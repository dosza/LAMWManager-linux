# Classical Install  - From Sources code.
This page contains a tutorial to Install LAMW Manager

Basic Tutorial
===
<ol>
	<li><a href="https://github.com/DanielOliveiraSouza/LAMW4Linux-installer/archive/master.zip"> Download</a> and unzip or clone this repository  with command: git clone <a href="https://github.com/DanielOliveiraSouza/LAMW4Linux-installer.git">https://github.com/DanielOliveiraSouza/LAMW4Linux-installer.git</a></li>
	<li>Go to lamw_manager folder</li>
	<li>Open a terminal and run ./lamw_manager</li>
</ol>

Example of installation from sources:
===
<pre> 
To install LAMW and dependencies:
	<strong>./lamw_manager</strong>
	<br>To install LAMW and dependencies and Run <strong>Android  GUI SDK Manager</strong><sup>1</sup></br>
	<strong>./lamw_manager</strong>        <em>--sdkmanager</em>
<br>To just upgrade <strong>LAMW framework</strong> <em>(with the latest version available in git)</em></br>
	<strong>./lamw_manager</strong>        <em>--update_lamw</em>
<br>Install with proxy:</br>
	<strong>./lamw_manager        --use-proxy	--server</strong> <em>10.0.16.1</em>	<strong>--port</strong>	<em>3128</em> 
<br>To clean and reinstall LAMW</br>
	<strong>./lamw_manager</strong>        <em>--reset</em>
<sup>1</sup>  If it is already installed, just run the Android SDK Tools
</pre>
