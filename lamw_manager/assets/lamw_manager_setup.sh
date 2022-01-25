#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="951473558"
MD5="9d6ece49378d18a177d130a6a266e2d1"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25976"
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
	echo Date of packaging: Tue Jan 25 19:53:17 -03 2022
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
ı7zXZ  æÖ´F !   ÏXÌâÿe6] ¼}•À1Dd]‡Á›PætİFĞ„*ñSA·œ©‡\}\â"ÊÓÏÓXQëıgÊE"´=Áp¼Šé0JÙ/äjd/^çÿ“ß—¶Îlœ×õ<øàz¼<‰(O!GÜø£‚LÊj €¶pº7‹ıˆFï^Ä^´®Jßíœjá®ü|¼Ï%È¨vI¨NI
ÙÎGà2£ñ5iõ„ İçó5[I‹)*Ä"‘Ó¾9Ñ’³¶$SÆÛ¯Zc9.t*'VÙZÑKı'·ÇRƒÿÕ7ÈØnC}1ÓzÆ›€¹Ìá&šõvğ>htjŸ0±k&¢]ÿß,Ë[<$‰¼Jë%V² šsúœNtuA ³Š>Àè¬êÍ)”†¥¿æn–PµšjáÍ*k~a^Äß¡÷2„Fş²ÅÖRLuñ®›ƒßÔiUßÂ.mÓ3"ZËòË‚ñ˜Uğ|rÙ­ç:[ñÅhm˜%é$Aµ óƒ#¢X¸’ÖùĞbò*èØƒñZÇfäÚ0gb^i_³6 ‰ü©<KL‚1Ê%nƒï`téaÕ7K"ÏuGEáû°ï>†ÙşTÄ™$¾Y`lŠOs\L™ö’Â½V†¸ŠÀƒ¦yxí\8ò»py<¦OÙÖjï¡«Á.x%ˆRùœ·T¿­ıu}—*‡(8û ŸßØ“æjôÃİk(‘J£=¹uzÇ‚¹ëŸa¦>ie@…ı—»­R•ĞNŞxçL:Ûuƒ…ˆ6¬ùø£®QÄ®)!¥ê=Â·\ÈcÑaê·ÎÀGR)jbR~Û©õÔÑh¤ıšm­?.ˆ,Ù¢]kV®Êü^ş­ÑVÓ‚WGWÄ<*µ’û¶7©°ı(õZ˜J´ü³Ú‰9E­Ññåopd¢Ü×šÆÊ7-U1&kŞr×
;ŞÈN8¤˜Q÷¤ßŞ+ˆW'È³,ŒW*B©!Á³P³ê¡(Ğ¸£,ºk1¼î“nI¥î**H0¦EŞÜäè;2ürleµÔû›k*Õ=KX]Ó:zôºwáP†;ñ˜‹“T…:"ó:¹Oxïx{â	{Ö9è?¿Æöâ&~4¬°4wXïÄOu¢¦eå4Ş{z8jØ.ĞO¹…`ékÌ;‚€‰éÛ„-½¯æ¸+B¡ˆg>÷?iÔG¾¹”pœ‘½f´Â´i.ÎfÉ[‰¤iG÷ø…ƒHsäuãµù·3¦@:ÆˆboÊRË(Ïà¹UyM²øØ¼¤OÅ9N‹ØûÙ™ÈŸFµ¸K¾æ'šïš[†Ç6
3¿hHŠ$ Dªû¸S¿¡TñÕOîH!¸ÏG‹-
0õåº“(YYH8]!|‰Z„ ¦×Ÿ^.¢…/
ØÙ©“ú3Ğ•ˆP³:Q¯—Å§şRn´«HKó6‚¥»	ğ¨cŒyWÎ8û•	+<ŒÚÈEí^ı\G´A«?·ãË}q×Şo;oÑwé-î-Jÿ&i´æ— º¥}¦æäëı4(Ë|È~ó&‹ƒ¥úÙ“™I%şfY³åTXï>hÌaEb½$Î’Cr @èİä~ 3‡wà
/uhÎâb%MÜâ,ŠUÊKbäZè â×<±ºJ4ÀS±ëmyÓ*ü)™›£K0Pp%.œ°`hÓy1m•¡ÿ?×Bú?| aÁš¹¢"4æ=Ï-x"ã¶Hl´ô0Èw&ö%ìü zµøÕ¨÷qÑNB9ì’m	İsĞJ¶ü÷µaÜ3"ÕÖ“ÓĞ„®ø÷ß•ó–‡ÁÁZóú¤KMü€Rø¬êLØÍ½¼7pşe_”bç8_Ó‘Wg²,½B¡ Q<2øºˆvò^$!¦AjÆ«\×˜Óï¾dæ=7š¬|Æ²Qıu½||Š,˜ø…Âıgz.ø‘Tœ±¥•F×¦ÔöçÒ“ÊWz½²ùÙWSí-Xƒ>È9_Üˆ^Õ3Ój’{xy÷ ğüHo¼q”æ&0OSˆ{mVğ"†İP±¹Z3ŸÑD±[l—Ş:q?ú`èà€á&Ì&?ÓŒ›Z•«¯7’!§JD«³¢­Ë(Ó´¥†·ßçÎõİÕåÚV kæËD¤‡…ü+Áº‘İJÂÑ³8§]Y”„oG£¡ká>Óøtš“26Ğ—j§‰nÿ××·ïl6KËÅ76‹ÚŒ_œ•ó1w3Ñ0†ÕFËŞ(h{Oëº¼äh£è²Kı™UÊ-öyÃ¶àß~õáˆÏ_¬œJŞeªÁ0ç	Ü ‚o¸WÂu]s¥æsˆ£½ËF²Mö§›à¥¨í^SèĞlëãØ×M±2<qÃ¦à‘ªÎ%¹Ïí…Å~ëp–æ¸@|Óã|w¸'@4™«¿ø2âÆ'î	Ş‘r j©_ËÈrYøG™Œa1¾Ö¬hğ¯Î?wjäël¼ŸñŞ#eì’Æä,Ñ‹dÊ/uôÔ¦W™øu À»»BßêÔƒ!ÌÈO$ôSË+r˜ú0Ëg VCl±ğ‚tc÷]¿m~¾à˜rÒÑçˆ¢CåqÙBßÁ±„A«²<ÊEdEèrŸâç]ºÀzBt<Ãf¥TÎ@ú±•‚Fƒ¥ÓÏå{62£İƒ÷>+êÊÚ|=SL¯ñƒYüÇœÆ`¢Êq{°¯ «oOpyTG
‹!0*;+ØÕ‘á'÷›¹bØ*!uŸÒ#×íşƒH±6{‰“e±á?Ø G"¯“¿"êjÔÈ=]‡ú>ÀñŸ\ @‡F8^×t¥ä¶8*‚‰8]²œv/á«E¼é7şWó›ßÃĞŠÇh‡¥óİwÌh£Öùôœßu™âò ‚/-'Q5adEW¤Öàı„1é7İ\>Hméİ zÏUë\·R5ìU/@ÇÄŸ•áVˆ Ñ(„üV™¯<úïà*BŸ÷æ¤•ıo>[ŸğÂõT0¤}{Şów>2óêÁÙ-0
rM3j¿+ñíiï‰>p@$¥ş÷Âà§œ„TF±8nC©æš¼é\4ûLˆdÀ$“ì3Mû‘»â¨‹ñ…küaR($«LOÓ‘šìy¡dĞêFHYU¯*S8pÉNuceÑ7¼°k0½uÈ9›}µU¹`ùîLöQ’”ÊkÕ¥+V
Åbs¯izÓ‚¾Fş/†H&ƒ¡áZgúpš8Ê¸«&\¢fwåb“œ3ĞQóy2µ^µèa¸ÆÓ1¨Ró/?V"­7HëèÁÂ» İ™œ	ú`9¸:ºm‰ğÖ‚U¼í=ºnÉ¹J]L±beó\ÛZöUğ,­(úã×¾1(²›ĞDâ“±î›Ø ÿkø«Eù´pVßÆUR#JÈ8¶Ô…ƒo©t½dñáu)÷³óÊ´«èØ+Áú$ñŠ°€B`C|Ò"ñ#õ°@~¦ÑH`ıèyKÁ†l,:g8Š9ÚK
Ùúu~`}%.Á¤t­Ã-‘eêé?ûn ,ÍÅ²(l4ÌÁUÕPôı‹o9fÂ– iàW~^3‹]H‡åèÉUƒ.¶GÓ5HÃÆáu6µ ö¨6©^©Ù•màáWÿ-P‘RG…İ-?³Fªw× ¢¤©¥ğ½²Š”Æ˜ğËºcà‘†“Ò÷+©Oé¹ÈÙEFàï…Gñv‹Ì¤+‚×÷·£—Y‡ mks~.Ö2ÏA<@{?VS+Ø;¢ĞÚ…/Äİ¨qˆ³?~„ÿ„¾ç+ÕˆŠ˜CßÔ5S‡#AœK „ùKGoVü
­r©ûN1r«.ü¹hw¹Ÿ„½‚1de"tÓÕuYd’D†¨. ¹èa›KñBä%zkevìŠ – /£
|ôGK7;‡‚À×`Ui—«-hÅ4™/^>ßç¹™=)ßVùÓèáØzÑş&Sî>¶O’ÄoĞú¼Ê£<E³¨8ıIZ'äñèDe'Ù3×}ZK#[¼\X×©WÚ5;d;‘Úoôbn½óĞïF\}×81Löít©ë mÇaL*F‚5ÉÜ“åã7ÍÛòM f^Ô¼Ö¸0ÓùQeh¡3(’ú´Ó™Ô&Çè„:o9ı+/Ç\â‡¿U²/,h{Y;êĞ;Ã>V .£S"–´ên˜'}{Ò JÕ[78çÜÓía[#Û.#…s¢˜î‡Xô/‘Ú-Ãçêéÿ\ñÒºr(¡×WÓ ÿfğô…-­‹_Zõ3ç¦%ñ[ÁÙûëÏ¨ê¿åJËŠ;r7?n}$’bHÓşäú.óáB¯y6Tá´µwJØÜ¶ç#)ÅÙä>¡Ú6Àëğ‰M7i!îâ:˜<âÊÁDkdÅvÕÉX-Ó…\?°äõoÌW‰ª²®§æX¦Ğõi[§dê´ò›>!‡’Í)1Eú¨«:°°Õ@—0£j&Ãt•u§]ÕÁÕ já\/øıjVº[€”IB$ßO¥©‰É÷ØÖ\íOµæ£k× qÿÙˆqÇG2”¬ŒàÎÁ@$§ËMKùHtâĞş2âq£-.Yxò¸1‘Z<·LŒ	0™"&^ö‘-;×K2ßg¹ZÕö”å[*…LE>?ˆÈ;5@üÜß/F6<NºˆøÿoEØ{îz‚±Ê×+*B©a„pŸ…Ç†3Àñ†÷ZÜA˜÷œï‚cL{fIŸVñ¤ emír"XjIì¦cÓ\"’=Æ›‚FLŞHJXn°QƒÌ2ãµ¦îa¯­V·öAİ;k8 [bpW?×¦7d9/Tœ
(ÙVªÈ€£Ï­H‡IØËÓ…ïu”(¤›H U‚Uv15U-æ­/SUÆ--HÏğ %jÅM0Â48úyAkáwJÄaÙ=Âxüô©7•é’zÙRˆ&<İ‡•œ
a›«G3Z±ç|:OÜÏNX >7…Ó4ÀıpİG*rÄF¬àkşœ©TÚ ZÅ‚°–ÿÇOÔ¾ÑYk<"˜÷ÇZ×ÖÜhÕÜÈZ“¯k'%_ß§õ3YwÒóØ$²°˜÷ê²·A©îùÛ‹Zğdræ/­ıjŞƒö`îWxMµ?‰e6*û‹ı¶)Æa†ğ w®ÅŠ:=æ`#J—¬¼Ädç¿ÄË¶®eùî‚LnĞ0¾ùiáàqávè&r8“øB¹ÜĞ¯½I|y¶CíîfˆùŠxÅ±Q¶DÿuÉ$^áÅÛŞş¸¡JÖ~™™.óU_bËæ]‡ùˆR¸$´–Z¼«íä¾O·ˆ™+)“şƒC=&•7KWuíj•zèSMpA<Ó©`ıîNÆô<!¹NåıãÑşmw>[_»¾=IÿL`ÓF¸ˆÜaÚ¤Š®ÙÊ›‹×ùoşJ+E¦¯bËWCªé}ó
I§Mp¹ö)úp^Ñ?œy´ïß÷4rŸ@B-L50PİålÄá¶ÇãÌ¹ÒÎfzP¢ä©ËITzyb.ÀĞ
7"
ÛEI;-¼ºÛÍ@»§*ÍÊ4K’‹’×¬ö™¡/^a¸‰-Ã'ê (ĞgóˆıúxŞ>~kv*;çÚ&h%)QÇª	i81Áµ¿¢ğÄ Ó[SúkèÓ†îìŞ_Ím(ÍSBığ”üÕ7[›ª9À‘"îœÌ%Ğ¶Ôİ(†É®!$ÅA`>> O9ßå¶ø7a×ú±¿ànÏ>Í¨n}zïÀLCo¼.6‹r:Ü°Ù€Ù“êôöêÿDÈ£óşòOY?9I¡11m=¾Ñ“éh*qş%|w×+Æ±Ù™ïÌ¯Î­/ŞûÏÚ š5[ZÛg[ÎM+bÀAïÉ~Ü¹E¤/ûãK—dMo¬Tx¬î7½Rœ¥ÕRøƒ„¨ìk˜š	á÷¥½[W#áZåÔ6F’J)3\~+'Ì>UVtóƒÜ
ÜgúÅ7{<HâQ»mMuÆïKéˆ<x>³mÛĞŞ+£×Œ„íÆ¡Ë¢.[mCœvF=9jÃ?Ö1cjªkV-fáu{™«½6Èœï¬±†Ÿ}(Õ”…´d¾,ÉØ¤®ñçûcÈ]l(Y1/ˆBo;™ËÚXl%D!µÀb?Ù¬`Úg›°c{ëœÏÍ×äÑ¦¢™áÁü¿¤Îù*;’%Úï@³«…+Èß`œğ_ø¬¬4åa7ôîc
DÃ•‰«qµ,¨=`nX#^Ø5½Hò¤wöX¾»Ü(v$'Ï"q®u&R÷îÎ¼$*HâM‰ËÄM/9ÌŞ~Eøì¥nÃÛ_¾7ØË¤=<Òå9¬£’h~rœætThàrÎÎ®öÈû
èıR›êà5šSø)ĞS3
5×yhèlêÆ}Ï›NÁ“Nú©”h6HXCrü®F›oœ´Úl¿|3§rÀ'×ÑgŞØƒ]‹ƒV’mm1¬9Õâ˜s¸ôóî8ÅJo¨ûãa¦™SİŸT£ñ¥¯ë/“¦ÏÏÌ•Éù­q•”-¿©]ìû¡ËRJPĞûÊĞRC »§p¦Rò¢Ç+“qß–Séä(w~-ü(xV/‘ˆ’Á õezâ™òà´:;1Ë©—Ğ¨Ø_¡'Ç
o‡g)¢úhÜŒ‰‚C	JÄş­ş¢¼ ³Ûºè­ëî³…Å“®}ÌˆãÇ±	9²K8x/Aè— Úvseòv=£\·¸©¡§‚„[™³©—af‹ÌİÊƒıÊ½]uÓÖ¿CÛS˜>èáRwVuáì<E”€FQ¤»òS®ã&b«T6q2©½;ÑÏ~‹×tMÅÂüYpØAr3à‰í¢ñßûñYÛÙôŠ®·¶!+”•D/’¤#üŒ#à@%ËE—ÔÉµR­×L
kÂÔ‹(	ëš–ù“íçcBëäæ{‹¾LÊEö°¹UéÃôáÏæ’ø›®ÄµÓ¼äNÆWé5ó¡.32vCş«u£¤#È‚+Ì7pl{èë6:C‚jm>¹ÁÀQsè Ü§"›Q*?ÖF~Ù()*d8%àO Tİ"{æHFglr+0,¥[Õ¸™0,:*Ö¦K§ †äœR|©ç¢šgÍ–Å“È\k§^à¨¦Ê˜naÆ>¹ô5¹:/¿óÌèhÙ®aF<Œ²ıjdTr¢™æ,)¹kÉõVn}EÓJ[ì‰Æ¿-íU·Š15ÃñD"ÉîÛ#Æ9ú Ó)¢3_Äï…Í»Ö.IRHˆß±£,jjœIBÆª<xOY¹™ÌyÅc‰!Å›³gÔı1q‡ õ>-(Åé¥-[ ×UÿŸE±°2bÖÛAŸÃ+'ñè’h®öÂ¨Òy¢°—L'ÁÈp Õ4måOfÉn¨;ˆ´VÄ.(gs0înÒÖ®#ù,àÏ°×âql”h1Ñ¨ ‹ª¬ÛÌDÔÚêmÑœıló¤óüªÀ½ôöƒ¤<9B(õ½´9ˆz'·¤Ñ'û€Qÿ5b_êHFä…Ì¯[Çıª§'4D¼}a„
Z‡W;ä÷v16£\Î1ã*GI™Ö¥ƒ—ÓÎ5«Ïô-¨dÎÎs=ªm/€£ªòT\cÙnçwT±ÃKÇ@R,0™kËJo¹Ş§DiÇPH][ÔéVËç,¦¯¸-äñQæ yøé­ãmõH_Ç
>‚½·ß™°lÿ«Âòıím%¿À3_×²ò^~Q	—ˆyY&ø|ÊKú&ÔÑ›e1NIÕ^.÷€âˆêÛ
D<Ç¹ö"éjfœÊ`4`nÁá+•ÂSp-Q@3hÁöŠwjÃÔxè,H]†®2®ä“0ª]É€ÿÃšé§h|c]„£ Q,Q· á »Ì!fß—‹9ª2ìk«œ±º°ûZhútğ±5Ç#¤	­Å•tï¥a%Â™ay(ö°{Ì¡8äPØû^)¡
Ò×~H›ÉÜ½pÊ'§r±ÜÛÈÕªG®‚üNm¯ÏºizP³gaƒU€i<ÎÑ—}t¿E³j´çkä3½»Ó§¬¶`†ùq? L–Èe–Ú§³iñúUPx´dâ,­gbåª³@ëypdÅF'4R«-©à}Ş!4ÇŠã‚ïõ±ÎÛÅ_)#ĞŸŞxuÅWqŞìÚÊÃ¬µÑv÷…‡p‘;ï…ägë$ş6¤oÕ Ñz­(Û„Mà%ğƒ/‰,Hm‚Fu‚	ª‹PacÎ&˜ä¼Í‚1v4»mÀZ¥FKMlÇ.¿'ÜÂœÓ½ÙÖµQî[›rÆ{¸]¦á‹ZÂƒŠO©¬ƒƒõäm€Ëñ´qã~—îI:2)ô!ıBi'DN#Ä
Sr3ßF,’-ğèÆû?XôÍjf85Úlñ®ŞH%T¶ÂŒí‰Ÿğ»`]7µÚ,_ˆ›Ağllæ¢õ5£yØı©ÌN˜«R=TM·bÎ	*vè%¾ çë8uÕS´÷’7Ñ’lÂ —ö‰
ÿ³6ü¢‚{^@4FÒƒl*TÇ+LßMÿ²kã»å;ƒC%8ßÁlèø{°T>4©ÃÿXD­}#28œıEË”,
EbÂmà¢Á˜Šó4Zåo ‚6İO7ÚÎ¢]Näãt=Ólì;éãIÏ˜´)%„G«Ü¨ä]Sir½w8ˆL>‚;Cüİ½Í¤ÿDHïùk[ÖVœê‹GM†FMİfI$ğÑà«–Hí>ÿIW˜;w·©ÁBw}¤Å›°R«¼òÇŞÏ2,Rêj‚ u{Qbğ?ñf±q9™C.»6xh!EıÃ}¸Pê.Æ±sá'AcÄ^şWÉwRÇ®ª¹ó5 z}ymRB<Û`‚ÔB»&éÙ«Uã'GG~¨Ìqé-VvL•Sî‚5ˆR)<ip§â,«üèü®“>_öUp«\š¸nuÛT¾š©eŒÿ³/ì[PĞó€¾ºÄ:èñú¼-B›¢fĞI
Ç—é+kç¬"Ã³éÊ{ğMÙ›¤•?_ i*]
IZ .Ş´®¢+²ˆÍ™™Û²sÁ^ŒJÒ€¦{ îIY‡Ö*Ğ(yÚèo¼Óm¿"(ófº¾È¼‰ñL6tºi±…À/y%ìÎl¡Ÿo5ç×ÅŠb?Sp;ùàtúl¾gmÌØå‡‰fËHì¿të©V¡¥›ÅÖaSË¯R¾æL6?` «Ymy[©RcW ñ2#Å‚|$m•à÷¬„o-L¦;}Dæñ1èó¤Fã:8ü‰'ÑkTË¸Ã¤CĞy= ñ±H655²H+œßí¤Ójá›1Ç•aĞQôË£‹¡µ­ë(3¡¿Á±ş[ß
½Eh×¼”É…3GÎºèÓW ª"œÇe*.4«ÿs[ Œé
àèu~j™ÀÉ:*rñ-Ÿ©¯Î‰˜°¦Ô¬şLÓi&\$CïÄÅXÍ“şl#Í¢á^e€˜`:O$ŒÅ|Œ6"dúSø*Í Üqï,Ò¶» ’dş˜Fş·ÂxÂ™ëô¬ôÕ³ÌÛù6T“©Ù0õ——SÁÛ2.²c‹ ªïÆœ ‘¢p6"ö
‹CÑõ°`ˆv|¯µğ÷©Oº³¯
k-§ÎÈì™(Áÿzå†Ip¡#²FE~Û(™—÷	ˆ·aU€æqéC+KÒú§"Xı6OT¤D´cJ#pŒgsûàó$ÿ¿ü£ÿ·+_¬“ÏüD€Oåğ%}\hA’¿G¨DMø4­AÑ3€Cl—&B†à„À®é¼å*} ^°ğrU)‰tôÎùyÇV¨{ñs,SµßˆÛ0×¢ğı¥¸hT Ì®b
2&Ø‰
•êa–C›µõg¥FÁŸ@Ü.ıUØŞ³íÑ}²0ôy¼˜£´ÇJ‹fG)‘´EÊ+*×q/Ùà¤lPÏŒùÊçÿ²e”íu‚ò(–y*2Ë3´$32Û­ñÆ•T‰µÁQgœŸÒˆş«¤f-Còæ2Ã½š«¦¦ğ®}²„PËpdR…AoVaaXÇÌPißô@'éŞvà-JÊ9{õ‡NJ÷¾>¼H ƒ@¾‰éBŞ¹ÛÜt—¤ÑòÖ–=kºzû)ß¾îmÒMÒ¿7î†Ô³r:àæ9 e®³ÔF³ÙK@$Åä”€S5¿#g¾•¾?1¯ùÏgHk™=Âì0·'˜q”0ºUohRqtu{µY¾·k	Ô‡ÁkÓ…b1«": ¯€ç$ô¯BOÑEŸE5Œ…™·IìØ!·Ğõ~|§3\ùO–í.uÈfEJvH(ÙÂçàª½°*Ây@î†o”2íˆw"×HViÀÜ––OYç=½>P+ÁÀk?bMõeËi¯IØM<¡s’=¡nsµRv§1Z/×5œh,6ËQğ”@ò¿Vºh?È//´{“‘ˆ–7Åğ×Óï…*ìjfºÔUdm—WÆÇãY½—KMù<|ÃÌÈP˜IµHS ş Í^Úe
PkÑ¶ˆ¸XÈğŠ­~>úe÷1ïêw c1~Ï_ËÃÄG¯CÑÜˆ/p{—ƒó¨ƒÅgÒöÀ ø~c|Nsì¶(„Ÿd—´k×q°ûŠ?–´û+MBÌs9 gIìk"Géí†MŸˆØ]œ•p–@jUk»vrYk¹Zä’T*<â8on áû—«z5™–- NPªPØı$"†µ±7‹Ï¿ßy¸¿oá¬ƒa>‰²KKì='cÕ¹D÷¾c™*ªùzj½Ø_¡,vKßòW¥Ôğà™>(‚ÓDQ~§>y9¦òOénr<D¼x‚„Ÿœ6õJÎtU£äÌrRi^Ll/À Õ5U¬Çü¾”›“$–¸vŞ,&’®×”VB0Ì\çjÕÙ×ä
HŠ2R¡PâúãÄ•-¿/Ááë°´§w£Œ¨”‚U^¾PaÄï
pèÏ,Dh-`%77RHeaŠF~$®bëêü	¸—;;ÚÍc1A=üwwöéŸı+/•-E9]|=[]É'íÂy¹ü£%ÖDw6/}ÄÓx’ŒÖqo…94õ –¡…èèsÌÒkª[mæîì;æ§Ãe¾lN$É³u5m “£]È¯ÿÒ7 •Xß²x—œnJlúÉE£6ŒQ†z²¼Ä0œh2h¤»ÅĞ×ónàÀñâä`$ŒiÇ©íd¶µcPˆ—Âı7×lGª`\Æ°NlZå|«¬y_+/·ò”RK´èÀ™ï™PiçÖÉ‹³x;ï›°
ºÏÂ]fŒGe-åÖ?I—ïp©Ôòº²{˜ iãÊ‚|Ã›`òœv.Eè½ÌdÒXÀ5hïÃr2pNß«9ıéSÀÒŠ°ú×Q]ş±Kã‚¬»% ÓónScÄç’¼øıZñú_ÎùS­a%`_3²Óğ®[¬Õ0°À6Yû']dxâõm¿võ½ÍÛª$³Å§KwU=Eã©%ş\ı3-ğ`—Xñ#˜sø¥™˜¢ öâó¡yLÁ;˜ĞŸV,wHŠxp;2åÕ…ùŞ³ˆ]Jíoı¯V›xvœEİÃûŸ[åÁ, QQÙ…KAk£Ö™ÊÃ[†_xÜ­jÙæ’~'W’Ú&rßÆTóÃª€füš2võ9¸pvY|Ïœ€·¦Î¾*ªöêlŒw'yH˜‹3ìD,B‘ÒB¡ûupœR7qy™Î^¸ªÅ–Û•ËÓÜ­|ê+tÃªDÁ|ü¬x@B¸^m@ìdÃÛ›ÀPrj	’ziÈ	a+³¢H¢¥m•/ÒS[ b¨ !s¬#dC)vIWğf2À\àiACj1'?ºTP³»ö6¬0+MœdãQpÔ`ŠHOm3ãZV@ı/!”$fûòŸH8]ÌUş©sMŞ™İ*›$Gš°CÙ,]çáÃô(¿$"MÍ`Ã¼jÑ¨ÿ¤d‚Nh åÇ¾néBÏ§U>ÃZÒ7œã×q±j=¾Ş÷A«lúoÆÁ[ß‘¢™åWkPÀÔß°âwÖøÅg@vZ¹T’Ø`EKi¼‹Š'|V™-UöÂPÉ¿Ô—B€‡cŞ‘-îYzœÄ¾à”6¨¼´¿‚§®.‡vÛÁhåî»áô6Æ<@gKmÂŸl\%çæ‡·ú1‘>‡*ß98UäR¶ €ƒç—ş?ÍÛaGõ™&0Ú:= İŒó:çêfÖáã†ÁN{Ûˆq6jt†Ìâ9ßE÷b\K46w…9ş/’Ç Sé< 98ÍI"YzmW&)_òÌÄùXŠAo—`——©ÚófÙÑ2·…LÃ8TÌ‹ÌâığdH¹|VÉ:ï¶Íıw¾\	pÎµ@Ì@òï(RÆÑÊşA€ùÀJs.‡¹Qÿ4Õ)Ä!ÃÍÓkh"·ÁÈÃM,8–ï$©Ó ï]jvà ×ïåŞ”‚XMÖºó\Uˆ]Rf¹Åè&		Ùä¶ãÈ¡¬Ûa‘_§Kó«†k|ßG–#l…Œ¸‡õ8óqŞ~9/BØ^Ëê-@©/®ö=À_°#ÆxOÏ5XRœ­Î·–˜ş§üˆs\Îêó¹4Å–Iÿ”-*½53¥Â1utœ×&’ˆ7o.d[—gÕqŞWTR|ÅŠzr`>c¬£•OÚÙ¢S*‘u]!f
·Í‡•^êíéÌÒ9éu9 Oêd¤D!Dé#s¥Ëı§LÆ(OSVe’€ÖâGóŞ"v„àV—¬.„Pºn“zÛbè¾bX%P7[Ä}†²ğ8<% q¬¤"¦Z54Íİ«Ø&!}¸0©ÜpOgf)ôsèx_êu1“¡ÿïS{©:7^Ú7œ6²5ŸóYŠ à„¤úé/YR1f²YÌ1dEå!½‰—
–[µŒ¦#z1çı’¿ıo­K‰ZòpsÂ‚‹¯o—:8$Å3I…‡¹m$:³P’is!¬Äíp‡§aöU<”§m0àO;çÄ»¹ó+ÇH×ğºÏ,Ú œKéæ ibíh`³0Yç6v‚,…şX3Ïj7a€Ñ„õ^¢$o£hÒç/­4“F“İYìg_‘'÷•'×?İç +ö±Õ,PÄß¯9™;u–²©ÕeTH¾€ß’Røåƒ•Æ…Vê‡„ˆ_5º%ºOÖb‡ .å‡e²ÓdŸ»,«’´’wn³¯à³?°OJ38Q Ôß13Gƒ|Ñ¡ñ-·¢ {y´~€úN š·#2Ï>~u=c@7ÒdP›éRD½}øîNh9‡©ty¦R°.ô¤FÎ›ÿ„‰Âõ«Eœbˆ‡8îYqJŠ"çËŠ|‘urVç¤H¥…krë+6öKë¹e»íN"ÍıìµË	Ø¾,F5@Exª°Î…¬ÛBÍá]%z@!Løöxøı‰Gg÷5KÏ4šò‡öÛÁGz™ß³3O1÷§{:£¥ë-ıNó‹ábÌY5sÈoÓKQBò©h4ªÿ‡p¦+u°Îó¾¾¨_<[A@³È£ñæğÚåGhUğS,wªóz€wq€%ÕAkĞºWÄ0|{cúñ¶¯ıà‹+Á<„ñ.Ú·³roôIsÜ[Ïg>óºïJ‘‡ÕÕÇNt{9ØôäÉw~&'ê“ñpêõ¬}îYŸªºå¿<i¨^ó_aZÑ1#"w®9ÁX–3ç9ùcÓ»šæUd>BÈŞwI2™Z¼¥a¼‚Â»xíÉ¢W¾º@­ó”Ÿã†YëS`#JÕm©ísófW.;=Èwü(Ó‹Íe²¯Œvcxá™Ö·äR(qÿRa…ºÌ=Lhœ Y’[%"5Î>XÖ¡yŞšÚ"üzà›?ªÊmâÃÚ‘’Î®†‘éŒ)=¥P¶¨Q"3×üê!p6IA;9TÏQ„Ş¸Es©ğ÷£ùß¨¾…Áµ¯²ªÿV©GÜîó|h‰y›øTİGØ&1V#V=¼¶ßHÓE…3<T öõS+c0±`¯9²)@’ %àuë‡éïo”÷p	‘|c|W —V¯ğ2… e=gÓ70Oó
f8jt–£´x
øìûjYT—U”ßmâsü«wnR˜ZgôÌv„;G¾«Ïçšô_J1'2~q¬ÿ%˜Ä~° ãÆq–yõ°òb·>÷lô4¾t¾T9½â¯ûMùYÚÏ¿”ş)7dÏB
KJiÙzÖäÎ¥?›â	–XjwmtE¡³@éÉ"×²'ËLX8Õ†‚\µ·$yf°÷U€µ3¥ŸÉ#Ëa°¼E³ª¡”—³""‰Bo$P&,ÑÄ÷|Lò©Ç.Îçèø_Û*‚ih†Pllp%f‡däÃs@ß;Ã	aı_æ¾4ˆ0Óğäa<ïP‰—™¯;Œê]#÷æDÎ®_’y(ŞaŒkå—¸^ cªátâü)êô…û÷ÌÁNDÇbİíI!†õöœS±eî/1®ÓnPdÎgÇ~qÏHu­@3@ñî¥ÿôOÑhÕ>I.4ß¹D3ö—“ucímıW¬Éw÷‘¹ïßìçP¹Å•Ğ_d±gvkd¢áåª]>g÷|qÃ^œ!9¦áAyÓÓ´r]*9Ê]*¡¦Ó6›ŠÈ;ºÌÍãVl’‚ÈR=*´—ÒkŞx<s„ß—%¬I£•3 ”³^ïfã´ƒyĞÉ÷rÕV1€u§Èâ¬díeõf‚mO0=‰Ü‹ãC@_ìêKª—[¹iœ'å‘Œ
²ß>Eûçç=ìzˆÇá"©ŞÏİ<Äˆ£ş¯ø½Üå%Öá¶÷“'éûìåÏ”3µŞ_ù³pâÀœ2Ş‹°?,8è¸-/ÒlEHë iŞ–ği€ìmèŞël*&ä
G¤¬o¦Áp,oñUòâšıša¬,—×Ô<Š¯µœ¤6ı0“£î@¸úìçèîmîvÚ5ñìF wôñ¼ÔUí|a›3°—§­(ó ÊöwwÀ%¢>©%^Av ñ+s€&×µ4Ùº|Æuünræ×à;)3cÜÉ¥o•èb’× P“\Õ<¸	Ã: W®Ö±VÛ„J…à)YüëTG)ûùñdÆ“êO‡Lve÷èø^YXC#ÎÙÓ‹;6ı¢§Sr€(Ípşå*Æ¥:Ç5v§Û÷§J±às”Ê~ÄóóÅª2©íš…\ÌSz‚ó«]}B¬´uq¸6òå$—râ,Ün»)Bétc3Şka
è–¼äòàa”»lFNi´‡¯¸+ŠíšÖéƒŸ¬Kpî¦‹ÁÍÊlÉµäÓON$L~¬¥©€-””),ÀL’‹©ñ¼¨#c…ùè™!¿à-å9=œ5[ë8Ëß[gÉò€NÍ–‰¢¹"ÎûÛKeêMõ[çÑk,yºuëXJ*™È/È¸7$®ªUíf;3ç.ÈvÑãCš×õtF•Ïk†ĞÅ$¥§İƒ)’×'àĞ‡ß#§sç9>XïÔÆş)`œËÒ“?áµ&Ò\5ÛIoC´aßæ\L:ë•»¶"ñÁÄ¡;1ùÜ™dÌ	ÑY/•ö6Uût¬qeApy1¡áó^§¤½ÎÅ~×[Í$¹Rc0¿ mî;%SqÔ)ÁT2Æd9Î$Ş05c³tĞ©yCFO¬á4Œ»fùhEWœ‹]/`;?6·6$Ä5Ú«¸ö)³äKß*Y¢Vì¢pœò[<=îË/y_“ÅâÛ3¬(ú§Î“U\yÀ©whıW¨ÒŒ°ŒBÊ]Í!4}£¯r0ş'GGEnÎ¶ÖëÏ<\MTîå@‚Ô¯v†A(‡âçx[«õFü¶ìÕ‚.õÿ«àŞXİ÷	6æÃ}áNkâB˜èsg)(Ã¨|ÁOD˜u·¸×<Îâ¬’ÿÚÁäQ.úhïŠ¯Kò{ç#ıíôğ¾
yåÄó~!Îå5©=^ô{ÂY bVo¼eq>”z&ÁÓtZk2ü4Ô2Uá{V]Ü)$æìQ+õXâ¢[x‘Á4èHc¼J0Í>Û?÷¤—Õ!‡Ğ±©ÏÅX¢$ùBîÅX¤RÙ“°:´¡E†š£VÌP˜	6B~¹p_Q@8Ñß×~ß„æË“Ìp(Çã*¦p³1ÉkeÍ¢¶ş«EÀ(T5Æµ2›¼²˜I@äSÀŞh	3à’Ã™ê2‚óô+_©DO&Zy±¦™¶~%kq|Ï!Ã„ıØS9um¡¸[o&İUà’ys6/ Šõº_$Ôm8u›&=[Û›‹Yâë¦"“õĞ¼0úş›|@t"¬%é\{Zµ"}0ıƒËÇï8i=É¸ñò€¹SÇApëÉfÒµ$À“m+à2Üş S©ÆoŞÃ)u“ÜuxQ ‹T¶/¿1öÕÀ‡:m¢Ø¼b·ÓûĞ™}©~}ÿ‰ÏThPÓìĞÙ1â€ IZ;¯ÇµÌ^”|£­õÈÃ•ÙŸ¨I¿¤’,v…µsF2Á1¬eÃ|øàŸ(Œòµ…-…9ù^ë¢mbÇñUájT9÷ØÇò¹ºı-«[æ"rR“úâèğ„y@œ²^º¬lRı­é~¢iĞÕ·7´‹´ææøC[76ï³J`7ªÉ‡É½§S(R&‘ğP†5äšKÑ\õ€
Îş7Æ5Sj­x(˜—ú0eg7”
œÇ\É„NÈ\ïç7<Â–\èpİËn(WYB3áPĞuÀ?ô­¿úfÅ}¸}µİXÔVBP³Ä¶f%ééîX@×”½sHº]Ãì±6ƒYÔ”UXáB¨|ß2´…ÇuÛ…şµúÈÕipİÍŞ!ß&M _„ßö±“»˜#ÿwp8¥èÒwSOŞÊ@ÔG 3.ê¤H8M%š¡”ê]âõq šØZˆE¹Ù_×P¥ˆ3bã†^é¡<d»$Áá[k	óÉ¨,F7Ì¬°øè—Q`Z,šXÆú­ÔÄÆTj¦‘ù,D„X„µu„m‹îaZ¸ÔL¬ó d’†Æb•á¼ÔôpùP•âÑ…wÙ?;"yPx‹}1†šzyê1Bœ…3+VÆ¥Ej"zî³üf]ëÓw$æ{Ş|àïƒ‰=!†)áÈP0F×£ì)Rİã#é¼i#³Ã:/«yıçã»NN6Åàq¹ÕO¡'é[†ÂcU!é(R‡ìÍÅğ<wÃ‹HÚ ¹lb´˜1f¼Â^¬ï¡K\ûÓÜ»-ˆğ‰/p‰2‚8¥Úô^ÿÕ/ÿL=9*f:CùIÏSï¼á«×q‡U(|zë¡áF æ(ÿB_E’$VGçêöµõ³÷>Ì ÖíX',7{él¨ºªÔéÛ;'}]öHxŸ·Ï*¥¤ËŠµŠ¤¯U¾'5~ÒËeæÎÅ”egÂÈãı0Ë^oØç„Ş=Ş–ß!ìQÄêûywnÏLÅYF7mAS¦5eá+í\†€fÚ’\äæ¾â;Îı%ñ¬ëÀÌ”:/¼xÕ@Ö4/’(§£5/%R¾¤AˆÚ­±#mã—h¶\qëË°»EèàßB€rÔİ‡´ß½ï»ËZAU6v'b‰qÂöU¿5°ÚÁòÿ&i¦/$/æªOğV“1ª	zÛÓQ;¢8h«Æï¬‘ÈÚˆ’€¦?û«ÑĞ$¨£Ü3à´ç‘
È5‰Õ¶ï!ì¸ÿ…îŸGq¿éû7bûw‘ë…„f¿ì¹3Ú‘@ïµ~CæÕ<˜ ò6j•ÏóˆŒ7á~†j*‡pÃMÄ›1*$öè
©‘ßaKÓh_‡$¾ãÂV‰„ÔËĞ![hl×–=«› wà$p!ØGítø¾U¬	„JäBfçÄö
û©Xhû¿:CÀ+;¬hnl¢ĞR¤«f®ˆ5qõ¼ãô~Û±WïTz«1aH7-ÆÔõ5RsiàÜyó±×_ëğëg]ÜZ4;ÿ;ŸÚ¼â$«ƒ<ïÏ±¾$èÿt¢¦ÛÕ=ÍÉ<ï Å³ÉÍ‡¹wL¢_t^ÅûK­2HqeAwştgşr)*X?À ò¥f÷µˆEuğËó:Ujs´	e|cÁC™ıóS$JyË¨¿ˆp˜ÍÁäÃ	¶q„Šì¦xB%)ÊÅú×Ğ²/àŠğâDc‰K¨¾¹jt°™4KÄŸhÇ5¨±ô‰Òõ™¯z'lBïá`fR TEO6§¨™'¤ºÁfß°ÈV¿Ñ·v0U¥ö¸On°>«•í%wÉSÓ?,ì/«'ô³ºË£Ùü´GôŒz¤zæ]æDı,9ƒGÑKo6¬øğ'ü¢ñUaƒô¿f1W w@œöò†2çò–¨mc{ñügç…\)ÛËDtßs<ÌKŞªŸúêU"Y+wØ!·¤­d3·²àvÏéMİ¼¨ÖÌ×zğN¼r¹®ÅmÍ¢ÄS8®œÛÉ;·o€•¸ø—*#µENÓÖ–²!¬ÒÒ¯¶OªÈ˜—è«mc´¹<Ú±+Ó‡BáƒÏí›¡0kš{=§•Pïş ÕõÊ…ÈÚs…ğWôG<”ÎW?jX®ŞVyË«ÅÑzUZ¬üêK«ıÉúKåöî¼˜9Õ¢H?j'*ÎÆ
Î­şü§C!6ñy†È=Ú?Å¸4|¦ÆÈum4²ü°¨yŞ÷LŠ€ÔvíY¡ß#™hœ´U©	“Q­õ¶ÁR%(±Ç€¼™Û« ºÖ¯rúÁ§‚(ûÂ¸O\æsl†É•-¦6“í$qÉªf+ø6³"Ñ•_†Ï'M{y’†¿ˆÅ›]?–øKoxÎr8Ø»@w>Jb÷IpXám½#½pöÕƒ”^PŠÊ@kÎºóñuEÆÂ·¶ÛnÖ³‚YdÖhXÔ_:u
~Î¶Ùh´NhwÛ/Ma3“Şw_øícYw'\·îóã¹öá6õ&Øã “0m\’ï®g{Ú$«ÁaT`¾Gh.[A©ğu­zîJõë¦œÑ,¼É¢ÑÎdx8¶Û38›×Œr„SİZvwÕ›tÈÖë…ÀøC{l™×¤/2Îs„ÅÈ0­1ªƒoâY£<f¹Ãs˜ÍÄµ—›pd¼"ñ¤¾q¤äİq#›"ß=™?¸ÕvqŞ}|ÙÊ¾Ï¢¹ªÔìs.DúuQÿj9ë8üøOÅQ}93ĞôÙAB8ßÊŞF¦–Wxd_xc§,‡0ªCËïñ/£	Ğ¢Qµ†q-3l‚e÷Ñ£¥÷=ê$>1†˜>ÏĞ¾rI‚µÿDÆ­ë”mtñ€ ı;ê
M~•»ğ ô‡Éb’ØXş>ş'{*ÁŒøIÔË·:Ø,ã0>&ÒWáÕ²y'°¯ĞªZ{¥šd«Ú:¦Õ“—¹Òò\ŠÌíÚ¾©
Î&|Ì…í*êÈ…ÖÔ&ÌğÜßÈÓWÊl@í·¾×?EÜäLìÛe6ç´}¡7uG~iNŠñ¶™:ªÀ¿w®«ÿqÓ`æz#ôˆ_/Ù°~Üso™ï×OƒĞ»¼Dòım¿
U„ïöAÕÏ™ûTTüaÆßÍhw ¯ì­ÙMomğ‘£Ô…ÖDğ@«%3"¤Ø'¾`ì!CßPi ‡‘$:ºK€äƒ3>_n¡D,t¿1·«‚›!–İË;õ+ù2(q·Mgg¾´˜5]|¤Ã¤Î§@¢"–µÿ)¢|³®ƒ¿"M’Ì—¥ß}^ˆ–^’ v”X¡¢G¢\ =±]Ú•ÚÃõ™/nbÓôšÃ–xja§ê¹Bciek‰ÜôŠ>ñP«qvé²ÁÍJ6¢}9Ù"şÍ}H÷dkÊÜ‘çÕå²k"¶ú[>‘Í³	¶ßºb?ØõSÈ‘"àºóaÏİ›î¨ckÀ¸d•˜‘N=@›Ñäı¦Gùí8ê¾I]'ÏÓp;Iiğ!—f‰	û Ç¨o¡i»mƒœ'* ÄªüicØkqQ®^(B€mßû¿™™Œ¼ıZm˜÷³<{¼èç'^(Ù;(F>¯Ø.ÀŞy]M&d²¸0ã/ÛPßßÜ¡“äi…*Â•Š©q{1ë´w+|B/¾è! >àÖZØ†Œ ^ñ¬GÏ×I†UÚÓ	Ë½¨W˜Æ³Ø¦'Gà\è4xIalÊ"ÃR²Läšbãñ‰ ³¸…†!=NÀÌphöMôz6j)¨3åbÁÄpÿiÔâ¡¸“²´Hø")¡CÍöîÙ«
”i	BÊXƒ¿ù”J¨¶ÃnŠ(oÛV‰›Ÿ¾Ëû›*¾ê]˜ƒ¾º3(*'³·’ÂÅh§Èaœóà•Ì¯ÃºÿŠ
sÁ²?ñ÷TRrn;Ò?²óĞTm=g°Cˆe›¢¸rSKè§5ñğÎwş0Ú>f&3
ÖJy—qCÓÿ?ğ¯Ê €DûÒ½´í%ğÛñb¸Îe;sE½qJ”à]™í’6`lK¨÷èK+%Á{/€¨c`$Át^¸»Á¬3Rx}tÁëĞ;#	tVuNRÒNíåà_#­!"º¼ÈPšùRåaªÈYl»­Bï‹í¸–;ì€£1”í(Á5…š¯È‹¢¯"§FU`YÛÍ¥ºùìÕÙ‡†piï?0»«ô¦[“Ñú‘#.@H“¯œ²ƒ¸©õªn¿¢î,~Ê´Ú5<ï«2€w?Õ"á÷ Ñæ¤O¥'²+ê§/#şE ,W&­ZÅWÿ5”O15Ë^”9á“«ûFíRë‚‚à–^3VÈíWNyù-DÙ›ª¾Gâ
#ÉY<‘¦¸ûS2‡:æ^Q•zğu§UÙo\’“*´$Á‰äX¿zˆÕá©-MÀ¡ïÑë¡Ò‹ˆ°ÙÁàcı¨íPÈa`J~-ÖÕÛ»Ë’?½ÍılË> mR/{\^¦n ÈpÏ©UÓ*ØÂ‰¡SÙçÒ	ÖşÚF˜¾ñw”XsMYhèÔ -z™†³KÎâÍNÚÍ	ıø¨Òµ!(›gì±5G¼L=Ï»åùPo^½!„…¸K÷n.t8P§lgGĞÈ³`HëÉåX({(gPÀZ¯¤
õ˜&3øº‡Ñ³bJ®·ÄR]ø¢ˆ#„µ-=÷sÆ{ˆZb6¡ÓçsnÇ,Ã?gì¿Yù4¬ÆCk2"ÁHİ¥ì‹6©j&*û¾àCP=>GÄÅ<çğ	îí+–.ô(öí*Ám4 5O³»¡„h‰Ë[k	¤¹Ãÿ*´ñ_˜şñm+¤NFs¦â_¨ô+€4šrƒH³z÷ÖÆ@¦S­Æ¹mÛúxxñeœÄ8¹¢‹Z÷$]4«ËEAî„–DÚ¬®ÙxW¼ÑTÑ`”XgJ#0Şğd£½çC–*–¿ŞK”…Éş¨è/Çz‡NªiÖB“b“Élª©¶4´KÈ!G:ô#‹İ‘VR0O÷#¼Û~0í“ŞjFåûBxû{ ˜ŠåTæ9Oüı¦l)¦ö¬ğZª¡VŸ½o~[•Ñ\!m!³k²£'‘BÿR8lŸbh_ÉÃ2€‰÷c|w
½kÑ¢ğë_I¶6³©M3ŞmM± ¢¤ƒ½QÊa–6ª´ë½·qüë7q”€šOÓ}­Öı@ÎåmÂ6gÓ˜–}W²êOÓ§÷ˆõ‰X>WUz+!c7¶¿ ½“¬€Jìç-iÂÇè÷âœ(+ø³u‘È_\jŸ:ÕtÀÉ!¥zcF[ß’ ÚÁ®€ÊÍ{]oÏYXsî6A“o£9KšÎ‡áH	&#\ïŸq8¡¦˜pü3%ø;#S ™bàîÁ$š‰y=—À¸!®ª—Æ@w\Ë<ÍPÊÈÍƒÖJq•¡–x#="v>TyÒPpOøŠgZäšªĞ8¨¶Y[5¸ğûÇ‡‰W¬èñeL¤)8_éø.JK}*•©ì/E™%B$¾x%lw'ºñ$Õ¢’˜3“«ïd•ĞÌ;RO{mnº†7šZÂğ’H¾ÒáÙ«(¯Ñ‘^ÈšAÃo&f“#V”™8Şì?:Î@ûº*˜^²~g9XYûW(9p[pœwqÒlÕıÌØ;Ü
|*ïÃÀñZ„-ÑhL8îc²`I§¶8y€Ké³ï‰¹^t:5²Œ8Z£°¬‰j7š&À—>sYr ø²İØNÙxg-o`s·õˆ¢áv}}¥s´æ&ğb›¤ÕJqkÜ İÿD­V¦¡&s1²Ï<B–6€@âpe©§ÁÛıõBÑñö¸  Ö°K×‹æÀ)í_ß¡]Ë`˜•Ûÿ,cùß˜1wÚ7Âœ/yL?#D¬1ÍûGßÚ"¦Óö)\¤6(ÍLoÎ-ƒ—bÍÉŞ58©QÄZ‡À£Î®”¡->,âÓëc4Ä_šƒË¾6±¥ hi¤í^zÀ*x#Âã¢YƒGHñw‰R\\ù«:)æb¿üBwqwâ¬Œ.‰šÈAè+	\MRºÛ]Œ¯áH}r×I”PÆË“p r8¯¤Çm3ŸÅ	ÿÛË×d ­{¼~¾¡!!‹id† £„’ŸåÅTit³A\ò¬Û\÷eÎfÔš$|²È4“p •“fX–	%6yÓH*	—<1qÍî§õ¿ìÁ-ˆ_,‚TÚåÙ<ª
koMæØ	*ŸdLÊça?w5 >ì…Ï¬{¬Û¶ÓŠÁ¡E#>·ëÕKÔ[yDtÄ‹òx%uŸ­–h¯À´¢–ÛşáµNw¦”At0ÑwğH)§”µí‡rÎ»DÜ™é5ò`N2JĞñø¾³‚sYš¬ÍÆ=zÑT_3$fDüüÏœ`V°6MHaš±ºĞ‚xºÂ1îÍ…	*Ê_•ÇAüü2¸%2ÅÜJBá*–eÆñƒú/+†´WnÎƒ xú:ŒYŞë9Ûei¡‰ßo)ĞÜîÀØÑŸ&qw‚îdè?LuaUå?}ëÍ^üØ@áyëç¹VŠR7^íÄmzVXìCd•1ñg†N™²Dd…à’"dhU=oxÍN·d-XÿÏÓZ«7’C!4e%—yzşĞ|Awúü<^Z3H{%/è˜”/.w\ŠböN	1c¦Ì_p´v[ªC1ú²G{aOFFöìğõ¯D¸î¿<†%Kz­NRÃó¤85£Î¶>ïÎ}Ğè§æ1¥f·%iß+™®*ÌÜSDÇ¿´\E¨nÌØ ¯nßE¶íy&by‘qç¿Ïs_5âRAæBvwÉ{ÄWw/ÏC…°´“íÄŞcZv¡l’Fö÷ôßß8[ZÅºdaŠg`ÃU † …6¡´ğÎ Ü
ÏìùFÂe€ƒ¸ûeV˜jšù¾vË¹æx |™e "|î¸qe&WÏ3ø5™åy†$ÌlğşTéÒ¤m$¢g‡˜IgNyfFĞ½ë	[^Y«lı4œÂãğ‚à]æçÊ†¸ à ;wsvÃ¦‰äñK~$åÊ9X÷*\™Éüf’ËÓ
æOå9º:¤¹ö^Îİ1â>¬‹C›w{ÔıÆ«¬×Ïq¨*S9
YRªéC80%A¬?…}¢H2¿"…4FMUÄ<¨A/€O'}:êÇÛj%6Ñ=ÀjP|–¾Rfák¡åÑÛ26")çúöf¢¨Ú¢¼Vëh¢~Û°Èã˜â¤©7ÖlPw³Ò2“oèb#|f‘…sÄä/Ï3Öç)tĞÑ®”¡ßÉÔ3‰h“|8©
BPˆQ`rğF!-áWUíBÖ(“ÆµX¡‹„3-cŞïš†·"6YmÜGÈºÌGì¥®ƒûÙûº~H›KÊ‰‚¤«ı¢û¾\yã:u7)]ÿ*„D»c?ÿ•¡yÅ=úÊ/Š‚Ü
 ÷“»ù™yJAãÓMBöh´MÁ·_jX 7ıÀµnŸUÿ;ôö”›¯*½“¸Ùmü¸š˜ì&UÑ64ek!„ïOÂ–ßGÀ€8âuúDĞ–€}« ¹§ØÜ§ww
4/Ô’(À˜VÔù¿˜´Å:–2AíõxLëoaÂ+ùÙ,[Îüví²+àuÂø0íÏ'nÍT„×>ÎüÎ.gà1#À±êÑ½tò´«ÜÅ=YÊfjÒ•§+?Ö©†Ij0„l"25^+Y}¬\??&œš"—qÁ%Œø=TLTø)EVO•ñ³€3ëÇE]0¢®/õ])B<;ÙÔÛ®–èàûbä’³fÒr]jÅDÎ:ÁNx9~KKYg™ÖŒ+ËYª4¼™¿eLDíd·Rv×›·äš:ßù~Ş¢Çî¯(á\dĞà›l‡Ïyz?iÛxMÔE~“]~¨N”o‚Rp˜‚¨ BdçUÔB©P:ZŠ¦5'¦h’p‰ÆÁ_¹ª[„i®)º/) ˜@¥Õ{7}AŠ˜jgKŒ­óÛ|ŠP°.…W|æ£vLÚ„àÙ‚ĞPR­-w	–ÊywêM-[¹ì÷I8åGäÁ_œ©ë—ävÄ2Z§ÚSÔ
ô¦ì·Ræ+›`¿D}¿îà†…HŞ­|—óÊj1*ÃœşFjhì€í×%;ĞDBpnÁÓ‚ÂÿŞ¾¨÷MdFØok,–ê¼
eœ$å“b 	”VÖ_/¾îx}¸¡ª›œ4›‹©êĞëu*hYy°d¨¿YŒj>ş<Ù=ñãá‹'WÍÛQeäğë´\¬DÅw²0d€IS]„ĞĞŠ“vó±Ïé,İşéjÄ¼½œÄ¿öñ	;5«S'Œ^®ši^¤¨Õ\•¸ıÀgßÄéåÌ	&nR³]jŒEŞµÇ×R¢€/‡”-ƒñÊá	&bèšXØâ&ï›N3kZŞ¸ŠêeÍn„+êø¬KĞê6‘±¬¤{KO:Üjq¦™%y™•¬ÒöwÊWÕë€«ù	°Wç ¿	‘_r_#J!aSæˆmŠ=PèÍ‚€oÙ{ÍıÒ]›†"Ò¡:8Kµ§’2òá‚¤*öä2@]Øfÿpè"
°lŸe¿ñêscCËş¶ï¥î•%6ï{½Z:[• Ç£×Õ}åÊS¯nò1ª¨¤pê^Tµ½§ g ¢Fi;	—Ğ •`nÃƒ^tXïy7~×Hbt“¨-£ îPu\òÛ‹8€¡e^ßY9S•ôË—­²mQœê”ªBO¾¶ÎÈ³ ºÑ'‘îúîO*‡ñÈÃÂèºæg~İ§ïÏxŸ‰ç‡SõârÒ–­æÉXOÕ‡UÛÒÒäHi¥¶tğ¶‘’™öä ök¾ÆÏ§eäk¤EXú	MEl»
Ë^§w2f!Ê´ÊLi(mz‹2¼7
ëßË3”e–ma¢vô‚ÌL9 3’Lƒ“jØ6Ø èóÙ`bNoŒ*LçìÚ¡Ğ5˜ûZŠêÁÙšµ‡'Â$^»}8½¨..¾+P—Óc8 İ7Ëï€"b.u£†íchCƒYx{ú·#¯—ÜĞ[zİ\dŞƒhá¶Šÿ¨ê†ƒ}p5yùš5üwx¯º¾µvÛ,ŸMÊp²8c1æŒ`aö\rÀ¯X¢5’Ç¼%\ò›t··‡`÷=;ÄºiëßîŒóµ…b\‹h	´¾€·rÙĞŒ*]N—"ôÊ-¶ø¥b¡ŠÄÖ³«)¶Ùæg€¥d'8cH
pÑNI¦çú½íš(‹ACÉ#=Šï—×æm W‹²:,”VÛÉÍ +?½Qa®!Áæ)³|ÀAâx©”Ÿ2(}$M\_ıÖ)˜qÜb€)—mµ%øÃÜR§[Ñµ”_VÍÑõæù:ò¸ğÑT#çè‚Z©l{ñÇç4™À<Aª-ôµ£¥¥¨e4p…ÉT4jY<7|2f4lÁÈá¢KÛØÌ…lÇ8V1°ì¹üw¡S;ˆ‘VµÏŸT4G.ë%Íó6Ÿzànã©q¶®’Ş]Ø‘DÚc?+|–¶[&BC¬„¥ë”ıWê³„‘hç»Ä±ºr]uRÒ’&…Â<qˆ¥†1’cWÇwfô^w‡#ÖìË€Àk åS	®öŒ'çÏŠJ”U9//h€ZQ_OÀ‚ÌUæ]Oã÷lşk^]=ÁDÔÜMäÏJ¼¬†w„­.qˆšÁ(SY"¢.q•~’Ê¹Mì£¿|è­÷°U±„ˆ+“"™ñâzSîrrŸ`2i]±ÙrÙs‚î‹ÇVn^Ö]EáŠ”Åo®}Îæ‰/'ßyÁ[^×0ŠÄJ±[Ï­Ü¾¹oæ˜ÑuÿFûä;e¤íæp:o’ğ=ç‹ºÔ8È³_³ºGË^L³t§h+=wÚ-?Ò+¾î.s_È)©iF<|jÊKı¨¬ó‡šf§Éqt™{‚ñ~(åNÃMbéõ¨Ô¾V­Zåzqõ™¦ôj‹´K¥ ËCÑ@|_?B.c÷)ßjfUD˜:­Y*¢yQá :Çi	©³š‹0c«@W•Oj†:ã¼]²”ÂÂ£¶‚n?ê/è z´}”`Ê³©Çk˜ÓÃ¼8ÌKÈ"+~^¡Í(yRñûOÖh¨µw12ÂI»ÔÏUlNcëT¿-O¿dÿWÃ×2ş6êB–¼³¹úpğ•ÑJÊï`ÃÚ0ÖßÛßöş‡‚©§ò–Ø/Ô÷Àli¾ï˜fS®û1;Ô-`Vµ-pG?ÃÃ½/Ó1È¹=J%Ïê´Ù"øé"_¯½"äxî”Ñ„š„½frˆ\}F|*ÊÆnÿãh—Q­Wa›µ`¬µÓ2ïõ%á’`é›„døM’)¦‡ÀYËb›èè
…œ/Ú#Ñ÷TF€0\şšÜ9A’Z”ŠÖqT!lö)? ñBDM}Ÿå™êL«AÂ¥‘/ñÖw”f'„GA³röBÖè/ÌÕ‘‹rĞíßç© !a‘vôò‘€üJu5eeÊÅÈ“ó…¢­ëöNFì­ÏÌ[eE,ÑˆÌy]n“¡–8oËª·“`Ç}vÈÍÿËèXÉ•Í¥à0I˜ØhÔ[Äm%uöù\ïÙiRSûFšjĞ:N”A3ö–L‰šœ ©ƒ«?eócêÀIÓD‚>ıÇhÎo1š±É 6Õ’Â|-Z
‚.]K¿¦/ÿ>"uFÓ˜9ñCEôòö'ğ?’ëj_¶|ã„İäO	w/£?}'£Ÿã‚~ÍäUë¼‹Lq•'Ca{ïFœš ©<É¥«{Ñœ¸öäN¬lI×» ¹3Õú©òzƒlÚÜßˆÕA]â¡È½Õ¸€“Ú^}ô¼­Ó~Nkòg—u"æ[oØHD¡xU·‚â1Ù"‹lu²±‚„\ïc­ª‘S×€6 şr¼X,êcª¹£lƒ1"‰Ç…Ğç¬¢¡ñût'Jé?®Öò·Æ‡ˆõÊu;ÂÂi´­˜±· ‡B¡q²¶nkWÏ	•zf¸÷qw—·âšÙ)e²k‰ıËê>o€•qŒ§ÉİõÎ’úÍÀÌ,HSt‹bZ%ús·´rÑQÊ=”MRÀ<Tï:¦áuÜ>d”C^4&öü§t¶wTöSØír
åqâ@Õ¡ˆz’›"\ö©eØi)ô•2”­ÀxL¾ŞÉéæ]Õ.³´Ã[\GÓjüUJÃ"Ô¹ÿm5æE¨#º§-°bôh¬ynZgÃBÁ—…4èKÿ“#¸™L§’F9vkÉeáØñ¨·h½üøÉ*÷òëZ„æš­¤jößsÅ¬Ä©ìùnËÆ<º¶Ä~Ÿ\*®ù©;yîqw\÷ü>ĞSÆ¦‘Õz*m•m'xg7ÎYfb’‚¼0‚ô³Ï²éxû@‰lÈÏGôÛöT¼8†m	Z¾™Ñàmşï²€qe†C@À½Ç¦AR¤@g†KYºsa©d_h¬"‡9KŠ8›ŒT‚GõĞÛ¼sì%ë—a•˜EÚZ¥.½“ÏœÎ¹Ÿ¹§"Ô2!ÙøA'*Â„`}õŠ£ùSÔ­ªØO!,o¨zà,ôØı.äÅóÙ ˜5a–]¾ìÂ‡)ÚÒiqàĞ’Ø­,Tóåjö[+±Oo,ö®5©ùœSH/QY/¼ÛÍ¶Áé²9“ìò[^z}+1—e”EÔÅuæK%HšÒvŒÏ1!¾¶y(û¦@"ş²1å>eaµ>eXE†p£ñè7'z4¾£úµëÊ#™˜¶´/<¢‡N.Ÿ?²,“4.yØ‰¹Ú"˜[DV}íÌŒœÕ>5‘ã™íé«~“Ì¦—V÷ËÔt«zmbŒ`Aù½Gep¸0²Pµ5Š8FÏB7¶Áæ)¾s;ª¹¦s&$g=?Ÿ>
®4.^8	çv•F
w,dJYj`•+.gm¥VSÚU²n7çb>Tï¦C–İ(É^ıìÀ{Ôœi+à5-á^MÖSà
óZEQŒÜñ¤YÆj
ei[áõø§*íÎNÅS>ÎX«P8¬rÔÅ+YSÀ¤P·vôØ?p3¥F’'¯æÊˆ7l¢dù;ØšpÂÛôû AOxÓGz4ŸèşĞÑğa¯ÀvmspäÚÕ­{ïUû™)	‚2½¬i[(»	HÈ“ÿ÷ZL¡%:¬¥~.Lu§ˆE&<@Ù¡rø0Æ~»g¢É[EÒ”ñŞxìÚ‚íÆdI„ÄEAD3ê‡[v**'õÕ'b]—=¸BÑ“œYq~±Ä6 ‚Nñ×U ôS¿QÍ¨<DX„aN¸`»ÛŞj Aq¤g™†ço÷ÚÑwL›J¼FSP¼L°Tª§g¢yBıX‚º·°¤Î…KGñ@K„•X´zÌGí«ø0Ûñ]™a’ı”¿àè†—}ÜÃY>ı§„ÁÑ+³3ù2*û,¤æÊ3XTf;På”JuIªYï	¯Ïf”„p.pUûÑ+?>ÔPJÒbBï«ë1,ƒı>5¸¢µèw8ª“ÊRc9v‹—.|ê,lÀÊPx¨æBVh|ĞÌ3BÑãÏµ^›É»Ü;şğëÃGØı^0t²F¾o+«âY¬0[ç2Ò»‰GßàæØU²H2=ĞÌj f?g‹j‡ïÖõ1â¯ùôü1÷EKvXÜc_£Ã5[F‹Ÿ®2TàÓD«·¢J_â=Ü_üe÷QÏ\úÏ{Z50¥éä*¥²pÒRôÁµù­èãvªz£:Ríòbj”yÀ¨‰j°53ÚW”>9Ûæ‹6Ÿ923/Ğà5¸ŞQÓˆTšÕıàì‰Xwm7·½JÁÎkíš:üw]ÆÌ•óÆS·5U ‚úXºï­øÑ‰ô,ÛZ¶!Ø—Õ7k>’bÛñ;3N	\YêçÏcƒ=é}~§zª7¬M+¸ÜÈ¬i[À$Uœ‚BÙ"vã6®=ÅvÄdcómãßd&×Šÿ —Z\ö¬†¥zò<–»ûå,ËNEKÈĞcœ%Ïj"Ìö…5N"ã/M)£×¤wé¢¾é_b˜Õˆ¶éˆ¹¿¦ ÂUñ¤íayÆ	ç•r@ŠDÍÄ9@iKÒ›â|Üâ07?ÓÅóËopçúÚÂŠã¬`4Â4ˆ$ÕméºïŸ<©”“ù¦›¡£0wE!håha‡òW…ÎP;«ÂÏ8ÔUê‰›Y¸úkò­—œšÊı¸àG¨Æe#?+G¯5Yqë3¶u åÔ¸Ÿ\nã,3ìØš1oüzÑÌ…
>Ã’ê\ŠÿÑ¹‚È-ÑT˜ıdÖù¯(+CKRıTŞ³ÃÏµ×š×ópi)*×±h­‘1¾öİø7.˜KO²-Ñh™ÜÓ¸}¹‡Ç¹œŞ±J8À;ùÃB	ìÌ—Ÿñ¨Òçí¯÷İ†MVgízĞ¢TßÌß/KFÉQGY÷œ#¡Ê[RıNøÂ™º£Ï”.óKJ€DáS´D^•g0÷ÖM£UëãñsÏAâYêI¨Íw‹äÒ-§5”äŒ»ÒrèòpY¤B•58’gaCÜc¦p´ºt£i$ŠLnl,³â6"È!ç‹›¨)7ÎıÇ×ƒ-±I—]vû]ámnNz9|èÂ2Ã{Üï73Á]/İÓwa{RºŸNû°§zXlÇ¬c*ı‘7&3ÔeyoÜ“#Üçj“ª«<ŒmU’1 ærÃH??$´´c·J;6£´¦F/¥½˜2ùÚ,šHmmP2ˆ¤gô½âåáfjGV
‹u>*ÕÀHøjC·+zV
hU>~· Tk ŞˆN_Í`–]İøkS”­H0TWãœW¦oK@ˆë»­(Ñe@|Ú².6¯É]‡!@òÃÌd@şÒ+ôK²1F-‰#oQAò.³s¤AU@ç(òDÄStÎ ıœÌOK	¹ŸP·u˜òµÅO¿œ=´è'*Ğ(È…<ŸşÕ˜uùïb8Å˜UPìì_ñ^áœÔw­&£8VÓ(‹/Q$å”“zò0Wíj&ìyÔĞĞoˆ}N›p­[uü\3Î'ÄT6ÄYƒŒ'œ
ÃØ­
õâf29R P\»)±`îUÏ³§ç»ˆhK:ğàVF}ïÌ¾‰¶rºĞ$£Üª
&ÍºĞdµTK)Š+Àğ…½QÂIö*Ãºn‰D¼HHÿA‚Ú
ƒ=@²&½¼Ãk3tÈĞD°@$*£´¸s:ÿÜ±‡ğQw„³N¾•¨SiÃVGÚ¤b¡I-öB£€1=Û;F"ÑŸpÎÜˆÔªßGÍv6|[à6¢¶š –OÑÓ]½°s*HñXvÓ€“üĞ^ì¶–ÚÇ©@Wg ª1!Îø_›QÌ°`v[‹+O6šzÔÚß¼ù®V0\bò:9½ØİaØµÍä%šÛÌà…^ÄáÀƒ/0ÚT_–O€%\lQd§c·aD+Uøt´¾Ûg‰»‘Uü”¹æ˜Ç†|‚ÕH»§@ñ¤i»3µdƒ„²]:s²|l~[›äF[œ¹QÏËò¦ÜÑ1/>I4F¤U=„Âh• å	“ïNEîåÚ€C$ûÔ(§‡õBØìó¨†.}f.O›CîÍä\ÆOo ~'n4T·Ãíù ¶‰„sáµ”!¡…ÔF_úRß~¬²àé#gAÅÌ‚¸SÎ¾­ÓQ wûC}Î;éÆ÷ HQaÈ'0J·]MÉäËxO¥»QB2d—aË²7–-/^Äåƒ'¤µªÇ™²^6e:Ö>ôICœ]‡¯TŞ?­H{ ÔO¶A6ÜÆÄ˜ÓÈ7+Ë"»áFäĞW"kFùÅ4ÿúÔ{H°f
0M‰8ç{v¸KÓ…¶šÑ´§7Œ.åÿıû`:'œØŸ?Ãvš9á§/»ûô¡¾ˆ^yÖ—3Âì‘ãÿ÷ïMûCèÁ8€¢CDnåVyÈˆ˜ëv¢µk}3˜wˆıF.¹~Š¯³#DÃîæ#ª¬ñÛg—!jUj÷ùJÓŞ´ØŠm· åTÂkzîóáQ§YÚ
SânO{ë^›Pò@¸L—òwWXÈh7ÊUG„µgj®î:íÃ^~ŒÈØ–)Ñã³T¡¼3Q¾¢N”–‹è$j½ øÒ2¤‘œ\6©j©°À'80ŠòŠ»§+1Š·gÂMG|„I¢|Eàx ±ñø\NÀ¢RÄñNœqúàÏğ±!õb‹7æk0Ózs‘ª@a?ˆvsDÇ829™|SƒğE4®RvÇGÌuşâ[”Æâ±EH÷ï¤”ª5Vâ ö§Ù@E­ëa»¯ç,C¹Ç°øX@™}r¤ıå\‰FÕŸTÒBÄöì²5«e­ß,0øÅƒèÿa!wN>À]	Òœ/ØL	¹
½•n^ŠS»´ÒŞˆ”so:ü1?á	¶Ú=öb‚¿Ø?wÃ<ÖGÜEŞ*Cø¼¬+G-†×Ò:— 'iàÅóy:JG…š¹ˆCÊ«¬L)4I÷±@êXëÚq†×e°1HG^VvM MÇ#uÔ"~”¢şœ”j9ÓG“8|xÀ~ïa^Ÿ±ÓTÆ-¨özR˜ÆÒyğÂ+4Ñœú}W|£”âkºkçS)¨/‚3õğg’<WjP’ü÷r¼"•³Ş”J]²³9Ëò®}´ÒL|d%ÉKb÷ÇÚ e"³~ÙÑÿ.IÓ²‘;,„ö0¦ãû ç£èŠ^ÙÙÙĞ¼—‰ášÑZJ3È˜8ãyÎX
?É\-AœJ•¤,:äÄGm¨5†üzF'Ê_Ä¬ß¹Â*\AğƒËgü:ªáè»ò¬9¸Èİ¸h%@c“1„äåg×i1â…(¿èV*ÅÉVÄ ŠÍ”9nÜ˜Ï*“/°¸ÍB»F¤QC‘Yš4÷¼…¡¹ü¢+“ˆE=o]¤„iŠ+Óéá¨ƒÿ	­éÕE™K¶³–›Ò´Cûšcu2S´G–/±lŠVqé{a²fïy’È¶aàIæºÏğJÁ›Á_”mÖÎÇXÛı«~ó;îŞµ‚,ËËOowH$‚`¢e×Æ¹ı«Dáİ+CºÖACÎ×]QÉjr#É&ÃHA±®ì¡ïigØó‹7+ı‘>Íı-IêÙrğ˜+ `uïËÄèİOV0m7Úøhô³j¨’VriGğ…±…€†c_4ğÆõ‹Œº2v0‘šˆBÿ®7dãã.„qÒê‡ùFı`ŒÂ/»`ş$„+!<há˜|rÏ3ˆhí`NÅb‡ğç<8¸Ó¬š»šÁ«ÇNY%Á…wøÄ±N/Y»ö& =ƒx£¹¸ûğ×½F~|ÄÖEr"Ó¡\[µ+L1–
Öß÷ïyıe1Y×p¸GMÆ	–Îñc®yºféÔÿúI—
EÓ§,bÈa€´Ì¼…gÔÃ'üCÅ6Átrşÿ“"®GñOç7k¬ÁT¼%ZäœŒ<ûİ¨Ÿ¡ëŸm‹¢Ö2g„S¸Anl'3XŠù¯‚œÁò¿àÄ‡1_ï°vH™o2H£©âÂ†°UÙávÏßƒ¾ÈªÉDÏgˆ¬´ñƒUÍ ’˜/¢+°b£m@&YY±Ák—Ú$î*	O(·StØÅ©=?Šåú·gß\åKA¼T¯{>††ràmæ—×põóÊÂÛoö÷©W…
»Ø±ÔˆPÓ"º $1ğ6·xÙRe—+cµüpß":MfÛ)AJCbÑÎÂZ'ã­ğ˜Ö¸
³×©ÛMleú=6éóİñ!†éW62À¬9h¨l¯x¬CFt's	¨¿ï#æUST¯äJvËTã±ü¬û`øˆ½¤îU}ÿ­¸tÔÅß§`şÍòâgYØt`(Ú˜Î+ÛÍ¬ÂuEÿôÙ%ÁßB:Y2úÒOXi®]ÄL,ÑK$ÃóOi³C EƒÓ›m]¬2‚|§^‡#ÚZ¶Ó~Ø‹Mxe uÿÙÏÂS÷ú)ªlr¾g¾v"Ä>Ï¡xºÛ>¹   4JcÜ<iÖ ÒÊ€Nç±Ägû    YZ