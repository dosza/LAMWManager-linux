#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3130454690"
MD5="eb827254ab69706a04be1c4c1749003d"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23576"
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
	echo Date of packaging: Fri Aug 20 12:40:57 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ[×] ¼}•À1Dd]‡Á›PætİDöoÙ~‡»È×kÕØ¨!|WÆNâô¶Ö¤¨ôbAÑ¶¬€B€sb–w‚íPÍiQırZ­ºòâğï|Rò˜ó³†ûãËdõóM®ÍÇzºêoıæ](õËdjŠøçÎ_-ä>½ÿà7Çõ'¶^PqØµ6ª8©†N	‡»$áDH¡¢±£öß(L)„Ä/°@
,­7ÏvÙwE˜ÔÆÅT˜%OK‚|EPÄ(QÔNÑïÁ¼èÚ cHdœiîå—äî2Úö_ñí]K3â¨HôáëÍÙ€E°½6®RÓìÅtÉ†	O5*­¦M$Œ»}Ï—©‘¬[qDN,WO‡€Wj9´‘ªıkF.z‡–tN®£Íš´­SM_/+ûôzu«PÄM7Y
ù)‰U®Ï.€Ø=¾@
‘AšºíhCÛ!ãŒ ¹
µÌŠğIªÚèkF±Q°ja4F×o'ğ¡VÆãxğ
]Bé´°etR¹iyÇ¸ö•»Û„ÇÎ¤ß!jâ·í—;³ÚLÆ;ƒ¢¥'Ìw	L6ä¢ôÌ˜¼‚¾İ.¬R,,@QO&ƒ"ótóQÃYÉÓâ¬È7Ã{rÅÜ¶t«ûÅK±¶ ¸ºa’H gşàHÛn/QZÿAå·¦o¤*8±ö¥=Pµönñ+Á–óş¯wó?7ršBvùÊ©ÎõZN†ør*…u¾}¥Cˆ¨ã]ÖB¼x4åëÏªr[v~Ğ$pÀhl±Áv®^zÁéîJIÈ|±ár6´”_¸HŞAÒI¿Ó&ş5Yà—OÀºJÉóp¯~±0æc*Ü‹AIjÁœê/imÃˆŸ¥­Åæì)FÕMˆÁz}'ŠÁ³
¦XC‰_ı„ïmò‡«I\çØyÕoæÎ’>É2)èŠén£®Ø«u¡Çq ‘Ø÷•/5¤„Òœ¯&'KJîd÷/<£m¼Çö½BÛ4ô\h×@üåLñLqÁÄà}\¦æ¯'ÑWÿlø
¶İ¤1­¹)LÏ¨hÑ8 QAçO!däÂDwgtrŸRJ…—æ^¾ÑbùÂ
G1Š´‘mŞ­¥í×§J¦hkŸÔ"v•¥›<ßÛ–‹­|\‚åÙZ–øİl°tvëıÛVõZOÑÀsæqê™”HÜ«ñ´ª¤/¸7ª®/¾¨dJ}$E•~4,*¾²2ßdªÑ¼GBh
Ø”÷©û÷Ê1 AùÓ¡{a	D<Ú›Ô»ÏÆEéváÅÕ±¢ª@/ÑQMËÙœÿçßÎò!È;ë-mPN‰0Õ‹ÒV\ä‘WÔ$"o
5ê	#<Ñ8)±·ìÙ6)±q…$FÃíjÑî$·à#÷_3Àşµ%3b·æ‰™å=£¡µlİdEP}ÎHQ«˜x"àdmAƒ»|Ï#«‹¦ÖÃ€úWå¨¿Å0Î!KËÄ&ó¬?ê2QEqÌÛpV)ÆÛÃÁÜ’­ı§à÷]ûë‘îÂâÇ¦/Ü¡+qËF\™ï÷Œôc¾şÁ‚vÿ‚t4jWv„$^íÃ=ûuoÖ‹]4–…ø—íÑ`:³)ô…ŸjJİ¢Õ
õÃœì›gu¡äÖ6şr¡Ìõ^3Òlæ_vG¾BTÃ""èÌGUmiğzº
±€Â]èN½¦X»û&'Â©,²#¼äÄ9¤ï¸½ºªi“BŠÚP ñxæÛğ6Ÿ1`£oÄÕÖYrè–Yà!x^W«âœrÚšê³Óã=ÆÜÿ[ŒèİMBŞ(ŞÁÿŞèOÂæ£+ı¬-I;?,jª‘ ½:” Ø•@|”È`üö™Î³’´e‚†¸ƒèÏµ&¨š<@èÓ²ßıÈ%ª*­¦8¯½“'¤¿œª=RƒŸñ~şE¤ÕÔÄ\n’j¶î…X/Xtì<…Ú\ÖA9¥ñgNçb9÷‰ÅÕ:N{Íh¯Ò[­ØW–:e_î—ÚÏÙÉÕ/Êëˆ…áC1ªêøKš™']4»Â¬I>Ëİk|Ø%ŠU‹L–ÇJÉx‹‹­şYl`}˜›<PX5>±AùO1p‡…pwù<tH-ãåJ|-˜Íx9'(‘*ô×LÙ!~	hW‹ÔyÙJUÕèÕoYj!K~Ç4{ løI<´U¬7ãã™H€V„Ãøƒ’ÏÍq¹é ;FÕ+‰è¢)˜$ˆãßlˆ{c„„ZÑG=o:?ÕËlĞ#lG¢6Å¶»
Õ¬õ…;—8;ÈÌ6w+oÙo°Âa	F$ŸºoÑnÕÌ}E=g„ÒÁ¸1ÒîFÅ‹St¢$Ú%‰»“úˆ&~¶[2œP¶s:4×…¦ƒnI2TæÍ'Xl•şg{âŒEŸ¸_ Ò)åÿ1…³7.õñÆe‚KéÔ£l·‡uñÕıÅ7dô0v.9Óp›¸ ÇÁ~õÖr‰i&¾Æà¤	¦!4­¸Jğ1>¦‹‚uğ$LZ/œ&)[T¼} ’t¤9İŞ*]oµH—‘gÓûíƒ&@ÍÄkõiû¾åğ´­5LÙ/>‘³Csô $ƒ+NÎ‘‘”ğ„vÕÔk)5¥ à°ı‡ö#ğ!î)â‹¡¡,¤æÈÔÃYÙ8Çˆ‘'u`ÅCşRDè;tm©m)vdÆ0¤½–AÍÃÅ`|`Iª¨æĞ¢?œ_”ø¤¸oŒº.®Aœ›cpÂÃ·âw·şwLrVÆPO¬tZk*[Íåòà óúFzz(±%¶ÖÅ†ã„§ ÷qd!f :rZ–æ‘°ˆ'O:9- Ävi	©ƒdA˜lªÛÆ¬·²VU¢–.7|„©©!ôšV[<=oÎª‹|”g^ÙSÈ WºÜÿWzSr«'—cÙ×*q›uJ–1™xLdáànÚ5æiÀ2éNˆnË‹ê¶eq¢™ÃÕNxü’$}½Ã˜rÎÏN—ºnWV° ï‹ûéuu…5eb@¸f³
9KM‹ØJÇÜA„şˆNÉÄ_´5Øìşo­0< ×Ò:”†ß˜ÇjŠŞ³Æü>şH¯sQÄ®)‚)ÓàÂĞû‚µá0Ø·—ÅUE—$ö^.¢Y»…8@Ãt.U]{pƒmğš–ñrjŞòl"ÑÚ6dGŒ‹ªöõk†ak“o¥$cÉæR”¨ª¢àş$±£2xLÆ¼“wvø|›Y~ÆQ¨?íË–Š$R1´Û¨p9!à@çXáA"ë%~«æÊIÀ•Rsÿ?ûüóz--WjßÄå#£1İ}¬Ğ=°“ûâ.B¶6Ö÷=Bdçïİsá·Xàœ±‹¾O¨…örFiS†XC[Ñ,Wƒ4í(1=­$eì“Ü+(Šn?šhdƒ¡-µÖ_a[õ?gÆ|Ôy±ö?}Ã¬} ³:)E÷ØTI÷q3%ãºëU	N ä)*Úd#ÉÍZ—.š.§ºÆ²ÑSQ0T›p›U"=pwÔ×{5h‡S*‰™ûÓcş{/3âÔ—ZJè	{gü÷ò RÛÆ‚áÚ9Hµç'[–ºÛß5	B  ÏÆÃê#¢şs/XÆpÛ^/ü£_:4ôLiÅ™È[Š66nÿNëırµkœ÷SæßÛH‡×C}•¸»ä³ÂÚ”°FMMöÜ=lE×"šÿnHA…º¼×ŠDW=šBß‚å¢V@é¹H2b°Lbƒ‚w°²×w«ñ;ºæ	”£
\¼3Æ &1‡iF‘.ŒÓjîº3”luÖWªÔ–LüÄL­"™Îf9ûèês[; ›¿o·ÎömØcE€ÅÌ­K®é†1^ÚÒXÌ¶TA/ù­ÖíŠñÏ°®TF¦_¥´:~!f¡p=ÚJ3l0Q9i<_K½ÿ)Sw¸ã¾"`¨ƒş}x >‚=tµÖTAœ‰pÂÆ5~N¥šeì?^oàÆVÌŞÇ®rí"Å÷«2V.¡Z"}t»ï:zÖ«ª`63á(¹ÔŠ‹Á¬€PfÁZa Ô#óeÁbµ‘Òhæ|µø˜û‚ñÊäObiS¥Ê¡z?É†ŞùSº<v¯zd{™ÚƒŞW·«ë·àú}1*œyh%¤Äaè“à¸½³NS&'Ë ±…±BótA@Œ—U%Š©ğÄ¿¥RªKtäPİ–JªS¥#t2ü+ÓÔDÀêğÌ¯,¨ÒËô¼ˆ(d§ĞÍGÅM+ü^6‚­–5dòÅbH8Šf¿²²tc‘uÀ¡bÆ"ÙãÔôÚaIõêşª&ˆ¾¿%
ªu—ç´+MZ• ÀpF<RKö±s°"²":?Â¼<OÉ51âÙ»%aÈ?%¡!7#ÛyQË<è¤¨ƒ¥|Å=Õz¾Ø  MìczEL<èQ±GûÀƒşäÏÍb£qPFìøŸd<÷ ¹cdÈ«`Ë§HÿCÃWÖ÷9}«cÜhşiüò]ôkEƒ®6òÙâäššyj—¸¼îÔÙq€ŞŞï¶¢+@Ú®Ÿ¹XÈ ÒD½bfíOù©:¶å¼÷Ù5)Ar2Ş5Ysªñ Ãx0ø$|Á%'÷9×0eõÈ"iê³Ç.ÌcªµŸp~7ÇÇÚ–´t#³¶Cı.ÈP;c˜tÖ¬ò¼¤Ù®‘JÿÅÉèC;)y=#±ÊŸ7Úü1£˜T:¢Ë[Ğ<Ú»øR)°v ìHœl÷lœŠâ+ïHÚz€Ü‹…=[÷ÌÀ¶Nü¥êS³f}`éÿ©Â&³ªM¶a5ç9/àÄ¨@EKÜ?_Š•Ñdúƒ—A”µÁ	/S,‹CÊòˆËS|·:?;úª8KGÙÏ®ËÎÍ¤îØŠéæäL•Ö/š¥Ê©ß¿&‹Í~ó4¯Õ–şgàª»à&~ Š+<XĞVˆñ®Ô.[G"€t?œœ>KKYö(^a+Æ¾_=C„ôİtƒòaV2FÀì_–²sŒ”O“ãÁÂ¦6²ıØÎÔF„Ë›ßÒ)Ğ6IÄ> :İ8+J¼¦?+­eRÈ¬›÷õKğw}z§æ£ ›h»Ô=İV’éİ¥"ß&îxL§ÁäŸG®áßÊó%ĞŠ°ÉEÅ«î³Ä°oq#ôîR$sİ‹¤(ä8Ã7‡³½¯Ñì 7jêé²³G¥2g<ñ¨DïóÅ6šQït»XSNÜsd”RÖ—p7aùà÷¹¼· å7g·uCä#§o²ê×2yjÈ]jó6*Tµa—Î¢È<ëE.H¬iSCåá¤€¥ÆQÕ˜ùd­Å¨Ô8U£Ó´Šº·ºjaB.´5æ•EA€Â\×èØ5ø(”-ÉÜˆ‚òÑÁP‚m”Í¶~Îíy‰Uû	ì5	dÅ¸‡ƒ*Š¶8!rDÙ-ØK>ÅTí<ôsøßf}¨`¸†téèyu´	›ÿäĞÕ¥µDW¼<”é‹Á? Ø£Štæìo‘¸f(Šá¸¢<ŸpÂĞ¹Ú {Ùó\ãQ¬
WMúTÆ™^®í!‹Q¢3]7Çúè†d„:«U7ø](4´S7?Lå€ÏrâÓ¡J^!)‹+©u).‰¸sïyó÷•æW<Û"ÕƒKë(gzØ)kv`µ»£4ÍAÊhˆßØ‡
–*dº"ú>#à0ÁD ôo¯bg–ç”m&)~¢aÇ€+­EY§±d¾¦{v“SdÚmQäÙ}}\’	Çäá«Õı¼¾tZ@ø÷4¤ğ"j­¾ÙT*¦-è˜BV,zs‹¥ö±]åuâ8-Jn äy=ŸóñgØÍ£?ñ)mEĞáÚí~‹hEHÉ.L4Ë
Ò‹'Qš"öLÅmR #¥°´®÷$£•{$8ÃÚ0.‹ğ7ŒŞJfôC"óA	Ú•ı2relÍAdXŞÍ;ø/WU/m`Ÿ˜39.0‹¿ßA}ŞÉÁÜÆdXj)ˆ>ëî41è,ıüp–†ëi\°M¡Ïªã+İb"#ht{ÁªÎQ+}Å›ôÆäí}?ÔÜ9ø¦zEpa  ¬Zµ<¦-×ãiº°±¹œû&üÆRá¼$¦4œ˜ ·SÏ˜b$v¦«ßl€Ù'):§Ò„Ë.Ÿ‰Ö1l@Jô=³ÿ&×‚….UÄÛVbB˜Ê$^'ú©%Ö ¦Ì5Ğ1½Æ¡C^ÓÏ…Ö ás7ï¢5€pŠó_Õ„ªƒ+cÿJÀ¾ûï-yÈ¼¿ZWS>L@H;†´&VúùŞM©WŒŠ|`8Óáè¾¡äjÜ“T–ÃGÌ{X–‚U	lĞ2¼A…ÔM	º½<>GÉ^ÄOÌ¦¬²¥ÜÜØæCeë
¬ÿ†TÃ˜´g\ÅÛÜñ—yí”¯&“@BïHl\TÊèIòJQUıW,*¹‰ºSÔ…vë—bšè$¡BŒu
ÇcÓ>3Ã‡[ãv'ƒ=2÷Şyy•W@ÂKÙĞ{?eur˜¬.XƒPP÷İhƒë ö9âo£Ë}àwÁİÚözt
ê©K„…ÿ¦Ô8\Çn÷n˜¼aßşâıÑ–”m Ïlxª9,äM© [ ï—gâaæ‘Ú‘Û2HV5¾OÉØZãq”‡È9*hğoIe¶FtçİÓĞŞ;Ù*ùê`£#ÜîX†£ÍŞ,°nİåæ¬ùÑOˆ£ÒSM–8rÈ‹5šj}¸’rBBN5@É¥½*$áî~d<[FMª_p^{t‘€/ùHTvI¡jê&öLÄå}M†Cƒg¦K=¼®éÛ_qJÓ.'fÇ‹È!š8‚~ofR_„ŞúâéÍMˆıíbOgFÜ™yÏNœ(‹¡+DÇ‹”Aø]U6£«@]ãáœ+Vr»Š·ú˜?°cŠ¹¶‡7ê,Uµ«/\‚aYÊÉõ-#S¹d56½f,°iü_ùÈi`Äˆ«\×Ë›`B „Huº¸‹dÆóù¬SÒrb¥Ÿ=l½4³Ø»¾ZXÂØìœ±%[ä.Tû»ª¿®‚ôÍ^ÿbçHóÛÈ•¤×°F:¯CŞ	×“pd`ãììjÌÓ¯r‰ëÀKáV	ÅwŒwîjîUG¥ˆåÿíx8¤«ËüqÈ½$#Uá<­æ ÔuÒ?\Ù‹ùwÚ/h˜ƒa„AÃôp	Â"r¬ĞU¶şõM½?eºG’Ün”u;©Ğ…8*Ë»£©b¥x˜CwÊŒ©´²°o¡]Få€$}f^‘ª`n[¤q†ÊÌÏ	©’ÂğAXt OnİÈjtPÕ›û“Ñ˜‡OH,çXª8ôÈ"EB&k8ƒ,œ´•
(zwT»îlš³vwáŒ\Œ‡V,×q¯FäBùËç£ÒjÇ³‘)†‹%Eg\&+İ©*ş#æSó¹yß_Û'`“ÀyCâ"¸i±5eîˆ1„’…Ôš¼EñÙPÇ~’ç}SïçºCfMyF$LÃÊ‰½j@ı'1àÂpÔìInöèÛãù°Ôà†ÅÃ­È,İÛmÍ.ª›ãşŒwÔwç3hE2•Ù®>Ã¼­È' tİÕÇgó3rÄ[Q¾ÒBj;øWã OÌlûpƒWBÈú
q (%{‰°mOÿRDÕ‹%ªÉ"ÁóĞ©øí ¡;4
N:`tûŞËã)g¾U±Šmh3\¬¶‘ÚMÂŒÌí°NH€n/Îşÿ0oàÜ’<ÍÉ¯†¤Ëdk¶„G¨]ævzô
ãÙ×ÒŒWI¢ó£dÀ0,âåµ]Ì¢‰ëü/±´Ÿ£‘‡ùabéH®sHYfÃ}ârë
w"¤ÀºÎÚu_¶Ük+VÄ°'_¥e°8½Ôòw³Â¯å]"„í uLçÃn¨°5•Ï[U“Yf(òt4¿—kØ—“+ìÑ›"]Ú ßÌ(Ó<21Çø¾3*ıäİ¨‚´Îä(~¶Ÿ0{l?~ßÙ‘D3¡ş  „”×ˆLñ®İë#ıó(òÙöçH²³½¼_(r¸-‘\ÕËÛîä$\@èîèhp×şC2[ˆã›àÇìêî’¬à™I©nQ¿2İàıí´üvSüß‹q*¸bG\t¸nô@BAÄíş•ÓZÄŸ¼ ï@-ùğ‚}¬o¼Q…
œéSVHö¡·áMóƒ,İX†ÛĞë+V†gñg•bÀ":úUãÒoT"š¬ÃµpFB§’Îßí7³³Óå2q£	{±ƒ¨BİsN2¸!;¢Ñ9Fƒ´qÃá—Wì¤o5ğÂ1/.7ÓË/•öÈ$k¹VïFsÚ1Dxå!½ñÃb(êsOÿµù:IWÊjğ¾”{ÑTæûCEÉ½~K‰ñy¼™e\Æ;ÍËÜ	‰aNÚL‘Pa¾8+_w‚¼ö‰ği÷?t 7£×¨C=­|ô÷ElÎH*s§|ÛhAÜOû¬SÑ3n·Ãq…IC/ı¤±nç'ímúÅ„ÊŞ™oTy)•ğ±ÁOx´¤éQ4õjÊ€“NÇp†8Ã“icKš±Ş(\kÌ ŸäÒÑO~Ñ­n7ÄEĞ©za÷~–2·#³¹§b:37‘Â;½®ò¢+Ö
=î è’œà ™Ì]¬deâ)Ì0ò[şqİÎfÃ€+[-~ı¤·¬Ò†Áº¡Öçä…cZàıºĞÚÎ4¿";|lı]}>vùz¶ãŒä[ˆ@Ö˜XäµşÖ$ÿkDq­¬ÉGo0Sû+ğÈ'ÆKw\6Èİ¿
è3,±°|0ÛƒI·Òô’æJ¢¥0%ır:Ø;QtØµ@U@Ö<,¤Îp¥×ÂC?ßPĞó9ò‡+Fİö78Ò˜,¯L
æhé5ñ ¾¬Ë·‡“!7w%÷8ÍÅ»Yáiİgn’>>xg6àd¥IÅ4‰ê:é¤yâ÷ƒ]ºÒD-Şä3Ê”{jMİŠL’²$5GüÅ.qİõ#ÒĞ$f#ÑÌÉ«¸ÊêtxZPı'°™>M `AêqÒıii¬UC’¯€éÕ½¨›ô‡KloÉ2mÜò²6¸Fh$Œ?ŒÁöÜË^šÍD¦•‰á§&~Øù‘d¬²Î3TÔtiş,šª—@¬©\M–èµ)®Zõ±óPìs$~Z‘3Å¿Û¸Ä&/íZ&¡ã¡¾rŞk%_òÅt2-L[â
8î°QGôq§!c‚çÈÜ‘"¶½p W½ÚuÃ†Õ5ÏÈ-ì>‘e‹ÜOY=lsÓÚ;óØæÔÒXaÑ]Å8¿şˆ•>¸€†šc?uÎ–Cb¿5½ê‹w—VÈÑì+Q&” Ó÷{Ÿ6åù:Q…kAduxH±–©XEA@Ä1fE¿ığ|Ï5h­å7\’&ıiÕ\t#‘Pkéz¿ÓÆ“»¹¦ÌC˜ysÁßÏóZ_¶=ƒ#4[Ô‘`5^ÌEsÈHLæÌ|K×”™ŠVFÿ‡CAšÏÛo×H‹a²F˜SwcEß*³Ë-± Õ^´íÜ¿€qoqTØµ*ã’—w„6ÿ´;G±±™ÉÁéRc¤ÍÍ£ÈÕ“@ZEdâBÖ{BU÷aŸÒA ¡°ÁBˆ-K=1ÒÒš£û{‘&’êÿ[äC[0";HpÓı<’[ºóÔEGQêÈQ½L7¬\ÒÍÊ,(÷ÃJlCÅq"Øtzğq–´ßYş£†O\{XõÓhrQyîş•Tù’Ëœ7v!ùˆ“ñ(hñË “™*ˆJ\äNXg¥³’Æ¿ó-¢×DÑLã'²yºÒ×³Ğ,ùa	ñ×q²(×E‡øĞ_ÀB[ˆGŞG£?ÛGÆü×›ûÏ‡Q8v-SRíSÜê¾@—ƒ$t•rdä•&”±Ô¢ú¯ÈpˆZ>]×Ò„ #›¢›B'ÓÔ‰%ZA.R¬êòß<ï©ÃºGÊ-Kl7Éµ´.ók¢ùZzÿ+Èİ÷àâB÷MA³7Äâoh™›«şH!‡dNõîQ—Îç3üá×ã=i§¢F‰şQ´\$¹‰šB˜Køg¸ŒêÈôX°-¡ı‚nNy­~®÷pÙzDÛøˆ'w‡/º´‘¸ìÚÕ\.s^Spïğ¨fÏìc”f‚©Å<¤üÿÇûX{ß°F*m¢ÿ²±o~1ûsvög¨c+dÖQØ©C‹ÉvõÄNÂO)â}œ×á<K‘É±2ñVü:™v†öN´”×ËÊAÍ‚µq›İUkI˜¿Ì›T-şÔQOo¢"¨°¿Föœ¢¥_ÙyçÀò	¥D™h?S*ì6>¬Ko¨5İçào|İ~çÒÁÛ%\õ‚ÀÇ×ŠÊ9Õ
Î§vÛ½Òe$!d¹å$+¨´wÆ:ŠXš ‹UÛCjèJÌš~á0h/öÎ¬dE¼­Ÿúb0³ÑÎ‰cG›|)µøÅEe&:ÕüÚvØQk¼±âtÚEÃô}u½¸ÁÚÙñ¦¯Y¸êqíL­Ë­ï\½šÒQ(rsu?PR?¡Æ"Ï[Ú`–Rı;ÒŸÃ´¿4HÂoe¦+;·G&LI…B9 ÿ?5q&!õPIah—„fiz©$Ù}½­bû@hœzTG#Càœ6ã¸Ö¿“„Q‹C]ìùµñ}®äR?ÚåŞıoF§BgíÍıûÎ³åFæÒgsXšxzƒF?<1Ö^‚}m“ª±;º'mø\rğI©ŸØœaißô¦Fÿ.ZÚ·J²¥²Ú‘­íŠüœ„NZ18—éü!õ#¢q•Ù¡®'*°·Ò2­1 e—¹©n¤Ë®gsA¢­/jèåtŠ7c€n0÷Ñ@Uàbä>å|oã£Ã[ÍXc$Vt¼Ü	$<a•)e£_{Û³¹yLMdÆ9Ğåëİí"­öÌº¨£yÈ
k+DX+ï‚¶¶íÉIu6ïK*¸¸ãÂÃ¥uË‹Õãl½»Ò±£*$ÕŞB’$ûÜãòÔ x³@IÜc?d?„ Ò‡à¾¿Í¥È1=S8)@<9»’•˜çÉ"Q­d•šæ;Õ¼IŠÊ¡GL\Ü	ªˆã¬ú:ƒ±Æ¢´ª-·ˆ$÷d%†an¡'òXûÅ‚œ8´c¢X65ŒÔ »ÕãJ¹8Èô6ÙâKÓå†YÅŠ¬Ï½(‰1tBu3ª¿1Zw^/ëgÑ’™”t!†B´I2ò”‰¤Ãä1©B˜ÿ}‚Ô-Ş1%öR¼WÜnÑØ÷—1ûIš.Š 5¨ã$€¤0È¡(ìuÕm+ ıáïÎ…YUWÚbæ¥˜£º˜BÂA ç<–ßp¶I©7˜¢m‚
A•cœ´ş$×\8xGŠÄí9IuĞ·^íˆ'vn¯±‰i‘Ê|Ô(9{ßÏî[²7OªL›sb¢îéjk
–¸n…}%,ßÑp·Tğ‚ÛCKÙ,µ@g¿Eu“VsNLè@lQ¡İÏPØ²6Ûò©3V‰/ù\ğ€ -ÒƒÌ0Æ_6êŠqö•gUI}¢WğmP&Ø=?=P2¾©]ÄİùË÷ñ¢[KÉèÉ³æª€é=
şAÄ3+ò'é“ÎñÛ¼Hëş~:YXf"à'áq’}¨Ú Áñ¢`UZ1Àê¿"qQUøË¥~Ğ#û–pXX¯xo:5j'€ªø¯×.ªš±O€ÕR¾[{Wş’>Ìm™>AsîQX¢y×ÕÉ0ù@ûWÏ¦åa]|,Im[ƒ*’©Õé‰%+Í[r}ÿø[@‚ûïñ<Ë.ğÓ=Ö>:Y”Q­ŒK>ı*RËpKqáRÃãœUøs-†Ëq¸Ğj`õùëm;e$¬³Ô¤Qæ=Ê4¬¸ë·e†|òŸÔBN_1b%àB ´±iuÎ³tŞ–qÿ®Ç¥ÔÚ˜²®:”yËÕ„pëFß~cğm½{®`ˆZÉÔŸ%mzpFÉ[¶(7C¿ Q=5FÏ7¥v m»¢¸wM¡Ö  x¤ç8¶Ç¾—nÙ‹NMKÃe8ŞÏû˜i¿)8@[N¯¿x•Ë<†M¯WŠ36i]Á?ô$^ã+Bë4¶Çcmb úm!€‚üw&ş3ãÁ—ëp•!Ô4­í+€³·Äâ•ÄHãcêˆ¥œQç› ÍhŒÏ±çÖşZ•!xêÙá%tì‰’‰O±¤?:tq”:×9²›öÒ…ÚPmYõÆiÓ?ÖãMÿ©uã\ı'@{Ü†N(ï^oûğƒ@‰ş}Éİ·-úüB@ä~pìG0#u&ÿY¹ÓŞ¢¸·8b)<0˜äùj#‘9I‚{\KŠ«m/pv„Ş,}l¼¦_—±U9)ñ±>z=ˆj Áü’ëQ>MM¦¥oÂ­£¼ŒDü,¯qG‘Õ\ñ^-vk´Ê˜:[ßÎo=R#	–"<$~ävÑ±DıÀúåŒöot°{iµévïğ”}J»Ì16ó˜öä²aÀôøğc$šv:ò^²†ÅÂ%ÔÀæ›¾F³ñ	gœh¦VÎ®^ÍÓ5E¼ğ.ÀdH9èškÍ©ÜF³g Ó•éNõ–ŞÕÙô7¾¢‹fjèG¥O8^SŞf#ÛXMŒ–£j‹© MØ(¥t½õFİÕCò‚]|^@ãíšõÀIW«ÌV¡ĞULƒ§•z©şúHC	—.möW¿Z ÷êËnN
êâˆ½9ıİ?ßfF¿ô96€Dìå•zëujYuîWdÇÅ3”¤A_&HQ\N(ék28·PÚêı}hj!<³äTVÃ.'Œ~,>ß»ê;ù->7ÙCH˜{¾›ıùQ,é1=£lâÄJ¡˜cx°î0à¬+%\ƒ+TÜ¦I¼}£Ñ	È!Db‡:g·ëÂÛ­¸„	ùZ–_¶;*Eb½Ôğ¬:ƒúÃ®4 V'›4©ó;!~T}H\˜Yœ<|˜P"˜tÿÀÉ~ÁF õ½×û1cP¦Mœ0h÷€ÜnìÖ‘u8L2?¢Â3×.‡Œ”™®*ÏÊ¿!ÜŠÿ@‘çxÆÏ)õuÕ!5ëD¬0dc°	Tñ_èÛ’n>	µw¡‰†NDª6“+«Òƒ™PóëÿáÜ¹æ]ÀAXCá2vl1ûåø™±V·¬ìĞ|nVÆkÜkä8t”ÕPDğNM¨EÃ?—Çg#G[‹G“ÔçŸí£ŸYŞ(ß©—¯İ—½ZM1•LÊ®=}¥kõGrë¶¼q'›¸ÔœÄ`…©NôïÿCCøÁ®	Ñ†Në+ØH¬VÙET
flO™¡Ws/ùÌg#ÖÎù—ÈŸ,}hÀ}šƒ)&XyKÈ &NuÂş|íµÏ·od\ò(@ıÍR @ÂÇ¢8ğ5Vş‹`Ê‡¤#™ø!EÏmU.Ùfğåá<ÂøØ±¶˜HRÅ:'JE'I¢Ö,néƒúÖ)ZoSµ:™à
ØøhúRsÈ©Õ5:7äù(#‘>ÑÊÚ«vüY¨=É`Zƒ§ÉÀ)X»´<&#ü•k‚w:B+Îà$E¶l»­ï¼¦É×ã32ƒxIÖÅó_·Ëé7TÀúmÛ®wn™krHØÍo44±-î˜êÕç“LÌÅ[a¿óóØ*ÇQ9‚÷9Òö¤¡(ı‡A~—ŒV§ŠrŞ×ÀsZË?ï¶&ÜBîaY9¢ç=§çÊ$‚“t¾(Í,åt°ªG€Rï&qÏµÉ©•°&— "¯Ü‡ªª–)j¶«’h3•ÈÆW#éê¬	³5ğ¯÷èå»}…O94ö^¿â‰ÄF†ÿ3ü@ÂQíP_Ğ¾Œ!^lÇÚOaío£ïÇ‰:^ Ï¹3(¾¹ApÍ—±pRZ-PŒLHï÷tÆ«n“¡ğ_+ ¶ÌÚÛŞc¢5ÎçA·YÅ2SÎ†h½Öx™ašäñá)PQé‹=Í4Ó8€yé6|Á¾(A†"g®ÛÉaK´h:Îøq}œ<<\ˆbîíÏæÄrN…Y¥û›NOÿ |¤Å.%=1RÅß1Lÿ\Ôúš!"d[ÑÏÁN=³ÂççÜ­"É›Ê$Ó†Ì23ÁdµxDàMvOŒ#ÈG3òmã?n+#X/ØÄ¤ÎïÊØ İòâtÜúÈ*V£—Ï±‚ÎZd»1³"Ç51ávéÙ€1Û£,½'Ši”ƒCfôø™Æ2ƒ²¸¿¶ûq%yÉm“±IÍò`%MÕëª‚WâbU>4ÿ•d™8ƒ Ğê?ö±åY÷È$¹c0NPåõZ}«*c¥Š7ÇÉÖN…™=ãrHÜghxvÂª7~¼>‰€Š…ûyX#OTÇ‚³Ó5ãı_›¹-¤’8IÉé…€»&§‘ÀX;%,]‚Ûá=¦Ôü’×!H„n¸êånñÕÁ›Ïş-oñ÷2|]¶8šh1IKİ¦í=ÄÙÁœƒ«÷Ù<LÉPoå{À¡ŞD$Ÿbi´G]‡D1†…
ÚA˜Õ˜É…©Y€¬–ä¸M{ŠÔ‰Ø#½{+0Y±+ø“½¡”ĞØß®ı¸¼?Vm+2Ìş’ìDëüÓ$}3rü„i¯; ÒtÑ.ñ£-x×ŸÒ&}|d¦«oÄ¯n°Ô;HêUÑÖ¯úù‚·è0»^L6‹Í`³3f4>v2“`±ÔSºÜ,j]i¥Ë¾˜•YÒ@ñx¶z7*¾"‘F–¬„Ş‡Û°qÇ ä[A–»w®Å3(Ñ”jŞ;;?åğS¥”õ5¼Õ°…°hHıÇ«»éúşÂ€Ê­Öò\õÒär¯{|OŒzLbN…Œå>‹±%f¼ã”  ®ÏdJEàÜğ®~¹'ªsğâT€6‹$ï”^P·‹oõ>øtÖ#[IËU„2Ğ^ÁÁöîÃMŞYĞxæ3¦•‚fÓÿ@sm‘&Y[Æ’úHùº(VDÅĞ¶\-ì	oŸƒÄ»†Ë
´¦èæ8¸>éUtİEz£+©íâ¥+ƒzˆ®² A;m¾§0Œ,ˆf$ç˜öÚ.Ùl#ô×>{ÇúSSiÏ¤š‘7N,¹ÏÇ…oˆì
\òÁ+¹£+ L–S¥ÒùãßStş„Ó±‚C;ë³/@gö€×UXû±2nvÌ©Uôéöd8¬ikëä±1Ça\À}WãÉfœ#½Öh*ÕöƒxC-ï-ÆE B^ê¢¹šU(+“õ«è ½s»İÎÃ SıÀj3ºx;aVvœïH‡”ŞÑ`}ÏÑ4Y†À;u9!ğ…¸§¥#K&g$e¦3Wøä”¤«¦hVmDÅò¨:¸™µ5hx&ÚÈ‰ól,õ„ñ"Ñ¬XK|Ç°£%Aye¶ï<1"À£Ğˆé”:
ÔÚ†“| ô¸$G=ƒÃ‹¤ÏËš+9„çŸi^¢òú¯!&éÂBYTkõÈÀ¯iVn¦“pº®B|©kÍÓá@™yØ„ánşö=\w¿¦5Õ­(¨@Õy®SvÒ¢Pgù•wo˜ÆÅèÍ‡­U8"‡ˆ™0Û¹±ºLú¿zÈz·*”æ	ZŸ|£ÁK€ô>Es`Ì™9Èon8+°ş/†0P±¬lÆrWS¤ëÒöq¢¨KúY
QÔš_Ç·<ôPÚF'"îÑ)Ø~Í­ Å!Ÿà&CÀ£!Õˆ¾Æ0,&‘)Ğ6Iÿ	«´\HW…j0øô÷€2YJÇA§/1yÓ.UH8¼´Õ¥§&\"Q¼^˜‘k &lÍÏT†±ÎËÍgÅãŠ‘k:ëó^DÇçšû.÷y•à+¦™õ½$ˆ¿N\·éüŞ*fÏ†ñ«5YL§Á	ºƒå:ôlqºİ‹qŸ º¡Ù¶Gk–ç•˜ ²K‹€ÕI3~Öw<Œi¤<ô`‡SË~®é¢}ºù¶,ÙÕ7AYbè:'é˜¦pÏ‡Ê€1…9dŒîæ¼ÙØ,ù¶
 )‹«^ŸZ?ô;4cyß¡¬6uYš‰Ì ZC³zÜ™Ôü10›Ç·á©z³4"÷\=2IN@$G_ãıŸ}³ıuT'àp¢)ì¯×ŠÀkñBæËåè±Bw|_ô#ëp’ç’WŸ= §;ŠÿœÎÆ‘ßşkù.—^ö¥´;2h¼8kH«ÛÇ²¤a:Ì/ºÁ<GP5åJË<ãïŠúÑxù;|×Ê‘®‰ĞbìS‚]Ûå“t-ÚruHöÒË¯mf
1¯Š•Mø`ÏŸÅº_yu@:3MaÕ¥›nîÚu!e«ävˆÙ$¦aÁg{"Ş’6Tğ•DÌ3F“äá¨ƒ©šú ’™´ccPÉ{\^†q
€cnBœ™k©Õ`É~ôè‡Xó@vKÍHLÆÑı,ôÒÇríD†‡®0ÃOWw‰‡kíş]P­ÔAIçàèezÏ™l{´Ÿ“ïÊE¡IwRÈ¦á¿{l¡hÆHsi1„·]Ev¿Ìgõe!ÈÕéL1ğ3÷jâ¾ï «öÖ‡F0.D“@æ•›ìDæ×²ÿ€Ê›êóÏ”§' B©[¥FØ†Z[üiï³Ú–ËÚNc!Ab¥-İûw”/Ëœq¾Qc4ÏµNq£tJ`~—*d^$]Bf%‡Â@}äx—kİVõ bô†¡¸İ¾éXmw)ämVa%sOÎŠi®b\ÂÉ-ÌHÏ“À©§¨qğhâcF·=Ò²[§Á‘U¥AÔ·§\Û±
™(:ÁÆ|TÃl´ÂG˜{ç§áëOØ$Ê«ºÿÄ
á­ºãúí˜ª&ıäk˜S•óZHèqÆã}´‡Ñìè3{fDùdõ/£TI1SÂÜîcjUf#»İšCº,\¤E0Ñ#@s´Lş$ÿDíå*êì *J‘ß	@§ş÷pÔBK¡5S¦òDe¾4ß¬¹¸'	_4ª#GD&;½Kf˜Np ¨ê›´X”šJÑ¥A@ÊõAÿ6¯p$kdÛ#Î¡¨x¼`XäZ}Í7İ¬ëõi¾©œb6ãéÈÌ´+_kOOG·ÈÁl|B#öÛ™Ê(LÂÕ2Á„¬CDæøŞ+ï!(ÜÅÈUk´™‰[Æ¶jUnºĞWA/Öæ1˜AÔŒÛÎœ&KÁqHôªµ‘Ê‘¿†{Éèßqw!:/“uÈ¿ù0‡;ş{Ä¡‹İ6¡FÇ5à£|CMEÀş°5‰³‘9'İÅThòĞ^±:h¨%¾Bw[¾ëE°eHûk‚#üì—lAú™X´9µÂª9o0µĞÊAÚ—Tx®¢§À0lo™‚I¿¥nüŸê$ª{7¯&¡š³´Ê*ÍÕx(€¬©´«««º”04F[=K„?Y"¯^éôÛOÊ¦®@¼Û¶°K¡öWÖµ¥ÜeÆÌl|·ô)9‘÷â!øl¤ˆŞówOœW<sæ/ÔÒ3Äèº=p›`İ
—?È°íà<¹|”g&W …ÿlÿòÖŞ 2‰Nœèö\0R ¾Úˆ.·c¬VT`m¹lÛñÕ˜B@Í½LV÷ĞU‡ã°QLüâÄ•1]|¥pÚ‘VŸndc§äÏào‹Ñ±š‰Æm^ìa)òX|¼»gãUÛ#’ŞI­(†ê6üªá!;ï¿¸/š¸ˆ¬¸Ş¹4ëÈR*IöÑ‰¸…@zâÉV=$nï!»zD=ŠŸ‚š¿C´—ğîß‡”A°ëoéúxzÏtE‹b æÁ>Œj.cµwç’	f¹}ºô8W›ô/°Óãc0º»dÒ‹I£æ7—yÉ HÓXfr²
¿İN¡Åğrª&g&b»ø!ëØ	(PØæòõ	%'9L‹úõh‰Õ€›GÒ±‚‚°òáà3ÃÊ!9[ËWI¨í¼»d|¾)cã^¹°¬Õ‹;|ÿŒ~D8üÓ‹”­È´’ÉXèká/ˆVƒX™vƒ£AVx_—Ã|Æ/i ÏÇÃqè‹JÅº™!âwÎ¶Ë4¹æ„G4òyc»lŠa%‘Òq1~ØE”Å“FĞ5=€§Q%¦]'}ıêÄÛ*˜,l¤íG‰~MzHÖßÁ³õ¦O¥wµ7öâÔâ›1­yB€éußˆxÒ ®pb’TÒåüoç)â¬ˆX²m‹={V©OÖ´|nÀoûjÃN ¿œ
	²§½yĞ„’ªB"¦”¶É5Íœ>Èç½ŸXØCPÀ!”7¹û»Í™ï)Q‚­•,	ˆõdÙ0Èfw¢oç*wÅÏ‰·ª§W¢Íõ¢zğ~VØÛ®ãñÅ–\âğ­GKlf6ür’V£Ñ’fgÃÜ±ÏÖ•ï ääÁ€&<L 1Ğ!n?¼Ùq2E/jVİÿô"Íp½	?@ïhè#¬!¢qöäÿ$‡YÂ	çVgràã<äÏÄÑ¡ÿ— ¸ƒKx÷4“ö¢…—ÒL9p‚üÜÅG+´IsHGLª÷_úì6ÌAìÌÍÙ¥œDùîûZº™»ZË5&GÙê4Óñƒüj’ ÂûşğJÜ]à¾÷xZÎK;†!%˜OÈ§ÁcÌ[şÑÿ/5Š’c¬bŒœõ(K€ÚÔÙj§µ"ú‡€p~õ]ÉÚ¥ -Ê‰y4)
ö>Ä¯êƒX1k¯˜™[Õ®kgh^†Ù*Œ.£uÎÖgè†ÚÜvã;ñç'À°ƒı¸ıË—U¾Ò|aMå”¼‡lSoAÅa¹iDÙãLwld­Ø“lËìVÖtólp¬A"M¡ÿ¡rhcø8·›1Ÿ%NCõîáÚ H;æ¯ª€Ÿ—R­¡NUwÉ*íêß»šÇêÚ¼ıĞëŒ©F.‡c’öXpäªX¥¾g®C9-Ö·©ºõPQ]ÍôíkÎ{%:	3î™0€Æ”Ş¦Å5<å-bENaFa½;5§„&Çé´ù•’n4Me5¢Ñtû­I6¯nÎwÍ¹(÷ÏmInƒüº¿_e„qéŞ*¼ãö—õæ‰ıêÎº.§fU­øÉˆ}˜a	NXù…ãÒP$àš,5¤ZğªtïrâçßüĞÌan?äoV;šğ|Î1í¦yŸâJ”Â²¿ÎõSÅËm9¨yƒA”ÌKã£+Mä†ó 2~XäŒVk“‹ÖuÄ¬ÈV[¸ek?^{‰âàÛå-Ğ.­>²lKê$ÏinfO|«óxÈÔ/DÇ
Ú7‰E8£gŠ>ï?Æ\l¾¼M7–€ÃY_	É	ÈÌşÚÍÜ±±9~-VpP,YîÛ¼ç¡Õëk¶ã„Vh —÷¾«ğÑaV^»|“”	ÀÔŠÉ°‹@O‡<@ÁÈÜÁdğSü7ü3
ªx>³„×üW~3˜6ækh–•Æİ©“;]ÕïébÉq‰äxJWú§©²'
k·1¾UòLhxúx­¨6ê0m¯ÁÄË¤*<lÓ"¹pRG¢RGÿı|ØÍÈ¦İ,Ô˜4AİïÜŠĞ™^ƒ"Mrü$ag¨š¯„}¼“åğÇÁ”Ã¹;^#¤y.çé$/|~¼¢Öu°°ÃBXƒÄcÚìå‡ ¢	càÀ4ˆ|¶>íÜT/iş¨šÁíK7#0.áêEF=¾¹åxD6×[ºˆÛiîYŸáLhBÒ«´{oŞæèSKM,XĞÒH@¹jvÜ#şJ¢ŒbtŠHf³I&¬¢³ã ©PQlæôœEwä¥„°“2æ0¹|_È4ÛÈ!T»çq¤6-Ì½Fµttg€×ÜÀU	Ÿ-ú­¥¬‰A%ù˜A"vû¦iu#7Û’İÃåóÄéïFÖ¤—\>P/}(†œ:íË¬7ÊPT‡ÈÇ	G–£^GÕ—j½áO @Øµ$W{q(BşÈlÑEt¥¾“!´[Xµæqíø2Ñ,ãçj"vJA¹Íß›$™zÜhÙW{ğDY«ÇZk;nïï ‘r½z‰ÏŠ¥şã¢ÁÍŸ’İ]…RÌRÙ2‘Åä2Ÿ—n9Dş8®ÿ·†xÜ/Ó"pšJ6CÍ*Úw‡6åEâÈ×¸;]q|õ:í;Üæ£ãÉ©€£qwTî¹OGŸ#§u‰P°ñ™Ÿ‚û}ˆûçøÔLÅÖİKRÈÊ-YÎ©Îë¾û›öa¨Sã´4’	îû2mPûæ@"IhêYê«é!}‰‡áCÄo§®E¨ÏdyÆìÒã)¤‚Åé¨( ÿ.Ğ¤ó=ƒ§SIa33Ypm1ÊÔ¶*G¸úxõµOZ¹ö´„#qµTŒImsXb4£lé•8wV„ûëj²`M‰¯PŠ!ÙA
tä¼7Kv%ÉqX¹¦e5J£«ÀÂõê¨(]µ„R`‚Sîz­KŠ«&ñ¯9­õñ·”òf$Æ+»¸X€$‚k)ÍÇçõJ†côà-Øk¸÷¿ã¦™‘XG2K)ÂZW¯cgÏg9ƒÉ@ ±Bê
ĞÙNª}Öcû¡©âÓ!şÅ-£¢@!S IS1¸vkĞU³ZÍ‡sŠD„~Wßl–™·nhúoYÉFíáâRm›ˆ û:@õ¨YÙİ¾’>5FëÁ_Økéè‹K¾Üïyª~x¢ÁÎú¾ËÂ½µ EA«ŒÏL`ãšçõJÉÀh™´ÓZ4à:g*µÍç†!4ß N@,QÃÌ/õ9Uî–niXMº°‰Ğ!4 2:°y¬„vöD(”Vk"hm^É9¨‚A_á¥=ó:&* "ãÿŒ
Õ\»~º€ÒééPcŒNıH¥s£€pñ÷Ã#|Y&ç”¢]tä4ód»òjCsN+Lª|ó›Ged ›ª`€wtJF‰lƒl¼ °`W©¨ÙUòa'*¡L%_š5“?2/lE¯ğÊ$“>Yå!äş¡ë[Ş¸Z<)å)É™HX•„TÕ!%YOÀnIï¥Ì`dªÎ*\‘Šó9 Ê î%³´˜€‹38DÖ»âãƒbmµ–€K<ô œ'PG}Ú}Ã©®i*s(ØÁUyõ^—Ç¢¯8ã]4­'”:<¦0"H ¤M’ˆ¤ğXoå*v^.#”¡2ıàm‚2ĞÕwb†X!›—(ıjh,Ê‹¾¨d‘ëF
ûAêÄïH&VûOf4¶ô+ş'Su$@Gœ|
Unt3ü¨¦Â¦ÒûLî–èÄcÈì¡n~Kİ|f>åê “rPPÃVh^ƒ«J,H–ãºËëÖ0Ìû"·F]WõèC—Şù­»1eé|À¦y{«I.œø#=ÔÒ­¼Wi_·–;cTvâEÖğóÀSï0ô7¨\›dÇÔCÔ…‡ ^Xôêz>¥}šh)
¬X~®F©åò=ÒJi'hSRÁ¹OÓ?ß.ï?ç‡Ş|ÄË%8Yà)¸^R§W+•GÓ õNÊ?ğ`[€äJrRïB–‚$º‘šyeFÉÍŸ1,ŒBÓÇy×®äõ&RÜÇMOÎ Ú˜x•ß³üÁ°É™W:8Á…äZ ?e‘s¡dØV¨(^
ıŒ¹`¶=–^H«cÑlAÕ–&´ƒõ3œö¬¯÷Gs*Œ¤ağÜ¼ãÎzK3‰í^RÈÒF ÿ‡}øë¯í6ºŞm_I[@"
ÎM±+E…ÌÁ*Šò·$×·ÍAT–§^fï‡È5A˜i ±Ò+D•½ÊO¼g$£=@¶ÀËúÉtô%‚ÿ[|Ÿ?FUÇ0ª'‚=“rj#Ünªv1MQº}ó*òL‚Å­×¹ùÂ	måg¸/èOm V¨4ÊÌ)*‹ı9›|<n)Xn¶…nã
@s»µÌ¶¾bGó Åˆ×#äï®ºâ¥]ˆÑø‘r]pröÔ¨®®G`!iZ-´ók¤yàş3¼ñGÉu› ¼ìRu=á¿<öÓwv÷3…qár¦ñgÆNª%{é2}£j¹=m’®—ò´Aˆö'ãarrÂæàî¦óò2qDywĞ•
´6MÇEˆ&³„!˜Åj¹]Gİµ"«êóX¯OS‚İ.¹L/`s§R|µÚĞåúêû’ôñC:ØáŸÌÇíŒïîN>EÙ†ÍìzDÚˆ.ÈË‚Ö¸¾ˆŞ„¿Ùi­c@EıÙÿ¿°Äu»:GÅR•!ª‰mF²*«ƒíÂş_htè.£M®ò%mBgñJ)el¤áŠG	|b?Í…¯´I£6	¥	c€WËĞW»z2 {:§Şíİ”a›Êê-	¾œN”»*p¢=£ÆëÁË9[WÉaqô¡Øô UÓÇpBİŠ'+BÎ• #,ÿ•â4Ib]ıà ò°oœ¹!Cn€v	 ŞvÅÔ×l¨~£pR_V1Ù6&SİÕÈ¡ÿ%%5ïlR!ğ¨"±ˆÒOø×º¼ìWö4 ³s“ûô{(4gÇäQóÓ…¤CòS"¼šU$‘Q/oŠúMÉxÕã–ØLŠL—Ù‹¸ì	§|åN8»Øa
~d|«§\I’µ±A<ú¨ñË]“,€K†`]í;nZB”Tê’3Ê‹OaàşÂÈGıV˜%Oáì»ş™ïİ°3n™‚èÔÓ»a—[„¶Fv]Š9îÑ¾›àƒ8ä4 L\Ã$üö³[Ë7!.TÁ 4»ÑMÉ+ÜuXÃ†M\Åıt>Vñ·’awŒnôÂ/½å"¥Á©ÙqZ#¥İ©ùv=(º…'MŸXöã
îèD6Š¯ ‚ôg©PB%Ö+\ 8gØî¸Î>úµ•şhRkù¿¢2@ö%¢N Û3gïÙdÚÇ¿!pÏÛA.¹T°	ûgpÿ² FnkAp¯
9à+ğSëgP«¹‚R3©!Ï™?öv9dånçìH9 k¬­T‚•ÅÀs·™CÕàÿ^W&'®×
´æV¹œ*eK¼ñõÚÎ—cÚÁøşÂx¤‘jRo²ÃÉıhş­…6\(-`Ê›d¡g\h©rÕ9YÀs––Ï)ø,Ìçf¬6æS¥ña`ÉVÍŠ‚ã1@Ø<¨	Ãq¯G¢­B^­öâ¼ï=jGWy |êHúBQQn]°Ş÷Ê¬õ¯Î¸[lªÂ©1%r®şS}³šv/U°;^qt)Y‹0"©6ÄâÉûş·Ùô¯­Ã•¯…PÇö¯uTùE·.:s‹s(2(›Y| ÷¿úûˆG¢?£Æ©Ã˜7‘T¢çøH		æHÚIè#@½³Ù=×´—ªúÖÓc“ıITÛq¡7ÎµTàñ*?Ùn%båeºİ£A8drMÏ³®ĞmgÎjo†‚DñÓß&¢g^à`q­ï­‘iL½çç„¢ÈMxÚ:¤-¶I`¬$_É³_ÄúÕXß~y
Åe—C_½Ác'¨‡‰`gÃ·¢r·&\>98tsaî›ÕÊ}çÏËBŞää6>?®´ª*Ç!PñáåÔ€ ş¿eÎW‘´†NµkqÿËœ‡/;Ã´“ÊËš‚à Â½ªKï'6W-l \"cxã?ÕÜÄ²F³ã¼µqºEñ(>~ˆÔÕn0’Yª–¨‡dÍIÉ"—ç–àN3c¼ÖÅ_^—Ş%¡oõÃ{Åú4°?F ÊF‡v )³=E—mØ°Ó6ŠZ)X8á\ê¶^ı?1[Øº¦ïóûØÛ¨˜mEîÚù8–g]9åÍ8=d‰ü‡;êİH	3ÑGŒ4«öR€FQÀVRr®âÕé%ç^+uœa¡ÒÒa×Z•:0£k"4ğSá—©Ç¿Sà=»â’Ú­¹G?X=İ!qÛ¼	qÆœËbò‡6®sáÅ6¶¾±SYéÊ!^}£8c¤hå™ ×«TŞW*1ÛêêğÁ?•~Ò\ñp†ör+"Ø‹:2Ä[¨ÈEn7XĞä-=éúeçg`«&+]ÏÅH¦1Lª©2â¨ k[n`3ÑÈ@õàz÷ã4.Q|ÌŒl7-‡N˜Hé) ÏWˆ}“÷º—h_½ñIùÌ¥mÌW¸ƒ¡²KQ!ÀçÿÆ4K”ÃElæ‚,Ã½rÍc=ˆEOé	^•ÃíMÒ@sÎT¬À±LˆX×kÀÕ«‚»te»-±?ƒ g^ş#×L´X[OPÓ\É£viE;éÜ¿ ÜXù²bTUÌ7&U÷ÙOãHMeQŸtêuñ«Ìıï<°ƒËe:ş"N‘ˆ·ıÜİ98‡JÇ¢ÿõ€à°#Q†3jw@Ä ĞÏhÉ±)U0îÆô0‹°%–’ŞbJÍPƒx³u|§ÄÅ=‘`JvPO~ÎñÚvìwìöD<y­ñDP“ÙgÈÔ>nÍAwÎZæ~S:ÒÊ¸Ş½Î*z¯¶t47ù"3=¹¯¨1×ÿÈ,lWEï—wrnDÑ: œ@ª×Šs<;…0y}°ôÒ-®·u¨ß=WN,­Ú”õ„Õ«¸…¤Lğ¾V5MÊhÄñĞ‚)"½T·KÊÎ5§/_sSù™4ŒtğRt,J$rÄiª6MI„µ¥ÉN×¤¤P`î„Û¸áœ«ºñT)Ë&ÛßY4PËY½,Èr2ö"ü¯ÅèVÕü˜²]¸|#®œQ£±¬›¢îs,°ZM‚ZÊP‰ĞófãİÅry9X-úX{İˆßj¾»	Æü)İbÖöhé“¾!ìõœj°èP-5–d>¬».>İw*?××G÷R¦®eù&n ]Q“3Gƒ 8İªZ°ŠÁo%P
0r6ù`ı‰Î„LaR6¹ÀÌ’‡KÎëˆJ3CÌ3tª§ğ+'¹æSÁe'"ªXÙ#ä•­ªV]ÌÔ¾ÜçxGc¯…Fho£pö"•¹;İü `]AkL-)ŞÙ×àKÈ…´4MĞúÆ{QëiÌƒW¨>"^X‡P[5tdœ|/ô€Ü¯‘ğ6£…Jşo+ É9‰íº)cÔW/ô-¼wPA&lÕ‰q¶Ü–ªÆê°ß5à¶?Öt!ûÖ.ù64úİÚŞ{è,áàöÄ¿§Ï¥K©A\a£·à&Pq'R{OÅÅÑÆ.Ÿ×¨Nƒ®êè´×p){‡uÌ­bU£UëûìxGd
ÇO®¬ô£ŞÈ`=åòÿ,%G@åIİûïŞMòxµ3‘]l»à¿n©O%ÎõÉCWÕËÙäÈZ
ÓÒ„¢Íl­ºm³X,™Î÷ë.¶Ä‰^X’™ÚTP;„tÃ¶xª&7H ¨p¹İ6í%f|$òT§nïu“Yšÿâz=s$)ßxbŠ9Zòùô!Ï¿–Á:®vT–vQ”k¬‘ì^Í¼ìV±ôÇ¡}ª«/È¤‡€pËŸç¦ ¡µv¸ÓƒÓ%×j¡¯\9b‚¯#4DÁáÏám’s‘?˜ïÆ}Jê´¢ÒôÕ±ƒâ¥êi&Í¯œWûú÷¡ôøÔÿK´H…zÒ¬ôoÚÙSÿáİÕz›‰¨r>¾Pƒ>YJÕœ˜¤Ú  [umºÌÅçh’2ÕµnøM¤x`ÜD"£T„ÔHD¤êª†t­™ğ×G®Ù -Õ+œ²œQÆÁuiî3—SÆÿ¬Qqk%¤‘Ú÷Û'Ş/&âBn„—!Ú°jêø|#bcíƒ¦T]’i1˜™¼Bëbšy’‚$Z«Æx£©ŞÓ–aÅÔ‚™f`÷Çš{!UÌ%¡SI=å„Ã)ˆ<şs™.¯dJf$Ìù÷zõßÆj›d½úZMñb˜*VÖFÒ”o	ë8íczæãW‰Ìq³%ºyKi¦©®±à‘_8‡½ÆH‰œÁ˜ÕaØK£ëªyL÷İ:ĞzY°—t¿OãÔM“õjĞa&àA‰*Å2›ş4•Wë•H@ ÿìLLÎÖI#†Æ»¡¿mühä½”àÄªC†æeìùÔ{q¹aLäBÄÃåhUt`ZÕé-½Ø kĞÔ.Ö"ÑÓÎÜëŸ,÷#¤(#p¯ˆD…wÚG¥pw4±ù˜ü½1&øåòİÿ	}Ö~Îã?‰­xxĞ3XDÕCí–8HÆ=Íı÷§ş{ïGÕÍAè¦Ä /ÇN2¹·Ÿÿ»ço›7aì· ™ÕLCñ"xMcàöBHøTp_û,²>¥C¥^nÄY™¯3ı¬Q6ª¾Ê5äõ
è_ÏÄ$õeĞø½?¡•<©_1iü§ÆV6	g }µ°5ùNIö…Æ@Ù…"®ÿ2mkDÒ0(oh\(Ÿ”ÌÔ¸NIùáO±‘ós9ò[§îåŞ NAmÑ§½ŞHÚqÁÖ½×ÎT„ª_>W·‘êëµjåêFÊ:#|Õ{«H‘\«ò7l<¹¡à›YüEÌŠúğ“6NûMŸ.¸´bGø—BßUèŸ¹°‹]O#G7>¶‚ÊÛywê¡$l¨£npó¬±Y›üäzO‹m­Vğ>£2«J\×]Æñ°TšXd[ÃÅ°Ù25-Ä\
‡—"{ü©?ÔÑ«JqÙ\²}ºâ1Â–:ƒ–køÛ8üKU C%`¾~M4Ò¬ú®ÎrfallœÆY_|z,N0ä	%j8M†–9F`Á>¯,€;êî¢ W-;‡+ß¬òÇs_§İuÁ*µÖğC}.V&àkætÇš!²òéÔ =WV†ŸÖº"¢)x§•Â5@ÖÍÙÇ.(hAEm¾agœ<Ôè¼j¯Hí¬LÊ#~v«ÅqS{«¦‘”Ã€ÿÄe”³êÊšF_"ªiÒv6=ïşâ}tÈşÜ”ö¿ğÍCZ;`
ÙößéGFÂ 6ƒ]ŞØ’áMñ–O¹q…ÏG‡£Œ?ËÌŸAÙdã/`“ûxjØ99†wİÓ,PÑ¼K7ø¸t'Ô¢âÌÃÛ,o
Ü´\ş à‚ ÙZ¿)ªúµ6øÔš.'ˆwCº“UÏ,†óeg\ÚÆÆ¯“×+äeá«šàãYG†°~Ÿ‚<,8 M*C³)„¦ùIªµ{uw 'DË¿»“P}L>…ÙA!’.²UtÖ•šÏÅF½Ö6˜ĞÉƒAÿíã*¯‚Vàq¹¢Yºzâ§²M#ğM‚’0™¹xl,ˆU‹t]É…Û[ğReÓâ«[Uù¿Ó8Ùc7—3Åû|
ê–óÕ¿«’,]Ño	€V‹Ì˜ÄF·®?KåàqÓˆà{p«^&õQ_g}öº_÷j×Bƒ…0ñÄ Ú|Ş¸ŸÌ«´?¼I,ÎÌH¹op¹Y‰L9 Æê¢Z‡tÕ¥%Iø¤³* (ğd „¸‚ÇY#qát©	ò4œIˆ—òmD:ÙßPB¸Ü9q2$Ş„xsìÒ"%r»KÙ-Ó"Êf ±•ë¯o2uš’Á(C¦î|Ú;…Í|¥jàß”Q
ud~ñ2d ×ÿç-ŠL|q¡êóaÔ5
ØdÅŞ
Ó$¤NÎ­²aš]Ã^Øªş°*L0²Ê‰ø0Øô[\«'0‘=ƒ®)üËäÙìŞÎ­ùS°hüÍ¨óØ2¾—™›TPéşÃ4ıTôÄ3jà"fĞÚ¦Ì£ç„Kœş¨Èç¡µ¼,L'?MsÊFHêºéNÁ³¤áí¯!qó¯[ŞY[?bãJKk!z ¹î&…mcí	Öj-s:;å¬qnµ(İÛO`´F´8okoú©y_Ïè›İB(/çj])ÇZ¶ª!^7f«$+~4pãİa,qÂoØ‡$×F˜òîpĞÿš< âÓÕ†iØ]ı~'YÒúa‹Û/ä\°Ã{úußS=Ô;Yl˜/,g9ÿ °S!?˜ÑŠP*Elˆi> E-z=šŒş‹€Ÿ~Ö4ÁiVXÂ©'ŠLo€W"âÖˆ¾l²ï¼ïûizÜIì7ÔÎh¾°i9â“Û@ÄçéúWŠ_é¦ «ÉƒÎ{Ês2[Ùğ"<kATÍª?ª4íSC¢ù¾l±‘¯Q×,%İ¡>ßø:ıAÑ5DŞœC«´äÂ+Ø)jq©[Ë¸)FÀ©A#¨›² {­:¡Öµé‰6äÿŞu²Kî„•‹cœÀ2ÃIê×§’	‰Í#Ü+¼6ıvL€†® Õj`öW[±¥‰äq†ËÏ#feXÃ£ÍPÈQâ‚TÜÂÂ¾0Ëı€0-pùŒ^ö‚à­à(OKGºTó»±ŞÑ ©r2ZÃ»‘:I»Ù¥‘v¬sÒ ÍÁ~ÇÅ{!cÉöI¼©>×ğ™ÅÃ“n ùìúüKv”;ÃRm7;AÖ÷4—deXõL}Yğ'ƒ}(7ğ§åÊTsxaßÒ\¸”,šçzûËiZ7ò§ŸyCRš‰²
º§ßmhÇ–—a
±@r„ÕÃË`ÎFGlÇI£‹—Õ0-­Ù–ë ¾£ÖB¡e³EDpoâ5¤VÂšh§a>¨pVäÊ1·PßC;ÿŸe„•»x‡¤MÁ+$²	 |%è³¢ÉL—Kˆ»”§;”<™„¶IeQA	Â`¹%ÄÀ›ã¬IŞ˜Eá¶ç[#µVbÔŠŒ1X2p¢†¢ùY5l½“š=†Ú0İDÚË2TE Î4=#£YdÁ3èR»ˆ*hYáı?63,‹m_Úû…`Ä[…£6÷ °ÃË UlÈ×qaY­çµP©5&Ú'‰½|Q7FåÙa¶lG†­hGóTß’ –=rÄªwZ¦XgÌA†%Ğ8²‘YyvzÀëä«à‚ä„®2a<‰Ó|5'CËóÏ‚òJÍÏHy:p4Í»#ãe{u>ÍÔ7ì¨åw8åóğc}ev1İ¢-k )?¶ì‹ŸÄD!IªQ‘:­ò0ü­f^ĞII¿sO­Èy11.dùªj‚Z 
~#¤×ƒxArWGIg»yCÀ^šË'óK»÷„»Íı¤PÈ˜X“ÌQ¾âõ7©æh±IV8®'*œs·_;»©•´2ÈD*b¥9$B·\¢étÅµï‰È.‘A;f0ä¯¦j_M‹vR?ã˜19òŸÊ@Qz.;vóu<ÎNj´+Ã5‹;¤“:š äQñª“|¸@&i	âÊ0Tånm=ê:"LàbØY’ÌÅplôæ$õ‘Gı¿gİˆSßË÷‘RÛ¬jÈkİ
Â¨ÖTŒy¡véªpËİsü/‚²—îQdPºàKÃ¯õæ5Ü’FÊê·”¢ıéˆèPÏ]×’øœÄ…\æ$l7j);²Å´v±Ü‚5%Ïİ#Ø„ I°sJ1E—&²¼Ê±Œ›H®ÉÍYŠº¡\G\?/B«‡Èâ‹FÂ7Å¶âú(o”tÑ•Ä¸“‚âè2ûÎï­ÒÖÇ¼pèñHgÊñSÅD%ÑÕé í³xQô8^üˆs|şF¬I?5~s@k¹ß)Mßùâ<Æg¡Üp±ZÔıfs)ï
éÂğÜå£•Šà ³º¾ßÑ%°xÄ3Gwhõ{BÕ àÖ°ä+Ó!Ùûû¯Ò`nHM÷8ùáRë‚|ƒDÔÏ.o:Zim!á¨:Ü»!´¬^IB»~^ûNñ£i1:…{d^sE4'ğn.	°œíGÛNv£ÿäé
'AâÏ<bW‡"e*•ˆßx4cšdè5Ä{„¸uöÇ÷¾m!@Ùæ¤dOCÆÜ+—Rùx;mQ75¤ÀÍ[tŠÈó¿“LÂÔnÁğ—¹‰ÄµÛ.šxåkÏƒƒ]“:=$ÂEmOQôŒßı‰ß^Ïr`°¢~—:©v7SoŞô0BG„ºçO`-AÁ“²¶@ÙÎ÷ì~û3	ß,`)AãúB¾éÅ1Şh»æ‡y4•\ld¯eAñ'ÄøÒå|÷ ÇÙ=DógÙˆNåÃFĞ}É·—GùqÚÜr¶Æ»­òú5¯Îl°‡7¹B^›³qı…1R±ÀF~–`ÜÖù¹Å.‚¿}¤7ïè
!uîRp%aE‘OMşñŒJ¨ÁrÊ*PS~•5Aª¦ûSt–u3ä·Ê°£³­µâ+%K°‡¦öM å³Çq‡Í )mFÏèşÑnüH}OZæ q	æJ¯›PÏ‚j£‚T¦xÙ2xÖ2VÌ³Q)P
DXz"æFÅ	ÿd¢®‰ ¬ÄT¼!ø·â†~­PÁÕá»Ş=àëQ-Ú9mÈ„œã;Q‹"Wt®µæÊv¸×ğGqûõQÃy×-Æ~_})Íi>KyBèeÑÜ>lEU0SO(ª8È•áJV~¨«i»ú’óSrØEŠãŠğğxÊì>4aia¿x|ßUßlëêä—ébæ@£q¹Ø¢âµ¥¸¯¾@böú[Yèóú!g-„j‹NÿmíWïIbIHPj$Ü, <?öŒªÆ€Ó%¢l*)ßck‹eJÇ9pŸ×u[J#ÜÉ<îñOÜp€Bªih-\H@Hs7(1T  ZÌ[S(õ¶ ó·€ÀfU£ş±Ägû    YZ