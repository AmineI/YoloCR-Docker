# [YoloCR](https://bitbucket.org/YuriZero/yolocr/src)

## Requirements

Global Requirements for all the OS.

### Global Requirements

* ffmpeg
* Vapoursynth R27+
	* plugins for Vapoursynth : 
		* [FFMS2](https://github.com/FFMS/ffms2)
		* [HAvsFunc](http://forum.doom9.org/showthread.php?t=166582)
		* [SceneChange](http://forum.doom9.org/showthread.php?t=166769)
		* [fmtconv](http://forum.doom9.org/showthread.php?t=166504)
		* *optional*: [nnedi3_rpow2](http://forum.doom9.org/showthread.php?t=172652)
		* *very optional*: [Waifu2x-w2xc](http://forum.doom9.org/showthread.php?t=172390)
 * [Vapoursynth Editor](https://bitbucket.org/mystery_keeper/vapoursynth-editor)

### Unix/Linux Requirements

* plugin for Vapoursynth : [GenericFilters](https://github.com/myrsloik/GenericFilters)
* Tesseract-OCR (we recommend version 3.03+)
	* and install the data corresponding to the languages you want to OCR
* links
* sxiv (Simple X Image Viewer)
* xdotool (Linux only)
* parallel (GNU Parallel)

> *Note*: most of these package, with the exception of all the plugins for vapoursynth, are available as official package for your distro.

> For Debian 8 and LMDE 2, all the requirements can be installed with the YoloDebInstallation script : `sh YoloDebInstallation.sh eng-only`

> For Ubuntu, *vapoursynth*, *vapoursynth-editor* and  *vapoursynth-extra-plugins* (to install all the mandatory plugins above) are available through this ppa: [`ppa:djcj/vapoursynth`](https://launchpad.net/~djcj/+archive/ubuntu/vapoursynth)

### Windows Requirements

* [Tesseract](https://code.google.com/p/tesseract-ocr/downloads/detail?name=tesseract-ocr-setup-3.02.02.exe)
	* and install the language package `eng` or `fra` too.

> You can use ABBYY FineReader instead of Tesseract.

* [Cygwin](https://www.cygwin.com/). During the install, activate:
	* bc
	* gnupg
	* links
	* make
	* perl
	* wget

* Install `GNU Parallel` from the Cygwin terminal:
	* `wget -O - pi.dk/3 | bash`
	* `mv ~/bin/parallel /usr/local/bin/`

> *Note*: Cygwin terminal usage here → [https://help.ubuntu.com/community/UsingTheTerminal](https://help.ubuntu.com/community/UsingTheTerminal)

> C drive path is "/cygdrive/c".

>Scripts have to be used within Cygwin terminal.

## How to use?

### Help for determining the parameters for the `YoloCR.vpy` file

#### Determine the Resize parameters.

Resize is very helpful to locate the subtitles.

1. open `YoloResize.vpy` in Vapoursynth Editor.
2. Change this value:
	* `FichierSource` is the path of the video to OCR.
	* `DimensionCropbox` allows you to limit the OCR zone.
	* `HauteurCropBox` allows you to define the height of the Cropbox's bottom border.

> Note that theses two parameters have to be adjusted before upscale.

You can then change `Supersampling` parameter to -1 and verify that your subtitles aren't eated by the white borderline by using **F5**.

#### Determine the threshold of the subtitles

It's to improve the OCR-process and the subtitles detection.

1. Open `YoloSeuil.vpy` in Vapoursynth editor.
2. Report `FichierSource`, `DimensionCropBox` and `HauteurCropBox` you have defined in the `Resize` file.
3. Choose the fitting ModeS. 'L' if you want to define a white or black threshold, succesively 'R', 'G' and 'B' otherwise.
4. Adjust the Threshold by using **F5**.

You must to do this two times:

* in the first case, the Inline threshold have to be as high as possible, and subtitles must remain completely visible.
* in the second case, the Outline threshold have to be as low as possible, completely black, subtitles must remain completely visible.

### Filter the video

1. Edit the first lines in `YoloCR.vpy` thanks to the two previos steps (and the previous file `YoloSeuil.vpy`).
	* SeuilI = the inline threshold value
	* seuilO = the outline threshold value
 
2. Then filter it: `vspipe -y YoloCR.vpy - | ffmpeg -i - -c:v mpeg4 -qscale:v 3 -y nameOftheVideoOutput.mp4`

> Be careful: your must use a different name for your `FichierSource` in the previous files and `nameOftheVideoOutput.mp4` for the output of the ffmpeg command.

You now have an OCR-isable video and scenechange informations.

### OCR the video

Then you can OCR the video: `./YoloCR.sh nameOftheVideoOutput.mp4`

> The `nameOftheVideoOutput.mp4` must be the same than the output of the ffmpeg command.

**Now it's Checking time :D**

## Known bugs

* Cygwin (Windows), when you run YoloCR.sh for the first time.
	* Signal SIGCHLD received, but no signal handler set.
	* YoloCR will run without errors the next times.
* Babun (Windows), you will have errors when trying to run YoloCR.sh.
	* Use Cygwin instead.

Contact: irc://irc.rizon.net/seigi-fr