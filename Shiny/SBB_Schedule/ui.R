#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(leaflet)

# Define UI for application that draws a histogram
shinyUI(fluidPage(

    # Application title
    titlePanel("Best Commuting Places to Bern and Zurich"),

    # Sidebar with a slider input for number of bins
    sidebarLayout(
        sidebarPanel(
            sliderInput("popsize",
                        "Population Size:",
                        min = 1,
                        max = 396955,
                        value = c(1,10000)),
            sliderInput("nConn",
                        "Number of Connections Per Hour:",
                        min = 0,
                        max = 60,
                        value = c(1,60)),
            sliderInput("duration",
                        "Travel Time in Minutes:",
                        min = 9,
                        max = 473,
                        value = c(9, 60)),
            selectInput(
                inputId = "city",
                label = "Show connections to:",
                choices = c("Bern/Zürich", "Bern", "Zürich"),
                selected = "Bern/Zürich",
                multiple = F
            ),
            checkboxInput(
                inputId = "monday",
                label = "Show Monday",
                value = TRUE
            ),
            checkboxInput(
                inputId = "tuesday",
                label = "Show Tuesday",
                value = TRUE
            ), 
            checkboxInput(
                inputId = "wednesday",
                label = "Show Wednesday",
                value = TRUE
            ),
            checkboxInput(
                inputId = "thursday",
                label = "Show Thursday",
                value = TRUE
            ),
            checkboxInput(
                inputId = "friday",
                label = "Show Friday",
                value = TRUE
            ),            checkboxInput(
                inputId = "saturday",
                label = "Show Saturday",
                value = TRUE
            ),
            checkboxInput(
                inputId = "sunday",
                label = "Show Sunday",
                value = TRUE
            )
            
        ),
        
        # Show a plot of the generated distribution
        mainPanel(
            leafletOutput("distPlot"),
            textOutput("testText"),
            includeHTML("instructions.html")
        )
    )
))
