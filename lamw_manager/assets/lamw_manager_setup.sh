#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1623668604"
MD5="d8c90eac2cfc5c92649eb377e6b09b86"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22720"
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
	echo Date of packaging: Sun Jul 18 02:16:08 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿX~] ¼}•À1Dd]‡Á›PætİFĞ¯RQÙ…µ`Ø;× QœqoËZ{Ÿ6q¦Bg%\˜ÈÀIíSİáõ°"$1;ßÚ6Ï£6bw•m'Ïl‚šcŒºµ£[ŞÈKÓsÎÍå¬€#*q“V>ˆóÕÿô@‚§,¿z¡mjm2F@1õRa"Ç3Òà¼Óq¤µâûè’P’(~ÎÙë©ÿJ&?5°ìš—ñ*ç;:8XÍ%7r¿"½íí™‹¾j’úHÖz¡Wçi×ãJ²2d"²>†‡arJKaŞùÿçRMµÔ2ãÁ„¨$eµJÛé&Rà£Î`tT'H"“¾ akàŞÅÂ„Rçâº¢ëq»Å=)Ki%0Xã?»HŸo†Æøõ› ëÃ2Ä‚İƒÖ5]Õ„ìñ’I[£ù·>šñÉs°‰Qnë°;Á³-ŒÃ>÷¹£Ÿügg×dÓ
