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
*  **Codigo** Contiene

*  **codi/Dades** directori que conté els fitxers originals descarregats d'OpenData Barcelona i Catalunya. En concret:
     *  **codi/Dades/T1.infraestructura_ciclable** directori que conté els conjunts ZIP per l'estudi de la infraestructura ciclable
     *  **codi/Dades/T2.aforaments** directori que conté els conjunts CSV per l'estudi d'ús de la bicicleta
     *  **codi/Dades/T3.accidentalitat** directori que conté els conjunts CSV per l'estudi d'accidentalitat
     *  **codi/Dades/T4.qualitat_aire** directori que conté el conjunt CSV per l'estudi de la qualitat de l'aire
     *  **codi/Dades/BCN_UNITATS_ADM** directori que conté els ZIP amb les dades administratives de Barcelona (municipi, districtes i barris)
     *  **codi/Dades/graf_viari** directori que conté els ZIP amb l'entramat de la xarxa vial     


*  **codi/Exports** directori que conté les capes exportades d'ArcGIS Pro. En concret:
     *  **codi/Exports/T1.infraestructura_ciclable** directori que conté els _shapefiles_ de les capes de la infraestructura ciclable
     *  **codi/Exports/T2.aforaments** directori que conté els _shapefiles_ de les capes d'ús de la bicicleta
     *  **codi/Exports/T3.accidentalitat** directori que conté els _shapefiles_ de les capes d'accidentalitat
     *  **codi/Exports/T4.qualitat_aire** directori que conté els _shapefiles_ de les capes de la qualitat de l'aire


*  **codi/AGOL** directori que conté els recursos generats a R per enriquir el visor d'AGOL.
