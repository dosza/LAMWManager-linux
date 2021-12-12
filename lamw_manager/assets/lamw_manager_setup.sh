#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1855329073"
MD5="451e5e1b60418d7aca13334b626afc45"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25496"
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
	echo Uncompressed size: 188 KB
	echo Compression: xz
	echo Date of packaging: Sun Dec 12 10:46:22 -03 2021
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
	echo OLDUSIZE=188
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
	MS_Printf "About to extract 188 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 188; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (188 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌâÿcV] ¼}•À1Dd]‡Á›PætİDõ"Úâ'Ñë™ªş¸lÇ™S2¥_JËÉvc~>€åsfñß¸İ®:æcñdRÿyœà!Lv'A(J2>FÛQSW»‡8@mk4emGŒÙ­ÓO¡Ë B :¼ÁE±·ªò³Í¿åßbÙ&|N')(ìº†Î4ê8£“Z
E·VFÿ¦c/,÷ÌîÑAÙ‰Ô½äÛ¯_Lì)Ó½¸Íd¦Š¯CëA³˜$v×®G­İ€ëlhÂ?—{ğ©Ædß{XâjÆnoê+´"¹åîlW@Q´óÃP}UÑiØ‹ƒ×ø¾Š1TmÆÆÏÂ0øÖ²åµÕ½ŠÚNõ-3~7Õ¹)o“²”W¡EXòZ˜n¨Ä´ÙÛ™ÍD]Yx	iµ|¹ñXÒKhßZ`ªn	ˆ|p¤Ú+B,ï*‘y[,ÙvõÌ‰„!OP—ôpğ±D–ã¼œÓgyE~*É>ÈÔÎuµØÁÌ­¾HÏ¨9¨­m²SÒ¡ .·Ã®ü>]Ü6÷RÿÖIq¨,¢(Ø‡<PµÇ6à¡7^ yŠw›–ÓìşºoË| É¾Xë'RÜÀ‡Ú€ }ë)KÇÜ
ŒÌAL^åi£¶~wàŞ]Ö9ùõïQ°R|—•TÜxYØ4'Ê‚iğ&=<†×PX°…éZÛ_ ®½ZàQ„ïºEªhê›áN}•u´RsÈaÅ[ñ´²cîÆ¢	=ó…$°{}ş[Ÿ‘^½â¸Ş×mæ÷dí²Í‰¬û±¬)“	ê3[¶±Ku)”#œ¶´‚¿œ“& t™Ú°RñìÍ-wñ°û\dá¾¥eFèàı¤)ÚU­vÌŸ	&q1°­1ÿƒªe,„lÆ³-Æ£ó%Ïµ
elÌˆV²İ`3úÑ–Vo‹y¸‚?Gx®0`­dQ-yU24é:²'ÿÉ2¡Dçê'!8Aê¸n]]*2:"(¦æ^M4j˜í¾Ò¤ÛŒÇ6#„‡»©Æ„0]PY^ j1Å7«Õ9ŞQ;Zä"v]2°è†›èQ.´˜ÕàUüPg1F€ÎZµå«±ez¡lí)’eèÅ+ƒ|^¢rˆï¨ î&çÊZµì¶Š'§5³m™TÍ±„Ú<ŞÖ}šb+ŞjÒX~nÃ´¹™9ÒI§¦ÁFåÉÆµ¤]ç"æÂğ6Ç”Ö/ŒØ&Î6–¸Û_ƒ{§ºE®-„½9É³¢½ò°êâ¼¯\|ûİ9å~fQ¶êG
(o‡Å.3fˆöØˆÃU·›†¨î¥£1Tç 6	Zå‡DàÌUÜ5å˜5ùôÂØşòcx±7/d­£&¨‰hg›’¿x«kÚQ‘¸¸]C“Ù~@HøºÔ‰äœ& @e££ÓİeÈ_EÁÖ½s4åMÄè:P»’ìd­Ğ¢ 
»Œ/27Æ 8«ÖOLV	ª‡-ğ”]LûÊÚÿ9~İ,g,àó›¶K¨Ek|6o³„€[”á’ö­×eÇôY# ¬ïGwê`ZÀ'R¨ó <^ßLòÇèãÎ3è„$Æ$¸çkvÓÇÑ PÅÀêÂpãıM™®:¨‹ÀN‰İtªZ{d•÷U–èô¡â6²üœ,øÎ je–©aì‰óîwÿ5‡?ŞÊ<°Ù!§
¼)ÕÅ—ƒE°êñ-=ªËz¤o*^—\:WŠï?^à½­c"w1cedM´éO›˜ÈñÚk]!‚È]Jií±{ºú¾™Ô„©±qÉò(M¢=Ì¼\LmR]_n	†ãhÔ°éŠz4•ö`Ş˜ ÕTX2É®`ô$º™à5áü5øÄ&k4t§úr\ß’¯ˆé†ç­±ÅoÊz…›"¢±ú¤Æ9.REÎÍfĞ‰İnı* ‘E·^/%SGh:4laÏ9¦3x\ zuà6?èùëæ¦Àƒì¹œBN¯5À„óKs ªŠ‰KuW¸‚*ã;p‡D/ö£TåˆXƒÙS—šKe%‰W42[k*vèüª$L<©zçÃ?åq£ÛvÑÈa†š@Í©ÔîØÎ4“ª„ƒ Ğk<ğTjùÒóšcØÏçr3¦8Lç6.6¡RíkÃÈêƒ
@Â<É$EËu°®®M€bwê;rÂŞœ†?»¡Ä=T¨Æ±x
XSèmU­™ReVŞêP-9	ˆTÁ€z|íŠ;ÕheJÆ&e9<ªì{ß‡™ûkİãc¼MvC±óÿ=U`½Ø$LsÑ>h¯÷¶±AÈ‘&R³g}CªÌÏø¤É6ã™”O ìĞ‹ì>¥w_–«2ıwí«ãáßaó\øÔ“‰ä¹Ğğ5U©XéZ´€E²A”øØ€:•wü¯/¾ê¹0áÒg¸Ÿ¯:çºT2Ó‘ú&Ô ¼}`±pRØqóş˜ËyŞ»M?åF÷¾å1X€¼R ÿµY‘¾…Í¿AU£E(‰$ÅíS…«qòÚªˆÓf}i\Kj¦ú€‘$î³Ğ¯½Ìe&Bòk¤G[÷®¥ªğZè€s4‹Ñ!b“¡µ xöãëç*)#F–f œ¤`˜¨<d6-§hÃıAÌ¥]ºI³ ¡zBŒ¨†
W×jx†6ÊğÇN¹Uúæ±è·9ƒÂ¯R<ª±ÚpŞ{Â×š¾8ƒáÑöò[Âƒ#]jz9\ï6‘ì“Ë´ãå·+q`ß@fH}ˆÓÏwÕšÎ³$¼ÆùF%ã?œƒÃ <#« Ü&Ü‰j2*!~Êa°Z”Å: ìõê‘Ï<1â}
Ayz|~0›Bc¡êu?!@®œ%KHEéÃ:sl;lÁ=ò=ÛÅ‘7G|9ôÏïä··W/ßÄÿ!~‚ŞC_âCV’¢ÿg!uã÷ªEéŠíÒÿcèšdö¼“‰÷Ô´*yCmc‚JíÜ©ySTÇ¤€Z‹ñ<ŠÅc3İ‹‚¾R¸(Ç±à8~"ŞiT;€ ëÃ9§ËW}ùN‰õ¾Có¨¡gÿ1YÏR‘}'ã·HájèEÍUØß¦]7yG®î?R”e‰£mæŒıÔ²` èÔëEí»ìì	†Å@|‘%Ç³òq0İ½=ŞòBqñm†éÕK{ò¢ò×ù‘°;\óX¯NŞo¹©~£fwÖ/©™`U9û°=úW×9w´Y&gZò&‡ñÿÿ"§œ÷³yšiÓç¥'u:æ'Lz´Ïßé(+à5×@3!Èƒ`œ±«X‚â0©RÈ¶ÂÆ-…Ì6,ÕÚSÖœu° ˆ%‘5Q"Âp:?:à;£â6J§Xó³e¡Ùn”ÜÚ~z¡ØÉÀ$·Y8’K@ô¼ü<
ğÔêÌ¬ÚQœ¬sq¨,ZäL»mV”²4áÑZ@ğx'%4—VqøN˜„—ë94Ûö%¨uz®ï}r›õwZÉz‡ş@
·s®ôè2ÆªŒŞ¢¶–7ôhN{{–3hØ’y¼ïÒÈénYQ*¸nÚx`8
­±ÏÛbyÆúÁn×&FÑ¹vß?@2Nº;*UeoóòTïòmğ¡Z‘:vŒà”L¸q{âºÀ<®XhÍ¥ö
(Á›àšáIsn-_VşÈ¢·N'^½ş ñÄE…mÂ¡ƒkk>„¶¢E^´ò®İ[İ50ÊÁ}ëÚ_Ò)9;ÃÇ^A~å#yÕ§Lõ,‘ÏM|O¢äë°şhDPæ{±†»ì»-ıÒËéœî×C¡ú&è¿c‰´²¸º³¨®'ˆÓ£¡ë“Z¸4" ”ËÇÓH˜âütí—$²ƒ¸&Ÿûfc³:››WÚ±”Ê±t‹úëõqJF£3ilk4•ñ”lfW§V¦mÄËfÕC¾)Ã¡Åæo¾WkƒßÙVt®b]Óß¬,I'«q -II–}5²,Ê(ÆèÚ˜êŠ£_h0ù‹ñ¶TØˆ‡	ƒq„½hS±¯©BåGGÿmú„•*'«Ïd®aÌ/äX™ÈdsqQD€QµİÎ´5£[?!İZÑ	ğÆí.oˆå€¸TH[L“ËÄ-ÔÈn’	ïw‡zH5§Ám½˜ªõ@àM»^4Œ¥pËãaéXk¬![Kõâ©!»kÔÍ'³]ô^´ÇÀÓ¢./¢EÛï@lMQ£È/d¡.$PĞ¯½÷‰IpóQı†—SõúP__‘swmg¥£¿ùÑ²¨$|èó¦pä·O¿Ôe›Q2¸¹0€Ÿe9|ö£Ãøi:N”ØRÖ¯ ?™¯ë/Æ‹lg+BÇ¾Ü‰_›áÒŠğ¸Ïé'»"çƒØš³hïâú<ôÇuŒ@èG^ÌxÛü®bˆNP‘`ÿ3?[î´–ˆÍÊsôÄNĞ¦h-S8`Å¥%ªµ]š
Ä”·MPòpô,÷‡"Ä¦¶Gàtˆ},§‹AhY§@ğn#3\J‘l3·Wéä)€'nıêOÒa
‚+BbŸ$T¥·Ù¤l€ƒÚÃg·Ê2Bfì©;fÿê{ÊS€p¢‹]90ÜåŠt} Şº\ªô€"OÃâQ9Š.6ÔUK¤¬mmYw­6_;:fŸ€ <T.Üµ43=éÛÙŠëÊs,ş‹¬‹úòŸ~	WÃ…Ìõö?sÒÁ³S dºç_IŒØ2=“`äsªí²4ıáL£}ƒdRÀŞœ4	"c¾‰¾Âv"”¹ñ«½ï*ˆ†5	6ó’	ô‚Ñ Ú¼_N¡¶M›LA)0]éÑÖ@ÇÈQµEÜFš7[!2å|o‹jêíŞ©xˆ‚N5öw¹¿ÉA¢Êí½µ.…¿¦½ı[íñŠ=ÇÜ¹DÕó¼a(ïk©QŸñÛ5Áäù¥~µ3¿Ş™]„)ºş‡ª{§VÌ‘Epc\¡İ+÷Ñá)[údÒÙ‚¾oÂoáÒñş(¾»Êğru…Õµ³ÄUT§ùÔÎ'’¼BCb[(|Ù`è­=fUÀ¨l	~f5í](-C0Q™Â“¦ƒs3F’÷TS[ÕÊ(¢026¼°ácò‚pÌ{ø$ ô'%tòcf9ªHûğQÄ±]<qØ¿hÎĞVf«¹ó>R doe@İSÿ§7—®È§(îQ+>NÑ9 ÊÚ!{?ètP†{Sm¿5ŞˆlğÎJP‘.ÇtXéHÇ‹PgÀ‹İTq*Ãc’çÍ×[?‚›r[0÷¤ëßÑJÌÔo&İ½WàBŒ…¬mp®ñÒn¸‘` M=}›@×]*6†Èúr 5é J)['£¹	²% ò&z]6…á¯ "àSĞP#ğ‡1ˆEÔ 'nëíe9$²Ølå½ñ>¾zû5ÍˆbfF¤‹mcöíGV@;L÷O}PšËeğÆş9~Ô{JÙ¿C$~so‘“±5*ÄéDOŠûÑ<ü;¯ó‘‰p´ÿb¨U®ÈÜëàı­`cx».?Ì²c>`bíU„á7€V	úeö5ŞŞ:©ÏIº|…‰)–®Y#U¹ßiye°¾ÇmäÚ:„8¶Ô¾¼ètÛ–İÌá“µ†á€@ÊüØYÒx~şDRÍk^exqß0ÍJ:O2ÏW¢Œ„á«WÖ¿?§LEÆJ-ÏœövÜ†ôw7S _dÓİkü2v‘·?tr7ôWÆ¼Ê?&Vˆ,‰ğßó÷®òšãx2€\,p„òÎÏ±fŞVZ‚‡$
+‡©]ëÿo‡ƒ„E¯UÅä°˜ª‘®•EIy{ó´“—Zu‡b[ˆiò¶_R(F½§¨ßŞiyë´0?ûšÜa›–1é&k¹[±Ùç‹z·w­ÚÛíx„à£|AxÑÑØ4ÒˆOq"Í,'Âğï
ô™èÍñİÔÃº¬g!+Ú	¼T{™âvğp¦úœ.ù“ÆrJaìO2C÷v'5/.0EGÖÉã^U$Å°ÑÌ8Q7ÿ	ÃˆŸÅEO×öf"Ü‘ÁSüÃû4ä†‡¡ûX_ç„bñá<EÀ,tÛÕc#vš'A±*•LÙ¬ú^æv	™ª/jÑ–«a=r®¿´‹ÖçPÚpåê+Jú±k»µÜ*ù|æÅ/ÁlóØ<œşQÒ@¥†¤‹Ù'¢Åı kó¯ë={†ŸHİ»Î¦HLûœib¢Çè­lóã]8·ÿQëãñ¾7Òg¿¸Ş-´‚Áa„`¶ÀÉ*ÅŠM¸"Ês5àJz#ö¼dßÀå““Á›”óp©Æ*p¸Ú4Ï-tòéÙÅi{zİñûkæı-ËŸl…=)GªóvšVW(mc!œm|êG{Åİ‘~ºv!Ñ+	 öÓè÷ÚÂ©5Tøêˆ1Œê{œ2¿£‹*ø¶wÏ–äv Û´3.ğ+o¤K¿~KñÍÁê&}¶‘dÇ½ãızïsyãµÇb"Œ lÚ4Ğ8Kçoz“ÎŸ;{&3*šŞ<R|Å"xÔU÷»$'|…ÒrÚM<§Qã7Ö‡-”ü£™øë¶à6-ô¹è½ßrušîM€Mãeååıhx©Ù—|– Û3÷•¤kWƒˆcé± YöÌ…ÿ‡{¨Å…ÜÀ³5úl1Lšm–Şõ£æ›Ç:Wt[½N»ªóËÉ;$=e
ì-hm³%îè¨‚ÆÍJgçbĞÆ¾ğÀ¹q§ïhBî£_ë_~Ğì¸Ôğ·—ÏM/H¼·~Ô·–rOj·±«tB
µÚ½"f™‚û[ÑŒ4ÃE­Ï3å*şıFê"Å°¡˜¸€H°9­x£2p1öòàä:*¬\ˆDæO¿N1_(ÏĞ[´u’«vîzœm{w.ÁªÖ ëÇÀÃ3ÏÍl¯3)²";a…ûşA(¡Îúï#ñ/å¤Ò(ã±6Y<Ñy@[”İïû`+kYgF!Åç:PÈğ€_À¬¹úbÀyKü0Ÿ9òçg³-‹§i…>ÔO×Ôk‹väyƒ@*-„ğÓà‹Lë²è(ŞZZ2<)‡—`àxå§ôöúzlÓMÁd/wWa›/tÿZ÷+	LéøöEsæ¿C¤G§¿ˆWD´*l”ÎŒ°;‹º\Idñn+œOÂ°Voã;ÀÙckjÏ^°’fhãGXfåïê]Ğ÷SÙgÏIØ%X CF¸œöÏÒ–ÈµaÖØU\ÛJ •¾P~ÿMàäL8æ ÚRKûæÂ‡`ÍA¹Ko.À’ÀÙZLOdzÕY8¡SÓeo¿¹nÕ²b.§Z–»ï‡c!³y†~8W»Læä=(„qÜ£%Ú 7À!®(£Ş¹‚BÕ¶¢Dht¶t•4Ò—ØBX‡F\Õ€fÔNŸ9¿O‚Ä]55f•%èÓÂ ,ÅÑóiwåº²îv3DÇÚ±ÈİP¼:0.,_êè(soI¦şL±öÜq¦ß‰¦Wf:óú½`<ŒqòÜšV2ø˜µ˜í²ù•ƒÒª7L+ÑÆ9ˆ:ÔË¶í§5À7Óºã*0»Ì?Zä*T®Yå r0¬ò¦c
^“zÄ»¥ŸŞbŒÃ‹°£š`ÛÁlvºèıÔ¾İVZ›ˆÙÁ‚v¼	S«I4ğ=8õ3õŸóNŞœWÎŠª‡‡„;ŒaxeŞïNGv	YhpKï^½U}o¯Şí†>ÆOŒëÕÌÓ{¢XH}¿ç~ bü[,KVEOöÑD4	¥âMîuå¥*`Öæ¯Ğ\ê§û‘”y0™É·Ğê’Ö" 	kw@^á“Tsi7ì5Êİ4g,õàĞâ¸uFÂš.ğ
dD¨…¹·HH4á6¯„5Œl…_	`bĞÚş|%qP}g#/œäô‡³Ğ·ç},q…
ãÁ‡1o¯ÅÛnÀ0·¢àŸrUàp¥'°ú-æ²M¤ÌIG¸4â†	¥mZ/Á¶¢²ü^Øi 6 ^ ¡B	oáA†JsŒåwİ³*‡İ†  >\æ»TIÒú
ğ)³òzÙ  L¢q^”ø‚KiÎÆSü€hÂ¯z-Y–%w ö±Ù?kyÈ4p'SW‹Ï]M;MSĞæõ¡è–Ê¿Jó Á×ËÅ©6Úì/Ï)Ê´dJ\”‚¥°’ÎŸìÿ÷ìÕ°×@Q[[ ÁÖŞcEµggÛ®µÛ IHÃ_o·ğ¬‹
xv-Š^&³(Käÿš|[hA-±7’6æåû¤¾:Ò®ãî€ôâ!¤Ä¦7Á·÷vl¥àT/¼?ÜNÎy§¼l´˜æß+êÉö¢T¶‰(újÁ4Í4Ğ`=~¤D—ı5JÊå=l}W\#®wË Íß¦ìàõƒº<Qw·KóŒÍ¾#(À£8G
½Ê ¤¿)/—Cµ‹9œzrI‰Zöªé¢í>ğ£·ºÚİSIŠ`É¯.¤®Ä×VùğŸ7sòNM-…"?´e7¿ç×À¸+ëìntõ óİW“†¢¸[µÒ%ñHs×´ağä(B:gÓ“Sä…;4J„vÊ9ÏÁ½ÅËŠ°ivV?¢:ˆÒ¥´o?çœë%~ÙMTE~urÜJW\ è•‹RÍŞEnç†k¬9Œ¥âÀRâèv5»† •Z§ˆ”'[¦OïTÙ‰>ÀÛ’<2~I1«#Ù'[|¥âb!¬‹áí¨œÇ"6GÒñ8ÚƒC êÅóí¿ƒª‹€?iÿ¨'`×¢jå(R…nëŒ›Põ¦–^“Üm¡wË©Ş8è¢©1ûW—>Ç¤3PüÔªxD\üOÍÛ·6:…¾äûa,Œè?Ï@8ÙÕÙÜ=[r d|X{¾a5¨Õèc¥¦‹Óú;ùNÆ ùØÈ:šNÃ­àâ"<ŠÙ³ï’2>âŞ¦¤æ µóõ³C`š¶‚˜pŒ×Ë§aµ‰}+ÙûŒŠY6’(ÀÅd×/Ä–±Fèrê¤•­ííz¿·‚“t–Å dó˜;ÎÙ©\´I!y7‰Dñ†ó•œõä¸°%ˆ<¢–‰¿î"Iz¿è9¸¼m¿qVKF]7O‡š(‡—øñ Bh€iE65Ó›¦x6JD6ğø°íšPY­7xÙ¹³‰Ün¸ƒ¨ ¨šN©ŠQåœ‘êø3WÄÑil¤;prÅÑJvÑµÖIŞŒÒ«í?­‡çamDşŒw—2®cµiÍ-‡bjÄä‘¦¤v¿c[÷Ğu‹’ıkŒÀÅ¡!·y/5Ş!w`\¯–Ñ£CÕh¥®²ñ !ÎT1·á<>3®v©k³E"Ş•dI±¹¾7k»r¹ÕOÂg1!³[¾P›a`ó›(-	ÃEëßŞz[ß}×2ély	Úãµ‰lí®Æï;íkŠ”êvFÍ„ı`7m}ıdDN×Ãİ9ÌÔ‡QÂÎõs8Q”pwnO½}Ø~)¡mßFOË,soÁÕİ¿æÜOÀtfSêÖ†G[raİ Çh´]fT¤ø)ªàüÏÜ™ÊT“™ªæñ¼³³£ëÎ¤ã@|EÖé'
^}¯ºÄ„[!z±J¯Š1ªšK}ƒ®DĞ<D)íÕÅü"§½…ËçVió?o
—ÒfDõ‘@°jºğç¥wİœµs:Æf(Nƒ?IDÆsˆ®\lÂ:']¢àÊ‚yPY Réæ>áò	œ›pÙèŠŒ«À'.Ã¶.  p½ßW„Ã¹k´j…ÕqvY‰•y&!|âÙµ7\ì³nÎx«)÷E«„eØˆxÓ9&”Ùj$JøIs/„°íiuP-ñ	|SNèñIÆ`RÈ§S.»¡•\ƒLqrr)œ½·[cvÔA.”§q&„Ÿ„Á%{ßŒJU-ñ¶V gB	 XYõµü_ù7ğå;áÈÂÖ?í‹rhe³qrçŒ Z¿¦l;d’šãi Æş¶rXÖ^Ëöi„±ÑHœ$„U!W2sB¹ø¿¢1ÏÙ…\ïá“ı@o§º%´h¥ˆÚ¨Vu»“gG)7‰9éº«æ/eÙ´p’@eš¡Ö¢-ÒŠ×p>ºfOì§ÕY%v«ØÎ›ô»šKõ…dou¹ŒÆã+ÏÍÅ8›
_¥Ñş«NpÍxŒúá	<¼R²­xEDÆ%Šæş·#†8Yª&_Eò>F`¡“Hß÷'<x7zHv†1AılèXCId–7*°Œ@ »øu}}Ö6¾†2³AŒn{†¿İHCğØæ”¶à[…Å%ÜŞ¬®Ã~¸Äé»8€ØsÈ×“¾Évúíu?¨áäÅ3{'¦ßÄ/}})gÌ&(H`Yeéñ‰şİŸ‡óÎûæluÒ ¸‚™_üH;¶ô`Åçc¼çaXLTæœÀ=“YàÑ²Ô\°äÙœûè>B4Ç ¼[ÊL fÎ;†èeª#“vœƒœ£0šªÜÃ°e¸xÊ²Øáò®Dá‰¤è›LGúBƒ²™ıÿŒ_^hl[Ú0»óE6»û¡U´e-[F×›h¦Ó ¢À"q‰íbUÿu¬B)!ÿvÿâ®¶óa[K!*ª«Â0NPİ¬O{×)ï?—'P?ï(ÊvóÔTŠBÆÉãR“ô„Æ	|W/h)ªÀœ«Wºöz @®ŞW!ã¡èn|œ@±hK\¨$ònH5°¥)gCbúÕåßÍë;ş N((^¶¦U°a’¤“†fØˆ”w¬¨Q&D:2ç¼=Š\àÒÿ…¿P®Æ_Àˆ-•Í­añÆ(¸H#ÁÆ&œĞJÇ(ì³ys^f:àÎ†¬5½n†¡%	&‹ë[ıJì6¥*—Ô†ajsßS¯µh¼¢u¨	‚=RÌ+ùµ-ÍP	Á]€o6Š<A‹N$.Õ 6C²è¬³Ç–^Ìam×øuphÍƒ„[`,JUQÏ	ÏiNÓ”ïb([Ğœn(¹&i·váÃ„ïÈ©=`È¼}n¿^ü€S*§)ÏğÄª©Ïz×J6q^ı—Ióh‘²|&ƒeNÖ¼º3öA¸À«¦à©`@ù«o:X¿%HevÑÕ½íu²¨Ñ¸NyDÂŒ:yÖ~_¨|WZÜ¼wÓÇ±áùªcsT¦™Ûi½“G¶4xXK›åÚ"}á	ÑdØpcµKRêV¡[âGN´È:Ë;ôñì©vA(O|w±÷6Ìb£xAi,B“¦ŒããUwÑ‰ÈŞ:(‰*d¥*öíwfÕ‰¢®AÙyn#FÛ¨ä›ê©ó	¦bb $ù”›²Â±°Å\ñ¾î†ÈB”¡óY¼îĞ‰ÿáMË”Ğ­ëˆ¸Zc4µÓ'gY”£™wE9lÙÃ BËûj HbNÅ¾äŸò¦¹¥c5“q×Q—ÇZn
1%2cknN^S×Ù¸,ğĞ<Ÿ™^÷şå} ?ÃÄ‡b<æEÌ¢ŠxãÒ©¦‘º­6LAÉDø,•ğo=!ºzï(®òä|nãU1ü;Ãwë*]ä¡ø<V[7 ıÏ'HÅÑVì
"}2Ù6SÎÓø2äi´ö›wRCecíŠàoM„0s˜Œà
?ğä"è£¶ôà|uû@…Ywˆ†î`9]Øzµ§]ÙÜúÕÆxˆr.p}óPøN—ÛŞğ.tì„OÖUµšGÀ@LÈF§Ôl…€éCBs¹­2B u¶	â´ñû9áìÏ„“*mé'ˆí ¾¿ìƒ8¥)„Õ<cŸZRD\Ç4ù!ÂUè]%D‡§f—¬y
„¼ÛZÈJÈ(>øúÌmoÎÖÕ3…ŸF·ô`šk7ú“‰G}ó¸~DBèY#Ÿå¥zi¾ªÃU
-‡kÄ¤åø× °:D ìË“¨ÌmÒe«¥VjÁ,X½„W+5Pì¥¥x5ûãP™yàÚx>ïppã‘)f¯3ÈSOév0…ã
ÑÔ_ô½é3­¿ÇÚ6¢}5Á¸ôŸ:,¯e@lÂCHŒu¾3ÇYè]n÷OG‚>/8$÷(âÂ¡s¯‘û–µ3ÁŠi=Ô¬d‰´õLC¨|`LHÍÈwÇ‘Ü°ªŠ1ïˆ"ë$	¬Äe8eÉqğò*ÜBd×#¸U™WLŠêZÂßG€ R‘Äk¶	‘ Ô‚‹O»Ê›	ì7„‡Š­Ãc/#SIÂKAuoQ8f–[æ˜9ïQ‡'ØÒ›¸¸•o÷ID{ª
,sÅE¨±“«Gg$ÿÜ"Mï§°×Qã4,’Òi.JöïÙ²×Ôë¢¦ ønİ­Áø.pÓ[ÓÎŠxõ [¼f‡64>4ßVå|~ÉèäĞŒ>ñ_x“Ìê§øÛçT	Ò ¤qlÆíÎFäËÖöOö¹|t%<æs|3ŞÿØö®ÒoÔ÷Eø¨~!#X—L@ÈÕëTÅ·–LK…Íª`rİlİûèN/=<BMÊ]s‘èF}{ zÈÌá…i§öÁêÇÉübè|&J-lp—‹f%¿kİ:º¼0Õ,”WõsåùSš4Î:¾üGª…@”">[ixÑ¸Ã¼ìû»l9Ãú~¬D®Üš§¢úDà^üvã¯dš^,ô×B89ªFvü×ÕW?Cv¨æ
0Z,¸¯¸34r¬*ËVé®;Kï”3i{<'¥&\ øNĞ?L¨ŒÚ³Ù:m
š®$‡	Mõ«‡ôNÏïÔß§Yë™_@ß³ÏÅñ?}•üªCÒ”şÄûfì ºİşÇÿ¶¢?8GK<N…=ç}T„{ü6iğĞ$fŸnº¨Gè>’ğm½|$M®Ü‚wº1¶ú¼½ ãlÚN© ®yÓÚ5L|’Ë¸¹%¶ÃCnÔÖShfke„10¿^_ŸE¡Ø"ñ³½£Qé`£<ë‘Wû[û¸:Ğx$GÀã'ÛıdÆÇ*¤ÆH İì¹R…È'À•Ô¤†İEİsO°P…ïE¹¾ZÔ¨­_4Ş²u¥ŒÆüB øhrj—@²ì0&ˆV7Ğo6ÿšìÌ“¹ ee1Rõ®
&æÑ“‡PäÜÜ³€5;ï[^LFöàå ôYvğ’ç•cá"ó¼¹ƒŞïªîÚ|Ğ`ƒ^;C2@lTct¼éM=F{sù9GVa„z{‰ Ë/(£sxI[(İ§ÏcÏ”XĞ|¦!õÁ,W|Oóüöl#/hzî#d/YøuDê¾çm&«ûÕ]M*\Œí•Erâš=°0©©îXnä[2tK	­Å)›Tw„Å hj J|ÇèÓ—5)ôE˜>Ícé9¹;ÓÔ)Bş“˜ğxX
ó¸ÒĞUíÀ”³^ÇKÒEì)ÄDg¾àE8ó+ÈH¤“_¥5”ªã_†4·}*|§Œæ%°ñÆÿ¸s<‚¶Ç¸ğr	×[Kø¬fa"uü¯<…¹³•E$¤æ)oÂ’ËáÖ‚[3ÓûïIúcæ·"¾[Š´Í™Ó¶æ°’¢õÂ|÷7Îá3˜B`x1©àËSiø*T’%ºhØ×w¹æ‹î$ƒ2¯ RnÃ´×BLAòËL—\~—s­6weñŒAQyÏ6|::ò¸K§”E™vï³´¦o›Gêœ¿ï ¸øW¥â´±rğŸ¯Z*À5š£0¦5ˆlÙNQQê“Ù»Ê¢{±Íµ¯òodÍrÖ¦NO0†ÎøŠˆa}Ãİ.q¨Œô$Ğ$ã£d~˜DÖry0ŸôJû^G€&¶M‘¤¯´Ü±ÕEiíç/8ôM‡[—Ìİe>m{µD3LBh³mëE.Ï­)ê—ndbÓ6.icA§®|ß¦Ñ~Kvİ_ıÊŒKmœÛÕR#Øœ€¾ZŠq>”ZÅÊû©Ù³’jC}Tj›3¿cüƒHy®wWŞÚâş"É9Õ$J÷×¶‚k¹’;ç¶RÌ
±BVèÉıj&£¦¹ïÉÓ#ñØÃ›!œZó¼‚c<3ÙÀö“B;r Hnƒ™~$=ÅMcÜ¸‘J·ÿ5jÎ5»N0h/ñª`‘ÃvÔ0X¸O2o€!<d0vŒ»Ài ½Œ¼¸Ä•÷9u¡Æ››Pú1F2Ë ,õÈÙÊß<Ì®şò‚dáD%¹KÓµ•òšÉ$¾sú^=R
NÇ^çœuÑÂººnÙ'lÕ°Ü{ÊãT/ı,FÇ¶9Ú«Ü»,\ßdú½*œ®[ıq€äNyäPMŒ%wá‡%g`insä•Ñ—(‘GFï?–ê7ÊãHP÷E+æÀ¹…°ä)î‹å¸/;‹_şMÂ|6„¹Ÿ(“ŞmIxrÂÂºO´Í7ü/¾ëÅ¤²ùz…ı™·Z½é#\|İ.´“FEZ!º©ÖÎXg7[b„¬>M^6ÁÜüNöõÃËibi-ÎÍ‹|Å¬ûqí×Õê2¬‹û.†.:®8½*6+vö[Áá6ª†m>×’™£×™šÎãŒvIÜÎü	¶¤õ«â¤ˆÎÂæ¼Ô®°áng ˜ğ1^Ø³0ÌÜ€c&İÙPªòºæÙÅ=Óa -Šæ
h:ğR^õjx—@İH¤e†C="Â÷£YÎ‰9ŠXğsOÒS‡ïEeaüuì%×ÇËŞĞê•¡*ø¶”İ}‹˜Sj^>í“¼óÒ
ZâTHÉ™Z1mo6~Ê[<z£¦±®sóJş5ƒèd»ç'êê9O[Ÿm4–ôÅ=¶ø'ÑVS2+"?ƒTéÇy’ƒ¡`·${H¥Ê"ï°[—šEœò5kàåq)–ñ„*)oê¨ÌO_ÿ ¿]€o,e"$'‡ÿ** ßC¿ZIÌ´£İ0"Â”×czQ/¬5|W*ƒ`(ªVR­)¼³S€©Ã8-'ƒfmĞNÔ¶)’‡¦YoŸéòOn“lvL3ú¿+P½¿\'™÷ºzÌÛÿ=2É/@3³=ºmnÈN’)ÎwĞT,uiJï‘GšŸ†_+•÷1«¯õßr¥
B~a»â¸Å€~³ıŠíû\4ˆİÜ˜íjŒô ]UwÒ÷>ğÊÎ¹VÒ/†;n€áÊ÷Úpï¿Û¡[zqªè—š³u˜º‚üc¼Cí†w{ u[„ŸAùÁÌàá›IÍÉw7Iƒe‹-anÂİ·çÁäfJ–¸}"çïDùƒÕ
¾Ôµ	õó­“9¤ÄÛ=a[§îÛ4¥…ñãfj½wòò´ì¼F4§”Q½'#c6OÀZ[×cø\ZGxåË8¦«›J +‚~©Aou¾	òù¶[ÆF°¹‰Ü”°Á*57S.«ÇÃWtÜ!¨¡•ÒıÔÍhÛ÷ôµ¾—jh€;&*d.±{àâŠ3IÛç·ëq@Aı^ÿ¯ù!™…˜*'îÛ,'9şG(!S®ÑÅ‹0™œj&]›ôã,øÙæü¯)_¥ôÜ¦‡ZRHO5¦¨UnˆßUh-#îşÇß3úŞåÚ$¦\ÌÎ´µßp€âIëşn‰õ<¿QpÕ¢ĞâÙ¢•«2P›ü3‘jÑyÑ”µ2U* ÜãaoÙj¶pQ§­Ò»Hn].b?-B1Õ%vdÊ¤’-@1Kµîpvşµ#˜Îº.UgƒÕ´´'àƒj-³âa,ÕbR.³2	9óñâñ€}³[}IUÂß¿¶È†Õ|*B’Ã7ºG§×®îğV¤YMd3Ê(ZhY•lä.@şJWƒA2ï—¾$E&1#ö>xıü
 Cªâ/Q9¨G‹(-•7¼Ìi°õ§>¡d=İWhá pºIqÅµø®½?„µ=ö»>gÈUAIe?O‡ô%»¾ÛŸåHûà¨,=wşNMkQ>À|4Ê¼²!ï‰f!¤‰¬ø‰¡ôµÂ.ƒ¬ä‚A;Äú	t]i¼ü¢îp4ñUÖ—Â¿¢¿IQ!İ`„Ó![šÓX@z*¾Q˜¬¼²À^ü'¨¢ßï’zÆK¿ANİ=ÿºYÁ$S¾&ÊøfØß=üó	9S¹CXÖÿ¶g_¾]Fö4)¤Ù¶—ØŒl™¹?äK×ñ1!¶§aı‰ ÃğÁFQN1Í©
„Ò>ÏH8V–]ÏÊ"t
Sv«#)îÏ˜÷î2)°E^wÜ<+“kÂëë²²•ïÏÀÊyÔ:LyÿAÒ$å… xî€cC›ü®¡‹œN'wzı)„òÖS	/³ëÂİ%mì¢L¶è»ùÎˆ‰"·ú¹ß¨-9)iüD ™ê¿Üo[ZhW³ õ®ŸBİ)YQSlÌT$tx³ÀİødŸ{‚t™°iÜ-n£9d~’Ä›3œè?Ÿ!øã‘/“FQµ"³¢,ŞÛöHQRÛ×x@'†zUEÜ¼$TØû˜Hx—´Ë‡T ,¶W^)®ÖöÓ6¡5§áoz.°Ğ¾ô@=4øœ½OpoV6²4¼QÑ ¯³œçõb~?ğ„A>w¤M†—ùëËìÛÊ²¤>õÿJ<
©v(ÏàtâF ]nv¿†^ZŒ³µX%”yvíDG¦ŸşVYCx\Ûï#ÕÊ~ï9ÿPÄ«A„‡€’õY%Ë—Î=·˜Ìf«ûœİñôÀ1,‘¥C»dz ÂTö	3Ò®Ÿ–f¼å¯r%o
,'
uA—{¬ß(ò‘Ñ©Ò^"œdb®J-Dü†a`~Ï«n8`ò8…ˆ³Wçlã½‚¿‚sûµÜ§ºj~[wõ3„
Ï]Â ³\3×!ÛØÇE-;Å^ÃƒšwJê_í›¢ÀA£’/{x‰=*%Ñ®…ª…üŠÊK€ÍtÀF$ƒ¤¹»çÊ ƒ tŸ@‰×,­ÊCïâ®ÒÂ ,^½%ÚÏÄÇ[v0V3ÒŞ^ /ååËq×7İ2íaØz±Éôt–™àŸÈ±q‡,*”ùÑ-n²×0ÃKé¬ÉD(§êF|{ömm‘FÊık’ü„Hğ2ÁúE$‹š‹Ë¶”mÔ¶g¢Ç£i(à?
¡<¡ËT*ªáÊÔàÈ*
QcfİÖtvĞ\q|ìiX$^Ö»Ş~tX
? Å€–EWk­h6E 'j×âÇ•ê;L¾`ßşŞ¯°e‰Åj`ÁE~©æš}‹è^ƒ¨%úÉ,ºeE/}R¨İŞ3nÙo«Ê}yÊß%J4"|-zËé×9ùÏ€ß¦_İs9l' Áé‘b¤Œ_Ô÷á=+7†.JÏ½ÍÆ|Œ­ªÃ?x,?[…2áâLLğÉéNoZ?LĞ}§x-ï2r†LWïµW?‰%{11‰qF³UŸñs'poJN(bOŸ!«.Ác£º ÀIêÏÿp}êªD÷CÙrÑı/{šh‰¿'—Ÿà	yÁ‰oR‘qf’H`ÇŞÓiè™0G~H£ØË¹xI¨VĞÃò¹Su…I“ÂVõÍN§0¢°İó¯@:H€9j#@Tú_œ5ËRù°)µôI·`\	‡ÒáMó7Ä'ŞhƒƒpÀ`~µº"ŠÒê·9¿X¬y*m¨v¾cìù2ìj«K·B ?r¤Êÿãúûê!âñ ĞÂ¸-É-8($¤Mø÷Ñº‚Ò›Ëİ:²‚Ú1¸N$¾²»#?Â‹áCm·®×&ù•¤}¡æß¿õ§ën¾Š„ùBø„*º®9ü%Úl¸ŞÍüD²kß’|ÙFaÜKŸ–¹Uß|~C §ÂÈÍÇ_ØOkí7KÑf‹Éc6Aü—ñÉ¥kùş}³¸½QŒ@eó1|øH9ÂJŠã¢¨J I +ÊéõMà+¥æ$ì™§•Ú«+MzäeØMİâm“¦ø«N4±9.h7àGxú,I'bU7&…ß²uØz¯rAvR“»Z‚„»D]êÄúÛº`…ú°^­ô»å/$*jeA8JCKî &ş‹„™èêœp;àxß+ÔUBäËÅhòjT[¯ìEwÁ‚`õ˜“îÁìuqÁ™#1¡8Ï‡“vu©Ôz³ØP§8X¤3/.
˜qR€ˆ>ğÇª¹c°³nÜl‹OÚ HNìËÓæÊƒõŞvEŸŸÑß¸smÿuõ—Làj²÷±ÇÅ«ç!38©ı&üÛp:_`Ö)â¼¢ /CB‹±Z™ÿŞÅtF+±¨†ä—“xwàÈqm\¾k‹
.µEq˜„úšàN“8aRË±ÕıË'-Ä§8(²sœbÊ1aá+“]şs~à³½ûUA*q¼åyiÈ·ì‡œÙÈ¨~ÀNé2­U(YÛ*d(T—v»$Ì·…NLA(¶¾$çûœy¾ÍtÆå¿2¹Ÿ –µùY	Q.h`c¦-íün„txXÊJª*(kË˜İ¢#`Öª¶Ò(8lÒâØËÎæ&.ç¿Ú‰.óë´Í¦§2p±Ì¦‘A¹ä`İÑÃƒÿ4,(´Œ(U`Ó¸Õ¨» Ön@WˆØw¼õ}wu.2t>€/™ñôKÅ¯ÜßgJ[yš<#R¼Rµ6À/ŞŞæªQÅ[tùy]¨Oeä®É#™ú¯{•/e ›	£¸İ„®‡q|{¤ğö ÅcöWÔ»ÚSo5—±f¥_Tpr[­$Í|´ä“®dì½¼XÖ©&!µ6Ô¼Ãø4!…\«ª°KİGğ•è€ãö•,“Ùáô™“Ó:¯ ´½}TóÈ¯wù¯î*oâiçêÆá÷‰¸EÆm¡ß&[”ã¦ŞC,·ôèZ>ˆjí²Bnp,à Ô_¹ÚÁ:v€½üÿùÏÕúÖsOŒÅâûQÎC«BĞ!ÄÎ<š;Ó…\3_OAßrÍV8Û{{tÒE­<ò¾DNª{åº‡2…ã0c°Šˆ-–*QÌ LPî%úûÑ ¶à¿$Îu@3|„,í‚ré?Ô/˜(oÍƒ§V½0æì7øMó~yûÂò"µ£ÇNßô_ëbZAö6L¨ô«ñ¼6§ ÌÅ[½dÚEÿÄ‘µÆÙuIİ¦j)='(ïœ#%4aiÑFbù|6v|ÄW—lè±sŞ¦aÛ½iÑY†œŸ…¸­åYÀŠË˜­C3Ø#FP×Á­¯~/ë~ŞÅ­t^¿¾·V‘vâİb]F¬u6ğúøÖåöR>ÍŠ$¿¢ñÑzÛ§˜¹ó˜öE(~Í£ l‚‘¤Vò´
¬…-²²ªÇ+¼ÚßÇ¿ËÊ["Şô”ÆqLD&i$¤Aà¨Äà˜–ı„µÕz.¡l;âñûâjaªŠ0ExAxã¡NQ~_ß|,³¢<=¢í¤›wËZòØ:ñ_RIİc(JüxŸ”¶qR1ÍYFgQF”<ôïAt¦4‰ÇfÓFğ¶8Lx‹aµøˆ¶	-õ¾ÎñkñğĞ’f—ã†˜k<À;’-ØÓ=t£½Wí]u÷õ;AƒU:©ƒİõ1	™!'# AZùPn?ùï¨Ÿ\´©6Ç[OË dx~fF=W¾ÍÇâ(Ä¿Ğ5£òİû3Kœò¶7JOw§ï+â;EÜgä<üáCuöÊr¡ıI>ŞtLè‚ÕÕ±äà–í~íÃ& i¦¼eÿó¬'ık’`>÷Œ¯,r}dn>^ |pNwşù6¢½Ô°63ÿ·îp>k)xeŸwo	¨Šè^4Õa è;Q\¼éÜ¢AàØNáå¾)ì”‡¶;÷QvNÜ™a`À’ÉÓúêj–Z‹qG}~ƒYv£LßWŠfçßö87³®)Ÿú_IßËışi'¼ŒA¨ïEcşî˜İÑÉ±¼U!¨Õêè=%ÇšNíO:ë‡ªl'‰h5ûÁ°Š(8|í«v¹´“Å×n7™r+½ÄiNGbl´[§/6rxâukŒòo‚ş+oÚ5vuoíMÊÙc‹¶~ÉË ·Èø	ÌÁòg»\DòS‹ŞHˆøËnÍŸ´TbñÎ"õPÑVêÏ«2;8H²*ñä|í×„í’½ĞõËÑ4„ÙN`š°÷	Ö¤ˆ@äRÑ©c/ßCÚGvİ”ü®Û¾qKx;{İ¾‚pñ;\.5(5‚†´[LÅ¦hÙ§.Ò€Ñ;a‡B².º®Çt%«È˜îœ!ùXIÁVADĞ»©ŸÙt±M˜Ù6èÁí÷ÂíC1 Ì²Zã«%.|²Æ`élÃÒèNÉƒd\ˆÉ_Ë²†Ş¦)4ï!Œš¶î«R.Ò¾h÷øîöèË«÷ˆ3õ›«V	áihü%uÊŸpÆ ç×Òb=yíR±‚£îî÷ŠÿS,fE-#Í"øn“ËÙ8…’d¥q aı÷Ì"ÍÏ‘VW`7(?º7áVù9×ªÀö)g}…¿/¢İ²™±!éå°CkÉD¡/&1 viÅ<˜ÕğgÏ¨"S´’Ê2]ŠŞh!ß=¸"àH9› *&"šPş‹<z}Iê‘^ÂLfŒ:¿%5<ìòÂÁâøAÄ¦ÜZøH7èHÙÉ^k²şP¤>ô¢]Õt­a‹YXo­"
@ä(Ğ÷^Œ”66×g4ø[!Ü7®êPa¥A¶_`³ş«´í_"Wä01X›£Hk¢Ì–÷WgêUœ"ƒEÍ­‰ş6eÒ†›ı”W÷”OTœèğ"+¯~1³³(
ûN4¦ÒoK"¸B»7]&µş_ÆM‚ÒÅIâá(òOakJl%øPênÊ¾k üNZ:|pCÍq¿€ÔşVbº½&/Üı)˜¾Á±ªûÅ‹ujîR—è«ÍfE/0ÕÃØ„\°•—Ô³:ß;ìêNãêµ…cÎğ3bR‰‚ˆE¨…+û™¿ºÛŒ’!4nY{Aü6alŸRšÎÛ:IÕä?TMp <ÒKâ-ÅÖìBÂ¥`ÙîÀŞÿSR:×Û­5Ù[ãİ.Ôcø©ÍÂ__µç‚ğ×QÀ™¼ÙRÙ{<*Û%(S`ÎÿÜl†l#)xë·ò ¼˜°âz÷ğãÉqQ¯¡­Z¡³È9Úç	ä£ıpò/G ßiCÁ$±Õ‹ƒt¾ÛìÍ…vèïb‡ıûs:ª‡ëÃ—*"°áËoSp¶#¾|qÏ»…–ºÛòÚZÇÏİ0¸Ëé‡!£Ìş0±‘Ãµİ_a‘VÜÑ
Z¢»¨<ÕTE=ŸéÑCø“KMˆ}”»$øÌ-n}ƒ¥Üµš9œ‡ğ©üæUİškLI±¼á·wÔ"Ñj‡ÙçˆbÆ‘Í¥
9r‘è–Qõ¾cT|~¹ÎE”Òûy@^ÆOªËï?wvß0İ]¿¾îÚ5‚şiŞ2ÄÀÖÙĞÙİ<A)–ÀÄ©œÓ~„×½q–U`Uşìéó]ùn¿;÷«ÈÖ6)Íæ3ÁXà·7pœë}…¯æû	©V¸KÆİKCáwzcCø•?Å&™Õn°fVZ—‘B©é_:Ó|‡úÒ`¶¥×Nwİõÿò§²s§³´€{hg
÷z¦VU w~Ÿñd+Ú7Áï!‰uXVXÁƒùÿpù|y1ãaç°‡ÔR}ƒ¬ó†¸WòZÑø˜È5…yT¬ÚÜ2—	èƒğ®úsUI*€wè’šÿú«|Lı]2M‘Œ¦7ä·Æã
.û‹pÿYÙêEu×n—*4ª‹Û+4jˆï•m¹=:sîäqÚ¯ºÍBz0ìş¹Š¥W2¼h·#ÿÍì ı?Ş(hâ½ îÃ˜«½wd¯î Â|zEòa_R–êP=ïNÑ8:LŒùıáOus¸ä?^¶‚QùªfâªVRÙiŒ!)j]"9ßÿ×ß?9Æ÷ÙŞ?Ã,q.ó–šGïk£èê'’Àùí›ÃjÅ^ã£|Á |¥Í[÷Ÿôc„M!ƒãòCÄg¯®(Ì}KfOLŒ>ûï0êˆ ©Ö?ZG¸õ'¸y™yqGâ [uÛM­òF¬Ë8â·E~jZÀú¾½i<}oãË°ç‹+CÁf±É'­7gXÎÏ¿İwóÓaBÍ¨wæß›âZRCîã;S:l:,Â#JIg¢E–áeíƒªëÁ>…g—¦º’â¤É*T¢M€„&²ƒ~Ûo”_¼u$×wò‘SqO¤:${¹]sx’8knª¼p°ç7®kd¡3Fjâ(Åê1V;Â
» ¿U¸ä	Ô ÊKªvæQĞË¼†!œÎù£®fT E»˜vk,ízfgïÿGñ–ˆâÌêªB¦!5 ¾Ó|…ùB'MÇÙVb+Š¹ázp?¸0€;®C×c¯f=DØ_åp¾”³êØó8â†"{,Q)NK“€aAGšéhÙ\ÕM±#DÿÆ3	‡µ×ğ'œ1 ³…Á±mÃ^ôº–S¹b†7²` íænÄKJ½\üÜˆl{Ì’øåvºM÷¤
à™¼»¯×ÜyUşâÓÊ ‹I#›¸0Æªq™åú1]ˆ!V,\`€ò¨7dHÈ§½r<Ùÿ'1¦q_Íì‡0çÆõ¬%Õ¿!á¶b)oÄşp»´@îÆWÍú¹—:Ò4ke[Ÿ~Y­Ü¤ŒI‘îláJ*Õí¾”e÷ô!æ =æš2)h¦UgIÜ-Ï¥,q~¸sÔ‹Y|Ì]¨¼/j½HÉWÏİ³ÀRœgè¶ÒD•@éŸ	õ…òåWÊ÷¹.n‘ˆØ˜Ñ¦ßË‡ÇÄíÁ¬‰¶¾ÌLÒºÚ_İ@*‘‹
¶¬b"vo¿sñ–	®Òş’
|ÎbÖÀá¾ìOuEeÊî&{ß{û±{;P¨[;ïrÔÙ\ÆvIÕÈø"ª¥›gQC%ïŞo:Vnæ€Å”¿O8Ò–ùóKĞpPe%LÇeËß¥ÇßÓ_‘»Ënàx¯®=.!"ß™m¥Z‹¢ÎÛ±[Şzkû’ªE@¹#îí>~ıÃºÈ”F©Ù%
ƒÑEtZq{ı77RÁ@ùæ­˜°†Äc•Õ«Ù¸ S}jkWòŒngÀ‘çY¦ +¡Ê
N&öCôïÅ¹:¥;»™MêJÕCcˆ(	ÍpUYÚl˜B»„R.ëh¶öéÖ{÷?ÆÈ¦M‹ûÇ)c
R)ÂJM}Eÿ"`^ä}]eM'Ù×®‡ÆÆg•Â3C ‹´o”öå‡!tÔÜ„Ø(•*ƒW!(§¥F/HõëÒ#YÎ!kbˆ’?Ïİ3ª@ú[XLŠ¼úáEHñ‹™½Š™6²¸T)öØY=÷½bÔc4¼~ê%“c7‡È=»
K¨¡ÿŒÁú’éŸÖx˜2§Ò”qm-1H
4 şGÊU2ßŸ¡â&»"1Å¸”ÁÇŒ“D«q®“Á…*æ®&Ä”¥G»ˆ_ ¶Ôt­'ào‘‡îG‰Ğœ-TõDƒU_ğ8ph<9;â¤JyŠ=E`MéÿQ—-kÖŒÏbıH­›ÆD	§v)Æ-»N;¢Q–§RÇøøE’|2"@¶½«yP×– ]«¨²şÈ¸•êİËÍ\»ù³%KìŞ±/ÊìÀÇ^ñz»Åª0•vI§7À çŒY»³àA·¥œTĞvŠ¿²ƒLåõŒtÇ3ü­ªİ|ZcQ}¶3g=³fâÑşÖ½ìëù\Hİ<Şù'URg´ï|F.½Åı™4Tºö29é
{g\±íÜk_$Ç‡µêÈÆ Z“™?Û Q{qyÊycåĞõIiÂ‚ÒÖK.Süyd_|¯S4~Ä%ÑsCÔ eÿXÔàª?,Û†[K]1[3‘§)ÜK6w}5‰£¶˜¸¼ğtOC®X`¹“À.¬\º‰¹#BOõ÷ğŸ8ì²@x³&ğ@òÓ° 7şo Ú+Ö@¢åÃïµ;í©¹«YøıóT/©+fÌ4Fğ×/]	ƒ·á¦Ÿ¤C°ßªÕe±ÔbŞ”;[R?ı|¢óÁK–êŸ1'zÃnÕ)—Â‡FK°õ†¨fä 9}/àÙíZ«Wã#xG‹Cø(lI[÷’û¬nz¬Ö÷ÑVÜpÑÈÛ.T®„TG°óå”9[ˆ³@ô¾¢;Yü k+ßwËtİOÀİi«Ğàªù‘h)\LäŒø³%H\
ÕîAòùµbÊÔøG×½Á„ıh=Ö2¥<5™	ñ|øû“sÅ8\àøğŠ€S«%†‘ğ×¿»C>ŠIl®Uî'.>’ ÌSi6Vİä«i}ƒd+ÄMNÌz¹½Cÿ‡ˆnîØ|VF¦$\b}°ôE*°‚Î½lôe8ÑY¸ÖÔºpµÑ#4µ¹£½µ¡ÃÓÓT2ğ[ìw²ıR‘â–0ŸOi…—´Öİ•¥¹ó öI_ØØ‘zämªxÛTï«SÆ‚ó5.}ˆøK÷ÑÕô)'öğÂ£Œamó¨ì±øûg+ùLwHÙSÑN*“…6¿±[Ò÷ŠßÔq„hû(¹ª/îYÔÄ[oƒ±‰É‚2¦ËRø¸B¸EÜºNÌ!qÕ€KÔth|

•[67x| w÷×&Š ü–ê:W]‡ÄvŸ¶]CøxŠ\Òá"Â–l¡Ä?ï~ER–s9éâè1ï®(‡+¬<m.üÃÀ1qi`}e¶üz DKÚêZ»t²–Gs$'²?JCàğÃªF‘øOba‡@1åårÖÑ>æü,-”Pı™TÏnà)³Ûl9õ#±
`ÊA¢ÜRò7…‰Oè£à*ŸIQĞ×g1e×©èwkÿ{¸2….GÂå>=”¢2¬ÖÁNÂ=}¬P!R ÿû Á‡T6(/¶•FÆ¦Ó9&ÿ¡§£P‚NhÑb¯@1c·‘Ø–àä¥‡g=³S÷ÔÀ†çv9Í««®Mt4ŸT¡—ù„‘58“ oağdı‚äì÷#ÂBdÛ–RnØÇòİ¥ÍÚø°ï™€ÄÀW‹¾8‡JDÖ=ô¸éü‰µ±¥È>©q‹Úë
 æ»’[³kÜã‹ø»rxÙóSpÓ_è}jLô‚VÍ©ã!-»L³íúõPBJF’sû.ÙC%ºá– òUqY…ƒ]ñu"§ôÉ€û’*37ÔÙ5LG©ˆ2®»^”f:ÖÛ€…Óñõ!n²¹?0	1—ÎÂß¿ÏŸ¬R³Y_¯×?ş´†¿,dÆó×A1'`¥lÖm„uãqIÖRWœ­Šh§C@š¹O×}‚’h›$â¸@K(×»ÅQ%DÔwü¾Tc|\¦CÂ÷L‘ŞŒ^r¥­†3šáÿf^[0=%™§GÒííaP jaĞ½Skt6ˆRÅP¬¯uLÇlnëÔ”]İ;©ô@8û9åOÃÁÂ»]jŸ#,:l®ßÊ'fWçåÃ£¹¬ÒJj /Ä¿“÷ĞÁ>•\›İˆsò;.@DÎã²SçUß_<™åı—!…-¥
4İµoçü¥C|IÑnú±òÕ>N -ï÷°6ó¿¬zÊğäVüäæCø;3±W‚W…ÒGUûfZk.üÜR½I·Tæ?s)Í¸=ğË	†C%”_ğŞŠ“¹:—~íúá]¾DÁ_ÎÂr*Hü°a_ àötr¡QIÖzèo^×*s_²õÏ_Ê¦)I /ÊVmAœŸnX™JEY}BkJæ2HšŠ±c;s\0oğfÔªµv¬G¹²qGÅGÔ”§eúeãø@°;Ÿ*IGğö>”üÉe· äŠÌÿ.:Ş-çÒaœ#©z®ş«Õç¦l)À–‡ÍD!Ì·èDÙJ€âÉ™]I¢²ğ8É\+ÜEfÿ €˜é,5¡õû)hì&çØ4Ì¥¬-("‚Àæ¨bÂÖÆâ[(;†Ç”.»p-UÍN›ÛˆÍï·Ø›£Võ=*5…BŸ+ Â9@]€±:ãM†N³8Ï-ÇNkWëÊ+áå‡¹dëÜ}ûøSrg‹¹7æ}½Iîæ=ÍÕõô>ìQ¸>42’%ÑV`ë
ÆÍj–ùÁšIÛŸOé‹`ãápÚ¬h²F)ZÆ¤wÔç£k7iİó¿˜ƒåÔ—‹!kÅ¨Z±"öŒë^{ú
=c÷¦7¸3àd›¹ªãfÈZz˜b¨°z7
©*èò[Åk-¯(ªrÆJ¸m8”æöº3bÉ•Ç¡SQV“ş}%_Ü? ±­öŞ¨j¯í2ƒ%ÓpÃÑÔv<7+¯¡Ñ_ Ç ÚTæğe¬yU¿P€øÔ“ÉF‡ëÍŸµ/¸Jû.*±;v=¥S»£-8Ç˜qï¼*¹áI²µP„yo±T±;êb<¤n„û À£‹¦	r¾ÿ«ì-1lÍCäp–àHİ¬pPKÙ['„õJğÒÛiñ®ÕeøwWN½ñ¹#8›–6òİ~ÀrÖG:	’áY£ÉÑ ïõQçõ-4³
	j†Ä’‚İ4ï¢¹ADB0®–’iÉÇ1ùEé_—İ?ÁõõäôÄi†Ñq,J¶3c’æ)ä2GŒœ³·sLÜóty¦Ù	HC¥î“‘uñË—ÑªwñÕTéMF†9(ºáè‚ªí!QÁÓÆû‹H.XÚ7»J`‹M˜A¡E¥­KÛeERS´ÜU&Ç¼9¾Py¤«íw´c§S÷±Tığ“©r¦½gòYp"z;ò¦i¬ˆ~I·Å¶6w·›¼¿å	çÖş1º<šk Xó¦¾è;K·îº%Ã¥<Ò]Nu`¨ãı·x‚Ê¯ Ûl\fÆüJÌ¦×HĞIÆ!X]İ‚ãpµÂÖˆO¦@OÈ!§çvjˆTZrìV{K¼Q´I&Y”ñ1E¿Ğ+ƒ8âÛA¹ã<´ÔR<½5¶`*Öb}ÌI[#æğÛ~Ó[›b*ÿãjÃ‚¥ØC×Å’ÿÚ"ÌC·lòbôu[Qjv5ùÎf[ÊNXãæók|èŠ³ãkÿÅ¦¹³ÒBLÜòÁGkQÍ RûÒéĞAYLôË(¡b]~E€¤t0bÇƒQÙ“Š²›”İ57Æ1È['Éj“TìIÿ}öy­îMQå£É®y?xÇ¥(oîôg„ Şë#Fş&lR	än®s#\’¼÷>µ,ª^«±0Œ©ü–ä)N-sò7U¥QiÜæ…Ï¿Šğ~E ihøL3„MÈDm‡¥ËËZ’f€‡{ú¸ñuM‘Õ@éñ•Ïv˜(o³.ñ›)†D!´w—Ö¦CûáJùæõæ!“›",©`Ø‹QUÓø‘G>K;öõW1{&p
ØëS\]iOæ&…aké¹©œ¨¶}(ˆ£÷$Q)5Æyæşv´/¿5Ä?m…,/Ÿ³4¿n¦ŒJ›ÿÎÀ¾"$âÚ@†,î“iüáªÑe»birZ™Ù>ğ®~ü5Ó‹£,ûuÄfâÜ«£«4Ïòƒ`e²Iš²Ñ8Es,;œ	ˆ¶ıY3t‚Öôwê#§ñ#G¶Ä\*êí`En2&ş½;™¦éG‹$mB6O±™ıcÃ7'}`e<ùòWËÑkm<;ã%”g‚uî©^ †æ0‘È¾øY
..+úÏd­Œßğo³ù _&èƒ¥v3V÷í¢)†D1å~lwJ”,›7*L!ŞèR7«íÖ}çìE†i0v£ñiB€Z°ÛE3)ü’É{ñ·g™İêQ!róoqQÓÅF*	–Ó€ÑİæåÙ=€;
ªİDÔIİBºÕ»¾óÂBÎ…k2	66®ê£½ï‰á†ZÍ±Ñáfsl7ŠÔh½ùÑÚK^eÅd³XMÎ²ÖÆ½*Ìs´ĞİÅóÏ¿È6mPU^OpÕSÒSùe3dâ|ørqÍp£vÆ­Xhşox4X*³M¢é“RŠru5rQ,ö¯tŸ55À4J†ØérÛ8T;¯‡ n^ş
Ü±*Ïò~KÄòwİ*Uè¼¸@zQ€ O—M+(ãşìJ/Ë9¯ÛtÔË<™œ¼L“‡ºxìáû"^ÎrŒh!®M—R°ğ·
üs`L¤Î‰ó-!!‘œ†baêñOİnŠƒVé8$«æÇ8Æ
èeŸÍO><ÆoZ÷­²o‹h!46Ñõ’myü•…{#æX1Ê²’ü?sh«§¹F@kó#GTæ-à’¤ ¿†‰VÑ5º,àf4/Æ$YİA”Ø†¿ÅW@W‚•’é“·Xqµ³Jì gí}yy€ÓÒ]ÿîeÅŒÕXªØ·ab¿Çkö(õ€i|h§ÌÀH0R.2coñ²cY­òß0>UC–Ä¦~ÙÎqàvr-^«z}7ş¾8qqÒX#Îsz%h?à„Ê âdCîq.Mò‚¿ÒL:úÑ~Ddâ£ŠÇ$õ %¹ŠDíÉßj º)¥¾üc¶C}Œ@¥QÎ™uÂ"(ğP… c‚ XîTOÍß+*Áq‰¾dŞt)<,¨DÙÀ^ã9Jl _–ŒŸíVÅg~:ìç5œ“bF¶îgš¯‹¦Ê|b€…Uï5¿Õ‰Z€ı9 ™#Ù»Îİ»1õ~ ßÑB‘¶›¶/e2é~iHYÔ³¾5||Ê?-•5»G”˜>xbíÑ~ö{a)4ñŸrV>±ñ­Aé
Põí¼Ì©ÖLggYTŒ˜ iæ`AWb1NÔš'KÚ+µ´¹Ê½&{S Ğ)[l8pD¯‚y¾oHkI¿’á/ÒG¡Óåµ€cDÔ£U¿ƒeÖ€â!ÚD—-ÁcyE£ÂœéËşˆ†“ÎzÒµnvÊğİÒ4WG#ayÆ`m½¼İğöÛÆJícp bh$t¯Hbbì­ˆÁå¹5dºUŠ›el[>—4‹ßQ Ü…;Öî·ß?Ì¶3şS\"ÛàsUãTœısÛGVMÜ÷¾Ê 
ØÍ®œS?Š[<O=w<zrJQä…-ó>¥,½*s]9,j…Bvùîı•ê¾3jW¾â%ÏËIó{x/u9øc¿Úú'?ëõß¾P_Ó}àc $ƒR,‡8²|¦[½MvøDƒ$Ñ’İiw¼‘®/BUš‰}=â¯ØŞwh¼vº.Üìµ+šU¥<Ë‡SáÁ;SÑ÷ûâÀE(qOE¼{ªÔÍU„§ñª§;ıïÕİ4HëQ––´dÀ,tS(š˜ŒBbyHÜÚq
ŠR`µ¨õü;Ë}4B´‚?²ÒE!„Ek‹•’Ê&3Ò¯%y[Pd®yİó4”MÃ=—[i;h:G‹àˆºÌ¬‹PCTHKRDëíôĞ'øTÄûiFâı°'y˜Ó÷Šó](7­1u
`ñ$'EK3"·IòÙU¡J»~é/5Á3Ÿxãf¹cA;Vwê:z»`Å}#$´ûÉ2Â´i¯¦Ò®xêV!¢ªû=q²‡¦…Šbä…}Ÿ,­ôWŒ¢=SÂpæªX Ú‹ş»‹ˆÇ¹-…›‚äïèçà7e›Ïp!
³mmÒûÉµw>œJikÎZïÜ¦K?eÆ¿Ğ˜OV”‚æ2«hä­êråùÛF2æÀµ¦“pá½+tÔù«"NÇ4pŠ¿’N' oéÇàÛ¢§›kÌVŠ$Æa!õ¤Aıî*
Äá*?ïîĞÈdZdF]sg>­¸óÍ?$tfş,±ÒYîá˜8yF¦WWEjÑxğ¤N"'1—ß0ÍÇ¤7}JCÊ'ğ“aÏË~à¸÷¼GÉOğ#ò ¬$	‚ñ8çïş¢q~ve"@ÖÕ•®{Øeä”ÀT‹YÛÖoMXtWSé^qS‰2_­0jQ¬œ“…FİJÀ¦Ü¦ğ(k†eZOähKtX˜î™\3o¬Â@ãk¦³?}è-54^5áª²Õg…O¢aËo™iúc0Áşœ Ç„óM,Àw–î³°*ÑiíyÁÕÖG*„`•ƒõ¦<õ`Ú)i ËD>ShÃ™LÒ•ãÜ”‹ûê=‰ø‰'ª4 ‹ñ¬¹O ilPÅë„V
fÂ*wêûW1¨¹Ê«Y]âhf9ÉíK8ä%‹¶[%bö”ÊÌ(§HóÊ˜r%Ì¶°`Ş­p.7UÊTCÚq£mrûs‘£o­2-4X÷Í—±s¹òMÉàÎ‰ò±½¤Bçzqí4~ •KÔÉ´^ œP¢\%7Â…Ä¿s5z#‹wSÈŞöÍM½!2Ê	š~.1¾7Çêv·Æ=Nï›ß8Ÿ
ÚÛOÜ£¥¸¸Ÿ’7,°æä°WXRtµ3l¶1KV9sM…ê0Bâ+è[íg¤{Á´cš~^>ôp­qá5÷ãµ9IC%ßç°â8b¡ï±j%êÜiCê×xÒ¦Ëë‰2„»ö1És{ dòr‚«“ëbí² ¢¤õõ–ÆîÅìÂå‰Æépw”Â"OsÁ’{L²~kotnpVÕ6"—‚aJ.øx¼é\ğ¾¥9e¡|ıPúğå%üÿ¾îÁ8êƒsŒóüæw°¡%tŒéŸn±³ÌšØkR¸ıÍzNÎáCXñ>®ë¸ú¼ÁËÍ?X_Y|8”a°Èç]'¨ñ:‡Ot"Õeê†9tYT–ø—@¹n=…=4z!½ãÛ`½7­åÑÁC¼ÔM6ì­¶ÀUÔq¬f¶ÕaÛI„«î®lÕ?ƒÓ<êÇ"Dûâí|Ô=¸»Û"ÅŸ¤&Ş*?Œq(ùx‘Cîå:¢Ua:¹û `/œø_ÿ?à7­šØTgûÖD¸÷ÍE7ùeœx¿QC~n`*Øşb…Å*ì—<Uà r©§õaèmÀçì²­ú{—äà»&7™‹Nœ QßRÙk%}QüN¤]~ŸşN@y¶ƒsÊmMBl,)~ŸŠ·Ÿ[ùI¿2å¿Ñ½‘6Kn
Q™«)‰Ì=Í:ED£,>ŸØ7j"h-Üë.ªàJÚ]*Hqı\ìæ±és8,›ä,Ãï…O™Àg®Ù°‹oP7Ìòºù»o|VyÛË	\vâ“¸nêò±wÙB0¿@¿-KÛ~€à*µ¨ï©4Ñå] ßî¹ğ:Á3ô˜‡Í¨šÆ©|4PO£1šcô1"Ó~y©l>AvEú*g\[=|™ê6!Èlp«Ø-øß‡è¥¦|ÛSœ¯D¿’Øs •ï¸:’ı‘~Ó¨{[ã ØÍY~±¹+ı8Ç³Q+$v‰NjŸêÓ¥°Ş_«Ù¿DŸÓÊÔØgk˜úÿ;!÷5D²iUôš“«?æƒíÓ„'ïMQMÔíƒñ½„¬~ÏãJoˆÁ›¤vkK­İòæçù|ä¸b©‘Ïj%ÛYmòç^p?Ys4BPõÀ"ø0GïP1-§ßi.pN†%˜³¶@«£b0ßÇàÔxDĞ:ŸAUÂ ì¡.(¹eÚº»S)Uæ"}1öş= ¾®1Ğ­âäN0²—ÁÜl7ˆ^ƒÅo(C–%ì5k–²œËœ³ymåy?©´Yç¿ïÅ†‡ #­hÍL)OñOöÍJ-šgR&Wòk]·œnuÌ<L¤ æ{®Wú}Nš1"Úk7k*,àwóÇ¸@90v;¯mõçT`
–ÔjoyÚdåzH iØì–¥ø3Ö/øï–M"¤-JÌ§ nâñÚM³şÔõT¤£*¡"ØEàÃŠ}8+âš“­¤¹hW(]8V™÷Œ^ë©È	µ£”CµqIÿBs _ğ^fJm´UËjÒ‹˜g/Şo<·Š)²Ïı ]­Ë¿Ÿ™Á|SÉidıÉ&ºÇŞ)!ÔI]ì¹WODt—Î®n?É+V¥Ğğ‰Ùò‡ñ6BT‘³Ñ¶DzF«Rà±3MûuˆÇ0Ÿí:Zéêó˜†méé)¯K‚\X9•ò"Ímâ»¬gq¼Ì3yµˆ¥ù.§™£Ş{‡®Óâ½¦Iä¶/Lš²Eç­3Ãş6ı#Uù‹‚ŒûQJğÙZ)ã¾œ_Ü;æçº]øCr¶æ­ì“ŸäUŠÜ4.7Õ(¨Ğô!àÉX£M¿»/M8»âX«5fÃ¦óRs@›4Á½ËÃı´cQø}çP" çcUĞ6Ğ›ĞyÊ9zs¼Ó‚¯&áİ"åI“~›>3‰B°s¾A.0M€tºL´bs,tò‚€¤×M?İÑ~àn!±Ê‡¹©¶êoW”ä¥¶HWÂ³x\)Şö^}ÆV¾»E·¶õªİ
†ÙÅŸÉÔÑõËf £ŞA±ÏıË­šIL§“nÜ¯m’!I*‘*.	g’Õñ`^×­×õgc^#-ÀRNjŸH@FªƒŠâ°ò_VJ8Ëo[âe7¢cD“¥n{êiFk‚£¤ <OˆùrMi™Ğ-/°¯¢LÄ¤Š?ñ©ÛüQ€¥P‰Ò;u´ÿkö”3µğ
åA1'•ËÎş­3±D7ö)9÷áxGÍi9qr/6f® •ÌÊò	˜¨øÇÎºÖĞÿ'©ÄÌW\,t½x«š¾ }ÿäüßÑg­Ò/«ŞYúoH¶®FÍåbhÍ’hİ¯Ó²jÿY‘tÒEÒ¥ìLÃ¤°¬7­¯/¶¡(ÃÔ3æQ¬âzj¾‹3Õ(Äˆ¾¾Wæ¨İ¼Ï×ßÁˆie-K ØqBá¦éøĞ˜Xşéù!ÔêÒi½SIùBÿZıoíŞÄ­"JêZSE‡q	˜©‘Öüi²ª-B@µS7>µáµLÌ»Â¼ôhD£jºàfĞó"@>8p®ıQ0¡”[NSæpµ¥…¿°S}"%w‰İyÌ±«H’â¢¥fÂ}‹„¬é¡;,·U6a_şóbõgF0‰¸­ÌR&è~öH*0†l¿|Dšk7â:´:	›‚˜}7àŸïDĞ"P‰æÛ¯¹(6n·ÿ ¤I 
a   Å|k6“KC òÆ€yIÛ±Ägû    YZ