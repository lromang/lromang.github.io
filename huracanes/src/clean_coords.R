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

## ----------------------------------------
## Read in data
## ----------------------------------------
data   <- read.csv('../data/refugios.csv',
                  stringsAsFactors = FALSE)

## Extract relevant data
coords <- data[,c(2,25,24,27,28)]
## Only clean lon
## bad_lon <- !str_detect(data$lon, '^-[0-9]+\\.[0-9]')
## bad_lat <- !str_detect(data$lat, '^[0-9]+\\.[0-9]')

coords <- coords[str_detect(coords$lon,
                           '^-[0-9]+\\.[0-9]'),]
## Only clean lat
coords <- coords[str_detect(coords$lat,
                           '^[0-9]+\\.[0-9]'),]

## Read in Mexico's state division and change
## projection
mex_state <- readOGR("../data/estate/",
                         "dest_2010cw")
mex_transform              <- spTransform(mex_state,
                       CRS("+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"))
proj4string(mex_transform) <- CRS("+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")

## Filter coords only on mexico
## Check in shape
inside <- c()
for(i in 1:nrow(coords)){
    tryCatch({
    center <- data.frame(readr::parse_number(coords$lon[i]),
                        readr::parse_number(coords$lat[i]))
    names(center)        <- c("lon", "lat")
    coordinates(center)  <- c("lon", "lat")
    proj4string(center)  <- proj4string(mex_transform)
    inside[i]            <- !is.na(over(center,
                                       as(mex_transform,
                                          "SpatialPolygons")))
    },warning = function(w){
        inside[i] <- FALSE
    },error = function(e){
        inside[i] <- FALSE
    })
    print(i)
}
## Filter only inside mexico
coords <- coords[inside, ]
## Clean nomin nomvial
coords$nominm    <- str_replace_all(coords$nominm, '[^[[:alpha:]] ]', '')
coords$nomvial   <- str_replace_all(coords$nomvial, '[^[[:alpha:]] ]', '')
coords$tipovial  <- str_replace_all(coords$tipovial, '[^[[:alpha:]] ]', '')

## Save data as tsv
write.table(coords,
            '../data/clean_coords.tsv',
            sep = '\t',
            row.names = FALSE)


data$bad_lat <- bad_lat
data$bad_lon <- bad_lon
data$outside <- !inside
write.csv(data,
            '../data/errors.csv',
            row.names = FALSE)
