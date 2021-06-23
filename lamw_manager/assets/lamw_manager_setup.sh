#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2546842271"
MD5="4b424c1c08d9b2a90debaa62e84ce8fc"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22924"
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
	echo Uncompressed size: 164 KB
	echo Compression: xz
	echo Date of packaging: Wed Jun 23 09:07:10 -03 2021
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
	echo OLDUSIZE=164
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
	MS_Printf "About to extract 164 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 164; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (164 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáßÿYK] ¼}•À1Dd]‡Á›PætİDñr†ùişÊ`ëTŠr¸)Fs<T‰^6;ƒŠMêÚóÁOæìOè0Õaz™tæış÷âÕÚ-¬Z"ÖzqÏâ7”@w¢¦ø„91c­ºnMhır;…¾èG<jbJúøf·Ğ´ûê2ë?šmÜ	4Ùí{¥Îæ„‹kŠy±oƒ€G1¤Äíè—J?¥m”¶şğƒ®€á&á(›Q+r3.şS˜ÊØüÎìj¬¶<w­„.]5/\?Yˆ€¸Ç™ vëSÎU““hÈù0¤mù¢ÙDc"!(1OA-…ô‰a_ª¨ï_»Ü««F½î¹|§ø=ĞıÖv]ı9ñ_¦ù¢œĞ»u‘ü&+µNÌvFğ[öm“á„ÄñtİöÔel?|š¥—mú˜š%BÏ©y'É¶¹ã‹¹PgK]û­µÔS¥¹¬CØ£ËÄõ~‰Ö¡h]4wKM~vXÄÅ»JÉ`l%
’S‹Ğ¢ª‹ì»ÊOß•ïÜ¸±vQ,„Ó¸µ¸TµrµªxlÍçÍ¤º½6: ^ÑJFá3ş_CAë¦4uÑ&á˜Çæ£ş$®7œH¥: P,‘rTZò¾‘BYˆ·•‡+pr ø6Î?6ìÍ.f®Ôù$I³@£(wÑ¾MG¸dM†JTõ¢y XÔ6Cíñj<.m|fµ(Ä'’Ï z}f=¡„éÅí?#Ã+w÷cU"‡ØCzF_‰ÜÔÜ;É,kL…Xµ±ïbí÷Ğ“b$úvôK±¸3@­lÒĞYxüòÀFÛ›N™ñhY¥æÂíD}Ï¤=²v²&Ó²Ì’uü.‡Õ¥“|Øğ±(ÙLÇ7~ó»Å/[v2¦¬LBO‚g4}w½Pœ=t)aLSÂ[¨gv¤'ÃìñH#îX¹3/ vBF¥ ]ü”cª<‘‚)MÒš8jŞDP÷Ï`å¥ÄÌ¼±–ş:÷å1"U±¯4şûÌ…®éÕ	jA5jÀ¬ˆ?ï6s’!NÍ“¾um7KÒmÏì-Yü©õŒ[HÒ—Á®'¢gø£}me1ıUHİŠëpWÉ<X 'Ñæ!ßåÎšºŸÑ‚œÖZĞÂ®œÆ(.MÎskÉ-\+Y-Nk×QÍeLW´µ”<.¬•‰íœhåƒ ˆ}ƒ?Ç…êtÔiê¨/+û{
ğµë-ğzÙÁƒSŠh^ˆ^ûĞğY‹­‚ôz„Í¡nRr°P	Í·yGVïü Ï’¤Ã½ïåPPæ—*ìOwı	]SoS¦Æ4¦dãV{nCò+‹«İq„îa…Ò¯U\}EvÃnÜ&vy7jnşUtŒ{#˜rñ‘ë¦ª³·ú†ğÔ4ä×Î'MïÍ8	ÚI.ÏJÜÌÚÜÇ°«µ5z¦Ï]µ^´Yüü®wŸîÄåx2æ?÷†HàÒöÑG@ÉœÑ°k,»^ïOyüõ
/¨„NH WdÂ¡÷<’¬ŒO;Loß††ãrÛÂ¦L›¶~
2­ºòà°Ø¥ïzo'yå+9Øb3ÏN9u2}[d5ç/eÉ5T{eì+“ƒc4wv¿ßãùàMI™k·<ß­	?“Ÿ ¶Íæ)Ç˜aolÏcRw¤A=FdH’ê –˜`ÃæİD,8¾˜û¯g-Z,xZèOe·tEp#øĞšÏ‹!ñ$ê°CàU[A¡Ï 7ÅÒm3]‘’IÏŠ	Q‚q&Ôúlh>¶Éœo¯7$ÿ^
vTLÔòŠ¿\ºÏI©z'­-®,½æ„ûpú?9¯ƒ³˜¬`pæ45c
hB–À˜9iÛ¥ĞİVÛUÙá
ÀäŒ?ÒƒQêŠvì®ªŞ©¦™ê`dÛ^éÖSöænÛIŠr"Uøjáiİ¿Ïş³ÈlD²N. ·ª¯NÔÜöÖgR$q3gŸ1MÊ‘»ôl¦IH¤ûêÊSÂ—n8hÚB·ø8l‚tbÖ!¹*µœ…Ú9º†3w\5³y?¨‡[×*Gu÷¬._â_‘Ÿ£¶ ÛÊÅ©íÚ4
J²©r°6ƒé®…3®çé—×Ûqbr½€©UŒ!œ©ÍlIƒñçâB}$#Ùì ŠÔ#ÛÈo3±Á»Ç:‚Ü°ÜÑIUØ­ ½ŠV¡L‹#åX.p…ÿi
¦½$ñd]I!Æ0×©£¹™²£ ¥†€íÒ‰‹6iøVÕx¦àYÇ¾3`Dvûb³è"‘¢`ÇnxïáWJÀ6Öôôäj>+z	âò ÑÙá¶ó±ÍrN1bW/¯G’cØÇ+û0‡pµxóÁ¦Ošå{z*¥|hâúçòi§>×
Êa×=ÀKó…]~LF«´âÛlx`o×¡ «nükˆ…ùıè?ÿeâ8a0E²ÙM¦ä¼ic†1ö![+íäåùj…=ÎNãì"˜a«­¿X…Z"–@³mn[·'p!V½<A­	´CŒö•±ôÃ¾¶Ãh°"GÒÁWa*­vêªPy´¯–¹ZšOª®èy¡²^¨p§3]Û¯7¡ı"…•~Ò‰²€>m‘A7¿à˜PŸ.–¹g„/óîªÛ›ÂªşH›¼{«ÔÑ½U91F€ğ€ÔyÜ¼¼šåüp¯l¢êX››m	ğ[f0&£§LƒÉ:k*<ó—ßêˆ¡½É|æÿÚp*5íÚ#¦ç˜ˆ=I¿3&ïBšá0¹?ÂÔ
à©¨®@|å`ş™:J™î¾`õïÇœÚNœÊÿn“!Z¿û±@‰†¢Ä©Éäğ]~	ú<S]	{’“tÂ/ïS0e@´.{fròÌË¢1*[‘nbèÜô3Ş/@2”‰ËÛwÃËø?œ.ôvÎ[tØ KÃ¢&VÜÂh%¨öôEai½/à'qÕ¼æì9Ü»];oêŸµÀdWjEİåæXÌ>(ÕàŒŒ[¶9gæ‹İå<÷‰Üâefqşæø¤AšçL‹Œó í‹~ßær¦¶$D4•ı¼Mj`J³ ^R¯Gê$¬„g$Š~èq­·³‚·}'³§ÏjkEQÔRÛ%–ª¼œåØVø‹ô²†5ÅÄ:]†Ö±‚¤*:1t,A6îûDÇmˆŞåY8q\Ur5EgÊ;×|‘Ø
‚'kQ7 „·Ë)ıŸ¾&ÚÎuMıÙŠía6ë£İ¹[s S»zÏî5ú†ÉY%¶ùMØ¶7™´WÅÆx>‡Oó»ÃKŒùkùÛ´ã„h½À–öe.ÿî½2d‚ˆÆ6¸FÎÄâI¥ıh1ZŠz)¸…Ö<¬%ã|@I 2Ç——½JüroNçÔÏ˜¦àİ‚ÛË5!bª]=
‘Gå`1™	38ìœæ&úÃÚßA‚ì@ËCsOğ ùŠ+fßwÀşÌë¥-—„œ€öÎQãÎƒÕ—¦s@¤;qqš¤™Áœ¾µè,÷Ó±ÉªbuÖ‹îÌß1ú[ú±…áZqË¤.oÓçOÈ©ÁRìTy–n…œWÂ5vûŞCtYæR7é©T–+ûœw” mÔÔ,b°V-r)v©Ã¤§¬f¼DÁ”•øÀõ²;M÷ÓP$~|8—G^¼á’İp÷ˆ`Ï-Ó}ÿÅEQhpƒôt3ÙÅë:ÆÒ&cëísrh=x`±v‹8ÍÇ(Ûr3i°Ô/TíêT;IÑ-¾´õl!eYõ;.¨aj*N³*Š¾@lÁ?üä*hFXÿí<ªÆ›H“™R3²{_3¤èNÍ_ñ÷…ßHÉ‰ß>Åô[ˆıG˜n¿VÏ<É\pDXŞ¥æ*[Ò‹\/â~Œq¨öàÃB]S(ÌÍØÕÊÆõÛ?Y¢ï†œ4È˜×}^ó`…)¸¬¯İıİZì™Ğ…>ò^&“`‹ÑXˆ×qNŸ÷ Ùß“©dÇ
ÿ¿¤Za™‰ {P•+NZ‚¾YÒéĞ×•™şIÍRºüsıH.ı,œÈü„Îe·ú™¢ºŒÉ¡AGøM+;•Úy—gû?‰—fC¢X¯–èÌq²5Wˆ%ÓMÅ„=2,ÍXWHNIu1‰°3‡!L£CRTó‚²m^p†ñÙş(‹D°ëÕ†O<‘æ1±¨îèàhêÖW^Iä§Èy©B‡oü²”mº”wH¶‚ ‚?Ù?ì½rB>ÍY àh=ôØ]`¾ˆ[õÇv\Bª|Æ[”¢².5gÕ1Ÿİ^%JùqÂÄŒK>ö s…ï/4MS:İáç6UI{8¬u‘Ó‰AÜï|¨È2%>¢Ë4ÜËxÍ´İ†|â9nÛWè÷¡Wyû¹Áâ–gÆ³°i—ÑvÁÃcÓÂÛsÄ)Åq‡Zä‰×“şÒûôÇÈˆ¡=¼µŸ–ïd•vJ¯;ğçüñĞ&vı`ÿ4).Ğ$^×•şïğµ|èkVWM=÷³½	ßaÎåâû¡w<u7NCw““şût*‰fwÍÜ’¨}\W©Ş<[èï­´¢4Íb’áhº,¹¸Sbråša9ÎI«¶š4ÜÒÓ`B¶ñZt˜Å':0™à6ôí÷¿;¢Ãıï^:fÇ5ÕÉ:Z,Ë€†!˜9`İ¬~XÚ-1nèH‚òÇ„l‹_@Û(”2Ìw‰6ÕªN3×y‘m7*[Ç"‘åÎÒİ]084k¹mß”Üe¯Ù‚@ïşıf-~,Ç`œ²tòyƒMq 8ä^QÇã÷.­\~1+t=ûñS’vÁ.¦U¹bŸ¦g{ Â‚Š@(—8Gp&sÃÜ¿äFÕnpÿ*›n=™¿6Oñ^+ÓH¡|¸=ÑHœ8“G#}/Y¶gÅóñ½÷¯ßO=4ñYMNÿ‡î-Ö—qJdÙù¯Å°–z¦ Ça´«ípotìşPÊ°s švw\—OsZáïØ—HNì´}¨ÍsÁjº«‡`9æêÊ±J¿Ôrü]a!¡4BP7Å-ÜºƒÿLsø4*DœÙì*ò¸ÖÔª]YæÉ-ïä½¯ßÔ±X¯¤š›G«Õè®ìwĞFŠ_äÔn¿¬•ÇÕâËQg‹oPÈ¢¡#¤ƒè\&íğ†]…˜ÕoûëPp†„|KävÅ¯wú^øàšÃ¸ ½aõÈçŒVÕç$Ö_{;8HNpT8EpQFÊ^4
7~F"lÒ]aR±}¾ŸºÄeô­ãÙË±èƒyËŞR­ZBÒ/ÔYÀ¡½#QZáqç d‘¥o=´ºXè¬À˜ÿ® èÎ—·ªæ4µQ²˜	55ËLé##;QFÇm.",Ïˆ’Ç¿Z‹BüXS=\Ş(|«jü{pVòĞFßúšl½ª÷Àa®9å•ˆêì›v%°&ˆ"‰9Ï‹‡ü×šcˆMX‚F/d™Å“a5hìz%2¯4MæË1ÑÆ·§Y6Kõœë%üK3Úîş:Û$eõDbÌ‹3]2›²|I¾Ó9Må¢©Ñ£wEã‘ö¤*;‚BŠÍ¸–[è¡´,5– Ç¨4$¹ùê®$ğğá$ÒÚÂrõí±ªüC1EC0EW†¢jgÂ…¯¬™Ğhmì(ò]kw 8q¤ÚÖÁIß±ÙppLÕÛŒIÖT×¾'¡_ L ZâÏGÒÆğbƒ \ËZòé*³Öæ¼ıãšk}G/Ëœ“ÆºO’B$TÔŸßa>SSŒ²4wC–ÇäP"Ã‚Ø®c¯ì—Ş¹Ÿ•U™’SQ8úAí,şúµ¡mw£ìˆ‘ÙwŸ>@Éš·èN®:Ó4„±*/ì QôÓY _
aSÃSº €QÅpğ!¾ÛX¬eğX1¼p_µ§/İ!Q‹Æ3,.Xvc4fˆ†¬…J-†©ºúY+ Š3ê@Íš‹ÿË&8¬„×jh:<DS£0Ï•ªºòå=É”—äs¿„¤Ónhx>~Jc“Æ}İ
„i0­3êäLm2Šš5LŸº£Ğ~¶
‡‚nÕù=ƒËó6|/RŒà`çöMÃÃ.øezÎ ÎĞSvı“»OU4Ì$¤”Èù{ñtéxR d¢1N{´½+E‰zèı µ?t ~ÏXÖ Q»Tı_1©`ØÇùU•’ïñ‰²‘8—ÆÉŠTZÒ3„ù>¿¡¤‘{óÍa!×µ6eæºÖ¸‰¥;VzHh‹ıˆMé÷Ò¯‹Ö`½ÙååaÎpk$ñÜôĞU@V<ÓKË[yÿÃü¡wQgÅˆ_»5”ø€ìˆ“@½ŒÍ€Úö+SHïƒ(ıTÁ\‚~òCĞ=FÍó<$H3±3ı<¡§YÔä[rñ‡ÉRQ¸dı"7=tÙQÅû¼Hçf”ÛSî¾Z^Z˜á0ÅÛxh?æ?©y~Zc¿¿©©İ [p¿^0•„w¨R:ş’Â7¢­*¶ê²Êğ¿ÔU¤~)L¼À)peÉ1¹‹w]É¹‚ŸÁ¹ö P±:]#ò<áÊ»G^jA™.»åõœa§Ü_ğ¶Ñ”7šıã\ÍƒšÏšÒğ&¨näXÒrKòõ"<.õŠü»òì¾ Eıƒ/ÇSƒ‚¡$|­÷¿rà HrlN‚j [:Túğ È„sÎØ––w¶%C”ŞnEºé‘Q¸X&Í©Œ… Î®f…#ÑôE¬7ôa¥o6³ ,çÈ,f7ÓVCöã}6RØËO£‚v]\)¶„ÿTëVŠƒ»ê¢Ÿ¹ºên•È@'P´VÇŞè©‡ùyn^|„‚à=
t‹Öb”Æ(.?ˆ n21
Ğ¼óÃoPvç^gì•S5”ş=û{Ö
›ÕOèíTQ¡¹{Lu,	¬”‚zä›O®^
¯¾¢e	>nôß]•^:”£Ç§vkb¶ÖÀ¡¬Qt>ŸWsÊ9Zï@`ğ+_1p·ğö¶şP”e&XÅ£âöQL\Q¯RĞl£Ÿ•?ê r@]ª÷86’·f´å ŒÌ“&àVË6‡{yŞ0»œòç/|%Ñgz^Ô…JVï[º9ĞXz;;“à.FgK¦’)ñoµq0ZT‰j¹''cyjÓ9v¿*RwaZ+_íRle şfñ†Œ£ÿÉ·™nOÊˆ]®Mpè%»BÇ¸A¯öxÜ v³Ûí’/aÍC,Ùd#çÿÔ\½Ç|‰‡ÕµI#¿OĞ¢u £pVÑùCÆxiI
Àä¦¹á›&æ¡¦iÜ2Æ©1ö`“ÿßÓ#à½şÓƒòbÏH³¯Ã0£y«qpÚâà^
‘µ¶‘ãÂ°ÉÌÖ¦òô˜¹}ıKùÁ”|Y‰ñ]Z ƒ#å™5åÖŸr€Ü®¨o±ïJnTÁš	¶„%ä¤¹ªô+eéo¨³t[æ¸ü¯àjj™ôèLÜÏä“¼•S;şOÓoªÈFÛ(àëb*íx¯™·\ÀÜ£jTyxŒÛs'±ì7‹‰$ÉÂ5qŒ„.p×)ïÑüÍ¦Äâ–ÓKû#ÜÛa»FxaBù6ô“\sf»cX1¬0!. DQ)R0GoÊ—]=îyÎp|»ôß\c¶Ü‰$T&,ŞøeÛ‹1úÏF:M*³øTu¿QïQ1?Ëç…îç´‰˜ÑË<ï ˆ/µNâêİké4×ìš}îlğ+6n³ŞÁğéeåô‚M\k×Û„é…ÃKËc°fÚºv+víúÙè¥‰/jì£ÖÖ>¾Õ÷‚êh~((‘Ç¯öú-4ó	RŒ%zÓªúV¯™P€¬­·øp­ÕP16bƒ°9§½… ¶pä“_0}Âtµz3‚AÒ÷Kü?[N1,^	£¸KÌõÇæy‡Œ‚(×Éˆ‘ÆŞa¥UÕ¿.ÓágSÇc%Ÿ{ßPQ"-[¼Ñ­ñTó‚0¤—ù—èwÌ3…âòÓ;ãü÷
ğø´A©ŒÚeú”EB{­f) Z2k	Ã;TCWvš şÌ‡ápÃˆ)aîQğxÉ­iÆ¥°ô™Ç¿ %Š*¹›Û°·y¥Wø<1ğò^ŸŒc< œ²ÉfÜãB%8I/a³–,ÛZ¡ã21?±9
p_±·ï-1DÆq»uÿ‹¡öÂ¤2´X’"J­qÍñ	ºîgJÌ•3¼ê¸šoHÛ`æÏ€e) V¿ $«Bôi›C£$¨g8QÓ‹6§sË
åå¿Èsô¼‡›Èà&8ó¹İ™¼>ÕQƒ±ÿaSu—ÆC_-uİ¾t@äålp#8«ÌYab³èº$_Km@ymk›×WF³zAşùö ¬øô"2ĞÚŸÜs‡Aº?¹Ûô.ü/JÆ›ß)GöO	<Ó¯©ì ËV—Fƒdtò¹l*šïUR¯!³SãD˜p¥Š>·æ:Ãg¥G7Ëóv/ŸÖój'a•Â—d2U;¢¦]ÜbPÚe' ÂbÌepÿXƒî—q¼—ÀâTn%°à˜ü‡µWPÏËåÚÇƒ¿{÷£¯gÕlc:Öã«Éş(âGÉx·í,… ïS'Å…Òdö[5_s†ãx^Zfï€óÆå
Ú¥äD:ò! â7è^½ShÆYpÆÆD’MxfEjîÚ:ø	—
õy †½a‹ëkQšÀ6UàOåP‘È’üû;œuº"[ŒP|‘ùìòàÖ!H\„v^]¡vügK+ç>…Üe¯no™Ú¡ï=J	Ï>	åWİ('Sç©”oÒ¦	‘lPy~³±­¶	°èª¢Ê4›AW n¡şË²V)4Ô6$t‰kLwØÕS¸ğæí¿é©|1{@«jG‘˜ò™‚eØ/Ã\$šâv­¼/Bbq±‡º„E‰¹Wç|'gêª™;Ée	ª6I%µV=ã€†`ÿB¬ bMuxt7Óqë¤Õ÷+pÑŠr'õc´B~¦Í]U'{­	ñ{¹URÿîº$¤=¯$(ÓØ “%¨iı¨y4åÊ‰;I"ò<çö`*™÷f÷m¸ºEÛòÖ•¬¹A~¼Uùè´€IÔlÚé;`('\9bÊ	ËÒEÏw*¾3ìX³pì¾Geú’Ğ-’WA¸}ãRR‘"‡µx(¤,Ò<Z*/¿ÿ3èSË›­l¥‹çHç|Ø.æ¦=ÍJKEf.XRÅÄ¬83K§üñËU»£şyĞİ¿ i˜:âZµòŒ Òmnß¤=‰„u%}„Hä'+ÃŒÀ4ÑÆÌÌrÂi‘p®»ø¡‰AÏP`lq¬£¬K77m›âl 1†8¬µI·Š©QjåjòŒ‚Ğ7C‰ØAäŸéXÎÍJ@!˜k?àğfkÿ7f[öøw5ÍA<Ùyaù!&oæğ†’7ş®qè;˜{Æ=–Ot¤şV£DabRÙ5´(›—­?Z!Ü°Á×ëP²™Ç)¥f¤uYë(8íü"¢ƒ‰¾ÊAÏQ»ÓÁÃVvÙóáê¨¯â>bÚˆ0€óà¸©ãï¦B¹#nÆl¾õ/Uü'ñÉæjö|:—ä¡TwV´±Ñáßœ *ãå„¢Ç¼Ÿëøï)
8 »iş¨çqHàE­™ù?ë00Ëd°hC%Ê1ÕÔoT„‡’;ÁRøµ\/ÊRSY°ê$ŒhUÌåPË€v‡mÙİ³L<¾³¨ÕÃ×«´†'+c]_µÏ²9çÙÁ486{¡KVìé†$­K"ÏİlT2^zË¿‘ê ,kFAû/wNŠåÙğû»ğ°"ÓüM.z£`¾˜«4d˜°„#”Cšo™ìíPŠÌk2fav%—0}/Å~À.u®Îøw® ¬c™ŒÇªˆNô×»PÔ¼‰À]wUíĞOÌƒwpÛ‚kg:EÉL5)œ¼ˆ=)ºF8üÜ@ øÉKP}€ìnùv´Ej‰šÍk„ó‚ÎĞ_¨8G®+)ÇV-M;+¼<5í¬”/´ğpÃÙÏtÑMq;òàh”ŸHĞ‹Z:À½ËÖb[j•à$EŒW’oà™kºåxT%³Ò“†3•p–yY0<Ò5Ìvö3©+À•˜\D¡ıE·ùZg+.3Zoàİ$­
^)®À+æ
ep¾ï³p>êNkx):³Û_&B¸ßçe]²ˆÎÈ[É©~µ×Î‘ŠRáşìÈ×üÒ;¢*%ã]klé¥ÉÛ6ƒQJ¹ÂÕO3Ï ˜Kw[b¿"Ä´ Š,ğ«„8‘>@÷é2ÇÙx§F•©ãèsêĞ#=¢iİäÂnb.pÙ3•D{äö’Şím#ı¥jHœs {¥-vÆ!ä×fâÚ“ÚŒ>×›ji¬R¨kLßÈ>Lu`X‡°Kq/ÿ¹Xêü4j°GF€Ûé¼8F¼zDcşŠ¯ŸôBt,`À;(ßy¬yO°İán¾?ƒuãÉy?ÜêÊ’½ãA‡÷dOÎ”bñõ®m®dÊ÷nÔ“Ä7ª¼³hk†ö‰Zşœi†ÓÈÀ"(/áş!’8ÿºü9y¾mÉìyb§	¬>;·éÇ÷%ÿhÀ»*Ğñp;í˜ø2j!(R<R/[“ €&àŸÿ\…öHSÆÓvò­A3Mşš)ÚÉúò?î‘qÛ—Ÿ¬˜êdÀ?ñ+Á¾6HBsE¯ŒUÍ½ÅReÉ•<Æıè²Áøhì,Á‚i¤ôBßŠÿÆïÙJÊ)TBœoŒÎhm±ôbOßJ{æR€wK€Ú·ÆU<ÑùÊ]}ÿ»™°ÉSc‹ûaı]QŠóû*û1:¢yeß,k]|¨ƒk×'Q$N›Óùê`ƒ •ãF^oS(µÿá\˜Ÿ( KÜ«x)µ­¥ t™Çw‘³_~ã@ú%BÚÈõö&rÔzñˆ—",v˜R·§oª.ğÛPcƒ5=yM‹¯1³åÁµÊ[ëuŸUVk9¢˜†ƒ°ìpÔ8¬€Ã^}@BXÇ^Xë^Vma
‡ßˆ„Éh—ğ]@
¸i!sEF°5Å|ÎK\bT•x¶;Â³°õğgú.Ì=Ë68|„ıÇ0G#¿lÏNg5Lj°lƒöW é22<w Cr? R^ú·Î|¹	Í¨É)€#0¡-/v¿‰˜°KŞmNgKv°_)2¬q ÑJD›Ê¾Æ\ÁEp…°L@c¶_)à²ZI% v|÷TÁCş´Ú‡BY¸´‡™³•5å	1T ÎÎ(²NÙ¤W0FC¥öF„fíˆúaRã±¨Ú^´Š>±p”Ğ72+ïBb¢h¶³¯ÏQbaèH“#s$Ã6`àZ‘QÎÿ¢Cy=:üÈP{”yŸOhÏ=~¢D0;Ø!«”çAiÅ»YÑçÃŞb [”`–ìòXßïQZ%Wkå(5SW™’ë.qà'=ğ8jÌq®ZòÜâáËê€}ˆ÷ıÛ
Rš?!JJF¬IT,Y3koèšs}ğü½Co/7(š™ïğcXlbD0›œ,—Ö3Ñp[ˆ¢·IëÉ”ŸÀùXkåãÄ$~iÎê¬½¨äö™Š‡L9ƒ„–-Fúu© æºÚOFºRÁ,ã•5Œš’Åğšİ |ß¬7+[H„xw£Ùé"ƒØ`GMŞU8ì–]xièÄj§{ù³(G¹ËúÎSp•FÊ÷OÜî†”°“?IB¡†{KF~”ÿ?(N£ìĞõ¼NTğ«ßÙ¹7G¢ş¥dB>)TrY{b_.@øG/ÚZülÍï®èÛßeK¸¿m¿0NW:2A`Ş€[5Ä<N|]­‚Ì\tj Êò0kÛpÕª z±kóRÎr>ŸÑôBÕ­åùÃË_»Ğ‡·«t4&˜‰G´¦ÆÁ	ŞÍ (…’¡zÑüà·'ü}&ÈµsIÖÇ;[QèÌaĞ¶ãü]´zQ?ñlşrg®Ú9i; x0L€´ñßÂášädYG‰ÀııÏzq„î‹¡ï'9!é¾w½ ¯nª|\F+‚åZ/×ı$fµdmŸ0dT¥\!-%ÿ_rƒ6%@ÀKy®ø^¡˜éøĞğ'äašH,{‰Õåknõ|2OtŸ8ÆZ;C±Úm½ãğ] [éK“Lo	ß¹äxÜÑ´ÿ5Ç¯È0ò¼Ç(ß¹¬|Ñ±éq³xªµøÕç«LÏdÖô7Kí>ÚŒ·ºÔ,`î\¶n•ÀÈ	
Šv¤` Ké!²–ØY?ccÕXEæÍÖR6¶OüÉ"g‘Êd»ËİFPçnºêĞF ä.€ùRÛ‚î‰zÖZÆ×µ«ºönİÆ¦”)ßr>É>›__Î¥i¼ÔÔÄ¡‡å-Ó£ÈZ• şBpIú“EH3´˜ôÔ¯ÃÙd,NŒwQğí4YA3M²´àÏ~(ÿ<€n
|•+RlÀàhû,yîM”ÖY‡­t±qêoûï¨ £×ñp{kÕ¢şÎÓ,X|!Y­sı×‚ç4JÊq$], ñ> GÛÔzÛñà¯§ì	ï‘-gap±e5MngáG›\Ûî
ª+S
:ÎQ†«çûã[h-·	‘ñâ$J²^OÃ£4™‹©nQ»`«²òğdc=¿·-.Æ3€¿s÷&Ì‘_”H½F
	Ç}1†I„“JDˆ~På†îN_Øˆ ÌPW»Xù«°Æ˜ÑÚèŠ_°ñ¾ÿ§‰Ÿ¢»›İËP ^£+i?–~W)6öUÅ’ÜipˆĞQÃõFo’
<&=Æ9¶nÜÖÂ›`5äÊ
Qüµ,a~v‹(šôÆò)úºÆ•Vl‚?Fßè×ŞX)66À¡?ªKn+ˆò‰'ï(85ÀN¢2ö¶ÌZU}‚	5ä² b×Û?œê¹ ô{>§BLYY±Õ|ëu‚ Qñı™heÀ‚uytÍIFk&ÜÄ±Ô…ğ}÷Fu—Ğˆ‚OÒyÏRŠ[€œûf/”úŸ7<î´2ÔQSî­¤ïÀ
C—«Q3Gî÷zçãÛ ¥t09/ôÉHÒ÷ü	:S±²½JéK$„0¥ëû—}P}İ,¢¦½ó“q¬áãôş¬“Qx•á?¸8g„à›#áÙ†¥ hw}bİ9Ó©Âê9×ƒ0w|634*@çh‘0¡,ØVë{e”R–{]Eşî¸®)­°ïÌl¦ÉGñ ­sš=zÒ…Ö›ÏH°â¸„n÷ˆötS‚W&„_ÆÉ!ˆJ`s–«õBfr$¤]÷\‹˜^¢üØßêış]RóÍ½=â=<¼`€×ê¨ğê—ıŠ)0`7~ãK·Ş¦6ØpŞË[&VûÑïœ¹çs¿nZÛ9ÿ½ò0İÉ9 ³è²FÅÇğ¢*ó?äOæé„®İó3l$1
SÊ†tk(§;Ğ,ÔÑ™şh¥™¶åsš‰ÒYcŠÍX…°úeœôå¤EŸ~âá/ÉN“ƒ¸µ!Ö³Ÿ·$èÇàxS" |¬ı¹€4ë­/¿şEÅyQzjßŠ†úÊ§âB$³¨ã×Ñ«ä@&£	¿ùË5¯›ÔIÿğ/‚–@·9¥)‹*õº·WÖhñİ3ØÕ÷û›ôññê!'zYËñµôUJ·¹ŒuFĞ‚+Hò'˜KålŒÊF…¤>‘ˆALçÎ½ç“òñK˜N é‹…{Ü4leŸ²Ä¡4Qs)ˆMIŸÚ‡ñü;,rÑ;qå8ˆµ›7ü»§FNEÌyšò^Ğw.ùBBa†š†•	§NNı˜¬¥ DÃHÆœ+ç÷ÚüÌá¯ãÃKí¼L¶=mæ2šjÆRŞß

„>ßıNTªû° Q#Ä˜¾~‘>Æ°·Œ^ hğ	\û˜Zx¶ü‹¼š´’Ó˜ÀÕnÑ8ûÃLmQ¸l*”ë›[i RÁ[Xû’c˜¸‘†é6´ºÆ¥\E©¸¼şxÒ	M)‡>}‚z*â^2NŞí'6…ˆÃúÅÉ@É¦ß X€ZùaØÃ@€kIÆ`Ì!ÎVóJUXî3¥é3ßf[¤ ©3¤<ì2bõkInü 9Æ…æğV@M|vc‹™ßgR½%‰ÖµÁÆB–ª}àv`ò[¹Ş[ƒ\QHü4{’h\;2¤ŞÀşpÅ¨ÇjîUä•”	ş`Í¹îâ)¥­œNE·:.‰ñ@~j)ºœíQvFÈQÉ>´ÈĞ{¯A”¡C(ŞnotZ¼ı0H²yôµ@GMDÇäé)…z>1·eâvü%leh¾m‘D¾],úa“«ı^İÅ?¶5ÔZÖPk?
ÒÕo?çP~…^àµÑˆŒ5rèœ(ãË~ê@ZÅF³ú/Ğ„ 
>Áú‹¯„-ü@ZøD›c×6p`h:aÒ >M@ív£ÁÛ‹d—{?¨Ê–m‡Éq¯a??í¹À+Øw9÷âƒ‰ôDaºÛSÜ35³0„º½ÌkVÿïßÕ¯¬ÙÂüÖıÅ3-§™.Ím:/³__:MÌP¿èEkÊ¾$Ë¡Mïpï„Øú®®áÉI§:†Ç{ÉtsfKòÍî¸Xò©†¹íàqBşŞ²ºpH|õ^^£¡Fê?¦{ÅßËÑŠÛƒòğ”ù'œi]WÀ	¤O¨j2!Ë¸/?2ÛIãş}ÔÃëÂ§lÏ`BãyePÖNÄw²U¶™öobKú˜ÃP¢“ğÕMÛ\S­8û†]O„¨u.éz¢[à¾‰r%…±0"vÄöXLg4ª‰Ñ>@¸G7²ıvÂ¸ÿéÉn-¨ 6£*GûT6¾ 7¨…¼,¼|ÄmGV¸´'Õ«œ¦*¼6ºÉ×Ü½@ĞV„GSG:AÓbJ±§4š•­WYœ71¤ Ârt:üàc¯lV-²™Õ%AçKí²…k–‚GM¥LeNG'êƒ? u±ŒD!†ójIzlaŠ!ÜGÄÂ<œŸÙkB…Zh°h¢êõl~2yV­r±«4øÍÿ¡Ì@ª^TŸv	Bıy…Úøƒ¹&JĞgX4úĞVA†nM}Èywñ¦ÁN8ˆ£ÛÉ³¯Ğ ¹ìœ\V‘åmÖ
½ZckfÖškêyê—¾¬¢ºš|b­#!©:”’§¿‘×½¿xæÖ†EĞÊ¡Ş[}`EfÏÛNÁ°©D*[ëys”èİıc–g‚C£İÿ)Vì´İè÷>áĞÃì¬¥ó»µ¡·“îîèäıˆ”÷¾·¦%çqú)¶ê$·²gÙ¶–Œê.ƒ¡½RBQ|¶óù‰¬vÎf”p5†»Û0Jå9F«2M@á¬	S+¡z<a£CS\¡eñÉ¸ñSP¯0Ï¤_œp,-+ÉÔNnpHdL¦Ëm”±Âƒu—#"w^Œñ¡6YUëÕŠgàk„Ã!yg$ıi	oŠ:mn;xãj
Oy¯™;:îäà\®Äš‡	İ¹…×Âõ¤jk?~a5<yïìÕoA‰DHí=.kÏâ
$”9$¾hâCTİ£GõêÎ.Rk²¼Gh$Š$…K!tçŒ…X³nÛÃ<9ÊoÌÀ$V´»Nvæ½×N©×d#úf·€{“}½Ü¾+ÍSéS.O£–ëR)o9²¹ç‰T´òcD.°_Üº¨¯Sõ(Ox¿ÔQ¶“O©IiÍz5EéĞµìã4~é„”*„Œ-Ü4ôİz,R¯¹a*Ë)FvÎ#’ èÍÙQ…F†¬™¦ LîÛsİ\ªhK£‡ÔË¨v±û^üÀıQäı¢óV›Ğø„éh’4Õ4ö¶Öó{š;Ö:´³K¾BælBê0Ÿ¥oh³¡ù˜é3«9O$«ÜØ“¢”Î4™wZ‹C@)º„å÷„š5Äşïî%ø®ª]âgøFêCFOT™Š=oT»*Í¤óó¸ğ‡å5íßc|e×¿Ôek2ÍÅ(¡}Âü)Ğª.ÍÁÏLNĞ†
“I¥óGÑş
”£-’
ú¹ˆ \b‰$¶Õ,uÃ„Ÿøš}8ë‚ÊMss.²šèö!õN²QëŒˆà¡¯ënp·.Î—Î‘:˜PÎqY Ê'#ÑŞÿÔñä ­;mgÉsòÙ8w‚±äèà™Ş9\¶W1çª6#n¼ÒÉCSû Ä“@L¾øğõÃÄjp°¸÷…<Ì«vUÂjN{BÕŒöº10¹’e€t-½eI,Åİ÷(våÎ¬lDx_·ÎÂ÷†	z—kYÜò™N7RæS˜”{–ÑYU–LYR½Ã¿Ş‹8‘¼A¼xŒácG21ìÚ»´ô¥çkRm‰í.õ†[½ÄgµBOíe¸¾ãú^è¦‰0·ùQYÛÙ”â&¢ğUª½p—a4¼˜N/±4sÏmß¾weÑ/(Š™Î„œëÌpë{‘¬8<÷ĞˆtÑåÎ	©ÆQkÙ×İ‡¯Üé;_Èø6ƒ?ñêse›X^¯|:V&Ô²“#+”2P÷ò¬ƒ<®¢˜Vïy;_«–û;qî6fV32µŠ~K#}µï/‚?Ç¾£[®ä}ÅÍGpó‡„Ÿ½¦Èt˜j·zQ}xCğLf»’ŞÊÀeêts9Á %‹àlpšÒöƒù÷¨w®V$ñX>cİymú³Nzœ9Å*üt×®¾Ç‘¯èF{Mj&ıİ‚Äƒ©ûçìœ¥{q”'“Â³™˜§ÜRsÆş•äĞ\¨«<ßô#çµ Íª cšW5DIÂ4ºËíL´5*m¡:è¿‚½©J$„LaÈ)LD/To¼ 	™Fƒ¹Ö[à”eÖC®³œ*°—gZœ¨î¬!™mÂím8Ê´AÔ.W|VíÔÕy(Í5p(Cal3ËmÀH	TG(ËrØ\•èWu.k€èÑÙh†¶0æ1VÅ`pO•QÜWPptyá…“L®uzKLÑéñÉ ›ç{ÀéıßÏÆ§–RQSÒ™êR|²@
°g+‡p6\»5ã	Õœ”¨Š£)  j€ê=õ¸?% ÀˆÀé`k'Ç¼æ¹„ğôópCûlÇ?2Ô¢GËîD…X<­wÙ}dBl§:É~',æª¨ŠÒR®â¾gÌ5Ë)_@ô¾ZºÂÁx‰†~“f•aïNW'Mÿ^ŠN©™¨å‘ÿ[ÿ­;w™Äàe¿yNÇÌ2u€¥0˜èî˜|¸ÈÑâ3ÿ^Şµu‡µ^Ö>Xcº¶eµyÜW ¯`Æô]•€ÁªÙdÉOøZ¦¢‘Ó!0Éš±)u„ıwQ¿I*Ù1_2ãÃv‰Ø¤‡¶Êv’‚îÁ{kIóÓºş~S7=*–˜ÇÒT	â@1PèF“AÕ¸<Cş@î®ÆïÍ^˜g›Äß–äÎ2áìşv„mş˜Èš–ß2/sãŸ‰x%RF«hl¼·~Í”D‚¿dÇH	L+P*§2òéåÎÕı*é	Ò³ w–|qEç.õø¯ù•kÙYœD‹”Æ'úŠ«¢T×-M ªq¯F†„­Õ‰ºÆñ³$ ””]ËG[Å77Êü&†Yj•î¢ÄXDxZ‘l·~Í]ÜFK§±Ú·mÿãõœ?ÅÖs½^ßÉÂ×wà(áFéMmc¬9V.Ğê}Eİ•9`	Y=Ú¬ğ£z*ÀÌ»=’¾hÁ[ÿ©²£íh5˜¾9PâP½XîJíäõÚ¶»ÇÜ[2Æ¾[A)a™´AQbıŞ\)¸^ƒq¬ñ,ÑÉsÉnDÔ³°W.ÀC5ÄNyj	Ÿ ›»§ÎÙì$¹şuõ'¨¶ú·u×ËògRØ£Gm^×Ú«îPÕåe«8Ó%ûÜ“ã•âX5Ğ‘ŒX?½EDƒ4vAı›ôüqL¤£Ş+ÓWõğ÷Aww¿Ğ40AE‰cEAWñ!—¹¼cyx|àOÿ¿c	ˆÕ„çM§HÇãbòÆ_ PáG\_>‹ºbåe¡u@ÓòõB>ŒÊ=0ò¡Ú¥Iõ<Ò”:_ t	Šºÿßå•"«ylbu!ë"Œ“-?KR®z°8ıúO›ö#úPÏ(­õl–d9kûN+‡cÊ|sQåWéô½õ%;YWšß¨_*±„çsZ½áOp9AŞEÓ¡&qqN¥;‰Ñ§ËC0=Ÿ>KÒ×‰¤ejm 	mWpŒ^f¨~ı'ÌñM±U¼Íë¾Û¡YÓqó‡·ÜbffµÈZ˜ïUn2u~î®0-*®j4A®ğ/å¦µ½uĞÌ“´/3v“fñ-³±öÓ?*FáÍzfŸ»»B‘W–ò³x%µ ËŠn&æn“DtZX63	
™RnÃÙªJ &áÔËûÆ
qÏ3œ@ÆÌ‘èyp	lP…+‹Wºå›Ì¡Å¥H&†tŠT#³OJõÿY8¥˜ó~0È­EbÃ¡€ÏÁoøıô~@
¡!sMrÏcğt‹B%,MÄ½œf3 µòLåİ†–Ò¢¿VÕ‡¡<‡DÆ¤ë<(”J¸…	®¦g¥Îâ¹<g7l÷>sDKäàP œ¨ï‘4¯š•Eş]ûgú¯‹zQ(eJ»ø©=œò"é^¿ˆr¿”±QˆX]Rl~iˆ*Ašp%œÊ›û÷ÜºÔ\çTk–&âÎ‡sÜÊû <Ø¸x;“ôà6Øb$³ñ¦Àñh÷¿P2Vx8lÇT …¬.M×‚NŞêãˆ˜G9@Åè–I¥«æ (× xœ¼¹SrT`yi}È²Û\Å‘–Ä˜ZèşÏ¿M …<~uğ!¥àx&Õ‚†ÊÉÀ×+v¦|LRØ¹şà1„‚Všİ÷ï~(t^Ñ¼vìaQ´[Ò1Ğ‡{àqÌã¡Xı½Ú¯bØÍº:{œ¤oÈA9ìQ˜æ_Duá,4vi¸4´âş,»tëUİ«ìÿ.€)×-.•}nò7Ğ“ÉÀ„ºÛóŠœ#co;(Íı+”¾¸bltX#‰Ww_‘>WJƒ7Ÿw®ˆYC£# ”ÿCœPUÖ…<€	8ÄZ[<¸ŸÆ ¤- ÌVÌ4Ìo€õÅo0,gÛz–N¹rÚWÒß‡€¶?õ•íùò¶šì õÆoÌ
ò÷Àd‡A‹[±´µqÙUlVsœOEûıFtI*©ŸküôÈ3gë6Y¢!–âŞª4‹Vª›}¾ğ³FÅG$¨Û$ôêN"¬xû$…VÊåÇ39—%.Ä¯ÜhbğÅÆìƒ1e?°ÜÚüT3­a‰’3–d²–«¦ioe¾˜DKæÿ|¾‡[Mn—©ó®ìŠ²Ac¹¯_»„˜E¨hèlÏ7Ö¹l’¾_³ÑòÄ?y˜ÖáôihA›š:¥˜ñ2¼\QuE³Gm¤9Û
u®ÿ»— Š÷íd?Ü°«7‡©àÅôT˜Ú¦Ì®²Æöÿ;w¨‹†µ_I¥‘Ç×Nf,$r¶>…gE3v`mÃÎù9m2ÿ?ƒp®Oec¥ò_¹Ï…†Íõ¹1»÷xmV À«@’£å7UOÚ6ÃÅ\ohîeşŠ®Q”À’Ö{ÆElPemÑ˜äÉc±1 ±¿r¾áµlË7æ­uŠ–]l¶s%t:kre4º²V0Üßá– "R‹Tˆ,%vÃ,B3ÒgmŒNWî¬]Å˜]Ñ=•ñÉœAB”+«/w¼GU~&"æÁæî qõj‚ñ­	Ò¸èµ!Ş£Ì®<-²}òE™k£rs‰ù#ˆb•¡ğ‘ŒFİÎø¬;“ÑÌ[…iš uCŒ‚“#şWdjSZ dİLi \á8VÂçR‚×ŸËïo6›2*JlºÈ÷j”“7Ğn¬[º£<§ÊræK_w?˜Â¼òŒiÔ°SÊĞ4]¦‰/ØyehRNö 1=Ç˜Ãò^kUmÉ}ëâ|[­ŸN¾¶ªı6®vj	³n6‚Á²gŸÊ‹C\"šø¬Íf›'Ö±gÅ6r)W|®jyñk´._NNôNêÛÄQ›ú¬iŒ½:çòwí‡oP¢ÍŒÒ—f(hèzÒ­­¥°A£R±5aæ*Ú¾wˆ¯x²Ş
,„Î2€Òª´òùõËò¬°´‰–‹¯·Ak¦*Ù¤å=tA:¯k‚0g™õ¾Ê¤c^¦Ğ¦½ÆÄí%$Jú/xG‚kÃİkŸ¬ÙË¼a4İ ÔoÌÓ³A"Ú*Ÿåv_	»]O9(3­Cÿu‘X,/»„øSè´ˆôz y‘:¯º%^´)e^ÖÛ€~ÖE·±Rõf:ìë´ìşc×<ë-t;Y KÅ7Ù÷6ãü1ƒ½T&veŞâŒŠ)S#Ãü-/¾e·vKõ‡“ÆÄ;@œK‹RæY!&ÁU!(FaÅ¶-òìôõ2sFQø³o‰©™Õİã˜]Ê¶Pœhû#±	qÃ«5D‹®ÍO™²ÄĞ=óÄÓï@®»ñ¸*>ó ~r)¯¾‡×P×]itW7ñ
*ı/Ã,H$Õ¸2Á2 ğ¬ƒÖÎÜ+xA~rNı¼Ÿ›éYJ°nUZëá{¡Ò­¼òÂPåè‹´8>j	Œ/@SHó~­#yšû¢ä°NĞ‰5¹"ÃPˆ³Ä[GÆ çğPyÇ xAeµèŸû’;6‰}`ÆP³ÃDÿ4•›âõ:ÖD"áQX²´EÀÿ¼Q©e?±zx5ÊœÚíUKÄ%P`H) 6e#i0wM¾”'ÒÄ¾r
^E„`ë\ø	‚}}(D¾ôeğ–·]‹}vbºRÎ,ÈTy¢W,Sp	—tÉº˜³N'XŒ›G•bŠ§uÉğDnà— £S4¯RYµ_P2wS3á®$û@	G(ì•ù™àÿ/ÏùpàI?Şó|Cé ³%ó]²£rDİ›C)ûkm{„T_‘†³‰Ÿy…ÏÖW×-#¬Å˜ª³2³h±&8L‹jX+\<L4cß<¡H‹Ê½F2ÀJ7¿îS”êğèd‰fâõÌ0d
—K1bÛó;é ¹TOÆX,ÿhå„İOl6ª@~ü:Rî)	@Æåáy¹Ç—Œ¹È†Æ}<ó>~V¢ÛKÍT¹¯I:Î}¶¦Õ‡ãÖE¢cÌğükªêóBÂC‰Jï`Î¬­ÒáÜrÜEK•¾¹\_ë”%h®°ı1š*?Zª¾‡-ı‘ıÂìÊ©^E[Ã›ˆù1Zça-'¬œ'|·bp%5ó}Å y³¬™oã1O£e JbP6bsnß)9ù˜!`ËĞËÒ]Œƒ½mäCB`»`²·³ÚJlÔjnñó÷Xš]æür!Üò°¤?Í›Îô´a÷„±É5Zğò¤Ç4Ë$¶ÖEË\4HB¿ç˜†-Te¦wÖI‘º'Å”q‘xî|B	!è¬ïóìW(FË.vØ1ø‹<;DÔ£S´‚R_Şh’t8³ui¤"óQtí|–`¼q=`Mb\L*4åÁûBáı¥€UèôÖÅ.ìùß‡_^Gèºô×8d’¤ÅfØ§ÿí.]ü~$µÌ¬höğ®53Ú3âùæo§ä+f½ºãrM³7¥ƒc†G¾Tä_¥-ó)‰?eë—ø$S‰\*ØıÅ&;HÏ"Ú+	´Ã€ö”‰äÍGUèßíÜÆ»ş`×w(­Æ<(æ×}ô;çDÀâÆ·’š('44±6¢ÇßÅMş¡¹’Øêo2“d9Ø¾šÚœ7µ:X'c0,XeÚ6åÇ_ŞÅÑƒB¸ è:¥Ü4ó:¤jyœæ½S+ND¾:1Õ­|EèëGØ~¶údÚú––	ÏiüuWŸ”ª&ù“/]áDæÃ£\Ó²tíLÅ0<ämIı’Jut§S5[`A9û¢ÆR°Eb×PÇ1 ²`´nóÎ&Îi|y°s[\	ü „kæJ(êŞ‚Oğä§ªıÑhJH›‰>?ùã¯?~«}Ù¨¶2æÂn*©h”3Ÿg¶DÂ?z2Hû2œ“"XúëÚœ„İÙà±Q‘Ÿø
gšîXX=Ó‘ªï5~AI´}6äp2¨g÷CÈ‰è»c•ÇÇ] nøI}o>›¡û7İğE¸8‚VJÙ!¬ÎAX¹ ÖÀf±
úµ`ìğ‡çÒaP/î×/= 2(ù¿+ËsAª @Ã
ºmVÓ^¯»Aoj7½„p 4Â$ís6ôs‡ïçjÇİŒ 9ö/;Àâz» ú{àØ0>@"Ã0ÿ9õ+«ªf³æ<cGá&zYçM¨-²Š—ÎKRŸ•ñÄº@¦‘º°ÿŞbMGxîÁırİAÔ£ÒÏ¤ßàaı*\³2hˆ–äOå§p{‰/¸OäïIBN³Qµ~Å+Iß©¸dğ0xğ·ö!É(§)hÀ—uN{ü vú§Y›‹&å*d1œX1zlû•›))­¡j1fX6E÷ƒ•YÒ÷\fƒµ§ç>Y#høËÁ¯¹²ZôB±ê–‹Œ:õ×óÈÉõ£Ÿëpˆ=÷¶çHÕòò¸ ™åß4îöpğ!æ'ÓÑÿÚÍ*dìVW"bºÂ·Õ³¶˜cIìªMe”e}³Zñ`¾ıE±÷¤!H»²„06dÍ§Ãï eenEW>í›EÜÚ,p¤U£ÀÊ€EöQ¹ÕÑ(Éß½æë#C=óTŞÉ}¡=TÊ¥!ˆ{ı!¤ÖR]ü=èÛÎDò  j„uì“•c—ğFyÙ;‘à|$ÒDxglÛğ.É†[¼µÑÅ$±Úî*gs%è€Ü²£ rYc¥ĞH61mN£a²ÇËîr>s|›Ó4‰é&ĞNêO—Y¡éNÊÛ>¨,ÿHi8-YØ·ŒÁ§×‹Œ‘™‘Ùá;Ô\`Gä&¼ò
H×Á$ùáï€9nÃïµZï%|®ˆuuc³Z!Sø‘ÿp‹Õ¤Ë+¤H1¿‚ÙgÕŞ‹ñ†nÒuÌ[!Êšla`H<ÅqØ€á<²ää4¼fkÙdDBN^ë\mLÜKnˆ¦¤E$G R435*h#¡´7É8÷¥›ä½k¹Á)qê+êuè™SÉRD6Cğ:Š~‹Ş´°_%iqÎó·™™qı ùú‹şG—¯ rvmß/Øíä!8¶œ¬if»iSdu¾”‰kÅ"àıºŠ·KÜKX·æî¨ø:¾ŞlZ Çúw—´Ge§ËÉ‚šY+°"C$=Çïy& œÛçûIì+Ü‡£[‰›crK‚*X{ÁãÏºİ÷ÛBVİy†bZ
gŸN‚1oŒ«P¹ãÒÏârw«N!2äATµn¹ò§\ì(ig¾“ Ó¨±üd¸u]ÇVŞ¯8N]ùLÙ¯(ÍÄ-–i‡²m3sj	ö†ş=|_ã äLŞCT3€1şWTP„‡¶Á"RıV'ºd±ä¤	šô¾³TËÖMÿdqRoÑ¢±O—\
î˜Œ0|ÏÓ®·Û*%+ í ˆfÚ"kõ‚ÈZV¦ÿr»]Bb—'.T0f¹¤œª-J”2Kæññû“‚9Õ†şô«óEİ…Büvò	Y#ßÊÊywÆÌ•h[ë÷Êº{1 ¤*0F1°…8q"¿bïxŠŞ‡ÙAkJ¼eì‡º#yPDöX¹K¿ y‘^ÑjâƒZ—›÷Q…¹ØpHˆ6¡¾Æf¢=BTnù?;P+¸ 8é Z¯¤Tù12¼»Ê¯­•WúŠ¶ù¥éñq5mÁ"Uw’Œô_åBä®œß»ºbE°]™v+±ğ9mê\ªéÚ”‰•‹H›¼¬€Dâç™ôF•Hˆj!õ²ÈÅj±÷¤Jœp?ÁRs—¨úSÀUWÑ»|©Úggú%,òFœ}ú­Õ(ö|×« ¿t³ÖÜì1G6£ã€]£Qí‚X¾ N'\®hÓ~ùåp¶~jÙ¯a6ŞöjÓ;úÂ´N7MxLGÄûıu¹cu R·º“E—†1e!¢ªPj½Ü¢ŸjÜPíÙgì²L¿Z:ùTK0ç\Av0‘
HÁ}z1NxzOÆ"£rKÍ³t™“ı:fVdË•‘p°.tĞÕï[×WJ"<šœI¡óF¹yf‚~’"¢pú'<(D@]õº¾¤OKË¡!•‹91¾§yö¬0¯S2ŠÙ‚$*É©¬?{¹ûK ã/cöÖÊÁkÄ=ÄÂ³_oQÊ¼ ]ÙÓ2S" ı®È^Ô²¡.ĞoŸ’é¸pİIœ•ñõöÒ§"DÕïçxK&Ó‹gø2¾³Õ]³5dy™u³ßĞ^Ú¬`½òEoe‹Ü°üs:ıù¥í°h€"ìm´İñ*KŞ)Ïk(şE£]ÛŸÙ€^¨(QÓ	9]°ûÖs{â>ó<¿sØsñå©:v¢:LV_áÅV§Æ{ÊnÏ ÁZ% °Ë:C¯õû÷¨¸‡Ë†PÓC¦BF¢ER1cõ‚Ô´©Èä
§€¾74"{ß·ÒÁæÏN
éù`‡ ‰¤*Y3kë{ğå½Ly4­V±jûïü¹t‡ˆOÿÓùxğò$1î[=VIeÕå'/:÷ =-È6uÒ%Ñ`ÕN)ïòf³a"HŸé{(N;É]}cëî5Šö;æ’J)-³ù¸ÆÓ ŞdÌÆ^l™ãÙììx!V?<Ó¨q–ßÚ;ïÛÙèÌ’ñ`™…¥
Ÿ0<ˆ±t1ÿ ÇÖúR”±P*æ°‡û!\¨E-(ºˆá˜Ï°¢^”Ÿd1åo²_
@Õ±ë’ŒçBÀÊÎÇò‚A]Íá§fíLíY_M)’‰Î&Ïù›mfôši÷•Ÿ£ZÀy€B	í´¸Û.R:c|7,Â›¦öçÑxHQôaŸØ0+ÖÒ]t…½£©õœ‘‰û;º$ÊïÄï;èİ¿ÂDœ#¢¿Z¶NjZg]ôè‚„5£¹9nëÿT›_ËàÍŒ¸ë·]™”‡m†¦/¾ÌCÀékÎ€ğHÜ6r›	ûqƒ¿Ù¹\ê7şğ%aLX¬søp|a‹“¾Şz3j;õt¬´¦Ct	­¤JAÏ« MsïJÚYó¡?ˆ,ÔB‰~‹MRõÍ3ÎF²§1x+ñ}	0?oc7Å¼‡R¸›ï:d¹à¦êĞåÃù® mĞ±ÍòÆlC÷Cb'|[rMüÉâ!çä‘«299k´{ej` /ªSŸ?G$<;u*…õyEø»*ø95¤x/u©]óÆdï_Éã/ Ã€ö¹¹Z
oî§6şa Š'®¾Z|nıgû¨Ó[©[ÔÍ‹Á	š«U¯+µW=IÔ_YA;F“œà´İsÄ_Ğ¹T†¹ÒRÛ¦¶¿ÀâRMPVänC¾ñEDø©p<¾ğéëé€S‡§$£†§A“€Ÿ"âq´væö;LV«>2#
å».°›h7ğ)ƒ«dÇVó°Îô‰°À“ñ«b×ƒ5‘y²¸×µ™ÿ¥SBı`†óõĞÀ%øD¥³Ù1i	×öï…kÕ/Ëõ ³ıÅllH¤İn® ¤VaÉbZk!ø“p$ø¨Bª²«;8E%—Â´{®Ì7®û¬ÒÛã¤…f»M×Ğş¸ÑÈ%ÏW`î±b'éUJ67*M‘¨”È,ÜÓï[ÉĞeŸP{YÏ¨>&:‹:qÏÈ:cuM–>›|°k8òŞâö¾²à”ºÕšîö1	3¸Ò”º¥ãTTùœ·š<ÙÚw½"õÃXïÖT#ø1É M&øVÏ˜Ï8âÇ<4©M´r¼c	IÊg¢(N–x²‚ËÕ‘DÏ+{†¶ğB‰>§~_¥‚Ú×c³ç£¶»ªp¶+ò¦Rå!·ŒKÑp”º=£m{WV•¦ĞaDJDêÑ_DJS‹ÅàZ<Æì;ù±ìAÁ=ëwcŞÅdâN8ŒÇ‡>7*jÌàÈ‡ãÜ’òtG"İï*€Õóª~€Àw*8O‹@õrÈºzö=¤'ÃC¯·şk«d™ånÙ­rÒ˜O$ªi›ô²À>—Š§“4S<‚•´™l=É°9AŠ…ô2ù÷¿âoeYç>Y[áÿß¿Õ/ÜJäŸ(Á5Z	$&W‚Œ*ÀQLìA@C&—Û~tó¤p9^õ˜õ(«îå‚dl0l›²/eDæÖ
é<!={¿ğ„1>£†[›†//Šq>0ÚÃ±{à_UëaÏP@EåÿSB¹6a1ÊÈØ™[îıˆàq.îøAx,’)ùòù…
ŒâµãÏ÷CÖbY3?Åiß÷çSL	Ë²t2­¬—Û`Só=¸ùÁWJ/Eg<€
Ü!ù•èLÚZKC¬5ÜöÀj|Ú¿–ú‚IüJè8d3Îv2{´Q>dÇªÛ:Uğİä,ƒÔÙ-×†CßÍ°|‹«KÍ”°V‹ûu¾’1ÓnúĞˆÜøOÑ<JkÅ²İmY)oıı§3bvØö†¬WÊ/°A~¤‹pújépØó`}Y•m›àm|V‡CU	Ü‚iˆn´À2ÿQ‘´›÷k5zª¢À¨[%¬¼´í¤$C¯m,øúwÒxÁâ¥aGÄ Cb62h(¤ÖJÄ(NM°¡Cw)~€¶ÓÍ*NŸ²şËÇ„F‘Ôf×V°²xÕø]µ‡DÔBÿíy@‚ešvcÍ<+6ËÏØy“wDŞ&ª‚H¼ÌQ7r~!V¶Xå½ô™ŸQ¬RÌQA´B™+›9'3Ãœp Ò`–¤x}áfødÉååU;¾`ÊşX¼ñÀËDv©Ã²Ï%}Î„Ùtç-˜|úã‘$ÒnÓ“¥‡²şàœb|(ä
QˆƒHÉ6Ñ_EìáiaœâÊ³§¤Î±älÌö™µ@Y@Ù*WA°x=˜NÅ6_›ZğV±üÕu–§&e$[ò}­÷—h<ƒCÒ=È¿pÏ9™Ásx@­CÔA&Qš×o‡‚Çv÷Ù·ƒöáX…$eWi¼®B2œ
£THm›Â×ch®wúú´ÄLÈW8%«.«.×¬sd«Ìi]f÷İààíÍßDG¬aØºƒ%‘ªÑ "^y˜ÖrWÇZ…Êh¶×ì4sYfñæ³åÃÎµÖ—~*8ƒä2Ì0x˜:$–õ^ˆG¥kóõüÒxYà–ç,şMzÓ=WŞôÿîE¹ƒÉyæ¹‚Y{G1>CzXŠ+J†I•Ôd‘İT£@ß('Š×.3psÉ(½>S:èƒ§d~\4¨¦×ª`àÎro?<$™b®O>Ğoi7¶\šê©Ñ.eş¨›ã«˜PÀÀäW$Pw§WÜâ
r¡=¤ÚÊ¥æŸWvî Yİ¥_2`<ß9ĞJ/pú4/Äe'Åª¥c-ÖçiŒbK‰ÌŠmduíD‘ÊÃOë~9?ÌŒïÍüÙ­fÙ ¡Ã±®S
§ü±ãÖøW‚åûÓó”¸(^ŸÙ«â'a !l<¡áÇ8ª ?”JüaÑËgšdao÷
'ˆûŠ9ëÉZ´&Hğ¬ÇÄáq/Ø/ÄûŒû }×Zß-ã‰¨ªü<´ 9L¸›P^ñDW|Oê;r¿€pªtñ/²û5^‘ ¡gß€@É(amäs},
ßÕmÅMş B×íYš*8àW Ä4h?]\ª'eO+[KZ™€ÍÔMçŸò8÷+µÓÄdñ5oÛïáOVï!ÇF=:+ë&› B–$iw±‹3Îjz+r#Ğ£Ãã—¬”0z%Íñ:)uÚ8,)BãßÒ^“×¸lP
Ëp¦µÁ(Ô¤5üÁ:ü¬*Ôì‘ŞbœAŒ†Tn›w.ŞÒè‚JJã¡°S©•Tİyh;^¥¤_²„=Ã-—tåµD4–Z6%Ü?G"w8“†îNÉšè°½‹È›ößF¥Í6©R’æ“3´¸²XŞ¢£”Œ^oó¶çÕ‚(Å®Óò=k8ÍDuÙ%F¬ÿ³[›
²¾aŒ;µ®¿v ÎÕ°R8:t#†Fò„r¾€İ5÷ÎgSõûØâÄ}zä:ı€RJJBÈ|»Uîö<i.lTæ
È7]í¥nˆù¾ši¢•ò³ˆõ>pÓŞ¢ÔÙ™J1E&şëËpüqîePêZ,Ï\ÛÎÁjî}AË‚ ,€ª=Éš–ÓÙK½Ô¥7†Gİ¨ãğ2e}¨[üÆ½ìcªïØèÍT>¦²[Yá‚4½Wóâ?1øŸÇfæs´¡# “‰š•™ê™*1éš~p©s|h`»)¶Û³±òhõiNÍZ. 'CXï
¬OŒ«G¶?"=ÖãQÌwõ‡+9ëStö«Ë·v©q˜ç•+ÃD~Ş_ß¬'eÔ,ôÊ‘şÌ¦o+Ÿæî¼M1 ãŒÍ5J
Ø3Sq=ñUìç‰Á9;Õi¿ïöbPßÖÓ8)wOÃhxÒÔ˜zêğGÚ«ÁéyQ™^Çpûã]6Ü¤ÃK¶G&´öEä]cİ}séßu›:³ØÎöŞvÀ5¼¥](ÃBòäAÁŒ#‚™Ò^k,âßÎ)iÁ'ßŒñ%o‹OÈÆSJ„µnõDï^VF-ÜŒ¼H’şÿ#èĞ©ß€ã%¼Nµ´‹¤ØX•l²+f³Î RÀÈ´–«¸ö·‚-äÁRnw¹sÌBR`Ì=$\ …¼«ï‘M2·ÆA€©+ñ«©ói@pIÜ_T'p,fá"ê_¯Ôm|Ã<€›AÖŒ"O",GêZ˜D!3 Şê‚˜Ğİçrit¿~q·}	ósH¡‰=Q§J\Üoİ¦ü…Âûû¼i)6Ò€R Ù•Vcõ·ó —®é2ÊcŸíºØ‘æäs_mŸzõÈmgEIeŠ'#K<æq–T-æ–ˆ/n^rúL¡[âB# öÅ¾ˆ\Q¿ÌÜ§ÔŠ¯‰Ídaõ´œÙµ£ÆL=yE½»d‰+E|“6Ô'àÑe§ÿi@+Cìxõ“~èˆ¸6`†ãfb0–aK‘'½5<¦ÇV[¬6‡’XpÑ~ˆÚHÆµõõm·)HÃÑ\‹#»ªNˆ¬·ÃÆ>‡ºx‘M;€©–Eâ˜Ê},ÃİÑÏhMR9vgö®.,ƒ—Ê&…³ı¼$
ƒSÃ¡t‹eÃóûÅ´áuDÏê“Q‡¿¶#&cÛÛ4 2ş×%Èµ‚œ@mğ´‡ŸGaÊ!×Kí)éÚ8,Ñ>µQõiJy°‚oõ£YÈ"rûpîˆ°Õ›D
OÏ¦ëÌ{xC{.A@v7Õ •^éëä¦ŒÖ~œ×
µçŸ÷[°Ø;Q†r>jø:îD4¾7ú×Ùã† ÿù‡4S|%64Ù‘'íQébº¸×¹Ğœ¨{îªã6ÇğºıCQid]1›²ßE_zâ_g¸©6î„¯˜?Mær*Ç‘dkE{>Ó]@;­w—Ã_NyŸ±†İ))9ae·ÚV4†û5ê­Üˆ±¦O§‡¹ûPcqXA  K ÑÚO¸ ç²€À›š®±Ägû    YZ