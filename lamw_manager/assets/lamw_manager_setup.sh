#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3790902363"
MD5="40a03c6c264d023ea09d291ab59d694c"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20820"
keep="y"
nooverwrite="n"
quiet="n"

print_cmd_arg=""
if type printf > /dev/null; then
    print_cmd="printf"
elif test -x /usr/ucb/echo; then
    print_cmd="/usr/ucb/echo"
else
    print_cmd="echo"
fi

unset CDPATH

MS_Printf()
{
    $print_cmd $print_cmd_arg "$1"
}

MS_PrintLicense()
{
  if test x"$licensetxt" != x; then
    echo "$licensetxt"
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
}

MS_diskspace()
{
	(
	if test -d /usr/xpg4/bin; then
		PATH=/usr/xpg4/bin:$PATH
	fi
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
${helpheader}Makeself version 2.3.0
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
  --noexec              Do not run embedded script
  --keep                Do not erase target directory after running
			the embedded script
  --noprogress          Do not show the progress during the decompression
  --nox11               Do not spawn an xterm
  --nochown             Do not give the extracted files to the current user
  --target dir          Extract directly to a target directory
                        directory path can be either absolute or relative
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

    if test x"$quiet" = xn; then
		MS_Printf "Verifying archive integrity..."
    fi
    offset=`head -n 526 "$1" | wc -c | tr -d " "`
    verb=$2
    i=1
    for s in $filesizes
    do
		crc=`echo $CRCsum | cut -d" " -f$i`
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
		tar $1vf - 2>&1 || { echo Extraction failed. > /dev/tty; kill -15 $$; }
    else

		tar $1f - 2>&1 || { echo Extraction failed. > /dev/tty; kill -15 $$; }
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
    --info)
	echo Identification: "$label"
	echo Target directory: "$targetdir"
	echo Uncompressed size: 160 KB
	echo Compression: xz
	echo Date of packaging: Thu Aug  6 19:19:13 -03 2020
	echo Built with Makeself version 2.3.0 on 
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
	echo OLDSKIP=527
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
	offset=`head -n 526 "$0" | wc -c | tr -d " "`
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | eval "xz -d" | UnTAR t
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
	--tar)
	offset=`head -n 526 "$0" | wc -c | tr -d " "`
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
	targetdir=${2:-.}
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
    tmpdir=$TMPROOT/makeself.$RANDOM.`date +"%y%m%d%H%M%S"`.$$
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
    mkdir $dashp $tmpdir || {
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
offset=`head -n 526 "$0" | wc -c | tr -d " "`

if test x"$verbose" = xy; then
	MS_Printf "About to extract 160 KB in $tmpdir ... Proceed ? [Y/n] "
	read yn
	if test x"$yn" = xn; then
		eval $finish; exit 1
	fi
fi

if test x"$quiet" = xn; then
	MS_Printf "Uncompressing $label"
fi
res=3
if test x"$keep" = xn; then
    trap 'echo Signal caught, cleaning up >&2; cd $TMPROOT; /bin/rm -rf $tmpdir; eval $finish; exit 15' 1 2 3 15
fi

leftspace=`MS_diskspace $tmpdir`
if test -n "$leftspace"; then
    if test "$leftspace" -lt 160; then
        echo
        echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (160 KB)" >&2
        if test x"$keep" = xn; then
            echo "Consider setting TMPDIR to a directory with more free space."
        fi
        eval $finish; exit 1
    fi
fi

for s in $filesizes
do
    if MS_dd_Progress "$0" $offset $s | eval "xz -d" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
		if test x"$ownership" = xy; then
			(PATH=/usr/xpg4/bin:$PATH; cd "$tmpdir"; chown -R `id -u` .;  chgrp -R `id -g` .)
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
    cd $TMPROOT
    /bin/rm -rf $tmpdir
fi
eval $finish; exit $res
ı7zXZ  æÖ´F !   ÏXÌáÿQ] ¼}•ÀJFœÄÿ.»á_k £ÖÜ“¯OıcW˜œÁ‡ŞB H5ƒdJ%È"¿&Sëw	r1œ{ğ9ûè²Ó&=GEïŒ4â¬ôÊK±°¸,¸t˜gÊŒşÓN‰`&15ÆÔ$6ìU´9\Ğ¢hpzQxqîŠ3Sô*Ó¢øë<SßÀ$¥"TÍS!6êVCkÃC¼x$Ìh/6Æú0×ÔÍ°Ç”Ù2ÚÌŒ<ğVßÆè^³;Rßğ<¨ÊìÄÒÏÔ…$E™¾£ oøÿös’u_+QĞ14]?s*ó©%%Bœ³q#¬úĞcˆAÒ›Zz9Œ2*ÏÉôûÈì5w\ƒå |"`”x«ı*Ó¤Í¹ˆÙX ¤«Qÿ¿dßf:›ªÀ[^\
µ:kÒ“AšDX¢Ê@³¸µ0òZ».§²ƒK^‹CçsÀ‡2½…Fö§NAO$ˆú9”Š÷méüsˆşÙ
şMñ§?4¨<‰OÎn®»Ü‰‚ômï4dÔG«ì»jûá_`Bãªé@sa£òhY€*ó!±ÙÂ{–º
g^-WÈoÇ	4OÄ|‚h¥8
•J¼O&§xÚZ¦–>¾áOäà:Z]}Š,Î5C’‹#WNAüÑÂñ®áYÔãJáG­Î„nøŸD8Øív,Ù:¡†â`VtJ[Ísºo- ú<??¦ßÄi-ÆJì?î¬Tj³d³mİ›Yr¾2ğU„\ÚÅïß
»· ¾Ü¬¤%ªòÃó°{ùÌ«˜WŒB²¡Iœ'=-êÚ#ŠªiJ”íNs[G¦Ìğâ«Ê`DƒÚõì›‰Ã¶òã?oŒY¼FİÛ‰ôE×‡ùÔo‡½“KˆÿJñâóñnĞXRŠWö9òõ&¥!ÏUYWZ:ªyPíÈ6gEpUõ	ì W•1ØûÿK8>Lß•ÌIåÀ+T4—«¬L%ìè5æx—µ7S›Ï‚SwÛ¯Tª‹“Š¿´¶À ÿÂ
gş¥«~{Â]ÈíHörÇ%8„aM›±ÈJè
*Îr¯Pˆ«+*xmËvú²³@¡:ì›å?J¼‚T*†W
@ò(‡Ÿ ÕÕ¶)şgá±Ÿ©I‚Bğ<¦Gù72Ãóò¡üÓÍ•ÇÓ í©´(ú¾ˆ†­uø`€¿a€¦:Ğo"P‹×CZH4œÎŞTŒ!Ù§åº4çR\î÷4¸ë­,ª¶ärnàşß³œ¶JÀCÉ¡ÔıWÓƒ‡I¹ÑóRjİtz/Q¿B×D°Ñ†6?ŸÎ¡:î1Ç·è0½^ã‹«°–ùHì¯—«n¡sB%®OœûÙ—WfóÄ¶G3Õ¿Ú”.Y
lÆ«&¤4ƒeµÉCfa—!ô‘â>ºÃµ5-R«V1¥¬hª?ó‚?ĞÖîo×…Òø•=<'>Oë.hÒ©t¸‡¸7# rsb}¿“M%E¼ÛÙï,t¼Oá&*í‰ÁœÁ§‰–ŞÍ(ş%œ§3¦_ h(Ÿ­%®Ò
GØË(×œXÍvhıÔîd‰pè9úT t¢õ%}Ù8ƒ?ƒÇÎétGeÆgªãLoğ
Ògú’©~M”ı0ğ^ŒE˜ä µF}Î©?/$³Úô}êû·òº:İâÀÖîUº;¯`¬ürÕÂš8,‚Wˆ&BîãgDÜõÀ‰Ì},QSÓ´ùˆ-TÌã‘¡ŒãÓNJåvâUZ*«¦ò±Ç¾’¼YşàÄba8YqfÈ—¦dÇÂÄÜújµ‹(¾|Pe~JF¿æÕ¸º<«vŞ)º®±Š_Å™ÛÓ÷zÙ?=šŠ eî,¹ŠŸ˜µÎ-Áï˜A
ıq•0f!Ô¬Ìxq[xAÈ:—Ì¶Có(—‚ùÛ€¡'h~¿Óå4ê—0ê‘¦oV+ì;î$°*¬Ñ'‚*âãdæ}¢ a1ÛˆŠ˜p533î”UƒV/ş2(-œvQQ××,ğ’­FÜ³I	»ŞÔé†*ÎT<=ÔåÑNÉ›O÷!,Æ6ó@ÿÎÖI-©	ØÀîÚ¯ù´
@pª5
6˜MHö/ôïİ}Óò¶V~ª‡¬`,ƒNBß3B§ª%o¸ iMÅ´y8CÌP|F6‘ïMı^vw¡š_¡\+Ú
x_Àµ,œ$˜)±j@Ï›†|_ıæKLB?Ï‚ê•Q‘¥ºIìâEBŸëã$ë³»¶‰£!éÀÕ—8–;8ò òóªonBş"¢Ìãêã©J-ó=¹Ô ¤RŠs¸(èp vc³uN
f³‚êRÂº-c`œfÿ­½+n›;#¦©3bJl9&õ_ÅL]Í•ü’©€ƒ±HŸ@äj¸w§ß>»Ç÷€–‹F—Ãõ•1Ñ­ÕPë	İÊ£cj–ötJYÏt9Ï „u ˜e6¿^OËÁdAB6Êİ–Œ¼C~ÓûÔslöúZ§¹¯_ğ¶É‘«~s¥ ƒë|£(Ø×ÏGÚ!0	”$$Wr?iÖEŞ|V¡º·Äã|W§ù\ é7f­¢ÙeÏO>oeáp¨J dÖ¹¨fŞ7–¥š¯ËzÎ¡déœì@’}«¿[„÷×‘5c³&ËM`l¼ã~KÇÕ2aˆB;%eŠky£kƒÇùõDİCêELË]ƒ§Uk‹Ãé7lææ¯nşDxUˆWøv´ôŞÏ°ú‰{$MÁoˆ°³3Ö†UV‚‰ælgèæ+Š~ëBÙÂÃ®ÂÚOôR¸"ÛJGr´bBUÅhIÊåˆ•?@ªzÍøY%JÒiğ/yºJDm&ÏGƒÈ#u–Ğ—KuŒ¸Ş£¸?§ÈŒ+$#Î7`VĞE”H1…¡(’ğx¥½%: 'ØlRE_o²µÉ¤7Kôu}ÍK&ÒH›
Å^XÚxÈ’=%F²2j#§dBêŒ‰4´¿CÚ}>ÛéÏá£&'×¡ØáŠiëÓPt(Rl‰Á´úª‘È\ÆÉš…•î”°˜ğ¨'é¡ThÏX¸O‘Us[èBñn¨Q¡mu…nëå^üå˜<fòûÂ‘»ß}	ÓºªÙ?lÜVûÜO§MF‚ô–Â|X¯C+0ó<Íæó5ôlvçlm]ú2s¿° º—2³Äœ6Ï~LËîòVjø)&8éå'ù™^§Ç'FBdˆ÷nÙşà®¹´ªÙ9RS¯31 !–Å
 ³_ç<¹É‹Ñ^ğÔ­)È¹¿‘8ÿ»DÖÍO[…Æ½–µ”öŠö&Îš”Ç	˜úµ7@`ÜŒ°8¢nDŠ í¯†ÆËu&=‰\íÓFª—Ï(Eg±õµŒŸR†ÊÃ¾.Š™‰&• A^Tb»°¯ævşVŒ®nÒíöÒ¶‡iÌHSîYíy¯Jœ¦R¬+hz9'ë¯Fbí}w¼Z³¹E£IêãëğºM´u©TZí¼	
íö"0öŒºD†A ùn³GÌ›,Ÿy|ˆš]:ù Àş;wÇUKûûÙÜŞ‚Ûãuõ#¨RğñY.íúõ^;Y­Şæo2‚9´ò½—º^¥"kîKTáDoU2“9_ÎƒÙ;„ä¯ÌîÍ¡ÌV¤%¾ÉìÖ}$”½ÀÊG®©„CÉ\-¦ğªEû†ß­1äfšVâç–Ò¸4où-,±ÍOû’uÒ–U¹qPÕ™Hõd»µ1oØÃvÓ¿LÖ¹×h_ş·˜Bâ£sóÉ›Ù`µ}¬åïòq-‘…’=Ê ‚¤à%CÍP¥KÛJÖÔ_®0ì†wâOA91³êÔ'@‘É¶RÚ"='‘—(šZJığ[Û™¸;8EWzuHÓ<Ñï¦ó°ÎztÚk³`PcP"÷c<ı¦Ä…/ò#$ºßç(!~°6´HÆDhÓJüRı³è}	ræD:vıjúº,¡Ã<‹+q!0ù¿Rá=ïŠÔ¯UqÃ|8ß.jÅL¹"„KÉ¼¾âW]¢›ŞdŒéÉÆë¯qnŒš—xar  ®w°.
Ş­!Æ(Íàê¬Bí«vŠ_B¥±Vczõ9µÉRTA€"*ááÚ¶—˜%Ñel¬Maªí$oÅ^³ÒİF|ƒèƒI^H0ÏâÀëÖhÔ¢¨MËwvC0¸¶) ‡˜s‡:ÇÛaúèàÙìU ‘Õ®ÜÇ˜Lb?}R8¤	Ê¥qC–¿©’”ÇéÃ¨Ï;–Ftù!ÚÄ–¤QiíëV;ó5âÔ—Fœ3F1ŠLf7”€¢Â{®Š'%ñ¦@À¿'d„7 fZvÌ¿¡ûòÙã¦?Gİ1l¶fšĞ)ğÂÖ¸šXt0½ ­˜å'ÀÙàFJ˜ˆ£Tƒz‘@2/3=ÙŠ£­îò÷<Ou5 #ñu8‹Õ³!ÿ1vÅmúw‚x„X%ªØh­ƒä²m\÷lÔ›’-zFÿ.j•øÃN'MK=Í-GÂZué¼ÛÂe·ÿY(İú­³Gºëöƒz´¦Ùø†“ çªÖvîÛ}¨KV.Æ3±~½%³+w¶=X)àî$éHãô6=¬w×æÁëJñ–®÷yÁÑ“t}fz*S¼õÈ“Éj¡@—éz½
m_˜¸€^òX¡bã#_ªêIJ7šÃ(G=+	ÒCá"=í6Æù¤åj<ø­êw§ÃmRãŸo¥Îï<ŞÛ—•†å vş]—Khºê,KN1ÈÌ¡‹¸cñæAn-ƒâL¦»Øööÿéf€]%/1]^èÒ^Ô>Ø›`øµH°ş˜pøÇî¥bà*ÁÇ¾SùÖ¡6õëëIˆÎğÉÿ*ƒÒ{0póÇ.H|N×GK›üy!›y#Ùÿîv©ÍTß¾grÊd$¢ûÉoĞµBOl7`Lïsºƒëzˆ_¡ÁtííQ:‡ 
GHÈ‡ÇËPwkjÅ" oîÄá¾?|wÓšxÉIôƒ?c:*†Ì¨]bTİR¹[ Ò«ƒ]EZ÷ËwR1lT~'©e˜Ç©œŠÆÊ'D\ê,Öóê´®?m59%#ó´hoÁğK:ˆ‰‰4p!A…F	î¤x€˜ç ÉÍL–u-€EpàbéÏ½é»‘[$=c	e}·]ìjg¾+‡…„ÏùB®áê„
ætZ¿(“ÁOGeöEi`<l÷æĞV	Uµ{rni/1W.Ë¯B4FŒF$-Ø[¥•Â¾ÒeOÒÉN2cl8Fµô©EâåÒİ¿	öY|±óTÿPˆçf™<Kïeü–1GÑ¢ÇnÚ…'ï'4<ƒ²@ë_±‹2ÿIşùŠvgãÚX¿½<“•Ù•ÀÛfÁ„bŠŸ¹…*è‘%£ë4ŒF ù>çó>\™ˆõ¡‡ªd¾İşõ±;Á¡ë[*´ÆÁ'Ö¹~ñ?PÛez“5øy†h¦ÛŸ¤y5a^:/Ë!ÆáH,íçÃqŠÄ@ŠÊò¶ªèbÍŠ»%ó›kŞÖ±ôµ§ûÁ¨ÎxòËåá"XR™ ³ˆ™‡¡‡X¥NjÚ]è'ÕN™àóÒTU”6%Õ Ù]Zs²Y"2¡Y‹Àfà!xO·«Â@Ó™î´< {R]¦ÈŸ2v¯³µ¯Æ¸ş
¶œÓØç\Q†°d<_ñN'‹eø½ŠY„bšÙæå_»¨prH…iSıPe€2Â2Nz	§–‚´ò?ß ›& “€àI7İŞª·,ÉtŠô:Îqs“ò¿ûô_ŒŸRŞdŒ)ã¡Dm!ÿc÷0X"ã,îÊxénƒªwŸ¸¤úÜâ5«û¹eA<ïZÆ®9;ìbKa~'ì7şz9œ
h¿[#0ÄKFÃ£AßˆÊ'e]ßß½ºoìŒÇ Q¹óBmÓc<RœX„tG"‰wñ Ç$X¡Íã%o,<
İÜ|á¶ãAò4°-ìŒâGc<º*DBïÊi9ÍÆjcøiÂüqæÚg•c²8z®#•Œˆ;1h÷z¿©	Nó$e®ÈF).8şù8ĞÎQÌ_‡$hâÖÿ}73µLQTv×ê¨iĞ¼îĞcŒ2
lÀI‹œ¦½S®¼¤fã³29A%B\Âß¹ù‰}4)–IZC­ñËû¾ÙúI'R+¾R[.`|ÁG  âßãz¢	Á—Ç¤r¥¢n…€åƒLóe ²,Ü¬²{’Ãg\=Z³ı>vp`:™¼ˆMëƒQ.r,d|E‡àNÂÎY\È‡ÿó¥ÖPN³'ƒÙ¨¢š.AW‹úõ%wÖw —V?hYAgt"3·İ/¼wFõÁˆ«hçÂƒüOÓ‡*úÌ¢Mw[CöÑ²¡KĞsŒc‡˜ìS.ºZúïôº»÷±Ù;–+QÜz†ü=ä$Li•ªÎB÷ÌŠ¡Eí„¨şö¾4[w[ sŠµ¼’^ô	É¬»dò7¢E'—®[_'ğ) d!B­PªÒ%ÁdFXí¯ªñÌŠÈ‹ûS…©ÀkŒ÷~æP¡L¿ı¿:»ÖI—]~Œè©¿ıàd|6“1¬'ù*µ3‹•P÷ n}zÓ
MğZèü#ÿã¬7ş;ÎÚ2NH¦×ş3„e6"`ùëúÜáQÇ^2Æ Òê"‹ÒöÒ2q|€
"XKt9àd\›"¸:FÒz x†şI8^p=Ù¾¤ã¼f÷<ÿkê°I«¥–}T9@SÈYöÅa§D!Ö«äÙrÅW××öŸ¯ç]¢±ıú&£ãÔÔÜŞÓ}7İÑø²¨ÍÄ¾“HãMÊÁÄ¥6ÕµÀS2-!N+2}á¥QÛBËjDD.v½¦*óîûØ“Àuád|Qgÿ—Âá©™†I9õuA^è|ô3|2ërä€HkŠÔ9y¯[‹re¡I<«Ã5	küauû½vÜ§ŠJTŒúÆ{G‚tŒÂ«rÄt[ÏçÀ„ƒr—»ä:µS9c	²Å	™ïô²Ö)bµmß;NÊ?´¾æ¤ØD!©—MÈ~r0¥İú¦¤VOßd Íá/)Ş¾Óªå½å;ØMzÀğ¬•t”nãÏ>èìÑ|xØüÖ©¼ÃNàUQ(?ÄæÚÏQë—›4¤ ›;À—Ã¯k©¤OˆÅáUÍ)ıfbİIE“a¢ş†íÕ'ï¤%˜9÷É_ıÆZq™bmÁÍ	ĞUí(‰YhRm¤¥8á&™\%Ô¯¥åÀ_FuÃÌÍ£;ÓqQ}
Q!n¤R]“ßƒJnşæşMnèöÊ}Ñ*Ç×B–`áu÷è…¯áC•šÿ:Šòl»¸çvç—¢Áy›A¹bOC§×ŠŞ”8æÂÅÏ.rª
®¨ëøÀÅ§¬‹\|äšŠ²Lnşe´ŠDòcŞ?ıQFLî]=Ş¼5ÌK}Es@åh¶‚\k†Ëî@F€Ñ}<3ü……½p¾´õ–©;Ä!@8ÃõíA/YlêŒ·õ]s·ß ›HšÇ“ÑÅxÓ7.iòÔ¥?Œ.òğ0JWZ3ujñÈ€{Æ$ß÷HQŒ‰°GQ•J£–usK°­Ò(Ã}¾®j’5›³\Põø Ú”¼Î@øJLe¿ˆAœ‹7ÆÎ1Ÿ—Xô”‡<Ã±)œhîx%Zçª?¾ã–f‡,ıê½«’kĞÆúT
9>$ër ø…â˜š {Ê·:jêğ¿¡;,„Íà%ÿU
a`1‹ ÅOGnãI¡XÛ®ÁœmjÕ.ú¥óó¥ ÛÕè1ÓÀ5Dg(Pâ¯8{XÏ¹íĞOwÀÓ)‰ã~‘äåõúW‹~	şÏ‹#b»Ä~µ‹È6KÁ7…±	xv?©DÓ¯ƒybé¶ŠGj{£Ùr™ØÑbi‡Ÿ‘m‹3NYÑL›Ø‰şª÷¾&Ô9ˆ€XkE#wŞÿÌ@@½ZP1â–‚vÍô§ìÎã1şù»jOªZ‚ƒ¯¨Î6k£Ş5˜æ—¢#§øÂ^~V”Á¹B¨y£:7İX_9Eüß:”æÍô/ÑJõô³F‹Ù¹J¼’â •uš$;s¤1ŞcT$ñqæ¸¶æ­fP˜SØCÈšw&Œ'„k KYÒ˜ÉÅ.…dT<kuÓÜrŸ¬É?A&˜€Á¬ üT€õˆïØ[ÓË‚VP€3ÿxyü‚,z·ßEèïˆC÷›30ïñá4uî‹L¾ĞDe©™i(Ùx@Â­äÕ, ‚á"sgËcİå @Ã‚™ù¦Ò¥Í£b@íe„µ•¼õú#[5™¹8¤\uJ]éPÚ¡¯éÈkK¦HŞ<4`|à_éŸÁLFÆ•Î÷VjååFÿ„¯õÅ°UŞ¶¼÷™Ú-'W5ƒå\è˜ÏšƒÊn<zW™¡è\ÿC±Læd›5„ˆ«öô
íUï½îïÈ€k§¤Cùæä¸bµÍ]Í"‹WË•Š»õÚ…·RÑéˆKİ'¤¹i#%Ò|¾Ö¢Æ©Ã¶kºÛº1hÈÔrÓá¨O²«Ÿ¯ùã3‹°*èRéLÅ8[«'9&>³ÂÜ›4-%f"”¸ú@Ÿú•¬X´Qs†é_?AÙ¨Fµkœ«ÁÇë˜
’ùÊ.QœÈG‹öG©Ù·CƒrNGCQvÆX’İ]F˜1â@pæ÷½ş™àÒE^:>ØÿçÓQnÜNZ6–}%Ùú2{Òu¦õ9æ »{ÎhÍÉ¬†‘Ë­mÚà@şîtœí,b°(œ`Ÿ±uóºÌ¬/ìJ½?E—Ø(´ëN ¿ãF±æŞyx†c{iºz‘Œãb?œºÓJãmLù‰‚®[…]›{«Ğó›‰s°{İ-İi:w_®‡’häïÿÕ_Åe±Ä‰‹I–°ÒÄ÷­´ÈÆß);¿8ÎAßÓ®~í»¾A±É[eÌİl/p‘&†)Ÿ>	høëß0Ú`8'q¾> 3Ò¼µï%|~ƒ)²™
S¯Ïi^‚îä¤J¹u	!Åã[RÔE<|Ê¶3h}RéJ½7Ì–ghòXP“+Z÷‹…M#ö6´—V­QD=ìù^¡y<±™–’Õ¬n‡]˜Ä9“&Ÿ(?1¶‹ı†Äz‡%Î>¦õ‘³àÛ©“Ò[ÜUO›AÒ#ÓdÛåÆªËM>hg)Àã0ôBÔ"#Æ>5PòäÕí '„a<¨NQCÁ˜¹¦:O›Ë-=Ê/! Öºªê–ù¥-79cŸíøÌÌÅà’x‰ş ÓñqÔÖBjQ”¯„UN†&ÿ“Èj~ş'?š¶%e ‹ËFEÌ~›,wşv×7¶†Ghì£_ˆtï²aeì£M¸ˆçi±$gOÛÔhâtv³oÑÇ\¨ê»)#–¿ƒıõ#Ôo9GÎI†á(8o#ä:]y68ƒ=©šq`Û)#Õ»(’‡m=uĞ‘áüíµ…mAÅáÈ10oIOåˆ½ıcF¨4ùÌÕÃ¹BÓöY²c×9úã¤bÜÉó<—ójé‘¿|Êû6“–ßÆOß51y¬\6½kßØ>ä_{j¼æÖß¦’šBÕ;3_­HçuyÒhœy~Î"éŞ¿è’¸œã“‰¬‚bn© ¡-ğĞMŸƒ†ƒs¢¬wâ†‘!ëpÛ+KiºÉœÔ°-,¬:7ISG}KGÒ·ºmxã˜ºIa†öFx	ç÷À0’9’Á€\n€s×ŸH«ƒ\ğÊ?âŸB††üôõ&í˜(0.º<S¨á²ö¡s6Í[]mˆ	‰za– ÏËôKTÈtÏrg
Ú9Xîg¸îº¸WÉ‹¿Õt¿şjÍHò5ÕZFğGLÆPNÍğ%Ş±fâú–”Ø¬LÊ%–RèÚ#LC‘TAplèâpiÅÛ"‡–ĞÏylBßŞ!£u?<Nè‰®®ˆQÕV¥FsÌuÒE®³.Y±"hŒ”):x>õl)SØô3PzM‡+V4uÇär,÷¼ÂtDŠm]j€N«´şxœyi,n”Ì5µX&™9›É ªè§w²-ì»Ìh?k¨8Æ×@KíÔU«k‚ú=RPc3§XY±µ#’-ç) %,=­w¸Jl~bŒ³³Õˆ`FŒE{T»\†Ï
ÏÈ>ì=FÏ+*ƒ2c˜³ßV|¢‡æ²èÊÆ†F¾½åõØäƒ¡rQÆ…—'€´Ø¯ÒRC¤£–AUZTl›š•š…ànæpR™+ç²…ádkò«â–znöÒ6œ9@{¼ÓÂŠ¦’¿
Ğp:€“\ı¨…hÒ’ŠŒXW§nù³é1Ÿ¢²>ëõcPš(û®
í-„Gû´òºÃ²^íAı’ñÚd”`Ö<-ì3\iİ|÷ÑOL™ŸÀ’||É*ˆü;G-ïeEŸ;T“ÌšíŞX¢[_B¦é”!º*1ZWTíCPÒ–hOêÅÜ¬Ìc¢e¦Î¸L‡ÓŞ±k‹SÃÆ¹âí÷>)3‘¼|~:»øSmˆœı±—Üßğ!¾èPûÙË¡¯Á9EøëTÄE ğ˜Õ<¾·x…VùYB¯èO£øŒ	ê7'”s›J[*æÈyã÷Ë´¢ê~ïR!E/Õ¥Tv!»}gÿİvEó¶{ÿ $r–¢f“›tq£ÂbßáŞ¥Ü°2Ë»KB«i&YÏ‘©é"êµ«¦yå=ór15Sµ0ÔÃšenö4iê:RQÀqÖà†qBw›­òó²ü9VjÜ;l€×yÌc,O›rÙûîÀGIÀ°ÎóŸ«Y½‹ÃÉòì†oÄüç¬kû¡Ş›X÷ÿ´½ÅÒğü@9›{+´€“ÕÏ4Ú8wğ)TQEÜ;‡ko³i½J5ÏâÊ†/Àğ>U]ÜŞöªÏ&táÌsUì³écÆÈŒì‚'‡Œ
x2ê;Òæn?¢ìwlI@:D•İÍSš¿•7>¿®[äk¸˜çí3ÏÀt©X[K1Á‹ZK¦yejl° ¶œ„ølöâœµQ×ä>ì£êƒ;)#fÍ1vv–Jzp¡óª#3Ğˆ‰$z×–Ûõçh•¥ŒV¸ºa4ì>šçÎY<•B•xH@€Jğ~µÉW?Š¶©và<_#õácøµ¨O÷·såg,3j3Üw•ô~ñƒ¾qI}Bm/¹uåÑ”q©R+Íèà“#m‡çês@&{,×ZŸ$Zó4«GR!#be_¢ÜıJxôAÏå˜AõeWĞ'Š€¹HVÕ×Nr$éÑ‡šîŠµû´q@¿í´y4!Â!Û€=¨sÅ„s½“,~sú²RK)‰{gÉšâñ_ss@ı&o#=Ï¶>^¯àPõùr®~¿Öå W=·Ü³¶J2t~H+d7.Ğíø_¯éƒ«Å²	s¹¤9,ô”Ö"·S`LÙÂÕ­±{o!X~ZNg¡h«õHdí2:pò½öK–È€Ë¤šËDëîÆyPôñRÅÛá0:­³Ä"j#»¬dÿA6ÜuV†£é¤Ÿ`ÿo·İ„Å'q(50-fYXÌPİAîÜlvüø¸U9¶½.Z ñ‰b'õë£“2¦Ç.ö3|¦6¡C[éìTSˆ]¸a‡òª¼•ÅÒ °3¶;é3ELa·‰©ïIó Ëš4tGN{§ÁKÉ)!ÄîFN€H$éĞï‚¦¸X'İ8t5ÁÿËÄV,Wøï“OÛp¥]‡Lz ;DZ=¤ËŸ„Ì¢Z\5ĞÉÛ$à¾Å"$ô¹vÛÚJËÙx&æRè2Vòjpáaæ¢n,wı‚{–%F…nÅ–âRp3Õ²CR–"«4ßì–ƒPBæßÍBYÙ¡È]6VGÕ¿…<VYÆã96ä,Ê0W‘us&
An;“0ôSQ¾öİïğğG!r…BJ†´¨¥ı§³^ è]¢l„Ë§;iÕ×Ê;Z•WYÜåæğhuJ¤¾aÃÌ~-;#Ó´Ü‹eNXm†~R{'×Åg¶jH4kXÇRò“r¿ŸØ¥X~_IŠ™á:¬»GÕ(eË;JDJ'5±Më×£VC»DûM<uğô>—i||º9GlF#‘ü
Üó]ÓĞ¦öU!¶]cµĞ\6ìõDMa©ÏzÊ÷˜w`ğR{ó†QĞ‘¶ß%?\üõFM¦éçzĞOaÇ’Y5»be§Ll‰[}üÅ´£úéÛ
•aW¶@¯Ï™#š€¸cÄÉ¶u£ÂS*'œÈ«ş¶ÔÅœù[;ÏJÆ„iz‚)Çƒ¨%NJ¬pBá1ŠVêµñ`Q78{èãn·Ì[8P¤,Ä±§ B Ì©ı‹w²Î¾èÛ@×‹cğy\o†ûS·„«Ÿ ùe~ıÀIIpb/UÜFCrsä†Ì£„ú‹EK¹¿Â…QÌ°Ğœ>€T¶/T²ŞJè:¥Ûè@T„ùBäbÉ<9B—6äŸ‘4ï€®…€’]5òÛ¿äb}Û³"ÎÊ±pfDØƒ"¹#)N¨°D`}É0¨5]g4H6Í]†à~’¥Ü#aŞJƒ˜ì ‚´U€‹2lXØÕıÈï1^ÒoºÑâË¨·ùnƒÿ‚yéG§¶À‚¶Œç›ğêƒøm<Ã‘ØÉ¯$^Xp„ØŞ="nVŞ•!.}§~³¼n1ùJ¿€‰ªZÚ©_ªnB¡Ö_çEğç×$ŞÛYÅ“ğøjÿÌĞòk…›±èõ( ÙÓwjÎktÕ¾³'œC,“ÕÈ¿(4n´/—á
¹1ãC‡Š^šêgú«pª{\³»UDí,0T|»PæÁ·2CøDf‰Ûz0ú¶Eà^;õ¨{×/ágöş79U*línç€ö‰zØ©_VrëÜ}œ¡i CmÅpeĞ§ï5ê[ğH¼ÒLİ’Fc	”…,±«U©Àp`\’ûëYõÿ¸Ò1ƒ?N	`œúã¬NhÜò‚ˆŸBîè,€´\<¼¬´–®K+FÃ‡"Öù¾2ÊñÇŸAœ˜²+v+K¿ ß†ÜíÚÂ°
Šõøôƒy‹)ÄdË¥Q™· ºJ¦Tt+üüCMb<U’Áµ–§NÉ9¤İ§™Â>kD_q#ÕZ!:!æzÉ°ùö}8 ûp]»%FyğÄ•uJÓy¥æÉœ®÷mí8U¾}†4—TIóóx¶ıUv«ıA+m	:»¯:£%øĞ€ÓéKkPWá÷¥v8?‹oPFëkTŞ)­¶_Ù\e·Û2EXP[e^XJá«Zå4œİŸ7‘ÕêFÄMNH	Xıÿ6×¢÷³B%¥â®&ùYÎ•&‹3lê€ÛfÉ$ÿh½"ëxì)»!.¬7’êÁÚ÷ÚşÓS£ÀE—ÓöñwãMî¿*@²)Á:Z¼é.ôÚM.#d•¯®¿
ı£È¹T€z¯)£m-`Fñ!=áœ›³>=_ƒuÅf<sÌ^‚¡í+c{Xì"€bºl Uª)ú.±a=Y`®ˆ¢÷jF­Ä4¿İª¿AƒNŸóu—½¤
å½8Ÿ]Ë%ÖÀtXİÇ¬Çz~Ó¹ùÍ*Kq&ZŸ©wÃıà”‡‚¨†·ôõ¶¯Ë;SOrîÅ³Ïê@ÕïY'Ğ\‚L›ŞaúãET$Ùàè„V‚á#piò•L-1áĞäîõø1“‚®a,ºK¡ì*\±¬ÄW†ğ°ËRCs-ïxcæöŞiÆEpí©G±aÅ*ƒ³Nheeü²‘î/šú‰V„.­ôıİo`O¦«\Õ<àïS_ÚŠd4ñ/Úã-F’™7ôüÜújß¦r<×nÆäÊ¬Ÿkœp?3@âŞ‚¢›¹Ñ$À{mçï"(Æ¬Ò„ÕşÆàĞ{à™;şïÚŠ`Å Ìôf)<¢FßÓ¿ïøçéÑ¥›˜#><­€;ÖÜq ‰Ö{™o4Â__«ä>ŠÆ‘È†+Áà´ º\>~¥ık•ÉôÒJğ`éí)ºSE£Ï
¯PóÁİDEÒÒşl S\ó„¢^$…?İ.İj®S¤^›¡AŒÓ~³.î¼9&v­Q)ôÜ#´*†-ÅQ° şxªOÂ³éÒæ–<„o	¿+Ü|f5‚8)’6Ğ‰_BH¨Í‚
~$–BWÑ‘×)ç¬:õC¼í[ş–¾EæIµñ¡Wunw{1*,ìø?J«£yØr»åíxçÈ‚¸„ ¥h+8ë÷H)4”³ç·ô³½ªzê Œø;ŒvŠz³Áoà"4ÚX®“_iÛ sş]¡«¾ôñ~³mƒ¼C¹Œìc4ëCÔ:}•¼!Øµš\L¢˜8RÑø+Á#¡Ã¨dÖúóğŸ¢Ñ<Yÿdˆ"ß»b¶T‚íqò‹s–¦§XŸy­ÙWH=ï'°åG1­Œ™»>³ëÏğ1ë²†úúauF~YJFÂ·›í!¨¸+
“—ÓŒÆ«;§Ñ¦#CgÅ¶¬}Wd¡î/Q6 ŠAıŒ±waæ½À¤sûhšı{÷|¹ªÄG´…j\‚GÓŞâüas*Š\“køö54!€OØYãDQuh´Æ&«@õíĞ2
F™)++¿½İ‚“ÃB§_µTÀmçpƒÖ7<g;B,¼£$S¬ÈïSKmãpÉ„XÛ‰ÂÙçnë¬ =ÊAd@,¿w$¡8^p61KòlÕpMñ9»Ù¦ãÙ¢6ÙvÚL²Àíp³ÕtfüÎÙk©ºYöÕÄ”-RÆæªÌOrqE¼ƒˆ|<›ÎvŸ×ÿÿÜÇ'AiïÙ·’&À!îA–5dçå2d(¯$Ñhwç©›ùÌÇÈÖºkæîz[³ÓÆWÖö;èeÇ¼¼iC/ƒšÍ.ã¢.¤bQÍø´ÈËãšºk¸¿©dîMd…)ÒÌÓãQh‘q¼ÊÁoS0~DBh:¨QÃìøF_
ÂyFMtœ‹8¸¾kñ¢æ›"ÖÇoê÷&+Â²|é*‘#Ví°ÆÓ™ N)—Œ„ïmv|EÆ×\Á¢)'UÄÖç·A©ÈŸp_{+í’ÿÿ1&{
4„MRÑH¡ÊdÆWMeÅ­0ü¼ÄcŒù\7©®ÒÃ@È&K™¡ë1âLkïºµ2ëJ\ ‚‚Å_[ä™q¬HÖQz­@¹åı9Œzßñ´A^fSÿÿnì‡ŒôÆbœ«Mfçäo¤S>Æƒ2"¢ {ß\)Uº/jĞz™Zö‹İÍkNó0('õ½À¸PÌZ¿D…ƒªÄÖy;eu‹ïôUßp8©U¨<†OŒ ÆX”rõ:ĞNíàN Ó¼^ĞŒ<G*F3 ÅÛÄß =|ªåv¶ñ×lEFé©KE ]=Š_¹gtıfm5	è1£q=l>î½6â£³Ï
=)\{ç2à`ô®ş£&^â®Md¾òÂ$ôo+ÊmíJZ”­eeÕpDå 7õ¥!NÃ1^ª0c€àÈ¹l›ºMRÏÚ½­!zhàÙÆ
;C•vÓÂ”:Å›7è™n"N#Qi×Ãài[ÒüŒ<¯.¡‡BfwxEÀ”“Q‘aNk—Nc´Yú `wmsO¿ôöùö
õ®?Ë¥3%dÙZa§Â×QÓ]nôãX\½_øfÕF¥î
¤äŸÉæ	ØŒ1ãD">½Ş^Ä¹ç¹Ö¦–Æ‚!=¡jT5ƒu>QğJÂk±ñ²7ÁlRŞ32HŞ?Öß…Ãôæ úêàõ¸cã4±íÌ˜®¸m•
ÀÉÆ·ù¼»¨ı/¡O·ê8€	±ß—ZÚv‹º<\™¹nL%ÄLçî>:P•…nW1Î’Tä"®nèP[¢õ%ßóƒ“Áª[o^<°
Î3í6¬šğ‰oÊ×FïŞõU¥rym´Û¹˜$à$FãŒ»`ùèX‡¨w^åŸ“‡Ñ]|S»÷Çìux=˜<W$÷İ:&n2«0cÎ¥ot~xézcÑeŞâáÀwt¡Ã8ÜÏl?×±·O¢/İbH•M‹AİšÍ5{o5!‰ìb<™Ä=C.ı† B¼‰Í*ûu_“ÔAájé8ïy}¹4Lª`am ğébİ.5ÎxWNÔ¦j{0m1ûn‡œ
a/~\74]0âq*ÅÒä'rÇÖØĞ¯öùHWF(ã­†¦i¦ì½à5ğ`ä(¨Ô¬PpF¸?p³^@;rßXÌã§õsÏÛıÃé6E¾Ê¸<°Ÿ“oÍè±ÿıƒ ó'ê
@1ïLÁÔTŒã¸ Ç“Wş’<Üx+–X¥#$/¯Ê«ºB1æ¦Åæ™ô"‚ï½´ş!v±Oê¶wqA8ÅÊ8ìeÌt7­n’`š¬Î†‡"èÿâÏÀ¹ú”¿”ä´ìŸ&}Õw. ;¢|5œ´OJ_³®“·ó}%\âÄÇ³¤Øß§0–Ö,IÊ®¡CÔ{­/Ô±ÑÙ:Éq¸lb1M>ŒêË0lqŒÌØ4YÆš„FšÇñK­º/Jñâ¸ØNİßáqì@…îèN2³€?!‚aÛA)l×.Y/ªäşÂw ~Èî#İ	ã½qnÁˆ’‹nü6|=;€8<~ÿé’	à ¦Ô"€fÚĞD¼|Ìj¶+á—Â·}Äh­Fqn¾l‰u`µØãĞä ‚‹7¿ïˆ¯ãWiœ‰Uµ!‡³gÉZ ¬½_£kpï€åÖê]uì4^/—óhß³ëS”%ÌíÆãú©`©¸ï>hÚrYÃ@Ş—‰×…½¯Úmum¥Ò9ÿÁ¨ƒúzgÄ|Vd»RLÈñä¢ ‚QTkÚF€!gıFAn<ôÆ›ğş†˜UXEĞx«_5ï8“ªZµmAíuÇS–û†§WÍ0û¾Ik|Në"¹“»ÃX5EiˆŠ;ŠöşHÉ¥0ˆÔjta£O\pë"qPO^¥mBùFUÔéb2Àü]Êëyˆ®{ÿÿ™ìr¡Œ(¢¡ã|ëî2oƒÜ’¿¯Å….şï©¹ ½=sá¬Õš§
".Ÿ¶To;´¸Äöú7R ÁêåùwÜ²‡Bí"gıÿJóã.Ï)åüËŠlW³U„æL­¼Ù’¡ÔAÙù‰kÂÕİç›:qÀšâSz¬–NµN^|¢àÂ;ÙJp¹€r˜këAoÁm·¼4¢ù¼ß/À6?	z!}…+S„iv;kÉ$W~3Y[IA"UH-ãëlZ3«ñ"mÖÛÒÁğlrk!GÀß½<ì“[•O´ACvÌÈíËMˆ›¾]t»,lÈzCV­¾-ïP ¢xSæ©Ó×ˆoö‚ìï<´(KÃÀ)vs…^1%Mcpa¥-SO˜}«İÑ6ä}|ã¨¡Ì¿[Z'h,‰~ŸkÖ8ƒ«•^iÇ“mÎòìeÓ‡7¸R0—£ñú§-éXj–oÄJ·dÖ:á×¤a$½Èƒ/çvS–y{êw²ëµ•BÕT©äŒ‹Aş
í—·Ñ¡‚¼o£`{…˜“¢‚g }š¹ÕkV§D‡z
štÙ(|æ¾C±îR7š@”ñ¬ş:DQe«pú>×ØYÉSÎLàâÙ‘œ•†ŠÀ-
ıå›pÓà(ä.âÂ¯!SË~ó]ì-õµvj—W©h…]ØU˜ÊŒbĞŠW7gÃa˜ì¾ñIUá«}şÙÅP‡ƒÍRä*OÀ“J:ÿ“ÍüwÄmRow{ s(mÏnÍìd³cöµxûÒ"ä»/<5}»[Êål‘EC7q2µÒğå
†ŞoÑ4p·6=ºôœ_£†¯w2òavĞÃ°ÒşÏ·rzÆåï'3–d}¾— Õ„-§8{0ÉLzĞiÁi0Ù„Õ!çvù0Ğı–‹»Ó¦é5˜ÊØ 6m)ÿîìúU(n«.ƒz,@Èti•snPÔ¤])İÊ°	hâÇ›æ:(‘™¿ZÉ‹:w
¯ËBq¸V…Ãàäûİfh5A‹bşˆ	î“Ø–bfjmÚnìöÏI_Ûl„ğ5ÈçK‹(º>ŸIµÅ,Öu/Oí¨™ºÌÄÊ3˜ÿ¹èãòŒô`^¦šÎîhğ_ö%6ê6xn	%B¦—!`™a;u^ÿñÒé”ın!mq¿ÊALh)nÕ¯àœKûøŸaò…*"B0¤á’EÕ1x¢T;»è<Øp>y–ùµßT{ş…-è£1±ğ8JFgqrP½°ól8(A*º(œOäjPË2®_ybp¾+$”X~½£éeíµ2C¸^
6â8ôÄ G8\í…Ûu­+R	®Ÿ¾–fğùÃM·ç=´•):Œ$ëV¾Õ–Å\ÇŞ;Mç‚>òƒoËIL.µÏYĞ\ğZAò§éÊËã”ÍÌĞ`ÙBZ¢l"íQ)Ğ\¹?·úpe¾Cé.§¬Š!ˆUèÜ L7ICÂÊ*M§\ùşa«§SvD‹ëÀÜ?FÀÉöïá¤%@+:rr²Ÿ@Š¨ì‰sPòÁöË¥µŠJŞ@OóëëÀ	IÀŠãó
)é¡¿Ü´oÏıdØí·››J›BÂ=¥oÅ­jŠL.Ú‚ ˜t×9-Ã¤»*ŸÎĞÌçò{èÆ~ÏrÉ( –û1óÓÁasdà €’\çÉŞí&N ˆwıhƒÒ„¡â!m1^[]®úı6$Ê•ƒ…g…T–co>-äEĞ¢®œ!6Ùq‰½ò_¥¦%?”Á—ğÿ×x$ÈZ”üpúÜó‹N,$nsøØ=µéwwy`M™A¨(Ec–âÁúh¢_ÛXr¹ ¹˜'ÃaåMU,W}•Š´u»|9Ëİ=ß’•Z%,8áõ‡™B¸–nÖQr¢èç$õü ¸8“uP­ıÀşÍ€ĞÃğ/› |â~ëˆJ¢ ^Eã¼º¥ëê¦`É*rÓ’çS Ì&q,1‰ã	“vbš&_;{Ÿ`ñ óæªW¤ÌV6|Æ¶çu!Ñ,j/ø—Ãğ²Bh‘™€~\jhß.ĞY*Ÿo éÓ*ÿU;:5§±ÛÙİÉÒ—Ü]ˆêGZ,ÁÒS‰mvyÌøb:4r·cÊ[
|ş2aH‘¢TA ½_h¬>‡7ÚiÉ‹‹mºiÒ]ô:[1	?/ t÷Ö2Z^ˆ¥}I J=§…½`È¡ÉçXB8Æ´e4]KÄ×ñùÏ“êêÒ° aà"~;í³Pù&u
G!{¶Vgæ]—€aAM³^8Êü•¬Êñ“¶5Ù5Íï3çß³&,†œbLL€ÁbğãÙ›œÎ9`Ê‚ÉZÓ›'½“&è%á­^ptÎæfÉò¤fÖ6õRS¦QE%EV.. E¸–18í¾$ÁßÄÜœâ$Æÿ¦…³Ö„N%ó?ã²»öJVÀHÌfj‘Œô“ïfs‡k >ÍôğAŸw1»¤°»šŸêHõÖŸPÏÿhëeR½àqÀ½*âAäËŞ—¥àwVqv¥^óbØÇ «zSh’L­RN%h×7Úü;Ü0tĞÆ		V‘æè¡|oÁ´˜"œrÀ‹ÉÀl'Ÿ)BÓ_Zä cŠ{¬’Î³{‘o_I¡ú„ÁAäW IîXÇUO?Õ
ê—¹î…ÀÏ$'zÌI¹	"Í°šãöÄšGíŞmÿ²»2hšrÔÕÑlĞ+ÎÒŒ4wAáüg*±_qUÅ ´¢Œ,ä‰1–CÂU ß€`
7: ú†ËfuûS©3ÿ³C×‡$	ËSªcípSyıŠ1ÊQv¤FôÎg©ZÃÿü<çw‡„FV)JÌÑºÕF%§€ÙŒH;Dk,¨›?|ZöÜÀ¸P:•½²'¨=å’Ô|‹":¢ÆÚ¶»Ôà‹\*'l6ŠÆ}× \ ›ˆ“@”úe²¦8Xo‰Ó…mğw3ÜWP-À5Åu8	ñò›L-…t*+i("ÅŒ<™7ÒRQÓµHÕEGD84o‡^ˆÕdßâz¸Æ01ğÁ7È*¿0Š"úH2ÈAŒB.ãçÏĞ¹Fó.+rœÁ8L;ÌZĞÄ6¼])nDSÇà—i>èì#£|À¡qNŒûKjç^EÆuây™ç˜kÚ]CvR„VÀÆÊyşáî<}â‘˜…2;"òÔ€T„áÈ`–…Ã|{¡\mÉÛªİ‚ç! ç}ù=ë2æ$)Õm¥h HKKà/l¦:í]MdeEÖ¤7ÊÙnPf„µÜi5	Œh„pAÓáÃ%îéãùºİO0ÅØÌQ;Go¼ûíÃ,¹—İÜ¿¢`%c‚¯Wmú6.Æuşe”l´‡,ÃÍ9tÆ¼-ÌfrRp+!n\âª¤Q}6Àğ7œvT[ëyYE%¤“´“†ò#røêºÓ-w½È¥ÉDøÓ/Q(¢ƒ¾@ÙS,p^İÒ#ô±§YŠŸÍJ¯å 3‹ƒ“
DODï»|=æ5i
PÃ™émÇŞ;8Ü^™&U{‚7
’¿:Êè'ı’©°@ÉËmJà1 ¾Å	O´ñŞÍI.›Aänñc3BèRØYE‡DßùZE“?i!<Âœ)ç|0Nß{òná#óÀ¦©=:®Ó"»ÛP£|=Åo¨Ò,Ÿ[î/BL3cUñNÑš¥ëÁá¼Ê”İêÌ‘ãº=úÕıŠ(tÙKÓ—ø^ã†ÇŒb®Ğ‚¡—ßLE\±·;÷HçmÂ¯ò }º¢“@Ù¥± ÙB7ˆÎ Ñqç­Mñ×ÑÕx/E+Çÿ¼‘rˆ¡Fí<Ÿı©>Œlò%ûël¤â[Ša»ª_lÅqö›õ«.I¹x8ÑŞõPzİrS-| İ¾ú]O«µ½#¿éë œwÙ_ï–Ÿ¤LLé©àY‚(§¹X™¡ƒ}ZE·¹Â…©ùÖIfèÛWc6Âc^ÍÿaW$2¿…hIxÒøŞ[ôGÜ´^¯Ts“²8ıx§À™ İ Íf$Ï¡“9Ê¹³&ÀúÍÜÄ‰Èú]—Ùüuä+¨ïÎ†ŸxhN„ 8JÆ{SÖr¸Æ4g·eiK±Ä+°J)Ÿ"uë¬ªGgö.Hƒ˜•ŒÔ,ä7ÃîÀIş@J3>-È,~tÙù3"ÏŞGIPnÖ>‹”é¶vİ7à\{ADÉ*F†zúĞ³t†ı:µSCÏvìWŞSı¦sPç6dİ¶<Öïá¼îİ ïmŞ-Ñ³¯„-‹¿(İ4'~¦È.Ñ€¤
 úº6Ô™£{Sş±-³ÃF¿Ï£º?Ü¹ŸÑ»áÇq4¬©xó\óÉbxi­AÜ©Ë3%í²±ûÀò±PµqH“v^@Ù½ik»çJ×‰7òµ¬¶”sùü¨êì?‰%–´Î+˜¦›ßDÕvÜ m9âú“.ÃşÅP XùE5"İtÈUD]Pl.ŞYYîSøÈÈğ”XeVìH$3)SŒ¶°o(¢·ü6¦õîªf¡2jI(á@:ÍœfêÕëş
ÍoÖò¢,î	<ùš‡¹ÿÍşÿÆ.`ÎŸ°á£Ú‚D·j˜=İ¨y…ÜŞ™h Hõ¹v±«Ï„à‰^;.Ğ#z4zo09x‚öJøØZ_¯Ÿ‹¨£Y,ú&q•ÇQiC´ÿâ|“À¹f.ş’o'>>Ñt´¡ññ÷i­€‡Ó¨¯)ºˆµÜïÔ-¦°ÈÊ@fhÈ±ØbÕ vkC­ «>ı>çì§g¨'"Zæ$Ô>î/Ì—kÖG³‹Îd÷Ã”ñhşn¹…,ÿ¦û8ùiÅòZ>®±‚ÃÈ0øyIås>co3jö8ìt ¹®ò:÷ú&²ÈbZTø‚@CM¶„q ëfi›[gÛîà‰d¿ŒÅ,ªq‘µ¶(%¸‘² ½!×!4&:£°}¦õë=+Ê4µ7ÒŒ–§Á3¼ÙCŠôp&€‚Ÿ¨ex0Ú°¾Ï—¾z±oŠŠ#Œ†SÍ5Öq&qig“=Ê½ˆGâå¦¦LŞ-–Õ×å-Å¸­$ıVj
˜d wfjf£—µhŒ˜CÖëé’ÎÃbïHñT‹_Ò–,\u“v\ge…ôV2ğ°ŒğÊÀôş‰N¶ŒêsFwu©Ã%Ë©?E‡¯“õœ°@ÜØ Pã2tÒÑwŞû¸l+aH±WS€loò‹ÀƒÉ§9½ú@¶v]Æêä+®Û¯ks‹‡ÆUÃ«£Zaá‹áÈµiÕât´L3yŠÌÜá­ÅHuªH~1-ûºz–¹P®6m Y†³_—èC4ËCÔw\›şDGÒ«ÿ¹>î•BçÓßëÛ~ÅæÍ¨´´mæàAÆ‹EºvRâv¨tØÁ´ßm‚ŠúhZrø	I¿ÌJ?¼¸]õ6”Ø·§
cgeÑå»¼YR>‡•»ùèv§µ±M†$ØDƒ­?²6â]á•}Ó~ÄSI“>ukd¯5”~:ˆ‡¢0Ã¼ê^Ü?ù!¶y
m.TÄeÄ—:«5Øy”ü[É"† ¶Pºİ]¹.›¦¨„bšÜG<¢¾2^fpíZeL!*ÁñÃ}É”WKq[dN2‡l§­Òï³^2r‘¦jKú?ì{“³¾5ÔËQ›~‰+ƒš©üdğ'‰;'û’+ofÖ£Zñ0÷½*<f­~c²j¦á6GBÏ»ìÅôæÔÊåúÅf;c¡G,2.œÈyxMò(•>*XØûm©AÉÛõµä³ÎÊ7ĞÂÀŒí/[3ı”k:‘Î€¥ós÷{iÆo„Nÿi;ªüá.ä‘°›%şêÏ¥åâ¸¦çuº}Ÿ@Ôfè0#g%BÔ}o¢|kA’Q0ÿš©ÄV¸â BâS6¹ŸB:pz.¼³ä‘y»í]T¨Éïê†Şúß¸J9¼{Ò&:Ü+:¤.ÁÇ Ù |³!QW&—6æâ^‰+Gíÿ JímEA!8s¬w‘±
Ìa  §U}°-_[×LEMËå‹‹ËÏG©ænQ™ÔháIìoï[#*©“_]‡Çî¯2‘Í—(¹Ê MZ»¨U;‘ïUlÙNçd÷Mß 'å½>UºW2MV ­Ç©§˜U)Á8> 'àJ´'O³Ş.\E×Å&jÏˆN_¼cğ»Ú¼5G¦ün-êWééÂß-0K9ÆE‘sRV½	Æe­p£…“k•ˆšË.Ëı~ÀÙÑîÂzÂ£“äk½—ß…#3‹ò„5º‹òZl¬ûÕ_‚?T¹Ú’5‰çÍPÔ\Ö[ŠÃøÈÙDÈªÌ+è¼ÒËÆ*/tZ«1ÇsóL?yÛv«ó ñ–Œ	
(/å2%ßŠLŒæ
 °XGl¨9"·Iz'£@a´‰ IB.0‚îËä¨Ú#±Tmß2ô£Ë¹»Æpš¡œ;önv³(­òOŠÿ/ä%9yì„µ‡‘ûşİ3â>BÏWdœcí§Ã[¦Ì«õ­™€ÒñşBt{+³¨ş6\¡ÀDôüHê+ş/©¢) 6xE‚mzt8-¡ïÜõÍ;…7aÙ©ä„›½ş$@++„Ùßy’"×Á¼q“B$Éb6¨+‘·îuÌH™p^9Æ±Búù—±@õ}yVºãoŒµ…Æ•9pe„¹ÍE‹
ÉS/¬|7/“wb÷ ¿s¸(Ë¬k×E«éÛ#‡kI’ı[½7²!)ª¾¿%ü.œØ¼Ài˜>ë*GV˜ĞµËJµò–"ÉyBfR%êÖ4Xè©½iŒºu™®‚LRã¬(^Å¨“Ù:0b©ÌÉ8spÅ‚cÍaD¼æó@¬‘}“+!¸[uíªïŒµ½šgØ³#¨Â†„;Eú¨»<+ÀFt”¨>†e°Ñö`=½Â=6Áo1@y£].v8¯n¬Ê™©Š”ÅzIÁt&ñLÆë§%˜]×uìÃ:ÓÉE@:k}™YHkÈ½U“ØË~’êDˆ“<«+İYlÍ‹İæßÒ—DÚ¿ÃÖÊt¡“›G 0¿¥¡Ëbù+i³Âæ©NÎò\ îí	ª-fìQ`‹´¸a±Š·J¯}'Kyìk¼Lù ÆğšÖ4¨@õ`×	âJ	ËU­öıï´{ş!æ	<Â² Ş£Û#Hæk¼IXgf©œğ™Ü¦¹ØÉ™¤úd»‘ñª”·ş@÷Ì?ñK²îìïåAßĞî,H”"’ÙÄñ§\ §F›èI³èa/-í «iÜ”5fÀ$(ÿLRVµÊÃbtÈÈê¤®œÜf;Ÿã£VIãÈ¢Y*õ!(€ş”}tóZ\¡Ìµ¾ÒÚ‚¥8¢EŠøkê7oA)scÌü÷ÖŸÙñ‡*q·¬ §&Æ±úè8¬ŠoºÉèTvh|Z»åì¯cË¦¬¸è²q3çô9ÊÖ¶+mMàDLÚ¸'n§ë¯´m_² €Ï"ì15tÕ­ı™hj|§}qÏeÆvÎp[0¦B€¦f¤Îj¡»ï›ú;Z|¿eöÆïÈœ+\×ˆÂ$»Èˆ3´WÇ‰E™=cë¶Åûl)pë:eØú¯ÜaŒ\‡:VÜÃ£·9÷5q‡Œ­8Gj–|~9q(Hi¦l_İG]mO$½˜¸…CÓÅò°Sï1q¢´ˆø3Ü|g»EÌÙ¼HıhbÅªÚÂ]Xıƒ<4§Øë”r*÷}9'—¨°!i—ÛÓd9²²ºûj•mşîôL!‘Ùme·_˜ïÜH;ˆa¯ÄÚ_çÈlZïûL
A3ZÈs+¥µnAY¬U,SLğ?k!P>ÍÃØ”ÁaÂB›?†ò±ñBI›1¨ñkœƒ¡ÀaŸİää“J7¸¾ğ†8ÿ‹«ã9œ9ŠÙˆg2u4«¹ÓÛ—ìu%¢b0ı¹§/ä”ìøî›ÜµeÇ—ÙR˜¼P†d£wDRùäåoCızbµ4¥ıatnéÎªœ]¯†Õ•€?‘ UEæ™”‚+ó#ÊdWë¶¾€ë—Tğ’Sä­Â‚…YÈS’ûV­5G˜Áœª·açC¦`‰ ›ë÷´°xÇ%os úûÿBz”&KÄŞ—È®ª[}Äh$*ÁyÆÁ¬~x?]eÓu Ü—pÇ‹tée+^P¯¯&.XÍ–9õ£Õùøç†6ÏÍš”*\@)¬!€ÎÍ7ÇGæâ‰§Q ø¡îÎ¶Õ›(RíËÏ+#GÇŒ|’¸ó.}q²¤nÚn0rõD¼JÄŠ;“ äÄ:m0nœrè}íßfá</ÔêÑtBê<ƒúk.Ü,–Dü|¤æÍR§”täTÊ—È¨³PvèæLÊ¯Só9‚ğ¯|è­y(|´4ä¯ZxwY‚ (¶i¡¹2J>˜ãFfCJûŞW¯®WäUË˜cvcÉ	eÎ!òµaÒW@mé®+~Œ[üå™NƒÖ´ÎUÍèß*ZÅ|ƒç¡4ZPæ¢hCÏJPÈŸ›(¶È¡QhÈı*çVÚ¶]Âğñá‚µ}êÓ ›ÙÎYº|Â/úáw¶ÕbF’&eªMRŸ°;9ªæ0º·şC²ó ¯ŒrÕMlT¤æ¹§/GãÏ±nêĞ¹o|G£ÏtnÀ1Õ•‘`Ãş(àìÛÛúè¶Ïüó7f¬†î?™,~è^=¢œøĞNƒŸØë]Zù²Z=şˆé)’Zo™Xop.·®'„IXaÚ½¿vÍ2GÎ£€5$Å: `9éd¹(À¿HùûH0Ftag[ÕH¢%íÄbğŞj4½ip€hÃıNÿbğIkĞs~óıØ@Ç{áî¨_W˜Î4Qå²¡	˜~½@â”XŠ_àÄvw1#½âw‹âƒ–8¤„xÛª‰n‚Œ*f/yÚëvvËº$‹wv["£K9ùbÃ"¸ŞãƒGy"®aØ¤`mm¼ŒqôÓ¶
í›%1ÕŠ®yQ‘.¥‡¤£˜IßOòì‰%¸O5äR_]G…ãv‰AìŞ¼·X"/Óú·EŞ—ô¢¤™ó5ª–K£˜±I™p\Dƒæ“42ëıf¯AÏÆ»¹—4Úô†‚ôâÛ”Ts÷‚Zºì-A™èNõo#d‚ë; ÷% JR¡ªcÇ{ e	vŸE—+
§0fr‚* 7f"×ë¶ÎAò`¯ã|rdÓgóšwg(Ãp—MZ¡‚|›Ö@mí„fÙKï’qjÈÄ´&Hc/¿ÀNqFTAò1k7]ÿM[^Ï‡BtF:ó¦	ç¨+ùÅ±Ù´‘«xÏuóYö}iî‚`Ùk¿
dz!04Ä“†q‘K¼È|fbÎŸËÙ'oªPõ$gàÙ9oãräÌ»/Ó&y{.	ı3^øÆöfÿ(oùôs¨ZÔ*JWkeÉušƒ}˜šÛTv8û%(ØÎB.ßšu¢ŒŞ©¬VrpÙ°/)
VÌc7ÀèAA±ŞÚÙúw‹‰§YªxI)ZÕ:Ja=:É<Âºc	óIÆ,f˜îó9È7ÎÚj¨Š%v5†‹‰ÚªZ]ôY(sàÿN1)Ü©9lò©§K·Ï‘©S†cñòîwV,I&‡ı¿Á'³¥K"µ"ÍÈ¸ë¥vËÚX»eİzí0Ş±ÄpÁãøÙŸƒ_Ç"ßH¹ÅøŞå•ïó#— G(\¾ïšLÍ>–âíŠš²\kƒXqÜÆUìenœ4˜ìØø4Ğfç#sëË®2zÕ­›Ë?Ÿ)vP,
l‡Ã×Fó)„Íi	âewo(R5Q-/çÉqç,f§ÄnÂ£Œ6êÅ_âa™;É–}ÙÒJs¾,›·5Bù¿Y	?0™ˆL“„¯äˆ	òfbÕ‹HYÔ÷òÇğ(    €Mu½d… ­¢€ "İr±Ägû    YZ