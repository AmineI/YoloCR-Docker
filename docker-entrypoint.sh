#!/bin/bash

## This runs an OCR on all the videos in the working directory.
## The config used are from Default<env variables<conf file


#Import project configuration variables
source *.conf

OCRVideoFile(){
    filesDir=$(pwd)
    file="${1}"
    basename="${file%.*}";ext="${file##*.}"
    msg="Processing $file with SeuilI=${SeuilI} and SeuilO=${SeuilO}"
    filtered_basename="${basename}_filtered($SeuilI-$SeuilO)"
        echo $msg 
        #TODO Eventually change subfolder names ?
        mkdir -p "$basename/" #($SeuilI-$SeuilO)/"
        cd "$basename/" #($SeuilI-$SeuilO)/"

## Filter    
        filtered="${filtered_basename}.$ext"

        vspipe -y \
            --arg FichierSource="$filesDir/$file" \
            --preserve-cwd \ #Without this VSPipe overrides the working directory with the script path, which is undesired. 
            "${frameArgs[@]}" \
            /YoloCR/YoloCR.vpy - | ffmpeg -hide_banner -i - -c:v mpeg4 -qscale:v 3 -y "$filtered"

## OCR
        /YoloCR/YoloCR.sh "$filtered" $OCR_LANG

## Cleanup
    if [[ -z $KEEPDATA ]];
    then  #We proceed to cleanup intermediate files only if the "KEEPDATA" environment variable is not set.
        rm -rf "./ScreensFiltrés/" "./TessResult/"
        rm -f "./SceneChanges*.log" "./Timecodes*.txt" "./$filtered" "../$file.ffindex"
    fi
    cd .. 
    echo -e "\033[0;32m Output in ${filtered_basename}\e[0m"
}

for file in *.$FILEEXT; do
    OCRVideoFile "$file"
done

echo "Finished."