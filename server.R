
library(shiny)
library(dplyr)
library(ggplot2)
library(lubridate)

#---------------------------------------------------
df_raw = read.csv("./caiso_final.csv",
               header = TRUE,
               stringsAsFactors = FALSE)

df = df_raw %>% 
    mutate(., TRUEDATE = parse_date_time(df_raw$DATE, "Ymd"),
              YEAR = substr(as.character(df_raw$DATE), 1, 4),
              YMONTH = substr(as.character(df_raw$DATE), 1, 6),
              SOLAR = df_raw$SOLAR_PV+df_raw$SOLAR_THERMAL,
              OTHER_CLEAN = df_raw$GEOTHERMAL +
                            df_raw$BIOMASS +
                            df_raw$BIOGAS +
                            df_raw$SMALL_HYDRO)

#---------------------------------------------------
df_forecast_raw = read.csv("./caiso_forecasts.csv",
                   header = TRUE,
                   stringsAsFactors = FALSE)

df_forecast = df_forecast_raw %>% 
    mutate(., TRUEDATE=parse_date_time(
        df_forecast_raw$DATE, "Ymd HMS"))

#---------------------------------------------------

RMSE = function(y_true, y_pred){ sqrt(mean((y_true-y_pred)^2)) }
MAE = function(y_true, y_pred){ mean(abs(y_true-y_pred)) }

#---------------------------------------------------

