#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="730155432"
MD5="7009dbe21096d16941302dc3b053ee38"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23532"
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
	echo Date of packaging: Wed Jul 28 16:12:44 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ[¬] ¼}•À1Dd]‡Á›PætİD÷¹ù&í-Wİ¿	ŒG¶Ğ™™l¢W‹âXz˜°L¡\gÚlÑ‰İ¼N§İ£Ó·`“²?*'ĞşR6¦Ş'>*™Oª$`òßÒ³B¿×™	¤&"æ•|ç	T0òq'4™?|0|1Ì„åI%Ãƒ¨wşwLæ.ıâö™bí-™ğ9Bå¨ÙÂ§WşSS<Ø~y¨ˆpµMçtT‚y\œ3YÒŞæìdëÃcJéDÓÄ&¹×÷6æbUM³¥¿ù=*Y‰ù€Ÿ‹ÍÈ×N¢Ü4&¥KAßÄHWPBÜª’bˆÖ›ºdşÎË€KvÅa|&Œä~—í·^è&àüşš­^µŠ@mŒkçH2!ÎîcÚ+¼zL&y•Ùï¼Ê÷_e1Lcîä°WèÿõÉñB‚N/c€cªÏåuWßûŠJÜoP×©·?GŒÔÔåj·ÅKY‹ö¶–Ğ†÷Ğ;côõOÕIÈ94Bø‡Ì+:Œi°È¸9¶¦£>š‡ËÍ^RÉŸÁ	ZŒ‡¼’ÌaHìŠY*??u6&«©õĞœ"ô—1ÎÚÖ5“ìŒ›ôc7¼³pn­¸wœˆ>ì&¸­îiÉnFÜÖ!ª$º <j+ŠÉd°M
