#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="929256112"
MD5="cdbea4c1c175728723240d3c64b187a3"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20572"
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
	echo Uncompressed size: 136 KB
	echo Compression: xz
	echo Date of packaging: Sat Feb 29 16:54:43 -03 2020
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
	echo OLDUSIZE=136
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
	MS_Printf "About to extract 136 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 136; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (136 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáÿP] ¼}•ÀJFœÄÿ.»á_j¨Ùõ¤0­<Mˆ‘‘Ü•êÍÊ˜§1ï=÷¶Øì•l±ºûN×F­ĞúplÓğ¬¿Š·L§.æØ‹’¿LI„ª¤Ü‹×´€AÉ*äŠ£¯-zòùÄú¢=ü¨q¸H¬“ó	ïb&İCåø™³ï1ˆZÿ®\¥DZq_u¿½Öàšm°ÀŞØeyÅ¾JõÅ¤2êX
½E>&JÚÿãÇ®ÊÕ·»;µÍ‚MôÈ·½ĞªnÏƒ»ŒùÀ;„ÖŞiªÃ#³’ ª‡VxÍŸÊ^/×ÿÀ,;´úï¾§éù#„ˆÒBÈyš'–³eùLIäDìë/Etr¼»£ˆE‡0pxf
	ØÎ€8ÊĞÕè‚K™V3Õnšúp0¾Ÿ5Jú€âğ˜F÷$´èCÛc€¢+×™Ú3BSÎÕÔo×åôˆÉw÷Î:jƒDKÿÿi1'`rÙb]ıÑÛåÒH@€ˆ/Îâ˜!
