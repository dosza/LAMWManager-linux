# Classical Install  - From Sources code.
This page contains a tutorial to Install LAMW Manager

Basic Tutorial
===
<p>
	Getting from sources:
	<ol>
		<li>Clone this repository with command:
		<pre><em>git clone</em> <a href="https://github.com/DanielOliveiraSouza/LAMW4Linux-installer.git">https://github.com/DanielOliveiraSouza/LAMW4Linux-installer.git</a></pre> 
		Or Download 
		<pre><a href="https://github.com/DanielOliveiraSouza/LAMW4Linux-installer/archive/master.zip">https://github.com/DanielOliveiraSouza/LAMW4Linux-installer/archive/master.zip</a> and unzip.</pre></li>
		<li>Go to <em>lamw_manager</em> folder</li>
		<li>Open a terminal and run 
		<pre>	<em>./lamw_manager</em></pre></li>
	</ol>
</p>

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
