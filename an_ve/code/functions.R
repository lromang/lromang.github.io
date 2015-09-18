## Funciones para llevar a cabo tareas procesamiento e ingeniería
## de variables. 
##-----------------------------------
##-----------------------------------
## Librerías utilizadas
##-----------------------------------
##-----------------------------------
library(plyr)
library(foreign)
library(sp)
library(rgdal)
library(maptools)
library(lubridate)
library(shapefiles)
library(proj4)
library(geosphere)
library(mapproj)
library(FNN)
library(ggmap)
library(RecordLinkage)
library(tidyr)
library(caret)
library(RPostgreSQL)
library(data.table)
library(googleVis)
library(rCharts)
##-----------------------------------
##-----------------------------------
## Lectura de datos
##-----------------------------------
##-----------------------------------
## Shapefile de carreteras donde CSTAV tiene cobertura
## Notar que la estructura de los shapes puede cambiar.
shp <- readOGR(".data/CSTAV_Cobertura_Carretera-0/CSTAV_Cobertura_Carretera/",
               "Cobertura_Carretera_CSTAV_2014")
## Datos accidentes (sin hora)
accidentes_tot<- read.csv("./data/angels_clean.csv",
                          stringsAsFactors = FALSE)
## Datos de las carreteras (extraidos del shapefile)
coords <- read.csv(".data/road_coords.csv",
                   stringsAsFactors = FALSE)
## Datos de tráfico
aforo <- read.csv(".data/aforo.csv",
                  stringsAsFactors = FALSE)
## Datos limipios de accidentes (con hora)
acc_time <- read.csv(".data/accidents_time.csv",
                     stringsAsFactors = FALSE)
##-----------------------------------
##-----------------------------------
## Funciones
##-----------------------------------
##-----------------------------------

