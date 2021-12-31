#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="794890845"
MD5="d8d107d486f6f74ad2d607f893bbd432"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25804"
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
	echo Uncompressed size: 188 KB
	echo Compression: xz
	echo Date of packaging: Fri Dec 31 00:58:07 -03 2021
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
	echo OLDUSIZE=188
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
	MS_Printf "About to extract 188 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 188; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (188 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌâÿd‰] ¼}•À1Dd]‡Á›PætİDõ#ãäĞtëÈLÆ"*¡çà&³¯©Ç¡Ooşÿ…_Ù‰eÀ¯¸ÊD,AV+8:F•2­k6²:?éOÓËg&3'jPMH“m]yúâ’a3¥tÏMÂbÄ~Ü·BÖŠÏN–L_ñ·¢ÉùÀ _£.±¢Y¸«¤rñXÒÎÎÎœ(kGJ©mÕùm»+ÿı;Ô3BÖwò°z"@GGMÌOá€~°íÌD#)óèªPxå¡‡ï!³èFEàZK¬pºÊ?§ä±? ¹C?tfÆa7ëvÛD„zdìi0pıgÓÙ”x©Ò˜å¨ZÿÇ'6{!ª^LœkÛ=¥™Mâ`Û "oÜğÆ h¢(*ğš_Íˆ²m˜ihdLM¢ÙsV€4=ı¸>‘,®uî^´2%‚ìT.(›{z2¼8ÕìPb_S>$à"B6V†ñµ}íX»7_“”…Ÿrø&1T©E„{HÏ>\·è|ŞÊ"xXÍşÅZ‚¦7ŞQDÍœ…ÈÆzå\÷ŸQïVX•‹İ¬¤ÛGß ¶Å·Dºu†äéÓˆDÉGkåŒÛˆ©î¹[…É”vLè³ æ*ÍEzxLü¹óãøtŠ€<.°–Ù+oÕ–­iÖˆ†º<h…;¥Ù’ÂÄ 'iÃç¶ÏØÏœÛ=Í€héVüØ²§?(W>pTÆˆ„"t¹g`*
øµkì
&˜&+²+²¦Áòëî„ Ç"Í•BÙó¾`z jùêÄƒ‹_÷‚„î™f¡1…ÒC¥%gMòÔÚQ¹üÅ±N+Ã~ÀqÎ3å/˜\€¡ÔüÜ²rä¨Ô ^­¤ö 87\ÙG¬Í¥ğhÒ€y>Úx‡ª†Uô®Øã'’IÙ§µ†õH0À¤•Ô·cB n,”´f"ˆÕ¢ıCîòJ’ıĞ ¨?¢äŞÀR»
³Aà¾kŠ¨ã€dc¸¥o"(\‰3´°{ŞMb03‡Yÿş ËWšU&u”<™zfcd~'‡°«Q[Ááo‹J7Œ|°ŞJ`Ü7tvâğƒ¤r}7ñ,p ¡ö—ïfLtg°[¼ÓóH÷&Ú0ÚV•–+i;ğ+[wp…ò>°CX"É–Û!ÇâS¶ÿø^3Æjƒ;Ã†â³ï…æbÛ®äı¶Ø±ÛJ˜çüŸ4 B,È!°À2èM×¦ğpoÇı_fºë˜Ê£PJó@›8ëÊØ¬‡nìSÌì;
R¶B®ÁE¸¤Úq†xBz²R©ZÈcÒ™¤•FÁşî42FwbŠ	H‘K8J~J.ŞöZìºIg#áJ’$ti8x_¨GâÃ†”™µ4"WV©­hÊùT7ßzå®µ.¾Q:5.¾$¨Ü`2óHKè`šÎõ?*ÉìdïòWöj,èOBÊ &®ès6W«"©÷9ğº™ÏÒl€—%W!ç3¥L	Úo€7WaÏ»¨dwn}*’v…Jìi›°İüÉÁô<™Ñ‘ÎÇĞß·#)£Ÿü‚7Ä£¿O}]ûíİ¥ÜÑ8¿²œQŠEQDÈª&ÚKÂskÌáëƒa6¹³>¬EqnM,¤kÚIIš`ÇAEtáUSÂvN)8}
*’Ûª¸ËIÌNj[Á†²ö/ğÑ3éÒa•D´ç"Oé;’8x)`55<‹Q•Ö´ßÊÁ$h‹Aû¼Œ]9µúöExI9
¾a¿Z­ßx¯ú±K™l?*Ö3^T4{®i`­/† FMtÁRÃ/ößªàèÇ¡ÒâJXô+ômË½´èO®*VÇÓ†¹˜´ß‘íKâ`MQS˜âD]„U|Rœ1*Q2­ìl¢r#Cî—óÁj‘S‚múÕ…;Œ§,|Ğæ¨gMİši!ƒÁI`¡óÒIôñ~×Vq?O§ãB’›ÍãõÚ7º~Xeäú·9àÌ‘`äxaP¿ùu‚S£…«O¶i·	U·¶–G„ödü¶DŸa¢ºôßešZ7 xEºæœf‘ÈæóÏ5T?_Cœ¢÷ƒÎª¡€2•HVÊÉû¬e¶K$®÷$ç*8\şEœ’]fjƒL@ÊX±ÀáöLíÊÉu8ÌüJs)<?´Ş¬Ó.Ç€’ÆìÌz	|ö¾~À’ı$q4å ‚_|¥š!şa6Dr¿ÿzWß‰ÆÑ\]ÊCÕ>»ogb{Ò¿rÎIæ r(œF»'Şµ´{ Í3uL³4ûTÀš[e?)µA‚Lƒº
Ê¦ï€
Ó¹Açìõ­”å’fUÈ8Ñ-æúÿöÑşï€¬\âŸNÈd»-ˆàJÙ«s°“’pÑ×ŸĞr«Ğ¤2z~hm•Hé4Ë%‰øšÀº_àu#gÄGıù§
‹”-—Ù4QÉ»ÜlQÌèC€Ú4·U#Iè¦·ÈîÎTK²œGÕqËIíL†ØôÃõ¨êß1)J%ÏÀRÚ³STğ´{"9‚š˜[ªG¹—ÂÀx×ŸIw¿JpKsÚ0Yrşâü÷\©MRÙ
¡ 2U	ÖÑè·/˜?€wt=0ÈT¥;Zkjdª(X¤¢OĞà÷ÓG}¼F{ _2lPyøL.Ö€bşÀ7Ÿ¶ Ğ)#+}«*ú’t82ë:¾f¤ø™<ùGI©ÅÚUƒ›c0,dı!€¿-~'÷ğá­s@Ú>ä‡öÉ ÍíOÉo2#geØ9¿µJSU%Á"zf¬­6yçì®gü}§‰;R$‰àôí‡*]˜­›ŠÉJàDo&ËÓ03Ğ_ìãOWGtÙqgcoß¡'ûÛá™X)	Ôq´[NÙ´î jAÈöË#D„ªgåL/6¤Æ`Av:)Ù@£¿V,Ô†ÿ,y–'AÏ ¼Ö°¥èñØÛËØßş¶1Ké#¢ÀmĞ™:$
8ãÔÚıLÛUI=ö“äƒ6èÉãtmÚxØI\‡iP’¢ O~ëW«Çv0óz`‰hçÛ§é(šhµ2à‚ƒŸ†,gt$
Åà@’ôKquæ¨JÃØiìç¹™‹¦ëoèv„”¡˜•>»kËu‡y +<aá+¦Ö»pAƒ§Ä´˜wãC,G›tƒ@Üª6Áêjõ`ÕjZ9?IÂbuã¬pL+ÀRÖ[$¢±bê¶èäêp25ìÄd½å‚èÓCËŸQ1(úIŠ¨ho75YPû­Ğ ”7{·øwûFİª‡jN…çà\vIî"áGNÌ»ÑÙhùÁÒÓlçâX×;/l÷¶è+±Ë½Gò($©ÚéãÕCbA£ÆQ'÷î9"İ^	ãw†SL,¬¥QFÙÉGk°šîÊ•êæ¢‘Q¦’Øw[ Á/ÚCÄø»o¯)µÉŸ_"LäO½&ædpÅJ¼õÎK1°H8»PÇT¡N¾Ø¿¡‚Œ4#?6Âqã»˜:ğQ>z„w”f%¨½©8ùÔTJhöe¥ÛlN7Pi…ùkÖ¤6¾L¹ ¿õ=Ç]•*wÀwrÛ©¡N>69cÉñ.ZâËõŒ*kšöÀC¾ÛÀ@
 ˜–°hÃ Âa'w¬mÇXîÖ\¿eV›_¬o´GÄÒ´Ø—`?|Òd_×ÏÏM™Š‹š6¿¢ÿo7£1«Q”‚ˆ)ÕXç_7¹:ÑèÛR½S‹4[U×I0ÿ@7Ü–e{ÕPÓ}Pƒöf¬‘˜‚ø´“¹ÒX(gK% º›)Ö8µRÚÄŒOù¢xŸÓ‘Ö¨
T)»¦{0mLÅÆÆ­É.‹ª	
èµ2!qšÛ4åAT}K”\9…™ëøÉÏïbë—“º³üå	OÜn@Ê˜êÕI3‘µ¡•¤O.µ“	íä	Œ^ì³ÇÚ‰Şû…]**Eb›|NëÓ]S*LSƒC¾„wVµø•¯à,5®b-1wİ4UR×2*åÓ^³À»†{YêA	pËgìDƒ¯!ã—¿ıé
İº°PñùÄZqöi>c¾ç@‚T—³ƒmÜĞH0‹ê†v“ÄÚCÄgÓ%@–\¸qûü}7stLÌÏÇPpÏãyDJê—Ã¹2¨|k¨0Ê­E¡$«D	ˆ@Ù!W‰¹ÊÚodòo9üár-ï¹|™kA_è¼V*ÔŒR£¤ÙrØqÌ{ÛğWÿµu“c`(&îkÔÍnƒİcªRIô*~×5+IæººÖß<uÁ—m·ŞiYãia’ÖïÁñÌíª/R„ìtùª•*Ô˜÷…=i`­8LmTä€«Ï¹Á×j kŒgi5ŠNô°+hÖ±Vª™•bC_
ŸĞô¡+ôjBMµ±‘4áº3z Dºënä;Ì ]ëåÓ²–sAa	¶Òc%çfŒ>À?
¼Â‚·¨Ã¥6.
DÈ	_Î§®S×Õ[‰
{ç³U~zÚ®V\Rn‹(“Áe}B¡Â67ºCÂ‘ÑltëÙh¢0/şç.°ÉiŞ4ó°œ?y¹_4`¨oò^4Q¼~IF%¬Ğâ‡õŞ6»M1 İ7|Xûµé¹i°ôCÚ,V8àöëaÛ¬x«œ.*mågxşwLö—7­STUZ‹šû‡Æa¼à’¡å„B¿!‹–)1oj¹Pe×+lKÿ ¸éÇN”ºÖ÷;ğ]“âĞ	ÉèLmK ¯c8u¼uç‡ÿ6z"®Z¶Ì&JÚ¶+1xÒ<œ3ú¦‚<ı=K›åÅşè–/Azÿ[}°ñĞ=R1ôvLN

ÓxÉâíS lÏ÷Qú›ŞªçC¹HŒ\´ßôâ…³
›{?yk{Ï†  ¼ÁøB§ñÄl{îè«1æÈgoQl9Û[J#¾ß	Şò#¨5¢$À”Æ…3Ôy8ÙçË5ÊÄ_:m}áwhIpY\lu¾ùºÜ\BlpÀÄªW‘†ÎE¸“Dê	vÃp¿üor>T¸Y‘]÷ûg½G˜4ËÔ" 7I"éZ>#º×¨ßÑåïùCBw¹åY-DÉÄ’ÉÁ.´crë[a“+,ª‡˜l°Aº³¦Ò%GcÛòrûÊWªbu@Õ¬ÜıêÇÙÜ=JñÒ5ß!4%¤‡}&ıÄQ¾™{æ&OXnúv/œç¯ô7ò¥ÿ]ØgÖ•>â¢¡4pYã&N/Ùl6¸¨ùûª¬Ä€ ßÛ[\BmL‰¤ÿEüÛÄ]9{ía‡†[™”±Æ«À¥/g½8¬«x^kgéºHJæ£WKZØcBk?¼ã1
ö®¿Å;ÿj#g÷»¦`'‰G¸ïfVréN\ŸİÑØsª=0ö™Çğ8U/@q çpª‚,’£Q½¼l°É€Â;{Ç3È$À¿À´‘+5‚%´¸¿6À»Ø¢°Y{ ş)ƒ
µT•4Qg‘:©LÛœ9SS*DWFQq“iØÇ'VO†~ãØéLæZ'ÈJäüÆÁi…+Ôe›RrÍà:ä¯<Î|rù˜Ây­êı}F¨Ê† ÌU×sw›~ßÔ­h‚„ƒãé^\j,*>o,Wvâ‘èB†¤üOiYaŸ9åÚú„ØháíI5vch´¯¦°!—o2×îßù—Èh±¾2ım_8}Ï¡ámhkÓù¡â‘Ãâ¾A,e©ãìæÜ	a®Æû
óOš°nìŒ*XÒ“e¤ò4{0úym<‡F\]^4Æ+ÃÔ ‡®X$°Æuü,p=çYÕßÇòU DxdxRÏí™ƒë‡¥êÒ8„9+¨·Àw	GŞIã4d|Ö[şbbV§nÀè“¥ÎçgKC¥·]u½_U©ûÛ!Ùˆ ÍÉ(S)ĞÂQ,ƒ4*ø_ôô;ğ¯˜‡îPâ
YÌI–Qéó½1˜á`åì‚¦‡VÜhÍNVRqXö©eö–ÍÓêFA»õ«a®"ĞÒ§²’Á½¬%=&èNôJI&P³ƒ,<2Áº;4Çdq*Ò~5@o <ÕÓ³EÒ£”…Û
xË¤w}%Mş×šÔû„\§æ`€ì”Å¢ıÀÖ:-rŒÚÄôáîÍJl)3”óŞ}õAŒê¾)¤Ùğ½ôÆ;bwœÑ
¤Ü„¡Û¬Xu”eÛ‚<sÑèšÓğ I5'TAV…ì¿ßÅğ^YJöæh%Šg~ã¼Q»…Êó=3û!íî¢‹ï€Î2#â‚ÊŸP|\à>ûÏı§®³•İ¡©àé³-‰JæR^ÁŠäõn§‚6\Ğİ>”â‰§ ïrXÂYÉXšÇ»¤¸BÜ«d?^Öe:WµdsÉÈu{ÙC˜…÷Ôv*BJG‹Xv4¿«èÍÚÎªÌHˆæíBK5F%scCä‡cºü”ÈCß¢bu$¼e­z8É]¨;»õGù¾§¡-ğÏmï·wó, îZ<2eÌ3\–”EÁıc÷r¥ÈU¡gë9œPûàµşƒY”Í?ÄâjTù²sïjŞŒ¹ñz3½ï^P9Æ ò8P¢¨¤±‹|Óû¡kG_OÚ|:‰>.ş¼rëb¸í|$Ä1ü'ˆŠ!R{ˆg½Œ¨íğzC Â]µa«‚+_ù!æ=šGY T¼h¯À–óÄ •Ù°&ŒcË¥3)9Wfüİ jZøü²Úè÷ş2¥¨'¦êşyºÙ]lEBÔ¾ïg§ÿ-ÑÁÔhó|¡í à)§-–‘Òiª.×Å¬óÌÇxôõ›ê¹¹\ÈÁ†sæà¸ï¨½V>ì3îbZœKrU‚ÀDùVKP Ÿ&ãT—,î’Û2MÅF CI¤u\s«©’ÉÎ9ë±Ë!ü#Ë›vÂy–qÜ¡Ó‘ÁÈèS÷Àå$³7´~Z,ÀÆ»‚<sÍDÂ”Àíupù4L¢P´¥Ñ=€ZÁÓÄÖy.Ø¨iÿúo=ÔC1nI~èêó•b­Ò‚¬õ=’@Œ_óÌAƒ‘¦ì‚!‘|,ûaÇõ’ íş-AŞ©ãÉ7T‡Ñô€é¸’ÿx?UY|p<—m¦ò‡LÏ@˜ıÁşÒ~Zç)ğòd|w-;‰íÁüì‡°P:}7Iy%™îõöxáü;ßåjH{zˆÈƒÖÁ»*±‘­¨ÌJ¥õĞ¬‘ş ŒÓ.¿)«Â¾™óÉY:NjUIkx0”Ç÷Ûb{-M¥¦¾w®@]FëÔÙU[èJ¦ÄzîÇí¶2éş[]½b~ÊÁíÁÌNKâ8¡b^ıMd.ÆaÔåşõú”0—jí—ªdSÕ7iæÔUEÑ`ßd’r^8Ô<¨aÚ@,ZüŠt-î’óp®Òps”Ö-*˜Ä\,fŸˆğàŒØ°lÌP•ü§xZ°c¿£äŞEw	D"~©ß“Ôe?Æ$¿Jâé¦‡-oêp¢qZÊèÒbB!›kÏ¿¾˜ÒpĞ}±ôP½H+„^jŒAÆœ½Çæçßlø‹ ÙøëÎÔ¸wu+b¿®y:‚ë²°Íê‰!7exŠ2”sO´ü'pæùñXYxË.E9t XÏJ#SÆ4*ôUZ‡RÿÕæ—95±oör«çÂµÙ\`>®÷XÃ„¦¶^Â+Éÿd“9[TñÉ+i«;>ç‚~
²ı’’C>åU¿+ñS0“*v¼À?];şM»Ì7˜˜©h«cQÎ¬‚²;À';kïÛ!š ‰zğ
¿Ş.÷b]‡ªâ	6Çºbv^`êñæKâC¦2·†rË²AXˆC:Q}&xc4úuÜ„¬Æú
ƒvZÕO×âJ7”…¼“=è´Æ02­{Ö=»TúÏÑÖÈACàFÖî!OYvÍå¯ná½S/<:·¬¨M>¦Ÿq ü 7æÖÈ„tÃò£‹SEĞïxƒå†§®ôÁ4a:’ÆÃ£ßP0©'Y?œ“"ç¼Ä®Üs);[2¼ÙeÈ˜a¢8&àJ@=Ã–‹wíhgë½¹/"‡M±HKñ]5U™cì W	£ì€V%o4†>ôî#Åk§WòÉnòò[†Á¦ş~‘Ô”3DFÅzg…ÿ»Ö\<ÅFÂ‹<¾#sq«-tIóıá½zÚ³farÀHšÂ®RÏ§´²3¡§îDyà-¼Šgùõq/.İCÀ ’³ä\TßlĞØµí[ÃÇ°t?KàLœ}2F^Äoê#;2ú·R€ìÚ`ùÜÃ*	E¶*ˆ¯ÄL,*¨í$ØUìt¡{|7Œ0ïLeı™ô-Fy½Î%qzvÙºGçè|å’ºxÿvÓçYQ]¾È´×³¬’ĞpÁ…Â†Ñ}J}R7¦$ózù˜L‚!o.;k>~üR|æ]mèí«óõøˆ¿ÎÊØü¥İÜì º·°S›"…†”K'u.™…©«¯ğÃÔ:ÒÊ]ªƒÖ¼8"«…;anéœ£$o›¿3à:¹~¡(÷‹1ô}ˆT“@â0zO²·9+“Ef"\öø$¢N97Ïd°Û-£0L ½²Wö®ù¨4ë³G[2ÿ}"t¯j‹yæqÁÖÄ¤X~mÍšQ) ÉY¿"Rä}~8³rìgmŠö(!‹Ğ*Ş@ÀÚs
  *áš#Şm¦ìn ê/<´y;œ8¡Ğ”|6Ó&…ÅIkì.>—f„»}|jáÜek€=|†f¡&K³¶ÈÜú'UM·Üğw6.j¡îúøçzù†Â»Z†Uõc6ˆ¼†¯eS«‘ TgW»ˆ—±(S^G_¥ùÈ¥êÖ}µÁ6ßÓ¾`D|å“Q8´„–ÛYÖ¢±€MÒÇúm7îì7‚by¯yÍ	“f¥å)ôq"äPïtZt!2Ç¹['Äš“®e àöWqıÄìT¼İ-æ3kg)n»|•ÛAtR‘	ãrzÓ³n%‡3zÙ±ÏäG C?¥Ñz^&vèò*µxà²’ã¯±j!¡âª¸Ô=-ˆvªOS·­{ÈäLvVËb,wÁh–×Ã¤LĞ+ÊİÉ’ïÕÃä[H‡~ç4àKhHFm¶‹éßd`ü¤0lå»Y10M#”ÃÍ‡…º~óŒ—†øUJš›¯Áã¨Ğê/Û²ò½Ó³§`{ñö$Šş„¶™ı®>¥©Ò^Ÿ›eYN6‘Ü2›Qå)ÓÊªú\ßÍÔÅÈåĞ®«¹‘İÛjĞÁtî$V_b9èZoí€îâdŠá6¸U^.¼|@néX€ä7kã'0™N SËH“ ßÈÌ|½â?sÊB‡^‚].lråã®‰£¹Â”Lœ¾*”jdû×È€hÊcè%[Ğz¨çö@…-İÔÕOm”I-´5Áb1+,IÄüî5\•Ó1 YÊ-ƒ#JóYcØx™Dç§Y¨…#ã8´:êÑZw7gU&ğ=}°Qœ”ÕË¨²q'œ/ÍqçC\Æ9¿oñ
