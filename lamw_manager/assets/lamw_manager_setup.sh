#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2882804386"
MD5="683eaaf4b430b33ed4e8fb4b160076c0"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23336"
keep="y"
nooverwrite="n"
quiet="n"
accept="n"
nodiskspace="n"
export_conf="n"

print_cmd_arg=""
if type printf > /dev/null; then
    print_cmd="printf"
elif test -x /usr/ucb/echo; then
    print_cmd="/usr/ucb/echo"
else
    print_cmd="echo"
fi

if test -d /usr/xpg4/bin; then
    PATH=/usr/xpg4/bin:$PATH
    export PATH
fi

if test -d /usr/sfw/bin; then
    PATH=$PATH:/usr/sfw/bin
    export PATH
fi

unset CDPATH

MS_Printf()
{
    $print_cmd $print_cmd_arg "$1"
}

MS_PrintLicense()
{
  if test x"$licensetxt" != x; then
    echo "$licensetxt" | more
    if test x"$accept" != xy; then
      while true
      do
        MS_Printf "Please type y to accept, n otherwise: "
        read yn
        if test x"$yn" = xn; then
          keep=n
          eval $finish; exit 1
          break;
        elif test x"$yn" = xy; then
          break;
        fi
      done
    fi
  fi
}

MS_diskspace()
{
	(
	df -kP "$1" | tail -1 | awk '{ if ($4 ~ /%/) {print $3} else {print $4} }'
	)
}

MS_dd()
{
    blocks=`expr $3 / 1024`
    bytes=`expr $3 % 1024`
    dd if="$1" ibs=$2 skip=1 obs=1024 conv=sync 2> /dev/null | \
    { test $blocks -gt 0 && dd ibs=1024 obs=1024 count=$blocks ; \
      test $bytes  -gt 0 && dd ibs=1 obs=1024 count=$bytes ; } 2> /dev/null
}

MS_dd_Progress()
{
    if test x"$noprogress" = xy; then
        MS_dd $@
        return $?
    fi
    file="$1"
    offset=$2
    length=$3
    pos=0
    bsize=4194304
    while test $bsize -gt $length; do
        bsize=`expr $bsize / 4`
    done
    blocks=`expr $length / $bsize`
    bytes=`expr $length % $bsize`
    (
        dd ibs=$offset skip=1 2>/dev/null
        pos=`expr $pos \+ $bsize`
        MS_Printf "     0%% " 1>&2
        if test $blocks -gt 0; then
            while test $pos -le $length; do
                dd bs=$bsize count=1 2>/dev/null
                pcent=`expr $length / 100`
                pcent=`expr $pos / $pcent`
                if test $pcent -lt 100; then
                    MS_Printf "\b\b\b\b\b\b\b" 1>&2
                    if test $pcent -lt 10; then
                        MS_Printf "    $pcent%% " 1>&2
                    else
                        MS_Printf "   $pcent%% " 1>&2
                    fi
                fi
                pos=`expr $pos \+ $bsize`
            done
        fi
        if test $bytes -gt 0; then
            dd bs=$bytes count=1 2>/dev/null
        fi
        MS_Printf "\b\b\b\b\b\b\b" 1>&2
        MS_Printf " 100%%  " 1>&2
    ) < "$file"
}

MS_Help()
{
    cat << EOH >&2
${helpheader}Makeself version 2.4.0
 1) Getting help or info about $0 :
  $0 --help   Print this message
  $0 --info   Print embedded info : title, default target directory, embedded script ...
  $0 --lsm    Print embedded lsm entry (or no LSM)
  $0 --list   Print the list of files in the archive
  $0 --check  Checks integrity of the archive

 2) Running $0 :
  $0 [options] [--] [additional arguments to embedded script]
  with following options (in that order)
  --confirm             Ask before running embedded script
  --quiet		Do not print anything except error messages
  --accept              Accept the license
  --noexec              Do not run embedded script
  --keep                Do not erase target directory after running
			the embedded script
  --noprogress          Do not show the progress during the decompression
  --nox11               Do not spawn an xterm
  --nochown             Do not give the extracted files to the current user
  --nodiskspace         Do not check for available disk space
  --target dir          Extract directly to a target directory (absolute or relative)
                        This directory may undergo recursive chown (see --nochown).
  --tar arg1 [arg2 ...] Access the contents of the archive through the tar command
  --                    Following arguments will be passed to the embedded script
EOH
}

MS_Check()
{
    OLD_PATH="$PATH"
    PATH=${GUESS_MD5_PATH:-"$OLD_PATH:/bin:/usr/bin:/sbin:/usr/local/ssl/bin:/usr/local/bin:/opt/openssl/bin"}
	MD5_ARG=""
    MD5_PATH=`exec <&- 2>&-; which md5sum || command -v md5sum || type md5sum`
    test -x "$MD5_PATH" || MD5_PATH=`exec <&- 2>&-; which md5 || command -v md5 || type md5`
    test -x "$MD5_PATH" || MD5_PATH=`exec <&- 2>&-; which digest || command -v digest || type digest`
    PATH="$OLD_PATH"

    SHA_PATH=`exec <&- 2>&-; which shasum || command -v shasum || type shasum`
    test -x "$SHA_PATH" || SHA_PATH=`exec <&- 2>&-; which sha256sum || command -v sha256sum || type sha256sum`

    if test x"$quiet" = xn; then
		MS_Printf "Verifying archive integrity..."
    fi
    offset=`head -n 592 "$1" | wc -c | tr -d " "`
    verb=$2
    i=1
    for s in $filesizes
    do
		crc=`echo $CRCsum | cut -d" " -f$i`
		if test -x "$SHA_PATH"; then
			if test x"`basename $SHA_PATH`" = xshasum; then
				SHA_ARG="-a 256"
			fi
			sha=`echo $SHA | cut -d" " -f$i`
			if test x"$sha" = x0000000000000000000000000000000000000000000000000000000000000000; then
				test x"$verb" = xy && echo " $1 does not contain an embedded SHA256 checksum." >&2
			else
				shasum=`MS_dd_Progress "$1" $offset $s | eval "$SHA_PATH $SHA_ARG" | cut -b-64`;
				if test x"$shasum" != x"$sha"; then
					echo "Error in SHA256 checksums: $shasum is different from $sha" >&2
					exit 2
				else
					test x"$verb" = xy && MS_Printf " SHA256 checksums are OK." >&2
				fi
				crc="0000000000";
			fi
		fi
		if test -x "$MD5_PATH"; then
			if test x"`basename $MD5_PATH`" = xdigest; then
				MD5_ARG="-a md5"
			fi
			md5=`echo $MD5 | cut -d" " -f$i`
			if test x"$md5" = x00000000000000000000000000000000; then
				test x"$verb" = xy && echo " $1 does not contain an embedded MD5 checksum." >&2
			else
				md5sum=`MS_dd_Progress "$1" $offset $s | eval "$MD5_PATH $MD5_ARG" | cut -b-32`;
				if test x"$md5sum" != x"$md5"; then
					echo "Error in MD5 checksums: $md5sum is different from $md5" >&2
					exit 2
				else
					test x"$verb" = xy && MS_Printf " MD5 checksums are OK." >&2
				fi
				crc="0000000000"; verb=n
			fi
		fi
		if test x"$crc" = x0000000000; then
			test x"$verb" = xy && echo " $1 does not contain a CRC checksum." >&2
		else
			sum1=`MS_dd_Progress "$1" $offset $s | CMD_ENV=xpg4 cksum | awk '{print $1}'`
			if test x"$sum1" = x"$crc"; then
				test x"$verb" = xy && MS_Printf " CRC checksums are OK." >&2
			else
				echo "Error in checksums: $sum1 is different from $crc" >&2
				exit 2;
			fi
		fi
		i=`expr $i + 1`
		offset=`expr $offset + $s`
    done
    if test x"$quiet" = xn; then
		echo " All good."
    fi
}

UnTAR()
{
    if test x"$quiet" = xn; then
		tar $1vf -  2>&1 || { echo " ... Extraction failed." > /dev/tty; kill -15 $$; }
    else
		tar $1f -  2>&1 || { echo Extraction failed. > /dev/tty; kill -15 $$; }
    fi
}

finish=true
xterm_loop=
noprogress=n
nox11=n
copy=copy
ownership=y
verbose=n

initargs="$@"

while true
do
    case "$1" in
    -h | --help)
	MS_Help
	exit 0
	;;
    -q | --quiet)
	quiet=y
	noprogress=y
	shift
	;;
	--accept)
	accept=y
	shift
	;;
    --info)
	echo Identification: "$label"
	echo Target directory: "$targetdir"
	echo Uncompressed size: 160 KB
	echo Compression: xz
	echo Date of packaging: Wed Jul 28 14:25:14 -03 2021
	echo Built with Makeself version 2.4.0 on 
	echo Build command was: "/usr/bin/makeself \\
    \"--quiet\" \\
    \"--xz\" \\
    \"--copy\" \\
    \"--target\" \\
    \"$HOME/lamw_manager\" \\
    \"/tmp/lamw_manager_build\" \\
    \"lamw_manager_setup.sh\" \\
    \"LAMW Manager Setup\" \\
    \"./.start_lamw_manager\""
	if test x"$script" != x; then
	    echo Script run after extraction:
	    echo "    " $script $scriptargs
	fi
	if test x"" = xcopy; then
		echo "Archive will copy itself to a temporary location"
	fi
	if test x"n" = xy; then
		echo "Root permissions required for extraction"
	fi
	if test x"y" = xy; then
	    echo "directory $targetdir is permanent"
	else
	    echo "$targetdir will be removed after extraction"
	fi
	exit 0
	;;
    --dumpconf)
	echo LABEL=\"$label\"
	echo SCRIPT=\"$script\"
	echo SCRIPTARGS=\"$scriptargs\"
	echo archdirname=\"$HOME/lamw_manager\"
	echo KEEP=y
	echo NOOVERWRITE=n
	echo COMPRESS=xz
	echo filesizes=\"$filesizes\"
	echo CRCsum=\"$CRCsum\"
	echo MD5sum=\"$MD5\"
	echo OLDUSIZE=160
	echo OLDSKIP=593
	exit 0
	;;
    --lsm)
