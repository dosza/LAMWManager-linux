# Other distro Requerements #


Introduction 
---

The LAMW Manager was originally designed to work on Debian-based Linux distributions.
It is recommended to use the systems listed in [README.md](https://github.com/dosza/LAMWManager-linux#linux-distro-supported) .
For systems based on Ubuntu, the ideal is to use [LTS](https://ubuntu.com/about/release-cycle) versions.
In these systems, no additional steps are required.

Other Linux Distributions
---
From version 0.5.2 it is possible to use the LAMW Manager in other Linux distributions, without major complications.
To do so, just install (using your system's package manager) the necessary packages to compile lazarus , freepascal and the specifics of the lamw manager.


## Requirements ##

### Important ### 

+	**./lamw_manager** (or **lamw_manager_setup.sh**) must not be invoked with root privileges
+ 	User must be able to run commands with [Polkit](https://wiki.archlinux.org/title/Polkit) or sudo

The LAMW Manager will look for these tools and libraries, indicate which libraries are missing and indicate which debian package contains them, so that you can install an equivalent package on your system.

### Tools ###

git,gdb, binutils,make, **fuser**, unzip, zip, wget, **jq**, **xmlstarlet**,

### Libraries and headers ###

x11,gtk2,pango,gdk-pixbuf2.0,xtst,atk1,freeglut3

Are equivalent to command

```bash 
sudo apt-get install git gdb binutils make psmisc build-essential unzip zip wget jq xmlstarlet -y
sudo apt-get install libx11-dev libgtk2.0-dev libgdk-pixbuf2.0-dev libcairo2-dev libpango1.0-dev libxtst-dev libatk1.0-dev freeglut3 freeglut3-dev -y
```

After installing the dependencies on the system, you will be able to run lamw_manager

Compatible Linux Distro
---
+	[Fedora **GNOME**](#Fedora)
+	[Manjaro **KDE**](#Manjaro)
+	[Slackware **XFCE**](#Slackware)


### Fedora ###

```bash
	sudo dnf install libX11-devel.x86_64 libX11.x86_64 gdk-pixbuf2.x86_64 gdk-pixbuf2-devel.x86_64 librsvg2.x86_64 pango-devel.x86_64 freeglut-devel.x86_64 libXtst-devel.x86_64 atk-devel.x86_64 gtk2-devel.x86_64 wget.x86_64 git.x86_64 xterm make.x86_64  gdb.x86_64 zip.x86_64 unzip.x86_64 jq.x86_64 xmlstarlet.x86_64 -y
```

### Manjaro ###
```bash 
	sudo pacman -Syyu gtk2 binutils make unzip gdb xterm jq xmlstarlet wget git zenity --noconfirm
```

### Slackware ###
+	You need install: jq, xmlstarlet, xterm ( to XFCE users)
	+	tips: 
		+	use [sbopkg](https://sbopkg.org/) or [slapt-get](https://github.com/jaos/slapt-get) and [slapt-src](https://github.com/jaos/slapt-src)