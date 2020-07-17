# GNU/Debian Requerements 

OpenJDK
---
For security reasons, LAMW Manager uses the Java development environment provided only by the official OpenJDK packages on your system.
[GNU / Debian 10 *Buster*](https://www.debian.org/News/2019/20190706) provides only OpenJDK 11.

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

The result is similar a this (sample of file /etc/apt/sources.list of Debian 10 /Buster):
```sourceslist
	deb http://ftp.br.debian.org/debian/ buster main contrib non-free
	deb-src http://ftp.br.debian.org/debian/ buster main contrib non-free
	deb http://security.debian.org/ buster/updates main contrib non-free
	deb-src http://security.debian.org/ buster/updates main contrib non-free
	#buster-updates, previously known as 'volatile'
	deb http://ftp.br.debian.org/debian/ buster-updates main contrib non-free
	deb-src http://ftp.us.debian.org/debian/ buster-updates main contrib non-free
```
