library(shiny)
library(leaflet)
library(RColorBrewer)
library(geosphere)

server <- function(input, output, session) {
  
  raw <- read.csv('addmissions_data_clean.csv')[-1]
  
  dup_lat <- raw[duplicated(raw$lat ), ][4] 
  dup_long <- raw[duplicated(raw$long ), ][5]
  
  raw[duplicated(raw$lat ), ][4] <- dup_lat + rnorm(nrow(dup_lat), 0, .002)
  raw[duplicated(raw$long ), ][5] <- dup_long + rnorm(nrow(dup_long), 0, .002)
  
  
  raw[raw$school == 'PUC - Rio',]
  raw[223,][1,4] <- raw[223,][1,4]+.001
  raw[223,][1,5] <- raw[223,][1,5]+.001
  
  rnorm(1, 0, sd=.01)
  
  raw$gre[raw$gre>170] <- NA
  missing_gre <- raw[is.na(raw$gre),]
  raw <- raw[!is.na(raw$gre),]
  
  funnel <- unique(raw$stage)
  gender <- c('All', as.character(unique(raw$sex)))
  
  
  # Reactive expression for the data subsetted to what the user selected
  filteredData <- reactive({
    
    data <- subset(raw, stage==input$funnel)
    data <- data[data$gre >= input$range[1] & data$gre <= input$range[2],]
    
    if(input$sex != 'All'){
      data <- subset(data, sex == input$sex)
    }
    return(data)
  })
  
  noNA <- reactive({
    data_na <- subset(missing_gre, stage==input$funnel)
    
    if(input$sex != 'All'){
      data_na <- subset(data_na, sex == input$sex)
    }
    return(data_na)
    
  })
  
  # This reactive expression represents the palette function,
  # which changes as the user makes selections in UI.
  colorpal <- reactive({
    colorNumeric('RdBu', raw$gre)
  })
  
  output$map <- renderLeaflet({
    # Use leaflet() here, and only include aspects of the map that
    # won't need to change dynamically (at least, not unless the
    # entire map is being torn down and recreated).
    leaflet(filteredData()) %>% addTiles() %>%
      fitBounds(~min(long), ~min(lat), ~max(long), ~max(lat))
  })
  
  # Incremental changes to the map (in this case, replacing the
  # circles when a new color is chosen) should be performed in
  # an observer. Each independent set of things that can change
  # should be managed in its own observer.
  observe({
    #plot NAs
    proxy <- leafletProxy("map", data = noNA())
    proxy %>% clearMarkers() 
    if(input$showna){ 
      proxy %>% clearShapes() %>% addTiles() %>%
        addCircleMarkers(radius = 5, weight = 1, color = "#777777",
                         fillColor ='yellow', fillOpacity = 0.5, popup =  ~paste(sep= "<br/>",paste(sep=' ','<b>',first, last, '</b>') , school, gre) )
    }
    
    #plot all
    pal <- colorpal()
    leafletProxy("map", data = filteredData()) %>%
      clearShapes() %>% addTiles() %>%
      addCircleMarkers(radius = 5, weight = 1, color = "#777777",
                       fillColor = ~pal(gre), fillOpacity = 0.9, popup = ~paste(sep= "<br/>",paste(sep=' ','<b>',first, last, '</b>') , school, gre) )
    
  })
  
  # Use a separate observer to recreate the legend as needed.
  observe({
    proxy <- leafletProxy("map", data = filteredData())
    
    # Remove any existing legend, and only if the legend is
    # enabled, create a new one.
    proxy %>% clearControls()
    if (input$legend) {
      pal <- colorpal()
      proxy %>% addLegend(title= 'GRE score', position = "bottomright",
                          pal = pal, values = ~gre
      )
    }
  })
}
