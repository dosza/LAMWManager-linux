#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="513182236"
MD5="300b92d4e741b622cb3ca171b23c2f00"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23324"
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
	echo Uncompressed size: 168 KB
	echo Compression: xz
	echo Date of packaging: Fri Aug  6 23:38:35 -03 2021
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
	echo OLDUSIZE=168
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
	MS_Printf "About to extract 168 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 168; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (168 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáßÿZÚ] ¼}•À1Dd]‡Á›PætİDõê2é~ˆŒæÈ(*ç&NfZ kş“öë —3­z	¸üîËº?{‘a¯ÇEØ4©c0é¼¦ëšß/“_] L]`Ÿ#á±]›­“4u±ÊÊ¤šÖOiv—ëÄõ¢1¢y…95…Hãw‡”ï±ãú•	DªAÏûÙ!àüéÎ_‰€ÆSµ²É{Èï3$L,[eZ¥]ˆ]×é`ûÈ…n[¨³dë}¿µ—“c)ÀÔ6¿ÿØ±Şx»É˜ßWçŠ&ÒbšoS4£V)ğ ¼ÊR•z`¶=È®½	dÚGª*U…¼¬Œíy¶ØÄ™÷]:Ò[y«'Wf'F0oÍ•ÌX»åÙòp¶£)RìÊsà™á[lÿÀStÔ»I‹m
