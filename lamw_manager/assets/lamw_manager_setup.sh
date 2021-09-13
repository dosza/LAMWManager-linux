#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="21938011"
MD5="72c7ed583a1c705aef3989a2aee00719"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23324"
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
	echo Date of packaging: Sun Sep 12 22:28:21 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿZÚ] ¼}•À1Dd]‡Á›PætİDöof­Ê’Óä¢ÉßR0(S3¾Ï;Æx¯P-{Âd~å*~RVä~L¼™	öuGÛº{¢+V‘@J¾íŠB[‰Xœæ™ÄZùûcş 1:tQ^™%Ğ°!sL£“[Ê´iÜ×ØÿIà}0‹ô‘ós'p‰QÄ(Ì¤è¡J
ŒğÁãæ|ThZZ,JÓòè(oİ¯Ô¯ÊéibÖãs´ŒªGO/¥V—²’¯ÍúòZ ¿ğ®Ÿ¾~ØgUcW&¥\ayZëÚŒ˜9çn½1•Ï!ZÑ1º|*Wt`|³S1\ùÙòŠÔ“Š/"‚ğÀÛ:³Ü«…x`WtŞî|oµ,0¡Ä17¡sCwx€ 6s%
62×ŠÖ ¢a«å,"êUòUòaRÁ¹@…àğ§°¯Ú¹(Œ¬á é¡èú “´=ŠdşDlÍqŠŞÏ¿C½B0Ã”9{ÉÖº`iàà„j×…WVï ba!Ã97ìRÑ- µ*UŞß…ET4ÀG{"ª™Œ‚Ÿ£gul\oe­&¿^"³-»ëª
0‹œ6÷Æï¶Û¼Ädâ·( »äÉù­1:Ÿ]d™R9µ¼“+;g˜aì3{ù`ÏBÃ-GÄ2Èğo‚uõ_µO|ÉZ5®ğ2™×-š¦mÄÅìÎŠbøûœñ©yweO|I(f¦)U‡>)P%<j}İjãòDRËÄ>{İÈŸ”téıyÈÕ¯ƒÊKÛß˜Ç}Â·kÎ˜âRã #t2a¯-ü:¨ûg¬TÁ¢f²­pWJ”÷ëá¢®o+{qhx2Vh“0³ÅSH\FdL*§¦Qz`ˆ•Äo˜”T&LÄÀƒüulªïÊ ¼,ŠÈú‘—cÅÃœ–¥°ÙC$5ÒtS×	Ğs7ÈŸºj Éò{M`„ÂN³÷J:ƒÑ%ÈGVßxTöÚõ{x8‘,[ Âb³ƒÄú6µj.òÒ‹³Ti~oùpÆ"î®¢*¾p Z~U¹Wæ‰Õæşjdi¶¢’õ6»iœÎ¹ò”_˜™FjùçĞg:¢?»7x“à	é Ácvn5«<€O§:ŒñOı-1–¥û·;™a9M!Fá3_-v¬^;_”¾ s"MÑYİL!7¸ÖÆS?å"YäÒOĞX¯Á¨Ş¢mÙâ¸I|¾kaº¡Y«-‘Ê¤—˜‹8õÏ@ m9ÙŸ¥µ¾|%jû´Ö!§Óä({lí_õ»4ÔQ;Š@{f'_I{qª{ª³	Sûfóƒ]/¬«síGîh¾»Ò“'q¶èAñFàıß"°.C^ª;_®³›™—ò–ÌŒ€“–ğ	ĞdÖ¶ÈW2K½bØ'Ó¹¤höFêùôÈã”Z½S>á?ÛX¿„×4ÊÅ­^.¥§õÍûnyQ6[8ùcë¼¤HÂ`‰ìƒRäd“¢s©ºJK¤"oíÆ `‡G°|%$û#ÿ\{AmU¢š hîÖ‰.„xÑÙyÔºh~áÓ*cV¬ş¢Øíã„5ö¦ÆÄü–µ©(S×¸9¦çÕ–2èolu–;£°ñcĞë3–rX‚ õ¶`Cö©EÎuíÎ-ˆWğ#SoLzëê¯Ú˜Ïª#÷åY<òI™QŸùÍîX;6*ğØÁƒµîÖˆ›V \½œ‰œù%Î>HŠºÁZ–€İ_­·=ØşÇ5CÇ¿äÉ¿öıÍ0âñ–Íiü®óFV#}£6ı€àkcà´dn÷…{*£ÈÖ¤èÃ/Ê\ƒõ‚ƒQ5¾†T¹ïÒæÓz‚Æ"¾Ò?Æ…ˆ¡hö4šĞf˜ín†ê5¤Ò$úÕÖÊ’Ñ9wW‚Äû¡Xõc¾ñ€Óè§îËH^Íß:3Ùm›ûx·D¥J”‚†$d‚®ßUnõøƒ@Òíò]É¼Š×‚²|'§2›+
¼¸ó®×#ILòùMÔ£Ë+¯ –*zï3V_†Š›CÒâed»è‘+À<y
FlšÜB5É=¡sÄ0¯²ã’PP<¤+— <ˆ‰it­Dçÿ 
=³Ò·&´ÿÕ”šêç\ı[_‰»=4vˆƒ¯/@0#fnWl¼?OVëÁc~;ˆiª¿‡õÑKjƒ'¤ºß'Ûe@äÉT¶ÂØØû\‰»¾Ée'Vôô?m€ÖØ£Ù˜”
|Õ¼sIĞ«æ'òeFnX8Ú›åKC-—£Íµ\‡ .€Ç¾K×tÓ=ü¥®+òı·üXG˜¹Œ†‘YğË©÷“J³6¼„¡= ›B‰îÚ\¾e‰&aX<ô;Ú£¬Ê½}/„¦îD+¿L$y¯@2Bã/>šB`%‚Í£TæçÁ¡ıÍa\F3(ŠH:¯5iIVHSˆì›$›\€ ä‚Å-Vkğ|XáğY¯|†ıÒ!ª¯Q<|šç“ÍªŠíÚ¡‘h¯½ÈÌQ Ÿ«Ÿ7GÆãÑ“ª p\JYGXc‡Ï·D×oÄÅJ½Myô>Gõp&QB/÷¿l²R[>÷òÚ©.QùNÅÌ£²Ö½²uÍJ|àzå&­yıözöNî+)Òv}eHgªëeöÓ®pÑ{şş/ õ[¸=e‚ ŠÕ›Zz€å+ï¢~­‚¤ÙÖZf??¶H³@ïË-:\~—/yğlçç8Šé*ÑX(fUÄnkõ‹=kNz»]MÇÇ
 ßôŒ‰º»\:rÙ\ƒ3\ø™´Ù“?Y6,E„B¬ØñN=’;M*³§êK®º@‰Gr×%rfïÉ«T¡­Yo ãõ¥<¦á¹+Ò@`4¸Š ±Q|äiîèWø µ^ŞÌº<}­Š²ºÙÿ“‚IÜ8¯ ÓÛ÷•b¶¼Åšdçs²XO%_s|©ãÛW—„ Ø¹ ¦¼ç½™^A¥¡k ye{dƒ…35yu—&òµt*W—Ğ¼7§c¿ÅÓ¾90n9M#a-</Şk^',¨¡ —òï¢`ñâp›û&ª¬( vvèntç ÓG£iAÏˆ¾ùõ+Ğñ6e0ékœÀı¤œ‰ÿ¦tí>š{~„AE@õmò]Âr”*vÅ[;©Â´480|ymÏcÒDdùí¿×©•7Ä9‹şêWf1aÉ@ÜÈr½‡¦ŠµwŒÔËªËÖbÍı»Şš&ì©[T>XÆßÿEªƒô;±oã@	Ù4ÏÔ7lŠ)8„…àDGÿzœhmàªùJût³	À!i-7ã±Í\+~=W%ËvCíæÁA¥kÑœÄhÍtÆ™Y÷†Ì	‡“ì”j-‚MEÆ-¹öW~Şãvò¥Ö‡Ix»xAıc§¨‘£Zğ+¥9¥"¢®-3vn|(ª×É‹3İŞqÆr[ FIöíÏÙvãòF5ªİo§¿²ùêN&ì’Ñ™­Ku¬âEloQ)Ş!ø™ö= Â>+Ş
 ÿP&C`ôV©g{Úğlf€ü£T‘Ù(3]H3‡qóE€Pºn!{kÜWı¶ÿ­L4(%y­ÿD±aIûÎªÅ1~ô7]ˆ›[^“²µŞ[p{d†RfÈ‹~%gÕ¿û›:¿fÌAõZ'ËqNKŸ‹Ø3gĞ¹^¡™¿Sé 6pb]ìH(ŸëÙ‚LŒ™\$UßÌDgª°£|ö§B’'5>í_X¨jŒ6p‡õ£˜0û7D®CêJW]ÎÀ êºdzõÌÓhãVWƒFQ™Ppr­Ç×©1àÜï¼00Å«óÔîòyBÑœYTËå@¹)ùyñVKË@èèı>ÈgÌÃç-ô† Q¯öÕÑèŒàc[İû{pŒCz@“WÛ¶Šâû/VN„ÙJ|è•¢Eÿ¨mJ?—ãïJ~æÌ”ıØ_¿»ur¨İuzDìÿ$]ş—W‹ö,ä#¨ùFÆX'Õ]¡ğdWfSé…@BıS	&R<L\´çoØõZ2ó{S5C#£]âV,oíoÕ¦p0:©nÒl‘-«R­uÉ{ÃŠÕ|äå«Şà5Ş¸O©öYÚO Õh¦àdÈ5å3ÌÆöä3ş3ğ±ãOğÈáZ"^DÔZÓ5;¼-¸ş¯)LzâúcÓÌÂBU&:¿h;®–ƒ¼7x_oYõ“!·Î6ùˆ4Üş•ÏÎM¡şÒ¸<İ®K3§r¢%Àı¯3oq+ıRİÌÖƒˆ2©°_`8ZìwN·Õ„‰DuZşQĞ)Ÿ¼ma¶Y<R°gTÄÂÑÇJs±Ì­$8å¬”v®ˆsœ«|ø–ÀXFüìdïä»ÏŒq×p@Vk—ímæYíÈúŞøO˜Ëë£sÅ€¾ÖÇ5üÑsğöŸ°yÓyz¯TÊºÉ÷jüÎ÷|\/r›¢ğ³P¯Ã–ÄK«¿=¢è«Q6	'\k&´¸UÚ˜B¶è<HóâúàËQÓ.ç˜Tk±[kkY¾²˜k¦6ÎnÁ8÷bá9x8iSôÄ¼…B‡Æù X£×B·e½¬Cc™	7DœÑÁs~vŠìáô¢ÒG)h¬î“q¤MhÔ•³›òˆ=áb¨‚M>®(¯oK'üG„õ©ŒÁv7E¥„ò&wO=G	x(ŠtŸö«Ç£¼ (ô¿÷ã^{×Î„¤ÏÓ:¤vÌ\•wBû`˜3’ÊQ'XÍCB»*3<Ù#Ò¤á•Xà˜ú‘
]Rø‹föşÕ>Ii 0(>b^!	­ÏŒI'Z¸9ïköYYPŸd¶¥VÎ;î‰†ô“+ÙZÙ_Eòê©{ÜD¿>íµ¸ğwğ*ÜªŸ³j/Ç
in.ÇRwò=ƒ•ÅB^Ø%Wæ…+®Ü3àºÀÁ‘Ş“$ŞV@à‚d³¢5²ğZJİ-ûO7c³•€—Sä¦·t õi‚Kìğ³÷ºä ¹fêš¥2İ…û(æÀ„¾Âº™<?:ê„"È_¤Ux%	{¹SßHfÚß
…ƒetÈóYê–=å|k×(ò®xG5ÍŞkwÊÕœŠÌfò¸#àîg6ÿ~·*<qÇdåbúáaMkßGVQ«U˜::o°¢âÌ8Fáş«¿LR–a+Bö©n|D½ñe³ßnrq×"ÂoòNL‚\OÔ8½™š_Ùnj‘ŞlINPLYßë«ˆzhTÿûŒÑËE&ŞI¯pØÔè± ‰.=¼ùöüÕ=Òw ^çÙ*ßÙ¯²¬ÜªMg÷É£Š¢2Šl=ŒAFxY8$X’¥PFˆÎAiµ®îÙ€ÿçĞ{uÅ¶×›JœØ¸,ÄìO	 ıfÄ/„,@§ÂUEr Î]8‰UhøõtNÏEŞ/î½ëÛå“hm‡Î'yïLŞ—C²¬òßÅqÜÁwÖÓX¤Rª€ÜÜzø`»Æ«2¼‚Fl¬üDGÏT»áoŠ2¼Ú…8Tñ¸jèÉïaa¸‹ E²yÅ´o6«…Ñ°Pm}`6šùFî Ì8A‹‡Âeæšì°v‹s´5ÉB°ÑÜ®â@¸£EN=x)‘!éÀ¸"Û/jQdoÊÀhôXWŒl#&I™Íq67Âv¾{S!$2ˆÁ#BB;Ş-Â©—Cd
]×aR‡	ËEl8gu˜™†8e–ëdƒ«·f5”9]¦„‹ƒÚùÊøø[†™‡smOÿ[["XÃÍ|¸Æ-šûØ˜œ?õ]wM[0·2BCD‰ÿ€<B§ìª+}û<8Â’FoãA­ƒVKw¾
‰K¤˜QÕª†[6h|:DY*ºı0‡N5ÌÚµÀ8Ót²ÿ;wùV•u:zäy˜@O|İ0|é‚ÕéEÂšBƒ­?Ñ^¤¢ÍÙÁO›‡ïb‘f0q§ò• [Ù-M…DÛ„€˜‚Kæ¡¥¨¾"šˆcË ó‹Ù(¡Á»1ÿãŞë„æ¸¨U6ã˜8ù‡ºVÙd;ˆ‡<|]á3ıwO`?3¢€)“²uÛ¯£B†!¯Øæ ‰[	7öI8Oî OéÜÁb¨„S†Ûú&­IMZt€,\û¤QŒ¼Ş Í;w;nµIÖû'¿>À›½ùÕcK}°å“ÖŒ9}»96Ú
¥}ß>g¯h—_Š¯4,;ø‹àë:-ÊbÁY‘32“rZ»‚¸Æ’¥=µë@Tf)Š3õCşA$~ªíÍ¯	ÚîQkPãl™.¨†c  H†ŒW,ëäÄ×W«³–ü½Ú03×İŞ¨Æn!<®’Ÿ±JÒ,‡Dà×v
"|'O5mÜ"M,.Š^â}ël§˜©Š<9Åß©I	Ùx8–f• ?AeK:u=J¹k2Ë6¶Ì”ÑV²räÂO‰.ŸºØ)¤*Š”Å–¼	Îê'7µtÙ0 […Ö¦ùºÅw,1­.O¨‚q*a¶ä{°‡³¸5D zKrÍ2ÇñGâÜÓïaíe¶±oã°ˆÍ'ûó^î¾#¿YNjí 4jq(ÊÈÖÑú2]ü¤Õu-‰±œm@‡SI]%ÍÎdn™è´K—*³®ô9„H¸–RuŠ“mŞU$MŠ;V”a“†ªi’×Ÿÿ¬Û–ò»ã‰ˆ÷Ô®-Q­ß·HÒ»àSÚieğ1*RÄÃòÔ‰?h$È{’O8À?›}!c9£B®Ü.0ìşÔ^c
O§£ZºüÁÑ&á(™wZtÇUœ>hr¶ÏXÃ¿å ö–W-‹W ›æô6åGÒíc|Ä}º>İÅdè3‘5LYzÍÖ`ımbÃÍŒB&µ‚–ú¿Ú³ï.ÙJ\âÚÖõÍNPr¢	ù´0“OK ÉÍ]MÅ–õCˆ*‰‚†,¼ÈØbÒ)"ˆ¸Ù›ÊçŒ‹]z@¨FnHKRÈ';5‡‡Û€‚SG¦eBhJ‰ğY9Ít'‡‡à§–KÜßQ–²Ğ!W)"ë6^bà9äîõÆj5L´¹I• :YFè{®Ã9øPÚíXRºÆù>×èş1äeäTŞïâ¬çT4x—.süˆhUgÉåO¡7Í*í@ƒrCŠøZIsÜ¶úã¦l§tD°^©¯«/~‡ƒvßb	Ò6WcíY`3Š?&ÜşúUĞÕ•®Fİ‡²Ş|”˜ßö!b*©	`£T’ŠÿF3n#Xt¯4¡Ö-KÒ„ıƒt1êÍå·nágˆUO´Î›Aï°÷£!çƒ?Y¬ˆ3=l¬ë›¡[Ja”Ø.~ä“ÈYà‘QóF­Nş)ÏÄ õ¥c¿½gDƒ-u³Ø7jÏË!\:^áKIÜŠÕtNÍ$fe®£$Á‘uóÙtöËÒa}„Uóšczƒ ]¤ãQyã[KyyĞeï›Ä™ùeb1»¬Ê£¡"]0g˜ëÁN5nCÿoÎgšV•RÅ§¡¦Ã;Â0Sr	k zÑl1ÊÔËç°V¼:‹0#Ø¶Í‡ˆ:^ö}¾¹Q)P°—şuüé©1=[åd2İ¶aáì@(Q{¨›²‹B

XŒÖGsçíZ™3N·‚†…cÕFğ)fÌ'±ëÈÔ9A[¸.`"%œÑ£¥ÇHÌªø{Lıãéx×úÏSÛÅ¢Ù™Ù™˜Yß•ï¥¨!Ñ¶¥-§iR|½+‰Ãâ
ÑÉªäX}d3^ 6[7ã=è±>x~f‡Ë1
:ú“3\ùŞÁ£gµÍ2‰îåUu¹˜•}–¸“Í#:]ŸšÀ°ÄCà{oÒ°ÉQèÅS–©1¹Yš¸Gû8{«Júıß2 #?h1ÍşWä íÂLXâó+´ühëé·œ²œ/Äôx²¾ğ·Ò&o€+ïwíéÌ~ GJk|6®Ş\ÿªøT^8hŞ¥‹-ŞĞ×tÁøØŒ»·›dQ‘Xêµ/.Câ f‡ßAàqH°}¾\Ÿ¡…nkÛã»# tjªí˜5¨=5EkĞ¯ÂdñßÛy,mµLÎâƒ$İ8mÃ3çÎKÏM‰¹ı3b¿>p_â0¦XÌä—¦dõQì¬÷GøyE,÷³M9/zÅ_?»9˜Ù…T!8N5ê Ùx/;éù÷>xì?T¦¦À\ğ)æüœï/c§”ÍŸÜ¹?î$RˆtE5üd%WêK8C†ÍŸÔêœ&0Øô,‚#ÒÍÑâlz/‹ê‹iÚÊ—Õcó†"wH ¦Ì‚"²üí;ÜÓŒxôŠ·“?åfh=Ég©S
_?›•BİÒe£®;Ä=QïåÃÿ{r¿V[}ĞC‘¾-2v^úç™‹\Äùş]9iÏg=­V¿[ÊÑ%÷5t¸®”\Neœ­güH½÷±Ó!¼¨ğÁİ_ÛJ«¢=fæQ ¥Î9fLv…Õâ5—$ORtËÃ0ŸT¢t}G$Uë4`¥Olºà4Jâq°!Ô>VŸŠïÉ=hØ¡Ù„¶@|¶ş¿På ,K6éêƒê°½hãò¯äÎ¯§ĞI¢ÇØEBØ<¥Ã¨¾Åª¿ş_šĞm¯1A[¤k"¸ÜÛ„¢¸ixÒU=9€v G²Xo-Ä3‘4W¼wHõ%ËÒØÑØ£'Ø	 ĞI„ñ>cC5©š	Õd&q‡ƒçÃf„ ;w¥©'£DùRCxî+ÿtFœf³NæÄ¥Oø3ª,šÕd‡ˆ!RœÕÓÍ2[jCV±-4âìÜúÉ—îsyÄ ÏÁí»>"Şe¢áºâÚô–Œ‹Vcédıa$46_§—ö4lW¯õ’Ûà×¯Ü GiU<Ô–¯')Ññhº½Æuÿƒcà¾e—L¿·*î@†*¥Há$Zm¬“ìÇ0/“ÓP-ü\ÃM9€öîSÎU„
˜­¼š!U9-¢Èy4µ›+¨7²ULØË-íçÙJ‹å$¨VÒÓTz¯£ıìŞ©«‚|—Zq¥Î˜8Äî•ú`ôRc’ÂÚ‘:.•Ã’~U´Tê[\Ç¨ëp”ûºR’*dÎø´¡*~uI nùŒ9€¯üû² ĞĞ“&NbeI„ßí×˜¼éÎ.ïóÇQûO»;f§N@‰n¹Øö’âmt¥ªÄ‹0ã\°	õ?›X×3fARQC`ğQ”£»¦Ô¾×°8‘ØW“t”C§€ó.$ë%™ßÈz°L&É*0ìq7Ìn–w7„Ô™÷o¯T/°ªrr¦ô:GüŸÌ^á¨±c;É˜Ää‚³©ò7NAaÚnj‰@»Îf4ó'S¦¦åÆèÃQ‚2bŞ$8¿éêæs¨X)˜Ã¡bæÎL«Ö³ÔN] Õbz•úÕOÄóâ|<™ÂäßˆÁãÛ?`ç/ÆïFÄBÛa“Œ„<£˜³Z½yDñ¿Í¿¹Q£ç9w½SeÓ©*ÛOyG¹‹K+	MÿX€¢/ãvd˜5ß«€¤g¡•Ã>Ÿzµò¸ %pø…ãô$ÀÓ¨™úxĞ?É¬"…k¨ï­HØ!=R+] €8` #Qàƒø„[ğrt´«Å>xæ	ª¼½Î	*‰ jßù¨/Çèø„»leÓ-aršF“»"N ¡>AøÏP$›1a£r¼\\ü=ª’Ò¯£J¥±—R"Ë by÷e(­ş'0¤‚Ó)=]‡‘PÙz7°àü#­>!—wÅÔ^Í)q	›Q`Gçé¾şš˜è › Ü¬tøšìíÔ6ÉZº¹ª¿Cy¢ÛO°Ûó‚z‚+Ü¨-’¾R–ÎhqîáËş“ò-o\¦[öÁİJ¤ö‡Œ¤â]YÈÕÕ­"—Y:¤±‚ÃŠßD¯e/ßæ_Ï›xÕTb àô^zûìÖÆí¿x¶¢,Ç´ÊNÙ#ß•QÇ`‚².5Uò;T|6æk•p2ôc„?Wgs
+¸ xß8Îªª´ˆøäJû3>Ù}~Ï•”fpf“**£¦?[1C<\pC[½¾G½œ“IëhôÌNõZ·z™×é¨×¯ÙÒwBp0‡Ùòúvt7˜@Tš¼wCy–økê0qúRñ€›¢ï¤ù­7oú.qWeC`³·†Ôâm¬ŸSîfÛ¢Œ|’ª‘ŒR^#;UqÛë·)œ‰sÄ9ÿ(Íó PıyÜ¿—"ÀHXF(
>ÂòY]Ú'×ySÖ’ãÜâ@D‰Ò8	¹R"U@,R •˜ÒZoÜNì";å9a Ëšô®h>+ªG=9~#8&NzEÔŸyã.½<f"Í«`i­”+=¬—‡ûÖ5Ù ½çwøÉîti’©Oïö/ÈV^l7Ã¨Î.-‘µƒót àö™Öoq²RcI\+Iö¼qfŠiÒwŞÏ¡M^¦ü¾±´íI&—)T®8PÀoûÔEKÊ÷R@}#iFó;ŸR•¤{9Ï?BQI?ç¬XÌïè®¨Ïæ‘â3yÑjº9n%•D™å>ö4ĞHÅ§©\”ævíĞ …Î/d6×HÏ36k¦=Ğâß3oïõM)““2”SÔXÊÙ8÷E¦­r"UNŒác<UŞ]Úô.ÓìMEªŠA¼[6ìx¡¶àDaÂ3±\¤öum¦xÃ?Øá6õMßBËC+ÖRh")GµÊ'†¥I¬2ï:„ØZeš’™cœC¯'¸²û’ÔøËŸ;ö%kN¥ÿîcÖÓIEH	½óåÏç_[ÛXËëìúèè?EÄö´ÄÉ 
èãZ˜­ÙZ<=[9ùbèR„ÂÿÁÑfMdUÍ“ıÊÖüÉXóS…Pª„“‰»t’KÌÃ¸Şã+é0ÀS¬Ãvh'«V|ñL¨­’¾„×Ó)uÛzº&ãĞnçGîù’\û‹s—9·m÷wçLmãïReãÀeÓ˜,°ùh>ÔgPb4óß¼5}½`ñ4 \ğPãS0ÒÉba‘Ùí[à=vÓ
\*Œ@Ğ÷ÚÒ¼j6ù#ƒ¬Á"ªÙ	E¶IO¡ıeX¼ZÈåWâœUWh:Êsñ{sÈôÉ½Â›íÙüñ9#¡ó‚^q£NÊ%cÇjdpŠ®CÆ7š1~lïµ´¨L‘İhû¡“Qª®Ÿ×ä„õ‡¦å1¥ô¹,yt=¨Á9Êş²#D°ÔÅ%ˆíúøËÃnU½wyš-r°J.ßC(hp+Ğè*ÈOìí+¢‘˜ü¼fcæsşÀÎ¤‹ßÑf‘I›C³=‰at)‰%7èÖ’ú¸¶ÜÅ¼Ğ~?òN3Ç”»MõÌíÃ%ÖXÒEC¯æ“4KZ—E ìW˜Ñ
¹tÀ õESÖa‹~·a'’+C¶ªøN/`ñ¾º’ôêá”ËÈ(ä`iı}gÊ~ä¬¦À92­~·'™7 ­B%}cj¸ñ;­B£µL^xfºÉ?YÁPGòEèöÎ“’u›ÒkËGõŞ„@VXÔùĞ£›Ò’
x^‚†^6ô™Ê0èü „Ş¾gĞ¨yÆÎo3Ü\g¶Ì95ë’Ö·ç3ø°<ÉöµS¶O˜Å¸ÉŞ1v•HÑ'»¨Nôb™•s4_Csˆj¦èŸ¡².¹ªuØŠĞ#ÛA%$#¾e7ºÉÿêñ/*ÂÁRÛ?Ã	 ùS}©5Ö#î=l‰¸‘íúH¡ÄıQA’Ç.‚¸ß…@B$ÁzÆ%m¸Òî–Ò_µÛïY’Âıš›úÈa£©Ä àúqlÅÒŒ8f¨HˆšíVƒÛÃŞIdP#›d81bt¡	 Ãc–»ŠƒºqÙ‘ŠQ¥}‰¼­ÖÎ¬
ç>w_)fYÙ°—üşÄtHã†¼P˜#MeòÑ=ø^sæÍ¡5ñ——üÍÒ`wl‚ÃóU_²A*íyÍ»SÇVîhŸJZêMæÙbŞPW3’•i¥3¿¦†h 2¨ş"ƒ Ø‚ë^Ï97ÍWîE'æ.Út°"\	GĞAñmJŠ „àïH818öFı=«¡‰¡ô%}Á9Àè+3ù*†ûï±X8“]”#D‘Ÿ‘CÏ¿§O¦Óóã+KŒe2àÍÑÏ9æ¿ø`’"WûÅşà‚µä–ŞtÉ;qƒGz—|°q¸X½0á–ì¶^ğŒ¶3·Ã_3ú‚õşîr~ÍŠïµ*½ .óô@Áztu¾ˆ
hç¥‹~XB`GG¾E¯úÿ`Ÿ+çö·&+ÂŸå¢{¢îŸºç7´¬HFhŒ;Øı ¬Ç2¡¡¢	mã0.•?Àƒ¦‡oaGäÒP®ú=î§éö¿Šó_Ï¨Œ.fu±Ç_”\†âì[sÛ™Z[õÚÁAÍŒ iÑ”ÄôJQÓës²;óU‡Œ$Á'JŞÏšt¨~¹&kZmózòÙªObÙéÏ‰Èµ­¯ZLı‰h×šğ¿Û4ÔÇ1Ãi{Åš‹‘n	Xë3èƒiïÜ}‘ÜÓ]äÒõ^¡X6ôÇBnëh×ìİQ;’Oè¦ÆEf™0TÒÅzë;\R.ÌÍf§k€½ú ±Äúé¨b"F÷C rœD/	×)ê>\ÃYZOòìİk‘y/´{ÍNş`¿–2¾T,lüä,pÓy\¡¾cÅîÎ“e“5_ñzÔl˜ÛX+SxMMæÉš„/A'k¸c!Ç|D…5o³,ì4)7%şrº-†{°L8–+ÿP‘Óè‡”!ÕÂÚ¢â‹üL×zÍ¬GYÔ»°\ø›Ü‡_ÃëxCm€€Z²~©¿ÜF!ü&ºçOÇ÷æ‹à…?y†Ğ³òuI5ù‰­èáŸ²$IJŸ‘%„qÂ÷Ô<“ğû¯;öm›¸ZRúP¯±ğ^–U—İ±ºv/óİ/ì¤ÉŒ„0wÿ\[¯+{¯œ9j4¬è¹d«Ô,´"‘átLÑÖz·Ø$AŞ6¬‡'ñxÕ$o/ RúK/‘¤.³C­(›…ƒo…u¡KLq˜¦÷St¯rQã‰|šPs¸)*FÂ:P›ıÿ@nb?OVqÙO*39*ûa¿’×XRVñ;²vÄ{Gò€Ò2ˆÒ?’b(V(w?3Aá6+ã°KÈûú:ìxÙij•QÙü÷¿8Væ¯w†=A,Àˆå¹õ©n>9Ë¨^!øQ°«˜ü½ùz×¡4Ï?m¹kµ£OÂí<“HÍ¢w9¯mu¬?ÃÈœ°ÑÑøÁt}?4‹cGQŒ#AMâì>„ı°±w¤ËA†Æ‡"HiZ§|atãÍ¢¹ê«)3K2²*´”q|¥eî@ù60»{Æ…¶u?§d5Õ©Æª+ÿçîÛ¨¢$34)Ëm¿e)Œ¯K_HÔ¸¯åöDòˆ”“áŸ>TÈ¶ÅŠ¬
l„9Ğ½”îK‘¿äë¥üÒW‘½ <ŠézÅrÂ>±dİIÎé¼¿{£ LîoX}\çÓyÈØ¹è¶²®6WÈ÷™&¨›qc?eì’'3Í2ZnF°±è;“OdüµE}§0“î_Y
©¬¯7_Y…Ï¥øNeRıê¬4TkLç,d¨à¨™}İñŒÚ]£D XéæIùõ`c#“;z‘»¿ºÏ/ùu¿ƒöÿçŞve	è”š(Œş¹Ğùm¤øôDŞÇºØQ }O½VñŠ¥œÇ†kE ìŒTñÜ~Íá*ÿÀÇŞ‘ºJ¢ S¶¿¹I$é0ñÁÉŒkì@›šW…èyZ(ÉÍr]`ğp>²ìõ¸º¸"–’pëvag€ ‚‡:o§ÂRHU"¡ùÃ³	§+oÆq®Ü³yaf™<éR˜q¦!­£²£+&*¯O&<­Ğó¡Ş%ö	xa9œ´:Îñ«Q¾AcVC­-IÑşö'õ)JÌ—¡å,{¼=Uï#%ù­HğĞ‘È6şIRsº7òÈëX¿“µ‚ás³áğÊ¯m«€9øİlæôŒsU—J=¾CSîõíHëéĞU²²&¤i“N1*MjÈæ|+:eñDíÚÎƒÜ„‡“Pã{ÚˆÄ†ã_äã°Aˆu-g¥BveµLŞÌB“‡³¹â¦»JatC¹ZoŸõ€vÇ7'ÄÖ’Mk¿h:hä`9Ìü¨ø?Ë5âÕaÉfÅ`î`½§ÖQTÙ3†É¼#pVœ]¸9@‹VU‰êp8G<ùD5ü™›£÷¬üÏóU”$’]élmŒÀ€öºêı÷ßp@ŒşÖ}|²±BoFñr‹ÇŞL„4şò“ãc¸`İdºJ¬rñ5C½SEí(:òP-Tsm•¿PB¿t˜fÍúûğÎ^8ûö™]·ÛÕ	î+ "	SR9{½‘(ï]ûxH7Uº]“êguöÂ½lâƒšëBÓ
÷[×›¡6Ö0¿Sèå	ÚÍİ,k"%‡–køâ%éôz§÷¥ØÜe›p›ş|ûğ€ûp0²ÆYáNêÇíı¨c´ÍÄ z+‚ûÖcèï_]ç—¾6…Ó£ÉŞ²ˆ&_=R Ë1ñxF0JXÎıä5ÍMuÊEÃNÊ o}<yãgqäª8È$¬+-KZºN"¬bĞÿ|a¢€îÒ‡%}ê2Ç]R2ìeå`ômÛDlbsõF^?ò@rôFY»+’´&OÔ‚SÚôskÈïYsô™iœÓ{à†‰&ÜÛj`9¡ÑÙãQºå‚‹×!è#9MÌ(ÿí?c­WyÖ·&À?e9ˆ0…WØƒÅLa(<€BÂJDP’îæõ üá‰‰t^† sñt7Ø°­o4z¼×Ù%L‰yíŒÇo[”n´[E±VúHISİ˜oBL¦ğív¾Mvß«Ã%Æ\¯ÿ¯BÙ mÁÛ~`ú*Xj-ÿl”ÂƒX3Êï½,*„Cô€çGñ z½pó4èNÒËKw‘]Äá¦fÃDâ~ajXÿÅO;Û®õq18şâŠ‹m„Íù×Ô$¬0(Sù$±ÊlvèiQïàwÈËBÜ%gğêÃ'‹Í˜. "ZT’©°Kì¦B˜§MÍÆ?¾´õää‰{Å%°oµÈ‘"vpRòTnÌ»¤Ó³Ø*çê›²P7¢VãÅÀñ/¹E8÷ÃgÚÂuJjÂß£À9N?§ÅØ!Q;k"áBu¬xòµs;Ş±')kr}w\vRr°=ç6ûg¶Næ:vÉ3pl„SóAôÉÎÍÈ5şa…C‡z”Prş"zk?P@¨ûaP¸¾hX•ğ³–Y‚½È>¼È4ó!–CTß•@“Ïx–‹'Lva*nÎgÜåÆÔÖ¤1,^+ßÍšôÍñ²Œr}FN
,šY}óûÃÑ¯†ã¬jí€¤¯“×ô›òDª+%UúØâ(^°“BÜ Ôí^'³NßÚjŞs•Cøğ3Â¤7’|Íş²y³H¡Áé >H™¹ÁğYÄ?V\­u#CÎà¥Î¼BY*Lô™¾·ß³ –nXš†ôoCúpºC{»XÎ³×¤CóZŸáo‡G{?ª€k]^ŠëZ±ó\ó‡1BğËşÅ~ .Ü&)ò«L(÷ª	"¨®gy5Hhtn]Ï§OT®©åÈ|U:ëÄêjë|Y{@¶1“Å’w{ãd"ağYÊ6>DP]@E»·F‡Q·‡¸Zeì¤,şÿJ}œy«j¾c$–ÔÖ4ÒèÛaÔÌm¸hã€™MW<î
*"3ƒÕm(~óö½{Ğî¶Ã6ØèãÏ.ĞpU…rhíœÿ¨ªº âÿk]•Ùñ:ï¡?²ÕF50™MÓÌi ™wr.vuSX¬I$¹è®é=ô¤ÂÙwK>¾\´Rdì£ğj/S³Ÿ£ªèîÃ~·“ÆjøòIC:ìlNN¡ÍâbC4Úˆ„$ïô*Ã¿G"T+W×êÏÛÓâˆ`Å'Ü×ëDfşœ¼Á…¦VƒîOÃæ^µ„öØmş•UÎ¦âºüF²€ª„qÌ½^èÓEš©šÑ,ÓİµŞw4PGA~µ¡+J#.I—doaœæø–$a`–R?»o@B¬Ñ­-ó\u’b3^è‘6É¬êİ­!ÃëÁ}œ ¤šY?È¹6áU‡~RQæ@c'§ê‘%¿ıyĞ’GëGºƒuÏùUcrØ÷)£Æ¯˜iÉ7èìyj¿ªP¬X{UmL	)AOŒ¹«Çnš©á›µ	
óSı@° ©—…jh+*”ıïµ}u“¬YµAcšç¸zFš3Ã{¸™{ŸÙï°)(Ù¥Éf®åÿçß°kûµÒÄˆOÿ4À¬t»¼‡Få½¶ÚQ­½šËÜblà|Œ›
Ÿ2¤7½õÕ¢†Èï2V€æ½jœ@)ópâCèKmUÉ—ç|¦é³}8½£Q¸â&çN4¿;wí'q»6æºbï¾ù–k«LóZ10ÊJÿ$yHÇpÍ±–K7RWÉ³B™¹Æ >š«ÁÜéŞ[¤ÅkPfÚ ú˜ÒÈxvàG-|õXVòIs’Rñ¿¯'´·2HQó×©ÏùlÊ¿\Ë‰‰ÈMå…88îÿÎğ¢ê¬û¡[o9h,&¹n`˜fª­™âê™ô vÄê’4†Ç¦ªPë¿èÜĞœÆıÑw)Ğ«k†ŒÃùñ ¯¦(dj…Oüx˜Mc¢eŒh\.y™‰
zª1i3øCûLÖ*µç¯,ª ñF z,2ª¢WÍ0 %¸vÕî`>
	¯®àş$|f<–¸ä_¦{¾[%ù¯Pp¹óC¯Â*¡b]1ÇÓ?ì¼­6şéò¼}8[FÓâf¿…ŞKår6Aƒ˜Æˆ"Còà»ùv?íëå Üœ÷2ÔiÙd T!`¼=9ˆ·¼ºÔ"ñ+º<L6n,N{¯i|Õê¥"Ùí ,ÁY>ZP-Ga¿¶Öx§vRÁ¼ŒÃ–ëaº¢‘(tÜÅ]­Ê÷ãCFıbQX6ùµf¹h­¶•pÿˆ}½Vƒ˜²Ú<áÂFeˆ“ß3ë6ü`÷¨ôHÌ8>–~BÒà–Ó\÷Ğ3±‰€£Òİˆ%©ÑóóDì²U_ê¾ü3GI!ìi0Î¾;&‡Œ%r2Ô¿…à¢AmÜäÓ-­¡ä¸Uıœœaqm}3¡Ë–ªxCDâ;;[H}ï2Â°i“U,ÅzWV?‘$@_ÈNw³î‹Óàï¨D!† ˜ù:Õ†'ğWh±ä.S™Ñ¶l"x0Tƒ?\ĞZ–Ö¿8œiBX|U÷a#4 „àì)ÊeşêXU3ùñ*Å§ĞQ¿/]'K=º ¬6î\ÔPu‡L!Pı´-–¡–ó‹©|§'‰Ê‰eoùv£ÈDHSÊ6›šR~ŞBŸQ¥ˆó)®^QãC§…&ê’ë‡x‘,0šæ#L2D	6ZšpŸbÏ,»£7s¶Ê¸ZG Ù,$æ÷D¸Ò<˜{UwüÅ)öÃ5ìŸĞÖJ ßhæLÂæ¸F6rÿPoÊ/Ğ®<éÈÆ=Ç‡”ó-?ë4)uH'ÜÈ¿‹XîÊ{ï†t¢Íİ‘Ñffˆ«økZ»Ì­Lv:.öàB:-­Á2ü4ı¤WŸ6Od‘ù×Mèx(ù•?¦·E6TåÜˆ¬-±¶ø ZLIƒ`rº—yqUªö¤!Nj,ş+ÇßûAMîhÍ÷Åôä lÉñİìD+Ğ,Í’¹éˆ;.UÖ†^š» 35œ[7‹Şğ/„â-j1häÇl"ñƒıüeä¬.—“¶æHœ•/? hğpF¦›=Xän'¢.¤PrX,ñB®š­Y	r±³:%ÒìÕ·°œlgªdv÷Ò<ÇpÁö0ãá½z‚E,BT†á•ãáÓxoŒ(Ê<òK6sU(üêÙÀ4ôEñ&"9Ú‰£f,Jukí°É«’ápP–÷ßú/®ÎI·x§›]ËR;ËK'Q‘6ƒãc¦y‡ÏkRù+ñæÆÉ/Öš†¿ìGó
‹´b¿ÁƒXÕß7‡‚İQ¯şMvÚY~V·/<Ë_ÅnQíßç!xß’E€`Ä¿×Ñ¨œs(!¤€g3µx6»öÄ6Ü>Su(‹ı't+‰vùê‚Ş¦ÃP·Aı@™²tìxĞÙ$‰æB}e¸ø·zZö«•sƒ›)n%¼ùÛB5ÖçBsBuµ œ"_àQoGbÍäU‹ZÖîÌ®ïšÛ1A¬ ‡#¤şlËÅÌTs¿ç¦úGeƒ™q}-ßãóÆ>½~u&¬-œÔš3¾„XÑ®©ÎÍ4Ó^Õù@Æd®ş»bîŸ»J‚a¼6í³ÇÁºz£Õ=y
n¢V¾a¢€°ªÈ›$_„åXØöÕË×qC¡Ò9yşèĞHÓ*Z«‰{ğ¦rµYÉçZ(^S™	e0…¯mÕ«©`z­Ó»ç—Š¬Ös±¤÷¢˜-Ï¼ì{}õKs¤{êF=n¤q¼—‡oÿ“TÍùzÎMl­é; \]îéTäÎØ6®\ª(¿“„rS…x†Ùw¶f(êN½U{GÌz^»çEÀ ø\gå¸ø«N··Œ÷¨´QÃI'HsYºÈğ!¶ºç”·4‰/”Tc‰ ‰˜Qpü­¤FlÒ¼zÓ"ß1áìá[nÉ´òIO ‚•x½Ç›7äÿO°Pş„ãØµRÒöŸUEÉ¦¢¹"Áà:á¼¦°³ÜŠz³ÔOU/wlĞ\¦)N)×EÅD$Y4ˆ‡i©Gİ«ß¸q&'Ó;yÍõI`.~f[+£dyVVî×V­dÏƒ4ÓEÁ_•8ğy©KN#¿4\f«„¦¥r~qâT"Å¼gòÓ0˜h?ââæQÖzmmñ©8€ar£¯Š»Ü¨ejÏ€ÅÏ9Â9ÓŒÇ²–#•…‰ì>5Î5zÔë6ô×2‹³	ÒN¹G@%E‡‹ÏäØ§ÉØu³I@o÷ƒéY,àP¤cÁµtğö)kH`¦~XİpQóñòäœŒº˜*hŞƒÑÏXh•+ÿŸÈ1y´¼ÉÆ…—•OÇ@úpšE(½‡—™`HCAOÚqÑĞ`O2¦³?	Q2úªsZ~!<inõ3ii	êÚùÊ@ÚÍCÈ ÔPŞº”ºj
•]”,„u¯^Í€(tu1´;ãÙJ„}3b44‘ó9:—¬7÷
ÖLßKL=ÑÎ9ğPç§ï¼T«†£X\ WÅhÕÿ#¤u¬ŸßÏWK?œJ§]µºDÎÂğßİ¸´ÿ…;áÓó¼bnš›Ú$Œ•ŞÇì¥¾–ş´"J_%b‚Ii‡‰/uß¢U­Ç%3ø²yê·¼A¹¸MÖT†hMHy <Ğ_ğÕŒ¸.h–’Æ'‘¯•Éggğ9÷E?2³á*QdèzNgYË›|*ª)·ÈÔŸÀUÍÛ„aû‘5Û(~ª‹í¹c¸òÇÎ¤³£yÙ¯Ğõø ¸Ÿœà…Ôä¡´BGµpTSõ#êkÜ€!HäKteJgöOİMŞûv¢Àb6iàJJ™Ä¶•ÃÎG·?ß…³(_-(u¯°Ã(‚”}!&_½3®§šyhÑ–$‚±,«’Yñ›B}[p>LìxÔˆ¯³¬f»¯à¡õ”ÍÚ^'â@œ<eÏ~É¾Z{stëŠ…2(œ>?B›€›ê}ĞBÀT†ØƒÃä^!l+ûà¦¹oB50<Ãa³Õtñ¦zé"÷r¦E«	H0îhÚ²ËvÊíµTZ&–ìw´¯á’ê'gQ”™2×‹b¿ä[ÅZõ§”ae»RRÎYíÁÓ‘Ÿ5;[µjyşªì 9ÄÒI?¯„¥Õœ¯ºÚ7wBæL…°Ü3ü‹)9Œ•ö6æ±Ò‚YæC3~^,/fn»'Œƒ9ˆÆ›ÊŠG$Àñ	{OÒ=X¶«Ã{;=ŸD‹Î+Ù•L“¢%ŠÛ§,K¯•¤±	TŸÁzƒ¯õïP}¸#Vu|uÔ‚MöÆSB†ú±_lç_oèôu8 û–j1'¿Sl±‘§˜ŒÑÈğ„tYF¿İ>PzÕf§„S%Şa›&
¹ñ­>KUÚÖFòÊ`fPzú6üq×P‹)8V{™Aê¢xT9$Ä¼ñcÿ¥Ë$²öFËU“)%ÍÃjk$mæ6=Ü¶R¶˜»J«S„³‡.oƒ_ÑŠóÚI,h]¾È…ó5 õƒ3<ù`DN+ª@“#Ñ¨>*GÀ7XÃa‘1¥Q‘Zv? Hö@';/®”´ÇFßi²+LÓµè{ÚNÊ´‡TÙNÍcE1j7jŠâœÿOEvãÑ]&)UmıˆÔg#(ñˆ¯Ê¿Üh0³YêRš¿%`M;·VQ‰ÎU§ìpÂÈ6 8—ÚÇÊELÖœc¢‚y‰èı¡T­YB+>ü±
9SZtÿüN‘cÈ$'e×4lÁÅ£‚PËÒJ+T“?€ho»Ó¦„Â@µ¬8MÅŠÊeÎ>÷^¾´î‡Í¢"“J¡ò4µ Õò÷&›¶ÑõÒ1Ò[DR3Ë·73‹7úõºÛT¨¯4d§Ät6båUØó1ÒÎ¹^ÜçHeSø_?…tÏï–	æô?F$‰®!³ãˆeÑßÑB!‡Ãğ%èlY~~Á¯4&ÇâA¿`ë‘°|@œ§ÒôŞ)›6JÂÓö¼t„Ê‚ûkQø%ÎƒÄŞ25­ìxÖWïDGÅ°j+’”<Û=ú¯s =zqîş	eDm±½jÚ=329Â`=¬ÄÏUîK	âÇ#Š|ĞĞáz8r³DG¬ ¾ŒŞ	œ˜wth+AW³\!²£†v»ÿ]BúX“GÕ1®OaT¨ßß9×ÄJ„\€„ı®"L¥ıš/µ_óhûùòò’0µ*ÙU.Kk4WIexa§,ÚimšşãO¬­xkè3ŠOb()šğè/Ò¢’>4 ~0åÏÒ< #6H‰[çoPÄ>wŸ“o®pbb—‚rªHcoaÏß©'â¨Ü8Õº—äóLŸàljÊˆ56!YZOÒçˆrİSƒ
îMQF+,ƒ×	”2+©¸_4¬–´mTR«uu.õ x$:xõóÖ¶ØëGFÅê²É‰1È‹*&äùÜÒ½ËÛÑÛ¡r.©éR|§0¹6 jıg^m·âQ34ˆUAP&æ8¿»Â/Ÿ‚Z¾—OÜà&zµD%i`W+“·¨bì¸İr)ÄÈ¹akqë7ä“0i´ “öóì‹GQ¹TçÑÊZŞçV™¸Ø•Pç-(Ã6‰—f¡ñIã»ë:SÕ¬6Ñİ¨Å\\ŠdÒ=KúÛÊX²‚’?-›ıóäÅ¾_}í'Êô•qÊ5”Üècü€hxU£‘Zª03Ì‰ÿ,¿¨[+é t®3–šĞ¯KTÓCı—ÿ4Şbß¢eKé¡êy:ğ»Sù"î£/hã±ÂÍHjä˜Èæè›Ñ^—º¸Ow,¦“šÉäãPÒåAÕäuÒ	6™›õ—¾¶E÷¶Îî·?©6·÷ÿøeÄ;
.ŒBu2¤ImëSbGĞ€½Ò;<32ÉéJàèSP¬N£°>bÎ•ûÆÎTAŞ"8\sö  Eñ®ŠCœğ&1;Òa¬»8›ßslfÃ^c¡7† SĞŸNhA¸PGf×²òøŠş.qwßø…«€áğÛ¯_šR^e5ÛêÄ¬øg¾d'KQëV%},?˜’&ä@/€éÊAfs4D|…LoyĞfoàaÆj}¬áëÄ!Y.ÜÒ‘]'Ï’&/÷“s} |D¦Ö¾ƒè‘r‚9Äv	vQPFDgÄgî¦€ñ<ü“<QÁk¸‡qşhöÚC¦ØôßB$ZvÜhˆ¦ÇvŸÀ&Yéô‹¶ê™Î¤i'WÆûR£gğªŸóvpåƒ|.ñÍÂ&XJ÷S\„j*Š<k´ë½û\"ò®.¶Í½‚-ùë©iÔH'ÂCØøĞxÚÉ›õ—Mäqş¼~µ¾ÿÃ‰Ã.I-0ÊbR¼]~çmÅƒ½Ğtz âÆû*Çé ƒ é§b]…r"ğ¥¾…šÁp’Êcõ"Ã‚º×i•=êâÍgjuq”fN[O{*2çl[Ë1õ‘Ûq F4hª9*7Ç¸YL¬Ùmó³¬'Ey¥V¤~™2bŒƒÏ­q$Lƒ*ê@/««.kZŒ[ªxpïïòàÚ™XK«9È;ÊÆ}«WuPD¥—H¯÷YNUc¤¨ÄT‰Ñ@#î«§Dã§é\%ãƒ/…Lñ`Ó•nÿPJƒÚØŸâ8–ÅßcÊ‚æî{Ü¯å1!v¥ã¡áŒqŠ˜1hPxı †G¸ë¦Ùq3‡€Ìn‡­IñÄ§fØ@‡ïö^ß`l£w‹¼¿”E:¤]‚à©ÖxoV"4ã“›óÕJ_orrí^ãQV-æ<<EÏ­DF÷(‚²áW`ıbª=/#~}pŒ0éO(—¤ø35'B¶T< ä{
"4m¨óÉÒĞ¦b¶°a„:‘şî:æc`näÌĞgñ¯u•.E?/¨mÑÚ»ÛQë/¹ø	¸Û1dšÇŞºG}a•¼PÓ)#;8I/åÁ9ü{•V	l¦Ò— °ë‡²FVg÷ÂÎ?b)¶$ûqÏÄ£àª_pÒµS/òB>C:Rı¬…?y7ô«Üº¿î"Ú1j²Ç‰ÃyÜ'ìqcaÔF@¨ãÃêò—ƒªÀª«;b„°e©o«'/[`Š¿¤zàÖƒe8Ü”²FÒ£Âº„ú%
”Éÿ#.ÿ'îfóš¤JÙ¹Ôß¸¡„`¸›+¥dÚ¤|·Õö²ê´)äãÖTg<ôÁ¥UÕşø‡LG`À8ø­­ë·ÿLºØh	.æÑàIg‘SíÜDÎç;XteÇq=·e‹Õìî-áJ”2<`
ˆÌ(SP0Œ…¾`T×½„›Î»WÂß•Î¼†æı…¹PàŸÙ—•”ôRg0ËÌŠ^¥Uë"şGWLÇÉ´`æd×#öÏ:ã±Y[lm@–CÇğFåÈÒ4@ë«¹}íãƒú¢°}yÙ·:)X(}P£¼¸äSœ¥ÃU¦	~v0ÃÿÏziÇ­£LÈùˆ“Íó…zõª|Voï$HL ÖZW Ü‡µµ&gtzC
´‹óÄö+ŠÔÿdCq|*<ÍŠ¬{¡/wÒÀ$ÒïÚ„Ü…–`bo>{:–#¸»,pHyU’e_ïç¦5.‘ëg†	õ›dUKöTOuÌFZ5çU°ºFË˜âôOc—¶‹ì_YµqÏCN¦xxÚŠAmãıR±v`ÀÕ) ¢ªî°±ËÈ¤¤‹¥¼Ğß=ÂËIìÖÄ:éê‘`èã€«Ë²fòo;÷ÂÏodÇå¿½!:Ú)£
c!¹¥Æ© À¼é(u”F0,I§X
z=+Ç£†3m½²çŞİÛ¶®»8‰äSöÑË«­jAEHûqùÆ^Éá°Â¤©Ñkj7<[K‡÷àĞäw8›(‰™&ãèäçº¾ó¤R-‚q*®ï5UÆèaÖçó©Wª÷Ì*Sş`A<ç}°üåä¨-ö1¯¨su?ğtğZIºÈXGÔ§íŞ0œ™<úáÕ™ˆ$W¤À;£suÀàBCéQVE8…N’î§¸¡`N<]N}Tsbp ÃDæ˜6@«ñ+ç¶a'àvÕm°¾9ì“£9„¸ß÷'ÍSÍjcl;²–·oJêù ÔTÆı÷"¦b¦ôÖŞïül]Š-ÏÙç?Vt):{%ÄãFfúA5‰É2Äòäù8å±ÛÂ"À¨Œóó0(ˆ@}+-½3,Äe[¥æ²+b<#×_ÚÂ£Èáë9 1ª˜mC.ïĞÛÒL»ëÄæ‰˜œ:–´èİ«C?ÁN¬à–Ë™&2”%¯oùò@Ê;µ®ÑÉŠYë]	@l;ÆìGu*!ˆ†’ê¨X¤%X8Í[‰ØÊ®~YgpÆ]ãbB*ÈÔÜ=Ÿˆå	é³%0>q’¶Ñ=ÿéœòw5‰­]ïh¥ˆĞ¥1‹lFÃÚ	Şgæèb¹l¼WÓôÎ–ÈàIÆBHunŠæ‹âÔxÃ§'š™Ÿûsu›˜
Ö
7}€ôD«w‰J½úpÄ›¨·D¥#6‚ÈSÀ vö`!°ø²a*0{Pôû{hAóUÄõáÃuÂ8fì£lt*¼:(Kj›ôŸS‡ÑZt!KĞ ›\ñF÷„ß¿4ƒ¢YîäÀ%FäƒÀ˜Ù{Ÿ¼ü«e;üÛÚñ6€ëäXûÈíéŒû;ÇLmÀ6‚Ç©qÔBÏ®FÄË3ŸÏô;S…ş+î’“â¦Ó rK±v1`PëíÚE@ŸÈx#xüüÆO\óH¿C™Ë×åVğ?I¿º5öÉy:ª.ã~u®«†·Í+Ú´5ı{8Ì„nS:ùñâ6ùÀkÁr;ò¸ùÚë­a£Ï]•¶Q8¨z<æÿ6İHŠ‹BM¹vÓåÅ„#ªÕé¥{®~e6jbÕGrà”ö ^…KÚ{Gò!1V0mkfï—±¶«’
ŠÈä«ùXdÍf¼}Xnªg—™9–¬YD˜m™òá+›u?0úóÂFxy¯:¾¸7¼»(~8‘j<kD©6|ñßm7œ‹µq/ÔÒÓ¿³•!ùş¨¢CŞ†˜.äEo-‡Ó;HåºÕ6$ßiìDõ=Tk¦›#b#}(C²·:ÑVùêœ2œyÇÇJh_×åÚj4É ğ•“ìñKn©u²¦ûl2ErÀQ¦°¦ÿ1Éªówî³ÒØz/4´	5ÒŸÆbøYuşi§Ái7%ä³ +“n&°ƒjá7ÂÈVô]NßËäËSıDÑ-Ò-ğHo±Æë=}LK»×…ÑÊr ÿŞ$‘xïÂ‘‡“à•s¹ò%~’ö&×^®ß_\ŒŒAà'İ§¼œ]îG,C¦U>FvŠ2bæa²÷²1&Ûø³ÿ~
y5.|o¶rU$ä°ğ'XÊ¤Í™P³igåÈlçx4{0ú£ËÏ©Üà˜o´–Šno!o~õ“ßÄ®ë…»ÔOE“ÜK¨^Æ>Úøİã!r	~ 7yÅGŒßDÂÆVEc^c‘Ÿ¥¬$x÷%E~é
Ø3rî×½´¹¶7%Õ”v¼ø¼Ù>BŸ×iú†=âô÷® %ÿŸƒà,]|I¯ü:ˆï"ˆ³å¤ˆ(‘‹@ÛFãƒâ‡û•İb³ï1 /g¸ÇidÉÔzPP ÿ„tc°^ºşì>QŞ9@{¢5@Tzò/ŸZ“G!õã-Ò=×wE‰~@6Å/ Iäg$uEÃN—!/“È¬Ï½‡òõt˜æÚÔ@éİøÃât›²	s1ÃıO¥zä¡„Å[0Ùn9Õ@+dárgJ—é÷ÜÌÍ‘°1Œ»HŸ4¡,6NîË'ø±nXî)*ˆ@ã|`Íg¡~f’àœÏ7hïÀh¶‘Â=Oò¼ ³îY¬»[íÅˆçŠ¢# ÿš32Äi¬¡È¯vcÓâ½Ìªéë–It:ËYm*é|V·WJö¯Ñ‘mÉ2¬íÈŸé†åÉ*ÛAêBÍ|P­àÖ“ÿXV’iàÈÿ¸ü¯¸Q›|‰ieË°¿¶Gaş’u¤²ØœwİœÉ§ş­Ø^‘tÑ@Z{vêF)Î¥ö~m¢ÉÅ³™’t©¦ÒØ D&„uS‚˜ï½7ŠG÷*’zÇîb>]¦•a=à"ïg(¥¯%hÊï’Ä­3âòA¼ğ•óC!í¹ˆé

^dY¼…w‰’›û·}©Ré¶†ÏrŠ	ô§iA¿u6˜Gè8H$~)Z…—6H±Ã[UnÑ‡»/r‰ÙßqC³Æá!ùƒ{LñÀˆßê7(‡Hn#tËfí:Ù3X«–ìÇ"9ÎPŞ^Rkšî¸JÅ²ûRØÎ\2­¤s¶ Úi­4»|.I2.gŞ+Ü,WïWk±~RR†Ì-x˜®hO;ÕméZ‰ÓYü¥ø5õÍx7ˆp‹ÖR=æ3…½óaqÕ•:÷Ç†šÌ"\”ù\“²˜KiƒèÀk-ÙÈlÆ8(äk5ÓÆ6}g¡ !qÚ`}0Æ²L†§ŒÛIrÒ4*™€FèB±Øû—O˜CÅhF…Ê­ç¦’P«ŞË—„_Ø­¼(k¬°¢„+\Bk0|&¡–(Lèi•’ïG¢‰òÒr” Co¦‘I†Ì”[GQã8nªpœÙ· Y”‹ZŸö;¥­ÇìoÃûT˜_µü=ªfX‡¨equÈSpxb+½Ô3ŞÅñå¯W‡Â¥§Ì*¯vOY§üÃÁK‡*L5ìÆèbjùt/Ô&¸ö`;†®éh˜°›Ó–ßĞCP?Ò“&ô¼³ Y-î˜pøˆ¤)‹x¿S”x¸mæ(B×¦ì€l;,íS¡Iã²$õ°&eÿ7)š2MkgçårØu7a¦ŠF|ÆëÏşö4ùĞ†=¡ãH@àá,²Áíå¦›¸dâ\‡ ¡rŒñ‚âMURZßb
n#E£³¥óŠ¦tbB`F2æMJ.©íšëKü<JKeE–ÎK›·R¿ß-¼å±öíŸ%7"ò»Ø`5ëhA>&
³`0ŠêvOh7¡›ª¡*†òºó¥Êçœ›œÇ½4 p®ğLì×bâœÓµ½.Õ½­VA<Ù¹•Oç®Ùôæı´¨{²OYWy¾Áïø²Zx]÷¤ÀY:ÙèóvOuëï1âvDÉV[À­»FÓÔ¾ú÷¤ÃU?½ı<x<tfÒ«?¨öøÒÕYPÙŒ¦·I9× –È¹0øµ/O¸ÿW_ÿDç„¡ i¬ª^ï©’mE EúJ@…¼‚€µ¦Jñ÷u†
m =IvÑmÀå°´ÂÍAÉÎà»@$f!‘mªÎÂïôãn=8“¬Ô5íè“ñ¸>YLªê˜üMV!TÌSÓÑmú5¼À™ÆÈÖ8ëÄ<šâ}RU®2f†–‘Nì÷ÛQ7•Äìû{5ÓqºÌxÉè5¨ú¡|âsª£X†úíıvÕŠ6ºÂJäÎA-kç˜tÁÌdâ4ŒZÎd6³Ùb›–ô=Cù{Ğ„	5¬y5Ä›$×S®ú‡âÃ?ŸçÖŠ1=#CG¼ß1)bğŠŸÀôÜx’ı:È/,æiÿ£Ìkœ³[±‘­3éærB¶OzÓ)$´bD‹˜ÁMo¾­ŠT sŒ£—/KÍz¤íÓR¨ËnMf8GgÜ£İô„ÃFàÎğè]ö¤ËyöŸİO|p&rÍ’Óò°úŒ“S¤‹a”•Ù°sØ‘TŠÄ¹RÀ˜4]#F¹£5HaIõ/©H!hn6¼´¾ôî4Ğ¢ ÉÑ§ï¡d¼*êF0XYç‰õo´ÖòšÙ#ÆX‹¤¬9ŠõP^NL >V2CÚÿ¬œù¾õ#gë\FÅ½ı½È~/Ïrm›ñÚóH·8£_ğYï æU·¹\7	Da'XĞĞ}°§Òƒçè«JÛGÃí?›8xNHoê»QzixÅÆşbàÛ:ŸÚ™ØP‹Õà@›f½ov9â8ëåË{4Ó®Dûéïœ¨èŒLaI`'ßMÖ«È‚vó€-(“¿òÖ×ó&Ø]ĞJrvra(kğäC<06)ÕoL¸<Ü¯YE¯R½õrAr”
xTƒs%Ôˆ ×¬Òî{ÔbÈ¸ª•ô?-¿Ü¯ÔWœÑ€ÍĞ;½ËSM	ÁHìv¶h´›F´ß€vÔ–ñX5š;ŒLùicsöĞjÚŞÅ]°Ë-ğŸù‹5&Ò×JÆlşTu2ö]7¸
‘¨SIÙ’¾ßaô9ëÆwpû®Ü‰÷ñ÷®)Ì,5u´]´@äöU@ä|zBD±>fw¦‚î³KNĞÁaÛEß¼i¶f±§İHm‚œkîÙAA{V†J„1±;x’B>'øî³‰”\{ud Û+ØåºÙhóöİÛĞqbõ.·{„“ëíJ uqÿÉt=¸1ÃÇğ]Ş9ø-åÍt.±eÛµ„UVi7ü}6Ôn>2´Ã…-ıë{O`}`‘œly*µÊœScg!”eb¶ŞÑŞså¼{íDCIÓĞâ_¬7®Ï‡ŠlÇTÅ>Uä;”D	%Î$ß
P¬ûş0K³(âèWa›·í‰>ô­ÙwÒŠ>Ò*ÑÜÄ›œ”¶X°ûòy .¢=F¶Ö•Èúw»"İt=­4¶»‘Qì£’ŠUöÈ¢'‚gŸTBŸÍüÊÁW°Ò„ÎË	e§Õ®ÁM¨Ø©¯TÈ#Êì ‡Ûu,¬Eâ[`p2t8úÅnAŞ÷;ZE/2™d2ËG-¸¤¢–1nİŸvrmnÿøñ‘d-Ä9äÏ);¯Ò«õ>õÎÖØ¤ãƒ?Ñ¦ğI0ëMZğ:¤v¶²2Ã“è/Ù¶Í(ÃMË0™ğˆÍùLS'†cÚE=Š_‰ÜÙr+ØbŠ&‚R”l9©/ß$»˜
+ÎßŠMÂ´Ñ~ÕßTÖ–ƒ;9”ä{SæB»ÒãÙUü2÷a­…8œP^“¬/guQ‰Çyqpt˜8/ãe™s“®z¼ÂñßV8nÂ·îa`šts¾c¡áËÉÄïº$×aDse wåboÚ=üE‰şh²¯SÙwK«ëGá$òïöÅ=3³]Ù`mÛ€¯ŒŠ[Åc¿Û“Ùüş2LÛt]ÎÚªµÜ;[¿lrÍ+ŸeuÏÁ¡R†HFË,# ’²à)+O<Áç¾ŒU³*gˆ<Ö":e:¯c~LŠ,‚¸ tàx/¿" Nœ»A¤â¶;;,ítl·CWÑ”«»ú††ù*KŸã@–î±¥ñäftPºhÓ³¬^„‘‘İN KŸÜái.«É…)²?£Ld	V®§0ün²hÅËU¬ì‹’—]¶Æëùz‘KËşÉ¨ßA&)¿u<Ì²¹Ÿ ï[ö$sè -˜ZƒÜí¼™Öï¿Ü±qÜˆêhÛW´÷“,ÒÊ^%€f=ra›z>Ş‹íÒÄ»æv¤î½¢$lŞos8UQn…¹yTæV·—J»ÎÈ^ñ¡¸"`ùIYk#dH¶Ò7zøó?|¨ş‘‰mßm> ãÅa[Édg8 ÖJf,®ØkC^ÜÙ9 dİ¿Uİö~ƒûáàÚm@¥qŞOD"í|Ì&LúiPw•‚Í›…Ñ½9„_Â¸mL‰ŒÙÉ§ËÙ÷¸œã0I–œ¨Ÿÿ±|
aøx¾°ßi´|N±ã.Åb£éÍr•§º­.r]û~ÿr¡ºşI<Aª¤‡ğ/§B Å´ÿQB\¯-hêÅÍp¼{©%‚«êƒóã|†³rísqOˆCÌü/NZˆbb‘%÷8K‘¤ƒãª¡‰ÓKn=ÜŸ#(Th„o°Úü¾‘]“.L*œ—ìüw’øÆ›.°ŠèÆ~âplºŞñŒÖÁÛºÌÌ_é+7°Õ"`ˆ"l¿Úuc—`üñYgœºÄGòÆn«{Ê'µä¾à-¯Ç/nš]e€ªÈ¨½
8…‰vJëÄXä"]¶„+2mnŞzÄOqÄ«S ßµ.ÁlñK9±]%ĞZd¼m»S¹µN¦rù†?Y§}² ÿ$òERnlk@¨ÅRz"ƒuògÆcdÊš•Ösr×Ëê‘Í9ÒEÓbA¢C€-»Ó­4D!¾ã,¥V8Ğw3Yî7Ûd%v'Ş¥;äµ¡SÁ©Ó¹ı²°XZı‹*i8íY¤7Á½eÛ›ô¢}éÑx„K¬ğ˜	x>@µ†~à&k=X]Ğ¥˜É “ ô‘Z-Şu,´šëËDÊXàUúôm}N²ebKÀoB{;÷J[ï‹A§dAš,ãyr#Iô’Øõ^”ZÖªíƒ|ZÊª†)nûàÃ"Íà]'c7Ô¨µíÇŠ6¢Ï¹·f!I—xÿË¡Q¾ìÎÕ    ª1wÿÁK|. öµ€ğĞ‘ï|±Ägû    YZ