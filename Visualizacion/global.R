# global.R

# --- Librerías ---
#library(shiny)
library(shinythemes)
library(leaflet)
library(plotly)
library(dplyr)
library(readr)
library(sf)
library(data.table)

# --- Carga de datos ---

# Accidentes
accidentes <- read_csv("data_complete.csv", locale = locale(encoding = "UTF-8"))
accidentes_sf <- st_as_sf(accidentes, coords = c("LINREFX", "LINREFY"), crs = 25832) %>% 
  st_transform(4326)
accidentes <- accidentes %>%
  mutate(
    lon = st_coordinates(accidentes_sf)[, 1],
    lat = st_coordinates(accidentes_sf)[, 2]
  )

# Infraestructura
infra <- read_csv("data_vereinfacht3.csv", locale = locale(encoding = "UTF-8"))
infra <- st_as_sf(infra, wkt = "WKT", crs = 25832) %>%
  st_transform(4326)


longitud_carril <- infra %>%
  mutate(long_km = as.numeric(st_length(.)) / 1000) %>%
  st_drop_geometry() %>%
  group_by(klasse) %>%
  summarise(total_km = sum(long_km, na.rm = TRUE), .groups = "drop")

infra <- infra %>%  mutate(longitud_m = as.numeric(st_length(WKT)))
infra <- infra %>% filter(longitud_m > 20)

# Barrios
barrios <- read_delim("app_bevoelkerung_bev_abs_31122014_EPSG_25832.csv", delim = ";") %>%
  st_as_sf(wkt = "geom", crs = 25832) %>%
  st_transform(4326)

# Variables globales
meses_esp <- c("Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
               "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre")

# --- Funciones auxiliares ---

generate_temp_labels <- function(temp_group) {
  as.character(temp_group)
}

plot_bars <- function(df, x, y, color = NULL, title, x_title, y_title, stacked = FALSE) {
  plot_ly(df, x = ~get(x), y = ~get(y), color = if (!is.null(color)) ~as.factor(get(color)) else NULL,
          type = 'bar') %>%
    layout(title = title,
           xaxis = list(title = x_title),
           yaxis = list(title = y_title),
           barmode = if (stacked) 'stack' else 'group')
}
