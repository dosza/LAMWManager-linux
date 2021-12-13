#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1596505971"
MD5="382b040b37427f526ff35c898065d568"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23936"
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
	echo Uncompressed size: 168 KB
	echo Compression: xz
	echo Date of packaging: Mon Dec 13 20:02:51 -03 2021
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
	echo OLDUSIZE=168
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
	MS_Printf "About to extract 168 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 168; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (168 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ]@] ¼}•À1Dd]‡Á›PætİDõ"í›TÜ
2ôŠ½_êŠŠ~‹çöU”‰F»=Ú°¾ÑŞ³ñŒ>Ä¢×$Øt>_ …xzã§˜ó"N‹ãø†ŒôA[è(Á˜Y•¹…İ3ÉZ±€•ˆÜ®½Ñ}ø˜ûŠz›şsú©˜’oXW¡ÈşÅÑ-Í÷[ óÏE~ç–æ ŞS§ËßL¯€ğÁ¿;{®ÆL•ÀÀ©‰}”ÙÔÑ1dŒ6S ®l;BCdùsºC'Ä"EZkc BÈ?(v±¶dr1šu°t¯‚5Mjì°Yı$}ë“26äEî—G¤w0*ÎÕ/ßâÜ@
œyPü/tX>	IÂ)§³Şê»%•#yæT6½Áµ~WeïYYV‰<A¬*dKk³#övİókDd©`nTZõğ&©5µ=ÛŒûPë¤ƒóYÓTæJéıiB‘zóÎz~€€Î%Äaö6ùlzı\odâJÊ€F3–›"îÛG7#)&]ccÀcTy®Â;¦;G’9DC%’±Rì:”™”^Îi†à ]j9Ìˆ/æcé®Qb˜¾a¿õfÍëRºéÖÎ«	…y„,6ÉkËS^O–MË ì1à®_ŠkKgJ¾şKŒ¥<ßä P(AÜ`ªî‘-Ö7ÌQQ»u"¨\Î¤-t!x
+­wóïº3t–ƒw;÷å Í\¦k@ñw”FÄ›MyÎÁ£j;TñUó9Ee‰ OïAÙjé é”Ó:]C4‹†ü­T¯~C·¡TwâöÇö	QdîÆÓ"Å(×±~Øa¥-}›×
”}ßñ†}N²¯‹7OUpV…88 ¢8G£T€w|tHè3ñ©a¥êó¤–õàwKè¬s¸à9sã>ˆ­(xÂ
`¯£ÜhãDúf0—±ºZ*\äœ¨ä¯°NX:ï,Ï‹Õ=³^½[á©¶÷VUçHµr£;ZïÁÖiËR‹M.`ZO\4ÃÜ“ç8‰åP\ñèÀIä•b­vğšùşÒAúl‡pÍP×S>=kR‹N«õ)t7LRe‰´¡ôÍWüŸ’¦<òIĞÓr|¦ÁCªu)¦‰ÎÃŞÍÌÆyv$‹¥àë`şÜ&Õr©ö«)g™åÉåè“Ô1šµcdĞK3F?Íj‚q[76®kRN¦T£«éşıÊ	moSù\ Ä£?eZùâ3äÖù“ËC(ej oıv'ËhŠ­áÍHUÉ£?Jºrrn“k°›s–—ÎnËôN|
—a}rØï¯µçï´Â¾a½eÖğJ&æÛMôDıV1Ô}Áº0"`L0*\}»êÜÙ¥pxùšb½Îã¬UàÕéÄ5TÛÒ“O_ŠN®ÇmEm¸°Õb‡”x9î'¢1ìE±;d
>¸\âeQ°gVSÑ&*_…şC=˜bö)B’AÃÄ¿Ôìì¿0ÿß*‹â1e$UbÀ¥èb××tAèÀ}h<Úò€À£±ßB£¡›ÈÓ…À®Á{cÎÙHGAâ‰Ä&2º¥¬ë±°ñh™*«Úaèå8ì·½^Ë‡iPcu`I™ÇÖeÌÖü©-š9UWçİÀ¤.±Îò–¯_(ï:<È>®„Ytºª#k—\<§7ájôÄÜLÈñÕ¸V*S‚(ë#d¿ÿnæÙäíV°[ç6çÃ¤ÑGó¼NÉ¡}IÈ¬x°:`ÿv äZìíÍGŒ¦F½İµ”¯º£À)rAå†ò®´:ü¥êÏcA5á	mƒ,‚ƒqê)ˆ|ë á•1W4ÂJn)u.¿!Ÿyû·ü}Ù/³ï¸Aİ^™¨SkÁA	„±.ínË„ªº±]j°óìI>}sT'´Ö}¤øØü7í JíæŒó@Ságİ_»ÑA®xàÑı‡f³w(©ƒÄë!8U9ar>"fçZ­Š!<şÄÄ—$YI†å$-‰i†«KÛ5±A,æXû˜…Pê—˜ŞİÎyşt2Uş/õîÕÛ-÷z`É¯\¬t snÂ‡x»‹È‡¶Ò†}åO|NtË¶åzo(åÈüYk}yávôCÇ‹mHà§­Ø1Ão:õ_Œ6Ó€néó÷=!ÌwH÷ë¥éô8àZóvw>…¡c4¤AcÊOîŸa3¹G¿"›C†¡pT	ğqc<³ÉŒÃ˜[=“Øò6Úíg(Á`š´µ¼_læ[&÷(Ş§©¦ì¥û¾¹ä·/8v@ÉK™5Ó¼ˆ•‹\8íùışr-Ê"Şa½Xfæ)|W%d÷8÷Æ¾Ó
ãØó^}OÁd²˜ÜÎ+É´Qœ`xN6_Âf->ÿ¤ë‡|ıÕJ­Ğ´ğô“£¬h]F¯ñŸë_‘‰ø'“ë~6¬2w²[·úÄ*D¤M³z e/Â!ù‚÷ï¥“{Ğ–Dî¤g:+;Àîg„Î
{–d‡É{ë^Ö+%e@S÷›/í€'W/ğ™N­ZO:1ĞwgbÏ„…À<6˜.<w À×JÆ¡ÓÒÂ‹¥]×¦Ñ""¯çÜT[şVWØ	‘Ä°´áqsÁ¯Ñ‚@&J„¸‰Åhå‚¶E$¬ÈLa¢rá‘Ê—Zq<>›ÕĞG`p‹á63Ê¯åš.(b#Ñçß ÀàÅ@à®ıØŠ4y0¾N·tß6ö¶±€×Ì“¼Ì”á‚ó“††J5ÃÓØ8;x‘q¶ßøçüúf@æ@åw¹/Étó 3«‘z“ írî?ôq>Ï¨²¢{zí‡‚
ƒo[EıÕxÿıíƒÊˆİ‚§F7ãØÃ.ÌÚ:•FÍFµ%Î7Å£­_ÔJÿ¦¯_“Pq«p.FÅÔm¥íL1}ª´R¹Y‰(æÎçN|iˆ¢ZŞùÏòhŒàTKmĞ©¦QUesõdÁ7Úğø‡Û°nø3…ºFu¸]ÂW#Â§LQaÒÿz=köbn5=âŠ-úüLè‹£ş¡mG‘7Xæêk,n$¿_­o;VT$T	%úê¤‰t——0FGƒ­±n<ÚycŠÏ\ø'òaç/u¸lq·Qe‡rÆûÿ‘jä ¹]µ)÷/­]!‚×¡VWušI ×?ì_n]3®Ú~ >ëR€ìã?’Íx“üåÍ-¥ôÛcQM¨„,1ŠM‘ÌvK‰g¸WÏ6Ñéw$ÿ*Å¡AŠ*CVÕm¬†¸ÕèA*<2ôÅ§=d).P¡…5ÿoœqÑâ†ğU.Gªõ <;Îª·@&e¥á\öûƒDÉxBBó„¥ş;§Ç²9ŠàT{“‘áŠŞZ©JÎ‹JØö?ªû"©ı…şH.Ixİéâ{ç§ıkç»KR:¿zŸ]Tî—ÚaNÁŞ¦Xù¨gÁ¸pjò
Ø_ı‚Å+ô"*Ö
©á±_İĞKŸ,şİwà32¹ßaI¤»ÚdˆúR¢«g7gÇQö¦ó6’^)q5%Û9ËvÊª¶¬6‡ z… ú­NQA!6¾Ú}Mşm5])­øVZF»Ö ¹lÜ‘%)'ŞîùÃ¶Õúñağ*ìpEa9'å!öÍŞ&d¥½§ ø˜·0Ÿû$4uıIiŒOãK?P6Òêù]æğí[¨’NmÉã¤NºBØREŠ?ù8wfî¶Äê93?£¡,Ò„³¥²4¯Ë¹¯.ğŸPÈ¼TíìÁä1Ô³â›O‘îÅ­™®ëç9À=ú=•K ¨èÀUv¦Ê`ÍD‰.oP÷¯œ—Í-_w a\¢™*eé“Äã–€8ù j0î÷ƒïáòyÕäñêşXé-¶wÃ¡—è:Ü•@ôÛ·Hú¯Š+ğ»¤‘EËßY%›3#ıRı®töRâô
×)N(B£ ëzÔû~\¡m¶áòj©Ys†ûÁ©ÕÆRD¢»W°ûou*Ù@i»PTQÄ¯…^Xn#u92ÿãkl–„ª‚1ò>T¤ğv.YpgqL<ó}%şº£” ‡“*“3…³0ÌÚ7ùG‡“o'ûL¥s&ŒØ7ïU®Ÿz\Ìg,y»jÄS”AÒ¿œö>IjEö]Â–-®Bºà8ØZÓÖ‡ËX8²Ğò”ºöYĞ˜¯’×›ÎAöYIÜæ¿Hµ×#Õ¢´şÙ÷Àêznîî¬ÎÛ†¸D’7è¡¿u8(lå‹´à²½iÙ<ÿÔM…Õ€Å¡M¦ä2åÆ¬é8é2b.qÔåoñÀ P´åjİ;KËUîÖ^o>CÒÀŸ×íæ” ~õóó÷aÛ¸üÉ›FTK<®Ñ_X°#c”?÷ÿ|¢¶‰‰,Y™Á+¾QÉTÿ8ºSå³~áĞ2ÀÒø®eÓÀŸIHñ şíŒF³è\ƒT¾¥A°5…ôk%xj¯ãHjıàj²(k©PƒÖçácK°úÇ(¢•}Òå%1î `'ªúvÊ2dä{í€)Èw¥3—ÅÆv
!šó–Hß£’ã\êö&]Çïà0ì¶ş%T2ÀÑ/%ZÊ3ß¬ ÿfó^Ğèt#^À'´ Lu?1êOötK
}TÁ¾â`©¦ÃÅ˜4aQ^ìğ°wÈÖ	sL>‚ÒæJ¢ ^×¢zqÿlyZh_½sF²d”æˆKr#z.òLÍ!+ŞUÅrC4hÔ€Ú 7t^®é*º±”ûH(5²>_ÿKoR[rõj™ªÇfâXNÄx„éü¶E^F–¨Şç°§»X¢l!ÎŠı¬öoü+¼b›g"CÛ–A¬O¤-¥O»ºKuïqµô$º¢{'ÌT*“åAHØ‰ÂÓŸİøXé6’>Íëöâòh	s“z]*4HÁp/Õ¾ÄBú¢›“Ïe5Šg´á£ëS#
As\éP|ÁQ âmeÔ^yÎÌsĞJCŞ‹~ş-¥&«ä:[ò¸i	‡ò¶X¦
… m)œdÓZYƒ_ã¿¢µl\¤¿D¬H§1O—.‡{|E	ŸyL3£sP£M3	ƒÍx°O‹‡Œcÿ·š¡°üLÂ‰"w˜¤<¬¶P€G4
Âö¦ÍwîG»÷ì¨ĞE-b9ã<¸'ñø4-²İ¤¬‚½{œ~Œx–Ñä[´¼t.%ªÎê¢óZ˜’u‹ ãL^8UˆFi0/Ìq®Ù)ÑŠ±Cà$’Ì ¾ôúJûáŠ£÷éò:0ÕÿïÁÜXK³oï&4-ĞÁÙëœ))›qÛje`Ò[.éÍDËÖ/ª‰S|Œ6K<Öü¢Ê–Â®Üæ®êüAE0Šñ?zƒÔZÏÕşiûó¸Â=¦¼ï¹»ôæŸp]„úHÇûëu¿á4ñ7ä¿¨’aíç»UÛ‚ßfÃ2Ç#òL”6ŞÙ÷õÑk’SA§·ÓMNªFäÁ¢Õ‚¿EEñbÛÇ{®©í™33ÚÉ©=û£l¦®ò‚çÿúÉwP¸ªÌÛ‰Fêñ8¤y©%Rj³:0NgG}.«şÚtónP³¦œ±á(´=EÏ‡bäi]0è•dQ µ‹ëUèÑÆïMÔÇ.1;ŠDÑ½a»iÁáâö¨Ê!ß_Æ½·cÓMlş?ğm†^²|kˆBÄdxÜNÈëÌrÂ÷şfü9ö„f3³­Aò»D^¨Æ°Ö±Ö˜Fã2ıWúDO¥×dŸ8P		ÁÍõšGĞsˆo˜øÌéÜW,™€ßb6¡§CªoZ*p"Ñ#óJ°YìXR%/‡ÔPg›Z‡j’'©€ı†øCĞå:‡ö‚f/ÒGĞ¹ÉÆ ñ6O(îo1Ÿ"½mXğÍ¢´{İRp67=OØq	Ä;º¸zDµÌG¾(Ê-:ˆjK¯äÔOr:LßŸö”øğÜ‘8KÛ¿Æ®²N} $÷+
c"./µGÀdA]V,“óÈ/­JEhß¬ª÷^Éz`]où”Gc¸¸KÍª;^jì·6ÖBÒ¹Ü>‚ôY×ÄÎñI‹~Sa+‡’9×ºWCyzüÚ‘Ûµ@`^ve›ÃÍÂ™‰ÅÉ¤(ÂøÔ°¶µœb®¾İˆ¤ÄJKvÄQ ÁO¶:òûZ_w…S—[WzØîoäœ(1/&ªèÆ¨¯X&‰cû®j=üRıŞd{¸XõÙ¶b2R)0?—VÔÛ*ÌéYÈHS[ºŒ›¡"¼amy~´U=¢q•Êÿìkãx‡’€øäÀrPXCÚúÅOKsÖÖC¶NYN›Ê·twÙçÚÒ<$é0ıÂ)i[5MÇ¯’"yşÅ4nğ€Lüd]}ß×YV9+¶Ï:P)H‘K!"…H¥ÂJÊ8şÀù¡^óû6×è4ü	øÂ»Wà8–¸l.gLÄR‚³×Ä¬bÓ›Ö‘êÃ`˜u(_â­ø›tî¹Áòt%‹ìÖÙ†Ö^¢ÿD*ÔÔ—ÀÎÑ¬¡w´ÅœÜntÊĞJS>hë}ªª¹À÷”¨àØ˜îP Z“uìâv@†ë{e6òÕâx`[·óÓ¨‡?¡OœÉÆ#Aê0êxvm—]sêñ¬ŠXÚZ'&Ûûp
Mÿ;C4:‘7|	GäŸ=ı†Š{è©“kgõòØl‚F˜Ù¸6óğe•âºTğØ©+†B‰ÔZ1†¤JuÂw“ÛBsÜi‘ßšlÛ``:‹µ¯ì§ãØsü];«fI&lÈü¸3~QˆÏÂÂ£É„©ú4ŞÖ°Q`å‹Fa˜ŞG|Qî÷×i*¤Èügp;7¿¥›zÃ¼ñù&Ğ0¾ÔwŠ®V2=ùV×TÍU1ì<[é·¬¿4­l´»‰ü..µÇ¥,O‘Æ:Ò‰Ó+„bGŸ1«Â“üåídšèÙŸ.¢í¨]€fîÌ;…Kd:4‚ã=_Ş |¤1Ø¾íıÈo¹1DSHF¶5hÙ«B{/”}nçğıİ/;û:¦\fÔI[ˆGÍMeaŸÜ"[røSbf…ˆæĞá´`Ğ¤Õ±ë.så¡,E¶’‰”$Ú B„[>µ¶ÎüUâå~ˆØ¸n,^½k½€Õ0==”\9pª£e/«í+©Îø)²ı" áLa¦))Ba-°ØËc…ö»¡±ÍS1İüh(vu)âLG7ptõ  ÷æ&w¾a}/vQKösÄSún4	†=KÌÈ„!Hm¢‡åËJL[o}±'Ñªa!˜‡ ÕVu8ÓÎÒC¥dzÄ¼/çÆÅ(³?%ÈwÏ´“PZŞ5ßÕ9}†4§ÖÃíÏX`: «à0ØvN‰z‘cì Eã:U«n
Ù„UKÌÇùÄôú|aë[gågD˜[a¨{}üQO~Ù"œDF¨»«väü(Jæø¡”ÔR»ÃÉM’ıA'¾wôµN¶â]*ò]^Øu*.=aÁ†·O˜'ßŞa$Œ –tı¯«Šğ7<Êà/)úœå©…™rª®ì©©†ıéİÏi.\”•íbd:›&?/İ/VäI•S¥º«¹
¿Tpeı¿†±Œ]VZë‡½kÈzØfxååYËè%SÎ»êºú+Í÷ğ)\±Ô ÇèÅ½¬˜H_1ºŞ¸"GırÂ%B8àü ^X‹ôD+Ã3ul;.ÇPGõr	¬ş˜¿&º–A¢Óü+9,4”%¥¾Zœ¿Y5üLV€FÒŒ–(²ĞpÕeRn5¹^1B–{”J#ÏıÜµ.–*­Øu‘ûI´<“¼NiÀ|ëÛ] ÷mZR\†HÃ_Ê%x«î&îfŸùÆhGÓÍŠØ4Å¹#z{8Ö§‰(pá¢şòtM#Ó:)>¡HŸŸ—g6+RÕ‹‚zñ-j :´)‡”H#Úä$Qp~¥³¡c½_şÛ0Ûä#•_DL¢LÃŞ@l¨Eo>m|U£J°KU‰$ã÷9-ª Ë¸JVEÖüá¡+„ë"wpí´e‡_hØÎ>¸$ğ›Áî“ynğÆWíöö…€²éó2f­G¸l2:Ñ¿â•'ÕcÈ€\Ş’"İ¦C4şâ@957RÀÿáòlŠ+ÊGBãËèÀ«HA¥y˜†ÀJß·É<÷Á¤â)ß·¤Y#Şğï™Ä¾’"ij‘ûî´È\WgóµFM¸K«!7mªµ®¡4qù	P¤Á…kDŠPœ©A†#‘e0}³ ¬æÌñ1ëcªãdCöƒóÔsY™ï@â|‹ÂKU¹Ù(?t{ ½´İlw¤ĞúW«°³â×Œé¿U~bòŒ/×ñl½X8­mXÚˆkN•[ÈÔÓZÓ£òC€Y"*£ø
²{,Åú#y!×­>Ã«"UäÃ¹´æ:v©¾õÉEm'"i|lºP9ó¢ÖDâÏ•8%øÙêîÙ°èMèFH¿~C
 (gÀ9¢|ø%£T$šczDÂ*A¤Ø¢Tf6ófÚ‰&İÛ«ÕwJdjB‚²z;Î9•]Zñ]EïŠ×Nßò·½ßãÌ˜Õ9‡LwH~Š£]÷"¢öÔ}Vrvi•4[”ûº…#øİLœÊ5y+ºkSI&ù=HÊ*­)˜i»ÜW-ÜšŸ­#'v<–ô¬,ÿb$š¤6”D«[«Kß¥‡S¨bq<7ƒ«=*´E–"‚¦ø™Jöà·[òÏöÒAĞª¶q¥Í´hV:š—má(M0PÎ½öğ<ü\’	k[B4O( \İfúÕìQG;o0ÂìuÇPœO—Ğ¢?3Fˆªq¦,ç7iÌ@“Ç*T3Ö_`W¡%H(Š"IÃ¬„Uô¨ØÚñj.6z?ì”J¥e+ @wÜzÇ=‹	3‚–W¼ÖÃä__ Íß]İ¨TfUGé°ëjT¡ŠÔ®›‚¸·qE·ëÙ  }:/(¦<]ÿÈqlmà`\.%Aï]®jÅ	ld^ş•…ÿ`ïAîÁÀóÙTm‚"#«Üù#-ËT•’VğñSCøt{Ô9ªpá}¼wPKÌZo¬©Ó³¼6„ÍÏè"Ö£KüçÜWøa€‰Òü|¦‡%‰ë8t	$¦´	:Úšş$Úù	‹Igí¬•ƒÌ¿U	Iò÷Lµë·óbœæO »äÑTƒ¾êÃ,P$±=µÿFĞIiÄ0Švá]¢^oYŒ7Ü\aìn;W’“À¥`†S‡ê"öèXíy…ûÊÈïpÉ
ÁB‹ÈÛ™”íÒ–wlÌf¥ÖÈÖÊôJlØÍòNóV}¢p~ë(áêã~ƒëŒšêzî!ö Î’L§\ÿÌæÜ*Œ¸ÚE¬xE`°é$ù°pBa"ƒÈ;ÍÇÜĞÅ˜–”d¡ d6:¡¼İÑÒ|rvÉ¤©%:?Císm+3tböËTQóˆàp>½ÃAnn%ÍQÑ4Ş\.‰³QQ”€Nƒüx7oÊ!	Ä [p0C‰J3JP÷¦|àxùêèN4£¼şÍR‹½<+ûdÏC§z¶"\ÎıûÑ?ÃÉ÷Ú4Z3B—ŒVaoÅá´AP}rÁmèL£_wtÊCGõá¶7°„t™ê#»ÓÇ€®"KÏàpÊé?²›ØùƒÑûĞ–²„³LI÷VTÉØw÷àëM1„'}©;ªj,ºN1À·£{çğ‘7"„,äÈ	n~Ó›V¨ş¹p-6Ê¬ªúÕuÕ(¦¨ÿG3®•3Ê¬BğÊR?µ'æˆ \ŸŠ6³ë¢9 MÎBÊú˜Q/•@ÕÄ‹ÁœeœöÚ´ÊJ›ÇÔg´;<Îh'YF_@¾µ¿ÙPT¥XÁf»>rt„*‡
°Êƒ”ÖqêcP€TsS	ºô˜÷Ê»:û+`ldòËú6áM%d?úêŒ›aZS0—uXœ8‚f(yt§?/Îà%{‘”W2uÚ7ŒÑ ”+Ètİ§ô7ıµÈµú	:¡y)ûJ™(8èë[8Ì³½Â<¼`¢Á	.bA*=¤¬l®àNf·0Mª„„P˜<µv=’›'€EÔ ¿G´ıÖ›,2ûËIôá×6
åÖ)Áƒ¡µk›Ûqåh‚É›ß-úWú÷¢‘Øİ“èE	¨@NÄ9 Y²5ÛœlÁ°[ñÔÂUFõ!1¿ĞM›f{‰¬Wª.è<¶İF¹Öñ€œ@ÆÚ€Üé¹sWš$nÜŞèùwç¤E`½èœQixî¸çù[Ú,tbAĞ$«Õ†_Á'ıtË{´*í¹x$Ò¯ë{ÃŒj€K×4Ë‡á×‹Ä3?Ây¼±/_YØ®ên÷— ¢d´ï„0òmxÕB®ÌEf8ê¹Á²lØ‰¨®iËš¸‰ƒîıŸ:‘M+«$‘‚½%ÒBÊ–µÖdB.{ƒòb—SöPÈ€ÂKq¡,Æ¦œ·ÿf‰â5’ôNr…Àà5àö6»Ş5Š¸køWÕA›’'_ÈRŠå-9îFëìO¢Ú¦9¢Sºñ^Égè¸ÒF-5ĞãÄèî;
1‡v¸œú+¯:ş…bÿıP ©rUõA°È>*JF<Q´’®åQ_Ï™Â\®iåÜşäs<–ü»Êb›¥cv‘5Ğ./Zñz±iM,_S'WrëZàÕcÌ‚ñŠ#bfp'öŞ$åL†ªg —“~Bäÿ:j€Ì<4¼èÌ	bUdØQMş`	=ólàêÑËy‡¹@âD±5(çÅõ^0áïY­âP>_Ö»ZÊİô &F™Ş›ñó$É¸ñi†‡è4€ç•g£:Æ¥Á3ù(ŞJâñ‚BŞË€-jhû×¢j¸_h!ÖA¦Pc•uÂŠ? >å„®PxĞcŠk´¤êu³qš’m^¦İ`iÀåï;’$"‚ßTáw)4vŞ:>ÎR
£>ˆ"fİ„#¢Êp4€/„{ÒêD¶>ê
1uí.&ì—ÜÓM ğ’†*RÉMSyÕ_É$#Uº»sñÃ2O-–ï2ìdÚ~‘kT
ˆYĞ-Ûğ39¢×Ó9!Õ8ï€Ê?Šbm!J„ ØQA›V²J¤ö³¯Éu0ùØB1È&”ái~ê“ŠÆí¼XwZ<äÎâ©ŸIs¹Ïê½H"«m“•Ì¸Óô‹£~#ù—tbtEÌÔÔm¢(ß	=FÛN&=t5áëë}³Ğá‰S/Ğ•iZ~¸Â‹ÍÁÃëS¤Ê_@›,=ô:rgx|¿æÒèwêêÀíì‘Øa¯zÇh™¢p›4?2AQ;­Ë¦â3\<ÒHğ¢7oH«9Øzqİ)ÜG
Os¡CÒ·?øWY»¹h‚ô
M¢Á«ëŸá´¡Ä¹¾ÆK]‘u«e6ùüAè=îD‚°2G¢XÆòİ+JñğÈ	ªé‰¨Cã˜`0Æı\5Ó½ÿJZëM™ËÃsµ¶‚ùÖ à‘Üã.mLW–DbûöBå‡Èuäê…XÂ™Em's’yLj|bœQ¿\S½ôV—Dyo¬ƒ-AN?ëÎ‡ú~b&•<ËF;Xm.A€•$Ét_çhÉÖ¶
9ë¦zx_Ş¯À£±¤´Ãÿz%ÅíR|–”4Üğ`OZÀ)ÖÊòlŠë­ÙÑÊéÔëÍŒ6”SúmŞıiÃroNˆF;!,\4§’à: ~áMù	~…iqèOU*¦dK,µ£âej@ìšYt¿á)1<ş³£Eæ¥Ç6|vá-‘{7§v`:äh.°ÈÔW‚R&fuß¶dˆ¸Ùó²ä³;úktÌÿØ‚à°Œ„w6ÒzœÑáw‚Ã\I£:‚“gs=Í}Ï{Y±[‹åÃ'Ö\)xvœ»?pø>µ3Ô—Je-ıàQªœÄí¶ë¬šGC"8¢B¯ÌøÕa#qJÿIIWKşs`Ç©3tÂR-°-’Kp/+ílûé|[ ïBNœíÁd"8ÒĞÀÆAÔ•›¡6ş*¹÷ÆÖ©¦UùyÖZGi
M{jÊhùç/§	ÇPÉğúƒ`Ÿ'rÃB¼S¦EJ{ª½ív[K'iÌöÛĞ"6I+¶'Ä»ñnšÉÀ‡x#_½àªÚ¸ğœİ³1ÜV0<¸FxïÜ„;…«&Êaæwq&x—ù*?°ø›+Šµ°Áõê.¡ù6iñÙIö4…‚‹=„Æê|ª‡_{ïi¥P©üVÍ>;“®ñuÂºTì$Í5€mrû:-)MB"–:Ş)ì¢ó·4b}cpµ¸Æ©¯£º¹iPÛuWxQmÜãAd5í.²~BÕo/¡I""6çktÈ¬x
|»ÁK,%U*ıÕ›z9R{Ş¸ÿ}€İEZ¾Â‡÷|"Ûº"vjêG…¬¶'÷!v¢v®5s‹ªà°iĞd½€ƒ€ø„:°+;  YòÈOmIƒ½îb4òØk½æ „ú‹€Y°Ø~I]
¢r90*YhŸğyX‹ş°«¦Ìœ‚Ç›§÷&~¶è¿†œ©5³!¦Ü·ò5õ&˜FAÛï‹..ª5¢+•ˆ—»l³ÄaÀÿò ‚¤9Àª›p/iI'­šL6vÈ®?Ô­°Lm¿1+ËÜ·$x_¼ÌØA$QQ/ÛÊ½4ˆ2†xääØİ!4g+?¨C©Ù3z:Y"¦ÕIİ¨›ªû|æÁ7£(ü8ùi=wx*œ«>+ßòz´R	ï«’ààF óíû€V„a­È‡(‘n¥ï[ÚNsÆ~kí™!+†ÒßèÿVqÑs,@3URÁ‡Ø³X÷çÔè3/N]§Iñ@¶EŸgÜ¹¸æ†TÒ©êœŸõ£ıDÄ˜µ)†Şá¿²
Dl&µ¡ÉEO¼éG Nf×è®XbF8aÍ?S²Ÿ±<Ùèµ‹›*¦
ÄÂm+‹,ÚÔ`†<÷Û[ßŠ/û°‘»zğı|g~–‹/Â5[&€vG”y·3¶ŸZÛ73/šN,m7ÒZ¹M€Ó1ˆ››+SŞL6ìË¥6î|ÆFbİö‚išHKoI¿$ŞÑ&UãşOc´Ô4Ú„ŒXŠ‰¤Ö¦tgË©ËÔŸÒ-–Ô)}uOpL« ¥ßJ}|$ôAR›u=.ğ)àæ@âç*JÔî–TöC´«Ò@î¦2—á]c™ÀÇÅË§š›‰r·Áë¬Cm!£üvÀ/üwJ!’^'Öÿkéú¤Ÿ¾ÌĞg+VÇ 	ó¤P?şƒYÄ¹†úÖEà$µ®¿]³¯Eˆ—G:¯F*ln·àAÖ)SËÃ²Ìé<÷;`›ŞwŸ1¨ğúŸ#d&Üëâ¦Á¾à«B=~¬.õJ®;óAÊr.Lvt|^«µ›çêjPÒ€äT¶qğÄÏVy{ëNO.Y}qÒ$Û><	àñ1åêoÕS'E@}ƒ”GaRÒÙ"mvºHâÁUê¹ GEƒş0š$øH…b¬>9>VuQÊdµ×pß:(bÿ»¯ Ô§Åöiİõ¡]8—»`ş¡Ï¢sJĞƒ¿îJéCµàîí{'ZÙğY·_Aí}\M,v¢ô4+{&*ÄŒwl`Ôª©[ì=2Å±ö‹(Ä[ê¨»^_Ê>3*\Ğ,ñèŒ5.0a[
 ¦÷ñF#N ÓqÕÓÎßœD*¶šÓÒÂê¿ÂEOCD¶­Î!ƒì˜>ÙA˜rUhJ%é>Õã’áT—-=­ÃD½yfŒÚÈ%­;.Bÿ²İlİø_.oNJKÁ¦Ä„Löp÷Sx‘_Ş¾Ùb>oå@àQh>gáÕºM‘K	ÖûÃü#cúVİF‡û ¯Ê#++"zPC˜¦Tõ/F!KõÒT¶ü)8Ìë°|OófkòÁówzÍf­š#w/Ñ$X³º"¸/¶ß,i7ÿû…R”%ô%wv0ê7Ú÷‡ÆóÉÈ©ì#Ğ>/ÎÖ¡•®BñqÃ×E~jëyU‘›iâ° sÀ­öOÌ?÷İdç8ÿ,"fT·oÕ[V‘f[í—&Jä€<3Ğw€õ/›ğÈ y3X(záC9w=ˆ»È<Ñãc×ä¬»®İ…N-Ôø‚³ş«¼)½9“Õ°‚DI«Z=‰ÍÑòO–LB½(UŠ¤Ü-ŞÙ,·ÔOsrEŒ†Õç 9úºë1¬>stN†eğl=İäå0›QäqÕÄG$àrNş´ŒP.ÁoÛˆ÷±î¨p¹GÁËÖévR+ã,&¢q¿]FÈ¡<5®gde
è¯±˜Öwô·Øò5D®q·î íı´Ú_9b8ÿ6q<­³ûàÈˆ›üß&ñ^I6Ç÷d2£eó®§á£)u÷êC˜'(&jLr’Ï
©“!lA)["És1¼BP”·ùñŸ“8ço©3<!X¢owz×ÄÍ#7BªOtSN&ßNûQùHf¤Œs´q-]&+øç=T´)‘s“¨}iD^ŠºˆÄ?äÿ^mú¡œ}¦–UTq
›.İİ:(n“•½b\=KuàÄwó²`­æşàõŞv4˜=Ì•à7PªÜk öµç_<æ$è¿5p,Ggê{\å8.ÁŞ:;·)$RTºû¸9lwdX@~nˆzêã:ßÎº¹\
ìN U×º,è¹ Óë·e«3œ-º.båjtTWÄ±/g6‰XøÜ¼i§)·F•OæQiYåX şpÙäÈœK‹hO˜ìğñ1ı•2N;ÍXFó¡ïÌ‘›í£c}Oo`Šó„a6X6–§b~ezÂ]¢å½*n{+fä(K{¤A@„µ+Ô%b'Eø1üÊĞö™ÍQP2ÛOX™k{n„ôp•ì¶à<eŞuqB”¿Z.O@¸û=Õf5âš~Ñá\q^]¯4^°„Ó ‡¢Šëw´xx$UZ`¤ÎwSY®È‡–gm½PïHK¦x8[ cÉ¸…<.õ¤™„ÂÂ25õ<€¦"xü´Óc¼jVR<ÛOq°%Ub“ÍD^Ø”9uq¹‚ìé½²˜F@ƒ×·|CÚ¸™±*bÄâ!‰Åë´¹Ô†:úxé—±‘/Úv^,É‘¯×GmF6¾µŒPi|œ Ï>®R»Œ¾–~ê¸#•÷×©çí½®mÕÕó»ƒB™ÈÒ±±n¯‰,xöK Úƒ8oşïËoe˜p"Òp™Fëïpã~é¨h|WÒhWW•‹KY±Á91aÄ@¶€ëĞœı1–uq‘İÃœCn\6Ã›ZK_‹a¾„§5ÎÃtÕ¾º]+v­†±K_¶a“s4XÛñÔAoÑ ^Å¥N;àg(
pO¿¼©ÒkğäÁeÁ=d DÊ› r? ğ5¬óì–î1aù¨ğ_7¸,‘½0‰SwaMX pz¥èç¾£°Æ¯‚Û<°Â¬Ÿ<M±•¶ƒ‚Ù|QÜô#ßúxG‚ ™|ÒÄ~‰şñ®z_Ö\¾~ÅİÖ,v{g@÷Üzª ÷.¯bkÊ„rÿa¯ø•ĞŸ*ƒªë®t ùÇÄ©Ñh±ƒzØ&}·šÚcŸ
gŒ*ãçìB(ÔÜ‰¾ØïæU“ªCm¥à»†Rmü YZJx?ôKApª~5–s§$]ßôÈB¯fá ÛÒÓ,&Ùã×Ğ¿ùóó‹2÷v¬	åËqb˜A‰œIÒÒÛäpŒR&$’ !#>‘N½ô0‚÷ú•zŞL_·Yì&ŞRÄ¨eUÊ÷E€Z:"rEY½Íjƒ–1=Ø½Áu¿7+ç”Ej†9 ‡°¤‘Ğêµ4nÚsÕĞ!êWgÉ3û³«ãøIV¬$¹¤ßÖ}òÚK
\–†Mƒ7Y÷Ôâÿ(üó§'gÔ{ô†ò;âª;ÿ)OxZv¡§Âı8Dí=Õx"ójZ§ÀŞ%VÚ¹’¯hx¾dcõÆ€ ®K‘Ì#¿R³óh7Ò2¨±	4%¶>ÿ¸ t‡Qõ`º©¢&ŒueçFe¦şš+ZÚEe[X(šû¡üÄ>Hçsö»Pái'ırô*kğ£«€¦·î­"Ñ¶•+»§Àgû`(Uîİ_O³K«ŞNstëÇ7îÛF’Ğ!]ÌıB¼c¼¨Û¸Y7É¶Åúl™RŞ»~¥Á^­äQì®/moÛb‚âAÚnSÕX;SîWĞúÏ!Ôr@òÆi¥ÚÏÚ'(?’ÑŞüoĞ÷æY±<ùIb×íƒk°dC¸áXá'¡Â@±ñÔ°f«pH%AB:{İCÉÃ;Vİz¼â;I™8G7ÀKÄL	RùAL(g¢Ãö9ë~<ÎÓÎŒÄĞ™÷U¡ú&Ç8âVø"=·N+’JÔÃ]L'úI#\m^˜Ş4½!¬9î'¼6æá¾˜²nkáİÏfMâwñğÍÔûh-Âí¬u¯ÁT¥ä;ÛPZ¯2¥›'ZoRêyéPÑ=ÙƒõJ‚@âûÕÉ±7³´U%]Œ\óvó|™?şgãF06~íš.ß‰1ùh³ªg§›rLYSŸÈ
[EéÈ [ç5–§»bsÔë=ıä3´¶­¥ ëP¨˜Uà/x6ª´»3ŸyÙX^G{_>µc™¿½¦sK’óÙÛ¦Ÿã*pe†•¶»¿™µ+ª´u”­C](pMøYßfæc|™igœ@;¸øAŒñÚ¸éT'¥;`ƒ¾ºç:„Ñù„VNŸ¿ıbºªQïkV¦4Õ–3¶`€˜Mˆ,p³g	®^´wóé «Ï½Xí·"Ëò—R,Ø’‰EW¿*>Ü™¤…’dCÀdOÅñŒ¬ÕpÛŸ¦§·v¨®Û ÇL»/Æm~®Vo’à¡éÔÅy"„”wöx¦Âù¦O*ãH
’2ç¬7®áæé˜RÈ Øš¶ò²îš~"»”Ò{
ï³I»™Õøˆ¹f÷Ğ~_å}‘º–æcîRÙ–eÓpù6\§(øÖ)Ù«+º6øÜ7<É7ÅÎóùíŠ³ ½OdpF¥?öî²$ÓlÏ·Ty’gËQŠò{åêp)z9‡‹[ı›KtL`‘—Hšğä×6n¿ıTx”ıh~æ(…¶ç__±æ<ª[.4‘¸åòuĞ&>JƒZÜÖ6L¾@!U£~Rm!4¤)ª1!ámoº¤MDegşÏi]1iUñ,z85ñÎ\óekü}çy»R_!¹'Yrù€1ÔH¢^3OwÚ<ÜnZ‘e|øYw¼Ì‹ÿõÃA#³‚öå\’4]Û˜cIm]8`µøÏeÊ]¢]2¾ƒ‘µË…›UÓ¦S70ò?³*ôy¿t
}õå.Wû°K	ÅI¨nJn2Ü©eS|uˆäÖX•ëâç=Á=‚(SŞx
$¦F<¹=yŒ€²k»À×ûş-&]içhÀ{9î[“ÓÇ¹¼äŸ—:ñï|'¸Í¯*¡¬ª:^^á_s·lÆ)@ Ôê¤u¡ë<~Ñ«PûÖîR¤‹P]’Ã+E^¼à<ÙuâhUeÎw®M ­!
ÕÌRòìšÅ÷æÂqø÷ ¹†İí¶fYCî—M‹°‹tïÏM–0K°Ü\h‰FIì#ï´íŠucÿÆÉs'ºOe%9Í—1›ş.a¾¶¤4~Oƒ¤˜Qf`:‘'Ú‚¯ıÄ›½èĞ>˜¬'Á#æ¦¸âÖ·c.¢ô€ïpï“’‡^ÍpÔa?\ŠÃÜ—4h¡w¿¦U¡ŠÚt-5ÆYé‹ƒŒåô¹ÔŒVé+&Ñr¤_Ö–˜{é¡óŒûnMš°bßÅÂ,òÕ#ï_"÷·`*Ui04Á²D?R”ù´$½Ş}’Æ•[Ç‰¹y“{sŸ®¢IKUÂ)Œ¦¥¸‚eÓÆßŸA7`Ä R;Áº)í´C*c'íÿê5oo—g•'˜”Wôù."Äp·øEãw2<z9SÈ¿†¼ÙôMB:k-®²®e§ëw*r©Æ2¶‹ğÆŸ-7BïK¸}/¸ìÍÄëª
uÔ]'ù÷
X¤ÕÅUÌ¢’V>¶•+Ûzú¶«ª·ÇukõUÜ§hW¶ÍS+#ÎÎ¦F_~>Çò@Ç6ÕN<¥İ£+œ÷
d„-z\ªvWÄÑyvÍŒ¬²Ó·E“ fú·Œ¢¦ÚÖ=‚e˜y"&}Ä»@êY[Ëì£|vÖP¼Ï¯ÁÌ x†Q6'_–Ô]A© 8¦¥xŸ™\Ñ
ïouº“RhîafÑŒXZ Ï€Ş¨®”£0–­³)ïë$ë!D5Ş¼:aGIÔ•e³HÏ}ó §YÌîi>Šâ™ï(ã)©nYH2	à~‚¨±õˆlãšŠ¸“{Åi95Ó enÕ0w,	Ğ·Í>ü¸È2
{%»`ØTN¬˜8àœ™¯gªÜ\ü(…¶ÅÑYl‚ÈçÂñZM˜Û	8FáQ59JÊê´„ÖÁ¹Âÿñ/ö	»¹	š$pµ-û³ëÁñq­Ú®ë.â/´%Ç…©ôâhR¡;0#](Ÿ9^ÿ¶£5ı q Åı!Ã´ÕŸÀÜ46`K<­\ÊP'6LÙİ0"uB/I·5î3A„º¥˜€.p° tÒ£lXúör}nB.I“0a]Nänqãï¤ØA²G1’7Š’#˜¯|kŠ2ø«fh1—šãD 8l†ğ€‡Ÿ)ÛtÒ	:NÙsœ³aŸj^×sÛêYf†‰M ÂoKåÑŸ¸§ÓqiéÃ÷~ëå1ÿ=ıéˆAoŒiÀ€a|ZEêN`æıç/ia½–£ÿH¢Á=  n¾ÊßñöõÓAíÒ“é’ß[şóçÜ?¿Î„.âNŸø—õâË¡a}”²Ë]ËEá¡Úº_½ŸÑ×W0ñB¦Ÿ~6nLwcSXh	ç¦.t–)Òqà¢7[J½J’M¹BšıËÂ­£§SJVG>~„Í 1Ö‡ú9Q¡ãNaNíøò€RCœÓh¥?ìÇèÈ${fi&â€BÁàıÄ`³ğDû5¶ĞïmÎ‰b"|¶Ñ’.ù^tâk£Qw"öYÚìLûR; ^]—
Ü#¢	à%ƒsë&ƒ[u‰ÛRÈnÄRí1W–¬¥àWÄÂà¸\F&Ş¢Ìe=;wÆ|L‘ñ'±çä“úuÉÍ3úÓ¤Œäı„ä  nµ=†äÃM2°÷^›aIÛ¡0›MgDJ¿·,)ì¢,Ø91ÏJ	æÄÉ$?ëÙ¦÷Ü*ş/¡†œN¾7Úé@<öƒ5T÷ÛHJQ¦¹ñß2v›óÏ1LâK^ÙšI—²àäfH&¬v<‘Û{Şù÷Çí„ÏÕ¼w]¯û´è fÇ§_D3dïÃ³yÍCXUM[Yã[î†u1k±û~Üz£Åäbı= «©ãj‹¿»í@ñU48Èi°y&­F®÷™µ'¬nø³T1J+¥SMìTZ(ã…Ny¾ëåéZóè‰¸PÇ2‘²­ôJÀ/„™uAŸ&ˆåÛ«â`W½
Œôd™“´¶˜zËxÖè“_–n¯×'¥üŒ|Û\×í¼LI;8Î²0>²ÇÑ«°»ë]åïÔ½}8ªWb¨ÖL–N¬Ä¸6ÿE«î`w°7R•„iS!Çé­ã‰)'…\XLàY•%OØ×ÄõoÉ±µ}ìAØ·n;¶@ÁÙv%_Ï	&·ÀMo­{aûƒØŞ*×V!ÙT9—H3Úá‹¶D#	şb>«;ÕQxÑë-^‚Û	ì*íQú—Ÿ°6jıè}€Yó†´`šK2x~‹šJı1sÄJÔ 7tl`—Ïj62’ôÊy¡lÏeFÉ¹]ùSÆR!ˆ†!—%ëÀt62è´ú‹] xvé†ˆÍõ®S5	û4ÈÚ_+e	¿¾“°ÀcI2U“ià&ûÙ¯Å½$é4åEŸ;Qvâ~Ñ%T©£äcØãiéFy˜ä2)qõ£öŞ=TÚŒCp¸,¹×n_›ÕEiµ˜>­çÑÓ*¡èÉÀOå:Y_sç­r´–ñ.Úy‚¿a¤ñÁ?•”Â6CòMÁşp}•oõ.:l;SŒ
KlZC¢Ìƒ{'n_±´Úù°™£ˆğ0‰;Ë{½ E÷@áú¦JÁ‹D9Q‚¬É7ÅèÀº}¿T+«@¼“ãºê¿÷ñİf\<O€:-A&2µü#ƒ1dğÉVÄ’`m#‚Ae›à€R>1ú$V7Êm\!Q¢9 ·:-öO.´˜?–šH/ÛİT*'üíµ&.àtÇO~ +6?Å°ùI?Z$œÈÕÔË¸ŠŞ¨ª¿¦¿#}‡©ğp¶õµáÇlØ5½f¸˜¸ÔÇ,#vi¢İ:»G•¨SÎa$ç‹Ò[|kùPÚ=;Ÿà£g±É*sÄÓ5û¾}L¢Pùa¥äúA(S)‹{º“+„Å§†¦Wd1ÁÓ»~Óà•¶¦ò-€çµjK ø{<‰¾aeÍ.y‰!†S5pÑô©2Â¹È@€ ª5Bˆ«Ó—HÃg‚)Ó9òè®§W;!ıÔô‹sL"
Pßë/eØpòí›;š¯Í^3İ¶“»+ó)`WH‹¶$x–å.œ¾Ç¶ëàİNµ¯Ì&UÇeúûs¯LÂW^úËÎlœÇfÿÑö¡z‚h#ğk+F·<ĞÊÒpØ“® 'o8‚?È±óN—0ı(™0ºšCy¨C¿¿aUü°S‡?J‘ü£Ş5šêk˜t¸iŠ®ÎËfl¯{m¡€Pç§3—íïYqıØDÿàcÏã©!çø1{‘/[÷Ï^ãÈ"UŠé4ß8‡¶Ş{ä}ZÌ¶S¨ó}­º„-jø/ï|r‘é¢'ÿ1mÀÚ•8â1¬d1}H˜›kĞÄ4z8¨ä8Z…‚	,Ü×ºÙhí–ïúV¿Ğ>yÏx_°'' H×lÏVÑØû³èOŒØá»@¦Óœ¸{QÎYÆ8îaçvD@]öêÖÈr‹“¬R0“Æ„Ó™…Sœ¢ËÆup¥J¯ì]›­FÛêkå­ü<ô_È“çm¤ä?˜È Ó7>ÆæÖ—`R`2Ñ‚®gßEOÙ<b ÂÉà˜~PtÛçp6*%5¨èğÄ¾¿¬4<åó™$6 “ÈLÇtWpy3²ãIEy0™ÈØUØ›zÖ¾Ä˜ÏÈÜ×pÎw*X€æŞ&¤ İö~î©yŠ»8^”Õè€ÿÈ)©d¨.¼ñ<¢É>’Ì–íİªåíÜIyê>Ëè~Ú½†áq÷_(vEt°Ÿåo_ëÇqPãd{ñV'˜T‡±ZùèUH:ü—S¹f–myw< ppu¯vŒÈASŒ¼z‘íİÆmO8$âKÃî
ë¬“¡İI–	P*Ù<ÓåÇ){ñºp²n}0†Ó]¯ÛuG¹û0F—9/”Á·É’sgÜë>Ê´M×oå)GoNšÄRÆÀnCÖpîÄÂ¥b*Ğ+ÉÒŸZMjYÛá¶Á¤š¡xôÁ‘Êg·ğô‹¹Zø¿çZÊu½¾=^(;.2E“	¢ÁÁv×+êásàñCªÕì(ùìºmp0†–•¹Ò
q÷­qêA‘»³§×ÏPóLÙ›ã‚Æc"QO~OaÙ¦,MqQûÁ Z¡ô²¶Ö'²ç¡¦<gLAp)ã'öàú)¶‰µ:dv¼¿¤Ä,Ã‹Ø@‹ùVãcOĞ!çı›lß¦Ó¼È`@H'²NÿG³†Jw¾ =»lÄD@½¾ğ}Dåæõ¡Êuoğâ««¥É	jÜÆ\ÊÒSËIC†[¢üHÇC„0ÁQY)µI®µ?¤¢ç\?M†Är]p¤Ä•ÆŸàŸèa²a¿WYí•=Òñ•‡÷ãú€™ÌC©o‡b?¡ë¤Œx}t!İa»’a–ã Ô,—/+¢_":~•¬q9P¾Ø¶Vµª†#VUjŞ{ù	§ä$7±Ş6/áÃæ–İ“~¶ÁËçAÀ~§´q/ ÖHfM±r÷Å°ƒ#ó:õ˜}§š¡¤u¢‡Jêl¢–…"úd›µ<¤Kd;¦Çüˆ€;?Šb³†<%¯»2ÀÕó!<bˆˆr+ÎP-÷‰8ƒ;ˆ.¿€odĞ!a¼³ŸÓT(¨DR¢ïß/ù©°…Ur.r;}lBÚv•lé²Ü¸ÛB‰ñ“BáfTíy}•73¶bÁ€ù3àh%‘ßS¬9“j¹š©ªCD¹D›Wæó!ö# I7ÍbåšÉ¾¢ÉÑé®Ï"×ÖíÇ2tMRğÌ\äD4í{Œ>oâñ^h˜}¼>‚¡à’QM}’×I)Ég>"k†aÅÕàªÇÅ’hC%Ì–XÒ(s­šD¾A°ë°_€>ÀWçºWÆqï“Û+¢œd&şªÁ!…Ôæ8LÂÛ§¦|c¡p²8TÛ.ŞZÀf
aÿÂâ]åÀ4ÕŸÅ³:\)í<ÁŸŸ6T‘Z‘­µ¸ì¿pÅ 
¬I¨é–HÁÅöæ0FJı-ºÍõíU¹jsAätíúìÙŒm{‹Ñ#ä	ÛŒ`usï‹2Óíù5RÅGzÙí]Îê6~$sÜøYI$ÅsÚI³é¿n~„ìğDØÏÏÌ(Ò`x®®1±’/ÌüF”SÊr/…Ç3¡K¼{0Àí¤ ÛB­}÷@¶ˆfúk©rbö¯8Û/s0­‹}¹§ÙĞ_ıèâ-)['¶@ÃëbÜ)tÜ
%ıù­’ş´Ô$A†.ÆMRƒ˜'LZRoà]¹u~Ğ½Pµ?4—Sì<¨”.˜À©?àPÑsG±*Ş|	—	rí…+ÎÄiÌÑˆàë_äÇv(éËŒ&h¥¹Í5úÕF½˜]¡8˜'û¢å,ñÜt{‰îÚbÄ7î¼lk“K‡ç›¹şc0õ½÷óÑÀ-|i£$¦è&gT&ò[T¯nı¦QV€«à?$®nÊŠ3ĞY%fÎ,©ñœGdÒ+”d,­½§¿”’ÛBÔßb.)Mî6^!mHëÿšQs«¼ğœÒ¦·MR ÃÁï:¤ ,İomWÑBèÉ#i£‹Æ7?Ú?îi®-‹•|ş¥útAFU[ıèeÑ[yÆ9kxìyÌšÛô±şëb„vo”ŞÉkĞë››(ÿùÊÃz6Âõ4Ÿá¡ci·2›y¯QÔÙ=[`İ(ıÀ*Á%ıŒÉÜıÄÄÅ?­‰	¤Ûd a¤4}±”ÓµN¶t‡
AE0Ëó­ğÄÚ×Sô¦%%;4œ%ğ¤kÊeƒœÉß“GââJ-¸7‡£ó@ ¿ÄEˆàK‡ùNıÓ;qé×¬ÔOpôks§™^s(*XÀ}+”Ê* _4¦Á‰ı¾"än‡ÒşˆÊhˆğ{5'¢ í‹÷’9©…¯¤Wï YÜ¢ÕUËa9TØ•l˜.ê3ßšĞû¤Î¼%{Õù‹iì	Å"yöÒ8CÅFk}Õ1­ŸÍÉ‚ÛÖÇEv´¦(5 Œ ãZ	!3šLîY¬ğŠİThûÄ¦*°3™õÍ¸¼ü7ÖÀQ‘ùB’È˜Óc—?Š»æO­>ò®…A‰)Q‡/ı|Óïè<»]}äuÛF'¡Ë‚½Æ¹…tY™@¼lµÖÇF!¥íYÁ·ø‹;t–ªK;P–ğ%0®¤*Z\¦tSID7nŒÜzoıÌ}Ó\½)ø*÷ßëc^‘3kÒœFh2Å†ı‹Ì_°’òA$ÊbÎø\Ï™¿İw"(9°5ùôPñ0Âó£®ïhj’EC>÷w?ábÔ9ÈI¤–|ãCJ¢L{ËÊürQøéõ¯û~òîË;Ï%G…)	O`yâPÎU1 Á­ªÿ¥ŒäæNÜ6xql³ìæ¨I°Jö#©İÈÃœ‡¯ã™p‹!¥0L K;x¨HÌ†qœ6±½ğéÒ†ë †bğÛ?Âps`BÙc,ìy`©Œ–Våá—<‹uå7ñÛv·o´íÔÃ“ÿ*_Êø%är¡–:ËWİ]XîåÚ^^3¬ÈlèRªüóøeMßr™Yµ¶uÑB6>j~â Yğô¾_ã¥ß+íÁû÷Œ¸êToT[·émÜ4õµJÌ…¢Ò£/_Âñ¨DºÊÁı ªtÖÂÒ;!»wÛuÑtR…+Qã”½lU» &k÷r6×Cí *lå³€üZÕ0JÕ=«æ6OhU_‡]`—«7YWÕôô+À•/ Ä„å%ŸaJ}bıÕõ€J5âŠQİÏÂ×[Õ]Õ°D+/øwŞãÅHô2°›Ÿ¬<¹ãªÖ–İ¸j,É ñ€¢X‰À{ˆ *
›Ñ™+=z"7n:nJH›×ÌyL¬e·#ÉßR2LßO{KÑeS
…‹,˜Œå]r2“t“Y6q—Š j¡)+7İ/æSV7Ã¾^¿º…ú›UŠ¸;uÜë—l ëÙí©á½¹"}bymt _$:SæL¥–VEªW{³¼…”²y^ÃJ¼5­”Ç´[hX¿xµ'è‹b]Ïñ–¯Úïl¤şÌMáS#çy—5Hª*°r0´í$‹}hË®âÇÑzûÏ£XÆGlsR‹hó1Û Gîz*¹‚Ç˜—÷Nô;‰¤',V­^ q’…åÁ.W„i°µ>ÏÈÃÌ^>îØi‘¾Ÿiòí¦„ãN‚ş`>rK8Ñ¯xgí¤¤l¿î
ûG§§i“8$”ÈÆRáßÏW*®(ùê <hË& o›â'4Çâ)ÏÈ5^ïbcÍl¦¢‘‰ŠZÿLëøf¤p2üÌ¦Ú`’FúÌyD$üV®®¸…>cèƒ»Î>Å'Oœ§‚Ó`«ÏÅÍU7çëŒõ×ÚÕU;7ÍHÙ¨?¹äİÁ€X~¸Ú‰0€«¾n;Á³›4//Æ=”Væİ²ÃÌ¹¹_9Yùá,9pœİaaº9½Ôı;pÃ€şáR~@‹}}îöı˜ã¯cèÃ«8`ÇM¾Mê)æ¡0•Šİä,Ú•Aj¬»••ôs¥üEÕ…¤ÅA=p„ñLÿô²Œÿ~&¾:œÜ©¬âîZ„%Ü‘MïsÃWßúk­ÙÕñ/¡Ä[‡IjËùtµ|÷oú!$¶8&ûãòğ—ëMø{Ù5æBŒ‰h qôJıål—["›N—Lvp¦Îo²±ûJG$‡¦Z”új0T¨dÙko¿ª2 —y#	ln*"i¡ó«Ş=åê²:–UùÃ-gÖñ9`f(à§|ö™"N”@.@hAâ-ÚÙbõn†ËÎ“¦iXQmˆJTÙ:öé¬t{Ië]õC¦X«}CìäëŠãXXÇ_'ÒÄx
'±ê‘—e)X’0è	œÖS‰wuP¶«¿ñh †îª<{šÂ9=É‚ÃsyZ$!œ+çÖI7<©üÉÄ ÷íDÜ)OŒ àü4_!ŠMIƒh«óĞhõÂ‘Øö”ğUÕø¡)›8­îÿê%@¤Ø«Êú…`·Éàƒî¬ßFCF2‘§ÈëŞAÎa÷0›&»‹ ³·ø —}Iôšå3–qÿ7g¸ÀµTˆÍ&®jĞAnö9bd`7w÷»V@¤x›<¡ ^ 1Çƒşˆnµs	UnÒÀüÌ‚tJkRÿBLÑcˆqe]ò3Ìîñ>³€ÍQcF»M3˜T¶û3:™B‘^N'Tá‘åßr…òƒu‹LÿCsi¯RÁ˜Ñ:®•9UE¥BQ]tî3M÷-…h/•¡ıióDQ¤T&!`…óƒîáe­†İâşŠ´qÿnp«R7…ê½jê0×Âyhè¬œ¨åóá­îuõWfõØnÒS”’‡şp`õÜ†(Ï|€\%'‰Ãë:3up2p5TO‘fNÙ.h=(À„¿k”5/†uWvš˜PÖ4ã_sï®L=yş–”ãQGş3†t ¹TÔ¡ËÏú€ª¤±ŒÌS!)½y³Ä£5=X–Lôpƒ	P2;_a±ÕWg»ÇojDÅÈ^8u‰øôŸ‘MÏÖön§zZ¡Ö}+È™CëYı1à7(¸*Ò?k™”#i±IKªË=ıú@ÏşjnàÇr£¸½yFÊæRf\À{'ï8§OÕ—Ü\¿SûzT¶İìnMÆã‰Ö?0t`]ç$·çë#ÒçRrÖ¦d-¹Ñ†m”˜\€§/5s.LoCk¯´àíbÈ+ü
ÿvråq@èd›æß3œ³ÀfÚòh'­ ë9„9&äW[n«6p§ËdƒæµHdC`Zy<ÖÜ„ƒ\´a;l	îlÉ<Ök8ìSĞÙãºĞÜ‰°İ=Øµ”ˆÏ±jÆ±fÓÊUâ‚ŸA³«Ğu±£YMQzäã*örıõ«ÅBÓ†ûöÖ?¬wå³´í/Qª;Ï³ıİmuø0‡<)Ş ²˜¸YÙÍ¨„sÀÛ"Ò}?WKX´‹/¤PúÑF{êûØÎ“ï~W°pxü»Ğ\5$:¯‰ˆÿ.Æ{´ƒÕ!ã@›sâeœØRpüŠú õPrA+J£§±§Ğáb¨Å"`ğrXõÏe(hàŸk½Ş|³Vµ\c‰rJû‰	úß8U<>~¤ğÏ<ÿÌıvÔ¬rtã*~4Bfì´d'ˆz>µ›BÛèT¤Š›vW¤„ÂËÎu„(RWğº˜Ü›é0©+…… oB¢(ÔT7Ğçù^#¼ø•À“o”ø[iÄs°(~á(¡UË_4Ç§ç6«G^wº·Kâ¨*hıÄU*C´ûØM½ö]-jf{‚D£b4Èw¸$°’ÂË³›gš%Ãlè¼rUÎ—Ç`ÒŞiÖÕ°9²hZé<míÊE»k°‚HÚŠÈ×N˜]ğ–.§}êÏ‚¸lĞş×ì\¾^8sş±„{ôâ2üæ©¶»ZµVøî~û¹²ûÁ\Naa ³À(`(rÍ¶õ‡xÀ{-’&gÀŠÚ¬=øÀGl÷— \CŸ/„Qh>]ÇÃØ"“×d2pIËáÛš( ‰CÔ#2rY€e9XÆ«·Àö\ÄoˆtÿØJƒ¶hO”şŸŠ°ŸÀëSü3L2_Ï´÷ƒ	ÔYÔ@QÚª€X7 áˆ® w²<c½à@œ"Q}+:í™êˆğÕX jî¤ÂŞîJzÁ/£>íYó¢A»š –ãû+Ù‡ZU¥í‚ùA@ù†fî,`IäãrÍæñ×sG;‰t¶ZËWF‰Ìp\¼Òà77¬óÄ¨£ÏI§$\°XÜ–»~N³$Eìñ)”cj‘ówkº·¾.‚2èojë²˜µ0u{Ô"å9SnÕ.òpt%Ø£A>œs(­«½óp,Ï“˜ƒ,6hÙó;…çÊĞúÁ ˜á$f6Pİô	_7¿¾Ç°*•f“;s­¸$çáşsö:]Fš ,„ÚâŒ/+Ö^$ÎSYHìÒÁå=öÀ7ü€á«Ù$º­(¾Ï±5CT0w µ>Ÿ¶Ğ$'˜€¾Ì™´y®ºzh‰-„¶™ß6Ár½v[<ú ­5û«Â›é‰ÚÇw¥ªÿ;¸&)«áƒØé¶İT*eéëş±¡H0Ùt¤GôíÏ²ÛÒÅÒ²0ùK2Ã›	?æ“< K`£÷b&QqP,¾nÉn‹Oåş!_¬&´éšZîn)=+şOUaÅ_òLâ¹åŠéL˜·^¸Ç–Ö¶;ëG¼ŒIZŠ¢¡”ü¸wx3e²ê¬ƒ¾7ëšílóÖÀ@M2¼
tÖ5î¼š-ë,øı¸ÓìÙïèìàò¡b˜>&-ó“V!3õ+£n¸oVYŸİµïd£WªyN!f`hè0ÜzÛ|VÈ¬AûXî}¸ÈÅ.©Ìš…¿¼°Ùp/ã%T¤XÙ:C¯ìsŸOU@;—‹Û´7ö{Óê­'àªçû,áò»A.Šh±?/¡Ø;Î±¡˜Y¨şd2êÇ;ıè{@ÀÖ ÊúBş¥Mc?HİÔ^m'ë„¡•-ÆTó©¦[ª>&ÕÒÓLélyÔ»;Z`TAFrÀMAk%S8nU¨ƒ>£+q~¤îé†¡¦G"l2MÑ
ïk3cŠŒëÊ|m!­~S½lõ-)˜[¢Ğ	"3Ò†Ã´†¯ƒ
§@ö0øG¡	¼àgøêüO,¿:Ì2ÀÖºÀ‚°B+ŠúÅi§G‰ÚQ8Øî£¶»µ$Õí?ÅÁL	s™ße‰ËnRcisrÜúˆ¸İµU›š¾$óå\µa†2Áüı`³!öíu HEúªç/™S¯æãè¬·Ğu!jtœBÀ2öí!™ÈÓûçúŒå‰4F‡Şe(NÅ5Bf*xµ÷ãkÙ`¬¯İ›™F$L¡`V<6¸r‚ç!>6ßúË±iëPê€#¤¥•./ø!—İñŞa¶ çârÆÀlú{‡†5£İ’Í@J²gR<PÎ+\¢¬-QOl¬ùÍÛºÄ;—ãVüI85*Ou”Rò{¦Ùã²Á.I‚Š’áÌÇ1%báúòDˆ7™d¶Ï¼Ú`ô(2ëø&V¢6/ìé)ÙqD¡"é™âı÷Ü‘Ô È%Â«`x/Ò!¯½Åâè´9¶×ßl“â'„¦öİÅÉ?¹ @|ƒugÚøÑ¦0ÚÒ]M¼pÄè³AU¨lq¸g&üCºOWqc¿ÂIÁé’­Ì±dtB“®R¿Â£ı‡¨S›á•Ê‡}µìYëœŸÕ -G„ß›mÿJê§Ğuï”Â]¹•Íi„¯|SüxÚ«ü–OWOâêñlwğ
jtpå‹Áåb¿ÜûÃ[!¬š·O°Q s >¶àÏÆÈÁ,¹Øåo€Ìã*´'™¯[¦úQ?0w:²M¬dò½¢¯e'K­æ_ö™\@K•\æ…–Ìë¥$ÀŠçÇ¯Éˆß·ıö¶¸ÕJé˜Ù7^V¾²káL~¾qÊhTrY¡§`ŠU*Ô™%Pó O8@°–Éyšóy~}.8øRÇáKŒã8Jÿí(¹æ†›:ı9Õ£PƒYSxÈÇ+iŒ©µ†Ê±8„Îhåa×°"~Ó›ÖV5¸6dx
Â:	»¥—„"öE|Æ)Z¾ˆˆ’¼Ø]ùíAtkÉsªüu†æ¦}ß6XÙ˜ÿ–ò(Êt¢+³TRer >Ÿh£‚föÊIĞ@ü†°çàFx†ñÒ FÚ4kb!^D¨ °wßª%=Ñ°®X‹J£ÖØÓP±„De_
”m©…_tï^»óÚ“á§õí46âÜáè9,í›ËBÿŞuiÑı-UeÜQš©;ÉÜ¦)ğS.vDà—î˜»ñÒæ€ÁtÄ¡V”ŒL7ø‡‡^¨!S!z{äXÜÖå:You‚ÉEŒşy³‚ ;Âe÷•›ªt%e/Ø4h3Ö0jjí5Æe©ÕCZ+ğ=lB;Äºßw'ñBjë2dÌê”Qrm,9^ó'éÇáwê¶…6ŸÅdÙ¾ìÎÏ‹‘Z.²ïCDãã¡K€Ö^Ó lb“ â—çöM>™÷MçÖ:ŞR½œ:@‰8ŞW
²«KuİÈUßS¡ºpèŒÿMs±tqÎ[ÁRèp^åÛ¨=“*·GÑa:ª*\Ö~'Èz¶t[z÷øß  ¿3msßV'œ !LäJ@gzO©]“fQ<=ag®j=TöÂñj‘ƒİ{Æét~¹,…‹€š§ù(eÖGşp9Ş˜«»U ÒÈçâÔù–âÀPaL_ƒÙÄ v,KÆl5‚8ğÜŠÓµ;p&9İ j–V!×(ÛoX}{×ò48xCT hôWUß5nÕã_»vw=!”±ÓZc/gJö—›¥ù#ÁU"!æo".U‡ğö)¼	Ï¢ä¢a44¹¶ıá-CW–âÉˆ— *¯½>Á	ê zMÜ&?\\¡±Æ/miÇÅß^©²2‰Æn¥T‰ŒèJ7¦…~§ëÛwEFª,`•1YVA$ÿÊn„şšØ=owÅ¯*mRğƒáŒÕşˆhj³H„ŸÉxúHtÔ2	Îì]Dá,ÿ6—¼ı®ø;ŒKwq y¤;•èôAwóYZ/|ú#¨—–Ğ§¹ôæ©n©Ósæ5İĞñÚˆ,^Ú©ÓqöÉV3@æë™€!@İLwú!å0ß(=LŠ±şÛe8=›¯?<97‘Ôug ÓUj-× Ù=5Ë;ÜK®’‘±„8Yk&(sØ¹Â×E…ò|a×XÉæp¼y¦ñ·ÛX–.+Û½˜LuŠ¯L<B £™ŸeÒÖ·(ŒOÉ^ï*+Öøz‘|ÔkØ¶ë˜%1ñ^C4˜:«îËÉZ©˜Ü'¬æjrÙïõpx¢6Î’\¡-ÒÖœÂşX¡¼õï¹™Ï\ŸÁU¹4íßK_¦‰ñÃAA¯y}|A‘WÖ­¯´¾€ûXpã´¦ònH­†™<`qoï†Y†B—+3 &|ÇüŞÕ¬V98Ç“İ›î§<¾Ü±cJ Íœ'í¬ÊèÃÕ+ˆä‰Z(‹ŞD‡¨â<fkÚèB }L»H[¶’mÙ‡<d‘ìÕ­ô›9¦Lä[Cı„—­®à0µÅæÛĞ¯¸úkè\…¯_hgV¸=í7ã[×
( d2®ÌšIL Üº€À4&Éğ±Ägû    YZ