x¦ÊX½©Kù qMc¦Ø7ªĞ‘ÅIèqò­€†w¿8ThLîVò*¯4/—õŞHŞû+â;/ş`¢€yÿJ€û­=dSg
ã¥4œ3¶›r•ó|}@CÄjU²Ÿ¤ ÄE¯àRŠAæµ}í1¦Ã6„’É–Ò§¯1îçjÄèßùJNTµ.l/QZIr„wwªOãğnI“²cÁÚ%Wh^ê¾Ò˜½Ëø.Rƒ}¼°Äú”‚×i,d‹>ğL[«*pĞ2¿è¤óÄôäím]NÆZd Q2aÅó™e)ßGóEÃª®‘üôæú|qÿœ¦&Ä’J&e6^İG0İ†¤	Ø öw¯nĞ'x–<ŠŞ],7íra‚&Imâ}(EZ!oöGÆmÛ¡s¬dc ZJˆWšIaºŒ9'~–}‘ rÔı£R”&à¢O	ÁS§$3´[Ğ†Ç9ó&¶Så~œy—vA[öj»&í€]s¥¤¶]îºue½uíè­ß°éú­É«©Iÿ;ªÉw6j9°y†N5Ê¶Ş_‡SB¶6
ºü6[:u¬×ƒæ2ÿÀ)´»ªa'[0ô1åø&û—ãÌ´¾®†ç&íÅz9Ã%©»|"* sëÑ†¢üpå@¢tß8¬¢O¾¬Ò$¯¨ı±–1(U«eeÆÊ¢ò34˜bGcURüÒ2Ò>W;¬‡Ï~yÁå°V“”šAØ’¥õø¾ıU€H^,byş‰ôCŒáiR/~¥ÿe	Nø5à—š ñXó`‡öaLÀü2H8àÅ1T[¡ç|Œ.#übşîPÅ¶¿Øf»œ’åÜ|Ôi‚ö¢õêaO­•íÆôOl…¼·~âü³k-hä€…g(ÙSĞ9o¹”Pnû1¸ OXc¼åÇ¢h¾#ùwAçœ+(Í
\ËOTä®~w¤·©±`”@Zø³b*ïZ)³zÙ1n_l‰%ğ7„?ø¸øÃR@P§Ğ`–AKş©Ç{ËF¹ÑG€ñxÜò0Ü*äuKµ—•O²ş…ÆvĞ`m×Ã—İèõsnãJíĞÂë1/D0¾²[ˆõÅRp
­˜Åœÿ¹Cœnm-{øáà4®B7¤á€û˜@+™Dµ²TÉWğ£+E™¿²E	ßu§ÅY Ê:§½î£m}=7M"ñe…¯ø&Ü2ø­a#ònZD‡Ş,B'g†=eò«Ötô¿
V~¸4M]0¤ÏˆÙA—äÒùgp7Âa]|o+¢Í­à5oÅ&6*{ÙEê¼½´…e›=<&ak°d|[ÖÈfú³yb‡@Âã·ZÈ+ÅdÛeçöY1åÈN½1n.)¡	š%'‘ h¾	7Áí›}–çÑÉf«ì<zR].¶À£QúXfåF¢`Mu»G³2j¾a C8jfsym•°z`„%ı!•¾V†,Wñü©,ùiaÓ¹•S¯uI¥ÙqZ+Ç^ãÓ£ı¾˜í9’ÜçœÕ‘qXCi?ã)É?u7Whò§!¶Bç€¨IğH Ècˆòìš(M!\ôn±û·K¹Ñ"Ò>{¿[ƒ‹ëNŒ˜²îØNxÒdw÷°¿ `ù¬€%ß}~%TO'Çù<*( Ó£°Z1­Ì+ÑlEœ÷ ?âv'‰kÚ	é”“İ¥SUêø%b¢Ê–å‰t.ó6¼x¢y(›]øË­uÉ¿Ô÷^OC#iP©ã¢(ZÃB[á¹àzIk?J Té}{‚w3Ãì
p,×ƒ$€•ˆAYÎtÄ¡—gÎ¶0wËÃ˜
p[@åày+«Ñ—ÍÔ1Ã¦@8XS’µ¯á$Dw7Ú°Š=šˆş«Bè•j²ø!`™G-vdÄQ‡
WdŠøœWƒ¼+Í‡YÛÍh£—$VÜè%Õê¢.ˆÒ¬K…åWXÏ¶×\°Ù§ºdæË€ˆÉÄø†\Ú+†OğŒé%Rwç}{èLØ#J(–¸âOxä&-Aêça	Ó?NÖé¦:ñ¡×pASË¤d¤]?‚
]øåÈøŒa­‡™´¿yœAè\Š—s©€›ß‰©:SOË¤%$Ä§«A^¹5Hdx¥0A|ó‹¼¼áOwXÔ=%3I÷CRgùÁÎMgmAëJ·ÒO·cÖŠĞ·Ó)®OákzG
ö·VuZ¾ÖF,J[y-Ñw‡ç‡ò¾]nr¦nƒ „¸cÆqÒF´JQµ™NB¨Ü$R_wÆK +y9ë‰”Ç\TÇ‚oß
2w<û«×b3e¦bâ0Éğ9­	Y¨èxu€Ô¥Ï*Hç •ÍÿrÅÉaš%4–Æt+Õz¡t9¨+nI(Sİ¤B+ş&¤	 Óï5bîÙ‰—ñ7± ¦·RÁÒÅJh\zØğô²Q92ĞÅ^ÑK»ë™}Ñ7‰kòx¦ïÆ|Õ1È“õz›¢±‡`ÿlÃÚ»èF~Î¢'ßğ6[<¸%5§Œ}¼ßèÏø°€¿f¤MâÒ#ç¼‘pAd£‡Ætñ$ù.Z0êæ¦Í±.–ƒXÿÏ§~=’‰Qê2h'7ùÕ	µlğgñkwå„ª˜#*$r,^Ïu¹w›ÌÙ…ÛbàD¢»ëß•4Ôı-ÓéĞy¢eC Mƒ^«'y0‘óßzf¯yB;ÑÆs¡lqH=¯Ao‰Îdc|ÀiæM|Lùó>IrzwNÜÍšW9äÖ ĞìBØq#˜û9Ğu fü&FÃ'™á³Ü“¯ÀwZ¾C}îÅ•™c~î¾á“ò´°_rwïĞPü]yÚ%
îĞhlûçôKıÿB˜Ş-õ~éuÏ¿*•­eÛÁJZ¿GMNDŸæ!·mÁßÀe'.s\¥}ì	ßC¡Ç^ô+¢c‰Hv~]UfZçFT«ê†l.İ¼È^3uÅÂ3JÀw.¼–/;Òó.3/‹jwx“8œkhıãÀ/}gY‘íz¸×7æ0où^SH›™ÔŠ¼!±ñÀ4Eˆä—ä/†`ªÁ9?åK´Š¥]@çz¥gŒ¾¼i¡Æ´û`®C-¹ ²–fW6¤gÔH%şK­b£_àF›ıiHõ±M°Í›·‘È”JRÓ=Çs$2sœäÆu´Å~ÀdßfGÔöô€Aìä`í¤}º–‘g¾íb£\‚Û½:oĞÚeHŒW’\Á³Ï{tØƒ²î;½@â×Øğ\òÍP¯ıü>üúg&ªoüŒ°¥Bw“€|‘ÃâZ4\†gåĞe£ª—h/¨ıÕ½H‡¯E@Ôi­œBu–ã|9ÆÊC,ö§2’3|ÚCTAjQê&}ÃaÍÕ,Û<Œ2FßÄ4ÄSıÙ´0I±/kÍ¶¾@t’şÎn \ÁiSß¬Pûàèj×zÊfÅ¢¢HìbQöåçÌS×T[ñÃ\TavV«ÒışM ×4èÙsz'f—ÿìµzA”c*İ(œaÚhÉJ¼O2çÇ°s>³¸ç¥8ã¯èl=øA´\”Î]Ó2%°êAÏĞÁ”Œ2KC\æPİË¸›ÙÉ´dOŸêûÔlhgV×*PëaÕç°šærŸÖµD„ûpº6•ao¥^7³ÅØÈz=|İi€œ)*‹åõ±îbsŠ¨+€¬ÀòS{CöäVàj¶¥ºÃŒbŒüqPD½-ÿ¾à$¤_‘êX‡ùP`ùô,9ú—'±H…}ê¾‘l¥£ƒ5¯vŒSşK6Û„Óšz	Ñ2+Ù-ãã’„”Î"@<k‹iw	`jfV§Ë_»y‡?æñÙj¨õEj¼OŞ`CÑä1ú¼3HeÜˆ}?û{Éú#ùA]nšD.;9ÑÜI–3	îÙuB³ÚÃ€`Ò~½ZŒ†Æ¬Ã ­cd]¼ºHzéØ6¶Ùï6S{ßçĞ!}l•Î&zğË¢Jp¿XÄº•§õ5ïr¿L¨7
±Ãodß¼ñ]ÛÇagÿ_Ãøâÿ³õµÖš*{4Ÿ~°0ı ‘‘§ÅİBK•ËßÂŠd?]8u½{Øñ8óuÊskU >ÿğ~Ö/©çÒ_‹7¶ãVÿç}m‡áë3_”ÿOz¹Ñeå¢ñ}¡Aã^‹Û'³`LxŒ Qš§»o§›óG…şlşÀiŸ¦İzèbwuQÛG9
	+*f¤ìs›»y¨3İƒ½À“2¢ W)ïõ+4]/4ù-E§ı¹‡S­['8øRÿj†ë
c,<¨ûféH9Hx³`¿aY„Q
×ßngbù¬ƒ†aöõÀ9 ¸Òû¡€Ayta91Ê&N˜!®~8À»Q±—
')Í»ß^‰ñ&K¦8­ ÅÈT“Tò™2•Eñ¯ÅÈÑ›ÂÏ‡ˆßÅ¦ì*#švÔ6X	÷=½Êg4Mãdî0Ã2+$”=º#¦Íˆ»—GèŒÔ÷¼lüvóÆ’/gš:'=vRP"cGR)èß)lÜA1Lİo^¾}ù0ów¾
5•$õ}
¯/!Ü­W¯Ç0ıeƒRZ0g%Áõ¤õ2qô\ªµÅ‹!«t}Ò
Ñu†Ü ).dÅÍpsÍO Ûöï¯1Ê»Ü{Šƒ´Ë¬¢¤ŠEB)'™.‘ÖYì¶Øo2€BÑéÕy¢ÍÉÄÃYçê–0"áûŸqúëmÑ å¸¡ªù=hW)ÇúRàÈk±ˆM¸–šg?»BFd„‘T#pù>¯àíì ºûÕå…­í5µÆ+¬RàW0_>¸UQ¾,£ÇØKt"ÅÓ”êx(èŸ×>zÉ;R¦ú—>ˆZÙôbóÊ‰mVpv0œl~*RÉµÏØ‡/HÈİ}dÂ“—fFùÜòıº™•­ d`T²]â`LM—¢¸.×‘:RÚá”¥¢r×¢ymö{ø¨;™RÁ»âc\tÒÙLØghùİv@–´ p!'o„ÙIT¼Š[iCIõÃsv}FFóa•ëß_©96*ÉÀÿ9ûóê³ßeq›|¾ñ,!;êF'Ö¶ñêJ¦3 1Õh*	çÇ„uîµƒSf"åWìL¿¤Ê4\çôâ#æ;Ø¡zsô.$Å.(Æ¥×@·5˜c|İdƒ®éÛc=lãIêïÂ9¼Û1'åfñd¬¡G¢Å@Éõnø5E gf„‹X/ŸÌ`‚WÏ]“É.?Ê\¶·Ø£@Xhej’İh¡‡î
M<o@©ÒzÅ]î*¨.>‡¨®Ù˜`ƒä#Ù–(°ÿS~XG!<ìåv„"Z&¸I;·§?Íœìü£3^2n!P¿p{[°z˜¿Er¦Ìdt‘ ¼V?ãÔÇqÅGuŸ*Z0Ş*š'òQ~Ç¶ÅŠ|y<wIÿ™Ü¬‰ñô¡Ä2wÕh,¯¢7EÀ¹ÒêRaÇÄ¼%û1 ½}$KVø”-õB)“øå§“'’á8øÄ1¼¾‰×Ô:ÌÃ£J®@VÅ]Âˆ|ºH¶6já¨ XÒbáoWÇ¬8td…¢RjÄ§?´á=_ÜÆú 2× MŞÇoIĞ¬0Ê¤IŸB]ã [ñ	+Äm·Ó%WÒÎÜ·¯J}+§ØíT‰Ø/‘ò)"õiV
¤1wÙ4à+Øİ†&gOqè‰h<ÓIT«p04ÕÆDu•ş·ĞxI"½) 6¿ä¥âziüFş}\Š9a»Zt°î¹S(âjä±ÖToA™‹ö­u—3Í(ò¹ä`q]ê…8€ÏÂ1í1ÒçmI¾Ñ§Æ¬«d¶Ó NÔIÂ4†@Ó]-¶Şi0hjov¾À‘y48üOŒéúPlZ¤gtr¹nø¼—è73ñäÆ|$7Œˆ
 RÀ#Ù¦¦È°ˆOôÉ#ÖæduˆtÙx[€-B	˜Õò÷HÙŞà˜™>+{qÛxáHu´¶ !UKN%w	İû†5'É½ÔävÈ‰˜Æ †	@¶/GÕ§ÕªóA[®4—DB‘ p^dm3 ¬ã¼z@Ó¬Iğ}8ôï€®0sº ™ä>ÿD XY!ÇÅW›&TşT—	Ét1€…2ÑüÚúˆkÔ—*ú¬œÈFŠ1îTøÖÁ¹á÷ZÓ« —UNìÄ³tŒYáV}Ä×Bbˆ)Xé‚“-¬Scüîÿx•Û–¬Ouâ•}+êÕ¾•Ş¢yµö¹˜(;1ã†F÷R××Â9_u˜ïVŒÅy¹bh¹î3¯eöBÃ„ÚÁüĞï£ƒfN¹ô&îS:‡¯óšö^/ä÷È²dqİx“/êFÒb¯=i16í	ö[H/ÎÿŸZÂ0”—ÙÔ ŞÚa^¼À7Å >-^¿	kŠØ…‘ô¨å¶2õŞ_\4ğğzr\Ä²&rb	ŒòpB^ÁŞEÏâáÊ0Ç£.Oİ4òÄê'şÁf}õ{-$Q^ó×‹Jçó—
