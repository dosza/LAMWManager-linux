#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3691404558"
MD5="57eb9bfae441e5da121133c8304b92ad"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20732"
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
	echo Uncompressed size: 136 KB
	echo Compression: xz
	echo Date of packaging: Fri Mar  6 04:45:32 -03 2020
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
	echo OLDUSIZE=136
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
	MS_Printf "About to extract 136 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 136; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (136 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáÿP¹] ¼}•ÀJFœÄÿ.»á_j©[÷RÍãZ&Ş~›=ŸÏ"F¼'ºY~·İœİh`„>ö«L÷OËöé…Lô6Ù<)m	nûÕozÇA—şà´”œÚìkEêcë`¬«RBTÆsÎ#i®æÈß¼Eplİİ~1€*éİVµ›À+æ	º—5ÄIö2æYÉ½R€ûÒîä•òĞ£*Nø&·zb'ñ!ÆÂÈ_3‡âıÙ‘h­
c—#ó3–Œ5êz4J&‰áúÃ:kéÎøsĞ!î!Üµ0é+0»:HIÅY\^;¶èÔÃkŠîãmÚÕe'|ÇïÖöCØ!6ë.ÆEÇ‹¥Éo>…%†¹èfÊAdÍ&ß%õ¦œ*aÌ¦~ï3'3lƒ•h
5¨"^ÂçwÎSK$2r5¡¾``ºıXf–ƒÔ”cG;J²)•±véBSN[» ®“ŸıV9Ñ1ºÜ4³ ;àØ%)ìtõÙgÌ¹÷©Í™S,FÓ›/E6cÀü”•
ˆ~³ª›Tô¦CS£ßÁh5ô»…ˆ†¼¨,,›§~’ÿ;'2 æø«i/ò¬“`qP¾f“è'!Ùp0ƒaÕa )G	Ò¿Z%+6alºÚ	ºaÅ£ğUèô§¶'t*…{ÈGb­×b~Ò@è
³ç £#£rPYLŒÿ'ÆæÃ«å3.è]4èqIå²&Ğë%b{Wé‚*Z5hĞ¡ùgÇÈ	È¼ºKƒµü+¥¨ÌV`ôxnÏ %CwnÚs`>ƒc—B±vŸö–@zùúîßşÛ4UÚ¿ñ‰ÖqÄ1IÙÁ~â8%¾”ÀDiyZÚ(É%H>Rëü‹ôÙ˜ıu·D\¾ÛV¾ªãÓØ3õÁÄp7nK_¥Í`>¡Û^BİQŠ&")š³Ì·+5·oìÓ+•óO£°¼°Ğ C´ğH:­M&
„ÑıM,«Ø ·¼ş½³‘Ê±’{¯2œY$„5h >Ÿ’¨¶²ó_Ê3Ì—+ Â˜x1ãM©çi¤–èHĞ²hÎ^aî5\Øwú«¹­ùE:«b¢1å‘DñÎ§Ÿ¤Àˆc F±4Ò:;Ïâs*G»XâFSŠÔÙîÚsíRÎ…`„.—,=ªÉI-ªÎMq±§<Öaf§Ó Ö±ÖÖÌ¿ûÏ#¿pŸüÚ–¿©Ã˜µw˜¨ê"å5v`Ê;åâ”‡bWZ¬2n$ñÎ6K›ãlóõeäü˜"ñ6‘Ÿ<:ÄÉÂŸH”jÀQ“DiËNûĞ·$ü×pF²)ôé³|å›dZ4D\´Å‘ggS9‘Jf¸ppÓ7›ÍÚ÷«ùe`múJˆ@1‰%h±=ñ7Ïñ5 HÖ›&ÿÜ°o¶mQà@@¾ªÌØ°Ò§Œcètõ–«€re¡€¡I^«®/õÚy	-c)`^í°úËlGU¿Q@åÍLü9}üãš]SÃuê6“Ù‹%ÒE|Æ3àMG¥Cåö<“kò&Ö9zPøÆSŞÛWşb"«½ C”ÏDüqôr(şÔuxº 	>ª&Ú:O·~}~w‘µ0´À~]cfËçãèAÊµX´:zŒıåôNˆúŒ‹¶ÑÚJ ¡å[t	öçJ{¡†EP2võG€neaZ<Xı0S—Ÿ	ò6ÜT›œez#Ü±Ü÷š"Æä¾á™Ê¾ÅÆ,AŸÉ€$VˆÀ¦^&§¢õÈÀ±±¡¥NÕÖ:Í+Iå/mó;]ii;(lXìiÂÿĞ<$BT*~‘ÃÛOºÄZ©pgúËK¨Ø–l•‡Äà^zës1i„f‰°´ƒi“£°cé™—°¡6
P~W‘şµæñĞŠT’ˆ\9†K„?ÿÕMdºˆiOñ’Ğ0™Õ›VXd 	góeı•gWWtÉ†7$Ú}eÍP¡şª¨ËƒŸ_j¨(Íä{ò-BãM WÌˆeÅ
æi¿õ-LèLV?*AS„qÏ`“ÍÕÎ¯²Æ'%#[&™±¨é]ææäU|Œˆî¦ÂÂhãÙµ*` c;‘ˆÕî`B¤vñ%®ãl9®?b³<ªôåƒ@«h‚F·t–£tœ{ (öó­my³}#^F^—êlİ"òIñy^›{ºR“(æâĞTC
•Q¥k’î“¼Qh;Z(-¿O(‘[¨=¤£ƒ) ‹Ò‚ÓóqØ@äDÏÀŒG««L…h€ÆY«†!ÍñÏò[DFK¡zÕ¹”•&ßzÂuˆmyG:MîÈCÄÿ…KWÅñšr‚]ò>
G¸,dkì¯Ğ¯JÙe‰íƒhds’h†¤ØñV9}xª;<N¤‰1İIR°ì‚“x}‹0aÌ2|úQÇ‘şl'B†÷Ò¡“1õNo²cÇcuóÜş3‹vu)'Æ…kGºdD&ô ¸~1äè¡wCÁ.]Åî'IBø	\#‹]…„½æı®‘€¯ñû¿qæùÕìé`Û²X™©æaÄ^<f<Ùrşú­ğ¿M©¤n 8[ÉÍ+—ªuj+V¿)’a/APW,g“o# jÉR®ztNÀNoù|˜ëJìüÙ¹óÑØ›Ë­mêtÿÃ/Ô~»ou1/.™ 	 «%V‰¾<†âÑ¯†Ğjo»{˜Å;d›§ÌHÈ3zÍTq‚M=YÒıõœo9Í…ÍE¦Š|V™ÑãÉÀ†––)â®6Škºjj$àDÂSŠª"»‚Ñ#>XKzY¸½KVÌ¥ŸZ<Óà¹Li.Ê°ŞÚ´º‹Ïg˜Ï?£Qàæ‡„ŸXï·
®'*)äjD3Ò T/U`ĞÄ¤Â|Äàw~7´íÒ½)¯øĞ1Ó5Aïã ˜eÿ]ğû¶d'ßĞ*í„¥©€LŸv¯Y{Ès„ÍAìEk ÂğäP•¢ÚÁ«Z]k«b~Ù©¥ïn¡Êp¨	2xªk¨Ôö1 –Æàk{šŒ4µebâeVƒ‡¥=ş½½|.a-P‘‘H½gaìÜ èz_SKŒ{§–•!ïˆöÁ0Z ç¸Íş×7=BW³©Àş-Û.¥‰†Õf¾(ÁHt	!l˜ìŸíW'KæV"İ['“kú5pSèğ{§Œë”"UôË7ªTIØ©
ôÇpÿ† ÇĞ-—DêGÖ¦E¦¥$ ¸ÇÖo_N`Ü·ÍG´Õ`[ ÒWŠ’¦|%{múpf©>ÒÎ,×°Ü>Upd§™‰%	I©Ë!éí:Œ#¸kÀEÏú°#)³Üuí6b2iüåo)B1Uv¯™® K2Ö“yĞ)Åµ^g0-ö y8ø’SõÕ¹Ì…irë0ø1äÉRÜÆ°h18[ºHg×Á\“Ã4ÓĞ-Òül¿4fh«}lÖo,Y¹¬,tT‘m]Póe›Ğş ï):»çb‹Ødj<»1X,G’J“¿æ|ğjYP¡LÅ¬¸÷s`›>ÿ#E²!ºi4F±R?÷îrËñ*û¯-Ü¯Sè+´ U¨tEe=í¼Æ£íùHÎÄXÕ6Lã§jD	[W:&ãg$*èø şÏ]!\n`Ø#×ğ†J•û±§sm	ÎlPÓyÂZ¯Šàêw¦?ùŸœAYHDßZ«ÛÎ ª¾”òîøÊö$„*m4ÍC½Ï’­Ó–šÜßå•÷Á3±½í	‘„Ÿè÷ğÀ™ã:[_rL,LÁc!âˆ”­TØ4Âo˜ÿ±w¼ÓU q‰,Å·9-*¡d=
w5ÇIxrôò©€jY]N¨ŞöÊlägşÎ•œ‹Æ%©½»§TËÓÂ¶Ã;wNbŞlàe• ÁêÌeé{pŠš·ŠXßx$rµ|9=•]¤ 8dh‡Ína™Ö5nø¥@l˜¶;Bñ$ÍÛ©æÌd^‡üŒ‹™îv§^Æşw2S¥­şqRĞ¼È!(5¢“ú¤”î|ówüÚ¦U3½x8níEgåğhfz­'‹î	"™yú£wlÄî`…xy*¾µ4s8cÑ·+ÿ@|È,æ¶ÉZ A‘+®›ğ3·u7@şaç‡Åjæ¡X`ÖI…	‹ÆäBèE´¶cÙÒÑoé×ıÓCò	’'·Õ5n+«’Øéc}ø´	±Oš:èÒñ>àDãò:ÍJá EİÎ§/6kğIU\…;Ì½ƒYb,ƒ)… 2ÇìlH’3ªv4$Aàã|øÍ•ú?ÂZk@z)§s(uÄM?a(“i,„˜¼Qù@q‡¼™}³;aM™¹>Àé-òÜèIøHÕVŸT†'õA#úlQ!hLàùêâ½HûpÉ(cF²°ªeFİè³m¸˜ÁÏ¥X;È…\ÓğÇòj›‹’2Õ¡_ÅXÆ
M9Õòéµ‹¶§cÿå¼jb:®ôÅëE}èù™¥£ú½á…X4†óVUËr"ï†êY"ŠÏÇ5fÎ?6¢éá–ê¡ÀÒNz–U"¸İweíå£+ÊEëØ»k$qÿŸ5²Ü*°`TÄ‘—4¸·ˆıX'T-«ŠÚ˜õTÀ«=
¦{oc :_Håû·ño!ªó~OI6Ê¶‹5eb“ı8;n·t¢05¸A‘J*Ÿ¬?òmSÑJ,>=fõ9rÕ1'Ó+"'æjÇË;YK¢AïÉ‰F¯şçPX=Úò’f™c¬1ô’ä>Åb¥)´é†|FÔÔãYZ¢³²»!Şx4»45tâiª“Ü{‡SQüÆ–{‚bÖÒM`dæ—~FÚµÔ³g`ëöÙfŠU‚üÛÒNUäÕı‹@)æ’sénB\şEŠNNqôRrqÉC"±_$ ¶\;rl‹tîÖu’<Š±ğm(CŞ€Ï]µ.IšsgmX¼AB0(„´9ÛXÖúşcÉšì³ ­éü,UµRıöh5…=¹ ¤b<É½Xİ²³Ò= [ö””R(§NïB>ÆWZÁ5w\^L+O•ÏÏwZ>ò0wª.ÉøêD^qtÍQ&cñ>|¼r>)p^:XŠ/¼—GP	Ïaujş$&;va³†À•E¾e¹IÁÉ!Ù@Üù
À	<­$Â­2cq`‹(ÀÔ™h"º	8)®.¨‹1	7û€¤Š²á¶¦qßÁ&'¨øÕî ÿåîæ–JÚ½~Qt¯jÛ³
¸£ks™ÎšÀÒ Ä|+2x[Ïë_Ff—§mª’šîøÒ?)NEe&¾¿r*Ó	\aˆŸ]L÷”Rsz”Ø¦¨eÒ¹è5¦%üãéÃD¯ÉGJ´‹?éBf-]˜t"¿3‚2•Œ)„Ï{p¾³Ëkí7m'Œf\ tm+QÔos~,2È•=–öáüÙİ%ËxH\Mkrã±£õèà—`1*á  5R²2æNDIyÏ·X_G hv•FğõoÛAÆ×å8wØL"(”ú²}wŒ<ƒé%ñ`cNnjÆš5¹¬gÔè†>ÉßÙªCİ
„ì"E7,Ëbl–‚Ü…Ÿv‰¹õ˜’°û~u¥ëzÒ¹²æë21°ä|wş(pİÌøL¼<İE¿L"»¦lInñ:Pş¾2§ãXgdùKW>÷l§/}îÅ©š»†ÓÎgİZ$¯JdÇ¦9Å…$¿L­3:MiwË	GÏ`î†¦ºÃQMß…ÄÃz‰HRÇîDæÏ,I%JÏ„Ù(é{;aòšsÈ?_}ıäÎTL¼Yœ‹¾-ˆÏÛş_êõ¦¦¯°6#6‘ß`KP7Ô…Ş!Œ²|‰º™t¹5vÚC7.vØSg4şSXoIE2`ÀI©pÁï˜ è*÷J˜lLÈ÷W1—óï*Eİ8ŒQ:EŞ'“‹2Ÿ±2^÷Iœ"m‡ƒ¦,¬`ÚZal§—‰\ò%_X&œvÛŸÛî=@Œ²+ÕEÉB`FpƒŒ[kc)É»Ì®ZÂlÈõèå<ïhÁq¯¡âxüùV¯U10P½íq,ÎnMÕwı÷\Õ šp\òü O\Şn1ãB§‚ZoC—ğ‰¡ŸZ-­ÆÉ‰óR•¯Ï5µ–Ö®s HªË¨ÕM÷ì®&’ƒ*ıæ“Îhì0gÜ+=ñ¤R
‹!G€T\Åo—§.Èı×x78Aôòòü#Şä¯Úƒg]#ò×Úª:—à®üMö£}ùÒÕ®Øw#_O¤Ìû“
íãÉË<’·Ğ¼_”=8Z´¿bU%¬hX€.,œ7FOúß!'¥¹CÏ‡Ãb³ aPRh—U†Cl"YòrùĞ!é÷Ô¤_¨ïÛàÆí¶ñ½ÊH“0»r˜^¾Eï7Sûú3®xDÀ¨§ˆTmŒ·Š|À¦æO¨9S1`§¶îK“BOQ¿ö-""Äm"és¶­C—¾¸Ó|ÎòIê•YiÂ÷VıŠöúqªˆƒ}o ßd¾ ¿Ôd~AFK`,mğIÅ‡dúÑ¥½CœŸn…;g÷9IEÛ)KNş1 
‚æÑ±º{œŒW­ñÂ-ş~_È0ø†°P^„LO¥ÛFÈr~ gjÕRbDó›*£JäcğD=v*)áÂØpc“§4MqÍÉ# =††tnV%œH–*D
©O¥—Ú•¥×&§Á	†Êõ¢ë`hSãş@7ÀäÑÒ…P "ËWuLH¼~‹å/3vîÄ½_³;~úÃÀ·„¯I"–òÜ"ÿ‰6oGS‰›8[LÔ%ÉÖJ
à´\U
d&;É#qæ®%—z|²ô>Èíã-ÖëğäWsók‰ÖiòÙµ¸ãˆM¥]©|1éS+‚Ğ-V›bˆ\_ÍW/‘¾–‡SoWÿüÎ¾‹á»J1=i|®«¾UY½ĞÌH%œ|†Ü0Ğ\š‚u”(ãU®TÖ™.™dÅà<ˆ«BëºIÖ.-Å¾ùÇ{¡C3- %¶§ªû/èõı>¤].2÷cç7ZÏÌ”»S¥ÄUjÚ%Û²°êÃl…ÊÃYºİN§xg¹œÂG9}’ÌçuÒ'Š]©nèÇJ·±8˜ó\8b{7T?í%×7IÄ,¢CivüÛèeË "vÉóÏ¨Q¶ŠÈà@mÅr…m}ˆ·©í3CsƒÅĞä<ÎÎF¬V‰ÚC—/±à9æà-ä@!PBV¼&Ö€€ò™©||+ÛDÍ.-uÆÿÀŠã‰6õôÙ	İ]ç¶Üî´¯ÿÔWeA‚ƒ|äĞ_qz½××
o€§
Æ[ğk³%­NïcZ–NÏ`Qòi¯6SDÌ¶õO™‚&u
Ç~Õ×O†Ğ»¨à™:?j¼b&‹Øßéx¾Ø$¤³Qtº=‹ãüsòlSoWKÔ1–°%£æˆúYi6Ş£iÄø
wxµä¤oäÅ-Àa;î<n•9Í´X9C‚Å=Èåœ¦P¦„ÊH‘‰T‹”Ï¹ñ	`¸ìªJãÌ¼ßÉ4 .vQè´¦®8z’¦ãàËÔ˜[$Û	p¢pŞbH1ë5AC“M=†º›VC hı3lù~²:‘Ï*Eâ6¢¼sÔ,/ï^ÕvÒTú¡;ä İ¶.xĞ£h¥&ƒš5ÒQÍiÆ3:1`e.“¾~bÎò€ôôÜ8Ó¤­ôGJªê(‡l%Ä‰]š½I8_³´‹Ø»Dy‹iõñœÉqÏRÁ/s…Á/Æò¶¾U—”î&³äøØ«è·OèªEù¢šAÎ¾Œ"%1¡g@¨Cg5©‰îĞ]’é{Ã–£=›R‹SšçÇ)û¢í½2µæïäõèj@ımgÉá—+JåİTHÀ/@æ@Îİg@Z'ÊR„GmK_ß<„wò’<ö…+U÷3;'Ùå“³É”Ş‰^Üv>ûW¡œ«P¬¶sœk˜•§ä4’ÒÊcÖ›.Îuui‡êDÍQ`‹ÿM'Š"Ù¡ÇoƒŒx¾Öş¢˜*rgİ~YN]cî#êĞe9‘ˆãRks{š¡­÷´`üZªÒè¢TgâŞÆ†üKOÌeLRõ·*ùbÎÓ:C¬–øÏ
iĞ±¬Ë=G>î‹Ãœv³¹çìg÷¼\6Ø–˜—f\ê­fåO©›¯,é=Æ®œb5…—W¾[YÆQ·¯õ,=§ÀëÓhêCVo‚Ï…CR5›Í.¥0¼\Şğ€nÒu§«Ö¨BîGo¿İP§âuìºÊM—åè³©I7T«€]Ô®ïí†'Å'Vğy)P6µoPÜ8ªÒ£Ãc!CUP9•/à:“
´	ÿÊZJ‹Xõğøvgv€r¾›™ó5x!w²ñ‹ç2›³Ùë[¶y[ïÊ…ô©
Ùähb\Ï”'{û-ù¹wŞ† ø×mÄË3‘"R(±:¬ïZ³Ó¡ğ¥?ãjÚ 06€I”éã¦›ÁÁ+Õ(óÂ	)˜ àµÄ.¨vÑäEÂëİ0uØ÷$OÑÿş‰éhPÎ/&Ãœ‰!Y«°8¨ßÑá±©ÿ¤‚9OúÄ‡‹Xêjñó8CÌËC™×[?HO·²¢ó1>f?…4uæÕí@4{Ó»G3ÈË;¬îîGbÖ•¦¡õÓW¼Ã^ ^â~Î>À¿ÀaàTq–‰mŸ	ñvP+Æ|NV*˜V §Œ‰¤Ï?¥cŸÏÙÌ|á‡d¥kâÇÜÄ¡põ'–7O¨™ˆ}væIjJ:•é¹ &Œ:òôŞs}\]ö?ñO6™{¥dÖKÂî>££	7/ÑŒ% ^ Óëæ‚ô÷y¹øûM•Â1Ğb†¹qAä°ø.%ñT6B=…#$ğ—™Ñ+7ª@úæ\ºøÎC™ì[Ä¨Hı±£q~DX}¢ÿÊí‹!qKŠ¹ô©Äf»Í©ÌI–ÕÔS¶ À¢˜ír^N&“İUINà…ûî+uÃmºRÆ.Ø@~Xx»çC8ÚÄª¯iRK‚¸‹Ê®¤Dğü&Ó47Wk÷öeî‚Îíbç1t…D {Ëz ®Ôq¢DÙn¹Á?ã²uYRÑ8«Õ\"ü5ó5Q&ä©5“ı*\5³1*`®—Ug„:6H®Yzá¼–Î‰±î î€Ë4ú')¿—*Í;4†¡×sIt[œ7-O¸ĞM½_ÙØ}Ÿ==
xPC’íy,òØ¶pˆFjelXiİÉ(“—Ìqo<ÓE&+‡¿¨Q¾Õ^ÄÀ+ín–Ìâù(2So
…Çwñ£8_ı<2vE5Àõz·KîHrŠ=:CÄµù1(% FÊ0	Öe$FYCT9`ì3R=í×h«B¸s5—ºıqâÄmXD«óß–ïşIÎlÅŒôŠÎ%ƒ$1İo™k±ïä' 	ã^'«üïÔJl¶‡¯/ê »…3FeW&€m	kÚ”Nfù.…äÊşöwZ,ğÌ+ĞP‡ÙÅı¼õ‰'ØŠĞ”ò>´KÃ¥u	şëhÓW l¨™hãj}ïuh¥yµ³í'¸tì(õåR*BÕ”FM!şÁ–Â8:YÕAt`«™oÉÉÀ°F´õ¹¨aÎ+¤Mo$ù&ïôº|ç¥Õ³AD©ñåÅHLV\kY{‘,A¡ Ùqêº/¬v	ø¤X¨œ÷Àœ GüXTJ*”ş¶V‡Òûsõ=ª½ì‹ª´bßÈ	ƒSu2s8e•{‹YÛ¾Àš€j¹dÚO°:zÌ«cèÉÅààwR†¹9Ò¿.!jbõtûV)à‚n÷Wx2ŠßF¹hgş‡ĞÎè¢Û§Ÿª½Be@MEÚL…íâ*'½ÂÛÊW¿Ùù¢(6³b3î:SÖYõŒ‡ôe6óï
Y#¬”,"	;M0‘IÔ7¹4Ú…*é8ÑÄ²fn²n$¦ø:s0Àòå“8G½ß¤h(´z£’³	Ö¼~®.¶ÿ’³¢1Ãx"ÚhıÈ¸ÿT({j‡gÛŸ~)<Fú±ùÏ‡}4­)öMz–°õÒEa }!=Ô£„®Ì‰xg›C§ ¢„>X“$ï¼lJ^]Ì!“²÷{ÉmvˆİÌxï	ŠôÁdƒòU¹„•×©ĞjmÄ¾QŒ³Ş±w	™I¶šÌå"¹º ›G™×<m<ziİŸavqgYÒ7ĞK?ãÕÚ:òh/öâü3¿œO…T
ú ¥ÊOU7u”c¦!êÙè¦z‰Ì-ÀIçÿ¯ È.iz‚Ó‹dƒ¶Áßcqdè9A ½©\T+è=[­J%ı%Åœ§·¨Ğoé„Ÿ(3®õ‡9¦hÊ¨ŞŸáEĞÉİ1•ÃÎ+z”G/T]L8Ù+‹ÂØ!³+€ ªk93ÁÈ~ˆÛ
msÇB4mô	h.@ÆûsDCş8’WÀ›‰®Yœ4§9’Uêækâï»İ,Õb¢¢ş¾Õ/¬ªä‹Ú—çß6Ò°¦¶…úÙ¶ø5á…q°c'1Brª}ÀJŸBU!­	D%°xù¢²4·Tz&Šµ¿nÑ§`P)ïñ@àMß‹Ï*{¯@â¹2…EFW»0ØŸÛÊ2æéêŸ•gø;®Ñ¢Q|~l—};Ç™Õ°îK\õ(†Ö¬šÛO7Íü¤m®\l='g/ìØ¨åc"€9© sFêã4”ïM˜¬:c«jÇ7„Í´”FÜº•ı+Oá³+€W@ıìÕv_Q«õµ•%ç}ÂŞH‰g€©õ/TáªÚ²w›Ã}Å¥Ï(,âOŞÓÁ9(EßäcL«?dğ1°|­²|û n´è‡ÀIôàÄ³ˆÑXmÕN¼²¯•É=áâÓ>Ì÷¯KÒ¹}¤º_|´Ùğ2]UÎÜ+³ıq¿Ø´üLZ-éÕÅdò½?Oê+ÏYäêNHÔüš;>Éò£›T’f—U>/¹ÚÏV]»¼j'4'¨,Ì€
J¥N]pOÍÅÙ]FAÑ&Z{~¥R¹&?p~MişÁ-•J]ÿ„kòÍ.fZoº_mx–˜K…’İçì|q,²¨ì|ĞAJ[^–×¢µ{äŸÉÈşÇõÒ1+RA(ÀõR*‰;ô_i"–Àp‡î;ıà…ÒåÚK'9Æ8¯•Yâ$‚w— sb®›?¡„tp¨yU(KÚúX/×ƒ®ßyä°S±ãÚGv¾fùÁhWÅ'æ«ñãwR­ÃÉ âß¹‰/Q}< Ñ—ŒôIßÊ\æ?ûáo”eÙa´YVíyí¾b [×4}ÖÓşl4¸y‰›öëzıX°ZÈ1œÅË|QFîø†Ã,¦¤÷›GwÅ¼¯$”ª¯£‡£Éëô¼–9ĞüF|núÂM÷ ´}.I\©-æï·ı}Ã‘kÁ›İ—NÊ”ğ¨EZïëHÜ]7Öw†QNÜP1êŞÕkÌ,ÿ(L”óG"Õ7àY`LÊ§UxÑ),â¬Ú“y1åûÈ2¨5,+ëúê×TşYŒÂR‘+›…œî¹ñ™´Í¾qü÷Cı‹ Wã'©hú$ûşóO&öœY5I¦5¾&×-Á­v‰Kƒ™
‡shR=rçCS7X†—÷QpÄ§íuàZR¼(Ê¾å éƒ·q)¸êÙ&$û»‹­ß-íˆGhW*2Ô½©	}?³ä×ïwîåÀd¤ª&‹ÔÁYZ÷c2œ°3CâÅ‹-Šlüúi(r¦BË&>§-(‰ŒÇ}2x¥D"áËzU*ÎŒÿòsC1¿˜P>²j—ƒFÃ×ßÂî‹÷ƒå·ÄÔ‰Q_ûÇ?š'S&PH~!Íµ•Ê‚ïı&ÁÕüB†4ÌçÔ—Q]Lh"Êšdı¶Cy†zvÙæÕNPs 7É4Á^%ØîOZ_U0çî§ª­Œ™'¦6ÎŠµãÔíuãJQxµJTwä‰úÓPY3Š\ç$*/JŸG‘sL»suîPÕüÿ=!ˆq_¹(AÄ­2Ñ#,Ûõ'}2VD˜1İî—ş5IÍ×Ùm¹DLÜ¿V*‘µÌ6”’?zÓ®«zrzV¶Öyˆb;_çí·umP©ãĞ?ß@–=İôöª#úæõ1ÿãB§çƒF •wrôKL±’Mií%¦múF4h`…ŸÆdšÌ³ùíãÏ@¶ş¦ìs=Ú/f» ÷U¥†·ñö¿±ÄÅDM)è‰zÍ9µÿ£Wœ,\ÇLôXr¨F2;;“Dm.‹BøLNNOİÿám5{ó5¨íUÇgyd‚>5h yîüzjŠ†Ö&UÍîc4Œ~.Löá,B‰Šmš¤ZO®»Œdyô?êF¡?ÛjÚÒ5*¸²¯ Œ^=üLHæšÂä0^/ñ.<@Ï:'lıE9
×2)O;è.Èî®ş8üJ­ıÕÔ0ş>66ÈïÖf¹6Mz}ÎÿÏY}·améB1#ÊÆ"x+2^Ù”ÄÒ]D8¡|$á)ˆ3-ø.03ü‚"­Èı“ïgáóuAÑ+ùÂ9w—ûFÙf‹ş#f³:‹¤Ã²PO¦*ƒÄé¾™Ã†ådß³ÚÛAyFÏ.,€yŸ %4ŸÏõ8ŒŸØÚk4aŸÔ¾áVª<ïrkO ï?¢¹yØ—¨…ƒÒ,ˆÙåQJ™¥²H®Rw¤¨xí¤		Ñû×!5™dæùõŠDŞvŞ°ÈQl@oR›Q5)]Dê4’sõiOO8ø SFT(—„u¼º“êûÊ‚Ê¤9¥£õç¢@ÛÏ±Â¹_@“1¯‰wQ-©)ÑöøCÓ©j~¶İkú}¢CD“Ó[4Üàñõ'µ½´>5@[İîí\&äŞZ"¸Bd)&¼¤™.J‡GéãfôÜ6xË"Ló<¿~?tù¸IĞ…|1ğ¦™Ë²!äõ¤ÂôGãwßIš©p‘£u»“ŠˆŞã>³¬”“çf†P>wÑÓ¥LÚêüaOøÑ$0ÚÄÊŸ<*@;ˆéUÁiÒş-gXjegtıÙÃŠ7òÈ]6fÄPóÒÕå–Y±D¨IŸöuÛÿd;Èê>ş !sï\¯+ºmR2µíÕ÷[Ü¥IDô‹‡Ú^öåXüg(ß~¨ÄAdğ<Õ4AÑƒåërÓ×€¸G'\¢S÷Ş{86oû˜ÍÙÈ˜î.«7ªĞ^ƒe‹‡ƒÀ“`Où÷o>‚WKCÜ¨‹CG¾½&W^oæÉInÃsó-ßµ G¬1Â¹3öœÍµoÃ:mù
ø@j’õ÷b’ì¶›…Ú"ï§bÕäE¼ì°ºmÂàµÚÅ¶X¸÷KıPibp‡"§Şv`»¹( —æq5¢ã–ëbµVAsB`š›&çÚ`ì¢¸UœRó¡àÑg†®ì¾ï—è2¸Š‡æ–2zx[¸;6Ñ”øÔUbêñZE5¤¬×åüz†m™ÈHvkƒvê	û#ÓõÕ
ºæ^£Ÿâ¹l€N¥ …!F­»áyh+µ„ß¢Ñ«ô’cÃuÂ=6v–S¼oÒ¬6MKH<jà°™MÒ¦–Hlú Íë _Œ›[šÀRUbyÄûDÛn¸Àg¢6Ú®òìÓ³Á`Vl¶_±Ävæù!İlÿÁv^å×\ãj;vGšĞFÁ”ÓÌ=‘ŸåÂq`ù…uĞP~-;Â(Ë@€¬CÖø¹b€ë,‚H™ö<,TuÏbŸ'‚QäâàwºbË´ÃÀxG‰±6µø	ˆŠcÅéXz>¥Ü"i”/‰|8t)ú•tŒvÖw†änD¢‘ñt Ğ”sDÈ‡:¬qTê:õ›³+lİ¸t^Ì+–üœ±Z	QãhE(2¯‘Ä ¿»%rş9PÈèvU+iÌçõğl\i	Ámw…­{j§PCÃlUñ:iƒªş„î”hßJ¹2¸S,QÀÿ&ô‰dîÙ0eA^Êz‡lÊsq~V»É©îa†í>{h”§`]Gş†€À…>îáö»pÿÎœm.•&S0FºRÔ~c¿zZ2EŠß´Ë|í÷«ÓWjy*'™Sî$Y}RRì¤ûjãäÀÎ[éÈùbabd¬©ltæú"BûÊ÷Œoy
@­ ¾¾(0¬† v™Fÿğc¾ı§ç*!¯=… d¼ÍËsÁ€Iº–Q§ºÎêcä>[Sàdz—ˆc®¬˜ÑmÀñMˆ÷yãSI¶š]y+ìˆÛNÚHeCšO›‰ÏÊ4	îçF/†$eĞ~\\
‰ˆFïy`ˆM§Lÿã¡İ¬˜¸IHh\] ¹6ªÛ‰]?8BÉqÖyÒ,Twp¦¨åªGê„—»÷µ^(Xc•TZàŠ%×ì‰²IwäÈ7ÜaNz(Ñ ã5·ızÊxÖ@£·"ë$8Cßd’Îÿ0n*œéô"tş°×zÜêú ®4RsT	{ï>÷ºú €¶«à%)¤îé}=,o8©=`²¥LÂ´Í>‹ÜÛ~Ö5ÏĞÉÎØª4ª8“HQ9¶ç¸<ç•¹,ôÉ‹jŠ­Z® ü=ziÖß9vBD Š%7ÅC!†¬å#gÃyíÙ¸l;?Óo|9³&T5I¨aæQİß‡»½™Š“-U~´e×„4¡¥bçf!‘£äû¥pR·'-xëj^‘Ö„°·áœ’)ÑÊß›ÿììZÿu«#aéóDóEÈ+ÔÓêrv–…Á2u!ù]ï¬Ó9ßÃoÕÈŒv…æùƒ¯e›ü=qRwˆPˆÔe4eHáßjÚ­í``k[ğfIğLÿG·$q‰ÏZi2Ö«¶õ-K¤©v‡QêQó;¸oîà¿ùPAµÓÄ§nìø´ÀàÉµ«TLQœQA®ĞXxpaX‡ó5£§}Í•ÿ™dnk¤©`Ÿ0ü:VöÓ£`ğÂĞÂ6¨Ô‚¹n&ß¶9Eˆ>*+´òßª¹]a! 0*f"†•ÜéïÍdÂW-rÏd)è•‚ãSäa$•s„?”!¾K¯>Ã½“¥J¦=©(ë›?éÌ±%½Üõ:ğ›© RÛšú>RÉNò‡´{Œ™”f.jMtO£o€£„×‡ÀL!‚”‘&}Ë(~ÁõD2ÔÇ?FïU	qv¿<HƒÓ{Tç«…N9ÇeÔ„òĞã²°¢£ğæ!Ÿj[Yî/#µnôï¦!a¶H O…`½ë~†ó£#‹78ymR•—C="|jÓ*LßSµÄ@YÜDLòuŞÊÀ`.äæ¾R
ˆƒ©p/²†Æw¾ßDäŠ`–Íp€Ä‰*¶*rı¹ÓÊ'ÓéGşq&x?DBÔ¿¨Xjœ§Æ_öæŠŠVßq^š¹»¥ëÁÜQÊMùÅ\`“Á1¥ò¹è=|ıf	lá3çC§²%VBäè€cECI|ÄÆÂÎ!éÏº•A¯¼Ãµ÷zFÂÉıkõøVQ7¯æ/ĞÁéi"w¥˜2µÄ¹é?}F–×{šN"¦‚7÷È0çæq
}"f=mW‘‘~ïua[ÖŸC{PéÏvá%:Û]ª’Óšøô5­Tß¡x	`ãm¾x’R*×v™´Ã;2Æ"K8[¶Š÷ƒ )Bf-æš¹;Ûn—5ÈÒ®æE€©PM1:ĞF¦ zÁ^ÅÄßöIy"®'’f!è+"r·H^ï ¡·ö‹@GBÂªÉ{·³|İ¼ë‡çrKE´Š*¢Ö¹wö`¼êcºÔamîP²ÛFy6JÆû†rÖƒ|…¼?h…Î¿şSO ï==^ÑÓÖ¡¯/ñ#öú²«R,Áèò2å5£Ï“~H’cbä;,Yñ©Ynãq¹<ö]^‘^ÈšŒÖx¥Ôm˜³*ğ^á2ò<Ã·ÅŒ6\›„nV6Ôk\ê•Zˆ¤ŸÕ/Pu…şT¼Ù=45"ó¥.Ãê?Ì©¼]ş¿ŸÃÔÊa3Áëï5"Si|;‚^ÖR/WŸ{»::LHãa¸Éd+tyºn@s'|¯¬(¡^ĞÁÃeÏÎ£E‰¦…úì»üÅT¥Âad®^¡™ÀLò—,gğ¹Î1=‘NçnG<­æ:ôĞĞ°ûwF`‹'å×"4]îq&³½/9Mï¡¹røGæ¨uŠp\¿º·¬¨Òç@"µ¿7`ŠŠ‹ŠaQák7†'À6œyfÏ1P–µ±d@nX;Kóõ¼.ğšT9‡&›çšåøc·ö¸z½®„A”–	”£[i3^#uó>ñÈD»Gn®›ıu˜M7W¯¶J$é7¾õ‡ÃÄï´Æ¢!ìâ”éHA\3w}pÔĞÓ°r8ãŠäp‚‹ÓÌWFÇhòÕ? ÷ÇÀcÄÒèEL‰Wµy«»&ÆòåÉåJÖ(±&DÂ1#Ë}!	JxèH”ÈÂğ>ñ¦3w,Í„Àhš”P9Ì;³h¯BPåd7ıéOÄ«bZÃ‘Æ~¥â¨¥ªrÏ”·° ·7X¬^5â,Ç€œ„şÒ‚ü?sC”sä˜JÑèr€KÇVâğ :CiB&­à`ÊA—|Us¯›ç¯ŸL˜ªö4YDZ¢ÿ­“óÇıQ"ßˆC¥R‘“•Ë€å+p–@oÆxê±"NwwıÌµe´ÉkÅÆ¸œƒök×¶†õ÷”¢Û]ÑÂKú­êj˜^¨l£< ù¸¼Ÿz1ˆ +´—E¼\b(1îpÒÙ9=RÆŒIërw[à¼²SğüON“7ŞËŸ£ó|ëšaÒ• •÷æ[aF:“W\Bsµ1¤o¢ŠæŞª$*¡ŠË5<R$cË«m‰h^BDYúŒ/„˜‹¬B™¿íÔ™ï0‡yĞ$D^ÅÍX™ú¶u¨ åy±W¾J.ó^©@‰üğæ½‹²­u×L¿ÅcKohÒsÊéàZ.àŸ’Éd‡f¿¬}`c€Ğ™JUV²¹Ö˜n­/ç7g:êL-µ‰°jù(»ju-…ü0Óı`‘ºLqâe{²Ø](¾èIdÿämÓYq$F‡#êRm6ÚGi¢vtGàğH96kÜ£r{ãŠÂ•Ì¹B…<m'Ià./¶3ëä²ÆT_vª GÌßT.=†Gë?]íPæÑi"P]û ÛóW,K‡DŞ=b3³ïü„$½Õşò¢èb j¼[$Ìßë¿ .‰åÑ ¦ŠÁÏuUH[ª1Jàµ¹yäë¼‘&%Œt®ù"<üµéÒ±h¯ŠåÑHª)í›ù`àA¼Ë,ÿ®Ãùí¢ÙlnˆPÖ¬ò„Ã6"Q:½
µ#@cËÙáñÜ7Î´ç:+Åè­¯`ŸÍÌ¾»v¸ãƒch<~¤<¼"zÌÄáI—Ã%G¶Y¢îæÙ”·J'ÅÈ^ô˜6,ø«åÚ$Ø»N x×)ë/~T1İ(`°ğ.¶›¸ñëÃ–d‹°ØËzîªv¶(O7‰2‚œN¯_Ù“WãI¾G©®hñNâJ“ı¾7“Ë(èùÔ"ş_â–Q0ãQª*šñÅğƒƒL@÷èFş¢$—3M‹IQ´«ÈšÅÛò] a®ó}áë÷
®X•ñät*5$mª|  ¬®Kñû2ÏÿdğmuP$¡¦¡Õ…sè¬MpúÎĞ×ìš5ııÿAºD“û@`îKTtÈ6í¢ã£APàdIŞ®tËÂc.ÉF¢åğàÃ®™böàeiÕZ¥¨Ì]Ú&‡*¶:‚G’1f!„ÍŸ9° ·sPìfQø5ªfıá/@/‡@½³ó6ÍŞP§î"¼Õ pEé±Çãı(#*–?Ü©ß¥Ç1ŞİSv àå:ÿœJÓ~frìÀ­ë*|4©NZ]’—B©ËÓø;ú>úxÖ‚ÃãRéô=¾¬T“Ğ‡;ò0uÉ”YuØ‘ÅêûW ÎúğÇ±ñÜD÷EÜa|‹VœÅoth>Â[şz³Œ-æ4úä²&	[âNK|(ĞæiwvÉ‰®Ş;ÖKÔª¾keÙg·®ì7P@!†ÌĞ¨÷ÎÿÈ¨ş¼†LÒ7¼ÀÅ~µßŠµ°àWëok*~k‰|ÊvÓ®†£¥f9H˜'
J×oß©ÁÓŸ¼GÍgHLò5Dû³ùZûûï4ò`õ^)b˜5İ/ÇÆÍpúX¹P;•9©”RªsçZà]½Ûœréüº/h|Æ $×	øAq¼ŸºŒÍ„gèü÷Ğ°3˜E7ÍnSğg³VÅ“¸µ½d'×¦Aµ]..¬¥~Âî\+ô*¼)t*ù^-+"L§ívì’(föío‰ş`$S‰Ã¬±Ízç­)MƒW+»FC$Ìx‹Ù‚bÛ‡úş¶–7Ğ—}™[kˆFn“Âèš'bª^JÛ–.©ßmi:Ê´^â¬H1‹Y	AWÿì5¦Ñ§ÿoSî aàÁÏÔ•½…”#ÎĞíj"í®Ï9"¥ÙŞ8ñ¢%çæ­ãZÊöh¾ğ ›¿Aß4ÀHÊ¹;3]Ãÿ¸Érîz«@ûw
;sCHÃ=5ôåŞúŞ#²Ê'WİşfYS6†|‘ôµ•³IY–[ºı¬­—D<á0ıŠ¨À­şşŞp…µào FT\KOièöôå;øÎR;;ĞJfæ;Q¾³ù]@q,@™—#gÄõÕŞ9.®MŒ‚C™;>xº«øo?ã7Å¶^^ŸùP*Ûñ®r'„eóº!Ä1Æ:¾‚ßú » Ä…¸×yĞ&	u#tŞ`N,pš[”È²HÑ¯<A4®©“ş%9‚ƒ¥{V”}´SúK¤fZ}º&\Sö-‡h*jƒeªÉ¤Ü•œı±teÙ£!ÔäĞ¢Ò‰Vf±oèØ\\£H¢'mÄ?°í…®BÀ3‘Çı˜˜ÂS†’‹İI|’,õwèêbdnu¢“ŸS:åóõYTÂçš»Ñ¹FœLŒ…˜|B˜ÉDR(§ŞÖù£¥t+ı¬ÑĞÌ*(n-½0c½P0—=?ÿ¯kL! ¹˜"3pÃi‚¯´ë‚„@]¥¨|l¤Õ<¥ÅÇ*5,ä±-)Ú™Ïœ—aüæaãŠ\îé´¤·beĞ9hªG(\ë1î´Z»ÉDŸß!¤çO÷H\R’V¤LÎİ¤;bHIOãOu6†ıŠølÊŞ¯)_áØÙï²8á;Æ-¶’T:iµ	9‰^ÿÖrm‡‡“QzKÜ¢~  ‰¬)7¼ÔnìûOÅ,GwøFá§‡ª¸ÂùÇ7‰–^Â7Áò:ÊJüÍ2„…†E*Ar:=3zS³§½b”GĞô°+ùCßUJtô÷çPš5eì+¼:îºğ=¹0÷4}Èû³?ı!SÇdËÆÏ¢(‡ğ½Ä4Ğ˜q°L„ ºå¬7áR½~ä:Ê,
m6i¶scçêÓîY£¼Ô£Ò;kÛ·9V½Ò;(:¯-º|Ë}dØÖüµy|ëÂò\îC\®Í˜ë*_°eüî}!à=Ü·@,ÍÙÚ\ÑŠX2ÂĞÇİÌ(Rû6t/ñ¼‰Èë„SÊnsÔ"X•Ø'¡Îô„E,
Ÿo‰Ñ5ò]Ğ&Í$só+0&¾èıù½«#äpPù€¦T(Ùõ‡Š7IÆ‡Z]jÚëü%î°ä~ƒ:è>Z'üfjI¶—³Ea·&€êÛ@)3u’~Qõß²uxÏv$—lèWíûó}D £%$œ÷›z“¯á¢û¢Œ|é”Ç™¥ûæ7@2FšÉAMÂ©—–ÉdZ“<_Dïâš"î¨4Û@ˆrÔ@ÊV‘ GŒîd²áÿbóa±Ù®‹	ƒï=E_¦€Á^lI‡eà¤“î»ÑßF¯Å@}z}…¥æ=Hİ|Vn„_ğŸ	ıh £Ã5ÛBÑÀw?±MM¦½ˆä/·ĞØ…Ò'‘ctñ›Û&E³Ãn†ç§ÁîäBPZŒÎRÅ·sÕö¡°”ï†7	7îˆXC,×-oúb5Eı;çˆÊ«öí”!Á^ÒÈØæ¦,Dyk¢ªuMÏxMğ¼OÑÄçòM®&Ë¬è©/&+¹’f°Bñ*QnÆÛuèS…ŒUâ¥·òoŠŸ˜#üáÜ‡QÅ|«²Š“ëñÌDpq‡ä<"á²gZAæ>/ªoäA”*±DJ¾ñ"°Ûz®Ü“V·ÈW5ùÖ`qe RO†xBnäû´©¥Óp`iÆOü|Ãg¿wànf‘‚pÛê“«¤õ‹óşØ¥G¾`ÿtco¦øcNrï×!ToÂ£Ìi6.DT+é‰ßxWÏ°$!»æ’·¼mk/£íåè„ÇıÃàQ!_ôø5É‡`õúu¸›#ÙIZÊ½õ4Ğx`_5aÖ÷ÒW­ÆÅ¢dYóIœ;`y~J(eÊpâŸ¥oÀ
 vá¿¶Àô¨¼(×‰¿ ¨+Çêÿ£~ì˜]øcÇs[àåMtñ9â9Æf$æv€ÎÎ¤ûÃN;q L¡—†ÔÉRéğô¦¿Ueó‡ò×îOXêè£ÍE6cE*Ÿ·/((cp¦Ü	ÂÄ÷OA
8?‘mŒà-µƒ£–f¶UŸ¸ùg™‘˜ 1ü†(™|øŠµ«Ÿ1KšUU`v5I9[U‹>:uyxƒp+û­XS?K^K.ŠYÑ C$uÅŸ'êâ­AHÚ½	ºéş;ğ{­†A•2\6ÍÍ*§«Š}‡Ë#¡pû&½‡ƒÏHëeî0~NÎ%•ûRèl8ºpû_‘µ’Ô¬³ÒÆm£*6#ŸB{?Å$#È<hÁ{ ò¶`•#WÒ©´f©ëë1ÅeŞ³)YÊ:5±£Ç¦¼j¨¥ö"õ7¸­–J.ºl¸9İY6 F;à¿¥'Ñ»WG/´l±	ùŸ{Bvl¶U…Ò¢Ğ–rîaô:8m‚¶ZhòÑ„dgÙ Ú }«›ó¸ØÖILá—\Cİˆ”óµĞ§©œóòcÈSjŒQ
ÅÂ/ÈHÒĞß§ú&©©@ÓCm=”	¹#ï9‡°¾÷l¼=‰ÜÖ›`™ı7
úšä[Ó|.úäqLJİ(LG[€†ÖlA=o:Yãƒ0¨FxÚàÜ_Íd@®íÿd{2¬ô5íıäX(qÖß!û–Ğû—e¨Ib£~«ºJWÂqézlD”¨Ädä{ñÄSÁ(V‡ÙÅ~¦ú+§BDÈ5v§-
=bÈ:FSÍíÕ_m	3Æ«7$ 
féö ÁËp£Ğ¸—ÌüNqş1ÌØæŠˆøÁDú1ô®’â…ˆÚK0/8† ÿ×ğH×½/î&UYœX“HÒÉW(Ï„bÆ8
n*ˆ4>Ğ	¯ªÚ7¨³…Ç‰.fo–Ujá4™™¦k$`-Ù´—õò¶l¹‡™Œ¨îın=Öy"®`ÿWx¬ÌÒ¡XÔH!ì’®ãê«ÀšNõxêú(EŞØÓ´ØsïÄ—#%¾Ó¾èÈŒ£ğI„úÔPŸè×ÿúwğ˜0gˆÅécğŒlc[C½¾û¶€ó˜ùØŒš8èÏ–ÿ áÃ·Â‡hP§¸T†Ç¸æ®áŒdà6ÄÅÊcæ;±ïÃ™=
v9=¾k¯1’ÛÃ+Rq¢ëàAG· @Jï2w×*	X¶Î¢Ÿb“1éÆ“¹£ÒŠ£´¹nøBFEihW;+ÏŒ°®/¾0Jpu-„G§©|û.F X€‘-Ô(¸ÖoEV|m/£!®¨¨2KQ}
#…Ş–ĞË*ïc*S6[[ËrÁ,Ò—Ó­ppÛ}2ê°ÚRû‚wa¡‚FÆ`=å:ÍwAHr`FnæY’gS™R*sóRÌx¬|A„³èñ>JÍP‚ÆS°z–ò¼šªÔó¢wG«•äáŒmã¥/qœäˆ ½½fÑ1ƒ®¨<+ÎCt#ß	^Ü-wçé«ê?Êz1¯+–~Ğiöê
Xš@Şİ$…OJˆ@ËdÔëš£ßs¡ğ`¹ogë±8?q¥I¹:†²®QÎê¦Æ¨yèàĞoó°"»«ŞÿxzJ*2#÷²ÓÅØÉŸbkó…î„ğ6¹çéš*^ÆË¼óVÎ€=6g÷9ÌÃğö ôŠ[ºŒÂeõ~‰_b®¶¼€Ëş£¢cfnôü|?«dš¨qv!óŠŒ´Z œ xµÃ”–Œ–t1š¼°MÃŒY±I'Xá¹à(²È÷ô©ŠØ¥EKâÔı9
¥ÌÅÈÛ‘\Çã¤àƒÊ_&!dyK½ƒæcÒe]*Eçº]Ög€õš£ZŸï¤_ã=ÂV5±Õ`¦'ª§;GúrÃ}¶7Tøum“j¾	ä+“À<ytgÉV‰¬ÜÖ…,qSc¥*´ÌŠñw.ş¿CµßnWnà:tı¼JÑ[–÷»ÙÛÂä¯3¥N.ñK ¶IÛ)•j/ìÀVDËnGVÂr¿u«ÉLêÛQ3)]»ZâŠƒ½{Hë¶3sñ8òxÍÁ´?êéå,Ë^ŸË'’šzÚâ‘Ëx{%äÀ©¥9mQèYíD½-~›¹®Á„!rŠÓùdAıpf–¾“ñco`Î€´¹¢ùS èïaõe°ßÿS·ó<êÄ\Zcyï·¥lˆ¯Ñp§†Cï¡Xú¡»?Gá["#¥—+H`Ô;N‰$°ú/"¿õ†±Õ&Öˆ¬&;©V–òW¾M¦Ûàö9¬¶§d¢“úK¿Oæp-š‰LŠ„¤öo`ŒÆP‚İÃlR[4v¿(tçèYã”ÍüàRşÄùo+PªS ;ü<ñËYæÛÜ¢ë™;,­­CÂÓ©41«ƒÏÿPGİ»D‡“k¡ŠSÚ¿Š#²Â^®Üªud¿ì‡·3Æ[šÿà2Ü
ˆ8{í´E@9ÙöÔ~‰hA”À®q+ûÇìŸPh¸#?ê&kŸ„¥­ëï^ØÙA¿DhiÀ6œ!<À<Èş{=$¯¸+EŞà%[¯F9‡MÏĞ<Ï'°b2;j,£ÅÓô8U¬áv³Ûj×^ 2 ½˜Ğ/&¼Û¥ÇÙ†­ -®>_Yç¦YNœå_…"’.çPĞÅqìîÆdú¬ÈÜ.-ÙŞÉ§işüé'‰ÙL~‚6bG¥h8tÌfš¬ßÕÒNWKYÖ/üQ°·Bèš2˜šD_Å¢hdI'œ§Ø%7†¤‹æ^¹!ü¸êUúŸà¤"šı…+©;ÅÓòªË“)ñT0&6ƒñÉNÊ¿ù­­ĞĞÇT> ï ä GhÜÓCÍÜôäëİ3›çëA!;±jîY†6ç7É¼ìµèØ“s·ë³—‡EÔ§‹'œl"Õ3Óüz
ä¶*şKí<\ô)±ÿôÊÍÇW¬¤­ÿÿº‚Ğ0«\<úc=OÙ84ŒTĞ8$kÆÉ´`yjÛSw'ö‡Z±ñËr¯P±B«t€ƒÏ4£–ÒôDß²Ë4ÁZ×ù±ƒÁnµM]¢_aÇ"’øã‡'î[hÊ§ÈeŠ•*ƒºœ¶<Øô]¡¼p.=ïş_ŒÖWUR(„&ô‹údMÍÛú+:ç±;¨çøL¾N9JOæzwƒßÃ¥R›šìÉú{6(æ”ß—’¾°ê½şú›â×½'0:®äùÈ™¥Ï\‰Õã)mNÁmÂÄtş}œ&okî‚òNƒ‚/“g¿|ãá]«]ğ,»Eá)2G†Ÿ?àt§õ*oÃ")¹Ø=±?é¯¦£u•á²(Âõ¨:(g•ûÑ]Šhÿ®Øk¨"ÿ"…T¯ä%GÒ›y½µÁ«"¹ˆË>£°!ì€Š99DÎÀ­•±ÚÖ,ˆóˆ.í	¢¿ÀK 3d*|ü+Äo†6ùI:œ”¹Ş!pHá¡ıåÜÍík?˜º0T$¨ñ{t£R}DN^ÀÓ<Ö­Å¸2“…£N 2C±Ñ-[ƒÔÊÄ*Ë6÷m®½ìF®Šp/Â—øA‹:¬¿‡~¨Äådˆ•i·ä6×*åºÅ‚AÊ»ÁéSP*ğ÷¦zi¹=ë–V7Ñ“ñ›7.	 {k’—MacÀëØn™n«³›7l†PÆ¨‘‹U®gÖE\
À² 
ò°úêÂ£…T¯Æˆ¦Ğ¶F;$jL¡ÀÕ1p6ÿ†½Dè#{qV	¼ÓÚPjk-™èÊOÂí¨c1{+Àw(xñÃ0nã:ç•Ög™ÿõõöìjÅÂ÷|UÎ9öS½Q9$6œ…	wÁ ¸Õ˜+ú	]—bÅ•b»Ô©¤~*ëxâØÀÉ‘^›Öƒ¿¨0û÷’Oó_·‰‘Om'†ÜÆŸ€ÅbÔ z†ÜÈûéV4ÿQşS+ƒö‹Î
Şü’Ú!=¢ì†ğØ&ÙdZºS¥hÊ/;dh_I#1¤,0ñèMm¿#óUÿWí¶\Å¡zŒµvkHFÙÀ:ùz/‘¡t‰©´33ÖÆ»¥W!¾ß3Æò.şŠãÓT 8CağãĞT‘ŞµªúâãIÉl_EĞ-O‹Sü´J=Ğ
ZÔ7ÎÆW=+¤Û#–Bòì¡„YHş[—üD4S‰´6%ç8dØˆìpòÚ|oò¼„Ô˜ªgönêâo-tuÛ:b ëÎº†2|ı|9éŠˆï´‹ûfŠö ‹+I©ĞÔÿ¾~`¨çyùvÂe?¦;«fO k c		L¥10*q×hÇÀ æßF	H]A˜Jš Ä¨÷ºBx”„=WÍœu©b,ÄŞA´ùè|ÂC¸¦Ø%íP1&§nÆ·'“-Ò›bÆÙ5FE;şs@RNĞ»f¹%¼U´ÊCéèµbK2
)¤ •*4ÿw±¦'QÃ}3LÔâß¤Sª•”{zÆ<¦ß5@ˆS<]
\àän+ÜF×ÊGÌVûŒ"_B®¥]«`Œ*îF/Öoˆ+¦¶ƒ×­TKš#³5Ç s`?Š_¥Èˆß] ÏómHÎU•´ñ¸ro­~?:«òï‚µN¿Ø©ê°İÀĞÒBËúÔáO}Ò#8ZÓ›&Ê05ƒ§•æÖ`3¤Y»¥§ÒÅì¶™XzMt%î½Ûı©ØÄ ¸SWÅîä‘7à:‚å”üê5¸²ÏA;t®Ì|?8îJk,1ºTY”„ë»ü&€ÎRi:T#o¦waV~€ˆLúôWï2²ô©ß<°eåñ™8]%ôKì'4dbËÆ”MÄ/NRÖæTÚ¶p¤8ÇãÖ-O”Ä‘ÈyŸÃ˜ÅÆól ı!G&»®SÌ‡]W cÎŠ8l­uŸ›x>	ÁÏ½U,ª¿ÍÙ¿â`¬8”$òïÜñş*Êç¦d Qº¼97d"ñhFç¿ä§‘Áóæ»Åß°ş‘ Md¸ef¥¬GíßÅfõ2ì`‹¨dö]XĞE»œÖR‘RãüÈ•N%Kv¾‹] j’ÇÌúˆXş¨y\cR>Ï¨Ï_Ë$ñ²1v‰"Yß!­òÿ5–:‘ÑÄ$Jëá‹“WıèĞh=G¥’„(¸uú±.mSÁq§ÆïWt8æŒ¤x·_ouY+`
ƒTÅòo^”çİX¾zòÁÕï±|g×\Áæóõ’ùÖÏc•°'Î:xxíó^@ÏõÈSš·-KÊ{zî®Ìıhßd42åWz×Aö»çÅiß*›dêïeÕ™”¬Êååáéİç²^%ƒÇ²5XTÒàòÆÔÿ5™³/‘N³)ššï*Í*Ü£è8Dêë„Zc()yÏÜ}ˆÓ cğL›¢À‚&·~$h4±2é#ìéÀƒöô­uáw±8xÈ°8Ğ·¾Â*ı™v•}ÇÍGŠÂ¯	K( ŠÖˆ•Æ½¬zfI1ªX°0æmUíò¾V†çqÇ‹iïW“Ìê6™Qs6>»ş ¶"C+GG#¼~#¡ª|şæ³èw»JÊrd§6±)§K	Úÿ¯ó="ú÷ì³İbğ,v¸Ieæ7:İÅJö{à:-Iäs±ÏÅJ¿ëJû(ÒzV6?ÖjŠØ»›¿û[ä£çÕ(Æ`XRØİ!b3¡:ö0e˜y.ô6mFSşVB,T	ôŸ¼'<Ã[E_d¢tezß½1‘Ï¸¶zKä–Y(me ?ÉˆŞ»“$İx\¤>ùgq‹ÃàTô@Lı€(UL+
à`½N·RÎ	Ç«^MJûÁÔ-Ëx¿ÀùX/$;”~‚æŞ€4[›ò‘'û»Óq‰1Î…nµE É™Ë&-X'˜ïÖE ÕMy—]ÿâ¦w©
jş«>ä­‰õ{E&ËÇnYŒC!p{†q*ŠP§ÊZºÀh8
;U·Ë#àfæ¼<Èat‘ìÇ¿WÎ¢]ªMB%jõ“ÅÅ™<_Bû‡®^wnEÉºâŸÅVCëÁºrQóuK|!Æ[öyÿhrxæ)ŸÎ„µkQ;9oûÊ.ªSÂN­ée©jt×ñîÚ¹{ÖÂ Š:“Ç^ÜÎe‡e'Š%xıÚZ‘w‘ürõÏ/®~ÙJ<*×pÕD\‡½ÑKïC¦9´a*T²y®†C´%)Ï27ôgtï5¡ŞåÒê'x,Peë6cÏ,Ú`^¸7ï~´º¼¤jC®†õXİtíŒü´®(Fá”[€DrV+ë	½dN8º=p`»T    *Ëš¢n Õ¡€ ^ŠÒ±Ägû    YZ