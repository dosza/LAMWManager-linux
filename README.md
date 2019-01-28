# **LAMW Manager v0.3.0**

LAMW Install Manager is  **"APT"** to LAMW framework
LAMW Install Manager is powerfull   command line tool like *APT* to install, configure and Update LAMW Framework IDE
to distro linux like *GNU/debian*

**Linux Distro Supported:**
<p>
	Note: For use in other debian-based distributions (but are not officially supported by LAMW Manager)
Make sure there is the <strong>openjdk-8-jdk</strong> package!
<br>For licensing issues, we recommend only using openjdk instead of Oracle Java!</br>
<br>The stable Freepascal Compiler package (3.0.0 or 3.0.4) <strong>MUST be available in official repositories</strong> of your linux distribution (APT)!
<br><strong>Warning: We do not recommend fpc packages compiled by third parties!</strong></br>
<br>FPC Trunk is not supported!</br>

</p>

<ul>
	<li>Debian/GNU Linux 9</li>
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
<pre>lamw_manager 	<strong>[actions]</strong> </pre>


**usage:**
<p>
	<pre>
	<strong>install</strong>                                 Install lamw with <em>Android SDK Tools r26.1.1</em>
	<strong>reinstall</strong>                               Clean and reinstall <em>LAMW IDE with Android SDK Tools r26.1.1</em>
	<strong>install-oldsdk</strong>                          Install lamw with <em>Android SDK Tools r25.2.5 GUI¹</em>
	<strong>install_old_sdk</strong>                         Auto Install lamw with <strong><em>Android SDK Tools r25.2.5 CLI¹</em></strong>
	<strong>reinstall-oldsdk</strong>                        Clean and reinstall lamw with <em>Android SDK Tools r25.2.5</em>
	<strong>update-lamw</strong>                             Update LAMW sources and rebuild Lazarus IDE
</pre>
</p>

**¹ You need in Android SDK Tools Installer:**
<p>
<ul>
<li>check "Android SDK Tools"</li>
<li>check "Android SDK Platform-Tools"</li>			
<li>check "Android SDK Build-Tools 26.0.2"</li>  	
<li>go to "Android 8.0.0 (API 26)" and check only "SDK Platform"</li>
<li>go to "Extras" and check:</li> 
<li>		"Android Support Repository"</li>				
<li>		"Android Support Library"</li>				
<li>		"Google USB Drive"	//windows only...</li>
<li>		Google Repository"</li>
<li>		"Google Play Services" </li>
</ul>
</p>

**proxy options:**
<p>
	<pre>
	<em>actions</em>	<strong>--use-proxy</strong> 	[*proxy options*]
	*install* 	<strong>--use-proxy --server</strong>	[HOST] <strong>--port</strong> 	[NUMBER]
</pre>
</p>

<pre> <strong>sample:</strong>	lamw_manager install	<strong>--use-proxy	--server</strong> 10.0.16.1	<strong>--port</strong>	3128 </pre>

**Forced installation:**

<p>
	if the default installation fails!
	Possibly caused by a lazarus package (.deb) in <em>bad condition</em>, <strong>action</strong> recommends uninstalling any lazarus 
	(.deb) for this use: <strong>--force</strong> as the last parameter.
</p>

<p>
	[actions] [other options] ... <strong>--force</strong><br>
	<strong>sample:</strong> lamw_manger <em>install</em> <strong>--force</strong></br><br>
	<strong>sample:</strong> lamw_manager <em>install</em> --use-proxy --server 10.0.16.1 --port 3128 <strong>--force</strong></br><br>
</br>
</p>
