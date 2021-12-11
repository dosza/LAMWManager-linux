#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3204322400"
MD5="182416c928e3837242b300bf6999afed"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25408"
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
	echo Uncompressed size: 184 KB
	echo Compression: xz
	echo Date of packaging: Sat Dec 11 09:22:08 -03 2021
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
	echo OLDUSIZE=184
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
	MS_Printf "About to extract 184 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 184; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (184 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌâÿbı] ¼}•À1Dd]‡Á›PætİDõ"Ú­MÛÑÍı)0CÏó€nƒPq:$ŸæY]0fÏ-ı¥œ-o³ìÑÕìIºÓ!v"Lÿ+4 l½Ò¥÷íoÁµµÕ®åôÆÒlº"%,¥5¸f©Ñï]™älÚu‚™UÌØnT}œÁ£CË§FcN-	äˆİ˜ 4wğügæU<W_È‘†åêïµ€æSÚGFÔ3–#û;FÅ È şc<÷T”©µég+Ğå{=³ï}œf‡.w¹õèì9Ã¹t7ã[“Ó"Õ—3.³	;´*qú=Lï£–¹³VáEŞã`™šÛİ›}D¯H­•…ÇÜA¢†yÜN¹'“	k@ô­şGå‘ObÅí|v­—ïñ¡ı*Š÷jö¥¯Œ›. áM?wVSÂ“umšKZ`,‚€;p±nw@¢’šZ¶"~!æÌm‹ã<“£á×0”U1şî ”û:^¹·Êw¿Ô»»¶šúlŞ›R}E1Keˆ.ZË3ÍiEéòx¿âõ=¥F×Cit¼SC©^U:³v²BM>~ğ^İZ?<n‡Ë(:<]wÖSÈ‡¡BŠï®Kº,‹¸Â›ß[W¬èy†¶ê{Û©³ØŒ@æ¨7ŒÊ\ªmİ‚·Ğù“ÈZzÈliÇ{Ù›wÆö|§Ğ©f@ôu_·y–—0ªU)ûh!*šÃ‹cíuåL Öƒ¶fÛèFÅ>Ï½PıòEØI‰+ÎÉVù<àQ×Q•ÑXâßñk<e5¼áë->®D	“òM«$æFx:•UsV*óKì
