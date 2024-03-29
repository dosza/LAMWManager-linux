# LAMW Manager Setup

<p>
	The <em>lamw_manager_setup.sh</em> is a  self-extracting and executable ( to lamw_manager ) file create <a href="https://makeself.io">Makeself</a>.  
<em>lamw_manager_setup.sh</em> accepts sames args of <em>lamw_manager</em> , but need <strong>--</strong> additional.
</p>

Example of installation from *lamw_manager_setup.sh*
===

<p>
	<strong>New: install LAMW in custom directory<sup>1</sup></strong>
	<pre><strong>env LOCAL_ROOT_LAMW=/opt/LAMW</strong>	bash lamw_manager_setup.sh</pre>
	<strong>To install LAMW and dependencies:</strong>
	<pre>	bash lamw_manager_setup.sh</pre>
	<strong>Install LAMW and dependencies with minimal crosscompile to Android</strong>
	<pre>	bash lamw_manager_setup.sh        <strong>--</strong>	<em>--minimal</em></pre>
	<strong>Reinstall LAMW and dependencies without reset</strong>
	<pre>	bash lamw_manager_setup.sh        <strong>--</strong>	<em>--reinstall</em></pre>
	<strong>To install LAMW and dependencies and Run Android SDK Manager</strong><sup>1</sup>
	<pre>	bash lamw_manager_setup.sh        <strong>--</strong>	<em>--sdkmanager</em>	<em>[ARGS]</em></pre>
	<strong>To clean and reinstall LAMW</strong>
	<pre>	bash lamw_manager_setup.sh        <strong>--</strong>      <em> --reset</em></pre>
	<strong>To just upgrade LAMW framework</strong> <em>(with the latest version available in git)</em>
	<pre>	bash lamw_manager_setup.sh        <strong>--</strong>        <em>--update_lamw</em></pre>
	<strong>Install with proxy:</strong>
	<pre>	bash lamw_manager_setup.sh        <strong>--</strong>       <strong>--use-proxy	--server</strong> <em>10.0.16.1</em>	<strong>--port</strong>	<em>3128</em></pre>
	<strong>To just upgrade LAMW framework with proxy</strong> <em>(with the latest version available in git)</em>
	<pre>	bash lamw_manager_setup.sh        <strong>--</strong>	<em>--update_lamw</em>       --use-proxy	--server <em>10.0.16.1</em>	<strong>--port</strong>	<em>3128</em></pre>
	<sup>1</sup>  This is necessary in first install and <strong>only works on new fresh installation!</strong><br/>
	<sup>2</sup>  If it is already installed, just run the Android SDK Tools
</p>
