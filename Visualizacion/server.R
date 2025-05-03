# server.R

server <- function(input, output, session) {
  
  infra_filtrada <- reactive({
    tipos <- input$type_bikelane
    
    if (is.null(tipos) || length(tipos) == 0) {
      return(NULL)
    }
    
    infra %>% filter(klasse %in% tipos)
  })
  
  datos_filtrados <- reactive({
    df <- accidentes %>%
      filter(between(year, input$year[1], input$year[2]))
    
    if (input$month != "Todos") df <- df %>% filter(month == match(input$month, meses_esp))
    
    if (length(input$category) > 0) {
      df <- df %>% filter(category %in% input$category)
    } else {
      df <- df[0,]  # Si no hay categorías seleccionadas, devuelve un dataframe vacío
    }
    
    # Filtrar por tipo de carril bici, si se selecciona
    if (length(input$type_bikelane) > 0) {
      df <- df %>% filter(type_bikelane %in% input$type_bikelane)
    }
    
    df
  })
  
  
  longitud_carril <- reactive({
    infra_filtrada() %>%
      mutate(long_km = as.numeric(st_length(.)) / 1000) %>%
      st_drop_geometry() %>%
      group_by(klasse) %>%
      summarise(total_km = sum(long_km, na.rm = TRUE), .groups = "drop")
  })
  
  output$accident_map <- renderLeaflet({
    data_map <- infra
    
    leaflet() %>%
      addTiles() %>%
      setView(lng = 9.9937, lat = 53.5511, zoom = 11) %>%
      { 
        if (!is.null(data_map) && nrow(data_map) > 0) {
          addPolylines(., data = data_map,
                       color = ~case_when(
                         klasse == "Calle para bicicletas" ~ "green",
                         klasse == "Carril bici en calzada" ~ "blue",
                         klasse == "Carril protegido" ~ "purple",
                         klasse == "Calle tráfico mixto >50km/h" ~ "red",
                         klasse == "Calle tráfico mixto ≤30km/h" ~ "yellow",
                         klasse == "Camino en áreas verdes" ~ "orange",
                         klasse == "Otros" ~ "gray"
                       ),
                       weight = 4, opacity = 0.7)
        } else {
          .
        }
      } %>%
      addLegend(position = "bottomright",
                colors = c("green", "blue", "purple", "red", "yellow", "orange", "gray"),
                labels = c("Calle para bicicletas", "Carril bici en calzada", "Carril protegido",
                           "Calle tráfico mixto >50km/h", "Calle tráfico mixto ≤30km/h", 
                           "Camino en áreas verdes", "Otros"),
                title = "Tipo de Infraestructura")
  })
  
  observe({
    df <- datos_filtrados()
    leafletProxy("accident_map") %>%
      clearMarkers() %>%
      addCircleMarkers(data = df, ~lon, ~lat,
                       radius = 4, fillOpacity = 0.6,
                       color = ~case_when(
                         category == 1 ~ "blue",
                         category == 2 ~ "green",
                         category == 3 ~ "red"
                       ),
                       popup = ~paste("Año:", year, "<br>Clase:", category, "<br>Type Bikelane:", type_bikelane)) %>%
      addLegend(position = "bottomleft",
                colors = c("blue", "green", "red"),
                labels = c("1 - Accidente con víctimas mortales", "2 - Accidente con lesión grave", "3 - Accidente con heridos leves"),
                title = "Categoría de accidente")
  })
  
  output$accident_counter <- renderUI({
    df <- datos_filtrados()
    total <- nrow(df)
    conteo_cat <- df %>% group_by(category) %>% summarise(total = n(), .groups = "drop")
    
    HTML(paste0(
      "<h4>Accidentes filtrados: ", total, "</h4>",
      "<p>", paste0("Categoría ", conteo_cat$category, ": ", conteo_cat$total, collapse = " | "), "</p>"
    ))
  })
  
  output$hist_accidents_total <- renderPlotly({
    df <- datos_filtrados() %>%
      group_by(type_bikelane, category) %>%
      summarise(total_accidentes = n(), .groups = 'drop')
    
    plot_bars(df, "type_bikelane", "total_accidentes", "category",
              "Accidentes totales por tipo de carril", "Tipo de Carril", "Número de accidentes", stacked = TRUE)
  })
  
  output$hist_accidents_per_km <- renderPlotly({
    df <- datos_filtrados() %>%
      group_by(type_bikelane, category) %>%
      summarise(total_accidentes = n(), .groups = 'drop') %>%
      left_join(longitud_carril(), by = c("type_bikelane" = "klasse")) %>%
      mutate(accidentes_por_km = total_accidentes / total_km)
    
    plot_bars(df, "type_bikelane", "accidentes_por_km", "category",
              "Accidentes por km de carril", "Tipo de Carril", "Accidentes por km", stacked = TRUE)
  })
  
  output$trend_plot <- renderPlotly({
    df <- datos_filtrados() %>%
      group_by(year, category) %>%
      summarise(total = n(), .groups = 'drop')
    
    plot_ly(df, x = ~year, y = ~total, color = ~as.factor(category),
            type = 'scatter', mode = 'lines+markers') %>%
      layout(title = "Evolución de accidentes por clase",
             xaxis = list(title = "Año"),
             yaxis = list(title = "Número de accidentes"))
  })
  
  output$monthly_plot <- renderPlotly({
    df <- datos_filtrados() %>%
      filter(!is.na(month)) %>%
      group_by(month, category) %>%
      summarise(total = n(), .groups = 'drop') %>%
      mutate(month_label = factor(meses_esp[month], levels = meses_esp))
    
    plot_bars(df, "month_label", "total", "category",
              "Distribución de accidentes por mes", "Mes", "Número de accidentes", stacked = TRUE)
  })
  
  output$monthly_plot_normalized <- renderPlotly({
    df <- datos_filtrados() %>%
      group_by(month) %>%
      summarise(total_accidents = n(), total_traffic = sum(traffic, na.rm = TRUE), .groups = 'drop') %>%
      mutate(accidents_per_traffic = total_accidents / total_traffic,
             month_label = factor(meses_esp[month], levels = meses_esp))
    
    plot_bars(df, "month_label", "accidents_per_traffic", NULL,
              "Accidentes normalizados por tráfico", "Mes", "Accidentes/tráfico")
  })
  
  output$district_plot <- renderLeaflet({
    # Asignar accidentes a distritos
    accidentes_sf <- st_as_sf(datos_filtrados(), coords = c("lon", "lat"), crs = 4326)
    
    # Unir accidentes con los distritos usando st_join
    accidentes_distrito_sf <- st_join(accidentes_sf, barrios, join = st_within)
    
    # Contabilizar accidentes por distrito
    accidentes_distrito <- accidentes_distrito_sf %>%
      group_by(stadtteil) %>%
      summarise(
        accidentes_distrito = n(),
        bev = first(bev),  # tomar el primer valor de e_ha del distrito (todos deberían ser iguales)
        .groups = 'drop'
      )
    accidentes_distrito$por_poblacion <- accidentes_distrito$accidentes_distrito / accidentes_distrito$bev
    accidentes_distrito_df <- accidentes_distrito %>% st_drop_geometry()
    
    barrios <- barrios %>%
      left_join(accidentes_distrito_df, by = "stadtteil")
    pal <- colorNumeric(palette = "Blues", domain = barrios$por_poblacion)
    
    leaflet(barrios) %>%
      addTiles() %>%
      addPolygons(
        fillColor = ~pal(por_poblacion),
        fillOpacity = 0.7,
        color = "white",
        weight = 1,
        popup = ~paste0(stadtteil, "<br>Accidentes: ", accidentes_distrito, "<br>Por Poblacion:", por_poblacion)
      ) %>%
      addLegend(
        pal = pal,
        values = ~por_poblacion,
        opacity = 0.7,
        title = "Número de accidentes",
        position = "bottomright"
      )
  })
  
  output$temp_histogram <- renderPlotly({
    df <- datos_filtrados() %>%
      filter(!is.na(temperature)) %>%
      mutate(temp_group = cut(temperature, breaks = seq(-10, 35, 5))) %>%
      group_by(temp_group) %>%
      summarise(total_accidents = n(), .groups = 'drop')
    plot_bars(df, "temp_group", "total_accidents", NULL,
              "Accidentes por intervalo de temperatura", "Temperatura", "Número de accidentes")
  })
  
  output$temp_histogram_normalized <- renderPlotly({
    df <- datos_filtrados() %>%
      filter(!is.na(temperature)) %>%
      mutate(temp_group = cut(temperature, breaks = seq(-10, 35, 5))) %>%
      group_by(temp_group) %>%
      summarise(total_accidents = n(), total_traffic = sum(traffic, na.rm = TRUE), .groups = 'drop') %>%
      mutate(accidents_per_traffic = total_accidents / total_traffic)
    
    plot_bars(df, "temp_group", "accidents_per_traffic", NULL,
              "Accidentes normalizados por tráfico", "Temperatura", "Accidentes/tráfico")
  })
}
