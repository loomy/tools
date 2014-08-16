#!/bin/sh
#exec 2>/dev/null

if [ "x$1" = "x" ] ;then
    echo "need file or dirname"
    exit 1
fi

genrestring=""
jsonout=""

checkresults(){
	let i=0
	files=$(ls | wc -l)
	while [ $i -lt $1 ] ;do
		resource_url="$(echo "$2" | getJsonVal.sh "['results'][$i]['resource_url']")"
		jsonlocal=$(curl --get $resource_url 2>/dev/null)
		title="$(echo "$jsonlocal" |getJsonVal.sh "['tracklist'][$((files - 1))]['title']")"
		if [ $? -eq 0 ] && [ "x$title" != "x" ];then
			echo "$resource_url"
			return
		fi
		let i++
	done
	echo "NIX"
}


doit(){
for file in $1 ; do
    echo -en "doing $file: "
    if [ -d $file ];then
        #go into dir
        pushd "$file"
	file=${file%\\}
	band=$(echo ${file#\.\/} | cut -d- -f1)
	album=$(echo $file | cut -d- -f2)
	band=${band//_/ }
	album=${album//_/ }
	genrestring=""
	resource_url="NIX"
	jsonout=$(curl --get --data-urlencode "release_title=$album" --data-urlencode "artist=$band" "http://api.discogs.com/database/search?type=release" --user-agent "FooBarApp/3.0" 2>/dev/null)
	results=$(echo "$jsonout" | getJsonVal.sh "['pagination']['items']")
	if [ $results -gt 1 ];then
		resource_url=$(checkresults $results "$jsonout")
	fi
	[ "$resource_url" = "NIX" ] && resource_url="$(echo "$jsonout" | getJsonVal.sh "['results'][0]['resource_url']")"
	genre=$(echo "$jsonout" | getJsonVal.sh "['results'][0]['genre'][0]")
	if [ $? -eq 0 ] && [ ! -z "$genre" ];then
		genre="${genre//\"/}"
		genr=$(id3v2 -L |grep -i "$genre")
		genr="${genr/: */}"
		[ -z "$genr" ] || genrestring="-g $genr"
	fi
	jsonout=""
	if [ "x$resource_url" != "x" ];then
	    url=${resource_url//\"/}
	    jsonout=$(curl --get $url 2>/dev/null)
	else
		echo -e "nothing found for query http://api.discogs.com/database/search?type=release&release_title=$album&artist=$band"
	fi
        doit "./*"
        popd
    elif [ -f $file ];then
        if [ "$file" != "${file%\.mp3}" ] ;then
		track=$(echo ${file%\.mp3} | cut -d- -f3)
		tracknum=${track#0}
		title="$(echo "$jsonout" |getJsonVal.sh "['tracklist'][$((tracknum - 1))]['title']")"
		year="$(echo "$jsonout" | getJsonVal.sh "['year']")"
	    	#pic=$(echo "$jsonout" | getJsonVal.sh "['images'][0]['uri150']") only for subscribes users
	    if [ "x$title" = "x" ];then
	    	echo "no trackname found"
	        id3v2  -a "$band" -A "$album" -T $track -t "Track $track" "$file" || echo "error setting tags"
	    else
		id3v2  $genrestring -a "$band" -A "$album" -T "$track" -y ${year//\"/} -t "$title" "$file" || echo "error setting tags"
		echo " trackname="$title", genre=$genre"
	    fi
        fi
    fi
done
}
doit $1

#curl --get --data-urlencode "release_title=luz rebelde" --data-urlencode "artist=skalariak" "http://api.discogs.com/database/search?type=release" --user-agent "FooBarApp/3.0"
