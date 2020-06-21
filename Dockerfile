ARG DEBIAN_FRONTEND=noninteractive
#Prevent prompts blocking the docker build, like packages dependencies such as tzdata
ARG VAPOURSYNTH_PLUGINS="/usr/local/lib/vapoursynth"
ARG BUILT_PACKAGES="/packages" 
ARG TESSDATA="/tessdata"
ARG OCR_LANG="fra"
#Could be switched to other language codes supported by tesseract instead.

FROM ubuntu:20.04 AS base

ENV PYTHONPATH="/usr/local/lib/python3.8/site-packages"\
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

FROM base as builder
WORKDIR /builder
ARG DEBIAN_FRONTEND
ARG VAPOURSYNTH_PLUGINS
ARG BUILT_PACKAGES 
ARG TESSDATA
RUN mkdir -p ${VAPOURSYNTH_PLUGINS} \
    ${BUILT_PACKAGES} \
    ${TESSDATA} \
    ${PYTHONPATH}

RUN apt-get update -qq &&\
apt-get install python3-dev=3.8.2-0ubuntu2 cython3=0.29.14-0.1ubuntu3 \
checkinstall autoconf automake libtool libarchive-tools pkg-config build-essential \
git wget ca-certificates \
--no-install-recommends -q -y &&\
rm -rf /var/lib/apt/lists/*


FROM builder AS zimg-vapoursynth
ARG BUILT_PACKAGES

RUN echo -e "\e[34m -- Building zimg -- \e[0m" &&\
git clone -b v2.9 https://github.com/sekrit-twc/zimg.git && cd zimg &&\
./autogen.sh && ./configure && make -j$(nproc) &&\
checkinstall --default --nodoc --pkgname="zimg" --pkgversion=2.9 \
--pakdir=${BUILT_PACKAGES} && \
cd .. && rm -rf *

RUN echo -e "\e[34m -- Building VapourSynth -- \e[0m" &&\
git clone -b R50 https://github.com/vapoursynth/vapoursynth.git && cd vapoursynth &&\
./autogen.sh && ./configure && make -j$(nproc) &&\
checkinstall --install=no --default --nodoc --pkgname="vapoursynth" --pkgversion=50 \
--pakdir=${BUILT_PACKAGES} && \
cd .. && rm -rf *


FROM builder AS plugins
ARG PYTHONPATH
ARG VAPOURSYNTH_PLUGINS
ARG BUILT_PACKAGES

RUN echo -e "\e[34m -- Installing python plugins : HAvsFunc, mvsfunc, adjust, edi_rpow2 -- \e[0m" &&\
    git clone https://github.com/HomeOfVapourSynthEvolution/havsfunc.git &&\
    git clone https://github.com/HomeOfVapourSynthEvolution/mvsfunc.git &&\
    git clone https://github.com/dubhater/vapoursynth-adjust.git &&\
    git clone https://gist.github.com/020c497524e794779d9c.git vapoursynth-edi_rpow2 &&\
    cp havsfunc/havsfunc.py mvsfunc/mvsfunc.py vapoursynth-adjust/adjust.py vapoursynth-edi_rpow2/edi_rpow2.py ${PYTHONPATH}/ &&\
    rm -rf *


RUN echo -e "\e[34m -- Building VapourSynth plugins : znedi3 -- \e[0m" &&\
    git clone --recursive https://github.com/sekrit-twc/znedi3.git && cd znedi3 &&\
    make -j$(nproc) X86=1 &&\
    cp nnedi3_weights.bin vsznedi3.so ${VAPOURSYNTH_PLUGINS}/ &&\
    cd .. && rm -rf *

RUN echo -e "\e[34m -- Building VapourSynth plugins : fmtconv -- \e[0m" &&\
    git clone -b r22 https://github.com/EleonoreMizo/fmtconv.git && cd fmtconv/build/unix &&\
    ./autogen.sh && ./configure --libdir=${VAPOURSYNTH_PLUGINS} && make -j$(nproc) &&\
    checkinstall --default --install=no --nodoc --pkgname="fmtconv" --pkgversion=22 \
    --pakdir=${BUILT_PACKAGES} && \
    cd ../../.. && rm -rf *

RUN echo -e "\e[34m -- Installing VapourSynth plugins : libffms2 -- \e[0m" &&\
    apt-get update -qq &&\
    apt-get install libffms2-4 \
    --no-install-recommends -q -y &&\
    cp $(dpkg-query -L libffms2-4 | grep libffms2.so | tail -1) ${VAPOURSYNTH_PLUGINS}/libffms2.so && \
    rm -rf /var/lib/apt/lists/*

FROM builder AS tesseract-data
ARG TESSDATA
ARG OCR_LANG

RUN echo -e "\e[34m -- Downloading tesseract trained data -- \e[0m" &&\
    		 wget https://github.com/tesseract-ocr/tessdata/blob/master/${OCR_LANG}.traineddata?raw=true -q -O ${TESSDATA}/${OCR_LANG}.traineddata

FROM base AS final
ARG DEBIAN_FRONTEND
ARG VAPOURSYNTH_PLUGINS
ARG BUILT_PACKAGES
ARG TESSDATA
ARG OCR_LANG
ENV OCR_LANG=${OCR_LANG}

RUN apt-get update -qq &&\
    apt-get install \
        python3.8-minimal libpython3.8\
        links parallel gawk bc file\
        ffmpeg \
        #TODO Building a custom FFMPEG would save a substantial amount of space.
        tesseract-ocr tesseract-ocr-${OCR_LANG} \
        --no-install-recommends -q -y &&\
    rm -rf /var/lib/apt/lists/*


COPY --from=zimg-vapoursynth ${BUILT_PACKAGES} ${BUILT_PACKAGES}
COPY --from=plugins ${BUILT_PACKAGES} ${BUILT_PACKAGES}
COPY --from=plugins ${VAPOURSYNTH_PLUGINS} ${VAPOURSYNTH_PLUGINS}
COPY --from=plugins ${PYTHONPATH} ${PYTHONPATH}

RUN dpkg -i ${BUILT_PACKAGES}/zimg* && \
    dpkg -i ${BUILT_PACKAGES}/vapoursynth* && \
    dpkg -i ${BUILT_PACKAGES}/fmtconv*


#We declare a volume for data, that we set as our workdir to process files in it.
VOLUME /data
WORKDIR /data

COPY ./ /YoloCR
COPY --from=tesseract-data ${TESSDATA} /YoloCR/tessdata

RUN ldconfig
#ldconfig creates the necessary links and cache to the most recent shared libraries
#Needed for vapoursynth to figure out its libraries.

#Default values
ENV FILEEXT="mp4"\
    DimensionCropBox="1344,150" \ 
    OffsetCropBox=46 \ 
    OffsetCropBoxAlt=-1 \ 
    Supersampling=-1  \ 
    ExpandRatio=1  \ 
    ModeU='sinc'  \ 
    SeuilI=230  \ 
    SeuilO=80  \ 
    SeuilSCD=0.03
CMD  ["/YoloCR/docker-entrypoint.sh"]
