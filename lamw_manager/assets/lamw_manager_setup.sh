#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3696761054"
MD5="3732a6e047fb9477d8ec46ff3a6480e2"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22628"
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
	echo Date of packaging: Sun Jul 18 02:54:52 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿX"] ¼}•À1Dd]‡Á›PætİFĞ¯SğubÃ¤L£„0[$TsŒèç«r…xw&<äßbêÁ©G>ÕÉµ9—´¿h7€%ãÊºpû±%ÁÙ¬QçK,÷î†:ŠÀv†õC€;mÊ†=Ú#’JVÀ•Có¾Î,ÿFê€7_ıÙòMF|Ş_ªÑŒ¹MÌ=š¦R^˜[dU¨Ú”ÊÓQ¥tu½èCıÆãğ:õwÍ{æw:öŸäj¿:"—šß	P]„àÁ9\Snv#¬‘9.İpÕ<áˆs?¤Ï/vá©MŒ{G¨$_4+I»ÅÇÎ¦ûR2Ìnåü—ä¶kŒ„ÁW#³„&ö#FF­áeê†¹Ã¥eÉáè#®Ş¡×šF/K>½ŸflÇÚ4OóÖÜ<’¢(Âb‰—Z.Ç• <úÓ›)‘‹hW’ÓN²‚¸$î@·v[ZªÇnŸ·¤æÆÄz " ’ÎÁÃïĞ~“™ĞÎ
