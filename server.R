
library(shiny)
library(dplyr)
library(ggplot2)
library(lubridate)

#---------------------------------------------------
# load the cleaned 10-year hourly generation file (pre-processd in Python)
# 87,936 hourly records from April 20,2010 to April 30, 2020
df_raw = read.csv("./caiso_final.csv",
               header = TRUE,
               stringsAsFactors = FALSE)

# parse the dates and create  a separate variable YMONTH to visualize the monthly data
# aggregate 4 less significant types of clean energy into OTHER_CLEAN
df = df_raw %>% 
    mutate(., TRUEDATE = parse_date_time(df_raw$DATE, "Ymd"),
              YEAR = substr(as.character(df_raw$DATE), 1, 4),
              YMONTH = paste(substr(as.character(df_raw$DATE), 1, 4), '-', 
                             substr(as.character(df_raw$DATE), 5, 6), sep=''),
              SOLAR = df_raw$SOLAR_PV+df_raw$SOLAR_THERMAL,
              OTHER_CLEAN = df_raw$GEOTHERMAL +
                            df_raw$BIOMASS +
                            df_raw$BIOGAS +
                            df_raw$SMALL_HYDRO)

#---------------------------------------------------
# load the 1-hour ahead forecasts
# produced separately in a Python environment (statsmodels.api and TensorFlow)
df_forecast_raw = read.csv("./caiso_forecasts.csv",
                   header = TRUE,
                   stringsAsFactors = FALSE)

df_forecast = df_forecast_raw %>% 
    mutate(., TRUEDATE=parse_date_time(
        df_forecast_raw$DATE, "mdY HM"))

#---------------------------------------------------
# 2 metrics are reported: MAE and RMSE
# Mean Abs.Percentage Error not suitable b/c solar production is zero at night
RMSE = function(y_true, y_pred){ sqrt(mean((y_true-y_pred)^2)) }
MAE = function(y_true, y_pred){ mean(abs(y_true-y_pred)) }

#---------------------------------------------------

