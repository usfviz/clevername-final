library(shiny)
library(leaflet)
library(RColorBrewer)
library(dplyr)
library(sunburstR)
library(rCharts)

ui <- fluidPage(
  mainPanel(
    tabsetPanel(
      tabPanel("Web Session Demographics",
               mainPanel(
                 showOutput("stackedBar", "nvd3")
               )),
      tabPanel("Web Session User Interests",
               mainPanel(
                 sunburstOutput("sunburst", width="600px", height="600px")
               )))
  )
)
