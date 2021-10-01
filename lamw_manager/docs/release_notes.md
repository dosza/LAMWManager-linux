# LAMW Manager Release Notes
This page contains information about new features and bug fixes.

v0.4.0.5 - Set 30, 2021
---
**News**
+	Migrate Zulu OpenJDK to [Adoptium](https://adoptium.net/) OpenJDK 8
+	Update Getting Started.txt

**Fixed**
+	Get Current Version LAMW Manager
+	Missing Google Play Store API
+	Add install psmisc (APT) dependencie

v0.4.0.4 - Set 12, 2021
---

**Fixes:**
+	**Backported from v0.4.1**
	+	Remove deprecated symbolic links
	+	Add /Update\<FppkgConfigFile\> tag (*and attributes*) in \~/.lamw4linux/environmentoptions.xml
	+	Auto Repair: Missing \~/.lamw4linux folder:
    	+	Recreate lamw4linux settings
    	+	Recreate LAMW.ini

v0.4.0.3 - Jul 28, 2021
---
**News:**
+	Apache Ant 1.10.11
+	Hybrid install: latest version that will work with Apache Ant!
+	Hybrid install: new *Android Command Line Tools* to get Android API's and Apache Ant + JDK 8.
+	[*headers*](https://github.com/dosza/LAMW4Linux-installer/blob/v0.4.0/lamw_manager/core/headers) module was divided in new submodule: [*lamw4linux_env*](https://github.com/DanielOliveiraSouza/LAMW4Linux-installer/tree/v0.4.0/lamw_manager/core/headers/lamw4linux_env.sh)
+	**Backported from v0.4.1**:  
	+	FPC i386/amd64-android crosscompile ! 
+	Removed code deprecated

v0.4.0.2 - Jul 27, 2021
---
**News:**
+	Apache Ant is no longer officially supported (*in fresh instalation*)
+	Get Current Widget from idemake.cfg and pass to *lazbuild*
+	Now: LAMW Manager uses new **Android Commmand Line Tools**
+	LAMW Manager can execute *sdkmanager* with params
+	Wrong permission: idemake.cfg
+	Fix parser proxy options

v0.4.0.1 - Jul 18, 2021
---
**News:**
+	LAMW Manager now supports JDK 8 on Debian GNU/Linux 
+	Now LAMW Manager installs OpenJDK in *$ROOT_LAMW/jdk*
+	Now the default OpenJDK distribution is ZuluOpenjdk and the default version is JDK 8 
+	The [*api*](https://github.com/DanielOliveiraSouza/LAMW4Linux-installer/tree/v0.4.0/lamw_manager/core/installer/api.sh) submodule has been updated to support getting the latest version of JDK8
+	update-alternatives --config java no longer run on the system
+ 	*\$LAMW_USER* and *\$LAMW_USER_HOME* is passed by env command.

v0.4.0 - Jun 20, 2021
---
**News:**
+	Android NDK r22b
+	FPC 3.2.0 has replaced to FPC 3.2.2
+	Support **Selected folder install**,  using environment variable *LOCAL_ROOT_LAMW*'
+ 	Ubuntu 16.04 LTS is no longer officially supported!

**Fixed:**
+	Fix unnecessary delete fpc/lazarus sources folder to *svn cleanup*
+	Add validation before delete files created by LAMW Manager


v0.3.6.2 - May 6, 2021
---
**News:**
+	Lazarus 2.0.12

**Fixed:**
+	Help menu fixed, to lamw_manager_setup.sh users!
+	Prevent multiple lamw_manager instances execution!


v0.3.6.1 - February 5, 2021
---
**Fixed:**
+	Add minimal built tools requeried by Gradle
+	Setup android 29 libs on fpc.cfg


v0.3.6 - November 23, 2020
---
**News:**
+	Gradle 6.6.1
+	Updates minimum usage requirements.
+	**New:** Detects and updates the minimum **Android API's** without the need to install a new version of LAMW Manager!
+	Add New module [*api.sh*](https://github.com/DanielOliveiraSouza/LAMW4Linux-installer/tree/v0.3.6/lamw_manager/core/installer/api.sh) to get Gradle and Android APIS	

**Fixed:**
+	Try run pkexec in tty


v0.3.5 - R1 August 6, 2020
---
**Fixed:**
+	Missing Android API's
+	Fix: *--reset-aapis*


v0.3.5 - July 19, 2020
---
**News:**
+	Android NDK r21d
+	Apache Ant 1.10.8
+	Gradle 6.1.1
+	FPC 3.2.0 *beta* has replaced *stable*
+	Lazarus 2.0.10
+	New FPC installation method without using APT!
+	Debian GNU/ Linux 9 is no longer officially supported!
+	The [*core*](https://github.com/DanielOliveiraSouza/LAMW4Linux-installer/tree/v0.3.5/lamw_manager/core) module was divided into four sub-modules: [*cross-builder*](https://github.com/dosza/LAMW4Linux-installer/tree/v0.3.5/lamw_manager/core/cross-builder), [*headers*](https://github.com/dosza/LAMW4Linux-installer/tree/v0.3.5/lamw_manager/core/headers), [*installer*](https://github.com/DanielOliveiraSouza/LAMW4Linux-installer/tree/v0.3.5/lamw_manager/core/installer) and [*settings-editor*](https://github.com/DanielOliveiraSouza/LAMW4Linux-installer/tree/v0.3.5/lamw_manager/core/settings-editor)
	
**Fixed:**
+	Missing *fpcres*

v0.3.4 - R1 - May 20, 2020
---
**News:**
+	Lazarus 2.0.8
+	Update Lazarus version on \~/.lamw4linux/environmentoptions.xml

**Fixed:**	
+	Fixed --reset and --uninstall commands
	
v0.3.4 - March 10, 2020
---
**News:**
+	Add/fixs Path to FPCSourceDirectory  ~/.lamw4linux/environmentoptions.xml
+	Optmization code on core/common-shell.sh
	
**Fixed:**
+	Fix --update-lamw: cannot executable lamw4linux
+	Fix error: detect fpc-laz
+	Error: Exit without Install APT Dependencies
+	Prevent error: install unrar packager
	
v0.3.3 - R2 - February 25, 2020
---
**Fixed:**
	
+	Error: Build Lazarus with FPC 3.2.0
	
v0.3.3 - R1 - December 3, 2019
---
**Fixed:**
	
+	Error: Install APT Dependencies on Debian 10 Buster
	
v0.3.3 - November 26, 2019
---
**News:**
+	Android NDK r20b
+	Apache Ant 1.10.7
+	Gradle 4.10.3
+	Lazarus 2.0.6
+	Install new LAMW package: *FCL Bridges*!
+	Introducing a new installer : *lamw_manager_setup.sh*
+	Add (transparent) support for non-sudo admin users
+	Now LAMW Manager prevents **APT/dpkg** lock error
+	Detect and uses fpc-laz to provide FPC compiler
+	Adds JDK 11 Support for systems without JDK8
+	Remove unnecessary files and rearrange directory structure
+	Fusion the lamw_manager and lamw-manager files.
+	**modules** directory has renamed to **core**
	
**Fixed:**
+	Error run command : *fpcmkcfg* with *fpc-laz*
+	Fix incompatibility with *fpc-laz* and *lazarus-project*   
		

v0.3.2 - R1 - September 8, 2019
---
**Fixed:**
+	Apache Ant URL

v0.3.2 - August 19, 2019
---
**News:**
+	FPC 3.2.0
+	Lazarus 2.0.4
+	Android API's platform 28
+	Android Build Tools 28.0.3
+	Your now open Projects from File Manager
+	Start LAMW4Linux from the terminal with the command: *startlamw4linux*
	
**Fixed:**
	
+	PPC_CONFIG_PATH fixed
+	FPC *trunk* has replaced to FPC 3.2.0
		
v0.3.1 - August 1, 2019
---
**News:**
	
+	FPC 3.3.1(trunk)
+	Build Freepascal - 3.3.1 x86_64/Linux
+	Build Freepascal Cross-compile ARMv7/Android
+	Build Freepascal Cross-compile ARM64/Android
+	Lazarus 2.0.2
+	Clean CLI Messages
+	Add *--reset-aapis* command, to clean and Reinstall Android API's
	
**Fixed:**	
+	Removed  unecessary messages!
		
v0.3.0 - May 10, 2019
---
**News:**
+	Update FPC to 3.0.0 to 3.0.4 on Ubuntu 16.04/Linux Mint 18
+	Add Auto Repair to fixs FPC
	
**Fixed:**	
+	Fix Uninstaller
+	Fix missing ppcrossarm
	

