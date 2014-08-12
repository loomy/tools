#!/bin/sh
exec 2>/dev/null

if [ "x$1" = "x" ] ;then
    echo "need file or dirname"
    exit 1
fi


doit(){
for file in $1 ; do
    if [ -d $file ];then
        #go into dir
        pushd $file
        doit "./*"
        popd
    elif [ -f $file ];then
        if [ "$file" != "${file%\.mp3}" ] ;then
    	    echo -en "doing $file: "
	    title=""
            band=$(echo ${file#\.\/} | cut -d- -f1)
            album=$(echo $file | cut -d- -f2)
            track=$(echo ${file%\.mp3} | cut -d- -f3)
	    tracknum=${track#0}
	    band=${band//_/ }
	    album=${album//_/ }
	    resource_url="$(curl --get --data-urlencode "release_title=$album" --data-urlencode "artist=$band" "http://api.discogs.com/database/search?type=release" --user-agent "FooBarApp/3.0" | getJsonVal.sh "['results'][0]['resource_url']")"
	    if [ $? -eq 0 ] && [ "x$resource_url" != "x" ];then
		    url=${resource_url//\"/}
		    curl --get $url > tmpjson 
		    title="$(getJsonVal.sh "['tracklist'][$((tracknum - 1))]['title']" < tmpjson)"
		    year="$(getJsonVal.sh "['year']" < tmpjson)"
		    #pic=$(getJsonVal.sh "['images'][0]['uri150']" < tmpjson) only for subscribes users
		    rm -f tmpjson
	    fi
	    if [ "x$title" = "x" ];then
	    	echo "no trackname found"
	        id3v2  -a "$band" -A "$album" -T $track -t "Track $track" $file || echo "error setting tags"
	    else
		id3v2  -a "$band" -A "$album" -T $track -y ${year//\"/} -t "$title" $file || echo "error setting tags"
		echo "trackname : $title"
	    fi
        fi
    fi
done
}
doit $1

#curl --get --data-urlencode "release_title=luz rebelde" --data-urlencode "artist=skalariak" "http://api.discogs.com/database/search?type=release" --user-agent "FooBarApp/3.0"
