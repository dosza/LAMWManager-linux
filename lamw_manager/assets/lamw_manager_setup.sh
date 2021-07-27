#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="47504618"
MD5="3bb5036f0cd865ec1e40b564887e8949"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23224"
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
	echo Uncompressed size: 160 KB
	echo Compression: xz
	echo Date of packaging: Tue Jul 27 16:21:43 -03 2021
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
	echo OLDUSIZE=160
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
	MS_Printf "About to extract 160 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 160; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (160 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáßÿZv] ¼}•À1Dd]‡Á›PætİD÷½~5š:Ó¦É±¡­ÆbK£DDÅÁ5±qrŞKP‚ñqÀĞ±>ìØº
ÃK*†êœ`Êfa‡³zèØ€u§‚9xO¡²‡U>íÇ‘Èğh#¿ÿa…dßU0îìMåœ‹7Ü· ğs£Á—z=`Ä¦ş"/"_¿îíÁúP{zdáS÷!U´Wg!øoÜÓDQµFô‹7?‡Ê6® Üº!. qù®vŸÄ2ú\ÆOı¼6’ÓÅ48]Ó]³J=×vmb\è¯y0;’úLœ±£CTÌ\¥{o=Ö"âyp­à™¾Ö×îGìø4%ş"&ÂÒ<ã\Ø’”l7›Eÿ
­ÏØæ(Ÿv@i¥VgD¼eÆ@œ—,MBƒ[`˜r'¾hn­qïR^møpWŞÂÕ%¥ÜÚ|1Q·!92ÙÁÏÏå˜QÿW1¹Ê6»MøŞ‡¨@r:tÈDÊä,¨ğ¾™<º33a·g4Û¿ù´thhè<fø@ãLQ!œ©ÀAËÀd6÷DÎIÏ$/­‰†_Mƒc*ùŞ/<½ ìçùûğ3ï}/VÌÛË^Ğ,nÆkØ{§+›Ô?±2Ê;ŒM°ÄåÈ$>´±ÅYó~÷ƒj¾qhR³jaÕİÌ	j:ë¿MÍıOa"†]îú0Jô`¹(Ñ0~ß&=³”%Ó'/9dYq±~"ßVHÃÆq
JX AŸJÒnÈ©”ÉêDº¼İò}šY-Éá\WíÇ[ã/[v*ÖD­	ír‹7WA¿'qˆf€0‚§m¦x˜ó« ]ÏCØ8`8ÛÒÁ¶|J2×=½é5ª:ı7—x×uë|[ ÄÛ}H”y5!0	eI_éQÃF#Ø*"ê*ÑÍª?f\ç±…?qcåEvX)¼üYWÕóOPQQíhó23‹!| wœò2…t2u±e4­™1Ç½Ñq`‡!Cã ºãĞ…AÙ2ÅƒQ¸ØVE€$w ñ4´„^ªTEkªôw2yM€j™iDh·°T­¯ºœæq‚	\hÜ*†2.m´j†Dj’s®ñ«&	™U¢€¹O˜c¥JeóŞßY‰zx%%Oñ6<ŸØ-²šëşÀú0­îè¨ÂÊN²\“BVåC}€xËzèR6…í¥ —•5\Ø«»#FBw~Ó}¬½â—Ğ¢/g$ÓÊŸ>:„ºañˆà•¸™Ğø`=˜˜]Õ8GS?rl4$wÍW|1Í3œ%)y&"Z\Eğò,&úàÇ'”=µtNˆqì‹ÿ"hc+Ê-ªJaˆ­…N‡fí™eı ’hÒx²{Ñ°®«ÁVÉoÄõ"ö‡cµ„œîş$Up-Æ®ºŒË+aşp:$?Jg¬ºk7Ã÷Bïğ6sçÇõíIƒMcêoDÆµmrßzƒ¬h‘êÁ‚X“·©Ú[˜„ñßeó€ÇÈM_!„…\´|#¹‚odğ«mÃšÏt©QŸlşÖs§³-‡‰ ûBq[ğ]íÊ¢÷ç ÔW'‹Ÿ°ùë ø³é?­µZ
M·½!îrsæ¸ı^êØÅÄìòîÆ•ÃÁ¬‹û%Õèyû=ÚªCö¶a{ñ½­d³½{°;°Z‚äû`…›K‹Mç üÁèkFïuj+‡ÁÎ	o©×X8÷Hq*à6¼äi¾Ò•@{{`şğ*MïEÌÖ`g¡ñb>¤–­a€@-ñĞ-Xé’›1dH]7t:öÉÖÏ	RyìØ-¿p]ğ—ÜzyiQğ—¯Î¼ø½áıÆw´™nûT°H½ÃM¶ñ@ã•|€¶Ö•WĞkÎ\R•%Õz78¢ã5$:9%ÂcL¯lE«sëL;0J¨Şªûmúë§™™XBû>øâKm¼˜¿kU¹óàÃö†ÌUõÄw—õ:¤›HF$èÙÆ-£"ÜqEC›êu[`1+UíÛö9—2tÂ¹'»Ç2­ĞE!¢p"O-NÑH5À[7©påŒ‘±bz înÔbŸ(–Uö}e˜‰ÆÁa|õá%á4Ùq´]“ùPdJ—v3zë»nb­ =Ë‡ÿ[	fV“Ú89|<ãG¸;†L¸VhV#,şÙ&s.á`ñq–5Ğ#LÁ[+ÔƒaÒú‚¾BTÄĞÜW´Ä¬{öm@à£Ô#¯Ş¿SºÑƒ‚ e9:vŞ‡MP¤¹Q­©v…Ÿş~Y0±œ)ıSN”ó;ÁH~O XuWÇõ]ÇÃ½)ÿt™„\µ†ånÑû…h›0Oß®ò\ÑÜ	_ğ’œöÀè%	8ºÊcµö¼Ã`ËÕUî‰¼"-¦ÚÍo®K:ZÜ­‰Ö$j­â')²U)äÈ1ÆéÛÄ8ßòÎ¾Tœ¤µ3	¬&#É£ëëáîÖ9™æY„K±¤'n†Çv/`¿t¸ÑÛ—ï§¥Ôø7F1™1˜RŞ×ñ‰òBÜjQ ‚LU`ÑsP¤DÃ9ç‘“Î[
?+êaàÒÁAœ«¢Ÿµ<4»”–êV1ÿ…Îş˜—ê[æîô’Ñny¢KnNŸò=á/Ò|bû?õuêÍYáBFÙğ=ÈSÀ….›DäÊ¥ßbHföü×`b.L[s„Ì:¢-WZ#QË0OŠÍµ¸s¢=œ°=qôŞñ—™BÈ „å\jêk{”B§÷‰E~IÉÿË<4·øáïO¼Çoçì	ºfŒŸK«¾ûEf<·Ô»_÷Ÿ¦lÊ…ÌØ#KUèB5ì›g£2pSÆo¯u%Bd;İ4´ ª’¾^E)¶¸r7§GóCŸQ™»Â6x«®u}KaÁåGKã:ŒOôYœrHÌ9¥¹CÖª\ÑÇuİ¤AZ tÔ’}·¥SäÇvUl†í_#)E¢yüvİiÊµ>	®¡µÇá”Ïã•,CGGFû 6Nôû®¬ ãéCí¥o/ş¯ÍöA²Îó_UbÔâøš~ñÆ¶¶æ‰©È‡™Ùw³¾¯5Öw M’QşÇz¯g ‰ua½ç°[ÜFˆ<±íS²hg+–$„6ÙKµ/0Û6€KcÜÛÂÀ[Ù°~ëË Rİécğ©{9Kƒ$Vv¬'<%i3í…9ÔÈöÔ–j €Ç™°Åmÿ=]Ìo’åĞêß-IOQˆ4bi†ØA„‘9ßg:é$'cm‘h  *,€¿—×gá÷+òŸ'û9J ¶}ì¼TIØ³xÌ[u$æüa
ŸÑ%'›î?B¤w	´¾:‡ÿ÷šWp¢‚C¶ìsë@‡Pü–´[áfâ¦hÒ1ão¤b¦a«:{×øax,û/ô^‹<ôzŒbŸÇ‚$Ê
¥™ö1b'Ú©!mñ¨?­B8=o¹ë+kd´ä–(ß ]ÀçTZî§ !ÄÌzJ‹iŠqâüÖV}Yøñ‰xÜé°¸‘wo6q¡+),Ó¸n¤èU§Zcx†Lµ½'4xk+p0&µ¯6êw
®Ä§uÃ¸‹Â½ ±îæÒd™î¡“ŒŸn«P:h!î³@ÿzDáğøãBÅˆ·†=û;~ú˜^kBùAI*Í1s!–‘F¶&„|Á=N±Æ·…ˆıt?g‡º¨~×}†Á‚ëıÑˆ†@ŸŸ)uz:>îS¢aÿáûE¶ë±HH¼}Uí£aˆáPbR-ÜÒŠä	nB,ËÅŠ‘e•TÖâ'%åZ^Ì·gSKÙbÇo!zìÛš:érb:³Î/…Ò¸™˜•m+¯Z­˜cØFÁ²É÷G™¨5.Œa›i\Õøb×C°¢ü|©Š6¹å6îLè÷'ğøúo¢ªHC÷8Î?Mo·ŸöÖšÊ‚´'él%¢»ir/ãÓåë.k«²FH•në¥Æ’@âÙë‰ævo{ú³ùzõ]!{7ùÕúZ6tæüa8<ZgÈäÛÌ¯5Ó“”¡Â¶ŠP»İ±İ¥rÎ£ï91Êòq 6“ô¯LæäYıÅgĞ4Áê@7ıÆ£Ú^¸Àã¶Ö÷fï·üD^W‹„¯
ÆÏøaÉnelÜ†³G|;RJÄ:u½æŠõ?º%…İÎçıiÆPn¯C=Öİ²cäÍJ3ş§¸!ÑSŸ+Ùâ“<Zz´ÿÔ= ‚1¢Ø-gûå!É}Ô±œ%³ŒK£¸ú2‹8Î2zIºáŸmê‡ï,£ŸË˜J?óN$,–o÷Ïr_DéÑàë¢DÑ”øÎƒ¬ğÇ©J¹•ã¬'dÌ³şaæëNĞµv?,ÓCmd[^ö¨Ş­@Øj÷<¸ÒUÓÅÑìûáOv›prCN?'PT—&Æd8	x8KÒbêĞÙÅşŸ—dÏàw´U\sS–,—Êy6wğ˜ŒUÖn¾·\(@ÀëÏi$´Ü÷Js)«ÀZ±p‰g!’<Ñ|%;EnØd=£Q¬GYjŒ?À
¾ñõµEø¸ÑŸ
8‘±ê¸'œ¦¼–eétÏ‘£Ñ^bÕ¼Øu_]ÄqÏ«s–ëZ+@Ì¿é4×rP³y¢²É<¨?AUÄiq±À•ø7c2Îgè’²W°»çŠYB.Rê[Ó’Ó lÿ¸İTIg˜tÜh–|Öÿ9»FlºÜšÂï9i0ßeÄÌ£®qğô()ÔâiÆ–1ˆxªİ¿!×°<2€à4¼©LqH¨–r.·›†RYL›Ms›·w_t ’Úø†üÓO*O­8~v‚Úãvg\x30q£ÕEs4mœš³D}îß¯‚"f¼ec´jMêò0f÷ÉÍiw&½DP$Œñí¾üÜÔ)1éªõHŸfz¯;Òß2ü“õİÅĞƒ—Ö>ÉO?Sİ zÇÎ·V3iïµÂÕ4h"ÇC 3«ÜA.sRâa~nS²ÚBÌ7K{I$â‚âÛñ¸Y_½ÌÌÌªæmªÒÿ¹–±Gı "UZ¨‚eÊ Oú%BÏºÕ£é—4IÏÁòµ$•x»ëYy¼	?ìc¡£||À„8-dËÉ‹fÂK§“ÛŒ!Q.ĞÒsùQ.ø´ÔÂV.úµ±¶WÇ/0hÈWŸÜmË¦ Ëİ£¿Ğv,ª0êıÄë5Ê‰¹Nøµ\Gp·Å #ï6L :ì xÕÍ7Æ¨<÷Ğ*í=‡2 z¦30şï½<Œ}_Å£º‘³¬P;=¨´ìãË Ô¾3·š ~Qí/ù¤AÑ7ˆ÷d!yjÎ~Fqäq’[®®ƒDÓ÷vCK3k9tâ«”ìñ«É[`úéğí6·«Êb£7,_h„:ÃòP¢BiœtÂ^ıhkñÉíW)Èæé˜ŸL ‘²éJĞnÓ¿î{NÉ°”_j¶AzS5—êÆ6ÎQîuï›ÎÇ|zN[’ÿñÚ‘d'ñõáZôâÏ„†7êjöYp:)íâùçf-3o]ë`M¹ê«Û×X¼D!›šğOÜDI4O´PÑÑÌ˜Á ©
hª•¤üú¡ñR¨ôÙît®(Š¸LÈL×ÄY•mZŞT°aîdşüî¡¼È#›eğéòk0°+Umd®BsQŒ`õ
&YçzI%l«àø¶D ³¹Ì7ü!rÒ¦]B	»};Á/ JËEa}+q»—ZÈ±×ZWÚL.4™µ87+8ü’+ß=e‡+şïßìZõ5Ø>¡ÿ®Äõ’iÏ´\<(iŒ‰D‚ÑO©ıDiğŒMØÒYnzèIÉeBgb“­CõÙqZÄÙ£@~ÂT\ä:¤ØâPå—ñËlƒqÿ8Sô·º·æß~†Yş8 bù ì’wé1Ò…ßÈYHŠ“n>Ä¡êì@Ğs<âÍ»ƒ"Ú†?Ü»09‚Vê¥œæpéæúW Ş[ÜÇo°Á2!O÷Ä>Ô±Øõ<±qçA±¯ıôÖtˆ„£ûÛè‘¹æk¬y?¹ÒÔs½2[eôêÆÌcıQºã-$ØôfDâİL#š’_J,ÙëÂ9²qdVØÅ7üÜAÑi´¶‹óõw­ŒKªÂÁCgÄ["ß•îKº³å6ÍiÛñã¤‡°ªø;ÒTŞ<dÔ=ıèï½•ÍP–D¢o÷`7gDÙ`%eW»>çÈ S&ØÌ`½æ¨âõØrGI’x‰ëú¢ÁÂ»pG  ¬KOÿWD<Ta½>FìEÃâ»¥Ò8cäê‘üşÜİ`TF†ŞºIN´í&,AäˆêQ1EÎ¸	~üwoèûV5P³“GVµ¿ÎÓŸjjm*ÑR]Ñññ"Oö“­FfĞu„ı\*§^uØBó‘‘`j°•â‡_©„dÉ–\ãÈ.MœY6 ·<Xé04ó¨n&p!Ğ¢¯xÔîÙ*R¥YÓéàå
ƒóid70ÆQ·ÆÏü!Ñ0ÁâqêS‰wÛòú„_@dâ‰*íô¡»}“êyé<kÂÌgAS¨FX_	M‚Ø¿µU=Ê%m^NcWì·eíqt¸ùF§k¬†¸«‡IÒä•4ís@«Q0åÉÈlZ‚äé.´áî"F ÒZÉj:d^`nšZSãUVŸÍÌµÌ&R„î[¹”û®ÕS›“ºoÎ®Ğ9ã®î5ßÕOG“´,ù,'ˆ`‰[^-ËÂ—j×,1¨Á?v¥Ìd×…ô…r^A»Ä¼¾÷x­.u4.Ódœr¸ÂÚ“ª«ÒßÆ ™PŸkÚ•Ø”‹™²¼™DVi§!Í3É’Ê[ìs‹\zÇş ¶îì}kí}}å±ü€»2V–<¿ıØıã¸=+¨Â'¬?+q˜üŠ'ÓÃub/z¤uVĞÆ~ñ$«
C¦ÛB[Ğ'3‡ÿK¢ã$”W’OŠ sPÄÒ¾lA-	Ó\ë–şuÕIÅqL°ÀúYÏî|áŒJExÀ²Pë£[W@Æw“Õ–7}}ËŒ»@Y;Ğ£C²>ÒUíàÁ==<Sï,AgR, Èy(i<¦˜‰»¹ø—÷&$“j"Dw›T*‹•©Ï }ş)ÒVóÜ‘{/y„Wä8í¥¼7(P:[Ñ7¡pÀ!i#+™Ù”6àÿñ&`%àM¿"ü[}Y\&Ë0€;ãÀ‹m:Ù(±q7D‰ÎPè ı²F&‹Mü×àĞt("Oœ#œñöÙ¾vºÅ¼?…+öà va–~4ÆºaëZœdÚ—áÆ'ôá -’¡EhŒ­*cBC…ƒºİô‹ñ7öÓy!Tö¯d¼Mù2'#=~À°ßÍôÃªëã˜úRK¾ï2}h|¨8°˜˜ËG$­H$R@
Pà`\V_Ã N!±•JÆ‰4]eˆçLİ ø™6¦óM(à¢;Øûşo6'ƒ	‚ÖÄ’…B°ıZ±kd¨¡Ì×Ë§¡İ	¸´ÂDYƒó§Ìštõ‘í©ãvÇ‚RÚ‡E
l&üÿMÁx&"w×°âN‡²ó²³}¡`J*c»{¿m
§»U…m,¢'Ú6p R0ñ *ˆûb'´¦ÅsDL¯èß?*2ùÍÎÃI¤¡¨ìº~SQ}ç7çc†á©úÕä«=hMO÷‚*ÔîÉNpš	èç21Òå¨¦#¼Ì0×ÁÎWœt¿-7/vÄUp¨†%]¾)_Êe‚
¨ì‚îÉ¬‰P/A9Íwü­1îw°•ª>ñ÷ÿ‡óP˜-¯8K‚3ßÑ´¬|Æ»L+,ÈŠ6†ÍgZêH—üÏt;0Ïí%kl`KtXºù‡%^ˆ¼"õ’·-Àí‰ûYÂûÜˆ©nŸ±Ó6[¥€ËS´Jr§9;l2ŸÉŞ?qn©l+çIÊf&Os›&ÍkV˜NR…‡˜‚™=ó™a(^ÁÆşkEëL ÑÄ£ì2ã0Oğ	^ëÊyÕ]QÚzEı™hÚï¼×ŞéÆ˜¾	ƒŠÔHo N-ìp$ï«Â÷—¼ˆ»ºMqêg^Àc²çv(·ë(*[	ŠÌˆ˜]¡\Ûˆ×ŸI†Â¶sxµä³ª€ØãÁ§—9Òœ³!ğjµÓâ:<Ññå¹i4Û¦w>çw_7)Åv/{ŠÅ³„u'U¥ıÔñ“>Oş4nl`A@béÛ–'ÿ(nƒÅkg$¿XÓÏ¸(ıì£éè_.gF%ú0$<5kn½ 0ì[¿¼0éS%E5™HN#øŒåPÏ~oß+`«N$KŒq(2ŒbêfFñÅ¥;`î”>Qğ;I„†¥@ÿtÊ·R(¾siîM})g¤¬ì°0Ã²¥3_"Äñy˜@à#Å×`§ş{E•ÇYä¾ “-éD]Ğ˜$Ù]@ìÕ	ÂF+UÿsfB²}¿éjªG×qêåøÑSMoêX½Tçİ ı`Ë5cĞAUâš­GÈ_êÆ¿AHÜØ’Çt®Ü2ˆ÷‹7=%¿L…
óÍÙ5¬ÉÜ#ÀON§ÈÛ*·Š¢1¢ø5Ï„§¸Ö‹QÁ-î˜ÒÆ¶>ûÃaİ®ñ”vDj¤{>0€¥{Èè¯y0!Ø-‚êé Ÿ‹^¡h¹+6¥~<Ø«-A9.ôq5ƒÛ#ûcşæµ‘®eïcJh‚#˜ÅZ9¹ O¡/ú~ÜŒM¼T¢é1Ló„±¿Ş¤`F	 ÂM"¤Ú€x@Ù ªôëÌ÷æÈôéW,|ßl*`ğ¹unÆËVX èµœš³Î	qÍìPZñì;7öµ5™‹ëvˆº’İ ˜Ç¯‚F`üûŒiÉ]àZå>û:ã‡QãÛ$qİfC(„`oaÿ*Á	œ!Í®ÌÁŸÆü8^NPDBº~Ú0tğ¦b×à(Lx/È:çÜÒÃ¯	ğ¥Ç÷ˆ¥NÜ¬{¡ŒµnºèìĞSra_§1Ó¾ù½{SˆùeÜû™â—v	IèDÃŞ|µìŸ£i›¥~ëoë¡íİ{‰ñíóYw'bÿÜ‰bÇšİ4&ä»áÂÄ(k\:=.+ƒİß
ìé/+ãèwh+·òæK±cX†3-I&¥€
v}.|/y,´R¸ÌdU'ğnxŞ¹×AÉ¼Läù™¼_ğg×`¤’ÙùZ=½ÓN;¸¿‹^zLÛ~Y¼¸0ËgÆ?´4ÓÕv•×pU1#.Ã6>g2Ây’j‚0ù×ÆsÛÆ¼¤…Æ¢úÉÏ‘9™yoJ Õ>¾g ÿ›¤$Ÿ?¸ñ›êoğ‰ Ğ¬OÕ9åëôjQ<xd“®Á\°¢”HE}ZùNÃ~I^±,j7›QyË; ›R‹jµÙñ3%ÔØTjÂ‰åÅ”şAÔwˆñ|E÷CÙ´Ó®ˆ<x ÿL÷wÔ‘‘2šÀo\I´·¼2êÍƒ›ÔYà”’êÍø'…¡u©ç‰Ù‹	Z¢ê¼‘DêÿİSÏZ!±¾ë5j8?›ó¤/ª¹£vÅC¢Î¯¨öMµÚgÁkmğzÃİ{$i^UG]S¨=WÆön¿@0Vœc¬œîë»ÂÇ)štÙÓxá’íÆeÛÁM\¤»zÀEœÙ½qÌ…^	¾U“P²$FÒÇšÇ€JW‹è^u^p°¶„\óŞWiÈA¹6\êŠ> ¸%Ç›†¦ 0bY§ğ­µ§qBBÚ2“DWgwO-—ú|aŠ\½ätî°%âŸW ãz¿Dé6Á”¡‹İõ½e@x'vî…Pi¨9ĞÌw(JÊ¨àFÓB^ºó£úx”U{b³ÕQù—äø¹}×N”â3AbÔü0F4*wC•ÒDãUĞœØèb÷5äÊ«G0´cœ@Z¤[ UBZìËøö†9ÉAÅH^¦½¶’Ğï\¯Á°²1Îks­Š¸€ºl\ıbkéb–šèß©Úc	¿ÓPõ|ä¨œ¤¡í=/UGÂ%º|ò*b[‚‚[»Fı„RİAèõ“¨ÔBDíLğëîh—G@c<Å¶Wİglıæm˜¡Aü¯m°Ó@H¿$ÓçŒı§qñÓ°B\íXŒ9 ‹àÀšÖ¢A”ú.^/œŠCÜÓşú`‰aÜŒéƒ§­
ÙØ€Ä¤SéŸ_QÓŠãÍ£À”×° [~Ë*’(…>eÉîZÿ‹‹‚ÔvBõáf kˆ(T wW€Uˆ ÓjíøXÅÅzRşõvÂf€ô"¯s²d`(Ãl´/”í7ğ¼Ã¾êĞ¾H÷Õ¦½ZJÃG[9FëğcB+\¬ØãjÎ¡	˜wWIZÃ©ç…Bqñ²yå¨ĞsSçb¼ÜÃkóğtàòz#yÛƒq8d“NHyÎp|şš`şi·”8¡Ä?Ş¯¦¾ıÙÿIw÷Ú6a¢ÖjáÊ¼^h2´N™V/q<Ö³ƒĞÔòàç%Jaå~åÜ4ËüØ|`ù¬ê¬_Nû="sj9¿²fHéì8ES$œÄß|+QA
„4~½>—µÕšÊ;½[3¡K×OLË³èu°»NóëÍÌ	+ılßYìîCº+vÏ7Tùø—6Éˆ,\Ú94çÇ¿xA	!6rÌ½¼æöEmG@fn³Å{¬#2¡^ßÛZ¸¬švŠ•ğï_;ÿ„]ûÓÒC|{ZuÑâUË¤ÇÁ¼s‹ÿ5Ö=È©WÈváI/OK×³ê#ãs#CJ0ûğ—îÓğk8•üÇb×ŒkºRÿ}¨¿œ“uçI	šU)‰ïÉæ¾ §Ôkÿ	Ë°=ıÔ5—Ù›­“!8bÃÚâPœBzŒeXöz]@‚åSgĞØêõ‚O¾ÜuéªÖO]“Ev„åó¦y¸§âcßI–U(;dp‹9*~¥®MM”çœÖ '} ™‘† ª5İºRÎªÄ^íg—¦J0ÀoÂEAÛİ
Eá?¥„À<šA-:†>”U+ŸŞn™É@øJêJÅnJ{zêªuù›!º&_íàk—loqÔF˜ÅÃIlµÖ4vŸ‰äŒ„Ä­lxV¬ÕH@V€£Ö&¿pÅø—œÓi›&æôl}M¦Xl<N+ ™€!KòÓ´Ó±}wÆEÃÊ+Æãèó0÷Ñ>·ò¼I"U¸_åS­§`>Äá‰6¼`”›ˆE•TÜ"© +3d¡¹ëÈ©ü–Tˆ7èĞœ¥v&ufI:×Ù^7:GKçÍÅ\æ¿ƒ&g´4¶#Ïå¯M¤ıÏ	Ø/ü3mŠ3÷`ú!±ïÈsºH©£·y—Ld)(C–öıËœUft:§­^sm|¾Ü´Ù”Ê$MÔ@˜
}?‹¾á¥±Z´ËLâß<©Šs§Ô²É$-~Ö@Š¾ÚDA‡­ŠGJzu~»˜¡Ú+NŒï—µoÙFíçn…«ç†IH6È(&^…˜sÅš¡ı¨Ä#2øšh…õN˜àèòúL–S«©uğ &ğòØåĞõçÑq°âbÈ(/ACœ”ÎÒ"¡èû¢4ıõ´û)}_ÚA‚ÄQPÏrºøÑş¿·½1¢í—¿¯¦´aZüÖ¾w¾ÉDºYîlŞçkÍ ¼qúÇ‡êRò_@ÂÓ\ìóğmÁ³ï%±ó1ÒeE4¬e>Š¬ågÁ¤X(qrıÀÎ§EñtÒ‰‡+7¢¥¡z@Iä_°#^ÓÁc¢$›tBãÜ¾ÄãPæ	¯šn9Á^ ¡·f?OCûğkR™	!¬Òm*¶WóÂAêÜĞ™ß4Œ÷3İPı¦²QnğI€ú>«÷ÁàÿÀV=ª÷ËÄhò1ÙÉ˜Vc¹|±›”˜U¥¢Æª¸é¡J›»Jªµtı1á³œĞY†ÑŞÄ.”gPpMû}Nù€Pãnd	qŸM<óó¼ü4Cr:ÌT"Œæáb0ê¼¡%OMkÀPKŸÆ#½øú‹‡N=^P™d6áè3ì›.s'Ø=ÒÑ4â3ø›>ñÜ¦ÓÀ’ûºÀeŒ²èE@’|›)òù5?P|²ÁEÔ`QüÍ6ğÒKÍ!vMxS@ú š§ÍU Wê€ZX%˜œÏ¥ıÿœË‘ÅÇ¿şhóó€×bÖ‡s?ıŠÊÆ§ÚKåróuì¯ÁM±¨À™ëœpÙ pñŠmR™×z¤[}"gl²ÈfV¯áÁ€=~û°jÄ‹‡Ÿå(´¿Ÿ­—<#\Óö»DlE©Â4EŞ¾r?ÇDì>v‘¶oÚç dj|å$ÙËƒ'¥aà—Mh.x:0’Xªæ"xºmx´áxª1Œ¢Øµe{fgX/–¶ë¬ª³u/ú])1.Âà²’B¼¹ÛG"Òª?}RQŠ©Ù”Õ€9¾HYA»º¬YØ3@Œïv&A5„·WÛü3ÄåM7ÈŸ"Š}—ÑÄ;öÅ¾tÿt*¨Vv_êZ‹”?´s¤‘3gÇ´/¸æOê’héåm=áñHÎİY!º"%]$eÅ³ŞÍ¤ ¾&µkb'Ú‰w'Y@*—bo&ˆkoœˆÜTI˜Ïl`±âÉ–%Ì§V:ŒA-ìU ƒ‡ó¹Q¡ßw®…ÚAÜPŠÁ©C»…]í_»Òéÿèä»ùş9µçOõG³´R“XúŠ%(àw¼e^íƒ`€¥8ŞÃ¤’óôwXÓOˆƒ¦+ŸaÕr€jÈò ş&ô]dÎ†ä”iAVrèÎ4íR/œpb¹qIÔ2Š)Ùí]\6Ïue·Àã¼Ÿ{(Ì“ğò_p@3Âµ°¢–Ö
ÜQÒ/§Üı£Õm+¼ƒ>5ÃAâ%wû±*Œµõ`”‚İ	Ésí/şº ß”ïTà0ãZ}åÁi¯”û§FßÆaÉÚ}Sç¢^¹#APO»KÎ€¨ó}”»A¿‡±ˆÙ›Ò
kD3{’¶|}üŒv£ceÁòÅ½µØy×Ş¶Êñíf—tAXØ;Y=ºá:…5ŞB€6¬ßËFåM,å>x PKö^«åïtµˆ'y^US«ª7&r‡Ras¯u`*¨c/Ì‚˜5Åfivã—gàğW%œp!ºm„à$H­üÂÙP:È¦é÷¹ä¢9Ùñ›1»‹ú!¾W§£8r9—%ÿÖ!:ø0u›»ÅIêÆÀ™&ùØ	v8£ ;ñS¤FMÉ0†ïë&£ç°…4§0¨]…|ìü›[èæÒ—‚ÈÆ*’?‹G{/ö‘/H`ÜN(‚O(-Ø*ÊR˜8ıºz¸¦ïML\S
Ğ*++Gií›DvD¶Şw]ç‰—Y«©èvë˜Hşu&øc±¦ÉÑ\ÎETµ!¥ CÔ÷’¸`Fô	$²Æp(¢Wó].R6ÍEïTçå‹»h’L!zñ^l¥ UcâéĞÛÎ—|¸]¶cm÷ıÉ"ÑèáFŒŠS±IéY0oß„ÎaÈ•x¡H£9†^äâ€Š¬h¬¾5Ç­bµ¾F_yÄôàMªPJµƒDD:^Xo~ÑWA¯,[‚(£"`ª½Ø.â„ğ¼ ‘6K–hú(ş ß£¬`}êîÖS›İ‚²Pwt?¦O¶øÇõ
=ÑgC]jeç›®İZ}ráÎô®ŞjèîŒZ@nøñØ¿@98ÿCË}Ç¤XÂ¬jéºL|”)CËHú¢ØE%½ŞÿWgú›»…{$(›»nÒ€ÉRÂ‚¿ÿû·®sôl©ËB¹ØSÕ 4›ÒëH3âòZø÷O¥jØK{.BOÚø“(Aa¾Tô©%1âäÙ†·~ï¡)Ø9£óò³šÚáÄ×ÎW{ßO6âÿüñ.¬)öpc=kE*ğt°-ş¡K®gpHÚÃi™§ß_®<h¢½g«;s½ØvœÈ×JĞS³—ØyèÃä2m´ÇXRòîĞ™€Ícµ‘$ˆ%NN$¨0–^İ™ñ«ÿ0t	·ÆúéRßÊâ¼mJj­ÌaÔM$Ó«>;2^ÎLx«îO®D/øZ¶QüNxùË¸¦«ü#ÂF÷_^–
çM$±'4ËÎl–M²VvüF~áGišupJÀ‰V„WÖj	áõ¼”g‚—›fD{¼|êL=¼Ñ)ÌÖ©‹ï¯¾fƒ¢ˆv›†Dû¬şA{Æ™¦–HÚÜXÄÙ<'z#QÌ‹pj¥ÓG#è¦+f^>ÎLë~×u%U«2m“£@Âíı5È¾á”œ(ï¬³FÜ*;(/ ÅZ›iÊWllg®zfë\t@0öuĞüÿ&¤HzM|®ÏË-ç6Ko°ÁŞıµ'%Bh"x$GUi}åG?°ä<Êì­yIC’ğJIŠ©=dĞi<ä_—ò’8:ÕaÉX¦‚Ôß+°} ú\¾ş 9öı3qƒ—ÒŒğa
ˆ0[ÀÑ¹$¼±óÚ6IP »’*Lü˜¢tŒÙ`#7’Õç&Ô‰|‡ÆÇ—ØPKy8œ
M›÷ı?Ì7s³YYÈÜú¬_§aâƒ/eÃ;5‰íggfte`qk?HâÓó´²Üİ™L
¦‚}î7µò‰ÅŸjA›{?EÏ„:MtÚ2—UÙµ®E#kOÚ5+$URD‡\ˆw¿,éµrL÷;ğ³x#®~'‡©FÆEuè…ÇxĞ>ù•°L ŠzÄÓ¡s3@}µ±®ØŠ:Şş¼Û÷¸ ìªÎ$¿šFˆZ
mÛ‡ş}Û5L‰	Ø\&$d$€)·îm%r| ÔàwTs'c´,B«ZA À9ıë>òúéf,UXş@=Ÿ.PŸè¾ŒĞ÷ÍÔWªĞm³îÎÆ´IÈ~º·u‰5Ê³ù¨P!R0º‰N…Ä½üÎ¾~qznc9í<üRdÛ¢%©JUThâŸK¥q‚³2"_²µÏ][á›8fqÔ2±¯rĞùõ^ÃŸ•óM0ö	#¾
cñi!9,ªôqüÿªÌ“‹DF‹l›ƒ¶°çùK°+’6Ñ'{o¨ ^Äl^´ê®4b@T‹,bK Y®àÚÌJªkø‰Œ$Å¦qİ&ÆÂ÷®i!†ıİ±§‰êÇ‰¶Z:›¼™eBßÃ¾şC¿Ê¹ú'[ÚÕÿ1÷œ½Ù\’
4*ŒğI°(S¿ş1Ş®Gõ‘Krßİc'¸Ññl4|±‘Û0kyƒÕ…ÃÉSêÆ¥ğ#ò
ø…“°æá¿‡°||¼Ñ!	€õOßAî¬È'dh@étI ËA`YIMì²N:ë–H}SÖv¾^/w­O²£¦ú Eb…ÁŒoõ]"Ä›A±;ŞÚë4-ÜÉŞ•O	ÎRyŒÄøAš¸¾Ùıy¸æ!SÀ·§F?¢ÌGï\0üxà:h7Ï–£óÉÊv‘Àğ°±pÃFt1{W8÷÷³'üà
\Yb°0(|¦“ö4h_ú®%h½Kû!$&¸gÑ¦‘1r—_”2¦Iíà‡±8.ô‘^Pšo¡îäÁæåz:Iğ³€ş¯ùŸ…:Ga£A
¦™dàÁ·;b2ëËİ]š½0$8ã›ï.ª$Éy¢±cMZ„’2h/ÖO°ìÌ	Îˆ×Dƒ/û=~ïqÊ4‹Ât¨&¯8¡…hZ¤ñâØÊğñÉ4ó›Øõê©Úo²cÉDÌkXfûœ&;ìâz5Ïâ² ˆ„¹İ]´1.Ò¦xè&¡h»0ºa1y^ŸXåïogx´~%Ã@Û	ÉBúd¹‰8ÎPFÙÑ°ÙF’$YÆÒNNNC¦…½Ùå¼H±	Ëc"-(&ñ>¨Í¹úk; in¢°mg¨è¥ÿbC­P¶%«…î±æ{/v™]IPcú'’2¬ãdMÎw îÆ­†ƒÙT"v†N‰ÿ¶á3}Ú`k((­·îé‹öŞšÁ. ¸)eØËˆŒâ|tÒ¥ƒ…*·³‰†¯ı—ÕwC›?QbURB¨7Ğ7E.b¸$v•wËââsg ‡vŠeŞ/BF“w«{Ìb ¢±Ÿ>ÛŸó‹³lóßlD ¼8Yü…tÿ²Ä€¦
wP ²m˜óY…Œ†hgfâ¿÷«Zô!ˆî@ş"cŞ€ñŸëŞ…s¢œTúi9{–Ë¿’ê`;Ğ¶ìòì 8P5O
ù"GsòéF©0*‹++9®Uí’î7ûÀ>WÚêsÄŸlüÀ•ø§m=R¦ê[hTN=äVBÊ(MÁ7eÏj0˜Ëù©º%ïè7=Ós¡"åà7Œ8jœ!ô4×B«¸?æîs°›cÅb,~d ­,/?isd]ñBğµ­oû×G?ußaİç–^UTÛÁ›]Ç­›À!ı€•ÏìÃ°:‰…¦´%û<\"»$dÀúe7Y}®ÏƒA¡Tı€€®]JáÃpØÀºl'Rî¶+¿¾–c´"ò§Qy€™àJ§0·†çin`¡,¡±„Û“y%°ùıËV®5üTsUHçj­Ï'tñSÚ¹Põ9—¡y{İ³m
ÆæŸ£÷ÿüºKşÖ™Ÿşey¼AèòGÿ„ë½¼“bS‡š—=ì!© Aµ&?zğÃ»%¦5*–Éà–†±ˆ«Ùºlø´ıæÂ\¿Y'Œf”èR^%X@å¾ú,Õdç68´]±Õó5û	«‘{µj•,GËº à¿öõº™zp´·[ÁréôëÚš¹¹·w¾^ÒZ;…oêÂ17oÆÛ¥ËrAE¬qİOò•H¤N7~{ÖÙ-¯0©³ø¬:8ÔÀ¬TşfÄ§2ìÊÔ"/B"#2âë|¨ñTV‰cÁo©äUj¦şø†>`Ÿ¢¨®…Nµ¡Í÷R‡*Ï‰|0Œª+Çñ6sŒÄèQå­ş»bÅÜ(ÒÂZ®^ŞÊôÒ£ŒX"¯t8c¤`a3²Ë³¶t–à¨¥¼(¥Á ô¢‡5ÎC%—Ã?D¥‹,•²µõË®ÁgØ\[´²y:Hı&B±q.x >²&§Îö3	›ÔnÌÂÄu¯F©àÏ@ª'ıkl8ö¤=âÒBïä÷¦nE!m¿Ó‘•’¿ä-û€‘âÜ«{i‚4œ^İd¡‰Ö6lvÅ z¾D µÁM31&Á³!f1£¦Xf¯1§CD•à¿bÙamÖæ(Õ®YGÈ1ÜÑŸÎ[(!£ıÇG‘=åõrH|è½3¬·İ&º0|tßÄÖÂ­­Wt¥¸i>®{±¥ İÕ¦kß±ÛXµó½L|ëXÀctĞUøÍÿ©¹zôNgvx<üW²$aµájIuO½w(&ZéóMlœ¶:ùITŞÂ—ÿ;|køs»ñ#v–Ğ‰ø¤#8ëØ—¨Ö`ÀfÉ­—(ğ¶DÁêL…Ñ—ı 7Â#¥¯$û)ÃV)Ù·JSóöËXl´œÍï~1+—n;ÊCg§Õ¿,ƒÆòlıxØoÅ*ÂQiÏ€,Ù-
WÒ9sêğbİ_u×#…&N›D¯ôŠR;á“¤/ÓöI~Ü|7ëÁE Œ{nºÏß+°âåAzqücUK-Õ:V…ºdÁ‚oÁ0Q@™n#ı.Qô‹ÅÌT æ¤$†
„’¢J[Kå«vµ
®iœZ”åœ6úVú¯O+…jĞgfœR%F=c„¿ûIB]AsÕ­÷<Ä¶Ã´ôõ³™ÉPÍÆ¸·QkTæ\[xùÀ1®ûV¿-ŞyJÇÚu— İTİeÓ´J¥–-MHJTTj€·ÂË4ßI§5zŞ†%QŠ¥62Ûİá2cgÊô·¼gƒì-	ÄÆŠÔ=‡q–p•™è¥w¿ï  ¬.+×jõ²Ìì~ PÚeS©ÕØŠ©?¡ı#ƒln÷Ä{AF×T_wØ’­K4©áJ‹Òdög†\§O]¼J»+ó¹ª•¼ø<ÓğjBµË*›'÷1J–˜b¹ˆd{wÿÛ ³³ªúbÙ†İ896«Äƒö’‡ß‡¹—)I’rˆÓ,A¾óEAğ2²³…İQÊNÂ•d£7tüÌÖ'*QÓu[WC@VÙğØÖ·ƒ¦Š¤ä3QW}å,‹]È•lğ¤½9M?#nÍDâ`kÆ/ù3s¤¸ºc2V¯1›£sDÖËx\&àÃ¨—ÚpˆJ6´×(ĞĞÁµ©ÜjnË9«¬ìôî/ `Üd<#½ÂŞ>d¤˜†áçb^²õ”åŒÁĞBæÏLÇæ}âQ‘$ÎË˜W‚í.°ı¹îû§B™‡ù‹gŠNúxÚÒĞ|M3&2T\™ËÏ•œj…GœŒJÒşñ~Á§›!Ë‘€ÜåĞÓÌù¤œyÌ•ÀÒ#ÄÖåŞ“ßw¯ò¶ÜĞ_ç°JÎ`"7¸ù ©gòR±â!åaÇ¾c/#J‘ÑŞ1©ƒ¤U÷È4
iç•’\¥ù-E”,lß“1¹Şè5)Ïvhia3{í¨·Óğø6®¬Ğ@,FƒDı}ÈÌ%ĞT³=Èl{ÙQşäuY:ÿŸ=Ÿ¿eN¡?cD;ú¦éŒkü€;§ÁJDĞ.!¥^_Â)ÉMãI¤”CãnxÏº­ÏÊ-ıè
gnÁ•”À¶äO\Ö<ÓE&ğÊ³¬õ{¨Ü§Ô‘s¶J¡`bZj>UYƒî´âŸ»ª/€Q¼rüáï'"ª[Ó\äs0(\¥+Rm¢H'@ Xi‰UŞŒF6$¼—fê<ìg1îşêÔz'Éãfk4ï‘—\<’p¤ÚKÉiæÁ,;Eÿ/Lö!aÜfÒ<8%àYá&ÛS|¼)İœlT®R–†á(3÷a˜nEj#ÄeBùÛÎZësØàúJÌ1Ù®†q&û·€jIe[‚.²o‘SÈï(E:óg{íï%«°ã0‘œg¦hhAO3Q¨Î­|ÔG-À¬H~ş¢ÆGÔlMF?ñwL –œ•¯ƒm¯bÅÃ”³ªNµ°³&ª9#jZ /Áğ?Ëmoî®åË@sÉ¯Dßn™

3‚œèğ (“nœü(x"{×[ËÖlw»»$e±:J2˜²ŠĞ]ê„( +Y?^ñ]ÂÖF@7Œ(e]*Ó ½^;ÀB:©Éª*İüå¦­Üsd§Éÿ ğfiÕy7Á¾nA ± ØHˆUào†)^/šiJÎkº>éu’gå¥œ¡¾l`m­‰ªz‰(úÛm›·S0Õ£Z*±ÅÉ$œLˆš=We€¬Ìbßİ-º¾‹+$Èú•97İ“¬2+õgyÑ)•!ZÆŠÂÅrÆğ={I‰¢?Æa+p¦Û	‹sXVï;q˜oª´†ËÌ‡¨J`rìyE…4°qÙĞŠA‡–®ôô_>øo §ï¥øÛ”¼
âœ °}RTé&¿Ê¶vIùkêÓµ—³¨_ÖÒô„p,6,L¥ìcö[4ò6¢B@x³zİìùÛÉÆ”¶Î?É[©Àå‚`Ó"Àêrè°tõrÀsò‹„’–cëg'^¹WÒm! ¸+D¦|~ÃÓaŠ…òó ã„ovŠŞÖÆjQƒXnÑÊŠ-iµÕ3°Xó¸¢R7¼g¿¿~±YPÿ=v¸Æê>¾ä>¹5pìÊt¿øœµ†§É@F/Ó²‰ğÃXsÁ¸¦v(O“'»0İœ”Wk™1‚[õhJ$”hêFEÉ6IÜ½+ÕÅ)÷Q“á¢ŒÍv"Ÿr†¹ìÉ6Ş§k,I\}†öNã(éÜ¨;Àµ:‹†ÿ4q	. x-º<W…,D[Õnşái£5ë×¢İˆ•#GK“ï˜ÿ\€7í;™8ˆ­Š’Äb<“çiJmW‹§_ÖËŸäƒD ®ûÙ’&ªşœ°ç½D+ŞfP?“Ç]á§3e•{e59²]&¢Z²N"tÄ+GşhlSa¿…¥‰m±@’š“]º{Ïb?»%<Z¥’zöÕ°Eõi¶#iÚr‹é¸	sã™4™)Õ0©Iîm+r]WÔú&"—9²ÊBºê¢eCïE™vîä©şŠÑvÂ•?UÌ„Ôç#¦Ç5y=‡î1).‘q oFÖW;JŸÔ^—‰UšË)p\ä ‚S›,ÃDÊçwò?"‘Œ½á=sQ“”sh‡Ş%`dÎğÂ€C¢5d0Ùa>Ö±=Ôì×æê jºuª[!?ğ-ùÉL.T§œ“®”nˆ¹£œ¼x‹Ã#®ßÅCâ_~Ma
³„Eè½œñÁ	*„a^õslwb2o¡‚÷ôÜ™?†Á÷fXa
—‚`m§şiĞX³D,¨¨µ0˜Qõ¼I>ùf~šF,ôËwÙrÃaXã‹÷}Éÿ¿¯cÉs ê’4ştfí‰±™4ª:ò~÷ÂeSWW»‡ıø“òİ+Å–¦®†Û1³ä»§´ŞR×VŸE±;kI—-ò\
Ä´œu—ÇBÊQ]sŠcDÙ¹ÖtöBvİÙOQÑŞ=ğr}‰{ãmË°IÌ@•Úğ¿¡ó¯$ğìÊ-äwj<Éº·3­?b¶R{;ø’/ßë¬¹K1¢ºXL´_P—hËDáfø8Z§s!Ãy~0ÿLßuˆxo«¦ô­ƒöræ›†»æKLÛFsx5XŸZ®”ÃÛ¢ƒ'÷°>×–ôê²«BŠD‡†’û™ù–z€Í¢X£ÎªèiÒ˜•Ìkç7(ßêÎ}"¶ÀÅóä¡âL¹+0L·L¿uVälÛí©Ã,ê`Eò	˜Ï[ò¼“‚38Û(YBê|pd±ìkV tjµØr€ŞÆğ1d™×äEà:
Û!ıIÄ#.0:Sa®ÍhşyTğ9ëÀ¶3}3	@»RÚ=šNtS§[ã’Àyé_põËÌùæoçK˜…¢ÙÚjöº^<OşK`]êP=-täºr—søùnèŸ@çı’İÃD°w°µ·C?3‚-©¨â%Ó©Í?	ábÇÈaLËx"u»;n”Ã"J«ô¸WÎRóñ¼„%e­×¶,É(ŠÓZÉuà–¡~Tš;ú£¼Tg•´fS1ö¥e†Á^)ºíhÓİ5‰›	â"dxíO»ŒY¥u<¯„ŸU,Ô¶€†€Tfw…mÜúÇ†
ÎÈùİ<·Ê2ã‰•]‹v‚ ’—n:”òÄÚ„)ëS©u›f2-æ•¨~³êH8-[]Š/Eçë·câvt®‚z·ÄÂ‚(¶Ú/Òt`yåó¸Gtî&µ-#Ãşµ¶½)iÔÌo|KÔ¢¹S…ø½w9Z;¶òXrÑajØÉÆ©¾ˆ­	 AÜºüÀcË1ZÑ,ĞË¿ “ËèSWÖ²Ó:ñÈÕ"@¹xÃøtŞC1ƒ7¾ÿ;µàHò5¿Õ6^ß0mú£´H¨ü²9¼6_UL¢ã–_ˆ[mrR›ÿ™éÄ¥F;t	äãÍ4š´‘V÷¾şÙë"À<˜<€HÛô	
ø>3Ã”AQ¸9Ñå±€;Ùô×öí×,ñu~üá©º´4¸Í¡ŞT°R}sùa”‹şĞ‡5\ùİX1ƒ*`08på³‰–UÓ*üvkFê&A>g<O~;=ÎUTÆpäp¥¡dKHTï‰L&Sê¡–£çĞáÌ«>}f±
”\ûí ±ëİe+ie×˜­ÛıºUl?uïıÁÓ&v§tœÓáöõw;Ùo¨~ù^²Y%VU tÚ&BNXoFû{ŠB¢u‡ ¶Nêle¾-áŸ}Ix«¸H¿Œÿ’ÿù×JùgzMxõNÊ†ğ`G¥B»/ªßß9—~ !áÿvŞÁ>ç¥\Obj+1"…çŒ#&¬ü¤¾ÂU  ;)Ã-F‹³"4p8¥oõ²h—Ö„f# ÌxÎ±Äùœ¿)\Yªéâ†q§µ–®°µ×G‹Nî&9êé‘¥ù¶ üëß]€òüxw«	4²Òå,ØÆ˜‰É*!Ÿ•@š‡ƒ‡‚D¼Äæê£\šu…»Í4_ÈùTáÕ4kîpqù6Íåi’*µ£9Dùä,‚Ú.æÆ5—µ¥?Î‹-{f
›8i¤«à¦Jzƒ‹Võßıa$~v'‰r< ‘DãıÎgw¤Â‰f ’ØI:ÈH˜œ¡‰ó™£ÚcslïwÉgXD† ¹«’SP}ZxºïÇk(LÇĞá;ŸÌºfP(“´ßÔQÅzà£;ª9¾ M¸üí!ßHk7¶2óó.Rçn ÿ$€ÑÌX*o7@ƒëÕR¬”*ŒƒLŸ@Ù¦Î£úVËâ/-•“'?	Û0ÀÂÄ³ÃuEÀÎX€7›ÄÄ ºR÷b9áÊËİtB}üN!v±Ş3n²M~ÏÛààA¿EıkEd÷ Š|Ùø–x]mÎX	K»âfÎøy!íÃ`É·ü”j4c©ƒÿÖ¸ZG‚¼çNïP“Áº›dŒ%8ÄhB\fİÍ•{|–Ğí¢ 2ç AÊÒ5^‚-#”•ôlÌ8‹ŸW–ºa¦EÛ®/áàA×y—­ÒXíº~¬¾`ÛÓÇ£G(¸l£JiP{—L}4Y;ºOó+JlLë«Ë·Ñ—ÓU¯_×B•B§&œâµ=ÑÊÎÒ€@ûr^Ã¥³åßHè¹Ş¡¤iÔ^3M?ò¸"“³l¦ÉÅ™`5ÊÔ‹;ìÁ9Uˆ®’¶r«-u-ÍeÜ-X‘à»%LtjŞrí¯S-ì2m’*íÔmVÌÈˆû¥p?®*'o÷–]ßGM‰QR:·àİbP€Ô`µ‡Iª± 6h'¨Ê k¿Hcc¦jõ½=T‰—(}ğ+dÎ=‰bÉL÷	"Ÿ	ŒÎíÆû6ÆAïòÅ†ú®Éó×Œî@T¦ò>«ƒ$â`ê²Ñ›•„lPâíˆkÂW])ÿÆé¦ƒbHÉ˜+­#‡ıjÙS¼{èFùÓl¥Eš$~¨._F¥¢FÑÈ»¦›ä´Œ.•_¯ ‹½lÎ{z²}®¿-zå„cS¥}´îÊ³Ø=u M2m¡~œ8Ê$GÆo½ÂDˆ~zâ­4®ÎõÄuzğt #ä*y¤½ßM«–íy;ß;£®{í®•i‡ o;ÙK¸AŒÇ;@1TK®ªŠU6'k›İÏÊGD½5vTñ?|û·Ò:¬‚Ã:\ªa¼çîXÍ½º¦êå	Ó	*|Æ„@Ş ¿X¾ñ+qP5ª±wËM4#òÑÑ#
X
ŸnJ%¹Fàn_;f¯Ø…‡ö[xÕªüÇùÕ#oœYµƒºâ¶¡œ”¾?a™è;¯d¤ˆ©¤/4µa·ƒÁzá×®®öf—¾jÁ—6ÒüGŠw¾uzüÈ7¨ô˜dW-œî¤5øØkMVz™Åaº­ü‚Ë²Ğ…ZRtqD¨„8ùùâdb¤®zDã*•é\JZĞş]/hî}ÉÍmÑPY"ëÁ~~ ¼›œºx;<oáO9IÇôŸ®`ù/„ÉUÕG#Óçƒ?É±a¤.lm6û,Çdæ¾UEûÁ¬ÓÍı<Úa²pwÎæØ{ù+†$ö^l‚¶ìê\˜ª],ò¤_,m8È–6ğáöë.ĞÄ±Y—GşŞ]¨«òßŸ @¬ñD0>İÂÆÕ±ŒN\/âÛğï÷ğÍã Pôgœ*~^Õiú,”z FsGn‰Y—4–JÈªo½}`¹¬}@´•éÁ‰gÇ<û7ÉfJî÷ælÊÊR‘fø@?aÕ¦1h‹¢bf/á¢›-©áğ¯S‚İb…ÆŸÓ+¦|’	¢KèöS«+– SÉÂjlç^Gãú¼!—¼ZßrpéNÅCê²‰×ª-:oÕëG(şöè6‰»ávy™‚Û\›µüÓÁ9»6ş‹Ÿ8GÉz//BåÓ‡ï™ºÑKækm‡o¯§Mù›u§)½¤Oi
ô˜º¬`&dı*Ş¹Ñ@³±R`Ø9A”5ö;µXs-¬åXz+7ÂIÀ³}U‹L-<mõMJ ã–bãï4Á—·KÈLËç.Ø s»9MQoŒc !`²H·q,È éjÕûMÔ9œ¶«Õ¿8–Ö½Ÿßh(™ü¼3æ-ó<l÷d›ÿ‘&ÚæR:H#;0ÙyˆÎöVïGeèhŒl3™…EÙnŸbÈô#ŠH0#ß%‡¡3)"”®¥úÖ?š{ÊÖO¸¹_ß5a{DfØíl‡i.Uá™%—ä‰“»*Û°PS~Ó±¡"'áoz{ÀVn§ Í+ƒÙ,UŞv®ZGé"X„­,¶ˆÎCó¹¶*Åó¢ˆ‘¡Ë@0cñ„ƒ-6{a“¢VU¥¯ØİíoX”>^bü24*!‹/´>:à#`ÔC¢¬µ¬ñ°Úƒ¢MÒ\Ášû—ŒÚ²,@“øVg©3Á:WÆ!(w/ÏS¼®ı0¼w`ˆxkOZÔ=qC…ŞX®NÈs"wQ÷²>šê²Ú\ošÏ Ğ`Kj#ÄQP}}\h˜mH¬“Mµû3!#¼-dõ9LÆ„­¥îñ¸á¿{ğøI‡4y°½ª‹/ÑœÁnÅ†m ˜Z„IWĞ· |†	°f~š”—èºN¿ìœ)¨*„º¶^pÀú¢Šï—¶‰²ÜV9tŒ+hùßv<í´CG‚ß\·øO=öºˆQÒÕvG­ı'AT-º:ı•°LC&¶kQRm€€DÙã@ì=¢¼|‘h™}qĞïÃ7I›‰Ø;uË÷7†ş¦Öš¯»#}‚323hÚé9•hûû4hYÕ+Â³dç©µ'ËXÔK"Lôä_B ãâ„L§Š±MèÁ½RWíuÈ]‹Ş²1#Ûãx…1?…é¡¸¿M¼SQªUĞa<IÁê4¬@fCBå`[åm:¸©}‘›7åû+ê¡}£.‰I¾sËÄõ2}n’wv< ”Y/¾R{áJêwúÂw’±+j\`ÊÀÛˆµª­¡<	ÃEòú€frŒ^…lí?hrºfÁí‚óİ¥ıSå¤•¡şWXŞ"càÛÙ'.Ÿ*.d¦ÌïHjÚSp0ÇDZG¢İÖ.´Oş™*e”«á¶D{:Á²’9O4Úfœéd\Æ
.4ßÿSğ­^.³K)U©¢®ñú»Ê˜PÙ¶)+©f*DŞ\eÒ…gò&êÈû»|˜ky·ª_qÊ-gcê ´¬çS–Â‰1Ğ3P‹Ìp‡çÆ>Aët ãò
³¡û¥f7àÕ£ŞöéXyb…
oø§«¥´éùŸáÓLïLáøÎëE¿^ÈEdtazñrÀîêÈídö$NË‚ØÕVÒ¥®¤Ï+@äú¡ï|äÜæ~¡}ìQ·Ì˜#à’éÃ¦$©u‰ûé+—KbÊyU¦$[ÊSW¹j'´ ºHW‡{·üÊ]	Cß‚¨=Ò:/"Æİ\¦GjBeÀt„e¦‚‚	«:Q‰R{‰{¬Ìä™––úŠgßá±ÎP¡ĞãVhî–)ÁK3%QÙ@RÅLtß|
{5ñRÂs¹>ñş:p!Œ¦îKÖpÇ|8 ÷x·¦'3ÏùWŠÁúh¶
™Í à
¢sqJuZ{K0™%ª³ÚŒw"vÇ c”ş2è,Ë‡C;ÖJ³µ6¸¶k„Şa2[éó¬ÆÒØbÇÃ£-Ì­¨âcdÆk·[ºRVQ7fÍ=î®xªÖ9¬Ê®Ä„‡ÄÜ‰0+£
IæN/VY–â·Ù|ÕT*(B*Z?èRao¨ˆ2ÎwNÍ™éåò‡ÄÂüÉ·ˆ‘İ”Óöl§5:ÜÔhüZ‰tĞmôÊƒ5ı¡eg|Ì¡²vrÍ9Js,2î8è\ßşpºQ?Q¾¼ú˜çÚ(GK=ŞX+,Ie”¶j¾Æ<Ş÷ÍæhÚq–•?
ı6Ù§¦‚Å^jïEkF»ÙÃZX·7p^ñÆ$L¢¬ì¤#.Î˜|úãyÄ²Š¶ı¸“´ûõ±õŸ_ûo%„¦~{4õÜ…	P©67oHJêˆõ¿˜Rİ£‰=>áK±µËÄpo½ëCÊ’nşÿ¾˜7‰E47?gË%óª†¿5ú$Áhì[N"Œ±…âü^‚Å«ÒA‡ ª!|ké½yÎğ[o¼Ï	µ²-1ì„ßÔøó¹Û“zŒmã_U·Ç…ˆëît§©6b^RxIÕ£º¾ÏkÒ¦96¯O»&†ÌñF“²Yš6»X:†92n…íÔØbwšø¥šŠb>¤î"ëyC²ûpıa¤¸,ä(š·7ÆK‘ÛVˆyA¹ğÄ®fâ……Æ‰9X 	…¼
zKëğ¶Æ÷½£á‰ˆ¶·-82Ã$Íıc•pñQ›"ÄŸ@=Õ õmü›3>¥C¢5¬x„ÀÚ~ÅlŒ´=òâÎP–ÄÆTËW–Ü4w†=1ùâ	r˜²][·ôôLa©‹;ˆ‡|ç‰·ìEZ¡•Å’|{á [Ju¸ÒM%¥’ú pD¾^UDs !øwãUıërRËC×šş·äaJU^©’uS7ñ$û­Y£sfôà£Úû½{şÎCßm‰Y¾ÚI‹Õne½/JhÁh/=M ¼D&æø¯:E)Â<PÖcŞg	8Ú•ü·9†‹9eCSfÓía9MóeÏÃ«‰ÓÃäçy‘Wd}‘'ceNÅM.¯ww[‚e»ÙÚC&)„çjÓXR¼Mm³lVÛÀ!êG¶z¹Äá¾ÃU¬×d¸iòVÃj5=‰÷¶ü@±îÌ¶À¯^9€«Îøé‰ÚŸ_óÍƒ	s;_á6¹Io~ìÒR .ÍïŸÔ{5Fè/àÙA¶/œÜºU?¿o‡šìùaYê{Íü„>6àUaöÜıJÚîÉ¥àiûÕìÚŸZÍcŸïš(|úm“XäÔªÉ¨Şù`Û•~Xç£{Qï&vW%˜ôâMu½Óã|ÆÄ˜½¶ÎU”¦úyIòˆeP
Ğ’—U¥Ö2—g7Pg…Ó†/zÒ™•Õ]—6zX½6…‘7Ë“›vÓ;aƒš;¡®È˜Ògë|µ”õ„Pëßsc˜*@ô,áE®ÀjBíÖ`*]õ\;ÜtÜ}–¨8ñêæt:sÛcÓ
—´‘ªìÛ’1nfZbœÏi	åí ŒÄ
u`-lØF0İ;¸JÁ«äíáÍş¯í=câZHf%ÕOÛ‰TW’9Å7BU"jÍğĞ²Ä	x0W‡XµÛ„/wÄåwj„T™)„?1EªfŸ(Ñü–æê7Ìoê™NÊ½À¾ûäCşs°}„cÅë·-²ì"0	É« lSfóE/2Ã*pB’*¾±@|vàÃ³ûUXZÆÅÎúm*²„¼tğ¶b[—Èj†9÷ÇÄ«Fö…QcİŸ ;¸×o}^.Õ·ˆñCÄe3ÃW7›(,·œ¼\ˆ¼nÌ§æäá½Rdo"’ß]ga-@9|D–xœZp2#Ç§9aòu8,1“U`UJk€·q§õ·j‘Ù‚päkªğ’.x²cã%gí™pkZtEäB$JÅVWÊqˆŞµã¤+u±JU¼-˜ÍƒL+ş¹ÚfòA0w„©|ÂÉş—o Šš×êºóƒ1@yzn^¿OLZr\F×ÄÌË(Äà05Yy7?§+¸¼¤¸üTé¬Á˜¶sÎ¯Ü²øúJx×âcb‚ÂMM7¯-)¤•SU¸#x6”D™Mü÷*µ(Í.ÿSú–¦0ıw€àe~-¯nwºl Àïô'¤Öv¡ Ï¨q©ã_Vœ¢Y£Ébk‚ÿ ®”0ùToXì»ø=ïÆ­KNoÆs¾.sr¨mv>JK°vq"Ö}İnG,72k†¿Í¦!ÔÖòÓÎVİš\Š{É‚ÖY‘È:xÇŞ5¥×Šk®ÔğCêJ´P]oZ¢
0*vJ»"«è<Òã	0qeÀÇŠF|hV'2Tf¦Nf%®TUñ&_*4sõóÖà G{ Ï­½ĞŠÎú2ë·ZwiülQK~Fg_ÁşM½æÙ¢¨c¡p Hozd‚€´:2¬YC{ŸÌ»@"æ.›lÅ”b&èÔ.G€úÖ#ıızDd†ïwå¢©ˆ>ÃHÇH‹÷Õù…8Äd“ÂwLv«¶®œN_†>`hÌuïÕˆïĞËB;_P!=Èú$aˆàÈ-“ø ãUúÆ0-«}:çnX«ZKp4ÒÄKæŞI²ùq+·PP…‘–ö‚$SgÕŸäƒ(Ã¨¸™m3¼uNx[º í[BCN]<ıÜÍGˆ½®ãÁ¸ê¢¬ dÕ
M0•*şß‘Î½ÏmÀM‹i?™úºCíŞÙ‰ó9TöË³ZåúOÇ˜0•·\Yàıra«s†À,ryñKì°/ Ç¸K
W€c¡T^röó¹ÆLpëãOzD³†]V¾ƒ–Xe5¿µS3%–]ìkû`Çj}7ÿ|]Ô§¸Tw|,(ù4Ùo%>{Ç°Yœ‘ò¾âPS€æ8,J¯’–<‚+hœ'ï¢’,1ìW…‘¹÷¯5µï‚»­œ·HV“ş8Ÿb4dïø!×İô—·EÜğıßì÷6×À÷ÉM3–o´˜]Ñ½Vr+ce.õ§(•¬”†!b1ĞûX&•~ê
fòá¡!öXbœ²†õiç{šÎP¼CøİF’"D@’A2€t<L’ÿĞ®tº™¸œµT¢– TLpº®$—§xd¬Îô‡w´Ëbg)tê³y0/âS‰pLRÉ˜Xå‹”ì£èãÀñjCtÁgÏâ¢.âhPéßSĞqıæô[ûDòÈ‹½…{CQG.“õÿ2ƒ Œ'Šæ±A†Y«&ë/PÍ;&£}o.”€<$`}Y#|€¿zEÍ•{5Q~9jÓ¼@b"÷²åó9§\²ÉÚùl9Å‘õdW1Uk§æ ¿uÁE&+‡ï@¾”PŠ¬D&o*ÛĞÙ¤×”JÏ­q=­ÆŒD2U²¦ßêºQÿªN{)ŠÜŸ,vôÒ.?ë¶ßªr&bÜ‹‚±0b¢dÌ9bÇñƒñq†°}ø§³uüFìƒ'S˜ïpóºMÚ_Ş-s‰ÎEú­âgÏ¥\3ÈH§";ö¥¶ÂÕë£ü¥èw æÅbÚ÷¿WåIÅYˆ²—nu¬ı(è.¥ùˆĞæe Q©>–—%1›£ä{’«“júÃÚöªh(^ï–È–Q·2‹(¼¢2EºÀ(… •Ñ IF –Î\Ëe¾¯*Oì>½ª„ÓåÄÍ¤Zœ‡_|ÁşòOú¸ÑêŠ;‡Ù)Vè}“Zğ¡ÛWFùñd´'Qg-Î”P`“,Ëî×% À#1cèÊU&*Ã~ŠîPŞû/êş\IÓİàÇG'uÑş¶d"óP^öï#ïLs2Ÿ8ş“ÍFFÛí‹G.ëÓ¼ûÜLßEÜX€¸p]Ú-_£[UB •à$qÀdx·ÁóPš†e3%ú‹Q»2=BĞK¤…ÇßV|D”5”B`òp³ ½'E¦dOö„I÷r={>=NC²]¿Âé¢$„<Å“»h¢Î±’†ÿ6âK®Ô ¦ì3{Õ3àÒ<>‹\ÌCxàx¹‘Zz°6ı(µ§fu[úVf¡òKxa+pÏŒc¤¢N1«ÛÛn¤µ³‰ø­¬2ù™	<!ˆku»+m%iCD\¡ş›4Ñh5aN)Wu[ü 5u-n·2Öù=Ä·ƒK®ÄZlÑÀ×@pá¦L%yĞI7’ø$ï¬u¿UÁ?Í¶&€O•ñŠ±ûí¸m»@X™d®²Ÿ¥²¹r^0;F‘ò²,òs\f€a²÷šëíÔ©kâ©SĞ8’¥Ú#Š 2ÏØÙíadôéc,ìğ#O×½ß²: îğWã£Æä¿6h38 y³K´9ÌQåàö^¡RöK;ØÉÒæ—?üêS×'d½Û:%rh>½§!;d    Ô¥‚ÿCĞaN ’µ€ÀùÚËG±Ägû    YZ