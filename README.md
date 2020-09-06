YoloCR, optimized for Docker.
==============

YoloCR is a convenient OCR script, forked from https://git.clapity.eu/Id/YoloCR

This is a docker-ized version of that project.

*Why ?* Well, considering the many dependencies to build and prepare to set this up (see [original README](README_EN.md)), I just did not want to pollute my WSL install or create a heavy dedicated environment/VM just for this considering how low on space I was. 

So, this Docker project achieves to make it fit in a ~200MB compressed image, instead of a 9GB VM. I'm quite happy with that, to be fair. I used Docker [multi-stage build](https://docs.docker.com/develop/develop-images/multistage-build/) to achieve such a result, by building the sources separately and then installing the built packages on the final image, without , without any build dependencies or leftovers.

I wondered whether to build FFMPEG from source to size it down even more, but ultimately decided against it. You can do so if you have specific needs, it can save you a lot of space !

Preparation
=======

You *will* have to read the  [original README](README_EN.md), to learn how to use the original project first. 

You'll notice that you need to **first determine the required parameters** : thresholds, pixel areas, and some others. Note that the main author is french, and they made the parameter names as well.

Without having a GUI in the container, tools like [this](https://github.com/yangcha/iview) can help you find the relevant parameters : both for colors thresholds or crop box coordinates.

Once the parameters are figured out, you can create a .conf file to store these, following this [template file](_default.conf), or just write them down to then add them as environment variables while running the tool.

Finally, **Prepare a data volume** that will act as the input/output directory. Put the video file(s) you want to OCR in there, and an eventual configuration file to use for these, and the container will spit out OCR results in this volume.

I also assume you're a bit familiar with Docker and Linux. If you're using this on Windows, you are advised to do so through WSL, for example if you want to mount a folder as a volume in your docker container.

Usage
=======

Start a container with your data volume mounted to /data, and with the parameters you want as environment variables or in a config file in the data volume.

```
docker run -it -v:"THE/FOLDER/YOU/WANT/TO/PROCESS":/data amine1u1/yolocr
```
or 
```
docker run -it -v:"THE/FOLDER/YOU/WANT/TO/PROCESS":/data amine1u1/yolocr -e "DimensionCropBox=1344,150"
```

Once done, the container will create a folder with a .srt subtitle file for each input file, with the OCR results according to the parameters you set. 

Two additional environment variables are available :

- `FILEEXT`, which defaults to "mp4", is the comma separated list of fileextensions to process
- `KEEPDATA` is an optional environment variable. If set to anything, the temporary working data, such as time codes, ScenesChanges, and working screenshots, will be copied to your data volume on completion. 


If you ever need a reminder of the standard YoloCR parameters, you can refer to the [template configuration file](_default.conf), which holds both the default values and comments about how to use these parameters.