shinyServer(function(input, output) {

    output$generationPlot <- renderPlot({

        headers = c('SOLAR','WIND','OTHER_CLEAN','NUCLEAR','THERMAL','IMPORTS','HYDRO')
        
        periods = ifelse(input$periods==1, 'YEAR', 
                  ifelse(input$periods==2, 'YMONTH', 
                                           'TRUEDATE'))
        
        # filter the dataframe by dates selected
        df = df %>%
            filter(., TRUEDATE>=input$dates[1] & TRUEDATE<=input$dates[2]) %>% 
            group_by_(., periods) %>%
            summarize_at(., headers, sum)
        t = as.factor(df[[periods]])

        rb = data.frame(PERIOD=factor(), ENERGY=integer(), TYPE=factor())
        
        # react to  generation types selected in the UI, build the dataframe to visualize
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

        ticks_angle = ifelse(length(t)<12, 0, 90)
        ticks_bool  = rep(FALSE, ceiling(length(t)/40))
        ticks_bool[1] = TRUE

        g= ggplot() +
            geom_bar(data=rb, aes(x=PERIOD, y=ENERGY/1000, fill=TYPE), 
                     position=chart_type, 
                     stat="identity", 
                     width=0.8)    +
            scale_fill_manual(values = c("THERMAL" = "#F8766D", #colors should be constant
                                         "IMPORTS" = "#B79F00",
                                         "NUCLEAR" = "grey",
                                         "HYDRO" = "#00BFC4",
                                         "OTHER_CLEAN" = "#619CFF",
                                         "WIND" = "#F564E3",
                                         "SOLAR"="orange")) + 
            xlab("") + ylab(y_label) +
            theme(legend.position="top",
                  legend.title = element_blank(),
                  axis.text.x = element_text(angle=ticks_angle),
                  axis.ticks = element_blank()) + 
            scale_x_discrete(breaks=rb$PERIOD[1:length(t)][ticks_bool]) 
        
        if(input$if_absolute==0) {g=g+scale_y_continuous(labels = scales::percent)} 

        # visualize California's long-term goals for % of clean energy generation
        if (input$goals==TRUE & input$if_absolute==0){ 
            g = g + 
            geom_hline(yintercept = 0.5, linetype="dashed") +
            geom_text(aes(0,0.5,label = '2025 clean energy goal: 50%', 
                          vjust = -0.5, hjust = -.2, size=10), show.legend=F) +
            geom_hline(yintercept = 0.65, linetype="dashed") +
            geom_text(aes(0,0.65,label = '2030 clean energy goal: 65%', 
                          vjust = -0.5, hjust = -.2, size=10), show.legend=F) +
            geom_hline(yintercept = 1, linetype="dashed") +
            geom_text(aes(0,1,  label = '2045 clean energy goal: 100%', 
                          vjust = -0.5, hjust = -.2, size=10), show.legend=F) 
            }
        
        print(g)
    })

    # ======== DAILY GENERATION PLOT    
    output$dailygenerationPlot <- renderPlot({
        
        # Build the dataframe: hourly generation for a particular date
        df = df %>% filter(., TRUEDATE==input$duckcurvedate)
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
            # consistent colors with the graphs on other pages (e.g. solar-orange)
            scale_fill_manual(values = c("THERMAL" = "#F8766D", 
                                         "IMPORTS" = "#B79F00",
                                         "NUCLEAR" = "grey",
                                         "HYDRO" = "#00BFC4",
                                         "OTHER_CLEAN" = "#619CFF",
                                         "WIND" = "#F564E3",
                                         "SOLAR"="orange")) + 
            theme(legend.position="top", 
                  legend.title = element_blank(), 
                  axis.ticks = element_blank()) +
            ylab("GWh") +
            scale_x_discrete(name ="Hour of the day", limits=c(1:24))
    })    
    
    # ======== DUCK CURVE PLOT
    output$duckcurvePlot <- renderPlot({
        
        selected_month = as.numeric(substr(input$duckcurvedate,6,7))
        selected_day = as.numeric(substr(input$duckcurvedate,9,10))
        
        # filter the requested day of the year (e.g. all April 30s, from 2010 to 2020)
        # result: 24 hours of data for each of those days
        df = df_raw %>%
            transmute(., TRUEDATE=parse_date_time(df_raw$DATE, "Ymd"),
                      HOUR=HOUR,
                      NET_LOAD = TOTAL-SOLAR_PV-SOLAR_THERMAL-WIND) %>%
            filter(., month(TRUEDATE)==selected_month &
                       day(TRUEDATE)==selected_day)

        ggplot(df,
               aes(x=HOUR, y=NET_LOAD/1000, group = TRUEDATE, color=TRUEDATE)) +
                geom_line(size=1) +
                ggtitle(paste("Net load on the same day: ",
                          as.character(month(df$TRUEDATE)), '/',
                          as.character(day(df$TRUEDATE)), sep='')) +
            theme(legend.position="right", 
                  legend.title = element_blank(),
                  axis.ticks = element_blank()) +
            ylab("GWh") +
            scale_x_discrete(name ="Hour of the day", limits=c(1:24))
            
    })    
    
    # ======== FORECAST PLOT
    output$forecastPlot <- renderPlot({
        
        df = df_forecast %>%
            filter(., date(TRUEDATE)>=input$fdates[1] & date(TRUEDATE)<=input$fdates[2])
        
        rb = data.frame(PERIOD=factor(),
                         ENERGY=integer(),
                         TYPE=factor())

        # Build 1 Actual and 5 types of forecasts
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
            data.frame('PERIOD'=df$TRUEDATE, 'ENERGY'=df$F_DIFF, 'TYPE'='Diff 24h'))
        }
        if ('4' %in% input$ftype) {
            rb = rbind( rb,
            data.frame('PERIOD'=df$TRUEDATE, 'ENERGY'=df$F_SARIMA, 'TYPE'='SARIMA'))
        }
        if ('5' %in% input$ftype) {
            rb = rbind( rb,
            data.frame('PERIOD'=df$TRUEDATE, 'ENERGY'=df$F_LSTM, 'TYPE'='LSTM'))
        }
        if ('6' %in% input$ftype) {
            rb = rbind( rb,
            data.frame('PERIOD'=df$TRUEDATE, 'ENERGY'=df$F_ENSEMBLE, 'TYPE'='Ensemble'))
        }
        
        ggplot(rb, aes(x=PERIOD, y=ENERGY/1000, group = TYPE, color=TYPE)) +
            geom_line(size=1) +
            theme(legend.position="top", legend.title = element_blank()) +
            xlab("") + ylab("GWh")
    })    
    
    
    output$metricsTable <- renderTable({    

        df = df_forecast %>%
            filter(., date(TRUEDATE)>=input$fdates[1] & date(TRUEDATE)<=input$fdates[2])
        
        # ratio of solar hours to total. 
        # Scale up all Errors by this coeff to more accuartely reflect deviation from actual
        solar_hours_ratio = nrow(df[df$SOLAR>0,])/nrow(df)
        
        # divide by 1000 to report in GWh, as all other charts
        coeff = solar_hours_ratio*1000
        
        data.frame('Forecast'=c('Naive', 'Diff 24h', 'SARIMA', 'LSTM', 'Ensemble'),
                   'MAE'= c(MAE(df$SOLAR, df$F_NAIVE)/coeff,
                            MAE(df$SOLAR, df$F_DIFF)/coeff,
                            MAE(df$SOLAR, df$F_SARIMA)/coeff,
                            MAE(df$SOLAR, df$F_LSTM)/coeff,
                            MAE(df$SOLAR, df$F_ENSEMBLE)/coeff                            
                            ),
                   'RMSE'=c(RMSE(df$SOLAR, df$F_NAIVE)/coeff,
                            RMSE(df$SOLAR, df$F_DIFF)/coeff,
                            RMSE(df$SOLAR, df$F_SARIMA)/coeff,
                            RMSE(df$SOLAR, df$F_LSTM)/coeff,
                            RMSE(df$SOLAR, df$F_ENSEMBLE)/coeff                                                        
                   )
           )
    })    
    
})

