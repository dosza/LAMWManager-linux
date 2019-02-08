

**commands:**
	lamw_manager** (this tool *invokes* root as sudo) 

*Note: you need run this tool without root privileges!*


<p>
<pre>					<Strong>Syntax:</Strong>
./lamw_manager¹
./lamw_manager² 	<strong>[actions]</strong>         <strong>[options]</strong>  
</pre>
</p>


**Usage:**

<p>
./lamw_manager                                         
	<pre>
	<strong>[action]</strong>                            <em>Description</em>
	<strong>uninstall</strong>                           Uninstall LAMW completely and erase all settings.
	<strong>--sdkmanager</strong>                        Run Android SDK Manager 
	<strong>--update-lamw</strong>                       Update LAMW sources and rebuild Lazarus IDE
	</pre>
	<strong>Note:</strong>The <em>default option</em> is <strong><em>Android SDK Tools r25.2.5</em></strong>
</p>

**proxy options:**
<p>
	<pre>
	<em>actions</em>    <strong>--use-proxy</strong> 		<em>[proxy options]</em>
</pre>
</p>

<pre> <strong>sample:</strong>	lamw_manager install	<strong>--use-proxy	--server</strong> <em>10.0.16.1</em>	<strong>--port</strong>	<em>3128</em> </pre>

**Forced installation:**

<p>
	if the default installation fails!
	Possibly caused by a lazarus package (.deb) in <em>bad condition</em>, <strong>action</strong> recommends uninstalling any lazarus 
	(.deb) for this use: <strong>--force</strong> as the last parameter.
</p>

<p>
	<pre>
					<strong>Syntax:</strong>
	./lamw_manager 			<em>[actions]</em>       <strong>--force</strong>
<strong>Examples:</strong>					 
	./lamw_manager                  <em>--update-lamw      <strong>--force</strong>
	./lamw_manager                 <em>--sdkmanager</em>        <em>--use-proxy --server 10.0.16.1 --port 3128</em> <strong>--force</strong>
</pre>
</p>

¹<strong>New!
Implied action</strong>:
<em>When using the <strong>./lamw_manager</strong> command <strong>without parameters the first time</strong>, LAMW Manager installs the default LAMW environment (Android SDK Tools r25.2.5), in other cases LAMW Manager <strong>only</strong> installs updates.</em>