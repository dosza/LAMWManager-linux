#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2665104784"
MD5="3463f1ddc9b40287c94bb00e596a267d"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="24976"
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
	echo Uncompressed size: 180 KB
	echo Compression: xz
	echo Date of packaging: Tue Nov 23 01:27:23 -03 2021
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
	echo OLDUSIZE=180
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
	MS_Printf "About to extract 180 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 180; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (180 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáßÿaM] ¼}•À1Dd]‡Á›PætİFÎ&ÆhÃ‡>&x ƒü›$•c*î†ÕZjŒ-T_O_n”¿«æŸb8n˜çZlÌõ c?òŠ²G_]T}ÔÇs†…çõ¢îĞLĞå“5[ÄçàM'r’½¤ÍJ¥ >Zt´1ô/g/ONç°­P/ÎÔâ¥E'Œ6:zR‰GäŸ&àõÎ mÎzÏfq>³©†:¹2Ä£†u‚}æ°µ¨M,0Õ)îÀÍgh>^3Éöò…5¸@‡Ê£ÙUõ&B,{‚àgñÂçÿÚ2é:¨ÎA.X¨Æà1çğiÈ¥"è™ù‚âP¿R•®é~ ·½ükD90`À«0Ñwn½Ü3vw’ÄNxÇgÎñ€Í:g»YöÜğ‘ù·a†«3¨M¬rå ì1UptX={òáN9×³ Ü`´>ÌÏHÔcJ¦ä¨1làÈº8ì ~M¸ò|AÓÂß2*÷x³ ÏùüçÄé±´C  1®¾F{îI¸êÒ õŞe5êÀ¹!´ô|ƒ(×¶ı¶jáàQÄ±i¤ªLªU¥ÅÉŸ…Ç!0üŞÆ*Å­Ú¦€±v²	Îp	ê\O†òkm˜@¦ÃzúwXSÂ¸²ú§[8e§”}Ç¯:pjñÅ¦> ],ÙG–BT)SZ…Æ¤rÉ!x¥\©Yw‘†›ÀŞ¦&µ	“’lGò¨È¡–TÛ×³‰*0Y”´ür«#Üx­lÁ\'‘ŒñM¸CÒÕK÷ı¾ëìD\qsû0D÷U27ı]ğµTºE±9e½1íOåmğ_[Ç÷è‹Cr’ÿ|n+Ÿå–rÀyÀTøó}•I`oÃÎ8tHG[Å±î•5@83ÜÚ´P¬îXXaú™A®ÛİÔ˜gFt =´