#.cG[RpF«Ro¿€»Úöëd^ËñRoã*ªêfğ5Emƒ«PT¡ÒƒØ§§”ğÚí9EÖoş¤¬=ğàFÌÍS¬°vz¤¸Õ˜éBÖ$¨ ªí‡:z¬póş‡%°VåÚ²wfV*®ñ`)iº0Kğ>;¶°çx[ˆÈY¦š´‰Û/¸:WÚĞªö·®üşlù/X	\ÂT-æ
•çÖ*N
8 ;–7ûÿàÛ©°œ?x{EÌ˜É[8†ıƒŠœh`Åì¡[âcfÒt>ºtj¢55…ªß»|vqwò–A£å17‡Hm)õq)Ü<@“DÈÄ{€O‹}yÌWŒ×TMq…¿†)gÛV(¸´6S}
·ğõj¹Q± ¥IHåxûü{µ¥œ>­18nÌ+{,¶¿ÔÙàxÏ=­›êõH¾7ÈŠo7èIú¼ÁØ¹KK€ª¹£Jì•/ÆShTÁªpİô4µ‡ñuG‹½¤¼³Ÿ)®á¾öå¨…1¨‚ÁHSAYº*<¢*ØÂË¶ÑŸÕ1|IdÃØØ3[LöğkD’ü^s¿ªÉ†‘J—bÉ´j[k)f£ÚnÒòG„¡HJC»û$F=†¶ë,œŸ¸ÖWµ¬´es¢®!bVUĞBÌï9é¹¬}ı5Ï]İÙ ºI8Õ^¥y6pyx:g¢D¡ÓP ÿœëÏOàZ7ˆ[¡|ÎYÏLyÆTNè M:Ò)…Ìœ	"\AÏ†ÜH{;å¨ôdş<¸ ı]Øã½ºò%Î|o=>)æÙQ8YÓÔjÀK‡\F´Lø£ì–/È1ÙÂ?`?‡Zææå!Åªùß¨p7d*»O B9½Y>?—ßZêÍŸŸ'ôÆoôİ%¹;aójYf®Î`æö§„L
ÇM£Š6£8ÖÙ-Ã1tË,{.Ëk-G!Šè…rÍšsÖsÖNQäÓÙW¾<(
¸j#ßÄ#iÔükE}…>p=€ƒËtÍÚëEÊŸ¯±I‘O‹¦›/í1À¶i	5Ôš¨¬¼J˜q¸§»Le;İÎF%[E8Ş,vŒ$É:Üa ‚¼«ĞÌaõÍovÕ†öl']JîËl	(æß3r
¢6†ò.‰·âk`Ø /”İ©Ê¡Ø;Ü¾¡xÌy3Šõ µõÈA%c¡3ÃñG!>0Œ[+”’? «azÒ&—LéD2Ài¢*Cš»ô2!KqvÙmUY»ßÿ”®FÔÎò`Ëséw¾ŒklŞœe#lê›Úÿ”Üºœò¶VÕW½˜†0OÌ³	`ë’§‘dur¶R«8\”'F¢õÌ}~XE«‰Ü³ßßDZ×”~NÆî8P8‘EZ¢àr³ú³€A2û0\%BÍ›M¼.9Ã ı¦Ôä‡°½ÚcIÊvÍU[
©Wía6bQeàˆDşºi'ŒÒ¶1z î#—‰¥Å«9¼Ë~‰Õpú«ÃWXOk}Iı¿º÷<r'£vÚ62j¸Ì7)h±|làòã·Fà»²B¶Ê`GÎ¼­Ey7qûí¸³«[ã¨ğâåoTOœNB;q(e.Á0ÿfàŒc) pECé»¿9±P±vÅÿ
A”Üqßì¡Ô63o!öØyÓ@ÎãÀ=Ûæ'ßqYoæ`€N€¤‘ÜxÕı•Ôm†Ú£Š?©ã¹ĞEıÎ=ÕÉvÔoË ¤]0âN,Ã}N+Œ	WxèsIÄöû³Ç-¬Wt·6,GÃ¼É[hª:.sY¸Uà.£L»í„Àhš¥{Kjàl,"JÙMÂ0¬~±³Ohšså[¡hE¦}t°œsÖ’ÌÁœÎ·Kçq!˜%ß4Ê€²Ş€Î[¹¯à¸Nôz(U,á°*¸~ÿsŠ)‚‚ÎôOÛµgFh|@!P®ĞÕ¨;Ã;†\¨ğpësá|ºxG‡§Ñ ŠED´ãß±¶K;s‘cHAp¸ ÈØ9º®£A^úOÿ,cG
.Õï‡Ø{pSç ×lîı
jÜÚ–*½DdF¡œïFÖFÖpšo4Z$’”kä¼9q–¬†	S‡oOw¿k#ğäIë{ÅÄóq†ÀkÒN¢ zÇT¦†eÚ£İöÃ˜‘ÑFÌ¦HF#R„™=d÷yîˆœ,Ôôuš† ¢£ëü¬J}w5°îFâgÏoìwàPV§%Bo~ÆØ½r
‹Ù{ÚÊt¶GãNv©ª>§Ø1(T)ô	ÇNßpÂJ‚`M?ñwö±‹7¢]V?ªƒ*_¢TxÈı6
~æ?@<@"(y£µLHB¥EŞFEYñ¶¾˜NZÉÜbgÈ ²¯ÁWpˆX-¡\P{.5-ä%o½z‡¸¬‘[¢V“`)
‘wYŞşgà| ®ó~øÙˆ«]•™:¾•q¡‡¶5ø‘WoÎ@	æÅIrD&OèV£Ê÷ğíç½…QéÁ=˜©JW ¸R”Bı¿äg‘×¾‘‰‹sÜxP„¬ß¦‡¦´®ÿwÔÍ
“QÊåtld å{†¥PMÇ+ÆÙ
œİ¹œŞÉd6s-"›–N›=TÉŸ’¢ÖØB—‹¾JUÏ3»Y'kòÌÈùÏé¯Œ›ÅÖ>,‹-RÍ«¦€Û2@”[éš¿×Jş±Uˆz6İH”{	¯¦”¹½:ØÌ®‹ ÅÃ–#şˆÚãÉ…CŒŞeæIßu0Un“¼qË^3¨´]€¡»æ¿ÖwèÿÌ®ybôLCZ¶=`Fà”©ÜÁ-§&{ÎÛ‘&Ø™¼½[|pxCØŸÀ"+Äg“ûf ò·¹wÑK¶Î·N”ÎŠ`Ï=ÙÊîVÓ/ñI¦±àw9ÙA‡[óÑÄ8áû®=Oñ&mX×•Gë:W˜’$&í^j7™£”´ÖŞTzYV,Œ¾„:4yp7ó€"šòûÔ?rºÍÂæn!IO±q%sª‰+ÇAÊ ×¦f9½÷âµ³Qnµ²÷w³¨n´ªRiTçÛ¥Æ›‹g‚3ÀOS™k§#G~XBj®‰œDªö.‡2”A’)²A¶ùSöx©œoAWá	Ÿ(¨„Ü#tVˆPBn6™Z>j¡Ë"®ÏÑj‘KÌ@Òê_}a­Û	ãÃ´>ï6;RÛ\}PÒYPRm5¶FJĞO8iä şÓÄÓ6ÈÔúê>ÌsƒÍR5{xbº¹1ÌÙ?ÿ+–S	À¹’BİR«~v’ VGñ"ã›&Ÿ!òúºôâMSéÔ<ŠjƒØîF›vfÄ}xò*Ù‰±IÖï_Õ`ã6W"¶š²éóÉxïé½7 È÷äO¦@]¸–#J˜çÊÊnÍ8&Û†U_äAVwÔ_šqÇÑLB ¢³ª
]¶_Øã4CŒÎL1W¿z€…?Aµ0‡Cí,9ò4h\Q \c dtšE<Ì3ø›ÄP“Å§õygˆˆÿíZNÇYG	 "ÉRs—ä=_‹S©‹D’…u^óÌI…xØÖSv‰ hD»S»>O€È-È7JKaBaûk2°"…*²(Ç|Úå½gWğ¹‡çîÜBQ2àÀT±ï0” [yşj#ÏZÊ4Ø*Xê*ÊÎ„^ÊüŞcº‡´Fìÿß{–·X™•n7)•Å{n+:´A8ÚİŞ’»*Ü]8ÒMW†Ù5—¥Ä.½ç†ÿSãIuWÏ‹™¶iBÄfê¢Jë‡÷(AH«BÛoaô­åiÊzw4tLğÛ€ó¯»mÀD„,Ğ%CÜ×e?‚{§ÀzL¸ZöÄæÇaeè…(ß#,só÷"¸¯m¯í²ç9/•%hFC†ASQNF›cf»>#+ı#qèAÓpÖŠ®•9Åt8ü´½0’}²å†¤³†á·ô:à¾Kò£Â¼¦#[ ìF!ˆv²¾í<Iİ³ÙÚŠÖYŠhd ¶,XßÊ÷İ;ú(°÷Ï²L[–±z³E¤?ëu¸A1?¬6:hÔRf vK…>†#”ã³ ²çõ
 ãÜ¶U1ˆBŞsF•j[4êĞ´Òª\5İnÀ|¨ä]ŸĞep€^£ŠŞ¯yO6±iÌÁT)Ìô£pì[u4¶GÚw€F‰EÔ	,b
ë¥™§¨Š=ö¢ÅCÈ¾t‰Å&ÎkMµµ:`Ùœ'}ü¼Ñ«è¡r7²'w-%½"FÎåîa>,O`„MÃ¿Cä¥sââ¶ÓåyÓ¨%>b½ŞrÛ¶j*½±L§¿²ÆÚö* CX20ä•ÊËÏòO ô?´Vj“Pæ¿4Î=*”7:!
Å%ªfØå6L’Ûò½² o¡êJü0·ˆsî­?Ô­í°Ï™»X¯ğ¬"8Nz™¼¢ú¿TW°…õ:¦V{áÀ¿Å}µtqÁ¥q²\³”ÉãLWXÂè¡Y²esÉls#‘¶Ş³	7¶Ó;NW1—$_è£b(7Û9¿.„1’0Ûçsù;¿ÀŒ˜œ‰45½«ø ÖÖé&™F±ÒB¦Œm`Ø„À‹Ê‚H	¤S‚W´åP,õêA¸€u˜ ŸÂ³Ê²¶§†tYÿ±²ÈÉ
ä	JKÜş¢Yõûk*ßÖ¡İŞ'ú÷‚m¸¢åĞ‘Èj÷ıöÂƒË`øCÌoÙ~÷Úä¼F®;
s/&•»ª®â^ı¶Áj7-QB9,C^*lÿ‡Ãßd”á Å+%‰=*~¿Q¥x{Ç“I*ºÁ³çYé¯n6œ¤¤‘'7üo²j ¹¶Á<\tm+5Ó!HKìt°†+5T‚ĞÅ4,<‰3­·D¼\ãXÆ×şK¨S]-€ø¯h° 	õ6ËÎD’¦&ŠÛ~)Ç1ä=]ñ	³óÑèåiî­w‡„XÆàn¢RABÏ$'Jc[f&ø8pû¤fájO(—$—^Y½¥Ì&dŠêèŠ5”´¤°…qÔ¦ÌÒ—µt±‡àÉ9hŞ,c›Ññƒü¿<¦~$!™pƒeh @ïÁû¤Õ­IsDİ7(~÷?İÉµ£
ß%?ïVu˜\ğqºl”u“™8Q„ìeÍ-V$lñc!òs<Á×iñv¯Æ·™FŠIî®Çkœ—özÉ÷:2ÿ¯\ı=Ïnvµ\¨}Åã½z]J1:ÀH$‘	m~5€ÊyóÒ0
”`Ğ×4ò‚e)õÓ0ãlX‚¸[ˆi;yj{\dóià„©¯øÈ*:Z¢|5«‡3õ[škoT:<€g)Ìåe]¸¤•„ÓBà>¸Z¥–ŠEæê9RV[°ñTuk³zEuXıxH4#bk¾¯I¾û9JeôZ2'fÊ+ ?ÎOî¼@o¥ö;•ÀmQ‰Ñ¯w8 /kßœ"m}›µ`­BM#Ë.VÊRUå¿R®—RÍuø¶xl±'×ÈKşÕBùì’uâ×¯º\ÄBZNOæÓb+£Ş¯w”
ñà¨u"œº’­îhút\»AÈ¶ö2¬gw¿ô!é¤Bê÷Íştş9XØû®‹$*‡Ls,>Ï9öëaƒˆƒ^R4ÔÕ–«ƒ“Ö2©(LGbßL;†a&…±=¦®ğ$0'İ!~ƒ5{Ã5½ro4a0˜#Ëh;]¾™x²8qèYr8m4>½ÕøŸwSƒf2qQƒMàš»…w;ñ•êË\ÔLvTp7Ï/9í¸˜¶eJ7v¶‹<,ÊóÇNw™;uö*VxzŸpµÇ ]ƒXÉm÷~HL²Èû"Áü%´Âå»ô!Œß¼Ù…t,Í©Ç¢<ÄñğÆ^ÍË¹*`x×½ö=x†BÅ÷s!æ$°ÍUk‚/Ñ¨õ~¡zø“] ØØp’ÛÇ'ªœË¬÷d9±"Fbˆi±ş'AÛæ,bğ>ÄÙ 2¢Õx%†4;à×ÍlĞRm•ÒÊ¹¦µ­Lñ®‡~l6(yVÿ«ïû˜ÈŠäŸüg‹Ëe,´w™j®Ùgcj¼Ï½Xy)‡…tKÎì?YÆŞ¬„úªóL{	‡ÊÃûOn~‹h¸Ÿ9Áe#£/(gÇ{xÄ[f¦-ß˜1Tƒó·–ˆBu1éJ÷»–•äz¡`@v2°"K|Íƒ«‡Ğ¡zÒı*8u›’§Ù¶£µûˆ\!ÙljH¡/ÉnzQ¬-šx :É!d–Œ'Ô‹Ù¹¡{|…ßC¢¿Ç‰Ç¯†Ñr„Š„V[ZÛèQ´­
Nì>–…©ü›WM‘ÀZ £½a¯’Ş/ÖXÛ\Õvåû8Ñc:|šÂñ2ˆ%ì¨wá¹¥ÎÍÉUûEØ¸”fó²¾vB’ô‡Ú²¿5ßäQ|ÍÇt‘…¦KÌEqfM—¢µÓ¯¬gÑ•‚S_&ù*‚y³m¥†3<ÖLøESû†ïS‚˜C½…ª§s*Í/àÊBÇ6’ûïzzbt—-«XQ6ûrÔ?­è!u“H/Û½n’7Lé]…¡h–.ŠÏŞtœBm.ÌœÒi2=X¢!Z]3iZõ`º;è¢xò"©Ö;ÃçÁv3Œs¹y”¤t7oºÙæ­ÌçÚFÆ–èöpsŒl¯o=>s]òğt‡ÛY­åÿg»i­‰w@ILy•>ve¢í,Ü•÷?»/ç¥1¸²‘µï‹Ìs^0‡¤õÏ§^Mºà#¨»³}
­¼XÉá½™TıA&?dÂ´Ï+µÜÅ¡Ö²€8×.+–ä€§3æÌ4ú±f£«Û Ôé„ZÈèŞ]Eºø:¥°œ¾%VNÓ÷‘9™—yÍ<Zoğ;9wÏZ—„ª¾ ¦­ È¥L†á¹îOİ8N	×e…ªG°¡\!@¼nH\®lŒÃ#’Ês™e¡,¥ÃÙÕ^pPFUñÖ¥ğßAáDUÛ<.÷#qÃ~c/ö×Ïe¤EåK¦EK4<HñRSŠy×ÂJ7~F¹/Q+¤kŞøû†GÚˆB58ìcÎó…VÜEø8KÜ17Båœƒı V™v
‚3P­†é¨²º§)µ™Ö]±*œå*âæfJt÷’k„ƒQhl÷E§¹S¹®Æœ3ŠøÄ’Ø7MINÎ@SÃbWÜ·xth°5/y:Ûƒ¥“yr¦>ÿÉ†Ş&ÿ"8•‡pÿ" R¬IqSÅÍ«Òä—:{ŠŠ²g6µáNziMûv’,T±±Ò!ªjƒOyi§¶¸]gÂòØàÕƒZç¼ÀÎwà–£ykÈî»KùW^\Ôjß°uŠ‚=|@D”¹Qs2‰õšUAÏ,tsúÛ*‡Tq
–Ñ§íÙwYoµ8ø¥ÜÚ¦^¾r…4©1Jf×l£R¼©ÌÇôÿ½ÊŒ°Œ%fcaNk` M Y»r~²›îÄ¯ŒU÷¥ ª¦fVX|!²÷UšamGl«·>ôH@¥’LÔÉ€’§3Ä	ÂCS|¥zŠFy;³›ÌKöÅ„9ß›^*©ôÀ\+!ötv¾·Ñ¤¸Lvâ«
èŸ1ä¤?íúšôX{÷šØåv ›¼GÂ9õæ<Xdúqm…á6¨‹e´õ]D#… óëQâÖÜ^M\VGhúsšÒ¸.Éñšv`;àÆº¿£<³0Õaµ®yJáÜ¹VBÅ…VM¿5¡˜)!†.ÕDÔ€¦×@Â’Ä:\*ÃÚl6:
†û¤fÁèe nÍĞS¯aˆ$Îş9°Gòç+EâÆ!‰Î”B+a 8g­X0.Ó§Èë;§ÊSŠ’÷øgk¼à?Ì¤[¾°¿z—ZÇ ŒyvRŞByJ)–ğ+»æº$óœuCñwp¢İZu¬?UŒ4?İ)™0~úb¤-LM7¦³ş,‰»]ùodÁÖ¹RW ™·Ìş©@ßtàÈæI@l vÌñç˜4ù@Ş€|ì‰ÉE]pŒ|–˜-Z¸t¹úÿU´Ö#µÂ¬ıJ!alÑ«ëqaj‚†-?`‹r]N_Lyùˆ).¤_mQƒ’”M[wı‹ğ*€%† µä8$f¾?ìµ˜[z\¾ËZ÷Ağ—×Ôdé”CYô±·QøØ,µË:zãgÿÎ48ªm„÷óÄ@˜¬úÃ;gË*"¡‰‰³Şòâ#> ¢ÎLl[QĞ¼Ì©	˜³—¹B@!E9òè{Öê¤|Bà¡Ø+a­éB¼¿:÷É2u¢&%@«¸
A[ÌØä7v¦qœ/ÂrcãZ–ƒü­ã=šû‡’"h¹^—h·8€Ÿ—÷èÛYµ¬?Rá³—³<}Z5¹qŒÑ½k[?Ñw¾–ËLªHÇwëü9%òÄ?Ä82õº\ƒ_DÀoí†ªy$ua‡
óRe'ÿµ@ˆŞ´M4NÂ³³•Viäö'¼¥üêsFÔWØ50Ğu8;¡‡ÕÿlIÂsëèı
ëVr%ë.0åAJ÷Òéí€=U{â×jÍFÏ8¿íC ks­~Ïãv«œeKYÁÓÇ÷§¹QÉ»âJ‘`lw§k¬Z²cxX/*¡ïÙ…fºû•7Y¡[X 3íÄúˆY÷ÿéÃ œŠT’Õºpw¯I#*ØŒõ2ã;ÈQX^¸	KÿMõÍn¹ÀiÉ¸ 4¬ºCôkˆûSl•—DÖ éıì¾'Vn…/DJj4G—ñ÷Á£á>‘p/i¥ƒ#BıĞˆµÚ˜ã³Í£ê6ÎÕƒtœŸé¯N5ï)5¤Ä=_˜†ÿšr—úØ?a’ÆÃ
È/ut°lú1íÈ:¦L¦ÿ=ü‚ôØ”ûçGÇ]B^ >øˆû}nãìYåaö½XÌiÔ%’¹Æ„Ùv…ßàğ*˜æ9„²:áPš¬VrTÕP/Màí¬Èü{†vÇòDP\ˆ,K]üTéº>úeú'æ’ÉyîëÚ0iœkÈ—,Ş&Z¦
íE1÷úÑùË?MÁ&—·¨ô\í#OB©eĞK]l¶zû
rÃL©3&&áˆ¡ØhS{Wªç\%€í ¿)Á0¦!0‡¾'G® ûÛ½ëq×Á QYÔ$\Ûã¢Eá…ƒaô¢saN3Ñ;Ï€;Âê|°g¿áë+ğTh¦†”ÿ°ccÂ¹M#Uğ¥A!ha£—ĞpÆa¨î°´@`…|è%İ3C“ãs—¦X²Û4Ú¸ú+gÍ—¨İ¦]|tæ0Á²^£z~Ä"dMŸÌp~cºLœ%vlCÇQÚ”nŞğã’±@@}È¨ô/	{®/,CÍwÜ À?[~o…fâ†—]•Ú¤³TâE–Ô¹ï¡­[øÌKm£`ké??0Ë¹ ·+YDŞüYëË'Û¤¹çñß&´Ğ€~M.Ã!ª‰—ü,Ğ®­S)ŸÍ¸&:×wşŠ bms‘ªÊ:*òƒÑZöëî˜RÏkËÔ^‹P¡¢àë\T§K€³²&»jÒÑfàÇÕ»È–æ¾ ÈÌ	À°µö8\lŞÉ2‡¨NÇÃ~«62Zä§P€ÅÃo_úêN²¥t“k‚9ša[Ûå÷-¹:¼î’¸Uôï…`çKú'Ü›&F¥…kLÅi¦K1QƒíÈJãZ+bşß3À_ëĞŸI—¹ƒM,ö¬üÔ¼`ÌgIŞ³Ëì"d
wîKG]¹4ù§àÜ4¦	åØÈ‘ç­9w@E_“ıÔ|¬‰gÅ/‘«|ôrl1œW‡g(£°˜+ªU>ÊÀÃ‚å R–g9jÉìffˆºf\Ñ~a|N¨`:q…]d¿ã¤E'•aÛ¢jûš»€J}OÉáı3—ığÆOLŒ
Š:HÁgÈåé‹p*'×`§}Rg‘H³$ èò ÃöÚË@+ıq”Nâ~ô¨°°ø$"“³™·½‹~ÏW•4£Áù‚³A¨äêzTŞÌê­rø¢Íıê¼Ñ2‚.ÓËGÀôWÈš2Û|ë<{0…©w½±8nTd>1É×`ßù	CŸ=0²lQş0-‚0JUtê"u¹±õ%â¶}7,¦ùyM*íö2r»¹Ëë€ÜV±-)ÛZÑpè!éĞò²°ÓNt‰5m’©ÂQ,ÖI†i®¯ªô8JâÕ”­G°…ffíøòô{³Œàªø»Y :“…dÎ<»üÑ<J(JJ–Vï8¯±~kàYĞ›ı;)(ª:`ûƒ³ÀÃ7pc#‰ˆ8¥<j†;3ûí¿…Í¡ğ\ç]œÃ’Xc»ãûA…(K¾x¥v¡}’áEĞbµ'ÅÂ7¯İÎ^;M5{Â!ö7…©ÔäEmò¢”ª¹ëÙOK¬(KÏ=Ÿí¹lDÂ…ëÄ÷{”\d±ı-eu?b‚ëª$Q$ƒõÍHŒEÎ¨¤Ò Â¿@p³Ä¿lâº6ê—£«¡&¼rbï1ıUQ”Cb®ÿ«£	¶Ì¼P7Ö;=¢f7Ò~Ü´ŸY+3øÑ uºP,ºËO ;ŸVj[»3y¼»à
9¢7mñ.0`àı€Ù2·SGàÈ“o5s€Óûv`	¥Œt·Ddõ«9/Ù~Èø¶ÚñN:=á
û -¾<ï•*\aöyâÛGd¡Ã%y¥ı7/R6ïˆÑ7Œèd{gÍª>ôØÜjÀ8Çµƒõµï†c~¶‡Ì#Ş<Á‘¸7ö5aÆ¿»Œ÷B;ŞÜ?Ôt$—@O†ŠÊ*gÔ¸¤[+‚ÿ¨•ÏE½Û	I‘§Ö-Z`ˆ$L=NJª++¸/°-u68pP¹O¯~ûå#ÔŒÔi×ÓÄeçêAµ†Ï¸¿Xj( ìw‡QJn‹q.4i„B¹D…ÀÏmõ¦h1m„“!OöN6wÏ!í‡n]ÕÓî¢?uˆ»r¤¼Ø¾Ã(~=0êXüG½ä»üu%,xË.«i´Ã®×è	¦ø./†9°äaëBŞ5ø5'&Â§’£Kdu”U+fZF7i£Í¬ëƒ6B×ÂTÁ×‚ûé ÷÷°ª¶ÔªÖŞK^wøMl–ÆTÔT‘ğ f$j)±$ÒY=Û•øùÜæôéıÄœg®J©ƒaÒ)Ä	©DÇ÷‹É‹‡A8ãØ–‡L¡„ŞÉqsÁ¡İã´ˆk‚CŒ/ f¥‡âfc«ù‚ÙªäïÔ*ÏßeßôO\qv³Øj;ƒ@µjÏb(x†˜’ò±œ²‡¾[cı5*HœéÜ¸Ã,În‚0Ø½O+(]ŠÑ3Ë—˜O?²Ìg ûÀZvl¨0y6R#ñ»@Ş¡ÚŸe*¾A‘Ksûö~€ş%Ùd·ûòXÇ™´ÔNÉ+Ñ£t&ƒÃVTc‡–ğI‰'Îëi;„‚˜“Bi€qBÄîxC87j‚ÄWa»U%Ç±%cjI´* ¯¥‚ıx Ény=æùqåó¯nå½^åyÇ 5–±ãÓA¿Ë‡lpF*}Ü ²<YË®€9Z˜š "À‹hpö1üv#æ]Dhb<P¶€Oİq\ÿğ³ÎÖ°¨¶ùP74Iu­a@~ËµÈiô˜<ÇæÇçµ©bRoQş‘±JÑ‡³ëÑ
%ä%3øxx>FÀÃşÍ‹†•ø–#öÚLë°äû0x¯ş™mJµí­:İmš';?‰²'´9g¦¯œÓ\ª+!5iø×ÃÏv•;INõì$­,È“şj×…ºî!×½ÿzcªNğ0Ó°"“‘Íîè˜AÚ´fPe‡$ÔO½±e)¼÷¢tTÖ7Vågé> § ©˜’,(RtÈVÇS‡J²˜%¶ĞØ›üf¤ÙtĞ48öô§Ö…‹ˆ6d‰|{Æÿ#çè—”
vxÁEÂ.¦96²UŞ—àò1ØŞAñy_ù),$*3,ƒh”!ÑĞÅV¤äóåd¹å-ŸÏFÊW‘TUxZşB¢ÅpéJdv'ÔhÒjCZ1sâß–1;­ÆÁgïtŠoïO‡ÍuÆğštæ5 $é5êÅå†?E^¨‡Qœ4Ş<j¤Y“096‰î*ÓÚ€·‹™6.ïh¥L²=B'ôÏúïÓQWµBEG^¡xºU1å¥ª£}6B"©aô'EØg‘µ¬dg†rª,mP%¬¸\î=ãZôÄåš€°‘Ax6”I<Ğß]_;(ú|ğ˜²éZæ«B¬e©ÁI«Ò»ÎíÚ'^BîK¾Pb¬%nù<&eƒû¬ö¾è`çßö›½,ìÇæ3?°–L,èÈô+üƒåPHÄÈÌ_CR8yšfp }’1Báq¨DL3RşÌ•iü|sÛ™+KØ?«‰kTÚÓÚqf™MMÃZcr>‡ª­?Zº[u…%Jmy®%¿4!9ç`P6šôÒ™PDvMı—‚(QÜ ’²~šÄÒlú\i5ª=ÿÄóØ%Ë‹+8aU4†ù›•ñÓ0gú7ú?R§şw-f ğ·yrˆåW¾AÃ ÷-–O¶sş¸\|·–q<ÎkÓtŒh‰7PWàŠiäs…™X˜e%+ç’S·FÏË¤Ñu4n×iø2j}áuÄÆ´pgÁ°k©Ø0àq”É5ê@‡³x2èE˜úÙ±ôwk¥•5v–Õ»>Sö—i
kU¸G¥®jó{P©°™×J&©~
Øún¿Å +ÊÀÁUæî]ÀL„ø#¡.¡)³/©~Ã)6ÏKA¶À0qy6üÃYÜQ©ãy·ÏS*Ÿ9‡`â r"è4É=ÎÁz1

