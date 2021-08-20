#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3028324151"
MD5="01631d25971ddd07cca6878313452454"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23596"
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
	echo Date of packaging: Fri Aug 20 02:11:50 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ[é] ¼}•À1Dd]‡Á›PætİDöaqı¶\ˆ!˜Ÿú»$²òdÄS+î7MI.ÿgRFWL)éì¤à5!;†•h¶ÒMX™x´e>x_şö˜íj÷*ü'v(ˆ¡B»H/±Ğt9¼7ŠõåØ‚®ßˆVüÂ{^¦´lZÃşšÄÈ0à–1×÷> AlTÆæä†5ôï.•¸€¨§Âf]CV^â·„m.¶S­ñ¹ùä1óRSöÍš3Ø®|HÇEíÉ}’İ
 ÛHíåtoäŠÒ¥|=áµÜ-Í—õãÔ«üg’L)0 èS’›>>Ïq³²^®U—3Ã€Şï>2HÖfCÏÔ%Ã­Wv¹[şœi¤Ö1ZjŞÀñÑÑ	ûÄ-‚¾Àr¦mzö¦8ˆ••™$ßş8)Ğ1æ{ vÉš	ZìÆÛ¢¾7Wüì¥öÓBkÄ|!~¾}æM´ĞŸËMcQBbY|sº—æÇXxz}:ÅÃRÂ§!y…?îFX¬Iè^TËá"ä´jm¸Š³s‚ó‰ÔFîæ¿ÎPê™[é5·e‚hr†}©ó”õÔo+N!¸­8õ¡’Ò3Ñ¼Z+…‰ÕÛa<PÏÜ²Šú™²/7D"‹Ûs;">°ûúp>2Ú§¥Ë•o=/BN À-f+hİeo
