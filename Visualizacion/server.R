server <- function(input, output, session) {
  
  bbox_visible <- reactive({
    bounds <- input$accident_map_bounds
    if (is.null(bounds)) return(NULL)
    
    st_bbox(c(xmin = bounds$west, ymin = bounds$south,
              xmax = bounds$east, ymax = bounds$north),
            crs = st_crs(infra)) %>%
      st_as_sfc()
  })
  
  infra_should_display <- reactive({
    zoom_actual <- input$accident_map_zoom
    !is.null(zoom_actual) && zoom_actual >= 13
  })
  
  infra_visible <- reactive({
    tipos <- input$type_bikelane
    bbox <- bbox_visible()
    
    # Devolver sf vacío si no hay tipos seleccionados o bbox es NULL
    if (is.null(tipos) || length(tipos) == 0 || is.null(bbox)) {
      return(infra[0, ])
    }
    
    infra %>%
      filter(klasse %in% tipos) %>%
      filter(st_intersects(., bbox, sparse = FALSE))
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
  
  observe({
    leafletProxy("accident_map") %>% removeControl("infra_message")
    
    if (!infra_should_display()) {
      leafletProxy("accident_map") %>%
        addControl(
          html = "<div style='background: white; padding: 6px; border: 1px solid gray; border-radius: 5px; font-size: 13px;'>
                  🔍 Aumenta el zoom para ver la infraestructura ciclista
                </div>",
          position = "bottomright",
          layerId = "infra_message"
        )
    }
  })
  
  output$accident_map <- renderLeaflet({
    #data_map <- infra
    
    leaflet() %>%
      addTiles() %>%
      setView(lng = 9.9937, lat = 53.5511, zoom = 11) %>%
      addLegend(position = "bottomright",
                colors = c("green", "blue", "purple", "black", "gray", "violet", "coral"),
                labels = c("Calle para bicicletas", "Carril bici en calzada", "Carril protegido",
                           "Calle de tráfico mixto > 50 km/h", "Calle de tráfico mixto ≤ 30 km/h", 
                           "Camino en áreas verdes", "Otros"),
                title = "Tipo de Infraestructura") %>%
      addLegend(position = "bottomleft",
                colors = c("red", "orange", "yellow"),
                labels = c("1 - Accidente con víctimas mortales", "2 - Accidente con lesión grave", "3 - Accidente con heridos leves"),
                title = "Categoría de accidente")
  })
  observe({
    df <- datos_filtrados()
    leafletProxy("accident_map") %>%
      clearMarkers() %>%
      addCircleMarkers(data = df, ~lon, ~lat,
                       radius = 4, fillOpacity = 1,
                       stroke = TRUE,              
                       color = "black", 
                       weight = 1,                 
                       fillColor = ~case_when(     
                         category == 1 ~ "red",
                         category == 2 ~ "orange",
                         category == 3 ~ "yellow"
                       ),
                       popup = ~paste("Año:", year, "<br>Clase:", category, "<br>Type Bikelane:", type_bikelane),
                       options = pathOptions(zIndex = 1000)) 
  })
  observe({
    req(infra_should_display())  
    
    data_map <- infra_visible()
    leafletProxy("accident_map") %>% clearGroup("infraestructura")
    
    if (!is.null(data_map) && nrow(data_map) > 0) {
      leafletProxy("accident_map") %>%
        addPolylines(data = data_map,
                     group = "infraestructura",
                     color = ~case_when(
                       klasse == "Calle para bicicletas" ~ "green",
                       klasse == "Carril bici en calzada" ~ "blue",
                       klasse == "Carril protegido" ~ "purple",
                       klasse == "Calle de tráfico mixto > 50 km/h" ~ "black",
                       klasse == "Calle de tráfico mixto ≤ 30 km/h" ~ "gray",
                       klasse == "Camino en áreas verdes" ~ "violet",
                       klasse == "Otros" ~ "coral"
                     ),
                     weight = 2,
                     opacity = 1,
                     options = pathOptions(zIndex = 200))
    }
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
  
  output$tabla_resumen_accidentes <- renderTable({
    df <- datos_filtrados()
    
    if (nrow(df) == 0) return(NULL)
    
    tabla <- df %>%
      count(category, type_bikelane) %>%
      tidyr::pivot_wider(names_from = type_bikelane, values_from = n, values_fill = 0) %>%
      arrange(category)
    
    tabla
  }, align = "l")
  
  output$tabla_normalizada_accidentes <- renderTable({
    df <- datos_filtrados()
    long_km <- longitud_carril
    
    if (nrow(df) == 0 || nrow(long_km) == 0) {
      return(data.frame(Mensaje = "No hay datos suficientes para calcular accidentes por km."))
    }
    
    tabla <- df %>%
      count(category, type_bikelane) %>%
      left_join(long_km, by = c("type_bikelane" = "klasse")) %>%
      mutate(acc_x_km = n / total_km) %>%
      select(category, type_bikelane, acc_x_km) %>%
      tidyr::pivot_wider(names_from = type_bikelane, values_from = acc_x_km, values_fill = 0) %>%
      arrange(category)
    
    tabla[-1] <- lapply(tabla[-1], function(x) format(round(x, 3), decimal.mark = ",", nsmall = 3))
    
    tabla
  }, align = "l")
  
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
      left_join(longitud_carril, by = c("type_bikelane" = "klasse")) %>%
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
    # Asignamos accidentes a distritos
    accidentes_sf <- st_as_sf(datos_filtrados(), coords = c("lon", "lat"), crs = 4326)
    
    # Unimos accidentes con los distritos usando st_join
    accidentes_distrito_sf <- st_join(accidentes_sf, barrios, join = st_within)
    
    # Contabilizamos accidentes por distrito
    accidentes_distrito <- accidentes_distrito_sf %>%
      group_by(stadtteil) %>%
      summarise(
        accidentes_distrito = n(),
        bev = first(bev),  
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
