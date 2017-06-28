#! /bin/bash

rm ../html/body.html
rm ../html/full.html
ids=0
for rows in $(seq 2 $(wc -l ../data/clean_coords.tsv | sed 's/[^0-9]//g'))
do
    echo $ids
    coords=$(cat ../data/clean_coords.tsv | awk -F '\t' "FNR == $rows {print}")
    nomin=$(cat ../data/clean_coords.tsv | awk -F '\t' "FNR == $rows {print}" | awk -F '\t' '{print $1}')
    lon=$(cat ../data/clean_coords.tsv | awk -F '\t' "FNR == $rows {print}" | awk -F '\t' '{print $2}' | sed 's/"//g')
    lat=$(cat ../data/clean_coords.tsv | awk -F '\t' "FNR == $rows {print}" | awk -F '\t' '{print $3}' | sed 's/"//g')
    tipovial=$(cat ../data/clean_coords.tsv | awk -F '\t' "FNR == $rows {print}" | awk -F '\t' '{print $4}')
    nomvial=$(cat ../data/clean_coords.tsv | awk -F '\t' "FNR == $rows {print}" | awk -F '\t' '{print $5}')
    echo '{"type": "Feature","properties":{"id": ' $ids ', "nomin":' $nomin ', "tipovial": ' $tipovial ', "nomvial": ' $nomvial ', "description": "<strong>Refugio:</strong><p>'$(echo $nomin  | sed 's/"//g')'</p><strong>Vialidad:</strong><p>'$(echo $nomvial  | sed 's/"//g')'</p><strong>Tipo vialidad:</strong><p>'$(echo $tipovial  | sed 's/"//g')'</p>"}, "geometry": { "type": "Point","coordinates": [' $lon ',' $lat ']}},' >> ../html/body.html
    ids=$((ids + 1))
done
## Remove last comma
sed '$ s/.$//' ../html/body.html > ../html/aux.html
cat ../html/aux.html > ../html/body.html
rm ../html/aux.html
## Add end of points
echo ']}},"layout": {"icon-image": "shelter", "icon-size": 0.12}});});' >> ../html/body.html
## Add head of polygon
echo   'map.addLayer({
        "id": "dangerZone","type": "fill","source": {"type": "geojson", "data": {"type": "Feature","geometry": {"type": "Polygon","coordinates":[[' >> ../html/body.html

## Add body of polygon
lastUpdate="https://correo1.conagua.gob.mx/Feedsmn16/"$(curl https://correo1.conagua.gob.mx/feedsmn/feedalert.aspx | grep '<id>' | grep '.*avisossmn.*' | head -n 1 | grep -Eo '>.*<' | sed -r 's/(<|>)//g')"_cap.xml"
polygon=$(curl $lastUpdate | grep -o '<polygon>.*</polygon>'| grep -Eo '>.*<' | sed -r 's/(<|>)//g')
echo $polygon | sed 's/ /\n/g' | awk -F ',' '{print "["$2","$1"],"}' >> ../html/body.html
## Remove last comma
sed '$ s/.$//' ../html/body.html > ../html/aux.html
cat ../html/aux.html > ../html/body.html
rm ../html/aux.html
## Add end of polygon
echo ']]}}},"layout": {},"paint": {"fill-color": "#9C27B0","fill-opacity": 0.8}});});' >> ../html/body.html

## Pas to full
cat ../html/head.html >> ../html/full.html
cat ../html/body.html >> ../html/full.html
cat ../html/tail.html >> ../html/full.html