’^øÌ¶–w^¬|d‰1}co\QiõæV¡ôW½xú_³Å(¯„8E¸SsVD°czCw‰€ÛÁşL6 @ıLÂ?‘'B*šDAGL¤–™Dy(RaÓqù-Dºs\èj_:º6¾Jõ†æ'Öª*ævû—/'¬4GmZ3OÎù#Là	8’Œ©3Õf´áæ¤š©éIÏ¹ëL’Ó™#ñ»XĞËSïåcnğìq”Rò jÙ Ğ“Ü™®•<¬‰‡Buá"Ò®şÎà¨‰‹à<ã#?~ÚÅIÕµ*c®Rç ×‘8.cª™rz?\ù4ü5¯óbUu­Ï’ ^*¡ß2ï'É8{gâ·ôùË>ûŠúò©^adÕ1ÌQ%^íıiAª»Uÿ¶ãm0€ç—xYVFÍˆû¿Aø3´wÎqÈ±È)ÛÓ•Ş†©pÖU[¶ºa×  ¼Î¨äÌ’!Va!÷)² ¦ù ^~²7Ô	ÜÇ8NÂÙOğû,wu½HSB‚ÅàÒıRWÔBk¥ßXÁŠG¶bnÉ±ˆªs×½õ Ÿî”ä	H{8|·1¥Í@ø[9Vø’=Ñ`†äJ˜Bşü G‚^-ğZ±û¾ı1;¡Éâ%¸ÿUªøpfv½aZ³'.£QI0M–ˆUG=ßR~İ¯¶¤QfÁ‹²Ÿ?ºÌ|Ù!øÉ‚ù¾
t¥•éÃ[B
ô$Fz‰¶GÿR´fÓ‡ÃÏvƒ³B›y‘-Á)««¾sø¾¤·5ºõ…kY%I.=f»ˆ¾NcÇ©õT˜™Ïõ×dxäĞÔ¦qHñ™-&ù½ÿ£Àô{¹pÕVŠH¸A€5õ6Xi }—ú‹–ŞZ{úsö}†ƒ¯i«Œ_nLz‰«ÂÂªG>â»ÛH;lù\Iá>™ÔL¥A•3MmÍâŒË¥Ò)V]EîÍÅÄwöBÛ#)‹%Çü	Ã…™\m)º2N®Jİ3sD·Ò|Kw¹~d_¬º Qægºíö´âUIx^o‹½ğH÷›í@Ä?FÒÏQ‡‹|+3‘—Ãªğæ&Cúİt¦×ø‘:…/bPpŒÿC'Œ[o<f‚š¾ñ´Mxêz˜n¢õ›Q/Ô£Î0UÆîO+P	I´:P‘W›¾B–jò³;g‘ (ÅüXyÌ/±yğ‚ì¦s{–×Æª…2cÏÔåSkªàEu@Äú¹’şoµ¬O~Š5¡ö¨í£ŠÃ53Î@OK ]à6œ‘WÒz3‡^Éb¢®•"“ÿ›â”´Èd4e2ì¤Ö]û®²Œ˜+×ã—PuÉ<¾ÆCõº`­1“–”qV=ğ~—1ÖØ„v§¯7á€<9dìV$UºO;™¡ÚYEl‹¨E±5™éGµ)lı2;=f^&uí	P_o?¡KÇ˜?Í•©%.\'r”ZŠD0¿ø·y^ƒ±šÿAáØ¡jUóW;ğ>Zf`ære¡oC^ã|ˆQs¹ıÌJxAÛq1^ı¯ß£_ö°M! z·¬%ó1Ğß€î1ª¬a[!ñàó1¨¦Øù<ªÊ™ ù)Ë¥2r÷PàaYæÓ?…EeÓÏÁzÕ!û\k2$S@VÖõÆhZ‰˜+KÑÇ¤2œ½n;)3î``çT´ïZ)ºş;7h¥ˆ{!†©Üp’…=ˆÛÂ»€’`'ìµ“‹©1\Üdƒ˜zò®İ¸¾¥#ş¸M.qzl»°—o;•Á0:³»q¬Ï<ÓhZ(8£aÁnãKrMŸ©»K1Ö½0u:Ü¹šÿÒŸFGí¬ä6Á¦7’qå£Â_76,¤µ#F*Ä·–Š@¡]…ébÿ™/û‡åhJ¿=õ@İXA]»,fyicĞ†!>v{(.sÙbøïQ=×eëı‹znéŞ|±bZå`|˜ÏE¦¿¨cIëHæSADòßœ‘ÔÁj&ú`¤?—ü*pı¢€Ÿ«}ÛÄf÷õ2Ow‰4¾d­“C]Ò
Ğ3—ßÙg5Õ8‚§”¼–	"X(ŸsûYbœ¡fÚšvˆ]Ş%Ù˜ÚÛw†œó7'‹, <Û°Øët¸ñ\™á°/Ê©<çxx¾™®¢¾Px¼K@¤uKí‰ĞhWÏ¥>†Ù\Üê|-•s‘®ÈÁ2ãéÈ#&¬ÉMÙ²^“"ÁèkËO=ºt7·)T8DìY™ˆNÃG
úçÚÎNÎÓ'˜2:¥d{’/|ÔÑZo ãˆø¹_Úâ4·W¹µñò>ªPÄŠ°FeĞî°İ¬á#‰u ˆŠËK‰²ºxáÄdL mbÛ´ÿTë(hìŠfH8|hü®y\áïŠ—iÌMúÏ N'ì!¡´Õ”Lº¶&Ûk{Np¶#µü<ÁNÇNú½¨ÏgÎ8h—‚·¹´	«Ü¥&Ò]ÙÅ+İÊ±TÂÏ «ëå'öRªó¥T’”@HD¤÷ˆ	æŞºD´ÍìÒ;WRl‡iägßKªV^&™w8í_İ†-¥Hb©ğÇ“áí¯¼¹q“;¦+5¨‰îcWÑ€º4Y™‰~;Tü/½Zk#Ny&e4˜`ù…’`ú¦„øØÁÕ}XQcitl‚şÂwŠ”`ô#>/rIŞ`ó3Üıü€Î£¹{¦Ö0ÈÁf?–U:¼HÁg¿÷ËÚ¤»"†vó1ï`g]"3bª5%{ÄRÒ°³Î&Ã(ñZèöC.m¸Ü?P7w*Zt\~k_ÊƒRí?#_ÅâRoÙ(p„P2x! Ïa…-qèón¢ªÛEïûö¨5·¼h«U`u4|à5;=¿pmzÛNé¾rĞwØÓ
ÄNÌÏªW?S!ÅpüF_øab‡šx>'@–c`Gbû³Îr$œTjÖ
kÉÑK|£M
[ëõ—úÓ©*Wƒ™Óïß‰jxËD8vÃùoù¾Íu`ÁYî˜&e"YGq†Èÿ‡ªÌ •Ïå0÷ÂCg$—¾“	lIØ'‹ú~¢8-~/8ó#¯x"Si’MXKÍC.{ÚÍØíŒOŠ‡º	DúíR Rã5±‘š!‘sùzÑ—Ç*ñQ±i^Ì€`¤DÊ³û˜©Jî.*P¦è\c•6Ò7rÕë'ª³%àÍwÀÖwn¹å¹Š
ÄĞ,ÿEyC8—íÎjè“óÎŒ=àñ†Q2:ë	–íf)öfy K;W”|ı¾\…;İ0q„†[Ò.*ÃjÅYJİwC³‘ÓVkkCoŞÉ•gşŒwA9ú5¿>aö.Õc—¯ƒ@ßÏÖuôôPqÒ˜ûá¤NÜï°h+üƒT2"#%æ­Ú +ıö5—¥¯i„5\›ƒjlèÉƒ¾¨WíÏªI;?^à•áÍ¡ºûZEDêÃ+?Ñ×,Pì|W•”5ä*3ã¤Y¥èæÕîRéÿ*ÇP0G6ÈQÍ|*éB„¡C°õ¬BÚsco*<Që-
|ğJlàPb4½MÑÌ›
YE"©
şùEâ~tİ~·–È ôÜ¢‚œ®ñaŒ†Ãjsk‚Liñâ®ò$éâu@¡E'SèŸ¡q.io¥…ïMÌ}FØ­Ê¥±Şüî,‹ÓügÜ›~©JåÍ¥Pååqœ@éz›´W7íô_’À¤ÿÜïNÁõÁI}ÌEì„¾¿ —ŞÌˆqO'šÆ¦‹¬*î± ëCwµÜ•ş0)˜>À¹ bÂ.âyç5ˆb£()zÃz:‰Æ Û<Àš¿÷%Wjé‹\¦ˆ
Ñ«0ÊÍLì·pô—1£XáçÄ![Õbª¿jz× L¥WO.î)R5Uò½&“ì“?ó†qõî‘cu‚~Æ$½e¦SMİ‚J2ÂÌÊ	Ú9´P4yVj…:ØÈjét-Ö,RÏÀøÛÔysâÏtÈûSÓ‡ÿNšITåQFY¢>¿Å WO†( ”¶)Ñ9¿7€íĞhßcâ©1İ¹Ÿ4‡×ÆË¶
WC AÆUÚT"Ô$®[Ê÷ÀÛiÃû|² ‰å.»W‘€=‘3éÅÍ¢G_tk§WÉa±Û­m†4ŞÑÂ üœ[-?œ&ÏU…†gåHïa&$\êƒh”U÷|©|1ÉÖõ)ã¾Æì¢Ì&tğıB\$%ïZ)ñ€KˆE¤U-ééµ@&ø˜môÂx^ÜÜ%Ÿ÷foíQçé„¢„8İÂ$Á¯<è;ÅtQ0K;°‹ƒÜñÉÖÑ29lf»²³Å4?'óÇI¬»$©â0¯aÿ!(Ç;Ö]I £u]Ìãù0’xj·Ø¸Œá±§Ú@µ:l>_WİçX HàØˆê‹ÂEË–ÊríQ«9åëeÄ¯^Enğ)M?Š‘À¼Ëø»PÚo>¤"[4Øl§…Ak¥¾c¢ÊøÛ¨…ïòÉÀ1©EÀá|œ>YgQ$ÔÂ%SƒXSlµÑÓg¼sõ/-</rR¦6kzt¥ß¢nÕï,iİ¬8aåÖ¿à[^N)Õ"â¢^‘úŸ95Z»ŠŒv¿×kO§£İo3f¹éüëŠ¿° Ò@	gu@ôÉ8}ê9<*T¼«°'í
_ |.n<ÑñdˆCÒÀ” é:¾bŠ<¡¬†a]§jŞÓšrx u öâM"Àœİëª'áÇ°ŸR)>Í™® ô	¢TaV®Ò¿ˆå-Ğ€NES	™©7÷=NÅLßQ¦yûáı,æˆÙ¸šoŸ¶Œrh¶(êêr*‰3ìV)ºÜ­|ùâ4ùõ/‰¦dûC]e‘ğª ×•øÂÍe@,!/ÃìÌÏ³DÜ ÀVê†µğYÂìT}ÕÈÔZ—ÆH¤~ŸÑâ¿ s_yVK&ÜU4Ó¢¡w ×âÈÕ‘-–…WÒ”¸¿MÃ‰©»…‰VWÛÎ'ÔGë´Y¬uáñ}æ?Ï™ëh?fªm>‹Ø
—–Ü'Öncµ\X]Q™iñÏLöÄvóİoYÖdçé¡Û‰ûWÄÆv.úå­ïà[÷‡â‰öğğ:TncÚ€…#oŠUzÛÖ¡ç"2Ï[şcG`¤2¾í0²«ã÷ùt¥Çë±ä_•™Ù|W¤Lb Ë_½ë'ÁZ3iüä­~"GÊ§ù´“Õõáùj;jdÜÒJxHÎzíÉ=n«Ìª/K‡ÍÃYÕÛ?t>_{ø¥Z o‰Êü«pFÃ(è	9åòô„™¯ÈÛÙÙbàkìhrä¨7ŞŒÍRänîlM¼Q|J²sûeñ_»á)<l–V<Äı&Î^¼+J+…Ëãõ}7·XÌë3íO›…?Dú¶¸õN<“o¸:º„aú€zügmRR§ÉyBˆ¸ÄEÓF§îr·Ò¦—ä*p¦¹¸Vì2Nk-5}†\²ãVßêÚ1É-¤
™É8Õz§0>ô€Š?BğÕ&ñ$SòÇ¤H¤ÿŞxĞœŞÿPòç³s¿ç åCC2ä"£ÎCRXD4°Å“u¹-x±ªOÓlg¬µZ¾S÷á”¦ö‘ÑÌæ”˜§I]&ÁeÜh†³WÊ“¾Tµ~Û¶MºÙ™Å¢&Tdİ.Ÿ"ûøœ9³I…±Ô/ÔçÑ&+O8äoÓ"{¸%êĞ!XM…º Qã~ısfïp…ÙI¶ü…q©i’§"Š·…¨éàd39ñ ‡ß±:LHÑ›Å)õgf¼nlkUup×wÓş÷İh%>YĞ'İ+\)í³^b’$n–®3ı-
ÊZ6A·1ë/ÕÜô2Íæ‰¹vdşo›ÖæDùûW3:…ÀTî¯\*éF
—q;eÁ„Xß¹Í²?s(qìÍÒ#Éa€¿W
‚‚Šø…úÃ,†¸ù-Ñ~Oiá0½ïgÄÆRËŒ!S@›¡¹ñ^í›;cõ:ì’3EÇÜv³€¿ÌÑ+É»:uÖÛµÂ=új‘öR¤)$‘Îd¡Tæö¼ù¿ZĞ˜›‰"ÃkÃ_K%|O\'wB\Ïn²2ØDr³=%·®‚&âöƒËdÇ`½Jp)Á³{ø-‡¢R`½¾¸ö¸WÖT€*ÒM	,Ÿ¬Ark(ƒ+c{¡ë-u–Œa…˜ó¦Ø¿ø2*1¸~€‡:§ïM‡d3Àº3	0‚×°]ólÏì«EĞÛm€Úê?q‰æÖyÍ«é(fÎµ‚V\^é?ÈqwÚlËÔ&É‡ùéTê{ãÇ²mAÌ¥ƒ…Z,Yf¨m~Q¿¶‚RDXAŒH„Ûü,ñ“óD48ÂÇ€îJyªlüÂáÍúŒÛ<õ/ÖßnCy Ë@Éb¯'Dç†Äu¾f'•­á€b–¦ı9Ã“i´œ†bš) W ~öª¤rÄä¬è}5±¶€Jå,o¾ÓŒwø éÜßFMJ/¦¼ >c¨!+ØÛ,?úÉ1ƒ1ºÄ™4I6¯-}"ºBm-]û÷9ó»ûøÓË““‡³¢aw7J}7ÔreäJ­Mqj¨ã’|G°É™Zğ‹7Ö7–›#§r";wn5Sï½úq	ƒt#Ë/œ:dÕ_üÿãFt Xãá§¼Ô
+er 3Y¬ÍŞI\‚mOm¥ác"¯~­ı¦ÇQ€G@áU?i/L×SÀ­1?FÏtz¼áš\_W›\dm5›¿#qş’Ô§.Ñ¶¤2‚ÁÁCÿÊáÙuü›ãÍ_rvÍhDÈOs[%«Ûç„RÂ+?ät„¤˜¨'—{N½M¨Ö„Ö`‚»Û,=©#6gŸŠpÇëEfÁ<~lc¯Bt”÷¦×oR< f¹öti?¼ïˆC.dMî©%åÿ%£¯¿v†ÿİ°-âWŸ;I³ï+XÒÀšÁdä·ør.@k,ÙO55zi˜ÔÈJ!1ÅÊ¯Ùù½kñ‚™ùik‘}ööçÔÃn,ñíã<ÁİËT>ğ	g¢oâYaìn]¼yÛçZÏ¦ÌİşBE_Æ>r¡× •Ë(¨-Üæy}y }Èî*h“¸c6‹	Â+Ñ‰}Mû=™±Æ5D×ez¶Úæúj½˜—^¯&dxĞò¿˜@]lQëFÀ¸u¼ãĞæ‰ÔÊ†FA8Hkdƒos×^3Áä½tÑé–ìW
¹è¨§ [I¬*,ã%¥Ó7§xk®“k5RùájtÏİÂè)Gù%‚‰
¿™®5‰÷³~o_Vâ‡Áùô¬|!×¥ÈhÒ6[#YğgÄÉGÿ?9{ÍÊÁXGÓ±Xâq™¥JØ	ÿ½+õ3C;˜z¹bÆpR&nyQdÓMiS’'Zzç…vİûüYÓÀ”5¡§æÙ½ıÌŠ(Ä?u¦Ã<6 mª¹÷7™&%ØxíÃ!?Gß´Û(Yû$"AÎØ4¦ß¶ß|xŠ^…«¿æAZMÌIÅ>Æ:á(¬Û²Ñov=1g	½}ú´İÖıU(ˆì™8éÀ^"ÿŞà‚Î{‹¹Âù”e–¡[sá,¨Ñ•|¤¤p½sizÿ‰¬®¸´f5ódšeNf°÷ØQîšÂ7¸U¡«‘Ëzã› ç‰Ğ¼¶Ut4‘‹Jr6"V~½^Õ•Di•
3º£‚e?–j‚•}÷°§Ç».úìYğu³E²Yç%¬öÖ “œ£qÛ¶k::PÚøÏ0k9ãW'Pâa®"‘;h_êì1å“Õ©¾’FbPy¯N³"Y\y.A¸–!Æ‹Z’OØ²jÿwîR$Âñ‰_]P÷ßc¬6óoX„ƒõGù0o	ğ¨Ø6G mLÀ5àöpÃÊgæü
Ş3¹9?ïZ·ç‹f™vg$’§5ÛiLÙ¶¿.O30Ñ$9ˆ
ÍİE‚aÍÎÊEää=æ<Äª«ªAğ’3â.PIpƒ’mâ²ş ë~ş"T&+™â(Éëè$€ú&#×SäLäx£<Ã‹{ÓK¥Ô([G”ZëŞ'Ìå†F²2à^Ô¸‘õîÕï¾_W·q{6ôpœe;ºİ‚Ôg)ñ“ş,f”C Ñá£œòú°t-&»<QÖ×%}‹Ìıò·Äoı„ëmş@ @-Ÿ¿[c$'ÊmQ¶ó®ç/8‡5ÏEÒ 1Ğ½]¹]Vdk/“XõİñoTÖ”ÈÚ¤¥µô‹Ò8Ò@§*ŒC¼Y™`¼ò¼‘thš.–/Šç!ó¯¯i¤²úÛ¢Å*_i z1;ÀiŸõÚ*5nƒv¾4¢‰õ2Í	MÏúìäÁÙÛl¸ËB?P?öNöWâë›Y¥jş¶0ØgÔCí£ïü6E,îYŒ£ÊFZ•uÒlÃ,\hïáÚdJÏ§úS6ƒµ|Åuâ´ˆÿ¾”Û–Põü@7ƒ~O‡ŸŒêû]p—’øğ>Âš7KŒ—9Â,D%Ô´œÀ@ûÙCÔ~+º^»ÆK÷æôs¯-ò¥O*¸´\Áj	­n­`>HãJg¶¥‘Ûloô=½\â~©BŠÆF=4i»Xw±v2¸58z }ôAªTGfÇ¨õù=CiiQÿ¡ÙBÂJ"=o¸%‚ÿØpcd[ÂjT–šg‡íÉ'[LX“!‰ŸezáEFğ{wŸSu=ä(ÕŸhó/•z˜ÁgÈÕ´©ŸtÑrsX†&‹¸@P“&LGµlŞ+7ÛÅÎ|€×é¬9)”`8i«x:ªk‰Â@» V4›´pqË²èpw4_İ†œãfh—!úÑl2dï ƒnlxz´1R—)"Nq‘±åR‰,İ‚ »–„x+
B ±YŸÃpÙf…u^NãÜğB¡å4rˆ÷¿]XÌy>ºBà]İaÃ%Z^wÑ=˜ñ“x)WUmãı~ÖÚÓ0³u„a(SÄ<©1Ø²zaã¿/¨Îş7Xÿİ®A-áƒtƒ½Ò‡X ¾zsMı¢?ÜÎÍøzŞ«çÇ¯o-,tøÌ1hÒÈÿĞÛ>rf5;å‹‘äx{;Nùö©·5k1ûaƒçnÉQim’‘H (¹KsŒ”GjcÀIIci:€{°»®k.Ğï²õ9Ë=Vî¨‰Û.qAa§¸ˆÒ‰’hTUq¹1±­Ğ=.ü¢ã‘.…hçØ÷“PØÃœŞEb²zvÿ¡˜½(¸Ñ^#àÇû}(x0Eİ¿:h0Ç+Tğ–ÿ-ì8Z[š Ş ß†{c·f¢PÒ2à à³“@£İù ˜âŒ+†sÇ+*™ª`‚Hi.v&ƒmœº@$¯×—ØıkÏF³’­ımh>'?BsL§Æ3wˆ¸âh¾ÿ Ú¶¼Q*Ù¹9LºÉ³Y©¦êèWaÕP(l²˜TCp?YE»ˆiò¢Å·ŒlB-ª%\Ã‹é¤ÄÚÕÆ¶2ø3˜Š¬J¸½HPï*/Ó¸ÒD¢/"O b'NõÚAü(8›f²à©SèÉïÎ.÷@.ÇZƒ
Z%WÃy_æ}‘ŒC è^P‹»ÜŠ‹,!Ã_1öYA€‰¡dÑY€bU ¡a_EZ-sã‡•5í›ç$Üÿ8ˆVh4Öó)Ó‚z9m(çºs2“èH‹0ÑW¾³Ã’5»xp…ñ hŸğ@õ;=O„¯‹mNe[HUû  Ä¾¿~3Ç{çœĞ	@Yª_o[T…û›C1¿EI(åwÍÔ ²{…	Ìfà8sõ!l¹³dUJÇºÑ§”@åj¢Ğgó…nDLhËÔÚšCbµÚ”5;Ÿ¤ER£‹xEa:è±N<“}²=ÎåÊyt•önqho¸ĞJ9vÍ)Í(1ÿq“ø€à…’1LË+pf&lš˜UéÈ„r|!ú&uÿT—¿™ÛSMB¡Eqvì™dŒ¤v5b?(ğ™v£]º´je°
¸^íG•TCßë|¥™»!G]Û)ÕåwòH÷İn¦.{ë•ï€‡Ipl~c³«ºó¢Ã“Œ»j‡K£gp
ÙläíË…wêNd ,t,7mU„£\;²¥mùfËí Lƒñf÷5¤bmÇ(™=Š´…6°[Ç¼Xáá'-J*ÑWÃÛııSüñE2™ûZÄ	º
Ã¨ÂQŞö?A!ª•bÕPJó¦#µÒúGñLuÁã8–d[íMhZ¹ë‹üfÀ¤;ì&ğ©•]†sØ)©0È‚Õ”4°"Èàà:Ñ’‘²w/4ß¾i ÔM²#|y›°Âä‡^/›dHò$[¦ä­ß„E‰VÀåc{ŸŞ‰97×©¤ºú“rìÓH'ï"Ü•.^:<^Š/à¡²‹÷îc&LÓ`ó¾%h·ÊWEÔçW XÑ¢ÑIÀ—2B!øbÈu>iåc{ÁKUÂ–£Óh^#ûk"`yX…X#ıĞ„}ß/S‘	Ş6ne¯»S	^œneïˆªÚÑ¡Ä »]ÇÔÑ^¿²ò=!8™ê¦cÇJ.¾<JvKSç/J‰n5„†í~ĞtÂ4şÚŒ¯TĞ SÇõõ¤E˜…àóœ‹B˜ÛÜÿ‚êÔ*“_ïm¾L§bw¿ê<!ú¦Í­åÔ›$Ì¹«…PĞbC5:ïì¼t™mPÜjZG}@¢ğ]±-œˆ‡õ™_NÎ9­ÔU&]‚)	 ¬­r°æ­UêZØµí	¯¼×…„¥ú:ê¼£9[½¾™á:êWÂD@]$Ì0‘VJ¨‹hòøm¦G™eTn«ÕL¶;£Bÿk°‹<®áó0$ÿ¸(nÉäâ‡0ä‡‡Î"”"IÂT›LËD4½³‚¬ˆ°5ÿ©Ui0—¡y Ší!‹ï¨¢út„¶3¢àÿÁEJâ:æRY(ÿÄ´Öò#%ï^J–Ü8½ìDWXÃ˜Í®1ºûD§ç†D›mÙ}‡-Ë—Ã„+ıQzÙX†NİdÃ•şÃø“W€ÇOŒù…ßC^Lµü”ª+õ/Zòx5@QsuHH9DğLaVuú|7KPKc<{VåYq»:ÎòF
ºÅ?9gšWÖ@¯ ø0¢†Ø‘/w­2-omİ2dèÕƒ<|{t¶²u9¡¡À|Ø}ÑÏş{ë ÊO.VI¥¼1zƒËĞlR›y?BÊõdw+;’ŒTÁG/A†«bV7y§¹5VíKb»…aCyš«İÛ˜‹A¢?ÉNˆ…µbA‰á-æÕÛbb|öÇ-šƒfÈ£AÏra©0aÇéPoŒy&á.GSP#ÌS2Œ¬ÿ`•tŸm÷²}dÑ{ß¥Ñé_QŠÁ<ÈæTŠš%|5·´™ïqÒ0bSx%zwîÏóÛ:¾®Ù§[.Iç¾´ÿÒ„ûœ‚p)cÁ†Íæİ°	Ò5d’|ğÒu&r0Şˆ÷6u‹xúUüúŞkQa û_4ou»EoéHÔ&şíeb¬¢ú’åEHšÊ²®±Ğt„¬]”ïqŸéÕÀWˆÚ  *9ä\
zöà¾*xßğE`›‘ÎX(†I­Ôœ‚FB`õŸºëÈiå4ÄœMB­«ÑogbZğ´íÑÔÆ$66Sø0Š(mŸ¸$y¤• u«æŒÌ^Ø<Uœš¦÷®ÁËû›v7+6˜;©¡BÏô¯‰xå¹¦+²NR¶AiÂ ŸP‡8=ÛØè—òQYFAùH1sHäMMœ1ú¸yúeü8Lö2jÊğ·“¶DëFg¤®4MÂÈc§{îŸçûç¨µ=O”ÁÂiI«¸BY6D»İWh'«”}A·ÖÀ¢û!ÏBÌKéIİ€³'²îkdMš´òŒR”<Ïş}¼•áõî!àÌğå|KšËsÖÄÚ8Lr/úX¯M÷7Mü¸¥6¡>`×WŸÕób²¬ƒø²q”IQ„
¶ïˆo…óò}Tr‘¯óJ@€Õiì8*‡ÉY½]”t²|ÙñÌÑ`Qõ}ğgb}‡èo‹å9/0+0…‘¯X‚¶MP7šRZğn8ÉizÍv€ÃÅçú/Ò±ÑÜ!ìŒJ£•Vï+#'b&	ÈF¡`ËĞî¾†Ùì´K°b4çZúÔœûŠÆÒš8ün#ß÷ı®›R<á}‰WPøë‡§s‡Fâ¬£;GN&—WM6üª¶Ï¼£ÔHf›İ
®SÓ˜‰ iüãü%µ!¯<!¦’=×Ô†bÇ¡0¤Uƒ@IÊ!0—ü’‡âî!?ºÿ»ı(Uç äßàà;H6É×J§
U´›bØ›ø•ƒUóp/aÁ;K¯½$Xb˜·‚ÅLïV5TXÏ¶`?ş’áG]¡ÒIİ‡‚ÆW1I—¶·*¥[I†ä’˜Qö‡dú{-vC³´ËOÆ—´¢LIÁ¨Å°06ŞPÅÏß.1r.è5(òñ@Ih¿‘)(ËĞÛa3§yß$®±]“²»Š{î6 ××%æm+lÊÓh2ÈÚ—ï`¸cˆĞ79ºMUÓSiÔ¯6‘yVåA"³Á€Ä%Úóı^rñ„söY’ò¦*ÅvÎâKu%ÙÎÖƒ%°|ÉlËh©„ôGQV\GR^¦ ®âùª¸q„âS+^…VS¥ £‹Ô!—q²†ÈK×ŸµpIÂ!¯ÙABg T®*6ÊP(ªš° Gfk°dÔ&êØp¸ÚÓÀš”:ê9Î†ÉãDfòx}di­u=ÿ`újÈ{dôx‘ìr|Ãy&?Z·q™ßÃ¸:‡“9
9æ‹[ÙÓ0k#–GÎ÷CùfpiË)“˜3£$íIÆí¸˜!q-£c¼á…}$ÛiƒÇåJfşšêl¬R™¸Mª§«z ñ×±ÓP_Ë°d˜v¿îº+¥çu|ÁßgaC?|i((€ç…-_M0Ë21G˜“­€ÌGæàßsD²šáÃOÁç¸A{XZ«Ì:ÅÿÿaRf<øá2€áÁ/Âˆ3ÓÃGx¥2ñ®û¥ˆQSÎoÁÅ‘lÄcU	¢“hZpÃæy'¿ç=øSĞ_[¸+j¦/¼0Ş®y¼Iˆ¯²éôù†s"†]Ø­×BfœáKÜ8Œßœ|Ì½®	În³¬‰èï nUj#ßLu%ˆÿÇ¾ôg9YZqŞœy"GB0D…!öéÛãÓ]-·Ó,×ëy¨9!ûC~tVè¨ïëÂ+iˆ^MuMl	egA´ÿ‡±>
u¯‚U«\f³=)Ü
TGy»¹¸«_ÙWÿ‚+û»
~ÍĞÅ ¥\ÒR}ª…t÷ó¨&±j¦a0@µ´öŸŸnZ²Í7H!³D”?!+Ç,î†PÄ,‚“&¬+Q>R¬(‡<NN:ÿú^£> ©Ÿ%ZÃ˜™dvÎj©Åc“°İåÅòà`»h@Ä¨'¿âh^yQËµüãw²·Êvû`ŞQ6†ƒd<£íMf5æ\“ÿÙö‚qCŸ;>z@šYğáÙì‰z™ÒÛ “ÔÓ>Ôó9wÚ(tlêôŞ<Ù®˜2)&íã	9iáòÂOº‡‡ùy3±qç‡6ÂÏ{:@êî È„i”¿Cù¯$ìúwJ²¨´W²W3 ùQâ”ÑøC5üÈ	xrñ\+³+AÂZf¨TŒŒ¦ÚîûÅV—D¯¾Mâ1USºAÍ
(›¨å—5Gø¶âÉ¾ÇG”ªô’ããz{¯µ0K?‘ë+oW¸ ·3"Ş_{ğØÚÎs=ÿ'½ôÊíSÀ˜É¥Wp©­–¦óÆú¼e™É"bgdÙ¼êuËHÜEEßW§gšñ}Bî.©|mÓˆÀH`†aä²ã&aº*†³Ê7ŒajÓW™¦7u.ß·–;SDKfÂ ‹Ğ¨öfG1ØR‡ü¾F˜05óZPÄ,Ëà«'‹™U?V„K¤{ÉìeÑ„ö¬é¶ë]ªÅ’_4ú6ã}¡Ë]´×…Å§ póYö
Æ™â†æÕå¤Ôª#Jb£n({İ`…• &xqÆâf·Ï¾‡¸Ô3Gô¸Õº€]I§××%Í|Ôè×ëQZÑ¤ÉÑvğ±“CQé&€ÿ4GÌ–‘†
`œm‚)š}Ïõ¾CMG uU©C¤\–*‹İˆ£$…İ0œÆ9%¿e£ÂÊòouâœô4ìqE>7ÈƒÉÌèëòşŒĞª©ÅDğ¡Õ}¸òz Ç›Í¤ó°Òáƒïi,m¬òá{K™s‘¹k:ü¯:Û¾1Ğ3s'µg‚Ö–`%ù¯RfZ—SÆ(‚Jo½LS|egÏE½ú/H¼|;hJlİ/Ô±eâÁói[€’~šˆ!SâNjˆÔYvHÑ†²…"s*ŸŞnª¼Â‰¦©wb¯DİµZ	oõV±ÎÂ.šú}©'.JÜŞ²‰XêôùX®É­Vß£]Y#	{¢\d,¨¸Òi&@Xêæúñ•<]²5õVğ³¡‘È×b"Ç"±ùÉãë®ñPÈ
´qsŠ#˜e8R*ŒéÑy ­_{’CqIğµ.0n€üÙoà‚ìÑ=SoÙìÛ#)2:y Ò¼/@^«Œ{x?²Å‘é±ˆÅG•vŠÎÀƒ,Å*,kŠı;öPë„o°š	‰Isk||/ÂÚ©ŒğGcò½ã¢[(³8yÕÛ¦áã‚#•ˆôUn g|“,Ô«Õ}`\fAK¹bøEüƒæEô‚äjäpı°£}õñr‹L@	L‘¬bîxŒšôÙVIá}ŒWÜõt[}„ÅZ„ªEáeµ'Bi+XÌ*ªSl´ÀgwTMÉ•H=ôÍÚ+¶™W
G4vÍqQ—Ø•2˜‡×–ëµ.$LoRµ:I±Š²6û?¿ì³ŞoIĞª+¶À„|ø]O4X>)nÄAw…HwÑlÕPô£¸ïš<ihî—¼âßmM×å_Ù*}µª\vÑÒ	C”Sö³úêÕ½´9Ş]@L™‹H
,:öKd°„¶Ä›?¬4í{ÅÒ	Z“¼ ½u‡{­˜Ø9Î_]güÚÏd"S·káÑˆÂ®ı=ï5suÖäaéşşÛ»^¡ÓŠ3Òv&“õøfCÊ"áè"İG\ƒöy,mC(„Ä7Î˜ TÉâe‰[Ÿäæõ?ÂÁ'­”4} Yı&Wòy¯6ÒõtP®Óãõ²˜Îs Ÿ£ÀZX‘;Ãšˆ;ÂH¼çZC{dRêÆ()$uÿpŠÌJ/†«}â*Ä–K„¢è5N¢[F£S%»m"€õ‡­^O^¥q:–Ä#sÇ‹V"ÿY†Sª5Ú‚Âø?wtGã” +K)oÀÔ>’]ÉÜvu	»Ë <GuãXûP`AßæwóÌÍ»0°2P–ß|$ÆÛYİ¾	|
JãÑÃ[¿¡l'LSNĞòêüÇé‘l¹n79óá³WÎ5á~k¾£ĞPñÌ‰„ø£@™´ÀÇüŒ‘Áaÿ%]që—F3E£e9šş‚Úg;¤ ^›n§’X¡Ô-¢È…ÌÊuDjÙ±X˜œ7üYí¿©õ¸Ü b%òDøÙ­‰cÊ×ï¸vKŸùŸLO>Æıc:vIäß­ì×›lA1#ÅW¬#Ü=µ’¥ıÅ>²ÿzN}ùøÔ Îm¿‚×–*ÄÚ‡¢a¢€+ÈwÑ¦kâÍÎÉ¤Tfô	À4İv}°Z+æi¾k3İğümˆ‹ôdF®@¬ ¼ı"¤6‰.a¢‹TZ:÷¾]Ï87÷]£ú6•âh‰%¨¾já[Ü«1#"ĞÎ_ËUkÔ­}~J“q¶Ò	Ğj¿—Vøâ7YÿGoqĞb,Õ¨=òĞæ¤ı†<±¢¸àt¬6ı÷q³ÒAŠFßãŸ·–½†˜Ã–ÂRF6HhÏ8‡•K[¡Æ%p6ı?ü4ÁB" t(úd¶uqfcÿT7—1u£ÔjCS¶à_ÉÂöÕî^ÿ¶«‡¡ÿ¦8Ÿ÷Ë­BdFíâ4^<É—|å} š6‰ü%ü×½œË;*T €°I/Ö]¯zckw	7ßi/xÙ›D·ÏKkÔÊûÚAeİš< ĞIC÷ wGJ»€ÏºËŞ´|k‘¶ÔéıßAÁ­X¥ü¸tÍd¿hÇ*Æ8\…C?dâÉ2¾œ½‚ŠÜÖ¨ÔÏ»\Ğåîãi9[$ÌA¨lJŒ`E³üïML‚š•¥üÛL…­¨û©Ï±“©<ëÆˆêqáURTãî,xh·q$ğP7iZk¡áôË2êæ¦vôG¢“’¸ıÚ¿t>|	nT‡îŞ$Vn"œ”42ç(EnJ¸šºœä.ˆo’I–6ydÑÖeH5sk y}\õË´‹PA`	2 ö=x„Û¼E1İV<¦˜8´îM6‚P:f
Q7ùajá'õ‹¾Ùœ@~"{a§‘‰‘’:4âLSñpÑúâµ	ùåYæ0>¡mİÂÆ_G8—:ípqw~šúàù Eü˜K,ŞNº™É'ÿiÛŞ-/r™Ç”ÿÂ»Ü–»£§{µ¤ŞïÒôn¬_¹W
fç­IQı¹îÀ £UÕö¦	Ÿxlç8,n]ˆÈr‚õ×vjíc¬îwyR¢Í•Ò`?`TÕ'ü‰8Ñ?u<Âáªã° ì(“a=LF:o™Ş!µºiÃU*F>•:Ì!÷tvW¼bïPŒÀ¾ê±©½¢ˆÇ¡Wg_s)jŠ>Qtx˜å¼$âÕÌ˜xÇKƒ}’+ ú;Á¤G“wŠT­ërÊ€H"dj)ûÈoV¢|’³üğÿYZrQNhˆ#Œ‚Uœw:ƒ‹#$°³«níımŒŒ›!›úün®w¾ËZı¶ƒÀÄY‡®ºâÜ•5İ
V‰-^óı©¸Ä8H¹"ür’¿¡Ğçl<šíöŞé8¶„¯ÏSDğ‚Æš  e¹õñLİ^h š ï¡SÖÿò>OpXÊ-ù=,*˜U91b§U§îró…_gÅ¦QØmT£2mØä•E)}ÜO`\"XÏ~`O ¨s	ƒÈ°·*áœg›‰2eùù f{N¡A;-{‹…p³©ÓsŒÖˆÚ@(PÌxGîbÒêZ™ş=ã:ÙÿÃMš§×şßXd<ßCûšs‡áÒÍ„ƒúÓõlíÙÁïIûÎ]ï$VdxN¡'0ÏšXQ7XÌJ-.±Cb`¨lçë€ş+Z6ß2,u=Ù:U‘˜U“²±ˆƒõÍj±+™GÙG É¤oİ—"©íâ½Ş¸ÛOqØy@g;jÖŸ•‹€‚Äej¯ÿ¯­²k„êu•Bİ5qi	„KÔŸ1d7˜etñÚ#`Ë"i)_È—fÃÖ+|Rù¨Æà}Ğf«w¤œÑ5*,c ä8œR0¿ÔŒîñ$Ä¸>»AÑ7†ùtÂ¬·ì€u/á==†lu¹|"ÄrÛwú˜ïïO$”Ù’‘“cµH .±Ğ1YNŒqØ“W­ftŒzb%ªÑwyœ>‹úi?Qãk²W 6/a6aÚ¯C	Rª¯*Ja£‚4¢ÖE-è¸,çH/VÛéŞ¡¥Ó$`á¦±±0ø«à
dƒ	ç_yÌ?Ü
7 Cå(’»áp9şˆ¸µ¾shö:Éqœ;ò»ŠH­}i3J¬v³}&õ/ÿBºã,µòerce<Å¤}¸f
©ffõ9ıÓL§í‘}ì{
>¬f˜U™óe,«£×[HEI#£®æx7WÕù¤†Œ¬ñÆ¤,½{iÑßHmtâ1
†bdTFÑâ´}¥Usú×§.pH‡ÊÊ}[(%"$µè¤±ç<K?&.¾+÷ĞşI^·[vt´ÌµSHnÚ”+Â,-€—bNJŠ…¥gæå€=°œŞ6ÑbF2¾yÜPÚw:<––í«8›KÆ¡Q°®«]#Ÿpš/§òIQØ¥‹ÿ//ç¦½NğdwOh›õqÅ,I2•0BDåyŸ“TÔI&
8ı–GAÑùúÿîoIGoiøf¹òqô^o: ¾/‚æ…T+îöñ¨ö¼ı…VN*QYŒŒ³cÚ¹v÷½ˆ‰kè8V5Ñœ×‡­yÂc•ÅóÊÁŞDl]zŞiØg#§İÑÀDÀ7›²Áp¼{hPY¸ï4ƒò‘ïÜı@™æÊxVÆ;y¥EœDm9HĞİ àb~Êµ!v7•€âBñÉçˆ©•ë•¡¤UD°¬±’¥ßq‹•_ÅÉ¬õ3º=)UÈ'D2(I‰pÙövOœHSÍV¨,PâÚÅÔÍö ç/ö_¥é\ØÊz¶zä{ØqF…2Ù8ºQ‡pde’)@p´9ùMû a‹şàiØ0Æ;Š’bÆİ:gÙGE(1õ‡4›QPƒrâG9aÀ‡{`y×¿6Ô¿İOò2Ÿ—ƒû1™›Öça¼“¦pÔÛ}Ä÷KyXiİlÖ„¨…c`VÊá©Â+!5,óÇñÀ©À–(HÈfA¢Y8Y1r5›jˆïòËjÚRœ$êJŒ-UÿÈ<æCÛ)rQà<Kã†'âÊ/üÁÛ^Û$Ò¨v>£vbÒ2My¥æmœĞC~ŞX°Ûj9YÔ©ÏF—¹Œ%¤Šwİz¬ãä €E…I“§ã ~k‘:Uf|nx°‡“¬º#Ó±™ËâªÈÆŠs7ø®ZŠãò±LV)0lzN¢˜ò:ì°8tÊøZeNTE/j®üÿæÿ“ç,Uïè´s×‘ğ9VÎ°6ÉJáí[)cOK–.u?Ñ"z–ôb~%„ş#ƒÖs!ªVÕ© ĞBÛÏ¶®ô}SÈÛÿ!f>Ë~¯Õo¬a^¿¸¸;ÃN{‰>ÚØ))W`züÆí[º¹-ª³`uÌ^Ü’ÿ…Ÿ'ç/xkiîƒAQ&DëØ+ÇCÍ÷êâÄšĞd/9š÷=£W1-&¬¸õ ´Ê^É -zö_Ú-v9×~†éÄ¤Aì×Çñ^¯ª­¤€"³\&„lÌè?ÄüÀ]€¿iølÎí‘&4 ÅÜ•ôÛÍĞlÂÔeWÛ—sŠ¾½â’£1×©­)Òô¤mÖµôêïÊ9)ÛW‡æ^À¹kW|¡mày‡çù¬DNd^èÎKPáÙ
­Øk¡œcËŞ:›¸D„@2-½eß¦Vwğ‡ùlg¿å8tuRX‘u{•Tæ_}ß+FùÁLİùeUÎv/jæÖƒp´>º×…2»!™±%3‡çê0]ê×\ş°ÈmK**JT:G²ÒÒ*Á¥Eğü2ÙÛã0T
Gæ/P8 Zçï®ÛÜõu4E7¿iá\E	?¡u€Ët‹4³;63lî‡Ù¦ØWĞ8È¦K¤ØÃ“¥C8VÅ)6ÖkRP.âÓ±Ğ×Æg0QÛ 7&Mp·ÒÄğcââÎ[|«Ckµ&o\ï g‘å¯ ™7Ä÷ê%#“‰Ûºğ¸Ñcxs«9-"¿¥ÖâCâİhcn;zĞÅ=¸x±Å×Ma³ã\ªËgB>ÀBùê¿;‘Œ…f©ù_«>ı 1,ƒñrÍŞON‹€.")m9,ÉYaà{¬ÍK‰;|}A®‡•VW‚Âî¶1nÎG øy\;ƒ·ç»lxiÇÂ°ãríï{	™ ‰9'¢™Õ4ùŠ—YDÈs8¢]„ÎñL›B9+LRutÖÿ(.Ë¡ltM%înµL21û„£ùErÙğ9¾†¤ÀÂ6šf™WäsŠŸË©ˆëÀ^XÉ×1?®øè,x@>·I<¡Æ>	6“³Øõ®X†¾‹/“ï>Ğı?ë>XR¯‰@Ê^²4Æ–ö&BÏœ9$Sˆ;/€ÌÈ
É7ÿ®İ'©¤îYü"ÆÍS,ö¬Å9Í-O,WDÛÓß;ë¦LÙ¸Û	ì$k2ıåË×û¯N!nFÄÍôöĞoj}—QkO¦Óƒ¿1eÅ¬H¥‚XN8Ï}%²»÷hDY"6ÁßÆ²U-·@Ğj-RÀ‘„I)H9 F¤’VÉ
»	÷¨h§‡5ÛKÀ	?—ûÈ­1bïèb¦ôk³ß¥„U?'†`á¾V¬ü:bG”“jV¯ü”ö¬r®^Ğ|&m¬¬+c¼†œ¡R÷F¨©Øï[äÒ\Îôàok|ÌÓégÓÙß¿ÎŒuáë¶^{(LiNXdÍğB%¸İ€i2¥ ù©È.ÒŸÛSQ9e»½%Iµıàñ9_±ÄZC'¬3Í´³}ëQñK«¡Ö€ØŠ~™Ï¾Ä÷AZÆ†m±şü½ûı@RÕªş¹§¦²Ë´—_àÁÒ=I™Ú6|Ù×Ç«c75ƒ>ŞÙ—8ºo¢	ÕŒÁÄ eÍ=™ë,ÿ*ú¤[ß³¸\ØÔ2úé•ô•¹¦"ÙqÈ˜ãÌ¸¨u,ÏšpşÿñAÆ¹jYëË×ëçÿ?‚¬G´ôì¨-ĞùiG$êş[am¼{¶€œIQH;1R“¬PçÔmÊ:¼ÏzçI¤ü¶§g°dáü¯c/!ıÑ 1axTkFò@Õl(ïx_\ƒ™j:×KH¦@x¿Ã–cVØö}!WT]Ù¶šò¯ã7ÉX:°eäTä“pPÓ¿+Zì	¥è×Jò%’$l*ä±tñˆv±“Ø¾­İÓ@¤
İØ•¬êwµPÍr«LÔ0Dú‡!õº|Gk‚;‚¤ú‚‰"ˆë­FæßTLHÁÀÜ¹O¡a†¤¦YsYª½:ïÌf:wt~… |†Š å×‘u¯²Öi.´¸µé©FÕc*­´¾@n½A8)ÑLâR±ap‹Ì¼§ü$ÇÁHÁ	6dñ©µ-'ëJáÛùÏ‚äånY¹.Q‚´}¹N;h¶TÂI	ŞÈµ&˜º£äŸO#­Yõ‹IÅ+À‰° NAêO½¾ke ôÅàhN ï=yµ0‡+œT	š}}°É©Qo¯xëmI£F}@ëş á%ŠQ	’¬s_¿_ÄóA×BC§D±4h3`*Ó'^Ô³-Zi1>Ô\q–ÀHëR¬¥ğE“å¯‹ˆìşY—İè€2«‘öŠBÖ¤Ù $5½õ~GZ‚Õ`‘èÒcd&Vf!B#‹3ª»¯g1'ıÅâ¡n²<÷=y/–òNt#‡3É•ÿhÉxõÃĞÿ:¹r©‰£ËNòŞĞÑ9àEqà“aºRh-gCî®•XöŠñY;{üZ+aÉ:ôªŞ(Zº Í¶,\şu@Rˆ¹¢Esq"P<l7[S&º7Säñay±È=3àñyQ$‡ğ³rÈÙ°;=ÍºV¯ª#„×Ç'#«ê(´Å€ïx…w± u(gMÕLÃ²9@à´eÓœ¸ËÇ—6ÿˆÈ3AÛ,:˜9¹ ùfì7&_££+Û¡£¾øıæ‰ÕıZ®›ê[Y/ıo*@	ëmNÚ€±Ô6ô9'CtÀ»úš~HÓ[ğe7ˆj÷êÑO´*üÇ!²M7>œ}áñfZoW",l‹ÑÉ·†ùf"Tt<Û,Øë³ú÷Ï	T‹qOKÌuO¿VWİàn<N¬º"5ZëVš|ŠÜÁÆŒµPùATß,x,ß¬íÁÈ%Ì7qjë*>ÛçsiPIËåÖ³ÃÃõ|vC¤ğ£¤:’
n€ŠóFºõ£–ÙŠªppñÖ´a%‡İmºì?ßÊi¯{qó³
NO.{ñÆN/¤f´~íÔß7Î iP¯VË¾EÂºØ8†²ôõ´XE-9[PˆfãÅYÓ	K.–}ÌLøÌ=V§$½[¾' Lx¶ja…T²Ÿ3²ñZ8¿T;º_Üo¥0-küİ‚…öæ®®a îN¤äÒLç.ğmğå±Z„¨uk<Õ İ(0Ì‚L`°‰îìÓåEäÉ›DŸ'c!‰Qóûâ±ÖNïyÜXÏ¼@§°ª	ğíÖm÷RußÈYR¦­ëØüzn
GcDî2ó»e–Ø@#§zR>ñÓ%°¾tÒ£í¸Üî›ŒëNÚí:,ÙÁºw´«Ğş;¶Í—Æ&¸A¨gM±„‘	ÇÈ”È.€†-_6°M55-âÁ	 L\
ï"¼eÙ1‘
T3æLØ‚_±¿‡)Í‹†ªéÂ["å_-eêsÜı'BLÑ?mïú¾ù€Ë:ö"ÌÄcşxây(q=¬0lPo¥…;!å·3¹Úç±lÇùKƒŠ…VÇÕc¢Š¶Óer2Ë´¦2æLVs£·\{D	â±ç$sÆzòÑıDFiÔ ¹õC0ÌˆZÈ„0-u†6rzeÜ8Ú×yGÚÉvJâZÙ@v÷<7{Åµ©•˜X’‡Ë)Æ÷'lQ€`šÑR¶K=ÛÒ0×İ‡&päœ´=Û&÷¡¥°ª5`£6]»…Ù¬Üº?å™äÛ¸ıš"d=ş§+§"R~$òmú‘:+şDĞqYB@Ú©SËòÚ«H«:¥J‡„#amË3P;bU$Cw
é}"Ø°5L&÷O±\xÁ?õ ÇÉ	zïœ‘e“cí/æIÕ–Ì[Â³­†NøNòéÑ2“Œ†•Ï,é;é/q‡›&“‡„üâÕ¯?Æ&G.½ÚY™Zí!G!Î.ã¡
àö©•qJÎš,MpèæšGt~W|ù{w¥>N›+2ÿVb¼7äñ5AŞÿËu1Ÿ`Ë}²˜( ¹–yB˜×"›5Å^^Óô³é¿‘@Z÷¥­ÖÚÑV¸%-oØûÇ•Ï^òù—G[ü 0Í© !áÖÒW#Xz[Š´5Ór'§N7?÷`,¹™_è$$TŠA"ƒ¡(~‚¼J-êíp#ûÄ×Ï`y "p£">[wÊVJ¾ğâ9E#í…÷± ÖS)ˆ/‹§BKKØ?~)ŠC~óÙzºğO¬ˆ®5NMRóVï}sä¬jöß8şF”ßµCÅ/L"+ğ‰5 ïÚ+\ö2·aú4e7`]ªT¦Ïµ˜´JocÊğP9P‚¸‰è0+Q“úSBdyŸdÎJ%GÊK şòaXàğ ¹fÙ­OEˆö=ÓğÎ··–&ŒÀ ñzğ£ç ]+÷¸PÉÌ ‘‰àg‡¤e)ûø„ïû†¹]÷	u3ØÍt	^ cü(­™7³|lµ¯ÎÙbŸ©ä‡5…€K½§áoºäîì‚Ğñ4jRòGÒë€$ÁÉ$°!^a²¢Wjß8'31P£úlÅ¹0hå`¡[	WäÈ2Ò8¾ù˜ù¾-‚ñAZ—õ9°`¯Ÿlãm¬ª#hÊbFR„Nzè«QKz€šaú>¸‰Æ1‚*VZ+l¬ÏÅëf[¹Ï>×òQ¿œ>2ÙÿùMù@%Wúzv7ehn0”ë‹¡¨ ¦oà¢ûÌ”qX,Kë•şà¡á&z|ÃfÇ68QœÄœ˜fub\ğÎE]lL
ôm<nn—ëªÊ ªeìS]KÎkgô¡Æ]_×³È_Œ5ğ¤<OD!*“Ş·¹´ìtz-ìa5œ|ú  èÜëØØÏRÇ°3mù°º^3PÕø«ÍHl¼½ç-´f)ÙŠÕ)qRøö"Ğ®okëlã”ÿšG¼´úd_KŠòd^b…ù W¼¯n—ì‡?	;˜Ó¤7ìÂ>%Ùå¯,7ïCñ½twt`Ş' Ó0ëPå‘M—'î¾LÁö-7î¶–ßÓ>«bïÍÏÊ8ø…4C—í‡7†ÿh¾İs´|µ‡E†ˆqs’ië	«ñÊ‘eö­65PÃuBh…†/û¿˜È¸½-ÖİË·Ömş)¶Mƒ‡&RşÚÈéŸTVæ@$m&¿<§y}–³òf{½³¹Èaœa¾O¸–$õH:îÙÂ ¼'Ÿ<mŒüv½7ÿDïn fUUòÔÿÃ$X”,H¬7ĞMÇMÚ¯è¢BÜËy¶øá„+uób*k&»Ù†U™‰Ã¡ñí«˜3I¤7t<]ú¯ÒV/}’-ùMüù¾Y†„°†¶6Ğ+$tM \y†YL	üÆ{gşõ„ŞY¥ğŸ§LRßÆa
ØùBçGîx¢~¼y»gY¸{¡&£Zû”Q.İÎ=I3çüA›ú
Ì0Ï9õ^ì®ïùS€,›AƒëKq]¸Â~Ñ¸Á"ˆò”¢åÀ @)¶–;SS«"z7ÓÒ`ò]1‰¿2ÜÁÉñx|r·evÅÈßÔÙÔ {›+‚ì£¥5éİÍOwT~Ñm_’ì½%™Ï¬ü´öğ §†Öi¶ùbŸ5º_¡Ôe[yø]( ÄowĞÁP,d#7PQş‹†1'íoÂÙYu¹æİ’¶‹£a8\A:g™sik&åŞô*ÖY0ö%‡¡}ğC”îƒèLmËäìè œÑb3ù¿ğQŒØÑÖû-ßz~*c8ğèÜğüT1´.T½?ZÀØô(¥";pÕã	¡3D]u\öYÔlã¡Ä…ãõñ_6yÀæ$»6"Å‡¡—ä¼‰øç4²L”ÖâÛÁT“ì©Û	öˆ©=áÜ¼Î|jGÓù”i@Öš*ÔG…{“¨âÚ3(1c®Vİì¡ÀÀ@Å¡™Õ«¯mÂ>?äæ=ĞiË«Ì:9'“•±2M$huoA—ùÃvÜ&#‹ÍŠãæhØrŞ¼GÒ
|³³8Sd¦â+	İ,Ö&‘k¿3Je¡ï}—ôt¢ªûìjUì`Îl]W78æ˜WCw”#C3=y¥Ğ@,jâİG’ç5¹¯ËEqMjXìä¡ì¸Ì!»¦>EÅcÓã’Š'úÎVQªü>Ü”3øÓ5Ûr«Fn@8¯
DœÖY€óÈíğıv(WĞ¡9ÃH¥ö¾G´w@E¡X²ç÷"ğ£<^`\äÖ—¥ç‰ú7©:â}î|ÿ¸&ÂÑĞƒÌ¥ğELÏ@Oršdr¨<Ç4­F²CDú:F/L©"Â3VìRST¿EÎ÷ÉœqOD7«Òğ‚yfèúù‚+ŒF×Eó~õê–‡ù¡N%ÄKô4omì#~Î?È„:JË+C;Öq$B€Š4	† 1 !ä(eàB¹‰~!~pûèæ!Y<®P„ÈBªx¯Ê"Ç´¤0Sé¡å`U£;r3™$Ÿ]^+…4WOı†áôvL/É½ì_Ò1#Ap“Şmy”3’¤ëÆ}¡­¿š5Ò—¾J˜Ğg:.šË]…¼ çEó-"ˆ"—}jòúƒÜcğ–ñ‡Ü~«C’´%‹A/[¿R ÙyÑ¶*ê!)„
´c9æzfh$¼Ì=·ŸTÙ•&´F2/QmÏsÃ ÁÄ›8»ämÚ^}Á§V0Ø=ùª˜´d‚=òĞò›rì¡v@¢s7Äâ,î(ÄZ`…
„ÀÕ„yÔóxêŠwc§fØÙìjñš¡ï†pJmÏ––¨âú]±#˜h‚
¬±Lp[õ’”‹;Ú‘?¶Á?{ôÓÖ«7¥j¬bÒZ4ûÍ ¥á®µWı_¾ºm’Ê£Î`SË’œ%€9Ô—Úf#Ï¼.:öv¿BŒç‹1•GS[?ÙÀ+š×"›l4BÍ—ü‚¢ÉİÂµÈZŞI³¸»yZ7hõÅ¥3Û0Î6\îëš5¼÷e¶Rçd¥ñYğ;ô‹àX£F_7ƒ
´Lö.,'¤š™k4Q×aCfÀKErF
»B»;6ƒË…DPÃ,Ú~F¥…¡á„,b›‰Gò³ÏE\}Ñ•Œ˜Ó}!¼_ROãä.ëXIµ÷N”í!“"Ã¥ÖÇõª`3%8pÖ=töÔ ›F>=ñx²‰W×Äí~°W²ØÊyeDg¯ÜÖíŸ ‡ß./5–•õ‘6J'âKœŒ¥ŞÂq+Éœë‘¨/$Û#sş^~¿ëJ×,¬‡†êoªB®-i§#ª’4cİ˜*JRw×3kÑ”›†ÇÑä¢’š+âã]F·ğLÏ[Yk6äF}@Å;¾­^¹O±;ÇVo™›ù‚Gc~á'NæØ!2ašËB£&Íî§["¶xuz@’Ó! iˆŸ{‡=[h*)¼Z3O•~ÇD¡¸™¨ÁP†*m›éHf]¢—D¿mça„ŠR‰TÙé9–Ñ2ÑegALço#ı‹$ùB}¿§šIÃæ$<‚}Y¤yåÇ–›ß×ô½€P6•Ë¸è¶Y@êRÎT³]yÚV X+ÄÿUu‡ešõ•±áßá,¾î¤9|6İ…Û—L=°ŠÚ°vª^=H…®í’n5ŞŠN8û~põ"?ïNÎ[ó|ê¾pÀÏo|ß1#J¨U!VíVº¹sş¯Ş§R–zS2y‡Rİ³rº8KuÕslàa*‰}ú{®Šy+²û,/¶ˆÑBnxñü89a1A97oCÓöCÜ¢ggõ7Ø]H„»Å-vcĞ¤ër Ãİ£NgÏ…”S(q‹f²­³½Úš&•á²¾±,—Ÿçï¹J°’^EŞlXúâ}÷æµ7:À/çP°f¬^Èİ2üX¬“¢ËÒÇßkPÉÄ™„n.ÓÊŠÏ !n­ğ½Èu„]SyTuç{FÓ9R³¸Ğ¶úQÉ¸O¤Æ°ÀÈâZƒR)GGk¾Còe«=Hû©¡¤½ˆ;ùf—L?5:i(’çSÏ’?û\§ÀCI?#²u'súš(ì€W¢FnrÓôcEÚ°õ¦ 
®v	áâú¡
T¦fÔaYuÚ„şßo=‹ÜTïx3™Ìl¾Û!ï+mÜöòŒ…¿©éu•£ø/0TÛù ³w„7jÎú²2[Vü¦'ïd“J™ä–CVİGØª*õÿ….pˆBõlÌ>±ş¡À")r£ºNp+Ò÷¸_ş¾š,ÄÃJBæ{…*ÖÎt”Aê«Z¬†q^FÕÀÔx.m7„¦¿É<¡ëQîÌn©ŞOÿ=ı§T½oÕ;Ï¹Q~·Òªˆ÷&ZåôÒ ¼mÑ¥‚Eì™ıx& PHá¯Ûxj­|†)á‰ĞıòØß}tÌ(>j^œÄ±¼•âäºFÆ¹ï 0ĞsQÛfVõcE,[û«gH™0ÒğÍ“›×Òa#2ä–d5¥·ûjğw+€=Y‘W/(†AèÚÀ:öÅ¯ï“GÕ+D6E.)¼@u&FĞÅ™*š"ï6'7Æœ9”º÷¬çCD`ässÇQ€†*„eè8‹Ìî×¼-•^ü4œv*å8!¹&’,½¯ áß€ ½âÖîegszÄKÒ«nİ@Ÿ’…MP§©õŸê™‰‰¼g-æN—Ô“úğ ÌÓWlš} _ˆ‰à>5B{~êÉ Š[M15ùb˜—Åcm#İà© \1•Bfy±È´V¼×¶³ìK&TQìË
ï—Å·²¯ˆ¨@ÁØkÀ¾°hÇ•X<eOñmàr|0ŒXâ¿P¯¤t*„K‡ôAapu*Š’x¿È ÀY… 6n+Šá”ËvM~ĞzxD½ü@»8 Å©Güô>N€[Ñ'å¿ğá¸gRoÙ–BM®–Ï‘cÊ²“²{«ºg7’bV
l8Iut†ãl.¸„Û’¬¾õ’IIí„¼píq¹šºÒ1úJ Û\}\§’½YgZ Ò Û­EÎDÌA|W¿~®~ßfŞ‘3× ™xDDØÉ:ÖUF8RçaáÔh9É]Sø’€³¬BÓb$òcd«´:ˆºaz‚sRG<2~™rÌÂäïÇJ–©Ÿi–Vè½´w?*OÇ˜Hj¨-+†™ÁV8ØÛà‡9h˜»~´xÔ*×	§ÒÄéæŠT!âæHÂrøæ‰Ÿ9uwãH`'í§vÿkÃùa§‰2DµG‚^£˜pêğ”R¹ùÎE)cŸ>Ø8˜¾«³ÃŠtg\úk…\“Öˆ[7ıÏœ¯-aê†M0ÜM
„ƒë-?=!
¤{q±Aj;©¢9—	íšû*mdgâjÍKd¾ZƒÁ&ŠõM©è_Jé—>CÚrú"ÕB‘x~	k§hÙbŸnÿÈwÔŠHoÈó—åS»×«ü ¢lNjaš®s6×_‡CÕÏÂ-0Ÿ™Òƒ.&@˜¥›–XÃ(¦Ğ²#í†¯soÌätŠ1ÁBò’\H¨2ÿQû.Ç/e†4Wê&êÁœÇ Ö9¤&ÌEÜ½z¹mŸ»ñì¥#|dåNáÔt%1¾T©$&Ó_LÁ
eØŠ.ËÒ)nŒöÖ(#Ä#vJwÆÁŞüïÿ´æå5ƒCıÌaª"\ıV'Ó½9ª+ 9Õ]ÑEZª¥{Ñs÷6„ÚÔÏÿí³7mÁæg4TŞTİÈ°&t]|pn¯ì¾CÂîg¼#3ìÍ ‘k*‰IˆI¸¬æ¬xÜ<lHÓwe>ıE¨G¨R¬©ÅäÂkÓ·rÀdì€¨"*d‰–ˆ2"õb\ÊÏ›îÒ
Ù
O[T¸}"ƒãj€ÒÇcN¤ar¨iò²5á¼æFÜ~Ä¾Öc?O×cÜk¿Ô‚äÿŒp)&÷ÑcËæÚ˜n´ä¬4ËN™æÂL³ş:›Á£@ŠÅ¾0¶;9^CÍïV>è(†ƒŞ’îOb®Õ)*\ŒÅ½’—S}x8ÒvlåG=p‡ı!Ÿû¿4³a¤õ³pDÛ{a¡¬w+Ú/[_=}TK—ıÁŞ‹6‰È?    jXĞ¹õ š±€ğ1øYö±Ägû    YZ