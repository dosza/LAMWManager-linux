#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3592227226"
MD5="f906758c00c7a6abe06807e7576d2712"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20464"
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
	echo Uncompressed size: 156 KB
	echo Compression: xz
	echo Date of packaging: Thu Jul 16 14:53:37 -03 2020
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
	echo OLDUSIZE=156
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
	MS_Printf "About to extract 156 KB in $tmpdir ... Proceed ? [Y/n] "
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
    if test "$leftspace" -lt 156; then
        echo
        echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (156 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáÿO°] ¼}•ÀJFœÄÿ.»á_jçÊj´«{5Ó‡7"ÈbÇX!–n/“+eBÁ•ŸşjĞ˜¯µ{€ÅE"ı´¢%cÕ‹«­hÄdíatŸ¸…è•ê³œP›v¾ö™» CW
QÊ3BWÓ_IFÜ-Ó±°	Ò_.‰UŞ`Ògİ+kûb3tÉJ.4ºQ5´×±1é¬›İw¯ò„~İeólimL<4)­jy'çâªêEİy’r8}?æÅk¸`>½†¸ä|ŞÚ0èûm¦§Ûä3B@ÑÚä.;c0aÆCÎ$ø“}ÎzïSgË¤}9›@ŒºgŞE€í.ŞT¢SÁ›‹ç	<<çÊx[Z´¡\EWT_77?DêÜš5)£zEì2ä)©æƒ¬ «	#öúŸ…}UŠİge¼>HÕ7:Ğ«7ÃR´+—ÔKé¸ªĞGÇ”Úƒ?7‹{¨
‰hğûxeĞn¸F!„£¬Fa<Ñ{”²¶ô¹ ¯Nêû°ªMDwZ‘ãÁ~4ªé)‡NÎ/§B0‰Æq	³‚&K‘2pâÎvYBu”}@Ñ}¿¶SĞòúÖ^úüÊ¤ãÄ @¯—ê3®_Æ²ó|ğ§[ì»o ¾_odò	YÌsèÆŞ¬X* gÛ(ÿN5•*Û±âP‘’v'íª=º÷jÇ |>½É³è+ÛïÙbÌ)À¿Lx±š¡¹!ò8q> µó.™2nG:
ıÎ4"ÚèÚ×tœlœ>1mæ“±E<sç!/Ó²šPøs¤xÉ#›ÙŸú~jàÎ6ÂÄÜLEúŸÖ?ù„8­úø]6ôyâ©åáÿE©)5€z.åøJ÷„S®„ªŒ‰ıJBs{Ét”÷T4,†"ƒÄ]½=£şQÜÖ
W‹]+¶¶Çs~‚‰0v3@Ã]Èzø¶M´•1™e›„Šà$õNµ|·LD?¨GÛzJìŒ.â©áUoâ–º›>)K‰İ<tşk«™°ñ°x›éYáÖ¸,Ö†ä¦I5Êİ–½4E_òy§&†•wC•[hˆè•ÒË+ìĞ›…A^¼•µt¬aMÃï-={Zw¸«ÉğwnV5¤³ğˆ»ÌSöO˜Úé¿UÌ¢ÂWôY ´Š¸_,Gw ‚…EèvÌRşv%6§°kĞ‚¬h?³Äõ.äjTéª²Š¼CµWNu€M¼¸ÆÑÄ—éáN5£J¡Q¿&ŒÊú š’iÏk/xª&¹pÈ2úö±àKz‰Z2ÿ ıò8¶í°Î¬Ï ¦ÌßD“H/ïãUô`ÔLï	SÂ;£aùn˜W.]ò¦h’#)\ˆ_/1M…¶0f“Õ uñÓßİ: ˆ€ø#9>ÇDœ‰§|…¢P{ÜÛë™úz`aàË¹öëÃø@ş2×AÀ]rÀË<f4¦0ü{Ó‹ì†¢äÑF¼’ ©ğxF‚Aõ.§ˆŒ¦•AÓ|ùİùC¥!Jşx»7å?Œ·”,=BwuR§ƒ+>ùÊ:Æó—V%2zÀË©y=?,?)n;’¬½Á”
“Â|}Ğ;¾f¡OA«[õæÆŞ22ğ$ƒ|Bh|&a?åÄ$rœYbõ‚ZïØ5òğ(oäZ¯aR_Ìï>êîø9½†"€µ¼uŞÿÃùPtğ¬‰Â=µ\ÍM]‡[‰npÄhw”ÂOøDb?qÀHÂ0]#K—“,ÖÅ%Äj«Õ¹—ªEßÙe?€æxyUc‰M© |xÜ—ûlá¡9İmÿ"Sì=‹g{Ër‰_A—U›ö?3Hš>u³JDÇà<€0ÄëŒ´r¶d†@òu?IRr3„Ø‹—ÒF¡6úA3®Ñ¸¨¬nìP³Ü+eL¡ !DÍ–{»µX¥|ım‹øğšZ&«“ª/€äF¶*À—R‘ˆj_R…fú>]lş¶Ş¢Ö,÷ày)!P÷>ÌùO5„fVÜI¥?²ºY·¼}#ÂXå-voæ@z;b³5+İøKÕ¯ÕøÄ(Á—İƒË"êgÇƒz¿®Ó9’4Úh%¡ÃEpLÄ=Mp½ï@.
QL–÷Nw¦†uâ¡OVDx£æœš¨„ãõ(•a®sØ‹bç–¦‹á{•7l•v+ïÈó®õ´_ ×………d¦·WèIŠUIF^P…­
% ?¦Ã¯Õ÷ÂĞéæL†@ï©&£±ò§&W‰ë^Y²ŞØT]ª3¹˜e{*˜ªj[Õ„õ|ÍfÆUHbËÕÜ:œ¥9Ø°NÓ|5ÿ†•Ä±Ï"x…Ò[õßóŞYëF=z>[Ilç­#¸Gp.µ2à<,ac5ìØ£' ŠcŠR(E”:ª"¯SÎpÊG{Ø„º¿Së^¨>xg|{ôïÊwÁ˜@~°"ğülYP*ÅÃÏ…f#”Áb“îDÊ½b“>«[s%Às‘¾!PŒ'•6óyœş×âšäqµ†6£’ÛÆÉDº»#RÚÊÊ£•L/º‚…k=ïÅ+{FraÈ‡}|‚Zş:w2Tş7è\×+¢=Yÿ6Š€äAÊo6ó BÎ†êœêŒµ—¢çÄ]8ø½Ó5+#]
½!®àtñ­´µ:”]KRt²øªªqşåŒ6³lâ±ª#l¹hp<(tN"×•ÓËÑ+ÃÏ‡¼62Ü'C';ôı¹ïÉÚ(ì ïF£¿®®÷ëŞNénü7Wæx8GÙDñ@Ù†*â5r°“:ÏóJµZnX½ÿ\İ˜áórÀk5V7Õœ5‘f»™Âl¨ĞØ]òökújæ?Z÷øõ•gæ2Ô‡&úÌ'íéZDñ¾h®¨#´~|ë*äeÑqşª§˜3ázğ!‰1áÁ•$T6àmvÔû¶¾CÖ¶<‚]d1E‰9²$íYm.‘ Dfr’&7äHg#«X
­½Şİ{í¬É4N´¥jORÛ@¦iŞwĞ6ˆ}Ñ©B~¶G‡±j0¨²—Á>ÌæïÛ¶¶ÂU¢³´’ÕšøÈ@é~©Ü¸8;Ø«š	ÙVÜ®ã‘$LRKR$K.Õ‰ıÆğAúîİd5œ4¬‡Ó)5SPˆúz¡…h	˜>ç<é™5dšŸ'Z_ÅOÍš'9eÁİ;»á‚ÿƒæY‚š!Õüu´ƒÅkŸ€ Ğæx‘OØwÑDRœ)Üëİ¤õQÎ”[«\Å*İ|Ïô­y„˜ù|T¤)²À>wêW)Œ¬ôáB¶¼mø‰•Ç+€IØiùe¡X,Û~(«^û fR0e§÷Î¶ÔÖ¶|˜§(õğ™sÅHaüİ‘Ür:Éºi¸ö·YÓªLwñ´ÿş W€N Ã‘Ø‡»¹éÛÿ2ñˆ'ÏŞÃnñá˜4DïIªŠè¥ÏüŒÂŸCb]	Š°\.å#=‰İ§…¥Í¹&âCH›»8P\¨it’3‘‡'W!×c|¯À^_)®{lûŞí[šá ÍwôF‡Ï@»ŸX—X[(ò›Ö”ê^@y£,£änã|N<ÔdVĞ°¬„4N„ßğ<ÁNyBÒ0è€P~—ş{Şç¤Ï"Yêı8íZ“ª €·EóäÜ3áÃ¾OI€Wô‘E3äV|Éäø˜×À+İöÏ‹fâ<24ÑÂ/åt[Å½Ò%•/âÒÓ»²yïª…Ï°)P'õ‚‚¯lpIë±Û”Å.(ñ}Uk5Øyïµî…í¨º/Öh!xöpK)ìŒ&Šå]hÏT’û±Uuê·ŠÇ
t®: {ò[¹˜š›X/\àÈ_—x°ÚIÎÂ)ƒ±Ïê„{Ød:îA.,¶ğÏ{AùLUáKpÿfª’£ıˆA—úò¾ŠÏA\´0CmqNÊ„â@Fƒ»“ÿ,6lØUéç´ñÃü|ù*³Õ“Ùğİêİ´,‚¹L‘‹Èµ€J}>#LBÊÆÆº…ì¥Xöxs¤ÂßÖ?PrNÆbÉÄ%_>÷tCvñÈ`IãpøÚµ‚áé=fÂy‹[¦}±ÆEÈÑgôÙ†àDêëÌ5bB[‰.•FœUŸŸbN˜D—ÓA(©’Í\ac‘b
ÏºÄ’ò^t|ìÌ#<Ï­Â•Nôºô~¨ä˜‚ÈîĞ‡>\'øÇG‡33V„ãiÆ‡«¸îS6tû‚éºûìGÁãå™aY»úLŸ]Û¯EØñWbŠ/……şZÎÕå~I\ü!ªh …½'kéP7W³âè+ØÉÙA¶ÀÄi¤
‰ƒA.jÂ-}BÑıà½í/ü·İ3&°m%úÆıEˆØõêé¦t	t²É‰¥"LÁéEFVêìİV%¨hãØ[wmÅ¯úŞäUîëÌU
¯ìŠHÿ täïKÍşí³kÄË¹	Ä{¥+« ±û0&Bt¢ÅÂñº¡wó_-é‚„Ã(5±h\¦Øv<~³ }v{':Ä	ÅÿÀúúÓcŞHetgı“ü¿Yõõ]4HÂOSƒ¿ë!Áu¥ ½ÌÈz§°]Ü9ÿ~…^r ¢GE*tå]¡"O=˜|ùiÙg¬ÆÛ&õrvÏîaû	‹Ÿ+ù×¿ÈqË˜ùqáïãÙO.ö‹!Ê ûUìÛiâó¹›…·¯Ç}ü—-*“vÚ ÿ3n{D‚5Qè[j3³£À ğNf…;ÖÏÆÃQ¿Ç;ó†–D…J7%¤0JÙÑv=æ4b»®<b°İJ]Ò²òïÖüh.:-À;¶Å½- ¥e~Erâ–É.®ogNÛGì0´¾Ì‰1Í‹œ``m—õZ™ p°³«½¢&
bÕQí/øpC5ësÜ[_ÈêY,şü'†N°ˆù<!­’™×‡K)èSqò¸µÃòn+uŞÇ,¶˜^§Ÿıe›¨<Ö/ßíôQÚ#–™©Øj÷«‰:¤Ì²›Hw‡8–mªøä¸MR•¾µŞJ•²L3ÈUzW£‹€!?Ë-È„™rä[š9œD§,Ù®Çw"°¬÷>‡ß®‘ú.ø¬r†jî™ÌbßØ·u•Ã9]Dø­3µµ³%œ^€P~ßo$Æ¸`çÎ–ebÈ0ÛŸrn,ğçÇàªû—Ø4CuÃúßÑ¤må`d×Jyµ‚zÆñU¿GEh>‘sõ—PPÅ×®41ÕöDf˜3ZÀã‡÷?ÀÛ[RW#¸;hÜœÉÑ†Û/JÊKób ñlØ+;ewÃõÔÄœÎÛ°lîç¥±jƒ¶¤iŞ¹‰câ}G2Š=ü‰Ğç`æ®Ñrí–×›³V4s¦×·rdk“oB$F$˜¿í’©¨T"Ã§¸änêãî®İÏzœïîì—ÓÕ8»B‘'¤(a÷”ÉÌ¶2@§IÈà9gÜY3µî§£ôÜ+=+§4ƒsãšœC™Êã$Ip-8çbõL§!K1]Ç4m4ıywcJ.†Ë¦ü¸Õ7æÔ®¸–„Ü:ñ¿b\K
qÇ8oîõæpª]y»&W5[ßØ1&†.éÍ; ,?X	[ÃÛã;[î?Òš!¬b¬ «îmÔ<´.jz÷”ŒHyb
ëÉTe9[ÁPše£Ÿß…lj‚”äê5ádr'ñÆDœ"Ÿß‰X®EB†VşNä3g+59P42f[@TŞ” `§IšßË—·‘õ± ›[1¹L;48ñ÷Óir< [¶šºÊí‹wW*«.]!e1mqfgÖüÃÎú\>°‘tu@Gıâ;ÜÚQîår}rŞ{ş²çÁ¯‘_¢$>XÒÌ+
”lô	#3‰xe¼¹ıyBñˆÜ]Y1ØoY×éuÊ~ñøò-xd©”´–ì_Œ+ú¶·™İë xr×…<”u!××İı …ÖQR¼›8^Ò µ³Ò=EòL¦kÓbÑj#Ó}z|ÊMâj‡˜Bõ''-âëÀæú\Ù.0ƒÂ)ÿşÜêŞ¨şX¯¹I.ï¾¹ûÚ¥W©U6ÊœºnRTÀ‹Mc½ßV4¨X-4bÆ£SC<;ºå“øÁåÚÂf1Å	{_®Vùøc­dÿåÊ\•,u
Àí÷Ìkˆñåşt%]ÚZš¢y§«…KÖíkÍuLB]X0hª,Mwo×å@$¼&ï±Ú^\,öÁÂÊör _b€q˜T0Ï#İ4b† KÔÄºdğ¹ÂB?„=ÜÜ|ËHgÈü+F¶.M,æÖªDxäÈÉ/°éæ†éº
X&Æê˜ÚŠ35ëWÂ•‰c4[b:İŸh.Ä\‹İù»™Á›ã»²rQ(¢m  ¡[	ğfwß<¿“GİO»”Í™Áş)Ù„ÄêõĞiØK™awÛî;§ÙS9¤èI¿«'Í~Vò&´’•JvyîX”ÜõÛnÁ\í6ù±£d1ŞC%ËgÒ`áİ¤¨çs·:›@,ı¨«€dO­´®ø©šôù¤#–Ø±nÚáÍ¶¬[Øˆ"œ’şõ->gGoy?HìBÎ¢«|øÁ{ÇÃ,8™ À:T_íåI½VOYnë w^ô—®âÓ ª.®r-[Úª±;IÄšNÎ¨ì8¬0B›ÛŒPİÚâ”“6êæl–îKF@ÃõŞƒ±ü§K‹#X:½,ßP–õ¹A¹Ã¢¯y1OıÇCoºfîY|0 ¶™Luj£Ò&F?}cV%o°k­ ‚şvßÛ)õö/±Pƒ#û´êY_„»sñ-	òÂN7®7\L#bmËs¸¯¸z6.Ë¦ë RÀ^¢{ˆşóé¡æÁ£=	×Ôc	¢Æ+:ãp	²àS\7GŠÑÒ©Ôe8ÑŒE¯î&óa¢ãw}á{Bøó¾zi#½8•:çÀM«\¨ZE€ã²fSe¥–X5ü¼²æÎ€(&E ñÛÛìˆ±7;{4<¼ù®?h@Ew.9«æäo[ÏŞ˜åáv˜~ôVi‰Ğû0lb-Í“KÏŠ3[*®è›ÎŒÅ¯Ñàá”ëú’ş$r”ØTT?Ğ´œÙvÊš­‘Js+p"hd'!]=glãì$ìa¦ ;6JòSÁÙYYEkÆ>ÓsúaÆAeÂYPw×8Àà—û–oå½lG¢*åš p‰İë”hÅe¨ÛßÀV” €ôí›la$~|=õğCÍ3Òã’Ã < `½ëhS¾Oã€p{Sê¢¤lg8©‘ú*À/…¯Ïş’º>J%£¸X,ÅØ*±;[Àôİ§Œ{Ç|$GLPºæºz	×~®çS²Y«Ó3×–¿Á±5Y{ë-€Ó¼º`'Y3î4nRÀ|&o[«B–LbæûCkÚ0+ŸSæÀÕ˜£ÿLEL‹3¹ĞÒ?ÌˆIäÆÌ‡'‰NœÕd¹uàÂb¡Óy×Êûƒ§G¬LiõÏèªß­<-°æ81ˆ—˜PÃ¤É#É¢EH¯ÃÒuäÛ‘¯ÚwĞ˜yx­ßoS`ÖZu%ï‹0|oZäXÌŞ}›ñ‹p»Ç6ízfj‚õÿWi­mhßîâA¦ñ„;’³t I+ÖoµZË5ğbüšà¡áb³*ô,Là*$7²p¥=ƒ´‰„+Ô/ái‡ |¸s­]AælÑ‰¥?ˆ+ù½oeR‰˜—»G•ãÔàô¿Øó,a°ö{2b</ßÑ¼fô¦¬UPÁ8şëq’÷¾{_«ìsg<şãN×D¼;G}Š)!»Ï>ÎsÌHH‰q®Io-şŠ yáµ¢Á2\ë[º¶ØU N{Ó <QÂëD2)äN×ULĞ_ßF½“|™çQØhg4Ö³Ç´”oîæ:~¯PŒ^‰/öÑMªtEÄY‡‹-Íüw3¬bJ„›òdvFïæ
83L[Ecs¾bM8Î™nS(II¡ù-Ø8·	Á²£Èñ®‚—³¨×Ëà~ue¯fûg¬ÄM¥"ƒ.~ÁËÿ¤Hø¾zÒbà/¤ôo€Q`„bäa¼ÅTC¦V	•ÓFlhŒ¼ŠÖÛ)^Ÿer|GıMƒy†Ñ%@§Æ‹w)eç}¥nøô>ÑdûŞI†GØ††jğÛ/BÁgJ@÷”¿çZîŞ¡ßìé%—æ Â²
ó˜^IØl-ƒÏ>lÅµéøos]º
¡ƒ"0ŠìñA£ÿ+œ$·˜ï6Û„CÔ1©¤ûùVE-ä§ÊÛç“ÏŒS•
=¢ ZR#œÌŞår–a…`©ı3­<|0üéûR°uÈØõ´_;´,Aa ¯Ç¼è²M£I‹™h{Ş¿Ï“ù_“ÿŞ9Ü“Ë\Gã©‚ì¿²NØîLC4‡a#œä¦aĞw_¤Õ×6ã™YjßĞ¨¡c¤A®­F4şt²ø‰ğ{à™°·"÷¼ŠGsİ€•ì¤ŠH‹Ã6J3ˆr|Ÿ0”<89>3ëÌ¹Cí¡M))fÕŒpÛ€e,}÷–å×)º®s²j“7Câã
N>ÒÆ<."ñÀ¯Ôè´Ubò¯)|ª iµFS'Ç1f¯RñêE–6ÜÍ0hµHÁc¶~ƒP§«õXÏ;*O`Ù!9,ÍšËüRóıà.'Ğ¾w‘ø5;.±çË¸]F–÷Q‹Ê$®ô'[	oåëô¤CgÊ'Û?ğ@>‰É(@gÆü$ç§Â1†8b…îòG[9}ñŸ¾Ğ4l%9à¨?æ8ÑÏd³†^hÆ7ó“ı@Ô÷z3E,Nê_fÈ1\ó'°EçtÂ´ÑÇ% ÍÃ#Á^P:R C†›”¾/U±6CMê%
ÈvôµÅ¨ 8c %F %ê9\_·èEàEÍé%N25¢—³ò7‘º!_™–_Æ¤ıáß¦‚ƒ*dz"'?<×në>"4Ôô#¶­åÔà•Ş&Âoö%Ÿ†œFÙÔ«!UàTñ’É| òIhLP’©È]¡âA{-‚‡ÌY×*VÜ°[ÓÊ’Ÿ½İ+£[ä'öN.Ñ#´¤‡2¡œ¨ucÌÖï…;úh*b/Ç\4Íy÷ÏÆ,P3ïjÒx„.…~ga	sRCk†'>ÇA79¾²¢êÚ~³Ú@¸X¿§“Š
#&PÃ±¡ó®Ûãº·
1}Õ?
Í‚ı+N¹uÿ½ScÓ‰©Òn`Z„ˆ7nËŠ”‹Øà}càéxÛŒè*%ÏG=Ç¡lÏåæ‡İu’9Ç^S¾Ôë¬ˆc¹”
ócjW¿ôıAø(%ûñ‰)¬·2M»†VôìëHÍ	VëÒ~{ ªO)f©ÎÃføˆ<š…ªšc/¶Ô›aZè ÿu$Mc ÕcùQÙ{ˆêp4w.¨³zÌ;ûr1ïYQ"İÕA¬5·ôcEİ]*3jÊÍ?«U„w9Oˆòœl+–a¶ö›÷hv[eªß~êc[í³#A 9gû3)L9¾øÉã}ÊÚ^Sw-CÎ^>6BŠ£lWò<¾Î6m¬“ãxğÊ¼f™ß‡=–ıL&é,ã¬o–]ì¹¥<¢åFLÚ-’·rÜıËçÚ3¸Ï‹ïÂ¶y·Æ3x°8~.Á™¬›Xá¶iœ…°£[‚VZ™jÖc›k¸øô¾Ç!¯¯¹‰úÈu¼ÌJ©}
:©ªååĞ<êôı¢¤<T ‰ı<u”£y«ñ"„ù@Ïó`—ñ«(Ö¨AùbPx/÷ß›Ìoò^{b£Ñeo•,YË‚ûIÒô (.V°éÂ2º{ùü÷7
'ÓKP¾ôl¾
âÅÈZ6‹“ı~ÉuÃPeó2›@­¯óMŒd2|oš-*#·7Æ4™„Òv[ãU©¼&®Š¹üu8ïÌ&+Ø©à÷Zî½RBj{‘Ú(9£úú|W!²º×u£¢$®šu5ûÌSkC¥¼;—ÆR ~Õs@åÒ–œ¥jên—zP|"ú>ÆßÜ2¬XpŒŸ†ë–Ì¼§“ó37ªà´_ª¨,ş£m6iŞ›<’ß1·b³æLg‚ál@Ë
m6°|Fy=-ì×¿çæéã,'E‰J¤„qÂ UÉ7Ğv_x¢k·™GX±&2;5{ĞTÿ­×ëkx[‰õ˜¼N‡ŒIõxŠoÎ¹…İ}„kXŸ^~b8§ı,K`ØQ‹³ô1©oÎÓHHüûñsôy;
Ë£B®ßˆu@ÆS?‰8¼êWâ]Š——<2Áé8•NéN¨E¡…ıÍ9/ÑÁ¬%:åº·Ù¦øàÎ5i7Ûçû	ôšà)€ã öîizb¨´ôQ,Õ
=Ï¼ıê«iT9R©ÀÈ³Àí)†I.Uj(c7Úç-¬--Sù1èa}ÿ­}gƒ/šğv xåÆı™¥S"Îô±DıÔïAôzÊWMuœMK_KßÃñqr§•€~(p7-DE]Ğ{i½DÏ±#|j·,Ó3oyÜ€ú´—¿U…;=y[£88O[È¶m:LéÖ$8Ø`÷Ô)òú	Ÿ8m©Ñå¾Y\y-Æ {( H´S¤//÷/M4ÃDo€P…Ö ÂMOr@”êßÄ  ÔÀnp[ºÇµâÀ†Aß‡PnŒ\´„±/!u;nÎM2aÛ[Ï…o;!Ä[ÉJ,¥ƒû]w0ÜqÎ_¯L	áQ®KJXóåĞÎâÙ1-Â,î?†¤½QØWQ™’yõzcùu©”—ªıAë>éï²­*n²æp-ÀïB¯Ì·²qX°¡-ºõ'¥IR¢G‘Š~Šd,7ÿŒodœúKd ø}ŞÉ·ª¤±Rx¡Ióçîc××|As~ºÖ\4%£MÛ:»ªv&ZmyGBM¡PK'(mN%U5DH¬…g§ÛN©î‚´î5µ)PÀ@UQR0]Ú‡ŸrI+òšl¦f¹Mš*åi¸‘TrøsC€gcmrnzY*×÷*hŒAøòKxª™0jƒ7áI\`c’¹ı
¤-Ø¦WşD#vT|ÆáéôrèÊæí)rº2Îák!Û‰ÀÓŒ¢3È4}ÅÔQ´£9<[³]JşÆæ¸tô%Ò~£¹ŸœÎtÖX¯¿‡øŒİ®¹' †¦S¯ÂÁ¢‘™Šç€ m§ÜŸĞĞO`õ´hl1ıÆ²w ØÂX¤'#Z,j~®–¢Äjóçô3êJcJŞeb¥l¡·`¨šaÒl#iÑØ§{SŒŞÄágƒµoŠàxcÖ£¤GOZ P÷‡Òo üÌKNmÂÃú×s6ÍùEÖŸ=©×ÿ¿dH¨\Q&uŸ3P O9w =j†j*ôÑ.ì??&şÿúôŠ÷~t'¨<4	:VÙ!ƒ€ñ¨>¶óú³§Ø+ËÛDàbh±© go*4R—¿«ÊÿDJVm¯Üâğtƒİ­d© ~Ãù$!ÔY–fßú#jéö©ÄáV5$n]‡˜ë~2÷@«ø)ÁqQ§HK·ƒcÀãPOÕ¹¹Ã»´	5§é˜Ö»»n³†¡g7¯"LÓ²kÕn•J;2üÒÊì*ìÍÚ³†@ˆ¸Ÿ™y!ÌõD•XÎ,TU:“7¤úá¾*;"¡e²ìaÜ¦·ƒvu–Ï¬•…Ê‰´Vùz}¶Š³Å²±Ê1Q-çƒWDîÎu}Aår©0ÿMÓ"]Bv×ŒDJ}úÚ­®-5ãï[>dOu¿@v_ÀOC'ì.!ÕFhy6} µN*î¸E«ó§<±ŸÃGóÀ˜FÃOüş#˜ûÕÌ0Ä<Sd¨cÓ œ{ç0½*ä”	@ñr¦.j/ş9ŠÍÊb3	“´™Yîj©“i˜ôËÜÿ¦˜´°q…,»V^H
B7Ûº ñòŒÉ1§ó¹âÖ ô©ƒ3¾…5ï—||á4ñµ¿é×ÙXO±°Èm8ùÃ‘2¨†Ó:Ê®ß®Ê(­[ÑQ¡af‘õZ€
Ñ§^-‰f'~}ÄÂ²óv}í¬4"ƒŒĞÈ
¬aÎ†&ªjº°^æ“UP¿t?G˜† >rjœ\ß¬RùÆ^J|µxõY¶pC¡c…Ì×Âaã¥t™$Æ¼vp¨g›Y?ĞÈ‚V»¡ÑÀˆÇEC	Ë ü'óìŒÏeÂ­Lk¡JÓüöj@GÜïF[ş{¡óèTp£-ünƒÎ/R¦–ÎDÕoäi,ˆÌ¨*nè/WuÙA»¥ãI™‘~ØàSäF’|4r¯¼öƒ¸BÎü0U§9]‹6‘ÄâTßGf¿ì| Zªwt½¬Ã´);X»ÅˆpÑ.‚¢¤€ŠÄu'Æ÷¢§Mf®I^x¤ÈÙ8übú±	xøNcÅ­Å~/®_Ú­?vpFßûôpÒxsŠM|Ö¶^¤UĞJV³ä#¼<’ÆÅİh:õ$™+Ü–ˆãß½$-á|º"Ğ`Û:-¿¹S-—‡!¼kÇİˆöÖ¿éªkÂSËüÜxGNr³·±âV.2íví{G¤_hº²aÆ5!bºMêí’YN‚7l„pD„É¹…å…©K§4tCËá3óÿœñÇD †J¶jcƒŸå«¬®®2‡„°©†^Õ0×¶ ”Ml*šªGTÌ‚’ÂªúÖı*¶À®†XšÇó™¼b&*9(ãÍ×K´ÈŸ½ói¡$HÈÇb£©Â«y—ÊFËKı™œu¬¸îÂº0H®ñ® -VNLõÑ¢°ı[¼B&ë¢·ãúAáÒ¾¹Å`¯;”Çxä€¤ï»½:ìNØíò)\>m4Ù²ÂN!}”†"Î<÷¶"Ïxk(°óF-Ï{t/àöÕÅše°'R¤¡·víéW-Ç¤×Ú¸*1jm—zcV’ ¡f€Ö¾JpPAœj¬Õû
ÅÊ(
wN­øÏ+]s‡Ş£mƒ7ï*{L“+Ìİ´WLóaOÏ3"ò¤¾	:ØØ£‰u¯JÏÔã¹1^ÁÀº˜
~rÈÿÂ(-Š‹¢~7ŠÅ_tæ°<šÃĞ<Ş)şgb>>~g«xÖ+Ïœ^&7’Ğé´Ù	²Aw°§c8*æ¥4G§Š¯b;”+ÆæY¦øå”Ñ>ÿı°v)u`6•ìÍáGˆKÇÂç·¹v5ş”÷…ƒ“‘ÕQƒ¶yM ¾ãm7'+qÙêÌÎcâß ­›sõ4ŠÏ¿HÆªEàõä”¦~}µÁEu_bÕ‘³t“¼,?vHßÛpŒ})f¹9Y£ØÌoNã4eü'µ#‹eº±Y»ÜL'à“-.ÀLÃˆºˆ-‰¸=»ü¤ñÆ¼µÕ&‹1Ç¶ÀX õùƒKµ4ş«´èP“<>H±®å	nJoÌ‚p£Xÿ×şş¾Ë)ò$·ù®`AÚ]ÑY5³¤ò m†9ÌÏ·¦µèŸqò¥3yô?ªÎxŞf©XÜDÜ„Bâ^xdTÒ.³Yæ¢‹@^êh³ëÃ…›ó§@åN™éƒOàÊ• »Rã_ÚèÈª\÷e{ H´ÒtªÆ<nİrü]‘5'=t4ıÇzûcš§¢GÒ»iYgká£Zİ™zM¤C(õ;âü4ûÕñÚèŠïÿAŸØMãYÙtË#0¢ƒ˜»F]Pn±õ´xzøµşäÔÌ»¾¢»ETàı1;L)w*…§"#BÌÈÕCn&¶’ø÷û•[Ÿé•°ª1ŒµßŸ+“ÌÏÅğ¬À³˜c)fSQ#îbBùŞ¹y¤w¹ÆJ1Í)AÙ.Nàğv¯jUàˆ„™‹¿™K¥—(Jæ]ËÜ+ë°ıÓ[zw 5U¬ ^º¼+oÚLêYa¿÷è*Óë|rs=@xmB0D{ [ADÃ7êİ½{á.[M¹ ì"pçÀF’?ƒ­:WĞèôn.í<¢úˆ²À-Tì­aàE´Òdoú !W/M–ÙÂÏ´Ÿäævl&D#ñå`ïÑ»®Wö4-ÑÙ#ğ×taëùáí"LtîŒ¥‹¨}Û	X'Ï]ÊA‰œ5ƒx´Kçï]¥Tç!ÜºN/ˆÉ™Ò™:PoÑ¶*[°‚ëÉŸa@W\ü>†ƒıŸè7º@ê…úHâ/[„püË¡²­y±6sŠEoéÇJ9Ex¸àö:NÅKiÔ1¥``R¯¤Iáïº%µÍ T (§òÖ4ën%Êê·0íŞ*¿®m:—i³ÎŠ€ü„+œ ìrÚšÄÍ?†_µjİÅ.ÕÙjF\\X©©YYWŞ;Ü­™ø–ïI•@¨‚Å| ÎV‘@riXÿa©!ÚgH*OHn×Æ-èŸ$¡óÔm¸ÑClóÕ“ÚO”·s¾{»ÜÉ¡Õ¸ªS÷r·Şf+3Cöj
?À¡àœŞÙĞBòq\¡Ûtf'ˆyvëuíç#ş@ªÛÉ§İ0ØÓ´1ÛØ{ÀjÖºI[Æ–#–ÆK¬€ÿzRGÿø§¬ÜÍÊ5ÀËQà-!1Ü™ ©Îí·+D!¡‰dàùTtEÔûA¬q°ÉiLÀÊºïæ8=×b]8 h+)Õ§+òrÇ[¹’®¶>şµtdâJ’”YI­:H8|­-€R Ygñ÷£Š**oå½¯õÑÜ·¶ş®i°däLòÈõV3d÷k´qKíUÍ’€W†5»Æ~­-#ìQ¾¸4 B÷1ƒ¿ô–Â‘U#ıŠ(ÿvı-O^ë${–£}yQŠcq-vT£0¨¬`®ÿÌ4gİv\íò‚âğÿ¡¢2Q·şk2/"?J4åşsEoxfÛoîZMëÛ€®—ô>”­µÜæJxPåö³ŞÅ»Ô¾¯ölåöàœ†@ş¿,‰t5­ä©Z	ùv(«¸g®>Ÿ…÷&P©Ò³š†1E¥¤\‡ÀÓa|Ì@Å¯ ”t%o2Ó˜ñó†mßŒ™ew6™çC!¡_u¯ÒÿòÓ… ˆFo¨Ğ:$9„J4R=)¨î“_jà“®ÅD~ê3Êüû•]LCIè§ßˆzóÖ;gÅ?¬\¶§ªXÏCiÌşÆQlŸÎ	“|­•œÇÄñ“ì)ö%û©¤ZñöI^@Tó*w`3‚›Tˆ.ó”Ô0óé‹š^ZÁŞ3Ø/a¹r 4Ô—5^Şy<ÊùÄ³Î,l2ÆÉç*ÇÛ¥µ_A¨ÕNáå/œzü(\-Ğè@
P¿S}3hÁåá}ÂØ¹oà®ˆ|¯±Ve¨ƒÑÃó+Xsñ¢'hÄNLğ.ë•”|aP›A?ƒ:Fô"ù]iŞNä´éÙ½9s4Šü\5®cşù„&‘‹PØ~‰/ŞÕÈ.õ±!´˜œ	Wmºë5<Æ¬MIÍ$E_TÕw@æn–Ÿ¡Æ'bo]&ŸFá²Ò‹=í'{ØhBs)IÈvÓ,%Y¶$Æ“#ÂŞ2VM(lú¾T_Êëû&p‡^»A´DÊsˆ›Hÿ7­ú¨‰†Ş§u ŠÊ-´_À1tü”ãe‹ºá~* ÎÑ9Ü\È ävÊ‰F±Ş™+¥b¬pq^e”¤Y×sNò¥2’Å=¬X,ÀfŒ¿#Gq¿nÓƒĞõ–Rÿ¦
hRÊ‹lÁñU³¬šÕÔÒA •ï/T
’¬¤áßóZö'Ñ|Èÿ1”¿WåÊ§êõÉ¢16|T-Úï°‹Ÿ~G!¼©ÏÜ÷ó,âHÖ"œ/0J‡ÌXN•f““XËU/:Âã—İùÄÅ¹™@ó«<ó™<dÖÈ„Rà¾ÄíOeŠ—d²YøMÀíd=«}Q V&Òú³n°¸2`ÌUº!<°6Ü`@[ ÅÊ‘ìƒí(ò¦öBÂºG©¹ihŒ³´
Ùk7_¤ÆMnğ(ÆÙŠ’ÖRdQÔ0í²ğİÑ¨-ĞŞëàBš«˜ VË0Û¢£Â˜¾,]QG æ5Lä‚ZW»@ğÔÜÿ†×Á MD¢•›ôİŸ<H0°”ÂG’­Ãˆ_*s
˜Ø.Ş4ãAŒ–¥r£^Í\Pq4Ì›»5qé•—ÖŸÍ÷Õ76†ö£ç-+ëˆ·¢[¸j"´¾–¨ğÀ›Ì{÷÷ I¢Xé‹£Ñ¼x]/óÍ\Nƒ·H-¢g¯§»/6Zã?_¼XcP„"
c@B¥$+ıÙŒ)YC»à¼©F(>évä£öo=BQô)ŸÃäû"kL@M$g®Å¢<š‚n‰@ÿò.<UÉéu’6Ìº+R]¡å ?“Œïš†ÇúÖ¶êÏu ¨ÿ¯0Oœ{ÜJpÊj-9-ùf€kã=yueƒĞråÆ²y]4ˆÂd"V÷ÈÏ2Ç?Òe±ş¼
‚=b”\Ñ… Í
Wi5:©Â|³M#%²`6 —­"†	sJ’÷‹äöƒ9Z=åŒ>6D"KfÍN\ûÛ§}WåÖ ño]>x×µ¾AmÓmç¸(B˜ÄÙº­våƒÙ+Ò¼U©g¬¥Â6ú­DX¢±€Úµ[ñ©¯òHßÂI§¦£à’Ó‡ğH*ãŸ=v™¡îRç…Ÿ%¢æY;Îp6›§Æ4ãKÚ	;Ä!ä'¨Õ3WKÉĞ¤„ßÁÚ=kšC3[€È.È™í²®ÚãvîŠÄÅÑ¨„qW<ëA¦|“y˜‚s­×ƒÔ÷¾”ıªsRü¤³Å]=!÷s™JQóÉ©ñ„%wC^²kc67åsí %oñh.¿éI–«ôBA0drp:è€Ï°e¯Ï(Ä‹Å“ØMn†Ñ&9SĞeIQLë²ùí|ŒòLÃ{gû¬_Np…ñH4F¯U¦Ë»DÛŠåa•7Å¼É	„ìx•Û×<a¹Eóú ürQÁ|³ö …ò¦ÕÄâoäØZ'¹Z²â|Â7ÓÌkŞ¹İSÜÌ:”ú¦ R¿uÇL5üO[å¡¶˜ÜçBö¯ÆvÒ½f×÷.Ú–7¾àÿ%ô0İGª9QŒÆ?Å`ãí+¶KZ@Uaøw-NèúGäÜk‘Ùâ}ü|çOêk)$“bSÉ§Î“VÎébw|ìºi$¾Ç¼¹åx•âgßlÍz¶R#P¹GRd+ĞÍÔ*G)&±pØ‹É]Í`E ·šÎâø›|İ0ü’ñ$¶¹Ú©eOòØİ©.ÒãŠ/‚ÿãXOm X¼ıüŸêi7}YJ^WòÕwYm±ìú{Ø[Y7¡oZ ­Jügõ¶‹òÔİzæƒ¼ˆ6ı@zˆLÍãr)Kä¹Nş Å¿”\MM4Õ§m·s,3H¤“Ïåğä~ƒ<@é…İJàÈ…_]š{(	óWöÀqT•ãæ?ˆ¨ÒÃ.ÖİÅïvj%¥‡¢GÔàq@3şÿ’QİÁ•ıŠd¥æRÅvF’2Òh¥8DæU_Ì§êÕÜeš–‹eBËèg…àóGêaÃ ~q|ÅøbR¬¥ûĞ?
ÌQôœnGëI§÷³S§ÆLIˆ™’w÷ıŒ–v…Ã f¿<Ü:eŠÄnÑÃÊú6W¾ËÄ”¬›e8Á§Û´¨7
¸™…ö8734Ù9~ºá‰˜£Lty	¹“§ã
™˜?¼9âÀÉPÌÉ†›gC³9mŸÖ­“•Å›İcp¶$¬R{Ş·Y­"h¤x!&[´Ì-û7á "_¨æ¹æMJÄcäi¨j%ı­rÏ+FB¯üùlıµ!ÏdP‚¨ÓÔ—¯3ûÍ\
h)ìí09í€^¤7yämƒmz|¼,™iÏ¾çló:ÑE×cÿ¡‹Ò MšçÕNêı(×ªRóÚë¾vÆŒ¾>á.J++bIy_){Ïª=ÜoN	7É:«HòT#o‡¤î“=7ÄFøw8ˆ€oS?!‡z(òŞs‚™lîºM-ëÆÂÓ·¦Ë^u`.{è<®½¹PÅ³ièHHàcõ»k)í
ò"3Š\¡µĞÆg=ÚŒ6U2”ÌVhƒÃKŞW#éFßÆ‹R#ßfkµfüh¯“‚›úÏAşèN¾Q*¾q½Ş¥¢ÁÍ güã²]Úïùãz’;f'¿Òj>¶h¯µ5‰÷'ç[_ÿ¤Ó+ˆ©¿œáehêeB»÷ø˜ôôC¿«>4_á1İ{3;u_àÅ+}	Ñ[\G}+¡å.Âài¦†wK¼(Ë†9‰,ryjüİôÌ®é Ï.²©™E#ZĞ^eÍo`¢òb*§³tÚ.…áÓ‰òK¿>T“•Şäè1—ì[¥#J7+9?&»…ô¸„9z×¿o—h8÷§ÊŸ$'°q3\éP‡£UŞ#‰ßû'ƒ¢j
{åFaµ-cğg®¦1ôˆàhÖüµ}{œY2[)?—ÚhŸ±É4À%Ïx3s>ñÂg‹¢T¤\v¢8f[{ %±UÔï§ôµ2úXn/şÛÉÍ°‘91ş Á%6Ûéø8<Õøœo§öy\ª­ô¦aõ×†±y»ÿ´Xâ³Z&ÔÅ5ÓşJèVv**öB0™
ánæîá›‚fúôÕÜ‹e™ÁXrJ2~bBcüß6¹ "®©gÃ
'²ŸBÛgZ}½†gHaY¾cüC¨\•£ëRÕ8ÜËÀÅ÷±jGÿxõ‰D+Äú9d+¤iß õŞÜ¯‹˜6Æ%	1O©|-<
è&ÚÑŒ\†&zŸ–YĞ`ÈßØEk\.Şmğ¶ş¯çùñ‰Ñö¨ ³-weÔÙAô´¬®»ûÍŞf\KYŒøpWëƒ/ºéo¦œh¢Câj¢éiµÏ6~ˆŸŸÃ@{\~*‰ìId¾LÁ&Hò*}âLÿ¾8ok‘ğÜor®şÉnñı±Ö¥
° 
Òöå|ó– å)“Íş¯%ˆ=Zİ‚.‹Å32ÂØw§íêö›ŞÀz8ù€ÏÛ†Ñh4ğ9­î·Ç™»Û-×§@mt—ÿçãĞsõ8Áç§]‹} LëAÀ•é	zÂvŸB˜ùäú}'ë’5ú"@Î	†M=j€¼ÛÛîf÷.ªåãŸ(–~ê0É8w³@C0… ‚L–\C„áìEŠÎ}÷ì#+iGê¥)‹KEg§@¡«Æ¤ÕA,¯#Dåüúj„¶X}QìQJ+¤÷.i{ºn1Ş3àßŠEı‘›`Ä
÷4sşéÖö‰W ï¼­ôÍ2ğyú†8¸m*"w`‘:©¥¨@<äÉZA¢òçÑÆd:ŒÈ[éıOÂrõ‡¹‚’´sœ„© U¸ˆó¾ÔÉÌ£¨¥1<P“\Kj“q+Ï äBe#WTÉ>ÜÔÎ2Cz^Ö“ÀÖo»ÒÏ˜¼0ÖÜJeB¯c­P›?´õ‚Œÿ8ğbU.iÏK­[Ôç³İAæÕƒ!´bËSı¶^À°½NÚÂpÄYõÊX‚še‘ëíîÍr6«¢qÅ%XQì}«e%ïP2ugĞe€.§Î¤Û±qåÅÌ?æÁÛ¼‘ò9`^•'¸@w8Äéûä4S,qqÎÒÆŠ»úó
éŠşwX£	™ån¾6ÎşLªıôĞŞ&ßîĞOQmZ>‡}èæ°×*[Cï·À›jÓŒDâqúÎÿ¬å5_Ôƒ,©Èæ£;#×!ˆ]»Ûbú/’U¿ù8¿ Ò³Åå6Å„.Ö’ÒyÖÊß$©cßåÄÌ)™Ãã#Û ñ¼5k¦÷ŞŞ>—’dÌRJqğŸN¶Äz½‚ZMSµã‚KO_ËN¤ı‹zŸÒ€õa–IËÙñhu¢W\o&t‡×ÙO‹ÒğôÅn2qo"ø/ü’F`GHŠ“î¶zÿpÃØ±„•Ó£È)İHÏ¦KHÃVíûq…ûE5E?ix5ƒ ¡R²WbLpÌx7®Gûi¡ç¶Óáàrˆf*Çg€„†ñ™ÛeÛ.§ôßóI-0?ßÉ½4«``œ¼7Ú0&‡Ç„¾@~‚Ç_òë|\k*¹7kÄ`ÛQ 4‰“WQd&rP$—vLÁËcÕ;¢‹qaMk'%¸ŞåöE$®*ÔƒŞXG}ÑÓ:üº#Y?óÉ15C¾>Í¨k,NÜ¸™/¼9âæpñÜ­Š«”k¦Ê~Wana•æò\ò	h¨²bXi#«ÀÊÁµFz­y¢°1á¯Î¼ÁÆ½R¥ª8³½dÄ8ÂI`$Ö\­;®aO#SXhÜÚ¼[D×²èäZÆ÷N7TIƒÈÌ¢¿f—áƒ¶¨Ç€Ô‰#:;J­hÄH?9%™O©İâ_ÎŞì†¢ˆíWêö,Œœ~5\Ñ²è¨=”IüDûê>Èüï~áÕğòm€KŠw÷ô˜H‚uµZÓ`œ;£¾ëìWÄÃÃ®
ás,…WµÀ!¡é2$6nü¢¿şgç´“âŞÚhÎâº”YKÆñ#ŸzÙvhoèáÙ=ıëWoÛA~ßæ°A§ÿÌ& wànÅûz;×õÖ®mîN1ÿy„›>à¡gûEŸ¶0õ«éÀK}h©IXŸî—
6ÜœY\Â	cõª=cÃK:Äæ´[0êzj3èÆúZ×¤M›E=äÚÊSÃ+dP!Lü=3QæÇY’VFÈÏ(Ån+Ş·|'SèfËRq¯V°Q;!g­Œ”]·ˆ÷ÔåeŞ³¸ÒÁF²Ù¾|l±R[OĞÓµ>Frm}˜Î¡£¥µcŠÅH„ë,’/ôİ¦çï2³<“:µ=Ğø%Sl){Ş;2"û·×ˆ5/ÉØšÆ~\öPÉDjš´K»kjF¥A'xı{È¸‚‹€ãÎtå8î¨Ã»C‘íÇpcÍıHá& ƒr k/ÃR‰g{Q¬[,]Û©8Æü	n¶BˆîjíS&E/R<äĞŒ—Ó‘h,5—í8î…%»	B?e±â¼Ÿ}¶†mê´’‹VpÓùfa+´=ùĞbÉ¶Ôìc“¸¶Pgo.#A¶&»R7V<äá½ İ¬ÿÅé£¢‚ÔğÑ4\£üÂŠ£”ÌöAiÌŒ9oe´?%ê ®T(œ{%¥?[ÍLƒ;06¢RLI³‹{ˆP½&v¡¾u¥5¬&,Å?a–z'ìUVH¬,féş×"àá4?q¤_\)H1j§ß·QáôÅTĞ Njp 9ë_PfY3Éy‘°y½ë¶ÿ®6iX
È­´(E@nnILç¨¯&FløkC¹ŠPª§ƒ†Á\v0Üü¨k{ŞÍ'q—„éQ+(KéÆ,¼¦{SvÖEp‘ù'øuõ7ÆI„ßäª5¼YH¬©qÕ1Ë'³.]¨mÉ|ìM!Læÿ›s"·õö'ÙKi¬ï¾®!³œ—gX3™Ë]m9ÛÖ¨¨‰§nÀ/´Ôñ¦;ˆ–A±Æ¦Š×A¾Ã}­><ùó6ó5-	Û”GÎÍƒË‘Şî)iºÏvªc{s­®?ê·i¶Vó™2¸®íÉ`;|àEœĞr=ãlZ	İ½„¿ÂF€©ƒa]µ¸_ˆ-­¥é$%ëæáãNgë„qØ~VL`6fôƒ‹Ùàg¯Õ&áí>kıJıÇZ5wä£¾¬ÆÀ?+%â$QA¦À7í® ı¨9œï@múä2óÓ‘¤
Ë.zvjÜ£/öÀy€t"×cKx¤ïµfRWJ†dŞ¹Šä™„ğ.À$-ZÅ£ÓîüËnX«ığÿÖúàœu¸Œñ3Á—å“Ë!Õ(°ËAoÕğä«—”ÏG•ìğ1Da_C¿¶ëLÜ·3›MáãÇM«ù±~·ÛâOf
,L4PW´†fò;ïu½Ãá¾Dº°øf²Déj-t{,¬Ä6wıt´~¸‚*7àa?n ^É
!‡R­‹&€€*%ENÃyö~}¤Å¢Z|WÂ!;0Ù¿vNÎ¤ßXÛqŠ.~°îêÂ¦»(ê¦XcZŞ•7tTä®£xûŒ©¹›çK3øuY	ye³ìºšå¬ŞOÄî³ÒŠWÖßš»›Ám¸³óCJÉgœ¼sVY¿ûp4ó?µp?¾İºŸ†ÍÔ4gË9¤ÖFã0„pà>ÅüH¼vnÖ¶È¶Ş?{²~ÉóéjÑ
¡kõ+B‘Iµ×±kn­	¤@}Z6¡ÁÏ—ÊW(ƒ|f>›%ıdøù2D† ‹›Á‘Ã¬l¿-ôCCš„½ùfùÃA³å6YµÂìçˆ•õVšÅğ	Ge«¦Çï{åQ)•Xj94ÊŠò&ŠÄ{RÚâ	ë:ÀÂ·MÇÆ^éJ]2ã™U‡ ²¸¥8¯…	SìØÃy¼å|Ï!TŸ¸°‰ÃFÑ`÷¶u^¢¹Èœ~ñš ©Ñ;ºA@M‚ç´L ç‚i8c¢†0£öP¦À„Äş:Ş¥ìŸÚÂ:#mæPİH†|D•˜z„ñƒAt_×è‰»³’[ØûVLB&{’=Ø%ŒĞa0E—µÁ´ĞZï•S¬´ÒLòº¥i­
±óJÛ´”ÉRª=ëÙ0dSFCä
szµD§ Ø<õæÂâ„sÜå/°¢PîåÒfœYjåù‰+©È8¨K×†õ#°¿J¯ôÔ±¨¿IU…‰óBÔm©ëkPëãèt~e?BŸ!êQöÙŸ†ÔÑsĞ»ôÑFØÁ„…/d©ÈOUó|h2MØ>W	Ö”LtÂÔN2²S'»àmc·–¢7™;eË°i¹Bg;ÎŸà†â„©ŸûE'1DbÏ=ñô4µ¯Üœì^%YÏÍÇDÁş*“]«¯Ğ½ôí¥eáwÄQ¿Š§¼í}A^ªb;9ªªÏü²ğFÙ/‚B¸Ò4,ï}ÛÊI€CNîâ®¸|¥rIÎÕK±ÍÎƒk*´ï¾C–A´)XoQq™Ÿ:Ê2(®ùnÈº§HNf!iÒà­6Ù>UgwÚĞ^|<ôÊ	ÔÏ‹Èõ^°ã%4ÑªÆ1á®E—¥ĞÛuèVéJÇºÜYD:£«M5²üÍÖùÂåm¸;O¤¯»´<‚ª—)ÕB7âó4MBZeÔ^Ob¼Z©Ÿ±¿)ğ‘nUÌoX©)4·Ï°ì]äÛ…Š×:¤}åk/‚r	®$Aƒh:¼B ºUš…°…Ík¢`ræEDüFíeÎQÌ$^½óú¢öÜ"¬ºÇ¥£ß”5äc°ç«'ıÆMìC¸gb*‚-ı€=Š+V8û<ÚËxí¸é.¸É¾jO®äw…Ñ¶ªlYü.<‰×„³4 vZXC¡dòÂø^†#3lDÙ«zßÄn…<ÅëÃ…ÛªÍot9ú<ï±“ºo+1àU€ÏY¢‘©×Ùu Ë Î2ø$iò2(Jk¦C	+z™dEM7š/ùwíVôx¡Ìk(*F±Òª8—HØa<;Éú(euoLÊ¥ŠT:µ.õ·q×ë^O²Î¨gºæƒ¥øŸÏFñ•†ár¨íğ§„lÊ–Á1tb¹@~.œf'D¸NµˆÊÖ†ºAkŞ?­x¸ñ5í~]d‚~Ã©ß *æ §oÒİs r{[Ä%¬ ¡#ÊÎ®× ‰İ^â­×£Æãÿ¶¿£RûJªëÀVlq£ÆæÓm½åO¥'™a"£`U%iß¦§<¡B&”—õ‹êC€­şıºàq^qbqŸ¯ßÚ…ßl+ı¤éqÔûİ**Ï³ÄíL‚gÊåœ·ÿç°ÖQüé·šX
SÊ¡uèôZÚûw4ÀĞÆ{[*¨Af9“¤?øóc,Şˆ$‘ÃR«º6k(æWPF»ŞxaÆÓî”^A,c*dX/¼Ø«ÎI‡Ñ¥O2~[@Q‚PêSPk>™ ÓÆo°²êúŠ_ş»Ÿv2œtÇ£((öÖ4|ŸûÄµóGW ÂşxèåVõŒu¬»UysÂ¨ÙøÕÅª¯§ü¥×õçƒ4úĞ÷»ÀÈ´AyÆŒÂùõ„TÑT0JıÖ&½V û•8ŒrÜZ+S—QğŒCˆ:a 
€]v¼÷ñÏÒÅÿğ€8# FÓLaäœœOAkõ«	V—-$9Ò-²E‡ßˆŒIE””äİ— ÛB\Ñ©¥1Pÿ•ægß
N§W *IÕNDÛi¹…€éÈCÔZ°&é+Q£.õÔXîf½Ånsút\¤ÎËJ©ñD’ß$–’ğò?§#{795ï>2|dê–Ço.2/ÙÌ_›„7À§{„"cßJ”	Mz	õ
¬OÍ·=R”¥TÖ®X#ÿ#>×Lrì»õ4È¾Ñ?ùè:¿XQ¶…úyÃR]êµİµ]ˆü´úC?™ˆ-8\ÊSî¦ŒÀ¬;õ	‚Z‘bSi¾¸‘ Ù~l+SìÉÓ‚oÄP€ĞØ²7ŠÔÌU›Á}«^~dÛ5ÎP7fê0n®p…Œn”™ãlÉQ£Ü½ôMØ{t åÜ¼\)ßPqtãÀ	Ü¤*XŸ¥_b½
m××ò@ç[G ¤Öãš$í2Ä7áã¶Ô¦§'‚¦“¹‰ lQÆÃ±âfVZOYcëäªu´9óŒhÄdµ¯s×".KÄzÆ°½gf		sz`Cär;T{ßPŒË±³‚ƒ{Qäqpy7Ã]v‹ÖÿwûÏ>‡…ˆƒé‹¤FjÌM¿X±İŠIòÒğ¸&ƒó¾İ×óÖ½n²İÂÇ½×²òÛmS¹†½êÅq[İë–{o OZ5ğ†Ü†+åvµëRk]u¤úˆp-
0$*±˜=¯WHº­|àGòôY‡¯·wd$ö,`#Ã^Kş>Ü'U)”†ö«tK•ÊaU²¼å
Ø<™5Nˆ>›C÷ŒGQ.r}{¨‘Ğ&5YvÃê¦:d¿ä¦XW9¹/[R“	üKì”lÊ®Ç‘~Y~bDyPvyVû~[%¾Ó0–.;½c˜Õ1 …ï‹7 1z).EÂÃ‰öĞW‘”‹Üÿ{Ë?Xá&5ã¶â@J¬>|!}mYËú‘†¸uùŸ¡Ø<KA:ò+9g“Ú˜
‚± 7§™‘5tÚÑnóÔİ¥^i9Tè Á‹hN¥GúAµø![hû;ÕÉC·8­ ?<¾%S1dd¡4ÍLE¯ Ø¿YnD{ ®”È•zuI¨@ò…?"Ü½ÒWİ¶YYzÍÖ‰Nò½]ÜC´í˜[DM:dÊMöµâ}cá.Pœã/Õ<ÿHÜE†R¼X~”Ñ^9É<88ÃhT-HJ7D´«¨s4Yã8è©P4%b)5É(œ±ON0*Rf“ùÉ3ÎÖ?+XÕ¤¸Q÷iiö•× gû´YÇ•·õÜsğRç:Ş—VKµÖâ˜£¦OÒ{ïEÉÉ[Ê/bİãgâööÛè Í]-¢ì>ËZ¹w¤Ô»ˆœ5ÚÎ‹ô¼DîÓ¸Ï*C72¨p/%$íeByÿD^~¢GMÍşl½­N¾Ö›‘Yy	åµ±ˆƒËÑ¸Ï¤Èéx„6ªªı¿¡ßÜ}•‚æíú
Œg×mZr0«—x+ µê„õşàğ“”IY‰ƒÍ.…ÿÑ‘ıI¢–)î®[0WŠ&r¹y¥™=ı¤Bƒ{¾ÊTAdĞÚSá a_Í7ßRQ%*6nçÑ¥FÅÎï==˜íí_ÊqwVmo¥îd³œ„ÿ~ÁÁ#;œò¼+¡!|ÇuA„,“
	$ë¦±8sñÆ÷M! Èy‹Æàº©0}svÂÂÄ\­D2i2Ÿq‰ÖÖÑ‰®ùÎîVô­lXz/°ƒM¦ëaJÕ3½Šü? ‚í!=½3ôŒ¦êJ~¿~1~'&)‘’ËXæÀ³–ŞW¶ x•°ß®M¼°­ôİvĞ½…Õª”9ÈØ±ø‘¬ëé§0²uäb˜6GÆ¾|ù¸ÒÏç—úOá *Æ¥VÅ PV†¯»ç… QQo½‚CCK¢é˜òhû\Ôá®_›@¼ª¹›xVq-iOÉ­bLBzôlJÆf Í'¯!ÅZüljOKŸ‘‡m
«¾;ú=G[»É].æ	ø–ÇÿLëp÷`cád¢À£íÈ=ğpX)M¤–ÖU0»sË~€6¹ª›,èaµØ†2¸GŞm”ÉşÜÔ^pRÆ\JP0¬&¨=P¹–™‡^÷(e–Å¡´û8M[J0Ìü+°t¾d“ôqhß˜Şqe~Bùíß¼+éçDÎ`#Úq	Ìok¦Şjj1Ğ˜E¾ùk„#ÓâV™ä…İÚ*ÁA¾è?x©‹¾FâîYIŞ9|rh7¦pÔÂQ—©¹½œe0ÆûÄ€Ø[—ÁÙñ¡¦  —Kt‡çŒ ÌŸ€ êßÄè±Ägû    YZ