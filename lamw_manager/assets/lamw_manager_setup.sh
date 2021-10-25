#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3066866895"
MD5="95cea18d013448e35e55252c85098770"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="24088"
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
	echo Date of packaging: Mon Oct 25 20:40:35 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ]×] ¼}•À1Dd]‡Á›PætİDõ¿RòÀw˜4'OÓ¾)&yVÙn…N:ù«"t£ˆµ80÷TÀús<«3vd†ŒKaıÉ500mã'ë$1DèLFc;ÃŒìr¨"<`¼Y7ÑA‡Ó>k+Ãt´ã-¢ªØa Ñ|­dOşŞÁö–6ÀˆÜ­KK±z5HÏ|òìœ—Õ²kIã —ÙseD(Ì,j¼H ²=òxÅRÊJQ°È>çü.I·àK>:rvÀ¼øtÆé,cÄ€BÒ)]÷âÙƒê»TµlùüÀ`ú”kÔVyğÉXê”ú˜/ƒ™·šåî»C·Ê“Úl%O‰Í§ù¬*.Ÿ{¹ªXI”±ƒ—`Ş¥†ôû ÕXK–	Ÿ“©×‘Ë‡ÿıg	>&Û6ßàu°ºÄ`r>À¤ ƒtXA{ê€rO«­™òŠIÍœQ\€@fÌ¸Bl h[%Ò}¤óòÂ¸¢…ÊQ¥s#j ˆ^èÃK³;Éè«‹g`X Àbh !v13ˆ•qÿ2òÒjº„]6Ïp¢§Ì—Iä+ü¼z%q“«+¡U¾5Ø¥8‰RiÜM£¾å¿Å•_J¸ E¦Š(Ø©öÊáòÙbP
