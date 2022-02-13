#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2626248635"
MD5="3486e6a54d9680f221543faf9d811961"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26580"
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
	echo Date of packaging: Sun Feb 13 02:15:34 -03 2022
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
ı7zXZ  æÖ´F !   ÏXÌâÿg’] ¼}•À1Dd]‡Á›PætİDø‹§ˆCógå'®èç38ÁÿkŠ•ÈZ©rÉ7f•8üI³ªÂ	“İõÈ÷Bb öí“.NısìOÃ^¼ˆòèÀ¯j>£h_€%FÀ=^@ùîMÀâË˜ÖOKæQÄ=O…˜«!£E+×à óºs;‘‰gÊŞÙ¨ ! !·Šmš†º¶Æv!õï"G)Ã¯iac\>ß‘Ø@ÓJ‹Í¼½ÍAA7ÙvN'&ro|sà‘Âq‚GLş5µ‰¬‚M.Øs¿?#nq'»­÷q¿ğus9Q¯ÊÖœÉn0&•¬e×(»>¸ıH¿$/[MØ‹ú3‡Ş(wM'¦&€á“Ä]Y4A·7œíŞ9QyT_8€ÆøÆQQäŞEÍ”@°"mmÊ‰cqn9.|îêµ(Èy£øÇ\Óji^¤7HÃ§uï,f©ÙA"Ñ~WÒg±“pOm×m˜¯lïï¼ÖZîÒK–cYWiÚ_õ:.5
Qæ‰<OÙ«­İ”.ßÆ0¹Øíİœæ÷pz´>dij³È'ÙóÊÒb=«æ™+×ÑWãö¡\=ğ7UU}â—Kr2Ö/C¾¤‘İç`¦‡cìS	Yôu¢ ™–ò+é1MäÅŸÁù“È¥îé7•´ÚTæú7¨Õ6÷•sTæ­f%Íò@¶¿ãĞã²ß¹ìè>‚†o®­X_í³5z:VBà8<¼şa<½¡gV0((pîôÅºşœH<¾ï9Ã7szÍÁóö¿.í¦FºãD?İÍå£~;U5F˜"pÀ{¬ã;ã­­5st)ÅáAJóC`yd€”íM×µY}´ÙÏìFk6ˆÃ‡8UN	§)„ÇªG{ÕéòçŸ«R5¾³„0Ñ‹¡viôÔtå°dl©Ä½J-ÙXxl=éÕ ’xû„–m‡§.7
®ş-;Šª‚Ôj L}TÔfà‡B/Â'MuH>—ÀÎÊön-#X=:ñ
Ièó‘ğÔ¿˜2†2˜ikŒˆ5]_+ÛáyºÏìĞ¶›²:}eßè‚ˆQ¢¯¨şşù}k9%i+°poyoƒ²ÎÑı‹YÍNÖvÖgWıE_¢anÍªBõÿúâÒF†(ŒŸêa‹K²Ëßd¸ò‹šüC¬!ïQ¾Œ½å¶9£<¿¹³¼e3·l&¯ˆÃ–Ìùs„ÿwHîVcbÌbë9	„ÛY®zM…çĞ†T‹©š‡)X«åÎÌç¦Õ[š;ãsKÈ”Òı¥œc€BKÅ„®5¶4H³ƒòV§ÿj„+`Ù¥Vô9P½
cgÄU°‹ÈîÉ“ızõ+Ùu‘+èâ€K²QÊ4ÈjzÑÀS¹Ên	º±‘İšşíÏşpùŠ&8’Â:ç/ıŠ¯,Î¤|ñVÉ˜Š¨èü"Xv+4zMd.=¨> ÑKº–¶
°nÁ›•B‹#†Ú«]	A¤ñ€œ†òÂ++@dwÜ%õF6dÅâZ:?¶ÿïÔêé†R"­	û{V’ Á±¤;8Dw» ³*3zŸı“Ù›?ÜÏêª#]sOWßÁú÷oŠ7'Ê£-7½?gÓ,÷îåëL£¥Òö8ü¯!Ub4=¼¼Êl—I<$bg@9†Š3¬È’DMò/8348É|ï²hÖÒûßk·rŞd	†ĞtûĞ®r“©g—+H 8yQ|‡Û’"[¸Qx…ÖêÊ;PnÂvqfĞ‹×UWåß×c( ,S[õziUçIø*Åë'â,'wü€â9¯ éöÔ#µàßÅì§@s—¶ØØ;ù¼D¼…¶ş˜›øîØ¶i©l¦º=çW’Ÿ(5õé—Ë3Lf½Y¹S€9¤3÷æ‹±»¬:°ít’àÖ{B65|£òø^½‡CpİÍŠ ¯0NC†Ú+YàO.Óœù\"/vŸóêyŒkiµ:ïÇ“YL~9™D	ì99Û|–DÕt’·Ò=z£÷ßk°-€í4]6ÉQmCqß.İİGp¿d0İxòT*@ê_*¨€ŞSâ¨ r&Í
²~è*:}{¶«G¸z~ºèay¹wÙ±åÑ´ï²›¶H;ÿ8­şrSh»©¿M2)¢Eøô8=ıñZ+Z'Ãâ*1ÕÀP0}½òÆhâ¿hZ½gA(-rãÙlù÷£B¨ó
[‹÷W%}Uû@ÍMâ7ÜezO}©'œ‚õòîÀ#J±VÄö:ä!õ'±5ØW£"‹çÍ¢L7®€qŒ‚/8%
³u¯l×OzŠ$Ö9›€9¢M!ÀôòZá&éÚ8Æe'i¶,Ùkäğ;rçÀÙà¼Ï,ŞÊğ7%Ì%\<ÍX——o¡
ƒşV‚ğûl1x[—v<¥RƒäJ7°æ)´êâäÓ¯	ß«ß%ÍŞÓŒH¹YŒZßG±d?Oùæ^™W‹’j««â–9fş­yŞµõ5¼$K\‚×GŒ…LY™è¹Y=6†êçJ§ºY³OÎÙõ~S·n«ÓIìÎÃH+Dí5·ƒë_Ö{ôZ(!æ>6Dù&9Bû$¼ˆÖ©µhÒ€ ı’¬ÜKİıª®F¾U¨<¸¹àwueWü³šxñHƒoôaÄtb"RÕØÄsRƒ$Un›ìØ2m Y¡ó22Ná^Ò‡«º¡æsÿóN+x 
ÍD-ÿ…8B—‡™@r¶–†âÚ(ÈÅfÌYÆ‘Cöb,WX}íùğüŞÎªß8‘—-	æ­®âL|EbHÆ9¥COçŠ—mÅ®ã¡ßdDíd¹Ø,fhí‹İK6"ID7‡‘2ËAie¡@q¤—#u¾¡|6méê.ÏZùÏ5Yá†ıòŒ`ûe—dJX½bí¥O^.Ê‡ş¥Ï°?)w#Ûæ£ØˆV?˜4ñ)Ãpª|Íjè=¯¿WãFÿZDNÁ¯‡£á?êÛXW`tˆF;ÛÂŠ·Ú‘9Ì80Ñ¥y+OÒÃ€<0…7hÒàN£lŞ3Îæ,YdÌ# ñ“š”»Êe‹N3 Ö5ùyl–|‘ò§ï-@Ç{Ñàˆ®ş¡ŸúVİia¬6¬£¸SVÙØ¸ƒ«œ3Kzò¢(Ù,€qùÀÅÊéŸçõäEÆnÁÎN¢/({fM„n¼ÿÁÔœ¶ÚWj
§£5–˜W;üZË:4F†r[@³|›²¹Â=¹ƒ%áFQ’×tü)W5óW·©STªÒ¸i» Ç>Vã‘àª:k1]AusÏM¶Tß°5Šôn{šFŸßD¸×Ø(Î/¯árúşõ†*:>\,ÖSÊ‚/]n\şÜ/UbBN¥Bãéc>î_¿åÇáñoørîÌÆTÃo–Cíäì¥„oÆ$„ùhÑ3ù›d–Ëe	iá^q~¡ûàB<çÂÕ ¾Í±ËyœñöšõDUGìÕÚ ³†ÁêĞs²>´<êÚdÓ“¥]‘$c8â‚¯¸çğu¥¡º7@•¢“ E¬—«p›ùú±{ô}C]èIÄ‚L_ï©Ô­=iÕ„eÿkø0-ß¦-#ÿ³ZnaÖ.‰ó ~XK§Ùãˆwú–µ¯¸}«}£jöÚOéu®®ß1ğÊ`‚¢=\x©Ä¥F¹Ö¿Êpn‹r{ñÙ‡@¯£Ó«GË¸^UØ¸YÚÏ³ñÙ¦R›7¡Å7‰33F‘?·™VñãÿÜ®Ü³´L8=éÖ,yÇ£KçÏ+?”l‹UòM-Cu·6Ó†ä«<ÆZa<ï0ñë=gR­ÖvNè8“¹‚&,nNtô&<ğ²¾
}û©«÷ïğíjaİ	Ã
aT¸yïÜ·œ+ış§s‘Ñ>qTÌRhH7SŸrî³ÍÕ0ë	)¾Se!"ËÎG£œñh©ÄÜş}J YmiŠŒ³²t?ùcw‚b,",©s¬q¨ï}Ú<öoE	læ¿…ˆ5‰yã¶ªÁQıä†Äş~»k mI¬”MKÛq”Ì&•€e WCå:5Jğ@$fg¥Ç ^æÆxP£¢BäFÔêà—ºê3³#§p¡·ŠîâÙZü^Œ®²xwXM >Ó}º· QúEÿƒsŸùÿUZ'¥ê¤PÑLGMğ3ï+.·†P<àºÿjòÊ)h‰ÒÇ²")Õk Şâ÷÷ÈT›âØ0ûY½¢²F÷Ê‡ß®*ßã=ãZÔw‰™á_é”ÖºP'üd1a-”îËŸã¤!"N/LÓhçà4¬c/ØÀ«=!$©ø$õŸ¸ß¹½è‹´Ûî¶àçZdãÕ¿p|¾„x¯Œ‡öa||6Q¹vowi‰‘¬¾}á’kÊ*i$öœ/Z¬.w9È€„É"éÅRWÊù†0Áˆ¨bN0Š¦ß.¯vüs¯µì|CØ^Ñ„!É#¯EŞ>Ú‡º,ĞÄ)äÅ½ÊVfÊ¦­¸sÈuŠv¶IGÕ½Å°íÂ nä½¾VóŞ^	•wÆcuğo°9Iw½[ˆ/ UŠ½ƒ•c_Ë§ÜŞ8YT^ğßee ëY£—§'²zt(M+l€}gİm{!£‘(ç'«éÉúíÜG‹²›Í[“®WF·HtÚh&¥¢ÏÏ4†§WÛÆÃNëTÇ2ÿû'ø(}Ä€×»Ú_¶c]İ.s‚w›:T‘ÖP@¶ú’Ì”Q:§p¡wÑ¢"#†»ã^éÉëRÜ“ßïõQ¹ xË‚­é„b†hq8d:_Ó?)÷D<¬nº=–„E>>úpX¬áV¬sñ¨«‹uĞ•ß¥ÖÁğNşiAóxäMã@RTGDPÎ“6ŒtÜÃûšrA‚rCÄKùÙGÀªú¢ÁÖ¸;Û˜Ÿ ­hã!,#CVªx&…-ŠÕ'c1KµD_Ã±9>ÓtÜ<Uæ!îãÔ€¨=Æ7q?>¢ám>ª¿Ó	$;L¤ÅDoc=Ã‚u% Å\D ŞÙaPbÚeAu9¬¥gÁŞÌ©ù	ÚÌ°ı°…šnñˆñŠR½‹7í7ıÌ«%CB’¦ºjÄ¸r¦Üğò3åcÔ®‰I÷Ä1aËÇJíÉ½×9«8\hëReœ@ßIlßcKh6íó¢¶ŞO<XÍÎ@-å6¤63=lPâå‘)Üÿ\¿f ãUáeä1²D$ãCñØ­¢Î¨o¡5eSïHìâáÓ€ZZ—ÃPj“ÂUOĞø«Æ‡¤&5ïÑ{8UÅÓ¤İ–º|ŠAj¼¯·ãËl›á0%ÉÓÉr¥FÉò¶CƒÒNBHÀ÷ü3ìç¢İP0f»c,è§Œ3‘ktGüı,•DÊx;ÂÊŒ= JŠhşN2¯O+÷2¨ˆ/Ù™[hy$Ş„|ÊH®”¹'-í9"Ò5¯c¿¾$~Œ•ßkÊÑ—ÅH€…
¾Úû1}añ.°ÊPFï'FdÜ<VŞ–Moï,NqËmÑ‡’¤!–NªLæ½ñîO }ØœfQO|Àm¶¼.°@x÷ëËKoj—œçXnOâ¹­ûÏPı$jÖVƒŸ— «ø_9·ÄŞ
ÚŒSß@Bºæ±w}²ÏéÆWÓŞXÿÔî8‰øZ÷l·%ú5µ¬§‘º„z:!§z?J†Nù•ú.&ïïŠúú×ÂÖjÕ›µ±¥èÏn[’{Y?!„µ5µÏà¥™__–\rK*%¢%):÷Ïj¬®Z À³ä¢3%¨j3‰±r  ú:’"¼İ\şF~°Y&K{‘Ÿö_.Æ:,é6Õ­‰0´.“*õ†;°VA¿˜UX	NzP«¶ğ´˜\š—òø˜SÅú¡Õp: ãpKêğÑoµ%á‰¶_'Jı\Wš6Äe zdå¾aAÿ'Ñ)ì¥ÓÍ<ÌŒÂjC„Œï@K:DóÈe†½ü“qËøôÛªˆÏtèÔzÁöÇº±õÇô2<:1G2åe/•†cÙ·¤G®Œ³¾{>ÁhîÍodş
‘ûš*$
eô¼Zõñâ.;FRëR×w‡OW-wäï´m™Í8GÎÉ“Të}é° XÙ	!q²ÌçÁí¡l­5XÀ9Ô‹"+~Ïá 1Š:™>È“è«1mÁ·ÙÚªÙ‰Î‘‰¤|U±ÿƒ®kƒŒt;-KLÅŞF*Ä6ãù£SÉ¢šSñq¡ûd*‹mšZqF'!—ZEç±¶ªx t‰ëŠ1ÑÌÙ'4)fä©µä}úç…²æÑ2m/CQ4;f:yk‡F³¦}mÚı f_	T/£Ò«gƒÆ³Š3G3eÈ¦"j„ìºgxd1	ÕrÛædkc’#œ8èØ`†Ä”‚½Ö<3˜zVÀ.¢CŠãxíº•Ú~u€ÿéÒLôe€oÄh;ZÎT^©¾«nZÆ)
O/f;"Ñ™ÈÜ•eId=÷¼j‰á;ä$Ì“Ñ…U¥•ä?ˆdpa[A#Xì‚!¦1™¡]EË—Ş®aWêìîøévC+WKR7mıK¨™¦o
§şb`iKUTnío¿n(ïû‚ãz^véü‚Ì=6.›;~s¸ôÕ—É}èÊV£›.Nã…z.âÇºCß¶¾QZ˜Â @hÍŞªI[ò×Cì ²š6¸È¯8{92ôrMæÒî¦ÕÊ'&ú|*$`è|j¯Úg¬©2§Ã,»CõÃ *ŸËÁ÷Á‘AÌ
ÆuIº¢©
.cnş¶£Ì‘„ R´´ì72vÎ&QƒÌÑÖÕ&*û\¥øû­/b´>è“SH›íznMlãG/‚ÊxÊvôye6ËktI¨ÑŸ¨’…—LeÒ­sœuç?[ Ñq‚ål	BcY3;mb®ÑyZ%"¾¹¼ïpÒ,½¢çú_ŞÖ‰~»P<,‹Ë¼ÿ	æ©tßü Î[ùÍüuŒ2‡Ç1¶Qù…Ÿé2Óò|è«§³¬£ÑsU‹.Î‡„{;‚N×ø 4ëšÏİÁ“'¼E°p´èîvé³fú-¬%âœãÌs.Á‡*7mÕÁs¬!{Áiö‰ç\£JäU¶¦ÁM0Ô´,€R|ğEÒ,Ò—Õ¶L ÙQhoi¯vhİÓ* Ba'˜Œi³1—c9®İ,ŠsÇ JY›rP-¨ù°<&}ãí&Ú-8¦Œh(U´:²ğ-‹J6Ae”ƒÃ~H¯:=€ƒÂëU‹>ë)6@œvÂ˜]jøÔo[Ø¦¡éŸ¼LKÉıT‰ ˆÕ2ÛÉR†G©ûLä9ÛhX«h.0…„µçĞ©(·á}–ÛOnŒ4p:yNI†¸Z¾’ºÂ<Â®»{ ÈRÜğb»”,ûøø!ÜĞçPã½.$ìm¨]wPXê‰øÆé¡€ˆ#Å„¯œÉCL¶"´$à ~ƒ=§·UkdFÊL­ÿŒó…qUã®ßEĞDĞd€®ÃN‰´Ú®¡¬Ñ£‹WÔ	}Û6ænİ¸(Ø‚ÕO„¯r€ŸPæéÓªü¶?2|Şq¾hX¶%a—oE:ùz]X¢ë°Å“Ã	ù¡]_fè£kÑrKñiÂíiI§L)-òîK½FÌ*ãq©TÍ-6l‹B–ÿä°r¥·¼şX>ÿ`MyA§ÃN?3QÆÌh“ÄìÖ²úá6YXŸÚ·qÌL­æî‹ÕÍ”âüD›,\FŠš[¨Ë‹³çrâÍıÃ‹×Q'ö ÙÎ^'yıÚ¤%CuK¡Fş…§•¹LÑÿjoO¤aSˆ*ˆÛƒ´é_"G	şÊ	Í‡£•ÓÌ“"á©DõwÉAáó¼Éd¤	T€,ue65ñ´yiæLÒVz€â¥5~/×ƒ)Ô&qŒ™BÙmz«àClÏöø“g}£ ¯óÅ0b*ÿÕ—¨º}<)h!9aLOŸĞi—j`ô­6uKy€HË_-ûùîøÚûõ_†änõ[¼MĞ‡ÏaöÿæRÃe"™Q—$èŞcè85=
«5éC„Hùª[D£.É(¸¸£”Xğ-N´øi˜’/ÓØ€ÙpeT	_;á1ú¶jˆ‚0pàšdx*z4ÈÒ&K„FXàFŒWY41ç¨Ë„“0ÍN*š…óIjk ú±)Ù87 p]A9s6c7Æ?DİS{¯Db$TØÚv·Ø% ãRz]‡û¸'8œ*>ÿc>qÜÔ]¾À“¡ı}¼öÿ ;@vÃ&4,{ãÎ]ˆ¸“ÚíĞ-D|ëÄàêPf%¡ıgwefñ)™¿ ‰l£ÌjC’„Ÿ|UêÍ,r
iú”}î³Y"{Tºª+€p)”ş®½wÑ´¸Öâîè0Å­ühE¶ê†ÇÚ{#Î‹§?Kdlª‚g'ÙG£ÇJb‚øD}Vn%¤¥PÃd›I¬Óè^LĞºBzŠNÎsÍ¦íÇİ—8š8î8}¯îz5Ní³6¼ºÓ‰qS¹W
rôÓ '']ªŒLàj5·ûÔ´S—ÄÄğxmİd®í£Ëf$ä¼Ò‹š±ë£%üMsÄ|yr„2­-ÀzS)Ê¢ìÚÒ‰‰»ÄŞP‘¿b:¾µ­ßÎ´~(†.ß’/´í×¬66_Í^2Å P	GISäR1R[ß;1)©uòß/äÛ|¹ÌÑ-»U ÇåF•³Œ¢Kı…ºÉÓÃ¸Zv·xQZLÚQ5Ësu xÊà[‡ù ßæÓÁüb•$?Ù<|Á‚»)©jòÃê‡5z²¾ë•+îòı§D™<Ö^ë±ş<SÙ„ãäw²V»ø´.FP(§ÅáÑpê’Ÿf¬ƒ”¸¬ÉF#4ÁÍ<mxŒèÅĞ÷ÿ˜(¾ıd|ïG;yìmbÇQèçpÈ·jC1s›%fİfG1ß¥õ8ïÅ¸ó½7/Üt­AäBY¿ÀKPíÿËÆu¶ìÁæşi¡6™‰ô$jŠ+‹R:€ ğöXçõÎ¡òÛÁÅæ¹°Á‘l“Ñ2gø¼–#¶’¸qÛ3ì™¾ûlw˜Å3cD´¢'‚×ø
s2şä†Q†M{üG¦´3°$Jp&œ8ZÊfYyv·¿h/I‰Î¦Ÿâ¸€€¡*~´ĞBí×‚*Úy;Jvk`eû>ºœ`“àÚb”ÃÿÜ×Ët
!…_t´i¡óßA‚»†#ôh:ÜCcà€RB[ÈĞ*#çcÑ2Ğ¨k0Øæù„¶]TæXèE…Ö|º=ÿÜlë¶€>RßÒMôï´'ÌØĞ—“î~‰ÒßÊ¤?ThõÿáÃ
†(_<T¦J¹KLÍc]öPGàî~bí­‘>íQ#H®³ñ„ š-Š”N(ÊÂ,•?”/³Aucõ÷õdAè8!á£åœÙu
 ŠçºÈ°å0¹úÜŠ=øÇ§òu?âi÷Œ†&zF¤OûH ‘I™ğà½’¯w¯R¹‘6	ÄCŠPq]Çµ™óĞéó?r:GèÉÈn]éòõêu¨BÌ+»(«Ğå›\)/6Æuş,-úwÄi;ï&‹¤¿ÍÏåŸX¹'ø¶Ìœ”	„­R€"ûâÆxpÙC JZŒµ4X`õÏ{BGˆÒ|‚b}TBN&rç?LºQëGÖ SÿşkµZ÷m÷êñrõYO‰ªbõ‡AetH/ñáElUS<Ìë=Á…(@é[¼¨²·Éÿü„çÛ·käô…–œT«m#ÀH¬"¹!€E†±—reÿævöÖ œí=Õl¤EÁQ^ÅœõµğñÇ«‹l÷—:¢r;Bïi¯İÕœÎ½ºdÃtÑ?¤gbz %wØ‹û¨%ì?9>N ıdè–½8JxbG–Ğ÷!ü8«ˆ†Ãš¯:P,,•{I§l#[T’?ÃyX8H0;e ¤»ÿ)Ä€ÓÅ9¹
‘ÄxA«GşÖLñËwª5$ŒÔ«
†‡´'{su*Áê‚ûn²/ôdªaY¢ôK¤ö¤NeéÃb†l;ä¯ÌÄoøMqéa¿Y§Á	İ:7æ«ªz™e…ÒGA¸È´pµIÀu)ZœGRQ8EBC¥ÈdLÊ×´ó2<+ç÷—ÔÛê§|&È>^vº¢æ†§Ó±­‘ù“¥‘EåÒ\_¨©Z/Æf¨_ +Ÿ_È]E+¤wØQÛEØ±ë
–7<¶´QgÿfD^Œß&ª bYp,t7zƒùÌ1‚FÂµQjoĞÛƒÂ$…:Gá÷+òÃÇÙZJv øjş\R=Ûw¦§ˆCL­ö™f"úƒ$€{†3_Ş¹cÉ’3R®¦µ<t›­C¯ƒÚÏó²¹oIwšjŠ²9XcvJIN1¨7<=t.kÅR©¾ºíQô4QrËŒ´ág|&Ã!×°dAÏâ14À¶Õáy–„g™?z'ËÚs«iUÄê/Is‚‚§L²[Ü	pXšX¡	Ç¹#`¬üœu8Òpiû9œà¼ÿ÷˜´Nãòúù&v`µÚl¾
kT²³šV>ÃÓ«»ŒE¥w¾+Î¼•gOÈÿ@Ÿu=CvYŞ†_ùÕ\‘×Í^½µ«…äuÉd¸ë
HO? f–a÷›(|	ƒ«plçE^4´Î™ïc':èåŠi4]{ ögÏÖgÅÏâ»g¼	â|:8­òò}^µ¶ÅµäÊŒŒhk8¦6ªVM Äá†õ½‰Ÿ‰}Rıèæ$ÛeØl-¿©o†êÕ| ~ì4¸SI¯C	èÇKDÑÚ¯"@Ëºcë³Â,¢Ÿ.BzÛUa½u«|Sm¿UÛMóÎ×ŸYew'–)ş¾Ü°…Eµè”%GÕ2¤­úùµ›äXõ?nÁ†k(“å=ê>­—]ŞkÙcIU¯¿ÊOôÂ İnˆ”‘_×®Õê‰/[í³.­^ºşQrWHˆì/COÇÓú9nş#,VíŒ™Ò‹¯EèJ“NthÉ©ÙÚAÓ>ÌI:Aí:YãÁ§hˆ]TrÓjNn:Jã'
?	T{°•A@‚%à×²ºnu÷¢s5{ü®yÁöƒMõÔGvä¶úÕFõ/4í“ÑU³\]÷ËEô,µ!sÙ&Jjs¡ŸÊ‚†Q3úÇlKXËä¡{«ÙÉä@Àğı(®³uMn¼b$ãIÅjlB@Ö•¢¤<r¬î'ï½ã¬)·ÊKë+¼X«Yº7—Tñ‰“ŸÓ4@Êß+-#.ø=dÅ Ï›ÉÜš{$éoÜ–!ç8á“ñP‹®¸"qÎ•eMsô7ùçi™Œ^«üD›7Zg ÂçÙÑz16 ‚nâ¤¦T]ßNûkĞ”šuÌ¶™»ŸğñŒäµO<€Éè*L’6#öølû$^\7(G¨Æh¦r4C+AöãöR$ ]ñ$I¢N…fb¡äÒáqv6™9ùÃ İPxÔ°4	d#‘ƒßy€wÅû7™*~º9áòh7h, ÓhÒû—ûm‰eŸuüpˆpf©©­/ò¸³÷ù…Hç™ñ:óTß°íhø8¢˜úË/ŸSŸvñaq®Ï? ¨Ïz¹ñ>Ñå{ëøUYãÕOÑÊî%Â0E¯~Í{,{ıº¹[A¨’O¶<`©ÙÖ«=pœOó=RµæPLÎxzĞõ·« Ç›Å	)•İí_-.|RX,M¢[Ö†pyª5:‚@t’MFZ. ¶•1Á‰vœÁzıÖõ?ß…ÁÈÔeÆ€[åÛÅl›1¡I&ÿÓó*'¨U¢Ÿ¶Q²Dî«®ïÚùßEŞŠ££¡Ê€§_Å.şGJÙÓPò%‡Lï”øÔW+)ªSe—öÛyíêƒ¥$ìÖĞ/%úÂ=°“ÛOK-%@[à½z”R†57ƒà4†±"
½÷*İg‡z~¸ué$òcººöÛCpPûÍÒÒYQJåÿuXµ=»zYz£½„@eê×[¹;€f+)šÊÉQ?×u¤£jÔtáÙ^‚u¡Î r>/•u.Ã>CàKrzËZŒåÔ(¼ˆMÇ;ïíí/2Î²ìáÑŞÇÕgRsŸĞ3Ê@Q¡Djç‚n¿âJĞš'pñçsZ`Ì•!)}é^öƒ!ø’Œ}½Ñş—*‘wW{ü´hš ØĞ\-¡±?"ƒß%{–%Ï¦eüKö¬Å7µÌ5Æ»ºÓ~SØ4ˆØ`Ğ¬÷¬—91ëU§FşX¸03Áfnô3µ+·UZmÔÀ>kí»D–ÓÃ%Ù5tC}Ï I[Ç2§sì<Ê‰¬œ*š<9(
÷£SĞc—º„g=½#.`g—¸ç(Ş³Gn™ëûÁ©]e‡(Dl<v`ãİáª'šhd9lJ{U0Ê±‰dOÁ½ÚÃ¦Lî–Ã9ºÄù—eW­?b!pÛ<L‡~'¢¿ú×•*E`ÎÍÍv±y“Ÿ0íÅ#lè¹û£k¤1;šë×¯O,®õ4é[¸à(4Ú=]Ùã/	€üÊh0óV/6sïb½1îíß”Ç¶©*Z'ê{¡’²±>ñe6ŒMg&.dH†Äå\äÈlfâeî ¨»P°c¦ÙŠ«ËD­ìV ˆè‚˜ÂzÄ#V™˜ë_+ûci:³LËÃW%ÿ›ÅïÓRm9é‡@÷¡|ÖE5òÑå-zÂyM˜ÏÁióÄ$Q]†£2{jn‹ÅÁ$û”:¿D ÷˜Fo]$2èk~]Y*àyï¢%ø<À.i M–İtƒ2”'èÑØ"“µÑ9löËhúº{f§?Ów `/Zr™­‘¦XT‹x]í¶ÿîÆäpR¶ÃY` ]ËÉÍ¯Åh¯±íŞH0ü«ÜfÌùPvfÀÎîÙmá[×¹DÆû›w±çM)’½@¥J&ˆá>¸z$g&€á¿^l»ERu4“BÊÖ1	W½|u³ò’	AUµtNûœ´œFê/Ÿ×ïËlõáû:5ğJù=fêXHĞá‹(ƒé“te„öNëLòp€e¢?ZJŒÖµ¹RR.‡v/ªÍZ<"s†pT0™÷Å_cUR²+‹÷7BCĞƒ»ĞLıÎ'gİdæıÙÕ&Ü•‘§	A¯X±RwÆôËÊÓ"?eLb“
àÍùq‚0ÌB yr÷”.ÑqU„kºár“ÂVVH-	G†)ŞäÜ_ê·7ÄiÃ°æ?ñ)íj	41ıº?´M…G,ËË¹NTˆåd–YËoøú/Tcuù>³–¼¿|ğ»EcâğÑÈ¿ÌğFoİ‚2KÉd¹Íiİë¥‘¦Zf*§‰#u(ëñkŸéØzë–ª>pK}ö¦$RĞv”Z¤.EBLÅuHŞ›càšR÷Ó4Îø¸¡a8TŸe†9B
¢CÛ¯…1TÍtÒ„4+_İÁHÅQ<–”‰§9™İTÅ>,X°fÒÍñmNûY(ˆ
-G¶éwò¤z)P®8ÅlX<k[Ì²Aq¶’;Ù¤N?PäŞÍ‰ü W…ÀO	n‘g'¦ªíIÄËÂ5áoíü2z^¸8#Ù0+ı#oÄíj6Ñ‹a¿;Nşíõ§ï`Ã.
#eUe™Äâ™
B¥³AäÕ»³èdYÁÈøPšìÇ˜Ü'aâ¤ŠİO?×;'À¬ò¯OÖ£	ç_‰fšc¶ÍB›ù\áC ú˜Ü£ùÄËdm  ¼#¿Ä}Es1äÈP”2äŸ×:z²@ã b0‰\z|T|SñÔ;´ádnmÙ»G›Äš²¢Î ‚ùÚ	±|·'Ç'(ÎQ¿XsËS;Ü‹4$åçšøÔÌeêİè±å%Êj˜Ê	¡ %Ë‘Q©ÒnNã4ßF ¢6 u¡zazÚSµ™‚îIÃº/$P-¶·×¥Ñ€#È?Ğq™™yïh%ÁûâÖ“;…¶—/p1jÕŸÌÜå‹1èè'ör4U+E¥ˆîŒÁ¢ğî3š>m†+Ô-±#&Uò»çpÀÛQß£º§J_’{|Zú·¤6æ4lTïYWw¬«ÇìĞ
ÅGø-3B^*eÜÌ8t¯±é"%)¥é›LvÌîç9ÖZªî¬uSãŒQ€~BUÎ"?/ùÇw+—@AaØ´XJZ™ğÂ5¦
+Æš+á1ıPYéÍ+ç4=ÿ£Qk"ä²2eMÌ65›7.*œ­\Cûœt
ÅmŸk	Éb…pg*\	r<ùf˜Ğ¯Î•ÈŸ‹vl¨¹`{Eü*šF=6–˜yòYÎLa1âIÜ_hG±'¼÷4ŠÇø1¬÷tXêªöY¿Æy¡ìó"%Bui%ÚäeY†ÁâT4GâÏLM¼F]¨WDåÀ«ó•HéAå«2^Xß\pàF>_ÙÃÙPH8Ïá5ŒÕ)ùg¿-ÇŞÙ:ı¹³ÍE Œ‘ ƒxÍÿö˜(n L¶Å´‹ñ¾ö¹ÔuåAAØ(‘‹-í}Ô*9¼š•vé!±×í±ÄŸ%Wƒæğ©m‹I¼í Ù„u.ª‚Ù|ß7FŒ§Xÿoó®«àmí„™SÏAĞÉSÔPæğ7™Ô
.İèÆK’ßûĞ±ÒD=îBRNz6©±Äş»ÍC²º¸ô¿(]ˆæÛSt°DQ<‰”eê„N®“?œtÂ')°ÌQåGÒwÈ‘Ÿıõo[ÓÿDO]Ó/)õ•¼ÈNK¡#ol‡¿¨á¾Uçœj¥±S¥	@sŸ‡*Ä…Jüé
Ÿ¸˜­Ğ$ìRï)êYJ¿w|]L¾+ƒO=ñê‡‹@q"-X¢2Ÿ]–‚âö2T`Ù%A<ÿŞÅIvçG2ÕİÓW˜x«äúYWÅÉˆs¿î¶›•b±ê{¹<¾’jÂ«´<ÈËõQg¼0Nh#Ÿ‰f|¿L gä‡ÑµÃÎjŞ	Ä7'[œbáÖ•ì5İ‰Ù…äÉ“yÊKeç½ºª|š´£ -øi6k†:_¨o‹ãKdšmß\¡H/ıÓZ‡Ğ¦L#Õh.’.Ù¡©Ÿ‰{-…"^NŸ$t´«+²‚74:ü˜#öL×l(CrTJñ|G=0	e°!nÿµ”":}:!:‰sG¶ûgŒÙÔhèz*!	ï÷EÂ‘¼ï•I"ØZèEñˆz6U¡ÊMG›šàjH	ĞZ­‰]Ú Û$b“éÇrú:>g‰¬Ûı*–µ[\èÁúÉ„í0§D®i‰3˜:E|
:{ÃD¹ü²•N‡üLp($Àú~‚Sp×R0«q‘pú6¦Wµ!B•Ò à2¶QÎ+ÿ8|â¾F4º&&g¹«d+Zü0ğn)şê7I†¨ä±iø±æV]ò%lèŞ¥\õ½Ñ&ZÄ<T*‘>Œ0K¢9R&Æ¹X¹[‹üSI^t;z§VÌÄó~x§R¥ÖÜÄÆ`20b –ÀÁ®%',mŒ>‰Şìt”s4×98WG’Ò€^m@¿¦\ÎdëæDáø4%­uŒwo–Iš»lw’1;™Iö(cSı°ö˜nµïæktW0wîYÀuçš¬øı„ B}PXğóZ„„ÅaLWN¸.XÉÔó‘Û^t÷`ù]'N3p"m&™¯™Êkß•b:‡¾Û‹Š6»AÈËËot;[/xÙ0Hğwª­Ch…Üª"„=ÒÎ7OùCiwcl~–Œç¦ªö$§§IÄÅ-ÉÖªÜãau‰leåóéKâÄR´Ğn’_­Œd)?%—XÓgŒPƒ»Ä¦!Õ§>Ü#®\Â¾C»äÿß
ù…QŸ¶û¤û2;ªè?µ½¹ªğBÄo!tõÚ‘µz¾Ï$k,·)WÓ3r	°\Õb§§Èñ€™ì!‚+‹:Ş…h3œ„©â1Ş$Úvq ¡ï>Ã,ÂcFƒ0 ò S±¤³<	lò?ÅÖVaß[+Ió;(¼M^@‚'ÈåEÌìş½=:^ó5òds•#0ÔÒ‰Ûuà”‘S¡ù¶ïÒì-…Yò%Dí"a5"0Ú+N"&—Œµ¶¼?bìw¢Ösw¯ ó“ZÊ`M2f…à}²§-–Ù¸dÑ õc*Rµjsò~ëhf:®˜µ¶m¬ ô€Õ1hÑƒ×´J	ÿÃÚöSõ—D«õJ1zM_ï:".ë|¬y¨0Xó5Œû¢Ş—LUÑs
¿iI™)f¦Ñáˆ¨ŒtÈ4énnş\·ƒ¤È>'Ÿ˜…uoö.5yÄ/®$®§ï.Ã§—K%IÈyn¥ĞÄªŠOîêŸ&îW¦Fê³f~şè¸±şqt/Mî Ây{Ö¹½t-@e¯´ËêÓ6&ñc:‘Õ§{¡pßàÎÇ¤;QŸÑ×çIXÕ[†{ÀN#AÃ±¥b–Ë3;ı¢Y"'ªÈKÇ#*’ˆ<7R ÒÏ§xA?ÏORbÚ‹‡uGùßt–Ãg É˜3>p<öÀ×›-¯çg %W}mF5zuÕ)ˆ–Aøgğùz²	*u‚PÈ”ùºY}¢	a;¯ªş£¯ Z'w‘ïÂ¨¼ßèìa‰—Ù÷24÷¹Ò"ŠNÃªlÏ•yğ‡G Ü™ÜÖ÷Å’Á7†˜™	åÕ‡Ü<tÈ¤GÑ0¼•;˜ø³ø.‹·ŞB~éBÛx¢,ÄìŞ š½Ë™x’«4AŞ)–£ Ìí“«YCyÌV.{S+ù‚/{¡øÀ´Iihçò„ “Ş¼Öızßô†]]×‹‘Í¯	µ¸
hñbO3ƒçe”>’LËx¼p*tF—YXKL2¿ËÅ¢ÃËõÂ­-I ´º<¡®ñvíî°pH©=Ô'­)@È µ’ùà[ÊÖn’(H[— ¥tÂÔã>Á«}zå9Óu(QË½;8({ê×w`ÛC˜Ø]ú_LşPW0×Ìkæeº•–8&dÒÄ“]ŠÙÅ¢JÚajÖççhvé»Äü7&ûy—r"Û¹±¨óXú*VÑµ¤í"Zµ6ÑŞ>"ã9Réjwa÷ãß)¹,"2)~^/ßp†|V«éünÍëŒ.İ¥˜ ñ¯†µÎ£$ğåòt¡”•]c~Ó»hIsN€î[®÷FV€@B.!d73©‡“ ©ŠsİºÁu&W:í*dtàÛºÔğhn{ÆÙU	HïW_Iæ&[VĞ/®r(s£Œå ¼ìó.ªÖ®h-5çSqFy`º˜l^Zğ¿ÌıÏ…67D’vÌ‹9ÁŸ¥¢/›|R•Rë_*@/éÇ×éÎŒ\IÇø·3P{¦¯#QŞ<‚‰[dWÆ²Í³„±ÏÏ©ù¿‡]•~L€¥¢@n?ßHgş¥TOßL­Û©3¥¼u—Úvë¹õSfîàæ {ÜÉP ruˆÌuCÿêŠ5P~ò<Nü¶]µDW`ã>„YåD'úÓ%øŸÏw¥Õ8ÉNÁıœfE3kúÖ<ò®İ¼²£ıâqt^j—¢5e ‰à
ô%O“•/ÛfÏÏÑãÇ~’M¡›¼÷Cl*%µĞ\w…œGJIÃòê±KBÛ-r†Øä;¨“¨ G‚[.ª;+ï]· âU©¢Œğ¿Ù¤ĞTÃjQì˜9&ì"¶U0mê? w“§iaG·‹¸aëÖ5d=ZíĞ½’Aø œOº¦2¢=Éi(k–€(\Xè<*L§OŒTqŞ>ı<6Çt«œÖ›]V‰^t»Å‰*‰‡G¦{h´9N°‡'G™gÎ<¸4æ×…ƒhE„¦°sÌÆRîRs ,‚¸˜Ç0&É-ÀÍ£cak^Z`§¦H¢•âÕŠÏØÔ¨
 ²Euš{CÑMÿÔµé" yó?¶6ùÆeîè)v~Â`ŒÆ70‚9µ$F |†­;g”½Şø¤Â2YÍ¿a!]^Î4Î#1¢¾8€¿Ñ˜i·›Öy<™éVjkDŒvÜÊnßş1±ÏYÍEê<äO»DTÉ˜óºÆ¶,wCÉî4'§PŸ5 †n®iM¢jÉêyGìhÂ‘ëŠ×h:/pmçD™eUh`eëÀ]ÂğÎ`Òš›Á×Á™¶|Mf+Y&2ÜN/Š×ÍÕ7:¦ĞÒ4î°™(4:Í	¢ÚÂöÒÂ<SíòúS‹– 5uVso§÷ç^$bKŸĞH¹kİ*M^æTgP	ÀĞÌÎ$êy]å>U:NE{*LÉYUŠ3Ÿ¤¹Å[ŠZP
C¬ñòù×ò21r§ôZé¾¬‚Q4EbÉaR¦í"m§\ßö°[.jÍÑcÑ­	‘,Li«)ôdÍMñÑ¤›R–ø§]É?©]½„ÿ ĞélqÕÛ¤)EºKíõ¿pÏúzú+ºáÌÒpFyuÂ8|Ì£D'íÑßõAH¦î×ş¶K^˜Á¤ÂºÔ÷Flé6Q‘ìWĞÚsòÎ1ÈÊ¡ Ør HÅA~­$ /vÀs&uÒR'İ´~tlóÎ¨·;³MB«¡´ÿö=ÀfäoÔ ƒçbT¸(š,­Å6>íDbvÛ©òÃkV²™a³zœV
ì(ª¡rc·†WK5'Ûp•\È9ùÔM~[± ~ò-ˆ“öT¼n(Å¯–áuq€`ÿ/²B¸ÓŒ½‹ªoe˜„)ìê‹%tt¸ãê¡*x.{Ê¦0Ãj7 #¬+`^¿Ñ›œøb "…Ÿ^ÒQ”ÙwzœÕZ§Åİhn‘Ãa÷CÈ±^©ô“ã>u¿ÒXZŒ."İ5œ/	ˆQ`†ÂÓ\†uHN6¡fO¢QÈcu{^Ô!íô=hçÚûZŒL…r‹êŸU\X’ÃFîR¤öÊ¦u»Õ ö–èE%àÿ@U­Ş©åÍˆ[ŠqJåØ"ØB¶ıPc ş#¡%$Œg$+Äj_.¢gjâ]–ÄÌ"Ä¢ÃWİ|.ê#£î¡LÑké"œa"÷‹'ºnR‘ú­(HÂgı&`SÃ™]_—"pLØçä5¥	2Ôd=`à–ÁIK(:­‚€¯]­ŸoiùäLÓØ¼íúÛâvõ‰wos¾•{	¨ldFjÎR(QxXè±ÊA“Mšö¹­±ôN7…ÚÚx"Åg3À`“Hç§
d°èv j,AOœ#ŠûîCn)ğPh?é`K·|¨
ÌUšJŠšçeÎvÇ…‚	°#íxüë=+¼åPº:4ƒØj(5)jV(ıó ¢¾ØdWiŞª­ØÇ7)YZ–’ÊØ£_æ4Æ	 -´²L5˜NQ<ppIïpbhW‘ŒB“ñy­uALßõ¼F]r¬ºŠùBØje–…Ê!:9zĞı{aÌŒíÆ"é.Ÿ†@bÚÂƒU•ÖÉD×n>µêCT:Ø'n‘Êõ\‰wv‰p§EšNF<·OSJö#­¸—e£ ¬µ6‚È‹†rpÁÃ•mÙRmÛD—ãPU@TbD“XĞ?¬‹îê|+zí¦Ì:‡«¡Òe4øW¹Å&CIA"îu$äà·‚>k·è8F¸M³MüGƒ•×i!€–$Øn¬Lö%‚Ö«BŞ¦œ/vŞ(F#­˜@’RôxEzy>«ôÇù†Ànê|Ü@Ãºä­yâ²}I¼Í.gŒTû®hí©¤çÇ½MwBM%	ºYƒßv„ù%í,%MÓ›[ œ¡ÛØö’h¤f±e$_Â>©Pë!AÀ…Î÷ÿXıyİ 'ƒ27§—fZl¾’A;³£‡+Š˜ı³5#$fvGÉ#®^J3exŒÃle"†_nŞ‰5tc5X+Ÿ–j—š¹»ä#›óÇ¡‰ç="€h8ül‘‘ÊLËÇ‚©ök¸kÙğr«ë[‡µ]÷±ULÓµÛ’(VŠ2^s)Ú†"’Òš5¡E€œ„˜óZœ$t$£Ó¼U€9›˜Ïä²rÈßØhgTäPcQ†ÿPï÷*¥´H<‹YüHâIhÍâøµ`)íÓ_O•]^¡­Å8«Ş­è	§y³ŒŒOÊÈ3Rv×pTöêÄïJëÇYa:Á¼(•è&gúñ¼D–¾ïp\/¤ÀŞFoêÃxæ+OY>ˆ±˜dw¾ÊŠÜU•İ‰5*à_.a>©@ B7;nÌœ¾ (­sA’Qùû°í«Õ m.-8#QA"*+–·¨×ÃMH“Ïq÷ŞÉ§É^5´o#86{JhW5&—Y *Z€óZjğ‡"{xápH76Mm{¦‘<ãz{M×ƒº|ê5UŠ ²ææhëÌáˆWAi?ÀßWˆÛ+t
1g£2ÎAYKãOÉd¥ê4¦“•ÿ°¹ì˜DL\£ÕI	c£Dmj‚Ğ¤?€¸Äf)<¿v`Ï¬ÏO6IûŒ7FyWŠ&åÀMğ{¬8®\w;"_dT)™M(úÿVäCDD(Ñ›§Œéï;íI4ëĞ‡Ï0,\MÄ‡b¹¬¨İïÍGRúÏ¸©A¼Ø’Â,ô¤!fXØ9¹ÔÅLz¶#ìö4ë• Ü|dŞ]:êXZ~^YµB.ôÑÎã{DsĞ½æÿ÷¯{ió%òw‘`v;äyC¼¯näìñ)­{_=àE<qYÌü¹C'îùÆ«Ğ®ñäØ0UPï›*ª_Š0…J¶ò‡ŒœŸ£ÈQ«­oi+³ié–Û *‘×¨ ˜$t„J3“élhÏdÿ¤vİªJd¨_¬8…£Å„³+’0Z‡‚Èv‹…Zñk¹òdÜŠnó=í¥VÑ¸}|[á½”ÜÔIÓØ–Å’m`U®R‘íªÏ€¹å•…MúkD·“Q¬lÄ®>—İÿà`KÒ¬ÀÍ*iÏ]´ÓáúR.¿dıCãuª¤¬®êác`ÙÍÖ5Z'A†%1Í ^;ôşkiÌ°®ˆûä¸ÿĞØHÕEÉ]Äênİéİ–Ğ¥«Â”cÃ§Çíœ_Å5t¾EæbÕ¥jÊ±kQ_ÎTîKKÓÑ–e¶u¹n|,x.\ñóY¾‰Üšêí?eË	«ø¦QS€·“uWó7+*™Q¦{¬Z}F6¾m‡¶f·ôæí%¿Şí÷?ûmÅŞ†­R,”it‹¦È”'YŠŒH¹ó,[»¡ıœ²½ø[dĞ·]cµ~¹ OƒË7L> š¾ ññÑtÔWSMâ>|cKpŒş
ã¢¤ìBÔ^Â{M`‘
<v
¦×¿ÚËD6ÇfÌVş]“g7øéĞ¿£ë?	<_ÏóŒ¿Ø*¥³üª²ZÕŞpÏèØÒôé|nMJ?5)|ï-lö¤˜ ı-·g¬~ 7]ˆ³Úìê~Böö¦,\PûÓÕ`¯tOV1gÓ=5Dß<Ì”>Ö€áA{–ãıG>qùµ-\¡Y·&üPh	•Ù-]¾uóSÅJ‹§ı)&İ…ÕMµBğQú0şiX*Âí¼üo“Üï‰)Ái±?ú¯œ´ØrX¹?¼U[f}I!(hïÖ@“Ó‰ömã¤6Hª™ŸŸzTÏ ”Î'ÊùJ*·–!`K¶€–ã£éÛ½­Æ<íL	ÌuoXSÅk‹\qiGØÜ#VyEBJæ‚Ÿ W?°}MTêÈ`î\†½Å•¬”Lc¥=?PñØ¯™Ár¤VS´"x‰øÂON„)%@î*W¯Yıf	ø¨`ø®jóƒk¥ÜE!ĞÄ( ÒY±(]‡c5$†W™\ˆ‡¬xÚÊ~Êœÿ‹Š©uéC'_`ËRºó?]ÓóÈƒHp)-ƒeõú›ƒo¤VşºûQµúÚç˜„—Ë.kóÅ rØè²Ls\ÂÉm¦ÁHËj÷"E\Åøšòöà Ş{1}ŸT¦ÖùO+«0 f¤ñxùw§•I$8%ï µ=2Ãeï'¤r£H	¬C«$´oóªx^vB‘0Î3ô]Ğáç­Õm" 7aãØ>yòJ/N/dulŒ/ÕÕİ ×W”­"ôï¯|^móûåiº×«³p‘|a³p~ËÒı+Læ`ˆ;fêVh~6Y
?Ê¬‡>;æ‘—ZÆ"f6Otİj¨¹pM‰½ìe‰â€àÂå”Ù½ø×r	#æ¨ãé˜å¹QÎm‹È¾ÄjÀwò@ö¥ùì9,Âï£Cbé²Ûò__¶AÂfÉI€íË-D}K¤5³*Å}õ¢CÖ‘ GVfBXşZŞëNrr¼ßÏVIÆĞ]ã·S6[áT—c³¯C¯ôîŠ<=•fSéÜ¢­G®<X}À‰ÍŸÒhóö!•æj.‡€?¸òä)%kT—8+d?Ë9†Ynî`éÉ '”!~HÕŠnÕ»u¬@˜…ÅşG"í“t˜¨İeÿÌ¿¡L)PõùœƒÏ‹­…è¹¦Yî34—÷œxˆèÙ8xËV8àİ³Ç	kE¼\¥R§¨2ŠôKôJ•‚¢{0~„jÆiTö„Ÿ©pÿâ^Ì ¡UŸLå±,)â8«BHİÏ^ó­]DïîîÇ¬Ú`Å>¤hŠ*†5GğYOéÅ£ÉrHíÚ³í™’ç;IÉĞîİísA¸XCÙ¡7òzäÕ;æ˜6¯7è’ğ† ‚?ìo¬«|«¸ ÌwxôCÇˆt¾`CN³"Z'kaGjô^‡éÓÀn‚ğ'Š<°ÂK¹¼t ÿdMÚ™µ»ÊR!³ÙµTø¥©IŠ½Íµ·CLfS+¬˜H‘óª’¿¬èœáıÜJ¤PêéÜ›:ó¤3e_3|¯#İ…¹¢"9³]+eõÊ,oï?&iáa©´.=¯BA‘lóå‹%lõëú˜\«¡Ú‹PÓiÕüG½Ëp×<k¶UóEÎxdÇqFUÏ0¯
Š2ç¥¤]Jut…ÇÍppåíSìä,äÛøa >à]–wo›£ßÃ? †4Ú!H·~+ER˜Ï
ºnC—Jğê€0ç”M¤”+rÌ¤‹z.öZpzRŸ¯Èè¹|¬¤‡ÏP£†ODÕş­ãå’´Cn,¸[ò3l¸@ IMMxb…!i/Šz®­"{6ym væÉ?tØósí[=[nÙØ¸ÔTşğPk!˜ÿ˜ÁD–òYY3¤Â ÊÓ°U<Æ—qYø°šÔÛ­shßÜàKEGYşÚŞ\ĞédS=9H%ÿ€IÔ1o¾"ûœ<…¬˜H×%¸B•“Ù^ã‰É(ùûÓ¨İ¬3“»ã¬5xv˜VÅ¢±—
Bû#É}‰"çÓ…ù:èÏ½â6ÒíaaÒƒ`o[°NŠa—%Ò¾tb}¿ä!oa&EJ©Ğä6ßx"…9=6’½ı.xğÚMÄİ“v´¤Uƒ: †·å	4+‘oàªö“Wïš‹BåÕhhzˆÅ™7yp¥«î:,p–)¾¯N+ª7ŸãEËOíáô0fòÄ£ê‚([\q2İOA~¸‰Æ|…Lºl7¾Åq€K;Ş1º%L @Bí¡—¬TÍ|Û”€tòŒ´˜ŒŞ'U:k»Ÿ«pé¯AúÙ}êÚÙ¹‰¬àryAp
*C|;=¼* ğöİ•Èß*D¬+Ş^h\‚½–‚Ğnıc+ùYR×±,Û$S)EP•rŸH¾’6.\ 7ş I½ñ„±t¨CŸüŸrØÅ=¦Óq0v÷îf›`ç_Åèß—í#²ë¡©I¯+½|£í±şP\”fÌµH,™ŞöÀ”ª3³,fPÒ4Q¤€Ìïé¯¤“VíÏÅûsºËìXKHv:9UO„] œäÏÎ¨FlıXC`¬±ÑüX{4mö„§¶afKF[Jn®›^3Ë/Ói
]¿TĞÛOSµ¥¿ü×W¡
77Šîúì'fåšÂäŠûéIÍ|oçÆ9SŸÃ«7£ï„àº…?éšÒõXÎm-œôËZc–öUİŠ³­:\:»å!"?·ĞJ,k90?À;ãõ¯‰Èf7bÎ¿ó¸T
]‚%{¨JçÈªC=”çM¿M¹“K
Ña›(É´ùšÛâ;zÄ²OfÃŸ©R±0RyU¬yOKò$å³SK	‘Å	4C@µ³6^½Õ’Ëloh\L„H©~;–ŞŸEi‚‹¸¡Ia^ÙHä‚mÙö¡Ş5ÔÌÁíJödó~& r‡Q‘¾ÆE¥XH°äå¼™*ıE«qh$ñBZğÃ
Oøü¡¨`F6“Òf©Uëô®¸Ÿà:ŸX6ª#Ä$‚…l2Êğ©ZA¡$Ø;æL«Ú*e'§ä»iEzÅ÷.%Ë İHŞú¯ÿ]•d ?Ö]êøIïtÁI*ìùógdÒ©IeMúeÀÅm*²¾	ÔLŞGäpP:/ì®+ ³?²MÛF˜§‘ŸRÀ9@[JƒÖobeI6ü5£ZØ‰äôØ ¹{ØˆÀÏLv<0ä5¹6­1¹)5=AíVB%Í?Áä¯cÃÀâ¹QT°)M|MßG—WSKvâ3­IıCé‚S«è8eY“Î0…Ëšögµ5µm}+‚½Õ­g~5†Kb3AÖİ}<|E
JZå*òuåäôkêtIãb:²aÙ`ÍfkÛEÀ¢€ØÉ?³XOô®Ì'1F’¾st95õz=>–Å’à>ãQMF	a&!Yu­:BÖÖA«C\p·’İß2²ÎşsÔG§Ï¿ñ{Wï:‰&½ò\>Wâ"+gšNh8mRêÆ¦€iµëVĞFU,şG6Pi AÃù_çzş«ŠNeŠñb˜ŒŠƒ=ôjS<Ã—¾%j™Ú	^ù„mÚ§È
põ…Š-ÿÒZ­.¼¥É%ıƒÀVxçY¯$¬ªĞ©kYg±y´çŸÊİÆå²-°ŸxH¡´Ú…Î÷©`+ <ü—=äÒILúäĞ	ÔÃdßß•Q>&WåBY•Ùn(ä8r$L+ÅV~ºñ½ªh›üØòbˆ¢N©<Æbv¤d7ÉÊşÚ$—×§“I~úUIùN;å'»¥%†]ˆy<Ğ¶4«ÇõÉ„ß³?âmW^šô\fuøj€7ûü=ß[À/ƒÎW'ã¹³¨šÛ_ŸXÕe(ÁûÁ¿ÁéTfÿ[hŒQjr¹ºúX¦ºnanŞ¦°‹M,¿:>!ƒ¤,¹•†¢ú…Ã	¢g£_ûó¿Îødkò}7xq~fÌ¦÷VSX¡>§o´WM…|uõs¹˜{±ƒGä‡«úkÅ2¾ˆgÓËÔÒÉ«¶yBèÑlÎ–1ı¸#˜Ö8Üğrsà˜F3tp	í_YjtoåÄƒ‹ÚN
"•«CwP[‘…:Ê1!¤¢ëÎ[#rÿæVÎ¾†ş„¯<43‰¿,©qˆ«@±BÊgÙ_±~‹ÂÓÍ˜»Êp>³´FT>7ã³<w?ˆ€%ò½lo¡´ÊtğŠJÖÊkäÚgø‚en?‡ÈVØWÑKõÉgtØ gx  èR	Êeöo»“Áæó~5“Qà¾3ÒéÒ…±ÌšuÌ³ñ(L,’ÖY%±3Á5™ùTŒªR°¯k:#œÓ²|³%zB……±.Ì¤Æåà¤e ±D¹RCT,¬_i®1w:›sV<ö;B°x=NÀZ$IPL"Ç±§8”Z-²T»¸u1‡_™Ğí/¼hĞ|vX/ã”Mvôº²‘1½‚“5h9<YÊ\<ZCıœAñ™55…(øîµyÓ¿vqìn©ıù·âÔl…ğê=9—B:p~æ*á„ÑÊÀãÁóål@ævå‚Ú¥š#©Yj³=*ÚÕÍç¹üqÀß÷ƒæõ×ô{™^SûšÆ›RÏ†ßµ:3Šô@+Êz,dÎiÂÄ€WPí«¨Š¨âo£¢4Py!·L ÏÜß"ùò—eh)©‰h"çÊâ­Ü–Å?Xƒ°îİ¼1å|ÛÜÒ¸’’ş¯Ë×~‹ßz Ÿªˆ›½zİ¾»·5ZMd¥úÖ}	5ú"¬‰–iÆ§@ØoB_”’	±í¾?º§ÀñÛD «á‚Ò¨¨òiá¿yw‘S¿‰S¼©©íÏ×ŠÙ»ÜèÑE #¾ªãÈhÙî›	E¢å	ö/^öDíïÔã(…:]iMü1<¨~?%	JqéIç‡İ™Ì°µ„ØãœccÏ'|ã”ú…ãa¡À½’Y}$<MK{v%x·z
âsV”+£ÕtQÆÓĞXş+ü5å©ûÓNx­ÕuËëÔ™ÄZnˆr NµùÂ1[`,ÙzNKv*ÒÙº¨³¦wÍõ¸Aƒ/ôô¢‘9m»"¬Ãï]û *mˆyJ$$ü´Ã‘S±Ä²©«NõÅÍìÏù—M¦`¬j)M‘\Pd…&ë¥Eÿ³8U–™”íÛ©ÍÄèÄñú$px"×ÊHtX'‰{5ß¿}Î+±…³÷Ä|Û{iœ­?[Ùµœ~Ù¤Š`bÑå-¯ÿûJÏ³Š¶UışC3!úDpgÜ©Â‰ÃéDï=%è¯x)'>Á¶Nõƒ²àWÂHï)fõ‘{c†®^Ş;èü¬×T»Ñ<¥e†òA”Ê \öïÁ³ğ³°‚`/AŒúmï$"+átÉr$Æ<ú¹ftLà¥ÜÖ7Ò–Ğ}[ã©é­_æ®G´[°qqßèÚHR,ßğ±R&ƒ™Óº"¹H
÷ö‚Pw4lŠB¶™ÍNG^ãæÍàW°›=Oê~×C+pôÇVw ZÆˆ=*¹E½µù¨ÌNÒı{È£ô»ä´tjÉ]Aù=<Ë	`…„SyËµˆø¿!ÓFñ¾m5õ-’†•RÑ|Á80ÅÚÜ|uÍBí¶öÁôË0Í>í•¶Ç	&GÚ ‡)"Rš:e_—o:MJx1ê¿>?ËÅQß‘"L¹?~¿°>áql¾“k}í¬½SóïÄ=Ÿ½|üÖ¡$0Òyÿ ¤Wa!š¹Ù.Àâ½<æH~6Z"´w€Få´gÕÍ©ë‹5‰ÄÚ¹•İ„• Wk­©ôè=xÙÚÀBêWDVuh`
-XyYğ
-!¿¢ğŞXw©ú–³øQÈÒ
G)Š‰høîÊÆ°ÀÔ8K×É,:®-ÙBv„l×‡ñ9Èc6]4ÀÁ*ûLP–´D‡Å±LVh¸fn[EÑXÙ'ƒíiV^D,?¥A`”KM³ìAò/-Øi0³Z#ÕvV)–Â8:ÍøNŞAzÿÌMÙÒ6(@duœ"MøfØ0·@©å-)ë}'€ÜQâñs°Çş._'ähó!R/Ùz-ÖqbĞÒ#‹‰ïMø÷Ã_	s4•§KšĞäÕ¿¨³¯ÿ7ÏÁX·ux(Qê‚¸/­u²á-³uyqŸ1V;oèq3áÍ	>¡0ÔRòNq¬çT ¥FŞşÀŒ-o¬$Ï{Ö·¬õ”MÏuO	}ŸeÙl‚…eHß ì:æ=„X˜"¹¦gLa+Y©Óß¡îÙ;ªXç›Ø=hò¹.&)I/Ôóÿ¦4ÃN}šôQ¬Ğ°²†Ø:R†öÌ¸ïSNY[YwpêS€=vãˆÜåj9-Å¿(4³:½ûCÈzÍÔn'ò¢¹Ğ8¼êèReú–Û™ƒ[‡Ø¤#B‡$lÂcœ!R4y~ñï¼)°,ÆúKÍï–^L1cû€¶%²vr‚˜äÕ*Ö¼ùŸ@ï$ª¿å+dä‘*­1¹f(³é8n§Àlfì—ğn¥³Ú=:±8°Ë5wx€8P	8	8ò¨ôëÚ£qúÂû%sç§ëÜp‰-Ú›”(b 7vÓáâåˆ™Gå4	ı½²¸rñ¿P;ÿ>ŞéoR:Û>,}¤Òx0W¥jü&:œŒiğÛ!è……âšÀªÜ•(/}¢b¢dèÉ­;µDÔ)­Û‡›ø•Ÿ1ñ*SAMVJòZ¨5/ÊØ‹Q¼SÖeš»;ºñ&Û~	‘ıùúNw¬9K$MÌ•?÷šÏŠPÑNl9sDşƒëÓÿÖåÒ|-CŞª¯©ü#S´Vid=9¦ÂôÖ3ˆÇ‰Æ­;Á9v#•8U÷vÅ^¾¦Œ{ˆ üÇÔÁ¢ö"I²1 Ø¾6*©I”>´Sú6Bßc	aìQm ›õW!’¯ß!ªm¥ìlTMc@ Ó‰œ#YL’¥á²ñ¾øŸŸà¯E”„‡ÃÓ7,QÛĞO(—õ—Zfº-D©É”3SÅy­ˆ|MOÈ©ò~Õ'DeHŞ(A“+BóŒÓÛ	ÔîN(²Â½Ô6XìR¾Yñr5¡5âÖo\¬Xœ\Õ¤“X 
~xTÛZ?TäÖ”ãàœv
·üîéœ½FDWõU¶#(äÌ¬÷X=ü+Yµ…]ÿì‘ yçÅYxò‘µÏ•íUÚòD¾‡xÈÜwí¶x7äuK€O>M`yĞCÕ,\l_nX€,APùZ±¬Ğq5¡‡˜¯íe{“×Pè>~Ëü€B©Ú<“'1ì6•¬Cäİ—¶Y€n¿è=y8“$Òc’ª-B³¯ó#uK”áC„—ã”Ù3FÍZÖë˜Ú#ˆU¯È»7]ö{¶‡'2›áûE;«Éİ­Ãô%\   ÖƒÍ"ëæ¡¼Ó ©x¡A‹3pö¢'½¾CuùTçO¢ãQùu8°¸nÉõÓî5~ö ŠsîÚ
U‚ëÒåĞOM­˜uÜ/¡ú¶¤Å¤	OTñ¢Œ
fVağû†²‚ÈîrµUs~14¡¿“QÆË·f:?@gø‹¨àKŸÍX)Æ_`˜q¼=°æë	–,jÏ¬¨ºüœ¹@JwèÊ~6È¿Ø-„!nûQf0†=?S•jàF¸uÿ¾oõÙø-Qğd‹ìëÊıyµ~SšíÎ*wN7a×7†?£Ï¢F–¢ğNÎú$Æ±$ïÍ_ÄÃ
úîú3XÉDsöDİ@Ñ.¹A<ûCg0CMØ	óT¯ün%j_×Á½öË³Ìl¼.äV³*/<èvŒÈ÷cDv³xüåÓ·/u!u†{·)Ì&=7,®x÷¤MºšŒ}ÆÙK¢cvng¡†€r5ïÄ~6ªk+4k®ï0/c¼ò
ˆ“šrşÛ]"áŞï7Š½£'çévM(á+>¶I
¦KßfÇ„Á¸á‡SÌÉ TxV¸¥T	êÇáv“&É>å”«OLÅNl5Ÿ)O©2Po‚m”åt9OŠyOºc…2ÿ—„£Ä[‘jÓÉ"¨<¡”´Ç<ş›ÆÜ”­jú¤S˜=kšÁÌŒO8õ1ÃûMíº¯¦Ovùƒ‰XYBpûz4  ?â1«²fQ–¥j¢ÕiÈ@HF’‹¦9Û	wO‡ÓbÙFöN5›³×ËºşÇT=@ú$ùºc°¾Âğ í	åš#J®©È;(foÉ%bŞ•R2»ü5Ïôl¯UA®å®"£pó »uó¦«ğÀfü? ¸¬Où`ŸË•m]‰wP@P#&ñÜ 4ÒëÈÉ$7‚°	0ÓÖğjUÑ¨¥ïÛv'*tj	C›”®œjAËu"“õ“èâî¡§ãLlÊcŸSª±ñ(ŞöÒ%Åx\ué¹;~	ˆBœ«fS°T¤l§ïfÆ±6;R>ZÉ_ƒj¼)—p#kIaà\?¹ù“–Šy¹ó\Ã•¡øVõ"ĞûÓş² ©’†U‡¡ªèúF Ş€²#æhs ^X”áé+¤`}¿$Zµïà)¯Ú¾í íü¾Õ™¡q{³ÚÓÒ#Æ.¯ÛO´{uîƒÔØ5Şçm±ˆ=àËUéÜ“ÔHá§~&B÷x>O?\î”„,&1õ€ì01„ƒÈj*ïØƒÖöWreeı«­_Z`ó˜ ~´Â‚b¿—	şüN[É)K@-Ø~XpÏ­IÉºİËóÃ_n’tRî'ZÔçô2Äx
wä²W%™í÷ø¼FntøÌÏ†…h6eäöQgB WüsàVÂâñ¦©¹QíèN({ÿYa×MJ¹ıl‚‚n•™í[W¬‰ç±(,¢¿6]ªUz˜3Ñ±¡X0NoôCF‘X4ùu4®Ğ®…yì^A`5İi4|CÌSZxk?pt†²4¿èó½ÿ”‡îÁ½o¨¾3“µ`¨:cÿ.#âdà£Á|54õY[h«<lˆUéYE®ödX‹íÓŞƒø‹(«¸eÙØ<O{ †œb'Ÿ3U’“W`ÜÏİa®Ùg–³$'‰`¾RŠôNëê~ÃÔ\9¹7=Æeby|~äZ àÈğÚO">NÑÖƒÙËİ7ÛÉŠVbºh2²¥ÈVÌ$œTĞŸ·Xr6œq0ô!.h³‡h³C…çx3Ù®Lq
ÒşÃş(Œ\9
1/ÄJÛ¾*=Ãõ\·GåŠŞQİƒÑîÚøq¬3€EI}4É~ Y³ÆÂ
2€)bcg¾wİÖB X1!äÙy¨SÇÀléß¬ÔÅƒI•‚;ªoÌD½|èçêËPî;7ƒ7=ãÖF8¢“’6:GÍE¦£g¤ Â: ¨ÀIè @{›ï¤Ñàgäùzc¯±”m2öPEÆSÙş1Ş”&„ƒáAÙÓòU®$¡ğıœ|Çi	2îV	Ãñê’›Áœ{G ­c˜Øš¬V
’“oÅÌ®|µ|Ïå\Ö·Û4²‚ÏdÁˆÖôm«›Xu¬:Ü9Ş>AE~°ÓM
Ön­-}¯Í|­|ÏõKSÈ×ä1ÉEq`9¶9‘ÀIª¥7şıÉE"¬.nooñ˜½ilë¼–G—¹H"•+1¡BÇ#¿¡j·_®foåT™•ÌsóÜ~d WHôû|Ip§oiU{ç’0ªŸ"$›å§¨èXb÷,CØ·³º³ªÍtÚ§‡ ‚‚g;&¨p¢iÌˆ¤>{Òú7Ûí/,Ê=³‘e±_ò÷/– õŸÜÍ“¢j³‡ûF¶¸¾KŠiœm'¿u,„ôƒ÷3ÇlŠDÉÀÚ¢¾\“ªa·ùğ=bW†şÂƒºü«Å£EDùvM]«p2²n:İƒv`»¼É|x±öÎ5z?¸ÊåWMyĞ«Ø<wÿºû]Éƒ™iùôö†¼™jË!21Sİ1ÒîHVåÿëRGW‹Š„ÀŒLÿğùí°K€¬X¸ç‚jœ‰]U³ †¨šg@š|Nw+š|±  ‘xÏ;²-Á"ÓQ	¶<"¥½HY^ÁRä*v_q¿ÁÁwS­³	à¥í9†`…K;QnÛ™´†ÂÉa4†ÿœÒáÛãÇ‡P%¶fûYsµ”
bD0 D…™4’pNÍ]x…šMhÄ»\†BÉŸ',?Ú§©°Š>å’;’îË3Ê—X5©ïà½Åíç!í64ƒÏ#+³š¤oóÈlV±^¢Ìµ"3ïb¶=M™®î Ç<'Ñ¾ÄÇ° 2±×à›ÉÔæ‹
EøI7Ceç9®9„ñ8 ƒ5™'iLà¨Óàö=³×QoÏÖBl©k´Ç1YO¨Ç}™Ğú]tê:S‘ÌtîsÖT§|Üa^íÆÑš’A%— bœ†Ù=J	€/ö]l¿ª’qkÖ:¬º[C@XŸÄ`L/§»f	ÃQø_Ğš(Ü)Å¸œ±Ş=•Oı¡¨©˜)ÕÎĞ\WûšS€±½†©ìÃ6oâ‰ŠyœïYû‘¤4éşqêÊQ</i­`â^rh¨gÿ5æAÓ¶º"oÿKÄ¹RÊ¯S‰ùÇjİ´Å½C°äû<Aâ&ƒ´
°mŒÌ
^;›U–0=É
Èñ˜Àj–ãdØ7C¤:2‘ü˜öqRúä¡-IÙƒOÀQ‹˜vÔÙ&Şói#Öä¿¤qVquJ6ZÖÖÍ¢}Æ*üØ›9Òì3Š½„ìHæñôì¤ÔœÆg‡Óï¬gÁœò®Šå‹.+ù™MlÎPÛğ‰pá"ÏiÔ5+iW™Ì—0j‚ŸTÖğjş¿ÕÌø·ÌüµĞı–\ŸwO<évBW$Ã`¼¡Ççø‚·òÂ%neÅ×{¢Ÿ„ëÔA»16‘‰”Çïüú7UßpÿHn¬ø;ÙÁíPHpØ‚ô*ê;8uŸëåÓC§%»Û8İ®î¥H³ÍÁ5İP¬“MØú‡•şœÌ`yw*%úÀóå|cüË§	a’$ùòóĞ¿8%R‡î¡i.u¢9 fÿ%Ó¥j ÙÆwû®¨«*Åä†XçO_M5Li3´‚¦WÇ3r ¦81øK”»`hJş_ ‡‡~„·é28sKD¥g/¸¾‹JC‡ò„¿‚ÍvM$‡èTıY©¾]x8®`¨bÜı“pRÁÀCj¬…‹eœàË¸¤}Í ÇGCO’ÕÅ86çîÚ=rJ&’f2kUí?
ÖŞó
Bˆ%ß”»ôÌ2;}ùYYæËCÀw1¦NS{)4ôåíÿ+Ì‘ãá”²1e	ø~Õ}fyr y¯Í$ÃĞ­="Ì‹ÓŸÄ¡xñFí,`ƒw˜¶NWUËÉ·éU×#H‡M?ñ>§O× £ ¬ÇÓA¤UÊAÄ…êùøR·ù¤Í4e_Ëgöşf,tg7ë[‘oŒúy«9iƒHvv¦ä!ÂÏ€ÆƒÔ0M€L;e ’¬yğ‚Ùe?!i+á4ëiÿÂ!ß‡˜Ö»Û˜­2Ş¾mŠ“7)³v¡em ¡T±_ûè„VÁ$ôjÎÉP¤
£ißßW£Ã11©l×çŞC¸¨)äöÚìÛÒqOÁ¬BÈ`q°¡™Bn‰ç-0Eù”ƒ×D€àÓ­%ÀĞ‰âìj!Ì¥©x:¶M³‚ÖQUª¦êSìJ2â¥7¸ÈSÖvR”\¹îB{÷ÄifEÑÌA~<)ç. L>ğR²†™LËHZšÄK|•õ¥—|”›Iï‚êà†>"ú¨ºÎ†æşÑñ7Ã#Èsı¥´C5@y{o©A9¹¶.Ü[šÅq³M"…ŒtšD`Äï‘ÜÔiø6Å\îmamQ8s%òùZ&g®SnøÁUúææ|ñ\ˆAíM|µÛÔN—U×:¨é\ˆ×C³a7‡’@}Gµ½@]G2ÿ@7<Õ´Ò5âhÆ¸éª¿|Ê/VIñÄ/•	K¢ë¡‰ ¬ä¥ÍèÓ~,“Ç¯ğpmÌ ¬uŸ½	b ÄŞ	Ş°Ípc",~>…â( oŞ¹Î¯IØöqêŠä—Â¡.«sàÑ“–&¤ ³á˜_ôn$‹À^w¿ÔÙtÙ½RêR…dKÕ•Ã7Š£s²f¸W"ñ´Ê§İÂS
ZKXÕQlQÌô\ãf‰1³é/˜¹şšéÓëïb"Š„FDh„÷¾ì¯°ëÄsCUm›A¼„Çi¤nòŒÍ`2c4Â¨v7]³Ò:¸@8¡ÿH7’o5…n©Ñ+ñK¸_öéJş´‰¥ª!œHBh‘=ÀåQ^¬H‘Hş©Oú“|N‰Ç(å@]Í<ì±À•Ôe±*êrË‚O”’9ûOè¤GZdNmŸzºŠ&B´JºÀùp-ÍUÿ°aÜ}ÅM—jÊÁñ¶™ÆÚ¼-××ïBØ¢¿}şúÌM•òv©Ehµë&\hÜ”Ä½Ùb‡¾EN9Uî›É¸?Â/‡)B'iL÷!(wÈV_œE‹rhŸ·pIëµ2Ÿÿ ¡&ä>6İPÿ¶¹p‹Ì…ş[»&Éö[øTÇh½Ëâx&cÎ}Øuû<¸Óá`¥ˆôéx*}%Ææì€tÈ8ØlÃ†7}_}Î›¢ëuÀ5Ê“„}İÂÁ’ôÅ¤âG=´™ş/uŞû?®q¦d4ªÅ}†X:y×ğœğF,şÈF×/wŒã_Û`(ƒw{
Ã}¸Oˆ(ùĞÚBŸ+™eŸ_	€Ğé¬b2ÂÇ|‹O4î(ÎÁ—ı8•Iˆ3ÈíO;„iööœÛÃNŸ†Lv)sOœZû®f)ZV;m”_REÑÌ®Æ‰bğt‹Vêˆa"RêLC^c˜*tWÕlÊíç[™ÿq¯!M‹ˆßµTï»ä²EIªN½Šä ë¡_éÚ’ãk+05x¶‡%–±‹Ëâ	@Wâê˜zĞÈŸ•¼ Zù    Ê¬£G¨Îá“ ®Ï€„¥­±Ägû    YZ