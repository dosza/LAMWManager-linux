#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3599864335"
MD5="24cf4ee885248ea7c9e1f61e45d13e69"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23580"
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
	echo Date of packaging: Sat Aug 21 15:34:46 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ[Û] ¼}•À1Dd]‡Á›PætİD÷EËôüÌÖß¾U:N‰y¢ {†ç ®¤\–9ˆ " ówXØCYëª¤ÔüÏõ»ÛøÎªRäşt`ÕM‹)lÓòˆÉèà«§•vK úq&
ğÍ«ºKÒ¢»Şm¤—h¿½ää ²™¼ûDÂ“•#ŸG¢±`V<®ûÅõ­~dßSa¹»b!ÀF¥j¶ñ„µXj”næ[q¥d[!ı˜Ìñ°ÖtvÏ›G‘‚¹\Jót)Aı¥İ>UJÁŞŞF7¹q˜eøG_RÎğD`»¯s”ÿşEËTÚŸ~²J‹ôàøD‚kİiiÆÚaA¸l–Ùw÷ğ&ÚQóå2¤6>ón‚Dğ‡÷ªæŠtÊHRóâÛ?÷—«¼¡åÉ®‚ ÂâÌ5$¿·Ñ«Ü?øwm^jTÊºd¨2ÌŒÆc±õğWw|‹Ù!³[†?›M½¼¾‡ñk1#T´À0	‹ë=6°8ĞôÛæN¸_“*ĞõèGrËæœ?Î1ò÷—ÍË-ºæ-ùgWË6;¥uÔŒ¯2ÑÜyÑu;jNÒ×æVæ¼êÓwì\ø4ƒáô]Ò“&k'ÍQß°±}EˆğG5~s/Õ,ëvt¹*$üĞ=× Û1BfÄ-†Ø#KFıöI¼…§<8CÍ„ñY¾ÂaŠ
¡ÏDÆf~ê4 ™×°Z•­ÿ|ÅO—›1ø¬‰5ì#yŠñ•	¶æV Ñù4å°e§Rä¸,Ây¡Õq³ÌëwRÊ¦ÒC£-Z¡òK¸–'ZáíòÃãßPfê ¬‡ÿ½A7T(0TŞYƒ~`€^wd:Ü#q›áÇa7Ù ÜrP©A£·@	ÊsÂeÛ}š‘<¬¤á²‹†%3N)D~#eÕV˜Ææ7…¥Zî½{:Ÿÿ„i1=ñ¿Ù#¼5­Å¶°©†Œá4¯À°µ68r1§£şvR¾ñU¼ÿşnü#æà¶çtĞ1—b»u54üO8Á·lĞC½a¬süšÍ	zdšÔ¨‘*qB¿€Kf¤MŠ¯Y¸ùÓog“Àp„u²ÄWLF)[<2§Š*gxÛdC®ËÃƒÇ®dÉyÂ®+®ğ¥LşÆÛF[úO|â$›ï o(é•Î7×SÌ­Vízƒ6ÏÛãÿÎÆ;Ñ8$c¹¦A\`‘öe':éBX\Íoàí®ç±_aTèl‚r•_u${İôya¤Fîj}ùá§XÜ·J7%ÇbW§<I?÷p:¤ƒZ|€#´ïë¡vTS"HÙÙpºb<(Ñ>ZD\Ø–¥c/œ›öCÖc‚óÂ0ÓCãïˆyN¯œ¬ŒHÁrU PW,$ı=Â5ˆ¥îjÊe^Å,sLG4œQşË’ø&rÀæPáâ·W0M9¯âXô•‡Næbt¬ yµ7W 0·¶Ó™XpK z.émçVô¬º!òœÍ6O0êåÿQkËk§T$E¡ñM·ù/˜•¹…¦®3ş²û¡ÏşkXR;™<ÑÔL
75®¥èqAdàQûJ{¯äLÑTœ_9@ÀşäüQM•1â“iñcÉi18µãZàDB7Ò…“åÀÀ_]-z	:zğÕ<€š¢R7o ^kzµĞ9Ğ±ÈèT-ÒKõÈnoÉÍï#4ı|Î(w<ÁŞÂEÓ¦2ÒÿéFÂ]~º¬.íZ1")Š7ó|_Aºd•}øÃËs2ªIg%ZØèºLÂ‰Ù+óÉ²®>¥Ÿ!Â=$=.şë¾³èÜºuÙÇCT9›ç|Pb·cp ;<út™²2è|Ş£½$ÃY6ˆ±Â|n½¿œ}íÎA³ã_÷êê’*Ó¹áSàM3†CÈå)ğ6´Ó„#+`±ùAEííŸ,uŒ ğœfÇæ¤)Òç í:è­}CªÇµİâÔ-#öŸÃ­zV•î¤WÖÁiÇKén[Šõ%&é¢*Èsâ6üØd”¿ì¾ûâRËäŞ“wIF;6tyæ7Bw¦EF9k\ãY'ª]¾Ş0_Õíİly0Æ‚c,¢2/xkóq­uHÚÆÜ¢fÚ]Ûl	M-0ñèÕ5Îeª¯çš
Åx÷]wyİÍu	¼ÕÆ¾>ëê~dHj(Ğ¤4sØ¸ÕOšœtIH§²/Ku,Ğ†ğÇ†‰± b“KI?İB£…`:²øœûº†Àšì¨ûˆ3%±8nÌ
3Jw#€›V-IÔ/ã'^~=ªUF/¦gßÄ…ûºúŸï“~M9mµ<XD	¼Ä´¯ƒŒ0‚lªaÿnÑ©X§5^Ej¯KˆÔ©“	?5\'0}nÅ¿àÃQ¯€IA‹ï‰W,D'C5’¦…›¬[âL|¢ ˜6$?{ƒ¡S„_!qñ¢ÆFKH¡¨ÈtËhGhï5?Ù‡¹¼İ öõ¡­¬.œd=bÙ&×‘s‹……¹6»ÅpÂšvÄ1¤2›9ÂÎğåGca¬-ôº€7Aókği8eûßTÓ¢fæ¿µúM[·‚¡Æ¨ºvÓB“­VéØv#mùÖ€ì¾jÌ¼Ìè}0O¾)*ô£%kÀÃ„}‰—,Q;¿«…ç(X¥@è×‘•„Ğ˜¡±)'wuSìşì·ÕÿrkÙCO§ÂY˜vœc‡U‡èµâ²ï%ÁüÒT)ò)EÆ,z,>ñ/D¾c
eãĞ3=˜0–ø‘ıp©Èÿ«±Ç€•öÊÏ`Tµ({ïzì‘1¢v
ÖJÜ^PÈú¤¬¸r	è7£YAcÔä£_ÉvŞÜ­^î¡½òğVáç/c’bP™O«wdYíÅOy¹CaÈÂß	&Ÿ^ÅjÎGlhû·AUÚøy¯îÚÔÒv€Ñ—?£Boiÿ‚	™)†ãÏï|:Œ>¼··rú¸‹·ÓO‡Ñ?Ô
·\î6 ßFã»ÑP!³ä>Ã*[sEÿÙ»t$„áa;+ÀYzŠj¼˜0wë]éÄùœ7 kù¿ÌD³‰”"¿ø©ì²¡½JzêØ¸Bã©Š¬;ªg`YDşäé 0^¶Ù|½AITŞ³s‰£Ğ. À(i^rÛ$Ñ6Êˆê¦qsì]C†iEg‹‹€|Y&‰yo±¿Ü†>N†à\ÕÁlJöÆŒ«šÏ1±C ƒ)ì|iä~²
êR¤`SÊæó€XÇ\§hGníGê=ğïüÉ"Qb•Šõ`!HFºÒ_•ËS'l.i<ê›è4#34Ó¶‚IäùX>çÖ7 ¯¥AvÆo˜W5µQŸ ¶×zKrƒfø.”ºrírp+¹òÿ¬(Šè?qÂ%Q2¸'8 _y2½Æ,Å³íõ¼„“®°t˜˜ßÇ|[ÙV¬ü…'÷9Íçóó=ˆÓÏ³p©c@ ÑYáĞJ0"Ş±³P…ÿu:cc(ğEáY5ó},98>¼ùâGÆ*°Cr`‡¢X'«T AæÿRO6\ôÊ%Úìp­sXß~|[è(Ï°Í·en¾–§ïTa<(«wU¿úIÛ½uY´Ÿ_ İ®è8¥¡T]
'ƒ—À5'¯}ó¥	{@_»%†ëš®òtççâAÜêqÇyÔİL»wÛñ×2÷(2»á±»à*F¾³~A¿ÎÈşìH™#œ™sĞ¡”ë¾ouÔoò»—Òœ6éB±!&İşdU¬«8İ8Qsˆíçáád’û·IRmŞ°)Ô†Ó]‰µ4¬ZYRØé ‡ n8„Ï5]şFhp¾İY0Oe]¾¡\8L[n®ÕwîîL„ÿB8}t  üà(T|…à·„Wİ§9l,ì¯²OÄš\É@¨VÛÎ ¯ÈÒ9~¹º|ŒáëÄ©vÛd“8õï€X­×šZQŠì—J˜§I¾´T#¬89Ç1•'0«i =lûÔ­ÅÃó’Uş™/WMÚ£Ş”äÉâoÏ¿Ì_Ê„şrt‡ğ	j‘¼OQ`b‡Äšƒvtq:¥Íë_ˆ•'‡qiĞîn¨±`€‡c(ëEš¾&WÒfÌ2 ÍøvFÜ­_z!C¾,¦‘c(á:Ğ•+.ıÊ³¬GÕÍ€
Us¡ŒÊVÜİ±Fÿ»:ªNıôí7BŒ®Fš\g”İğA×ö.Bâ êæÑ~ÂfÖ³ª b2™bÖ“†Ã²×ï4°"ÚÌB²¡gS0;…gğİš74Z‚ eB¾*ÿ¦h1µ+=8·ŸåÕ÷,Ø¨‚şƒèOk4­r‹œğO ÆÈÚ,vøfl÷"nçöŸÙo,{ô­4{±Aèé”Qãß•cÑ`e-•¶ÑÄŒˆßÍœ¿	+œ
=>5Ã­úÅ;Q¾$ª uázdÔ	ÚÜzÑ³Ê·¨UâÑÛUuí‹1¢FŞ'Âç·‡"^oP&iqÚädÒtxŠûÕ9.	ÛÀ§ÃÃ’şv+u|©±4–ßŠğOÔW!±V\#lCÏ•.dEÌ§`§#eú€”Ò¿s•F6{óxü1 Ğ„‘n‚íÛ·ÍçwHÈæ¼M×<¶İ¼Q!H}n‚yáP¿.iŒ•Íî#ŞØx¢‘İö&b\(eP6&²nÕ‘Ï†~ÊÂÖój¿¯KxLl÷áµG¬‚`cœÇ_æ~ärYq"vxÖÌ‚÷!ÀĞbz!öáM¼g”üÄ‹_¶Xp]Â6ÑSŠÖ^ã[¹Mt5ˆvc8êŠ€.”jõ²jş‰)ãtÉÒı…@
.vvş§K:úxû€™Ø®ÃµÅğ³3—=½“ÈB<‰õò{èT ¦LÁ ER¯0¢Õ¶9jÆZÄÚtò>è¿Ğ¥ªÇ•Ê=‹LjÙd¡„»cÊ(TgiÇ²5$³jî:jŠºF&0M‡&)î¶)ĞÒ˜½Dõ’YQG_±_ßV¨ë¥h@ln€¸şÒæay”ÃÓs§DİÔüì‚íh[AXÌ¥La§œ’+ÑªM™zÂö#qEr¶a´¨sÀ“‹¼×O<õ®^ªÌY¸.°ÈdÆvY—®jy>0¹.Dß°äHÃÒ¥îcÇSd½Ğ”déíÓ	SøV(Ÿ;Ïfõåø˜áÛ€@±({ÏSDİÈÇÂH©‰ƒ‹W¢©]8´µÔ8'!xÀ]¯Ô£‡µM3TËVâVÎ›™Şaâ0§@M»Ï¾Ÿ’ÁÁb|…V~cËÌôÏû‹™D/R²\n?-ÃXe
¥NÆzN»áv¦E&æõŞ}UOnˆy]¯½D*µ
ËëöÛü6MŸ,\æM.[å;Xì«s oÄ¬Ì·b DñŒ(×V—q®"úê3nI“b *ŞJ~æQbGë:²¯Êågw=öø5ÕT†èy¾z-ÕEPç•@8İr‡°xÜyËŠ‚lDhŸJ^’»ÚØ}g'{½¨<2†WË•2'/›hÓO9öw¢_Ib!%Ä»O¿€t³À¿ÜÒ±?]œ\Ô
3 }‚çBkÀ~´ùî»ÿ~¨†dâõ@^K½K˜ë^Š%$Äåt›7uU*ºc+Üëb›«°èŒ|¯NÉÁàI–€>ºg¿>½²"qxvÆ"ÖÆ¨Ñ”ÃsÃ­f,Oµ:æ¿ïQ¨lüÄ½®)|@SëúÔ»ÿ¥~.a¥%Æ$A’`Îá¿İÑ{ZßÛŠ£¡ØŒ{ƒ‹å#ëxGe…Ó~4²cèEoeÑá˜ná‹ƒû3qÎ~3àMÏ³·TınkAlŞ)Ú4»bÓì>ôÃëd˜®â¢å8}i™eûùŒÁ|Ï,TNut`+qj™;)¨Ñ52»d¤úö¦5Æ–ª@«¢rë¥êš-ŸXï”Õ<%_xvUPcË ‰ÚëµìsÈÕ÷ê@>Y°<‹ı6Ä‚€“ŒûdŸd4b ØÓ½eE{U"Úp˜d:;*ØT4†²uğZ7Ešñˆî‚×q÷¦VÔ<Nñ'ü¸Ëâ÷IjÒ3À±§8Dô«G¸³!¯‘ã†.ÅxsY|*‰P±ZÌ{›¤7ó‘!LÂ6wß]Õ4êPl1HFB¢jÊ†¢ø„íz=Ã¬Iò{º˜…cùgÊ
WCùcRvˆ©#¡¹hvIÎÿìßv>lµİ®âšGëqÈíkÔş¾aIkps„Ä;Z~‰I“!t÷0Y™‡VjıfŸ@ä/è“ü†D·øÏbA¢_CË¢ÁŠYÂÂ"~|ÚÎGü>½ViJ~˜öüèù†=¶wŸä#ÍJ9‚“Ú™ò_Š>ë6Olm7a‹Vç­8'Şz±n¬œbÃ8†'•Ù”™¿ìÌaR¦äŠtÑn#=n%Kÿâè!F`©nµëH0£B$1
9g¢ŸÂô÷@tMÛ+ ¤^ñî¨Ğö$„…±÷‹Hô¿Œ’0eÅSQ˜EpkğgAn4é!‚‡šÚLğeno?‡L>W¯|1UßE pß1©òäìó5lãĞ›(uÒv·øÕ"L•(ĞÙÕ¢ÚÊÀ:Û%§ÒŒàk‚­ÀÍHµcÒ»:ß—¬P››~°âø|Îstğ–„©ÄFªS‘ÓîY-özÎmGÓó©ÍÆ”Bº;@Ñ8LÁ?úošõ7mÃ¼xé,]Ã°ô¡DÏĞõm>­è4òaú%LçQšFmwJ,YOc[}¹ïh‹6`÷-*;WÁòËåÁÊ+òºôåx>^>¹W¼E6mÇ…Å÷Ûí•tùÅ®ZĞÑuBú7cSà‚‰±#ì ;¿¬ˆ/åİğS|ã­o]5›ä²Ë¨Èë43;+¸şÜ;Æ«$eàæ’Î°Æ•¢­êjW4Æ%Sò%bºA`‘íl1ÖƒGÌ_`ªÕ¨_âï±²i’Ö_÷VÎÜ
9–áØJéŒõ­âöØ È(±MËºm#°pà{çJìCÖ ï{ƒ{ÈZÙ Eİˆ5Ï6p.`(à<Ñç«Q×A²™åëm‹ØÙWì1¥#@Ÿ!Şå§ï¤ë›BÓS§å•Ôn(T(>Ç¸:[ï}?bZˆK}ûÇÔÒ«·ëqZ/ïLrÙ)Ö•é¬ZÎª\Z÷}£¨€Å%'PÅ“d©Œ÷Û5ÕFS¿aéÕÆ·`¹3i»- M‰à¿‹"R+ã]pÍÛLÇEWªƒj=ÓSk]ôùBEc7­¼§vİÒz–‡ßÎâé7ƒÃÄÄÂÌxGêÑ«ømÏ:üÚ0çÌƒÄ]’Öÿ» ÊÙ|ˆu¸Øï%Œ;t­zx¶^•÷Y·‡s®è‘]à<Ê ÎFRxOÏ­¦¦äà¤eÍ
Ô+M1 ç}I^»Şÿåşi#µğ¼°0ˆÀ±--Œ=©EBFŞM;ëû6›ó•× Hc ¦şŞœõXï9uŸÁÑ?r|ÒñQ,Äµ#ñæ…‰DsU‡5µU2ã)Ë0?L¤Pé¡úÛ4BÀ2¸AË¼Ğ!6ÍÄ°­ò8¥YiMUÜò‰%'³%ù„k&-]şWœt'C4¼‡^4 lxøÚ¤?BZn?ÆL/ÄÃ, IWDa¬¥kÙ×ëò%òœÈiŒßôÀ½j`³O‰’¨t°»P4\…	lËò0M‹½ÿ_á+¢ïœ
'—óUà°İSÍKÉjµõUHú¤nW¾Îh»Ú,ººxnèÅqõü/¦èô'ÍÑ~PAÍ±¿ãeèét@«†ìW¯Òñ÷DtOŠTõr
ôMX+<$#±•ëÌ«˜:Ÿrç•È21Fİ™ü‘ªQòG[ š)W
ÿôÄÃVT¥hF íãZ„/7 øü(!¥‚ÌŞş<ær+Ec¼FÃ»-W-ÕwæLfR„6ü•>Höâ(¸©*ììµÌTBJ^Lˆ×¤Ûúv>Öaœµ^è-º¸£Ûy;¬ì/·Ei»'b{ØÿõTO%c5J‚æç¾„–I~LÜ_In/ñ+€LZ™ÖE&¦UuöW}:6”AÿÇ•fJ‡ÇòÄ©Ù¦Ó˜¾©˜Ûİ”¹[‘pÜDQş:a)š©è¢Z6øi Kd{î:»Ö¯ùúíT[UàG_€G?®õ;âxñHwØ[vÕûhÎ1WXUœÔ|FÑu…«±3
Ì~ó?$¯Ëìİö7Ú|è½÷š{ş5Pf¹F±, ¢ƒĞåÅ°è“\Ö/f×&kkÌÃr¦vã]ÊŠ%‰Â2)„ÊÈKPÌÆ’
7¶Ñó ‡A	PbmEäˆ=fğ>¶Òø{m¾Ì°¢±D£BäºËï]©)ˆµõ¬'QüE·‹‡5—~ƒßbYpbõ\ãî:)¡6>€•n<€ÿDynñb»ÅJ½vjÃ÷ÜŒp0Ê^Û´:ô¢ò‹?”R£¹‡hË !É¦„&=ÂÁ›[!Ba½Œw-â<vÈ5N1Äşeû>Òò\)Õçßâ¬“¤´­M„p–'IOûÊ‘_”78-ŠN8a|ñ×©0¾‚ôşäÉ3Æ.7ÌC5l\¦óƒŞ³Òd;Œéˆyz¦e½k}İÎ1çÀn$v¬×yq õ-İ‰Ü"#ˆç›Óê7†“5‹}¼;i±Ùñ}„kCzCBHÉ«j4Ù§JÈ_ÿñR¬ˆ†¦8*Ò¦Ä–¯ñãú³XZ-ÿ™ö÷KÄ®ûµ³ğÍQ½üÓòÉèøÕ•è0d~K‡Øölt0~wË´µE*±\÷ä4¿ş˜¼ÀC›>ôïo®á5_ØÙ3V€ë·m9! ÎÌ¢-óTACóq•k”o)Ú)pò^ŞÁDÔ„F€I	ğ'#u×)6»Œi)†ôZxLÀc„¬éK÷.ô&J®ÑÂşmæÇ+í¯1û.N…ú\{•ÂÚyŒ1”å]<È*›zôNË–İ4²J—7Æu‹X¶ğr76rTƒ
  v²‡¬ªm‚Fò4ò‰iyL:Ö¨„©ì( ÀøØ2tˆ2lÇÓºÌ|åã¹N€ãİ­Òÿê^¹¥˜mâÅ½ÏÖÍÕy‚‘à$FMGyÜ’ÜrıD…Í=Åº¤rk¸o( eb“–½•EEğbß¤7(ÉŞ÷KÖ~y|â5o¬F/éCêÏvô#	ÉŸË"·ıh>zV#Ñ—öWc*ĞÀV”Sxõ×sÀ(9BYÊ‹5éßªdŒ‘Ò#˜.BÌ$Ç1¼šœ=ƒ5ëÂ'Z¨˜`zØ¹ÿ÷­`	Ñ(%hp'ø2oyÖ)	3'4NwwtÂ I^‰°ä¹gBíÂ¤ø¢øI5Â
æ0ïNÌÓ[\+ëdGˆ‚+8AñR"œ›¡åùµ‚ÃTf#Ï	ÕhóæqA‡# ÕPôK_t°9¿	Å¿ÃL¾VÓé´ıDPÚ
óIÕÉÍ8KÆz‘ƒH(ˆ“F%¬m¥ÙP½Üp£W1oº¨Ä‹	şOùh×W{Kõş7ãP§5»ŸcŒ¦'/°B`®wÂ÷Q½W³ÂZTîÌ§ãjc}W8
Ë¡Ş «Ê“~•H¹<|™Æ‘”¡mI"â±¼s
i–9ÀvB€^väûæßú¨Œà½”¦Pišo²D¯ğÕÂXc¤3ğ`LœÂ²âÁø(}ıHL™P(+„>åzXáß@±ÂZÇ{&÷\Dæ~²5Li®+/Õ»?¦¬—_8*¡ÈâëãşZÉ_à"öQŒ7"72½"eúaõ“ŠÍHî!Ê¿	‹*C÷œ¿\iVDé}faÏ—{tÌ9f±ŞéXWd$	7%ëv°ÚXlR¿¬HÜ¯;{3d¿”|á”kvú;şˆ³Öş=–bj0¸)VÌŞ0vo„½¹T'xK	ñ"?Ád`’Ù>X¶sl!˜\çˆC×§èİ\ıKlcğ©M-A½-ôÓö¥§Ö¡cÊèÒ®eí
ñÑÛLß~Ê¹(¡°ñyÉ/—‘:¨ó5.oÕ‹øéCŞ÷©&ƒ]Í6ÏR¸Cå¿Ë´kÖŠÑ9	¥&µ×
91xr¢(KBî¹I²H¨¾¤_`÷ÿ1ÂOLZa„YU{}S”‡›ªª¤©/xŠjRH!éºåı³v«-¼“`fZ¢Æ¹Û#zœé	eıÉ6k˜Ù9‘A•y$cUt\Â¾Yf+ê_;Iz¬®]Û)G«cqíS©d–|+ÏÁÓñÔ÷0¤œb¥¤Âzñ×š«ì_×¡Æ½VK¡fJ»[` p£S¶¶&úGª@#Î…2€ç ñ-…üê Éac–ÆÅBD:9å]“UÎ«ü®6°;ˆeDD4gÜx¬+¶òå÷FŸ´lòyUU¨ñ?·EDv ÙRëeÇJ¬Bã|¨Hô@¹M_?kãğÊéIb†0]¤Ğß(ÿ´½£!x1kØS'õæaİÚ·°¤ëıMàÑ´ÏãµŞ*’2´ÿÃ"½„Áeæf“pñNô?—ª³9¼W„‚m¾±Şú¢€Ç*±”’ÊZÉ•§i$P6èÙÊiC4l–Ó~ğH’±òñlùÕ>¨»S4ó$^Í:Bá‡XìéİaÖz<ÍW­Å\ñB–"c:Ç<j{æxÈ¤FÅ?şÅ~¡v¤ ƒ·u='Ûa»fv•õ ÕI€I@<šg$­…G× şi[›Sù+KEH´İ~Wà]Œ£ŠX53B`ÛÓüšN™mŸÚÌDµ_åRqw„³i¯ &³‘]Òò
Ü¦–e» ×»¼&ÄÔ&ª­i*(]7b’8ÛÇ1“Á[+bAA9üE7%˜0ë`ËnQàÃ=àí‡£VY—ÊôÿÃA&—¯¬»õŞ'8àæ½ø˜Šn¤Ùá[˜²l‡*üÙãøãÏ=ı™ÃÇµ8wZ³ÿ¦ƒ<íµBãFİU¬©AéWp©x	Î\èº
¹ÅÂİé«ºê©x)÷üP[Èd¢ú‰öC¹_Np¹°WSBÃuÂ1 Èbq¸ùNùUW5jÿ“{ŸúSh/¸e‘Ş«XDpš“]VhGÆÂ7³Éi&}aSı²­Àò]GPHpwËjrpòñzB‘ìIâ“pµá—‹HÀ0•ÓÌ_˜í¯±KH]¦®¿ax®Œ2)°$>ôo‡ş®ajı›§Á)Ôª,–BHSPÒpgÚgä|vİTÍ‘ç&L=9E²Şìv¸àzQÛè¶DGób,œ.	`Évz‹K52¶Ûä`¿ØŒ>$ı•S(ä†©'X§(©M”û±ÍˆOCçv¦âEAú x–éjCJG2X8Äêúï­syç*º%Š|MÌ-Ó³Ä¾6õ:C%|…Ş©âæ[4/"Tt¿nÕni¬áN/G³@˜öé2óÅÃ?˜ÓD‡+÷fô½÷¸•š§vS?T×rqTw½‹EÓ^Ä«ß}µ±Ñím÷k"^VJšæêŞw•h#?ñäšì3`âur>ÈÌúÛ6øÓ¼×ï™bé¶Ä$òIWzc„rÃM{=ü¢yŸˆ›…?×q‰ÂC&-}òcÃ…2,Z3E’²l>¿ïíòåM>‡›YÈŸ/ßsgHİ&OsF8®íˆ«I³BÓßï²¯û¬¨!ÂĞ7â‹Œ§§G©3ô;[©‹«¹e-»Ì¬‚ı	EçåÒ·ßÒ2 CíÚt íGÈ|:Wm|Y^nMä0±LiÇ%.¨ş¤9©'pò,XÛòÉâ§Î¸Ó…±`Ùa,•ÕkÍÜRJ-¸\gl³B†&MÈE\·ÙˆY0ø‰Õz:¢à;\’µ—9•´Qå‹’[OeÑ Š>¥<%çİæÂˆŒ &@Ò0­;U…ÁL~B2Û)±|·t%¡c¸“/Ş¡:tñ°E%vÕ¤‰È5"âhÏXÂAÔ•Pyä<=üÁè~Ÿç-qëLú´ÉË³n2ãTc©õ8CF;up~51©BqàDGû”q£ÿÓşÂ„q>&±)G‹Ñ‡›ıÔ¯Îûã•bı* ğ†·ö¹á´z±h)[4øsWhˆì‘³‚u;’g)"m‡d(Ñ^å{	óşæI^/ttï÷$§fÓ˜YtŒ«É"8;#i¨<º’)œ©/Ø2t|ShvÔHkò”A7_!ŠUĞ(A¿œH«'qIoô H°oØ³T|dì–|?l·(nÇÌ­‰%µ_©Cœ¢çÁty$SÅ±®šË‘u èËÍÀ oôtÊJ_ª™Vß]9uK>5ˆ}šÓĞ@*-(ŸPıœÒ¶rÚjAì¶‰”^Ô[7Œn
yşú¯| "Ä%C6ÖÕ—0V8·ˆhœÜZëÉM1HM©#øåµYë+™Z'BâšZ§‘ğ
¯æÕ")o3cÄ˜rDxÃæwÙÒ|üR5SÌBvg†ß­°6şšnˆ*wpëTF'FûÌ‚—mº;KÚmz´…ˆ<£ÅÓE·$M
&ñÒ"„£’“µƒıßÖWä?a¸¼«Çø¤ëÉİB¶bºjª0èj®z·ÈûQòÀÃ¥¹ƒáß:_Õ»š’ïc·§@4ÀÊT"CP„¥÷ñaê|qB.du=ıXbáš™¢QSSê õÜpÖÛ4ŠóÑĞš*¸ŸJAˆÁ¤ºâ•~ts*]–ÉQŠmvw¬£w\?rMA£_ÍzĞ*@8¶Äoé‡6Åºn<|µ¹xpòÁæÊAÅöÿÂ¹·¬;–Ü™Fîá2¯ı°;:Q—1…0Kß-Œ†Z¸Ï°·Ö+£0WÔñv:’=‡ĞÁßÎ… SŠP³”Pîs_0¹Q`¦k$×}_ÃêTunµ­(Vî_&©|z¤x²ÃïŒü=v€ï¸ö5óó=ò™‡·BL­vËšæ#¡2–	¬9±ï…S}ŞVS…‹>¤*‰ë)5½Üú>İ•}¬¬€[(¤¨gàşîÄS×`»°§*ª¸V¡Ÿµ§Ø•5ÏÉA’Á[ÌÄÔ"üÑ€] y€×­ÜñHú,e-XdiÎ†Õ¿»”hi;ê¦± ¤nğU‘WSjècv3ô>0Ò}Lh²âÚVıŞİuÓéaÍT2`Ì‘¡ÌVˆ²F˜.4h‡/®´TrçCLšÍ@BÊ2ş´Z¸?ğ!“TH®¿9V{ç\>äjÙ#ëj³ ¼ívÕ»Ô4•éû*a­şÙ¥øşê•_ÄºÎ: g±“á»`ïr?)İ*aı íN7şTóÖ%Ù-Puódt’=qÙ2k	,ó	îµæşˆ	ƒ5×uÍÆyèbŠ,ÊRÒáúFÃÓWOå_Í”…^Lşô:¸¯·'&/}@ ¥eÍå”äşîşÛá—¸øê(BÁÃ'OVƒ8‘ú¸Šå¨àÛÿß"hä8j~šàyˆeùœ_|¹èÎR3ïOœÓØÍ,˜½t”öÕ­éõ³ieˆê·¬C†¡Ê’C½aÍ°¼Iİ~*ĞÉyÁsT°şaëÍw{©ËDğZ§dCãWc•<ı­¼¼³‚€›:ÕòkÒÙ“Úù}[Ä+ß9D6^äŸŸ°¯Ç!=¦¶ø÷²çÎ¬İåZ÷‹"Q…Àï±½b~e´õ%{Ó²şRGe£÷¶LÌŒTô—AÃzUë^sSÃ•FCváS£TŸ!ùtbŞuO)fo¼à·Óü“¨¶=™»â¾L`ø9š€›mí *Ù?vpØ+¸~E+Ê¶v EjLï§^¿kİÓì¦ ­Z‘­N¬úDÚfc¿c_†ğ'ïÓD6O®]øªÑÎáßËå”%7	ûGaa¿ƒá*3›çÎõÜêÿww~ŠÄ7ãíÎ4ûEfUÎĞn8_Ë%ƒçºn®JÙ˜³¡–	9X,”Nš¶k36¿µDìåÑ¦Ù.ÉÉ*ßÙQ® ŠÙ¶OEk,ƒ3†yg:Vï<1ì©`Ü”uÿuŒj*¯ô crË!¬Fj#u0©²ç“4)Û\¶]s±$ÓSå#GG(S=·
é€^=o«ŞÔÊbÓ[æËÛÁ±w!k¥µé@û"²gEkğ³?MãVÔ‹gÂÅè—0¢í|×“@š—ƒsªoœ“]HB¦ ğƒTÛ¬òæ%¸»yPjí‹Ç_İš.P“S˜r\à»~Pá	¬´ÿÔ0Z	½_¡\}Á;k“w'ÀşéE…–"ı0…µĞîyN(Ç™XŒ¯Üs–ˆFä,é½«®.á-§p ˆ„¸x›‘ÜòI´‘rNíîOñQïßâ„/Ä&|Y»ò™Ğ!
¶An1åÎ¯hj¸Üˆ¯¼ê›È?´Ğ'ö	î»½? ‡ÕWÓœ«O#ããÊ¨ -?uúód­B!$ëîƒ  d2õ® (Q[—÷aµ_ÒŞèæœßÁ‘§øM åâãú›K/ü×„Z?ö€‰olŞì'ç‰ "5áÒŒ$é´ö¤ç†.´LøŞÂŞDÖp©ŸõµÜòağ§oq’Üf½VXòt(êù§KG'vxH2ôù…Ó`û²põJklæ“ƒbgZv }ëZ` ƒ‡¿Ğ¿z~ù7®|õ&Ãˆşà!7jîó314«¦CtµMë~TRÈ.?‘ôæ_Å5{_H.}Rè±l¾á ÷¥ÓØŠ5»0;,ßœ»­ez%Yÿ\¤_Qş²>+èTœ@dèìçDˆ_Ñ]²ë'Ñ¯ûg.S½B³Cº{|ŞLÔ1EF×ŠØ\ıd4×³r¤; Ïü07Z’àxuxĞ&Iàe%‘Ëóh&‚‡&s¯úÀ7j]w¿"öïn76Â’Êd¿fsÛ2ùEñ"‹-«¾¢m’o½ªîƒß•cùëÍ23º?1Æ]”¸%'Ç N…F€ŸÁç¸.2 c•N†éT×2®|¯¤‹uv8iH.Èó˜Rüq£$ÿSØóoŠÚ›ÇV¢bÀißÔõah
+‰p¡û}ûÇ¦µÒÒÉöj6iö{­çáaWºf8CÜ¬XzOã’­É”ş(ZîKœø|bÅ¦ÜŒ´… ÌÅ9ìbód<' –|3’°K®*´ø™ònº€èƒ_iÎõ"ıhğD¥$°‰•Í8Nù8„y\ÒzéÙ …Ldb³æwS©TdµQåš#¡]ÖLËûQi«)ë`ÿ&İáX^Dæµ_‚uÛå,æk›!P·x”Á6°a¥óüj}ÄŞ"f,#^n­ª@¸MHá´›ú’­Ÿt?±#!íš&Ÿà\g:1bşèN,g†PfAéÀï§¢ç^©ˆm™òÆÒAwz±›œÖæÿWÛJÿ¤¥Æ".%pQw«µœ³„
ˆ…Åèl¯	„ÕF™Ø=Ü.p“†qîÇÓÂ–xÁ¬æ³D¨—$çw©âYdS&è‡]	8©Wxòo$TDäÀù
NTRB‹OšıH\ĞBµ$:¯qON!:€.&µ|2\b%$ÅÆ	Ù†@-ÈzCÁºS®u¢5±¶òŸ~ûËŞ–üÜày£¶F‡ô5æxî<¼ÚÃV»P[Rc¨+‘Ûß·¾§×lß\şçYÅ/NÊèS‰Ú»as9,Å][¤U=é5A·7R¬ò“™#u•±x2Oû9„(;·Læ4”ïÉW"o°‘çyg¡>”¿:Ğ¯'†²¡ÚtğQÑJšÑĞ¾6 H}_ï˜a¨¢³Kbş„Ÿ§şó9IûÒåBÔ¾³L{,ºù~7«tsÌg,â(TMîj¬›ˆD ¤W¹F+C£2N~é.yáŸ9‰Pq3´:Ÿ–­˜G5:ş„İRüg8ƒEÙfY\xëB”y$Uó^E¾øQ„f •>9W™|jt¾§ĞfM7r¡Äî-¡ÏÉSº^‡¨’$Ş«»¹ä÷UÃêƒ.Ã2ÊgÊÿÄª`$DŒ¯‡4
sÜƒ2Ãe™f¬Ïônçòq•Ç®¬r(ë´¤ñTDœ@›d>ZßùÅÕÖ4UU}¥Tu„Èy‚EÇG¡ìåÂl\iN4(©İÖøé¾†q'g×Ää,DÛ«U§ÁHlC×ûû$'ûSÜ‹dœãD‰)„´NÄã+`B:TĞ[µ[-ò:¥3âäí¼5b¡pd˜©ÍN—öÖ;Û]¹•Èê“eyz. ıçiÄØI©`ĞŠú%xø‡XPÉ××Ö†A2WOE¹•«)s{x[kúb¸2ÿ·~Ê,èšë §TfRQ~šÈ$×œ·hÜ“è»šEN*™—^N´ß]4âÎÊx,0½" §Ú´ •“!|ueÄ=
^°<è¡Â+Â? ¡‚à)$czJEó†æU–Çî%µ£¯¢¬¸L¸ïS.F–8w­ GpƒØaÜ¹ÅŸÔ5~yâÔ¢¢rqÁÌ$ê5Êp*%£µ[{û¨ZüVçäW™©[;.W‘³Ë˜¦ªï†ì%å¦eíö.Wa#ºp?@9iQŸZ¥¹I6bUİ¥>.!ÒdH“ e/P|üc°Ç)Bé \iPŸıa$´¼Ò ×¦'4u”t«ÿ„Eh6²6ü¹3±Î%S~I38ÀòH¤iA‰±÷†S
£Å@?lNˆÀF@‰ Fqı¸ê×î9¡ıu"šÄ²)òsoN>êÓ4–¹Ëub±Ë~T»E¼ãtÏ4ï œ^wô	ËÿÇıÆÔw—$¦ÌtœÇg¬ÊšBŞyTsbqŸ¶o@OJÜû3PMé’áœ¿Ò‚·Íù‰øDâÁ—w‡T7.,œ;ûRruÅİUIÓ8ˆ‰¡çúö¹æy®WÕ¨En£èTq¤šÄ=«@Ø19uK}Ò£C²bT¤pêæòÏ2Èiô-?í¥ÃÜ­ø%@Ù¿¼Áº[nø¤{ˆ!ï º+>cw=Æ€Ø?¥ù¨LŞñö>Ô‡® £ğ©r®‘Ù…—Ş«£·Öñœ×3j	²É¥“k¤R6}¾Í”‰÷¼İ$“ñàæÈÓõp©Ä-Ï]g0Ö8CÇ“P@³´vWºzX#«¤‹‰jğŸR%ß_¢¢wr ›g
{»àõ”>Œ~È›‚@ª)?Ë¢u»¾^u…½/Y]?Óş°¥c¤Œ{kÿ…^ƒâ>ş*=˜c*ÃñXW4Ö¦Y²öÕwm+[ô	ÃÆŒVŞqÖm'lX€Ø·å¦}?“œ„eí²“ÔqHİgTLOh±e†$n43¥¡úŒZFŠ‰dıÂºV	tPjÔÂ‹Ä±â‡\BÅùmí¼&HÔdCÈ—j»ª²n·ÆœuõˆËdÛÒ¨7ÿ;:Óëe»ZÙtw}Œ“eÿÒ;Ödù’í¡«ÔÙÚtfcä™#/‘JUâ3FÊK]Ätçã$X§Éëv)>~Wïòo,OAÏUÆ6,@àˆB5^İÑÒ¦şJ	ñ§òäv§!á¸-ïåT›œ¤€ÁAAş|†Ğ1_ÄÁ7%HÀ½3	¬ìô àğKE¨àıA'­{’© Æ‰»d¥ë&V±ueÙU)†¸fÔK·i,OAUö‰ma†OÙ)Îß: ‘v­Ç¦¬C¥k\uÌiôAABTaI5Ğ©<? t¤º"Qpt<ÎDñ ı¥ÈyO—n—¹{…¨÷/ùğU/Íöù¹$…>á§lÃùÙy;‡]-ƒ?±'®ÖŒğ¸–xF=^­ aÏ Á1£oÀ]„¥AÜfN=‰Ï0óÿÚ¾!úÁÙ[ŸÁE,Ş§'óX5í“ôÖy}&Û‚¼ÌÍ[›	ízmrô”é²oÅ·ã¡ıÅäÑN-$~&^m‰ë $	 WsÙáş„x‘3Fàöô{ˆÛì[ºMYŸÉEµxúù°ÀAşÈ uüú}î›¤h‚E-‚Î
ö‚ÖbûâI5ÕÔú5ñCÜ®"§Äqˆ9(ºª‰gi§ZzH›ëb›øŞ‡1]r+ ½‰²s2'óŒ¾ï…œ:È"üŒ‡ÆJhRØ‹ıØ©0©ŠqÁ\¦&¢#¨b§oŸÁ—¾u€€©¤ Æ¬X  è
±b`“®9Ş[Y’E‡('ö+ƒÎšù“&±­ØŸ¥º›üğf®Úİïû,c¡êqn J-ıâG8x1ÖVØ¿àæº›X™ĞMHt/¿ü€İòáEÈó)Wx´Ú..{w(-¨ MeO¾‚X\jÀW˜ïK-Òu{wŠ6ª¤²C‹vèÀ
;,µ½vSì©¼É¸6øÜ¯Kn­gÆNgˆÍ§UäpæÛk»ÛĞ†kcËİZe-¢®šÄ?—^…É½d³‰Y­øÚÏ(,h¹µåÓfùKC
6ƒû7ìº9ÓÌHuÎÇ_ŒàM! ¢õÇÌŠf“^T Kû+xu»®·r„Hà¢<A$è¢¯Û2×µÒCë[‡6²Ñ ¨W7 M…\w(¬7Ì>Œ-®’ ÇĞ¤…êN½LyG-'j;Øæp"tšé§·Y¼Üâş<±ÿ‰óMIGÙ}»|‘Œá»á†Etmü+Ho¼#Ó@ƒ–ìK-]:.œºÁCY K«vlnôßo)ÙcY…Âè(Ï™§}¹(îÍ™0ANêwæÅ[7k8/:OÊĞ+¼ıÃ¦×ltR‘ªM}ö¾ã›Em=”4=gãmÓA@x‡vV}ğ„étk„²Õe„ØVFŞ/V©!fI“%\ÈÈ~¢2™1)ú›"ŸÆ^¥8@ë>XĞ¦˜V)Lkd¥Ò¹ÍÑÈ]Ô*TxV¿#î”x'‹€pƒSèFp( ÷¢Ğ"#ÚÈç´No_!W“8µ©fkğÌ½%D›X«êK¥$e0öOÙt¿„²ÍÒÀ ¸â1“]­4Ã#>€n¿ôïrm´Ï·\í¸Œê²Ì =âJ¹>Z#	É	ø¤Ğ†¬Vü0¦:¦Ú0ë;4„pÓÕ:\ÇiëÔ×©+j—sè[YZLÏxú‚œÎÃ6xğ7Xè±©jÓ÷_â¤˜Áb]\Nà"ÚµÛå?£p÷¾Ï½,%KüpÖ]ÅŸ›&ÉjïÆŞ}Ãìdı
ø@0Í,r÷£érå!…,‡X‚2™ú'—_ÛTÓ- S’5Ä`\,…énÆ·=ËÆQ×núâgLdÚ/’ÏlD½ƒ6–x¨¶wVMŞİÒbp‡ßJ¦Ixleõ1äd«&¾NÓ<eEğY‹»Å€7ñ•„*!ù+OJFKšrÎ³ˆµê‘_Í¾ Ij`•û«Í¨¶öÁs¬b(Î¾í˜»Ô2à!Lu˜qÏ)Üáäñ¥¼©:HmŞÃB¾~ß8ïó?’PûÁVyàİö8kû(aEÁÓùµŒEô¨á¼„*ÁCßr
™í”!×¼ì×DğTRİÒ¡ nrDêü<§ªD\~½õm£°VÉÅ-Ğ	zÈ»~ŒÙ±9ıäì‡¨±šJè$^½ÚÆ^ë,D3î]E'Éœo·7Ë8r-ªã"°V„n¨ÄV`áŞnB¯?XàZèî~.†Aä„“o¼`İ‹öÑXfö?mÚÜ³Ù1¶°l#ø[xX„^!3c¢ÌúşlF*¦U›Ô56Œ“¿ñµ­~ŞYgK– òÈ«Ğ’G‹ÍßOéÌ)Tn$–¬i×Üó×·Şê”‹#o‹-dÇ±Ò8àø„Å­ÄóDZÑ4d¿g:V)s¥¬Kö3ûóõÆğa)Çäu·ŠJµc“äÂ‰Rçlš£ª‹ÓPŠoájB[Y‰¥VSØA&äB7İı‚õc­ƒh¹37h†¶«åZ€‘½”wÖÜ+'u+X`K§ÿuÓbßÅ¦"éIQ;°ˆ«ª?á˜ï4F<`LNHJ»øšÊïú#bçÅËâ¤ôø©‡Ôõä»9H|8òğı‰oæ¦£5M¿š–k¹]¹½‡†*òmån¨Ò
w3=’0«,…’I•`M,RÎ*ö„‰Q0ïDßæZH»û×"Ó°cı½¹_6ç`P%É+¿1@îæ„LoóvëÖñ~Søæ„ÛÛ´işØªnß4ÕN!ºwÌ®¤+ó¹»1U: •†º·9½ÇfÏZşÁ[ÀÜİQÛBwRXi{tàaoH‰Å€L½¾KÂš	áæ¼–*‘ë.;mØƒè V¡ÎÃÎƒhÌíu²±‚U0î)üÏ{—”Y+pÑƒ±ÒÂB¤¤‹|.b…¨»–„mÙ~}Æ}à­Ü-7ã‹ì†r»­|Ÿ'„YÄŞDÔbfdövïkÃÇ÷P»Ï“ò˜/1® í{5{üf­ÖCÖ]m,~ÇØ^a‚Rëôƒ]¾s<–x´êËôbMœ\6­ûáòkÍènÑ:LN1À²/ÃŒŒ
ŒôN“Ş…Æfè­JHñ>q<#òg9µ·ËyW"'Ş~p™ë¥öM©E!V¢‰MÍ9åõÑ¿qYuÑk+j$ø¯‚m„cßj ¥ügœCßp‘BÓ‹…Á`Ç@?X,õé!±xÑ€<Œ/Ğ‰ÙŠ±•İİ/Ç”²©?Ez‚ï»Ÿ¥%—½UÅZğæ ÷§è8Ä‡&³4	øÂó9ãÍÜCáÑıyÃù”A3ìzêç);ÑF¯û%*n¶ÎÌê|SvÌTöÈğl×Û¥±¦Aã0oMFşÄXÕüšWÏ›Dş\ísÊÓFlÄÄ"HA3H~ÿÂ9ó„eÑÌ‘Şp]"qR™â4%‹p[eXÂú›Y‘@™–Àâ€¨”XÎØÙû28`@à©ÊkKlüRBìê¥óW·¶³¸iBö¾œÒ´uö9U7³·WYw//ÙÃøTñÉ›uÓ±X†ÓíÌ¿¹œÉu4´…q¨ÏÆ÷KküÄE±°%¤%âŒ^1‚¦Ï»xÀ]¡t„*¨9§ƒ&ç}'m`¦µ÷ vÚ'N<+ˆNSÛîù°’Iv…°Ğ÷F\P mEô7›ÀB^8-ybcn#ĞŸúËïæKZyxkF3.(7¬-í\ÛqúB[¡×ºë¶!Øà
Ë|ÈñB$®ÊYƒYLñÁº·-ß.CKŠªÃ’¯Ï{™‹ œ94÷%cÉH¯ê>DÚ¡¸Õ‹2ãyğ}½r-
‘x\¹@ÀæcÍÜ	H¼ÉMüÛÅu¥æOÃ·ƒ¢&|p–wÔo&ÒË0ÇOÅVªü
¦ŒsûZÖaÑNYW'+j
©ÕèO=È®zx@«òĞLä``®løtÙÛ1kp„ãpS>“İÇQúÊîW?¥û¿µY2ym˜lÇ²ô•“º¶P¡ƒ™`­bX€	)¶ˆ>Å–Ç|cPİƒñò’Q£î¥)”1O¼—×ÓÑ£‚m*"@T$¡¹Ä÷[QÙnĞe¶yûà3MAÅáÔz«°-^Ù¦âÀ%kÌ¹°¾…–GQ!>ÆLvŸ"~ãú¡K“ì`DOz?ÔÊÄ/ES$­¶.
IÎÍìc
Hù3E+&5o}¢³
7”a}·Ş9Ò·¢ƒÃš{fõäS'¨Š,¥>L’AA^<Çş`yørÖÜ…&m.‘„˜™ZÁh @œV}fy½b¤'Q¼V @~'A»>O¹ûòBñ’é¨B[~‘NÓ±ç4Éş(Û¿IÁ"¹fŠ%áOê¢sl1Dİ»ñu¸,úĞ…§	p)fS>3LÊºhüxI'd/xšıÙÈ5j¹¬½³´l`qÅˆéß/ğç‰ÅÈqn`{¹Ü¦¦Å1ÖÅY®uÄM{® tÅÛ˜ÍØ/{çñTóñ¡I‰ˆ6sâµ÷»´›oÌ-¢ıÍÊHa†iƒ5İµ>7}¯LpÖ@leB¯F<7À¢à*1ÂãÒì*±KGZ4Ó` ‹î–d‹0V{áÇXàGÖæ@Vpf}î;û6ïüÒÒÃ£ ¢\,,§Íä#Å€²{Ş”FZôQ7Œ­*F-k‘[Q>ûÖ ä2ºˆíÂS“€tÔ1´i‰œ«¤¥CL@|ghÄ[İß}Ÿ3,Ë—|ÿ7ãnÎ	]1Í°f8øü¿^ëNß 8HÌ}Å4vÀi^y'„CmÀ0‘ßó1dÜÜ=…Q–Â²ï%$¡İ*ÔZ[“××Ìš$fù”Õà{ïÎ_šøºQÏP898"(Ü}œÑ¶OÙ´c†Ê ëéVĞg”?ó‚ğ•W.FÌö¹´ ¬ù‹™'D"&,‡- /xA•+VqĞ]‰‘÷úı_eQÏñ"³­ù%W™0gÉ{Â”@–V„)·$—^¾Åe³ƒŸêæyKò3¼K’š
ŒØE˜¡zmí°3DJLúÅÑÀ0È›A¥8™Ğ>ZzyÖÍ Şó-<Î´¦`LÑ«‚¶ñc‘åyEºKÁÎ¥ÑP¶™¹‰Qá«á¡ØP…±‚ŸS\H½R>k–ÌÀOQc4a ³XÓ¢ ZÍ|±òıŠŞAÍÏÑÊÅŒ¤ÎÆû—²œ zƒßQ»^<Ä±˜-•Â÷P‰XÍYEÉãi+?.™
aìhÔnõñÃÌ›È’â€ˆÄ ]>>VØU!m¨È‡Ÿ9|RÎÊeSI° ˜ºeÖXmíHCS·“³	øTUèïÇÑµ~“‰|Xä{;<e>ÛÇfp¶ÿ›2¬Eëñ¨±¤ÓmB)Nç»J„K»ÂŠêN²²ÓhTme_É‘æòÿ¶­Mâ¡ÍÜ…P¶NçÈ6˜(döñµ!Jvk(ñíµë©7‡´Løôgá§ Ãª×(v„i)pBÊÜ8—ú‰8u2E@Éa Ys/ty¹"DRQ2İ©©ìhË)´¸åÒ|"bN3˜=2NéV´m‚™ÑĞ°”N7í#†Ùİú‚DAü{/“VB?§G7Ï ã(³!³tïj¤Tu»ÃşĞPqAgGÂÕ#“c¥vı#êD”%kÉVWS ì³ª‚ıÍI{¸IsO[¾Fq›sVşîx
V³Ô”š£ZĞ9°‘'?™v2¤’éd~xËÿOÉ”wéba¹¯Ïç¤Â<R€Õf!½°‡vşâ}
¤TÖ™ÚO÷,ãtşÙº‹¾›Ú~¿nåBÉ	\˜Áj=ïò:—N¼ª_)Bƒ’ß˜zÈa<é>D‹¦¦Æ @Ï’»Ì3Óu©æabÂW^Ñò`hƒá¿õ4¡>i^ØkÀcÀfÔ>©ğq>‚);´”Äî¯%øcß¬ ¨PoÖ\Ï_J“à`×öz¥9ş‚Õ"^Bš!4z×)ŸFjlK)XZ¹ª…±"?(Óg7a+›È12‹WÛÍßÑq7Q,¹ïAÅ¼Sê?:†Ÿ>gLZ«ÿâ ¿ÃìÚÿ0kôFUšè´Î³üg*óû‡Ÿ §á-N½cÕa{—¢Í¼çQÇÕòöí»(¦â8á§.‰ïöu‚Å.‘×á—>wÜ¥šô24¡Ş0mD‰ù7Ê­y„Àca€0·º¶§F0ú"âğ4œfp$wòfÜdúñ ?LúÓÉ^Ï] kl¤Ê¼âÎ‹pŠ•ˆ©Ø\hÚğ<U]v/dë²Q˜ğ„LŞ9¼’ífÅysR\\Õ8nÚı@LeŸŸ¶•2jCc~	g^ºŒ[
„½šåŒ¶²Ó ;Çª¹:$F‚g"…ƒhÌVOkÕyûT:ĞöÖ]GÁÛ(pÑ;ó²ç„ìÑœ äXğ«@îï(ÙøÄ.i¢nÂ­^ÉÜm¬y@ğY÷C@g!w$m<:)œã<âqŒ¼ÖşNIe×Ò¿Àó˜FHÈ—ÈTËz^·¾¬aœÛê^˜ĞHeáÿûªd'ã1h}cË°›RîàÔŞ˜ÅáÈ<€–ëvªœHÖWl*4|ôx{qCb{’œGí©2ùú½§:=ò·’ğ‡ı¥àC¾gLÉª#"P‚AŞ^’£J{Voa“ğpœ~gù÷^*ˆœÿ ²Z¤H"ŒïÏ•ú7‚ĞòıÖ~¡'=Øo?…u5§Æ’kW]zº ¾:ùÚó,[	ÂÅ½éÇÑöPgäÍáÍC°éxX;¶sIDfH¹ÌÎk¯O–àà?CRBˆª¤fBe¢2kæ;D£(b
ŸÙ4[şÛ*ænÀG·õŠMÅ0Qj{qúÌ.«°;kœt¨©ú•÷Ï½‹®Ç/İ	ŒÛ°nàaÇUcJİÈ­
ÙHç,©Ğ_ß-XşqgÍK0˜{©Ä4<ÖŒÜQPœMVP'oË;—ƒúYötÑ5äã]îsßÃ×Ü¹j¤D(RßUyKT­Ì"!Y/a iƒ¯ïÉ•€ˆ£¿ûİ#‰^g¦* I5÷`LÜpãkRløC,1FÙ#M¢åš’Ğ¨14çËß„Ef™Ğœ9^e£‚£¨›©ä"-âòV1QÖÂB‡—Û>U¡FŒü3{$Ê1v	0§²ˆİ3T5mxº;"ã’¹›ı</y¢2trhhçªù:b{¨Ô®ISÑ^³¥TQ"zcŸÌ†™ÉAŒHi¾{Ò‡+ÎéÇJºÁ»¥¬]•i}b™§KToÎlIà°+]XÖˆ-a@¹›Ärì‹
¼Ö<›‚Â“áßéDtçúVÎİ&uéŒ³Ë…Ôöæ€8ÊÔ°ÁÔİaraÆÅ©¸À]i™THZ*47–¡7¤Ul¾¢àxÔ³sâùqZLÔ°ãk¹<ã%?¶%ÍMúâÛ—{Sk¥·,¥öú¥ÑpÕ-?ŞÌü'QV}éÍ÷1Î½É‘pCv}/;Ó±p:pÀ…‰³=¯Ò†ßÔÇuB¨‚ÿö×ˆ|w^“ZV}ÓŒ™ÎºË¶’Ÿ{[^#ñ¦ÍÆ;v*a£#şGFvŒ²	¯šw(½|<²BˆÌ¤İN35ÉÅ›Úg~xºßc(“6óı@“â(
aA“ºmf,ÓCÀVyëÅ>ePsó!³kËè"1dÑËŞO:’™¢l	¤“lœ‡E+OĞfÈ´<4}É¸É±p,
ùßÿßâ62Oãç~!]q÷·œ™±çY„u“>B•^¼·ªfÄ'^_°ÛoÂL«ÁoaÙ’Üë,–æt¥[bÒ’µØ)|ã2åâ‹—õîš]A4Oáõ»ÀKvÖ-2½Ü½J½î)ædÅ"vÒ¨l©§*•'Gj~h,ÿí2/(”‹oOKè|ûš¶)÷ıÍr;ëØúI±ówØ}C¯÷Á8Nf"Ç'–ÿ
ÛMKÃ¬åàŸa>­w\r*åaÙ4ú¬(.‘Ãª†|NÿQ‡¢‚¹ãnº]R2»UÇ=éVãâ5ùB*Ù4®oğÙeú]‰Àj#İ”ÒËü®ğ¢İHÿKÙÿÄdPÊ;J‰ìø?ğøb<ÿúiî+q	¼Ú‘õ\3Ûj–ü“eÍçÓÆî<I$˜E¢ø×#/ƒ
¤ÿf¼iVl’Nñ–ÊÃ+¥WcÍ<DÆœÄ:ÿ¶vŒmÄE¬\\é”OEú¼Ğ*Ôs~ÒVp‹ŠÕæÒ hhq¦»SÎ’ŠøD“A±ai×fB™X‰ğRúåW1ªö%òıö„İj¿öSÀÑ½	ãmêŠªÕ¬ç^˜ßuhÓ<†ÿÕ8°Óªİëşïï‘U|ˆ†ßH—àW0«İá¥{rğY/©c‚Í2hY"ÕyVbúTª¡Iv~x€TB#=E˜eë}›°Á¨#­È¬BPBPR4’Pğ¾Dg8šü(ä‚Ú’ëæŞî€[òâ¦XÕ±yÊÃıÀ>H1¾·WÚúàûŠa,¥ÌuÂÅĞ~à®e†¶0…,üáE³"ó•GòD`7‹BL|"H´v!|7‹ÉŞm{…ğWŸš‘xàá×y_]4j3IçÓ23¬ßïÇ)uÙ Á*ºTÖTØßŞ›û¯­?ö²x‡GnªåU~|æ)ÔÏºï³ŒILìæûßü@¹À¯ËÉŸ)+ww¹å.<‹brÎâÖ.z#ìĞ„;´WÏúw‡ó£Ùı)€«"H¤¤KèóŸb–>¹æN.h•I¢‘©ŒçÇ[wıä›Â¯_4cºE]­PA*6ÉTa¥«ƒR¿ò=m¾wŞ6ø´yô©a ñ­˜0«K%TFÊlOnù5°üLWğ9¶W4øÑƒÔGÉè,_ ¾7¾rHæ7r	TdÎ 7a•šˆ9„ròqUé•šì†Ø¨‘ƒz°×#ÜQ'†ˆ~F¿»ƒ¿¨Ãßëv‹¸­ıÒø"ÍÄnRÃî¼°@ùñÆ¼ÿKvïVÂÃ©øUå^ÁMõ‡4U7†Ìş?/ hşn^'_2ä¼¹®…eQÅ¡I£Ú†…R¤XxûXY§5rf%å@ÏPœEØ<o ó8ˆÛİ–xÜ¿ë”KûîpıOQåMRï›ÈÖ49õ‚Ê"ÑßVx3ïÖa'˜Öïa%IMÚJùà{¢§ÉàNa…cl"(ëVÌÔT_î·ü+VíœU‘Sµ? Uı©Osİ;#àŒı¥—ùªñ($›Î8Jm(;Éf{ÄÙ#D»³¸)c€İ
oM´~úËìZª«°¢¬B¤»×Í V£Ÿİî‰2p÷íÙÃÍ&¢Y¹ëJ¸í×yä€ Ô¨!	ÕÍ&>ÊìxU¦“µmëÏÑ´ÊÒ‰ÁŒÅå™ 8E Xçn³Åª@½ìq¦'zd,
jøW+€&NIµÕ=$Â-Ï¨°xË`H‘ºÃ+\Õ±¼E!©ÌÓ
Wb8…å¹åJš%¾“£v¨I*›wNà:§^Ó
b*3oµÛI–ûX¼í•™…õ¸ŠNnëcƒ£úÓÑ†Ñ$±e|=?Æ¯íp¹aåd6B	&C8mªl!äÎ'îîŒ¬‚{_íQz =j¾ğiâ­5ÏËÔİûÆŞ.e?“óÌÂ³2(:^LÅS×5||Ğ1¯©á™İíş%ú…[˜h‰‚îscOÏ)Tw1ól€î­)¢2óëØ‡‰¹†)QÅß¯ßmBğ”7H™dX¡ƒ ûo¥ÖÅHF<”ÆiUxD-]KÓdkka5x5İUQ¶7G5í°È¿8¬3£™S*“ok¸–[“Jcšyüë2^n¡:¿•İ¾ºìyÄ¨0ÿ4¨~6jN:áµòÑšµYLmß-®ÆÔanÊi™W³{;µõêËE¿9akõ&…:¢g¿Xs
õGõ]´_?EÊ©Y1µÀD?m]ëÂÍ‘0•ßVÆpŠÔÏŠIRù åˆ®¼UÔœÆg.!ÂAv„ØãÖËæ„Dâ¸–RÈÔà°¤z$Î}şª³U@[oÂgVEÔl‚¨Tu9»!~ğè]8B='ò8j2·À&úÅzÖ³²	BÂF6ñ”x\©·a/Ÿ{˜Y(·¬¦§®a¸T±>¹4 ¥ƒ9œü0DmDWç‡RBùÌ$àDxDF[7›	¸°ıí—_"*»wüVKüÔnjë€)ÑÖÂp¥0öZ¡1MøzHR	Àq'ïUÔóKÆâ!œÚÊ®0œıôŒÓ’‘›ˆìrXfãë½AÀ¹æŒ78â=Ç]IñÜ¨òÃ^D­ï¦š¼®	jö0?j¿×´¢6Õy„Ü–\H]ã\sÿy?ì´/#‚İgî¢Ÿ’©—¼Õwºî°¢Í,¼~½4ÀhT•pïaÊÊãMGe‰*fÁ™û'­Ñîà˜S–y“Ïş9ZbÎ¨*7‰§fVÃ¤‘_x~A²õ›“J´E~Xğ Ú4ŞdÙYÃçt¹ÔR>j°!o+Ë{Õä	šNÂ·£.t×2ì5Ao{xPğÖ+9¼[væFL·ÁÜäÓ#×ÿ¥˜†õ•ÔŸ©	*ëluïjÜÚs¾Wt ªÖƒ4¿iä–ˆ_ƒr ö¸»NÁW¹Ä±ü¸ÅëL“ÆÿÂîî2ºÿ±MËœNø‘Ng>¡ÿÕ›«†pô_ ~ÆCûOsq éZà¡ı‚IØ™Lb@O¶>Ã:§Ş÷l	&<5Í;!:òºO2©M	]ô×)½X*gêî ¡-I?¤~D³—ÅÍÜQ¯¥3Cúu¤Êtj€‰''É{lŒ¬;¤e»·\Ğ€TÁÍzşj(oKçø£°}^'²JÔ´·‘‘vz½óÀEj¾Q?ùˆãÓT„v¢<à{nyŞ| ÅSˆãşEù-x?3„hh—+ö!ıÉ¾åñK›€“Ùe0æº:Î–D‰vqG›,]P	×áVifš3¥îöqƒÜ )];f:dAUr[õ%.óo5ÏÀöZo“ûg]’4V%ÏÓAÅWX·+§½T˜"…•í8.: êé°DD  ¢G¶vëbÕ»~ÏÎ
ÌÄ÷¹<G©¶$eYeõ÷½CçUŞØ>Ğ7§,zhM²‚qîbÂsDˆºp¹®`C ïÀüõa,Êë[-ušE´úfÆQG®.¹b{ó5&åe.Ò…Î[;EiÎ|:LÊñø z§Îàò’>Z¶ ¬e/ŠÒ<‡¦¬Xã§çI5Â@ô©¼?•øÊ?úØ¼d«Ì¡WdIœİó‰¨tÚZ^\úùnr{‚·Öş;®§Jëk ]ªúÃ(İeÕä¸¾vÍ½I}zØ8ÊÁ¯SçÁ1óQ¿Ï…^õåŞò=“ë3<.i~-œ.ç³šX‹ğÎš~¼»±ªqJ÷‘·ÅX\;ğÖ`z(£>Ê²saIf$¢ü lœisˆğáš”œ8S±Z¾· Ÿ§šıù(EÇ‚Q%e#Æ êbKù	ˆ­¾GìÆ*ø#Îo%-àæ3D)/Ñ¬É¢Ä­%jT—·H{—¦¤Lä£ùÓ;VÛ/ñ^Â8~è2Ÿ:A«İÈß´<ª¿L„ÚÓ‡İ;ì+­•}YL{«£<Lı€Š6RéÖ_Lnœ“ÔwÄG8$-wC`±)"jÑ‚¡u¥Ûqº§kÚ^o¤.mÀ¿ 5–ÅÉ/Öf'M!ĞòıíAåİÀµã§è_ê‰Ù/‡49Øãv)³«7‡,w'åÂbü²Æz´äµY0Äãû¿7x4±¥ÔÑ4hçJg˜jHmş_šÄzß´ "yäÚ¥Ì®ØXõ+§âó)/(—À"	¨áİÙİœïB*ªº1!3ÏÁM¨h3¹¹Íªê»ĞM³$jQ-áó˜Uz‘b[cn#;pˆš@‰"^Gjõxl`:¡tìwxE •Á“pfóÓôbk\›p„ßà?…,OÑ3ûdÕ¥¦x”Az‚Äº1IÈheuMM}Çc]‹ÁpÊ*~œG‘ö|—~¦¯?Ûêñ¥ÜmM#É>PÉ›©ô÷îÕ
UöbqÛ¬·RH¡t
'l…Ò¶GûşÚ©™ekØ]úÿnÌg½åçÆDlé¶ª^ø…E[5÷ª\<CıRS¦«4u<1œvpinsV¨f‰àØÌÏõÑU’ íşy!r}®++Ö#¾ğ.ºzTØ¦};>®Ç¶¡B°ülD¬Ë î¦= ` Ù€„¹ÑOúiˆŠ3ÚèÈÊ¤+ŞâîtØBû¼cúò?kÿ„µ¼ÜÄQßobw•ŞIÔªô›ÔÅğ5dbÚ†££ØK¿â9œ>oÖ²q‚
Ú^ÉŠ‚ÔÒ¡aÙ{(skàµddß³î¼¡JHõ=„.N?&Şº¥P	ÖKàTeïY4m¡ÿwƒšbM’Ëü*¥‰ŒâA½R”Ä5!>æ	Cu¡¹5S±¸ïÊ[vƒª¨äp2tØAêK•ù æ«1qù­9âLVêÑqØTa2Â]4íFl?fBá.ô$Å>·;ªU×ccë$û0İ¡¥«Y*vˆ¦uáèYw @«úˆÆnY¬ÄoÎÆÙts~z3t‚;#Wï­}é¨Ÿ9
6‘Å• ôúË´çs&ü)o·«à\HG+»ÚO€rŞœËDk’‘.ş¤E;¯ŸPS—:W¹[¨ò‹Ûw$RåEŠ¡Nkü|XÆòÕ”­pØ‡#Lüòê	oİuò)px;È¢qãZìE¤ıˆQL§µ½ïak¼x«OBe)4,ö‘pLˆÇ¦!#£ªb,­j8`Å°Œ‡5ÔJå´õŞ¶Œ©&Ì¸RuÍ£T
²(¹›‡zóh£ÖŸŠaâ:M˜Usßë¢·D\7óÜñéŸ¤…êïSü"ßG˜u Z6÷,2B¢9ˆ¦™¨‰¼=EN5&KC´Q3¡sÍ7Üz H  ìúQœØØÂ ÷·€Àp2e±Ägû    YZ