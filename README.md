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




<strong>Example of installation:</strong>
<pre> 
To install LAMW and dependencies:
	<strong>./lamw_manager</strong>
	<br>To install LAMW and dependencies and Run <strong>Android  GUI SDK Manager¹</br>
	<strong>./lamw_manager</strong>        <em>--sdkmanager</em>
<br>To just upgrade <strong>LAMW framework</strong> <em>(with the latest version available in git)</em></br>
	<strong>./lamw_manager</strong>        <em>--update_lamw</em>
<br>Install with proxy:</br>
	<strong>./lamw_manager        --use-proxy	--server</strong> <em>10.0.16.1</em>	<strong>--port</strong>	<em>3128</em> </pre>
</pre>
</p>




<br><br>
¹  If it is already installed, just run the Android SDK Tools</a>: </br></br>