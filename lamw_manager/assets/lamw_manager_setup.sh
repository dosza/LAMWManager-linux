#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1777291718"
MD5="05758bec955022ccaaecfa3657b3f9ca"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23812"
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
	echo Date of packaging: Sun Sep 19 00:17:40 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ\Â] ¼}•À1Dd]‡Á›PætİDõüÚ4Ÿ9,°n>lD=eVœA
TFÏ|¯ÜÅ8(­K»ğ_{íÖr$yÄ›òÜ"ıĞº÷–&\ºëCCXí(2¹¼-İG#şl$½qşÆ'ÎwkÜ$ª³íeÒYü®Ÿ÷~ÛRbn³ Ã	'¿ncÖ×"¾,Ox{¨!dŒ2ŒT|İ·šƒv¯6şíï×p²+ÒH¬ÀI Ûèu³¡OìxÃyŠy«¼™ÃI÷ƒ±úr“üˆ_CTv$Bà»z‘+PÆ
CŒjaÌ‡õ×:xMçMâîèöıAxŞÅó—
l!¼/’\oûš¨âÍ7ÊsÔ¡`ø|xàÉrÂÔËâ“Ûïy÷úb3øã”¦‚Ç™VÂZ	OÉ›Ù™9»rHáôØ}Ù¼špëÏÇ#O^¥äEÓÂ_gGqÍHM’ûŸ|=Î(A¸ËÉ|RŒTì¢¯ûÌŸpóÉ_ß=’|‡;4Í9ø»2ÀFbRŠ?°¿š±ÊpÔ~”ß¾õd0¸¤@¬Ú~”O³ŸÇ.æ5Y‚†%¦Ä°vVÆÈLA^yÍ-åŒÅìzJÍ)üùh¡–Çß‰"|vFÓ®ÙAL¤¬ŞµÅºfvßllÿ5Vİ‘ë©äˆ:µ·N½=à!ş¿áD	-T.ÛŠ} :·îR^äQ-l6›K.¢kjÛ_«ØàéìÒÄQiº³-'uyŠ™¤ùM¤

ğ©bU‹+
>ÏáË_Ÿöe0 d›A.½½¬¨>:œí¦DgÂÄ®D•éÃænl³CÜb•)y^³PCÂ’ªªdpae×¯ˆNeä‰âùİy‚¤/÷x“†ïcWM¤Â…L„cşd‡ta»¸ê™Ìé'Q˜ÒÎáü^_=†÷7¿ôr­/"·Ö"×OëjSª®A‚€ó¨³«\ yÜ-İÈ]{AÂ¨¾ï'¢‘ÿ¶@Š\´ÏÚ]akÕ´²I;Ä¶§¨j²_G§ÍJ¥¯Šúœ&à¯DM¸ÃÈÏLèÔ¶m†ZaÖC3}¡¿óã‡Ø6DîÈrD`»úEu	"O'âåñ(Crl['“åMuC.ÒŒ[:¾Iü¢èé”şHoë¨… Ÿ†OğÊ´syG¾©3ÌˆTfjY„C -’Óvò147÷\Ô’E!­(7=Ei#
×<ŸèîuÅŠª)ïãàÓğ¤©ŠÀ¹†9˜æŸ·V´òÁÆÚDèG ™ZWW)q;xãôïÆçË/3Ù0H{º7JƒRîk¹Zèç›Ãì¦1!ÍLi‹P%*”âbº¿óq.Ò¦s>d†¯ì÷¢xşR
qæá"üeuô²2¤h< .“h§Úù%&ıø1Ifg£d`Ø
¶”ë/ |¹¬ÒµËbt Fzí®v¾E–bĞˆàJ]ãağ¼ur­ûAçªòÄ”jpX „úÆü³Ã¾Á&ŸT6ïf½Í¸y!6Bt¢9i £~¨E*Gô.²›Ä!cšŸ3c°¶ÑÄVë”0#û#xñJ–Év[İhKÍŒÊøº‘ÙW
Ÿö‚ŠËÄlŸ³¡£4x®fJÜ®¼öÁ]áÀ*Ë%q@ç¬(d%Ò[@ÒC¦ø€´‚›/C£"ºüe<)ÓÚÉ´â|QíšË#}™W5¥z§óil
²ÛhöàZ†FÑaÁÌ¢ËOğ[ö$ĞvÎo8ó§ïoôˆN'6X
ùB151ûº&1ÎÂÆÃ#W=øŠß!\Ÿ·¿ş57PÚÌn9Áî6Shi»]™úú¯!+_´<VFé»ä¯à•ƒ ç~§½õ4C
«ï¬'Ù‰ßFót”0%g³9¯¼aÃEáEPëæ{²éÜB.ŒC‹˜Ì bšRºÕÊ¹-ÆíˆÁ„QôOE	:»–ìáŞİ3’’.¿6Ş´Ã‹§=rÈ4KC(Ü´2Êh*¸¿AÚ¸`^ƒ¾píØ}¤PâY”ñæ{ G%²×‰t¹T…³‡Nó`é&V9–¢@i÷MFŸpXk±ìm¡!²œ²Å7ß{·v­ÜÀH´—C(´Ä¦HÚBë%eñ@T´¥Z$ëã~ü”g!¯<[â–º©,Øb‚´<4¥¤›ø¥–vÅŞ«H^ç¥OˆıqÀ¼³gÅ¼e"t
‘9.¹æ0‚<|¿ñ{üş.¸“t¤ºÍ6éº×ëÿ“¨Ø.ûß!RÆî!?i^¯æ9J PqÂø0eŒ„klÒàâõ€-õ¬ß0¨=úïÏW0i4ùà²6§"Ü|¾­j³ Vå
3Ã[º29â¹ÒoÑp[lX’EÄOÙ‹ÌÿÑ®âŞ)"K½+Se^*²ïà7ºÎÜöFòm& )¢ñ¯êbÚM°'à”ø˜ÙF4&Wßa»ÿ—.\«q»Öî9Şš¬mPLŸ¡Üu»C§Ş#+<Ê!cÃpúY×îØ}÷ğFõıü…ÀC«	ªS€½÷
Ø¶Ï‡Ôå»Ê"oCàmİn™µªÖ³ê´Îk…EGÒ©{1Ñ™Mw°|4&]ü0M8È¢gìû'İ†¡Y¸SÔVÒ£¡²ƒ‚æ÷7gY_ãö ¨¡J=v·ûåÀ3Ü3öPv¼–ôó*¹{nˆfDKjœw¸¬„úÌÖP„É®2˜\êÿ¡`<ŞäjŞTÅw€4
!Ó!J¸¯´`}’4{Îh–€?H1MmËˆXKñÉ]½ŞŸeİ>ÏÁÍFNëá]Öæq¤HE¸I#q^K™³ãî!£“à¼wç¸ üÏìƒ´eBÄí«B$(4Z I@#ÆLÉ!bMÛ²4gÏL®?ZƒB4ö4V,axƒş…M‰¹{z¾9ÛLXµÍtƒ¼(ss6ƒĞ¬DÉ…XßlSwIÊ,>_ÿ€6à]–±’˜Bê¬,†‘VVòyte|ƒº"
âÄr%4ƒDä3† rój¦}–¿7Ÿâ	 Ø2n n¸piKZ~ìsÍØ¨©1ØÒÉˆt´÷¸Ì'‹gÑËä²Ò“\›Lé ¶ J€·O A¿û²Ö-ÛXOd'dvW+ş)Sÿ”D‡mjÛ¨ìß¡X4lĞ¬QŒSP¹ñ4ƒÁ”EƒàºéİŠI"­aÄ$rw³-¥BèÎ˜ç\¶t2ªxã º­§­ÓwšÉĞìR9şÄOyo´Fœ/ègï¦ÛKOJ?±²HeæÉ‰SHú·;Õõåyá´â™³¦XE“‡Üß <(jãl‰÷û$Ûy¬@ƒzòF›ä¬“€%Pÿç¯˜+ª«- uÔw¯,âEéø1Âô¢#G.É›œ6àø^yrĞÍŠ‰‘tğş@ŞUTsÜKÛe³–&›ì÷Bxçó7K$=",Ïr@ØD­>”TiS;–á@(¤•Ñš¶ )ÙDßpFêòÑy=…_’ùXN^Ï¢H¿A±ïÚ¯ù1Ú*+¡|,PŞo>,È>E+½ï&A§5	úME¶¬ÓÙ)ô*µœƒø1óQ+jIµ! ôé”×‹–æÕM…Z+éğß@TÕrdæ‰üWRxll¶V¹Ë²ÏüŞÍbé9]Ò<íÇöß©ÓÑ—«&w ìîÆø% ÿoPJöXŠŠŸ£{ÛiT„ävª—:	C7=Öt"&X?w;Ø×Î£‹”ç-QºåÈÜ?+WŞ¾û º¿°=÷q?u$“…sfş;%\ê º{hİÕ	]#mY9{1eP‘r6|ëñçÉ¹šY$¹N²ÃB|h¯9!’LO*ÀÏW,4uZ¼ÊlŒ®Üï´wôÄ1k‹(jg‚E*0ÛoË…7‚E`ıMÏ†9·ä$,oµ:òî<Q#ºEpJì@8Œí 3ÃKm˜¨†]~T”†ÿÿs¯¼±œÅ}˜
û´Ï9½êyx^¯^TtÂÔ	·;ØWë…lÃÓe?œU½ôŒ¸ÍÂÇó§ú¬ôèÄ;¼F%İ Ñ‘$£GâÕiÅ4	hm©8Úu¥ÎÇ„›t¢±Ç‰ûÃûIì’µÊ”¿èLM’Ë³öâş[ËğæÍl§Ó@Òp¬ñüÖ~:¨½DŸÅ»oQÏ­0ôäG"Épi®<nü<B”êg-¯!˜²Æ:àÃWM¡òHÕsÓÚl¤Àå_¬UØüÖœaõrv|Ê}Õät÷¼*3qèødsb&W‡Y<èKìW®\Í8Õø³–µÎĞ>-ä}h(šdìJ‰!¯aÄ4š® ¦È,kÎpÄµÏJ˜Oû"HL@9Eì-½%cÁÔ’·W¡Üİ‰¸“.Eíjõƒ¥Îğ°_sŸÙãá—°7òK?J~o,²«š¡­íY%déWĞwÿd}ªŒm÷œ¡İK‹§·ø9Êw*a¡¼HaıUtFT$ƒåpçàª)ukş“Ù! &ôªø‡Æâ •.ó0E~>ªM¥>×D,&H6ø·¢T¿|q±çÔIğ—kMvû;­ôĞw<±Bƒ“=·çeù»å·kŠ™¬úåÿ-¹­»Jş´7>Ş0¸*7lpkó&à¼ãıÛĞÇ_‘Ò~lûôoó9%#\º–Å3¯)Ñ˜Qr·R$uvCı‡¤[0	»œïØ.NÇ¿#C™^œâñ‹_~šÚğP]4¢m»›ıh¹¼*N§½;-‚zÔù€fˆb,ó©şQ"rUÊÌàq[Ÿ8YÊ¼¬ïüßĞíEDSPVŸ®FçísgĞ¯f|Ã„}1»-…l¨Cº¸;÷@8kó+TE)ö¤öºØ2ªsø Ê•‚œ!œ©q÷5øî“úO*2ê¨ç˜s÷yZšŒ²¥±Rì´ñÁÈ’1¡}“Oşr+´ÒÇ.f)’T»œ×(İ¦YõF7ä=£X9©%‡)·>lH¡¡(R€6h7rÖÉWÒïD˜/ û•4iÉNGñkåƒsè3ï4„UDDkz˜Lõ2´Ö¦*}A)0×ê’ƒ­İ\h³Pk‡Õ«î~°gïµNùšdšZ°Gß²ğ;Û!iîEL–9t¢hà±Nº“ôá‘Í(_®Ò.Î:ZyF<‘n1‘Z“¡e¿¸ŞhÑ†Á¾WÍ5ïÄv‘¯á[³Û.	û;´«àIÂÕÁ…[t`I»h›ØéàË °¶µñİ1˜ü•=ï‡9«ô?Õ[½-<ÆEÑ#úà{ šNØ(7ÈTÄaÍY)-MJöékH”Rfù3=íy1]>ñ¿YZ¯\!´2®f$\išıò!óf9a±§f<°tó#b#’dÇÀ9öÂa¢‡©Nê÷œkBŠYæ{ŠueÕÅ9JlJ(Ü{@şßïT*¥iíÒ9Å“×*¿Š¥l?ŠÆ´Lka#TWb£‚¸1«ŠÌMØøÜ,UVoS-û’Ğ‹ƒLx8[‘eåotüûñÇ/Ü`Æ£uöId¨'ŞüBŞ`¿"€<"îîß²BT±}ˆ!f¿î©ã ³ç(€Úu¸$ñ˜Œ5¼CÑ¬WpgÂÊwÌljŒsï¥HºNzFB£?®¸âÍmAòmü 2s>q\>»ˆC…I/xª^A$ûÌZ–£ºœ%GÎ‚qĞy±‹ÛÙ¨–È½ÖÄÀAŠœ¯Ü*Ô9di€Ò¡u¨Wè¾1éoÅëŞ=l³MyVX,U´ÒãWÛzì­ß:ZØğDeQ%.İ§É>v‚¬‡i¬&¬ğ‡“Ü†ÁkŸ¾ÜRDLµ‹`üfSÿ«nÇ†FßHj"_×ëv	ˆexã÷×ó†èà /(ü¶Ä|‰p4^šø;¥4³·à–œ˜p7Š1pö7!lÏ0{
ˆö…ß`ãš0c*¯ï’:°Ù`q}¶]^Qòíçj†MQ|ûVoê”åD7Û'=ee¸“¦ùpÆõ•>“ôÕ¿OË«eóáCSPI[%ÁÉXÿEiÆìêÄì:B^•ûqI•oò¼d¥v>âl—>·Vª'ÜŒØ»·‰øçõHe;½ÁO#ª8{>°ÓA[ Ç•¤w‘Ûô®¿«	C«
¸P}–,ÎdŒğ6%Å5»ù±«N2Õ6"å/®l@ùÊ:p©t`™RT¹u®Â…=@¬İƒƒÍ‘Êí˜l¬öãH³*aÛÉpõåFKâç:LİLàÄÍM¾Q«ş°ï.›´’Ív12ÁpÄ¦FôtE(¯>Ùb0şÂV„í`"»úY€ÆÀ”f<	RUı5b2zÿ¢ Hvü;NÉ$<k	ß¨e8o^Îœ¸ëXÌV^ÎØW¦H=§âë¬Xtê3T¹p#5|ü ¸2
—m— ´¡w*ú}´;äé÷‡™Ïtb<¶+l¬7L%±ş4Š@l€',¼IıŒNL
kF3OÆ×_ÂDKêw.Ec˜)vñÌ[„oâÎ=Üg°Ã—4ÿîo‰àßéÌ÷5’°çyño¢¦Ë%©qO= ª*^ilÄrpÏii#œ:–Óm•.Ë‡MX>`º­fa'–1b«èå±Rì]ªß”¾8j>¦~ R]ÿ£„#-£à2/ÄÃ¬ƒ1æ”F jvI[œãíšt6î@7 úÉ®îÊ‡C±ªuÃ Tt†ær£ÏP—!ÁŠÖOù‡ní3£–bÃäœxƒ€¬óép=5§Èğ¼£vŒÙßÒ îÏ&=ÎAÒ°oÇ`iŒŠÈ“Î¼ëÜTÖ¼³¤H‚à dyŸÔ½øši@‹3QYì‘U 7p _Zéº÷dí¼ëİì2¨¡¤9õDK>nİ[klÏ²vQ•Ò	Å«šò×1åÕè,ó¥´h=ì.Å2—-j‚·Eº›EƒÜCGoË]–P)ÎU ÖõYpÑ@LvµÂ7$É–½p<dÃ/
\Ñ7\ÿ¥ë4–V§¸é4Ğ±ŸJ‡¨(‡ùB¿oÄ6v‘äŠAy‘Ä÷Ğ.*]Ê0¹Ç’wc°J™· ô·•oqrI‘’F¯§ı¹J­¤Ògø¡ÅR^fÜÉ6ˆ
u²¹ {ÃS¬¾ıq'²	 Éğ7 *°'aè‡¤×õ|M£).,Ú!ÿ‘ŒKËé·“v¬ªÇ±ÿ#4i}‰Á\êè#¿²‚JÂÖBşÕá é·ú 9±´äà‚o€•Ÿ"ˆîM*kìE{F±Õ/|yiÒ z‚ËÑÌÖÎ™â°µ>”Sjw¼‚é|ë²v7³Ñ¥•u:VÔ<¯şôõwÔšVYË¸}á~ğ±WA	T×á¥¨fŒ  ÚÍ¸W’´ áj¾ÚCëNšKx³Ñ}jAõ‰¡î°RÁI tèb½O+vBq˜‹…:0Ú¥RÜ´ßnŸuwGÿ»Dd+‡q7ôœ¨DKÓK¼¤ô§\2ÊA”çÛ†¯rw¶†°/CüÉ0N»Ó¶;äo´¦Mœº®-Cş@ğÁP»é4§ğ$
¿§›°ke¹‘ğ—Ú¬ÉLŒÉâømÌdå"qsR¤qK_ñ4^¯Ü“5ræŸâúÍë¯M#åJÎø-dŒoµz˜Ër›{æØ"›­Õïù¼îFúpÆ!Sa»Pš¤^1,‚ğp6´Öùzyâ¼¤;¥çJM¨ú‹­fsCq£xáYí.¦®¾pKqó£[$ie¤®#Jx 9úµ/|Ç•Æ^åUG#ìRÊ]*b˜ =G·½ïš:‰PATY9(C¥ıSÁ³²ŞÁGœHÉêpxÅÀL¶#iËJŸ•µj¥Ÿ9&Ÿ–ä¯ó)é¸§à¤ıú¾k~œâÖı.®<Ê=¸fœ|Â<ĞRç¬­èV `SÖ6Ç‡çqàëá(9‘×bvPÅÓÆ‘›èŞ—-ÚÓ´6·¡}XY4"ÊÌå+eÁ÷UñKUq	cöyÊáû×lëŞn­›à›µ×ˆÑ&˜"Œâ*ï’.‘O¨8 NËrIƒù‘®ÉõQŠhUc"a.Ì;O2~µoÌD ìv¿¾S%DÂäÌGı{Ä›Ùq²¨kZíØá…|‘Ãá/Ì ë½g ÄÕá‰Œ7S\¶ÿLĞ¼^h\U~˜ÿ{£ºaajfşë×£^AÀ’¸ªv2iÇD>ò0£NàÑº–¦Èú '’Mü äEÈF"a0Ø°R,GP8ˆªÎ9FîÕö­é(Wâ”ó°ÕdF–ˆWGÿßşr’¬ÍŠ^‚2+œC,Î,ÿ	-mûò{3óz[bF;!i%`¹ÅŠ¢[x¿÷ÊĞe€¹òu_\iÖGÖÓDu,Ã½R(ö­£­”ŒôxÄ;´±æ¸Àüó¡¨À=œ§ò
{H†Ò@<é¦9ğ\§8õVê	û£d¹;ÕöÉ÷-_Ã’õ‚a3p…áùkïP/00êÕ;Óså¥Ç™`@±Ã<i[ìâÀUº³,PâôyË×|³«" Ü4;×o§F@éSÒË±Å$ŞnO‚tCú<ı¼‹ãn: „î‹ø!ráç¿yVßt&µşŠœ_5:Š3½MçÚ¶ês.h`N´òUaáİê!æ*DÄ½ğZ[Ü«^òÚ…¹ÕÿÔ"€lL¤ev.
ïs=¹í
g¿·?T§¢Zh;yQõ…ÃHèÊx§_m!ã„‹Y¡fà½Àì>±tf¢¾Hlxê»¹¯5*6–	?®¾[$o²éHùt-<’æmNÙ…XPN‚SÏ 3‹s¤¦Ù¡	‰²lPwÛsü0Á‡x¾|‡’±N5–4µ@˜dV“ò\hUÌïä-†®â5[9ow½ºR2ÒŒ˜Ó²zš &xÓĞ–êÁ¤ŸyÕ•Fc¥œáD"¶à¯ek:Ä!-İ­×ëQÖ®ÜNÅ3šXˆt=·àNeÖÈÉÉ	ï'Ç†ÜşèDW’Ïú¯\•rÖ7Kµ¤*A./L»õŠü›q˜°bpş.$ÇÎ3ÉöZJeômN äÊ±x"!ÊnF÷¾<Ìg"e_a+Â6sO×üÜüö×¶ãMÖ=í?_Â¬Döq#ƒµ÷’”~%\~•>s	ı,ÿ˜*—ÚÃ·Kˆ–¬ù¢^h¥QG°/d¤zÅâˆâßo3õr‘Ö—/ä¬Ö/üŸi [ ”Î¤A $ü‰„FdpÆ™\…ˆ¢4´®‰E>cĞ®saÄÅIZ”Vñ`±MuÂ!Ïyêgÿzf—œÚj%›T£¸ÄÓF`ârPÉ-“Ñ	ĞÚÙÂ™'ÓË£.Ífká¿æİöMêŸ>Çp-•ºZˆÂh3(a öÿèÅ?ßëø*Æ©{|Ÿx1œ¶X¨y²ö4ÛÆĞíóX¯eWüKvD—¿§¤
E³”ãTÌ…Ò^6DĞ6©ÏøZ^´•\Ï÷Dû‹EÏªÈ}‡fÒÒ`íˆ{Ğ÷EÙr‹+ˆ™>Vş‘jÓ
§íÿæÔ|¸XaNV4#ùL¯…
$´m€û *¶:lV5 tŠ˜~dÂë[Å$ôÿsWèPÃ³ã?X¤²yZrØw o/cjç£1í:j\{ñ{ùj¨"[Èdt”â;läß×c¤ób¾î¤Zk‡a¢7ÎÇmZ,©*¨©ÑÎ[#± -d`çù§lrM…¹ïL‹œÂdİ¸¹	Ö„"ˆœÑŞi§¶ÁvbLg	7ç…ÅÜ<Lûür5~/{BUáıO÷Ï¦Œúø/£:Ÿ¨£ÉI¨-İ"£dEË[´Ã,‚c Ÿ‹,EæBÀëÚõİ¹©„::¸Òå¹Z(E|)š,j©ö$µd—#sEĞIÊ„§£-ŞÔ¨É‚Š™¹õ¨µÅ¾ÚÈs0 ³œ÷¢mbU»j·µ	+u=óËÁã4` ²h`¦ú<ŞêIPÖÍ3İúhĞÁykªbä“]Úqëf:ãô!sĞfQ˜#†kˆQ¢îLJM·˜‰Úí­±YwÛäŠP»¹}2Taé–€~cÖˆˆ%E—èŠ”'¬bzGlû!s!$­<Ş©‚Ê¼Áê€ˆ/1àîÖ¨W¬î“¿ó©®f¼usÑ•æçÄ§ßÔqeo&Üg€ÔŠŸb+kñõ"Å(ö‰fO•Ø†hş"0ö(•«!¼tPù;ëøHfö÷x‚Ë:»rÏaµ!ÿ\}UXÉÌkPqejãÍ”û–k¦<5¥š0).»6š3l³ì’*¹"™Ÿš|úˆƒ¿ü²ÄüéRMS3ªÎÍè…"RM)ÕÎ|İš6)]|ebG3SÒ1fq€*Ô„«ÅØGh{š&ÑIkM´qåüì¯€Tø]“J5Í¶í¤õ%Õ#A¡—ÄÜ’˜Gtƒ°ˆXu 	×¾¡[Ğ@mª°ŠŸ·Ëïü¸a2êøM_´«Ò¼ç€Q‹OlÙ°3‚Â/â†!Káë.Á¯¿¦(áÄ£A4fh±É„l
çrµåĞ‰-kâçç(iğªVwÖ®¤¼¾PZE«ÂøréC£ıÚ`S­aÑ+’1“'€ôüğêÜR~Uå{²Lœ¶ˆs³°!µ@"¥½’'¾`ùK¼èj™uÃWlå!¯‚ ¬6™#ø§ùåı’Èb±p¯}ã]
÷®
IHÒ@ïÁæ¢äÏıXùoOl©;Åj™ÃYÜK:üIü =|Û½]µÉ÷èEìWNû•ÒùğôÃ‰~Y…Û>ÿë3ûu§S+kRZô‹ºşvJhpŞZÚÅĞVQìc}]ƒêA`À;`LulÌ¼ÙŠaP=³'ç`v„™ NµÊn_B-Rµ–ág:ûH÷Ò¶ î 1T€}”ls>ÏóÌªtUB¶>¡U™³6ÅË—	¤‘(îø9éÛR¹à÷²Q«=²¡/âUÙ·†dÎç»ABì¥¯ªelªœ>„ªxsë4TÃNUm‚œe×Å¤KÒ¾Û„ö™J‡µ2Ã±_” /G¿˜¼d(»Y	&]Ze³>c0ƒXšl¤_Mb Û
Ñt»?¯!f¿µÕb%²ô¯=œ†ŠÍ|¾/f_¥‰|%l
å> {JD$2kWßhO´[ÜŠÉ%Ó%¯±aWL-7¹ÈHêvbâòvíŞ‡ÀÏÿÍøP–Ln,ûÁÎTJÉœ!HR;À´ñæßËµ]7® ÿİ­¦4ä§K,¦JJ£»f”Wğ•N¾¬»@&eŸ™#£\	Î˜f;°¶gšù‚È—Ğ ¸jÓğØ=u‘m[«ÛµiD¼jcÏMJR#cĞ—ÈÙ$œÎmı$*ÇMÈÈÿ!M†kU›ê9d2Ï®urcNÁ¿Ø2' ‹föÛmŠÚô…Wç¬5
ŠIf€äã?„©[xÉîÌ9’pòï7åÅ5ş«îÚ¤¥Ÿ_'ùâ?ÓCĞªˆõ5XŸjgMŞgÇá€ÁÆÿ çˆt4Hm#ÅEòÌÏJ
É÷jÅ:‡ğâX:» SnZSCÑYöd¬à¸—Â; –<iº/v´S¦O±]ÏÏø«ı´f¾è89¥İÅ˜3ƒ·³6·OÛùª×XS;ŒRŞSŒLğLÕªhœ¸|80PíœôıàOÊÕ›öŠ¹ƒ²mhÈx«Ibµ;·=ÙWN:KÉ7 “]µ¹pìM}È)Ær¥}É5÷'¶¡"¿‘ê ´èÿ@X/}õÆ$/	˜´£¢zI‹ P`c-Şèl‹é.8m2õ‰î‰ÆWÈ­¶kFkºG˜yÖ/~b˜S¶]åVGµ„#ŸòdéèbÄbÆ¤”ıÍíÆºgPŠ¦ñšY$@^2ÛI€nu¹&Á4åéÙ‘ù§ù¾1¾V,vv†@^ÅDîfÓ§uÌüÙ±¹f[H£]ˆ›ÅÆhqj¶Üú.É_˜1?.ÄXŠo³fG`øZ*Š05şy„OmÓ ğâ> ŞúëdAüâQ—Ïè’šEß·)Ú-æbŒÌ‰ àóEòîİÛ|×-È9õòz‘®*Q‹æhıÀØ–Â©Ešì˜éDtü’ÿ±•Şn»×5?f7Ÿ%XàòCZ¹¾C}
_¨íkñ.”iœZZ‘¢MÊsğÔhÿJÙ§5°D)Ÿg›²"LL±¶Õ)ş+Ã‘—µ(´àĞO¸@SUò ³eİÂ™¬§ÃI˜æR¶½‡ÅÂø[Ç’İ³št\k»hÑ4¹rrŞó% úãC-ËÅ×™Ó´k@¯ïJYù¶ÁîŒrMYºªLXİ	@ÏD³³3ëchŒÀ‡ìõ:HHQ¾áf%¿.FLÍÕÑ…ïÏÒT-À.Z[ŞÁíƒ…Dšûç%Y#¦nê´^ nj ø¤)>ırqÈwÈOëày¼Ömcß•3îy´4ÍZÒ‰TN—Àß’İ'n­uÈ Aª ©şT£Kïz³¬¤~ØMœ|T}ÒÍÀJÓsµjöÌ_5&ô–Í€ ©¨†–ukıê°¿GQ|xó¡b¶ş†×GCmT©…“K†¯á/fª™ûÎ—E0m°•Æ—ª§‹&îÄ÷Vt˜4¤ÌÃ¢ÄœT†7Ï€ém@mYdM¹Qïğfù|Ï"jß P>níà€ü~€ 7A¿ÄmoQ…2Ò¦~àÊ+m*mÍİ÷¼HÂ¯Ä6³&û@Oªˆe~Ôğo+¸3;:IŸ¬¤îƒ^qq/7ŒXBC6”=¯ã·õ«ù#†ù~ò]Î5š¯Ú_8Ó1šaR¤ IàEFbkh«5LÛ2¸~®Ï‡GÖR¤pîšŒ#t¶²ÉIö~ 9ÖÄùHy~uš´î@÷Í œê¢×ñgè´?Üs«İÔôs	zbSáŒB²^n"‘)Ü:ıMárİFİd©kùÂ8°wG¥YdÒO7…¹ù­8h§iƒäÛe¶Iá`¬{úHïOH‹;a”¢Òx”pZUüáâBú5ÃŠ­«âj=4 êÁÀifş®:dÍ7Ëñ’@$…à †+KícWAœ(Jƒ®«fz$-A1¹ÍjÂ¢›uãÕEOCõ¨¡K“œ¼ıµTÒÆ8.eÌh3æ:¤vrĞPµ’¤-Ìó	^=İ1ÿ²Ò‡):éØßTÉÓÂœõ·IÂÅ…Ç\&Kø D1.Šø·Ôf8@õ†İ×±ñ®D³mû’$z8³Eé=÷äÀö>ÖÙœşĞ„™äÜ–PÊá®ƒuè»­ aVï{ïC+ìg‹”V)3ONÕŸm`£Î¿Ùu¢Ä±¯vÛŠr¦úàHƒ3¹¹bšD=DUO)'78"Vªi$õ‡úõÅÀ×úeY»`ó“EÀàY–Äü–­Š÷ÿ¢k³{Æ«µşsœœµ¼…AAÆ_c‘‡L˜©aT³Á5¦à¨a¥ãÛ¨O˜ŞíÎÛÜX¸’#Ä*£/U\mD‚m İKÇ—X£y;>E~XXVµ§%åHƒÚ{ãÛ5<DîñÛKûq Î0†}¢—¶ïB8‚GrMÊÆ8oàQN=Ş'DRĞ<$½hÖ¢÷¿üàM-›—rPÿ2Ì+Á–9Ô¯6$ŞÛÚİ'¼ œxÛoÓ¢ğ1ø¹¨Á’ y ( 
¼Á8Õ¶ÓÕ(\É*à¬/rì¸¨Äv’â_¾mgınLpd*á°°=»1ıîZ)Gq¿§5&»àœ6”ÂÑWp(GÓË‘ú¹3§˜2r<N,‰NQ»?ÊÏ½é&KŒ0³³{ş9”ÖÄÂÊ.ğµ¸¸ÛlÎ£V];	BIàÒhı((EoqEŸåh½Mß(¯Âl±E®×mû¹aCÑfoâåşù=¿ÚÏª
È»¹-³TÈÜ!×YwC§ÿ¶Õp’ZÜbFPÌ{M_‹¾3ä(åú;"ö~a·ô²ÅL—=ĞtRûú¹Ä‹ÒMj£ê¼¦dXıH–L‘Œ%ä,ìYT¾8‹?cÕ—.‚ms•œ£ƒk:É~Ñ;lQõPaês‚k¥Ù”«Š¸ÇŒfûøÂuG›.ˆ¬9»»¸—ó+C9˜æu§t¹Oü¢CÏJ5øşög¸Ï>Ûlƒøš+)ò“Å«Å\
İàK•,TPàrx¦gp¼GL†šêƒá2ÈbnÉFÍ°E
€Ó!šÿ5³ö#X¦ë­¬Õµ]©Ï„pv~+‹°uA.á]ËßÖ(D¬L(†Jü}ãcK§Õõ\ 7ÎÆ’Êä–nĞq~ÒXb"%Ç”ù)1©ñå–†8|›V axj"#>8“ «²İŞğÅÊ’c»¹¨ŒŞ¯$ªœ™£Ş£	³²µî|£ B®U ˆšèLw"R$ÑÈ8½~§{‰;7¸LŸÿöîXKb¥eJ¹8*h*Ó‚İ<]ÁÉÃ),EG,VgÒé‚í9›Ñ=¶'…Qby ·hx@EÉ^¾¸nÀÎeJŠŸæ¹u‡ß…Õù¶Y«ÍôÚ”´Oa‰Á×‡	XÀ¢ÉIñîL± A)¢LôOö^ûÀTqÅ‰•“¹G)×Uàd%‡?bGÊ„ˆ>e«FK·Ió ‘ÖWıGœ@~â@T¹ûÉ[Å0è¨.(ÙÍô…İ—ê_ósw§-Ü%Îš“fL„t¨SFŞošD ¶ÓJÔ&)‘‰kóÑŒs‰¾WP¿l£Ï!¦2FR´`AÁÄv\ÉÒé Mh„Åé›l³UÅ×T¥É—VÈŸ=cÊ%ş:†
•çx®¸o.«À@Ğ×ş?ß*«æ/Ñ$+­’¢» ±õÙˆNV5YĞ(ÈÇ¹®€¥!!_P*~^=¦=¨Ç~ò«óYÖ äÛs,PG£r­Œª*òñ‰àÃ£S,é«Œ¼8“8ÂVW0j‘ÿÅIç±‘]óÚäòkã(®aÒRŒ£Šøa>ª6#Œµºµ¤Ù™~YÒ‘	­‰SÃ2'øÂÑ÷¤ãWgüLR«¶¶":¿KFÄ‚vAYY8rÕğm&æ„tô`÷ÍÖ±Ôgì]Û'[â Ë3z‚É˜¼‰šLÁß›º0“ÒØ ¸
TÜ«’Ë¹ı›w@rñ÷ù<£¼´’7É‚MÈ>&x`„â9é-2ÖüÀêğY”œxfş-ÂÍÿ¨•¥;øÃh4vzñÚ\dÊ=†Ç(ÔÏ»r`7YOnî;#N|OŸ²ö¹\z·&N
¨Gj“¥%šÀ‹áÍÕ›Ì¶ò¹®a6¯4»˜Iõc²… wI¢íègïVe[ê5ÿ¦èeÜñÊ˜jZj’F'àîBÄï¾Ü¼¢ß­ıcÃúñÍOkŞ8§”(Kç‘³-aDÒ8à´i[‚Ú¢,îš¥Ğ¢˜Ôõ!ÂZo+-…ĞÍ.0ç¯¥î4Õ”ë”i]eŸ´ËïËUç×¿äÄßXƒA6äUhÃ³#5"ÛìïS?Mºø\İ>Š=n=QÇş¿—ß’JWVL›ó
¯”8'‘Ÿìübç4t´™/WZìåñ¬"ÂÑÏ@Ö_¬±Br/{ÂZNöŠõÈÇ•j*/àÒË»[¨™CüTx™[ş†Bl³ÁèY+	Î>B{¿_UÎ>óQw/˜`µ¦"SŒrğ Y¶¡|°' ]÷‰j’¯·{‹¯ämîÆY¡SÊÑŒMl|ËàŒ‘Gt0{.ÜÅ“›ëo«Hù‘ş»#›mzÇk€¦IÀ¨R mĞZM.'á Pİ%dJ‡t»VqHâ$Øds]jÒ=!ÅvNœ‰…/´è<E}ô’d,‡™–”e~%9Äâ-˜I-=¬uŒuÓÇ°²æTwSEÚ?Ÿªmû¬³ts:ıÑô® ¸Oõ8/6Næê§ (çO !bQõ®y&yÌô!bı³ƒiÛ¡ök#jÚ•ëé„¡_«f²mFg›CÔ×J[¬½y¨lzYØd9ğs¢ß¤?	ƒº {´²h ¡s"Ç’mÍƒ°ºV0XŸ~'Z·Ùj›\}%’Í¤'ÒÄ[<c:cÛ`4ì¥E¾«Ù™J^‹ŒÑb¡÷qGÑò¢—­,fXwÄBª4%ú„¾Zø¥WLLêQ¼îˆÚ0´{V(uû'ÒÁÕX!	›^“$b5‚±òø†ÿEWùÕ¨ÎU2ó‘æhª›w¡°+‚ÅJÃAnÁ—¬ä›‹š‚`¹ +¬#Ô,ãZ˜â¼¬9yñê¯Nha¦4°a¹Lú®Ów©X‰²Óqµ+¸oJWæ»ÖB!bî)R}– À‚¹®¦[q×°#BÊÆPH!ùq_¬¤ˆ¿?÷‰õt‚Å;‘˜ÆìÀÊè™.LI A eÄBR¨T±šq;&¹ıŠ
é÷
Bài¯G0‚«Y7¦´[Î­W"“¤£c6s¤ 9JşœT6h:jàºuGí_¶Ä26Ï0üéÊ»9•Ğf\6ÖÖ |]Îf£©M n8%v37qâÈê•Ê ëTµH.îÇŠ(YVòDÂğ»:V~à!µŒŸMt¬ª_àÛ@kÜ¥ePFó*0=â–ŠYy :úÍI¹Ğ‡)Ì¬[¬#¤ÚYïçêÙPÅÜ5$ÊËîz8/˜+%Ğ{›Ç¼ê~Çí<¹;•ã€ÂŸ\â†‘@D	¼éª²vŒväñ³`™] i/Á«­“&‡ö£»dL.²vö0Ôá¼Î‹…‚*â_6³âø²%"ı|É==V›nåk íKÊé#Å L…k«B|oûáHfòÉf{k ÏÏ8€PãW¤ïºCÁtöŸ#Ò}¸«íhC¶I[3•.ìîÿœsyÀãº·±fDÎy'ëË?„3ıúM5<TÄØ‰+>¸-p¾˜fÚ,zr‚s¬ÃO¥õ	Dçd–àÅZGõ,Ú‰™ú)Ôæb4"ğ7ª°ÒÕâÓ¨óÍJªJŞœÒ¥uÌzG‰ÊÈ®Z×~kèDÊ0¿S?ş[>ªù§·¼8ğ°¦Ô¯ÆX?ÑãíÅ‘Ò?
¶»hÙ—Öà(ÿ»ò¼ñµéf<×®n00uRk‡}‘›§ë—xP7\´gê@–Ğ dÏ4i¥£«sÖ
ÄìA¬ÊÀàÀ·MÊº‹È·ŠWV¥¿µÇü³]vˆ›?wåVÀ«¹úFı%ùƒCõ‹mô¾Õ­ó tô¦ı0Å$QÏQÀÆşra{	±~]äøÍ¥Ô2òAĞpîÍ_¦LG©"\5n¦È§A™"kõÊ×›{>î¼/*MÖãrÎŠy<qFƒ¯-ÿ™m*Ç¿ë@§ÙW*šZÙ\óDÖ’Í„ûğ¬äıõÊÑc"–d%0ê„ú¼üÿ´ğ¿.Ğòa°râ_ÒçfA\hZÇë|Ã¥äp8? ĞßCúIáÿUµ˜]ük´À’f‰iËUÀ«Îãõ	VXøÅ–˜^K‘ÔÓèƒµ®d¨|R€âZœ©Ö4';Ô­äMC.ğñíáæ 3cÁ*Å#î×ŞøÔÔrrmÅ%F«·"´Â"ÑòrÕ¶şü³Pìeà/òx—#MIæE§‰‘Ooİ‰J²[ÃÆ©@Ëàù¥lr\kƒÏ„SbÆ·a–:èG²n›ùÇÛH,J8Vq|£€ ì$f¶k$y’áËHóÙúMEºû2¯V½\ÙÂÌiµ_A÷ m(S2š© ‚aò§­ÃÆ´##wÆ•¤)¥µ¾RMµ|b
×‘Õİı¾‘¸Y¬1—¹ÏéTaØı0ÀãÁ/QŸ Ñ:ïÃ¦>·hSÂÃ»¾´n¼?7ûDm¦×ÍÇÑ|Õ™Í¶HÈF‡¹†^=21)†‹V?ì{·uÔ×0™ôr/“µë¥F{=Ø"Œ”şÒÎ— ¾<‘ï¡uİÕàˆkéÿcà…“zåAÓ¾‘}²ÿÂª/ÿ\ğ”^®ObŠ»ÑM†ÖÍ¹rë^»W¦ïe•s6êòÄær;Şg–úğ³ætÇÈ9=Äõê:øOª&µn`¶alÇ~Üö#·g6E81°(vBdÎx*²1)Î«ÜÕõ
©¹ê?æd[•V¯¤’Ûd€’Ÿ«¦øooI%*È’Ü¤j`#Ğ´§ Ù3¬öK5pÚáéï=õåÙp3¯İyØ¬~æ*ĞGpÏ¡q0°—õŠ¡Å0µí[h’Í1oYeWÖ|@‰>ØÀß³‘ë 0 Êö‚"¦|Ñõ uRºH:£°içf„ı·”‚µ­wçáÌ%*ÊS]¬@‚Õš°ŸQcÙˆÔÑÇšÈû£‹04!ÄdšùOµĞSE~&nR
Ùgò{Ú|;BË§Ä×£ÅõBŠ,Ã”)T	Cœ}™Î#ƒ&€îäSøu¯Û£ıÑKÀ”~¶´¼ùWÜ‘Éij“—9œrí R›YüÖÌËKÄ%hçQÔ".ÏîÅFêLwš€€7HcvC*Rfx³¶E«cL}y¯Ñƒö{²ÏDÜ•D:ïøgvñßÈ3ÄùæJÍ5n%`-‚£WÇê}ûÚ¹ITUê(Ú.íŞe!`¡‡öãnËéa )i"ú¯Ú`¥;j€vTjp›Æ÷h1P€ÄÂ×æ†Y2ÎëgLdÁ½“¥çÌí¨ò‘;*=úQŸ1TŸ1óHÇõ]è„# p'½Œ¢q$†ü•»’0”Ãn7Á­˜¹ZëJé®¼«k3ş#ı€æåó±¬9vBĞ8ì©í£fúãEwoŠœËñxŒ˜<Á`ÊĞÅGÿ5ãŠu£‰VäDYZ<J2•ÊÕ(w•°Mmšÿ±]¿dıs! êĞ‹dFÚ](CC@2On;şç'L]·/Lp&õŸwaI¼W{yóS9ŠîšpŒÚ§}£\Pe°î ¼q^—ğ¿T+A8¬Ë 1X²šCÁiö>{§ÚDF!ªA3u÷ØtêV^DñßœèmJàğ²_ÕôP°õf‘v^‘#¬Ú$½
KNFvO¡Uì¥×lšÕrÅ³Ù['ƒĞ®6?îVš°#@¸]8æÁ¹Œ:†|ï,İŒ(…3ÍoA¤ÎƒØúI ù/ğktØ€oÍ±s ïò„Ù4şŸqİÖÿ	•o–1¬è„ í7GÀö7‚W.­wµ* ›÷{ÓË+/ô©®b¨Ô1u¼8$Èã+^[O=¬MÍŠ)x¯ûé]ÎÉjovœSşäéÖnV[èXZıÕüº¯Rzôß¶üİh† ˆÃ3r‚d¦¾>¢‰½TI«›¸«J¹"A¶®–ÈA±ºxL…)f$º—a•Œ¡CÉetåO­Êi ‰*ò+«¾°Zf¸–bÊoûÄ(‡/›¸X+÷[ ê ñ–FHmM" <5Ò/ä'ÿğ¿­-4·N(}çékµD`@W\ dE<j†)öË™&Â²/wBŒW ÎÒ¯Ï[ıO1SËUÚê-Y|?µ–ä¢0ıéQÅ+Ò™ÅË×$Š†\ÿYL]bbh¾B±*'>VÛ¼úc6‚?àõ…«u.P™şt¬)Àmˆ¯üŠªß…yF‘ï€Š‚aŸ×Ñà!Ú%@f}­C/DN¡·xŠÀL~6¼]Ï±…¼
Ù
ÔºM—±Rªœûí‘aç õüçŒrÌ×vW†Y ÷ÎÏ&fRhÅöÁ2ââs®=7ûˆ²ı;>z	ø>œõDÿÇBSîŠÅşş².V¶9”v´€yO°MpORÆé&#‡˜è,	R™4,îß9Ü¦Û¾[\ÿ\Àmô9Œõ¢ìõ¦äprXåv°ğB"ÀmƒŞá!l¹+*]rÇWÙ}ö#{O°o“ŒÔ²K¬fï4=–0¬ú$ªk*Î-~N°±®Y9åâÀ}QM?¬F§-Ø74ãªÉoğ !iØ"£^ÖXcP¼À{&ÂµrY0)¹Œ/Q_à‘
Hn~—Ÿ¸s^ıœİÍ«÷šÏúñ6J¸^Ö*Û;ñÏ^Ù¸~ä:ø›Î‰z{GñËø¨V
lCÌ~ÍÔŒ[mÙ3µk1V®eŒ†ÅŠSicoØÌöÕEÎ¥°¼NŞ1â¥`½TiîË¯’V¯n§¨'FZöî…Ø)ğEïGñioÌÚ×è¹ ±‚Üï8'Úl‰ğ:#c4ìû†Úé35ı03_O²/áÖÊU—ÒÏ³JùycSd-´í	ª…³2ş0K@#>±Üæµ·ò¥`¦Í3ô/{$YòÆš!´J<‰ş¿Uİ×cÌÜáğ²	ƒü>”5éšÑÖI¿¾ÕOzo 7•Ô“0€´¨%Q1ï6 ;oJPµi,“ºÅ8NâUÔ¡Ñtü¶ÿ‹İò„µæ÷¥Aá5Y×®?Kªg´—O§$Ñåï›è½™­—R"¥O]zÖåßX«Ø'y1e3‰W©*&bÃ#„²ëúq“¢oÃGÏíî(w^:0äìv|¥ÃHYê6&¦Û­©°œdî¨àÓÖ¡U|"uî¡—©­4Ò6O`¤zìÅ’4p®‚Ù'øÉgX¯¾7ùl‹,»mb_ØZÚù—e\ô#ˆACÚ•Mƒ÷}şäÎÒ;¡php;4Œ,e9ØjÇêÁMŠ'´gOŸvƒøêÕşSz¿=ıH	î¨5•ö'Õ\shû	İ÷ÉŒéİ,ÎôsW“Õ|²PÌÀ
ƒ)Ø,{õD€dĞ«[¾ÁµKdøHÆĞDölÜ†3Ş
ë L¾ZˆŞÍƒa‡%£6q‹r|±`*µñÊ7äğRxdõÎ×î?qÑ¬Â›¯—ñ5³Q/Ö´{ä¬°£—qÓÆÊWg†ûYoŞMœ\(}?¿p§ù¢@×«³‘WB‰y¾ŒÕxAó™×İÁnGñ‹=Š¿W—ü•;Ã¥*Z¼¯ÛşôÇæ=êb8Ægn(ñº4×Â‘„!*	º _\ÇoqW³Zl¯½~óÑK°}2ıÁIM=§Å#"-ôê'ye‡Kv±
}-—5“¼íË-fş_Æ€í@”ë?ùx@¢^áTÒ¢J;×İƒ%Ş²òf>Áé|Fä”QBùaÆT©pğE9ÒÎ5'@ÔiÕ
 ›•§la±¥é!# †½ÌË–è°È+÷(İ óñ‰w0”3¾•Kö\e¤çU_Y:ØŠJÍ¿lxŒCÊCìåj1ş	¯KÑ÷mñ ]¸'†Ö]q+R<iTs	SU[Üh}Œr {íá áò€uôûbğtÙ‘¾‘Yçº|dJA7zÄ­òZ
mo9åR?¥ÁHë´¸Ÿ=m+UŞÎvÌD¢)#v1%¦'{šsXñ‘ñ'†ÇEp³ïç_ï,‹û8ë½úÜjBÈ‘˜!´<€i	ş\WÎ	B—^³øY	Ò]ŞÛáTZQ[r¦›¢qÄ‘îJ÷Û·Xj@[,'+>«{ğµ¿²¶¤§fcÉ—±FïµFwÂşÚ}¤Ô6¬bê6§İb¦´j«ŞtV}ë­SşD% Pm"Eê?HõÎƒÁ‹ZG|ë>ü‰ÓPGLÊŒ(@Äôv¨×Ú=¦øUù}rU3ß{–moô˜§Ï§¡ñtÊÒö`·`~ñü,e7C¹
§€îÎd×S'<ä:½ @'}E~âòÚ©”¦\ÎTKë¾ÊqÁhWöŠi¤:R2èØAŸ5@´f+?ı¯™ Û"ƒ Lì¶óÇÀÂïPñ“s\zÃe£€ş’í¡h'¯±-ÌV(M¦©—Ìå^ß?ÀÈkÌŸù2rø[ßC™íZ;ü˜½áè„•f™ŸØ·kTEq\ñõjÊØ™PË†ÀË8 î„c€ÜùıZK=»Š	AèrÊ2oÎzGƒ#¤®!lx3ˆ2¡ª¸ù®ÈÇnÕiâw=¿ÓÕ=ôó,*‡ 5–;ÁZ%ğÉk5­çØjµ“wkŠ>}èVÏ¾vlKŠ½rÖık*RIÀ·
†ÿ[¤«5ñô{)ç2¦C=ı1Fk{C3{;fÊc9–¬ÑEÆ€ó—_=õ[
¼Lšrd&ì§w > këp°ÎaİÁßÊ=ùè¢)HùUC*?Ä—NÑtñÔÈ6tŞÁBŸ9…à¾{rÑ2µ '{ßĞQnòÄgğ÷ş$¸_åÈŸôä RıÖe4¸~lò¬?aéÆï9¹8¨BhªGGÌê…¿©7ÿag0œ¥ÉHÄ»o‘üe#!W±ZWHá¦4•¬ú‡G`¢Nßu×¯b»… ¯ˆ^ ôdÏaÉ˜~ÌaÏ‚“îIA¤î?»¯…ó}k©zîGG´ùÅÜËò¹^·ëÇk{£l‰?'ã™¹ÒcğØıÂò\qù±çáÃ¦dÚÎ9f7(7bj*iõË‘j-+éÆäÆêĞÖ ŠBuÍõ©ü{n5¸˜¦Tè>¯ö¤hùÍÀíÎ÷Ëjğì|ÑˆlºÑ†DÂj$ŠwS¨ZOa§ŒKu/UŒo‚'œ"c,Û:V<EâØZ¿ ø£|âÿâ§ã×…fMPz0çĞòÏÈ”ÕŸiEáFšø×uÚ#¡˜–·%ŠÆğkz‚‹‚âÛè®w©…ø¬•! ~=E¯ÛÌ·ö÷)ÃıŞ%ŸrKPÛ\%9{!Ëh	.QÊ5K_+ÒWoøfq9qä3›YÅŠJÚÌûŸşz€~#§àæxƒbé•ØrÚÁô´šµ/»ÙqAäaĞîèk§èùÎ•8ç\ÏíÔoãÎk0 |¥aué2ã)É·DIÌ(áÂş=+êğš)ŠQõÖ€$ë*¡^ß¯wc#½º>%¥¼€6übc¹…nÑ®ß‘Ä†¹£kÃÜ"¹?õO’¦½÷.°m~º©Ö}\!¬Œ)Ä‹ghTÄÿ}.bÉÀ_#F¢0ãÏËÆ1F;$g×LëÏ))1
lÊ=	e*]ÏE¡Çê[.æƒâú«lµ²7\Á¶u F›³"÷½Œi ¥EåPË¿DÍ…ÅZ§tÇğâäÜ6—Z¦¤´õ:™ÀÕES‰í™û’wÆ 8î%¿?sJI†À9úƒO$¯:‘ÍhOÉ ÛóÚ‡zsNF;+iã´&æz[­ÇLäøCJğ{©µìÈ} ì²Vµªëœ/ WØYW8jHUë¯·m ı¢|Øf}º¯ßµÙÛJQş–dy‹Eú”ñ-ñ”R¯/€½08—¡C`P‡9.ƒÆ»Z&¡<iRÁ!ˆxL9ê@\ş=35ØOu(ñe«Š‡ÿº|GñC·%¥d¾õZ<»$2»ĞºÎ>…m¦ø ŸŠå4h÷ ãËÇ}2$dŠ3ª_ÿŞ…L(K/”ş;{©punoÙêñ|ƒ­Â})©n;g(hl?>œ[qÍ®ñùÀŒ‡±AŸ”0OÍ·ŸSò¥¿\ÕXîÈ&¹nmf3¸ÿ±daH¼(cÖÃ`
µ>ş'0ˆÚ?}¸lâöC9“’¶æ$¦Ÿ0WO!· áS:ÙwÑš§j‡/a\ssúÅ¾Ÿ™€¤*Ã;"i³-õAİ¼+ºoF(d±zÑSNô«©Àö¨®±y:Ğ¨-„ZÕû+‘Šşh±ÃMòk´íg¾ıfiRJ•Ó7ôÊÍÿq‡‰J¼Æ¥(»‰lg¿³(¿{ŸE‚Æ\‚"®¡hÿ¥*1­^’\wLkvÿŸ\
ü[u•bÔh±ú¼—¿ q=+³*şüPÙê` m¦@3¬ü€¶”ÿ1“¨ ¾> ÷¬¬óaP«ô'ìB¥Y—yĞ¸n‡!àÂ«ÑÙj²º
À‡r±’LôaAÄÿlÖ¾t3‰Ö³]’ª¨†ˆ¬çÄ†“Ã¬ìÔÀªÑúùÇAÔS$kZû½¹	ÄÚ27¦Í6(ca_e¡ÎcF™lÈMío á]E½bé»GıÚÀ*CwG²€aF:34Ö§LJ
üHµĞ¸úä)İîHù˜Èã›‰”^ıĞ5|¾%4|ûC+d€kéŠÃiVË¹{Á4!rG<Š¬mUrsÿÎò|“laÏs¼Ã7««PÆ?oV9–ïa	Ø;KÍ"0wı?­ƒ è›XÎÏg KZ.ÌJë#°`ÏÈÃŒ@!I`ºàS3¸hÕÂ*+‡tc“6S¦ôHØ`ğò§òPÛJ{oìVf´İJ=·å-Ü'hµZ<Ù‘ÜêÄ´Àò	Áí›)MdâcÑâcI‡§´}{ë²ãá˜º¤¥2)=TQÔŒ»³ÚMÈQï(Ôşñh@BY@g/‘’øiî´by‡	èeÜ`xÖï×·=ôÓ˜İ†wİR{¥)yC6‘øè¡hOÉ€(4áú½jÆ_÷ÿPÕ#\’Â§:wdpQw•n;xÿXÂ`®ÖóŞz5ÜÂ@\yZ`%µ¬®T‡
‚Ç«>?J9YÂûÒ>IÙé
ğuòÓıı™Õdl.eÜW¿y–MÚÀ÷yïğB;L?çÆy“!³¬ÑKa9K4yÕW—¼{;bŸNd½–±vuÖ{ĞêÈM+œÓ‰ 8™‡nX»ùªbn1¹uÜSãÛ¬1ez¿M6¨e€$Wu¥¢L(tK"¬\ÎÑ9Ä÷Qæ€øXj4×Ÿ¥¹˜ïL—GITµ&¶E)ä_«€e<ÖuØ¬+€J
Ó0*„ÓDñ\ÈL9>‹èî`f·ê~óÿèÊ`¨U¿iâR†Â	İÍ¡8¯qÓ$ó?kSPWØ(¯çY”Ÿ¼83Â~³èìt9ÛÄhÌº&Øß2¯à€Å¿=d{UÎYWÒXsNuJãß8Ñ–VÁAZÃ°,nø¥yÛ}Q*fÈ"ÙuyÍP'D†ù¤º,©ä€%*8518P^Ìšæ>(¤½<â7¥Ä¼BˆL#o¾$Ğ#!SéR„n—®ëºİ¸½8“¥"ƒÔyğnqA-&”­)£¶ÏO?è¨êûë›ÜŸãâÈRÅƒ£6Anú$dˆäËª€º0tûïZåÓ–xeÛ9£@Ú6® Í‹qNCmÒc ÍÏ
iñ.¬ê¹‰âA~IFŠ/G›UE@’n­l“=v}©ˆ. z”6ùºÍ˜BC½Ğf<8:'­ÖgpMYÛ«U9m!Ê7Â-ÄÉã¶Æ´ŠÄæãt0™<î'œFv{§:iİùÈ)µ ;gû×yò`: €ÿ(naï‘Ãºç†Î
:<è³™Ğ¾rãs%°&EÈF+è%¿şKˆGĞ?§–Çÿ³KÜAË6Bú–6O¦+ú“˜¥ËOFL–”¼vmŒ*9[[K÷tÖQ¶ƒĞÈfµ™Ë¥BoüË·µé¢F(&’£óšå¸…³’Q®Ñq%O‹ûçëØ¹ã‹»¶Et©†z´	't'æå@?ë'åÛëqÑØ _£3:ÓÒùƒ1:-`Smœ÷¦wçÖ9-ıàú8èß»‰>ñi&">f«ù¾äí’ÎÀ$Q_Äg§_À¬‡YœÖ7ÀOÕRsõ0ÃÍ¼¬æ`ç3kQÚ@‚ÓébÓ¯g°aëhİ"i¨DÀšşÌVà«Flm]—Ãv¢éç›€ºÀ#éO&äºj6HVn$.@™AJŠÌ…àØ}	u	¶°@—=Ôî×¡ ™ï•^U[ÙJ4¸á–nI¶M¶7 \è-b¬U‡»;“nz#é6ÀVì`|CIëïıh÷7îxï#wùâèò1ş€y”Üz“d_$‡µüu_
‚§Ëø[Ã!öf ŸÚßd„ûZÏ%Ô[á£%ïÄ„[ôæ!ÿ=×BÒÓftgN8Å´’ae«œĞÊ’^ìYú¦_åè[qõbÜhÃí7º‡:Æ
ˆŞ_3¥ã|®Ä@¼¬[ªZUq±÷Ÿ’Óè1÷vÉêatˆ5F›àRH˜! çb[)¥cCt#s.¼s_Õ1DÎwîãrÇÛY.€8µÂ¥>9+¹ù~)H	ØÊ*£Åëâæ¦0Làc¢ÏúP‡uzhW}H§ëydËÒ Ë`(`0bô¸%RbØO-Ø-gG¹&vÌQó£Şûƒµ ä6uË«x4ŸF”•»™ÄÈ¨ŠPû1¬¥¥´Lj€Q5ÑV¯M:}}ç(ŒG<>østôußw^Êæl‰ï}–»lxå}U|E…FÑÕ³í™bFÑiJy·M§:f©IÊ0k y{ª—‘gQ‰$3,{'_c» –0fŸm”8]UtØ5j³·7	‡^%æ›PIiV*<õ¦ŒV$xo#ÍÁÜŸ GÖ>ëÚRìšEÊÇÿf'ß'¡ns‘0Iï-â¢ŸŒAônğX¿ ¡€Şc´yïÕ~gşÈYÅ,ˆÏÛÃòï>2¶Şş#¼—3¶t-ÌM…X³@¸hã*(ÙAÀˆzoP«øÊ/3tåI©¯PP…scéi¢ÅÓì’ü£ âCuhQ›#‡\dwj4üB¨a??éFmÿî¯ˆG2¼Ã v¼æ·F1ãTµ›ÆÂm0g`­r-I¤Çˆ§M@ÀZ~{3ìrâ uoC1 W;»Üc÷UêoŠJÑZ4_lıv	‹Y6Û÷Õ¿Ü›|<:_‹Ó¨–,¹¦ç^Mön¹cÿæõA”×†4ß˜0œÛz‹À;f+GÏP;f¢n>ÈBc;©¯‡,¥DÉäØéò^R“§x£ Èº¬«gß$†Mø/*2pç†Ë[R˜åŸ¼)÷MÛ~èÀ­¦İç0›óinãgŠÿ*CÍÏ]D_9…Ø¯©£`gìTb°Ë4æè—áDÔó'7-£7yªşFgc(İ‰wQùÑüIô¢·ßôš9HÍ#—8Æñh«mô>oR¦]NZ´R[¹&ö8Âç²sîb¤@ìÀ¦å®ÔÏµ¡6èT
È[!”Ôı½«CD&·‰Ü¶·jo#Ñêé×IA¼Õ›.zPıX‡×ÿÓ%_>î?	Š«¦)»ê9@FÓÁ ÆÔîAÌMâ\Ö2G,%Yƒu6Çl®ßÎ›àBIßÜÃ…¡XÑöÃóa–NáOÉ@$<rBJ’kS‡n@±fµA¼æšûä

~WÎ¨IGRúDÔëá†7`·uU¾´Õ>Ê&4„w<A‰o˜ÏÆâæ¬6Çø`Eù‡À!.g­«3/AÛ3WüT/ÿW¥6û
0GöóÉöDP›)ÒLÄ·ò„81Gsìl÷(wKŒÊ–R§7Fh xvQ%‚<©5¼×¹Í¼³`É_(¦€”t,÷Š™ÑŠÁâ§½o§ÕÇ–SE©”*–æšÖ{t­¶zcsãOá(6ˆgdè…î¥vÒP P Àd7ÜIö­§E™£†f¼ßûÛ»eÙ·AÇR‹MÆG$ÓÂ/ Ÿ?‚½jômÅnİA&ÔíĞÈbc‹|¸C„…QR‡eûvÕ€N¨K=…åôxo-Á}Ó–´;fƒ­²b_ãşÈ{à¹c]pkÛ%¹ºGKâ-Öhõ<sò¹k#Ñµ‘–®ìÍdpøRÜÓï‹jûm÷^<yV;~|nBÀìm.KšuÉ-š£©˜q>•›¡í»¬6âp`pø?©EÅ«b¼Æ^?hl©Š~Í½¬y—ıñ8Ğ'6
4èi…+ÎVçT¾ôàÄ[Ñ¼k[j>ë0ëJ«Ô®f.¯?·ı^=½&—oıDV÷)¤LRëË^»úıE£ãG²ç{¾j­•]|ªNr–4‚‰ùÅœßŠÛiÏª«Ü3‡.ˆ*V8Amôõ5RñS$·â.B(Ó3Ş0\Ô5€úÕ%PXw#—

v©Ò£N%9ovÎÚJÑ¸ËÓ8SHÙ¨³øNÑ”bfçtU§ÓG	6–ÿÔù$3Ş9+{¶:1Î°t ·Ö{İæ»ÎípeŸh¨…#ßqhÆÀ°:QkN>}W„„“Oê'U+Lm»ld¹¯ÜXpWTOq¢)›7M$Âû*¹yoÃáˆÊ6´úEad8âÛ¨ÅUèYÑµh†ğ£ï¶^É+Ë_ÆŸ˜Å¿Z5ºğ²m‰`˜x1yhà¾ĞœC§…~oŞœİİVÿôÌÏrEgÑ¸Zõá¥°éŸè^=¼c*/~âÆøEbù4˜ãá[iu¯şäôÆšïu˜¢5ÃDŠã:ßù<  Óà£¿û]ø
Ğ$V›å®ZŸLÕ„2Ñ«º1íofÚøaFû r¢HyÎ¾bh*' ö$ªXÅvÙ¿1]1F]}›OõuSôÓÀ¬ibkå'\\âí»«u½ì•úlÅ‡G1ENÚ³‡oE¾/ 5º‡TµĞƒº»2m“şÓjQ	wV—ö"?@¡«P+³s¥§vv=ÈY£ª¼@¯Ê&†e6¾Gé²%ÚÀYœ‹×RhUkJ àdg³JQ¨59>ÖôõN§ù}Nvùé]­&&][D‡Æ¹æ$<æ/P/tÙÃˆY;ï	ÿş
âşÚ6[¸ğ¿<1Am`ˆÀ3Dµ¡O9şcÖZ¼‘, l<¦^Ø;tXÍUN~vË„E
úÄØ‰é˜åwT$ ›¿÷è9ğ¼ØÒ”Î>° j@2ã9¾é’æŸF§KºÀJª±r÷s»÷ö†DòùPïŸ£¦W÷ÓüQ¯níé,"ÿß‹œ5-r¯/s6ºgâÑuŠì<Œ‹şé·Vş
k§×“,C:Z°¶Ïj%øÉ>¾1÷»ÒÊrïiî¿ºı\ˆû'1èõt’¿=¶±£Üt90»ÔúI¸‚õÊl6­µÑ¾?tTñÛÌ¯]íÒÉ¥
U8û»LçîñÕœî;.s½ş¯…Ì°¸{,’yÉœW©„[×nÀÕmì»Ùsù	Å¹hkİåÚ†{ÁkŒ0-É9Hé !ŒİHĞNhê;sj¥¼ğ#^‡LZO…®2nßÚç‰sSnPOô÷"`‚Á’KÎõE–OˆON˜ãïU–×[¶"Ô„ÃõDÃ\„<D¤Èİ4ÆgfU¶ŒªzXû#©¥);$Ì™GGÉÂVxñ«¤§õ|›N U¢KŒ‰*v0ÑNFx|w%ØL`µ?¡µOâıÍÅíR n‡AÊ‚0=Ö¬á÷¢sr°è08ÙÆ¶ùm‹ƒ/t#–ƒö#tˆ`)x¢ß.è¤–ºû†ÜPª5i2–ç%B˜³«EbÛkY­ ğ+Ÿİòı‰±L*"]½T­zxÑšv2I4âidD7 PâUáºw.¢¦¸Rƒ¾îÉœÁIE€€}|"ÎM(eÅ€›Úÿßt¨±‡—³Áhåt¸ó±°Kùt1·L§7ÄEÔŸÄäÙ¡ÂÍgP]4¥¼x0*^õRşA€¯>ûÃ™ã±gş²È&È#ä{‚=t…dl’ÃØ'Á`ü#ÿôÁæVhC4;$0úCŒ÷YÏªf n
µb/êê@NêK\Åê.–2f+Ş}³7(×Àe_Uü@_DuÜ¶LM€ô_áêP0Ì†õşó4˜-Ó’ƒ™Â-nÀ5&íNÑ"Ğ§¬ÀÄ÷Å…Ù¿¸át’ä-Õ<…+Á‘ÎÓıhÕÖ)Xÿ6*5·A¬6“Ãœ–'T›$ûÀIGyW1Ìıl]älXÉôkœ}Í‘àİ»r~Œn0«/¯ÉpëŸ'ƒØÆ±¤eïµ§–o¿Çxığ0Ó/\İU‘ EúÅ¤ šˆ†á¸É3XËÃ½Ü%õ\wgÿ¾KãÏ—ÆÉjÌ‹£_à:ñà×ÑipHSLE®S6¼“ÏÅD•1»t-ŒØûMGK­Š£å²ó¸ìôãbÔòßh¢ÈšÅ[ß(‹ˆfÜY³aÁø÷}E‰,‡=°Hr»ßûCqí«ÑàüNEí|Å8fÂóZD½I7¡PÅ×ÌÑØc™y]4½%º§SY}8¯ÏÎõœ´<ï—Í2¸³Üú‹õ“sçsüf»!œF`ø,-B@œÖ¨I <Vz™ãü»<K—Ù6¿ó²´Ğ‘ã	*RNª¼ÖÖ´w®‚Ş<¿:µ^Åyuš[qØœ@d‚8ù:îÍ#eù£vŠ™£›È'Øñ€`Ï¶'Š]6ô=¢zAÈªÏ2ÃÖÎ|„mQ§áOC_¸f‰{Ã¡©W‚5núæ/æW¿!l°xáFª‡º;¹Ñı² ß‡²%Û¡ehx§Åï€Š§´Ü¾Ãç<‹ÂÃQ"£Ê"ÁŞÔ½ßàåşàs¶a¨ºá‡µ*Ï±\z*]z<Û?7Ÿš¦FĞ¨gÊTb|7Õ¶f†Z-Eı 3ıú)P“w6[ Ü¸4v*õÏ¼¹%{¼ë'"„!i™ÚK"}€”ƒœ‡Y†Št-€_®•['Œp~²;ÂÈ.ŞU“€ÄÀ]şÙw9&0—pUc00ÜuÌ_{ÃlÑšNBÊ&	k4Œ
W0cmÿÒÎL‰¡ë=²Jèù×{ÄŸ$„Dì«bPrGA5l=æãêW$a¸zÚVÃƒtZ< º$HÂ²¯yHësŞÃİ1<4‰™Q    N0ïh,±& Ş¹€Àïı¡ú±Ägû    YZ