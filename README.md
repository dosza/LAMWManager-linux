# **LAMW Manager v0.3.0**

LAMW Manager is  **"APT"** to LAMW framework
LAMW Manager is powerfull   command line tool like *APT* to install, configure and Update LAMW Framework IDE
to distro linux like *GNU/debian*

**Linux Distro Supported:**

<ul>
	<li>Debian/GNU Linux 9</li>
	<li>Ubuntu 16.04 LTS</li>
	<li>Ubuntu 18.04 LTS</li>
	<li>Linux Mint 18 <strong>Cinnamon</strong></li>
	<li>Linux Mint 19 <strong>Cinnamon</strong></li>
</ul>		

<p>
	<strong>Note:</strong>For use in other debian-based distributions (but are not officially supported by LAMW Manager)
Make sure there is the <strong>openjdk-8-jdk</strong> package!
<br>For licensing issues, we recommend only using openjdk instead of Oracle Java!</br>
<br>The stable Freepascal Compiler package (3.0.0 or 3.0.4) <strong>MUST be available in official repositories</strong> of your linux distribution (APT)!
<br><strong>Warning: We do not recommend fpc packages compiled by third parties!</strong></br>
<br>FPC Trunk is not supported!</br>

</p>


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


<p>
<pre>					<Strong>Syntax:</Strong>
./lamw_manager¹
./lamw_manager² 	<strong>[actions]</strong>    [options]
</pre>
</p>


**Usage:**

<p>
./lamw_manager
	<pre>
	<strong>[action]</strong>                            <em>Description</em>
	<strong>install</strong>                             Install lamw with <em>Android SDK Tools r26.1.1</em>
	<strong>install_default</strong>                     The first time, install LAMW with <strong>default option</strong>, in other cases only install updates.                                                   
	<strong>uninstall</strong>                           Uninstall LAMW completely and erase all settings.
	<strong>reinstall</strong>                           Clean and reinstall <em>LAMW IDE with Android SDK Tools r26.1.1</em>
	<strong>install-oldsdk</strong>                      Install lamw with <em>Android SDK Tools r25.2.5³ GUI</em>
	<strong>install_old_sdk</strong>                     Auto Install lamw with <strong><em>Android SDK Tools r25.2.5 CLI</em></strong>
	<strong>reinstall-oldsdk</strong>                    Clean and reinstall lamw with <em>Android SDK Tools r25.2.5</em>
	<strong>update-lamw</strong>                         Update LAMW sources and rebuild Lazarus IDE
	</pre>
	<strong>Note:</strong>The <em>default option</em> is <strong><em>Android SDK Tools r25.2.5</em></strong>
</p>


<strong>Example of installation:</strong>
<pre> 
To install LAMW completely the <strong>first time</strong> with <strong><em>default option</em></strong>:
	<strong>./lamw_manager</strong>
<br>To install LAMW completely the <strong>first time</strong> with <strong><em>Android SDK Tools r26.1.1:</em></strong></br>
	<strong>./lamw_manager</strong>       <em>install</em>
<br>To fully update LAMW <strong>after</strong> the <em>first installation</em>:</br>
	<strong>./lamw_manager</strong>
<br>To just upgrade <strong>LAMW framework</strong> <em>(with the latest version available in git)</em></br>
	<strong>./lamw_manager</strong>        <em>update_lamw</em>

</pre>
</p>




**proxy options:**
<p>
	<pre>
	<em>actions</em>    <strong>--use-proxy</strong> 		<em>[proxy options]</em>
	<em>install</em>    <strong>--use-proxy --server</strong>	<em>[HOST]</em> <strong>--port</strong> 	<em>[NUMBER]</em>
</pre>
</p>

<pre> <strong>sample:</strong>	lamw_manager install	<strong>--use-proxy	--server</strong> <em>10.0.16.1</em>	<strong>--port</strong>	<em>3128</em> </pre>

**Forced installation:**

<p>
	if the default installation fails!
	Possibly caused by a lazarus package (.deb) in <em>bad condition</em>, <strong>action</strong> recommends uninstalling any lazarus 
	(.deb) for this use: <strong>--force</strong> as the last parameter.
</p>

<p>
	<pre>
					<strong>Syntax:</strong>
	./lamw_manager 			<em>[actions]</em>       <strong>--force</strong>
<strong>Examples:</strong>					 
	./lamw_manager                 <em>install</em>         <strong>--force</strong>
	./lamw_manager                 <em>install</em>        <em>--use-proxy --server 10.0.16.1 --port 3128</em> <strong>--force</strong>
</pre>
</p>

¹<strong>New!
Implied action</strong>:
<em>When using the <strong>./lamw_manager</strong> command <strong>without parameters the first time</strong>, LAMW Manager installs the default LAMW environment (Android SDK Tools r25.2.5), in other cases LAMW Manager <strong>only</strong> installs updates.</em>


<p>
	<em>²An installable LAMW Manager package will be available in the future and the command lamw_manager can be called independent of the current directory $PWD</em>
	<strong>³You need in Android SDK Tools Installer:</strong>
	<ul>
	<li>check "Android SDK Tools"</li>
	<li>check "Android SDK Platform-Tools"</li>			
	<li>check "Android SDK Build-Tools 26.0.2"</li>  	
	<li>go to "Android 8.0.0 (API 26)" and check only "SDK Platform"</li>
	<li>go to "Extras" and check:</li> 
	<li>		"Android Support Repository"</li>				
	<li>		"Android Support Library"</li>				
	<li>		"Google Repository"</li>
	<li>		"Google Play Services" </li>
	</ul>																
</p>

