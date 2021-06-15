#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1992652908"
MD5="d524e0b4a83062d931e12c9f5967c16c"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22292"
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
	echo Date of packaging: Mon Jun 14 22:22:25 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿVÓ] ¼}•À1Dd]‡Á›PætİDñre»å.z0BTô·²G@èŞ©ÜQ{yJ*œâüÀr¨)0Ìj»lÙóä±”˜ÉˆT9{ø*zÍİá+úˆ#I'Ò\OçŠGn|%¨¾à^ü9×Á±®Z
*­ÂCG/ªP”5Ãù’Ñy+—¼G%Ú­«ø·Ö¿®Õ2fĞŒ5p'Hñ™(
Ö]MkŞzDjMòğÌê{`TBe`LÌWÒSè<İ~2zJ6çÙj==[Ãmß`ì²¿eg
Xb†›v·m\ŒËÒºaÚT„ˆZQ À6L	lœ)i¯–¾ˆ ó¢<òRuZ©şÃüå|BÅ•.vfwã2=ìz]S¯ª.iÅ,ŞÜQÕ.>[ôšâıåÂH‡/‚››è%ßQA[&ˆĞJÙ¾äA‘Ram¸Î	|µ ˆ‡äeıÊƒErä¤óãôàè‹H‰İ¡%½e„¥A­¡‘iPÊ2Ò,^L$@H(´·7og¾§QzöéEˆÿÄüüM`£G'TR;sUKìù+×2K+bèÜ Ÿú Qz;J
NÀµª¢CûõWR¥ØS'€Â.½ûdXßş×=(°+oâ èZ3`ØTÚØ2„¸Pç×Å]AÍˆ!á*ÿ…tÊìäŸ´¢ûõ*3ğ¨¡Õ¢Ã]3ßHN8c_;ÁÿBya ¡ÍkèuàÑ€`%4è	*,ÎfóX$d¤Dªk^ŒŒph¡xbL³ş¶Â}oY'ÔßÍÄûnºœ9m¦eFAÏ_W^Kiº„Y!F”½ØàS|nÏ"“ÒÈõå"WŸGCz £ùµJM	v¬·
ñ1y¦F—Š±ü¦E )Y§ú~·¥êjû#ç>èää°-;G®|_2³9Â°ÏÕn^"ÒqêlŒõ„e%	gò,û¶FÊE<7Ök30Ì#À ôÉqg¬±‚¶³oÁöş»ypìGğ:ˆv´Naı³«s›ùE[ƒœæ“èc25·ôåâƒğh$]®¤È©¶J§_íóZ™+áâÂ§ìhê“z ú0a EÓ?øHrûQ\%ê,sø¬\¸;4(÷ÓÀk{iti®‘ˆq{#&éÈßHÒK»=<:ÏëØã«Uÿ³kÊz <Dxƒ—ö2‘âù5+wÎši…Ì×WBõ›E	´ç­^Kh‡µğ`¡–<û´P¯ Éª^®ãÀ°MÕG±¾­Ö“a ¨ì-3ÈšÁÁ4lÿ_Ÿ“P*œóÑ¶ÉOh‰`ğo?_!½–±¤ŞŞ2UAˆ~›pŞ>fÎªIEzZNÃHWä5E²üÄhêàÄ¸îl1ú9‚á½—êfuWU|€U0å{ìÕ0Ü—?İM<$ı”!9mSk>\„SÂXDaú‰ÜK<ÀXİ,ÿ1öj§Ç3å´_¡Wkßª×
û@Y~Şª>ö¾u´¯Ó¯?hÃ?%…d“´r¾‚¾¦FéM€’öÛÍIsÉxÀCïnÁyQv>Î[ïÌœêğç	Ób.dşÙ¥¦Ãt±ÕR9Q ¦f¿ïˆ,æûùT
LkÚNV´OÿËQ‘°Ä½›ğn²‚â”NÑnğ&E¢‰Aó¶pûy¦­œ¸T<AıQà ädÀ:T'^ü{÷Öl× ¾óÜ©	º„I.•ÎÚ—4õ÷ûs+sFãã¹ó;ôCUş‹Ø÷ñV?¡¿¥"~cÙ&Í@|7	ªÔ‰Ë»­ªÜih›¦ü};ğ+˜4^Wöp{qÉ6­5‚©öd0³¥m	nLvôš®º’„òœÇ­îøFÒ z"°($äyµû]ÙƒrUşX¸ˆj¤Z¬XKsœhÿ1NÏ5ÌäºO9Í¢à¼?i›{m¨´g¨~˜±N˜;vŸø°"´æŸ'S39“l*zHyÜ»5·K´!¿+*)¶;:WúI˜x2“UY¦-¶6[Å“J”~
z²Y¨pÖJ†c®:É»ÏÌN!ˆİ²`>¥‡$á{â¢8c(“ç-Á¯„X@Ë‰@‘»š™TïÁ&‰nŠ˜YP%Œ"ÂÉŠÕ-Ã²Ùãö„|èà:à‚—®QÜ¥ÎL,Š¾À£3Îxê» ¨œ¦[Ôˆ„OMİ_‘páì“/ÿôØ¼Îá¥ Õ‰B±Rªy°3™¶hgrH±‚ÒÇsÉgOñô½'(3ĞPıÁıEöX@ÙL.†¾zÎ‡lDâáó#®’%/-ÎlYfM«
ÍËæÉ3-‡5<(C¦Õ´ğŒ½ÚyK!öîº<È!t~Ãy&¡]“;ã3?:ÿÚE¦cÿ½0Ó 6¢ë>SDÕhgTŒjq¥ø¥”{m'DG¯CdåÂsn.S(ÀĞ¡@°Íös"½,:QĞøƒĞÄƒ¼"!äY1	w['WHeTm±Tà¯Ñ­Çw:¢ê^ş.Rˆ ²©ëéSkÄ¢ä6w¡åo³>1r¶šÙØà5"¥¡ş¥$¯‚Üè*¢!şÏÂÓÌ[	ibdĞ+“vA2|8®(°ír$Û5î2"bˆTEqîƒªõ~=W§öâ>ÌJØŠŸà¡f’ \¯Iİbg¡+°Ø‰â‰ŞÂ©lå˜Xo¡´c ŒU¬9¦|ÉL~a¯ ’‚'mÍĞÒ—ÏÚñvd’·ì%’¯ïMG}5qé•â‘mk/İ¹X¡ÇÊRHÔIŒ~F±€e‹-XıçzNñü¨ú»Óî_c.0	Ô_÷“”ëR¥)í]• #€Ş3£Äüƒè¸Óğ~PPH+øœÅF.Q¢^WÉp~¤/D½…	5İ™Ò?õgB…„ÿ/`vmÓ}5w9u4$@­÷ŠRŸ5¿.…Ÿê=*ÏôYÜl¯àª•;ìQ$Æ°~;EèXß8™ç|@ì7†=„&«ÙÏw›Ö¡•ù ‘Ù““%µÖOe)î¶—ˆœhêYŒD¦º¢úóP‘ÁW/’ïDSï¥ÁËÿ/önÆ„VzVÑ‡C}.)fª«)2eGÒ¼ef!(Ğã'Ûy¹9èRŞŸ}7IÆçÿªU€Y!¶ü×—gX0Ùä¾“¬İâœ hIœ»‚“¬ÄÜşn=EySDYb”Ÿ…şy¼^y\âóF°¾AÑJãn·ĞAşŞ»ÇhÔŞÑURp±XyR"¾ÆÔËzÚBŸm.7AXÔ«çXâ å%@_Àú™ö(KN›Uo; P‚ğî†iÆ«x[çàL£Î¤;ÒÊß€ƒKæÀWéæsÉkJóW»£*@xÛìv¢·˜úôÀMpf>áœ3=.â”`3/LÒÏ¶P–áílò üXå¾K‰g¶¼»¡ú §¸<vd|ìÕøTŸC9r"E>=XbíÀÙ	úRLUÄ‰ız9èÅ>µqv=Šà·WNp´â‚ÑyÆŸÔÌ¸,Ÿ·~ÎºÒ›WjÛRúê•ÿYY‡ZŞ¶ÅR‘ÑÒ¿@’Ş”÷Áñ­!yÈXÉ$fl¦ˆAøTú"Auô©¬[•ºîğI]PîÍC©
ıêRZ‚¤g€¡9¹³9ô4 ZĞc3 ¢]‰¿ÜqxÊè:ŞÇJ ÆmŸ¬èièVÀ
Á¢À¿†ğ¨(¤ËGqhá½6²ğMFƒ—}‰¼ı;—«m±ny9ó.®Éü÷[9á!n6ù“ÇX:x¯7.C{ix[×µ‚L¢¦*q¿\œ%ó'R%#&lXí7 m4+ÜQ¢>96$‚#¥"ïš½ŞUÄÔÁÁçLt›hù”äo£ìnş1`ˆ‡[¼İVÖ «MöØ›ÈòğÿMDìl0	OÊNŞ(g©	•²^KY%¸ôaéÖÅ¢a%E­ñ¨ƒå¶3OÿÚIH öL›ím5eGªHŞ«^—’¯qF¨‘—´×>eğ¼.Òg›}¿íİF($<C€<TÅ¬ÅÖõÁ™Jd»¾éåïG‡Xèå…´ç¦›>¤HÜ+]Pd£Öal–¸÷Ov«šÅµQ·ùóY$$çacªfYc	öÇóõc‹ö_ÓªyÜ¨öÁ`KKB¨Tÿ&½8o*¥P!ùºİ;;÷"ÒùÍ«ª­Âˆ};Jû4\LXŞ]\%ÿ]uÎ7‚ƒıœs ^È¯İµ,µ,ŞLê¨$E[ûÊ£íPƒùIX¹dm¶‹TÃ‹dÕº÷á’2ßùüí©³r³@é¤~hàYŞ¶ÔÓsÙ9‘{/EOfäã,n¹.rŒFwëø³ƒ9XG9Pa˜‡Ô…ö‹dZ†Ñ¢¥NæP™Y´ƒ°îºëŞ“5¿™¯<#ŠGšÃ›€øÆ1&…¯Û¶t%XÌm™ç­‹ŞN’E»2ÿ›•Âˆi´´1:ĞŠmpª »„D]Ã‹ÿê¦ÊÄ¢7'i—Cİ]İuå&Ÿ™VGİ©PˆÖß;yÉ¾)ék;S•/¥uW°nª,™KåÒ&w±Vîã$ûöø*;s,sÅıJë¯àˆş#z =ï^FvIP(òİ#2Ì"ï|nSM½ïÕ²ü´ÌåshÆ¾šÀãMâ5;\Õ6íæ}òÊ§VLÖÊİûçwA(ÿúÍÓÍ—oP\ÊÊK+œb^|VÙ€o—óçæ\ÕÉ]¤á}E ¹àJ+Š?‰”4î>tï«ååÜZYçq‘ì„iúBP„Mé[¼Š‹ö—ö®r¯ëÄì›ÕVä€†6_Î…~0à8ı±äÁm5ùšû	óx1¯·P*§á=HŠÉv›yáàL¸cûvŒ#Y9:ê&ã’šDZ›Ì°C3XŞc }3ágZ7üÏ4Åöü\‚×Ã‡¡€I@ãÔXLt˜’eõß»®\³$r‡D×~â‘ÀÃëÂ¥ §ú‡z@1İÏÀõ÷ßƒèÂxÀ ¡/â<©¬×¹;_¡¶¯ŠN~¢Rcí ÜØPÄxï¥¥0 W‘¯FFÚ0Õ°Z…hZ¢ş4­‹%¹‰K4óâknKéÖyOf>c£ı´WgÉ¶%gc/z/5gCÙ™mumt˜ú;gxïr5ñ‹HÀQ³¨$ÕAtŒGª€s+ÒÄDù¦KNìL9_9èw¡I n#gg¸mQæ
Á“\†$q#Æn©FjŞ…ï,3¾SøµÊ‰×’eb
¼²‡N¥ïµ7cãÏñÃg_™uaqf4ĞTáE…İ¥Í0ìÕ…V&üAÁı	@XÚì˜Õ>ä¨|/Ü»…Ûí˜§–1Ê1 HCgšğ3,ƒªĞ»;õîg¼Ú”ÿ½~¡.R	è®ow<­&û¬Z;JñîXÛæÓÍhÅØ´¢J'ÄËeµò_À]öÖz…û/ñŠÕñ¦Z¤Rj£åbšÜ^êØ¹YnÈL•9­¿È®QÖò)Sí‘ÇÎ¼\ ~_Î»-µ°«2Á
 Ü>qy½ã£ †Çá±üöPÀ?ÆÊù+
IÙù_)§üÀr@üĞ¨-€QÈŸøÆQ¢Ö@˜ê×éªÕšeÙšÜJÍicBÒ ä]XßLUXÍ›GTˆå×YX‚xBî\ós%~á”·ò<l«1ŸÖ‡~úatWiÜUƒ½ø]AGd#;+KDm^Òˆ™ïÑ::s*¯<3qÌ]IÅ–Á†År¥Ë&T¼»Ì‰C%{ÙÿrPUà~¨<ô>9s¨$ˆ!íÄÕŒû±[××ks‘ÖäŞÈÈ¤ÿ
ë6Sï­ÏÎÉ'ş–ìi,¡‡´HaW”^'­OÒ«–lÿb•Ù…<E#5©r$ÖU€J={°.¹uÉ6Ä^ár?³Pêk7é×ÿJõ¤×O©HÃ}’¸€çqàÌn$6ñ'×"k|àˆ%è%FJ*šD'Õç scbW†Oj	×{‡ì®¿IÌéÍ£"?]V@ë6€E>DvA¬I_W0aÚ1VµŸM«<è¦V¿~ÁªÉlqa8ğE„u—²­<±ùÙ]±„\±-7é8S3 „-¿4(4|üÿz‹Ë/r"İ/ngİ¦{‚Û°@lÑø0ç×]>f´
İ4ğıÒÛX¿¡=5“¶²Åı‰AyMI ãhEÂŞ¤bùHKk+…‘^‡Œ~!JÕR±År-A•Pu}Şkö  ¾°F+ÉÔm1N+k¼ËĞ_4lÂicƒZù6çÂç<6šÉ¦ñìZJ8»Ei<vwû¬ó©èıšõ~Y‚ÿ<Xëô)g«âq˜‚Bˆé^\s6‹šÓØLJW{¤æHOIe©dÍC0é)sú@E4EÉ‹FCÈÒºĞÂÀ7(Jé¯0ˆs³}
…şàÄ]üÔŠTr¡«'°V/Ó=4ª¢]>O-ñ9!0E;„ı!L1P8·©¡6ÆÆ<0E—–%,@NMyÜšÄŸà˜áÒæÑ@´ï”å;1·ÄÉ·¯…ŒAŒîU.©¸³òƒBö!€Æé„şÈ¡¹œ¶äí˜	/kQ‹ç¢¹?E:Ø#! aA·³2yî¸]-Vk‰‹ m+(L]­h1PXn|ÚYş“¡—~b…Óèÿ5Ø¤kşzİSéšMMc‘ Ü ¾9?zkÌ—‘éğİ]lpş‘n®Ñ£ª—ƒ[­š´=•K;ì25'^ˆæ¿šÀóÍ®ã9§;ğ¡~=ø±ÖP²”®ÆÂFÄÏ©Ÿ—Mˆ@)›Ÿ:´±C)ÖØ…pK¤¡ğ…_aZÏŞÿIî¸%H;ø
iaXôıª”Ä¯Æö!›ÕJÅGüßRÂW%³¼|‰©MÎ"n"@ê¬¬9`×@ÄMà×ML®ZÚÉÿE:As)SÇÂcõVuvşjíıëLÄÕ½!½ø…OŒÒùôŒ¹Æ3BĞd[ú¥‹ŸI÷¡WHwg¹Ö8ÑÇ»TTærC˜OVEÀíÀFÜ;gr$»;¢îÈERnˆÏN]Q¥~lˆƒNæ0Ä ô?ZûC€J"ÔÄ8qû×´™ ´gŠÒæáŒío(¡’x xéqÃ‹“OŞkkÛ	ÚÚbá3Ö˜¶1}[œ°µ‚¤³O­’	Ÿ^ó<*"r×ÄdZ‡¢o >ª«ZÆÏx4-¯Şâ¿„R¯Üş}ñÁ'ƒ>íJŠlLçíBê’Óğæ«ºHI±ÒğØCoJ=Ğ·ÁÓWL+ Ğß4ö~äk'g‰ºÒı6+Õ]¤HvÙ­×Û©Á>?ó"XCp>ü…@+ÅNcGµ`Õ˜hô’6çËÎêŸâ4¶Ş ÚbÈçºÉ‰Qïk¨ê´/q¿nØ+N›±muãÌÖáR‡	¯š—y*åPÕÛš|R¡õHwQ¼Ëuf ×ùÆŞX š±³<Ó7®V4í÷ø-sUî"44†Óê‚ÊÅRìÀ¬[ûèñÛûº~*ïñõŠ3QÌòçĞ"e|ÍEfRßÁ—ç€÷¬oê$úÕM$Xê#”‰â^¢9â:à$©yw^Æhktv¿¸Ÿ#<	 Iªç»šÔİÙ)w)C¶š€$gÙóœ^ùğšY¼òzõ”*Wx#çùÕ)©W6Åó{†6¨Q;¯ıÂÎ9»×ú–ÜJú¼®á…Ü–+ä_âƒWÓJX.U‘]Àn‘³…âç\[Û&Ë6ŠÒÏ¶Öø§e÷ÔÄÆ<“*±%úW_&ìÖÌg=ñ€m™‚LMä½/†ôEíïsí•^şg÷©40ˆ0Ñnkörã!ÌPböò ;¤
y¶®øbàß6Ôä&…È®ÁpáfÔ1Ö3§O×ñø¶ïUÖÏ6Òö¯à>ş¿7ÈL×ò)¾VÛ -˜–¶^‰;Ï7æ„ø+ÈöI_<Jµ†¶£•‡éo“‘$‹Øà·6‰¯¯nãÙ°Á|ÊÙ›^‹›‡âå¬»‡Ú+´Â~˜»\5é–>ËŒró¢ŸÖ8ôä5-÷×˜ÀÇÕØ÷›‘¯ÆG^>´Pˆ4L
%m“¿0dÕ]Æq#y¶Bªë*yr·Çñ6¤¿“÷i—ì™åî!a.\I—JÅHÙÂWk^¤õ<:ÊA´ùÿk~lÙG8l]È­E UqÉtúAêÏü–Ñ¤JFá°Ğ-Ê™ôŒ‚<:Ø®ÆĞÊOÄĞ¯åM€©îoh~Ÿ¯ær»ÎtXëò­÷ûfpütSÚªÇ’7÷‘D½…>B@aÉ¥Ê©œRÉZ³ª.|îæ}iòô–R˜ôHÌ¡¯ILë®-lI{+LË=4y0ÍsY¤F•ŸÓ,ôÜk~­>%aC¤ğ;•_U’â¾¤wÕıçAÚ2½Uk\¥å@ûñ‡@ê/’oäÕÛkœ•İ›^(8ÚÉÏÉ™D~ä7 Ş×ÛÆ»|¤:òºŞ*ô|‹4ÍFát9/§ç$‚ÊO½*Õãx¾êF&³è%§èQÉÑ°:ü<IŞ¡Ç1c?®Æ#¿¨y	¿j±½°ùï²9Ğµ€şY^(IšèïİœİSÔoâÖÿ²ï'¨âQ´œ<…mø×É‰ŒÒ—ÈÚåŒU(ó1úâjî‘„ lÄggªÁ¤]&xWîD¶bÈT…’¶˜¿
öƒ8=h § <Š•	ìƒ‚Ëg‡I’áVÉ[G‰gŒ‚i’ÏbÉÛ½Ó#\_ÀŞ™³Wü§ÙsN>OÿÊÜ¸B¤–Ğ5
á®şøÊz˜'cÂ‰ZÌğ©ïHªàÂÖKŒFUª&¡b¦Wd¸9€Hş¤sÄ£0·_mÓø d6nağ«fx—w¼<sµßlçº8 óc†Ø™Ûí„œÆ¼F²mšQIÅé=	D‚>|±Ûş7ÚìÖí¼5
H.)¼zKêÁaÓÇïšóÁŸÎÁóGÕãwÃ±Kôˆ6³}êáØßBS«>8«…›¼Ö0`İJûA¶~£ĞR“ÀyJ™M‹é„?sÓN=wğ%[Àu³©Ú<—`xzxĞ{XóÑÎ:]Ê'°©º¡­5óëœÑ{*xƒVi¬şl|¢çMÆvÛcì¦pÌïîç–ıØ¼i^ƒLŸÕ$÷·¬sªr[×CZ²]€¦ˆ‰SJaPoxŠ	gÄGŒ5ƒ)5;ÁQ9³fz úMÖ3V&; ±s)ÑÁik‚†‘ªN9şex¾´™R´Â¾Î´Æg?ŞÑ6 ò
åbæÚş‘”¸ÄÇ„‹¾Q¦iŠeu^Öë£é–Úa[kÜwà Øïò¥•ÆpE n‡®Ãÿº£øÙïëº·¨<­_&O,²xNÌV‚¼cf€tÄ(mâ`aHnxŠ«¤~qc’õúàv[d\©v#»ƒ´ÄŒúŒ@aµÀ ^^–Ú:T;Èn¸“v^¸¹õ³TH5‚+òÔïçßCT˜pôyœRê#Ã(™ç=±Ş;cøaÅAûÑ! –$t"™;…Éğ;W3 ,0Z]€>!^‡ËeVF±J<ÒåŠ[Úm»ÂÎWPD_
Gåò€ùvwPbE’¬øìøÈm¼İÃCN¦Êìê|@2	”¢2Ú[ç|gŒh}¢U›Î;ã:ˆí2›.ÄPÉ„¹µNŠúd®$ ¢P)êG}óïÿ#mfÆ·;QüğO¦‡áb+µvì˜ä°n^z&çoÜk;ã¸aäY0Ş_! }QTŞ4÷ı: ‰6úûÍÃ'Éì"2¡)Òğ‰z? Š¨ã	ş›{›Ã«¤z´ı×vf·.4¶ÎÑ]Í‚÷F§iÜş0]ƒŸ•ÕÌÙKÄéÌ®ÔÉ92wm(Íd ”:og”´²ÖDæ5ÏÏ±hÈDsö™àÁ×YoÕäÂS—Óî‡?µ~~,y©h8çãÿ&É_fç4=á§b;ÊgT}hÇC±4¨‚@ëb8jÅrª%‘SÛEïÑÅ€¡)íætƒ‹)¥hãİ]†âÎUrazã¸ 
–‚]6
#Áz!#ÂÌa`~7	t±áœÁÓ#ä AAç¯p†m^ëªœğV\„›M¯ÂWõĞ#ıIÛ`o:‘u4Ç‰ïL¶/SÓ‰#V°#˜&HRÇÔ†{ÃÀ3Åa¯&È+…ie“Îÿ3–)˜4<—•UÎWœKö9ê±Sˆš†Jedê.äM³’†„eø:(‘Õ˜}ı¦WªÄã>j#â¤ÕÊzğóŞ¸¿BÀ7—ÇæÑ¤—ì1½A%AÕªú¥‡@ŠpâcïD±…ˆ*3„htqÛÕïID}J„¦“]o;1.=)“tX9½øÃ3G*6lL}¡}0¤Híˆ Ø!¯£CÚÉ?èh¶ë¦¤‰C¥¬:6‚£|ì©8ü®…õÍ¿!m”nfo­'¿!­uÊù	‘@Ò«TkæÆq^ˆş¥ø¨ÚRã;ªğ­Õ?ìÍ×v(qN¬å9k»{>¸{W¶Åè¥)/Eu·ä^*èÔ=Ö’\9€cU!Ç(ß–,Á0êu°›7èIÇÚ¸¤@'•åËÂÄ§àÓWİ"“äÍ¥à6hq2Îz°sb­ûyX5–hX(¾ì±>Ã…åì¿L/kF`%Ÿì†„Eñ·ÙlŸ0L“ì¹O4:tç"rÚ¥øI¸uoû“ÉZÀ—æ4ué¦‘Œ*Öe;ßkâsM>ˆuİûZbù~ôX™®#£áÁ\ÜãÇöSn¶ÂZı“
fÒ)® Í!>Ğ Ñ6*â«-öÒuZâ×·}W÷2ëE£T»ó~4€ÁZè#°È÷•~âUê–S3¶ L< •¬ŒŠ%vk+ı~˜d¢4ôÙ3ç¬ §­ª%Lz6êÍv_'ŠÀ™(y’,dtDÒ
è-CäE¸ùb>XÎ@0Ã\#D´ìĞ)VRçĞXàf§#¾ØH#Âÿµ Ÿ\ ÚˆÍÇWF«A‡á¶Ôe ”kĞÖ¾’<Êè¬»IıIàÃŸ(ŞÛ5á%ÆÓ|ikÙ–ˆÇ#İb_3Í°\ ~Öôı< ^o(Ğ4öÀ£S˜°	B4_c.À3t|<z ¡\ºhäœ(¤ËS‡?Å˜
±½çİÓŒø¢>w´Á¤ò9¯ú®$ãÄÚ¤ahmâw›~	ÑŠÉ4ı‚	-ÌˆöàK¾RŸ»ù•”í•ó—ï³\óú2_g‘ÌğëQ•ßJ%uú’%™ĞXåv“)¾,ËŸ­Ò~÷ y.E6‰ñØóìG°íXÑ¬T3‡â`–Jâ€œâSÎn)B7­™…Ø¬µ¸„W]–òj0œ·Ï÷ù9¯¢‡ EUCÊçàÚ¹cƒüÕô[®Åøxìá
‰EGPá¿pœ¡Âô:à# Í·l-ÛËşé=Ô|ÅJ6o;‘c¸%…í)¶ÂÉá«}-©Cv1;ñ*Æ»5R\xÔÇqÔòf×•°×¨9ä½Ù.¨õ¸(D!­ÓFOyàs=Fæßşù}ƒ›Ùt¾3M4•ÄÉŸÇU°Cİ—fgL iÖO•ä[äĞÉ'ôÎ" ôìFûo Ó-$ù«LØ½ƒ—fÀñ•ä§Ëä°9!I¼ÀÕ•:›QJ[fƒ‚²z€<LJ^7½Ö1¼ŞÉ•¬'¬1œ•d/úŞ¬zÆ 5Ø[œÁ88yWß¶ÉNĞq×UÇK“³&‹9§êºg6a_Pƒ‘™ï ±j¹Õw6Rÿƒ™óTİ‰YÿÍtÒ}­äĞ‹M6/õ…ÙÍ=ıÈ!¤i‰!ôê)×0ucÖÉ*€ ëîÈ óçEôn~MJägëq«T‹|,dHl”µ`ö¿‘PÃ–ğ³›.¯0aè^ïôÏ2ÓqãOV­ÜÎ¿Ìõşwƒìaü%ò²­c0ìYÂ©%^–±pŒËnzN9måªO¬—¬Çe}üMS1wkg,l×z‹“9wÆ¶æXò'-PÅA{!"¼ÿM˜‚Ò9úŸ/-¹¡eê›6F|ñ93ÛßsGï$t…ûèø+‹·úËº­Ã„„o'“`"|ÃEØªio;â¹—.ĞJ+£$Í‚ó_:şd—7±²À
ÕXqŒPµ¿·µ†êş×>w_W•Üù˜ƒD¤¼SŸÛ-ëw j“V…ñÉ¢B
»&dtİû`	ØÛ÷¬ƒ¦õÇ)ÌÃ­Xšá†¬~¯ïn]È±A¢€®ù-8ïÈswP›|(Š
ó‚ AÔ-ósl‡u¢r”nôšÙù€.»îl¥
¥ ‘”Ğ;÷TdÔÃª‘ÉeŒ boš‘I‘:šÿ¿ç¿œ.*ÅLÉ4V­v ×ÙSñÈÿøë(ß$Ã‰IÎ ÿºF<Ğóh)ÍïïM:–‰à+#O‹š °:ëìç\›
õ¢<S[oü¯Ù_OhŞL¢¬‰pìÿ#I¯ú„ÊÉšt5"©œÅÉÈ¨|Bd¼29y9;àjıäÃ4¸«¹ÅÃº†üˆËÕIB¾-4CGªİ¤"í&Fu¬ş—î#Œø>ª`WmÚ‰
©ÇÂ¬š:ß’“íÑ[âjèÄÊs`ò„„OSºvO
±ŸsSéİÇİ,6EY’$ÒEÇmIn¼}g«ÁƒDTû.]M¹j¸ÍÄš…tní»9‡ê  
)ê6¯_UM1üë¨¬¡Ç29¼Ã$ÇÈeZI0ñ,î²æoÍ‡2|·ï´f„}8à'ˆ¦+S´–:ÛHa·÷+€öE§ª^—¢
ñà‹Ë%w ØI˜Ş%Îƒemü7öîJS%;ËJ‡XAİ¦Nt*¥"ÆB^wÖ¡Ù¿ø§ßqã¡ ³]©_Å7w—éDTT²!Üş!2¾o˜[ò¼¯`_¸ÿ€[:
{†ğòE”§ÙÏš%Í¾á4‘œ}Ó0ç1vÛB‡á?Fv¤HÎÑ{¿ã±ˆx¬‡¥Æö°­âdÂ±Õ˜’…{,z.Tõ2œ X`şl}.6ÉËÿGñ8të­JéÀ
Ÿh¿¿%.ïMÂA e\Ë¥ÀÊü5xQ7ûÿí~Eâ §*åtè·4Í–Ï|Şôæ~+1™€tu ºK[ÒF9sXÚØ_¨Gv(ráÍã¿R1¤¨cÏõÉ½W~†æï‰{Ãu-!Fğš¶{r»&#·"6\Qõ]…W,Avz‘#E(øô4ù©KÛÃZ×µN3°-˜àOî|ú ò…ÕãnJÂ?,Îï‹=y3Ã<®ee‘}> õ+rşƒ!¶M‡/.¾˜¬(iy£ÆÙs<Ä9Û˜øj3&¡ÔÉ”Œ.7©¢3{½e=ï™ôåªpİ©nùæÖ${†¶Í#Æ¬œ€İÛ¶y›"áOFUkó®VŠôÓ$:ÜRËAøL÷ù¨]»#³ÕµJœVcúšIêÚ’\¢ªªDSß'%·eŞ•97·Z'1®Ö¶iÙ«LW¸ì¢†BA'¬h¯o—|«ğÁ©éÓØäQÆl"Oª²÷ôP¿œÅoñ«Æ¶Òæ\˜T:27jZá˜Ù’$é]äz,™°ÓÆófX­b'./#I_Îuê|z¸Õ®ï‰[LK†%‰7•ôZœMß|%İ…÷ÃğËß;k=…:)óÌ—6OI¬WÄ7!¾RLÑ˜aÕÔå¿Ä‚eTŒ£VØ•Ç	¿÷¬ïHÜ"ÅØİUúé¥ıPFöİxs8»æ¸·#¥"îå]l‚îçz/=¸ÿÙ®³·ƒ‰èœ%»Ù—8Ì«øûlyGBaJ‚Z}ÙÍïj©éCv–3|v?î}‘î!~/E£`·O>8o@çQÕpÄ€YÄ"j¹•&0Ãz0Ëø;e;ì{™„–Cà˜.ê^ä³Œp^îˆÇÊ¯JKFz$Ú¿KŸRÔeƒ¯»ŒˆÈ+=}%‡áLÛ!h˜P„]ëŒš
ÉÌW«óé¯€æS)œíY¨ŠÜVW{à=fş	ví‘˜dV+XĞ®ƒ ƒ›²nRZÊŒ±Šf"şT}rä[—âÑ|fJ€¿,c®¶ÙzI¥ZıÆ¯ı»Kwa ƒNöÆÁNˆ–ñ†(znœÓ ª<)’ôZzü\²­" <ÀéRéŸˆÒngôezãW†O:Œë$w_¨Î$×®Yu{oUOF‘VjìS+iÍìZNg˜ît0¥Å4ó„zP ÒËã#u½:¦Ö˜Ëÿgqca?ÿËÛ¿=>ÏL0BÅgı©$³k&áaeÔ&,"rY¦äŸ^5ícĞöR¡mx+ºK~”ØqT÷}ØWÑ(õ|öQh–Îh©`¬ÁöI»¯ÇŒ:àUsiO¼®
%x¹·úÂt[EŒ˜T›ñ&î÷X Wûå­×0|£ÈÄdÔs^·„«ÏÅ‚ãkDJÑŠ§ÔìD~0á\ÎµFÃñªß‚§Š€=À†K´HÀYk j·ãfH +.Ÿ\à…Ñ"+âóNDyWl­.ÿ´!ÆÒª•õäh_ï§:Yì²Ò¤†#îKñ U9½ñ×úÜ«Ù«ñš¢ù±GRjÙŠA½®×\ÿK®§J²õ®‡ÙÚæ)iâÖÑCÏ’Ë+Ÿ\¾³/A0‰£Ş†nö·_l)ŒÁjí6Óƒğ`¬xê´‹ˆaò9ÉíTÚqQ;ÕR&QC°5œ¦ôü\D°Fû$Ì9ş$ôèŠÍ„¥uŞğëËœöDJ’S„váå#ÂÁ“)`±¦§Ïû™K\ã¨¼Xè“êDÍ£„‹=a9v¼c' }‹ÿeŠ!»WíÑÑ×U~Ï0kç
|×k-ñ ›€%•©f‘A^õr4
ÂaÉ<Œv*4µ[Ë4ò¯\ôÈzö£î¢ûÏ18ÈZG.ƒ¾È·¸ºx6 `øh"Ô“TfçÏ:ˆGèr aödŸ?6Ç*€£|X³½İüaÆçR2Ù.áPo[^Îe6hL 7|€wÔÔÅ”õ/ÕM›‘êØÚ¯¬‚¤¥]É•†1şn<|Ü‹˜$z’czL:Éğßtbƒ?šŠhhX‹¼”'S}Š¬šòƒ¸ApùÂ"K 4¯¸ı½D	÷_dbMşŸo
ÆÙGüÎrŞÏ™êµfüiQY|ÜHTG¯’æÏx¥¡ä¶…ùÖóèÛL$±‘nÓß‚Àmş~‡üÓ5zTÌ.¯vÚ3 ™@oÙv ƒÑ«¡ú0×ªØZó·’½T=ñÄ2~›sB¢Úâ¼öD°Ë‡™şéWçªíPL©¿íç†k¾3lÏ÷ñ¯øAß—ÒÒ×Ï|vøsŞ)JãÜĞãX‡İ±¨«çÈ÷„U¡úUê“Ã«ešU×D–‰øYûk´1GVÇÚ0ÿït Fé•½âø#aàXmøäuV¾ìæú>.} <ûË–l Ï§³]{Ûk¹„>?çï#”óàŸLU:o©0ÛçÖå&š®fˆç>	¸­à©G«1«²(†Š\ïØœ—­
"û¾C:¯btpº“3!~º<´ƒ×ê ó`|³Zê«‰0«)Ã{§,İ}gŠøµâ#›ÿk5`ôï´ş#‰4bœOŒ•,÷À_ı§gâ>t˜5¾}õÁKÕ¦¨İ'®l2]«%=sAQğõŞ0»dj?°!r¶ §ÃÂƒãÂ‘ ´æ®af©µİûmïf`M¡Ëep¯­±ƒ&áPâÀÁŒxQ^Ù~	«;¦8õƒS‰ESX™×Ïûîl¯4˜´¶0T:xŞŸXÇş Ôú|k9N„l8àé&X>
Œu¬ª^—X×X¡,QîaçW¹‚Eß­r)áiˆ:°YcWx*Ô'ÿ¨«h¯t´İ xzÅ˜Ós7]2£†îş0Ş²ËÊ¥?mù0ªd.¥G“ìàóvØ¿—Çú"“<’_ş[ÀÕ¯Åör„s¨T¯~ÜuI!¿ÖØv"iõ³AÎœ¢V.zJo3`ˆ0¾ÁÈÃĞD™{{üoäòÔHê r
'gßÀeŠ5WŞc€!yLóOã°Ì“uÇïe¾).KkB$à@,Zşaåb½6¢¢ß
¹‰¹&Ht ·UP(ê¿Ù’˜üS8EåÅŸ€é5µÊó7åÃÊ7×Q©ÍpéuÄu¬ì×Ùç ôèCÍá	=ˆŒ}“ßŸ0}|¯ú ğ¬pñİjËìÂ.)â; „`vÓFĞ÷) ¢X±|Ø·5?N²œ‘èfŠFÀ‰Ù°¹ 	Hà¿éU”ø¨à¿pQäş&/Åu’Ï.#/W6³Â‡q>OWér:rØm;­¬®õU•©®:_­[ùÑùlˆìaè§"úˆ¡?â­Ë&2L‚P]‡uæmÊî_¡}Ö+†•iY?îİñÂø¨m`úy­¬âŸÕu8­®’£ëEƒ@İØNX<zRâJÀ*¥E¥uü¨c‚{,Q¬u${ˆJ_È+©Åoœñ‘Æ •)fá‰;€¨|üğ0–Ò4ªŒ;¬İ9z³-ƒï[7kœããšMI](kÂTv…xš.E¨h‚*eùEçš¾›É›t¸îòÜsôğâYiÀİ¢à­^s‰bşiÒ³·4à£U©»=„œy ²çÄ{½vˆ:'DßˆvMñ˜ÕÎÎIå*è©.jüöç—‰îº
avÀîº'PgvÄ
bÏ@°ÕGÕ³z.„/:~EŠ0‡®¬S¯è÷kËodÓ^Œ]jyaY©GåÆ‹›²FƒvĞÆéN½q˜)§á•½#qíáü{ö¯ØÑéĞãü`D"4ÃN8ÌS2ß…ë6O:iÖÓ^ĞÉ0ÔÜ«üÍT `Z¹vLø¶l'æ8u•ÌN,gíÄ½94W Æ8/&oŸkËö½çÌ%ãØŒÆ%éØâ[ıºPôó‡‹Óf¸Œ©P6yóß¡æè>a²8·S_\³ƒwî{.4?RÏa1¦¯ô{Ğ—½R»_Öy^hd=XOïÙMuM+¥œU6Á&Z;üÓt!K‰8K<º}‚½“ÛÎ”IE–4ÿC±#ÊYë8!Õİj'Ô^êê¬”ˆ€#VÙu¾MÛYXğŠwƒ³†œ‚äQÈºµ+:(?4ŞÇMbø—iL49Õ;Û”ß}¦†…“då&i›¬(tášØ›¸[µ¥KXÖŠåCÖA—îl_š}-êçÏ'Ş·f6-*? 5] )\ë0Ôí&‹¶$L@÷x½=š¼ÅíğAÆjÔÕ„Ã†Û¤„ÑTF‚qÊÛ&2Ô¹}ÛŸmZno	Ö/˜[à#7d.„´ö/ìûì”TnÚZÊˆ|#ñ1!ÍûÉ†0 p½s6Ã¸×l»¨hü”õ×r$I­ÀÉÿ«/q¹nQ.¹×Cİà ‘9Äâ+(ZŞpÖÇ‘qlvú’LİY6ğoD-,³&bËÚùÚÆ57ëy²ìCZ
Ëx$ñz;,˜ ÆÀcÄîÅèº\kU8å¦F;ĞZ†Y©õ¼Ùz/K¨ô9ÊYfSäyg·qGÔ¤ÃtûB}b^Î¶•H*‘X;IÕ·3†úäT¶Oºÿ8†¦B9ŒpyMHœ 3¶tT	¾×«ùáXØ¢Òc)fD•3$ £b¿¥±ãG:#
ÂC²ßæqczìx„î®­c\¸ŸT>´ŠÍ6'£óoœ§~:ê¶è]”´¥CÂCTŞw
F4òÆH½®3Æ°ò…R§¬/$öÔn”o7Oàı
¨Ö	#œ…H¥Ä}dR›EÎ1#Ûs3‘«=¦
­/xõˆ9{ \¬<H²]gan—V«ÌŠ	lÇÂ¾9j±c)v»Çşi>ÉSdõO¦&Øv«ëÉ9ãˆIF¿­T¯"PIJ–{â…`B±+Ëã‰cQXÜúYÄ"Y%½ÓeĞz3^…>#±™TkÈÔ«ƒ.İâ,ãòÒ*ÇÜs9F&Şå3	ªbş»t,ïKawLáûôTøv²dvk×é‹×bÜfšmÑ+9ÄeRoÅštş©àzsî/¿ƒÂ#Şk¸×¡ı~vüï²áîÑÄ#dÀÙ–z®,|n=æûµÌâø
´=íÂƒñ‘ˆô¾mŸ#òöWEu??ÎZ¯g†'oùáæñë“Mşqçs€yiÔƒßu½õoÍ}ÔĞ(nU°âçybAß´úˆmúæ`Ü­QÂû	,ˆè-ô”T(ºÏFÁ¬ş­¾73” À,øˆd·idb k/O¿Ç‚šÂ•&°T”©€-¨«tş?Bú7Ål•bV…[œwágÊ˜‡4;tL¼\ThL.ƒì[¬ä*šüæÖƒ]3òÎøC„´°ÖÅ¦#áµ²¹çÆÙĞv¶Å#4ºÚ"6˜è¨œMß´’ó-àˆ+)
øYº§ŠàôB7ûÅ©GTuú¸Ô¶æ*–s¼"ŒI0ã9çNI˜îŞaPAÄxv…´õRÎ²¤âeqyíH	üÔ†ÍmPåŒy‰«3	Q`rRTÕÕsî¥ÀrAk5và±àpçH¦A[¨Ç#•H{póÈl8&uò±á6ä¶ÿ@ùXU>^9ÊdÒguöÄ“bV¼M®ª¶ç|«HKßxD‡¹4?I
U€ä¦ §	(ªiNGßÜ !ú¼wU‹\‡ ,/&¤.¼‚ZÛNwÔ°‘çÔ{Í«eWÌ<>¢£}ÆÖv´ûJÛ$'V6¡@2cˆşÕ ÜbÌaÂˆ£ùŠ8¢¨`Yç]bŒ÷Æ›j¾•[zßØÅ¼«²–öN7¹Dã8‰ºy‰Úz°pÊÈ[\´Dd„C)…˜6/G*&¶Xjº=où®:RÂí}`>áLŸ¬•zf{2ôtDvÑ"îÁ'©zŠ¹vP(	Üá#ã…U·–Ç·)Oj¹P2äq.ÈdÅËè®À0·Ÿ|mªZ¶X|²èƒÖÑ~ÁĞI'aB›$án¬«¸
ÆèìËoAQ¨¬{hÒNÆæĞ¼wsóŠèÊÆô84Ü·®²€'ÎüÆ·©™1›ƒ©4›ğê—<Ú–DÌéù”b;š`q	ÄêO²xèSª§j³ïxıô¿ñÉ¤…m0cV;bÁ£>ĞG7S—¡}’¬T‹ ã}²Ú~û0•&Ë²±?u':´~VÉÇªò`z4ğ ŸÃ0•ÂyjŠvWÏpDH÷VÚ,7}éèøpG^ÛsdŠéX6ıê“OØ›(Lú0‰Òh¶gá¿lŒ_ù:Èo“;£NNá{ş¢¡ÃŸÄæR·Ì›´c+Ÿ([•Õ)K3ıšíö¿ÎV¥úÙ 
#Ó?Eo´$@™šşéØ„2ÈíQC¼w~l ÿvWi¾Äb™ï’p‚2”ä0Ø¤bµQt1éß6¾›§$+ùıèßĞPv3XSòm—NĞÄ.zÄˆœòŞ¹.”u…£iš˜2Èâ|M'/ÓQ¦»ò-^Tuùz•¸¼z×î Tíyf Æ‚Wae÷„¸5LU]b‹Æ1ËaŒõ—A)S1DPâ@}qÎ&YI–&}³îPs4ü6'é†ÊoGŸ‚C´Üne×´éıjhÁõRÿÉñïEçzC‚¼Ã¤ï3ŞYP’!äQÅ8ĞåFÿônõóÕÒõ ºCÛV¥=¤’h<…‹ïG>‹µs+uè$¨jÑÄ‰÷t@€³öŸ»¡€±²	¢	¿;rU^(`8n?ìÂ_Í¬¹Öábæ}ıf£|‚#¾G…A‡5¯Ì³sç(¤8$8øVì¿ŸÌ*İBæ„å…#…ï š</O‚wÉS«7FÂ¹é¬ö?Qnİ…‰RJ+ıÆsZ>‚FË÷<¦Æ~“şd&ài§¥¸™¹¯ÀéäzÇÌº´VZ°8‹Š§İİIQ=±ÿ C#[Ê>¯<OØk¡t,A?Ç—ÃßÇm·ë €“Ôù€®^jˆ«…ñ¦›•}5#OftòS±“‘ï@0Ÿ–O†ŒJ@6„'Æ‰)µÄÛU€°æ‚>?v½B_¯‰[^³v¦p°Ğ¹O¡ò$vx…×gò²¯Géª½W~Ö6£òÁZ~Lx­æ]­ê0Ïp1¨lìÄ­X¥‹§‰É6fëÕ.r˜ÒŞı	„çb‡Y!öğ8[oü°v¯ÀŠnˆÅWíÜB-Å}ÇøcğÀ2=¹’å*³®#fü“¶ Os=®(4€œ Ÿexue]Ê¯¹ÈğrM:á³Ih—Ù9±&T¯fo”/o±Š©±ÔMÛæäXS>íQ–uYvÁoq„¥p)èøÜªğŠ£¿ïŠeeõ)ıÕÓÍb¾!=Æ b_Ù;syÿ^Ça^ßèbOY9k¨¨šğ¯êÇ
¢h±”fw(áaî¨2vy/«B ÿçTşYK5<šJ])›å¢3zYæÑ¡k¶z¥Nw“Ã™±Ñ—æìHIDSøhäxk>•Õ.©
™« ÏÌ¾eïæxgË ¥­FúÚ(ƒI×ôêÈÉ…8ÎVXGgT’ff¤ëjˆRN•3«Í¥À‹>P‘ÃO~XìÄËVŠ45%=ììD¦ø]¾7\!ZËëä 9ÿèbÂ^*œ:fßÅÇ;ÀI	Ì1IÃïtBøËß¹H
à!Wz†/*mrxå¾¶J	GÒRÿ(­õß„äC™ÇÙEÏ)Mñ#À³úş{ì¦Ve%gìÄÂÚõ@mŒÔàÃ îÛ‰Ò	Á9CEkå
›ş5¿às·Ë‡öJ¯‹(t#ŠC„Â	-p[÷q@TÿÀ“çË/düY³´'sÆOÛ-ÒÖÛ‡¥Ùİ¢ôzr_®ê×R‡ä6ëIÈ>,`»Ğ®¸Bãu<IñÅÆF–óŒÊEŒ‡« oLDù±¾QÎm²CuV0ŞG"ñûğ‹3ümå»„ùø°»ûçx-PDÃTËØnãä?šsR®#:gQšXÈä¹º»°jy[±K”¢İÛn£Š»aß7É#Héyã¢îF»ujçl ‰Ü{¯Z’Û7\ù„ˆ¼ÿÚÆéÙ«i ”z§*WÏµ/iww…Ç5ì(HšÿÓ¤è‰ÛæFJMqhÅĞú’Tª ¸EÅ’¹qó½\_h6•ç"a¾9ÃLÉÑïŸ09¨ëO¬öÏ0-ÆRíx¸‰XO•¨©›¢² tĞ{ÂaŞ³SˆíÒB*½ãrÛÛJ]Ñ0?Í«szWhjåŞÈ>"èMFFV÷Qµõ½¥@’BÑf’flâ\¾ş9\ [˜n>@}•\À.p"]˜\„Zø‹\f¬ÿo4š5’´	ÓQi_iK¸úÅøšâ°gÌUŸØ~Lú”8L KÊFÅB×®¨Äï-e¬U/T `Ñ9«a±Oæ½H -Wøµ€IdğÆƒÂ`Ëu½!Ï‹ûf›ğN·¶bH^Æp¬,ÎPÅ
 zÑ+ÑŸ¾Ø©M-¸£iø:Pd3"³1·¨#Rè»¸ÄRc C+iŠÙ]íëŒ‡6p×®˜„ 4&=*¢Yyı›$’*LïLL`ZCTÒØXÅhävŸ¶N5#ùP±.&f|YWcª®Ø(OØ¨½  <tğÿÖôÁM…ëÊºäyç¿y£×,“‡ìõ¥NSMë_‰«	ø«”ê1w}oŸÛ‹pµ™5ÜH!«n‰ÕüCSñ0óÀúÕCjof¸ }ï»ÿëñ7saæ´Œ½TOş$Æx=[Ê…ÒK+£/h|ïº[ÁQñjC”ô4ve¢Ø­)k¯­°¶B™TTÂGG˜ù1_ÊoÍ}çŸR®ä7hF®X“q*Ö<ÒæF°ÒüN²®PîğôêEÊøªÉ	µ0ŸçcøÔIxê|9ü@ÏŒ4›H¹–Á®§T¼ZÎ¸ÿAíŠ¶ AZåŸá.-SÌ<w@—¬jÑ9Î—(eÆÿXà‰ÿ­¤ XºO|÷—<T‹x~b[,Ø(sĞ‡°(GŒT??Õò3±Ó…‰è^®Nl³ ›÷½¤–EŸ*;÷#u´Ø"ÿe¶Ìa&1‰!–Ç×:sˆ!öÈã@,Cne`è™¥Ş;„Qç²Õ°›yÏ†!“‚•1§=·=]ƒÉÊ4Hi÷Šê9z	º)Óµã¶åñ42²ø©IøaÕ3LX ¢ï¬¸’şK¦VªË>-sè‘¸ŸÉ«ù±e0ï15uG¿#İj„Àb¥ô†p+‚csı3FŞŒÑ0Ùg:&ŸËdµO—±¹ÊdWØß+ÏØgQ{`Ï–ÇoóN®jqûØp±ÚırSTá—o«ÅwFZìiWEÉD‹DRÓÇ¥ĞF3ı6Ç—2Õé6©k?Y¡ˆ©å}l«ÎìZu	7ër*óDr<ÚvgñùßØÕ¢Túû…åîOfØ
ò³à!Øm›~·>PB’)×ÕğéÏ¦Ë´¶¬RLigoé™ÔMÍ
„wçzÖ1h€àL"V‘»‚T4n‡=×ªø³Ø±u!&ÂjÄhb?',45m÷¥7ş¥<àÁjö[R½†^©>
¸Ù…íè¥à7¯™­œ¤‘+@ãb¡ë­p?kŠ„ò€Îé¹K:ŠWkVhrJÌw=‰Æùy¶;Nô;¾ù.g„<E†­&C2ı‡@ğşŒ±„&Dé^a¸Àr´•¥#{¹­ò£ƒçéXO¥3Ê‡SH]|XÅ~®Ğ:”ã™Ïû®Å51¹›…7X4ËâÃT^—1.¯YßtÙF”g‘Ùë‘›ÿA·iI‚ %x‹³yTÕ¨ÀHÏvßŒJµµøùM¬Ì2ë?b8TyŸ¹sLÎmJâi˜íı‹-Œ%ş·Q¹æH!¡z&D7Í 8”wNT€ÙôªnÖÇRiAuˆgçyàJ¿Zn¯cÿy„«Ø+Œ4åõeñú¦d·‘ú>ƒL kˆ"ÙİÕxÇPí°€À$jóÈ'ú#Tleò—'<„<©')şŸ<¦Úò¦pa{—£ƒ!Í;ôW% !XíUs<æTÄço}ßyòg±íqQjŞ~‰oîv‰¦›Ô¥A|YÈì¢ì»„Yİøæ-h§úH!ƒ3ío½J¢óxìd5,i:D#àQ¥^‚eJlÒ¼Áøëó¥3%ò‹Çz¬mÁÕXÜ7gëÂš{9Ï¶…J3{>FhÉ¬e¢ÅL&ûu
i¯çBé ~+êäz`r]R¡ºpB–Æ¬zIce«‰½iºù«ÓE×oGxLÿK}Œ„ŠR÷¯«à±a:«9%¹³G¡÷ZÚÏù>ƒ…càÅlxD^yÂÈÙF‘Æáö6äÅlYJ6†pàp±Øš-}ê½†—xP¢D^DW	¦æŸ¾Ş»ô˜Ú‡ıVR06Ô¯©"	2|ĞŞmàD´ERH6ıĞŸìíeóÎRPÕd» 9ı×‚±'˜kZáÑ££,òQ|ëOÒÁÇƒ3E\Ô&²ˆ5~8ª³ûÒçiÓÏa;Ubo€k-ÓNÛ“nØp"ÄŸë*U".xŸ“2¿7¶‘Å
ÛK©¡¿‡¤¸ÜŒÅ+mR¿ŒEÔZP”- l³Ş$£'»y,Ş‡Ù7ÔØÖ ê BÈºBÿóÛ*ÍMÏ¸~
`¬õÒp!eYæ›aÆ0ĞõNÔƒ²è»½²]ä&-N€Íˆ^ğ«ô¾Ün9œäÆÂÈ> ºçÄ:ãÕKé,¾±äsøİş¸â¤2]Ú˜„Ê®E°IP	z(ÿbŒÆ;,<JñYÕ>å\iìl„©ÚBòHúÈ’!^zÚå%ôx¹ô#ìNRÈ:b10zÚUÃÑæªÚ«¹	ã‘•y—š/?s=ÅM”NlÎˆ¯-·4yËc2ú.'¯a±1Aë9:íeş ;¹dÒT¹ØœÄà­Ól/¶ß>‹Y<”>·µŸì[¼TC: Úë¢}îdIÁS•½Y0d¼ãÙÇJø:`¨àØè²0ïğ7¶agyæC§—ìåe6Ô®¿½›ìjIòè¦òdÑXÊQÊºÑçÆò¾‘ú&nA?´È&2e\ˆÚâ.jÎb~ãTX’j]C•†­ÈaJ‘×0šLTv8ş¿®_Û/kœÁW	VH]Â¡“”ß)*Šùğ°cæ˜84]×î²Û•¿_TôßS™Ø]€×Æ8Ôi4LNŞô^İğ>?ìÜX(
£¢ú¦%`ÂnÂª@;…ä‚<2ËÃÏ_"((7mâèÍzå(.oM¶æÚ˜’ÂÆÚY%5ƒô‹¦ëÏ«{8æèßµÔY*‚Œñ‰øO”4óÿ&ÎAœ¼Ûær†³“ûã:ÈOé†'Üà?ÓsÀU(fş8Ô1‚¤ºøvËb™ÙA:‘¶88'Ë¹¸ Ï¿œø+Ñ›¶&cªÙ]­zn¹ ázçÆ'J|ï­wW!o¾Aı×'k‘ê(Ï›ô­ˆ…ŸFA*ÓöÛì’ë?˜¤ñ_Nª¿@Úu=ª¹iÁ=nû­ïtXZÅ“”nÀmäRşŠ±ÖB¡6wnL•ìS*'ü»	>û4°C’¬ıÁšÆ[Úpœ7T´ûmàe&	BhF6àŠâêME™ÌØC4ğŸÊú
cÒuÈ†Wº“*ŒÙİ ÕZÅöşXæŞO8åYáRElt4A=;J1eÒ±<©=Sf¸„ŒrB¼Îöf>+mE µ¹óz/R"½“ç«´ŸÂ8m	3áÍ;Ç…\VÌÂ'Jµ"Ü¶Œ;¬ÕĞìA v?‘£ÈP&«¥£·f“¶[#«ÎÖ2ğÿœ+ª®¡şŞWñT+ÂgÛÒdóî‘Yƒ‚qÌìß!AÏénÓö(*˜¹v¹+”»ËdÊÈş´¶2´‹ƒ¹F)°GW.K5ÅĞdÕ†˜±(‘SK¨ÉşC2•µ¨mc±Švdõò—Ì¯Àœ¼ÏK5Bèb;ÄFÍåù®¶à³
€T¦6øôÀ«ä³ ÑPÖµæíå ¯ÔfYö¬Â'œú‰Ì\ŞÕ8
]<,À¬‹^U]ÍZˆùœ-wÅ3RêHC¬S¥±¸tjÑpÈ·˜éÑù#"j]Ÿ0wûËXß—ß¹[$!Ë@ÙH‘JÖxAPöÆ¸@vO+ã×³°)âÕt½R›­òY>J_—ó$YE2ÉjK MF¡Ö‡÷ş7ª«ï(«sèå„ÓXQ0áş&úJ"’C>[r€¸ÏóÃ/~9½É4Ò¢–ÒJ´if\F[GkC‹§B)S@|ÄeQ\œ”«É§—gw`EæñNzªûÑ#"3œó¾;`AWãÓÌíñWI$:®ãÀß|„ñŞª‹¢,›rImºwº¦©éõpˆ£¿"9·âº5ş7$´O“‹?s@öŠ¥êÄÓ¤¤oBšÙbS(ùB¿5$àçy}™^U±(¶¶ßş&^»İvŒ_«:GíŒÂl}g>ï­00û¨l «ôU·EëŞ'.¡ÜÔy»…òJĞoÚ2HhäÉâÿ†ô¦Ú>§ÕH‹àİ Ìí»o5ı;yàN àlÆÕÎŒ~á[B«û­ëmq‡©¯¾÷$Ç9Wè±'ì¹bJßëİ¤ÀæŠXzÀóZ"*ŒÇ<@N_rt8±TÃXîlyŞ¾p@(f
½iäâ	ŸbæÑ/-Tğ"K¯&ó¨fzùO ABGÌù==»‘Rfry)÷óáZYR9øˆª”ŒGõ­¡‹ÄDo-Û9@g<åäëÂ¹Å'LúéüµI€
ÅN©Å£æ;ˆìØG£ñÂãËI,±^õ¡¾„Kt@dbJj…Nß/G‚	Ùœœ”R@`pQÔ¹§"x±2úÓÖû²à=…ÿY‚`'Páê'
T>f¼«;6½²Å¤¹ÉÃ·Ç(³]æ¯wV¬â+w<Ğl„;V~h³à&‘¾ßBßìÒv‚B§‡:¹Ï±¯ÃÍuPUFmÚAm
p;*CBÕö  µ2˜<~¾¸ÀÃf«:›¯H|Æ£H·ªJ{²;ù&ıÄ÷{Í!ŒÍ–¾_•Øûêc¹HdÏu‰=MV4@ë»sêù€6ryÊ ¼zê¶rÿ×„Ã¹ßÜU˜Øšj TÂ@'X•ÿtÅ¥Jrc°'u"ß7:ÖĞƒDÉ§_Å$Šì¸Š¦î XjĞŒù÷®_«9XÆû~ZÔâğg¬"iÆÀÓLğ®¸ï7j¬@À‹$ÈÎÄ®³ [g/JšÈÓŞ¯=àL·à¤úŞ)¥ #r’³@$¤Ó¹Ì8yÄ>	< }ïxëçâ¦aÿZnPÍHÉLä¨ Êı£TÍ–YŒâå;]{„‰.…°	¼½š{.<ÖcÉ cZùçZyNhâÂ¸ê‘AàƒáV¿mş7\Š¹SĞ4‚×ÙËƒ™ü jÒÇŒ·›§zZ^}qS¸8nŠ«š[ä. uöÃ	V u­í~iÇo!ÖÉ.>WÑ¾ˆ
L£C|qT¸Ãf9\gñNÔB¼Kÿz¶K,=–†”¡S–²‹ÅbfÕ»©¥âøiıÙBô8ˆİ†\¸)%èvóî_ÕYuÎğc³9ù	ƒ65
W&Í¼ß8Bæèªr?·§üŸ‰CùßpŸ¬-Eh&ò
}88^›ëın1A†d\7ÿô¾/ı²	è%DÇfÂ‘I÷‘ÑŸüºŸ_AĞ'hCQşQ,äQdm04›HrçÊàe“›T.9ü‚;‚%š“{İ>/mm¨N?°TMÖ£-äè‘T…®´¬ØÙÈ¯s#“/`½ÒKqÙË$Ô“ÍØlÛ2Ù,eíe y÷û—å˜ñ|]°õUŒ`™äâ{Öÿm!2p9Ø\IIï ş<qªíî¢|½İ@™&X»Yœ’z’IÈü·(ÏFøÂÚOGÚ©‡Pj`"³/Cªò#8Ïñ(#d)à<oyçf¢_27û*õL ´Y] 3)">R(³ã=0p2=¦zÖ}]…húFD"`å	rºøiv®T>²bv`a¬”r‡‚©İO{YĞjÁ!X0Ğ¸µ‚ĞÀÑ{ºäÁ¨°ñxM²Ë›s¹OáF²½d}B¯a¿T¿àä£é´!ÓZMe=6¹ø&¶T'J/¸¦VoÄß½:¯¡§ bzèÀOØ%‹§÷­Da²ƒïF;f±t6†îõ˜Mk_k…Yğ;Ë}ú&–ş(˜ ˆà¤3–QPn%Ü©Ëlµfnù/ğwiÿÓc‰ø%†ñ™/'ìõ<íV‹Ä:§­WèÉşæƒ%õ‚)†ø6‡õÜ*”ÑH!åÜ«|	Gû1Ön·ZåÈ´ü‡Jz´(ªÇGË-¼©lğ]“ı·G­4(û‡—üã.8!zà1³}ş['FÔ1«8Ÿf3C1½MÙ½A×ò«ìv2Pdÿ±˜ˆ¸zêËs¥€Âh¤()$%Lüã"-JŒùuoğ,Ò±›Nv”q¦–¶eìÔÍŸzUà•äŞ>à3nLÉÑÊ˜Òô
^P¥¹İ­g«ÿM@]—Õ;Ä–P¨Ø¿(T>’‹vüÎø>Å±»µÖ—ø¹‰%‡ÌàZ—Îƒ]ŠTg…B+ñE#¾¨¸ex®İ¬Wóp•“AQíà²¥d^©Í(˜Š›Çv=±²gØ-¾az½Œ»¦ †6y`$'—iôãl’ÔwlñI±n$ìÖ,Êz*Kíš³®´ğM†Áâwµ<â}~ş†”¸Ê©ÛœŸıÆÜW÷‚!è£OU”?hĞCÍµáì4¢kc›~†œ¡6“½ÍºÜŒ7aâçxºÊüİ¬˜ßI°½şMV•ÕÄ‹&nğŞE~î:‡WÉÊ9û£ÊÎ8£5‹­tŸŸ¢âÍ©„Ñ ÓÅ¸ÀNT³Ö±„(tƒëÎ¦è–şÒHZı£ÄTÜÎÍDl·£©G{K¥eÃÀ5’\Í,nSĞA±øÑû4•mÂ§ôv@°zÿ/~°¡\€Ù Z\@s/J:*WŠÎÊõ#Ájn9!çCüÎuİSÜÕÃÙ=ØÌ°Tİ¥omÜÂh†/Ùè:gäç£=÷/¬|Gnå‚b:b¢PéÒÿAúş—2¬ö‹Õo»«¬g6Š–7U¢½N{5âkkÈ_õ†“Ïüë¤“Ç~—F¾HCÅäk¡ÔxÖ%é¤ÖB×øãDtü¬ÕËÑGZ¥„hnßïb)ª­a´LiŸš¿¢
ï3'Œ5¦;ÜDé\ÜB9iıSıí÷,¸O?±šŠA°×PucÔ¹ 1m²SÂ!X|¾~Íª6×HHç¡v¿Ów€pë„@è:£µÌĞ¡U=Xÿ¾Äà¬p2—?Á;­¸(®øm   7ÉPÅŠ ï­€ğÀ¦±Ägû    YZ