~a±&'¨
ïíà7Ëæ’jMİP­•LıÆúš†kNj¼nÏØkÓK¯Zá×7ÛæÒÉKú5ƒGàç5òœ^Ì½±¼õ©ıŒÜFUõ®©x©ÆûlèzRj”Z•z"·Â¼w-ñ·ŠÜ8p†	X‹Œo
 ½"°Æ1 ì\jš°@ú9d«©¢}ZàS|s7q¿ü‘;J6£^4Áë3—>v&²˜,ò/L¾œóÄßØí	šĞª¥†1¥õY7ÆÁ«™6Å:y!(Ü"Ù²}Ã<h‹:Ô2"¦dÏ)vûòbiI:{ZÄ²ƒ;ˆhK7sƒË¨šE¿Öÿ`7™õí~¯[W±å‹m")Ó*ü–û6Ó9Xß—¿ı)¤ ªŸ-`<,*‰™ÂïùFñ)W€eÈuÄNüDëš ½^€üÄyğşcWèEeQSàæÃ·ÿ$5ì°3<Ë>©QÓÂMË)í(¤e¡å(ñKæ(Í²İ8dçî*â¯w¢%â ß»iim	^è;Ï‘wTFi´tÕ÷8RWê‚«6ŸØÌAIb0Ÿ6/í¶µ.¸ó?Óã'7Ò{½S¦ï¸d"éÔ ;³P½¡Š‚Ÿ—F÷É¥•<;¾l@ç3šiğé~L37‹š_xÃWOŠ¢A¤k¡ˆ-³ÚÖî½û»˜í:"#L×F©»7]OUsÿè5ƒ®›ŞŠÒ…>;·ÿ' öÜ¾LM‘cOå/”sî"å‘Šœn)€ÔëÀ×¥ìAùb¤ùªwä!ºé¸^PéRM¢ëÇÿÏèÀ˜qûD<ĞüÉ½‘Á¦Ğ®¡…DñC4ïh{ï‰ù0ôx‰Ñ/‚¼nñD¡¤'Œí€t.!Šã®œ ´ô¡8y²%Oïk²(.|ãê°ó9xÑ;M}U¥Æ'ÿÎÿcUğˆÆ$Qñ
N¬Ÿ\°™5èá†ÛW	¶ñ?xÁçiÕéÀm±ãû–…¢Kj–hjÉg\Tòf¥ØLöô¸´ƒZüïTÈ‰İoá‘””dv×ñzììö,[ddx×éœğ®(ô²Q¼Îğâe!›²Ò«‹ª‚™{b9ºuM)Ìw³N$cD>”j2‘ àTx„ÂÓ\zøÂ_,ÜR“ª@f¡¨³ş¤1xŒ‰°	0âİ£Ñ·ºïè»Vñ–’’!©€Á…µ­»h3ß¨¥oËØMÕ©ÁO{;r/q„NÅ|ğÁF]è¥“šÂSQìN ú—xCäñş¥‰)ôr£¨şÕ³f	ù8UbÚ&½´Sïa$|”¶‡ÊFà»L÷S“ Øø¾»Š 2\/Œ¾0àşÉ¼6Må\¸L3#8şƒóf^ÜØ¹ __|Ô©¿¶·Ç€È:ZšpØŸ‘p¤ğtš@Fšı ÛÁË
û•ˆ]³i¥x/FÔ ËO=–AäK§Š^ê1­g#Ø®qÆè›ÛY80Ñ¨âØÊc"¡QX;ówÛë'Oˆ?E2Lì±@œè£HB›GO%q(ÏÉ§ç„‚‘¬hÈ"JúhÒÈi^„™íE6¦•aŞè"Ö.¥ıÑ/»ç|ÚsÏ.sí÷cHç™¨cK†ßÄÆ<3ÊÜótK›K;`!¦r 4‹ÀAös¹IÙ¬Ù˜»ÌµuL÷ÒZ' |éY”ø`‰¯¹Ÿµ£ò~ï—µĞûáFägô…Èg<AÄ§»¾©Kâ9³°Ï‡!ä",Vë2dU2zQP®ÿî*-qV’x(’A¢9†¤1‰¿¡$’W›!UîE„´ì!›l
kDQ>O×Cß
íĞl¥Ü»ªg°/tr2u˜æU%‹ÉLXèü×68˜Ffrıºı 4V¼L
{G*0#ğÀ­"ÑÁ%7(KŞõŒñRàY¡cË¥òµI«íÒìæµ…"×p“ìÜòHUpŒ7h=e.ÅÛêBõVw™{uš8kÔR9ÜÒ}æî¬úp…´*èŸ„’r–ûkv{Az«¿’ <)Äâ‰GR—]WLåÍ¤ÓƒóoJv°L«Ø£é÷F»Áï˜¡ò}Ó‘¡Ópôgİ“,ñ¾ŸI­9—ÀãNöçßİõÿå3X9jmzBË/Õ–à)C5»2©ä¢ÌŒŒ‰>SyUµ¹ûë¨åÕÖ×ü©H™·¡ a¡aEûi•½ÑŠjò0ä•œ6:ù/S	G§7\çëÔMc‡Í|ÍŞÒ§½”«‰şçö”6¤Ï‚¹ş~#ıÆ/KÅXóªù/#ZÈW(»©Ûí‚ ¥ä¶˜šNÆ¡ Iƒé™´U«0œ‡Rdò=Áƒåg}ŞU]ıòrŸòpĞ¶÷8›!Pgæ&“ıêïœ‹‹˜©ŸNTú˜ H\è¸£ğÀ0†A;ıhõ¥aVîí(²8·öóêi™ê*%ÖHù¢7Rb‰ã‡UÊÔ¨oPiß, ¡¯ªræM/æZ8„Üz#C|“QÆÂa÷yÄ72iM÷—N»¤$e"ˆï•LÀlœEˆü¬3ø½(}LJÜô|)?^¢q ŒW€–mÙZüôÁ¦Ç‘¸¥´¦?}è÷òhşÄÑu‡¾d‰ûí¨GX%éØˆÒ6‡ÊAwd­üÒÊüká¾OsmÜÇ·ÔòHñ˜€Eè(’úİ_÷~åe7 ª	yG²N¤tø²8pé¥[õ*,«`uU_º‹RúËG'KŸRJJ˜¯^»KVjaÉÙê¤'Vf|Áp†æHq&¤ñÔ-Í•¶ÿü‹’10OĞP'ù³s}°Ë¬‘Æ"-.
ÖùR“¨Æ³½mû‘¡ÂÙ*cD›ğ£Û>
ç`Ü°-šŸÛë¬aÅ©HGŠ¡¸át,á”X>ÖîŒÜí~9èƒòµhÎçÇ†l3]VÉfÖèªôY˜¼¹üëp^äîŠW’ÿ=ÿº'Ó•
¾Gù¿İ¡E¦"$uQ@(ÉÒ×°waW‰ğ¦§&š>±ØÖ~°ÊùúpÓ„Tó¾
^:å$u-L4
Õ‹0İˆ±øuLd“Ñ’†2í'ø.àÎVÄ“Ë_¬ÏÚšjöŒÁA5Ä„s:îç¯H!¶èam9@m%®S~Ê¢Ì©”ûÛÇ‹™pã„ß±—ÔËcÜs˜Ğpí¤g‚€ÜAî&ÂKL©T¬?±öäSÄ!áÖ°
½•ägß:ÿÆÔ˜øªg@Á›§!Tfı·ËÕ…¹®‰}4ŠèıŞh4½#ü|b« m78LÛÃy¾5hµY
Ê›âZä#À®ØÙç*÷æ+ì¼A“ÇKF>YËˆ)-»N2£b7\Îr§††4Äˆ„	>g•æÊm‚s£ 4ëš{r$m4ôf¼Ücóõ0
‚T}e55to´-ô#çôñØ\ÕöÙƒRUk±TÉQ)É¿vX2CŞbãÂ7ƒ³Sá¬–­ıc¢N)¨Pçîåt¦?ıaX‹t!¹*«ßE‘ø>Q
Èrû Æš¿	óeyŠÅ*ËÍzU^(o'¨"Šé.µ’`©îIÁú«²‚+ú• Ã•$˜É»5ª%ÌõLr¬-¿µC»FM9Môa^ÀğGps³Ãsx9MåNÅü oGB<r1Ú;°(&á=JÈ”2‰[æúâqÆ| àÃV%p—â?âA¦™vÂ¬ß¸º—À
‰µöº‹¨ğY½ÜQÆ=£ğ{¨=X—KÚ|v
C»§Ğ!$OÆ´ƒ|ƒÎ•3¨\"wŸµ¯å^R=·Vá®¼óÒóJ‚Ñ‘‰erØF¹;yDŞczülUJõSÙ¡U*"ud¼XF·)>·Ê¿À`â]ƒDóÅÁkÛfoì)-ŸQ?Ú†šCO¼0D=±dÁcÀı:ûQAï÷(˜ö“¿g_ë½ğ1¥Âk7„¿¯}‘öE6àU\:M¶&‘.MãŠA#¨[öYë
–›Kc!‚xEæË aÈŒu“ÏşıˆJµ©»…˜˜_Õê"À@CÁÌ·»AO)ïÓ-•ººn9	×q>–'q `PGòÕµ|ãåŸõˆê®â:óÒ8á…;êb¨!‘Y‹EÍ°”m›‰ÁL#ÂQ…ØfH¼›ëLÒl·İ­h+ûp¦ÚÀgN~TLE¸)›y|Vµ˜É}g•öz¬0êPo{ÄIÄ¯£vgˆ­‡cMÚóÃcĞ2ÃÌ9ŒGjº\mÍJìãît›àa“s©;°e\*•ïÜ…A-­Bzåá=I²\,1}şıë?8š8.ğYïpœk8À2×÷æ²T­@Ö½SÁÇ2+¨E–{ÊW¤] R*.iã•ÉçâÎ–Mˆ~ôÌ"”a±(H:[$"«™›“®%ËÑè–õ‘Ñ‰‘LÿQùW´4_,,C3>¤"\H6sdÂÍÖ“ÛYrª[åìMûŞ}“e‘@ßĞEõÜJ°.7ÆöSBd‚Wí‘Ât£šw“êïW”îĞ½“Iúµœzø ÄaãØ-$ˆ4¾ëû0>™…ú9‚˜|ÜáÕ!qİ×ùˆÇÍç‘OI`Ü‚kÿ»âv',OÒúÅı¹#vÉ–¼ŞDÿg<LG÷<2§­!Jí?4$¶ŞÅÀÎ$Ms"hNs”R¹ö€KN¨»uºÀKõç”qøaU¡”ñ‚-72çdD¡Uø\ä"rˆ3gI¢nƒ#Æ[’Šµ_Ü=´Áä3ÏM¹R¸ájö^¥ù8B¹¤Ï( ‡dáÿâ°2nŒP 	P+Iÿ‰L–ÂŞë4­ö¸ºøÍ¡šŸıÉë×:]˜bœOû¢Ë]“¸â(ªÓ•+Hâ¨Ìƒ#M<J`WïÖ-D‘0U8a\ß”(Ë“Ú"ÁÑ—¿CÜºÇT´jİ—ç”7ÿ&¹‡aÅN¸4J`g*!¼³f5‚†ŠT¡øáçÇ$5§RÄ©iô@5¹ú€B¬·(Áœ›ûàÿÓ­ç‘`.Åâ\Î3	î×úO¥ëìñÏ1ØĞDCl*S¦Û|»AN¼ù{àÅê7!ÁFtNÍàŞ“I]‹UB!8€[‘4ª'õÇlÍèñÙ÷bíõ²=eFÑÚYš¢€ŸøH1Q(–÷«İ’°*â-Á«Û:óY§wÚÕ`g£#Ô…|‘{µÁâÏ!•9’ı×xVü¼Tã°Eì­ÙaP8sö;eÆ?N¿sË++3şl!])k¬f9²'³‘"Sˆ/øSMÁÖÍ­,† Âë°è–ß¸SD¬NŸaCMG‚Ü´ÎÎ‰,Á•tã#É)?ıªã­ôm×Ä_ÒÊô?¿4³'2TYşO¡ÑßeB?m÷×Pç&3×‚Ó]H¿¬W|:hÊ¯ñöFñHÊs”İå¥T~A!û<Š'}” €Ëºa,ú«ÀÍÛ¡÷N‡.Š¹
;ªĞƒŠÈËlwò{G·D;5	IV¬¢f^¶`Üß¿DÉ5ÊÀgdÍxç:H^,´wDGñï%ìN`ÿñg«6È‰‰FÎ™ˆûÀ›aá”Ï„ÌáOÄè­ûUVv :»bšmğ}Ò§M_‡==ùŞ‰W8Ñ‹dƒ”jEè5ÏêSPªFwŞƒ K½¡á ò|lZgú@‡å“ ¿Ç=­YYıªYZÎ`yÓg1È›Â˜#Æz¡kFülÏÿg{XpD$‚dÛ›§Ì<06ÀŞPbû¼Øõ0‡)A«ˆnıAù¼É”š¸bÇ»Ï¦©šø\§V'¨¹9Ïnzà|uÏµç±[)lR%¹Ë²FèMè?d<|í×GŒ9ÃÜSÔ€Ş×¦Ô*‚ıÑ¾ù“ğhk‘ëŒ&-Ù«ê•b—ÈbĞËf¸ÍšÜÀA>İ
ê‹'euº¨’Û€JK‚\å.K0¶³éƒÇ_§¶ÖËãÚÀõúy?³;àÍkç„02 ,®1?xÈkÍ8ÃÑ.ò.HÌİó·ƒûr‹Öt±m®k#COš…_³ 'T-Ğ÷PËêì¶gOæ§Z½Ì~Aäİ:ªˆ½ğºÉ²‘ºpÍa`‹¿S¡iâ2rwCJ+˜¢Üø”ş€’»!Ì*«EJ—c([™®Tç­œ«PŒò< `\§‚f‡©³§ìÒ°ÌP¥öƒ2}F¾ç‰­Iİbå€—À*%ïd(ò¿§—2n¸z•¶¢ö} }¢ğAË~Mò>hºK"r:+ZÓL[ø!®cs8@ÄÿQã»dªğ8A²“ +1yÀ&
ÿ6a™ÜÂ3ş†TìEös¡3õB¿ü¼E–şüJfÒ5~&	cW~[¥ºª’Î‰ =jÖ?È0³­r9öz=oJ°XÌÆ&_»¬ö¬ÀîA‡@¯m[cüw|8Ëæ»0;ÊLQ&­0>nOşdÉ_õ1'aVw”@›»$¬{ˆ‚ûÜ¼ìü"#¹ëˆsĞÒ§«ë²É“Ú)Ê
ƒ~â^‹Üø§¨·ôƒ¢ˆ§‘0	¾ßşTÀÅå#`¹ú ŞÄ¸ï¹¬—ò‚€Á@‹5À3×°KótÜ	Ÿ%€»a!¼òÏ]/ˆ^LjÉºCq³°n¢p(-nğ™8íóÉj<,Z‡+¶×’øıb‘»Ú™ì™±Z¶ÿ‰<ë×Éò°×ÜF–’96ÂJ5{ü(‰Ê¥·NäïÙ¼ígÒOì;˜ÒÁ‹è¡ë$¡N½¼ëˆóµú§ÈZ˜|¼‹ÊÏ­E˜à¨…mn,”Ã(ğÂiû@y=jAØ)¨÷õ|€°«[šİvL{g<Î†H íA<hÆ¤Á9Ù1Ôsß¼şAŒ^û$lÖOã){ÊÃœªáé:ç^íöA°¾ä0¬„¿å¾naÎnìV:q‚¤BoÓs<¡e%9ìÃy¦õcˆ¸¢P±Oõ94œÜo‰¦¤-”a+6Cçf$£š}&Ë“XFHvn¯A!«ËÖµ5¶ßèqÀ¹h ĞÔ‘J>VTIÄ67v°\@Sß»Ø(ºŸä²xÀä†ätáAîé xÖÉ{?Ê»` V¥y/âÅõû!{ án]ËšH_AF¤•Iè ŒèIõsİÅtí‚»ñÊJ¬[YÑ!CÏq?Î j5Mxƒ¥Ÿ+ûj6T-û2:ş2W't!™újµR¹õÈû/&ù§4:­vh¼j|!I]«¡H´ô_Æ\/ª¶Òó³á›meobHC( ŞOê¬)µàrrk¢réæ´:ßNe*Ï†8†*¸Ôy.…ÉŸğgÙtaùŒ,X½z6BÊÆàfª¯Ä¯v#ÀF-û%áš-	{^âbÚL5ó\…¾èdÖCI¾yù»_êçZ®ßpäêg;1ÓCU¸RsB·VLf—e!Ğ#ˆ>#¾gáB\•×ù5„2'½1‰Sâ£æÎj	1(†’±î>*&È*£ö8¾ ÇÅ€¬åŞcFX2NhojÆì¢YÁ¾Œü¦œÛÈ#úkC0ê#R¡óÒİœN¥NúÉ¥‹cKpb\g/Ÿ¬av42Â¶±ı´îŠhÁÛş*·JÒqÖhí³P=¤á²ârßYRÚŞÀ}€äR^axj¿¤zÂ„Mìwy¼ô¿e1AFËö&KÂº/!³·°)˜$¹˜ãí§ØQÒ¨ò7kKşÇßyÎ–Ú-húF¤Ùšƒrª"Ş¢¾B‚œxù?–i]§Æ×¦i·|´Ç££3^€÷ñßzJ”€^°’Xq·×˜nÿ«÷Š	ÙKâo™€nbáµY´! I€¨,ît•³),ÈQ²wµ@ªC9õwJ1ŞEòãq¤ÑYxXèï?Ÿ-ÈÇMÏù4›ª"ê2­®×©í½ìæ¾(î,Tv<ª‘— ²ÌÎ"Tæn©¿±Ğyœ‰b°}#ä@é`ğOÑ¨BÁğz“â¢Ç7X›à†`+ÎU3$®cÉAëÔéõuy¬b[;	"»½;-2šè;„½fk¿/f¼÷ÇlşzIGá˜ã¨gõ²-û±=d~AU—V‰ü8øÿ!¹ ©á]ãLìcAà<ˆñtØÄ9ºÿ8šÉ
ä’Sòºÿ®Ü~Ó_c{¥‚ü³ovœ÷oòID,ÅñWû	.¨¸ÉHûcÒiGVIH‚a‹o×,m·z9¯o(ºŠaœ}h|Ä¡vËO¯£Ã”MP¶Ùê+~…Í…ÁÃæ°}Íx.øAºC©)‹›õk^JŸìÎ‡†ê
wİ_7«¼n«pXRÇ×İ´µè#8Ë à*ƒ.g©ÜØçaA¢ËYy_ëå.§Üù^0V­XÀô,ãÚ–ínä<f™FÛ´ç[ğŒ}š0A%}\ÃÚräTGıKJG73&*5°ømÜÎ¯Ç,Uä´ßäÙÕòR)ub­_Õ`Bî*ÒlÒí ƒYÉ±`P‡$Sh\ş	~ÄE*4¶È›ÆélÅ„¦(Lw3k”¹qô	‘Ggë5ÖµÕDôÖª~ˆü`¬v¤ @ÖŒSó¸¾.È9ö¨Ì£	§„/‚ià­sÇ^z0g}ƒ#äög:ãA½–»“Y®ãàUx h#Íğ+41•}
E2hşÎÖ5¿¨5(ÂHÍ„T
GÔ/FØÓH[y X§ÿØ|YrÈYWÁA²Oqö×u) OÜw¼ÔNl#7pì{[êØ'X“n–T§É%§í×&æò°D{Hì5SH	¦LN™ÄaI¯>êa‘âz¯Èqš›·×ÃÌÚb¾¸Û¡Gmb-,HR*N°¸)Œ-`Ù  ¢wïğä‡Í8{&cv&HÊ¿Óôë|·¯
@åô†“şñéÀöåıäâRWÃ¾§p…Ìj<àØ‡“mŠb˜´X@•µìcaşİ'—?–J8gÍı‚ÖôÖñ˜NŞ¼ö²—ub•×%(™íg¼Æk¸æ½H&ìéÉC»µ=MCµÚ—áÎŒ^L\×<guıbZµ6F°?‡åYÙ_±¢‘öÈD3Œ'‘,]n.5Š'rİ·
¦X×#ÿf†äB'''¢É‹¶“Ô)ñ¼¤Ö©¤òè¼Ûù‹N¨RcÏYY³?p`B(’š ã]W9RÆZ-ãÍúS"£ µê“„Æé=`Å¡¢üúÍ»ë÷Ä2U%ã¯}¤ s´·c™{h"cTzEù1Å·aG¨Ô–1é¸–)’Öô6šq{]üÄÚÙ@~¿hZß¹	ìîƒ¦•^šş7c®†ŠPw›ºà[Ñá>ËİÄ,³±şß“§‡à[úÕ?@ƒ›9+}Ñ¼(ÒêòÒÕæ‰37ÍFŞmÜqÌábåµgEf0Éòj÷â;J‰|ßC|ï	„1¼Ä5w:÷Î›ŸÔ,ø£ÿ©‘Û«*ºIlèş*ÔÀôy„Ãı~Ñri%d*|?Ööë&9[L®lC‰g…’Ğ)7Ã
rONI&Š«#	)ögôÌ¹4½5I'ÅBúVØX:EsWNN†€gš*ú¾pëõWäê“ËIŒ¿,Î+×¬J
éáä®1d÷(©C)Up/Üâj7;ı“¦Ç€(“åGLFpam>Xl/KêBßÎa/gl—è6ZKÜÊáŞ-‹És4Ñ´k"vê°v-¢éáˆ[ÃrËûSS›\Z­/ÄğW™Ñ#C¼‹¯Òù|¼¿‡'ïÖ—¹ÇënáGÁÛ³¼µ;ê¬¿öÖÏ»ÓàVÜÙˆÀà†>ÆI|T¨šÍ—³Ì÷Üİìµ~šô=:µqÌÑF	i‚
Ü¨tªVÆ}`UŒ`Gç²j`c„CÃã9µRÊ`Lu“l)Ò™>2'LıEwAÚ”ÛKâÔ¯r³7˜ä#h¦ë2©6òh ÌX]±AHM¡Æ¤Ûœ&¾]`vKõûYÊ)vã™ÒwR˜à‡ûrGŒë+|‡Î?ŠŞTÄ?A‹9àRõTX– r£À!ïxÀôÌkóf Ç§ ˜‹ã¶ËwDòp/N•;†EÏìxykâ¢tì£ú†{®ôšà3·NÔ"–¦14{ÉÇ¾¿Zˆ²¼YE†¼óc*tø¸]ÈCaÓ¼-!•İåö*×ÒvÊDšªùìÎ.^‡=O/ı8’"¡Œ•š–É×ËøáüøT’˜çlË{LVt¼Ÿ¬ë-$É‰,÷V°´&È(¿ zr9WöQD'ùfÅ`¯]¤Ç’ŒklDV®vPí$m‚ÓüòT¹t‘Ïû¬)²&qÃÍjŒ9ëı $å±<Ijœ¯yY‚ˆF¬âGQ´Ã2ÿ?	Éåºà¹"Èòp¾6ë$î\rÿpzF€kÂêÄÓ¥÷óŞJø3åÕ²+e”Ï~ñN?î‹mFÊ=={°ê¦æ ‘A–‘"<Jf6`´•»/pz{â¿ÿVQ[÷" éáH@p›JHöŠv,¬º³šGäoú"#s\FÒšı~»Ì	)ê‹ô3øÏd˜<ß@˜ïÏø”[B@Ê°Ñß4a9xGiC(¬!ìBÅlõAQ!,E¡û¶We’¯İ‡(2<]+íçB™E}Ö^}Ñòk§‘7ÕÍIüÖ +Ïîú*šB
%0 Ït¿ Nt7“´ŒL?ÆRë¼Õ©%°ì%[Ó¯ó3Qçgls ‡¼ÌŸé=tÑú-NÔå'(Î¬0ºƒ@uÙ÷(ˆ		YvPrÑ-óÅ’ª¼dg¹˜à¬àõøúŸ›»¸7$£‡uÃèñß×à*q$we²;/ï|‰ù7·×|Í@V:µ@ |'â"€,z¾¦ˆ¯0zmå–j-µ÷ÕõzÖÁøçµÓ<Ê‚â¬d<»£¦Oş¾Pğ_kÀM…ÚHÇ!”EÉÚø^@w@Ğ¥)ãvl-ÑÅ*·n}p~'+ğô$çĞğtnˆM¦ ,çƒ"Ã¶{L×ìQ`ßP]
!€–‚º&§»±ı>ëm[0tB
ø9×9è™{
ŸŸûïæA…{DWˆš¯B©vQYŒ’VfòQ]ßDgÚß=€e²é´e5Ã¶ßÔ‘ö”‰™áô8>	[Í‚"ÿdÖƒ•Kªo§àÖTŞ‰‘w‘¦<tH)Ã¥şÂ’¶´I4Á€Ì,İ¥¢™à-¨$fä¾Ê¦M‘–öàê*t’ªNÍuœ¾pÊ.Ge"pä&œxWìé#îãšSf_Ù š½Ò’Xé»<*$¿ÍÖfú²Ş(‹3öÒËN@ğ¿AÌDŒÁ÷øæ"
L)#vìö…†ù·c	O2‡¡˜P±Ğw:máÈÄ”èõ€5ÿM…‹ ©[¬—	Icècës£¤J:Btpƒe«½+Úò¶kî`ÔĞ€çÔBKª¬§à^b½Ï®¼YfùW*E×{If‹|àV(8 ¤Õ¢9á2+L¯°G¥{dŠi¤rş[ŠJ?ú?NœgÖ¤tÆ'Ä}¶ÕÙé¸çCÛÆòÎÜ¡›·•WŒà²M#6w}U3e<áşº~Ò³åûZ_*JJY*ñTc/-ã b,j|h?ïÑá¡›[Ûuæ×6 ôZNuAô¶ùª˜ˆ›Ië¢ĞŸë‰ã7…pŞf•OHşLÌÆ3elEéÑaØÚm(£gü°S*”7’v‹ÊYBÔÙ8÷fÕ<‹ho¿	-±õÒÍ·¬îLX;®ùê!îş­^TO°ï¨–ÔÓJÚ¶‡Tø*ÆXññ*r¸nMÍÚü:æ\kuqĞ‹ë@w|`RBm :x{H¢dºÇÃ…4Ş«Ör·¬48£“êÆ ‘)p·yèÉˆÔœi‚0òÜo–Ÿ˜kuŞÁ|°¢ ŠO®ÇèJËØ|'é©µhÔpoxëm›hiQ¬½ÉI;ÇúÓi2á*A/Õ’Ö‘ßPXzäùµô’6¢G¡ºÔ02w§0ñ(7cËª]ú$1y‘’Ğ«!¢ä½şFïi!ıÍ\ï«g–¹àä#İ¼³Ë|yŞéê.ıâ]^=£D‹Úk¤.c´Ÿ«Ê_hĞ`w^‹É
¸´vdoü:ÓÛ0ËÕšví8 °?„d!5 Géá‘cpİ¥P%·¼Tq(:‚¸FY>;ı<­6›.sànMÈ<ß'ë‘şİ—ˆÈÂÆi’?NY5»R’áaL}R…kë;úfÁZöy$ŠÒikóó’ì+l…Ä%l†‡:–5Úİ@WT é$@RÓ–†xàµE.0#‹h—SÀ%D	¸=nmq+?Ëïë¬* ùKTç!N‚V¹’€tg¬˜¼¦RöDŒJÀ™üLg	õ•Úk•¾’š7ó|…ó\‚[.]ü‚sH@b.Ê%#5éML
¤Söãî‘à´Î}	Ş†Ÿjh-¿AkÁÿœ“O¦üÉäM2nL¥¼ã‚Ç ŒÇÖW	E‹ê×n5¦;šï¾~¥ä‹x†	J£&¡ò4%;*oVCıÎtOÂù *>y¢Z*Hã	¸ jpä?6 pwo/ª?[™Åy­©³’¼ûÎZ•÷ªÜ
¨vÒµàw^X<DX(µI:W÷³‡|]óAV¼JôÕBº-r†;Rû
øU¯E HQK!¶4;7ìa §@¤»”R§N¶»q¬³yı‘%’pZØ^É;‘´öÖ¤«ZAÖ#Z°‡sŞ•P3$ôWt`¼r[ÿ/S€®èş>¥Ë='¾ƒBäíï`ÅE_aœx-h>B3ê:½àñ’R« Á\¯ 7«ı¢8~â–uÔ<½ÕÕy”xH}4iöpç"A¸¨Q†áTWì,¥­Ë»Æk‹¡Æ:jdˆtv¸¤Ï¨3°èß•ÊFôå&=>€»=Â°Õw†An•O‘e+	‚¯œ.›‚¹º©È„($¢ÄğC<ôË}…É.í¯Üÿôôª[ù¥&˜(W™¸KÒÖ„f	‰•¿’©Eµ‡È'ñI‹øïÜ’Ñœ…Wõâ¦%ë±:®ĞÏÿ+$Š··™³ÂF‰—cÉÎ1ÓF ‡S­İeE6,Ñ¼Í±KR™ùô¿K‰l"Ú¶¥ve;;×ZXSCËÕõŞyYJéÀÌ3‘şJŠØZ"¢Ğ¼sMA‘Ü£H0k-ƒ’Âò£T@¯áS²ëê…NT¦À†ºn ¨¶œIÏS—’a.[ÀŒTo‚ÃÇîT’38¶"Ú€‚Yè0³œ°ï894ß*¹"ZDÒ Xs)6ŞFõáJ'x~{Â¡ôB'bøc·ÒÖ«±L—“·HŸ1d^nÁñ×2 Q3\sÛ„¼½°'ÀïGó~şZH#_HÄ#˜Œ?Q1Şx¡È½qOş¥—¢" ›KY_á#‘e@¶¯k¢$ï²I0Øõ <âj •ı“Ú ­BÅRè­LfŠ¾Ô(O²]WBt¯f|Z-¹‰{aGH÷º]ÄpÑıÄˆ£ĞáNÒ”z§u¯Á%gÏ©Ì—„Œ§‡88Gˆá__ QŠhI–
IUóáCFğİ‘	GdælI+•;@ó~2vî/ü®áçéÀÏ¥¥Ã%<1GËâ>¢]äØ‘æ›=O5 éDØ3.S±Õ÷û•ıvòÉ/š d	¥“èäû•µ-~Ûÿ£o°»a¹¡{°²Eb?4]…¼pMfÃc|Ì`ÓU	›1.J¨6Ú	H˜î\ØêÉË&XÊ?Q7b€	¨ÏÑ2òœ›ŸZxˆÙ#°)†b…niäuÖ‘8ÚÒ
å¡rIx]O€!•ôíî*‡Ğ,~#Ç1í/(-üÉº Á=£v³¹”• âfˆù¦ì¸e&¨x…ş¥ĞËdÎaªêšñˆké]©0(Ø™&PXCÒÌäÇÚ¬?	v2}ÿæA´:¢n0BúåöŞò¾/û¿tÌñr·ıãÍz
3jØ¤*IÊDB|"‘Ô“è—ğáH¾LxÌĞ—:(ÚÅËR^Ï\M³gs¶9jKİÅ!Úz™«REËèşíÚ8Â¥Eº=NúEŸ¢Ğ](“|VRjºåyáüä[ ñ0‡&f±ƒ4 uéMeĞ45X§Âµ§µíI¤x#9c^“¾â?ÔØ›Af$“M†ÑÀçFÕ>.*ÁR2Pëä©n ÎÔyìóFŒ¤ë“”ıt4»IıKß¥ù«YˆÛ ş­×¬tÖ;b_»¼+0EYäÊ˜õÄö‚¯º¥}(LÈñ¥Ú°SñSXgmŠ6-»	k@7¢z÷;$oõØ˜Y¯AuÜO€ÂñaìÎùs)õë¹ßç ¡’´ÀWåâ—ÆWMAA_côğóE…÷N˜o=NŒéyvHk’0áMşŞ÷¼Ç:L7X_$¢<[TŒìúêö“UŠ¹˜Û–m!`+>ÑíĞ'lĞvo;3-³¬i\´ u÷©Ñ<c‰´~y»sÍrL%ÿP†Ş`]s·Xv<˜õÅ3ÎˆmÑa3°šÏÑ¯ÖpåÒ#Ö›„4tl³İÊ8vù"~ŒÙ‹¯°i'vA3íVP‰²çG‘˜d`aGS•JJ·À²R««"½é »+Á¢meÇ•¹Ÿ­éøŸázà5yŞ·~^kŠ‘R›P¥ò™u5ÎòF£8à²n½zC»éà’@thAkQşáÔéĞ½ZB|ÉE¯guN2ªf×oIŒ1–^š^~€­g¥p…¿Şa,^=(z¢â—Gãw²ö W•W†ĞÖ=çú;öFÔâD¥ê´úâØúH«'Ñº y	ùEîóD‹T®—ú+öE½Ü‰—4^aI ¡î éM•Ï®KsOîlXQDş EÒÉ
ªQdKÿO"ÕRÖ“ÜyØïëò|[½&‰1¦¸
¬wğ8F»ÊNVğª5ºó¶/hÑ(:%e%•ˆŞI²áµ©Ÿv‘‘’wÕ*ë™oSÍÜU> ¥ƒĞkğ'½Lwç`Ã€dÖ4°|w³ñ0÷_ñ\ÕPgÒj3y1IT‘¨É¾ÈÒÇÚŠH­~ì€J„’1:½‡Ée[i³Ö&ÊHÇfb{Æä–ûà$5{Ôs?¸±ªÆMÚ>âQà(T°­ÎL÷ƒoÿ3©y|¹Æ_`†è;Ğ–5Ş´Õy+BÅ1Ø0›î¯ô;ôQnF°‹J¡=zèç—Ì»fb¸°àgç.æ9½Õ±^e$!2RG-½PÚ’ÀD·#p[¾#”J÷Ö2#íø”F‚Wv’ıü>º&tiÛœ¤Q¢ëcg¢r}XY:Nò	~…àÖqc%†Rsë(¬çŞ@€XÆÓ†Z‰–™A9p3ü/ÛÚC÷«Èp{a—Œ¦P¢ÕÜ"TAğThGò,`´Ì†&§N£\fÕôá-L»ı,’:~Æ¾½ØLÁ"Ô‚`ô°æœ­!1bK¿+åÈvdr|½¾`ıi{ªZŠ"1
Zî¥ñóIğ«!&*ã^‚rV¶´õ€P`~¥kRûï×F1pƒP‹ô?W™Ëw#ˆ_/aüIşÉlØneÃf#‹œê|xzk§ƒÄ<£à«¬ QLa¸{½séf$Šğ¾ÅÇ-LÌjÏ4Õ¾)GŸ«ülC•×ç´±ÓÎ¡£®×‹ÓYÂl¶àE’zGƒu·²*5ö€d}øF¹Wv×÷üŸ||Ó*P¬8Ïñ}Ïî| w¿Rêàiõlı9æ¯Só¿Íz\/»Õí$«Ìºv¶…V‰&;”õ[…¾”ŠÇ©¸=GÉõuş=ücˆÊIyRmˆºêjp/¤—j9Âí)Æ³šêOUxÄ­S]’!]ò%”µErYEª"¬µœ¼%k:-”xôµö	UlÜ‰Ä;FÛ`¡'ÇÊwRJ—™5ê¡Ğ¶²:65"µHM‹ùãÊıãÄñk‘jã-\–Ÿ<oŸ43²Ã¿8ª’ÖZ®”E¢Àq ã’jXô£zá#}Š”Íi—Vˆ“J_êN|OÿQc©¾¼pªÏ³tŸ9`š6Û(ùu’ÿo—ø?<³£y*2ƒ>ıÙ=9Á¨âÍn4CLû)üœŠœå-ÂOøáí_Üå¸&¥Ò:ï
‰“¼oñ¦¨E
İÂğ(JVN‰ƒZ72ë:~è³¿Ó…>N~Ç_/7¾Â(m­€<­ÀïC¹w2èÃ™Ú—ú;œ†¡Mo‚àGÒb’ õ_×¡¿kJ–ƒš6iÙf®ŸÕPzÃ‰ç‰eØTwÆ8Ë2«¶ğ©ÒL9"Ç-Œ²¥›dÉI·ên¡“yY‡9óÇĞDSX‡”=è£ş¥c§’.'£ŒxîÔQw[i¥¾	„{†úÕK{wÌÎÎû%Ú"66Âù‰90ÍŞ0Ã¸éÉwAi—Úÿ‰dï;å¬c5Ã˜5}ÛîAçĞ[\÷nV8Ùç(! ÓübºÔ½{O±R®cmIl NÁváÔÒ&ì³§¯**±Ÿ­gÜß›Ê0]““;ş>ìŒ9%-ª`ë‹¦-F6¨©h¹Ö%QÄrç| ‰µÑ OƒÁ³d¦ˆg~ñm‡ƒÿHV¢6ÌÖDûŸ7Ø˜h³VôÚË¤ûO;?¢e‡õ¼n5KA]f³>]‚Á€-âÇÑÔíOÄ=àbøA!>2©€¼Ë¿ü0º3¶ö£ê;ä Wÿ#×ÇKUÍ&cÓ_ñì"¶t3ğhğrBª¬²Î©ûÓ9ñK£‰œ¹)ûÁ³$‰îñøÒ¥JMv;‘A ÉêhÆØÊşĞCçâ[4÷¶‰ïF…Áü©š2U,¹Åù¦+Ò~¤³®“ë.š¿9VgÃÍ	‘p÷_u+ºùR«e7óÕ¯º‹1”»ÂKDŸn™Æ/ˆ’‹g¼îş×®ùµÓ¢*qöloPn=&ó‹8hßvÛëÎ¯î‚:N†ä/î_à–Ág—dûl³³iz–³ø³‚Â³‡¶UÒˆ©Æ¯U¶ù;³`÷‡ÌrEUwàfğIU@0 Fêzÿû»Êİ^_dôU]½­ÿ®lğŒ¢j5ÊäıZŸ*­IÍ;<ƒ6/NHPÂËš×hd¶tŠp…D&\ÿmgô³ÿ‰*õÕ”dO‚6ŒÌàXDŞ7šåŒÆGÇaYzÕâïu>BàH;å=8ë`òœÜ1vsğİ±d’“  ²—aÌi/Şw²³HFåó×¹bÁˆû>(ğ~a¶õ;cŒÄ2”Ci˜O¿‹qtb,(r®GİÚÔZI ¾;ÎÔ„fi†;Ú¬ØxÅ:‰íPÎ_|W›>>4kü[6©t(`œøªÂg»·SÈ Şü106àûşİ>+pzÔñG.<&F	·ÈÁÉZAÁšÒÑúÿĞsu›`£u…^sÚîÙ›ËÜ§Ó3ìÕ°áíÅóìèÚú¡"HşhS”(™£Âï‹-¯ª»şu<OøqZhj.Wˆ#Ìa!â8ıLøSéøÉöG”¼lÏÙjäÈ~
cRS&úÎeHˆç¶³Ô;¿¯»ì:ø‡¤ôhûWx—˜ÑVê‡Òÿ¾Ä÷½aWMlÆµ‰FÑy°™è—ã}Û}D+ş@WZªáğÔÜ"£ï/QALT[’ÌL•¢)ê#•H·ïB³Û†k®³ÛÇæï}CÄ£J3…Å»2ƒìÀİEGAÑú¶İIF`{²ğLRAãùÿ6Òó¼'wçŒB‰Öc+6ûè…ÿ@µ—
¸˜Ñ^A˜¬„jİşXIÌ;aŸˆ"Øâ+÷æSÌ€Ô²j³“_ƒJtÁ*Ç%Î¼­ÕR”ou¢øq9qé"çÇg	Mn§)›Tø;Â¢eª^©#1N¢ı^zÁù²Ç¼kq©aã÷”“©+ÿ»&Ôğœ¥´¿`u–}L=öwºPüú:w/âL ±£¾3wêâ]MÓ Çë’¤kwcíÙÌXª#0o½Òtzë¹ø.ìø­½•ÜO¦_‘ÛZEa¼çƒe³î€H:ÜÔì\CëËIu
ºiı~šÑÃÀŞ^IK»›S±8Nò3æ¤ƒTEéw©B?•(Ö§ùig›0ÜŒ¼`‘“!sä½è%´'z"õ B§s®]¸cÃ,üŠrÃeõö9?ñ $çŞ”3VbI–c§£•ƒ—Š_RÃ[VRuiÇiíŒ×³L(™O›¤Lªz?Óë`=^`›hfí¶qû~A„›«ÕpxÍÅsº4D@N§Š±
"]ºI@»
]‘£Yf™é®òS£ùpQüqÄ€œÀ/àÑû<ŒE=üòÿV¶Ì¡ä"gàV§~Î†ê7‰ µĞ»œ!|½lŸ¦ÄS ğôÈLj™\uwr¡\ëÔÇ„úWF²>´6@s¢?Üh^¸€'ñ'Y…Ÿ,éuÅ•šl”5ÌX_I¸³ãäb}‰+X&}ÚŸÈX{ÑGª¥,R!g¯(1¹¯
X¿.^×VÔ“_ü4=Â§¢š]Ty„:ÃÿàØ¥mıo€vÍôšbf«S™Ã®¤Á1©	í?àiQ’Ññ‹3wGfèèø´'øLP -~#úE¿—å’¯ƒ‚I8E-OaA,1’¾¯`}%İ×IÒÂæP^ØöË/Ä-²[ãÚ‚¦ˆ‘lhÛä mÇ¡V9†WLlÓ¤‘ÂT€r$6II×©·xıî¦EŠ$nQ¦ĞÑUBwúÚ%¥és÷C
E–¯¥vy9Ğ”™ü;é¾Á´Eb‰wHp@—YANˆ6òšŞa|ä(CÛÍJg×µ¿eÿBÃ¯®îfhû“7İCG1ÒºÂèxÅ]ìê‹dëˆã£‡¼{ì¾ü4>z–_(»än¬e­„š,”4,À9…¶e>Ä!3³’Éë-vm=)ÆÙ\¶fªŠ˜Qûú@m£ŠÅ] > ¬’L¾hL9_)xîº¢C,ìğFKóÛ|û /ñî–FoŒ6ŸÂTœÏÅ¾\’{–L(¡ÎÁËfù=•Ü7İlX$C	ãv^!^$WÒm3}Å1¦÷™têöê œğï¿ôáÕwƒK>'ìÿË½Ä/H±Ö.•5½<ŞOæ(5	ù î7™H¹WxgV’6bLäÓIè…Ä)>A$İ…oşXW‡×,¾]Ç4)Ä_­’ ıA½b‡.ëô"gS­½ıíÁ|*Íîl‹+yoéÊı¯ü|@]|5ÅírĞÉMØ—°†‰<sÉB„çoÎ íµCkt›'ç<nOÑÄÕ ¾½¯K'´(}ìb7ó†ˆØ^‚N‰Yp˜7Û.OH“Â]‚“Äo®Ï›Iùy{×F&ä>2€zXÈXı%uÏ­ `“RÓ²sÇu!Kš[•?Xˆ©ETQiYµ¤G -5âoÖÁ5°WbvK¸#w‡ÔÓÌëÒ€˜ànª6¨ğRû-x˜B»ÿ`ÔìöO€#áëúÔJáæ¹r:ŠÌıÃˆE6)®Êö´ƒÏó8©Ê?ëØl Á"ùµ•ûêwÀzÓ_³|¶)8'mÚzûˆk‘‰í…ºäé½©ïõRˆPª‘soãÖ~¿ş"h¬0fó„zu}•wÅşPİAÉæäŒï$–Q›5r›Ší xÓbİ±ö'TÚÓj©|'ê¢ı÷›O¢»†P×¬½õÏR°RWƒn¹^¥şñmwíİÖÔS¥[ Ub…$šÀü6&…5*¬}ñC[@ã²y`ıFÌí¤`S"'ñAğÃ€›¾™”ÜR€½KĞ‹[=Q‚)(!_ˆóV›ƒ`3¼dn½Ã«:Ñ’6…ôßhŒn^§ànšé÷É»3+±Å1¿$»üúÙçƒŠFe$à2JÍ¥I­/‹±V£ÆõRã‡B«$ôe¸4]õ¯Ò<fÄøˆÓ¶3ìØN²ÎÚÔ?Şu„ôn.¡q¹f™P 2S%”ß%Î ‡'|Ì¤´€ºâõÖªöFæÏ±É9pån„eÒ¥“¬{Q¹Û¤t(øà+e€ª¬xY¥ÙÄîŞœ±±ÖEÅà|ÖÊaG@äüZZeb¹éÊÙÎdÜÛ,¡&M{[ÿ’ªzÓC.p	¡˜°¤,Z]nçX}kãNl 	(ê¸”¹¯–±ˆúŠ†³}È»ÜO&0I£_,ê<iÓé&"°ŠÈ^*ó‡!0÷Ê
M´.+b@âósdÛ–Fï™€ÏÑ]O£–ÌÌzJÕ±fù(Ô@¦
C'ö¬0auüšƒ87éU¹ûƒ`$£”?•såêY¼»Œ¥®êVÎÕœÌ~€_»Â¯]ÖÒ—ÜGéÒ53´Ø"¹¼GAà6İµÊ‚ ƒÒàÙÒº`ÒZËqvèxëCQ×¦¸/iæKl'êñ+óšmãÁ‰ˆ³€ MÀÍD`ù'ÊÓ1»½pÌKI6urÜtœßd…ˆ€Ê«–tÓhÙ§rÆƒ9!­¥oíŒ# Å‡*åŞUÈÇÚñ¸(”èë–ßRü×!ÊÅÇµOŸ]å÷%oâvZì"{É@2¨İ½ëtç™q.Ó
8é¾ñ:Å¾6ñúw˜ Òœâş¥µ•d”.êâö.ÜÑÔ+Ô|ÏÄ7Gˆë€;4şd
Ç(“TËuşÁg]HÇŞ÷3m–@+’G ÙHSx°Ç.ÒEióZæéˆÄšX´>¹BlÈ'¸kÌwBÍü{8 ¥ö;].İ§äàg‰V×Tk^k¿ô†×Ff7…¥(Ü%=…Ö4X¥';À ¯ÙlÅÃú¶–û -ÿ¹#8ŞûÀ°Şe¤Óš~óB± eğL=:&96°¦PÁ³Û!dbckµJSô»X±ïÛ@ˆcºO¢# Ü<? Ä6Ş§o‚üÁRNl©Å’˜ò{(“•ØÙõÇ}´õ¸U‹‰QT»£04]›Kº«oØ™ôÁ¸AµtGC@=q.Ğ(Şõ!KÈîı?õÍa„­]Á’œFxOì´î¤Uo]0’œ»h8»ƒ„EæC ÉAÍ¡„¬ÌÖ¬ª^ODu<^Ê)@ğ†S‚;¼U˜ù”ééB6/p×ØEË.ğ¯nç)™ºŒ†@ähEYP(ùM @)œO×`€R–íÓîû“4—Ïšf*±éÎ§¢¤$‹Ä1èU®pø\Ø¯|:¢¸|–û÷ÃŞ‹œWCßàêbÆ.ŞJÒ£ƒI€q›1®é®àFá_ÆáĞ#‹Èûÿ¶âK?X«)oÏÊğq7w†œ!ÿ÷ªGBº~Â´a)#>o1a˜k^~âµfKiÎ•`lAÂµ³]°ÏO$ç)­›5ƒÎ”‰{?P_nıR‚ÖqÜ´kv±U‰–=ª¼ÅÿXÁîSt¦á^P"´°Û5†{#r‡IÔ4¹5P»‘	Ÿ\.¥âº*KÎ"†eí¹Ó{¿‘>ø=Ã.åˆ`:œ›Uå!*Áoş õ/S7nìğ=LåÂåµïBL}°ƒ‘ hšõ]a¡šùâõÄ1.5_»5Ñ+û)@`ë şø¦<•-°Œâ[ê¬jóZ™¥Lƒå;–ßWI•†·®°©Ó­&ƒ”ĞE¶\Ëx(áƒDÆY¬Kô³Şÿÿ‰ƒBI2ä_Öı„ˆo±ãl$í]Y²wq]¬ƒyA$[Ç‰nB¼ºŒ®6“†ÀÉò-•Im–q°±SÄ. k%JÚ¹u·-6
“š¦,ßI˜Qw8i¥ıõØˆ1ñğôƒÙ)ôÌÀŒÎh¼†¨æ+Ú2J3gÎ·Û'…KÎÿÂeb1²Ó7`éf!ˆ){Ş{oÉs$»^ÿ½ÿ!t8²Wx)©Fñ.)i ¬7VoZúŸœ!üë=nş'«‚Œõğo¡ËK4°•@òçºô}³@¶^#8òl®d¼L‘	‰ú¸W«÷ıc¿™_M®ªşÀÀÃ‡I‘kÑĞ¼ô†‚
¹dƒ4e ÊFÆ’]c%·H¾’ÖÚÒü&•lˆ7‹«è3r¢–S¬ŸÁ"Äg+‰~¸ôö8}‚f^ği¾{±ëÏÃ±u„¥^Ú?ÃÛqNØzøïxDá›E…ØtÁ°ô{°òu\¥OåúŞêÏ†÷p¸‚Ò/S½ÖySXMµ»u{÷å‡C#ôNÍI¾€È`Ó<«‚;–</œªõr—²—1Œ AùÅ1ÇtüîôB_À’ 4jõ€k5Î¶ÌÖ^å…Í@˜ù8=÷WÂˆ¾û ñòÏe¶ ´ÙIzfƒ‚¡„ò®¹YùoöJOüáR€øÇˆQMD”‰ªhÉâ©éÏ_	É‡©øäŠ¡_ ÚŠ¨‚QÎ”Ä;XJV)qÓ\Š«íCş©íôßQÚøÛ•–Î Èóş-\<¤ÙÁùà;.Œ]å™¨©è.zƒà[•Æ7ÔæÅ¥ØL{	y°ÀT*ÌfGï_³4ö…!—ús!98üX’FŸ©u“GºÖé#÷Ú*?„Ñ¦íüË¶W—=l¹h£È°æ\@C ÙÍã»ˆic ?0©=4ÒÃ˜h¯%üÜé3WÂnµ†…ŞÊùİ­[Gê@P–µ¸5¯"S0­#æAb£ÏpËKtğ'şØƒ!|ø)‡æi¿.¦NÂÛk?ŸZ”"+Ákrsë¨SPKHƒ³èåèCéf¶Õä¬Û$ß§¾ˆ±Ì;E/é›³²ù3L¶}m.WSNf‡Ûã-»¾™AÍè¹šxör´GùÃ”ï\±Åc Ò+‡¬º‚Åè”	cgğÙƒY¼|Œû:NWhš2ÑçF¹×±~ µh»Ì*CÉj¼î¨‘ _lùÚÖ‘Âæ™²øïFLËÚ±AßÜ·Ì4ÜğÁ’Ì)ù÷e—{Ğc¥ŞNz~ò7 ƒ³Õy€œ;ı\â—0õHã	©ÀÏHKz—¶ˆºÔ%r·]Ï|a¿×t˜Í¢ösµe›!¹	’'âoÉ‘¯]|¬ ¬”æ<-`ªô)²[®Q·JàÑu2^ğ!ËEŠb'v p‘Ş±l¿ÈY"#»‰ù,ëov t)Şæm‹íÉR ¹e)ó&ˆ¯c+¡ğÆoJa]vlJÄ[šnûÌ#`T’: :*=ı‚Z~e®¼ÿÌ]oôpÉPº˜¸økêßó‰=ÿFŞò³í!ŞÏ‘º¥øWÿ·ŒÅ(œ.FÉ“±³—¶0 ÃOùûC	Ê1VLc»j^¶Ù„-Q‘P.%O‘vhç élÊ3=85ú´ÈsË®›.áø/F¯ëBúîà¬°c-¦ºòòì>fÆ{€–sq‡CÓ*~jyà¼Hñ1íDŠ÷!¼Z|ÀàˆÛ3u­ÙÀ×1¶uMÍ~2Kõ×¯A'Åƒ‹ú{¬Z³íPµ¤ÎÍzØF9Néà~t¾å8?_XíÛ•ñÄĞ=í,…Çøª½è}b|s<`•B	ÿÛ3È•ß¸íãú(HÇM×ÓeÿXÏ9ÁÀÉa3%ì	{‰ÑCMî%£I5%5
„Ÿ\²ûÄÁ(O.áÇŞA·b§DMÁ]pÀw9À´v~Ò´—ÑÕ°°í|Ä;ÉÊá£­]õÎ†CgıÛZ~UZˆ`¶à.@ÍòE)›ÙçhÇ¸½àFU‡%¦óÉëCŞA4sxİ4<x~îÈñÆ3o#¢íuØŠ¬ChØı€'/^ìÏL±,Ûø³9hêÛ'\¬†ÓW';˜Õ!ıc´SĞ‡\ÛÃ0ˆú©¬‹SD:hN.î-. 'tŞM>Ğ§S“¯CÉÔ–ƒ&€]dŞæù y›³v… ¨JÿVcJá²¹²xk'U7M©…¾¿q­|0ğb7¯&ØÂœÙnØ+öéÄ€Z=M¾ßé'‚Øsi:ª[AªIìÛ1ãº\fUáBóÊ×¸-°Ÿ¨7åÎüyên¬CK}ÌyHÀÂ••Ï®|dí¿½c9ò›uùa¢È~–îLÓ‰ØÔûÚ‘ö	‹×5à©D–{éáŒ{z„¶‡ßRµyµ¶IP_SŒ¨åí¹bRÁ‡¤?47«‚®HGz¦(êj‚ëa‡’œÃá·!¹&ØÑ´G]£ˆˆ–MôíØÎXlæDïˆæ½ËƒOê¾ê8‘h>¼W1ÑËÁ«B§[AnJÔ^P]õİ õvÚÀUÌ‰úµÔÈcx=æAÏˆ¤"k#·<¡Yn/i©Ôh½~bl‹¯—§ÚÁŸèn6_á©U Ï8³Íõ~a7KŒD¹?äÜj`(¥"ƒK´õpît›¿Æ$ÆğëíÒCz…#*É.§ë²×J&<µ«d]ñ_ÓÅ"Ä×“øt1¡n¤Š¦–è]àôÒtµØ!İŠubOò•îJÍœQÒcJi÷ïš7s©˜"MÑƒúAÄìxüƒ=p%ËµÆvx×vñõtwõHÈƒB}ê«ZDìÆ<§Ôuo¬ì“Çgn·
Gª‰êo—Òú?†‡–Î¨E¥Y½íµû¶ÆSlKŒk¤¨ºkÍĞİØN‚y";Î|äÓå‹/Ç_Kù¶ûªG¿¤¿r5
¦|+ªƒ|”œ_ªôèƒåBg(¸4F§”–¤©Ö³î>cV½zĞİÛŒÎºˆ¨Êr}ñµTÌJ)ìêrBñ}¾¼! °€NÚJÁÎ½ÍÌ¾êre‚º¿-4BŸ‘®xÇë´ëp6jİÜ/ë".T‚‚÷íLk‚¢é?o¸0Ù²ôş?ÈwAg‰ ¢\?í›¿ÚB††F{×´“=z‡[†ÔÎ,–ò¼ÿtG®Dó\ğ¼*L[nlÿ×ÌMğĞXÙM|Ğ2ó<™éO¡"¨"ø•Ê\2#ã1À&ŸÜŒì‡µF5`-ÉíFOËÙ#¯%pÒƒã<Öš›·“;‚¸´óşjB¢?T/Ë^)·½xF¹ŞY÷ÍŸ•ªzérËL'º‘™×‡¼­>wÒj•qcøÇ§º²»İ=)D#•³ß!>NxFuÿõıUR?vĞUv7úÅ´ÆäÏ8¸ã•‚ßÖzyGÙ0~ûıœ’MùDNÉ §Rˆãx=ïzmû;ğ-%—¿ç¼l™ìMøğ­kÊKmXÑ-2ø¶%íÌªî%[J%N.tNä9;j·>‰ÿÏk&Ñ§üí ãõÉ¡Wßwjí2&#*~km)•µ¸–2³ÚS÷eï¡ÙÉ…)´áøV«ö¾gÉü:ÇM—ÎÖÆ7mO¡_æÀ¸şYçè½--…Øş&òˆ=q	ôé¨É_a
ë@HOË"œøEq—«ôtõë û…Ñb¹Ö‰@BüÁĞµO_<yK$öC½œŞ…NÈÛQ‹erÏoQHE+ì1Ö¬»ø –ÊBIQ!á5ÌKKÆÙÉQ…ÇËcÉ(ß¼ê7¼¡SFü¶ ò®]ÄFO(æÛ úkNi³ù_®¥ŒŞ«·}¬q,+”#"Ãêq‹5Š@şSµÙ©İÜíBç©	Eğ)ØÜ–t=ÀĞ©wf ‚èøòëœXõÇsãê¯©I¡;–ÕiTŠ<{©á?„ı¸×+—ıú&%¶İJÂ_áqÀëÎŸ¶Ràâ43åVæº(aûÁ[bBš3ITÑâ‰¯XóG»¶a—é ñ“Äu›–Òë9>ê¹€>Óö5[êœ\z€[r±´DAYñºQ&tQÜİ	}öeé¼m÷$ÎñL¾"ÃíÈ®ƒŠµÈàı®ŸKşví¥ø–¼¨tàœ÷JØ}-‚š{¥ü
:p3C ¢rõdïù­íû:Ê¡P"¯ŞVÄH#µ‡úÃi¬Ã‘÷M)á@“1Æë…¬Ì\7§d%àşó²4šµ¸ç¯2ë/Y¯îüğ˜Œ°~Èøö¯¯or°âÍmåzª]¬ÛÓ‹CéLÖøjZŞ!¦Dİ¾šI`mƒ1{"8¼ô…Ø‚„’<~!,‡ï+æ0Fú¦_šÔkşû¯ùœÙûòÑ…_Z¨1Â†UÌZ9AÑ‹L¡æH2¬:Ò}0j^³ jPüç¸ÂSxöÓŞ¾î^ƒEëLV¯·Åø¬a\dY9^ĞÀ,ÙkL,•RÅ€¹ÉÇPÂ_°5êÒáZûÎ¥,’éRjŒ‹Œ©-¡Å¿§³íf}rANôÈ–LM,hOŸ
Yô©İ4I¥†Ì=o!ø'ŒPÜò¥O´^®¡GŒI]×3#)Oğt6’;S—¹WJşê¤´®’•±¬ÚN6_$ F¼+nÑæP½í\É¤×ÎïÒ²:|ÉT]:å´Âz7‘îó4’îÎ†Ùñe'ú)¶5œ8ŒË°# œ2ÂÈP±Õ0ÒH •ºšPÂ/§@¸¦¦Á4M•,	"äKMó(I¾K €-,SÊ£E—'¥ß¤Ø±`Éøáv_×1ğÆ>k¶Æ»aša†M|)vN7#üÆÒ¿è^:—T¦ƒÜºª£BÅ…×" :Ç‰K3ø*Y¾ëjÀ.-	Åi¶Ãİ±ÓšaôÆ	¯¸­Ø4Ìcö´ÄÏ5¸×;aÁëQÿĞ&ãÓyO#ü&˜K\Gmå'@Åİ›ü²¬6óæá×Úı6n	‘nt7»`¡×ƒf’ Ä2–İ•¿ví$²é¿4×»9„óâïËOÏ®t9ëºãrSÑÇÓbáåˆ¿x¯%IÓS'*™Á7Fé~­;u67æM¶ÖŸˆˆØqwÅ±2ÉgíY•OWÓ¢X\¡hZÓîóZ*$lU­ˆûè›Tşiç™)É?[¡¢êÀµ/¬´<±vsñòVc„$(W+
ŒÉ?|>›©õªy“Hş1şŒTü}î½d«E<ÊÒQ{âÔŞ¨iX›¼IFUF”Ö×”fVÄ&]"¾q”Vœö;p	ÓtA%ˆ†g~€mu©6Üñ’$L>„rœ>w›ŞÿM.Û²
çQ'93ğç|ëÇ¼µ£z=c¯ànI¾Óˆ(ÿ£ZQƒà!#%fœï4s«î‚OSÒËú+¢ğëäïÏ…ÁêÏ=#I4îóÊƒ3ÿ@¿AğBx>+V½©ëÌ’YÈEp7Œ2Ûäïºx:œù‚“J‚h!*Í†Z^æİ
·ÖÕ³8[f39w?¸\mKÔC€û Iï_¹LD?Àµ×Â++\šÛsìX5Â]¢#h­<	6a
Å”‚Æ;îTïA¹<—öÊæÏ…Àòé×‰ğ8Äş'ÄsGˆÕ\D§¯}ÑMÿ9§ŞØÕ|É&\o‡°€²üô”<´XŒıw8rpöZ™M^U½3Ê)fã(>s/Šºb`„eP~•ôãôr°€n8TJÜLFÆïy7xÓ|,‡‘5*Ä	Ù¶à]÷ÑlÃ|"
Ûƒ©’åƒh!$úx Õ¼Ñˆ3pST½
eÓoÚâÊöh” 	™[«o™ÄVGğWnM”QêwY’»Ã¶l:Æ“´73å¸ß®û‰ì&ëm<+Ò4ë_°ó¾Ïº·(+ÊîãñÔ%]îı¿VGç¯	Ô&ãø‹ûw]Bt—­ÂSV¦İ•<ë°pÖcÉøí:ÿø-‰ê¹ÉÅ«xâŠâ~äÆ”MMù.{[½z3 ÷àMTº-ê€}Óİüö? Ùä/rÅxæÁ»I|œtËŒCÍå,û#á±Z¦ÈZò§>ÉGÉ|¥æ¾u˜ÙâÃZÚŸ»4ûZü@¦S	íëMbäs‚ü|´éx1· ò
‡[GÌXó†ã¬E¾3Ğ¦¼wwˆYµÂXEØûjœŸèçH|6håÛƒC¯N€s5ŞQi„œe®ëÓsÎø	œ­ËÎ‰‚ùóùjèf§'ä)nCvü¯:ÏY|¯@ÚĞÔç·†7b¬²ëïG„]_"È21Z)Àrµ´h
æã`ô4bg@µ-—Æ!uA6-kÖúgìÃlT¹Wæ@·	­,ó­£ºHMFÌÂëÿ½*®µgÔZå‚yCŠ…§ˆ=ºZnÛV˜:Ú;£ÅPNPd/ñºÆ{aÅš°õö÷ì=›;/¯Ò“„‰ü#›(®¯¦–hF¥P|%õ˜¢7uSE1Øá4Í7©
È(¬ìRìÀh»ï7´-‹¾0¿ÄšÌŒW•äIõ:Â'UôÒ?Ôõ;sú+y%06F¸ó˜İº´uÑÙ6}®dE|Wƒ=€í¬ß+|^![¹Òj¹â’½g—œSŒòÚ)45)ŒLJNĞí$™½é¡«¾N=ÉÏíeææXê–ÿpœ!»s54Ÿ'¹Ë#0ÂÈ¥|ÇÂq zY‹@t^#±{©ĞmÖhj‹¼‹j¢˜“FZ-6ä¾§‰)m±Ïoœñ!ø'…xúE:¶3=õ6æ£Òõ[]JH¨CÛ½¬£7äÓºÚ¤.IF´i¢Ç‡–i®ªziŠFB³FS¢{}å³éª–…9³ÊòbR!4!®wmÎQ'ƒ`%˜f]ã…Õ.€Ÿif9Yí{rë·xü¶eS Éãà&²Àæ|]Èı‡95ğh¯¤ù¿y­MíÖóùé¤›X†Cwä!´F¼(¤¯‰ÇùÚrh)—!¤‘šo»%81ÍKúÿLêÒá3/m °5ØşG¶<I³<‹¾¸¹UûV¦ñÉtS.ÄÚí8ÏT`22óŒog+Mİ=>Îçæìurˆö°d±0Íc‡sõÿòµƒàşBZ«Æê‡ó×T0Hí`õ$EÎÕ2›SĞ¦GT½ºE5U ¤)k§×gXª)D*›oµ¸[O ¢	Éß²¼}ĞfıdLX¤MLläié÷uˆSÏ••%Ã8;²ƒ}lP
w,÷GëÍO³ÀBy]OL6R]‘";x¶A–˜ğh1L	oİìà_®ğÔjˆ
Œ…oÀäæûHOÍk˜zUÉgP/ƒ¡CÁ	1ç]-®ü§Mú³ÃÕôi¶SP™×rs:›¦BÓ¢[bô›Ì¬©ü•ğéÙÅ®_¦KtÍáE?İ†ÛäÙ6o6
šÒ9ÒŞê_5À‘ORüâÛ·ó›÷’jØÈÏ>\œä%4ô4VöÊáG³	?ş6Š<ı’p4 O¨lÆ	w¾—uÅë‡~œ±âåÉÊ Á±ÄkHk Š3ZÎÑ(+4é.ñaiÊv+gë^gåæš“ñ­“¤¨¡M!Õ×é”9ª®ù^XLUısãŸ±–R¨Ú€º{B6ÑÑ-Š_…Û5}—nŠü•'ØJ-šŠ=îæ#ÆÉ]|ŞÕ°ÔŸ‹:D_ßÓXm†Z·ƒˆÍ –¹Ïm¨o…`} M©q4üv Ò×l»íJœpŠøèjĞwÕ‰8Á‰djdF+–êCCT03qéc¿«…uÊåWTŒáÏ±€™ü¿ı‚Y£ù{á>ìIdWV¶À	¥©Ùş7Àâ?bö"¥SëmŠWgàƒÉªI«´ñÑnÎ5¼Ì¯Ú;_ñtËÁı²æHróDšEN£9È‰‹šêGÜW?ˆ‚ªÇ(9ál…õôĞ ·´ö4q¼Q2tE¯¬²|´L+¸*RUô«SV¶5ŸÀWà}ÖüˆûO™9º¦º ›•…°%Ÿâv"SÑŠ%¡Hç7»|~¢D2ÒÄøtpHÏü!,êÃ*ã·åˆ¨ÄÕÀŠÃLÏ9$9—    K–¢åœ¡d öµ€Àµ—®Ô±Ägû    YZ