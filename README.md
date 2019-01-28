# **LAMW Install Manager v0.2.1**

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
	<li>Build Freepascal Cross-compile to <strong>arm-android</strong></li>
	<li>Build Lazarus IDE</li>
	<li>Install LAMW framework</li>
	<li>Create launcher to menu</li>
	<li>Register <strong>MIME</strong> </li>
</ul>

**commands:**
	lamw_manager** (this tool *invokes* root as sudo) 

*Note: you need run this tool without root privileges!*
lamw_manager **[actions]**


**usage:**
<p>
	<em>install</em> 				install lamw with <em>Android SDK Tools r26.1.1</em>
	<em>reinstall</em>				clean and reinstall <em>LAMW IDE with Android SDK Tools r26.1.1</em>
	<em>install-oldsdk</em>			install lamw with <em>Android SDK Tools r25.2.5</em>
	<em>reinstall-oldsdk</em>		clean and reinstall <em>lamw with *Android SDK Tools r25.2.5</em>
	<em>update-lamw</em>			update LAMW sources and rebuild Lazarus IDE
</p>

**proxy options:**
<p>
	<em>actions</em> <strong>--use-proxy</strong> [*proxy options*]
	*install* <strong>--use-proxy --server</strong>  [HOST] <strong>--port</strong> [NUMBER]
</p>

**sample:** lamw_manager install **--use-proxy** **--server** 10.0.16.1 **--port** 3128

**Forced installation:**

<p>
	if the default installation fails!
	Possibly caused by a lazarus package (.deb) in <em>bad condition</em>, <strong>action</strong> recommends uninstalling any lazarus 
	(.deb) for this use: <strong>--force</strong> as the last parameter.
</p>

<p>
	[actions] [other options] ... <strong>--force</strong>
	<strong>sample:</strong> lamw_manger <em>install</em> <strong>--force</strong>
	<strong>sample:</strong> lamw_manager <em>install</em> --use-proxy --server 10.0.16.1 --port 3128 <strong>--force</strong>
</p>
