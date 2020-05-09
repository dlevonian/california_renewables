#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#
library(shiny)
library(dplyr)
library(ggplot2)
library(lubridate)

df_raw <- read.csv("./caiso_final.csv",
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


# Define server logic required to draw a histogram
shinyServer(function(input, output) {

    output$distPlot <- renderPlot({

        headers = c('SOLAR','WIND','OTHER_CLEAN','NUCLEAR','THERMAL','IMPORTS','HYDRO')
        
        periods = ifelse(input$periods==1, 'YEAR', 
                  ifelse(input$periods==2, 'YMONTH', 
                                           'TRUEDATE'))

        gdf = df %>%
            filter(., TRUEDATE>=input$dates[1] & TRUEDATE<=input$dates[2]) %>% 
            group_by_(., periods) %>%
            summarize_at(., headers, sum)

        cat(">>>>>>>>>>>>>>>>>>>>>>>>>>>\n",
            periods,
            "\n>>>>>>>>>>>>>>>>>>>>>>>>>>>"
        )
        
        rdf = data.frame(PERIOD=factor(),
                         ENERGY=integer(),
                         TYPE=factor())

        t = as.factor(gdf[[periods]])
        
        if ('1' %in% input$type) {
            rdf = rbind( rdf,
                data.frame('PERIOD'=t, 'ENERGY'=gdf$SOLAR, 'TYPE'='SOLAR'))
            }
        if ('2' %in% input$type) {
            rdf = rbind( rdf,
                data.frame('PERIOD'=t, 'ENERGY'=gdf$WIND, 'TYPE'='WIND'))
            }
        if ('3' %in% input$type) {
            rdf = rbind( rdf,
                data.frame('PERIOD'=t, 'ENERGY'=gdf$OTHER_CLEAN, 'TYPE'='OTHER_CLEAN'))
            }
        if ('4' %in% input$type) {
            rdf = rbind( rdf,
                data.frame('PERIOD'=t, 'ENERGY'=gdf$HYDRO, 'TYPE'='HYDRO'))
        }
        if ('5' %in% input$type) {
            rdf = rbind( rdf,
                data.frame('PERIOD'=t, 'ENERGY'=gdf$NUCLEAR, 'TYPE'='NUCLEAR'))
        }
        if ('6' %in% input$type) {
            rdf = rbind( rdf,
                data.frame('PERIOD'=t, 'ENERGY'=gdf$IMPORTS, 'TYPE'='IMPORTS'))
        }
        if ('7' %in% input$type) {
            rdf = rbind( rdf,
                data.frame('PERIOD'=t, 'ENERGY'=gdf$THERMAL, 'TYPE'='THERMAL'))
        }

        chart_type = ifelse(input$if_absolute==1, 'stack', 'fill')
            
        ggplot(rdf, aes(x=PERIOD, y=ENERGY, fill=TYPE)) + 
            geom_bar(position=chart_type, 
                     stat="identity", 
                     width=0.8) +
            theme(legend.position="bottom") +
            xlab("")
        
    })
})
