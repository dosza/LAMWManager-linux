**LAMW Install Manager v0.2.1**

LAMW Install Manager is  **"APT"** to LAMW framework
LAMW Install Manager is powerfull   command line tool like *APT* to install, configure and Update LAMW Framework IDE
to distro linux like *GNU/debian*

**Linux Distro Supported:**
<ul>
	<li>GNU/Debian 9</li>
	<li>Ubuntu 16.04 LTS</li>
	<li>Ubuntu 18.04 LTS</li>
	<li>Linux Mint 18 <strong>Cinnamon</strong></li>
	<li>Linux Mint 19 <strong>Cinnamon</strong></li>
</ul>		

**This tool make:**
<ul>
	<li>Get Apache Ant</li>
	<li>Get Gradle</li>
	<li>Get Freepascal Compiler</li>
	<li>Get Lazarus IDE Sources</li>
	<li>Get Android NDK</li>
	<li>Get Android SDK</li>
	<li>Get OpenJDK</li>
	<li>Get LAMW framework</li>
	<li>Build Freepascal Cross-compile to arm-android*</li>
	<li>Build Lazarus IDE</li>
	<li>Install LAMW framework</li>
	<li>Create launcher to menu</li>
	<li>Register <strong>MIME</strong> </li>
</ul>

**commands:**
	**lamw_manager** (this tool *invokes* root as sudo) 

*Note: you need run this tool without root privileges!*
lamw_manager **[actions]**


**usage:**
<p>
	*install* 				install lamw with *Android SDK Tools r26.1.1*
	*reinstall*				clean and reinstall *LAMW IDE with Android SDK Tools r26.1.1*
	*install-oldsdk*		install lamw with Android SDK Tools r25.2.5 
	*reinstall-oldsdk*		clean and reinstall lamw with *Android SDK Tools r25.2.5*
	*update-lamw*			update LAMW sources and rebuild Lazarus IDE
</p>

**proxy options:**
<p>
	*actions* **--use-proxy** [*proxy options*]
	*install* **--use_proxy** **--server** [HOST] **--port** [NUMBER]
</p>

**sample:** lamw_manager install **--use-proxy** --server 10.0.16.1 --port 3128

**Forced installation:**

<p>
	if the default installation fails!
	Possibly caused by a lazarus package (.deb) in *bad condition*, **action** recommends uninstalling any lazarus 
	(.deb) for this use: **--force** as the last parameter.
</p>

<p>
	[actions] [other options] ... **--force**
	**sample:** lamw_manger *install* **--force**
	**sample:** lamw_manager *install* --use-proxy --server 10.0.16.1 --port 3128 **--force**
</p>