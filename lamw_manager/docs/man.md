**&nbsp;&nbsp;&nbsp;lamw_manager(1)&nbsp; 2024 Jan 23 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;LAMW Manager man page&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; lamw_manager(1)**

#### NAME ####
<p>
       <pre>
              lamw_manager - manager to LAMW framework
       </pre>
</p>

#### SINOPSIS ####
<p>
       <pre>
              <strong>env LOCAL_ROOT_LAMW=[dir]</strong> ./lamw_manager  [<strong>ACTION</strong>] [<strong>OPTIONS</strong>]
              <strong>env LOCAL_ROOT_LAMW=[dir]</strong> ./lamw_manager  [<strong>ACTION</strong>] [<strong>OPTIONS</strong>]
              ./lamw_manager
              ./lamw_manager       [<strong>ACTION</strong>] [<strong>OPTIONS</strong>]
              ./lamw_manager       [<strong>OPTIONS</strong>]
              ./lamw_manager       [<strong>uninstall</strong>] [<strong>--reset</strong>] [<strong>--reset-aapis</strong>] 
                                   [<strong>--sdkmanager</strong>] [<strong>--avdmanager</strong>] 
                                   [<strong>--update-lamw</strong>] 
                                   [<strong>--minimal</strong>] [<strong>--reinstall</strong>] [<strong>--help</strong>]
       </pre>
</p>

#### DESCRIPTION ####

<p>
       <pre>
              LAMW Manager is a command line tool,like APT, to automate the installation,
              configuration  and  upgrade the framework LAMW - Lazarus Android Module Wizard.
       </pre>
</p>

#### INSTALLING LAMW ON CUSTOM DIRECTORY #### 
<p>
       <pre>
              To install LAMW environment on custom directory you need use 
              <strong>env LOCAL_ROOT_LAMW=path_your_directory</strong> ./lamw_manager  [<strong>ACTION</strong>] [<strong>OPTIONS</strong>]
                     <strong>sample:</strong>
              <strong>env LOCAL_ROOT_LAMW=/opt/LAMW</strong> ./lamw_manager
       </pre>
</p>


#### ACTIONS ####

<p>
       <pre>
              <strong>uninstall</strong>         Clean all LAMW</pre>
</p>

#### OPTIONS ####
<p>
       <pre>
              <strong>--minimal</strong>                Install LAMW and dependencies with minimal crosscompile to Android
              <strong>--reinstall</strong>              Reinstall LAMW and dependencies without reset
              <strong>--reset</strong>                  Clean and Install LAMW
              <strong>--reset-aapis</strong>            Reset Android API's to default
              <strong>--help</strong>                   Show this help
              <strong>--sdkmanager</strong>   <strong>[ARGS]</strong>    Run Android SDK Manager
              <strong>--avdmanager</strong>   <strong>[ARGS]</strong>    Run Android Device Manager
              <strong>--update-lamw</strong>            Just upgrade LAMW Framework  (with 
                                 the  latest  version avaliable in git )
       </pre>
</p>

#### PROXY OPTIONS ####
<p>
       <pre>
              ./lamw_manager  [ACTIONS]||[OPTIONS]  <strong>--use-proxy</strong>  <strong>--server</strong> [HOST] <strong>--port</strong>
              [NUMBER]
              <strong>sample:</strong>
              ./lamw_manager --update-lamw <strong>--use-proxy</strong>  <strong>--server</strong>  10.0.16.1 --port 3128
        </pre>
 </p>


#### Android SDK Manager ####
<p>
       <pre>
              ./lamw_manager  <strong>--sdkmanager</strong>    <strong>[ARGS]</strong>
              <strong>sample:</strong>
              ./lamw_manager --sdkmanager  <strong>--list_installed</strong>
        </pre>
 </p>


#### NOBLINK=1 ####
<p>
       <pre>
              Use the <strong>NOBLINK=1</strong> if you are photosensitive
                     <strong>Sample:</strong>
              ./lamw_manager --reset <strong>NOBLINK=1</strong>
              ./lamw_manager <strong>NOBLINK=1</strong> --reset
       </pre>
</p>

#### BUGS ####

<p>
       <pre>
              1 Fail! Folder/platforms is empty! Use command ./lamw_manager <strong>--reset-aapis</strong> to fix then.
              2 If the LAMW4Linux launcher does not appear in the  start  menu, simply restart 
       the user session.
              3 Xfce terminal closes quickly (lazarus ant/gradle build)
              Close all xfce terminal windows and try again!
       </pre>
</p>

#### AUTHOR ####
<p>
       <pre>
              Daniel Oliveira Souza 
       </pre>
</p>
