#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1734383159"
MD5="4ab9d467156e3bfe180848648bc32c9b"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23260"
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
	echo Date of packaging: Sun Sep 12 18:18:50 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿZš] ¼}•À1Dd]‡Á›PætİD÷G§.:1X™šŸdı›_<QÌî?»¡âôfß7ÖÁ-Rf8Óƒ(¢”;½`“-ÜãS€¦Ç(UŸ}_FÏÔ&´Øá¬.öĞ1-@´NÇ0aq\é./#+¥ãEåÏ-¢÷%à¸'H©ZÎşWb~cÄşQxl6'Ù–ù­•rLcÙn¥.Ñhx¾İˆE}ƒ£(:Û2²‡?Wä’«éRÈµ’rŸ$ÖØm†pööé‰ÁåúF5m<)¦º!'^v_XA™c¡¥€ìŠÁƒr3•ÛÎ#nïIªÖøÿÉ ×«jÄOOÄ?ôèÒïgØ}éĞGa›S@9ºÀÁğû†öëâÛ ’ã¦yFj>Äûgöcu“aÜÒ3 P´Z´©†wb=iÂ/cqvşUÊVwúĞL´ú	Ñ	;¥Ÿ,©à“p%5ĞRİnòìÇ˜`öÈSFMAn0Š¢¶­ÿüOa¾­°Îô†$	é¦İ=«ãW-«í£[˜‚XêqŸU¾ßÍÉû˜AşOÀÑŠÁºA/Îø}Ái=Ïå(p–ÉÒ´à<ˆÃRJÆ?FßéÎ‚.(eÛÜYÄlšpmÏ>ÌŠ§ş³gb¾h×u¸Làãûß´”å®8ÖÖZÕ	ÜSÁ7}œ»…T
•Ã"f(NÜğâÉR]Ó…nú¿†m5 ³¨³ı›ãÜÄXéãbƒXöB-Œ¸qQNûÜ,y“–£èÍC×ôˆlßé=Ş¸zA_Nº©Ö–|Œ
ïÁ»½º©¯v†¾ÕàNìÃ<¯xĞ÷YĞÄë‰Ï ØÕá2íßOB5ˆR2yôËS^ÀJ¢6ùr[³Ô	˜1–²Š%¦ Znf’
t‹˜Û‰íå¸‡Âà Ô—ÖY>l-Ï#¶:Psº6© º÷PÀ,ÃŠ€IÑsSÿ’<O6n7œÖkØÄÜ6ê4€uU” ´¡J87ĞGè8Znñ>f‘ìE€ŒÜInÒÑ—¤£>Q2âijĞŞ5e×82ù«ÀúU×ã}Õg,ø¥guµ&zh%³Cfc4…§rã8¶ˆc/äê´qŞ]ä„«}¯¨ì7yÀ·™¶º~Zå3lMÓñÏ^Ìãò/fO-yU_Î§¹³×½½}]´et‹”Æ(¿=‚ù‚@Ü§"ğ{|ĞK˜Ş®ãùÌ7|•^ÀN›ş5BàÉ˜—­Nlz‰}ÔqŸ”iÑâsXŸí|cÎxdÕÜÍ„£ÄQsv.;¨[¹_Ù’y¾  AÔ<ğ›ÑøÊÌÜ¹âœI¸+J’}©ÆrùRšÏÈ2Ç¾3} Ög!Xcjår{+Ç005øÕ€ŞŞ}t%1w­¤†™‰N°e<np2ğì¨“Á
´t’âº¶B‰4r-ºH0];ìsáÜ©Ób¤^ÃÌáN)«âáBR§šyÑ]Ë¡Ø×ÈsE¤3åàáiC˜ækÏAs¨d£ŸªH^ÿ™ûø1ïk)kå­ÑÂ$Lô‚ÃÉÇäşC¬2¤ª$Ÿa;Î´hä*Áòó^hyKhşDû
“ÚİÍR©X‰Zhf?/78Ñ®|¯’K•~ ·½‡±%DN-ºèƒÏÎZÅÒ”7¹kœ«,ıPÏ±”n×"ÙÊ ››Õ@Qå:<~°:8+¸’Dñdÿ_ı@ÏdgËå8UÊÍ£¦éê¾¬Ó<ÉäŸ	à²ÎŠ3¨o}øx"Í+Ohß—+/{o°jfÓ MÛZZÚ&sœƒeJzgƒP½úÓšßÇÈìã cYkåòÎÄP…pXÒ¸¥|Ëí©°%…„¸ı°mœ¯äâqù¨	ÃDB”’¶o ï}å\m"WˆÙş&òz­äTS¡6¢y˜_7+çj¾f1Fq]hºÈÍUŒ¥ÕˆØ³zw Y{Â‘(5Îêq
¾n›ëaƒ·”wğô‚·¨@iœÍ¡Úy„ƒŞé¬M¿ÀöŸ*ä¾ãÜf#¨HTß‚Xóàb;¢
Y3ì¤i‹gÏÄuOâÏ½mréUuéŠzÂKfÌ5«$Lğ`K¶ß‡j]t|`X‰Gé‚L'òÉùvÌD]ÄäÔ‰¥V-¡.­½„—â4G-ìø3#:Ú„‡Eîøû—¿#ÕL3øÖáíg'lÄÔŞG càêd‰:n ´ç9MFbû1Ø@ïW\—O÷=ô¾‹ÍéÛ˜>{âİ©uS±7Á~Ÿœ€Nitb,AÈMB{Yü»¾ú4öCºéFäË¤oîÃ´ÁË¼+dÅÈ:K¦ ºfn‰}„Á£B,™$ˆÒÃÓ‘Kç.“ÿS$Kz1¡–„*ûÍmWLbOvššzê%äˆ¼½—=wó4âí˜’Ñà|š¬Ô`§Óö#g}IÀ'VZÏÛRE}T€ê¤áš³}‹2€#ªgh²&”üÃ¢·	n~>p‡?ğÈ¬S`VÚfíÆ­:I"Aœ¥’pÄí5«ãİùÉş²¾&©Ø:.¤¬L\hš„îËqİÇûTÚÙˆìÁ²æ½:™õi06ƒ‹Ê¡-ğ_sŸp™xoy î½Xœ‹„RÂ‘Œ7QÎÒlZX«ƒ'œ»áb¹Œù »"#‚İ€#ù©¦d|úA y¿f7çe†¤#·w×NM|\KÚÔ»•bSxÿÑw)=¿g…¹•ì`£§µ-\$’d‡Ù³õÊxCºîÑŠšWıÅ9,†ï¢$)™·Bí>¦t,åTò8Ç5B'œpYc1~%¯šà›˜tˆÑ¸:|Ù‡Ò¤+h3fEª3äómB¿¬¨æØƒ‡Ÿ~+¨ßY˜G¡™¡¼ë6²#ÃÍ›g‰âÆüÔÛŞI{„ˆU÷&˜9ˆÏˆ`†S{hŒÃqÅ4nÖÈ~}zªXvÇğ›…Êå÷_ë?Û=8Ívuä&M°šs-Á’Î•àBÚ*Ê Piv+Í‚ôùq1»ŒVÄhUS#³¨iÅÓ(4#j9Á‡s*zù\P,>
œÙEdÑ¤¤Ÿ¸ÑËéá¸õ‰±3øÃ¥Äy¹ºi¶ÔŒ]z:Ê|:â‰²ä‚.1rQ´î½	Õ¯¦±P¦ÉŸq,>hËºtZ¾ÈÜ<]Z‚•X¾ÌÅ&^ Â…Map[Iì¬ÃÔLew+«ëx2]Ôu•©¨(‡½—õPÇÇÔTëöÎÅ\¯Oc¯‡ ÇµÉ´¨ªÓ]ñ´Û¸l'^+<ášæåğXdÇËó±E¡`J˜µ¢îÅ_Eokíë„ ¡g	ğµıØş¥dr»÷ÒRµ&A¬´Îª8=z'˜/]àFı’…EJ8œ+,Ì‘ûìÜÔ›öôúAŞ´ÌtÙ
Ff' 4…_¤S"E!”¨31A3(ôkqyÀi´H÷®E!²e¿êËõò] ¯çÒA÷—.[i3ò½fŠÅâ4Ò(Ã\çê8ß*t;jÿlüBİâÃğ•@ÆuxG]°3üÄ•,†ûÇ~¸!îài›ÜÏµBuì,>î¯ó€¦*ÈYñH+á	ËoËœ2T²ãCXl1İ"ù«V*üG|ŞÔÆôoa±ïhÃaÚÂaF)T®Íƒ>…]asQ@Ãè$êsjàíˆòuµem"®O²Á÷ZôïmÌ	û9KG|	:Çb6äæIÀ®ğwû.’ÆdÂ?>œÊwÅÏI|MrHúMFÆ€¹«êW‹5‘z'êîë_Tws³Jş>!B†JXğ7¤ÉJÁI¬4P9–àòîe•6Ù¿Ú¡]DjwM„’BÏÆ>­Ìø¢I¯ÛµI¶vUN‰m°Î„ç¸£¤?»úˆ§ÇÔ‚.@£¼;Ë]¦ü~*áúc4PX¥SŠµ¤	êD©àÙDÓ‹b%q ‡“a¼ñ•ò9yQ#éª=|<ì0Œ{£¦·ç‰*ÄD8°œäp¿¦5+©”˜+fìSsGëÄ­İ¯“æƒ¢…õ]Í¡T¸SmQ:¤Zqm„9ÚÜÑ4¹41¾¦šlbq¼œ8=Ñ—>0;Åv(ëûx/¿ïdxDïºæIízı™ınŒøºuïM!·{Ò¤^J‰I!Ñ9c ¶€ù-+†É'ÖÀ’óÙŒ2d é›O²Ğ‚(+úYûâ.1A(®ÿq–R˜ÌâÆ‹ÑîŒ
²o;òëôqfà7Eıè¤”¢ÏªJõÛ‰zÂhÄ*¹«Rï{»“—@ç/‡>owXhãŠd‘Ür¢±5â+Ô87HI,X·CÖø§ƒn¡®R£TqÆz$ïN›;9ÏK–AÃØFjí	ã«ém!’ÆÏÁvH¹ËcÍC_c¤¶³­§¯RÕzÃ±(½Hsj¶ °;tX\ÉL	=Ó
ùÛ,qv|T*Î¾ñßâÛ°‰ôó­$ÜıA9*Òhp%Ÿdòë
zZ"ôî™ıú²ãëÅ9$)Ğ=à¿Œa(×·ËNÔ‡–ô›Ôk$T\ÃG8|èÙœ,
_—™W7œğÜ‰°éÒ”F’ô­§Ş•Bu(ˆÑ:L‹dee§#Ô4\JT&…Òş—hq¯Ä‰û»1'uö†—¡¢É@Ãú±§Ëé×TÏR¼tÏ\Q¨/ÊŸí—Í¸Àiy	¿Ñ†ÌğäŒ'ìÂ£‚}R×›äámÚ‘_ø}·dt‡AÖãUwìïFÃ@
y&v¬ FÜ¼­&â®û:ıB/™pfÑP_Ú_p]ÃóH093Îe9çE4k RSë·xœ¸G\ğĞ	uh#ùR{£Bšø¶Aİ)WxıÚàœÉ]©ÆÇı˜£²gx¹ÃD· z©¦ØiX—	º?˜Æ²ñä¢;øêÎeÚåîµ†ŸÕhû-Š+vĞˆ”ı|14Úa”,ù³³fÛÃâs¦ŸGØÿµ
Ü|š|ërX í€­Åegqn(¦ÍšŸïwvYC³Ûhéš
ƒø’Øt¥|©GÁ>	]Ñ­ùT%»€¥wÓÊh_Og‰÷¹‘ôÌlœ’{Y­øìŠŒäãä¿é]6FñVà7ÕÜw¯CkSİÚJh¨^Àò´_\jx?×)Û² jÎ$œ¯½Wé1¢„7H¡®lf‡|ŸøkÀ×p*;Ô~Š-r¤üü Z×b¦ˆ%øazßEäÀ{ªKßœ|ÍÑ›é;)eÂ÷Îä7»§¡=Š¿³r.ˆ+ uıÅä‡šäöC‘ÿBE‚{aºDáï ©{DÒëèƒ€yÜ·82Hªr_0§Ò¦Ä~0ÙV‘Ü£‹â¸ÓàËœór¯f*½©D@
c†‡£%,ƒí+ıù¼6Ûˆ=šm¿ÕÿÚß)Mt(§÷eéî÷¢â²4eöôÔp…‹ÅJyš:TË~G+ïe¼F=ğ4“øÉR­4<”˜ Ï³59Ø|œÀE>$ğĞ½×›ÂMSü"AKAJóùü7siØ'¬ÊSüZëlŸçÔÁâí,«D6}r²«U]ô+¾¶µ7Ôí–Å77Z(jC_æË³ğiaO˜™„4 ’µ}ZÃ	v9×xX‘Û>ÃD]L9[EÛY Ç¼(4÷†º%}Œ€¶¹;ş®\Vqc¨šËòàX€(™[äi5R5ÁNb#ÙÕøir÷u¢7u”^Ä
dÏíÔôÍÜeŠ£ßSÈà¥ÖÏ½‚,WíOó	§•+kÓšÒÔ
‘ë<\\·'Iƒgğç^‹QŞ±`‹ÜİĞPµ±8ÇJ3T'¹½ô63·ü3,†ÏñM¦’7ÔNÉQ7p0f»®©ÿ[­sHk¯m/¡QßœOÔíENp/¸BÓÆŞE¨;ú 5â¹Y­¬¬\¢Ásø2ÑúœÀ håøö©$÷è$6C¤ÂT×z‰IAlGİ)8òº#	üÚúëî¬‰5Âj7ß€[e‹6hĞŞ¾‹Ôå³#“Öüû‰«©(G`-¦ÑíQ ¾¶]³Õ¤›W!….ò1säDL¦,4*ùÍJ?äÔ«C©^ÚãçnåÜËÑâÜ£'Œ!ñ§•$“T6Œ?@O„^ù&/Í×RH
ÌœNÖBˆS>Ô1j¥æ˜§ Hû[È0WQÀãÕ¬ÑMÙŸÑ=ñ]"ÛQ†˜9KÓë,»Ë #!LıÉ	âÀˆP¥ÒÊ =QÜZ3x7 B·Ü„½²‡/Òõò¦‹¤wá]6m«š¢B¼!¹¯ƒ·¬ígÛÖqufC‡·Á£ü>· 8¯]¸8º›êå<—#È
Y|Ü"ñ BCòä$öjø»v©àh6/ïeä6zÿ7Kû«šëÙ\˜¿fĞ60æîb¡Õ‡ÆÍ6õƒ3.mŸ™¶~©yûÆòAdÔ”¤SÂ15}szcÉ‡Ñ[×9è	ü«Ş&«ÔûÉ–¼G™+<İéğxööğQZóbâLİ–µYOßª™h8qKAú.ª³fÑœé®S»RñJ+$'¯eQiĞÄw*vp¿ZLÚWcŠ‡Å‚C=Ï+ÁÃòèZëõ«òç
6—Lw!±bånƒÛ¡Ş&Ã¤y$VòCÓÌE‹.ÒçmÒß¨<´N]OA¥ ”|W’E.uô+#-î£ëõÍqŞëŞu¼ˆVÓ>cŒ‡¿µp%f§  Š…åXJ#O§Yà~MK{Å¯LÌğÔ?¸ß¼ìÑæI±ÛN’æ±€¦YŸ-³dsÉŠ¼ôh¦­Bf’T³Ë:÷àÿZŒşü°Úw¸ÈuœÒ´…/Oà![÷œ&c˜K’÷¥Š‘a”Ô.|ÓŸ&ÎÑÔÑÂŞ¾lÛª˜	•C<’ûÎS	Ë›ö˜f;#i§}SÔœ½…ŞõŞïK–¡B¹v.×“–ïk~¦ê;ÛıÏÂ5µùºú<9j6O'øğFt‰C¦«³0jiÛu?ëXˆ±>JºÈŞ3¢r`<3­§·('dJúh4€4å´^³=N¨‰>õ7”Væ[y«İëPš½¨}¶‹MU†¨®¯®ßòìY“õ·1Ï9Aya?c Jsk¨°äÊÓŸºPÓÕÁºÄâÕïŸH›(b;ú©œí¯øcµ4åô°ùÆäŒñ‘]vQòôõ Ñ÷öÚ©YÕkİ©SOu¡&}òt(Ê›ô¢ƒ”H»˜ì\òY64†÷IlÖ‹%âw›
A~@ÅØ­>ÛãNÕ²¬ı`-Îd¡ğóMª"gü‘å0+}uÛ†ÊB´v¼²nV‡vœ ØÜè:ûXa¾4+§ÒÉ/]EÈm?]7ÃH± 0eG!P–\zrP‰EÜj$ÎF'œiØ>ÖoæÃ¾WŸPÀöÁRºxJÙ·‹İy
…2™ŞùI#6Î$~Uµi9p¤$¯ƒJÉ[ƒÇ+ªé	FtM€M‰!AÍb«)—…YùkÈE/¿NèÊ2¥Õá^>ïšuAğ‘Vî)WÁ–_èk/;¿O{Oóè7kQ@'U¶cS!`&ÇÙÖ—b"–" ]­e8Ë¸íiƒW¤<Û#’Ÿ#ç|ƒXØÈ•Ã¢2ºR3>()ÆG"«Î~u#ÛÕ¡(mÎ¼pÈÒy|÷mkà'-ãÙUñN–:¡Ğ?hÒ±ó)áÔ=ÒJ\ÈÑ=iJpnp
Ğ©ˆğÓÿB¼Âõ}ƒêYğeGµì²bÍ‹{8Ê¦R?AkÉºš¿ô=I÷öéÉ98j¢ª|ÍÌx! ^”A™ÆğáN›Òƒ´İÊ¥”nv(Æ‡{vàø¨+cñi)!&—GØîN®%¾}ÅqöÃ´¡XãSC$ù¶®˜0#N!¸#|½Ù¬³ß²ñìø,a›ç)üÑç#"j¾~(cäëÔt§Doí4!nu`?­K¯ÔÔÎ‰MÍµ>5‰Pl=ıZå7J¶½8Wú÷ö1/æ¢ıÇÄ¯0æ®IaÿŞSkû1Ûı—Í”HóN3"àü:ì:sØoŞ ?Pn
ßK^ğ­ì3p?-Õş0u’}¾&QùáúÜr˜í’ú o‰ŞÃ.¯eå×~gë7×ÈÌ˜^ÑÂx)qPe¡ÓW3m±¼¢··d¹•øÜ7ı^ Zmî˜27
šB`ØĞû-—ş»aéÿ°‡J1IìÀïŞÍrA>há/W%0²-ëºµ"ô½FQ;#ICÈTU•ïkSñW®Î%§èW.6E7‘G&ödX#±y$aÕ±FñN©İÅ4ŠÜ%ò”Ş@¾.5	Äe«©–/=,”·jŠ	¦f4ş7Â½uVLD£>ÿ¯ª{ÇÅ½!ì€‹Ø~‰‰>wõk±ÍìpV5K	"¹ù.Ödc×ã<ñ€Æ¡™ ş@:Ğ[!QMõVª¿¥+ax¢ˆfP¯™mlmç9íAÑ{#CÚÊ„´o`7d°$
Ä±ÆôP¸K®hû¸¹äÏ ÷ò¬å?5Şı†~3§I	¼­Çİ5pg¿KÌhu´·ÊtšŸh[ƒ`şb·ªëHÿécdù™Êşµ°©©ij/Uç<|˜2²KW¾eÕYª©“®ş§á,¶Õ‡Â¡(ÍK,!Vñ=¤æúÏ¡½=Y†xëùã¤ìhUÖ˜ ™9Œ`-…Ìr½.v*Ìg ©PÚkcëÉu«]0œ{x¨n7°;l©7åÚÜœªwç¼”*StCVkğÖuãÉìÕL7®¾AäØ_’èhYrà& !ÈœiİÄr²‡Ff¡3P¶ZVšÚÓÒKè¦Suœ¹Lã¯^÷'©' “‡XÀZş«/2(&êgöËÎE@=>|eNÅÖ,¦Êh¦Å†jìÒ-Ï¶ûßdÏ¶ÔXÓ&ƒpG:’ŞÑÁ0ä‰\ÇÏg ‚¬š«±iÛk"!­»ÎU^piìiÚ¸£Í1cRÏX§Cjå½’ŸI$h‹%Ö®§õ4n—Ht%Øm™xŒ[¤5t£›à?
*¨ú½t¾ã¸C;»ğÌvPS÷|<¶©1CtOJH¸æ¨Šµó"ñµÌª„ú`gÉmÅò@l^>í¶Ú	È:àv-vQ(ÃŠg?
2°WöÉ¾­ø„¾%îPVş‘gkÂrcä±åe ‰fi^@)0ÚBW‚³üÓ	ğâ±Ã)+kçÙÄ“¥Óšá;º…¹y7Ş?Œıa<#W9,"cİş]ã
]x	“ÙûÂ±©) àyy@ìÇo©£Úóà¹|ÿEªQ/Ìµõß‚0)òé`*µD¡`±›eÀú20&LqÅŞ7{÷ë¯.B\´ÔijÛœx5†ñ¯á%«B™WàLÜîí–I_p;+Ó¹›ı¯.¼ÆÂ`‹İ§¿ûp³åÕ4º„‰Y 1û«*…ú.ó{­Ä6ù3…Ò–mñ…ıjZ8à=Eöµ@¨±,”ì?$ëåàÿÉö6<À)œÎWÇßNƒ®ıë¡ğŒ{Æ7wŞŒon¯µOŠ[åœÖÜÆ¢İ 8Ë?~»ökª¦­‹Û
7ì†Ã³.›»Í'¼¡¹¶NiÆüÅ!ÇÎ>m»9¦Èiå*¿r)ÚY•–"¿Z+X¼‰ÜüÌú @aO»ã1éïóÖ<d³£>ßO"4õvTÕµ”Şª!DÁ'y´é,ğ˜áqÇ}¿µ”Ôö£Ñ~l—VHà[4´Z;±>…»‹êê%ûôÇÒošJik9îŠ	m…¢òÀOkJî|µŸF3ûo]âàxL8MA™+S	èå‡á+ nõE…-÷s¾¥³R9uTö3F:½ˆxÀqª#Y$¶§øl[ÔúÂ‹´É¼Dl€«F/V˜„cè	ñıË•Ş×8ƒ‘¹Y­î\ˆŞ•_œGú×æ<ƒ»ı°‰ã&ŸüÛŒª2:´kî o?²T¦N®—Ò>Îm	©w)âSã~Ñ¨c´~ds~XğWl¿.×3ˆûN4ç¶{Ùè0 ,X>Ö*b+FBŸèÉ"	ÙdÈŠ®„s_w@2l6©ê©P·6g“Ê±ÕÍ†€¡Å^ÊÎĞ,‡ hÏU&u-MÖ™YÎ!Fó›„fqó¨Ôræ7Ğ7a^¿N±¹”š˜òØÂY]É^I‚â‚wnĞ>ÿ-d™TrôÙM¶?;‹ıè†ÒŸ¬«Ãù(w‘ š_£˜¨ˆ5ì““›ÆoIá?U‹'WHÌm6SBÿû§[jÕËïI¨­O$¸ÇÙ°¾à&Ú«0ßùí­Í¬íµ·ˆpÜíıÉíT5õCôDë_1Ë¹ñ!	á—¼‹aÓ@'Š]ŸªüKŠ†{ˆ²ÍN={Ï±“u_m‚Éõä`2ZÚí1¢ğ¨-øıC@™§şÔ¥,]_M®œÊ808Ø…ÎDŒµ—+r/Ê»ÑP(ìÈ×â»tTxŞ¨EFğhÄH?S™ö6Îšò8~°ˆP"ûºZÓƒôxŒE¨=ûÎşIŞJ°áÁ$î3£4Oæ/–ç).ölß<õ²Fhzmiø<r˜(è“$Q)D‹íÓßÊ~kŞF¯é2”ÑnÒn–¹'ù½g$”lÕÈfğv|§Ôë;
â³a½y&Şû<·õL¯©°
®…ö§X	°æõÄã•¼Ì¬‘\(egòÎp2§wØ‚‹]q£˜ls¼`Šé@Ñ‰|ml›ê%C	Ÿ-†AèiÅD‹÷;HåIøÚ/ëøÃ–ÈÁ…y(9“P½Ê![òõ,5÷VÓ0¹1zúLçP‰Êî¡g~Ñè“ÁÜö=İ½~ÆXÜ~l}fĞÜÁi ënÎ-g¨58.yâE«np98ÂŒú‡w{G¼Mt›’÷§ƒ2É(öúúè›…¿œÑXÂ—”µƒqN.Çp©×±:VÖ£:»i<Gº»°?W˜lPº )8Ç?)?0EítYiw·]şİğJŒÌö9ßœcmH;Êgt') nÙß{¥›+ò#“c[°ñÆB¹Ÿ;úR„õs:IIY¹~V gYM^¼£Şÿ­ÄA¶’îÊ8z ÆiĞ¶ä°y¡ºI½f­›éø`/:¥™S”&ş-ö ™JG^öc¨H`¤5=Ô5/–Ië5rÕÉ¿<Ø6ÂÃÈ8®£©t;I,r~êÚ¿èz`k=‡Rë!J£ï§vãÙödÂ]x‚œúÖC"^q[R ®
/t¾Há…©ÙåŠ”¬¥èHUÆI:¬J~ ÿáO»0$Pë7)RÎZH•kû›£x·e“äúA><¡B§k„9~G¬QQûeñğÕ(ìñûOhÜN‰ÔQÃŒVnú\Ò¼™–!r\%æu(”'áMu¨Œ²>•ÀÖi+Ÿtğš*±mz¢È¦uîñm#’r±h8ÿ#0$~ÙæêvÕ8“n¥vıåŒ(–l^‰JŒ,÷]/ş(à=º³m=ìçı^Ô÷H\ÀÅZwx±K)Ãıı²góîÅ9ÿ…©ÛúÚÄÿxíğåC	×{JŞ{£t¥V“X¯¸Ëi°~ô—“ÛÎ¤ŠšŠ½â<@šçYJ#ÔœZÿvZ©K¸×°ş~u–Õ¢9éÕ7š¸äècÌ'h„¥o¾OÆŒ0L(Tå¨aÚiÙ>gv4L7¹ƒ–9òÍ —’Slq_ñQş¸¯İ[í ó/åœæh<Á-+Pt›~åuÓ¸¨aş« É„#!s…[XxêüŸ#Sü·¨94£Ç„CàeÿĞÊº4ôqlNğ¾;"S§Gr]7>ºYÍ	ÑŠYŠ[qÀC|d È’qùåm/—´LPïÌùQQhua­˜p$Ç–5 “„ºs…‚Æu¿ª¢Ò´¤æ‘@óüuBô>uT¹ ] ©F@û-ç	ıÆI}©eî§øâğÒ¶›É<bkÓB<y3ùŸÇX¦ğ€[‡;Æ‰:v
~}!×ƒ\^<ergAÛ°›ÊéË¿ÃÅßŸ‚Ãx8 gÅm›‚­Üª_g‰Ÿ3·p¡
!L
d%ï€üDùMÄgëO:GVS?dŒH,4cÇe›ë³nĞšB,e‰c
¿âDƒ_½e8ãa[; “Úë^û¿jş*b]M‹hğ#oô«ó¹);„·÷£ÃëñÅôÉÉÂPfğ¨yO,—,Ÿ°%0´®B0`‘ŠÄÃùúGÆôün„f4‡î]·+Üoª'ùÊåÉ!XS4åq#¬	h‰ŸO®ÍæK4¡•ÔåWÏ,ßpÙ?ğ²è²ŞÔş‹éñˆÇ"´iÒlµ†¡Å4oÏAØİººYFuı¦Ò­–F‘’-ü/&ÍÉšmÆ±åÂ 8ÅÙ@&J1  y\õ4Oqtéİp›v	+PhÄÚÔOİ #µÊ8d·À`3mJ&9™µFõ\‡Û¢(­Š^6Ë)&í'ìİò8Ï5fzKÕß¡xD!	©Wı+ÙóÆª/ïà`Õı Å4ˆÖhIİÌ/b8œ¡<( vï‡Î¨şÚ½VcvdáÓıwû& ôœ-rYÿ{ÉşAß=’t¶n¦À¥©PI}ÈAÎëDqø2¶k*€ä€uÍW*Wÿ£­¬éÙ±Zk`gO_ò“‹b)¯¬pËñr7mƒ1ítşfLöºyŞ½ú^ŞYš>>¿ÍO(™Áğk‘ínß‡Ì:¬!Ğª_¼ç4 °ìb„¡©^­9Q»T”Hš=Ê–p¾ş}œÙ*^Ç-Ê€f^
@75·ÿ~n0KO\ËJÕ;àÀÅ~fjW¥ï™Ëwù©–ï+yS€äÏ6Ã¸æZJ³A, =}Vq,R|5Y÷÷-©ÑØçÕ]ÖÜØöî²İï!_sÄ(¶_ì%»\yìîä{%äìUD ±^ºzŞq;øN±ÇÃášĞ<Ş—d‚Amdº>uº¶r—Å„².èÊÎÁ¸<mØb­[9d×„P™iÒP¢¥ÛŸÑ½|ãö®ò"t]ÿa¾Œe•säé§9,û`³¾€˜ø^_AÏa\V¶ ã”lğÛ´"2UÍäõĞ†õ•u¿ „Šq+¾ğN„ÖV¤şk€›KÚ„Š±¨ã`D-õö÷¬Øy€.Ùû0›.h™éH1‹õ.¢¢wC_'
[X“Úr&öPÖWàÿÌx>ğ||H©’yl¤&t)’/f%$3¬CP§*‘Üédô„¬İT'XàÎHFeKœ·lLÆ¤ïGæ8†M¬F-s$ü"¶)'|F’Tgßh&¶f¿­İ†Sğ˜CM>h®£áÔdºŞ‰NUö·k¹YŠÚ»·üC½p-y;h‡3P6ÇX7ÖTu–¥Â	‹áC84Š¬àÄ3¶6³»Ù#ÀÛ
uîâ±QhÈÑ\ÁÙÓß´{ìvÙd]°‚ Åú.™‡˜bœßˆ¢Ş7÷åQZ`ºŸÊa,ÿBbáû*UtIÈäÆÎJ<L¾yºBËÈPøQ|¿ÇI|±Ø!nAÚ·”|êÌj« ÛXÛ§Î`sDS©Ò¤R©a°¿:ª#eA¤!¹Ôm -zh} t‚.ß†ò!£öB·P–BƒV?õ·-\†şëIcå‹%Ï5Ü²»2¡0°iÕ·!ôô_ë +Lı¯FÇ¤œ†‘ÒğrÌÓ›c½3R‚Ë• BM™Øû:ävuq9>ÄÄ(OÌÈ´®–îˆB¯ªñÌÜˆj¿J'}ùU.ÒbÂÆ„Y¥½9#^â¶nŸí»XhålëşËãÎ_jºæÊîD‹¯Š%ö*‹{÷%oÙZ1›`†Ş½qıú7À·€UQ™ğd¥ºÃß¿Ulğ'9Å•~Ï¦­Ìùà±%‹7+ özaËKi±××bÚf•â±qÍŠüÄ©ºT®¤
#ˆe‘Ì¬É¸Ÿ+üaĞT÷Ñ6³æ™ÏÈ¶ct'½Ö]}u:‚×¸–¤¬i3†—¿KkÆ_g¥u]¥ª9/AÏ‚]XÛ7³òâåõ?†Œ©ÚmO0ÈÂrmwÙ¸„¾Àivƒ>â’æ{ˆíf!RÓÆÁ+ğÎ«/&asÌ .2’î©YaŸH·•uXÉñ6
%€… ^ŠÆdƒ('!éDx`Pb],a%ÊJ’ÁÄæ—½Öí½ë0¸úbŸ©S í„ùªæˆğŠØ…ÍÂYãH³	dŸşÛ(°œ7Ÿ7ÙAu!¤’';7„ˆ·Áá~DÁÕ@õ‰o"ö%ø©²ÎFW!L±X÷Rô_³`.Dxbw"Ônz›5,9º.¨ìOßŸ¬ÊNïùÔbA@AàP`S~¼ã0zM• Ø
E®Ä-k([™!	¨^ŸV˜¦ñYFºl\.¦Ú[ÌÌ•TÍHjˆlg>'£²X6l(B‡©ß‡Í¼¯3Ñ¯€ª ğ{l2â ãäê&Û¿©WO êğ…Š<.]æÕˆÄbr†ÿúÃè“Ô~ÉˆŞ—& tÿl\SäxJÊqÌ>#ìn*Ìiwƒ­´ô“†ál½œ¤ùx§$t@R–ù(ÂÕÅºª-(ÚÍ¿A©Y7môC10}§;‹Š@™ñ6ºµ;Œ'ëµ®®Œ,ÅˆNÑšÿÉ?ˆDj„ØwéFi}³ Ëj³/[4ª¿[EÕ˜ 7Ha)YÑMù}F¬UO×ÎÇì‚øù¯ÊtÿüG¤=ö¼;s6ônÕ¤°UÒHb/rqÙ9NaNÊI^ ”%èÙçëHåhÄ@ê¶ô¸8–…9)Æè8Fşÿ?°~m*j®†èsï‘GÑe±ó¬b¿İèl¶¡hßÏªYşîĞ£«-ø¹»es¶èÂRm,½£ÑëİyüâMÇ0—z›§‚uáùØçIljÔÔ»)î¿ƒ®ØÖñÚ~Â¡ö6%ÿà¢­L[[êæSY[K·~ºhƒÜ‡#ÿY››aÈì‰ ù^ÎàÌX ;Ÿu	¤êÑt–NµÁù•ÆéÜ²)æg¢ïòøÅJŠ³JÔæ‰}J)í˜!ÙI0<Ë;I`|Ë-œÛd—ÏÈ®áÆoE€à_›WV)Ìßê}Nµ|óÒ·½!í{åárgùZXá	‰wÒ… špe+jõ—<4„É
Êì”üÁD¨T.(²8—[¶»Á(&øÎWN(;y •½¢ÿ(L¤A´ßš»5Æºg³ú•ıª”®G…eYª)¿“N%š@>Ó[+‘›ª§9Øó„ñè÷ıfÓhÊûÊ%¬&‚;œØC°Õã€Ã—_“él,¶$^›xVÂj[K<êù©Ñ¼Ûíp[È{¸²Õnï‹¡Ë2§È¢©éÒ„¼[”ñÃÿ—})ìBr9´>-òª“{,F+qz©?(—¦¬ãº7ƒí:I¬ır!Œ¿ãRâ	zÅ¯±üÿƒ)+¥Æ9»›_b?v6àø|¤íÇŞ¬ÑXeL¯\ÕÓéŠC¥–1’€¶^ó¡<ò“ºê®[r`Ÿ”,u3ÆpNašøûÈS(*A#M˜¡¡§DN$¶™<ÎPÆa4lÏ‚Y¥2„.İg¦&¿égkl£×rÙ„™§ cSÂHK˜…¥…‹ ş+Òš@½/¹§5‚E‘NõN$^’ Àß.³oä6š¾6Å«Á›"ƒr)¤Me˜Xµ¤ƒBĞI­`±Ì‰…Å	î)A<ÂIZDë·yè“Ş_(nåÁ²ÒÔ
ıâo@Å«Ó.ıvîPĞq4áëJ«5®ôö>›t®¦PÍ-iòè•ŠeQc»„™Î¿×ı^Øğ)£fÿÚò‘/‹;ìZ§w±V¶+·š1 TÈ£Ÿ…?şÓíàÎNëE·©?9»­lÈÌ©Ó'2Õ2z,ÿŸJZô¾öÑ#Ã¡p»š?0w½)şÄÍ5ôÙè¥¥°ÏÙ/|c ›^ggnÎQ‡Âõ0]w+^ÖW_m‰)ï!ügáçr÷ƒàÊ—s
Aõ=¼¨“¡æÇ]¥½üø’ÆŸ4a•Y7ÅÓ3œ2•ô´íáœÆT17ğãE@Ù¾LŞCÛñ¹q×T7GKf›'*›Æ³…:ğuÿ[3õªA ƒZÆI„dô‹#"}ùĞ&,¦ŠûGš ı&gâ=Ş,¿-Üjò`‰X[+š©±}`ÕYëô½JkÓïŠÖfUè_7“=Hª.¼½¬g‘‚ÜnfÃR¼a¾üY-*Úlgò8Y’­Ò;…è1&q:
Q´4E‹: Z±UÆò>v"xç+H²[Ç¤ŒÔÚâÀK?ç;nÿ:]:¦<ÖÓVtXŒn"j*Š7Îî¡vAcVìG¼ùêƒ+WÄv8± V¹1%e¥ ×ŸpùZò4Ìj<h-ä¾\¥¿nÑ“âº+R‚Umi]ûe'f‹
®¦)¤‚L}œzjkcÃ‘gX“ø-Ìc©ĞÊ™¾±Ç€-ãÑ¹Ñkªökƒ¾ï¡tH©E3ÍMsÑÛá•4ÌQ- +‹¤PC•Öì5{c9†·tZ‚—(;±‚<» Ğ¤™â¦–Ê’cÛ¥%¦¼¯ĞËÄ\/zãt¥ÈR9±ibS-_zI‹òfëŠ'ÈÏâÚî8ÊºÊ„º0³ï5çv€í¾•¦a~Üx%OFf¯O“ËPKI)Íİ
å~Uª™O[UõMÌw×šäî}^i?¸¨ı ¤Oé\SçnM€í5Àu‘Jwà)âß¯è²ÈØŞ2m\¾yäÀ9ã'07EœÆs‹	i·†çÔ¼× œ%‚ñ¯6Íœ[P>lÖÊ£I¡àÙêLjô ³dSnö-Àr½Ø,D¥Yí ·zˆ’€DÌ§Z¡Áj
og£Î©\´gÓcÉ‹¿,®òß›Ïª+¯~UêßÚÜ—¿ädJ]{‡»½¦Åõ’M)ˆ%Sn7?u%çO˜”?•?hUPT|Ó›>Î4Gç¶+º8hŠâÈÎ’ÓmM¸t•8Šô‡Ù€uqvçò¶Â§¡Ppy +˜2Ìùİuô-Ò7Mˆ1øÀf—:ÈÉN³ñ)fjz_<¯÷z¢7[g&'MP÷éi>6ZK¸eKc…9ÚDLvNzéÔõètñÜöÆõç÷œíL—Ï"€`±qC	=Ø}ËÂµ§2ü?¨³iyÚkmœıêÓ¯ëÍ©§eáãÃÒ³ªË6rø+PQ%»÷¢{¥)„¶ÜÑ05†Pó½g¤ìGùä¯­ÿïî)‰ôşÿRDá†ÃÖqub€©‘¥Y`Eı*Ëad`&´Gí2¸¶)›Ù:Q‹™GEj÷ı_øàM+„($¤¨xT9rÉ}	éöuûñh:ıaVBæÎ_HfqEWã.ïÀ½¹0Vq‡µ5ÓÓ³ÂƒˆşM¨ÓëøĞ÷P*„ÛéÔE¡b‘,-ê÷äÛ¯#Æ¢ø‰£¸Bík:“ï–¶ÅJr‚·öÊ•Õ¶ôblF«ìô=¦HÎ¼9‰ØĞ.}Ÿ£—Z3@õ°CvlÀ¾fŞ4õ»³A¢KÄ2§’Ëu¼ıo¢,›B‚òxQßªÅ5·xì»<¼(K”¬.îÒ´†#ùœèSåY§PLtt¡èr_jI8?¬Â•i¦÷Ùî¯‚Ó.°·dH³Ÿ@2ª6OÂ’à÷ë-	8Ô¥¬…oN8
Œ¦áÒé # ú%Hq™™Ìûü‡°|=8<Gä¡\5–`R†+ÍFo%?>Ø(½Ó£ˆÀ“Ók
òl°0¡Æã·áe~^~ìlt){Ñ€±j;îf”SÏ)W×1(«QØô?òGÉ¸ãÎ‰w	WÃ¾’8r[‘¼õğèºEÿ!l.œ<aAVŒËàŠ€66(¦›Ë çge@g„—í¿-›Ş(¶0œ›Ì<$§aõ°œïk™?ÜÆÍ§·ùóOĞ¢;°Y ô^\‹÷È	íT×5pñfèhN°ªB)x ¦7Z|â?£³Í"	šıß1{ßÊ|îÕM¤¿§M’”Î´xdü‹+íOWû,Î¦c3s]ôòªûÖ†Ï]æ;ä%×ÎKw–êq9w±e¦òI5vcR3<¡„ÖØè_Dê>ÓçÁdy¦ó1#¦–fö™·}^ÏHòºŞ™9kîı‚é¹à”:’ºJtØû‘îE4~Õñ@ıfÀ¸Rè`iKÂèmNòäZÈµî.ÔÀ¥¥ewù:ºDÁ¼ÒÖÖX²8ÀT¦vè¬øfwQwd­ì,=Râ‚.¿³²1›=9ø¬úå°~?ÀL5õÅÃd^g½"nN‡|BËä=y)0Oé3)bæä'™í÷&WUîXm¶ØØ‰¥' ¯ÈX©`Óµİ“bj¼²×†B€&.@õşE+?#WÇ^Ø&N$²·pk"Ç |Ğÿ X…`‘fªGP^x_lò¸È*XŸ¾¯}ïL½±Û—˜,`F“ª«^¬¡Ùu€ÀpÌøÉ.Æ`àU÷ü›e:Í€5¨7K«O™¿"Hó¼F ¼/D9Ö«a#İB(rT½²¥«Ë#g¨eÇ›jºáa3Æ{7+§›¢à¯	oºÃNÒÅ¤~{˜1Aáj¥‰¸0;ûĞŸ,©Ãü¯0ı¢Åë ³Y|û¾$œñˆ6mm
ošW¿(‰§†Øã[ ûÌàµ'Ï$Z^İ©Ù¦ê½¼»Ğ¹”ŒO/e9ä&È—WBx	¿"
sj3y#g§TõşË—Ñ à¨°Ìb®i0şöÀTéĞ ¸3õìbÜ
Læa™/’Çü§ÍÓÃ/—œ„åèÆëÚ>5‘ğ’Ÿ	m¡I¶kæø¨».Wô„r17eú6' „Ç¦,N7æm°ŒÛ/hD /bëOÏîö™0*tpÁ}oI èü¿¡ekÊs)é
b^}s•ùI\¨ã·*JâFĞ®¼Å ü?«³O	”á šæ¦ÿÈR¡õKJœ<x¸`qPæe¨WK‚(P‰dĞí‰§Ñ÷dß1˜*}ü¸_Nl›Ü™t,csaØü®îhÂ…ˆ ›ñÂÁ$q%•$¾œ“€Cš%V=ºƒ2†óÑ- ™Ùî£öHÊ¢œúÜ9P£k‡bï`qAœ·9Í16ËY·‡Aóœ)Êe9%e°¢ñşœ¶H|ù¹ä\¯Ÿ~õĞóöæMNaNƒhÂ›“H!>e
±~^S©Ø;ñ³ÈµëíÜ“(r ì!Û–À`Ú‡íşãg÷CºÆÀŠwŸÊ%úÉ%+DÉ†åó"náQğ?ê”[©=F„Ûéõ-4PV ‚ø›¯‰JÏs÷ú¼Æ—„0ÀòQBä|Õ> Â+…ôd«^o‚n ¢dŒ8¦Hõı%mé(>ô‡ÖƒQZŠ›åaÄ3ˆrÉœèÍåŞQ-XòyXÁ.Ö«Æ‚À²^x!‘5]R¢Ò¸¶¸Å¹×õ_š&¦ûÍ¥æI“	{¶	9`cuª'ù;†ìñ÷>)@‘Q›pÔyÂèSƒ‘ö Áøğ6­ñÇ?ÂiÁ«j]ˆ%½/hQúwŒª*~CPw{(íi»Fû‚Ö¤q'Ì¸¦bšÄ]øöŒ}0Oç ¦ÄI‚ŠNÇcÃJ$jtÄõÏóÙa.Xü{ğé§µÖØi¿ÊüÀhâ%‡òÃGÖ
9PßW@7ˆu>³M*	é­Dá5²©FHòÒ¬8¼\éiÔ·èâyù¹56+ê–ˆ#g6L¼m‚©r€Öm?ò±\¾Á„Ûğ†šÔàëØ}Ãisu4ëº2K¦«»'"ÍJ©¥ÎIø…‘(³	•sœe.í<y¹=¼¯Æ=ÌÓ].´—Ù¯;»û7[•s‘áùñÌĞ"µw÷bè&×…è´®æGä‰šE½Ó&M–>ïy—ˆŒU¦ß“éİû°İnv#Ì7 ÁëûøØLdÛÃ×ŠüXŒˆ¡Ó| 7LªßrrO<Ú.ÔWŠèÛHù >Ó6âê˜>A*)®z„8ü½#•oHŒ¢¢^ƒmË“ên¡zIrx?´ÇŒ»gõR>_/dúí¼òãxY./$ÒÉÌÓKJ*`¨àx¬Æ4]Á=¨ÄyŞmBÎëÌP' ÍvM+ß¥Ta|_
ğG† %ÙÁz^í7²fu(Ï4Œ>æBçàr1áÄj+¶J§Ú§r™T¤ÑçºªHÄ`—&˜9©Yİ!Ò†>ºú’{Ë8\HÀè(ø¾×a‘Å«NÇĞN|+Ï^JnjX×šÉ~ß¯Üî<Ù”`Q¢v"y€ÂlkqÓ<è,û„AÔIìà*ÏCõXGÏÅËĞQÛè"¯[Ù9"ÇWœüƒ!Ê&Î{qí³V Ş<†yAD‹_L\1Mÿf˜îáWñ£RÓ“I“A¾Ãµ‰ÏàQ™”’xyª8@rX\q
Øq:>ä ÑH#£‹Ú²ıZ³¦I¿‘SÊ– U:ı¿ÎæAÎŒë'ùŒoài‹Ö4îâ‹¡cıWÇSf”4?ŞnÎ¼cZÀÁìºáª6\|!srÑMRı{Dq~O÷(ÓoãëS¥àÒ°áÌ„£i¸|ÍôD·U9u7ôó¤)’Ê8º“ã·ôj5q`·ÑŞ›†Lªl`Xô+†øÙ¥DÂĞ¬¼íÀôGe«‡…ÈSÈª§LdQÜ¯³ı£~ş•sŠµ…0elÛ¸í÷aiÕ e!4s‚7/\½CüX»®ôE†hOÀûuÎ€•R-ñli?‚^…/&K[®pu‘á†ÉúŞoJE¢a×Ñ1è4áĞ-é‘#‚Lg‚Y tüeÛÏÇn,07†»f_xKFqgğïù–ç(AÄÊE
·ÉU„zo#ÆŒTd !\¤òB
NìÙ€ä
»Şœsoƒ›M#\_JVùí“xÉ
%õš’®§¾¿­­¹PQyõê­í•EêğøeuÆ*Xr±e½YÊÙ1ÉP¥¥€Èjè§î•€$jŞVæÑ:H({_Q*6’Ÿ?€·àÁ÷8{Rª¥—	)
ë?.-Ulá.PRt–ê4
kª”s’ò¬iDeyd.”V/'^ç	KgåC™›Ê‹kBKëk<9—Vú-Ÿˆoª§¾×‘Ùgæ1âsµæÙí"
í4ZÎs ——®Kª,œV¾±:sOÈMk­ñÁR­5U^*äíiº~u¢¶ÎİØ.®è<Õoà³¦ˆ½,01Lì—î|I…Ö“cCëA{ÿ”s'zvƒéSjæÇTÇ\rµ{ÃğdTÌÈ²R^JGi…kîfw•	|ßy{	¦ŞüVŒ7¶d‰&E"IÅâ%£xõ6âjœñ~&¯áÀıp] a9öé"“ö2úë`o	;Ë·G‹¬¢ñæD¯5íÿÕ®½¥ ìÔ¼áäŒgmÙÃ4ú#–^vGÉîÈ¾Î%@Y€	ıÿØïZáÁ¡»®S=zGJFö†â%Çœ+ìÔh(è†H*UN„@#ÑÕ\šğ’qwLâÃ bãfn§^ÍUÕ³åÎ.òÜ^_úGäFïYJ‚Æ3Ùk4şê;JTj|€FutTN#y¶8J%bÔo ûšÔ‚b‰åxÂ›İ:‘¦˜yÛã³ºWšû}­Œ£…‰Æ¶Üˆ?H1ÈÀ5Ğx,3à°û‡3(Ÿ0b0®õ Wš+“ãÂB‹àî 4c%#©23®OÉ¢İDÛÕb×ÏtÑ[@Ê¨>ïÔt{DEµÈ7e!Ğ˜nkívSSgK‰g‡¾)C¬&¨şÿ5ı* uD»3:¦üY,_âd´­$D´ñâMæ±)ï€¸ŠL)<ô€ˆÁK)iá6åãöäpßDÆø¿±ªuÕ%Zër¿—øú A@ö°êğOÂÀÃpRÊ¦¶´KÉúçŒLb®ÉÏ[Ï¶ã yW­lTygç ¿äOß‚Ë³ó§>g:]÷ÃzòNK£U<C€\9lHy­cCzóhfƒS·íİ­è”ãI¼ÁXõê€œz+“¾Nb xÌŠ?¡A2<JÊşl*Ñ2‘ÄQl"¼æ@°¼˜‚Œ´–qg«¹#ÿÎĞÌó<"¦&-NëB –^S•.0»-˜rR^“ÊÖûbÕ4ÚdÕ3”lÙœ›WCd>«Ùw)šO`É{Ä{… ~3•TŸ‰m4ìÜ
(ç{`ÀfÔáÆê[Ğ³À!çÈ¥YüÔq]ĞÆS£²˜•#¸%òœùz	áª|ÃÓ¯FJéşÊ/èm‹0Za»åõ¾ÈÀ~ZÎóÅ4|«Â2#ç
„oÁä¯OÚã3ŠàÈXQ4¥à§áò#üâ]s Ği{É,÷†NĞ\göC…
*éŒÂ/D¿ÄpÍ­«“D€fI·pXälÜ8Ò11+eÁ¹Äa‰‰¢ºìäŠhhÇãA.ô/ºı{Ö„Å§]m	^Gm¬1NÎøÈ-Eòu¨\QUÇÅàóã«Š,dëbGµ¥•şÒ¨I½7ñSÚSY#aJ/';ÿ’'Ú1uÈbƒ6ôfšMJyj¾]´µ*¯dÕMe¨âøü_Bä•µe*–ÖøD¡¥g­KıÇuÍÀ‰¹ñ‹Å¨ÈcÁÍÊC‘èîJ_f…j×)ı¬CqTÆ±OîSûïÿUÑÊ¡#U<®¹b?rË×i²†¬}!§ì"ò•<OFÌırÀìë6vÊõR&±z_õj)»İyPµ
SÃĞwD:daíçTèˆqºT3êM¬Ø›ŞİY9lö°ÀÃÔÅV–gIondW8kz;ëÂÄs„%f''ü%â;«¸Àï/?%ƒ´TH–÷•Bƒå½ÈB+
´ËÊSšÕ(Ô§vú­Q–³-Â…X«!a~ôØ½{ŒCÅd0)ú¾³]ê;ãqb–FÁ"³ÿı$Öõ*`l tÜhkP‡ğ ôÎıKˆÔ'Ó*æ*êW˜y™Sb!%¶¼Á† m0ÌòÏ­c-WWü)²_CÙ¡ó¦FÆ¡9»®QU
!Şg¦®õÓˆ:Ä>]ùİßŒSÖ0¦Ó¶½QÛlÿø‰ÕPï¤’P~ÛB¿O€Ÿ~TPÓşŸØ} ™§aJkş¢~]á°Ÿ€- Íş—š©ò¶óQëÉXê›A«-f6iŸ‚–rGIÕæ
¤rytÌ,»‚{#;87Z×l”x
ôjDêüæ3}/6Z3–}Ã²µt" ‘Ø9‡ºæjÙÕÒ3¤”x	PÂı,ooãlŒ©Ní„jƒˆŠQsuèì»•PUã 4Štƒ{ßÚ”&)v¢œ€ògñ¸¤d£éØ¾=v'›rv9°nÀø„.ºÁu"öuÃÑO¿!K«¨éJÄ–}•òHKnödÈì37ˆ®^(å£àçŞçÕ§4s>V–äáÆÏu˜­—´şÛcùo²KEŠ4K…«øò>ƒoG;´õËÆÎôÎ[I^)ùÏÀÔínuª‚×¥ZB-=Q­e_äŞ¾¸ïç^-KÁ#ÿš6„A&*}­ŸçØ`¬ğpãwc~‚±ùÙ ˜Úİ$åÌ@<î˜Z!°¦Á…!Û‹»Ç0¾¶aEÍ`Z¦øŸ?¥Cî+»JÏ÷½®‡0)wîgú¤¿)¦³ŞF õFça"»ø°Ø±ur^”=œÜHrô³‰Ü%˜ÁCF¼´e¨>Ğ ŠpXÿmux‹ÏÁ	¨u¼'ÄmKî.óÆßİ¯´Ì|%Í8–<!Šp¹ 7©ên=²­’mêJÕ;SN=_§ÛÍ–Ñ©.:Â²hÁ¼
r¹%Ïëº±8¥—!6h6Á<jø…ù‡¸{ Ÿ2¿õx ªd—_ÎN+ö£
“‰ŒÎÅ|oÈD>ûÎ¸ëW´!ä5e”$Y¥JîpÙaĞê‹'”¡™©.şê}íY^±…_"ße‹wXìÕ°™½× bÔ™wš¦ZµÏKì¬fà€Wé%½‚h?™wÂHŞ¼UTä­nÔJ§‹à”ñW@w1ß–‹¢Ñ#bäqªr5íÒÎqnë‹§Ó§{¢%İ½ĞÔdÀ$†Êç7M R0Î5†\lSH”=%+añ¸Ÿ¸•s;É¯%|g3j}€¥z¬ÚT~¤`/Vƒ÷á¯2é¤á×°0£pû_Š JB ±ËÏèµ‰¿HWÁ~üÎJ”ã;“¹Q¿Õ72ŞÌhş[¶:&ŸÌköÁ[k†7 xZª"béÄIãÁ–[:»Á†ÓrÃ>Ù$‚l€'QÙÂŸS×ÒyZFm–E“¹«jrKÈÏ†c¸hRµƒ«²ÁŠg/ÔÙ¬ Ì?~k|'TrY9ĞîH'ï ËR3ŠkóX5®§£²ô-ºˆ¡öŸ$-6^h£?½ğÇâiîŒLë¦¡d°eÕŒ–³ğjes$Áï	× ®™Ú%Nÿs½úÚ,gÅÉ‹ „)´	(9,7`óÅ¾wÆĞ·í*İP¹ªÈê`•p9N'GƒXÓM‡˜ÈİËğ'k¸/ëÊLÏ8„òı²§4šqTA€ñ°ccçøôè$`ÿèÇTzßv‚q~{ŞYÄÙ“œ†`K™_M[Tj½ÉuÚ¡)ñÀ¤¾Õ;,?Rè" f@ö–#'Z¨#æˆíf¦al¡ë4~ u‚<â¾i°©Ù^ë ’¶9€ñ¸ J¸¦|ï-aŠöÒÒ‰7EP~	Ÿ¯‰şe½6l±r¼â÷±ö y±Ê®š…
+;LæÀâf¿‘õ¡Ò·Ë,5ñã6ÅFì	ğ­7Â¥_»êp‡¥/W45—êÊxl Ú‡2Tá#×`k¾¸¯ªïaï•†ŠXZ;jPfQŠMçštŒñHJ£¾BÑó±S´¡O™²À)ÔëñÆ¡mÖ{½£ƒ~N÷!Í‚ÊvéØşKï)íóíÏ(»BE.ÅRÀÌë°~«É¦yågíGŒMx–©†kÀÊ§ˆkœŒvó…Ì¯Í”ZûsÒ®¢pd®«l¡¶í8¦¶dœy†Ğå§`rXvoÜ=™êíĞkÁùdıêDFéÙ1g¥#Ó^ùh«èÕ'ü{›ˆ­IÎğòFë3ámÔmª6ÖhaHhúayW6^*Û“íHğìœs‰aÃşŸg®ÄªIÌáâçl£F™bõVã\×‚ÕÀ1MŠ,Éôy~;Ü§‡øYÔûáz©AÚİ]Ëx‘şoerÊì¼T·§°|ßNï›Õv¬‰&Ét
¹XË8ÂÛ07E,@<?ÂûƒĞØ6¥YıİgL”û÷b ¦ã:kşÒAªY«N…³›&÷‰jš¤S‘rŞuFí, z»hØ¿‘xûôQBÃÿÔö‹ÉœôÍßFµ¦"zx)¿&]£?3¾İd’X†+E„›r¼€{¡4tÀ©•]C'Ç+z÷ÏûÙG·zãâaCh]§ VÛs3º!v×”ÊQA“üĞ	Éä$æe‚=<îû6…] öò+µ¼²éÜIvŠG€$ÂéÓöh÷	"`êLt_ÓHœSÕ±‡sÓa‰¦”amùí0ĞR%×_|÷åîW:ôM-‚2<A”w(¬‹-fµ\m_ôŒ¤—ˆåıÆ¿îA
æ9ß¾ü¨,Ù$Ë²§bDÀÅµ!ß|î;(ÜÈüF)ß¢+ğó$š`F®9:²L%÷…ÚæàŸÑŠfh†ô!%ÊiUw,äë´›½yGÏ/3®:ö€Wïò*¡éExŸ gƒ¸Ø—oÏÔ«úZŠÜB ÖÉi°°iÆ¹ä|m©uSòçà”T41&kYÊöØv½(YÁ~×uD.üŠ_hbÁçFş¢¦?âğ; Wñ4“7­-¹ÅÙ0ÀÁWwî¬z_†A˜§şâ¦¥0˜¸» Å‡’&@UÊLÃ¢Ğº®ÿT·^@ˆÆ+êÂx`#Bi[={ÔÍ-¬5k&c;rôdXªSP1ú‘H@ˆç#6‡Kå"mPİ{"uˆÆbÓsÑ‚@q5!ªç<787ÅûÀ Û}y^vå?»õ°+¦ô«vHıD0f¦0§Ò±”£œ—OÎÈÎ!jEzR„-íˆˆé+£Û üµÀVûâaÆWšSgmÅ?¹9Ñ(;¦ñ’Ênò4Ëfº»Ú&®Ú/±¿Hi´ûIÈp¢–«dß|wÊ—Í®ES¡küÜ{ßõ˜¿PœÄÙÇ"Pˆ¢VpAød÷ ëú÷ÏïeÚöG3İp<–[½^MŞEŞnvöÀÇ’,‡"¡s:Â·†Š™©.É	ÑAº,›£û½Ì1•Š#*¶º)?[…JÆb¢©&J4ãv6†zi…œ÷t]ÆR<a‚~"¶'³>¢É…œ›ãÓ:´›±‘J'b·¶$%ò|ı–°@ãõæËú_˜
ÇŠ‰ƒÙyŠ¥˜.|åu*H”d ~Ÿøîp½)wø±	³ÿ>C©ôÃ¤´OQ!?Wu:wÖÖ‰Ç(’n]Ä§Ol;¬ò}~Ğ­Yõÿ­F>w}şñ"³¢0N‚aoÖ[fÑ#³àwyUÈ¦Îb ÑûQC‹Ê¯uEX=Æ¯¥äÎFQ ¶¬(\’•¿÷™Å±	IØKV§ñÖrm+ŸÀAHÎC5+.×'·³ƒF¼mÏÊ¨ö™©M‚‚ÀÇ¦ÀÖİŒöçjê£f±õˆ8±ïĞ³¢aF°÷ävë7İ®ãÛ—L³›í¨wq\2S%ì­º“ß"z&†ùŒCøù¥ÉØ:9Uv‰ûúÁ­¹¾ÁnÍr±—=~¡¾¨:`\2« $Bğ°éèóì“­ÇÈCŸÃ²µTr§*Š§6
İ:ôVtÚßFZ‹fÑéz×ù¤eaÔ‚ÄĞƒˆì—¦Î0ß÷öÁ¶¸Ÿ6–{)Ã†šZÚ;JôüdÖ–Îƒ»ÈÑPMôŸíüå—îG£÷e<8j•<Ö&Ì´”ıµ
­¿µUÍ_zedûPáäZ€Ó{˜ÂZÖ¤ŒäÍÃñ	òRZEFÊ`c©€œ€È¤òá'ÜeÜÀq×ÖiñÎí"—R¤o óY„—<ãÊaºüU3@æŸ‡…µJ©#Ä8&Ñwéà²ö’Z»±öÛz,«êUDxÕbóÖÆÃç(FKª¤¨™€åÄÀ…âpâ¼à¿w%˜ß°‰7Õ	Õ$‚cˆN¾Y\É;=´œ.hŒ ˜Ïú*å>¸û˜D}NˆFüÙS2[¾¢–"¦lXÅ÷)+ñjC¶š²YNE0²(“M!ìOûÒèŠ'í—aÙ§ßI ‚s›·ÙèéÚæ¥®ê½ÜÁ'ÿôu84=²;8»M¶S}SeÀÒ,å¤=Ê–´ƒıßš$êèİmÏ¬ddŸÊøÑ¦¿Ç'Ô(vu~A3QÃ;ê–í?Ğ˜€Ûµg^hà‘àá®Æd!QU!¼L÷Äe»]©˜u)ÙàX£ *ô\³p®Cäû‡W_Ÿ$²§ÿï¿¶‰ér¥kZ,\MtˆûùÅ˜n”èÙvkÊi	¡EŞİìB#ÀO“œÄrÈXŞQ¸My¦:5âÎÍ¥ø˜SÂ°fq­Æ}”-¡ÍÜeaal/ÆjÈf,a°Õf&CEVYZ@àzÍ«ãVÌEÕÀ”G%ğQEœÁ‰é«¾ƒ¤Q€n·PY.?;üïQd[*ëÙZõˆ(mSÄ‡Ó·ä­®„à¾r²/lú^ $«:ïâŸÌ7‘K'PGÊÎ@DLv0ià$}gBÔ<›-Sşæ¸2op¥ô¯gZJ›Éé?_Z'bäÈ´êoçˆ™|ŠŸ„ ûş>d(|İ"?Ò”Wú5|lXı1·º1“÷"ğ`B¢†?Ğ®äV‰cº,’Çk´(YHèe~[3×ü£H¶I5´ÕŞiÕXiëf?fË^Šì†Òå½4™´ÕluÀX®-äB†Ğ¸Çˆ{—Í¿î[×V’„/õõ(¢¤´‰©½)­rœÿùEò°¦éizºÍ:FK©òõPíæ¡@š9ç}º†>ÿ¿¶¸ùÇK{Ó)¢DÓaÕÍc§ê¬>ósf‰€T sÀVN8s–Ì,WÎ¾ÉM¦š“ş0~äLHà˜7d‡¶œ¿Õ .°tÒılüWk‹Z1ÇM_ :¤Œ0Ãrwñ¸¾\Ï›+5jğ±„áÕ«/bOÌ`£$ĞİYÇ¤6Ÿ’O7àóªÎA²¸Å
c§Á’ƒV¬AgÚı¯_§Âa#ÑâÙÓú¯îH¨pZeÿ(½ä†ù·XËÏ‡­€¥˜Wm+ÑÙÉM55‹7®)|{t©ªı®?#n'8»)ˆX|@)ÏC5„©JËY¥*«‚o²¦"9ÒIıÂÈG‰–zã¡¼%ÊSÜë\ÚÀD»=$À—…£¶Å®CÌ»‘HV›ö]ëıHŒ­i­T¿â²£äjÿíÛvº‰èvøã0IZºı#~btqÒ&ú’ß½ïNôèT%»È Ë‡?Jqœ’C5Á¨t\Ù© ÍD$¿&+
·•„~ÆÊw“±¹£òèÓ–€{·Ñ(·ï†b=ş
­æ8ÍDäJÊÿ¾³Æ¤Ñ’*<@·GšM=Ò	ò_‹´$"ãC(_	CøÈÆÜÅvˆDƒĞÛª¼sÌ±°
àƒÁfa¼æÕqŸ˜»Ë¤ı$›cÃ¯Ağí+Sf
£u.%Òÿ
¬ekĞºôˆKfâ†+! «¢deşÇ3#¼-àá û@ıöì#ßBë:¹{Î½ÇÜ*ˆåFM9ÓŠÜ_ï/ÑDàü-%Zcúg_›fùŞ”àŞÒÍÒÅP³îè†ëü7 £ÿV¼f-¿íVÕZ
¹L™zA˜&Z²„"ißÇœô2¡Ñv}òu+ê¡­N‘v¾/lq¼?ïßc?Õp,Ê2ªŸË`~óå¨ûØëw·±ôDÀ†hP@î§Tìhè¹Şt¢Î¥[3#“x#bEë,u0ñÛïMwIat“:9§›F˜§€kÚP:Mä˜XaÌ]éùp}|¸ÉëK±Ÿ•íè£cĞ"×³]Q|=Å>Ó×ˆúçù°-q`fù]çšİUp6ÄC(TOïü[übhŞ™ÚQìçs)Çú³‰ÑıIò+§úcïQ@Ú5ù3f^Ó)í½ı"x`¸§ñû¤İÍ¶µ;¯"Q”ÉXÂZ[ˆ›©l¿8fgğ8'şW·sÕœ!Ó,ÕÅf$±eé1é¼æ)d@eÄZùçàgªqîäu+è’û@’.¥¨EA¯`FÆù%ÀYäŠ_E˜›G½Ş¹ÿ©.©3!zM81aü°ş·_ç\W$®Ïı~…ªV,şúHºÅ`ÂŠàIéø¦ÄòxõRTn­aşS„t!b 8¥;-&Yª¶õ”³NO½ê^ÄB¹‰Õzü€Â=ñ>G¼Õq·síû†bQ<_äüİ.,æ„ä—w(1².àbr¦€m–¬ö$i-«,&ÕÁ@·2/G™8†}5HÊdå7Gİ7ù¥`©†z²—.¸±Öª+ëÈa¦Váàm×æ“o¿UüÛWÅ¸¨3`#bĞ `: LátXÁiw\ƒ²Y:ãÓœzlSKB;'8”Š#ùÃ¥<Û™(xC*¦’ÆĞ†wíız1=²8Ù"IÏŒ–íõİµ? érh6¨Ş/äë¯ÜÇ/ısĞ¾¡>*ÿL DOÕoq*å”´È¾óBÎD›ÙÂó ÀĞKEı0 ¦%xœ™,µ#&…pgRhôµÓhÁtSc5SÑ¼úœ:÷ğÆî.`xÎß[uPM('ÃÁú	Â#wïéíêRæ}    ¾o ¶µ€ğ¼›·s±Ägû    YZ