cat << EOLSM
No LSM.
EOLSM
	exit 0
	;;
    --list)
	echo Target directory: $targetdir
	offset=`head -n 592 "$0" | wc -c | tr -d " "`
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | eval "xz -d" | UnTAR t
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
	--tar)
	offset=`head -n 592 "$0" | wc -c | tr -d " "`
	arg1="$2"
    if ! shift 2; then MS_Help; exit 1; fi
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | eval "xz -d" | tar "$arg1" - "$@"
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
    --check)
	MS_Check "$0" y
	exit 0
	;;
    --confirm)
	verbose=y
	shift
	;;
	--noexec)
	script=""
	shift
	;;
    --keep)
	keep=y
	shift
	;;
    --target)
	keep=y
	targetdir="${2:-.}"
    if ! shift 2; then MS_Help; exit 1; fi
	;;
    --noprogress)
	noprogress=y
	shift
	;;
    --nox11)
	nox11=y
	shift
	;;
    --nochown)
	ownership=n
	shift
	;;
    --nodiskspace)
	nodiskspace=y
	shift
	;;
    --xwin)
	if test "n" = n; then
		finish="echo Press Return to close this window...; read junk"
	fi
	xterm_loop=1
	shift
	;;
    --phase2)
	copy=phase2
	shift
	;;
    --)
	shift
	break ;;
    -*)
	echo Unrecognized flag : "$1" >&2
	MS_Help
	exit 1
	;;
    *)
	break ;;
    esac
done

if test x"$quiet" = xy -a x"$verbose" = xy; then
	echo Cannot be verbose and quiet at the same time. >&2
	exit 1
fi

if test x"n" = xy -a `id -u` -ne 0; then
	echo "Administrative privileges required for this archive (use su or sudo)" >&2
	exit 1	
fi

if test x"$copy" \!= xphase2; then
    MS_PrintLicense
fi

case "$copy" in
copy)
    tmpdir="$TMPROOT"/makeself.$RANDOM.`date +"%y%m%d%H%M%S"`.$$
    mkdir "$tmpdir" || {
	echo "Could not create temporary directory $tmpdir" >&2
	exit 1
    }
    SCRIPT_COPY="$tmpdir/makeself"
    echo "Copying to a temporary location..." >&2
    cp "$0" "$SCRIPT_COPY"
    chmod +x "$SCRIPT_COPY"
    cd "$TMPROOT"
    exec "$SCRIPT_COPY" --phase2 -- $initargs
    ;;
phase2)
    finish="$finish ; rm -rf `dirname $0`"
    ;;
esac

if test x"$nox11" = xn; then
    if tty -s; then                 # Do we have a terminal?
	:
    else
        if test x"$DISPLAY" != x -a x"$xterm_loop" = x; then  # No, but do we have X?
            if xset q > /dev/null 2>&1; then # Check for valid DISPLAY variable
                GUESS_XTERMS="xterm gnome-terminal rxvt dtterm eterm Eterm xfce4-terminal lxterminal kvt konsole aterm terminology"
                for a in $GUESS_XTERMS; do
                    if type $a >/dev/null 2>&1; then
                        XTERM=$a
                        break
                    fi
                done
                chmod a+x $0 || echo Please add execution rights on $0
                if test `echo "$0" | cut -c1` = "/"; then # Spawn a terminal!
                    exec $XTERM -title "$label" -e "$0" --xwin "$initargs"
                else
                    exec $XTERM -title "$label" -e "./$0" --xwin "$initargs"
                fi
            fi
        fi
    fi
fi

if test x"$targetdir" = x.; then
    tmpdir="."
else
    if test x"$keep" = xy; then
	if test x"$nooverwrite" = xy && test -d "$targetdir"; then
            echo "Target directory $targetdir already exists, aborting." >&2
            exit 1
	fi
	if test x"$quiet" = xn; then
	    echo "Creating directory $targetdir" >&2
	fi
	tmpdir="$targetdir"
	dashp="-p"
    else
	tmpdir="$TMPROOT/selfgz$$$RANDOM"
	dashp=""
    fi
    mkdir $dashp "$tmpdir" || {
	echo 'Cannot create target directory' $tmpdir >&2
	echo 'You should try option --target dir' >&2
	eval $finish
	exit 1
    }
fi

location="`pwd`"
if test x"$SETUP_NOCHECK" != x1; then
    MS_Check "$0"
fi
offset=`head -n 592 "$0" | wc -c | tr -d " "`

if test x"$verbose" = xy; then
	MS_Printf "About to extract 160 KB in $tmpdir ... Proceed ? [Y/n] "
	read yn
	if test x"$yn" = xn; then
		eval $finish; exit 1
	fi
fi

if test x"$quiet" = xn; then
	MS_Printf "Uncompressing $label"
	
    # Decrypting with openssl will ask for password,
    # the prompt needs to start on new line
	if test x"n" = xy; then
	    echo
	fi
fi
res=3
if test x"$keep" = xn; then
    trap 'echo Signal caught, cleaning up >&2; cd $TMPROOT; /bin/rm -rf "$tmpdir"; eval $finish; exit 15' 1 2 3 15
fi

if test x"$nodiskspace" = xn; then
    leftspace=`MS_diskspace "$tmpdir"`
    if test -n "$leftspace"; then
        if test "$leftspace" -lt 160; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (160 KB)" >&2
            echo "Use --nodiskspace option to skip this check and proceed anyway" >&2
            if test x"$keep" = xn; then
                echo "Consider setting TMPDIR to a directory with more free space."
            fi
            eval $finish; exit 1
        fi
    fi
fi

for s in $filesizes
do
    if MS_dd_Progress "$0" $offset $s | eval "xz -d" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
		if test x"$ownership" = xy; then
			(cd "$tmpdir"; chown -R `id -u` .;  chgrp -R `id -g` .)
		fi
    else
		echo >&2
		echo "Unable to decompress $0" >&2
		eval $finish; exit 1
    fi
    offset=`expr $offset + $s`
done
if test x"$quiet" = xn; then
	echo
fi

cd "$tmpdir"
res=0
if test x"$script" != x; then
    if test x"$export_conf" = x"y"; then
        MS_BUNDLE="$0"
        MS_LABEL="$label"
        MS_SCRIPT="$script"
        MS_SCRIPTARGS="$scriptargs"
        MS_ARCHDIRNAME="$archdirname"
        MS_KEEP="$KEEP"
        MS_NOOVERWRITE="$NOOVERWRITE"
        MS_COMPRESS="$COMPRESS"
        export MS_BUNDLE MS_LABEL MS_SCRIPT MS_SCRIPTARGS
        export MS_ARCHDIRNAME MS_KEEP MS_NOOVERWRITE MS_COMPRESS
    fi

    if test x"$verbose" = x"y"; then
		MS_Printf "OK to execute: $script $scriptargs $* ? [Y/n] "
		read yn
		if test x"$yn" = x -o x"$yn" = xy -o x"$yn" = xY; then
			eval "\"$script\" $scriptargs \"\$@\""; res=$?;
		fi
    else
		eval "\"$script\" $scriptargs \"\$@\""; res=$?
    fi
    if test "$res" -ne 0; then
		test x"$verbose" = xy && echo "The program '$script' returned an error code ($res)" >&2
    fi
fi
if test x"$keep" = xn; then
    cd "$TMPROOT"
    /bin/rm -rf "$tmpdir"
