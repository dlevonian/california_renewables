
library(shiny)
library(shinydashboard)
library(shinythemes)

text_1 ="California is America's undisputed clean energy leader. The recent Renewables Portfolio Standard requires that 60% of California's electricity come from zero-carbon sources (renewables+nuclear) by 2030, and 100% by 2045."
text_2 = "Traditional power plants are turned down to minimum during the day, while requiring large and fast power ramping to supply peak demand in the evening when the sun has gone down."
text_3 = "This is the greatest challenge facing renewable energy in California today."
text_4 = "Uncertainty in solar generation forecasts can be reduced with autoregressive models. External data such as cloud cover forecasts would improve the accuracy."

dashboardPage(
    dashboardHeader(),
    
    dashboardSidebar(
        sidebarMenu(
            menuItem("Renewable Generation", tabName = "generation", icon = icon("seedling")),
            menuItem("Duck Curve", tabName = "duckcurve", icon = icon("dove")),
            menuItem("Forecasts", tabName = "forecasts", icon = icon("forward"))
        )
    ),
    
    dashboardBody(
        tabItems(
            tabItem(tabName = "generation",
                fluidRow(
                    #titlePanel("California Renewable Energy"),
                    sidebarLayout(
                        sidebarPanel(width = 3,
                            checkboxGroupInput(inputId = "type", 
                                               label = h4("Generation:"), 
                                               choices = list("Thermal" = 7,
                                                               "Imports" = 6,  
                                                               "Nuclear" = 5, 
                                                               "Hydro" = 4, 
                                                               "Other Clean" = 3, 
                                                               "Wind" = 2,
                                                               "Solar" = 1),
                                               selected = 1),
                            
                            radioButtons(inputId = "if_absolute", 
                                         label = "",
                                         choices = list("Gigawatt hours" = 1, 
                                                        "Percentage" = 0), 
                                         selected = 1),

                            hr(),

                            dateRangeInput(inputId = "dates", 
                                           label = h4("Dates:"),
                                           start = "2010/04/20", 
                                           end = "2020/04/30", 
                                           min = "2010/04/20",
                                           max = "2020/04/30"),
                            
                            selectInput(inputId = "periods", 
                                        label = "", 
                                        choices = list("annual" = 1, 
                                                       "monthly" = 2, 
                                                       "daily" = 3), 
                                        selected = 1)
                        ),
                        mainPanel(
                            tags$h3("California Renewable Energy"),
                            tags$p(text_1),
                            plotOutput("generationPlot"),
                        )
                    )
                )
            ),

            tabItem(tabName = "duckcurve",
                    fluidRow(
                        sidebarLayout(
                            sidebarPanel(width = 3,
                                 dateInput(inputId = "duckcurvedate", 
                                           label = h4("Date:"),
                                           value = "2020/04/30", 
                                           min = "2010/04/20",
                                           max = "2020/04/30"),
                            ),
                            mainPanel(
                                tags$h3("Intraday Generation"),
                                tags$p(text_2),
                                plotOutput("dailygenerationPlot"),
                                hr(),
                                tags$h3("The Duck Curve"),
                                tags$p(text_3),
                                plotOutput("duckcurvePlot")
                                
                            )
                        )
                    )
            ),

             tabItem(tabName = "forecasts",
                     fluidRow(
                         sidebarLayout(
                             sidebarPanel(width = 3,
                                 dateRangeInput(inputId = "fdates",
                                                label = h4("Dates:"),
                                                start = "2020/04/30",
                                                end = "2020/04/30",
                                                min = "2019/01/01",
                                                max = "2020/04/30"),
                                 checkboxGroupInput(inputId = "ftype",
                                                    label = h4("Forecasts:"),
                                                    choices = list("Actual" = 1,
                                                                   "Naive" = 2,
                                                                   "Diff+MA" = 3,
                                                                   "LSTM" = 4),
                                                    selected = 1),
                            ),
                            mainPanel(
                                tags$h3("Solar Generation: 1 hour ahead forecast"),
                                tags$p(text_4),
                                plotOutput("forecastPlot"),
                                hr("Accuracy metrics, GWh"),
                                # h4('Accuracy metrics, GWh').
                                tableOutput("metricsTable")
                         )
                     )
                 )
            )        
        )
    )
)

