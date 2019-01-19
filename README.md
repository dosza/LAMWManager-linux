**LAMW Install Manager v0.2.2**

LAMW Install Manager is  *"APT"* to LAMW framework
LAMW Install Manager is powerfull   command line tool like *APT* to install, configure and Update LAMW Framework IDE
to distro linux like *GNU/debian*

**Linux Distro Supported:**
	GNU/Debian 9 
	Ubuntu 16.04 LTS
	Ubuntu 18.04 LTS
	Linux Mint 18 *Cinnamon*
	Linux Mint 19 *Cinnamon*

**This tool make:**
	Get Apache Ant
	Get Gradle
	Get Freepascal Compiler
	Get Lazarus IDE Sources
	Get Android NDK
	Get Android SDK
	Get OpenJDK
	Get LAMW framework
	Build Freepascal Cross-compile to arm-android*
	Build Lazarus IDE
	Install LAMW framework
	Create launcher to menu
	Register *MIME*

**commands:**
	**lamw_manager** (this tool *invokes* root as sudo)

*Note: you need run this tool without root privileges!*
lamw_manager **[actions]**
**usage:**
	*install* 			install lamw with *Android SDK Tools r26.1.1*
	*reinstall*			clean and reinstall *LAMW IDE with Android SDK Tools r26.1.1*
	*install-oldsdk*		install lamw with Android SDK Tools r25.2.5 
	*reinstall-oldsdk*	clean and reinstall lamw with *Android SDK Tools r25.2.5*
	*update-lamw*			update LAMW sources and rebuild Lazarus IDE

**proxy options:**
	*actions* **--use-proxy** [*proxy options*]
	*install* **--use_proxy** **--server** [HOST] **--port** [NUMBER]
**sample:** lamw_manager install **--use-proxy** --server 10.0.16.1 --port 3128

**Forced installation:**
if the default installation fails!
Possibly caused by a lazarus package (.deb) in bad condition, action recommends uninstalling any lazarus (.deb) for this use: **--force** as the last parameter.


[actions] [other options] ... **--force**
**sample:** lamw_manger *install* **--force**
**sample:** lamw_manager *install* --use-proxy --server 10.0.16.1 --port 3128 **--force**