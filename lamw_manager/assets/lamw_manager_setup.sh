#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3055651537"
MD5="d9bba2b17d62b860208f556c332bbc7a"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="24736"
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
	echo Uncompressed size: 176 KB
	echo Compression: xz
	echo Date of packaging: Mon Nov 15 00:15:32 -03 2021
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
	echo OLDUSIZE=176
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
	MS_Printf "About to extract 176 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 176; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (176 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ``] ¼}•À1Dd]‡Á›PætİFÎUp:jd××÷U#ä¬ßŠmÎµä/ãR¦„^ÛÛ­6Mtº
 ÄÎ¤R–âô:w­£s—ÁÄ
•ï#PßÈ,åm¢ƒi—¯uû2à1Ê#”¥=İ…‘y=RûÂmî9³?l[ÕBÑÊ=T›‹Å9ïáÇÄäù‰|º½Htìôf¦/IÔ…54O_êLÃãólñVÍW7~ã&I 4ÓFoìJ%|€i¯ÅÑ QÕ+³—¥Í*ğí˜E\á[Oà0Tå³º¶»Ì')®pqD*„æ`c
³=çQ*™6(ºÆã/Š7¾:9D:ógaõxsSÔ3ıóOçŒÁÑMJ©‚Xê¦vÛQîÃ×¦}[ô5¦§hcè07Ìt0ÆÊV^üä %Š“9Y…âÚöQÔcå„äóÌkî"ó÷NÇnèBfæá°À{mº)§1N'rR÷Ÿ‘ÌV ß£Íº¥aqú­ÁB7ñ0·^Î•UÑe*¤mÏ2åé÷‡8ĞşO^‡†ï´Y¡§ÃÀû¬Èˆò4şÇë© Ç~:7Hì¥åLRÑ}©h„ÀØ%õ‰¬m¼ë)<».ÚawI#©G´áË.”0‚5Õ÷qí+ƒªš¨&¼{•Ã¬º‚)â°ÚÉ­ôp2*$ÉşúìJÊGçM9í_¨Ö@TëÂã_1.zäƒ^¼I¹~ğ…xˆñO‰ØOi
¢WÓ|vNÚºá„‘—OöhzxJ/[Ab,¦QÿHvõ¢Ä¼à"_¿óÄúeå¸;ˆ„…&¦Ë¡‰RÉ©I::èr¼ı’¼BÅxâ¡É©üCH˜]škÚWºdÔ"u†Ù¶NZ6ùC²%ñæz\ˆgRÅÿëºDûfDğ%I©Ä
™´1øxy¶Âø}¸ÒY—ôAÓj>èŞ+?_W(7¥h§±áSÁ_(öLÖÿtKş88oÔÃ’rQ±¯•¬CKGN^ŞßãBmcÖ©«'ìÉõ·Ñ¶ZXXæA–ğmË47ú¬ù‘­%=^¬ßÃá\È!E9Xj-ÓI\?‰txôï`¾_êcÇ£í¨ªÏş“P¥3Jáõ¥½åÏá.¢K"¥±^ïRÂQsCÌsãİgFÔ=àqGQıDVĞ7HQÄ|– Ô*ÎŠ‘*ÒxHƒÓ›a2]ÿîelr÷åIœµÃ—PŠùÒoËB|Kµ“+A2@ÚÜøVCx4èá?8(âšwW,lÄ|–ggâäàcIÏ•3\\Ëë®š<ãñn+£:H¤M½’_î‚êÍF4w×øÇ€º	æ¡Oa¿ÙÑÕşo¥Íó	"şpú¥ì¨ÔöåU¥J6/j‡J5*LbôİZôzµ±ÿ—òÄR_ˆÇÊ§ÓŒ@$“CĞ LåI¼g(9àÊHå›¯4Æ „vã‡.;¡wÍ¹æOğú?|ÿ`c>,SAêõN®î¤.ÑŸ‡¼ÇõŠÎù?%KÒœ±ÆWÓ(ÍtºMá¹(îx™?ô^ÍÔşjˆ¡#šÌ‹:[²ªLÁ~A¦Ş¶"ÂlÙŸS_«¸)«#×WË”Áõü8µá?Ó›è	EAnx×Ğ&!Vş½ZÖşÌgŠ
jÇéQÑ9©Å­ğd"r³ëG9‚ƒ«ÛãÔÆ…¿zRw„ä-W¡Àx`ï~~˜îîñ÷øFV#{lÏ3X˜-Fãüzìá÷ÄÈÍO{bp“ö—Æ;|ğNx¬,İ¤ÄtAˆÂéitöÂ%.$ù¶_U™³W#e[Ñ–f®à;Ÿ
ÕÆ ~ÿ_†s5ÔÍ‚›X©/B÷Ï%^FH»æ[vº/YJ™¼În<Å¨®*ÚX®Nz£å°0aDïæšÙÇ<î”FLØ›ì¤“
2srW¸3Úed¶AyöÓAÄJH°•\ñå“—…7ÑÂY.Ò]L5rg kÂÌÌWİ&[Á*A›ÒæN1šÊã¸f]¤²¡x±jacúä
%tú^ı—o«%Y ƒ|°jÓU“Mr°c~qŸ8”¾ñ!iµÄí;Óp]º¨„Ì@eâ÷;²fíˆ+ajŸ¢¦äHØûØ‚§q†fŠ†Ö§›a•Â6·µ„n¥0G‰„R2L¢Òcƒ©!+ÃÏ“ñò†ˆû¡-£:«„î(.A²ÎKÀ€v#d8Y‘é8jÛ˜€©têÒ™e+€£äıMvœ÷ØâÜ–$ÊqU)T¤á»€ÊÅÎ¨¯¶­›©/íE^áã!¡dñ¥)vÄBĞ–‰¶g¦d–ê&)c>D_pÊcOàhˆ°Ú~Vî^ş]œ©¶ê&Èâ¾‘¯gşÅ®TdÙq80
ñÃ| °·Vî¹9ZØ8šË_ÿêj?M'Î¬­9¤Œ}~ü™GŠC“¶K-“s/ÓÎeEGßĞËR0k~$^Ï‹ü|‹ù;ë^Šh‘uÂô˜á…X]ÑâtOwİ6+“èQc ¬Oé(¨j„öŸ-„8ãÒ’Stdº¸ÒOè±ïxà0®v,£ÉTLGâÇC Ú¤"cï`IñŒ½›+ÀQç–âYÙÿ7PA4´EBë W$'®nƒ/¹ÆÉ¡ÁùU˜£x0Iè½ <æ¯ìÆ’§Õs¿5tô¶ìh@»±\jÉxË¾)ı8/ÅÉä`9WŒn9ŞÎª”¶–Ó·Vaäy¯|ŞvëİíÖ‡oò8ì¶E9•ä”êÿŒÕzCqUƒôÓ@ŞÂ›–'Ğ[$yüà³ŠıõÙóCÚm'—â¸úŸÿB…e
æ€õzQ­ü€Yõ1"’&eÏ‡q„J
ªDj¹Á<"+lú,ÃÍçöBÔ¼p–í¥Ë'Eïø¡ñÊşz€«km¤ºLˆ&İi×çúÃõ’•¹Í;iû'«Ö›™B0%Ñõ¹tlqĞ¢Ğ)‘EœNx¨LË!µ0érı8«’±V¿îç2˜ß4œ}¿qQ\´Lhò5ç[RD<6÷lGw¬¢ş$	 Œ™YÃ«é|óÓZkÍkğ´åtTnzBˆÑ·¥ä˜şr1Çğììv·ß†œj—¹°õd!fã±`‡õGGH˜c `0fvD1±Oñ`\neı0 ğbÈ%@kKä…ÆŸ{pW•-×8“b|şL\çîæÍ 4>“|ºo‡!„ë®
6©0hŒJ¾È¼â©-wq¡ï²ÎiCå6×ÍØb¿Å i††P¬äêRsÃa™e.ö‹?í2ÕUûR¿´ªÛ_jŒ!{­7˜ª£‡)½¤|üôš?H1¤ì8î(*u'$®¯S1ğe´htZûJøÏÊZ¦1qoÛ¦£GÿˆıPJ‘[IƒÔwvàåP'{ÆŞş²`œäc×E¸œ+Ä¥#2Bp+ìD: õçpJnXÃp9¶Ï¨V&v.g ª@W¶í¬Ğ)´Bv!¦ùOU¹ÁíP?¡—1,Å|á¸£ğ|Ûp§‘Ñª=]µA¹nÜ«ºú¶ŸÑ'˜ï"öã·môÀ$P†æêğ„¨ê9l2Zÿ|=YôÕLeMìŞÌw™i|æJÏ‚ã¨‚Ğlæß¯™·c”TÏzÁA"Ö5ÂüOZH-İÙÄ",ãïT"eŠlÖiú¦”æ¶ûCÎSÜ3kŒ¾¢‡ÖaÙ±¯ï»—§å€°8dr’_˜tÖñ—™LºŸ Hø0°µé@
eŞ}Ìbı¨>`+×ätË¯P¿›‘ãh(Õ…)Ib¦Iåd&¡¬–üùÕ˜]Š²L,NCENDÌpÁlN©¢YDv=ì·%³¯édğãç…2[<ª§·W<LĞ“x3ĞOµñï±Û…ÌŠCï×¾HZ‡í#pU
 VIË<©&ŠòxŞ$ydŸ¡@a¦òÚ;/¥¦~f‚T % ±Aª¨„ hŸ—*©JÚ·ò:{jÁÔö¸Á<µÙÑ3¥"p¼X6}Ş$˜´¦|İ-6æÊn)şTVÃ;L©~]T¢úëÿšg=sÇ’¬QÛV !ènTˆ’vZv‹ué“"gTÈLà^ mÄ¢ìúHÜ%¤!Æ]FÿvÉM'Ã_.„dé+öğb(º& Ü”æÛûªl[îE€Â)§©:S@Û™\şVW@i(kÏeH:*‡VlTÿKH%§zÑS³öƒî†%GúÆë³ì`Í[¢áo³5…M™àx«<å®ÏíiÖÇìƒo–jĞ™ÔÎ‹Ê\DI  CW	Í†ˆ™„…ÛåW ÊŠ¿SK2 À=ë]Æê°üÔß'¥ÿ>7¿†-òvYòj@§WÆNJÒìl,k³™Y’Q‚2%m™ˆug×S­f_¯¿ü$V²GŒgûĞ$êÈÜtOMKD·.]ô¶¨§,ĞIaõDÙ]ÜÿŞ°–úS:¦'Z›Cx‚‚3lDŸj qQ_ãàë¥¥UD`;%'­šŒ»¶©8ºW2(º\äú¤ë×|3Ÿ("PØ/s–§Åæ`·ßİOA°¹7×Á„¼¡Œ×Ä¦<¶L'Ğc’j+‰€¸İóÖŠÙ–Ú&EÈÏ^§fœ£Uùÿh¬ø…ğ¾ÚJ‹hä†]Ùz›!e@ø*”€ÜoÃršŞÍíğ¾¦Ô¹>*Œr­o8B­ö,|.ºßùøÇéÊä¬C¢|+û3Ê+ò0Í€R Š[ Æ$­Ô|¹GyM³=*<ŞÃÔ&§p; F\K`è×J§±†lˆªÏ§/!¬Eø©lø`€Úğ·lî’¼VÂ55Æéø¦é¹jÎm–(B>³OkpÊò¾¾%§·ùÃ®ŠÏv¦òf•»üé3Ú€Üøuzº¥ú®g«ûôqö?Á¦×Ù©L/qP¬PÙİÉ¢u†[ëØò,TO}#É…<­‹¤×K¢içĞwúp•bŞ[\WçÇ·ÿnÅÌ°öıÀ3l5nfpKù¿xDÛWÌˆ¹× ÚÂÜ­»…Q‰KËĞyznŠ%
,jÕ§Öæ-òVJ—kÄ`l¿U®îW{‰ÖÔªú&¦ZnRYéÔ5?¡W&n›dÆ¯/lÙ«tÖWÙö†ù¬$ÈèlÑ ßÿĞMÅ;Ô Ûr.% F6CnË[;_·à7É8«ş\
¥?p#İÅïô	¸i z[{zè„"%hYî›t1ÑYfzlú\7Û±AÕÁ¾OŞnÃËÏş›ŞïW²”! }p‡÷±ÇåÂÙ	2ŒŸ™BĞ‹h±j‰½3+J&*¿àhüı3—ÌjÊUii$?‚z·Şº“m_Ó¸ˆùÆú©]8˜Î Ğt<«œzÙ‡ei÷kgõ_Yú¾NV°X0[8­\_ 	şuAÈ %tßçI‘\Ğ’ÄšóƒXøÅ>±±†"&”@)¸Õ˜^d*¾1n¢7şBX	0¿Å»YÿYe“R?ªƒ]CÈû²Şk;»6i@^Q}vµBº8„‰æ/~1yÉ¢BéûÇAwúnJøÏÓ¹VŞ²‘<aù"1ÎğInâS¬Ï’ÑnÄ[*õŒÔñú Û„ñËéÌËe[±Òé•E_Û½S®”IİkÚ}~¯µzo@`LÆ =Şå‡NÓî}F¡­–ëµ$*òÚ\ª%°_-Z=şx¼ÿ°1şb‰ ÎsÍÔ8ÆÏĞ¸ø¦^ {å6KôaâñvÒü* ¼àm|é…ŸÆûñb<¿`æ€ãŞÈÒÕxÌr8áR5t©?³»Û¬"™—p%kNÅEÉÃëÒA!nÄ‹¸ÎáÜõàe`e_Ãb¸Ï:ÔCwuxÙiøü©pëÄyšÎñÙzŒq‚£\”N…û¥GUíÈ³+eš æ^‡]Ào²Qg8ÓA	Tm¶²¿UB:Û¥@üøgAÈ	²³S…àätföë^ôBº'–Ñ/¬Áx™loº¥’I¸ƒ ş¹­"p C´}š·«Ÿ,¦s$³Æ|"D ˜ŞmAŸ—^¿%‰ÕœÛ¶dD†op o7Eµ‰0Qâ†Õ~ØZüåo|h·Öä¨j‰çv.F)Õó†>k$Så,ÖÇ§À ãÃùNôè)ZÃ¼‰¢_ÃúµnpğMò„ÿ5å›Ò˜ÌâAáî›şh.é„jp=‡ğsé3Ä×†Aˆsß¥ˆîÎ©¤|ıg59¼vEæ9¯]Oòş€VqÎ¨ê¤S0nZ¿¤‰õ&«„Œt)•>ğr¶ôm¡ =÷óÇ2fXÿŠnnH×Gñ³EÄA÷Oİÿt
ŠlW3®ª6Ì/ŠO†•[jb7;f4±”[È>T÷Ò>ÿŸÛ{'™˜ÃÛ!e ¨]ùçŠQpj7 ]8 •PRX?¸(ò‡ˆ7wºXğWL%Ïù.’d‘Ş Dô*À!ï¹Ó	q¥`ÃÑÖ2À©Ë$.ĞUP	ööRÊcÒÄûÓÈ±9ÈÙ9Ët Pä›àPúÜs+AjLkl÷ÅÃÄ6¯ÁÎM¶?,
,´Ù¸ïEÏòRâ'ÿ`F+[ôjZXÃíôAëyşÁ}ÃÆåcÜmO€yj”\I ­#¹ªáÜœº½²ÈÎô^ÎpaxûëŞÄ(ôØ€Z©ÓVÒXB9]4E«¯â}Cº<‰Ç¹ÈLám`Rµ*lT™Ñğá B[NÔœÅ7IT;¦º‡†®Ÿ ü{í+ÒVe 6úÁ&TXVÖº³dbûPCv]àº^ÔÒŸL4tõÒÒ İ/Z“c ÛÑ²—™ÿú²^’í¯1[7´ HêpA$ñHÄÖÓ{1ÇZYšvÚ^y‘nd®¸C<A
î‰Ó4UGJ&Œöˆ<#Í’CíD›êHÛ8à½¸HÂÑjî11[z.ö&ÇÇ3‰W«É§•:S(ºªÔ¶cÂrïÍğs¸¯Â`*©%”$;ª š<-lAª4®×g¾R('pô%Ğl|½Œ‰ÖÃlËïË¦EUœ0”®Gñ^pşPâ}sy’H)>¬«oıW{¡õCØkàîŒ.pd}–,{-]obu Â{´¡¨'@ºÎÛŒFJ¤|¤i|Ê4ùü¼×É |7`£‘;Ìy“©cìÆ~U—!È¨“qÀITFÃğ#ÏGD(ò—»h® –1JÚS»x
E+È›’Ü_læMÍ¶iò@„¨¾©K6'Y”7³Á	İ:h™U­‡kÇrb¼p“Â×´1c%døÙrK)- úùÉ
Çê-Îy˜ã‚B×¿ü
öGğ“.~Nê»?±ı :ÂTYhJgGÏQKæ=öPÛ7?÷:ÕÌÀØÀæåècèÏ\’b¥ªH#"7[':ø¦¬‘ÈùoZzÍzEø‘ØØ’haèpéÁôZa=n¨ñ<©‚`OËkµ=\ƒ4Xã-HºÜôìq|Ÿúƒ L¡ü%âëcÆ†šhø9œÑ:û ƒşqÃ‚‰p¶.8ÃXf%ƒI(é[˜E’bCÃ‹Œê¯£GÜ*ÇvÜ£¹Ú>û6§Ïí+ª&‘ÚXêïi¾ÚÄğ‡(TÀeì×óB
	€©ßFZ 0¡*“'ø-ùB\|Â­ê´fpæ\Ôêìõu˜îç¨áÌkç/‰Â]Å¢‰‘¹ü"µ…cFì!ùlÚ›•ß+ ³ÿí–,2ğ,…¡&%õÿÈfw ãÒ)tÌáˆMpÒ:Áy×ÔÜB¥õ¡j¡V…e~uæDÖfEJW0È§sT7)·>å—êäT¤ø‡Íø¡f"I@cÏ}ÁºÚß2l³Ìğ~±	kf4tˆp‘‘·ÂúµZw˜ş]¡iæSƒÓÕœª8Ú”Ç£ÈÕ¡’Ì/µus&»OßGS¾rj:ˆ8mè¸‹²oìÆÀÛŞ•Ìêû¡x0~ÁI"ù/’]ßó	¼³“ˆGr)DÙxÆ±“"ªÇæQICßˆ+l^ı)
²œÏq3À!mY¯¾€Ø7&ìÕtfOâ–•<Ä{}0Çw&ı@9øºê5æU!Í¹Jı@€?ÌÜ=Fº°pI‰!ûëIîìü,&ã®‚º9ô¯M¸lÈ®%İ”{íŸîñ£JØĞÓƒ›€ÏUKCpe+$›K‚£5.¯³ê(—ÂwJáŒˆí«še	ŠUÄÚ°§©P¤Q0S3{›âFØQ±½&ÛWÄËò•pò_&,ƒ¡AÈ^¿ê³]X•ÂÎ£¢y¿}jò70µˆ}@òÀ’^(¬½~Õ‰üŠ&†ˆÏ*Å#hoZAÑÔºu²-™8ô51bbHêêÀ)’Ş¦ÙË¤b®¥6â¤	ì‰î­]óG¯NÊ~QöÆ8f&zÇÔëüÁ~®ÔğBi!5X0’i//Í†õ7jø
¶äj‹PÃÓLÖìß%³G¦[Ş)?§GİT®×³à˜”¡–•æToa1·—	¤BÒ
loz“w'QqôRÒ¢ææëí•ö¦ª+÷|¯¶
#2‡n´ÿÔÿê7
,.Ókß÷™#B­&;.#e’d_à`(B_ê`‘?´;ş¿‘ši÷›ö'I&mÚı¡k¤”iEI69Õàóù@ì—·ö8ìğF/g<k¼-Œ"4€ÏÈòÉáZÁb LÒÓ«z+Yß;›-lB‡»UÜö÷ÚR©Æé®©J5?ßnÑ8”F‘R¾e˜W*Íºq¾HoxÓŒt/|¼‘9éim)Qš»ÀÆ#G´D›ˆt)*št{~vF-ísÑæ¦ëØàgTóbø¾Ö4:“ïÙ)¯£üà0ï5l…K?î_ÄôªbF^_‡ŠˆãŒÚñŸsGd‰f³hÖ¥T¹ÃáV³æ†b¤Œ]Îä]2D9cÆ’_õ=µIšÑ·R¸}`Øúìz2aB>9í)!cìyè¥±M‡f å/FBfù¦m[(i`F°
ôİ*"¯?ŞõÎCä'èÊÉ*wĞ_úNdQ&¤öä>÷./ôÓ@º„Âäİ›i<^ÌøÇ&ú.ËG&¦å¨¢c¶wCäãz0¸¤q-Z;¸°ÄSiyŞì§«g¥|ï›S…Î‰[TGEÇc;;÷'_E[Öô…,2&%ÿ] X\R7¤å2E§…èß4`Ù¦Y‡D«ıF¼iSÙÎ™:vÿtbÌ¾0Çÿ!°4ÆMÉËd¥TsÆ$4´¡,M/¬«Ğq'¥­’éÆÄ­Êãw|E3R²›Ş úrwf#Ët“°ŒÏu§Æ²B@gı&&ƒR†Y0Pá0±gp3-•8†ùÇÈ„NKa©}È8ÌèŒ°1XœÀÇ´^ƒW	*E2ˆl	?†ÿŞ(H{ûS¤ÑÀR›&söáà°£QÉó4gMÎ“SÈ",QÕ¹ŞKŞô4{Äå 7íuµ[¦ëK=U!à§›âBÈù™P¬2e½ˆ+ÎiH à^š{ò¸- ³^QUí¤1Í,şŠ6È€ó²y•»J‡|ƒ·²ÅùŸëdïµÓ/›K÷LZ}ó°d@eÕWµšUêaïdÌÿ£
Vœ”»d{!{ıŒaÍÑ&ô
5CCLµ ~ó·uÚZ£;x‘³q®¾ó×/1$¢“eÊÕHGÁg•£Å€î™×Ÿ4I“ÈŠ"à –ôF¯å®¨"­ïK°@xèuVWcY~	¬#yëø«¤9ûü¸á"»ì.L½˜…æÙÑçm
8"çÊ#cA¨“ô3³:£îáâùØJã	€Œ°$•ÇÌÂğA¤Ÿ–ÚÑT¾9ô1@ñ{‹pşç'™w(H^aÃ­B"´(°2g„:ŞrPâ{—°û/“k›ŒÁ{mÿœîÃŠu%”oÖAÌ¨X¦:1Øgocö:W‘DÂ$8r.‹d_Ì›®;Óü(ƒ)Ãâçmñ¶ÆaÜ™ğtPñ@äœUÎfˆXv¾qrmX~¦æô»väF-òÙ¾Ö‘¹øËŠncËs,ğS)·—æN½âB¾´Bó+våÕşfE€`?%5êÒ€Œ‘yÔf::FW{eîÅÉ+TÚ‚ƒ)€.ùˆè¶oˆ~]AäÍÇ*[^×è.™â~\Z7é¶ª{ücAe!Bú”#À¾idËXJ;(,€”éÑ€Æë¤[œká{>Ø_^¯gü£KÀ¤ó[jÉ0Nò “‹yŞø³'H‚ƒ%|QÄäCÈ½«Ë*Ğ¡ÇsDƒ–‘krÌ’Ã]Å×A#¼1yÖçØ†MÛeMdqÀY©ÄÑæ^1Ş5
…yJ×Èƒ*ø’ë©£¦â'÷zj»]úÄy“gáñ4Âñ”õ”¤?…+·+Û˜*Ê¬^nxDa¼Ü
oCuUQ<ı–h;ÍTÒæW¥N“]î¦>ŠKÎäUÈ‚6¡Î½y[¸£µ5ßQOd¼Í¾—àTF¶0w>ØZ[RŠ.¸­”yáYÚŞ¢ØRL:x"œ5èîôÊ•Ê“=„bgÔWü‰£Ih3Çfy¤mˆ2€fˆOS!y5ç/åEÛşgq·¾÷¹ó£¥ÉZ"ø~ƒXJæSvyõ]¦ÒlÅcV{äì~iuÌ
’®‡”5ˆïTó[÷”óYé_²w^Ã¨¼:3_¿‘Ö[£_¼À‘ÀS¹ÕùaÔ|£vWÓqø<é´şt¾„Ê;%®f}`²2‡}íI]§JŒûí&p m	qí¢äÜ¸¹## ®*€ÔÊ¢SD”v4û˜³ÑÃûÏğÃ*–x/»‚-z0±¶Yv±À±•H¡§1ô¼˜ö,ZªøÌOh›Z«Åòù©¸ xwËÔRog”LœmS÷‡/ŸD8`š¨óo²¾-äh¾¨,!Óû4ŸW´tª8t¡¹2®T?à;ŸË7F¾ÏeeÆPY)¡ğ>}ÂX×ˆ©#3 âoÍgbJŒ—~àÿÚ©®D0!pÊl±—çIÛõ÷*
Tm´ï›ÈQÅÍÏô
Ü‹¤n•¾´i<M@ü8æÚ´ç¤£ïş`W˜NS2«z^I4”µK2öÍ‘Ë”«YfJj½ÁÛu}²ÊÑòzf÷ßò³,D;dwÇoÑ¹ÒõÇ²·éÎ‰9Ä¢¥ZkÁ­)q&½ET„±ÌâxTÄÔeêŒ,ƒtœ?ë;¿xÏ7æå¬›ìZ¡´£ëEœq9gü9êÊüÄAwrühƒY¦P‰Á¤ó\Tiÿê.¢Ë·+ZÇ5^Z|ÛÄí¯¡¿æXX…é¥ÇÒÔº°qåãHbecùwJŸ.7‡	ıàğêl®A¯¼sdÏ	‚Ó›µ‘ÈWam'+ZKQwÅ,Ú÷âêÎBø¤·D‡§!Ry.oi€ø­;Ş[/Èf´Ê*`üÕlzVv”¹‹I ÔäâD—ŞAlf´WÄ‘Ò3ş´i282ıœ¶=	?
Héit=<Å—îš¾°¹Óù›dÂ_Øï‘…z‘êbÑ:éOùMc1½ñºß¦ÉZ>Cù7¼QØízò"ñÀfÚçŒĞõ“*SÏjñœ÷	r÷×ıÈ>Õá‹7ğifÔL>F†T³y'Lä…&†Ü¬ÈÆ æ{¯$wŠ„¨­£?¹«Aâ·YâŒU½–ÿÀ€; I7†ïÇ:P70ï‚ùVRÈò§Ø±Û`§‘î*û˜Òc_
¥–‘àÅFyÙàW4y’ŠF CYKô¦Á¨*AS“æoõ‘÷¥`á]ÚgTÀé/tõíWÿ2rÌ ¤M†ŒŠ—!UÚæÉ.CÈ™“:àq$¥²„§ÏÒ`Fı4
,’}cêˆ&LGğ„„­«gÒ(¡
¹œÂÄ$·)!Í©là¥Îx^Ö“³“s )¯‰·3ÑÆw˜ß	;d”Ğ0T¾']È Ç˜Hë²e9"/ú…Ù6ëYhF‘Ğİ€§Q1‰í1£å\ûãÄíUTCvß®B‚çCgZb	ZApìêklıî‰+—j’?])QZ¼,¼b€­"-ßv¶0×ç7FĞy“K	
e‡«ÿğƒ‘¬ÒË£lG™MóD´#åHÌ¿=“|Iw€û8 °‰ •¿±ÒéÛ•ÓŠÂì™_Ü5úĞã¥µ‹H[³'5¨µ]tfX‚¡Œ©’öTÇíg‹#e`µ)Ce’+D£_	¹L4¹u°·Ø‹TWŞ‹ôğ÷w§I/2×jåpÕ¤ş>ÃmBrĞF:ÄêM†\j‹)††h³úboÚ*­ÑÊ®—ÊiN­Küëõ°?O—¶çó%Â
k™Û]ğ@ÌŒ¡ÆDØßÕ©*ú…u½™ÁÇ(mkÒ…™Bf¬&¾ŸÅYèÏ ¨¨ºı³l¨@M(G¼¶ >$Ëwµ;Ò£1ÚY2Ö*`· ¥xkä.aÃ(ˆOê9¨‡
“ £jÈ¶n$”ùAšd—“›µ=.ï<.ÎË¨Ÿ&Û¾‰Å,İ/2‡&ß¤¢K¶6ù—È}"»ÄµFTú	ÜÀñ:|Äbÿç¶Í&ÿ‚İÙ¨Ë›™Õò”qÎ”‰Rğ,ÙGóH ÎL­¡
1£N"8Ä©C6Ê°?Ş˜€
ß,¤XßæêvÅ±Ø‚°ƒ–5ë´‹Ö ÄïçÒÃÌ[²5ñ¨Îˆ)øÃàn+U\>äQ”¬vJqt„Îj¼LHn*šĞ³[ª¹ÿR,S@{+(ò‡rt@„R6G'æÀğ·Ç|Åœ•Ü!y*F¼pYx‡ÍÁÿUÌHDôÏ Øc‡)¡K¼Ğ1D(4v¡ÿ}fõĞª”Q–í`uÊäKpr—bÌ™íÆ­>}¤}Ğ›øzŸ_ìÜšÀ(ˆ|§şešÁŞ×²¼bFÖGdÛ“ªA˜ €Ç¡èÅ™ÆeéÒúÎÅñŠ8f ä±0ŒİÀe
\‘ lPhz]Sş»œ@©ÄNÚ6-Ù@€@GâCÆ¾ñØ	y¯´VE]@x¿İ‚¥eÑ,WïBùX$àûÂ²Ğ6µú`µ¡#ãáeº}:îù¼Í÷‹àPuzsa”°‚Ö«¾K<™x™W àc1·$ÎÕõV&CAô´Øşc
W_oeğwt>>ÿG}Ê3ãN“šUæani¾ô{&WÄuĞ¼€ë³T€Ÿ·ışbã7]éhu
«İ€Õ”û~²ÂWä•À /¸V\tT9Gºa%Øy*Ö3ŠPêÏ²ù¼ùÆÓ¨•”^™S:SA¾Œg,²î¢<ÿÁòã§WOÙìM€`ØtÆIª6Ä¸ûŞ9À—¯ED0‰±D§U‹Í*§åÿUÏ¤ÕP9„wv¬:±2kS†œ ívSvÜ“…÷—_¨^»ªPhŒ˜ƒÂ%eœ­°«™>Rtû&EÉ= ÁfğGŒï6Tõ­tŒ¾¡	ö©Æ /“öB(ë°dG¶0´ı¿îòøµ<Gf1—!ƒó1Â÷³U_®„¿OùŞıÏVY»AË¶V298ˆBî¯H›ãÒ|O$§#ù¼K°_Áwps·˜Ô¡|Ğê´Ü¬ô|ES]{¸©1:ó#¡ğ8ÊA‚¼;èÈ©Õ¼ÿJÀ5ËßMòƒøüLLp®ít,œS;ÁZ8+(çir°-t·?–…Ğ¨9jä2muøZ`¢¡î©œ—ºB ms—„˜‰"
:ĞT>i„rİË¤.ÓâEÆÜtG /•Ğ¤†X¡åaVŞ¾İeØ	é!™ÖóÌaÔ8avõO<`ø­"ı”:²ö³ëG©¥±ÌGä\-İGÓLôöòËWRÄj:é£\@ŞÎ-"‹U\Ğva˜†÷Ï‚æo™mÿ c'®AgNG–õs¦ ö‘iÚ„9f™Ö8 Âvï>vG…}Åj Ü†ïb­­·íÉ‚·ƒºwäÄÉUSÓ K°õ1{ò
ÔÎßÒ†÷Zôò™mö²•…4aã—U~¾àª¨@ÿ{<ôìŠï º#0"
8{yã±CÙSË-:>ÆÜ*?Äı ìPÈ¡dŸ¿.F;ÚçñÁÙ{.Aˆµ¶–®ÍŒ‡`@	óĞ:€”÷!kùüfÓCK¢ß†q‚¬`³¦ˆêf#ÖQ×F½Y¤×iO¬İì$a{]kÍ†¦µ¯@U‡€§‹„¯¸ñÌª0fçÜì-qd#h·o€ôıÜjşË8\Mí²ƒÌËfIŒö÷LB–¾
|mGI÷H”VõÊëÙô ÛÎ½Ş¥S÷Ä8Ã®ÓËü™€9BçéP¼è×ÒJ¡=6I—àPPò<şÖ•Oü H\†­ TÔÜR=„ìyÅFÄP’m¿+ÃıOsømôå‘Çğ!i©açöñÃXó=ÜÅYë‚J ‚˜ÓF·yDqV™nZKÎóœ†àÅNşTOöŠ8j/­ß,á™2•#¼úE!/’˜JÊgA=âb‰UôìÑ*•<¾íFçr~P'Y)P]UÆÜğû!$ÜÏ²1M§Ûn{Ó‚ø)Ù°ú®Vî„>i}î¥‚¾ùe]–x%4Yo&²0á8ê±W ^NĞùÓü¡ĞB$áYöæ†•¾3{.úÄÿ‡ö©²Xvÿ-åa IàIgBB-·q‰v=ÕÿÿÛ+ #é+Ñ3"
ÆåÃbü·ï]ÊãFSåì?²‘j9Æ°4È:Ç +‘(xQ‰¬çã7¡%Œ\\õlÎ‡3ñ1t-è§~[¶¯Ú‚	çn	h¾ŒĞ`Y¤ƒñŠLÃHÓ:ÖYß€Ö­ÈU'–9TÏFk/‰U&ÀÁ„®ó”0Oöûpº…œè’ŒDNĞğ¯Õ›Á2¿]ªÕúîvó	İ#O™ğPw^~±æ›Â}+‹~"¼ş’ğî…[;ÅXËúpÚxğ"˜º
zQƒ»–g0Düß’8ƒ§Šö ,^8ö8­±P_iâómÂÊÇıYÜš{9^…â/B, Ó7*KÄgf¥>5‰İD¡D~GĞïÊÙ¢R\÷ÿ.ûŸ¬;Ë<BÃWÊ ^HB*0`ùá  ôğIöHª•}+Àsß$?¬%#{Ê¡6•œg¢-càÆ Â³b7p
å›1	È‹ŞÓ^|ÿÔËÃ<2.óŠ,À/êåş•&Kzœ Ë2Å?û)ßé»ÍzêŠ­MÛÊØ s·¹¦>ñáÌnO*°Ì©/m›l´~‹–3õâçôÚÛqM¢Ùì&BA£]V¾D:äqåİâğ_6š¡zĞÁQ*$èÁÄI½0ÅÛÔà¿JX-Ú§0ğ4ªFæw:Ç¼m®ÈƒÜ­XQG¬£Ê•”Ú¶*Löì¯îùÎ,‹P<N¶]vÎeOS+Z\¾WŸª˜7@ÖØ@„œv3ãR´–à­2>ô`m‰› z£Ô¥şÑ0ÃA´â±\'.;ñDË`š·Ş¢„*M—)ˆ¯W‘)JïwC¹îæ¿‡U»NÃ?õ)º£w1²e]Îô%|ZHw”_q@¥×ó´ørF±¡xè‡W˜æÿpªAÈh5òŞXÅœ2]3ÏÄÎZŒ½Ò«©•áõø]e˜)¦ğğæifØš½QœúâßÈxñ}Jã™ÁüèuÄGvçY G×Í4™ı?L|œfÒı7Ü°feŠı>íYXpÅ½ì!/ıÇ1	Ì¿ô	1o%ĞôŒŞRRàÑ=ÑøAıµ’‹m"^È	¬kQÚ2OèUº?W4vTôÒQú5ÑğW®Æ&#s¸¹ŸoW9µ#á11¥ÂvhanpÒÉaÚ©ªH[\Ë†ç„bÜo$€#ëÚ·¦ù?wš|
5Æ¼O`¡Zm	”ï#mêåëŞúknÃ—FİêÖXµM¨jò¿+ñÂëğjÃ7­s‡K@øçYµ¯FÇ¦¼-Á¼¢Ó/f…K{IB¸á&ò ÍjQÿ¹
{„±xc¶ô—“ş²_$añ‘êW¾R¼¹¹rí¦½Z¯¿ş`qŒãËSÑGÁ~.4A¦g„`Çã¼ŒRÊ×ß7˜‡ q”­¡µbaê‹åÜşsäî‰¿Å¸|kj:Œ EäØıªÅaµ®qpbøßI4K¾UQÉ¤a\a?f–P.Z»(N·^ ”‹¥kCy¤Ù³³ˆ|µ°©8¦¨Ÿ¦:LÃˆôÕxÏ
ÌÔå=~2Á£»Ö;/wº™ò¯ÔvÎÀŸıF»h©.‚\ÊÌñZÆØ.jÃp†¬ê;züHŠÕºÁNS_: Ñ ÿûìY˜#Ã9i°BÛ•6	,.%HÓg©àÌäÆ³•àÅÏ´ºúĞY`œa®V)Æô/&û•]wÛ_ö-˜Ê q† <T´záHˆXˆM«ù¸+›^È´¢şıò*Œí?o¶ğà…4tËâádrıw¸Ë¿§‡A~QÜ9ó'hm_XÉÿë)5ƒö8›MKQ+1àl–A:{\Œæ¥©8ò+]ÁŒÀp¢¥KEegãSHÁ®à©iC+c2IÖ8š`nbŠàp¾¿iòÇDïˆzDíS~l¬ô¨
-½™fl·çúÆİ"¿­Şi„§ûÁ Ën˜ìí£{vqŞK”÷dp»äÉ/d›Z|ˆ /‰|ÑŸêO0™ˆÜØ÷ºs 
ë:Í†âå\Oƒhá{\FÁ€3–ã¥ya·ln?((‡¯Óf•ËÌ.ºÂ¨¤b¾)¶ï0Ø®€’™şé›>×·Fu¾À6¬)A¼Á¯gÜ9áüH*íJÏ„ÊN-d¦(†UTzı«ÕpÖ·Åş?°Ual§M7†t¸8ÅQV=Âô‰àÅãvL.…ä>ò-gÊT.y7ÙÉEc€z^$2ÇuP`O†]¿S/Å¥~şb9†Aª…\§$ ½ÛlL”t‰†ò§¬k>3—¶=¤õ²kÈ-\!|}mô)x„m‹=Î­ÑÓıA¡Œ„°6ã»|2ìLQK·LÙ·«‡Â™oQÈ«ÑFğXöÉ·ã´ÏŞ‹Ÿ*Sû^¸3KµÃ«Hª¿ü-±^kÍCÙLíRÒM¹:&ŠÉ¥“ES1Î¾ÚsWÔßì3î­İWGjY†v0ÃÑŞ@¤.ò8_>ÿ!ğz°å{”Å«NZ”=ãgˆ¸Zô"Ñµ„ÒÚ“â¼L2t3dcj^‘°åV­EÈv…­CØ P¡
®`ŠóÖàš	Èê‚¿yAeÌÙòLíÍOW‡Oìó%¯»}îx:±ûn"˜Ç¸Wvˆ—á>îc¬‚Ÿ>øv~LëP·œšF<ò¦2_¬Œ?ŒÍr„¯s…o£Y]JÎ=Ü°ŒŸ—YõM\L‘™ö&eÄ¼şqÃ&KAµÀìæƒpXÎy­~8Ú!å>ı-%û{×ÍiÓ7ŠÆ×Ì°†VÌ·ü\AíØÌ÷Í”O±Æ¡)1aûò†ûbË¾=BïÏ×§gŞ0©×›n:|ÒçBûñ1Š\¹Øhš¹.DÿNaì?Á;ÁQbJø	”‚'9™ÜB‚k<Óª@pôÂŠf¦*“H~üMAÍ´\Ú†P5fTı´Ê8úÒÇzáQH&!H›ÖgªrÏq©ïñàc®€,:>w6¦ÜÙ<Õq$w¥v<‚>u({±üfû//Í7+?È™OõÂOkú#ì€'ó(ç[z×œ£¥K›¾¡dˆ^¯e/°˜.&ñ{ÚšŠÔJŞ'Ğzï¸ª¢Âş‰:K²eT	|åCíìÛXBÂ7³ÃI‹…ï¸Ó¡xŠpk²Ã?(xÿ«-Æ3ölCÑ-·7ÛËÀÚqEy½J,€Û°’6±Wrù¼œ–ñÒkA“‚÷[MN/ÿ˜TÓëÌ)V!(ÙT p‘Œˆş©ÜÆ£·Ø“BY¹ÓŠä•zÀßœ$4 ù„››±Üîc×2mÒcU­¯I#·ŒqrIí÷¡v]|V¦p’6gê<qG<.#Ïæœõsÿ¶S%¢?éš§Z®aß Ÿ9Í@‰ëÛËH)öÅw¼M„HØŸ²S${İÂ92ÜE–áßàK(;ik}÷‹“ù®® Geó%¥>LÛG½V’ ôåƒÛLÃï(ù	\Œğçè!=ÃB£€šãáyf¢İ­Öİœä…åpbtü…rk_Ç÷Ã–Û?ec?Y¦ge"7ãÊ7‹—Ñ€Ş‚[~‡öàZü®À;˜ñğU†tñ²íkn,!©
êÂ›w¢•RCh­h˜Zèh‘qÚS›µÀæÇ1ÇÎ²mæ=43³¼áç †ÈfÑ<!›f.Ş'#O‚r/õØ^SòNá,PYŠÒ}éÉJì/sxZ~Ñ9ó‚U`©è®¶8æ§ÁØúí«!šX'eó8oå÷DÚüà"îªµ¶Ô
˜ÂĞÔ[«jüa•ŒFÊåci²èLÉÅo+ULÆ‹´Å!/¢É^£pı3{Òw®çg»4ŒhÈEàä¬Ğ†PôXP›Ñ±´™¢ˆØŸÈA†möiêp0™h£"Ç/@×?5k¸wâ¸Ä@H+6®W”HIfÒW¬íµÉÛ\,W
!ªªõçÛˆ~øÉµz8şÆnèƒÄ‘ÎSz]}(Nweã±Ò»!>ÏZhV.8pÌá—Àc‡Z{/Îw†¤_á–9g÷t ZjÚÀÖ”<µÙ1éÏã PW
ÜsÉ¹İÚm8©|¶XÇIB¦²ı)‚ãuCª<"ˆw16ÿF¶+^€ÚMˆVîÂi@¼j‡÷§X©Îñ­Üğ÷,3Æh-,Ñ¼r¬¯Á‚{ ERƒN\yEé£øRn´½õ^¡Èh`±/+Ùô6°ªñaÂ‡œRƒ™.¸ròÎÑ'±>à§  “ÍQpF®ğ 	ÌLT!z¡E¯ä›j’Ïìl‚U6RSKÙ˜_óïÒÏ7®O4é<#Å0Zµ‹Æ>lëQŠ‚Sˆ•ŸAï(%–ØõlSĞ%ÃÓT[£ˆÊb-7GkééÇ@m ÷ßJ+@A÷¦B)â‡~m°rÈŠB÷Ïÿ)Y·mÙPĞ|pë|ä©M?µ°İ¬H¥Zgp»k{˜Û‡÷ß.?ÇiÂ}˜Uk |!6’ƒœK&tn–èÇ™˜ß‹ø7§m‹	Âly*vÌ©¹‡»=ÍN2‹¶2Š—Rq]ˆƒ9&?Ë ½µâæğÚ_Ûx–ÑÁüu0êÂ„´)¶Š” N`®¬hAã°ÓøLAx¿¢pVÇk¿ì¡Íh•ˆc"}[Ûn»ŸÁ‰Âfzço.>{ãª5‡˜1OYVÊÓsGS©UˆBÁ%”T–÷p‰‚,+ÄèĞŸvÂ¥{Í©wjFM=â‘Z^ÔlY¾‘'&
SÿÕ»Q¢m;`×`sÙşQKè°d<ÕWOÒâA+Ìäuv¡“Å–GAf’²+3ŒÈÚ&ïL‚¹+Ÿ±]|z*N`n›Ÿ°ğ‹•¡©6oòò©Î§âBgÙÂt¨OÓ¥Iİ€Û¤Óy¿;kKÈıq;­¼‡iêd¹?jÜ›vgâ`RÌ¥K…ãŠş'¹´ŞŞ^&ôDRˆ¦)V^0BŠ",û;ÌãfZ&—täQ‹ü½JÊKQ	œ¾î‡á²ƒí	q5ÓéÁñ£K3ã$ı³„yøàönej”æBk|E_„±‡5Ê·É.úŸ4îëf Kõ!7]ùªt¦ö0ÚoæS_ò§>;ü´=°·Ö7Át@$°Jj%¾KÈ"ß6×V˜}Ú%¨jFåò›È“'‹7µÁø[ÑÎõh°SB¨:‹uãT–ğè¶¦UdB­tq
 vcÁÖ …òµ¸’€ÔÕWâó(Ö¸V{$Å©Y†§JÅ2Ó«³ÁÔÉ$«#ÿ{j	‘òl#ªZQGGi™8K.W7.ı¥jöAâ=Jiz£Ü²Mv‘¯’¤Óºûà ràKÚ-.Ñàu\°@ïËƒ%ÅY«á’&ˆøŒÊ"y]ˆÄG0Ú:ê¶’6ø¿.®ôÙ†P)‡¸×ëYÔ¦Ãz>8¬æûŒ4^tc’ôè‘”–]–XúØå—-e"z™=’ØÓPpOØ0+‰¤½DöGX¿ÃjˆØF:,œ"ıÆR«±¦¼¥¨î¨cS¾Q=ê!è–û."õBæƒ!	1vóçQ‚íø§°HúUäÁ# —ì[‘11÷d«Â–@‹²3vóSSÖ'ó[>y]u\Ù'´?ªˆm7İíÏÍôòUq‰ÏÚ	6×šVjí¾=j6¤äŠ­Q“mr[?šdš•"üNdÖm)oq6!úŠºAß-?ÜI5=0Îçf:¸ïB)ĞP/!):î$¤¸E™t1Ë(pÙÏ&ınÅââ´WÒôzuïŞhc½¢üÊ›XÈ*;=ÂØa[pvÙÍOÎÁ”áˆjB)¥U§¤_Zş
e<… ­Ş@…á•aËŠl»Vë`ª“šòD¬dò¤‡€.tYğ5Z$ıáÅä†ïßg6©{9×ç£¡P¯tB<›¥$˜ü\z®¼÷Æ¢± dà-{Qª®·dr²vêAïO?3mÛb_%yç±b‰Êuˆî¾ÊŒúiò&­„®sıöÚ¦ìÍÿ]eŠ »ºóûûÓêÅ—n°İ¬æ£­ş»´Uñ†™÷ÃËš|JBƒM	xı6ò:z±BUªåø¨B¬IÊ@O®wşO$C(Uò¿ò	%ëeÕ½€÷3rìpíÈ¿ÈŸrÕáÖÇV®xS–bZJzA¬…eï -1˜õ)´ü¼âÆyêozV³µº*¢í¾üíƒÉâ¨Øß±éÔîf3·ıD;Àä¯uR3¶]jÙn›ã²rñ}
Kí™P
v»âR_F¡ ‘Ef9ññ¦×“KmÍ‘ƒËl²’S×dÏ—†QY{0&lŒ6"şå ôL¸6£;Ş¯94ÇÈ$4,ŒÑYª†=¤|2¹ôdfo)„‹ mÎGw3»Ihˆ}¢»ôlRH-X'ÀBVcSéıyé0ÍFZù* p©DŞdo‘èßtß[+&ìQŒĞÕXo~­rZeİ	[8T++}O~İŒïXÛ{DüG""ènØvzŸñ¿Ø\Ø7~Báßcıì)Uñy»˜òwñsnÔ¨¶zˆN«å÷kW¡²q€uXµáQJÄp‚›G˜>lã­¬ƒDÂUU‹rĞ™sGHm6£­7nqvc2Ö’W›Æå#æ
Ï¢æB•´rVÒ¹UÇtË2§[5:¹üˆähÈ!À_‰¾ÍÇãA?NzÂŞ„f ¡ß8qÃMÅûóÕc!4pìnëÔPßSÁZu.²æËp]~İ—ÔŠ¿ğNzWÛh†íÑÏ‹´ÎL±r÷±%øˆ0X'B]Ş‹­M>ó%3b¯”…$W9ªEDÒŞ¾ŒëÌhzbÿ4vyvƒoåËx3R
8Ó4éË²×%ÉîÛ°ş9mŸ‘âè¾¤€­Œn×¦ƒ
4½úß/ø„Ë€õsº„I'T»»ÿ@{“
;@k~å ¯JP0näOŞš¢]Z¨ƒ$èÒ”"C÷¹âû–%=ïG=·zHùìÒ6~và:ãCbï1ôÊ½¥l•@-æÈÀY\.Dš¤» ‡ôø'â·±è |0ŞP 7ÎŸßzó^ŒŒü	=Q‡ænØÁw9ß0ëyµü½AÒ’ƒK@fú.*“BÆ	
ŒOÇÙyê=:OfFBaÅÎUâ$Úf©æ	°÷cAÉ“Œ–p–ıÈbË|I[Û»Pl¦#ùıîP“°èÕ ŒzIzØ€ÙÂö"‚õŠoî1à9ü qã ÿ~<‘µƒÄ½Ñ@Ès.½Ákü§ıHaµ€óí‘LòÉ"'ú“Ëm1‡‚Ãz@?KÿÉÃò­ß:)ñDP-|Ë0ê_ ÁYd Tü€Š\%Ïû¤5tQ}ï\±Mu9w‰®ªeÒ5WAzZõÅAÓD¥]¡ƒü®Ä@JÀ=±(è´oòë½¾ßE¤Êô„ÈÌ{v%²E¬]`•Û{Ën¡ÖŸÑ÷J?œ7š`¹,]–Êp·Œaw• yu‚Åƒµşf5¬òÜ÷6ÿ}%D òT_K3èyƒy/äÏ+ÌÏ^};%­Jß†(;¯Zßµ§IL¾\5—?"RP»LáL;GdãÊU˜XY/Daô™Y8jE2Óö§ò{ 0´h#€æŸ¦hqˆò»«Ä’AÙbBNzzŞéIjzHÖU^ËÔºcÖ*q õ³Í-ÄVA8¼³¯k'Ö¸ÊRr^ à¾$+9™üCOÙËÎ\˜3Øy|ş`WÏJ†Í"u•ÂÅGL¾ òMÓÉ,Æfî¦s‡Š‚QJã£˜‚ë£EªÏÍR-™¯)mL6øôU —ønÁƒ”ı–P¡1Iqšõœ’Œîp1#'uŒ:[fÙå¦‹Wo©ËÃ6H&{(ÿµº¤²œ©ÌËĞĞ¨I9ë-s¸³ÿ×}…SfÓáª©íÀæ¶&–ÑŠ=Å3]` ÀÓğA7Ï…hëßŞ!“Ì¡ù€eº©FŠá…Ïû!Öš¢nwƒh˜1„_Ëñè=dRC¡Œ§˜ãˆ~l“Æ!k”…®È˜º:^İ;»-¶…vn÷¡p.gã¬×0×Àóu”øŠú<ê)®7®´†ßÉUÒ‘ŞĞ3.”ÓMøôhCÔ’…•rr^õ<+B‚ö
n÷ï]:A=µA|†'ïı×š+qt"§6w]JJ4#ùÄEÍ§FÀ¾²2™FˆÊ¡‡¢A [è˜¶“›³Fwa¬Æ¦l'³¬]ŞM\òLÿ£öÁGìÁ¬Ôº~z±€Øì‹!«ñÊY˜m“”@^‡Q:5á—xèPÂ ÷X î	ºj”u~Gt²wÄÓ7^=.K°\‹Á ‰,;„Ç£îç¥'=î#M%©âÀ}~<Ó#Y47‘õ¾!ô«mLK8)Kü'!(£½‚6Lÿ¨;jÁ@çMä•÷D(sm}˜HTzr	Y.Õñ3ÅóûùNë<rZ\W˜jõè¼ø
Âpb‘xí+\=´Ë‰îŒ‘¿\Pã^#qy±w‚Úıl1ÙÉÎ•4_†æ5 ÷ÍGÙ5Xõ Ëv$¡Ö1ãQÿ fœä÷JÉbd÷9å(¼#şduĞĞVƒaè¦È×ñã~¾ÇBğÔoû›Nbp4áşš¶#JPø'Óş}ÑÇád¹õë1Š°i{s,EŒGàAB¶{¹q4Ë‹Ç]Îspª	¬HÏ–âú¸9Ñ–AÙ;6¸¾^zK°ÁµaÃè‰úI§`‘‹< ƒªy¡{ ãiDo5òfÒD·rk|btT™ó`¹ÄU:{Õá%;àVÉ‹x’*uH”ÊK„QµM›P¨Wjp‹n«R‚`YUİ­÷ˆÜ¡K^GSpV©w¯¼cÿÀZúŠµœÁÂ³cç‘'AMnÈ<-óséojÎänôàÀlw«äş¹-æŸäÏ€>ıÙ¾ĞÒÓÅq9ÎF}ˆÉ‡¬âz=-qı²ò÷%«étKT½ºj¢;ñ—nÑı‡!¨ëÒ2ç­¥¤ŒÜˆ$FŒ—ûB‹çóæ­<{]pàyNÔ¹·Ãx?Ä(ŒwE¸ÌÒ
İ›¬òüKõf–†ÙÚ5ÿ±ø÷eÖmÆnÒsùxƒTìĞÊ®Ê´<	ı™9 T|Ê&0-Ô&¹:hÈÓÙ°‡Ùg( ”[Ì<¸ Š0ÊŞá,f{ÚsÂ§ªk÷º§6ñK¼³%y³¼tó]Ôê2šÓcÌ>ş®]Ò.ş·*‰ôõAØ¦{Yõ’úF>Ò¦6RŸ0n?´bÇˆÔ!ëzaH‘#T…*³LÒ‚/&HªÈTíyb^J–ECNú¶ö&sÜ¥sİÇ¯)ªh›ñùJ?cdPLs6thŠÀJtŠ&ªšaCoÃÛ}Dï;qÅo.`É<`ş™r:”é ¥gë– N?Šk›@ã¼"h(ãEöølfN5s_+‘¶ÕK3	ˆW7g‹:`$|É}ÔÜ9ÑŒ2QO`£.YÇ›½ÙÄ—æ~”à¹ŠèÆ‹;A]hB†Ìß8<ß«N³i1Ş¾bã.»}+9A¢‘Ö¿iÃçôºŠ|Ü*ùıİ¥<ŸQÎ#ÅzŸñ /àWëÔßx6üCĞfßWÙÚøcÑ›Z­¤»mœ}µˆdÍR`%O
¿c·9Ó¼šƒB 8†àóOì²ç¡ëA…)I‘˜KEÕôšÊE8³ä™+)ÒD–û·¯•]C>Ìğ´¶Óv¨uÕË&T>ò
Jzl]}9ÒEv0ä-óAåÄü–:6µ\“—+âMæÚóáy'¾Õ@)áxíxBüé.ÿ ãù´vF¸×Z:x5Wš@¡8T}Ëûéi°Ådíz…p`Óœ¤´-’h!•CÛ¿‰µö•aiúW$æAkÃÜsêğ@Û2ñWö@'v<ŸĞ£¡wÜŒË™¡ÑáR-›tŞl4Ûò9wXrMûÌ®=OÏÄk,”®î¸xOÂñ·h2ŒB&ÿcJ©î&^ŸÖôvQ­õ[UµÎ…¦³¶ˆ9¸à<ñÚ$şˆËÌ*¿ŸOIqe:bŞ'†¢oU¡Ú‚¡ì;xÅ±æ¾ÊxÕ¾İ°}b¸_	®“õîªÜ£WÃH¯ò©2†¸Y¿¢,n)‚HEÒ%‘Ä;ì&t:÷9QjWùNf¤İ ÄÏƒîé	Ôl¼µq  ekñ€íşlÕ4¥ Hşş¶b/[ñÙj£¿v±…¦¬"Õí“‚)»Ë;š‰ Ñ²¢2b|µÄqyÔ	PşØQY XiùÉeÏŸ}–_2Ë…ß;fyEºªvëÎ_{vî9×"øh‰ÜZ¨1½NQqÅ¾LP­!Ø<Ö«¾´9Fn
¶dÔWÒ9 R`}MbJhtØ±šF;Bõ¨/Ú*jF~W2-¿¡Î³&Ìr—¸nš’$å½ìº(.ËyY÷Õ
7@“Æ(°Zƒú§+ÙıŞŞ¢«kLxW|v€+@–İáfÊGòÉSK­óiö	æü3‚iİ¿U8NF:hÍiç†¶hì87ÊVÒ P ÿÅ[¥Ş"ı|6>ö~*¤ªûáš¹“»i€æ¹¶ÛÄÊ<R‚+èŠóŸ>Ë0gÃÙ3°c”±YHà×—hˆJ+ŠZ|J#ä~>v•v[H®‹]h=Vrp¡@ı”&)±©1 ùÚE+o	F×o'ºşq¯)‚ÓŠQRø‚¦«‘ÑMMyf¾”œ¹@“HVë›½3ğ6cÜ±oAêÊ–s°×ªLL}7<ktË«~Hv0)oó°×üÿjËU²7:ï¥²¸P4g\¦ÇÔ+vg¬
4N]ºëdæÖŠß…RáÈ]BQè£«D®óäµCŸÄ¯ kJò*Z’aë*¶Ø)O|ë¸¡|åGÈ›ˆIûÅ`ZØµĞ‰{ëd!¼hè’üJCVÕâ,0E}iº§Dûs›!(0NQÄARjdÃG[2ÍÙ],†I~Sw3ğÖT´ İM/5£…S[IéxÙÿ{ÉÄ¯ŒçíçµÌå!È,—jeƒ‚Ğş"xóp+—ŸLP€¦*z[ÙÔü!ê k,|³ypƒæÈ™6Ò¹"¿/ö¿ø+‰X©¿R£Á@d)º$v m8¾Gã6Í=,Bÿ=^6N7İ© UwYc§øñt»‘C~¼!Wlv‚¿ª“^êœãæÉ©e¹)”BE³`øÍŒÎé>Q¬ı4”I¸±)¦1¡,ånO=fÄ	ºxrû.ôŸ=wx°LN?ì@-êÒúÇVğ¯ĞŞ¨ñÁš…öÁ%ÍkMø™Aò¬ìİA©Lk‹jD(/?Ùñnø\i€B8´*,¡r¦C~?5ì‚î¶s 	ùIã˜«¿Yå³üì(ŞûÂëo0 IúwmG¨ëü}Ù†ZÈ«\é‰v@œLŞ9À] §öZlû¶	(ı©:Êñd¡ï2i»ÚŒÉpAxAD+½i×õæÄøp6__W×»¾ó+N¸š<éµµo‘¨ÊÀ#£ö„]"ª²5s¨ä0ˆUˆd¢Ğ,ŒtûCLAÁ©’­3ÌüÏ˜ok×±ÌIšX3gÜGUx„n]~T“ -'4ˆ’§TxŞCEB¿ğd,ü4Í|•—+WU×™¦AhL|Àİ¯ìœxN½ã¼“ 3>bë:¤Ö:ÉİgÂ2ï–¯ £rÇğ
<—N™jä£Ù7 /ä°Dû2×#6>]%ÏëÌVÿ¤€.LM‹° \yv»ÖQ‘[ÙzjúKüWÀ"Ş@à"ˆÔ²É4ÕX<8•8Ø¸§•¯)çõ+”0ï]Æ=ø,¸ªJAÜ®ş	°$:f=n_íìâ`Ç"vjy…Œ—¢ÁiW0ıô-à0vR² ,ÔnŸÆ”‰¹Ë?š±¦!&x¼;[Ÿv r´ï/,—ÂA>5÷Í¬vÿßéêÉQB/ šsöFf°}êßR§Û˜âzŒ|2Iì3·c1ü=ĞLnXD¦`@İĞŒéàák0cXª«š²Ù›S
„>W^ú­2u+ë1—t+±OÉ¿ºÍÏÏ1ˆ³¼bv0wy3—uÙ•ÃëÄâ6W£BÃ‡L|•Ï<³ƒ°¶lw°ÙÑÿ”€şšÕü;ü­míd¢š}«àS0é,ÎmË‚˜¶GjÛU€jçÎİM´îY,@†±·ŞÇGïE–±¥A[‡ÙŠ~5>{I°U0b}< …¥mO~À:FŠ²ÔñÜ’.jÚ_£–%z×’_îR}Âjÿ^"ƒÁ :¥ÖÕÏÁ½-¼ n[ò¬ğŠS9Òé´Œ­r_c•k}1š²À;l(fÛaÔn³Ü¾oÜ¦ŠıLï‰úU[ÙzˆùsƒçFÌb¤§%¬À­ÀˆœÓÔ{…cFª’‰5¼ÉS÷XüŠ`kÆ—ÉçLş;d³“Á„yäƒL>IVŒ]û]°8«e]Ç°ßÙ’¡¶Œn?vêÂhE‡¥ês?©ùêİp$2úoo}PéëÚøE€3ñºò¯Û›e3cÈkF;QnT„N‚¶¡ş÷}Ñ÷¬—Tåšø3^M~Û"Ô‡m(×+ÉDîAÉÒÁ¿šWZ¼J.jˆÉ«V>
Â>[uØ§Á*$ZÔYÛUaN•?¸Ù€8¥<7Ÿ"ª•ÆÔıÿ½CÎíPX¤wè—¼’Ô‡2p´²¹îß¥‰7åA›ê_[áE9bŞ•N†mã¡äf@*˜6[¦ûÕ÷ÆÿÛÚòOcæ¥§UĞ9“bÚ±Wû*;¥«<ÛPfè!cOÒÍbˆOjl|Ÿ‡¯şT|İ;™$À®­x,iAZ i ¡Š4çğùLC‘«Z.Àòè4›pFşZÎAŒr„ä:’Ìt†h‹Ê\°…ş9ğ˜·u»¯¦K*àUßUğñLºxì}¸QŞx€gã?\=»a,‚YÄé…ØÙóT×á¬;6üSkÊJ‰{ –`t#ŒìİFñ—»DÚ(ŠæPnï°™ië¹ãV…Bò>§í¥¶¼Iºc–Ö%fO ]ş±ê©æx™ùD!×]`ØèX|Am°wÛØµÓÅ  ó—„Î:™È{ğB` ’V&,UİaÈ–yÙ¾gëoHp°Á}¸xªpÕS‰àÛŸ÷64Qı	kÁWf3öB‘0kÙUåÄmî]ë•¹EùBzÚ‘Ñ
:çÎj–b8¥ú°€¦=¨kˆ0Í¼Ø8¨LHb£†¹äiï„u„ä;®Íø*•.f{8l5³™Í-<ÇÁóÙVô9ŞbÅÊgfõ\ùh²9­kÿj-™C-v_ˆ¨Ï§n§O;H<ÿ§âò·ûztxæ-xıä¢ïÔsÄƒÂñ0œ…áâäÙ¹hÒ˜<»ûãÑÉš„ëbşÆ
y°Ú}‚\Y¸|èf‹Êó‚Ä]dé|töFú! °À—·ìqfg9,(õ;!&´Ò5PQ::¯§Áú<êBuôñ Q{¯R€i‘ëÌğÆ“®sæ"07´µoNÓoˆÙ;a›%ÂL)ïá^#v[,ø§†ºêSŞGu¡óvø×-Ù îvd›˜I†Ä>ÏrıVå
Ûğ…õÎQ‚‹[aÿJ®„+×ÃË èòIfDÕR0üŸ1oì½.à‘“†‘ÀÚ:õşr$4Z‹´-Ø âŒÄY® ş‹¸¤-9ıÙ—Ûiß-ñ~’Õ½#•ñ›+aŞ–ûµÏäûF»í€“ò8©H¬¥“m¤qJúÌP>w'F“*/W<to›İîÄ,t1§œ°Ù•ha›³İ[”<áM¬+0ÔOÊ¸Qo–2îĞÆd„¨h’æ±–æœlèÒdºÜ<ï¯£:J™ª¥I£÷ÚÓÖxŒeÜ¼3P›Ùô{Şoã2ĞËmsˆëcÓÅÒ¯òliLp£e‘Œw±9#7WsÏºŠSÉZG·(¶‰û¦¸I>q{öé›x¾€7¯Š³éØ
y'èŞ‘İşEJ¼”HŠ¿œ¦€Ñ¸rì8I!¨$|‡¯V.ÈËT	¸×ïõ‰«å8•÷o÷h¾I‚\¬áÔï›ÁÁ «½¸‰ææ+‚çmwç©Ù£Ëqß‰O]GY¢2'»ök¾s	ª½‚5Ÿ
ê¬ÄeqÅ¶G äN'şsm™Á’kão5÷ŞéL¿<Ã«T"(¼«F¾ =Gµ˜(t¤¿Ç¢´T2¯
åAO¶¶p»rº'lb¨h¯µt‰*ûès“JğÏ ³‡÷£Ù3œ²‰BøÑt$IŸÃKüW¦ø‡ f>˜Çštîmd2í³)ÓAFÅP%‡ }dºÍ
15 „|ˆ-ŸDàÆ—Ó‡]MJ7¯—îp©4b"­=ÌK<´#úIšv‡©./“’ç{ÌaîB=S©üĞJV¹ãåÈÅ<ûí©`ŸZ­säH†:åL·<·aMõ
ßISZN•îlšuÆœœ¦ˆ®0zF±ÇNíxvÑF¸2=a!r½$âH‡FnUœö@´ém`'O\V“{A—À&÷ù£wÄÃŒn >»•äØ_ÉO3‘%¡E‡¶a¦œ%ztCæ¼1ğëÇë]äåÚi{ä_¡‚“4˜²‘¸ò·j}Ùæº¡iU‰ÇvºÉåD"¥¢enªv‘õµtáB¡?õ:pb‡…L7QùQ©:+*bmÏàöo¥Ö‡…ÈòèvT(\kú5Á)…2ºš6‡"à†dút‰`“ÕÉr½|>Z[/“‘4Êµí
[ó¾qy‚=-‡Dı)Rëda*pôGG–!péÊ{ğÙçŒÃòç(û%|&2o›ù'>¸óÖ’—˜&ÎËÏ	¼¿„;Ô5A¤Üüƒ'c¥*¡z8Dš¡ÄXdØ¶	İYç<TÓ^7[%…SØ´˜Çôi•ŞÑp˜k>hÒ]*GƒPˆ»f‚Cˆ'Æ°YÛó\9÷¡ŞÃ— J'ï™¾«£zA²W5E:Qñô4,ã5ç„K/¨;ü™PªÊ3ÏÊsšaİ¨ğó:MËš÷7ƒ’Vıô	|'&•W¯`ÀÀ2çuQØ£±@øó?ÔZ|¥4£J¸Ú±o[ÀI¦ÿM|ªE”b¾ÃÎõ^¶¡GJì·NñZ9Pæ	—ø„Û•<êx%-IL@j,I´Ğš3àâvSÃ­gÄjâÃ^w°;æ« Aj2¾Ÿ‘!·øĞˆc@‡Ë´ˆûm­Ğ;s?t¦½Ù§1Ÿ3qxâ\Q¨Ój&|urf5_ÕÒnš±ùµ÷U¥ùr®a(Ş“Â–ß<0•¹_Lcììğşì^#àõ8îÆi«ğú'öw¯_¿Õ;°KùïÂ¥¿<#!Í¯J´º(¡*Î¾¤ß|¥éñ¾æ8k¼'§S~$8¤×èèl2ÆWc0ŠJö(,2üÇ>‰5õ@¥Ù­$qËGºuÌABzí‹ÀuO[C»ì^ÕÊßG–0Jˆë²ğƒóë”</é­zâÚ`°¶Šó:QIºgcfôTµ†¾Í}gØ»–ÓÄÌ­ä‚$á8ß¼æ ËRÙ?‹ !¦)ãœy$%6ÏTÿj:Û–KBQ?ïq²Î"é-7#P””oy—äa¾02¥aå“{Be{Íù4Å7¢Å’[há
0çdí_˜®ÙûU±z[õ{Ø’ÏÍğbetÖ…¦¥qÏAIİs	£nç}#›âb2ØX³ğŒzîˆèÒÇ¥ÓŞÙŞLÙş$˜šìóÛzá4¥¯sëË˜ûJÃœçÓ‹-c®Gì
H–ı&w¢j|ü‘¯uJ‰tñ#£¸ÁÔ‹÷º¾ˆH…†0†ãœ/F]É‚Ê']’"¡–ÇƒàidIƒn31™R¯•Ç’§~%&)òC¤û„Ñ.z”hyf–ÀD£”´ÎğF*}KÆ>2¤˜³ª•b°!Ü3™Q 5G€^¥{áœMî}(ˆ8›SœcŠBƒt¥¹ŞÓˆx ‘G?.eü,é\Ş\§5Í\m(Y¢ôn$¶3@›ëSDC(\PƒCšz²üì¶ËqÍ‘m>âBô•.´ø{Îª¿GP‚¢ˆÀˆ[_PpCèPuˆöo;Ef[XNÒŸCjĞ‚²'ù¢}†Q‘¶+÷ª},Â:œ4È(QœàúRßÿáaÌj8Iì³ÂÊÓW¦d
RùÇE';ÚzØ JégçÏNÑæHo~¯á˜%áİIBA–s„šşÆ}2†d)‰Oç¡6Ò\A™¬¶‘«?3QÑkvBÜäf¿Œ¬àÖ®˜±YŠ8Å«%§ú;<t£UÔ3'h{.ÛO/WŸ«]Ğ%÷êe—ÙÑ/:/fşêSëe=Y-²L•åHÌ›,39å¢z^ß¥‹€_¤»lğE Lv.Ÿg$à ÚˆÓÑ˜¶şwäîï[ ~{ìü~NSa°Pcã•\§·“zå8SrÎ‹¶ÕÉŒ¸_0’¼QÆÕTAÛa/$˜ —(|¾w¤1‰}"Ó¹fŞ*“PËqÍÕÊ;dG¼Õ=W.ßsñÚt
[µ,J¾+½Q¦d-DIW>Éì–Mâ³à‘‹f|äí‡ÈÔúY¨Ÿ.Ñ¸™üªËıí:ûÛÀÍù½¹J,*Ù¢Z’éã"Ê·Ñ6LÊw§¥‚\µ¤ÌÓ¤×U‚¯w›ÇD6Nù<ˆ6CÂ@Yì?<9àÅ(º“Š¸@¬ÿ#ÓUXÖ6ÌSã6 cg®ÁÙ”„{Õˆ2÷K¨÷ŒC‡{}ƒ€ƒì Ší7vºZ_«ò2)d8Õ%ñëÏhÓ6ÎsxÎúkÖŞv$å§]4”ŸF4mğˆ384ˆ
Î¶uº 36}na®!¼Òİ¼Œ5~ŸÙO‘Ò°_ìIÎ ¤´Q³½„K´_
,w<e4GSù0tD5ôìÅF}èäã´ÀŸºİ˜MŒ¸ßÖLùş›¢Øyú•x¡\QÈñÉ¬îÖ¤)­jœQK'u®TìãCÖ@X?¿eÓB–cıÔïİ e>l0j[Á‚¶Jˆ©²Ÿ®¨)”NáÇË®¬‘7áAÔ’ê./`åÉ3³‡!mX%Ğ«šìÃÍ¢ÙN2‰
h!cƒCNÜô÷sÊÑ  è»[Á#u üÀ€ÀlÛD±Ägû    YZ