T°ólÈÜŠ\¤]"K5"'p0D~rß1ÿÎZ*Ñ~5ü™ıüc€=EÕxë9ÄF_eÑl%7]|÷¹ÏeGÈ,ü€5¡›zaü‰.…^Hw‰Â¹Q¼‰Ü[9]
%Š@“"Yğº‡àPÇtØt_ÑU?bÆĞíÁô‡¹càfĞÛéÓÜË	PÅµrËØüü·q
7„øWÇÕşô&¸£Ğ™ªxºK3ÿ~sME^VÆÉ¯´…â3 Úëõh+p!£©Ê}‘”#½ÔÈ„v79q&ÁŞÙŠ%EP*%ÿ¥Ç9V.,Ëc„QŸ¿òÊ®½:5Y	ª^—Äç|àÔçÂX¢ˆQºæÜX+=O°ùâõ'Z¯Ït*—[Cÿc¬Zó´èeKF/YìÇr09å·*ƒ&Ag½œïºÍwÀø²jØïŒñÒVÔWVu—Z5M:6Ë­ÉV	ÂáE^6¦Y4‚¸.ü3p`’Š¶GTñAî%^ë“ÖŞ¥}ÏAgqü+jêkä•$Ö…“ŸÌ ü1œlT‰Ä{$k;C­<ˆ.œ•p­å¿¹³!â}A¼+Ã$CBà–ŸófÅ¡´e§¡rgì•9í)ÆšÄ4Ÿ4Öââ™Şüs¡d7¿.ÊBeF„A…yãäsd »xhIwúG÷_Nş_. ³3ŠÓb¢,d.gUŸ+÷Ã7ŸÄALVĞNŸ¥Êˆ¹Cò1Ææí<[ÒDµ^LVÒ™TÈø.÷6“.‘zjP°c%€éê„?X\û@ÓsÁó¡cÔßRF
ÆºÓ•­}Bíï9¶[ÛÚ„}’ïee`¸ÿ%‚œMK¦TÍ¥Ó|ßXç5Æ\@œF‘%1Œà"Õå9à˜H˜İ¼ü¿HÉ*)jêJ]Ü±*2›De±‘bÌğ,pÙlî¨^–÷Ké©~ŠµA)£rs2f¤JHtÇ5÷
mÚa·~ğ UåóïI:ªaX]kZ7`„è¹¬S¿±k—A§Ú¥¼\ÅÒyRK;çÒ¢/ŸtgäÀA$ık˜iĞ¾Säˆşg•«üÿ¶6= İ´;Ì¬Kn§ˆPpèyxJ«ı`ƒŞ¡B=PAHPWäƒ¯BÙàÒz’€båğ‘ìó¨JDÒ·ã–;S3í1ºÿµïXá 3ö¿L
~ıt</áôuáÃxQó$!(0Ø„RªB†'÷®mh41Ö”Í‚S Y†s0µİ~õ~aÚè—O—‡>ıß§q¡›3ÃgÊ;vÑí
o÷áz•ØÆœ€¬¾tĞzÚâè­UâÅŒ·ğÍl;ã²	ÒÁ}”Í`}Éº'(ÃÖ¶ì¶ëÖÿŒ!·4ùlxşrî§ƒBb¡5éÄÏßcä9ï!¶hì>Eqı?¦¨‡p5y<…´›B'ù±l±*\.lÊ÷åyè?Ã*¡'-ÄŸ„ÇÜ›”ME»R-8¯‰òœmXd–|0÷¿§lyğ6æ_ÙÃnü§ÄàDs´YÂœ_é•x¦ß*j#–Jk×gzUö5‡+ ²•Çšà¸Ïb5Ò–.ŞôêQWÅgÀ¤’fB-H©_jĞÊÀµI*ğOß94êÍCˆ²š²^½ÇB|üm»	şŸÄ8omØôœ«8î*×'‰¹Œ—qDòNC5s–/|æ¤
ø†½ëà9l)İ¯Ñ+n«ErëŞPêNh!µ—ØtZy¸‡şQßoú æMZnT´™Ö“ç|ìì‡®EVáxf_•QßÍÆ‚×§¤íp4 šü[î(t	ôı*¨  5µºŠe¨ş‚8d]z{ó2
ˆ{½)@JEÿ]–Ş£H§/¹ı™4JWUù°qvF‘µr‹¶åX›[VØ£Àuø`Íù¼ËAŠU0Í" 
–ÛlìƒZIFI¸Z¾B›î­ÜR«J0ª‚]ù¶Z.ìÁ¥{âc‡»Õj$cow\¬Ë7­­í/0/kÂCE?}Á[«±E‘ÎwC%ì‚şå8½y¼G•å´Ë¨‘c—1pïæ£øİß<ô9R
Ê$<KËÄG7öèÓF¦zh§Ü2Âz u±ÀÉUìÒE<»]æ=%$“aa½?UµÅ6dwTÃÍ³=Œ‰”ö©™NÅ8¸º‘fä/EİÍ×Ş=¾µr¶`„5Ø`*•ôP$ã?míN×!S°%P•oşh×ÿÂÓ0¯ã=k§áï×êĞËbê,iÇÊJhÚù´3\²¸&L¤XÕ^—}S%´"ryƒ0¯ˆO¯Z²‰<Ğ½ª5…ŒŞÀ®Ò¨C:iÿzuéœ¸T{gşäëñü^ú—€õ¶—;ñz12‘d1UFs‘!`˜ŸLËÛ>ŸîUÅ8ğ_D+—¦~¾?`=ÿ.ƒ¸ÓCõÍ@ÕÏí×‚ŒÉ}ÈXù}ÀÅ¬Ğ‡\Oó
s¿†íú;tQTåU§dÜsùÔ’÷Ü€rZKZ±OŞ\Fº³æß*Bê»LogıÚ‚9´ÔAÇuy}ƒŸSw%Ş…ÕƒÒ¨¨ÓØCgÑ]Ú²œX÷F\^é^_$ò0ûIFUö×æ“½ŒG™6F¢W@3¦ğ„ùÏÁXPœù|Wê=_æõ¥ú(¦·7¦u32^,ò6X )<¦8bG` ÏçŒ@‘OŸ|²İD<L]	¢ÈÃYëÛ5 “UZü\È¡ÜGGxIÆ8oUvØtoÇùqx7°€úxzËHLĞQ¯G”¿ÓšæÀ¨¿Sà
®şîy
j=ñ¢„¼€m]5‹ nİI6÷1#«;‹šÀ™<û»¿q.À—iİø=JÊşgá¿É2 `8ßétfHto=É–›-oîÊ2ı{¤pÎ«Pº •4^…sÒ3ñ¯×“ëşE]»¨­ÏH€Y®(”Åîßq(qDõíçKAÜãÉ£ù±êO‘a™ÇÂ;ê{áŒ²öêŸo.«ôn¹w˜\½æ‚ÀBğúNiâ¶Â03OùşÅÖÕaòæ²™_Ş)—5¶W<PóOÄÿû¤ÅAÅµ(\>‘}tÅTÑğ|KÏš[í/LP´~dCšÔ	BƒP¹•úzwy$©Õé€ı™Cd=Ê	4#9ÌøÙûv£ï]{F@öÁ_®¸ÏÂâ©N
¸Íßƒµ‹-™,?°…Lˆ, ãÕøò*¾ê¼¯U…:ùH«
Sı¹”ªÔnªK–¥B8ù§ãÜï/µ-÷®9±„¸³)Tvõ£ÖEYÓm¢®ÆU²`O€:S+ËŞ lôşE¸¡ïk@«z´TŸÉNÁƒY«×,S7%_¯ºßÅ»¨"„~vÖÍµ‘6ÓÌÓlEçz²tíÌJ·wërJÓì½Q¿_hé2$0±Teÿ‰
 (?Ğ4!7Ÿ0b`¸f±ĞqŸLº’@.–klß,5ã&‹(Lfz¬tYHØ§¸å²q/h=§¯	Å, ’éx0ñõÊp`»Å<%…$–´HXÌNz`Ê\²g‚ùşãÍO6é JM¡¨âd˜¯Ìë[~Fkˆ¦‰†˜³P C"Ï[BøI(Ìi/è"C¶Ù– È¦îÓ„œª
Œ.E¿¥²g=‹"Ö‹ŒOò>’zúŠïcì"ğkm›WÄÖÏòŸ:n{?#V¤§¨<û¦\À±ê .\ô‚©A°düMF!0Ğ fËvæèŒït?ÁËñäUYoô‘^Æ€+²HĞs¹ìU^rZtTˆü…W,~ZI5Y1ğ¡¯{ı‰MÁÖ£ú“ÿÜ¬Ï^ùäñ¡öF;!iF¼7›ŸèÇÈ(óñÙs„	ò#]}y0E¼Àò>ğ;9–rgV'LüŸˆ¸¦?ö'MAƒTâYæÂ]m÷¥Y Z)eJ“ªÑäXÎŸÏXDkèµ¹¶HÍ¢.š›^TY¾cƒÓ,Óñôà\à^ú7ŸGj§[JÇÙ-zä©ÔC}$‰bKƒı£†– Gkfñaéqrõ ‹_úÁtîÒÓ÷ªI1ƒYÔ«	ª˜ S%L-Òğø·½Bî’]ñlÓDÙI@zAJ–Äu}_Ë®æ—À¾2+Y…>›Ù0Orv„çsZ¡+OTÔltBåD³øH­5/Ê³eo	K±v¾¿ĞÈºÏMEøôrRPÆåşƒ:²¨”Mvˆsi§¯Ş%m$_ÿbA¬âåÔCÚ2uV‚¿dÖÌPeŠİ³?ì´×xEÀsşFYØÅCò›bœ[L)&ùÆ>Í'br9J&³çà³zÌ	¿]ŞY]¸yOz°“†wä‘wZe`ò´ş7™}![şø­>¾ÁL‡(Í+myAË_~NFğ9©ã
“¤i!GºupÒò,Ø“G+J“t½SÕ\5"ÇÔìÀVû¸¨o±BT¬Áğ¸Eâ™°¾MŞI¿y÷Ãò%ñWœ‡(õU1…Æ;\e|àwÉOOM3ÒïMeÉæÔæª[PĞÆœZ1ñª\–Ÿlãâqm¦aãH÷a™Š<EÙz‰™/G‰~H¡~©DázpÿiÒ@æø|n¨}˜X·µçåfÿºc•P©-=Ÿ(_2tŞdíĞœÿ Ÿ=E*)>_Ü]2ofM:ÿmåÂÔÕoTÍ^D ÿ½èã~ñ¿*3ßóvpñ¸¾íV)©Ï9Ê¿>ªFgñôf2|}+Dü=,K«A>wv<O5~¸ÿm¼É@]8­‰öèæ9Äû*‘âù—1—)¼Y!ÖE$Æ?Ã‹T»¤ÎXô	œ3/UãRïşİ7ãY	åw÷Çìà£É~™^Q.{Ä ÄnEÁB7uPl«iåËXuP2ˆ®^¢¹xF;Û·xLŒóËÖ |ÛÑî³®Tÿ:äı3H‹ç†¸£½X~øN‹ó²gÂ‘íñ˜GÔQ‚„¼Nï‹R©â¶fÉ™ó9ğ‡±ûCÄ¿`C;hÔÛ6¤ıºèíYÁ@$ó…Âğ%”"œãE×\= ê2D…´ó#ÇÈëM]N@ÀÆ+ü¶æ-¥kÀHèlâb§üd6àî©U}jíE¹*ÁÒµZ¿¤³†:"¾QóŸ?û²E€dïx‚6TA u°ì}’İßÌ„¶·Ğªz’¸;*CÉ^GMgCø.Ö÷SûpE\@=ëšU[g=JÏ(Ü(
…q†fñx ¤ıu½á‡¥n gzf×œ=7-î*¢ãO}9*3%Ã.97 Cpé‰Uêñ¯ÿ‚I­Ç¤¢'æÅ¤Î1Ë†wTj_<æÅÅQkåLI²kÈ¡4éíÉì@£_wºş=¹ïĞrËJbh¼G©Íâd€§äª?fè­,±UsòvéxÄ
®ÌóB™¸-U}ææîsğ®>XìùÒÆ:„)Õ¿ñ˜îÀ…áƒûª§®>CùHm9Æ|vCğÇ‹4ë0ŸXßy™è$KKåtZ!—‡™£B;¶a¿L> 
€;©ú+‡bÔ’Ÿ)>iÎ®=q	zGWbDiMåØ;+£ÿ|Z!-\Ó¡ˆ]pZ?-;!Ñ€àÎµœì„ø¬Â3Îj€j°¾‘À¨³9`)î«t“Şn‚»R¸>­(¡2´Ù¿9ÚAHy¿
rúqõ-–ò6%Ä‹‘Ÿ8şÌç&‚mı|íIÊsèÃÃ­<[å
J rÒh4¾¥9ù•“§ñá€·Á¹@µë¡1¶Ú¶¨kÅ@Ú™„Sğf/Qg,>{†,NÍÚ®©s'ÿÿFíù5ôÈğ}F¦Œ=¡J"ñ/œôvâ9Ñ9,˜å§ÃŸäÉN6#s‹M‡½ßf K
4¬å?E-°XLd)åÅ.*–ƒšàÈ×¥dÈVG”bõb.ÃÚËwµ f£®Ä?ÃŸÀşÏ3d­yÙ(·£ûDgÜå¥ÇÎ™¨«D‘ÕLØÚ­
ššåÂ5°“°(V*†hÁwâóàK¶×víœ5ÿ_·Æú*â·'²|nDÜœâœ§-kîÃŸN|üÁu¶¸Ó*ã|Tª‹Ö[¸+•7§)?:{Àq¾W‹I·â«‹®U«”&—µø‰x%*¹ç-™>Y44½¯X8›ş6’aÑÀn`‚šS¢Ÿu€Ğ×¿¯‚5‹Ò[\n9*åÔŸ/Íÿ¤Üp¹1OïPº@#H“¿[ß˜ş “}\Ïí¤ûy0>p3†‰1³Ç9ş¸^£É ¦Ü¤ö­ZÈªHQXã]~Ï­„8á¬Rİ!‚¶j÷¡îô[evˆ.9øõf5Ô‘ˆfóG2@Éo‹4«F0Î7jGé°Ùô‰OÌóª,6ñ¬à­+„å°ä™´À
‚7uÖ{­ÁË_—İÜê¨WƒlÄ™Ô°>yêF”1q£¸Ïğ0ÖvÓ³¯ab’Ú¿ ×–'‹˜ş|Ã9,´h¶&¡ı²†Çà¨;Yë[Œ—Éñ^“!úñ:G—ß«Zş–‚÷M¬¬½­Bo@Çb;áiÜYi-l™GØİ÷D@ÑoNW]¾?Ø‡ÀÑæ†xSç`¯ZÏ¢“±¼Êå“+¶ñÔï&›j%àLKú“š	¾ªÂ€ùgA»¾hqL”JÔS
ì]º#„×ÿÀft7ßî­ˆ÷vyï·l¤¦Éì&3Ô¼¦å–÷ySŠY†•Ş¸†“'ú+–îJ6õÔ}ÚlıÕ¿ävÔèQ´NôDKS.EŠmËY…![+„ºø)N)êÚzf¦áÿ”e¶zk_cÛl³T!ÕÒlÍ^Ü9§dÙc,›÷A‰vBHú¢šn€Ô$Û‘şİ·ù&hÒT¼TúÇ6uY&U€÷ºøë¥(ëf*á'èù5’Û{±ÌŸˆİ{JP7$vÏH®Íaéè\•‹¼¦è±¢ƒ¡S¤Bìn4…»–àñÇD…KĞ<ŸfúÅOÕ_Â0µùÑd Š·Y­¥…›ÅŒ™+Üğ‘/k÷üOPC²¼ÿ€«0õ Iñê‚f,±`w»»JœòÊâŸ_*ÊÔÓY€İ¢
şh•L‰@A{¾½Í+#?ÔÍ©™d‘çıÓ¾£OKL?æAŞ3È¡Ã›ù¹\â[étÿ"ŠT¯¶j-Êš±± œŒŠú`±#<ß[ÂÏvõ>^_6{¶+RÅÀb2w'0¯*Û£xÍ/kjÃe«W1¸!kb„P7©^ÄÓAhùÀ´Ãô¿Ğ¾n¸@@Øªó'×¶0
¾û#‰Û_	ÀNDbUŸmö;”•ˆ×sêÔ\Â8UçW‘´YY¯ë’Ê~‡;<åõZÌ]Ùš:/$¦aLá-ö`FØ\‚1=ö!(ª(‘¶æmgÇ ÇğrFR${3!rÀ/Œªæş™à"›~ó~ço(‰cµ"S$Ó`W…ÂRpUzhìÒákµšáÊ|rÙ«	O…ÿR–q¹ªğÉ‰€2<ònó6u!¸êéßŞÃE¶»´ösƒI, ¦mÖw3HüÉU¹ñ6ì«1ÜSgƒôKâ«±ÚÔ·¥ßİ•õÇ`9½ êÎøhMå’#a––'O
ñ÷s—'€CêI´9½ß»Ïã0»ˆùk(Ê“´;±o:¨eÀ~áÛô=§ËdìÁËDÇÎ¬¸Ó8³[@„Oê¸=R^I1»¹GÕÙNÚz…«ÊÑv“êıô6è)5å®#wÌ±­Ük†38}¶^Z†—ë!õÀ†]	"’›IÊ6åøBxÉÖ£[fË‚,7_\é^#³3A º(•³İ½«óbÍí»ğ4^=Ê…¨´5×ç hlwÕ³†Üb/jŞ@KnWYëvZ×»oqğˆ”*ùƒmŞ0˜à‡Ò9wZåôl~”§TYvÍ³Â6Z2É£œeXõmÅ»³¦É›Ÿe»FƒNošT„yEóÍ}ñµÕš8Qnrø•T Ñt•N!Ø	R4~ş@Ç^Ö¡ñÅ9+—;„ë—û¼ç¹CòÈûÉcTW'D1¯ı¤ü‘“uÎOõV¢<§: cª3x5^upÑV0 —¢q— êgŞ—C€;¿Êìºw°PÑÙt›éöh“ Z×VZæX¥ª{r¼ıxef.OwÏ ñS;ˆôõgG£†#b…‘ ¬G2,ÌZz¢HØ,¼c;(pÚvÊ€Lò"ªs/(Î¼Æ£ù8Şr­n¶BÕÕò-GX ¥^2÷ÛpDá¬—pñ3î aÉ÷½ıšö¨õö,)%.ì­Ñ(üD½³+¬E°–\4[F’ÃuSŞ>Wµí5+„†ıéÄiÁş7bİ}÷†{†ÊØ ÏåÅ{_WC\4ç™w­k"z;†F½J{5ÉÇRF·ÁAåº€õ„£ú~I9¼Q€ócröó£W/<§8M|ğ©Zí&sèiìp†ª)BSk ‰øé™§JW¡ÆÉÜ}åäzÕ5 ¿ÀÂµÍèr{G ‰÷à¦ÑªQ8ı–üÂóó›ÔE¦¹B,ÆMİ³$¾%˜¾ãx:Ëµ42}Ò‡YÑšÿÏ›û¹F`KaTB—(Z&¸}yŒõ”ü`øçD2pvĞÒß÷óÑ\]ÏÌhå¢ºñ»yNˆÍ]¶¹Ò€?NX/mVMıtÊ4ºñÑ¥Æ!G¬oÅeƒH5S‹Ùcb·€»®S2B2XÚË>™SÉ2Š¸d×Ô<øüa
ĞVäU•5ş½ØšæËåqM«ÛÇg¶èÁõPæ8Óæ|«XÄ×~s’¦*¨>Ú)Ñç¶¼?–C·qÁ.cüùø{tubëÑÕ-âe¤[lN›½–Fğ;]2$Õ§AÜC–úÈbÿƒæ­è€Å`OX|æHS&JWÃ@Ø°êJñ!RÇíHz¥ÙªNGÊ’6“ò‘Õ£òGËBlÿÙÒŞØæw;÷Vl!¢œÂO<¶Lõnğçô+Èô3£ùxqj²¾—¬ØèC}zşcqñ9tç½&¤É`²2Æsw, “8?—Æå·²Ï"´€¥g
Ï‰åaÂËW¶gŒ~0•pEoFøy5,ÚÖ;Yç3^ªc¥¹ÅüØ¼¸^AŞY1¢4CT›ÊÀÙ»‘ÏŸƒÆ´şµSh=£pØ0ºD[8ş¾øŸàvB2 #Ûè?úÆÎÃöØÑíÿ~}(§ÚIJ&´<&ÔçNT«–+d*}ï³†ÍÀìïnqİ›?ˆ!…—Àr¿,ZÉ.ô‚B©¿¹!,#kÌ©~‰KıNqK¾=‘ÓœHö}Y¹kÜ:â)Ôµ/”xƒä]	¦T´^HœR˜‹Q¾AK©ÅÌù¤nÕö•3Q,<²dooÁêüÁqà İëçy
X²4>CÛ®<ém”ãÃ®İŠ?‚&Šõ÷¼ëõ*AÅ»`^†H½Èˆ ÕÕïõyç2°ºIÚ´-ƒ´ÍÊ˜`†9¾læ’õ:Ó‡ØÛ…ÁĞu)îÒ)ŠÀD'"eğÓá™«\ı™ä':{){Å­ g^UÆû<òŞKiCÛü@pu>ÊNh\«o‘uñU”É¶u)oñ¡<ˆ­I˜À`FÔ„Ù”ŠıÙí²^c(hØáöUÆıh¯¦ô0œjÇÆäcz¬*&¹Èø±à6XäÄ}ŸQX¢ĞW±7ïÜÂÂ,¯ø÷Ş<†z/½S'òâƒèÊB‡Õ²~\İßú¡ñCÈqp©ÑâVd u48¥¶	¨X÷ûÄÆğKo¦1´¬„Æ€0yeæ¼—…ì±^uÚÆ»­¦ª†‹
Í„%ôd^7ÙÄßsÉ®~¯˜ŠÙƒ’Éßøşbêç‰–úÑi¹:»}5ÏÏé.õTı¦>§†-
W’LoU“VJÜw#$ÖeE¯p™Äíìò­)bÕSÕ(	4)§@«V^µ‘¤ºt(…öÍŒ>s«&µ¤Îß(fa»É9*É}ÖŞäÙË|i›Ğ1î>NÚÀác±ã½4êMÉüÍ/®DaŞ-i5Kj5Œ°2KB)‡UBÏÉ*ÃSà	")ú¦„Cğ¡Ó»9­…¸xpı›:^\.‡¥*éa2¢[†‡17<ƒIŠ£{ã|ß¨„I.¸ñKÏM»RI-ó~ZÕsÀHæ’îSmş¯æÆĞb{,SC|İÖ1g(@Å+ŞŠN»áµZë»g­©aöâ8²CEx·àO6òÔ@~K^±s‚ä®¹käŒM„2lK5¹)†‰œ`A£ ƒÏÛ&¹–PmœZ@6d?" İœ‡úJQ$üu€ì3|qû#·€£åV÷ˆ	têzò§†€L~-ğ,t’>¸˜¶Jy–ğÜµ´ci­*ìût¿,tÑZú«š|£Õ†pÖ*»¡é˜øMÿÿ'ö^O‰ÄBmÏ5¸ê¯ZUwB>÷FR@ "/ (,~DûG•´ËGªReÇ¤F–‹ºÊRs9±û&ì“%w’»:gddQ‚^6¬£Ãİ½dx
%Škaß8ÍÇíƒ»­2\¶¼KeUµò¼nFß™ª6NàÏÄ¨ÖÙzïuI	]›?p°ñ0Úå ¢i® ³HúÄjç³¡ øŸãœ6‹uÁ§„…y‰Næ\o€ ÏY şw9Ûedl¿‚”şİ›=ysÜg#ïèÖıİ‚/fÀ„óEfÍÏ%	mPS:Ey»pÈáäuæõx‹ï®T+Z(Ó ê˜D#äØ„‹oÿüÛ°­JV0€ñÀ©±'ÏÎ¾mƒKˆ×­1¦²Q½$İ]	¬åÂ-™UGhÈû‘šàsÉß@õ^”u°¾2é÷9ä’ì#Ñ?¸Ò’ÌD(ŠSå,qş³²>”Û—	Ö¤”ÇÓè8HzÓôÂÀ›
É¨ÄÚöhÌê¦{•8N7Á€©ğŸµ©JĞ§+Ib¬`Š!R’ ­wñœ¯ß™¹ÿ[õa„8Ø9¨WÀ0Øõ/s¹S·j¸ºÌ”Å²³¼Ï¢³üËwã 4r¹İì•ÆY€˜j“ÇZÓq^m;–0†wH¨Í+ªê‚‰*G¤,üŠ¤-–|CÑÚ«<f[Ã©¢ŠTg’&Î$Î&‡²;ÚE	‘ÖƒÔx›[[~ƒ¹’Ü=yˆ4 ¯Û±EMˆ³H­%l«Ïmv“i}JuØŞ´OGOzË…ò4=ç>RÓšŞV‹åÌÇR§‹¯µìåú%y­ÎSpïFã8`éìN™ -Ğ 8p £µ¯Ş[û¯Z)<š)6ßü4#Ş2ù.hv,‰+r.8Ø«¬uN˜®q8«9g;)Q0”¶@Ù¿ŞAIq(ó ò:ujÉı‚ğ¸wÚ2ûFDÊe¸äùr¼;¥>ƒ7¼ş»¹¯=ó!ÆŒI{å]+¶A6¹‡(XFÒj=*Y¨š~eïa‘´»kÊY@}.ÖÚvÀzù—LÕé³âù6@=Üü•$áUÃs 	Ÿ•·ë’ìÎw‹À{/}$ÄÇvt»;ÄıReDŞ–ZÉ…ø#Ó)d³!+ÚxRÁC¬Œ1!ŞcÀ€ °è€Rjzàzê,ÛşÓ—Ì5aî^¨©æã“]**?ˆqy«v31ñ¹cÁ¦Eúú©ÒªÈ¦ñ±÷hkº«›ÉôŒ6@í‹D³@"NÎ¶Z/÷¥f…E[#W¢eY‡ÄM–:e¼Õ…æÔ9¤íIĞ÷‘,òšÔäÏdf¬wÚ›ëeË¶M—üGy½^±ÎÔã: ÅZxÄ9¶ïíuf(¼{]H°Ú5Ğ[±^)d¤—¤Ÿ S<š.bCF†Šúë*¶ÂCŒ_8›ûö§+P–cœÁ½ÿÔûÏ_˜1Îßš½š­V°Y|İÙ);É¿éXš‚îí>¤úıÇ#úd$\ú°7u4ô,ÚşÒdØ‘¦éÚE y°º´a¾Ğ‡·*Ÿ”\tT)©Ê¾\.(ö©÷ö…Ál;@°mÌåk65™âé¸íÄ{`X>Õ9-$ïµØğûÃzrhÃDŒˆ.;Êæî8Ğûù¢™®dºØ9h&¼Æ|ªI<l¸<ÇËgy‰  è”w¼	®3ò2Ü+ G9ªÒúß~úV \ÙÏÍ3/}ü}ël{lå½Ğ¯˜s¼ş Ø„*|åŠZ×pÖƒ]2hÇV‹»ék¬€bFfk¬Nà†#.w[JáAHïHQÕZeSSüwcºÓ* T÷şÃ!‘Á‡9wúáhæbÈ®'ªB7ç|/¥9ä*3ŸâI;¬HÛTT1˜åÆÑ÷º§<Ô«ıOCÂû~ç/mˆFmLû<®Ü¼ãÃæü”«?>Ï},:…sĞ*Ö/ËEø’Y¬—ÙÑëÔÎ¿‰ı«KS‰ºPúÍjsÿs=oJÖ¯q ıª}<1½ø¡GŸŸ
ñ¹âåÙW²	ƒ—…–ÖêõJ	Eğ±ó>ğÂBİ2Ëi•L†æqÖ¿Bx…n3Ö„ÒİnZ•Éç/óûÿ-Ö²…_éšY*æmŸAâìÇÉğjT¡ 0¢gh7M7‚Ñ­„À&ª¨¿HĞ> *”²)7iÚõ™Ôñ„_xîé /R&|÷î Ò	r¡å¢OIC1Ls!r‘)4jZy‰+»“R#ç_ì£‹D;Oá/#»vg”eè/Éört§¢@ÿ¨“^¨Ë%x–¹l0ëü2Òrš:¯îÿÿü,èà˜÷.³MfÉò·EóèíQt6rkä¾€ÍAıNYaÓJdN>4¦>”Ìr	`¢%phªc2‹V!N…cñWÍãÁ’—ÔÈÓƒ2y`÷Ü]fß1ªvnóÔùñvˆaÖh(Rh)˜‡ğ}QÔ6º‘­!B.§å6şŸÏ¿L" Ä×¼[[›Ä$1şWE<–~{>ïcğ•›ºM»§šêjÏu¡2î¤x¿£o™RÏ1¦Í˜]—Pÿí<óØEA¶yáëµ-cŞÃÛ|3êH”AGî)Ühîqn•%ÛC°Ø©‰´ÙU%è“¥‰¬§wyš9UÃQâíKiˆI@Ä=Bó/çhå-ªü'5Ä[Öò×5§<ïÿ¸ù6b••ê¾ øöM_(xxø0šÖÕ¿»>KM‡ln
œI0FsŞW¦Y™¯"ËTqœ,<ğ¹Ğ9ÿ3:/Ë_»æ”odé"HM¨^Ğ	åñB%À+”SÇŒO\Àù¬ÄÛOb®Œ•î1‡Ÿ”2ƒï!”ˆ1Øéƒ·’-Ñt ¢€o.Ä¿jÜÛ_è¥;O«rSíŞ¦z€'íKàßP`»«yïòDƒBÜw à;îöº¦6W“e„ öŞîKD„9~`ˆ¥BHP‡õ44J]áM"` =Båë_¯@NÅÈ³V¢Ø<-kVöF™i_-}’dËºtxyxG°cD…î¯¿dCñˆùä‚²VÁ˜”Kv×cŸ6ÕŒÅÌqÖtP “a8œ‰mÇ®{·y´³Z$EŸ¡Fk7è	Á’¾\,çÀøCÒ(ğ¢Â…ÑÃ¤?}áĞìÃ¥æåÀ‡»ÎÕåêg:mw'¼ÂÚ}&YwÆ\v7Äly(-Å˜;Ãp¸ ®KI*S`«mÜû«è.Rxxìlhu/ûÙRX j(õa@ƒ4¼…†Öu˜»›“v²‘Á—«©»: Re¡ç”+Ô‰-£môøNÕ'Àyµ½jXú	§:WveŸ¼ NwyH9¾™™ƒC©Bª¶–Ÿ$}ûk¯ÏŸ²¤!ñ‘åÏºêQD`»¢£­Ì(uÁ†„òÛşŠáaÂznøZ•»3JÑ€X!Ğ·Q¾%Ğš¡&¥«±£lWĞK]ùZ¨ê<lE=güí3ö‹C8»»ë3ƒ¶¤QitPlıZÎJ÷zˆÛ™™u”ç-x¼dìŒÏ|½áÊæIê$:†ƒ–<¢ñ¤6»¶ÃW¾f“7™œºËÃœÀ*DŒz¥›h¾z=7|Ôk'73¡¤@A–¦ŞÍ9ß²Æ½Ã_Lì_„d_¯MXÇ3 díe'sşdog	_ce¨=7úbMèõŠ0‚è?à u?¯-FÍuÉ˜âZ–ÿ_©úš›1£_²Åéæ¸(ĞÏRïØ”Ú£«;{ÓãÉÃ1¡ó!ı¨L“ømš¯l^K“Šçî~­öÅX*Q÷®$®oª$	=Wö²ÅÄ…n”eM+¢W~IYªM¾Ì° •áquo¨ˆ>2äBEİ•'“9Š%¸å0ã…8kôZ“"”©æ#{å«šR|°Nô{ToBÔ3Xı¨1h\kæÀVK9ªş“ÿÖ&L« +²ÊÜÛÙ¹¡Â~Ó@»tT·óR[×ğRËx2üvER 
 0N¼˜Ú•Øz>fÙaSsIŸñQaVæı§CñC’_)¯*h“)íi2ó.|W@èû×a^y¸1¯¥¾2Kßæ‘R<’[ÍxƒøÉ6§HZ¡ùS«ákÍ¡„JÏ[ö])L«dU36ï¼]ã«Jt¨aFÍŸRKZ£¯µMÊŸÁù@l©_˜Uû¨}ÓGø8ëŞµ†@ù?5V{~PêbT Şæ†&P&£¢îÛlGÍ“ãvmúâ\ÖõtúzŸqP]Ó½\RAÒgİİI5Œànä`Ë@Z^ŠWéßßb^qcBú¡ì·E
ÂHæúüLpLI©ìdŞLZşÓ¸ö'qk‰à8¤½¥¹VwÄ¿àÓáiWàK„¢w9¤ƒ%ºœÛÙté¶´yğĞİQĞ”ìjÊ 2³`S¨P¡]%-_5DtŒˆÇûUBé!¥û!o\”õr¯äÉdwA˜$â¶û,/•º7ÔÈl»»é¢-?=fˆmV¦â"NÇ* 9ÖBjw‹á’®oE:Ûh9{Ü9){tÚàŸyKÏt]!*´Ç–¤%}‚Ú¥]´ß‚wGSy­©²cMü~ñOU¾¡}ÀèËÍ/­ŠûSÉa‰]Áº¢-zÄcÓ£Z–bzIxpkœŠ‘o…&‰Y±@ƒn¿7U È/òêßßª%	²ğAJJ¦uµ­¨+	€ØA]%;‡ªGÁ©<ÇÍÃZ½q}7ä.9ıhÖiˆœÉÈæîÒ¨ {İ¾İà¥¢f|îÃ¢ûª i!¦µ°ßQpcæò¿¦8¤CúGSeuSè˜Çp¢|LŒ,›˜Q=ú@4ä³#ß4—–U‰S\•ñ¹?²+o[zfñ?ôÊé„ñwÅ‹Ö^Œ››6ùÎy¿ÿL=C¹û pÎŞóä#ÑB¦¨°î{ğàÈÊƒëîdšüÔ†ÂÕóoú€c`
’eˆ7ÎwÀb|›¸°9IU5”g«ıu3’5åÏ3(´¦¨58ç	>/ğjœ¢ª`# ÍÚÌÈ$ÎÂq$Ô‡t]1O»²tÙën‡ş»ˆ`Zª–ê†zŞŒß=v	µÈ$@À«ŒiÇ®Ä½ü}‹ÃD®ø!¾S”</f“ŠhûFşïhé0İTÏî_æÇj€±`r{‹aZèi3¤Î'^©UójıFğéÁ®)Ó¶{G±@·àq¬ì¬rÀDvbŠQ½E«|Îr¢·,Ÿj”~¾J[9úÑ‡ÇJHÄL…ÇCçë²é†8İ¼Ó¨•ÍïÄÀm3Å[6öù’8Æp2^=?iÿ­“¡U²YE!IIh„£¹=µÜ­”ç;©¨G¶_6ÂŸNGMÎG‚Ñö>¦Ìr äÊO0âfH¼!3‚Úâ°ÉÈmIo¬|ÕÏ‘ô®ï”î‚p½Zl,»s¹<ñ9…‡rÜàó˜äîVm4éÓ5e×ÑŞ&–š¿34WZ^pwšÊ…ól¦‹ivR63Ë†7òJZ¥ìíì‘á.’|§q¬z+øÒèRgLM†p$"Lçj–Í¬<"ë/’Ÿuü¿)td&Ôç+¨»·k³ãÌØÍ‚Ã&„E:B]¤ç€¿*‘XâRc‘”ĞÂrÑ¼Áq$Ã™PÑı¶1È)àŒ×oÔ`pÚQ9%¦Â0Q~Èı×R‘~Yéh »HÔ™’¾üaÖOç‘y$˜€¤YT@p}:!O«Y­^µ4›Á«œ3
šb¡Ò¡€%#—ÚºğµMP¯9>¦æÓ‘)W^_uK@ĞÂã•gËr51G³P°Ğûm|™3ĞÍ­©–Ép(ÊWe{Ç /²Ï=Ë(XuU·7ùü„{*8Ä®'Ën¨p¯ «·ê3*ãø®õòO¸%œø\à.2"ÅêJnöD‚?1Ğ›Ç@LÛØ’»Ãt^á‘×Q@V5RÌ O¡ÚUT*„YÇ8*M‹Ína¾ÇØş2Æ
© Iøî1Xœ*1;8IÊÇx€’¥&p	÷èk:©1Xu‹ ÿ¿	ê’{y|¡•éÖ`…»‘é¹h£•Ø`¹ö)ƒÑi?FÕ	Åe6$¹Óûy5êÙğ†ú{¦s¤Ç.–D70x¡ì83ÄÆËÔ‹ÀÈÙx–ßì~óG˜ğ;ùR1hBôé­0Óˆÿ0v¤!S®@GUîogX<­Éš•ºï¸ºCÇ¼ŸÕ³ÛóóI²Á[mˆŞ¤ô
Å\XuNjğ|Ú±_'“ßX“ØÀUNqt5j*’š9ê?«U¼˜~©oÚeG”ÒÉ¶ªË\…V20ÌµŸåiBRr@v[j‚ãƒ¦EÌlò!øŸO0İoyòXu|UFãú]BN½©¦x‹şúŸ^Ğr3i/k¼í¾¯{ÛçooINœD£¨nø ¤D.Fú6\+Ïjf dÃù]Ûª/ºBqt‡i|©Rm€›qÃ8´I6wTº˜¸‹:XÎYÁŠ)Väó$jP?$Ê+§Ä¶ç6#3Fñe;*íÃÆë)}&µ¾İñÙ‘W%rï¦ `¥æùÿÇ<	½¾p”ïÿAi°–Ï×ì"F¢“^Ó&ÚPïì²2Â¹y{ƒc×äˆdş7±Úİßcô¼÷øs	&?¦úÉ³ûS¾ÖP®:ÍÆãs9õ&j£™cò\|tD%¹ï9ÊœêÜAuNãIGqÈE9µÊ² zã¼€«éó•>Î-:¯×…ÉÑQ7nâCY*‘“£âƒK¹GKYÀáomÒÒŸ¶gmz…@Z®±HĞ¼!K­N¶ßÂ`s"ùaìÒš64“>õº%½—=åEW®ÁÛş?v©´n;ãÊ7Ç”Ù“œüGdÂá¨ƒû@¹g5&f}ªGlÅÚØfİÇ!¢Ÿ¢n,¿¤YáRÆ¨gsTÉDxĞÎGøxr^È‹ÑCÏp‡"Üş`cŒ±çÕW§hÈy‘%z…UÏÀ¤ºÌ$ê‰uƒÍ–æÏ¬¶à¢×ŠºüRwsØærx(ÎìÏay]"¤îv ºùàzäµÖHÇQ€6I—‘™¼°|JqçJ»••!ö£Ò—ªHåZ£3*VHŠeÿË#;ƒ§K¸vŒæ*6$ É`…s"Å¨ŒÂ„ªH¦w˜ÀzK¸ê€{ş°~C=ğ:Làs}R¿Ü2$}.ÀWÚ‚Úk&û‘ÓÈ.³B &»~g³³çØ—\K‚½±V=!0—²Ñ§’®F(#Û€æ÷Š$à¨[º¯‡æhNÃ7fã¹£r¬£/ë,âÜêwå ¸Ã9¬Â.JûâcA¯ÖîNG_UÊŸ`0i?îfÈ…\ôçÍï-.jÊ‡c³°ßæ£ê[]„ÓN”tE^Ê€ıÂUmQÛ•n=…ŠÒ*U¦LªgBQ·Ê<«Ûk›v–dW:º#%5>QĞ®ĞÈèø1)¯% çŠ¿¸6ÿÊVå¢¦ö¦=Ş<.fÆf[ÃI<İb'-n<HŸQê¨[wĞœáª¦9oá†`‚;9Üô’ùn¢¤¬ÜÊ´Ó•üOB¦*ÊG-ÏÑ&iñ¶p¥ã{BßV¥WšŞÄ‹Ò‡›¿ËĞEå&¹•!Ë­gô
’He%éUŞ’¾§¼Û‡aötB×b¿•³{";äÚ‹Å»¸$Œ™[)z„'Hf/º”‚,s~1¬´ ¯1RFğËÓB¦4tQÈ¨W¥)b+V@BÛ5ŠüÅknÀO]—›Ñıv´®ZŠà8ÉE«mC·PÕ:$fÀ~¬¹Hv¨¦ç_êg,RşÙñƒ¾ÖzÙ–;c}ç¹ ÚL4ãHo-ƒK ñGP$§E®ù6mçQ#»¤“z
İ'¥-šÂıRÙ3íş¤˜¯=$]+.áLÅixa.ìq•aCB$q@´ê÷ã4“f°¸AT†Ü×äSù.™Ö­ı ƒõ®C£‡KÕ™ ogg!×è²&SœÑ”OãĞ¿ú´|2Ÿ`)j4¶{ú‚º||æä
İa=ø‡ğ¡¶ïz2/*gP"ºšß¡ÿ+F‰d-…"ÇZÆ[¢áä®Ù˜¦ÏÒöN&ÜAŸÌ'öölQ^FLŞ—\¾¹yûuˆö’õ¯}¸1ƒ¶V;Ú¯sìm¼
Äœ@~¡K$aZıl6Dg8î0×#hA„çUøıÔ¹8±w£en¾Ç½‘á8½EDÔ5üFX.œ…“à
«3ŸÙvºİÌ²°ÜFp¡ıI€fKÌNÿôLKµPQ@7İOIx)Öç½…ÓŠÜ}ÊÆè1{˜N;R×zaue3cßîÒò‹éÎ“¨@‹m…ˆ6«ù¢+¡?ãPÇŠËE¾I(qÕgòÛ'àD¿Àx³\W¸gêƒ×RE‘Zc­*¶‡£gj4 „7Š&ácd	³­Aæˆ!–xÁØŠfvÉÀuşà•ZpEì;NX‰à¦¦¸Ç/?Hl%¯f)ÏÂ€úšÑIs®eIT^$•54\*ş¾½2lNÏ\üRÃ›b1°IÁ¬Œfz~+Q0WpÊÛ­£K–eğ¾—ça¥ÿã·vFùÂ-×¤µVy@{½¼êü¶èjİ0jÍ ¥Ş—µ?\{>qcˆÙ=Gc+}“q@?±0û.f)ñê=9ûÃõ:ıßGßóº›Æˆüz' ƒ,ÒªşÔJÊ{
˜ Û÷h]Ş»›Srd®ÆĞ?Œ]¨;Qâv¨aÈ:€CJ›ğš»LkŞ3ßÄ<‡_±UUuî˜x—èB Æ¹E/ fD”™ è9Ÿ³Ou Ã‹^wT:-m)´H]j1sißÔ‚DGğ2Ílº«­L¾«ÇğktİÁFÃºî;ÅÿúÓ‘M‚Rq—œÄÍ+Äïxã-,¡»R½‰m T‡{÷:øoÈvÖ9Là¡wÛ©yBı±ì·ôèÎÍ¶QÖdbó·:à&f¦F­Œ	Pe)
kÊ]ı¦üıÁQä¿b€‚lkvcß&èuÑÕ-ƒëØ\ğ
ùÛÇnQõsÓÈ°®gã¶½•Ğk m-älşŠ ¸ € j¿[±Ägû    YZ