§¼Àº´&z|dJ]=%’†Ñ]1R±İjÍB9Ât/ß‡¥R~–Ug•¸û("ôÛˆú¢=¢í«!»ëÓµ`gI÷ÁÈ#ó¯·Îyüìh1ê^òF¬J¾Ôğ­Å¦q<åm0ŒT*¶ZO ·ˆ©ÚŞ‘‡"Lm:Z¨Š%zT’O9ÃX»?L¡kî¢îèbÊÌˆYæippyÊS‚gN£?©<4³@KQM¤–šùğ­mÍeX	–[]Ñ"0*bÊŞÄıaËe©ã7ôaÜ5>/ëğ/¼d¿ó¸R¸‘Œûyì¯ˆúàM=
ëşb*€võé¨6è/
!•ö^`Çë… qçxC QİkŒ8øiêÚ"Š&ŞzÏ¿îV.XòÒ0âwr¡fLÄì>m
Ùv=×Gb¨ÚİM)ƒXP‚@»¥G‘z9ÏÔó€xf¿C‹ªˆ·²"]%W©İ§G@j‡*î ñóœ¦Ïü•xª²óm^½[¶^p°Æ¿ßX*§ÂÛ%ÁX•!÷ù}\õGƒÿgªƒÌç_¡‡ZœEnBµ|pWøZ0”±“-²» UxJ®ÑÕõ…ı>êZ°^Ï°‚=¿µİg,ÙñpR'ŠÑ¼˜c§¿kš- ¿0“Œ«N÷Ğ-'ËÜº>›*o(P%mû |*yó<ùÌÕ^{#£û’c_>´íXÄ«l+¢«)ñ}µ’P8”òN‰CÀ"§J¬W’Ó‘ãİ"è×ª\K~2X¨¡J'Î4®JÏ@ªxæ?1ò	U&ÅñÃ¾ºÃ 5×Ã
“¤öèùÔ[˜ç‡dôuún2|TôR¿¼s™o¡ùsè,B·*üŞ&#Dî8fƒ¼±¬-³Ô”›÷¿áÅ‚Š B¬uæ_Ö¯ÑT$†"›=šJB#äÇ¾+ÂC¥nˆ\JIÆØî2Ü‹ö ãï±]¢T¿‚«œÁnmY^³î¬Uâats‡,”w—[|Ã/äåüÒè×Õ»‹®C¾!C…j5=Ë9,i­9nàâUÅ¬‚ÀàQ?:]Fô²?h1Q mn4JD• ´™{Éå4Új/ÂR~
“e+¿(ø}î6ÔÒÎÔ®O·±°T@|„÷Ï›ey)&³;Z¿¡MQS|{ÑŒ@ì:	m’ıeô±×“:B	æ„anáÎ¨õ7ë°l• UhW-tÖwµÒ§c>ò>v6şÚõ˜_~ñPğİ‹t"U3-}İ¥úe|g}ûøo˜¦K8ˆ+ì€á4e“råS%+bEÿøqé^ ªìûâéÛR©ˆ>K?ÆÈMù*a-iè>üwÿ´×8‹>¡Å7 Rµ\Ç²v)SUqø8ég:1M‚Yób¢‚çÍo'Zü¿Lz?ÉÉÄOçêZ%HaP2k’•Jµ²§ZPşäËãŞğz›Ûô µ	ÿ.ùœ Qİ1eÜë0{G5nÁÉ–=%™E‹oSP³‡Í¸V-ËS
×{BİõF Õ¬K¤rªVš÷L^z2+V,»@Jê¯’…Âoş}'®]©ïÜÇRyÑí@˜¬jW¼·÷ ’o«•¦éïĞŒgÜRt~.\[$‚rN1¾ßåu‰ˆ=gÒó@›½&#ˆ£ã•ú8×5²n8ñV²”¨<óckÁ ĞHö¶q´œx9”«—_I
Ùƒ–'æÕµÌ¢\ÀÉ¾ÊÍÔ|cà¬Û½o‘‰eÓÄÚ/ûÜNğ ¡VªóÛ  /´imó½!DIÔ¦ÌB•zîCÓ20†/k§ñk÷¥H¹ÆàÏ&ÚnÛÆÇ
Ù|–DªtaxIÎzäg:5¯¯uÆ_°†òC~Œr€ûºôÓÉgÿ´ÚXXFc±‚US+¿N¤…åŞfÔC¢è*Òëé¥†¢v†ÔYC†ò™3[P¤„zÅ?{™9»¶Ñªd¡í’ç=‹+øÇòç"—0ì´®ùRˆ(óøK&ÕòÓ•DŒô~šcú«,?£`»ßêuÏMiûà"Vú{c¶ ¡É²€ğÏ¸;ß(°(ïçr-óµ³n¾o‹[iC[ØI‚ÌÇú Y^§Æù¬rˆ‚>n™¶öÎèìÑà­½üé‚<yú?ŠıÓò œNæñ/ö;(Pê¶dT`NÄÆTärN#(ÀUX#’>¹,tiW—ÆÈz¯L¥l.b—"#}®Øìş©3ı0Db+©:n„Ÿ]Îˆ±“ëŸèÇY!P'Ş–¬F”Œp(Ùµ™â}åõ|\B¹ÃÙNlnza¢¸²©ğ{'nRMˆ8µ++¯İZºŒ¹´¦¦4®9ŞD¯¸Hî¿Oï­ROªÖ×‰¯€nI}Rìò0ç¯åçóSØÀä=qİcPŒî<Ætp·´>‰×“8Cò˜MŞ‚×çFÁ`Ÿf[ô^ìŒG¢;]v«ª”q‹Rº‘W•Éœtãû¤¸J!¯Œ:<xàµ/ñfL“Hz)¦M ¼²»}Ç`×aPŸS¢8ûøn°1ı$4‹I((•“"Zrš–š?§XÕñ`…Ë!pÿcÆ[s S‚qYß†œ£¢zºı×NŒ“JòÇ_È5êfbÇ
ªÇÌTOM`«¨¯^Ej—%GÛÊ‰¬=B~‚ñá™1‰¡¼ÇOîÙªl0áÊ‹À§ÃÈ÷ ôşh RÊC²¢ºåQ€'kXÚÆ«/éÏ¦ÈVÜÄÖ— ,vŸôÇüÒå1C“ëşÏ¡5Õk[çr#yh›6#ÖÑšÖwæõ‡{o/ªºÅË8#ã”ûÖx9:‘ég—¥_I_W‚ê»Š%tÛhê#8–ôğgdsüP2‚q.Q‰ OÇ¥@r3÷Æo–J8Æswè5'Ôr¼üÄDjÍ’µj„‰¥•Øì+×
/dL_ß0šLCeSï¥qs”;ğL¥µüò{¡ôæ92D\>h}’ÁŒ¿Õrtñe\ë¿ıEoßÏ ŸT&æø‰i}öCb^²ßì*ğ!d;´Å$ãe®ñc ±¯éÆ†bRšû"–Äh_)P~ªú8…2*ñğÆù”*H¡®ØeoœËGHo«2Ì¾ñƒ®ÑUÿi°~R¸éîÿìµË?©_f¸ÌÓÉ¦(ZˆÑ#‘Ó½–Ûb¡lH´1é[3‡Wp¤»¤ğ²Ò¥Ÿ½‘»¯6}}’,øa$®æ«Æ²tb!_(şÇo›,Š½Á¯¿†‰Ÿ\;„QŒtrr™»À*¬o¦jÍß‹ŸìM]¶Ğ~k ­¹ùE÷ætš?“Ùû1–\£èŠ&ÓlÂa˜µA	Ç
Ê¾f ãÚÂæ®ì¶36Ï•H²“uµhbKsé«ŸÅäÍƒ‹˜è–”8™®<ºMÊ ƒ`(}‚gXN®”iÆsTdY’¡·ÈĞ9/7l²ñxp~R¸NœuZnW©wVëCÀóºáÿ7Şfa\Ã5Iå¿Ñm“ys¥$îõË¬ZÓäİI-é
$V:¹n‚¬En¤.Ks&z9¬¾†*Ÿyp-KL‚"¢Ê£€Äa:pc¯e)Pui[Ëäœç 9;í,Ş3¡õšHÔ^İ(ÕXï´‘÷‹(Ÿ ¥~¢”(Á–Ù!X·‹-9’ ãÇ§¯•ÛÆâ`È×ş6â;ë°È{R;0 &*z÷X]µ¹bÙ…¥OÌĞZ•W¾Ó?zÎĞÛŒtº˜´zCzõÒ„0pIôCé½Õ…CçtÄHQpâÙe§ØŠsaˆ>Ñ,ì“TL÷G”å|‘º
uŸÓğ(Ã¸± ]¸*Ğ° êÿÚeš%ÂÓ¬b>nÅùA³¥-˜!#BùçB1Í ³"îŞƒÙÙõ¨.}£Üz	È(¸ÒèÚu_z S™®-®„BçŞíl5æé
\‹Š‰ÍDŠS!äfMíCö¥y¼oˆÔÓÆk§I€ê[µ=tñæ>‰"ÿOo%	­¶—t,f!"¾°í›[§$2BwsO†AJŠƒƒÖSU˜ádY‡7YvGÖ6ˆ¼îÁ4l6ËGí…²‘Ó·š¾¹ÅX[¾¯!†£.Rj¢@"0Û^›„÷şr Â¼Âøœ %şöaT{d›(ğˆ‡ıôJün¼¥Ò´3 q?q‹õíÄÃ4÷ôdµê¨‰ú	u…uX¼~WXZeÛTø„{´*ÄvLÿ„E‹ùGP‡¨7 ´uºŒa¡@™\vÑ|4–Lk¾“FµEºH
åNúQlQ…5$¥,DIkÔˆ£÷mnØ§|3¥‡˜cÄ“îj§/$xÛL1u^O€óõè{6UH$–W:ÚnÿUÑ¦)5bÒ±3àè2pPPRMò0ã 7+¶Ÿà[Ğ=_PvLÁx
–]s¹Šs˜\˜y	(»Ÿl.·]Z/V‚€xš¼T—‘©)È¯"BØõÊÒÓÃ°ÆªÊs:›öÇ—ª}Qñ‚/eûùòøàKGEA@"[EhîNŸ[S¬]Ğ¦È÷Ã°¯å$)ğ£tm­ì±½M™kÃ}ÒŸÕœø£ÂPkaƒD·S—Cƒ8zG%È6+í¿5ÀÅæV<‚&v[õp’kÜM„â™i¯ğ¯×Ğ[F‡®z+UbîÒıGéZ seÙ¢¦@>ëM¿"}I€-Ë†«Á„P¬=Ê©±’9oÑúĞ³,B€íÿƒ%Cä	ÂàßL}‚ åËWa¶“6 '}àúvYàqøÀêZÈw˜€z‹3Ó9ş7MM…ÊsxšG°ğ‚™/ä2aw&¦Â¥§E¨©n©å¥NvHØ¸÷;éàØÔ™dÙYù	éµ‚æ2Z·½äUÈ4.ºøéOó?ºæ{mDiÏö¨‹÷„x{jSÿÁ^ãŠ[H˜¹Iw z»^1“^ÚŠ=–Œ¶j­z&Ø›Õ6g}Ë£c“ƒh®î¸D³oY÷?İÉš
•Sğïkfıg²¡sPÇK•F©]yNjşªëĞ;Ş\Ş&mˆxy™ËÅ™hÄoDïŠd¡÷©	ÀÆ'Şñ°ô4ˆŠ^N@l§Rnc`ØK $»ÈÏÕ"—ÕğßŸ\Ê7©!
µ^Ôo8‰ñ³•Ã¸œÅ[¨¹¼.}ã*Üôæ·ŸæÜ†íå#˜Sì˜äqT~7í±¦>çRU1µ«u%0 6ĞR”‘AvB9mX€ìM¦³ğ <&öÚ±¼=šŒpÒ¬²!gT]_ymS ŒŒüIW¬SåÏTMÒ0×MGÕx…êÑ-®‰†%küÛIj—ºûÒÜ]I/
:ßÓ+R§øaŠ‰’×~&›(CÏHÌø¹XJÚÎd”ÿnWÀ«Èƒ(n‹ƒf¸²^ş_ŞŞ’0Ài©âuÕè_§E˜”	à«¢î©rçlÔ£ŞÆ1E}d7ªL¶®$ûsóİV0†<j'ªÆAv iĞ;ï¹ŞŒ´\ºÖ@¯5P„OÚ‹ó½ÙÕÖîXƒŞçO]0«a‰/ÿ'*££ôf{w¤ªô$²¿¿$íoí *ã¹¸!ö<rîÏÒ
h¡Ì.aìC.×enfSÑé;kßˆÉ²•CFZ¸ƒÉ°˜íÆ2ÅôKÈ—%úœb$KK³a0,$éR²-]{í·H¦
8ë J¥Á¾ıãàWäıfwÏK®_¦vü›Euv¤Itu <;c>+ZAª!–zÎ Æ,ˆRˆ ÑV×†ÈÕÏÍ&ËrµÒ{ù²îéîå4éPNÎ“ñu ú’fšR~	ßibşfä*°O;ÓZi=mFİéë DòàËµô·”ë¶ŒÔ
júÊiÍÅv«—Vùî®Õ2¸Ó±1PM¨C6²m7›Èü(‘@9Ğô\¥çJşÀ·ßrz[¹6~µjï2Û%Ã¾1ğ®BØ¨}Dï/ñ:‡ºšéZåµk“Î˜QÂ†ïÃé‚@šÚ€¤“˜t©3°l¨a,Æk)¼ÇÊ‚Æï%¬’5#›ï‘»Uõ!rÌòmm<äÏ0îÔ¶ÒaôpŒ¯.jk~3òïËÈjaû.~¸«4‘¨†D!HÔËb2Cıµ„›xštnÛ™¡]³µ3²’xÑ?Y-³ [‚ö}Ïğf8qo#PÏjÒï²-=Ô/ˆ¥wÒ¼QÒ—†ñ¡Ç»œeérİÜEhñ#¼¸Z‰ÊB0Kä•»Qª}¬ÊSø¦Vì\»T öÓõsUÛ:ªâ±Ä­Iª¢Ğ\)ƒòYèv¡ÊM`Z’]
„´û.¹V5dĞE’-/(
Ü<*ıÁ¥6V§ı—7ò»4Öˆ‚]Äğóƒçñx*Ë€ŒZ»Ú%g:4ÍÚƒ2õ
 ±œ«
Eğãw£O0‰Ú¶qS‹¨{ñ½ÜZ:FßB!ÈAÜåå=U.MíòsVønE7¯çÆsîÎ	Å$Y³1}Šj.Ô¿Œ¢nÃAIÿËO‚äóX1ïr3ù<êI)*\6å«ƒı.ÚAJYz9$HîylÁ!ò-¥t!ÒG†qÑBh øOQØHŸAñ¸å°x¦YWÆv;â@ÌHÚT¡/µJ¿ÚjóŸ6BôÚh³Z¡8‡'óçñGÅxüM1Ø}üXwúná¹½at®~45¾ùïâbÛápv›m›SÓø4›TvÑ¹Ú9°Qgˆ´ƒ0¦$¦älÙüŠH<Êv	Ğ0¸#‰:ÎFç
bö$¡@Ï¡˜´_”®mÛ¯	p¾bÊètZ`ß¤SBªf™°µ¬óDMóËÛ|FL1c‰âñäc¥ÙÑmMkUµ·ƒN´ê!–S$QS»)£ç T†¼^f¢’Üå—L›Ë¸ ñıwóé0ùœ.±wÓ?IyQ´¶›÷T9j ¶ş±ĞÊéø9Æ „ôªiZs®\Æª³m‚Ö;ğÊ™8ÿ¤¹‚úã1ccn}]B#³Mª-O{ ïx–|z'83)p9ß!ì3r%bÏ g¡=¾PğÄ|à L6ì¬¸Òs¿XPÎ»*ÙŒÜ?w&­mmri«ÏƒA·'KŸueI<è¾‰†€›±ÈÜ¸¼ÌŸë¨ùY‚™Gø:ø@Ù^ÛQ„ jêÖõê^T†dşÔ$—#oÓu‡CW4E1•½R°Å»—Ş‚¨.7ä<êàøNšQ‡?ŒÈ@=Æà ÎÃ‡ˆèE–—oÖ×¬7ù÷ĞkbjxĞÚÙãY7õ„<HDúÑXF.öèßy2<¼04­pF®% öíòzk(2SU²³k¾Ç’‡&ë1hU OØ:\—®Ï´Ñs‘ºCƒÍ©ÕØefïe1ûú…°ÍWn…j8¯2FBO8Å¢Œ«Öí-ŸÍpŸú£	¡ÊIGı´º«¢òŞî”ç}qŒ(c{ôéÚyÏÉ¼H¹_n°o¤Q™/íb·_|¬Ôl6¦°xNçÕh½efëg»ÑcÓ¾h`¸,r5Ì™Ø÷Ûõ¶‡:>Nû“;ÿ¼músŒ­ñÙ4
0^AŞNhÔ”h¹­*„ÏwµRÙ€&®R†Âö‡­ºCqŒLºÉ{Suş‡u ÏC}šî†lìA}J»&ÁşŠñË›mwÀ+hëùâè¹M	;¹S§˜ó£Q¤¬iÍ³¨,Æ_«!JiÖ†u®œÖ/õ:'Õ6Ş¾rÓm}¥£˜qAAg¯Nj’U½™m *å®Ø§ß¿Qëñ=ÌxCkâãë¬&x=ì˜På
†|¬¾'³Æ¨Ÿİ,$òõÇZ”-jõ0Œ‚Ğ½§îw16<x„È²ë!E<’‹ ¸a=7´·â‡¶n•2‹e†\ Yr ¶Ä1XR.õ s¦â¯À°y³ËÚ-ˆ—c›i¸üjÉf%” ı€`¢ş:=s­AËğiÿ?,Ê–„ãÿ‰'hÎõJ:Ô0ã®4};veƒ¯Wr˜	tpø; &ÂùÀÁ†1l¸zUm>iÕ§Bí,5e©t•N˜vZpaD®ğMÛÍ¼rñeô¹	®pí›,¨î•úù÷oÏL}Æ”‡3túµ˜FÁ¿¶dm—§QÊ5Àì™wSÒÖó—òæÅ„)_–š€£×wqö‘äQ³t^1·º?¢	S¢<5ı»pŸ;\Kıá7uŞMÑ]°ùäò[Í}V¤ze%Ú;ƒ>’•^ö0Ú~úÌ÷i³¯VU¾ô•èuD0k±Hnı¡—fu;6iƒØ'|¦D6^;>ÜÇ¤QE‚V¨u!°†“qéëğ<5…ÓÏù»zB‰$d¯W(~+ãµüßfÂ“ˆ“|æºÄş¯Ú“2GÑımç •»?3éVît'“ù|ÇğĞsVƒÅ	Æ…È›/æ{¿"Ä¾¯°Ç/•2›of‹Eï£–À€Ê+sSf Cè£±ÑLØèbiªÔ:“¡A—>ng+Brİ`Øg³Ú:‡¡X@»æãÜq¢€ëõ©Ûvq¿£/e0Çç2€k[oø¬‘<"ê¢²PtEåræŒŒ.ÅD˜Lõı&hÊ*ÄŞé2ÇFh…•á£á_4_›2m-‘<zÍåi”äbN#·ÈŸä³®L'ˆ÷-Gëöª[²ôeÖ© ¼’è	8•¿<
Eÿø$Íğ—èİX³$Ö•MÇ=Æ-
îmní¬UÒø×ó›€hı_kœíã’gUëf
xƒ´i2ğ±‰•Áün­Ğ®„x~¾-§~d—üIVî"–/¤&qu¡fÉx®’QÂÓ/ _Òt²CP’ù‡±ùcq;\œÎG=F‡óÕxØé÷ÿŠIò…6Ù†!–ş-z¡Dvpzaã8ÌFf´bæ™›Æ‚Ë$;;sÉSØRüo%!á£ŞôJ…/şij{²ÛîHÀ ´åÑ~ÙÄOÈ°h ÅºSä°”‰sñCy	àøX§G=ˆ†sÛHARM‹ÕİøÃlÄómÏsÎøÜ-óÌÍçh,sâúw{Ÿœêşnªp¯ßzop¨›@'*¤Ğä´THwÚ•û›:›'Ë‹$*s‹°"3PtãMÁ©ØáiË§>@ìòDbOaFPdò.;¼Îò¦ª¾šØi½Ÿ­U`gêœÛ4ê«Zv+^á X’agtÚQ*şÜVÛåÌãkR ANQ€xBÃÜˆ,•~˜´™8NU'áw\NœEğ®6“†¯f&(&şv.!{J×í¸ª–ÇıÈJ'‰KÌ]úAİeUèÕÛCŠÇ¾3…ŒE‚gD$ØG—Ûğè±$¥Qì•KšÃ­Ux87"·æ£Õá³QŠÀ—0Æ1ŠÏI°Z‹…Š°óy 5¦í	
däîqìƒı;çÇ4Jğ\qŠŠËş#p#8J
Êûá#ª‡t×–mîì]ßãé»YO¯Ì?Ş÷ÅlNä¿Â©à@hÉÕàß˜NÚ/`¿Bb[`FWOÄ\ñvã“SyKşà³¡Ä%^5Ï“;Äp‘ñvóµŞúÆW$s¢—rùÓ–äEàÄéÅÔA¦AÖ|p½†Áª¡w¦rşIÁw¬7Ô¥M¶¡zã ÇôÖ]ÀnMp Ê»*Ä¦ŸsÔÏÆ—'B–g’®ãò?–jQ|=ô³“ÜÈj]útXàEl"°%–.’‚(§pOéîå#Ğ×úrB;«´‹ü]ĞCHÅ’ëTew1ş´VîüMç8ü±ÏzÑW1O4Öô’·ã¸o=Ï¬V£9ıyáÏn$<ƒç2£‹×Ò';É1 •ü¾GÚ&ÎĞ@	ıE’KbgŞè@)sÉ«™N_Ë&MÌMe3}Û{íú¯ß|~sı³,„Ì5<º‰!³Vèn=~Ñ|A½:?2$ı«İYâÿşäàÜMùâ‡²§—–ŒÆ6eÑ#†¸c–CTXÿÍP²ä›²¡.}5O”F–†¿ U‰åV›S#ıOñÁ‚ZÏ/dí¥LÁãùVÎÅ‘5¹ÄV¯>¡pZÊãblá„´ÃçFf(õ¸P½—ä§Äï^˜Ûk:~‡¼g“ºCMú/j.Å‹ÿÛ(g^…x'7D©P)vHï‚œ>F¡«Ë†ÂMw
°F7e²/9H5üî—Ò§xPğLz#W.ªRğ:äaÌ(ÒsşÛ”±Ì²tãïÿõ<åÛnkw*ZHb“"¬xòJ´¹oö ‹?L7õXâ­ù({ŒTVñÕ™ŸóßßXˆ&™oFÙVĞ€Ã0{~Áh§·ßÚÇ†8HOîaåC>)3Íİoh‚¹Æy~,[çv¦Ík™‡|§—¢»©éQŠÅ¢àà3•`Í¤ñù wémªººêåæÀªÆ9L‹ç¨Yç"1‚êÂÒ-öbŠ"‰_A>âÒ¡cê[S
NÜç W|ˆì/p,`™ğDl%6–*¿&ë¼Ì¼+@ÔàEâåòók‰ÚÈÊ+¼ëç‹U˜”sx\C‡®^â!—Cösª|Š,fIU´lğ>hEÉGjŸÕ¦ìFÜ1ü–'â{Ô¨˜úÔ¡o™+n~#Õb³Ùı©ïZ"<ÄÏàSÃ»§ÉÄ¼±˜JUzäª^:ˆ$Œ„[ÍßØhÓæAªzoŞ4YÁ\3|Ş.ë4†pvM2|Yw¦ó:ækòa™åïƒ­âue@ç•)sruMšÙgäO ÚŞö/-Ôb6Ñ«ŸêxßáP°@º9içíÇ¡ê}ı‘2Ônèh5æÓÈÆ)d¦”£
Ö1ïüç„È»\¼$e­¨1İ£œ•TğÑ¹,ÆR¯B×Õ4ÕE·WjÊÇ¤	©i…å½cÅy¹ÚræÔäÓÉ`¢Müâ&ı[ö€âÅİ¡WD0‘Y}(
’Ë+îüJà[X”r‹>D»Ã¯_V5öFzäºPúìStJÊ_Ù
²l˜¼Àx’/Ó¾.˜2ˆ$&/ñü§”¨À¦¬`tÅñÉŸŠc¸4’jE™jR×¨A/ë¡³"2¼İ©'@¶wR£˜gªÎÒ,š½§lë)G\kÆØºÅõÍÚ(RŒ*Ã‚@‘PF3F7¦ãYßÍU;BgæÌ}·øíıÆïšûÕ
MËZÒŞb,öp{\ŞÜÙ³wß×>cS~Ÿä™Æ§ÛL‡Ç/â[mÅJ÷Éw[#íÙ’@%âcç7ó \ÎYkû-ïµ¿lŸ¿U“ ‰GpO?uÈÄN‚Ğğî`Æn€'£Ø°
îšê®­ó°Û&l¼8ş‚„ˆl2pàÃñ‰£`Ü†g«:/?À®Vf'½á½ÚyÉÂ2Âÿs joäBuJå‹!·%c”äÿâ
zè‘Y:’9x”×ÚC‚U_IAĞúyeóÖp`Ø$å(ê¬•>^6ÛƒÊ‡³_ådğı®W’s· Ñ¯×&}O Ô|¾IÂ<—S"3Ø/‡¢ûª?£G
nEi\‰ÒìàBA¡ çí?&l¤ıhè¨«úJı<tU¥\#6ÌfíõEÕ(R}MÈ]´_æù0ªĞÀ_uH—ô……şcî±Ázæ•Œƒ)œä”ëäFyµÆŞ ›Á™åŠ»e­4(ĞÒßô‰ƒ-Şñ`Ö/L ó‡Ù„tÓèŞuRÚ†Œ6-\iPŠM(û[j™ºªE‹š4!ù˜ §mÖ.hxÒä"Q(Ñ¥!i4N}ò²ät4fìn½\2¯>h£0×(úIÆÀ¤æD`˜üö)´^Ÿy+§©H|ª€ı‚3zÛÌ¼§š5á—ÑL<äéïUa©b©¡ö< ™=ÂT›Lfîng^• âŞÂµXy{zF&úgŒ ÿÙ…0ò‡cL*µ8&†ÑÒ?…â°
~PK‰Š¸í0ûb)¢5â©òA„œÎ!õyU‘&VÙ:ZµQ¶,›bW¶2ÈÄ=‹>#Û®÷ËÉ4§Vğv^ÒU°Ò¬šlêa{ßFWÙë‚›	ı*ôvN>‡ËCµ—D–}ZÑY¾#=,9DÉ€$ŒôÇ¶Ó»ÖØF …äP•c§TÉSdM_è²ÂÌÍ2ÿÅ9Äû½ÖßÄUl†ÅPAI›Ú¾ù=„øßHÏ­MÖë
8„Ó)¦[®ÌÁò*’¾†Ò1®½ÂÍmÉ1 ;¼OÍa’ì±@š£š‰-%³dĞ¯ºİr¼¬V¤(ëEQ³r(<bÏ\=İşïËIO/;ÆJQÉâ„c$Få>[¥Zhßİç$nØ·*ÇSŞæ‘ÖÎÃFÿØs.¹ŠK‹º5ÊŞGøå_¤Ù|SÌ†YŠ=Á€ßÁËÔôÒç?èéi›z=”êÅF>­éeÁó-WÒp½¿ºİ±%5šZâO¨×Ò‡_Eå8Œ¦™E<È¦Ñ+½¶/tHÙ×¸­sã)öÃ‰á%«sóifõ "|råB*š+Kåg!ØÙo¡ÁŠxKÜf!¥s„•âÖTÛSúcó,<ŒOÁš@Fƒfª‡]µ§X ¸•&~Îrª‡’šåT°c–©š¦œéïmœ6vÏh&'(!Îeô,Ó†ÌÙ”=çZ	˜÷ÎPXÙßt½T^{D^+†ˆŒP}å“_ˆÁ|/öòËÓ.®ìv8Õ6P²®g–)±¾™ëO3 ñM»#@ÛüÛŞú{c³|»db—LÆST/í¾uZâ£KFvX&}!-bRmZµHM ğ2ıÓ„[«æq%KÍLl€ AçÃ›h@ûê¼‰°µ[îZàÔ`PR!®°Q›5)ÒÒNkw.Üråi0Pl÷@1Û5z0%'Û×%°OKß»¬ä¸¦ÖÃ|C>Dâ!úQ£ú‡4Mzi^Á…Ò—¬„f®ìj‘üBÈÀ‹œÔ—·;yñ.(¹»½ğ|¢'3÷oQ„Ÿ	9ğr¤ĞĞ=¡èˆ6©@æ2g„÷¢k:È¼ğû•Eó‰ª†N§B¿×*ã²Q1hd¿!\9uºL|ÁŸ‚€-Ïî
FÕ{-:NÁ×
ÅØÌ¦)L* ãÛs¸)'—

™=ìÎî@sj‰Å±ÙµÅ~m™î¦a« ÙÑ)‰E|gŞı±H³ç©í{}UtiqoØº‚A‰TÂ«{~ßMı2âÛ¦Ç2JÖç4¯+òŠSwú•­Ö‡ÚÔ°´Tà~aCNQ9ià¥·;Bé~›ÄmJwgiĞ,œğ¶`,<ÒÁğèu,Mªcq“´R÷_%wúG­458éÆká¨w}ı]¹÷G7·±´İ°6yİõª„ÄkÉJ’éá„P*Ûû¼uÅl~ÔËæIËğIêğ­÷Íşij…ÿŞ|\,–&ĞÍ4i½¬®./¨œîˆìFâ|˜»ÅÎQ&§HÔ/Œ›¨í¯wù’Ê;}~˜%Û+ÓZoä\L4ÒFŞ*ä~^øéjü¬r{u{6ÚP\Z±c€]vx÷œ+’fşŒ\íR(©*Æù40§“
5Ğ¨û=eedôn©÷µ©¢[	ºÍ—ÄtîöÚÖ0×¡”>}–jxöV‘Óş5úê—ú0µµ¢+/È¿ zG†¡n{a£¶ğ%;äŸh»—İzÚr[7™°6²‡PÿúûöŒè ¹±(fë=;Úómï8^ŸÉù¬8Ğñ9äöªó&Ô»Q¿TÂë
ùD$»MN)E´?‘I0w¦ì®ÕúòwsÓ3g4Qû¬ø:q“Éjc<‰z¡«©ò²G“Eæ²ÿ¦-ÆE¾%¸YÂìö6ÚÃ!Î‰º¥¨±œ]ÚõÄ_
"1/üš*
FÇq¬ïs/Dp˜÷œ–ÿ'4Ob¹z‘[Y‰³ó‹(–™È³²RÅmÑàéqd‡`êËÀÌR¿&œDGö"-rÁ{ú}ì3&O9ÙBFdòÔb#JâbM¾£ô\Ùïé¾¶-^EÆâ×lCÉCÅ ÿ UÏSÎfğFO¹>•áeí]˜?ëòºÇ3‰Uö˜Z× ëÒ€8änµXgHÊÈjÕ0E*^9:ÓÒ–¬¾%6¡½;*Mæw™×à=Ï"é3××î‡Š)Óõ´\¿L’(ŸYª-vSÖœ{·Ñ±¼é^féÔãâšs§Å—²ÙèzYr =J6Ÿæq [Í»ùUZ­r "%ºÉø™{.¸ën:m+÷Ğá»°€‘äCè0Ó'¤•²š6Ãİ<ºòÒÙÿƒ<Pnw(f“F'‰W” Ôà•Š˜‡èì~)-’-¬©òe5­ƒøÜRÎ°VÆ‰•ßÕÊiô©ì]à!ö€À7Š±wZò/~åpïÀíik³Óœ<ó¼ïÌ¥Ò÷ÌŞY]Bwï9y†¶öÎ^_…ı+B^§ÒªvÄºLP’ã<+/õT¦1³EÌ¾)h|9Ì¹„}iLwšüø;°RVmˆ”ß,îéck±s´„!G=²¼9®îèFm4ûŞ•í'/Â®ç¾ŒÒ(¡ÎJB3m¾Ÿ*Ggö§Âõ<ÑL°xˆ;Z"†)òSê¨|!$È?¤Ôbf¬çV½ë}ï=›F&ï$QuÒ·é:m¢#‘<“Aå¼—Mâ°Mhõ°ÍlÙî’æJ¦²°°;|3¬uì÷½ğVı¸µ_(ì7Ê+«ºİdÈˆ™¥ò¢ÑdÉ‘ §ƒä}76Jk £4¼öÕ1nGb€ïNı´i™ã*@`¢²sáà›†OHş²Àm'İ“ï¥\q…–®"ÃK#p¥FÏ2â•i­´óÜÍ›´'<n4‹“J˜m€ªfy®°MÚËôĞ9(HrÍÎ
98iª Ô1ôsÂóÚvOˆcH0[ëmiğ™ªnÓ!i%ñLkn‚BÛòád¹Æë0t’°¤FçÚÁH¦ü±<'Nv:Énæ¼uÀŒÃ¿Î—2/jhÜÀp‘¹lï×v=Ğ†Ë¶(˜í‘Œ G§OLçjGÚDğ„æ-Mş¨Kcš <ÆS¬èuüZlˆÄğ{1àzS"Öœáü¾µ@úù¹ãÿş‘ìs^“ YõCÇ¡üÿ[ŠŸ>øØJµBé’R6FF|nqBN\ˆŒÈ…İ©ûi¡Ël¦­*°š/³yrPfÇÆ{·¦O‰UzíÒÊØs©/šJRèd¹ô gøgeŒúdê½ië>ôï§ëh‹ ış½ÎÁk,»piÜú×N(½l-ÒÜ´ı’Bï:owYFZä&•âA­©±µo¹SÈtcy¤?CvÏ×çÏb~æº°½Ò¤nDyÆ“Ğ×oÏZº$7åíqS
¶ä¡‘Ã„¤@ˆŸZÛ5qA+W/½¸á®ã	«œbÃá’,îj’³ç;Ñ1¼GÍîKoé÷¯ÖÓG%#È±ZFÇÉ±»óÑ2TĞË±Ö÷VçšE·³\ÔnàrÎcÊè|EoıâÔû/6Í´’ù0[2&˜rÀ-oo³¡İ>b¡>t<ƒ	ç®¾ˆÉ±n­Ïrm’eÖXÎXtãá§%ø0ï÷ıòª–İEÇ¸ÕZ°ø¹†„»£#¥+mØëNÇh4I”ÛCKh²††²û]'QZğm¡P¬ÒGÑV/”œÅ¢¬@®›W¤„Ú—1ùj0ù’²ZÎ8©ö\€‡†éÁf)åõecÁÒ&¹gK–­#?Vßæİvÿeµoú ]êá5ÇW¿y@D@½=_äğ.iùtUlœ1Ñ´jæË†{Lçç¾>ÌB@-õƒçz!ZÛÏ®ˆ¾×âñ[1û¦ƒ±éÏr%à	g;óĞR*k Î×îÆá*8“ 8ˆü„_Ñœ‘ú~œß+;ßnDµàIåê®ëÕ–[Å@ĞZaIwÛº\³‰ºÉ‹2†»‹õ~Ï³ŠŞFŞü¦/.¥–×LŞhÜˆM¹H2F{ô9áÄoHMD\ù¾)Y™tÖĞ†A‡
„ŸK®ÜVß¹ø¬ñRùôŠ`¸CÓ«ÏW	hÍİër¬ŞÏÍÔİÒ8Ôÿ¨—eØÛÜp]w¡ÕL>¼O'q0«¼”õrÄ¸,’VÀ]óRC¿ñµ$IËT€„pÄ”|í}F d aÖ3« Pİù ˜9×{í—J>»ö¼ªæ¸g&ZÊ³«C®J€ùO~e±6“p(ñQç1Î|«>°äEëeè\`ã.X‰‹á«æU]Sğ*tV¤…Xê…Ñé&‡ÿAÜ¼N
ÆK
%¿˜ ª'Ø|}:×7½¦VHßoÙ÷º[¦Øfí•ÖP¼Á@GSÉFb)-˜ãZºço×WYü†Iä¯˜ù´¥¬#ŒüµÊì‘•6z0ü©U@šc‚HQÒº3I:ÜÿJÆE9G`'{"»“!ÂRº›QÌúL‹ğ/•`}_Êå”ÈßM’r†Q1œÑsym’aİIQ‚AÁ¾Ô²EŒ@ué°ÍÆcZá6fiZq}#’ÔjQ,9†¶Ñ!(ë¹—ÉıjB p69ŒŠâl„M·1‰G@759"V¹$*OF¸TßS’T„RjÓJ‚ªö)€õô]¹.j‡cÆRÏ –®÷Ş4ÊŞ+ÅÈ
'%FÅtºà.hfÃ‡ß*¶Ÿ„«ŞébÊWÀØØ2
¨@Wì³ı~!„W»“_z¯4©r%`U¾Y ¡›‹#)j ØVçUÆS”$¬ÿêùÜ!'mÂÎõFèÛ6qTı–«¡>Êºlf×“{gÊ‚á•!£«6¦$ÒQ-ÅÜ÷CÖêGàêîŒ’¾İj;÷b®ğ±hft!:*“Á,eÊĞùx2ßVRàFÛ_şC˜äûÑ¤Ú8	Wk›¡4báDt0I=ÌÚÁl®Óh!Ÿš¢OºëOé1€U4‡£¶—Ïùç[µw8?"xv´ä…~¢õ0yjù1$µù…Ş#{zl]:Âú’æAYvQKpWÚV¸€V¹øZ—b‹H»ñ¢å0²­ò=yÅ==kŸƒßy&{dËé‘ªìòcŒÖˆşA¦FKÁ	$#ù÷âƒñ‰êtë€'{…–™4óÅÿ‡D÷ËãĞ/ˆ‰¢Wøø¢ùpäÇ >Ñ­yŞ ÄFNà!	nÀR¿Nç8ŠœïÖ¤1hhlë
ªNãÔ)Àúu%Ö=ëèË+eúÔ745ãâ›—²“!ä7{‡bi¢ÙƒéÛ4ñ"o,Bª¢$6Úu¬àIZØÓ*&ı¬ÂÄb½¬Ñ!Î	dúüŞßoGrqErÀYf©¸AK‹ü‰½™½æÖy‰ÂsÈİÈĞdçŸÉRU4k ÎNŸqKuÉö}uï×J\—ö‚ôå52ì(ğ·ÏŸÈVÇ"z~‚éÏªA€.”UyãEoÀŒcÊëù<ìÉ††İ!<ñ*•f'C¡Œ¸^o»%*o€BÇ±Ñªqå]âI¦HöŞ)	;¿^W3n½±>¾ì¸Ò§³E…¥öË_eÅbS¾¾“:w£òÚ¯~ºk-(™RÃmÊˆò&Ë°ú?î  ÿ›éXÈfÖC´  ¯¼Õ¹#¸·rpä	Êô¶1ÁÚÄCU‹¿»€÷Ö‰mqvFO­±\C»ël™Ç¸^uQâkf?TãÊ¢SLëwÁs‰åÿ€aR[ €$‡Ü»6ì´İûxˆxnP/È±M[¯Ìñ«a?èz3N}šë€r{vsƒ®ÏHƒ²í–k×,«¤3=g®»€KL;ÚT­ùhR«bË±b7:+ÃvÒ±ß&ú\yZĞ¦R2äÇ¨˜  áÄÍazZŞ]ê9r1B„ÆìÌÈö¶â¿³V~Ùö«K\;Ğx€'®{fJ7²Ñn£~SûH­ê¿	—‰kÔJù:*¬9ØÄÏ!¨ÊKT½£¢#o{ ¼‘É>™E2Pœ·;V¹5ŒÙ>Kà­êö,³}Şù^AÁËŒ­_ÚxDu;Ú‘ÈœfCû3àÒìpF|$õi6.UŠ.b"ñ™;.v¼k¹âˆz6[¤Ó*ğ¦U|§ PBÚËöüez‚‡ò¯ÅoÈÍ˜¼µÎ‘‹"ßÈ}d7æ´ôè–‡ª=àö2ï?v,(ø"‚xY*‰Hdj&+å€¦Wí86¬Ğµá¨&¤ySƒ2MWÜêádFŠ¼.!˜§u$5½,dÚyè4§n’¶×œÈ:ÿf¯§ÆBÕ»^g—Ê­±VËM ¾ğ‘¦êIÄzN¥lÉĞl–¬8f>Á}ïÈFãªÎX.4¥‡0VU€P»Á¶iƒ‹+É´¼j\íqß	½‚ïXƒšÊhmj¸`U5ƒğ" Š<¶Áy=»uÂº#¤H L˜§w–DÔSS–³l·Ò-Üärîaó©éLbìçÚ!ìÜ‡mNmèÊß»ü\4ËÔúÿÔkÉÄIäOôÂÛ“KL5Cà©äÙíqK‡Õ/ÆAªLp+CÏÈ–÷hæãµs\n°Î¥—Ro	<L=#f³‹J;•]¸…º8í4™b‚âİª½Àº÷\Å–§èßvÿ%ü‚3	Z¹XÛ'Ç"©ÇŠ9Œ÷ ´ı }”ª0‚Èñ_yÚÙo[C=eº5ÌP`Ïá”ÀTœyën€a«y­ä¼B<U€®Ñ"1¦ˆ I>&Í _ÃË{$‡2F÷|vÖÄqŠ¸¨»P.¿×‹
¼ƒs9Áì(İ¸HKÕV@²Âì¹ï0œÏÅ0'…s+U¶wåøU®ÎßÏa¯Ë•4ú²Ÿ„§™“	–¯áEMl,Ëæµ~Ç·›E  Ê„®(¾‡{äï² Õ1›„…¡‚Z\éÄu´áQ	Æ*«oÂP"‡™H…N9„n´õåd5TãŸQ‰ÕTkMèxuª›à“5iµl«gW*ğÔ`ÁñGT†<œÌ„æ£ûJF“¬ -i(nACôzŒ—.¼ª«¿LZ‰P¶x,ÅŒüxğ*JŸgFUæŸ–ˆ…pLB§Ûâ•¼ÃF†¶,kÂºë—HŒZ$»Ì¥ò¨Ê!‹B¦ÙX ´¬€TÈù´´#6G‘rrsz.‹µÆ?%läõUıPê€tÿ¦ÚÂ– ÉÆ«©$ÙBJHÇ}°¡”&o?+ë˜èe%nÒÒÁH<)¹­=±î5$ÂXÀEªîj©¬è¹}'ï:0ˆàÎÍ¿xGmz—å£ø|U£~àíÉeĞ] ëF-M”êdE@hğŠìÃÑÏ¶£›Tºîkg8¶MR+V«^¦Î Ì”åŞ¶D °œàGå¾ƒPƒlLBàËî}$jL‰ÄĞ‡Qe(ûÒ2ğ/p¸¿|[¼2ï\±arñĞw'LêºŸÇ×ÜØ`œf7p€Ì¶¥0½ÙM*sázØšxÊÒëe7a(İ7Å)¹úAná?Y™jµ7êRå‘j‹	IîÌİº4g;\IeÖ›ækxôZó…A.’ÈÌp(•ŠŸ(ÍµŒ}éâÓ6±ÔÛ™€Ã êHdÕ¹o]Ø4*ÿğh÷ş}¬'~q¿öF¬k	µµÀœC•÷5&æ0’DØ[©uşZëvò™QıòàÂ"jğµä—ëg^0Œ«¨awg|L§	æì}š§ÏIÒb¥ºí}²c.Äèû&fêdó ³0[‚5ù¼–ç>1º÷aJS_ÿ‡rwÏáõ³E
 à®µHø¾işNFXÑëà˜;Ş£ãrONÿ±2÷1ıdAÚJczàÂê2İˆ<›SoÇœ5İå û0L¶—VFƒ¼Ö@c­‰~àØ>èĞ6h«®ãlJ{otzÎnI<exñEzú8–TnM-+iª¯É{¬c ,ïàù/™ü‘òîfSl
"»†=‘d¸,WRØ?ü}óóÚÔb…¡?PŸC×HVöSyFÏÇ:“ğšèîİ›(æ'íœ6ø3¨ú÷Ø  (ğÓ²¬ú­@Ñà¹!nàşÓç9¸Jh‹zÀÓ9&Ãf<Ä;E';1i*K{ğ?&i{|Arš¶¦Å´)—2Ü:)½Ú·Uˆš[ÜeMm´, VãAJÛ!5–òD(<ŒQÅsgò“`:á{NQjc¿ÛyJŒcgw'„É!VØN´dì;ªËBıĞ$UL.-àÅÒ*2˜‹ÀŸp8º]Pñ»Qrè}zhh¢„â¤½dí{ §P{Yxúù å³/F®F®w®ÒrŠJú€JV[(gÜè¬ç'c/(_oÁ¥“xûÁA‹ÖíE8®·éÊû²Š%ˆä›™üõ‡ÑÄ¬>ˆv(ZGP]Ò.'ätD­[*—W`ÀË‘¶‚X¥ÊÚÌ£ïp,fÎÚÏ¹YH;ÚÏ‹?m%T«cAd ıüö|:oÛ­94d-œõ*°ëƒ—déTF:J,8%¾w	ĞKO
êì1\•¾X¤Ëª}\R_Şº|lùêÌĞúbvc’ÉÁ®³¼ä{–4ë­º/²n‰Sö}ÍáFö1¿Ü+$fiQœ‰İÛ"/@u¡ƒoú‚Ëiéşæ$ØRw	]uë—ëò.XC£ÔEİ,å/FÀ@İ˜ŞSfã2²â(äû  fôÒ>ÀÉuv*ï ã}µ`Ãçóf2õ4¿£á“üÃ(Q©h~É¨ıºWDÖJrÄ-ğ
«2şSwŞì/úGH;© ^¥Óm¾Û¦°KIˆXŠiÍH—ÜË‹±lbÅ‘}kb¹)˜Ü7¼'UJ²¬ø¹«È†«•Ò=„"s_Eë.ı8¥U ëŞy­r÷vñá‡Ò‚±5GWÉ¨2»g£…åx8ş}BR¥;ıùºW6cºmo«ÍCÊrEšåB0øÂr~5I`-HMùRµÎL\›†KDZ*»3n&)åPùõ´½µk”ÚÛ­Oùx§±-s@–ÂŒfq_ÄŒŒÜó–}"@‡{vçV9 8BÎû â
¶b$´ó,aŒ„¨{4næºÌˆÀg;'±éöSÀ|k«­ÌCÕ…¾Q†¨ ±k¢µxikßöŞÕ"‡
£ÁõIøËYån+ñ«ÁpÙùª„ø…>1â²öİAÿÙÒ¤¤Nò2©
O5mğÔm&ºñhÇŒ™"åâ^Â9=kïhŒÌŞ›e9¸øÌQi2/Ùöó­ĞŠø¡jÑææŠåŠ±.«UvœO±Yÿîµœh÷	Yõ—[8*Xÿ€à€,0vEKHb«˜”åËSÜé¸,#LuÅ <¤¥“+Ÿ£òõféF‘)- !IêPSÀ¥ÊAB	€İédŞ†6=“À0_ÑóAõDvP©¶”»m|òEô“6¶‰]:Œ»®'8Ö¥àëX¬3Ò!FS.Ë0©œ>3°<Bh}¶Áêƒ¶Øn%d©u—şJõ7ßùîİ#¦!îåb-Ş¿ÅJ)|Ã°>	İ®äò‡şú¡‹¾GŸ§Fãƒe“Í†¿£K
¸yIÜü
ö;ÑİËš¦ğ
ÛÃfJq†Íâ/1 ƒ[éLq§…¥ ´mX«Ä¬ 
<‚‰UÆ;ßqIş¯)5Ÿ"ÚC T!ô3›ÚŸ¡×ú›x²K½®ÍÚ«Ÿ#chİõu>
ul'«/çz™v·«J«Cœwß¤uJ J‡D0ïê«‹°|¨<¡»'ÇUÔ‰tšu,±Ùöœöi*@w€­¬Lª“`Pq‡¡:Ç¦ÇEƒ8İQ´"¢dä=!j|ÎõXLœì2ß3ÆéğÇ6ìáJXiPÃ3à~‹ÆR8©dR'{)L^üğ{LÌíı÷Öç<«—éôbÚV	jÃµ#Ö¬ÂÒaáî e³'š¡AÜ$C[OmbmaØ,iLÅ&èŞ‡„|ø9¯°¼luÕÆË³'T¾RÊ5KºÆ·Ff*Xı´ä1ĞÂê‹ü@cƒÒ!{~˜å·Ö˜›ÙÉq’a9[ı+„¸=æİ]uÒ­~W¾ab†÷!g'³NV*Wl˜‰ù-‰ÉÓ®ĞŸ¢*
]¶+¦]U?Øúÿ¬ÏBÕI¢…ı(³Etî8-‡"hÛŠ«0qA™G[	-	ÜŠ˜²FRO\ßn´gÍŸ‚©$[Új~-Ş?@›åi{i ´·wÒ“Ì¢p^#ß˜rã±ûĞŞÉ×ø9+×èìşµ¥l­DûûÑPíıí>æ×E)=EP¥zŸš¿£×DL”^öhíEtHÍ¬ç^®‚?šrB8Z«ŒöĞè*v#8šC'rEˆ„¿Æ~¿^iÃœ^lÈs®µDLÿSÄ„ƒÓ›¶T­´™‰†:İ|éïl°…ìüê±¸]ıI=š¹Òã|czÚK¨ÁÛşìE|=gXcG)‘#)ö o™¥ÉÒ1t_ºXÛQgLÿ#·÷	3¶äq.èUDƒ1,º4ŸŸlrr$Çq1„à‰Œ<÷rYZnd‚¼şi›ÖÊ;c¯˜™Åô!ı­ÇÒ÷oµŸDËŞ/8R@\7ÀºB„V0ÆFhKõÂÍß4C~£çtTSz°êuê ”ZÿO`¿°zL>©WÂ2ôIŸ4\•âÈí˜…XVvµğm¨0ö¹'´ ›,
Ú‰êÉµVã<µ™º.6^J%\¿ëq[4E	É;©OnDu<K²l"æ«p”ãöŒ2Á}Èôˆ¢-½y£‡ğP%‡8aa«,#@€ñTVùe)º`é³µ^;†ÊE¥ó ¾º4M%sÁÎĞx$Öø3ï—”&PXÖ	u9:Û~ÚZiÃ²‡·tçÈßş
ÃKeHŠEF‚¼
7IO@ØÒı¹7Ú ÙŸ	wÏº=z'(WÒÊÔ³(°)8•O×8lcä›˜á,ZhmOÛnsj w¥ûÉH>_úƒF t,ül4maùYP!Qê” h^q]I"ğØA"XZ[ ‚b–ÓMª|Š­_~Ydeğ–Ã™¤™Ïj vãVĞX-eŸ`PµŸ/ß¤†mwÁoÉEo4P–@æìşÛ`·üz„o€„ÈI;«Š-^Ñb«Àğ¸T•Fd•\Šaär,ü‡7ğóv ‡Áºö~&Ò!htŸoòŸœĞ ºsŸÉÃj¤v‡1Bä‹).î#)™:²”Ÿ½‡sÖzê‰™¡Æ«ôg°pƒ€ ODZc4÷PŠµô^iO"ÇA ‹Ç”u¢¿;Qüæz¨•¤.Jü±ê^D†ç>ˆÀ'ú)àlœsSä_^}<v”}1+~l
+„1Š­*[ƒ ı[U¤)£2xo½_"³ŸqWƒàæ ×%TG5¨K¸àï1bÄF_F—¢Â’7å;d¿ßSĞúë’„xqJ›_ŞEïM¿
rëvåQ,u	†©†~¯ïpı||iôFR“@nãYúŞX]1»Ä!PğGLVÂ4’à~m”FIV‘ºÆ2(_¤LWØ°½q³¨S1NàèELÎ‹Š)TÅ|«fgı­x„Ë¯MlåñÇfÄñˆnÿâQzK@àåÅÑ‡ÕGÀe¥Êáı“S‘âr¡"²êõ€¨¬‡¢fÑÖ¤¬ÿ¢åíÑá­€*$ŸM$6'ô²lrµ <MoG¹W…CŸò:ùÍbŠ‹İvtü¹M=OQ`7wÈ…y‚1Ö¶ÍVÃd-w±væJIj˜½—‰±Şü·IC¥€|,¹:ĞYŞUV’Ôb™òznh,tX6{Æ6o9J¹„Ö¬€şQ¾¬=;è;	S‰ô‚
mOÕvîhÿ™qœ€†Î2’Êw¤ı€õoÕsØ2ú³INIêK}Tù¨€9nYğ&	0±EëâÀ²Í¶é˜¦İ-}ñîcË„\{Wx€<‚±Ì£ŠïİªtÁÊ¹Í¿ÆÀƒí¾…!CÏ¤ÏÍèÏ	Ñ–é£»¸Z´á?·4ãÚoÅÍÆíØ°Û/N¶bU/ª’(¦¾Û1iV<÷>¤037,ãšf:Â­V›B—™{e²aèÒØ¤à;Æø\¨r‰÷uMÔQyâïĞºÏÍoû0ùeŸµ{Ÿ}Ÿ“ì¾P fâT‰N@½îÕ„.\°Ì·QD>lyQoôµ ãú–Ï`átàJÚø¢¼/öÔáëàBùÿ÷yIGV-çÅÆèHb{>ñài¯4ÄÑ¦9yü>Ù·äÿª†€.“9!¢Ë†»TN¿B|^9EŸpÅ=Ì}kÏi"›¤W;°õĞ`újµ¡n­í¨Š+±ı¤^üş^:­¨y‘$Åê/$ÕzT‰ïç—d¢[œXìò.ş|Ğˆä‚İ¢¾Š!ÒUƒ^¶¼4s2ÒDr6eWÜæßˆuÔ–ƒZ™Ã²…aŞƒªÍ\TıHüĞÄ¡/æ3#N|©ãÿFô"é<ÉN®Ş _µ}ûŸÏÁ¨X
³@ô«ßôFú½+™>¾ıışò‘ØŸ™[Cy‹cs¦†EWÿš3¨şá¾>¸pÄánh b’1‹{7k5!’ÁÏp)u©¶§Qáî·=¡mŠºÅ²ãX§aÃSš-ó)Ü€?ë˜íÂ0¶‚Ñ=Ñ7Ö,Ä_‡0ÿ\;í	<å/nŞÅq¥¿í±Ø–u ±ÂZôŸáx«F€ÂLîy´xÕM@ yÑàî2xÆDX8+J4`w½ÒY›_JÁ…9y6$Jahè2++}³ÆÍÎc;”èšPZÙÂk­½Ü`^ª:|eJQB…1™ĞM3¸ÚAhÒœy¿ÔöˆS˜V S€o†w‘q «›šFè÷íYš"k+nTàÄ9³m×œ¡şçê_JËêj+Y·òu”/
¨Ùè²G."Æ¼ŞÅYg
-9”†ø7™äóC® P‰=Zšr\GˆÊt¥§‰LéŠD<àÙ Énb‚ãê—ÄB7üšGîÎNµê-H«1Ä_ ¼Û+qó÷U”Ùã¢:cç_eŒå6?bE¸¨ä;Ã„+=K‰ˆ÷ñŸÀÕÎvj/ú„vf•²²Á?A‡¹ŞšA°¶¼ß1R"«¼h¸;!½¬i:|PF3ŞïÌN”€Ü[b9É8ß}èSƒŠ’oNí úùlíœ_®	W”ìjéÂ·ö4Jx¸¥½%ÙöfõÈıx^·] Ü€½õõŒtÕ/J‘dó/ïW6ƒ¿5ßHÊt<M¼[Q¥ì ×‡?0f•úlËÚTmèæk,â{èíhÛL/ºñÊ»•Œã5Ô~!RÚ[Tó€á¨-!£`˜?)²\¯+LëÓí q50!ÒuÉ9Ş¥÷²†ÒjÃ|¸.sRªÉÓ.‚{"bœ|7¸x­äj5FÜıàêæÒ~,'ñVUx[®fL2™›™CáU²î@<zyÔÛüC"Š¨C=*f?T¶ÌÚ6"6o©ôÑ0ÿ’k¹¬ÂJùõÀ½i™¯ëMx¶]Ò™ENÓıxËe/©ŠÔwUq¥(Aól!û!¯ö§ĞŒ.ƒ,¢ó®ÌóCõÎà™Bés‚a»ÙÃë‰Älì\ƒü'· ã5fsÎ<ÎoUáİƒqõŠ€İÃÔ!U¾HaG|V¥4e\Ş±"[i¥ËÉ²ê/±&Ç·ø`í1óû~zÔßâ‘ô¥Wòß
tÈf=5í”entá6Cí™:Xë"“‘í¨ÅD€Šéw÷R|%LÈ°ì5ùÑJ¥'aY»7d7¯¼ó›}Æô÷ôàØuæ‘ıÂ~2¤®3úEªsoßÌù}Õtíşü¼R.g·¹¸0ræ¨df}>IÃ Ï_ûù'¨Ğ³ğ/”Í4×ÎøïEœi¡š‰6	XÃñ¦»²A+$%kô@VH²v&ÔÜˆ?6„|ğŒŠÙóé3¦Â¯F,ÍIOÖÃúâÏeóÔîiÙŞÓ«ˆP,@±|€•İ¹iÖÃhêrÈGÚ5Àø%‹€!z³1ªK7'—dÙÄÉ)áÖ6•ŸË‹ó(esÑ¬&GT{ºrGœ÷²NÁÄ˜û0gìÉÖ)¹FDz0Áï?ß¬¢ü{”è¹¨øáÓ¿d¯'ÕÒÕ”Ú]PëlŒ.?µ¾Ö@Ñü;q˜¥ÈÛª‚2âŒÊ„Z+¨{Ğ×ï0o<dg¸©ÛÏU™øó8Š…ÊİÁa}Ö!!ÃCª¶©!ğ1Óğw¯JŒDZƒÎàº8æ;V¯Pxße‰=3<Š¿Ö"¸Kğo±Ÿ²ù8;E3<oNkÁX…4î¶ç×ŒÕÈTH{ÉÖwéqÈWåÔ-o÷N`ró	,8Ş†p'¤.ŠÔ‘Ğ»‚0à÷â­€òt}r]x_tVZ°B	çD#Y˜‘	{<D.Îëk¬v2ñlº¬‡u²5àæşÚ#;?ı£C]›ñs¤ZZårƒÉ¾x+qFÑšwZªèYÅLpşDşLÀ“få¡0¯ë.Î_4'U«èœ<®¾zÍÍ“´0‰¯ß’¡’^;‡¾|Õœ¿>É‘Xàá’Å‘ÀÂ²ï>8ß},šEÆvçqİ´'£¥sa©Y©‘?¶æ/Tú\p"µ
k’ïNÓDH-›`¾êM³2TÁº½1|†<æQYq\Wä|y­;d9Ã[jE¯Ìc
xÇÒ! °°±ÁgdÎo)f¢}ÄÚÁu+`5€R µ…#*^"`G;
ß&XçíÚkìÖÄˆäÍ7]é+5sCoÚòòë\Bî˜ªIØ¢œ~Æ¸^õˆåêL%*“a¢ÖÒA“°Ã?(N>âŠæ!øË„Â–í#ê¿ó*~¬pQª¬9ú–›@Q™ÿÌ¥cJæìå±š–¸‘Ä ƒš+Äœ¤U™(M¡`+Y‘&¸¿á¯	Mb§$-¬#A2KgqR’!‹Ìù`x¹şr0ö%åäI¦’æÅG_ë]îe«ã.Æ;4j¸¹rË˜U`šä$ø2şç°ÈÅôAÔZÉ7!Oû	sH¿cpê,İS#±ˆÌ>œúu“V
Ióø~Û'œFç‹p8lCúûút(D·8Íµ8UJİb%ğàvgĞ»}ÿ=şöXX¨•ŒŠşQ6>^_³	¦Şş]ÏxªğU(T+e%Ä“
*|®¿„PÉƒ9 VK¡güõ|à¡Q‚ìÔ]³Z¸~\ŠÑá2ÁNkgØÏŸËëDsû4±d‡c‚#Ğ¶AÅıè`r9ªè`¦UšC†?ø0ƒçÍıD§t&vãkl¾ÙY%Ì5F	ç!.İÓ:^ÅkX19Áÿ E![Şp5u™ÚMöE¶(JCe(+>ÜÎ¨İµ•*…ÃØ»–¬ÁEÙ¾ïJ/³Ã¥=ÙuåÙõ¢¦mF{Ë<}Ÿ%ß¾‡İßÅåa`.%®–ÆB;xõŞèIÆºŠ‚$Á¢ÆyŠud…†‚o«ªOvqóì¤®îP¢ßÁ´›?A¬ò_!e÷<¶ígZ¢,`ØfÎWş^×ƒó¢ÇÁA“ÿ´4 |è:È†H³E¬U‰p_î
¯Î‘¶ˆïÇzz‡CÛ8ß=À˜ó}µk’ÎµşnxĞ¾'Õ=Ü <ÙdbÜ§ıç+Ã‹ß±ÇSXU•/Ãd¤,?Ê{m¹âàğ¹Œ">P+kÁ>r±ËíÆôQ
€Ièñ)øÀ¥«ÚN\EÕ/	îÆi@ïç·¼E§x]Çö¡[»g©9ò´2S“!¸D![·á¶èš#ˆmZÆT¡\nÕz‚{+û Ôá¾U'µ«z•rÎŞìïd×chÒ×æ(ƒ­EfI{¥ ]1m/Yşû´/ñ;ÿùT¡Ò>u'8g­DÖª»¥9ˆ6*‰-KÓaÀ*;ns†E)¤3:EÓ?;®‚ âô^ÏŞTìNVó }FR·ö»'^M¸_DZhÀÏ&X#aï®ØÇ¿NæÄÚˆ&ßX€Ù¹ıÍ´Â™‰ó‡>bÒòäÀ æ'¬g^õ"[ÿlq¹ø©‘"º·4`mßDP÷yI ì¤ÿ`@;©piQÉyL1ı	ïÍÒÊ`¿\KíE×k3=ø‹@YõÄ³Û¦jäm¢‚{:å¶¹{®ÌR*QnæùRÍ×[6H qôE€3†/ó•Jµ
~1İÎ‰­–šÕ$®°^U>Bx>	æÆÄ#½½TÓ„ë%€Ub_>êOcn,Ì
+ò%Ç!˜h¡røt)ˆ<‘Â/
d·§O7Ùå"am¯@Ö¤âXëûêÊ¥å±^“kºÖJC–Œa>u>`K'uxc"¸Ğê6…˜Ë#0ğ¬/ÕŒ·@R—• vÃ*›¤åšT¯éóÁ0*Ñç„ñÇ~‘cGÔem¯ŞMÇÖBô_È,»çÙ–õØ–vEKaÕ1e„ô–¹‹OÛ(&r¯áÛÜ¨V4{)şQ£ã£n§‹9¸¶–×{™ë5šˆ.W¨2n„¡óåãÖ2>İº'![¶•Ì˜­ğá¥¸ÎMªCZ{ƒèÁÄÅùêıcx ŞÇ;pSğ
î“¿Øs4*öôä€gëØPò<‰99+¢
N¦ ûF4w?ô™L™Êa}&M…7 K#ßãF¢ñ¯İ0÷·Å½¬Q* PTÅeõèÿ/GÑÎÓkNPú~Ü&ÆïRÔ.£6È¥`+IbÄg ´z_bô4%lY4Ôz‡ä¸¥tªGÚ"
¥o‡¨”*jv½Tú‚båw€¤Æ÷ï[¿=^[šL£‚gr4Â*–Ğ 8´ŸÜ2mƒ2*:g½ÆlqxÉ÷¼‚î¦¡0º£§ìR.NªĞÜ©#Š,È«ĞÎ®­à®•Ğ×!Ù¦wfYqĞu¿øªÍáÁkÇ¤ÎiÎvıĞÒøBÒ¨˜ªÌúnŞ¿Ïùôo=òŒT©õÈš¹7Â¿a—
j¸Ê5ÁØÇ­ş¥ïÅ‚—ÈI2	¸şöo:©–ÆÚîåfpcî†\d:nT~;•ê6G±'…ßÁ›Gùäâ¢á Íq¯ª!f=5Î¦nÍôªqü¾—€g€8„öWÙMµÕq:yB‡¼ ¬N„«Ìş,§Û_¿Å›N£<œ³.üü(»XY±Á;VtÂŠ§‰1’üĞ³AmäÁ»¦/(("õc»	§°¦Ë;\~ôõ}ô-aË$	§5ã3#…Û~­µ”\è‰$oiëúõÙÖÖÛ* ƒµ›êcùÿ]*’§¹ºÏ_=³ÒçŠÒ_ş¤£çäÀ~sì.´_C­æõ€éÄóf´©XúwèKä”bKŠaô-ÏTÎ·¹D[ı™Eâ’	‚òG2^ÛÚõ	4æ|÷9(Ÿ»rû¼z8eôV¦å¹!WRBµş«ñ‹ŠŸ'÷şC	Ô‹R-6¼Ù¾1ä.Ç¶Sâ¢ÍØü!@Çš8kÖ¡Ìãz½^ Zî0ª/ù
­¤Ú[?´-¨ü¡Ñ[€¸¨Xı¾`,N’'{A£ÔOÂÕz¼i…ŸC®üqI]›t%å¢cn
¡"b6ëƒt|»¥›¢”Zjğ_ÇÌ&÷çF%&Sj”Ô¨P9¡.ÙS‹ QÙ!‚^Íæ^û'ºJü Ov–Ûûç+~¡›T~ûàm›{°	ªÃ›É©%ƒ¾oâ£:ey”ÖƒÅÁì·§æK8ü¶Ó²aãyP¶şÉ.àQ½êê´ÏR_Â«G0hï¼rd—`Ö£Ë
;êL~°Õ2}&³¨sÉ†¨‡h*q¸ <=ÿ§â~ZôÌ‹sby	qeN.ƒÊYqóYÌ÷Büa–zaJ¾#Ê‡sg"»JŞ45ö¯…“šìRŒ{œËËŞ@œ½Æ±æº^ŒsÙÎëµÀ^dKR›:,{…U8J—]@LÉ Ë=×~wÌ'V!£3µ4âüUñé(±…ôÊÂLîœ´âÃ)áÌg¯ø7…Iã*çÂ/¿zu·yW†‹™ı{fa?ë»ÏwÊ'õB—ãûÀÀLdâm!8¦æq3ñ¯	±C¹q\NBº5ò{¡Cot—MåŒ“íšÙ6IcÆlëXSÇÛ3fùK¨âeloÖÙÏ´–]l7o¸¶0ö{YÛn,ª¾e½-_™£»g¾ÔqÅœúÏóèß6 ÑP½§ßOÚüßM&YDÄl	¸Õ4Qù0JéSÊü}Q0+”Â¨Ø8{â¡¥5Œú<èƒC±THcä0µš–¦'–¯BæfÿÃ×Áav8\ÊW÷ÃP”èAî­R^}¦îı˜²?¤Z†~ìrS##¼z†y‹éÅád¨fJEsi ÁHvT¼è\dJ¾T³-i&İ\i‹ĞcQ}4öP8×V;åS.¬>|¯NÅŸé17$d¦×j¡Kö»´¬^ŞàğJä¦ğC¿ı8åUÅ¯ıT„BÀøw$©t
iä¾º¡ÿ[Æ*%=…øÂF³¹#R¾?\mm6óB[{¼ÌvÔ€ıÎ­Î íÆÙ±W»ke +—ÎoøÜK)¬u/1j'ş%CÃ~5s}…çÚU×ØSâÂ¿µ–Ì¦¿}¯&‰Z!=Æ;Ú²7ƒvc<E<âk5¥ÑÏD"ıµ“¹¦ríO¹Ö,­ÿ‹6Á?— ğÚ‹[8H’l“Î?-\›Áùk(¡£³¹5÷ş¨ªÎGKÔ'aæ‡«º~Ñ/«Ë¨?kób±™dÓ¯p”B›~E1î3IQL$¹*à³ä
ÇYJÓÇ¿n?Qéº©>Fñ=Ø&P`‰ƒìÂ·€ºöBÚHö]º£¿?)×}Qêİ§ä‰°HoGåµåWÇjo¥»¹·ÈSPAgwªëæ“‘•¯`İ{å÷Nr11×¡83Ñİ~ ñ!rOPÌd9ÙµÏyƒê÷lâfØæ˜ë‘$»áLa|)áŠ­)@}f¬ ¡·7Lk0'µ¹se	Y¢Ñ×¥µ6¶ßËêÔÑW•ÛXèŞ%kÿ-B´iv ÃŸtÈî=0£>£Ü½ÔÕd©D'^ß¿¨ìè§¥ØS‰·n!1Úº	†\é˜!S‡-¼Gyğ\Ğ†ò‡u—56Ö8xCkn†Ãz>ìõ[Â!f¨’ÂÍ«xÎØÎœèWx Ê”Ë2b¨ÕEQ{…Ú(¸¼ş;,?Ü€”,Gz®Nàœn¹Yú'qøÃ»€Äf• i£1â9Õ*›äÂ´6ÎXè¸>ì®ıÅoã 4Â.Ë\jîE)1E:£Ë“Y>Ô®nœR®))ºŸø’0FÆøB[ ËÄFŠT#-#H¨•" SšÛ[Ò±2‚±/“‰Yÿ°U”ù5@÷Ñ‚èolÌåVa’SÑÆ ªä3£b@C8­)ƒŞª¥»¥Ì—Ê|§ûu3)5‡‹[0mÒdaRot*6v>\÷WƒíÈÓÅ‰Ÿ¸F¥e³2	ˆE:Å>â.MTüÑ4U!ÜâİİlôH?„ñÀ­ö• éÁÄ«¨ÿ³f•A—R{î¦òzq™é^^½îÁ8Uï™,ã?ÿ0Ì!§ê¬®˜—ErR+EÀü°z§ôQĞ9ºÎ^Å%j­Q©E©«Ù™ôƒÉi ¯g˜fsS«.YµÓ;±ågê(æÅA%¦sœ=V”6ÇÆÚpƒ8„·ò·â-oJÓ*DZçœsqÍ8e¢h4W•F„İo^I*SÉESfHwaÕ´§ê,YüÅr'â2Û5/    úÄ´æ¯n¡ ™Æ€àğz¹±Ägû    YZ