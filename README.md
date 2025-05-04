# Trabajo final del master de ciencia de datos
Análisis y predicción de los accidentes ciclistas en la ciudad de Hamburgo


#  Descripción
Este proyecto de ciencia de datos corresponde al trabajo final de master del master de ciencia de datos de la UOC y tiene como título: **Análisis y predicción de los accidentes ciclistas en la ciudad de Hamburgo**. En este trabajo se analizan los accidentes de tráfico en bicicleta en la ciudad de Hamburgo de forma estadística y geoespacial. Por otra parte se trata de identificar las principales causas de los accidentes y realizar una predicción de ellos a partir de modelos de aprendizaje automático.

La captura, el preprocesamiento, el análisis y las predicciones con los modelos de aprendizaje automático se han realizado en ***[R](https://github.com/adrianlaufer/TFM)***. La visualización de los análisis geoespaciales realizados se ha realizado con Shiny también en R y se han publicado en un visor interactivo en (https://adrianlaufer.shinyapps.io/visualizacion-bicicletas/)).

# Autores
* Autor del TFM: **Adrian Läufer Nicolás**
* Directora del TFM: **Anna Muñoz Bollas**
* Professora responsabla de la assignatura: **Susana Acedo Nadal**

# Estructura del Git
El Github está estructurado de la siguiente forma:
*  **Codigo** Contiene los archivos tanto en formato Rmd como html donde se expone los pasos seguidos durante la implementación del proyecto. Contiene las siguientes partes:
     *  **Codigo/01-preprocesamiento.html** Exposición del código para el preprocesamiento de los datos
     *  **Codigo/02-analisis.html** Análisis estadísticos de los datos de los accidentes ciclistas en Hamburgo
     *  **Codigo/03-modelos.htmlt** Aplicación de modelos de aprendizaje automático para la predicción de los accidentes ciclistas.  

*  **Datos** directorio que contiene los ficheros originales descargados de las diferentes fuentes de openData:
     *  **Datos/Bevoelkerung** directorio que contiene el archivo csv de donde se extrae la geometria y la población de los diferentes distritos en Hamburgo
     *  **Datos/Radinfraestruktur** directorio que contiene el archivo csv de donde se extrae la información sobre la red ciclista en Hamburgo
     *  **Datos/Radverkehrsmengen** directorio que contiene el archivo csv de donde se extrae la información sobre el tráfico en Hamburgo
     *  **Datos/Unfallatlas** directorio con archivos zip que contienen la información sobre los accidentes en Alemania entre 2016 y 2023
     *  **Datos/Wetter** directorio que contiene las mediciones climatológicas en la ciudad de Hamburgo

*  **Visualizacion** directorio que contiene los ficheros utilizados para crear la visualizacion con Shiny

