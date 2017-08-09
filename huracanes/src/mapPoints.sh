#! /bin/bash

rm ../html/body.html
rm ../html/full.html
ids=0
for rows in $(seq 2 $(wc -l ../inter_data/shelters_inside.tsv | sed 's/[^0-9]//g'))
do
    echo $ids
    coords=$(cat ../inter_data/shelters_inside.tsv | awk -F '\t' "FNR == $rows {print}")
    nomin=$(cat ../inter_data/shelters_inside.tsv | awk -F '\t' "FNR == $rows {print}" | awk -F '\t' '{print $1}')
    nomvial=$(cat ../inter_data/shelters_inside.tsv | awk -F '\t' "FNR == $rows {print}" | awk -F '\t' '{print $2}')
    ##tipovial=$(cat ../inter_data/shelters_inside.tsv | awk -F '\t' "FNR == $rows {print}" | awk -F '\t' '{print $3}')
    tipovial='NA'
    nomasen=$(cat ../inter_data/shelters_inside.tsv | awk -F '\t' "FNR == $rows {print}" | awk -F '\t' '{print $4}')
    nom_loc=$(cat ../inter_data/shelters_inside.tsv | awk -F '\t' "FNR == $rows {print}" | awk -F '\t' '{print $5}')
    nom_mun=$(cat ../inter_data/shelters_inside.tsv | awk -F '\t' "FNR == $rows {print}" | awk -F '\t' '{print $6}')
    nom_ent=$(cat ../inter_data/shelters_inside.tsv | awk -F '\t' "FNR == $rows {print}" | awk -F '\t' '{print $7}')
    lon=$(cat ../inter_data/shelters_inside.tsv | awk -F '\t' "FNR == $rows {print}" | awk -F '\t' '{print $8}' | sed 's/"//g')
    lat=$(cat ../inter_data/shelters_inside.tsv | awk -F '\t' "FNR == $rows {print}" | awk -F '\t' '{print $9}' | sed 's/"//g')

    echo '{"type": "Feature","properties":{"id": ' $ids ', "nomin":' $nomin ', "tipovial": ' $tipovial ', "nomvial": ' $nomvial ', "nomasen": ' $nomasen ', "nomloc":  ' $nom_loc ', "nommun": ' $nom_mun ', "noment": ' $nom_ent ', "description": "<strong>Refugio:</strong><p>'$(echo $nomin  | sed 's/"//g')'</p><strong>Vialidad:</strong><p>'$(echo $nomvial  | sed 's/"//g')'</p><strong>Asentamiento:</strong><p>'$(echo $nomasen  | sed 's/"//g')'</p><strong>Localidad:</strong><p>'$(echo $nom_loc  | sed 's/"//g')'</p><strong>Tipo vialidad:</strong><p>'$(echo $tipovial  | sed 's/"//g')'</p>"}, "geometry": { "type": "Point","coordinates": [' $lon ',' $lat ']}},' >> ../html/body.html
    ids=$((ids + 1))
done
## Remove last comma
sed '$ s/.$//' ../html/body.html > ../html/aux.html
cat ../html/aux.html > ../html/body.html
rm ../html/aux.html
## Add end of points
echo ']}},"layout": {"icon-image": "shelter", "icon-size": .15}});});' >> ../html/body.html
## Add head of polygon
echo   'map.addLayer({
        "id": "dangerZone","type": "fill","source": {"type": "geojson", "data": {"type": "Feature","geometry": {"type": "Polygon","coordinates":[[' >> ../html/body.html

## Add body of polygon
lastUpdate="https://correo1.conagua.gob.mx/Feedsmn16/"$(curl https://correo1.conagua.gob.mx/feedsmn/feedalert.aspx | grep '<id>' | grep '.*avisossmn.*' | head -n 1 | grep -Eo '>.*<' | sed -r 's/(<|>)//g')"_cap.xml"
## lastUpdate="https://correo1.conagua.gob.mx/Feedsmn16/avisossmn-ciclontropical-2127_cap.xml"
## Echo Update
echo $lastUpdate > 'lastUpdate.txt'
polygon=$(curl $lastUpdate | grep -o '<polygon>.*</polygon>'| grep -Eo '>.*<' | sed -r 's/(<|>)//g')
echo $polygon > 'polygon.txt'
echo $polygon | sed 's/ /\n/g' | awk -F ',' '{print "["$2","$1"],"}' >> ../html/body.html
## Remove last comma
sed '$ s/.$//' ../html/body.html > ../html/aux.html
cat ../html/aux.html > ../html/body.html
rm ../html/aux.html
## Add end of polygon
echo ']]}}},"layout": {},"paint": {"fill-color": "#64DD17","fill-opacity": 0.4}});});' >> ../html/body.html

## Add aditional info
add_param=$(curl $lastUpdate | grep -Eo '<(value(Name)?>)[^<]+</\1'| sed -e 's/valueName/strong/g' -e 's/value/span/g')
## <div class="add_info"><p id="contents"></p></div>
## add_p='<div class="add_info"><p id="contents">'$add_param'</p></div>'
## echo '$( document ).ready(function() {document.getElementById("contents").append("'$add_param'");});' >> ../html/body.html
cat ../html/upper_head.html >> ../html/full.html
echo $add_p | sed 's/> </><br></g' >> ../html/full.html
cat ../html/lower_head.html >> ../html/full.html
## cat ../html/head_aux.html > ../html/head.html
## rm  ../html/head_aux.html
## Pas to full
## cat ../html/head_aux.html >> ../html/full.html
cat ../html/body.html >> ../html/full.html
cat ../html/tail.html >> ../html/full.html
