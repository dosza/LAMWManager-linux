#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2472300436"
MD5="5b63097bff7d345d89973ca3b8fe8985"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26360"
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
	echo Date of packaging: Thu Feb 10 18:32:23 -03 2022
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
ı7zXZ  æÖ´F !   ÏXÌâÿf¶] ¼}•À1Dd]‡Á›PætİDùÓf0ÛÆ3õ_(Û•–H#ßµËÕvK„×KõR„»Şsƒ¶ºDF«üFP\lÌ_;sÄBØƒ‰î;%ÊrËáæ¹¦m~%¿ç;£!:N"CÊÇ|ævõ•ŒÙÂ®Úö,ÁdëÏ6	Z3Ñ.–ßúCs]$™â®sÃá©£ÄDßğQåHÄÿÑ¶p'¢òi¢åÜ™‚0ÿw[¾Ëµ|GFâ®g?8ã¡—¨óo‡Ïò*è«vv4®‘ÔÉ‘”êZçê€ñà5JŒö§™7Š¢àÛâš¿°;Ø-‚/b˜r¾:Ÿª‚İ³MHüRÉV ¬)°ÎM±ğg¯>²'½ËA0«få­½W”¢0Ö·´OZEâ«œ0¹gãÁ8E<:ù3Ôtw	GR !™=qQÉsgëÄ¶©Qíºn
Úì…X~3ƒXüœÊ2ná/0pÜòîgµ¿ba°&zŒ=kÊyPŞ—øÿ}BLÙçD¥‘ûC‰Œ´øŸÍ‘®ßpr7ùãj¨}Œ‰ù1@ê.këanË„ˆHÛ;ù]hh[q…Â2C)ê«I{TàkÂØ‹íÃ€<şùÏe%‘ø¶Î+ŒF¾
¦y¾zÊ>µôÜFbî¦Æª/M†éÂcÜìK‡—,ãa¨]Ãß„2íkƒx¶ïó#g²t©4bšg²pctr­:•µøëÇP³jÄÀ-Äà”y–æP c
Kr[±ƒ9—ÛCó¦²Àú9öJÔzJ	R”ˆÚp2ªæ?È„qv—PÖ’§ñÿÆIYÎ ü_”óÈ
¶_Ğ¼Ô¢èqş9ü\“¦MN7`®tS"ä7IüWãïƒŸû2Óé†ı„çÌÍ‘±‚•%(õÔì0=˜Œ›—ÿlÔô–jğg‡<JTTèO¸%˜ ëùHîå’µf‘òõBWFûĞ¾`ë Æ—ÍÅë©iÜ‘ÂãÛ'-“å‹üˆ…p2wªùz¥%vuG7*U@<1Ñ·Ş"°¼b¡_yØ’v»<`)sÔ|ï!Í@1 0Úï×!ÃÊx\kZÁ^yî#*ÿ±·Hvõ†‡AÒ@Vˆ#P<*29±?0÷>¨Y¨™FÄî%v›ÆâH6/‡”é×Ód+A,×Z­Ç»ò›ìŠÏgÿŒø%¾}6E|Ü÷^,;Êyy{¶êÂËC1IÆôİ!@ÕTÒ?<‰L¼¨¸'¹7íÑŞº¿9Ò[g2Ê¥ÁnÙ5¬xFr´tX™µ
¤zVc„é"dÈcTàZ(~‰ŠñC•5r‰F+fXó(\?lO}Å„½ŞY:Ê )8„Lã
YDIC¡ÛfÙß	 ®fVÇ¿ø·_:›ş¹(ãëÈY­=¦E¹ö‘Ùu²ŸcA!µsğ9ñ®Es+ˆ[–«%ë€4]Ğ"7¡±Ñ¿³wš¥’Ö0Um·ÊÜ)Yª8®mü8î¡òÔ¢ FşâªkœŒ˜Ï’»aÃJ³õ°¾‰¯à†ÊØÅ` y·÷VDò”	-¯ëuB°5ÛXt²xr©ÏI$æÈÏrùuBJB]ÌùòcN+–GÄ+6e§böö3o~tñüO—0½´Åıèã‰E÷ÎŒÂ¶AO‹Æ¦^ÁQ« ]'; ~îe_»#K¢ÕÑèeÈo"¾R¿–ŠôMY»v!ñ“¡ÑCE^,v1²®Gœ^È&òY_-÷™ŒÑÒÏt"èófƒ#¤˜z§¦IÒU­n<ÛÖíD‰-ØbğŠ‚Ï­RÙ;?‚/_Ÿsş*2nĞ-ÜÎ³M*W`ûØxş˜¦Ï†tKEÎû¹WèB9!sÉ‰¦áb\ìç½ÃeC{?6HÛÛ:l­½ª]Í0›À0Û­ ¹ãY`©;Aiœù†K\&¶®}µ'Ú¯æò‰cÃ¬§‹=²LíÎÍÿr÷&Â^€]Ì;+GÄŒ]™à*AQp‰{øâò»’?Îuâ×ë>y—F7ÇÛXÏÔ	O<Û³'2øÓ§Œâ®­ôŠ²­A¯ï•¤Z’ÿPX"mF¹¡õ¥y'<SÍÏÿ1r^š“F¹42
l>oÛLyRÖIJ$Îş¬ÔÊ¿KÀ B¬ˆ«! v—šğƒ*œ³_Õìdx¶l*
Ä+Gj.C¾?=KÆ¿rH³t›P"bßÖÂ6ò•İSOëËÎ¤.©ªIsgûcÇz¬ÂpœAì„÷aeŸqŸ<üÁÛ/ŸçÊ› »;ëíşìjU)¾)ÿÍd… 
û{îş3_	àËj$Á+q›$›ÇâênöWEtë¡ÖæRË˜¡Ë•’}ky…ØéòGì›$Ÿ<:ºÅmóùÂÊLÌLr¯cófo™¡'Xçqq^í42?-H¡ƒ‘ûb—(,n¦fšBÅˆYéY[Îz	‚«¶{Ôÿ°ßâ}ZQ+ÌÒÒ¿XšÓÛ
ÆrÀâî_÷ê‰`®()ËÍaÓoÂ:½C<Ág¿9ÖB>F‚ÉóE«{¯¯®¼á_¼¡^”3z)C$ÊÇÍ‡5q_¬ôBi¡4½	º„äÅ]›a”af¿½?^T¯z¦)³¬–j™ s§^±àÑ«{¦]ÜZ…UÙ©ıCDÌÖÜÜşÖ¬h/K·:U£w±ßMêOİñÖRÙ|í»géÎZûĞ$nèL*$©°å(<8™0ˆgªŞs¸k)nIã0R¥ë -?«1êdãˆZhK.u/æèvSµ0½éšÆ.«¯«ù¯¬:Ê ³0tÉÂ‚Â¯BMòI.Üçø¢yu`gÆëĞÄìÌx³}µ×EG/.øÖ‡6ì#Ç8¨.‹ò*ş"§yCËÂ*É?UnZò¥w˜Çıïøğ¾rŠX¹µ÷Ë¹ÂÚÿùV!L
Ü¹šw£)º!³S²geâyœ’‘ë°l7+ã2À‚ôœÑ(I÷¯÷İşgYµFò²ä”~À·Cÿ<àÙÓ_ˆó	(0-ÉhÛ=Šy‚®×nUnï=İäXÉøõä@BĞ0;òÁ;EŸŞõ#"èÙæèOª¿3ã+˜j‘‘İp5Ñp|¯=WAX‡ş±Á¥;X Š«¤L€;±—ÄêSKW»Ó)&n`oåxqñl:~Ê;UßaÈ,ÇS¿‡Z¾ûá%ş!>of€°-Z º€æ<›–6õª	¼~ßA†Ü–O?>l4¢ MQRÙUx’*‰Ü¿Ìï1ˆR{½ƒTY¤›|
­H™ôì£ç·R¤Â”‚•Rş¯¤A'Vßù; Å:Åá¿æ`ÀïŠr|\EÒi›ÄT*Ø†I¡^Á”È¤nÈı˜,a²v=Ã×¿Æu‹‰„®ñZƒ3$ –ƒ…&ô™E¨jİ<mË›p¾XäíÁ*^(r`X–ÖŞVm¯øZ8]i2³ìõ¿!ö¼¾fT8ÈRD]N2•µŸêA1Ab¦["Oé“›0ß×h…5Üşz+ßK)¾íğ½ÒºÍS‰şÓ73Õ*IØIëÿ#÷õwñ?•±’@ƒÜ€?º™ûbËª2¿?kÇiñ|!I˜9\à&Ëg»ÏD_<0ŒØª©~•ºT.ÈàU]åhÌtœÏ· å1²¥À¡IX$“­{YjVxHæGqí*¥®‘aœk_YêÅÀ»“\ÔS ~œlJEŞzMLqdµJè£3ä»¹$Z	Ôİõ4¬w@ú5ö”`é4§î¯=æšËKW¿­‚®“±Xza}™x¾û×©Î§…nÅc•àÕ5î¶ÁŒØs=ĞzOÃíŸÉÃì‚ØpQqİpBC.kbWm—’/”{
_ğK¾ïºĞ²%ûWÛÉr‰ì3ˆ¯—Çr"èé@¿-£â,,UèHÇçx6Ã ã1û»ÏË¦B/{ñ†±£íòÛX— zPÜ Hï“ĞcÜÅ6A,šMOÿéİÉÄ§R‡&Ál‰XƒÉÜªiŠJÃL~µuínbÄ²[~™ö’¤‘~÷¤5ÚpXÿf1>7Ñ”LòÒ•ÿî5ëtøHö’B¥­Gdä¤:Ö²wÓ6‚ÉìƒëøeÂ¬aÂoï
dçÔ.@ƒWìékVÑƒf {OŒWF±©tş™`(G]÷ìúI½…Úr~úÊ¤Êº»ö”…B>m'‹Ì§›â‰¢J†°®}Ÿ›Ä´åYØ`JpÙ°ÌdN"€‚8{T]M.[¹©©q³H  kÉ1ªÃ%Ë<1]jUÔèÙ}ÛÖ—½\[a½ßÄù›Ñ#ò&@Xß0[­<åÜ©–½:÷â@†¡i¤4Y?B4ª¸°ËõQ¬¢5o–uGZtu½İâGr_
p Ò¼!N•Àt¼B8 ¶?p>![URXMö>:äq1Ÿ°˜ë 5¸6ùZwl‚5kK]™¿Ï"ÆMÿˆ«e„¯jd`_‘\V{ô-TÅV©f%á2Ëmvx•×+ÈÛÂ<HÁCUâuYš¯t¨ªóÓH×ü™€Å‚ôsº6µå6¼ìí-Ö¤ªâ=#‹+×6¨µ”Üíòeœä‡oy#
Ÿv7xèó©K¾é²w•rÏOáÈŠ}~
Qu±·ßÆ—,^Œï®—eèó/?–¦Z9Â?:¦©nX¥2é¹üú!¶û¤ÉrìV‡6³åŒV—äÎ³xIŞÑ‡<[‰dÓWú ßY”Í¦íMÅØâñJSÉ£1F6Î°ìW*“]VØÒÖûÙÜ06`_Ö¡|ÿZW¬°;¦JÜtJşz]šI`è4z æş!µr2—“$ÉeQÖÏí¥ó›-Ê¹ÅS‘°‡’ŸÌ²g,xBôqmHìÁ^óC×•°ìªØùÔPôW™õf{©'m•„xSA&×¥ûŒd !ÀZâÄ û¬Ç	&şOÅ³Wû×ôş-t2”¥/âÇ†gİ5Ê^O¨oˆjVø1då~±ƒÃÜ÷’Ói#+-!B•ŒYıÓÂ®·ïH2©zO•ùæ,¯YŠB1u|F]¯§Ï^ö(Äz.	ÀNYK Ş×]‹áØŒñœ]àvârfÃhò¢mr Ær=Ï'©F˜¸{6K0ÇÊ"Ã|ó'ıkú±{‚úÓ
d”aÔ
‡»ÃŒö½¶„Öm¡y(‹8ÖpQ«í-Lz’fŒñb‡K'LF‹ôt­³ Ã«;ª«›·Ãäf –MhØÅš5{gçÖ‹fïª¸\‰#x'¿·ÖµO~Øƒ;­†²m@¤¦IÇ%üõ8ÊR®Yû?[àxòÚÁ)Çbÿ´Œ—ÕºoĞ»_P=Æ‘5«>Éªæ•Ñ»ü?éæXÄ8eâÈ’LÓ³¨R'=Ğ8ô„Ù(g¬Tg½/»ºµ7Èêc§IªCŠÚV>]6ËìêP-UÅÔ4˜ıÁ8¡…˜¾A«DKÅû¤Øø£T!K*Î!(EµTE.ääØMæ®Z*¤¤Ä>U“¶•Ôì1ŠáÎ_ºòÚÊŠÏVn²,^ììì 1PA˜NA{cØ·[,Ñ-ñ4{¼~ó\6E’.¯Á¤]‘-Àå­÷xş×4Ä'9‡|½šÍÁ}Ù²sŸ²Ñ ±—Ì­<à×^Óíÿ\l1¤Ú<8DÍızãI*hÏæyí8.ŒYáƒ^·™R* O-])„MßÜIRù&¢#şå¿rt7wuÏ"²|l 	ØÉê}7VÔ:	ÃÅt è¼kpã°áñD:íDbY7iz¶¦a›ºcö›µ/¿‘¨sÒÌââ–(ijO²EÊ5½®¿òÜkF„›•Æ{—HŠwŸuÏÓ¯ˆÈOEFc¿x,3L¢‹C„aÇ„ŠÑü,	âæû–Óë¾¤×t°·Òÿß—§Hz˜øƒq®f"²Å™¤a,T@I	âS2_äsÿMƒywÿ1¥±ÅÁmn€¬Q>Ú!ú_€;É]9yùiÁïÒ„š¬	.í+ÿMu`\ÇÛ­ç“ÖUrƒàä„ûÏ¤díh~÷¦«¿Ù|}	’×8Ö®|oú/<QR2ÛcŸõâá|iu³?™û@&_\	O˜³ùêq”A)*â‹­_–œ­×?û¢0ä£?Îx¥(C}İ8³ö%Ià;'‹CIá|U˜êz’œór›ú:êpuJ™WñşÃÊF
º¾ÒfëJòS¢Ìj¹§×zdî ù<V†«}­V)¹tâBB¶¾ëø=×Ñ±dx
HÒ>p0Ü‹`c¸Z¾jNø$Êÿ¯ĞA„sşiX}ƒcYN'rv°’Õ æ´ayÂ
Ô?1ZÇ3¯'ZfuWìÛ5Ö‚s j³íGÑ§ş´¹şÒÂ5d§Dãnè(œ\åqlµÙ8“ûoñ 0½Mìept¥Æ¿\—Q8şaPA5Vp”œ6AáfHB~ö—ÛT%ìÎ•™ü¡Ö¬‚W\1íè¢ä¥>@Ê‹ + rXÔÂF‰âÿ3ó? —êš[çSq\!´wÕ¿;¦…XjÊèàıÙ+cÑŒÄÌV™DäBñ¾8Zw²OpEÙ4Èûˆ?5µ"·0uë:­›7[üÕ­Æ?†ûÊ¢GwÓÛ¥}ÿ+M²Š#b'%7¿ŞJ©-÷)íö’UÒ<s`ŞŸÅO^iML“J:”º¥*û§\O€‰g™Å7Ëª»Â†ğŞ¤Tˆl!A7kUVWÉ†ğ& 8à—(ÀüMPLÒ•/)N}¸w!Ièø=¦Û8Q]””=‡*Õ“†KÇ^ÓXJ™ì}£iôÖdi¤l.óLŒjÚÁD`¤ÜX°"#4ö¾RÿÍ™H_ ¢”N±xW%ıß”íe¾&…neCgBJ–¤{TmÎÇ•¶D S•Ó$/TáÈÒñ-Ù1S1_TÇ˜jÌb±€Øç{ êm0³“PdÔ£Æoyû·Ö3u`ÅöÇ³ì<“ÌXˆ)ÑÃjÎLÍL÷*VMq·¼ÀÌ?<ø"ä#C5 İê‹©ñIÜıæGÓW\ßIütR`9Qm2*ş¯½J’×/\ ZÉ7 eÊµoÛÔX°-]áìp±’©¯İ¢ªÏ²ùdöñEçuuCàM4ùÄ#‚ÄÛ’ğkRë)å1>¤l‡RÎEe¿[ö–ÈìTÍÑÚ0|ŸÛ&I)ıüYùtl*¨•³ :dmï_8=zp*(k2#%%$R:¡¤_‰ÑéæÆßÉäİÜ±šBÙÏµCù”%‚`â_"İq…w²r-‡¹	!ğD¯sTejT.¶l)•&bÓ¬ßÎg’ M#Ëã’‚™EmZ3‘i"ëÁU?3¸æ„5Î°èšWœ±)×kùß°‘âIÑ0¸#Äî0¾[<2“©}ãˆŞŸˆåa¯ÌJª»“˜^h,I"2<mè\Ş{{™ë¿NmÛüßBß’B	¤R2tİÛ·à¤J5ÜÙå›4F¼°ìHûß Ì²Aì½ßÊ£P–Ãë!Şí òÔşğ„‰ë0wöÒLÃL£9A!Œ6\²CmYş¢¬Hœ¿ÿ!iÕÌ8+ÒGnH‰Ëâ_DbK<êrYö–°ÖKœ
BsùÉXú˜ˆxºXËNE»k‡ÁªÖÕı#	R•Ì­MhOª.ÆRXY…ÅŸf‚‰­Ëf\ŞÕsßÉé–À†Š+tyøDtö’êäYB4boy³çÃ¶jYšĞÓáˆ
‹µ ÅŸ,‘á)¬Éb‰@5+#©3×˜	st|h¯ƒ
?2SÏß-'7Ş‘Ş:„Iğ‘âA'hsèÌ%iö©—'‹® ™`ñBĞ“f3´@w5ÙÚ§^33¾Æ¶~·İQ¾äî‹ø¡3´e½µqŠ‡|gî÷û	œ»K÷)Ğhú( ±5êşc¤XüÓ±¹£å9CĞm{5ŸÃÇ¾¸o5¹È*‰Ş×›a•ô=–	/×µ‹R8S½ùEÈ)iƒ€ğWêâhl(«%|JNÛ¯63ÈŸ{ït¿Û)Ù)ş6ntäúlÆ‚ÅR¨¸d½æØ?XT–ÁÒYÒ ¸zR‘Ce ¾Ô8Ÿ £*ş›BVVÔĞD%€İ´ 7ó
`V} .‡}s©õº8Ã¯©Â+¨¾Á•Ä. Îèùcÿ!Yš‹Õ†¢NXÑXR(†®ñ:¯’õ­ÆÑ¿Æ5ìI5È’ÆÀqÊÁiC6^j;@çyñU|¡21„	rYWfOM›#SìˆMüsªÄ¶Xœé5¡ôr\é]1Àï„}Î‰WvÌX?ƒŒnoÈèÿöµ>””[6X^Y˜åñÚF@g’õî$¿yİ›H¤§WõîXÀğø>Ç0xÕW¼ÀÖ·Æ8 ¤Öfû#q=¤İ‘
 ¬¢ª0˜;ğ¥§v|Z*soX\dA*š¥Â$ëó	a|ÍlâÉ^şSs_ÂŠ\‡Â«„éEû¾¥¼vO‡¾†è<p€X“—sDå>å,K¦}ıñ¿(¬„æîÇ@ÊE˜ÿ<@sC!¦(WÊĞT›ï 20Zw’âWÑv¡ÔÀrSâŒrnÓ‡Sf;ÄŸbw÷Åª”5Z£¦áŞò8Ÿ³C¾—tŒ²ğ"<4­Ä®2AüW)Tş -¸W†s;ÕÀp¶T	»Ba‡D›p+g¤×˜õÔä²8åĞÅøç&]SáÍV ;›ğ\=&f¸p¡ù 8ŠKÄóTÉ¾`†ZA…ÜÂç k^¼aw&]é}Ëgâÿ òŸ¤©¨ã‰î=0AŒTìÅ˜º˜Ó9ª™S×I°”õå£íÙ›(Iq&#ÑfÕ!ÄhˆUÈ’Ëğç&_‚x¨È&æ€©|‚]"<ñ²%%+ç>[Ÿğnb¦`{Èº¥˜iÏH-¿Ü Q«ğ>ŠïÛ¼@¯y”È£Ag½ÆNÄŸ¾EÖô%ƒ6ÆÖ?YÁjQw¼—]|®¼lMÍÊ€à[ME`¥ù³êyÛ,/¶	n?ˆ:óÛˆàâ'wıŸ;abÙ8ş÷‰Ø×íæ;ÖzHœgÊ»eÖŸCd^0=dêYµò3Ö{ò4foÛğ'Ê•Â§·ª±ªB—Kç¶Î*.ªÆ•oéà4aôeá7â
Köu#õ[ğ[=ø3-—€È£{êè:Ód³ÒªJš‹ eA_Q”-p ù›-…TF½<-@b\3xxª‘I_cfë:ÿS)¹S­,ü×c{Yş‰^ÜGR'ïsØ9âdÍ lwûñ·áËzLM‚ Ö?û‡ıñıQ1¯UiõS©6Ó²½å°™4²X”4Ã»GU­«ô1è-õÊœ¿T{ğ‡„ˆ ”.£‹TƒhòG™"äp˜¹)š²># ‡2hâyø''M¨7K´³ÚMN×ácÙe"…bÓÈ™ñ‰¼8éV}²jI9VŒˆ¨m’-ûUÓ¸ëÔ$&÷õ¾>¾_­++ÂäÚÆha,x¢*&]ªÅ’„µZ7Î—q;§e6OYúv»§»x¹tw}|®‹»ü×ıuıÊëúáF‡1Òñ~¿¾X©âná©fòv3Ã!?-Lë‰åI¨†óŠÊ¶€ŸUİ& ãÛ9<¢û©61½Q~¾Üİjæå}Ï¢„Šà¶ey9Y·¬ÙÌlÔ=ae»»X@
uÃ4ŸâõSÌëÿ4#äÌ¨º@-<àïM}õšND§%utqê9×Ijj¿znÜ„dN¬=a¾šT¥¹ÌşáŞŠc+óˆßØå:Öæ-Æß
z¾Uj«õGÔÉQAŸ& şÜÅ+dƒH`óu¹ß6U_vW ‰ğıApÒ–¢ÓeØÉ’—í˜Åƒ£ÏË¾×Å´†áÂ®ÉÄÕ„œ0˜°YŸİ´	Jb‚ùî0‘ÁÍ6Ñ#™G(õŸrDÒ«H‡¬28 ê™LÚ´“f©Ô–¶	QØ™W­çîû+è²b7˜™¢JÕÖĞz¥ˆØ‰ÀÜÊGùÁê5¸³½Ğ£õ¸?5u/fÏ‘„”xÃGØ‘xĞ—³ dJÈˆ»©(Ş©â”¨i=iŸø“f{ähN»®àx Êë%§‹ğcYõş°úÂäš‡@e«CY	¨ˆ{vQ@	ÃoóïHO¨2ßoğ ]ËZß¯1¡å„ßV5Ã`¬ş3Œg:DdÀÚ–ÃœñÏ/!Í”5›iÉ.”¥q…IBË*$ğ"'’ñì”¨”ÈˆGx¥­ËUa7Æ_”X‹½YÄÈéÍùQgƒ™²¥şQ^w‡Z…¥­É£(aNî{„¿Ø÷™%¬½øÁ°™*ŞT$N­šëãéøÃÙÆàÙFM¶u·8ÔÈì 'HÃÜ·ô\W}Pîºf¼2_c+‹8Œ/–:ÔÜUDzöUEL`ÿ±şvZY¶ ÎgÕ’ŞW‡è1å\FOúŞ°1$c"d–	MMîû$óÑªº,Nzƒ+êd„ÉŞˆPj;¾ù<Ê:ÌwÁL.Èp†Zú’ù¬ëº)Û*ªÃıª™ö\\¯Ç'+8‘wÌk%†è9±Wî´ë¾yJşôYƒš“ñÁ
úulu“sâ½¦úCïwõ\ƒŠbË¬ªEé‰vÌ´2|)´[!T>µg„íNo÷U_ÕBÆÍ×
LfYĞ¸Lõ%3\¬y1p¹kè™‰¸Ğ³s»sµbhè«¢h½³ØZ»ds×ì=ú}ò{zØÀåpÎe]!ãò+Q£ØH.M5I\íÑĞ¦è	x¯¼ºô'Ú€Â$qàxp£ğœ ó£ïŒ-aå1;P¯Ÿş}ÌßğGq$™sÚ²X*şi®¹mÍÇ‚èV˜ZÓ‚[C57Ó–ºà·Kn_™8JJÈ¿pü„o¦‘7Ş! ß3j)[ÔL·Ô×çÍŸLÖìlğ´ª¾G±&‚ò¨i^V—&¹øÎtPa½Ø¸@÷h¤ŸtµV“Ñkuæ°TxD3»6Nİ(Ì1ù¼>¤=ƒÍñsº^*ıê<2¤9oŸ˜'Kp3’Îƒ'gA“¢Â÷…6S-õ­PÒ™ÃÚÄ(¸l˜LI¤äó8Ûö~jqü¾$ÇÎ3ø×_ß'pkO;½iéBœe%N”Ñ–—h?ªøÚ]IòÅI%6BD°1œ¡mŠñ´3‚NU—»¶–÷SL9Áys¦ÜÕ™'ŸWêÊØeçî‹ÿx(½ë“? %×¼î†fƒOÙÉ¥C±ª#A*h$x¢—yêYÔ^OMW½)'„N…—k“ƒ¨V©Å€@'ÖõU/pÚòœ#aòg v-…dæ·Ên;0p½S–1Ïdª0Í+>•„ŸøqxD.›šsÂE«aRQ×f…ºè5T­ûñ@±ÛàåçİÃckuòêÆpöªGøÖç±	¤“§µ=íf0AFYCZ û–e©/xªÀõ~ÅT¼ŠÀ°œèA°»ÅÌ-kXÇÏ.µ|úàI3£^èÏ5,×µhÉVÁ­¨¨›]©¯ôU–Å~>]ùS&‡TÌ™hÈ'4®ÎdİÄV7^W1œ]xaf§uòİõh_jfM$EeN‰ ’>¿™vş œ ,Eiçìÿ"Û$¦ˆVy^IF²bl¼oâ±=ª5(ŠXºìFDXjŸBğE`³°ñ:Dz•š=Uü6»ãßÀ€Ä¤bË÷èaÜr;kñ¤c?áÆÛŞn­°ğò‹äÓ/ABäåÌ% …¥ç·ìØPş¾¤LÖê®9Â5€yÙ¬0QVïÂ«©Ù
‘ÆzÖr–ÁtÇ—o	S¾oüC(v?ú?“aĞü–ÉaùåSVÖ]sùÉäu£¨Z8£½­îÑa±#\¾¸¯ˆ ß´…Òm`$V—f=¨´¦>ô±òåÎ:xOs(:§¬:,jÒÒ¢RñyïzP³ÚL–pCim…sŠsõqNr¿cKw¾¿)®4(,{ÌéÇÜÏÛJyP†NôsD=ëf'5n™x»ò×ü¥0íw`1j"ò€ùÏ\8›É´jëƒDïdf«ßDóSzÍlá]^ã„ã§¶O*«Iª&Ñ£…îÆÍşú•¡œ1F‰a`€š}5]şûøšZßY£^¬„ ™koid'³k³†2Æc[}ÇÒÇP ZÒO¿©ò”Í‚,ì™Sÿ-³9Ã´„ú?ú«ú‹rƒÌßè« ²^–«¤áòw>¾¯öF;™}|ëD–¢\$.Ÿ†yKd7WVÌió¨ âîûZ>dfUò²0ûêš…zÄÊÖ[qP²¦?ˆ´Àÿ–Ü•™¡™ıéş*•ÓyşÈÆ ï
²Êâ’fhw;øp’Ä`5p’z4ïBÊ¯©u@€Nõ3ŞÈßFãf·º‘8{	€HD+U2à£lœğzû­-Xş½ù_T©©ËBœ­à÷Íwøãr÷zîû¨Z}*Â(­j ”Bø1`³¿ÁWB.«>ˆl™£¶nğ%…k
#£Ç%íĞ/Ÿ Á^Òpa·%"ç»˜*9º®İkŸéÃIÿ CÚTa½YÂ %r˜áryæI3>n>ÂÖ:T]˜¯+¤J€ÈišF‰ßG‘Èpìv=Êİ§ÈôßÓ`z¬Õ&¾×şJcÍÎ&¥]ÉU‚ÜĞü¬yúœ!8#Z³ËúÓ„UHm)âİ˜©y²Ïm®=t‰ã“ 9š\¯¨)Gµ+)ŠÌ­¦*À7¨eäTVo–ŒEB›5-§M2×F iÔ{Io–£5ã(Ñiº(aÀŞ¯Ég)ğT¨ªÒ±q<åk¥I1ÕG[Æ{Uåõ)?‡áºƒV9§kÙ7XX„X³Š*¶$b5váj+/ğSşÆÚLPZÇyÃ>i^|4¹k"í¢ê”dsı²B¬Cöµe%„™ÄÿÕ_ëØ}„6óÀi¹×ió`§rİó[ªg¾ï~n«—ÅIÕHL	É›„[£®§<lÙÏß‘äüFµè¿ºNàšê]G¯ñ”N™~‘GĞ=i"‘)ÿñšZuõŸzºw]4#¿82!x€º]İÉœÃ,&Ÿ(á„¥e†QÉö=gå)/V`Ú¸›øWT‘¯Nè£óMˆM7/YB‚‰ ¡k­d‰Ô$¸ae­sÁ`wø{e0v½æt†^ »½İÊƒ†jJŸè÷ù³oñä~6ã&§ñú–Y„l{CÌ
Õuo]Kiš˜ù†ıÊO¯E‰rİšÜõv;(§_£é]Ö½×f‡‘¢g‚|é~uiV;ÍŠ[»¸Ë¯±Ód™{×¯¡À«ØhqèÂà-˜¿=v–WL˜À80Ã?Œ}u†)üB±Áçè—‡4V¶pùñiÊÔ(–-%½Ü™JlŞİUŞâ6¸cå§åi·Ó>´ƒO[ƒ¸«sôàÑ&Ä¦\ô÷´}&Ö±¼ªJ‰'w¬Kaÿ|ˆ=y»àSá¶T8-h8}kE	»Áó]é{PfDŸ{‘$«åÁâ²3Î4ä”­Æ6åfFJšH'óòì©4‰ß´ü‰«é,š½v:e"°‹(Ü² óÃ—·Ô°Xş{h³¡U¾„1Z%¤æ	›ş¢€Êrá‘\Ş“b«Ò¯&”÷‰õ¡ë™¨X4*6=Íp#è‘,©½Ú–±Ú³ù¸bÙÁ£ÂH@cÁœ¢Yîÿe@÷Ïm0üú_Ş¹9[Ê'e)ØOl‚˜ÿ’A§¿¹OK\dEı1Í{ô&ãÏ™”g˜å±É‰©_cÓŒ"ãb=›`
Ûf¦]H^åoÌ²£	éß€>Zd¸M«i ÂËõı&Q¯C‚şâyrêØœ—µ£DzàïõÓÈ,M|qç,C9Ì&´Á	·:|Zw8ºD0a’ÁŒP:sĞEHr“êÑøÆ’•È{]‹=ôŸ…€Üğ|~š¥ôi~mÊ¯Td3`QlÆRJTá¨Øÿ—OJPÇkÇÖ¾o"¿‡Çé‰EÅş¬ôD(ÿÓ®Aİ¯æ	8Yw„Î ä¨` 2¼ìc›¸iñbàw¿­|AÊá„!%¥$Ía(.Ì2ªp‘Ab`ºqoO`aNU»'µ=5öûŞRšüOl5´€7^MREDHÆH[GàLæ&Ÿ+21)iºÓfW aÑŞ(ı±–13Úâ_HÓE•_Å‘½^937—Ë;âÁPş½h'ı„±+ø¸$YÆÃ]E>É ğ„ğb¡¸,’’Bµ…ì”(¾´«¯=ó}qøùà¸L£ LA^Âüöj_Îw”¤8ÅÃ`r®ú/1:›[@O]‰Aì„ZLşkœ'n{Ù¾„_ç_yºq*!€	êÊXîMÀJí< ÄBËUĞ–å´JËús€‘‚ÂømÍb²”eYns…
I<tLf(CDÔè6‘mò4RıgË N…èNj°z¶«°u…rè¤µ;D!htsƒÿ6%P‚Ïi©Áu[÷¢á}992<y›ÇòÍ£|LW„`ua)¦ÓxsMãÙŸ0L³Ï!ÂŒ*6í’	ª¹ÑŞ„ÍiÒsøòhïØÚáSY~Bmı	ëÔ/Y2zJëßÁ­ãa	úCk Q¬YEQ~ûÆWÓË‚l¹p‘d²`bğXğírÑÓ<IåÍlb_Ûb«¢v’3“c¥ı…™wâ:Ä^zaî\‚”^Î8\(v÷á…åµš*0<øÃüíë†í«çõX@‘‚´,¥°io³¸¾s‚áNµ6cıNQÕ(ƒkX¥Vš½u>!~,-—s³#<•± ¼‚ÇU=Î=ÖmûÏ]§@¦ÛÔLjÕÆÅFò³ĞœÅfÅ¼!íƒ[¯ıYBeÉpŞA‘R¥K%¬6¸1Zokmì­–¶Pz2+Æ/›i£ÿ¿X—zØ^nÿ¼õ³æ
ÙËô½1#äµiyO‡7‘¢ş‚Èî÷a/,Â¯…¯O‚'yúÁë™x¾˜LIÿ©K:6SèµèPşÛCYZ9¹nãˆ*¢½@œ/®Ã9Lál÷Šdæ²j¯rßw2ÏK¦€cß,EÚ¹64İdt§ÉuVyoi¿zz‚yù>\ ¡¼&YÆ°˜PÑ¨ÚÌ\‡kT4 æ–ãb´ÏÙ¼¯˜èow v6–¹¶µ¿<~7ğxß›¾’{S£öóHÜZQ­’ioÜ’À9„èŸ€G ®•1ä±İ›Ã,Õ¼
Éµ°@[Ëä%8¦9=6ùI°.ñô¹£ş3îLÇ)&¢×. Õ¼°í,…{9BsŞµ‘½òĞ_pí³ôµoğÚÈÇ1¨wêgöEåÊäÀŸ‚ñoêsR
l’ ‘Tãğ«ë%ì›‘—}ı>Ø¶ú*˜tòßF÷HÀgYİ‘Qı”ÀğŞÆQ"ŞÙF…ç'IH,*ò‹×ØˆÖ AR2Å—™°ƒôç_umü·ÕX»Š•8¯ªnX¶œ0DJ¡ëe°N¿ç 7•ì—TøÇ£ôZoÖg5J‰ĞX˜^¯Šê‘Ø¸ßUÁOb­‘Öögêã:Ò•<½ğÚÙmÔ’ÌdòœĞ›ÇİÆÏR~ä¡«Æ¡j†™ÿµ*ï˜Ê2±'Ïq'ì ¤Í$ÂÆbç”«N‹˜ß{àºw˜s²qsc'’ï#D$U-š$àO®ÆŸ8Xïû+•{>:7¸¡ùÄ`Æåˆ;{‰ZÒ74Äò Ìe(i^Hà~#"QÂîíºç‡«¥¬9÷fÉFò>“íêz¦º°ƒ€@Ô¦?á½pû£%À˜¯
bœ(öÑ6u<âÈ¢T¡tu‘î 4Mİ:©Çbº"3ª‘İîf¹â%Îs?®P•Êİ8c|àb£¿uÜ§špRy‹y‡IûÔşQnÛƒà­¶tØÀ<T!¥•ÌÆ:h¨å-Ö9aà#>
ÂfuÒzöà:³½T°’˜ibõ´Ñ~yÔ×ù¤É!Ÿä”ŸŠrèş¹—™7²ü>Çğª©kÕ#öï%ßÄü¬u'o/¨ª¤\g'Ó—:’¸L°“Œ‘•zã¦0€&Yü}Ã¸‹† ®Âª¯s*¿¯6¦²šD®ˆŸS…îøÓ|At-jºÎÔW÷Õ·ºb‚¸J3!©ƒÏ¿Uì9©Éo%•Q©@Ñ(uic)zD[ƒt¸7ğÂéó5(£pO‰JÃÑ7âyS¥<a5H4şMuãşÿ1é~êĞˆÕ¸©‡ïxÓ3"\3ŞØèImêŠ¨2F±„Õ<”øşæé‡	ÕN»‚¼†İ0êO-%Ì†Â"Ñ¬ƒ®…eƒ²lº*Öa:õã¬YÉüiØ#…²¢ö£ÖÈÀĞOê_X×A2ÉL\90ß^[Ê7£HŸ¹xYZ}eºÌBBÅn¿hŠaS*.'¦®óSÌ®¡ìÈsU°'E:Š®s:¸ÑeÙákdb–ŠßF>şzjyòà=oÏKş«^³‡x Q¹"1ßŸõ"ÉÖ¯,uR4nw¿"›H/SJ!z¡ì…4}Kí~ã,ğdÀôò'¨>KÁ)gÏ„ø€ÒÈ7•@G[|5jÀOøtu=òz²©‡d¸Ùîúc¯‡j>X|°]…–ôjmöSTIµ¯×~ùjœ•vGm¦$hMW)z%ËnÊkp¥™8ád¨?˜E™÷ı©\¹“¤İ,OµÙxÍøş/øúEá­¨dÌØw…AóqAÛ (ë)‰ÜêçÊû»Ÿ¼LqÓ‚ÁÊ	æƒÂ/Äû{ßƒ…"†ío%aŠœ/–]¡tŠNpuÎp¨?~‘ÁÌÊ
b8P"£ç¡f%÷hû¤©–‘‚ÌïhK‡Èï-±w$+9çàâ†òoïÈXşªƒ%a"”èlÅY!K™û\üI)QZ èzkå
~¶=WKĞwù
á±hîEKo
V*esiâçé«÷•zÃëï¥ÅB9Â	Ëã-”øO¢X6[ŸĞÆ[4Ú–îd÷£ %-ÂzÈ½æ‹˜¹†{íÕz34Úªöhìô™›{:Æ1àÍ¹@†ÏŞ•-œQ2p{H=S¾/é•ÍŞ*¯È7Î†ÆÁf[< VÃÉÖ²Ø»93th¯ŒÆãî
xjyÇ&°Oş­²|ğáQ³*÷š§¤eùÙEÏy/Î£¦üR±j>ÇI™µÁ¹§íÉ@’›Š®Âöã[*¡úÓ¼^O{'İDzZÈ)%{ÃP:¡õÈx½SsÆW6btºÊ‹¶¬Tƒ™=W’sçKß»úpÈSÒC—½°”Ÿ´-/¾KhúàoQ·LÕl7ññœÈ	•%E”u
Œd¾v
ğ›–ı^Oõš3¶ ¸x=nt76ÄJÌÙuT„ßJOªß]]x3ş‡ZuÛH½Uæ:¯õmÓh	Bjr à@²“6ÀéŸöFÁš^jƒAk6Ş–´Êî­ CÿxtÕØĞ Wõ"ZÊø+z„í‘ÊGÉ•îh>tÀNãé–•EÚ‡¾=ËÎ®Â/Ş!É3§<{ôúëÍÉŠ nW ‡ µ.ù·3µ³ Ò•ôz³‹ôPXĞX-üÈâ#uoI
4oªŠ\Q
¼©8]ş6j>êıN(JŸ46ZGë*ï#®j§%ü	3ˆß:-Ê@´~£,R_Ò£ ~Í‹;ó~Òç”5A³^†‹5‰9ÒüĞ—OO½×7Ï–°„	#É©?•%ÕƒÇ"xî‡Ğ‘…òÎèî2Á…ÎYäx¥İ ¥¾‚œiW¤[Un<Ÿ¢_üo“3bv”äc-Ä³ö»äz×’øµØ|?òC;õ°v3ÄäÁÈ’çµì™ïÙáÿñ©å#aö©““äïæW…w—_ÁäUT±Z1^-	`µ]¦X0Óğo(,•2wŞU„í€ƒˆ`^hõAÇE¯2›Ü£ŞŒ?£Z[á5uTËTv"@ëéƒÎ-có!‘6[l.ıA:ÒU¿`@Vm7‡úÁKRD
ZO°LªA¿¿y°í…²+Ú%@\§ãœ\3‹²‰Î‰¸åKøf2'…{¢ªS<g>­BÊq\x§W§–ôv±Ü·yÎ™|ÿ§Ø*|E\ó!†×y
HmºWÄ™˜=»CÔŠ&¾l\€ëG-ó»OìÌS-ûwTïÉ¯²Æ9w+PÇq-ÕK£"‹:ó İiÖS'6†÷@xQRI}È‹;‡
˜€§	W¤²†èø«—çÑ«¤V&xUíNÌÜUH|¼}/ûè.]˜0Hj¼ÄõdÎı¥:!LìøœÆşéª´±°¹æ·Ÿ\#¸S™ıİòÍŒÍr™‡KòûÈ¿@#K©Ó@œÊÆè««i@  ›xÊs÷KĞÓ·`w«‹ÔGñB¢– *™÷»ŸÀa‹~Å4Œhõó	3¤÷$Èè¢³šÛ‘[>Pâ/KÒØ¡<•o#=ø=ÎŞ]l¹ó‚ş+İBjª±!eÀğlæüs˜fz°ïÊõ,Slä[Ê…&åI°~t‡«¬¥•ïÒec”Üº°!ŒÖÓs5‚°|æid@÷pf—%˜SÉµ´š‚:È…l<s7ÌŸãóa^ú¾\Œîhô•|ƒ½Š2Ç{7É¹8™[eRã*X‹ce|j8^t¼J¢]1ßP´KfÙ0N RLhrâI“‚İÿ­ˆGÛ_q+ô³ÿfıâ'^"Şy|b<Öm²ÑÄ¿øåÉ(dœòÕåû÷zƒNTŠk‡Ò0T\•}¼SXˆyÔ¨lä-şMöÃ{gçÃU¤Âfqx~Î‰ú®mï,ûyÆæºeí%æ|±òdúĞÁ•.F>Zş™4­ß?²/û5 XÆc¤Búƒ3Ä"oa$ËÓ²³.•(;!–§Ï´ÿÈë³%‰tş;@×7@Ê²l*æ1,ï+"¥~ãQ1¡ÊÈ}P½-æi=ùåÙz¿Ùæ@ò}2‚KR*TšDœ¯j–útG3'à5†–6ïåÏ>Z}üTïƒèÂ¨oüŸ0"ÏçÌÊ¾ç¬>:ü5Ï:ğCX²r1¾¦¨§~3f~$´×¡]Ğ³Ì÷ÒÙ®00&l?óñcôXB"Û·K³/u‚á¡RÔşKÔO‰kèï§®C&X*ZF|Aö’’v‘â›èáSæŒpy	:ÆËŸ>P—JíöZØRè ‹f;)ûæE8M ½­¹Ù¿yî»
W>ÓÿÜªà	Ée™òİÚ·RÄÑ¹ÆË…× ‰‡s^!ücmàdêİãÁûb	G—Ó±‘˜¬©« %’Ä‹¸Q†”’Æû(ÕÉ%$ò ¡µî@> èjR
ÚÑÍ¨Éè#ï3ş{-¢—cc`˜°«I—C‘“ùİ‚)HFnûüÏ¹–’ã °C<;Mæ.ßïb/Q‡‰íËQ}µFb!wò"¡¥Š!`@¥~0{ŠLµÛşšÀğH.h³,l°u²Ú›ÕÊŞ{}”²sÿVº</%æ%À¶ üÉC¯*qkWÀt#4·šgÔåËøŒƒM9ôáZ	{:¢an…×´NUáÙÓ™ĞÔÒ„1µJ” >Xl[íp÷¬İËjr½›áÊKN£Y?I|>ö¯^_³­ş rëî)Í=mùx.ÒSIÓÂ§f4‘²“§Ûû1NÈf®Áuñ´.‰õ.Â²*÷ÿÛŞ”ìT%šì*é™Ø€µg›Ö®§h·šår	{î(vÉòÄñFmÈl‘ÃÜÙ=Ò±°L5ç6-š›307ÜmûÏ¨Ô„6u°oÑ‰¿õ–‚œzJ¦,bğ¹HPcÉì”×÷ËÉò1Î%›$Oà_¾ ó=ËE½GH0Ú}™}ÖÖ=ë‰…z14ÉÙKì{ŒoPwÉ-…ªúC$oŸ‘ß5Ú†ãB8>FV»R$*åfæšDÕH£ILp˜KpÄÑFáŸ"ó¶+Úv¿ÑùüB7‘x£/,<‹Av‡ÈtX‰…¡²BğÖÛ#šâ\Kå<r-5²Zİ©c= JÊPˆ%ŒªÜT½âÿ\·bá‡SÀƒòğñ>2ŒóìÈ>wƒÊ-U_V^Ê¸ËøšÎ‘
!B»£‰·è¡,¶;¸—§“]ÔD•ÈO¡$˜NSHN‹¸Ùş–æS±vœÒØo"£ÉsJd(÷6ÊÛª²"Ê@œ%‚ñëÉ_7¢%¦väX°ÛSyW7DÕd>Ú}ô¥UÙ©Øhé¦>,ı~r¬D½Æyÿ©*I†òsÊœòAÆoiE«ö ”ØĞ‹.³ãœR[5HÔüûifÇïJÉ¯Ö#” ¨trT7BÑ[DÚlrDúê¢^ 1V¡Ÿ r«yl¶à'€[HàWÀQ8qÚò™¦˜E2Ér j9›Â·T_©)j÷’Cp‰rŠxÇÖëtôª’ë´°&Tç8ª|ß.–¤Á&öúd¹ó‚p0›£¢F'øúƒîÉ6BÑP°`»œµÅÇˆHs³[ªF|^A8"v÷¹å„õÃ‡ $ÙBA=e€Å=Ô•¿ïäa@äú‘;î¢¬ĞŠ£zã‡(ï9IU‰[A9µí==? šÙïĞá!94Àœ¼ã…Pö,”æX©º QCÑyÄ™ˆ­}µ~ñĞ%®YAX÷¾ªˆ`ÅÀ¿£Bˆå\èş êL]PuË(>•F¼;»^¹¼l¨ªsÒÖúYKêÿĞÎ[öqy‡	%¢ÏÀI¡LuLCFïè
m=|1ë8gF¹†~*«à7,Ì10›eïÚ‰B»”R[Æ¬Á¯Zİ®”V0è:Ó_;$Wİ6NMvd­Õ33Ñ‡B–„0/\¨(%IÏPDØ­#(¯?qq5Èœ=]]Ç²q×úyæPfgÜQ.CXç}M^ÀÌ?WçkC¥ŒDÌe¤^Ô—™"¦‹X½»´ŠYdIäm7M‘ .Œî¥v½ĞZ¿•2ºôóè Õåešñşï4$g&*³9u)`ß³Xá9nÚêa=•ô}z¤QUÙ‚kíê±<ámş‚1½a„¯……
€øXğ'Öò1§Ñö¦¸Ò~úM™±›@ûf@)µkĞ#‰®2si¥ñ ÔE©²Ü°j@ME¥ãšHº±hÙ†O¦MU³šBªÍaM›kÖD¼¤”‡Úµî*SFÚC—“ˆ9ñw'øûØ¦
'p=Ç®°‚—f8Ø¦2Ó½Sa6>Å?D™µ¸dÛâ™¼Ë4sksGÖTèk|G*!ém1ˆC|vcİg1¶~¤’v+A+¢©°eü½jI)­M±‘Õ·•5<:œB*Æ”zÅñ :íäÒ?½×a%zÌ°?BAN£_FDĞÙ KU)]>‚s“ÙÏMş6\Tj5ép´îCdaøs°Ìøæ—ê^xm´±ÿ@úİ¼gÈ½Şfeİ*á–Å*.Â9â
U!{íchÍ¼¼ŠÍ¿vÍÁºpMíepœ¦!&qØÎ¡î]óloûæL¡r(“|¹ïÏßVÍC·„î”‰Vvqß­,A9!Ôğ­=ÏJ¢„y	xbÿ¼7ƒ¼|ä›Uo&†Òáı}MƒS!—%¯¹a“á%Ï¨=€Y /¡Ä¨¤Şy­ıeáAÍ ?cŸÎZ49 Í•-„rQø×gE‘ß¾yîÎ>p„)ğT/ñI¼ŞØî Ënxj….ˆüÿ-£1÷k@“ó¼üÔúDÆ°RdD¼à†ek(>òE‡ù| y¢Ñ*N6Ë¥}J[ÚÂÍÖ©±&æ¨LËµÛ=oøÓ,däzF'ßôG1ßˆ+mÃğG1[:”¼BˆXû•úGTÄ™|ºVËæ
nyØ~¯ÎéofOÈå²Ã/îè¬Ã%Øi7ÔÍŒ¯å C¼›`|c3+¤fµµ¸£¾´	Y-kYÌĞƒ$<ˆµP"F/|%ÖìÖ&"fRÈJ+˜#"ÿH)£ËTb¥½[·!˜W]¡ó©ú¸ÂKQ³ÒËbÅ¯û4øcÁm¯4KÛ‚=ó	FB÷6‹b<l	Ğ½† {¹èjÂy‚7¾!76-öYùßÉÈië÷üW£´û’£úˆW0ÏçH_cÙ”+‰S6g9ü|If5üf¾Y$lLÄİ~'>ĞŠÂû|{ù•PâİMW¤ÅáıÓÎêßE½pĞ¥'‰íé;P·!8êS„M?H|W¡‹™o•.¥¾":¢›i7`Pd®:£ŠåAÀNO4N"ï‚ÕåÊéâ,MÑ ¾ÂC—{¨bëF³¶V’tfèo˜¼[Ê™ÒéÂ"¥dıÜš±Ì‚ƒ`uFZÀÆL‰yDãÌ—Wò…Ÿ»3B$ÊZ»{6æÜdú•â›kÚ]dízÆWóÚaal|=Ğoª€õ¼í%>Iè'”mx£İ\ëb’•Í¼xñ;;(ÁúÄŠ8áA–‘ğ}ØSŸl˜—²tÅ©Í
Cï=Tµ–êzdOjŠC±øä„³ö‘¼§^«\şo;D¾Ùdû›OÒ½µ–£lµ‹º§…¾DÃ<¦×Ö2üš­€%GS~ºğC‰ô˜M˜ëBy°F!2şH°	ókq…2Ss!ÖõD+L‰OXdà Hì¬¥öã7ì¶Ó=Mo—¦D×B@?‰Û–ıÑ7´‚}	èHTPL/Â÷#4æ©¦Èİ^-i 
ş— …«÷œªuO5ê*±ÜÁıi4¿ç:É>Epé½ı¾õC¿_g‹áø‰ÌşğgŞ	)W“-m´ûË;Ì“¡_w¾
ú©C³“CÎk¦(ŒM³²Èˆy®½øNËŞÀ‘ğ¤›¤¥ÈÍäaañCÁÇ0œÚ¹7¸·I'«-ª7vR]2éâeµğ®¥Š1W^ÚTaçã"¹³G	Í«‡v¾Zk}}\œ )’ÅF…U×AÇ1Ÿ‘Õ*Lg£XfÀe]İnØÈ“Vúh7/ ú#R¶xfÉ¶5öeıÂ%*S^<ÔÚg¡1Ê2lÔ8qíV¯jyú%$œ*Løu˜îÎ×_®g¹ÁÊó3İİ,7RË¤g×¡2¸ö‰Ì`œz’u1ƒ²á–ÿI Ö—sj¨øÅ|`F|ÉÜ^WÑtpÅ˜lï:ÿI¤
M#÷wB ±Šns-»¡	É"RâCxâıí’™¤Ği$G(ZQ}~9J†Rf´„È<?5ú˜å‡Ùw<¶±¤\–3ôXkôÄpYöß(7üA]²%¤JEF)0¬ƒaÛgâDOtµ¥Ï`!ŞEPëÅ„šS\lQ+5¾ã‚–F\]-k®­·Úˆq—}CÖCäÉ(¹ßISŞ¹µT†"V± 
º9Â O’#ì/»@Car08÷3FÄT¼?ÙGd÷[$XôèçÔî‹,mú¥¯fcÅ`jš¢ ÖÇû×¼ó¥÷.jåì¡­¦Ñ~èÓ991YDêV—ÏÍÿv~Åß-'çÄ½qÁsH›´	aË·WcÆ(7è~GåÊ¸hõ}Ëû¬Ô\şåch7Y—ÿ]rf,b–šK¨X‰ò²y%a­â0n /µn'Îÿ;Ûì´uˆÅqälõŠR»UÎë êèvÚp'üyPi£‘oÚ³ê¹–ñr€ûŸ%¨5K|"]£3u$mì÷Àğ,Î…9Œ•]H¦,LİçÅ”á°¯—TziåÔ†ïSñˆ_šß9i*-Ğ‹¢FFA–Ñv¹3
›‡»Ÿ&8µV*Gö1¥Èa“|On»çH²-, Z"æıÃú›X?®ªåö*Cè-]ÉØ>dišL™SS›ÃãşĞï:Ç2Iu'†]k]ÛªµüÅ~EIpÖ`p%ègU"½İ<à~İ ñU<RÆ[ø~K†H¬2â*/wp”¬6 È"oº/&ªáò1x’dW‹g˜-] GÂûò›õhèO°ÖXj*‹4ßHNa§œ_>1-Ú`¸2ĞÃã™ÏWŞ»˜ürß{¬¡x–ı>Œ4]_›á'6ôÜÇ.õnGĞ^±¬·•v³ü×UVõ÷½—ëkwâDÕõ»D…A®Ñ´/ñ¢FL=1l’¦a&„,ZLª fr±è©iÌš*sÑıxßƒpRDL¬­ÒFÛÖÔWN y6¶WxµÄ$•âµì}¾m­3u˜¡!)“ã„³®¾L£ëÆ»<sìéù6LˆĞ´?d0“I)–¦8Ì&£(	o¯½cNğR ÆÂÿş¥ÄB´(Ì¬†ád„œ1²ö‡ª>š,/•˜*zÊáxÆ]ç•UDBo%ûè6¿ÿ[t›Çuh*°
Ç#ïŸKr&íjCµò­^”İP}Â8­ñ—´/ë “7¶©½æÇh±=£Iåèn¯_W¦¸÷“ Ë+Ñx, Oİ–±lï—ËCöV9|D¯Ï‰lÚ€'{Vu^äGµ,Löã‹…F>tĞf 1¶ ^€¹5õÌƒ³­ÒÑùQGİšø&hxÉ°}"v¬,yLş•SHÚëØİM^PëÅ‰§úáì!0õ¹1ë?×?8F¢Ô¸½Cüı. ŸÛÇÅŞ*ì!„ùƒıß0]I_CŠI8•œµ¥+ë×³®¸´t»»û#|cÒŸ‹â }"DZü	-´ş'.Eø1¦fM?Âô-ßaüâQF|NP³¦sH^ú6Iz¿ ¦mr´%õ¯˜MÊÈa«ş4(+¤ÁDÍÚ–…zâª^§ÁÙeÒìËN”ÇÌë“^%–Çï«Ngş>ÙPÀìÍì|È’ÖZè–zÑUF¡3E!&àTš$÷+Å y5äFx°–š¡6òZ|sD§ÙîÏ¾RDw<Ğ6§Ú“-†©Éé(v—ßD¬{¯ìK³§£í±n/¾•´JŒxÉ«/¬Ó&)úàw¶ & Â¸¶ä)ı´‚¨î7µí+0é–¶T\Ù€Ø8(ÍtîñWŸT’ÙÂ:Éª-ŠTİ™ŠD«2)o(ZXE¡¶®ï­?Ô8¿l.¬‚Šx!·dŠİ• ¥ÛB†5ÑIü$|=¸ŸU 2Òj ¶›CÓëi­fO®,³ô³^g_Â‡í›Ìº{ùãô^t@vSÓ\İó¨äJ¼§u‡ŠBÙfk2`^å! N¼ëãq}F*5é™!'‹AÁ	ºU¾ÊÉÒËš;ó±¬[£äş®ÔÛêOä{ó¶ãoıOÈ®
°§èŒï÷æ)ìKœY›ÇŒ	tñ2b•Ôâ­ºLªÄ}³:³ì=Í†º:m @l¼Å›ÈÅB½¢‹ĞšØ¾S‚İûN¶IÏô2«Ä'+¾=‚l7j"}™ˆâKr@kqºËåñ<<‘ß×µĞõ>ûõihëÜI‘€cA±‰Œ(ˆ-Ì°
Âİ0]QgÂ2â"?È¹Fuq^‹ğ…IÇ<S¬JXŠÌ‘™HãSJÙ_f±8éˆ	-â2×¸	LŒìóÖHì"_Õm
ì¡/Hğ›t£†ñêwÀóºC%UQNe\3{®‘©'<ôzÆˆ±õk@$|ª;­†¨¡eÜt:0åƒ{ÉG§@çôá+ìÇç-,t´×(éÎ«ÒÀ¯w.„EÚB”ı}ä±å®*ùªyÎˆ¿˜Y=c(Ñ_5u¬Í\ë]Æ¿U‚Gòˆ^"¥¼¼³—Ø¼"xrˆå¦$–ßœ´Ir½¿“ÇŒÖ!{-h&ö}Oùìğ*r^ş÷ú¨pMÙ19•7æ¤şYIbğNF(lgµŒ²ún½¡ŠlEÒü"iÌH Â˜ã²>·p3»>pŸ—é?àNê\ÿ>’D5g)7fCŒöà©7æĞşãÙ>€h²lAë1Â EÚñŠÚ¿…“íIåTÒMÈ¯QÁ{]îİyÜ¢êNJòa<ÄŞ @oèPñnÆ«™¿ ¨w¡/µŠlTú—ó¿Ä†_ü8[ª&C´ª4ÿSİd’ûôUÏôOcLiëÍ‰§ ¬N‚¸Í¦W@$È×%ÂëŞf€¿»ji©÷şºš	¼!ßÑ6Ò”špT6ÓC OCkôæËxoaT“‰—ı¢ ¾÷~Fäh~Gˆ Új†|g¯ÖZª´ôó«9Â,ÛÂõ£»°T-…È[¤ïdpåĞ^"ë¬GÔ#m+U”j¾ÔØ›¨F¥iø}J¶,£¤)`«ËÕ>Õş+èĞŠp	ÜóÚ^ú±	Ÿ©€nèkåN'“æ_ÆöÎ–É¯‡£íoZ7OÃÑîH8†w,˜{ TººÛèD2ÁG…ÂÍèôl}ò§x™‹ß
ø½”ØêI$iŒı`ÙŠ(>Ï62©áigĞ*ş’¾ÊÌøË‹xdx56òê€®åıİêë³|B©j%²xm‰ò7–ştÅşì`ïTPì¡Ìó»ªêà[)f¯ù?jÆ@\Ç‡®–Kâ¦
Q±H)\€¨o+ô°µŠA-]k©SsrXSI:Ğ˜ûÄ°ÁÔƒ¬ğ,ïiEÄKKêl†p”õö´´îT…VR &|[Ÿ´È€CŸÕ@IDXârIgœßA±NËÍ6wˆc³šN.vß×ç»uÑçbhq¢Œã9¡>@ÿû&™ƒ]64Sntøİ<^•ùş¯ñË©€AC×?µ‰¯z«èÑp¤ØB*“u4°Dõ
]ÊúD¼‘ö–ÏÛ#³–Úq#_Áäi‹zûÑ¿ŠLa¢4$0ÛïXÂŒ*u%ÂcõĞ{Ge hÌJÌnÀ7@Ë[É‡d	Yuw¶Â“CÏ°¼¾Öè€CLÌ¼é‚	ª*ù{u€¥î—WÙÖ0à½„×òu¹í¥è1éÜâ˜"u[¹c:å	ı«|Aœ9“×‹leğïWÃ¡æÊCS¤×;¤«ş.†êjŒDO¬éYúí'Äl&uc/™%éú1›1è´«Ÿ±ddÊ(»¿ãqÀäâ¢lâO.ï°ˆ…!ã]°ÄÛ¾<Tœ ½
iÒæërT›ÕFƒ‡Á+§’5¢$Bj§Uˆ •ŒVI.ìYV;Áo@Å×Ş5D9¼UÌœüvzİš–?¨~‰À<Œ…>iP<J¼2!¸•ÎYh†6­ØYêB—Gô|Y€ä¤v!W‡ŞB+†!ÒÓ	òBÚÛ*·t	ä¦y%ù.íGğOüˆ3»5®\5²6pRñ ±æ;ºZï<ØõÇsĞ*)v£åd‚ae©)ôRN¬\”2¼]JÛ]4· Úk9­iêša’ºîïpešuùÇï tºQ>Ñâ×©kÖt>â¦ KÏ, ˆéÃUt*ìĞœ!Ù#d"£šMâ2·ôDÁW{&LæğHZ._psªÏGbsIO8Ÿü¸°0¥Oè~.ÛßMün~@íeÁøTìÜêNj×¦á[Œì¦Ñ
l|¼+0¤gÙU–õÒã¹ÒÑ¦U7>ÇEK‹]@ıÊ½WïÁÄà!/¹MoÑ†HrBAÉ”ó®;àn:IÏJ3"Ú+—“ò¡Ïv~;@,\ÊŸ«‰£0xœ·›ª-KZ(4/—(ëtÂ%«ëÅ4Ìè|È{®i†„lı3‰UŸ8U8U‡¹ƒ ä‘ŸRîĞm÷.áˆZÛÎÛ
VOÙ;1[(ğÚL¿hHd6¤g	Ñ	*²•Æz‚µsAµ'h Åú¦ö¼lŒöåSòç	4jÖËcõ7†áÔÓã˜uaôõÄÏ˜Ÿ÷ùliIœ$¶Ê’VÂçí	|0éÓÔGAñ>¡´váàln6÷hÁHõSñ;TT(zp(ı2£¨î~”:5Ù]—7°–MfÎJÍ¾^/!Â,‹¢°·şWx“çÖ³>»SzF{t ë®0Oˆ=âì×ÔÁjšQÑzFÀØş+wz=CGÖñè¡ÄY=ï^ÿÃ{PøpÖ²$ißsvc|×ç»MÏJr€m“æÆ^,•ÁÁøV),6Û©»sÕ€ûõ!œİ¤Õ‘(Î4=&Û¯*¢#µwÈhªİÑêğ©‘«Ç´ ï‡9^ı„´¡ ÷^ˆzJbáÕ6oõkæ‹vUÊ …ñÏ‰¤ø^áŠÃhe.ï§ŞxÿáYOo†£Â}ÖfqÜ{êšŒ_iÀl¡Íxéx¿•«8|\pgNÏxÅ%v-Õ¹C9?=f“ô`½D,FàæGyÖwi¥[DÒï½Ò¸ÚZ»ŠÂsE×zÍêl=âbÄ/M}Ä»ü/0}š1¼H¢1´RŒ,´Ç;$Á‹˜<Í’Æ£‚¾Çg^3\¾#´®	˜pßµ?üê!³©å¿‹›®•YºÎ@ñÒîÌ¼ã”™Ãˆ3€€·E@›ü¢ÕïDïÒ‘‘ö³6ìğí×õÚ½óDMm%MÔ£!\¼–r*çê‡fN­†0'wú3D²ôÌû£öYÀ[¥@—Í×{¹ÁŒ}#¢ÔÊEIÉƒÉï5âdûñÑ@èĞ{`lKnO+¶ˆ!¤9ë;)àBòù›#1ÄXÎWp¨Ş®€BR¶7Lu£ĞKy¬dsB1än{Æü±n <ä¼JùC¿:e5‚€.òù¹_µÇÃ&û`Æ H0ÔU|âÑ©¤Æ™6²"	®¼‚Q¬æ‚®³æˆ¦ı”'±!š‹¹{®A¼”;ª¬2¸@'»åµAi9²ˆ¸	5hÜ +ĞáÄx-¯|Ç™S¬PD˜İ´$V!+A,¾ˆ-ñçnÉğĞ8ÚáûˆhçTË+W°NJL×3jlÜM‰ïñõ…\ØxŸi…"OÓ§¥-÷_¢VÓ8½B´é,ËT¦º{ı»¹ÕXÌj,§3Ğ`PÓSóşI|ö IWGESav·¢hîØ\×9pò7Üï8ĞÊÏ´DÄ<G}UÖ†d`U«M²)8<œQùÑUß4üó­z¹yÍ¯æ…ŞæIôÑîgœ$¸ß?¶z†qq4íğ?1RÎÊnYĞJ}$+ÁğcúûN#4bÇÈ7q¹EGÉ¢ÿ+›`3t=¿ğLĞnºÁ‹vl(¼±‹'ã@QêË>5K¯Îê™…ÉÏm1C‚[¤L–¶8ÉF3nGu*³F!8B(÷õ&|H†«s•AëlµwdS^OoCÊÃ‡(  uÒÏwc”6İ[ıh1Äûƒ=/#r™wåUšO„œpi¨4(5ãĞ¯ÇvEbœ¼Ïº¥J$d²e«!:½Í!ğ¹ä5ıÁ²îHû,	«-Ë:Ğí	‘Éu3'äèZPæàå¯„èTsçjÀç»¥'eÒa›çïÆ
¤lŞ¦îëÌ|Ì¦gIüşw€ÉëDoªş‹‚¾^?/³Sx,šğmšlC~[%~8IÿªL@™ï¢*Ò‚ÚùSğvƒN	r1XjácIEI|a·Ïıñv&Fş˜Ó„m:¼İÍŸ„v	êUQ¦ˆ.ùí›œ@%iX¢e€òT=åLÚ,Üô>Y,lpÚ®ø†ÌTn†­Ë`ßé:ª{á³[hn»ÃÙ‘üªE¦
ïé²³»å*rúâ²„gn*Jo
`làûiN6·Ã¡$MôÉúÀš¿Eû=OÆì>}ª»AYÔT°áçÊ¡(1†°É%‡¬¶—œVmÇ˜ÿ÷ğ(³$hUµc`·dYSÊ) Ü_ûvû+;×`º=Cü¼™n?Ë¸’š“…e'%İ¡ŸÈÅñ>º6ffñdw µ€¨Æ4$@ŠrÊbõÌèqÔµ/§ócàA.©¬ËE^ş?@Fg‘LøG°.õ&m;n4æßïëö·:³Ğ§¶q¸çu£›¹D: q[Ë›,/M©AÃúA!óäÍ=µº²›×^l«³1L–haâÅçùX‰\ºò	§96öÛàMÖs²~Nşy†ûŠk˜q¸÷ïÿë“Û
‹`c¯v’G‘dşmÓO5íü³ e÷ë‚XAÖ¬@]\ 
û~„è-yÎxê\§sé¢Ã}_Í0ª×Ç>8IÂT3…léE »É?ïp$—`ñI#µé>Infóô›°êË+X Ìí'˜{"‚p9€Ú0~ªs-¾´.rş@¡<EvDË2›|wÑI_Å‹Š/Àu-=ú¼;î_“TúKµéªÌFe7X¯{HşĞ\ƒ„?<hü‘•3¡y%ê·îVÛ”#._+!0H¹óõ"ı'KÁÁ}™ıÀúŸwÈ¯.m×¼ÖDÛâó»±ÎÓÚà™û†°µÄ«O¡ˆ|ìü¸P-K“éIŸCDÅAÚw¦„ä: 
Æİt•T7jë­'\ûx6ŸÅÏañ&Ù6[šÆpó‘/¬Ù}Ppœõ²o÷ô+CZFD¾»ÜJeâ…¸WÜDqØPGày÷!şÀ¬rFPJ"£Ú,l_D_¿®­lˆõ®ğ ¾¡Òi_Š“¨¡*
İägP~ı¸¥³-—çÒ¹Th¤²ÚåÀª«‘DÙ¿ÆßD—À)û	ol¥ÎG˜g¹ÅŠxJ>6y¼øj¯v‡$åÙ§B×“’»Jwr©o	<¬Şéí†b"ø9ÿç»{¬m+wªóÜ.%Ñe|L§?º´õà@‰Bgl§y”àd¢
}½Çß#ìådµV8Û¾D£aAOWŒ_g‡°§Á$sÈ1.{¢ï+6â«+/Õ	ª5gc$ïÅòJ’ÃSCtö”PN·HÇ;Tù5œòTß_æÕxñ¿;¨Á‘‚@°]Å J ;ŸAÖM$)ï¢!uMßw‹CÜ™vÏû=8îå]{A’<’CãëãwhL]åW&Ô°Pe^!tó¡VZbß%ÍPbúbZÛó@MsT5ÏYàVÓ¡áBQ’l{*(Ä4¸
® éÌ^ó6¨SE	:XÌ¹LİÖèQŠMuwÆÆÂãœ+ò5‘u¶ˆ®í‡­…âwÉ¹*Vy,ğÛk:^~uóZ–ñA¯”|EH«ƒ,vÁßo._AqÙ¹¥(‡v_Ğ‚œƒUù3@ô‹oà07T}ï­»,}¢ŒÅ¾Ûz<õ!µ‚:’Î´„qÓŠdRÉs¡/Ø>A’ë”,2ê~ì«w CââÔÿÆŞõ)ï2»c™9å¶A)Ì“íØ¦çtf9%1wb„ãª’5;¿Àæ%Dí¡õø/±'ŞÕØÿà2Dyqé#&<Uêç•}ZŒ8Ù„Ô)!d™Ëp®ä™oéÕ!6âMØM9¥ó†‘ÊŒPö{èÀ'òYS‚.ûK±]Â°b)<İİ %iïKèDËU GX·É-H>Å	K‰k´oXÏ{Sf±$£@wÆÛò²ÉIÈp¢-2b èÙV–ÕŞÂô‹=ô¥É˜Ê5]Nƒ.*W7ÍÀM§"íÇˆB‚× /˜ñ[{S†ƒöÔO†{ÓMzÀÜ Œ_¶9lòg…4Ôg@`+Íœî8oÁ+2› ¼­_([d¿şâÆ¤õn0´‚E7ŒÉ‡¤<Éñ¥ğ\ˆ™wDLL7-6LQ<;ç!©é]†,hwû“%åJï×ovI:©ç¥gl­
æƒAdÆóUà& Æo³¢Á
°ãÍÒT õ¬K¦ ½°n+½ôĞXÊ]ƒ§‡‰áÍïŒÅ.Bä¬^#v6›”h?Ë[ÇÊñ,úÈ¦ª€/½×Ç©o*šÌaÎ"°0„°àÁ·Ñ~ÆÑ<]Åú"¡hå¢¾Pîª$n@ØÄÊ0TC¸¶LüV7ü*-ÜíÖíÖå™i÷óo-ŞëY"Ç´px6{Ú–Ji`Zƒ}«ã0Òê±Ş	nl<qı/<Çk¿p§T|=§l¬(A±áá_ª±üi¼u÷Oë³Id¦L”NĞ– Qã‚ŸQY“œ¦.x‘9ØRß¾¶äRÚ¯®“0‡¾Ü„Ó¥0!€”û“aN+¯:ZOï™8 †…2G“Âõ»§ôÒpã”ğ5ƒËÓP;+*°â9˜ásPfjÎ‡ğ§İ8–áŠ¼€D%¥»Ó+eğ,ç=–•%î¸õ]´Œ6çüeˆ|y›?•XÉ–†ù–Ü¨ÇÆG3øÂòZßÆwŠÏO„1_2Zºàñ÷bÃ<õ¿`ûGâz_¼T®«–Ù&`ÓU	Cåçİ}!BB¼:üñM+^b’Q·4(¡¸ÿ¦1téJ&Ğ:q!|¸0i#	Õ‰ï©v1hÓW²}vs¥SØC<ü§ù÷×ŞòŒöÖ^¹"*ŸE‰HÛvÚ9¬ËĞÕ÷XƒSÑt @‰y»âD5<¤µ~n ¬'x°%Rúÿ¨³&pŞGœ^ó8èKrU“£ı_Tÿ’ùg6 ¡ñ¯†Í›S>ªŞmZ×u½7É¡²$b¦É
IYƒiH:¨›J¢á¯¥ÑIÆ»‰Á‚\¾ŞÒĞ"Iš?]Œqá¢¢‚€^çXl;ª'w=w6’ş“Â,+&i ÇŸî¥J€^ooå^9W¸x™ïâí!na=>03ß‹ÑÈ†/N#hxÓµÖÂÖş$uh<iMFT;î‘¶LÁdPœG2;Pı‘r(–‹Mı5èEÂô7êşyÆ¦8‡ë,àš2ÆSàõsApéÔÒ†d²B“SS‰”•¨·.GÂ.4Yr<åm·{FxzôÑSj´w)Ûiè~r&[AÕõ¹q‡zñ%s?¥?àu["HÈKáş„ºŒâ/"šP4KÌÈã
4T—	FÊA£ü¬HIóİÔ
‰-èÈ”Lø7ÎR»›Êè¶<ÇÔQëîº">6ö”Ø±œô•P†9`÷ÆÿI‚ N»&ej1ê•Ï§o‹ŒYRº…`ğOƒ~M•‡ã:_"s×ElÇq@¨Õ^à"°A‹˜?4WÒ4İ»½»’½¸˜æ`4gµ‘ñ‚±6¹òäDWĞï;ÓRá?òDíŞnÙâ˜o¦¤¿ßéĞWE˜4÷Ì}ÄÃTIõ5å º¨lVU3nµd°ˆ:ö6%O:Ş*ÈMÎÙ“=à`{R³Xµ˜5Ó£/)«kUÉ»¯úœLås;1ÕâıÂ/RXú€a²ıö‚o|Iå³æ,½D"iY¤B€æK„õ¡ÕÎ ›„ˆÈb÷Æyív¶›ÁKa>˜n+ÉØy¦ëFš4F‘sè'^,³­Îõ×‹T¨èæzãjä6»²ù›Eô<dúíŞ)g$\ı·h.Ÿ’&Aùw\,º]7[Spô¦¬-È•«è]xòëKQc‰ÔHÏyÇ\œZ¯îØŠí£××§ºàe`wDwÄuòSÎ- &µİå@Ş»ŞÍÚü«¼­Ä Îc›²·#*=òÅ^¼äB»i¦åJ¯ÔS2…ùñÒõYĞ¿ØW,MYm?oİ£<¯‚{¼Ğ"‘¨¿®ı1º81TØ´Ë‡›µì7±j§ö¥Àãn?‡TÌãäúıànåäˆ1W ßJ­Jëfãò˜|3ş˜D 0è¦Î0I¶^ë÷TÔfz#êÇÁùXPu,¼µ^‘qßtšwãŞÖ8Ó«gI$ãÓ‡–Â¯öoz„+ˆ}Ÿ¬WD„£ºFúdt÷À‹mcèQ UÉË•t\K¹İË‘N§º±˜¸
‘›&×©'Ø–ªÂ^Øø¶.AÑkŞ4±ÌÑN7ôÜ<º ÊOµäiéŒ2ÔPçĞ@Æ¯½xÏ2±Ò¦7    ‚/'øy ÒÍ€^;5«±Ägû    YZ