#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1524145238"
MD5="c62ee2742971ceee355ee3f311afde42"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23600"
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
	echo Date of packaging: Fri Aug 20 00:54:17 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ[ğ] ¼}•À1Dd]‡Á›PætİDöaqı³È	wíWqÖ»µ¾
éO¿ı!±~£%òø;š†.9L·_	CN‹DÍO{^¥À1zkc;âÊÒœXlÄµ1şÂæ'7eµxÏõñŸ[“K}´Ãkº•DP ÷İ,ƒQVÕçªìœ.» T%A}N‡œ`*ˆÛñe"|ú19¼Üé¾½Ûõä#F± ‘¨ççˆ¡÷ogÀÎÊ½„‘	AW¥ÈU™%cBíÅªsñºAÜ;Iö8ªÇZ~Rmİiê×0™ª±zÄ9ŸFÓG­?GZïW/»ryåï‡,Õ»KaP~Pø‘meä/øÍB¦¼LyÂî+©&å¸XfÂ,­±‹ÈÉlÙcv˜‹™8œ88o©™?ÍvŸ/;«„•èŒı2µHP€²Eß¶Îƒ:+ÕïQ±Ò¡lxòf±ZŞ½¹cî¶š¢2±šğ2ÄzåXO‰Ê÷—É¦›Vô>c®ìsÕy çË(³–¬¦âĞytÉc1¶ÄG½ªŠ<1¢3qgVÍO¥á¨ï+¥$µîè¢qšî¿şˆ6t,ÃœÕâµ€Á?ŸoğÜ³…çÇ‚¥ù‘û—
Ë×Yº–núÁMJ!Æ—f-àµÑ–@`éº!M^Î×Õ_­.L½ñ˜”f¦ EOóW„N›–¢xŞß‹`ôÃã^HŒ]r{gñï›Ì.¬6¡+5¼m•ßöëå¢ŒjÕn'[§wf”³ë<Ê1ºlğ08^Á°Â\ïÒÕ“Ök}ñO×¼Ô·tÅÎoú_BF)3ÃÆë¨øuA¥Á#|İÉ~[ÂÁ‚Ù3ØÊÒ÷`ÏDª_‚Ïµeï)¿Â»`{ùŠÙ¾ˆ™‰ÒCv®fÄÚtê9ph‹åÅQ‚.TÚÍ‚oW¢WáÜ­,o®ıùó=‹/Ì[†ĞY‚=iÔ©%µŞpF‹y9Wjm…WÁp§0É
İÅæ&ö•@¹I¦?øBpÊ.]ÃB"·niVáKÄCo'Z¿/•:-£×ÒÇ/(NœÊš­ ƒ{ìV­z#ğŸø‹8W}ê-˜=—k±¸ÁgO}gii°8ÍœI˜ß˜şôÚEh„?l+Æ'šÎ§©Ñú3I	Œ;Ñ@#„NN½n79q“r¹sa9(ùd}/ÓB5¹ß€$$Å`˜â>¤0‚¡]°´]yƒJ)1¥ÔˆĞ‘™ä—úÑÎòÔà‚l`‚hU6§›Ûùu}áOiÍSŒ*æŞæ(×¨³¾q7Aia¨\á}±şªnÅ€2æ& ôuêğäo&Î¸ë&x;7üû¢mˆ×¿ÖË]ı1QâæBdk_<Aö¥‡Ç”wøê-Æ¨ÂÃš×Çpì¶¥¦²áµvg¹#qŸ7'ê,K¹&<Ì·!ê?7åÑû&óÌo>" VËÌÎoÂÅ( „˜wW€0çT£ÊÂ´´¶D›UäcxáF•_Ç¨…pP¥iˆ´µpL®¨.€MêÑ! E›ğÄ.ˆ9Ï
4i+„ar­DØ:ê¨#­¾Rèå³×€\g¡¤öÇjvU\"L­å‰ŸFl¬å„ÄÊu¾·áŒÎ¡ôêûç¦R€[‘s'©®…äùlfP
í}æóI€9¼-åN‚J=œ¯·î¨PuùH*¬L9´ã =?`§~gƒïgóYU‚ë0øJ|›§SÇ JFfÜÄ	S¨`óÎHbÁGº·Ö]êõ“êb@{hSw
åèÂ”TBşæ‡0€)Ï‡†Û×š„Æ­tcçUYá–m¢–^C‚NÊïNßò™Ğñ¶ÆêïÙmy…vç!³GØi)P»•úNpü~)cDˆ¶ƒ³h M¹‚c5fI>‰<¬ÀßP§A[.¯©„R@Lr’	åyZAı`;®[³@”yÅ€¼@±ÖXdÏSc­­¯ñBí_ì3myÂ…ÌÈIğ²â–€áíS»(>	VÏ¨i~„`év­XXYõJós‘0ğf­DIÙfR¢P)äóê©9è˜¾å»Ã–¦¨’æ‹'paç~Öñ³Ø9×¬;¸5doç0÷§Á90dĞ+jD<´ üë<·„K+P†hke²Ë2¯&h”Êr3ıV=Ó§rY$a‘mÄåëÃ5=~:3OáÇóeˆúüQDÈÓîç!$g‹1à²iq‹Ê:±öçpš;È€ŠíÅîÍÉd4Ö°H“{ó¯¹“,çOĞëO¡&Ç ušˆWû\«hê5ƒÔR¼}¯T³A‘¾P¢ù"ÈXå£¬cüÖw«_œ
Ø'jJÂŒ+,«tâ‚ZgubWŸö·>cI®6e"\1·;bíId˜€:ÿÚÎ–ÿV¢«×§ÇØ¿ÍbzòsLğÃ0K#Ù 5´	‡’rü¨MZ±J¶Nºt=è¨–½4šÇUË8ãÅR7•°.Ä’_4óä{ÈB`Jüù†ìfë`û’á;¹ËVû»Uõ`½%²ÔÎü8” Bã©¤~y$®`œ¢Ù‡ÙŞŞhŒ¬(c TsvƒYÄ«ÑFqœ¦Õš±ÕÙ´ó™-ŒµfJ‘[¥DsØz´%‡Û‚ÄÁöûˆ‘tU­Šgµ	ÅHôibİCW ‘ ¤º.­]ò/¾O"Å¡<…ë6-Åzu2w0OêÅëÑˆÙôH”àÍç×½´9ÜaZ*3KFn2ùfë}ïñï*`	}Ï¼ïÚú­åÊ“ /ÊS#mÊí}ó­YZG¨¥©bÿ¼·a¯ÃG}œ± 'Ûh6òù~Ğ¿f ¦|íÃôÛ35Sıc—ÒÉ/]Ø=ô4"º²2Òd4G¨ıú{ëZlÎàËÉÿñ³üù698ÓròlkÅ^ÂÜ?j®|Jl6NŸËo‡R‘=ƒEÚ¹ªjI×CÆG´µŒ„ß^SòÃ‡7ŠğVRÊehğ1±Duš³,’Ú<I»	ŞÓl¹$Kş`±â*	¡ã«ªÁ´aEa
mÓ'û<L(ªI	èŞRÆ@ÙÇKêù?XºÊQ²gÄaµ¦1+AÆüÁZÏç«ÿÿæ±LOUä;Û;¯@çvlš+¹R÷¼L¹ãe²{)*â´CšÿáNÎå÷[/Q@$(¬›¹‹”(8¡Çò¡Ù¥H«@Á-|p{~s9Vl” ¹'|‚şDq;)±5{'í'¿µ}ÎJ_BBGü±°0ØR“µÈçK[UAøƒí¨)´TÒ®`påıÑŸœâR‰o“YTNiã\úƒ<˜¸Vlâ-úÙ«î<àÇKàiN¼ˆ§üæ_¯œáÍÆ_ãH2wèmLOrV ı¡ÍAn‹õ¿ô™Í÷®ß·1'%ß“Zf<Ó4JözBfİ¤à(‡Ã+I÷mûH¹wß"PvÊ÷_’1ãµeXF]´ÅÍò[Ò0?~+nYªyGıdºÄ1Ğ6féügOÊ3Ğá3ÙwP/æ|¬O¹ôÏ’31mU\õ>kİ›şÔĞÎ,f^¡z°y;-ŠŒSÈ…ˆM
+L¦Ò“q˜Fl¸>\±õ±'àØ(¤"‹|¾â—¿~Õ¦RßÂÜ[`ŞˆŞøKÁ©ö‹Åõ«{ı”(Z¤¦.ÍÁÛÊÎ,"‘Bò`*ù‚¦©KµÂğßó …¿b<şøoZTñHx5SÒlŠ5,dãí	>à³±yM·“d<fkT¼f “cĞ¦ÓÏsfñSÊ4î±´+¶KxsÌ2šï²o”`Ï)ÈA{0½| X×C¡]"!Ñÿ×S;A!R>öìv¼I‹œÜÇ8Ã©JsÖYZëW©ÚVXÔâ•5Ò9#ñŸR”A(•<F«'@¤DjñU	¶’U¥İØL“±9×Ü;ÿ>ûK­‚€k:“¦¢œÑ@1o›á4S”ùãÀ"¿v·[¹–øî>û:¬»KãT|üÁpAá-”»'‡9“úfOV$¼2«Ãœ§*ÓÄ¦NqÙü»g@»şk}°cŠÍ#k}hÊ>½w
Ë¡Ğşh04Ğ_€ª\Ú.;p\iQŒÕÁ4ù(ç¬?;NU;{å×S¡òjeİçbd«pd5¿÷³DMŠ¿µZ¢ÙnÜÅµ©İÄ©FTÎ I2†F›YßÄÑfJkÕ¯ dÿ˜¬ÁQ>j0Iı—M“}İÚC ²HLé!ï¢f‹,¯7#¯ßõÈCÀ,åˆ(¶)ì‹õã…Œ¶ƒŸ}LRUÍ‹y³	±ªd0¦q‹òS%	#Ò4jcÃ[®ÏiÏÛõ§ƒFò¡A[î¿±XÓJúú$Îøu#KA ÔÎ¸Ñİ—A¡fóúñ·1¸òˆ/$›“CÜ•â¡0ìŠğİhÀR¦yEwÈûmøÉQQñ‡RDF½ûÃ¥J¯h®2·Z„d½M8š×~ ¾R}y¸i,1›şÿZIõ+‘°×R)OxBò4ò¢¤
'@»j˜}…~O¹-}qSfG…ñs¥úıâ€Ù×Ç×s©~mTÓ™·'fı×62HNÍ_YŒM, Ñ¦³%6Gh› ïO.ì÷Ûâ¨í Œ¬ÀVXN®€-„<á@B×ÛëvSÙéŞïV‚P é4ÿğíÍ ßş~'œÃ?aöï9Áı{ò;Ô§Qya<hÉ—Ã"V-–ü‘ræ)§¾P³˜«Ä*S}1³hb~JÕúŒ¹â<0)‘æH³}lá8øÍ>å¯¥o~1G»ûÓmÖZÙÁ¸'â»~šïº4)Ï@ña
×>Û5":;È_Lào/b%¹ó%½%V¿–¡1ÇÚÏ˜£3Æ˜\ÛÛÿV±½áºê&5v s­ÎE"÷Œ'‡&lòpèNúå¨Ù‘ÌljI˜Ø_nK|Ÿ{¤:Ş ¸}w÷2ÄWDÂuÍKãBö0‘¢WD1{@y¬4(³Ôİ6#K†è*£qQEx¾Z»4˜:
l£´óÈØ´of";ÕuU',^˜7üãÈd«ı¯†2ÿş"ˆyº'œ$é9„fÚ:†KÁ–ë•	‡Ñ÷¶'qŞ±P<ú9 Xµ4CÀ„:†–5;‡á8›Š@¹—M#g¶¥/ç ;¯ÚÙ†‡ƒoßÔ÷8šAÆÙ>÷&Í¿¸ …¶%ó¦Â2¢aöß8Eü·”*_Z‰G†¨ÍJOPód~IœÕıëK¹ße÷µ[?O†¯¼Y’ªúKˆ–CÃ^?'< cc4ù¦{ˆdïhm#—æòùBÎó< Gè‰;Q˜Ì)[ÁÁu Â)B9Í¶r~½ĞfuQ'ƒïk}Mxñ‘Ó(íW,Öì^f²Tğ5ü¥6áì#Ím'3U¸÷Ã¢-J<°àí®†rñf»¬&Aßvıÿ¤!¥!Z['!LË.¤b•óı(5öèeÚy^C?kÆxq"*ÿ¤i2§hgpNV\(ÉqÄ8dƒ–Gâ}øûŒ/}Öòv^õÄ¿®PVjuĞ+ìè-n–Â&V‡tf+/ÄÔ<§3p+ “`¸¯K¸[!ˆÃøİ‚$éƒ¯Äx/cÊdz/˜­¿=Ãœ>ñF£­%!EÕ‡t„MSÃn)$}šVÏ5ˆäM(®â?å§[>ÀX Ü‘Ëè_Iå¬¨¾ŒNô¼„Ğî©ÄM½¶õfroèÖ	üZ2¦† Cğ•½üúÏ(ÍJ°àñù_¹Äë‰é”\ì²[Hôw÷—Leà+’_lñİÿ`ÀMF Mm€»¯/ÆI}Ş"óÉÆq6˜¹ÌšÔq×]nRb„Ìà*>”o¨âq'ñ\´BVœ\7$Ì,aŠQFK[Ë7ÖÎ‰Ë¸÷â¹
	:ÙÉXkÿÍŸPÿ%BMàÑ7ùdQÆê–Ü¼:~I?ùlÄfûÅÍs3ŸwìmSé¿P^øîãñÌäìuj
Y+Xo‹¦¶Ì‡İ
J|4GY¢[ß÷©05%\Fg«C¢û«]¡™ö"û=7éšC²co’–ƒ­nEÆ«~îEhÏ†İ2±ßà8Ü¿B'Ç«p¥zî§y	İ·“v@‹/Ò)¥?w;…ÕÛ‚í`DáŒ ZS|Ì¼asº€§õ§Aˆ&ÛÉë)‡Ÿšv7©z¬˜±rÕ8-£§9ÜA’º^íjeÍÛ:õZkYçXƒ´8Œ}ıC§Ÿ^;q’yE½vHƒ=lK“VÓ€’’?(usÉ&©ä°Ïõ	ès’ôõôæè…©n±C:l†5í£t]¯ç˜¢ùm¸n&?üQŞ7MHœbÑ‰BÇÉïøÀ©Yle‰tÚóÖe&÷ˆæ"©I áïĞ6{6Â'#ªÈ.ºØFyo*y×¸ä5³†ñ²µI‘E75}ñ™§>õ(æ
¡øW¡ë< ßÅìV8¾hõ
ÎæÍwÏ5+r;ÀF48™‰à/ûuÈó'S/ScÉ$(MÃÎˆùI{NÇw¯Æ°‚Èi»Õ^áò/:B—.Šı¼ƒÑ¶Ö¹òçFÔ¼Ç¿0Ù-“ã]ìO<l@[‚"b¥.²ÌsØÆµo%>L‰ØÜ±\ï*Û9å-}WßšwsÜ{œZ$ı¨@€2ı…MÚÓw\ƒ-ô£°‹àê‘®AÌ ©3I_·ŸÚ$ÎlXäIÔŠ$H«³iÕpÇ€9½˜xg`&=Ëª*Ÿí5ÄQ˜¾3aÁİVœş$~/uÅœSŸgÂ"$Xb”6şÀü¥3ŸÒşñY»dÄ›»©4QBÄCjG÷8aÇg9º« õc¾‘!SÏ¾¿¾±«X{T·[²ÆUóƒ$[PÁ5âFÅ0¢EùàÉÔÎ¹¤¤-½ºÃL…Œ¯€§*­ıoüâÌª„Š0#èé×ÄWÙJú,g¡ögîİnØW¦Ë›QyŞ	‘ÅaÌËaú^>©57paÏ¦¨
s«!ä8Z{µX®ç~]äÎ\Ì¼Ö)U´`èZ¦>ºÖöù&“c¡*A=ká«Ü§¿‰SjïŞâÂş.ö=5ÇÒQ§BOUTN:×¢¾]‘´’k3›{-p3;¯iÖÌ?&i©qqÓd¹}RX–ƒ‚Ã}/bùtã-I*{¦1mRÙ¯`rH,¯îšAÑ&VïíÈ¸g3İ„ékæˆ?Ä„ÖÚv@ãhHÓ¯ª$‡ƒæ¹Û%Í¯rx@î¡ı™¯¿/rì§9¼¿IŠÿÂ‰@ƒ¬éê¿#Ve›¤V *®Ù¹bÔï©pà&zŒk¬âï…ÈkÂâx‰Å;wæ®ü\“{¢¾.Ş6­"¦*ô\~,½R©5ĞË‡b‹,#L\®	ã*PÍ€™¨q•Œ¥ÿgbò×í™u‡U![º¡«d™ı„ x¸ô­vv6”³³öê¬÷øÂè¤j™V§Ü“£Áü“ï3€b«;¾ÖSÿ±àq(Z¼#€íc®ëYz—û¤„A¡?pÕë ùÑBnKºÄ­xîAª~I’…E%Ö—M\)hÑbÖ@ä$’Î›{ï,h§—­³øx<ÚúwÖ MŠËÄıñğk°i–¤4e}åMmZçÀ~Øê¿—/Ø´r¤ËŠAÇnÂŒoœŞi¥ fŒÔ:Â`•Ûş}ı]0Æ•.¶2öX]¯'Y”–[	)0Vµ–˜
RÊCßîK‡ Ê9òŸ2mhÊ4,.‘Òñ!îRrÏr@*Œ¨¯œ­;·úów½;p^2°X–`zQÚ•òQ¡Í®ÀZö<Q#ùxz2»“#·éAÇÒz¹yV¹•ç7Òü–äğ$ª¨Ò@fKÊ¦¾ÑĞ<^¹$“ —C$ŠŒ,ë])ö!ñ2ŒSGP`ı²`EÇgi­Æìãnhİ¨X’EÀÆ[­Ÿ —í=]%Û¬ÿš}bP…UVVßWVˆ‹ó±iví{C+)<!“«a›üñ”>õÌærTzåÛ¸çİt5RWç½dø¶D\ÔÊš"ûªÕ°Ó›Ğğcú/'<}Ğo@Š°×\‚ƒ–šÈ†zh‚z`LIpûÁ‘Q‚ËÂt‰› Wù÷¤ğ•İ²ó±tX›Ü­cØUÚ´4‘åN4çÇtjÎ0°Ozèàuó9‹À¯öa&Ö«9ì~‹].+ÑÂõÏÿ:™¼j[iw½-½r
P{ÉÎŞmÛ^?"23Š`ÃˆTO‘/w‹Ü*
(˜q8UùA¬‚”“E#;£ˆn¼¥Ê|TNÜ×ò™Ğ¾<oòï®Œwæ'€TW†‚ìo ‚^ë2Vøì1Õ?âRr×x—iëó9¸­x²Fg¡ÅG"İU…È|‚}Lì­ d"æªûu‚ÏÃ8oédbØçäÄ[S%°W[“šñÚ•€OŒÜÖ-w@æ~8K/ø IÍO’xûÌ;c†SÆw„ôê:=â§Ü–äCân÷útB½Ô{Ö«™3›XÂ#ø`Ä
9—úÑÔ‰éÖŞUÈ€.~ñCs€oüøÚEŠ(’kdkôBq´†Y¡3AZ–ŠÕÏ\†X˜ù¿fw¨‚Ó‰ô~d¬A»o¼BLH§kœpF¡Ùó¸FĞ®|§Aå dë^‡ÀÄÚ$÷ÓŸQX•èû÷KÕÙÊ¿TÉ\Ğ9ôï9éŞk`€Š~±5‹ÃÏ^GP#Á˜9£Ù~à9šF	JÂ;Æk.ØD
¬°!B›ôÛb9B‰+®|}”t‡».#¡²x,İı¡½‰¦ÈDÙµ`¼îÖP‡1µñ4…øw˜u}^'-Şew¦˜İ{ p¬fŞ“9YÑz÷,D€S²GÙË›GFqWÂ‡-lÆ1Câ.Q‘ExBñ‡2õ¯T,#TıB¤1©FdâÚ¼_©Ñğ1Øø‚·“.†*²i¶!÷w“áï¨Op8rÉDĞc™ˆä°²ôê L|÷/ğ¤½òŠI,iîœ¦qI¼ÿÓ¢§¹ø¾‰cÒš)•u9m .fÒ¿È¥Œ_ $=âTø@á«}Šà±ÿ¹_Hq>Líø9ï°ş;RÁ†ƒ«çŞmËl‚R=ßÏl€ç®÷‘™5ˆRÕX:«áö”=s¿ş`:&u7‹Ê*CS;<jºx7¶{”£J”¤šä¥;d[¾C U„¸åóDÇ=ŞV~¤Òpû;ÒG–üIDbĞÚ2¯÷[YB.a!²Zvó(‰‰Ô1Ñ½º•ûòS5ËbÄWÌNòôÿ˜5¹Ê¿·°½’–[]dE@kA\O‘)šjÈÑqËÈ¿Æ"¥¤.Ûâ¿ÍÈ>ÂMñ]) _ÜÄÎ¢ú`k"ì˜n4dòÆ¥|mB1œë“îŒ)è#•½.£ş§qmX³eyG³O/AxİjeÑ+¤P…„—fô‰—Z=Ùé¯ùí—I)»ópÚ¿’‰Ñ\)Í«%¥O!ßPašúNNR..2x7Aøˆ&»ÉÉI‘d‡do:·±J-—Ffèû¡ğÁÈà:°"*¸¦½äTeƒpKQ†ÆÖåEØ£Q&¡ğœ=‡š$.+'¡9,¨˜Qô'F ¨ ­†xwQ§*‚ldJ+´ÍöÀŠWîH¾ø_c†ô·¤ÄËÉ0b]c>·Îì}˜ˆ@40»±øç”ß÷Ãiò•SVºv™HØ+/'"ğºÒ4Â¥´[:p¬d
¥¼K}÷ğn7¢Šk:˜•²¤­iñ™	7-ÍpÉ3Wsb<—‚Ÿp˜°’ÊÓëT¤?(Fªà ®&Jd“V¸TBQ+a˜¥ø»whdÿ@„²«¼€Eˆ0àIÑ-s#ã™¿R“‘µâm”–Íæ)¶ùm‰ŒæÑa$.‡ryUåE‰ê`¨cô>èşHbc›\GXóşÕ6£pªNæ¦XH ÎŒäëbˆSîÇ¯ë‚"–ÅV_sk~}ü´KòAë­jú$êÖe	=ÒJçì»2Ëñ„q£Ê×Eg.áÒ÷*Ú3:¾^7Ş²¦hË’§†úd5åV"ù,\ë‘ Ø¯üK6¦ÆkTI‡PÊñçƒ(fƒùÏŸ7K8 ¯ÅÈ±Ñ*Ÿgæw•W‘bu^ó5·Lâ_7¤'Œi¡!>2Ïp?c¦§àO¥ô×&½Pş7÷kO:½ÿµ¤Ó·§J;ãnÊJİ÷m“Òğö¯	« ›<	ÖîÄj›®Zë%“PpÄ…ˆÌ\cµß"CNò	0„âô£ŸF	]Ñ\+ú³J‘±/ÜÙ;`æ{ú5$ Ÿy>Ú,2¹ÆîJCvü¦rÜÿö/|}´º¶Gè}$Lc¼wÕ’Í=-*,jH›µ«‡Øeşà»í‚;Úü¢gr0¤
øÿòŠÅáºã¦hH·tA¯zÔç3\R!’åmK ÛòÈü°W¼”:÷ˆõÔtüÇãÏ`‘gL¢ı¿	¼'ÆEÊ ÓôG?½./t:²ï³tóX±öV2‘÷AÔYaŠ¡e(øıõ(‚Ù½&J‰dñÃ»Gğ+ßáU!S*ÄÍ½ ÍşİpÈ$†øôšñ~W#„4Åø¿ØÄgÜÄ[ğ¦‚îØ 9öa0vÚİ«…¿¢ßyCŸÒªâW–	iè&©„I×‚ëE/·×’6rÆæ6³;¼y9m{F/â›®–AàÛİşë€%šEÿù|	pOÚû5´0ÚÕ3"İš3ËÒ£`†j]iˆÜŠ‰ò;ÇK/$‡!ÊÄâ±iª×²Ê[ÌOS’ò8¢È ‹k4…îûŸ¦Ôñ!ŸG¢t˜æL¯’^ô°™eÚà”Œó™^©Ü#!:ˆšêÿßÈÀ|l"‹èÈ3z“óíZ,Ç¬(“6 í#g×ÙlœòºzO¡[Pg»/ãX@¹6™ş¦"{ûÍc"’¯%S–vÅ²óäÇéb¯j3`»Ù ßš]bpÅJúvÂ¢ç™]œÄ¿·ò‚û¯Ğ…0yå&~Ÿ=Ôö4J2¨¥@v\Z½•PR!‹&%ícªpCğ’¶„±x•¨&êmé™ªW‘Ğ$EJíÔB8à¾ËíÌ2A]
Ê\l&Éø)vâ{»P÷Ìıc	Mz.\Û–zE.£b*H2K£PûjYâ5¶1úÀÉd2¢ÒNÊî£Œ	HŒdÒÒÁ.ÈõZpg+º)7¬ì\]çàfŸ>=®yK)í³”k_°½(!.cËŠÉ£­µFÑ`ˆëØHjU±|dq<Å…ÓéeÓS"hvˆÑ¦&Â•{<¤Æ“¼cè6ûJ“=ÿå¤ qR
üşˆS$ğ†ƒÇCAï‰¬º>mØ€­Ùaæ™b2şäRdéßˆºÃÄbÈyR/ˆ/çŠDö9‹G*ÇMÎL®wÚèÊ¾/ùÀ®Ü·¾¬$êúÛ³»S. Ï¥¯ EæÏ*pá0(˜ìğHQ±„ì6äÚÃ|æ éÇşa?ÒCå‰'˜¡2”„­'VòëåjãÚ•gDi)l¹Báîÿ!”ÚMø3J™~8-úØ¡Èş’†7|àíÏ	{"o½Z·só¥/.ªÓ¹2*ÏÕe;ŸÀ.Ä÷&<G¿{x|:T`¨“·£¸ÈŞ¤êxÒ\GŒ¼Øã.Ÿ¡€†ª™ãâXz•1bˆê'òÊÕŸU¼6~éÑ	İÎ·æ#–{ĞfÍ°4­Ç„d¼ K9¡Ã^öş»¶àŠ‹¨ÿœŠ³I~‚UY«Ó-]…kê¬§ç¢¹KÓ¡Ôü6ŸnµËéJĞXG§Î%›I±0B9m!ÎÇ:YéÙ×-!Iv·AL?}d"ÌËS$mÓÿkRqıà’{>óSGU§$F•óûİat15»}UrA2š9²1,Íü$qÜñÆŸÖÑ×=Ÿ°@/!Ü5²1+·_ÊÉª½)äšzÆíÿu)y©ùNI"§1‹=ÅßÈİ%½5An¦5òâğå#VV”ys~tÔèîÙ×ÚfÛ=À‘‘8vRvpıP‡5¢mÀúK5B	Âª“Zj
½%g¼vn‘1ú•Ô±k_ºG´|ÍæuéxşdxíşG`v’d$¹‚8´7Ax¢¯Eâæ—\hsªà%%e”’{iÒK@:±g±¸èÔYGIQ·î*ùĞtI€æ—Î¤hF%2s¨9h%6}={!âéSWe{¢$ã§Úğ¦×G•¹ä"Dy¨ä!¼êÌÙÒ€2µı­JoÜèª£î¹ÿHÌN`Øëú¬ÒpÄ‰LKÖ¤BÏ’'ÖÖõÉå=édHÓ>;á”’8~—~
ğÒğ	J²ó›å±æÀxÓ;“Ôªüï´Z×òÏs›…ûÊiX‡ikYÏx”ìkã#ÀA±ii†ÙFJV(:˜­¼ÕŸäßc>=Èìj‰ö##s(Ã£'z£nØRøW6I¥˜9À®mPß¤T[ƒw#§,•{è„€£-ûJ™a|€ãyÇ/khY«R¿R±ÓöÉº×Oª[?ªi™!Ö‹Ó=[I(2I«KÄ¾Ì([)@¥^>ôj†èJé rnñLÊÈXKó¾]|’ ˜Åıaˆ=¡¾&`Áæ¬Š£©®Î‘JsîĞ.ğîÆ@qÊ?4-äòáMbq©XüsG¡X…s•Š†ØÖFüxo÷Êë$toI÷à}D„ë(ô@y*¨É&ÙÛ6nºíFæ¡vO|[‹Ùû\ ¼úòiú(8Í#ÔO™Òr(clk—ŸN‘å%×ÿ$øáu:Ğëßl3­—ÚØ}xU™ŒÖµ±Hø“8ÿ„4«µ7jöê Éb™/¬å“óJÀ`e|<.^bRZY$~û„äX¯qã@t‡-ı#úÇ^é5Ò&ğÛ‘ŠÀª^;k@Î8kNJ?
¤Ğ÷ä3ê„ëP€8ÒÿÊe‡5ˆâ-³ıİUe) QMï|_/~˜7îák‚õÑ³Îc™’§Œµù	Ÿé°ÆYç	 qèbwˆÃvÇüĞú”,­…ÿÅ-xºÆ­ƒÌ °ƒ¯¿¡İÀUo —9œ* Pœ”pZaæ;!	µ ÆÒÌ‘E™>ª0Ø=P¦°¦ñ€2ÙÛM'@Wÿ$.stNœ.tı÷GÍ®Ä¬ÿ¿$\ ±Pƒ/vÓç­-z±ûâè@¢"#»ı÷Ÿ]îÁYÖAÙ¶°|lbÂ/y;W”˜Ò“”áÇMºøîÅşØÏõ*Æİ…œúÆCZš>APÒÆ³¨ ˆî#–uèT¿X¹\;Ì,<’\ĞoEz‚¹Â]Ò7S‹HÂä›ÊÈÎ¹¡ıØ—2,®ôªÖdßÄı•`ÏÿZNS“íå^n»Úo ÔÅ•›ÿœi1K@3e¯ôRh6E! ú¶›eå»¯Ÿˆj¡tg?3«¡#­&ŒdJÀ`gy×®$gJ\Å˜)ŒÒ¨8“š¾‰§…g¢ì‡ŸŞq™_nª«ŞˆÔçyÂ|ŠŞmJWÑ;Ğ¬Ò¶f°ıBÃˆÜ†$„µ°_)şÍ( +{ï¿ú¨¿x‰Ùl¿ÉsşEG	¿SiáBÂ$äºÖÄh˜?Í ª‡kp‰ësjGK9¶S_'P‡êbiE'¹Çñú¨¬:çDzOY-x<íÁ7ÿ,R;ÁÃÀûVğ;¸Î'GDŠD˜­¬Ç‹ÄtÇ÷Ê›VH!w´ß]–GBä=€k¨à;ƒÓ	‘yf)Jl`JÜdt¥İq´?Oœßà
ƒšåÑjø!LO;R—n|ğv#P{ç!W(Ù_Bøs)êÅU‚=î ¸ˆDŒTB¡V‡iÓfñJºÎÂvRÜkÏ™ëqñ‚ÕÍàŸå¨åãœõt†@¥¸êhÓê‰+í1ÇØ°Bˆcp+…Ñ]zØ{Üê=¼ğjSŒâİ+¹m5òß	)Süø¤oŠ3œñÕè’Š=ÀBtACy>×³KMÆÆ Ô^Ç_€aªO¿Y«*„	Ì½ªƒ”
ëVÄù÷ª”pXïšğ²ÖJ_·{•.£Ô>ÇE,|T‘#LŸ|]{©éVÃùñG¤€ôMš‹E:õí•5ä¶Bv$ôüäŒy­êöî€_ŸÈ€³½KË„ğó=¼v „–:½A ¨´‹ãÌ„0Íˆ8ê@|"áİª`ı‹ÎØ‡Íàè©`°[Ü7…n?iKºU…Ñš‚!”/»*ÍêıMsjéB³Jïj,I/½¯ŸbşN¸Ù73ûP?tø×~f6’#FÄÛíY›·S¦Vs×­€¹Wj5‹ø?:.^ì¶4ÃPitU£Jı¤üÒQ@E¿=§PVÅ3ÊösQ÷©´]…È¹¦,C"»¶¡â:öz>RVÇAtî™M°Íd/¸é¸€wÆÊ5ñù)Ÿİz†MêÃm ÍÎ"ß¶-’àØŞ–Ü´•ĞXwß‚p›‰7õFƒîZ_0ï=M¡³j–ùD†™Ã5#OéğšÕK<1tq4
ğßÖ×º*w(ûÜ,¯Z·Ğì”Ñ_qÔääîã~?˜Ü(4u]ı1Œo[¬ ²Ñf%=7"Œ5‚‚¸näd?È ÙÙ…»Nô ïülˆ‚õ§rã¿•¬â¢™D"VÜ×c"áxb–ç÷™ÄÁ>ÍROËĞÌø0Ô“3Ø1í¬k¯°Ş8ÆrNf§Û~‚Jng^Å•%
åwØ!|éçÌĞã
úlTĞ:"‡Ò!Í¶2£ Ä}©ÇÔ	o©1ÿX?U¦nD†§‡KíoíÃØwŒ»‹6±"VêPï»fçÜ_I{Ã÷…‰yZ˜AfISîbd6A÷Û'œ7ÁFŞ\ß?;G‚,Á¢~ËX½r}95Òœ¼cº9Í]ŸÀ¾‚m—å×F(ín:µm¢5ì	},wóbƒ,ÀÉ¶°C›4³”6I3önhóôÍÊ+s.1¨a†3»µ8ÌÇ„‰šRsÏŸ™né#óy¨"CUÇ,%2Yj¾§…XjË§â$áµ)Íb@/¼	×PNä>ÒN¼7—CÖÈ°ên%_pƒg¤03Lê…’Ø—½mŸ¥ã¬P4¡ø¸\HTO~;»à(ÖÇôê"ú$ÌE¸/C|V³¦}t¢á&ò>…²l7ÈÎîHåf¢jz²®€¡*âÉÃ;§•8K2ï½^L§ØH¤ÍöÔĞ)I¯/ÃNêœ/¾£åÌÀ(‰¡ìï@°•â³iØFÊï¯Í÷Eƒ–øòÏÒõŠ2Q¼g3ügŸÙä DN¥ƒfˆJâA¡4Ç”ÑT¤¥·‘Â0ÿß'B²Œ²iÈí”™#¾«e¶R ºM.…Œd^±Ÿ‡ÑL·ğ|}˜^)w—/e)t÷°ÉãyfM7h,ô$•Íû3—°+°Ãô£y$%~ÙÄlÌ´á¡(r`¹Â¢nhD-ÕÂ—Iİûı¦ÎÚiµnñ{$Uó5¶$²‰Ë›²¬H!ºkK^‚Æ³İXIÏ;I)a•€n‡şşb)]Êß‚„8²Ò•=-¥Ã´’|HXÍN¤´ ÒÏ­{j9)ØãotFŠü Å›°ÕòÌĞ»(²İœÂlçƒSõ)ÎB°ƒº¾e_¾œ«„Şm2ëõ"uÚ££¢6ô%şãıu×ûœ×5ıÜµ)›Gª^ÏÔ\‘=§ZXiê‰ sÄc;#,±EÊF:´ê®†L{PÎ.‘]lgy	ÔAĞ2Q§‰#‚©wøÒB!ˆ½ÔÓ•2¢ân@àe#º
x0 a”É„”ˆ oùØh÷X¡CœŞ-Ÿ°4ÿrñÜõ‘¼}>vÕ2äUãVçsÛ~¾Çp Œ2åI¦§±ÆúQ®>°eşo%^ç;ğ¸] ,U0…mÖ•š™hı8}ÈÅEKÄª"êÍçÄ2kÕŒCCæÔÈÏ4“v£DÙ9.‡?jüñk›…“'ËUêÚŒğI-q&ıÈ	ezD0®~r§&%éÛl¢èÈÇ"‰*œ$~Oµ*ÈpÈ…WvvÄæÇÉÏ^'+gÖ2e£©?¸=%Ó9Ù› ƒáÑê—`õ"ñî%‹®òº-à%ŒµéÂ˜éİ%‚]A°ïÁ§vÛ:¿Ù’`üÑOù«iy`rO¶§.A/²:ü×~+ 	úe%´b’ı|ïıLÉ© admI ß¥jÊå.¯*ÿ\ÿ¬CVxñi`åòê#GG¥ÌDiV2<†'>Â¬DxX§v}Ÿ‰`TFá*òËÂˆ¥™§lœPy?~‰ö¤ŸÕèB˜rÓÿÚâ Á¬1Fõ;9Æ“/½9vã5]QÍ’Ÿ#‹¹i­°ğ|2sMv*ğL{{DÁí‚ºÄù`-;;Ï“&b¢àdºˆáÀóŞÓÊñ!Êê»¡æ‘OR‹\ÿTw ¢­5ìÍèjUcË…a?æ´ÛF¡x~@ … 0oP·‰òêaBO/NãÑ:J5(ßık$`nó:Îh¯Ñ»’=Ï)eÕ%Åªñ:Õ¸'1ağõªâ¼İ nâXÀ{:ÖÏ U4+]¡½KqûyÈı±şf*½óŒºÑŸë,˜ïĞÁC—1Ç×ÉÅA@½æYØ.½|üìöé8ş®º¸-æ‘Çl11ğ>E¥Í ³iK–27Òü™ÎTxWÃè!+¯e>a’C|ëœööË/©â]£EÔT¦åB{hÁ¶D´ŸIÏBØ§uÆ3êÏÈ>úTÜ÷¹»Ö94t)@èÛESá{Ÿ€esk“»×¥!I»è%êµmˆk¹7İôBB–‚AAÒ¤˜°t5îÙlš÷…Iö¤¸A"‰pÖ=úî‰¡zoÙ:S±u£§àæÛP|7«M§ViË!-ğ=•(Šé¼Ò‘Ü:ZX©6íd‡î6ySşZ!N	:^Ï%-6£¬÷‰šwİä/OÆí«MwÅ÷¤Ïò$SsëÄ eÍşç‹ˆÇ±r4å
A'Ô?„ş+Éš‚f¥:Ğûìñ8õm©]QÉ\^ªBhq'°Ÿ–eIUäº‰|*â»¨íŒôêÎ­päà•hÀc4“Õz 6a=?Ñ^)u~O9 •<BD´ÀE;†9èê^]ÿÍİ°#9Ì˜L£Òøï‡Ërq+•3X±…úuE!äß8fdÃÅ8xV3lc!W¨•4$³xÉñ3ğİ†Ãsö,Ô{
¢´õ|ò9nGøÙT¥ëöú	%ºšP&V})ÎS•=6•ŸÂÜ›“İµgˆ¹eãìpïáô8­b¾èª1ºÜ%ÖÔï)RÿdÜK)¼ ‹‹eÔó‘97lrÛÍq4£-TœAL3æäƒ[˜}ëÃYJWF%"K+H^×kÕâÜª–¬ÚY²§>U”>Ï	1íÆşÙ2Uò/Ù^2½³C`¥İ£À=ğİb3(ª•Ã6‚Î]Šok¶Ní,7­„®¨ø£-Fäax-ôsáó'ª,
	c/#ZaÚX`µ‘p8DMR&—
.|I—0EñœÊğÆÑ6 C¯isÅ¬ÒóDILZ{t‘ÀÙ’3(÷rL°(y¢÷rwÎŞ¢hY7MÑ^  IS€ãV"ÕXï¡6¥â½Ñƒ…¢A€¶°›.Ê{z.ğÁK˜¹ª[®xxÅùê©ŸÛêÛfğÒTÌZ‹ö{]›éÍ¼ÅÑ.ŒvôeÚHUïÀ¥"YÿQø9&”÷ëË¥^Å.È3
É^t%€{jÏCüi~[ÜïqéUŞ `/°ÏÅÓˆê8‡½wöıÅÂş¶ ?Äƒ16D—û˜¶h/4x¯-Ñµ|ÛÒ\Õ™Ôö3~2Z.f)O¤ªÓ&”z¡=EÅmf¹ğÇ‰<ø¾è>lõ÷ŠåÇjµbÆØ¹¤¹ù[':#õTê´­šØ¥±pÎêz#¢¹É í?¢AË=(XG3Å£¸7sE-`…?µwÒÄHÆ½¡ü8kÿ˜•”)å·§©°á#àw j*Â³Ï&áa?³7ÈÃÎhPCk”7Éã=•“*
Ÿı¿œ)şµ-¯<½ÿ>·}<­#cùúi¾.$ÂhR™¥,O8’¯`cÿW˜¾.¤Ğ¹“á¼#ÆàÊ[G–|İ¨Ÿ‹	ÖÑü.½0)Ğa%Ê©:Óï¾W?NˆŒ{FGöQ‰Úüœ)õBls›û ód‰–%+è€38ÅøÌˆV
d»ñÍ“¸æöŞJÒÛ.Ç"áå.R¾¾ä‰ÿ{¡O§H›(¦«šeğı_æzgÆ‡µëÂ!éIfŞ?ãÌg+ç×½ø		Ôˆhljj6¹éùm€´hşkQt ar¦m¦m¸	°ò¹½õµuò(š²”ØEAk=éúŒOD¨†]G8ü)Ğ=O-šÑ8Óß‚€½¼åî†m+Ôñ(øß†ê3—/¸WY™nŒÔñƒªİÕ‡ŒP'ß²5tWŞ¢«Ùp{ ¼91,¬ hË&‰0€(#Îq3 <VºöE%’Of!¿6êpêõ7;¸ÇëÕ÷ÔïO3Pê‹¹l×ıÛ«ÛáĞpÙ$j—æ´O	­»Õ5„šk¸©Ó<«Gş#Á""äGæmÄnœš_©}F~SWA€ ³™Ã [¸§Ù¬éO…^™8ß1ãx~“µã‡kD(Ñ>M‰¨O{™h¿¯—N3m¶ñ{ß»¨9 Õ*¡˜)ºBe
é£Küì29‰¶ø»|…B8QÿÁ5á”ÄÁ½ì,7¹fõİwÂìÜáµ—mêÔaÃN+s…-ÿ.Y„œDˆÜ×š³ç7Ãª–B,•ÌH¦ió=GT6<ÉA’éñùÈÚÚoÎC^,Ñ73kÑgt>ha=:–Z*¼·?AÀ­H­”k–}!Jê@íúĞIëØº¬ÒAğ!Ú­ƒj6=tiÊ­|™NÃN¨ş[{MõÛ`u+ğve¶˜ ‚”T#?àíiòDİÿì?‘˜S¹7ÏíT¬yƒÑÖÁ¸ù°ƒßz†1/ÿ±Ä6!4#]\n$åPÓòÁ–ü°ËÙø÷•=ÂÌÃ8€€¨±ŠB.Iw)[€…Š„(Ì3AÚÎ[„ÍAæğu‹K8M
<—J/àÔúSmÛaÚ9T”uî¦]Sšçt8/ºZf¹r¾åÜ%Õ:„æÍÑ—
ø§’³ÖĞiçfnap®KAË¢î©Ÿ´ÿJóae‚Õ¡¢øz{i’>7LÎç=ÇvşÑ¥İ1¢±2ªâÙÊÑÁÊÖe±0P@)_õ¥*Xİ!šÿ¥akiötF!ÁR(>¸m% x4?²•/ÅÍâpûî}…kz)åq{&6&FºF~+R@Š[¡«ÅkƒĞ|Ä˜¨fÜBõ=f#'zá?¨&-6Õ.ªi$‰ÚLx¥…†I8lpÃBŒ&>În&„>)y«Ç«_{Íö±*.ŞÈÕëb$¿Hw:N6bştW•¨Bô‚ ¬Q²Âª÷¨ÄL]å‘”¥ôÀnÍFú5èTĞˆ¥`Íx]§7ìPpHƒıH£R›Á™Äˆ¾õÓ^»´SƒPZÅ¾@'/¿±NÃ¾î¹ Tî?$z$ú;¦*®ôCëılà\-Émún×ùÎ¬oYæqê
¿æ‡ƒì@ïØ@( v¿_`?+¹whÖ3y	a&Ôü¦–…ËÿKöê¦û¯½U%%m~ó)GÚn%rÛ;}«ÒøÅ½Ok3Ù{P|ÓÂ[-ê±7RyßgÚv¤Ğs9´Ãf”èd´ÜİÙ€R‰Ş˜ »¼ãØÌ¿(‹d¿oRÒ¡üükÜát>æxœt%Ç@„ÆH¦‡æ­‚¬;ğV ··(Sû´o™¾a	Í9TNR\sïo„¨ºFØ/± Øzgª.’¸v’oÈ^Ä$ l,ËG+íe«ñ•Ór{rSı©ÃvĞëÀµ«V
à^'ŠIû`º»ÃÌß^g]1ƒà?—%¤`å–¶-evæÙè¥LÈÇD,Ó7õ
¸vN%B<î›ÛázùĞîÍ€m–÷@íòŒcO¿z×—ÙN7‹>½ær1EX©È0…›Kñ¥í}Ãª$Ó§»\ç|R¥sCzL¬Q{o}Ü’6†¥øQ«Ê"Ë	BbÂ?R†‚5HêİúâàÑÄßğßö#eˆ²‰Bº¤ M÷óvOœCWJwªîò§è¿â™–õÃö9ÕBçİQƒ/ùï´  Ø]ÆëœJ'y¯’PQ^•äÛÆ[Ò¥ù¨^'tÒ[¿¼Ş&›±€ë*›¿§ª¾EByŞi‚1¡nÄ8êSi*Ü@L¹ÌúDL2üBşR?ğˆZ´¦àÙzR/Ò)`Ãßäñ¦	;t/ESVItÎè ›ú
w[»dñu„”åÈ>ĞÎ·7'z8áe/Ü‚	µÑ·Ú •…ù­jÔd¬¬Â\¬•Æ"õ'ÎÍù-!„%dêSÌ«œ_æPOÂ]ÙrÒ!Ê)´c¸ÄW7	Çí¢TåÓ•ÄG'+ıMa¢úºa)îğqiã\q1ÖèU·û„LÏ[iÏNC&Ÿ[ªüˆ–ø¶.p/ëşK”ßª±U„µĞàç%3ë„,{#9ñ* eÎŞ)§ëA)¸Gª¬HDj~ıgeYçLÆÊÒ¤*£¾b*ZÔàŸÇ¦˜PâÍaÛ-Ì¡ª-‡’#ÍÊİg¥£îøøZrĞšÃUsUQKe”-9ÿê¸êüàeÙŠôÆ$uÛ—ìvÉ%@i4zÁTš'~«|ÛÁÚGg×ÚÈ {Ó~~fİ·ôÂäàßZ§¨½~A£@Z^’õb«C‰yu„átMjŞÖİøWW™Ï-ªƒòee<a+éd4™Â©~5ÉáÃ=‰¡OËÄCçd#¹Ôv'§ä¿'Øú€YˆÃ÷³–mî«xÆ;ÍFLÌX¶ÚÇsvè¥gŠï­äáJ¹÷€$íË)Ñ{3İÑ@%z©u¢ƒ~Ó?eNñç|Ì™û±Ò-¢“¿Tˆ#‹õõlû6îU:ùªŸ²ôçÁ,eJÆÙ/	5µŒ—=4!ÇÚØ$#33@KÈ×C³üöãÊ¶á–g¤;l‘}ñÊÎ´TbË÷)o³S¡Pv$éûâ½§PUê¬®çø^Ø·ºöøn¥ÜReç™}äÕO]Cñ”²ÔÎá§DÇáÈŸÃD­MfuHbQd_(Ç›­³LìËıû/#Îò/¾tOŞ@E€˜ÈÄq&ß-q4Bú!ß±Õ0]«ÊÉ—Åø©Qšnf¡l5ùÕ»€Ã ÷=˜hí›ÙRw0¥k:§UKÕD¼åù°Ë¡ƒqi§5lC¤öI¦C\%¥a§9KMòKÔ·+Ã`Ø=«f1èK¨q6$¸àTWÃ¥­2í%À8 |¾ëğÖØã5æ0šÃyÏåÃû¤‚ø§w§<[¥N]VòC:$kùà(h
cj=eR,‘÷¿£Ù:¼Oæã5Ô5ï‘ƒÿkì÷:¢ ÖQŠç‚ª|ZÒ,·!ø‚YdšêíÀ¥H½ég÷÷âäëæk$2Ù*Û!^Ô²“©¢×7¡Uñ‹«7úWí–?¤â*b±U¸Dº%t ·Ì:¹!q®8ÓN?‘Œ ƒL^°ş*â!§ê¥&Â¶ÏÅõ"ï¿‚İÜ‘–Âà“ºİ9`&µµ6^oSeÙw¼É¯¨-È¶R¶>°}Õˆ˜gâ9À”ßøíjÉ¿d˜ Hß3ÎP$ÏCƒå£=•ƒñÚYÖkÕÚGœ®<`)L+—`¨qW†pÌ¨ŸmæMú‡µğ{Œi€ºÎéÒÅòò°éVökUSCÇ\ÅW‚±Í&…§pÿûJán
Gìc«10¡şª§.qkg{ò -tğºj^®n²‹_#´b”œ‰Æè§‹.%ÙòÇøôwÆ¼5ª:Å-bh-¨âªšTr£V#EM91½´šhœ.`3^³¤Ñ4i”<ŒÀŞãÉğ±_-÷Œf8wgL<:6’æ†wŠ,ı]T‹RU¯¨uŒË¬õp"¼zT:>êY¯eJµøŠ£çÍÂÆİõÑ"™ºÛìõ–óx»!bİG£¾X•[}4Wçš°,.Ğ\
„±ã;³€Gv‹nqCORzĞ†ˆêZ;ˆ2÷½øyC&Öq¿}3Ô_3q ]¬ş• Ìe¯íÂ¹›b!ÕnîS‚z(›8Æ¶‡@Æë=ô)
ƒmCÓi:\ª&’ó˜ÎÖ¸0Kú%1\éN{Úgë¬ğ¨ŠëÎÃñZoàU´Y©ÈÅ¡%âL½´§°Áµ¥?şrAà§d¼³3œì—F}@q¤¥Ÿ˜üÂÖ¹õaß³è=º@k»ğ'¨Y£íj¨ æb&™¼æ 
zI \¹îĞ?M)Œ5Ÿú¶òp÷¤>5¢¬ô¢²œ·)F6|Y€Èk?ÈåGŒ–zU|>œémeK×$e¾ F‹Nkê ë¥Qú¨?Xİl¼Ö7HLxC»»ÔVQV	!OŠÇ›	ì)	ÁÇ433ØÅàg-
¦4¬ÿrQÚqêì¶Œh!)Ñ„1à>•ô®áZntWß„ƒß¡Î=õV2ĞMİDëî İµ.¶õœ|U=WXÍlLVùÛ²vÑÔ<o¦ã‡àÈƒ›¦ÃŠ‰£¹Ñû#±ã½†®?û‚ ¤ÏÓ]•}{çÅ•ô>Cvö&AÙ4¾iRÑGê½ÌYû‚#åÕ
ä|E êÁÎd«³ƒ_5¨yAP&£Íä¨Ù\ßåD$,íÈÓáL<LåÖpŸº«c•Hhaü¸D biïPŒÑrœ¶> i2³8ÎË˜Z¹iÒZ\Ö	íwÓ<meKW÷~ƒ˜ú€ßàı4üÙ³§)ZÁ?­õÿâ(3v¿X´»Zî­=Óp©°<úŞnÁõkñÕz÷ËnİgZ2ËoM°mÄíß|DË9]êEº»ˆª®½TR»Ö}¦5¶Ó— åco-¿Ez¨¡
µŒ‹‡ª·/‰Éõ%®lÂSYk
ÉO‹:•{ni•’mÈG=Ú™Ô¡  -N`Ç-òÚ24ÇÕxó·”¶ÊTì¸Y’m^g¥lĞæä›£<•UeD_¡C¿½‹¡5ôúYPÂÎ§-åeƒïî*/ŞŞ,c[ºOF‘g¼03mL-uÙÚÀ#ñ *Bñ„Ò[ßH'zÏMµ3²´ÒÕ­hnºö"”Jeæ„´QÌ•ˆÚkô¡B …Ó\â’† ¹ÿ±ŠÀ³ÇvŞ(Ü·Ô©<%×Ä|rìü"¢Ç°F÷Câe,øƒ¸Ïêèq“}]†ä8š©0éøÜ§´ñÎëÚ’É® ¿iÁèl~;öû~ùf@<_ä ³²itI{®2›˜ÈÖ©£Pp«òzb7ÌNåZDĞÑÆç±J8y°^aV9İ{'êwEk0€Ã`õ„.R\İ'£˜«]Ò÷1;4y/ş#ˆ­6ÔğØ6MrOÅ|)BQÀœÿcü<wå²Í	
K»mô
Å œÔPÉª#âv¢(?«*iÌå×PÔ«²mÄ†5P–ºî—öÈÁµ.ò>Î÷§½öK“åÙ’UÏów)8¢JÂ¡¨ìâcĞĞ\ş^^RŸq"îiW|Üw3”NñLT›©·"2nÜİbÊ†½$ #Şh†=Yåp$"µæ+ÒÛlZ‹ëjI¥‘*yGÑÁú]¤b¼şjøO#Ñ)ß¦õ’»ˆ**íTAŸ¿°ÿñã0a ù?a(Dh´êğz½o#—Ÿ;ùŞ6Ïuàzbç UiíÿIãÂ(Y¯kûKj»µöãÒa»%N¦§éTøm}ûÙ†f¡Ë„=Ø™á8x|RY^ê]+ôs?ª,¦9‰^¨O0#õ1óàEÜ‡–ês¡"¬ÀM¥V/@·A?YLxâg½¸<‹Ñ­•½£gÁlˆÜ”mºRÄÂdu’Ç­VîI5Hè\í¡Ó^/AHØ'0ÈÔûG€¼„Ö$@O>Á’İ-ì[ò¬0¾VzyV ë.¢k~^òíÊÔ:Jö¤†Ñ›J¾2/‰õC:|Dµ})øp0Õù‰z!øÔ†§XÈlõç5céêĞ@<ŞrtøKâ1ö='@‰î^6:\!!)9‡pú’'VÊÔÇ²BÙLŠéV`{&†LùÒ;Î7Kì yíšÏ3ëõÍYòjĞ}D2›%³İcÿmbÈÊ˜	d²ı[˜Ñl,+à ò£/mØz¡ìÊÜİc÷­8É~Q³¿ŠRz
^–HthpV³@k%c,VäX¤kn'ÛbGí°¿»²½€ØB’¤¾šœ„àú’ÕÍ{ê4§lDnRÈ®ç„´/O¨
“e>Á€Ñš§Kì¬w%«àZ{¦""Ó}]„½‡ŞN¸ğ¯Õ±F°LºÛk™´Ñƒ¤7+Òkq,ıËèAlv}î¥I!àViŒü”gê•ñÿüı˜¬kƒ!^rœÎBCñ}€èê^Ã¦Âü“cÃFş/	o®z¯.ÃäõîznÕ&![='¤Î{„„Ek”J3[s2EfêäPFš{9M™Ç»Ùƒu‡1f®ğaœx.ŒuâÃ#5)¿ò:7ıòš™ï}‡L5xœ®H«ç0™5'Ÿô$Æi„°±e[~È<]³°'û÷Vt#¼õ?nJÓ1„îRÒ…¦¬ú9‘×É£¬Y» =™>¿yÁ>Š‡Ë]§;;ó’:ãİ•û»L=ê ^Á°°‚ß‹E{	e2

Û›_ˆFÖD(b…ş*Š;BcÑ8Òfƒ°wNøU0FŒò§­HU¼¦ØĞ5ïV3³ıÚÀáÅ+Ã1K[íÃxf[E{<½ºw•ï£OÈØ®*İ¤óEAÇê"»ºÉç|-qm¤õˆJ“]Ì²}<"™x¢+©»¢Ø“ÂÅ¼…ÏÍ©Yiædç¬¾ˆ©BÅn51
>îŞëŠz½üÎ9$ÆAwöÈDJd{i<ì§^†O4\ùùÃb¿æ›Q/t-¨üñ	2ŒIL{s+p¯9;%+Û şõrS¡”L_³s¬2ö ÑêK²JwXhó ¬u%®è&}QRŸob»Vz®Â;{ny6«ËVÊPŞÂvúâøîxÈF¢ù€‹M^ºëjëŞÑ.ı(›o/ìb»Q¿âÜ’^9äêT	Q‚¢¾.:”a{eêúÑx‹uú‹â/dS>L¢$®®q˜6ÚøY"Ï0º9Ñ-úÀsÀÓ/,¹ˆnºŒîGœ—ÓàŒmS=ì<bº­ä‚!ÎºwÁA¼‚kæœcè*D¥Îê+ªb¾^v:»àõ]×‘zj\Ş°ı¥“¹Úó5Š¢fÔ&îÜ²YÜŞ*t•°0Ù¯G­ëÔ1øI2â-Nµ­¨°×U¸«fñ-lÖ6DvØÎVÂT–A·‡C¡4CLm|òŒAáXºÍÏØş"ıÉ¹ëhû<¼ì[)ª?zt™´ËM >›áCŒpKr
ú°/ "à(±Ù9Ùr°á%¨xlè=m£şh
\ø¨{×‘²Æ<‹¸n<8Î| 2±‰Åo?7\ª•,pY`!ûØ¹•:ÌÂàKü¬¯˜€wc¢EDŒÙ|ğË,¥’ƒ9âD
œ¥•’!]z,ÈÄ	NZ—İK}£3Ë ò¯JşÓÆc'™6¬”3ÎZ`($zİLèæ¿bà‰”j’x®èç¨Fv^V,ÆtËùn`”—jİ«ê!”27a¹C·ªóÁN7‰?"¤ŠnTÜÿ¦€ˆU¸WÃ˜¢Ì…4úqü»!£¬n’ùÔ5ªAp	«»½±D6#E7©N’çooÅTÓ¦ à¨¶JÈ‹dÌä.Õ~ EG^§‡tş"ãÁNZ´ô[Á¥VgÂd%¢§u„ñAÓS°ME›J©³µ[Í80d¸Ae¯f·¨Nú|„f£²‹:Kì&¡véùMrM,8á×TºXJjŒÃ7=êu8­(şk¬É±õZq³‡^I^-¸ùÀ¿b	<;SW¤yÊ%ÔjR.ı¯<@Ñ1‰/ªÚ,y%3şK„	Q¬¢JÂc£>î’jäP¤âÕX¼UsˆZ¯¦Öş‚Ğ¤*«ğÎ
wİ
BFª¬Ïç½ ÂúCi0A¥È‡@$!º©°ÑËC³m˜ø‰Ûc×‚‹Ï|Ğç]YNòäÁ¸ŠÒC ÍÓ…K€­90vYŠë˜ÆnBÈÀoşç¿Ø±_Sn¹^PmwĞTR×-ŒÒ/*¥GTØ–‡EŒh½O`¸ü™!o,šÉ¿T´TÑ¬*ó¢z`upwye¬üTÙœ¤7ãZHì¯¨Ô¯èÄâÏEúl´óâ¶§ğúŸ1¸©~S¼A ¢ÁW-[·ÌF<Eß"?z}ç³ÑÏW‚"­h0ı`Äó"­ÎÒ–kï€vñ•˜núKÓiHŸñƒYjWpã;ÌìGÌ¨
İô¶ƒ£?fçU#ItôØáïŞÈUv­UM<»­8=ÓpÇÌÁ‘%ıÑ´¬2¹ªò˜sRÃ‹P×…\Ò'‚+s€4¤Š•ò¹š™Şš“;RZıU ÌNØn:©v»ö€%ğ0[éWÑ;¶Ì6‡n´´K=Ñ7úN0¯×s\Â¹3¬Í|¶%(¥T“ÇÔ”Lñ„/€SÌAnön8»Sƒîš“Uà¯†K¥8´ß»+Ğìå\ÉÃ%Í'–~ïí#·ŠP—‚ÔD–ñŞdœEMÂpe)uÎ×›ÏJ:ÒëòXŒ#<4Ç¨Ï-ù““ûŒÑY8ş:—)ÖÂuÊg¥¸2ÿ•n¢=Ÿ–`;]9ãHºy³ ÊGÒèS‡üXÛÚúğnU+§÷Îú2‹ÕóƒİæTÙ>"şªŞ<‚í• <,0`)ÜFl°Böİzàõº5U ja¦›üíõ¨ç}2È·İ3öÑ°BGÁƒ&ş R¨ûsßEmò¿k€t¹RYiÇjŞAzZ2ƒ4Rêäµ|ûº \ßÊµŠŸË«0Õì5|¥ tcŸæV¼Ï‚Lû¸ÛÆ¹Œ€6vkß71vl‘g«D¢!"à`÷»jn`¦ëâWÒe³Ş±k®Gn…ãŠ
ŠsA°ì¬´ÖìbO#ÈóS<"÷o+6¸6üj°Ü‚5É¦]Ê§‰£QHaQ‰²_-=ÜµÈ ´#LNÚiQ•QË™dàê$7¨§x;ë×°eîšsa‹Ú»•Ö› kd…3o³—e)g–Å§ÛË]ÌÔİEË+GZã°T¸šÒ¿9^ÜØ Ş ËL¨ó:&(•Í]w#æA ·,îÌŞ‡¯iûƒ¼ /¨]¥ÍÎ±»*î«”Ó™3Ê;ğ½H)ÇÉ˜{×sŠ'IUÊ“¼¿G¸ºÏ…Ix´ö—ZĞÏ`õ€Şè’všÅ¿·´0EJÂöÎ‹ºéÒÿ“¿9\½Æ'Õ†Àô‰!¡˜èh1_'¾Ìè¯¾OÑH® ÖIÛ lûò]7³s#K1g@÷†ImÜ÷W›Ï:µv#V´½Òò6²„+óÊ*’óx'ÒAkÿĞ%=I£md1É—~1ŞU»\Ê,à²•UÚ’JÚUÉÏ„zÎ!ú²EX¼¤÷0®Ì»û fÊëµ¡¨>!@&¦mÒĞ’uì·ï®jİw•ß<zÙÕUòQ2!ºÄ×ÿ˜P>´ ÇğÒèRuY"ÌEr²Ä›Ü0è	Xjwk&–ÁüØ£Èd]ò­ú²½Ç_Ï¨äø[Ö8‘@‹B´,BrİeøãŒiæcÊ‹§Q±zæó­ßÑÁg/°ØtşÊ!FÀŞ<g«è`ë
_G~}{ŸÂ;õÚÖÊõûG†\»µˆÎõˆ`1Š"º¡ÌêfÇXÜÄÓõa˜ı4Næ‹Àa‹ô²xØá=ùw®‰E’ƒk|ïL˜aÆ{P?#,ŞUïÌ@e¼@ >TŞ¦òGï‹•N[ ,‚ÒŒ€èJòó¾Ò%@D3F_[Ä×-Lç“…Ä)ñ±Gšc±¼âg(4Ã|„ö!²Ä¤sÔ¨É4¡všx£ °òîÈö,-x…3Á°½n|;öûÊIR?ÇÔßX«MÏ<ÖFÆjãıÖÖi¡‘$ş2³QBÃçûÜC·ËnéßVt/AIxÓ²P|/ë„ çâ!¶ÿiàR´ !BÖé›a
Ê7AäeĞ&˜©ĞµÜ7}šŒkSêl£ØXEaX şğÍŸÏóo½ Ä·`»„«ÒZú=±lB©Ğ2ã³’	¬ÒDœ¼¥D/£UòÒ¿­O¥Õo{l.zb7o¸™È»h[ôÍ	ÿ/b¡Ù‡”ğú”Jp R†ZzHf8Œp1•–‘{ÿôh˜æ?r<RàÛ$%a#MĞ!äi'i6	³3¾m_³è.)ˆ-/…qİG­c-§ÿü-÷£d8”›Ân˜}í3Á[!%Gö÷ énšÿ@|ÜîìT<2$>µxÆ[Ãğ€®ùw¼O<ÏLß#UX!Ìëg™¼êÖjEtşl]{¢5© ´çO}+:sbàñNv ªO£íğ¨õ•/OxRp¢M÷(qW½`«Gô{D‚NK+Ï÷4±¢«¦³Ï{4öº¥Ek&?çR;&P÷qÄ®úí¸ØM¬]¼å„=r#X¸ŠM›)ˆ…°ğ›ı)œ.8W9'Y¥â	nTˆsœ˜şÓ¦ÿx…ìÒJ6‹ hÍ‘ØîjÄı|h×-;l	¼$?‚CmQ(,oò˜­?3ŠÑ=4xà¨RAZ—£,ÉQ¯2û®‰ƒáåNµt4æyÊÌ%¯ˆ"3Ô<â–Tç‰üëbT¸[j>…™7 /|	Á¡Pu¢F†ÛN¦"|A~Šò(˜Äk6>îsèókêš'‰·Ú SÓõ™ÏÑ·¨³ ´q#ˆc!/Ì7–·2)æ¢2P–p!J‚ôé´H ’|º€Æäp(pÛø]SF‚øQ½‰¿—±Wum=1À¨3M)~÷…Ü}â)qEw›oÙ{ûäD`£2+V– ø¹1X
«1S0oÈ1IJ$°|„øSšİÿ¬v¤Lä$0'0=®˜$Mğù¡™Ó´£…ò³bF}nUà¼4 âüœÃ7•ïuá)^XŞ4Oü&€Y•$Dœ$ôÑ°â2Jp²ãï£k^<<¨0ÏÒ®Ø+> [t'\G"KØsì‹S*ÇrIÀáI#äßRV­:wAlÒLË†#|$ÔéÕC•7v”cƒÅŸÉ*:ÿñâÇDje+>²uœÕéCµcŠBÌO™e§¬p†ìG4p°{ ™5©`uF-HFyxhzë1ÂÔ„JÙ6H Ñqáñéîho:e¼»]Ïdpø+ÁÈ;ˆè§Sç{cMˆPvQŸòıßè¾Ë®õd!1æ³¹ãyRyıUÍ­ı‰šÈfÀ¤³œ·4R¿Fj%½-òŸ~ÎÌ<údÛÈ’Éè&d–~	÷¶ØRÃ~ÚaêÑgRñNÀ(:Ç®Jäì_!bop‰kÒ°©L°.zaáLg”ûèíO!Zlv„šoødß‰—›å¦dlá†Øğ ²0ó)}>5@»µ–úšÿ“ÓÎOHqÁÎÉÒ¹ŠÒl—mªMs’]bªù†VíîØ]ôÎù?Mº}£gó|Ô‚
HY!c8uòÌ¡hB¾J_y“ˆ"ãƒ xí9­¯8RRQ—.f¡å×MİøZ&ØLO@X]z0ÖÒÉ-µÿÉ\ÆóF«^Ç_fVÑ]ÏNKÏ¨äª^>úıG‹j“±åâ-‰ieWÑ¢ĞîOíÒiÎ>ÉÊtšÿÏŒË‡;LùJK!
Z÷6¼@kQğË<5@”Šq_ƒ§B#z‚¼»ŠÁ¾)öYyÈÁ,è‹)46f×&”úˆ02¡ëB™¯k ¦•å±_Ô3ÖÓX*¹bñéöŸu	x¹c·úËùCBI€ş—ùô×æcšŒ¬“Üí'Ë·³¯ı~DÚ2Şi¿Œ'7V2îŞT.‘(5£Çy93¦Í.o­I#™Ëp.u'Éaî Ù~¥r¶8ôŸòE’F&>Öû)(ÅçsÂ™ğ@€÷ŸrÇ<˜ã’‹¢Dñ­j5~ù‰e+ænŠérkşÍ=^hŸ²Ô¨v…T‹¢|3ÂgßOeSªÖùrĞ_ÆŒzQ0ÄÀpÒC½í6o)$åV‚ëä/ƒ5¼åù<“blq„x‚D‰"·F7,A*Q·+çú	nÓWËZ­ôPqF–Í7*ô˜°k“KÎr8´uà[V–ÍÓïy®ÚÈÄôÀ^û4ÓfñM¯DGšâ4h×ÿÛ÷ 7pVåı›» Œ¸€À£}‡†±Ägû    YZ