ú¤š]CDk
,FÆú¦Pu©`-ãMßÏÎ3øê#{ÄË´}êıÔÄ|s¥’©kêÑÇâÇº*õÙĞ.™c+»;UÖı­ª´@1¿çİn÷¸½ü¨³
µyö%ô!uk(ş¸Ö4K<ˆÒÏe@¸VšÙSìU%øeZC 6C)eöj¾ÍoòšF,ŸÑc	i&;åad|Ç”sõŞ‹h¦Í´mI¢e¢üíR±ÿÚ¡ÚÉÆIÊƒ×¨è}ú¦æ]z¶Ü,ØÔÇ™Í4ZÿEâÿÌ¨‘…î¥kx(O‰=†upË=s{úÌ‘¨j˜z>DeÃç™
9tÁó¬jİúq[‰·ôÎöS½.dBïØzÈp¥Të®¾f3~‚§	`ú¸Nxk.y
bæ@8Q4Œ*Ùa—£+ædfh¥JO{c•˜K$ ‡²ñ|r`Åì8ğ·IîE«í›ó1ÙÈf±Pp‹>òé™bÿ^±ê•ŞVŒí5æRIû“ê§SE¾¶®Ş^}nNÕòxâÄlGÒ–¸–¬YBzÊuªzãz#v@†Ä¯[×3„6.%æ™Ñõo?á¿SßóE²2‹î÷ÎÁ‘·ÏVi	6=B5bXíHb˜x¥Z ™ñ¬ \+5Ô„;›[…%
òz#è`Ñ‹ÅØ³•¹;,¯İÉ`¿ë!`ÓV7tá*.a¶²n«†Ê™‚†ŞŸ×5[b¦¾ÃØÒë‘Ò¼”Kà æµ¶7£ÕzÉ’´!Ÿ@XE›™¿ İ’J'rØi. ¯SÅå<* :=nR¸8À›ˆŒ*B<1bË±õÅ$ı"nµ(şóNJÄü‰NªçrÕaÀèŞdw@+†w!Ël’ø}Ú¹¢¦”,~¯dµ"òi9à“‹;YãwêR²[›Ò¦šb{ùœ½$)¡òÌœ3eÈU^Ô±Vú¹ÃTaÂÆJ÷÷+±g’|bÎÎÿÇT/ÑÂ[nh;wQºm*l-4ZYpAØT¢óIzË©Œ'öaÍ\¹9Ìa¶?¤ª?Ã¼¾×¤’ş ßiÓR¯_á:v‹7&ÿ‚iÃ™Fê
ÒàåÚ-gçëÄÔŒRÕTr,¦ˆ8N_æÌ‚;õêÏâšK°CbÓùPn·³I¼9^VÊG“w­’!n²:‰ªfàÂg–ôï+¹ÿà¥JLËVxîıA5C-°–rZ,§†º&qºPMVú(ö¿Á
àÍr,f’P;÷ìd|â®&çó¹g¶’¿Ÿ“7Ÿzo¼¢Hó²‰.ä™6pãÉ(
ãïØJx°¥¨!–8.Ë¬ö¸ù——C? ‘FjğrO‰-eÃ¸_d(dñ÷˜ÒÖ‹‰ÄRéKâ¥¶}{d8‚ÁªëöÔÄ™ÎüS„ïê·?7ÛÁ=Ö1uùÛiHŞ|TŠğ]î6ª>ÖXä×uˆ4•öÌxÆ©¡tÅİù@Ù :à.”’ª(i˜â:È;.z¥˜g*n·¿ÿJàÊĞ«ïSæ3võ¥ÉOšÈgüo}_„-rÇ ,ÉĞ•ø!Z‡ËF}ÑÇwUÄT[×p¬wEWRIûB0â‰8/ÙJ:ÊëÖA,2çÓaéƒÕdŒqÃùšÃ{ä;V.a€„T/
d¯¾×ä4zJ•a†G°yÄshÿHñ¸ÄŠ7­ŠÌ]òXúù½´Ş©UÀ â¥”–‰W2ğ»Ğ8Rf-<@ÑòfĞ_g“»Ú%¦N &ÊÆ.–:ë˜|‹ºdy¦HqQf±×{4õk¤“[ÜÚ*·OÆY-xğVOPùìği‡E×3ƒÈAóúô÷u\¥åöx1´¿f f><¨/ğ¨ò¼-‹5máeÇnĞ³øI™6ùì‡‘òƒÄTxåèRÀ0~&u\>´£8U«ù‡«şÄ;ƒÉåµ95‡û¹è(@*tDlP“$µôgØ—^i£og%ÌÄ*K1æÎkr Nöì•r3¤”Ãj\CE0Ñ·æí«ÈDìãÓ¾ÜwQg-6Y–leâ¥K&7}ùnòÓ#Q‹Á˜ïq<Œ@I4uôóA $äÔS›¢İï'kÎ=^,Eæení=•LÀ‡g¯šû'x®6|õ/Aä#U€µ+_%ælÏ-Â0´œáÕè¶/»íáÆ;…±`'êŠÎ¨ö|T±l^ó½`¥±Ïw™Õ(ó”f­Îk¯e³gAÎ°Ø¢7†³E
2'FZïG¥OhÑ
8“$ˆèAç)ÃÜ¼üÔï[‚œ&c__"êèa—`Ç*@b•­I¡á@FÖC[½pÀr£@0e(ù·
xêúşu•J0»{„C¤s©ä›¨ªÅŒÙCóµ%/1§ÎõÑ2HmE³Ï®|bGö¶9€pàLö¢¹|¯P8º‡›ÈNÕJığ½ù  Ê—ó<D–ÇÌæo`ÜÚõMnÛÓøÄÖro«åiQ¼‡·µ™@¬…d¾yWUÚXó¹Fg}ê¾[/Òñf4@$¢¾DÚ´Ş0¼ª9¬ÂT¡X«€†®I'Ë³°Ír#WÆ’çõ$5f1Úb•ÇWm&†àJğñF¡ÊRØGMl«ğ×2öpgÃÕî¦QçÅ›ŞVcâZñJ©?¥—˜{Ä4Añr÷²İä ‡«\'ÌËú4Æ±FÆªÙUÂé¼ÑîÑ	û™´ù¼Kou®ƒ;/HşWıŞ8u.ÁúcRûŒoÓÇKJ<¥ß]Èî˜ÎDîC©»ö0
”™Ñ¦M®¥’7uHó¬ i‰ÿÑCWÙ+ÉfD›3ÆPÎş8sõ™Üå;vÉ•"Â8BŠe{™“ |×_?a}ÎX¨RfÎ0œÃ¨4jòè)Â¬­o9§ü!‰pœ±Š§§ŒKÿ=5ğHaÆ'xJº~¶TOËû@N)[d7&òßĞrP9>0¦ò•Éí«RÒP2­ë2vo¹ZEi'Ñˆ6;ëpJÑ’+êÇ&Š î1nXÁ>3»DüÜ
?N0;Ùü¶ÉgŸ¿aùwOµ_¢êbø#º$Å1è¶9–YåˆúùI~`.:ø2P’õí*²v¢ß v{İJ˜N¶th]~‚ï¢¨}ÂN½zSÍ3ËQ²í‡6ÉE—q«Âvwtu”á;ÏÔáaåç]ëjæ:,L©š7×ÈußÈ:?6 Œ{³¹w¦ğXw–cªÎ'ÓV¿¦ô…Cö }§nÖ1®»µU¹&)F1ÁõÀó¢=gè‡õ‰^0&ãv×7 —B[¿=OvÅœ¦ïÔ‡­û”s·ôO+İUpl!÷‰sŸ©OƒßÄ“Hh‹ñ+­£a[ë¾ğµ¤y¼?Š>5³ÓçÎ­¹IİIÇ›İû6ØÂ÷'šÆòÂ2™Eú¹îçe{ihİ™ùÉGOÑ£ÖÕƒ¸íG·ñJ|G§’áslÀp'ù¶ÑwY ?1œ¾9wExÜå	ÕÉÉßçà}:ıËLÈ7„ù <÷¹uIŞ|³jÕ¡€®k•ÂÕWo}eó$¸õğÕáú’lR§0¼2úÄ`2ç´I‡Ûİ+êMmÿW.JÜ•¾)êüæş}ÍŒWù~Œ2[»Ù[ûÃänë³ovY§yƒuãR%<5jù &rœKJBq	Ô³³§7CréèøŠ€‡Êˆ}†_ÑO)ƒ“üçßó?·	úÓ›Ì±®ÍYäcÒßA^ hïëÆYb5¦½AĞNàŒGn÷¸Ë§XOê°4áös1cSïŒL”ëùå'¸á»Ş
4QŒ	×hoO¨ÒÃßo³ô§Ÿ?–rS•#ÂÏÛPÈ9£&¥@0È
¡¯ëRzjJ+{9Aeäšw0Å7ÍÈ+óvøM\æ>”­'ÔQõ)¶|†‰é±ówŞ‚gOÊp Ğ‘=Ãæœœ-Yt"Oç\úÕwu
a¯»ã|òM³%œy·»;ƒ) l®¡yj°ü5"iÍsäÇ~Â¥^‰j<e2’Œ†4Sn$å5µq-‘•ˆÃÒÙh«›Gìø¿íâ³–tb}zjŸœgÏ
A™ Ù³„#Òz>rAl}¿²z› zª4ê£­Zb‘SxüŠûˆ¾>|¶5ú¶ÆI*díë4lï€2ém,·9+ø@L^qwAâtlŠ”S0ZÙøè¥†SöG+ÈI+­~„Üºşö*«&á
§™ul¨ôéB£m8„0ÚÚ1`6öñ)aF"f`>´à]©äp+†WØÑè£¯¥aï"x] IWäq”»7é5ul«!*Ï¦òçlÊq™Âã›»Å˜­dœ›¶@túHæiÒ©•á!IËÈKu¾,¨‡ŞÆ»â¦«3t² •ì­\ì&T·&,ñ‡
½a}U¸nğû»ö!˜üJL]V«Öı~fSÊX²\6ë2[¾¥
A3uˆòœîd*i~àè¯h /ìºE¥Pİ+XYŠ{¢Zfl_°•ï|Ö¿ŸîµûtÉ¤:?s÷µU‡9¼İ.ä Md'ÎÛ%mph	Bï(±¶1]5É6®¯„¦´6PË¹-h’‰”Ş-ªa®yãCì4C–Á¨î}æÑ`FuóJh¦Z»°TvÿíW:‚ŞœBbŸ¿³ä“Ä{ò(à*÷í%r,`ÎV’	M¶şæ€í@2?ÇYÓˆÆŸ1zêÀÈ‰~Yÿe»Fû€&£”—üvÑ>1jÅ¶“û¹Zí±t¿e2ïÜ¨üô:"ı¼ªeëëñÃÆ³Àç”Ê»U_î÷ I¯;–Éè#Q>v-ŞÌÁğÆ¤xOxËp&¦,:ŸÀŠÀ†ÊF^¾íe§©ÌØÔ§F“Ö–E›¬Éì$k)ı²µ˜j­WÒßßòÍX¨Åb<*ä2o‹A¦«s5’\?g=LjÈ¥ÓÌ[ÌQ]ÄÒÒX5…— à¨&Rm ¿ÃÌs¸uF…9ÛıYK;&„¬¯›¹B}|T¨'4n÷x•*@ÜÅ]ÅñˆÉ÷™‡À£ê—à–¼F'»‡åª<<†‡&õ%)Œ¬8H0u>B…[…¼0P(H÷pQ‡º¼U;ãhÇÄE€®™m¶ùğWcÆ/™%¡ÆØcr0FRIğ\Ôñåƒ]ƒû°-hN(„®÷Áá6w)m(aHòA®A:²CuíRyyË;ä·×>ãDÖU4_äò;WyW)y™–1—˜n[…Qı€Dóñ¦S²xU÷Êg”;“×ÇR$úèÀ÷46¾›ôf èàËBà“~&Ø\£“9ø™¢w_Ö z±Üïb±Pè9(–‰XŸŸNL`±ÊBîÒ¤ 4…g8¨“î5[?uÓ/†æ8~uc«š¨óÇ @c	‰—@÷P”ªÅøÕßŠ»E
=ƒ€Šh&ïË¼§›û¿'ûH•9];25Ü8‹;w<cÁt–¤êÈÖ…åÚª
¾'Æ|‚=B"g{ï&,%Z&oÅXØyûı6-™ZÏ(Q3ĞÎFFnÙ‹¤ª­hYÿñÈÔ3S_˜A4`’T:¡Åaéõ+ŸJ„9ü7æQlíOP"`”Qå›˜0‚¡^tE:9T†gãpİ’Oúú).‡ßK àáq—ş~£Êã­ßY—” ¹dnûYí¨ü2×§³	Z|$ÀÌ®ûbûZ8YÚõ aS”Ñ‰²ÇzÛ”£¯bêği†1ôõİ#ÃjIº¯_n‚.äR×ü£Ë·ŒG”ı7dSz*ñõ9ÎU`£ß^D.ìX…ã¹½Œ“5$tàûúZÀõä%(ô‰VĞ	-Íër$É{ó`¹ÏóÔïß‹…š%ó©½áş8)Ğy_@8ÒH"9„öù\WıÍHŞUK;n(âÂÀÜ±übágáÃœÔŒ]B½«_]’ú#mP–ë‘"K@Z¨w ¤jõêÙ!ğ&;Ñ"›pï„ÀoàÛc-Á½¼ªôûôP[ƒƒ[×ó”¥À,×ıÕpjq­Ê“N³XÌfdÅ3:Ì½1]Èœ¬9*4Ş—¶•3PX’{ôFråŠ¨"ş¬] j»wûO·5<|€mñ¦[ÿãÆ9VöÓQ”—g RGFôûW¡BRpâr
Z,Á¹ó=”_jƒ 7µO¹Tüwl!Ãşa_Q0N4V&³bâŠæôü‡¦‡dBmïŞH«ùQ„še‡#é
JABªšPµ ÕÙè¾/“*ä£Ò³@F®ˆß¶š6`BEù2‚¿GthÎ~¬dö3ÙIrõíHBÒ²ø¯È$.±ø€môT¹èü(F"¤RÖØöoÅß…lD¥*÷­Ñ Ö+¡|xˆ„3yiâÇäö0Áff˜Â)Ûía5¶1®~¤®\çÀÜÌëŒ0KQÉ¤GÁÇ²ıa8¯¦í¿Û,ñ9¿ö¿R%ş«÷(¾;½”éHò1{:$icªÄ¼9E-òŞÄãt`ÁÖãˆIhkŞk9NŒ"»º—.ä¤Vµ¸C£Äa|’ø!Kù3ÙÔÎ,"ÃÏ·İ {|åcÏkT›‚s†˜è)ïÜV•ŒÇ2 ©6åÖÓ^—¾_×v<P¹èûd£1ºĞ 6à+âõ{×ÈÖ2)ŞytCídd€«>—s
vu!Uëş«:£°ë#Z1
[£‰–T§
šVŞp(Í³ìF8x|îœù,È}­œs<İÆÿkÆƒh®Y[‘e@Ä[Mxÿò¸Ğ‚^QëfKèxY¦Ènä2Dá… ¹z‹öì”ùbAí¦}unG9…öy’*¯‡5ÖŸ51¥#{R´6-èÿX@ITÊi2‹nä3{¿ïcÄ8‡ê¼äšN/Z¥©1¥ß›%¬êË5{›[†M_¹ÕCWoxpGX©¬).\y´cBöDNoØÙıú!5ËvT†‹æìÈ |-y€»[œip£Ò·[Iê˜¬´Ü²eø² >kSIV31ÃøK…dFTÓ9# `¡À‡¿gÎ/ÊÍ[º …X‘ÿ·ëŸb¼MKAìÂ‚IrıA„ß.	u£Ä76¥h¾nõb}áRãHÕıMÂƒí°»Ç"Xı1mOÖqòtªû¸ŞÕŸa£&qÔ°aéâK^[Ì´x€{—¯_ÕÄ÷÷Ä8éañ¼SÈs0Ô³EL)ÿ&T›lÈ3üªï›#§‡Ä™ÇyãœŞ²ëÑï6crŞŸlòÄŠ¹C5÷³=?¦»ÁTƒ”šl›~ñ1‡|íø“%®×•åsß4™TüHÕ)ÿ«öùïXh
 J Gä	ı|ÎÄù“qş?ùoxWªØÇ\p[‰%ûQ-—Ao3×OwÅ×[½Ôq•½ñ•+¿2ìŒœ6á~êá
‹üç‚ğ+I¸¥V±wş9‚-á¿Ğ'‘gÂQ‹*-Vóğ;_qŞ½ã¥ñ ó+Sk…É/¥çI°–’¼.Ó Z3c£hf'”`Å“riNH~p ò³zùå'ë:ÎéJ¨0şÈ4Œæ¢ø‡ÏV»[•P _ÎL˜€T
+7¨Ú95ş»qS˜7$†q+6õtBê8äÓ›kâjä‹áªŒı5D²Mjõ5·Ú­ÑoBÏÎM\mÍ*/Ê}î€×Úc‚³Õ±1cZvŞ	SŒî
À5 éîñ£÷ş†PÙñAÆäé¨K­—¬¬¥OÜÄÊEiÚ¾Ã^‹†'º˜ê÷¹AZ—nµ‡deqƒræÊ™£Ã2R{URõ²‡°ÛEºœ5}îdú‰Œ©ôËŠ÷VvgÕÑ4-1­må¥®uëÅ?ş–\ı¡T…°-o†c|>íı§Í[j@Ò÷ĞZ|2µ ¯DŒ}«%+jÂ¡WmÏUøš9oßar~³E¢°êÂów’ée©©üIa55‹sPÇA¨ùig6Œ4*×^ë3}m«·<à'L!à*·o**0çÕ¦c¦íX'+ ú
9h}UæÄRÎ}©hMØ–ú“ÃgDÖv‹k€=çÄ£¨rÛs—"ap\ÇúÁ[ª£š­úÄ‹ğÇ½²VŞ¯%Œ¥u<ceşÇ0Ì ;F
ä‰¢0Äç™äXnÖ®£‘w sÈFª¥	çËj©Ó¨Í æMï\™äy²ãŞëw¦Ğ_¥&’>äÅFí—f]ı„ÆKb£‰>ÇŞ}£+Î¡]º.ıù
¡Œ€‰,Béñ\ø‚5PèãîôÀ[ƒÄş¿=ÿ&kíµÈºzU^†ï&Ö:Ò	4»DvˆlÜr3¦ÀlÇ8Ş[yäX¬lçùÒ5ÖĞ×56ÓR•^šş@ñ´K•iW¢NK³sM¿{‘Û—*%åç=”>½®Î€ŞƒYY±6))ÏÍ|lC—õai“Ù‚ ‚RW {o¡-:›Ü(w÷C©yöD’6hÉ£LLÛM ¥öû¿‰‰mK¡ÖmÉÃùÍñ¹‘uwÙEáoùòa;¶ßëôÜm‚Ä-»ˆ‰sa+ëJ
\<FP±6‘ŠŠÓÃ"™È´j Üg®±P„”lMÆ–ºqóÜ…¹–qõ£İ´§¢9dÈ0‘÷çAn'ìFˆÔ¸e[
íIvÑù#¢Q%r’(yÔXĞHÏØ¦P9ùw‚œi	½äI®SÚ‹åËøÛ9áßÚ_ğà¤°$#À^]§2¦úQ|0ØË¢2àÙğ>¨Æ$nëş7ÈãdPEF'—¸wìï/†azfÏ¸­#|U‚mAzªO°~N;« ¼5_[Â ÚB7I!<¿„õ1P
|ÔùØxñDkZ)m+4Œ)É»´=¶Le†Hºwq‡à–køÊeoâ¬œaÚMm©*Yq¼GÖW7Ôs2Ş€ñ
ÇşkKÓ]v# ßªÕ±Ùx%>ıDÛK5°Ï¼cÚ§¡¯“cW	Öxè…İ²»ë1Ä3;Ô£¯~ª”r>zôEhvY½‚¶Ä*1…0€öC&´„?<Eâü”ê,‚ñ\ÁÌŠÜ€å'‡k;C‘Ğ¢•fÊ¥Y¸ÁI‚û‡Bappºaóô:ô"ÄHœ >asII‡ELŠ™~p$=$:òŞ«Uwº)˜TxºŞc”–»,qÛ‰yŒ¡{U}k‚ï}ªÿ^² (Uù“ŒÌğˆäö°º^*1‰öÍã¨¶@”AE(~ÔãP€ñYÔôŸ4"¶­Só5ízaLu#õµOY²¯%	/Ñz¡©ŞTâLÊªØ‹ÆÖ‚Ê?x±h¤6OØÏn ÕU’!¾ÚšØ“Fã’çuÈ¨àŸó‰N%ú¾Á[]¼zãYx¤%L–UC2!2“?ıƒÌwh¤Çq\‰îd{@yk.}$p­lKÙ(f³ç!w”ZÄO"ñE­§¿R@]Çõğ.´?Öå‡,§Fp…w›b çDñÇXk7è¶®åêõ‚‚Ÿè¤ß"ULí¦ô¾ı°7õ´ˆUhLÅ¼¢môıË‚kLs¿Ğô—iIà'@p2'~ò^‚w}8ëÑkæiV4°åe”šÛv|+Å¢uWRåkIĞo”w:F<Êéó¶¬vÎØ1¾†
ô¼8Ãbxáà’‹œ.ªt« é3ì½…Í(Vÿ›e+æ>5IG²Ö‰ZºC‚º¦‹wH³oæüÕ?À
?!:Ãj$v*}¼ÅVuWüB¤¹cÖşµ?º”ñw5O2wq«Æ¶‘wŞÏÍ6µŞîôì1×³¹|§óË€Î«Á……á&/OVÉ’%v©rXÉy£+º<1=_U?uJ[ôI‚Ò‘oraî ±åu#æÕ³×rzÔ,6K„z‰£à"3F¦òŒáÓØÃhØ°ßMñG+®şö¶MkÅ±ÚêV¿äÈ0D†
Zµ@khmŞ*')êÒ~´[ }¯Ù» ¤üùn`¼SôX¹PIÒšñra›]ÄüQ±ÇnŸ»(†)-oÿÒ§£¼q+…f{%äµé"(ƒ(İÊJï˜pŞìöp~ ]°.Ê—Úg§wªVòˆF}·îA$ùÊaëöu6A~š°Õ€4z9®¾w¥~
[$
è¿š²Ç7í L;:	Æ·š“‚îGzã.¹å~ögU¢Ôf‡s8™Öû¨7J~æt™ 88Â¥AÌÒÓ/Ïs‚¸tÏi]Å~C×˜¢ädwÇ…9n K.xØL/ÎŸiø*B(n#W˜âQ<²{_ã<!¾ıoÅü@ sAíÏ#b„&	ßú—˜ºõ“4ÊpßŒ‹ô«Ú“O®B±êNV¤lhA¤£š°¾Š¾µæsÚ‹C÷`9ø}½ø°lbÖ¼ÒPôÇ–,¨à8&ãMÏÌ2úÓ×,ƒõİ—ÙŸc”tGç…ÌŸF‡xÂß9ôEşš›t›Êdö+û€6çú‡gİ"°Ìüßç–>ùîÁägY!ñQ	èl´d¢½k¼¿ÎF0síp•·Õèã”vòÁH][§2éÏÈ+…Øö Öøáj€]mˆß¥+˜ğÉtšgmà†bÍÕ÷3. N;uxí­ÒW¬(Ğ|¤ÙŸ@â…"ñĞÄWÁ£’ierXÃ‡$]SUIô 5Ân8=\4&|ü5ZMDæ‡Règífî#L2AææwÀ7U\¥øô“øñûeä=ÁŸüŸ_ßğvèÁ„µï¤IYÃ&#yÕd2ûAï N.sŒ˜Ièë¤\?¼l•VhÄ ŸvÆ_ >r\¢ ‡å!9R]Wƒæ¹§@ÌQ
	R5§ƒè,¸ğ˜@×x×¬7Ü†–c9Ê‚f¿•T¾(1¿­¤ÊîÉÑÅÍbúÉ÷Äº?]ÂŒdºasRÌîb6TîFÊøYïËÛà9_½°L¸ü¨ü”N™ì+®	˜fR(ÕIÖvDN‡ö"R(™ÅÿÉé|ÍïxïÎËY?–Üè*7áiál7=txğJJ‚&)|é|
—¦uÜõÌ1cY6•€´¡d—'â‚áš(Ä[ü=UTIm“+¤è ‰òâãmÇ»j( P ìãÛAÒß[c_F ‘Ç¿Âİ¸ÜÙ>w	CÏ¤1IdÏÿòK¡'p)Ó¾§@2=×€ZÅ
N‰­z„<ºØuq½+È8ô±GBí‹zHìm€´miò;R\h–]Æ|x©ñ’Ú•…k¹qÓyYqÃ12»EpÍ“ŞêcŸR¹#òerùº6T†«»¨|*8¦m ZÊDÊl· ‹•¡+ÌŠ§Mrå’u7‚Ãùu©Ô,o9¸v	cÈ‡øÈ k“ ÒÍú"V[=¬
÷J{„_ôÌ.ê”ÏYú§Ğ@w“º·f?$Î@¼®öõ´Ø•ş®9^!í·òÆÌ¨8°QØ=¬Ñf}Îº²6xÉ>¤†O8AƒœM4£—ˆtÒÁ‘7P?#îÚïL¹X¦~YŸ¯¯Ã‚İÍ0„Èx¦§æëEí¯ ë–½…`ÿS#¥ÁUÎõQÔ¸]4]Ù7n©`ë§ÉJ"‡Ñ£­È‡êg‰¶¯S»şÉÌz9,Úˆº³…µÏãsW¦5HÂİì6õc³ Œ"¢ÿ/E¾Ê›¤–à-¤òP-Ÿ¨ÆF¶:â"£êÖÁ{z¼­U VÈ h‚Y¹Ÿ3J)
ÕCé¤2*ÙãÔÈ«íúÛßØĞ4İä{Ú’],db:,¤RŒÓ`E…¬ƒörMµëwk­|O6Úƒ»›Ö½¶{›(ÏŠ&¨qCHá¸rGnó‡´oÉ~æ¼«ÃÃ¥LÆ.#\cÇÖşwâÚë
 ÀÅ§ÛÓôÎHª¹t¤'¯âÕ Í:8QÎßw-{f”úVíã‹üªÔWÀxÔPÔ®#½5„ëÆH¾¡õbC›"4ÀV\92 HY˜2Ş¢±ŸÈäãb®ı¯«™~•yd#J©\¯—Qrõ"4ìóD²9úJ­?¢QÅC!Ì/‚¥ËØå;Y+Åò·#C]°°j6«C3å™Q6eqaşeÈ…ŸT×àHú‚G0ÑF»„îEKf‘Á‘©CìK¸M‰¯†¾Ín\¼B«îİúi¯`;€ıBİº"Srdè å7¶œÄ—¡VI¾Î²^È*tül˜šÒv×¼P‰t`¶¨Ücã¨«è§ıò†İV[‹•ß§Ğ '\W}E 8’Ïñ’mªşRj»Ñ1.c4o]Û³·:ÖØ\Và?(‡wÑzJà­¼Ê¦ù+ ©,NTO·bœ+ØP, DÅĞ	é.33ü;,öß`ÑüæÃ»ÚIıó	2šHÙ\ün@0_Éùóó‡ÿf)ƒËÑ»¯,!ZK?Ä»#r9O#íÌNášø¡	ÿÛÆ×¸ÿMì¡îÔ‚}™ˆ‹]Š¶ZÛÍµË§ pCİµ›,rO3î‘‰hû*øºm!ñpQáu	Ê©â{…]YKÍ&¸µÛY!.¹çtñÛ§ Dá[u8¤ Uùn½Ëv§çæ›{Ğesö¶uà?«­¡VÈ["Mˆ<üÊ‘ÎèUÛÖÈÎGÑt@Äï*­¦4S¢ÅYEWÙuwİz?)¡Ağåë0ç*ÏÂªò±-(ºÑÒ@7?YnGÒ<”óÙ4Lƒmh,°f7,æD¼ş.ídŠ¢ö@+ğy©ø½¯;0ÉåÖ¡^>x¾Ä•Ñçgu¶EÃ±/"yĞ<©j$½hqGHeâfyÿhœõîú>Ö`ã2wë˜şPğùE}Z(·B>{É‰¢~ã¾0|âœĞ`&:ĞÿQ@Ù…n%µ¢¬<2)&ÿVÆƒ[ £ä„á2&è	@ù~ Ï‚e‹³[ŒÛ3ÂÄÿ¸º`™Yî„OdÎ¿´´$µ”' s4|]åp˜¸¥Ù¬ª=ìz.>;¬]Š{»fÚ†B‡KË¨áé SŞ#á‰!ÒõaÂEéò!ÊV1Pêõ%[hºt°ÍÈ÷Pwé¹-û£.¢ÉUÛMÚª‹ÆÑûX­±Ô(½ô´Õ4[Ö¬6åyôĞ­‹CV®TÃ²ÏõƒvùmO	ÃˆóÆ6p6Ë‘Ğ|‹¨aæËØÃyÑsÀJPáÌ$ÉA­@&™_ƒõ —~NŞ•ÿp€¹ÎhE»§i²ï5¯õ| LÔ¶o«Ğ¥ ªò(¤‚Ë^Zt<Ï–æ*¹1ò…”ƒz86 :^…
Ú¦Y77‚!~3sÙñ	?Ò>	Æ¶)"%V³u2 ³ÂÔ›Âpf«Û“Z¬¼ÅÙ×âc7Í4ö-¡®ÃRWf€…<Ú*]Oê‡4˜1«Å[sƒZê.+8¤öj’¡UôöY.Ä@rûşß,Á*‚jåøŠÂRı¤p”³¡|WÑ ¢Un«Ÿî«Òı¡AüV]¾åØZ‹1åwXi‡|,/š¨²¥ëÇD^X~ ¦bP¯«Ä+3ğãÿ.Š„ÅñtÂhu)Šë&=Ï;ø¢~k*óñü'¥(×ïØCÈŞ0hÂ0ëq‹©Q5>VŸi£…¤AÒµ2Ìı¯ŞŠ5^§^T¡Õ-M”d²ÕjòKÏåÄO]"rl>ÇøªòID<F‰
 ‰±­Md¤ƒñîYf|õjğ˜­Zâñšš.
·ïƒV¿EB´%E§Æ·ÍáÒ{wºq23±Ø~-q‰Ü·Ô…k­İÛÕímãe ¨TWÂ=Z
¤°¾&÷z[®@;5v$hñ‹]‚ŸÿiiRç›^âØEğûH‚&ßÈ¨CQ–;‡›;'G-£»ŒÏœkÓ¥…‰¸æä„R®“8zÀ3í–s‚å·M=¥fËS,3 ŒU<ºØo8-şb¯Ñ"ûˆí¡Â¢­‘¦:ßçÉ†Mi3¡g¨ãÙÛuŸ/”“Rm÷Txtüò)›n±»ç%K\FQ>âƒÚáœ[¯ĞêÁìĞèS+§~næ2Ì)Á­ºïÌW¤JM›Ù¢¬­ëÄt<¼ÉJ2•W›*mQWH‘ÖÒ16bÈyâepdILJ†GY1ëcğ†_–÷f]™Z4ÂX´Û]ÃrîFÍLÛ‰…#ÎÌ¤]Ppb;]ç‡û¼Ü0.ww¸Ôà‰Á½U…-Tà„`73†lïdææuU¨‘¿²Ÿ'Ï[İŒ,™¸_ ’Ad‰1|gw^S†Õƒ±}°ıÔ™ù?É¢ÍãÑÎ6L™ñJ¡i®]&ºëôt|ÙÇë¤ië›
?ö;Anit3­3òq1ûÊp‰.ô×G¬™½^¦‘Í ÷0¥›-^AĞ§êTmgÏDásÚ¿º¿J“ûXÏNÔ¾ÅhoÏ.XªÔONiÎ£Ô$B}‘ÌrÖ%µ¿[xÇ9ı;A‚qp‰M%Ò€ê× ^üW%Á@õƒ¤X„R;qû†fEĞLÿÏ¥:Ö+ÁïÇİ®sähÂ,£³yÒlh*©6YG°O7œ’ái¾ñš¶;¼²%YM™rMmÂ8Ş/¸O:gõ‚Ø;¼O®éNp)õ ç²¾Ùñì*Ğô1%ô¾4÷$ÌİW~ ÈdŠMÌñôÙ3E"ºúê´x	Íl”ôˆú€1³·O€G2âg1bí#‘ÙÀòKAwm®kî¨ø$Suğz¾;½ú\7(’§s*Ü4×U°­ŒÑ°A‚Ê0§¨4¢Â¯–‹¦?H,Q®àF%¿?€Åƒ¹_û‘tˆ8ø?SÑHC´fåÛçMªQEÀføùõ´Ä¦çÜÜ\¦Èæ?\T(Ş»¿X¡å­¾¤£şîîÀ¥º¼^Çá«Âq€„ëøºÛqôI/ÎØ;·X¯å1N.ÓÁïW›8ÅÁ?;E<¯8LĞz%
qÇæ××ÊÒ× 1&L£v¬E¶×¬½5ã;‚yYşˆÑ.ËYäÀgHâÃÇb£Ô/‚¦©Ã'à*Ÿè²ze§ÖÈ«÷8¦Á©¦M§ —Ã¬Ú#"¼‰ÏşË5ÛÖ}Ëó…ÃÑœ Ä¢íê¨§Ç	AÚ‹…$H†'<uhó³ó£’C„#æò´„èCÅ>°
œ·ès¼İìÚ"øâu½„Ÿ—}(‹44ğ[D¸ ÷°P£lß)³†Ş+É©¦C¡š±MğY(­UŸö­uÚJu[·uºCŒ¹±…¤ÉÍY(su]¡«A¿BÿI.éË]Ü1ÿ çMÑ‘èó	Êš+°Ñz h€‚1äò4? ŞA{ÿÎb1â"7µtì3Ö)R›¥ÀóÇ~ØhW1y/Öf¸  !OdRãô|L>ËŠX.@‚)(‰$z6ıÕ¦[õ ìU“½SÁ§¦YŞg7Ê´:H¬™1âÎFTJ¾O"ã"ºgÄnª½–é ®9=pß©ÆBö=¹Uÿê“MA5š\^;7(¼6€LTÀ¡â¡ğUò58ÿV”ÿzÈ½€Q¡Î¡Ì#‰Ãh“l.ºôé“unà›+h}t6OsÎ*ÎSØXæ†öğuš6"y›}6Ğ(ğ¦¢`Uø¦	ŠaÇ…0İYµc¢z¨SŒ¢èn±H¿N0ÏŒĞ?ª^uC‰dm–Ô“VğÓ&Î`
Œ$–k<rqM* ‹¾Ÿ•Vé¦½G £“VØX¤—Äê½((m®¦èà<”Ì±ìyi‹åvÆØ_Yßø…RécWˆsÉb¤ô¹)¥FUd£GqmÈGš‹Ê
Étğå-£	_$
J FYbÅ‡SáZö$ÜjºŸãkw20QÁ@A5iûúèkä@Æi¸îÅy;“ß¬	š—ˆ;'ºşk)­èà6Rå™?•9©MpÖô&ÑŠu¢,w0&šhzÎæ$€ÍFÆ÷Ğ÷%Ñ-ù ¥{3eHÍ7Ğ:[åº@ÁÂé]?^Ã/«¨BkMnºîÈ‚‘‚g+"Ob_2vb okÄ3lf^Ö5 ©ÙÂ6H´›9ç<F{ÄY»våÄ&¿lë¥¸J:hdí¨HIØú|÷ô,èŠõ$L'
¶®Ì‚®àÃT{\xßaQeZ€2µ·†å†pQd“ªĞÀ—’jS3‘S;j¬ĞŠŞ¢•hÁ<E·ì¢	¯†tC‚ëÑÆ4—÷Òÿ2šôr"Ù‡Ûd‡œç4“k{*˜s¶ö”7-•<G¦oª¼Ï€L–ª	äænp Ìwâ›„‚OBó©Ûƒş2k%+EaÊ½(	³Œà6óTdW/õğçş9‰ªe$+ 3…$p#|wåOv"' u€Â.N«FÎÍ¼	Ãh7ÔwGu-ÉHFıñ*ÂvìWS›LÅ¬`”wgiàûî¸B“Ú¬¸E‘ğ\â{€§iU©~V•‰2A¬dş&ÒæÖ4­(¡ä©>î¸@Xn|¹:U‘¦jİØ7¥¸,ÅTiã":°¨gõDAÒ$Şl‰·!dC\Éx†ğK€†ZÜ`_ìôCLíŒ#°œš£×ükºFO«şÒ.ÿ–FAZkh4€³M|_]ë7f_*ÊØåUåôq&Ñu%½ØÎ†7¸|Í2Å´eK××·xOPæò˜#…ê÷ #öÜMŞë*èÍYò÷¦¶ZPúİ”Y$g0æ¢Á0€´nYIÖ'Ü£ÿ0J¢d!^‹óisdä‹ó{óS½Š AÌ†ÃG	@ÑDÇC³Ñì.]ö8¤Ò“¨PZÓd÷ßàjòÕúêz§ƒJ]äRÇ»‚:E†”~çÿÚlf>1ÅÃ³Ö6cØñbpKñ‡ä3ƒ!-Õò|$à±Ô»Û–¯ ´¿ 1£8æè£Xïõ´Î¶zh¸¹ó ÄñÒ~:Â^	7~Vgşósd5œª¾*"IÀ¼Aß|åÄŠ=ÁOz‡a\S]gõBŞ"âÉK>¢*
}ê“åjÿqSg
GYîzB@´FÂ2ª·`+tóqë›@	@<½«$ñ®©8¬Âx»_×1ù&!2¯‡Ög­ øª)¸Ú*ã-ÊíeÔø&º1S•·óx¶íó­gûLÉ™Ã]ªÊò<âóæ ÊBlZÌºZhö³> +S¨J`;³Œ&s*#ïxnùGÚ±v8xaSW@6nT)8Î>W‡ùhĞ0ëJé¡6wuIá÷7~i\!›ì©nâi„	hu¯VZ0è?’ H¹}KÂ@Øß†”›HöŞb;ˆëŞ×ÌÂ®_D[-Ûd† 0
Ë§DÆÀ±;­ÿûÍ3$¶eíH«­¿İÛPyôWr%§L©ÉuõÌAì’6	Ğ{q_Ø›|€ßEƒ6«mø¥?KZŞsÅ…›t…s¹eyó¢¼ ¹ôAø"£ÓñóºS;jeÓgşÎQùÈ€CËË!“€@”NËÓ4"à’äbºN“Ö…ë&ÜKâÇó!){Ö1âŞtã[ö°” -£†ŞeÉK¦4•-©1ägtG]i˜_!¤2nóÑJU•[ÀUşÕæzL½9@=b7äûjIŸEÀEöÁ<`§-ÅpÓHşLc>!PÆ¤©Ş#
{şoÆ"Om/‚OfÀ1+½ãl~ê7¿Ì´ÔÒx§àŒ!/] PDñ?¤
ü<‡6ô)47ê;· (åú¶Ã³ÂYDÿ&Sdk¹Åî3—³¸r¥IŒ6Ãò³*jªÈ©¸=½,àl–$‡×ü¥sCXI3;&›–ænf#6q­—uµ‰lJ×ÛY—aå¿¾V1Š¹³×æ´Ì†¿ò@îXW9Á9îX?'¦-O„+Lš*ıó’„Ñô­ù·Wş°1²ñ|œ®:-°Š|à¶p)),W/fŠJ8âèº}İ©áx“¼Ôe:«E€‰	‚”‘¢Şb¸jÖz3.Ã÷Í”š‘ÇÒ7À¿¹µ¯0İPÀ;jíE:¸"öwlœ0oA*aB¸*<Ğ@?·—TöG­S}_7p˜S×nI”Xu†Ÿ…¯ó!±[ÇÓI2dYTt:¡ù†Ê}Ş$Ğ¸ás<Ä2ºåcpì¨Xß6£3W<ÈÅw¶sÍõ†]ñlŸ1¬”³.]¥·MÃ™ĞÃC©»'×i–›“LTşÓY7*	ÌÁ.'Äí¯ş×n¨¬ÔnW$\bBê!XA€ğDÒ]UX.j"ÅçÑš	Æï>¦Ê–_ßg§%›™Ñ³%Ş“WÚ¥rr,(ªí~V>†¹1¥€ù˜oèÒıR‹¯8èU¬VOnÕ£s‚¥¿<Â™9ôÔ
:»d>#ïœ?4¸œ«J±¶2\ht-ó¾p‰.Å}İ{*şçƒòK"pñ“çhihˆ[ˆ{Á~²¯Bß°¹ûçV.|nÆ½·¿.¬Û$P³¦ùyçY²ç»v`oÂ¥º)€BGIƒBüVBŞ*wT'£ŠĞk,7qƒà#‘}fPû	1óÜ³ ¢†¬†XŒU“£€¿l®«À‘5{$NkJ×.‹Ò,}KÉÿfU†&,Ëòë™&œ¦nã“‡àp1üté%VKé2Ø
”"°yÉvÇ@}ŠXx˜ƒ­u¬ØÆ 4˜˜‘Œ,A•âƒŠ?/7¶nTùkí_¶Ÿ“¿¬/Òc`Æ/Qeáíµÿşê6º¡ÄŸ‘¸¸”ŸÖµ:/ÔVøL)Ã"ø¢ç6L´eÈ¢qå”è3@?ÏÇ5o“}%ü­Q½Í–dó¬¬†½‡ıë‡í|ª¸®[ÙM[ÃšÍğUcm/Fvrı„İmúëÚpE«\81â1®"«ÙŒoJ@Œ—x—?sºFBkãcdæÊÖÊÂ(ÂÃâ{Ë­f8ß)£ö(í³x•3ûS¾äÄ4ŒyXœ‹ù3ÌtÓ-©F(³íÇG-‘4õ¹ĞÈfVŸ’£LáÍÓ:Ş	í«'cŒáà6TïU‹"u¿Ôq¥d"_ÿNÁ1=1f¬ObG§’AàäsÌQ;ÚÏ1îÆGçİè°İî1…B7… Ò>Kpz˜ÖYjun§5õ)ª 9›ôÉ>¯
ùI3«wæl IÔµo-—5&^Äeû&™L¥
¯cÁç›7¶”ÚQÑM&Õ(¥‡=ÁTôÎ¸ˆUì"“ÉT&şzÒ¨“‰îğLLc`ørÛÕÎ¾ØK÷ÉÜšég±ÏJ„}ŠâÕì÷S$z~6ù}DtHê ¢Â¥‡Ñá5›´›g;Jx;ï}¾_c¼×Ë C*^/û#ü?>À7ıN¸š0¹{µ%êŸ»aFıÿëÿƒ=ÔS.¥¡·—ËŠEª_+Ìô?¡ ®Ş¥Ô§/^¿H
ûvEö„NDúãÖXWøX“Tù^C¡¹ÚŠ•@>ââ_G}†IS¼QòªÇèÿö7#ì)§ÎÖğ8Ó¡¥:E6jÊ‹ç„ÚÔf©gSœóLEq·óæqÆ´©cÌ-$GQËİ£ë…\
÷ÌDÔîRpDjCNC@E9gUˆ¬]6x1½ŠhòY•·`__‰c‡;Òuƒb{0¨ıgw‚ŸÏşşog`LwŸWŞtOŒœº:qü\.·£S/ùÛõuŞÜ
|wãáªB“úar@"û‘Sù4wÙ«#’\Aù;ŸÈÁ{ EŞ¢ÓSóœTûšü6¸IIw‘¹c‚‚®k“¢’çœ8Fõoñ»¤ïcÀ±LBA“%EhVR§¡=ÆÑÑt(®FÄRÖWsZir¤HhÏ2U*Ø²GkjÜB5ª`	-;”²m6¦Uw\ZD€îÀá¤¶çH0Iœpj¬÷pÚQ!#ò]ƒ U‘Bá=‰Hÿ5öàÒ}Cí×ÒÓÖèÅêq£èÍòIwóq{éó1Í÷^“RSa9%ø_jæ`:jŒ0Çÿ P"½¾NÎ@å¸ÏUÖ7¬}º¥Œµ¦ÄíqašÎ-9*¤sñô%ÌÅ¨ë,R2@$¥ŠE«¤œœ]íw@=eDy0şPWq9Œ…1&laOƒ.í“èl=õãâ7‹½‘‡
yíså»}x¨­¯6Š”ƒ8{c„V3h¹³7~²ó–,zúÔ_ÜA¿ŸV)W|şŞzjßÔ¦•O£)F"…—®=åCsôÖÌù,ÕGĞé~å/á×¸„·9ˆ…ø)B(Y½XPÚò`Í.Êì^ã£EKª›Ú^»Ôm|àW¯Ìy2ìuóÜI³ÉR5óğUµ©B[™"Øpÿ•Ã?Ov>ÌQŠYóê_„«œş#êÀè"ªÕ/›å=‚I¸'ƒ»i¥¦Âª<há˜€´Qãgæİ5ä8ÓF–&êHØ©	o5ŞÉyõò³%»ÔóÖY—³9iâ»pïØészèˆ§«K¡;^ôU$8%­´9b×¼¦| ª}-É¯ÜO×yˆ]=F›BÁ¿¶cõÒÙT;9áeh%+h³×SÎRZ6íÿêõ5Å²\ß-É4ÖÕAè¥3üˆ0	É^™x‹è sû°%"M#7¢‘‘«r†—æÎ¬ö*Š‹üo$Ñ¨0À@(òŠ]ŸG|>¿„¢È¦4+U˜±/$cª Üdåæ5ÊŸte¾®ÆŸ=nq0ÒLA9ë­ Ğy#)]FiVi684B»ÉD°%j™|$ıa[ÂÉşº¨|oğ0i
-İ%0µĞÎî¬w@—e}»Â~å‡ß<œ ÿõ·
ÈhW†4FÈì†;˜@”°MKœsyõÜUÖ€£ ¨åêCÂb2¡ª¬¯uO,S,¬lÇñÀª=¬\mq¤a¼d“»#~ªÁİÌŒVşX¬®85,\+qSõ­5À,Ù#k³fõc"Z%ˆA’0°h«÷B"“¤š›AÚîG.'uâŒÓs¡±àF¨Ï ÄgÍ’.•Š	æ*œFvST®­Ws9AX·d.ÑN?.kÇ¦“27–9íş‚o.ñÍ6EµÏomx(5—‡•şÕØÊÛ^íÿ(±u»8i%‚À*'µıûË©•ª¨ŞİB¦?Y­9í	Œ7„šîÿeõ€zÙ‰€ÊŠ¦QA}á=ĞuoII×!¼”ıåDˆë#e°.¹.WM³»ÂE7Áw¤.bW7ar¶íßæ’ı¬ßC–D©[ŞãuGÎGë@ğoµ«šÕûX‹	w[$mmÒSÂ°'$k¢k‚‰™jAcœ!®C>ˆÌÉÅw¾pNúè=QÌéŞSim`b±¾í²cçóÏJÄœÔ8=ÃH•zõİ-ë‘é”ÈäÒ¤á¡`‘›ÃqÔáÜŒ|^ßGgÙ÷ôoÉØáZLSajÈıV`:o¹°E2»åCßåoí¨‹¿ûáP¥€Ø¨İÛYªñJô îa6¾ês¤Pêü¯ì:ÿ{%ğÒQ´@‡€Û‹elÖŠ·˜ìŞ…2ñì~¬Eÿw7f.(¼èL¿YŞÔÏ-ñêKÍ˜á‘*æÖµöµŒèÍâbm‘…§-fY¾â9˜ØÕEÿÆèˆÛqÌÕÚ?¸^b	›(¥ØlÊµ¹^vŠ	£§Ì‘–«0dó8rÃœ-)½ÇÎ±yß÷)0ö!eG³ºñ¥@íD¾(ë+˜ş¦2ÖeÉT—Û_MË·?Òl½Ê»s
J‘ëÛtH<c¦ŞQ‰ÅÙı3xÊÍÈ©/Ç1ÖÁŸ^“ÀëwÓ;Q¶‡å×tÈ’¥`°#7ƒ¬ã\æÖÑ±gÂ&d´1^í˜ANÿ,§	¾ĞİøG?Õ<#‚C‘1šyH.H}Çâ¢k­Ö;éI2?¬H¨Â>ğ)›sã…gKÏöy"ØLà$ä³!Ş`³<İ@üNvƒû‡xĞçÚ˜géæ¯‹ò~ RÑG³:ŒTÒı‚”©…^™µ¸²Ÿ¿6anÔ[u¿®ğ{áKÉ Î)Í€Q,°ª±ÅÿPwÉ7Y#ùTóR¶Fxha¬-Æà£¡ÿş©1øÄÊ´Oí³2}º@l›6#Å ê{ŞoaĞ´)<	{Áñæ¡°¨ÓÙl_ŠÛ /µ¢"•A¡5¿~İ¬0ŒÍgLth”%F§Øv‡
£+*ôƒ{7^!}¤
$ŸöŸXo-Ls-“ßó£wD¡Ø¹iaƒP¡Ğz?šT¤W±şRFô	My$)S1İtZuÆ®Lx Ñ Õ¯bï.wz±“+‰¦
†şãÀ)ü½­¼f+.Å5ÚùI_+P¥tøäÏ	ÆšÀ+Ñw$5¯·=ÆÚNÇEšÇãN´<›xE›ıÑ…Š_w¬Ëêl"ö“şùnL•>R>¡…¸6R¢pébNn5„™¥\¬œØ6£'a­±‚ur³Ã4'ÿ9WÍ®äP$cKİ½Ò&{
ûm­ Ë^lğçRºÉ¿ì&+dåFSÚ£æÎıÓËù©ø{VÖ.¢õ6[2	c-ı ùğu‚
(îº;"lZ	uúIt}Úoå6²	;BMºÅPh©€Ù‡—Å8ĞÓ…‚By6=Æ‰Ò2L7‰ÕRf!i·+û™ëœ èUİúâd¨øaŠˆòKí²?†õJ\ÿ?ş8kÇÙœm*˜ëKğÇ’ßÿÂcáQÛ`×V¿Æ]¿Pzãéª»ÚÛ†+·OÃFÓò‹<Í";`1yB9U{2+¾ Š×üƒÑ5jx¶oõmrßÔqA]cPØ V&hk[q¸^ñFÀtó‰ƒâ*Bô3uç@¬Æ‹Ç œ{-j®ı˜¦Ü{w¤»>&%üé vo? q~Š»Î0ÖWÉ”ıut¶ìŠ©ÃOX3±¸.Ûá‚ÆB…†qÑ‘ù‹à¨¬ìN”]?]•9}›G,V²vÎRã¢OÜúuxrún &p…¢{Sfm*'Ù·‡¡àv[G?P€¢`Ÿ´—A(ƒx*7•ôğÙ„¸ÛGR®ŞÎ¬’,ş°¹¬F¥øÄ-İ!%#Ù4¥%uLÙ®)J²¼¾rÓ›í³.ŞûãµY 1lê§NÜ¼ÿn¹ÊC¦ŞYRšNò<Ÿ§µü³úé°ËrÈp $ØÜŸQ%ú±hnÿou¨Ò¸xØ‚tEï’dX0„½FÄ‘|˜4Y›ş4™!\¿Û<ø3t¨İ¥Ø´Oi£;Ã3FêTîDÀOÿ_¼ºB²x¢H_Ó;s™>°¨Õ¸d¢½·ÚÊ^apSX·V£ğ0—ø•>S.…ÉnÊ×	`mj·Z.‰‚¥‘ÏÏS:	•dq Î§^KìÀ‘t‹|q0ƒŸz¦’HÒZ.t“dÏû«n%]¤™w(mGë!Ü¯³Èİ¼ùÊş]¶¢(² xË|£}jbQ¼Ş#İõ`,²ùŠwİÕà:k¤-hÇ‰f—&è ¹ÂêãÎqÄFİÄv¥›š1Ì¤.ÏÙzÙ,Ï`±<ÖWæSp)cHÈJ}ñ7MfÙÙ¥T+z†“‹!ßÓ8¶„Ò´E<Jp¯ĞxæKÏ¤„øòQ6Jˆ ëìq–wİáÁ¡ëx #%’”SÁ¬yöãgí³”íÒÂ!&ñ§³»ôÌıg¦œÇ)¢ÁŞ=R‚@áI%¿V«ÿÑDòqq%RˆÿÅ™y£M/ØÛŞÅ‹ş`Sêà‹Ë!:êóXññ
”`\//ñ­±6m„[vä/rD–é#ûXÈqZï;é‹äÛÃ+Ï#<&n˜9ÒlÒ|¼	 `Ñ³ÜÑ-Ã¡÷p[âŞğ†ù:	t,&.í{g…aÅlÀ¥pG7Ô¼ÒŠKôÿE(ù›¢ùë7}?Á’NxşÃÕ3EwÕõ˜0œVH#RµÚV"—©=9wˆ™Áà-XÆÎ¥öj%\à,r¥ÿ®½ ‘÷ŠæÀópÃ6!by²ò†¤úÇh£µD`}j©è6 |${>®’§tCiX'áb­Ñ»MÖ3°}‡Ub7ƒ>(±pV­T…AßÛW_8·£%<¡ÛÎsMj\ı!…Ñ/İôÄPÈt˜LñO!°5™ñvàw(Ş¯×¥¾I‚ë1%‚ph£'W4Œ·cn¥šÖ•–CSxø×‡¸$g
ktâÖ&îñª6şgWBïÇæöVj6`
Š¥S³Oß¨cGíùÃoy©‘mx7^ 'Pİ,áø2’|ı€¼ÈºF.å×rÈ¶2^Ï¨ˆºp&¥î?*Eân,0MŠ¯´"¶ã£’·CÊ7F­kÒ“¢Ê[8ö‹¤kQ"'>­–æ&9Kj+èÍS]ô»½ïH°MßŞ:(ø oËGü±Írõ‚\[rÿë’¡…i4±>ùf›M¿è¡rÖeí¶‡C¯¥ÅõAªAIÉr5½¤Ù:<…T­@<U=múGñCÎ³¥­0â"zƒFa-ß-Ğ ê’X×'–`Ÿ76ñ®JA•öVÁBNbº±PÓLÿoÛ=Çêós½LÌªlµt{‡ "ÔvíM¸MİùË[«[>‚…ÍáòüoBÅÊ¡“+?ØEÊ@`ú_d<ÎhXB¬OÒ3&P¼ˆä¤?t¨»İµÍP²/.×ÖEÃ–1ñ¸öÖQ¾âê)Ø*×³5/ËcQåP2SÊâ[Ã”Ñ¤ÓŸw¹Ä…«š,ïTàrªõ7¬Ò0"+ñø«5TYšK#Â–(Å; ÛjÔl·st†7 ""Ë!øl3åoğ]ÈQkMÃş+Ä©,d…‹¢Çïg*íÇJ.À—5ædÛ¯hÖn² l9wkgÏy¯Àúÿfø­÷ç.ú)¼ …xoûZ×
×ğãÉ¾åK*÷½ÜX'¼c×ä6ëAU½"™ˆ›A­¶‘éûW"­¦^à?]°VÃ´S7ÂE¿ñùD"«‰fºşxİ.§²yÙj/2ìV¡2»w½{<öÔş¿lr^êíÒî4ñÈhz	V¦X0¥å3åZñ»ã×Ÿ_[ìÃõ^…qÀAD5œqÓ§†!§úÛÍ—9‘0±ëè†¦"üÓböÅJs,[zjÜ
ö¸ìEºˆÌ³#Nk7d6c½Á=)x†¨‰aDRLF†.ÏŒ¯3‡ºŸé¹¨£º¸^fë3€Âµ(-¦FF·áÜ ?_?ÙW–o¥nÎ³ƒ:g@-uØsjE+:³«ŠAƒ‰gøƒ¾”ë²æ£j©€lªCÃÉûÀ[‰‘(`Äsyãw½¹¿&­I2`•¬›²–àßÇèì1e]Í1‰gñ$ûölÄE‹Yç8û,AĞ´zóÁ1I¢Î,ÕTThnªŠèeò±M«Ñ+m1¯ıa)„P$ÙöÜMÈÉAîv³rKÆ%€Ó¢Yˆ­ &tÛké¤r„g=§ğUõÛÛöN R2(ò«ºÛæÑvdg3,kˆ›yoÎ6vƒD@Zõj ÒÓÛ©ˆ
«È§¼B-yŸ)(±@÷dî–§@Îß§_…=¼±œ-õóaE;J¤~¯0şâÃù§|ÈÒŞ€YË:ÖNª„²¹³¨B³(<Ân%JİN¸#&ÜzSØß€ Û–¡øÿ[£–ÈÓºoâÒ6•:¶‚¹F0&;P#0vK[A±gÑ˜KHqò†Lg{@şĞàµUR„Ä},WÖ‘¶q%¥¦<¿åôfÈkÆ@ >±£ğÑ}ûÈctİßZqò¶È{JZ­ÍşÄ©rñ‹•1-)7~x cè
3n7ï)Ë³úÍúˆ›Lòf;«–Æ`SâìŞ™ı#úóNBê5Ú>vsBÛd¦0¢«Rgm,‘ıñ",2Ë^I®£E²!šxQ“çù2R/:Ãt~Ğ„•ÅGŸ×TA°§½Ò.©áOj­\ËÏDˆQM?:67ñô†p:QÄ` ÔüÉÏÍ	Úì\H“…¡+$¬Ùò/ˆàìå9è
üUu	ÒŠ(ÃEãÀëò3mØÀö%üÜmyšÈÿû G´ãW¹0¸‚‡Î`¤„´Ê¸§õPŒ&$g¢‡r}êÖá t±îÏ­·ƒ¾œ>÷u…ĞC|ôå ƒªî9Éøy„8˜u,eE‰°£¨O´¤Ìê¬[š*ÿŞÁ•E€úìPåªôxœÑòfq¼•@9¬
+ZÏd("ñâ@ÁË-­¶²°ÑG_@ìX¥
yëçO¢WÈñĞgb6‹ÿÖYûâºX“‰ä½È.Â„®›3­Ë!³¨8T¤ùœÉ$Ú£y]qØ¶nè©Ì\($ø—œ`Ä9H‹ôé3¨XÀ£”Ñ{CÃıêâÕúä±V´!|ÈŸÏçïyç¸ô@¡“ -{â]ÁÅ“f"Ñ 9Ç8ØcÔš
eæÿ)lP¼»9ŞÑ-Xâğ†æÚ+÷á³LámÛ£Ì$Ó Ğ˜¤§Îñ™–ŞCe4ß°ØK™+ˆ(	ó¸„ûƒúÌ¼ô&o{f»"£ï´P€~)’ TH¿ÛâX`½hÅ‚~&]‚ƒ¸Â£Ô‰×3yl18l®oÔd=„ vöAØİ¡GKú&ìà®T|üİ5 i÷!óie
u~Pæ1¡”HÓ[–‡=šÓJXf ŒG¦•ëê5Á&çrÔg²†êóíåû‹Ÿó¿çÙPs¦ÇrJ5qk¢s,Im’ü@ê˜QÑjm›p¢ñÇ±™ÔÙ­Ç–Î2â-’şŞ¥9²€wÈ‘æÒFï”'æÒj¾ÁèĞ·M²œÍßTAJÒŠX4ÑÃ¢TòÕ°8W‚UÂI<ä™iûø8ÙŒä½ñ›!ßçt~T	¨°Ğ™¨×>§$B›Jİç<rÿ Û¶Õ6€œ)xBJ©±†š†şÜ5î4@|äcÇ7„J+äe»fT£°ÄR¤2%¿$ÑF8Ê°ÚñIæ|¾J¤°ª@{»šCİd×ì¦0ÃRfZ°$÷ğ+fâŞ€ë†LÙÈ¡	®>klÑC'!Ûçbdª‘±jÿó™†Idw/‘çs&	Ùİlœxá¬ø ’¥:õkÑ½¥[DL¯^g-p¬+õ»éØÍQ8´ùsè>2ı§MbÓ±†}¢+ÚÓ]WO¼ /y5v˜ë›nñs¯B[zbY­lğ½ß9Ë1L(n ÷ÄIS ñ0.Aÿg¼†eØ0QÖæ·q½“¯¼oni?ÓOIîŸÄ¢î$!òftïù=iøl¡óí´ìá­i€ğ;#hºÿ|0†µ”-+@ŸãfÉíÆ1U,÷†î,ª‡Pš—÷CÚ’=k#EDÍp¤{XÉõßı:âz{ô±……ğ˜ò"ÍC7€s¨§!”eÒöfŞãj”êš~şVù³'l×ş›*$óàj’ÆWlÒy·ä˜EŠe§)L¶Ùy«NGe|»ÎpªŸï4\ø1Şß¡‡_İàH$µJKÃ˜ÛåÛU2¡­Iƒ›2íwNûCSÀvïş{Xî‹VéÕ›·Pğ˜¡›&\›ÑDä>üâÜ/PFLL…öÎ_óÙ¿ñŞ9‹µxfvK¥ˆ	Ò‚§±—0í	B¶Ì€‡¾ĞG]:Qk‰yÏÅh¶šémú4Õ}Çæ¤)àIÔÖ§¼²õ(‚á½§;Ü1nm§&½ù©ç:Aì‚Q);òÜú­/*AÆÈÌÛ7À¥°ÁoS(v·§<óF‘V*ãÑ* ®'­ÔKkòPBQİ~¯Ç~+š~ØÈV\à†îno‡Ä
Ã€íEœãà?¹ãâüµíVìG”1;œrm"§>¿æYhÂvxÚb—ÃUÚjU°Œ,…Q¡µ³ò5_îø™Š˜¾my³Ûyá69¨b¤éHÇéÓĞÜYzÙ~¬%ü±Zè°	^¬>IÂ®áCâçúbŠK†Ó”ï¬} ısá°îüªâ+Û9qVrté|DEX{¿™‹/ÿOX»çİƒ=²› É­|M~£máåõË¼;X'İ•ë¥I³E	\#mNªé¡Ï@˜9kœî8`‚ÃOAC€´ºÜfÁÓ÷ äbØ«¶!gŒ9™¶)Çj‡Li0€Ç¢•ö™Ã9„ÿeÜt¬Ïy”ı+ô±a>8#?™"#¾0z0ìˆ#íTÿ>À”cv¯ZrCê©ëT0>ö—ÎB-OØH_=sÓü1»ƒg6i6ÆNÀñÏøj©&‚³“:Š\+´zØïĞ—m×áõ°	ôÏgà™Ú>œ²Û÷ö'Ø²[Ôº¿c$ï(’Ì‡ŠµakIâª6»´8¼åUÕÚ@ÒJ¬ó Ù–Ö*œÿdEy”ØoQüs'D9º”mÔfbX;2pÀe»¼·	Å&fqÕh€<s¬ñJÜÊ0—Ø›U“!—ËòDÔëè`…kÆnàkÛ‡%€ö
(m!İø²?<^Âga=şÜä
šçC#:èõ(›Á¤tµ¼gØ]½AÓ¯k\ırÓ›­£|*CfÉª§ôj¸H7ÊÖ€ô$ƒ[r	Ø5áŸ<‚ˆ»İEšt½ão b-âô#	TW•7Š½cœxÃö·’½À-Ó˜÷™5Ù])ïmSvÎ‡Ğ:c\xG]!÷Â?ÈºàÃ7»öt¿ÿÒPfúşB7#j=d*Ek¸*È‰˜ ùTI@#³zÀ†¤…¦¸ójÉ½ä·¼ÀAI CXğeep.Ş|&ËzB+›¢?_u7 ‡‹÷ÂV÷zÙ€—óÒm¬"S9SŞéKr4•Ä:|YW¥ônÒ¹(ÇpÚWd6’Q?a²j¿7g‚ƒg=¿ógnß¨Ã5æàÑé _†´m4Ïl–}V6k>îd*e®Û‰cà6«sà"lÙ^í®MSPÚâ¿q‡§£Ÿû±¾Gõ¿M8&
$
çK¦¢ÌÄÍ=ñ5’HIúøˆz®.¾AƒÁxHu^íuÚÜááRGJ²½.²±@×)v›Úëª’ù««Çgó[Óª–~+²Úcâ!Œ+#şñø,d–«„;W3š§YïÉ~R%5r‹ívºVÍP†ı”İ÷ ¼%èÍœ:ÿ1í¿gæŒÄì6Ûßu6”Ê~±CèoiûoW¶Ø€dí/'p_Lõ°–„æ»bı-ûúd.Ödl˜Y¼ï'aB¥‹ôSD«U¶]}ÀEa•QÜåœô¢Ñış»–H4Pt˜¿ 'fnÜ{çGhYd®¼][[¥mÏüÆ,·J$ È`’©¯-9n­V®/¯‹ZÜ³,ÈÊŞ=· ÃŠ¿„Æ…üÕd @!¬/ŠÛlLºÁœUd+3G·*)’”2|,R ñáÂv3eE•í×(Éû<•O¤“ÏÒpûb]ÅcÂÒèoš]}2ˆ†<è™*ŠkŒ‚Mÿô=ÚmÄ¹.¿àÔ*:ÿşEXN>eô5rØı…oíŒ§’fíÊ‘Qÿ»×°FZñËn¨rÑ–³x¹f×äÊç¹I\áñÇZè…¬Êö>jâÎb² µ2Âş²YA­]	[åC_uCÛ×şß¦ıœ¡šäÙßé-ÌA¿C/û¯ÖWäÕ×'ƒ¥Ègy×ç.ˆ*wÇ…~™ã²ÓVˆAìÄÓ•ÓÍCÁ—Óù$9:ßCî'ù°n¤ğœ3É×ä¨1‡‡ø0}¤Aj2±Äˆ¸ø”8ö^‰ÍN}9ıÀ7™ŠT®lo²6U¨®Ğ‘×µê>-ìëìŒ ŒGÔ_ií”İn8ı·ìv¥[]Âwø²ÿL×vúGùSeşå®
ƒ p{}èeBJ*í³°¿–ãè¼†#”…3@}ê»îI±Û®ƒ ÓQAò‡Ò},‰x§¯N¨¯bO±n"Åe#TòÎHç!¿zzƒs>K(	Ûil_]6]D[@¿ Exªş¿¹äô±cŠ¢£¼rw[õašTˆÀ×TĞ$åBf ÿ_Ãn.»\u#•p§ ×!”±ì¸‘QÂ…ŒïsŠJ¢ÒƒTwSˆ’GME{~âpyåQ·‚'­-ãÙóÿòö{Ï#=|İÙï¿ÈK³RÛ…à¤Àø¸l®,·šå«Èø’şZ9ÅSœ1l]²ÿädÍşG…vÔ®”F4¿[ÍË!¶n#•Ó˜Û)'!WØB±Eç«.Z. ›€!Ët]	U´‘¯$4öëŒ¬ıº‚osªâK’S[<ÎpkBc-h–åGÅ	•e²?ÕÑ¯,Bß—À2ƒoĞçQ+a%)es¸lU‡ù­'¿Nï(ŒL‡¿ŠSÔñü;Ë´swP:W¼³&º]Q*( +ºÒ‹`¸c«0ï¹ìİò×ÿ¢‹$¬µ¼ËŞI6ğ²h¦MG    úEaUNøâÂ ó»€Àg¸S;±Ägû    YZ