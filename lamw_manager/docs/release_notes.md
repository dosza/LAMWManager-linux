# LAMW Manager Release Notes

This page contains information about new features and bug fixes.

v0.5.3 - Jan 7, 2023
--
**Fixes**
+	Fixes fpc source code path in git (ambiguous path)
+	Fixes missing bc

**News**
+	Optimizes LAMW4Linux installation/update time
	+	Use multi-thread in build lazarus
	+	Do git clone *\-\-jobs* param.

v0.5.2 - Dec 21, 2022
--
**Fixes**
+	Remove unnecessary APT dependencies.
+	Prevents lamw_manager from not installing in \~/snap and /usr/lib/lazarus folders

**News**
+	Adds support to user's sudo from wheel group
+	Adds experimental support to downgrade Lazarus Project
+	Expands templates and simplify the [*settings-editor*](https://github.com/dosza/LAMWManager-linux/blob/master/lamw_manager/core/settings-editor)
+	*\-\-minimal* option can now be combined with *\-\-reset*, *\-\-reinstall*
+	Added experimental functionality: allows running lamw manager on non-debian based systems
	+	It only requires the user to install the libraries and utilities to run lamw_manager
	+	Automatically detect missing dependencies
+	LAMW Manager installs faster than previous versions.
+	Compiles freepascal using multi-threading processing.
+	Check tools download integrity before extracting


v0.5.1 - Ago 18, 2022
---
**Fixes**
+	Fixes missing /tmp/lamw_manager_setup.sh in assets/build-lamw-setup
+	Fixes duplicate ```[safe]``` settings in *\~.gitconfig*
+	Prevents downgrade of package.xml in cmdline-tools/latest
+	Adds support to old format of package.xml in cmdline-tools

**News**
+	Adds templates in [*settings-editor*](https://github.com/dosza/LAMWManager-linux/blob/master/lamw_manager/core/settings-editor)


v0.5.0 - Jun 12, 2022
--
**Fixes**
+	Fixes wrong ld path on try build lazarus project to linux/x86_64

**News**
+	Adds new commands to LAMW4Linux Terminal, you can run directly (with auto-complete  tab)
	+	sdkmanager
	+	advmanager
	+	lamw_manager

v0.4.8 - Mar 8, 2022
---
**Fixes**
+	Fixes get LAMW Environment
+	Adds validation before delete *\$ANDROID_HOME*, *\$GRADLE_HOME* from \~/.bashrc

**News**
+	Ubuntu 18.04 LTS is no longer officially supported!
+	*LAMW4Linux Terminal*, to run FPC, lazarus and LAMW scripts now is avalaible on start menu!
+	Now LAMW Manager not add *\$GRADLE_HOME* and *\$ANDROID_HOME/ndk-toolchain* in \~/.bashrc!!
+	**Recommended:** use LAMW4Linux Terminal!
+	LAMW4Linux Terminal starts from on your Current LAMW Workspace directory!!
+	**Warning:** from now on *lamw_manager_setup.sh* from [*assets*](https://github.com/dosza/LAMWManager-linux/tree/master/lamw_manager/assets) will not be available!

**Note**: LAMW4Linux Terminal your LAMW Workspace from \~/.lamw4linux/LAMW.ini !

v0.4.7 - Feb 19, 2022
---
**News**
+	Build LAMW Packages in silence mode
+	Uninstall old gradle (from old package.json) automatically 
+ 	Verify duplicated export LAMW Environment
+	Adjust *--minimal* to install only what is strictly necessary for LAMW development 

v0.4.6 - Feb 11, 2022
---
**News:**
+	Adds *lazbuild* startup script on *\$LAMW4LINUX_HOME/usr/bin* with PPC_CONFIG_PATH and --pcp params
+	Build FPC and Lazarus base on silence mode
+	Adds new command *--minimal*, to install only minimal fpc/lazarus crosscompile to Android.

**Fixes**
+	Remove unnecessary *[core.cross-builder](https://github.com/dosza/LAMWManager-linux/tree/e1a9311804f66f19044a1a2150d721afe1624a08/lamw_manager/core/cross-builder)* functions

v0.4.5 - Jan 26, 2022
---
**Fixes**
+	Fixes missing *xmlstarlet*
+	Remove deprecated code from subversion actions 

**News**
+	Autostart LAMW4Linux after first install

v0.4.4 - Dec 31, 2021
---
**Fixes**
+	Remove unnecessary files to fpc builder (*bootstrap*)

**News**
+	Module [*api.sh*](https://github.com/dosza/LAMWManager-linux/tree/v0.4.3/lamw_manager/core/installer/api.sh) has renamed to [*services.sh*](https://github.com/dosza/LAMWManager-linux/tree/v0.4.4/lamw_manager/core/installer/services.sh)
+	 Experimental mitigation to [*Xfce Terminal bug*](https://github.com/jmpessoa/lazandroidmodulewizard/issues/110)

v0.4.3.1 - Dec 13, 2021
---
**Fixes**
+	Get Current *\$ROOT_LAMW_PARENT*

v0.4.3 - Dec 11, 2021
---
**Fixes**
+	Fixed: Fix wrong permissions in *\$ROOT_LAMW* parent directory

**News**
+	The module [*api.sh*](https://github.com/dosza/LAMWManager-linux/tree/v0.4.3/lamw_manager/core/installer/api.sh)<br/>has been upgrated to get path of LAMW Packages *\*.lpk*

v0.4.2.2 - Dec 2, 2021
---
**Fixes**
+	Fix get Current *\$LAMW_MGR_CORE*


v0.4.2.1 - Nov 15, 2021
---
**News**
+	Stop Gradle before to run *lamw_manager*
+   Move setRootLAMW, getRootLAMW to new module [*Root LAMW Settings Editor*](https://github.com/dosza/LAMWManager-linux/tree/v0.4.2/lamw_manager/core/settings-editor/root-lamw-settings-editor.sh)
+	LAMW Manager Setup now prioritizes PKEXEC (if supported) for administrative privileges


**Fixes**
+	Fixes get instalation Status using *\$LOCAL_ROOT_LAMW*

v0.4.2 - Out 26, 2021
---
**Fixes**
+	Fixes error on try add first *jButton* on Lazarus 2.2.0 RC1<br/>
**Warning: Lazarus has been downgraded to version 2.0.12**

**News**
+	Add description of **LAMW4Linux** on Start Menu 


v0.4.1.6 - Set 30, 2021
---
**Fixes**
+	Fixes GetCurrent LAMW Manager Version

**News**
+	Update Getting Started.txt

v0.4.1.5 - Set 18, 2021
---
**Fixed**
+	Missing Google Play Store API
+	Add install psmisc (APT) dependencie

v0.4.1.4 - Set 16, 2021
---
**News**
+	Get JDK from [Adoptium](https://adoptium.net) API ( [sucessor of AdoptOpenJDK](https://blog.adoptopenjdk.net/2021/03/transition-to-eclipse-an-update/))

v0.4.1.3 - Set 12, 2021
---
**Fixes**
+	Error on start lamw4linux on command line

v0.4.1.2 - Aug 20, 2021
---
**News**
+	Adds /Update\<FppkgConfigFile\> tag (*and attributes*)  in  \~/.lamw4linux/environmentoptions.xml

**Fixed**
+	Remove deprecated symbolic link: \~LAMW/lamw4linux/lamw4linux
+	Auto Repair: Missing \~/.lamw4linux folder:
	+	Recreate lamw4linux settings
	+	Recreate LAMW.ini

v0.4.1.1  - Aug 5, 2021
---
**News**
+	Lazarus 2.2.0RC1
+	Remove unnecessary verbose on extract files 
+	Crosscompile to i386/amd64 Android
+	*starlamw4linux* uses exec to load *lamw4linux*

**Fixed**
+	Get Freepascal Sources from SourceForge (while FPC migrates to gitlab)

v0.4.1 - Jul 27, 2021
---
**News**
+	Apache Ant¹ is no longer officially supported
+	JDK default (installed by LAMW Manager) version is *11* using build from *AdoptOpenJDK*
+	The [*api*](https://github.com/dosza/LAMWManager-linux/tree/v0.4.1/lamw_manager/core/installer/api.sh) submodule has been updated to get JDK11 from AdoptOpenJDK API

**Fixes**
+	Error:build lazarus: *unknown gtk2* package (backported from v0.4.0.3)

**Note**

1.	To continue using Apache Ant (hybrid install), you must use [*LAMW Manager Setup v0.4.0.x*](https://github.com/dosza/LAMWManager-linux/releases/download/v0.4.0.10/lamw_manager_setup.sh) 

v0.4.0.3 - Jul 28, 2021
---
**News:**
+	Apache Ant 1.10.11
+	Hybrid install: latest version that will work with Apache Ant!
+	Hybrid install: new *Android Command Line Tools* to get Android API's and Apache Ant + JDK 8.
+	[*headers*](https://github.com/dosza/LAMWManager-linux/blob/v0.4.0/lamw_manager/core/headers) module was divided in new submodule: [*lamw4linux_env*](https://github.com/dosza/LAMWManager-linux/tree/v0.4.0/lamw_manager/core/headers/lamw4linux_env.sh)
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
+	The [*api*](https://github.com/dosza/LAMWManager-linux/tree/v0.4.0/lamw_manager/core/installer/api.sh) submodule has been updated to support getting the latest version of JDK8
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
+	Fixes unnecessary delete fpc/lazarus sources folder to *svn cleanup*
+	Adds validation before delete files created by LAMW Manager


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
+	Adds minimal build tools required by Gradle
+	Setup android 29 libs on fpc.cfg


v0.3.6 - November 23, 2020
---
**News:**
+	Gradle 6.6.1
+	Updates minimum usage requirements.
+	**New:** Detects and updates the minimum **Android API's** without the need to install a new version of LAMW Manager!
+	Add New module [*api.sh*](https://github.com/dosza/LAMWManager-linux/tree/v0.3.6/lamw_manager/core/installer/api.sh) to get Gradle and Android APIS	

**Fixed:**
+	Try run pkexec in tty


v0.3.5 - R1 August 6, 2020
---
**Fixed:**
+	Missing Android API's
+	Fixes: *--reset-aapis*


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
+	The [*core*](https://github.com/dosza/LAMWManager-linux/tree/v0.3.5/lamw_manager/core) module was divided into four sub-modules: [*cross-builder*](https://github.com/dosza/LAMWManager-linux/tree/v0.3.5/lamw_manager/core/cross-builder), [*headers*](https://github.com/dosza/LAMWManager-linux/tree/v0.3.5/lamw_manager/core/headers), [*installer*](https://github.com/dosza/LAMWManager-linux/tree/v0.3.5/lamw_manager/core/installer) and [*settings-editor*](https://github.com/dosza/LAMWManager-linux/tree/v0.3.5/lamw_manager/core/settings-editor)
	
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
+	Adds/fixs Path to FPCSourceDirectory  ~/.lamw4linux/environmentoptions.xml
+	Optmization code on core/common-shell.sh
	
**Fixed:**
+	Fixed --update-lamw: cannot executable lamw4linux
+	Fixed error: detect fpc-laz
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
+	Adds (transparent) support for non-sudo admin users
+	Now LAMW Manager prevents **APT/dpkg** lock error
+	Detect and uses fpc-laz to provide FPC compiler
+	Adds JDK 11 Support for systems without JDK8
+	Remove unnecessary files and rearrange directory structure
+	Fusion the lamw_manager and lamw-manager files.
+	**modules** directory has renamed to **core**
	
**Fixed:**
+	Error run command : *fpcmkcfg* with *fpc-laz*
+	Fixes incompatibility with *fpc-laz* and *lazarus-project*   
		

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
+	Adds Auto Repair to fixs FPC
	
**Fixed:**	
+	Fixes Uninstaller
+	Fixes missing ppcrossarm
	

