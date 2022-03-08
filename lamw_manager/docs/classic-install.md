# Install  From Sources code.
This page contains a tutorial to Install LAMW Manager

Basic Tutorial
===
<p>
	Getting from sources:
	<ol>
		<li>Clone this repository with command:
		<pre>	<em>git clone</em> <a href="https://github.com/dosza/LAMWManager-linux.git">https://github.com/dosza/LAMWManager-linux.git</a></pre> 
		Or Download 
		<pre>	<a href="https://github.com/dosza/LAMWManager-linux/archive/master.zip">https://github.com/dosza/LAMWManager-linux/archive/master.zip</a> and unzip.</pre></li>
		<li>Go to <em>lamw_manager</em> folder</li>
		<li>Open a terminal and run 
		<pre>	<em>./lamw_manager</em></pre></li>
	</ol>
</p>

Example of installation from sources:
===
<p>
	<strong>New: install LAMW in custom directory<sup>1</sup></strong>
	<pre><strong>env LOCAL_ROOT_LAMW=/opt/LAMW</strong> ./lamw_manager</pre>
	<strong>To install LAMW and dependencies:</strong><sup>2</sup>
	<pre>	./lamw_manager</pre>
	strong>Install LAMW and dependencies with minimal crosscompile to Android</strong>
	<pre>	./lamw_manager              <em>--minimal</em></pre>
	<strong>Reinstall (forced) LAMW and dependencies without reset</strong>
	<pre>	./lamw_manager              <em>--reinstall</em></pre>
	<strong>To install LAMW and dependencies and Run Android SDK Manager</strong><sup>3</sup>
	<pre>	./lamw_manager              <em>--sdkmanager</em>	<em>[ARGS]</em></pre>
	<strong>To clean and reinstall LAMW</strong>
	<pre>	./lamw_manager              <em> --reset</em></pre>
	<strong>To just upgrade LAMW framework</strong> <em>(with the latest version available in git)</em>
	<pre>	./lamw_manager                <em>--update_lamw</em></pre>
	<strong>Install with proxy:</strong>
	<pre>	./lamw_manager               <em>--use-proxy</em>	--server <em>10.0.16.1</em>	<strong>--port</strong>	<em>3128</em></pre>
	<strong>To just upgrade LAMW framework with proxy</strong> <em>(with the latest version available in git)</em>
	<pre>	./lamw_manager                <em>--update-lamw</em>		<strong>--use-proxy	--server</strong> <em>10.0.16.1</em>	<strong>--port</strong>	<em>3128</em></pre>
	<ol>
		<li>This is necessary in first install and <strong>only works on new fresh installation!</strong>
		<li>If it is already installed, just upgrade LAMW framework</li>
		<li>If it is already installed, just run the Android SDK Tools</li>
	</ol>
</p>