shinyServer(function(input, output) {

    output$generationPlot <- renderPlot({

        headers = c('SOLAR','WIND','OTHER_CLEAN','NUCLEAR','THERMAL','IMPORTS','HYDRO')
        
        periods = ifelse(input$periods==1, 'YEAR', 
                  ifelse(input$periods==2, 'YMONTH', 
                                           'TRUEDATE'))

        df = df %>%
            filter(., TRUEDATE>=input$dates[1] & TRUEDATE<=input$dates[2]) %>% 
            group_by_(., periods) %>%
            summarize_at(., headers, sum)
        t = as.factor(df[[periods]])
        
        rb = data.frame(PERIOD=factor(), ENERGY=integer(), TYPE=factor())
        
        if ('7' %in% input$type) {
            rb = rbind( rb,
                         data.frame('PERIOD'=t, 'ENERGY'=df$THERMAL, 'TYPE'='THERMAL'))
        }
        if ('6' %in% input$type) {
            rb = rbind( rb,
                         data.frame('PERIOD'=t, 'ENERGY'=df$IMPORTS, 'TYPE'='IMPORTS'))
        }
        if ('5' %in% input$type) {
            rb = rbind( rb,
                         data.frame('PERIOD'=t, 'ENERGY'=df$NUCLEAR, 'TYPE'='NUCLEAR'))
        }
        if ('4' %in% input$type) {
            rb = rbind( rb,
                         data.frame('PERIOD'=t, 'ENERGY'=df$HYDRO, 'TYPE'='HYDRO'))
        }
        if ('3' %in% input$type) {
            rb = rbind( rb,
                         data.frame('PERIOD'=t, 'ENERGY'=df$OTHER_CLEAN, 'TYPE'='OTHER_CLEAN'))
        }
        if ('2' %in% input$type) {
            rb = rbind( rb,
                         data.frame('PERIOD'=t, 'ENERGY'=df$WIND, 'TYPE'='WIND'))
        }
        if ('1' %in% input$type) {
            rb = rbind( rb,
                        data.frame('PERIOD'=t, 'ENERGY'=df$SOLAR, 'TYPE'='SOLAR'))
            }

        chart_type = ifelse(input$if_absolute==1, 'stack', 'fill')
        y_label = ifelse(input$if_absolute==1, "GWh", "% of total")
            
        ggplot(rb, aes(x=PERIOD, y=ENERGY/1000, fill=TYPE)) + 
            geom_bar(position=chart_type, 
                     stat="identity", 
                     width=0.8) +
                    xlab("") + ylab(y_label) +
                    theme(legend.position="top", legend.title = element_blank())
    })

    # ======== DAILY GENERATION PLOT    
    output$dailygenerationPlot <- renderPlot({
        
        # Daily data frames
        df = df %>% filter(., TRUEDATE==input$duckcurvedate)
        # Daily dataframes, row bind
        rb = rbind(data.frame('HOUR'=df$HOUR, 'ENERGY'=df$THERMAL, 'TYPE'='THERMAL'),
                   data.frame('HOUR'=df$HOUR, 'ENERGY'=df$IMPORTS, 'TYPE'='IMPORTS'),
                   data.frame('HOUR'=df$HOUR, 'ENERGY'=df$NUCLEAR, 'TYPE'='NUCLEAR'),
                   data.frame('HOUR'=df$HOUR, 'ENERGY'=df$HYDRO, 'TYPE'='HYDRO'),
                   data.frame('HOUR'=df$HOUR, 'ENERGY'=df$OTHER_CLEAN, 'TYPE'='OTHER_CLEAN'),
                   data.frame('HOUR'=df$HOUR, 'ENERGY'=df$WIND, 'TYPE'='WIND'),
                   data.frame('HOUR'=df$HOUR, 'ENERGY'=df$SOLAR, 'TYPE'='SOLAR')
                )
        ggplot(rb, aes(x=HOUR, y=ENERGY/1000, fill=TYPE)) + 
            geom_bar(position="stack", 
                     stat="identity", 
                     width=0.8) +
            theme(legend.position="top", legend.title = element_blank()) +
            xlab("") + ylab("GWh")
    })    
    
    # ======== DUCK CURVE PLOT
    output$duckcurvePlot <- renderPlot({
        
        selected_month = as.numeric(substr(input$duckcurvedate,6,7))
        selected_day = as.numeric(substr(input$duckcurvedate,9,10))

        df = df_raw %>%
            transmute(., TRUEDATE=parse_date_time(df_raw$DATE, "Ymd"),
                      HOUR=HOUR,
                      NET_LOAD = TOTAL-SOLAR_PV-SOLAR_THERMAL-WIND) %>%
            filter(., month(TRUEDATE)==selected_month &
                       day(TRUEDATE)==selected_day)

        ggplot(df,
               aes(x=HOUR, y=NET_LOAD/1000, group = TRUEDATE, color=TRUEDATE)) +
                geom_line(size=1) +
                ggtitle(paste("Net load on ",
                          as.character(month(df$TRUEDATE)), '/',
                          as.character(day(df$TRUEDATE)), sep='')) +
            theme(legend.position="right", legend.title = element_blank()) +
            ylab("GWh")
    })    
    
    # ======== FORECAST PLOT
    output$forecastPlot <- renderPlot({
        
        df = df_forecast %>%
            filter(., date(TRUEDATE)>=input$fdates[1] & date(TRUEDATE)<=input$fdates[2])

        rb = data.frame(PERIOD=factor(),
                         ENERGY=integer(),
                         TYPE=factor())

        if ('1' %in% input$ftype) {
            rb = rbind( rb,
            data.frame('PERIOD'=df$TRUEDATE, 'ENERGY'=df$SOLAR, 'TYPE'='Actual'))
        }
        if ('2' %in% input$ftype) {
            rb = rbind( rb,
            data.frame('PERIOD'=df$TRUEDATE, 'ENERGY'=df$F_NAIVE, 'TYPE'='Naive'))
        }
        if ('3' %in% input$ftype) {
            rb = rbind( rb,
            data.frame('PERIOD'=df$TRUEDATE, 'ENERGY'=df$F_DIFF, 'TYPE'='MA+Diff'))
        }
        if ('4' %in% input$ftype) {
            rb = rbind( rb,
            data.frame('PERIOD'=df$TRUEDATE, 'ENERGY'=df$F_LSTM, 'TYPE'='LSTM'))
        }

        ggplot(rb, aes(x=PERIOD, y=ENERGY/1000, group = TYPE, color=TYPE)) +
            geom_line(size=1) +
            theme(legend.position="top", legend.title = element_blank()) +
            xlab("") + ylab("GWh")
    })    
    
    
    output$metricsTable <- renderTable({    

        df = df_forecast %>%
            filter(., date(TRUEDATE)>=input$fdates[1] & date(TRUEDATE)<=input$fdates[2])

        data.frame('Forecast'=c('Naive', 'Diff+MA', 'LSTM'),
                   'MAE'= c(MAE(df$SOLAR, df$F_NAIVE)/1000,
                            MAE(df$SOLAR, df$F_DIFF)/1000,
                            MAE(df$SOLAR, df$F_LSTM)/1000
                            ),
                   'RMSE'=c(RMSE(df$SOLAR, df$F_NAIVE)/1000,
                            RMSE(df$SOLAR, df$F_DIFF)/1000,
                            RMSE(df$SOLAR, df$F_LSTM)/1000
                            )
                   )
    })    
    
})