²ã"ÏÁ˜.Æ‡¼Õ«‚FH©iĞ“(ŒO	«d¼°­:Ú™¨Ôw§uM¡:,AfvÏ¼°ä8g-°vMcPÌ©œàFÍËÆ$òMÃë&JS¥¢;ÂéŞº8d¢rsŠGğºeòù›Àwy²ûë Ğ@Ë„B{Æ¹¤+OˆÔ[¡˜CkéâäÄ°z¡t}r.·qGÕı¼9(5^´ˆõ)Fi;ÀlXÜ·î8l;ğ$kÑM¢¹ÁÍ8ÖóÍ)ç¥«şoÏª$Òiy¿ÍÎV3Æ$UêWsG ºQıØÀ2>ù^'Àµm§?İc:8ëãçkí\Ä'™§âuŸi0<Ìô§"şFIFÙ÷hG$,#¥*ò…— ÍØsºƒİãS©şz¸›Ô~Cb7·ÈıS iÀ#
ÃB£8…§ÒQ3kéøİ»í˜-´ö±âÑ‹ÎßŒÉˆà;‹/‰Xå|şDŞy3Iv_+6É~Ñ·Í;~md¾Ù‹èEs[¢î;yàySÎ\Ö©Z¡ã—·ª®¬çÖ)Ó\ªL€ÖF"³~-øpÂÁë”
óJ
^ ¹N0ÓæáŒ©ıC…v‚mÇÂ¿ z7¾jQyŸ[§†éæËÉù(`UÓıd?ıœİÖ—Ç·++1àß¼Ûtn^ã<+³£‘1¹°_¡ãb‚VÕw»†üª½Ç¸ã
?‹`A/»ºõ.·şê†C‘¹ÊÕ4ÏíÏÙ>”Óß“g¯#Ó!×Î,u0İMN99Êë-7)ŠSÎ
VÎô«+‹´äÌğj]×WŒ7‹@p}ĞüÊiÍ7îúÂúvùº?	 T’ä$Â
Š)È½Ù÷tœ—;Ó`Õ-L4.°†Æ@Œ	Ş’IiôL(ºîsÁ‹¿ô4ğ–¶õs%5Å×NgZ· M;/Vk`«ÄX\wÖN5æ4FAºj±=ªÚe$i˜aé}0÷=ˆÒÂXb,F%YÕ+ŞhÛ	6—EwØ†FyïxØŞlH¿]ƒí<DWä¦Ø<Nj@`Ø9×¯¿K.ÅtIíi`½D‰Iíşë
!îĞËYÍ+©Z>ŠÕ©ô½{‘ÊÁ4²ì2¶æh©kĞ$Å¼0|R‘‹ÎÈ†›ŸnÛ¯“…W=»ê_@æV¯„s‰ŒtrƒäğiNÁzH °è#—{àe]†ÕøAŞá7´‚™óóRuã%/V-ÿ¤ïÒÀ‰G~*®ñ¸Zs.Á©-üe5eÇœê`7Äwp=ó~Ñ%c†¯qÿy«İ„Ñâ¾
ªG%EØz´Rˆ¥ÑğÀ@Pê¬Á gµ'{ ;³åë–š’òğZzm+G-DĞ‹E¤º¡½j¦X“Ê’¥ÅnfÑ^¬‘Lmn_¼ë:ÓˆÑ]B‚7€Y%#M|U¶yæ¤l¦àÚq0@‹h6ù7êZŒğ*™Ešô#q!W­€‡ærËÉ-pÛ#´pgÍ<ØÂuu³1Ûê´„G¹$,·îö¸e2'6‹^£áşÖïZ¼†xâ@OÀ4?}®úé8|ÄJ		
gŒ€õˆâÖŠ÷«•WI°íËe=Ê0UˆÄX{O¦ƒdB•´bÂæÀJ	)Kª² ^ÃpÅ‘†…>„ò¾ôE¥Şè)]0'mN‡Éóu»%*ôßÛ â,6J²¤É}© V²i$ÙVğì¹ÿ¢¼^–.ŞÖø_© ñä»I”ÿÎzO_ÀKD/ñ¥Drø9Ø¨Åy<`ÿ”¨ÙÏaíö±æJ°«iL ˜¬R_g§|_šÔ=¢Ê)ş¢DÓ?Ì/Èìf7dÒ,o|Èl¸Eâğ"“?Í^øh1·D# a'Ÿâ•}]Ùrà¤nÿ.)šÍÏïk¶…‰´ÉK7«Ï0V·cY	¢˜Ç:½ë8:NÆ‹s)F¿ØØ
ÑLÂ b¥iûBùØØê ö“ÕTB˜‹X¡á6e»şzB¹ÑÆJ^¨Şİ}“!.úéÊ;7mëi.¨S==+.n9fØatÁÄ²s1¥yÁ³¾a;c»O‰®k®•^V‰&/Üİƒpû×ÿ/+´P†HX®T¿r^”…{*´}ñ¦¢B’WG%:éŠKQë3“·³}9KõZ¡Ô¢ôªZA·â£@ÇZ{`q*‰Œ×ğ`/0bÂáTîøb4œe”fæ—
3ºÿÈ_ß·pÈ«¸ê¶¦.‚¤Lm—½qaüÍq´¸q1FüÄ%Ï€TÁ>Î‚·*®ËÑ·e>èÉH–Ïç¡åŞ+X-ªß‚…`Za-´“¤8˜Ù^<"ñâ„ÓË+p0“†p8A_Ùm?H\H¯ù«¦Ï‡uì!9t‘€èà}îl&˜½²Ã›ü?ÏÃÄ?‹¾½3f¬pÜq¬7Ÿ6š5µ÷?J-> ¼ÿš°îRŞ·ëhûêJm‰éÑ<¡t¶`$x=UĞ’*ålF§Û¼òz>3#{X|€WºÅäÍPùÌjnæ: Zò§!³ÿ»,7ıà¾aã¡ï"(75ıàn±éôíßW›å(\
ÈÕ]MÃÇœ ù—{ïI0Æ˜äÜÆ¹£OéÔf¦fKŒC}GğfŞKŸ¶ŞV¾«jRğÍ+Å»Y0H&.¬¤)šn8-\ÊrŒÀõk…¦‚OşìZ˜1¼Š‡9¿ÔAw°³XİA+S\v	p×|ÍŒM›ağ™ ¬.MØOpsÌª³Cïä?d:DF»]ªRæêI èÙøà¨yü8C¦åô±Àzm¯¼¹ñpbûËĞÚ¤<h‡¸¸¸"~
Ü\JtÏÙ´´ƒI£€ÓÃ/ÖõDoŒjrç"Ğ=îv~aƒKË¾q©ÉD…rñ!‰´“DG¥ò¦€«·Ø ·AŠÒ "É"¡õÙ¤¹Õ†æ_ãFÚ­ziùøÑsı¼3Uábª«¬î<- ÄŞg"ó]U+işŸåoˆÁ|kgwJƒ©“¬âïxÎQzà2Z‘ùì\„r\*Š¶.k)Z[Ÿ›qØšş’y¢ÍÎò1[ "{¬éº¬şP›öm³GÿÕtP-¿o™í.®ø­u¢	;„Ë)/EÁ7ödÁıûÑH [„5ÜaÇQĞ¶f÷zïøtó‰.Â‰«‰ú—ÛÜiP–vÂ¨çéŒ'ÃÑ®p¢réàÅşŒ=Ê/*uÏQÇ[·sl6ÏXÔ¤ ×Ëq¨Æ°Û…¦ÌUe–Ó‡ÑkL–¦ZšGÏ†ˆÚÖ©êDúô"j‡14ÌÈ1’ Ğ˜˜›]ğ¼¼SX¶ğ(Åüõr|9µ'ÄzËz¬ÃII~·“[K)O¾:]¨KŠÌ¾o~ÜİÇ¹©aîd¬VºĞæH]y›û_ìÃTJ©/«X“ ¯v=7zàËæÏ«İ„,'lÑ?Zq“q¤ÇMøÍOyt„·‘m}bŞ:=	ŠÂB­‡åâÛ¢Äİuß„İçõ¾g‘•æ¬Ì}Ÿd×1¥¼o°ò|¯vQÙ˜ëÀc.Q–›*JIu˜÷FÕ]¾—å‡8—ÿ6bÙá)ô^ûpôHıj?Bµ°­§JR.BY=Ò5Û^F³¸s)¹ÄÜTÎBQöÎ•¥Ksn$MƒÇåE™Nzi®_xšz(ƒ/í~òxá^‘;h8KÏK4>¯~>¤¥?HR1dUVå6m©êdé“Ë¯Ã.äT6¦ïßIjªÙãb/†µr´F şğMš¦’—ƒÃÆ.qÒL¶OsU£”wMæÇ²lDA.y?é†“ôø0`¸c8 ævsf¸uî#¹K’AIl‰ˆ€ˆ÷ËåKü+Ì\µä;ö+c\¾îöuÕ«E–â”àşøx=ú¡‰Ét¾¸#¹Ëû‘Ì^‹C\H?¨úËà¹eÌ"%ê€¹cö¾e†L.½ËÙR¬‘£[”IQr-óĞ2şÙ1qİ´®[»©—ºá0š`>èX¸’şòÁV{ÅnG\ß`tJÑ¬—.×§eSU)fîµc(Dh82œúÙŠĞB2ãŞ¡11Ôşò:BÀOÙö3+>ß»å@öÕìmgÀi<¯e­ÎãÒ‡GEiÌ3O²¥[«ÎÅˆ©5(ä¦Ÿq1'â©gşáøk¦­»”¹Å‹2…Ğõ®K”	IXeƒ{Bù`šp‚2<+QÇúã?"(â<1Åj{îHİ~C“Lˆ¹L?õÆÆB€xMPÑàŸT¯¢–r 4XS˜Ä›H—®‚§Cuyb¤û%>Ï¥—–Z³&›òv–‘4’!*İ‘,>èÚÁŠrüòûd¤ı³Z,;6ıß¶o9´Vy’ÜÊB<h6Øè¤†×>ë…ŒLÿÂ£4À~õÜ¦ªĞãètìDXFßOœgäQÚiäH)^ğÍv´ãÃi}8k…(F½#°OáÑ½m„—èŒ'öÔ¸D	â¦m¾1XWƒ]³[|İñ”…á
Tğ)JÇƒ-3¥¦ånoq%™Xn9Må®.NÛÄ'É0)Íóë"R5‡w4ğ)òrû¯ÛDl¿µß”»×€õØ}›`‹¹›|„L¦†@	ïå| ?rçfõ%0–áqÑ>câÂ¦	Ü/Æi ¡se1Ä@ÊgD/ÖvÁ9¾lœÒ…¶²cÆ¼øÕ¯f
µ2|öDÂ	FÒ+¾E×A `S¾å®Â¢ÇH&õĞG}!®‹#µ•%ÊHŒ6ÉLTZ§üfv_ÇªÿzL¶bWÒ%İı½ğ—X
wîšØğêø)!1ÈŒørçóÑ¯ô³½d_X±¼ÿ¤¦;‰;Ä?ş?w-¼ÿÎd#ÿ´Rd=n*É¡é™ÇŠ§ä0#@hF¾ƒÜ±òÄ-§ƒœ¸l¿4t]§Ûe.{$°ŞÑàWöPaë¶»5ëauLXØ[$ÍšGÙÍÕœŠn‡Ø(]iÁ"·?Ùn£’m2¼²rèµ±]Uøğı¹¤2.ªêª[
Qkú'rÊ°ÛŸMÒéş!ëÄ¼m@œ‚¾D—a‘/{L”2#-ó‡üå‘_È ÄCåTªrÜo^¿Ûw‹¯à~LfADÔô4•ãî‹JŒ‘{uåÿVr…ÌfÌ‰Éë„ô0‡~ÔÒFÿº-”Aøô“cŠŠÄ¬Ób {:døu=­&æ6%£ñ!äÈqVÈ<¼€U) pT³,ÑJ†8Ê»Z­K¿ıdNÚü#KªpkKÓ¿øåì¼Z«óÌtÏºz3Nu9 Ì¡[®¦!`aç«Q~?»«Fş¼ñßƒÀ©ŞiÛo­4é¨c- ß»‚à¹*¡>ÍûÔù'hÍ‚&()º{ªÖÚğÁ†$Ñ†’cZO´ó{¾]ìîãé‹URZ§İºáë?Bjÿùj¿Z9YĞX…ü<	ñ/Ş¨ÙdopU‡O´ÌW`ü2€õeÓÔCÖßVĞRÖz~3Rïz1'ôu6?¤.}Ùx–‘¸–w c7Ìwû’‰œ`êeòË^rúÎ¤”§Ë~E%·=6’¾Lß+
NÓè‘é!3[%$Ac4ËkvØ°¾c7ˆ¸>î¶²œ.DĞcóÆKÉdwØÕ>?Û•%ã60ü@ß³nâãÙÓ½&ÊüU›=$)a[b)Ğ‹ßä{×Ã"ıÆ´Ø–Ó¨s®¸~)ºWPG6IuiA\µo06y´¬VB>¼^ˆ?q”Õ\\ŸTéÖÜå¤‘ı˜ËóqºÎX^AÔKós
¸a«¼Mrnä„g˜ï
ğ_9äı¼AD1JìBiÙ¿|£ô~sù®eÛÂ”“9(nıx±ª@ÑÖo­GHè"/²,qè€‹Û_†[‘;!ä;RQÊYè¿éf˜´•´r›{»~òT#$VLŒï¾Üâ-S_ROÿõWÔŞ>7kÉ¾bÜ†¸®¤$å=É'0R~¶Á(ùúÑ™Ã¡÷è«ÕzæÊ ƒ‹’q Iqq.Ì‚Áå·Z-vßz×.…€UõğLš©8 ³E›‡ê*‹õigÛ¿¿|{+Äd»°CNì¶¯î §/o;U[$­Ø()ƒªiiCb©Ëbbƒ$<ì´çl–õ“2wÁ°‚ã	Ü“DÆL"™Öaíö_Q€‡ËŞ‘xıŠógÂ$ã[§ûHäaÓ\êİ àm³ñE;#(A_Éú~§HşY†ù:Ì0uªÙlGD¨S½›,üN”ä>ƒ@‹&™Tkîí?Rx§Å7$l»PU×\&Ö‡¤RX‚ı¬ZâC`\êæe‰ñ³×°€(e`5\¨™ze¢a?ü\æ°.6Â0³nƒ­j*k‚>²µÔEEçÓX¢Õ´˜ë÷.>Óñ¥"hÓ.±Ï3’•göë¬]ù¤È5ÛV*lË\Äª‘-ôæ™üÅcHª_ÙŒ/ «âÑö˜:Fç[kıò¸Q»Ó¸uVäï“SãU=kŠRÚî¥°RöVOdRõS69†’œ°ôôÿªÕPÑK@¯pëYĞ§ÔY—ÿÖË¦Æïı'èT…:²+‰’S•UG×qX‡ChÇq¬›0O†“lP¶+²ãÙâef`qáÚà—L :Ş
)üõÂÖl&ã%¥¯ÂÄ¸áHMgırÌÌS-wc®§"™p<›ğÖòoBØ£@Â‡1F‚ÄÉv;cÆU^¼C“±Gl}?æÙce¥&åÙ 6Q¶œ¯À­!¹Í¨–¶ ÷ç™A|,¥=Àá‰J/7;Ê3äš_œÔºÌx2}AP±®Ñîœ¬ò‘Ô¸Ñ XÙ½ÂÑÍfe|HêT¿ñ·>SiküT8c’óÃ¤÷ãùXÙñ¶/0m_áOñ]ˆÅ¤5¼“á$Í9h9ß¸z¦Xó—Yî¸’ŒíwŸ0»ìÇ~µ¹é@ì#ÒÉÛ7AÙ%DĞáµSÉê ß–I%)Ïhêjp XÏ›¹ÍZ”ügÀoşCy7F1´ß‹*´üVœÕú7²¡~Î]~øE+ÿëòTÌ¡oÃpÉ÷Ü¿:¡Û÷¼˜`NIÛl„KNĞ¸\?·àçì‡
÷PzùáZ»Ş÷wl˜¦âñŒ±.œ®NñóøcØ…¸t“aÖµÈ©[î¾Gàà¹&^Ÿ†ˆsà~ûóRvc§an£¨$qé²nß¢m=™MM33Àp“Ï!º'ñääö)ò “ÂñEg(¢d­mAŒó&€ïö~åÑ£1Î~;SÛñî¾q@'Ó p„ºTmS“÷¾#<²‰kş:\\ğº,D	dõx®«™¬ è#%}¡“öE/]RKËEu ¨èR?I£j9şB8Bµ²F(–ÆîğÏ²ëòdV$ü{îhj7×h¨áŒá1v`Îº6Å5Hrâa²[Åú¢qXkÅ©6õ4ŞÌÁ8Mg…«åËµÉ™¤{·ßóRFd¾ªvü,‡TA¶3qiı²âæõ½˜FM?_ó?VuÕï£•<ŒŞió´3€pëù/Íšù¶/ÿ“OğœåZ`†à–š°1õR[C¼s«Üÿ<å¹µJõ™â.·ÒG?ëe×ÂÓ.¬£Œ1~ÜLä1`c!«„(0¢º'#˜°¾»òHî¥LóšÑ÷Q½S(‘¾ğ†c-óVW¯Id®ÄC0¼(Ù6€J¾æ×f'Í¤ú'äµE"‡E,m¶š„ŞG´©4È„ÕÿvªòÙ; õÅO·•ÏÅt-zã¼apÎ¯%o[Cßğ‹ 8{(zf ğ¿Èƒ3êXGÜ»2Üyî¹ Nï§0ù^	£.\ş^­xá{V4*Gu;±¸5ŸF,¿1z,Ög/°¿¸&<hª„î¡‚L×[ÙoRê!Çˆì,N#	ÖÄhŸNQh”ì+ˆÿMQù…m&^ubl8İ("³Ê\È:—
ñ¿Êæ›“ŞŸgt”Ê?Q‹ *~ÖSËá_åı]¥£i}É€Às¢¼”ÿèí?¡8zü¤{zíOşv2¬Q­tg%ÒÙîvT„qf_IÄbBRN®¥õñÒ.ÅĞkí?’Ö7¥«Ò”Ê6äs6NÃÆ%…Ã…Íyf€ş}‚>¢«¬Ü×šH¬ôˆJåÇ•ÆítÉ8/d$c„âàP Í¡!ìÓMnR2S¥»)väÆŞ}5‡u>ŠvBJâğ¼×jäD„¦hÊ ±zrÑ{¢)…"!°—’Õ¤İÙæ€Äñ¬È~z8ÏğÎÊŠ´ñwó„5A|@f×!¨è¤-7'N&bŒQip—YwÇp¦r¨ŸÜáËKÇ™¢ba@­CYYOZi|éù¨£`‡ƒ0¡-,X"iŞÚÅFyşŒ)šÉ‡Fß§HüòØ"n,ü¿½ê#îd\¸^X( gºÄu5£oÉUI‰áiÓf¢Ñu7›³|•<Íçœçîâ(Å‚»QLZ‘ÛŠ¿MP-ç.%ª¸¢ŞNc¿r’#ÊxÈÚçµ
òZEX;óT¤.Z$JJG±ã:NÌoWvöáÃÚín.Äàe“SÑ4AñìMŒ‡ea‹[0k¹ØK"HW#FÆsŞÛfİn¦Ùê8À>ˆÖ`†(â}¥c=u4—êÑÂ†Å™¸xïÇÚb–š‹h¬™MeYXÄ÷T6.6HáñnºPnê*M?’Ø¥`ñßøÉKjdç]VfäÁ|Ã^«×éÑ:×´xÈû:¦Œl0¶áƒ¹¬ı’Sâ?‹bõ&?üˆá%h=÷~­[µŞ©i•S'½PÁkc¯.Œï’Û>†Àl	ó ¥órY-Ê6ØàëG¤f¾í)¦w)üîÏuNh¨;"DIİš•2° »ù¾àƒËÑzÙ•§’ˆB˜ÜÖáÆ´™dÙÇDªØ/Ú¡d1ùğığñCb&ÑÒõE˜‰’.õ•ŞµIÌû<›cA¼oQ…Œß¡¡:.Ræ9H—D "ŸØ 6KRp—÷33*NÀl¥‰?[<¼«<é$ÁÃ-¥Ü O&Û`Õz ó4*¨®$0x{ğ†ğ1Äû¸‚Á×¹ÔfLbWpÂÑ[b°0µ°Û
¢h~ÎåñtnZ¸(A^ˆ6ØEÔÙÏ"ê†#‘WgĞÆô|G£Öb‰¥ØNÙç&Ñççgàf[Ô-X@†v‹o§¥§?Ú˜¢3ìrñB9†||áı‚IÄ“M8ø«l·=‡I A®2ÈŒĞİ×âÕ	U"‹TŞÙÜ5r?«¬Ş‰Ü÷ªê³Ú´Ójl©,wÃ|§XÒ›¤ö'ğ§È•ówºJ‰
B(¶	ô‰ÿ†¹€Xåœ`ï¦Zrè~BÖ{I˜ˆòA^^>!Bü0L{U›îéÕÒx;á}|zãŞæ„²ıÉ^İŞşt·`IxÀ½}¶MTò—WªLÊFÈÓ»'@Î~f¶CÃé¤
™ôBWCÅ.)Œ9d(riLãs<œÌïŸy(89K8Ç‰˜-­_;&wõô†â»¿¾„Ê£¨¯l?(BÓ‹%8¢JPÖ¯Í&-ub…O¢‘à©Jßùz)®µ˜Ge˜Ã)ï­ŞØä`r..ñ’Ÿ;#é°ŸàÏ^Vb‹0Ã*şùo/·¬@F|ó¨|#¬“°êT_”[,"˜¯f‚@¯ë×4D‰#UvÚi[±0È‹ÓoénfÖÃªâÖÚè‰‚gx±>èó³%#ÆòJnT›4jü`u"Ü†[QÉÛ£ËVâ30†Ç¹8#İ±›áŞjÅ[‹N7IŸ­…Ò-Éï(i*Q=HÓT@ş+8ÛîŒ´ù”GC/)~<p­…©P¿û2)‰í‹ÕÒ‡ù’—_«ïô²ŞTÍ‡³z±xÍì¹k¸!âh-E¡_5°X6mrc9 4ï¨ø] mÌä,ÍÓ/=‡?†M¾ıÏÆ½Šşl£†e»àİ,5¼Kù£Á áÇñÈ/”•÷/´Jñï>Ô6¬ş}”ı¶ÑaßÛÈ­®²ñ 6L~>¤•u”€”$Adn¾–7X¶Ò«#>™Tr&Ï$Ï"sUôú"Î#Šÿ…0ŞœŒ—oÂé9nÅLàø?mÔ=	ãïqxT¨4‹ıÊşU™ârUë£B¶m°Ø¤˜ºØ·Î"†{4-—«\7}P€½¶CBÎ¡¡'Dx:4æ§*§`n%IÇãeŠ–¸×=Z±¢%>Û%õÇÊ-UlµqÁœ‡ÔI:ê…w4/èYĞĞ%9Şf1f:‚rÊíàe“Üql9÷–Å[Æ=\·İ'ccö×7äe"RrZÚjÍŞ=©`„²uê `I«y4e´}§Ôzİ±É‹Ç‚ƒSzõÍ‚d¶<¯mz|ÄóÌÀ¬LeQvÕÔjQõ'5cÕİà8ûé\^´zìÙà_².¿ËS„‰j#fˆ7âTàŒX:JµfPÔÿ1C/Ó%jwwÀÔE.DZ;a+›]ï¹ªyº2®ˆÌş—š|môŞ4lxR.±°hf_YW£©æ›D0‹¹x¼ı!£“ËåÉ4÷²ë+Ÿ|ã>E³İƒl$hº´;VŒZñÀÔ‰‡©cEHe“™1"HÚÌ2­0Ğ1'“Q©¼;’Lç
÷	®Y~zóã*–S%ò-D$?­çë>Á¹şSä¦ODÔê[ãªÈĞtsßk-çÛ·hãğ
6K`’‚½zaeöÖ±z<h­Hj‰eèÆ@Ú¹=§ùlİ¥Lƒ§®5P¬Á»Î(¢L;&ïîôbyi8Â¼¤İ5!®¶ñù×ÕS‚'-NqtßXî¦
4M!½ ÃbinÈd,Jé›3mY¸e*‰øQö^å•VŞ‘]C¡UëzÇøL¡+…?dµĞZ<Ë«pòÕ³éÁ—÷%MušéÔ"}ßMåäc–‘ê»c-*¾ƒ´S?€¸:Íš98."”^RÚÈ	Û§|­¼÷ÃÈˆªXä8\'ùª{¿é&ëğBFí/Ø+{IáZÊm?i¯õ#A=ÌSå%IÀjwgº$ùjjhÜ£©µ.Š³"& .:ÇÁ•qÛ¾7Ñ¥^RşºâùŸş+¼AÖõ	é0.kÀ3¾o"×ßÁj©1Tø\Å`0NöYl@¸†E‘__8X±kÑ„k”µÑFj^]÷Á2EÄ¬À>¹>íÑx!äÀ¥í/àQ³Íğ€ªa4ûD\GÄåš­£0€ìP„¸‚°3Ud@Ûê_ çô”÷FÙ°2Á.YEr»u9yŒ«"·u”t¤´Æİ¤l[·¼Ä ÛôáØ…&&<ë–$ÀåÀvÇb¿$§¡z×#–U¼*İ×ñûŸOZKØõJävvşß=†Ö0€_ñ~%3Ç	Û¥Ğâ’‰ÜÙF:båW6ğ Ô[‚&°Xecºwoæ¿Çx)«@Ípuå;†eèA‚ïğ‘ÌlÆ”¸xË!PCğîK¨Ğƒí)½ë5€ÕÎu„"Èï¿Gœ)eÂ}ìê~éë.ö~†[‰Ì/wŸ¬—ë™C(“rIYê5òH)Æ,i¤Äj-MoKnôV¹5ÎQ3}º¥-¥@<†¢şTéoã
 cô¹n8>Mú÷¯61©ºÔ0ÒŸ9ÿL˜¨õ½HPán8Â˜çÔ!+ŸxĞ3¯…òaÌAàRØ±'¤g9Õ^´b${l¿¨®µMn;‚¯m0’ÿò9¤ÿ¯` êaÂÌ³ªó ß`Ù&¼ä…€ÂôÃ/Mnjô’N›a‹b—c‘õBÂ 8Bè’,¤íq·%Uv]œ½ÁÄÓ¸gı€õ²''—NÙE-ĞPœêPÍ}NO"ˆ
