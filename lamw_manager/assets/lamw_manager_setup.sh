#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1136148317"
MD5="72ea630d05d2b6ecd67e5880bb69d14e"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26000"
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
	echo Date of packaging: Thu Feb 10 16:56:04 -03 2022
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
ı7zXZ  æÖ´F !   ÏXÌâÿeM] ¼}•À1Dd]‡Á›PætİDùÓf*úWA;Ïé›ï@¬šó°ÃâBSø9¡­—×¾dùË¥èŒ^„
7Ïè£oÂpäÁœkFĞ±O‡Ş”îa¯½s»âMcøÄø«5Í&^û¤3˜Îéfp´–®Gù6;ÈDŒi¥ín“³ÎI¨m93¢Ô`±ğ	Tİ³(ıYº%Ã"½+Õm ãüÎâµb=İHÏÇtüÄfæšôã8İø;nB»–ËÌäuKŸ56ê-”İÿï…şâ…'û;cÂç+¸+nÅ0Fæò|V:åB@.coUH^wëë=·o¬Ä®[)Y¸âêø¡«üŠŠ«Ø·ñ«©•Q('Z^
xh!+Ò§Š1ˆ9÷¿wêòŞ/_†ú§ùˆK2*>¦ZâY£wû1hiıv–Ï1PH.¸Q	{C*XÅ_“Åoéáû¯ŠëK”àc¬
wcQ5£O4Î	ã¯Bã‡í^Q›Ü]ßúò. Çó‡&¨Õ¢‡¼¹“)*®u.8Q¤ûàüN·3MgĞfÚP´0ïŒöÅ©/ºÍ%Væ‡ÏI÷uÍ³÷úc?ÇŠ<|dÆÉ'“B®AÔ ;³*ŠbïRğÀ–ÿR(²˜-D/ÃF×¯ ¬‹²ekŒBº|Œ=gPH¯ëRYZ°Úş&€d’nµÃşiŞ5&b¶¶%şî”=€‚¯J
æ7€¦Èâ^ˆ•šØP–ÎÚ®«X+âƒ!ørıÍ®o¡¡VUt…ühs²ÇRZÚ‚ß×8‹İÅˆ¡8•q;l™/¬O”ktLÈü¯­ò_ş×õÀe‚gê§qwá€o„¤Ì h•ˆÆÄ±ò_–5{xödLÁ&—úÛZÏ–¾ùP.¯óá”(q >Ï™"EB9‚¬J8ı“Û€šXÃ–I>aÌ–ÍNİÓıÜ×Ø¾¥åÒ‘äƒÄ}òØÈ“ã(Ù)WÀ‰ïNûö%£ÆóZ›‹ƒ1“O¯µøÙzŞÔ”\
õEòÏP¢Åøk·“Ô`¯Õf’Æ¿»&÷³—}İ6û0Ãd$r8àÍá=DÇÏáÅLÂW-£j’£pY+TœÎš¨„¸£,ĞÊâËÓ$jJéå¯?Êo5}´|økôêdM"råÎ— ¢G“ñno- ùåÊşÅá y°ŒCã²FïÒêéØnÎJáŞAtg‹UÄÚL5ÉÆÿº ©9FÍ 9†ñç58;íLXå‡á>©³(·+Rpv)Y¹ÀMD‹Ä7rªvc˜¥Fé®FSvJÎĞ>| ( v)çˆUn¸¬¢tÈ'¦;â="’Å2a¼U}Ë"Àãı=å#U‚Íh¶²Avšf[WŞx¢İ1#’øé»Ş†cÓw`7@qàúIöQQt­7Êw¦Àu½)+É²L¬¯wåƒí·ŸË¦3Jo—XâfY÷o6Ï"õNlQÃg%1·ĞŠ0r…–Ÿ9¤bM¡ìÇú(– ®#DDˆ\Å–ªŠ¨Š…ÿ:Äµb§€X_šcÙeSæD0Êòö¨Wv+HVÁìA»	S—İİGö©]=FîªŒæd"ßTÓ“¼_ŞŠ;çşCØªÁBÏùç^Û)f|-ø&•¢Îë¡dÚœ2 W)+åóş‰ŞâtRlçÑÆÜT1Q[wÑ¦v)1ÕËÖ$?DåCÇ=˜%W#¿&xÄ´‚H>…Í¯®,¢e7N„*_Úù”
½Ç=Ñ±˜hƒ×Q©‹xpmôX¼êYÏmiÇÃ@¨ëWÒyë#ŠŒÃVM½Ü©åÓÃïĞı©Cè‰Î¥uä•İÁ”>p.³f°["İ¶5²U
eè›ëA]Âr'zRv¨‹¥‰ñq¤c°eÿzÏ¦çKp3ÆyHÑĞ'ØŒÌ±ãj`Pú¬ónÔNÈú„D±î­šú•°»’Ğ±s:*	;çÎi7©¿ş'¿¢¿·–øÒuM£ÜtáQPãQDßÇ½ß2ÜR”gN–°(İ}"Üå1az–·®…%ùĞµj5:§ŠÃÔ"½FÔ?İĞœ—tû@d˜ùÛvpz—ñ·wyÀ^îNİ9QéÙ;Ó:xö¥!­wÖ.fƒ7g(İó-ÀIé£+Ó
”/Ü	.‚¯®èãÙs3ÖLqñ¶¿¬\’©àÖo¯E½‡ÅVˆkß3Nq¤)>o¶OÙÓ½-$¬°ZQıæ8Õé¥v;
lbHe$É¬3«pîTd™ªnMÉ}d–í6 R^\Ç:„nREnh²"¯\'ŸQGÉdˆ|=²4|h­èälÑâë^§ÓÈÿ^Eô»¥2;Ni¯å­D¸ep8<!\‰ß¿4?áÌÃULiy§Å‹+§,Ï®öˆIÅşg—®¾‡f‘È\“ôxc÷­Ûu’÷Â4‰Å¸Ğ^"Â–şPaì·#>ˆ›ïÂ‹F™û=ACFošDºèìÔ	ˆØ@=XHBâö£öè ¤…
•­Íˆœõ!ûLìıpXFÚ–#-W¿õùg3
´Ï‹9’·¾Ør4i˜º)`ştÉy=L’¹#ò.hm/¼-²~1Pw(©H“~€6œ*;óKo:¾Cñ_E%5§¯N‡=I('Ã‚«ntzbO¸¹š®¡Àº¾dÚ!%/3$î‘‘EâÀòJæ„H®'N9'øO³!Ÿ·úErû±’çP!«
¢=úH=œÄıê*zóMÓ}Ê-MÓ`rpƒÑá¼ôb‚Bn\^hµå„NÊNw´g„§qû7ì„ I4¹2£-]Ë“doé™l<ºß]“Í¹K}HÅìûÊ(ú¿µùõ4©ÃµÈïªZ=…Ñ`ÖÔ¬
ÿag\¿}dØÅc®EeÜr¹~ÒÇ+¼1²›æŸm­}¤ËşÂEü)Ç(2`d*Fçê\\[GXŞ=ÄÃŒlŸX–—Ï´¯h‹ºá¨tçáœW‰¾Ùû‡‚ºä[M{œ*ÿéÎÇ÷Ô¤ûï7ÓüáHl4‰¸Õ	œ—W® €ñuôĞÃV-Ù?…®@.{¤Œuq”áíy,RdOqÑhæ¬ÁÂ£S´»2‹ Å› Ùá}RÌ¢V=²mp'b®.66ôJ°VuÒHŒ§lŸ! CéŒ”ög±^°¢Bêqï”ìqM^k9¿œœZ+·š»Ğ`fõ€­@°uL«± ˆ’4î˜†'·¶©7ÈËĞw­¡Ûæ°Å…-½¬‘sG7Ø£É´bÅÎ ŞM¿>N¥P¼ÛvËÊÀ7>ù;aä|?“¹‘)ÿ¬ì-hÔƒ°°=) dšF:›W&†ó¿lÕükõU¼MÍŞA	µ&*S·L^¸Ñ%İ¸ªĞrìïoÔ"«î >£3¿r¹,»ätR3|w¾¶ø_{#ƒ“W?6Ë¢ãÈÉk€8Ùqµ=ˆ†à&„ùèkb¶A»~«äç-fÂˆ’ˆ¦â¹W”é†ş^åô–0^	i Ğ)B>şvO5ÊJF”˜úíANt‡6–1‰PğnEÊ)»’Mî"u.¬Ñn·ûÄş‡¿-?9RXÕó_I7Úó¯AÜŞX`«2npĞfé™Ï` ¸õS¶ÄzREÂÆkˆCT™—ÄµuÜãTSˆB·©8i7£é:0¡$<K–ú“Ù#Y{Y5MïiNU«×ºNYàîu¿Ãî(soÓôET{
Nßê¹£ÈŠ@×õQ´-Ì5éU=t»ãxRã­P.Ù.h4‰wæd*²ç3bK64 J6ı® ×§¨H¡f|¿HZŠBÁ´(Ã¹ä2g•tNR”ğî™?¸Ç ¡”»¹èi¦@ÍKÊ*&Â¡° ¯/œU¢3æ^İZ{\Ó‹9‘îÆ&ô×+) ‹’ºÂæ(nR¨x×wN¾§# ¡fÌcSÛ‹ÉÄ†Ä>Ç{|²‹ßÈHj×|–Úy÷j¦i°jKÜ4ùº	³6„ÔXã°W»8kHñÄÀªâæÓîq¨À¶_‹=pûÒŸf­®õşTŠé`EãJ‡Q97U&sÄU×FÑœ¸woà-ƒg§%87#¨;Aù¶ÁÔ·hyŞ¿şå´Ò˜N%dëtº/æëØï8ÒéZRyd’¹‰‘WÔ|U_qNB¿?m Zu‘]l÷ã‚«}¡J‘œS3³çøp7Ÿ(û×ÔqrÃ~]?Ë}‰®29M$å´«ˆ<4Q×„95ĞU3ItÍ¬]Ê2wÙ)ı$Æ«­GµhbØobB¹º¡Q–ˆ-È=ş ± ² 7h///1¿—WÎ§òë/¤µº{‘›dj)‘¾f2E®^tÓè¯¸VÂ¦ÖÁaT‰™2†ı2:iÁ%-ó'1îD;uÊH<%hØ| Ã}pØóŸÎİ;Òæÿ¸|’ŞBª½×q×ñA svÎö8†`÷Sÿü•¬%€’t÷ç—ÆçJ@Á%—dƒ‚—MaÎ€]6œFú¯#2!¼Çäô „…Qê<,gj3SÌ²îfâ+jÜ¶µhcáx@ã6ÍŒÇJ±mÔ•ÿËc•ğÚ¶Q€KÕV_G0Š®ÆçŸ¹y0œ’½~ƒšB¹ì[<qtªGÌ!Ëk¬–8åÄ,¸Ùõ§Æ"n—«ÆP,Íä†ÈÜ53e÷q—)Ìm3ÚCaVBî,][àè&fws¯8zóNe¬ğ¢Õ™èdÕ;í$5°’ÄlÒØÕ²ûÅVÁ-‡î…Mh®ijIî¯]¦±“ë–C"ònï5Àóîç m>!L3µ|—F!ÂéàêóÏİ$}²‡k&Ù	†2u²ı{1%İ•+AqJÈÁOdçó|\¬ÎM¡1CÃ+VÂ÷:t‚l2ı')µUU×·æÒğÿ)Y'ù&åõV¤7ú[Q"1#½j7²kÎ¸ŸjÁò‹ğ¡_Û	 ËêYş…À¹°£Ûqy¾öôÅÈˆÒ/‚á<e™´'2ø%÷k€·óÆön®ëŠüÆÕ––9]¤ÃCâş+ë…Æ9~J‚E*•¥b€p"¼äuÔr>k¾]aãz»9‡‰SË³NãôÒ*Ù§`ú²ôÎı¡jÑgÿ	ğ<ºnl+a•Ü‚%Ün±`ÿ_6ŸIV!Ê”k7ŞÁs8ªû‰MjZoºF
	g›_N"¤Ôjø¯6¾È–F-í¼V)ÉÖL‡À\àT‚sÎcßL^Š oYo€ÕM zß×å’°‹ç3¹©İ¡R	ò¯·û¸]æÖ´+ç‡K„áQ‘.ô‹@Vnãì–	&H{Ğ]qZ“€	¶…1©¿&ÅÆÎ—º­o/7ÄÅ`ëórş€Åœ®íŒÅ=æ^Ò#Ê/O˜¤.›@#LÕ8ûZxú	J.Í®òõå¤Ûd¤õj€g'Êö)|c}9‡!Aó'‚÷>|[Í-USÎö»#tGOˆfR_pï]n™Ì?oóÇã¶iÕ¬ê ÕÀÒK.c/„™ÌL×:gİù¸dŒ„ŠlíÄQ0m3¹O¶´)Ô&öÃiçfƒ3ısel}Š9‚°åŸ“ã™ã˜qg¡îªr3s¡ÔF‰ğVšÊü’%mu¤Ó‡!{jÍ–˜:ƒŞ4[6>¬°j ½kê’ÈUë­â ¸Ä ZmUĞ‰U½~Xß¨e—ªÌLß—/É§ØÑ™S®Hàì¹ü0öXØ´yı[†3~ëş’/¦ÕDƒà¬€è›h.í>üÀu—Ûã´”9ÿ£€€ŞíÜ7wS‰*jğ™ãÜ~õòğ™ÿókaëM‚YL’áY…aÊã¤/úß  ã.*}©z®õ¥ì¾ßv£3ïuöö+^ÖfĞ¦Áˆô3íÕÔjËÑØz§.¤¯!J¸€áù/•ŒuféQF×™‰¢¦ ëò(8kªóâ¾Ó=S‘*360.ŠÚ²¦Côo¿0MxÕkÖ£7 áövôÀ»;ãÂq¾ı»bœÿµ^.Kf—/:Üìl‡!§Aó¢\qÃ¦B‹˜£»Ğß¶–z¦×š¹Ö¹äiG™OÄ°Ä»N‘¥h6ËA_ğËEz½¶Lˆ¼/ªmÕZ·h¶ÈšTbÇ5hLl—ŠíG¦í[È2(…±ìÉià>r}«ÜÙA¿Àµh£:µ+xés´.hÍı&›¦–®|´Ñ:e‹+?ç‡·æÄµömLâJ¾?lËoÖ*ÒK‚ñ'`#­Š“¢ìcVŒ zŠJÁlc}ªTæD@}¾ôÊşYs'ª.@u´=¯êdş•ï"éTHK%‰–”?ºêîO2 êĞŒ†¡È²b!
š.k_!IÎÁÎ3Gs¹³€/ffn{J÷å‹1‚TÉ»E7e§âÙºĞeÍÛeÄÌ³®ï[&K¡ã0íbÜc,¥(BîÄ.ÍvGt*ì£s,Å¼şèÿõÂÃ)Î‹N3	çÇ×‹Ùİ¶¹ÏmÁ Hy:(Ö²zÕ›]qìk„	s¹ àQvÈUF¹h×ã¤¹ô\Úsë´!ÆöPÎ×İï^±dãë¥"¯ı÷·7ó¿ê"çOJ§Wşş”Uc…H¢Û0@öĞƒxÀœ_%«4ÉÁıoxÇÛës
7á--ÁŒ"h4Éµ—”iFŸ-=æ§Ğ-#ö©º:¥ŠBÇM û¢¾d›Ã9õª‚ÄB]à·ïF–ò8·zş·ì¿(y×c2ú„ç*NCOg{sğ¿İ®}ãhhU7N&zÎÀ(ÁûØíSôg*;1°¹7§vuŞÕŒ~]jìĞ8u9>œ—†3»8À¬‚h*ÔL:Ä’Ş^«TaXf£;Ÿí+!šk-½¼Ömİ6>‰0Ê3R'6—œ±Èºóè|9ûÇ8n+{Ûï6
|¢œp[·G `£(É_„'è¿Ãø|2úüp,«9mH%8pˆ½)Y÷	üuŸEeŞ9 Â[«…
„¾­„İHm„«èBÃÖt•ÿ5/î>ğĞµ‹Qxbdëöï8Øui¼¥—çäÌ \*[Œa”7wˆÁû{f»_‹œ¿ı‹Iç³×‘Ş§"×®Ír`#»¸´¤hÓĞ´fm&öDy*e§ôL(PåÙkÒü –¥óê†»Åü+d”·Â8æmryÁ×†oÀR:zFİÆ&\OÇdd.®°è¦áµ:r»#Äƒqa‹d0†…|²«	˜FÁ>¬!¬y-SÓ¸…î¥á¢ú#…u1âQnæ±‘¯ÆX§ÈN—|rPÍ’_vl1-$äGA¯Åˆ^Téx;Õ7ÿû÷ÁGc
Tx˜?R¬è@6Ü 'û§ÂV£ˆ±– KÂP["àFe¡Úšı}Z16ör8ÊÈC±PyÑ{ø‰6e‚À$¼íˆ•·ÉÄâïÌ°è;‚=fb,mµÅ¥6é.îèŞ•°âÜÖ˜MNêB°¾»XÔëóü>YÇ.Œ"°µ-'=3l?Z]ÇóO©+² †eŞÕ¾ÄÂ3YJÏgH»X×ÿçÓå¹û–ƒnd­WQo]ºPˆÎGF—è÷DDC÷–öî¹ıxÃmŸ©‡F¨(™$ 2Ô¶Ş€ªL´dGF ¼õÄj…<RY9@°§@¿è#'bó7ŠvoÔ4vASŸæj®^ÏèC1ìnN–ç¡¡WŠİ‰·<š²ògXÁS[;v¹ë¯©ÎùŸğjy¾şù™€?‹Œ%¦°ŠXEyÑÛ³’
 ûÊgwBG›Ó(L˜çü3œ9zÊùš²¿P›„{É¹ûû£Š:’³¯"‡z>åŞºÀî k0Ğy#e,4Õô)%UFm•V×Ÿ­ù)ÕnÊ­øp#ãÂåë‡¢•õ–äqéñ‡3¹Æñ„ß[¿D5ôqX"M&O0¼)+„Ñr€Ÿ^¢ÃVŞTfüÚ]Ô§r7æ8™!ÄĞTlEƒãÚ=³×¾ğw¯«Ğt{ù˜Í^fœ¢äùèÄõaÛÂÿŠêÕÉg[ÙBˆTÈôË£¨ÿ-]¯jÂ&´é°4½yÉğSÕ7Œå6óCÖº]c‚èº…ªŸ:x!0%½S*ÎÀ]ĞH¿ cıÜs¿'q8{â3/z»~;Ç+¸P^nCü	6>Ç’lËŠFM<Ü6ì„î~Èà‹Ò[š¯ºJš»{p4ùVéíí·Ÿ…ıS!ñ^‹Ë¬„½@ã¨ªu­˜Má³pêÌúq3ß2 ºJì·›=fp=r¤Ê$ïwÒOÓˆÁ]·X ¿#e©X“›E_å,W	\Û^ùí(]q)A=ç½…2Ï†=ùÁoü>¿ÁO¸WpOG/Á¡’‘Ëó©W«œ”ÙZbF,qRåØÿÿïœ¤Ÿ¬Ls!×ĞEX†êü8o˜HüI…Ê &h¤Šá¬¾“´­9:£êåBĞÇ¼4©÷	>MœÎÊàŞUíÓ$f)Ï(B&j»x‘E5ŸnÏ.°÷ab>…jŠyu·/­IŸßŒÏ'VİXbÂ5ÛÃi2	n˜hAdğØoıI9º£©Kß*J‡gè7¦ş±3„ÇƒŞ‰	¹à1,´i€ÊjØÂmOüàèÛ—†öÌ?š¶z;NvõÒR·ÿLR¤3§£Ê6\6Øq\g¯qüH`Ò/séóZı­™®»'vòÏ”É
ÕCZ/ÏRñMoÑ[“üuzìÇaËÇ¹éÔéïÛ1Ì¸‹ˆÂÅy‰äğÇÉÉàÏÅğµ( ‘z]×'u<»6†Ã?’ÜÂÂŒ†Ö›¿êÔÜVÎòŞ'Ì-Ò­Lùÿ×=R‘aÌÈÌ@OÃ;~/ÁBÙ›Y}Õ…xöşN‹°F°å~Ohé·~«Ü4}ÏÜótŸ{/¸j‹pÏÁA·Ğ”=K×"‹\­€+İ‰r=LûöÑˆHBÅg‘5†MÄÔvÑÉ³øš[áª?æU©nX·sµYÿ.ì»t´ùhhix‰ĞÔ—½°El	àöOÿuW¤Y/Eø3uİ$oÇ¥ğ×‘)ÊÕîL;²rÉ¥©ó%ç8[Ì¿‹Ü·–
hz?â/yMW¸{ó"º|“¨É¥£eƒt¨T©(2+`l­%TZrÙL0˜?–Zy¼+ë•Ç3ğ/>Ë^+°öù»ùó‘€y#JËİô·®]ŒŒg-¦¡üªôBUgNy_Ï£F\;ı×I)]­Vçà|Ow˜pmk¹¿¤	^W®yÓò^sLğ«˜®€ „ø`Í-•Šw‡}À›¹7_ç†_nü¡fáò%Ï¬İQ «¤pˆ‡‚6EÔoe‹Á:n*(!mVî	Ğ‚åÊA=·³ß sbXÕ/õßN„lgĞ0×Îø¶-8lƒ›:Ä7†k¾ßu(Õ—ïÊº¨b‘+))_¹¨¤sx,×hÉıM”Y8ÊctÂ½ˆ	MÎ@9qù“~}E±UÃâ«Bûz/0]‘òè-åLfCÄÔ}ó›ş×Íòól
ª„ãØço6‚òÌq¼Q©6 #Ë‡ÉJÚ‹ùÊ)4JúCÎ5 ä@—öŠ@ìˆ!ê EL ñ?në’šÌG=_V,i¿ïÚÈÿSW<•T·'‘1	F’ôš‰ê©vwĞt;E<ïM¬Ì<ÀÙo»Ê6@[®§¦×?×	fùOáÕÒgË!¬¾ë¨ëŒĞFà·¥]s«ÿwr_¶m^Tcè³–
£^––ĞWhZÀ"rÎk²¯]«x†BNÊt"uX{Äş$øJÔäûüNğb5î_.}GpŞ‹ï'öm¹İ$‘qÄu6†2gstîóËê«€ııM=d›77?Jö1µúl«ÉëTÿœ¢9yúİ±ôhyØ!.†TfïMÕ#RĞ2ÄñCië˜Ñv|‘ùm¿Ï_:y*IRò‰u”ãûÅv][Ã¤ê™O%µh«şï½²îİ-p`ı$
w„ìè–äµÈ*'¢>A0rW“…]Ç|.ÑåUä£XF‡¤S?Q¦™Ëòü{²÷p|üêÂ³?CíÁÄúG¸ò`u^Ğ,+Hêñ¥x-Ï¿7©]g=ë[+Ã=6øë¹‡Î2¦ Şz^‚r‚+¼’#åm/õÿ}­³ñ%õÒÒ›^¡rˆ©i“¹ı Q=öÌÖøÜú¾ä+«É=°2/$@ùNiİ~¼pÕ$õİK
¾)	H‘! &‰a\Œüğ-DmpAÅáÉWı2½[ëÕ0E°RPSJ…¯Ş“\`Õ&nŸO–ÃøÉV][ù%Ú42>‹¯í;—ÃÄåxÍR®gÈ©Zşş–%ÓÏZb¡g‚e¬ŞñzødB\ËL„È™Ní* ‹x9#ÀNª&ü6&…\ß¢A…ÖÊŞvûOà öGÕj§#ºØ €cJçŞõğ}ş•cBEšZøìfBº©lbı‰üéUÑ¸åæ‚ß÷¼aUËæeapG¹ïB»±2µÂü¶É*~ÿ&@–ü]§‚œ¾İAi•÷eVğuåİÁˆó)Ÿ>"Ø,“Á‹¼^Êß‚¿Dy–t^°¦œ«£Éªú \–›
2GÄ¨v_ÿv-ĞzµêÚäœRCvøÓ$ëË¿ìÇ`sp…àAÕhP­á%çépCÔÎ@äN¿ºtAà»¼éƒZtôÃf+<®íÍsÍ×¨*Ó˜–*úÓú$íÓ(U>ıäN&(t^SÖ
C$ù¥xC¦F0VèÈz´/nO'aÒ£Ñ=}t…ëßOÒÓ¨ {ï*ƒÛKılb•`²¢e}[2³ë¬íZˆcF!F'¡SäpA¿KËäƒc¯úu¿I·åèYïG-órY–x,Bn5şŠâ;‰p¶CÏÄ¹—ï4km\wÒNœãj˜öòóŒSÛY;e¾¦éÛ³ Øhº»¸†“Æïcdx¿«Àõ†qLk•aT™¦uÏZá-q|×Ó¨šuSübBÅ‹zCBÂ> ²	o
]VÛkÉã7íLŠãhÜ¤BÕ£´Ğ=ÄêkHN…ï€È “È¸¬Wsí{’ß«XSåà	Ô
÷ÈzZÚ\KöËƒ%àÍSœÀ+¼¡ß°oùÜdD9Å´Ğá»	Ù^†ÄµOıYk@üÎóCs\7¶Ç^´¼ædG/ÚÌ?$Ô=¤
¶#+Š¼
p°`à,BğÆÉH#s8vçîÉX:éó±óÀÅ¦»„Â÷…]ëá5è~<äi¶Šl’‹oº«¶b+Ô (/Ó¿'BÒJÓ¸\f['éù½ƒpO#’µ6¤ğ2Øg”‰èlÌÄŠô§‘Åí¤œÒœ0ëĞşènæwic<]Ÿ¡ÛËû¼€äb;gøCL0mşø¾šT¹gûµâ7„•¦yãCº+dÒÊÎÛÑßœBÜäO=‚Z!ìÊ«“H†¾KU¬ˆ¤)²¬)ÄºA¿rsÃì>ªñá'M!ô"ĞkIº²avE¨ú#ÌØùWÿÀaÿxj]ÔÔBn2›FE)ÃÔPµG0÷è„Äùæ]`Û2:[)<şáÀ§Ï'ìä^Caò³M_KÉY+8 ¦!~æ¹àËkpxNW™ÓFÎHW ı`İQcö}Â­Ë-’?”±>ÄŒ«¥Çlvë³ „òi§µñÄ¹±’!àáTÀ47<®†í¼Û©DMNw~ü^yüz±c­#¸JûLÂ~Ş{Yê—Â½‰B¢~ŸõŞÎ¶lÁÖ¯Ü?Ä†,Æ„ Îó"ƒŠ®§p¯‹¬GHÊÏ;,±ë½OjÎ®U	|è)<&î‘ÊÂâ÷Òc×Ø2Å¹z…D|!óÒÈºaÏ)7©ê˜>ğd¹Ìõ"õËé¤“qñå-ü]¦:¼µ‰It´ãÎ-Şgí1 >a²ú»´ÀÛWR?³˜Ä©ºÖ_ä!H55^}$‚ï‰â0ÏN l§îŞ˜~¥S9?Ã×;)ŠSSJ­ºC& rğCªAğ	U@Š¾†Å¯3V„­e(›D%íâñ\xéy×ƒqÌ$İda¾„£N@hÙ³Ueóã¡İ¡Ä¦V4*ÂäìÈKä‚G-B	¯õ%ºDÉ[š*Ç&âõcêóVÌ0¼ŒÁ ÿå_y‚W'4ZÙ7Ÿ¸eAç”“_Â¿‚*p‡ãMÿR4Ó’LPrÚÍs?ÉÜï•lâ\¸¿!1_éß%§+Õ{"®«i†¸œéiµOSª•Â‰\ñí Z‡g]uSÙÜ—OUìƒÁ¸ñ@:òMÄ |±eÒÓÀ|PKø8›¨ñ^J¶F#yÃ¶¼Şû½ÙYô$éy,@TîÉ]f~Ş[¼q•~Ø®H5:p}¸¡ˆTp)¦¿¾·Úo¢!¥?‡°·
„Áö¢Å-]ğ‹‹÷63q†>¥$s£Á0¨rŒ¾I£2v[µúK¢p6ü¶Tğ> bp86ßx…\í7„6©NÍöh®²B­>(á×¥_ÈT>)v!!Ôş¥ª2"ØéÜ€q²=CWZİŠy&X›ä™Çc…Ì0™ .}Œÿ–ĞEâ×E½.…@ÑÏÆi]¦£y[wLÒİâZ<ÏÓÚFCpê/±v}m
Ç]ÕÎÓ2€™Ü‡oëÁxäWEYÑqÃ‹,Í¨R ôF²6/ıÛ0¾â•%_¿ŞsGÒ‰Ê`•_w‰Ê1˜5— F1Ó¬tEÎ¸ uŠ[úxŠiÊÂ}‹C3¥˜ƒ×öù#¯«‹­ávl¾{ºtuÑuÿß@é1ÆO°±¥©yUÎ!•<¾ZT‰ñ ½„0‹,„øü®iÚT›ìĞÛ»[Ûæ‰lsÈàªÁèúÍüK\-Z÷‹ùÓio4Dñâ|"€Ù“xCay^Ÿ@´Œ$‰­È/s|«xöT°?xù×ÿÖÃµû4ˆmÏNŸ³{Â» ñãGÁÿ¥mnl´j­º;“a†oe¥Lt;âb&jxåt_	¾ø!¯r#xËor3bø‰²ÓVxÀ°Â¸DÏ÷ãº“)QQúÂî%â:"<‹c£„¿UpÆ‚ˆa½Y‘¥±pßC.+ÿPv?\ÿí^Ï3¢º©±ÿıÅ9Ù	tÑÆ)ÛpşbªææïWîâ˜Cëf_ˆ oÍÇ4²tâŸÕ™G:èƒn?c½®Ñ»<’QlfAHbÎÍõ¹wÌ£ş`uºD¬á®‚“Dù5@”Å¯IıttşPA°lXCeíÀiÒ*ã•ób í¡Ç£
‹Rôd’KŠ1²EE²SºÂEÒ±Ô ËQùƒ¾›mKÊ:ÉkÁ
%ã—4™şcÂ¹R!]âı­Â“T07UõıµTqcÜKğŠà´zÏÛG-<  ‹ rOH¤„ÇİTïŠNšr©†@Ëë>ÓJõ…K·WúNa¨È]È‚²¼ŞbĞŒŒ…}³ÇĞd†~ıø cĞ?{ÏÍ@şbd—ñD{™X¸î‹À]!¡ò
;ÿªB ,æª^,êg½l²…ktÄ"¹Rb×$`«Ó·m€$ë´
…  û*)Æé@tëÌD¢˜ã—$ÂŞÃz( û fğjè$eÙkÿï›Æ’„/[Ü-óxAfóı'ó©¡KH´‚iå¥ø´XÀi«"^l;­Bğ=Î(X•ÅüÙú…‰‰\ñkgÚf"›NCÍ«F8ÁğäÁÅœ/vïŒƒ$X3œJŸ"ãXß‹Á§¹“…´Şx=İ¡¬ÂÒ¯Õ€v”·›¸@‰:¹ÖÖºß4€n—B"w}-àqjÇ
î4òèIßÎÎ(Îj99	~çBPŒ7@úQXŞRJÇTÑwƒzYÙ?óEçevªsÀ˜Iß3Aƒ?½Q\3Øù¾ãşÄªÿÎ¢m^Ï{gPØûXšØaø¼]µ#p x´â¬n14áÓ6Ë£şs3Áõi—
4±ßS¦«X²Ï¿
H…Àæ<§Û;Än¯K`h’ƒ‘àÆ#…îX5ê„ÎWœmÉÕ|¤*`.…’édÿÙÍÛº çáMdkùasYOåÉ~ËW,Y'MËÎ3GÆ`6¦øt„vC+³@¼óSÑÄÕ§ÁøI·k…ş–Éè<}¥´¥BS‰k-FØ¢ùs¥ĞW?^hrmâó]ç†cöB+´+°üšU­ƒ ƒŸeègs½Îîƒ·ï¿ İIb9Ü/€RàÑ¿âQ„²@´wÂ­*À´í§IŒã¶ûÌQÙj
ç¬iÄï,1ŒH%kªç>M	æ(/F¤É§UQ2B Üú¹â:ã[¨õ€J7ğóï^Ù¶/«N’¬^öËöƒæÌ	‘x5ıRdzUU¯óP–Ùá'Ô}f&†=:È3~ûèvâU9ï£iqÒöL4^ZÜ¼…<·óPğ'.È•y¿ÌR*·Ç€'/ ™*aÀ!©"ÛûO:3¼÷w¸@;šõÎ“¹Ë/àayş­êÁ ›…„ğ¨+¿á™i„·]ôx ëLîîÂÈÜÆ!âˆœ&™¤ŞÈ“Ê4JAÛU”«ÿ}Ò24Õª*0ù5>…ÕÃuo÷+	SõBH	h—/ë‡$FÏgîÃÔÏÈ2zš˜NÚ•\Í/.‰Ş5ä«Sù¯ÄÂO¹ç?åá%yµ íZ”Z¼îrİPš^Ÿ±sĞRÓw-ÈØ;e¶Rh%SI"©i¢ı9	3_w<<]`š«Zå—ÑË,=†Èí§ú¶×{¸Ú–âà»9/UÊp æ=Âã˜p£Ù¯–k¨7¨¸Ÿáür5c^"p¬ƒ¦ßú.KÊ|âá‹pxoIÁÖÆPÕ2ÁØ™/“To›J>ci×eLN¸İYöle¥Ş8—¶£<b±£J{„œjZ£²ÔâNÈÜŠÙÌ´Q5¿æÈêğôõ”ugáõÉ&%-HJLÓ nãÚ¯'_Vg
Ä€]ºí_¼á›ßò;ÊÌ÷‘… µ7	m²L¯®2Æ5»º2¨¬¶êhsà}Nä”'³[UQ×³)¢Uo©kÊ)ÿ± ©3‹Õ¶®löíÅ¥k~%ub³gşÄ¦¦?[VìàZØqãš¾k-ìCaDê$óï’	˜€r@wg­2à2®ãûê:Ú÷Ú`¯êğ¿ªú†]²‡ó™œ0»høx·Ï¤b-
›{.ıq‰®b>Q_,ØiÍ(›KÛ6¾‹ë,|C¹û˜‰£‰[Gvo¢5Qæ°?bÿäq„¿h!"‚:ª÷œ2Ü:å”9&å²ŞC|M,mÖ9<øZ‰»LQ§n–bËb.Od?óéZ²“*|høÒªë¶›ÉS8è×üv}Ë|—'S*SAA.¥à"¬™Öâ§?E#œ|v¶ÛøtÒmŒ*É×³ù4bá‡×ÚûêštÑ±I(&¦Ô‹ë
¶”Šïôóô½@,^dµ+ß ›ÕÓŒ\Ì ò¯Å­-%-š†Ÿ%û/ ÔHÔzÃ€@;™ôMYD5€vsS–ÓÊmğö}If}<¹o 2°ß8ù~zı—ï±NzÂf[X•m,‡i¢³óÕşkl¬ò·“+P¦NNâD[Œ!?e0-JF•)§&?ÎÂLjlmèşÊÁZÏ
L&t-Ñï·liØ…;s(1åw-ÑPL–¬¤ï[‚ôb­ÈâİÉù¯Ào8ôv•=ÿíÍÏÈ¤d˜¦
ßŸ‚ÓZv:– ş>:h´Z4É&‰±Î™üÛ‡M†ğğ}Ïouhë ë YóùJÅïÏrw+2ÀÈó7"µm¯`Òa®@!‰.%ó6òa·ìœ(§xóGlÕ€fW]Ô½¹TØMŒ¸Ò2Õ]ŠÔ/ªYä3™ôJ”Î±‰J›3R\Ç˜’Ì¡–k¦u×–Së×_Uwéø÷ï¨ø?7yŠrŠ^ †¦óƒ ¥ºïlúqQ‚ÀúìK+}dFm¸üôT¿B	Bs9p˜Z+`z«~»¥E•Ñd-Ş†”n{kÚ }„á‘ª‘^—´?É!rFuËø?…ÃŸ½âßôş¿m5Ñ_N‘fÕNhœ˜>?Oâ}Wùs`ÊŒÉ™T)^öpÔÂ3ı'šŒ-	3ãpex.t1 ks© æê.±³\±Ü_½]2¾ÓzƒPx8ÙfµtIi-äl–ä~-ï:
…ÃÜ³=ß&#ŒêL§
š®kAË¾Læ%:1pˆe¬Këj:Qåtª 2¡Úëô1c}y'ù|¸ÓmV¯&7×AtØ	³âÃê¨ıÁ±Óó˜F}_•yWb1KÍN4€˜¨"Ÿ5Ã¾7;)¯ÅD¤U³’V’Qq”u½ÌËõÑ0"ã`iüÆ»¨ëé×Æ–U.èx=…#èZ _>İÍ*›Á|—¤îã,}!™şFdÖ*^ßª’ğM]ÿÎ¸YQ¬aA…qÇ…t(á[©)3Å&@£í/j“0ü‹sXxÆÙÆº/{'®%f&@ßËÏÑõæ%?¶ÅC»*øtƒ~£é¬-T• ;æ^À6DRÜzÍ¸;ø.år¿2 ù˜yKës(&áû91[	¶ƒ€E³¡
ùÇ'âµé„©ˆŒtÁ§I*Ïì
g?®TØ›(kØóZY£wMÖ’~:øÿ_#’ò€=‡xÙæmË|{Bacv W[yB í´€Ú—ÙÇM!°a,Àlv6?W—STyâ¿Õ0¼;9kç›Ê…UÍİîng,:h
ÂÒíƒ¯A¦Øù‘û–Éßd®ÚÁ0"ª±W|³Páh¾|ØI±ÀªôÑäìÿcè3íCk¶B¡4
GZ|¿é-Z5Õl¾ëÉ‰ÆB¶[x5¿6â+Ù‡zSP ØáÚ‡gÒ'PtĞ€&)=œùä¸ºß"Ã÷²!©mô&kÓ
$hìZ…ƒøáœpõÆ‹‹×âMµf³;Õ¿lb†Bâ ‚cîe‚]Ş±<¤sä}Œ˜3øwªÂl/sHúeâZ(Éê®Ÿ¤OCõ5¶R*½0£xôÃ¯ñ¨ŞÃJË7&wJ£è
¢\Äö²âˆ°ó‡ª%ü'{É‘úÛ#B˜Dî>ÛgèpB×)? ˆÌ£çck“WßõmŒgºR´¦¡Gè^»‹°uƒ¶:2—yX¸úë-Áúë÷ıˆ…!xÂ,¨NÉ§XĞ%†¿±ßh”6šµWº§iE0÷Ë)>)o 7^]tEXCˆ¤˜Ñª{‹	¨Ì¹:)P.¹ã“e”8áá=×U(eÇğ0\– yµÚ§C¤0˜åÁÛY!¬w2ù
æò=½ÑĞZ%ä@}’suğ|æ¬´‰˜²Á tŠ!TùZ"\ı¬Hé:}å°v›>‰±¶/‹µ_¸]ôâš‡+àÔÓ»|¾¤;ı(K9-‹ngò÷†œ>t‚|¨9$yÇ5 b.Àlñ”K`Khiz‘% @52K<ß:ÉÆô“59{ÁÇMŒÇêÑ€Ì¡ÿ¤ã›ğ°OÉ)Û¾™Q”Ç‡$ô‹â$©Ì6¢Z¿ø´¹¹œTû®bµàqrŒùC‡/¤bn‚¿d ·Œ½«WÌpfkƒ8í½äÚÙ„Ş?Ì¦¨½ AeÌİŞî`w5xÙyÆƒ%ÜŒgHFWÓòµŠIÍÇ¢±ç]ÆªV"R´¶øİB½Ä¶'Û/ÖsÖ`Ñyâ‰Ùë£(‰”i?kp]w®-³hæ‘uçàBá¢p:Ú#x±ÔnÛŠ~ò¸úüØx{ê™|gÉ³eU¡Şw?ù5IëÎZí—¨Äï¥Ò»nÌ*p}Q
ù6Ğˆ òÉÔ™	4IÔ ˜Í´I‹w^˜ù1. w9(„š€‰ÚÊº%Ios8gH€õªûì­Ìñ×sw”¯±½ÊJ|;G­m³l"ğÑ@ß‹ñ-²\“G©8:>óh<M›ÆI6•WÑ¤"CaL;ªœTø2	Š·òâÛO?ë½3r>©ş~AFYöû@ºà[¡X¹aĞ¼¨ÜÖÂcÆ}Ûä½¾HÏ@B±¬ãš‡ãıèŠ¸ ¡$ĞŞĞı»±;Ó¼„Ïˆ³±Å 36¿²‰(Ÿt˜ˆŞ5½?K5=VãØ…ÄÙ˜Æùs´obtåkjMopÖıš£4)Œ—LÌ‰e!Ç9’äÓ(hÄxi |~ÓIïl¤Nü™°. E0İûmÈ¶9Š"jÃó£jÔ.Æ¾ku}PfFÕê…Õ*sPã˜$ Ø…Øz›PJ|µ"tš• †RUŒ¨'<C ë$Ÿ^ò¥±ûHÌz‡7x§lÓzl=LtŸ³ñ«hèEˆ™I½ão·'Ãz)Ww½wm!U{ÎøÆÅÔÕÖfö­8ÔÖ5§¢üÀs¥‡dòmXÑ y-
ÎV^óhÜ¿…Ãr'XØgY)Ü.ì!“³rJÒ„ºÜ Õc®ÓÉr²Üò˜’õ@^úM¦	pïíŒÒÙ„{ş­GW=l,¯ïZ¸s£ùëùİJ6üÃwo?×D9_Ú£ÂËj&7w^¡BJ³Á5ªfB*“»Ó(c(][|¯FÓ229™/P¶µ"²D÷g85âØFÀ¢@€F2®h¬6÷©ğÁU{˜Àû,Â5Öx1¦bß°h¦¢(²î~‹^ì)\Ú%Æc›Ñò„¹?Ğ.õĞô¹Eì
YÌÜ›†»IU4NB è˜†}lÌeşÆkÄ“˜ò½™†í˜Š‘¼v‘æé¨?9VF$±Ã«<Zœ£ØÑ.šÒ2Û‚_Ö×$©¿dàLêG385O•)šQ³Åë®ñx¬@‚°¬ÛCïŸ‚"†'{+»á¥j9^?A’ÂZ§UóìÙ%³*å?1?ƒYÀ?3`s±+‘mª4´\p0=˜ñ½­;Ÿ,X|šİ&=+?>)"Ş¿º¿D´!M?%QU²(;Œ‡y¤Ôü½Bóæíõk÷ã–A„LÒOÒçËçTù¿œ,v5ô(ÄÌøæ?)òTYöSVÃ]ún¯¢ „´œØMb‡ÅqÅù—-éÈé‚Qš­hîRÈiÂ™,7+¦xE-³-ãm#Hø¦;Ù–˜§/1}p;oİrc:3ŒÜ´d£ûÊ\Œ§=¯k… ì,]X¡ßIX=ÌŸå<Ÿ•Fn­ş™ÜÛ¹IíÌNš²?|¨uÃ«1¤î·›¦îêÀ½²N„yÃA™’V!&U¥ÙÖUqÇØÛÓkŞ³c2S2Eï¬‡óú›Xª¨;|2Ş'æ9&é}¬ı‚%I=~\†ù4æÅ‰|j{¬_üYjç!s'ğîî’$£Ğ0Há¤ªq
,/¨ÅDw ßr…•Ø|Ÿª²É†wƒ¯O%pb*U>CµÍš—F´OºIÁâ6^%(zÓ«MgxWº6«ÊîÊn3:ü]¶l;£L·X—â-Ñ8‹Òèæ¥4,ŒÉØåû[Èõÿ|(ûuD>ÛùM}á^³°Ñg§9CÛôÜxd!´^^Sœ2I¼oÁ›xGn¹Á-;‚pñÏ)I©:ó4$oİC:¿ú<È»Š»‹²ı/¬3¸x'øî]-ä|T]tC™ı.Øğİ(¬ŒÒ
høÒˆCÀüpş»¤™)!¸pôÁ¯yõ>\Ó``!î®`ïBí!Jø’‹%pM§§Š=·û–A›ûHZ!«°—Ys^½‚T—h£%¸wÃ9“»×l„Ğ‰\J;°õ/`.ã<&4¯@àŞR“ ²;«œ=/{7±© Ì0Ç¿3çëj2úTDc¨¾†¡dNºø·ë¾Ìj•Ş×èG²BSçÂC¨è6íÃOÅëÏ¹KÏ+ÎÜ²L»«F/j25ú–õå(ICÑÔ¢&…û]xVoÍ;mf†ÒÑ'Ëp¹~ˆ8ßbIè?‚ü,aãñ¡çhªúÍ5¡¼Ğ6=C«5¤‡ˆÀ
™mÉ•˜®Ëµ¤ë¥m¶ì4J¹eÙ¿VF1DC?fmËR5úÙısÂqB·¹bæ_2¤ ûj©©9†ås¤+‡<\°Qà3(“øºÍ8qk$†SgñneFi¤Ÿß‰(üòìc“AwÒ›¤?Mkv¹OöûVÅ¯ÜÔƒCq¿aO¬Aıµ¾É:şíü­­z‰hº6f–º˜=å>E:r¡&ME"Ÿƒ¦(—ÿ›ãÊ×1ïs A’W<^³ğ®­úÌe+Q´2Ì¤yØæŞG¶íéÏy•ŠUJ¸2ÖhñÎ0Xl¶æ}3”¿ÑV£~àÈôázj¾äıâi*é¢ÖÒ@í)Îò=ëàı õOïùñ²ÁŠ;(ƒ†Sñ+â‡ˆN¯¹,™A_õ§ùÜ £)Uï®&ViÕl! &<3“†?o_³¥Â ËÎú`Şø½Ø	Û,ìrÀ€?÷ØÅ…*ÂR>1C¸#áÙñä#$ô•Şğq\Uœ_!Ğ6Y+³XBâ7%Å{*¡ş˜°gÎ›ËÓ‘m¾(§2SZ9v@
”w8.—0î	Ünøã¶®$ŞhÿâğÒÖˆ¢ğ6VR Ñø«³}•ŞÙXÿ—¦6•ÕŸ—¤á
#’ñêÀƒUjˆ¤03=ÔÖÿ$œÙ‚í}¶¶nèûq7*M¶¸:µù=0–éfš–V#£EÍ3Z6OÒ¨Ë÷HÔï½y ´÷lûD*,¾ªÚ¯,YèS¸ë´É)DuQ€¤xÏ5sXxì¹VKƒTbÑ¼ç¿D5¾wÍÇñlÌ‰Qêkî
™S#¢ˆ®/V%DZR^¼Õ+¦;ÿ9I±ˆú±*î£ÔX:`…ù£ ËRŒ¾’çBî‘Àİ¸G%n2	…$øš 	ÿˆ”vÍbõVóùáEHR•ïzÛ©‰PĞM>ØyÆÓ?l˜–Œ’õÆß8Àƒsõa1–S´bf{Q}=NzÚxªÉí„¿4nèRcîoæUzÀFã|“Ç.Kê™Î:Ahö¯c¼6áGW(nSd#Ë¬¹*Î~àMgss\ìLS³ğYÿ›r$Ñ¼O<I÷£Y®×7NWÚ{6ØèõÄ¼HíUˆÌµâ¾,)Y=ùáª2Ç~_,&§†Ô¡à¶½âö.7*?£–Yˆ Fö•[Yª â]GÙ2mRÁö&O¸wäç^õ'Û„¨:sz‘ (­ÂŸò\&|i+´ñ†¶Tš'éCWÿlÌùBŠ§4ºª;v°˜âi¬Èk$2é”"tù'^¢^¸ò}(h»²¡< “Ğ-/HÀBŞkúÁ+¦±™ã{Ò-üøÔb
ì$ŒèJ­©|£#¯^9êRİÏb‡*lÕC^£W ßW—ÿjèñ Äl˜ğø¥°œlfÍï„Sj¿Ï§AƒqqãY4pôx;_ÿADƒùĞæ`áãl»|ÕáÔ¢ˆ©ô¼–q­ŸdÓëcT’²r ‹
ùUs›MËåíÂ˜è0,£Ñ$80O_9	j²AKUL\`ÜDÛŠ<™C ½7	Ú¡§¦ö<éQş«óè8¿%(yÄ>/ĞÍgYïmq×)îÒ64ã@»¶å…áoY|{Ã[åYÒ/ı+Sæ:‹4Ö;¶0´üdißÕÕÒ)®tè>UÛé:
‡«Ï*q®tUa»Nªæ)’Ä}.{vD‡1H¶auÃù™ }$Z	µ‹Ds®ØÀ±`£´jlø´Á™Ó\£rI — ™˜Ä,Ù¨–Â¹ÇN±Ñgš2HÅr–x9–(õ°)”SÍ‰£©U”‹åX©œ8H" U:$zT¶[ê‡7Ô.pÌı§İ2€"Gˆâæêµ‰«EÂô’jk[ó÷HIî´		f
IŠ¡Òº‚õ‰(Âå¸ôm"|5:B ÈVú“{ò–Ø_ù³ÀÅ* xÊõö]'™ù&ÜÁX²HZ-ÂV|qÌµi^2^¬.wSv4ûa/³º u+#ÂÿgÂ`eyÃ=úîÌÄÌ:±Ï¼‡ƒŸlù_î=4³ ¨ÿIƒ‚ÕK1Ö¾N<7=zn ÎŠ/®ô60ö/r>çvhÂÙº?T(
ğÃr•ĞÛ¥5g{w_ÛøPìrc'_¹Ã²()h–åDÀØe’Ï³¬cë• îªÆGÆ4á¬Š“»Ç½kïïPÚ	z4×\ğMtòq€ot„f¢ÌsM‰1ÂÌŠ'›6¤Î³ÂIA\QÖxãÉÉUi»¯üô{ZecPĞ¶“ÖİIDÒ¸âL¹è	"½šèÃ36oS[(9Tm?RºEí3P4“ÆC¸»:¡™PğL§V» næ{½´2]i/õa¹&1AêhwNÙívÄpi”’ĞÍ­è½¹ğ:(à{ÓK ÒíG\ĞD±“¯¶Nm–¼ô3ƒp+çXAá	× AZ4mN<pí±†y("B°¿fÇ è^4}/šç©¥JÔëN8/‚~×ëŒd}ç‡sğ¦™ÚmÁ¦Ä8› ­@$Bª!jGHõ íç¯çH8ü¶
£…Áwùh0ıhéV¢nukğS©â¯j“¥Km…x>ÎóÏb†i_Müœ:³dm¤»WòªàŸ÷yÓâdü IF/6	[a˜@°L5×Î¬>]î»©ÍpÖ2=®6Kfû½ı2¢&.¯åœ²pÎµ³[ƒd/´‘ÿù“ãN9;Z|ø:UM$ã•§— í#§D¤ŸÊ€²[DD0&íÒEÊnòU)ß>…©K°uåpNgêa3™úÍd'xœäÌ¹¥™^ÜĞ®)$:x¯P'<¸ËZHË{ß°P÷o»,nZp‹˜:/»(Ììõ?(¡ô—“l„šˆ¾÷GXn”«™2Çø5<G-ƒ{ ‚Ö©ëªÆ»RŒfùñÔšÃª½.Æı‘"¿ÇÉƒÛır`+ãı¿ÌÊpÚäo¥½T€Êçv§¶Ïõº^Kƒ’‰j)ĞÌ&/—á“«¼	ÊÆr0ı|dM™gö×¸ò›Õ(v¬2‡ü[ŞÂ…Ø#jŠÂúf˜aë%‡zLf× 1ğî]WéÉµu“'OÀ*nŠÔ•n¡ˆy„~òŸ©ÿh~Ö‰œ¼}Ö°
¿m£êÖM‰¡Ùbmû™ª	‹%š^fSYŞröø /,)(ğÕËÛcV[˜‰Á”®…²Tóä0sµßRà¤k3eˆÎ”fsŠh ÀÕs¨#„oıâógÀdô‰Gòwû« ÁlE	QxŸ£™¹VåIÛ/ùîÃ”r9Õˆƒ(i1x7ïÙ.Œq»£yB=&Î9"Ù¸SSÁÿGå õò…:FHò–IÆüŠ#šyÃĞê,ö¹ºáƒ¼[>èGŒ$†=Øµå¤F6¶ËÏ²5]ÓcØ>\”ºcçd#;ÌbPÊñüŸª9œ[Ë–O¼Ê•Æ)›ª´Í,4-HëÇĞÏÒ6[[L†ÈŞ°}[ã›<óVz>/š@¹uCdŒÜ¶ÆÁŒ­˜ƒWîÎl™Uş›Á•BÜ&¯yüJrğV¬·r¡‰#EÔpö>œ_­àH6îvpüe³€¥Ãã8¹m†¹d?¡QgÍUıˆ„[Õ‹ „ï¿“äjÕªñnlU}ä/Ô‡Qá'Wt¸ºR=¥4ÒVN„"±&fo,v’uÚâ¥
Ííz°øGô¢…HŞ•0\:³5·—‹#Ûå>L¿öü2²ŸŞv"/Ò³õq8Ÿğ)Å„¬cÂR@ft1ÛWÅ†õ<…Û>ÅPõ\¼_4"©¸G)Ë[àHæ-Èá7:ÃKàÕRVHQS[ƒë¯ŠèdÕrÑîO¤‰·˜ûWú¾tÿf§s{ Â{1SV-¶¶ªË	¦®P,:Û=åëZ=õüV==şmá<]Ø·-#Iùyš´éí°úyÉ”¯k‘ëæ»ñŠ.¼éR.+/—ær~Î&)™óö8-ÃODÀİÆ~U;yXäD1Hí{æ`9ÓHmÅ|¯k¤ú=4aëAË}Ú6hª›ÖNµ¨™–°â9P5ËrÁ'¥°¤ğkd	ZŠ?µëb“¨)t!¬ÛÛ%¿åìøÑMTÉˆëhsÕÙOGs³;q^*à¯eØC½-C cMbÄ¶cÆ	b!Â!8¬˜Ï§Ïf:2`B ¡H[ƒ29HÁd£	¼68Èr§•}ßTö×=4VºÚÎÖn%Ù§ èª˜Í"š²Ç†u´û¥±”´k…n=ìÏÔ~¢˜çç:mÿè¶lìpR÷	.Ôßv#LÌUU{Œ±È¼âÔËÕD:p^»gûyûÖl½ïB	¹I/©áuĞçzƒ¢57¦şÓ8;:‚7¹XCÑDĞ™‡
A
g†‡ës¨Ëà|·ÄZ™TÒ€j„”qæå]ª64›O©bÍÙ£âp:!V"mÚÃï*ÅDU±ñåºÅ3`s_‚5÷bºkM64¦ÓölFßÍÌªvÄÅ<ÛÕÑ`|S\@8’fn¾'%i<ëbà·9G/Ò¯?!¨33æk|‡>Àjªì4…í¡Æ‘œÌ£5íõ†·2‹Få¤E¤ªÙ½ ”ü(Æ­ÜÛ@W“vƒrÎ ¢Ş(Â› ôCR´†
%æA×ŒHBÜ…ŞNx›ˆ;‘³š³ğƒ"°&Hpe|¤“,¸X‹Ü›+AÊÁ	¸§Ñ7ë¶hñÒ\íA`©jµ¡¤Pİ[k·‘Òizş‹äıÓvkPe]Jı-ÉEÅºY{Ë¢ı"İ,ı–3[t’—æ¡Ü¥ÙÓw>Ó_ŞWyIáÕ/ğD69À2SE™~¹Ç>ÇW,šÇ	ä‚Àı[%aUvS?Y)¯ĞİÂÁ¤88k2	Áùx~=›AÍ¿jÊÂÊ¼!×5_Ê³ïÈŞÒÚ:ÍJ‡5?ıÁ·N˜¬nÉ´ÀJêÊË¶¡ØÂÜæís)ÀgÎF‚ˆåA±Ä˜;hÊ(ljq¶†Á¶ÃéQu™à¿4Çöc¢İ{–ÕíRKíoÆ©şf0‹u¡a:ÓkŠ’.eJAo4¼ãXÜ›:vŸ*G¯šKÙ”å1Û
VÛ“ÉˆœÁğÓÚxç²Y‹Øº‘Ğ®³kíîã<
s"xÇùÇƒbg®
­
 ÷ÌØzjÖ)TÓ5~ø­Ê%öÛñ)¢!ä>8Ÿ]Ÿ?ÅñËq)Ş´p¯ÂH¥M€³ÌnÒkZ|.€·„ïÄ<O‚é³²ÉDVM ›IİuE˜I[àŞ¾§×8ÅÂ†v‹>xÅ¸-yÖ¿X»²Sr%Ú\/V‹òyyKŞ–)^æÖIĞ7IzNd©w¸b'sUÎ GÔ_­ÓœÚxb1ì'áÛmËñIÁríÚÊ³á<öyÖÉD³Z¬V!òovÖ5N/¨\
øih´Úv4ñÄ‹Õ P´®ï{¿ÕMVïœú·¾ô[Òã/gÒu{•ÔàNù<Må/¸[³G½©bcÅÕ$Ü8µË©§'rup»9öDÇ&[AŞWÕ±’Oi\+«7¢ø_.ãûÔØï#b”ÄbÉ tÈ-±­>í*nÔH†ªg-MS˜’ĞÊ2Ñà|äR;£XÊ(ó¼µ¤•àÃ“fZ§j­¶pİóˆÊµÜ¯U|î¹ÎYcıb5t<ª“õˆáĞş3à1J¯	ßü…%d¯/‘r™ä¨c“¶VPÉRêı€şW0}qú:²G6*k=şMY3¡HÜi:\ÅU%Øxå•ßkÒéJDZ¸ü'q¥¾…;V¿ƒz‚1((ƒ
¥ÒyEÍÍv~±oCQ1y´Ônd*›R}ñè¦!•?#0Õ ëñæãuÆµMÖ§[w©{esŞU”q\  ç°t#øz¬§âŠGcˆ$âû¶· heltImÂÓàÔ‚¦Ì9«8<f_Ó˜šh3ßXÂ%RM@çYèRµfİºCâªó•>æWI~À b(œıP÷WÛ—vVïj*92œ@I®,Bİ®[LŠ£_µ.Ş‹íLT¯V;’ã>t¦µÜ—-p#Õşf³%öøl!e¿\9åJ¬†Ã£Ão²æ%nPùGÓ…#âfu)îü#BªeY‡ILL6ÄÔ>/Pó‘=gÅZÉÕÄAEe–‚ú~îK]WÖÔìZó†ÊôŠøúÜ­â9]üÍ‚/~;u7(9Ÿ/¦+Ql;{®ú÷&)Qêô¬ÆâbJù4¦ş+÷Sgmm½„g3^óÉ…Døn-	ĞmËcC‡ºÂ‹tÂ‡ÙTˆŠ¥&º7é8½‡Ojr dóS·Pî¤Ê5ïØå$´ŸlÃœa/¬ûaÎ)TEÀWéHRVÚ·ü1·5h&ìÒªvu;¥Õ˜ ¶§Ö	‰5 ›mšµ½Fˆüìèi+Q*é@¦»¿‚†kš=û)ŞXô€„á`G M4GíîÌû¶´*Îuy3'<û¹Ï[x•ó•ş«ìÃ´2€¤RÛİëË&·AÙñ±÷tƒVÖŠ†Ö²#ÍIfˆÆÄ¢µşÊï•äğqí½d Ÿ
5{Ü²åKkjÛvòm^5ÿÔ²S›zÎÓ2mÌ¯¹kgx+¬È¥Àqm_U.ƒı*•Å„4ÁJ¡ïIos·†*”N¨_+R}Sí$Ï_Š"}ñlâ5Rş¤JxÒYïAå'&øÌ.·ê•ïß·…Ü¨i‹ĞğùÿÔ:¹0Óı®F f3à£´O;!¬%$„y5†…v¼iëğÚa{%4&­*å;®×viZ¥á.ğPî™Œyš:,#j­fù?¸ÑÇ¯ é€3~Ek/'öÓ=óHYÇØ	ÖY,[`âÁ#4yz@äÓ-²EÀëKãJ!tpødº;­3r™KaŸ{†ò„ª•Iè,ÄãHHæ@ıÆç&h0aÂ›?VöH€"O*Ş.fIJtTP"-Âÿ“A!¤ÜmœSzÛ&«D+ô?¹»vhÍ³Oÿ³>¥˜EMS@2¢ç™´Ã¸zİNğ.ÔÏÍğ÷!`Sµ,o€˜aMÜñZE.º?É•,~®¨ı@Pâ›™ƒH>×¬îÒ29šuÂ
Íérş˜DÙw›7½ÿÂÀ/»ÅÂ¦ÃÀ„^„æÃ‘×¨Ñƒ|ŠFÃ.@|®ƒ’µqÁ¾±òiCooM® j_Tná£÷şÄ<}#Ø0>[ÍÅ£4Ä-Õ¨şucâP7ãçÀ®†=iO‰°Ïa­2lUfjÜñ¹ Ê¾”Hƒ™‰¯8éøËR‰™Ÿ0vMiĞJMa9íà6	LêuàÓcÕ&1ÓïÜ¥XX8Ïç)È‘Ä“"…vsÑÌ:£ÙåªK³0ú¼+Ûz64m½ˆ19-™œE€Ëó0ßUÙ(>DŞUK¼^6á<z—ƒÔ½&ƒ•Ã:
öy}Ø©ú°ãšo²–¬NùıX] ø/*“úK£{sƒ,»Ì]”
-W`ndŸ–IdV[ìú^õÀØdJÂ£¡½ÌòV[+é îÏhgM4¶gzQ‚Q£ÒÁ¸9ò°Ã&áN0Pz^0__°C!'}…Œ¼ÜE ;ÿ´î„†ÁP`Îj€|İP¹á½n*ÂOŠ6ÄgËşÜı²ë>À§Bø}]#aPÕMÜæ`g±«è(,¦ïœVËYå<CZô¿>7@D«ˆÆJ´½İZí™ZO#m:ëø,Ã‘·÷¦O!I“†uµÁ¸Š Ù:ja[úAèO.;êà¯Âß¶]kN~[¯ñAİäÉœşÌÛ!_ó˜b§„¥íì'äÏ|'¤¾³÷YF…]CQÒu|Góõb‰Èù2³œj/Ò¹Gu$è7_İ—ÕaµáëtÌùfL©”µ E9›Guï³Pö`—Bçÿ%öÃ'È9Î–Ğ ôJ«QD£ÜÜ€ökUĞ+Â&‘wûZ°šå;FlÜçs‹UÎÎ|‡¥¼âBüJ¼Ú†Ş"qó)—ˆ­7ıq^Òğ0Å¬š!ò‹3Í»å ñëN¤-'ZNÄE!2HŠ1lŞøö¯@[Ìä¨á9Kâ&¡Ü<í°ù…Al£ñäWß“¶[£²ëí§‘š9	D;EuC¹bï®Ø\å PS|ò÷F,&OH¦{bxÂxÿT ™ÿZûşmVÑâèxB¡çÖ™: JsO~Ù0DEf’ç‡Z•ˆl\X¢1.]JRÙßRÕZJ“ybrHµ´ÙKƒ¬^™¾,p·
wÇÔÊEÎæƒ3‹…¨ºL÷w7a¼éHûß­2ÅÊÏÈ àï®G
!Î}ü<ºÌ\ºÿfÙÒ)ÆÀS#Ôœzl`mÿİAø0å2nxKì*î|ÔÊÖ³–Í¶E;†òüáG=¦êaŒ¾õ–ÔTÍ’6·S§»hI•ôÈ0ü:¼i§Ÿ Q÷ƒh-M*©ø<µÈL¹®@idå&Ş3-Ø³½o·pl»yîcÂÆ3)X]õnØnûJj'Ãì¾:ËWT]"Æm9°ùa¬©'Sì)'óJ†îB¶îû·'Wß<>@—ÓtÚimë/`ÚácBíW9m‘«â)Ä¯aGM°|ğ—½µû‰3yoÁ5ø¥)Åô©qùQ^#åõúA5·øÍî©¤ê2°İ„ÑÄ~{Ô{#ö/5C¦‚|3"Mğ·P|ph÷eYP-Ö#~e-À:Äè§p“*·dDÒ…ëşšó/,ğÇŠ"È·Aåo¸Q=(ïd¥ÏŞš˜o9~#×FPá¦Ôµ,Ûº7\Çcäï›N^¢QÃ%Qˆ Å¦Ë*eE¼ÃÍ2`® Á¶E<M‘˜æ¹_@ÅÔ"j‘•ŠSÂ‹Øl2Ëšf©]Ü¨£ø&Æ¤Èİ–bbÊ¿ä+?R|pÉœ¡Ğìd(DBÖ$‚İJäåBY0ÏoWt¼€‰”, nÊÖ]=+µ5ªÀÓJ`º	ÇãÀ½»Õ‰ğE¼¤,ò@º+sô’šBi5C*Q!Âá'*¾…¨ìfåøÛÔğÛÿ$ô™9)Ñ¬u}^=t+˜½¿Ø¨5tÖb9O±7úÜb$·ı÷şA3î™ı|9—*¤†?ºã·8U5¯ÃCõ½½jJqåÙÍÄDWYPùNš¦Úe6¤ 6—ıe8'"^”µ4îÎ´<2¬›ííş|T„«®òÂ Ò`õØ9 b%üjYçE$šİâWPp¡Ã!mwÌŞ4Ç¹\<Ş!…¸(éµúåÌW„¶l0íıƒß„¥ûÿ-±ì6–£®AQösWB"´êú«˜ùDÂSPé®Û6}Ö°k¤é=–b7ŠÌš$ş33ÅBºŸD¯A"ø*üôöV³BñùĞ†ğà™;îB#è³´0wº-–Ê¹‰‘³Úe 2õ&/°¦Å”Ö3ˆ•w¡iÊç’¦Ğ":—}ôJ¿IDkÖüo$TÓAW{­Á8ãªï¶&9)ãÔÇ&‹ìV´ª[†´üê•üÒ*.V¡6(†ÅÕÎ° “Ş~K]…¢åÜ->
‚"&Š»Ãm”Ú%t¸®›ì	l‰VW0¬¨õ}ôÚ—p„‚Å×]øÉ’ï°~£ö%YuÏD1M¬	~z';½vğ±iŠs©'·Ù•…¡uu¢+U Ö¦5n+˜”®2ş’uÒ“å|g¢û5Ûm›Î8ãûÕ¬yzÁ:çı˜ÀJpŸí~.&`£wòşmãTrû¥Ÿ¥Â±/J/fx§Ô¦¨¥wüÙ¸[É¢ÑÌb©:ˆ¯­Ïò´ü<â_c¡+m›ÅİUjûª2’ƒû¦JÁıt ‡¬©>­nÈg˜¼Ôªî|Ì£ „ñXfü/Âá}R·Yœe²zv˜!š¨/)9="ˆ@¤ğı#êwhvsNE:|™Ù:X•• ½Ó„§3EĞeÉ  4zY8M„ˆ'£ 0ÌvóƒÀrqÚsèÿ2e¼E°VVÍ¬Á|Á9Hı7æpt˜ÿökèvUïó}¥,½\JcaŒY1â·b—}-ö4\HåãsMzgR¨ş8ü´:›(ç¦ëª{EX¥!Ï0ö*¯8Õyk†¸pÔ:*Kò£V¬Ñ •½:%ñ3;t"q¦"CmÁ,ˆ¸Fß÷’?¦DóÒÒ·4ê•´½µ…Ññ’™ÆzX"‚±gJÕ´“ˆÔ¼MPÓÊPBñŸÉ‰}MlØ3o-Ú²l™SµæVKnù`s5”€$:h9…?®‘ˆ±¾vòÇÆ}Î ­í…§cïˆ¢¤i: s‰à,”ÚÆşÌ‹7í,4#ƒYFäJ»"@ÈÆŠ’ƒb©ÑqªR%Lœ55s}‰»KaK ×ø­9XhıG‰*qÄÔZËÈ­Y-ª¿ñ­` íõbHVØ˜(ø^©æÍË‹D´~¡X¶VåÏ­Ö)}jûğ®taÅS†—•œåó¥aCTÃêUH#ûµ‘`şêRÍ'22Ëc'Ødöe‘¹=!gÚú¡dWvçüåÚÆÎ#…›ôäe£¨Ş/”nÙ2Ï¸#
–‚ª ÷YóE;?ÎšÔı—EèÓ]¨xİ¯¬|¤tzÉ³‹â»ıÂCElÿ…k#­ƒS­É@?bE	èdƒî* Q{ÇNèÒÔ|lk:–İn‰,Fsxs ‘û ˜ı`c,Şğ!¸xN>,sÿ®+zÕÚ†{"€œÀ&ö.zÍİáÃ%u_?ti°ÈŸ5²íŠe»9´¯"î4CÕŸÓØnèêfñ“L\o’¿O{`ó,zÆåŒuP$ÎÿM³W3Ñ÷'$Š¦WiYuu¡NZÊº9A
^¿T&r@$†×+ÿâw@Q{éuŞ¼¦òZE§hÄ´n¢)ô<Â|.s4&PĞµÊŠÑùQ’iû
6Zñ/æy~'CEÿEÜT™Üø
ñIªÌ-GKeFÀ"uænaoæ‘} FrZ„ï`àlõOãIÔ ;Ójp¨À%~ÉÒŠae68{å_RÏ€Å ½r!Œ©ùÊãâ4RªVÉ.êŒM°óeÇ™*ëèß©R/8Ër!ÃÎ^Æ«ÆTgüqî U{¿;÷ òÇë ¡şZïö#f«ÎİµğV)M›M¦KˆÇ bFx›f?z7¸‘üx0§5ÑmÏ>cbŸ©ş_qä1ù]kÊ2EÎÄ!eÃ<˜#À‘•#V+g :í©µ|•!)]†qÊPò~Fv°—|‚ ë~ïjJ–º©x	×4ã%E[§Äı¢´»jo"Ô[äËU"=§úWH5£cá’|¿ê?ít-›£»EM¬Ù¨3"»© ZNrö·«ãÌS“¢Æ,•E-IVA@ãV†ÿÅL–
ˆ¸éÿ¥ï1	¬œe“˜bœÒêŸyëä9ùã ºõ\œ:ø¹œ‘úÕ†,>»
/Ó6pxNºz‹sQ€©oK,ª#]ç
ÊÚ6ú…©D`D¤ÈGZvŞG#¸–YPãĞÔ{dqm0 ?øGçx…§T"`O¯ı—¬Åmä<é‹KÅˆ¥Ùn‘«@Â?ğ¨YºJ§ÖgÖè|²¬ˆ˜Ô×İ²KdºD~&Õ+®¢4Æ¸Ò1æ7{=•CÒu@¯r,1e-×Ë•Ò5+¾©éêa­YşØO²¼ñ*jrk‰m*0ğ0$JİcåCSÿGìğé„˜åo'í[÷¾ML”Ë¾nÇĞ–…P‡en«-ôAW	ù-×ú[K?!š±İV7 ÄCE²Äv{vŸøèÙ%¬Ë¦\jVy1­@•ê»‡r2a"½@¤Ât4—”J;û p€Øâ]@XªâEqhÿˆĞ”4ÃÁ¼U{ƒ€¾5N¸ÉÁ=¾•¾Z™[ Ã÷é'ğøUÇ*†ŸŒpß}pºJ-Ò<zû·zH8ZL*#"”]^ İz†4ªı,C³‡¾Ú„?{æH-ûwFN©ˆİéKÁ¢3›1Õ0ÁXvYê åˆ.CPİQì8ü±„í‹¦ı°¼°OœOïÊ=Öâ§­XŒc¡âA43zStm²ˆÕVZ;DY%jRuÉÎE°…À·œ¾®¢<P™$hf‰8º¬şCæLbø;]jÒZ‚âğB=Æ?¶%]æ.Ô°¬Ùtâ?OÎ~»Ë˜9ñŞj¯FøGÑ.3C$†<ÿOwøÌšéæ÷8›,òb{08ûk·è*-ÓÖÎ*.Q|ÏaÃ²Â‘øÈ P
æ…º>èõğ–‹…<zõ‚·½¡‰Ûíòm79~Sdµ3òçÃoy„dÈ¦?Eıe†©¬sSNÆ Œ„HM.Ê>,1 FaËïÜœN~” Òi”¢ûáºï]n@9/Yiiæ•	O…ŠmØLmë×T,©ûRÅ6®²:¥»8[.RÛO¦ë†6åÿØğÈï¾ùÈ¡Uƒê7~>z‡“P¯w%DØÕ¡ˆrÙpE¬ÔS{BÙØB…v£¤.TT¦/—ÂËUB_®ìhŞÇa¤™™zôu&£xÙû­„4½•ØD%»³á˜’üŞÔ“ø¾°Ê“tF¥dãÿa€æC±'¦ßtc•6$5‹Iy.şŸ Işº½–WÇo´Éô&…¥ñ»û¯89æ´haQ mLÊÂXõ€»JÓ­J¯’"V~Aô3~B0"Èº<}µÇ¦m`ß¼„¤zò!èïö—ş4Éá÷S®Øyv¹÷hBì×í/*0›û-ë¿tEæ£¿)pç_?³ÛÃyÌ»‘´]è(œ|zÈ}IJœfxİLİôÏŞ±Lªâ¢+aÇÅ´ºšATÆª°6`w’ãÁã2îešøÙ'Æ<æÕÿ°ùÊœ-V>0LĞ…löØ±‡_X”â$òóU—•C²İ)\¯¿^ã¬Rz^vj¹+-¥aõÿz½®Í×eÿçİæŒõgURñò3ŸóÓÒ¶Q*ıô†i­ı	¹:ª‰è½gëL¨BÏá¸?aÄ˜	h}–Èu¥L@è¦“<©úeb®
¨ğ:ÕúÃğÎ}/DÕ% ­¿öšØ~Ä2ùı_\ªäŠ‡6É­¾ ‚3,Î×vT>–× •¯b395É–'	Wô–Ï%FG€[ÚœÔt‰¤/á»³¹3+§,A‡6ÜÚEÜ»&~²
¼Ì7¶áôÑZE’Î¬Œ?zKªö3!âkÆzZ8’Ùæë¬³³ÿ¢àİdÁß^µ‘¨Hid1eËÆ/¤ƒ\_ß~'.^i]~ˆHcê¤NÆ>&Š›~ß™at‹£ÏNKQUtÙS_&NÏı¾P
W©ÈvÄÀß 9Š€c C¶¼÷B×^›K(#|ÚÄšûM3±×h{àßÒq\Ó;×9…tŠÍà¬ìeØ0Áä“í{?³—ìÜ¥2%âbæÂ_ÿ‚gjW‹.Uß<»>ÏŒè=Â    =8uªÙ	‘ éÊ€ ¨w±Ägû    YZ