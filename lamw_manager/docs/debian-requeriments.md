# GNU/Debian Requeriments 


Enable  property softwares in /etc/apt/sources.list
---
By default Debian does not enable the sources for property softwares.
For enable you must add **contrib non-free** after codiname sources 
For example : file /etc/apt/sources.list of Debian 10 (**codiname buster**)
<p>
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
	<strong>Rembember</strong>: First enable property sources!
	Run this commands to enable OpenJDK8:
	<ol>
		<li><pre>	sudo echo "deb http://security.debian.org/ stretch/updates main contrib non-free" | sudo tee /etc/apt/sources.list.d/jdk.list</li></pre>
		<li><pre>	sudo apt-get update;sudo apt-get openjdk-8-jdk -y</pre></li>
		<li><pre>	sudo rm /etc/apt/sources.list.d/jdk.list</pre></li>
	</ol>
</p>