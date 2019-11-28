# Other distro Requerements #

<p>
	<br>To use LAMW Manager the user must meet the following requirements:</br>
	<ol type="I">
		<li>Only linux distributions ( and versions ) listed in <a href="https://github.com/DanielOliveiraSouza/LAMW4Linux-installer/blob/master/README.md"><strong>README</strong></a> are officially supported.</li>
		<li>Compatibility with other linux distributions:</li>
		<ol type="a">
			<li>Ubuntu / Debian Based Linux Distribution</li>
			<li>OpenJDK8 Available in Official Repository (from openjdk-8-jdk package) or OpenJDK11¹ (from openjdk-11-jdk package)</li>
			<li>FreePascal Stable Available in Official Repository (from fpc package)² ³</li>
			<li>Using OpenJDK is recommended instead of Oracle JDK</li>
			<li>If the system does not comply with items i,ii and iii:
			It's the <strong>sole responsibility</strong> of the <strong>user</strong> to <strong>adapt</strong> the system to LAMW Manager.</li>
		</ol>
	</ol>
	<Strong>Notes:</Strong>
	<ol type="1">
		<li>JDK11 does not support Apache Ant Scripts!</li>
		<li>Freepascal distributed by third parties is not supported!</li>
		<li>Freepascal Trunk is not supported!</li>
	</ol>
</p>


 
How to Install OpenJDK8 on GNU/Debian 10
---
<p>
	Run this commands to enable OpenJDK8:
	<ol>
		<li><pre>	sudo echo "deb http://security.debian.org/ stretch/updates main contrib non-free" | sudo tee /etc/apt/sources.list.d/jdk.list</li></pre>
		<li><pre>	sudo apt-get update;sudo apt-get openjdk-8-jdk -y</pre></li>
		<li><pre>	sudo rm /etc/apt/sources.list.d/jdk.list</pre></li>
	</ol>
</p>