fi
eval $finish; exit $res
ı7zXZ  æÖ´F !   ÏXÌáßÿZè] ¼}•À1Dd]‡Á›PætİD÷¹ù$/RA	»,{»­YŸÕ§c^dZ|BÆ? ¨,íŠ"ïªÇëCc°d4JQ#6$+F"şºÕ©Ú05ü8GQ!Y…ÌÜ*Òè’l¨e•Ã‘I‹¨*„
øüu%­hôéşh#,_â¸$¢Y”°du0è¿šáBG•TlíÊÕÜB&8$½Ë‰«è®¥ÿCZ@bk›Q”=¼¿zC2+]¯àx¸„‡êÈ“Ì¤}%} šı‚ên.»Æª¶¶İøË6dŸ`À)!ÅÖºöÑ®‡p“è¹ú\¶`üŸ”MU²^| ÏıD»óHÙ²8ÛoÈ¦n„™ç,ıÅk)¬Í…ãÕYpY^|D>ãxD‡•Y4Ÿ`Á©±İ®Šá§u>üH—°™¦¢TFUş_p`4î-ªõŞbˆüoŸ=e³
íˆÚ©Bˆ°apŒ:ØÜPh>Hü6µO­²oedŠ1İIrã¦‡?EÕ[yui…¾ÑnW~yø­Èÿí,{¼@"Zû’(>í	]0~Å¸ú¡CßƒÈ£á×‰<H,n>kÃ+$Y™¦®Î‚%r\¿ÛêélG§•†Û“r`‡'²ÄÒë*„¾‘!ÀrúíŠÖ·mÒbq/Ğz3INd`ß(ØPS53èU‡jCçäC
n>4¿èşÁ#®Õ"ƒ:g…Xˆ^\4íI&<éş‰·ş øQ¡§>õÀæ–GÈnöê~¸Aj¼VœŸdªQÊÀ¹í¥!’6ã¬+ªŒ:tÅtÑÒDü(;èÆôRçP(L—óòjé¦â©‘(µÿ½ç ÎªŸC·¿XÔ/µ¶“*b¹ÚÖĞZHÎi58XÊ€‰D¶i­öù,nj½òÙß«6·¹œJåNÕƒY^çâ¹—ôsçFYˆ¤ZœéƒjYtO˜g?Òë¶>ğTï~=&kyØ"ãEŠíş[…˜zùgV­˜Ù‡uq.7ù¥U…•°<üO\Å<Ò=–v›Ø*zt$·Ï„¦\^ojæ–Ñ&lÏ`XİrÈõ}Ø^$]ZJBíÆ4º5´ónùçoÛ%K#ÿ¦¶>{¼ÕG8ópóA·82÷ÄØˆ¢üIC4!eT‘×JFJHò‹M{ıPÉ‘Øát`ëgâ\Kó×IÆĞ‚´Ğ§	‘ü¼ê/äÑ*Ô‹ôùT´{(/ĞàtÂ^ä¸ì<¢¡°ùÉ6¢ˆ®›Isš¿iV1Ì¼¤ ùWdò™£ª'®#Ù‘E«&–.62Êç;Šå­…›ë\zÎ¤¤Ößı,£âŒXÒ•‹€7¨Å*¥¢¯Ó“tåóŒp=ÑT—¶²³ß‚¸”ÍÁ¤ê4.éøï¢LÔéq/u…ØI_±—€Aœc÷]Ae|Òó‡ğ$So°Åß@¯ª OÊ{¤á#n§…Qkåé]~aA+šY4¸ùi¥ßcìgët‡‰ĞïŒ¢•¯èòIŞ™¼‹5FæÄß"5€¤_<o½uBß­Š†½ñ%3şÈô5Ş^NæÆp"CÈÎWÖªÅî¶å•ï‰¬AÈàöGMdŠHº¦ƒ¶+=“åîG˜š=(C¥¶ácµÜš0¦ÚúÃ¥¼v}·@0ºÛ½:·SóçH™&Ä‰*nxİw!·ô›c•‘_m-ÿÚw?,ÀD‘®ºM;ÄrêÎ:všlŸÌv'ºb–¬‘6$ÿ	¢<¸òÖNåÏ°Ú¶Çl]ÄÀ x·´‰À^×‚KV§qË£eñDıÉùd
ôêVIi÷>à;,:ŞqN#ÄßÀßF¥RãŠèåQZQ—Å¦ÕÓ#EÖAM/$CAÖvç©ÇJ×âil£÷‡>å–vÓ2m‡xétDø@ÅÁ
Cæ–‰Ø.*:ˆóÂzoyâB:]/á|Î}²#|ÛD”8Z®²´Ó”» „šr±áûÏ|¦ÃúEv¹Ë†½€Fd>ËÄO:Ó²¨5ª’H½ş.€]˜
¤rLi5Óahô%×†xûÈëä`œÂÜ–¥:Ú]„wVşñòf;¿…'Z9
=äñÚú.é0çıeCÈõêªšÚ½-s
ÏÑ{¤´8.ØSì—:Ò×¨”Ï¢yõÉˆ	S±HÏŸá‘ŞŒq-xü[{3ó»PJö8z…CÚ»Ü¨Çy]3š¥£²™zÆ*·ûuŒ¥ÏÚT‘1á÷ÀuØ	¸cEH#ƒ£qê)h†˜ôË²ÂˆÔëTœ?™“N°,ëSbfGWë¸Ãøù)èU.âªYÁØèU(¢®óúY1Î¿àIİZºû¤…Œ…9f(4ö¿+Ze‘>­$á8_¤{jçıÍöê2Â³ƒ/Œ|R«Ì6”ñå}¾„¹šÇUç}Kñ_|Faqk\(¿@ö“Î˜Bš¢hëŒºd3#-†)EÇ±	}O˜¢©oínÀr}÷b&ÅzÎ¡î1ñUnr~Z#Ğ$µÔ·2é‘¸x>à”9ğ™àÔNxhåšô‰ëU™º‚;ø†_àÙµ*]¶¤•Ü_S,i´?•ó©8÷X¢pº‰ãªÄµZó B¨àçÙxkâ >Xº†Ğ©‰§M.MlNyé¶Â–eZ¥&ÿ~Ü¼Ç™tÀDÇâ‹Â_D·¹®%4›”öIeBş1Ş+ÁàgîÿÁ?w€ıÎÜ^«½úİë›DE¥Ì\•İzÀ-ŒèÔA	òŸ²…›õ¬{*àç‚‘{Æ¥‘ô¥amê‘–fBÃø#²êî‰Ÿ†HrÿÃ×¤:9Š­çÇîB¢MëÜ	êÜ<	­b“[ÓLV¼Û^+Å@}¨xæ¯¹ŸÛ9²ÿlTùg÷†»ùN®l«P¸‚Û¢V‰˜ª'X«M¹“ÁUÖP'…»0—uDH´‹/]i=ËÖ{³·0BÛ¦É¨T¾ƒzz%¨°py7n]5gHì(RgQì»3W‘àKÚ«š˜^ÛDï¶ù
î@ì<=Ğ4–ëı&ÇúJãÈ µj‹Ò¾j~¯úiUİ°Ô–Ñ¼«ËÛÔM=Î·Si-VúTR¬¹ëãÎíeP~Måşhàªz$4&*¯L}0Ê2ĞG°)'Ï­cOQQZ7iÜÔóÒ•í…—mxÂDüÔŒ2siîú×VïÛf‘³3€c„Å3*ì<àøŠòÄğnˆLïİÊz£%û[íİ0áæçUHªó!·¸Ñbë´ø{Ğ€‚­#]ô‹›šPhSO~Rhú’’e„Ù€Ãjìl.x ¿Ğâh	r†ñC&Ë¢g{‰I'}DÌ°N¦kv%i0°2d²ÓÉ8•±Ş]»é®~1n7sD,ĞÇÜƒÚºLXi€xDÊéQ &ñ×ã¤z’šéGçÀê»wwÔ’I±*½ã¼l°!eûÆ¥Bd/)@;÷›ÜtòM^²` çiªïR¾7Ñ³*(–EGbòP6®šëÔÂ§&Ê’lq­«n2V¢­2C{9Á–“Ñ·!¤=N#ş%ç>a%µQì5æD-8Ö ñ®$Xİã³]ªYóa#ˆœ™m¼`ö{§>øøuSÑœ_›Gm´Ê@>UIFı+ÇÔl‚ü%	4Úúœ³Bª âd›È$ä­¸F²ÌRmw°6S«¹TR‚¯ƒéRíR,	ƒ:ı$J¦×EŞ><SG™KåK¬İ¯Ó’S+~' °ù¬*%>$7	E	æéL–^h»‹ éÙ7Ï ×=£¿!L!*¹Ò_>±vŞ/#o@7 èèk>ç…6?Cº	Uä*^%ºeWò~éçJÈ‰%j9›ßÎ*BëäZZMúu3:;œõ¡oø`ç-5HÏAûIªú“7ß£ÙJ™¨I›ü¸DB[Øjßv“G$İ õ.À¶+JqØŒ^å¤óÜŠ„¨ğxÈ—÷ÿ”"‡¹ÜºÑ`kwFY+Uß•!¼Ã³[%ĞÖ‘Â}ÀÑ8ŠİªüNÉEÏ›<í…×Ç¦“Kø[pô¨À%Ú¹;syüî¥ŠÄlŒ-Z¦@)PXŸØ wu¨qÜ=t¾ß—'õE°Aò§·RF£uÛõIãğ?-â8÷c6-H,.Û&´Ì0éoÂ9ZYÁ´Ì¶D‡ Bºgëqƒ¼’12:Õ;\Tæ“9#86dDX„XúZv“éÿ’[QtÁl sàjŒ”Š¸Z»³Û¾İr.®vH=FJîâF—Ü)/FË`ÆnûQ‰JhèªãËŞÉöê¸Ş*—h3Ê)åvSàOó¿&Lò°âšw­‰‚Ô¾Ğ_<ÇÂÓÕ£Cç“î9ù<P;…h–K]ÿ¡¼œèÙÓ@á<$”jœô°À$w
f›¬„ùqÓÛ k²ğ˜&3ÕñuOSûIèŠ‹ş¹ª'‰Yÿdxü”S"[Ïl[qõ^¦êùÀKpP¬7f€ƒÚ!1İ’¹÷¼¨¾«V‘øÉJa@şL¡ÿĞ,m½û"µhu Gâõñ|`UÃƒÃíæÆ(Ï8q*êäï#Æüpo7˜¶½JË'„‘e|²ô>_'fh%¡Xğ«™KÕ'Ü$ndü0OùBé|8o@×gXu“-T×©¸úñCy3§R@|<Ö"£/r4dY*~pr>‚—4lWßN,q^Á*GõĞ®ò‚±:TÜcÙ~Hˆæ,[˜ğÏ†7êQ¯Ãc°R±8±Ô;"ë·n?ùaEúßâÇEÏÌØÖ´ öUçõ“ƒÃKÑŞÆãhü¢å÷Gˆº²È[¯7Tùræ?¹ 8‘&D(]±]Òşè,«à,Í íÀf°¬êPëL^Õ´n$%­å“€Î\ˆaq
MnÌ*¯eZñ
¡*}Šèr şçœ^>Ñ×·1—ï˜ºÙ¤ÄMØ‚ÃSy
7Ş¬ğôÚU9AHÜ\Ïš	Âì¯´Õt®—M*¾ÙAyÅ¸ «2¡•\qŞbxµ.÷OÔ›—¹…gı­G§çó¢Ée‹l›36òÌ¯xu³ùş*Ğ«¦î´·^I¶Â×/Ë .2I?Hµæ0’¿kÿO«_Pİeá×1áA±ßm>¶	q“>8••^Ü‚Iúj™G:2/aS4şÕƒ›É¡*£C=á“L—gù¿É`§mÊÓÁâ¡±FzX5Ö*0`ŒÕøÂ‰’î”/_Ò¹ˆN˜ÛYrš§sèQë6v.bÃş‡ÖóWë£B(;QP{vtˆTäøß [ìK^­aŒ/š<÷©¢ÆÿÎ7ËJ—àH	KpÍA“š²oITX«÷dÃúA²h …ıÖ£Wˆ‰ms¦GÏÙÄ÷È\Ö«EÜÂ"•Œ–,FşîÆÎ¡•'k|ŠE*5âõ"Î(¥¾ çó¬³;¶™Cã²*ŠDõ?ğ”0{ëßàe¼\-g¹ö\İÜ´?¤÷òŸ+hÂ÷|xh™G¢'ë8ŞÒ¹uOKcOéÛÕw$ØÀc`ÎbNËZal\—‰¶ÓT»e!”›^~¦[•ÓÙÑ+U<Ò³á‹Új¡=èt*½jÛ?ğZdù®Hª8­tÓŸÓ¬O]#bTd‡ŞŞÃ«kËk·u,««¯˜ÒéxYƒI„„;DÌõ\LîéSËÊ1HŞiP‹:/õ|Úª6EPŠİÄÆ QÀÑ—$Ã¯õµ(ÙÄpÖ%ˆ°Úª×'æV`qÑHĞÏ3®®C"ß+ô~×#‡àC…ÙJ`™ñÛWGÓÅoÒ1lÀDIàœD½p·Óæ•+FìZ€vÒíh¿k=ås.£AÑÀÔ]Ğ%CÔ¢šrZ{m?0å-ëyúÇóÃ:êuÎ¶ÑÌ}fWˆÆ$|çÇ®è<õREèä	Æ-èB Ã…êSqjó˜{Gaó‹Âõ}Ş…Íg-ò°8Ì¹£EÖ(ÛÂ2¿œI£PtÜ†fôpé~+T’rJşĞK1:bûYôFøÿî§§§­]¾¢66Û¸ÙYEBJÊ¾ƒÃ%E­3Eú-æ•£ÒVp÷æ:y ş}h¬ZÀ¯Q+tîÌzŠªÌØgÛIêê8ËÙí:0îëtd˜g5õö©M™‹úŸÌ#è§*>$øèÃú$ËëV«RšoK´GZ«TÕ‹öÛ¯GIs«æ;ÒÀú nú"˜Ùï¿ÆŞ¸×PR`•ç–HìrÇí ‡Q$ĞXã» óu‹rw£ÃıVìÆ,ı!ÖË@SGVMŸ$§Ì@ãÅ”^çº¿ß"•†rğy.åÈØÄ¶m¸‘ş?bñè9ejßÜÍdíÇŒ¸qE» *WäŸŠíÆÙs€Ÿ·é1˜vxë<üë-êMré{/S3Ì{+@ß^„W³Ï^÷<üdnÉ·Ğó;ÿâ²¹öÍÄH_Æ|Èg6G:”Æ2D£%GşæÇÍ52úÄ5¬o8oHCoÜ{[İQV­ış×¤å£(ƒ	hD/æT$ñgïáX“õÎµÃxâJêè[rKî²q´ ù6…úNäœTIa„ÿ´Æ>ì^§?µ;ùúäU¨ÂÉJ8ÑÆ’ù÷ı»Ùh˜SÛ'ğF¸~}îû0ĞÒÄh
šg@?E&ÍÙkR,oĞ
ê/;ëMóîÏã§Ü\ënI]`Ôå1ÄA‹ÙZ1eÇõ€éº¯—‡EÄİE)Ûç¸¦8bCœUÓ©®ˆÚñFSãne$ğÛ}°zIñ'",¹iŠpÀa¸E0á“ uÄÒ1´†¨%LW.Ä™4–ÃÍbQ9bN‹#/núêİ»ÜsÕ2_>«ÙÒ%¡e ±ˆøİÉˆÚëı%›$/¥-|­XKÿ“l
ïhs]69µ¹ÜØ4pè}üSHqşy Æ¦:p
ë¾ùÈñœ5½ÅLì$` ©È\J·n9UÔÓä´Bv!VùjŸçVQŞXsF 2ª§‰(p¸A/Ûæ“’a˜B—¿Sv„,
lFŸë:ÓßÖ‡Â${vg ,²Ï©äEC¯po#¢+|<×|‰Ï*d=÷ò12K°Xrå‰êST'š©„Ö%³ŞX¸Ş'zo}ƒ ¡ØÜV{sÃàq=x©"B¼Í¯Ã~½÷ÚLcMÁ3O‰™9Í'°xctyJƒ}ÎV?Ù”•«€ğiğ8rÄZº’ÓàÛ±H<nmíı¾!<`Ñb‰Ú"9^rëEÒæÂ|qøòºâmŸ:Çrù—j®£òª³¼òò¹Ù˜Ñ­„9DÖpİ@kÎ€,¦%á1äC€ƒXîCFs^YÄà@VÃuıií­9ï•X'“Yò†^ˆ_*µÆŒh°øà×W·‰ÚºFÆÈ‚Ô‘}0Úqs&mãøì¬/ƒ¦g0¤1¯Äôtj©«®à“ŒçC^–3Z”œnjÿÄPÔÃ¦µÒT…y,â4ñæ²ßBRf·ßK¥v\W·'¹Ø¹’ÉÌıİpÚ-d¯òB‘
Ë‚ÂvgdBº\Gw\Øî‡µ
¢GÒ­Ü¶e>=§9Êz÷¹NXfRã=V¡ïÙpz¯´¡$b66ÏûÛ†CS®»îŒå=šG/oSÈÁllv=.LN;yp¢wri¨ã|({¾bÕOßâK×£‘÷Uf!…¬€‚æ¾íä0›ã­<tµ¤ûğ:€T	útè«Ø¤hä]vïœP„°’pÎ}Y»Vø.¯àëÚ5ÎE¤„Ö(­H‘Ù|Ô.5ş`lÒ÷TïcU/]ßgØc­²TÁ£NrQÎd·Oƒa_itÉ\Ğg;œíK+¿Vî•~šÃY”¤ß´†û^»&4R.\bòmPÃÆhËüÙ\¨Š	D¯µßÉtVÏÚL-.­v˜µ›':
†§”F|^/×yMaSmUtbÃ{ZÿDøÕ|eC“9¡ñ»-­¶01.õæIÂø•[ŠL|"]uÍ©~÷ë´†Ûñ)òT«WNwC§àfğIªX[z]E×ÍJì?Êß„¸3¶hhLÜıVòıeše®OWf7!<ë¿µ,Û’Îh·p9ÍZ…æuåÈ0Á8êKÔ¦ùï‚PŸÛÙZ{ãë"®tJìÓ^ íµœ#¤á’P;œArâ…
«¿Õ«Û±è=áQà8Bæ²Æ°¸éAm.u*8æÛòP“?a×µq't9-ü{Qõ=S%¾f—‰H¬îî	ñ…[¼Ú‡ZàÛr ^p:ÉÛÁûÁÔˆRaÄõ¡ª`òhƒõ:ñóıÄ_Ü%ŞCib-œjH§5‰,½¹KöÍÂ¤éˆ‡ôâ?ØxtXÄX×.1ÈC8\º¶#€	ºSšO”RŠvİçç^§„£‹ãGãLz¡ÜÄBNR_†N„i²)æ•p]òC%);ı²OzÅîôwwÛLY‡Ë<nÆ¦\ìÀ|vqÂ Lv)ûˆQflkÜï .¡^ñÀÚ,°áËg#Œqçøœ*×åÉ½çLnª£|³Em8œÚ²P`3Z?‰ô)ÏK¥ó×¤+DüİúYÖ²¶nå'Õ«¨T?Yá¼ZçrÈ9Q£Á	
‹²õ3¶¬uEÃØ—¿)ø)(~+õÍ†cıeŞù„=­ÄŸ…Ã~j*+ Ä[ @ŸØÈê¾ÓõrXß`ßßéÕ	¦lò ç Ç™7È¬s¸Å¯2®ê°œƒ ÆùVúNÑGÚİä;=7e~ä®—"·‰R}¬£ƒÇlŠ³Sy'€ìag`PÇ´ŞŒ˜In Yw0Œˆoj4]>åI^ohzSM¸ùã6 r¹Ó‚·œïÙ„=I…9´è›#ì
ú
vÂ§ºé9Ø,L$;Ù,Kx*'*êXÁ”SÃ»Àeï0ıÉ«0î±#b¯¤‡í8L@&á Ú
ãÕ÷¬ïZ	‹¸åD½÷µ§T;[/”ic
úl–k­ù2î"Vúª4„vxİ’Ç=æt¡I¹[J®Ê:[1UqÜpô!¬d©jÆö³ö Œ·ñA$ÄüÈ¦ÿv
•˜dŒáå4”°yÀUåŠñø^ünÚ*ÁŞª$ïô*‚~ŒêÕ:x­$®?WâÏLƒ¾˜U+vìvVS|¨ñÊ¼p´'´	©6#Ğˆg½‚*úE1(Ğ»)OŸ—Œğã;8ZÌhƒø¬ÑÕû•1<ââ ÙÔ"×cWÿÚ¹ØLÌu‹P0OÑÁªàDé+¤P0qñ4ó8îCâN3ğú¥?×ìu‡D½–ª8ê&ì~×.Z¹7‡’>ÅØ¦ƒ÷âù¦ğÛÈšˆòYG4F†pá’Œ·ƒ†+ì{¢óqòpŒÑ¬5|¾É`ø³´¯øá/ûßèzuúïÚŒ"év,"´´ßÆ¸Œh1¯Š™ÒÉ6ÛM\PQıLeAà„Øş4k8&”_õº”·€/9äš½ã%$}IÖád±­³!*·ÆÌôşë­¸²Í/PYutYİ{hûöÉØùMÖb: xè4Tç2&€ÅË5Qs91åd8ªËbÇìÙ¾/«aa^¦hÙ\ı!å“j»Ö‰|Ö2H††ê4œÛ®xœ~ 1Ò±Ñír[gdÎ¸³ŠUËP•Ì7ZX½¬rek}ÕêZØ©¿84BÄé5ZY5iaŠ`©²è¸áôÖÑ©)»poÖ^®Š†2¦ÆEÕHÅO^ÏZ»¯+Ja”|#fd³u”b>Ë-¶ºm›v£6XH!c•9°&å^hãql°Aû&»X’œ&‹wàø§Ÿ^iÓ@‹Y@'iü.€„«ôÄ4‡ÈM¯ƒ\¥İ\O½úO‰ˆÀsO× õpO’[È×#V™‰™¨J.Y>ˆ‰µùÌ‹\'J?iD‰¤€NL<æğTùn+¦i&Su(.ŒbY¾o—WËüìeÇHöª;OØøè'„pÑÓİ}eÈA6û}N°µÏû„¥E ¥qªìC°;ôA´ŠØ•9àŠU`km.Hs€Dğ²esÙ•V8øÛnpï—µ2«öN‚¦_!oö®ûë®êğ€éÜ—º\1ÏœBñÃ(8Pè€¿àÚ¹ªë¬¡\Øs[dİNë~3ÙQ†µÓšb‹0«
%h¯å?Şôi2p›¹ã7D¾Šhï„şGtU„è`ø la†+³).]÷Äò
F`ğpz—ë ¡‰¤¿>IZ«¤1¦ƒw ‘«DY¼c±ø´1v²=.Ô ».Ú4×F.ã)y‰±c 7HŞœùKædœùÜÖ€{só·Ğ^˜º óÆ{ÑœB?@¸byMn’üÛ¢ÈŠìf‰ñc¦¦=¼'ÅâCq‘ÊÂ–;°ßŞ˜#¨U+Éæ%e]©*ìÒìïO/ê<øXÊrI…Dşü~í«œz´›©óeÈÙ›KŠ]ñëƒë%„ÅÖV¥nª=hì’#øÂì3×ßdgï-æŒ^É,Êµãrw½ĞàPr‚³ÌŸ*%Rx±”/¯\G&èÛLªÍÈ2=E¿şÓ¡x6|ûgÎZAòk*ÊBQÂÂ”ÃĞ/ŸœP_Â:€³­gb5ºPgJSğ‡£Ô÷TíÚÆ¿k6Rè2,WWæ­ĞÄXr0+5ßH.âá‘©îM¨	ƒA‘o"j
8ö_”q@vÄ‡Y[½<Óò:@mêz‡yU‚-†á$ÂI„ÆeòÄ Hä'í½og_.±ùI’×`˜Ò¨};e<¼µäC <7Í¡¡ï`ô$¬\¿9=}J´hL­“vÃ'¥\¶­E8ÄÜ%Ì3|8gnW™ü3”€Ìyi›Lf _Ë­`OKŸÈ]VkÜ•1Y>˜î˜}€îYŞÜ‹Ÿ¤49miØC>òŠdRz[Í™›/rïH65dKÛõÊ¼½öïëmSÚ1H§bÖ/¯{xªñŒÉ6ª$>xvÅ"%ò;rñaZÉÒØ&,ÕUÅÒÃÅŸç½£	—©¤‘Rİ¨ƒHÊYYÑ‹Ğ°¬$ 	¯iÏ¨ê”ÏÇeß{ßÓ•–
øÜXA*C•iHmª>!Ír¯®´`ÈWñU‰šQdŒTÔ6¾ƒ÷œø—€1Ï0¶ky§€_ÛÙõáÅ˜BC‰es¯è3Ÿ$çIºâæÓ7‘6ÉºÀbx¯B3ºÇÔä<Q¨àå¢Šæ¾ŒÉ±‘ˆJNëå>P„÷#¡$–½ÚµW˜–hH4ú}Ä°B÷ŞT=#±”… åéÁàá†Õw€Äe’D`¡é—SàxB"dMg@JF<¯AÒÆ
“N’˜9A†w”Tópë¯D†$rÌ½C'šZEñg|û~õˆÂ–1Øşè—ãT`‚€Ç‹ˆó9ãÏĞ¹ÓÅÚû¦ ´…Ü2ZÎlğrTYÒÁ,ÚyY‰»ùÎI¤öæ‚ìGï<B8‡ª/2¶¿»ìÍ¿ì ¼]äáeË™våˆëãMÃlŒbšm³ŞezB“>ã±è&Õù”¨Ø¿ò7ĞõÔPÔ1ˆíÈkš¬™ĞË±„±T@P$Š«/6ÑLÉK/®Ú]¢rÛ–®êE”Á:ºO¯‡Ue÷T§Ã…^‹Û3V½úá…Ïû€RWj2¡Tü´fñ ËG<+i¬$¢Ì•Ù‚­W˜_)¹„hUp]sœíÒJÖ‘Ÿ£ÿD¬2P^RT¼@_¼„xŠÊx:y¥Üqp¢ŒLì´}ŒÒu© Qu>Üİ†…™Êgøe¥z[Ê´÷Œ¥®ÊÖe"Åmbwã©IËlÀ;ÍMÊ}€û86á˜>ÌwAçSäLª:ÛÓÀ&§70$˜H‰ìH¨<ÓCì†*êIÔ•gô~‰Ä2~»Àrë-/5ğ½”¾.{²îÌr.’º•äúyE´!º¡üñ¶üÌ´lÈÊcß½6-ÚG°ˆMŞîşC©8ÕÏJê”Õ¡[ê„®z3‡Jèè®]ƒ³ä'ä¥wšÊy'x÷ÓX{h2‰¿pj W	òÅ«©r\ÏÒf ‘3:I+Ú¤‚·Ã5ÄÛ‚ğ<ayR%Ìä.Å¼Í­6@ài\÷@WÙ‹¨5}ÍïW'cgZN-°G>“R<ø‰¯fZ®ænrñt)ÊÎ[² ãEÄªaÛá¡­xcx/öğul³Å@A©¼ ÂBózBïû‰BJLo‰Îê¬‡[>í…†¯¢m%Å£µp€¤½—KëÑ½Å2=ëEö™à+s”[ae³‘HW·UB¹v¢y±za»%ÇŒíq	YÃqd0)û\768p@zµfÃ€©A®ãÂÅŒù‹÷fL!Bh üœbêà9?öí'§D‡¨ŠÍ4Œk·"j5–îğâ‹Ôœ`iÎ)ZE•LË'ìäí*¦…h5(;ÆÃ3v
Ç¿Õ¡"Øõ‡.Ç¨%æQäH|üuİyh¤ªõ®MèLC“C¤ÒÓµå­„Áp7Oƒ©±ÃáÄx'Gç¤ğ™+&ÿÉÊkİÃò&’âS´½²%ûS¨·Ëú†É-üxJzˆy‹3´ğÒõê§œ¤ŒF¶Ìkäöpš§%ìˆöÆá/á—›Ú8…Ÿ$	Û	‡ÕQxÙpß›ï§rè/§*”<Râ®R…IL"‰T²3Yn‡òYqš×«
õ«rëk$$Ö
loWƒ~Ş†¬„Ü8/P™p{0À€…òÅ™ÂL‰Ô£CX¿‘İÛv—G!+1•{ºUŠŞ*+Ş!§vS§›°¶V#İ w=¤é¡àÌK¿óYo'vÃĞ€µËCeû×ó‰a“b‘O[nün”ñ½×Á(¶àè¸HíXJ
g×X_5NµgİÑnËrºÆ¾O’&yÅO.¥í%ú‚]æ ~-œù“(~!\é¥
‰ÈO›–{!‚YŠI€Ïvéi×æ¥·/; ñf§ı,!$<6÷´£\¶F%tá§ÀT;dË˜¥¯Áı­ÉüNÃ…Y^YƒN:|LRHÀ“m÷gÉy¿ı¬iO|º•ìUÇ8mt2˜ Js¿Xª¯jÔ6õ?Æ‹Mb¥C.Ò.eÿ:\›„˜oînÀÉ×c8WA.k¨zL4Q »‘öF^X*J#[÷PŞ4´÷¾EveıëLArU5£á«7¿à0¡Æš‡¢Aµ†Â[Q?Z­|a6&+=f†¬Â-’§ÈĞPİ¼ù¯ !û¨ i¡†h¡÷—r03“1$Ä±ÕñĞ‰ëTÈAòL²ğHğo›æIÚyasŸ†a[‹k¢
[¢N2€É>t€©¯Æ¦WF§BÓÅÒ¡;ÕëÅÃQÅ6£A¶%ÛÔè·‹ñÕéÊ‹íK¤¹;½‹[®y%46yı%uıå$y]‚ñ1Ó5tnº¶Qşÿiª†?aJM3‹gŸf°|Y6ÍÚ;Ó¢Àˆd°0 TzJù)K[Œ(p0„uÀ—¨}îS,Ÿš'³bäÔ!ğäq‹ÇÖpé9úÕ£.§Uv­6ı;ƒ ÿ¸„	R)¯êÄ‰&>Õ-;Tk‚)õştåwIë/êÒ˜Óšç…”_¡îüv G‘ÑBØì½Am‘=‰¹Jó#.oÃy5İ¥mÅ3dı/)HÀÚ^ï¥Ğ³¢<iï%wLÜyÍ0¬Tg=‘`ûA&N`rTÃqÕ"è%«.t û.NŠhKˆà =}kop?‡ˆ$$€ ƒs+Ä¡8z7éÛ}A„ÆŠ€à
Á+}»“¸È“Aß‹“¢©÷ûşş>ßê°j²ãaÚ\ü¨¤m¬ğºêÂ?ˆt8&¦¬˜2È5!İuœYk‰òƒŒ_®]çj¾_Ç S´êÚ/ lş„i%d÷JvMäÏš’›¼šíÏ¦8œşùî»¶ötE¦Òûè6M8ût¡\µ.¯'ÕUÚñ^M ÷¹“7ĞJâj›	jÔ­xw9¹ù¶jWa ²È6ƒ^VÖõ :[cmÓkÕÒ-:ÿÿ#Æ*Ñ3]
à¿fÁâ?‹#ÚZ˜Œ¾ÃâñÎÜ”­)óÈ91`7}ºæ¬O)ÓÉpNp>jª)bg„©•· †³®•Ô6=®·CwÊ¹ë™“Ta
ÄJ’y®`Á×Ø¯=œ=Y)û–ĞE¦\3ï©%GŸ÷/‰Ã¤æ¬­KùWå¡XQ%¬’Ó>8­mÖ¡Ë>ô8¬gI.¯¹™ƒO`¡—’VÛì¼YP^¬,' uW-¶ìÉ÷’«9´“Ğ'ˆì¸|‰õA·]åhq5>œ¹g·IÄfÈmO…G,š›~çŸCpÊP]ø1–Dr÷Ï§zë@ÜVâĞ[s@Ë‰¿.Qæz°ÁŒ0Hİ éğ¬z¡2¢­úíĞáß5ª`É~Š¥ õ•_å1wìâ/›üòP%
ù;)ôÿÀÊ{ËÉ·˜hbXßÓ[†+!©Š~©âüêÛmõójK…°lŸ?¶ü÷rºBªmA°†¹| ‚–WÏ™ª§«üä¯Ö1ÔŸów@(3ôM¥¢“Ÿ5ç‘Øªùôd¤„¯¬v3}3µ¹ÂİÓñ«RŞx©a+=>u)	[.—‰j[ tW0ÇL¥ï±Ã˜™:$å<Úûd*åNÃsL%c5DbîìÉˆpùo@u6×ùñÊˆ¡[Ğ»¸ŒŠ¢ Bj‘ø1§I¢‡ëøôy*æ-6œ¿|jÛÜã±PÓ=kGšµÆÜˆ—Ö–BÁ»îlK‚YChÈï›j7µÎ/³Ùáj=9 Aó7™lM¼78,í†Œ×o?ê°}¦=cŸıƒ¤E‚üIñaêÇÄ®ÕĞ­ğb;uö^d^ÃŞ91Åî… q2ö¾5ì«X7ËMÁlo!ºä¢ı×$Ú!G×ø,b74uÄ? pˆÄ²K,ˆç0_0UÁD(lHõº¡"ùp(ò¢^€ A'‡“NŞ}â‘¢O^U° ¿ÁğNš—ïÌö'ydp‹nÂHtFï×iÃ,Q‡_X!ªC1kkÚl°ÒÛ‰ô0ø×
»9Ajg¼Ú³¨‡áDÏEódÃçé¹ãíØ~¸@Q¢s@ğùãi'×¬bØ¹äµó±åÆû?U—‡HÌ=ÑYámãÕG'm@#µáag˜=_p&7šn¤}†yñ1ñ°Ş%õ«<°hA;b1üjg"K(¯ş­xß(Y6ª†¬°¼‡¸fÜëëÃÃ(¸şésn!$·F2Ê¾UŸ%zÂ,pÍBK~Ïëåf¡‡÷@JşšTîõnš±¿€É[H3¬°„n“3K°{Y œÂGƒ¼E™wÂ–£¶ÍC©äzø„Up}u‘Ñ «›£Ä¸²_¥Zêîô-ñ•ŞÈšşÚ>n7âÆeËK|Äû|PNvxo	´7í”Ìk£zC(2ğ×¯ úW:òe^X¥ö|¦uÇ7à–:VuìpB¸‚bÌÕVÌ	‡d…”b,¶Ã÷˜‹°=f 5ª›½„*ˆê×ú„c„‡X÷c™Í§Œ±˜®'ØxOÌ/ZJó‰ª›©°—ø‰øÈ§N÷+úÿÖş8ØÍs#‚HEÖë<_6XÓ±g†R‹Â!¼É^
J–NÅÊ¬–Îø\¼½¦rG£Òˆqİu»ãÕ'¶„ˆCÆ)wúˆ/ƒó‚½”&”ğØejRòU]l[S.ëşğc@omÕËeõë©Øç“d)íÜÁê%qøzv…~›;‹ë¿ L>u èHiºK, •ú™ŒÇ—¶ÑÖ±3h#á€	NŒu0´¡ŒÉ¥òÇ;şÇ=è#cùòİÃF0 ¾‚½)EU™…t×†“<„å¤•OÌ!Ğ—6€òiÓ*ª,Zım“L *Áµ&Æ>r—›‘¼Óæ\bW	§——4PSúG^NøÉ6q1W$Ò£nñ¢ùàBö¹Ùh€§-›íĞ“©ÇáĞ®~Ú_°åÁwª{Ù{HÅÆaÜÆ€è?ö,q÷¸HÇr+êU”éÀ¹69›E¬İ_#¼!+oE9¿<xí,àvş[{À/@§w—©:Ó«•¨hE®kX2CoŒâĞÓà.Rå]uÎÔ
Ö™%ä;§V,~8Ì€Àú@¸D7lOsïÌR¿rÓ2}úq‚R…¸yrñ˜4ù ˜[âş+^o“¦9rİö›‘Ğøı&µ,²Ôk9¼RQWŠ£^ß-9g>êŞ÷Ruıf,?RR,KxIÉlkå¬8œõÕ]ëÅëAx‘dÜGCÀâôöß³;äR‡&l|É¬X;Ö'/\ˆ‚ÃX(—WÏ!0xN2ÔDô½V<>ÜjZ}Y‹Ò§ ïõmÄJßÈ°õäé[%£æ•¾#í[æÎNí‹Ëòàg|ñaeÈ0Qt”Œœuéüª¹•pŸ—âtŒ27“¼Jç.Ó´•#9üùêÃIÌß,ˆ{ªj—*òv`³¬Îu"xó†UÌgãâw^ñ¥Ûò®„Êñı#eÑ<Õ°ËÂûqƒšÔ–%°+µs€ƒ-G­í%x dñ,e¸±™a5ùŸ?›)hóÒØsæÀŒ[&$ôÔÒ›?Û3ÎŞlL‡<s•fö–lzàù?öÁÆ:ş*„'üf§r­2I¿×®â‡ÍÆc›'¬F†nŠêĞNWòkrAgÍœº²w5‘ÀÂl¾­o"ã÷gE^ØiIlNœ-Œ(åNFı“¤ü2§ş{Oÿ¿ò5ë ÕƒË|c3X%Qf6ƒ[$ƒÏ¾,B
€@…ĞÜ‡V¾ù›üˆ3¸d›÷ O1Z±“ò•ÇÓ+åäÓÜ’*3–w²S¤0y	ĞOÀÉaS—Ô ´N?ä“…8¶^¬pPz´9€L¼"â(›mªÇé)Nf8µMT¨%NÁ¹|‡nzwÆJ]D•GåIıÔ	0Æ€z”®CtĞ×"îêPÛç$"›‚´9€ØW\‡©ïm–^`Po¡¥¯lìÓ& ÈÄê=L!?{ÜÎ„ë!LD9ÔòzO¶tÅJØÊ¢!ÌhÏÌÃ-¬†oì<ö?˜Óf¸
U^:Ì3bJT­Âe•¥ç—.êÕİŒjâ­ªãaD$Ú²^Æj4ê²ÇûïeëÑÉ|3{XµÅnˆaá8–š…ó®i¼¦X<²ëüÀf:árQzX -(E×\äÄ ¶Ç¼D&ü'Î6=ÊÁá¾GŒ£.J‰ÀCÕ7áUt»À–¹ü(9¹¤ñÑ¾˜î¤uÀ?©˜Ïr{ÿ6}­´buBÇã§ã@ó!^AsÜáÍÚ‘Ç<`ÛÑyÒy™ÆHáe´Vı/d*aÉPQûKïuß¤Û«G÷ÖwßƒSÕ«ÏŸTzˆ@B¬iº_:gX€Ì«“Õï­•ğMÿ\U¹¢Âœ©ü[2\ÿğb-à 3”:QÓ@ÙuûíÿŒ¾34pOáCn¿ÃñŸ”ÓĞÓAùÿÜ>íçtw¬ "ĞËşF_WnA˜/9L‹¦ Ó+ÅÀD^¿«ŞµÀ¦Kñ}ü¤ø& K¿µyÍ»~¥®PhBlØÃwâ0Ø)Q/8#•†ÓUVÃpñU ¬\’Q<GšÕGrí	-®:º}AŠ‹TP,Ó.5°ÂÛ±T­$HTí]n¸\ï‡(IÍ^·~\@#¸k–º¸VÜOÛq®Bh/8ö‹\•Çxb—$Yt3a´!-e/ı•Ë	÷4<ú¤ê¤êÈ (ÄTV~ÁÁhE-­A|S²ÑÔ"@êxôŒÉ„\2ÅÔLÃ.{JŒ¾œøÊà¢à&»½A¥Íš¯*ŠƒHÏQÛµ4±K1jÀv[í™KåØvÔGÈµXŒ¤Ø“¯ªş±k
ÚE.	úKq|ÂêV¬lqyŠ­ûlÂ—šÆÿş‰¢wF£úĞ©.Ôˆ£ ­n5¶™/|l+Má´™\/ÒúªøvÑŸïÓ^Š†I`7 Wá†UËÜo&Jy†ÎŠ]ïÁîæÇÅe$ëF‰:ÛJ†ŸL[ølaÄ¾=¨:q~ÄÉ¸£ìqİİ}S¿¿­ ÇŠÅvÔH=ä#ÄË’FTÓĞ°G÷åÔäˆ,“ğéoL~0‹JöW=e¼Úæ…D›ŸÁ2)¸}éü˜—M›ÜA™W]
×AXÂîMÕx%Z"_65Úÿz²Ïë /.­)NsÁÙ°
JXÅÇ§±øO2ú-F©V+²í‚üd¬RÄ`[J?ğ7ÂÕŒ¸’mH#Ø ¿cß %1§-ü†h)mƒßj<ÿà§ÆÕËÓ	°‡·ã“ĞGúRî%4F#Eˆ6BûŞjNCX„CÒ„`'5€B—¢‘ÿ¼CÀ¶·œ
JÇ…Õe¿hu›™úÃî³ ÖkæYÖOÕ\Í58‘£RËf6Á5MéàOçùîZo«Ïwïét†áJ£_®øš‹„ÓÖz.1pÆh$‚‘İñæ™ŞjIGˆõ1Ld¿ñû”¤7=@åÿH1—{îVûPÙ2Z¬>ş‹°P70¾|×É¥ú“«µ#æÖgÊ2Tk¤bÍ>ï¸)˜±ÀwÀpM9 †{ë!‹!ù)Ì_ÀaMRŒÅî`¯½ Ü“D,Z]Áyrk¹Yä’!¯Ÿ¸£Ğæœ]¢d—AĞD0Kù’TİéùÚ¿µc.QÈ»ÏæéT‡;Íëí3^f˜ùˆoÙ|Å×ŠÀ]'ÿŠ¦¬Sú— ã9¨¿ÚôŒ-b`€Û´=„#‚Å±= ‘÷èóØŞÊ¨.A1ÛÜ­İ FëáœöID	¥Y¼ñr6•"øÉÕÚé9`«@=ˆ!^Ü¼‰ğˆ²DîEÂ…¹cL$M‹±‘ÚÚ"”¡õ9ÛŞ|>iRÃŞw‰C<ßæ×Í€h+,bu‹E¦Gøõb·ä@Uù×`N©ğ1!>îx¢–K8/¬Ó¹¨²WÃš4á%ø1rµˆ•Úš§.ç„¾Bø£Kô]ßY•÷
­±áê‚=¦Cüİ·st_l¹3\oŠyYz~îÓ\ùhßÃmPÍpQÂ,”±,¯Ü@bØ™$“¸g¢$`h’!µùmø-Šyîí§{°\âÈJJËÍJ>.¯´IkYöåªoq­ÂjUè°ZiØ}v˜=Y©\çe<3S0[í–ËéÊp«Ü²‡5ÆÂO¤>µÇÛeØ¦\Ì¡}@äòæ¦Cçúÿ{Ë]ŒÓ¶şÏá²d»[şé’UaHD‚ˆxoÀŠãäÉªŸI=SóÛÇkÉ4yV¸b+u[Rº‹uöÅÛÙœEYÁ)—ÒÚšÜ[˜ÏDø¡9œèmÚ5zÎØ‘d!Òı…ê²R|Çx,5ƒ’D­ >^ä u+¼é°ŞS_W¤”>B<¥1á#¼ÃL[ÎË{‹S`’âQVp‘>ÁÜòß¾wc¡ËäaÑ ‘Z ±M(÷ÿúÖ ,}òï«E\ŠëåyáP’?šÌöè7Š¥ï#xçoèz¾Åép[SC#¢œû3ÙËÍÓNeÊ({j8ıÉ¢É˜0U¹ºc~ìıO¸(=Ø]ÁÀØ0Ëä%,ÈW¨T³XaK:µE=FÕV)fÓJ„'1™âá` !«ÑŞ'?Ğ((7³Ñ–“'jÊTq¡°°¹³4q†U’iÉ@Ä3 ¬,­­ià#6 6ş·D…“pŸ )®Fò¿¢´ìx{S^Di#ÂÃ¸«Óò–P%Ô9¨*Èİ¾_hWñš|ƒ¥c&Ş.I§ÌœôB}øj³=³:r°ŞÕ¨
Üì&‚Í?ƒd¤°&4qVw04¤/=YÖ&.óÙÿf æ^!ÿ|åt»ÊøŒÓCäµü_sãµ|êF‰Ò™àĞqºÂ”$ÛÀ,*áPÀd,¶ñÌö&ÇéÒä“[ÀvÜÎ§lõb•-MØ°˜?¢ªù¸W¦ÿ+Qø¹Ë~7òßy%¸*¸º›[:a%à4€ºM ¼£†Âó:ÿúşeqØ~KÂAğfC%@ÉìÎ¨µbøÌgväh,27¾îFÆ®ÿª½-6Âˆ*ğr)·¬$2&]“¬1î„¦ùı=j! B"Ax'¹ôµy³†ÈÑ½Lï?µ #cêãüÒyrĞN:	·äÂpXNêÔ.·Wf™²C%ğú4ª/?b%ÏAĞN·²~ióGğtˆk
B×‰‚•%ë£”Ğ*knØÿ¸—H×ãFU¡n${Ít‹sD ¾zr<—Wß­Ú¼J ˆ¶ÑÏw’q`Ãt8 jëéô;]ÜTg¾é¡<7w œ1šÉß´–Wğğ°UÀ-²s¼hŒŸvÉBÃOÙ‰htp	w0b¥—zLùİÂ9Û=ƒjšÕ®·V4. ğ“ä<¦*í{Õe±wÆã®šk~æ…*Í¨<ˆ*£Íèı"‰2á)ËKËT_Øhë×‹Ô”á n[cR(Îº¨äa‹}kS¥[w«¾F¶²ØˆâjÑzL@÷d—w¶ED?•–P5
Ô™Úïû8«1XÀ•´T/.$-H&Şò2Ázà;Ë‚º‡¢ş,g
"°DU\ºÏ:¿ÜT2øë¹ÉS‚««èDÅg^
l¶üQo„Ë£àÖÎôùĞOa
Íøƒ£d0Í[Ë
os®©Š‰Üx“Ç"Ğº(ïé\[ÉøO˜V’æ÷¢šô )Ç9$§6İuÙx~çõ®ı$ˆ´Ì?Ö¨‹ÿ²Úğ #mœ³ Á¼[hO—Å¿œgŸe›Í©‘Jô¤`ã7hÍƒìv )åhFmt…™Õm™Ô(â:ü=?u Ş4F2é(ÎªüÔë·ÁÍ6ĞlÃfa®kq8EwãÁâG[Vëİ„E Ç"'NG&v”ôQ´Qc‹ß47<‘1jEùÿiHğ¥DèrŞAH|¡>"á¤$L vâ+®…q­.­GI´«›ÀU^0A^d}DĞ™F;`Î¦D:½~Æ£gVšŸœiF—¨›‘E’Î±¥$î‰&ó/Ñ¤’2lÉõÁ >mŞg«ÿX/€nÕi
¥ØµÕiĞß€ÚèfI©ûÿ?v9€°5gZ»Xi¶ÀHÒ9Ï&¥K²Ô·-À ‚G²±®ùãÙ&ÙØ½›G}Âíò§†pNÉõPáh¡¯,¶ª€6®{ÎíN}£ÛÙ{‡“Ê©c@¼Í~pQÃ«s36€%şí}¯DÉ³K¤õ®{P|£¬=7½—Û‰h¬¦Ù–ŒÈ9ª­ ã¼ê˜îï<}Œ*´Œ/McE\
{§ıãÿßÕÔã_}±=à€t4M.kSú’("'ÁyÅŠ·ëƒÅ7Éâ¦=Ëô7-ÎÀ×wƒJ
¼l<—Ëx¢1¯²ÙÄ³tÙPa©ğºîMJıÇ5íÉˆòP¿îÏÙ‚û¶´@ˆ
>é¢'26§êsæô]ªæş­H3ı©ó÷o<ñ™†V ÈI>T€šk¦™âÄ|h B5¬0¶¢ı”É€Ùiö2
’\p÷ÍWHzáxuât'y)ÿ€!<îi'¡ñ2£3‚²õé©a”İäj´¶0[oyóßeışº/Å4·Lã–PUğîgÈ%ÖÙ¨VvÎ{Šx»­kç½1™%i*9i˜®†ñ*&eL¯È7£ƒ¿§"“tçŞ;9ùJèfjVTÒ–xwÒ*eõ¹›xÈ|ÜØé7ä‹Åùüo¦oiîˆYî‘ŞY4-8k¤Š*Nv¨PqÈ¦¿”ÊÜÿ…µ'ª“™Öıë­$èÌÙYC[ã4!×™ğ¶~x‚‰Ì"`^ã=“p²Œ:ëZ/ùKîi‚¾sŒ‰‰\ŞpYIê4§í¢¡Œ']¨E´9uBîØÚRÏ³'íBM	?I²yˆÕ×qÊ~/|>‰u¤±˜_ØôñöWÔ¦œQ²¢eUC}éå<œö-ó¤qñdŠË.şB1'‚*EñI~ôœß™E¡bg[Q›©Ñ iÉ‡R]Æ¨KÜ›…ûµ´/=Ûï!Ál>Ç6é‰<1É™"¦` 5mÌĞ(Ø·y8Äû
ßØ(ƒ%UŸÇÀ”I—kUÙL[Çdº!Wşú3wƒVrÒ+òkÛçÓ]Tï§È´Lƒƒšò2˜„Æ©1!U>ù Ddc$]Ù½â6<€5³wâÜ@ÿù¶•K1ùò´»±ó/‡[Dº;GcèÑ`ÂHIñË;xuDŸû[DHÏ«ø]}eÚ?˜í$¤µWÓ0ğß£ÿ&½ˆÿå«8éÃÇSSáWx“ µùôeç’ ´·ßÎ)r¿bÒc´±a­f<oOÁ(ôA—ê‚ù·0 İ;‡òhdn"q0›ç»³+÷¨»ÜY•¤•08Âe’”ZY§ky Vöí.^ù©cş¿À}¢ÑÁ
œ|Öí}] öP®mÿR1×¸~cöRÌ¿oŸ~ªg—îc¸m šQôşvzÎİ·šÀïE;‰Îv ˜ÔGşÃİwTU[¾(³HM2’nzáÙqÎlÎ”ÔcÏŒµ¿1Öúæ¬ÍÉ~N’µ)%ºé¹Û3C‚º¢ÇĞØf`)i|Ø»Ÿ`xpúÒ4Tı02«x_ôkNS0øQ›ÕÃéÎ…å·‡"ˆWã'ÚÍ8–ğ©~¸ÈšO_üfxo;ã£~šë·;F5ï]<QßöGdËİMŒçCr£àAŸQÅjn­‰H&¯ãtLóÕ7À8ø£LŒ†lV#›çaNV¤xÜG;jd¦uù#’.#¶—»÷`6½
[ÖÍÏGİ0#aèÉ÷­P‘ŸnãJ‡dMDUˆõBQ&£h÷Ë|ÍÖøœ)#Ì‘w+RÂÍÓ½¤óZgC]ÜÑez>‰å]íxğôâì™‰D&ıÑ[t–Œ®$;ëaUf}è\ƒ:×_zf<1ú¾{<ŠyÖãW÷ëñËêâÖŸÛm7¦}ÀCz©2'ıˆÉ×œÙázğG‰;èÿNÉ©;‘…uŸó—í›û£vÖ¥wçİ[ïúÕ·•¡3^0¶×ÑM¸½¯í¿¢˜ÿ=\íŸßT¹9şz°ØLİoÈ<ewu2ócÛ\GS~Otİ²±ñBè7T@ë¹åîš)ïàqğvüêòµ³ê•¢;‚ê#´CéK[¶BÍ„ÔiS2 ë-Ù¬ıÍ…ZQ–„ÃÙp‘İö\éİÃ1{[3³¦§ìvÄ‰¤C…ôëª˜$ä°‰¦0X°§÷›1Í/øº'«¡ƒ¼^Q"RPıƒÕÔ#~MgmACºÄw–Sz1îVmT1ëàOiÎò›¶ß=jŒƒØì”Ëû– Ë‰ıWnû¸!àXŞTrêLp%,@
!…¨k( *ı©R9†»ËåŞ£ã‰Å‘ÙhæÓsã¤~"À¡ö:‘ /®&ŞFK_ßyÜ§œ·Ğ„i[c­ˆG"(†Ò1İ;Çe4î?ÉJÔ¤Ğ¼¨e^ù!fÓˆùdÙÑ“ıÕ¶	ÕÆÆNÁì-Ê´“¬êM—ˆ'«t\%KoÖ ²Ä×Š	½L’‚Ñb¸¢R2@˜9=ì1D'¯è?.†Wa¼qÔmÁ­ËævxüÎ¤´˜áñUªS±–ºÀOÛ#ğÓÊ‰H"Ô(,ŞU0²PØŸ´RLOŸe"Vn?^™Ï|%xŞ~Ø^O£á´î	:r ß`sÓ£TÆ:já:s>6ÍêJ „{›ª®Í`íËu4òÛ8j/Œãº«íí¬EÔËõOi­°à0İ_Û)’+åÈ£¡,¾ïÑ—µç@6t}=äD6	o£êd8QûÁŠüu?Kµ3fäç;o0Á39ô¾C‹cQ0u+÷eK²•Ü	l™o#ø6¿/–V/ìÈSÄ9ÖJqî÷„_Y&éCÉâeĞŞJğÌí±RÅT˜Å`±µ¶h?Ò§†¤(‡._›6GºµeÚ+€Áê¼şê*ç=6ÒJN$múH¾¨s»ğR…ª[Aü¦PŠ•!¼0B½=
®'Â‰(czã_l«ÃöÔ¢y³:0`-ÕÃkiLO5R×95×ğû$ğ‹›@¸T¨g¾:C.¼âKaÊ©LÈ—n;êÁ¿ºEJË³7
|Šİ{ê4²Ì#ßàƒøaõ¢„šÜ®G§ƒ+ÔŒ.†3 ÕñgéåWûİÚK,:µêG ®8€[û)Œ#)ØCX?éËm)¸™¨G¶v/Ş›–ïc-^¶VÓ#;¨şDšMèZIÓ&lìŸ2óÅùšâ‹º‚YÑ”3ªÙûÀY¬ú°¿¬x*pLï7QQÇ~;ë5~Qf¿oS¢H=zÿŒç|)ÿòfOiÂŞAëïöJz â…[›†?œş//îÏ4á¤¶b1¢ûÇîªJ“#â,#nˆ=xt6Kªÿ_kïtfƒ³XªËz¢¸¯ù &E”^
áíV¦J^.oªÉ²Š¡¢şmmË2âVÕÂ²ó\âBà¬§oAöÿ¡ùº‹Ëö-Ÿ´ÿ¬Îô{"”ıÿòyLïÀ#¨4Rñ$Š-,²,I´o/tv»ğ&ø®Õé"1³‚øU½‹l®"¢>[å-$×'¿ËîÃ}? ×öh” ç]d˜Ÿço|&İ5Öªuò›]„Ê¬ÀÌiÁ™If?Q'SÈ#Àt‘{dÊ!±–·Í`3,|§PX÷ªc÷*n6¿;æbĞİ‚ÑX­YÓìR†±ğg•£á×lªyCĞ¹Hs÷C/TÌ yFcÁJUt0Hì4^LÚw¡OÌÕóYÏŒ“Åá©§Wn?94HøŒõ6ñ=
JÚµØŒ3pğòÚÚÖÄ»İş z„nw²l–¸nÉ†‘ÿx=J¹üJ·’Ş¯]Î5?èõĞ4ylˆœÈe–ïuÖïÍŒøøÂtDT
7üx8^Œ«&Ï|ğ^7C
XÖÍ÷{§œ@3âL™SŞjU…CHtşËÒ–¥êP=Å<+Àæ¸—•Jf„/şı‘›¢¥œ§èûäûERÇl¾»•B!ZlŒŠ$‰qÛBòæ[7Vıìı}Ï'îŠ]ç9Ï9¹	ÙJPƒslVÛ²«ä€méİÆbVÎÇUÜhÑ”­Qı¹ˆû£ekuı‘ér]PX6w<İË®ÀH¼´µ–¹ğ16Äœµpx´t<<ˆZT"a?8æ2áÃû3$S$x„®†¤mW6åÕ5‚jƒ7àåwœàºr†ÿ<‡?NÂ” ÷’ZwP3ßjá8‰É,k¼>ğ--AA´>1şfÊC‡y‚§ØÆä«é”;àØoUÓ.ŞD°@9{1tÕ&xÛ8ĞÛÂ<¼Ët
üYçwlRsÈ>¼(YCĞ?÷ì&í«¤Ê¸–m²*+¸]D»ÓzRˆµƒĞ­¢O’—]·ÁB~şšIñ:âÔ;=÷ëª¨BÒäÍƒÀß&ˆH.á¼è¯Gá.€ã×IÜªÛc:¢Êÿğ™Ø•X¹áLêM;6/ âSt¸Ÿj¥A)[~oƒõwµşT@Ô‰~«Ğ|Oâ&…eY…ReS:(>zXz`Ü´/¸OÛ@› ¬–Ñ‰’w­ÂyŒ?Ñ¾SäÖ¯e'úhÓĞß ¬8]Ó"ˆ‰¯(.ôè,õ|İĞ!œë9°k»È£2©qP»Ø¼JGœYLóX·›ÌNê¶fF¨À}ÀÇu@§ûÚò‡´z&§»M
Æ6KJM2ÉîÜk³méaªdLC^ÜxsY¯ë$oª~×xp3¼+Ğ“–Ê¢T¦e¹ÄÛúğ*eœÀd¦C•˜¨kñ{ÖÄOEÑivœ0ÜÈÀÙíCäM”n
­íúÂ«Ğ³H4c~,-é¶qÃ2I¶[È+Ãd9w	}ö!v6’‘Mø4äó+ÿÂ+5ê“„òÚtÂ¾”¡vşYßò¢«¿où•$(. œ^¨nÜ;fœ^ QÉn†şë¥5n9Òª‹Ô¯2¤£E‹¹Å£ŠpÃd+ÛeêÄU»Ğé7Öi÷ +İGÄg9y“f8ı
'&rRİKÁàLRmXòvBö
f–Qx Ï'(öŒï¿CêfªãR( 0$ï–™Ü€ó|‹]ìâ6½÷3˜nO[¤abÎí·Ußoo-¹&ÏÛ5/yˆ[Œ  >â—3Æ«\"s,%’â@½w„^·éFRg½“£3#)¡³ˆ^tûÖîà,Š<mÚÖ[Ú>QğçÙm­ Wİà@ÕãTˆ8S€½´ß¦pn<©ò„¯˜Ub±“ÅŞèĞ*ºD^+fh~4HƒÏh}†‚»ó¤M\§ét4œ^”F=µ:®Ÿk?P‚/šÏB}÷mß“?ûoÅ‚=i¹ñecm" DA‡ ü"MkÕƒ´GEÍ\ß×œÌÄpyyhpÄkc)ËëE‡;ªæ“U5ì¸ÙdŸÌ˜¥6éĞÒÕ!dÊC5>aëv;Œ“Ç~œ½GÏb]œ*U>$ÚFú‡¹÷-<ÇSO".û¨ëõ0/å*ß¢ÿÖİgë±µPŞ·W‰xú	y×¸d¦WZRép¡dmc´õ/Ä÷@a4IÙ}=Tf:Û…¸[T	f¥îÏ6<}4^b\úD,œàZzö?ê`ria|’¯¡îµ„NÙ	¿ŠÄkÚ§dzü-–¯<ªÏh} ¢9¢;Àähß©†¶èT]#ŞËÀæ§h‡K¼¶H/ŠŒ9¦/z­ĞæTğŞV­wŞœflØ$şíûzuı;¹ÖşÒE°|Œ]K¹;UÎÜnîZÎÛ×Ö}GO˜>âwXÑ\Û°£Vÿì+FéLäÓ†~b…Q;O«1¼¼PzÇÌÍ"cW³Ì96ä"3´/UpŸê¸S9{	õ`²†*HQª$~Qò×¼J‹Gs»Nä·V•tÌ‹5íœàú†ÍyÃ£¿û(eŠ÷€9‘MÓ)lV%›­`Ò±XJ.Tmz–fa3¤&)cV³Fé]Œ'À·ü÷Û‰OhsÖ{gck?àCÚ§Õ¯x0Öşt”šzµlÌŒ¶$ØwßŠâ¡	z'k·CXGDMGEwèıxÃeôÒã}xf	Ğş
†<¯«9ˆö%ªü¾ö¤ûIVœ‰\÷Ï"ÚO¯k©(D0ÆÔÜW¤öëc€ê¬º(ùbDv¥¢AO~3ÄOñÏMÙ9	ªRÒ”ÏNå^’ĞÔ!î8ò=¯/É‰æ®y‘:9z"{§3¿;¡7œ HtŞk¡o¢•Ş‡6RZ»P—ƒ3›_øA¸AÊk÷ğµtá+™ƒƒ)Ê›”H`õÀ¶İb,+çõ*D5míe+ï·Ñ®Öº1ƒıUff7öwÑ¼	o|ã‡—ÁÌ¨Y¡TÚaÉÖq;ED[Ø:1ÙŒÁÔo4¢5ÆÒTQM«N†ª‰,›_,÷!ë¥cõ:÷ä(ÏU2St¸“÷Ïwwwä'’¤˜?ß0„æMö‚_¦Œ(;Quä@koo\êv¹zm™†Õ`µaeä´(Í¸2«ÒXš%ÛYPsÌÆ‡ñtùC¦á#İk	;ÂûO¿Ë?Â".=æW¼Ë—7œã_eAÛªlécïÎK¢İ$»Üğl’4´‰à+÷eÓÑaƒw/YC¬ÓKÄ*­“9 'rz],îJµêµ;³jô–FçnÂ5…OikXÎI%FådÄÂ¶›5¤pèÔœ•û‰½¶~Ös	
×vıSòÆÏÙ†«ÌqÀB’¯óeVIÉ6–š`{nšÒ±çgŒ0€9À…Û(¬=qŒ+V>DŞ£ZÏ22!`µ¾ª¥©´ó`îÙş™<õç@FÒ,3î€/ø®óÛ÷ŸÁ@Ãq·KjÆç-ĞênhÌÈ#®AJnd§˜ÍsÍiàõõ6ØŒÊ#»x&QÙ“Â³V DßÚÅèVjp,–^D¾doänµHo}nÎm…(3@Ãp²Õİ	ÁŸ¤Òj©µë­Æ”v»*°Ë0g¬áœ¼gè­çfÍæ¿eœ±×8úŞ£çEË¡§Å¦É¾,tRN²1„_üQÖ ×;>TEx¢ºÒEÏZ›{×%dW˜s“+ ’„—z+–¡Å@¸.ƒØÈ€Ñ–€¶ú°ixl^¿1{]Éq†F[ç¸y8HYCĞ¢3cJ³B„e™=RuÜ0æ#°n#£Kğƒº8ª“Ü0.YÊH<O³°rÌ0nHa-\^$%#œ/0…ÎæHñ-®ä¡¦ÈcNàIN 4y6jgú"ì±—` ÉÎAÏ›°¦Ğç¾ªâWjxTë÷D&«×BpU{¬w7Á’ÁÍ¤=æØœw-¼Ô¤Q›š|:âÁñw)‰XÇY•9ìdÈ7^÷¸§5‚Ê< ïF^Ìó&	“¼[Gä.T¤Ÿ9×ï^b$JÖØæ+\©9ïê@éñç¸Iºá6ó°ßKåÅ_*¾räÏšĞèHf¡} 	ÒÕ˜ëkk·â1
_Ô¯…âdg#;ùcß•?ï$b·pà ¢Úˆ/£
¿1‚§M‘nÒ¦™Øi‘¼qmD.›™ïl9œyˆ}G´éÖ"‚šqvÔì#Ø?4OmÃÄb˜” ¹Åäßñ’~ˆ’ÄÅŞU“ón‰²Úz÷0°ái¯G~`ÈoxÀ ´$›ÙôŠ(ïŒ&nTFY`8i£³1Ş˜Nµ¾5o	¦ÊV§èS¬V*øv¡"—6”é½µ dxT²¤î	s}ÌëË€gÊhwÁúzÿc¼:g$<ÔÀÚk+1Á	İ/yÓV^L¯$åöRÆÃ7£Ééë¬º±e®S£¦Ë7Òt<wÑak7„YdÓÑçêf<ÚªÂÔ¤ıLøk;T¿y	S¹Èlo#@Â˜I.p Æsy>¾	™íÀ£Ø >1ßqœ|o ÿQ#Q›­{ôéŠ)^—û÷÷÷ ÛZ»õ8¸cÔœ`¶ÛP÷ñ:`uğ$sİ™ú¹	õó-Z› q‹Ã5¯aÿ/u"Îe >ajLÅ:¢Ô™óÅD0½±ĞÉkd:tíJ’;¹áœ:oã‰¶úw¢`³|~)ésdèr.Q7WwÿÖP;”VzoÃI#ÁU¹üM™ë-ÎÑSZ=KD-zŸWM…p#ÃäÂİ,>ÇÈÜ;RË&1sÆ¡9w#@K è´Ó¹ëËp•hx_—Ïj—4 OQÁ«„4Îj¦ßë¦–8”=Şn:ÇÒ»`ÖnÿGI_O(Š/<û""7 mJÎaOÓµì=<Xj8f|Ï ¦¦¤À›h»/ÿÓÖ£x}us>§6Ğ$¶vß3Ô/~*4†BLFwÜ•îD|Æ0d@ŸÑÒ	È×l—ZxÙ¶(¾Ik7ªáñ¡+Ì0íl80,¶zĞAdIB5Ö»#Ç…ä§D8± y÷Ä&C	–zğ6TCë/y®U•—£å^Ñ
°Ô[³·,¨¿ŞjW‡’éMôP?²ÏH3q!00Ñ„@&ì)~øìk¹øıİDMÂÄŒğùà+G”¥ÊÉJğR–Ô˜İ…İKëåiWü¼–šİUên—7Û¤©¡Ç¦ŒŠı•:²­³D¬8F³ï­¤!€kêît²Ö”ºšnÎşhÑcœ&íï6B ]MM ¯È§æ³“Ñ6éZwWUí©h	ÔgŸÁ Ï–Ğı ,îRÜ §¨w7‡,‰‡UØSMgTF‡ı|å.òÜÈ~ÿ(J~u½íûèÓß±¯³œKë \{¸¤ªáÊV˜z$ŠæuÖçòîÒµÆÿ%eŞÒ‡„gEGùùÇÍ}Óíì¿Šcøì5”…st9÷n¦WL¡Åg0"÷kL¸–§ØàªşÉÈÏAgªd	q•²#Ñ5¢^¼îw,Õø¸
£ÅTéA·ÆË^ç‡µ„§Ğ)eµ8F³Ü
şiÍñğuG1²_“‡ßÃ(YûMóÅxD#¬‹\  ·á!$…‚ „¶€À¯AäÕ±Ägû    YZ