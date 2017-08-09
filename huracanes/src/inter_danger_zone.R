##########################################
##
## Luis Manuel Román García
## luis.roangarci@gmail.com
##
## ----------------------------------------
###########################################

## ----------------------------------------
## Libraries
## ----------------------------------------
## JSON manipulatino
suppressPackageStartupMessages(library(jsonlite))
suppressPackageStartupMessages(library(rjson))
suppressPackageStartupMessages(library(RJSONIO))
## XML
suppressPackageStartupMessages(library(XML))
## Urls manipulation
suppressPackageStartupMessages(library(RCurl))
## Manejo de arreglos
suppressPackageStartupMessages(library(plyr))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(tidyr))
## Manejo de cadenas de caracteres
suppressPackageStartupMessages(library(stringr))
## Manejo de data frames
suppressPackageStartupMessages(library(data.table))
## Predicción
suppressPackageStartupMessages(library(caret))
## Geoespacial
suppressPackageStartupMessages(library(geosphere))
suppressPackageStartupMessages(library(maps))
suppressPackageStartupMessages(library(maptools))
suppressPackageStartupMessages(library(spatstat))
suppressPackageStartupMessages(library(rgeos))
suppressPackageStartupMessages(library(rgdal))
## Gráficas
suppressPackageStartupMessages(library(ggplot2))
## Otros
suppressPackageStartupMessages(library(ggmap))
suppressPackageStartupMessages(library(deldir))
suppressPackageStartupMessages(library(rje))
suppressPackageStartupMessages(library(sp))
suppressPackageStartupMessages(library(SDMTools))
suppressPackageStartupMessages(library(PBSmapping))
suppressPackageStartupMessages(library(sp))
suppressPackageStartupMessages(library(prevR))
suppressPackageStartupMessages(library(foreign))

###########################################
## Read in data
###########################################

## ----------------------------------------
## Shelters
## ----------------------------------------
shelters <- read.csv('../data/pacific_refugios.csv',
                    stringsAsFactors = FALSE)
## Coords
coords <- dplyr::select(shelters,
                       nominm,
                       nomvial,
                       tipovial,
                       nomasen,
                       nom_loc,
                       nom_mun,
                       nom_ent,
                       lon,
                       lat)
## Only coords with adequate format
coords$lon <- str_replace(coords$lon, ',', '.') %>%
   readr::parse_number()
coords$lat <- str_replace(coords$lat, ',', '.') %>%
    readr::parse_number()
coords <- coords[str_detect(coords$lon,
                           '^-[0-9]+\\.[0-9]'),]
## Only clean lat
coords <- coords[str_detect(coords$lat,
                           '^[0-9]+\\.[0-9]'),]


## ----------------------------------------
## Danger zone
## ----------------------------------------

## Read in data
danger_zone  <- readLines('polygon.txt') %>%
    str_split(' ')
danger_zone  <- ldply(danger_zone[[1]],
                     function(t) t <- c(readr::parse_number(str_split(t,
                                                                     ',')[[1]][2]),
                                       readr::parse_number(str_split(t,
                                                                     ',')[[1]][1])))
names(danger_zone) <- c('lon', 'lat')

## Make polygon
danger_zone_p   <- Polygon(danger_zone)
danger_zone_ps  <- Polygons(list(danger_zone_p), 1)
danger_zone_sps <- SpatialPolygons(list(danger_zone_ps))

## ----------------------------------------
## Intersect
## ----------------------------------------
shelter_coords <- dplyr::select(coords, lon, lat) %>%
    na.omit()
inside <- c()
for(i in 1:nrow(shelter_coords)){
    prov_coords                      <- data.frame(shelter_coords[i, ])
    coordinates(prov_coords)         <- c('lon', 'lat')
    proj4string(prov_coords) <- proj4string(danger_zone_sps)
    ## Inside
    inside[i] <- !is.na(over(prov_coords,
                            as(danger_zone_sps,
                               'SpatialPolygons')))
}

## -----------------------------------------
## Save results
## ----------------------------------------
write.table(coords[inside, ],
            '../data/clean_coords_inside.tsv',
            sep = '\t',
            row.names = FALSE,
            fileEncoding  = 'UTF-8')