×‚sYRƒ,t³-HU-@õ7C=WÍ-Æ¯%:³m@ya§«%å¿Y¥1’ĞĞºÑ9à-±‹a(1~ÁL=³–™yÔ¨Ä)½TEc5½şÌó§Šì;jŒEŞš±¤£Á¸‚µ;ä—QØí\#`Óg›÷/oeÒûüB¦¢jwÖân‚ü}å&?é5mØ!¾ìØrEÚg‘ùUu¢öáè
ì.ÈØµ±xLK²=c‹˜Åõı½ªe½¤TKY@ÛôãøO,Mk¥UöæLµëònÔ£ğ54Ó|$ŞÃıKğ9´wIíÊñK¯¡ï:Û*Ÿ}¨‰ÁËF®ã³òºosÔ=Œ„9»4©<‹F.óXî,¨SÅµ6>_ğ’‚šÌÁj¨U»¯=?$ÉŞ´Q@ãÊ·j@ÇIƒ!Fì4jÃ„Vª-AòüÀmå¡\Ò†öÙ-/ÖKß}ı[®Zî¿+'¼—1¼ŒCåpQ(h[p„nB	&\=Fôñò–PEZsªy¼ú€¼B)z6øôõÓïÿe˜ş«+M±Ì¦ÆVh(¡ØÀÍ^nç@Ğ7JO´ì
æüá7Ç·¾€"%yuÿC=¶âîSá©Z &SNdİ‘×‡†ekğöËYô¹&Ëô–ó‡î àö)Ï«Ûtv „Ì™ì¯ ‡Ø èµut@ÍİgÏí ¥QL˜±ÎBH·½órÃ€“„c¾C'tO.™ ›rnĞTá7=ò<Ä/i‰GF€;Î&å¿ö—®˜íÓ­ız1„k­lÆkV/<7’ïª˜«jTİÌ¨ÿÈ ]_¼Z ëìB\tC’ö>â#f‰Á¥}4¡…W*änSL™ÜÄÈ¯ïºBËµé#ã©p0æŸü(ÇàÕ;©•–ÊËËYé³±Ç¤÷­ÀLJ¢>ÈPš¥Ì$`}ßñ?Š×§§ÈµŠ:†>l,æ’]%HŠÀ.‰ìWmB+±WI4–ëï—ëj]\íM©nU¦w7¶Ü-¤-xÎGKNæe÷qAÆşÁYŞğkœ’»İ[.¯N=.È-¼˜©ÜA0TÌK!q XSb9Ö &ò¿e)öãQ\2øëRõ>Md·¤T(ûD]&«ñVcy”µZy¬Ğ	x§jÿi±`Õ%vèãfB7~KUÉäAŞ/7dÉ¹f»¸€èQ2¬PE]5Ö˜c»åÙDË=Ä*©ói‘ì À0‹7¦CuÑóŒáÏ#=SÛ©‚Ø$jĞAëÖ]ƒ-[âšÉ·µŠÏÌæsı€¿Š %î ŠéW/ºõMÑGe*ãÔ~íÊõ0ĞÂD†ÏLd±º¼!´†Ü/¬Ğ“5BgT™9(• 7ÜMÉü‘\7Î¥¹%|ò& ¸W?zÅoûvé3R™±¥be²•†ç&(F- ûìÛ[R¨™Í:`·F
U}fş7#h¹SÿCÃ»Sñ5*n¸:yD‚n7Åv) ›t¦<Pƒ¼¬Çù"şlUH¶Ø®¯=ç¸Wq!]ëâX#Ş\oà\óß×ä}F…ó†&ÌòÁšöûºĞë4IOú6#wY›µJÑÒzÉß­åÍ“Tj ¦sïHkqß7M&A9ÿL¾×Ú¡®ÅüSb;§<êRÃÒ5éãjÌ8ışxÃø·jR1>/ÀÌ4’Ã¨8?Ud[†ÆËÌ{«‘¹`@c`®@Íp(§Ç‘Øè„Hnü‡¸)MòÓ‡OÈ—ªlìÒÊ©S%k&m¨}m^À»Ì`ç½.	İ4İ½Âû ŞUVÆEŸÃZú{#2°úm:G)ƒû½1V9=æôÉQ0¥Pšñ4#¦×¬“İóÓğÂá9Á‹èô)"oö¾?.úç\>ÎS±	V´a5Š3?¹|ó:QL% õÆ¤ı+u b"j¡v2Ö7ßŠø/Ó¿À´Fà´¹úÌyºËîp£ÙxA4ÇÜ†ÁQÍ£*ÖnU¸QÁ¾UTõO®B;N%sæ‹§áÉI³ãqlÖ-) D†mñoGO"F<qâ3}šÉë»’sÿ?¥[úi¼ ‹„*^¼ ÆÊ¦Ğ&¡ æ~`â¿0nY²µ	Ö\Ş“ÂgÁ]‚‚ÿE11)XÂ½ úçÉÅ_—`Ÿ~;Öˆ±`³kDp(:„¨`Ÿ¬[Úÿ·»Ğ|ã/AØ™÷Í@©#P¯DÉ*¦}d@G±<²Í3~*–úkÌ×:¾ÖñÔlxê…¸­º?½!ğ³>vÂINËÑÈÙ`ü„°¶¤ØçÕ3•œ5Çê|äC\÷]Å¶×Ä%âóNNœê—¾!º¼¡F\ªüjÛGxÉD#òç©Ôu£ÒÂr¼ª¢Æù‡p‰2|æt<„ûØESMc ğyJƒ¼ZÕsè-TCÄ{?‰ÎÀŞ‡@mHaÚqdBL¯JÀÍ¶â/Ñ¿ÜfqÇY‚}í“ªr±d¾kP·²¥ƒ¡Eî¬79euË'±œ³ô\€Ÿ7ZŒ(šd6OP¼{5ÏÓ\0M ñÜ›`-¬‡ª!Ö„{í_q9ÿ“ùs²‹)yŸ4]PÆO ä†ñ½ÒLùî
‚"Ín¼’¼55LÓÄ²†vÇàF¥š·l-¤:¤ÿ½FY«¥AT—ÈB*(4¾³gn4Ì`JxÑ|šÇ+ª‘DË·/êÿÕü ÌßzÃXA è'D¹DÆ¬6ÕìµP!òäòJôæ…·U’zØY|;†åÜØİãƒuë¢ßê·³ ¢ôA2ê uOuÄl,+u_	;ÖN;hk÷Ksõå“2&ıô”—Ërğö&ÌçÀ
·ğ“¨z)—4  Áä ½XíèJ%F²¨'Ê ñÅnıylşâÚSU{õÏM5{·.`‹bßàˆÜÇ{8ÊÓİWÏuV5}/T,rî­A°¥‡w][¢ã~µÁQ0±ïÅá‰²‹¼ï"W%à\êNõ
wTœ–ÌıräDÎò3ä¹c,ûÈœ6¯¹w~q\g¿’~„.­¬áa©Î¬H×@c¬µüa—ÙxëYcÓÖG§äQ„rÒL2%d„Åyª~Ü¢¤–¼ó–½®æÿ<{âp'y iŠ´5bõv‹Â_<Îo&)qĞoÃ’ÊJ©²‘hÊ”«¥‹ZúH«Rí‹È»G±a¹ê £ğŠv¾†ûŒ:)†ì¥•#ÌšØÀïİ&š2úÆ€À‹›pb&<Ş+rï¿¡f%IâÂÍO‹aÙN”ã	·|«ÉE)ctÑ ­ † ¢åŞšå>§ÏÀ:*ótèêµ<wB‡áÉ->%¾|;WfÅ¾ÂİWØ€0±é <ä„ö´¸Í©Ü·-Rª!«ú×O7íHN Ä-à0ºü—iğ·n^KÎ–¸»òã©WB:bì ÙPÏX:ÿxıá€ê=>ùs™ëI ïçê±rÈÇØq6¿#EİùşZyhıy:¨F`/1S;K¾Q·òM%V³Kì1­bD¶Rh=÷/Üy0eKãÀ™~Øo ¹]}5‡úP!ó7/ZóoêÍ‹ªkk¤•”Q6<Û>Ã=‰' ê÷ÛIÓ99Î”úGiázè6}*-À1†ñš÷õlÖro²è›ÈTçû275/á`èpÆPNâÈ2û$(Uè¯v¸Ê3˜l.!‹Qó„-zVø‘…möºû3cWÇÀ{­MÎÁÖjà¸µJ@ëÎ°?®Â‹FVf–˜ãœ´ÊÆ4HÜ4šìSÃ­LÛ8ØÍˆS®äû,CåÓëÀöiõ.I®PaáÙxvã/xB`Qÿ5w J`Š]Œ®qÅ£ëCí
—j5$mØh·§G:ï\Ğ˜Í¨ét
ÊÿÖJfø4Õ¸Î™o~æÓ«}è©"B_ï Nà­‘¸¼û×ZZJU¼æ¡µ‚•h.Šï‹‰~ÿÃvÏîÅPió1;‡2í0DÕéğ¦h´Ë®¯é§Ewˆ¾êÄğqU½asZÉ¹¤7:	¿ek$N÷í8®i2wû‘“Ej%@{×³—Târk³“Ò.Í;´.ûÆ-i©]h}æİÍáÔNƒ6ü =5·5fÏûÇ1ÊŠ¢ æøtsMÖšèÍppÈO«_=iî#Gz[æíñÈ`ßš îK´×Ò©„ˆpVÎkW÷»»äÿo¿Iÿ]¾ÚOÿoAåv2"?’ùÙC%~Í;u2	ÊLˆÃ»lşü‰£Ò+óúS$bAÏ¬ı8¹!–^V#DA9‘2`”,u’Æ‡’€–#I-l¯ô¨¬íÜİ€Ùz3UcflÚ‘#¾‹`.”T¶¤ÿ¥Wd½ĞnDï…„›XQ#<Ñğ6LduÙ´”* š7¦ğĞvlt©»êCA*~I-£>d±ˆïáˆÈ«¿¼BXÀò¬6YøŞ|ˆ)7 °ØØ`²ñæl CEÜËx,œ-¥"i0°b2ì»ügåû@61ÕW&"öMÒ Şğ@]°Ws|a8ú¾J_iïÏLR5» ¨m$"8Ç]v@›ËW#¼¿ÇÌ~AyOÚxSIà­x‚mû^4ÎYd\î—Õã`èŞ´›b!ìQWØÑ”ö÷£İ®Í<"@v%ÂÛvïØa–ÜÍÅJòz¬ë7oı|e=­Í‹À…rÆ7`ÊØO-¯··_ûwûı şO†ÿÓâŞpmÍ¿OîˆúRõÚµ^ÁŞ5üÉªˆÓÍİø$>Ùÿ"¨X¿D5¤Ú©”ûA:Œñ®#´ŒæÚBøîLyúXœ[g‰Ci¸)[ôéx‰ÊŸÄ£erÜùzek€®#V`8vèGS3¿ë½ey‰f…Tlex@ØÂvºFZº£óCÜOŞÌ bĞ¼eßn£;
–cz“¹%_@XHÓ³5­ŠW#Ø"Àò’Óƒ‘c®'çß¦X«€5ÊÙı6õÜhˆ¹ª#ÕTÍTzøDŒ[²’X^â:2öi\ëİ,*…%t””«¬»6’v`ûç!
ÄWÓ5Ô]­œ¬c‡ùúßmè»F^ëI[ç¦ƒHòú<ÅHŠá"½c|ˆåøâÈô¤Ò —‚¼8·•œhHŞl¦@t-•¶>ÀVÛÑã½L´0“S„„ùÜD¢Ùæ¨¨üB,Ú0q×!áø5İƒ£s†O%1NRÙ¶¬ø¶Òp»Šú¥-&w6´´É&£Ê|ÿî5E
8ŸXL‡Ën¬ø°I¦AÿøÎQŸE˜w(*Y±X«¾‘Y0¿–6¢¥pçïöÁŠXIúi^~òÙ7¹h—vCêÊ`çº)r Ú¤+:fÈûé'Ø¸¯B©:¦óà¨Wğ÷†epÛzöM¥ês3P¶š½°éQÛûnçÃ\ãP‘#¨Ë\BmŸ`›¦1À@¾°×¿`¶[ªè-#ñ…¯ÅÍ>Ç0*13øIÏMà72£Ãæ)›$¹¬1Ÿ@ÑÕ˜cæ^mĞYßÌãa^«
÷&@²pÑ <ı¸uT¡¤ŒÜÍ°’J¦78e@m¿‚.¶_&Ív¢op3GôÖ—…Ú¿óÎ‡ÔtÌïÊvüŸ·Çşã‡{UWy•Ø¨
s¯vìhÛ¡gÄ†¾Ö1'(*æ~|| X€6ĞÖWï @@XZ#&^Ë3¥j½p^Œ.U‡é¿‡Ê2˜kÍ¢¿WÃ)‚]ªØ±©*æXº §Ÿ€‘‚ù¤fnY`F$b€²‰pàê­Âï/İ
ÛS>ÇA×GF§íyW¬Û˜a$ît1‰a“SƒÅ"ıS(Öb–æ]Ò 4eN<!JÕÀ[ú™ä9hÇI›	É0”güÄ­³ÿ¤¥!ÿáñé8¼š‰˜y…‹s~1s¿)İÁo¨Å–Íô¢Ëa¤ì½«µñ?èÉÀ	œ!¾×®	X³ÄF’€DÃû¡±¾Z)ÂÙâª_:úBéÕÓ;q…¶Ówïºê¦B*£i˜^Ç[
YlĞøAWúNQiİšÈ¢}˜ô/x½LrÄ4½wPxñ*P*µ/r_İ$›V›ÓÍÅÓ©>à…VìP÷ŞìÊKwR˜ñãRMJÎÔ¹Ê„eğ÷5í‰İvÄÃ—~MxBé£x™çÔ¬Ë£öbT½ß!Ò ¿ {dPØèw¥3ÉôÒqÂZ€/Tåˆâom2¾M •Ë±Û3JôëÄÄµ[ü½ÂG*áÅW6Êa°“Ix09¤bX¡¶öW„k{¹W¸}¾ŸxÛéĞØU±êLuİ”úªÉÀT[`­„-=ƒ Q5bŸáÆG·Š›ƒ'D™Zr÷EsOx¥23& CW;ã*JN
*Yœë°¤÷ˆğ¡®²s*ñõ2€uYëiü+¼›Š/• ®f‚Ap/Z^GƒDÃìd„ú@ĞĞ1]üåÒ/[Q8WŸÁ•ø¸ÛıtÂšÙ †' 8ˆC#Æ?Œûì’Ÿ7{¼¥—ö-k‡Âg± ò¾xL–õ†İ Ô/ e`÷­AZŒÚ`Á€>– ¹…ÊRş¼- ¨úlLÎ7—}'éğnåoßCM‰Fc–kóõpî‹¿]X]<>õUûPİÖ^ŠUÜ1íEDõq•9äv)™¢jzÊ›Ï†,¾èGüJüÍTAì£7éÿ)Z$ø,VŞY±ïEâ³q;0Ãàl[ŸÜøˆV°’š–¤wƒıŠuİD›0Ñ£$±SDŒ«	×‚blò2Fú¾ò2D~ÍËdŠ-K×2ğ@\CøŸOè©PVÅå–¦¬¿áw|jo7€ÇŒÿe¹ıFÉà‚°÷Å±y\ã†ÂÙŒ¼öW°/ <ü™!Ú.´‹drfÀÔgOCºC·Çº8xsw™hŸp¸i‡¬½àIİo|ì×±qô©-4‚1M‡W’ÛöùMıaˆ>‡a¨ “–ÃŒã¿yÏ:˜ÃÈUbşÇ-çBöØ‰Ÿ”«rÔÁ¨‹oóÉ9ñ&ËÜ_¬<|}HÌ–L8„¶›ıÏM|x’38[©„h4	<ªl#Ïï“?æ‰P‘^)¡=–ÏF—4W)¢ËëÌJ.yÃ0E'-‘ÚL(8ø×—ÖmaOsâ(Öh6Ë¥°²âB‡gúÅá™™‡Â‘3_]ÿdİS/–rÒŒŸ¡ƒÍ4p®?ŞVr!ô“—›uúQ–I&Ë82K¡—$ÏÁ«ÙÈÏºÃAL–Åª2¸¦"yµ3øiy¢)Ü«†.A¼q«“»FÇzéÙ˜TIß¹o«]$	 $+®K Nv~•HÔ—úe2)rjFõ™~×CVÀjÍ$ø:à2Ò”XíÚ0¶«}NCæ#QÈ[`–©X‡mñş]Dc¿ù(€!{²ç²Ÿr³úp*úïÖR>YWq¼ı]ú€ııõ%õd°ÇTK?ûùÚS:7LJ.i8<Ë¹¶FşÏùŸ—îèâplL„dı„r=2'ğV™™Åw¯¬¡ú?¤Ïî“t®a¢ò/+³ºä)ôs×£í_¹E!lâCA0µÆ"À±™êV—/m¢à¬FsJòˆå³ –OÚiÂ±İ’Ì›õŒVÖÊ() T®›’¨°NÓw\æ«¾Ÿ¨ç>!ñÍŞš7¼aWrÂB	9Î‹ÉÙÂ+¦ÿFİQŠé¥³àÚv;ÄBC€k}áá}™5¨q‚÷Üº>ï»‰ÓàÄ”ıøzÊÒ$¶mc$7JSÜYàx"yŞ9½gaZ	0,ßĞA¹3îãÅI5¥A]¿§[+Î	üÔdX«YJôş±íb¥€²A¯ şÌ_3	NMjÑ©Q5Ãx½õ’í{‡|!ÖíŠ%_ëåÒÚÇöúî?Ÿ]·¯v®PaeÁá]‚E…³±Ôw´ÌïK“«È/¨š“%³KÈ½5*èÀ‰ñŸ!ãÃ0öÒÁ|îïÑaWL¢
Ç!Çìï¸Ì(mn¨*êAòm4éqçû>‹0õ%GaTÇ˜éaóĞäÇ·ôÎr›¼A·ÉkiF·÷€| à3ÈÎ0Ã¹ÆRùÅo–Q!brñÑ1_”!(Fñ­)·‚“œ	=æ¶<‘Áê™Ä™û«ƒ*"õlT•:s·âŸvÁ¾èÙDôûs¬–´üà£fëå=¶¾.²O:¾±‡®ƒj(WbÔëlğb:)<¥•8âşEôÕ’M“ŸÀihmHzæòÙ-íã¿OlgƒåIO…I±QÈD¨àüøÌ<ø±	HÊù ÙËv™*hìãÊdˆ(Ù¸EÚ
³.o\(·X„›ŞAÎİFÖCvî|/ÀôI7—ç øWôrµ¯ÕøémE›ÅG°ıu'Ì4<vŸµºPª1‹m@Z¤°Pÿ`Ér|¸ƒ6¤et3Ù¨kA'AÔZÂ·uy¦d?Àd’Âh-.øÎú$D\ªvOl‡W½® İœ´&¨Nb_’©õë´ˆncÅ¦TÏ•H5Fx	¼7<D§k…[[ù2DŸğ·­”g&HM$k]Z+-à!ªùdô®toâıX¢7ÓÑ`[áU8œâÕ)ÆaÜŞÖ~Ô¸Nƒ_ÀDD…ŒiÃé÷UGÌµÕeÙ—”‹@¸xõ©ÁK`&¦­÷KwÂf¹>hëëhÉ‹òóhfX¾”¢^ T˜’•çƒ¦_MÅÅÍJ~ÕÙ¦€¡©@Ş¹& ÁkÚÖ@ÜÆ+h¹+g³œû ù)ü#!—|í 0šh–w³íH–m³Ü1çˆŸì–¤•+Š°ÆX¹˜mÊEìAÙ=c‡eBÊQ)Å,1ÖIØÿÔ,ñ@N2Âáµ¨µ™;«ÿEˆ‰–Àáúís3Ùn¢P Màz#ÇèÇ¿ÊèÏd·ÊÑ Á8IKíc˜]°:ıE 5«¿1e]Ï r¼æ†÷êÆïC¶#SoŞÎešğ½	/ÊeÔOä%yªºÈ±çÀ_‹šÿœøE&îXÎHYbĞI
‡H&XÉÖ¤eÍw¢ï)«÷²,ö~ØüB¾@ c@–
:2Ú²<‚‡xÃ0hnB©9äu˜şrŒÅMQ
"*Ëw8Çt`R¯*¸'¡QŸ9N]~‚¡z
cy lšîbC >Ÿi=£Òû„L¿¿İ«`×òÇm%-‰¹.‹·W’'NF¢Â0ƒÿå£3'¾QE–°Š˜:6uºKaxYtÉ4»ód?ô4¹!Ég$MLmİûsH.€A>ßxí×°¬šAY/¤Äçšk¡;ÍÅ1+ú Z·LZÊF•„F¸¾^TbıÜoÔØ§ó.{\6Ùª©~øïäæVqç5¤äâMV0÷Ñw¶Å!8¸Ôğö½Me9”¥ õÆ+İÄ[	w¸Ä„tn¿]£Oûí·çC}_•Á.L÷@TFø†ÚSTĞIĞrk—«)€9·gïªî‡ù K«ÿŸ­!­¡¢h4°ºŞ9°Ğ×ğtÙ¾”–¿F¦ˆ1]›-0¡iç!ÎŠÿç¢gÊ¦ä)8Cş/ğ•
“êÅ¸z5øšˆ¼ê¹Emqßyü©=¹™q”Á£¤|ŞIÈ°yÑ½âƒ¼ÑlèºîQrr~àƒ¿:;ôz_$ü¿øş¦;à£ÊÍŞG°(ÊnçhÕ*õŞ‘«Å4˜i+vÔyçtåH¹ï¦“ü	ÿôˆz oÓxîÎÄÃ™O©(JVÈTj…CÇ°ìúlu—Ùtzn¢wO»EL±GÓÒƒ¨…4ûdÜaÃâp:eü¿AKÓ®!=Å–mü'ñÙ'ø­ùïê4bìùê*ß‚":õ¬u#eF Ûw‡”Äd®a+Ê”ÁV¡í÷îèşû1®Bæ—HÂ;6LƒiL(ÂC„BÁá+z0şëXo´Ñk¼5–ƒíŠœF¯·Ö?ç/G@^ı¶©yÒW®jÖ¨…OeõUf·(ıßÒÇÁ²VW¤{8ÎóÆ ÅĞk2h&…'|Ó‚\ÊYa|¸¶R“£Zêñov±9n<x{×z§¾äƒgÒ"ëQ·[ù]«z=<Î5öÓæWóry—b·É™kD 3¹×Wh—½F ›á)>ÖWS-	´«\y9ş‘Aò<<ŞÇ S%’6–"ş&=ó]½]†ïÊ1"æóÓ¶KIHå-BÎ‹¼Ğ0…ThM°×I¢×=‹¦î3Q‹-™["ïÈÂö†ã´?¹^ÍzUıËêµ¾•
°ÄcÎS5¢>µÔÿïŸ‚)UØğ>_¨Ìê>«=hÕœ]ı˜ÁÇâoYôcJ¡;(ø\cCkqøŒÆ’
}ÀŒ8ZSEÀY
pÿş€èÌ«mƒ0•õÁüãğ„U,Â@·nuè¥uÓ»øCZ-ËÂ´ÁÃºLë\Z$q |i¹	JKU;†êµ‰E`R³61|Á:ÕŒ"R<§+E¬W²*×ku¿#eß•)C;Ëx«–IL7Å!;¹ˆ¬_€lùÖ`†ğ¥UğùŸêmº»ôµ$hØ! _ÚM¯qĞbfŸöÕÇ¥M‡v×eÓ¡ëv·DÇÆ—¾b0ˆ£ÀªûÒÛSH§ËnÅtfÈUfû¬„e¤ÒŒ>Ÿ#N9í·Iª£Có5è:
ÔeÆeúVp¥ôü‘…Füá5©w|¶ê³I¦W4o†i*û%ïkßVîwÜëµi~Å‹´©ÃzEüÿçènÅá¬°Sí’ó9;œ—nxóšjhRë´¹ãåÀn©`p`¢6¡²%cƒÂàóÉšì½¨)Ê¢¿•½	ıõ‰Â#o,>Âøx`3vÕù$+úo1@ŸÓ¸ÂŠ'0”‡xğÙä_gvÿ*»X¸ }#O”w±§8×^SüAjá)¯[ôPÔ*ÇXÁR¾r€    ¤çªÔùHX ¥É€ç ’H±Ägû    YZ