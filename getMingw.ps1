
$MINGW_URL="http://c3sl.dl.osdn.jp/mingw/68260/mingw-get-setup.exe"
$MINGW_PACKAGES="msys-wget-bin  mingw32-base-bin mingw-developer-toolkit-bin msys-base-bin msys-zip-bin "
$MINGW_PARA=$MINGW_PACKAGES.Split('')
$MINGW_OPT="--reinstall"
$client = New-Object System.Net.WebClient
$path="\mingw-get-setup.exe"
$client.DownloadFile($MINGW_URL, $path)
