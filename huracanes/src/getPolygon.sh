#! /bin/bash

lastUpdate="https://correo1.conagua.gob.mx/Feedsmn16/"$(curl https://correo1.conagua.gob.mx/feedsmn/feedalert.aspx | iconv -f windows-1251 | grep '<id>' | grep '.*avisossmn.*' | head -n 1 | grep -Eo '>.*<' | sed -r 's/(<|>)//g')"_cap.xml"
## lastUpdate="https://correo1.conagua.gob.mx/Feedsmn16/avisossmn-ciclontropical-2127_cap.xml"
## Echo Update
echo $lastUpdate > 'lastUpdate.txt'
polygon=$(curl $lastUpdate | iconv -f windows-1251 | grep -o '<polygon>.*</polygon>'| sed -e 's$</.*$$g' -e 's$<polygon>$$g' | sed -r 's/(<|>)//g')
echo $polygon > 'polygon.txt'