İéa³à(Ã–ù†)æÅ’È“ACöÌ9ó¥wCŞAìÿOäI
‰QŒëÉac0Üıge6‹§9bg¤Í)â­¢ŠÕ+!:€7Ÿ·TíW/øñît4_EYA‚{©Û]oÌÓÚ²'!å­
3ß:Y(x,ïÂ)^Á•E’j£œ¬¡I6¨— /å®2±şQ¼‚&Ç¥5™Òº+EÚqåú’¦ï{‘¶FSóokÁ¯ÿ>ÇˆÑ%™z Kg†±ãQö.­*ÇC‘ğ»=	Œİ6Sbm{=PÁmù¦äîœ3C±J`1åûîäŠKöÃâxØ°Kòºàúôs U¦#ÅäR^Í83c„ôn€ÉoLhAˆ\ZV”s“ş“ÑèØèğõ¼
•™v
\mZ›©dúô„÷áR›©½ãv¿==n=cÔ{¦İ5‹ƒ„s…vYv)Y=×>`ÅåêE–…Ét4¹BgiíÏï·ÇSvéÊzš‹‚õ&öYÏJÆMõÎ¡¬cñn‡ èBşéaãKª¾ÂùSôÇÍlÑKG>s€;IĞœa°|zéÀòİlº´DÎ>g2ÓÙ™º•\k3’Ó®8	ö¯ï‹ˆ)ç/û|œ i’sï½“ù#ßJ3^o·çˆ|ì©¬»¾m&w}pGuÆ¿l:÷„,áY•ûÕ &x•®-ü»}Æƒç
Ï†È'è×DDÒÒk:³ˆ¬ùŒF‰ØxiÒNƒ›9ºƒ Ê@‡O’àˆœüÇª_­Kªd­ÒïJ±äõĞq
“³ÉöF|=êÅ½ò2.¼ì+áóÀ‹k0ÿÉNP{Y_åŞ“=•"‰æ.Ï^$•¡;K.a‹Ûgly™ÍhñN!ÊØ²[«üQ•zßE‡
°ò+Bò©ÊCß’Åšó¿œô4|„¢æ z\¢«c[—ôâì±’oÛ€\EÀ¡;-ö#"	”ÈO—'ÜÚQ‘Ø ^ÛŠë%AAAí¦!’ó"
G+m¯‰"ûìŸI,ç£íûY‡ã9Ø¨bj?¬BEM×ãY#9òÓ ò7Şm/ùÕVô!hı½Îı—!ÖÆ¸ù±D’äÓø,Èsğy6V¥2áïjÜ3å•ğ`c¸éÌm»I¶sÆ?ô:>eS¥LëÃÎI¢]€¤5:B	o{> O¶U!ä2l`rç|™6¿úi1lèvU©#N½çQLå‚w-ô(Ïã+ThN°w7¢±”äD‹ ’ûx“şmğÉ´„¾AM]Â‚À—Dù3ZËú&ÒãÏPp–q$”&DñÔ»¹³?©WÃ¨3r‰¹w£‘äà÷uèoËKàÁ…×ÌY³—EË`øJá2 éĞuµ=÷«şè{¨ºcÕ»‡ÂXø˜ v@R¶3˜=æœ™Ç†›ê³”ó²|ÊéÍ™ëÙXg– ëqïşİîî?É`x™7r¿ùß[ Yô…5È±Ç[¹g­ÇşôŠÙnùÜ=›0t5MUJxÖES·ÉÌ?ø´  ½æÁØH´'¦>Ö¸Sıb8…„ğÖ,¨U cô&÷8y\2=)ÉÖâŠ¤¯Ş&Htã_^3O¡1¤QĞO¶½ğTŸãP?8Ş"¿HÕV }Ç×¥’7* ˆTòÑ`Bôt61Û¿'ıÅLªf" !¦µMQ€I3í™CR¶b,¡MÙ [(Zş-‹ §_”QÄm*…ªfâÄ67Ô
I¥cà=£·şàm$Şî]‹¥ú ƒF©“õ‚—•£^^êÈææö[œ³ÿGdX¸¥Ú“–ú“Ù¾GpÉË2‘7±ÏïLAR l\ó‰Rã½¿!L$é¾^g“eü¢_f`o¢ÿÛÕmÙ·§)"§‹íàk”:MÉx†âá3iôÙ;ÖÕÜÖzš7å{ÿäöS–ı5™'_g´“`ÎE½¿üèfÜdG;<(¡^ÇP°Æ$uÍ”ñğšæçdI À2YÔh£3päÏO”Hƒ™‚ô±Š„øàë;	‡§(Az#L$F’<œ*qØÛÙKz·¢–‡á_š3•Á¤é¬£Õ¦îCxèS§7‰ví³:âLoâÔ‹‰F×A´¯M,ÏaŞ¤ôÏ€¾ßE¿Œ«=óØ&´+Zb…ÅzóF§•ø=“ntÔ‹ü¸„Å°ş¤ç¾ç»rnDkâñ|’]¤!ÿz’ëCâØ_ÑlÀWô#Æq"	µêTÜAòÑ"Àò‡Èk¾“©F`´‚[Sšê¡ø3.¤tX6tÂA»J¯æú&^æÛ¹û@^ÈÎö°†ÎU‡< ’â¹VĞ”¾È"¥Ìr$ÂˆÜö.ØÄn
E®¨ì:3»|@¸Mïö•*ÛDœ£„]9¯¨¢a<™1†#é‡ÚFzm5~¬ª^Ná@õ–ÿRÓLeU¶ŠŒjÿ€ó±~¼Ü¶56Iös¥ölT€W48,Dì.òD†Há/Û=N‹åu¢<YT³ÄÉ†n\£¬Àl‹ê=ï\C<ÃëdYrsÿ'³H`4l³T÷ éV=P¨¢Í#ÚUÚ·&ê\{ñ=hÔâGs~,p+“rÉTì|}€{z¥lŒñˆ\•ñZ/—(á;AR’T¥9¨#µ„‡ô¿âÙ>ÊÄ‘³ÈÊ*	
+¸¿bçÚ,!»£@é
c/@—ú»ŒyHî'e[“Ñ­AŸCc|&Ó™®&Uç'µìƒ>–í_Tn¼÷Ob“"²…ŒdßÖuzQwœ¼”,‡Ì8—ñË§áÕûÂ^k;´‰í&‘xrˆğ³Œ_ëÛQÛ!#ÒœÇ‹nÊK/}şXÎYQy%İ¤MæB¿ióˆ_bNj¤˜›éö¦bĞQÁÇá›!±ÒS	ñ?5uÆËåËHÛÓn˜şğ ıg\û¾ò/ú»a(´ˆ%ñMs’ïvÄMÿ…Ècçc³A³`\k;«O;ı¡Áà?\½Jl;ŞŒaa’,ß²“ë°¥Ó¿Ãj<ñVÔbˆÜîò*¡ xßd:–Õ8;nmNé”G²›î¥	QX†Õü««'N.0¯*[iœD¥şUn˜³ÇˆFò|ù²~ÍÄ¦}†şaoê­$gdŠÿx6©ªXÜlk…Ãw»jB•±‰¡î ,{%CÊ[x¬š¼]˜R:/*Û÷Ó}µÅ--Ş³ßBÔ2'•ÆÕÁWš?f²0lç[k[t×©Nejà[y^
rA½ğ 3õ=1¨§1šJö_xí¯·ùUº»z½­R®ÕÊ!
¾ÂZıFÿdy¿È4Òù.8È“ ®(Á¡^RkMIê˜¥à°2Š¥‚¤4pµ(¯½îÜíC%àï
ã#XUå>&`H-K·z!öT<’í`Dß©»v{ êG>®¨Î´›’Y˜¡•ÚÃÇ³ê8&îéÅßuq{¬O\Ş ï´§w%«7`öS$Óš/˜®˜Ä“0:ëÛ%ëÕÓv©RĞe÷feÈ³{¢º·Ä7ô<VEkÚ'vÔ}äôßlRM°¯Ü¶UÅùá´°jí:Ññ}„[½GûjãØ/©Á.k!ƒL‹âOHPÂ®-V1TäÁÛboûhNêæç‘[²rMÕw™İñ,İˆ®õ°g[Œ†_êºã Vœ€¹ CÏ@²Á©Œ{yÀU‰©”‡?s¬³Ç¯RÀ´ƒ“:ùÍçw;ŒA}iÂ@Nş§©!PC~Ğ‚o@A£kÔrDlëÿ¡àc''¥c€•òh¨a„B5*‰ÌOÚiÈˆM¼í âCİ“üäpßĞSi³gƒèqCA AW×+7-Ö5©B(/è	_¡Ù %óÍ¸º>GèÜÔU[¶Ôü‰İúÚ7m97w_ñ&¨c´ò—0ÿ>¥£±ØŒ?¾Iûá_åÂŒë¥»+|÷ ¤R 2<úÁº¼ãÅÙò÷÷ô‹Ä!äb¦v3S]’F&(Ø´³ËK€¢ûšk³¼× ³)7	½§–åuõ£Âuød(	²²u­ş–t¨Èæ4ñH£Úš0ğ4Xˆaİç%ël½D“D~¢EAÂ)_—~‹Û&	Áş§q‹ådL^¼³3á5iÉ6¿º'¸ˆÁ%ŞÊİ/•fô…aò‹)AsxŞĞnù›Î”Jh	6…åÒ_ `ûO Ÿ^âİ7ã<ú®q·Ş„õ[Ú‰ĞTím. ÒŠ`»üª`‰¸`í_9óÛÄ9ëz÷Ù„½Ç¨é1ÓâTy‰3ÁBÅå—›’ÎƒŠ1Ú·nCÅ[/X¯à.ênÇÀ	Èã€}¶çµNé·ûµ±ùà½nì¶aÑ©v8ô?5C'r¯‰›Qí§î¦=DSOtÉ¨}¢Z|Ç˜’2¼$åäz‰Xt7‘*›Àı³µaÛm³Z/òF~ÃÅÍif'EM7-)ÃÜ«­Ë†ïíö¦T~ëÀiQ¥é:'1®_3åhZCŠ€İ˜AT
Rnş–ÒëÈ`3“*Ìf#†úq’ÇR2ü‡¬. ÿ]ÓÆ¹Ëq»Øßj£Ù,NäTúqUŠfe8Ed2O+£s¥Ÿ	ÉóâŞzÈ°©¸¡×Ğ0#ÙVgbå”x‹oØ^ãQR±\å‰Âçªù«”*kpÈŞdiT1™]uú5V¡l«†F%‘¥Y'"¿Zîàé4RİÙË©"€ü‚)\>"Há_‰§ê.%(!Æî€–§·­à²e4í0±Äá¿uŸs¥KŠm%è^H©A6 ky¨²pÇd¤éOù~¸vÇD>mí÷å#´i¡·°ëV<gùÅ”úl-ò×H‹êGùÍ…¿€jÿ¡W­ói‚$cá+HúWŠÖ€©´h#T˜!8üİ>
ÈæğCÜşSY™ç6™Â¼jµí¡ßå|S‚‡Ë³+(I­åİì+”nT6!Rö=hI1æ«	—|bS£ü¥&hõ½»cN„“d>…bİ¾l¶À/ Øş¯Û±r˜mZ^ğc
š ıÙ£\Ê!	´â«Ôz£Ç’”1rµ æ2«g± NùÛhí&†Ê²eïòƒŞ¨´ãØ½İ×uÑ·UkõËW÷D’P°~ÇNt´Ñc}î]\=à!œ!º8„İŞ ¹ñe5ZeĞM&{7	û»„HûÜ>õ„Q@GğË@åô}eri…ˆòB_‰—D"ï89{Årïæçp¸*™!s‡;d¾[EÂ§É¿%(ÌëqS¦”dMa­KixïàesŒ¡$´ïÇ?s±nfŸ—€
QÃ éÙã÷üö:ı­ÒñËğî;ñçª¬Ö?ê¥‰¹ì‚PwõÏ˜é^ÒôxËe_â„Iµë{š´»ÄÍí{àJ[ÒÚ_äğIU¿‰êã‰â$¯
Pè«Iì*Ä}§AÙU@×h]i<)¥Ô')~‚)9­ ú«<å;=IİKiUÁM)ıâ/Ù=f   ÇŒn­‚[DßÌKw^\*²¡bÏ74ÎŞrë+:z¥ Ç«|Y0k·$…şiï­W:ãó©F±/¥µÓ ihµáÖ±9êEÉÉ«é|6_¾T²&Ö=Á«šF@²« ¿Ò¢È0ï
Ã,:ñ~,Õ’p‹4ı—Z“\€7LÜ× G¬›=/rÈ9oyx•zã¬ğ©·CØä¸Ã+CØ‰»SÊõÿ ~A6ÎxìyÊLİp]ø€É®E8ÄE%PN›}B„Œ¿•Åz¤0gwmàÚ]³YÀ@Ëj=3®àØáJ70Br°¼ôf!Š¶a#¥~Şe,{-j–
qB‘egZÁfmì»ËŸ!
v=ê²‡’8â›³€5aôº=1œU<‘Š´è3Ô§‘f©Pœ¶“!QWÖÃ7¡¥Ö”~ÌtUğƒózÑ-R¢n¿¤Uã<á`iÁ‚>t˜:/—±×®:´ud0 ó˜‰¢YÖ°ã ä \?‚‘vöËşó[+[éªVÄ^¹[øJ‰½0¶Ò²÷iK¬!Ş[ªš
á+&àÌç¢Qø5u Sb—MDMÙ8 ?Üuvõ=4öóW]bâú.Ú?ÿM”÷ÆÛèŸ2œ’¾İ9$0â\CÔ–/ÈÁ@ÿ°ã›\õZSÙÃÔÒ9Åxp…Qq—¯+}=AÁL$iïmzpgøˆNÂ6îˆx©!vZ}úG¶½8²÷~ªâ«×ìŠ´ñ^€UB„š Â
(”mîo*:èÅ–±ßÛ¦ßïÈ‹8RE¤^QkvKŸâmºk›®¨ÂâËØ‹h­WG‰¢¦¹PEyRùËv†©{¥v[	à•yÏP†(Çq®#×¨©G S{½Ìò×±.^Xxq«+_õ/ßn€3ÁJÍs.†s]Î¸h¡±!bqRI@ª™ ¤5='ú:ã2õÈ‘ı|~o@´íúJoJ
ƒô±Ôâ21¶ ±Déf!ÉÏÃVGŸV{%O@Ò×ÖÌ˜ññ±es)WFp²ˆªÎgUo,§ı_öåøÚä‰ÙE”š‘7sC¹ºñy ƒÿ±èŒæ
v¾Â †j}ojæî;t³6ÜÀ‡‰Òç ğfÂN7Óc'÷ÓŠÄ{A0‚$1b½:9zÙÊé7]#ÈÆB‡ø…9äÂY‘YN|ôI0û, æüÔËq	gĞIe´"£Y‘%Š5E©œ1OÒ@2zaYQ…€¹Ö¿‡½8¢ĞJ§`±J—½Ö4»ë(¡N¾'ÀH‰<7 ~  %“†ÍaøšxK™ÏpĞ\	y‰·İ2W¨ÆÉ¢‰ƒ‰¤pÌ’/¸çóæ¿ØÛT:^EøÅ¹ïNé(Q‘y/	ˆ‘«ùıæï0#i?€ìÆ¨K;]½Éékhõ¢Ê1µrL÷ü¹;Iğc²E`E*‘hĞrÑU!ãE¶lä—¿…¨QÒWÿáØ;†éÌÇ£ne Âû×7‚ŞÜ“ØÊóà¼E6›ÏZ)<1ƒ_+BÌç¿ã¤bä‘ğmÙç—Ù‡Éj5×ftÈ^óóù‰QœôR"Êƒqmœ)¡«Ñ¤*CÆòÜ”sT÷ÎF?€-º¨,ÒôR)0X¯DÂİñ"•Íäîı‚@ôğïZ÷¤uÀ¶Í5¥ÃÚ‚yæ=¨È›:W–Ê!9vVÕá8GóÃt=on‰ÛFüıE‘#ÄTÄ}ıTºñ2d”´µàĞ +?Üz6"ü4WØ@ó»nÛ ‰UÀkä_tºüA‰¡bQC:”#g­l0Yrq Õïdñª•'	×hb)‘(lĞcPnr	\ğ{üƒ¯•Nß¤«y¦Ü×!HZÂà6™@2	búÊºHöÆÜ7@wVOr!‹ÒŸACì“3)OĞ³KĞ+ä¹«õ‡”ÓŒÑêÁÂÂ¸D2CªQïM˜£¸?ú0lœ£Ù‚]‰ÖÔàü)ğ?5Yy¤>ÍíÒ‰ó*`Ş‡«—0[o+V&k~%y°Q AÅ˜N€ŸÙ–Ã 
·v[Á‘¬êæ¹7~•
‘£öµ–ıFÓr²`§ò¤¸Qf¯Áé¾6Ë7–¡¬Èë#\©é©Şé|nrÌ°¨³a0¼´ıÍedöåÛ=¯Å\"¼U!]œsÿÎİÔ¯ÏÕq\së˜3õä,È‹åPèck<l¥Ì<ÒÎÖ1Ï¿Öff±‰uÏFª†—Ëz=7Ï¡UÑÌR¹up †Õö£¯İmĞUwú«sÃ2
ıxŞİÈh‚¢ˆ+‡}ÅG‹©jÇeç˜^N¾Pïe¦5«şOqj5ˆÉ¿æ$E\#Í`µ=b®ª5S²îà¨İ<DÌ«qº“Sr”Ó7„†_ğ²s]á¸}üb«à/*!Æ‚‹OA2m
˜ûM¸Z*‚YdÍôÎ˜š’[ñÅ+¡ü·˜?
’ı,o:>maÑ]z‡!0+V]îúˆ2•å0e˜—?®­ëe}îZ’ô)ºû,09¬ŒŠƒ^Ãõ‰f!ÍWEi¡‹ä¼rKI8´NíÄñ>¦âŞğ^zãµæµqÃ2[²“áöv^ba]ÄR5,ÅÓ´øÄC9õq-r­…nş„ …ml~`¯O vO?ç—ŸÕƒ	ÄşWDFSZ“dZ¡èv©ëd‡oØo1l—Ä“Ç{ d~hõ1‡Ü5îqc™3ÿ©¿#(I64,˜8u¯é^xr9 q3—<41¶)ÙL&Øí¡™5û`ZÑ1Ú¯×næZâñ·Òõ¤÷¦zïQŒ¦”Ò< &2O(Úå‹»Ş†}ßØR'Æ÷šë‘ª‘¾B:èº¡ªÑkÍ‹İG'ò:tş¦:¼7|ö á#±‡«º.B°ôÇÕ”nieWçŸÄu»/8rãĞ‹ş™?`JRp¤ƒ7ìÃHCŞ]%Ww ï÷‚ÇYõ&|åµÈ€áî©„36¹4mK^âò¤Ê§ÿt¸Íy@Aİ±<|	ºè ”ä>7ö1{Zé=6ÿÎlah¶„˜4®ƒñê³îy{" o|®Ó_-\÷•á=)ÒÏ´j¥1ºO[HÛaØ$L@«˜®ÑŠEO¼à·"İ)÷aD‰<XEYn¹5È4ôeŒé<‹fÚlË¦Yu¥°:ª¤’ÂÇÂ‘³Æ’ù+ù™„= ùI,H®É°w6A€•ÙL·1ç•PzeÂé-PªR1—/u[o2—ÇäÚ¸Š>Ó[÷_+<E…!7¾|~ôªÓ£öTMø r6P-—n-E—šªk rë]1²{g/+iÌ…7¹C}gSÇâh~ï ~«¿mŒ»0=›œ%d–ˆ,Ç¼B1Ü.ßµš´çï•êÈ¨x
•–7$ÅxT®›†ÎzDO—D¶«šI‰P’ÉM½›ôñ[œgHÀ}ã~AjŠ5¸¹{Æƒ´0‰bIÏBfCÁC.L¾$®$TˆÓüYÁ¢Zäâà®òÒãÉ·Ú/ÚNµYæ\7‹•{1È‹mx©]“ ¶9éÎäå(ŸºRHqš²2éyªvk¦=-qb¥QEët¦"o£ı5üø¿†Ø	ªjDÍ”åg=æÅ~QW%kƒ0¯ØÙ6§Ği½YfzØÀò’4£Ò¡	V¤qÙİ“’+‘)ĞZÿã#ü­¯F»»øWŒ³]5@jÔõÓË16'Êı	¶/Íüñû¤Mö¨¬I[’BêãyÄİQ“A&«Q*¸k™½jUÎ˜fÉÛzŒâUéÕ
é‰:<ËŸf§z¿Œşnú¤ğM}ìšï(Ø¤·ç)Ü•›gÇq*5½E$"·¯gy÷Âí{ª)weÎ+7)ã·ÚˆÀÛñZk» ­KêŠoŞUfDPø6åÂ7UÓ.ÅV[2E§p²¾Çş[ñtÌ~¥øËµYni³ÍV6†²Ë?„Ø2Õ|œ‹ û!ùÇÑøá¢Cn:ÈB1@œnY7Ôy²Šá80õd”ƒ“~šşQitÀÿ5±g ÅoĞR‚8ş¼6på=¹ã•qõ>Y„A%ßuI«ïÔ;çêp¦RLE-z~6Li¨ŒÓTÇ;	ß“Ş{I¸­F
z›>$óUEJ—ÖÂnp3d|ÈÈ\mà ´‹¨Rn@ÌÂß\„0ñ^ºùê¶í‹6¹Úi+­ ÏŸƒ9ÈÑn°Y~rñ•mT:‘k¨š4`€ÛlŒöİ|‰A8‚ıœ‘É±ËìaÁhh©»µ=( èÖÿ… 5]?y6+l³¨=ºKëæØ×%l!6‹UN’?•[‡æ¿ƒÑ—¾õKãÛ¤h!‹Ô-&Áá÷¢®üTÙSŸªq›N®áÁÄÄÅ•]|yÙ”§¡½UV>n0™uRßÄHÌÖ¬»Å5«³åÅYë3äÁê'!†G™ê$WÍl€z½FFl_”`zÛéØº°Jšê·aÑŠsH…Ùc4í·f]Ğ‹­_ƒ-,—}%ÒûMUS4iCÊÚ‡+`MådfÛ64jïDæÅ&?±Pm¶”;/ç9û:3ˆë°XÀìM—q¨¹Ö¨3Š´
›ì_;Ñ¼’Aæìm°>2ÉL’yƒîSaÈûÁ0q…ƒå$ìŠ=²{éœ‹kë›ä!mğ3i¡Pº<8gè¶4rW'8´-]ûÙÃ%1bL¸q	+’w#Çèf8T\Â‘xn÷Rs6ş.iâ?[=±;§¿¬_|ëF‰b@>˜¼6nl­á]şTûÇ¸­ÅÉM3Ë	Ìp€ú±¦Äïiõç@º‚ğ¼Î à¥[™	ZÊ®Ôk£k{ş'‘ê­ÍBé§ãÏœÔˆ ŞîŸWßr™N„aô·?6áÛ(-&KóYhytişş_ÂËwØ‰¿šd,¿kXø¬Ò£‡ÔÚYå´QáZ†è‚E(‡•ƒã¥úƒ‚¢9¦õ4w"Q€Ñ@iïë-ò‚S+½O˜äPÈE€­íLD¡±ÖxÔÒ>>Øâ¨h1s/3óÈü(q1]…MÊÇÂÛg?¼}n¡ ê9fD&İîwšZô1Í:Æ$wDNËeväÃ-ÏG0)ÂäüÚõè½};aŠœr2{v[o=!kßCìs:€m IœP‘gæ“x¿Vf9%ÄÂR€åB¨QT.‚&”ÅéMÜÒšÕshûE#5ĞàTv-Ñaümªì=ø4lQéL9\ÁêG3ıMÊòB•Y-!·`h¡Ág’ò>[`¬5¤WQAÀƒ0r`¾Ûó¶²ï÷Hu¨Æ™ÎnBsn%OHc©ªô¯æ#7-&£î’a!‚Uí-µ!!J_(‚e"—@›pÑ˜hÍKÿ~,Õ>LŞ1X³½p«z¯:$R9)î£€ì”1U†­ñÜÿğù×ò³@ê/i	ü›îÔ.‰˜(dk„¡vr Í©Ê oCš@ pCÕb{9İÖå’4ó@Ç‰t(SIÛ³¹8âõ†`ä©½éüMœ–-as6{³é×&% ›Û^½A°YOº>¼ŒšùÄsÒ›GZG”UÀqqØÏæ6íâ£Äúğ!«ŒËjŸ"\ß(v©Ê½-(¢I¯Œ–Ï4–ğù6S±ğÂmø9ø¼íÜHg¥Ğ1^dŠÆîÌUÁ5]j}=¤`Š^Ù rt÷Ñ§â€İ€ûòi–ªcŠbô+o¹*¸“©[LÍ‡«G3Odfı‡Nze‡ ÙÑÄKH‚‘é#Ä=áç³xğP”›
;Ì¡|kQ»ïÎ	
Hë$6«ªÈ’š‘KæÍ{•–gŒZ€ßÃ©“ÅĞødäi?9Wn+öÆ#EáKn<hXìd|Ë…ÁO„å)¹¡ÖŠ½é×W¶?Š…AšI½"ìEÂj™É`è
ZB{®ÂË¹mxøãa¿b±LYŠ¤G„’éñUÎ+Ltd*"Ø.$] §Å#¾D}‡V´È¡)µÚœ˜+à#l6C²q×á’IxHX*/ƒ}OºO(Ì¥çù_‰íBÚ#ĞÄûG¤Í ÿ4·	¸
6YÁåo¶£NÙL5‹EÿM)·P	Şg8
şBğëFı(ƒ.{kºrRöp3œÃWC u;xË£ay±4D'ŒFÒ{G©¸×è…PŠÍ‰‘GÂ©2ïô#œÌÒbC} z®,$h¬´%@·IÿéËœãÑCSƒåŠg[èu€=’üıRüŒ¤Wœ¬ÀÁ¤ôí2äóOT$åÚ4Hnewé­5;šØCÃe‰9µBd¹Õè¥N½U¯cAÈ°>­™‘îáø7Lö;¿‰%âÅ¢Iú^ º	ô^©âÜß®÷¥Ôä–huHéƒŞz,²À‡ÒÍòài†ÃT^ÓóğÒ^y	æ‘‡Ùyù¦,ßGpÈ$"À-»W'Á|'Ò;æ
o·UqùÍaXgŞ1p×¢4ûçÉW\ûsfi¯Û¼S~øËu0"j(ê¡§r{¼1åŸ´Òu…>RcGV¹Fõï´‹„ï{]ß_±mï½ÉğiÑLá:‹3vïO}Ü·mª<(’áÔLpæMÀèsaò4/ıâ; VpÀ¯ŞZ™ï: Ud!ôdng İjîÅ3±W›öb
®/îÜ·+xõöÎ×È}Ğ6÷Æl;&fU°/®6ú¢ÌNÓŞü_K½eBqäTãÍ_z.=‚mÂ­Ÿ"ºMYs:"Å°İñ³Ö²Ü­ûé­É=={¢Û;}DA+­ÊÆ¥¤!Z¸Àƒ8nòT'¡s« …ø]’æ-®N-ão­C®!öññ®õjnDÅÚ~§ûì…€0oUì9Ğiµ‹DÁ«âF‰K ’Y›DÎ…ÏH`b42EĞ8Ü·DF¬—Z+~8® ñÅM&U Øø?Ã½€Ñ>ë]×ê.e¥¥¾ôØßÏÓ>â ie¯N;õRj>®±`_'%ÚRutEŠrªÁş…X7/¾U3ŸiË§C½¨ß i¬Œm,îİìò Ag¢×(ÁTQë B~E2¡t|†Bİ
x^hÚi{éÄEv·=	!sºlóP#|ö9]UÔHæoíBöÔœ:¢¨µ/§¬sÛ(š)ŞG´Õx¿lï¤c«ë­1şé=)ŞTj»]k¡ÎK<Ï@7äAs7•¦	ø‘’óG(Ò–Ãƒñ[4Ã÷hŒ/ıßQá­ç¹´¨ølõ.LoeÊĞÄùêÏ.¤É‹ÖëU3ÆÛz‚¼T©&@]t!í6hT©¿°u‚:ÏõğBğX¾1Bt´/'éîôá¨[›lû‡h›{aAb×ãcsƒÊW²¦œ¥£r×ø5>ÛâR_ŠX;Wt±Ãl¹jF¦éŒÂ óëÖ¦ŒÚ£·ÌN\9â =ú˜{fÑµ¢ú/_N¡ĞR.Ì¡/”„bqCkÉpİš]ÓL&Çe0ŸËé³ô°šv¨&ÖÓ¸T%Ê|ñUÌU?ˆ»q¯t-r=òcaİ”o~kÿŠGClÿÀS:ÈSGõâ›8Ghå&²Œ¢ƒ¡~660Ô3ö}IæßÚ#5`ºÍ¦¯\Ş ºB°-¥UQ%3Âx:ásH"8¼’ïKÉèhaŒDKIï'Âp¤*¹¾W›úĞQÚÜåKWÇ_!zoÚÕ„àqt»q§Éúö2ç6—°À¡½ù^ÏÖ†|¼KÍÚÜŸ´˜@sR*„Êµys]àğ¡>sì`’ŸOÙ¹×ñ<á¥Zjl¨†›•¹w!ş7p05#	ş•Ÿæ>Ïÿ·ˆ[u;*àp²u6µ¤tÏ”…íÙ¾Ë j{ ³ä@ªÖË¯å3¤±ˆ³ac©Z=D²l‰¥pL5å–Ou`cÓGåÔÍ¯î'êØ¦TÑ7rı%rã5‡M2öK|b4z–‰nJ´

¨)Û"Íëõ¤QqØğY2iÚ<Sy„q¢€CeÖÙÊRL>J6¸Ôp6.ÃOêdâÈúÕ¯oDäßR‹d˜˜^\€ç8—pO&ÇôÓ»¶Æ©¸F›¥·pÔğÅèk~T°»[·G%Î€Ğ}ŒêAW˜hfOš¦C–8ù`¨í§eû:»Y%–ú+Ê˜¾œr¨(èç@~åÓË{Ñ &F,òIaL¿ª„;?¨¯2©Kb]‡ëÊ½{‘mî}åXßIÖK?D+|g(zß£›ûÇ	kv¤‚3½<—«ß^ò~ö„´T‹ Ò~3ƒep™ïVßÆÄ”€û†C)¾AûSäıQÍ¨!Úîññ¢Ké•+²‹ÔlÔPy_ä®ˆC÷bk“2PScä¨ŸŞæ->wh#Uoë!63ü7übf}¦¥z0èçû6T	…›æ”?zÅ…•Êñò­‚ŞOå’\™û1²ØIb »âNo*R>,õõ2À9–ëJî°ˆ¦¦v-¿ÎıF'àCnü›2Zgú??—¢­
2ÔbLé‹N¬qxß„³Q	<®ãìn-6ZŸjÕ{$LîÄ›ë>‰bÈ}ŠMåÀSû¨*dQêˆü_*KˆH’RÏz–0q‘QsÏ:
”Š<¯©¼ÿ£lBi\cMÃ”}jÏ–—µ€ÄM_±ã‡äÔ<”Áx¤‹wİÔ>¸Ít†!
¿]¦v¥æ§ ã˜%X _GI§OVÚ;´úâÎdõÁø¶U4ƒÔ,v øOìê$í_j|ÙyH‰Oı	ı¢ëÇı¾ÀfLV:)É;èw#½Vk´2‹¾Àåä-!”&!9v2<ªÔâªûW{nÚğ,ñËç;…FŠr7»£±íUæóe¾~ı9Ou?0T¸Ñõ†¸}”~Æ[>>í-Ö¹²µÑ»ù2T¦I³…¤@I9Ñ`MZ-bÕ˜”IÆøşÆÌ†=ph7 =æäÁæİqnBT.¸Œaâ7´ä?àÖ+¤Š<[+ø[Ä\ÈbÏkš‘gk¥äi§d¿[û z¾*ÙKmÌ'²7iĞ£] h’_K
;ÓÑns©¡êAtœ>»3€½£—–‰¶é¾}qYüïãkä45Y¢Å~H7$q_¹Â¤³(T'|ÚRBRHá‡Zî#èÉ*ª<Sı‰@ÈâFLÛXóH²Lô½±èŞÊõÎØ,"3==…İïXÛùŠ´WáøK7–¢ßN™çĞç•{;‹GÀ9İ$?ÿï|ç>°sïY@âï'iå"ª­å²å¿aºŞœıâr´Fk+3ƒ1+ÊY$¤¨µ¹À)¸wë;B^îMÁı¾Å#Ex/Ù{Ù%FX–è oy¸·šÚáW†û§êÚçñığ2S®êG#Õä«fxÂ&Æpï½/(‡Ç½ş¯[ş8z©^(ğ€¡ ÊŠÃ	+X'ïô%@‘¥‚A](/?4êBBoÿÛ‰S×Óü¿›Š6²,Mo†İıRe#÷À/zğ6‘] ê¢kAØ#R¦™zíuäs?mhË4‡)ŠhÜ(ÉÅø³]˜NR;òa#>Ğ?@#¥Gtº·Šûd%”Ûæ7ì ]òûÔ1È‘ª:¤ıİŒ’ûMÙÔÌäF#kÄÉëx’À*(ÃĞ]ºìº¢¹ö˜Jå¥¼“‡§_…ırKÃwÑ™¸Êqï‘à€
á£Db¬©åğv½Ş	ƒ©bD°úr¹‹ÇÀøÊîÕò¨ŸF^ãøí†oæÏ§|	¦ÔÖÃsÈdÑ¼OÃôçue±ÙGÛ¯Í®QŞ ^9Ìw„ÌxƒuY8½¶m8»'<õò‘^mş_G2p¡EZ¦5Ÿ$à$¡Øõ¢L¯/¯
î*©"²oØ¼YÇ®ÇÚŸ ¼l¼¦8ãYHs8z½QiQJj%UûN…’ A(KÊS 9{İşMRtõïPÈ!´¢éyDUè˜3ç@Vêß¼nòÿ(Ñní>çÈW|z^Ì·˜àŸÅãG›o¬(¦|~dÈDä
Ñ›hß\dÇkXÑÖŞ¼3îš€§TùíCş¿<çëbĞ2!š»&AjË·§[€Å›yá€NxY{Ÿ¢Ò€A¹óIj'3 çgkRè…Ó5ÊIK[jY¹Â´'>`a5dïBìæÅ÷ÂÕŞ‡!J|]D8›ÒøGÏèÉIà)Î8-‚óuÜÀû 3—kãÖQ·Dş•"^ºy—w•.ÁX,ìÓŞ
Œµ‹EaË8fĞ5˜Oà{+.{9W*>¯¡ƒ&yvı$ŒŸ¥€yrªÛé®œw!‘ïd‚ Å0.óåfÈ½ÿ¦‰I©K²+Ñ–h± µ¹Êóä×ĞZõ>‚&Ûf¸Xt„,Ëdüp3èĞ»ëÙø¹i ~Øv<çïƒùúúÔí¨`,u©!‹—PÃË-²¿?Áù?Ä` ß‚ˆ Mö1=(Nù“¦Åá!ÌÓ
%ä9Ÿn=É'¶Skˆ¡Byò)R:~î"Ò Ö¹¿>åˆ©¯©ÚMMŒv²‡-”Ò/¬WÉ¼ñÍMN*BùlğYZ" ï•:a$Igd®ê¦ÉãL•Ä`ˆÌÂËBÚèÙÍQ¬×#+ø$›˜.;ÁÓY²Y|#\4ÓVq–ïhÃçc‡WyÚí†êçŒ€‹œy‘oòŸ3ØÈÏøáÒôEy‘ßÈ³ÌJ´…yCB`£ÈÖ¨AK\ÜùrFG3.ŒÜuûêÄ†ŞÄx^IBˆy™fCÒ«†l?'„wÇà ó¬o!cÆÒà“›;JK è•™CNb/,” Ò¨çpÖèãŸÌSJÌºd„;ÑVÚŸC=–ÃD(+µw"Q„Ü%hfæk<hy4Ñë®&¾_‰şM”ÎN²´¾K`F¢¶ª"6Ú$“îŠúËœP¨ÒŒŒçê9†äÀ:ù® Yx[¬ä_¢ö(LßO=l~Î'3=¿ëTA"#­n„*¾„2›ä±vh#{yÂÕôÛs3Ä_fÿ)õ\4Îò -à‡¯1õÒïèxÚœ¥k½Vƒù¶ÚA5Æô›ES!2{:‰a=4úœwÓÇSNÄšíã‰¿~ªÉç’›JŒ®UªÔÿ”Ú/E[{:Dn¡Fl {„¿0¹À§¼¼Pã EíFáçô?ƒşŸñ.†"#}X8Æ tÈ£¹¥D¤’üıO@ØNïVø	Ú3´m}šĞªnuQÆ…§ĞhŒø-)pV¡ñİ:²Wè— %Ye\Z’îêé¸Ã;Ûö[Z¨¹hÛß¡Ç=·±áã>>Iîği/RC3‰`8_F¬Gw‘Áu('¬§Í-¾l‹LfeT“PòÃÅ>W\Ûÿ|©¯6ÌGWÁÄ>CÚÛy‹‡•šwzŒi‘¾ïËFËêG;AÎÃ bF>.¢Å"
í>½íaã9ŸÕkı³dnœsÛb¢A°ğIÂo…ëy™ÄÍ¦%Æëä.kN1kg)Å>v%ÂsB8š’4$CXnEèÆ‘<éEßJ.Ö³©ÿ¦]'gc³Ô’‰Ìœc0$a©É´ñš,ËäËñÿ+‘.§%Á~ÂÙ³Šş˜Z…Úšgz‹äm×:`ë"şd»¥W›uU€w¦P›Åv±âıüácj+2Ü·QëZ~‰†×êZÜWídäw2€âox·ŸJH›4œ'ºqâÍ¦X­×\m|¹ØÂ©ß´~À$9Ú{R°-É7§K"ÃûOÎ”zj½tıO©´¼b>¬ÙfòÉŞa³”]­hÊ—‘¤}Çî¡ ´Ş S2	ªû%¬À;\¯\š8ÀéÚ²‰»ÜïÙñkÊÑ†ñó&<©Ç¶¾1å+Ÿ ÉÍ§Íwˆ!pN/Í9Ù¬=+D:¢›ˆËZX±hì°ÙÓÉêóàò'0áÎT×3[H©ÂºWh´’¯ªLö¢;ØÒ¦ñ+°q?öÌ¦‹[oìÑC›ıfnE©vjÄ:|1ş”+·<DJm~ƒa®¬Oõx5<TÆ
Ü5bh¿7¢0B>1x´7ÁıÑZ ~“ëê;|%û@‡-LÏVÀ*s1/ã[ÂÎ;}ŒÀëô¦º™<²ÓÅa›íG|Y¾[
k‹C}û×¬IAm0èe¼ÆÈ¸Mö{ˆÉ6µ‡a—xZQYh\ı9 $PÒÊ§ğÓ»‡½ÙÈÓ«JŠÉ:ÍãÛß;gÏh/‚8,ùË ä¬DLQí·ŞŒ-ó¢ `C_›Â²`–v›|Œºx%Ã$’²Óc$
ª¡q}Å@v¸èÓ&deÏÁåŠ*¡·q=hŒ:R÷ŒÑB%ªâŠ³ŸcÁ1z¿ZmQÛá°}Ÿo©øúºkÒ)DˆìSAıäèÇÜÔˆÓ@­è²4‡( ¨ë&x#Ù[†_T(¼]ôFÈeBœ•:ÍIlú›û”…`L“®ÿ7¢ÎEKÛ¸+G=e}û¿3	»f7»ıÜÔ™N»Ÿ!‘²å= ¿ì‚ÒJúŠ°Qşá6nàî¨2fh–[c(f<ï]²am‰ÿ--«µ¶hºg-¥ì›¿,gUt.‚7&Á“íË,7)P¶Ïş1àGü¨[÷ãIˆ¢Àíš-!àP§3#yD.ºYû„YWv8¯¡+ ØİãìYVòkÔ­‡gHÄZdƒí—àı/”å·›Ù–Ú2MXÕRÿ¯íWGN³$Z©@eÇb^•ßÂ’€šÑê±{“C¤­U’èI˜B`y_ß¶T‚?ú3ĞmK½Î”0bºËVÒ~\VaÉP¾Ç„¿a#éÖàR,p€~º k ïP€áÖ7¤FVÜß§®Ï±¾YqİÚ›ı¤¸S‰vî³}qtĞœ™ı¦WEòè³›«½2•À¶ñ«Äçí©ûxàõKgš§•Ö]Êø©F/ñ)à­—ŸX¾ÔÔz\2AkQëm´»%šÌ‡Z­É„0H8ÆŠAUÍfÜû?¤ƒ;xÅ	‘vÊâ–„áŠßÌ‚RÇ:Ãjá¾°q€ùİºÛ6–3m`×«};”@©‰ÜèC!“aîğ¬(Ş,­ŠªUm@ÎèToÑñ}Uê‚æ5ƒ®ƒİPİÿ‡¡9lá™¥¬Ê@]û¢T¦>°C ;³/x:Ôš—~‚«Z=;%õİ;0öŞw›|é›®Nº
~9ãÒ/ğ÷‚d`ZåNéj[›Ç›lmp)AqğZ‚.éN}ÍÂ®ÿÖ¾šlUƒ- ëRÒ!Çg =æ¾YŒÆ…Q´„Ë.Ø(gRné¡88šµH¦*öPÖÓ%_ É¡G:uĞ‘»{ğB„5Íá?U}i`ä ‡œG«.@ L¡6ex·ml»O?A^¿PùõYDA€¿ÎêŞ¸ƒÀüaîû†!ŞÃƒ^µÑrX›VQ‡jŞÒhÛOşií³ ’Tt“—å²»@^`%Ôi®´««º«ÆrØ<p¿$ÏNøS·ãoÍ¶NØöØÍŠíW´)×}N¾Ï\[4—;¦s§CùÔ»åJdgå‰ubë”„6F›9W#£	Øb‹Huo[ÿ»ÀÀXe«¥’#@v-R~·µtUÚ°‘×i	JÏƒ" æÚ»¸¹Ã$ú†¤ ”Ú5µùÓ„ÙTx´Àç(òĞ‘ù›Mw²]ÊDı#ÒQ±³ñÔéo•k‹§ÆGÚ ]!EĞ§–×T£«¤ÒÿúpY>äs÷Ã”â4Øzßóg`‚yİOÈ–—ÿ«SWã*ñÚEá>*f4Âå(lß^CUNë6[mÍÛæ¥´Õ%a®#Q`ó>Uv5­@ãB$Ğ'í§õ®ñğ+P‚´XÁyŸ	Ğ¨­¯V;n!¢7œ‘ô^Ş’³MW±”¦œÄ˜µLí ûâ*I†™Á­ïO›qk&ßzÈy‘åş·ÏIê’;ãWÔ…’R{æ7©Ø\gÛ¤T*-õ·èÆûzìÂa&“xÑ#Hí¯P/DçÍ0=Ï>úîg ú?Íµò>:î&Û¶²ä¦amãM¦Š,4œE÷È´ŸÀF‹ÉÜYp)Õ¢¤¾rˆk89“¯—d<nlé>`3²Ñ`N‰ñD{Ï*D oV	ùDsÓG¨Ô›I—¼˜ÕŸ53]>šÿT0N¿ÏJÍõzd*Säÿ“L0)ğ©br7f†2zï´€Ùiÿ¶Ò† < ê	X3A 7•ö"úáåPI.GlHP-²o4!LôJAÃ9F0¨ÎøÙ\ãÑûxü¦Ò<£nv« ü`ºÂÑI
«J+@QİDy!ãiù†ÓjiÙÛXncÄ/!Ùˆ6íjÇ—áå1×«’ZğÍùØ4GM“ˆù	nYñ¢‹·ƒ 9boIû&³í‡Scú¯¤TW«¦–Ì¢ò
$Ÿö2¢gÍ1~P?8ÿòˆˆÄjqØkİ4åö+~Ùl YRß;¼ŒYjO¨lu·#g9öä4­rÃ1ì—2Eô÷æÍˆÂæ©%Tb•£„ÿâb´_v¾(ƒlbô½ò¶íÜáƒ6ûìam^Ym¿LÇ¯©†F$f!®Nl¡OÆGA¡aV6‚ Ååò<HPq1Ûæd8TşİF“ı­óA
2SQ'‹P·a¡ËÍı¬ÇÓıÙH%#òvow±4­’Ä+Á© ïÉ=	>@õeÊ¦Rd§_‹!p5ºAŠK>–ü’|?»Ö‰ÄÏÄ
Ğ¥•Ğ#f X†äŸñA+Í‰BT*+axÇé^é˜á}‡ÜÃ!Ië.£â•Ô#İdQ›Ü=ïdaî®‘\Qj¤éy+SXØ)à©Éÿo}çˆ*tÓdæwøÌëVÕÊlöJ«²6=$/Å€XŸŒdÙú¬°5W_Ù_¸èb>ò e¿ÜnöJ+¦4ÔşÄ$¿0Î•7ÒøW-+/æB%;¢wØİ½P(òMFœö«d§³â„[”´Âæ¿'o«ç#®À_®‰Š\ş_Jğ¤S&ERèåUzU”$¡ˆA©ÜêßúÊ®§4o'‰ì6åpkƒ"ìtÇÙQ±û§¨8vÄ”/ß¼rğÏ
>«õ‚İ¥®’9×€,UF`ÅÚD%ø¡ÓM¼³q^cî²h§:¸T™.ÁPE|J¶õ_’7äB4%ú§ÃîslU^Ù~¨}&œtÙ€EıbYb•#Ä|$M‰[ÒFvT„UÕ>xGRéM‰SŒDµhÈ®*g@Lh"³²È£vÛfâgqƒ²*ÜØİÿ(%¸ Ô@‹rµ—A›Dl!ƒ'#Ş‘¨½§zGt1‡ÈÎ‘‚&úf±za“M/ …z´á»,V@wU/ËVÁ7í¸ ‡>€Ì¸]‡/øöS	c*­@¯t0pYĞòÆãNuc…ûŒ^kcœ DIGûN|ùÅ2Åò›Fª’iwñW¯9X„r#Î|­ÂS9$¶ÏKRáÏ|¾;J<æÏ™"FÀª~BŞÀŠÏîIèÈ!yó¦ºÂ¯q¯‹A7ûš¬Ï½4ã91ÏpÉ¢jµ¼–¿¡/¸£‘ÉÓ%ñ¤™Ÿû‚‹4 #Ñı[³<Şsÿ4º]­©Kù©GŠ¦'öÍP“v‡E€Ğä¸‰Ji'Ã­aşU€söìÅyXÃ•;4`]é0* ÌKTFšÙBœÊ%°ÃØ¿<x×òJ)‚³êt¬
òRŒ#FJ¼ÉætòF]À¼¨$T¥ƒ:‡µäøäÁ~HE€*p"Í$p¢ê;k½¹eÁ²ÙÇtäV›¾(9‘âô•irû,ÎÒ…ßkÒf÷æ\´D8(¼e‘»CÔ›[J{aÆ;é¿
Py=ÎòY‰.—pè“¦§ÂÊÉCáÈæº1ÑãÅYìˆô¼J.eJÅÑğ›Eñø*æ¸¬Uâ8Ø‰)ó’`ÅÉ¨ìÌ„V¡Ğ^+ı4ÒC=êHQ ³aş†×Ñgæòó‹<öLµœZÀ=tİZLoº¬<ÌàVZJ®~uÃ‹h(t^Š+X¤¤GÀXƒG2N@W‘LáDíu©œÑZš}ZĞõS ¥ñLßy@ ÇC
-l%¢ƒĞ”@"Ócğár­Ò]œã)ßnú†Œë°öHÛK¥ †Ë`ë¶«êè_‰U)³ o´„zÍ}ëñQ>å­ìhmĞ[5H+éHärôç¸¬¨42O14Æ,£?Í¾×¤hÈ’gÒ'#VO;¤F0î³)€lz}T%³C£%ô½ÄÕSmÊÎgù]ú°Ş&×û2¿’BZ¿FbMé6êÇù¥C×‹<@âÚàòp‡¢­%]ÖúŞjÍÿ$èïš:'S„”;´\í ÌFÖtÿºN ú¦qºÙ­Í­ÿÎu[·Ô°×}ƒÍæŒğ[•ƒ…ôºÒMI^MÊYc½Ü\ögàC±AªÍ/µÉ‰=İ~à {i:EG•˜VŞ¼“˜uy7?™wå«qÓC@Û0Z½ÇÀ‘—ñ¼c‹.g€Çg„ÈØ›gPùÔÍÈÊU!‘fõJ+™”¯"€<z¼¤×ü·ï±g‰ge[™VÓ>yÊ®0¢¸ò–VRh¦/KÖ’^%¹ªğTJ}cÑ±ìì¸uiÊø¨ho
bİÊ£¤hdF¢‰ofÓÑı8ˆä|û§ü9+“÷:§ÊFÀı¦ÁÎ+´9õï ¬éR°¢…}×Úœ«Ïªõ
ôÂÜ}|Ã¹»~êx<ãµäÒ³¡QçÍåìØ†~§šÈ¹÷QŒÔp¿wİnşes+csAş¾õUvç¸ßÎv4t®pÇ‡œƒ ?'«G‘×RHóÉëê{Œ(w®æÏ×£í”í{eAÛÙ°•o»DçM2±yì’öéƒbÈaÿ©QÔW-ÍtƒR«ßA-)¥th?Ë_§æñşÃwÑô—$pg^F’´h¶ƒï6à¤½ÙµdE;û"¾F³-UÙß½ù\'êK¡=¯ĞV´±ïhøm0åaÛA1#øŠn¦î¡_{Ï?MvJÆ ˜8¾uPHdÙ(Åç®˜+:¯¤ñv9¡L.Êm%ô C‘0t„õ£8ì8»ÈíjæG+,<ŠxBWÒÒuÖeN˜4Ó.`ªÆ[®ãBqâ6@šâaJ§çp³…Ìö¡¹½w˜3-*íõª£xIi½·Ê`ÖÙ-çü¢æ3x
TçÌRël‡\ú|)}=‚Ã±Íïï~Á\3îóİê´é°‹%ß‚ÃÓöé	•òÄ×C†ïR&ÇŒ#eB/ï“ÛóÚH/üÙú¤>?ì†§z)Rvµß¡©`S"j”Ş®¬©‡#‹9êÃ%÷±@©ÎRÜm(Ed¿ó	¥{¢"î£ŠRB9;€gQ!ßdG:‚ÚY·³ÙËÈÄöô7ZŒ/I#5ªæèsøÇô0h[ù`ZwrĞµ©û³Qš*7?m­;zlM>ÅH¶Êîí‘ÅCq:j§D#W›† -j\tIÕ/BÓ~ü
ÔÑb+şˆÓÜw@A€ñ|
<†ôÌ=6S J[ßsxğ7¶peLã|ˆ5f¡¬F+/{7×ZÍ6„­B•7¬ırZôW:Ïqâã'vÅuúƒŞp¨Ñ÷òÑŞÚt?/¾K,³«¥ m/7Z	5¸¬ùÓ>áònµ.7RYSè’xDÉğ?°¡áãŸj­'(ÜéB8¬õF€ÿâkH€–ZNhJô®VúıPpµ¶Díı'ÑÚ`Cm•EWox®šA˜!Ó”çJ¥äyn/ùL,=VC±Ê­/Õ’~u¢¥º—˜Z»DêovÑ ^ôDÛeØÿ€=qY&±¹5C8ÈËü•û§'°Ê×=,8íZ%IäW~›§VzònĞ0àú
¦áµ!‹kİ¼4{‚X• îi0=X{hn™ÑN.d»Ğ1zÓÅH˜VQ$ó†š6Sê×çú¦æÚ[c|’Æ–º¥_¾É3{İhõZ®¢İ$û`ÌWQ{^V1íu*’.œ/æW qµFS:vı®xz6½×¹`¤˜r\ Y{ŠÙ„h4[ƒº"dyr0s$_”.G !œÏ¸qW{pv+ÑJŠ[‹h¾Ó¬
üq9ë#L¢ûU¯Vdøt6×7x÷“Ÿ³ÀR¡¯°DÉ·Îì¯@8!v<©òıĞ¯ë?¡
çÂƒò ^‡"şçSßäöêıĞWœ>1B£ºçh†eLñJüW³²cã‘_—nKÉ03Ñt¹<e=}_~®ƒ.ûq4-+Ê}´:=ƒ2YNz¦¡yçM"÷tÃéEè‰ÿ#%’†nL>…¸Ôá\½ï¥ÄjI—÷~0ôÃ¨©8TC°„wb.ECÑÉ]¬£Ó#š`°tËÆµÉ>å~†åP“ğ?–ğ ¦îœ8úá\&Å³uP¬ mù£u1NœÛÔ‰~¢ı4ÚŞ´£ª—$WÀÁŞ@Ÿ<‰JãCuTÒu«ÈÎ£¹Íw½GÏÓ‰“A-á÷\‘Yê8@ÛÌù²”£s¦Áj×
ã¸šxAì.Ô¤ßæĞ'9IŞôfvù<Œ7?¦àq†?‹“JÍJ±dLa‹Êî•õdSo€q>{[”£¼§Ü	$é=ø–TC¬Z*yT™ÌâóÑ*EÀ»Ï‡P[\¦8+´Œ= 44™Nƒ"‹Ìka:&Åš´ŠN
ÕÚF^lï€DÅÊ¨lÛ(Û	¹1pè•¦@OÂ¹\M`:AäçaÛ9±ˆ
c×: {í!|"…ªEÖåuÄ…áq]Ğõü»Øu]ÃÓ¸RÜLè±{Ö©7X/Ô¿.×t[9Æ†EÍ¯?ÓyC–ÎuËå8=šŞï-ßÎv¯/‚2™œ‚sˆ€·!5MáSİãoxa×\³%SÒ—ß’6÷ig|P~Z`…“/Ää;§Ñ~ùÃmccBiŸš‹%¡öA Q˜)Y5cQ/k§6n¶ÜÁ©˜rÅìkÙ„Dîï‰Ğy¹Ù]ùÜ
ÎÁÂ9ªNÖ›~ÃÙºõd‚OæŒ«dpåÄ«÷ qÕnß¹òHR¼^› „¾ïcî‰¶Ì:“ZY­˜Œ%ˆëÑ—‚™›1mN•P…¢i(]
Ÿg<¦ã"v9•7e‚ª1ò„}Áw¬Jx–Ó*„G¹@A&²ÉrÊ’ oÜ­²’BÈšk¶<?DWE·Æ^ş4òğ_*é>§\®ìX•ŠÌæÖı|ß,síœ”ß³‹Hº%ÅR-!ç½%ÕDô¾Ÿ7ªb¹qñy_‘ûª,!N´9K`äËJü”¹‰8ØSµ¾2V¢yœTŠNq¤w«'lÙ½”ü†3g:á ù&J­Zææ=&Ašp› à™úœp6Å}qgE]Æ–+9ˆ«÷Ş/Šçh~i’=üöNdE-¦åxÄİ-ï¨ùşÙÏk:œ±µ7Ë¹GáK º/Ã¶°Iw³”Ë!Xiä
&hû+Z0›p•Âá`·¬ƒ¾o ´*ú
7y•+çRèšübB]°zñÆİéH^6–f¤{Oær„Ìcô†¯Ù#] ÅÓë„èLŸbŞ7ÖÎ@Èy…%` œ=¬§°²yÁSf–jÌ’ùQ–z OVŸãˆ§ß¥Ü:&Ğ3k•oü8‚üø•Z–R~Ûìˆ-´é†•2Ä/ƒıy˜x¶,9?òÒGËñi{%!Rm*ˆy£\MdºiI:-Å)îXã]Èi\¤BÊ!‘h<>èV)-Ü %Øñg¢ƒ µİõnÏx=pûjR§Ö²»­šz°ûvÖéê×Šcã’Úl~ß¾c¦Ì´&—ØtŠü“U6ïÈ¾ìr­ÆÚ¢|tÚ ÅY©¤IêŸêÖ+ş·[ÒÀ±ÛstË¹Åv;zgº¤H¹ònC^íYÀW÷ñòŠrY8—ĞÉYÁÄ:.<dçpøa¤<ƒT'ZÖ›©½ˆÖ)Q²rË•µ¡ƒYââà9”›Ô]'½`éğ‰±QÅ›Késfá•%ä4`¬"ü¤ â“Pí3Èb&aØy3W7‡9›

#r¼e
J¸œ)°ìùcbf¬€ÇÿºÃ,ş™`ÑpÙ›ÑÚFÜñH	ÎmQÜ®?Õ7[E*ˆ¥1×£Nù‰Ÿ±O17îÚØ§•:&Pì¥í®s_A:Cşo13€ê_‘×ƒ-hšJ]S>İ©Å `â›»è§i%>œy¹nÙ, L‰ßJÆâìÙ&¦+Ã¸*;3PèÕ‰]höË uøæyŞz&á§²Ş·*}az‡Ê‚h‘¯|¶¬®@şD…¢M}‚Á€¨‡éôáPoœS<HM(	tk›øoßĞ>]î…„ô1ª>	oEI­tyfÁ‘’íCSn˜Ë'ë™‡»åI‡ÅíL`³°7'¿Í,úRªAµ ‹¼û]Ù¡­PSş¶˜5DÄCjòæ	p‡.'fc"IIS°˜’ş5“Ğ5Á C[OÆ5*¶
x¿cÒ„Éç•t«Ò^M³æÁÅ¸jGU8Å5Š¾å|—›ªıü;XĞ„+á”»ÎÄ»E a²n•dÈ•İØNòQaËNo£ûö¬a@LjdŠÂÿÏÅşñ jªÎ½¥³ˆ;ëêœõ¯pùU<N_BÁº·ã7}´aÕ¾õŸcímlÖ¨t&Õß¾¿Ô\áeşÄ«»„şmtd¨=Şê€Y Ûü×s›¶_mVcrÜLf~DYüüG<nÛÔÎs<«ıÂ$×²Òş®Ï¿ÆåOU¸Şû×jÍŠè•J6Ù¥õ™tâÏøp\Æ¼Êır4|=ÌÚzß½ñ‡Wœ¬ÉLW»èÀ>ãË‹¬“§ãF³äEµCÂbÁ…ü*h€ÄxYÈ¥Ş÷˜ù‡*{ôE‘0æj]rŒïÚÿ"éï¢¥í!t†}€Ç/KÿS£¦U7±@sW{ê4Õ}IÑ@íeö§±h‘3›vÌLj¸ëPæ¯J§d½¬÷gbB*Ò÷wñïeÌÃS[‚éN#ê°¯-·•Íğ¿ˆUà²Fáº¦äi’;SÜë‘hÈñRâóÈlÀ,ì—r6Öô=Ç6]%®½.hìÂåÙ=[œs–|HI@ôGîw1#ªH-c8+p˜9Í÷à<¨¸†±»^ÜªÙ¿w¾…4ï hU”õv¼÷áÈ£ß,íô²â‡wx3¡[  MÊ/EåO=¥-Î×ŒmÏÂOşrş…Ù¯“”u2…?–æñá}SGƒè¬^š„×¦d
V1ó'â¯ÄÆ.MÌ°(A7‰j–£ºåb»>	ë¿wúeĞvÙ«ÛÃâÉá8ZQ„ı®j#@:Øé­'œ¿C¿9µhÆPuÖø„™äëI‡C”2ùÿ0]Œñø	D?…èü4¨£eÂÌÄFßÉcÆšû|&´®l—ó«zI›Al%f¯şXóUªÕŠjæk?w«„·8õF2ÎÍ;g²$ûÜ¨G0]µ»¤ƒê½Yx®òzÖŞœ[ÎÎJ…6ö^ÍÅGVœ$Î£¤G»=Ûˆ68pëáïc‚—·ëu#o’Ä	'3,B&/w?5;êçQNA9Ó‘M*pOö&ç˜*{?•ÛUñÿ"±3ğ§˜Xuw/
(¸,¼)m¿ÖÄ;Y%UĞæ{Nİ½Z‹-aï”ğ‚sËõÆ©Äîş™_–5FÆ‡fŠÍêpå{ìˆEÙXÊWë÷Åa&•,äZç©€(]½âb>ÉŒ[Ø6¬ÿôÄir?	/æö¤8¹6i˜Üƒ-%nq6Û¬­ @ß™‡Ì@ uuÙ>­ñ8‡¶Cš})Ú[sy˜£‹4'×,`¦ÌFW8šÒ›¤˜ÆJ‰|€æóPÖò]=øĞ‘A§,D¢ß
)~}e‡¶ONI¸Øæ[Ì£Y€šSRóöúnûLhÚfL.?ÜXµŞë\;ÄÉÕE^ú¹£¢í²Q¾ÓñÈÛø”š“_H¶_ãk±¥@å1¦M3®F£"TU†z`Ğ:&"Ò=*eÎÇP¯¡µ“-«±¥eÌ>øi>Àoáóë<êw„x}@QÈCjt+´#ï-¡Çfe{a‰K´À1"6ÅlPqÍ¤ë+—‹mC—R²ëìQ„¡¹©±¢Cbî£îrjÙ™©¤Ÿ/¨òï!6Ílª+b½CÉ¿Â÷ì¸±¸9â~Iƒt,½Ñœ¿{/Ò<íƒŞ·&,I²W·ädŞª‚`ï#»`.ÆÁgI&Øq\Z­/ÒBŸıY'_púbvdco¨ù>(8_ÙÆ³T,79'ø6÷¬pı·¸¦¦.áY03Ş'´·FûÅ-×i‘À÷™¶­Ô^AÏô€ƒJ9Œ¾7ÆS°Òe˜§0œ]Ó´zUl¤Zv³È=œ®8È:ö±•qÉKÈ‘íöãŒGñÖ Õã0“lˆœAóÌñko°”¾MĞê/Ä	/øìu·Am
Z¡¥arTmÉ+ß£Ã0©h£Ã<]Ö+§Rãxgª±Â	MJDqßî¾õ‰×%½~Èø Ï
ÙZst(]ân­‹’åq,âìáµª$¦ñì[ÂïÊµl[ƒ>A‰Ëº?LÊ!Ä¬ñ†YÍñMíqWÜ, Äç¹WÄÆ–4(öô‚6>ÈªµT{w›âŠ
mHedöÙúÛòPĞ;yÈìK±3g_+\4Ç}Ë‘ñdÃçz‹ JçáÕ+ÚYU½:1jØÜˆ,+…2_Å¼àwF4Ö‹˜ür\×>x},ŞÓıF›òK<¡ĞD÷0â¿àOViH«yËÆ^[7ì}¢Œ
tÉq/=¸Ç2ã©îŠxª_u=}o7ZÌ"°9—{cíÆ%?5Û3’¿,ÓË(9kôu@[g"¤ l4š]çé¦‘2‰N¡SqïÖúr¯Ë³_}’ÔíZø‰Ñ^¿y:…aß…dtWÜGTcxWœ³:6¾ĞËÇ¯Üó¡"Hvó“{Ÿœ¿0ó~ËD¡» ‹æÆiz7d ‘ê {ñ‘Eª ğ/×mÔlù-ñ6¨ÜÂDIÖŞNı¾Üaë(K1"¥á8–øË³Ÿ´È<DÌPÉMÿ{ºY¢¬ÄV»´=Í
y®9n» ŠÎ]ÕÌ[›?îsÏrSm·j·dÌˆ¤ŸzÊ
rõ>uÍ&™ÀÊ¥ÕR)„Û•2„Ïvº:,‹1êôÔît=8ıuRè£4®œ"‘Ì; ¼3íŸ#İq“¢çâÎ„Ò˜ò~ë›”FÀ_Ã ß‹ó,SBÊŒÁ­.0R;½”-pŞFØz»eé'Ë'<“‰Pù]ÍÔdÛÂAàŒÑNKÁ'eÜÉ>–}y¥ó³Vaì¶×W­¤¢sÚu!D”ñâ¼flo–ú•†Ş×7ŞÀ¯ÕıÚ‹yØ¿]] §µI ™ˆK¤•×‘’õöfm¬ş7uÍŞ¸£|S§©n íÚ¶ :¤¿OèV6I
ÃÆ€#dnú£¨–y¿€+I=#o+†»6óçÊ=mvn–ü,8W„!(¼’“§ĞãOëØFÀSÛ–ÇæÍÄŸŞInÓf·jµ[  O¶y¹T?zÇ¿l¡©îÑ1ÌYó{Â¿Ps×œ¯¿ÔÌc?M#JJŒiofa3QEs’èÙÉŠ%g²<b£ğ ©WTë¦§Ws×N¬ÒŞeeöÔ¶‹kIïò£®5ÒœgÇ°†RöfÀöûL ãJäÁ"*—•ê%ÿQ±-½5/#¡? é0I„öG"@ãQz?	|olC(}æ6®tUZŒ]nã)Ø-€×ÜiB ãú‘r60ûO XË©¥ä)<A.àšÕÕ'éIP[ãwB7"ıO¹ÏIbKŠ›(fM'T,t âõı=ŠlÎÙÕ…òBïG µ)“ü¡è²»ø£F2¿­3,J:8gôµïw¨)¦ÂÒ@NtlY¹§æË(?İìS%(BÉ`P¶U2s›‘ˆ}­î1°c7]ÑáêüÿÔ×ÕÏlI¡‘ÜdE–c`i+A9ÙÔ¢'Kwjÿ¸Øç „Û¾ªİQIu­zN3%y"¢ğ™¯Ôí´     A‚¸ä×ñ• …¸€Àk,ˆ¡±Ägû    YZ