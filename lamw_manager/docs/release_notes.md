# LAMW Manager Release Notes
This page contains information about new features and bug fixes.

v0.4.1.1  - Aug 6, 2021
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
+	The [*api*](https://github.com/DanielOliveiraSouza/LAMW4Linux-installer/tree/v0.4.1/lamw_manager/core/installer/api.sh) submodule has been updated to get JDK11 from AdoptOpenJDK API

**Fixes**
+	Error:build lazarus: *unknown gtk2* package (backported from v0.4.0.3)

**Note**

1.	To continue using Apache Ant (hybrid install), you must use [*LAMW Manager Setup v0.4.0.x*](https://github.com/dosza/LAMW4Linux-installer/raw/v0.4.0/lamw_manager/assets/lamw_manager_setup.sh) 

v0.4.0.3 - Jul 28, 2021
---

**News**
+	Hybrid install: latest version that will work with Apache Ant!
+	Hybrid install: new *Android Command Line Tools* to get Android API's and Apache Ant + JDK 8. 

**Fixed**:
+	Error:build lazarus: *unknown gtk2* package

v0.4.0.2 - Jul 27, 2021
---
**News**
+	Apache Ant is no longer officially supported (*in fresh instalation*)
+	Get Current Widget from idemake.cfg and pass to *lazbuild*
+	Now: LAMW Manager uses new **Android Commmand Line Tools**
+	LAMW Manager can execute *sdkmanager* with params

**Fixed**
+	Wrong permission: idemake.cfg
+	Fix parser proxy options

v0.4.0.1 - Jul 18, 2021
---

**News**
+	LAMW Manager now supports JDK 8 on Debian GNU/Linux 
+	Now LAMW Manager installs OpenJDK in *$ROOT_LAMW/jdk*
+	Now the default OpenJDK distribution is ZuluOpenjdk and the default version is JDK 8 
+	The [*api*](https://github.com/DanielOliveiraSouza/LAMW4Linux-installer/tree/v0.4.0/lamw_manager/core/installer/api.sh) submodule has been updated to support getting the latest version of JDK8

**Fixed**
+	update-alternatives --config java no longer run on the system
+ 	*\$LAMW_USER* and *\$LAMW_USER_HOME* is passed by env command.

v0.4.0 - Jun 20, 2021
---
**News**
+	Android NDK r22b
+	FPC 3.2.0 has replaced to FPC 3.2.2
+	Support **Selected folder install**,  using environment variable *LOCAL_ROOT_LAMW*'
+ 	Ubuntu 16.04 LTS is no longer officially supported!


**Fixed**
+	Fix unnecessary delete fpc/lazarus sources folder to *svn cleanup*
+	Add validation before delete files created by LAMW Manager


v0.3.6.2 - May 6, 2021
---
**News**
+	Lazarus 2.0.12

**Fixed**
+	Help menu fixed, to lamw_manager_setup.sh users!
+	Prevent multiple lamw_manager instances execution!


v0.3.6.1 - February 5, 2021
---
**Fixed**
+	Add minimal built tools requeried by Gradle
+	Setup android 29 libs on fpc.cfg



v0.3.6 - November 23, 2020
---
<p>
	<strong>NEWS:</strong>
	<ul>
		<li>Gradle 6.6.1</em></li>
		<li>Updates minimum usage requirements.</li>
		<li><strong>New:</strong> Detects and updates the minimum <strong>Android API's</strong> without the need to install a new version of LAMW Manager!</li>
		<li>Add New module <a href="https://github.com/DanielOliveiraSouza/LAMW4Linux-installer/tree/v0.3.6/lamw_manager/core/installer/api.sh">api.sh</a> to get Gradle and Android APIS</li>
	</ul>
	<strong>FIXED:</strong>
	<ul>
		<li>Try run pkexec in tty</em></li>
	</ul>
</p>

v0.3.5 - R1 August 6, 2020
---
<p>
	<strong>FIXED:</strong>
	<ul>
		<li>Missing Android API's</em></li>
		<li>Fix: <em>--reset-aapis</em></li>
	</ul>
</p>


v0.3.5 - July 19, 2020
---
<p>
	<strong>NEWS:</strong>
	<ul>
		<li>Android NDK r21d</li>
		<li>Apache Ant 1.10.8</li>
		<li>Gradle 6.1.1</li>
		<li>FPC 3.2.0 <em>beta</em> has replaced <em>stable</em></li>
		<li>Lazarus 2.0.10</li>
		<li>New FPC installation method without using APT!</li>
		<li>Debian GNU/ Linux 9 is no longer officially supported!</li>
		<li>The <em><a href="https://github.com/DanielOliveiraSouza/LAMW4Linux-installer/tree/v0.3.5/lamw_manager/core">core</a></em> module was divided into four sub-modules: <em> <a href="https://github.com/DanielOliveiraSouza/LAMW4Linux-installer/tree/v0.3.5/lamw_manager/core/cross-builder">cross-builder</a>, <a href="https://github.com/DanielOliveiraSouza/LAMW4Linux-installer/tree/v0.3.5/lamw_manager/core/headers">headers</a>, <a href="https://github.com/DanielOliveiraSouza/LAMW4Linux-installer/tree/v0.3.5/lamw_manager/core/installer">installer</a></em> and <em> <a href="https://github.com/DanielOliveiraSouza/LAMW4Linux-installer/tree/v0.3.5/lamw_manager/core/settings-editor">settings-editor</a> </em></li>	
	</ul>
	<strong>FIXED:</strong>
	<ul>
		<li>Missing <em>fpcres</em></li>
	</ul>
</p>

v0.3.4 - R1 - May 20, 2020
---
<p>
	<strong>NEWS:</strong>
	<ul>
		<li>Lazarus 2.0.8</li>
		<li>Update Lazarus version on ~/.lamw4linux/environmentoptions.xml</li>
	</ul>
	<strong>FIXED:</strong>
	<ul>
		<li>Fixed --reset and --uninstall commands</li>
	</ul>
</p>

v0.3.4 - March 10, 2020
---
<p>
	<strong>NEWS:</strong>
	<ul>
		<li>Add/fixs Path to FPCSourceDirectory  ~/.lamw4linux/environmentoptions.xml</li>
		<li>Optmization code on core/common-shell.sh</li>
	</ul>
	<strong>FIXED:</strong>
	<ul>
		<li>Fix --update-lamw: cannot executable lamw4linux</li>
		<li>Fix error: detect fpc-laz</li>
		<li>Error: Exit without Install APT Dependencies</li>
		<li>Prevent error: install unrar packager</li>
	</ul>
</p>


v0.3.3 - R2 - February 25, 2020
---
<p>
	<strong>FIXED:</strong>
	<ul>
		<li>Error: Build Lazarus with FPC 3.2.0</li>
	</ul>
</p>

v0.3.3 - R1 - December 3, 2019
---
<p>
	<strong>FIXED:</strong>
	<ul>
		<li>Error: Install APT Dependencies on Debian 10 Buster</li>
	</ul>
</p>

v0.3.3 - November 26, 2019
---
<p>
	<strong>NEWS:</strong>
	<ul>
		<li>Android NDK r20b</li>
		<li>Apache Ant 1.10.7</li>
		<li>Gradle 4.10.3</li>
		<li>Lazarus 2.0.6</li>
		<li>Install new LAMW package: <em>FCL Bridges</em>!</li>
		<li>Introducing a new installer : <em>lamw_manager_setup.sh</em></li>
		<li>Add (transparent) support for non-sudo admin users</li>
		<li>Now LAMW Manager prevents <strong>APT/dpkg</strong> lock error</li>
		<li>Detect and uses fpc-laz to provide FPC compiler</li>
		<li>Adds JDK 11 Support for systems without JDK8</li>
		<li>Remove unnecessary files and rearrange directory structure</li>
		<li>Fusion the lamw_manager and lamw-manager files.</li>
		<li><strong>modules</strong> directory has renamed to <strong>core</strong></li>
	</ul>
	<strong>FIXED:</strong>
	<ul>
		<li>Error run command : <em>fpcmkcfg</em> with <em>fpc-laz</em></li>
		<li>Fix incompatibility with <em>fpc-laz</em> and <em>lazarus-project</em></li>   
	</ul>	
</p>

v0.3.2 - R1 - September 8, 2019
---
<p>
	<strong>FIXED:</strong>
	<ul>
		<li>Apache Ant URL</li>
	</ul>	
</p>

v0.3.2 - August 19, 2019
---
<p>
	<strong>NEWS:</strong>
	<ul>
		<li>FPC 3.2.0</li>
		<li>Lazarus 2.0.4</li>
		<li>Android API's platform 28</li>
		<li>Android Build Tools 28.0.3</li>
		<li>Your now open Projects from File Manager</li>
		<li>Start LAMW4Linux from the terminal with the command: <em>startlamw4linux</em></li>
	</ul>
	<strong>FIXED:</strong>
	<ul>
		<li>PPC_CONFIG_PATH fixed</li>
		<li>FPC <em>trunk</em> has replaced to FPC 3.2.0</li>
	</ul>	
</p>

v0.3.1 - August 1, 2019
---
<p>
	<strong>NEWS:</strong>
	<ul>
		<li>FPC 3.3.1(trunk)</li>
		<li>Build Freepascal - 3.3.1 x86_64/Linux</li>
		<li>Build Freepascal Cross-compile ARMv7/Android</li>
		<li>Build Freepascal Cross-compile ARM64/Android</li>
		<li>Lazarus 2.0.2</li>
		<li>Clean CLI Messages</li>
		<li>Add <em>--reset-aapis</em> command, to clean and Reinstall Android API's</li>
	</ul>
	<strong>FIXED:</strong>
	<ul>
		<li>Removed  unecessary messages!</li>
	</ul>	
</p>

v0.3.0 - May 10, 2019
---

<p>
	<strong>NEWS:</strong>
	<ul>
		<li>Update FPC to 3.0.0 to 3.0.4 on Ubuntu 16.04/Linux Mint 18</li>
		<li>Add Auto Repair to fixs FPC</li>
	</ul>
	<strong>FIXED:</strong>
	<ul>
		<li>Fix Uninstaller</li>
	    <li>Fix missing ppcrossarm</li>
	</ul>
</p>
