#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="4119861063"
MD5="02878fa3bea2ebe5b5cb8b75e909dcfb"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21492"
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
	echo Uncompressed size: 132 KB
	echo Compression: gzip
	echo Date of packaging: Fri Nov 29 21:00:45 -03 2019
	echo Built with Makeself version 2.4.0 on 
	echo Build command was: "/usr/bin/makeself \\
    \"--quiet\" \\
    \"--gzip\" \\
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
	echo COMPRESS=gzip
	echo filesizes=\"$filesizes\"
	echo CRCsum=\"$CRCsum\"
	echo MD5sum=\"$MD5\"
	echo OLDUSIZE=132
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | UnTAR t
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | tar "$arg1" - "$@"
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
	MS_Printf "About to extract 132 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 132; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (132 KB)" >&2
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
    if MS_dd_Progress "$0" $offset $s | eval "gzip -cd" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
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
‹ -±á]ì<ÛvÛ8’y¿M©OâtS”|K·=ìYE–ulK+ÉIz’J„dÆÉ!HÙn÷_öìÃ|À|B~l« ^@Š²twfv6z°D P(êĞuıÑşiÀçÙÎ~7Ÿí4äïäó¨¹µó¬±µÕØŞÙ~Ôh667·‘G_à±Ğyd™®{}Ü}ıÿG?uİ1—ã…éšsüSö{k{§°ÿ›»Íæ#Òøºÿø§ú>±]}b²s¥ªıÑŸªR=sí%˜m™%3jÑÀtü<1CcyÒr&¶Ğ`C©¶½(`t§6u§”´½…A—R}…ˆ<w4ê[õ-¥z #öH³¡7wôÍFóGh¡lØ~ˆP£sJTYÚUb3â›AH¼	¡wê·N^Ãô¨NFç &Ğà “\¦ïÓ€Ì¼€¨8†ëf» JN«_„“
½ò= ı óüìÈh$­ÁÑĞPkOÕ¤3>9Œ»§ÃQëøØX!YĞ\o÷CMÛÏ†qÿeçM§ÍÕ9uãQoÜyÓeÍm˜eü¼5|a¨(W)
„£³! +Õ#
ÔÛ†^p]ä;ls@{FŞö­Ö} ×ŠkQÉû}Ü9W©”“Ã`~‡Ñ5µÆº›Üó·9;ùô–(3[YÏâZnp	á
©a. ò­™z‹…çjìœò­QPŒÂ7Ìİ	l‹2šFtáÚeO6nˆRIx¥‡_ÏC×§;^!«H°X²«º…	ÛçtzA cö} ÄE–Gt1ÍQ8À£A—¡(P*S3$:§ú<ğ"ŸüÌê‹añoí'¢[t©»‘ãÄT×şL¾1H#ÙMXLeUìšJEPÇç>tÌ9ãÓºô²$ ³ñùM@áç¡íZFmvxzî¡n¨	-j-QË)*'(¦™µq«İà—®§hõ[Rğ°˜„eñ`‡0c6ü«'”7]YÆwŞA2Ÿ¦(s>ujŸğe2œAš™&TVÕ°–ş&Ú•šÎ6ˆÜ¼ÎQ|»XtfFN¸¡ H+ÛaŞ©ÙDÂ§–(eíiªT²Î×ş¼vÖ¾çØ /íPÌÏvÈçô/èê.ÉAwØ?nıbÔâäMëlô¢7è -ûM>Ÿ>ÁURËY¶"{¹0ùe¨G»Kè•’z½®îÔ´R¿N\EäNÑ	!hqı¸b¾ÒXJQG¸H®QR¥’IB"™šˆ•¸)–ÍMa%İVŞ»0m7¥TÁ'NV—¡</,¸O¥’ib,°j,Ğù>‰:5Qæ<Dß*Ì`2;£ å„+²R‘M ,€“Ëá[Q“6–<úúYÿƒmwN†‡Ôª‡Wáÿïno¯Íÿ67Ÿâÿ-L¾Æÿ_àóÂ»D›1š³I{J¥Iz>x> Íy„&+¿¢TF‰ãG>ô{nØ0v1]ÆWò©¥ùÄè ÿú$/…şª˜_Lÿë¨ áøäş=ùsss» ÿÛ ÿUÿÿ-óÿj•Œ^t‡ä°{Ü!ğQ[ï¤5êbÄöi÷N»GgƒÎ™\ç£$éEda^sñ¢Â›GaÁõ÷dÏ¦™$Ä>Yx–=³!'`†ñqJ…õ|Y`5¿÷Í€‰¨NVŠ1á‘_"W©ÊCâŸhšmQÇ^Ø2
˜Lî\æeÔ™3˜GH<#³À[€@×tbd¢c:Û#çaè³=]O†ÕmOÿ2E%«ÈYÍ;íù+G–_ù¦ËxD{n&L`¼Š2³›3F<Ó¡À™:y§†ıÀ{ÓçuMÉ[ı8°ûj•¿¤ıç%‡±ú³¹óµşÿ%÷Š…WmÙEƒ:;ÿ‚ñ?lööŠÿßÜıêÿ¿Öÿ?³şßÔ7·ÖÕÿ‹‚şÀ3€\0õÜĞ„Ô‡pdø¶ƒùw@æÔ¥;H !Ší‚_Ä£‚ÖàdùŒè¤Õ´_ìnk¤åZg[_È±+U‹†tš£à|üX™ùÓ83-“¸é·	ÖM,Ë-?şw`›K›òb¥¹˜ØXğRx€tØocİ¹¢ToŠ{h³p<µ'i%Øf,¢u—†XfXÈOá€õ¼°úT=›Dn‘æuõ) ¦L,]z98ÀØ	/»îïóaÇ¶]‘ˆ¡HóÇ‡¤Ìœ*)9ÍŒŒ­z£ŞÈã9a¡†šDdléÖg…È¢§îslÒ‹zhÎ™P‡âñÖ¸1n¨&À2>î>÷[£†ªG,Ğ{‚9TUk%`ÈC Ñ8iõél^D9èwZÃ¡Ş9ñ«Î`ØíñD–^“Fª×ÅöïÈ¥í-iûÎ%A/v§' É2®~Øƒ¦9((ÚÜVÖ•ø«\@bJ3W^Ô+=Büqu87BeX0à‡ ]J^Ç¾'Ş$°çføñ Q˜pXtÉS†€D_f/&ÿáØSÏ]!xr£¹a¼gfó/â¸Dcw/~uğ§ËARC.á÷:öŠ|ÆTñÚø_Iw%L'/Q]:o:`v.Ïíé9r{qª¢ÉØ6âJ¹ZËR‰ATuõì¤s‘£Úº©6×Ã–èpı¢H¯TyÆ›'pOÆEò]Z!!ä§Ê* á
8Yœn48;}IRC>ÂQXìÏ±–ÉŠ¶Yohpj
6^…«İ¬´}ûN{z›CÅÄ`éöã#ÓíãîéÙ›ñ‹ŞI‡;7!:…å± ¤CÂ<|u:jİrãX2ãm]Ş«:èc}ş«Z²ºTK§Oåòfu¡·%Øğh#–ëR|jUqĞSÂº•¦<É™c¨­® 	=D<¤CxAeı(€æbòâÅÂ@(&<\QcSãœV°§¼ç¦;§Ù¹ıÊBÅn‘HÉº+¬m)Xxô¾â§Ár2ÿ‘Ô–I»6µG‘a‚ìõG†ªYˆHì«¤7LûEDEÚƒŞp( Û>@½zÖ"Z{öê°ÿjK%‰ğõÃîw¦"¸PåËÀ•B™Ä-©ŠT²;	’8öÎíà¨¤áE¬¢×Š‚ÆObòáWÛOX¢öûBVÒ½÷ıéÕ.÷‘eçéÜÖˆÃÅ,`Ú‹Şí¡	¸H'¼`Z&í¿&«Oíæ´78ißªDX-®Ø*•,±DğÕôØ´Vªı*†è4µ_¯–³µP•d}ûWä3û
ÈË:¸œY­J´‚"\‰JvYZÁô|w»TbÈJ¶[ÚíèÉç/‘ü¼v¼8\‘ö2êî¨µ÷3 OE“’d<zÌÑL°”L¬pSîeÆm>•KÕOÛ>$ù­ÃEäHNö\Ğ¼Ü~Íñm„ßm¹cH6dí¶aæ0-{^8ÓçÊ–\ dx¡ÁGB*q{[j“®º·Æ‡=4š­ÓƒA¯{0å¨pçAÆ)Œx²æfKT_¢5<qv	5‰KàíŸCNÎƒÀóŠ!)}9oKb
«òå‘„X‰]ı,W*CŠbÒ7§æœ
{Ğ9là¥¶ı2IØm×¢WüÒK’ÚßÖxßûÛO^k. L8üµÊş/_ÿå×Œ˜¸	Â4jÙàÊ~·2ğİõßíİÕúÿÎÎ³¯÷¿ÿ×XúÕLgaşõ_’^ ×âóÆ‰`=x@™ï¹Ì8”×v9B<èÍ]lÔÅcâuâ²^W«×¿·KŠ¿ÚxæÑ4”j\É2ù]Kº¤çóƒöo2èõFcìÏœà7ˆ×—0<x)‹ÀL4?À}ç÷3ñÒ£ˆZêI<”yi-`Èà­ÉuPz@}á.Ûxr6Ï(AB8%wÏ+ÉCTò3ß?AwH]Ä¦uğ<ôÎ,ºäÜ$Äl7œ‘ÇÃ³çÃ_†£Î‰a¨›¨ß“Öh4¸±­WÔµ¼àšÿôªszĞü}'½ƒ¡6vwwááhĞ;ëªïDsÀ«¾sò7Ù(Åøï8ŠŸ¥ï4µ˜Ò:oB–xIÀË˜!P<-ÆcU®!K›fğ×È^z¨Á©˜ü»\÷|`L²”Ü•Teñ“+#rÆ›¯¾Í"`å¨o†çÆú‚¥æå¢*—“ŠĞ%±H"ö°ò-ªÆéjàa[?M3 Mjµ{k'±F¨r$R‹¦4EIã<E<½±’û-âzd¼›ÔœØZÜ}èÔR¥Õ]ëB÷3sµ`z­Õ@'“Åë¸M`LØ“ 9†ß–Sgoˆ
¸CÏs †|G/'j»ş£îP¨‹nQeˆËb•Êcí0ÊoüY
#¯G`‚o±œÓğñ'ĞŸ~Æ˜ t‹]¥ëª…ßŠ’ÕÁ¢Hb[Hª YxCŒHr¢#,B¥Â¸nÛ.µ]¼È\ÀÉ™$Doïy¢•ˆrÅİ¨3éHMîÁ¬¯™Q©	.Vh.(.lû¡Æ‚ÂÓf¦Ç–8xhA’áZHœãÆÕ”„>•¨u*!i±>®V·,¬:ÇB¯xèü¸	ğEK|lX´Ü”SE^l2 µ˜"*Ñg<Nj ¼¶‹÷jGƒÖÁqG ‘{üêº`óBˆIşÑçé^àN$ïH¤Ä¨!ˆ‡¼(€•ÕİVk2Té9]Jü.Kaé|·¥½ÎõŠWWH1ÏOŞV‰½1ÒiÔä'ğb?²vòh$n2k9’{p”íL-5(?cq¿ïDÃ|	’œ‘Ëh*…-LÈ«ğ¢<3A×[M|Èc=¤Ë§x=)#‚F1î_ã3w˜p€ïağcF¯¸¥Ú‹ÀÒ|0“şˆEf`{D\ÓÒ›zÉ_j$O&€aefC•ÌŞ¥Kƒ–ã¤‘8õ\ç:¾¾­!†Dúª…
@¬¬äac.İØñ‰êÔX”§]hD„5•xì˜¿Æ.cáY–\Ú¿šAìíÄj»1ƒáñ/­ÁÙ_òx~ÜÆ8)¤¬¥"*Æ™³fÒ4¥º_Ö›êyYg¼–5½œHQVïåQa0„ç¼¾ş-®ĞMÈK0â„D$‰êñî¾—P§<yb}ûOµ›ªÄœ·OßßîÛß}·äF?qhzÉ`öû[9Àâ’îe?‰6XWÜAì)–µ.;Ä¹s.‘é»
oGLÇŞ¼+%—ş&vÖ†¹}r©jQîàM‰-‚˜”«Pšrê‘¸ä#ô2=]HòÊZùé‰ÚugŞî©*ÊµíK·i?¹ô‚æ›S3÷uoğráp'ƒ‹ë±­l®˜u!fLúOóı`ÎŞ¹Gàåš³\gïø`,emF­Ğ &>e+–xgŒ1íÏ?s=G½Şñ0ƒZiâ€§Ò©ôÀ;åË 5iSc
!mŒl4rˆb1ÏúıŞ`dÜ!JªØI.›šÄ½ÚüÚ€Œ_£iÈT,ÌçŞ½±Rãëb	SÓ»
§½Q÷ğ—ñÂMqƒà›Â‚"±wîò%:3á"{¤L¼Ş¹ëe+ë{ \Áœ½£½ûy‘Úğ8#ş-ËÉÙKqÕ<úg,îË_¾›ÍcˆI¶,Ì&ÔFÍØzü¼h+–\îp%ºéûNúŞCV§ü@_Pë=Â¾ÁF¢”s|ï»e@ÆÂB–/å<tbá”HñÂ^PİõVZwyğh1oÎn[”]„Ï#ìÌ€¿=Í¤ƒ/¼¹‹zj.¨‘m‰ššz{Zì"|DµsE§¹£7ĞB‘»iHğÂ®5‘Qi<1)÷ñ|òUåğ.cÛI	êNÑeåá`"X½nCãQT±±`@W‡F>nDƒ…íš13AÃDÓµOV¶o1Ú )s;RpfÛ_…†syÄÑèåşÑYxmÏ‹ûÂîãš"ÿõIÛ1+²û¶““Ò«P¿ÒÄÂ}ş/ë} ÖÄ?Q(ï³]¬t²r Øœo	h)"!R¥XŞ¸È÷L=‹Â¤y-Vù’^ƒ­±˜!jËû}±äĞa@iük_pg?Ï¤·-ûi^ïí½Ñ^t´SXÊ’v®BÊß»yŸíßCùxÃ+Ó‰¨Q¦ñÇ7š¸[«á[¾@­vàákÒF¢ø¶Ò„­w[ã“ÎéÙ¸;êœ$	©Na{!;ùîŠ”ƒn¿´¦AŸÃ…x|Ğ¾õúü<¤€€txSÛÕû€ÎÒ÷¢Î©ã×ç®· ün©i\ëìš…t¡ñmÙEí™8ÂBh!°
v)‚ y¡EÄ×ÏÃ…SGC“Ò–©“°Ùéæ"†úÕÂù$KgK|vøebù‘ H‡ÆlÎF‚ıMfïÁ¸·áõKHEÅY@êº§](e§ñ„ß7•`”…eM¢Ï°è@‰’)mßc¡8±—¢tÏ±Æywk¨÷»duÅceêÏò§E0¹¶¨VÉ‘½Ì² , *÷jy˜USV‚,aØsi&‘+3d×b?,:vjµ›^¿sú3D¿qñüVá~°.4saALJ>m½õÃ®º‘›Ÿ;(UMÚBsa@¢˜#íí@X…ĞÇ)Pâ!˜éó‚ÿ’‚¥#ÉxÓJ¤U‘JÖ~“üüV‡_Os’¦‹Xûğõ'œ X
ù)ÙØ Url~ü»'J` ùÿS	H6w.­İä©/d°ÙªK `Zr±/'®xK¿BäãQ&¼àû§hRrJ/ûÂY	ceÒ‘÷:Õ˜µŸ üÆÿá€3ãŞ"JRòÇB“ĞŠ}—–îŸ1ïK9$uÆ±ñ)öçBãU˜a†`Âçà‹j‰H]"Ä6VòÒ¾8?°zÃ_††|† Bpm-0oK;¼Æ°Dä‡‘ãÄlæ!\š»ÂihlÆ‰tRq@ğ,uÜB9ÉîÇ(F#Á¯ìœ€ïŸ:‰æI¾jìH«"«÷şwŠ»êDÁ¢+.Nrõ#ª®”1Å¿Šg(„Ÿ©ğ>–îàñˆºæÊq­ĞÀ™R‹'¿1t&ïğ]åµYwZÇÆ:è!XËœJªåÑÏÚ8œ¨%¬Q%ŸCîF»$œœÖH¬w<jr|•0É¼‰Bî_ÊZdÙY¥²š”bTÁÕ‚~]]‹ÿµ„95ŒÏVş©Êg³ †	·şK¯³hò¿í}[wG’æ¼¢~Eº€1I­  uiQP$B2Û¼€´»[ôÁ)Eª, …©*¢eíÙ§9û°/Ógfí?¶‘—Ê¬Ê@š’=3À9ª¼gddddÄòï¡á«¾“"Á¶*ë‰ŒXµaO¿Áø§,SCÔlƒŒóëÿ%@OèWóÎÓ¯­Õ¥Ò¯¨›;Øn dÂÀ;¼lI¿şovåıxtO†’‚c­U¼³µ‚•½a0€›©B¼ä¯±Ö*u‰&=¸¦tŠƒÌ®ƒäƒQvS£n”Š«ô¶úz‹®{ôWÔ	u¿#$©öÆXÀUuO–Ê$Rh¬V/Gá9ğ´˜©ÁŞ^Ñ˜Óî>+SE ¾W¾9ê<£Zø·­L{»bøWádÀ\¸õÜà`¦úĞ-ì“-g:*íyYmİ¨Vgt¾1FeAZ£ëæ*§"©Xet·Ôß9%ÕµúÙ[¬úì‡úp-—hQNlˆ5§²œ…·›GÂhõ7ƒ€MÊfTå¦B7¢ttŒ¹$”3ª&êhLD¡­<¿ÇƒÙhW-"ŒdÆ­ÚV­!ö	ØÀµ{­5é=ÈKÅH.GêÉ4)RzT£‹|"CnLÓš‡L-Fr÷gÓA?Oå ¹®ÿ¼v‹ÁxÈ¿Œbü;F±ğà$‰¿¯âAXK†üû0¸¸HÍ¦â;/›Ád€_sã­ş°Éõ.tÃOÿÕ¼IÌïûùÿ?F¾øZœœ@“ÌÏZÿÈ¡u¼ø†.mÚ×4*–Vœh_U’aÈ«¾ç%DÑ2àr:‚sY›&üšrˆ‘wŞ¿Ä}÷e·ßaåß)–EÇşIÂûøcND
Âayï´¯¢Òñ{ïñv@#_Q¿Æ¿Â_o8¤¯  ò§PVhV|û‘„ú&_ÎõE?ù¸AOs]o5ñÛtèOéïl8‹oD%ü+Â°à78¬óîO“p*şÈbo¼v1Q ¥D1®î«ô›HšLµƒ!Å­H‡éIû*²¤íŸÃ"¹1Ï ñÜÒKEÜ–›Y0Ü$&Í£uèóRùŠœféÁ£=•#WƒøRrœÔ>ƒ0’ıÛ¬% ÷/¶!ÈæÕM$(ë¢œkõ†gòlpfš# ‹.*•Ïê"*awêwªï’dÕíZãŒfjüÂİñŸ­õ¢üÒm*Xzæª[Ì+äSÖ¤W O…£¡”&ğR'=f°t‡Nutûò‘`ğ¨oÏêx \,¶}Bİ¼DÊÑĞL	»½'ïú3’ ,Ï©@O›}n·AÌÖ®¥Š“´Q\enhTªlclw=9•b#‘Œq‹]O/µa±J³’WÃ×Ó¦Ô„"Z+wxN}nÏo&Ú7™ì^Ë*iêöIÑL!3by‰/Oç…0nå£%5n8† È“Ù²éÅ‚‹ÆıpšÄ-¤G7=õÁ5¯ ŠÈ¦K—â w:Ñ9Åµ2ü…P‘°ş{_Uh&’‚Í¯&Ğ 10š1b‡¿=ñ|k÷ğ~Ôçl¢5ïX!`—S—¥öÜùâ3>øZ%%C¿{šB¡}t?Œ‚Kqò1t£´›œÏ&Cnm†€åªadSğx>ëY:½`H¸ò‹i)›ó{+B›|Ûà3ÖÉûD»¹ù–úò"Ó¹/ó×)G¿q¿Zr#½ãƒiüxÛ™ÅÜn±ŒÂŠæTfÌ%sØ¾gˆMÃFæ6Â'&O¤É½È%¦vP±óŠ)ñM‚¡ÑÑ¯3Éùz““½Ã7½â”“s±¾‹_Ğ^<â9.=nœwæqt+R‚ÊéCş$±ewJùTë´ÏV²/ØÏ¥{7®ŸÕ+y¨˜zıÏ¿åQœÏºc/‘÷w ½·r;²{Yœò>G¦Ë‘áq$æûİ»QÖÛ~ÏÄy_Ouwm‘oĞİrr¡;æ¾BÎgòRnG™	ÔlRõ™²Á~ãLA[æÏÕ¼N[Û³¸ÓÿùÀ1<ÄÒ¯ºIÊ­]Åîæ)fq»w±åÄhmh`fR ×¥yqÓ.¨šËör÷“&ÚáÑJY¤¸].J)wªc4\¶’—îŞùŠ•ßÚƒ¥›mÿ˜ß)?éfQãÜ5;f:‘¸0Å§?û«[[E,$GÃÏÛÁ5y~À
ğ3D4 § ‡#îe%’ó®­§Â«b—°¡iNåÅUl¡QÆjc¬•c r|³	Wëg÷9ïZ¯“—]= Zçğ»Ö¼RÙôÙ“y‘JT7*±¡õÙuBªÈı]|Şmwÿ–,·®g•ô-VS¦¨V£¡ºÜ\Óê%üõÊƒµÌŠbä
 (*fÍàíŠ 9AnTà2Yà g1óùÒñ[»ĞÇµ´Æ:0Ù·ôC‰†!ÏQ’ğ¸UB:f¢¸C¢,ènÈß%ÛØ`
•€léä¯Y•ÄùÎ¢ÒÄHÛK£oˆ*:2ñéKEÁ´¾üËŸÖ¬6C«PlcÆ*ÓM‹3"³@# Âk®ËÙÊJk}reˆíkÏÿŒÇÒGÍmÔ6]8Â!0™–{zòºúÔıóêås¾ùÒóÎä*ˆÂ	šàøILo`ÿ}¾ÏkKñê¸Åø™[ı:ÁÜÔ…qšTÿê_!áW”%Tˆ4|oì«²ŠxVšùyİÒFzõ¼.ú¢[ºeÇH°F«‰—Ÿò‚¹êy	ãâål‹M¢É·µ,åsëf=TlâéŠrÕÊºô,ìáu]û„¶?#Û'(İü¦³9?“;xVY‡yùÎ6ÜÒ£rJåÆü3WÖùš…ù
0.iu¸L°U\@Á¦AMHØ¾m,ø±.V~Ä}‡Q8Eƒë|Ê°‘k…D†í¤ÛÅ3NëkgSŞÇõâ5ôQ#çañ,™x›£‘„4ÍÀ ôÈı%ÏÌbTìÒÉ-nGıÍCNDú¹F¾ùù­Ï2ò(ÊÖ¬!g¿dü¿ÆVs»‘ÿÑØ\ÅÿXá¿-Â»Jñß6kÿÍ‚şf„ùšp$‹íöÛãaÀ&Ìÿ ‚sÁ¡!ò`µQ¨+8ó|ÂK…÷àËõ²´‚D5_ãÍ)¿Ù?zÙŞgßµ»{èÔŞãÕ¾
Ga„.Ÿ2Jõwîn§UY;óß6v¶šã52ü İíìñW›ğn+}×;}	ñ7í]|½­vŞt÷ND–Fš\Éªj,ïúF™”lÛHØşûé¾*`;}Î‘fE3áqûø¤¿ôêÛŠNnıÊã–ÃéûKÜğz-}êMQ¿'±ùjàŞùô @šq>«*°z¡ãÏdè:Nü¤K†ömØ÷Fœ™b‡ş2•ºµ6ô#ÁXNNåÁèÎcræ”Ñ2Š ÛäÀ8Àë{r»£°Âşà!^;Ùƒ	=B¼Aæd§SqŠjbš²6ğÖÀñ23[EvàÚØVg.†~¬ùƒå²¯Ÿ7s@àÜõ—¦r4.¦Z…²ˆ;È`]WØmRe¢›<hòqàî¬´š¨,–7zJfÑöuá¨~Î&CF¬ÁğıtríÀá¡Èİ[k‡G‡5Ë˜™CæVšù7t=à|ğh7˜B¢Ğ¬4'd¬®	C—Y-Ö·çtIô•ôµOœ~^á¾^ö¢Ë˜ñ¡„q•¿i$)¡ÏT¿G3†2Ñ–9–ÀÂ€›¶Ö+ë=”P~®àUTÃ uñŠ[H¢ÛPJßà	Ê­õ~ıuf5`**‹Ój-ElWÑ‚äS¦Ö%hUiå#|­×ÏêuöiC‡º)ğ´O‚°)ñÈ5¥2—Å…öXH›o½êOíêß7«ÚùaÃDÒ‚ñ‡\˜æáÒÿÀ¼ÑÖàlŒø |6³­J; [WÜ>B”í¤H'\Û˜;áĞ4ïL²Ø"+›ŞñşŞÉIg·ßîvÛÃRÅÌP6š¨tr²ÌA¿í†’åÅ¶ gª¤w’ÖÑªä0}*l7‡çzÓ…É„M“på€>xQäİ ‘JJä½@ZØ Ğ4*%ïü‚NicSI¿ón¤%é’3§¥N¯2Ê™…E-EbA^†a¼!ücTªSÆ¤ô•AÅĞ¤S/F¦~ƒî>EÎ„RiQ2´å kSŠ¹µ•Îp{ÂºZ•Æú­V0¬¨ô)ß˜pİ·*[ê©èŒ©X´`.™Ôr°bê¥¨”XÆøØ1R†œóp¢Ù`†ô$’×«‡°Ñ0^ÑG&]Ãái²;úM… &Fˆ˜ô“,ˆqï¹'9Úw ^ß‡„íİ¼ÄošÀÇgNÎWbRT¤ÁÂãÜ4u˜)QdsbøyœÕ™šYşF·.ôÊËXÃ?ÊùçsW°,€ôµ/P5)Z`Ænš—)—Ë´œ‡¡Õ5`”ÎŸMîÔ}[¶ÅPæ—Hdq!¤£BÒJu9†ª½7L£’Œd6]PÂ¬·#Ëô:ö·ÍŒ²gbj,Œ¡_8sRº­IV›Ee"›DjÜ*ë×Ñ÷5Zï6·¤·ß<V˜Ò[t1-ã}KïÿPŞ¶Ô¢Û9×jcŸÂ`uÃ0‘„Óîb ¶Ğ$-¡±9Î=7‘ÆSvÖ¥R7ñt6K<¨oêBÖ©a™‰È*âduŸÜ¯H¡U¢Ù„|1²9úŒ‚+˜òK?>›tà¸ë»V«!	½øº	Ã…ÿÓ™‰¸ĞPè;B
fB;wœ}¬ÓŒÎ‚üÒO´ÕÑÈÂ#’ÃT°ŸûÃ˜D»<ê…_e\CRiÎ>`Õ*LœûûÖ&b%à[VQi B§(T•-iaÑÎ)FÚAÓ¸‰Ÿ@ÙÁŸ <İ|ÅN¢†(ÑW®åÜJìü;îfcF‘æ”5NĞ &Fv8{ˆØ:…qFáÀã0~Èˆõ"ˆ[ì]úc" ¬_ÿ®Ñó ­h0:äA`ağK½œÅ7>µ™›ˆ4éœéØ1LÎñ$HW×N‰»ãƒ·›?È÷ã˜Â×ït.	sJL—üXóù×Vö'ÿ:C%]hªóe0›Ò¨Ô°gÊ"{1û´}ï	ÅO¨4¸‡B©„­jì˜P¡ˆ¢{2L­>?So ;#HİQ8f,Bàş‰ªc*ˆs½zÄ	¯ÃëêlâÍ°E	º"øÃlâ>,ÈP½>TÇÆrºT6\ó”V;>RäÇj¢âìÂÑ&Û^ù¨4Z8N	Vq1p‹ô·tò¨<ÀåY{ı3g®›úŠ^˜[û‰=ç–¬âşı,<Õ$r IÂ¬„üÑ§Uğ /ÿGĞÄıÇ~_"şÏ£'ÍlüŸ­GíÕıÏ*şûã¿?²Åÿqu*_2ĞÏ+ëİå.
R†Z°ÍüäEv/O#”aŸ@7gŸÀù’•èÈ­ãÖ1n‘Aó†~Í„ZvLãÔo5ÍG÷ÒÑÀ’ƒ[¥¸cœ<ru™w?Gœv42aÖÄ¤A5¶²ªÑ…„ŠÉœŞ$44úrxh‹B~³Nã‘ë\å£¥8*—ílZyM õAOÂ{ «$Jù!Ãî.»#×‘ÛÃ‡ˆ&fYjÜÒªrş¶z}Ô~‹Gn®”,HX®Š˜Ê¢YLË¿GüÒÔáÿ2×`^Â–È!R¨ÒµT7•—´ÚbâšWBjÄÂç¡Ğùêj8ÒÜ³»HF@6Z²,M
d“IdÒ›½êöáÉÂz1ÍüJEŠ¼ÎDA{‰—Ìb.a“÷pÊØn;ßº©²Dê‡ÿON{t3§ôÉ¤„ai†,4~#}uxÔsºÇW¼x#Õ×;ò¤iÃÒ¬@yà«*ä)s$K<<zÑØûÉŸàÑ‡Ô|¿şÛ¯ÿViG¨A=â(u«ã‡!›†'UñP$­Ö:«¬ã­6«Â1 ±Á6tn/.SxÌ­‘g $qâÔ/ÄH3”9U #ZA«æT¥“/údéSU[@H®Fj³–©¨"b¢¤¸öMş–Ú¸’-@&ÃŠ¥ˆk™W|ª›ÚŒ¼¢¥Ä8Ç¯Şùƒ÷RËA}°5Ñ<ÓÅ}S?Wóq‰7ÿnïŸtº‡í“½ï:*.šâ6œğŸÉa^c9x=‹±›fD¸Ö*¬Ò }­{›ˆö…C3´ÙKÖ¥
KĞšâ¥­äå‹(&¹1Âƒqü.¼&Â’£¡¿­ÚfmÓ¶`4;İşé1r·îL­F<øÀvıóÀƒ¾oÖ¦şä/»ß2ÑYÆ{/>Õ‡`N«™„Û}Z…ÿÓé¤ıöYúvÍ>ŸYu—Ô#~ïE°_>ÓB7Ëæ>•ÖM1o¡?|Èf1mö<E£ñ•ŠÚL	g3¡‚[ù`ÿ¤'Çˆ{ rASÆ¤“ÜÕĞ†c©Ç5´¶Io?r
y¹×>ì¿@0½š”º…ŠÀŒ™µµ‚ÚåÈê9ğSìè2×V›¼¬±¥r§Z¾†Ç·ÈÇÓ3‹iÒĞ?¯‰ ×¼Ï¿ö‡ø¯F¡†wiYı2@ôlpæ‹h½æÜ;ò"úNÔsî¯qÒå ›‰7ô‹½€)bÕ¯ÿæ…rn2¤+[#B·Ğ¸¹¯!^ïÎŒ¾?Jâ,­ØEœQµ:E—¾Zª>€M…-NØh< İG,èØOşÒí<e¤g¿ğf£ÄÁG0O½x—?ùB#!ÕyÉ»>Î^{sö¿¯³ˆÈßPZH2cJ1¹ùa%EÅ†½R•F¨Ü"[ ¨]°Á¥)*\ªf5×ÚÓ9Œ•ºÂ(FIk×©ˆ1µ,9µö£V%Àäg“^N§Èf„Ñ¿§öNiW ­°‚áLç/íïÚÜ§Ë­¤ÉTí¢ 2CÔ¸í\sJmjbE•¢ÙTíhR³fR£tÊRbúÓØ?v}¼;D5Cœ‰9ÅcY%ãik­ÿã²Æsmf½™ÎÕûíï¶…L™=Tçdƒ9*Ö±C•˜"y.dé*ÓÌšà	Ô”È3I 7R¤pDÂÆÌÏãö‡¶$™sò´ÿ5º·#.Ié¶‰ïi*yşGİŒÒ¼Ê³dç†yD]P-Û`¸Døáƒ|ÿøB2Éê•`G«ÙÚcåí~/CÍÁ>ğkFĞRœ4+¼dØhvwvĞ9[]H ¤YnAI6»
–e“wkuTö÷^öäùˆP{ßpÿãT²Ä$@Æ[X,Õ` ;á0DÔÿ±ŸDaL^uÇü'Hƒ™´-ãúÚ0{«bğ>Aëšwù‚!ö:}æšÒÛRƒTæÆêMŠ•ŒUÙ,§İı–,n>«ğ¾’‹fŠ=›˜¥q*oKdU3³ˆû{¯:‡½NF¯Û>è€àG°juüIL\sö)
¡¬Ã(´ğ—üÑÏ#H«W9lh:Ìa­íÃö›N·ÿê`W«ø-¬ø‚6á2ı¡å4ÆıÍÅõå¾J¶Àd;s‹n
šZçˆU¿×¸Mku~·‘ÀRqyM»µÔ—MĞ!>åôŞJQ´Í×±å=-ßø‰® DŒrCâ‹.Ç3AI3APòà‚"l	]~€ü$*ĞÌ>q«‚óC™°_‘­t;ûv¯S¯<=C0É‰µ×hkj¯ Øü  œ{2K0F;ÅYJGÔêèhĞ‚tfwÓDD £ª•YgJ7;~®Y¢;oç–z/wÍ&”Å%T	Ô_šTÎpà¿ç¯3Ô~K@	iæÀOëãpˆà.Pj€×C YÊ0ƒmî OMÏOº2…6^É%Š—×Ú2.Um	‚ ÀÂF˜Ì^$²ÃoôŒG¾ğ‚FŒé×Â²ªDA4‘P¦I<s*_H=ù"ïË<èMç„ßô½FCôĞÃ“×2&–v^¸0 ¼h­»ƒH®Â!ú‚ódÉr—‹òT%Èª×“Q¢Y‡Ã²p´›…EÁd¶ßs–ÏêæÆø"bKFk^:5µO3"ÛWÓíì8.×@}Š¦³Ñg„ËXX~å£z¯™Õd)oy²çûñRd1ÿŒQæO<aÕîUÁé`‹ÆÂºŒe’ÛÖ¡*^¥wkÔmZ%N¬÷±]À²oO’“(¸4¯Ï3×?Ùãım•DÚrÔJ%Ü4ÄbK2¸Áã«â„¶5Ûò‘7Ys+­-]k­°Z£VÅF3^|¤¶˜$´ÙÂPÏc}³‰ı1—^h$%L¼/ã
´”L¿T˜Ã!\¦£‚¸*P~9{Ğ~³‡2Iû¸¿w¸Ûùkk“•š\øIYˆwwp¼ÒŒŒëc7ùõQ¢Õ>¤›	¨iäçMÑ¶$
G¯Ãó$W~`NÚ]!¢çªn³È~®.Ds15ºXºşÉŒ·¦ g¼Ò„MvÍ.+hlH1=BÛ¼Ak²rlP¹)øR£Bhx	İ‚ƒÑ;ıƒi.'Ş¨ÉÖáœ£ı(šM“5†¢Iß;rC®1xLŸM~
¦Fb5ú fŞgÆÑ–›åáî·ËQtFSl¡V3îº`l™Ën&A6–µm æjqÖÍ»©Bu¥dÔ:?Hqzs{<Pú^¿ÇÍMØc+…4™šsl-¬™’-ó“t¶1L–-^½S,PL³»KğR2£jåd»¯•/÷ju•õöŞì ÷âJZäÃw ÆÛš"Ş|A’û ’Í	rWÁ0e|EzÆIm$Ú*³‚—ÙÌÊtZTóz³ºÍc!Ã×H¤ÿ‘@ĞsRô©ëu7j>ª5k\["¥Ãp¾ÃQí2/G~$(‰@ZJcÒ»á»J_”ÇÑ	k0ŸÖ’aø[nq¢¿ÜĞhƒ S'#œ>Š9wnş¶Y¶%}”Ò¦ÑÁ_²ÏR‘Dc5Hƒsç÷çó ¥WJ—†ƒwJ7pôı™Õ`{ÌíA¼›£+¾§¾}IEê†{æLC¿9
À,¦7¯üxä£¤íÉCuÃ«®3Wt« ¸ x„M]‘cáP—IèÂ²1”ˆhÆÂ£w3,‹éÖi9qü.5§·„–™ºÓ\i³•š¸1Í÷íví›ßã?b_3®.°FÃ”½kjh{_4¾ß)B·ˆ+ ¯q˜³öå¾7·0Åˆóï)ğ.YW/^îí„ÙÂ‚ıÀ8ã:gñâOj»écœ:œc—àğ­¹än0n¦ûÁ¢*Œ´lQb/zï'}~A‹zÙŞô}Ÿ_ĞiÁh	1ñ`ïP°,$´íÅÕƒ†$·½+fcÚ#2+c=÷/B2§v ¹4¯-<)R£~¤\–Å6­î±¼-o8€.ºG~œW±Ue«\*s¬|üVÅ™iå£uÙ!GçUË\œhædHEÕæDL`ÀEåø¤ÃÃıÌèÆ­:ú‘¡ı[Ø¹ù)øM’¼èÇ¢ş0Mœ×Æ»1Rƒ•Jfªş^%yqÏEn×ŸzA6#3å,©õ8sUüÔÕilR[ë.Ç-F~ÁñK¥=©²ÓKM÷„k´‹€ã½µÚğİû¥õ–?Äó²&£òX&M˜'æY GäK/Ê’1ÀÈõ0'ñˆ­³ïù· Úªú”YV¼(²Dñ³l!³~:+fÓA­²{á·;01×íêóYú•U»…İ\˜¯ TšŒ)ËgÚÃás2óOŒ*`"âuĞe–qp\Z=a1ô»¨ìä•¾Xcºù7ÿó‡ıˆ^‘ğ¬†H¯S/Bc›u¿²åµXé›‡Uÿúé|Ï|ôF=£G*ÂàÙy*K¹Y#jğs!K;ÍêJl!@0x‡¿7XY( ä,_T|å¤Š
aÄ0YÆ¦Ã³°LU¹,‡2–:bxyc5´GiÀfy°¾+ğ9êhÆîQ’`ÖÔ¨´œ©‘¥ÅÖÃÉzµ®#Lø]gih
3ş9)*‚yï2Âœ7
~ò‰ÉzË¹@îBÅ˜0(VÚº”1»—¯YìÄŒCŠ‰Á< ÷ÈÁ¡¿/¶„PÄQÂÁ€c‘P¸‚ÄH˜cBÊ@ó·‚j¥ºO³]`<0•eeTş¬E¤7ßè¿R¡JğMmXà#"ƒ	X6úÈà×ä{´È†Díc/5…# ÷ü¡1ŠAXŞOÀğOÆn$ ½&ç{l	íÈ']@«¿ÙßÌ¸p¥]]27+CsÒÆpIX"İ®-Û™¶Ü²1Ûò|ªj×ªŸ‹çæ´jçe+Ûè÷a®*3¾³±3Ã…N½N±ó‰ö¯œ‰‡ÍÏN±q4ÜP,Nî©$‰Ìø~’ì.Îj}ñ‰›ÀŠIBˆtK²¦WKNÃ··&Ôm£„0iO§c%±»ÃäšÎ Œ.A3Ô–&»“à¿âĞ¤¥ÒK¯éE[tœ"îVUaï²·KvEa¤l{÷eı+‡.H|œÅığR²¦Ö¾G×?]Zù–—‘Ù£>Ê®(Ú[$Hš±ìJf0%.u5n-vii#”îÆ„“šáá…NÜ}y@~ç¿¼$ˆÒ‡!>ŞŞ(ıdÁŒP†íL[1¿<÷—%³ÂVÁnÁ”—ÄîWº2Ì©ä*q­—¢ú¦dïYÁ†Ä­’nÃÛ·¶û`Ö›ó<ş]^ÈÀE¡”ŞRRg®dÅWØÔ¬:sê³;B40­'SÓ"ËV37:Ù=ì8Ÿc÷0ãğ‰h÷[š¹–Åî_Óo é¥ ¾ü±n²Š8úÁ uÇ›=z^wrî_ÖÜAx§f}ú7İÅ&š§G.»®Ÿ†?Y¾©Ú.P'SÛÓ%:Ãô¦ò2÷÷^íôÛ¯N ŒşÁÑnàex´3ØùáZl©9°Ê¿ÁÉ
Ùˆ<^±XJÚáMŞÔ.¨qsŞ²rxî'æH|Ş0Bş":©Ã´¬d†R%GL‰èÈİk-¬”/·±L
7í6l»!ÙÔ£—Œœì>˜Ûé¸QıåF$â‘a6BÏQwW.ğvlÂB9£´iY†Êğ¢ÀCcw
v€Fï(oñ"ôÍÉ¾eYqÖìŠ*â¼s{ˆíÄĞqUéœ,³9»–uƒÌmóÌëÒErÆÉ+–0·‹ØöOwÄ«LêÓFşg‰ÿóäÑ£ü7ü¾ÿ³ùäñ
ÿm…ÿv[ü·¢x?+Š'÷D¡¸‰] Åë¬9 Ø\<“fj×××µ«àÊ¹=d¯Gõ!œ%ê=ûSåµU	¾R”NªĞŞ°ª¢yÑB…ãÈgòJ+mÏúS*‚Álı+†˜ŸÀû»ãı¿Q$x‰**|Øÿş¨»Û{K__áw’”1gaŠ*‡ö€ÀUŸ)ú®kö7U8”¢y¯ø[õ¼i€~ ÂÄ
ÍY—üı£+ÊHÛ«Œè²ÌGhë'Öj±êöƒfGªuã´À\‚¬Sı/d±ep\¨VEvM¤Ànd\1p>«¾fECÊôçËç¨Ş*G­~ûZxYÏşO¼óaMFñÆÿl6l?Îáno­øÿŠÿßÿsË†ÿyòÎÇ ¬)¥/‰jİIŒã
¥\Îâ/ò-Õ	­qå$®áÁ =¤J¤Íåµ‡®§ŠşFÓ{^ç#ì"ˆâä+fbE	«`‡G'{¯ÑKıpƒü*æ$L‚‹›*"¥o8JıĞâa²ŠÚ«¥¤0$÷¯PŸLgÉÿ™ª1ÜGIÊB­ÙGp—r·½÷w¶{ÄÚ/÷:‡'>Y<Åñ
,Yıœ§û’YÜgšYİî¯»oú»í“6úôZZøŞgZ ^ş g¢½t«bÀ¥%’yù}gÿ†Ïƒiæ1ı>™”mÕ(˜4QvÏ’³ä8¼ö#òPİõ&?bG#XéAä¡SòO¥t6Ş®êèSİgÉ»ö'J†N	*Š5×6·ÙşI/÷âiö¿> r‡—Ö§T:4A¹ {İ="9Üm¹—DX•¯…û?ŞhHzjD§â²N{j½jmêYT0ûeÊ?øUw¸ÎÌç9\¿µ‹é`MOaCß£T aı´¦Æ"\­Aî["1ÈÙûöäèÖå‡á%
eQ1ÄãŠÅxt|¢µÎ€6qÉ<}â'µÁÌ«Í.Æ	ˆÎiRôd«Ñ|êX Sôâ N¸E³.¥’İÕx 7ñãî$Õí­­­'zÌİJ¤Æ'õ™B÷—Ísõ&ãQÕŠOÏõ\·k‹´ëœVî'Ñ¸O÷oçÚF¾1wÍ¬|¢æB¹Õèq­Qk¸NÆMgî˜öôÁl>u©æÙ[@3™—yÃt,¤¶‰LP$µ[e·ÖšO0ÙïÉ8—§uGİÙ˜W±@ecº3ÏfŸ9ûSİütga>ææ™ğ[êØF?¹Íª¬}'cnoÖQdÎ>·›Mêç|„ù«.êõ¡Ê—NÕêg Évdûi1ÿeÖo  AÖOÀìÑœ¡Ô‘RŞp$ïfçÄ~O1ôŒ7Y”‰b¿ENˆW@yÁ©¦Ã·g.#Z&¢‚™®¿·Û‘©æ@Â£Ç4^R‚ŒŞWc¡ŠÅš—…ÛMö'£D­•»şÉiÇQø£?HĞm¤¬ŠEÑÂñÔøz`Ó” ƒF‹ó}9èö÷N:Fz»œU÷¦xWEÆ	±VTDÚ÷IüKL­baÛµqó¹¸|l­ñ×kæPmŒü%iñİZóãEŸnUYK{b<T5ñwkækÒ—ƒ\ó¦aHëˆ?Š.ıxR„ƒ×ùKXDI©³U|ªBÊœ«k~rİ×¶ÛfÍÄ¢Ô£Äd'¤L×évÚûTªàız=µÈ÷Fª0áM”ä)¢,5RQp>ãD±`Æ¨§´Óe¼ÈA]6'
xbZ]$b8'İ<a?{œ}İreX7½7sÖëgµzÿ+sş…÷\ˆJ.p&“Ã=­ÕÖè"¬ÿ…çğó~ŸcdSLàˆ—`Ô+ƒ¥z˜Ô±cûh£z5©]D¾?õ ÏˆÕESë‰w×³Í…ÏF°L9H¼µÁÅ¥!=ß"y&°iJ£äí	h¿“cÜF–Æƒ¦ş ÑŠ)6,%©™Äq2©$üB%4jOk”³ä8¦mHÂÔÊîQ¯×owÔqA—>Ö(Ô·¨Æ‹xú"oåÙ«ãS)?¡…õ‘’¦¤3IıÕ!5ºß¼v1f<Z	ÀZÆWO<—ÉÓãq·ózï¯-<Ï®m8e­i˜ŞÚ¸¥ÛÆ´–j_A{`ÜùœÍªU¾cÃ>ÕB©á°:å×Æ‹1i¤¤Ş?‚á%pÎäb*ñ'},ª6š¾' Ä d†›*¿Ù­r¸\ÛşŠtA6pk™Ûš{_M?ÓTüÁü9Û‹Á]„‹¢õB¿şPm¼Œ	hßû÷?˜ 8–»7¿²ïÚİ=ä=Çù¾Û7Ä
Ÿê0xT“c™O”!ÖóÑÀqïÑp_ak	Î?4Õ¡òŞùeò˜•úiğá|v¡=xA6å/X#—a#}û!‰ùİKŞko.ßª²&Ü7.G³d+ıFÏ]'…¡m¹c2C„6ÏÎ¯¸™½÷>ãÓ5ôFA84Ãly“G.¹{Ãsv	ÿ(Z%ÔÀƒ]l86àyb#eÆáÜ™‚Ş%¯g2¡ä0áßë"}²CNH²›„“*ö×…UÑ³ã
&ıöíShÃd·tQú[p•ÌK»ÑÏÉØ÷í=8Ù;6x”¢X›©’ v;ÙÖ¼lßkĞ4äá<x‡z}ÇB!æÛ÷ÎƒêvíOõiä#‰ Vª%A™¸@5Ì¤­\ïôÉ€}Ófv{÷¢-eß­‹|¯4»¹¨‹ºÔ´`Ï^û‚›¶”ÎP$«àÿÏ*Ö¡Qí/4iL©95JÏkuDÓ…b+"nŸGŞÎ+À÷ƒÀñ·PêËfWúòwzbş·¯ŠßjÆö-kd)q–•VüùÈ*¿åæÛ²öt-ûj8_£ap¾ñ‡ÜÑv»¶:Â“İœdSkç?:É>¢MOW¬KìxÊ©¦ˆ,È.`jüÚÄO€Ö¹A-½.Œ´ş¹¹I7ğ×oÃ_àêÚÛ¢3yÿàİÇØ4ÛÕFŸò#)bíwiÚˆóÖ4ÓÖ¬!w¯şPÈ$¼¶£\ûkÏX|3I¼Ïøiöp–„ğ/û,½»zë¶`üCê]OŸ»OoÃiæ¯ Í|ŠQ›ÕÛgò
)M`Ö›V1÷#‘ñéZİ²‡Ò°3ğã_şCÖ’ïo¶n2SXc®îl¢ ĞS\çıòï‹«ÓÌoŠê;	Ù³8Q¦½Tí…´Èdë„†÷éÙ é¤˜å]yÁïÉ10ˆ`‹[C¦AóGZÃ7ì¸‚? F-Y>7=*ª¥KVJ:@CŒ
G¾P\…¤š™¸8¯Ğ	•ç³õÅ­Çe´€{…
ÓaĞøì‹Ï,22fG|­<Ë¬•l[XnåiÏn¼¥–ã7G½-µ0êR¯O^vºÙÅ{hÛK3×’%ìÆ`¯Ø¬5×²2¼k›œMÒ¾†	Ö¡êæ]ÿå?ØËºä-æ‹;¨]{•ŸÏb²"™ªèY ŒJ‚˜)|xšpÜ!=Î%
Ïğ+9Ú¿ü;Û»ÀTŠ~„N˜7zvZ„h·•êËŒ»eÏ`{\hÿkø|Yû_´üÊÙÿ6¶6Wö_+û¯ö_w6 ÓHın6`Ü´?0<ÖàÏdbLVE_ÄŞ—_`‰›W8EŸîÓu4‹6ç½üXøîŸ³\áÁ'Çár«Ä-·e«#
z8©Æh¼LÃ*o™F(ïekÀ€ahîWı!^ê.›—°\ı'*tÊ}ã¨ÔKq­ÇÑ1B3øR™ô§`Ú2AG…‡NÙQÉ>‘Şş¼È±wúLª€ 5HhVŞdê)éK¥rƒdîœ iSÎñœ+oÑS£åv;‹wÏÑ3af¿«ßÊr>!T,¤6×;ŠY[mè~œÂwDı¡6ÏC´:O{ş6[ˆ	ÜäVô¬–ˆØôÈ¢V«13­pàeÕèÊ|£a‹’Ed“C1‘›Öëè)õáÑ=½„;}t·Ö+sÏDÍÃ9«²Å‚Ä$JËØŒX2N®|/b^]`£\‹ï¢Åî‹¼ãd°[›Òá.PLœQñæŞÉx6Q7Sâ|ï÷É`].ïTZ££ã	(tmäl.¯NyVTÈ³ŠÄWĞÚO~ÁîñqKÇ,E}ªO§ƒˆŠ	ÔÏ)y(Õ†‡mª›ú|ÃAs4aÕø"ï-š‰{ÂÌ2X™l.¤‘Ä6…‘Oa	vœ1K+2ö†_»Şİ¢‚†-;ğjoO'ĞÎG¾	{4)YâÍ€v%¾8¢’Ùƒ˜;B(â§Mô¼æ+SzÖ•ÊÄÚÉ…c\Ó"=ĞëoZ®
1§±nñ|ò/˜´3¹Á\Øã%³«å©°Â0QØ&`=¹Ã›	TŒŠÎ0@ĞoñäÄ·Çø)ÊÉº j~â™€t©ÿM{€PüHÙPµúSéhƒzÁE„uÏ‚˜Ù‚„ªBqV([Ï\æå±È'ò‡İÚÃHŞ¯ÿgè°C|Dn½‘· ¾6“ğĞ54ğ¨‚2‰±]Ø9·á«¯Ò Ì°Ç¾øº©~°(<=¦gQÁºÓƒ²:UâB¢wÊ…=à0Š
AÆÆM:°W!lªªsîpÇğáj>mŞüy'ØÅr”ã…ä8°é6)‡NVdÓ¥hç>òıÃ ¡ê¾‰Å>ˆ÷Ã˜1’Ì½UEmÑ?æ÷eáèI*äm<òWM•JJ9};6 ‡Ôï<ÛA¶¸‡il*bXàu~ª¶ß¹“,İ³%ÚCÎo}Gõï›(]/İ(ixvã³ŒtÁÜ%ÍŸxƒTK%î¸W,‹±Ê¸…sÉıœÀĞ"›—îCîg¨ÖY&òpŠC+IGq©ôôàgé˜ˆà\ëâÆX:lh(³h6Ôø˜Ã©7ÏÇÑWÈI·íÇ°?üü³üõ$m \›– ­l'ÉuK$âŠ=Cê)‰ÈÁT	EÎˆË*MVÙf•ÇÙpE¼;fbì
s$GoàMı¸—DhwUÖŠô"R^ÌF¤˜MğT›x
 t!FB~äˆˆÜÛÓ@¡À–"(•Š{º(äÔ_š¾6"ÃÎ®Ò6SM
õ€D"û“9õ	ÌlƒëÚY×%&dÒ¸4nYòb™&s½{‘$
—¨£ØOM£L£dë©ál=ÍâÅ˜í´5@ÃQÉòR+3-ä¦Vv*xvcÇeÄì-’,—‹N6s°mŠWí„)ÑåŒ±2»"ßˆLâ«’ 4‹`'dÑ´D°q?k/T'øÓİÇìÖ”—Aí²àk”föEÎt™+F|m/—èˆ…§¹ü¢BËª15mŞ‰ü]:‰V¿ªüéÏCoâ_"„Ğ•7F	LST{ùÊ ïÈ)†’Ê·È•ÚzU{FAR•/ÄÜ–ç±x	M|’	2|`2b%åïM ÑÀQ$XÄWš¬˜+‹‹Û±Êõcoàüôÿµú0ÄõÏZÇüüdîG[ÿÄ­î¾Ôü À¯fÓÚxøeğ6·`¾3óÿhk»¹ºÿû"÷&A§ŞqO_8%¼-{î_Xh#~÷¼oèZšÁyrtQ%×·É h‡‘jöØºrÏ’wõ¤ÌgæbÏ=ö.ò/Rc:Tİa™µ t_ˆÏëŞ‹cÎ‚yƒ?MbƒÔ“¦Ï3ÙL<íCv>K8øÁóN¹“ËÕêóºøŠZ° ·/oTs×aDœÎ2?À•ÂEÙk«8­VK¨¬ä$dÁ<£ gªgù/Jx=Ë
z	–/;gÄ@ÔĞM„TİÏADzÑ€Ÿ³éí%–,áèë‡}KÃ‹¬xn1sš!^àÄ¡¬¨sl›ÒÒ° å¨ª{h>ï€<™îµRÑA$‘èÙ}¢öd®*UP’ÇqsŒ”Ñµ³”fDQ×¤4Ç¹Ãœhüı¦§dŸ‘Á6L÷0:ée¿ÁNˆ3·Z}ş;~„ü”şùÎ wÿŸ4¯äÿ/<ÿ:Ëû’ó¿µ¹••ÿ·áÙJşÿ"óæ¢ä7E7FTVƒµ“oLÁı)sÑ¬µg—¬ñÔe„*Õ„¿´#ËTcº1¸ô]§Öû†¶:iª{¦’&af3§,½½Ã£ãŞ^Ï1[s9
"f{vñ’ß]t ŸGÇø³‡¿1s2À‰¶DÖ4¼\J“É‚¸Q§oZÂ¬J·®ZuV=ã2gş	WÏSQÙx¬©£çdİM]±Ûíô^u÷¨±q´£³Úæ¡€=
&<ºõÃQğd‚ã“‡8ˆ\:Æ3YÖºù¡2zä',CJc˜6Æ¨ÎªºA’ÒÆyÃ²ïÉ–*Æ×ÉŒú\&¤ÿkJ,FßÉ%c%•Z¤»AĞäXÇä±Ò|›~=¯\FU‘1=ÙIàc=™1e˜¶ÀCÏÃçóLN(äúKNÊUêûyÂì(Ğ…Y0n!‡Í¤P1ò?üüó[‘à&›$ÅTlì‰«ø€ÛìËç(¢ÒSaªO]ú¶Åj±Ğ¯.c¡/Èš/9vsŠƒFˆgØ
kCBq¼É#ÜqßŸY¢ë<Œq4g“„y±RånğÖC¼7PÁ3ëZ—¶F[¬)ÍÖŠ|Ô1xØsö¸é±ÚläÍĞk0J›‰—Au“ÒÕ>C_æ‡,Fpá84ó‡Â!b1Æ<'|µ|sÔu²Ğ|ëCzĞûy&c8!´Ğ†³:ü·’ÿ#he Œ½ïOù»„ş÷Q#‹ÿ»ıèñ“•ü÷eô¿rÓ„­&3gì ky=l¨po=–€!@l˜†ã¡Üâœ—Ğ;éHJ
Pß›ô¥Üî>~æ”‡#xYz>
^¼aÈfÚaSè5®à¢Ë3LIzTŠ Ã ópmKN•¬¡¥qÖ'9a’ÖS†[M
6íÅo, µÕ\OƒwŒGÛ¯'£Ğ²´ù÷ĞV‰Öç·ö>Â„zq¿åaO¸¸‡P5Ş©çu˜+1eoB$»†ı"D	=õÑÔŸ ùÑÃ³rmïlÂŒY57OMé%Jz^GŠYB'¯hL‘àíuğ6=x¶ŸUßœW·éÏyïšöE•ıŞªôyí»O]ùÜzD5RœåªÜ{TóşJğå¶ª¶TúB×é~±Pë]D{)Gº»â<ÏşÓÊ204üø~¥¿…òßö£­­œşokuÿÿ{Üÿw90ô€mâ_0Ax^¡:éşüš]ø^Bş°¸¥œÏ@ÂC¼˜šã\‘c.«BWşøjh>~ÈÈ5@Œ-ù°ó}Ïà¼3µÌåÒ;„¥‡°Úúúm¬Î„q`SC8!dÆ±UõR?EĞ˜;@{÷ál@†Ô9%±gì!Œf‡l=‰¼I<õ"T*(“CT³"ÆV<†Ì‚DÇõXÏ}^›ƒ±v0$‘º{lŸÔÑ&e«£pğ‘ûŠ^w:áBQt”Ù€?_¡ÏFdğHgQ¦1ûy£ÁzZããÓ–ƒ Iêùºt6áa×=à	ÍF:¹Ô=Ğ ³^ÊëmS|çÒ¶"R_jQmxÙ5=«#Á§C”VùÎÃÆöƒ!‰¯":§Ò—äïDˆ2Éë½¿vvè”bjĞ†!­œd`ĞÇï—\*¦Y<Æ¹ÈÑÎëàPôæ	FArcÏDƒÁiÒğôIK$êAIÌ´$›°$»ø¯çO¾0Ÿ­ËyÖßiw_°\uíÙ%î¦?İaı#…B)µÍ¢%¼mĞ­¡Ö•â¬ùÔ–ˆ{´Ò~Î8>¼êo´r‹1Äs‹Äæ‡‹×hÃ¤$ö4O´pš.R#«S’Éä¡–&‘Ôw)’´N· ÁP-±â¡A]0˜X,ºÉ{NF|5ÀHørÈw~FÚŒŞyB¡˜ujÅ†Ş>>#¯šÔDI™€£Ûçƒ3'Eb¬
–†H€WOêb¾o—j³äÓ	¯©¿à7¯ö÷Øò½K?Îî\pÖî#øø2 ;˜ôlÖUg3ƒ¢oO8Ú4ÎúDÛæYcßp*¥ü{,úó•6a†¼ÖØÔ(aiR8å.ÔÆ!LÙ¦ü²Í`ĞÁÔ/ÙÁmÏ ·t'ßÈàCŒÅŞa¼€ÿNÔ¾/
 ƒx;ÑğÃ·Êa46jùÏsHïÿï[ê_^ş’³ÿh65Vòÿ—ø<xğõä<îèÿëâÖzcƒ?dÚÅ?ËçÉÿoˆ¯Ò$`™Œ,SÿƒóàšÀ7ä*R	AÚ S1a^ÏÍ13ep•gfHÃƒÅe¢1Î{)¾U’;]¿*ÎóCúFÜÆ¦¯nUîoË­îàmSZ¾ÂWr7S	¶ø£¢ë,m•º&[¼Ïw=3¿šqR•6ÇâsŸ“	ÚÒ‹Ñ„ì„¸¾ÏtÀF¤ÅsË˜adñ}fœ)-^E¢§)°Ï˜[P†œ–b,,Ğ Œ<6bjÎQT€…6%4d‘GQI6*æiæX~0¨I4#µ¸…æl£€ö‹Û28f·±ÙkÓ†0£–$jßLS”‰ùXššÌm÷N˜9Š,e!dÆ±x ¥¡Šì£È˜Á=Û¬Øi®Ç©hh—CnæRÔ“ù¹û/­`ìäŠv1Y‡zöL7¹ÿ–Æ3ÂzF˜Ï,²Ÿª¥|ÅglàMDuzÔ…õÄÓÏöıÌáŞ,Y¿Õ.O;0â­5¨&sîIş¡ÓÑç&®¢’÷Kúÿmgõÿš[Û+ùÿËèÿZ)4õ°ÅşëÌ(P}ÌÊòáí#âò‘Z(cÜ¼Æ¾Ï×ÎE8…×x: ´@”,Š¡Ë;–ÜLı–»ç*£ „¿¥eÁŒZlÄ…L²‰âÄâ:¾ó‰óQx.lêİN{÷ dï*ı1¤éƒÑ‚ĞA/‚A EÜ¤p†úU^uK+ÌÖÉg*£F†kG¸ö£ÎD€Ü—^ıç\fW+F¢Œ,P)ÏÚúï‘h5ªH¤eÍ:é&Q¹ùãğ}õişOÁ^Âˆ‰’_ş#“¶Ñ0õ£Jí˜«ÔzÜtÉ†\LªÄ_şıò£ØSR¹ˆ&12B‹vC’½}oˆ[çQä &Hddû¿½Ğ·Râş4Iİkƒ€/47*í%k±±—Çá1pâ)ÌŸ˜åt_8²JøuÁG»kğ†ŞT“˜µ¶ÉãªDŸUB;„úÓº5¼«*ê)M–"¤†Zb4‰i§å]”¦¿ï0Mü•¡*Nu£Šf}ŠñRs4$Ü\4h	ŒRıaQ!'¤„,J­o€s¾Aá<51SDòÑ›ÃÓºXÍTñÜ¥›zB±£Cü	ÑÌnÚ›qcº‰“X *OìfÌ¬AGÆÎ©s©²0rÎÏŒÊL|ŸÕ!}fZ„|ˆkÈÃjÃ:¬úJ—¦ÙFA¾*âÕíÏÌU[½É›fiEã%b7±ZÉ®>«Ïê³ú¬>«Ïê³ú¬>«Ïê³ú¬>«Ïê³ú¬>«Ïê³ú¬>«Ïê³ú¬>«Ïê³ú¬>«Ïê³úü?ÿØ!1  