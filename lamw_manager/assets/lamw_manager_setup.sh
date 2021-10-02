#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="44664897"
MD5="bda16f7e01b48e70ac0ab1b6f2e4764f"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23940"
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
	echo Date of packaging: Sat Oct  2 14:13:14 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ]C] ¼}•À1Dd]‡Á›PætİDõ	üÎ?“åX0˜Ñ?MÁ°2ß/~åBTi?qË_K¿K£é©Üªä€Ñà1÷f¦Î÷ãJ¢«xG 9X•2?¿§d’ˆnÒf`öyW7\¿GSdÙÎÉtºI:”Àı¡M6ü–½ğ´éñfëç¨åÅİÏîa Œ”ó{M®‚ìø™~vØ»v)¾™±„W´Âlÿ A=/ÌõnÒ(‰Vw½Pèç“­ÃõÛ_ş  l`uËÓoÑáÛÖôl¢ÁÕÏîRSyòš’‘çsœmÕ·ç—¿G(µTª×ıÒ<üşF5eMãÙy÷Re`ofBğ#©rÛ×yMá½UÑŠqÂy«Ş._´ùå&(Kà+Òr†²#<Õ=Ÿˆ/çÎ¦Ú’Ûd'½$ó5ôMì‘³˜²+·
ñ±.oß6¢¥âË?G"³²“ó:gšl¾”S
YócÌ-’¡D+ÀªOìElÁ\Äáö‡!,ªÔÁå)û«7Nüj‰ƒŞ¾(ÄdTşiíz¡ì0—e¶¿¼ÒiÖ\LR™•Ï3è¢eË4ôïIü¼®îË»ú	”œF	‰Ã{ëïo›Ïô!‘È;ŞeoA#g{ğfvƒ|ovÆ_)ÁÈ	“xÕİ‡'<íøà‚¤9å&‚ÌäÌKií€7Ñœ‘zP<_XÏn³QÉ©ïÉàXûÆFR5œDjÑv”Ä5ß…›(6ót#Å>å~ †téñeåW‘e‚v7c,¼K„
W·?Ô¶lê#_u¦šiFpkÁ"U'¢v-CÏŞ;"m9_òäÁ«zM@MÏ×)|AÈ(—Û#šî^,ó{îŠénU›ÿ«ÿ#‹_G¡²¢ïhJºíö3Voé~²e’ à H‘whq qÂ}Ó#ÏÔ¹ +Í ?X3Ğ´6(ç›<:œêëKñ$óK@cRŸ&:£Q3‚d
b¥¡’÷4k^ŸK­öè7~ã”âŸŠ7ğfkºûÔ$ E1šÌ¡'¾7;Û®Ìò.#±B>M±ŠÅ‰£ UBmVøø#Õ®¤h£éj«ğb“Ú{Ê¤İ£ ®R"Sö´1 ğÍû(AnV§äÁ5'Û¿Zµhó´XJ€ô•ğYô/GY
ÆCX´x‘»õ¹vÎä¦ÂÚmÉ‚nÄwşˆsö·ë©¯DåÓWàJ¢è9…ç²‚*9Èi!T2qGS§¿­ı¢ä%¸†¶]ÙÉ1cÔ~j` ˆP¶F[*ÜÇoà(>}Üàƒò=t²hE0Šíû&ÓgKÈÈŠ	ZÍ3¯Ìtµ\Çà²{pj¼ïtĞj×¶‰lü{ë§]S§ÿÊ„ƒ|v©DãQFVØÎ›l¥k*Ğõº­¯{ÎQ_Pº·ÑQYîÜØıÙà=iU¹Øydy•GôÏ{=‡7fğÿ…Ñˆæ’wA<Ï}(id|Xıy˜Œ0êä^ÀS†<òR '¾[‹	ÿ_¸Epß"]ÿ•<m¤Ş¾25IÑo”ïIæ=ı‹°¨Í` ƒ¿M<G{%Q¢¤ÃW'àk0ĞÚ¬ÍWçnLk”ñ<}ß\Æ›Úî>@/ÛêÏàú°ŞËsÂü´zL»R’ÁµÚS‡å„ØßÓ!æ•ûëU”ÜY[‹%öF»ú¤Ûíwí½bÄ} ¯ÌB|xPĞï…İ>¿zÍ4Åæš{ÂîcE¾øi§kEñ n»ˆ.ÌnÈmÖç4û—†28d¹) ‚»Àß%·ØŞ"P!~³®yó#¡
f6qÙ×¨j¹ÚÔó`f#­›Z‹wÈØ·èÇjgecƒçø»ñ@„Hj}ËµÆæ«³¯Ş:ØzÓ!–qáDAQ(L¶ËQA‡ûW
©\dÀ£€µ¬6>Ëµ0a²ÜÓ¡Óú'MXØwX}ÑëVd3‹`ÜÉEw˜©5Šä0Ñ6:xníãş:‡n´®·É³ Æ÷€~z<@©¿Ã„Íb™ÇÄI˜úaÁÉo±­;šÑû
 ;Ç÷<Ëx”şk¿b¬hÓbO*eÓ“Ëä'ôr+xÈK º³¹7¹w·¦8ºyKàWB¶:T¦”"êğ?íFâ\›®Ş=uP¬Øa!ğS½híÒÚ`xäBUdîA1I1í1‚¼›Ä2¢K.ûÀ—Úˆ÷2›ıVE–Úi™ĞZm›Qx)¢A¾ûƒÚ_dB^#çU"óm}[ÁcÁ[~ÉàÉM, p˜\¢fj@¹Gìİğ,×´AÔêıî7sõÂ/?bm(fÓÎMcùÈC¨-ŸèëÃok+2÷ViÅÿÎÑ	¬ºÓ§F¡>ÑM©-Ï}fçò*ı.a7Õ	9ºB¿xt¿$7ä]ÏÆK+Ïˆo€¸J	İEAÕ ±Ü…]^J›åH0X¥ÀKÒ”‰ÆXL*R[J<"¦T;· vîEÎ h"“2ßM¬¿$ÎE¾v‡h c¹ß–'ë?ãa	¿|)‡wÊ(./› ó8f¦L”ÉèV0ç×h¹¦^ïßj~£Æ÷ÀAlU¯‡ë…¿BÙ	¼¶s"‘Ãf)ÒÎû<êî(Z™²š4Ñ58ôcu4­0DõyS½{Œ—q ÛÀÙçç€†â¥ö·\_y^6÷m¶ò†R$ÔäöEçr}§áˆG …¤,5Á#`<Æù.â:­};y­ˆzúLºmæÉS*0àá¬šWkE)ŸcÒFËÀõ¡:	„ÿå´éÃzÔà¸ó_x„>ŒNQxg®Ô2ÂtÅ÷ĞÙú|®/?¿·ÇŠäÉ.×¨`Œ…1ı9‚À^waÉƒP¶;Š•ubEA¶ñVüûÒ-î€âÈ¨UœpJæqâÕº«¯ÁDÚãy:²êÅ¹ˆJğ÷`Êi¥ÇG"G{7}6ù×çw#-rµcè$vÒ>„ûÑŒ%ÎJ&#¸µ#ƒæö/‘WIäÒÑÕ‘šÿ³÷ÕíaKÓ€@kùÑßÀÔEx®P$~@¤}iÈSºü.$@,íœn‘×QøÓ· #õíAWÉƒŞåÇ©8OMË(5&íÀ	-—‰íúŸöpl–Jƒ‚dÑWB§#Ş?P"Y†¨Év|¬ 	b>Ú³«6¡¸Ï›˜®7vœoEaeN	z];2ƒÓ†”¬×¨¦$”ÆÈ´zÛËÕ©o1û§#ñt#‡G%Œõ7ŞÃú¡m:Í_Å±½€éèêJXŒƒÊ&;°…pİëér¯k×A =Z·ÀÉ(dU&Ov¿»%©É§ÂdF"ÙacÍ+t/,‰×Ë‘O«¹dpxévÜñ“j‡3—>¿2J°¬¡mÖ¾¹§PUá¢¬‹Ô9Ğ¢¦f÷ÒÓ¶.‡&©™ÔZìòÌDíÌ°œq`ö;c––M=Á“ûØ½­<oÕÏ´ªd¦u·äÑ.Å “éë66|;îœ çîCe¢D}t'‚áMÙ íùãBÌµî;L³n¤ÊK
xh³K™jlû\%rî4’=	=ÖÀø…³¹â&—f|£İ²€«ÈÌ*¦5aßcößÍi½ ³)l¨uX~¨¡SU±17ÕK¤1šœ¾*IÜÚf†O=xY?‰ˆºQósJ¸Ñg”íeÌÊÜŠ¹·š·_•À¬å€¶¡şİ…À~’(`©ûÃ˜§eÖ8lÛ4ÔğpavaÀ6è°±ã†z Úüêó¬¡¹‘Ğ:×¹º:/ƒšIÕW„W-6<¯ì¸éHè–7¹‰î­ïqg¸¢†É—8)”éâkÑ`wøqÎWR@n÷ÓzNmø(4«™Gj´Ş©Z7V9ÑCş`–Ñ$šq5{™û°%qU=P¼ìË{ò‹¯6Án°îæÄ½íu‚Ajãÿw)Q.Ô´Nt¹N~å$ÅB-\™®ÓE'0pOGV£8¶hÒ®@©ş>±TYò_N`ßsu€–Q+¯YÑöOÕñ¦]F÷[(s¶Bõ'‚4ëÊ]irÄkUtdêíğš|I )UäDË¼ì³‡Ğfmk úƒ¯ ™§ğùÏ^l®‰å½TgB±ƒÃÜ÷¡öïOY›V1™—â¨ÑvÛÕ} óØX’·øqÉÁÅ›…y–2bÅuk79&
>mØ‘ì`‡§8#Kn8ÎhWŠœqˆššOâxË’Øsñé;F6şHbéMÚKÊ#a­J,ÉšlsÀ7ş<å:å\¡R"
_¢ı?P‘z1¨}º"æôÌt <rœ ƒQS'~Öh è6rµAC[PÀX$ĞxFB!Ş$KDô{Ä©áğ7G%{Œ_Ól^Æ3&¤SÃÂ„:ä(~§»9±óY°7òÉëCh£fà—ç*`¬ezGkÆ¾ûªÀ¶%aMDğÃ_Ÿl G€öÁ»)ã.òO³&.Úz“AÌ¡ìB\Õƒ%É¸„+<ºb›Â^Úaİ>%¨8i×0Üï9~JÂÑËÃñ‰è4PjíX¬¼6‘À‰nMüCB§[?DYæ{¿çŞPèÇœÂÈ·KP‡»…r=×ğr³ãoŠÓ‚¼ü×Î&KT u©GÖ<ë§të#Ù7 û~
«Æfg»âÒrQ
R”z?ò—\Ğgî›ôá†ºÚı±Hpè¡ÏÅ—Ñµ‰ë	ñç›81‹‰€èa%~à3²¡?.+åÁ×ÏO(TÖY BÖ5AæŠ}8§‚@6óRŞ>4»ï\iJVÅ€Å:Pb 	"ƒ¦ÃpŸ•pã—Ç?~R5^ÏHÍ%œ%.g¢êNkËS5%Lñ½†k7Q±ŸË°0´Ğ­v\MëööŒüÄsåUÆe×ZSußp^¢,ó-ÑÛuÔv.½¹«¥½~ÜáíßU˜ÜáÊÚ7Â¡Eeq„ñ ÈĞì…Ù®.(aƒMôó¢mÉ-ÛÂ©ZGp/õ´Èj—Áùúi
ÃÂÆÃ„ Ws½Æ!ê‚€])%üä—€‘ˆ[¦ÇLd‹ÿ$ñ?€ï‚ş7ü…yØ`İAóœLİAÏa
ç¥ì°ó¤–Òmåf¥qª0&½8ŞyÑB¡ÂUïöŸøÿ˜nÁnU.´$Ã™cTErmóC³¹¾TKt‰‰,«)Ì¢÷LQÆÆÎ¨3Í£8ö°cŒ¸“ünWş!ÁËù\/å4üÿ,ô–4³×¨Îˆ]RRZ†Ş&Å§4÷wI‰šp½zóZn×ƒ Ä¶ òîÆÒûÕµV/ı¿{ıÛ=, 6“8—OTÿŞ<R„ûí¯Ôg\,gYÎG`ªI2…ñ•SïnZFºYï¯¢}s°*+÷UÇcÆ–_²[¤%ÁÉQîú© •ÜMã²wÿr¶öÆ ¼aòÒÊÈ( aĞŒ£%2»C.„ò Ö™l+å¸ºPd ·Q\‘Šµ%´°ò™i*™—}JYA½sİgçY ”ÜÁ³‘³÷Zäö¯È)ÁÈ=ÿTd–faÖ”êdùĞqÆk½£ÑÓ0İÙ>â|ÛğNh€€}›~IúÜÉÿŠÔÙáÙ¾½ˆólŸI({Ø£:Rj5×ÏûYJj[—?–æÊ²³•¸ì)†¾
B*?2•<øÔ‰g9Ã½0J+yE|™Á‘¯0E.é[nLEÀ÷H+uÖÅÖ0G“µ¨9Z Œò
ƒŞ]ä›[Ç•bõñÉ¶P€1¿àÊ—!È-¯¹ü_¨¸¯Ş„R~º¯ÏŞöê[QM"«^pV‘:…F,]İƒÄãÉ@çÛ¢&hS}ïoW5±Å€Ä=¥…}	€ivİŠÏŒ„Â§x«AåŠñq·Ÿ?6ÛË%¡Z'b¬€3S±ºB‰4·÷gJÄšÂ Ú{Ç9œ×|{¼Ãå“û<ëa¿NgL$¥šñ¡¯V–©’ÂX	ÔË}TíkX¶r‰KÜù$zã4YfDôÈñ³	… èçQ¹­FgXHvæ
Íiø	¬ãQ\†Àg‚8è
•?Ğ=}³¦?'v¾8ŠLd'3£n6'ö–-Åm:xpàZ¨;2 '&™4#òì~ëE;"Í(íöpëµ¯rgs=‘YlEÃq øÙ{é2[!—ÙmÅB”[ùcs †İ©í$Q†#Û·É‘İ4Î7²d<ûz{ğ È×Ş’ìdí8ãz"¦5+SŒ&]•¹?»ãÉ*şGÂ´.Ü…Åçû(,LP@	•µ ·vw™hp2zs\ç#ø}É„Ï©ıİ¶œ‰³ËUçÿ2üÿ´«ÚêÈØZöoÕJÍ:ì·WÁ®«õÄ¦·m4­5ûÙƒ;BaÙŸ°H;oê>HËË
gû?_©ÏÁh]'7cc§òÅ^ÔàÂT%İbs9_rU´ÃÃlcAYOzıjEÿÌjÓÕú»MìošŒ:q1@½É¶çaCúùAz×ï½ƒ-0œŞ—˜ğ,
\W¡vR|5¦mÑgfR5€¦}C„MØ6Ï…£’¶Ÿ_Àğ(ğ¸¼E1°ÕW|áïRú\dÕ7ò¶lÀø€‘rô»OŒÙ€W(åâÚ‚­´)GÆ$Ñ{e{ï7§d&¶ò9£4şRÀ‚ËV•wEEgƒªõÅâmsâvêSó7±¡;Èæ8ƒİÅ‹H?´òûZa{c¿dÉÈñ]rÃò26g‹ ÿñbÙ{âw¯€YŸ%f®ˆl)¤/îÅy5õ\ğûÆk;IvP-î"ˆlŞpØIĞ2g—ÏÒ­ö§çp_Û´Ç,Ëæn®i?î{ìZ%pIsŒ>YS‹H‚*óF›kËZI/.%ëêXGb¸7÷xÛV^¸Ÿ_K	Äc˜.-mHı7 CXai‰9Nï•_ë’!Š¬k¼%³˜fÜ—–#„»pã47ma>À÷2Ğõú1~QLfcĞ1¹QÌ¹(Mõâ\	?{C«~ZT}©æ¾¶e3©‡«à‡=Å¶ë;[­5h‰¿Âw•IßVª+j;İù¥FÅ4¢±~Y“ï¢»eáğluY=ƒa2Ã>İ¼Ä³L6"QKÓËıÎ\¼éTÏz#’”`sš£:¼"ç—_5³dlÂ©Ä^Ï‹€ô8ï·,IÜc·­MŞbéãzÚ;.”! 1è†˜ó‰j
<ó·‚î*HØ¬-y <:]«RàÃ;1Fp¯(ÛÔõHÆQ…< wV¢}‚‰\°ïÜfÛcÜ‰sÃ×æ,ë¼¡ôTÅÅÔÎ;èA‘KŸ‘]ÿbô¥‰e N“ã.ßMµÖJ!}¡_z[¯«Kn¦×Ÿ¼ş›ÃuÕÌEVL ğhï`ßxqÔ]2`Ø9JÒÒ3²©r"¯ÖùWÌ)1ømù>Eô"á!K)>JºàÄèÉèµ‘¤=—;b±å×d}tE>6¼Ãez›²‘‚®’|›
:¸jQŞ8—1æjÓâ\F{ —«9*§›ÀP}Yu
6-åPïÕ«íÂj°)ğÿTŒ\Òp!ëAsí•›µƒœ–Æ·İb¯VU¢ßÏz\,X.ˆêBHÃsÚ: #Ù·°ÍÜø©ğ£ ÔäƒÚÀüöš ßüB5ñÌup^¾©{«„‰–#ç~ö¥§éó¿BD]Œ¾í~nÖDù
‰B%Š_Ä“Ÿ[¾Ø{ó¼}©RæW,í´õQHBÚ@¾bttı9+ïO¾Şi)>'?Õ3]àÌê¥¯MohÁ`Œ‚EüÛÛ^[-Áûå!Qô»çõ^ÔC­¶à{í¿œ?¶ín—ş*²Fj(s*0á3òiÆn d«w½œ|Ésö%ª·š;ÃBƒ5¢İ[‹¥Ø‰†3ØX\kh?P³VLDRPS•~trór!´°ok;œ†qfÓÉßµ>¤Ü(ÌÉ;¿µb«şú_KyÁ‘P•ĞMçÙñCBY|WlKÈá`áºoÔtÖ`pnuØ!-t›ÈtêX|â>Å^º<¾{Í‚9msC³&¨ŸR4õúƒ–áF?$0È—Qn9~|ä1œGzufJçÃNÇìOèòw•Y7 õ)ÅEWÆºRÑ§s™Ñ•ßwK’©;ÙöÜDÃŞR|‡Yã;2ävÔ¯Êj­	Ä9ã#¾{¹»;.+õ± #¿ÇçkáP%L8·ºúTø^Ù-–Ygµá’²>Wåh"V0eºy,ÖøŞ÷m´yğ ù—'ÉXËàêÉå0xÌtÜÍ~eu|£Ï-ıùtcë„Ü]qS»£îY(Nnç¢°ê'´ã–pİã~il‡‰Õ$i Ğñ¢·Ÿ~­[;P1©1v‰¤|"MyKT¸‡¬Û®›Åøq²ş¢$ï¸ıò¸ôâ‚ı‡%©c%Šf&‡«À’-Êçó®\^­ûRºş@<8Tû>â<ræÖ>Bß®›ïŠ@é„Å|5Š‹à™û ÿãádŸÎçm(¤).£+¥ğ9Á“hÖ}Ë¦„ƒš“ğOkúç|!%İ¸Ô'Ø.ŞÜpïsybÊˆl—K@M…$î;W¸máé8•ãÄ¼Pd¯ÔƒQv]ÒéxPtªã~Wt£V ¤W®ñ	hVƒ,_j¤Ã0³SQĞ˜¹­Bîa|A²GÒQ§”ØõgËÂ°˜*Ïî $Ôíùí4ŸïépÃ°²8‚¸¶j5Ïåzß¼ []GŞã.•xx8[	Øæ"ØŞŸT(YÍNÖx_å3K€*£ÆÀgíi:øOóíÜGÚLD9'O%"{lDá-ï@¨ÿ9}Œ t v¾ØPğ‚ÉşÎj7J:'r]™e;Ã(ˆ;O¨²ˆC;ëD†}.
¼\¾ÏWíÒğ(³d¢C#§“šgğ ²H”mbÜ?Y¹Ñí±ÖüßNU·Ì€›hïU´7!Hğ>ÍÒOò½²É3^ĞŸ3S8ãš»‚z¦tò9C,r\Ï“)Ø˜URøpÑ]KİH&ÂÁD"R°tØz)çq ‘ˆÏµìîJ"ÿPAì³¢ôfUdªÁ~şÒ4›_ÈÂO ©M¤ÑÎuWí'wª2L4\^—‹:ê7Ù™‡šä›íõl,ŠoèÏÃÎR¸Ÿ]g)2u>ÊÉÒ˜§³”°ÛLÙI8_?¡9aº™ûi‹v~§"‘H9€ßÄ [Äw),$ıyônÅhxN`JğEÂû®£ÈOÄ4%³Ë¤û(UŞXáİÉ­»ú:Ù1\7lêÃÃ ±—­áSÔĞM-*âM™"&9¯Zú‰5“˜Z¦n:ØÓ‰oˆSÍè0‘'bçşrÏ‚á3D‡ ë*‚;ÒĞäDTX˜0 £'XZYêwïRÈ†^»ÒM=ïpsD~ocIŸ‘:™/Ãzì-­äçóÏrÍ–¬È–¹#5Ç´sgXIÆ“àyœâ•D¯pNÔÒ˜.ô¢wğçQ^6„ÂHé‚õgKz`í´LŒ¦M€T*+íéCŞam,”¿g8‘ùK^HlÃ‰šñĞ´muDUÕ›Ñí3·Çaò+øÀŠ}%øqÀ£Æ L„Óá¶ıœSû1MÄ¯•İñÍÃ)’óA4ï2 x´c)rÄ„o,—‰'
å1vÔú¹Òø5ğÔCê÷<İSä—ÀàÉHğ&à]–}ûo*”£RH,c¥U‘´«­`9C¢#N¼ß	(kô¡˜æßì=2—;Î“)¥º~Zgr§X2˜3ÂZP×rTk}_¶¸]2^ï€¤½İ.Ep’¶bÎôk®¯ÚµkÕ¦™­†^WDzû-‡‚á70Ó0—HõĞ[,×CÆ#öF¹­! wM,Û%œ´Ì˜ïˆg6×JpY³Új9Û8\wúÿÔ~¶;›á§}¤ú’S³ÃÜwèû@¼ğæÁì35€H=K9–hænÑñ¼?î÷åF?8¡1±ğ5]NÛK­=«*€­ÓRD£qähúÂIPêd<o0š2àµç©W`]-ÿäÆñj2áì&2h&`\n_D|–|•™[…(ÚÍŠ%tŞ¥|¹çHœ[+cŸó=¥£<ßt a/~­ël!dĞ51+où¤|H}úqc”è-ÅH‹|ï2µÕ†!¹ÇÍHj¼µ´¥jÈ¡è®&g(ˆs”	Á¦VNïJŸ÷ë5ÿ?ÖS­¬xßS­®Ó´•ºV—5µ‡¸/\Ö•¹šªj¦@ÁæüfÒŞ‚Ã¸yÍ:n…)BõÃèàµïã«EË#z°¾·7ò!õ²ym=D²õÆÛ ÙªÚ©üo¿©ğ>ëzãÔú¨0ï« ¯7DL!¦¨Ô@X¶0ş~Ë;¤ãZÇşĞ‚8Wš¦½<¶?rRîÊ‘Çà|!òØ&˜?Ò(„@iØÎ6‡b¹Øîà;šş§„rÜb:;fö ©Ş¸~–9Äˆ—i“)®ÿŠzK~×•IX±…@:½¾òeñéhÜŸùcÊUkNú}ÉLIqócjh^Ô/²Êd0·.ÙX“nx‹OOVàÇpz-ö{]•i†I,:ëZ¹	æƒùĞÓ`= 5WMÚñ…ˆ)øÈÑçx»ò[£!Ğ=ø“¸*0å5.¥¨„¶9úYØËå£¥;6×óÌDÛÊ@…»ò{ş¬#ûóª£±ÛRÍŒWşG6üä’ş‡l|u@Í u~¦&œÎÆANXH¶µàÃ©‘Ö•ÃÄ -¼}9¶wUïğ ‰©V™~ÌWÎo;ö‡M.ÍX™’9	“6åîxæh‹EXå—H¼‚OÃ¦/ù*9÷ÆãÄYª‹æ=Vƒ.§·DaTÚ]ŞíšĞ£İÍÒ¸ÌÛu}w.Å,ªá8Ñb¯Šl”3l›8Ö¸‘ÓhÓo–±›Õ8è±ÑÀ§™;ÕeÎÀ<·”'iÙrÃıÃf_üÙYÏÚ'%Ü¹øD“X'vßŸì_Â¶bv¤;ùa‘èWÜNÃ’´·-œï_º³‘J9u‘­Æş(CTÌ•0]ìœ(’Gû°à"Ï€{[a…şVgKÅ ”hj°®àY²§Fàå@[_:)²{ä)4ñÓ`x:æv½,Õá¼Syœ½ÏÄ,jc«¢cyuˆxx´„|¸C¼^uLJéÃä½±"¾^œË¦§4ÀòÀWmİ³‡ÑYüì‡ÑÕïì­“ıå­IŒg3Ôæ¸)='»=€Û;íá¥ü3¯½ŸÖ´s©\ÉNÑµì@Øú¤7j¹¼®}7¿¿íü·;B» ¤HÄ—+ïŸ~7Ù!ZĞc­'
.ĞJÀÏâ}è÷à2qJÕ¶Wä¤’›­ûÄkîEßh_OLº Y‡3êŸ+çÅ)ÀóLšóDè#´
à‹ïØÇ@ÿ=LpPš%bo¢e¥oZî]àB8×	¾Ï{œM,Dëÿ#-¤¯§ÑB*©
íVè'©éí@h,wÇ·n²r !Q˜npbkÀé|ë›íwùD=q.&KÌ.zCÂ€ˆú­ÑƒjRZğ9a“ø0áÉ@k¦({hŒÈ$Ü-±[€°»ÓÖ&ˆ¯CèS—µr”¢So°1#\{µ´"÷@wôÏ@[¼ÿÆAÈV…
¼ŸæÛŞúîñ*Y½#Šª•k²ë¯ Éo‡¥-@+ì1Mm[â¥èÆGµñiPŠ£¹ó(Dy³İ†Io·q{Ÿ×õÃÌ_‚v§˜·”è¸}¨ünß—·Q¨¦­§ÛÍlŸ sòç÷§ FÂÕe)¥;)-„qƒg¸l…3ªôÖóıoÆ§Ép‚Lôáo&¸WÜLAû#r™S|öÔ-hv4³>qîlæ !? çu»ˆö–Ñ”$0œGïYg¾e03
½S%ß‡mŒW:»Ìø¯™ŸÅ#
Ó³~BÏ_Îœ“y'KwıZã$ò5…BµÕsöIÉÂéN¡?¶Qy÷ÛÕŒÿÚÆS}ÏÓ Ö†®¨…Jî1d¹‰İ‡–•hœÔ4;
-æ0¹ªQË[Ì†û«³'T¼ˆ'†8ç}fU	šÑéXN°ÔÚ«OÓš¡w/È2`¿¼ÁİV«mŞ$CŠ©üÛi Ö,´O{J:tp3ô4Ôã:t"Ó†_UÒ)h;GèşÔÛ¿´v	F;°udTÍF½º®“äÕÉEeæk*2{†JW†Ã4Ğ¾)2ÊîPÜfŸ	‡9u¥K¥å“¹uU§´&(/ÑØ$œPøÎN¤ÑxZõÌi§ÂÿÊ
Ó™G¤³³A‚€<Ÿ½M2àES×s-bÊD´ÇµƒŞ&5‚¤Ùy¸ŠáC&b_-µş”î­Åæ[SÓÛi£×wy\z#«ğ'»Å®İG;b»Œ›NÄ‰2r|‡i&{MÙàx\L0Ë:ÈâW(ôEáD”‹(—
¼'òí#ù \¼Kìı·ng±&mZ¦À¶‚;Pr®€r„h×FspAp6†H«¤é|£*…™UUì£ıõ°Éu‹ò/ÊéİåNMŞ¹ooú†\VQ=éßñĞ=[MÁú¤yóy‹CPäH{=~±±ÀÎ=ªM¶T5GÖ27âúix	*ÑvÛWşJØÊÀªy´	?Q;¥íœ,'aû|*¢¤wDoF-ï—¢¿ÁóÅ½¿ÆUÂQ%» ¡y6æCĞFëíĞ¡PÃó$İéúy’.9bgOŸ!ÚG¬"Ê5¼sè,r¨|ŒÅº^Äæ¸ĞÏ˜¾ï_01€pKË,Öov\ÏTMª¹Øb*@oã÷~Æøæƒ'„Šàºh=4"Ø‚Şğõa»ñcv—í>)äï·pMz¡\YÅùrp8—İƒ|Ôn•!ü1şÌgì¦?6DÊ7¼z¢"c¹…çDÂü)ÃÕÕ“İRòŞgï}Hc:,®œ[Zî0âÄıqò&Êı²‡©·´JÂõ»5šPÉåÅ-å}VÈ“@¥6‘†2÷²@ü6Bkm‰$¬í8 ’ûÍÓìM(V™·†¾W‚ƒ­ê¡ñım¤Ò@iÓÚ+•Á$ %øgA<ş¡jÎ`–Mú0†²
Y
÷†4xPzLbA–H8AİLWUo rR5’•.­SÙ4E¤¶í^iš¥á¯“¦ê úO8y¦u¢F/á»Xô2œ:æYP]Ê.fäìÿ÷[{6¯D+Z¡g§C’?¾§÷İıãšÛÂ7®?®€×Ü5ƒŞ,xb*ûq—æüÉ‡X-g¾Ã§İ<ÙY€~E ó-Pì YmF¼7ÓEö‹³eO]6E÷i•Ü9³jœÓ²täãI‘w@O¹$õ-ov„tÚîD¸%ÔXé.7g¦7oú¥ßG³×AOÖ"ê%w¨‚âÍ«ma_p¶]:e}TËO èÄ0VxÅ×‚®‚ı`ÄËG>ƒuh{°n(Ú*€_™'9ù_UEtÎ,<~§P‡¬ rğ¢TóC§¦¾5üşJ˜ĞĞWuäMxeÄEOû÷+³ızá	UNtù+ûâîY==Ğ&»ËCVŞéõNËv’/&yßÏÑ&+x ßu¶EˆNK›1‰AhÅ‡mïÓã <ñAºH£‰Ä¤ÏN¤O§áÌäêè8=MêG®9°õ=Šÿ½£ø»²¯9ŸØØDSG©T5ÿ×S¹f»¼ÔpLGO6ˆfÁo)tòPx½ÅI)a¹Â¢½ûGo
áböoÎr£êâcï\“…Â…™@*»ªtÔDµqSq¸2<N@Ág}±IÜ@.I¥J	z‹JÆnãß÷©k' ¢8ıOÃËø‘°±^kn’®&‰)äH¦ü´ŸØÌEHìu=õ«eĞøPay¥õ±B°pTäÁnó08P3Zû‹€Å'Yœ ¨ÓÕõ½üÄSífußâc×?pãcøiXš4‡ñê)Ù²ŒƒÉÃÌ¿…õgÙú½Ü UûÄâ²c^sM)¸²Qßo¦EoıŠ¢º‘í™—ÒÕ1-¶¥b}Òêáå®u—z.P\‡«$9_ôÃ]•æÆÿé³äÇ)$®ş¼–:ov¨`)Ô°é4•¬NMÕ‚·n¬”ù 2IìIÊ®7™Ç¢Ïi`C0p¨V	äW]«…ıInfè ^™[ÓÖÒ»eDr‹4±ƒÛ%ûi©x¦¡Ğ™úJæĞG¥F6»ü)˜€‡º†â¥,¯¼»aâÀÚÈ0vôòµÉ±¥bi®Ä‚ÿ2ÖÛáéHBD5WóS:È“xıIÔŸ§2İ	QÀX×d†&şƒí$‰!Cö93½f;¨’5”óDPyÚõÙãC!<û½s50sRÔª kªyú¨Æà.Îãº:İÚğBkXÒÓõZÿz“'ôB—Pšr(ê³Ã8”ÛhªQ±€Åÿ¡²CÔªde0ÆÄÍ	Ñ)H¨r`f²<xZvM%¿úûÔmËjÑ8`I\–dØşCKİbVbæ4Fş”«FJšu1èØÄÃKW×t’•ĞÀ6ÅÔp×¯Ù[Q!âN—ä£šÿ¯[D·ªØÛtv S_/r§C@Üæç56¿Z`:ILÍY[õá3#±ß{qzµ˜ŞÚaq¾ZÚ8|ôálZß¶x4ÛñSV]èÅI#É;ÚU6œ~«7Kà:;p$è^V—å­J(XÈÁ4»â_°©yJèóúÅí&a4şQ(#rmÂ™+æšş>Â·‹9­yÏ/İ†@ğÁ°_Õgü^¿\¹`á<÷ã‡
‘¾;¦‰$ÚJÉ.*ÖÊwÇÌ"EØ?ªîÅ&ÿÆ»$dÿÀ Î9}é;>·iYw·Pã®§U9ag‰ë·”B«;Ş°&Ù½˜Ü–¤`gœtBp	-ÃÏÿ\Flu]¬-Ã˜ˆ£gåì}—P¸´Ğrõ %€Ò¿\ˆ0{İ.BF_¾¬8+‘ç*ÛÛ|ğèúéM˜Øå1úmìæ"Šwşøy}¦ïg9¸bFø½ìjB, z9&Ï0ªV²şeT-#„×?ÎÏ½Eï"›P>‘k÷ãZÒŒµ56*4´xÃœ¡âf\wş×Ü»VI¨%YOĞÄ÷ä™DrVêeèmÃ@Õ®È‘»7¡Èyzr¼ÇÂ·ütùĞ)2;S•Ã¨gü$¬ó†¥ÙÌIH¨êÖŒª S9?Ò…bŞ^¤$¥³|B—Ö8ÎÍSéòJ†±m6`†xoˆ:ïqÔÎes‚ğ™	Ö"ÿÔ-Íµ¶ïØ -€hDR‰&€Øy'û`­‹ê†Ô¨Ğ‡©|ÁêÏ§mü~†øXDæPg.FÏèıË'Ö|
"ô9†æy‘Ôl1p—¸´=õ3
Òq)]K }kbxÑÙ†µK S^K	ûôÁ<iQ9(¯N º%Cæ$óÛ4¥@_>T}Xà&4€½ÄI®´¢lû
a™áf‰”%ÀÌ¾¦Xå‹âL/ 4taè¸pék[xİ÷ˆ£™Ò8¼ëJ`uĞKCê·ú@X ©’D+ßBÜxëÒ N%,‡¯ñ2åÒœ ûR<L»Ú+µ+)ü(øe§Jº{qÑÄ—èßN™1"LV<.[•„ê¸-cğ«KEŸ2ÒŞëŠ^qxX°¡7îd–düÁÅí††¿’¨K°JŞY)¼ĞæY*¿ÚÍñLVg‹j¸Ú
¨î Ò×}}fíx–áË-4Ùjœ°è—˜*JlR‚?1¥s Ğâ÷ÔOÅ “á¯1mbÿ¶@uQN2^bã¯¾M£×š°®§dg³¯Õ µÆÕ¿….3/ÂÙ§¬¥/…âàZÓ!ïO¨7™Ç:Æ3q`GÂy EøbõAÜø‹Ù¿ö(Áà¾¶ôÏ†¬H¥•FÌü_ÚûÄh*©úà†Ú÷©¶Y>lÎÓêxs6W®¾TrÚÌ½ÂÓŸîR˜W¦agıßHÂ>;E'·>yèŞ
?k8f¯UK¿¹ŒZh{ú^‚Ë$„óÁDê„„ Ã0½®õRwìñôiBÌĞ“&}÷oØ–0ĞSıøàî¤|¬L&§¨•ùÕİCvó„6x;bïcÆYg*$†–Ú­[nf5à>Û™ ¡NwDHÃ5Låúæ¢SlÍSNJKCTQ¿Á×MŠéLªÓæ|îfNnX@?Úİ*M~ÿ;Í;6¬Üğ5™“1æç‘£Z[‰Çd†h4¨H…yaP¯Òô¦¯­ñÜx+1Ó4 ë`jù!E1m`µEn£VÊŸ@v†Ï}VG[‘İ96áŒö¯»¯gOåËOjƒ[Q^½LHšºCÚ;°3¡èl;yYË1YÈt›w§ F”tuãİ¬Á3u+Å‘ª£n:ôR^Xz/ lÿ.ÜÒ>ßöªBç$\¹Ëù”ñ¶$Ôf¸¦5-ñrÈNá¸VNG'²\@|ĞrJÕòÿæ¶4Û<²Mòıs½Â½j»q”/Õ[ê¬ZËİqÊVqêŠ±#6vÕm÷U^×'‡öÉób;±èàÏã¤Ì#™wtX¦ÔD›zBŠÓåf#ö/oõ})	ÓEœâóÿUæšŠE^º±´µ ÑöEaøøŞQøàU¸Yà^s~a‡E0J­…"T3Ò¹ïˆ%ÍÌ‹ñ
9ë ‚kŒíå´¬¼›íŸıÌ™ğD‰eo&—iT•zÃ#·4VtÀ“RËñM)ğĞ}6w»¨õÕ•Åd[å¡ =äóàn´F£
8î@qå,úM«÷òpAn"éj	'ªR§~Ç>ÛE?Ü)Õ]Ş§9(v) @6Û€.¾ºÍÿˆüü`Àô7}Ï=»Ü‚mœÕˆ}EG‰u¼qoèşSn§@ò„.Í»Vz³}GL¥‡±M
{“‘ëõj¹0¸[Î@€{¼&¶ºYÕ¢n ×³‘HQ
ßN&4ƒNXıÓ‘óÃØ9ÈÂs20J59ÛÊNIáuŞD›f]&n§)#{‹*gÇÀ¤¯ŞœÂ5¾^º³¾È—:²ºå6r‹4‚¦ÖIcŞÄB	¸9ö×#Ú™òPù õø&ƒéşS™Ú\³ûÅV4ƒ#C=­ø¾y	ıƒş†Ğ^6÷‡ğ‹Ë8uYùåš¨"ÿ]TƒÊôsğaìFdNosí˜Âa5x‹I0)¼ì¤8NEk™õˆYÓl&Ì`XÔ¬†ŞÉìHŸ®.ª¡.<I±Š·%.&EİöÎÔQëxQ^P|Owè9C~ìØã8¿°–®¿šÿú:Ü2Ä¥:0ë üüÕ‘«‘Õ§â×ë;^%Õ"È‘l£zn~\ï*8÷&è4ƒRÊ·õêHHãS§ÑlVŒc²òŸ÷[\ª$4Ç0rYaÖÓ£ç¨‚ÍTÚ1Ÿçğ4½Ë™½õn‚N$²[6ô<ª¯¯\ÛGÎºˆ·NàçÆkm
†ªå=¸tı—Î±;rzÖoçz=ûıAV*òîòJÏÇÈ½óüO–®¯éfµ$B½3“Ì?R–·"i èbÍ‰Ü‘g•T“­T³õ’mÎYK–×[âa¨éîts¯m^Ãˆ¾Ûšæ!P8]æ†óë1ºËà¤×vhZŸ-¬®)ƒ 55f°}j$!›ÖU‘¸–|=ñcÉ­ò:0]Ğ ÌHMseUúª”ãyÒÆæ3C\‹¸R‘Ú.RĞ›KÁh§e.1s'z—L‡ªkùèœÃ¾™Ô!#
—è¯YìÌÎ8B/nï+‚] ¸Ş¼GGCÑ„(.”muÌ(ôå…uY±ól¶•5Œ€MÓ”*áCn{ËböZ…ª¹$¯ìšùºj;£9ÀmjX&·bÜ,¶óü‡û§ÓôañK.Å9)¨A™/Í¢¶W¶â¸#³]é…¹íTìãOĞ:h²‚¸!&båzOĞ*Åùb¾	1.ï¤ò˜VJLR©TšÏ$
ID)Êü¶òs>t²ÄŞ…*á~¯Q{Lnë o€uÆ¾ärÂõ¯WŞšW8çŸ_İè”¨ÂM€¯yj>÷¸ã˜÷p•:$.~Õj™(êSUÔ›e™³K^´¶Z|ë6´@¡ƒµÁÒY/	xöà{C4™†u1å‹¤ñÅeª«€h´	/ Ák‰ï}MÃUæ…wÂ Î~"âÑ[‰ùbs¯OÓJQ,x1yÜ‘üY~ôe#û„£”\]k`hà:Ÿ¦º×Ôy|†•LGÚÒŒóîvŸßÄÄ0Ù%Cñ%åƒõbÚä¡xú‹20¤DÛöyÊ;Îi™Im‰Æ÷ÕZì,]'aôš‡¦·GRˆDÈ-,íøw%\NFÕ÷ï“Çî:—…V‹xÔ=8oÿÓ-w¶HU0V!ó“ŒMÈâÊe“¤2h@«Ú
Üf Îğ ËW•ó=JÄÇ|ßş²ÿÙ0­4Şyì0Qîª{²¬cJV%[ŒáHÛ×’»C_ÅZ¤r4¸x<JœJ•Y_£ûTí÷Ì(ióSTTˆ]Îæ™Ë­*$è!Ã½ù-`¹a¦ØÉUİ•Œ1Pš1¬‹ß‹ÖSX<Ùš–ˆ>¶!X|İDšbs½}Ì}cø‹¨ŠQ"Ò&N‰¤¹ØKDè‹D5›)‘"¥tÊÙ´‡íRráÛz‚ÕÍ³i›É¼¤æ] 7ÄE¹xL·à«Ê1›\Ã(!ıÉÁĞ&æ¥ñ^¿Ï­î’Çÿ¹×‡ÇêEcjoÁ&*”Í„ƒFşÒ»àÒ/»‰ï°´'„?â¿/‰˜
âæ#Û3åüj°.qÂá#š	«†Àt/U$)ÀÚßA‹¾jÂ¾ÒÄeÎ!’$Ò93"«Yc(ËÂ$Î}°èï ©'/1ÁòLiƒ¦o¢+;õ^™¨ÿû[Ê¾Öæ>Ùÿ·ğêˆ	ÜTş††-z“ï³Š\UŞÇS{Ç6Xaï­Ï#$&¥¶lF5¾VCÓà™_ôkšÁCÛUÁ à`ÈËë,á,p;˜©¦s~š¼Ñ«ÁÅ€.ÁzrIı6øç€ÄÇ6gAĞò¹Æƒ=u?µ§Qº´9övÁòÂ:Uæ¯¿ÊW	)k[˜"PØY•ng9GsH_›e>˜G4›Q"¾§;Gt\àWŸÏ	û(ºŠ7ìKtÙWÏõ3âõAÖ ±ö‡|!¤aÑ€ç”ø6¦Xz¶]Œ_^üëáQv;ØÌj„¬3CÇÑÉV’ûûcEz9'u6*>ÓB›a·Oóu£t_ğW‰ˆ¸·Åpwü™sÒÀÛ >µè¨»NÊ(ÇÔÒ´ÈõÇÏâWÄ¦JRw[›¨—2Òd3™¨¯ë·‹Ïñà{gáPgÅ©–æÍúZß“´ÓıNW‚ÅöaR¶ı‰#CZ²ïº±[î¥Õ–›kåçVB}¾i¤6åÎ5­ö'Õ«¥Ş‹º}Ëê€#¶„¯³&Ìeá¬ŸÍ–æ;,fÛ>¦‹lCÌĞ3zú^¼RàÁ„T©ˆæÂÒ6¥›Z­ÂŠX/jÍ°Äwñé†g$šT>çÍ*_2ê¯/ä@¯Nø=åÈ Ü2ˆp1úŸÍŠoÎaiqv‹åúaqÁÉ‚fûùD.
TìÅ%lÊ¯“wÂR³‚Kë¸ñZ06Íoê]X²	¥0† w‘ô+Úı~?`¬*o¿$YOŒåc´†&ì­¸èuXö–CšHÅaI-ñgŒÙà)•‘U½t®Û>5j¤ÚL¸Í¨Ì¹/Üe„—ppYì•Ø–eõñü,eg‡ÍÀw¢.ï^é’¤y$×•9Ã “–ÏÁmY3,ÜrnËÄiæÆ¸ò’ÿxg)ıÛ‹ØZgğme'íâÅ
Y›]ù`Éà£ùytìƒFi]òÌ4—Ló:gròš3ˆãÓ;®Ô±7£bÒcûe|Š„[İÜ}¼BÇòæRşñ¹'…°ü¶¦eI²¦ç´‹}^ŒØ8ç3ö5%ÇF×ØZÚÍŸ¼®dNzv=»öë4ä|(o9·†5S”ês§Qîôzü–-ÄÅe#Åßg q*ÇÄÍ`º™ÓıÆ°p×>c`ÚáQ•„YøåÜ%œP ³{[Ä5ÙQ¿ŞÚÉOO›1@›ØTQ(5~§ZãÂ——uÂu§æ|øqqÒEYUm™“§‹PÅ×#ÖæØÜê~‚¸B15—_oÓ°~dİåÒˆıHE©‡[›Q,}¾Å¯|ë-¨xn™ˆ<ºt©ne¹6Nj‘ ÎÇ°œÂÍŞõ¬º.Öšœ!0ñÔ@&á;³&Á¨VsÆÛšE„©r¥2rÎ‹]:ønW*î ŞæR’[>­§°îÁ"¤Ë-¾ŞÀey¬\>”åĞ0—¾	·å†bó½±?c/Óxp÷{Èü/^·½`3*Gü‹ÅŒ‘ªŞ£¤óìëĞ4šH3Ô·E¤ŞÖ<®³+z‹ä’›ºŞHYUÜ"ÇF åC-ŠGÎC|·–tHS–u®¬±D4ãTB¢Ît¢·eq*Õó½`ßUƒ—¼Q'T*—Ó¤Çüí	lğNç“¢ÃÄWˆİë‘Ç²SéûÃ(jV÷ûÕE÷á/Hƒõ™àÅ	7LKKåVX©XA×^¯é	sáù†˜À® 5Xf#àm¦QÉ"©¾ÂÔ³.reË>£P^pn„™JÏ¶ˆ I@ëLVE§Éxè*v¼uÿ*ÒK˜i'óÔ¨ô¬wÖÖß6úÊmé9×?¸Ñ`wW3c›2q¸0_n‰õ*½º­N¹rz»¬1G\dÑª¶ÆZY!øN™*›e°ÑiíŸakò *´ËÔ›‘å­ŞIFM§Ö×ÜƒlHhU<‘ùûÛ*ì\¶(|†Â¸gPİ¨<“Zz\NÛ:%xkYp“™¡˜(µğ1Şn<ü¼ß¬~H>¸U€=Ém_Œ¾ï[ãZéÅÆÂòÔÊ¦èoÓÑCGıHgnlipW¼›1‰aœäZc‰ß§Ëj†;+/¯Á\¯Æ¯ag5n¢^Ökd`6ÖšğĞ©Q°ÈkÈš®2 CsEl¯%³íğI=©>êÅ&!ÑJÕüEù¼êÚ­€yyŞç…¦føëmNÖ$à‹Ê¯ßğºBĞËiTBÅÛúf­„±b…B¯zëì“º”7Û+ÛŸ	‚¯yÏ+Q‰Ycyz 6¢}÷Ëš^Óèû+uH!lHñ/P39hëñ ¼Ëu SvÁôwJ^`¢‹¤…uQ´_›Gì`ˆ¿Ê»Ûî-‹~ ¢Ô]^Û–…<Cê».)sàbÉÌÄ+ÿ‚.¹ÜÃÂ¼ŒÁïU‘PšòÈ®˜šä	&ó5JšÂY”'i—£Èn ¿ş^ )qõ¤¯°q‹+KpÓşşæO}
¼œŸ.Ü›@ËRÆGE¥&¿[ÍTdÙ»àHy„¦¶ÃÆ'áüqĞ²–Dzİ;.c3é	rËjäÜÄ›ÚK&Hÿ%©¬+CÎ «>r¡Tk¥Õş˜IğØÌß÷¬{øè²µ&²áJİ}á *x«ğ«¿øB6&sTAØ+ÌVûŞH‹S6]äØÌÛíìãßM6gĞ½…–BüTÖ0LæÜoHB/*ŒV½Lk†‡Å—ÁÍœ°õn!†y‡á§7^M9±:‘7bÙ	M‘_îÓbEBläÓa±¤ã¤‘·¾°åˆ$Ía0
ål›†.œ"Êé1µzÍS”LR5lEŠ¢œ‰1\†¸Aş`ô_Ìw€ŠÜÈ¦èJD]Ôó÷·¥J:ı¦º€³v×mZ—8êÍïåX*?ÁÅ½?LY*]aìWØ)8ëyÖéˆ•±Hû†=è_²‘İ réŠA¥‹|ámûá«s«­æ¯²İüÕjbòŸwÂzIékëØÈî¼ t…Ô8èã«ÿùkéj£ô·İğˆ2¿ll*YÀÄÒ‡Á}Í1bÓ©¶M×áÈ“à[m l;‘Ÿœmø¬ıı¶|wL1Ànğş¢/	<Û‰­‰·}#«ll©>˜PËº•n»Ò.¼D|ÛD/NÓÓM2jÑ¼µr“Âº³Ær<Ğ%¿ÊÄ*jÇõg¿ñ}[¢AçeM¾kqÎğmÖ§0
‰ÛwA¦“ äqcsvFj“Şó‡ŒJâ¤Ó}¥Zµ0öó\¶)ZÅMñ·gá¯†ú4*úËıS‘
ƒ>!¨¹º 5J¡ÑÇKŒ«:Õ²%B7Çp¥´…ŸY`d# ê@”Ñ/¡HBÇZ%×hÌª¹Xµı?ˆ×!¬œ!
ÀÅi*ÌšË¹¹½®&ÄüÆb4Ï×À¤Ær¢S{`f¾ÊáŠMöhÔ|Î6fÃ£?mîíŸ¨eXjşıø^%øE¡>Ÿt0Y´—†«Ùò}«t%¸xå¿6z0QŠ}ì<(·G)Nû…qËM„O@…ºÄÓ§Æ5'#^Ìõ{uK$F…ñVî?cùúivŠè0wI¿H•,#”EYj!DÔ@w6Ï±d¨É4ë\ĞØt%.ñC®<b¤‹U_÷×ê¢M­‘¤ş?ß´'ªÁŒæWbñı­õWPåïÅ‹´Îj²õÌ+‰4ãÂ—ÁuZ{În¬øãÕ±¹h‡•˜{éˆh€2$jQ,"ø|ùÊŠ yd2¬)uQœ_–êô;R¤TŞ7'áO£ŸŞÿ¿aê2”ûd±9:¬7ÏªN]’3\š-sÊ_|Á—’R¨Ò’E†-Q$İğüÑÎûô›Yî®mŞ£õT²ÔÀ·kÌ[^6ø€d•DjÖ8„zØ#VK†y}9*ÚÏUè’¸i6<	øğ{¡0·¯¸–IŸ|-g}ié_¨ÜOÒ/Õİ§0,âBL=ªå¸“Sâ-òşL€ê§\(-E*ªèÊRád§(G¸?6ÿ/3OÕé,¼öüÄd³ÎÚˆ+ItqOĞş½9¸‘"İ;ŒK¦F½¨ëµ• ı@aîuÌ•³G×¸è7:­ÁwÂG/Mş›Ì‚yÅ^é]¤Àş*ßG3o”’”šLa|>¿\9‡ã÷m]üÂt¡ËÕÁŸœY*-{«,>ÀË]LT‡rá¼Ü'Œ.¢¬`õ7Z’#×B°-f¨4™oOÆâkú3/îQ—Ÿêò9èôzî´fvÛAUf@|Á™šô+×¯”¦ƒ!si¬3Wy1pïó?Iº	›Œûg¶^KA	hg#¾·ae.É\a]ªI§„œÑn”ÉJäıdÍ4òëaÅU¾ÀŒ©x±‹¢(«4Ü
=On\«i=Œ9ÁXB;d}#À“z.Âq¨eFe„Œ^}[F—_4yÉå«ÇQ©'‹°N:@L&eóívï¼=©+ªÎ‹ƒ‰®–…uz„\ÛPuv·-i3Ë€6x¤•Ã½Äü¼Iê{KúSIßè[ÏC·7Ğ€vEÚ–„2ÃŸáˆ±¿)ÌôS=ŒODPFnn7ÛÏüÖı]Å5¼‘	qˆK£Ê
ú¹ã@FQøf¡U Y ¨§S»2¦&Z|}Ù>pdâÄ#‡ÜÄÂGÀĞ¾ZS ¥ğBñJ•×ßv-30øW?m'…4(Š:oÍ¢7!Õ–eëJ“O—	F÷á”ZÎö%¥ØL^FŞœ^¾S8¯ãd>Åßù6Š—3ÎÖò6Ğ^0a*¸\¼m5·*)O>hR &éö®†ü†².#t4ÅÚfôTÅ§€ğüìT6›ï¿&ér:)ıesìŠ–¢¼ä´IÈQ6Î±†TVÒ¼ØŠÆNÆ&ôX4…î°Ì¬ŸGs¿Š_Æo<×@’Mø¸z}Ë`ÿXÄû«‚vB~¨½W€,¶ğ®Äw};2ÿfÌºÒMÈ’Ã|T=ò{Æí~è‡šİ=McüƒôáÏ:¦7íE8Œn¹Hh•Ì¥ŠuËùT–tËlj˜nTzpªŒš·wåh³şŒ<ìhÀrz„"æG @hFxdØúnîA
—¼¾LıÛÏ¸G9Ìú0€EL‡ZÈeüÌ mzÕŸ–±“‘•şi¿¤(¦ğ©xÁÙFOz‰ 2‰UqcV’?¹átu6kñğP/óN±ÿd}5¤èöW;·î—ÊLötiš¸Œt¡ŒvÅ)L¬3Ì÷³¬W\U/•ÎôYÕ[ÊƒßV½—»“„¢ÕÂs·Ö6)|•.ì!Sš˜æê4Ò@1_Ë@‚ùª­IŠ ë
†6Ë7ÔÇù0ê#ËAvd«ÅŸô±÷hF¾„Ãú-ƒñc!™#ğu]Ğv9ÿ:¤–j)OÀ³@±ğ,(oŠq÷©L•ñìı<˜Ø´UËn°úÀ¿Šk³ŒœÖäš·5Ñ>}ß%ûñú5©IÎ³+àMaÇjá‘/’vÑJ6Şÿ(Â
DwšÓÄ´…ı¦´“İ,2aoi š% U¼Ia¸b¬™æŞŠ¦²%’¡L@ñôæÓÓw®öÄŒ32ª::gP¿où‚Ê0Õ”F^~)¥|ÕâÍ%;ILiÚØŒøÃ»MŸ&˜,Icœ·±·,lY-Š¸äês¥8z"°‹5ÁËœ9zqprêÍ…ÄC6KäÛb³ºâÉ–híF”Z^<İgóyTyq(çvo{HÌM|‘Òë'Æa¼Ô  ‡‰CP€	À¡ßíXrjäë
¾´ÔAVPe(ˆûO2¡&´=HÛÉÀ:”ˆG§ê;¤jñ€p¢“¢Y
tİ«Ø‰â‡Ë¤U0ÚËr¤¼ÂY,q¨AVB%Á©É>Ã]ë¬õ·ÀXÒ4Ë½¦ Šè÷Ú§'®<èÌaL§ªåAÑÀêÌå1b±™z].p/*ôÃ ÷îĞšğ§üg
è:_A=ç)yÊ•Î&•¶õçUH%ó †±oÄ5úb»²ß‘ºR «³áşy¼yçD¦ÂùB|"oè3ì–ôÖıp­/?Ê4A
¸qD¦NŠÂ…í™kË¹¢Ü,	Ãe\"óbëê~ıõhÊ“îvÔVæÎÁ·×·hê³»ñ«ngH¶à'r~£½³k\§&ƒ¿àä.¦êìZ¥ş#dqªGf·hƒ+¥Ö¤˜uò›fê´÷Òİ3‚2¦e~Áî@ˆ¿|«
‚<@:ş¥¸Ew,a\%ÑéXã+Ñ†3À`PŠ)Ë¹;luÅjÉ«Ÿr<Ç–í‚mX[¤uSÄšcp'¸]ñ×ßÑ[O‡”¬[ğ×*®n¾">°Úİ°B¤(óÏ¯şÚÅÍå¨puLÔz	ÅÙïq¼•†ËÆÁvÇÉH-½¨[›·mTLIàÒ°Š¹6f•2çè4Û¾‡È²?æ,>m½mŠ`(X›7NÁ3YäÌìWÜ°:Ş-øgãRİ •ôœ3ì(ïDûÈ™iğƒ¡ÊËÖ lq&NŸgÃ¥…í4(8Í„LF^ÂºíıhÙnÓé´õ¬Ço¼Á7âF5¹Ô¤@x±dò“'gq^ÄiÔ7ÂÃE\Ç+aÅ,úúªZN>£9»Šeúpƒe6¢.ÚÎËÎ:å0}	€$İıj‰>çg±ÀtĞw<e¶>{—=Éâ6Ò©.ÇìvÜ—Æ.‚™(|*mD¡®c‰e^¾P¤zDàÙ""fú²éë=h¢ÊJÃëjWFÿzÖïâê$„´­L×`ÔËxµn†ÈF„“¢§Âñ<P¦ÑÜ­Üq	9Î-Õí×GÈé®ÀòB ÒŸlgÙ»L–/{+ºn%«~Dsà"9hg¢:n’çŸ`ğeÇ;i8kvhü=3Y¢PÄh–.Íõñ±µÈ>NÉT‘o’WŞ³‹“ÈC2Ñi&<Ghíßpî î‡1m[¦ H£³[=ÆHøÈöX;/J:Iîókä|)(2bhGä×œ)Ì;ÛÖï>•vcçï~ÃÄ+L…‰§zt?Mud$ñº|MòÆªä³<:ƒ‡|˜·Im\.ÿÂ~3 \Ã»İ˜Ê
«t|n›—¼•Ñê^äø7àg.?ª‹åÜXNÂ @˜Â~ãİƒC¯Á©E{×9TB$İªAçËKô‘Ş.½O„Ê®«ŒÜ’A:Ø	aª8ìÍç¡ĞÊ&»psÑãƒ¶‘„ÜaÉÊ›^¶ôo1ì§ğ“Ô—­»ª«¿KÔ99íë©Ê¨}‚|´²PfË²(mÍO1kb¿/¬êWfLºæGÄ“İ9<•LúÎFú+X,ş@R‡tÕhˆ9‰+\2ò+«*÷LfÎ²İM¦-.Õ#9¼­·ì÷{yzj{‚“E5©t„YÇ^Õ¬à:ç[W9—>¾!ã+NÈe1”†}*iGÒ"Ê‚¦ùõØÿlı—P ;Á»à¼Ã,"]Ş/œRôÅA+Ì}¿vÊ¬êÇ3ŞG˜¶´ÏÓ|€à·ä¥¨ÏR¨·!”ß¡Ïª°gò>Ñ'ñLèÕµêêŞêOh¾]cÓ_ÑšYFßnd,@ì‚pm„È=ÜğfŞ™!qï8 0ˆİ¾^ÆDv­•Â€Ø²r'“î´f©Ñ5bs¦¾‘3à™t‘|E³T1³*ïNXmKç#ÓH©É5Ğ“O–Ã¹Š¼&¶-ÎoàlÀ±§‰ÉÂDaöxÈhÁ8¡Õm'Ö»¿5±ydÖÏŠ5~ôĞ}Ig¢D¥£¿ZLWpOÊg'70h£ËhÏ=ëæ‚Ğ©9~©h^°dº=øŒıy¾1#Ğ¹cL2VÔ;q|#^ü5}QP9©ám’±•šàÁ#à¸{ìheØ¶Cê¸áÂùÕJZˆVÚ…NÌ	ó(ÏPwªú©À}ÊÜ
ß¼ŞXÛ;¿ÍOÁ)¨q ùv%ˆ`0áÇñR¨~†`ø%‡2@åUUŠ%Ñ.NeïJLò’‰ãrªÑÒCÂ$µGF½ßÉ[¤"2„cârŒ‚Ğiå¾ËÒµhS®Â›çG•³º]M¡PšÑ†Ò_6
Ä‰Z·¤ü|ÆæandxwTBœ’ÇÅ§&Öq‰7ÚWL—p5è>
Ò±^oüv§'(sé¡IçĞ7³	7ÎòĞzTæğÿ.œ=m rwuAødæRÑr’/ÿBÙ¬ÍÕ:¹eôóœø§œÜÒàªÏµÇûôµ^7-‹G.oı`{iùüˆla™*ãÊÿ^¹°ªµgÒÄEª@.»¹ƒÛ#RGÅÃ]­ÇIğ>zv'"Ü+q7§üõ3êcË‚ÍŒfwa‡Äï-p‹FÓÆ« ÆqŠö¨ø›âŠñí–
Ï7v˜" ¤è'‰Ä¦x\DÆşâuşêñÀÂ”Vœ•;ˆÒ$ÄÅ#Ôã‚Y‰NA–Éƒ'Ùöaı•~GLÇ&`û°7e{“-œ»qÒ,K°LÑÛåÚŠÄ)´n6–„Ï“,Íäa ÷81W&·(óyú9/øæ¶oë-fğ†›4Á«9ç¹±ñ©¸6Ñ6ÙÊ›cq+ŸÂO·”P™o¾vÆÜÎOYámÑN<¬ğÖWÌ8S:Y@,?4ßÑ aÁÓ:C˜Ÿm‘ˆlı¿c/ßÈ„}şj‰8¯fkàµãP¸æ~IÁXaÖÂ¯lq­º!9˜s|ĞH“õC`®b•åŸÜ7nTöîÜ´rMÙê+Ÿs±~x _93ÁöâËÂmÖ’Üç¥Ö*öËyX…iYjœ6Fd6ùt¼ğU§eíPwC£vô I½8êFw%a?&ïr¼ôNÛ¹úrb­üĞà\[`‹–ş_;@Å ¹şJÃ†8¶?só Õƒ¢¶¾ ÛK ©Ê yRµÚSŠËD¤)èÌ¡SäbïUŞ3€üX¤T‘½b„)ß¿Q‘²¾ğ#{VÁû… £ ÛK¿´GmâÉ+‹ÒìĞÏéÙø|°ßm/Qs»Ï’Ò« ´ä®ÏyŒ ²,û\ E¡«d™[³•Ñr)D|–bõ­§ÕŞ[%zMŞß¦™²7©°À+™Ó¥¿OLˆ“[…3÷~Æo}ö}“N÷£TdNìş•4&Ïà=ºÍW™ÕÕ?êËİ¦g˜qõyì!×6³;ŸŒí†~À¥JZ:@Üö;q:gßK’Ïs}• †Il{òU;Ï³ió™µùh®¾uI°P–Ê3OóYÜÄ+^4ŠtnZCslC’=oå
×øF@oÿhÈ½ò3(ır~ıO€(»?|iá{ï‘~¥mf 6ÙÚ0ê!
¾bÌ‰€ E ôÖ¢çÊ;ˆMì
PòŸ#veî¡=9Õ4EûÆÔ„ ­<#­İ‰å=²=v¼¨Ø¡!«“S¬Üh/ûZS+ï¡­“á}F¨]Kd:¢÷b4Fsªã]©—îÃ¡:}°2¹İ°ëâ¬©QSî«7bº–åæ;±~míå½‰;Ã^#EUŒkgU¼=Lz•,QHˆwpë¹‰1¬ç3=®[wßqŞ‹17,SOß*F1:ß8üÌZnù#m#vS°œÍ*n=[‰ÉíŸ¡
íª²²L5!‰@y¦ è½Ã!1¸êŒcc‰;dÖ(Ù\1ª`šğ)#ï]¾”|Å»E;üÂ‘€T´2›	/&æ¯s´¯éÅ<ª ›2„®ÎÄ_Rpr¦={clzeVw»}2Ó²Ãÿé/ÈÇ~s—Yt¼jüe„ÂF¯…³Ü_œÉ„ãm´Ÿéª„µ•ñ;Š‰çÛFĞc¡C¢øh•¨÷œ*İöM•=ì_º‰•bkVWØM”·õÛ·ğ*¥M>(Ğ`E©ĞË91ù<P[{>Š6:¾s¡Ùms’_1ZN)ëÃ ¿ßŠÕ.cA˜s2/a(s8tDÆær.KØ È¥û6…&Âr£2~g@—éøÂl^sëüƒcSÿÉ^VX¨—²­sv…6DäåQTÚ¯t0Q¿Ì£¯D{(áç`ç&„E¹Z–FrÀ°J’ÿD2R•Èû$fbàóu¯a™€5=²ˆIO&È[JpèÓD;ÁóZ+­“:.éo±ê`K±(/Zö¼ªß)©tSšuY¾‡ÉiŠBZ‘²~ï•B«ü²/õÑ%šQKÎ[ÇW¯¹FbJ¿s~ğÓ³ÒTSI&!^T=µ§ë©qxÇüsöêppáÀ©–á±õXÄ¥{aRÓ€¯Õ]q8lBÎşÿìîß ±L‚F>p]•øà1<²¼ï3·?m«Õx[„SQ“Ê%·ÁdpH/S‹PÛ|–îÌ€„a› /²|­Sµ%Ç,ÇiëÑš´ãIöÌR#_›2¾ˆ›İ–{ÅÌ­ÖºÎÜÃÎjéüï!ŸcÿWv|$H¯:pRnvjY)¶qvÁê7¢È(Û±%“ÆI`œe‰tj@hc?ÈÅZ?ç•ÀGÏ¤›§#×›*À~ÚPƒö&©3ÜwO‰‰›: f'Ÿ3ˆ²*¾ôM†aÓjtÊ†ğ¯œ°‹=ÇzT._§šÊHò†gAàt
={Ó°ïÜ.oöDÃ±'—ÿOÿ„‚„~`ĞÑ:Ñcs´îÛ£¿R–¾—Üö8”Uğç6ÊÀî2­z@.}b–Â‹È‰8èüüdk³ÖIVœ]%E~çj"[Ã®­‹ÍY‘^%1‡&Ìıw%°R\1¢ëğkI™¡dÊ¥#^l[,äÈwÿÔkª',ğVâÌ—¥D8fÖ(KØGH×5á¡¾Ô@DaxóO®~qh\ÒÂÿ­d„¨}–s4‡»ßOI’3bTÙ¾¤:êØ©Æ? ³ù£`Ş¢ÌŞ¬¥mİ#yXê99¯gh\«–¤OªîŒk4OÄ«‚fPñ}š°)œMˆ”a#?®U5G%Z¹TPÈ¨²Ã¶„s‡¢ØIA¿²ŒsØs¬•™¤¢ÇJ7Dè„•Õ’ ÕƒQ+¬à´qËöíç6ø’V$æw«µwª·ğÒ¾½İìOÁ?		/Èúë[é-UÚ»AâWy±ø•R¸êÙËÂ†pîçAÜÈMêI-,Ç¢±ÑÆa”¬¿Œ]pUï]€q±I‚¶=:àMÆ²¶éGÙM	ö²<èn¬ÿ,e¥ğÉãÓ `JèŞ@¨£ŸîE›>Ú;Álæ Çìb—®˜O‡¸ÊÒRÙà2î2Ÿ’ }A˜Z¼egÅ|–DJöÃ9¢ÕP8Õú‘ÃèXÖHøë¨åHÖun›ë‰a$ÙÛ2!ueÇi·ÔÃkqİÖ*4Hœ ”Ùœ H÷®Ş«“²^€jyë‘Œ9õ/`Ù¬˜ÆEášlî«C¾Zººû™å5^Ì®æoAÎ6áì/¡Ç¢ã®ŞÉR@N€mxáÔÂ’¿ëäv§ZJEüøĞÖî×ÌQ<¬=:?R¿Gc	W‡áüIJ¨@'Ÿ_±º5f®?íš·ÚÖ{µ…ëYÑ©š¨‰uÃ8)xzX_VŞ¼¦QÇ—Ç¹"44í×‰"xÄù—íHêâ¯ïkh¨mıÉ¯jôŞ+~º†ôƒÒ³OÏ	µvw5GXDÍçˆj{Ş‡šìî7Ñ_|	L
†øƒ(ï±ƒ÷• 2ùÁ[ÎˆÑĞ¸{;Mã ”¸ÍİíxgãF¥°Éöà}RøY¨WÊ6›,è?*ñ˜iPºÁÒIv¨w™bÁ1“:ä$°1a{†e_F@ğWĞ¨DÉ1æ¹o¦«ª=²¾ÓÑRèô	™¡š¯	Ÿ»?È>£@¿PÒ6èš™fúÍ9Êt   c¯--h£¸ ßº€ÀšT]v±Ägû    YZ