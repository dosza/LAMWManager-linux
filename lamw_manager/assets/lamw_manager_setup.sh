#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3086488559"
MD5="0f16efc5c4c5e0ea54963ce44a262b27"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25868"
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
	echo Date of packaging: Thu Feb 10 16:25:06 -03 2022
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
ı7zXZ  æÖ´F !   ÏXÌâÿdÉ] ¼}•À1Dd]‡Á›PætİDùÓf*úJK“£Óî@ˆzs©ÓQâşzv‹ªD²êƒ½¦› &Î‹£°±ÉíÉ/^À—3ÌDd†ı*®sm×€-QòÁô0n³.^oÂ&é7ÏNü<¨´UÆ"D†´j	g “åÑ)ÁZ‘Íš3(ĞéR´+$*C¶ôG’vQÊ[ ômn
F8æÑ´o”şã¿BY#¨×Ì–ÁÛ1Ş9=GH5>ïEÀ|ïóïÓØlQövùAÄÛ‹»	ŠN{Í»İ¤1;€HÄ˜6H` $YÖıî_„_P5áıù|­Íšµ7té(ì©_<ùş4 ªŒÂ /[ïîR]Ë¬2ğ²ó:@[äˆxN~£>ŠyÅœ¦·2âµ(€@Tf¤ş¡§ÚÁŞ,ÎÕ¿8cJhz OÜ#ÃTBÁà)ê0æ7B„WØB7ïôÖñzr4‘†È;yßØ&!/§´…æ(tj¶{\Íù‰,<	×&9¬ü=ëŞ—Œ·/³9ü¤‡ªWŒÒşhA¯k=óù²¢:Q°Æ‚ šuhJ†°•s9ã]Q 2´ ÜL³ReFÖ½¬M
°à†ÊãR˜ô¾8ªÉ[Ù¹‹åQ/·P`vq«îô©Ãxò¼lğä²:"?ücCR¹•°şsÜÓäÓáÓÔ˜S__è$˜ëÏ °+q%‡æ£?PYÕRƒÓ>>ÍŸ3®ı2†ÓŸHLÑXŠ’Ğ•õQU{'ñÀKfôhèÀõzãH@	n+K`ËA\L²úé¢ø£ø¿X%ª¹BÔÅ¤„5µådÉ L~¿Mj½po´³‚Åîà…L-»˜E½õàéÍN7"¶¤ñ{Í—B=é ¯ÿ«¸òQ¥I¤Î0šsÿ?dû±×>¥Çşg7ÊC§ª…ô9’¶óŸXÁ4Îİ	,b™2Ïp0Ü›•l¢n·'Äl˜¬¢ªª-ÆG`/7âô3Tox÷K@RLìó7°£Í¼¡ïÓÇ¨ÔÊÍ¼Ö'®A 6 ^æôÒ:á&Ÿ”d±kß__‹´¬%=Sén69ÄpÛ¦nš7b=ÄøÒ)6£3Í3†xH·’™ÍÁW°¼zTù(™Ê3<6AŒš›&)àĞñ0Šæ‚iğšgûø‚Ã`a±Cçå¥*ÊÜ–]\S±ß²ŞÄ¢‹Z"ğ‚)™ô±tJÅj¨ìlO·'€gŞïlUÍÖì9UÁ¥±×uåháE¤Ò“Â£ÒõHO.ê$VŒ³¼vá;¤<iÇ½bxÛ‹<{_VPbÁ·{_œk÷•N™èOŒò¤=^J–ÕUùAİ|‚}Ù­°"Uüüêh(~úõ_z;ª€^¾AšPÒ±í£'Q<ŠÜé¼Œ<v2w©¸º¦©îèJÿ`kIq=¢¢İpêdÒh°LvÊËiÚoÃó&ş@ W§g¤Tgƒ1QQÅ} ÿìR©-+P?Ô<æÿì£Ç|ëÖJçt—ğv(PGÈoVˆÀCİˆ4Ÿ‚R¢1ÄMÖb
fï¯¥6Šü$2dçÁæµÂ>L8¤ã#—HoÅ´º„0âdqâ‰ç?îI\3DEÈì÷õL/‘&ÂÀŠy„¬ÏŞä÷îyÚs0Ş’ÆÌ²Ø(Şºå\³‘+nÏFiÀ=Ûê¡Îì%j×šk‹ş&=rc³	RQaÂÔ]KÈÏãæcoM­‚Ú7ßÎ )Z…,zË¾ú·¼NšûsÍ·³…­–ò *;¿¨"cwÍá%Pì3Ñ¿ÃÁˆŒo¼tĞÆ³Ço£ıÑ¿SN»ÃÎqœª-|n­O™rœQê”q{Î’0Aø?qµ£¨÷’,.ekŞ‹>âTMñ »­@6µÌš˜—
1§*¶	AeÒ­"Š £€Xi‰Ü Ú²àÔMùª_ıè~a(mÈ¦KÈ;o6|†fË—
^…¼‹;©!TÉc¤5’ó½îÀH¦ ®ÖœyÂï¹]ûœ6(o@t® =¹g?1Ğ^‚e‘@ái'#KÀ¯Z7Yê|•ËV1/r&‰Â¹G‚Ÿ=uØ,ÄÍœĞº|°ôÆY“P ×+'ˆÖ˜[DM.ÔEŠ!Ï,ë>q$Ô—G‚1úÆDÓ9XèwóAO‘Ø†W}ÁKÒMİwÂ Ä×gãìÙ6ÕK¯¿7^˜	¸#İ¦wø”°­ëVØ>òbû\ò‚ÄÖëçe÷äùd 4æØUß‘è‹í”'‚±…¼jä p®ûä@òñÍõ¡·‚q/2­‘ÎF'È³O½úöhÇ<İº•¨yòızãÂw¶X¬ê‚ 2ú¸I©rïÄÀzêüÛ”œ•éŒM‘ÈS´u‘=BìÉ"ôêÜP¨Ş-”­zE3Ö¼… BØ^o>ÓÔv%K›†±Ğ+Ñ'ùVmUexZºX~˜NÈhÍ/iîY-t?Ew|ş§Ò;à¿cÅ2n?[[«eZÁjm\½Ã9"Õ•îÌ|‡°"öİÄìÑèEÉh0iïÛ!m3µˆè¢›÷Ä¾Û?Ò´Óy|–Œ}î¥a^¡C„*#mk
·nªŞzbŒ‘0µœ7,z.êT‡¬CëCÒ¹«´Ë¶‚ØE.	(ªëHcõ@_UicĞ4½q~ò¡¾‚.a$ıYg¬†¬Dù?”o‹gĞV©Á¤~"½(2(d*¤È-™u¨ß .œÌí~¶ÙM].*¥*çëÒ”9nŸ.¶“‡ù`†LfRT†ö·He«§¿nZ>Á]P@¸rªzùW¼UwVË£Õˆ»0Ñ1ñ-=½e†¯+ªî-œó@Ê\Ö	¹y*ÒÊ®]uô<%åiµĞ•¶~şb¶YVX_úì¹o¯Ÿå~ıw|ÖoÀ"ã¨6Å€‰W"©³‹Ë4ka#²'ÕA±~¤nA'+"è¼ÿOy­õø°v=	&”íõVeÒ1«æ†ê‹ÁW16ÊãÉÁhÜQñ²óe‹Î]–ö n@[GŠ±ÖB3ÏO¨{è®ÎÆPë_˜vÎØlÆPdvúL‡)Ÿ
¤éãØŞnS&"O,»¹Gb )wN5ÆÍ¤‚möfvSìóßÅR…ÑQQ/5åÉeüwùä
JÖ¢‰€¾Êš6§¼Åyh;¶²ç«]±äãš±”pæl+„Œ¥bErnô‚²õµ€¬ÙïdŸüw9;»ˆhøVç–®\DU¡¾Î&ïÒÓ /ÒW{å¶À­§ Æöšo»úäfìïM×]¼‹~_ÅW5xÃ±×0ÆC€Ò’T/¶ÛË‘Úÿk|O*€°9òœñX7|$~–Õæröâj-q*'İP€_#•"H:låâ¾Ueøí|dìª”$å(ŸÙu²§…5è•µa&›­Â½ÄÖìH{+0&Æ'ÔÇ±WËÑ•Øÿ~ÓboDAılÖSlRã/€ÍíÛ²†UÊ>*à¬°=»”mQ@Çü>àiŠnüß(9³`Í½Ôª@+’Œ‰±
‚óp(9Y92[º4ñåéY"9d0
Ò\¥D°¾±Ôåw3ÒÕµøó2g«œ·ß» à×A¢š!õ–	±8y™€zÌµ@‹åÖÜ ıö¤®¹´i¦4ŸJ+äxcĞãÅ&7	yµçla2×]ì,Jjh­õ6€¦Â®Â=ƒ…,“ÖP¦®vÏ¾m9¨07u÷eEC”U;"àßÿ7†?[ˆf"|ŞN9'~	“ÌÙCµ¤Üé5X•õ@¼]€›ü¾îšÇæÆz–°Ó•¨*Îª2ËC-än&Z‰‚×9Ëy5é³õĞù`¸Ø$SÉ
è:ŞÙ'NI—–å óŒe¶œÑŠ ­#a™¦y²´×H4_« ûØt…®7h9}ìÌö‰Å¡,×a×sWÍS ûõ´ºİ7¢Î*2ÚÂû¼ø!ƒ‰—=ék€Àˆ>hr¢éçq;ù‚­Õ*´ëóØ05«ô’<¹ï9^¹á˜åVXÔÈ˜sÇ‡Yº³Šli=1‰sR²Ëí@ °å\³	âc‹b“á>U´;èpÙCÀÑÅ‹O\+°FõZCR•æQø,rç?°›óY“YÄØÙÊ °³îÀÓïa3™ğö§³Ó3¼êÊÑ­)ƒ€ùä±'—‹t ã,ôwgÚaN»BkQ/'Å+í®J+ÛšC{~]J…+÷9_>ÀNŠÖ¡nª|Ky^ö…<^õ©¯YQÚµ¥:[i)0‚kº2vGmÍí¦HÓÖ2SW&s‚v+“nîËƒä€Ã1Vè«½)‡º_'7×bn<BX,%hPGÏät©éÒò[{Âí£©Sb‰!«íİ(ƒc­0‡Z¥Z×÷„áûú¨+°B¦nnókÀâ÷šÆC¡¼^çeë£úÎ*©Ñ>s…Û^óÓp³n!ùÕÀ} ×õõuÄ>4?úb(abİ*°!âúy“«ˆ‘£Î,[ÍiGµfºíE†E!_É»2,NµpW=ŠİRc ,Ô~TµR\uU¸¦v˜i‡ÒãV_ö6Ğ|—ƒNpø~®–t¿r¡ç8ûJ%oad€õ_Ø½AT/K®¯ÌGó[Ëİ2šy¾…upçy»‹ªV4¸ùŠÿf±¥sÒO…èt—Ï^UüK.*t|ÏÒøÈÚt—ÄÕÕáªİ½ÀˆbÇí¬[.‚Ñ²Ç_O°)zhñ-"A¹Ëü*RÊ¤[ˆe`óº*Ût'ò¤º—6‰uóØgj>-k?Ù¦ÍânÂ½bXµıé™Y#¡ì'Bº†‚(Õúó~ä	(<›îÏ”ÌM€[æ!MÈ* VÎF)Œœ.{ÂéîûøæN÷Ö†œÕÒVù|«@İß›İ’ä¿ªğB';Æ’¬&À«cõïWÃªv9xù†ÌfxûŠŒCŞãÏ¬·ç¸Gî¶‡´aÈ¼#G’q(]¸éh/¡/ÄóïÆí­ J(´¤¨ÕÊ-×_4Ü=]øùñ|)¾¡€ïğ¯T¹ÍFvŒaûï¦ät‹ª&_5ñéUÒê –%ŠÈ™rB•ÂC¦·_ÙøyBº½zø}W¿¼“jCÕ¿ÊwGİ+Õ\vççøW¹L×Æ5¿y€+l5·>yıö‚Ä.»ğBhŒg¾©òà†ãñ»Ây‚†,‘~YËÉªñ£ßÂwe)×å”0M–`å_ÍBÙî>ƒZ&×‚ì±NüŸÚ{¹c­^î9fl»À¤3Ã¥Ëcéït•	wëÿ™ÿDToE76ŞÀJÖø? X0>Ô/
´¡Cƒ‰YJ­¾EA!Ğçt<<3@ûù_äğS¸â
ªvâÖçëßÿª!¬`Ëß°©.5ê"*ëm$vLj‡}³—„¿-¡¼p«MšË¸şÎÈP2_©(µyWìé9ûFã,špüÇú˜‰g’#÷ì1¬†Ô«õIÓõ/šÊ¿8 z~NK7À€Û&5	Õï¤­%1Ê©°Öğ’VÁ\Üâ5ö÷W:‡Ã3G‘S@üµ/xÏV‰Ô Î·µ¯ì_£üÃ…¹g°K÷l‹rŠÂQaä´’·O¥È_Õ‘¹àM…ş:
ğH±™ÜË…’9:í¾îóSaÛ‚&`\—¢æäÙhÛáƒ¶GE%˜RHÁÀDÇ^¤ù½y6Jˆ›y‰3 ÃËĞd*Ÿ F>‡kÿŸÒb€ğ…~)ãğ!ÃÉÜcS¡œy‹ó„€¹Ü}tû«­½“Lhu£GR°¥bıı×ÆÍIBI_TSJÅÿH°Li±hç„‡mó@å85÷"GnyşØëp’ª/r²¦y£\æB›òTLR2!¶Å¥Jf“R¤"¸™†Äçfã§9ËnJ§Æ7¼Ş8ØØ»xjU]øñnU‹/]Êÿ‚ÒäO6~iSm¢M‰JCRİÎt, ×{ªµÚÎ»õ­¦$T8v¿¹ø“ş˜õ<Ñ¦y%NÆ‡ãReê
?*aD¢÷»RêÊ)!Ün&–#õ¶·¶®&ƒ7V‡rœ¶³^Å æXÜÙõ¢9:İàóËkôõìQ&p“ÑY_Ó>mÉÿ76ÄG·tï-MÃâÁÉ7m¯°½æ³ÎEM1ˆ¥ŠsK]U¡QMaöáÀğæãŒk*Noù>V-ÏXo>_™;ÏFÑ=jáø²£ÊxüØ^=Õm	ş™•'¥&d–e{Ã‹Sœî#™a c†W ÅLPËˆüS|<ˆ€^†a§Iå;>»°¸«Ë(R¯•Ag`§xŸ5	D!­«¬rGĞªYVX+‚J”:]ßœ8'
XêÈ¸ØBì²0„1_v™û«Ëğ
#nO ác„°Ğ"ÛzíóşïsX‚6ûçÿºgºÀ78Üİ6‰¿¯ ÚİÜÔçò“Ôé…‰TCb~ò#1¼/Lkx#§yúUgàn/˜bNIğ² sÛq_4gÇ×ô­áûtòŒ?¯«".B.Ä'Ûf„Ø¿	^NéÛÏ\Ã./‰9|§­mæÙudŸÜ³ObŞ9°o2YwÚWñ—ÍB^)8‚tÒÒ½«Á™sìã$|XáŒor9Mœãê]°ğ¦’˜ŸÁMfÅ\çŒ]¸™GÂr‡RÒÈ•óÚÃk=>$Bšã¤Á¯M?¢ä¿*b}¯ï´O`YËx#£¶æ4´?0 ®º¢BG…¤wÕÚÂ=–½Hîäæ^Ş‚ËµòÁs$r®•¸bÌj®AÚÔâQWâKÎîı«”	CÔüë(ª‹Fæ_­~É¨“êPr¹!×³pkÉæŒc¨eú¼ç#:øò š¤JL´òçşàáüõŸÕS5~·gğ*-÷D!Ã§¦nµ§˜ç7bè?¥ff6z8¿€Eå3ç9zBõõgK…Ä]ëãÿ)VÚ÷k;Ÿ
\ì”êÃ·E¶A[e«ÓÎ¥
©/zDşw(ïŞ4˜é\9ÜëêPÂT„"´®Ö†*£›;d¡–&ğ¡ìTFÙåpˆ¹À"f‰IC%ûš¡ı®Ê”Æ êìØCE9>)ºJl¾Á±ÀÈ}IëÏ­½ã"à®ˆ€zÅ½!›ÜE]}x&±†(ê-~ßëLñÉ¤›>ÊjÄÌ”„‚‰	íì[¼“°Vx*‘`Ğ£Æw>”ã@ë¿z8—˜Å â“Š=íï¥~ÔHZ¸_¯aìğN$–œë'Q×É7Íıûjs:ÅşDŒ8;Âº.Hë¬çCŸÕ)bå@p¤—P·ã…à(Ë%”2÷¸Ã:©´k‚İp„‡sWã‘ˆ/ *ûkiŒ‡’SAÄ“OSYºSÛ<E»ël¥ª3HC§>Àâ‘¦v"$	¹e5À	1²ùé9~7ûÒpkÃ0j$;1Ûuæùûà!º´ı:üÔp«ä­4áP‹Y`#l¡›ÀG¤[Á D>:Èİªa“w§´¡sñ†_N¬"4 GÇàµ^g3ĞÜzbê]&möUò¥€jYíe'Íò¶!„Š¯à{‚Æ«	 “l¸% [£<7/pC¦Oa¿—‘Ş²Ò
Èı\J¤$Ó¨Øİ_¯VÁ`>ã	Årì€EÛe`¥s]6Õœê¯åyûÑ­ZNĞXºŞÙõÀÊÿÚ¦m.s~ù«PÆ¡º[|åæo lÑ,İ×@õÕ½Nİ¹ß-7r¸¹Ù®ªÖ¶PÁèrŸf…Ë åóPj°u»×tÈ{ßUkà¯Şk†6Õ1ù:û¸ãÃj2;º¥qîÈ‘IÉ'Ş%WSÚÌ*³ÆSåjÅ*24ó²Ş[7àö»Q+v+­±WUcNÌ2ÚıƒH@áÅµ^@¾øòåò&«DÏÉ½4ã[èçB&.Ñóv‰H×Z’cÏOø5m´Êo‰iñVg®˜i”<–/áwİ¡]}µ8ºtOZ×Ìğ@÷Ñúİ(»@Š1Aé¦ßsm dÉËkE¥wodòwÊ½¡)=²æÉd°^]ÉøÎGSæ!Z8‘f´ìóœİ‹ ÿdmšJ¬"ZÄ¬u’÷È„+ÁÛ•[NY6QŞå’3J¹¦“°Ù#É´ˆà˜‹w¶ßÚBl©­CÁÅAT²âhÙËR¿±ŞÁ"%eù¹n®?sJwÜ{Ù˜ö"N™±ıŒÒß91wâÚ<¼‘p=²æ2öhàtcÒ
¤¥T£
¥³#ó!4Ôå•yIRé‰½\9uUZ,S‡Æ‰îdã»sİ•²,² jek‚/÷ô8y%iİ¾w“‚ò³öfa%2yTø‹öÂJ#Éˆ†â%,—¥Ø×úãæöçMhB 9}ş9PµøFÃôBd2>æ…¢…İKÌRüÕ2à£:ub¯30ú^	¸{uÌçJ_­¨½0
¿çíZ£´riñ1À•Ï¬ÿ‡¡h†x2½×ÁÀì3*Ÿ¹f¢Dh5h@-§bÔk‡j5%^ğüL©½ Ê±j¢•F¸tbäÕ'c+Ñ‰(—Î}©ß³'¥uZéÆ“õë¾@9«Ş,}EÔÁ]«Ï¯VØ]k´"Ö«åÓ“©‚KÑìú,²è“7RY•ÚpêÂS½kĞšÑONM¨oŠén=¡”«ˆ,BÅ|$f:iG™;¤ŒÔœD)à+aËƒey.!?©ÀhL.›ıªî¬W\:%1ˆ(¥›Oee{¨L|‡^äÿİãó385´…¢ûWÜÜIÎs¼ÿú’m¬ñ¯sª–ª)^Û&½¡wÉÕiY´£õÌ&\˜:±¹)oŒqlQU`÷Ì8ü]‡å¾aIİ¸<Q¢A¥{˜ª~Ã¶^]rñ½æËèí°Ù4•äKß5G€‘%…±÷œğ¶İö~‡ÓèËvT\Ò %Ëo–#VzÃğæÏÄ´­jÄÔå)ô¼øoÄSòk‰İU“&}Pµun˜æyÀ²;8pL~t×8K9¹é'Âº­¿‡»GçÜà]¾QÖ/0Ò‹Í~è<Î—
!6…ëP¡+Ş¢pìØ[=¯e–™Ü¨cTÈİÙğ”îq+ıIÑŸ‘é´û/Š
£ÜV•µ®‚f¥BâşªÛ;c¢Wõ¤ëv†|¬KIğÆLàõ=Ñ0E@R!—™< ¦ò˜àoÍ´ÁÔ-Æ‡p„ilvÚ2ÑsÒ¹¢¡	¥Š¡up*b:!Øü+e	]{7¤#²>ÃÀîP%<bŸCÊ•0XÅW$Ù‡Sèí/ì‰®•½Töàõ´-Š/Ğ_5DáˆãÀh=çï=„®gKÕ,@QD/lŞí=õË´ETÏî‚Ç#µ±Y#	ªW9î`?\üCÜ¶Î}I‘|×M`­kÇ¨—şĞûü·ëªÒkıDåo$èzó¿ıAû÷pşäÃ/æ§`î]£ìñ &ªpAv è(jãÓı)[˜ÚÉÅu*x¹b½ÜÏÕ4¸ÿQ+˜ŸV•éíñœŸ7rˆ•UiS+ÒOôÅå‹a„V%ÿ¬Iu	*)Óå–Ûk?°Ä?ƒC@ŒY¶6äê[ëñÃnåt—,Ã¹ ÇÛúìq	ı:ıb@ÛY[ÖaK	Ø¹ÜóØLHuKö©0RÓ¼7ŠCÁt¾¨Ú3ÅùŒó£®ñYİ7o'äğLèšÖrÚSøS„ÇœWƒ^–˜sˆÅ¸@±57µ‡L*ô¼ı€ô6L®7Q×–ĞT%ñì‹z°ú¥—„¿U3®ØAÛ›êëa/”zªõ]³kCÍ;`C¸tKğ²{}¼ºa V ì¾lûF™u8‘ƒDØvnî1t¡ÀäKû}SuîKrt[‰«|wxoz`uúõEN9‡²SVò€FÛùÖ€CI­ğ¼
9"Z¬Nò~üaù/œı÷$ó3§Ø6Ï€1ÈJÖl€0Æ‘yŠ¥ogI‹Ô—Ü…é£1¡ÄcàòÑ¦XH´eé0‚'WÔ%å¹ş¹†¹ì-=ñÓ~c[-MÕjwñ¤Y$¹ƒ‡áLßï`Ö·]Æñ—–Ë«!c·ˆƒ?å®œşä›r0>h´½jµüOÅ\ÍÓòí0 ÏCKijômqÀ*¼ÏøºrQ*Â£°Û/¤–Û;ei¥”¸#ŞŸw èÌñÍHÂü³f›.ïÒĞq™¸¹ îŒc¾Ÿƒl	@±$HBñRYèŠN›öMê² t°€éqæÙ*íõ^‚ é“{;0r#àÊ,b
P„—šĞş«ÊØyÕ$RÌªÃ±Mf©¥¬ˆöYÂÆ³X¶‚Îh6¯*y‘my €áûI‡ÖÆ¦õ³¦¼7BUÛE0¡ª‰ÄÆƒ–S†Í¿Êı.ïï¾ÜãKlÖ«Á`˜95£ØrÅ[ş|bQü+^HslÈ±‡I¾õM–Ğ½œm+W7q·ù Y¡'µYlÀÚ5¯Ÿ€¤ÖÈ!>È˜Å¨—··*Y¹âºª<¼!ä–›vÏ,.¨áÚY@!®"Ü¾¬E½Ñï'„pO²l	ÉHFç#”‰$ÊxsB„ˆ§*ØÕN¿}Ü3`kŞ"ëA”ø—4ÈD?ÑË•wSYíßáüO¯ÙûiÙ„Úâ/-•Ûü˜HĞ´“†¾¸Â[<y9ŸK!l€1£$Lã¹Î
 Ó4#mıÒs´/5»Ã®(}¨zÑÃ^*ºQ¿ŠkâÙr‚DÌù$éõaŸ¿–­×Šrú0öğ¡ûFn,ÍÅ<"â${|)R¼í­ç×K&ÓŠÔ!s¤çÅG:O éu+O63¼‡©Kÿÿs¤›¢Bšº%Òhİˆ¯'1WwNĞÎ™íÔULÓ¯ç®‹ô2¶ıÆÕäÚ¹•ò¾ç®P‡4„,]dhaWhÑT³t,
§¾29G¡îóÕà5©±¢Ê·©w±[,;M|óøaÚä_¨ı;m›išW–L­2^2ÛDö}¿¸©æ×(&O›±¯^ÖvtîİŠŠ·9Şjˆ1J7„!ïÎ(™vL°ä&uß_‰Ì'AYú|Ù¤‡ßCˆjÌ°ŞRm°:«´Æ_½ØÍÃWNÈ«îW®5°hlxIÈö.½}@›²~˜eÓB¬V±©~V=Mô€“m.ø(=ŞÎø4¸/ÈvãÌ8Q´0öo;›èFªôágC
#úóÌu‘eˆŒQÛºâòÃ4È-.–”•ûÏÿf ôİ~9\Ü…OÓ–7ÄúÉp0dE©ş“×Ñ¨4ê“=À±Ûğ0mT[»¡„YÖZ®6u_i'0àk@÷î€½µµÊn¨%'^ï±4ŠÌœSsÆ$5‡ñÄ©™´˜9cRş/&,HÖ‡J$«v©üóºm”úV’^À…Ö`	Ø
*•€¾Í-r¾4Ï’[¸S”R7÷¤úS‘AÒI(Á®OçåQ‹ÌŠ°•¹QçÀ(‚½”§ôL÷XNhÁ0~‰u÷:L_îÈuqW¶\C8,‡9o“»’Ã5#º×GZã8i)†hŞ'ûtˆÉ¶}>Aû´+¿şcıÙ‰¡?âálsù4[ :(*¥KHÇ!ySåOôKÊÂ
8d:NÂ_xÚ y4£ÏÆ'7˜çæº·¨¯R–Ò¿ÂùöĞ¥¡äÎòÏ˜äÓ?'f8;])÷ß/eÖ’µƒxgQ’‚±4P7FĞC`\Ä‚ÑÂ©æ;"ªq&3~ÒN	Kèg>‘Å×}¹¯=`Ä(yCİ{À¬”(fhønÎ†µÏ›*3Ùaµf¬òl%/Æê)s«T­Ë§ÊÓh"Ú˜Ğ
ğ„R›©ï»Ë‰ê¸®ÿWùĞ<eJO·iÉ»¾J˜†§?77’EGL¨Åæ®ÿ*ÙW¨{˜fzÖş«ÆØÂ4M‚`ÙÓ‹Í®û)£ÂI¡Ô`œªüiUÕ^¹ÑÑQ¼ÂRJ%:ˆöd{½îõĞõdËì§yBpë£f°CĞÍ9.VÙÇÍOÔelÅ{Ç•û;Zk¨¯¹eQînVCÙ?UF5´“ƒD‡HAÂÛóûŠ°êA5n“x	!lÇ÷_Gš³ÇW3Úä\é¬<–Û¹éÊDÏ19¡Ş ™48FagS<’Ôáİp›Âm&´ù·ÎÂ{¿€|‡˜Q[˜áú^L<Ÿ¨Ñ†Ù\ÿziÎvÎšÅ|Kç¶rb—×şm¥%8…a3ÓbÉj€šØ¼tœU™³VÇğ;ÛM;¸İ8>ê£éŞ@	å©¿=F[n!¢l	Š™İhá[}ï7'4¢†ì2Üÿ¥*äEI>%#(ô|ª›}‹hI*jjŒî¿Mp«ZÀûOÌ6o–|›M{nëÆ¨PR»ÀçuÙ£Ó œ?©@õÖ@2Î¸àækAR”<n;g'Oìÿ¾WQ7i·ÛZ)zË¬¼/À!ÿÅrMBD×ÀN@aÀ—BAÅš%û)’¿!Vælï°¼æéZÒPo9ãdßùœ…>´‚¯µ»*3™æ
’úäRNÆÆ’®‡„Ù€eRxº¸=í,Ë$BÙ¦­¦¿¡iÀËLdîÖç ®ëû¯}Gx.Îÿ
Ö*]ëVßX€5İk cÙ«®÷e,{ÆB«] m7Î‰¸	"_XÚ{èé¤vÉÄÄ¯0¥çĞ9ôuŠ–Ÿ–CKÄ°¢k\ëâs	·ì@‡ÿ SWƒsªf½š;ºœBZ;×ÁÆ¯1ÍÑ
b*º`ğ!®ó:*îó©("ÌDD•İH1óIî½”jõ‰ Ó{\Vc+‡>’´g‡Šsı…¨yÀ“±øşüÚK‰É…‚ù¿dòæ†à¯ìš¶xD""XGšÔ^E…€já´è]µ(±än$…QYd–ÿ£a’ö?‰Õè6!×p;Âš=d>sOÀq4Ù-ˆ°áåø7 òäÆá[;å‡uS£9È.-¶	u^Â)Ñ?×Ñ\Bf<Í†*ıĞåòÓ™JÛï)qcêóG¢˜Ä<ìºÓ¢}9,xÿ`%¹[lÇ™nƒÚNâÏ1àîyb3µ<Ù+˜}İ…‹2×=¿şò-çÚ}¥aw‹\ÛÒ`QÅíD—ˆ¾%s¯ºjÒ3œŸWÁ2E˜¦X]ÏU\ÙÅ°K˜’°u2`˜ñî‚1â/fşÒLN‘wíÚøÒŠòÚSPIˆÛ=è­ò°	é©‹wL®ÒÚŸO°nä°‡®]ìğhIíªú>à¼°„Å…ƒ;øó¸Y`=XSO-‹âí§î(¡Váì ·nğT%³×ÿøf!êƒYŠıÆˆçÑ_	AxÌØŒŸH±{š›?2†;7ÅDÅnş‰¢Ç½d_å$„s-Î†hA(Ë»õ^éê#×†_ÖhĞ\ü›}°å0Rb3À¦Y²\±+çĞv‘j¤„…`[émò’_Ñd1ujuŸïº¨NÅ?¤£§ÓVyã¢GXP»{÷
EPX^i°ƒ¼X×ŠŞäºPGTØÛêO¶š(I,ò1YŸ™EáŠJ#‰Ÿs-d°\ä¢ä*ãæà}’›yZaÓV¡q’”İ« Wå<w®¢›—Ck„’pŞ°³Gµ‘¸Şaw/fœõK²|ÌìIÎåçÄÏŒ#‘Å³x;,XÓ	ÄØ„­6¸˜<
¼çÇ¿-ŞS¨<½2AÃ.£¬JïrpóïƒyL¼Ÿõ6U¦šHàÂn—s{jÍ—)odO%b¼§”±S²iòÅ/ìñe¥¡ôñßd6©x…«Ûº,dÿ'iÌÕ›]a³Êk=şÆcŒ2@Ëgé^¡¬BqgT£ôƒUÁIDŞe«µtÅ/Pk½ø1ó1— ‡?'“Wú•½m;R©uBæ¾–ÛİÃ«Œwö:bÖ'Ô1±¼ZŒğ4İcø|9Ä­/XG”|At„ñ@feÜYúÂpC~<2ò“Õ¤N¨±„MöºŞkrêgïFòL¶qæ9 Æ’‚_}âEyxaÑ·Œı!Zà‡_øe®Øë-äÙ¯ñ¨ŒÙì5ÏwC$ãaÁµcŞ¿µ>œ`;£èYcŞÒÚ›-¾,÷}áŒê66
Şü¢yaGp²Ï%¼Ö7Î9Mœ¸7!?ßš0fÍ:ÑãÜ×ªNN|Ë‹?bò>ôH\Ø	‹ç¥)Vr¾ÙÎWß«~½|²¦Ó7#“à8ı€a½èªÂAÓ ˆ¹†(ÓÍ¶¿„“Œ°fH€(òşŒ®]a¥g–G7å‹8˜Ÿ‹µ5ìĞ
§ı†ÅWîåFê%
t[ßz±xL».kfŠ(–?¡YHKêÿĞÉ^Û‡^?õ@e Ğİ¶cÙoÜî\KÅ\7u£%q™+êášI"¨˜ünî/çïnÂ§¢vfmîï|oA~—œ{öšíã$„ŠıŞyfX+:Lº¤!ƒ¸pdÔÑ}SóLŠKâc‹“5K¹½±–dRŠ£º-EuUj`ï°ÉW
Ëf„X[vyß` ˆ>àVÇæV¸íÚECYgmœ„÷›_¥6£ö[‘ôæh§¸Kx<¢Nşèv;ŠtÇX¤¼“$½“ÖQT¶Á¦ç§ß¢ÂCç¿úw`2öi…«• ¨vÄhO"Éf~}ÊÛ ~0Ó»ú&té®Æò—–ğw°d§-IM@ÍŞX9†„{QW`İÇ¦»¡¯x‰ân-?ÑÌ*¸ä7MÆ1Ò)ä‰#¢ÑqêêP8)ÒßlêëáœMóèJ%ˆ`70:M¢€Ï]v)PY ¡®¥È2+fw¬9Ø¾63¦P`¾–u¥»›…Ã,O!¢yâ£KŒö”üˆsq{I	°ªc?™›Tn§†Au.Vü+ÈA	ä^VÒÂÌºK@ñ5ÜÖ“…5Tœ8
x¾±R‚+Ğ#²÷Å+HÓûİ‚¬C‘íûßà¢£E•ä]0€ØÑ ¨C¯9gLàÇp[¤‡±)/BOëm‰æ¦ ‚º³„#<ØÇñ²“ÑNCšø@‰N«7«ˆ/ƒÂldV‘Ï¥ÕæŸú/£	 üVZLf
ÛYLÊ²ëÛ4ÒÑÎSz†¢Q~õÙÌ¿Á©+U`„wNó2ß?"%¤ĞïêJ9&¬!§–©3“»ÚRŠVŒ¬wƒ&g¤½Æâ·4t ™É¥Ë
qj9‹ãÌlö/û“…<â°
uÒ#ı¦#÷|)¸•n0 šğIæÿ¹cd3òÃf¯Y„ÓÀø·¼Ô9’Û=3öm‚Ò(—Ašˆâïe`Î¹ü»ã·Cµlº0|Ù0[bÇlò†Ö´œÌADÜ¢¨ºI2MµU¿õº:WWTA —¼6qU%ôK.—X¨´ŞKiit¯‚¿g`QVÓ,ƒßğ8îì[ğ2
KÎ‹ø¸¢øæ¯Ÿy›°‰pµ-¥^…µ2º-îî¶?“òe+¡)i`eYh:@$¡Òöy!ªØ .‘¥ Ìc¤Jªˆˆ»ş®«2’·é‘i`›ã#³¨²ıH^=dÌ´º
 ¤HR[1±|Æ1‚	×Ô´ŸhÅ&‡úxŸƒ‡S‘«è7gğC‰4YZÆÎ§Å-X0¤Æ«´>3„Ë±d¸çÔ• ¥!_K©QÛ MµcÂHj¦öäø ©Œ`†cS$¡åó¢<…@ô¦cü5HìkÍiR—ÄBT¾Up£ª­dp¢4æ#¬(½÷ËßÛbíÕÇWS”`•µ}–"&£§uƒ8ÅX˜R±lÍÍêĞÙ5TÃ.÷ª©(È§U‰—zwy¸›º¶­)Â»îÅ[ã`,)¸:´(æ‹'‹¥HÛØ8¯)bY¨•æ‰ş*3Ãoz@5ØDg¿¹çøR³g"˜f»EèÅfGFÇR¡*Z¿İ©ÂŒ=Í~KíÜ÷J92.;X6¨¥eçä9Jì	naş®z3.Y]zq|aÆã 2°ğÉC$ÒO¨¶¥ŞH3$/5‰‹<×Ox5ÙÉM!P_Ÿ&1Õ…¦Cbl˜â¦RÍp+W]å)9wz·›l!»n×‘æD)éivQW÷>Q‚5sü0‹(%œ’ô`ªœñ·8Ü‘óçâöç~0>ÎéKğ‚	6¢M|ÜkÎAÀaõ‘;ãarÄÕsıÅó½é° í²^bbK«ÅáŸ=)×MVÊ>ÙÔ|·¦x.aÀßÓš%l¸2?µI*á.p]ı¤Yê›©D@>Ş88ÂŠ'jŒ4>ÇRz:Ïë-8ß?ª–mÁ-qİ$’·í•h´ùÕØõ(=4É’±!ÓÃÑ_O„¥?,dÆú!#°•sà#4aIŸñŞĞ%+\U÷Ÿˆíj!VË±ÒdM(G7¨©v
ı‘ô­²ÃŒ¾ºWY%çö *°îiì}ÃøÔO~C½ÕInç¦sÛşz†TYZ–<U ¬ˆ®C×'~BaÃJ+ÈIİñ¤jå‘\0ÿ·N~	ûËihÉ¢Îk=è:Ê¸¾uSiôI£¥§ñLNş-)B[Åmÿ43xç`*dˆÙ­"š'yÖ4ÎÃ‡	ïâ& s¼iv¦ıIû_’«ı/ê&p1‰˜2uáÙ}c–‚¡Cê™“¤f *¥3“e<òˆñ>ÙÜY	2"y&è›–/  Ùv=»å«nf+Ü;dæ X»ôHóBF xÆhP¹J½,~á`â0´Ê·æ,ù(úæ\LğO·¥ßA¹âİÊÿ ²¾?ˆuìt«#|”]îa„T.Ö\-ñªæÁ•(¢á¢Ñ!İ°`ËuùW….ª/²r†*:íÄ—â!‚v&›óR 5&› øN¹
‡Ç?V&¦“…>ÿ}
ğŒ§šo3ÆüdXíh(¶Çóô’0¯%-­®¢‚‘_d#¤¿9<´\¨l’‘°’R&¯4¥®ØÜÿakPÑİı ç=ÿ˜‹áóé¨ "sí»Ün¥ÂÒúËÆ›ø‚µ«ÙkP#)y^İ%^Ó‡ÆÄôšQˆ'Ê%İ¤Ú6Ñ»t–®ïœÙz‚+a´"^¸Ÿ2rUØ„GíI×9:ù#|.ÖV47†ÑŒÖ:q$8â;ñÊH3%Ëæm‰
eE•&¿bô¶=ùûıg…É¢fZO›FµƒªÙó…U]Š¼rF¿XxE şüÏÚ½ØÌæ[:ÎÁÕÌI3¬š•TJLuGÂ,ú…cûÜ	×?ç³·˜6(È-ì×6ãÀ™G§³ÓÂÑ»“ìı:)©²" [\”z»]ùì{³…ôGMQ®ZTŠ2[uÜDôÈ6üÎüñI&Åù°Ò€úØ}2÷äE	\ukòŸ·o2·ï|ÏÀ_Êcöt¸N'ßÖ€.´£­ÌÔœƒò`ßbû¨"ğ´&ä†¸Gã£ÙzEn
ßl\% ]ĞR ;Ï°üO>êL]%Ä•…E3Å€Ğ;w)¾á'M§Ã55£qEƒTNzß‘Ò
}MğÊrXŞALÜ/|n8v#‡i}CMh”¢#B`;%J[e!j_¸¼¨EŞ„ÁI¨O$F÷¼“ v¥	¿è$µïû}¢GÍµÜ‹…¿:q•;_Ñ~CMıËKÏ°iöT`Ãz"¹İ|y1Ã39ğB=b·¯ÁŞ"|¥=é¹êé4ªYVí“Aõ¼|ş4•¹îšÉ›Ç£‹)½Kn7Ã»¥¨é:jMTtı:uFÎ„¤–İÚÒ_Ò„ãºü€Ñ`£i+]r´s[SEäÑ¤ìÅfràjÿ€«h¬kf9ˆ±åí×’"Å§VEYÔ®å/ñ+³ŞùG[è–Èœ:½)¤m#ƒÁ±¸é¥Wq9eÂRü	~r¡e°æ4Âãb ¢^×^S¤§Ø-wÉ8y™Dîúš<g“8@8èÒ:ùHº;–]
‰e¼–ïv®Ê´Ù?
^¥—;É­:û6BÉ÷¤XrSúœ  ‡œEçæUs†ãêü«3êÑ–†ùØUcKş&Üç^¯º˜»İÏ'½”€Gù_•<3<ÈI1ìEFØ)ï›v‘öí*œ-æ‡’ò¨ào!²a”«¡'÷éŸçmb+HÉ’ø“Mv[Lgxc6¡±ÛÂ8{Œ*ğqÉx¥,S”°ã.„~ŒdÜ›¡¬9*M6ı¾cï+Mšˆadu¹gmó*%Á<úv²¼^öÌ­é¾­›£‚{l€Ÿ:R§L ”=¶MÔæŸåœ¥?bWóJÂÄ5©ïER~._8Ğº±ÂËÜîŠFcÓÛ'×¹fhMµ¯.åò¶46ƒ¶RšÌ«èÏ¢ç‚ÒÀûhy;sR^qİ |ÍA°7/½Í_d‰:PÁz$]@š‰úN½M1<ÅØœÙ¶”9ì'¶ÈJp)ô$ê­k`¼ÊLJAÒ2é†°ß®†û%mÛ•Gû/f;²š>¡®NHën3–¶Ğ;+æ‹³·†<ÌNí½#€WòiÓÅ?"Úˆ±ïĞ‹[@UC—
ø?KßNèã‚Äp>?’;<›0Ù‰îhb¿éÂyÒ‹ìÆæ,"C™õ8ÌÃRLDòe)…*²ôõ¯¯€*<c¸ä£¸ŠR=¬Acİw½ÈZ
pGá"Å¾Oİ››ÀaOm”CÔÇÄÁO9Ë^ù4ë°ähÑ1s9/Ó£š)m·Ó§«¾Î\1]AwËì‹Y}Y€”GsS»§<³xP‡.3rmìß©×,ìp ]|åè¼ß£´¸ë–7yIŠ+¹’Sq´ZN>lÚ¡¯m%©YíF÷æ©ChÿŞ¿É+×Ó¤Aï`GÔuÛlâ¨@` úğS b{QX	CFìÆ"ÃñZZZ ÆÊ¦¼ÂNe¾HñÚkØ”[‡²”Mº<¹)IÈlø-aã)ß{Ñ
qE[Ñeb5Ê`+k¢À¨ğö(œFÕâ¨=%@á*89®s%?Ëx¼„áĞ€VçM]ĞÔ¦]/ûÏÁ´r
¹±K0ñg„´ìmæıZh Õ6ç ²(+ ¥Ê@Ó~¶Õd½ b¸!¯v8qÁr½³±“‰§*ŞP,Ò£şM´¼s¡íVw:"ºb_°ù¾E£ê½7Ò.°U9÷<ˆ¾ò»B‚½ùòÇ]ÈÁZ¥]@¹,¯UÔÔ”(wü©JüÄj¹¦St7Ÿÿ®mé…ç¬½)«Øm	Lo©ªN*EÕ¸šîG5 TKõn*dŠÜDOvÀÂY§z‹K÷(¹©c”ôî¶ÿWihşMYµµµ3ùÆ÷¨àÃ‹z·SÖÔ‹üåEJÂ@cÄÊ³häşâY¨O,<ù›"Eúœ0¥FËÓÖ;e\ÇvıÉ4?ºWóg_Q0“ÚhÅ1¢,bN‘´@ ƒïî÷²™¥+@@ÍMŒÜ¿‡z(ö¸ÃË
#E‹×ßöÊb¤8ÑºÙro…[?;Y÷@Êetê–l…´ät\®­gI5¡C’×ÂèWx`ˆô9Ù‘¢UåJ»–LìgE\Õı#»=€Xphài‡%·“7Éõ‰ívİ«^Ş$<	ËU|z03J&A:!,¥VN²Œz#¶‰$¬Ğ†ÍÄ\H¹Ÿ_ŠW+éŞ0E€R‘aõxÕƒkg‚ìíÒĞ®44ÒpÇä{Kz‚”|%Ë<62²Šã°Şğp“YÚıá_yÜ¦XÑÉFÜvÄ~øÄd	SªÄ‚¢1‚8 ¿`9CÏ9“HÃ4ÂjÇÖ¬À„jŒÖ]ôË­½±˜Ã²ÙşœOxq-ª®¶ËŸì_[4Is¢Cr4oòtVÍ˜ Œú³u1àõ¤¸y¾UcaİèÓ¸Tİ·£jtùŞĞ]iMi{‚oå<U™âèÈ¬},Ö¢’¡ŠRy’wšTcXvóT¨Š‡^
jùä¡#ÂÂDàÜÌ± (H›7`¡Í»”6vó¾©ª†Ù~e?¿¹o(:šL| m-ù¦±tñaø®ùÒ:aØÙªyÌ™fL¸i°(U–+uÙ“¦0	)½j¼!UŒr„9›ºGN”†ŒÖñtŒÀm¹Í¯Şv®Ÿ)›LÃ¹Zè­èb…D$¤ûmÍÅÍØ~³ÈÆ‘]ƒ­äAò‚Fò$æ5ÿlxè²ï	·qD”^>É‘Å›w'´¥+ÂZhÀâ!º/0ÌœgÛò'xü@İºáy§9Å‰A~R)ƒ`]U”Ù·º_Cın±¼e¸û„Kü¡×³€ÑÛmãÇk>_>î(›¥æv8+¯³t<|;ãôêØ³´ÑÏıHtÓÄA°ığÖöÊ2ŸËk¹«k.Ñ¿ Ú,æ–ş´XßXíáÃ²º<v8oTâ(€»|aäIBä/ŠÉiMïÂÅæ’5é$:à	~Jc‚A¢Ç¤/WäÒ ‘DDÒŠ©ë‰-óîbKY|«XCÙF)¡DàÈÁzäSH+P`ƒı(‚Ñ™sRş–ÌÃf'B£2BŸÑ,–2gúƒZÈƒNØÁ\d¢a5ôä3e]¸)·BIŠN‹WÎd‘Œ@~çl3D@~ÌKQ>•gº½t•×Õ³ÜÊ´íÉn:ar~~}¿ì8üO_hŒ o…†ş»¾ÂÈ{•úP1j^XÃ€„½’ï&2|-ñœËÖ)?¼ ä¤İ—;PÕ1Âñ°Pçk„· ÔşÑ NP'§TüÓoÇP¿„àHR0½›ö”×:“uÌ&¸ÜÂBÖî&Bãµp€|è]™Erç
93Ìò™yJäô*i¬
X3ïª×lØ¢¨¹ê;±”‹2Ği*ïÉ­¦i6ëBo5ììßNş>)ÁJ$ÑQL‰rKB/Ş]jüàÉòï.àë‹5\‰N€ğj,³ïHäg¥±ü>,Ã«¬ÓàÁ¨ a’Jø0,ä¾ nCojåŒªdİÙA3æÓËÈÆı²T µ;/½ùF £Mrâ
/åa€3tiNÄ²¶cşx}ˆ0$“*hJ—‚2›ı\Pıâ@Eañ¢TO]ïfÆüp8U	ïÊ$¹Lç9,ûæqÑ‘’½Õ/È›³³C}ìõ›VÅVO3eñ‡4B0}VÅ§8 —”u#[,ß‡¼"H"pª5³¢ag‰ıN’B¾ÕDWÄğ|Õ™ş¯¶q¾Ïœ	n»>¹C@Ô¼?š¦g™ëAÏ?”½P(¤cdá½Z„r!côjeæ«:óRş§àNÂ^6˜¨÷q~‡	k~duDwÑ®)7b*O±q)ZÑÀ\m¤ÎP¦!ëQåœEûˆ¥™ uoá\Bm¦*e—w$ f€XÔ”<Ş·s¬.~'é®„‚[Ô¶›¯HRM²µ2E(ddÚ{ëá=T•l4œImU{’îdâéTºD ëQ¸îkêŠè÷kG?’Hxµhë]¾‡ÑÕqJÙJo	R–åäÕÎ*ÀÀºƒâşYJşàİúÒp2!ÒËFù­í[ú-¹=Áõ@¤!7¨-/}(îMv¸õş`ùï?üÊ—Cã½á}H{õC×J±d/©­.®{Kÿ™ÖeDqôX
 M4¸Š×o½¡(z„ä‡(O÷˜ m¦¬XÅøbÿò+“ò4í¿à[Ğ•¶ ¾<úvÑk}ëbØ·¦ÛÄÔfŞ”nÀJªX{¹ˆ…Ó7€Ô„`“nH;uÏDÛêx°yÅÁzéãÈ^åª‰W•u†ßv:’N@›0ı=Pp¨-¤VÓM§ÅSè5I8ùÍœWñ÷.zĞ\LÖ"4øCw{ÚÓÚ‚†V?}µ ÇÓúÛ} jÀÊ(5I”şëu¨—yzéH‹›SŒ/g{­•çLó0>Çd‚ıİ LË‡k¿6~èÒ÷ÖB„ş;·m¤N£ã¡—ÇMF˜Ö¿‘““Ã<CR„…ıBœŒàœ†¯_uîï†¶-{yD‚˜x|¦¢‹ ˆÖª•ÿq´*ûæ£OÃtŒ|ú›YÃœc“w¾;e‘Õˆøİ~/ƒYzL®ÒFä"GÇÄN‰ÒIi°ÁÚ¾ŒH§dÀ«N:H£({ŠRÜl-æcğMD†«">ƒFÌĞ¤^¾m=Ş½uø–Ë%Y¿©ğîŒC9nh2:¶€{ó5xU öÖ´¿æ
Åöeez/ùâàØ¥Ò–µTA<»sÑ©¥óõ6=»E
Õ?1C¯„’VœûVí·%›Í ­‰Açİ5ôÃ6poÁ¨~­Ğê€|?¾5+ ËvŞÙá˜‹‰:s«ıG:¶t×ó“5p-}Æ´Kpß÷ yPïÂÿOz“¯f|¬š±C0dzöÖZœ¤Ç¸âJ¯ ó2Â˜ã›Æµø>JõOÕ¸T¨ª9¾Mı»fÜÃÈ“ôX_ÛºmÆ~Ù¾˜|iéÇV™¹å(çôéƒ†åÅoÖ(ğ]Lı½Ş0ĞŠ­Bòªl†î¡#³RÛ‚ |iasÄ¼rjæ¯¾›Rö™ƒªoøVåt«äî'l¬ÍNœu–¹‘¸ï¡|2ŞD+kEÏNBëš´|ÁQÜüJv¡šF<©d›Ç¹ıúÇ{g¨¾éÃÓô ønw=„r~¾Ìı($5ZÂZdÑ£ÍÄ?ê­ä- ‡É©Ï¶İßóÒQ¸à„¯€i}¦I£Ö	fƒ*ó1» èÃ
ëÀ»æÛœ>FâŠr Öªüh0ftØ*û÷UâPıó!Ü” \ŒŞ¶ Á$ÁH1Ç@râdrÇá\ÀêËJ°œ?|wÔÉéÖ<tÿ­îJ%'À.GƒªqDŒÈç”0N¼:P<³ç†hûAËrãQg<	¬UÅX76:c…ê<"–OÆFŸ´CIÂæ´å@KŸwB\8$ÑrµpXS%áó]}UN¼†È;pwÄ‹_†;“n ÜZ¾œé:ÈÚÀNµæ VÂ“¿º2mÑ#S¼›KR¬¨w@qòIdï§YA‘Ø±Á‘r9dYÌxÏ^</6Ê{áú¶dæ"õä‹|Œ*¤.„ qHÏû/şï"F ãdÅ\Á…í(/o»Á„1ñ–Úlyı$1‹üú[ë»õ”ÔŞœ:ÂPCjòĞ¥ôåı˜L|ÿ¤ø€ÍìÉ¾ŠK¡ÚA‹Œ|Ñåöëÿê^<oW·Ñë~€ÜOº„~²ƒtböyÿ€¬±*Å™:şR‚	x\r*I:j¢#Åcöš†ÇÂ'åöòW^ä\~Ä\&0Òev…:-µRR%w/§g•»†yõóĞˆDÊı÷êÿxTŠ­©‰ûÑË#†UÊ ´üRƒøÌàôçb|€Ø×Ú‘OãYæê³²²ÏIú‰û5Ï—h6ÕÀ¯lğ‘èô¨æ Ò]'UªçjëÀ(OÛòuÍí½G‹&(rÀløg-¾–OEÎZ¤‘™=¢·’Nëpá¸ÿ
,»—ÔlªòÒÒ=E ˆ‡!´än=ÿ+dkÅ}Œ$ }y×uN® ŸÌ H˜’(\‰	bèÛ¶9w«¸2ß)ñ8PÿH”ï˜AÕİàÿ¡ë{–öÁı
=ëÂ9ÂãCÏ?oùó~Ë  òI¾åß¶œ×[r•¬ Úü¤ãÄi‡ºH/c#|’Ê$aÂ£\£Zá`GæÒÅ‘`84•],3^lĞÜªºVyÌE¦éO,QÏ&Â¬îö[—•Ì-1ÅäQç\@Ä})öÖ1u«
„ºL«k°S”‰_ëƒ‰øE×¥MäwÌzŒ«ñµ+ v§¡ÅÚ¨íÙx¨».kr÷õç¦Tå·§S5=¾síS¤&w4›3Ò' ñ¿- ÷aQ<ƒÎuWÙüä•ïßqñ;LŸú®‰Ğ%ØöÊg6ÜÕH³«³rñó†S²¦r·Ã,¤|ŞR¢êÆiã¿Ï(«P—692PAPlÖÅ£Âæï¸õÒ§ Lš»RX½<Dê’Önø±Şq[¥qå6…	wR­M%³ÚB§Ù^©KPÑáx¶G¸\…òFƒ7”¶D•¢ÉŒ%
õõRšÿãà‘—»'=s€¹tTQÆ„ç$Ì÷éáı3õd­êÅ7ßBhÒµ^–91ÊÇ¸ ¹™K`ÎŞ¦,ÁÌıË,Fº<~ó}!é‚RgŸİÎ²"æş~ÉÑÆß*ƒ6XËâ…¯O°x”«„R"-Ôî·I1Õ8Ú Oø.+Qœhâ;©õßd\·wùìÍ{» O8ûEàÅ}Ÿ ×yëÀã¢V&©Ô”â+·ˆp«dø0ä‡ÅªiµJ˜ûH ÀMg5õ®,†úg{¾%ò, k(œ¥jëDl¸Z“øèjß(‰ÙçRŸšß0>ĞRQ(ÒœìKhÊŞœ â\mXø˜aĞ(»x—˜àä$ZÀ|4X¿ÌzÍö“÷°Ò‹,,ò½(ûüÔEĞĞlÂÃE\¼?¹ÚDôÑcz;.‹±mrÀÓ÷¹i;”*Ú•®T›XõHudZ}1‹IÇ§Ù³±…çX\¨­„n€Œ"½·”ÏÚºÅªâ¨¦Aˆ0†[³i9û‰’ëd:1÷öRMJ…Z=<*ä(„Œ0FÏ‘Öı‹”;÷6!Á¯&½£­ß~X~÷Íñ»ğ—š.C†+]>ŠWÈ¥û±É8ÖZcL)‚ÈgZO¤[¼ûØ,HN™°aWÒJœß5|z/“µÏrøVO@>KÇÓò]ÀvÙÅN_H)Â©"'¿Ü¼ö^)ê96Ì?-@t­ZÄQı|dŠCHbb8´•˜$›K6ĞTÊ•Í¼¥o.…Â˜*“#ä¡9‹¨Æéìf òœÿˆ”.î~@ùu?à¾Ç	•ë<	ö,•0³J·õ^öœdíøWZ¬¡wZ|$zA“c˜§+D”+S[îì.Âanr8_ğù2|ó×C®b|#¿-ÍšH'dOíMWÿ”ŠåNÂ˜‚h¹èƒªû&dŸ÷ë·9™7v|ï\‰3Íæ7…DÄù…g±6„VU«KQ^H™lê»o8µÆ+¤ô^±ò²èÍÛœ$4&ëóğÿÂ%;ìÙ ÇÜ

:Ï_
b,h!R½±˜uöJÏ³€u²hfvJ‰+½_&sbÎ|^)™Rm:
‹&Âğ_ß‘?%Iæ|Å:ÏÆ&K•½B\»q´Ÿ˜"KöÙ«[Ü6§òªi°Ÿ
RõÿÆâÆ»b](EtåTKYÚYïs—`ÑÏÉÒfOÃIOÕ5«üEÒ4ÂXÔ¬Cğê¡VxëÍ¸"ªG2È2‘$FàRÕ#ãOü£ºşsT¡
±Ù/:Õ¤%İôW^+9ƒ ÷ª7œ]ÂU\%¯N2ĞÈ5œô¹ÍsµGeÇ:-Àù-é·w,â\?Ó ,ù ‘Si²qŠmó£šdğ™£7µë’'á?@ÓÔÓÔ7X€_ãcbêºßsCkµ…±÷5%u/r2t?-³R™aÆé+sycw/Øïıå}t>´L*–YøIÙoj‘69¬Íï‘ï¹Ğ)xvƒò…È+¤~’İ”È‚ko"Z­ZV‡s%¾?œ.^Œág†<“€¼á!µ‡øç /“ÓaîáƒŞ¯ên"õ€–ŞpÇ[n§Mâ¤¥è°ı¤ğ±ó[—Qd2‚Å©{óÙ…NV¶[gËÄ|)dÃór/…Ğñ7Z~É‘ø¹5GUÊ)µ*Šs}/'Õ•SÁE]zèp†óé…Rñ‰È×•³8bzQ‡Sq¢P/–ßˆo¶‘¡C1=ãöÈˆıª¤˜·Œœ
…ÒüÚ_³8o¸uóÕuÇeœ6wÛà÷‚Œ@\~¡¦QúÔœq{›DIX¨m¦z1’s<<>èªd:o} ñ®<¥³øU¯z6†D+i×ey^¤î©h–§²º=aÿûaTñÙvìhZä¦0JÑ’õ‹Ñ¢¾¿Ì@ËˆÒÓÆıf:Èš5!ºõ®\PCx#_ÕVæ´C¼éÖM¾ÍTL5æŠJà'â‚’ õ¶¨¹‘‹S¼ÏÀÏpˆ¤ğ=}q`îàÓáVû›yñjë#ƒ‹d´<‰Í²&iÇ 02ÎÉà¸N)sŸ¹:ÛşÂÀŠBN¦«^­}wÅX ö;b £ˆÇ‚Åê,gìmÒûÈŠ¹÷•g¬l^]oàz¦ÑRÙ¤!ëŒõ
±2mÑ‹ğÇ¸wnÊÖ…tğøı¹5IÎ¿xè'‡¡’“œ^XúS}@‹A®Çæßê…Ù,üû˜ğh›¬ìêeb‚t?”güúq¯¥ŒÓ_rùË§ŞŒ7ìÛ,VrhÉ^áùO˜«•€œ5#V=O¿ŠWaï]»¬L²mtˆ±vœ×ãÇÉSØ“+tÂtâ8FBá.zÅêp"ş^ˆ{–‰—ùfğ<‰®…‡/Ø«÷˜>Ÿa¬Í9Ç7£ù|8vŞÏó6´ ÓàTå<B-vª ÜßtKJöÔn,£`Ç¶VKû³$ÙC†çÂLØ®´la÷ÿx–`…*¿ÈÅ$@Ó‰CÉn“döµ¦Jƒyô)gİÔAtºpª·{qFë<g,^6ÔaEéíÒ†OXá‚Ğ¡3œHO,0·i(l¿_a•r)®`ú1„'DPw°~õAiÇ(ˆgëıÛ©>ÊÕ,Jp†®µvTfCníßÒØÇÂ_×ww@ÿ.K¬
¥Ìy7b¹7øEæ×P(gìo1ì:‹<Sí™Å­¿ğ 
 ¡©¶Áû«ıÜBÔ)T¸*ÁP†áïêˆ„›ñ3³ÕCªVAU‰Æ´·z¥$ş6•›«‡–DşedººÓT®äj½Ò=¼ëJ’ù‡şÆøZ>Å…w5ç¡”síö[Ù@Ó•,?°)k£®"à`°YÅÈ›Á‘–Umá$b7TºSàİØr!+¢ş«f	TŠèÓ8š[)Luäfó•œä&•$¡±.vCŞÉƒ8Vx¼sâza:†›¸?¤êœ±£Ş5üüUñ«×% øV²[ º¤Ì'­jÂ~÷‚íÌÉÃ§Y^QHòÇãE¹Èm¬³·˜º‚ÈŞ¦dì ¡~§Ú([q<Lõú™¼lÇ&™Â'«Q¤HäŒHÌˆ°<®}nİ©/xæ­¶ÿñÑ%ˆVƒ] ˜EÑ§cÌT¢an4Jı®ñi½1XåNH¶Æu¢Ù›:ö¯şTƒ¨ée©n³²×—mâú–†Ót¾ï;µ{Ç?Wm`2EàP¾œÈÀÿzEê^X–lÑfd©À%-ùu«Ò>ÁeÚ9Õ	F^ÒÁüÛŠc	`q«/UöÆÌ™Q¸b[Ì	Ák-RÂµƒå/–¶[«eÉ=ÿ’şï ”kxåß~¡w·šòDYI€í”’ÁÈçÿ#v>˜E0÷£ÎæåKP¬)¿õ°ïÀƒé˜åÃÏ
¶ô±+f’º(á’Œ5põrç^Ón#>ƒ(`œPô¨æpèPàıfDø$áŸrDk862¢èHIMâOGü¤ø ?ÿşm¬q<cÃ.“rK¬<øˆÖ€,İ‚ª~wênÿõ[oÔ×Á_)õñF—VÊYfd‡GÌĞ¹7šÿ\Tÿ9.Yõ›r"/7èé˜û…“÷{V¨4’ñl$}q¾/¯ªè¹zdı!>óÛ;çšˆ·Ú4Ï˜ı>¾´LÕ gŸµø æÎÖçÀ¿ xš­°¸ùöƒÊBg:Ê5Ì*Ø/Ê%×Ñ§«pØuB%•â,39Ì‚ÿ©Æ˜€o…M'èìwü»¤]å­ì}š{PŸ=·š1]3«éõ]¸Ÿ¤›Ğ{U”×h©ğ`AŒ†Ò¡˜› ÎàFI§Ÿ"Ú$„”.Öe8/µ‚²(më‰˜Nç š3¤pgçe;ı!²Mú±øÕzãaÏµƒu!(`Ñj(Šñòğ;z7B»à`(',\ö¶‘µEœvÌë2Æ`”È¨Ù±ĞxB\²ur†+ì½Ñ¬ä‡-±øÃ’3gXö¹>Ù0êş?â†ê0Ë3šáÆz/»œ¬Âµ(á“ú#âCínóüd“šje"šëhpcxLÄÅÿ²üH+V·’±¨ÑÎ\ëÄ@¨«¨®‘zj=Ò¨–[p…È©¼ù“†pdËwG÷…$E³û‚ÖbWşïµïcqşöå¸°[•cĞ˜$¶o{úËP‡ò´tsg	¦_[¼j²e¥í!0½®§^_0ê"F és0r¤Õ¥ Í¿[b<ğx'/¦²Âx§~/¿éÉH~øöÇ%ãHø	¾}ş;×	PN=un!"µ8j¯¯5‹Èû0Ú^=Ò¬>¾3tÂÁc£ulod
í™íA45B‹Ú™ í˜Á1i€Y°>ş`	FÈï@Ú_Á¿Òø¢êÁäwO%˜Å;”‘ û…£ĞĞ 4I8O¨ .ĞŠCwã
A mB­®Õkùğ®Ë ØàFø|ÌÃÚ7Wª‚‰V#mÓaÇ_œxÔñR[\¨Ë¯=.£Øß9<!‰w9Îbïa­‘ox­Ÿ’v˜ç¦nŒ{5/	¥#ÇºÄ'm@Êœp\`8qƒvŒ*˜äãUhXó:bÒ]½×ÅË&–ït6æR7ntO†Š€„½ß¬Î72xÚ°œS†!reÉ0É1òH0î^Q‡~«’ˆìxjúÁ¿Ég¥%ÁÍ-I½«HdæM¦lz=·Óo\h/ƒ½Ö$÷jU©ìşÅÔŞ–ßëe`N©LY¥:…Øg€êëÈıßd«bOŒèP(°Ëa3’¤°4Ë´ØÍëò€2¢ßÈ.bSƒ¥5}—wÍ9»>{ä°Öª!v?vÏÆ93ŠIPÊIÈkE°ƒØò÷ªE€ï(^	aBr¶“H¢sÂ3–h¶Dqÿ*ŠšX«—%|Şà)Ÿœ”<ÍDWí™³˜Ø±»àĞÖ¹ŠsG½=[îtÁúìÊë8çu*È{³¦kB…DEf7«Ó³ó55{\š˜oDâXáùQpûmÃüÙJº?‹V‰îLçUÓíä 6N˜Pu«Ù‡Ø-õ&”Ö%Äk?}ÃÚß„ŞJD9 °eOÅéc®zYşïNOÔ²r©õ‚[a‹yƒmºùÇf¾;#XäÈt:ÊAŒ_ìL(7œcÚ³xEñöÍRÒœé8Šo½èDÛ lÑ×˜¤„ïbì7=’ÌõÔ·2Ózò¯(ès Ì“ge]-¼„IN®*B[ÃIC|a—x¥û‚1+®e_Æáxîfzú”õ"…}ÚÅ™ÃÈĞÆ= Ç^ñìdãSÔÁvI_;İ¨ÓF;á={Ìâ|˜ûä6ç nGg0ÌEmçæ('ÿ¬&“ÿöµcƒ‘€Ä¼í¼u˜2×­².  çô!;«m“3}K´1uâ¦Úş!l¬œÇš‡î£¸Ä¢A’^ÛHoËctÚ+ÕVÛ¼§æUÀºÑPå¦I,hq³–Çaïå•OW¢ú¤<XjàİÖ³®Á8*l a?§_Ü®RH¹êÌ"VÃµÒ_I¿ı·Pğ¨7WvœÙ¨ˆÓOÏˆ¤,­ó@®Ÿeº<[nWÃï8šL³ãŒ RPb¡–.mIÍ³?üP/{œıêĞ:ÙâX=§ñ°Sf‹oX¿òYZY2á¦µºñ(Pm4;½ÕºË»íø¨Ş›€ +±#7›–6‘{¢ï3tX9++w9œ÷ÃıÇ.±™ òKU1¿×ô~rí^P.gb’ş×@¾VåyŒœ+&ÔÜ­)—BÚ²	±zÒOç5À—f`ÎáïUÏöe“ºšŸ‹JâÇĞ^£Œ½İ¯„m+M-’¨4cõ;‹qâK\~J|9‘¸m=¸VÅV9Ø“/¼ˆQdqõíCª¦	6/V#şzü¤¼ıeQÖé}zmãOZ@©¶„µMÌŞµC„y[VÁ–¹Ö˜K}V-Ÿ³ï;£ª}`Mqã¿ ã1qÀ,I¯áº‘vo´E³‹ÿ7š½]#b­!'µm"LøHDÄ…WN+™Ü[ÆM„©+À ğBTn Ï¾í*ÿâ¶TÖP_Y]@¿,ŸªùMb‡üÏÎÁæ’(8V.õÂ3ªJ²SÔË›†síó!¹aTd~mn7ì;IÃb1öFf·¯>ŒeŠ_¢vl
¶[€ZÉp/ëB~ªê­K§î-ˆlA‘×Åt¶V	•r¬’UŠÆG[†âÎOVÉ:„ÿş'ŠX©>Fß…¸Ë™'»fßÙ†aë-Ê®¶,€Û"ş„òÔ“|î¦bVùÉÃj¶Ï¼cîc‡°;‚Qe}ÆÜÙÖ–ciÿgÇOï!1™móÓ>PVÙå™Í&(Œ9ú áÔÌ[ög3dgÉ˜ÍôîE1H|!L”‰	¶xôõ÷ªßÄŒ%œ½è˜(¥O9hEçlƒ
)h,Ûò)¾±?ñÍ¯BI£wH^?ü‡K{1Ùãš8¨ˆZsì`v Y§Ö™ ~d ‹@ù,täæÜ ƒœşĞ¶°ø?ÀNoïïÑ"kÂY¶İşîÈN}	h¶3=Ha¹õ9w_fD/L¾l6P°>üoÊ‘®òÒ¸:òú^hÒQ=û¸—‹ì¤$Å±ºéò1*NM÷Io³†KtÁ®È5)Ÿy9|§l›06^ÚêHX¬cçÕP)L];J™2é{#ê\3|»8^²oTƒ·œ‘Ys(wG¢?D§ÁˆL97İë°€"BT;gä‘„×CUÛRrâÅ>Ã!of® ´ŞÜååî°A3ø„/·>ñ¬Ëb'‘¼ÊºøŸî…Tå–?h‡(;”2uNêEjc±¼£†ğ©Hò˜\k’”ßâå&jCáòy.bgA3®Dõ2Úæİ¦Y8Èø­ÏlßÂ„óÍp¤å+Ûl]w£‹×”#¤ÒÇ›M´±ŠqŞw²ÏbJ[³¬¨HÅcKC}IHÛÍ'æ§RL:ƒzÕVh²0G·¡ì$Aağÿõ²'3<‹ó•ÿDÔ›(şd”?ü•4wR­ÍÄ€‘À†I2 ^.¼¶+ƒÌ*™„Ø pÙì‚GpHk'š¢N¸”ãiEøŠóàS®»«ÇqÀ#ŠAÁJ+¾‹7C:2µâ÷mşŠ©uK2Ï ¦f½ş z*É]2½1°ôŒÖFôàª:â§¢|N+[^J±´`Õ[e–®%ë½['„ïMsb=“vNíç™íâj²Å­§[üœcÂ7îÜ‚šŠ¾Tš14ºæ­°Å*i/1ÉŒ*e=[ÜÜØhŸ«àAänçë—•G÷äzö.WõF{üé!rÌ5Ğåaê†¦­GòŠGd54GéÌZU_ñD^±@ÃÍÙcnğn¹·ˆU=Ht±dáB.d¨ÿ¬˜ÏK…ŒüÄbğÀşu”9`½ŒJ/"¼Àk·ÚÁP–ó€Ïò»16–³^“bóê›O¿Ùœ§
X*øØg¸ÜÑµ7CjÇªäô^_ª§v9Aä:' ¯õ>	[y´ò/„bşö×Êhf³Š»N±kø‡ÈµQµÖR9ÎÈ‹.¼i–ò»Ñ‚
ÈXÆÎ¹ÂDãhtôä	ıÒĞG`)%8ÃœŞb8Å
Ô;y½7(Í{ÒÓ0I„ƒ~Ë·ym	çWÀİÛ„vˆÜÊÊ¼4m¤ê³¶0gA¡°¾›¹JR:yH¯ùè6~
İšúİ‰FZD¼ƒ°>'DÁW¾².¾ƒİWßá­aÒ|é&ıÖ-&SÏ-Ã"Ã¢èM/Ø¥%ôè†¹<Ô§6ø–u¨ôîÙ©ÿ?MFAÓ4µõa‰GØ­”ûjÊñ xT~ƒ-ï••nQ9zÚŸE_-}ˆ,ëßI‹Í(ŞaËš#$6¨•´F£&<æË!/î¦—ğğ¯+ H¬…Ê”¿˜|9p¼’êA†Ói#Îşõ‹
ZˆÚ’Ú]'¼³b0“’Ìà3¤WÃñ_Îq2Ğç¬’l?Qµ­f´	Qdô{|¼”³ús'iæ¤'äüDÊ²AÒxÎ)DØ?Ôd³®Azì¾«å¥imêiËÏÎh˜7úñ"ä»3ıg5û'ïÈ¯Éşÿi×Æ°çZ·ÕöKœõD—%´2ËØß,FˆONå¾€e|Øæxôì˜}6Şg$î©ùÕMÌù@êã‰ŠnŸÈÑÌšÓ^ƒ	š˜Ø“Ú›íÊ ìt:(ÄiÏ1á@‘¢İ?§ÓM²ÜN3	8Ù"´†¤½ƒa8é<	«~ş<ßPÚä¼Û{^³;Ò˜Eß7n„wH×ÅË«ÿÉ{eÈxJKËA´*â3™&º‡èÙºz®¼Lå ïÔ‰/¥ø‚ƒò´`Ñ‰S R‚KÓÒ£Rœ,šê*q‹lúéá. Ûğ_¸ö°ïV½/†W#‚eà³ô]Â0•7HzYW?Ù‹ƒşqœ;jqòÔ:æï¢JÃúa,rı“©Lu1<uÛ!¿lºŸèâ“v®5,· ûvÄ[^Cãö¼\Ş–+á&§?é-ĞbWR;mÌşç®1|ËŞêÇ+ÿÂ!»«yázÖIâÿŒÉL\èNKTq±š9 øŞ“ãç©ÛÎ0ÃÓÜ‰I¸àÌäcÁgî±ˆBPIQÌ#³Ú]y¿¼—è 8îA{‚ğqq”_7û¨<ò dpu>FíÍU-‹/4ôjô`bPOŠLTc¨{G(2¨p¡ÈÊù[ælÑ—àÅwõ.ß.ŸY¬5pê>&wlY”Û¹Ü@gÍRBbû-]×ïÀ7ø_İ$H\|ÔKH+wq#odD»|ÎñÏàR9k6bƒaYsí)f‚Tï|¼LjRŠÌX›J'–¡QÀˆwäò±ÌÊÕ¸ü-vkÓywàt1©Â¯Ø¾¼ùÃ÷VÊs¿/œ¨‚Ø.ìÔÇºœyÒ¨ŞIÚ’éfÍ:f¡ˆ½mŠ&&Ã3MÌÁoæÎÑ.•N~·+ë°Ó‘ÑÁÑß¿$Uç5Dî“}	Æ/uõj¸ ¥¸"¶1Wx2j–Ë|˜½4©:2èêİ¶µ¬½ú÷¶RÀ?¶ø/	[}Ù˜ï‚…• Ûô—”q²);šPÈég Ybî!Ij¤ÍÎƒäĞ¿ü}‘î†Ò¾@2ä”²&Öåºèµû˜©å «*¬o/¢Dˆô0İi[º    ¢†€R
ï' åÉ€‹ªÊG±Ägû    YZ