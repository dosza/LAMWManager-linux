#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="342817303"
MD5="457361ad60aa37b8a24dd27a372b2080"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21279"
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
	echo Uncompressed size: 132 KB
	echo Compression: gzip
	echo Date of packaging: Tue Nov 26 22:43:31 -03 2019
	echo Built with Makeself version 2.4.0 on 
	echo Build command was: "/usr/bin/makeself \\
    \"--quiet\" \\
    \"--gzip\" \\
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
	echo COMPRESS=gzip
	echo filesizes=\"$filesizes\"
	echo CRCsum=\"$CRCsum\"
	echo MD5sum=\"$MD5\"
	echo OLDUSIZE=132
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | UnTAR t
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | tar "$arg1" - "$@"
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
	MS_Printf "About to extract 132 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 132; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (132 KB)" >&2
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
    if MS_dd_Progress "$0" $offset $s | eval "gzip -cd" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
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
‹ ÃÔİ]ì<ÛvÛ8’y¿M©OâtS”|K·=ìYE–ulK+ÉIz’J„dÆÉ!HÙn÷_öìÃ|À|B~l« ^@Š²twfv6z°D P(êĞuıÑşiÀçÙÎ~7Ÿí4äïäó¨¹µ³ûlkgs«±õ¨Ñllnî>";¾À'b¡òÈ2]÷ú¸ûúÿ~êºc..ÇÓ5ç4ø§ìÿöÖöNaÿ7w›ÛHãëşÿáŸê7úÄvõ‰ÉÎ•ªöGªJõÌµ—4`¶eZ”Ì¨EÓ!ğóÄ=rxŒyäIËY˜ØBƒ¥Úö¢€Ñ=2œÚÔRÒö~]Jõ"òÜ=Ò¨oÕ·”êŒØ#Í†ŞÜÑ7Í¡…²i`û!BÎ)QeiW‰Íˆo!ñf$„Ş©Pü}Ü:yÓs :˜@ƒLr˜¾O2ó¢â®Cší‚(9uv®~N*ôÊ÷€öƒÎó³#£‘<¶GCC­=U“\Ìøäh0îG­ãcc…dAs¼İt5m?vÆı—7v6WçtÔŒG½qçMw”5·a–ñóÖğ…¡¢\¥(j4ŒÎ† ¬T(PotzÁu‘ï°ÍUìyK4Ø·Zÿõ^+®E%ï÷qç\¥RN>ƒùF×@Ôë:nrÏßæìäÓ[¢Ìle=‹k¹Á%„+¤„¹ È·fê-«±sÊ·FA1vß0t'°-ÊhÑ…h;”=Ù¸!J%á•.|=]Ÿzîx…¬"Áb=È>¬ê&lŸÓéŒ5Ø÷{YYĞÅ6Gá gŒ]6„v @©LÍè4œêóÀ‹|ò72¨/†Å¿¶ŸˆnÑ¥îFS]û3ùÆ d7a1•U±k*AŸûĞ1çŒOëÒË~€ÎÆ3hæ7U …Ÿ‡¶kµMØáé¹2„º¡&´¨µD-§¨œ tšfÖÆu®vƒ_º¢ÕoIÀÀbz–	<dÄƒÀŒÙğ¬PŞteßyATÈ|š¢ÌiøÔ©}rÀ—-ÈpifšPYUÃZú›hWj:Û ró:DñízbÑ™9á† ­l‡y§f	ŸZ¢”µ§©RÉ:_ûóÚYûcƒ6¼´C1#<_Ø!ŸÓ¿ WtJ¨»$İaÿ¸õ‹Q‹7­³Ñ‹Ş ;‚¶ì7ù|úWI-gÙŠìåÂä”1 
ì.¡WvHêõººPÓJ9ü:q‘;E'„ ÅõãŠùJc)Eá"¹FI•J&	‰djR Vâ¦X67…•t[ycLìÂ´İ”RŸ8Y]†z>ğ¼°à>•J¦‰±Àª±@çû$êÔD™óy~«ü1ƒÉìŒ‚”®ÈJE6° N>,‡oEMÚXòèëg}ü^8´İ9BR«^…@ü¿»½½6ÿÛÜ|Vˆÿ·í6¾Æÿ_âóÂ»D›1š³I{J¥Iz>x> Íy„&+¿¢TF‰ãG>ô{nØ0v1]ÆWò©¥ùÄè ÿú$/…şª˜_Lÿë¨ áøäş=ùsss» ÿÛÍÆWıÿ÷Ìÿ«U2zÑ’Ãîq‡À7Dm½“Ö¨‹Û/¤İ;=ì:dr’`¤‘…yÍm^Ä‹Bsl…×ß“	<›.d’ûdáYöÌ†œ‚ÆÇM(q<ÖóeÕüŞ7&¢:Y)Æ„G~=ˆ\¥*‰#|¢ib´E{acXÈ(`2¹s]˜”QgFÌ`!ñŒÌo ]Ó‰‘1ˆélœ‡¡Ïöt=V·=ıË”¬~ g5ï´wä3D¬Y~å›.ãí¹™0ñ*ÊÌlÎtñL‡gêäFpöïMŸ×Y4%oõãÀî«Uş’öŸ—şÅêÿÍæÎ×úÿ—Üÿ)^µId;êìüÆÿ°ÙÛ+şóÙWÿÿµşÿ™õÿ¦¾¹µ®ş_ôä‚„©ç†&¤>„#ƒhÄ·È¿2§.xØAQlü"´'ËgD'­Ö ıbw[#-×
<ÛúB]©Z4¤ÓĞ„wàãÿxÄòÈÌŸÆiœi™ÄõH¿M°ŞhbYnùñ¿Û\Ú”+ÍÅÄÆ‚—Â¤Ã~ëÎ¥âxSÜC›…ãpÀ¨=I+Á6c­»4ÜÀò0ÃB~
¬ç…Õ§êÙ$rÃˆ4¨«O0­`bùsìÒËqÄÆNÈxÙuŸ;¶İèŠœ@Eš?>|$eæTIÉifdlÕõFÏÙàx5Ô$"cK·>(DvÅ8u/˜c“\ÔCsÎô€:·ÆqC•0–ñq÷ù¸ß½0T=bîØÈ¡ªXûğ(CˆÆI«Ogó"ÊAç¸ÓvõÎ‰_uÃnïÔˆ—ø ²ôš4RÍ¸(¶G.m?hIÛw.	z±;=I–qõÃî4ÍAAÑæn´²®´À_åâ CPš¹ò¢fXéñâ«Ã¹)*Ã‚?¸èRò:ö=ñ&=7Ãÿ Â €Ã¢K2$Z ø‚0{1ùøÇz|î
Á“-Èã=3›Ç%»{ñ«ƒ?]’r	¿×±W,à3¦Š×ÆÿJº+a:y‰êÒyÓ³synOÏ‘Û‹PMÆ¶WÊÕZnJ¢ª«g'å˜‹ÕÖMõ°¹¶D‡ëEz¥Ê3Şô<{2.ªïÒ
	!?½PVáğ	PÀÉât£ÁÙéK’òÂbµHV´ÍzC›€kPS°ñ*\íf¥íÛwÚÓÛêø(&ûK·™nwOÏŞŒ_ôN:\0Ø¹	Ñ), æá«ÓQëè–Ç’oëò^ÕAëó_Õ’Õ¥‚X:}*—7«½-Á†G±\—âƒPˆ¨ŠƒÖ­4åIÎCmuHhì!â!}Â*ëG4+/& B1ááŠò›Úç´‚…8å=7İ9ÍÎíW*v‹”@JÖ]©`mƒLÁÂ£÷8–“ù¤¶LÚı³ñ¨58êŒ,`¯?2TÍB\@bçX%½aÚ/"*Òô†CØöêÕ³ÑÚ³W‡ıW[*I„¯?èvß¸3Á…*_nÌ ®Ê$nIU¤’İIÄ±w6hwG%/r`Í½Vl4~ƒ¿Ú~Âµß²’î½ïO¯v¹,;Oç¶F.Ş€`Ó^ônMÀE:Aà{äĞ2iÿ5Y}j7§½ÁIëøV%ÂjÙpÅV©d‰%‚¯¦Ç¦µRíW1´@§©ızµœ­…ª$ëËØ¿
$ŸÙW@^ÖÁåÌjõP: lá:HT°ËºĞ
¦ç»Û¥úğCV²İÒn?@L>‰äçµãÅáŠ´—Qw—@­½Ÿñ y*š”$ãÑcf‚¥db…›r/3şh›ğ©\ª~Úö!É÷l."Gr²ç‚æåöƒho#ün›ÈC²‰¨ k·°3‡ilñÜóÂa˜>W¶ä Ãö<
R‰ÛÛR›tÕåğ¸u4>ì¡Ñlzİƒq,G…;2NaÄ“57[¢ú5¨á‰³K¨I\oÿrrWÌIéËy[SX•/$ÄJìêgÙ¸RR“¾9½0çTxÜƒÎaëìxß(µí—IÂn»½â—^’0Ôn`ø¶ÆûŞß~òZseÂá¯Uöùú/¿fÄÄM¦QËWö»•ï®ÿnï®Öÿwv}½ÿıÿ¸ş»ÀÒ¯f:ów¬ÿ’ô¸Ÿ7–HüëÁÊ|ÏeöÄ¡¼¶ËâAoîb£.¯—•ğºZ½şe¸]R,``øíĞÆ3ç0ˆ¦¡TãJ–ÉïZÒ%u<Ÿ´£àA¯7cæ¿Á@¼–¸„áÁK9¸X\ f¢ù9 îøèt8¿Ÿ‰—EÔROâ¡Ì«LkÓ@oM®ƒÒê{wÙÆ{”³yF	Â)¹{~\I¢’ŸùşùºCêš 6­ƒç¡wfÑ%ç&!~`»áŒ<=ş2uNCØDı´F£Ám½¢®å·Ğü§WÓƒŞà'è;étµ±»»GƒŞYßP}'š^õû˜¿AÈF©(ÆGxÇ9ˆPü,}§©Å”ÖyÒÀh°Äk¸H^Æâi1«r¡XÚ4ƒ¿FöÒCNÅüãßåºçc’• ä®¨¤*‹Ÿ\‘3Ş|õh+G}3<7Ö,5/U¹œT„.‰E±‡<€•Ï€lQ5NWcØú1hšñiR«İCX;‰5B•Û A€Z4¥)Jòç)âé•ü€Øo×#ãİ¤æÄÖâîC§–*­îZºï˜!˜«Óch­:™,^ÇmÒ cÂÍ1ü¶œ:óxCÜxPÀz¹0ä;z9QÛõu? h„B]t‹*C\«Tk‡Q~kàÏRy=Äxˆåœ†?y„şô3Æ¡óXì(]÷P-üŞP”¬^EÛBRÍÂâ`D’a*ÆuãØv©íâEæLÎ$!zÛxÏ­D¼ğ”+îFIÏ@jrf}Íìˆ‚LMp±BsAqaÃğÜ5~03=¶ÄÁC’×Bâ7®¦$ô©D•¨S	I‹õqµºeY `}Ğ9zıÀCçÇMˆX€/ZâcÃ¢åÆ $˜*òb“¨ÅÌhñ€T‰>ãqRåµ]ü»W;´;9ˆÜcàW×›BLò×ˆ>wL÷w"yg@"%@}øA<àE$`¨¬î¶Z“Y JÏéRâwY
Kç»-íu®W¼ºBŠy~ò¶Jì‘N£&?û‰µûG#qÓYË‘Üƒ£lwdBĞ h©Ayü™‹û}'näKäŒ\FS)laB^]è€å˜	ºæ@ØjâË@#è!]î8ÅsìI¡˜0ŠqÿŸ¹‹À€|ƒ3zÅÅ(Õ^–æƒ™ôG,2Û# ªàš–ŞÔ‹HşR#y2|+3Š¨dö.]´'ôÄÑ¨ç:×ñõm1$ÒW-T beÅ wséÆOT§Æ¢<…ìB#"¬©ÄcÇü5vÏ‚°äÒşÕbo'VÛ=ˆiÎ†ø’Çóã0ÆI!e-éT1Îœ5“¦)Õı²ŞTÏË:ãµ¬éåDŠÊ°z/
ƒ!<çåğôÇhq…nB^‚'$"ITw7ğ½$€‚<åÉÛhìÛªİT%æ¼}úşvßşî»` 7ú‰CƒĞK³ßßÊo”„p/ûI´ÁêØ¸âbO±¬uØ!ŞÈs‰Lß%Px;b:öæ]Ñ(¹ô7±³6äÈí“KU+ˆroJlÄ¤\e€Ò4SÄ%¡—ééBzWÖÊOOÔ®;óöpOUQ®Å8h¯XºMûÉ¥\0ßœÒ˜¹¯{ƒ—C‡;\\%àhesÅ¬1cÒšïsöÎ=/ïĞœåâ8{Çc)k3j…1ñé([±ôÀ;cŒiş™ƒ`è9êõ‡ÔJ<=ÎH¥Ş)_©I›óPØicd£‘C‹ÉxxÖï÷#ãQRÅNrÙÔĞ$îÕà×t`DøE8HC¦ba>÷î5ˆ•¿XK˜šŞU8íº‡¿Œ‡nŠß®!|„ˆ½sï/Ñ™	Ù#eâõÎ]/[Yßå
æìíİÏ‹Ô†ÇñoYNÎ^Š«æ)Ğ?cqï\şò-Øl@tL²ea6¹ nD0jÆæĞãïä@[±är‡+ÑMßwÒ÷Ò(°:å2ø‚‚\ïö†00r¥œÓà{|ÿØ…(2²|)ç¡§ô@Šö‚ê¾¨°ÒºËƒG‹ysvÛ¢ì"ô|agüíh&|yä½È]ÔSsAlKÔÔÔÛÓbá#ª+:Í½ŠÜMÓ@‚fp­‰ŒJã‰I¹ç“g¨²(‡×`pÛNJPwŠ.+Áêuº¢‚ˆ½ º:4òq#,l×tŒ™	&š®}j´²}‹ÙĞI™óØÁê€û0Ûş*„4œCÈ#F/÷ÎºÀk{\Üv×ù¯OÚÉX‘İ'°œ¬^…ú•&îîó§xaÀXïÈ°&ş‰ByŸíb¥C•Àæ|K@K	‘*mÄòÆE¾gêY&uÌk±Ê—ôlÅQ[Şï‹u ‡JãGpXû‚;ûy&½…lÙ‡Lózoïöò £ÂR–´sRşŞÍûlÿşsbÈÇ^™ND:0?¾ÑÄİZßòjµ_“6¸À·•&l½ÛŸtNÏÆİQç$IøKu
óÜsÙÉwW¤ltû¥0ú.ÄãƒÎğå¨×ççé ¤Ã›Ú¦¨Şt–¾uN¿>w½åwKMäZg×,¤?hóÈ¶(jÏÄBU°KÈ-‚$¾~.œ:š”¶L„ÍN71Ô¯Î'Y¢8[â³Ã/Ë„< E:4fs6úìo2;xÆ½¯_B**ÎRwĞ=íòD);'ü¾‘¨$ £,,kò}€DJ”LiûÅ‰½¥{5Î»[C½ß%«+£h(S–?(‚Éµ}DµJìe–¥ eQ¹WËÃ¬’˜:°d	Ã>˜K3‰\™ñ$»ûa¹Ğ±S«İôúÓŸ!ú‹ç·÷ƒu¡™bRòiƒì­vÕÜüÜA©jÒšÅioÿrÀ*ô€>Né„ÁL÷œü—,IÆ›n(Pòä ­ŠT²ö›äç·:üz
˜“4•ØXÄÚ‡¯?áÀRÈOÉÆ©’cóãß=Qâ ÉÿŸJ@²¹s	lí&O}!ƒÍV]ˆ Ğ’‹}9qÅ[‚üº ÷ˆ2‰àß<E“"SzÙÎJs,“¼×©Æ¬ÍøàÏ@0şÿô˜÷Q’’ÿ8~dš„Vìs¸´pÿŒy_Ê!©3O±?¯Âó0¬ >_TK„@ê!¶±’—öÅùÕş24ä3:€kky[Úá5†%"?Œ'f3áÒÜ-–pHCc3N¤ÃøŠ‚g©ãÊIv?>@1É~eç|?øÔI4OòUcGZÍY¸÷ß¸SÜU'
]qqzüø“«ÉPu¥Œ)ş=P<C!üL…÷±to GÔ5Wk…Î”Z<¹xø¡3y‡ï*¯ÍºĞ:6ÖAÁZæTR-~ÖÆáD-a*ùr7‚Ü%á\à´nDbÕ¸ãQ“ëä«„IæM¼rÿRÖ"ËîÈ*•Õ¤£
®nôëêZü‡¨%Ì©a|¶òOµP>›1L¸õ_zıÛû¶æ6,ÍyeıŠTc’Z HêÒ¤ nJ„d¶y‚´»Ût Š@‘*@aP )Ú­ı/û4±û2û0ûhÿ±=—Ì¬Ìª, ¤)µwˆTåõäíä¹|'™\(%ê¡á«y’â„m”WÆAÔ•º;ıªàOI¥êÇ(Ùç×ÿÓÃ|B¿š÷©¶Ö3š”Z¾¢5wpÜ@É„#€:¼lI¿şOqü¤'CN	Á±–ËÁùrAJA7êÀƒ@Lt!AüWßh•V¢)O–”‘Èâ&¿@e?5êF®¸Bo+ï¡Ç°èNş‚2¡“o	Iê•»1ÎpCG'§så¿ŠÆŠi¬T®zñìh1S…Ü^Ù˜³“}Q¢Š€}/}Ô:İ¢ZXÁí*ÓŞ­Vá°ğÆÂ¯åˆƒ™j]¿°O®œ)Uv¦euu£R™ĞùÆ¢ÊŒ´V×íUOe.˜¤rm”ĞİÒ|ç-én,×Î¿ÇªÏ¨u—s‰fåÄ†8sjËù7¨İ<’F«oØu6”Í¨ªC…4¢tuL˜ÊU“õ¨OD¡­<èÀ‹Ùª™…nF*ãFu£Z—çà†ÄhMªÙ)É|¤™Ìà"•—Aet™OdñiaFópÓE‹‘œşlØiûCE$Ò­Ç?Â^§E§ßå/½ÿöº#F,Á<<%ñ÷uÒ‰«ãî%ïF——é¯ÉP~Çëåz4èàWØ¹Q«ß]g¹iøé¿j0HXßÏÿÿ8
åo”âtà:Îü¬’ùZÇËoèÒf|MÓèâ`i%cã«NÒ¹êá.aÔ‘-ãWÃ,˜«êpÌ?Ğ”CşíëNĞ÷Puû=öQıbYtíŒ¹?&ñ@¦ –aÏø*+ímFDøŠò5ş
ƒn—¾ƒÊO¡¬u˜³òÛÄ„Ğ7õr2Ö_dñÃ^ˆôv®›uü6ì†Cú;éNúòÍşŠ0,ø—uîşpåUìmĞÁ.ú4)p¦Œ\İ×é7™t<4($Å£¦’ç“ñUfI	^Dİ‘Ü­…gÍñÜÒKYÜ†ŸY0l“f¤QŒ¾ô)EN³ô`[Ğ™J‹‘…ÄÀ¾,y^jŸÁŒÚş]Öq÷/¶!Èæ5M$(ë¬œËµ†çênpn›#à]Tº(×DTÁîÔîUß]É*›Õú9Ôø…»#ñŸ­õ²ü¥»T0÷(L/Ô´™VÈ§¬I¯DŸŠ{]ÅM R'½fˆô„Netçr‘à Ça×<õõ@º 9lû¤¸y”½®Nû@^ßÍgÄ8[\™6ûÜmƒ˜­İH•ü&n£¸Êitªlc\ºœJ±‘HÆ¸Å-¿§r¶a±Z²’Ã×Ò¦T¥ Ú(wxN|îÎoí›ìGn¯e4u{†¤h¦¡XãËÏóB¿ü³#58ÈÉ»bŞôrÁúíx8N>p~zëƒkZAe™Íä.åEîl`"rJµ2\ü¥P³şÏVU&’‚Íª	t'@„†&DŒÄã7ğ¢%ŸïãcCï ï{mŞ&Ó®æy>qYjÏ/>ãƒoT²dÉ÷ñŒ@S(´nÇ£èJŞ|,Ù(&“A—­Í°ü@7ŒÌb
OßzæN/7¤ß]ùEDšËæüÁŠ0ßõ öç`'mš»¹ñVòò"Ó©/ó×){¿ñ¼šó ½ç ö£aòl3ìÙÅÜm±ŒÂf²öPfÌ%sØ}fÈCÃ5ìc …'(NL;<9\$÷2—˜ÚAÅN+f‰	FGS¼ÎÔÎ×jî¾k§ô¼œ‹õ}ü‚æğâÉøOqéqìÆygÏ´"%¨œ6ÔÆ®ìŞR>Õ
³åìñwÜ½ŸÔÎkå<TL­v…÷ßR/Égİv—HûÛĞŞ;¹¹½NGyŸ#ÛåÈò8RGÓıÆİ(ëm¿'ò¾oPçSÍ_åt¿œì#tÏ¼ÒWÈûLşQÚí(3€†Mª9R®+Øo)hËô±šÖig{fwúÿ½	àYbé×UÓ$åÎ®b÷ós¸ˆ=¸‡Øüb´603ÅĞ›Ü¼Ô´ËYÍ¼½:ı”‰v†ytÎ,ÜÎ—¹”{ÕÑëÎ[ñK÷ïÇtÁÊoíÁŒÒí¶ÿœ?)?™áãÜ7;f…y¢paŠoîWw¶Š˜95hß·£>JòÂHàgÈh@^#îe9’‹˜ÔÖCiUvÀËIØĞ4§öâ*¶Ğ(aµ	ÖÊ€Œo¶ªàjÃ,à>ï]sãõcò’oDk~Û˜‚‚·T²}öT-‰šF%.´>·LH¹¿‹ÏOvNşš¬®­rú«)QT«^W+7—z	¥üxu9ó‚¢ù ŠŠY¶ööÁ L99İ¨Ày²À%ÁÌb;æó¥ô[¾ŒĞÇui™X20Õ·ôC‰º1çXRğ¸?ë„tÍˆdğ„D^Ğ_U¿—\´Á:ÙÒ©_ÛÛª"*‰÷Y¥IJ»K£oˆ*;2éKY!Œ¾üé‡OËN›¡‚U(1k•™&ÏÅq³@#˜„7,ËÙÊ*kıppm±íË/ÿˆÇÊGÍ¯W×|¸tâ.l2ÿìômå…ÿÇWÔË—¼ùÇÒËæà:Å4Á?"ğ“„ŞÀùûrŸkKñêØbüÜ¯½ûa`njÒ8M‰Í¯ğ•/Ë’"D"ß è‡º¬¢=+Íü²æh#½zY“}1-İ²4’[£ÓÄ+L¹`=Ïa\<Ÿm±=i`ğ]­#KùÜÀúYU˜6É°ÅuÙCµ¼¢<[¨®Kàœ0ÎgÜö	Jw• aÓY›É‚</¯À¸|Vı¥UAå,•êÓ°Ì|U3ä[/ÌW€qI«Ãº€â
jBZÀæ][àÀõ±°ÒSöFæbœã©ÂF.Núsl'iÏy®/pœ4N¥)NjÅkègcr ;‹gÎÄ›”$ÜSÓn¥Eî/ù=Á.¶NÅÎüéìV0‚èo&9MÒÏEùõßå7>å‘•­:CÎ~ÉøõõÍz.şW}ÿcÿ6ÿí:Å[«Ömü7ú›ækÀ0ã,¶Û#±ÇaÀ"ü(ƒsÁ¥aÀj£PWpçë…ÂK‡÷àåƒrYZA²š/ƒñæ•Şí½ŞÙßîœì¡S{‹«}÷âº|ª(Õß6Ov›òòyø}}{c½¿¬C†ìœ4÷øÕ¼ÛHßµÎ^ÃAüõÎ.¾ŞÔ›ïNöNe–zš\ÉêjïÚV™”lÓJ¸ó·³}]Àfúœ‘fe3áñÎñi{ÿèÍ7-düÚuÀ–İá‡+<P½–>†(_LÆ‰ıªtŞ‡ô¯ 05“|V]`år„?ƒ®ï­zÉ{à.ØS,´n;èEpgJ<ú+8*uc¹vzÀƒ‰
ÜœJ.Í»@È™SEË|"l“cÕ÷ävGa…ÃÎT;wE£=B¼Aáe§SqŠjb›²[6ğÖÂñè
™­#;°t•ú¹/ºq˜şà|ñÕËõ¸·Cù¥-§\!ÉÁãËáV¡â1â
X×å:v›D™è&Ö™ìÎJ«‰Êy£§ñd4€s]:ª_Æ“AWÄ#Qøˆ~z¹v y(r7ÂFÁãÆòáÑasÙA3›d~y=ÿ†ÔƒG»ÁìE‚f¥9!c9òíH:€¸ºÈ±.ØCĞK²¯$¯¥xâôóÏ}$x)]%‚I	tU¿‰’‰0ä ÕĞŒ¡DsË¦%la°›6VÊ+-ä.ã •uÃU˜ëò[H¢ÛÌ*”¾Áä=+«®	øÕW"ÀTTÏ=İZŠØ®£©§*L¬K&´®´ü3|­ÕÎk5ñiÕ„º—)ğ¶OŒ°YâÈ5K%æ¥B{,¹ÍïƒÊO;•¿­Uş°ıÃª¤ô‡\˜Æá*ü(‚ŞÖà¤ø <šÙV¥P­+n!ªvR¤–6æn84Ò;“,¶ÈÊ¦u¼¿wzÚÜmïœœìüK•#CÙh ÒÁÉn¦¶JVŠm9©’ÖiZG£œ{Ì8ô©°9lÏrÓ™É¤M“tå€>£Qp‹“TÍDîÎ…U
@´Ğ)¹ó3:eĞ¦œ~çn¤%™R#g¤NU¥ÌÂ¢–âdÁ½Ã]ø'¨T¯„Ié«èŠ¡I‡A‚›şÅ-zº‡9J¥E)0Ğ–‡®M)æÖF:zÒí	ëj”ëÛú·^Á°¢Ò§|0áºo”7ôSÙ3 ©\´`-.•Ôq±ú¥¬„XÖˆx	l[)cŞyxRÈl0Bfµ×ë‡pĞ®æG&]İã4Ùı¦b`G°˜ô“,ˆñì¹”79:w Ş0èÃ	Ç	ºyÉß46€ÏNîWrP½TdÀÂãØ¬›0S²µÍIòs¼ÕÙ’Y~cZ—ÈùÊåG"ƒáŸåüë…/·,€äµ¯P4)[`Çnš–)—Ë¶œÒš°ßKçÏ÷ê¾+Ûl”Xé‰Ó‚,0.%wT8µÒE]J êàã­0æqF*›É(aÖÕ»MËTûÛFFÛ3	M‹ô3GNñBw›kj«Í²¢*‘‹#µ´Ê¦:ú¡(`´ñ~4¸ã|ûÍDpÂ”Şé†`²iï[zÿ»ò¶¥İÍ¹Ö UrÄ:‰ã±"»Øâ ­·„Ææ8öl"õ‡!œ(¬+¡!oâíl2 ¾aØ‹­ÓÀ2“‘UäÍê1>Ù¯¿K¡UF“9øbdsúE×0äWar>hÂuÖwµZÅ)ôê«u şOw&Ú…ºRŞS0:¹“q7Ä:íè,¸ƒ_…ccuÔsğhÊa*8ÏÃnB¬Ç.Ï†zaUÆ$UæìQ©ÀÀ…x¾o¬!V¾e*ôŠBU¹’F°‘íb¤4„c¨!;ø‹˜§ÛGâtt+%côÈwÜ[i;ÿÖ˜w“¾ Hó‘	ÊšŒÑ &Av¸ˆØ::Gq'L’8y"hë‡9Š nIpöizÀÌúõà½ˆĞŠ£C†&îR¯'ÉmfŸZËDštÊpl[&çx$Õµ·ÄnÅøàûµÔû~BWá›÷8u.	sJ˜Éù‰õ—_ÕE)üÛ…t±Mç!Jg2$ªT±gÚ"{	÷°}DcŠŸP®³‡ÂÒ¶ª¾mC…"Šn¨0µæøƒœŒÀuâ¾`Âî?6AC51†rr®TnarÂëø¦2lÑ]Âîj6q–d¨\F+ıc9]i®‚qJ«‡ˆ4
=PIváƒŠm/ÿ¬%Z8Ş<¬àb`‹ô·rò(?Æ“å,r{ı#o®kæŠ™Ûø‰=ç—œìşÃ,<İ$r IÂ¨ÄüèÓ"xĞ‰ÿ#çÄÃÇ~Ÿ#şÏÓçëÙø?OëÏúŸEü÷{ÇêŠÿã›³|Î@?oT¬w+”»,HüéÁró“/Ù½4…h çº9‡Î'‘¬dGî·N°9DÍ/ê†m4j¸1S¿Õ4é¥GG¶Jñ=Ïºyäê²u?GqÔë
iÖ$A5®²*£K“¹½)hhô!exh‡Â$kÖ‰¹Î•v'Aå²MË±ÕFÌ$ÜS$±”'¡$»?ƒvG2®#ÛXäCD»,M·´ªœ¿­Yµßá‘›+%–+Ä"&ƒò k–Ğò¯ã•¿¬›ğ³ ™-5X0säPF)Tér*›ÊsHF]1qm•¦xAø\+º¾¦‡Rš=»‹ägdc$ËâØ¤@6™Dö|sW½sx:³^L3½R™"/sVXÃÖ8Oæ°É{8İØî:Ş¦©²Bê‡ÿOÏZ¤™ÓòdÂˆ4C¿¾:<j¿;Ûã/ß(ñõ¶ºiZÁ°+P|U<%F²ÄËc0ê?…¼ú˜ï×ÿõÃ*Mâ‹ŠGPØKİêø2ä’ğ¤"Š¤ÕXåÔj‹
\ê«bÕÜí¥2…cnıIİpŠ#§©#ÉPæVh­šR•9}èS0Ò§®¶`"ù*‰Í¶ Š&LJ"dÄÒ7õ[Iã–¬hª0V,E\Ë¼â¨5µ ¥¢¥Ä8ÆoŞ‡MËA}p4Ñ8“â~İ¼W3]Áæß;û§Í“ÃÓ½o›:.šŞmxâo)2/‹¼ÃØÍ0¢Î\kViÍ}£{kˆö…C3´ÉK6¹
GĞšâ¥­äòe“ğbœ¼ohb)jhÆo£ºV]³‰!fPã°ÙÜmŸãîÖÄ“©QOƒ€GÅnxĞ÷µÚÑ0üy÷!;+¸÷òé“SZ-Üî‹
üŸ'·[éÛe÷xfÅ]Jø]0‚cüjËİ¬šûBY7%ÜÂ°ûDL:ì9E½şHGm¦€zg³¡‚eõ`ÿ´¥hÄ¨gÌhªx€tr’»Ò0–zREk›T›ø3Ï×{;‡í×0L¯…&¥~¡ 0cfí¬ ÚE>²rû)öúÂwÕ¦”µİ(qtBTóWcÎáşòqzá0Mê†Õ.M@Ä5oó×vß¡jjxŸ–Õ~¬DOo¾ˆÖk½§Ş!¢ïÙ@?gmŒë$p^¾‚i3ºI‰.E¬úõßƒXMfjàÊ6&‡9Cåna"p³¯!ªw'Fßî“,­<E$œQ¥2œŒ®B½<şPy‡Š˜°^L§\ĞI8şóIó… 9ûe0é=|¤x$»üäQBªÆïÛ8J¨öæíßÜ"Fáª–B’SŠÉÍ—•ÎJ]¡r+ˆl	 vÁ—¦(3W%Íjn"´§!s*õ¥QŒæÖn"Ğ|²ØÔ’Ú¨up5Ê&?´ÆñpˆÛŒ4Úb=…´wJ»i¥o:Şùv‡}ºüršL×. 3@mç{jSËºÃ¦jÛàš“-SVK7&ü±¢îÅI&æÇ²÷‡åüËïet˜µRüeºWïï|w°)yÊì¥:ÇL±f&;TùXè)ÏL–)2Í¬	N ‡ÔêDöI¸•"…#’¾0v~ÿeÙº’dî	È³ó7ô¨1™¼m©$%mŸi*uÿWİŒĞ¼ÂY2‚sË<O¡.è–­
\"|ù ß?^ˆQ&Y­m5;{¬½İ„Ôö_3Œ–ŞI³ÌKfÍÎ:gk…BšåNäd³ç¡Ü²\üçšÀFåı½×-u?"ÔŞwìœrB˜¸ñÄ–K5êÀIØõ¿GqB^uÇü¸ÁŒmÃR_[foşÑ&h][—/7¤³V³M`Ãl ©¼-He6ĞoR¬d4¨Êf9;ÙohÀâõ­2ÇğU»h¦Øó]o J[¢:¨[˜}DlØß{Ó<l5[@½“ƒ&0Şx«TzQ'$´kâ6ÅQ!”u B©í<‚´~•Ã†¦ËÖz°s¸ó®yÒ~s°kTü=¬ø‚6á2ı¡á4ÆÿÍÅõå¡JvÀd{S‹^—sj…#ë~/³Mke
~·•ÀQqiÙ¤İrêË&ç!>åùŞHQ´í×‰ã=³–ïÂ±) DŒvCâE—Û3AI3APòà‚"\	]¾ƒûH”¡™mÚ­
î%Â~Åmå¤¹ßÜi5kU‚§Gc¡vbã5Úšº+(6?((çÌ,j§8K)E‚¤³»›&¢	P@U-¨Ì:SúYúùv‰ş4:N-õAtÍ6”Å%T	”_Ù³\ á¿ã×™Ù~G@	eæÀ·õ~ÜEp(5Bõp–*Ìà;ÀSÓóƒ®M¡­Wj‰bã•úÃX¦òÑÌ¥j¬39!(°°&³uÙá7r	Á‚/ƒ¨‡Q“±òkOÄª‘“‚æD:2u¨É3¥ò™³'_äC™½k²¦ï-2¢‡HOŞª˜XÆ}á*Â€6ğ¢±âwzÀ=ú*‡ìz0Lã%K'ÌÊS•À«Şz1°fdËÂ34³‚É l¿ÅçÌŸÕÏÑør$æŒÖ<wjjŸgDµ¯ 6¦·$ÚY:Î×@sˆ†“^G„y,,¿ü³~o˜ÕdgŞüÓÏã¹¦Åô;F‰!'?.*'×42`³há\F³2)Ïm'©ŠWéıu—VÉëC°ìwãÓQte«Ï3êŸìõş®B"c9¥nb±3¸Áıëâ„®Õ€í™0J“5µÒêÜµV«µjÕÛhÆ‹Äƒ1¶@ê©46›$ì©ôB#a(aÄhx™L¡eP2S©0e‡ğ…‰
âë@u¦rö`çİò$;Çí½Ãİæ_k¢$Ğä"á•TÄ¨»ƒë•ad\Ã»ã_ÿ1Šb´Ú&ƒd35Áa`úC´-Å½7Bà}’…Ø€ÓÉ¢çª®“³ğ~¯/es15ºXú™ıSXomÎze0›vÍÍ+ÛI13BÛ4¢­‹R‹lPÙ|.ªŞ˜´ İ¨÷>à 0ìÑÕ è­‹ø÷èp4šÇ«š†²IÛ;–|C®1xMŸ~Š†VbM“ˆ™÷:ºr3)w¿™oFg$ÅÙjÇ]·ŒÍ£ì
dc^Ûj®gİÖMŠ+ÕFmî)NoîŒ§	”¾7õ¸¹{æœ!ëB9¶ÖÌ’+óót´1–+ªŞ)(¦Ùİƒ%x)…Õ}‚Ér²İ7ÊWçµº"Z{ïöOa÷b!-îÀwÀÆ»š"¯Ş¼ É}§Í)î®rÃTñéOµA46Vé”<ÏaV¢Û
¤ šWÖ+›{7\©F"ù
€“ O«×ıÑúÓêzõ©ïJ¤ÅbÎ·Û«^ÅñU/¬¥Hk0ãônùTiËò°
ãé,Èßğ‹3ĞüË‘Æ ‚9;©éôQ¼sçÆoSOK«Ã®¤OÓ¹iuAî/Ùg)Kbl5HN÷Î?Ÿ/"ä^)]Ş[º…«ïßE¶ûl7ìİX±úî%‰„™³ı¦ ³˜Ş\ùq/DNÿ&ˆÆOômU]ç¾ìVAqñH›º"ÆBR—IèÒ²	äˆè„…£÷,K˜Öi9vü>5§ZBÇHİk¬ŒÑJMÜ„áûv·öMïñï±¯WXÏG½nº½bh{[6¾ß)B·Œ+`®q˜³ñù¾wÍS¿0ÅHòï)ğ.¿¬é¯Ïöö%ÂlaÁáGØ8“oñòOj»mcœ:àœŸàğ¹ÔiĞ_OÏƒYUXiÅ¬ÄÁèC8n³‚õ¼‚á‡6!¿ %ÒjI6ñ`ïĞ$XÚubñ ÅÉÍÜŞõfcÛ#
çÆz^Æd:N
v yiZ[8)ÎFóJ9ï»îtå¶¼c ]tüyZ	´­j[å¥cåã·¥^’¹–v.² dt^½ÌåfJ†”Ğm¾EÄ»¨¢OJö3#[e	ô#Cû1³sÓS°&I)º§mQ¿›&Nkãı6Rk+U›©ş{-)Å½°¹'á0ˆF°Áfx¦üKb=Ş\õ~ê›¿ŒmÒXë>ãã~Áø¥ÊTÛé¥¦{ÒOìôEÀñŞrmx„îıÊz+ìbÇ¹¬£Aï–<V¤IæI8ä…ÊË…²d0r=Ìq<2Dëd„€÷zú7 Æªú”YV\”Y¢÷³l!³~º+fÓXA­²gáï·;007Cõ¹•~•“ÂnÎÌW*MÅ”eà™n·K‹yóoŒ:`"âu2Ëº8Î-°®¦.*;8d¥/×˜i>Åæa·=¢W$@#<«.Î×a0Bc—u¿¶åuXéÛ—U‘üúå|/BôF9c@"Â˜àÙy*+¾Ù˜Ô<éçB–v†Õ”Ø@€¨ó¯Š’	P@ÈX¾¬ø:ì)$¶
Âˆaª Æ¦Ë³´L‘Uù"‡2–%mxyc5´£4`³X_r+u4c÷¨¦`ÖÔhi>S#G#Šl†Rõ]G˜ğ9º.ÒĞvü¢9’ÁÜû'B 3ô¢Ÿ9ÅT½¥\ ¦`LkÇã)eìîåÂkû#±aƒuI±10D@ à9x ô÷Ì-!”q” £/JW'fŸ2Ğü­ Z%î3l¦r¬ŒòˆôöóWÊTé ¾©«|Df<ÈFéüú|oáÙf{?ÃšB
˜=bQq"HC‹â2ø	6¼Ã“±	(¯Éé[C{’, ½Ñ^k¯e\¸Ò®Î™[” 9ic˜VEwkËf¦-wlÌ¦ºŸêÚê§âyg˜9£ÚiÙŠØ6ú£Â}Ø«ÊïlÀÂr¡Ó¯S¬ÅüDçWÎÄÃåg§·q4ÜèP,Nö‡ÔœD†¾ŸıÙY/>±	¬\‘Ä„(·$gz½ä|{gBÓ6J2“ît&¶Ğ8ñ·…ZÓ”ê2íPCFšìI‚ÿŠC“.-½Föš^ì(ƒ.àS¤nU'ö.{»d÷QFÙÈîì¾ÇgİğÚ£	CÅıøJ²¦Ö¾G7ƒp,º²ò-ÍÃ³YF5LíFWíNÌb$íXvKv0%æºêwf»Œ´r#TîÆ„“šÙÃ¸gLôùù½ÿòœ r/ølsué÷Àf˜2lgÚŠéÍàÜ_‚•Ì2[§7(Ï‰=,we™S©Uâ;•¢æ¡äîYÁÄVIwÙÛ¶‡Ø¬çiûwiæ.¥tğ–’zSY '¾Âš`Õ›êT_˜İ“¬m=™š9š©ÑÉàÄù§‡‡OöÀ¸¸ßÑÌµ$Oøš~N/ñåÇ¦É*âèGÔq5{ô,²¼îåÜ?¯¹ƒôNÍúô¯ù³MO\vS0>6 2S´\ o¦®§stF˜Må2÷÷Şì¶wŞœBíƒ£İ&\ÁKìÑA"àxæËµ<Rs`•…›n#êz%na)—7¥©QãÚ4ŠR|ÂNÌH|Aw„ûsŒè,$3²:–ò(9rHdGî_ka¥¼ÜúA4°f¸m·á:É¦ş}4˜3ò²ç`î¤c£:úËF$ò‘e6BÏQvW*ğö\ÌB)#tIE	He£(@cw
v€FïÈoqæáä>²qÖìŠ*ÚyglÌ;]l'†HÆñ±•N9È2Ç˜Wpj9ÈÜ±1Í¼.]$Çq2~#ÃæN×òéøoU‚IByZ/ü,ñ?}Z€ÿ†ß7sñÖêü·şÛ]ñßŠâıtœ(n<İÇÅM)^gÕÆærK™©İÜÜT¯£ë f{2È^½Õºp—¨µ0ìO…k«|¥,;T ½qEG
F_‘Ï”J+mÏÊªĞ"‚ÎlÃk˜Ÿ°÷Ÿ4÷ÿJ‘<à%Š¨ğaû»£“İÖ÷ôõ~'Ns¦¨0´‡® }†è»nØßTàRŠæ½òo%†úJSb+g]ò÷]SF:^UDGàe~†¶~†¨<?v¤F‡0NĞà
xÊw¨Å–Áu¡R‘ÙšHƒİ¨¸’p¡¨¼E$æóùsTî”£Z»{-œGÕ3eÿ§Ş‡°&GÉÆÿ\¯?ß|–Ãÿ„G‹ı±ÿßÿsÃ…ÿyú>Ä ¬éLŸÔy’X'Æ5r¹À%_&ä[*"(Zã*ÊIRÅ‹AzIUH†ÊÛ ]O%ı­º§!ö¼¹ˆËh”Œ	+JZİÀæxxtº÷½Ôw1È¯–hâqty[A¤ôUO‹&«¨½FJº CòğåÉt—üï©Ã_õ4§,ÅÑ†}»ô”Nvöş&vÄÎÁë½æái“ËS·8®À‘Õ3ïy¦!™Å}¦‘UÑíş²û®½»sºƒ¾­†¾wËÄËrf!ÆKßs
|Z"™—ß5÷ß -0|3ÇôûdÏl§DÁ%ÿ||>>oÂy¨îƒ(ì‰£¬ôh SòO¥ôV=n‹:ZÇÇT÷ùø±„]û%Ãg%êÏªk›bÿ´•{ñ"û‚uÂ0İá¥ó)•MP$— aoO`’î6ü«"¬ª×Òı5’¦¨õT*ëŒ§Ğ«Æš™E³Ÿ§üƒoPt‡ëÌ~Ãõ[¾v–Í.ô=JÖOËšyä"h-0rßĞƒœ­oNa]~ì^!S6ª |¼J±OÖYĞ&>™§Âqµ3	ª“ËşXç4©z²Q_á9 SÌâ¶, /Ü¢Él€Kéd÷õA=€MüØ¤²¹±±ñüÏØ­DI|RŸ)tY»Ğo2UQıÅ…™ënmQvİ‚Ó1Êı$÷ñÅ³ö³Í\ÛÈ7æ¾™µOÔ´"€)wz=«Ö«ußË¸éL¥iË$æú_OÕ¼1{æLæeŞ0©®á&(“º­²ËëÏ1Ù2÷dœËªWˆºc€î¬N+‹¶@mcº=Íf_xûSÓüt{ša>ææLø-ul£Ÿl³ªjßÎ˜ÛÛu™³Oíæ:õsºGÂôÎUfuúPá¥SqúèDªÙ~ZEL™õ(Hõ°{4…”&2@º7\Eã÷“Ú~ì1ôL0Y„‰ò¼ÅU@yÆ©jÂ·g”QÁN×ŞÛmªTS áÑc•”ÀãÃƒ•DŠbñ†æã²ğ¸iÁùd•h´r7¼&>íxÿvÆè6RÒÅ"ëŠádtB³ph*€A«Åù¾4ÏÚ{§Í+½›ÏªCÔU‘qBbU–öÃ8†ıK­ŞÂ6«uÚ}ìçRùØXæ×ËáPmQşŠ¤ø°İ:óÃÆ‹>İº²:–öÜz¨kâwËákÎ/¹122ÂÖ]úñ¦0©ñKXDã
Rg«øT”U¸WW?şä{¦¯9wÍš#Ä¬4…‘crO¤*Ó÷Nš;ûTªÜûÍzª£0èéÂ¤7yJ(µ§È²4¥FÑÅ„'ÅŒ£ÒI—ñ">tŞœÈàÉaõq[À9éá	çÙ³ìë†¯Â
ø©6ÜÎY«WkíO¢Äûê¹•\âLc÷´\]&EXû‰ˆ/àç9ü¾ÀÈ¦"ÀoŒQ¯B–`RÏícPõzP½…á0€<="*<ªÉ¦ÖÆÁURË6F<eÀ1äÀñV;—W÷|‡ä™Ò¦)j·' óNÑx]YZÖÍõöL±ê(I$–ˆƒI%á*¡^}Q¥œKgÛV 'L­<9jµÚ;'úº`rËj‰-ªQO_”V^¼9>SüZXinJ9×_éÒUãäàë·>ÆŒG+Xë£şõóÀêöx|Ò|»÷—Şg—W½’Ñ4LïlÜÜmc ­¹ÚWĞ ;ÁÖ¬RáÎ©úKu»•!«gcÒ(N½}1ŠºW°s/‡ò?icQÕŞğ FÀ3ÜVX³[a¸\×ù‚t9màÖ°5ÿ¡š,¦©øÁ½ü9Û‹Á]¤‹¢õB¿~Wm¼ìôô0¾·˜À8–NšïšßîœìáîÑò¼ïNÚ[áãKŠbrc,sÚUˆõ|4p<{ÜW8Z¢‹õz¥^¿wq5ş ›•şaôñbri<ìÑ(^W¿`\ÅõôíÇq2VßƒñãÍÕûNEÕ„çÆUo2ŞH¿ÑsßKah~?L¡M$“‹k ‹~ğ!<¼ÀQc@À '”¡&ƒQ0êÊÀœ{Ğ½Wğ¢UBìbÕsÏÓ6Rç.4ô.y=ûğTH!‡ÿ^“és½úp@’hà5Ä T°¿¾,¬‚T lÒßÿƒçÚ0¹-]´üÅ\%óÒmôsºSì»=¸Ù{.x”¢Xk© N;ÕÖ<o—t?Ğ4äáÜyr}àûR!Ç;.¢Êfõµá(Ä)‚Xı©”yâÑ°P¶r­³cœâë&4ó¤õ ÒbYöıºÈg¥İÍY]4¹¦göò<´w†,Yÿß*;I£Û_hÒ˜ÎæÔ(=/ÕµMg²­ˆ¸}1
p_}?ú;şr}¹ÂÜB_~W 'æ—p¹}SüÖ0¶o8#KÉ»¬²âÏ@Vù?ßöl°åËÙWû°óÕëÖîÁ§+rWÛÍê&ÊWííæ4›Ú¸ÿÑMö)z¦`]aÇSN=DdAv	CVáæ:ôİ‚ğØkÒHë_××Hs ƒ~÷Ù&ü…]İx[tg"ï< Û›f³RoS~Ü†‹Xş§´mÄ¹5ëik–qw¯ü3>À¡9H|)mGYúkG,¹Œƒ[¬Â±ÍÎÇ1üË>KuWß„-˜üz×“âs·ùéûx˜yÅ¤™Ï0j³~»¥THi»Ş´Š©…ŒOj5tËî*ÃÎ(L~ùOUK¾OÜlÓd¦°Æ\'“†@cL©Îûå?fWg˜ßÕw‹'ÉX›öRµ—Ê"S¬NêÓ²Ò)6+¸¢êÉ10°`«³[C¦AÓ)­á;®á¨Qs–Ï¦GEµœ•’	Ğ ÀQ¢/W¡fÍD\œÖè„NÇôÜZ™İz\F3¦a£Pa:Ÿı`ñ™E@FÆâˆ×ÊVf­dÛ"r+ÏXxnã-½¿>j©¥Q—~}xvğºy’]¬I€¶M°4s-™ÃnÎŠµjıYµ®*C]£ìØà|öå0cºnîú/ÿ)^ßjĞœŞr¼ØAí& ¨4ø|’ÉPG§x""iT%BãsÀÓ1ãvÄéq¡Pxºµù±w‰©0}0oÍì´Ñn+5—;w«Áñ8Óş×ò7ø²ö¿õ§Ïóö¿û¯…ı×û¯{€Sı~6`lÚŸHgğg21&«¢/bïË
,©y…[ôÙ>©£ñZ´6íåÏ…ïş5»+<şäyÌ·*ÜrW6Ë–ÔŸ'Â¦ÇƒJ‚6Ô8"óä±ByÏÛ*†æŞI%ì¢RwŞ¼teñŸ¬Ğ+µ­«şQ+Åµ{‰šÁ—bdÒŸ¢aÃ•ş9aG9ûDyûs‘ıà*ê´˜TĞ¢´&ôS’.-•êô$£s‚¤ëæsÆs¢´AO­–CÚÍ,Ş<{JÏ¤™	ü~¦kËxúœP±tÚ\ï(fm¥núqJßi¸µ»!Ú<wÑê<íù÷ÙBlà&¿lfuDÄ¦70-ªÕª°ÓJ^Q]ÛolQ²ˆ\g(&rÓzÃ|J}xLO/éN?ºJ+eŒ¹g£æá‹‚UÉaÁ	l¥e 6+–§Š“«ŞË˜W—Ø(ßá»è°û"ï8ìÖÄ¦ôØJÈ;*jî½Œgu3œÂ6y ¬h ÃùJ‹atL<- Á›®«ƒ¼ÍåÅ)[E…l•¾‚Ñ~òö&f*êSm8ì||&ATl¨ vNÈC©V8lPİ–ç[š½¨$—yoÑLÜa—!Jds¡Œ$6)Œ|
ûK°ãB8Z‘±Ÿ°üÚÍ¦˜<1\Ùa/¡fp;8DK¸è…ŠîhRª3Ä›íJ|yD!#nrì…PÆODè=xÃ+SyÖ-•hk'CÆ¸¦;Dz¡µÖ)Şt¨
1§µnñ~òLÒ™\†h*ìñœÙõò4Øâx¬Ø6`=¹ÃÛ	tŒŠÎĞAĞï ñä$Äw øåe]P?ñL@ºÔÿf§ƒP|¥¬kÇZó©r´A9ÜE¤uÏŒ˜Ùr
U¤à¬8P¶™¹Äå‰QHÓNë #¿ş¯n@Àc8àGäÖ;
fÄ×
Z¢†æ uP&Ù!±'â6<z”`†3öÕWëá‹ÂÛcz•[wzQÖ·J\HôN»Ğ£ç\FQÀ"§±E£óAÎ*„MÕuN=î>\§Ë›?ïäo»8ÔAÙ0ŞYHn‰›“Štª"û®X{¼÷‘ï	Õú&‘„ÀŞw!ˆ°ÏVµXÿ„õeqï¿‘q:ämÒWM—J;”vúö\@Û©ßy¶ƒbvÓØT´a)€×é]´z¨Û~ïNŠôÌVh9¿õmİ¿3l¢r½ô·PÒòìÆgîBøuJš'Ÿ|ƒT—–Øq¯˜åÇÀpKç’‡¹¡D:>./<‡üÏP­7Oäá‡VM½K5ƒQ/BO¾K'´@äÎµ"5ÆÒĞaÕ@™E°®±y<{óû8ú
yé±ıÎ‡¿ÿ]ız6P2®ë ­b;ÉuC&bÁÅõÉOe
ÜÁt	Œ"gÅåuQŞågÙpEÜ;1vEx
£Õ	†aÒĞîªdŒHx9é‘`2À›ğ8PÈ )Cˆ1zîGŒÈ]ç€Ü¾
6×„Ò©ØÓE#7 üÒöµ‘¶·Yğµ´™jÒ¨Ä¹—˜Êij$0³®k{6\—)HãĞ¸cÉ{zË´7×ûI¬ğuûiH”‰J®jÎÕÓ,^ŒİNW•ì^êÜLwSçv*÷ìú¶ÊH¸[¤¶\\DsÚLÁ¶)^™u¦óŒ”3ÖJÈœŠ|Ù“¶Xü ¹Y;!ëˆuGÿ³öBw‚5L÷§Ùg^µË{nÌ4»/j¤K,	ÿÛ^Z¢+ŞæZğ‹:-«$Ô´iKdÑ¥“æê£òş1ôáB]=Ø(aÓ”Õ^¿ñ$À{rJRRù¾ÒX¯úÌ(HªS¢BÌ_ù=•Ğ´O
9Û±æò÷ĞhØQXÄ#ƒWÌ•Åì¶B¬‡rÃ$èx¿ùµÖ;Ií³Ö1ÿ?ıO½şôÙ¿ˆ§ıÏ—@ö«É°Úï~ü‡µõõç™ñºñtÿğeô6A‡Şó^_yK¨-{ö_9æFòşeŞZZÀ}²wY!×·ñ h‡‘JöÄŠvÏRºúUæ‹sñ™¬Bç¾ÄûQx™ZÖ¡+¨F±ÿJıxY^U…ğf4/ètÂá8	°@	‰İñr“ÍÄiŸˆ‹É˜‘^&på\½ªT^ÖäW‰Ex–½ª÷²äñšÉK´ä—£¸/;[õØk4@ÜQøJx§±ˆ¦™myKª!¨ı”I ñÅèÕ¬2µm*Y`8LC!]îK`”^Õá'üyYƒ*¦´*¥–ü8¹„Ô7oD}O6Ş²*R¹më¢´,i~S#ªgVòtÒıŠzÄwBâI»¤äÔJâL¶æn‚*¾RÑ_€¿©P)KêêkSC¸P–Ò6#[iš¾ğÄW´/²¡ú4Ã(Ø'I,cš‰ß`ó‚kV—÷/‹ÏÎËÏÇŞƒÿ{¾Q_ğ_xüÍEı%Ç†¼µÿÚX[ğ_füÏ}<ó‡èÆ†ÂJc®zúµÍ¸½>šU‰É•¨¿ğ¡
­Ã_:£Uª>IŒ¯Bß«¶¾‡;MÏ6Õ<×IÇqÆx˜²´ö[{-ÏnÍÅÈ3Pğ0û÷ç—¯YSt~yòı„K7üláoÌ!¼p+‘3—Ki2Y7èì]£^˜UËVu«Î+ç|ÜåŸ°hÈzrGÖcCi='ë^ê
Ğn·Ùzs²Gõ,ÖxuÅf÷¢G7~Ò‹>À9z|úÇ‘+ûÈ“g­[Ÿh£7fr±Å§aÚTWNuV´AĞä)¾#wHj¨¤¯—¡—ò<!ùJ,©ïeH)Ä’N-2ÍàipœtdiºM·™WWPUdLMzr|l&³†ÓXà›yx<ÏÕ€B®?ç¬êµøv§Û‹LN—ÆêxE6{†JÊÿğ÷¿/ü T“‡‰íQ]#N°Í¶zL%=•¦ÚÔ5i íZ¬íÊ<ÚrZó’g	Ï8h„|†m °& ©ná¶H}of‰®pã¦Oc$Z”·Ê­‡¸7PÁ–s­+S«-Î”vke>ê<ly{lzj„¶êô¥ÍDe@@İÃ¤¤ÚèËúD$.{l;?”è#¸—'8Cxµ~}tâe¡ÙVºô ·ëzûpiBh™UoÁAÿÅÿwzÌ•6ö}8áßò¿Í<ÿ÷ôÙÓÿ÷eäoxèƒ>>áø~‹B,‰¹O6aU,à‰OÔ¨Ã0Bgy8<-'4uÜy¯(\œÊt, ‹{(PèE¯rÒ>İŠ·*µS†d-İ +Ú \!Á&ıŸpq^‰İøfĞ‹ƒ.J
™[!O~DıîaT`:ÄSt/aI!·€>D	‰ëÕo, {ò²DcÒ½‹sbÕËíÓ4GÃp€ƒú“…;“,”4gxYÃQ™.ÕdSùdëbÌlµÿ<ÑeAKl‰ŞïCF9WSï)|Ì0)¿+9ã\ı^HèüW±@Ñ“‡=ıgÿ›k9ü÷ÍÍÅùÿOĞÿğ<è›¸üh€ğœRp“ÊìF\†Á˜üápY_L®áET=ïšó€¡Ø;aÿ"=ä—‡( ¤dTËı°ù]kË<&È#Ğ)¦–è!,QÄÔ•¿#,XÅcÁ¨†æK{$XÑ|¡„„‹g¾ØCc×î¤CZLê™>‚ÅÖe¨Õ,Ã€¥j©“Lº±ºpÓí,1Ó¿ĞÀg„±#“¨Æˆà@zÓ¤jf•ÀÙõ5Üíñh)@±‚«y‹¶äş¼ûM½¾úHñ5¢°¢ÿÛ½¿4w€âiÇTüÑå°Óÿ€ÎT8ÒE‚^ä(ñ6ú4T†éQ/ßº3Q_™Â–ÑzZ"ù«S³—¤
–f×:Ì®“:ü×
‡cšcâEÑ,›ÖKc*ì›TÊU·3¹Â3¤ş‡{Ìf	¥T×Š&ä¦5‘,	•BÇx¦æ±sb‚¡ÍTÅøk8Abä
„*3vıÀd9O‹
†X‚Rã4Õ<¥fn4ïŒƒH’ˆÕœw˜xÌEÚUºÖìbbuTš§Ñû€øú^Ğ r–Şù­#zï…bV¨«fûxDŞj` ¨‰’
‰¬´ÏÄ™’‚ŠUT û“ƒëç59ŞwËµ9ò™oİ|ÁBÕ7û{â cè^…Iv380­2ıå4 qrÊêhVÏšÑwŸHm¢³9Ğ®q¦Ô'l¦.àöGà¸éõe¹æÂŒĞApÛ©1æ
gl]LmŒ"î¬©/›öw3¦AÍ
W%îÜ—m’›Oô1ÁbïA/ØÏú“-ßö#çºÂHÄØ5ê[µqr²ÿúúÿ‡æúççÿ7gíÿÖ×Ÿ-ô¿_äóøñWƒ‹d¸mşo² +õU~(Å¯ÈçÉÿoİ+”JxŒ"SÿãÇ÷ø1ª‘ánÅJ@÷tĞÈVÏLQ3«2ø²Ï'ÀãÇJñ<»¢L4¶¢—¤oÓ+Ò»é}ú‡ôTÃ¥¯¦Övï|"Í©U®FsŒ×Z´’¾Ì¾S‡~¾7¶èÌY‚¡	t—€úÕ|·2Ãeèºí“Ÿ‡ÔgàÄÕü¸êƒTÆÎqÅ#'„¥1ÿ.C%9Iæ¯!;øfšeûÔ‚23eTµÂ­y‘:KuóE8¦¦Ây+ĞØ•äšÃœfŠ_Ht<š2J \¨Ë«3ßRïßu·n ³kJ ltÌ aF$,Í
ÄÀ™¦hkû±²˜¶‘ŞÛ€@ØDéşA*ùÙôSFª‹2cJ‚¶?pO¹Ó¨ˆ²³Hh™,õdzîÂş+‹÷lE&òİ¤¥ƒ4u˜eëÀ5â¶JöP©l‘3&X\l$ÿ!1¢gRA!ï—óÿ%º‘õÿYßXğÿ_Hş4¦ÕGC§ò¿MÂªNDII>Xq‡¸$G¥_Ï»~òz¼Œ{½øE
#(-’¥iİcÜãÛaØğ÷|%¤8BøK
+‚X!NC#¬B¢%Û°7<ˆéÀE/¾vµ“æÎîA¦½ÿJmsü(U(“-¡^FŠ¸Mİí-¡ü›¼¼›V˜«“[:£¦L@”a‘‹ŒjBÊù_	ôŸ·Î]£UˆÖûÿy÷›bÇÔ0ÉV£\I™=¬@%Â?v?T^Tàÿì!¥zƒ_ş3“¶^·[õ£ò˜å-ö›³!—Ã.ñ—ÿ¿üÃ*öŒäT²I‚ì7ŸG.qëaĞÅãöht &Hde—gOr	ûæñK'
Ro=‰"šxQmaî½ñrbÿIÜCŒdã'G9=%¤æ×“WW½ºÁĞ`²¶©ëªBŸÔ3¤Æ–3òOK
$QW³¨¥Åz"Õõ£AL;­”S†Ò£EÀÉ#K¾
”õœ)Æ+0Ú£.áf¢mFd•v‹
9%ÉmQjî—<Â…÷5òó©Y‘ÔÀS½;<«iÅW*­?!¥>¡XÑ5ná€æÊ¾EôQm#¥»¥ëÅÈ‘„É×¢¡ÂgÔ˜-
ñêAŠÁ-å©ã05ÈSƒy#ä“*îˆÕnÖ"}5	ÏÇá¸‚!J¸šmë™½î+·¹Ì£ş¼c·ª.>‹Ïâ³ø,>‹Ïâ³ø,>‹Ïâ³ø,>‹Ïâ³ø,>‹Ïâ³ø,>‹Ïâ³ø,>‹Ïâ³ø,>‹Ïâ³ø,>‹Ïâ³ø|ÏÿPS†I  