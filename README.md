**LAMW Install Manager v0.2.2**<br>
<br>
LAMW Install Manager is  *"APT"* to LAMW framework<br>
LAMW Install Manager is powerfull   command line tool like *APT* to install, configure and Update LAMW Framework IDE<br>
to distro linux like *GNU/debian*<br>
<br>
**Linux Distro Supported:**<br>
<ol>
	<li>GNU/Debian 9</li>
	<li>Ubuntu 16.04 LTS</li>
	<li>Ubuntu 18.04 LTS</li>
	<li>Linux Mint 18 *Cinnamon*</li>
	<li>Linux Mint 19 *Cinnamon*</li>
</ol>		
<br>
**This tool make:**<br>
<ol>
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
	<li>Register *MIME*</li>
</ol>
<br>
**commands:**<br>
	**lamw_manager** (this tool *invokes* root as sudo)<br>
<br>
*Note: you need run this tool without root privileges!*<br>
lamw_manager **[actions]**<br>
**usage:**<p>
	*install* 				install lamw with *Android SDK Tools r26.1.1*<br>
	*reinstall*				clean and reinstall *LAMW IDE with Android SDK Tools r26.1.1*<br>
	*install-oldsdk*		install lamw with Android SDK Tools r25.2.5 <br>
	*reinstall-oldsdk*		clean and reinstall lamw with *Android SDK Tools r25.2.5*<br>
	*update-lamw*			update LAMW sources and rebuild Lazarus IDE<br>
</p>
**proxy options:**<br>
	*actions* **--use-proxy** [*proxy options*]<br>
	*install* **--use_proxy** **--server** [HOST] **--port** [NUMBER]<br>
**sample:** lamw_manager install **--use-proxy** --server 10.0.16.1 --port 3128<br>
<br>
**Forced installation:**<br>
if the default installation fails!<br>
Possibly caused by a lazarus package (.deb) in bad condition, action recommends uninstalling any lazarus (.deb) for this use: **--force** as the last parameter.<br>
<br>
<br>
<p>
	[actions] [other options] ... **--force**<br>
	**sample:** lamw_manger *install* **--force**<br>
	**sample:** lamw_manager *install* --use-proxy --server 10.0.16.1 --port 3128 **--force**
</p>