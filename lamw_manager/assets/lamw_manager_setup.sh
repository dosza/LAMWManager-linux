#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1797198962"
MD5="d0239848d06c560b40cd60a934ae0b55"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="24168"
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
	echo Date of packaging: Tue Oct 26 00:01:39 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ^(] ¼}•À1Dd]‡Á›PætİDõ¿S «©×ÔÄ!°®ç  «Šv\Û»˜²•EşcqÕÔ×‚Œé“)—Bœk5LÙ{Ş,9*ĞÑ)Ü›8İÍÁ°(¹,£Ê p‰İ˜läOJéÊj pÃ
%"ïO!eäà|¬C,ë í£çh’Ú†“D¿€¾ZÖ3aÄ££É#{TŸ@å-F¨S[‹,²<<:ä>œ›ÏàÛ9ÀKOİÕ…‘q(Ò¯øœeCïth´‚ô¸R,pLüx9¥rçó(±¿†¸ZoÅGepaÔX‹Ù`¿Ö Óz6Òíıº&&‘+‚u¸÷ëj,|nÖâaEö!4l«5°lûD¦­«.vGaÇUˆûÎ‡¢ôâ!h&+5¸˜²sˆù2¡	éJûÊˆÖù1Td¾Û×§³k©‚—¿¶â(w¶TE~%¸1& ®øÍT şóQ@Ÿ4ì˜»¸ã¾ğ›¶jóì¤5p´¼¦€C¤B.¡°ƒVï$ªf-¸ûGc´ŠëTno4fö1Zq&ç[Ÿ|kÊİª~\³œò˜)¸¨|c
}ÇÌ™y¡‹¤5Úì ­¯¶×SûÇ§¯,4 gp~.åâh³'4IşKÓ¨é7âôMörö ôæ=‰ç/Í+,Ş@¬²‘s&¾#Cgí}ÿ+É¼ÊyZKË6 a†£ƒˆ`>RtËøìe+ÌİNyÍ¬ä¦†§zéTj]‘•*ÿÂSÌh‹}¢5^gÒ#-ñ­,ûğ@8L%3²t^€œ˜FªtœeÜ‹CBJ)pË~™d>‚üÄò¥yÀ±¥ÚÕk£Fş
kidã	÷hzS]/9‡ªı)üTöÉµnwZ¾öé9äÇÑÉ]îeT÷	á"?Ò“ôÅĞ»zĞ÷İgXj9Ò“Ö j–g­ú5‰Ãª¦ü–à…)ßÅ`g„ú„•Ò` ‘ZAÙ1……z_.ç¢	Äx•Ùª^YØ”È?¾—ªC¢í•3âà|
ıÅs2²ÊxlQƒ=—ï}ÃTüì¶2s›r"`ÆåÅ¤qù0?/X
é Q,'Äº!Ÿ>
½ªó>È‡º{|lëÈüûVşÜµEñ &™À‘æ»}­l•Ê¦ıtÉauZB¾á¦ ŞØ4æR±!ræUÕSuw »6½ë»#IÊ{ØÒ°Ù¹IhF£òã_ì‰YĞQ[)j—ŠZ‘ny-æªRÜä
õ×¿-{L´ö`¥ÚÉ¸J¦ÖÉv2¬‰)I&3ò?[È_d|j¸‹¯ù®Ê¡òş‰rû·nûâ}VbìÓÇ#öÉ‹ÊÓ®ó™Ú›\şñ‹:¿±KhªFª¾Î"B¿´“kŠ ƒ7}PÃƒçj¯ŠØ@‹z’½¬@‰·U—Z~Ä;:Õc*i‚@…×XMÊ×¹™{ƒ•‚]iÎñª"8²Á]1'yİƒ£"ÅêX5ßü hyg8'
Ò&&éhJW¼Mw‹™hRºÒô¾Sä¬ĞTU.\]±•´~2Â·Íæ/ùÅjùÙìzHt‚+ šWùmÃ\ÈRX)1XşÊUÈ&$õŒ§ü.êÚÈbvNcÂªrÅ'Qfê|¿$­¦Hy¦0=- dÚApQ’‰÷q-OŠjûÀÜ·˜éaei’†*Q,fûÄ²Væˆ„Ùœ~…6¹¦ÌŞ.ø@W¥EßT»jà­ïEÏ"Ÿ˜rhè_‹°5ª“øŒ?ÈlA¦¡mØTÇ?Å÷%"¸œ_ƒPq6|TŞÄt…LI^è¥ÍTdèsDğí>…fU‰®:Uç_ı’…°¢>0\3Pô¶ş®ÕŒ1 CuÒl$!qf–V¼‚5˜E0§æd•¡Â“¶××œÈª†]ÓfñòıŸòb)gpä÷rõ¢íËƒN:ªå+f›&.‰› w	šYæ}®»´bğÊ%³€"±`ì3sŸ>ü·²÷
Õg)âŞ(w|ÿB &ÆÙiÂşÙÜeLèĞØkÉˆÄ0?ûx¶0„> –‹ü:öÕ¬på=X{şL»Ÿôèm>hø^îRh¬ëc u@™¶ñçğG~ Ø+éU‘­0Ïmb.9k€1Ï2¾«äï‰‚œì.L
¤‘DtÛÓB^KW4Iõã[˜OŸ­#­Op$ÚNj»¶ôˆÏä âg2\ê$°,–Åóµí#ü3Ï¯ÕzN>& ûPQY}şz™ån«ƒÈD£<Q$|”÷^«î$Gqk; Q©\,§©c˜MGK²Òìe€Ó•à=áĞZÈ/}ğy4>Œ‰¡‰ô~„"Üó-€Aã«£Øõ5¬¨Ôw¼ñ7ná¦Í‰tª‹ïJù6Ä¦Ûæ°Ô<¨@Î®è³nQ3Ñº„¥U5j~˜qû­J¡·"×á}wÑÜtºA5¥Äø06ñf\aæZdá¼ÊÓBµãRùÊıó%ı6AÊüŸ¶®Ô‡iöæ\Êì~b–£âWÃyl>Ê›Vzı(ò,Âµ}ÍQYÏ„ıìûfÒO:»¾¼Úˆşø¯›İÓÕI¦œ»Kd3C­e
HÆ¾ĞôåÀzPûŠ{Ì(&—š‰qÁD>‚em–§KıÛ8âåÙ\WÙ·Yú¶Od¦É]ıCa
,;iX×ö$˜W•àŠÙ÷CÁ¦dQxoO	7¼„%#ZÈ€Œ’tø"#ºøäøAU-À™ˆ#å+yZû¦æPFÓGoD„üí… ¥÷›ddÒÙí­ÿ„—-x(³ë¾ZrÒN²6¶Tt@µœŠ$Ó.ü«iÈVrô-ı©§ı(˜nkLzL|}§{\Ğ;
ÿ
â»+{¢Ú¬ÿ®KRğ>ãN]uMÛÔ¯¥‰}`@ŒàxöÛ±Ş/2nÍıŠ=Ër‰&xĞâ/óœz~å[2!¬ELDòÿÔH’³J."Ü¡É–½%fiJ³À™jaT¨¼/Õ‡cçôEÓDp–k÷ß%W¨ì™½s{²²8S‚›B+á_«­á*zè‘:p»X&"mg¦Ér{õ¢†	Êpû2—²Qg˜¤	oÈO¹«Û_;ğ6àœÁÍ>zJdiQ;YMxiPh!W¢B	.ãb‡$Àªä3„L)ê‚àDâåä(DWĞƒİO2ßğ>?!Qäƒ6ÓåÂŞ–Ö(ã,Ö²DïœßE¾—ˆ?“˜¡ap>Dn¸®Õˆ©UÊW†6¤ÇÆhP°$€MëE$ømĞââZüö¶¤ˆUIOtL2ìV¸e{S =Û^_6¶2äéô5as¼ïkòÉ˜y§"+Ù)ŸªÔóîÓ:ğ7@d)t¬ØĞM”ò®[N“ş4y$¢Ù»5%¡Öøş,BçcšæˆëÄÍedyPˆòP»V.“hSõ¿mŞtÂ  á§M¨yÀ$T¢å°^D¾2eåûå—YLNóbeémt·‹ù[Á{ô~á‡\:ùJæf(¼rf¬¡Alê\BİÚIŠ"Iíg‚<‹ß–Ôu¶%ÙM¸dÙïßJ	çûTf}À¬_Iğ˜Lûµç9Ze6*jØ@#}i…BÕõuéFf)¸Ì1åXVLüS÷Â”,ZÂl¨Ç
ŠO'« ÍŠ¼² ³‚l§õ¼QŞ1C´hã‚df¨Í÷µ;™Äqhİ]$K	åç<m)-nÓØÿÇ!E”ò¯ˆ¶h'iÖœ‹ÈbëiRO]ıùEÖåÚ­T:!ÅÆEç DÓñ¦š‚¢ÈÎ+YÆ‡WB)öÅÒí‚o;yÉdŞ•÷‘j×_Úx97¦Bk˜xg‡µ±F$+—ÃRğEeu9‰"lWıZÙZÂˆ´ ¬!q°Õ™ís{vq£F\
SÍ²j±8’A5}o‰ğVDË}¶Ân¢ÔTOğ™¬PZ1À"B¥'<Ä©ÿœ—#åöùE7°k3Ö9mÚ±òA+½ø)QÊ­†¹Ê©MYåª¤$>9­‚‹œ°Avö®pCDRoÂªˆ›Óröl³	t£É¹J†%n*ÈbÄyÛ†–Úw6ıG	‰yêŞ°.¿Ë*)?í#ÊıÚ	3=õæy:ªo»ê«X[¬3G ©IT[Çé^Mû<¸o‰ŒR…”ˆ}£1ğå×D¹–nªN„‹
	¿èbß-ÊúVñ¸ğTF}Üâ,T¾¢Éw¾}¸¦T·ÇqØìÊÏ½bX`òÍ-½P<ßÍÕFHÑ¹òü‡¾Sa¸™z…ZJè(ĞĞØÜœ;
êY[FöşAKVº†àŸÂ¦"xÑ=CXÄû¶£ŠOR«…ÆI³A¡[¸‘Œ/6V~‚Àı	Œ_DâÆtr>Šñ#7ìˆ¬şG©(^y¾v1w´±†ßâÙ
Û¨Ê£É¹’×µçO4>ïí<,âljSa4ìÈDñŞ@¨ )›İ©å‚‹½íAæ;×•²Ô³· ÂÃîgS”ßœ)CĞÈqïÅçÛ›Ñ :t»şïû:\%í‘‹6ªÏ.‡áLpi‚5±/Ê©( nQ/wW.t¼5Ì¼Ô99ÈÒ¨0ã”|œÆ«"µWu$ÿœ?‚Ò)^¬Úö–pK±À6ÅÏ,Ï ‚ôïã%'ö”·ı)Õ	'`XCKÅJ<ZÑîØĞKÜ7mÓ”îI)‚ã¼‹Í·‘‰6XCûıÍİzÉ¤lJÛI7Cƒkûî¾xÔV|'/“Üß©Qú‡u(uqàğ­ã PnëŞ0w7Şb¹hùˆ/İby"Ö5 ¨Ä,šgÊ—ø$ÒjWäxa$EG"îX 5zÓÒôÓ¨.Qhİá÷5•‹Z7·{‚‚ë3jŠ–„:Ñ™»==d»tÒÀDà(zÍXÙ:cª¯üœX;ªƒ<˜e«¥ŞÚ"’»öY£ºÈb-…›Cû?o†d,â¢o—–ü<ÌH65Ñ½û¬
dNĞŒ_Z+;ÓBë‰°¨¶jÉõ„H´?åhı wC98C¾ö ÿvác™6	lLuÔdçß?ÙÎ=«½3r²Ôn«œ÷İ”)±9©	1pä©ÉõsòµïÚe¥^Í`X}»}0„×ÇÌ—}VC…K¦MárÿN¥èÿË]şJĞ"I4VşÇßtú.5È,¥§Ë­pMåÓ\
§¦±K¨w“KT˜>1ª×5¡iôûÜÏB“Sâ”Pç"iTœxlÍF®MÌšÊ—e<“>”ÜU©s#HOßfE¡^GŒÿ–ç^TûÌçû•¸råaåŸF©êš1Ûã©_­ğù^)À¬„T²º©ß4ô¢º1Øã€¢îxDCÔ7µö;$Ù.iıo¥<ÿTuá NæoV†R³…V­x;Kÿ=†7@æüe[”ä-]Õ£ş 6ÓÔ£·†¶ì³ätÀ¢ùòbÈ“: ˆ­0?[Ù¹¦¢=®2´†”u“½àaë~_2¤c¤˜^Ç½»S7i™‰Ë¬“šÑÈ˜r²ƒ®âJ9‚'¼;àwë4š#Tï´"Ç	&èjCh*4WD
Ö¶p§-r¯;ÌˆÕ1MæÈ3üb6X.ŞGß §ë(=s^ÁŞ§ò:CÌ­5u)@uœwß>g¨®GXlæX±[	Ëç½Ã4@ll÷°ÛÄÁ+7R\¤ª»Ã‚.31I…í˜Gí!ÕÀq³ŠÓt«âhG<éû
Ï¿ÂÊ6LrEµ¸ ÂàãƒQ4ºôÃ¿2HuD<:!±®Pµ3#7Ê§qX¡õÜ]5şfé¸Mş)_IÖ½ßÁ™Gs™@Ü 
òU@¾Ï¹§Ô“>Ù€L ÀãÚ\4€è4ËÇ9!­<7«µã§HY ¸Š%éîßèæfŸ@
ËşNÇØ»Ó-i¤ğJhş$’pìbJÌIg‘X˜|ùr.[j+Ê]4å‡|@Ö@“+ı“¯ÃÏ5„(15cØ˜§F³ÈvÄîm2 Á—úÈNY7Ëôª3¦ÀÓíí§jÜ½»¢zU¦´ªóå?'À“}TÉQ\ç2€â¸¼·İß½ğAÑ™ãò¦97ÕiAf=Éë‚²ôæAŸõÕ\Ãew+tX´>Ân0epîÉ~ÊpØØh¬ŠµÃ`‘D2ñkşÊa;}q¸
wC¡¯‚ÀĞq8 LÏ‡¡ßXèùLä$BŒŞµå0»š.Œbe¬M¹íĞ\„€Wšƒ°õ˜Öu°Xû$QzQ­ÖM„#óÁ
ãK‰uIL¬ÂKËüzp:L†O¤RÒÒ·õeqØf5ê „Ã½`ÙºmkDgûğ{Ãv¾I‰/Œ’Õ{0GáDI¥Ã‘¢ãEQesİøê®ÈF‡Pa$ô&¯r‘×à;¦L_eÿĞ QVc*Á)å{é×i1·aY­˜Ÿğ*ÔrÖ¤‚a5¶@“Í	¹¼qâ—öÜa²ó´'|jâÖ»wÉ×¾Wbàõí³xìÈ÷$Ïv“ÅÊ´Xbç©X²å³•Ü2³x™¨¿÷nn—>Â€ûŒ$ªkT(¹"#?›ÍİËîx4EJıj;Â‹05–¡D×Ë-dù6’iÁtèšÿğE˜U¶cì™^ğÃıvÕTÄÑ›°Ä–Æe¦Ú__è"À]ño,şG5¹5Bc‰ô—M\ğKP„Hcp/|{æ–%cš++¢"M-úfæ IJwó]T:
=F…J·È¯a0‰,‘ı³¬‚Ær&ÚˆìëW1Çñ¬b[[âm‡@ZršÿC­õ&ZOË¯uGNu¥ÈMõ-o­{M"Kı=ÏJëcV0à­´ŞK÷*ş† —yL}(vºKë‰“5“éÎd¶	=ÈmB‘æÿT€b©<¬ÒïÊæ°Zä‘ ŠğÔæ¼q¾Éx¨óşJÑÆ9zósewq_ã”úí¥2BÄ¯ÊhmTË:HôÊüwŞ‰‚Ôƒ~3"­&b,Âr£”1îØ½9Yà7×åŠyhU¶hoªŸêÕEBYĞr? Ä€õDã”ö÷‚ä VKHÎı†¼ŒId‚Ç˜{¾-ãÔEÖì3¬oÇÏ¯†áÀ-úĞ!€ş5p¿ì`¹¨Ù$‚Ë{Š›x×º©øÄ–ZfZ¤Ò¿ğ8Ñ{1k%¥LÖû›„©£?ÏÓ·Fšı‹F°Kmš°]ŒAÙÌp&±‡­ˆ#Mír™´í@6İ˜–p"ºŸ¹‹ß6ä™¥È'‰KC^2a0ŒHM„'eo·_;‘_¨–»ƒ‘{bf$%NŞÏÍ•QK(®¾[y¢Ç´K[ÃCVA+4ª#2‰áóG×“"Ñ·Ü;˜¼ßw[¶¿5köpõ&7§xÌÎ)¬ïv[~Oã@[Äpê÷e6s ­ô¤à¿ ËE…cÊö§$-¡rs#i6‡ae›Á+ˆÎLŸFQ^á‡’L¸’İôzáYJ¥¸áH•s“ÿy·\ ›"UZ/
¼÷wŞª««¸¿OnÙã{?Xo‹ò;× ¶Fyë)Ë:P–?˜®I*ZTëä+),Ÿ„¢æ!èÉ_ÊûÒ$Ãëğhr*/!ŠÇá^Ré;:­¿¹ÏöYB6ŠuwRwpå"€º‹•±×’#lzÒç«'½Üw‚ö½y•S¹ìÌg‰ ï˜ÁC‘O€ae‚Ç0×O*»j;şÕÓùaË¦ú-B•¦î1Ã‘â¿ø}²= ³-ãLÇsÄj6İÿ‘m<ò9ûè!h¾’FA&db£ú)¬j¯.ªK”díÜi7ÎcÊ±BÑ.´  ğ¡Ü¨„[Ö¼êÌş*ã°òÇ´[Ş²Œ."	VVêªzó>”¯=4W&Ù¡ÅîFÎ”è‰o'Øœáè]®²ìcÏ]ûîÙ7bšò¤ø@Niá†$SJ¿‡„ÆNúh¾<t·š•„0B³Éá¤Ñ,	_~+Õı;7›±ì-†)P¶ä‚§“Abvç€–t³Ò¸şÍĞñ{ø¹Âù†@‘l·AÂ‹‰SIrëîùi¥]u&¿\Ûyı)âFøGXm— ‰â8ûJ:»EğÅ†ÉUÍäŸ¬ °u¸‡vO!•C]àÚÔ’‡–5üGhHK8h½•üÕÂá]x¡pãğÕïÈ["Â±ÜÓ¥ö¬µ_²ã²”f'XÖa…C‹¼İÓK*Zzºc€fN@¼°Œmè‘iÄÃxåšï€ÃôùÍ—`ºÙ´ä2°9qóypßİêbø"h7ò¨¤Á-¥3H")
±]Ç˜l±ğ¯Šƒ"©îı4‹wŒ9Ë˜æONç4 Jö¹IÄÕæ1‘EDryöå:A¦ÈÑªoH*Ì”=„v³™MüÏ(¾”‰×’tÃë %zmTv¥ò¹×HƒP3ˆë³<âD3Œ‰mtnÍ	<5[ ØÅ#Î: û'šo§#(1ä7>uø•fvâ’7
(«Á,4ù[ıŠcG$ÑÓ*‰ÚOëÎúZ·…òùPraÛª*„®TØ>7Ši—mó3¶©v<)[’‚9x~É~fòèÅú:€$+éş:¾°>6D¢pyî²=Ò’oø¸ ÍŒZâ+mìÕ	tôH¼í´à'ò¡AÚfÂRÌµÃyŞk‘È½(Ïa
“D½–@°rXw¬Ô}0%0aëæÛ%àCæD]ØÆ~Ç»Ód”ÂˆxqíUm4KòÈØ¶I¯Ë’X´-!²®'v3‰ríèÍ­H[“¨¦¯¬Â…®…Î• Sxoº”âıw‘‡¥á¤Ìï3µ‚Sß®’ıZÛA LCB+´^œ0aifY’d–¦Ø…¸Â¾n¡€’-8ª·:]j[Àtúg‡	omLú85Cÿ6W­Èği›h¡³‰A;¤=îBEÚRˆá}q2”ĞêƒÛä?ï_AŒîj(ÁÌÑ
÷:Ekİ”¹OµÃø½s+%“ê(ıÔ2£)¿H;È^T'k¾÷Jâ_“oïQy9ÎàÀÍ,Ù`FjeØÍ°×GŒv†{İT&Ù#S!ãÃÌXµ½w¢¯¨ÜËˆ×†À#3/SÖ“<q€!HtÃëŞèV“´…†q<œuT«XıÇ‰şÉÆ½ƒÑ5\=ÈÅ@‹;ÛòOŸ¨aùfoáï;¢°Ê©RÙ€ÕÃdÛÚÈ~"Pq ãŞ#ä¿à'Ç®7Revkµøn@—YõY9¤Ş½‹HsÛj)Õù¢<§Áó'÷ĞÚì@ğ¶hIu,y×  »Ö(íĞM©S¡gBË;²À³é±>%–Wçl&1ÓÙ	fnC_;õ>Ö+š€{H…¶u½j“ ¦0¯ƒ¨¶åºxêR‘óüFw¼X(D§ÁçŞÊ7Äl+‡cƒ7°7îFƒTòS4¢.ı[IëÏz<ÈbHşş
#Æ{Á®™ùĞÉNvIaÂ@9JÊÎKw•]"dÖ<K9ûkHiK"›i«?e¢Œíš»ñŠLÎ]í®Cµô…Ä/Î>h´Ÿ &F“™Àş` ñg\´4CJøãğ½¶®¼!ºkÂ‰wöÛ5×mÀ€ß,¡nu¼’8E4gsz!¨¨)ƒZÕ^g*OC –›"ôW‚!±ß´ç¼ãlğNj23\·‘®^D6.• Mö‹¥Ÿ^$iàbXâV%MnGÖr=? ¸ õŒåƒô¹Î²¢§ñC¡9)QüWâC›)aãh."qG»QŠ˜Ñ9Zğ<×]¼ë$5‡âÄ6fâ[¥8Ú°]¡vAùˆ¥Ö–¢ó8¡U§,p"{)«Ø1iyt…úĞë'ù¢÷'í¢NEs©Ÿ®]E‘ßKÀ´) („oDç}v«„¿°eóSE3„OTPŒq¹±eğĞR2Ï¾u0¢ë=K)Ë©	9×–(÷ ö‚Wˆ›wc€L_‘Êf7»ŠîJÌ¿,zûs0÷™KOà„Şe5Ìé†qÛÜaôVò€íN³¬2ÆJ,îc8Tãö8úec–İ˜‰I¹ù[›øªIÎL¦Ì%Š:'&[ÓöMİ"_û9â5–ETÿ“¥…Á#á—–+H9x\+ÂN™éKÙĞ1ùÇƒtıŒ¯3@¶ßüü¸‰`aò­•·é•VzĞô÷ ¢¦‚ÿ2JI–ÚÆ²oV~GCëä>4•¼a,SxÔH‡xOĞ[FƒPïH½àt		ğ±š7²œøÜÕı:ZŠQJS¿ªòÜi1Sÿ_C$MŸª½/XeM¶œG &¾* İ/-HÇÓ–£«‹dö9üR$ˆ<õMËÄî5tS)A,#ğÊd­»“îû;À’4Qáf¿GÎTçi´kÀvyòÚmy,ÜÇ:ª—ƒÄ½‹ÿS?j¶üe[ËŸZX"ºğC
ş!Y‚[ôup†k?Z}4rÁAåJ±Ö=” Ô¬ş(²cdn#©ÁŞŸkÈU´Ü¶‰ÎP=çÜ;9¦œM‰ó&_qM«G”ğ,dÑv·è 1-î‰JˆœØ›™@…tì1£êÆ¢ºuØŠ¶¶²ıßMş¹úÕtÊÚ~ò …û<PÈV=ÛõQr©ïúY–è4`sß&ã†úöÍÁGu,‚À‡ß¨yxÿ]¾Hx(msœşH{-Óê¿gsëJöqŒˆ¹C–»ÔXCrA"}rdrÀĞÕFu|÷×÷Är*¥hí_½¿7 ÌƒZc²îAÄ¾ÔG&Á˜úçg®+¸şöÌÑeŸ›Ò2½'T¦‚’Ş°ÛtùMã˜Ã«} xõ~]/ÌİfPä¤Há\±«óÔ[bã6çKGËs«Ñ•&]"ç¬¶õ+¹Ã©º*§ßøm)#æd Í«ƒ´í³	HÊ‡(ÏR¶ôº¢a
9Q·ïëµH½Ç­…›í¾tJZĞ‚d]É S8Z}EÔÑşM±E0c›’«â]s;mU6Ã²…õıb·+wŒ-à‹3Sjn™ôŸÁÖáû»+‡lİÂBUÈAjÈäf [‘ô6Í¼üú<½ØmÃ^búÀ3›]üñÄP÷ò¶äd·!{ä%!¤–º;±¦´ºÂÙñ“(‘O/¥õ
D#£ÚCˆ“Z€`Oâ½©À¥t+õ t^ÃøÓx1’w»Œ³ğaÊÁµ?ØÚ;p-¢.FÚŒo;Cã×kæ½µWœ\D&×ŠÃğÔJµjÎÒ¢&"¼h²g‰Ÿu­[LZRÖ{´„À¿İ¥:/8·+ ¸~Ï<œy€éc¼|“IŞíĞ0ì¯&€Y»ö«¥A¨Ø$H­Á4ÑHo‹PõOt¹ÙOk?—Şò[‹}„T² öôÛ{ûÏ$ıå–PV†×·¯èd•x8± +¸Ss@GjoÆA¾<¶ÄåÏ$ƒQIv$)Nœ+$d!Eİh¶‰>:1‡¢™V€<ŞbĞí‡.©Òû^ÈS«0¯ NË³qš9@W’åK·Ñ˜±&%!—\À'”V MË/ë.æÎ‚š7õ ÒT¾ÿw ‹È¡_EK4ô²JÃtÈ+"òSL¯6¸pwšt.W(=ÒåĞ™e/Ç eí‘kŠ:½^:y<b²‹‹áLœ&z†i<¾±<q·úÎ³ÒS³u¥°ıê<#ş««ø¶z‘~­W6yô}¿Ë‡‚.÷nšnõ•ği¾PìŞ?ÿœİhÑ7LxvŸ|¬9ÍÂ6ç')´O&\K´æ‹G‹Ï4¯¾¤Ä /î/J€İîØè!ñŞk»5”=åDÇ±)å ˜ÖU+“fe®Ì¸¸iQC"×©¶ê&²ÃûuØu
î0&:Â@-u¿³şVûë’ÙÒºÆŞd’XçÓ "·[ µÔÍÏªçW…zMOv×je¹¼co ì¿'ˆN¨»\Äßì¥—÷±_ãâUÖú»_A‹~üÛ¨sàÜğÃz¢°9l&f§K&yË'EÙ6Àë–)–Õ'FXûÌšõn°Fş-¤ÊîzßÛ$ÛªRÁîvš2˜¸ îÑöÖÄHèdì8jîU¼¿6·Ã³Sóßínc‚Á¢qğ<Úö›Ê®Sóü½*ÉR^äïT´%¤£ÙhD³Lb„ø¸˜¥¶iqÌ•ß–ĞÒ=ñHW$¶ÃRÁVX¼ MYXÿ9AÏU15=aµ€út4Ù;jÇû»ªrGK»ÅÍtÎ,bô0¾i¹RóHÛ¶%½±Y£K=`±çÇ¥ñlz'zõDö,o³=cbt¶.!¾šëtE—ş-£nf®ªTØ÷¸õ>=¬˜°×¬†¹G†#™®4G— a-êñ…Äö°œÏY ±ß U
*İìù½(\ÄÿÊ-˜<Y!åisYˆ8ËıeH"^åõöÄ WÙZ½¥jiõeˆ•ÎáwºjfH<Ìú.ÿßLMß‘€uqD™—³ö7>±›._{£&é:)Ê$Ş¯NÙ†¬Ó"BÀÚT }ó<'çyñÕ­ó(p¨g'ÀvEõï[½‘ç\§a-¸P £Ş™Rb—]Ó¯ÖoÂ]ÆnÃ):áÏtL3¾°–†3îu†]TÒã]|ÜƒU¨	@òYöF1‹?1Şğ’|ÑmMHğîšØH¤Ò[İè#YÏ+´"2:ñ¿ş!´ùk‰…7ğ(èâ² fŞèÄ}ıØ§’¯ OÍmºşã¼ˆ[ÏÜ¾wSÉÙ’gŒª‚˜¬TÑÔ}ôş2³0il„Wõ8˜twéÔ„^µKÙÕ‚ÅXG ë‘\±è‰mK‡Nvç|ãYâ·=rhóƒû‡EÖè’0”»uãJp¾*+¢øsÕ¿ƒm{º=Ó°W°H9Ä«<êşâ	§€ÙÛR#}cK=kÑwLgc‰’â&ÙE\³ÙH1ák{h"î-d>Äù€-!<WMÄş¸%çIÇMdaŠygÂ…]NµUşdÈî[ÕéÖ6*ÒüÑÂW©¤kÂ5²áhSq„	'Ú¶I‚OVßÒŠƒöok=¨'dİ¶Ü)!š°Ëš›ÿC³b.”,ğÜ/ÔÚì6ÔçœBcó›Ëıë¾O{À0YòáˆQÓ·ÕY[B•=ÇÃ5•™3‡gŸšö1gI~¦)ç*ÈÇBTl4úº÷Èv¨9õ`®91XÀšh,‡»/İÑç°kİƒFr¼¶Í ƒûøz=ª]`·JÌŠ§+ššÚRrDá¹nNPÅ£|uEÜk™ÿ&ÚÔ¨;Â%ß4˜)’‰£é<}‚ÎÊ¢âø¿¡_Ë2;Ç¼ÓƒGë¹Ía¾,*S«7ù†æn4ş|f}¬œ¾FKÜ|"1ãDÑzU,ƒÌ…@Æ‹ÓP”â)Š¨¿1©±P¦y}
ü„â(·µ=lRûCŸR$‹”7	^\¬%“‰·ø?ã'«´3—qßúĞT‘y-Ë^x8•ZœÑÊ©¿CÉÈ.„[µFJaYÀÿÊËŸıÚ>–à—¤Z¡”wè-Iöß†ÌÎQşèBS#Ë¦$Db‘¥Ñ9= .yq€n´Gñšm#`İRŞè‘á}:n\ñQ³eu_ãÀ!3-ÂBã;æé¢`iì+¯oVÛ/än<j¡je3²<I­¯“3 Æ¢	zP¤§S)jƒTb¤ßïı1)¾ ¬ç$—‚\QÎÂ¼Šuû5S%/Q<v³v»HÍÓ/B¡Êw„Ôÿ†OEH½Åø3ŠÓ˜d0ˆÂZğ“[hü«OFÕÈ"û8¤%s]!p0EÉF,ÅÙ¶ÿó<!%MŠ—Ê-Ğ¬Ë¾×°WÎı‹††~4†œÆ.O}é•[ß¥P	Ø¾Şo˜uÒTN(lÍl‰öæ´æ@Ãí6;šŒùeì&–lKPiæzZLÄ5[ğ:Ğ¾ÙU|.)¤ƒ¨ 4mÍÚÄcîqë›½ŒE¾ît‡“ïˆàƒX˜¤ãnÁ‘–Õ;*&V‹jU¶› <ÕÄé"xÇV‹ 1%›ºT(úÕÙÅf´cÆ¨Éá'èR—CÊ #sÕŒÍõz5Šå7Dê!Â«¹ø 0Úçå|!§ºô{Àì·„¿˜[@İÖ*uATRPÃHÔ•DSÖãwûÙıQ©l¶ÎÁö¦·û±ùãñ'²ØçmÚ_]B»ÃW3/ßPw¤‘»­÷‡Ù^Xc
Ö[Ã6$(¤7 ×,Í{ünÆöŸ"’H÷"dLµ\’
’…aÈÈ–…êé¦±zõÑ/7}xİÒ’#¨’ÎFÕğÓ1ï™	úÍÒ#wğk<?üŸ?[£`İ&¾«e`êÍøF[8÷:z°+¯Z§¾ö¼ºò H‹¸½áT½eX³Q%=	İÔ‰x½çÃ®ÓDÔL@NÄt·&ìŠù9N'»Ï#¹ÉFnOÏyûëŒ×©¶VÏÒÙÅ;ç<~£fDÈ´@0åkÅ)Êûnöx“HˆĞX‰"ı‡x4ĞêWÑØ‹@±f/dÈgÿu#Õ&Ÿ
cõ&iH>’»Àş,Ç5ü¿ Îğeì2í3ÍŠ­-èŠøÔàü×Õ®CËf[eÉä-OõÁ º!ÒÃ”a»ª¯ÚŒÕÙ‰”}èL÷|ˆ¿5ªÒn‚è[9»0'ˆÛ/dŸ+<¼Ğ¾
;°*%õÀ»¼­e-©‡((sˆß"Q9e@Éå¢ğíÊ¤ÀIòt·ã°á‰H1Şs$6”¨^XQÁ³äqüƒj¾*à-»ø¼¸odˆkñK)¹Çû¾ÇTÙmtİˆåÕdFs«@;ö5IAâKİ ¿'÷7L¨¨–ÁnÑ¾˜NìdÒ©Òò»J_…—İÖ@wõ›ıOyÈW4WÖZú4Œ¹9Àğ_˜‚VODªşÎ(t$ª–ë ¾@Ñ	¢9¼÷ş "ÈgH«%¼¹}©úL}§•'"Òìİ§TU	LsÎî^pBÁeª¯z®T³ÅáL·ò¿ùï`"†qœ½k~&úù_’Pş»pÂ³…²£h,†æ?ÄFBD}Î„ïC'´M1ºæW+»gI°Ö€Š0˜¦Üfû—3Qî±ÂKgIA·iHDŒ£Ù˜µÈ3‘û¡ùäíîÕN¤/V8Ê,ï„ó‘48oŒLtVqï½¤¢4„ï
y¯1ÜñÃààßùú=Ò'/ÇyG,–ï†	R!œ6>uü19Z0¡n^zù±˜aˆûÁ*sr°_—ÊÎaL<Í-¶ëTyO,)>øÚ‹}dÂ/MxĞ”îV„Oº¢è`ÕW8[‡‚Öè·:ï\×jš °Ò‡¨È…`@W¯Ü›‹]PíX0p"U=gPÏt ÃDyÈ/›¤¢¦¢Ñİ°‡kŸ{¬hÜ¼G]ƒ„G[T+‘'ÌU©ÕgÎ…}3u¢ph½±Çóãb‰ƒKÏ-M´ã×âøj×ıx9˜„©†ÑYy^î†L[Ş%`ëpÎ7º~z7¶_œôÓ>%j$87º‚+…»å½€Á¬Ø¸@çÀ¢ĞÉ	<ÃS¿Ø@Ó&‹<>÷ÍK"¯¾0"úÕ «kRõ¨nî.ÚØ¡ Ûè6$ ±q%À²¶3“
l	D6C‚]Ÿr‰+Í éğ)ùšJïŸ	*ÔÅ(F“‚ı_É™nš“º½“êüˆŠaçµıÌv$*œ´.aí³'M"«x Oh`{oÁFÀÆÃ<â¼ˆJmœy!v6Ö9A8îÑ0V´Ÿ[›ä¬ñ€ø?Ë«™»eŠò¯œUì	¸ğPösºS¹aÒ³ó’ææBSïÑº:b`ò'IŠ2sÏx¶uŸ¢Öz»ÀêÃ’ıN·–;9®½‹~
İ1n•®ß¸Êø.TÖüıK
:ºLXñcÄ#:Êˆòsv`,¥¹’YHp"V³·âèávõì§49rvf†Ğ’İ¾bÊHè|ğµ°ÆÙĞÄ½s¿?*zÏd„AÉÙpoeãD(hÚ†„´´›Q7z2[/„QƒYŞFo5¨m³Ji
¡‡'Ô‡&¾¨·‰›ÚÂw0GÄİàI@Uù‡!İ¼çËQ'\¤w$²¹hW¢·¢ìÉ—c€–ú¤İ]jÇ†”õ™ÓİÛå,ã‹y*gªù}Û²Üîò«ûNr>3“®‰¦½ê@‰ğE!s+;ÿ¶7ãâ:Â¸€“pñ[0Õÿ}_1iEò©Ï²şäEA”54ÈòŠ±ü°©úYËª“	º™E‹¯ÜBMVÅ3Mk(×øã$µ³„×PüßvT‚Î%):DC¡6ä³î5ÄIaâ;pşL]nü3U.‘ctˆ™»óG
èÉx†:†ÒßÎXæbIô?ˆl:Ã#¹‘A÷”g12á†²-k˜”-•9[y»Å.hì0â™õÜ¡¥sâŞ¯½š8âóŠ‘æı¼ñ<Ñyáûçú!J%ÁN‹wş8ş:ªÆ=1Ú’9³/s•
+šäwXQÆXıƒ£P)7K¯ß
°zôz6'¥'Zt§Í?_S£®²«ÂU§Pí˜£ËÙ›ƒ¬/_C'·›X$-ZœU6Éb{\·k¡ÕSŠŠv-X’>‘Zúr¦@`=ƒc¯íÌüıé‘mÆÕÜú @U]wQápr©<¥ìY·Ÿhs^•bN§"¨c)ªÜÿ+ 6Ò"óë“Aş¯dk-Ë
.q.Díà3À.ª¸}ä-61€U…ŸWîXG/–í¹èÿhæ›ŠG ²®h¤cCÒ_5ô†ÑD;ùîªe¢ ï)ş^²b‡o[º¾9¶!õÏTUJ–õh	pév­Ğ¥[3~Š H‡éÓ„^â\ÆÂd
Y¼0Ë›–¸ÁH­Ï@®$7Ôö?t"'„Jvì†1mŸlÇA	(‰)Øb¤eãŠ²Şai;U¶ÁxÖÙta°)q/‚¥…Ë‘¥'ø¤à¶¥]÷\qûâ{ä¥ı*¨\À%ßèÛå!¿ÜVşÂµ‹İ™}tWÏ`?š‰úÍtpƒ¼ºE…hÉ–œîÒHîª2‚,bíâmªàıãä;ÂÊ²AÁ@$Ê}ßo‰ÏXrë	qi6¨S9†ëÖ\ ú[º*X›äEåJÎÛj­¯ñ™üMàtœE>/›3Óçò7µêv¦…™ypÒgË•[A}ÂéÇ+`²çìA+ÎÜ²’u:‹¬„¾é‰¥.ÿÆæF³Ê%aG«Ä­/[èŒ
PÈ	ÛÜôşDQG ²”ã5«óO4˜kºmÌÕ±3o€<Òø‘øØÕ.Ù¡…'Ñ&“”®‚í°€3ç‚&"s‚ˆÔÃš”È@ïF;h¬tSşŒ2h©€s­º¦×µ¬ÜõEß§ƒÚà`G{]rÍOáWÚKõ×õ•£³ğUÎé¬–#Û(4OÊ]ÍJy²ÆŠ”Ô:¡k@@9ûêwš}âfËg’fW7HéuñÊ<Ë¨ñ>ÔOCQ0g5‡’ÚÔVE$A¯ˆ\X;+…OäÉ.ô“Lü§oùq¬w­á`¸‡B–.·Ó
>ˆö,ÅæšLDRßEÃ”a'‘êâ±›(MT›‘‚´úÁa‘h¼Ÿ†7ö©N æK×‹iùgk·$
<§
té–û9Fš‡î—òxLİ.ïÇ_Ü7¬hÔ¾ÔGÔ¨y·Ï–á9ˆ? îªÜ¬ı*Õpì'mDù+ÉA‚½ |‚ ÇœÌ­F‡¡€†ü±
taZÙ4­£ªä%xñóë¾:u¢Î›hßşo^fş
”ñö  îtü4ßÎÿÚj.KÎú%,æÙZVYØ8ôxò6Ãdä+ ŞNŞx 8tE!ó²şWzt*§»"ùÓx{–‰¨)97ûÇí2Ò†ÅmîœC¬õÁ¤#œ Ø“qi‰°‡Ö|£FÀ¾°Cè*ûÌ(YÇì¦š'§jVvqÇ[1-,§!¹å; ‹÷ºÑ´Í³¶šMêiÛ°×
-à¸£4„jÜÓ}Õ¸‘”C)™³ÚÂ.‹¼ ‡¦zÜU”£RYğ=Ğ¾J”â¤Ò²á+¤âLOû­hê#À­£D¦Æ)&šÎ\Ì‹åù?ië’Ûz§“ô½Ã0Y±>:üµ]3ÃªŒ¹ñëwÆ<ÑX½ÒìÓLîæ­<«X.n†j%òSÃ×¬IÀq¡`w`%</uÖ&òl„GÅ4š¹k-¹İËînT\aÚ[çƒ~µ‹M¯kÎÖ|w2l¡éÎ§)«å¯QUqk$sæi_‘#I›qÈ/ÅJÏã×à‘‰0e>Ôtµí+Œ¹fTH43¼óbÙ2dÑCÂByàf7Âd„êQx‘äJ™Ş¶—ÎĞ¥£ZnCıê4mç@Éc
#+%=Ç0{w„Ëv¢Õ³ã· I4Ÿ¢OO.êM€ˆ¾!V½ô¨êçjA}®2FÁAu³\o›Á„Î‡Eğ¾œõÏ¸~ğuÒaÏXxİ‘oqÄ=şÑ€²¶£ ß‡ªuwëYúv8Jlkwœ«|{P…åáh@ÏÿÙpBÆÜLk¬´rı¢ƒ·VóqÓn A#“ 3¹¯b¼•ôÓßÚ‡Ì6¼´ÿ™P±2€r½©¸D±ˆ
”<-WÇ‘¶V’ÓÎ.oÔO0T£)ŞbåZÎ¤§oÑßäˆŸ]okÓ©´‘•
z|v­ñC‘„é*ïû÷MÙ!îÜ¶OÆ™£*æ®Aã&ÿ¯Éñ¢³æu,à«ÅMÏ@4û6ÕS™˜yµFÊDßGe‘CÔB«ÿ‘/aƒlòš§‹ÕÅ#²jÌ~Äæ²oø…êN'Äwé~¡i+S÷X­†¹Øæ[…qÛ¬/’*ºøÇ&$¡™³Û}rPØ‰ä'Çÿ!n2éºNè×:]°¦h]Õö–|\ïùëƒ<­X qÑ:Îºha-iTÖNù²+õ¦ßÆû¢ä¢ 	}§;ö%bšÉæ½òággÀúNªàµqMIåÃØûë)`3S¢(¤>†‘vŞeÊ„ƒãdïÆ«ZGÇ8ÕŞ“B‹qZ.8ëò\áfV¶W÷…UEÿo¾ ÑV¹­ue>äºnih½Gª}É[Qn/ƒ¥4%ŒÛÎå¶æÓG!rêià‰*TP¿S5dğIjÍ LRb¿¦Uoî°Ó;şÅŒAéCÉáÒkÕL$MxLßXËêKËB©2(´fWùMõ‰ÊÅloÕ<÷~qSdv…Û15…½+—*#Ô%Å¥Â+8'İ!éhT#zÊ6æÀàc—3S%boá¨UåjÎ?ØúŒç.?u)¦÷²f%ƒdŒ’òºP‘ğª°cşø­éwšÍ[¹ƒĞˆşTë2ñ fŠCÇqdÒ‘"zĞ¢Rõ°•Tv6²ójšÀãİ©k6bmüšââ²ïÖ,½m†œyœlƒ ’mb„ÿÀ$:ÜÈ&c?M#m8oIIGõ)4‹P–â†f­Ï¿¾ÊÔ¸ñ Å*İ)ËgöÑÙÊù¦%l¤Ï9Ñpªõ³á¶LŒ‰HH½KkÍfî×¬w,lÇ‹$\«ÖTO° â¦*à2ßÆl•xXIÕ2ÁÈkıÜäË•9­ü /ì° ½Ãc[:tZ]S‰RU	ÚÙ0{ü …€‰Æÿ¼¥<•¡ßäSBËóä]^85²f¹›#¡›@ËÏ:¢I1Í¨4*AÒ†'²˜mVöıñİ‹ïğê±Á<0Ûº*K°bä3ÇÖY~›ımrC¶¨øüPÄ'„ ”3‹îGW¡ÕJâ¨š( ’è§ˆè4ôxÃœØº9²5[×~¨CÖTLúhæÚKÊƒtõ×ô—Á]Aw9Mvn±Øfá¨Öœš¦UŒ¶k<ìÕ8ƒÖŒt5–Zuâb›Õ=u7+Vm‰üEF'‹(ÆrØµœî–g'}Ä{¦'õ4u(Éï ¦J„QDóÆ¥í5Ø6…0ÿø>·I«Ö©ÆØƒ­WRìS0Tuàşû6{ş0Ãü €:œß»_ìĞZ +¬¢EziÙÊXO“q®ìM`j¾…²,+ÚÚ‡[¶£(P—óv.®Ò.ø8ÊÔèåèÚÕ&Â Ï?¦Ê&e²¶Jht‘0O5…8Ô}H1)}ãv<±…«¹‰W’~¦ …Ày\I&õ*oõî´Ÿ[‹\Tr)Ô¤û¶ï!ê?EäS \‚'Åu˜ä{*fsl#v÷m¹ÎÛ»†‡†È÷—à0Ã$•šœèd>] ‹Oš£ÛdûˆèÈ¾N„/#<×OñÓÛëğÔëjg„&ôhÂıçì­Ì!hE],[¥ÿML°Å‘eMãMYçPÕ¢Á75,<Q/flÇU5a@3ÓzFü8CıH]}(lá(fÛ’JOƒ¿¸Ğ†Ú›=[]¸¿<^ØÄ4ñï·hYôlĞ¡Óz¾ÎF†±;á)æ™¹š]ÆFùŒL’¿#–fŒpÓv³yL«`CÜí:W	\ı»òÃXğ	æË~›ªí1óRì‹/œA–¶¾<§RŞ#Vä† Ğô3Æ·¡éüOCêĞz<¾¾/‚P·ÜdhG5kfLp¡Òô,-\ö˜XI'›&ê¯ÉšÀØ4U*ˆ„À„fBkõà˜NÂÕõÃæKÃúºr´ÚuéŸ= ´(ä'şUmğ'q°‚p\ãiu$÷ê†ÍdÃì*};ÅuB@Gù¼¸µ…KÓØéá"òyATeó`y‰b²k'zZaáÎ+Qyñl±—õf`±ãÙİ2/7ˆI¸_øÑ4$tFŠßì¯_ho)‹ñD(ºŒ±§‹/Ù#Ÿƒ´ÎŠPZJëGÖ£ÂÜ
†–ÀrÕ*_’èYÒ»3M0³5`”Í\Öû]¹ûNwø%=N|Uœ¨’ğ_×Ğ¤âÜÄ¸ÿ<k«a¨–{¼’ÊØqzLï±r¶_ÎKÀÉ”º*­b©ÀŸÒÆ"¢¾»bkõ/ÍÊÛâe}¾ÕE‚ó%«(ä.&ô†CQuÌ”y7ô[’=óOh¢ÿ®ÿöÑaÿrşv
ìˆc¤†¨Ír™àZMë˜ /œ\È7?§ ç¹/
Ğz	Ô"A]|"I™áËùÿŸ<£J¬ßãlNªXª!»ñ_(õÇBFg”x!0bÉF/‡Íi•2†> a}ìºó$LÜS±)„
Ò}àñåĞÖ¾Œ3;.]/¤D¼ \±¸	JßÜ1ĞJ¥<¶\3ª$OùQ(N(	·yùüyU^ JS„Ïš`tÇÃÈÄÇÃÔOˆ™4šVÍNà¹ˆTùt{ú:øéaƒ¦âUşô˜!úŞf¾öù>€+Ğ2ÒÙX?0l˜ôBZgœl NVfLÛÆ3×“ªô@â>"±c-–WŞ"šå#C9jR¬‚¦ (©¯{4ÿ*$­¾—
eè[|fGwŸ8Áh›“4*ƒ S
û€‘	¡w­¢–Ç	ÿÈ+}AÚ6^Óx]Ø´ÕT¤›'×¹wR)YØ+9JO®µAd¬pÃI(/šX%ó´Ê;ÌZ¤ÚS"9´¡ğì ÒaÀ‚¹ é_«ÑÒîfyL97ËB»ûJ…g#·«	3Ğ¨$0»î>—Šìó?ˆºÁè§áÙ‹›»`ì¦½§{”wvªdN¿æ’jLâ¬]« ª=î†ÿM'íZÜv;Ğj¾"„®-3‚òõ´°ˆÕ<»Ø³=º¶Ş¶µ×yMşƒƒ¿?í®I©âèŠWişBú’áß,WM/¢=/’W­ÄªÙ_Jcí~X­ºJÆy|&)ƒ¶Q-<«ÎÆH?ÊÄ!½Æ×Ûm„‹d¾¨]shG~ñ„GĞ>çÌƒ“¦¶aÕl;dËÚ.(‡³ïëM]N,ˆ”à¢rœ)::®t“©Ø(oåwÛ·1ÛC×.i¡&G¸	Ã2€¦ÿvrßêÕÉïndç_×>ªåŒ»'÷äfNàÍöÊp¹5”ìPùï–ªVÆ%_f˜cÄÆ(xü	AÁ]6X8ÃğG0Ğ|10&9¨ãEÑìŒY\—Ä/\‘È!üÆúï°Qe I¿›§ß¥£QSrŠ1–Üı2„şÈÀïoŠ%kŞ,UkØ·ÁÃh2ŒştŠ­;æO(7téÒ:­Oy5¶ãÏğrñ ±‡¯õ«W3_¬¢ áï^ÁßÙğe(XîÌ@œJ@äÖÆÀ€XTËj­”5ç[4³»>sPˆiO=ÿqMeF¹RôbŒÇõªSÇ…¦‘ª¢uÉ×ğA}ÖìÉŠÒååÙˆ)¦»˜‘M³¾¨¸O	{è=Rü­4X†şáÈ£ÔÛtØMT£Ã«C†)‚«ü±·Ÿİ*l²9&ÿ¨>å—cƒ©T™¡ìÒË´ßÏúùÏ™Ğ ÿì!´qÇ4/KqÅy´ĞóB—!eºß€~bD7üH¢:ÉÓ™ú”a@œRêòšÚIâÄ«ıpYƒNW	#5ÿp‡¡E½”GšyëgT+òºJdõ,Â­·œ¦$#SxiûıòIoóšY¢±–ŸĞõµ ƒª‰Ø.dúÔIÓ¹šy½S(=¯?”²˜SÂYn˜TÕ¶š\ˆSyŸıÇF÷æ¡òÿªnê²Ta‘^Š|JÆ“Rù]ËHÿW·<‚î‚¾™]BÂBìÈÍ¡O-Ÿ[¤~G1ñTm¥]¸û«Y|¯ôØô—ªÉßÒ»ÖØwÛ>.B*Û¯6^¬È Qß$~»›èË#ipë…¢Ú²bºvlœUd*½–ã–xÁ|·ÏpêäB-8)W8Õ3cÁ²Š«) “Õ¢nGõÇ…©¾Ú…«Ìä`ğrY_å´xò‚ÒŠ©¥Á s·ÿE“¨1ÀZùÄİMu¤jÆqXìñ¨`>[´.ŒÏ İÄâÖ<2©}eë½Rî?òúËppd_­É¾:Çk½=Êd*ãœÆ¤ŒTWÊ3Õgıš«\ÍYINuqÙ3ëô ºŒb-‘ÙúsÇÿ)êƒÚ¾‰,zìªmüƒ//òæw®áèÀÃß/Ä0“V™Q±4÷bŠn} ŞöìI·–.	XU¾ç>®»‘è4m)=¸ç”ìÄh]ä$¡t§‚Ûìl”šk#
©r!¤¹L_Ÿ¿#sˆÒšœ0
÷wuÒgsÆHAòâgä:sz<Ìùéq=Úâ~=œÚöéqˆE„´‘ö¡¨^^åàÊ‹6Î´íKTğ¤-³:}»Å0ğ©bâì6]|H¡*åÜbÇ>·šú#@aM2»©üŞL…—¢\†Æ †ƒU”»ÿ¶m#şi)'Ù!f~ş2ê‘—õ-!ßkçNAÛ—Ô?]o,ÀuûÂñ?“ñ¢ç-"vƒ	U-’Ôcğ?_5z*¦ü„ŞÚ(ƒ644OööÖ8d…Š×·NĞş¨`~×q/¯æ–Á©¾núUøŠ1Ú¸Ã‘©?@y.5ÒB„¿hÈíâ'SšYñ|CÉ}âr{¤}[ŞÊ«”õêåc€œ"ªÑÉ™ÆA+×]Sb‚kÁ™ı]ê1ñP€ÁÌíÔØ¦ËªÏÜn`Ùš.ñqúóK5|!(æ<2ÿö#âÍcy=‹`İ˜¼t'`tÛYk³½Şû‡ı@_^ëÍàÌpö
°¨ZÍÅ¨öPG®‰×)&ãBºegSúŞ°Í"€I@#v}CŒÇ<†=ÚZZ*ª#L†Í5¥"ê±†w•íG½ïF†Í~füşñÈ[ŠúÒZu¯ÍòØ3Û¡¬°Â{4ÍÒ“¶_ö{üïl¨j&LnÃGúìf@æ˜quÅ™ğ4+=T(óËò¹\kës$Â¡¶»ª<¿Óüê¨ŠPĞŒ:¾îÎ	9TÄĞŒ•°PxdÂáà¼‹”ñœÎ¼¥¢©#{pˆ;3œÛÒµ±ì¼åŸ—}œÅg½£W†øn¶ƒ¬èpb|ü¢ÿCÍ)&#¸™5bÆ”úı>§B¥@Œvàß÷Wğı—1¼ˆ…×$Óí«¤ÄA@Œ!ËTøüi@8.}N–àõMÅ=¦×íy˜0é¦XÖw@Ÿº¡è˜°-,‘²1¸ƒåÅ 
ëúp¸Kê%¨±oõFˆU/r®zÈ¢ü"Åğúà!*ã.²ğz+foüâÒÿy§ßN€‚ÈÚ°ß<&WŸÇP—©ğşíyë823çn«Èö]Î³² ÇºF¸f{'ú‘>qğ‡qê{”,Şú{Æ¯Õ'®³EŠäŠ„N¾¾û›_ù“İgòï¥]0=Ò˜
Q,e.@ş@/]~K8´càëËÛEìã#‡SÛ6‰ÖÊ#°ß¡ìì|¥M…¨²}¥”Ô‘FyÚiÁ^D-ô;í~HONÒZÒÑIJçô¢ZÌÖ¡à~Då»{·B‡_Y·Œ®){-<mûºˆ‚ZO·˜…MÌÇRíe©dÆ	\*ıÂ¸§e¹$T'Û-J#‘Zj.úó°ş"ÌbÊ§YQù³XÌ@0ü/@lKÊGpöAnÒÚ
Ğ7ÏEÅÿijš~9$Dyˆ™Ş Ã<ãÎ0AºSˆğìÜLÉà×±®œ³*EûsN¥¯@™W¸¤œöÛ2Õ¿ŒuâUŒ—Í’A•	š#árÿ×›Z¢nÃEmm]yãÂZNë4í<ƒ¾Æè¨u¾‚ş8ù¸›Ê/ò·*tI)Ï9:ŠnÇ9Ó”;“ëoãâ/3¿Xr\ÆŠš‰! =Jõd-©"JãñÁZ‚}Û[„Õ·ÏÔ®²¥@m€¶`ÅÎèòÀ38¥;ç1Æ¶Û=-ÿĞûxtIjlñ2ß.*4j'Òj¤Aƒ]¦v5½?•Lİnï!‡=óU¤Ğ[Ô±Á «õ¢{W’Ö»È:Ú:±WKH¬*êšºi:5%pûùa£qÎÙQ0Ÿ„
œåU”[Ğ?y€¤ü²!a)Ñ«•y}›Juœ”RT§›¤|o½Å,ÃÙèÍŠVt³×„Ò— >y0y´m;æü<’šæMÓ~š÷5ü¦L.Xª¶ÑÜVÏgÄé¡¿obßóÅBgÀLÚ¡¥ÎQ~ ÔtdyÁò©HÛQ“"ÂHµŠ¼£[)fã£Ñ)ì_˜ò^x#¥)ı–-îËâ,¯DåÛï,7pmU×W¶|ßS=:’—›ˆ”ÿ]ÈZKN=Øˆ:P^Êáİ¢O]Bğ§W¥Lí/Uo^ˆsÿ®JÂığĞqÖ "©²(ı>„ şè±M£ái£\îbI*ÆNq<z·iö ø(
sæ_Ÿ‡â»nÓv—¥ı[ÿYN•Hå|\Y3ªj	dNÄWû%ÈdZ¥S†¸šCM©­_±¿s79QİW‡§±ù!N;-­>ÛáÂá<é#Ù«êÙ0q™ÿçXÈ7Œ!İ˜¥(±`ÿğ”CLM©™†õ<m_ùı®2ÎáÄ£“p<OÚD‰ş__%¾[!®½c*›iKâvÚıÉ¿–‹|í"wÀ.4×¢İïcrÓ¾ä³ëp’-à’7³&Ğh«Õòe•êlÛ¨üñyRm]ŞEL¥™f¿¢½´™8Á°iö’~ôa~íÕ&9œihˆf¯Eœv™|¶’'ß\GbµÏ2Åb¸.Q¼ÿ·÷´ëö³úX'×	: ì-îÑb.ï+‹­QİÌ	Ş²lÊ¶˜Uš‹V2&ŠÜ]%’qÍQä¡T`§4Ä ÆËmÚrÕ|e„ÑizNgÂæ‘Œa;ÑG¹àòå‚@ô˜ekô±ì¼N/,·*êïùlk+CÉ¸J·ÓÁf1Ìbë‘@‘:ƒğİn5‰»®–ˆ[‹*æ7ıd}Ï:è8O[]€‰Ëü-aï.‘Nú¢â'
`¶15„^ø³²rËHRhE¸®	·%«˜g~õI`î®İÒÛÓµ¡_>,Yç8Ä^aÉ!5œïìŞáÊ0ÍïĞÉa€Ü‹¾Bï‘­°Çmõ’¨Ô±ßÒ„.îB*•ÒØ ”)Lû{ A¯ßÙš°Q$²¾òª~ÚTÚf;§Øc(zCfpm>%	¢p‘ùË’ÖçKd«É)Û:Jc ®cğ)»›1\‘=h²œÂfé³¶òlÒ*¥«I>JÉ‹¯ÀJ”Ú3#Å<ğSêU9YW£Œ
Zê+`˜ïE3®<O	½uµÔuâMõ8%	¾`û‡~Úc/eˆü!K:“`Hæàæ·#` yi´hØhÑ¸A:_İƒhéRÚ´µfMI6"	X©DP: wãƒûéTÆ~UïÇÛ,?¶fğ_÷áô³2®	4Oï„æ¶ucs²L#Aæ,Õ‘³á“ÄÍvy0…ÉSé
2Ì ¶÷ƒºà†àa¯ïf‚éx¶¹;µÎSéÕø|Pø”áÒAcòY™ò¾î%=Llå›ó’X¼µŞæÌ¶MNìæ“œ¹kŠ—îÿ7EH>ŠlƒG>ƒ¿à,c}s¼:‰v¶ºÂl0PÑ€›î¸­P³g¾ïçó
¹Íjá¿ÀŠôãí00]ÛZ².Šòìò&éS¨fà\¬ NíÓ†.¢ „9ît%Â ÊZ{N?6hóÊ{¿K‰¿êzô’dï7LÍwbWÄô í!=³÷’HvØŞFP§ûPæ‡•%ÒaY¶ÊúfaaaµÊªy¥@1*(¯QH{póÃ‰ÓÆ(5w¦ŞÎ ÿßşëDÌ^³âÿoÌ*ClCöı#§İójçHÉ<X…!¦òat5mãVòŒQïôà[*òjNoé0Ë½†êş˜+½×]º§
]§é™e9ŒëyéüEë4Æ¶~‘ÁYÎ½©ù£ ÙÏÂ—U‘º¾´@+ÆKz¿¬Ïo6G•±ñ‡0M®e[6{Äª»ø#}ƒ27¹30ÁÜ‹skğ|)Z‰èØè›—©G€9"ua'\l½{TqÕÌ PŠpÕE¿‡Ş~}Œp4<Fÿ¯mƒópÅ ñ qàtmË~ÃıÚUäóñšJQ¯´¦#b”vµ÷Áü×@^„ÚÔÀåJúW¿ğsŸÍö"Dqøõ=rA§ŒĞŒ03Ërm’ŸPj~ó9ck‡Íœ˜?ƒí€!Í¨+T¨ç¢|´ëñ8›o¢İ³úBe1;¾şÄĞ1w{ZÂ…¨«ãéª?šâÓöâ#¡×sÎÖ?¾C è2\°ôØ‘Ú(½ç’ª5™äRÒ ŸLtÛ%ÁîÁÜwb1WQ[wç9ãFÎÅØÃÔ¬8å=ĞNÀÂ•q§²6Ó—Ó7T2R0¸×Á¶³¸±s|R‹ãN‡…vª …„{¶_‘±2;/ßh´•İ`ÁŸ)‚— ø¥ğ9¼"/O;.9¢SçÆ|nît‡"úEâÚ£&šĞîwœò³GÒUb±ÔËD¨¯²-
¿ÍÓfê—X…nµ'ê'¼-Æµ+lbÿxĞW„œÉ4“Ğ:p™c03÷y€lr‡a]Ks³`Å¶wî<xI$ôïÊ™3gwğOCCcÓIÑ4ã£h?@
®ş9)Ó\8£É ;µ…+äÂñ;j¯õh¾Ã%ÀvÆÍô^×y/['Ç¡¨X8“iİ‘U£/ìLj¼òmØ6· ¢cj›g3â5ˆ3öğàT½¸êèBøË­§å%ãˆ£©+ôfˆã<ØØ;¸²ıÍúÖzµÉ‰RAŞ á¸‡¯Gz(×Û;‡ı'Ùß×Ìbó•üåÀœVd°Ûï”G2œ®=Êc	è,¾¨ø1ììE:@—;@Õò ƒÍ"á¯~2éFÖİÏ›8f˜msm©Ò~¿şA#å`~ŸË„[RÍ´÷:6)§ÑÂÇã3Ú«Èˆ?¸ã²ğz¾H”$E=“F:ûË˜Ú(JÄu
w¨T
áŒ£ÖbáÂIUöÕ8t‚6$}‡#÷œL+Z´Ô—– ¯¨Fœûõ:c‘Eé?¶Ö™û2¥µòüüê3[Ñ$'z†ùäÉ–oåÂæP¼¹ 9Àpt÷Ôÿ÷´¨OqSùÂ¬¡ü h¦kÓ¨á¢4ü®X@)êèÈj.ú³‹p{\»–øqYH¶íšõ’KVÆ= ·èÌìï¢ÚÙQ
ªõàøç`A»ìš¸“5ã6¦­Sò¨A¦}wcÑ‘pX£™–P€ À°U’?¦˜ ¹!OÑ¬È!JŞŒ£É„x'€uÀ–çâ|€¥bcZ#$%FT(ˆóWäWF(»y(ï oŸ…=ú…	ÖÌa¹P»)&jCa©0À-l”‚_2şÎ¿ÿ]iµC„!İĞ+ËÿuöØQÌÇœbb{d$ÉlR3XLeyûmpO˜¡Î®Ã UÅü=)=tUš_#º¼3z—{â!T—ÚˆÈ WàYL\ÌiUdöë!~¿„öA„²"¹¿QşíüøórM¼Âo»¾ÜÍ¯§Øò©ùÉd³Û»˜-¿j>ÎÍÌNZîÙ„/oJ…!ââ]—özÓeÿ.©OX¨øÇÓıñ×v„ ê›kk¿¥eDá‹;'ïÖÈÎgÏFÜVšÇı×%×&wè È°úVã[É)èJ¨ï–Ór9Ûİfâ†Ã£ªmº0hïº4©h¡=n)ÉÀ¤>¢&;úJü”çÖ‹·sšla^]Sêâ¿º(‰~ç]w¯ìvØÄGd%›× “ZH[KˆÃQ6n¯{ÇºÌ…š‘¶µŞ8LŒ°w¾Y?4¤z<‹‡QÀ'Œ€Ùq‚ ÌvlHYOì+¸(§XÂTAøvÏ<#›li¶RDæÿ6¯çô•1amï–”RcP~$jqh’‚²n´No(É|œÙÒy·Ä.¬h¶sÿ—‹_sz±ÀúÑ¡0¨yx%'‰Ò—ğÍWğiÅŠ=ÄùÌ¼0İjÑ
†ş†ÌŠíêt÷>gÌù6bKŒÉ^j–ò°Ìâ¯¯.ä…wÍG;,XƒŒJ`ÃaL@©ùŞñh:Qç€Ğ¼Á.i4,W¿Úı´vßkk4–¼P1×­wE’¢V¡Ïf)–³Ù¯î›óÅ—µÛû:I»yšÖK÷¿¶öÀ½	ÉT`İ4TÏfÚ¥O?©ĞÜÆM(|ÈTiñmñVKuñŸªNà]kÔ±¬ø.-ŞÅI¬Fùûië<îÿšX¹óÅo¹üà5Ÿ%cÕÁ¯TCLÏÆ}Ëe8»MfÓ.’½ïh¢:Üt@`Îq¸'2˜qè˜â‡üœfË¢EÕ¸ö£áE‹¼Ã7ãl¥æğÁó ­äM|ÃÓ)÷¸­Á«dŠ‡¸œp€LÊ!ÕkÃ-+¡°ÜƒfG2_;¶Ú:q¯1$ìXm-XT<®ÒcQPšJÀŠBgBwZ"Ò®•…CæÈûo‰zõ‡Ø1¼(¬æÌá¬µø¬hÒõI@ô;ÖWöÕî8Ün,ÅE³K 
53P5¢ëiJZŞ‚_·ÌªÏñ¦}ˆ’÷7ŸùeÎÎù¢ŠAÆÀò•z…2Rº5^7èÌ£,®—0‚àpcLÀÜÏšŒˆ„Ÿüò$Hs/v#_²hB~’¹R×b'jZí›—‰ É¡ÿn»Ójœî†;¥^IToŸ’´o]Ş´æY"«¸šdIf¸Ô)	vá®A¨ø»CZšşñ'cT“:qy»€£¬mÎ§*¿—jtÛô‚”H¶ŒQ\+'*[z[J˜!ñXªƒüÖf7¡ñ öf·{-„x€ÓüåX=1‰Ò'3¹fM.Ã7>Õ;~,ƒ‰§ÃVÑgdR°}ØÍØ ãeƒœNÍDê#İ=ìùÄK1¶kòZBU˜ª§£hü‹(Œª‡?a@Ÿ«Ø`>¢B¤ß$(™ê³lIÉ<52Æ(”«‹ìŠP[iŠ²†ñéÕj·Æ8ÓêìC£xÉ|Â¡×ñ~¢›h9(í%§£³·¢šƒmñkÀË£bˆ”'^ôÔ¯Æo0Òéö·«²ùMt\Ük+ÊxûŠÒæ(”íg÷ô üõÚ£EÌ­aÆœ!“ªì_Î˜û~ëv² Bê‡èÔ¸|XÊÑÊê‘Që#zq@Á ·O˜"9ÇÙí6î”ä£Ó{dà
q.÷êúT¶êŞ’vS‚{¼q‘Îã²0-¶÷ª8MsÏ#KÀ.M©Îß£…†ÏÑ£ô_F‚1Ù_}! Ø#ç&bÃÔŸsóEûŠ8«€àW–£*Ì›·PêÉ×VŠBª#Ûêçßâ\ƒY¡wšws…Sâº7\¥–8pÃÒ•§5<!¢–*o_x³¡<D2ôƒ#ÌH¦û0SD¿x–qQ@7‡øCj2½[?Ì–¸1É¤ä@,?HØ/æI#[^¤Ó®X@miO²M³8†îKfvlÚx †Vå›È%"sÆ‚’ònu¯U› ¤t¦š¯`X[Šw£hqÌù…”láfE¨p¡ó=Ö~ÒÚÍ¸2ë™•ë¿€©¥·tëÑw9œ.F}ıa;©Á*IísUî;x A
ê‹góTŒ keµ1=£ñ=Ãv]GH&óD,=ë?xéáÍTfÄH«|‡°7‘“IÚ¢Iğ´!ÉY		aÕ@ksëCK}cæ|\,vHÍ2»æ%ıObÍfu9ù.¾¨}œŞ-¸H¤¬TduÚ·,©3Gq¿ğ9W|´Ì×ã	Ôôå'™Û˜"#"L» bÎÛğ]vÿöo9Šò=4Æ¯OäƒWï+Èç$ ïl¾óbˆ˜œ
1“"ÜXÒì&¤ı•W$c]á¥D¦,›OEÜv.¦;‰Ù¶¹†–¹%a­_ıB
”_Eè`3¯³¦0 pÅL­s`¾óô»íş-[ J5*EGÄÅÓ1D6ŒÈò8»††ó:gS7év–]ûHg±áÛ¯÷&Â6i4#Ô×ïÙû‡cbµy7Ş|gf^æ2Ró·ízô ËUtÒ*Ö£ŞãíÄ‘U3HI2°›\›Ï|ï…   …¢øvË”Ëù Ä¼€ÀbS±Ägû    YZ