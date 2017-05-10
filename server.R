server <- function(input, output, session) {
  interests <- read.csv("interests.csv", stringsAsFactors = FALSE)
  
  interests <- interests[,c(-1,-4)]
  grouped <- group_by(interests, interestOtherCategory)
  totals <- summarize(grouped, sessions=sum(sessions))
  totals$interestOtherCategory <- gsub("-","",totals$interestOtherCategory)
  totals$interestOtherCategory <- gsub("/","-",totals$interestOtherCategory)
  
  totals_df <- data.frame(totals)
  
  nodes <- character()
  leaves <- character()
  for(i in 1:nrow(totals_df)){
    family <- unlist(strsplit(totals_df[i,1], '-'))
    parent <- family[1]
    children <- family[-1]
    if(length(children) > 0){
      for(j in 1:length(children)){
        nodes <- c(nodes, parent)
        leaves <- c(leaves, children[j])
      }
    }
  }
  unodes <- unique(nodes)
  for(i in 1:length(unodes)){
    nodes <- c(nodes, unodes[i])
    leaves <- c(leaves, unodes[i])
  }
  
  
  
  node_map <- data.frame(nodes=nodes, leaves=leaves)
  node_map <- node_map[!duplicated(node_map),]
  qual_col_pals = brewer.pal.info[brewer.pal.info$category == 'qual',]
  col_vector = unlist(mapply(brewer.pal, qual_col_pals$maxcolors, rownames(qual_col_pals)))
  
  node_map$colors <- lapply(node_map$nodes, function(x){
    col_vector[which(unodes==x)]
  })
  
  totals_df$interestOtherCategory <- lapply(totals_df$interestOtherCategory, function(x){
    return(paste(x,"-end",sep=""))
  })
  
  output$sunburst <- renderSunburst({
    sunburst(totals_df, colors=list(range=c(node_map$colors,'#B3DE69'), domain=c(node_map$leaves, 'end'))) %>%
      htmlwidgets::onRender(
        htmlwidgets::JS(
          "
          function(el,x){
          var endpaths = d3.select(el)
          .selectAll('path')[0]
          .filter(function(d){
          return d3.select(d).datum().name === 'end'
          });
          d3.selectAll(endpaths).style('fill','none');
          }
          "      
        )    
        ) %>%
      htmlwidgets::onRender(
        htmlwidgets::JS(
          "
          function(el,x){
          d3.select(el).select('.sunburst-sidebar').remove()
          }
          "
        )
        )
    })
  
  bardf <- read.csv("all_processed.csv")
  bardf <- bardf[,-1]
  
  output$stackedBar <- renderChart2({
    n1 <- nPlot(sessions ~ ym, group = "userAgeBracket", data = bardf, 
                type = 'multiBarChart')
    n1$chart(tooltipContent = "#! function(key, x, y, e){ 
             return x + '<br>Age Bracket: ' + e.point.userAgeBracket + '<br>Total: ' + (y+0) + '<br>Male: ' + e.point.male + '<br>Female: ' + e.point.female; } !#")
    n1$yAxis(axisLabel = "Sessions", tickFormat = "#! function(d){ return d+0; } !#") 
    n1$xAxis(axisLabel = "Date")
    n1$chart(margin = list(left = 80))
    return(n1)
})
  }