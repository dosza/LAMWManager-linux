# LAMW Manager Setup

<p>
	The <em>lamw_manager_setup.sh</em> is a  self-extracting and executable ( to lamw_manager ) file create with command <a href="https://makeself.io">makeself</a>.  
<em>lamw_manager_setup.sh</em> accepts sames args of <em>lamw_manager</em> , but need <strong>--</strong> additional.
</p>

Example of installation from *lamw_manager_setup.sh*
===
<pre> 
To install LAMW and dependencies:
	<strong>bash lamw_manager_setup.sh</strong>
	<br>To install LAMW and dependencies and Run <strong>Android  GUI SDK Manager</strong><sup>1</sup></br>
	<strong>bash lamw_manager</strong>        --	<em>--sdkmanager</em>
<br>To just upgrade <strong>LAMW framework</strong> <em>(with the latest version available in git)</em></br>
	<strong>bash lamw_manager_setup.sh</strong>        --        <em>--update_lamw</em>
<br>Install with proxy:</br>
	<strong>bash lamw_manager_setup.sh        --       --use-proxy	--server</strong> <em>10.0.16.1</em>	<strong>--port</strong>	<em>3128</em> 
<br>To clean and reinstall LAMW</br>
	<strong>bash lamw_manager_setup.sh</strong>        --      <em> --reset</em>
<sup>1</sup>  If it is already installed, just run the Android SDK Tools
</pre>
