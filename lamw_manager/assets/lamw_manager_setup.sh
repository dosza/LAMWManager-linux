#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3891924326"
MD5="70eacbf7b1caeeaeac4c4eca956a4d7c"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21216"
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
	echo Date of packaging: Thu May  6 22:22:39 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿR] ¼}•À1Dd]‡Á›PætİDñl;§ÖLaØ Íl\ş$åx²¿
ª\=ºr9t…qjÖRi¨Ïeå46À×÷Şpç‚W±K íb?fÆ…ıDÎê¸ó™Q#ÃÜ'ñn¦Àµwö¨sñVézèŸ5
~ñ÷¡“|ø>[v°›Ğ´cÁ<Õ×n86W–ŞÔ€ñğ›Æ•×ğên¸8g<kñu.•º±;Ø•!ô
HY5È¤a<â‚TT _àq»ÏÆU|·²~Äó„ç	õSí¦Qö9ÖnU<¬°t·Ût£wêMxt¢vŞdf|Ú]£Ä¥ğd{Ó0(SÀRóÏ1ñ)-ÊƒOdFGCÃû\ŸT.;Æ"ÀkDáh.
(9;{;5z‰y¦AWÚñÑK~Ì[ßQ$LÍw6aÌ¸)Ö"@ChÿKØMå¿Ê6]ëzYşÀ6ø¡ ÷Ô\šÄ’‡Œ\ßºûÕ~e›”ã1§µÚiŞ2 “û…Òø†sÌ!_`³±.¡uØ“§“z°‘jpOĞïLÁÚ†„™eì’ıjˆjòT¡N'Šø+êÑ	Õ?$n";¥…i©Ò‚\ˆ"R„Øü¿2×FâÍL&ĞîËsV‰>«øHT)•‹sûŸ|Cv‹í§iÅ[vßÎXLÇÿBÓ0—áÎş™èWØÆIÒzÎßU@AÉÉmBÌ|ÈI<ö°2¯—c¿Ö?bEùJ°&"1lštRªÃ“˜¥1+ûzU0àõ'˜è@•:Š4:wÚ‚ ÈÃÒ®/ü+Ô—‰Iw½Ğ÷7ó"&ªÄÕÕ¸aı0?c){ÜMõ¿Ì’™9B‰8a	M0H¼6fQˆÃ…\PE•^"È øN”_‡/MAI#]«_¾òP§c:™%İ„%_$şîœ½h‹‹Ê/'¡pm@ˆTÛ›óüZ9Ú£@(r®8gœ„ÙD«¾§ú/û£šˆÂ<@xñ¦Kw1SÛ‚âU_Ó/“&F÷ôÖU¯µş&ªİi7EW¤KğôÜó&CV5`oY|õk²-(\àŠ'Bx1^úÊ¶×Lh–E£çèå+lg£4a¿©d°šıQ¡Áa…åAâ.XÓ*a«§›=æ'£°¾Äò<Õ‚àcSQb)vÅ2.ó¥Î‡²şîªÙz˜Ù:«ÆAÆå¢¼z!, ÊğÀj‡a¥&MµeËÎ<ıö£^êœÂlø•H2fGvjI‰JøØ<‡éïuëê˜¢µôL€ödIl3#HgR[4|sG_0•vinïå
ÏùÈX£ÿVõönTãs—ò÷Ú;’p.Ó‚ÚE;şzÚ6^,©ğ@–´|!\¶ FÃ7º× ¢Jr÷ƒ³ÅÄxÉzVn£¹Sİ»v|t·élÀçQï†İÆTa,„cn^•óŞ”cfƒqÿàs¤!4ş«â@6 şŸıÙNZÃXpŠ*Î&“i;¾ÎxªŞ²0ĞÔı
µu<lC‘rkå×´Ó7Ü%ŒSÎ¶šP=‰Òp9æ`Ê:ï6á€˜>º ?lÎ
0©ê´³çœ‘é›v­²‹%µÒ€ƒ—_±,Å@8İZá…:‚ç\§š¾Í>jéhÂÿ¡ç5¼HHD³I yµ]¤¨óÃ=?Í @ä;$Î‘+y¦æYJ•Ë^ğÚ5G;z ñĞ£×°<îŒĞ8—ìoıè¡—sìEb†’<öŒÃşWb8còØ Î±µ¶”ÕRHvùb¼¨|4q}¨ËS0¡áì¤nxÇ>]8 ı§&jcP
peôlLf¾ËÄ|¼Mşñi·
zkƒ¾F–ô{óqùZS°ßC7ÚB[öïä‰úüËOzÚoãmâû€ıEùÄÅåmÃpge¨›œO„;)}@?‚³Ój‡]OrÇ$)waz4·kÜÔ"<¿»Á1#b”Àã¤Û‰½l!ûãCoN2_İÂ_mT·{3UØê°B­½/§`"¢ï9œd)Ğã©7yl£àô3KŒPÈ¼÷fA»±Ó—ùÄV>ô(m–6i=° ¨‰²±aRb"E2ŞO¹šĞt0W2æÄ¨gE”gÕEˆE5–F®„Ş,^’0Éí`óú1‡K:xs~H€ÊŠ—†ÂØ+´élüC¶ñæ³ Ë®|—Ó¿;áÙ]µ)E1¥İA–>Z°B‰Õœr‹em^¾b®ŸÃER’_Ü2šæèú­úYâ‰k$Ú„…~ ãŸğ¹vB#ßÑ[5Ñ@4†ZKï¡êBıúYAñş Òœßzâ;¯™‘Z,p BŞí¡fÜ¶O;Q˜XëjVšòZ›=—´şY²=¹ôŒô*Æa|x7üzyrGB¿™Ş**nim_*$ P5Ú‚¢*–<—©QNa£‡;¦
şnùšä»Â‹ ‚oÏù²Fè%ú¡'£w=JÛá®±]Sün«½`’¥,OÇ³T„´Rr=¬Aà°éx*ÛİeP–l|Ê+LŒnP=6u~ÒûÊ\N„ütÌ‹}ÿÎOçdÉ"ØiìÖ&ÛÍÀà,šôY¹¬{Á}ƒ–ª÷NÅgŞ¤K OM}Ñ>X1p«LeEdY¸‚'Ûro€¸†ÙœËÖŞ)ÖÅ5øî®l©û²•‘Åı‰«çKÈ"RÖv0L;>˜ÆyRm?€^ÍQ|hÙJ×ø>’İÄ±6áÈ^€€4Ç;#.¼Şâ¡ ”®eM¤l6â»š¼4İ8$%”–	]¯Ss‰ëD+	½>2ÉÂ©Î‘X¦´´TƒåbL¹>33Æ©v¥”Éë¿:÷ş¶3ë4«M3–±Å¶eı­ö¨ÔÏçf4Ä]ä)wLŸşã=…CDT]wN4¿a†³¡¡}ô+‡”uÇ’ ~kú·®Géz¹á=é)ï±æ
òá£®.ûWGVˆ³I<ƒ|€u8Ì÷}+Ï~u»¯ã§í´2‹ÂÀˆÎ(€ŞH¤]ûdµÔVk&eMJ•‘hÈ<#¯|+äñ´ZAåÌQÉ{˜÷Ïî•‚Uøf´`ç‰9¶ÌTs.7@ü!ÛÎÖp)Çx\¢¶,z¥?Q:ïlqnôÑd„àç=÷‹À&—b )qä\Ä¢¯…¦ïü&v›`ôÊE[z6áP«RLÚ:y‹0y(ı¡ÜßwË–º}€6ıSŞù`œŞYQ•šİÕ”÷H&F™~åmƒÎjûÁcZ¡¼eÂ×^LÍ¿PfqUƒ-X»¼Û(-8ŸfyK‘ÓòzÓˆIá—yA°úÿ@0†M5¿ÓÆØFaèw~dixUânĞCÒÑRfıt1GÊ}âÓş9·B@ŞŒâ:l–¶âoºóÇ©A«ÅÙÂ®¼Ç‰q„eÒ·ßª3K‡.ş•ªt½¾ H:’H¼¯H.«±dJ5+ixñ/WWE	ˆ*)…k™ì¦¾YÎÜïSávmÍægó~ÒR„èşgïb)Ø¦yæUN[˜Ë>ÛL(³ áÉÇš„±X<Ô&·zìO:­^]¬H¥ao0€Ì…4øtÓ•ß†1ç]ªå:GøXn¡rnË.2Òü‘o;]‡4û¡mâß ¹p^ÊXÿÿÅ#á&ÏoM¸•2Ô}ğI#à<×|-wï½râæ|‚3ií¥}¯Cø
¢òI¨{ãëm­`œc¶<apñ$aQŒ­†«EåË¦8ãœR¨,Šië[ÃW=z¨vrø¥ÉŞ½v‘Sf(¢Ç‘ãih4Äâ^(|Ù½ª:èé*9ç±¾Bzx&vş%ã·`¸\6Dø¿§$m5¡“úÑ&ˆdõ_TÎ#“Œ`9!ì‡
;”ºÊß­8!ôùØ¥}ãwè„º­ZS°åà~•Iœ¹ÛÑ'eV<@MŸ0ì­ıÑçtŠë	Pûf¿Wò‡H¸H+LyìÛQ ¸BÀÎğŸZ•à¡}‚=h¼ÏğÒ¡”@>g®Ä»©^¯	^núãô>VĞÿ÷¬(Ñ^ÃâÂ´vª°å®ØKbÌ‰5câø°Çç
yÛ§òKöŠw	-HØ¬1`ï`[=ä›dMt¢7nFBjÎÆ ïøäkZwzbhÄøo“jõÖ_aŞá˜.’ zãqô€D`×'ze›õ†æéÕÀßOÑ«¸íûòŞ¾«×é½Â‚ĞÇ;÷¹â6°]A.)#p:‚çı‡g]…¸«ÄIÈ#º·Ãó÷r˜Ò	9Ì «Tk?#ÀÍm¾|]óğÜ L)ÇğÙ²†´áøJgñOƒƒ$o:Ì¶Ûàs€	‘ó¦Ø·Ì‡í@h.O. &­İWäde=9ˆL.¦½‹\àDZÒX4>{ÖÊêˆùÈiÓ¸¢©Mİy×æb*ÒÅË÷6'g˜ÊVVò!:ğ"æÂ»úø=xçWyÂˆÈ”÷CØAxOUCUÚz*æ¥u•¼y5®]C×ÒSÂY‘K€5Mşes:·eI6‘Ù.TÿÕÅ3¿%æ“mã}~”*w¼V£ı*ÄãWJKs=åzçÆßÃÒíÔwû³8+Z^µC
çËê“¤,ùTÚôFƒœ—d&(¬ÓP@3ióZßQxp6~KÎAˆf]¶¥}ªœD%éG¾êqÁuå°ØyT£}<¼éú¯LC‰‘1s­9—>6¯Q#}pówìµˆÒÔşÍ€°{3úÔ‹=€ dã%mé&øÀRd•@«¢3´õMt4Wz«énëw;èc¸}=®rD8¼•G|ÖÁ_õ²	¢EÌÅA/ŒøÓí[ØÆ7v{„¼·ë¨û”<*fñÓúZâĞÔm³Ó†s(ğ2&J­ §`lĞ4õmX«®™YˆÃ°İø¯v©JĞöÈX¯k½·*Á*uCQra—·a¾¬:dDvœ\¶O8ä¬Šûfxé¢‰ªyè¢ÎfßC{|äõş¾*»ñJJâÆhu5IgD%}¯§(Û,‰ßôİø}K¤MrÓ¯MğÒˆ!İH AI#¾îÛÄRÕ
¹ºí0šäYlûG8{›b')‹ó€:¹?¹K[ëàÓ~=…ğ)†IJ”-Ö¤GJ?¾èåj–hLCé^#Ç1!>T tr}ˆrí¥Ç¹„ôr§‚$
Ğ˜˜ 1nÔ}¦p¼¨F*Œho”LÎ×Ô`¼R³Ò£AO&b=½´¿gæWQÍ½ Zúß'1^ÿgxm±ĞV+Ø¹r
Ñæ‰8â¦ıf¿ œ2Ì0iâwÉù5•î1Ä-O î¹cÓ.]oAÑ£Ö+æU'E(vyìÅÎ›İ3È“m_s	 éÄ½d©$ƒ½a`ñÏgÍd<ôLLô!±odo97Ô^¯U£Cl¢‡rCÈıÍáƒI…¿sîûĞRü‹“å½#Yú& Èh!jÈco­Ö°ƒà©ú!w}Á€›°…	%XÃ€ªVl w©Û¶"‘Ä"æ{Ü¬*a¢ôÁ—‘$|³å—¾”¨ÄbÁËTg3ô”¸q¤ÛÎ˜dk.{¯Õ¤#«7l¦ÇÎƒ!EœÑ&8P*àLÍŞíbÍ¨¡’‰P¯u2-´pì~ŒÓç±ÖU[¬B|¼Ok²±ÒTeù6’Jlƒ(„]¨ÚH	 ìZßÇ©ÚñtKƒ›J¤Ww@"„±$ÔHN’•À)şèEE	òtM0Ì!D]"~í·d»8‹pµªR5%ô#VzÌ¡c)I± œ‹}+- €Íe5UÁô¹=_¾Ì°©€ÿTû›³ 3t?qp¬&YKìÙOµ£–Rn‘·F9t}÷q8 »&+—Kg–~N&kÚŞ7‡Ü<Ê2°»ÎÄºüÓDŸÑËÀJqqê¤%î7lj®W¡¶§üK™±’…:<o,×$7%‚RDG8mÖoÆæMT„=6œŒæ\~€«g2“Aü¨˜MF°Ä“©¬¥Lé3£W\éõv1‰ã03Ø±ÍÑ#¬S[h|l,Jğ¨4É&bÔ-ƒ†jx}H03¬½b8Û—°ä92ØVõFÎ×èOÕaüY 4Ë:¢)bÛ<ü#ëX³PK£zsË¬Å—”ÄZ(BG…'k£3+‹§ĞI€CÛY¦áïzìÛÂ?+6ls“zßÍ‰)r{FıÑQşg¹œrµ¾¾…f!9Ë6–e!ºBfá±÷¿šÏ.Úr¸À¼¿`”[ÛÚ¢)%Œr¡ÒÉ½b¸6“”%ğs—'ü;„}lÈõÉ€W×Ì`VÌ)jŒM¿<ê¨)¸ãæè©9=_lÛT¶i¬šp>ÂôsM÷Æ¿ƒ£
3'ê3â"Œ~’_â$ ^w)3¼û¥{!îÚ¼=%µó#¿ôk¼kpÅ’#Ô†¬	–j‘ÜkÚáÈÊ€ÇNb°§˜E1x	ú”;î~€ùMÛ¬M#bŠtYØµ7¶«Rwš^=¥W¤O•T™FõÜeZ‚[eM…­Û
Ò[é{şø&‰ÔïÉ°î¡½¬"¼#vò!²¼Ö	Ï"%[¸¦šO8AÍïÙı+9£%à	æ Ùé…¯u:£Ê±5µA˜vè™z¹Qàµ¬Ãn£¦(=È;óeT¨fá^òm=üøWCZõ^2o`Çm™I_£UMU!÷NãNCfõñ9˜˜tvãEJµ™Ôv&îƒ¥·t}¿¹ã´ –¼µã)»W.Ú+bg¼|Rİİ:ş‘ç¦¾añRÙ^Wr¦[25FºñÃ4å‡õ÷—º“µÂQìi•t%ªWŸ1tÓò¶un~ŠM‚é9EsføvW¼ÇÍf’&Y‹«Ì,ªnN9“·˜½„ Ë)TyÈ+•h;¥ÉYŒÄ³ÉâL‰zRr£CX‹É<ó™”Y×İ àï¹z¸+K~51I»>†^!ã[)r¡Ì†Òâ{«x½«¶GÂ$Ş£%%Zy*Jã˜A_oÑù®$MÍía³˜ÎîÎw«HüHIÅ~Ú¯Á"—´Î\3 ğ’×^”‹”¤ñ½îWı/‰£àÔ‰Ö0>~_
5²ìœóòŸ)O(ÉößÔùmİWä™D’0äÛ^sYÉ¯j@¯etÿ‡dKÕI
[ïQ{±=ò»ÕÚ*=b&Ão—ÂÄh	‰?Ê:K.ä,£cLd•o<JÑ¼òÈy¨íü)­–uåÀXìüNÄÿpÊ¨H£ü1ÇÆøÁ$t¹!ÌeÑíPßÕzw}˜™³9G“ñXç1.Eñ.‰©?!HQ%C¸PŞâh8®‰ÒÂ?]ÎNy=!Íõƒ(fÛ£ºñçZ@×ò•˜!ÉV‚Å¡‡g/nÒcÆ°i•§úQ—µ…Vù(ö½©+€‘ŸVñ½¥cÇ¶4UÅíğæ½àûfj¼ÉCÍÇ˜úÑìÊQê`¸hi0ªOèı–ª4İ\H½q,IéĞD°èıóº`äVùW¦g¾µ9ò3Ÿ%{zÓ1ĞFÿ¦áä“=£ñ¿¿Ò`EPa4W¥árÛ9–Î"Z´43Z¬)×‰vX÷bÚ1Wí3×¼¼	—U¾É5?åÀH$Ezé—ğ«{#ÂAÓPE÷œô@ÆÏI´I$E£µvqKH&÷¯B^Æ‡<o˜y¸ÅrÕôoõĞŸòëï‡°÷¸&VÌ»iÜ2÷ö¥FÃ:É¿n%´\ÈåëÇb÷ÔÊY·L³ •î²LrŒ¥)·j¨åşSMá>5é…`:.‡í/¨½c(!ú€(Í[l‹\°F4üµ|­èeŒ¥„ä`Û$šºîoq»‰Qç¦¾_Æ¬ˆÜ¼3© á€sÌ))t*k/`[æ%yÏ@„·G9Œ>uDNpôb}îÜèØîî¯¥†Ç³æc2¦Æ! ‘ÅBÄÓr¤%¯uÚÊ–6WXä0Ñ†O`Èêöş¡ö;d¹»^à+’mõ’¶Àk¶b‘@ŒİÉ ®'†Ë ç×½9W3Q-A GÛŒ•©½ÖODÊ%ªúº0‡¿\ñyhv¶°ÀøD¨ÓËS€Tš°3¡Ğ<óê±(wõìOİkL¬;®·Ö4—-“Ã#•x/„°ßÖme¦Ÿ”ÀXáË»rB
3åXñFtµ?Òp-3ÎçXRÏ¤Ë3ğ:‰Ídìh	~éK­ U¢ÊçZõŒÉ‰{Ñy|Ÿİ²‰SÙ‘Cqg•N(ñùF¼«÷¸„Abv]NøÚÂZ…ü2FÔ#·P³9ùİ¼,Î»NZyJpµğç£ÑıûõBŞèwií†ÖËZw3ÙÑåùLØ«·H±o.?p™\ä"P}»oCä\Ï,I_×AÉ”<PIÌ[—ı0i¹R+T}	›¤×´>è‘1ˆm5ä@m;nºÒÿ’½»j=ÂZ¹‹2Ì*'pĞ˜¶’…ó”¼q[ìõ#§ÆúJ¨ !}].qoÅia.GÌ¢Ô‘x ª±V¼j/	ëO>ïî@f>Mú­¢˜í¯Š–ãqYÅ-®ÖcšÖaœ¼qç‡oŠB{jS´ì#lµãÇÀ½Ëßdû*@íà†i8§iJãÍİè¦0Éâíí¼‰©{Cà²ñEÜù™ÑTµwğŒÅQöÏMZX~}çc3#ï`¼’,şÏÂ¬8ø¦êXrT]ÉşÕµ¸~ñ4^7ÖË~P—CQÒ˜Ü®‚¹gJŠ‡zQ#è+ÒR|f x‰'©ÚBÔWë|oìé®“Œç«Z'F·lâ7«&ÎÔÇÄ£m€â_Ào“Ug/c…wXå¹qÍ’!Üyd…µïûÏ*¢úå25åÜ+o
Úİ˜’~«à÷ÓeôçXQ.’ºƒŸv*_§l‰0'?ÀßZE‰g›˜ŠZó‘w%!şñY/j_qœ;@6ìAÉysf|XÈ®	bB>vÄÖÎ²ÁÍ¤Î°j›ßC¼›Í\[³CNˆ”ˆ7¾ÀëGÉ±	™È­dİH69PÉ:ìúRÇğj“zVd‹J¢åßˆ&/¡uY-è n«à…bs§%¯3­=Û ¼…pÀÀ—mSB…Eï¨¨’1»$Cp¦µ7©é;ÃûZ€’oU[ˆ©Şx¡€s¹?Êa÷oùïXàV>iU¼´`Pan1ŒAic1ÆK¿‚;3‹ó{f·×Aˆ*lÅ™dá&³ÉÍÛ²pº´ôÜÙÍ`²‘ğ‘qæˆ“XXÒ…¬°¸Tz{ê;J,U@\‹êõŠfTTüa}ÀZÀÖòc‚½‘{V÷Ä7r(‹®,ŠNJİ¼’@8ìËŸ<ªÁwÅî´w{/T–O\
o¹\¾
æ“iodÊ¶ñáÒ	ÇÅZîÌâÊb´ıLèpI²ŞÏş/bNT 3RAüÈûàö÷âóF½Ñ7®$DŒ±•ßIÓSÿÏœ¬¤×õ›şöĞã;²c<Ÿ¼Íe+;Ğ¾‚3ÓŠO/¼ÁÇCJHÚ,òf•n	š“•¬Ş¶#­$u‡¹™ZÛ©’ß¼§c±Ïbß¤Ã‰7o2ÔoUğ@´ ¬7Å¹üš…"ô&dş+ˆíèJAÎÆ-h]í¬7ºÇPú?Íö³æ )	)+eËü°Ánü[dëBû{”-cûdû¿+D’§v(âÿ~Oi™7Æ#âqRÚõ;õâ‡4ı³şì±U¯Ÿ´Ìj—
ÖüÑ6ş¡n¸RiLıñ®2 ªÖ{áœu³¬Òõ¬ìÜ]pÁ?ÙKÓŸ%È!ƒJ”JæõÙ‹ìê=ß1BHRºØèvR¹&×õÄ'À“ø#¨Á?åQònf•Ì„¢‹¢T`‘4j‹btJ4O¤Øœ»{ÓÃ¬}‘Ê/Ïf(ädÍN`°r›g6úÂá2=úA}m”ËtTJ$	7>Ë•û~$ııëz—®ÙÛ2È‰zÉ¢%ƒ.Ô²•…SØM?÷“×ep?Ö3gnÏºíÆär‹×ª8õöËÊÍÏnYŸE¸Õ\í}¢üÃeSŠšTS¥¦Í¾4=ëÏSq”éØ‘›V¨ßÀØ3-jìíd:àcbm$rGa.§]+™0©@–¾ázê‰µe—ÜàURßMb›“ª@÷¶˜:3	ı~ºÓ&df×:f¡w:äïm\¡Şr“dWŸc¹s8~çııA¬UÙõ2Ö\!=ù_2/ŞÈ|¨5à™9nÔ:Ÿ5‰¶^[!Öûu™^ˆø3!}÷`k2(ãP÷»¢€uû€é<x•œÓåı?8ÓeÉlÊq«{ÕãAICá;™jê1zÂ™›0~*4S9`»ESû¾ßEŠÆ’/=vb«Ç„(¾óñJO'«&1ÛN:G•öjÉw"Hv
ócp8{®‰Ê@l¶±u—µNhµ£š”ü^p×X9®¢RaâN8Sá>Î¹l¨WWÉ÷ÊñgeUÎáêùóõ6 †g‡Xs-kbt~Q˜éLE“Yéƒ©­DJÛôW}xQ]6q­U02?¶©ªj’’´O=Q3í3”˜ÿUéø›/˜ ¹u©WÿÜÖ†]hÒE¦ıÀOS„#ÈÊk%’ÉûG´ı=™õÅ(ÑÃÕÌI†{¹¸I§€ftt¡§…vI\(ş²ÚÃ €-PXKø•)¢*Z~U53©ˆÌ±w+r¤å*Jú/xL²;Şİ;nqoãÔÛeŞ†àOø±òğÕ/ß²¿#Í[`1çv×†ÑıUØOlÓ‹x¢ıã1na¬×öÑ·|ôgûiÄL¯ºXô+‡´åò:%­â¡ÛKjş@îÛI?ˆ=f	Ç¬õ¼r„óÇ5,§‰ÁÀÊ²ÇM´o†{³½¢q‹¯ºèt6 ÁßakÜÖº˜B‰šˆL¦´5	éJÌ¹Şà_U}kÀ¢yİ™ßœäğu@ø¯Œ+Öûáím``8Ÿ šP[`¢¯W¢ãˆ›PY‘Mƒ»‹œ‚‹Ó‰4Bä9—ZøWòŒĞ?¨kóƒ;ƒØã5Î®:’gÖp~¨Së³
¹ÃÔÅ3?¬…<# •PQÇZqHæ¯©H¸¨î÷ìf=ñîˆ‡Gş†kªY#ùIÍ	é³ ƒ”wÓÚØšáÄGÆ&ÍŒ…yI!­ª9,Ì1¶ˆXwQ†Ûúwta![€‘ä[ûá¡”ö‚œ_Ú¥ÅKx±¤ôBu8ú3CcX8AÕe(OÙj›¨ôlï‚';K!3ËÏ{ùÆ%ö¦¶)bKfˆµFq¨ÄÈAO4r&mşZ0÷vê+Ï;tÄÍ³İîã¹§ˆ÷ùe°C•™¼½FŞ)AP¼z 1êŠ‚3?F<T{™àÅ˜c=,ÒcÎïuäÍz-cŠt	^“!·ğ•nùã‹½È°DÔÙá(U—™¯‡ñ=Â`½æŸËˆ°ÅØ]8Jıá_«FÊ³ÓËO,ø×-.Ã=@d“ŒıÓ>^Îº.¸°-ìã;)jò«¼›”Ópd¸[‚j
sH0§’¿è‚Ü?4›•å¾›¿€3sˆZªÃä[wnè©0oÿgÙ Û„¶Ô?j ‹À+¼½*µŒÙ…á@ÚË. Î?³‡ıbß}/N±q?ĞŠtÿÃ¾È}kÜöÄEşÆˆÎÈÅ:°Âéş©"§Z×-&ÌíNAˆÍé1z°5‰¤6Q\:ûJO¼Í=÷	±Œ§ùºşË½òÀÜ¨¬ÂIJc£wŒ`}5‘-,¸Í-54ÕP·ë~•+%dš_é#õı<G…EqğYk3t»ò¿ØÁ‡ÖêyH}=£	†CÿY7'ÀRs­ùØ‘c(-sÜ¾R‹t ®-ïl'Ï­×ü<øywio¸jµl—…R7]ê®Æ‚m´Ä“é¦óÙñµ¸ğ’œåKC¿Ï'»Åès¼ Ğ¤}\™oªléµ„¤İıºHÛ, H+bÒ$2¹uô‰³ÿ 4ûç|æ§[”ÙR+|œ6¦(ƒØ"ş*¹ò%¼Äy^cÈUÏÎ~	©œ|”½Şğx<jÆAc›  êlGBÁšÌ¤Ai´åO¸cKvcÜQ:ÌÙóßâ ÒEË“•3
›b4n¼eÉƒY˜Ö‘Læ;¾–0¾|[üjFàpA¤DGİ}Y×’‡aøÚæ©[µhL*Õ ÀQe]eÈ¿à€9’ÚI0Ë,F6[ú»ÓŞÏûDøÇ<‚"îÆ-…v…ï4ËtlÈq\ceáÓüHZcªê‘uyêÕU³råØõC»§ùŒëÜ›áB”tOÛëcaÛı@s‘9iwcILId­B—N$w­ï¨¨IÕâ#E$s{%“9Nóoÿp¿ûš±b5¾gv¢#­ªE‚Ç¡ÓâÔÇŸŞG{Ûë9îÈ_QúÇ„€<¶Q¥«c‡½\Ï>iÕ"®É,Éçu­<ú€Ù®p"	¨İº¤wí]îN'òó³¼X‚-mÈö›2—*ŞpJC›¢ëZ¡|ONE5àÈÖİ÷ºÁl'Éuw§AXJ’ÄÊ–H~z³èšP+áñxŒèIÍSú}€YbYuˆvÆØPß,Øä’ØUEßİ£ŞOˆ.â:Ü:9­Gq×À]''üÊäE¨ÀÓÅØ=:Ûø|€@ì©ñqœ~&*a )—[³tÕzÓzY›Õ~_<:ÓæÁ‹ "­¬³T•RâÙ i\Édë¤1òÊüwï`ı=ÖEª…8xò„2Û^=;²„ ×±Ò÷-fY1”ší'V50Ö‡¯×l º{TÕƒÚØvQñb<P¤ÙëğñÍ]¹Z	ÉÔ4=Š¯8<´×ƒ^>à¼å ¾ƒQÕ&!ğ!¬L7Y??<ïY˜<‡­œm¡ıáVÊÊ9^”ŞÊÖ•	kà«!Q;ùúÈGÀ·ñ(Ìêú„³Xs·°°eÑ;ÕÚ·ê€0…óF¿f s0S…P»~L›0raœçà‰	Ï)†Yy.šTl²2c,Ì¸ß54æKÛbfÃAÜB;€  “E—VM”,z†d!µËJìëÙè>“dşNªõ†IqÍ>o%3÷<g¼íqêOñ1 r{1–®×:v»–á'êğ™ÏN¾øŒÆ…ÅãjÊâ>)Ò™ÔŞbîg&.%Nô0Ù[)7¯¥4ë«ÇìÿvÖ¼.ƒ•@—Hc¦[[õĞ03B˜ìEQ‰)wk¬dü„[Œ§]û¼„%şğ‡œ>¢àR7¤G©3®Ñîø K{ÄuûDˆ‘n·>óŒÉ
¼QÙæmjBÅ(ÖªT‰çm£º±df¾‘Qmî_UˆhbÒ:uõj²B^$$›@Aœmò(éD%Õ¦>È¨³°«ìÇ“*ˆÒÿêÚ8sÎ\=@«jÓÎÕtSĞÁÙ@´,“åà¥Õ²ï¡I&P6ÄÒŸAu¯°‚0™'Ô<HºQ­DÉiÚËv?„[‘n¸bÏ‰­ÚØÀ#(VÙ¿/C›TvŠh›Ş“Äô!ËEû8Ìv@ÍR÷€ŞóUòA<ø•Jc°à0o#Ïñg²J¦òÇB7ö¶ü”³+¤{œŠTŸ·J8³úÄ["¸d:Iâƒ×^¼pŠ
#ø'ÌÛáÓêá¾~mYNèÎôäç×Gå¡yóiÏ«ñ«ª[±æú£RœÃ¿1ˆiQ9¯œ*«î[‰£ª4fø:Ã˜U	0ÿedĞ¦ş·êVå!‰O—…a­:‹!°¿>s7ŞZ‹•º®İNâs!c2CàLoº(ˆ×6FUQÇğjRÕ™ğpÖ7:io,†®'P*KyÃ=hÿu‡¯wB <y·Ìƒh¢Çúã§dî¡^)_;L‚|‘­=JˆÊíJ!!Êİ[,ıSa?È5qÇĞ›P\}Ç¼·¿-à
ZlÛì_ƒ€Ïx9O¡>€õØ´ª\3É£èåş_U‹7šØÍô°ìåà~”IÙ0¥7÷û¼€†("ÍÒAq3İwöëš4i:-jµ.Ø»mdt¸Ë*Ôş"#ÊúêIûİ HŸkQ06FÍÊ€—CYÊ98ÅÔ.ÿn17ê¿‘,3Ï8S†È»ş.2y—ÂÃâ VK¨a|ºìÀWÿä}½‡~ë»áì_–—ôÓOHA£¢Î C¥”Vm¨¢+¼l$®Ô†Ú_Õç=!º"€Œ4c¬ÿæÍß]"?»†®¸ZûÜ„»Sü	{¸I~‘h ™"ßñ£´oŒh7°™ôšòøö]"îå~Âİ©½•¤ğà$•’ßHHq[ˆEo’;IÒX†85„ÜÉÀ—ƒÎªW:ó'Æ4 ìº¸½ÒúÚôüğMÏÚH%j/Kà Énœîdi\ê²¾9’¿ìrü§·éåj$á¤Ù_¢—KùÖ»É}<ú­n0©Ï.†sÚ®]r=tÊh]T$íÑ1tFe@¼­tTÏ/¼èì³üï–ğ¡Gì•ÖÀ?¸²aöÔÏMQ,ÒgÛ®|O%Ekd>S%³è¡{_…
WÉÄ±k•³cë÷c‹F„pLñ}=9ŸìŸƒl„özæ7'£LÀ­Iñg–(„ Œä©wîÇ#‰Jáó>œTÁ¸"Ó)×°:½W2İ@·ÓØ0 ¾¥¥Ç§‘®2ÖÚ‰Y OœDjD¡ÔQÓ}š¡8ú.CÄv'›‚"%à
[3³2”¡¶ÚyRíH ‡Ko|o‡ß‚9šÅôÃâ'­òó`g¬‚%7:hÍH}VjÛı¬kş*OtÃêïÜÈD]§ÃrÅƒ3™]/¿hû\æ¥Mâ…5½¹‚2OrcOI?‹ËØ{­Ü†Cå½À`±@–½jöç`8°ıiI¢ÃnÀ®/5“ 6B’M`E?£zšèƒ…·ÊâÚí>ÃÌNMO ãZGlrô¦kS‘øç·øç$5^ùë,¯Ïz£ÉI÷Æ¡*Öş.iğİ=\Ã¿"1@G pÚYöV5*W·Á×[çO‡^~»Ş¹ö÷ƒYoàEÜJ5òÑK>*~˜	…?Øfeò+º4Seò×`È2W­öjÚ%ÄÆœ¹… Xû+Ï[İ‚(j‡rB¾}ÌÖ¨õÄô²}ûÿßœå2€Ùf7Ñ•—|‰V×xò¾™S•Èzæ¿îey‹7£{K2wñ„Ü¶:gjûG÷Å1ñ«:ÈÉ|ÎÈĞ/9d½Õ5\L,Ü×‹[îvÅ_Œ £MÊkÎÅl$kJ ÒçÜ€Õe‡©jT^ögœâÄêNôUª,4PóT>=m}©|©d÷: ‡³à=ù„mÑQi³œkx£İ_Ga|¬,L32Œú·:ÚÛ+«—SÒ$Yº~IêÅkDuãÉj:ÓoÍâ¼Í4rAòİ.İ»œr±õbµ'Í¡Ê(¾N2~ÆrLä¸ ùŞCq‰ÅIXM0ºLœƒ¡»ÔšGmìuA)×Ó«usÍ‚*?Gª|s”OáDñ×±ì¡˜º¿1}‡ïòÎï”×&¬0gkÅ'8§
p–.‘ªø5ÿ€¿W;E£ÕòÉøsMYQâÛ¦€Ç}ÒY$¹(Ò‘2eä_D&vƒ;d“f™ªæøÅ	CI÷wÆ´’Êë‡<{œ«\ÓÇ%ß¬ûŞ©î"’Q:%Âf²¼ ô‡G÷¦œ{î¸]§.j(èEVP¸<ØòûÏÚù X;š£·–d¼°0‘UÄÚw¬„l1Ó…âÊÅUè©ç‹›ß.¶áÌ»±œ ªkÍ«eŠRîÃs0ÈÖÉ"~ŠÄÍ¡!ŠŠÓxq™[GsD'×ÜÊ‡³hÌÃÚ³y=h­ÅˆTã)mLT'Xi7ğ«*ˆ`¤ğñ\Æ‹íc+[Ÿ6Ë^¾éTöÄÇV’Úëe šù½¿Tä [Š~Rn3¼HŸÑì)¡õŠ	ogöPLäjóå9³ivù¹î<ƒ¿Ö°ª9ƒÛ¹gÆî¦±ì>8x?¾xAöÁÔKŸ4r>V¸|“dÄÃŸÀ<F;ª¦«û‹j*Jk›’XÔ®»A%hmd…jÜŞÎò“ê†6ç^gÜ}˜f’TÈöqrFnp»öå yÎP×¾PŒ¿ ïj«—¾àX [¥p¯-z¨K›îˆù¸á÷+´ê‡z³*AÀš_mÄn~y4v$.9]É¼ vLsß=vé3èÖ¼g«P¨ukû;)÷„ÌéuP³™şøå
Î˜¨ôˆ\7‹TamCÕa²Óƒ$‘”›9Ë¡zè,~ÏÑ:Ì/]FÕØ+s½S®˜üvİökõïG0>®b‹QÍÀÄæìQ^BZ'¾TÌÆ”+›³­{ıd€)“8y¾M…£˜ĞONi::”©@Î%¤ü¢Ó±Ke½ü¸°T{ñµm±à2¿u}º·$;SIùK€ìj˜~Ë!÷¨5‹å İ·Mbo¬¥¿Íy¹ƒ|2PÓş|ÏøC‘÷oO¬Ô‰;N?š<şE2ö½Pƒ½@¥ûÃ7BïRÊ:¥-C³ßJğÈYÀk£¾LW`ÍqSúÉFÖ¦BI³ÄöN‘å\Ï&LHÿ./œØ
ølìyR×ì¤ŸTÇPX'ÿ-şÜ!î×ZsH3ı"„ÿòÇ!^£ÿ9ğh_°ïêuyŒœTLâF¡Ù¨zuéUÅ}·äŠØ-C9%7ã9Z/"»²ÊÂ_ÿk¸a€¿óÕçÕüdÔü’f¥$~|@+©­—&Yä¶¸C›H÷eÕÌ©}³^øl3äşÿSq´dÆ6Bìv&ÔuÎ­ûƒ­Êó„XLù–±ü!§*²Î|Ç‚ [•Ú”—fwddEQßhüeŞŒ«?äŞX–Ş°‘0Ä>7òæò„»Ğ 4şAùOıÈJÄ#xàÜúPŠš7y=å´jòh¿¢%ÀÍ(%”XÈ0ëóçt]İ…DÓjşÜ83gwUÏİış‚+D^¡ıtòç $¬³·…aŠ‰éVç‹Œt#îïÖ×ÙC´ysÕÊHŞĞµuŒƒ†äÛıæ(6}Õ/‡³,şÛ÷;9®\cn­K™Õ¡iÉä\]#&Ÿ ´Q"èÆ‘›8Óšé+ªİ©ØìÌ~O~µ …,TÛìÀŞ
jùêjc60+®‡²j‰¼Ç|‡GñhŒe%FÎáÉÜÇ‚;(jÙ‘è—³¤¯×+¡LÙ" {­#hG:J@UÕ9ÜE,y‡+Ï@Éx/hJ„2şòšñÙ96Š›¥Ì<Y…C	Iøn!ioÿp"û7)ßUGz>÷^ÊÊ\zjXºCg ËJÀó@IûEø¿jLHƒio=!èI "#2¥>—ÒÚø½W(ka^¬ë—0É"ü}h@ËŠ¼ËµÖØWIB;~0q¡rÿze7³Ú¥ı¼¼FLBc2Åæ–Õã—v3&Òr-Xáî›{¾ ÷rÅ-?÷•v{$^ùSu–Ú¬cNa“M—dŸL¨£®)Z!Y<9W\.k©ÔisÅID„Óµï®ı#ªŠË7qı£ƒ¼‹cZ…¬»_€î£(<ªG0ÖwŞNÕiÔš®ôFb½ñµÔúh)¼Í'³tˆØ¡Ëî™:ëH8>d¹£¾Ë2ç¬Z«üÛ€êU1Z	1çT’ñĞ¶zUóÊ¶r?¸EÃ052˜Õi¤)¦ŞÏö,§»M‰
§qÚíH—¹Ò«òmÓÑKÙş“@ ¯Øúe‡)“Í…ŒIYÕ’sÁá]o¦>÷$oaÉ·T?3ö+‹†ö›^a@Ü½´Kæ„ğ\‹ıÄx’òÂî§;›cNà<Ì	eúâ›)N[trqp23ª2˜ˆ±–~ùˆaÍ¶èiyp·óúdÆ:±~]Á(l¨¯ëÉå	uoÜ:Š?ÖG‰ÅSìTs´Ù°†~á ™á¸EgÂ@MŞ¢9¢˜G7Ô?ãà¬[İc…áƒHú<=©—èŠrB¤çqp€ô·Kıª1ÂD"Û»‘¢Âì•Â4é1â“Ô–V@ZÜ<{t•üLÈ<>ÂJ—>f’’­^ä£Qyäü\ùèÈò²fuË×åyáºAŒaıÆqÁÌÔË.¬ß«ìÏÕ†_  œÌÎB5–è¤5ÂÃMé ï/œ¶Ñô4ù¿"³1!·Ş#¿up\M0Zt´à‰Óô˜5ò%ˆàZŞH¥;ˆÒXãæ.ïgŒÆ„ßÜQåƒƒªT÷Øq%z3ÕY&ÌÕ)p¥W2F]½•²PPµ€\zè/Î´®ô÷IäégÏÉ˜@Î¯”—k‘ èbëN{mË9µ¨½ëƒ[öğ±2ÑÑ#Où÷¹üé³v!%Ú,;îæ+Yå{ó<{–l¯¥1Hµd iã¬¼İ+xÄlğÂc°½´Œï. Lå9¦¬•h;©`‹ F5f×7#K¨ç˜ĞĞ•ånté¾ğLJ¨¢%¡c%óŒr
ûY|]éÕX¶HüÑsø‹LÓ…!
¥ÁüîÈ+ÑLÚm/–7®Ìæ/•¿×£ÂˆI‚ğŞhƒ¸ ftVNş¼±ÿX20¤º¦3"k~hå	ro¥ÍLlóiµ…ÒˆõWiÇè-ÕIâ’Øíqå¶"Ü­€Öª* ZDóŠä3×ìg-ËÓB›ıŸ³GŠìòÿîCG" ¥tJkDÆ|ñã¡¢GŠ„„¤XˆñÖ[SÚßÊı†£Œ
­)&m£.bg‡Š!:U:º’•)\U÷ìw/*w“aá>Š@$÷€àİ©|£±–YLoƒ·AJÍO)·-¯ÌMJÅE“é•ÍÒ˜vuÒ@ííq–U¥—ˆİŠûeJDC±°âL9<»ÙüóUÔíˆèQ˜@Úîé*.^ı1ÿ%ÔO©P`¼9v ²§)¤S[M÷!?/ÃqÚS†+)2í+”uG.)ùm„İD~±e«6øÏû7ã˜¡øhïª0p4Ó˜i†N¿şkç6f“¿MM•…“1º‘×ËI¤R¼w%ş>N68*.OÈç«ìßcI0ÅÖé)8 ‡)’Ûá;h¬zÒ7º)7Jµÿ¤š_/ÁåL1ĞÚmØ¢í¥®ì@QbvíšùiàŒ{	®
Æ–¡ÚH(.¦¼Û~p¨7’…ZPá¬ózazp˜İÅÚ”N¥œC€ÚîÔò…Áâ¤Ó^„Ò(jµSx½Ë0»šê”¥ìç
4-…¶®¥˜È4ƒ<	ŒLïhÑkbÆØeüí=Ğpˆ
é’©ì†#ñ$Å73Ÿjq‚*dª7¬ÑáŞİÑîù@PçÕ\—]:âş…ë„	H «k0Ğ¿ ¯@ëØa3Ê]¹ÁoˆIQ\´—ˆÑËMfI’—”;Sã–7z…5ï`­Ë‚z°úw`jóïE‘WA·oé`ò(í^^C¯ìwC›ËÜ#QJ?lb H—şæƒèVw3€8Õ"tRYÌ‹Q¿vÆCDô‰º’·eÌ®{ccKg'Çk1¶XDevB2ŸzYl²ÉŞWÎ»:/o¬áÁL6ğÓ|òOh[òzÏ$SíÄÙL«»z	ÈKoRˆ÷Û$7"ÙcCÿñÉÌ ø '§ä¸–¹}-ş8sd”a´Ç!œ•›{JHŸSVŠKŠ/gG½^N‚ÿ¤ »A²ò—ók™‹¨ÆØÉÜF¬ÑñfFå"r^ûí:YæF€²D’^L??ìŒıF¾—
Wˆd5j£J³Iä7 ŠëÈ†–ôˆâQ¼¿;+~jUcä‹7¨J-+DÍ±	Û ™'~ïrp ëGûz8}@6M‡Ym°_øz»b×ßg„ƒi"ÜÙ—Ag//¿ÛiÈéÆıxoò“A³ØÒxÒğfb+‹íÏø\‡\fQ;n'sÃoQŠ¹‹F!›G‰"§=”ıöõ\ ê‰LÁ‚í|z@\1 ¬Drlºù‰­ 9¬R g^-Úá¯ˆ‘iQ*l‚]Iô5Şm££sŸ¢ŠõR hâJëˆõ+¨ñ$·6¤û?•,Z"(øg/4Ó½Œœ=ÛPgÚ+šYÏ­%îş:à¤£ÇŞ«6ØÚÒÀ”pP»hıŞô©ÀÒíwU4ÉKõ(_ei³-aeáI“Aìò!	~’oOåğÁ‹Ošª	@`0ë¥6ùğ.Â[`<ı]£QWgXsÛîxXl9Í½8æ`™S`ô»¢cA—aÑºÃ}o/@İºïLÍû†òË9wUg;k’ß"ÇH®=zhW ›	?-‘4L8ùÒ©Õ2©Äø»Øñ™‹qšwº«ü¶YTç¿e„.Øw€]UQšöşjß+"©RvèIĞsé"ÔØ¸ŒRJÙsÃ0ÆœAƒCİ>2øÊÈæAzoK<>òĞÃng0‹—õÙÿ¦ùâ£?\£§â-˜¹‘ÛÓÔÑÁñ.GÜv#Û<ƒƒDì‰×;Ş£q‡µõîœ—Ë:ìÀ/n7E ,.„s}ãÄ!ê†1•\,G$G(ºåjİlË¼e&Í.M¸t>¥û—C„“£D´÷·¸lİï8\Ói¾Ëêbúúã·`4şé§¥ä§•ì†„ØLÃwO]Ãü“ÂÒXI·Š’—ZR¡MKÄšıÕÈBÇLIYömİêIÀLsBÂY
"U8¨NŸLæb{.ƒ;Z²šÏè”pïêîÜi˜O)E•ÕŸEêm¸¢ZòÃûšFDı9 ®ñpR
ó<c	ÌŞu>¸˜ŸcY_UŒÈ"¢Šgê¶¼·&ì¢Pìp“˜¤'$æƒZ
«¯ ±x)8áÅšÅx~œ¹+cŠµQ—§³NÄo)‚dƒÛ !«äÏ·Óòİ‰ÑÅfWuÎãHw5¯J”¼2úĞü²¨¶Èà#¹ÙQ[ë´¸ÚÒ„…ÄU¯K[+?@ßÑuŠ»ËæO=$O.bÆĞhæQºoªÚ‘nêıRjÔˆ™‹Ñ,®Ëô†¤—×bB*mNB•JüSü:œ$²SãĞ„{BWó»N²ò17e§¨îÌ+H¯A‰ó=?-=4î]rBF3^·‘î!õeì
Š~f‰øEÁT%J2ŠÕŠÖJ[²ÙÏ<¼µfdrÑÁÕ¬Rí²­U]—È>ºåz7§$“&È$ÌØuB*‘ı&•›<óÃyYàñ˜·8 ñ3{ĞÅ’F>ahz&7X
Ü¶²ec³?r};É OÖDºÂË>şäì o»ĞO #eçäuè±QÁusC3Uç$9İÃ°Sz²#Úï¶» “ï”$±á^NíX3â²çrêÉ^_’ç:©_çÎÌêÂùßı[ˆhØÔqd¡¾JÎÜÀXX*2Å	]B½oJQ¸åûc Ñe7q:ÕJw7[–Bjq:Ín¬µßQ`şe‡—“]İ±^¨'‡\ìÎ÷ı²me±¡ƒ®ş7. lø>öhGf…W[Ğşq’NùDªlh\â¼A$0˜†cfì>ë(­¸y9°îZK„zË@ƒ²$ÚºüÏ´¯´B•¢sÁõ›„Ç¥ª¬é)É»¾¼5õŸ¤+u £¯¼q
3JPÑ×<Èa;ZZ¬ÃJ;kM¥uƒc àşÅXªÄ:}ßA½?Çéój?têåG¶—“û¨:Ô­” “H¡ëë.öì
šĞ$í2C¸õâ<Û(TĞàIMA8óÃËa.çµµ^6Şí€„HÔ?é²×m¦ø»O8İû™±ôív¼¡ÓËëëÕD¯v¹=F)P÷±Ó_MC­VŸË2ÇBá;ögİeãØL˜Ÿ|0²QØyDƒ#ÁD®DL¾¥Ó$;>²œ›b k¾Ît=Ê¦1šPu,5LÃƒ*bX1úîÑVHN4SDZ›Æ§F=[ÔÂTl	Ç—Q>`½5^æhÚ®ÏÑâmŸ)ªSZÆR¶w)%áÑú«QÙĞ|ˆIyY!Á0Énu˜%KS[–««Hï†ÓÕ/BÕîyx¼6p>gv¼]®'†Îå¾WJŞ)&¨¥Q’_ÙÛ¤#<åPšÎ2ú#±…bÍË¸è†ºLéˆ~Ğ b—¯èÁÍ‡º|Ğ1N^H‘³q¾È'é™+-Â/'æşl2¢„~‚–ûÌAK:`¨‚”U~ZXVt÷qïØ¬=azôX:b@}…ºAºffVWÙˆÉ8õûÉ.:cÖ³¾5#…”ñPãŠ;dÔÎ‹DQVì$¥Ü¢D^M,F—­s¯rş…næÊÂZ!Nëİ="ŒÎ1Øî]Šá²	îcà$}ğVêªpÑ›/Ü^B.OFÓa¤- H{¹ßlÔ$< ®|xÌWÏ@¼gQ~Ò×	¯cvVY~qÁÃJ¶0ĞòX~û41v2vµrn'«êt¾Ñ‰ÎVğZ|X­ñ€’£û_BJŒô1o¨¤³t“û’[^ç÷M<Š!”¤W²¥Dä}{è†@s.Š½.Àb:5K`ÙÃ7ş©e—·hhö>›ØMOJöà>¥ËÕ'’Ù:÷±¢ºŠÆ2Óg®ñÂBÚÏ_¢UÊ9’ä‡>s<RMøñ•d\La@>0àûXˆ¾“‰4È$Ö€¯MáSQ’sø4*éœ²$©.–ÖÑ-r‰’X<øõEmÍú
l§:ÜÀşœÓnS/®ŸeknR$)×ò”Óé1ûv±m-/û›uX£Â¨}e8^	
Fy…×ø™IÖ- $D}ÒƒÎBxZ9¯n„½s×ÿ/ÈLùY>Y]Íš_-â¿| ø¢©8YV
/ñ¡Qj¤p&I²‘óªÒ‘îd†ê89¢úr|^(rCx˜Ø²ÔÆ—¾mfX`EMv<[§:¡Äq®$2Y¡ò±ôƒ¸DÓx÷†«çğŞ_ôİ„eœH®\ÚÃtë±×
ŠËnQı…vqÍÂî¬;¯ÏôšØMx€z·RÆwÂİ-Êè,\ÖT88Œî9E<ä	É$†oD¶³ğV^Ç„HÁ!¤\>	XÑ _Ü]šZ²vÓŞÌšÏõ•.ˆËŸ¯‘?mjŸş*×µè-Óhˆ´_œ²ä]a·Nn4i'J1æ6`®ı¢ƒä…¡©…6é ¥D}]©—FÇ¢ÙºJ9%ìQª\â×³dç£¦ÁWÂİzÑçû<ßª£Œ5rï¼½-!”CÏ€I°Â‘ƒ@ûGëc	7JTŞãØœ
µÊÖàôJc¼CO)=mê@™ŞÉr°€Ÿææ(=ˆå-f%=hjä¸V¤}É´¥ÙõÌ’ÉÌåª2æ€õ¸
5FÄS;†@øÄ‹s‰y0 Ê£ïPæ“Ái˜I 3&É½ZK°WssVÃ0ê§J†+¿åÀrHEê„@ÂKRMë³#‡h!§j%òï!yšÇ¡$ó®]k¥óVÏ×e³NdQÈCVåQ‹vŒøŸ"®`&‡0Ë4~|UÆ.ˆNy¼yámş3æ™ş°îÛs*7[TÔ· oe= ë´û
ñîg;JÏ‚ë®Íí}û¹*ïã›Ÿöñ²÷¼å^	lğ)èLĞl!Ñô81@•:p'û×õûª”ĞúâÙ`wØHö_ß)Û®*àQCøÄ½NOÖ}ãéÍÓê[³ƒËà@®1‘
ªv3j ÜêÎòÙ &EoŞ·(o-6h&1ÏÍ¦Ğ¶b^¼hH…‚2NçÔáw´Eån†–»69èõaëá”LÂoõÉ)«¤®Q6ÅE%­~,¹Z8òOù1ŒX*«­¢tµÖü‹^â$§Gœ>ˆÃz-…Rq³ûB@¯ğ•‚òø¿¹`Ï:¾HècHù¯Äè%»nÏĞ/hFƒu¹t­&7õG˜qPª{¢ú$c »ÚµUKªRïàÿ¯ğ7…İ‘G]DEåÏ×ä+üWê:£üA&XX'Úİ±Ó‘LüOœ`VşZí‹Õö~MJêÉ«ÍHÀô†$›İ¶WA­Ä$÷“p»VM{?vc¢{üõ:#ªœ‚Î­fk¥ïv¡ç8ğ<b:9ĞŠ>H(6ÑÍ"ÁßèJG½“À—d…Ü§•‹÷LW±gv]+ÂBD‰
˜¶ÒX›ş
Ñ6ßYëTNò“ÇÃ¾ú‚`0&^¿”êÙK§°†">r[òÓÙ)€İÜ†MšdF
5`fÂÑÿ–v*Ô§†¢÷º¾9‡„ï<ŒÇÆ,°wx	¨Õ’ï¸y%5Q†Á ¤jÁ¥y•ˆ\É^KJ7Ø¡ıznÒš~yÔ¸£},
-¤—{‚Œ‹¯?]æ©!9ş‡³Yğ÷§(ª—X1ó­ÃUZ.¥†aønN€5'%^Ö‡o¡ÍB£°L•æı¬^;4#îx	ü*‡MïpE™+º]2ÊIé»°‡…¦L¡#‚ASÁZIT·üvÚ	D¬æT_äÀN¨4Ø7¢ÜV[Æâsı]OXj÷V=ÌÅ“	ĞÊWx.+¡r¿.ş–7Ó	p#ÏÕı<«hâ,I!Ø¦!©ŒXüÒš;à7oó>úRYEiÎ6Ù*v“Zğ´' gs¶æ+TP”›Àƒ2ñÅ‹ŠmŞ<=îs¿xa¢ds¬à¥]yyë7Ép&më²ù°MGil÷|suğ~±ok k¿6]È÷ØZfÿ·ÀüàÇÓêÑå|şLoBns°ºŸ‡ÑX-ÜÈ8a™O½Ò«´ò‰œ	EÅ¶‚¶Täíµ§¦&fq3Ö'¥	Ca;™MšO;ç¼}>ëJŠU€¨‰_õx~,P¡EÖñ3Û›Í›Ôà7ì‡—Ñi5é¨@j³ {ß£“&qV¤£6fı6)Í1—P« ÖBt˜›÷ÊN­¥èÈr¾"ş>»dÁK3°Sè…Éåî°•Ïm>Y½‹F
e	%ôôVøÑE
†ôé7tğ=Á:‹±a®:¾³EJ“Élµúsz{hAEñ÷é>ŠÔ,Æİ‚ómÑã|•LOAB™ÓA–‹*~ğÄ^]i9_ş¶ÿ/]r…ÖM8ÿÑ¹8(»Ş‰ÕªæÆ‚f»ÂÕƒ,7·!³i°Óµj´ò'ñ9ƒÍS Ÿq•JYòƒã}
‹¬ı|ª TÒáXÒòˆƒã+AÁ»º\ §?BQ°õˆngÿq
XQ8FeIƒû’­"êìñRşëí!R&Šıó· ªºŒ]šÑb(	‡"7?BòÏìvcZQ½¬Sè+ö>>ãØ«¤á²•ÜGíŸ`ÿ—£=%‡û|¯µ2X™o5ÍPÏô®+pÃ,dZ*U›R)kƒ¶Äìô=%¼)Î(Ò‰–dZm‰ö§&HH³gùî˜şK2]ğß¥N·­hrW€ß¡ŒdÔ)={ëëÜªv£Fç‚S9‰zúú21 BìË
Únvb›Gôñ2®ÄÑ« èÖ±…r•sófCv¢Wj®¥¢˜ÃşñÈ—(p§½PôÁP¡Ã1¯GŠ6®—ìÌ¶ U[WÊR3›&O_Rù˜Xö5î‚+Ò«Nç/æPêEú«F'·¡x)ÈwBñ¢Uù·}@’ä„ŒÙ-u¡İ{ÿŒ>ãôçéQšæ–(§Ğç§D#RMÅhpº±ë7 ®!ôØB.¶vMËş_q4%­ğØNDg³£ö€$ĞØ°q%QÖ4ğñsë^Œª?àz²j;
py(äÉ&Ù¸—\"`d¶íö[b‘'§g<YQìÌ•î×ã»^ ÙÿQúfgöwS€Şa¤*ğaÿ÷4§eTÿïCí«IœìÎIº1á%0fØßø@ñÍ÷Ëµ“˜¢6ÚbSiºÌ×áC©ÎT¶ï$“gÂŒêó¿u$rtÁ,Á†)ÏŒMÌ„$B£dnÈ•`¶r‡“¡YA.lG‹7ñC6f’œ5XcÔ$T²‚iô äî¼¬«
rÅ(Ï$•´ïæERwò•“¥Ó:B*zşË}$ï³’'«z‡\æÜv";‘Ùã„­k¸øİ¸j®‘ú"¯ŒÖï2ç™˜¢^luw’¬h]Ó«ï;ŞàJıvH6*I^ïÊnVZ¶z¬3î”×¤†÷"Keû¤å¢Õ>j’|¼ƒ]]Ïàù¨ûBû§„4dÒ¡Ï©#Î€Šß×ëò<±Ë‚=>–1 ÷×­Â*¥ê)ø—ı®RÿßÅ(¹Væ_&¶Ü5›"¤Lênğà×§ß3=~åŞaÈ›\óÍîıß¦¡:1ìhµ—ÔÊõûXkà¡‹÷êœ$+«(º¦z¢Ùß)¨×áÄ5’v#Šq¥° B#»‡JG~)L\æ;QŠ±…Ša˜ı¢ÿ	5”º &‘´ÉßQªWŒ÷uêŒí‰M±«N’¡¥“·•¨ºHàzü>¨b µ‹eˆ–’Ù»©a
}õkK?ÖõüTñ·À0¸\Ü<ÀpÛ€rš¸ıÊñÃ˜#€Dâí2+H¤a¬§WK-2ª°àğ4³È$ítcBy¸Ö0hp«ÈÁa	zAd˜TÉ7!ïf«ªÈX&Z—±T}¡U§šz5O
œ0±³*q¶Ç-
Š²RF%ªüNÈ½	€”Ôç*JVU*2¤+¹â¶E³8¸÷ÔÁ
‰–'·ìG±JX¾š°›qtª˜’ ¥³¹Fíí%¤Z‹¬Wex0‡&™a~R6ÈS…-<ù Æ6­’û¡ÉP§ÑÂR8ÏY©Ü,{eüMlÖbÄCZÕ1Ha9w8X1v"³Î\-W]úÍ îÊ6œÎ¸Ùã.	[lÃÃı¬lIEKU§'ÿÌPºzo‰{døPíeˆCK˜.k€†^y_Ù¥ø‡j¼ÜïÙŒ•YVu×ğªÖóøT‡gŸN=£âŒ@D ¶¾Æ¯½äÏ·ê0/¹-B‹º®4"ïÛ­­A	ç¢.ÆÃ>bëâì°äÂs_`çŸÊà2ÉU²å|X»yEŞ×úq@·-éÚ°“›0Ä½F«M×;u.µV•Û_[¸ƒ!eKİ¶
úmµöı¬\ÜSR	)şC«¶§ü,Sa¸-Ä>Æ|í+‚.>x'vp©¾ÛT–3Î’é^¹û¯	Ai{GÉ÷Û/†ÉÉk¼'µQŒ¶„ıÔì:ÊŒ
0º|AMH[)‚HBª'  =Ê€šDÎÉCÍZ*ßá¯æ
™û(œÅ7À    Ú¼õAHw^¨ ¹¥€ğë¾â±Ägû    YZ