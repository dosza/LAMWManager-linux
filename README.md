# LAMW Manager

[![Version](https://img.shields.io/badge/Release-v0.4.1-blue)](https://github.com/dosza/LAMWManager-linux/blob/v0.4.1/lamw_manager/docs/release_notes.md#v0415---set-18-2021) [![Build-status](https://img.shields.io/badge/build-stable-brightgreen)](https://raw.githubusercontent.com/dosza/LAMWManager-linux/master/lamw_manager/assets/lamw_manager_setup.sh) [![license](https://img.shields.io/github/license/danieloliveirasouza/lamw4linux-installer)](https://github.com/dosza/LAMWManager-linux/LICENSE) [![Language](https://img.shields.io/badge/-%23!%2Fbin%2Fbash-1f425f.svg?logo=image%2Fpng%3Bbase64%2CiVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAyZpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw%2FeHBhY2tldCBiZWdpbj0i77u%2FIiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8%2BIDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDUuNi1jMTExIDc5LjE1ODMyNSwgMjAxNS8wOS8xMC0wMToxMDoyMCAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIENDIDIwMTUgKFdpbmRvd3MpIiB4bXBNTTpJbnN0YW5jZUlEPSJ4bXAuaWlkOkE3MDg2QTAyQUZCMzExRTVBMkQxRDMzMkJDMUQ4RDk3IiB4bXBNTTpEb2N1bWVudElEPSJ4bXAuZGlkOkE3MDg2QTAzQUZCMzExRTVBMkQxRDMzMkJDMUQ4RDk3Ij4gPHhtcE1NOkRlcml2ZWRGcm9tIHN0UmVmOmluc3RhbmNlSUQ9InhtcC5paWQ6QTcwODZBMDBBRkIzMTFFNUEyRDFEMzMyQkMxRDhEOTciIHN0UmVmOmRvY3VtZW50SUQ9InhtcC5kaWQ6QTcwODZBMDFBRkIzMTFFNUEyRDFEMzMyQkMxRDhEOTciLz4gPC9yZGY6RGVzY3JpcHRpb24%2BIDwvcmRmOlJERj4gPC94OnhtcG1ldGE%2BIDw%2FeHBhY2tldCBlbmQ9InIiPz6lm45hAAADkklEQVR42qyVa0yTVxzGn7d9Wy03MS2ii8s%2BeokYNQSVhCzOjXZOFNF4jx%2BMRmPUMEUEqVG36jo2thizLSQSMd4N8ZoQ8RKjJtooaCpK6ZoCtRXKpRempbTv5ey83bhkAUphz8fznvP8znn%2B%2F3NeEEJgNBoRRSmz0ub%2FfuxEacBg%2FDmYtiCjgo5NG2mBXq%2BH5I1ogMRk9Zbd%2BQU2e1ML6VPLOyf5tvBQ8yT1lG10imxsABm7SLs898GTpyYynEzP60hO3trHDKvMigUwdeaceacqzp7nOI4n0SSIIjl36ao4Z356OV07fSQAk6xJ3XGg%2BLCr1d1OYlVHp4eUHPnerU79ZA%2F1kuv1JQMAg%2BE4O2P23EumF3VkvHprsZKMzKwbRUXFEyTvSIEmTVbrysp%2BWr8wfQHGK6WChVa3bKUmdWou%2BjpArdGkzZ41c1zG%2Fu5uGH4swzd561F%2BuhIT4%2BLnSuPsv9%2BJKIpjNr9dXYOyk7%2FBZrcjIT4eCnoKgedJP4BEqhG77E3NKP31FO7cfQA5K0dSYuLgz2TwCWJSOBzG6crzKK%2BohNfni%2Bx6OMUMMNe%2Fgf7ocbw0v0acKg6J8Ql0q%2BT%2FAXR5PNi5dz9c71upuQqCKFAD%2BYhrZLEAmpodaHO3Qy6TI3NhBpbrshGtOWKOSMYwYGQM8nJzoFJNxP2HjyIQho4PewK6hBktoDcUwtIln4PjOWzflQ%2Be5yl0yCCYgYikTclGlxadio%2BBQCSiW1UXoVGrKYwH4RgMrjU1HAB4vR6LzWYfFUCKxfS8Ftk5qxHoCUQAUkRJaSEokkV6Y%2F%2BJUOC4hn6A39NVXVBYeNP8piH6HeA4fPbpdBQV5KOx0QaL1YppX3Jgk0TwH2Vg6S3u%2BdB91%2B%2FpuNYPYFl5uP5V7ZqvsrX7jxqMXR6ff3gCQSTzFI0a1TX3wIs8ul%2Bq4HuWAAiM39vhOuR1O1fQ2gT%2F26Z8Z5vrl2OHi9OXZn995nLV9aFfS6UC9JeJPfuK0NBohWpCHMSAAsFe74WWP%2BvT25wtP9Bpob6uGqqyDnOtaeumjRu%2ByFu36VntK%2FPA5umTJeUtPWZSU9BCgud661odVp3DZtkc7AnYR33RRC708PrVi1larW7XwZIjLnd7R6SgSqWSNjU1B3F72pz5TZbXmX5vV81Yb7Lg7XT%2FUXriu8XLVqw6c6XqWnBKiiYU%2BMt3wWF7u7i91XlSEITwSAZ%2FCzAAHsJVbwXYFFEAAAAASUVORK5CYII%3D)](https://www.gnu.org/software/bash/) 

LAMW Manager is a command line tool,like *APT*, to automate the **installation**, **configuration** and **upgrade**<br/>the framework [LAMW - Lazarus Android Module Wizard](https://github.com/jmpessoa/lazandroidmodulewizard)

Windows user, please, get here [*LAMW Manager for Windows*](https://github.com/dosza/LAMWManager-win)

What do you get?
---
A [Lazarus IDE](http://www.lazarus-ide.org) ready to develop applications for Android !!


Linux Distro Supported:
---
+	Debian/GNU Linux 10
+	Ubuntu 18.04 LTS
+	[Requirements for other Linux](https://github.com/dosza/LAMWManager-linux/blob/master/lamw_manager/docs/other-distros-info.md)		

LAMW Manager install the following [dependencies] tools:
---
+	Gradle
+	Freepascal Compiler
+	Lazarus IDE Sources
+	Android NDK
+	Android SDK
+	OpenJDK
+	Build Freepascal:
	+	Crosscompile to ARMv7-vFPV3/android
	+ 	Crosscompile to AARCH64/android
	+	**New:** Crosscompile to **i386/android**
	+	**New:** Crosscompile to **amd64/android**
+	Build Lazarus IDE
+	LAMW framework
+	Create launcher to menu
+	Register **MIME**

Getting Started!!
---
**How to use LAMW Manager:**
+	Click here to download [*LAMW Manager Setup*](https://raw.githubusercontent.com/dosza/LAMWManager-linux/master/lamw_manager/assets/lamw_manager_setup.sh)
+	Go to download directory and right click *Open in Terminal*
+	Run command : *bash lamw_manager_setup.sh*¹


**New: Installing LAMW on custom directory**
Now you  can install LAMW on custom directory using command:


```console 
user@pc:~$ #env LOCAL_ROOT_LAMW=your_dir bash lamw_manager_setup.sh
user@pc:~$ #Sample:
user@pc:~$ env LOCAL_ROOT_LAMW=/opt/LAMW bash lamw_manager_setup.sh
```

**Notes:**
+	See the [*LAMW Manager Setup Guide*](https://drive.google.com/open?id=1B6fvTgJ-W7OS7I4mGCZ4sH0U3GqyAeUg)
+	Read more about new installer procedure in [*LAMW Manager Setup*](https://github.com/dosza/LAMWManager-linux/blob/master/lamw_manager/docs/lamw_manager_setup.md)
+	You can also install from sources read more in [*Classic Install*](https://github.com/dosza/LAMWManager-linux/blob/master/lamw_manager/docs/classic-install.md)
+	Replace *your_dir* with the directory of your choice, eg */opt/LAMW*


Release Notes:
---
For information on new features and bug fixes read the [*Release Notes*](https://github.com/dosza/LAMWManager-linux/blob/v0.4.1/lamw_manager/docs/release_notes.md#v0415---set-18-2021)

Congratulations!!
---
You are now a Lazarus for Android developer!</br>[Building Android application with **LAMW** is **RAD**!](https://drive.google.com/open?id=1CeDDpuDfRwYrKpN7VHbossH6GfZUfqjm)

For more info read [**LAMW Manager v0.4.1 Manual**](https://github.com/dosza/LAMWManager-linux/blob/v0.4.1/lamw_manager/docs/man.md)
