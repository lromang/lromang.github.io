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
suppressPackageStartupMessages(library(raster))
## Gráficas
suppressPackageStartupMessages(library(ggplot2))
## Otros
suppressPackageStartupMessages(library(ggmap))
suppressPackageStartupMessages(library(deldir))
suppressPackageStartupMessages(library(rje))
suppressPackageStartupMessages(library(sp))
suppressPackageStartupMessages(library(SDMTools))
suppressPackageStartupMessages(library(PBSmapping))
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
## Si llega otro, set de refugios poner mismas instrucciones
## que golfo y pacífico y descomentar esta linea
## coords <- rbind(coords, otro)

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
## Change Projection
proj4string(danger_zone_sps) <- CRS("+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")
danger_zone_sps              <- spTransform(danger_zone_sps,
                                           CRS("+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"))
plot(danger_zone_sps)


## ----------------------------------------
## Read in states
## ----------------------------------------
states <- readOGR('../data/estate/',
                 'dest_2010cw')
## Change projection
## proj4string(states) <- CRS("+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")
states              <- spTransform(states, CRS("+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"))
## Get States of Interest
unique(states$ENTIDAD)
states_interest <- states[states$ENTIDAD %in% c('DISTRITO FEDERAL',
                                               'PUEBLA',
                                               'MORELOS'),]
plot(states_interest)
## ----------------------------------------
## Union with Danger ZONE
## ----------------------------------------
print('---- UNION WITH STATES -----')
## states_polygons              <- SpatialPolygons(states_interest@polygons,
##                                               proj4string = states_interest@proj4string)

## En caso de que no haya danger_zone simplemente hacer!!!!!!!!!
## danger_zone_sps <- states_interest

danger_zone_sps              <- raster::union(states_interest,
                                             danger_zone_sps)
plot(danger_zone_sps)


##################################################
## Puntos Dañados (BEGIN)
##################################################

## ----------------------------------------
## puntos
## ----------------------------------------
pt_daños        <- read.csv('../data/daños.csv',
                           stringsAsFactors = FALSE)

## ----------------------------------------
## Polygons
## ----------------------------------------
pt_daños$lat <- readr::parse_number(pt_daños$lat)
pt_daños$lon <- readr::parse_number(pt_daños$lon)
pt_daños     <- pt_daños[!is.na(pt_daños$lon), ]
pt_daños     <- pt_daños[!is.na(pt_daños$lat), ]

daños_coords_p  <- SpatialPointsDataFrame(data = pt_daños,
                                          coords = pt_daños[,8:9])
writeOGR(daños_coords_p, '../inter_data/danios.geojson', 'acopio', driver='GeoJSON')


##################################################
## Puntos Dañados (End)
##################################################

##################################################
## ACOPIO (BEGIN)
##################################################

## ----------------------------------------
## Centros Acopio
## ----------------------------------------
acopio        <- read.csv('../data/acopio.csv',
                         stringsAsFactors = FALSE)
## ----------------------------------------
## Supers
## ----------------------------------------
acopio_sup        <- read.csv('../data/supers.csv',
                             stringsAsFactors = FALSE)
acopio_sup_coords <- laply(acopio_sup$dir,
                          function(t)t <- ggmap::geocode(clean_text(t)))
## Get Coords
acopio_sup$lon    <- unlist(acopio_sup_coords[,1])
acopio_sup$lat    <- unlist(acopio_sup_coords[,2])

acopio_sup        <- acopio_sup[!is.na(acopio_sup$lat), ]
acopio_sup        <- acopio_sup[!is.na(acopio_sup$lon), ]

## ----------------------------------------
## Unificación y consolidación
## ----------------------------------------
acopio_coords <- laply(acopio$dir,
                      function(t)t <- ggmap::geocode(t))
## Get Coords
acopio$lon    <- unlist(acopio_coords[,1])
acopio$lat    <- unlist(acopio_coords[,2])

## UNIFICATION
acopio        <- rbind(acopio, acopio_sup)

## write.table(acopio, '../outData/acopio_new.tsv', row.names = FALSE, sep = '\t')
## Make polygon
acopio_coords_p  <- SpatialPointsDataFrame(data = acopio,
                                          coords = acopio[,6:7])
writeOGR(acopio_coords_p, '../inter_data/acopio.geojson', 'acopio', driver='GeoJSON')

##################################################
## ACOPIO (END)
##################################################

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
        proj4string(prov_coords) <- CRS("+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")
        ## proj4string(prov_coords) <- proj4string(danger_zone_sps)
        ## Inside
        inside[i] <- tryCatch({!is.na(over(prov_coords,
                                as(danger_zone_sps,
                                   'SpatialPolygons')))
        },warning = function(w){
            FALSE
        }, error = function(e){
            FALSE
        })
    }
    inside
}

## ----------------------------------------
## Shelters
## ----------------------------------------
print('---- SHELTERS -----')
coords          <- na.omit(coords)
coords          <- coords[coords$lon > -200, ] ## ERROR IN SHELTERS
shelter_coords  <- dplyr::select(coords, lon, lat)
inside_shelter  <- get_inside(shelter_coords)
plot(coords$lon[inside_shelter], coords$lat[inside_shelter])
## IR A LA SECCIÓN DE GUARDAR

## ----------------------------------------
## Hospitals
## ----------------------------------------
print('---- HOSPITALS -----')
proj4string(hospitals) <- CRS("+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")
hospitals              <- spTransform(hospitals,
                                     CRS("+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"))
proj4string(hospitals) <- proj4string(danger_zone_sps)
hospital_inter         <- raster::intersect(hospitals,
                                          danger_zone_sps)
plot(hospital_inter)
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
plot(flod_inter)
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
plot(glide_inter)
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
