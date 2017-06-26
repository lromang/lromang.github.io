#! /bin/bash

lastUpdate="https://correo1.conagua.gob.mx/Feedsmn16/"$(curl https://correo1.conagua.gob.mx/feedsmn/feedalert.aspx | grep '<id>' | grep '.*avisossmn.*' | head -n 1 | grep -Eo '>.*<' | sed -r 's/(<|>)//g')"_cap.xml"
polygon=$(curl $lastUpdate | grep -o '<polygon>.*</polygon>'| grep -Eo '>.*<' | sed -r 's/(<|>)//g')
echo $polygon | sed 's/ /\n/g' | awk -F ',' '{print "["$2","$1"],"}'
