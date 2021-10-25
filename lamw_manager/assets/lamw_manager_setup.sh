#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="855023632"
MD5="4f5bbd5ae96e24210bbccb56c947b51c"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="24104"
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
	echo Date of packaging: Mon Oct 25 20:39:15 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ]ç] ¼}•À1Dd]‡Á›PætİDõ¿RÖ”çg¢ÊÕÅÉúô®Š£JŠeKÁ
–>”<öòÈ8R”I¥œ(‚W/$ş[j!ÅÄùånŸª‘Üî¦¦ guÌĞu™üÚ?ßİ^V%{D©j¹‹ÆŸ\Rİ4Q¢úGÎŸœŞæUaæ™#(&&\¯òi™vJ,I²w
Æ% ±zfHJ®!0e84SÅ‰óî¬ƒ €T\Xç¶šµ_a<hØ`…Ù*Ü-¦ªó-Aâ­4·sqŸµ:Ü“çà6…ófÅÖW³ZHün¼zÏ–?ï ¶†#÷~S/¤®Š;¢©/GÉ8ÿ•ˆSìş?õçvt*;'²é_ó8¸È“) ùØß ¸Yl´»8@9ßiVÿ'am“¼¢x7µcL÷iš¢šÊ‹ÒmâÙ\¿>2È.¢÷Iæhò"2HÀ*0â($yŠÙ…ë´iÆh	˜vè›ŒîÓpÖ(l$3‹LÇ ÒY•mzÕ!¥¹	¡Xä‡~¦š"(¤O¥=)ú7~d¸8öÒhd872Ÿ! p49•¬z	_›BÒrµı|ÁÈ2¹ĞCF—" ¶e÷ö9$Š˜\i\ş¿IÊˆùø¯¬¼ DĞ#¸€ÜÜgN¡lçİÀ®ÿ«D;ğk.İrÑRGúˆs‹ât˜¦Ÿ]³?'ÿôUÏŸ×B×_¹©C+¬ö±ÜT³_…×Œ®<>šü¶à£a?«sÓ»›0SO°µĞ„¬—G²:r8nÉ0HY^~KãZ›™‘’`M<úd‡Ì§ƒDÃª!‚œ¨ìÍ›@w„Û6äÌ[ëhÂ’ÙnbYÈµÖ\S•ÈßMkè?Í(ÒU´OJ›J)8»#DØ®2Ù ½ywbB?C[mÕWá½êèRÆ®X@°Ï¬,²kÏ-+ó§:ı©Z³%ØÛÔ|³õYFÔĞPı†X©(9Ñôpæøû¬(’+'»
w·ÛÛYXŒØ˜¥°»ÿwı
p0é®ˆx§‘K‡_›x¿rˆìWÖÿYEJ×²Íwˆ§Îß°!l¡£Ø²¸ŸiŸó’ÑhÊB®ÇË“u2Dí~¦ƒ…%¢d.(‘–9 ®<a¦Æ>erğ“ŸT+·7FXÔ*³{+á¨>0û7áô­h-ò›TƒËÈ\^ïÕñä)¥-ËêòYù`W=ª°º!ºIxxÆIG%7DÜ@w#6K	¾ÉÙˆÕ£<W§Ò’™qÛ‰ ¢şüšËiDêúCÏÄw‹ÆFÔ- Æä?&ÉÄ•¥ú•¸g@
<GÀœ;ìÂä~G=û=¡“^á˜—¡ÿª{·Oi9Yl¹ÕA'¼MÂ€ÕT±ÁÇš&Ÿ
XD*Şbí/cõ¼H”–Q>{³s–adº·}(cq}ô½n7€“!F©-Ô4»îLàb¹0è!ªã°ŠòB¹p*7µ¸³&<Å—…íptÑ“ş¿†+nTCõs¢Â6úBsz>°ic‹z¡¶Ÿ>k¡=ñZ‡Êtƒ‰¾=)šú‡Ué†ÈL¹ÒpsH(#Î‹&d¬‡@eAÔvÇ‘	»!ú½ì,ø´í5É£)êù*ı‘C¨¿qİïõü½AR,±
…Ïf²íË
ƒë
¼$–‘ª—Y*>!×İŸF%LM5¿NÊíÈ32JN»™:÷h¹°hHbfOIß_jÂ”ªãÇvî1ÛÙÒSÍ›N-Kùœ
`W@ë>w”'S×-•0üé'²Ş5ûÙ?àç«Şhe;%]Çƒz(¢2«W¨KákHO¼!åKDvœÆd±ÄÓZòàMWú`ªÚ¥MŒæ5¥ğM Â×bDtÿWäF¯³C;·lE¿|Ğ&Zm^ü#Wd]Ú±6#ö}´(:Jß+ò ZÙš–xoÖBö3öXµŸU!ğÓr­Ÿ\às~+u{>õoA®ÜC¸CLY×û–§;·6˜8Õ@Š)›}3âîf.ÖUïwöõ2/
vZœï©éBÁßX”G_åA"7ã÷¿lÚ€(,³;ëÉ[ãj ‘ÄWF˜äÉĞÏO1‹IP#£âcØî˜ú1ÚµD•O$}| ãæé¨£\r¾9Ğı–Et¯+©Îö%Š2å~€Şk—¯¿oM¸×"«Z8ûûqRœº¥Üì¹va´× ôÂö(T.èøIïX> ¡P3Š½ ìwUœ»¸1‘2?qu<U?2{±/îE’)Ä³êœ|§4ªğƒA5	.f?@DDjıb¼Õ¬OàØ¿†½€™vØ÷¼ÚùÊFu/^À!”[¹¯¦_r:Ìµ}n]³k2hKÛ„¬„Ìè”g·åõ‰Ï 	™V$)­vGtÒü©ó}3ìï…"SÁ£šDÈËr¼°’!?))Í¹ñj=uŒíÕfÉs¿ĞáŞLó¥tÔAğøebuá©õ&mÄ½yÚ>Ò2úÍ5ıCóÇ¿k:øe„Û
ßNgUr\õŒñ#‰àÄ¡W'¬UÆÉŞŸŠğ¶v@Æ\¦¡™|\ùºÇF¯ÃšæÖVAæV?Î©µ®úƒÖ}øÌ_jÆvyRä8^Ã€©9œI›ÓşC[Å|~s\›‚½´=B$µ15uøT‘ı¾àr¬ùnEá¢=°ÛRF¡¬“ôö°íÙØˆ¹ ÉıŸåç„$~+}.ÏŠ/Î¿\|NVk$ÀÏ²‰0U8/
ÜÒÇ3ûß{®Èí#B\díüV¸èMÎ‡§ènO£6gmæšS’,][”‡ˆ½ÊHÄ…G†7¬¨(š«~MÉùI‹¯Å«˜5
WÈ›[E6czÏ¦ÚE”ÀráÿV&£o$¹’ Ñü“ˆt0‹Tôàó<`Ş¡h‘¦_¹w‘à÷©Æ¼âä±P:Qp%—%ùÛW&ò>2'Å¬ÛıtÄ““w pŸ9Ç‰Ü0[ñ4ç¿Np]÷Çµ áñ®)ëşvkxuS†¸‘-ú¶_KÓ·(Í³„gğ$CH>ºgĞŠßı•o†”úZñ„@@Šô ·]MïdÿF7E¥mUXÚ^Øˆ	…´Ø>ª%ŸM'\:ôÊÛúHKŸÄ¦Èi-Äë4Èæõ—Buï›sÿéÆhõnä¶ìYÎ (+aLŠí¼ìF²ºô§Xc¯ 
ÏmŠ§q„cH|MÇ4_0't1®eS«läTD›;“‡÷d*`-î#Â4“°¸5´–ß¬†ØblŸQÊÒªã2kífÊë¡ä´ÑŒ®ÖX¥ö„Q7ç5r/ÜÿüM8Dágz—wó¡ÁWÍìoxËÑãt(,é8L°T}hÁû²à»ÂúÓN`íÖ †›QUi|1L<².©MqJF'Hªèñ#šÄXMnzS’#‘Mé? š:®Ò0lcWÕŸ©ãZH[–Ls+ sÍ-5NÂ{SrŠõt©üè~V[ˆÂ’@ş/4õÒf×2©ú<pµø@ÓÿĞÉå¯!à\L%#"ÓJpÖ\-vğt>“CTi2IqbøZİ"W1šêõ‘„~­Ê¥<lRzŸ=#Î§0¹ ôX0ª œå^§Ziım]*K©ÿúš!Á‘`œSìp•UƒHyhóŞ*óº:{Aò)ÎÇ;h™YÅÎÂÿ-÷SœÁ ci_Æxh6z÷_İì3îM®¯Gt³+÷ßµm¨´¥°ykĞŒ™¯)«MBíA‹4!¡éjIW>üGçÅ	`(¼º9™úÔ§ú”ÿw˜ârş í+ƒ4PšÃZ;“ô3LYNåbËH«]‚·sûF&À /;6H×Æô^§~ùW³kVt a¬ r…séjÇö£ÒQá\˜‚ã5qãÉãaöiË7ÚÎq`ÁÆ]gwÜ ã–f¤É©ØÀôïÔ›§K89µ©×ÚEu`´kî§•ûn—{1@ü“Ó0Ãcg™×Z¶yÖİğ…2[PQõ·tê“yJeíØßr[¹+kÉô9Ğ®>]  ÎRç½­Dû¥td%¿¢uFA¨[¦?7Òı™É#*ƒ|ô©±Œ¼•Â¯”ğp^æjr°¾ÄŞƒàTû®¸Ëı’¬‘€J&?&$ Â¾”Çyº"¤[pyÃlKF¿ó>®ü"J^	®UÆİÑ—Å{‡{¥(Ç€¨ğ›?ålãòÛĞÁ­-¿ßVÈ7Áğ‹N‡÷ÀpÂH’ÂŒ4ç Ë‚5m´cìL”áIŒ>0¢Jt4ĞÀúE!{œØ¢t‡•&(¨S‹®÷Ã¹æñlş„é	©„‹}A‚È8İH·³cŠÄ2¬ÌÑhõúî“¥<î¨¾+ÚÌ.'²•ÓXk$¡'I¾¶Ù0ÁÎ³`íp-ùTÓ
@.p¼\³«v¶îùã9çeé3p«¶²Ú2<ˆ)sñØàç6«¤O4›ìw"åA{º|hFÿ›ÔÔ%–YÛŒ¦‹a
3•ôÚz·®ÜRkû]Ì¡}ù{Åß ZØıô—  xSl¦ßG
#x³±›­<pGdÏJèLŒ1EdĞ2?éş£pÚ“j¶\l¨ø?sß8©;¶{N9¢¶of™ı×{#œu ‹"i7A¿ĞÒ”³òk3ä¸¯:²¶™ËbUé¬UEmX§l¸ÃU<â+*><ÍMHŸŠÛ„¿"}–ÔË{'ûtGÄôTİ¡n‡éu¥ÆÅ÷Î³î]|°‡ß…°È’¶ÛÂ'?ã@¦½Ã¡7‚gé&oE"ëé+	‘<ğı:—ªÌ.šëĞ©Ò#d27îÄ¢E¦ÿˆ¦aGZ–‚P-^…êÁGK§»ò€	;“#¾ñÊ²—˜mºd‘«$U”d•×ìŒÚFQšŠ»{£ÇE:{{¨8\P– µ	®¼¬Íú8è{	V=~„]*)ºvü“Û“û¯ş+<¼şOgH·é]®Øo{C{°
ˆw”×ˆÖH×2õ¾[¢e£æöÒ1508Bb¹rö¹)8ë‹%²-v; $Àµn
‘¶ÙBQs’Öó(Èõ»ëF÷Q¼õ*®  Ğœ•&1ûqÅC¦Vjt1&$ä2nf°R›¤¢ŞF°Ò„šÊûƒ&â"mĞäwÂÂËÕïG2ÎBùñ9(HCû›šŞ,……ĞÓ•8	‚gÑõpN˜-¶/÷œæ•DşÍKŞz5¸­ÛXûX’(œ4Ì:“œXJæíP¶¯|ÊíXÛ=ST£f{¼28'¯ªöd„§ÓÇÕÉÜ(Ğ…ø÷¶XJMlŒJŸ Â¼§½¥±öHË~Xµà„Ğ›^—éñTh¶RCl}vË4N¼|õ{@~EØ™"ÍY™Âj8BÎü¤l…Åjõ}>£MòúRïNn&6<øh‚¤{°{†ŠM8ºÑ	Ù	Õ>r!…Sèë¢ş©nÎ°*§evP¹RwÀ×¨ä4U”"Ì6<Y nQa;Úâ“¹û¤:øŒğ¸(:}¡¡”Ì”=fVÂ;©ãOQ‚\Çsh”Íê]*´ÿîñ{Ê<T•=r^x‰	Ì|û¿ĞñÃAªAgÃs¶Ğ{j|}k #.µ!f ïóìŠ£&–a®Èc‰gF¡/U}ò¨ëàòœ »4%0_J'·§©
x[Õ®¯Bğæ§¥ı@Y·¦Â>ŞÌl¼·2¡ŠŞª‚¸È¬?F#à½èµ“¡/ïuUcäüÏFò{^fY½éô¬=EmT[mÃ3hûöÁNö9ú/ØÍï ,¸u;ÌÕI˜ˆQl cfõáˆH,İW—ş— T2Ôp3+–°>ı 11‹aŠ-.İr–¾±ïeµÕêÑZ;ëvÁ5p/á§Ï’_Ò{´\­bı›@ÜR2,¦ƒEçu²…ÀîÍ2„ğN/ W¡äœÈzÿñr ‡
û¥ø»Œ_9=Ãş_Ş8§”)ŠWkX†±,nãæÖèñì¦ö4²Ëoë ÉÓ¦ò$­dºˆ™Zsq­Ğf´`
ë®]Ss	‡ÄOÆê¸b5µŸqFy;œÍWšÔ6´bé°±å„ÂØ¨cÓäG©Äb…æêäêjô•GŒÌô•®…0§¡Åø†ä$êÙİ®-*w:¿B 15ˆ±«±îÙƒÏøÈÿ€¬^†Ğ(ëİ°Û>¾PM™NdIÚJTó«×w`«¡3¢Ü›EñŒÔ^9t¤üÇ¨ŠHp	Òh-VğÛç'†.Û!q¯+áD?‡Y4(µ<ßåJµq×%#ºÏå÷TŸ³JI‘¨?G@ñ0@2€O“u[nv€Y…±ÙH¨òğyğÎ.É*µb‚J,È<CHaS½T†nĞEå9Êà[Feâ{W5ÀŒ
d»ÿÿ3¬#Ï
¦ìz‡n:¶*ˆì¸¤Rn¦¡z–^r¡¼¥İ?ö-ç4)Ÿ‹†DÉ8ƒgşpxEŠCZ‰±—ùğ^÷æ ‡Pœ3(wQ!ş»¬æj)WKçhÉèÃe]r\Şÿ¿°xPªnÄaµ>ÇÿA›™jå­I)ÇAzö5aB/Á‹HDhøşÁ¨‚Ğ£BáÅ´ìhÍ]hcğç¢ÑJñ¹Ôñ	è8Öø­îo0ËÆ¼‰Ù[äâ´6
Dõ^‡<˜Py˜ª]qsµ~ùxDŒ‹Ş«Ú(Ş twUW“ÏGu^
™Ü/#RãüLÄDØ_®²¯Xë¼võ\î®VÃ$³PDºoP‰®¢-B?¬|LÑyÄ“ˆ¨&Öv4ŞßŠ!}üZÜ9hå<Mvë¡Ü‹ÕÕW;ı;5õ© ÂLÊ‡äM\ÌC›èÉïƒ(J!œ*¯ ]2ÜM…gÅÅæÏwK,yG}™¯—ÎkUíA”­*/ÊŠ£ÄE¬§ŸÄ¢*Ìø4İA”)X<|	Í•Ãk;gl&’c"tÙtĞAĞe…ïlî%i”âDwì¹Ñƒñ%FeK.Ú…JÓeX°mO=BàZqg£·òDîêßç)#ÓœÒYÇÙW×2p&„•Ú0¾1ö?<óšt`Ëù,À@Íu}&lbå÷ÏŠ®ªàû2”®÷Ó‹4Jê­º3†R:ÜŸ2cêà š®â¡ÿPf'¯7Ó1r	
yR«éKEÃ™ËCØóªéØFÿ÷<ˆ!î7­tI¢õ\±î×£x˜g£#Œ˜Š	Û.­Kº’f;âù^¹€½Ñ}eŞ;êráOL„‹×±M!®ÁŸ][n–&v¬Ñ³´öFĞağA´¡kÓz°"û&;UVWõPNgå‘—àš’3¼©81jh=ß ã+cñeßóõBüîaÃëşuõºhè¨nˆ”ĞŒxÃ~lBé>õCÓ|ò~ZÔÀ[Ö(uc\°9K4ªM•>ômŸ¬ÀØÔˆx‹ê°^6÷ó:áX
JĞ.Ú‚ƒ’¶o¹˜¡(šÿ4³?ÙIYTDÒP¸ï‘2JÅÊéËQÏUî" rÿì X²½¼áyZ:4]³(½Ìjü:`’53ğ¤à*8Š'´;ûÇ3Q&Â=>Óh´1Â—3ítÿê°¢é›fûIçÁl‘ H¹ˆ,ûÄÁá­tº8\wÑihÄ% NÒxêM;Ùy=öEÙ9®ïø<;R™J9JBl¼¬õI¸%‚+rğn2–8Ì>uK˜{Ğ—“z|›ÜJöé‚¨øô‡Ñq‹gç®Ãœ9è\+ş´å•qtÖÂùcçm3Ú8®l&³|5—ô¹3~‹7ÖÅ8åßÚÈ_çÃ¡äªñ»_ âß—®É¸ÂŠŞ%òDßVÉÚñ³~¨f/´ô¬Ğ?ùàU©†ePØÿÔÇø©¹#½Ñ•i”k[FÁQõ°y?ÏÊ›ïTl“ZáïÌŒn^	Ê-CŞ÷ã"d›-'C^óúèka÷{Jäl81å<Zö=1L.)AUĞ;*^ÛmYjgö Dr¼øqOódI›k&àãC¢B6÷^µ™òEz8=í™—†oÒP¾åHáqF‚·s$I÷k¾…{™öHÂL^„¼Ë8ñ
³ËKÃ|*~³nÿr²ÍƒŸ5oaËœ\Œáñ¥²ıÕëÖ¿ì¯zÒËï/ï${y.çŞhEöÚ’Ğ,Niœÿ& ÇÙJ6†Ë|buÕHùP¿¤OŞîßh’ÕÅJÏó {:¶Ÿz«íşá°Ï¼µ¤uˆŒpNÚ>î‰“8FGÖmØHO`H"D¡aa%?…j4ÿÜÓÏ¨,Æêµ|!6Q.]ÓÛ!$:T”íÑ‰SÛyµ5=Ö;ò¹3§	08Uv ÿw£	mñ³¨RË]€ÓZ—âl"­Ğ²	õëÎÄaøœq~kTë¬[êj…ıø”…H%&xæİNsÆ÷^!ÙÑ ŸÎ=ZÎ(iÿ†ÄãkÙbè}:Ú±îá¸È¶ƒğÌ–F›œ‚ùC^gX¥W(âA¢>)†¶(ßX‚öhÎæé*p¶Y"İc^± í´?!êÁúË¨I¡!ì¬Ùq#Q&vJ®éU)*“«U¦ŠäÓ¬·^áU‘S Î¶$$¬{jú¾âğsğ"©ª°#Æ¢®˜«,.#¿J4¨„»-ò™¯Ô'õM¸t¯šÆt(>¹Îy¥‚Z‚Ã²G”®tK¨‰ïæ"ÖB·B4Ûì¨%r€IO8PèM-8Ìû—/€(dÆRÈÄ#¶„¬)°†`ÿ†‹%x…×•Î¬9IœİÒdæBĞ]Mô>9 2°HmY{÷|—Ö²C3uÑııº&'ÇÒU.ğ%Î#ãÒ@…úJ÷úÄøÀ¼ûfšgÉp(~ê‡ÆØÏô¡!8hß'jZ§¶Ó‹çŞIºµáÓ›¶¸a¶IPa€°TÿîåãÌ­û?o!¬…»PeÊ¹A¨=¾æÈ`GònÆÿÉ7º8šã$ÊÌQÓ¡º?@>3"QÎ i"zTÖ%¿`KOg¾}ÿêğÂfß½M[õ°!õÔæéùYŒNû|ˆ÷Àé¯ÖÄy	~,@Ş˜¼æô8µ
óe$É–2[·\Ä‡8ĞÿÉ¯¿˜à*BÌc —J‹F¹­—¬™QQÊû×ĞÊz:×´Šµ±¡‹*ƒjuÑázÅİ²îÜ¢é_Ñ}BĞ§0}Î¨Üƒ*»'¨‚v.Y"™°æîb¦z¦Kİz Ú;¬»·.ï¨BìZ¬ïP‹z‹ì…‰K¥l6cÎZ3Uç†¥™ª—‡[ÔRu~Í².6á“k}ã4D4õQĞæ¼Q1AuŞvëè¶. ±¡óòmà–º5µñ¶ÖZ¦³­ˆ€Û¢•
ƒEF™‚Š/V‘ UÊJ½âÉé€o4>QêÕ[ìèšH»çë–•W†$g½ÄwïHr¿²p* pS
€„Ö¬zÆ7½ÄÑ-püDšeÖßSFeY:‡0#ğ_µ§t-ßĞc,íi6NÎ:ä¸öÅ´¢:Ş%ÓUñ`ÌSïOÛ~ª˜4·ˆ-QÀ“Öu·2Ç“ nŞZêø6F5K×ïpaÈıkXTú:$şç×J½˜Ú-Ø…-9<\ì•
“G{á9;‹O61şz?{yîŞ¦b¬ÆÈJ{3ºó’¥•|	xñ…Ù^õŞ 7DóÁ“¹tyƒ°œIK¡˜Ö¹9şê[¦ßİóå¦»ÂZ¡Ì~K¦.ê!úğŞ•±Œx´áUÌê+Šû>İ
õÒJºCd¤R²¿7¸‹…X#ëQñêİÎïÌxiH$b—„¶ûŒ)AqqÇ…¦+ÏÕv ±¶w›—‚ŒŠĞD¨xeü
¨å‘¸á’üÎxXÂÈİ¨0’@äƒÚé)Ä•ââe/Ç!Jo–· =™uŸöl˜?Š¿6¸	#$ø÷At–;MÎ­ÒˆaO¨ŠUàGb„–wÃkS“@òC‰•¿µ$C‹K%C²¾–˜x#Õ¢BjGErljHÉÊ¨òr¦&Lk‡†P½ÎXe™1ò½yµ'„âÈÆÀĞš"Æ.Ûñ¿| ÅeÀÂ‘€aC÷rÙ‚£™N#ÙEª>¯Zz6Q®ÎPf8gA2Dó¢Ğ$ÖÒy1DÊ‡	;E‰êÇãq‹fm+§zh 6“;­à:ä¿1bL*-±ñÀ‰tÙ¤ß^/`¯\À ¬yü+îŸ¤íeV_<'0°ÂyoqÆµìF ëéæ°Šûæ{„@cæ;¶g£;U†wñw±®5=‹İ]<C™Éòw³ƒ>şhØ«ra‘G )µöÓhö%ëjÌ“åÒ;FÙè™/GÙuÚt<çæt×ÓføŒ¼Št,w4j©ŒÊYäÖ—xÁ&ÀajŠé&Ã¥¦_Ã®)›NÄÍ8‚Ò#>qÓ@Š_·ÅQ¸ŸV­ Ã!•ÙN c”b²­·*ÕhÁ”{>ã|¡Ñ$<Ì,9¥òÒ)åÌPÛUÍvm¼‘ôÖöV`.G¢wæÕ4ßªwV­VXç&˜/`EÄéåò,ÛzYy<â˜0’…Á¥ıª›V1¢ú/i\ıd¼şuú³®²SYØäÀŠÛúññäğ}‚~v;·ù­]0ásúh1²ï?Qù1Áæ}ZênØÑI9¬õJKK#/¢?	*¼‰+‹V:®m“¯ÍÅe€N!=…×òJÔòRj<6•™ŠwŒÅÿV
z¶V»sëûá»i{¥PÒ   Ü@§O›[ş?Ã·hv?Ì¯›ÀËµ_•%ÔÎWVG®İ¦ Giç~öÍ&`Ñ~­0gøİÛõÑİ[Š“8kâš9ØÜÓ—™6âà=ÙÌÆ)‰+Ó!™ËÌÊwúI+ş2·Ÿáb›e¢ÒåÔjÂQ„ìåâ„Iô‘ÒO«åaÚ»Q&<•Åˆn+ŞÅ_ÖWMNõn¾hfNùÜJ¦ò#ØZ®Rö %×¬Ÿ^ÀFFúı*0XW{µ"mñ¢ A£úú8j}IHs#™ªé}àNĞX+	ˆªê%òãÖI>êäêçÍM‰[ƒv¼Ïâß2ú±÷šd·4]Øàökª·;$¦ßèkE'_Üª¦EF­ÍÉévÆø9CJ¾´„®"Æ Ï"Z±,>~}¹ª{G&5IæŠ(m>±S–àú¿¢j%Pøù5%&Qo^Ò};ÍÆOš9BD½@+Æ»t·É±•£CÚMe=Ë¯P„<]t,Rl_~Ã˜=Çú<+uDÃè0ä`Ò×«A[Ñ–6ø"Ç±¯À	ÏÛÈ+O~l¹˜pÈÓ†M,øgğ}V’iÆ×&òÊ?]VQ“İFs	CD€9—qIíıyjÛ²TwÖÎ(%ÚB]³Œ+m‰½{èpï<§ÚìÌnfÚÔZ‰8Nó'!B`[Şª‡@/ )İh‹ˆ@£€ón¼­s‡AÓÚ:t‹œÊ±â„ÁÚu£`ÏCô5>Ø)UÁîù!‡gtL‘Úz D¦rÒ~JÈ×j§ŒÙ+JÉn|ÈÒğ!uûİ9’@ëÁ»¨˜ÉÜİ¢Íú,¶çüÕ‡O8ö’ÈğôÔ»„Ñ$c.K™QŒøŸùrğø5|š¯O`jëÏà(t¶Ò¯cQhõ5sšAÒş§T’wÇ.—Wğ8·ïô×šlêşDŒx¡ü'hÇ¢#äqpê%Am¸Ø%JèäEŒ¡ğD½2—mòecß°_ÇªQáWÎ¥ÁV¶İãÃ“B„.“ŠÂÎ³OÑŸ	99_€¬dyw&ÿ•gC»ßeöos¨´okü¤‡™°6Ó‡¢5WÇ¼Q@ÓY%ô™PoT˜.n¾h±‘zÈJöï€8#Œ»yîx¢æ0à\³HËˆT€[`)3R\0»X£A´šÿê¢FVk§€¡£Tğ+›(åŸÂf Èü}x]u™æIé`(bí’I§|^£ñ÷Ú:È*ZXG!¤À(©œ z
\ÔÀ@`¬WáäÉ»¥b2„c…&qÕŠòÍU³73cê€”
Và†m¤IÑM…¼TbòôşèkMrŞ'?|N„ÆŞØ{’QiŞQÎ 2 OM›İ#zF‘²p˜rÚbx¯óòo3Œë+1Dcõ‡ªä,ôcüã‹ÒÄ±a’ìT#£²n)ËvÁÛHSÊo€´„ƒÜÆdç};Ù›Éäá"ÊZD=å¡©2ÎĞû<—+9Ê^XJ¤-^Îú—¢.ÃÚ!Õyü`@t ·êÎÂâ™à õCI¾)AßîÜx[¢3Ša`£nĞ’æ1fML@HÓ‰®íC{0jŒªAïÃº¹ @Óh£Î
ÑhB4	/eè{ö¯¹6Cã›¶Dàwe	<‡¥kíuÏ_º=Võ;ík&>9ş“œ•ö% ìJÛ;ÂÄ9†…ÆS\Üº]ˆ§·Ym)õ)'ºWù?;¬ª°pôØ;ú!Ù™¹öàØ1>/¦›˜ƒ—³R–‰×U¦—|HÏhÎ³€ó÷»ãİŸzA'ŸmUÁ&İl„¹’HŞ%W@®:åÔ°ÂĞ¹™–ÅPÿ-¹ç
“ãŠ=^ôßÊûY*+RWœ'–Ôöı°~=²bô†X+iM°Ü~BsÌ¡80Ø¸á§ûaÆC«+•Œ&a‚êåˆ eÒ["²P¨RVÇ,»f½¯—«j9kÂÜ'wp^ÚÒ «‡8Uüi¡Ş4÷¬0‰²Û£Ê*®ª©Vk6\äË´Št•6ˆ×g$Ä6”qShNq©£P]—Ü}©ôµzgÏ7ßOWÆä_Ç™+W4JV© )6ä–á™ÒBÕ¿Í”u}ÍœÃ†xJêŸ}MY;13Ù«[eÒå”§EílP°Õx jæjØ<ÅÑæóû@ ¾“°²\;ÕniIª)ë@”èh1™°˜ë‰DÏ‹oóe§·~î4dUDÅ;µI3
¾Ä|î·8Rg?zÜÉµ…QâÖhìÕ´›å5!ï,Zé‚kÈô(•ÛÇiCdÌ!æz»_úÏÎØ§e_EäK¼«XÚa%Ã|Ò(<—÷kÌ"Å Ê¹ùÿ˜îAãºpTÆÿ +¹bœçÈ,^çAçv†Ô®ás¸Ä/6·‚µ±L…Œ@D‘é¥{ı»•öŒpÓá–ôojµœ #Lï$è®ü3÷¾’$&K'òG·‰¼æ™àï®††ò¥Ï&g£bØ'
AŒ¿`ïRµlÜB› ¶mMhD¨§à¶Z™æu}7ı•jLXÀ‘Oq©á¡Yo²7qI'{>¾^wúˆz-’ÍNÂõãŠ%$ôf“´Ê*Ş–ŒòØNMVT(×t%.Õ”şb0‚¦n“<¨ªÆEı«z-7p5$r¯5ó›Ækà3ĞÎoubZˆŸZà Xì×teÓ;¥­Ùù»Ÿ.Ğ¦ê=÷¢J#B“ğ©$nvIø&„ûşõ(T»Tû›êéR/ïF-î°pA·‰‰ëqH'n2
6y‘ñ]v×rQ9ö"Æ–ÎULŒÔ$r/¡¿XÜ©™8ÆÚäøY!4<cR0ä«é¹üš€×HigXèŞ{×ğ*dJ8Ù¡‡A´æàÕxû­ÉkìFk¼aõøŸXFF™ï¨‘©5åC¹&â#vÚË|ÍËËÀ›sl!vûPüñEúíqS±Ö·2–§å³…@N©+kï»—×ºH%Øpš(õ¤V—“;zbiŠ‡	K[ğKAÓÓ°D/Š‚Q«cn"Qıjd% =Jí‡…6´`Ê%04¦<ùê¼œ¤Æ¡–ï¬(\îå M Ú:½?÷;Â8Æ9>ä½•®ˆñÜË‹š_N'ë‰„²·¼XãÔ/fYÉü¬ FìhWßîÉ	ï?méÄ6Dxœo^¦«!dD¶zl%U¶Xìq.åÇõ*Ä“‘	áqÇÎ¦4üÓWö¡q8
/ö¾ÅêĞ'À¿ÏªÌÅz¹#É#ò\Üš³¦šŒDß£¼®h˜™Fƒå¯
‡­–â¾!²e–üè¸¦ r7€¡
&ö"öo˜CSšh´Í¦Èè+QàW]oQ;£B¥“~WÃo˜ÂÀ®…(?t…œ`ÚW_ØİÙ	½ƒè<×¿Q[ÉÄYSC½ tÑ“D‘È€†ğ B˜ôUI,%ŒïÃó22ÜÛµÜNvÇ¾-QÃ.¾L¢_pòw&=õlˆ¯ê)r¨*ö­@ïZİçB2¤›ô±|²]œh˜3Í¤,]ÄÓ»×h0L1
Qø!pın1ùvî_gC}Èk`óŸ5#O”	ó¦ÿKä8Ï¿S¨×¯-
õueĞ8_¨´÷´‹ôÍä]·¿ÎÒP•Ñ Ïì²¹gNÍ^Şü¤?ÂYg#ä Ø±©§İJÁ üã—k±¯¿ËìşT@T««V·¸ñÔ2i¶¢½?>	Ëéé‰2Ê
Šs“SÅ`äØIBm£µšÖO.Yä~îŸŠMûƒ…rfg{DÁ`à_b5¸¦	$Öğ·šb#øAdQwCÊÂw¤Åù~B–‘q\Õ­š»§¤J(2+™õÅb˜Aoøgq˜Ü
ÌÕnşY­ÚaŠÅOb‚xB5ì¯pæ5ß(d)µõ
o`3ŞÁğ¼U¸ÍPFÊ+¯÷îbèz1Ám'Íg?=ş‡rï·qUÈ”O.Îg$>¹GÕ>-)Ô¯×PÖ\nßªO|›ñ&Û‹§:×µÓ\ØñÄ_ïÍŞ
|ôòõ²Xêâ©PníÍãmQT6(Š/F"‹³ G¥ô§evk‡¥¥VG-%ã×‚Íâq_©Ät;µ¯gĞüóZÇgò`Eªc‘ƒ¨G>bÈ¬œ{-2©Ï¹µYdãësnVëÎ!Â§‰ ¢ Èk¢‡!t€$-ÜÙ«`KXŠËl}X°FİL›Õ\´P‘ş´=)Sâ—Õ<*RÕäV¥òblu[@&B¹5(=œŞÀ®¼6Õ1Ëİ¿¹ì¨nb)b–k	M¼Ë(Åò«;$êUk;›‚ıÉVª«1gÛR'Úò‚…Š©g,è"Èr†§ruÖ¡’rïm|iİ‡MÅ°]ÜüÉÌªÛ¾™sv–ãÑdëÎ-ece¸¸›¨?¢hjò“âÒPi´yO·ºb)\™IæÓ\f;£À	+Ábi·ÃCãm_,Ë> ¦-jA+Èû¸³¦>^…`fÂnm¨TZÙŠÆ*K€GõrìPÌ–\ëq9ê#BÙ`YµÈfTY$'‡ğ"r[¨ÿĞ=¹*ª%Š{Ó'G¹l§×†±O™ˆ(ğÍŠmO#Ú{™ÏÄ÷f»Ì&8áå.Ïî?ïZb\ğNiœS/î~6¡ €¹<¨ÇLÛ0s	î…è¥:İCØÈ6¾å\H®`¾ ~¢âíP~ÇÒğ Ñùâ×Å¶(áª‡ls%ÙfĞM|Š#M’ëq!	»Š:sê“¶¼L!a[m£İ[L÷‘Í¯]ÚçÆ}ù„Q¼hŞİô2Ü ßßa¬ğ—j0Õ2©6ÓÌ#±àM¨öYXNê$ĞÊdwëº0÷…n7ÕªÓœñ=oüûØ†Ë7@l.¥C@‹—âúiqFû6øÚÇÇ¼uÔ¾Â®~·ÙáãöRè«üÇVn×9(ĞŸraŒç=ÑL õb¿rXÜx$JNÜu'•`¢FŒeÌª_-_&a™CVAÕJI°™-ÑF¹‡×7ESäA°¼î$¯
g0Ïn%fÅzÜø6/#ò±óö5 »KĞ÷É*EôÃhúü¹%Z¬y¥Ú‚º?ÍjVdçH|öïx3´Ñ®D"b -Îñ¿ƒLĞ¶%lü°Q7Ü<u€Ş	yÛØ+]ú#ç Em²/mîòéE+}Š@t¹KC„^‡Ş}EU^sÉ4¹*3šinŞì‰=WËÑvxã«Û×îQ!Lúä]µ„WBä^SUõ©íê¶œK
Lß7ÿnEeMñK#”zt=árhNİù¦É^FÎ‚TZÌµìjğUCÏô@X±n}=\¶_İd‡¬{nº[0µß_œÈ‰ü„kŒqÀá½~_ŠÊî¢xå‰!³e	8 ºtÙæ•ğ=í¼›Ã“ªƒ‘Íé>ãÜÍ J t’yAâe”fT‘"àùì †1é»B8 w[X¬¬ş(&Í–IXã0˜[Ú™l÷LÕï‚ 	S^k‰Ÿ«ù Va†ÈKçXšV†à[Ø¶ÃL5Ã'ëÏIw²›tù,å ùrYºóe,Çc, íë¿óö‘g:{uÂ÷Ãm±ï;æJP-ÂöÒ‘’¡GÄ@ T1CåŸú¨œÙ8ñ¡Ñ~àü¿ªŠ
/*µUB±{Ò„ö(Ğ3÷»	„Ê£	õŞ]O?~¸ÜşŠm*ê#”ùÛ²>ñß''®äí™e)9
ÆIÎÍqí$e›/yàã.«ŠĞúëÖ0ŞQ‘>}¶û¬-Y·Ûíıù\ £è”ÃÔªû‡Šª´}¹G‚xÿÙqæ¤KâFÛSQ-ù4k³ßWÈ6?OkÎİZ$Ì …Ş?I]cëaf{‘úå;šªkÂ"Fn¶B”LhFñëƒ¬5kÜ˜X¹Ğ¦÷]jÛtğ9jmè«‡·¹CxóVƒ#‡	b„+‚¥!Nè\ıe“SíÃ’Ò„á›ª¦@C9_Ù7ÇA¥a®ÂN2±t¸.ô¯Ö!—ê<:M\ıO¸â4¥v(Õ±±ëò°r–/8·D¬Óx»A}.a¼V9K¸G#ô¥Ñìs‡uğ ïA?Dî{ôj46­iËa³åìSŒÁ>@CĞL,‚’ àbŞ–‰
't‰WäWÀ¿h¸*ˆ4ŞÊENãåT*7ì‡YƒúP³ =Äö4 ó§õÌ_^± ÿî+¯Kê·ï#ÎEÃAànó)€“Pd#(”jZÚ}8ÉH×DÖfñí„/PH+Yh8¹€”|º°p[Ï;áº‚å’w4³h¬>£Ş·&õö ïÉ¾jÌifµõO¾Y‚çi¸±Qzèå=_½D­Ì´N˜PLgÆÁ2©õRÚ¯ãx±mE‰Ÿ;UÃøzºæçQÉ9Õß­”ç±¢š¶Á»T'ãcA>™v¼İ¡ã·¿ƒÆ€åY
-ËZM‚{ ğHöu}†ˆÃ·éh¢q¨³Ö~Û¾ò'üµ‚[X[ÚuºË9Ô2pÒlÏpãn±®yN°sb‹>¾ï3aÛˆ´J7á2ôÉxç¼SEHŞÇ˜?­#²²g“Q	‰½ÜA™ëFêı§ĞZ°+XàßXàµº°
ïÜ{Æ'ÊC½Ğa™4ûóÔ«CúŒÕ ø2µÃ/¿øÃúFúÎıµ‡kTZïÇ&/å`[êC`‡îZ¬çì¤ê’Ö!A÷l°ÁĞÌ}}†Ä‰Ï›”>Yº¹ààBF^ys¹I {ËÒ¤0zUBìzíû•·úé¬uÆ ãä\
¼ØÌ(°Í—e[ºõ¦5“ê!$îq±îH«_æÚ@3š£œËì1Ñ6 şLôº éÓJ$N4Á‚Za2\&äöSÍâç6nMğìö®·vïåE/÷&_WÇi»•^Fb³áÓÁS°ÿMMçğñ÷­A|ëå˜Éål¹F/4šQ—Í™ƒ:ÇÌ¿›±9•åHŸÃØ®Gh©Xt%ÀÙÙHXÂç„õ%lëåyC_Ö‚(AU¶½E7’(½)rq™/ş.J æ†}‹»2ôV]v$|®w=Ï.6ÆhËlšÉ¶“íÛÉ†ªGÉúÓVo‰’.Äöu¾±‰İólÉ8\&Eıxû[öÀØéìÏ’´»>xÌq¸ÒŠAp ]œwS(3¾Gßjø§Ÿ(ïĞ’‰v×n/õó½~k9¦fõÁ»Av—5k°ãT´qÑ#E˜ Ï.É¢Õ7İ"Â6æuÁıTÀ»zb`e±âÕ5-¸û:\#ÓòŒ½gRŞÍ,¢9œ„A<¸^I-£…ı¹_ñ:Jp æWœ’3Bä„÷ï¤rÉÁq.z©úv]tj é&¿_ô°^ÇôFPr¢6™ğ”HrÑyñRŸZ“ ôÁş}¾c(À›¢´“jØØ=ÉÓÙÒN¿5ÊÂ*dÉƒ/®·ëé×*«jÏå.?fßU<ÙwbCÆ¼m²Ó¯M5Îç€ä'·yåÆ¡(£Ğn€"…ZÃˆŒË´*&Ğûƒ(à¹)€Ê)ùÄæşU<´ub$kÙ1ÓM"v’ıı–·ëØ@åîò®¸_ı‰6ºB÷ÊzÏû³NâÁ´O:^¤WÍn>=š÷c]Ğ~´Ñd8ls”7O’WêùÙÀG'‹é6N«Äa!<Á}Z­êÒÄ"YcQ<ºH"ÍË?DÓuUHèIïÊ'æÃã[-Ë1s¶4@üÍX³°‚	uàlfR”+ÓŒ“Sµ‚ëj,[|!ÿ×°Å~Šq+$‰ÉSç$@ üÙn°$oñ“±¾Ü‡å+àê¥*§U>–\UÎÚÁa¯^*Êd–ñül—¡6[¥*”ì€ƒØG
ë¨»É¢¿ÒwjÚÔìU®Í‹ÎÀşkvôµÒ	;ò*ÊÜÒ	j.Í‰ÁKS–²ñ×"¼Â3ÌHqOÅÂ`é÷¡ƒµ"ßÉN¹ <Û&Áñø\ÖÃ±òjïoS@½Gu+[úœ´ğww=ë¥ÑIC+$_ïVXcş».f+Ç¬8â½k'4ê;ùjà'‘‡"òÁÕİÒís¼pï‚©ŒK…+Ìâr¤7#†”>¬ı›ä"Èb‹&-úÕÛø¦Çï`‘ÙfãQ¶²BÄë'Ì?Ğç)í³:-†âÎ-U»Úªë—É~_…ÂTî+¶µÇdoC™DÂ2ãó+õ™Ü1>¾ ¶2™ÁU£Ø]º–µ®‘!X[Ù\e ´ë(
¬eæpRY2ƒI68ÁLCdt};İmf%{•7
 ²„@11xxˆXƒ›ß1GZD”­t¶v·"qq¥Å¾]'•ÿù€_˜Ršz¡q«¡ßC(À£‘Ç7GdÿÑŠÆ î³ğg&µù[[òÅ÷Á÷î	µŠ*Ë/g8‹göš%­(wÑ¿4L|/-ÖĞ^é»i—vf´ŸşÙ› H!Ã£<`pÜ£äIêuÆ‰5ßnŸWÕßEY!Z™FZ……F-
ı¥ÍM?À/!?‚*
ŒÌe¡h<Ï¨Œä2>;#˜ß9P»Ş DAû³GöŒn X¾@œØ‚-%¶àù³SÊN+k_2#ğqòäÖ´…4èVÍÏiü”÷CÑuSè¼²šÔ>nôğgÕÌ]Îı:Vİp‹½Åóùvõ?TÒ‰3õ]#g˜ùŞ Úº¦XÁ‰¾ ‡Œñ½Ò¢ğ(„xëíòŸÁÃ'àÀçŒæì%A\O¤Çn§2òUiªŠQ™`gÁa]…½›;kp¯\Y­	®4æ6Ã‘te­çmj|¹x ycY]Z´ıj½…#Ñût.Rş!Ö5;°mµÆrb¨¦üİô±ô°’üg,.E&€Hô2JĞÅl9>c(ïÇCšãÒçS}Şj—"¢»v`Q¨²²¢É ÆFdJg½ä°ÊæÖ‚™©=Û“Poyµõˆƒá,AIæaµ¡»8:ÄÃ)æË¦T8e=WÍ¸ÌJÊ=KÀrÎğs?‡ï¤ eÆ+ìB¾
$>d2â~ <¿î‘g„Z"gÏ±°9›u6¶é0¾^‘»¶µôúDDWú=T¸«v(‰j9–¹ª•m˜%1,†£ÜÎ™%NIDcv¹—å¤rÁ˜Æì2Óc‚˜Ñ-BÈà`±cñé¸~c°}¼š$,À›.™¼ì]‚sÕ—íæb`fGdDr³ø³¸’ÎYy˜(‰šBäµaÆŒ×©Äµ|Ÿ(¬®ôöTÙ‰ï&qq:íqam;évtf Vä+ı¹\VW[‡¾õ$«ŸVõ=RÆãóSQåÿÍõ`A61Æçsëâhvuéx¼(³ñ7\^˜ëËP×!ÜÌ,$•{H|—™LeG)SjÖ!Á¶$ñÉYv¥>ùˆşšÕ©RŞ×âİ¡*…Ê—:—z¢]4´SF©/RÈ‡ÈµSÓ!ı§à|¢S9ƒ´çĞåEÙ÷ñ4fM27‡L”/ –(”IªŞë{ò„¶Uµµ3ü”Í›¦¬n£w€•.hS/W!˜šô¾C÷ »kr>Áà¸]2]Ü¡·öğW:H×z¬DIñL´ú+bÜÔ]:9O%Æ‘êšv§œ:"NíI”ÈÛ‘ÌÌW`D	H/(¼òƒU’6&†ÀÔPàé?ü×P^é¸êùŞ÷zŞÎ!pvnà7™Òš
Üá”}ÁîäÁZP¼ÆlÇÑê|kË_­ÖülØ”¿g6§åÍ?+<Zkgğıgs"öĞ•‘·¡eYõ``ƒvüßKx–±W)íHİ3	\0U›«Ğ"…õH§ŸÎçæ‰ğh|Ô—Ê“È™pšóû›YADÎ—¾÷ŸeŒRvòGhY¢›İYnîsg”›b‚¤
Û£3ô–^°†ÜĞÅ™oœâ;%kµX·\Gd¢¶Æ|¼}Âv:ß+ÓSÏä^)!u_3'óe1¯Ï¬A˜ŠÕ£şä:’2c2™„‹i6ïu&§ÈÙè-ø/T¿ì àUn´!5c[/ëëH¥/õ½ÑÑ.44{Ïmj‰¡¨fèRŞ»Æ­ñ¥’íx_‹ˆ2í'9òİŒbkrè;‰è^­fä±f
ä[lß¡ı4¿
	ó×Œõ%!X8[
ÙŠÇ=ãâÙ-ù£›ŞÇijGåÕ:§i‚=Hy°Èİ¬õóÙ,R„eœ½R«ìş¹0ã”e/Bîë¡\H¾–~‰€B+°²6ëmx„Ä$ø†Ê”SÆ·cÔ>ç#Ğ8k¯Àª©~CaqücB
¬ÔÚ ÇÊY…`|šÈ†»´º4i½ÑÌîãjäà1¶|”2±&L«½¸‚MNõsHhN¨ÿC	[¥SGˆg~rê6D›%‹˜eòVœ‚ı§_u%âà(ğg6~ö#"Ö††Zr Şœ…ß0ë±ÑÎoXß ¸ñğWFœyn!«PUõ½êÉéª®ô»×JOPëÆıÕ%?Tˆo…NudïÅÕôSâÕp&§b]­ÏVp¿Œ0‘ÿ2c£$Zûz.%Oæ€v¾…¤#«—g`ŒôñHG!­ècÙŒío/ëÄÆNŒõÏ9éÒg¡‡tç‰’[ÿßsLvf	ĞÛŠY¼6]·ƒ?q•µ`®èõVN×®Ïz¸æR¯t©»”yşwá®Şb`S)ˆ¤ËkJ6×’3êu]+è`wIçf°89õñiñ—³J—W5‰˜xÊv0wAì&ë\Ev·¨6ÂW)sX#ıİcv\•~Üv_OÏ+1(ÍËÊ‘Ât«x“g†¨v¹JüB©ßPA*¿éa™ú’iIEÃ5Ü˜ç—šÁx¹‹ÚgsÍ€eæiè7uÆLFÁà×j¡Øˆš†îÛì“Í% W!Y	@Ö,ølB®Œœz³œl8ø‰Ê-»H‘HºNÅ·%^¤hkõßEÏ×[6Î&­ŞÔL­}
ö÷‚Ê,Ùæ$ÚÎ7Ø¢Lªf®¶¡uL·RZ!YÂmíÏñ8uÌ‹—#ÓJM®HÚªØ»‹-{/O°ë£g=…Ñk=NÄ?Ré%&òn{Ÿä–ÆrŸ^Ÿ;™y}J±¿éôC×`y. *ìZ¿Åm©Í€ë3×W-*¬¶¯Î6¹_ÁæVãÕDæaM™9ÚÁbĞTJIı8q’n\7£Ÿ9fÖÏm'”V¶É-ñ?–&”?­ô¶)‰~|ş8ìø R
ÔäNóµc]ıEŸ~»üyc¶DŠ#ÁØw°tÎµ»„V/Œí(š´H:Ì¯#°41 mï¹ÔŞsìÆ¤ŒkkPJhløÜ¾ƒê3Sø68?°YÁşaÒ$¹a´ÿ‹¾3^¬iyÒõB•ogïYs{Ò¬¦Ö¯ÅwefÜC)‰ö#€’¼¬i6‚‡Æ/;®xmšu½SšØMIÓÚyõyÖBğóTq.İeÜT{}Ë„$¾Ó<V¼£ıÙ!şC7×n\cUü3@4ä:)¸ßÏ#/gmy¤õg}²à mZñ÷Ãy EßKäVó‘Yk³¯Gæ¿]şğ†·(—ô0éjÏÉ‹pÉı%­7rP>£T=£í|*×!1*îÆfpx]ºåóXúß[‹‘  Ô9ù“è÷VHBcí©DEñ|ë¬fò[í	HÒ­Q”Ôf,xÁ<ÓßÇóbáAË(º.D9ûÍºÜJC=~”üPg@Èı}
ªÆˆw\ÆqÀÊöVjî¦ŸFdÉÅ&„ˆ”§Ï£oB=A†˜Xeèd;ói¬T·ˆ(ÓU<!kÂÓ/ Æ,¯È ƒ-Ğõ²°Sğ[`d‡Px«bŞ	àGïÈ/óË·R<{©iÂ‚8ªZn1¾C'l9
¾Ş¸÷¼*}§ÙÚvœ]¥??ä0¯™ğİ^£g°‹¦j¬n9ÏC.}–œÖÿ`À½{Ì!0˜{m¸«Ñ;‰Â?âa©ÇäşÏ›C_a>İÛéªrüDnWšÂÁ%ß¹å¢İÅ.ı‡‚ä¢P'f
+îîØT½MËhä†¯3ŠaY¢S˜÷ã¬ª\UDÊ3s­-œJ­·C4Ü¤F¡»¼ÃVì§²Ø³ÌÇn=Íë¤@è² œ›®Øƒ¸ÁvƒúÕ˜
Ó±İ?1[§±€'Ùf¢êl&&`À¾Š2‰!,œ+“°ÏşÏ~D"@»2)nE%™­\g;ï˜9.Y~øB-Mïb…µ`¬Rä¶hµ²sÇ½¬d	ñk0¯éÆÿa‹éÎ÷qO«Noıw<hœR¹bà¾vÑ¡‘¸mÇ‚.GœûÎ=üu~‹÷Ì[_œí&è¹-)nÆ˜Šyúå-ÖB+•ˆ¿ˆO1,¬¨¥„†1"Á„EÚÛ“ a|´®ñÑ!’,¯\ÙªÉ ¯’¼ÿÍïÀƒvÔŠªá…#Z-Àx'}š.ÕËŞÔwi 0)*RêÛ!´İp5Àlwû¦«ø“Ñj¹5tgíı%¹Æ!‰#b=ºá“íx¬f÷‰6ù$d}lykn:î[êñyY48mÀl_çP€€×0LÕ6Uæt™e‚%ˆMÜí¤–ÇÏ£ÆŠ#?a(U@¨fAáìVë–‰ÁøÖ Ë:Öå­¯£%·xQ«è< İµƒúQ¿F›óÑöMÃLpeøKåÃîÀ&aœò+Ÿ9U™Fy®‹AD…Í_Š—ˆ9©“ü¥¿)ƒ÷£W#Qq¦ÿI¤Àdê¨‚¥O=ƒ]Ç}Ğ‡4'q×Ãê£À+V‚ïµœÑ,upPk{L"x»Å¸äUå2A¶’;U%Üã>°æ-Ä• — t‹è8ê¬ˆÂË=·iØ'"äÖZĞ¾â˜„à°³­Í9#»_ıÖNß8cŸÍßmSô#şêèíZ•ïyvoÍUÇRÜé·<†÷º7ÅÙRû¨sF¡Úµ@*GhêÚJ²ƒó*¡Å=(JF”	U~ÑAœ{¬æ¾Ó!nìIx:d¸&ˆÉÔéeqªQÓà*Ä6–cB¾Üo¼©°·nA$—9Gåã4ƒğ	ªGó8gHfî‡|n€‰Î! ?Ë?õ+àˆ+,Ü2K¯2½p‘|ù¤õëV'wÍ>’wpmîâ~GpÑîêÕß¥Põ
Z7:eÒ{ıàÊ·Œªgº]GñÒoÁÚ
ş8—öqAÃ.á@sÃÆóŒo+¸å¸åİ+Ò=AV6ÿ‰IqâúöÌ êÖŸ8¨Ëqãùs™åó:	ëîá*ñ·ÌÊÚ´2)Ç´AV»øÇç…BƒŞ·´‰€xˆr­u?ÇN7¾Ç5rhîï… Ì}A…Ïô…±mK&q'
pàÇ¹èó™™àÜÖ$BNşœ¡Ø¯aö.Şz0¢/È2y¢Ê,²ğFÄ•äì¥Q­C§ôñÏ~ÄT†Ñ è9¿V®¾è§%{·—eêãÌ›äÒCÀ)tÎp^ÒMıÔ¶)§e#	°Û^;CB;.Õ©w½„Õ˜?5Ru 9Æş—%ÎSödW<¬F©}e¬½qì}êŠ’aÙV¡©"›"bá²=PEËIÑQ)[;D©Ú]lUúDÛ:Ôík"í'¬VÎt$ÛA‡zõ€Ô–+QEîñ2‹›°Äí)OOÆüjk~K4lªqí[H4èm(ZM%'¨àğúúIª6r9±´0š”Â·ZFO°fåAš¢f GM§É¯!#QKºÁxIa”ÉË\Wk)ÊIÿîèn†[ÌERxF¨ˆïı© ‚ÛãL1;ãvYŠöwRÃğp"S,¾çK;ÄÿKä•Ë7‹ğ]”|¤3Ü|"KÈ–ö»šc©Ezÿ°ï¼o‘
¡,—3h¯%ÀiÌŸeGy;ãz_­â”]Åpñ½%€©dê¦\4ìô)†ÿœm'¬—»NXŸÄ£ÀÂ²¿Í×’á‚ìõ\VNÁå_÷ö+»¾Y¤ZÎª]@»•ûà©µ\¹ÉgEÇÎ8Ä:æ}nAFåH¥{“úázT9TPZ/.Äún4”ybzH "ÚÖìa`NA·Ûşı‘DK"ó÷’ìÜğ§UŒUÑp—o±š}„3+&èG'j’‰kÎ6óï:· İ…hç i%	6‡·¶şÏúµƒ6‰”Jo¹¥
İ`ó¹Êİèğ™£¡¥Wq£+xëµ¿ås®ÛLzc€b£ÒÏ¾óø´ÿ2ƒG	}#I¬yF=E«0¾@¦;+ª­µj*ÚRµ~µ )µ0C¢w«	ğÆ
YüÓ"6\–`½ŠoÚUGÜMNSœIBtÊ³ËIğõÛU;Ç)²%<¡Ğ¤a²Î=µºÿÌ„2–ØdÈ,2¾àªU/¶é×BCÏÆ˜{ª"råTnU"õÚKA¨¦Y»ÚJ§cÕj`ë0•kÑ=ƒ†ê´M?ïe%\i¼C˜¹î‰ÒªÅ¹À‚ÊUüVˆ‘#È¥ÕŒ‰şeÎ@<>N@\²û•sš
ş}Gß6sŒ*Ô•¤âİ‡whÓù>ï¼DM;Ó»³8İµO=¨5)]Êg—Ÿõºb\uO©yÇz†õ]"ˆ¾v~±MÃ	97£i ôÙ54øUÍ·Ï½q¨B8~{’k§˜²áæléø˜,‹¸`¼#ÙsVİdåŸ=]yP/´ìv5—à¾L¥Ç³Î=Š4,©–Âx˜Ñ(g	2àôRæÙE{ò¦%¬KN7ÈÕ0dpğüCí´—½ïÊUs™¡'e3Ó|ˆz|!-^®55R}X!Ê"#/§;è¹]òByÈ«1 Ç“ïªfúß)¿Nt&ˆ›Ïœ}İÊHE”à¶µ_*›Ş°x”7Î¶åÖ~Áböš"^Å8= ¿¢lú†£Üt£F@ÀÈH1æ¤B“¿˜ØÕ†|ëaõƒß±]ßNOøÔëFbçĞ×¶\@òƒx¾lFÙ±[Û—ãZÙU¤MÕ„”İ†Äî”ıf*Lk™X²…T¯ô¦ï†¢¶ªw»å×;?3ª˜ª"gk Ûp‘°ÎŸzÍËw(2¤lø+™ÑĞBšñaÃp(£±Ä¶Óm¢W¹ÃŞã›¹ü	wò÷Ë¤^sè`IAÑT-CQ¼ğNf—=gHN9ÜÖqÓXÇ6Ëã¥Teg¬§÷™]|jé¡NŠ[ÓüÙS}
ú°±|ëL™.Û°@â€¸Ğr€f|ãÛdû-ztz™°’øRš{áV—;Î©B€œ7Ams‘³üÀj¤Œï5‡n·:¤LšC¨Ö½9øà,hsŠ6±ìƒİ·ÛÈšøÒ¬iŒóä÷¬k¬!šVzˆ¬i )À‚¿ öúŒÃ±ŞQméğ-¡j »/ãß"Ãƒ¢”4kd=îôÇÏÜü—ÿà<[g™âÑœPç{“Ààí¯lF,hš§?ÌDÿV>¶¬fÇF$Ş”>]J-tğ"²ïW¥O[Wrr!zî[¯_®äî«¦ËÏ‚%ğZ2¡œ
&#?lõÛ†²"¨Y5l„$aÎà(Ëz/ßiwâÙ¸Ùqµ(K»`Q^¢êÄ÷ÿã–Óë•(åîu~©¢<9¹ Ğàì2ûw­÷x5ËÀr›C¸ ÖŠ”\ì¤lÔK5Çâæg¨~©OšF9‡ªbëºvÁZH´eŠQ¬r ®¢ExJÀëÃ‰TŠQzÍ|£à•ÀıÁ[YDë@OÆ™h¨\Eò3¥®?)‡ŒDq3_“:<^'c—œå€•\îóëÈ€KuûÙÄf0şÃ4Èëp½¶¸Ì)ÖÕ@ş8µËÜÒ0;HPu5]ØÓÊ³DãYÌ‰$eªÈt v$wç¦Ë4HV†vß;†ˆ|gá-ğçèxÎËnWı• ».tš"Oªû_ø—¹x`é_ a ´jNÇÂvHQTw°°óiÍf€	ñ
—şl\kmVt° „×ó†™cşõI¨e-ˆ¼Âá|bMÎJ(Œ¶oŸ­S[¥¿Êù™#ogÆşcšÌòŞÌhLõ±¿£>şyÎp†ŞõŒlÓøjV•ª†-±%(øÕ(Y¿qJİ§Ï=ìÅ0·øÁ(jôo°f JÊX& a„Á—æn’Špm0
åû2ÄaE†Z¶MdIİ ;ê\}¨¡nŸêõè”Í@V5Ãö´å7 º¯†/Ÿ,—Œe¡—óuU@ºãt–W·˜É›ècí+–³é5?¶Ï|å:ÄŸ\ÇœCV3Jk„­^:Ù‹ÊŞª1­)Ù ù”aÜ^¸çP’pnœ[ìFW8â7xÑØÔ} z‘vÊ¯c%Ôm[M­uòØ3#
´IÏ=Ó‹« Â I¨|s\¼é&<DGäún­o>O»zË%tøôCp…IäKPQ®¿äqûÊv>ü ©¿´à z›9VÅa€ò,,X;/ÇB//$¥‚U¦Ã”äFÃWXK7D/F8;"¨.RÚO}<ñ¶Û’ı°°I¸×2°H¢`¦€Ë>ñ¯‚T;”×÷wÛvµô0‚;¸Fjæ0ZÊİòømÑnmÈA‹?ñ 3ëó DÿùO¯Ìå†Lê»Üì _—ba-‡«‡Ø¾ÌNO‡wüèLÇ1ØlĞ§B$»{Ö„úQÑqÿ6:q2!@lò#£}¢À¾j#xÅOºz0ÏûT{§ãÜBşxøƒ\“•­Ô4=ÙFx¯WHÄ«,·°O]²nd«ØQÍ¼´!­Gñ™5<±$£VvÁIRC[9=Š«ÿU¼ é;lúå?q&…ÊmSWvÚ¹äîéH¿qÜš*Tp4q•#›»QÍ©«…³.jWÒÀøc«©ëªp°^£J’&Jßé™‹@ÓM¦+P¤ÑC*¬vË(•A%Œßç³
.›E227ÊUJğÃÌM
 ÀûÚ{#‡Ë«Ò¶ˆ–eÿ¿_g?D,”„”.ü'UlÛx ‚€
¨,¨§¸›dJÃuëÙ¶ãD×ûÁk¶ÂÙózö‰Dø'jxLÕÎÕ§=Ä¿e»ŞV«ŒyÈPÒ¼¦D\¨9¬za^’—lƒx¤É^&…/Ø_³ı–n4†8F¨£¾ŞÅ± 9( 0š¿,İÙ×{ßà'¸kz¾Ä$mnR	ÊÁ½©ôQ,ée9#´‘,ŒÛ¸OWsˆMßÁ<´bI©çMpkÚ‚bªw$`{©7>q¿Á-¯}İÿ‹Ù’­ê
|ƒB¯¿!lÖŸ`ÓrÓ-¢îˆ³…ÔW9cEC9Nİ¢ŸÕ{%/+I,59ñã.#=PFâv—AÙ—Ò0ı:'d b¥v©b†Š¹~èe$HWZXçiy½xº,SnTT#ø]
îAf5YÃo„}•µÌˆƒU¬¼(û]uÎ7cSñ²WkõÏwÀ]d™ğÎê½‹LaÙ‹¥ê‚(8Î«mĞÊ8q0ò7m°Ds:q&w7	,Z#[Õ«õæ7ëk½¤xò‘„AƒR‹ËÏ×ú@İÍ;ö«$¼T ;Ğ¬»xál	¢‹ØÖÿ³X°ù
YĞÍhníìù‡vîÿüŞWYTğ)gñ~îz¤$(2SØA[ ™^lvxz½£k¸+µ«ÕQ9§#zwÑÓ­0M3„?¾Å¸Eø2ˆ/ÂöAÀË£úkø[ÖA­µ4¼êø4šÒ£Lï¬s_²{?ñ”)Nş9†ìÌ5fÅõF×nê
\ğcwog©xÎN@RFÃ Ê'ğ®ª’²€¯TâíÜá…$j_D\¢ !Ô¼˜êQÅo‚ÿÄ¢{Z4Ã’äò£*‡{ëLñÈ'¨ïh††ĞìT«•¬K)5/¸+sZêÀ"-drüY/·©m`VØ¼	ŸPQnHÙOå%îJXı#Nª±}'lœË+ç‚ ı{'E¼‘®¡d+]6œ×ƒ“übŠp¨dÉ^¶J4ëªœ¼"ÃiïmÏÕc…µ›šÅ^–¼VÓIf±”ê>(DùĞİvNò¯*­¼\N¦÷‚x€;G^ãÛŒÃùÅÁ¾'wµj%ˆ“íÑÉ°K 
Ôş?Í±D½º_UÎ#åBİ¯?[0= ±•ÜØàùşCíë×šN7ñ7c_]¿…S×AJ*Ğ­©îè£	±áÒC€‰­PÃK2#œi9Ó`İtˆë51u–(jXÖ ÖİÒÎl	İxlãa[‚~v2´—X7ÇT1²³ƒE6à,ÓMÓá»5ş(n®EÕsÿádc¸q”ØÇÀ˜í/ğÙïåH/û¥İ5nëÓa@s²hëş^šùjmg¡®;®ÑdlÊ¸JÁ> VÀÑ”ªš^U`: ‚vxÕkDen·C#Kƒ‘&îö[“®¬àR¿çlöÛwß,6lRFÁ ØĞ®Ğz!„TêÚ{NM=ãİÙüÀşàèà˜Aû‘’ÃCüzoérm©D®<íºObwó•	d½óc_AĞ¼3j2ÅÌùÁ0ìe¤ÔŒyè^‹Éqç´~g
â_å×ıw-¶äøıİ´6Vh<ï’Œ‰ÜŒÏ¾—us iÍ¿*úäÃƒ[f/Èc¬ü ¸E“8™_²KˆÙvr¯œ¥~Ä€’~xqe"{êd´¸¢`ËtT‹¥—hî[S—ªëğSÜ®´·¶ñ»±DK×í>±%ÿ"laô¯sbt÷H7îd}ı†W8ÜĞ»”Ï2Q¿ß¢Meû*-3*(]ßûa¡ˆEÈ~ñ€\RşÆMt¯+ŞDxT<ªÃ#ö*¯½–È Ç9š÷%÷QÔ-WB	à÷irEM3‘éÇ–^õ¾2l‚îƒTú„Î¿z²µxßûºX«¯ øø·c³Ò"ŸŒ÷E“ş.ÿ‘¸D”'¡bG j¶;Djø£êb6µ½ËŠx€Í é-»8öŸC6ş£@LÕÑ´r¾1V İZFFˆv4å¾¸ÃIû¶ØÕÖ}fÖ;<¾†põÀ}?'slŸ[ Ñ—s³oÆ·!ö¼ãÀ»zy1HÃ#Ô)“ˆÈFGã"IåËÇüÏgôiš¯,ûH$âÕåÅ7©R‘à O.ÙÑ¦íXîä_±óüÇ}øÕŸez”A„PØ©ìÆæÍ*Úá¹²…±ˆë˜ñÔÆ«N~Ë¨ûn>VtN:ÓïÂIÜ_8-@×ŒÊªË„ö¼/-Ìü7ştòjÉ‘v$Ş«ef²¨qÒ¨Ÿ  XiOUÉ«56 ?cih’bü¤:(FûST \Báåò*ÕxL‚Z4Kx p„=+7T)ù‘g*Rß¼Ç÷$MâƒZ»IGsÑ‡æ9vş{4¿Ø¡‹yÉ§FKŸ9 WÉ°¾@Nğ]ÕT1cÁ¼‚’|m{˜
f1ášH`fÔ9{"ªôIs'T9Hß¢=šÅõ‚>â§ë1`«s-à(øÔä“å´ü­'E}€6¡rë"µYOË›<ªSŒKp;Sªúşé	üäb™8fpzB°	_>¶ú´"ğ³ù®(ø‰_*½òß)ç"f<b%´åû;¶h·o`c˜šCãñ‘ˆ–@šP¥WIvnfO&¥L»^÷•p	¼«®¡> ëóŠ[Îug¿YR³ü9ï“™ªŸÈ>ö±àGRòÁºml»îŒÅşuîS‰0\«¯§ÆğF_Kq¾¤jE;“·DD]2—Ã4š~æ<ŒVïæöÿÿú49;ˆ˜TBé°Ôè ¦Î)1a&=­¡B’]”^¿;¡zî´@=è7˜,]À6~ÕŸÒğO†y?6‘`zöïB¹6yoÃ'§°H^H•;@r“7<Ñ¼¾õt?EÁ¦ixŸ8p„,q@(ïÉ·!Šçc+>è…D­¿Ù÷läæî#u0`ÀaœğÊÁ)!øŸ_Ôİ‚ãøS:‡©Ó<ís’½˜s7§XŞÊ¸ğõİäÛ;ÏQRpëğ6Tj1ÃÅv Ã¢x¦Ã˜Àë“Öaê§ÈÓ¤CNæD”òG¾"ó«$–Fpséì{û¡¹Ğ/ğ/ıÇJKB¤ˆß5?îå$³j¸ïiáÛíà<ˆÿqÅ5­#÷êµÅó.åğÀß'™/S¹>?+­F&4)áêò&'YhÂ=]fê$Wö‰İÂ6   ÊEHAB ƒ¼€À¶iQ‚±Ägû    YZ