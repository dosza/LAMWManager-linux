<p>
       <pre>
       <strong>lamw_manager(1)     2019 Aug 18   0.3.2  LAMW Manager man page </strong>
       </pre>
</p>

**NAME**
<p>
       <pre>
              lamw_manager - manager to LAMW framework
       </pre>
</p>

**SINOPSIS**
<p>
       <pre>
     </pre>         ./lamw_manager
              ./lamw_manger [<strong>ACTION</strong>] [<strong>OPTIONS</strong>]
              ./lamw_manager [<strong>OPTIONS</strong>]
              ./lamw_manager   [<strong>uninstall</strong>]   [<strong>--reset</strong>]  [<strong>--reset-aapis</strong>] [<strong>--sdkmanager</strong>]  [<strong>--update-lamw</strong>] [<strong>--help</strong>]
       </pre>
</p>

**DESCRIPTION**
<p>
       <pre>
              LAMW Manager is a command line tool,like APT, to automate the installation,  configuration  and  upgrade the framework LAMW - Lazarus Android Module Wizard
       </pre>
</p>

**ACTIONS**
<p>
       <pre>
              uninstall      Clean all LAMw
       </pre>
</p>

**OPTIONS**
<p>
       <pre>
              <strong>--reset</strong>            Clean and Install LAMW
              <strong>--reset-aapis</strong>      Reset Android API's to default
              <strong>--help</strong>             Show this help
              <strong>--sdkmanager</strong>       Run Android SDK Manager
              <strong>--update-lamw</strong>      Just upgrade LAMW Framework  (with  the  latest  version avaliable in git )
       </pre>
</p>

**PROXY OPTIONS**
<p>
       <pre>
              ./lamw_manager  [ACTIONS]||[OPTIONS]  <strong>--use-proxy</strong>  <strong>--server</strong> [HOST] <strong>--port</strong>
              [NUMBER]
              sample:
              ./lamw_manger --update-lamw --use-proxy --server 10.0.16.1 --port 3128
        </pre>
 </p>

**DEBUG=1**
<p>
       <pre>
              Use the <strong>DEBUG=1</strong> flag later in any position of ./lamw_manager (flag does not count as argument)
       </pre>
</p>

**BUGS**
<p>
       <pre>
              If the LAMW4Linux launcher does not appear in the  start  menu,  simply restart the user session
       </pre>
</p>

**AUTHOR**
<p>
       Daniel Oliveira Souza 
</p>