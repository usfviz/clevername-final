library(shiny)
library(leaflet)
library(RColorBrewer)
library(geosphere)

ui <- bootstrapPage(
  tags$style(type = "text/css", "html, body {width:100%;height:100%}"),
  leafletOutput("map", width = "100%", height = "100%"),
  absolutePanel(top = 10, right = 10,
                sliderInput("range", "GRE Scores", min(raw$gre, na.rm = T), max(raw$gre, na.rm = T),
                            value = range(raw$gre, na.rm = T), step = 1
                ),
                selectInput("funnel", "Choose Admissions Stage", funnel
                ),
                selectInput("sex", "Gender", gender
                ),
                checkboxInput("legend", "Show legend", TRUE
                ),
                checkboxInput("showna", "Show Students With Missing GRE", TRUE)
  )
)