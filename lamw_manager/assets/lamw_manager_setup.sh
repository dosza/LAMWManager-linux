#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2942159292"
MD5="955448bade2dbe892569dedb223412c0"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20896"
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
	echo Date of packaging: Fri Feb  5 03:00:54 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿQ_] ¼}•À1Dd]‡Á›PætİFâíip£ÿ¦¦ÈM­«¥übõ»SÏRI,7çÖÊ{èFŞ”ÒV‚Neıt [­&’n9Eÿ[\x“i‘ä_gYH¾O"j²ù¿Æ};@€”T5kÔ%ì“gM(ím@ª<sfµ¸S`²u„µùĞ[ÎĞ@(]¶‚Ç$­Zå.: (ÛZi‰D`å}®4#á¥É%.©v¨š¶ÜcœÀñ_‰NGcù¬kÔ{j)èUU‰¯…ì	nË˜Òé^ËøoÖÇ$ş¶ Ï*Kw¿ÀÛVÔ:ğºô|Z¡ûÎa»ä×Ö‰ÛBĞö°yspHqó”\JUhÉVÊªoT¬‹ÈÓ^©lìA¯èOÔâé¥:Ñº®¡<E`…p³¥AšÑI[,V;Ô´àxÑeí¥ˆzàFfs8øÏS+
ë½<e@ƒX¦¾äª˜ˆ;n.¬[¿œ‚:Iî–t§©ÌíF7ØŸyöT,ˆ.$™‡™|¢B¸ÂNaì}2ÄİÙŠ³Åù‚{÷ï={’
æ&‰éØ‚¬_G‰ı[ljÏğBF›ÉÙ0õ<J^¼¦Òót]Äš2ÈËl¥„`#–=Qñ\VÎ=Ğ¢d½<†híë+9Gœ38–‘ã$¶İLİœS]úê¨ÿñÊ›õğF½¶)øªie1nR]™× B¸Ö XĞ'/“l]BÖz‘ËåW–İbnxbˆd–Y@jŒÂW‰0üL Æ¥¢¶åà<X8§ÈÙQ5~Òm¸¥Á)ä@û!GRÉTò-py”=ÜÄd…y«~÷ğë:\¢7álVÙg¶µÌÿş—%n®2+õLÅ)§©‡¤ôbëdÈÃgŸ1f2‹å}º‡„&Ì7¡4y·s(Ö¨ªMÕA¥ŸÕ;ÛçmŒØóA›$Æš­Ëªº›ÅÈœıbJÂió™x3Æ*•ú1³Œ·ÂÊÅbÁ´õ£-eœ’Sj±/9:çqĞS™j§æ‘ò¤ 7-6E
¤qŸõRßà-=‚TÎëBèxbÇ¹íºg¶>£"æBÊ´wW ïO*e
çø1õÂá[İµ&‰§€ğF6–âœÉ ó@UÈo‚•\Cy.@šAúsxeùp:Õ°°äïÙİÂcxLloıOfÖ”ËÉÕ]hŒ»şå.×µÜ?±·ÀWë“óÆå–±)É»Ã™*á›_VEE‚Ò¦Jˆß´çÑÅ.T0Kì÷HİîŸ‚áôU2"è±gùõ+™âW8›¤PH>œúèËe3¸^$lqÊÇ™G£‘%ñª6#Ã< ?K¶Ò-:!…¤´kîXÛ}_.$qúF‡
h(ÆÓÎæjÙ¿›ë{‡şèo?Ô-3ïf‘•¤~Ş.²^í[/%ê
j[}á£Ë¾Í¿H-Ï1šTÏT»Áé?|XzCt.G!¡?„µB¨–Œ ¸MÕOiøÏyÊ¤/Ìµÿ°´.9ƒî÷³Üü!°Ü§šc&TuN éâÕÙ"_½ÔÅÀ>pxĞ©¹>Pv™”M-¿á0.Göı\£Šß+IY;şHĞ}u©¤Îó	ÃŠ»„,	Ğ×²	ÛdH*n¾Ilßây]B¯Õåü°z	8BQF_²5¶VK¢oîB¡Ê.tÚ)ÌÂ­Ëi"ÅúË¦ËÒ7^:à˜Ï»Ib¡[5éH0ÔuÖZŸ?9&Ñ¯í>/©mŒôi¸OÀl-YQñtæ9€sÑI«Ê©GKwë'²&	²pÅû=wrc:2jœ8 ¨ŸñøÒŞÑU4?]|Ô©öÓ™j¥që6–Z¶Šâz›ıc€¶YÇÇÄ`Ø8€íz3/È3à9{‚@Şæû;ÆÃâ'²oº|%î¯ê ¹œX€Ö’Ü9;õ°ûŞ‹6\±¥-‰wBß[øw±>ÙıŠhûWíıïN]»=›ŠfjÌ[fY¹QÎá	‡ÑyƒøEã0‡UkÓôó?ìSı‹Y¯¥£İ`ÁÆS™hŠ0ñË-#é9Ån(¿0„7Üõi8¾lw9gx%u%;ù˜™ü”Oá{ä<F´èR =ÊŞÛíwåu À Ör\=æ
wÅa¹Ğ.á)û­İñQÃğü0ZE³¸Ğq®‚=İ?ÎvÿOá[³LÕÕ%á«¾!kÂk“”eŞj˜GÛ8­
ÆÒD*¶Î;‰é½f}¼nÿ%nŸş¹€®Äl)3@"²ˆÀŸİí‹\8ü£%©¡]‡Áy¡åcd8xM·øÔÍ‘nåxã;Oaù \#œc$Àğ¹écóZ1Mp4†
t†\¾š³àŒãnöÖ~^Âjo¤œa;j[ÊmÕş;ígİN…õê–Ïd1@9Ü—¤ş1ï¾£•óÎI8y—9°‘‡DşVîŒ¾\h KÔÈb'0óêG¦¬!Æ›µè¤ÛYë’1¤}ş±-Ç\f¶Í -Ô$ù5wòm•R0Õğ™|£}ƒlµ£	Q‹nÔ(Ù=‡y7‚¢Ët[+D³ãúkÛ¬‚E˜— ‹‹Ú[J`7}şiŒŠ‚áŞë˜™{XºxØx·šFšŒ!ğ<PYh:tğÜŒÅ´íVŠ°j_Sg%²Üºék™8Yïœ‚+PÃ*y¯h/;ÇÏµfãw¸šÂ×P¾A¡©¿"‹X¦ÛÀ×–L»ü')¡7Sòo!Å ú9Ÿ³IÆÎĞñôğæœwÒ/h³ş,Œg=M½¸|˜8=`ˆ/ÓÀJ^ïQ”Ù7ËŠ @yÅ‚òÂ°£n»2 ßÔõš[£ -¼-Ú4R³ö£î~lµ0qÂü‹ÚÉ¥o'ˆãØ7ı”ˆ8¬d—$ 0ÚÓ°‹`8‘K¿€ë·Òªç9†	ù¸2½÷
©»:áÊ\nkÀ%Y³F›GnjµÎÿ{ûË’’hİ‡‰£è.znà°˜ñÖü5»­ƒ)C'Ú¦¸7aÅ²ÆÀÉĞ‰‰ÔaâÙXÛdt“´eˆé­ÚË-Vı“rNdH†€ˆÌ:Yé\ïüàkãC˜®¨Ùé»S'öõu¥†¨Rås°]f¾K-ß7Åêç»f°ªm ÌÚ±ÕxÈÔ'œ1pìÇŠR°3şûÍâj‡ÙÕ²³,L0?ö·~2Ÿ•±#ƒTá?è9±ª­PŒ(s•·¹UÖ5&ëÁÖ½ò¬Y!dZxÃMSÌ“nÁ$|<ë¼`m¡ş‘;x©ñì*ó
.–5€Ë@û=ëXO…AKmÌLPAeK&¹Øç[ÅœÊX«İaïjÆ\0$S°c},xƒÄÒxìªİ£¶7ş/ä}s›*ÆÖ*¯Ó¼˜ğø”“B&:Ûëõ‹7 ! ²1»¦¿~uP2éW]~™)ŠQÃô?ùF?¤Èb…Oz“…h÷U’LË^ˆc*°ÃuÌp±ğ¹˜Qk~N¡Àt¬|%Ë~8\—à2ò!ÇX(ëR©¸ ²†KD%g\I•†`tşÂ˜½Æ%S)JR^ BÚÙ}P®­5ÍbUÿT¼’÷ŠZd„ Éúó8§˜;­Æ	!Á“@Æ™5MçEvb—xCá¬©ÕÄ$¨!äc Ÿ’%Òg&¼æ¬Â¡º¢ğ’Œ¾Äâ"{ëKâ¤¼v˜æİ»*r|í$ïÚ‰R†p@L6Ï¸!]Ïq–#y£6tÚƒÕ}ö¾nœ&­Aáy"z)Ş(úTğ;êæÅÚIİôĞ«z vÿ]2‚0;Ë®''ˆ1.gO L‚‹á²=0ùFŸÂÆãe›,jZ®,>Àª±şÙÅ(=[©´F ç’Q[_Ö0*¡PªóB.í ö8"€Vx‰Š|d~ï1hœ)ãÔw•0é²Y"©W*¢fe(ıçNjŞË»pCUê}†‡áYÊÜ'ä}¿İ¬ˆ”?µ2”€Mg“QX0ñ	ªK¤ÿ(b³¥„Û?S› ¼d—F8"ÿ'·Mğà˜ 5íAJµ5S>šwÎ³K÷ˆÔÊ°ÆÉæM‡qm,vp+Z¾©B5FİVè~!– ÄUb®D–:
£Tø½3?• ,ÕAúÎ¾¯%2ç´g=â>—jO‰)}½ı4—Ì²›EF)èŸ¿Ñ:>)ü¾RûJ±©×T>v*h(°É®îumj]{há”|Ñ­ÌKà;ôß>“ügµ¿ª¿l
F€D–HßõûÒî˜ÿoÒ%©ı½R¿XèC
¹bA/ƒëè×îj8Î£EÃéØ¯#¹hÀßˆ[tğ[;wÔTæ›>½$éOøñïÈ™‹V¦l ŸæûgfÉ ¡ÈEã9DzŒ²ƒ¡\us7Ï’(Çô Ë--}+Ğ¸d2UhP…º@'nĞ5:ùq†nãZGĞU§¨ºP¡—¹ë³ñ™´.*ÂÈIË×Ïg`¡İXá±.bí<$´o¥İ;Áyû$F¶^äŞÙÛ%‘?°À`ÃA¶%<GD) 9
‘“<•{Ğ²½ÆìKÙì©*‚”ªîAÑ”Ülò|h¢}÷ğ/±WìX°£XÀ,&‘,ŠÌCß+òv¨AKV7»\§=ua4hc„˜+w#«£~'ÍLñØg©V@ùè)ƒê¤9ö•@°ğUòZ™Ê!ôúg#Ä‡ş%¹Ú•Şş§ P‹)W«ı§ümoˆ$¨òäv`Ü<Še²š£üÖ¿”Mò"w
}'~öƒÛğv3_N‡ú´>bìœI3‚¸×SÒ?Â‡@óÁk¼À€¾q)ü2İ‡çy!{@Ö!cŒW Z –°*†>Ÿ½	è—¼Ñ3n_¼Ê#`j&º§´/c“
#[bnŸƒtª¹˜ôØµ0O=ÊÔÿhz9Ç7ÖZJdÖ¸'%µ÷Ù?y¢>OÖuÓçY>ÓıQ@ÊˆkÙgê—£—ğú”Wˆ¡±Ÿ¨KÉºôudy™I~N|‘*·‰Ê±ÛÚ“Œ ¤Øü‰ş\ù8RÑ\©¸¼ ³øñ»zH£k'Â`¾¼aIŒ½üñÿHú„ULXÄêÄEÒ¾WÉ<
8~AEÃÒ¬ìòd¤dÊô÷|®ZMù¶_‰>.=Òíš¥á[b¥ü#5§"»¼›aŞMÖw£ªÁP'•k&Ú'ı¼¡‘SÖw
HVÑ¼§ç>ÑŒúÌBÂ˜î©„@šhCÒ£2L¥<Ì/"À¼èoG=-–´ÜÉîyŠšp– $ ¡$kvm¼ÌİR7l’Èßj &ëÓ$n]lÆ‹Ó3*AšĞ\MÚ*÷$¨,%+İ„szms'h—ì>Úöéê"Æ°d†îŸt7@ÈûŸˆú<Ã;£ÌYfa6“&¶qÍ.‡‰ƒOÈ ª[ïÎ‡Õí·âmgEFÕ(ì@fízz°·‡öc¾|okôÜsŠ©4UÃNÊˆ$ êóØ§Èğkù„º÷ø¶ØçY>é´„Ã·T6=N,2½í¨Á„Eì°fñ¬ÌDø3?êF+zòø¢âœÌÉ9NÿË;B5Ã¿"şı8xå—Y·‚ÕÎ¤ªX0òcá‹.“ÅQ
–ayÄ ğf¶(KÅFòòFK üÆ’	ñ "†—üTI…) ˜çr€Ñ‚ÏD¥­gpLëkåÃmêá~¡%ûjòVñ¡Y ñ‹/gÈÛİ7¸%è,®ƒ$¯ÔJ9 '”±£gq€³²ë¿—êMKÍFWSó£ ÈÖìJÓŠo²¸–ƒüğù/£‡Xİì°R\•‚Â_*~µ1¥Ñ9RnĞæ_Q°×ëqotî$p¢àdYOÁÇÒ5ÆãÎıÔeÌ”¸¸à†÷Ã¤`tåÌ@Ñ÷F¢xøy–’E% _Èp;{°Qfki¦õµßœ![Ë(—ÛNZVöœé¡HôWNóéÑÄîù<G‹Ú¨ãÊ]¸ê¶¦ôğ±6&I½ñ¯oMczMMÔ"VëO†ã$«YÄ–ù-,@í	`ªWKÌºNd×r4¬.…4±°|pš÷Úª\|r×¾âE Òå]pIC­`x‹ê`6˜e‰†æw…å)w,(y9’§—ÑIÀšsÌÏÃaé±-!±¶$l)s·,#…•RBrrÄ¹ÔM%è¸™¬",o ´ïq°?€8ŞS$j5¡‹y4àÕ<ÁÕ"çØLpïN:‰}”&†ÇÇ™x|ˆ¾)ijnê 1×#Ş#êu§aÚ!{E¨Ì Œ¶#>8šªéª(‰ğd3µÉ%¨Ü/f,²V$ÊŸØtUN”Õ)ŠâÇgÉı†¢&W™¬—ƒ5Ïõ+MË	f‰¾!Œ¬ñsªùnTşŞDä€½¬¶ØË÷Ò@J£ÃPY˜ºÉŞl']r¼U8#Érı½${†=ÿZOÚdeòıV|ÔZ
†Â^DèœU=&T$,vGôa!ĞI8jÎ¹UÙÅŞĞŒ£ı:!†£ÇC³‚u„ƒ¬H¹÷|tÔš<<×_E[Òh&IÑ öë"Iz'BêµLoÊs0
OÛÏ@Sv (%µå¡…Õ:İbg$¹½ç(ñ¿ÉØÄÒGÁd0½—²b%;ûÛã@[À^½|¸Mi‚“Ú[à‹©áåºÀ ¨¸Á¦ìo+¡ª¬§H÷&¤ûhìCú
…ã'Ôˆ«EAáá4èî•œ'uáºD®Ò9gÂÛújT' ÊdpPm¾;¦„ŠXç\G€ÿ,^+/¾G¬ö¯«í€á&•Oãd3hÍ)gà·$1	,ºQí.ögèd³eå'¿Vì:ò¹®:LÛ¯ìŸs˜‘Ã©òÕ»ELö1}‘˜t3ßj…–hìàâ>†ˆ(Ÿ(’òÛ„XÉ€Î);éhILÿ•Iîlï‘¸®ˆN[©ËDiâDH¨S­„µ¿HéÈËòkß8âé“×hfïJjòëuÌ´u›+‹øVá‚6º®å{åë‡x®CÅú·³‘³KÛş*~ÊµmO¡2ıãÇ4j÷Z÷d×p÷Úş‡›¥¦rCbŠ2Š©¦:«Åƒ(»ò»Z„I7¡ÕÅKcè´€'zØ5`Lr[ñA^ı£Ê’Ëß¦£ßÄ1gWÇ«›\>LP)bÉ…š°àØTL¯½4m/ˆx–ê6‘€½ğN²èJ]°*ÖÓ]™¬bE¤S[?î¥
˜ëÄDñ%‡”pY¨I­ß5PÜ¼™+oÔ ë ‚Û?³G~ÛÏÅ„,!ÁHG9ø&×ÔIõ<>qs>’Úûö„+ntğ`“Üeòõ†×[ :èòsC[´ÃK6°W’ÍÒ5Òª7jÒkÑÇs d.yvÁ7/u“oìÇM7ïV¾¡¹š.{4œID†é¤W*‰™J£‡¥Gp_›ğ?ÂMaësd°öKĞ³©ä®{¼ £ ¹Âµ9U¿skwzÿŠ[§¹Æ(B’¾?na¯Ú7Å?jƒ S(½	€w´òô·êÖãq <}¡¬ EáW$¸È Ö%ušEĞ#Í=L1—=,w¶B‘Ò–7ä.g°½İfKí9rür©ªö<ìÇ¿ÎI÷&@.l€ˆ=äÌE™Jq¤dÙ‰U«r›\»¤ŠŞ{P-º;[
hK¶ ÑK¢tÉ§ĞpU’§àAúÿ³Xofqô\°¨–ĞH¸P|pÈœã¿‚-ªC:i92Õ—Éí8»¤•°ª'ïe&Ÿ ø$·,Ï/«¯ÀÉ‚ÆUxñ9<®Nó>%¹[$x™oÄÌ8ÊÑyÛc0‹Ôˆ.iøÁü§Ã	˜»A¬ŞD˜Q·x¸döyæp0®ã³ÑøF¶R„ƒDÑTÓçò=¸Ö¢l:8ïöIP¤¼¥äzÃlq…¯£ÌÓ¤‚pf›vÿr#´yÚ!êtİ`r
RæñîØJºCı™aYk5­ËÑn`Á¨D
4„=Oˆ¦nBŸ+qÏnŸAóHŸ€~2İóş>´¾÷ª´“!èâF=k¼–jÂÇ.	§lE„d’ºñ©OF¬µ)Ìx,y½.ğÂ–6: ¬'µñ1›ØkK/äülÚNá,Xp¯jæwU,ƒgé˜uVêpK`ØS›ã›œ¾†&0ÅÆ«+	ÖÉH—w%ÆØF”uPªåÁL¼óÕïéˆùÂàÂ4ØÃÈ»È™ëëT­7(j}’É}5üQby&—=.pHÈq¬QŒ qÄCğtB4/îjııĞ© %9Ø«&ë6|¤")–&šşVdØ¼šXÃõ(!LëVZ À¹@´_^
wŞl)†š¼X÷	ÖcÒ&7FçzxU4_0^Vı‚cßíøÉœÑÊš°¦Ğ½ÜëfÚ—l]ä¼Z‚Ì	¥¯Pø{k^Qü:Ó;Ìì±ëA•¡‹µ¯}l
ëé8Òªã¨Û2qˆ½-¿n·ï	i¦4W(¾£+1ÏAæ1Ï]sÒóLˆ_ŸRGs]øéA­G‚8‹M†0ˆÒ=Öêk§^YŸJæÂì:Øä£-ßkF
¸DÏÿµ$N+²ü$K{†¾“¨†eá„Hğk³Á_ègDV…æ¹Oåñ#ÉO—°[ZGÌ#ÀÇg†T lĞy"æ¾Qgöïz¯8êow(6ëÌ‰‘*ó—¶{Ây‡7ÿBşÀmîEÛ¯ƒ’Tõ¶]ÚÕHÿy_„jŒé¥PÄxÕK€*ºÍµ¶:a-ôºLæ½zd?P¤¸â4nÉ-pvÑÌ•°XtİVs'è~v/ÖòQ1]8Á›/ÁÔ€Ùø „¾ió½³‹I¯HŠ™¸MâPJ<P ôìâ~Ö‡²¤p+8©Ã»& S5ùÿv¤ˆ1Ô‰mf cİ¿ ÕÊ›($&ø*vHâ”$I:¾ÉÎ7‡lú40B
{´”ÇÆ/":*ó¥s1ÄÖ|on¥t9\ßJİi–VÕ/í;…GÇ˜È²†ÂŠEIttÊKÉ´	´6{8(S£0Aki	›åƒF¡ië¬ËŒƒT	ª;&bzXå>qÃŸ	ª²+„MØB—EgÃÿpè>vHÒ‡¦­åíxÔÎ3~œ\:&ce•ÍMWH¥oe$Ü%Ëo–ÀÕø >İ5 Ô©»@ÜFEñx™q•Ä|²Á˜EK—›ÑÑÍk-eŸ@¡AP%
WÙ¹Õ¯–ñÙ>(6À«=øxU)†¿*%SÄS³»w¶üëo-ÁÇsW48şØ\¯x×±_Ì¿‚VŞÂ‰KãğnOêvG{*Ø„H&äR†QÌ‰/\‡gÚó_‡BÙñØa<Æ¥¨Ë&´†ôhî¡Öå¬<\Ì±V*èAˆ@I5Ë¼ìıÜ³äWM9¿åûô`oL„×èvÛüóPzÑ”ç{”)ø6åØ6CÀÍ—Q ºÍ'ñ‰çÑ6VÌ|1g… Wñş!¯;†iFŞ²Ã£!íÎÌjeAè±Áp“/õöQ“éÛÇ¢ßÇdî:û8kz?MIdC·0+Jà?a`~«¥f^FË- ®«.t+İFëóRwÈ1‰×DÃb^ØÍßÙNğ8))B`.–hS¸{yLçÑËUĞÔ·Ã–¤½÷+#|
8C!ÅNåÍHüSfıK¨|Ìf™|)û%«Ìö„#¤›¸p²íÈä)ê:;í´wm1Ì«ÖøúÒONÅ
¶0ÿüˆò†çå9°J¼‚U|­’Ú3Ùùxõ‹;[…\K% ©‚'%:İíEÓ»ë!¢!”HÎy'™ÌĞp7X¼’&Õé]ötl±|8s
ãâ_
×‡…ê#üË
ÇÔ Å¾A¡3+	~ ×6r'•t­Íšî¾8Ì—eu»@„KàŠ_oÿ©Ëi*ø¡¤œjGÖ’eçBUãQ/ñ@’›D®Ü1aú8¡´šÊç+ıÖq-Ã	1p…­•ûò{Ôe8 @,ÄFäÆuu¹¹q1ş·ª½I%!ô#ƒ+Ê˜d+›ø—`Ò–ÙéöCD &!æ5¶®‹¤™´†{ûP¹5«´T¿®L¿J=|Eş%uD(m¤¶A¥]ö½“’ïğÔæ>õ\„¦ke°°È¡31‰ú‹Ê¶ÍÙö®Ià‚–›³e¸°$~¤¸õöˆÜ«Ï	íÜFƒJˆÕÖgO­ ‹ ³#¾_Ÿ¾1kÕæU¥VQÊŸ3|øg4¹ùµl¾,l¼ê(¡6	—åS±S£ƒil§)‰e ¶#Ó½>}J7ØÉûHÆ¼?u~>“¯[š±iÙ²%X­':òœLv.'4€Z|†õ•}[Ëp"AZhÑæÆ ˆ4ŒŞš±Kú)Å’ù	ÙSá{QñİR»vò}SØ{˜ÆCr°±P)öá½Ÿç†Ï“LöäĞì„qUy¨•)MìÛ¢KÑ‰ñ¦”šıtpW$*ê¾I#0ÉvQéYğfšW2_Ãøğ½”ôËpÅ%Î}æÄ0˜:|¸Âë@oÑçVk…i!éq‚÷¨àäÃmOB¬:âRzq·8GŠ¶M	—ÍÄ7v-¨èM›K]Ôø*Â ğyYmğ÷ŸÇ™èKöš)”Ë»…w«ù¼Ëé¶-qSİ“ê¦¬^;ÇªwÂf}õ6¦4KH½Ø®ÑØË¡r>XÄôtÿŠ»4£¦ø2_n‹s—GMñ|XÁqÈK˜»ÕÇDî;-»jÀêúÃBÔ iø(˜‘ãçjØÅ†¡›ı¸
ã.,$Ò _NsfÖp¥£vÁöo0˜º||ß$…[;áŒE%P™›á2"¢u÷/È$1ÙQ¹ããÏKEŒ‚fe±ğ{«gËTZ	=§/Ch$çlÛ§Ü¦4kıòN•V>tÏxæT*·#©¿ˆZ>™2ôïäÛë ô×µ
±òå©¹<ºâKuakb¥Çšˆô…~¼kß@vµšX“UÂòræÃMBÄTqƒP½Ô]ö‹ÕáR˜Š5y£ŒÙA™º¬7l@ğ¹¹6'KD».„8áv ™Õô>P%.…UÅ¬¹İyOÂ¨r¿C>S`iÛß·Yú4UrØz%çmàf‹Ä%äùÀ$jªÇYÑÿ“OqÁ‰ø]|I±xËÖCş®—áŞ.‚h ¤W`¹Ûµ™Álrú”U-¯²aã+ä©Ørop™Íyf¤FCVâKs`ã—õ¨ëå'p˜"–jÈnÖFÛ>°‹tà¿Z¢Q(Ær¶:<g¼şáÔPÉ#u“®ZÁÀoSâŞkyD¸Ğa±zTè‡4*?¸MÌKÉY¥:©
ªh»€[.ëNÊü`õ(‚Ø‡äTbô¤Ÿ©úÏ]ÖIVØNçt[îúÛ[ù §Ì\ß)\€WYÓ0Xşåw›øD›/C³¿ò'Zwó7»š¨à–eh{YzS¦™±‡@¹yH6XV|’"x¹Ò1!-+W›Beƒê(Vh*Q+Ìi¸R¾¼^JõQ‘	Ëû~u`#ÄTH!]Èª§éŞ©]lÇhF½4°ìRÕóŠzÜ——_‘ E§›FD5dê^úSÇ°òâ÷ø»KR.,É	Qûó}·J|tf"%q¸Ãì½—æ1‰UÒh>/¹iÃxÒb¼+u­ŒĞ²•>Á?ÿ»ºøüà&°íÙZ·÷¶=Q|f>aşÕÊZç\á¨,íŒôüKÂªÎic*‡ZKî$^üsu»màå’N—Ò*Kh7rAùFµ]½Á[v£;Æ%)+b#O‰EğÀ\#FY’»<\§Îr¼šÌÙsëqä	—5å]ÙòI‰ä„Ûâï(x~9,oŞiÿ1¥8Éä NÛ{”)+8¶Ç(^İÆTõiœÓµ‰FCÃDö¡Ó ÿ³¨Õ~ê†¾äÌ&‚E"úøPB†ö=øŸ­›Ë~^*xwN7UŠÏL	ı@ ¶>S˜³¹Ãñ
¨„$ÍÓŞYc*mHÅì…½|™.«746Ïıe,T'ÃJ½îµò£wB<¢«Ş¡îÛú<7Ó	Q :/ôv1¥šÖ±l-qÆü40­ešE»)¹«äcï¼ê#WÒßÛ¹œÔm01v¸™™›8Ò7)?ğ 4€hyQë”÷‚á EìmGøG5Û˜Ã#`í|ğ½ß‘FöŸ²N-2€`ÜÖ­=xÕ³¬ÊCT"CÙ)¸ÿ\K éÍÓ£÷‡;ïƒö ÀÒpW³`8)¾Õ¤Ù Piì°¨KÔú õº¯ÿ.p‘ øHÈÿ¯1ŠÔ‹«·· œŠ†FĞ|ınbO0¨Pg+*#qÄÒÒG/97,9‹G’x1Èum=BÁ.éÑ°
}§\>_öÌÀóÚnø«¶ı‹Úö‰Ì0m²5y!	2Äß}R^Q½MµÃ…^´½©²53û‹™èÙ¨¼;˜‹Ìè†ÉL»ÜS¬«1)¶|àÜî@¦ˆT^ëMÃßåõªû
€æìÚ ëCÉì)eÅµbÜ„½jœğ&«è9(ØK¨tæw!I†¤x½[:7¦,.Üƒ`ct#şH«k"©ò›JR¥åÇOË‹Å é^JıÉíƒÓ­=™¸œÚ5ğ}PE«ËÈ]^Ø‹2«/”Ùø3Rí-\¤À9v¨mdäY{DeªÇùPhÏ…ƒtğ%"÷~pt‹ËşIš-:&a"Q’4dëÃ–èÿh»îî¢# kàÅ¦¥:© ‰Ä€»Ú_ÆşÖxeä¬l!ËÇC3	êŒM:ç#Í~‚uİ—jÑ„µôÜPÙ¯‘ºÀ—2A_.~Å=4G0Èy	u4¹¬Ë=Ô^¤E$§[=iÇ›¯‚:©¡=¥ö„ØÊÕ“¦fİó“x£åù]$šä¾‘ºÇec·/^Øf¡–YN•ãĞ´‡¼JeØmŠ³:ÅĞ„ıfƒMøjÇñ4XTğ'øO,Êëæ1€6ãÙ£X‘K|)½³-aĞ­áúÑ²%ôRÇí”³²QCrIN·±Ÿîı‹ø6hQ×AÅ0‡*M°ğ«#I$ë•ı)4üh5c¶çl¹1@U9+k5„ÿ±æ€ËX `ŠX|§€š©Şd~¨ÚQ$H¨´xôAÇgMÍ¹âíDNKìïv7ı3”B»x¢€¡4êDÔ5O(Ä…â83”ÅÆ°™H±¤á¸ô9í&@ªú'Ï±ò²8Ş«ø‰¯Ë{W¶¡ù¢	ñ¾ñ{ø«¼ºóï:Nì3Ë¤aéA9Ì´Àë¹?Ë ¢ôØ1‹tN% ¶®Ä êiü¶‰EÊ5ŒFGû¨ì?2è!k»Šß,†Ë¡¬2¿æØ6¬š¦¥$×4ŠŒpKƒÆW›V$·#Ù{ñ…ºzW„·&ô°G'O!+ò_o’Ëí÷»²Áÿ4ş7åü^1¸½ŠçÒu)’¬ÁéO™ìKhx³×´‹bØ5õë>ğ»i­[‚Özïéh°SÚcEîK
!Ò?-)IÈæJÂëÚi•ê&.Tïîìê.ÍR™8õÄ'U­°;Ql”øç­ÀLdYF3ºµºß	üWT•šX¿lğn{‹Ä¤iAÿfäåPa±Y»³l«wsÆ˜åşéÔ<"jœZ,şŞÇq€”•\Œé6•d&ÂkÁ{ŸæÿÌ‰imÉ)Øp¼ÁÆ'Âtİß5|5‰]e;¹ÎòºşBZU	EõáFÔW!Ô’û×<"ß-ÿì²
–àÁ„á À†•.94–qKx–çõ@zV¿	Uçá1ˆkA–ğ²á¸t‹ßG.¾~ß‘}À*Jü4é“ˆPY5:”¦¯J%)z¡¥aQeEµPàÎÀj§M&	ës}E" %‚Ïp£ü 1ı$VXšLâ*D’"U'xVm™œŠb€,ë›û”ŞÍáBtSdºD07Ø›%×b—<ıgòX€Ç:Òº£”'­;Œ?I#¤¹ :“FGµ«­ú÷>ovü	Q¯ƒØ4òÔÌ}aƒ‘j”Óì1ôç÷ØõLşBLğj¨]ÑÈ0†¡¥{,×ü)s+ªl¸"·±ÒöÈe”óÎ? «‘} ‹‘ÿ~ŠÖ·í{,r•N2zÈéªS”
½×rX´Šöê¾Ãı‚Kôµ,˜" ^6\\‘®c}â3>“w7ï»"»@Ù¨å%Û¶ûıK[×*c™·ÈÆgDéQ©”¼†Ş5
ÇTˆøw/Óÿ&¤ˆR"Ó¡G-vÙ\ğõ»±ì÷l…%¥åõôÜx •W36ú= æB‘2( l¹N‘d¤	lÃQ·%Ÿ}¬®Æåñã›¶”ş¥¡ÄÊ›¸L„ê7#Âe8/ò5+Vİcî¸ü—·Kõ¤N`ë(+Õˆêi$u1Bå
E]£Ì5UÍ¸Ìüª/Ê™UÅˆtÂñõšBKÎ¥°$vºÔ$İøn>¬Ëøâ”v3†6!ÒÓ‰&Ùl6ºä¿\Š TWršÀ^½ÛÒd?°¬@VÊE·Ë¸§v`”â†›Š‹Ì4îcÇêÖ/A±ŠCİÀËèV÷ºVş±-.â-ä]HŞ§ˆ´WÈ=FôÁéhsãiÄ¹ı›¥`0•ØîËÁ¡Ú(aö—‚Ò“$×QI±¹PˆúÊ©>0ü‡ÚğC·Éô†÷@ù¹ÙÔ
òdj^Dáğ"mC VÃcÓ´÷ŒİsGÓ sŞ´ƒwğÑŸ•ŸÎÒ·ÇÒ¼Bh 8Ô©)ˆlfŠ"£]ì2[°7Ş(5Ç'‡UG¯qµ\²`Ş5Œ^U–¢İV&lBĞ|ÿØÑ˜%
Ùå-\Ğ³Wûô“âõ³ÒIzòh1ˆ­íé1r®|tÜ›Ç,ŞzÅ²A«Ï¾Ü›°ĞÃn2›Ô;””HĞÿ‹Ä2|!µ–q«ªil‰˜&ÿQyî((WÓñ)>ñ¤71#UéÂiY(Û1˜ºgrù¨ZÖºú¼„öUr°6èñzı­`íòÄ³¯ÇûÏjËB‚W]L4»WŒnW:L(f;{aA·cK~òÜD˜xÒA%ì:âhw_=L ğ-¹kx¦îÔ³~ƒƒKê™ùHÖôGä½ØéAÉ’)º½¤F%ŞµœHö×¯méûŞx÷¿f£/1½Ó	ƒ³½­\çâ™î[ıUéwT^[À“l'A9ÛX¿ÊFí‘°÷³Æ·İÔ®:i™_¢8åYç¯l‚gI‘[ u¥ƒ‘•~!¬SKÕ„q‰_­ã¢íîµm
”ªšOgÛ*+ÀÛšãäÊÎ"kt»WÒ&íÆÖëÉòÓ@á}uî+k™z0£-Âç'€1™C Î9¥¨rz0”D.ŒÆ×GgyÀdğ°ä†º
0*H a6'¤†¿•›±Û®¥tR«ŸÑ/5oYO¬¢ÖÃwãMô“àLmr›ìFµ‰ŸœM}€j<­òIoksü‚PâğôÌ²wJ‹dı<YÉYØøo² ÒKn¶0©7“¯@Ãû®”7Ò®¨áQ¢¿qÏú#ÂÖäö7
Íİ¹é#mšÒLA’Õòı!}©uR;‰ˆ"K$…û?e¿•.ıÏQ|ˆÙ¯±Ÿ¨Ê™0·so¥5Ibcc5‰][‘€‚P–É‰¾CIšTT ÈQÌ%Pz¥JöÎ%ßÍ
0ƒ’İAíZçÉ{}X"¸n,¬CF:ªö$ÊÏNrA"¹míı#6y%[i"±U,_d–;XíÂVİ‡-4IoÓ²**¶nq8fPì0s{\ÙEËÕZöÎKİöÆjıt<#f@Sã>òêÇ¯Š{ØŸÔù˜°§ñëšê?, »›ø“kÏ#Ü+Â½iy9eÏÀå:6üœj–·a¿ş 5G.”Œ
UˆôªsÃZºëÙ”^†@lÓ¡T"Ğ;u%oÜÎ§ºNİ¹Do®p…†Aöû“[–Ğ1i‘aCèõAFò£»!XpK$ˆ÷ZÇJ]£{¤zcÌR©ğ€£ÕwYÕzo zÓ>á¼1ßÿÕ*ğ¨°{…r½+O
L‚>
Á0s’h¹;ÉÒè³vàu'´<yX¼6(ÓéA<£®\¨DeE–ÆúŸ•ñFñ³Oly×zì_DdôƒĞŒJÿDIŞŸw®A¤ùèËÕ&v ´ù4¨Ñ94*› ¿,zıb{‡v@¾d…#ĞÃ™)OL™.‰«Šyı-4dØ…"_±öf¼‘ïÏÉâÿ6ó§`ÅÆ¢\M“zK•sG{^?ÛœªDæ±ê|ùS-wá<ãí”ÓÍ@<Lˆ–µÙ‚zâ³/¨Ë»Ãd´éï$}óö} b%€¬#Œ»ƒ)"Ú ÒªtÌB`ZApHÄ¡w*>V(¨ã	ºâöp-áâ¢ŠCß„Úá~ªSŸ»‡Á¤Ä1ö'¥Y
ë¥pA§ÁŞzôŠ,E÷FœD=³ßqÈªÿ)ÿÙ&™(óÏ¢äE ¯HÎ/P÷x_`C)¬K:òÍ\:‹Yú†u.×~OÂ°3X”‚RíL†0¥9*¹ßÛH¢V¯½®4åÅÿ?u„PüO¾ì•qYÖfÓ£(…oÊ¶Ç‘Ôâ“ı!)pVù¹gS#‰n3.ïkA¶‚†Ó…<àÀRÎğ·7m³»©ò2 ŒŠ	û)İÀø2ü'"Ê3Š¦ÀeÕcYWh`ş-·ŒÎ¹íJ…É¿úğôZâR’ÕÉc+8ú]½%€å­nşíËfªç¹êo"dŠtDİåårÌŒ~ÅÎî“.!Å•g5PS®µÍ$«<¶€bZ§İ	À„ó÷ì}íerWH±r€l¦çoøÊ,,}“÷_´ÿFöÔ4ûp!SÂgø-`š©s%bNŸ‘ò4Vû‹5;Ÿ:'šÑJlá­7Âo‡TåFŒn^ö¾0‘CÊõcÖ1?vÂJñÆæFÀÓsë¶`îÀá§…›˜Rí6yC‡×Íhµùu¥åAÜXÜ®QHi3İ_†—ªIš«ƒW3z—}t¢”Òã‘‹ÕZßçİ„—º#Ì¹ÅkA†Ã“éÊVÜÁK(‡îñ5-ÁÖ T!·û%€—l/F^ıâ6¤×yP<şE¹L£æµc¤}l`ºñ,kà`JìĞÂZ	â$bMŠ –BìÕWŸ­Nâ’ğrêÑB´¶msö «L!gHP8‡^¼öƒ–èZĞm8ÌÍŒÃQ —Œ?&”êÍ&CmBdV[—k…ë1ÜĞEO<jâIVY—iÚ%¿'^Á/÷%—ÅÎéLDfdáŠxò~¨ e,ôkå™7ÿ`ÅH®dB’œoÀÏ$—"«¯ˆZÌùë Ú…&ÂäEk>YwÔÅCÓ×äA
Œ¡¥UOÕã;ƒ¹ÜD(»r¡G‰¶IÁ ™¬ts8è.ö­õï$ÙÙFÓCbğ2K—÷±‹&hŸ…Kfˆhâ sé' j¯|ŒÏ¦5âîÙ·‡Ózï|Í¨ÉØ>É™(ØX~pİbá>ˆ=ùÙ=Åı53>é’2?ƒßÿÕ?ù…AUù¤¤#açjm”Ÿ¨ÏA%I€vpf?ó›³¦ı„?Î›Ó(<=à?Ä£¬å‹ªS>€œF•÷;²6rhÕY­cÙß8ÃŠ8˜ 
 DõŸÁ5RÂì¸£"ÜüÅ‘±èöùõL>Ò8ÓR|#Ü×ÓÕP‰DF”)‚»±Q½ãê.Õï¿±›×BGhäV©E­½œå¿å±JBl­ÕWİ8f³´SÉT)1ï‘ù™
l÷Á‹WedÉ‰
áÇ°{äÉÂœ’¡‹¥k: IºÒÍR"åbAFÒô©‡B'üš¹™Ü!B~ğª3áƒ¥‘ÛæVÑ­T`Kö³ƒ/fäRk0GD³¶~ë³0•›‰¿l°$ŒÎîš"Nce{Oš{ş	·I»qåß7øù·ê.RSpøc=óŠ„dÖugp xÖ£å\‹¤¹|Ô_ü‰ìs\–½Á{P¨dš9ÁE„sPö´Çky%Jõh÷mìrñUûĞîÛîljævêøT…â­+Âò1j±„WÄ»1d½QmÜ7bX¨lÆU[üíÔòa˜`kLy§S’,aŠĞh5ÖsŸ×*«Ì¢'´y•¼÷ãÓ’1’b…â.ûªnÁ°93ãWéqÿÃDÁÍ/	â¢Ş|ÖU
»å‡#òEµÏuû §î£ÄEMÙPá ™Ã"Â¼9Ì„×$)S	×ŠI"‚>eê0"äò¢¦õ#˜;³¨h¢]ë¢ñT¿ÇÊó+wàM¼úk4úuø òíèvš!™`±Ú[ˆ,ü´ôa(Û%p©ÛO²8Ö"’+©Tµ/eÎz0Õ]²Í°çñ’ñ˜*ËšQ¼k²}ØİÔK÷N‘Ù{_â0ƒtÏ‡ğÔÁO Wm%9ÖÌŠu‰XÒîl¢:MEØÆ«7ãÓ/?LŒA¨4RN©;©ŠĞ0>ûehßMux}»/NİLæòøkò niIÌ‰ ÚPöÒR/Ã›dXl÷R¼çV'÷A¯#/“rÙ1·Ù}A‹¡eëwK|dö†¦æC{]<ä?“Çí%¬\Ğ:Qh­îì’¾Â,¡¶]?'ReÚi„ø`Ç
	uÀB·¼ÚU@”ÚâQºòÒûîóCj¨R8*nLrµ^‚Œƒ,çÏ«ë72NìöIlŸæƒ7#M÷‡+V-ıÙ¶ş.Bú…^‡iÖ°=Şe ÚZ_Z
TgHnŒ§¬f¥d^ İyì×ÌH}5Rz—ƒ$“æ%}Óö×8¤O.o“~„W{n{³1Ú%ôd³vC7ŠdLŠÎ–¤¼¨²Ø½ƒr“°uôÙuÅq×¬5íıãŒyÙrÒ›¶ğ&‰-}ÒlÈà^¼8´2kúñr‹°»µdM=s‘gĞ"”Òû¾	I§c§@£·‡‡A-Éú	µiÉ2Ì²—Ú•ÓzİI©]=°”¡PA“˜QİKjn¶zƒGßŞpw›”äİÓL`îyætôĞN.–	j
6ª¨È·¢–Ş/Å² X›®äMışù'íİƒĞ‹0àÈš	=nÉñÏˆ·-%“ï‰ô°°w×gÅË %nrÈç»A»Ô)š£…ÑşqİÁÔˆ¶n.÷A|pªlq§ß«uĞ¡²TÀí¯Ìÿwå×%7xkšh85Å¿^Ğß¸Sëbä«cóµ±«{6õ `R·¡
Éb^Uê¶bLbCÇ—Š€Á"IOHæv#¤—yQ‹ÔA~‹Øs—9—dø–#´¤	 !~‡¹Ø´)&”½úNûGµÿ"ÚÀ0&Îú)§ àM¨Ô“H²ÖÙ°îˆ¢%{ÔØx¦\daÀé‰b°ëú+1t¦9pË;=lì4™ö¸¤¬.Ä€ö$¶ğ¼€4ùD^Dã>Ë¦Ã`YÌ9l/r#¥–RÚ3ÀÕ-?Vé;ŒóJV¥ÀŠš|V„nK¡%	£
zQ6 ¿ÕMáÏ”#BDr!‰F…êßVYò§lu:‚áíÎÛÖ-+;ëî²«N0-<OçfÊs
şVÛ¥S'¸ëD@)¨©mëóqpOTMÑ#ì­%`aªOÍï_(­µgÉƒ;ÆùCì5ş^¥#¨ÚºõÖdê	j@şÂÍ ’¢–Óá-FÜ¨Şg™á@3Ô æ¥ØŒÿy…nD†oÄpÆPÔOj.šM¨óÛ kãÆNªÙDÇáƒÎN½IU{±—Œ®“I‚+b_İ±Ùır¬œôuù³ñƒüqfó©*è“OÙ Ôeõ¼_ß0!YàÄù>ºZ,b-ÛéãyG(8sëAUYÖÑuÀˆˆPØ §–ê…»ÚNµ#,[GÚZW¨EAïHfp#w° ±I^–3Û@01ÏûÛçˆóÙŠFÏ&ºM#A¥¬Š`ª§ÕÛ,.§
‡±ï#Èëé8¶èyÿY‹øyÔÅã¹ìğæë~.~¸ÌLÁ8bæà„…ªÇ©æ¥úy>­Õxq: :ÅQ¾E¾ZŞKŒó8ñmÃ;¾iÊÇ¸jw,
íÆÙş^Q¿ c\üñ˜) ç„bhSv•ÿ;a­"™ŠÓ´À¢lÒ¯‡"»ÀÒfI8ækøj 8/0Àg½šŞae«qÎiso!ŒRß±‰ĞCN íäyÃy»T™°ë·B+(•a”±·jr…ÏIÿcÌG§‡;gÆû<Çß‰æ¿<‚ÁØ°fııOpşiîÌ$?~¥1Ú¹fìÕÄ¨?î“H
Ìºu%¿›Îdû|©ŒJ+€ü3‹tU®GÌ:¼¢°jˆ:G
š"ˆÁ^ÿˆxæêàˆø¡•ï
Be‚<H LT03!‘±
ñĞ
ÙÀ÷d•VF¹;_±a€ğgãÅßÿu2·pª=ı	8ÁpÍô;ï`ñã‚òµ3\Î Âtówåİh÷)úÓ7äûôD®_!¨CÅYúôã‰¯Ğ	DÒé©á¢Oû@ñeˆİD¼PÚ 0™Å¾ãÇ'†|-y Œçq:âVı–¦®<2ÃŞ›+5ˆ.Ùáş4uEÄ“˜ì†ç~á ÛaÄ?hÒ¹!A5)2'º`@‹ØrÚë³ví°9Åã€¶|’E¾Á÷2“HÍ¶@|œg.‘M³ñEH…Ô,Y¯ÒŞwÆç³üÚ1¥‚¢Ù¯0/.¥q´¼ºHPU/Ls¼ô[Ú¢ÇYè~µÕ;ìò"F…P>ÒR®qú»HˆFdãZ¹ub19ÚÂ'>hĞ„³G¯ílœÂrZöó/E®6"%¢'Ô‡w|5KÎZ›ÅÎÁæõ]Í3H&3Àıu2‘8uv€H}ÄD¨ñØ-¡k›ijÖÈÏ0®ìU<Öıázô/¶¸i÷´
·“ñ$¡‡ò9leïÔş$rS¾®Â‡ÛˆW£š©ù¡Óïkï¤VuÕ3"Ë•b|h¡.Å¥‰ñfø/ÇEµ”Å“®¼ÒZñ~$¹Šû#Vøëè€ì”–İíaıï6|5×Ğâ“˜» 4½if®ŸtvÂ´ï€Î>c…ÖPV¯ß4Á« ­Ô$ßÍ÷8­®ı ˆ—ü× ’|E„e³·&>~ût¥»¨ğ‡¶'ÈÂÑÚŸË­@rÙ¨RéŠSéóúL&–÷DÁRöŞ§²/<-—`ú'ë:b±Î ÜñLÈÇ\€Ètn”ec"ˆ—E}ç·¬BcÓ­;yÕ»oÌ¥Sú{Ç‰{”Í=ô×öÑ½
¢¬Š4º®Ág«›ÀñO]ÈLy—ß€éRf(’P-1ÃBAj¹}ñ%e«Saã&º}{a#Û/€DLÑ*3øØ^.Âª4ztvèWµŒxE¢›÷Mt Ş+…Å¡¿Â­+óÒcq“‚8Ç…Y³-ÕÃ•2;Êÿ{pŞRQADP»|ëà÷Úk6æ…³÷´œ§šÙ%¼êWÕñ²$o;U_éj‚ÇËÂğ"ÄA%Ú-Àt¬ /FÃuÑï;!´ywÊŸò¼ë˜v”şe&Ì(âşH1¬ûí,zÉØµ.ó_Ê ÛóÊÍ!rUıeêí'ÅQ*h¿4©p"Uµ ÍâøÉGÀĞªòŠ^¹Œ_)i÷”E¦ç?%”¬òp¾YI˜f]µ®“¬”å9©œÕÏØƒF!‘+ç»Z¸
á?©Ol›zêìLÖç¥4>÷ÉÉ¦íx£¤º».u2.á¼í°p·yŒ¯›yù« ÄAät¾İÓ º›,¢xH1xTNÍÈÉîD™õ½»åÖ ÿ¾Õˆ¨{¼%†…rê|	œj8@l_:>ßÕ£çE˜ÙæzÖÌÁŸ y×¥{xJj–€Õó/œÓ¢4U‚QqÁÕÙÜw3Qãx„:˜ÆRk’×šijŠ@cptŸ2×wnê«bûX*rWBFªµãÎ²nh_º`C™-1V9R[d „*ó2í0Àø—zÚTYQÿú#ã~——i¢øÕÃ­"Ù5"ÃÇ³•ÁŒş	ıW`‹OdÃÀœƒ´ ½S÷vVêïğw.ÔHıó(Ïß²¨=œ«&;{œw*°U€¿B7?¯ıñ÷u¢ÔŸ‰ÅåNbbgÏùf Ÿë“½”A?~Ñü¢	cİ|8Ï­:²‘Ğ­zºr¢†}'åŠ“v)}'s>}™Ç\êĞEnbšõ'Fd’IÆÓ‡‹H±q/ uA?»»„áÍzyƒ”eşeA»Ğ¦ÙÎ+>t‚wª°0CLá¶`Êà"Aer)x÷€_áJçuDO\ 22wº›½­~C™™:oúò1ô½¿‚-„ÚÕÇï[ZJhó•›Â­ÂÄ®†‹úÇmq9íùœ:#5x¢t 7üå“6Xß§ƒTh°î9,4ëF¹5¸ÿo}‰Ûø°³‡»V¢¿»%D%~B= åíûL¼]KäÃbá8@×ëLSzteş‘s7,–¤ÉÛãIc`»kG¢òw7ôrA-¹ÆkJSU¸LŠ›5N>GéêŸFœÅõÖb0öÜ+wk5µ_j‚$ÎK”æ¥K_^|%uw¿ıÒ !Ñ”‚Àq
ôim‰`zãmÍèó·B‹ö6c3`yz}šT:—â]]Ä]q“ûB×ÏË3¢/*ú
/sŠ:ªàV\Ê9šm«·ĞÛsŠ“d¥@@¬Nî¹tŞd¹i²B'î?õ&I?Qü™œœ.Sùe2½ûZÅ|8T]‚™µMôwJPš°¥W©òÉ†4‹xcÇ)¬@ú…'îS’FäÇå7³÷ˆèåˆ{QX¤òÎiÂõD…$5fªŸTÑ÷¥ëåqÇW3~©&]Ô €•ğ5àM¼¿ÊJfÁ`Ó£--ÁÃÕJğ›½<Öo,‰"¬1Yc€Ğ+\Ş¬Ûäø5ØÌ4K-´é€¹MØVPëı÷Ødœ«íF#nÉ<~ÅI *…oEŒlÛR4¸n!NÙJt9§öå†LË¦¨ÙœøøäV#K\‡ŠDelÔ0DjyŸ®–%ÂÃ\§D„2VÏŠC7UùÅä©JÖ|Uvëôº:qª}£Ró—İœ}‹¦6¿åen[‡øzÎĞü9;AWÛŞZâÎÖriĞK [ÿ
¹îiVÃRD.v–Ãò5–,÷6"?P4."BOp²ÚDÆ÷âäŞ*,¾	àäã(¯E(»[—ó¥ı)zÉ?=î„€$tP*H ßIDíˆƒÇÈœƒ‡‘½Ç³ô@7¹•Q`±û–‚Éaw¨ŞÂâğ»¯ø¼éU.?îvAüË>Ã9¾'éw´\Ç±!‹KD)±®H«¿Æq…ÜªÕâŞçÖÍæ¨"®$j¯,ä¦É¶87h»4<ºşhbàÀº%Û×¤eDÌÛ…7¦Ç÷SN #PãÔs¤şPÛBZ¯h1Jl,ÆZZ¸a"± «¹ñ
X‹1£’-&¬œè†:b&Ôü~Œç“dÏÊ&=“}Û &»"™HkÙ¿zqLŠÃÑ­¾ÔÔsË¸zÜïlııèp­±wNnvj6ğÿªØá*cGö¾ón’ü7dMa‚”„¡Zà½¢[ït÷‘qùµ¢T?Dü§vë-ÅÂzzEUÜa$C°¾I4J L@8\”	›;˜¦ú‚¿„¬ ¯Ã¿ndZSâ4ép–Zğàª‚†ø²† $×]?©Í“ß%Ó!t_Ïv£•÷/F÷ù½#W×æ€4!"Àî„4¼˜ÍÿQ¶p¾bòù®Ê—¿l€3u}‡ÛºSü<lLãYo˜
oU¾‹'15ólÜd¯ïvœ†ç¾R×’–ÍiÑü
E}¶5(ûÚÂ0ü©”p¨`éK8R•YÆíæC'•~!~i	¨ãuùYs`èïø”.xÒ'b†~+-2øsRRå–·è©ö‚ó÷}ø6=­'>ã%º‚GVJÔT˜õwîgE‡Šşù÷uŞ0-ó”:¼ª=ff‹.P¬N2of7šWêÙú¦/òÃ6Tw­$ów'jÎ6ó7@°™*OSu_bÔğL)g•vi¼—y @Î+Ş¦gÓ_¶%A’¼ji6CƒWƒNè{|…œñ=-¥±5¼“¼’km> ¦ç"µLŠŠŠK;nÆpM‹Ï
ÉóÿÅ@ÛĞÛı…~bóÃN¬Iª%•\~×gÿy¾òÙP”ÖÏiU[¾ôö	t’÷,f":JC%é&àêƒDê> xg¾ü$w=rË‡—€®D%!Êmç·ıNıtß^ıs½o†Ã˜Î/QÿôÜécãy[È}Ìq¶GË€
yö³¢†Ëˆl¸’¦[ûŒµq?0q¾L9¨,p”J…é3Ü;²Óütô‰ó×ìx5ÙBp]\¦šÁ	s¦ƒKÉî«ÏhOšöJ±rL:LÀˆÉßœ{d|¢QMcç'şéVnÕ*?Ë N’!ÓÜ!›H¤íS×¥Soÿ` &¬0,µeïşèÀ¾ZÅæ„Pæiˆm>½fİÁV7@gœ~Í³Æ&‰ µş‹•¢85Ğ£œáæMs•Ü¸ç½êÈÌµò“‘Ã:vcÍ‘>ËüJ=p†h§0³.ç5übá—˜Y(bú ’sô‘(³5*ÌË]¼0òëçğŞdFW|Ê C¤eÓ{'-
Àê—ï‡eõö!cŞçV.„@QÌÃÄB[ëä‰–®ˆÔÙ4õ1›|ôm×Owd7Ñ¡¶÷7¤¼¦¨ -V¢Tğ,É3©g•Ğ}uXx•c!¾5-€“yê¶«Í/´ˆz2‡£USm©ŒrÊ-À|ëÔÏ:¸?Ûù>Û
İ£3;[>"ı/ÁÙšWºGñrP¿OSªxeÏ»Au6f+ôr6÷•àÿ"®ªUI/¿6Bóe2—TU™]B¥î‰±˜'ĞäŞğd)Ad¨äy‡“Q—=ghO¡`TÙ¯Iv¶kA¡I kª0H^¡«Ô[e_jÎüV¯0.*à×’l‚)»¤ã/=iëeŠ`ÆÄ©0">8
çè¿ôdª‘µbyaĞÏ²9ä ÂrO’ß3ç³On‰a‘,!O/õ?…{J2ª°ê,?îFŸ&IÎ.[9f2¤ˆ ]"•Äšñ×Kç+*1lRèÂL>.Ç ïpÖ“U‚°QT*êá"T–‰j#ap,«CeĞö­ƒ”lÄÌ´²˜Úİ´`ÒNNœœ‚P4˜Q^Ö‘Ï×}ÎmåÉ±cïB‡^ÙP§İfFsçEÙĞ%&àI.€!ÂtÇ–ÉN¸pN‚"²¸¶à·Ä~{‚V¾
ïìöÉàÉ ù–Q¦,¦iGı¹ØZĞW%ÀÈCº~F1;Ë’~K”1ˆI-OjÚ1DÕîšë‚íZVD£xvş±:"=ñ´×|\cl’\g¢³Gl	%}óË¤+Z_ì+×ÀÌ•@ã'­æ)‚Ç%„c=°@"‚œ ´›8C™ŸøŞ5B_æÉ8Ï«9ô_RD\ÒlÂ¾0¶w CËŞFªá"JWÀAø®$Pş`I:PÌ 
Öq<‰a’	–~Øï»Rë=Y»KÑëiQ3©ÃnO¦í²ûR¾ªš†îõh\'ğàÈ!<×Šò×‰ß{ÓyKJê_¿+E™ú~µ_º0È3ùH¿¯oÜ(È7L·ADr+¼ÌÔl,‹q)ŸtÏË âäµ-™ôè:†Æ€97´ºªŞåğP ÆÎÆ™İV®Fƒà¢uıVt'Šƒ Øui{iË)OÊ„`áÅìÛñÚß¨rPÕÅí+Ñ,4]Ê³\úÊ:ß-Ø‡FyE–x#„¹´`ş›L(Ş¹õN¾Ûğˆ£.Åési>Æ„§g·ÂeÃ£ÅÚ[bÉ„äûmönœb[˜&i'UÏ›—Bg†ÿ	î·ÊÛ5~×åã 
÷@9ğÍøıúE?V³&=Rë»ñ?N¨[¡‰úpYdïMw•e³ñ>]×g\{ €C¼×X1Q”uHƒÿå~IŞvŠ?(i ˆ¡ñ,ä·{‡M)ÇNeH[G´Dù3™±¹Í
2©#±Ö¥€ıKÔ!ú€øQ¬ˆVqßIƒÀ_nüşİlZ æ€)ıªö{é&b«„Œà)¬ÓÂ‘› |0f@§!ØPr¼ê$ øAÍÙE=Ÿ§ğ¬Áƒ4Ì¼®ŒTÎ×ëÆIñß.Ì[üäƒ€+°ó´´.îôı@˜Ç±¿9IuÛ7›iM#MıÍfÒéíØ~FK”ß& “<"€O<YLNËªkö7Øëóùc €±íBp„}Œ3z·ú’ƒ¸+š	#©BÛ
E‹ru6?e×}€C÷ÅÙX:÷“Ï­–ÿè£NTz»½cšéù,*»¾Zµ=Îq‰:›6†O¸ª¹RG×0º}É`$µ2dnvĞ¸×÷V²{R!¬i7™ŒsˆÎV¦©®U2‘E²» ¦÷$“ä°!#({ŒRHÌk7‰/±Ş&Cf1zÉÕ ¤axëmŞÑ­şµlv9İ¿)I‡]Õ=ö¦…”}4dy|@"İô˜F¿ô‘’(¥b6Ï§+³İ!hCÉ|.KŠ†õÄÅ?ºG›ĞÔ6!ä;µü  Wäâ»§ û¢€ğœÉ±±Ägû    YZ