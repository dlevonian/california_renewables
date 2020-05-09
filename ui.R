library(shiny)
library(shinydashboard)



dashboardPage(
    dashboardHeader(),
    
    dashboardSidebar(
        sidebarMenu(
            menuItem("CA Green Goals", tabName = "goals", icon = icon("seedling")),
            menuItem("Forecasts", tabName = "forecasts", icon = icon("forward"))
        )
    ),
    
    dashboardBody(
        tabItems(
            tabItem(tabName = "goals",
                fluidRow(
                    # Application title
                    titlePanel("California Renewable Energy"),
                    # Sidebar with a slider input for number of bins
                    sidebarLayout(
                        sidebarPanel(width = 3,

                            checkboxGroupInput(inputId = "type", 
                                               label = h4("Generation:"), 
                                               choices = list("Solar" = 1, 
                                                              "Wind" = 2,
                                                              "Other Clean" = 3, 
                                                              "Hydro" = 4, 
                                                              "Nuclear" = 5, 
                                                              "Imports" = 6,  
                                                              "Thermal" = 7),
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
                            plotOutput("distPlot")
                        )
                    )
                )
            ),
            tabItem(tabName = "forecasts",
                    h2("FORECASTS CONTENT")
            )        
        )
    )
)


# Define UI for application that draws a histogram
