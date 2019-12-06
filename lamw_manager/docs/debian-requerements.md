# GNU/Debian Requerements 


Enable  proprietary softwares in /etc/apt/sources.list
---
<p>
	By default Debian <a href="https://wiki.debian.org/SourcesList">does not enable the sources for proprietary softwares</a>.
	<br>For to  enable you must add <strong>contrib non-free</strong> after official debian sources.</br>
	<br>Read more about Debian Free Software Guidelines (DFSG) in <a href="https://wiki.debian.org/DFSGLicenses">https://wiki.debian.org/DFSGLicenses</a></br>
</p>

<p>
	Follow this steps:
	<ol>
		<li>Copy <strong>contrib non-free</strong> in clipboard</li>
		<li>Open /etc/apt/sources.list with root ( pkexec env DISPLAY=$DISPLAY XAUTHORITY=$XAUTHORITY gedit /etc/apt/sources.list</li>
		<li>Search lines of official debian sources e paste :<strong>contrib non-free</strong> after <strong>main</strong></li>
		<li>Save the file.</li>
	</ol>
</p>

<p>
	The result is similar a this (sample of file /etc/apt/sources.list of Debian 10 /Buster):
	<pre>
	deb http://ftp.br.debian.org/debian/ buster main <strong>contrib non-free</strong>
	deb-src http://ftp.br.debian.org/debian/ buster main <strong>contrib non-free</strong> 
	deb http://security.debian.org/ buster/updates main <strong>contrib non-free</strong> 
	deb-src http://security.debian.org/ buster/updates main <strong>contrib non-free</strong> 
	#buster-updates, previously known as 'volatile'
	deb http://ftp.br.debian.org/debian/ buster-updates main <strong>contrib non-free</strong> 
	deb-src http://ftp.us.debian.org/debian/ buster-updates main <strong>contrib non-free</strong> 
	</pre>
</p>


How to Install OpenJDK8 on GNU/Debian 10
---
<p>
	<strong>Rembember</strong>: First enable proprietary sources!
	Run this commands to enable OpenJDK8:
	<ol>
		<li><pre>sudo echo "deb http://security.debian.org/ stretch/updates main contrib non-free" | sudo tee /etc/apt/sources.list.d/jdk.list</li></pre>
		<li><pre>sudo apt-get update;sudo apt-get openjdk-8-jdk -y</pre></li>
		<li><pre>sudo rm /etc/apt/sources.list.d/jdk.list</pre></li>
	</ol>
</p>