>]¹_Ë£œ„å¶ı¶Ü‡^)ö`äí…#5SÂ1Èx˜qPc,·à$¿7Øpãâ;Uë3KŒôü²şDÓ‡ËŸò~öŠ©ñÜË—/G4¶”@ç}+’Ó&­ÖU[3=ìa]°¹›]F¼tGìi£Å<0è_ö]¡éíòƒ¿’ÊŞ–“=¯äŠ†¤Öl›¥í¾¢¼[n³Hİ¶É»9eò[	³$zhí’Çúwqgä6<½CÛµ+@U²r{uNÑk«CÈâ¢‚#çYÆDÅ®i=$í(ÙiäòóZ®º[Š‚áä}¦¥Ágª{Ùqz70pI#+›¦÷Ÿ¶]$—Š0’ğŒéÆ'<¡OœvFç§½-~BŒ³ãå#ËêáR‹;Âê`V¸¢O ğİÒòÈEÙzys,	aï„)³ c”íşëÄŸFÍG~°GÌ=ğdÕIa6v¸80|ÒæY ñ¾,<œ½Sj¨÷²ÃÓ&µè‘g–É=æ(£plWÃğq E?©˜)¡ƒ«À	Å>—dn\Hù)ÔÉì(7¹„ÿUqjÑrúÃæa›‘'˜«ğ‚Y Í1¥‚ÜgVÊr­¾üàá¶ƒR·ü‰Ä0Ã!Ëõ
¸KÚ¢aYÆó-6#»†–L¯±1˜ó^â9`ˆ8]~W1Ÿï«ñ>Ù†@õõş&ıd
*=èàå™¸´Z'Ô
kòNåßaÙû³ òŒ³-æ#6ç.C÷Ö'lzUë¸“ëµÅŠQÙyôVÕ6èˆ
 ÷[]Z‘LQKóÃÇ™ÒºßOŒìÆÒú@Œù¬1å²{¼C™´g¤r:R»—ª¤ıg_ÛPéƒ2tı"c“òQ}–GP#ğâì€e¦j†ïqv†7ƒŒñ 7„+öÆœ–&ÅàÀvy»±#^%èøö‘Ş@K®¹–±ä(8İ„óÕ¬/f,Ù¦nC±4©¾³HòúÆ«Ù°1`Ú!]0‚lpë(@+{Lš\äÙ~	Sxí
ò$yîz îñ‘…l¢SûÔ¤Dßl!·Ô“1ñ{ªZ}ç´`òöÑ9:[¡\rC=D¼œD»2\¤ÿÙ@Ü—z.ààåÿÚXVÑÙ0ïgÈ$æcdnË<?ÈÏu‰gÖüá¢†;ÎK‹í¢ñÊÑ.ˆ†	PYL"£øzS—O]şÌæ¼”4	—ÉºÑ=7@ËŒ"ÈÌ×*=\”(@öae`÷ğ¼y?l/¡YÅk WJïº7d\}Q×x¶/]Ùò?´Q2It‘ô/J°—d¾ÿ:–8V×2É=y«•Avã4y%ú=Xü¿7 U\öï!¡Ğ1V0ª-»•°ÕßÓ	‡å>–1_Ó3NÕ¼õ;ë€ç[xÖà‰Î©Ãü‡y‚`«²M?Ó3õ×h¶”ì©[]¥ø~	%¥´·!U5RœdBä/Ñ²ê`"Wc£GÏŸÅ…OMİë\(xIe+É(:µv‹oX~ªíî¥®"Ú8CŞ2AP9÷çX4®Z0³ê¥¿ò„>‘ˆÓQú?şP-½lš#¹ÏYndéÇ@“¡hrÅ‚—¨H?%«Fd¢£—DkZ¸&Z'ß°ˆë‹víşò'àï]iÎÂÕ©yÏ“Ù5œ8npm7?^ÄªèÁ·Q©Œó…k, ±6Õ±œcùsÿ}«BÖw¤ALOšağ7ó^³=µ!|™Ö+pÂÇ‚•€c-]xuU
¤c	¬ÿo†_‡MÛE·°G¶­.s´oi³Íg‰©ó{©Â‰–AkÍØEõÜ$ª¸")$“Ñ01Ö¼õBõ+3º¡×FÙö]ŠµN6 ~æKE1@ÛÒıÉ“Zà†‘ÂSK—ˆ'ä»Q¸£ÍL4ì«›Ç
¬ÂÌ1áU7ió¼ºÅÒ9«n]DN£&™–¿„»Õ¢Øö+|$Ì\;¸`ÄüKF÷#ÃÏ0ªnmÊ™#­
'8æ®Ù£5qÇ&Å|ùœêÚ\O+øWù7“Ø]p|2ŞOŞhDbU_Ôr u£AÓç¯:üC³9¶¤|®\åÎ³9è°ëÇ)½ójøB±?£|™–q]õĞ*åo™R¹ãíÉâr~}t.çíiÜ«*™ÀUIêi±ÜÚp´/©ËF]T0kÔ•„p®í[ÿÜÃ¾¶Ú>}Ä)¹7+‘ÈôªäåÚít	Ü2kV‹s¨´×pû'&8‰‚ê¢›W.œk9Ó.¸$Š	Rï?¥r4&3YŸ´P5pˆ&ÒÓyZ¡‰"¯0{dNeú¶ıâƒá!wqô…Sr3Õ 9†ü¹¾ „‹2ÃuTÅÒ_ÇPòšª
;wóÊŒ.2L"‚®úÁÔÑb’ëÆNFÊ£–q¤‚"'h˜İÇLçqªıhNğ™$ô½ ıŠ,|_ÇQa~ËâV#®]ïÇøsVC84éNîFû±¤|P¥hÊ3Í~Â¨LÕ‹’Á2¬ÀFŞåŸã.ú`*«@ÚêÏJ¸#66@ãWÃE°’	+:f#‘Õ>l×È5¦lÌ]ÆÃ«u•ı™ÅıO‡Ï¼R… BRÌ%g­y²›.pèş3Ï2SÁPGÀæùj›B,Š<h¿5úêNêeyŠ÷q+R}ºËçt¥âúãÖ‘N¦‹ÂRÏºŞp{#ùÎm	>*$#¼ßÒº$÷sÉT»ßàıÕà° o¯dGÄøKr£ƒ{¿ø·+aÖÓZ÷õz	‰Ö!¡ O{S´ÊP…ñ²Ôsv}æ£b:ãJ£T>~ÒUğPµOƒuà\å$¤Ö–§‘Ÿê[	5|DLıÎÜAFï…}2ÕŠ›v§k¼Á»‹N6T¶êÚwn‚Ñ=í~ÖŸ[\„ó³Nh÷ŸkŞŠÀá¦ş“ú}¿ßiÊåe‘í_9¢êÅOõjsÒÄuUäVÌ„Ò0.És‚[Ê>&VI­Ña2Ô/†ÌÓË[M²cU0VŸş`Í)2mngó‚b|0d˜€Òl_íÕÎ!Ù‘ÍT£á <X“pbs–TÔ‰ÿyÕ°Ìøá›'yY™ÈÂ¬n—¬¾9±³×Uõ©  hê7BÉ)0õSMk™ZSGõ\lEŒDÏşV¼œ"İiÃcÂÍ{œ½&·uİ¸š”Idˆİ÷|ÈRÊa,œJÁfë•Â_“Î=ºwQˆÂsÄÙÿ‚ZÚıM¡7˜!¤£b«Âì.ÿË t%²Ô¦^"=ÜxÑ/ÛÄÍCY-"5î1>§Wöt›OBbù~4g¹ øÈéòñÁ_Î¥ãoÎÖ³ŠOy:ş´à1€	2Eõç*\¡¤ƒ«$©İ‡~;} Áˆ›OíóŠááµü¤éüãÚÉ[@&d=1b–uøØÒÇã)º„×¤äRjØÀ.ñ(^<XÓí#"”†]÷€šo¥.¸ şƒO<$Ëiìdºc.9Ä?ƒ´Á§º¢ÌzÕ·Å*H€W„#Ÿ‰ÓŒÒˆaTFS_\ŸH.›½i1öÖğ 4eÒ3Ÿ¦İTêpRæÈ[bGÌB$Ê(†íum”óC%\ØMå‚2{"=²õ¿+ÖÔ¤¹.${Ák@Çñµ#D{A@„^a¹-æ"Şÿ)Øíœ”‚„à%h9êMñF‚|Yşş}û~G|-¶ùÓpz­o³©ÄwŞ¢:op^p> òı0rî©ôK)¤¾ïÔ<_B{ƒ²œ CŒú’Éá¢, re°lßrZÉÈe«ù”ı".]Zuvñá²Ùó¡k’¥™x/°ˆ
”ÎªÊ^„o˜H/í6lšSØœ{C@†l%6´ Ô¿É«3×õÛíXÊ¦Buó]ÈÈÙÀ¦bÍÈ`Gÿó˜Ã*Mù”;_—½¿Qß¾yãspsWÜ]°qŸåtføj
1ñIáÕ»ØĞ˜8º³5-Í´p)Å„uÀâU	G2ì“ã®‘+&÷q@9•Laï®èO¹n¶VÈ£OØn´+bÈ¿?›}¤uVm¬g“Önvz,¨ä‰×Â›ĞYÈ¬éöìå|Ycyšû¿b£¯Øÿ>Îs¹á(ğèœ™ÛŸh¼”dl5DFØ‘ğú¨"Ë´ú®WÀÏıyzíÚdûUüÉˆ2†òòh§¾ö”ÂËİ­ôó9¾{›†yƒ/ni-ÂAÁSß$«]^ÂG€oW¦~ÏQ{ğ¾ß\îc?iıŒò‰ß×ë_!¾=ªç;½éc¸”êË™^`4–oÊ¢Ş;‹¥nxs’ğ:Yà–Œ‡/¥|`˜°¬;MXbqè‚®²xe8l«²dù3³ô?Y!%xßâí Ùı£=ºûÕÅzaŸ†Ãâôş.Îıß‘Gc>; qáW¶i?pŞLs¸[œm¹”ÙD€Û‡0!­£¶kcÚ‡hÍ;=@ßkç	Â•Í±Ò½cš4IAkê®[‹.Œ½®Ğ÷IÜH¶4ÇiLÉ5î”«ŞÅ°ÅTñOy4»tûyh=¼L:óƒ(%0^‚“ƒ{ù:êæFü“"V”n\B;†°YGƒWTÖÄïœğ¤77–Ìí-Ş(»¶#Óä¡aæõ1îcïëû jHihGËjŠÚs*Ş¹Úp…Gl‹¿+"XŸêF’3?şC-Ä[9vayÅ°Uç&[- ]´˜¦/^R/pè êì.`Ô.—TÿdXzáÛˆ|XµO.§y•¹d¬ÇœÃbxVà 9¡¸ÚÑ#o9 ¥‘“|O¡²‹§kSÌÅ 'ü*­Şg‚Û'§9±tcÔN¤ñ6R–.DößâÄUÅ0Ntò¹¾(	Zä9×$$ÚíÓ81ğ¸¡”ÏÑòå»Ã™iÇ¢Ş;Æ<©âešAwd¹FÍÛÇÊ~ÜX *àĞ‚a1–1ÂEŒ~çºõwzv£€ú\¯¬ĞğKá'üûµà‚‡5X¢Pb7ÏXs«‡ê£xÕäã÷f`
û®òü#Q"Ô}ğOlWØıŒfÖ‡²vø}+ÇØ8Ÿán°êé(+¸IW/òâ‚e‡hoµNZWß·Ô<F;ÊîL O39üË>š¤è-Î»XüiıQL6ÇÄ(Ì{ [¼€W2–“\ğƒ”Hë—k>Mf8:Á¶L¾Ã­°\Şƒ-÷ß¼#ríûë¶ÆŒ‚¡ÿCc–gq_pƒÚº\ÃñàXoH«*kû9zWÈ½8!ê±kØC™eI*M"
~=ÇÕû¥D§DL¥'£Ö^sÔ;•^Hù}ç‚ÅZ¶	¤ğş¿ãÜ ¢÷dP»*–Eÿ0›Áth€¹ºyÇ€„$@Œ°À´õ’†Á0})µErô‘/Ù"&’ğàºµ=4ÀäPH»,µ“µ¾°l=¯ÎÀÙÉ“ú¬;††o™‹Ê?¶Xãß€ˆúy¦n%Ó{×ïÌvN7·ÆZR`¬¥„áÀÑƒjRqøt0-ŸÒ¡.¢úaÒ;ÉÿR/"J€T­"°»FÀF¿9‰V1–‘Òû’ò­ÔŠûÖ‡F¥2–æƒAPV!ª4*(¬ÿŠcÂwQ½‘sú'È²ÉáæÏsh¾à™ôƒïÅqÇé(üÃgd"Ïù]î»èv8Pæ‘ñÆ3¸€gáX§KÙ­Œ¶„£®”ÉĞ†%É³±ÀÛ˜„[¬o6x­Ğ9X^pM_]ºî¸Dá Î’‚™&œ”ôµ.º.j‹rü ‡xiÖGÁij²LÒ~ñÎH	öîıú‡)J¯™ŒC•#ëš‘<êó‰‘÷IØ¿ZI¦2‡í,â®®¡çËVÂàbÁ’Eıæ±OÅ!¤bf5•u5…6÷ÌB]ğóÖ¡8¹³$ªöÀ&ÜÏG~(¾”Jó×œÏWş;¶8(“!nJ‘:Îzc+]’'ôo“ÖÒäĞÁApsÂÒ½(ÊjWÀ|Z+zĞçMõNŒë}vª{l¼ÖQ™+ÑAß†ØÏRóL3öÉ¨wÕ©0ßH¿J¢U¾Ñö‘Àøø âR¿Ëiı¶è‰È´¡¶>œ N7Ë‡×(^¥™–Âeù·Ğ8vÃµ%…Ï@Z×l)'Œ¶rY	éHó…kgeºÆDûôüÀüoù_GÜŠ¨g´V¡ÄöUAÉ)e>Â9ê&/F½g¥+.†6(#/Y÷È«rºG|H¦i¡ç¦†ìÊ0O ;`³æ¸Aú4ÍÈIİ4£¨Oe©ûö]jmÄ%Å?ju)ƒ’C(¢@.¨¿&Z7]ãRÕ‚vëg÷ÜÃ“"JÉ¿ıÅµ¤ÈZÂ^ç%ü›?£Ô¤ÁOx·âƒ|	hËê”óg1¯—-şéí@Ø²³µî•J¤îç÷ï³ÿã€Áö¸8ãàeÅaµ`|4&w)P7èu˜0åóÀâŸc'1Ãô3]8L¦TzİÛR¶Ä…Û™{Vc5²igş"Û‘oiÓD€I,Ô7ƒT¸»]İúˆJØGáQ‡ Ëz4ÖêT[şµ©Ö6Z9¯¢ÃìëÜêª+æ…Ô¸Ö·¸1%v!KIØëïAçè•é‹«û%K×7Úï~:túòÂs1(PN¢hìì£¥ÙYNÿ{ğtõøÒYÂ—(s%ë…aÿRäáßi<gO˜z3ú²ïÒR­ ‹s›¿Y>Ç2ï§ÏA}bü^ÂÃZÈ”:Ê×™ùâ2¿qYÊ»€.Íl/)©4£ÍôhW5ğ/[}¯Ø:Ù|²›¬ÛŸ0L$%ë·|ën¬ÄX²sïÙA¹§fÚ,SÓK ¯VIç¯±:y)Ç(*X‚8j;'`å™ò7(3+GŞ©–hÙä³ûÙfò¤÷>Õ²»ZÑH õ–Á†²÷¤©óÆ¤I]Y;Q–gÿ”çÓ:ºşû‰^îûMP³—ÜÛXpÔI‘‚üÔ0´ö­TÌ8‘²}é”÷tÏ.gri #SŒèç‚5zÃDOÜÔ ÈsrgFm¤ĞqHÓÆx	2 		—C4:ÒŞd‹*KÉwÀÇÜâ'MËBn¦Ù`næ)m¿ÕVšY¶TW“¨Õ)%ÍŞ!˜}i›‚Á§åŸşı¶AfKh·0û“"‰ÉIWÀ*n¸T3¸õÿ§q-ø©€w/’U2¯ÏesoC“é’„´OúÏæåG'ô;5Õ[-58ô±åwQ4ÅÔ;îĞ`'§†–ö1}>ŠÍx†)ì‘Ó³&¼&â†<=Ê[¶”#ÏKxŠˆÚöçÁG|ëNhÎªMlñ—^Üç×‰†”eYî©_eßÜ5û…~Da+¢”¹ ÅAXµìJ® ô¬$³’Ğy«Reb§Xaš]¬O¤©]=â'À«×µeµN»<jé÷l¡t4)o¤×Š«p<µR­:ğ)Œ’	€gYïY.Ö]
s©ÿ8õ;#ë8ÏF›wùv‚ü˜5Û„şUæg¼Âib0 äî-Nµ™ùkWÿ:ªĞ›÷OÔ´íi`2½ù¶{·¡ÅÒµÄ‡Ìq0>D$”ÛïÿÙv›}Ö*à-‰)Œ†®ã=Ï±BZ.wBñÁ*‘8.Ñ—6ó£ó!›{Ú¸€q¶.Õ¥Êğ*Œ†ÒÎ°¬bßü1/øÇòóúŒìüpeTPÍæiou±¤º¦÷Rßµ@á)ˆ.Ÿ¬Ï¿‚Ã9àº€Á|‰G×}dš•©{ãw˜ğš£u~Ø³—JvÑ%#ƒ8IØÎ”8'E£¿t™¿ç6ÓM;DÏn°³|¶YÏvı¿5…Í>ä©f<ÀŠëæÈË_çVÜºp#FTÖ‹±ÉCf²B‚±ó/ûÉ3zu]¤ï­GÙ®ĞÜ{›ƒ¬,DLæÊõÁGnQqtÉrö%3ÿ³Qó"€ŒFà‚tËäè‘­½JİyÚfj-c’Q|S¾ªÑlR]sŠ˜Úe`'mI´—rWš¥ÙàB¶ŞQÙe
Qÿğ¢DlTğO(ŒëÀ Gè:Ô`ÕÀÅŠI§dºŞÆA¼ô+€§»¯ŠÜ˜Áf¼çÕ'ûS7&p,šé¥­u÷y‹v‚³¤TrºµÜgëÊığ¿„5V^xÕ¥”˜´©}òz&Å¼
ëDoí¥æumÇ}İthcµ‡[øÄ=ä?¼¡ 	§‘‚·(‡¨±Ç· ½óŞm;b[8¡’ÔEÒÑÉ¦gw=ŸÎl¨¢«1ÿoÖ½/ß®]ë}kŒ{Fâ!ù¤=”:,øğîÊd
…ìi&´ëÑüO]=ù©ºßZÂY,],=“ÃŒ×cíe†œÊEÿÅ.Ö1–J™ôÇ\æ'Í4ò<xŠ|¤Ef«ÀA¹Ec!Ğ§²@£æ~8«ƒ¢ˆÚp-êOi!i®!Ï:óÓş³à³ÕqÉb¼Üï<æK×s¼ıÀ{\æZO-ä´'ÁXe4uXë>vã„ÀÍ¬ÈøÚØpYd>·ÑÈoâ¯Ä[™+øIXjsèÄébâKéÏ;³å…›‹ÒM•âŞÈ‰,ø©°ª-o¢XìcÙ<ï¬V,{ûr²Yæ_çÒ[Õ&%|ÌŠÊ RATç¼„,%vS¾ì@¢× âÃ—¶Íyôv
`Áê{v+À‘ø±9Ã|I­ÇcÚ„ö¼´½H£i…BR¨gG|ø\·%=2eÇÜ¹4&kÄñ¢Í“ÀöÒMX¶ZOËÿ÷ñOq¶P(ÍEùdù4|Hå%´=xÈT“Ÿ@eâÙ½ö®ıÍı"Ótbkı*¦Î#\¿˜[D£Ñvõ\"|PRa$?ÅÍœuÕÍ‹â^Ü½ßWÌıˆ±k3 éûr§ZVa·î‡¢šš›£f7²°µcR]ŞÀè?’tã„¬bN?mG¼>ºd|‡“©P¡¾¤mÇú˜x&™êü0DaÓÙ“R/Nm5mİal¤7Íô½“(GÙìD¨êœ‘÷¥äÁ2Ú4qË-Ÿêò÷6Ñh2E„Ä¢$†éñeòpôßxWyôû>–(ë©cV3=S_iÖnA]óíÚ”ª*Ê—f¿tÆd@ğÊ¯ËNj0Ha Õ‰© ²*ãmÄ®ü¾"Çdc\M=q¥k0¬DF$>›y”è“Fè¼r	Ëç*:™¾'PdŒÂá-rŞûØ"!Vïîí^e®eçSÒÕã{…¿|úôDx½Ï>tXD\_l”39/ãœ^¯¿¥.Ši¢PšÓ¶˜5‡klV¯Z6CZwL4“•EÉ¤ş)ÅJÃÉªÔ¼0&fÙ ªrHG^ğaù‰L>‚¥æëäÅO¨§Š|·Ê·±pÇÄc<‚¼vÕò8cm×ÜQ«»[Òí@İüK3Ş]et<ÎTpD¡³Ñ¤-x`5£oicÆ{ºÍ¤›ëˆœè'n²ÓFuµ¼ÃèÜ3–$¹iîË¶Qbİ	£¼hæ?e˜¼OqŠŸ õq¢'†™É÷*à}!xtæ‚½Û~°ÜI@8øÂœ…}ÜÙÉ±oy‰J…4 ¬Ñ€ÿÃwqŒÿçjÁpPÓé·Ô®¼Ã·z·2»?Øã+ÇaxÓ©¡Ëôıìlíbyt$ûO}ÊÑpRfãô¥–cN«‡ßãn)´•àÂ!7oz¸ädBï0¶,Çš†jëš¢¢#ëi÷¾òò¤¥L>¦n´tBT}ï¼lˆİG0`úp‘GY;lûˆÓãP¼PCëÅ˜Ÿä›iáì”§‡*°ÃŞ<ëİ c¸Çå<Âï¯Ç!ççm¨­~uµvG”ñ
3Âm=ƒ–D*û?ÖŠçÓs>.Ÿ)±wZô*]˜FíjÚœï¬¦Vîuc<äJés1y#t¸¼ó]ùáX:¥JQ]È¸íÖ÷:ÕÖ/zqf„ì=ê£JÇP÷Oq%.û!öÂÚÚ‹Ş¨Ú^3©ÎôÄ…Ûo‘ı*ÙÌcXÛàÛïio-Ü×‘ò[EÔÜıcNÓİb£ËxÎÿåò›r„oK¡ê(*¦Ù¬v/;õCÏ•jØÇäQH©I¸ ñ>­Õ>âlˆÅïKbF¡'½`Q®ÏgH2%¸¨Å9€ot³)¨—­¡–Ò€#sÌeš‡>ÊFêÙ½Ü“*bNG<7e7a2°Û~ÎÜÿÍB¢ß]izñQlÍ¿Ë¹*Ñû“ßÊ?önœÔ8İ˜zÿiWÿ»ÖÇš/óRŞi4‰½‚‰íúğs½`Š¢D-J]…ğJc%¬ı¶3Û‘F
ñ„D·:ccV©°;}S•˜ë2V
ı×p†˜áz ”kGïXe‡hwı”Ÿ3ô$8é18ƒ½/ÉmŞ3[(x5Ù5àõ¨7Ü*»’KÑ¯'Œ²5Ä¯ÂõöÍöd¥E¨Bó¾İ&Z–È°°Î"”€ª‚î¬ƒ˜„˜S­í"ˆf1œşU.•ÊÄFç¾T?ÄóT ¬LV)€µtUšeÖ#ù°¤C~ª|Ú­7tŸ™6“©ÕŠé‡Ò:}¬ˆt‰GL®ÙĞÿv<º×û¾{`{Â4È“İ¾†¿"dÃl][°{Ì8rç98î’‡h–o.q;:ûßŞ°JÊX½‘Ş?†º½¡¹4e$™?VÆà	†ğ‡t²¥h$©[4œñø¨ªù—Øg“ôn2<+‹jâ*ªàv‡xÓ×œqø…"ìF¹à;72ÜMŸÿ#šğÊıùÌú“A 4ÌŒe¤J,ó@›uŒ¬ï÷¦ÜÙ	³~	k¢Ğë8k©¥f³NJíŠq½Gûu%|1fÈ·%T[ßÂÕr™NRHìä+•æ—å*‡RÏ©sëvFmTĞ¨ot°²ì0¯{AdİR(Çğ§—*¿m±~³ÌÊ£®ò-špÕ¤`}\eğ—(ìİGŠNüšd|…jú¿½Ñ½\§šy8ÚvÒ§àà‰·íûcâEdSĞVJƒôğå§ø@°V±„—89ÿL+FâéZd¯\ğ!öÓO—ğ¡ŞáFÎÜûV‘%‚¿…XªÏøò¡×ò¡[V|(ò'øW/v¸›ÕXïDÅí¾©“” •Œ2ÏpÁtOigg-\ú´‚Ñv|„€ªÊK>ŞYÏ~°_P² µ£ú±™¥»3J¼,á²¼¿^eõ—µ‚<&Ö¦¹0Bûø¼¨’)ù{d¯§”¢—ØÄæÿrLW@†Ü(¢­vó2<=«£ãŞÆ ª*	ù%‰«ÇócËaR¬E_®¢.ù.^íK¼fé˜‡WJîi]š¥×Uµ7Seî^¼Úìb$¼a0Ëíñb+¿”W©ÜîÉø1˜“H7æsT@Ú/¤íöÑ¯Éû{†èDok²xxT ÇÌ!°ƒ<5ûî¢p”2ÜufWœ+²©X9é¾]S±Ë?èi`91qÄ{äIPFm_“Òh²½A©èÕğØ0RWK`šÏÑàL`9XĞnİJ¤øİ#¡µ FO´ƒË¢6cAC'UÍ
C#şÿ!z„›¨«|ë%÷£š@ŞÁ|²éº¤Öy%+:]JÌµQa´áœÍô”²ÛX9Á$éß»uÊl°>µ~3Ù6³‘j»sÂ|ØÓÇ¿7&wgØYúÂÉV™ùÊÁù;fŒ°Üq1‰³j½}»êr&Oz>Wç¢•4çš½ÎÃŞÊÜØë'±ÄYw´‰ ßÎoÁ@¶SL ¯[wš¬&-ÑÉM>íü·¸hçvèÍ^'wƒ£• 
†f3›2Vüß©•b&‘ï{¨šşèæ|‰àã¾N‡ñ¦ä,M;èW[¶©iÑgn3Gáş<ÂV#ó™Íbùİ‘ËQR:=m[µ Å‹…”‚jkX¹'Õ[€hÅ¼\(2,0Ø2Ê£ëê*¤8şC¸(Ü¶]îi½>Kåª¶ª†îZÌ®´sô!C˜*{÷¾<Tÿîı_ôX¹ük…‚„â€ğfÄŸœhûYœgÎ@£½‚a!ŒLnğÙ}—h‰t­jc×~ŞÈÀ.·SM?½—„xGø¡§H›<iD\˜cøà™ÿı;Ç±š?¿Ñ<©FôÙ¼Øa ‰|Té€eTë·¥ÏğIØ§i-/MS!àEöÍ¯{:5ä;èô¾K4%Üd áèĞ¶ÁŞæİR&)^¼†ãñ×-P9…#-èHE»(xÍû#° ¿ZC¹6RØA×ş±ŒYWI-Æ\•àª¤­î„@)ĞG¦¾üãl¦ª#"›ì¸a\´Õ§xßÅ\ú0¬Kq"Ê,–÷gÜaû[öE¨ôú$ÈO””x8–<şq5Ÿá$È5£Ç6´oÙ’ÑS½š«B’¾ØjÈŒáSAlµâC˜ô`²‚~µ†«†3S¡MmøõŸïtÒmÅ ®‚èR3$îĞ­l•[|¼š4O—DÅõM ç¯«¡¬%Şrd«=â àI}Gi½E17´?B¨?E$›®õˆBÂd×$„Ã—w•I˜H^7mÇæaùº1ù¢»O¬Ê#‚Ôİc5œU€Ù›[+Œ­ĞÃïËÙ${®NGV‡õ²,l&»	Dî„ÿôÊş	V‰eÓÿ´Ô²lU•bRhÀù2²¢™ÁÆåú¾>³½w­Ş+5bZ/ÑHƒúèâ>!º¿±÷şÆËSÏˆ?×±‡ı(WCYÄÄ1’XÚ¹$×‘Ù
‰àqQ>f&ˆÔzÜÕ©uÊ`‰=´eĞÙ(*/óö™|…@NV=b¹†‹³:1 û~:}×Ä+ÏàÁW´î6»›ó&²çòyœÉ«Ê¥-1Ì.àİÈ¹(®åÉ¤]×\ßwâ´ê[“§sÌf"‰šÿÙÁÿ3‚ÉPÈ
ğÓB…YI†0Ó|«ÃÍ(Ù¥.²f™%âŒRä¦[ã~İ9;°s3>.Ìvg]Õ%&ĞµGz#_·9‘ÇußoĞ?mù£¥D.É•gQô–/b.Ex•Œ˜s\Yâ	ÄÇ"Vš‰@‰8hĞc–û@xƒöò~v,ÒòMßƒéi¶U’ff½€9^æO)c¾úL#«©oS§´X=nØpúGøÉ©wAD5å^~ÿŒ*YÖ½g!:Mw?¶…Ó3ÀÅñ?Ày_^dR¬>ÜÑœ\íéœ[Ê[u™‘•¹™/k÷ÄeÃíØ‰Íú™vt€3Æfæª‹ˆ¤mOkÓí…®£[ıªâs]Iøæ˜®y¢|ÿT‹ïÚy”»˜7yfóT°Â~nİr•AiÅâ€'ià
¿Æº§­Ù³)Ù¸–%%: ª:6{†(-Ù§%lyŒ]\‰šD	m@õâ²…™"¹n¨65ìŠ:–Æßnå¨ŸßÑ|%Éj!çÅƒ cÈ‹y¹Hö'o¬İ(À®‡fb¬Ê}ßá›y]rÄh ˜8ø„¦¸¢š;å6AWØº™¶iBî_HŒ­)ÿ$¨fS-<Ö½ÃŠ“7NBk{(Ôs»³€Ú#,¨‹“y·`=™¨ÇĞ {î>¶	òúl·âløAÍ>æB[±Çğ¹ÆDûï”’\<°=nu?,eÕ‹ƒˆ„$Ã½glÕùY‹•NtFŒVº\Ü)xÅ²!óºx;w²²<¥.9
áş ?(ĞÎƒ^:Cï¶ÚSHj%sfàŠÎ7³‹×Ä±]îw6Kú¡tóË²ÑÀçñbÔßA	ü"?Ç<øü½r–äÍu+Ã¥:CHÄ– RäÙ0™wşÂ¿cÈ¹e¯ƒš'îË¹>kœ…ğ¹—EÃ­øJD·´:´Õ6ÑĞ‚‹È÷Ï³òÅ3ôÍ7+À0% /¼œ”°;ª>Hqlt'·*İbr&K„Ğ|ª=öıGkêŠErf¶ñ->¢È¿õ:øõÕŠH
}â È*¡Şv‹a$¿6à¼<MšıaÄ“x/ŸæÉ“ãUg±¾ö:™`cÔ“ØnJv­ĞÍ õIE\QS+ß…6éñóŒ—LŞÍ…^'ÿëe…ÁX„È3²©¡â~cëìsÚÂX~Àó9‘¸vÒJôŸo¦$—¦†K\°ğ7bmàü­ñóXÙv§˜ˆH  Fƒ=vİÃ[XÁT´¹jVœÓ\ìu\¦,¾ïÙDI-=ê`jÇ¥-Ç³.J©i±¦ër1MT,jÌ M¥ò“¢¨@1¨Xcw[u#¨+ß M—`ğ‚Åúján‰ªòQSF‰v>ƒGİfŞélÑÀQïß9+Ë–ÕCœAó)z2Š3Ú€kŒV™ìœÑ2lšø¨¹£õ³¢{ìQ_L`­’y9®CïÈ ¸±ª™ó'Y.°Pü!%X_L³q¿+o¯í%f ŸyôfÓ½«ÌĞ°Hî9}CUÛ¼+‚Ä×Ó;ƒ¦–>ZİXà»ˆo—O Ä°
:ç•%8)3@_*g¤±èÌúfò[5
pæXK‹<—®×&gWÃ˜¸°Lx@ñ¶˜.l!N­X42º>MÚñÄ×íñõ “w±³ 8 gc‘^?ñËö“oªT¿Ó‡àEçÀ«‘-w÷t]UúäcTÕÇI!NO#ŸôÄIg‹~øÔƒ Á¥_7-‹pVğŞX|¦OOLŞo»ÁƒB\­×K‡õj"ædĞ¶¾PÜ_é;¡.åÁ¼v‘b1£õÓ&Ñ¿%ª ‚§Ü-Ş¥«kBy†–Ë¦Éa Ş·¬œ¨Ç&îìMğ\ïº@|TÑ¯×„~é¼•Ğóq| ö¤C¨6N%™ËßBÒµSëWaû©@ÆSığõº¾µş«UÒXÊ†è=xşpÌøjKR…S ?ã¡èíUgì8ScLÄmí¬;<«ıïQ&XÚ$öÑí	½åÇá4½Ù_„>%´ö\ß¹÷qŸ™ ü°¶è9*ËèÆ‡;É´n«³}	«ôÏğ¢jö{á•TÈñKaš½·¾&ÙhÔw÷û§Ò@Œ‡ak/:2ş´ú5Z®x_PRÙÒyiÔƒô:lúÜ¹rV…‘úë·‘=®‰›À÷ÙÑÂ«;ó%²Aò´Íµ“Ï¡¤O5üÂ?8Yfr?Ãı ;Öb|`>‚àËØTñ6æu‹”@ZÈ%ÈvE‰¥çÒí”ù3¯£#·HGı*˜…¤ò=¯İx£-	XIdJˆ6;ağKsü+¾I‘à¾Pô°ıOY¬§U‚N0ãg^ûW7ÕÛƒÏ¾¸³XÅWRLy,{#òßDBöÔ”‡’#ì6öˆÜúô‘ğ¿ÓÑÀjÈ·¨p¼^ïAuÁà`ı]%7-ö×Øıö¹bßÍ—¯è"PU”ÄgÚÄ(´lŠßÔgo8†Jô@2ª6±ÚÌŒtOÿ‹xú©9:ÀFÙ¶ØŞXaÉq0-;Dv6YåÚj+N*–õLwAš¢(tT÷pÌİ›ÌÏúfÁ}Mií[A¢D¯YpÙÜ®Iô¾îÜ–•ş­¢!İvU2Q¶dß•òæÿÿ´¼º´©ƒŒØ†#dŞGñ·ÀÙè„€’)9ĞNÜ£ğD‡ûy1\>/›ø']d¢&Š8@.º	©€k1‡ıA:¿ß¥ü!îAŒ'áâŞb{¨.R7q(?™(TË5®FErw‚ÏìU–ªÁğØn·Z2ÆsD¥õáî÷tòx»ÍåI%Nil…P•¶u€WO³í_A‘ÿgçjÌ°1'vUTÃ\o$1-“ÓI#ãÖùÒü©VM§ÆÍíÚˆ…©qd$d¹ÊLÎD;o
—ŞĞ^ı’sÉ•åÖôYš.}€*ôÃ6©e§<'tCTæ	Ú”±¤h½Ó‘pkŠE+YòXZå—~D3~w‹–ê#2ÆÙÜşÃi~Ğ{$X:›£5"¶ ƒx2äï$scJqpîbF(<›©éÑÓ
³”·€]6
€ñqâÃY†LŞøµË³ïNCÃ«t½¶Åî%:æccàœEµ 9áÉ ËxBÛL„Q3GlÈpü–¾#l">ÊÁ¯g÷	k·9Ô,t O@s_³SøŸ¥¼ó,
±±i¢dä¡!áöØãíYˆJ˜h×yšÈŒï?È	\4ìxä,")@•Kjèm *rÃÉï\±QBˆ…²ƒi­Íœı(åfn>rÙ¢ØÈ97tpè‘Äo	ÒS	2Ç&×ÚD_3tÚ ˆ#«à—ÇU­9AaeLc³,YLqlG‘ 3gÇŠÚòÊ½·MGu]s‰0g7†]|›Éûï> Ñt²yÆöZÀ¼CÉ6°¯jn
¯Ìú:¡bŸ¾ö ¡6,û¢{Óg«Šö)\CŸ™£CèĞÖÍƒ×^ZÍ5êÈá:mq¯©B×ôj.ü¥Òè¯Õ?oÇ}%Ó±ŸJ	1ñJä®H~×uÕ¢AßÍ´¦›+c ®ÅƒsHõßcC-6K»¬›
3‘‡g¹³oÎÓßÑÖå
­{?‡µÚ…>7d£X$”‰k_Æò¯›Úšƒw€Ê¼I·&­HĞJuP,o,Á—²|uÌ90ó–ÔI8*sÒè2JyÁğh08Ãªì¥ìÆ¾$İÎëÊ¿)”ÄkªÛõß 'ËñÇC˜á{ä~ƒN+ÍÂïÒ-d„>E=çî©ë«ƒJçKìŞj>5cé•Şh“ªÉ‹á¿BéŸ¬ü-Ò1–öhçõ>óÛ!úİHL,$&skMr§oë’#€…êXÙ¥š“Ñj-Aª¡€ÚËjÀhÙ!k/œíÎïÜşÖ	ÅZ$Å~‘{"ù“†B’ù-*
À„'Jú(6-÷XÌ	!n.$ş9º¿yœşeJ)¿ø¥s¤°Ï’µbE55ë.È²ªèu’ï‘í÷}¶à@AÉã~FB5ä\uf”¶ñ+š$€*nŸŸ£¤‡TŸ'R¿ºúÕ»É¶øX¯t€E‘[$î¦È7öTw4·ã+M+6áTUyl­|ÍO’âryW^¹¸+Zò*¦ş &Nå!±¥ŒVú#ıD¡¸i¡êå#}ôA‰Û˜çÉÖ€³IgxÇK&ôû"pR•³GƒõÏt®V½Búğ~óÕi’óØáñ 7µËÍb1`EÚ]NhÊ>Õõ¸–MÛMcìÜ¥ªª>Ç '‹V‹ê”#]ÿ5g³\p!e…W ö!c?JI€O¾N»˜Åş‰hÑ¥ÌSLTÉHô¦B¬
®š»I;çä2Ì‡æŠ–Øãj€ô¢nì¥ÅkÂ…÷ªdlæf»	Y|mò¾æ@½èJ8¨…ÏY09Ïú>i—PoŠr~¿(@üfŠUWË?R4ÅØÇ²Œš–:×Ci”$f™{ı‡Ó:Şg¡±òøFU•P9İN W9•¨T'¼ò’l"ïœ©G@µkqkQ2G§AšŞŸ¾Iù¤±Œ—œ&Fİ/õ¬æI'õ	½M:C­ŠZ©©é˜ñ·©Ç†JP\M /+HÀQë“ËË‹!U¼‹”N–~ô?»8÷ëò ¯Jã¦=×6§ÏmhÕnûNİ5ùê‰çÕI·ÏÚ~ĞjDı°ÅºËš	S›_Â¾íê@ôEÎçóœzYõÕÊÌiçH
\º§ğq­ymŞê×_ j3ºxÀ¶7† ôA½`oşÍÍ~ˆ¥Tì»köèÅ	N«ÛÙIˆônğT•ï´,êùšw«ô ³¨"Ë£¶AzğìüvZQ£¨u)X’)€Ê mó—Rá È·€À¢±Ägû    YZ