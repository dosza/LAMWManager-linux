#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3750117793"
MD5="cf2d9d37d381182ab901c49d09e55de8"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20812"
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
	echo Date of packaging: Mon Nov 23 02:31:05 -03 2020
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿQ] ¼}•À1Dd]‡Á›PætİAÕ‡8[KşS¿53N¹,ºš{ÄÔ=ö1-4BCÖ(ùii¥lÜş
e‰JÜE°u;jŒAhÄ„ôÂå=%éíÄã~Ûã€‹z“(² äğï²fæ—¬ò•ìÀc¯JÍR½ó%¼”‘rÙÆ}¥ñ’¼Æ
İÊ¡øí‘‰ß,Ö#ôuˆSŞ¹,Ôœl¾LÂ@,5¯qşI×ó§l\Pµƒ;ò3›a¡H€—½7ş?F­œ<Ét¯˜r¥Ô²:öø»„rdí¢*’
$5(0db°_S°Æzåªí‰ëKzZéöeŠ9?K®dÁšüzĞì6_a"¾GAiî™1/÷?1Ã3_Ê§GçGt>%ğ@Á42‡cGãâ*í³m.c‹ÉÏOb‡à¤îAfµÁWíøëI¤„†ßUäÔ$GÁd¶hÉ)¦=
ú® }Ä$Ìõà"Çi·jp0\|~ìì‹Ç©$&6ê_éŸÚªˆ¾¢¿¦ÕCóG|Ÿ˜¼aê±–’™ıu?åİ1~º$f=3æ\.0Ï‰{îÕŒw‹exô›Ş¸ÔÒ¹A‹2à0JöŒÀíÏ:ïìô·®Y—6=¾]9;I:šÏÔõ%¨® üon¬b:Tóu¿ÍU‹ç‡}"\ÎPiš½¹ŸÔY9¦Eûf­>ëµá@Š WİztEˆ1ä%{µnäúÿ®ûŸXqkVUê‰Òª°óÍšıq_¸—ìDâcófâ^—Ğe7›é^ßL‘W'c‹%ÅƒÈZŸìÒü
ƒ±H+šMÍGkoÔ7&¾‹Á3ä‚_oÖ\ƒn;ÔØŒªWK:i³nşë‰Œ«©à¶ åùòAyA‘‰Eí™~ıc­ëngãIÛí|‚v5çôqJ¡y’Ú>==èï¾viåš¹"Ëçîş[_¤¯İ(³k¯c¦b@ï“¬›¿:
ı™É÷qBš Áè,ç#4!º5t‰‹²¤Ö‡”0„K2º}ÒQæØbP)
ã Z~à9Z†”Î	âwcLK:
°‚Å›è×S­İÅø…îõ¾jê@ğ§Äÿ¶ô5‹ñ^Z¡½§
îÑæŠv‰>„ÜWí+33¶¾/#ÎYe½,‚2¬Hîöâ…åz¿´–‘·“}İ¹[ñpR¯Š{yôçÚ‰€
KFáeU©â)·9$‡ş5“'3£¬j)‡Fè²YvùNo‚ú¢¦¡¦Gkc…ŠºDëSh¶ÆóòûÚaÕĞşğXv ³½–0_ M¯(=µ¾LiıÃLm‡5v™¯æIøâkárŠåÄĞS^š`RTê4Ÿx'ıßÔŒg¬?Å&ÅŞâÊõºÙÏX¦ş4Ó
k'-"Ô'V°}YÄì¾ÍB¨VÒj‰ )•+nÏUâuF©ª #ò&™–'ÁÆT‡N—¦ ƒÈM¥j¶Ê<z3 Cï½<Êì¤§Nİrµ/4ÈÑ”õKŸøĞÑ
ÀŸ«É²ƒ¿?%Ùš¿¡”€ğ´^óºŸğÿ+ŸˆËWıGÒ¸Œ‘ßÍÇÜ #•]¦l`+"ş¹\YËÖÊïŞóÇå’¹!ô‡¶œ2i k±RDí&œâÀò7ÎÄv™•Ê“©j~KérÀ0©È“4í£_™v¹?hÛÎ\5kº÷‹`j&Ùi¢:£Ğö<CÿI‡fôó:PÛ¸ó—Û±ÁOvÕ±·O¶'OÑ?7ad`ÏO±ã,©0T7X+ :¶=Õ’ÿ[=(ü1h×0rƒÀ^ñ,$æolhÄÔññ¢¡.!8<h,^ıJ“g-»ˆ­,˜Ç½X"†ØiÆÁ†Üã%,âÄ]|QöQ¯‘Éy}wDµ_üQø¼)XÙZópÑbùê¬ŒÁN'!“+m¢…Ù'áF«RˆàF)	;‡ÌZ XSÙs+†5O—6ZSÖû[”¹:7É®){;á: \¿ĞïÇj“?T'†Á¹~Ñ¨ˆuÌ	 úŸ&'ú‹¶2 :†|í;Tk²Cm›lÏïå¤T8ôôD·M7r¸¡îÎÔMê»O‰5o[ÁP„uÌ´\D\úï²”—/?‚<™ØÜ›âsb0.,5,ÀŞ·ób^À¯_<%ıÔ]®\><6Pjél.ò±â ‚ËDÀÀØáu4FR¸‚TJÂÿ©pOøì4ú†
sìp¡èP®j&—¤œ|ïCxˆt¬Qo¨În…¦›– œœºKD3áYHµvÎ‘áW\¸Â¢Ñ·DOD}ïµ?lÉßeß ‹TKSE¬RhM	I“+¸:QB@ ›S°Ï»‘ªê­Îv¾D%PÚ…XŠ£HEÔe¿¬ŒLz:dL©aâ+±±4ùÔ¹ŞÄ§Ã05ëŸB¯Î<Ã¦-ˆ fÕM£_„_A-f3õtë*9Ÿ 'é¡~Gní'…ĞŒÌuØ
6}qGÔõHòlaRt;Ó–ËËn.v—Z¹Æ.\¹×<Ç3vLR±ü:>h½RÛŸù)µÀ3|bíf2†•oñC`)‘æâ¨œØ„:‚åZ™…fDnÔµoŞf¯Ñ/9FğÃ„Ç9v'÷Œí`AØHÖÁ.Õ”ªwJme‹m*ÆÜ‡‰tÜøÉ<²{•5´nÒ"=,½åO÷‚¢ôFBîq$½4DdU¡óÈªè»{©ë%Î•9ışŸÛzqkEÙ¤œ*²°U@ˆ$X½Üæ\‚Q4®Ó9rGTHkÃ‘!·vb¿óX½,[ª–&o4I•¤lÄõ†náâüº†ZYÂÚM9çhâ€>
CJ…¹¦zM2yñ/=Şh’!â¦ÂZnÌdxC|Ùh’MøÒİ4:_ªÌÀfP¦C½—4uØgÿp´’¨zƒ$|ñsMíóQ#t1şJoŒLŠiÔ À¿@ĞÉ«”¶°İ)PïZY¸{ş¥òt0×b 9eytL€r>Ó!KÂÔ¤f_ÆéÉ)} ğj*˜¾!Ê)GØVöwAoãŠBm¾gÒ±5Ç6¶±«kA\E2v5³jwUÙØÌí$p·°µµvm	_C#øS\5òmó™BÒ5c8€»ş’Â:¬"XTmKÂC÷RB?T“ bñ_üº.¥ñO„Ÿ]²yŸ›sÅ4‡ìŞpJ'–+ÒÚ\j2QÛûŠ=¹¿‡
m$ñ{vÈçŒâa»‡“Ùúš7sØò[Äğ*ÿ"q·#’éÁ)O¹š:ñC?¼N“Dbš(ê
U-„c¨×Gé?Në× CUõ¸È9Û³;OûÈ‡ÕdIaa.[Ş[†…’híÕˆ¬>¦Mü0#Vtÿ×Æ† 8€Ó4Qy~)d	K4¢J[96j,C××f6‡’—{Ú}}Û"k?MÌº½kDŸ4Ê¥AÕvÎKT•rô Ú%´½üŸëŒƒ£ãÙã±W ¡şè‡oEc&‹ßIĞ‰ôz"zç‚8õU@¤eIÒ²HKGr;G4.è’›Ò@ì÷ qI¢«PJÈ‘÷~ş‡kšËŞ¢èyÄn¦JÑ“ˆ±ü¾ÍFÎ°Ò+ÿ+q€wz
#`T*òáĞ72¨pÕol“ŒÈ¯y9(n¦rP±-îUk”¨hû–Èg°^Ï,ƒ<ïÎ×Ú~æ@Cb~é]òa$WFëÙ®ÌØÏÌ=¦¥Ès_).‚¹F½{Wµx(»ß÷mÛ—WïOö”ŞŒ¾Zµ¯{Å‰Ó‚j®EyÖ/°„^Ÿ7oC,¶øé¨Íéz‰©é6_ˆİ‰¾‘²ÛOQ „{LÉ½xÊîøRm›Öà3Uâ,'•åÀËè!.¶™Qü'EAÄM®µÛ"ß_Ú÷ñõÔº8ÆL)ÇjU#©ü¹¢êJ¬„7<G aØö uŠ¯Ã±¨U¬×Ÿ0×K²¤óô,ƒ£t¨Ÿ¢o‚Yi-ğ>èwy¨ğ£^>™FÅ~HÅ‡*‰£ŞæÂéU¿n$Äë´­%†K‚Õ
äÈcA=
ˆ>é”88ŸÙmá|Ôl¬_«ä¯˜²))ZµQÆŞBâeP,À¤Á;	”¶ÉñW·7óƒ7¶Íèk¿Í}¶¹%lXç¼Q³Án¬@ïbÕEg ^¾"1j?,µC:3SÑ”üãš}ƒù5Ë€bº7ÉƒyYà§ b˜Ë£¿ËÍÙ‹²sÍnc®¡–ÌK¼½Íì¾W&GC${ëÕàÌûh‰@ê;½#İpÉ_›ÂXoâ>éŞ»8·+àÕö¤€ùéã[Çğ´Wx<0›#²tWoàC‹àµO  «*2‡§ Û‹Jã›ÎÔlàñA¤»Ú&}¡Gïî·Ñzp¡şı’¼4\ ¾±©(&~=oäš ÇIW'½äÅ•ùŠßj1K;ÖdèQÊ Á„¤<7ûœ0·ş¢qX‚œAôÅ	– }ÙRGaCˆ•œØÜğ¿…ÍÂìÂµ¼Nt…ğZ“¹àãóÍ®q‘¥BºàëxÃ¨Z'r/Nÿ· ş„¿d4àz²J[Bc„N™?®ø®‚òB×ƒ¿$
´XªB½×C:ÅxHPÇ^^
‡,­È Våç¶ŞÓ?QËPuôüZ5*4*òrs¢~#B×4ŸF5ç!]$ôÈNşJ4f²z<o$®qò?o‡SÛßˆ1{f›} ™Ÿ­YĞıŠóYƒÌpÌ'İ˜Õ¸à9Él}V­êò;}CC?„»0z#†¯×£¬3ï3;{œCœ÷pV¿°ò‰¶€*BÒ?°ónr{k ZpsJ‹=jüÒ×uÎrt÷î™ûÛL±`¾ú277«k°-ã¹¼¿­±¼5^9§ì¶jæ·ñ…MeE×P?pn˜0ßxX0¾¦LÃº@­+@yï£ùÂj+½¢°Rx¹b < $îyô	ğ+]Ã`5kËõË«DÆ8›]ªŞG¹÷Z¸(Ú¬ÈÆ2¢dø£öT".S0±ıre@êóEi—Ê‡k\(¸UY¥ÊÕì»=7Ù#Kb¥qœœÉ)-á75A]A”8¿,JJsiëÒ£Åaáğ
E¦z«+İÑ#Gâ´¨Z"lºjÊF¸|}d„[>YE ßFŒítLÒ˜ ·ŸU8¶bP=ª•¥­ˆ8¿Ï®¦ºk´àA>-Qb®•æäÜ8şyÀ¿Ç)F1h~Ë¤à¼T’‹ùÏ¥ÒûOÑ³ıàèJè,¸ü Z¸á…ı•ğ¦/nê –¿gıº›,ıÿà3µšPü šU‰µY<¬IN~ó:…jù0^™WÄ›L°)şµë¨t¸ÿ)îòı«Byyìb}Ğ½çş9Œv†ĞhÚ+Lšˆ^&‹et¹lgAùÖ'š«pnò‡Ã?ş`Æ(«ÅÛ|]I¯É{í9¦€=K şYûFôÖ­»nÕŸ,©°IĞ–~şàÈ4sÔ3ŞìŸŞ ìàôõ9ƒ^õŒX¯‘ú{\¨EÇ ªã†æ9•b‘‰B6ò#Ğæzlİ–i^Všf£N°.3¾¾ÌË¨_E#Qşì…v>%ÒD²îå2:äm{¼yqaJ"ÈqNpnz!GR7Ï
ş­&LıÓwâv|ßÖGSFPAèìstCø”+3ï‰IDË³A4x\ìêÔûÔ$:èè½~t¹Q!‚µ˜ƒFÌ':fóı:UÆfíÓöåÂF‘#ix¥‘¼„Ş„nFœÛaYı‰TzŒAÈCw£¹íâ%zPÂ¼cÜZ±ÿ™4ï¯s,X•HÇŠZT¤³h-IİÚ|g Õ-O û^€Oá©]§6Ì$émux„Åp([51Rpáú›ğaÉw—o=N÷ı~X«wÏ¹a M„=ÚÜáŞXBÈj¿Ï†' Áe‰÷¯ïÇZ×*ğÅ{ÆÙñjNaê	äğ/ÁíŞ‘ëŠ‚÷{vÂ™ÔOñìWÿ¬8Íó1¨ßÎëàöì zLs‹ˆ¦4d€Æf ùâë/~+ç…i¹Ü±Ö_Ó®uÆî5ZşP#ãuMEeÛ}€‚*e˜³ãSËI\mÊÀp<kY0†)€àâ˜ËtÑâvP,Dï3•X¸LsqÅ…jQh$Ñê¯ÒäE®‹¥G©¡ío»DJöÔ
ÓWÌc â\¢À:£±=Ô$³&ÏåÖu‰5¸FNÿ¨ı6â²´›ÛH¨‚ï¥5¸oJA½(v@2ûÈRÌxH§Ng Â!â;ı´\Ö ÓòFVÅñ­@ÔAAåª¿¬T§ÍÆ9ë5à2IHß˜¨òûº¡¢½qú{\Ì«{RO8TV\í¤‰§ß»ØSHOï¶6Ø^p=éäô/võ ¯ı%­g;¬æ-JAÒÉ5ÙÎ.vVˆû›—.Ú
ùÂC¶xˆİp§[’E£±åg€’ª·¾éÇ§€·Í¥Khøä>’eª¯âUNµŸ†Õ ,{Ê7À7©ÌázÛñy,~ä(K1sV€´C˜u“P“ÙÒ™nı~Ğêo-%¿ñw|`XJ³°}{}­Ò†½µwŞméÚ5¸ı‰QA¬Eµ^¦Í®jR¥h;íÈ<R;5{È.wZ0P†%&½¡Ü Ñ9J	Œ›7œ[m|:·š¸§b¿°a×–üNŞßù–Ò4ò¸•Êíü‹ÊtÂBÁ+Şr4+áõíéÎx{ƒ‚À6­y:ÜcÀ•’4IÑÈ²T™ü5@Š[œœ##İÄûõ=µ–ÄA|¶.t8şlíy% Ë:¹°—oÙY#9¾°Ğ¾g+¬·¨z]çÓô;0ZôkºåEÎ¤m
pVbˆêHà&MÃ‚ÄÊk'ÎÌìª÷Rùë˜DÚŸ…Ì\[l6ÃV ¢)¬©å–/8´ltèŠô?êÓ™ozDNaY“ÕLï3m•%&ıáËn€!mZ:1¢&t3Á€ñÆd¶PoıêÁŞ-lËª;ğ‰È±=õeh/P—øáš·f1~°z]£¶Y¡n0+l”`ºbÿk>ÎIvgİš'kB“ÕC&ŸCİßÊ¡‘S}Æ(Á_‰8p†©÷ïTsŞº©Âñ~}Š¶0K;4Ï»’½+İ+±‹1Qœ Û4FÓ°_J‘aU©5Út5(¦{áÙu8Ÿ¼~F”ádÌv1î
å¦NK†ÍïcØëptZÈ‘
z	 ÒD}.üäIŸE¼Î›°ŠÇ ŸÑÊ2ù¢3½4ÿ;, 8G–â ]@¶­d†ÿ:Mä¨îúÖ%¡ĞÆR^?¾²º½×S—3®@$i8ÀfŞ¨ìá£[XJ†÷>ÎÕ½DpÃäÈ$àNuş>2ü“×¼à»G[ÇÂé¬·0÷‹WÊîåÇ™Â2)PúJ/5‰¸p0ìôFu¯<™]pÒ€Y‡Á¯,lú~ÆüÛœÔf¶g½vûp9¿º„CÖ°„ş®…ÅT3®L»VøçÒTh³Î¡T8o3
¿yåÏ«ùemoDv»©noÛ¯¬)ç÷ŞŠgıªĞâIMê-îûc}†©õ© ÓaØÅPïäwD)±m-*öß´‚ÀéÉ	t¥Yq»¹rÚ…Œ"„PÎÛ±ùÉú^aıì?}©
×Ç k#’ÍÇ)~Üò$3ŞJ³ç@Á¼™ıÌ_<ªCj0N´·›Š«×8 ™ıó *í 6—(Ô$sœ=ÏÉIõGâl.x.>0º]ª\ÆAìRê]‰ñíĞçÑ²¬ö¨$.P+c°:¿S]ô)ŒØ×òªœ¡»C÷£vÑ‡sÊmë‡Î¡`æ¬dW”áƒõ](TxŸ£ãvFÏ’è1qš®+h0ôé©ÑÔº½ cZsIEâ‘)ß©äÁ‚ÈiJÙ9A¯{Ûoù÷ÌÏ­S%Yd6ò£¿³>Ùür:LzéL§ú\8äÑN?Hã[m®óÌ<7Ì|_¢èœ¯¿ˆ¡9>)°šhŸn]äóÌµmò‹êt`Fz›¶íõô‰ÁLô×ÔÕ5ˆìÜK:¦ëŸİ&ií~¯˜­suYDéNO FÜ÷Ï—1³,Ãzáù«@2Ôv%S§ aŠ$ı‘îëN<¶O¥&ár°‹pp‰ˆ#yçzDĞHECW“"ÙÓªîrÁõfA¾qò2…œ*½¬òšßr öANm‰Ş$šñeÃD=Ó>*Ôxt!|_Oş`;FQXŞ÷N1{· ú÷¿«7ÕßÆD‡ø£@ {¾ƒßJ{/nR´Ô‡FU××$±³£î}«š"&Ä{<ğˆÃ²|û`2wùh¯w‡šä…Şß“tüg"ãÉÏüGêƒ‚yxñ½ÜŞƒ»¤îÓ#ë]‹ò?PŠ×´B¤¦ñl,nx–GiÁØ)B®-‡}ÔôlàcŠb€àãÕ,¤!Ï¥Œ„I¢ãUµ /¨9Ö8öL‚«¼$!Ï³(=yâƒÜ½°7ízRª´‰B‚3ÕYJNíä.lø™Qê–Õ’9;},ìlÁmÈÀğ×òÌK¢Å ¥<¿zt1:ŸèO?ºâ]n=Ä=ôÃŠÂÎ˜o§ò,ÖáÕ¤ƒ\©bÙk¨Sº ¦QKeRiêÄCa˜k\3Ÿñ°(,T«½Jsg¨úË	Ïñ!zI€òJ¬Ñî+”õxğŠ NfÂ<~@ÚZ¤äuœŸs
	•KZøÜ|İ²J;ÕÎn·= ×azPåW¸æ‰$G$…Ñ¿¯Æà>0M	šíË²ÆE¨±ù]0á>áSBí«jA)Nã3øcŸ 5`Œ»ğ1QŠuÂYUÊPTó%Ë‘c]òlm2jµÖ/¬A4N™­Ì¦6ê9ô®Q¹xZ81×,\ù®dE¥tŠ§)=
Û
3Ÿ­sº;>„5k]LñÈêì8ó[Mrtø˜AG æªUßêZ×÷±Y½û¥+Bxş ’i#„­TX÷ÂîN0WÚÊ¡=ËúK}ô§s6S…­ïF€ğÌ8Şßô»¶WåZş]Sà¦Å1ˆXZçÀêë’|jóa„óEuç­­ÓBäÑñQµ7ø	Töİ—é¥C¼µ_,‡f¯¥â„ZW¬qòÙûæ^©ô¥8Qy·š6brsaŞ³­5)’Çzë'ê4á®láÑÕ.rşCaDïp²ÊŸ@aS¾^¾}õN?Eä¾´/Ñ|Akí“J„³'HĞ!.Âæİè‘6§îÑÏŠ~Ä˜¤Y°c*ÜR®9V\Ï›Nî8›L83wJ~LÏä=`gşP,Søo^ğçâİ_¸kjÀo"ş0R3”»ê¾Ôƒ ¹¢–|ZÊñõ´MA6R(ÃWş- ®·ªu†œ³f£ûœ­G4Ë±(Ğm6àğ Şd—Ü
@adŠèa˜asn¡pş5ŸÓNšƒÌ¯ô-×æƒd­~4?²c*›ÜY_”YKP;|U"‹t˜möf)Ú+RzWİÍ*ãˆsıÀn¶èm˜éyı
ÍƒúˆÆ¡©ñl("ÉÈkMÉÖ*'/º##“¼×Ûš/e»dØI	/E}»}vù¤µÔBnQÊ°ïU¹2R®¾I¾¼¤˜ç.s'²T9Ë4Rb«IÀZQ5Á‰Ìµëãr©¿D/§Ü3ªì~úgªt|„ˆ-Q[_–Ô¸Xª).G–ôaC«Èi¾İî¿¬ß`ª‡XŠ9üê$ÜÊÁÿ;	œM’T—ÅĞ-Z+©únAãÌ	Ï‹/Rıê›ŠÑª‘ãwlqŠoqMŠß¥·=€Y¯l˜ÑbO°›îØÜxl¤t¨òdwÉF5HĞßêhô’zò!aƒ#xB—¸Ï%Å²íûSíP,	 qÊF2’ÔüHš4"L/$8&+&!f_åJ¶!ä[şş?R¨–P~D{1„ÚXd(¬¸ŠJÂ„RÈ»ãÔã	À©,ôM¸zOŸdöè®jMõ;Â²¬gÖRTË— ô×+zşÆÕw•°Ó“Ä1‰k`_´ğ²Õä£º‡Â Ä‘†•Á¹+’p¸ù0fÁTú8U.©%Ö™vÉ¦è.n¿Èù¡ïÈ¥wmÆDóhÛn‹	„yåÃñÔAU×ëÚw‚˜¸¨ƒÏ?ÖÅ‰*Tè²ıë	àÁÀå)F°ôÒÊ`5CU úWäZèá‰!ú/*C*“<š¤{ˆ<™÷ÇÀoÄ@Xv8G`“ír“Q^òd@9S¢óâZL‚?-{•r‹ÁHPÑõD×8b«z©(™"sÛâjH‰Ì
İ—q†"Ø§±¬ÜhíÁ"uïÉÃ—nKG£Œ½„	¸¼Ìâ¹T²w-ÕŞP}›¿İãØ ìE~®b±ÏS–°š{_s¡ØÅçŸX%iÙXÀáù4@¨±ı}Ï_Eü&|‰¤ø:íÇY«±Š¦ŸB|oœO‡±ßü‘4Bo¨Xõduê‚§¯œ¨È~+±+¹:wÑé4ÀÖ‚OJˆ5[òĞc²ªm|£]}ÒOQ™á³(W‚ ä1¹VüfÊ`BNXIİWÇî(;ä`(îf(ŞÈ–ÈÆ³R[\ËzK¢]‹ÉDô´#v‰½ÑEï¹ CBúÕu«Ô=¤ûª^ñÀSlí¤P´€Ú^ ‰ù¼íLµ¨ÖwfëÄgšËÕ#É2y€ƒŒÓ£Â‡Ã§oÄv…ce6`Š¨qÿ8-PI©±>Flûj-m±îLÊ[™1~› `ùÃŞB'ÍŠ-ßpi„´?==fkÛš¹°ÔòVïÁ¾›GÇÕø0ìZÛ49Jì.p[FT‹¡;Vb’Ö…ñ2…ıœ(×INl¶(ÇÈõ<bö6oÑšµd¶¤ù´Ï@ÉL§mÀL*Eæıƒ„{lSQ­×Á4+¸§É9RU«ˆEN®’mèV~ÒH3úJÑY*€ÆgÚfÎ¶=Lnö:ıŞõq¦Õ†³“o>{ƒèË±æüô—£5p{I»á¤š5k´_7fX„ã³m^ô¹Xæ$™i<òül€«IÄîSA€uHÂJ±KÉÂŞúzÍQGßSÃ=§}u/ä6©†B÷ĞfèÔZñ*éŠÛ”6¼ùGKóh®P:„ vz‹u µ*òçu¹Æ»ş“F¢ŒÕFQÎµ0·]ÎJJ
m°o•L‰„/"D»ş}èáÜ{éøTŒ´ÿ‰òË¿¹bÑ,€6mSlˆ˜û•}¸jOœaI‹.,sû8ß°¦µçj«¥HSÇéUxgT‰A_†
?}ÅÇšLìxlWkÈÿÎÂ{ú:CC§êèdÿ‹Å.Ìnå!ÀlÂZêğĞÆ&Ò©Ø…ğäH~ä¯v$ŠÊÒws•.ÊÆƒHyÉÖZ=Œ³dÒOÂó’œŞı}¾gƒËš
k2[~2Z|÷üã¬6;Â˜™#Æë·²iíût¹™Û 	úä«Ç^ÿR‹©È@{JÙ(¢uŞL>AÉg+^Of=h…,ïn‚‚§¶“®é_JMæLXO+*è¤o˜==dâÿêÕ ¿çlì8#ãşËP·5¸y.+Æ8å­x¥qT!5qâÑR{M®N|Ç¦Ø®ˆ¡Ã M½T‰!¢6ä€0îúºí…+--ºï·¹ î&K—‚å,„¿"´4‹³JKDÊıâg¸Gs‡É„$ıŠéüá+÷å^éÒW`Äíz±ió—`•K»&³‚­¶ÁÖ;”±{*"G£ä|ñLÑ¼Iäfb2Üë¢üæ…É>o ÄÕğ	a5uuâµ„¸Z>êŞà WÚ^/Ü˜?ç÷}+ğ+ğRp{á©Ä[Zt}gcÀÌÊ\{qÁøÚ}Î¥Ã6(”&Ò™ò„íyš'’vA‹RÍê©rÒß”=2e}C“,œÛ’œ½bÔ#ÙˆàĞØÄ™3¹­Î=*öş‹úKâdÄE…‘)Ú¨Í£1ÔG¢hÙôûÔº,ßNhÆípQé)`G><kbmoo?IøYv–üDÿÌ¡kU·/»În‚å6~§—o=sT ×‰khA}šüâ‡0pÓ- 3ÉvdØ>–RÇşayXö¢nì¾Bà*oØ·HÄ‘û‚e{õ-êï½0·şÖM«'n3yühÓ:1O³à›M³4j•D/O€ié §ïVÂéË÷í€ÅNlì¿İ©Q#;û°s
VFSC*X˜-G]	ÛõŠ¬rˆÖbû#Q=	€ŞŒVİ{A‹Èâ"ÿáL/bSE>‡"-†Îap</á`n0ùá	£—‚´<¥U¢	“í{¬iV×uêÂäömŸ—	:ùŒ·'Ï<¬h_’”IY˜CœÇ'SB4¼io	l]Ü0cE~±Vâ½í ]	™éÒa‚Èùaw3®‰zÅ&×n]ÃÏo]P•Qwéù]¶ô'ÑŠígØ7Ç“³Å[ÑÊ%XLF°Ëœ'Y$Ëe«fÇæ>,Eâa“y¦ö·2¤	ã÷¥2ª£áó]ƒ… „éˆ”îˆÿ‹†Ñêp¢“­²»¢7…xoşğœ¿í3é›´\"
ïi‰¬Z9.¤¢ WİtcfŒ`½w†ÑÈV™“TÃÿåäıq™ÈòzY€.0ÙüG(×â>Ğtbn¹ç^%ODo,k°ÑèÏÛŞ÷ªÍ[óY¯&ìß»ÿ˜˜ô@§…tªvúâ†êÙ4&t½K£:¯šû":óB—»
ø™Ù´Ê`FfM­a1‘p> »tã4¿ABƒ•5û™&Š_•¤dá¨”e¥£ØZ\Ù;‘İš:~@ÀS©Re/ ´/îK–zü¬Ôe~%¡´±¸”t{ülUİˆ9a»šx\rkkù`ÙT÷¤Ë{ÛÍhZcQØÿ	Õ’@Â«ù:§2¿1·{1ıæêâRª/ÛmL#7ÎÈ›¯‰L$öZ´Péû1—‡tÆœK
+@LÒû§L!,×_É‡KOÃø2§Û¼Ì€¢Uåî	şÓ†´ËÛÏŸÙâ¥dÈÉ4›–Ìœ¡¶›l=gÀ·É±õ×ƒÀSĞ2òî¶µŸşa&.¹ø[Ğ!¼‹W7Àb÷.x3®-læÚpx(X÷B5ò&A¨Õ:QÀ—¡±BxµØ¬’#wågÕ‚´¡ó°<*.?ùCÊÎŞ Ò¼$(a¿i¬NgÈæH³Ó’Q†:³Æ²¯N‹¸‡£•Q÷2VÙ‚*|Ii|‚¨&/.7c}Ã–V‹6@Ê¸•djmŠ,âh @Ãähn%‰ğÂrl,¦ç^“ÅÆ»ûÔzc5zëÜÏ¾Á{øsÙp¹£e¾f*§É)Ìú¨h©,Q}l;æÔ’fjp•!–	ŸO[¥xM^§6Z¼ëp<Â–æ6ËVšjçB=[9"ßh)v„bW¯“¡
4ß’¡ˆ!Ô–BŞt=³ßSsô¬×xß ëø2’É~ìö*$™ÊÏöJ|æà9¦?aHƒÁï/Ì‰E‚‰mrá¨´•R‰{DsIé ~ó®ıöÌıİKW*l+¡`ïÕG¶6•åÍŞÃ”ÿ}	Î_~Õ(N›%Õ¯à¡ÃÕP6]<1D2LÈ²Õ¶¨Ú¹Ôx®¨*²U"@hŒ»’Åo0úòäÅÚŸ ´ù–!ş±™2¦4bÜ–˜_l!•Ò‹„×æËDC<JvwC i5ó8ó¸a©Šãú_Â~-³”’V?¢åO6Òœ; ãĞÄu¾™¢Õÿ6Ë„#Ã¤^º&’Ä¹o /F> ®	/"NkÛDUåe;~—ä	…h¦V4x=”Ñ¼£É´§¢®í(ªMÆ¹@ö~Ã|ğƒ˜{~4£‚z-¥ù•}{³«5–š™;6PyÎÃ.ˆ„cWÿìk,‡³Š¹‰ê–¦¼\û'LŠ|†bw:IfgSütİT%‰OÚ›Rrü%Ô§7BÆã7q¹Ú5kÎ²ûÉ™ÈĞ"ÜûÂÀU´ÆŸóhÂš5Dë¹š°(Ä¹ÇÒ3(™0)q ªß¬Âç)Š¾¸‚ïØ\a,<A\ƒŠ™a+âŞŸÿn‹Ê80AsAÂpÃ¹T±»\±Oúa»“ÍíBºQe '±âäW7¥Ä™Y–¶=‰ÓUıù {b)ñµ^KJ¶ÀŒÆK6 0ƒŸšËÁÅíì“òÍè\AÎ-f »µ|°K¾y.Ğ‹u^ŸÌ´ëªŞ•–©!Ï{µ%‡±¦lÈbP‹Ÿ?÷wòºÍüÇ;ÆìÇÏÉ´pÛ]¥‚Ö1$+¡ô­VÌÖ‘\€=%*¡·Šëê¢Ğ›¢ıöÍjosE°‡Öğ5¨³–~F‰*OİÂ€:õv– •Çêı—sãı`…³‚ñ'A,æó¶„F*ù#øz0í"„úÃÇ<İ%jjSS©å¡Z1#«×<O»[nP±÷.O//I­„ÇÈÉ…/|µcòÊŸÍ»ÏÁ×F,É!?aã×=ªòV°Àf`ôåÏÆ—a«•¥í”Å„ÀÅ§—ì@µÆ5Áè…åCş£(¤ÆW|İí ßô²´‹¶â•Í¶¦õN¨èFb¯¬Ù	êßó„–iOÿèŠ@G¸€#›ÍWå5	îôXhÕ¢‰ì¯É–ïÑY‹j°;°’ïJ‰ìsÊØi	S`9)•ë2cû}‰uáşCmaŠNÜªˆY.?é\iQN7Öâ‚k:ÏXn‚¼$)\Ö¿èÉÄwşZ‹òÆè2TñqÖ¿&4ËA}VZ2¤‰	já³„Ğ[¶[©†ó©‰*¢¥Úó’<°„rm·ÉâšNÕBú5‘6¸&fîÅMªfˆÎ÷¼G@œKúóº€áø[;KŞÓ¾P©’íhäá›\[4õ0l”Û"½rO
«s8qL†me ¬™^çİHîƒ’ï±iĞ™_
·[YMEeî}ı@qËñ±ÑH4pI;¨6_?Çñ‡†{l²i'ZJÏD;ÁÉ0É'¡t´)röâd	ÛByş…R@¢Å¹³”İøã·o%Ô^3îÈoÊ= Hê¯?Ùâp­¹‘Á†ù6HI'kßxIwR¤¬»“ª ]à™÷¥†$"K íÚ]¡DÒ€{ûİ~¡ü­<TÇKˆèL?U9^”I´’
_„Ÿß¡ëöx¸1…gİ(´^	pxÓŠ×¨—^v"Ä®NIì9¸w”x!¿"a¦v ¼!	pâáÙû#¾ØlıTÇÂvËT/E_ièÄ	n»‚ AŞ3’BMb½­Ü°]àT[nØÂ9ãLƒ“6H ì ãşñ3C`Z©¡i}¿ß„Áú»Pnç4h¨4¿†1N<@ËHÚŸ©A99ÖÁˆyl³@#4Š	óŸ5ÉMkÁ8…y›ï…"Ú
ıò6ñ›«ÚQUÛ<Ÿ÷ùÊõJJT«v'bga'æQeÏ¨:l­n)ŞCyÎÑìa_oÎûä$:‚2kÖX;µ­˜…‡´›çOË¹G„Ğ<?—%Ûõıpè¿qO¸×ëbÊ†A*¸ñËcº×^;g˜·_Mš‰qS‡w†Fkzy«?R¼Ù Q—>J&_¾Ii?çÙ¼A×â´@Â?®¾'Şi³ïìÑZ~"ÅY&<GXŞ³E—a’‘B¿ÒÊ—A|*ş;5¬29f sğÈİ
‡4ªXxBÀüìã©üŞŸ	—ÎÖU{Äx¶{‘æb¯Ç Óüo’i?B*r¤ÈÿÙñ~<Ğˆ]bŞpQt¼¹UYåTêøP£²éäÃø}£7KÚä¹İ€öxd„E'fqHÓEÿt­ãy¿Ï_Ã!>ƒ—-ŠOù\¾±Ö(fŠ^Ufï÷½mæ»ÍÔub‚ÃñÓÿ/aÀÒR£Í…x¯R+û`&NAy.²4“®ãI®®©ŠÕöY«BÇ_œ•Í“Ùñİ!Ëê€Aı¦v"†7³üYg˜.ß»Z›w/üÕV!¸I¹*SÄüŞXétN€ÜuRof49 ÈØ«¿¬’ÓlOlÎAé4˜I–¹¸oïA´)<S|“s,$.“L?Ë¥K˜¾|ÒiæÍH§“Q9ŸÀÂá…2u¾&}*’‡¼|Tgó‹éÄK¬¶jæA ÆyƒH7g²ÿìÂ4Ô?W9f ĞhÆ7—Kc:PîÔé¶6»¸¶Ç‚Ğ9ââ]8>>ŒÖ%û˜º[Î×KûËßÊ±ƒ¼Ù¦-<M}%ÎŠ;8 ËÿTÆA2áœ£‚mQà‚ÆœäšNh£Hæd&"™µ±Û ù[p¶“õxYŞ¬i)Óó—Ka´äİuqUEË^~t¨º¦ƒƒSFê°ÿ'V¿QR›£`PƒSz½E®l¦ARÅø×³£©S)²pÜÆ?Vfş1©"®û{zogotÛ‰mÌ‚ÅÑkûX4=†)¹‹9Q[í["BıtSæÉk¥§W¯W7&Q¶³‚¦yÄ”U¨Ù»£qˆå!ƒÍ×Á^‹W©
5oşñÕ©mt¬¾¢8\š®§a³œìxyM`j Ô±¼);L²T­UvÂJXá=yvkÙÎsªoœ×§°PÊ"ãÔvÀÃ>ÿ»½¦c½äîÁM¾oË]ŠCË+î­†‘\ØGğ½#ñ$C]¶f\	ÁØFÀ‡ÙjÀ„ÅÛAyrÖ]Õ £ÜSØÇƒŒ)G?@?½ˆä„­*£oP›"nN5NL9ÔèI`bµZ“6Ë&ŞÕ\5Ÿ£ƒ»a©´à©á[ƒ>Ğñ ^lÑiŠE©Í[«5Ëè2<¶;'×³*G@cv¤?N¬ùzŠÒrQîğø×¡ÈXO¶€JM„vbõ…‡òM)mè;f:
ú¼Ÿà$ŸË±Vÿôû~1(`±3¼\*úm@BÈ‡ c{O5{r)xL4+Múè‰¹ĞŸ l5"{˜v‚İk\ËâÊsĞ?Y#—xx€¼&€ú­YÏC¯>1²4ü	¯à»Y»¦–ß%Õ‹Ñ«ş¾54¦¼¦)©°o^¢±™`èŠ¢÷d^=ÒLÒò0E+´yĞ’ÕÁMq–3š\?Laxk®CÄ’>C"Ç·ø>ˆĞ;ù‡X¹*ŠÒD¹“ˆd^îqÀ5´cú¢.×Èªm(P(a˜4{¦EtÛı†KFËºõ«İ"B.³±• v(Xˆ—æğHã0ğy(CÏŸ7ÇãXú¾öÁH¥=î‘^O#xª×Üı•ßûU4ß225hè§ÕÜY¾q§ßÂÇ4Ÿãºh\”vú*
k{ê¿‹1l–çh(Í}=¹G¨ ıL­fK–uö4Ãmónwæ)Ö÷Mˆ9ù
û>WÅ'—L–„gE
­4÷Ã	’ÅìğgË*õ¥m¥ÿ&k"ºëZ2¬ôO…âĞ]Áˆ©h€Zü`Cš‡c GPÈ‡“?íï³A~z«êßÁØ ICH$VG)ÄÑ×S+';Xø±FÚ†I5Ğ³y†¢“ó|Áõ0¡bâÎœœ‘š5ix‘çÊ^ßœÔß>•	*ë€Ï§ÿná,É¾fÊ:à±‰Xõ€úN4N6ááîıKæ…/ò¡5×N^d¿‹J’õªQu^>JXeÓk"JzQ5sõLå6
èCôªpî„e#³À£¢-÷˜=[^Nj£qãX*Ì¿‚U!ÎÇƒN¤¨ğİÈ8Ÿ‘¹Ô1ÖäÙ|B½¿Ú€ÒŠsºY´İÌôÛ;üànëj„x»Üà§	¼L6û†J¥ÎRËƒ¾w7J éŒgİ¡e–Øä¢Ô4¬Ü41ğ´Påz?=ilI·oÆ·BæÖ÷çw¥¦èPV®¿òjâ•¼.Zwês¢iå7ÓU¾Âuy¯°ë½ı^Cèó”¸êÙ¯uëqZ´ôÃ¹ï]l=~gxgÜ7¿Ú‹”Ñğ-¥¦Ê›âÙà7õƒÖÂvF˜@‹-3&”>@Êu’j$Tè£|ÿô^ÕbÄA+{ÓiÌ~Œø9
á¨M¾Ôƒ–oe+4bFÜR"KĞİİ·Wœ·fõàéN.¦ÿ4I@:±×2‡¥m¯À£‚/[GHµüo%ÇÿÂÉ6º'½˜Îµ‰@¦t0Å‘4f,˜CÍËn“õ^DÃÿ¥ÏJe'‹ÅÓ7’Xm ]$FêÂãkKp/‚~İ-V½'‹FİıŸ{½óKHOL¬»¯Š|=OÍ•/!»9"˜ç9şd?‚aö'=•ƒI¼B®XÖ2"×L]{#]W)ı»(ã)•¦ÕÕÕ?0éßé'›¥WOÁwsv6n¥ÕŒ†j»~²@QóñfbÈûÆrşã…›~Ò¹²Æ(×x»œ›Ât©ˆ¿Œ©aCãE`–¼@ü\$†"Ce‡"IoÚráè-ÀAk#!"»NQ_‰œIˆtMˆ’•1,!øLô˜:Èåy½x{×İ]g”¥Vg\3“îš»!ÀCe¦Û]ÂšÊ%‚3¾â\}o|ˆ¤…­ÜaGÛ¤c_¿m}0öƒ¯ôÚã\(bØ>*SĞvD‡ÉtŸ=õr”Ï,ƒş©º„G‰a[&á÷íù¼V‰¶ô—îşÖı]á­Yû<hÛJºYòË÷z–¿tÎ4õ`a¨™>ÆÄ[M<r~?=ùÑÛÌÉ}(œ:oå„·Ô2„épNN0WS«øŸxÃPqige)02ñ=&ƒ±İ›' ı^
^hLKY9;k?D÷v‹Í¯À; ü×÷§=è#¬œú ª+–¤¥{ÑE!Oîfn_B ¥›ÿT-‘#zA‹V.ŸÁ¥*óœÚßñ%a4úÏÕ“gÚdNæµG©g™ü¸C$vIËğg±?VâÕ#şR6‘k<îcy	PÕŞ?:œ<ß’Ç•¸É3XT…t¶/…5ÿªL´ßdåUE[ÇÊD~ÏÙ/Yîdhºcñ'îâm&—èTÉº¹J¼‹ü9m?¶åp‘óâhñÇUrB9ô‚lv¼J­*‘ùŠÀ j¶º²I‘ˆâ,(Ä`sÙM‘ØˆoÎá§‚s³ViNL‰aÅr©~b/OºËéª[İÉ ’}ımTV	/¹ƒùYsÎ•<Ò Ç%É†Èw¹”:3msiœ”3³äíebœû(Ï6Zr-+c ½şÓäLõw(áñÎK£E=;aF¸SC®½’J&ç'Û}¹bbVüÛAµÁì=V.àæÁV„Ô6g½vlÊ{§{J´„™_Ñš9I_7æRÇ¼¼rÏtÈd	AuòUE–"Ø£–ÚÄg¡C>°’V‘&ğâQÆäZW{ŸXãƒNÓ@àV,ˆßC<#º¶5vÉØÅ‚ÕÁ†Ç‰0¦5ßEùÁÑÁR‹,á«%¨;Å«Z.½ü¤¹)>¢¯9$€sdŸ^Fxî@P3\7×çıéÍ5n9¸Vâ¼Ô5ÛQ{×qÁ+Ã:oR!„v<qOÀü×ÿŸ·Á›ê£ÍËĞJBkÄ!½€]à†ìe4¢³,ºäy¢º#¯hÄ:Ğ¾êM/¯ÉEaî“"ıªß¤“]”Ë³€ø“RZ´[ñÕPìi9û–Lš_9?Åúõ¾¥‹s‹q4ò†û0h±tö²òôgi…!%á¨2ú 5šffpil’f
!ô1C®•ÙÄQÉÑPv%Şå´íÅrH1<P:ìD¼\ÙÛWCEr[õdïÁJµ*ü‚äO)	¿;¦EXYÖƒŠø~+ÂË©¥…à¼ßğlÑ‡´$Fµm1†X¹M 2ñŒşå÷#‰=á.>!ÅY‹{Ò¤¥kFƒ†')(€#ySŒµ‰çó>{W Æ˜ÊÜvcÆn‘¶’¦¶Ñ“vÁö:¤ş~®Mİ(÷İì®£èWèšêÜ„¸ ğUwi6ólß0øKş‚&!ï¢ÎíÇOê°İÆ:aü¿°¤#(Åùè¿Rñm”Ÿ	(cKbât®M,Ök!^ÍKÃÃ…†¾¹ö„`ªŠÈr„LôE÷{$<²ñ(%í§öóCL/h ¯˜ó {éè%ÅÎÏÇ˜3¦˜¢Ç2òüõ±+dŞiôœ1ˆ>pâ6Ş9›n;5Ê¤œN9£ó3MÄ5•ßtcUÑ0a	CÏTï²jºkáTói1ÔÓ:9êkµkıi+„Öi L¿ÿí¯.MÇŞ-’ìNuzK(ãn\ ×‘{sP¢„ÚÁ qg _Ä¶‘€"1ö+`g^obQéÒ„n§ôLcù’"Óµ8µMÀ_E0Hfåk„İšWâVTAb©±×Rä÷lÍè®¨KëjbWR¨„­”î­õU¿‹ôş*«èÏXÈUÉtıEu×xÆÓ+il<—ˆYï!PHz¼OqøNˆĞ‹×¼S¯ĞŸÁ Gº»µ%j^”øÏc†H “B şô2TY×÷„!‘ºì<Eío#¤K_ôğ8dº÷é-hPêÀË.à²yõ ‰Á]Ä†7r®úfz¢©³·7ØÉ*¦†¾_Œßˆ(`ZÀµi¿©b*øéa´¼|eâÇ¡	ŞbC««1N=ê£‰‘×¿3Ò?[ÒîªëJ~òæJ:Ë=|º9R²İ¨µÒYOÏâU¡±\Õè$3V={2è¬é|ylæü$R!¬¾],ãœ¿çL0)9Ó|°äz¾(ñÊ_éÌU	ôÁUÆœÍ?ş]"‹èöè¬\¢)Ó¸İ
-	f÷5Öq"õØZØrüœyÅ1^c7,¾óvŸ±+ğ¬Ør­·Îk'ps	œËkJÊAN@Vîm
ñ?ıÎÄ9$aÜPÍ²ön¢û›$†*[fãŸ¦gŒ›¥.¨øÑÆµŞúºq¸Ğ9¦9ïşµª¤ÇbR<±, ADØcÈÕ­Y-ÖX¤æñ'<îF½w‡Ëì{£sFÑ/àÜâ7{¾-¹Ø§ˆ7/×È‰T¤÷+àÎ4†,#ôÙŒSnĞ30@%Š*<a8ˆB7KsB‹#!pLX 6n\%ü‡ÚSHO‚Ûš˜ÒÿûĞCàº %TÌ q¢‚~Lèr¿+qÀ¨„³…Ü›0:„.|Ô& _Qiü†ë
ØhÀ»ÄìÑH²Ç˜B¼"äÖ,a€GÃsÇs=Í*„
#€‰B§^Êı¬2_…Ù÷69\$l|&™tÌüz@Ó5X Ãì¨–†oÍØÿÔâ·üÃÜşqQíáîÒ¬Şw§¼6vxòtÚt=^dÂÑbK<¼øƒ8Šs™T»p°á2:× ®ô‡è? ^$zåª·ºtúÂ?>_1…”÷ñ{?¾÷l)ßÜ²k/ï0”ú›]üùÊÛ"R¶êx™cO‹Ô04{ÂSúN7ŠKìÜ„G2Ó!o%@‚¢è%P•ì¹¤æ†0<¤µ/ÄÈHÂµ¡2LÚğŞBI˜˜à©áOæd	1²$·x`§ZgïJ$OSÊ;&l•şÀAÅù§ÍŒ@­A^&îQ|££µv9àÒš—O1ßYPÍNá×İ&¥lÇÕ´e1@*Ó­b½ëàC@DG±„‡³¸Q¾Lp«æŒZ&Z©EÏC2Í¹«xTI3M DÚœËUA%»—>D .`“öÖø®?=í-š`Gœ}ÎùÏúÒ}…˜wH¶•€ôµèPÎ 0j=Š\B0“;å*ùHäL¦ÛÔYÁüœFe‡U±ùéıM~ÙøŒ\öûƒ¯ mi_¡>V|ì9L÷g{µ'* & B(ÏÁVú~²÷œt«¤œç~€H±IğÊ¶³MçDAîùíRŸàäÃ–°‡KäàÂ+KŒBjT›M5( *•#Ñ5¤_Ú6²ö gKƒå"š¨÷gÄa^'ïWQvjlÂr÷f—A.ù}rûG³mçÊÏ!G6¸p~Tê°C\ğB²
¬#±uú([¶Ù&%ÿ£+ïot,9œNÌy»2±}´·W?~+İ«YÓ„‡àÅÅÜhOî²ïò7w4e‹8™éØ´Ş—,­É»JP5ÔA ¬ñ€ubÚo£–A_	š
Ê,‘'æğo6õ3Z¶#{yoNMĞo±IºßŠšÏŸ&K’'ô%<	Åˆ¨_¹mSÙ$GÖo{*»d¢òGL¾(5ğ¤”\ô„ïÏ‰ƒ2À P›€s’€AN"Š‚Û÷Ø|ÄHXM»,-uH>=½!ñK´‚82wÿ¨T ãÜ`NÚ*`+-8°¶$¸´jœ_’úÙ™t1(üÄˆ¼–Õ,bÖU5<sªúåó×
£ƒá*õÈÃ€ëòwÃ¤KróL*LE©wbÅóLÁÄìú	µJLóî‰õ‡^¡¡¤{ œ	µß´œÂu;ó–`€NpÍw½\Êè‡î5¦È‡éõT‰ïë¯ÿÇÄu=”W$“û¾Q"òî~àÌ'ØŞyQöU2õâÿ½‚_?)ÿCóº~B‹ëÂë¬¯iP&Ñ€û- yã¹p›éôu»Õ­Ê.ÁúÇ2wWbr`5|(«ËZ‚—V“ş='À95'J;/ÁO%¥]¸- {¿aV{‘3õª†:›C~±$5wd—» tÒ˜á3 e}0Õ¹ÇÕwl´‡Íe~=\<æQ£Î˜²¹¿¶8d°½fU—Â¬°ø%ûµ–Í\M¹Ééu{:m!šw6=U¥^úğ÷‘WHÕñÇ%Z@Ü›JeúOÆ¯¿@Öƒ,‰6· ñ¨Õ82ı¯/Ù¼}íÏÈ€BôœnAæÁÔdá Œı"yjşÔWÂuŞå“î–ß³åâQ›N¸âéf“Üà@šôÈ±Rf"­öñ©ı³ıÕÆÓ	µEv!ºÊW(; “Î’cã¦ş1œ8äÉÃ$R~İ˜,ØŒö·@”ËŸVÛŠ%haTıH—²$F[n¿ÕEmú0Ã¿w—ËË¶…ŞS¥_À°ı‹rÉÃÊ^Dø#Z­[±âÖŞİ\CSÓ‡CNr3AFu½2}¢ú±;w9IP„
‘D«dÌhÚ‚6ºà©ß+4ˆrkÿ€C4ƒ­ÿÍ*d‰bP¢Ú/ƒƒ¹&Ñ¹N>ÇVaÊgYFî=Ô¹s¯0í8°›ç•=òìî…R[³nwaÉÃ#ûÅ·º6Ì,åŸP9FBı=¡^§›³g¸`mi!f‚‚İÑgŸ×¤ÿ½ùñíY´-÷`ƒc;jRš ø*x­„¼ÇOn-[4ÃA
éÄ3ñÿ¦Eß|	‚æS™%µö2ˆ¤]¶¿]t†üSsƒ]‚ )Å•MH•íËèŸRa}ü*H«t´ïŒ òR‹Fv`Âükp~¤ĞDğğ6ıQŠii^eæšoè‘Wv¥E^½¤k0\¬SïIÿ#¨¸×GÇ’69õy.³™.Õ›éC¦¢ÕÈ?â•v˜ƒ™ÕÒù° ÀÒ_ù†æuÿ“^êëÀÍ—€¦Ñc75‡ŠúÊo÷g	êüIªFhÃÅü†Îƒ‚ÖD€Ïk&àé¯;€ŒÅs“x½¢rG¹’ójŠ‰%€d¶‚´ŸÍyc7½…ÎÔèjö´­®nLÏ–¿²†§Ï’¨
QQ›éØœ—»ú€ß–êãÒß£üØ©áQ(ßû6~‘)…*jg	1ıI˜ƒ jØ³vxWnÕG)&vJ,ı¾fşàòôaÿØ’‰ fÁïVİÿÌP}] ÷Û˜'Û ‚~!¼0òö ˆ7ÚM]'é­duÔ3H ™)z¤€ÚbË®/ãaédá Ò@‘q“úèã÷xDñô¡¯ãŠu#¥{RÂ¡2#í@E¯a.DÓó€½F–úƒab3±*ÂüO.ĞQÚOAƒ€&<ê«Ë ‹›¾¸!21¸•„½ÙæÖ¹†KZ­Xü(˜é€ãùf·…ëÇõåkS¬ 'ec£ÊXéšë^Å&JGVíÏ\bZ	€4F+r£°n«$±÷ş4»¡Ú\Õz„Î9YĞêÔúãğ«l¤åDj¯|÷ Å^3º‡–Kï¹¬÷¨ëAÄÒÛ	õÊÌî³SfsG&3w‚ ”½G¶g¦àĞ+(TiÅ²l0Aj#Øe9VìİÜC…¸Ôû›ß8¬ó]Ã8bô%<Õc©)0³ñ„7qzá?ª©:øÈæâº!´Ó®ÍüV%/|±è|µ'_¢ü8bK[ßÄ¨Û(¾æ|‘Ã³²sòW	Y ¤z€Ô™»!Şåıï"Â†*¯4£cÖĞõŠ*'ã
¤RO¤5ÔQ%ÓNRƒ	í;fû-CáaL)š)Ow½ùh|ÿ³èŞyŠ›åFß©O6FÂ¡(z¥×³–¤ø|±•¼/?éfÖtàÄ»ĞÂZ	œœ}-áÉÀ3hp#çåÕyd³š”æİòA ÖöN µ(Fı%L&WQ+
|2=+©½É‘ğp†a0“1Š¹kµ6 _ä`¿›ùŠfĞ@ì#8éxOÍœ2U*K†ŒVş']jşx$)}‹ä™mR t=‹¤¢')k?“1ë7Dİkiõ±š5İ]@ÖVSø7ÒëÊ¸·¸º$ÂE[ôÚêş”+Æ!u¾Êø~<«¥¿6aN°…ˆC Ù`ÖÆ8.%¤Ğı=’´'–Õâ¹Eè
K@·êÌ„ëH·²µhd$€°tÅRßË°ìÎŒìéMÊ2p‡È½5fhSEô´u”¼ÄŠÄ"õßãPf¨VÈE‰q~[œ­Šï?5W­ e‘o\Eï	x4“´Õ«™¼&·r)gı
P¯ôõ…ãs‰™PJ×†Ö$ªñK
É• I\i(K8”‰<ÒáäK/q´¼A^{š·m9Ôg;í¥Z5F‰,Ù¨"ÌgÈ©hœ¿¯Àà½ú ûe¤ÃT›]ÖÀlŠÓÑô4"0Ñ“å´àNxÍõ§æ	b^½tßóC0âÓĞJÛJtåì&7ÎNZ˜W;@Ã¤5ïñ€¦6ó ‡Œ<¾“¨‚×0tÄ.£j7„îjÙÙ¾ÜÜH¬ÏÎùdFMEX›Í}òfVğTOwôÃ^H;	Q4{®ShÚ¾¡ïWÙ–MÑ5 ¦-»ùÑ ÈíÀİ±“§JU°_sÚ·ŸüA“NÅÌwËµ—zwÌ(_#+*Z˜5Pl<eIó·\îü>ÏB¿ôC˜BÀÔİE‰PyûcÃÂŒø(õ‚Ïí*¸v$òîD²NwšÇ@Òóf„’ŒjªÄ¦b|÷‡u8J@aö{T¾†
«‹"]LiŸÓ@xK'·®VÛéò-Rnuw%ê…>11VMøTáÊnY–âÙ¦/Æ~³<‹Ä°˜œşü-¤/‹›¸w…[E	z
u@Ûd^Y8üŠ3œjyÑÉE§õU\Ô-#|·®ı¡ xfgîœíÙ…TfÒnÀ1²¹›Œ¯;‡
zf&²]â˜%ZXğZ)>èÅ(‡(u•î\£4²•\ß°s˜}Ë_‘–àé[LBB±Ò§eİ4Ã
ËÔÿ`øËù‹ã[ ãê¹WœPëÄgûËm×‚wybÌ9/•·=Ë›9S­Òv‚~Y‹]ğJmÏ*›ı='k0ª„‹NÏãæ?Õäº2÷ô}só“ã´½N0íÆnÂ\bsåÒ&/2ñk¹òHl ,éù¿j»¡¤ô„ÛNÙ$tûÄ:ºmb€±\M˜UÓöbÓ#	ıh7åIÉ£M—ì”¿Ş¾,I~Å",îØ÷bü–(Â ª]+6øz óÚ3*gò5:SSÌSÚ`´ÎJöå$IcØZëŸ4³æÄ»¢•X&­²´ôÇÖh­p( s—¾0Dj}°Fd,Cè$,iÖ\”	Ş^Ò3ïTÏ`j"^¨ô]†RxâIcU0xØšÉ‘­¿É’ç€F3c¢ëà±ÃR ¶WQ\p‘êÏ¯ OGı¹zD ŒUk"#UÇ.»/›n›_QîúÑupóÌsÇiUÿsRÚÒ™WãæeË×Ä3á¨tBbldúZËqã3ÿ]ÛæJÃRŒßÄiĞO,Ÿ±¸:<K¿„]àM( İ€^„Ç/õv÷ªØå®”A'T!Û¤Œîßô¦ìgÜâ•N²„&Jœ—bÁë
UÆİ§A?&±.q~­Fÿ4è+—7`Ÿ+2:Únèô`ß=èñrÚ]‰$àó„ÁlgÉRÅ„7=E­˜+•¿Ôrh dK½N@Ê2'Ù—låP$?p™#®_R¹=¢†!À¢h• AXr¼³/éÚ%(o·ĞIÃ±ğ&uBë¨’aÂuHÃ¬Õ‰cøÎ46.”fHqí‡¿è¤-~ÿ˜&q@\ö ëxUu“<üI2İ5¦OÁÖkLåÑ]é/njqQW1áœ–ƒÃ©¤%[¨“‹EÌ‘İ•´¬}òı”	m¹iÖ9L¡R%>ìÓ«fíÓ,ƒ”6ñ\èàØ	¼Eâ­eÌ·™_.˜8´öP°3H?\ó¾‡;‘^m—h?ÛA§eĞı\ñ Ïë„TëÄ	 ¨¢€ğÅ³«˜±Ägû    YZ