v2ãäÖUÚÅÅX-lè(êÚstŞêşôƒÀñG[xååŞÛÛµoyû"öÒ÷7ê~è$wÖ`d“pQÏñ@Ol7gñû°¢àZRóVğ™Şà!)íî–*'ºS»PŞQ08Ş2G2TÉüõlrºfïñ® ™Èüãø0çíÎì³{ĞÖ%ŒV>˜¶-}”M[øù?w/˜O‰*†hÿ°–»L6G/`dóAxXÃh¦mÅ© bä1'7…öh(Æ| ˜H~wKùW­.u¹Õ_TŒÔAñ¥<„¨I¤„(K†D‹a 8¬É‚x+7_;ò„yğMûçiæsfÓÂÒÆÕÔ£[­úòÉfQÜI`İVmW©Û7ì5Ÿ³-­aZm»Şˆ¯™ê#³bGÑBu­Õ³S¶ü/6W¹ùŒ†æ¾‹çÖ;¤É§”ÿıÖPWFÜgÛ »¦ Æ‚ÙÃ=Ö<©?öe.7ÊŞ´5„'è&îZ>k¾xÃÿ§Â²ÏEw<ÌnJÉ»@İÀw¼bùV*DŒ JVnxÛM™Ï¬ñcHRú¡ô%EPp¹§I|ª Ò¢qd“KİºÜ<©0ÒÁÂÌ<†çÒÂH.Ô­©ïL(4JğË¥W‡ˆX“G•»Bhw`xxd­ë–V0¦?{Æqj%MDPj­™•¸Û ò ’påò®ñ×T.ÌE ”Ç4Ãq¬+q¡pRº84ÜÚ‹1kÓ2ó†ÆE¾†¬åpƒ=FÇtA–y^3şÅÏP+©â³Ë$ŞÔïQA^•¥ZûÖĞM·Òv¶YKB#×òÙoéúÛ‘A]ŠˆÕ)j¯Êü•áø„ı«¦¾umÊîÇÖ™‰Ük%æi¡Æ'Yz zŸúê¡À~V9ÛÉª‹[ª‹¸OŸ§¥¾ìVÔ@ü·™J	†«_w°BË ½ÕT-*b­ÃafúAH›ó£VÉæ˜<7Ê}²éÁ©Bo³ıXC }½Çxöìâè+£BÃÿ@\bùœ–¾´EæRClĞÿW€§®^rÒy1ÄÔ˜0_‰¢Sˆxîƒ›zÙÎMYÂÊ¼;)B‰K…#%FÉãeÆ<Î0‚FÍú÷„qIwá'|ˆyºœ9ÀTÎ@ÀsU`áâÊ@¦’ş_ù ‹›ÈöRĞ¦ğBYò.…U(âï&6È¡Ëò6]œíüW1_—ŒßUÅ¥×NÜ¾‚óQ/I;ú²
e•pš(cµ™öóU„ËÎ‚³¤õu]\±©•oõ&Áüƒç—´Yéu!*6 xC3MáŸæ
_ËpUí›f¦âsl–Ò*„Á}²çßv²Sás2Ê^$§2êr¢7ò!¡EW
mˆÏD^&pXéœ§Ó`¸’2`"¥Æ¦¹ÍÜÛ‰HL¹4A·_nÓbkl:Ò(ñDÏLC§]Ü¨ÔEVİ£´n¼J½u—ïÅŸïüÃæ»jÜØ:NSmEÑjS¶³şiaÁ[u‘õÓãÓ“‘@ sû‰%Î£—€J/­5ü±ñ«ÇSeåÒe§[ó‘ä[#’ĞıéìÀ]¨½ÓÛ2Ù…__(µ/V.š.ˆLİŸÅ
‚Ñ‡ÉœoÚT­jü ™Wêëß®Í
¦FTDPÓxÅ9ÓÃD‚•˜1ÕDÓøÿÂ¡Yš-˜EwéXæ®’8é¸Á±´¹E=_x>OÛ…“1LæÜI/~ê‹Î¦ÔÂäDjBØ¡`¬)kÍ´àä_`sÒCÂ—Öf?UûĞx‡0¢‰K‹ODëo¾ÒÍŸ ¥¬dµÅáÂªtOu†U¦ Z&G(Úr# _DhÅ>§»Oƒf½öĞÃSÑ>èXÕï¿*Xoôî‡´×y¢em„ºvG¿¦/šÇ	ù÷Ío2™ÑóÜ„p·Œ«EòÓÁ5ÇÏÉ}µµşTåRX…×r	t×›îÜÙ£¦®¹5»Q¶Nğè§ÇEwæÙn|Wr²x?İ@µµßpÊ²E¤,(â#aÇZè˜„ÃSƒ†9öºøËŸŒtÆP¸CN,”,"¢Aqğ¨ÂÄv„D¾£éùìİÔ¤1?G~ü^YĞRj]ØHá¾äı-²I—OiÉÇ_BUQ¥©+
Dv1%¯[Gú Ü)Qª‹+À'öé
w2nO„½al—¤~ÓQ—U#NÂ­V†¼oRx0•Ú¯CŠÖv-vÍ¡ı,…í§”.Ôó€9A
¹Ğu¢ãt4Âv¾€C¿Rï÷~r|dx£mk'€©TELÿ­J9vóŞqYX?”{:êíì¤<«ıËOª@ø›çS9YæÇ1õU]Yl©À`à³ŒVJ_záï¢™¨¬Û7l£ÏÄÎpK§SFˆj‰ÎôÜ«I~™.ßãØÏuMÛSy9?:v7è*%ö´w@ôüğ9À9µ×‰öËOïÀ·©ÈÖEŸhMPÕ›"¤—áÀ*dÑ(BgõÁ´Í´öÂ,ÎfàÌì4aï®¹·|¾‡¼ò+¦øóêõÛÌ6Q<ûo0öúÙ;¦.$BasUKâË—ı_ˆk;Tã}ó
@N™î½šPªïak*RN
”cğéá¡°ûäIåÈ5ÌÇK{h÷˜-áú¡ø<£ÓbA…,m.‘R’a*6!ƒí.¸ÌBC!Iqt0¥Wëƒuu~Ø_¥…·T€ìÎX0ÖÌ±•Ò=©Z/¼NMhz¤Ï–îi­oşÏî	ÖÅÌÁğ&"ŒGÛ†ÕÓ\SBÙÌ‰†¤lô¯K`ˆ =âfÁE§:W·oÚ4ƒßdÀñg÷\p„F\ò’Œ@à]YÚwCv•–†oOÒlÅ¤go¢ıËùÅÃ!S¤ºÒÕI'3 ßÓÊµiECçôEîã8ÿ$ÑtâJæ§Ü÷ŒU”|Ã¦t¯Ä¬Ü'”•^šÏåÇeÖf
KP½ÛÂŒ_fv×ÎÉR¦1]ë¬¢ËˆY@–oû«‰©‚‚›µR£º7Õ™RŒº÷¨®“f#_ºiÍ3|åd<ÈO…“:h	\DeôÕ¥+~!ã ŠÚşËğ1êšoµÙ,Æö©¨ÔÆ™L–ìƒ½!üsCStosY…N®GÄ%	S`¬øgî	S°¡ã:&¢†gçYÏÍ¯T|šlŠºR¾}úÍ#R^ÅäÌOÙgû1«,ÆGViÔUœÖ†öÊRÆjŠ•47Ô9À¸±l¡¦nlÑØˆ‰mœÂ?7RÕéıÙÑz?Èjb˜îİ½`Éàß‘¼ÿ§U(Ìíw€ş¬
ìˆr+i°õ@èu¬#ÓOPîšÊ„(¢Á ÀU{(ÖG­?,ZJF¢(ï·}öËŒß•Î”ÚÈ°Í_W¤â…%+lãÉäí(yLx\NâûlN÷hJÊyË”7ŸüÊÑh2 öl‘hçÎ!‘Ã>Í,åSP¹0õ¨D¤±>¨¹,Èó2Õ•@ª¹4øq®«ĞÌä5Û²E[°HP²Èa˜ğ=¾3¶¸µ.’Ã°Z;Û—ZMòoátüQÑ ˆ!Æ75K{JZÚgo·ÉüBÔA’hjCÀéív»=ş¤Ğòô³ÛºÚ‘áz¨h(ÛKó1ä“ù®>·:Ã$|Z„¯ÇîŠUÊél¬™ë“¢••öI`µi o¯·:slaüÅ_‘D³¨øŠËˆóÅnËŠv­ŸÑ†m±Pp‚7>¸(jĞM …ˆ—™à$uŠ‘:&rJ
ã¬F]nrªŒ½KkÂÊ:h’Şj‚Ñ@ö˜j}Ã”ÅJ¼wŞó~½(¡ö²ZÒé	ùã°Ãğ­¦.ù[J¢lùÃ ’Ä£2! ò£*'&±x²K…İBÔ¶Jÿ“×Ñô‰¡e;6’û!ûqgZ×ßm‡Šg;Ú—RıEìµñæòˆoúöTçç=ıä%¼i\Áœóòe?îTğÄ–¤YAšÿíÏj#ÃŞ‹•J§$©€_\³_ó™Q7¯9bµ5İêSk_ĞÏ¥,±ıF ™^AÅëéµtD9óÏ¤hr3úÑ’RVìzËû2Í ÎøÁloßş«|ñI	¦k°Í5/…ğÙ÷·:ÚãGûzÎès:0á)è¹–TÇtşÔ}¹Ò;)-w‚ZmeK7ğˆ/àõa/W<–8¿Ö6ã¼ç•hPı–Ş°ÎÛNoIlwØéBD²é½”5fJµÒ”Ö9®*Ø)Æq~ó —Æa&fç”³ˆÈÃÛh‡!KßNÍÕ²Úªç·š¾ÍRf±CN•–zğèOÑ(i feNŠz¨Î;­è9™)h¬›iãıpVƒqzM=½Ú¸çééfF^jç¡‚şŒ‚yšˆÍœ‚úyê jÁã|^#ô•eA[xßìkëŠx)i"ò%ı}ñööÖUm-6¢	(+<|«ôzGÏ²AŠñ ™w@ò§¸Î“­D–´Še5Z’#BZ1¢xòÔ›ƒYÚIr§]†éQX2?.yÂã?»wmT'¶;k¿ªÄ=4§†Vş°3âC³§é/µU! K‘ÇÓg7s$…mf¶¡*!•ŒAÕ–ë¥9À ­ğÅÃÄ>šƒD<µŠ¨ ÃşÙª#šÚ ‡í•X#e0R¶ËüEÁÑù‘˜¾s—ºE†åÊì9nBé€4ûpÔÖ¤üúOFw*K7µ·ÄóÕÑüUk&U÷ìÜ¢¡»ÃvÏ>f–ØÄf¿\ÿ8‹;t~—ÛL2‡#£˜ŞC©g„kËtÈ7Nw>ÖF\ ¨vN2…Öa`Î@OkõK@vGáÂOÔü°¾¡64 §5¥İvèôõ4}g™c{q°}%>ØÀ<©î‰0¨]½n—íšvPE†,éZİ”š3S®Êm…¿Éî?.ùLFa©ĞpŞÊ+®øäyği×‡ğÈ õÊÛñXÉLAë‡²5á¯"næ,µ'7å£É5†ÑTQÆ˜è9X‡µF ½
Ø‚­auŠkİ$Ã#¶øT£s˜F`.l~$ÍĞÊh£ĞgS?¼Ç37’¿P·«J,°ğI4UÅÊeL‹m1æå;,@ÂÖGQ›ÏìÂ[¬İÙ3x]¶n]D¡6á!O©ŒSY/hLãC”1©ÇüS#°ú£‚£Åkà¢Ù}v2•.fÿŒç\¿øBN‘§'ù°~øıÇO×éû¸FY>(6>S&JÏTo|ø—ìJl“˜p–õJX85'û–±Ø¡.‚
¡[ÕI8¥£¬TÆ,°3#ø‹C5àÊçùä¿ğ’‹Tàè§Í¡KpkyáÄ„2Ã“HÇ=Öàı{An;h7¼ŞˆõğŠ™ëYÙ˜³&14*òP3ù˜3¿°"~ZÜ'9ì¡²ï%TS2ÜŸ.³¥è|Ôél’ËÍı0,MÄ
äg%c¦ÑÊÃ~al%µGı#!ÎÈæ%¥û´×l˜*Ö9Í|ß-Ş!ö˜™xª³î”i}¨Ğå,#FDTÿAÄO³û·‹–Â ƒ.‘ÜA•Ãğd:ï!Ö#*¾KPL°áÊÖ¹À^àÄ~Í|·ŒcßşĞKªââ­rÿè"ÜOtßùˆFÙÏ7.FqãÇõä¿%PTC¢ØğëFU]0ÁxıÏjÌ?f7d#mvŞ!;}–§·=İSı#6¦=Îc¹…€÷ØˆdpKßĞûÏJèÜú=Ì§T_•DÁB’Œ	ßÁÆŞs4¾v5Mçâ¨³ŒñD95«àÂpQŠRÎs'Æ)ËàÚyP¸&òC¹u·ÖµeÎàQW²2ñzºQ²ƒ Š{&tÂÓÎê›2Æùiúº…WWë,(¶ä’wç©âÎA`ÿ±…Ïx‰ÁŸ?ñy¹ b6¨l4Óh‡µ¨èvI w˜v&–z×êóæ¡À;¶¯:â®ò½öG%ä£©È½ıÎê;<_ÙPt—Òè¾?ƒÄ0wù!ÁKĞ’/ŒE~˜RvÚÔŸí”Æ2«Å–Ô³{X¯I¶åPÔ@ÓqUíµÄ6¯}Á¬.Ö4‘}µ¿„BúÉ
ó£˜µ LQCçáÁ¾àb4‡ÅdÛĞ &‚…Ÿœæ¤¹¨ÿÖ„x*PF†Áb¾á05üá ¢­h^ øŞ}½â-"Iğ­²²z z6xÃ*Û$+ä€× töè¤jƒj QAa§»µjëÜYÍeÚ#Ôš[‘'
Vªñsu¼«Ü™+‘©ŒŸ“& RÄ°P²°^MØÅhl~²—aTf‡¸à+?À“Ş¨»uîã-A™~©qÔŒ¿,]MF@+ı›Ê§›@ŠÅV`»oØìÕ«6ŒÍ1õ[›ú‹ôÃwsâò^“-wÄ,.7›W	)ƒ§¥,wÂ¸9¿+>°Ì6KËçTä†3Š^+Ñòl•‚4«äázS€«™èá€UòëîÎØßõ¨Ãûc#lºNÕûO°»jp…È}§x?Û_¥‚ÑS¹ÊzËõ%ÁÑq¾c%WX{ï4¥9>L¼~%Ò‰‘8°µ‚/ãenzÛ¹÷§¿Eú
ñKöcë¾ãÙmÛ*c£ŠÃÈ°Œnwˆ|A¶¢Ió…F.ªô{éöÆğÊ›8–&ÖeÀ}şy“—ÜÏS&~áíw¶ÄíŒ6õ<VÇ¹öU€€ºÖ$¢bŠÈ/ïÎ•b„r´[-È­×Ê+-»¼Ûô,õâ!‰Hp¡ jY"€%øô0ëWD„¦#ì!ygÙw	¡,+µRJU¦«½Ù… #º§Ş£t«ps©IûÆöµìix8ş"ekøR„!®*¼(“ñ3º¹6ŠJp1¢Ûzx«Ğa	»ÓéóêJ#I*ÎƒQê2«Bİe¶©Ûåz0o¤DŞA ›GîêÊÄe¯œ1ãKf¼bË2z 'y[Ú(¼3P&ÒTİnÃq¬±ãìœŒ]€CD1zóØu“¦2Î°ãÒy¡+b6¿š¥ÙN<±­#µ;O·K0dbóB\Gœj{æbºoøi×Õ¼%Şwÿ<Võ‚é!c¥xù¥W““•nâCÌYù©5Ûs%æ›	t[÷Ó1ÚQ¿›C#àkt &X€!±$„‹+§ƒÈ„øbt}TG—gÜÏù‡¼vçÊŒ»¯q,ç–³PF·`>su"'Rı$¼DÃÉ ²nWìkd4	¼s¹–¯…*âÉ²÷a’¢vÏ˜{ıÂ“8{f9à²MHq®ƒ§û?ˆ•7Åší"ÖO ¡”óëÎ•¹0K›‰ÌAû«™Ùm~-”]™c” |¯Œ‘K1}ƒpS1¡ªŒ¾‹I.aÉ$ôŞD_e&JE3‡MßşÈÚØ¯·ùirñİ©/ô0œ§ôŞ0‰§Ï
Ÿ©÷Õ¾‘³ë·ÍÕ|İ4İ$:>ÉÉ0hyÅ…‰0i#xXyİ¿¿lŸ’¯b²ºe{@¦RåÛs­	Å´ª.£Ÿ›×ÜC¿
Ğú˜´ü>Ğ¡´,CÔ­pÆûÀõ¢#ô{ù€ì”˜G€àR‰¸•‘ö•ÃyÃ†CßäÉø´­s@GˆprŒªO#x@G	]6‡ îò`>bE^Ò¦–ç²c__3È‚¸¯%Y©!"°¿I“íq pEéP¤c[)Î=:L«Ü¢œNA™©6rÜS•ñCİ'/`,ße÷¥QéKWTÀ`¦5 ‡Jp9÷ÀkoqÆÚï‹¦ Q0ı"aˆÁeÓ¥iâ›|i?)ä„!á¾Â@ømÜ#ì} Z%óUa—´}R©v–·èJá{½~$÷+-µ¢\y»nŞ‹ÁNhqÒ‚¦¤ÿc^™Mˆ?{5¨^=¯§@˜ÕæÍ½4„’ÀôíÊú^= (2x—qÔO,I(}éL÷
…Ö  0C²÷zùûäÍ	.cÎÑ<¢f®²ükÄUÈÅ¦'h‚·•ŞŞÑäiÅÊ…vè…•¸ı_.3
ë¦ÚV¡[ Ğ{{
ë˜v§B2!;B7Bî6¡¼hQtF*:íRw+KIëÙµ¢''nc±Në	Ã‹„|=¦–÷·Œñk%™18ÃS Şãßù¡ÚŞ“¬úçÏÒó(pm¡Vùú´ïô½Ôæà¶·<rÈz —™ó±Íõ&O}Qø•õÖ›7›® ÖÇs¸¨È£³!AG:«ıOÿñé˜ÊÙV]˜_Kà¡FÇüR¢Ín±,ÖFğ†Pn^ï9?±ğCğúK’„‡¾_&+dıhœÂa.eyUº_ç?­“åÎÛbÉ_ª÷@°¥oæ”v18HF³˜©JÍ,&BKqVcÏs°ÃlŞªÙE?sr8AôïçCü‡`œPÑ¬ŸçÉÜš	<lnÊy^ŒT÷ò1å¯Ö/ç:À/¤œf<îe#t©\çÊäĞ1c^‰´W©ûÈ6›mqşº©–æì¶Ù×_É(³bø‚œ=¡ÿ…‡Öœ•nkÙ¶œğB6¯à[È2‹î*iŒ±¬UÔj ©A™mçZ©Äÿ$v:‰†m{Ìù†C^ í¦1äô–®ò4™Ò…ñŞÍÑáGÖœ‘,bp*Q‚IyE—U ÔMÓ0Ôahù¶ô°xß4÷–#•y6ö÷0¢ÅÆÈä õrğxñ2Ğ^4ü#rä‹²LˆK´Ã!×âÈMvŠÃRÑgw€Å|%¦*igv®$DÒ.éˆr4b‹€ıæğ6.úBy&ÿ,(ÊËŸJz|yæ®ÌéS­Î‡}´NÛİ°…5â»°ŞE³%™×EJ{ŒÎÅäĞMÅqÕEŞÔ…:x•üj_<áæjÎ,6Ù-^]Î˜+éÃ¤²Ò†Ÿ…J!©ÜjE®X^®òˆÏt€u_†Ø†–B™2¶>_u^´²óWâXî‹r&L”‹M…U’ĞV@š8ÄšÆW)’VŸ¢Â=_|ÃVmM$9™ÜKëE[5§]R"ˆÒ'£nz¼­àØ> P‡õ\êíÕûæoX
¬Ó§RqµS¿]æîâz0û	Xl–©	ßè›§,H‡¶±#yÖ`§ˆÎÊWânfï`Š&‚ıù£ÂJ;¦±ìä¦½ÿqxEˆÔ·EkCQ‡ç´k›/‹K\æV’ÂÕÅ1‹M‘Ynö?9³Ë²$FˆñGN·ƒEÙ&F@,!3wİâ‡l¿º"Â`htÃ©€Sñ@OÆL<™1(„”õY™b1ÄEe­ûşßGË›ú6h2Ò`¶çšÀëJŞİ·Á—Ë–ñEvšS¸ŠzàöĞÓåk˜ÂÕQ‡R~¬Óå%@ƒüô'tİ;‹‡¬7"×Xxo¤ºÄFaVóVPMé³ÚZºzØáT¿—•(ºVÑËinÕº²‹x\`CäàN
,†ä#±„œxÀB&ÈLh¨{pyU£€+¯'$Bê†Ú,H‡âaSp®€J³(Rih‚§×sCm…æÙì4ëLÖuãfs×,ôgœ,ÔéôÑ$Ï"¹Ï­!õ¥Œœú¾¤©^:¨tÂş†èp7feŒ¢õéd
3S‹¹O³ ­Ù+Õ1©u‚§©LÀyDN³ˆ7ñˆÙû/“‡”õ‰ÓE‹ÎÍŞş§Ïf¢JTËÃâúø,†`!î RçF}fâcœıÇ¼‡;wgÄÉÆieB±ÜƒºzBº"c¨Reı6<‘…ğl· Á­«£K VûĞwC„¹PÇÏ¬o¢>Q>*œ—•?¬=˜Û¸tÍ%xq8XD¶Öf/ˆ}¤ŒwqD°j¥gxÙ©œÆNZ¬ÊD—Ø„Q-ZMYËìÄ¦×ìà³^ºA­Ù;ĞC½Æ‰ä²ú~WñM;­i¹d_r°í·oPÚÛg^Ô—	±ÿLKw|3øÄ¼‚ª%Tô“à£Æ|ª©O‡8ÇlÿM$¤ø±AÂ˜¡§W…C]Éà®$T×Ìù‘4áñÙ’Q	ÀùAŒ7+pà³LW\˜ÍŠ+¾œ
^>_»F(d4Eà°:²¢ÅÍlù×Ù/W\æeç«`L7H[™rq«¶ú…ÿYTœ&ã‘ÊŒ ˆ üŞûDÃFV¦İNO<(İ¿äŠGíÔìæÚ<®ô–±A%F5é›Œ¯úØ]Ñ)o¬Û÷¿fä)³éúİ+ÆÌdK°Ë‚ˆlÙ$#ÂälaÔÑ@‹2Mtxûz²€ê;hñŸ7s…&ÆB {$æÖ >¡Î’
şŠ=ÊlkÂåPìÑ$í%8¤Ôu”E:¢Ş@LRÏY€ùõê~43¸b•üBhHma×¡qàq$}ïó?—PgMDx6”ÕhÁ«ùßwzÔBF¹ÿÖÎZC6‚&±])ôñ’ÛÑçts—å›æ£ÄT.·gÁ>V•·n
»{áä—8Mˆï/ÏÁ¨n ¦üìÃ8»-u1.ıTñuÿ×‚¹ÏÌ"ó”øH-å…Ñ!$+5”NWFeò'MiôO«LEh·¥VÁN7½@q|èscæ'uŒÄeâ;pUıÍ€¶	ÌİÏ£	ü.¦_.ÿ?8ègCÍ|[~³õ+ØÀ”{Eöûš[µBt»}ÛiH}¹5.›×ê„bø§¹_%»»S2E£K ñoÿ7•/©ü$J(r4±ˆqÜnNGf²uä`Œx¢¥‚„Œ.éT`Ex—/ÍÏ,½á‹dØ±#<Ïˆ®ÈfhcJIîÿ7e¢%‚ÑÿÕëpˆ0#ÖÔõæé,\o/–èAJpóm\®šüÜÑk§úü…ù±^ù¦ÿ¦û8³hOˆæA™ÔYÄL6ù·cÃeàşM•ØïÏ0÷ğªå5vğæP0.Oİ½ÄğÒ¥ÕœÙ]çZü·Hº>s÷:i¿Ü(;ÄÎìBY Q˜„?@­ 2‚ø:.çk£Á|\»”µDtaU§7µú¥gÅgg±YMó×;ñÏüş1²²mˆ?Å¤á½`«—oqÔOEõo>d†¸œ93–"+H€'5£¶>¥;ûç`My´§“>aŒbÂmÑÉ÷9á%±”o—„YÆ²©;­¹áÔ¹2Áb˜ôã@5¿¨³zBi&ÔjéÂ‰mÙâ!!i0ıÖEŞàù6¦V ÄœZşúğù^9¾X9Ù‹ï®“¸ìv‘æ&+}é&U*À«	H¹g2QËÜÑÅ)X…•ƒEæ&½_üW:ŠÖƒ»Ğ­­¯ ÿs;· #<Ê«6º>ª\ÉEüí¼|VˆÑ14¬ôĞU6ÀYKÎ=îŞ]:ïíqT«àğz«)6ÕËl„;ómf<6 ‰àk®%sóx‰ÇğÚÛ©ÊP, íEAÎm$‘'2Y¼ì›3àñÊßxÊnhYn|I­`Ÿ>E‚Ã]—K¥g‚–O…µ¢që£¥cIÄ×C˜Â‡u™·3ÄÔË²òÜ¶@™ûP'¨|†l´?¢uÍ•èMÜêKóE}^&XO´Êo®/|¡â;“Óá*·•…Œ0‘%§–,•ôWIõ¬ê€Ò˜ÜóúVsµ’¤fp¢×·®ËWî›—uìÎåR×Ò¦ÒdRÅ‡Íc;öDq(»‚GpV/[ùşhÈ´'|C
6áP·õ[®| ³p„1³â9ÃÿÁÕŞ£¸e² o^üpö\°–[ …JˆÁê®'¾Áå”r%ŞğnA¡=ŠCÆbZÀá*œ×‚+DÃQWé7ÚI€î/
b –k)BÈ˜ °m/;OÛñ51·nd-;Äéb2¥öŸÈwªƒc„œ ùëµ9ã™Ò¾I2öUs9‚“3T‡“ÔÛ3¦B¶ãåİm€]ÃÈˆ€8gªtyÄd ^ºcòr£­á¸c™ $-ÌXév.dªÅeéİ¸İ+ÑêYaùwM1+„Z–A¦°Ş.ï~ºT—oİô?Nb¬WWÁz­‚0ò&R'<PWúè2“Ğğ5»¿™Ãæ)>•Rh£dô£U8’iıòÌXùÁ`MŒïÚoëAîe/]kiV—@·ÍMÿx>¶¡8DªuÿÂÈöç…ĞècüN©YÒâv=êZq'^ˆ¬xŒÀ‡ÎÔÈˆ¸jY0zx'§wPÇ´›^Æ–jêÌùÚwé=Á»¿
)ííõ%d§ê„¸Œaè³*'dÅvM…YÙ2	uJñGÍQ¦|B^c'ëˆOŸ•ßWÜ¹Ké¯Ğ{…p6ÎÌË¸ßÓbëÃODµ òn^/pÌÌ.K7õ›Q‚e48*;òTÑÎ€¿µ%øîVLÉ{Ï\ÍO8O
D€¹›™SaĞ¹õöd,Ùr…qŸ°m[š û¨ñPé¦Ø9]ï®w0ô\ç€p©2Ô…u™
z«¸,´;¥TNJêÿqg2"Ş¹ŒQ“İ Ò+İU¥7ŒDŸ4Y»fø@‹§±”­*ŒÓ£H›qŒr‰ØÚŸ™î;§W^C^7)\¬›Ş5İ2Ò8Aœ¼MÂÙßŸÇAñÕoŠ°Yß=íÜĞØĞ :-«‚Åè	/N¬%ˆ’îmªĞÖ5®E7†3
Qh˜Å<+-™ŸŠRC'	Tï±!DC¶ü0·¾oØo!¿ù—+™r¥¹J ã8!–L#ã*åúÁïıè® ½ 1‰ŠnşZùˆ©¹N«S:a²¨n_b·e§€‚ô‹ØŸi7¶-KÃá¯§éò?•ƒ n^Ä–K/LÛÅ.$Cgê>oü!äa¯âûXŞğì]%¬„á‡¿eÈ²öMÈ{ÉÎ,Ó3,ª+÷œòïæF20~M{aë?~'òAz€Ê¤¨şGI0h¯A{u]îÿÃmQ‚ÂãæšÙè®,I©™ÈÒYu-‡paĞáö®U¢^UE)%¾~Ş,>™fÑt2ĞUø±½2T”^×Ğªî¤YY(Kã’‹š.˜ä¦üànòXÔmŒmæ_!mÅ*ô©;àCZQZ¬ÊNHÎ7a±™ßÏÄ¬R&è]*©ü¬á„ xJ|UÆ`ğËL‚Ã?¬íÁ	úÃvß/ğT`Şbtn0¶fmDW¤ë¦ğ®m@èÅ%0½†¹¿¼Fôw
^Ğ«Ãj¸ĞıÊºÎ­™ND…§í¥sZ‰ÿáËVì%*ÍàºçÒİÅ1Ó»ÛCV#¼$ÖJìd3ŒÚGÓx]ƒ±š¼ÅS=,¢@ÿ¿À,õ*)ÍŸ‰zî–‹óxOA¶öHÎ›¤ñYj¤ H|Ô"cö¤ÃSU'ù÷€ZQzå~E[0I]ñáÿXVÑ·7ügrºÛìÑM°Ã¤ı)IXt,exå6|ã‰È2Qé±àCòúœ³@’Åß(-¸£§ó«²Ü®EÙG9]ûYRF8LæŸRç‡N¤‘€Š†±¤¸jï;Âéì¥¥¡mÉÁù5eÆôäø‘G¦çÄ†G‹ B¯•q(°şA]=¢4ŸB
ú;‡
Xõdõ>òó) `in©µ:¼jn*‡´
?¡Êºå>{3÷œm½Y¶ZÔ†Ô<è2íİ{’zD>ÔÇ-¥ì=z2Èo–Ï¢Õ:ÖLºİi{Óø}Ø’ŠUÍqNs<*T©Á
Eæ‡¼ÜŸY¤J2Ç¡÷A2tˆĞH p¥j­ó‰,!Ì§×hÎÙæ× l°ËL1 ä%BÃ¡JwïÏDœÍÇÉ«àM ,œ3ØmÖŞˆ,ÏĞØöQÊD_ÉçPÎY¿×[îQ¢§y¹5`Ah”kb‹·.dÉÊ?.Êª"8>…l‚7™a¬G.Ë·p›vïR³ğI@îÓÔzJH£«Ò” "K—†R ¦½ãñ­å®"ÑNºÒ0zF›<!‘ÅGÊI“«ğ—çÊÀ®ÿ(ôÂO‰Ä…¾ÂÑ#MxPÿ*©f?”ÕŒs½FyïyíÇáBşxªo™õÉ=S…Ì#K,3¦ı€œ:£Êd4á’‹\ÖÇ+1û„ˆKÜ0¼}ÜGHö'ŞµÇˆ¸Ae oçĞÁUİ’qÒ›šKU‰S ¨CËÏèxk €ÓÒÈ–ó„Kƒnr–j™ãê}©Ãã ™ÔZ
F¾ÿ¼’Ÿ›‘4‹æTuÁÕ¾MHdŒÑÇ#lñE5L¦‡4	›­×¥¥iƒÀİÉº:åo¤Ág7zÓ{T,9ÛÀ»İ9{t3¹­* š<Ä'§šCK¾—UôœQ,Ã<;œäYªzÄîÎ‘±'m¾é(ğ>8}´lÈ‹B}gÑ~¸Ş0K©Ú¸ç	ÆY›7Ç,xŠÍMå+ù:ï;C Râÿ¦o§İïÃR9/HÍÎÂçSˆ»w§ØSj^ÖÜ~MTÑ!ç¶\zïúÉk†éD+ŞkJå°w _x<îŒû¦ « ÕO³ŞÎt7ëw ) •YÍóñ?*€­²"®RÑ(×é }n´¼µ!—±·ú±¼P.Sİ	¬Ü™¢w÷¢ç9HçŒÃü®•*î}gkŠajÉ:w†l/À"Éñ=|F¸#2¦|ì…/½C©´ûLqÃ}U·yr='ù*nJ{×¼˜Ó~ÑŞÙ}¢I?CACh70 ©qïHOìö™$d±¯S¨GÁ±èúºY±µ£pF\şËÌ1òğB°¡	”šÅR/˜qÚı2qrz„ÅÜ4%ûD’ò«œ¡ 7Á@®•§JïüS”€ğñÿönM–s0ÂK1O®®8SŠùê!Æ2,±¢n¡
ã=K°²û\KîÖ60RjçêÚ‡K`]09È_8ß91øŸÌ‰]t¬óÌĞ#A™ïç€yyëPÈ×yô³@©ãü#¯j£Š#©±à}`r
•äaÙ§†mI¿)sÚéó³êª},Œ»îº»D¾‚­µÅ§ˆ=bq5û.o4¹RŞ|ínğÎoÅƒ:ÕLö\5úûo^1?¨ÏkÏ”{GEixNæõ>'Øƒ‘¦$Ä­èÖ25?}Bª§ÏtÔ8¶p¸¿ciØµ3³q9´0KM{¥ÃÏ´IŞgüK-¿P;Ù
1y~ÌåÄF^—Œg­¼û•‰}Uñi˜Ğ»KkKÅ¹¬&Ò€W!dÔg3h*«Ü  äCê4tFè``‚‡uİá¸°œuƒª–Í›ß £ [ĞıÅ4¡÷ñ_à|¯…\>zÃrXÌQ¡h‘”Îñmæ0MC”›—ï_èƒ—eQâcPò‡}DûùDµnrP¨?¶bÂ5cîS#Sœ“3’<¹Ö|¾Yro`S( LøÊq`KŒdUïf"HıKA<JRÚ,ºFYßuÁşdº]º#,ı±é®¾­†×Áøß‘&´¸û3sïö³Í0f~mÆC‘GÈ÷Ñ09%l9=ŞÜÌS Üú‡lº¨Ğ£Û(i`YBa?÷ 3›o¥R³¦óÔ±¡æÛ2AËÊ}°ò_S”«w‰º4ì7ä©©çB‘_Ï·¿O4†39¡ŸŸC0ˆŒkÆ\T¤6~öìô,«
Nvâw©,Ù=â0İÇ[Üï¦S#d·>­2fDš‹¤nš#éu[ïÆ~‹]õ¯©üıÆÈó¬twÉŠ-bÖÌ—oµ$–±(—³i ÷k=Á¿Õ«ñË"<!Xø%%/2{„aˆ“ 
¡Sj €ƒğGö=Œë;Ø|Fl%Ï¿`Œ[Yä±ëŠšnõ'l%iÇ<oÔßá!\XQ'³G£N ‚Ê]jø÷)d0jE›ÿru	©æM
Ç× ÏÀ¤•“ ›=¨fy°Ö_+XØ±÷
¥%%TâÖ³õ2n“6|x#­9›uİoÛY9¶Í7ÕÊ1]	Iœß[(A	ö&2œ½Œ‚Aã=¦§ŞWŞkh8¦‰Jø	qud‰7è«"¼Óğ±¥Ãğ=æP'íÑA+–øU‚Tù1_.ŒF«Pºo¨Õ6Aà§Ãâ³N}„Ci¡ÅÑœ¿¸ş)Â×xxş#W‰ü|¿Y<+Q¿Ú°˜m7*DÈá]ŠĞ¬ç,‡¾àuæ%è9^åÓ‹ú¡J¡1g²«k7Ü—ï(Ôıo¡sc§¸’©£Üıî'9$ZH©ÃaoÑ	ƒ’X¢2“¬’ĞNšh®vuá¨ko§(51ã.‡;6‹uØ7ó¬U<Æ\¦¯ñ 3CO…å¸,ÿ‘bRŠgÛ¶0[-÷÷=7™&;z•HŸmDİHêø²ÿàT³ÑÿDÖ3aI˜JÔy·m¹ğçˆ‚¶‰ñ–ô ;ı
‹xµÿ†HŞª8>Ñq³--næ¤›kÉ,³*±¼bƒ¡¤”KÅÁ	¾.uU~F-ªWJÅpTYµÊ1µsÊ=¶šdÑêeëúıÔÔµËKÉêY­ù›ÀMÊ Õ0©¤ûÄÓÓù5ñåy‚øåVí€³Æ{9JH""·W,üöäZ+ Ad‡bñ?án3rYq
/é'sÎ‹[Ó	»å÷å;¾/bäÿ:1tjH›Öÿ9a‡‹g†ü†xçÆÜÿ‰hñ%Ş€ˆäô»
õ\`à¾y¾˜ñÕó·Dš°ËÚ+.Ï½ÌUèåé?§ö+Üó6òhAUªœİ8¦õÆa‘ÿ…§VVªg¨¬, x’cœÅ_P(:úœãwo#V/ÑM=/02®sÍß?­ˆfõQË—2U^k‰µLôÕ´â•ªU¸{É÷alá§V¶|?¶{  œØ=ÒFÃk.âfü¡Kf +åtö”Ÿú¸DîL|´~ñp‹YïŸ'ŞPI:¸³i/§¾ÀrÜ†‹Ênó(boÏá_ÅÕä®nâ‚if’ÅôL-?°£<¥•'(=&Œ›Ö¿Ø£>Û0È "8¦àİò¯i7š‡Üö›èĞK72z¶súºEÛAÃQ=ëQA3]âH®ÇÄ,$ı”Móré7@’ µòâxÀqõ+´ZºwÖƒKÆÅØéAì±më$¼"îmêô-ÿ	 ì§¤ta!³k¢+Õ!Îòk"<İÍÆl\Z×:4›#*‚üog¿RíøV[•wn=‹Ñ$Ép^²Àtn•2!A9§dµ¹¶Ä+q²È5œ;Ê6à“°jµ’®¶¢²#Ó¬‘rZòOÒÛz,[‹Í«=˜["ÅË±M|gá1Ëü<Ê;„\H†4'wó¹TS¬LM¹ŠLy×XÜ}ÛÛr ²53õØÍ’âwöî3È9AA8G?±Ûê2gı¬ËésQŠÄºøÙÏÆfÔ’a/°»¾¯§Ú1]VÈüÜAï&àxÚtîZÒşş ñ¹tûp×m^ş¤w$ø8ø6®!.V„Ö&TVy"Û*(cìüŞâ¼T4ŸÏ^LœhäL½ıˆz8ñX„êi…^ üUıƒDÎ"_¦È(”}	¦1#sÚ³kTD¶o›çÙ÷Ô¼tÌ¤>„‘Škt²®t[ªL÷jñ²Øa&9³c³&å¡À“Ì!.óÕŒŞELóñ2)\mÿ÷ã>>´øo*2ç»e¤2v¶½áÅfıÆÿÕ*®ŒÆ†qÀ„Ø	¥àsÃ$2 /*ú¶45ª9À{Gòv•4ÉjÚ(‹‹ïPn›½öâS
µQc*’öƒ8×cÎ~!Â=Õ™€×WÊÇĞ–u‡‰J
qu›¯C_Û°™áöÔ{È&FàÓS  LÊàÒäI}ÚaÃ›¶Çœyr&>0õ‹vâÿ9}ëi“Ë7ï’·Å|`•’çY )©½Åò¹ Ë +hQ
]WKªc\÷ÅR3:™·€úÜ«èÊpŠ
×
¡õè)šo ÓšÊz}O–9+ÚÄoJçm`vÖ v²ïFÊßÑ†`RÒqùë|Û¡ãEIz˜$©Òvªº¯¬¶4¼}”—£üù‘'š#Wí<;Dìª‚ünÈ¯ıÒõñí/§ænUçÒBêŞmQô¸oó‹%µ˜u¥Øs¦b@ì€1Óû-ï2şæ¢õZEN9·Ş³°Ñ|ÁhTUï£öŞêßı»?¯,:‘õĞ<‹pålÑ¡¶Y“ÉbÏ*ã®+.i™Ò!}º}ĞÚ4Æ9Ï,ì¹AÈnıäûí·ï•³Ì›”¼`JŞ™Z0Û÷¯Ëƒ½dm]PÜúãõ‡q{ŞpêÚga5ÃXAòª[‰Zn0fG”Q'¡ş¤ŠÒò7b¬l&²2Õß‡H4¹îRijîöÈZ|^(ÁŒõ(·ss›?@ÿ>'.™.¸¢‚ÑJ#¤/*ÊÆQvlÆÛİŞÂ…TíƒæUg’{[Q+îı„ö¦aÉòÓÜağ7ŸÍ
WÀ ±¾¬‰,ªDİş¿Á–ª‹Dwä‡ŒÆ4*'…Zœ×F±Út|ÍÚØñ$)S€ym÷ÅøÕWÁmxlàÙWş.:‰Ú…©ŠüÛÇ|E‚§T—Í?2¾ùVŞ°ùîÊO·E•…wZÙÄ…µÿ«ª½eµù9tHây\«‰G•îüuˆkÖKõtŒ422nDJöG‹µ®¼ó•Í_J³!ªÃB2Y'¸tugS£a‹*+Œ±áïÑ62ı°×-9¿ÓlG¤›A±E£Ç×å'¡]ÇÂÌl¾ÏÂÜí-PäèO²†dÊQ²?eSŸJn³GÊ+<§‹DfÊªHq\ŞÜ¼1˜à.¾uIÙÂS³²õ–t’‹Šn¯Réæ…HDôŞViÂ‚Å@ <Ø•dÓ=3uTw4+Ô$|IÓÑ"ÓóYF|ˆ*a}ıàÿÕ§ A²şOe_'üÌ"1u§’]6˜5Øİ~†ÂË™T}Ş—¶__ç2— ğW š‰8Ä lŸL‚H['ßOUQÆ<ş*¶SÃØaÀ«…b•?%5nĞL¿·µú%C%N)ÑÆÆZ\ª{s±á¼uŞ/… #êømœ92åÊ:Ñó{ájî"™3ŞL*DnÙÙ‚ôİ5"‹ş)ÒÏ†¢sBÖK úÉ…AÊ
>aĞÉ6m€¶v×h›ÊÛÖÊCÿ7År(~ÍS$ÄaqLÄô™è ’¯~g‰Ûßa×«²3ô¸õZtZ†"úë/³ÕÂg9Ømœ.`:CmW?–T¡tR“.®ÖïªÍÑ›°µ«¤¬³LûÁÜûë/PÁû·<YôN…/ä:üüƒ¨ŠY, r)ã=¿ÿ×Í9Ò×Ó¡<–Rô‚ñö
«Š™ÅCW8‹Š7WWéßÎF€]~T]p9»]èÑï¤0ûıW"+q¥ÚF6Á‚²¹ôŸYşuùyú4¡-3…G^°éËMÎÊKû-`t×¸Ì8Z÷ÕÍ
Ç¹¯+‘byF¥økËÏ¬R|Á@{–@*[O‘a-«#ˆ˜5Ëãöm·gYGµµ.T³QAHRŸánkõ[ËIèÀdªMõ!%0
©4bÕ£ğt°·» µÌrÕeu‡×å‡7Kú¿>¿9± N#ËÀ¥FD…ŸXw™uœK±‚9+ùXQºpÔèU) ò'›7çƒéfmïN“§¶|'#	Üæç’Y'ÔPtuì/‘ 4ÎÈ~]Ëì…ÆÅOóz![×³ lÆ.Y
(u!²%ÍM,Œ¯ªºévŸjõORàå/ÅÚ/\”F¦÷†ïÛ‚™¦ÒÛ`™wŒ^ŸuO¢^ˆ¸WÎ/¦Š¢Ü!éõ\VÑ±K_=ÆïÌî×w‰.ŠIôÛëß~¹÷ÃMuö!™4TIUu•#UA/Æî„pUHÓÏı3²eM‚.ì©Qî€š¬{øóª-gëdóT6;‡ÙìÃ.'KÃ#pEêqhy@
æöù°©bôf„JãË‘!¿px¥âX‘˜¿hØÎù\ñ¢ˆA„M©aB”êèß¾øƒc†@Ì¿MÛ‚}3šæ­ˆ˜nùŒ`YMlKJc¡ñbô½Àv„f1Ndl1ñk]r¤Œ.:ÁyPtßZ'C#w™Ğ=½Ã,‰³fĞËU«ûñ8dÎ–’ÔÓ¨cTƒH e "»wì©.*—§ËUãè&)%©ji™åhUF³P–†ÕJVè–U,L¬ ‹'7¬õÙ=b÷Š­3˜ˆ…
®]0AM¤Y2rı•7 è;çã´+#³’_7¥ê‹ì_¬ô¸ûT²îEt©i&ªÿmSo(YÄıÃÁKkÇš¶ñy™ó8'ÌtáçÓµ£W‘úËî=ÆCLßm…3nÖl¦pÒq½ÖUX“ò@A·¾ªÓÁ†˜ç'«ôòpÙV)&GipRÌÉ03ùq­î9«ÅœC}¬k%w’Î:€¬½™ğJáVJp÷.n,µÅŒI÷Ö:åh·in†(„¥—å™A•Ì¾õœô¬'çí<{ì§^0áÄpú‚†ZHùIX›¾él£„Yô‡0aqiˆª s>«BNÄ²¼ò¦,rØá:6èài/aH÷Êr(l¢Ás2í$î‚&iå¾¶ü¥Eü*€¯‹B¢ cñ…Q+™×&ÁÒ3Êœî$‚©]UÑs¡ØIföîBÄlÔcïåEÆ¼süUÈ\½,¬È’³¡,‡8ú¤v- ˜OÜ%×d¢^ã<jll‚8ïıj1ÇX†ûj’‚è±Ù&góorË€›+&òOq´mÍ-±|ØÎMô¶E6SîWåÒ«_º¯å²
3ş²ÆfSªñ ³s:–ùt¦Â‚D_cŒR‡áİı+¼O¥ÉßÄş‚¡.2¶àğÌ'$š¾„²Œù^H˜ln§íiïûoFÉ®æm»u¼M$ªêŞÂ¥İğÑ’€PhÛP‡Øa9y=<Ü3à!ƒIaÌ¶A±Şè` #>æ€İ?vM¹`ôÒƒi|—£ıºê£©#PlÈ•Ÿª»ƒ{¶yBñ… Â«>ò¡ı·Zj{d˜*_ºã;Š«ÊÒ	—åRöjÁŞÃC¹ÜøSkJØÓÄ]Z= ıAšéàhâh´:áÈjGPhŸdkrÃ{šDKÎ×r“õo°9Ã²!äDf€Ñ3Ê6[I#­ ¢ô:¤<gœÂ7óÅİòéá3d[ÅÈ˜p‹öä™òºóÃ#P…¯û›y´N´™²xRü#ÍH‚eĞ†Ç³èdü§Š;e¯4£Şí8„:íH7?Ì»ÙgÉˆN€Öè rÇ°H“déÌ…Š…a	üá»z²
ÖóÌGÆ³ÈòaÖíØ‡eæ‰«'øµîlŠ­Ş¿CÊ	ê³Ğ•AÏ~Mˆ{†³B¦4ÁÃ¬\ªqJLtÏq±&=Ñ=ùo0–«Ûf"Û‘ó½Ê}»Ë©™–TOø¸æ®
6/¿pÃæĞ ØóÖ”öÆ,”ò¤FaèA¥™^…Ö eøÑg™˜²~Ùaæ+³À/{Ncs·§ß÷ı.êS^ÚÔÍY†Q²Z¯ÆtÈô¸ú5§ÄÖ@¥şŞlñCªádõdÍi¥kÍS;µfòÙ³+‚“y{¾VÜ|+ +3ænSB,uú,å¯:·)eˆ„ô¢Ë)Q…¦»—qìò^QÕ5øæ‡xı“°V¿‚3ˆŞ©n©'¬âbÏ'RnÀZÂŸÕ:¾©›uZF3¹-°IÙ¡2¸·ªµÊ6>É=ÈÅ£ÛÀ]	–‡mCªYuÅºÉwœOS4fó=ÈÓœ|;ë4ºèİÅöFµüO«5õ„ÁşkMìä
ş(»¾»ÎùBÆs¨™HÿãûFGô"Y—nÀqdIŒ…©:@¡H,ª£$¨hJâ'T.Íœ)PBèWEÉ†y¼1GÑ°¡ÂÃO›{&;jwCœá]]ºàÔÃô1y4O(ºĞdÑ†ß%¼Q"_Ô‹ß°)í“ÖÅl­"åœ•¢œ<ßB4„ÙW½¼>‡şÛº…ôf 	›v…’ÜâòoUéŸ í>¾PoŒ{ä…º\ËÂÅ¸F%¡æ«—^ÃıİòaJÕO'ˆCMnh¥}öqc;¾ûQuJÎÕ½ªˆ™ûbø"NÀsOd>¡[ö2ò™)E¥rç\G2ûV`ï`'LˆsÄ€Eãr…'£&ÉDÇÜ\“!æ€º?÷Â-x\æô:l†ó§½}ÜñŸBş?\4ü½¦œ¥dyÃæ
¦d´ÚĞx[JÑrVcİN}FA£ŸûÀjğlo)0ëœ`÷@ŞŠÔÀGÁ­™İp8( ¹½Ë¦’ïĞ0ø¥àÎ
¹¥Pk4^n$Ô:OP©@¤¼Ó}%D1+éH‘•)­5xqäYbĞÍª.Íäó04¼9@¶İ¯"Ü‚»m¤vİy7ÌE„ZnE‘ÉúÿIUªJ
ÈÅr¯ÕVf	Î´¬;r¯ÔÍoè›:¶$¸Ö?öBr$b~"‚DùŸ€O1éx¹5¦†İ‘=ƒûò„µ» ßEˆ"ŞúçÍòJ?›ÂÎ’ìÚ¼œDïÿNŒâK] 20=@"q®:bŸ3WébùƒÛÑ­<îœÁwÇ°X‘;¦kíÌwÇazî1aÿ\Š+§¬Ÿ.ğÓgæCœ®P©Ú–àtUŠ“1ğ¦œBáşw-sÀ+MKı‘dè—|¤ÚÛ"L7wÆõ(‚lTw4kâ[m‘_O¸ªõßéğü¦­Ÿ:ş¤V|Ê mS˜Æ§
¹@„
mÅß$şø¨ûŒU›s®9%‚’ÙøË‰¼í×cÛ¤‚hïƒÜÆ¬µb‹† Ï²=iCÖl9€±scle(µqâ	ê+³Ğ‡´¹È‹uAb*rïŞ¿¾ Å–*J¨!œÑ©šzü[ƒ}¥‰-øÅğıª	G…iİŞv\0ÍæğÙr”
rdéc£²y=Y$œÁl
kµïå:o•Ë¹µ¨1Î¬Ò<Ñn·÷ŞÏ‘;&ş¾òÆäÈ,æ— §­² 
nòUó9ÁË]D`y°C³n[uFSÌo1g¹xdíb<éT¡é·×ğ‚GâË\ıñÚX<ººfB=w«dàkQz“æZ¸CŸú$q©?¦İlÉ	Òäy­ê{ud£.XÚĞNóY>EÇÔb>ÏcæáˆïÜv}†Í5ÒñY¬%bË–İ<1eÒoOq½s‰ûâG(?‚µcÄZÉ¬TÌİŠ^. täRË–AW¢]àÇ>.¯¶°¸ËQ¤Nú½”pkR+´Ï<Âãæ_X'_µS®{µ ù¬T ¢äÇ6rT
ú#9Ÿ$|‰z1=u~¥uÁcµ®Î…VÃÃé{ö/Ô-„œ±ÙrÉx°/÷Pï¨ô‡¬4e¯â -\i¢ËÜ­÷©ß@¤ƒÌºÑª!,•h]3ùrb6"¥Í¹rNb½÷tß©= U:ºg¿
£^HÕ$+¯ğ{¸²ûC«\1DÃ· NeY÷èŸ¬–Lü‹õ[RynCw{¸p¤7\ë.9İ;¯kªçC	/ÆKÑwLÜãNØnÙf+Flúåù[Id*Œ¹hKPâRüØ}“íİ˜ üŒój:S‡…`i{ ´]¨®Ô³¥íäîµ"J<z2rQò]óT
AèHKK c~i—ğ2…€Wš	Ñ;:So4B/©$–òóıë]¨(3#,ò-”k8Û8rTèõmÁ‰‹Y8»ƒª©*¬§•KÛm?Ä>‚üø–®öÍšNå:tê¶ÊSkvªı³İyI+£Â$fTÇJ?ØB®şKçÛn³-ıø¹¿H–:Ã°¼{nùƒ¸Óë–„¯uKVN%Ík9‹½™ìŠV‘Ç4I~J¢N™™}ºg2ÚàÌ¢Qwa¥ĞâõèSúã€gòciiï«DãßZ§}£ˆÁNœ*Iï9ºìïe©åÔtuál–Ôú4×dü¶2¶dK¢@íÓ}a¦cËÚÁ‡GRÈÙ¤áªšû½Ìİ¡ò}èÂŠNs*¤ÕŞ˜8ÎÔ†,ä‚~m]•«Øk¢á^`6©‰®
ó-î‹‰‘hî,œÌÖĞe@6eg1•öëg¥vÇBG0†›­ıÒX;4ïBƒ­º+¸¡ÉI_Ø²¬a-R7´˜õC×wiuA›Ô I¶dx	”—;kcp‰YÑ7·{Ç`YåÙ‡“¦ÆSWú„³}67‘s¯è™”õCÜ'ÆÆC(hÖN¼ŸC‰)cÂ¶Ù’ˆ…Ú6(‰W8(?M&Î¹ù±8ıßoSBLí(Òÿ÷“¤J† œsµkÙ+oL©ˆæòÛÈüN“„h_Ìz¹‰¬¯SQ©âŒås™‡=e ±E¸zÒå@Ìº{ğH}è±ÒáË°?Ê½òP+msz™mJ©¢k„YÏÅ‰ş6İˆ¿!ª’”îJb#¡@xAÀÆ‚eéè"Êı•fW?Ëµşvö+ÏˆƒLm›º”âd_~$ó›]RÌŞ³2ÛÙ6%FWŠi¾†o…Ç§º—7m’´5şı3f¬Ì'àl–uk¸›üáJ.ƒæµŒèvÃK]wæŸÌÆ
Äáï•˜ô[g€KFG;òìÜáPF5‰qnrƒ%•WTQrv‹ë©ßºşİÔ³Sø[Ê|z+ûûy“Õ¤ÇˆŸAzÉu+€y=ËíŞ-³€£¤‚Ozø}Œ;‚ şÓ±2"IêÕjË·×7TAåjTãşVšöÂì®ÏŠ$(V#Û§ªß“cú»½®´ÁéÊŒSçSD5d×„x
ªd”ÍœP"¡Öİ(Òï¡¯F¼‘KåŸ¯mK™Ow¢n- %Ÿ@²cû»Ş x° Ïõ’»i õ®\H¦TU 9Ùçzëú­sŠJµ^‹@èˆ
k“ ˆTK-3<£´È¥’No˜…ºÛ:Ê!°£Jbz0×0±èN¥Y@’W™7NPx5‰ªÕäëôyn­µÊ¬st¨ôp˜+ÜvKØ¨£cÒóç\b"¼Ii;Ì¦1Û(aë(ğ¨Iü^H>“‘uvÄ(AYºŒ©#Z_Œ'7 Ã	ú¦ìMÏ˜-1»ıH23ã`u¹¢èTÙ©ak¿qßáïÉªâUé>Ù|½%ŞË®ô„¡Ô¹^Ç…0ZËäSTF¨Îå¢­|>/XÌ^éÎîTyÂU
ãIĞ†U¹ïŠæ‚\÷oÃíeŞ²›Rÿö{Ó2?÷LîÀ¡Ï†3Õ¨Í	k #VcWZVÆ¨.xi)øŞÌmi—ÛËò>Ÿ™ ‹.–ÇU{{T<ÿ‘³üyİiìÇ‡áÜ¹Ø€q™IÌŒÿÒ¶µã§Ø#oúç#³í‡ÑËêtAÓG0˜÷#‹»+Á@vlïÓ/d+¸«Úùé÷ŸŸÒ‹ĞÇ¸Zï\ê#`¢Ešb¿?ù¾Ü\‡{Ì%UûÈ‹¤©,)y‚=%ˆÙ².öÑ²êwÑ
•æ[êPÙãT?Ñœ8#Äv`³áÊ¶İ¨ªòúv÷âüÓÇ3E„Ù×&q¾=EbÉZ×¥Ù¶Kd³@™Y§ğ½Èş=¿3Qş{	ÄÁ¯[•üÏµH<8A¡ˆz)÷lsL(9ªg@üü>Å‘æX~zlA@Ø©æÓ92ÈÚûî´rÆ¯R¹íqÑÎ*÷óÖÓÅï‚‚5ÑcO ñVHñ70!h\ÚÉ†‰ÖÈ\f óš!£,ï,NæóT&|â»¸$ª°Ï›€‚ÄVê¥¯Á'j87‰úğ®u<­¾6FNóäòÙ¢‚~Y3ã#ß‚õ |şu#ŒPĞºGëAÉ#ùë¸ë*ˆÍ¼!µ¦A´¬‰väEäÊmiİä—7éõ:âLíš|{çÜ?ÕİÊf{
zÓİ¯QP$Üº*íæï\
šKCë¢qícìÖ½é m#p@)ríNpñÆñÿìJ¼Ñ º ô)/_ªÒ›

ƒŠåelÌ¢YbEÈ9¨À¾Ü&Ä
ÈL;,æş˜/UÕ.æsôöÇ*kä™Â¯ÎøªuËÔ2kK‰RMÅü†Œ¢³—çí5Pë2|x,éÂ)m5³à²|h+zªş?)¥€—aü ¼ØC¸HAÚ¯lŸ“f…ä™•1Â 03ëò¤?Ún¯ûƒl›rb-*p$H"c"ÿİ%¹IÏue'’}„ö^şëŸª>Wï°B‰‰?Ûtö†~·gM`ï÷µµr¡o¡¤”
ˆ–ô[Ÿ#
ĞNíM×/õ·%ÿIóÓiÆÿ1‡³—RZÄy¹ˆ<-à”±ƒÿÖ‡ ÍÆ øğş¾y“éshÄš\xÏğFT@]ª›ºm úg‚/ßæ@!²PEÏî(±ÿÜáò·³xí§7Ú!Ï¨i_å¸õ¾Ù«z¶-áµK`ÄCGì(g=@nÈ;Â¯ßD?=/ûèä(+â[¤Ÿ¸3âæ:ş@ÿ¨åóªT&Ú!ZºKL`™]ıĞa92¯í» şjAuñr±Aır%¾ĞĞmnÕˆ^G´ÚüŸcÆ4şË
4HHR•t½¶[¸ƒªı gìY%í|I”áoqƒîó„(CzOÁ]ÅëŠÚŸfºá¤ëâgñs~³4	2*F`İú8Lbj¼r
Ê±K-ùÅŠ—‘¤µ0*bıH*ÿğtÈ±kA)zxàÎÕ€Ô\ÀƒÁ¡s*èÚs®
$|’g0 Û³€æáDÏ&2 6i_Iuï’na=¯7SÛ”t7DÁ²¯*Á úô=*s¼P±˜]SbÓÄ ¸Vm/:.Åís-¶ß½kş_~•¶4ÑÖö¼{«©EB}¼m[tÁ¹ˆé#†]šf¯èTÄ&œík¹U#Í*ùºHpØ¬éO’ÂTîß¼p—ËŒè¡ =à'|ŠÓö7_V™ÕÖËr	Š”H6‹4é‘vÕñ—m €{öW2Úò5„÷Lv¾jOÇG‘u€şRs¸G=•›ü}I$Ò~=1Û“<tÔ†Ë0w×›+f®.~Ñ;?ÍÓ0`'b>*'ÿ°,Ë-¬Úê8[–)ğ4ñ”é ı*x¯3Ì&7ÉîOùÆ+o	ÛÇ¬
B	d5¾€HsEéşµçÑ)^ó„‚ç›ßSiÏR~qÿÃÍTÒPhX
Ì.~[¶a&—ß€
‘ExîâlËp¢Óîğj½Ô¯„@æúiüPTöˆSÚV=Û’ªÍÎJg¸ÙÚe³Oäóií6 ƒÆ¤écW»·ôÕ²aÄŞä@bïÉ“cÇúÿŸ§€‡ònÕö‰ìÃlæy¹_kxgîÏX€İTÅ´Ü„ñ«¨¬’Å—]à×ø(Vµ'<U¨ÿX`Ÿn{ ôÁFL“Ñû7¦ìÀˆöPŠçÁU4Wy6á¦Ì8“ÜÖ:éK sƒŞ(ÆĞ¦J¡LT,L¶:L26­ÿ±¾”+;g­ÙjÈ›Ñ 6¿*–$ânTü¨y>˜>"½c^ÁÔo$eGK4ª-9{ÍiÍğ¥íe×C‰Şzëæó(‹$Çh­gTTÉœLy{
Nƒà—¯VLÓ3³¼5˜'	Òq§¶2g°Ø¶ûÉ+w.Mt¨ØSbñ¿'ıùÀŠ‰½eÖïÓ¾Cı3à»s%7„o~ÜÄ\(£¢™Á‹õpØ]­¥Òqİ¥ó\%TÆ87œ¦¢îb“pç±tËæ£™õ³+äøşÖ·ÿ~=ë>­çÁ¦LpÙs/ŠâšT™A±ÉæŸN‹gPI}Ğ˜‘´şy!Ö4×ú<ö{€µşXŒÍéqˆ°\ÕË®8¦Ø¢w3‘ı v!aÃôÓÕ¹lMÈjÜgZò#ÏqÅÿ8X ìšâ“äÍÂ
ïø`£ş²v‚u´è~b6ò´Æf¨4ßô
»·§ôÌ¾jwXŒ-€“k‘…yì¨4ñÕ‹ä6‰ö|/”,*'Å7ÌçÆÇvû’ÈŠô†Â§ÂæP<Î¨Ø.×°§ÇCwq@ûIcÜ7yqÅy‹Õ=ü[µÜDÀf6ul)ôÇeo(ùË·¸PØÛ^)ĞÖA¥]XóQ¶¥ZSÇfHÄ #qÌâ<ó™>,£Ÿ£T’QJ4Ô%ˆszl®LëØl¾éŸÜ
”'Â]§ªİ†€…™ÀáœUäe;Ä	ĞkÈ¦—FU¿ë=‰»¹8İÕİ8{Ìrî'šcõt`[+æ	Æ#‡LGlÚ>ZéšB©ÆZâpùDkÃ¿`lZØ½±³u­²Áxò¦±ª/-¨ªmúÙÂ<àdF¯>ciñ,2²¿´Lé:b2=§7°{–ÑâFˆlÚ¨º“^®í¦ºkjl=#Ga”5?$ßqXd ]
ìTÿóIò¡ÏxíØº÷ìá×¨…ôûôé4J«á˜?Şµ¤ò½tÙW`
@¼WÅ¹|ñ*Æ8ˆYIaÄcÈTíœg_1ŸS$•ù~QJ‡‡7H÷™˜œ\[×m·ÂíÂ`¯ËægôVÛ·Ó¢ª‰µwìW2³pt·…Aå|yÒ—;†q²(Ï¶İÌ\Oİ ª÷{_(-oÍâZ…ë»¢öËh,»•çºrÏ´¡Æ$_n2ÁWák@¨iqİm}¶È08YÍ{'à¨«ªı…XÇk¼:‰¡ºÚ"4I)™ºábÇ-îUæ8€¹r\É#H³3|Ş@-;z¸«J¼=Ñ…ÖˆYç¬`¹VWÍ=ƒõ ÜöÑ“ÿÈ.¬ø·±>ZùNÉ¹¡à>GÈ[_H?3§¤ü1~Ùè@$}¬}ï4×_,güf!m»ÁÃåVŒmíJàgX—4OyÕ›âï:†•sıäÑ¾ù{‘Ö~¸¾$r½¸l
ªø©AëZûİöb¿Px»ùG½%ôr9&½=€-\oÕ”é@S‘ €1÷‹Ë‡%*î”“—NûåRÚÆÄºüOâ´[m´ùÃŞWwâÀÍ «vh˜Á½(Za¬Ùn…5Ş±ÎÕŸz	
^W>	Â} ¿†Í2ÎŞ¼*¨úÄ/Éßé’ÏÆ_ÂI¿ñÜ ùE £¬¥µùÇLÅ®5À³:P•C¡´ªì,¶DhNğ­’}>ËãSƒß¬{ÈñIT¿ Ônîğ#Âº±Ò§Úá€½„eßb»x2sä¤gö!õKĞ>ÔÊ7Äíô­Wı•Í5âDà
 }V›F‰õæ¯¿~€>Å,c&áŸc‹ù‚ÒDù&kyäj#£µp/^ÜÚt8áGæŸ.“XÃk×;+ş#˜ô~6ÿ!İ\©ÛÒ#ö˜&<°+D… á
ß¦vûÙE('ü§mr‚‚„'sØË{.|$q2ÆØÄ)ÍOIçá1S‰_HUU°ÌKÓóÂË.ò85{Á‹¿n¢m0%$½Š{Eq­[³³è ÍBWxğ¡2?èEÖ
N»S±– E	G¤ã·l‰0q‰—¼dw&ªH<#öÎM)f3‹¿dy¶ t˜b©i—LÌ!EdæFëúÎõß˜ßïµXˆôœÂŸ4ÌrÒøLr¥XÄ©˜Â–Œ¾öÅèVíÔ;ÊNbzX‡ê,¼ÿÚÁKÛyŸ¥‘ğçzç™b– å¶¬ç…%P8ö¡t!R¤x~şDm÷Î°a?dÓÏ#êÎëßvà_¸LõúBS{ ô0»("w~åĞŠä­˜Û	í{?½;èäúIä?ª–»WmV­Èˆ¶ªák}£™•û%çÖ™È]W[ZŒä*ğ.tŠ–?Ÿ¡£±.1İ½ ‹!œ÷qlÖ¾F¥m{uäÚ 3èL¹‘£×¡Zˆ¤PÔ¦yÆ9)™† ™¸=NÃÜW:Ä€nWï¤dO÷Ó»au§+â‰2aDÈF~1uƒÜ™šÒ¤¨±lÓO-6(‹Œ) ÒÎÎĞ4ımô¢a YIK÷Ç~Áê‰…—@ã‡V`çŠ¨ ÈE¥,aÊŠ¨	¯ñÿ™ûòÖ¦7åıë~¼ê*WŞ(f¥@…Î$!q°Ë'zÙ³‡ùN#•Wìp§w”ãÏ*¯s±òA\;ó0.p:ş\%×JdÂD?ŠĞ¤NI| 8!jKÇœii:°¡ª®—<wèr'k÷û©z´	MGpÆ8|Wå€t!bV÷™×"Bo»XR˜g„%4áø¬™(º¼•ßşR ˜|;`?ÒÍo²ìë«±“AèûêK\=½61ùóßV<muGöùÙ/Ê<(ÿÆp%ùìW6}àa<,Ï}µÌ¿@P¿V–÷L‰éÀ§røêh”ÂT>Õööğ‚m[ô’®Dçü›HÄFº& v)?¬~ØŞšÄ3t­ÿ4)§,ÂŸÂ|h=¡c
¬Ã:<Ğ©HW'6ÇB'İ»ønzw©èb¿ò\¹Å~*|ĞQ…Òi¤ƒN<¬õÄ= /&¾ßhÇıJ±Ë-ùdB„¥„sğN÷ñ5Ô8R^~Àñá&P¦ŸãQE¢B‰aÆÎ÷ª¦\¢hÎ Ê2‹å67%NûCP3ü§Åh”K.˜—Óˆxxi9§¿!7ª\óÿIZ“`¡ÃŒ‚éÛëŒëµú¾¿u˜Şê‹­kA?ó¸·S™Ó tÉÖ ı9ºp›˜ôï ûoÿ¸2òî½KX<ì<«u,jõG^y¹dZn¼‰ù‰ÿ$]‰g€}0ƒZ*2a*¼jDG‘«ŸÜª²1i©ûƒBáÉ£t}æ;.ÎÕ/áÒ˜®¬¶­gÿ¯ò&69ĞGŠ(™K7½=fGÏö8Ò=áJ_Á†^ —ÄŸkAËS•*ìƒhqÑI¾=é>\‡–”Ãä¨NXºÊß[´G¨Udû¢,!#Úz:™¶'V¥tÍ_0†Æ¤ú¿Iîœ˜ÓV |ØCjŞúz
:;7x/,CjôQ¢–ß¸k{î”3vwÄ{vñ³‰	Šï7ëÌ}ĞÉûnş¼øĞ‘BÿzY3¡´’^“5¸Ã&w¬¼òÚB	‰·Î*µ@.«ÜàÁ}ŞOKü¥Ñ€¸¡d¦ìp~Ëºí•¢¢ï1—ş3Î¹¥€;Á!ÒÉ;TÁ‚pÊÄµ&Ìû&h@ô·;JùxZ’1’ª^í¤“al3mtÂG¦` Ûõı²öå\[¿öûkÄâCP‡Ï«n@efÑXÊª$ÕjˆßZó1š/8J,×€6ÌuÚÓÑfWßiĞZYº.Qõñáº-VûRÈƒ}PvÛ¥¸éY[UX.›>•¡¾1_í!‰÷”&+9ª:Ä‘ZÁ	¡ê>S×ngCD•„™¬’ü†î,mh»ˆ«IùÖz%Õö*ÉNÒñ     Ùn.öà„j_ éÂ€À$Üm±Ägû    YZ