# **LAMW Manager v0.3.0**

LAMW Manager is a command line tool,like *APT*, to automate the <strong>installation</strong>, <strong>configuration</strong> and <strong>upgrade</strong>  the framework  <a href="https://github.com/jmpessoa/lazandroidmodulewizard"><strong>LAMW - Lazarus Android Module Wizard</strong></a>


**What do you get?** 

<p>
	A <strong><a href="http://www.lazarus-ide.org/">Lazarus  IDE </a></strong>ready to develop applications for Android !!
</p>

<p> 
	Windows user, please,  get here <em><a href="https://github.com/DanielTimelord/Laz4LAMW-win-installer"> LAMW Manager for Windows</a></em>
</p>


**Linux Distro Supported:**

<ul>
	<li>Debian/GNU Linux 9</li>
	<li>Ubuntu 16.04 LTS</li>
	<li>Ubuntu 18.04 LTS</li>
	<li>Linux Mint 18 <strong>Cinnamon</strong></li>
	<li>Linux Mint 19 <strong>Cinnamon</strong></li>
	<li><a href="https://github.com/DanielTimelord/LAMWAutoRunScripts/blob/master/lamw_manager/docs/other-distros-info.md"><strong>Requirements for other linux distributions</strong></a></li>
</ul>		



**LAMW Manager install the following [dependencies] tools:**
<ul>
	<li>Apache Ant</li>
	<li>Gradle</li>
	<li>Freepascal Compiler</li>
	<li>Lazarus IDE Sources</li>
	<li>Android NDK</li>
	<li>Android SDK</li>
	<li>OpenJDK</li>
	<li>Build Freepascal Cross-compile to <strong>arm-android</strong></li>
	<li>Build Lazarus IDE</li>
	<li>LAMW framework</li>
	<li>Create launcher to menu</li>
	<li>Register <strong>MIME</strong> </li>
</ul>


<strong>Example of installation:</strong>
<pre> 
To install LAMW and dependencies:
	<strong>./lamw_manager</strong>
	<br>To install LAMW and dependencies and Run <strong>Android  GUI SDK Manager<sup>1</sup></br>
	<strong>./lamw_manager</strong>        <em>--sdkmanager</em>
<br>To just upgrade <strong>LAMW framework</strong> <em>(with the latest version available in git)</em></br>
	<strong>./lamw_manager</strong>        <em>--update_lamw</em>
<br>Install with proxy:</br>
	<strong>./lamw_manager        --use-proxy	--server</strong> <em>10.0.16.1</em>	<strong>--port</strong>	<em>3128</em> </pre>
</pre>
	<sup>1</sup>  If it is already installed, just run the Android SDK Tools
</p>

<br></br>
**Congratulations!!**
<p>
	You are now a Lazarus for Android developer!
	<br><a href="https://drive.google.com/open?id=1CeDDpuDfRwYrKpN7VHbossH6GfZUfqjm">Building Android application with <strong>LAMW</strong> is <strong>RAD</strong>!</a></br>
</p>

<p>
	For more info read <a href="https://github.com/DanielTimelord/LAMWAutoRunScripts/blob/master/lamw_manager/docs/man.md"><strong>LAMW Manager v0.3.0  Manual</strong></a>
</p>