½É$Q>Zp¿±\„ÊpKÊ¸Ÿçª¤iJÙÖhó~RÆæüWÄ¯´bûjÕ Y±ºŞh¹‰i¬©ÛTaå‚ìãÑ5‚J%Ø‰Â¦‰Œ†à;*>®ëQ”ó—Û.g¯*ÊmDcD?uÄíj]Ïô¤ĞRññ)-Xy7Í|·qYú°ÃŒEÀÒ7³ãQnKY¡OÙôşãIgÂ‘-êx$ºãR•Ì™ødø)À^Ÿ-Ù²È§}´qª	ìËÍpR8ù|ƒ·z†M?CUÿ³ñêVT$œG“Ô…¿ä§,£èÅuÍüéÂÆL€áJ«I÷áÍ'¥c·<^:°ğV2İ èO¦ÁÃJ£v—ßM¶°ZpÌè2æÛM»%Eæ±!ÓZ_~ä 
äÁ;"‰ÓNsˆ¾êÖqR“«™m\¦i‘ßIctòD›ArÈiÔÏN³~=+$`©2”mÎ"üÉd%ò¿ós:¸r
$vŞûÀÁ@UqÃ+l2o
…„C'/ÀÍÜôË±N½¥üÛ ›?È…Î*­ÖoîÛ8ÅwëoS¢¹#|\Úä‹$@•gêñaÿ©EmwIÖ“à´"xd³«Şô¢KwÒ7Ï÷
Æ–îG­aê†7gá£Ÿá´ÃàÜ[iÕ0êlaóú$Íµ2¯’]Ãbì‘d|Ê…—)ø°¢5ï*Â©¬`e<ñVb0CŒ“*¤†(øÅ6V.%³[Ù6xûãsËK©€WÄÕZkOº¨¾°ùÀq¦y"RØuuôœ[’tx¹©à
çlA†i¥Øqê5ö|Ç0Ò´Úg€{ÃÌ”¼Ê×¾Ò`¥ªPlX?MW"ğõ_DÒpÊŞ~3†ËåÊ•¯¨`ÓrCw%ğÅæ'¼ëY 98û‚p9u<gÙ÷çĞêK}Ø
Všôh¸›
Ã1¥)R&Ã®²,­°g:'ût€„cÙH¶ï£œŒœÈFuFätFM¦&t+ş"c7Á+k2ÜÀğê'tBäÀôİEîàŸ'MÏ¶¥{„ub³eró«NÎ¤Y¼Ş\…P²¾ÖÄIÇE¤"4¤•ïşõ˜š0gGWÉP$4Mÿ—aØ±A¶åÒ«»¹¯Wm\bSi÷åÕ_šçµG$\xå÷ DÉşi;Ã‹AÏŸâë$Û½Ş¥ÚTÂ¸Gk\¨KR=¦†•Ó…èÙˆ·ôtì%k"!$€¥ªßœ—p—€yJúR4•,u–o¹.ŠJ–$JbEZUcMáûÛ+3³V±ÈX¼n—â’}¦ìØãgâÈì)NÓ.ŒWKDe%e±¾İÍİÌ\k¹Ó¤®Æ`sş‡}‹Ãâïúªq(ïËS„ndR)aŸi+Ó}Ít˜ïgNaq)Wäl|å~á,¦V0l‹çOËC Ñ*ÀÔ|xá=0;RLSÂİ^j¤«“YÊßVrŒmLb	ªpëxM'üw×^1‚Iôzg_æä•ş*ğ;‘²@­l–}—+¿Kuã+şô³{D³7Ï1€;j§YáÆ\rëÌE·Y=ÿ\äAĞ¶Û«Ç•£f¦<nÙáÂô­'¦ >êˆ•×qÁA¥$XHâœ1İ^"ç:Ä€]/8BÙø;ÊÜek¨3å(+'0à­vM&8å65aÉwÃŞß	¾±•ùiAşËúGsı5>µJÜšX:PâÉ¸§Æ„è359ï‘?ÄÅHÌF?w¬Íš&Â|ş€C)‡é8	æ‰!ñ‘!¤´%kf
ôúÒÇ³4+ÿ´RãŞ™ƒYİq©ÄÄ2&ÿäÏ‚	ª_NßÓW`Yp[`ÒÆ)†Æ$ç<Â!ªÂw¥ºvñKÉÄ³ˆ9`” õºî¦~)ª€i†mÉÚ 
ò
Æ„òš€V×O’+a„R¤OTš+×ƒsdg³FÑ¼SÉŠ-^—Iı®§Á.\ÿöªE|¡îO!1õÒVA¼˜ªÑÇ bCøï”Ù*UmÉRë–äİã\Kù*7-×»¸VœY—…–Oì~şÛØN¥Ô¦n‚»A“iÁc™ÿúÜv_N$g÷çjŞèÊ
Yv%¸c»‹Õ°˜3«¥€œ˜Õ•·´åÄèz=‹ë/ŒgÆõİnU6EYAÁÌ-}£åAÄËˆD¤¦¥8:’¡#vlI5IÇmuü9Aÿ:˜`ŠëÕ
"{·h+ÿàÉ(€¼Ñ¦Œ;‰zfTóŸ8”şÁôÃ0Sı¨¶¹£õšBÀşïr¯”w«Ó)ï+1ÿ =í9ñ¾ïN.Ã›Ò5–RÒÎ¢ö/ŞtŞKå2©íêE€v¨dµ=“%Ê{óS7¹©ç·m·7àcA/NŒtßëƒúøŞŒ¨¨Ì»şSKªÿ–.{â‰††Á8<ƒIjÆÅíx³Ç¾=Ër>®…÷ó½‡Õ~Æ.[–Ñ·&hÁñg%[¹4é2#H·İZÔJEH/aóøŠ–2ŒJ³¤4^\YP³ºŠ‰1­{§U3å{$¸%ê–±DøK£µıÍ>_{ØºúƒéO³d¹ËVŞBÂoš/;‹èA‚@ErpË€0ß4[‚+eN­÷üG "‚ğÆØ‡¶GP$_şß:òXŠáµà4Æ0ÿğ—]Ò£m
Á8ƒ¢"IÚX|ÙÎÙ—­O¹`k¾ıG÷â·…Ñç#8ö¬¼ämü…úØ%}3’È°o˜ÍV<ÖØ÷oô^<¯P
=U„k;:µ¤Hç¨xÀ©/˜ç–HÒıöŒ x1Ñ»Ÿ
î€ıÓDææ+YÈç¯Ò¢#ZøØıÓ-‚+:Dß>«Ø¥ #‚|´­‡²ñËfnŠela˜Ü–³œ şÏŠX¤g‰µ9Ÿc.<¢D7‚#™³âAú':ÈeíÉE¿Loèu¼©xíàÀ>ğT$ó¢ş.ó9¾‚L;+ÆoŸù¶ ÿ;~P©@¬Gªáw©–	Šj´äv¼OéKr½Wà×@öLwS÷z¶Q‘ÕùEÉ|ÎórõôrD$ÙpkIÚäÏ2øÔ7øĞ½rüÁ¤I=¡b&;”Çëô³-J^¹¨ıÂÕnÈ§ëAp3Ó&çZjØ½ 3>( ü¿OŸÇ0f’ ìõft‘Ìä3ƒb(ÍÎPp·¥ÊU '"¬Ş@¾O*Êãê9¥*Uë–<U;bî+;†Ÿ(ÙOÚŠ ˆáüH­ò¨jQ$q(jg‰ç
ÎUelœëÅ,_ßÖ`lŸÎ|ód‡]ĞæÀÿç5)™±„woæ6ÂjšZÖ®.ÿD„Æ{ÀIşìUİ’HèYRßJlŠjèf9¢;9…no¤êBÖ™şD;Ü[÷OôÙhq™’gí²ƒ:FtW——ıÿùH ——9W„[â—kµ.ëuâñÌ´w¬ímÿÛ÷e÷bóÓ¹]ÿˆÒbÊE²aÇ®0árÃÙöá˜Øy)_®× Ák/¬:=ŞÈ­ïÖàaËzeŞÆ±bÙ9‡ˆ(¶[gæÿ‹ê_[Teî¤¤Çˆ.¦Ô£Ó~º"ô›ú]¤®Ë(Æ)nEsÓhB}Ò-]1òV¼¨sŞ½È6u‰‰|ÉÈ1åjÛV}ı=fÜıK|ƒQ[z"a4¹å¶o#SĞ“ B!èé@):Ñ·ÿ…¦ô÷~qæ‹Îß+KàqêÉÚKFpº-14±ßj_Ğ°	>2¾„Äİ¸¼íz8nÿYÄ…rm>)tÑ|¡!ˆ§]›š{^…MkçSØQ±?P]Ø	,
Şÿ{\÷¨øÿ!O-k—³ßR´½Æ…¿òÓ&İDŒî¹\¼ˆmıy!´Ş\’Ccø
D]S˜’Îqc†Î‹3ß`—ÈiXq?ÙàÍˆÍH¨Ÿ Ï±òˆß»)Š™á~rgÜVäİJÓ' 
Èûã3	VÙDVç›hxÔ9y¢sı!KüéW•X
<±%ŒU?­İ`zXĞpÎpÔ¶ßø×Ğ¾m›@V–ÂÛ»f?ÖPÂCy6jfRíøñ	èàõ‰…Áú¨•>”HR.j4ÕÆÜ¬Îİ3 Bíˆì§r(¼É{ô¼¸ıÛ½ 1 ç‚Cd9A"ùr‚5
Ï-ãíHyGœ2ÊË¿NK<|á'ãämÜÒtx&_¹ÉdæÔ¿|MÊ9ˆ#.Gf@1"ie'‡È)Q•mî–ÀvÙ”l4õœÌ* Õ?©3üŸ˜aªAérh¬}İ«Dô‡ª1QíÈ±-àÍÅzE¤¦„#%4ı4dGÅ™r¿ïê:ƒXã!¦à¹¨râ<ëa*ÈÖ/b%5h¤s¬(7aæy%Ş­_HÅ´–_ôö~q”^òÌœhzˆİ&ã†ŸMÃéIóV˜!Ï•ho=¼;±pXèou‰pßFÀ‚¯±#—>ğ€6µš—XY9Òûºş|!Ë>¾°€¢_fÔf=Z,?ûSÃÚp/G¯OeTÌ°…ıœ•™ãó™	—²ø%T&­U!•íÙ…4y¡Ä•25û’ë ¨I»Š9mO©0azĞ.y[J8"’ôz+máÙé+ßò*2
ƒ‘-™eå²À¦Ûòâ»r6£y´@½0õ–é`dÖ&Ôn6òSŠ~¼>TÜøVT8("@Â®j’VB€›odîŒ^¡/-­ã½å¥kWı—ElP¼‡’jü'G8Ñüs&ZÆ“ÈõV•œ³ØzßÈ3¨è”Ë¬ÎÛsâšoÒ/ëJ}V™í©¼ãB  7˜öš[«Úa½ïµğ1œî ÉúÅT‹Y–I»ÃëeŠÉşØç!dºg!C¾û9¢1@u1„\˜¶ù!Ëc4½¡•`a*98&4]:È»-ïËÍÚ¾Î«hæYÌ|Ç'ŞP5,¸Ã¸+s#…Íí"	ÜKwzàİ	ƒù%¶,ê¼
Šoê2”å=,_LøÒC®CQP1”Ûû—'\…g‘«Â¿éá€k¼Ü|Ò™Gèù¸ÌÁ¢c [t‰'í-°†YÏÉñ/gÖè%Ï~|éõ!d¡Ù\“‡_HäØÀÇ¼¬9“ŸY¤—ïî¡$éa²P*Î²P¬Û‡1»0p-Îë*‹E",Êµ:U‰r¯"€.J–b×Ç{€¸t/á³½R’¦¨º+ÖVäĞ«ïÍdÏm÷…'å±æPÕYÃJŠõßÿCÖŒF|ˆÒOJi>ò`TÙYğW<:j¼yJq¼å‡=6ÂDµd5L…Ã‰ä¿Jƒ©Æ¹B‰hÜCæ€h¢–¸Ò“	›â®O#–!İµ#Š¤®^a>E“§ÃúÏœp=‰|4°œ
ij…èÁ0I\Ğß|4¸zù(„¾ä8ˆ(n-ÅÄMhÓ$Qæ¸¼Xš³ÅP×J•„ãÑÜ~•=ñøæè¥®eUïÃ˜>¢§Õ
L‰DLØ¹Á=8nêS‚Zßœ¿‡!>U&€Ê7š^Á1*!â·_¦€±ë¿T9²!•`[øÔ µ]{SÌ,›¶yÃ•!ªÆïãW–¥SN£•Ğ~—";—lÏêúm+/‚·ÈgîX5ëùZpî¨ı¦ÑŸ øËËŠ‚¦pœ°ê[n„éâNíóŒjTs@©«ÀXV½ÛÒÇu~Ó=’E:/ÜàdphCSZ±'è°3mÁ—õ'³ĞœEøByß€QÆK(¨¢ä~ZÔSÕµz<`ìÍ? ÉLõ:¤ì§™0ï(Ö¡ë7mÊfGŠÈI”@^Ğº|PÃ§ÁxèIÂZ8Súuä·&9—ŒWÙŞõ¼Ó_Êëùÿ¬t‚‰X2­1r+hí°ÚŒb¡»kå¼2X^®ñİ3ê£¸®¼¯14+åŠÏÉ#:Ç/3ñE¬M
}ÒÓ02±@˜}ÙöåÕŠ?‹WóÊÜëLl‘OÏ{÷;¸7ï®AvÓ–ò­«P6)İ†¡OÁÍ«=İØ^YgP`.×üig‘´
ÓéŞÆøpBó&A¤!·Âÿ/ˆ…xÄ­b`1/"»'J%¤Å*oäqB“nßÚ^`:öÄÀ:è{‰Û„3Ó¦ÕÒá?s´„ECÄÿÿOC†*Á,éÛ“§tÊ’
a‰b¥…	SGë€íâ~,œP2Ù/»Ö_“iô¶=¹-@h1oö[¦ê	ı/H6ıcÓ
>âÁÎ4ˆ#ì—×tWÉëGFè…—"³#É §¥œ²aœòş¤°ß>ãó5ıÛùú¾Ø7ı•@Œ¨µóØè†¨z­E”ÑK?¡ó¯cJ³}è3sóğçEUe°%	#„ãõ>ƒ‚ƒfRM½!dñ[¼? l{ÎüH­¬„yrt;=¢6nÃ¹©` s·lyñOİ´HRº[Õ°±–ííè·ô‹ªñµa~½…Ò²\CBäc*} ĞX×†¿2§‚îğP¸©”šöÁÛ,EèÏ‡^•JúşşÔô4{{ÚûdÛÀĞMã~I(¦²f€4ÔÒ½ÀÌÉÑ{ká½…Õz3¸.á&§lĞß{ÖeËNİÁˆR=ÍÉ¼;†8S÷£ÿ{NujL}@!9®ìB] },ÃœDªÃÍSckR0£ŸVøB?ÇÉC¶ÇwØĞ’½†AfÜ¦×¡É¿9F•*ëÇù¥Ûˆ¦4YÉ©ÈÑ§”®4æåÚï(Gú¼¤Hépk<q¼K,Hé1e;ä·l† ©C_ÿäöë¨âÌ<ùfÚĞdÖb3–â9ãÍš%OÌ°‰‹+‚ÔF#É#ò»æOİtÎ›•êjY4ûxyªlVsQ{Âƒ| ³Ğí®ífùf×€!ä¯îãfb†–ÊË‰Q=$²Ğ‚†0™M4ávy^²‰öx·… *3O¬eKûD¯Ó PÂSTß+Ÿ?ãgÅK
«¦:«(k½è…¯ülïÛ“Ô’o•Ã}4³ï˜  xu-0Ó¥eZö†[QİÕ¾ı¨òp>v¥¨#÷£¬7>8ÉxU¶š÷Â–…%*k¥bëGnù¶¤ÆEˆÚµFQ“âL€n‡nza²½½BºKz‡™=ÍKX
zäL‹…új´ğ’¦g9òÑlRáª Aï³%oAÔ[İ@¤Î˜ACÛ¡Ñ %}Â€&tšEbI×ÑÂŸ
\´I››O~	#è åÕÆœ·h¿OBÜä
šãmtÓ¶¼ ƒ¹Ş#Ñiø¿eøããàdz5ŸçBR¿u'LŒ/ºIZuXââÊµF4ƒã¨sñ—ŸğúU¬•ë4]êué"4PÇ¤Ÿ9ş^ÆÈJß‡…SA;#vŠFğ4İÅô/–‰æ^Íf#6áÙŞ"Êmc¥Üƒkü‚…[¨èÄk´{–Çj8³¨!ú*çk€ığÂ±¼C½'Rš§¿Dê¢zQ«¤éşw0˜4€I™9˜yUœ“ÎSµn B×‹æ¥ƒÖåV3aG–x[±ü)&†Ò§Æp5L¥x¬/ÁvÆ¸'yƒ7®ãí:‰àôÚ·¶a²Éå]H¤/2†‰‹³¤&¨'5‚/Ã¤æÖË¦™¾ĞkYÓæ*Ñ§fÇs‹ºT¦‰Ò™ÓEûq}Œ„GD×7–…ü>ğ~ôßq&fà¥&^ÀÅÃ<]JüÅ6¡ŠÙEË_ûCwa…$é€ûx‚rp†ÔyâW"õ%SÍµ§Û
Îæ!‰ôgXİCV˜YÆ>j*Û¼ŸY3Rèr¾ƒ-ŒM)Ä•J”§=^’éµéßÖ.‰²°6°qVÑ‰3¥°{ÂíaC”™=I½a$—Ôáè²t–ú¥+ÀWıŸ2/‘f\ÍdÔußğˆ[T¥Íjµˆ(,ğ*,â®©æªa(ßıñè`¬Â] Ã5«ˆvÙÊHl;4œKÓç«oä™ò!9ÊEcœ€(§é…G€
Óñ#/x£U.Éd4õcÏÌúœìÛ~Ğö¿WÑ.~¬ûPF Îà‹;;Ğ&rÖ—v¦z@úĞ)ò†ñÔä—ÑDÖ¢ˆ’–/p…ºzæ4gSR–Rº,gb«6j& ßŞÃjµ¼ü Ÿm=£cÂË,½r¹“V=¯R ê¬O¨g–¡à3*D¨7ÏäA%»– w1U˜73ŸS\†¿³G‚9TÓ.}ô*fÒ…:mùÁZYV­°­DW­h=Vè•í¿-Ô’UÊÍªÂñNs¡8¹cœ7üµœ¤av)ògN^(¶Mg-×ĞúÒN.ZÍ:ã†¬ÙI²_ÜïÉt	åL›n}4|§ZrMmâïiîŸ¯öUõ®€"´Ä?Y‰Ø©ÿj®2o?ÔzœÖÌ$½(ù-1ıeXZn‘üc•øşª´GdTfAúÆ)U?I½ARîœNÀ3ŸbD
Sx.Å:"Á*†ÓåıÊM£ì¾lµ| mÈÚAKbK=DØç¡Ì°üAñM#|½d”ÙË(Z^â¿˜P+òæ8¹5êB¦4bì\¦¥12ZãˆÿfEw “{”zÓ¾¥:± ,´väíN^²´Ïİñ=$cÁ.çè§.É¾D·Y{:ø™)ÚŞ îÙQäMQ¥ö¢gP—nYô/KJT1±?ÇEjöp(s2¶B	É1'c¶ãÖwwBçáNwJI‘Q­ÈQàã‡Ç@¬
CPÚ‡)’ÃK³d\Z+¯Q¿ç²­õ¼àê€È9~©¨*„SíùeV$¸P«ÜîØeA!‹á\¯A:ÆÚ ¹÷QMÓ>9FDõ¼*õØ“©Ë­jEØé·­ã·šBu5Ğ\{0‰˜Åõz]|ƒˆ)‰š5€‰Y$¥ë¡7şÑ2nÓÎÙøV$Â½ëDÊôŞ«©clB¢ñn[s h³ EÍ¶j… rş.­Y;Ô:)î~¼Ş™ì›owwÚßˆT(À‹WOÔ>÷d´'ôè‡ÓÄ %uìşN‘*¡”ñL†X…#7’˜±ŒñÀõéf ¨32'—Sø2³ß%åÄ0ÜÇHYã±!©}häæÁyğR¶^&ô_³”¡ váÏìèb0´¥ÅúÎ%FdNrPG2—vù@”K&êÀÛö‘pö$Dø¤Î¿màŞl‚!å„Eó$İˆ¸®½ô$Õ˜tyB–òö  >å²Ö]nn’ŞÅÿR±ÏÅ^g—íz—æwıwä‡?ş­Wö5Ÿ*À¤¤Ñûn`h.ä?•*ª†ÅüsvâQÕïAÄ1ÿÔjd¯/8ù
»ˆˆ\x¾	&,0-¿öŒ~äŸÇ ]<-ïón|Iò êN‘RÁäààÏÑæv¢>E©³êMãïÜAr÷¾Y€,ŠàM¥Íz¯ØtrªIª'õT¿”Ş•)ÿ¶hOòdmn5¢9ª—"*1y¯ ×èMñFŸ§˜ä‰è¬–‚¡d2:]Zü­üíY‰$pv£«™y{Z¸zÂBùy%Œ³+3ËR|ˆŸ˜îÔc3lPrÎøóëŸqNï5svã§²÷ê\ÓYa¹	!0–é\z\²"jøa¢íû†³®İÿF¥«±bğFíùz€kşÿuf^˜à!Øïó35^ MíĞğº >!Š€<Š@ÙI’–?<Sµ¬ÙÀá»eûEÅj¾úqÖN€½”ÿ¢b&Ùû@4A¼‘½Ø	Ö>Wg*©(kñìîzlA»/À-ìÀø]psºÛ	èÍ¯Ò¾%;¤\=!Ì:Àò$SÖ4!&	ß',lšw4ï—¯Û®NÈ\)è<‹+#­šue¤Ì²Şw†·'ˆ €Ll¥|ÛïVÓ4ÎªÚ4qÎı'ÒşË 0€Kç0Dï_˜ÒüIû	8mLfp‡ONõhfF"Y^Š;X¢Ì©p,åâO4ş¥ñ:`]‰`¯|5òZc¾ZÓ†KÚÆ<ë€Ş½jBg%ÙıB*Ø©e~ñÃT¦<H*ğ€¨±Q¢Áó]µo¶M]ù±_Zc•Ücx¢d¼øc& OÅgZZû‹Â¯´g97
IÜ^¡{¥èhÃ¿÷\y%u-Œ^K#¬B‚*_Q›kzp3u8/±?uİŒğ]ğº¨ ¬ÜÃÁm,_ -,øVŸ±à–”·°úÛÖ¡ğkšhµßÓÓÜT‡_‹Çh¢îò4\ŠÙ¸^ı±­‚³Õ€ëî¯ƒè²ïúv7ó`÷ZC¾Îõœ¾_cÅ.ÑtêE©İë÷GØZÌ“OÅì"’ÔZ¢b'Ø‚,»ª?J“…Æ1ÎCğÇ›\ğ LÊvä
?¦79æVû^Ï{%kËÇŠ–{ø¾îf]g”:®M›÷ìzÖ¿¥2#¡Ú÷ˆ½—Ú´9 °nmh’Ã…¨|ìGªQ$E‰Y8j`ÂşĞCùDÉ«£ZØ™Uñ‡’Ç³á"Ñ˜•û/§ËÊ‰)(ªTwdoCı‰€a7¡ıËïÒ±âfzE|°›ï™ñu·é•VY²JbÔÁÕ‡¸b¦/4Kùq“M=NRØKq¸o}—q6G­÷ƒbMáß|ı	™8ƒL(Ñà³ÉÛ]•r´”ëñ:ËfédªeEú™«‰UÚø¨,·»ÂôåÂ)¨ªÙ(Pt%ê:”Ÿù«TÛ¤ÅÙÜA¨6…oğC&?U.ø75ÅN6^¤”[¹5×G³“K9ÀT‡”8ER/';ãõÄ¶ĞÙL°M&T‡ÒšÜÍVœ´`2ÿj§ô8¸heX‚¯¹¸˜¶¬1¤Q÷)Nóò*8ÿu°ªê±…†oÍ-r‰9 Tlàªä‡`X3Å¬‘9yGnk&µ˜Í”åéYá{%`Möl¼Ü3l<âøü%ôçFo·Gû€BÅÔö€-Štq“™À[úJŠ5ˆ%B­Hõbáªf¢;>üš˜§ê¡Qaé+ò$Àyé¡³¨ VÏ˜±÷Ïèy•AÑr6º¬!¼®"
Œå4ø•5ÂS*{‰‡ş:ı,Â¼Pgüš×±
CïYÍUµä{£ë«'é7+ÍŞÄŠM·ä,U‹Z~¯İÿùhrnXq]—hşÀåniˆ§§sv›óåxcá=>àqÕ4§óæ•ùŒ×pJ€ï›<\vò%ùU-Xc*àG*;±çf›ZcI/š{µ|ª•‚‘LëÌAĞih[1’dfëF£¿{äJ]ÿ{…¼×¯­p{úy+–`°C“%6ÂT_rë¹O<»æİ;²y©•¯XŠ}•ğRñD~¦$©İ%%g>ÍÔ|Ğ<E³ïñ™ÚŞexß!Í+w$ák€dLä0òãq=Š¯ı`¶„8bË…»ğËñæjÄÏAîQ#Ğ„işäÈ¬dAä·ÖKG`/¸w
{ß!Ü¼’Ş;Eà?×1* †|ºêNRÿw4–V†´{É#.²«CãÿQÏ•TŠäJå"¸¦²‘÷å;ê>§ØxOşeO5>ß<‰ÅËw9Ïãpw›aJåu,†o²Cs5è=œ+ìÅsñ1—™´äÕ1©2>fã­´ö!µÒÍ˜!_˜N”Ógşâ¡â‡çà’ÏÏ#sıp…Ltÿ•ÉšãHĞò™!îªjf†5A$‹@rÍ‰8;¼½P%°9oõšô—èAÁõt¢£¶ETûKøè®Œ¡Î¶éür’2ÃÊŒe9ÒõEÎu'»¦ÓxR&Hâ•ëRÏC£C‘>wó»ÖI=iå *ß}Z¡í<èvp:Ëÿõo‘ÎÓÏ¹Ìty-dúÊaêŸWª>St¢GôóİòÖ)ûn¤£[÷~@œÌÚ7LÄ»,¿(lW=cŞªUªÂŸÕZ;#İ8GïÒ' ÎNŒû[z¤Vš“âJk¥ nU¼t&|şVÊQ"a½ÉKp©^9MŠI¶Jò»¡Í»æËîñI,Ç«{¨cl}Z4ùêëÿmÀó<+ç×·k/®µ.­‡‡ú×MFåÔÜa4Ä_Ñm’«§õá«õ…t=	î‘+‘œÃ¥› B¹I´/:ğB"y0¸´¿Hgb&‹;1ıîeÿñ¯f;í_¨Æ%n’Lèe¦¶ü†p/>Ò!_°“ìÓ÷Õ5#1ñĞ”•Å?<fjP!ë¥sÆ´¥UnïG>
e7"Û[”yÉÙÆ‚_·¿}ËÈLú"öÖ†Lw2›¿¦s§8dŸDxK¨ÌæÒ©cn†œ9}{ŞV_0 ë™ _÷1Œ/¾C§Š˜ùXîoäCiD³Ú×ÖÒŒªÃ:"ƒ1›·¨EV1}Ùİ¶?ò^¦Ïëñ¢£¯„H%|H‡m\¾%;ç:o^-eó»™ƒêüq?¿
ÃĞÏ¢<„[MÍó€ÉaŸ°Õrÿ°äœäÊc¯Õ]ÔÓ×
İ¼Ëâ4­Ó§9×Q§8zÏ#Ü&ÌJ@¾˜Ğü†%³DGGœ0¥¬e0ËÙ±*GÜÓ´Ú‘Ó¯åõßÀ´ê’ekfI¨³Hã
'E•–Ÿ»<>óŞK&Qoe¸Ï¹Ô×Ì ùà›şf@8„`Fh‰ãI{WÎÏ‚é÷NfÕ;–#ÓÉ›©C Ke_¡%XØÁı6ù2ÜVÌlf—ƒ§y·óö]K²`°E€­ú‰‰ÚEX ­ûm= ƒå‚%åx˜ììï¸'%	‚‰åÆ[°¬dŞD¿gÊ%Çî¯Ú¾Ï'™Í={™}¢÷^“é0s+K¬ï!#‘ Õ¼SçŠ†S¿mïÃ‰uO÷Í]àt‚öà£ñò
c÷º}MøVm|@™ŸL@]¿ c™ÄïxZJà _÷Ÿ:B9^s^Ûˆ¤‹`*íÕá‡^|ÒÁşùÉÎ\msÔ÷™!Ã D»FH·á/:ai¸à|m¢uˆœÂJ3ÍŠçrhü{	(P!áu8ló­û+gK•èäæã…V v`!ª,Ã1ì¶q¯¥•w øèº[›“CbÏ‚\B¥QKï5;2°„_zuhŞ ƒt:hÚÎ¨#!aØTÇ-ºN/ı‹—lÂ­‹·$oäˆR¾ÍDU5…ÔËÃ#Ï@¦^ÖµCÓdB	İtıVÇPøÃ»·Jg×jæ L2Y>	dšÃ„ü†‘ã0ë¸G-%µÅÈg‚¼òã/r$ÔëÁ£0ÿy6aa›6(˜V>ò¥)YA_]yU;öõ*tä@)³ìù[ÎŸìá^‹N–˜{¾m¨ÿŸSDÙ?¼±×ğ¬@f9!¡Åg!p>ú·¤ĞSê™L”â|y*JVnîÈA[kGÜ¯ÅTëdÜaU–Ûrj±%†Ş+wŠ'`äÅìBç’œ.õØ•åDášÉ·Ãê“ÚÛQ¾Îâº^[°•"Ûi ?ÃSXáïÒ_Í—oO÷åZ;Ì‡ºÏ®œ$ºÿ†Æğ½š~ÓİT›9†æWœ^±Ô„²‘QDs¤U:ôè7?Š“T™Ñ$vœz0e©uÃìhl9äî‘Ò	Ì Om¡‰£Ã'‹óÑÚˆ³tqvB¢šKÈ‘? vß#…¤À!Äâ÷É-MG‹˜ï¯ƒ5MYö*ë.eãÕ¹»u‡¿Û}¶‘9¼'Ci®v­7&Ç,u:í5%#éHúØBNkñ’cÆ”LciN†#–î¿Sì%©:z¬kŠ{3tbyø\X"Çe×õÜğ\Ÿ(flá™÷Èç6WÔ«©gqÊ!K0óVyêø ÿq–²<Åº÷v8$&T×¦©Êô_ÿ4(¶±*÷C+û²â£:7ô^ËÛ Ÿ9 ¸ïo/>S†8* Â"êw;}¨áË¾ â~A} ¾,_Ğ[¶<áœŞ3BdVÄÎ÷ÚXêh+y“o.İÁ=!¦;åe±¯Øá¶ïƒ„€+„Øä™®ºNmx)iÉnBu&¬™áœ²Ù÷lŠ^¨D+0˜:%>I£6€î¨Ê
‡–FV0ŸŞñÑ9pã}ó7/üœo$A^AQûˆÍÆFj»è‚©ôûŞ½Œ•ƒœª”ö<›±ø„ ‘Â8b­"Bóª'ä’K=Y.ü¾„ğ¶s&úD1ÜÇG;•³ê5Hõ¾Œã@–~«í ”?3;kf]r8¿öR•»ÍŒ\ã&%”H#ë*[Öhih_ÑY€ŠW l šÇ>É9ûßEå? ÇÜ”¯½#Q£ìı­FpóXÓòO®¬QåI¯‰ÈÚ\àò®#úå/ùÛñfÒÚÇ–šÉC’„<y¾kzéÖ$Ö£ÚK¢M(Ÿdíœä‡³¡Yº_%Ø²Ş®SoBÓzqâŞ‰Åïä×*“òbk_Ôc¹Ù¸ÔÄŒptößƒósGáßßY²Õ¼®ĞfféQ©¼{&^ï<Pó±P2ëMŞK¶—k1!‘Î4×N@7…ß­,'à*ĞÂmÁoL¤:zY/ÙÄGÈ,%6 6Çÿ e¿LİB8åR­êQA;qù }¶?Ş&<Ê²kˆôÊğŠ$0&_yA¼´¤Ï-öÃ.3¸âTƒ×ßâ³\à•Œë¸ÀPåºÈÈ*Yl^ï…zèËLqm9ûJÂï•ºúÓñ)wàó£”l™e¦"¯0j \z·­ôSÅ&Ç¸Ÿ¢	¤Zü¢g,‘ËáËw°‹å²ÓK-)°èıW’€²öQš€¯B\m¸uéÕôCL‡ıÊôúë¿¨°òˆ…Şà:{Wkí•eM<^¢ÇÛ›egÙÆë.‹Ä*™Ù„³I”ä4aŞ¨ÕşQˆ¥~}MìåùÛÄä(Š®û°·ÀûEZsÔŒ•”TDÃ¬´væîúÙµkıj‹©ÚQMmÕï'A Î‰»ÙÃ‡¥wš’=‰N;ı#'QÎ¯EEu½ó‹áÀ‡‰{«Un$µçIß3Ö¬AĞK¼ˆ»xÿÏ©l®9ª |@:­Mı´©éFŒXùŒ¥i8ôÊûâkSM ^·bî¨ffùF
‚ÌEâ!Ì@†ïÔJ/9™Àê­5¦b¢Ùt±ˆ'§ûÇámÖc3 ìÊÑãnŒ
ú aIºíÂ$>ó^,C¿$«ÉTMÑ  ÎNÇxnÊL©†‹—[uÔº²jùí/„V­â¯z°Íòö0`©V9šmÔ›Š>Ï«…ÂG³@g~ã+në¬·­ÿÏ0 ‡¡2éuxÎsÛ7q­[šÔ>Ó¬
8â
5÷Ğ½á÷£HY{ÒNÔ7öqert6BaŞÔH+´mCLwŸq|BşÕ¡³~\Íµè·9XiƒïN˜¦-ªŸö0»œp|÷	„¯¢É¢)˜IÀÓ˜õX/çëá 5#}ó¼«Xj`gÂ <•ë¬Ú(”n†£ÅSQ¬¡NüiÜi—Ê\Áª8¤=ùÖĞïÁâ÷yã	J“-7w¡,rhBïö²e¡÷Í\h˜OŸìßS'àÊ}eæŞ #-œ»ßµ:Ï¢ßlÅ®ì)™+ûLÅ›IsßŞ£|©2iR`¤C>f±.€†¾ôxÅ>Ë®U›è*Ò”ND~fp)“•Mseıp±´øcPN‰šşÇ~Ìİ9Ø¶I2Æ!mC0…"s:Y½8PgóBá~18}ÕR³”­_´*<À¼Æh‚Œígk?×ˆ[•­¤,:s!UÑ@ˆTÈQß(":'0bvŞŠ>´.Øó¿c	½‰Çä}<í/ÍøÈë"ÆüáPäì|+®^tî2NóûØÁ…õUB±·6VÔ‚6Uì ìJ§ø|ó	ítL»p~¨¹™ÉzXå¨ÍÎÃ•°¿2ŒÂPÊÁ=ï|ç"2³€,è•…‰ªÎ´€àİôÇZ¶ù×Èêt³&ñĞ[8c|šİÎŞ‘1¯õı?¯8î¦•^»Ãm˜8[¤jFÔ¿BlùI‘yÈûj‘—ô<Ùõ`îÖNÖÅÌFãNs¢e
ÍD\T„„hÔ>õ”îÏr‡³5©€!œéÄÈ)EkNı´!P¢ûj;Aüxò¨+ûÁÀ^AŠ]H¡X÷É¹gWâH.%^´|_B×"¨ìŞ­î¤;Å†Ç>£•Š˜\fÛ›Ò{¡>Ú-²Ì¶BªRíc*Im¶“M›LÒdğöåùh‰”gJĞéÏÓïLnSèÄ8ØÔm#‹ô  µZÁà5MÏ¿ÄuÒêòÛºğNEsİ×¯ğ®jÚ7šj/‡QWÈõıà´8$²ì•Ã4,qŞKvÄÍgFÕ¬2ÅGÍ›çÎU†+©4‡,—NŞdxhT×Ôá÷Š^ØV›SÛbu–ûï¸¿±QÔÉ´áª$Ï˜,‘Ô))Jú*>mŒ.«ÚİT&Z^¾&ˆQ«•5j#<-fz‹‹` ^ëJİ%–†¦5ïaà[Äµ¯Áºæ«ÎDk]sè±_â<·Š›ş-v·°sNY<ÅETLèàUO‡vØ€{9ccP’¦I&äøş‰À?[-şıç
ØOG‹÷]x»?8«ÎÉ|»[4_Ûò°¬°IÊá½j¯RË÷mwyGC& M¡nùCª	rµUe3`“S1XõjD“q˜dÁIô3Ò¯•ç•}$0GêÈÌ|FY>Ôé­³l|NU?v“Tí¡$'É0åW®š'/p¥ÅÃiå6áÙHmEÏN“
ñkõNÙAwŠDüäÀ¦”]Ğ5€ù9m_Û(gÑ)×ÃVµ¶I7A¢Ô«Ÿµ5¢VcG–È M@é_¯jÍ6’Œ“ùîNÑ“ÿüğÛ\XQ]&Q7ôz¢şº‰pMLı`xå]´ŸfFûÏÓÏm)Ísá ®.P†øÜXûó+Š×­WX³ÒÇ\¡±mUkF{C?ÉJtı÷¨íõßÜ_fæ)Ï[òÊ¤¤F3è·ƒåËöÚ4î^}Â›òûJ+gö
ÒŒ4–Ï!½å´€Ô„îeöä´æsœ¨Uêú%eÚÍ¢ç[Ø|jÇÊ”Xw ÀÆDâ"Ëº3ØíXµ‹áæLH4éàåÄÇ›	0Úÿò%L8ı¸ıÏŒ1¡†X§¸¢Ó7ÃDªÁQ—İz›77î‹í<À8É7t"]Ì–,0@WĞˆyeóØqR¹/·6Tz,“9.!^Ñ_Ï$Â’ZDõV»ã£Íò'åS×ûb•°y/ù/”ŠvÓv©rbÅ]*0M8Ní¤›-–VAXn…¦q´[Zèƒ¥™>Ë<V…bWğğÎêq6Œ”öø®¬ÍSë\5.’:äaíâƒmd×¾y…»‡ÍÙ²â‡Cà¾Lfux¹’3øwõÊ¾7ú"©ëƒZ+’ßıCä ‰ˆø%'¡Ñ$ÂèÃBa˜ƒoçıRŠÊB·Îôø…>’ùÚ”=åPµ*×1±
XùK`Sº¿·&3Hm)µ2şos0hâ½´v‰•lª)Qû(“VÕ™¡Ü%X®¾IšÔ™h9ôÖbvOO!ñ…‚êú—ÀNİÓĞV#ÄúşhËn’1Ü—ÿŸ|dÖ~ºÅoù9ÀBÕ2á`h¿{VÈ	ÍÔÓqPô‡`"qÙÀÓ¡9;…¡p‚· ´_u[A÷FzDóUµ2 x”ñÁZ>}ÄÜü£ŞÂÃÁ tµ½®Îú	 ¤øıpÑc)=Z#¬‚A(Føvò7kPı ¡j.Âu1>mI?Şª$=ZËŠ¯’Û:`‹ÀCŠà7q‚nÓ)§âRó.|Ê=ËÅí®€ÛéÚ6´–çcs•À¦¥Wx&½MC½ûó¬÷yûòï,»âzœLâŸ^“úçT–ˆHb’vÒ¦ü:tf¾T¾dpÁı6(r²³+p¾ ©¢ÍæÙWØa¥j´¼çêWî™óø P®¼Dû ^Û=Ù@(*VĞ<3çŒW
†ÿ±w°ÚMNÛvÁj$†Í&ëEvyJ;é¸¾Cü‰B’¿Hz±ÕèúƒôB¥ÿû€´Ãû•Œ^@Xı“ÎùT·©ûó«¯N2êN±ıúù›Õ£²‚A Hş¸ùßşzñd½½gn[`
Ìæ5YŞFvùã±ŞİJP¹<ïÃ.ÏF—Åæ.½¸ ÿ’2whç:³áŒ›®ÌV¿éYLdyì„÷úŠŞ@Ù±Raôş´¡©íŠ:1=%¿¯3Ciÿ Ik›´½ã9$á¶O/Kq¿ÌDÏ£j=ÏiìgæÆçxÌ×h²îşY—¢+c[­D²·›îë½± ‡÷#y×‚ñöË£”!ÇHæ”ÙbŠ=½Ëã™`Í•Ì³iê™Âì,}´ÄÁJ7c$í7’²Ö„MV¡ƒ
AvÓ{$¶bJj8…Ğ›}!¢®Ò$øsC£aª~Õ+ãl¾÷Ük€Ú%M3>¶²Ìsé	yœîB]¸Œ!3Nıı3€"/Ø2€ZŒ°¹˜nÓ¥Í%övÄ—x»¦2XLıËQ÷AÀ¶À	Q|Šw¡óíù¢a!?c’«9;—}³%â­ÀŞ÷yeÃÌã˜°ıƒ"e‹Jµ4p'ĞIy¿-Îó4zê¥*®D%u¸sNcSG‡ı¬<Õ&$ZÛ$aTîç”ç;GñF‰Öe‹)…^3“¸¢IZµïÔéÖ{hd½;7ÓŠg¯Oê‚‚g,RúpË¬÷£N5Ğ$Š7Ì“'è}OÒ8«ÛÙÛX7Îîë÷ÏWã®á¤‚‹,¦#÷Ó½E]w‰»OÈ^ê}¦ÔKæ‘0?H9Cùm¶ˆS>j<0¹Q·ïàŠX¢£g¼µ{Z¾Ó¼ı1ßØæ ´œ… TÛ³µåAö×ê°ğ • @i¢qõó¾•dä©NiËÂf´-†pA/4Ú^›ªƒó6ß™«ÕLdhzÔı0³‘T=ÍpÊV‡ı×-!¡JÂû‡éQ,gÿ8ı°ØŒ÷sí¯ÆQ&4ÏéDãSé?’uœ¬Ó5j,{ä£å¬ìşcÄ¸B¬&`Ë…€ûèî¨„¼ú3`eÑ`w:3dpà	§TP›Ö¥síh‚`-xP3§	SWÎ'ˆàkëÄ3ö¼Ç¢û“æÑÚ2Eòcub€RÈqçé'ùÚ*µû-7æAlõ‰A%"d–ƒ24ƒÉı<h£È¥‡Ûº­ãT8Àˆæ=›èå¹İ´šİ{ŒÊ©â@ø=ázj<i‘Ó¤î“‘…£ÜøéJê…ÆÑğpüø%•›¸‰ınxo¹óÈ™Šşç¿©×„¾=N»¢q¥ZÌ+©ÒZGÏ²e¼oäÃĞÒBlÑhşz¼Gn—€ínõ¿‚Æ"P¯‰ÿ®èNzŠ]%]t Q‹>`\cJ$gcûÓÂª4“ûÿš•7d&úĞb2Áõ_£ØĞ®®ş*/äE-ÖÙw}üµêˆßæô`wÈ×ä÷ÇŸL”Î([|y!bÙ#Œz‹Ë1ÿ:JW…¶>Ó º›šúTS˜r¶±àÊİa„
¤
íZ•şÆ´ß˜Ï˜Ô‘YN)RƒÂ_¡ß”Åè>Ò.-=ŠEâèVİ©`	İ€‚ÔñÆ„<ÌšóıÆ	[ÚœóTêR;Í—˜Ce¥å2énlnzmX¯ÊhŒÔ“¯„ù6g¯Œƒ§pjÙwÙ)Mmûä€cû,s™äªõ¯å(S¬½ğ6soçI{ı“¼–xR®QËdf–Y˜n[¤ü¶Ôèp~•$ìp¼RC–»ô8JGKÒ¦¦9Œ™<ç"@­)&Kb˜DèŞ‰-`>…+n’/HØÔ$éÓ±Vı3å±Ç³è²ºü)ÀGCOV£5Êj¾‚Øs¦.˜»!ôFóã¶•Uljë‘,’!Á‰ íÏHÕyt,ÊşÕ†âzû–0°Øiy@3½fSÒuª›h¡XÒ,Œç7G ¶çÈís'÷«ñ-p{°¢¶—Êœ
¦Öáq˜bÂo'ÓIÈhA»JäkZ
aCïFÙY‘Oü€üxìè¡c_2½p!ˆ¯bğûà¸€Ì°
tÕ…ß8z:ª8æ¡£>H™×¿(s¶ø oßiD1 ¨V¥Hr~—²MÃQË4-#ø¾¸¶
µŒn¡iÕäúÀ,KÉ éCÕ…^ÊfÏ9Á4b”$±I¿ß‰ir¥Wı³€ë¾ú€ÖØ³şDÜÄ9)DÿehX„>ƒO±¥Æl÷é´ŞöFC5'ËÃ.	`2°P÷-6ThBxÀ[‰fH%¤DäµlƒÆOüYƒU^‘Ìrª)QyfæE¶ÁPŒ{Û˜l¸õç¼0eZ‘Ë/0Í½+Èı V‚½’ù«nõŸŸ_n”äš»ÇU²ÓÅ»“ƒºb¹H[¶ö;İ7ì•JÀè\Ü[§{m#õÓZ!OµnßĞ^· G¸lŸwìÙ¾Üs"˜æipş§¡EcïèYœ ¥ó)HÖª¼:‹•zì’ïfE*é=i}½OU±¶ŒV³ÌL~BûXOXf'âİÈFÔqŞ8PªJHâæ;‹%3€âÉw“=˜²,Ü¾”ı¤¸‰µ2ÿyz#{á¦òãLÀ½¼S~ÍĞ¶EôêÜw¢æü‘×"»r*õ0½j!	›ô¤YNìvò·°SóÛ}Së–Î¿+=S¶À„¶˜Ğ±n°¤_®}ö¿p	İº&Öo©ŒCé…X¶¿ä’.ÃßŠY¤E ºxç`0æ×%÷Ó§hí¾srFk¨nd¬Kª1Ÿ¢›g˜âˆ‚g’Èr‘—CŒhçÆhEøã—İ}”ûæD/º6bd>aJ¬ìŒ´jšŞ÷‚9Êëp£ñÎ„ò”‹#İ…Ú`Zö¸©ºì½¨uÑG8}AIñsáµßo¨üEHyBÊÚ_ÊõM£W~ ‘o]s†òw¾ÒÏXeÏÇØ T¤0Ôö#<ÊÇÒ^Şvœt$Ÿúy…¥ÙzÇtŒäÄb½{ô¬-¯•È@F5ÌHå:‡>€"{‡ PiHŞÂÕDÔz‘j‘X(b\µeš¿´‰^Ûn”÷cVŸÌF<Ş‰z*³[§,	vÁAš&Ñq|Ş]`²êÄ÷’Ÿ™X/“­_İÛ¨ˆ13b¼HiX¨W^IšX7’2ĞeC$-—‹İá$lÚ6J!®ğ¾/GÇŞûÃmƒş¼jUßÏàZ4ç¤%A;?({kT@o‚“ß—ÿ93]öM
Ò0Ÿ|_˜ƒ’ıØ>ÏŞËK–‘lK‡Ñ@¦ßR«8®Kæ7ÇøUÈÇTw³2İÖ¸[Ø“gÙGÕ`¡LæK­|¡¦ÔUO-‹f‹sÆxÛiÕ†æûHö¬´×4Ğ©{²¹C{De¢pÒgÉæÈ¾—ÈŞçz
ü¾T ¤ ®Z¸¼°W7| T&·ç`—
M/ÀğqDERPŠâ‹“ä ™(/{Eåa´%*4F5µäÈ™á^ÖÕ+}Šæ^Æ}]Â)¢VãÏÉ¿û#–ÃÇuÒ_·¹Å£Â_û^%L¯<õ->ÕŞÖ†3t†·¿j;u€åÅjéâÃXJrj4ÏØPŸ;8MâúœFØö\Öó[ÛË¨ÊÊ	µì®ü{Løk%Ù÷Îí\ä—7 ’ûe"/R®Ş7Ağ[F•E|DÆ¿‰+êpà§1Tén-uÊv ”GgVo©·èlòˆs¢â¨ßYw>-Ë(úæ˜®S_H‰»´yÔ¦¦oT~s¦ÁlH¤î¼Oä‚?ÆU-îPÈ D—ÅÿAš„Œ_˜\&w™Ùäj\wIxÁ`e–[aš»Hª¨æ4Î7nıÊH¦h‹3šç…X¢MÌ°ê‹*	©qù´À¦«ı¿˜Ço€‹<ÉîÖıùòB‘ñ‚}>:>ûk± êFQiƒ²AÜÁ­÷±^Šåi“Q5±rs‡³¦mWçwZ£Ú ŠT~ˆ¢É’L9ÁeŠMı¡í­ÉïªoayrÒzCI\)> BÁ¨ˆİ!»±Ÿ;·Eåş?ôÑç2¢}«\)Ø7t„ë×ñÉú*¼tnÏtÅ8/ˆ/õÚ	¦„†ı€Åú™£º3nj]“Åë´ÅÜäô~0'¹)Éä½§MòØš†ŸãÅÚ‰dªĞå¦;ßo’r;§`õ›õ’]_‡æ"t3
ê¿¦=€^Xºä>¥2¿èúŒ¨®’ìö1YäĞ¦_ BbMØÿø^e]Có˜X.» «=D£h«l?“íÂ¾e(Â]ï#ÂxÎPYr;ÿ‰Ööt|<Ä2N2js,`ë@cFlºßbñ×½ùYƒ¦ä»z*’KC¿¨>‡.KÆ£/
÷„Î§Ÿ¡4<Aò!¯Ÿ†N tŞcf¡rŠ‘Ú0öøäÏ9¤‹Â°êƒ6E/şLPˆ9>}kéâk_«9Ï<šø‹£ Dğo•oÑ^7]¨¸<‘ÿ:»hşåEáVgbC¬Øå0òa(ÅE_¿ê"ï æïàQ¾buŒØ§"¦Ş–‹½ ™€ßÜåó	qã°ØDÙ¥—>ˆÙÀ2VpbÔ³u6HÒeÏÀ“WR"›²À¤  -ùåï(gôÈÆÀ³ÂÔøRwíäXqH´›ëûg­ú’d!_dss¤‰Hå÷¿ìßhuñ­ïıá2 òK-ğ·'˜8G>eßR¶‡u×G’Ş„ï²'âå:ñ`Î¦O$ƒ—'ÍºR^®b@V«'Òä&qhgMıMWëª¦»âb(wº|Ğ|ñƒvÜñú³6!f³ÒşÛ»c\6l‚çşÌ¿É¸ÑN‘ô¦Í'](¬Éß¬r$ÿS¥SO°gŠI>qEC‰"ïöH©æÜe@Ù¡İ	Û½ÃC+¡kµj­Cİç‡‚ÒL²›Ş’ówè¡¾hrO<•·a‹ìy*<†ãcšä €€võª) ËñŠ|äE‚-u×”§ïÔN
š‘‰Ì ƒ—a–¨£ô/~2ÜÂe¡‹N¦Š"2`M69µ]^˜Dæy­tëİúqŒœbm{}úÜŠÔÓöFD¬")Ù“ßi€ÙTáEÒåM½ó%3,Ø:v6È`Ó êDY«oõZP5ŸE8Š`oŞä^§cË¯ÅQ…Æò^9|
 ˆĞ=Ö–PJM‘¦X–ç·òÌ‹£9ÈDn7)^N¬6ÙÇÁR¤Ü8öHw‘õÛşã¸u{ófë¯¯ÿä¦×NÆ]ëüz‡lú~ßPœ¥ËŞ¹`'cûxY`AXIF¹j aY¡@Æƒv˜û¶û aOÓğãKÀ{ˆ“şñhÚp¨ÏWÍØm×Œ	U÷(›Œåñ;o‰ÏCn~£wò‘:MCî-æèıñÌĞc)ê·åŸd×hUÅN…
şÉs­	768ë{·1åHËæı#9÷'»ûãP lÖ+b
z^YĞjÈ¦
³~FvçIü¸Óß¿Kø	
>`›=Íí÷Uæ•‘«ÿÇ"?0]§t2~ãŸã±œÂDc§ä ó¦=¾`âaøDôÖ‹j7x×Ï[Ú~fÿ‹
”±iñZê–;µîÆÍ“Ò¡ğˆèB‡úï'I ¡M÷†3S»a=WŠûYxŠhA=ĞV¬D#‚’‰aş^jÉ MdRî{púw&`Ü›²ò·c]×âä=¾IC©Fd¾
õkŠn#z7»ŒìßÎT»
Ö
e¶'®ä=¬4<ÀgœÁPm•ÿB‚]?½^Ô‹İè³Éo÷+=ßX
p×Áú©ˆ»æ]Œö¸×‹UÇ#kIIŒ/"FJârf[wR\…W‡Ş€$ôòYî*Z,÷;Èï)±Œ2QM¤t*ù2Á}„U˜•ù6]ø—õšÜå¬üQB¯D«ÎxfG‹%F5A$ü|™Ş~;aR&‡0$<­L¾èPşø×Oş’Üõ}àTìàæeİ‘Yú­Ñ·cö¶ö°_«³ç9½!X†ê0:£2¦Ç@(Á&‘UáÇ —Şáì²»£ÔF_k‹•ğ„>¨¹ob¾ Õ^>¡hı—šS‰µtmå;ß]­ôƒŠa€:£gWiïw½™aSÃµ_ênwBÕC’a*Î›œ+—"ÿ4µûÇùÔßOK.g¨·¶í!Ú¦Ø9İ¬ ä\j÷—FŸ,„éáy88ì*|/óQ­BìüÿÊ¸Ì^—Ñ5âlç ÚæÔGp~É‘&Ö\Œ(îÇ¦i}ı2)™µ;â|n)|ÏÇ([~ ŒxslwÈŸV0œeËÃ÷VÜ˜"ûZ•üşíUVŠ*÷òQÄHF°I+ÖnËŸZ…Ò ç\"´ö‰vŒ„52Õ3m Ù¢°¬ï‡½±Ş<dª=ƒ‹ğÒ"aÛá‘ÇH£HPœÊícrÚÙã`å2ƒ6½T‰†6^„¬j¢dİu‚´é¶$3*"	g£®GÑ¸ç÷+sí\RJyÕXnÕ# ­cşQ1ÖF³?§ã"ûÅlïvø·ŒÀOØäˆ‡çy*¡åP<—‰ÚÁfSC‚a(_Ÿ—D+J3%?gÂH»“DrÿL~×RÆ<ã¾HO:˜ó`Ÿ¢•s#…‡YSìòîöŒ¿§ÃHa{Ra—§‰Éî‰¢‹òò/KqÂmáé^¨§×6åq’}dÎ=EÆè‹ÏA_E°»¾§4H,5+¶kTe*Ô±Y –òö{2t[vvY»[2 x;¥²´íyÔ¨qŠjÈ;‹>Á´¶Ÿ !êH´¼Ùs­£øw‚nnİKÑÀö+‡ûšØüxp¾ğŸ|«¼HEæ×ëk
)ûæDtÎóV¬ª1Ä3ıé5<) °;ÙÖKf÷t¯zß½*ÏĞÒaI4/"^_…<•ÀOÆ¨öÒO ¿­Ğ®ŸP‹	e%{u¶Î)ZÉ•§Û
8ÏÆä*Øq¡!fú­YøQóaäma-¿(5lsi“Ê2¶sz*	´@ß™bD«l0¡•}eó¾ô(dxğ Ìq#/.»â;-yBtº^ Dœš9PLÛ.­\{+90Ò	Ÿ¡pÓ´ƒ-Æ—\¨cJdTÎØ\4GªC[i¢ñ'>¥t.ãïø\>¶V”pvÚ FÂê‰MÖÆû/hªËk•H:3>³B•R0»øŠ¢*¦»j?óƒ¾Ì—4XÖC[G_…R|sÏÈñ4êŒûêÇãŠPóëd~ù?ªÉÅüo"ıôı/:¼9$k]>¾B[ 0 5{’i¬¤´ÿA{Ò:ÉÖ`ÒpípÒ3ÉŒfZúù¥dÇàM*ß³ceó-»«·µn_EAøÖ7å?_:Ó]Î„£¹,QÆw'S#nTÎ­&Å€WeI¼ù¶íúø!uvËƒDÎQZèuÒR™?±ëÙd¥¡WéÆ†,/b*!#mc§:Tü¬û>%‘çMú¬ÿK#ƒİÁûdèö÷·üïgD,óR‘u3¿BZ:­¸3ckı°\;Ë”ÕŒ	±ıRïÓ·ÆjÎüÃÁ èº‘(uGYu0Î¢ñİN† l¤]l©é^ĞìÓ+õ$‡””uN,c!7®cfœËÿ}F5ìºlaƒ¦xñ‹r~:fd…0÷ç™‚¹xo’Äû|æ–ŸQD3m%Ù7ákfÊœşî'¤OïŞıİã7€àéFGB—*ô¢å¿oZËÄ‘»…£òîçŸ²hîÏ¥¿«Yï0¸=?²€ıã‘¯ÑÅ(÷Ø\;½Ñu¿[5®p°Ë¸rÈ„”Çd´w¨¼µ®ZÌ #;E‰”lËy€†j³ÓP?õj[œ…‚©X LO]	U, Á$ÈAãÑíj÷iÚƒ€Ôe~  [
35—šÆ“[ç´€¢÷O|…«©ğ hX¡¶˜ûÁgBvà¿ÈşüYc„Ìd—Õ·âuıÏ¬m¯ƒå\]»Ÿ]l¬L<bOĞ£| Z½â|×eå”3²¦ñç–Ë£ÎF™*{§Ùõqæ‚Ü.Ÿ3>®û½€,PT(cœÍ’óf÷ñ'­ƒÔ4–N¯¼½/—<É´Ç3H–ñ§‡î4ÒÃw°…¾u’›•×ƒ7-Á]²»zº†xWqó2Ç
8—÷%…ß#åóØ¸aÿc¡ÌmÎ~—¡HüêÀÖÒâÀ2¦ø„S,Fº—c»	ä£RE<»š,,âLåüNĞóm=İÒ„…‘ù„5iñŠ>¶ŞvY¼T(Ç |(ú§Sè)ªáv($j´÷MÉ€ğ®¸ã¾©ÊÊ¹;üÕdœ¾¹Ìn1z+k¸bNÎŞZËOÍ9OO¹ÆÔ	Vx^ìõ§´qÈàÃ–¯²`šch­ŠõT-³o]½_ËuÉ:×ìúÀQuŸz*cQY¡239#à°¯éuşq47¢#Ñ³Ô°êæ$Ê |˜}M¼pCÑ™.+KÏmŒ‡(¿]ÅA†^š÷à§2•PğG'ZRIùq¢:‹R–>Sí°İào+ÁPÌ®Ô™mœ?NW~Ìg0?šTk
Ccv²ßaØ¾1ûØw,±iÒNRşh *Ã€­–ÔˆÕ~z ®Ÿ*†ò»&µNdÇ±k­M°p±Oğ>ãà9%>?ÕÆ®fÄÏâŒZ„şÖÊ»jä·N^ÎÈù›¥×1U™`:mliWÇE´L/xƒ¢ô¯›ï²šÜà'˜’0ö5ôE€Ğ—¹‚s_Ã4’çì¸¬8yÅáyNÀÌ g—Pövõ¦ÈÀi<Ì%DÍ‹`íø?~Fì3ø]:~v*í¯µ½—ªå¸õJQÉ³ƒ$ôRGê¹}¶j¯EV—¤äNYxÓò/jı;ŒNí­9º
”ã#”Ö‚ëc>©¡zÿ{Õ&§¹˜ƒú55+¨V:sßÓÕõWÉË¼®lğüƒöö¢]JŞÄï¿CÂöQ(¦Èº@*«>Ym¿Š\Ğ[ÉJBç¯U`¿çïäée›8T`oj 3)È2åß½¦Òœ‚Çs8oôÚJÜvÄôÓ÷Çà7wŠÒ¿Â!ìZY“¨ªàùÑq– _Y¼Éj ‚@3éş ¥YqA¸°ç“EP[.Û„Y Îò¹x-d¿À3B@¦[g°aŒ|éÔôUéŠêËÏ>¢ĞWé2·Ú_Hn`ûW¶Z¹–’IÓSºY†-#NXàq°H”òl¢]ÈÑ¥;
Ê5åAW½…˜Ç¬àH¨ï<ştÒÒÆÈ˜‰é¡XÿÃ‹C¬9¯ùZßM|hªi™ûå¨mƒµNxïéÊDç½ˆc1¨h'9š¢ phY'©yã¯ÍŞÚµ“şS‹rj	'˜ñáUõÉ+†5í2Å:Œ>]¾ÜµK'po† ‰ çJÄßâƒ@D]æ2“MÃ(_Ñ›—üDve”€Óº‰ÿ®,ÚBUÇéõEõâ8İ
ùzĞ4\ÚUäÛ¾Èó}JA×…º†ˆ­¢ÿ˜îQûÂØ	*Z%ı0©¦ùÉ’ëŸ¬ŠÙBoÍ²ıo’kÌBÎK#V­¸SYš[ù2—úK¾ÖÖûúeidèù'Ö(¿8äúîó}—R­íbµDö:rÕä±6‚İÇc¶.£Ş¶ûoO*U9)ƒÔ	=MÍĞÄâòãvú‡\&wáÃ'æ®çÊº@°ûí	%Ù¼8¤ï[[¡¨’„Øj³WG"\ùä??ñ#2±£OŠUîñª’“ëa//îú}RUA}y#Ií´Á	° ü¬ås)æzVkÁ— ï¡=T…ó\ü˜°Oñ¿´ç²1¸.ôÌ§³p­>ë¸–ƒOz,S‘ŠKk¾>ªCÕf¶”?~u’8èÿTM5µ®G¡›'ô¡KOQQ¿Ù7Ù}«®ÓÂP0ftã¿ÃOç0–|€3'µ˜A¶=’†Ğğ¼©Âcl§°ß‰\úvÓªqFc—{Çò/,gö1SÀÓcóİ¶8„7,ÄQwO& ùı¼Í M{¼nõ€”rõwa²¥ 2à‘äbù·mU9y[)‰=>f 3ZÑ”WïÉ+n¾ÈÙnDGÊe(¹v¢sÏMäæ¿BÜíXHáùÎç¿°b­~³ )TKz”®ÒOoä*Ä½Wëõ÷™S^óÆQ÷ï;ÌÎÄ/º«î4¤h'.—îz9dZ·‰tÔÂÊ@‰@ª2¥àæ„PSu‰•îlªÆöØò˜Üÿú¬™|¬ÎŒI‚Ë)YŸÇÃOßÒ2óí¬©-SŸÂà;Nk	Ng¡QT÷–‚XuÊxV*İeäLáØ* ÙHÎ~x•ë[•Q#ÆÍDè”M‘A{Æ"ğaq!¨±ÇÕ·€8å&ìˆ½2¹‘Öâüºáô"-¬s,(+Ô_—n|„Ô`!v¥ ›zsĞh›ú\TÕKÉì§éñc$_Çuõø¨jl8»¾iŸÿøØ½iZ8ŠY0` ‘ï£ÁyåãÑÏr¡\£)m©CİgèÒlÁ‚êèN‘š-;?·XÅÉú—ÃæßöİZÓ+:     >v}Z™0 ¾°€ğ¡–W±Ägû    YZ