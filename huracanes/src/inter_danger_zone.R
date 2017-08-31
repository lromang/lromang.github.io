#! /usr/bin/Rscript

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
suppressPackageStartupMessages(library(tm))
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
suppressPackageStartupMessages(library(geojsonio))
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

## Clean text
clean_text <- function(text){
    text <- text                    %>%
        removeNumbers()            %>%
        tolower()                  %>%
        ## removePunctuation()        %>%
        str_replace_all('\\n',"")  %>%
        str_replace_all("\t","")   %>%
        iconv("UTF-8","ASCII","")
    text
}

## Gulf
gulf     <- read.csv('../data/golfo.csv',
                    stringsAsFactors = FALSE)

## Gulf coords
gulf_coords <- dplyr::select(gulf,
                            nominm,
                            nomvial,
                            tipoinm,
                            nomasen,
                            nom_loc,
                            nom_mun,
                            nom_ent,
                            lon,
                            lat)

## Pacific
shelters <- read.csv('../data/pacific_refugios.csv',
                    stringsAsFactors = FALSE)
## Pacific Coords
coords <- dplyr::select(shelters,
                       nominm,
                       nomvial,
                       tipoinm,
                       nomasen,
                       nom_loc,
                       nom_mun,
                       nom_ent,
                       lon,
                       lat)
## Merge data
coords <- rbind(coords, gulf_coords)

## Only coords with adequate format
coords$lon <- str_replace(coords$lon, ',', '.') %>%
   readr::parse_number()
coords$lat <- str_replace(coords$lat, ',', '.') %>%
    readr::parse_number()
## Clean Lon
coords <- coords[str_detect(coords$lon,
                           '^-[0-9]+\\.[0-9]'),]
## Clean Lat
coords <- coords[str_detect(coords$lat,
                           '^[0-9]+\\.[0-9]'),]

## Clean_cols
coords[,1:7] <- apply(coords[,1:7], 2, function(t)t <- clean_text(t))


## ----------------------------------------
## Danger zone
## ----------------------------------------

## Generate polygon
## system('./getPolygon.sh')

## Read in polygon
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
## Hospitals
## ----------------------------------------
hospitals <- readOGR('../hospitals/hospitales_clinicas_consultorios_refugios.geojson',
               'OGRGeoJSON',
               verbose = FALSE)

## ----------------------------------------
## Inundaciones
## ----------------------------------------
flod <- readOGR('../inundaciones/flods.geojson',
               'OGRGeoJSON',
               verbose = FALSE)

## ----------------------------------------
## Glide
## ----------------------------------------
glide <- readOGR('../deslizamientos/glides.geojson',
               'OGRGeoJSON',
               verbose = FALSE)


###########################################
## Intersect
###########################################

## ----------------------------------------
## Intersect function
## ----------------------------------------
get_inside <- function(data){
    ## Data=  lon, lat (no NA)
    inside <- c()
    for(i in 1:nrow(data)){
        prov_coords              <- data.frame(data[i, ])
        coordinates(prov_coords) <- c('lon', 'lat')
        proj4string(prov_coords) <- proj4string(danger_zone_sps)
        ## Inside
        inside[i] <- !is.na(over(prov_coords,
                                as(danger_zone_sps,
                                   'SpatialPolygons')))
    }
    inside
}

## ----------------------------------------
## Shelters
## ----------------------------------------
print('---- SHELTERS -----')
coords          <- na.omit(coords)
shelter_coords  <- dplyr::select(coords, lon, lat)
inside_shelter  <- get_inside(shelter_coords)

## ----------------------------------------
## Hospitals
## ----------------------------------------
print('---- HOSPITALS -----')
proj4string(hospitals) <- proj4string(danger_zone_sps)
hospital_inter         <- raster::intersect(hospitals,
                                          danger_zone_sps)
hospital_geojson       <- geojson_json(hospital_inter)
geojson_write(hospital_geojson, file = '../inter_data/hospital_inside.geojson')

## ----------------------------------------
## Flods
## ----------------------------------------
print('---- FLODS -----')
proj4string(flod) <- proj4string(danger_zone_sps)
## Correct self intersect
flod              <- gBuffer(flod, byid=TRUE, width=0)
danger_zone_sps   <- gBuffer(danger_zone_sps, byid=TRUE, width=0)
## Intersect
flod_inter        <- raster::intersect(flod,
                                      danger_zone_sps)
## If no Inter
if(class(flod_inter) == "NULL"){
    flod_inter    <- flod
}

flod_geojson      <- geojson_json(flod_inter)
geojson_write(flod_geojson, file = '../inter_data/flod_inside.geojson')

## ----------------------------------------
## Glide
## ----------------------------------------
proj4string(glide) <- proj4string(danger_zone_sps)
## Correct self intersect
glide              <- gBuffer(glide, byid=TRUE, width=0)
danger_zone_sps    <- gBuffer(danger_zone_sps, byid=TRUE, width=0)
## Intersect
glide_inter        <- raster::intersect(glide,
                                       danger_zone_sps)
## If no Inter
if(class(glide_inter) == "NULL"){
    glide_inter    <- glide
}
glide_geojson      <- geojson_json(glide_inter)
geojson_write(glide_geojson, file = '../inter_data/glide_inside.geojson')


###########################################
## Save data
###########################################


## Shelters
write.table(coords[inside_shelter, ],
            '../inter_data/shelters_inside.tsv',
            sep = '\t',
            row.names = FALSE,
            fileEncoding  = 'UTF-8')