##----------------------------
## get_coords_shp
##----------------------------
get_coords_shp <- function(shp){
    ## Obtención de coordenadas
    ## el shape tiene 245 rutas.
    ## las lineas que definen cada tramo de la
    ## carretara están dentro de lines
    ## las coordenadas de cada linea estan en Lines@coords
    ##-----------------------------------
    ## ejemplo:
    ## Número de carreteras
    ## nrow(shp)
    ## Número de lineas que constituyen la carretera 2
    ## length(shp[2,1]@lines[[1]]@Lines)
    ## coordenadas de la primera línea de la carretera 2
    ## shp[2,1]@lines[[1]]@Lines[[1]]@coords
    ## datos de la proyección
    ## CRS arguments:
    ##    +proj=lcc +lat_1=17.5 +lat_2=29.5 +lat_0=12 +lon_0=-102 +x_0=2500000
    ## +y_0=0 +ellps=GRS80 +units=m +no_defs
    ##coords.tot <- list()
    ##carretera  <- list()
    ##-----------------------------------
    for(i in 1:nrow(shp)){
        ## Obtenemos total de lineas que constituyen
        ## la carretera.
        lines  <- length(shp[i,1]@lines[[1]]@Lines)
        coords <- list()
        ## Obtenemos las coordenadas de cada una de las líneas
        for(j in 1:lines){
            coords[[j]]    <- shp[i,1]@lines[[1]]@Lines[[j]]@coords
        }
        ## Guardamos los valores en listas
        coords.tot[[i]] <- ldply(coords,function(t)t<-t)
        carretera[[i]]  <- rep(as.character(shp[i,1]@data$NOMVIAL[1]),
                               nrow(coords.tot[[i]]))
    }
    coords.tot <- ldply(coords.tot, function(t)t<-t)
    carretera  <- unlist(carretera)
    coords.tot$carretera <- carretera
    names(coords.tot) <-c("lon","lat","carretera")
    ## transformar cordenadas
    coords <- project(coords.tot[,1:2],
                      proj= c("+proj=lcc",
                          "+lat_1=17.5",
                          "+lat_2=29.5",
                          "+lat_0=12",
                          "+lon_0=-102",
                          "+x_0=2500000",
                          "+y_0=0",
                          "+ellps=GRS80" ,
                          "+units=m",
                          "+no_defs"), inverse = TRUE)
    coords.tot$lon <- unlist(coords[[1]])
    coords.tot$lat <- unlist(coords[[2]])
    coords.tot
}
##----------------------------
## asigna_camino 
##----------------------------
## dado un punto, le asigna la carretera
## a la cual pertenece (la más cercana)
## p= punto en formato longitud, latitud
## k=número de puntos más cercanos.
## coords=coordenadas de carreteras
asigna_camino <- function(p, coords = coords, k = 3){
    ## Obtenemos distancia máxima latitud y longitud 
    d_lon <- abs(coords$lon - as.numeric(p[1]))
    d_lat <- abs(coords$lat - as.numeric(p[2]))
    dist  <- data.frame(lon=d_lon,lat=d_lat)
    dist  <- apply(dist,1,max)
    ## Obtenemos los k más cercanos
    ## aplicamos distancia del coseno.
    near  <- head(coords[order(dist),],k)
    dist  <- apply(near[,1:2], 1,function(t)t <-
        distCosine(as.numeric(t),as.numeric(p)))
    ## Regresamos data.frame con resultados
    data.frame(carretera = near[,3],
               dist = dist/1000,
               nearest_lon = near[,1],
               nearest_lat = near[,2])
}
##----------------------------
## curvatura 
##----------------------------
## dado un punto, le asigna la carretera
## a la cual pertenece (la más cercana)
## y calcula la curvatura tomando en consideración
## los 2 puntos más cercanos.
## p = punto en formato longitud, latitud
curvatura <- function(p){
    ## Asigna carretera
    road     <- asigna_camino(p)
    delt_lon <- road$nearest_lon[1] - road$nearest_lon[3]
    ## Calculamos angulo usando fórmula
    ## θ = atan2(sin(Δlong)*cos(lat2), cos(lat1)*sin(lat2) − sin(lat1)*cos(lat2)*cos(Δlong)
    angle    <- atan2(sin(delt_lon)*cos(road$nearest_lat[3]),
                      cos(road$nearest_lat[1])*sin(road$nearest_lat[3])-
                          sin(road$nearest_lat[1])*cos(road$nearest_lat[3])*
                              cos(delt_lon)
                      )
    angle
}
##----------------------------
## intersect_coords_road (road_coords)
##----------------------------
## Dado el vector de coordenadas (lon, lat) de
## carreteras, determina si estas se duplican
## y por ende pertenecen a alguna intersección
intersect_coords_road<- function(coords){
    key <- paste0(coords[,1],coords[,2])
    duplicated(key)
}
##----------------------------
## intersect_coords (accidentes)
##----------------------------
## Dado un punto p (lon, lat), determina
## si este se encuentra a una distancia
## k de una intersección.
intersect_coords <- function(p, k){
    inter <- filter(coords, inter == TRUE)
    asigna_camino(p,inter,k)    
}
##----------------------------
## asign_acc 
##----------------------------
## coords = vector de coordenadas de carreteras.
## accident_coord = coordenadas del accidente.
asign_acc <- function(coords, accident_coord, TOL = 300){
    near  <- apply(coords, 1, function(t)t <- distCosine(t, accident_coord))
    sum(near < TOL)
}
##----------------------------
## asign_acc_n 
##----------------------------
## coords = vector de coordenadas de carreteras.
## accidents_coords = vector de coordenadas de accidentes.
asign_acc_n <- function(coords, accidents_coords, TOL = 300){
    apply(accidents_coords, 1, function(t)t <- asign_acc(coords, t, TOL))
}
##----------------------------
## asign_circ
##----------------------------
## p = coordenadas o vector de coordenadas (lat, lon)
## k = número de vecinos a utilizar en la predicción
asign_circ <- function(p,k,seed){
    set.seed(seed)
    train <- aforo[,1:2]
    test  <- p
    y     <- aforo[,3]
    names(test) <- c("latitude","longitude")
    knn.reg(train = train,
            test = test,
            y = y,
            "cover_tree",
            k = 3)$pred
}
