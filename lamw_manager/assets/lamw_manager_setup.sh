#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1796252353"
MD5="95e38412700f347fe640301e5b91ef11"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20872"
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
	echo Date of packaging: Tue Nov 24 00:52:09 -03 2020
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿQF] ¼}•À1Dd]‡Á›PætİAÕ‡Awa	ˆš¦]3–Õ sd­+„!´Æb°ß¡7Ğ€ \Ç+‹{r½üÖ
ÒFOí´=Ó'ÃúOüæ
Z/è¤®ñ±=Ê£öiÆÃÃ¯ƒÂeÇ%.aWÔHÅºvš;‰6ğM(,¥9’w‘¿Ñ,eı³`ÆW’ò—+ÈV«‰#ÁÔ÷Ew4öÅNí‡èPßªßCôQ÷•í¿ë<ÊéOÚ•çEÄlÕˆ*òÏd_Ê–OÿæÍ.îy„KzÆd>³À*"Š„ ô5&ñÉü™há³Ï$³JOƒĞ6pfƒ0 êá4üGéğÃz‰Oİ¢ÀxÒ´Ü‹’wÁ¾Bë#À!ÈA;.êaÂ‘¯ÄÂ‘¢“Û¹ñSN"ßh¹ïN6_-¥K{bÈ¼µ2†ø!Œœpòî²¸ŒƒSzD\¢ÜîeHVˆÌÊÑãáMóºØÙ>¸À¾ ¯ˆ	ì
ÛÄw&·­?[{ë„¼ïU$4ƒıyæhFqDV)S!K¸¶½’j€Fğ”ÜĞŒ± ”ğ	B´€jRY¸òµïWb.¹èîJ%„ı n·Ø<úµİB_Æ2ğ…kW“ĞœHûªÒÒ`â1‡~ÎÒ-•hŞFR áŠÄwPÉ$ÑosíïNı…·^£61B·ê“RŞê‰»¢ 9»* ç5ğ[Ì<7vÃ³+OíF1Q¤¾Í‰Úß5Äáƒ…Ğ’\¦Á¨¦OÈÈQŒøúüÔdÃ,é¶\Œ[÷ÀpÚ#y|n¿ş%
—F½MC‚H®²‡ï.Òª•ê±.œå§!0h-í–òëşM!Cù0xÇL“¢”¿æÈÛ¾2Ğÿ)ØÜÌ”!(C&Ö£J³v¾=©AûC›ÿe‹Eú–xÙ·V¬+—°Œ“‘IzÃ§…èË‘ó©âˆÒéöÄPTêÿ¢$¸àÙ‰gÇ©\d…W°2“GY²å©ŞYwa¸Ÿ%0O¤@5iõ /ıPJ]nU{g/gİ4¼ŞUÔœM›­ãåpJŠé‡ ÌRØ¦FÒøş 1òÀ"Vä`D²¾!É$ƒµ, 4ŞÇ9€¾°õ›Æ7ÑËÑ{`^YõG_w‡úu¨âº²ÈÎ|°+töw”¢Íëi&+ºÅUKÔ>âûÛVœw)±êRû†Ë<yÏMò1Ó¤-TsxdİîSÁ=æd0v®6 ÜŒ°Ë|®aõ¸¥`i¡¸ıpøÓåù¯ŸÖàœ@#B²Ä¡¢r4G$Z¾-UíßSpO°¿ğkñ\;±ßkC!Õ§Õ°´J ù¾­$öŸï5‹”»DÛÛ¯¡!’,¤‚DEMQì»Ş¼V^µYá‹BáÇá©ÜŞæTî‡Š^l(ò)eNÍ0
¤RªÇäV0ÂHª|a- Ñ<jE’È4jE óÓ_i µ¹ßPõŞ…i•è$Æ€PlšÛC”LÛ‡g¨ÛÊöÃÄöS1„¬¼å+ëÇyë°CÏçŸ¸2UI<ÏYæÉçÃzæÚá?ù.¾ÃŞşà"8±:RÑõKö'JĞyT[‡„ÿ®²áEQHÈ8IFÛì“Ëuƒ%Dt³Ä
©NN·ğG–¯ˆ	©ãrå‹«¿°v¹›ÚL9›b‘Òù0_”ï¶&HƒÉI±u.¹E¿ÿFâL÷kÔ-Ë^úX«Q‹ïÊ¹ÑZpæÕĞ–÷ıs!ı…*•Èg}&Š~7t7!óU-4‘6Z¿½éÒ”+-ÖÅÂQ[_×¿‰W£F`hÂŠÔÖê5=¢=ìµİÅc&C! —ÉëZÿr6ÍÃ:ãc¿EÀíñ‡G,¨6‹özµöwS²¢&iÌétÊŠÉyH¢Ö(gŒñ9å­O‘H™DÖÎ®½ !-5.ù¥Ãô:Âå“¦ÈÂ‡‚h'óeyYô!xÑ¥ğ¢[€LÂ¨¹©Å–ÄN}Æot<´V~ÿ	iìŸ˜ÖËó"q¾¡Äª¥db3š ˜¿|]Œ¤B‰Mœ:2‹òF¤v´´¹u)C´èäª›Séş6	s˜§¢²›äx>jô”ñAÊWØÌ¬>’H:öW Pí#çÒ¯ÎH“ÂYÕr±»öî½-k&­zS{LQb…¡&Ñü¯™L}‰–ÃÉŒª¹„ÃZ&}y€Uî½;ÖàÏRÕ>ğCûeòİUjš\5ˆõ'¤štË¦ép5&!½(í§¥æÇ"™dK¦5PC³S>ézj‘ysüQ0;â”¿°İLBM
Ìï_*Ø¢¿*öªKr{;q¸Ğ¸b5 rA÷è0V­Cóp/‚a3ùûôÛôÚç9B :Ÿ•¾Ÿ÷å2PÄn ÉŒäpgŠuĞnû¦?v}ú£t\‘©«ØòcšÒÿ8rMã1ßdKçíjæ´%·
	UüA,CÑÈÈÏE‘ÁéêMó>ªÇz÷¹áÖ·uoÚÛ9o”?|Jì½:ä,‰%ÔºTÑÑT¼´^@i=üêKeø-¡UA]txÄº »$Ş[„ô«=G”¨1írÈì’v…¸r}—Æ}µB³ >ÅrA2Ò3ô~Y¾e§	"N…5²Å`İ[”=°ÄãJgĞB¨gmŞ¢ß„y*ÆÏ\*§­Ş<W$×fµ§3¹<PnĞòY™C²‡>Lécc6~A¨#Z‹q â¤T6É‘l y¨¨®}€Ïı&-bTÎ‡ØiCÕ‰¬˜œ/§¦
>Ò:³SĞ°ô)òĞ¬°»X]ëÆ¶•3!µ!÷;™±ğI»ş=>/Î
œ½”¬ÿ¶G>]«ß'œÍÃuaÈäÓÃõ5Û'š‚æ;®r¿Ë )yø©1YQÆn£Ğİ;©#- >æ<ïøïû+/->ËåîÍ ïÙÍU¾²Ì^|Gı«/ó¥Òò
Ø¸õ2,Íñ¥b
=B7xcÂäğ§O­ïÁ?¼ ø•mÃœ¥ğy:}L<)¿©œĞ6L^í¹İ?®ÈèG×’m&{,w@µ8´Ê+®¿†Q1ˆkX›@Y³®\î 9«udö÷eÓ_šRæFrêš—û\ôšzp>Mä2»¥ÉÎj$ÓˆÿS#XŠœå ü„ -¿ÀyÁ>‚*¦Ü°ŠzÀ[æ¯<'”ŒË1k‰oõÊ}¥<ë^^—-œN»ê@–b¹ùwç
f`8W"ïÂ7EÜFèA‹.‚ôï(i"Sn‡Áõë„:¦Â[Ãa›…JÙ‡‰Û—C¶‹MÛÓUš^ÃëÀŸT¿2R.±ı*½À„"ãÍ…FcÍŸå“ñ•¦´‚,«54€Å bkÊ¶6 ~™òl+üİ…}k rw4}ß‰`éTƒ1ÇB\{¼G§ÉFBP²`z¬¡÷7>WÈeº[–ÄüNO·‡z±âĞl	(fŸ†Ú·¬  +4=¹)¯u¼O`Š{g¼8°#ödR€éYœßÃ¬\F¤Šôúˆ5úÚ‰RÇƒiz««Ç™.o±ÏŠºa‡è|L*¡°mÃµİ`_³O;)?;”ßF¾hóç]	“ò(4u£&-¥¢½e&Âx¾+róB"U‚>EÖQì­ã§D#´;‰S-è±¦Š
>ıRe¢4TÃv-ùègá9,ahê^¸uGˆnÎóşÔ³Š›+,¶­å[Ğ`Òı<±÷€Y|„>­T_èinÔoknPç(h¸`´02ƒ0›NÕ·ce›N„¸bÛv‡ÀÏÓ¤WÓ½„‰<!*<qmp?Ã\¦ıÊA}—
L Ã¥‰ãÏ²zƒ×ìqiAš¤?Wç¥2e'îlFÀÍ®©S¡ S»lä†#Õ°ga×7f%‘ÚfÓ0Î¬t+•±õ6F[¦TjçXS†ª¢£ûE@Pj%¥[rÔV†×Ë0òl<Ò_</«#ÂwšÃ¬È‡%ğ"_ØTlOËªpÿàAh® "tA^-´JQ+‹Èİû¡¥4•²¦ÊCmÆÌV<±8¨ÃA¦p¾»;ï:o¦è‘:Wê»9X4?cx†RT9& ¸ç4…UñiÃ³SÓş6¸XÍJú¯Mrİşƒ?5Û$ˆ1MÌ6v	dd›şŠ$¸e™È;ùq‡İ4g?œiÑ$¹|aK˜<€AÛm‹ôĞÓ$'¶’û»QÈä«Ê\:3¹|YuÀ¦a»gZbEvøpú8“œ83¿àŠ*ÄpŸhİ)_EY5t¥ğtIj>8E|ş)éÒ"m„eh)5¶f¿“öÅ:é<søg»|/éù€—‚‚éÜÿm×¨ ™ë¬ïj¤³÷¬6ET–_“Aá8è–Ú¶.ï‡*­U=gŞå>wwIİ_Éöj¼2A>!iëgƒbGÜ¨d¿Qµí}³ÁIKŞÌ«:ƒ"M¯Ë‹îI¯d¸²ºR¼(ê›0¦ô4×ìÁ"…¾säçØ{[iêÏB]FSÀÍl'’û°qÒEdÇ+<ìOÍa5õIÜàe9	¢ùBv“4§ÇmC÷ì.ÎpÎ¿	º`[ïÛQÔ¾Õpr[ÌxIÏŸwŒ?)öb<škqØŠìŸT7/ıÎ›‚å³¸ ÿ†º.#ü/çoÆ•Ôxÿ'Ìö‹±fÕzEüÃìğŠ²ÿå1c†œrG,¢Õ2èĞ8¿Û`M`±ÖÊ^"‰\ÅNŒZ&qvÔıùÊFĞ•*öËd‰à¬²@hh;¬ù™W(FÁîñJ>ß[bà¶ö»ae&a¾]«o¥Y“ˆs
·&íÕ‡?±€©İË¯¹šYì…qE~!Òòû ’¼"Có>MDA _9ëzzĞ õué8îÌl+ØÆ§ObaFÅèzıš½† ¬$ıù€ó¹e ‹[ë›I(Ï¦Z9İ
UÅ2Høc¿G“ÈyËÑšƒ‰<B²ïXÍ=½İf—Œt:f0x—h˜Æ›·%*˜si”X¤UvTÌKkÛ/V­â·&WÉ‰,s8wØ“8Ë/¾¶_xXÉ[¢-Ih›ĞÌu‹–M€*vÙMõ¨{´l ß;ÔËÀ½ú‹€–°.òF	“×ˆZöÀHİGO=xuØŸœ¤êp8ÂS~º?£+5 }±¥Dbı*<Zyë²¬	ùèLwÀ‡À(wiCBõ³×¯°|hÂwıÑnv—ÍÂOE€‚Ñd’Wİ^şi;Pü¸‰°(_tc¬'§FZ¼0İI²Nj~a=áîh¢Q,öCÇLSéáõN²%<kM²½ê£àµÆv³0»¡¾¥Ê·2µ×­ÿú–„Ëv¥¡Xàšl›têK›Øt4İÀv)½Áî æ¢„ZC»œ&ä99ª¬È}ï[Î][¦0­šÙ,·ªÖ@Ò"F±Zdô‚?"3BW^ƒs5ÁŸìå[„Q“{Èõ^{ò
 &Ó³5rÄÁ·²õ½ÆQç€u—hçùƒñ"2!ùA•V$)wÊ¾ î£d¶áA‰&Âö›;t°’ıQårŸV­ß°Åòoòwæ¿RÀıº'dÖ>‚¸é²üaïç›÷oóÓ¬ôN”²Ç7JhsÄ’¼±Ğ-è
S-•V•+è@üz"„¢uXg§G"Ç¨_CPŸ‹S„õù^6œÆ™ÎZÆ"é>É~Ô}¡¤VÉœË-m°<ö`Æh½ÉÓ	º‘™à Lº%L!ø<}ìp¼J«6 ?´D×ÚrÎEM•n—*¯¶áæO<“±b+g&0Œÿæ¥Áè<Š°jÃYcÒô¼Ó%!Iø\ë¥éß?4º«övz£D=²ñPjdwúmıëQµ”›¨àç¼o¬|¨÷8ŞŞÔìËN«„)œA(›âc‚EÑ66àÀÒÆˆûO¥EH›¸á;ç¡¼•U|6=ïB¶˜/¬.…º~UĞo dV†§Å¼æÜE›jš1×54FÃ¬¨»S@·³­ÙÁW†¦<Yîú	&@g4©	ÊP´”ö\ÔT¾A[™Tu”5›•hø¤.50‹¶qÂmf?Ñm	TèãRÁÄ•îhø=Ó·B­Âñ&r1÷üGî~5d”æ¨•`‘šù÷&ı¨óæ0±«7¿›ŞÀ9¤³,¡ñw%"Æ°ùâ„bÄ‘x'Ñêõ2ü¤*—?`W<KÍ©~9Êö¹ˆĞ/áC_z‰ÿ{òŒÙt†âj:Z6Tƒ˜À}Ï‰UéBJbˆ;³G²~ğ­YÓõíãÛÎM1-¥qoèOA4ıÚ|Vp!™ÑöKx9*k8Øtk=T“”\.ß½éQ(ğÓËœmÓ
Ê”¢
«d^¿§@	Uëöx{Ê3@-D•;/¼5^'Jrÿ~òG€·°Ü1¦©mU_Cv Ö ·1äøü‘ñ×ºÌ”ÌCóâKıÙÕÁŠ!†B ,±¾3<%Ò,¶/rßëòbÇZÃŞ™Ù%³$Ÿ®ü3„—0m¶ƒã»1—`‹5â…-$ŒNÚp–«˜)êÄ²^Ÿ~Vjãn…ûuºMÃ›I^ï
„B9ğ±oÚøÉkvä¡ÑTÉ"tŒOl¾ÕÁOó|É‘{‰†)¡—m°¬nŞç+µPîÇÄ·£»·åÙæ#C‡ÖÈ€T-õÔ*ÂèK€a)'ÅªÙÅ\@Í~š(•}@›&èáç1rM¸$@.lV_Ûpëpì6$TvæU5ÁÄ	¤m}—²ÈÉbÿåÙĞÄZ¥x—K0irêÄG¾Ñ‚ÿÍaµ¢$BPB×Ók6²Âîé{—:û0ìû;åÃäRı_NÄØ:÷q{Ç¡—L±£+ªô@©Ì…s²Šú£c¾=ï`Ã·Rf|úi‰l‹w|#ãiÍëŞ81&¤Êqò2Àau¤È÷Äı ®xEeğKN*H-€ÍıœósCò€ÏÄ4¢$¹­™ÊÏ\`¬ğéˆÌõ!»2eñ'A,…¡eŞùQÎ«™æÏß¯iÒÚd1ŠÄÌÃ•¦Ç–ŸëşÎ&QÿHBãƒñŞ–g©vfÚ+Ä±»87|Ñ ÆÇY°Ü4I¢òºcäÓVvn¦ç³ÀË­zİá|€o¦ÆXó¹eûáği·#xåü|õ@ °Í â@Î±AK¹»•5ÿ\lj3¦=ê„´Õ±ö@½‡“*J? $iº·¹ÊP4§èº2˜jØûd^C))2ï!Ërg(‹Öxº*×o‹$1:ÿ¾ÛTÂCû¿höé2¹ Ê5¬(¢ÉT£˜pŒ¦”­&Ë­ÁXÈ C|,bI:È~úÜü×şL‚1•iÎCK<y›ô6Ü‘İ¡ÒJµP0İn±vEƒĞ­Q÷Ù;ŒS5Pt)Û“>«ËJô,X=‹é(qÍ¾øšÏYÁÔæ[RŞ0	sN‹½,F>Í§¤q2óD;»yßIeÌ¦ Ò&^tÑhÇ ÀŒRA“x#ˆÜâ,ôu®·Yr’QÁeX<3mN"¿6˜ŸÚ>ªØ)[—{@€õZ‹…Ş¤V Õ}æzNgaf8•éÈøÿ:=iºh–—Ö33î²Ss3xÿ¾Dïeª<ãj*Ğ§¶¾E¾ì1råûï/¢óƒ^Ğ‹•7l¦|8çRwHKï¾™!&¸Ó"¬âöÛr“%Œû%-o~jFW>
®nşrË$”¯KÈ!A'ö¿)(R{Å´š2/•Ÿã{ âßÃ§”àó¿ŠkÅıïb*°è½ÛgVPÌ>7TJËùV2
[ ]´€Ò1¿«HÎÿŸDm /µî	¦Ï^ÙX»³Ø3‚´›­{0œ ƒ0‰Ü„>¶—<ÑÇD#Í€0%¢Áªáb¢n®UYIåà²&á£<GŸ™úk:i¾fÈ.’¾,Ìî£'§Û!yáÏ¨dñ²ÄËykyÎjõßEÛ#¥Á_Hà†¯äÿ¥‰M‚dº°Je‰#vV³Uó±FªhÛ`:”fœÑ2ØÕkú>×0¥˜¹F*I6PÆpİ5±‹+Zî9‡«@ªÜ»=yÆdÒ¨
R6T×Ä¤¬£e32˜vKÅeL‡:\jhÅQ0])e¸ÁÓ`à#ˆÓı¥r¾‡^ˆh•wÿÈúfÙkS“è)lÚŒN’Ã6Jw}D•°k¡k(‚§×ÇdØÎ8Û“\eïƒNa|ísÖÏõœ*•Ñ°–¸qtLS6è³JÚ0ıÀC-ö+éXX´N¦±ú¤¢Ö–ámnüÿŸgşå5PÜE~®/ q$R\ÜÊqä³i•ØÅû³Qõuaô”ƒXñÇÒÂ˜Q²áfÖ0x6+&›İ&œı\e¡íŞFÉ_ç¯ëêXœìĞo–-¸ò¸²^E„P¶E±ÄK|Ì’Ë~n‰Òt>9Ø(öy'?ğ·şHÌĞœXªƒÍïäËÃ¨Ré'ç‚er™à@d¯ÒM3
òù¤:æ§NßÌâŸ@2”ã®Cıîz+şóÑQ=/9ğŸ|¹¦’øj—TƒäE–E®ÿ4ûiQê¹Ëc;ˆ`µêZš¥ÓëØæÒ¹µoóøËït’<,´íw¹xŒ­Nû¸C¾5xÈĞ»ÛffêŸLj,‘ÄŠB›á_Ğ´?€×š.ƒ©¤ÇÅÇ«>ÃÚNX¹e\¼-ÌQ¹¿]¤ƒñjÑæ»Í2D4{wêt.vMá„y¯ŸsÃz(ìÅ.#˜*J$òuĞ¯ù]‹§x*²­²ë£3ur)ÊÏmmÿGÜÕXYø#N#°zåğK‚”&»^-ºsó~ÍÄN~L6îĞ#c|	ŒÑCî¨$À‚ƒø&x£â·N…\”’¿9_PªÖíkŒd§†Õ°3¯ÍÒ!»¹àÉT®ÉëEˆÖ?,Ó´éâûÁW'Pn–¦Æ4ò7ÑÙ?¹÷ä¬-AZ8BÉ°lú¿Xô(,äğËÜÔËÕªÔÂÊ½#-«VsŒ­qcÑ£{}¡äty£½J9ô¼’w²–+fº¹¬öÉŞ‰‹Òvˆ	À¶ª:‡É«5~ÎrQÛ_”R+Tn'ÍÈ‡ıµ]2âéÏJøã=ïâ×Û¤Û…Œ>Í,yî`ß¸ôÊîiç¢´é™°–ÚÅôÊÑM4¾Á†V‹='°`Ü}PPÏZ°Ä›—Ù$÷¯Ò‚â€Ú8šb6Ö¶™4.•Eò5Q÷4òxTÛKìd×s.­H6ç›èŠs&‚y©ÎW§
"¦–v~ÅMìŠå¬•ŸÄ]ZÏ¹iò™¹r6á=}¦˜Ö8Oj¤r:c]¥Lm¦k±ñ—cæ`«‘÷BI­Üù)©7¯ö•:á@BvŞÿH‡Aw¸µ e1}ƒNøÏY»ÃƒÆL÷"ÔY„µP°,Bé°QF+ìˆ*Ïgaè²­Ü*Eá`Pêƒ^Æ±_^²Œ‰ĞrAE˜q"˜Û5øÚŸ^¿œ1Ä ~Ôüeı=µ¨29Xâ™Vr,©õËnŞ‰{j é‘a Ğ])8ë¶Õ™½¸Òú;;ôpt0ÆL¹ÆœÏŠCB
¬‡ò0Qšj>qA>ƒBËÛK²Q‡‰LıF–|âÔrıAyV©x<Á'ï†'h§¯Û3Õ9ÍúÂ0è¢Ï ?<­áÌdH{&¿¦ÁYø!ägM¸á3ähkø9%şšrYTÌ&?UàzcqNTÈ9nÇ|ˆñ+ÊÍ9˜Š5¨?P½<z$Zãæ3‡CÄ©b3µ=_%[NÄnU™`m×ét÷#íjY¼$ñx¶îjÔ-k‰eu¤øË"m”Î‡š[×¢$W{‹í(¾jzNqŞ×9úöLrŸÛGUGUìU¨O+Ùo5ÜâªôèÛ¤ ÷ÿeM™Ãÿ°L6¡T5¸Z­ĞúKì*+GÓüZãB"‡Ï/°3 ìşú{äN‘Ì;—Á* æÑpïÔ¤n½bY!{Z´-æ ‘$¼„²qÔşXcò}øà|w;ıe]ÓÜ©×’‚ım?µíŒ	Ë\ŸüF<æ‡s%w‡½k¾	¿ú}Â¿‘-gI…‚Pd±oEÅ7±^ ÁØ×æHaõ(,`µg‡1z;»ù=^ğÔåÆ3h-‘'ª8, z éÁN°1§3Ä*PB?#jª®î7åZt­ *; :zç+Ó`NSo8©®ö–o-[P>ßŸ°–ÂåPh¸ªŒ¢9¾âp³Ó|/·CÇĞ}‘Î‹‘y†Ä¡‡Ù&uÁÍGÆ®v½Á/7ªğ1ªÒi¦ˆò“V±·«±Åb`—áğ0néeï‚2"ı°€mö¾l§”Y}ÀYdrGÅM˜â øiÏ¼ˆ—f3&øtöH˜­/è}œ¦( +)“ÊƒiZ˜.rõÉ¡ú]å+î@'3f£›Rğ³pDÚÏX¿!‹q4(*YgºJœ/~:S²q Ù|}×MN[Òøü¸£\8g5`YSµDğml½¢ŞK²nï]Ò–y&_2.%ÓpLÊj-q‚Âóbç›<Ã/Æ ÷ÙnÀ&HtäH}’_0VÇ¹Íš…ŸçfzG|Ğö~C”™DÁ?â1?ùuõ“	0ÙSE·ÃŸtbÉ±ò”ıô§c²Ü
êŒFOİÜóbÓrA£^_;¾áL¾]\¹¯`_Âöä¢"ÿGŠth™ÑĞÁx°µk@€ñŒŒñíS fÔÓïmBÇtÖ;²ú ô(6•tx·{õ³Ã>fÜ´È“¤õR½ù *ÿåŠ-²‘ºcÊÀ¿¸@úÏİUW_ÖZ¨Ú½‚šXå»Õ©©ã¿&²ûÉJŞÜW=ˆ·Çu‚Zwy€˜W¤tŒ§Âuşù.J"Ø‹ÔyLşi¶—íÕÙú#c!<¬—Éi
m`ìwó)}Ş’j^Ó^Bä/D¡ù [T€AÌ—æbáŞ‘·g`p¦f‘¯ê*è½f-ŠëiWRÉõ#ö1Fa0†¹8‘œ[-Dšè…PªÔ 7÷–¦áøXÖ)èªŠ!Ë¤kÊK4¯÷ÑÍÔ<=±ÑûÕ]”¶ì‹Òø ]£ŠGÔ…ˆNŠÙÉf,OÌJÔ¤‚°È·pïp»gÓ
·w(¹`=`†’Ù¾à5PÙ³úkœŞ÷£b\ó™“ôÈ9x“ä\SJ¤fëäËÌ‰ÎÅm.W]º=î}§ÎC–•h0rlRv67xÆRÚôD8l»ó‹”±*Ç‘`ÅPNn4YàÿaeÓƒú‡†ø¶›:}Ÿ@àÍ"ñÜÎ»~;¬pú%ß3÷E—É7Ò¡€£º:>‰G5Ãû</ùû)RK{ ÕñmqÈII£ñP5¹Ğñ$Ÿ“CBÆğv?0òÈëR$§RäÔQzÍQÒj×01ÿü¦ëïÍÛH0öâ}ï$½n=&°7F:<"|Lc†×‡’-ëñBn|[Ó3=Láçœ½ël3ÁïÌ{Ä}•0stÖW4£YÔ@ÌÎ5 Œ’`ô½º$µ¸¦4*P¦ò+ÈÓŒÖ¸DÃëã#KgøÏ<¨ˆĞa}¸¡veÓå”ÌìëßœQM¬ÔÇ¨FÍ3µùq{— ôÀ¶K" C>!l–"›òÍîÃ¨cïÉ6òasèPbgÜ5ÿöqL‘²=8óÃU4?
†¸¬\Ãèš9gjÆ¾·ù½­õŒ¼[*'[bPD”¸ÈäSµú—¤UÃ-ÚÂK‘Wq¬N@yq.“ñ¾fõâapú$Z½2V\óZ-¡¬dÊ¼ğLÄ$m
+\>È°$@E3a<ïìMŸ+´"—Y´uY‘Y~2‘‚Ò·‘ra½€UİX'}Ëq_sa±ù8È‰2†Ì§%ïe(:<] ¤½t33ÓèuG‚ÒĞaï oVN¥Á´S'oü‚uÍ´ÒXË¦›ºzwL åÓqM¬•óÀ¸Z×ßud<RK›L5.™r>ì>ìñ(ÔyçOĞ`†]»K1bŠeÆ¾`}yğ™n!ÈŸl2­)²ø¼›ß<¤)Õ£QÔš4¬Ñq­¨³ê
¬^{BYpWå=ù@3n÷ÁhÇÊ6;Êsnİ†ŒV£ZÀàêíıàn_¡³MWs­áù™J\¿%ÇDİ¹±tr–±»×}S±1í5ˆC1ù»ñ?¨á't”m ¹'ÃõˆTÂ°YÃe£jµ{J­°ÍQ—_‘úş"tIJ*ŞÑ¢Ri[ÀiëJìR¬ãµa]ak@]:.+{ùT€Ïiÿ$K7ö^»µ˜®sé®õmôdõºıšY¨†£GŒßƒË¥õ"˜û‹~aE¨¶ 5xòÈ(í…ıAU{şûøï­øñ‡2ydTÇ­r,E|u8|6-u¼:“}À‰™Çø†Ëî)xı8ai¢HarwÂñ7—
cÀ™X(ï…Îã	Ec‹ù«U6[óï“ÿä˜BHMçB¢zÁv0Ÿ	î¼ÂVãÚ rØj	Èy¨Öm\3³qh²{4VLşè{nŠ6 ¿Àœ{\qLÔğ?ášê–dVO®«›øşš}:,³&t0‘ÕÅ\lƒ`”
ˆÅ½2&nµ×MÊëq>Æev™,”Â=wµ«¥j'Ólô×:OeÑn×æ6)‰`é¯ê‡C7w&%*qCªÃ5à*óë¯“‡c¡¿ßÄwêbMÙĞàä¸™ĞN´>bOfµzQWS›ÁæË;êßÇvÂ1§¤u?H…hùZNÅïNce±›‘qªwŸè¨Ñ•¯u‡³jR„ÚKÙÕ· J]Nëß¨ñİ ²=LÊŒÔQÙ6]Œxû%€ø5ÙR±í“Ê<+ıÔ·[Pº\ÑLkŞ¥”
8yC¸àx9ìı±#~·/Å¥3z«¾OÎA>4]{Qó)¦.'+œ}u«K
x?U{oü€Ú9–ÚìXZ/F2åf7»f“çñ¢Ô!Ğbßh—"É°H6£î›¾vYÒD&’ëxºØò‘¾Ëš/ãÜv‡ñÜ]˜ì*ˆ˜â_&­+ÛÓÂ ÷‚ÎwÎº>¦lPp:K’9D*¹´qBvññye‹¶P¸8ÔÆ7^ò©0$Ê:ÆÙv÷0ì1Å¼83­ÄÛíOd™=­cs&_pPáÂ€óBl ¶Èä&¿ê3ëfí*İ–OÑØ;a²(şqS§©™2‡ÎpoÄâçÎk2D8>“¼Ä˜ÕU*ñ0`.Õ°ïUóO=¥Ë{À
‰’pqr~i3Á‚&óÌ·Y«&ICî&:iWr,7aâŠ«Äı†ôÃEµ8•¬$Óaä·ùR¹ÂGö—€ªë“µUdZß^Ü{`Æ‹œ«÷ÈËO5•…¾¯vüplò ,‘B}ôâÆv4¸Hª+Z$¾œx¸G7£»¯Y@å·ëı»ëî¥Tâ«· >¼VşX2Ÿ¶ÊÍ
Õ‰ô@‰=2“÷3 ÷ú´s…ÑÑÔµšßÛ¦%÷jWÒdÎ]a¶m÷zÑ&á÷ U›Iñ(ºıDØIª«z¬djúÏÏÊÒâ†r/.İürÄöôøk6g‡‡ñ¸‰…³
¹éU:¨B-xZàµ…hÎ5“ºÑ{‡xĞîZÏ½à»©$kSK;“®œjê"}†-›†UêÃöáÚ¥ÅÜ`I×´4D-n¾nèúaÔê±ÓT+³]³mJeUùºô¡6Hí‹ øfê­äÚ^If(¦%7¸AQ fŸá³T5½"ñsGgîÇ«â”©X^Np!À¡nÆûzÄXycÓi˜BjÕ°œ-óüÛÃ¤p¯oÜ9ïìEy¼ ª8Y/ü®0óäYMZ³Ü\4¡·SïEëjX¤Â2;u§:Ñlè –ÑpF`ù¡Øç²>–øT‡0Dßİ/roÌû)/\\9ĞÓ+‹”[¡úŸJnçuı Ğ™	›¢ŸÖ´MÒÂ00¨1®"T†T‚çıV;0BŸ>z"WS-ùÆ s©Z;ã¬vµÒñà›R(/içaˆ]“İ+ñ
´i’ Oû#ëGGy¨ø[h«?¤az¿½éH Ÿ9á±<gÂ­§3áÛXi-LríA™pÊá„2øÄÖ«~¾ ûR¿xşsø‚û+N,´Ü(j,Š„œK—ŸÄü¤òäUÎîªŠÄmAE„Ğ
ÀÆ
ú#ÙFRô$æíP*…ƒ(Ëœfgˆ ´Ô[7j
p3™ÿ¨}]Kş$ ‘z¬¿y­{Û°m=®¨e¹{+û¹–Š~3â6U=>÷E„ß™µŠ06
°P„ğ½Øwò2s·¢k€ã8#Ù£†]¤ù:¹ÃKA4‡æJ-›åŸ×P<yü‚aî¸+ÍrüV}©”™ı öK_«Jğ/ Aúİæ¬úŞBñèÅie;PÃğB~>çfM|ƒØµø^å”oánOĞTŸÛY˜§ñ,ùÈ˜¹©/—>)–«ÙÌh-UNŒcûÁÚé¦VHƒq;8ƒ¹\´«É\YƒİĞœÎ­bÁN»âÂ{ï¶{ÙÅ)‹†Aº•„@Ôœ[¿İ#±ZìhÚ0-9ÖºDOAçeİkàĞ×ò]¯—Gr»¨$
ÒÅTÆs»èIe»&ó«1™‡ÅuË‰¸jc¢8Šd¾hŞÔ|{8I¦5P–·Ö½¶!×iVÀhu¸ÌtÊ2“G³İ5ÌÕë›f‰Îâ€ágîğ‘¹Õàúô-£	ã/·±B‚Vvz o+#™Õz'NPì¤¿tàùbâŞòs/õâ¯jG[uvi\Åà—¸(n®Å«Şo\§{Gs™ºúŒÁ¾~÷9Ò³a»OA°×è)Ø,ÚíÒœ,İ»‹)VÚ¬³Ò¹ƒnÓ?U\Õ™Q««8¨¨ö~uMúöJ…mÓN	5+Ñ×A“éÜ^åıÖl’?‘Ğ»ïÚDØRİ²vàõƒ™2Í#aßæDõòFPŒû¤-D¦kc–¯KA7¢ÑòDÔ0ïsÎN©)q±›’²…:¿"++…vq"å¥É:ßû„ËÌòõÛ2déP»ˆÑd@r¹c§æ@m1ŠÅGù,ßw[Åa-s2=«‹¶ƒ³j4…­‹f—<lÁ¦¯Ÿ”MJÃªrø{¼p¯Õºb³5¾/á«>h‡Ø{ØÇK  >	I¨ZUĞRÑ”½ÔNù¡a¯•ã^ò3n‰¹Óşøœ"'ÀB«é³¤°7•©llAêÉ…N³º1­øO="q’±¿¿p®8WùoW^«õ¶âaC¥oŠ¨\Ø6\2|?”€½XËÛ•YšV÷Ãß6âDâó)ÛPÙDñ<nï!BVŠÚê—W×‰){!uÂB„ÉWVüö¨Œÿ£ûa4IZÅY&UMğ}œ/»fjD;òÈDVaÅ¥>÷¤F,ËÍæ§En	oW¡R~R!ª[¬ivêB½‘ı*lw.¿9#ÕL.ªÉW¬"Å‘º7Ñ×Æ d¸ OS”WEuáß¢Êc!SöxvK¹&»l€&¬ˆM»7‘GSPEèé…ŠÌJœU¾…å›¿à¡ÿÒM®·czÒ8ÓÑ{p_S;ã9“Á{#8Ä Œ°§˜.9…ŸE]éİß•”şÿ¹ZQírX¯ª†àßŒÔJE´øô¶ş²[Y•PëTÎNe3&Xî9‰¢áW™E¶ŞfŸ¿©=Çe÷{VØˆZTd el…GMˆhm]œµN5Ì˜Gíj7iëÄeÄh¿=”Â¼ç¨µ‡˜[ÈjÊVÇ3thH]­íÉdiuF€àe=yå.3o_4XÇCN4“¨ã³wü mKv”Ö;øñB<SWj “[ÓbÊvujõ‰­C~^eXh¾H %(>–ê
:B5à ÅRğø€ñ¨Ñ000§2ìwÌÅ©­BtÑèc±N,Á œ_Iİ$­Y8¢QF4¤L¸i(À;aØ"MbÆÿIT›÷}^q"¸jâ¦-Ù®œT¢2Ò)Â°{¢íÎ«á»Î‘'º_ƒpq%ïå—&„¶~‡+Ü>	Öó”WÙN
 º¼àÒ€`?zÃ‚ŸwûÕş»ÌtQƒNîü„¶yÂŒ.ŒNœlL7G¬ÍıŞE4ÈeU’ãi~?y	c²[²&±…ô3˜¦{¡V¤Ïà›N’¯ş@eô«|‘-"êÇqg÷=’{@ä¾¡eF`:¯ê ïÄ¾tªQZ\=)h­ÂŞZú¡ØX"Ş<³ßâZM¿·!-°íEmM¼T6*‹>1¹Ù\$>ÊuB”EÌÂf=Š3A)ØÜIÒœ;'2øqŠèeUrÒ7ÏøÏ\3Z"ÖØ8HØN¼œuSAGàtÔ¦zRí“Ó¡,^Œ›V&²%IÀoñØşû´¿ \„Œøˆ.1ÈÑª¸>áÓ&•z ‰5aHÆîHHçÄÌ{ÅEÀ5{ÍÊ*ÕoÂ,Hº@lóv¬ó	ì¯œß?Š	DC‘w÷!ªüÓ–ßÒºj~?Ÿ÷“Rë„D.˜¼IKÕ‚BLxO&F®œôÃ›ÆkşÄÖ%Î¨.DQg-ÕPµÆÒ³ÓeqH(Gîü’Æ'y<ÀnLíõ÷'WŞJÏWD!ûLDwÄ‚âk˜¥¨êá;òÌşûƒ·uNeT’Êåb¨ÅpŸ^ZÓ¾EÚ®wS‹Ì•ÏŸÆçı8aZ†º"B“ÔCGøO)£¥ˆ8ı\oÊ`Î=e4˜ŒÒK#]/„EKhm’DâDåká.M{uDşÙ Ø	^ÇT ®ÉYÉÇ1 OòÍd¢¤¼qtõĞ«ºN8Ãr1œ"ìÁãâç!aÚæ#Rkƒm£«| û$&Îc‰OyH-N/djaµòmw×áÂˆ«h*¹ŠAöŞß7@õ2jóY³„İğ`£"•ï?‡¿ı3Ëe®éf
E½: iTÿ UAÛzâ“äºäqÍ®?™şìQÒË|‚úÇCÀ‰oU«åıĞÌ»«R>ã/+ÉbáWç2]©ÉêiO´è%ärÑ„).ÊIÔ«©KPI½ğÛ³ßóOj¨àûó(tÂQÂÅ¨åŒÎˆçŸu%èà^6SMòÄİÄqç¥R“Y?aÚÆ–LÁ‹elŸ–û™l¯3qînÜ†ˆ°c¯Kíw¿:½ÓË2ì¦ß|ÇJpğê1²Qï(	§çÍòÍÕÂPƒèFl7ë¼\ËBŒK³íğd4_·;_¹¬n/‹<¢OÆÔÑt5‡¿RX oJ$˜ŞX‰:1év|v~„:2•b£“Ó—lkëİÍAëµâ2–ºßeê&¬ì;Q}íS‚§ç9©èÍc3Ëî™Ö™ÇøluhAÇr©Dİ‚Î|_î½}â„ù+?Ná‘ <^à\ÿBŒ®–¨ê¹Ì®Ší½ÉK„¼JÊ$—»‹çÈU{šä¢ƒs3(m{m;Ğ­ü•È'Í]éqNj6;c»Ç*óÉ‹C­„#©_Çb¯ R4‹"¥…]ş‘¦K#¼—›:êænMrëâ›é¿Õ·eœ}DÔkıIeÛŠúø9‡òî:ìû~Ü`L+Ê07\­UKïx†•¥ ¼ÑhI­wîÁïH§I«ÖX'B°Ø°„Q'ÖÁ¦‚ÚÌÈÕâ&Ú„Vw.F-ĞÇÖjCu’úğ}uœçúû]§/È'åú¬¶ÀËô‡|$NDX
'æ2™;”G6áßzJ{´ˆŒ¯Z¥c@´_á‚ášÚöÆ¾&Ø|Mêí§Â'*lü÷àsâØ“3I”Ìª†q%Êì0‚>\*ÉådmóÓAÒ˜<M¥¥]îWdkˆ'\iŞ¸!xş=/mê7+Eƒ‡ZüzzıLÒ.Çñz”d]Àòàg!T-]^pU®ÈV´—ãV‰8^]O‚ö]&{d\÷ÍIØç›ÖÂ×r{`VŒ‡u¶€±¦ªËÈÅÁ-•²UüxÎR[i!pUª vì	~]u
,~Ì>­,5îa(lÛãÇy '‡Ê\<û²gŸù°kZ§…Œ@ƒÌ‘=Ç’P†êúÜH1ğĞÕ¡()‘–ı^ÌKh€™!…³¶diö#úSµÂş6ÃË/ı>†›s b“-IsV¥Y1ò
Ûã±Ò¬˜ÃŞóŠ¾5·dUWAù¿}ã¤sò‚†#2!ãlEö–»_K0"OR]âÁğÒ6=a.gsPVL'ïàTqv)b¥I±\g†Ÿ6
á›@DàQ¦xÉ{G~ºCÌ½,¹êXK±–áøß7D¯n|7§skÇ4&­jíBóÎâ³zÉó˜Æ§X8£Ö®*˜”o– ¶KĞ¶"Ş#œ—¦úoĞ²›xXpx7wˆ¢¿³ÑäDQpâÁI°ĞÆ=m47¦væ6$M×Ğ¤V<Ÿ”“ñP…„„lHuà2íYîÏáğ:ÑÓ5É¦‡Ş4bä+gøë"^çtJç:±Zc¡£füó7ú5I-ïR/Ã-œpäqÓĞ'eş[÷¡Ûƒ>¦¯İ7Ô±Ö­oòUÌ_zlâµ½éÙ£*)7±a™’¸¾éo»
İuÌjwâÓí¹t‘ØsçUpÖµŸÚ< sì­è+Úwtò-²ô
}Û¶%ÿ„§Öû^z¿Ãõ”Ä$ô‰©v$ap§´ƒ0E*±§(ôªƒ‰÷QÆ*¹¡ïÑ‚yvòá¶*›¡™t·@gäaiky:" ÷&Áøb•ª¸ ¤Æšó¢’V<q (aï>º@ê˜¥ëè‰'6)<«5á‰aÔSûGgjg6,_ı€˜°ëlPÙ{™=+‰¾5(A<bv­øèÀAc¢×pÃ…?é±ÏY™Ù
V¦YNX>§Â¨¿lóÚ³owÎÂD].Ô<ÁÍsØµ¥ŸÊEÔ§ï?`Qa‘„ÍnŒ
ç$ÍwÙh£Ú§«°ïB&sW…[·¸°Ñ½làsç!¤¶œ¾dàJ†£[·Ûÿ¤­#èHß^‹ãÿeÂaº{s<!	Â&˜„ps¤²$,{Õm’Õ¸13Vëˆ—ö×ú‡p?·”u·^«€o|,êz¢¸šiÁO6	ˆİÏ=§MI±Û0Œm3éòó‚Q-Œ­!<Ç'Ã¬ÚßA‡ıĞŞlm~AwBÌ5ğ/rÅucÚt¹ÜŠià–áƒ—ì]ú‰ıC¡¯Œ*Õ0FnÑúE„}‡@„õÓôI2É"ÛÓK”kqİå}üúmÈ ³áóW«ÓüééRIk¶¹ëÀ‘DÁŞ¹tüdUyNÉ¡AS-|ñåM¡n0Íµ6~œM/ûY
°)³éÿcL¸Â¼¶M´¨¹¶'o:q)Š‰Z‡Ÿ¼ğA³éKšR…Ìv,yö]Á^Œ¾8?MßĞŞƒÌEÔHÓ3õkœ—[>¼¨†h(0VÍò=Œ2j'“»õ­Tõ³T£ü–âPÒÈ‹1–‰p`ÆÈ¡UÄ"“§[êß¡³¦ÎtW„5f(
1EGx9“.]]AJÃ4Í¸CGÒıØ’øõ–É˜@æ<)â¡±«%Å«ªÉº*,+úİ(©–æGÄ°&Õyç±÷%·ü
à0 øÅú$4ˆ'¿€áôœÇŠsòŒ˜=Á›{"‰cúQñ.R¾§àGúZµy«5wˆ ÉCˆd´`×v›æôì"1¬Qİ¬óÁwÖhÌÈ.g{ÀK÷píìˆñPIÏgg-‚2–Q©P®F]Äˆ šà‡Ÿ‚ÀhÔ@aêÿjÜ(úIµñ ·îÌ%wüşjŒ	†Wz°JÇqŸx<|Pgq¾r‰®OXMK
ñ1ñ,Şñ*¯ÎP¬±®Şw¨ôÅ¥°+kŸ•Ì4†;lŞL‡zclöµâ¡ £p-:N+§.ü
Í¶jÏ]NK$&Zç²TˆF“é&#eD‚K—‘å½s¸µ`ÎPGÅÜê‘]G¸­È%ïªåEmÒµ„ÅLà<?å°•‰ÂšSéÒt¹S,ñeÛïæ.~D²/Ó°¥‰Ÿ~ºÒŠ³®âM²PQµP‹¥6.³5!&OHøœ·³ş#ZèÜàßÍ;­^ü!yáªÔ£’â÷PµCù‚–‘çMxœ­ûºùH¨m‚‹)è«˜À^ZùCëx6V•¯Ër	]9æ\gCº Ç5™œÏÓä¼ÁKÃtP?öğsîjÇş¿(³úF6.ˆß*æ ¾7‰ûÕyğf³ıˆ½İUp BÂuÀÌ‡t„ÍÓøŠsˆ@xFï©-J®Akõ„6•YóÈ+óŒáìûŒ¿£´ÃOî5oj‰ŠxgöøT—;;¹.´‹«"ôT¾"’ç&Òßv(-Ô1îõí;²Sá—!Ü§?jB¸ea`W°”cX“¼®)I>YÒ#ƒN[XEI¤#aƒşcR¼uf#iÑŞÓÚC/Ä[_†­#{’;‡ÑäĞ&"%ö¸[¾»E%UQhÔWo
æŸ’5"ÀX7Cıu¬ó6+¢æzôŠ/kÈ`€Má~™
÷Ayß®TàSoWwc…ÔÎ?xn<jñv‡]7§Dè@»këø`+…”2C9ù0z¹ùX°'Â8WùE¥'£‚\+f›Õ‘mºsÓ¶uxáØ¹õ †»Ïs)ÂsÄì¸'ÃågUîDH›„}Ø£ıÙŒcQ“ş"ÕäæŠI1-D‘Èô
OÿZ6ï©?`Øl.àìî19Ê±ÉŸ9°šq¡Óš”oØ¢¯¼†Å¦øxsa~ xAw…g44ª¬ã…KPÊÑ”vi!Pda££H×]N:ı!¸åœ–ÀM)æĞ1c£L@šM˜šïÈTĞ|èíxJkŸ™6éıiCû[E	]á$s^PÊåQß"éšmÓ«äf„pãÅ›5Lp«›0Ì£
²•´ËùS¸t;b„uÂH!DQ‹–µ‘VÀ¦÷«ìC›øÆ8äx÷Q [¶Âwµâ² @ôùîµ/æœ©]{­+[(\¸é6¨Â(‹¼c×GE0[$k¤m5c\I,*ïfO‚|;ñÎrspèaó¾dU3z'!]Î‘BÖKœña÷)®¨?+ [”1R9-ägx¯	wÆ?`ïG*†iüóÈ±Œ£uz‡ØC‰EìÒ}=vßñœ²“lÊ¾«m4‡ÅQâ÷TqN3Z˜,*&â~ˆ³².äP•7ä‰U&Í•Ÿ;œ-$8^ão`Ò…ë¤)MÛã!üÒs'd2n|*Øz¦÷­^n xùÏK’œÎ“5ÚâmF)@…`Ï©HÚb ]•’ìób“ö›0ÖqÜ5Şqí¡!Ó7HgKêƒ3V±£áü˜v>%Ü!»:óºŒ®0ËDŸ(é,¦€Qˆ-ÍTÂú3šª›”+'béÿ™}gÈå"­èæ	›! fO|Ooğ@éô…Ê…=ƒÑ!¼ç²"²ÅdUÀßÂÊ67ƒµy1µÇ¦ğõ+zúœD B¸S4r!¬ô'L©(Ï¸FúÒßHƒt0¢Q0³kÄ	Ê
Qß7—s…½n¹#Dÿ à‡’İŠøÇï»ô*k¦Hb@°ÒÇQ5¨Ñƒ95ŞMcÎdn$LBö	+ `Ì#“­?†Ù°8´¹Å©z°0=|$ã»šÇNh&pÄ¦17Uş´İ»9Æ 	ß,7>÷ı²iôG8*Üh÷ó' fÂÜEõ µ¡`Îd0Œï·‚Tk>øGÕÂ5¿“•ÑNg±µŸ?ü†õlŞT0U:6'’$Ñ˜ÿ<¥Ò§ú9påq® Ò P¸~ÙJü“ãÎK˜ŒßäÜ6Ç´<(æ:…äFDËU¦PiÖÀ~¹¤,}pX²”ÉÆ:"Ôèğ !ÒŸŞ×ÜW'‚HSÒ÷Nó]ÓŞëUô™!µè”äË×é—I§ª	0?«›­1Æ#Hÿ÷|Ğîë²×g³ìDCÕŞÓ@ñT~Ò…­ `’c¯Í?Cı±’›pBÔ‘}“ %7WóÚ(šK¸@¡yµ,x”®	`7¸¹Dl®i
Tµ÷—ü
ş¥l,™{}şuÛÄÉWîë:À(ásñÄ/öË<<¼ã_B'µÀì²¡iVv‘;Ú7Á_¿,l÷~<+A™»1²³ËşãW4>ÍgG¦+I·ÙÇOşg*ßRk®Rh^œÓtj‹hİ±H¿øb{cfµ¬òÃ*Ø±‰øRÁ§ó×¦Ôg26Vy1ÓÙ´ÿŞ×ågğï]’Ácİ…YPòBEµi&M£ä»
·KJbbBı¢@ú%õÍ0—¤ºthBÆùƒÖû¦
Õof’ä2xƒBƒÁFîOê†­‡!êºxÉ!è°. ‹›±&:õ-„¸Bæ¨m(éô~l÷¶Ö–¾šx<¯#}„D/Y¦[»ŒÅ)ø¦ôÒ¼F`÷`ø«Ã+jf[—”`Ÿá°[©BËÒ%r°Yj4€\ù¢®~w˜(c<E‹îª#W¾5u¢Tà–x†Hæ¡…§éìïbğbÖu˜­øµŞ­Ÿ		].ñ?ˆxî¥o›ğÇ:òº0Ë^ ŒÄ•h†	KÉi[É¶Ş/8ú°pu`  İ@¸=½¦‡«áic ×8â	+¼ÿÇqvà×í}îÕtbuÀÿQšŸÀ9#¹“Ø3³ï ¾<ÖƒXLñægd8U~ÑÑÔğä1Ş]€:¼BÏ}'&¶ê)Ş©óÅaı'dÎ
L;”]’h|…è6ovü­Cø1Â¶}Nw&Ët•…¹…ÚÊ]è½Åãá'H@ oY?Ì$c|ï¥Sãbç[ÿ`mêU/è&Ô‚ôÍínÈ¸m§ÜŞ,F‚ucş}ğc)ò»Õæ’Ÿä¬;¢è	›\†cIUÇ÷İ
Tq!Û ŞœûBÚ‰;Q4²š‡“s¾P
Ã£=mWÏözoÔ¤H'|ÙìÅyˆZÃïs”\ŠE³.½Lo8™äTM;”-qU!y7O›H£!Zdu™îmˆ÷0¯g³&~†ü.Z=|ô»‰e¬¦â—î¹ùÔJ„i˜£Ä^j=wÔ¥d"¬…ÓŸ{cŠƒCŒrd€5XÓË‡Çˆ¼Áp-%óg*Tš{R\cÑ7oJ—™Öê1[ïğ}±n±o2×ÈÖ‹¥h‘	›±÷ŸÏØ°`Í±üÎ.|˜›hÁ
`İG.´±L
šÙYXîİÚÏé§ºñ2¹n™…Ö0ù®#ª‹èœhc%uŠëØÒ)'vWWeÖõ}FÂ'ZEô¡î>ã ÛÖf”]Ñ!İ<«cÏÏ˜`œî¹c˜0ÕÖ4T|B92zÓ>ÓÎ•×9qÜ^…LÌµç‘!÷×ÿò‰êZsç®Ä€¸¾Îº ÄÂ—waW_$s÷™I‰ìV«ƒú‹éĞonu+‚Me¢mOp¶„–”5#‘á4ä®Ê3`3*²Î4À9X‘?œ#)«BãÑßÜ?ªGí?3`ŞZà Å‘,e°è¡¤¡¦=>à…´i'À±Ãkıâ”şZá|™}ÊU‘ŒèÇ²^Ù¢Öµ=¼£rø†öÊp. _AâÁ‚4î ²xôWY~lªçşŞ‘Ï“C¤.’!y9õ¤+(7_ÃMGt›È
.â+ë|Ä‰=)©>LDíQh¹”G'×WGÄã!OpŠ|ÜÄPç­(şœğmKËÉëÜn\]Fx3ÜRØRÄlêLëşêd˜îºA—…)Eqi±æËX.™»¤/ÔQãƒWrõí›Ê×oß|Ù(eºhÎœòİXõ:tDà÷^äˆE³%¶>q¹­âš¼/)Äı6Ù‘ÇÀ­¹«U€Àm¸÷¸ë+8ÒæW±!’{‘7¼5y+97…í·^oˆaÛBìT84ı’õÃø³ĞfüQ8õö¥³Ó¬Íôû´×e
Å‹‰.ÌÌ.TsÔŸQíu	,:¼0|ñRVöşJ?ÇïÏ PËnà•ıc¡Ò>ç5,aI§–>:Y^ßSğ­p¾˜Û£ÿĞö~Û#@ä—×ê¤IM”ÈÔ™Ë÷­=¨6UMé[«Viâ‚ÇHy} Ù"¥Ÿ3 ^œ
îŒ¼¯íNí?IÈVÖ?·;Ù/'“¶,Z~BìS…/YCêååg¢ÑJ)lä›9éç¼ ‡¶ßĞŒ¨ ¢^^ë±b‘ût§}ÿ³S\³¼oq«ùÏ%J¬Es?XÏ/Z ÛÂaÈŒF”šÂàÛÑr€¡ş¶ «¤ÇåoÊyCl'uY§ı=·%Î§´©éjßHugÌÔ<S	ÀŸ9©T®aÅØf=f aÄF¢q/·{Ù•÷=qÒÆ/şÔN­GdK%™¸âæDm­÷3åâ±¨é¸vŒt‘èãe
1†µÊiŸ^L¶*>q™‡ÏÃ¯â
|ö"Uê:-ŒNÿ…öhmuå@ç6ÙÆLÒ7XúËdi#-Ba;ö‘#1¨ÅdÈ€]€¡ó“f¯v*oİ”ñ	İtDÈğŠƒSÆ@ÎŞîİånš»‹v¸(ÙCŸ¯ó!ëÙ¶Û‹ÄóÛkq+ó[z(ÁR ë×Ùòt'ıØ¾‘Úp’â¹×ËàgÌ«ª”T°ÖØKz6wÑ‰5™ù]§éÓ{¾"U©€­è]á£‰Ñ@ ëH”Ş±‹=¡vãäšæcÚ†ôó-¶´Ú0)S¾As‰ğl>Ùâ¼%‹F1ñ¾‹,=Cdù|!llS6^`Æ^¼G~ºX°KÌOrˆªÁ¬ØCz§r [FvñKÑsÖÌi×ÅŠ:S‚huVLéì6ÈÅ†F"bS¦÷ˆzKú$´õx¬,©üÇòò_$eÜ½ÑµÎ_]pèâr4n[s(’­5Q§0›{È@£lŞš7—_O»wÓ¦÷±´½Zäõ¦!şWxÚ™–±Ğôäs?v¬ö·_ ÜX-ëê›çZçv_`ú¿¬dì%lg|ØL‹&Ìa˜®;£1İiÁ™õ\À$îXR°`8>C¼a_d/-'·Eyzhq ı'ÏpûŸâ´$FŒ†D¢Mck‹4Ñ˜C+„ó2±]€R‘QÏ¡Hd¾W›WêyDV‚ºè®İËl=¤9³’u]nÂÕÕ®5D…¼¸Â7fœl.Ğ|³Y˜nMVçEU½2Ë2RÍÉ6N )ø ¡U2UÔ1Ll‘6m	ôI“Ç!¼BS4Ë¼¸ú‡‡‡;ßÌ&_æî0
]½‹ù›,êIth'ãz÷±M
ÃãÒfºìŸ•ÂÍ(‡|ÀhÒò¾¯” J´ÒK¬ÛeûÃ˜\2"'¥ü`TAq´:ag[¢Üjê¢/Úón’èß’ÅıÒ“fù¢]öÔ¨Sv/²şÓOb:\î} ÜO-VÇ3âÕŞWEQT„¤7"$²Î Ï Rd	˜àÆOJò<v„¢Û`Ë}ƒ¯ÛNïx&í™ªÍÊs2«õ{¤å)`jg„{Z(Á–U'Å:1'É÷rYQX›…‰6±‹`Ó¶´bæ£ài¢„ko(Ëüb´kâóQcêCB]oÍ[çÄz¿e›—iø„£¹Á$ùĞìÆO$q«Ñ¨Rİ…çşÇs×ÕÃwš€AÇ,â7{ÕìOƒò29lÆGUì“?@}ïxn<ğ.Ÿ™¤“§;¡Õ†şÆ•=µî–Ãd˜Úã°*˜Ø§-ÑÄ?õµ®_ì6éƒ;üI¥–«l¦‚Ôax1É›ZÃ^>¼‚)ˆÃœÏ»·ÖöU]syĞkkôk\cÈ½6¤÷ÍIâ$€Eº„H±€¢ß*zÃ|¡b¦ÎánA¥­¥¿Û5C±¶ˆµGÑô—šÑõaÏM`…ëy±LÈ;'ü?äºÑD†jeÍy4>ÚİyçËCÏ™CkÅÁÀ‰j±Fşá/Ó%’ˆ/³ë?UÁ5'ûúPİEnÆY³¡{g
¹RwnÃ!+¯Üç¨Ö/œ—2wRg–ßğVqÃáyŒÖÍfPYN·ŒÛmybÎüoju ’¢‘^rææƒË¥õù’İéş¬Ş—Ş¤J\*FÑkß9¢Îb§rñß&é•r=tÇ´@¼r”i½öæJ>f7PVé3£–MI:LˆmiC…tÛ(píğ¸·-V–u¥&}4<e¨JIë¡íòÄÃO-Éóğ¥k‰$L´qËSKÑ…ÏS)!ÔÛáozFáªT5g ÎòæBÑ8À	an)Dõšpœ+ÅTîÿ±(¿˜!D‰J¼Ì]ibìE°eà®¨À\çKªğ/vmàN–ŒO‡]†ˆxÇ ıËØíÔVÃlZ:ê=ËXÄŞaád‰§“‘‰ªy6Ş(€¦=µ"òWwcµ&¸Cu@†z\Õ3Bl†N×h?§|ƒ¼8…'•6ògY;†£Âƒ ¯;'³0çDßçB5¼á±‡ÿí¯5Õ	€¯ü‚İÌ~ÅhQëK„œ‰…WBÓ¯uÚmãù’&Ğñ1in÷r]Ù¡Ø»3é³1íß­†é0{9lN‚™åó^{]%,Q×€<˜ÃºWèlÕD˜¾—ë:Îû’§èÛje»sdÑW¡wKÙh~FİŸt   ˆ3%‰td  â¢€ğÏšh6±Ägû    YZ