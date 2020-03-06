#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="142018717"
MD5="50f4d97904c9ef142c48688df15452c7"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20744"
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
	echo Uncompressed size: 136 KB
	echo Compression: xz
	echo Date of packaging: Fri Mar  6 04:52:28 -03 2020
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
	echo OLDUSIZE=136
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
	MS_Printf "About to extract 136 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 136; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (136 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáÿPÈ] ¼}•ÀJFœÄÿ.»á_j©\./SS*-µÒ°Ä*n¿Êz5g´}IşÔN[ûNÂ›jöû¶pí_±’y"æò­s‡§óİùo6V´4iwÛ1tO±1@	Øú]ğÚ¨–’D~ö’’˜l&Ráé‚>	mÑìÏ›i¹¯ö—od8ãk‚ÿVæê eÛÀ,g$?…Ç{¥Óš8ïMåMúr¹ùWz-¾_Ëİ’i@=2¯¿{{ìaæù ¶Ãí8\'aÑ¬Wœ’?J@|òzÿJ–ã‹œè³ bi‚jûïßÅ´Âü™Î-÷\
nVÓ9e|¡uvU‹ånJÑİx-Œƒ,5ï@÷ëBœÚ¸Ğ“¸‰Í*ÉÊ	õ<TÑ{Şu¿\ :7èk¶OÔ_óıÑÎÜ‰ÖRãîÉ»½ÏL¢u&{¬±šk4•M®á»Ë÷•¬í6ŸBózM~›/*D
ïê3 äKiq*Ë`!7àøjÈ¬Âß-‘Ùı}k-8ìDäñ¤–ÊÒïcFÕ·ë¬àfŠ[b\ØZş?CQdAœ€uá,ĞÁ	Ø)–Èho¶üdã$eVkH,¬|¸>X“ìŒ±³1½0^+Ïd¯İş‰ãDJh§pÜæ/Z ğå¶3Zõ€oWê*mÏòªW\€”Vís:+”»)1²R¼Lş1ì*±ôµwkµ„À¦Øø":sñ‰×.y$à¥Z;Œ}R±6íR\DÁQX¡FÒ =UùCÏŸ@eÃÈiœ½°EöÛëÎk‰Á¢™œ%sÄÇ|çÚ­%+–¦šgá<?ÍSÔ}˜B»GÚQf£Dš ?[‰ùNĞˆpi§¨5õ’k•ÆGl4©†š3·{şõD…Ã%Å1SEòÃY¨‚YÅ¯‰Îÿ\H·Z¤ÏûæÍÆÊŞòWïŞi…B¯çÓduæé¶lEÖ²
J·PBêc/rs¸â
ˆlJ‘ÓÜN‹ğ?ˆVùbGX-ìÛ«¦ÕµbÜ‹
“ûUL€äì?@êy	àP£ğÏBÚX•ÂÆ£å«Po³¥œJJºUÛ³³Ó¬×ƒ“Õ€WONÒÌI<.îëDø4e¯TÌñŒğ-ß¿¢¤a6 ØkÊ‹rõÂ²$™fıb5¡³S5ÿ„ø3¨è¢d,N~YLÜBU s¦¸Ö59ô‹hº'm ?Šê÷,<e»%°„¬$åujö‰®Á­¨~yÄ3¤ä¥î:/ÂŸà•GËZš¿ÂÇW¼ğ½C™ÊÖl¦ÜÒm¹EŒÀT‡f)¾­è—|(…g&ìò_³_:Qç[\şs…àKÙÖ»+3ÀÏÎfàÓ}ö%ÏÜKš¶p’PÊØÌë¸f‡Æô è	‘»å¯³¤¾P–T·%ÜÌ±3Óez¬‡ïb¬Nr9:ÌMá€ŸíŞ"è?@–e‚H6—×ÕÜÂ?Š1$£›´z*ñWĞ0£9—¢´XéôKtM”Š«¿{£™ÉG|®Êßªf‚±…ÉhtgA ÓÕIŞ™iRä³ 9úéT(Š ¤x{ûÇA¦©hCéKOºÎëÈ3Ö;üCÎÌìÁ–'¶‰:ğÇú¶YO¶+³cé’ØÖ•-åìIß.$ Gº"ªœÇºE]ß.‹šû|ùÁñ®
yu5 tÜaSÂ†J@Ç-‚„ú›pzÆ˜;Êx±ï¢†7ø™¨Œêœ÷k(-Î°ù´Y‡c
Ú6%Ò?kÛÿ‹÷ÒÈ€°–ĞnßKzÉ	Ù¤©šÔË!b,Òuˆ#ÿÇˆ²Å=PÆKà¤N&šÅ§óöZkÎíÔ~n´Eü&j6ÛÄ|
®[Ü@ÏI«Ï$0 6Iiê·ÇÙ\‡nXMÀnı-èãeµ½Ï¡ß÷0U@!¶æÙtàë¨ÇÅ‘Pã	„_YæR_G(Ùëœˆh$S‡YQg˜–¢^ÂTKÃRfLá$°É^º»g*lm>ÀF rb¯âêEsø$7V®ˆ/Õ÷KÌİéìA›Jõçıç`s¼8b*'xUÆwl.ƒŞ¼&—Àÿ­äÖÖ1ùi×‘¨Œ¼œ§&qDil.ğèŞqF’›é^lïdx À¯^µ2û‡2œl,±ÿ8İ¸^ö¦_Ø¶b©<éÙHjÁ´ìÔ0¨RÖ¨ÀÓçÂx:LZ¹X¹³NhZô½'*M—X
ÍÔĞMµ\î/ûØx:à ¡qËö%ÕÌv dÊkqyUùúlÿ8ÚŞı'ÿ<ëf÷˜í¬³c._ù÷c!L3Ä•¾Ú±—Ië¨ŸqFEŞÔ¸Rcâx¦¥0´*µ¹«âfpI=Æ:‰ñİ[ÇC*ftç´—ğé#9ÀLl²NÃ_û …ZpªC`šãè¦…«zÊ¾Q^¢£ìïH£ß¡x’J ¿*¤›û¥H³é9«'şÉ‡°;ÊA;@ÿÔ5zßŒÕ‚¤ÿğş<˜ÉÎÿÖƒmøxøê6{«kbšÅTºÆ{¸<JŠ=[Íß>Ôr—ûî Ù¹Å©VÖ‚'­¼_¸&BéyúŞé˜/õÂó ˜ÁÏ$¿íü£ş¿ç ´È1iã»jÆ&Á…“!V†üd¦ßõU¦+Ìõ¦é¨Çn4†ìTu˜zŸÆív~b„“Z/çEù),´}ÔkF2Š3N3rGß|$Å ˜‰¬<[P<)†‹™¾Mçä9p>í”lÂ`ÍI&>=õÎÏ«@‚Œ¸gÃ°bO5[Àà4Ù) 	» EbFµ…Å$ÒÈi¹ú£M ±Õïn1ËXÂI7Éé÷˜Æşƒª1\QD=ï@SKö3ğ¼ÉÂLÅÓ-­³õo–š‰5,28ÍL|ÛïÅ¾W3µ	'¦UŠ£Öõe£ÊZV€òµwNe½ñ—-ğ··°j0òÈá%öİGrs‚K.:EÒÔÚ·®èD#QÃùb³¤8¿K7càL2®w²ß„‹¤·NÛ{,Ë—=#’{­¯2`/á*ÂÜ÷ÌÔÙ,ò|N1T›a~ˆ*ıO¬p…òÒƒùı2û–€n(µìé;1ìÏ%Ûo{pH€UYMU´È¯¦Aç"ê‘¹•‹.Yß¼Ybıìì±­¯-‚õı÷'Ï†r}Æ®³t›"ØsˆÁ’@Ûo,$&JıpwÎ±,Œ”6^ˆµ˜pr¢
_-ïş ëm%¬oĞœ™µZxùùÆà2Š™P!·©1wå8XÉ[d+àVs3ŞªŒ!°†$R]3QQ©bN¨v„sàYªNêúmİáY©eI’ÎgAè#]øuÀŸwkLìë/­Ó˜²ˆ;íë—+å~„úSYı@›rÈŸj[Ãé
P‘åñ˜?‚xy½‘†èëï–·¯•";yš5,%]ÑDè5Î¢;Oï]¶Î•ÊEŠ¶"å§Ë÷%¥Æö^ÖDËL9k”Î`Îæ'_<„˜6.“ÑáĞĞm|¹v½‚–U„:¹ü+ l´® ÅEÄt•s|Œ¦ÈæÓ»u'6$ËRØ|ÄÏ™×şvmaŠ˜>3•e¦(7µÍWsÆH©è]êN˜6É¨XÉ£afñÔ>!hÖ—¤AoŒªÜxR1dLè˜‡,>&ıeÌk1í¶ƒ¢W'ÔÁMÎ-‹è«6W* ,¹VŞøûÖ>œàÁ¹|uØæ˜Ë,ú<Hÿ }+¸¹â¦Eœ¼sÆµîß Í¤¡šy“R3²ç³µø‹'§äëWu5éŸŠÜ&UqV‘­D y¾Û„ãH3&U¹ıÍÉÒ„Çcaü%Jw½nj‹“ßì(‚%ú)9İ>ào6kçCz–Rœ4H×jŒ%JÙâ*Eƒ­ÜUş\\‘lrÖ˜À73YğE¡Mg¡‡-“³éTB r]&¬JO¡”ÍUu[´¤E8mãàúH=¤TeÎ,‚œ»‘Šıã«ÊZ(góêÜC«ò†W×$¥áúóØ·O-`Ìš#ø0rI¬İ¶»¼µ­TdºĞëSI=píZU8Ï2b+Hc¿Áì”9¼ğÎ¤Ÿk@õy}_Ck>/ê*2'ĞÁ=•†/Š 'İJKPßMß k‰T
†`E¬^ƒª@Ù$çÜÀ‹ÊFp§½.zr&5ó{ˆÆÈrª‘¯>èB¦ªhucÆ3v(1¤ ãÇ-n]éöŞk©ıÜ”ğ>Y¨öF9Ô°qyv‰Ğéò´æ È›su<O‘¦Ü¢‰ö‹iíoèÃ°ÿ8c+ïŠhk`\#Pa`à}dª<Øßbõıã”8ípÜ6Şvş¶•uˆ—a„p•‹1ÅİƒŞÓ¶50Íd³½¶	™6åW”Yêg}M–¥3ü‡R”-FK–KÑ–˜À'§Íû-R…îQe2.±Ê!ÑXÙ;©Æ2¶.ˆüæ•(BîÈòÂğ–íW«~)Ö@n„Ñ‰¯zÜ »Ù¹ÙSÒıkìşó¡ Z·¡Ô*”k‰ÖûPî>´“˜ğ×wˆUnI¹Tt\:ªÃ9’Õ³ ü™S`nçÎrYı¿gP‹Á„&Ï)mÓ¥ûPŠ›S
…]l/ÿ‰„Â=•`lcŠåúZŠÈ·“~"çÄœ"Ì¤Ëòèf¦û;Üo™7a óÃ—"ØéÖWïGÜsÿã”ø˜€8›58ñ­˜|i)ô\ãšÎ
:<iIsb-¯¨×üs…æÁ£æ	SFÌê©~{SªÕ#V¥ÂUŸTğ‹ùm®B‰MÀ€©8q4²ò¬ı„ˆk±Ø¬^XOe¯ÌìñßA¿~	u©.S å’UB^ìåù4ßDhFÅÔ,˜?[IWË2ƒ8ıs¥êbêCÕƒƒ\¬.y³’ã[ÃĞ£W)?ÈÈgWuş"_¹Ä‘Ù¡§‚ÊÓäTEw’Ó/æ¹eÊuk(ˆ÷±u$$8hÑcdyÛîé7öË`ÉhlÊn¡n@™÷İtyãÁÂÕuÒÀWÿ>Z¼Òz‡"^ºr†3ÈÙ–	g<üUœÛ™·™Õ?ÏœRÒÄñpâRZlË%L¡•ûˆ*–„u™/ĞnKo“wõÅøs¾Wô'›©%aImíî*]·KP©Ñ§ñ~³ëš{»rÊÏÑ9oÏÛ}$x†œ:ÑÄ0m9HE7¾à0W¡=çvÎ¬Ï^_µÍ8I˜&F½ÑtåáÔ
7í‡kR~6´:Ñ~²›®÷ï+ÑÚ¯Pö~#©~>`«yåğ«ò¯øõÇ{/ê]åH’s®Eo–Õ Æd²—ÚÂÕ(¿‚iĞ'`:6ïÉ
D ±PÔ‘_" î©x”&5ú0Ú*%',*6òğD%&aUh¿bZĞ×Hè•	L–EJ	¤H±m8Èü% ØĞ”vM”1)OêÍ*?åQâã’¿¦Î)°úÓe=¨°ˆ+ãtO§e¿÷´¥Ë*ÌŞ|T9!™l–_&‡ÁGÑÏ„MÚÈOvh`á¨0rÉ¢³(öœ˜Óf«Š5Ğ~wA?=k*İŸIJ¯rÁ“gYÍì Al‚Ú>œú½ñ¢Ãr(ÙÖVóßìh]{U¢B şiı§ƒPñıc]N•Ô è«yåÄuxDé ŸÊ“ç]åß_lõÌÖş%éùÍ®µ*‡K—BM7s}Wf†,üĞ 0ÆMd‚7ŞÑíŒA]B’ùópÇÉ0sGù­­”ÎDs8ÑaTTG;B”âÊ|â_Vµß…ÍÓl¬×9xo	lÜõm	¬Û3'¬Ó|Åg»{Øñ-ß£šºÓë8ÖOI5ĞóË˜üí–8™ÌWP8.U²ø}ù¡Ù¢‚ÂÕçğ"ıQñ%Ã¶Î$Osï˜xV1·”ÖúÄIŠÒ}t(t1‹·ôÆI´dpúÆ@¦±™ß@µ?4v¶à´oÂoD-”8•Ví›^¥t²Ò8±0‚AxúlÃÜò¢¦¿—3¼!q\l%F<¢3stÇhÿƒ6öaĞéEOíò
ìS_ìM…dĞëõè²i{­[^¶ZÓyßY+X³B+CÅØ"›İ¤g£z¨úµDpJèNÅÇ•:YÒ}ı}y]	¯şt	—œ%»A˜çSdìEúKûëSCš¯îZ‚vüÀ{lµá&úÖ°€ÜFŒ„ôFÿiG÷ÉûĞû±“G«	Bvg”mõµ# N¬kIk÷…p|c7«ÊÏJøSú‘£ ?w ï–¬e¸øf‚G¦Üâ9bõ\úPWˆ|Añ{>pÏÄ¡'«’q©ò†õ(øc†¯¡Iõ!+>§Ô@+qO+kÒU7±ñ­ø[ëq$‰¢öğÚs»ÏÖarÇ ?ò43:ãr”a„¨
+;F&fÎÀp/İŒpT»àÅUq•)6ÌoC(ßaí~ÿÅÏ„é±ı§Æà[yK{Ù}äƒ¥5J§Ê>”¥?ìåëÿÑân/´š—œÅÙ$¬Õ+`fLªÅö :u˜Ûç/çšò9têÁªmª ÒÆ-2ÏL?§N	:Š?n6\mrSfpì& ¤1²ŞäğœVÃĞø(8›Ïâ³]eî¢"†)ó7Lu¼2Ö{´×=l©{y”üno3êrn›ÖÒ2VŞÎƒáğ¿s•¼ŞÓ#N„«¬D'ÑY±§_t³¢ÆÚåZHpI°Ï
€ÚüaRjT(„6À¼/™ÓKˆñã¥cÒÊ8]†n¶Ãf’·,}Y	,ÕµÓ]j¢îlƒ¼«û¯“¼ËŸøŸò`ÄÎ$³qäJíÎ1Jº=¼"·î÷Ÿtàöº¹×”x©D…¼!L'H,Ğv»r„×Òİ4ëtLeéÿôÆºà;!o¼”]µ˜J:×ÈrÅ~aq–Ò‰@u20VÎL*˜ÂºDÒk£{ù|&éG{?Ôq†%¦É1Ï`_bÈlÏGƒU •4Ó/öH¢ÄÁµ³]§	rIµ´Î(‘\z~!’½áùİb“Ğ!êÌ°¢DëÿºZ"HÍäÑU%Åb”bq$ŒˆÖê”(N  v"×<÷Ô?²†Èw	JÊ“Ti¾Õà¹j”Ò‘,Ó×q*åø ©Ï8\Ò°Ãâ¸ıüiÒ‘yH!©¯E%SÔäÅ=úÂ²œ½DĞHë]‰†6Go8Bù¹Î[œÔšµ¾÷¿Ù¼?ÄrJnÚá~SI’[) ø—`6#Cè½ñ°IÜLAÂ¶ŠB\ã¹$·Ûn»ºßQá¤“'Ü¸¢súéçÕo•[?İÒÅ™™óŒ|Ñ~ë4:ÎËyÊn“ûù­”Ì·« a¥qP](¨ˆxœˆ'$%[‡Œ² ^?SsÃ•Q‘]Rè¨ 'áÌç÷Ôê¨—‡­\ÚßMJ8q~ª‡y~cÏ !–ãÎ»}ìÀG2í¼İù±uä:MZ©b‰µœ}¤QÊíS†f‰…@’êH*É2>Øä;÷Æ¦³ä³’¢@¿±ï—‰ÌÖqÑC?_ı""îsÛhË±h¨¢Ñºgò1¼ƒ1–(gÿúùke…`,ğxˆÔëD3ôş­ã)·ôô•ğÉ!ª<ÏaÆ~Ë}’Ë½å
¨r!K”†5¶¾ÚÙüÖÈõ,jQ¢ÊRüU4rVCÕB^H¹pQyztÀÒÂSx&%…/À‚¾ÂŸµIò“ûØSQÿi}"U¦ŒÜ‰VóY{Pã…
N·´Dh	Íu1©3ùvXZ#—%¬Æ]7á½àaçq9€¾mÁ_Œ¨qK§·½ª¬ U‡`›¨^†1RœÉ.HV0.ûJjÌ¿‰Q#ÕêaÀrÛ2”Ÿ½ˆ"ÛÈ½Ç3ÜägÆ«7;ı·b úlÎ·ë/,m†8P©å_ÌdÏ”z%¨3¾ŞT%S=9RûïYÌä#"0¾µaáçc•§²§Q n&¾”Î’½ì¯X5@y_Úé|šÔG{9’zàl4-ş¥§0ËY\±f~®nì#‡ˆ4(ÔŠ³k5sPßÁjq–ı•0èr‚£*@Û`Û•ïÖ$QŸPPDnñk¦áë…({¼à¿„!°æ‹pXÜüùF,è×<æ(b·¼^*¡é¦n€UğÃ*’^æ1k«“»å:ûjí9ğ	åX§~ô”øxÎ6ğ¿‰)G!åÂÑ¢˜S÷{‚ì@,}Tfª½ê÷PÖŒçXç#}È*Ö’ìUp­> Æí™ô-%ãÈ”p¿Ç>'lĞMh,f¦ï ª¶×‰‚¶­Ç·×jùÔìºK¤g¦aè\õ ZèL¢K’;´ …+‡Å¹\ãÛ‘²£k)Ç;m–¯‰À>QPó\¿‰Íˆ@º7k<¤K;›R‡Ù¼?½JŠ„ÁÒB.å¾QË'zÑ+òèßpÄm~ì´gFÇ.ñÔì„ßéKÑ‰ÅrÊH±Ì[}ØlÃ×8šæ(TO¼ıúGXU+¯2ë‚xXEW”Y[ªÚŞÏ?‚%…[\\ˆD½ÙÉñ‡'<ñÑëıÊ¤ß]N„™¬äæ¦‰v Œuá±”Wk³©q¤®ÁDƒyÆıåc6êu¼”¢ËXãC ÷U\â/yÜvä¢º(¤T/qó÷²Ñ/®Ù¦ú½>›àıAP‹óÉ{s[ˆLéÂaŠğhn»º-i˜—ÜH)‡$Æ7 &‘Óè|êËÎÊ1J±¿í]ÏóØœ‰m|4Ã(6áúU˜·ñ:—Õ´(Ø·‰Üªbu5Ë˜Àç§csÃİO‘¸İ`ˆ{\òè­öÚì›CñbÆ}×òĞ’ö9ÓÀ ÷ÄøV&ÃJ›V¹oqÙ‘Jf«vk?Xìÿèª#j(LbÙœ8¶Üµ…ğE‚¢6±ôÎ5÷ßxá¤.ïÒDm«MeKT¢6ÿüİ^3oĞéTD†ğh²¨«ÈY?tú-e”2Wváo°@uE„É%W^=PÊ~æO5†«ƒcbX€Ö‰«IöGT
›p‹æ!£'Ñ}İbB¨s<K'õ(
X3ê”TáEZi‚„j¬ô‡’ï©$~Ô²…sÊ¥j«L”±í$e@$énÑnv¯Ú‡=äğLPŸ'zÈb=¤£Àc®MíéÃİp cÓÚÌÃrR€`,nÜY`e(â¾ïä'(ï’4*}–QëHEX•¦ó©¥ót.´wJ²v¿0ımˆ’b1…`L^-¾ràÑ¦Â#Çµp°±š²;YÿØ,›o]Õ6Ş§ş«­£]6ÎÍD§I<×™x×=ìè»é‹¼_¢bŒF™zÉ2á–#bÄ„Bª%åÊÓP‰œDqÃYãŒ·Ï¥$”Kã•×à²òèâ%vgeUm]¶LeLH²™kp5çF?ıM5h­ˆüº¿Óù‚Sèdúœª!Ç/¢Y»×!çØ¬$ÇVC:»×"LwüPÇ*¬@Õb~ûj<—Îß²êÔÄŸtÙŸZ	c8/&ÒÒ+ÿCv	XäŒoœo>ÒFè!\›iç€¦H×•1X»[¦ GŞ,o5ê?½.èFìÉ‡êÌğF[%¼À;y&?;Ñš4~'¦¨¢Ÿ5u^\nÜÊ8°¶a£™f¢<I!ùk~Ãy¼é/ôo÷8*ëMB`Ä)ôªõÿÈ˜U¬û¿	l¤_¶le2Õ>k»Ç“ºê›î		îà¼û™40É;Ô=O+Òça,˜êÃÕbóÀÊûqÈqKÌD÷gĞ–g¥xÍ‹¨i–å·'_ÎôİîDƒYi#T(%¹î«æú¯m7Ô¥CG$¹–s-¬/Õ¥c¹ÿxOUåV#À í±úk0*xú~¸µ1ºˆ„Tiöğî¹¥¦üÑœº×Õ”e˜0oÃ]5:úA¿¡%Z¨Ë–Œ­¡±¸¡S¥¢Ğİ…ìğ¨QÀ°Ø£ÅiâO¨E;m¼iÈŠÂz‰ÔJ©ÄºD
YÛÄã&4Än¾2’øä+S¾~‚IĞ;Š5É®l,ÎÎ½»«İßE¯²ãé	8ËdÅ4åò¯Ã®OwUğ™ÎwS³ÓÉ@ñgNÒ6O¹sš#w[oÙP¦S;©TrĞè§Ñ0ßÕ1câ„¹›œu}Øı.ÊˆOnuM¼ÍŞ€ê/nĞD #è‡?ævú™Ó,Úd½íµ[?2WrøïªFÖ‘-cÜhğˆqÕiSex+6ş]_xnFXïJsÏî'0paŒïQzÆU&P|†èØÈGB2‹.ò¯¶z˜Ï¢ït•î@¤²/e?…ú>¢™‡€‚Ìp°›œ£y¨èåšo}¸#øxğ|¥¸bò`Ær“Ò[€oUq\#Ë9óá`DLÎ‚7#õÂ»ñØ#N¦¿h&©ò¤K“š¢&ÓFu‡¹p//İëL a…µë<òìÌ1Z÷dÙ{íòP¥ÂNÇğ¯ÒœVmb?›6qĞû‹+µğ™Z³(R`û±¥zõı/YşÊw=1{}1ıƒ»RÕNDŠ£e>nòÎÊü¼¶‘ö•öOñ2pàK™?õÿ4Àk¹ÊMİu”ŠY5hì[î#vŠ¹VÑ€­¿Ñ˜J•¢Z¨[@? P~ï]«aDCRÀé` -»MëÃÆ¦%|-ÖGm2-h³ãÂnÅt;X’Õ¥OÓ•S¢³Ï(QÃº¼úÁ¼K\†¶zÖ§òrãq_†ŸñÎì?i2S«Ğ4ÕãÎ•Û(^*3QµG#¼-4%®¹å–“Èm'V¡E
w÷@a–p¼psCYãíAüo÷R®²âş¢dm˜êıÛEiPxÖ%7w$ÄĞ »ì²§3ô«†i®,·ZÒ!îD±@€P±º;í¶`ÅZû¹J;}æU#Èœtçå_Â+.˜ÜÆ:'µøùp±ëòŸ~H¶×qjÙpÄ t0ø…$ô/q×{va|?M¹;gŒÙÛÃiypû‚#o#§»‰ˆÔçQ<Ã âŠÒ¥‘:ÁÏVj>%ÜÁñ’÷±£°Á/h“E+ÿ¢HWø24É±LŞj.ü^éÜ0"È³¦7×A7¤™ùõÉ÷Ij­=zÜëÙ_F÷™¹¤àì†YJj0;Àë2¬¹K6½²[»6:ƒª«¶ÆàW8¿?„wœİáLÚ¤f*@õSWGdQ³N?Õ’ıÛªÏœ¯Ù¤IXÌ#¡œGuØ‡ Ú×B6ª“øŞùø€Æ—?[Iè†uÉ®œ<ºîìSÅR§às´İƒ74Ñ^øŸÒ75‚°Ğ*oV,¨È,ó?‚É
5¨x×@âI‡‰C°~>éÙ×U[©›RNB¥<ÚUøÛ›²:„…—6a‰‘Ö©™ÄòË2Œm¿ }ŠIQ´ó‡Z(>ebmÈ•€|èâ.ÜÇ+;±ë[?^ÍÌW"Æµ$@gµ§Ï~òB²b{W-56íP24}XX"Ü,~îx”Œo`r«å,èVÍ-H0Ì®»jAH”É©Ócñ–½Õ=ˆç%•8ô+#AõIÀ^æĞÑ«?d¥io”¾4Â{Ù}7ÏñŒ‚øv4árvÈÈ•h]hà¼úc_‚,ĞİÔº7„©±md|Ê©”Ş¥ØUğüOOZ£ÒLCæKÅicUÍ*_Í’(†_‚ ‹¤p¿ÃÒ‚=ŸÖ%3Z]"oû–ÖŠ/FqúéÄ)‹n¬àŞ‘tõØz[ïçõ0FÉ´GAÈùõÉ¯Ëí.%pÿì0XX›‡»|Ô»ï±óv¯–v=š'ªsÌ&L²â‰ÜG‰¨ìjYÑ?¶&rÑÀ¾¦I‚ƒ
ƒYµ’ØRñã`$BléÈä9Ú8…a˜ü@ÍF®ãÜ¿»5ª×(-/š›¡ÒBâÂ e-Ï÷òí©Kö[¥tÂFÄB‚kKº˜éæ0»/£q«ßÃle:îÉõk•N3Î*¯ªâsgº_U˜+?e”İ8¶[u¯bÉ2Æş¦sVÊŒ	úÌZŒ¯¢	~_9sf0DösöÔüxuäÔ´àå÷¤—?|0§~_ş(s;`û§¿O@÷Ãí}7AÆÖ{ â+–¸¾U@à¯§õeîÏåAßK²o÷„µæ:w`B	4Fr.Ág¬u>ƒ\²ü–$l}vaÆ:ÅÅà"×¥ñ. .@îß¯r¾o²ÖNq vâ…¿f—<™ÌùH£TL©pû…J¦Æ…q¤ÌÓ%Ã~K¢´ŞòÍÏélÂ¬ŠáD;xŞDv:vƒY¦›,Qd¨á\ŒpyZØ{Ct’C;1Nãküº2<5ò#Z°(K~¥òq1“ßŠ.ugig¸*ôÅ4höó0šWòm)ˆºÃ"ıIÛcsµ‡97¯ÛtW·Í‘äáeU¾Ï¸7Y‹–¯šË7Ì«÷Á,‹»øßòyŒn1„h´Uõ+Lƒ¯@\%ÇO¯åü 9  ­Ø/X¤M².+<¤Ùm÷µ!üÔK"óÙ¢d³ù“3c‘¯ Ğúr(zE“sÓ¿<¦æ;œMkV);®Cÿ@F”nOÒŸF
EnÖÃZÉ°6À·öGvMÇŸ!6BX‡c|?äŞJ…Ğ,O= :Z@B>cFhÖÇ§àËö×ÈöN€8-Ñ(ö¿6<}ßl?ğBíSı—U|>€’Ş”*‚AiÊ¸İ?…O(ZÜ{şgËÛD+]¢½JP€ q“c(1L<çwÓõTÛ)7Úõ`TË?Ht¬¸C¢R¸Pò~â¡°pìL×LäøgóGuğ?
å%áµ¼ı„ºSY<öõü²LÛ,·îÛş¶„Æk~Ö&N 5RŒ6ê„CdUÈË;ÙÌû–áIëİ¿ )‘¹”9f‰6QÙª¸{{‰Ë·mòÇˆæQ?zó3µî|Ø|4Œ–#iı„uõi—™„I%A3E7Ğ<2ÔMÎ¾ÁâÃèaˆ­åßhèX«q[øk 2P±_·ıêñö®d¹‘7“:¾_YUÇN$3§ÿ¼t|AR¿nõ¯a­^E§¿íÄàv8;[a©–lë›ÈäÅ»2ïŸ‡Í¼%êñÎbt~CRøîœÌşÎu¿OZ–“2b±
ò^Úgİtn­ƒ,O³È3XÙf¨Şº§ºì¾Å¹­<d°b	¥ğ*(îB!NHãEÈ] 9@7é“ˆªzä*ß¥´µ2@á«0Ó²l¥§°CÀqoèîÔH¡¬áX"ıcó¬¸ÉkT$ø‰ñ;gåvÙRZ÷ ‘…¦±í£Öİ’WõÚ8ĞˆæüMÀ ÌZ‹eÇ[*^Ò|"…a¢-Kå‘\aXñîˆí$?\e_ö’Í4àFwäƒa^EÏîM¸í¾8R©èüØM`+_ˆ3›±1”ö¦ÆÓıœX!èáïëa­–†npÑÈ@9Ê,d_@zı$E<åvT*`«Í‹ê™7OWáïÒú"<{Z¿o”ó¬Ë…y
¶.ÀÄ¼jjø­õ!Øg8à‘áN›6Û’nôi½½¹€d»5>‚X¡È*8bÏëËå¿j.Õ¸I85Ç¥ü X nXO°”~fÕ–É
L˜Í‹.™GDÓ}ÆHùñf4·×#wÇª[(§%+÷øå]®º< Ikd#èØ­(o\FßéQ1H5Ò]©ğâ\x»NsGaï”D×mÖ-aĞ$w2\b@\şA¤è†kû¥0|×6aÿFS&·ƒàï–¾-ÛÑ``Fî®u„Ş08(ËZ”æW&‡Ÿ»zğ¥x›ŠŞ|7ôXqì3ÔLWáæ‡Ò.nC94?»—sÁ1˜$I7kÂ[íwM&QëAÄÅ±vJÎëvãÃuğó[‰6œ“¼@â¨jòáÄîƒ•Øù6vrª„”l“ÙÈOö»¼î7Ü÷tƒÃ^Ìeó'\ğšHt(EÃ9Y“™Cb”ó…¦‚¤Zj;ÚÃeu_Û}S¿İ"-ÕGµ‘¸´ˆƒ…‰¥y¹b ¥#õYLH²©òØÀ,mjÍ/lA½óá£–›½Nªmºúè‡A¦‚÷–58xÓcJÌn{

Û#9Ã	±ï
l&.°ô<ãqlfÄ¯ €G²]†¾ÊLcÑh¢ÿÉøæaŒX~›E-‹0OômBÕËĞWwÎ§[xÛ M5ÌÕlØï5³É¯YY?ñ>„rBzí
L‘û÷x~Gö’¡>û‚n ¿~u«dÒúÜ˜'à·yÚæb×V²J²Óøà!*qhzê±şŸ>NÉóCCÔñ£‡|	 ÌŞo,ºˆ—ÆBYY*Âş ŸgUQ¸|lñïG!«Aşäc^:%ÓSòxS¶'wåñ-ÿ‘ıô4l„ZY¡Ì{y˜›6 íÈV^¨N&¹$w*	RÎyÛIdø„ákçÀ`³dB“¸]«WxÈĞ1v…«Â1ç¯á„BÛVõÀ©õ<µyz<p@©ŸIŠ$ÀraÏ/LL
¸)Ê­,E0eÂ0ÌCM/ÇµMÒf¿GG—;ÁP¿0–¦>b—$Ü®» ò?¡Ï3\!¬ÂÚxn¾³WŸ×ç±¿€GÃŸ’ü„ÁGÚ°N´ò|Š«–zëŞ@ØØÑòkëüÜLÜ/D-&»HI¡¶™şİyß$—A{^t^¦ñ<YŠeÙ„#òu±ù·i™D­	`=ÁÕVKÒ¿·{@À_D•d¥Š÷ pĞt……J˜w·9”i‚UòX_…ş®¤ƒş‘¬~ÅzÉqâ­
À•ØÎ`ñícÄŸSfş; ¾±4­ÀR¥ŞwWÒ90Ñ&<ˆø“MH’èç[ ÌåÆVsZIc3Ğ‹Ê÷S3„¥§Ú9.e··[¯N—‰u)§ßQŸpî¯eÏâg—“ê²¿ÕK z1wä‘3FúÙÆ¨0n2ËE©—1øÙ5ğR/Ó’–	¸åä sÓ¥R) ìXø´*%ôÙ@ aFäès×}@;U§÷Ì-¦å(²;`¯ ¯MMgC‚±Ha/äúÛ¡ÿ"çM¢	!oa»È>;O»'cBb¢ Q°jDí ê*Ÿ`KN,¹2J}›„lØ¦í¼‡?Ä]Ï´…J–|.v‘æBÈ=NQw™îŒÚÔ7½±ÕuÛh˜[¬'ô4–Ö¦¦ãÇüšÔa	a—‡a™\µ©{#‡Ï¨jÿË†IË2štÌ6í`Gnà JJ©¿6ûìcÇ‡]Î
'“Œ… æJ	 ö3bM{ÈñßÔ³AAtPkÎÎJ©|¨V01œî÷H|„•sĞ/ôŠ«'¢u÷¶4±šO§4+•£‘‰—Ş»ÖNÔşÉ‰à)E]À+¸Óí¾°K¾v[+Ê­òSıåÖ ‰å`¸å2ûÔ9¿½é•îŒãö<'Và!C‡ó9Ğó¥¸³; *ALhŸ#SûGoÔÏ”ósvgË/ğyI)ò}‰øÛ½½‹ú›¥ÑÙcÅ®­’¿2:Ÿ²_rj}êa˜l¼1Zür>A¾¾8¼oI)°.şc»«x;koÒ4Y9ŠÉ)YEû¹¶›×a~qsõ®‚>Qš²Ûu†İ§[õQU|¥½b¦¯ï^Ñ°ï2Ètô]Üjqóã–ZÔA»<´*ÖXİ}!·LaÓ
ñyÏ¬æè”¦t#>#ZÑ÷Šs|¨¥’Ä{›ß+\GuÏ÷ X‘ÜùµzÇâZ±Ãµ÷£špZ¹m~§n›ÍP/âãù‡Èt÷6aü®9ç¬ûR„l6ìH¡qÛéLÍ:)ØG×PÜ´]gÕèØÏŠ+&›+Î°<^»„ª™MÌ¹ÑTŞòÒ<* =­©òC0ÎäğÜ‰NŠ°Ú0Ÿ]h:BYÚ_¥‚Ô®LïN¡a=6¨|DëFÑúD?Jè@¬îwû}ƒgfC_Ûàòf$˜#ææ‰‡ú*ŠgxksE’´æî(ŞG9û'c!¾ô®š€CDâ0¡Cù æRôvcÄ$kˆ‰¯ˆ48[ö¥CâqZûÎ]îéer‘IDIó1³;IV¥Æ%fÊÊŸÒY4÷tŸ-»&7“'ÏÊ
ÏÂÑ”¥=6}5åÏ•_a `Åcàˆu0QıÖ¢d_Ù
$pm=½*‡[õ zÑ°Ê¬t—r3"pç“9Â«õ÷dm×Š"~s¨ÑÂû/«ŠVŞ'!¦ìíd­³‰	ñ8çßïF©E·ZêS®¤Óø½a³L–©ú£ÔeCD¹µJ+©¹p¿½DMñÎ(©! Xº4}Gy·7—¿İ!‡GşÄ¶9~W1ÅÂrRĞìøªíÀ6Ï¾~fŸ#ä2B­I@×oºşè-lŠæM½˜˜ÜcÔáşşì‰6Gô­¢¤,WQÆ\ìšp‚:€hˆ5®;G¼XïôT«Á¦	æÛw»™ŒŸ*}sØZ™)u¢›³RG:aêRbÜáÿëCëDf+€Ûª¿27µ¬Á?1çãÓ YBĞğëÈH/T¢y%ÃÅ&ï:)½î¾ÿ“Æ“"C‰ü1ü…çš°6ØtHƒÑÊº yÌô|èãN˜©YtœmlqTÓö€
yH¾tòÁÇG†â_¨Ë~u.3àˆ®ÂÚ÷.7ZĞƒƒCQdÜxÀûµZBf`*‘Ütóˆ§6ËĞ é¡®#xÜ_—-È)„ôwß¿ÄİQeHQ›pm>I~â+o t‘‘Ç}’ıc5e[¹`ã”Ùƒ¤ô)Äf‡ÒûøØë'TyL¼Ï<½†,L{±TÌI>kV4Ê_Éİklàa
3Ï¿9sÏB"È"®‡¿â&o•İ€Œ¤Ñó‹{öG*BĞ¨ç‰DØš‹o@•fÏØâ˜ŞÌÓï˜¾Œß~Xq¼?ZÆÁcÍâKm ş©ˆ–Ky[(¼Y¡0…iBğZ½Ëfˆ¢î[âZ——’Gl½hÛÊuÛË¥I– ße¼S¶ÍvÌ~yı“Ş{æÊz3n}©´ÎÆ„Q(=Rv™ñÖÎ¤ƒ;bQéTõA*Úfs}€ Xíf_³|¹“|Øùê¦H•U4GÙ€©z2åŞ)‡Ä›ö$ÖÍ°]×>Dg)-R5Ş\¢¸Şt¸D¨ŠrêÖÊ>bdKş¸?Sæï5¡İjá0¬QÚ£&ÿ\¼€eÏ+€`1CLÅm÷åú‚}æËA»`Qßvêe0G°wŞÁ ,—ÏšÚs¡ş³F“3Â§;rè¿—`™€Û\n§EÓ#ã%‚Q{O"K#`£ìKìµ8ö«Ó?q>¸ğûWºL…Wljƒ³Ek)¾¶Oó{[WşÃäsùÙ¶^ù)uµ£ÚFèÉèQÊ!ÈÂHR7lø*æñ7·®ËœÖzÈ1ŒcW&ãà\ØÊ+¨4Mn2K_ÎÂgK¯]~x0aö–ÇËÓõ£˜s”°aùkä•]²à	¬2¹6‰RpŠŒ]D&I—f~ˆ£¸¯íC‚”ŠDiı«yC:
üÁ¡?X+¦•C*÷/÷OöåNçÆ—hš&SKå0üÅŞõõ¾7²ÆàhŠ.Fæ#ç0`zw}¹
½š²%BIı)£lı€+ßv©+;4–°ÃÂYú=,–ÏqõôÀYGt>uzùqöpvíŒ'‘y›„ôzœè$â,˜ñ¢Ùp±I•y»ÉìdÃXÍ·î×Ç7à–¼­èõ¨×ß'LrÂàÒ(İv0\ÒqYN=KÚ<`˜,ş¥q8–4m(/MlœÌÈó|rã|ğ²ßùnİüQô7‹ÀĞu,>á°Cù//MrÉ¹<,8Ù°×••¹ú1ï˜lPÓ¡xeÖÂ†Ÿ§Æ¨…F¯ÆœçRO7XZ`ÔT>ÅÜtFmİ7×eŒ$^éÉäµ)<6ñ­_~Àè“¯Æ„1šZ©v˜òá 8º_µ»ğ­÷å´»ÊÉV¦GkÔ˜€	ë{Öı Â+ôÌ¡ê[_Ğ!Œ³‰íñVvÖÚÚ(‹'¼ª­SSÆë„xrö¯ÄlèÎáı©úä:^Nñy-4¿9C±x6xíT¹dí¼6vw‹%v@<×Bmûàÿík®ÒeR úeÌuŠ-F&
Àf.­ÚûySdÂşC8²Ñ€åîËËHŒ›Ç:bmÌm·º^§d×Û‹jÀË÷Õ£b{ÆN¬RDeuÎ”PU{‘àĞş_XG¾Ô³­7BYï'r¡5Çõ´±X´Ùs
|3Å¥’W_Ä§HFƒ½Õ÷Tnô7×ÌµêÔ—„Ï(^üK«åv†ZaØQJ}ØçÓi.dØşeâ‘rÛÇ®Ç-ˆ ãXæ_ñÂ'H„g8¶·À—èH±%R5?‡«Ô«mÑ‰/åP#ç‘.2çd1=÷Y3/L%Ï²ì˜}~)¿$^ Cçbu-¥qs4·ªHÂY·GóŸzš¼A¦·¾~ d¨é¢x5¿S*^,§0S(5¾²ÜiÃKéÈŞfE,>‡0zll·K|„+w/Üm>rq`©6´~ä)¬MÕ<Ã-11–IEzÁ\}ê˜şxB±UŒ±XÓŒØ°ÒèdŸRyòªp©Şô-Ë¬

f¬ƒÒ*H}ŒâÚÁ§(ì%€2Qöp6Q‚İ¿^‡£v…vÉ¯ø@G'w-±H·¢NËÆ°:±ÕÏ¨T¹¼ñ!‘Uoü^@ù¸ PçìŸºÁÃæÔÄöåuÏ+½¥ïN+ìÇY6íkØQÛÓZ'¢‹øUB9ªŸ¢øv–ˆU²İfUÜÙuš¹[­±£VOûuÓLbÀ¤¨.ªlÓü¼ç~)â ÃDıe¢‚PY ÍiîÊ'õeó¬}Ëãg>ã;©QïâoşK³±jší¥7<ÒrcnÈÕ¢ó·dSANxöSyğ-?	`ÛoÄu™}‡JKÔëJxO{JU\U_ÈšÍóß!1dá•¹èÈ”Ú·aw={âÌäœÓê0OÓûP®µ1à´ù£)¾ö´dÇÖf=ğQkìgÖ_™Â]ã¯; «7m*F&¨=8;ıŒy\@P¡•…¼ í:Ø>s©;RË”¦DÄ¿×Nğ\Û,õ­Á)yJÔ.»g)ø€uI` P:¡Ü_døÎÚûøô"{®‰+dc±#™2Xvwk4Ï?züGeÀ›Ü#E¼&îî˜8¨ö*këVÊ¡ƒp>µ¢’t÷§çšÌ œU”®îÆÅK>Fú)Ó8û­Ûïf$ŠİÆ¡şè‹íNhˆC„Kvö«‡™è¥IÊŞ •x+	èäŞöÀ33ıB˜>}´ï|YÒÓÍøå¶gx½İ}š¿JŠx2ªKèåLİ¿m®œlpü=KÂîÜ& ˜¸ÏCW‚4h¤=0¦ÜqMš=­‰KÇ(˜ü6à¤£§ùê·Å"©cV^,oEäÈÙZ‚C½Âô«é—e™ä¤n3T%Àn¼ö{Åcnvğ_‰Eh8GƒÔ¯Œ½Iÿ“à©-Ë-Z‘ie¥Ü·Ù*j5Oa%ªÏÍMÙ@dõrÏ^nérìòdÔW‚y;E=æ·«Ÿ»îM´ r3™­£TcÃëœ£Eˆ4›f[MõÆqG«¸†µî# w.Õ?ULòGe_K7èñz)AJÌ]+aŞ›êk&ø:/;OÃŸ_i¥½¡[b´İ;cà=H©@jb„2×ƒ/Wä“_½9Ö½«\¸XìùP.ì t–‚²5û ÙT@xà¦‚a7öE(Äÿ4ö°µÛúó›ïÚÓkÂ¯I‘û`Æ‹²®¹¹W,Z+ZHNõ
N+.!ƒ¶£Î„vÁ'6å+n™œ.·û£hNÛ:­ëÌWÆ
Úd·m¶kÆ÷D]ĞÂ…\¢ÛÈ)Î[µy=ÉU¿ÑF#púÌÆˆ‘%³¸°ï‰ª®t×cV|(“#ø¶ºÙÄ+SîÕ´õRÎaräb>eô‹äÈp0{á£¡”¦†ê—ûU®´Ñ—ë·l•¾È¦°‚<Zxè È!ëWV_¿ B’#!»ÙîdßMn¹‡gÁ3dóºü©ì&æJ™¬ãxMÙ]x„I®æë™z¯çjm„/MŠãÿ§Ï³èÆz”İ|ÿ´Wğ~ùİew˜ã à8´
œfø?@ 2™Â†İ #“4ÈŸ«ì'ŠLS¹¸ÊV;Xå¥ô&Åì¿ÌŒ[‡³ï­·İ86ŠÕ’s}æ9£x2³Ç‡¶úgwé§‹ŞÉ2ö¡z4×^O—xåš?Cf‚`çÙõ_äÌ”¡óşû×á’“ªŸšG—•nîÔÉ
]1ŸÔ¡»S¯#¡³úEq£q^	ëLRòÎ"Ò¶ôD½ µÕmò"/ÇÚe`Ò>6£4ßƒÿB²/VVõú_ZèíYœ³C¥g´YUÁöûm˜èW8ıæãlZù}ˆqšO:lôQNú«mg®èí–Ğ.cƒ£Š\ñ¢F–ã)êè-C~6íŸD‡!/]áyªÔ8©dùFµ1T”İÇ!vÅgî^èr|øÿk$lVâ3ôÑ´YÓ÷Ö2¡$Á”SdªÕçœ Tß"cœèòb•aa=~¤YaúCŞhÂ®„7zÏÌß7ŞmnŠ'Ì)N¹ãô8~nÁÕ¨&¼lÃsŸhP7iøIMcMHl\$J$ùépµ"Paï`âù±.ÓXt›ZåŞí#O¡ÜMTÓ§øY/ÛŞXCÈú {GÄ%ŞDQ8ù"ÂjÃÛª®â¿j¢7²Õ`SœäŒ>Š!Å•å–h/à¾±uËh’£'ò6Œ Ï“9^.ÔcÌtó]´'HAÄ‰öY¯áãQí\m`Áµô	©<ì·² .ê¾çAdµ0æ&GñSJe0³eÈ=™÷ş‘šØéÜø("7MtÛ˜ugbËå@¿
y‹BêrÄŒªì Â‘åbíù!:øœë¦DÏCêsêaF«ó'mz ø™¬äåã¨T¢îY=|õ«Á¿øã`ğYÖœ4ë+ºC+ª®8ø ’½ì‰É‘:UmV×G/¿«a‰ü¤ë±oÖCï×Åµ‰G 2×úoy ©4e¤€]$Ÿøè ˜å»VZÀ¬†¶
½®IÛ"¥ÑmÏâWwduÂ{:şÁ8ºü¿%åc\NDÊCM2”¯-…J¼XoHAoWée@].¯B!y{³
ÉW§W˜ğ©Ÿ8¡íô ÷d#>Ô•Yl”ÏYWB:ûì¨¡7b3¦˜îÎ„qs’¶L}WoY£í¦(øÚÉ#¹hÜ<0sååå¡eoÄ>Æ`|S±,4€à Ô¦6hşÒÖçh61ÊQ/LŞo³M,…ÛÀ …\‘§Ä•åŒ÷*á±9~:%Ğ6"¬Û,Pú-(/HäÙÁi‡cS{ß 1&ÌU£¿”>&€"–ÂQWŞÀ‰]Æ¢!gU«s£_£;H"ÖXÇA¯`»æm²sªÜQÓ ñÜÏ)ËîŞË$’4J™0aÂçY»eØÒòZ|0ùxFï~À£¢‘¤¢`Å/W%òô¸=LIéúˆ¼Æ{İ†Äî­¦4	£¦O§+¼[!U‡tQtÌóåüé}aÿ|«šp­’©v•¹àf .Ïpjè›¹“ò’l}pş¨¼†9Ep ƒaU—táT¹Á#“Tèı$¹’y½¢àÖ®²°+Ã9J“0
]»ú—luW@Fâ=¤—à÷€;şxJòtØlü]4ƒî1Ş˜—­Ü¡v¯-ÉãF‰/ìå`'3lèŞÓ=ˆ™×9ˆ[PC•¯„—n.O3_eû]ÒP­ÚY)bl™³SÛÙŸ a»Eæ–e]5—ã Ş¼Ùt.J¶“¦Ï‹MB²wˆÂ»ıJŠ7vDbß s¯ˆæ”—zÿiS@Ş?M[¢m=W({nÔ;Eç–-í£ı.Ä©ÇÖÍ÷Íy¨ŞšE]óÂÅÜ…˜,X¸lÁè¸Â½Yà¬BçD©ªU¾,éü‹b…*yW Á)Î÷Îß²ZêiXÈîÔ·DQß¯Z¸íú±¶_Ì¶¤ó“vĞlò7WÒŸ5U\uQn%ÿÄHáŠ+ï(¸AW åX{a©îFÊ/X f–€'¦ĞpïşJ¹PŞW:ë‚¡dt.ñ¯m;ËÏ€EëoÅO•â¸j}\Ôj*"‹ä•A”„†§ /›4èÙÂ²1W\ùâÜàgô%’M0YîğU+—q»_â´I£áF„Ï±ï?3L¥«`cntRıç’)K]œ²!Ì·ÆAõÌØw³ÏÚÿ¼ûbÂO..cyA/ÿU:sÌ¿Œ¶²ËôsÆ˜ÀÄf?T°Ÿ‡Ÿ|b(…ŞÂ’DûE?™ìšÒM¨4øíüa1D1ú'7ÈG#ŞÂR™@ÆşêŠ×ú(ãMP–—?©öÁ3lwhz^#³ ©yê14‹İßÀxzÀ+r»êaBo	7¢ñ*$óIšÄÑ¯” …Ğ.²ıÀÌØksÀ:J\I8Ë³4[t°j‘³IÕ,B}[1paZm©Ÿ«|„pFéWyíÃLv?‘:¬£ŸJ Ôvh!úğq{¹^Ì\veÛ
#$]]‘Üx&¿›/ùWË…Êa®„e˜zÿlX¨Ît˜Q>—ÇQÆ\@ùƒµÿtÎ8¶ğÙ°?YÊcw1vµµ‘œ€±ûA.â+õÀR zMï;¡E~òö©¬*œLg<„PÿÎIgƒÓ4PÇÃ†<Î·sıå³·‹ò-*ÅÂ¨ke3t>­ıXJE4’`7µÁª ¸•Ebñ*†píš—2–ZvØIäÆæ[šØ_Ä_«\RÒãılÉHÒ.ùa’$Ô¬ö²¯£ìÜ©àÿ>u¯va?±jfwlƒÅ5 ¡h¾òåYN›õø1al6W$¥K¡y;:˜[ëïàwõÀëQmìåÑ 2â#Ou<ƒó>K­ërö"Á¦É¬730-¬~ó¿G¡‡ÜÎëqÁo´ÿ¸ˆ3g{1ôEKMô£¯ûÓN‘±}òõ‹f?y+Îá}\¿‘¿GÚ`)]f
øAwÈGèÑ`@^û•gà¤é‘šëuÈ¨Ì3»ófbœ“‹wxÃGµ Û˜I%÷yHáú²uÀ3Åvõ-/×(ÎP·±:‰¶p*€aw3Æ’zš–ÿ‰Š‚7†¼*}ûdh§³ŠdêwsÂ‹ó®ÿ¡2~²±ùWg–Ş®Ó]ın¤î‡j4C¬gáŠí«âÜ"ºÈ$l|áí}Ÿ|[.#â!_µç¡l È;rô/
ÆÓ¼7§ÿ89x%…‹ïñÚ¿OÇ ›‡?ë[X¢t$~µ\øÎsGÄX>š’ +¾aÑ{úÔ$lqXî­á!DZŸ3Mø×kÊû°¹FŸÀá_IŒ·™X«|©RÂ¨-¯*×O½/a•âë/¾òhDÏ-s1ÓuëaxöØkà.<k“Jêä~6 wè«Çûè
Œá¢”?–gîéiDj©BÏjª5ùEœÔXÎ¶´Æ(Ç£‰?û$mÍ8ˆ¸ˆ‘SÙ?òÉoáQeürcGai_èÊ ÔÍñ½"jÿYÈü‚y÷m "Røó¨4Í]Â^2;´irÅİ3Ù_Zö_Í)§L	šİ‹ÀÕ–Æ,Ì-Óƒ'T_V7=všP\Rs™º¹Âè:€¶æ.’|#Tf&ò3¨ü8W]=ˆñ®ßk0@Œ<Rœ¶k	RÚ¦ƒ§Ó‹ï»æÈ¡DÍ[Lm3amèVÌOViá?’İÎì<ÜıÖİ&n–Ù:šJ×¥àPCroÚ—Ÿ Y:,ùÕÕ®Ä^¯Hzhå”ªDËr†"‡û×Ÿhè;äßV0ŸM—ıûËÀNÕKOü™d©»è¶sÆıÒmâ§E¹‡G0..L³u*¥˜-üMM%z¢ø†²ò93ÅœÏ¬—uÄò1ÚìÈèàË()H%¨û–s7wÕ‡zkÒ–„£ÁĞ‘#Ø•—(şÑ‚^õ?×+SR*,›Ú¸.ıÑN­Anb†Ôªnÿâ‰Œ\Àà;sËQãfó[F"~Ä=6ÑÈ M
[ˆ–7¥úzÍêj¾Ëã´û1,Ø¯ÛéxıT¤Ş(©šÀiÅ[YVÂx‹] Ñ@†¶å]Ÿ†)²§¸"îj¨%©{h£ >Äae_J¼)!Ş2Hã?®í¤bbˆüˆ«ç“€8¢Â6Ò>;:³°êŞ˜	û¨yey“œ}Îî|¿şÒ ¹Hï"[ƒB4Ği§˜\3Fßf<ªšºÀgÎàAâ¢LÛšÇ’Šœ1x‡‘³—Œo½{TVÍçf$LAOª-$ :Àà‘à:—aÀ&Uğ{³?ùóÂë¢†ÓíŞÖ\±´N*9×2”>m¯ûKæîš1ZÄ•däâ†’×²Åš·¦[smXâÂõXÁ¹FÁÆ›oä‹¿øÿö ^‘^iòWebn_í­á¥Ÿ)ËÊDêûZ‚k1<née@Ó„#<<š!:ãî'wÛaFGBpçŠD}ÕµX’ì€_+›ı…DÙJ8útU¶´kóüë^Üåëx@­¡+ØË€Gf6çlÛÉ¹à¹Üûß§‘o‚¼Äé4ÀÂ–Œ2ÜM!ëYÊ»ñßÃÿğ[ñÙ„Jö6¤wáµ4ÓeID(><‚+ö†{8®tQz³¯5¬„~ó­–~“œ‚@Sÿ"JAh1tdÅ§ßªdoc'LDA¨s`o¥í´&Ø«<J.x]ıBkÍ2Àã¹×¤ÀÏ'è}‰Lä¡%·tiÒ|éƒ³Ğ ÷ Ø¶;k³ÍÈÏÒLçĞ >§µ~ƒûöxœML‰wMÙ	ß¤(“êûc{%úÉÏÃl\ã“ï¨ô§ˆx‡½^ªÅp·ëÑ°|a¸î±W9YLáú—İùœ}*ÜùïeãçÌºtì›˜ÂåWL-QÌ]Æ|;YÃ<P˜è„~~VÄ.ÓWŸÑgE?Ö¤S~`‚ª ÀÍŠ¼È	Ë€ãJPnj=×Ó^Ó³#ÁJÁÁåşÙÀßémõrÆî‘fqç ±p©)˜š`“9ş¢Ì j+á.ñïÏ]å0Eõq.‡‹Òl‹ÿ‚,B 0^ª
¹_VnÃ™_Î2ËHRÛçÆ	ßYÃ&Î=CJ1(Ô{dÅy´âœŞ`]Äö#ldg:Ó«¹ÃhÒy-êãÁ÷N¾XâÃtİY†
¡ª¡xÊ£Œ–Ç3¦±°!´˜âÃçœ”c‹JxÈê]×ß—ˆ}\ß ´àTÜJHCiA]Å{Ïá˜äy¹ƒÙ†Ú½é§§e]\ŞŸÙ[36„%»h«˜3½ÕÿêÔÇ’Æ ÿöÓGù½ÿ÷í*aTØ@V6¸Ëd‡áÂ‰#$8Z´ËG~	u÷ÉBèEª*èŸ!ØRñÇ~ø5ÆØZë1ë$¾´½1tJj«R˜™Ş¹g½p»]>€Ö º¿ˆ©kº‡‘P5K–¹5£aÍg¾jQ]ìæÓu¾e)²æš½ÕÂÓo a²¼¼4„E8<N^=mÜ¡"’y0t“ŞÛW¾Qñ	(Ü2ƒ÷Ši!ê‡²Cû º|™Äél•ü1;gøs:ØğèrWä V¦2Ğ8£™|@9ã¨íQ¿W-^tÙÄC£ÛÓuSe”¢ı•¸eBX®sßÜ¦`8>	OR%•I`pÚ •ËŠ2œPî4¸ı(~¤µoå‡ù‰Öıš2ñCsi.c¤lRº7q´ÙGÖX×2¬f3©çi=æé¹__®ú^ÿ‡ÓfYV„´BŠÈÛ8u£Zû¶Ô©ÊæÔğÚÆÃóŸeñÿedXKºôhĞâÏíËäõüy"ÎRÀ‡^3HâQähÙ9W«¬éD¡şav:hzO÷!CzW›VÀÇ‡4økO-Ì¡Lé‚
İ‡¹N•ªm½$ä±ãùÏaêgÿâ®:|!ÿ£şq)ôº±€­sH[E©ÊDüóa#æ-ıˆĞ±ãc(À¨ÿM¿ë—ÉÅj¡G0ÛÒX*bª“ 	—«q=¢ÿã´WÒŸ&1!`Û´iëúX¦]¯Áâó/lñUÇ™h^‰Ñ	7&Ğ öøÆì=f¿k‚pş†¾€QªgPË÷rØ&YÊ.Mÿ±^ËFÛ;˜ÉgI[CÇºsÓâ‚QÏÇ˜7‹CN¢ì.­õì6LT…ÎmÉµRÿIì^ÁİÄÉhXÔ:€
ã|F˜£Gbú"ÍÕ"Æ ”i
Ïw°?c]C¬†Ó&hÎ3gdr¤ á^?‚¾ò†™EV•Y¶õëÄÕ¾Š$¡f@tló-±¸·0§®/ƒzvÁ{ƒÜ¬Š:¶q7:QeHÊ¸ªË¦tnŒ8õòã'51ä•èÈ±¦OKâcµ>ÎüÚG­í#, ½ê?9c-t·†ewTÁ“Jf£SZÑ‰«ÏëßOŠŒR‘ÉúkÿÀÅpËÕ4	@Y«ƒè›JtOŸEî[áÉ¾»q‡bËèÄAô§Ø›Ôa`_C?,Çy8ô–.,µI¨1şccY”q¦6~ÿLh¦ ó)Í8«4¤FsP« WµÎˆŒ
± ´á¶Yå<Û ä¡€ V^*±Ägû    YZ