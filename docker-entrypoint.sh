#!/bin/bash

## This runs an OCR on all the videos in the working directory.
## The config used are from Default<env variables<conf file


#Import project configuration variables
source *.conf
#TODO print current config ?

OCRVideoFile(){
    filesDir=$(pwd)
    file="${1}"
    basename="${file%.*}";ext="${file##*.}"
    msg="Processing $file with SeuilI=${SeuilI} and SeuilO=${SeuilO}"
    filtered_basename="${basename}_filtered($SeuilI-$SeuilO)"

    if [[ ! -z $FRAMES ]];
    then
        #If test frames ranges were specified (like "1-1000"), we create a filtered video with only these frames
        IFS='-' read -ra frames <<< $FRAMES
        msg+=" from frames ${frames[0]} to ${frames[1]}"
        filtered_basename+="_${frames[0]}-${frames[1]}"
        frameArgs=("--start" "${frames[0]}" "--end" "${frames[1]}")
    fi
        echo $msg 

## Create a temporary working dir
        mkdir -p "/tmp_YolOCR/$filtered_basename/"
        cd "/tmp_YoloCR/$filtered_basename"

## Filter    
        filtered="${filtered_basename}.$ext"

        vspipe -y \
            --arg FichierSource="$filesDir/$file" \
            --preserve-cwd \
            "${frameArgs[@]}" \
            /YoloCR/YoloCR.vpy - | ffmpeg -hide_banner -i - -c:v mpeg4 -qscale:v 3 -y "$filtered"
#Without --preserve-cwd VSPipe overrides the working directory with the script path, which is undesired. 
            
## OCR
        /YoloCR/YoloCR.sh "$filtered" $OCR_LANG

## Copy output

    #TODO Eventually change subfolder names ?
    mkdir -p "$filesDir/$basename/" #($SeuilI-$SeuilO)/"

    cp "$filtered_basename.srt" "$filesDir/$basename"

    if [[ ! -z $KEEPDATA ]];
    then  #We proceed to copy intermediate files to the output folder only if the KEEPDATA environment variable is set.
        cp -r "./ScreensFiltrés" "./TessResult" "$filesDir/$basename"
        cp "./SceneChanges.log" "./Timecodes.txt" "./$filtered" "$filesDir/$basename"
    fi

    cd $filesDir
    echo -e "\033[0;32m Output in ${filtered_basename}\e[0m"
}


shopt -s nullglob
#nullglob means that nothing will be done if no files match the below expression
# instead of running the loop with a the literal "*.mp4"

for file in *.$FILEEXT; do
    OCRVideoFile "$file"
done

echo "Finished."