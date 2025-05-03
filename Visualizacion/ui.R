# ui.R

ui <- fluidPage(
  theme = shinytheme("flatly"),
  titlePanel("Análisis de accidentes de bicicleta en Hamburgo"),
  
  sidebarLayout(
    sidebarPanel(
      sliderInput("year", "Selecciona rango de años:",
                  min = min(accidentes$year, na.rm = TRUE), 
                  max = max(accidentes$year, na.rm = TRUE),
                  value = range(accidentes$year, na.rm = TRUE),
                  step = 1, sep = ""),
      
      checkboxGroupInput("category", "Selecciona gravedad del accidente:",
                         choices = sort(unique(accidentes$category)), selected = unique(accidentes$category)),
      
      selectInput("month", "Selecciona mes:", choices = c("Todos", meses_esp), selected = "Todos"),
      
      checkboxGroupInput("type_bikelane", "Selecciona tipo de carril bici:",
                         choices = sort(unique(accidentes$type_bikelane)),
                         selected = sort(unique(accidentes$type_bikelane)))
    ),
    
    mainPanel(
      tabsetPanel(
        tabPanel("Mapa", leafletOutput("accident_map", height = "600px"), br(), htmlOutput("accident_counter")),
        tabPanel("Evolución", plotlyOutput("trend_plot"), br(), plotlyOutput("monthly_plot"), br(), plotlyOutput("monthly_plot_normalized")),
        tabPanel("Distribución por distrito", leafletOutput("district_plot")),
        tabPanel("Distribución por carril", plotlyOutput("hist_accidents_total"), br(), plotlyOutput("hist_accidents_per_km")),
        tabPanel("Distribución por temperatura", plotlyOutput("temp_histogram"), br(), plotlyOutput("temp_histogram_normalized"))
      )
    )
  )
)
