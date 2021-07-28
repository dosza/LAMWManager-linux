#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="557838130"
MD5="aa7f3d5bae05c106700250d5cf75fcbc"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23364"
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
	echo Date of packaging: Tue Jul 27 23:00:25 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ[] ¼}•À1Dd]‡Á›PætİDöo_‚Ç‡Ñ‘«Sğbu¤Ê/Ã\rNhÏ-~ë›É’²CË\\>å‘S‹õ*­}~]Q¥`Ø4Š¦ĞKz„MôÚÓÚ¨áA=íéšö{ÛE.? Í­ú,Ù—d%¡ª\'‹5ˆ¿rº†QïğÍ£Ye¯;ôÏÁbGVî(‡œöÊÓ‡ä®t“Êİƒ+“AÃ´xNkFĞ)*™~ƒ°‰°N8mÑh7¢io,o):“"½jîà·ê†uzjuçi›[£tLY ¥u£=ôîÔ`„ói@—ÄĞ£_åû!†Ep¾†s@¢óZƒlıÍ}ˆÓµVª«ú$ÌÜqEC™}†lõVØÄe_ı,8çÆàGÖñpËDŠ×dàÛ‘8³ç"Tè…ây¬h»Æá@=N½ãoq«¯7dğF™y·¶HÓçM4‘4?K =ÄÀ¥­ãXĞ÷2á›±t/O¹t;&=Í5x"§;ëòİŞ¥Ş7Íú©¦Lááï¬ºÈwÃş­Äåhµr³l<÷«¹D<åÃ«ĞÄ£]o'£øæ‡yî^%6)9<³uwÂ›­ü½ÌHSÂÂØâ21×/ø/yi/ÂÍÒ+~­5¼Ü:ôŒt£ó´rÛÛ£/¼àêÿ¢]?Ôçx$¹¤k|œ¢¸kœî)ëüxôH3¬·µz'ùkòáşAƒS]V˜Ëjl4_¶¤svÕÈá‘ç… ."XÔ:/³ºÂùWÊç/Èk1ÉEÉ©sã±5øÇ9¾}>>N#D'/«[µ‹,-}$¤W+›>^Xû0¨½?G`S_§27¦h~àÏ[ å–kÜèJj²ªš¬ZrÒ_¹ÏÊQ·3•~9k_FÌ¥ÜÀ7_Xe“_bã¿=z"/O,³**P‹˜óIv¾õ«Ò”†.ToH{OÄQÄò|®×«äùçË8l›QLG~ôq"-¹	r[Nä:Ø÷!¨*^ZŒl•øJ.çBÔ3¢U~Æ‚D–˜`:Û™î€ãñÏsb­‡æ 9æ¹¸ÈõÔëM¶ùvÈçÀ§Q	 èÍÌõä
”$W+4fzéF–Â"R²Sóßì0èùí\AR°ÁlAÆñï•SóóÖ›êÅ¶‹‰¼ÿÏò³ãkmÏŒªı»qLQ§˜dç)‘>ĞOâòvA^Ïyó-UY¹Økëõ–jì„z1ş-²k=Û3Ò=y&ê@Íª6Å…šCÑƒ7Ù½…j?câı“ª¡¹e³ZeZ¬¢Û– ˜d<¡ ïèÊB÷oÆ\#xw[ #|}©àqBèƒ­CÁïßœSo”Ê‹º@ x”4~ëÎñ{â÷„ËûÙ¥ü´¤.Áúç~êŸæ@³ÓAK‰á®º1ú;)Bªş ||Z³Â°*|Ìó`â^6ÏºK®IÎê¶]úİ(4&ER0‘s2¬"ü2¿3]óúi#ßPÖ¸’¯eÅâå ¤^´âƒ{Å	«§@ø’[İ0Lo¨@E?cƒóG$"ìãuTô¸Ş pf¶÷†Á­;=¤_’üŞd"{01RsÅhCèàoâË± ÈÁ¹Ëx7š./9Z<ÎÏŸÛqÈTgé¨½¡ï^ÙWVvC.;ù‡aà:zÔîgaâ~P;wB»nzı]ìZ„ôA÷l;ŒP6eUĞ8Yí<EÊâùg‘/' ùpÿÊ¢$ä5•"ß@‡îi¾ VîË<~‚XT™`ˆè•¯Ó£X?ãê°ƒ˜…cK–Hu…•Å³áMU£Ã6wZjœªÂŞ9“j0ÛÌÎ?w&F‰ïaÅ ŠSÀ®94ôxÒª»œqˆµ
y©¢/‚ÁáA˜—C˜¥ŞÖKÀ½ø’²Gc'ì“rı9>UÌ¾ˆŠ²¿|èw@ÙîäÁÒ" Úsß‡#z.nAO^ä]óÔÎBİ•[²Xî5³p}ö/’ésnCóeèê¹@ˆûn™ƒº©§XhW·Êr}ºÆÓ28°‘ÍëK0oá.[İ7÷´Ø¸(f£Ùü)‘ØÃª‰—Ëf7n7—‘n›hõ§ÉÜşÚ.2ÆÌ³Ûw³ô„rt¼xg Èëƒ£lA8»¥Ã¿‘Öí1‹·d"è¿’ÏÌß/ª¬Ìf¾Í’×
X3Œ°‚-§æo¥Ò„™²HdPÕ@¦­ô§“”ºËÎàÆ98Æ¶=”Á)Ò=Øãkbï"3è1–$I<0•ltŒ]`,õ”ïşbÀwz!cŸå?0çAôÊûóù”ÓeúËçr.–{º&^E$%¤èTPˆ©<êã#a¸…
0>Û¸Ä t{á—>Ø²¶´æ1Šxf:ƒ>Xq‰Gñ3ã#<Ç>ï|Àø'^Ä¬š•k·mÎP½¼›
t+òÇ0^Zc˜KR0{¿Ö¯O2!ïY+UzZmQßéë4Û}2TFÉ$Ê$^şVmiüÊI2#gm'Ôö!ÚÿË¿‹q„èÉN ÷JPmÑ#*ï(q–D17˜BmT<Zœ§Ëà;Qi·o¾6ã÷6ÄŸ^‹å¨ÜÈèCĞ<\sÈÙ X¯[Ëh+–X,¸
È †ø,T”åş?&HÑ—Ôßû&pÍ^Îz_ËWã<¯j|]Cë‡ïtunsnT%N7¢ ë°wê„:½úm›òÓÇWV¥5IÜ7<æWdÕm„>&ƒ ÷uÒs…/AZP-—¯Ğ0÷¤ØQÑŠ¹`2§6‹ôÆ‡¼İöÌPõÄÔ¶•–Wª·P ÷%„• ù 	ä²Wxşò€€zşêê#LşÓrÁ˜²Xÿ3üã;•€bXjıf•]ŸæôÍ3i°ÂÖ&¦ÿâ–ÎxJœ<‡ğSpcCíY0èt9Ğ÷]ÎÎP}:v£]çĞÒ—¹êûw«_Âiñgšóñ<Syú2ômØa¡\t?€ÛÙaÓ1ê¯\ïCÍÁô¶	¦¯.Y‘(Wô\tãêÑRŒ‹pÆ?z%#?`nyaó§‹ª6NĞ(ÄfcÉ3Ç}—¼ œf“Ø;»¹¢=X?‘S@ƒc«ï¹õjÑçLPÔÏpš  ïlšäC+nÙrßVÆÿÊäá*gÓ®ÏAr`¸ÄM$+Ç¥OF~ùê}oHB*VcZêN}­jña\éı €Ù Øf€ıÈ´ÁŸÓiÀl\*æ ßF‰™zéÃ8{PÀ(%ßf¦~‹jÒï›gÎùßsZò#Ö'YŒÅ‚R×ÿôRãáØœÎõ–2=ÆuPkP¸œâGDä¦ù9Â`¯±ã‚«1V:Œ§xÎFš=šíˆZ–/Îˆ™èéëèÀøÿõKqÅ?5vá8Ô'ôp]n5Şjn’œWèK%®TçÀÊ|gö•ôÔ (ƒÙg¨ÆF¶Ìõu;($¬#\€sN…ˆUí§º#ßÔ§kš¶&†0ñ à^­®§£ú_:pà`\Ã»¤òµ;ŠeNÛ#4rà‚Ó¯úù£^›ÉnVZ@Ê±‹lÚa$æBÜ‹Š­†©êûkÈ|¾Æ/$Kíêã5É'½,O‰¥îk{2%è\ì¤R7u+¨Ä°ùg„ãè{©ªòµÉ÷hÙ~ùœB¾•³0ÆÚ1MOúœ®÷²ºÑL6R†¯kÂæ “:{œŒ7¦t/lo!v{oÔK­r]ÑÖÇË«S	Q¡Š­CG×w†?÷:r‚Q‚¢cCPéäŞ–hj¼0 Îè
ëzî=ä¹!iM3Ho]1çZ°ĞŒ`Ñ— ¾À¸U ƒ£„|ş.¢!3òöL7iè¹e“$‹Kù®˜Û’kd¯Oy¢]9¯ı`Ğ€^şQT²z¢¯:¥4o\)¡>0ø2œò;«§¤«ï›,r fÇgb»¢Ü¿·;³d‹Ä‹ë¥±Vök:¯ŞkÀ›6¹.­xU¥¹éöEĞ’ïëÎÎmÚ	‘ˆS|Ğ¬&È?CÏO*íŸõyñ<:ÒÏŒC:‹£ZÎj\zâ@“Ú9»Ï„Ç%ğ‡½¼‰øƒÇ8Åøm|1=Ü“;Ÿ¢”jmÜó$búRsÍ’Jg?P>§d«i9ï½¤t›ğàÁA•÷k››QÆ62	7ü5¹“EcæûãáÍğ‰Z¶û ¤­~W¡à…)İ:ÓüÃ·#“õ­Xá2”¿)äs®?Ó
6Í›p[¯‡ÚãxAÃ¯-ãnÖ:””.Ì¡ÆœtA–³–c!î«şär
W:ß+UEl‘X²®6û«³aéGÊšA\3}l*Oë€z±n™x£MòPåqmB‰9ªRHˆª‚ÏôÍÍôç—HfÚMÛÈ5	8¿#R %óU)Ï€.hwÜyìR¯wŞR"‚zÛÜ	®õ%éìAN`r³äà¯ÿæ{Ä	£t:¥:ÉjÚÌ<‡éBí’V  Ş&°˜Rƒ¾¼6æïµöC@ï6ÓÑ÷3óÇ¶aÃ<-©K;¡jĞq0›|Íš x§XË	Ö#.*ö©Î2ŸiÖ“ıäDF›ük4Ş†lE>®áÕrÜ^À¤‚W;ƒ¥5‹à¬Z.‡–eĞÇº˜%¯«—ò®íhL¨N%Q˜ØVèÿ‹9!n~õğím¿2Ñ¦ïĞÇ|¹½v´Öy³9+æëLŒ®h¿ ¼O_­³Zxİ¹ëš’MFòred·(÷ã?}•‰snĞyÌÆÃù•ú½«Ì!0åÈ•ĞK›_näïk¸]k*V9Gğ)–YU$&¾q0mƒ¿p!!¥¿§ËQ3P¸yWÓE^šO+/üª:ğœ.×ÎIä./®;C¼+é¶qãŸt´â¦KßuëûÒ¡0Ä1Ô(Œ sIê‹}â>‡bµB[iìgßŠBèß9R™~p¤æ‰	áo#¸;:ÒÙ¥ò›Qõñ1ı0qdŸnYã51o3óW¥ÿkmpn‚;~Íé3—Cs_=5áª|®j¸­îÂÂ}ºã„Rb¼ƒ•…Œ(ØRPÔ¤c•Ù“¶! TSgƒ(q­-zåÕ@ –Ê91L´4¶,·ÏW“ÍîÆ?·ü”f4Ù9¯¢ô^îò^ü$œÁØ/Ï‹T‚¤—%Á?ŞËl~¦ÊÔô
‡*·Æ­zb,ŠlPa±ó0Ï£öØLè¶¬$ÀÚìU®Öû(»áT¾vKI}¥Ğêq¨¸<ÀZÕÂıIÅÅ†æcìà¨ŠL“EÓX#?3*<ÚmşGæ‰ieÓ^<õˆİ¿­‹J¥õÛg3óØ±‡¾¢Ê#ÑÄÁóuZZtòRé‚§ï^¯“ Şò
VM†\’W¢ò$±@ßºUt’š+äái/H¥5œ²êMJD$1²^Ê> e)ıëm!–vÃxi µ9%ªff—ßyOpŠDë¼ªø‹9]ù›DŠLleµ·÷,tlD"d«ĞöS(şN*}£®Ã“ŒÎ7	WÓÏñÏƒb”©jÜ!}wÛÚ
M¡ÄFòÿHÿyF½0‘Ñg¿	®Íi›&9'3ÈæuìºÖ“d®CÁM+å]¡“åhÃ6‚ª†˜ÿf€RVmÄşÄ!ˆ;¸·B#şÊ]êäã¥ãp‡?ÃµşbÌPÃÓÿÇÀe-['€‚J„rm2¥¦DøDåú¾>=°&ƒ~L¾|+»Aí›§Ä-ö’Y¬)ñlX·2¦‡1‚_ãˆêcÍeÅÑ.$ª59¹l'Ó˜=Ùâøùn­Iá*óg?MœìBîqìqncş|¢ûTE?ƒvÀD¯jNd«¾¬­xqØ—¹„š,`sÄ’ÿa¾¢	G\è¨:íÍ-+…ÿ>ŒÉÁf¤üß
—‰$¬Ş7Ş:å)>ö}°4Á¥1Bò­×}W#§ê9êé‰-1Ğ÷Oa+[U^çê¨UÙB²8Vş^µ¿Şş¬—Tµ½Ùù,¶“‰ŠÄ]^bO$·Ü¥V§ßiÆ€1n\ØÙQ| !”¾!ï5¢Ì$%fm€0¯T€Ç‰çÙ†-0µŒF	¦SJ)ËaÄ{¸ºBÎv¥¢;†ÈC÷¶&â>PN¹HüìZ•I­ƒéş¯ËfG„pù½Çl¾“hX›(»¨¾I)R-ÁüÙ£È;ïOã á7®ÛÕ½ºŞÏå‰ôŒOÕÌ…*åÚú+Ş‚x•dKsa4Èµx£o)jğ­Ò)mÛÃÓUÄ€¬?ï7+í]¼¦r§ø¦µt0€xúÒ"0½H–o^ Ó×zh¹OCÄuKÚ)_èäÎå˜ã&pĞL¨·âuúßø5¢]Ò“ı_õò,@;E R¤ûOĞ„j­€yqÁ‡\Ó«ô4QA§H¼N,s~·œQJã72şHnåRVÕü
âáª¸×TPYósƒmdÁ–ıá@ZfP™ÚÑc/xDË"Ñ)üÖpî¨â@W_£e[»R£:? øfƒ;éJŠÌŒbn"Æ†ı†òJ¶É3\¢‹HCÇ¤õ"T÷ƒ#K[êmî€šÉ±ßÄcÿıÂ)L†&´yM^8He(aË!  ¼Åê¡k3êHÉ”=bÏ¶±ì#;uï¿´E:ÓÁÖ–XÌ6¹¡ú2§ˆş?û2¼ˆz%Oƒé‚¸'À'Üª–]¶¦6õŠ¯ÒŞEb”‚Ä½@§µÏÎ eû.Ê2ÿ–YøQùç-´ıfäœéÜ¶ì‘,hªÓ‘%BBıÛÚMbá¦MJ6*	^R/p¨Ø]èe4Öš^oÖúèñ™‘øÜÚân¨ìÌsû\é5/£3ËOÔÈ¡|tOé£7ÄÉ—–>Rª¤3/åó#İYg¡ßpñõL§±¡Çjã5zV–eF´Š©•Â÷à¬sYoaFf-,÷æE—ßM¨êôNˆÑ>Ù(Ï-:§†?oÀÙÑuÊ?ÂÓãf{~hH€îî†éöœòD	bJ=:‘$šurõÅúÀ¬¥ÎÕZğØ;°M«.x[J~=``gIBd¤Êu)”5oŠ°>bÓû]:3ÄË+Øß:ù /÷xËİÆ×â…é¸½Èhü«‡“Îy<Ñ¼uü½<i½˜#•ÛÀ_Ã C<Ñì’ïº)^‹uÏØf/ùp“P
†(ÍÌüÅ3_Q¿Ù¤ûMÚÄÊ ìÏ7Tõ'Ã„"Mì=™A¸¥ãhëòíÀï™Ù>‰‚€ßE®é¤9¸2ú7ærÙà„²­—‹ÂT'E°Ú¡½X8øîÜ>4rz¾÷3óKáë•ß]Õ&Ñ[ê³ÕÒ¤<•[ğœ.OV[Ë3Á3×ÄêD;c!í•â¹¿¸€Ô¦Äõ$§ê!+`4¿u®ŒJàQE/VAu„3eŒÔ–««m˜$[_N˜ûXëíœóşn=
á~#ºh¶ƒ¾ğ†Œ„Ù­îY¢ÿw­.ş¯$h#ç€ÍjŠ&š—@4—t)¯LŠ@gÊ¨à@N%&—S.DYä"Ô\~.`úñŒ™­ÀxU'!9n÷Õ™Ï¨¡…k“¾@å9~ùƒí
WdºYÅˆ]Œ6}cÊÒ‰Q{c/ÂYÊûòÂÓ Ú|­ì?¼%"_`ƒZ²]"tÑ³ŒaN òÎ)GAO»¹˜ñ`ü«D‰¶¼>ÿIÅ²3YæÙ4†Š;ÒÈïàw•V²òg0É7|„	ÆÏÓn*Dš¯¶HXg%›w	Fè^9Ãq¶_ÔF¥­©ŞwÒÍ³2i\Fq×óæ¯6–ƒ7óuhß\*¢Ô¼Õâ:ğ†ü/¹óîùÁ©DcöeúG`-Y|nc)8°¤
òèfz>K•%´â)_‚ÏËS‹Z<BKj3bAıíwÍRJx4‡ã§2-|j;G©ëŸ”-ª[â}ï¡a6BGGd9<ô&8áJ×?„æoÏËoV_ôu7Ó&ŠúñäïÃ+÷Ìo[ßÊ‘”0Ó³;åİNÉK$à M ññŞ›PÏ¾ÚÀP”Îš«_Y4™Ã¦SóÔ^8 £KTmà•‹øèÃ«ÄaÑ‰0}†éJõˆrëğ|Dt` Ã=äÂè¤@?ØàGÌ\µÛò2zäİz+·¡-“£Âã@'aUŞ
CÈxÄ=ß[Ø^gNÀ¨@(×ôdı“—ÖòÂ{H]Yk¸ãƒ¶4,Ô\®ä%8”ÂrÅ3ìj S(ÌªÖş>5šğÀ›}Í;*ıHBTEŒ‚hĞN[h~$¹ã§˜T-+6Œ€ÙÑvĞO›Ì³5FÇ8z«—hó[TŸcºÂ‰A¥ZúêlKTÍÔ¢ì]òr×;'E £aİ*/vãÄp
$œ§éjşaš¹j›ÂSÃÍÒ!úš3vF/cµÂ3nE’»²N£øßª´M³ KdŠóe$Š,ì?¢¡ÇİøÜ—4^èETs‰!rLú:Aùè^ˆ	Ìà³8@­’IëÊ$&oÑ1|ápèÛİó·ˆ „Ã"N{ÜæA‘Â=àşÉé©bl1Œ¹!ë(.‡ù¸û†VYA¶·[êõåf'u‘„¿óGš+ã¡—¶Hê“zö÷
‡ù*F|“  Ëfzù¬¶åĞ`Q®üdpt\¤7øK,ê‘
Ù˜×>(€€Û	‚UâàWò]ã!ÁÃå^jZJŒ4ìE&CP¦?ÒHNôRÚ(rEëî€µµ‹NµŞyšFLqa9ŸÚâªêoqz&r™nz˜,?ı>'w]Hx.0ÆŸ¢œĞIóqT¸>ßõÈ…>0Â+`şäø„âëõŞÅí
°%tãŸsÃ]¥NãA„Ò 0ô‚$šƒŸÌd¬Wà¿!³¶„¸rì¥txòÅªHékªkĞÒ':i' =ñ7Iusş´ÈÄuX&åhá‘“z+ñ·PX-ü¡û(ÆîŞ[œPÔ7é3ÙHÿ øØE«5aÓër<»¸tO„%ËY \•Æÿ¼×§ÖMAÒ‰BSWº¨ƒRõ'ÆPÏÏÀ÷à2h/^Š|<ş	%²õÚ4ooE··[ó?)çÛnW`²oøÇ65rãKÜXÌ%S_ÏvQsëÄêD‘òw"R²—»Xvî\"ı0”äXàTÜÉSKóPø)G!
æ§ZÔ§6!yÖ¨ µûøá‚Ü¸Ëá¢Gñº‰_¸aBº;,,µÿ=ü	Iy7	Õò”X;eYÕhÖì¯ÄäªÊ¢—˜*î«
rî^MW@_wP›ÖVTŞ!½ôÌ<I $!´‹w—`¿Z–Ê&£§î¡BÉ¶Ó÷œb']¤Åumä™òk(†-VÒ÷W•4½!"¤CÖòçŠ%4$-3½jÆ¶·Ã:¼#(ÕYïêùÕlË`æ¸1+Åaû]íÆ˜­­Ô‘­'¦c˜“‘Ä$lu£İ1ÎP[î†ºKHEöØl*ËİNğ¾&M¥Ó€¿™«¼é,K=¿óCÿ<‰³–]OëMÖn‰ÀÌÔ$¶êS0FıH¹lÙ2hå¬®Uñ­Wğ?lCaDëà Iv}L9,
Äi¨ôì™ávl…õy…ŠhˆWL
ú¥Äß²OLş/¡%tÏJÉIÑPÃréiLEGzêR WÑJï5=ã£%òÊ.£!z2½'.ee“³„lŸ¹ÆÁÍ©=€4(Æõ.»£>YÀmÊV¨æù/.$*s jÒŒp­KhÙõÒxşÅXu¤}×ÑƒQ{Í[.N8íÙ'©‚¬šsÊJ85åâ×81ÃHjû·Uµ˜ÅÑšUµ¾óDé!?Ôş´<ñÓ“ŠP­µÆ[nŠ… ïw\d¹˜ã»ÿ3ªma+Q\j7`e[çÑ^^kˆ‚|_şBkğ›WYˆ×cÕ•—ˆ”JJÑò}	îyqH ÖN¢²ãàJŞß¬iÅY¿»egi¸A»—gAîÌ]Ñ°{¡h,×šcõ¬ï&­<]¥“+õ.˜ãQÔâ
Qrâr¹ÅéËóˆVˆˆ¬¸Ä²¸Ê§®h`‰Ë±¸İ†›ôæB¤¬‰Ôx$ğóñ4…_†äøÊ%õïrq´ÇçR-Jª–õQDş~™i£“89˜´xÂ‹ŠMœÇ‰ï)ñÑ833“ĞKñbœğqÓMa”@âBÏ
ÚõKº!Q„“»œ„
Œ¹ü×â*{zìå9¹°²Š\:“nI¢–ZìAÖ¿³³¤b‰jn”¨x¥Ké'®7Ù´Óç Ê@î:ÆäŸLêÂwúÆÕ@{±Ö#…ô…!¹_–Ìëâ2C]Gƒ®±ìS¨Qo‹çÉßÇøÖ«Piq€ ­Q™Şb­WôÕÀ,^ò°nr¾Ì¤ŸF¡ëFl.óWñ§Â€åƒè@zH7tş£äÓù€øåº(5îæ‡œa’Bƒ¼€0ï+ß:÷¹ÊGË65NS,”*¢º‚åÒş%D|è€,ËNKsFĞŒïKø.r1mÍVî’Ïƒ¬X hÂÅ…ãOÛ“¶™UşU#|ş…ÔcÇ>¢g{È(£ıï/»Rª+GÈÒª÷ L—‹¢óX×°n›™›û €×“Óœë3Éaí|÷vŠ¼«¡#1ñ•U²ï¨zkÎ½$®©éÏ³™sh¢:™»—SU÷Ø6Öx–¬¤©U*–<­—§ì c*‚ÛÍİ‡mî¿L=!=ş•¹à\CH\½'³M/ö„28şTD*oÂi¢Z«fÛom²‹Ïè30â:1`É
?(F.
É¢ã²ç¬	û“?âöºUÓ?˜IÊ|l‡ÎŸ^ÌÚ,¯Õ™e2·°S>c›>/“ÍÜ«É>8öJ[NÒ¹A<W#òhiŞX³™6GÅN?,Æf”Èß_É˜Môékìw(‘í/;ğğ§•gÕ ZÖ>¿ğœ±¡<9ÚÙ*€©‡¦.Fp—(|Ú*J¬ÉÎ¿±ˆ#™kpãH÷¿Rıó6‚Ë É)óÙ+ƒµ¯fN¤ÍHJÕ€Cí9GKC”> D#ø^vÔØ‡fÍŸ;ˆ+(ğ*ëG”»gî¡~ªòß#H¡$‘º(ÖÄ>@ªGÙÀmûÛàÎîE)ªå6;èóç,•ÎØzD'"B@m ë)U^ ùšÙ$W«È+$	íg¦a:€0PXérµÜ{ãÔÜ±¶…+‚“…¥ÔàèE™r¹ §yäsCÃÅO?ÍÏ¬ùäĞPQ®é…C°)Í .Ìñ1Y¦.{ÂÔnr`—’dªJjÁWZK¬9iîQhÔ‡’öqliõ›jG+}Oûğ‚ÿ%nmI»êCG(îpÙ£Vş(` A`I¡v>$Ó	"“áBW×9'[PìÉd*wÇ5.‹ã@Ñ	á¨g.¤I€ÜàßğÄš¤/R5^Ô’>npJvÏÔİÊv²V·Ğ!iÑÑ‚o+öwrË>fI²©ívf^t¢Q~?†×ÅÓy^Rø·:~[?ÑCå©7íšn"Gñ€Bäò'2®gäi™3¤Ãëj–ÀÌä…[Õ´†vVĞ L49ÆjÓÈPM_ù2é:KoÙ*drÈÒv©Eà¹ÖÔÉíÛ à·j}GÈ‘{ı sŞÄnëgäuõ‘ôÍµ„ğzP¥Ï…Ñ÷‹Ÿ£ĞÙ@›&0ßXDi²,ÆÓ|y”å(3_xÑ™¥ŸwŒy`é‡€Fúúfã$,ŒZŞ}™o¸‰'ßÅ¿wº Í­1-DJîKKŞN´ÁŸŸÿ–rÿ'yÂƒb¨çæ-ˆ^¢‰ôBo`Ñ_ßşe¾LóDÍ°¡&	Şf%mã^)È bÄ~oBÕ¶p©‰Zc>€9tIb'×M,çië}Ó1qˆËğåYõT+L¨…Ò00G}˜¬d]MRô‰Â$3F(m2®êè3~è”xÒ¹Û>î`åäçšI´«r
k[kşµ—Û|14èÊ¡4p£ãRò0Ñù³©qÚëC|«Wç2zú;àr h—çı'ŒË)("±8ÿT[,ˆ£®Åı”L`O¦—é\zÇRÙh_,áÁîbØâºò]i¼ç²Fcë0ËNÇ…FŒi\É!°>ñ¨ˆìüe(:xÏFWÂÆDıÚáJÚÉåAä Š[lÍÇvölkR¡|Ùz4Ün­ŠÙ±¿:¸Ğm™Æ¤4Ex!}<X­4]êú2@ÅîŠ¢ªG4vsÑ~gÓPcnMTÆk½Éí5H8·&]ıã§¸<Mr]…øê)hÚÖ±ÆË1J•BRÏâ/‰¨²ßNÁ~ü˜¾N?ğ¬d‚.º1·Ñçúè[¦ÇıRsæ.§æ š ñôú°<ÙUÿòBŞlÍä!h$ÂIhxlZ=	Œ„'€%7Œ÷·AÌ?ÊÂDÀdâêt¹`oÙæñA<Š?p-«´R8‰N’(
„|fÚ/~…âE2t˜—$[)*êU—‚SÅ©Y¡Ó=Ô–†_²jÀ·Gì.Jïv?G(}Ä¸>Ô.MµëoŠ¯¾ä‰õE~—Ÿ{2z]—õÊ´7º·úI”ÀØû¼ˆ™i¥õ8¸­»)Ô®i°GCA…ÑàË^õôsv÷Oüÿ9â¸¯Jc¥õú7—ş×{—NÉ üQŒ$9¿úÆ¦ÄÔß*w¾Õé¸I!³Ç	àÙïÓW€{G$cä-±ÿŞÕL/SÀr{3ÌöÈu·^Ò•UØÒ[ùA5¬!‡)2÷&6ÇKÔœ^¾lÓšpäòÉô„qñğ:™ymÊíXŞLZ
è‡¬ĞW÷‹¡Su ¢ËGE1%Á®ë~G¸ Pñ«áSYJï0ƒ
HZG](†w]`4Ùì@úPô«éGd­¶®…-9¸ÆUêfVô"&›í´J„»’	(÷
Ì¾‹'’ç–PÌ¿7^ë;ÊÄKÅL}ÖÕk~væí¤Ö nò1›Zp@>ĞKÊkÒvgŠK«û*±?+{•°4Í KÃßòGÇ„=Føä';±Ñ5„¾ƒúØV–;Hõr³ë—[!iªÔQ»ÁnŒ1NaÖfX»8L7
Ìö‘YòIŸ×wL	ŒoŠu¥2ŞâkÒ§§<ï *CâÂ0ÃÕ£l…õ“(=íoáN^ĞËŠ öÓ¿?•ƒ&€<àu3B¹nÆ<ğ”—†¡s^O
ÂÍ®ı€ğÄ1Çeøü]'Œ’€û°Ôÿ]Qª4£T6!Íé)².Oˆ°J$1zçöaşìdƒX=ö’3¤¹şz[¦¬emƒëëìêĞ»z»6Kw üi Ä¬}±j+ş6Gs@0äB¿pùÏ ïf2^XHÚ¡4Îƒ»µÀŒr6‰%Ö%Ú£Îğ"ĞP ««á\½cjúì›OÀ+Vj½ÄĞ¿}ì£ü³¤Âş­úšh[dëË„şã.¿û ‰¨yAë“[ú	àAÁA†
¬fÁŞ‹°ÉeW8<É7d?xC>Tïd»èŞ¾À§ûÇ{î*ûÒçZnŒ?›/¼RëÃ[—Ğ]JŠŠš›å¬Jõçc?óF©i^ÉÙÉ€³e
÷ï‰çû””Ic!	/9+nç‰Aé41^¯hÃ”ƒfÔ¹ïÁkŞéx“xî=r„ï°ˆıù9Ññ'±ì½ëÁ¹½BB0_Ûlõ‰«ßí3ŸL©f®0ØwµÎ¿ ü3³Á_DCî³§VÁ—w_tñ!Yt{Á½v £p¤»s+–¢ìµ/î+iåL2­ÂC)ÍCF½#w—OÏuõ7ÿ:kØs·KŒdÏ(ñs ×Ê¹åBÔİ¿¢¿ySÚ}AŸmçƒ@Q>Â’³d¿Ü;†d»“tÜèñ%u€Üî@'ÁUÅE9ïï3ªHÎa•°£ºzµVZ>ÙÌ€?JDÑ®.YŒÜï_;Š½">º!æµÒ%Oóa•ñqÖRúš:c²IşHÚÿ”CC°êöMkªSÄ^~¥xÌÚL“ìµwG8ã¿Mõ©™û ;¦
Zè±ñÏkş20Î™}vœğÍŠjğ£³iœcùôÒµ4ÑI›9ªøÑWÊY¼cõ5ÀåJ‚ÚTš•ÓÔv¬$*äı~:tÍ½4j×b¸—J¼$¤3¡:HıC€§Œuõ¼Ìa01tœ0ÜİŒ5æ°}#¬};Ø#€sCÛ~›Ö`‰HÖ‰Š¥2;ToktòƒX[Á ß²õÖÔìXºó[ª[Ø%¤÷ü˜ÓÂ<_oÂµEqu˜# «(å—(ÖÇ¹ûîa¿–j®-Ç“2ÄH¯ûÙ:]'ØÅÌÙ*³¢µjD ^c™é0Oi˜V[ÈŸ`	?û!¶Ğv¾Ñ+ª¡Ñ(ûëí+ğ§³×Àóö‡esãñø¦€İK˜Èß}çDw¤Á6?(æ~y½#ÌÖ/%=J08jµÉNI‹ùYÖRJJ†åñ3VÿØ’gcæÎC/‡ı¢kÆ15œ!^ ‹<?9îN6{gŠ*ˆÔV­q1¸“*ù>1!èP½ò^IL;£ĞFóM§…}(äˆº¤A¸L¡é^Q>U“Z7~Š¬ÎløüK€`´-¥Ñ<|‰©5¶
´=¥²õñË’QáP'Š®G5¥±$_Ê]Õ)¾.€lŠ¼›*­òôšóÁŒlÇú›Ë7Rp¨z°9P²1—v{-ƒ£~
~xç‰¼ÊWQ_“´g©ÂyÕC+¦¨¾‰BŞ+ÕFºÊœ¾Ku>
ešÀqM¦ã‹r}U5tk2Ñ,}H/Ò ç—¼opò†hËâ±ò¦Oæ3Ãµ|áò¼Ÿ«×ÓÁ-Q{O¼¤¨ÍÂS@x”ŸE"f"ª™5õL|Ì$„$ÊâNQx~é@àª[rÒU[c¹õ~ZÍF`ö	Uwób)•yK™]¯Æj½†>CŠ~Šÿzzr“ïàéš°k~ÿX™TgNGpŸORO8"A¹ÚùĞ¸5;Ñje²×úûYÆš„ŸvD‰Q%™rœ5:
zt	ÿÁj7ÑÄnõ7r¢/r¨B;ÑD¢†Ì2ë¬r±ÆøœeÊp|¦Å©İËåo¾/“´¢Ê—fut“TŒuÕF´ª¼RRä°oa-ƒğ;^[ o#Ôgë›?d„5\–­G`×è—÷ß]Kœz-ñ®ßí”·ƒ‰âDørïö—¸=¸V¬&…J;EfÑR!Ë  1™´Ë@““—ÇN%[¶Iä†…[Ã„C`moËuĞWvÕèf¢¨pˆŞ>§ ù¯ÃúRË1pÍÕ­ÏÕ„ø)‚Œe/Õ™ğbIÖÙ4ö€zå¡“µ!`GOú3Y7 »¶…7êîİĞÔ¨‡JV³ìmi9Â®…Ay`/åš¿:š5ÃCÍ›ö?ùŠ}—ŸoËä¤êlnĞ§Áà«u\CIĞš÷q­	7M0ã<ÆIIx‰‘‡¨·+êÎ‡[&Ylàm±+tâUºa°²WÚWc‹¥ t/† <ˆ¨÷‡¿@¨'X„T×”ÃRBQ u¥ü_fjt`'”yÔpÒ5ƒ~)Vİ–Ì}K£ƒº0B­'²’l1¢Ÿ4éøãé9ÃV«—Æ¼°ƒ­E·ÃIİ“ÿfÀOïh`ù%N§ÕÊ^ <õ¬x¸í‚]x4,rè}ZClÜŠ«Í=?AHÙÊõ½W/8&Á\+F­³©vL›$«ÆHs ÈÅŠ?Ü+Ûµk}8‚Š»’ICjãO5Æsø®]™®ÆAÒÉ"±„’K÷¥…BNw»w	ü¦AÓ§‰0øLVà àYFdµúåˆ×Y3ø^ëÏVKôĞŒ ôÚ_ŞÌÈ„ğ6‚1»!/ºÖ‰2¤€(Jë] ´1!ê"‚ÒWÿp4#æ	)¦ÔàªÚ g‡ó-ºy™z_‡DPRilÍåö¹¹¶œS_lp£•&»¿ç&µ´sæŸú@£egÜdc}îÈSÿ“€ô¨ƒØáæH8
’#AQt	ÓºÎ¡nZÑÍ¢÷İÅïuóãQîD€\q©um·>~ßR23¸ïñY]Dá–úHüDşü#EĞoe 7”ÏÀË®Qjj>"6µ@À€-¯4òD¿û€W§úŸÒd'ÀúŞÆd}§Ëòrà}âçïXRu`q§c§¤˜Æ©×ƒ!d‚^,¼<¼w|UÅ ÿPÓWÛ4Ügå<P^‹ku´DÛëê¼0ş”Â|5àæ/­vêRNn ¡İ×g«!èGÄ_@‰4
W.*‡…Î´Î–
lÚVv%%eBşH»ÉËç¼›r«ÇÿÈepnbòçÇÅ œöN|ÀáÎ6²}3ŸiÆ’1HMù86bÊğ[Äİ8]Gpjiå![#xŞxÕÌµD²l6‘”´ Õ@‡Ó&5@É Ï­R–3ÕJ²rˆ~0$	;0ƒòèbÉùªy3/W–©@ôÛ$°#¦%š£ûZ°±HX¢8FHè«¾“Öí=Ã?TƒÀEäf²|Ç›Ôò3+ÑsÃÛ¸á4ì™ŞV‹á)Z,*×wñÓ†eıéd0OÊºóÿò1â,.Ã¥òyÆ	!co˜e±ïû¶¡q'Ë[/«»@¸-4Ÿä>GHÊMÁ£ÓÃ¥‰ 
ErŞZ"ÑŒ\Æ1ñÌıåPó	­şŞ®Àağ1ö@‘¦ v‹0VŞ†Ö ˜Ì×8x%¾º 3!#Óïƒ}¿#±­0A{Si?pG ®[Zl*N-0Û‰Ö1wi²> ²é(wN«ólma¾tˆB¼…*sX—N¾õ"Ix£±#ã”óH“×®_ï@®½=NÑùe³Õ€Šàa¡‹÷³R´ŒBÛÓIU6ğuÚyÚ±z–j_ıT“-R¶•-ÎV@up)Cêd!øÛL(¦Å ñ–£•·âDMk.|\í”Z¿ ¾SŸ—Ëµ¹sèÿ2<öR§<gCg‘£*ÕtG~k0Ş•.wUP¤œ`Áu	 <ıv+îOÈ"İS­F†¡Jß£k?Í§Oéï¶§A¦W3.²
¢ˆ\ş–m>ucÂôİYñ×°¡è/ŒêFišìRåÿáº_r®($D‹d§~›xamyÈR7*|œÀ<3šl„}%|ƒ´™ş}‚]ÙÏÅAMFÚÒ±o/š«¥çEÙŞdq×Ã ^°ÒŒÁ³/»ÎÚ/<JX<Ã#O«´S(8Õ¨	¹wNßA¼Èzz£*óc‘ÊG’¯ÆF)‚_°ÓËô!DC´|ci†€dW¶à,™<Å:¼gÔö!Eèç¦ã<ˆÓ-n¦k6G–ÉËİçÚı
CğJ¸Â6o`3=-±Ë¤í&F²»mĞ3-\óÕ—iŒ¸ÌéÁo
ùB¿î-]B*È±ÚZºo9>†há8îF¨HNKêÀjú!¨
vwŸ8Ø$vR&ó©fä×ù„¬AˆÆÿÁÓ£ØJÑŞD¶2¶yºôõãîÀÕçÂkØÎ™=<'ûYv"è¼)1»¨4Y¶ñ\ZÕCÙP7³ø,»©G'Öš8!VYƒãÉ#êŠ˜mx"(¾ñÿƒPİkJšLyÈu7uõé,–·]?˜mÌ‹g_!È4q¨Ğ·˜Vˆ*JhnŞ<\OCw¥„A½:û²ı/ŒotßPÂúˆãğ¨ì«¦4?7{£Ëà‰/ù|ŸBâ¶úY< N¬#ó¿®ã|;Û?S‰FvÄ·<á¸k/y­·ß	áÒ¥¢Ş-×y5=R¥_¼¶÷†ÏÚïXÀÏxûó-ùÓÍı‚âäL]£@ñ5
ë?o)ßÏ€P'/%×=¢:  u÷Ä«ÜŠ ½ÏùßA‡ò^±
t4_L¤¨ËãåüoĞáw…yl|ÏÄ‹Ì|$êYt¹»ÇáÉrS÷ä‰fì„î®‡Ÿ¿=P­€× ¥Œ·xæÈ§1.“
WiÁˆ! 2¥Q¹ÏBJ>_5E{Ör2Ø½WZáCÈhÊ 9Îğ™‘ç™Ñ»‡­]?àvKC›ÁìŞ `|éju ÑÃ”VÈ~
úåM1«ñ‹(ü³¨G#i{Ù•¨¯’n„®¤ÛT‹8b¤Èr*·W„BÂd2QërMQRH1¹5 <ø¦Ïµ$IJê*Úí¨Jä& qº
œv4&¼kBœ»d€Æ©k|Sœß‚rG³¦ã¶‹³í?!î';ût/¶'ÑÕ¾o­/ÌìF$~…×AÒ^öD>¢
ôúÕµË*bNrÛ·ÂŠ´@WşœÈkªÕÂÖ¨™«æ[Y¾tÏ4Ğ8z9|o‘Ò¹>ÉŒåh`¯¨œdf¹—ãW"½¯GŠyY‘²Œ*j¹¨ËóÈÍ|!‘.ş^ëß°³ÇşRC=¢#É6“€§?J5ëpHi[ºMŸ±z¿'•ÏM¯–ğW*Òmä½u"^µ^p·éÏ×Š‹¥9„N¦"àİ'á8êü1i5˜ñ	w“ÂõeÜW8Ö¿çáSÊ—Ä¤0ÁUñ&yÂ€«¸4á›Õ_Ë-“x¼i•Š4í©ØipÎ:À^ÔœÚSYY-N†S›“ùcR	ãİ•°4Oèÿ:¿ÊŸ®²$gÎ°v…M›Ë)rVBfÃ€Ÿb÷ŠÛşR^„=lÊsûMoî™:Ø1'R5ÄñÑoU b·Åì ê§dÔó:~^(HÄ¶Áí‡D×wÖK&Füºær:}M®Óuø*8¤±âÂğ0M®u2LnWî~áûpã¹¯M$¢˜3ÜaûİÁÒ¦ZI9Z¯UQØB©I‚§>¼pß¹ê¶¬{Òÿ|°^ÕYxnW1F°½ëê²h~0Rëy~çëÑˆ·ixŒx³Š‡XÈ&.ø?Âo¿_x­‘W:?RfÄ‘.rtCb;5ğ%£µdá]³f}T NÂğeím ‰C­'¾Ø)bçîº°Ö<§;œìw€"²O92Ñòç^6´öôg_Íè#‘ë…T–ÍNU¼-]
=M€©Aià_`‡`“òY¹Œ€vƒ<@ıùúÂ4û	õ9§igƒ-=k©my‚©`Kºµ[± §ØíK[PëŸ\½Õ,Ü™—Ä/É°‰K×ûÚAp°Ú0¬;<Y$c ƒHq/ëÎ¬ …ÕZĞöÀYEs_	]Ë‚t¹y„„Rbv¬,¹DÃú«Ìk=êÅ¸§¬eöCP$¿Ü>9,'ìjtWì®ˆóZn!ÏL+/7)bŸ| s¤äÖÚ­šµºoô/´ÖñLT‹Ï(Re—ã“è Šá¶'Ó³ëÖ=Ç>4÷¯hGÊ2û¾ã–›Ç;#Åo¿–€Ğ+¤¥8úl·€½ë†W¥Il¯.
¹ú8Ö'¢Lª3Í«1ÔšÇyÓŞäáTÚyÁ²ru¬§àAş‰[ëûÙOqt=Ÿê:¤Ê5 °9ÆHúÍ ”rÒ+uO ³Gn^vnM…Çü”x7BÙ«dÆ’á•~fs»v}Ud§– Ëzğ²<¯JõğğLàOº¦é‰|øôx¶6•8M~/`ÆQş=¯8élÎ·ö—-)£²0	ƒ¤â€³m˜o«ĞH	SæYæèÿ¶5NKáğ7? ©è`ãUº[İ–šS9ÇƒÜ@bıïJ&(«Kãè§"A¬×$!é]Ğ¯x°©âµÑuğR)¥E,ˆAaÌÄj£bpæibÀKç–[¡9›ÛXÜM.QfA4Y¶¥`PŸ	—0±]&"Â›œ3ÆÙ%+€™Vçu]Ä	Á£9]•JIHW!´=aÂ6¯P$Tšğùµğwu6¥úp¯JdevôsïÀh
Q–AUÃîÌFÿúøZğaçƒãÆÖÓ8ÜSc z³ãGß™ëgCh’@ÀoŞ¶=sõÂ@âj"¼‘Gu¼ÚÌµÌFü>ãû†:¿qlá_×dµµC#ïáÂz
wVàQUoŒ-Vy°ƒî	6µgÉ3¶
³(±‹lkr‰²‡{yZ
‚ò¢X?ñÍd‘Ä&VÇ7T„‘ùHpV!Æ©¹Æ?Ş)-“6[gP1i˜ìÏÆü9k‹f6Ó%MCw$× l*ó¼Q‘¢@u˜)tû}uÖ$ùñ›ê±}iÒ×Ós¤üµn5l›Ï¾è¤òV)r o­Š+FÒçãÚK¹d,‰†oÄIÅ]ù+£0gŠyÉ=G³¹Êo²§à™˜¥¤òÓU8$^“[„éPD†S¼Òé¿j†Ãì¢ ˆ‡—Z?Í_}¬#ö»ƒ¦P]‹İ¬í~?öGÜ{j-+1b¼¦·˜Swn±ÉFõ\Ê£ÄH:­ò® åÊß„4Öİœ [(qÅ7|dÑZÏÍö<²`D!© ÏVÍÀå¢¢ôÚDk§MætÅZjV@ëFÜø³´	ÚûöíÁed¸&Uº¸5î	NÃ5XÏ·¡¹İŠ]$,ås)¦uKşc­l¸Ú(xÂÜæ‘ğHıë”µĞ¸Úñÿ2	K0½aGÙu´}	X(àœ'ªè}Í%é„—†1)Ò°ÔQ¦~Ú‚U¤E}tvy}Â<¶˜/#qy§£À½dR+€TŒqóâ69&p¼DC·_/~t›qœ+N =<·FO½Œ
-Ï	µ'²ïüc/™Uì½İ[7î1İ£óë"ñUàOnfMdO&”¨¬íi¬ÄnB3­°•#®×s“Ğ=m5ÚĞóH|ç©Ş4;3SÅ)Ç˜ş=¶~pM(J®È«^Aq‡5{ké’M¾q·®xPD5dT÷à‘ü~ûÚâ”sÿòš$ÿUçÍ«2^é»Ô‹`‹Dlgi¢¯¯š÷f1Ïwy¥Ö°l˜'sbfv’Ù˜g7Cr\Åã¾Ç»ÿ4ÖÔó)cÀµ÷1^Ş9rn^Eí´t¯*¾	r»-§è•sš»;%dé„çã«¡¤¼†RzP‡’JID‡-KqƒXæ”ˆ[RÖ’½¡î}Û&WØa|¬s·ˆ-í&*‡@†_Í|.~dPÿÄ`N_Ş«²Å¢†ÀÂÿx/Æ¦ M#A’Lz,{/­h€¾Ğš°Šh;áĞ>aè¡ÍxµíòØƒR¶ëešø%‚¬Òv­…%ƒúì5ì•ç–ñDVO%û+÷£Á—h?†HRÃØÇáG0|à¼àõ‡f-™—ÇÆfyÖ–·«·—röAû„GøÓIøÒÕ-¸ı
^.î	¬ff“+ï,BÂóÑã1
Ó)ôàˆ	Ôu°Ì]Hüûwó”ûÍI+¬Ô•ü8LZ•øB$-vV{8ì0$·ó+~M
…',ùs3Àb7ù¯•âîpJ=ÿBĞo¼)D~åCv¯ÔËÛÑ"Vu?n”ôÊòólœ¾ùú+ÒãóÈs»éRÌÕˆëU~ËêÍ GFÌ¬üø™ß  Ø=`ÿ•ÆèíÑÈD)‡»^‡aO“6iW˜rO’ÜóÍş(‚Íhõ¦cB‘—J 8ÙHcş|ß—,@¿C‘âD>lc¾£ü"&µ4âÿï©4İêÕIö–+â£è”Ñ§À*!›éàgÖƒ[ E”êqŸN¸ºÇyŸ‘ÇGI	&N*yF3øT,¾fW_TŞáW)ğ˜!4Å^Z‚1Ás2ËE\üKˆ”¬÷/Èìì%’†iƒiım–íì,WDÀîéì[éì‰*
Q¶•nŞô=$oq@@ 7‘IÙÖÌÊåÎÿšïzå	ñi¿yáîÛÅù¢nm‹ÒrPu% <qÆu§”õèMÀ¿H©.—FÓm¿:Ub$|‘&MS®#§ô¹@$sWøWqaÀÉMğeëâRÅ¡²(¸ëË«pØÎ µ©/5v`;ÁèlkcT(n­¡ä"íSK_Ì^_M–ÛS5?­¨äšè7zÔ?ƒ×µxÈà;˜¨J‚Òu6ÄPZã€1”ë¶,-Hg3Éñ#9ĞEh"
¹¢¨ã)vš²•áåñÉù^ë8“Ä|xh æçE@XŒ7süÛ›xÁòì8HêÒ /¤8öÃÊÊ¡¸®woŒŠRÑËÎ>[ÑºùV!•ğGƒx‚Ò5!*/â¬¢Í¬eSã½°jo/Æ3öàz¢úFûUe²KOzªO‘İ¼óËîÚş
À:gEsHÑ0Qt;<iäµ´€7ş‰æ`S²íkFiÏæª%—gç.‰´2ízfï·tè •ã&‰jÃ©h•p¨Ûš®uCFQŠ£DÙ°Ü quP-¹¸Ç§†øìÓù«4ŸAÙM—ô’ÛÙLšÙäµ°¡e3£PR%)êYß—àÎËVÿÕO˜›ÑûR%š‹Uñ’…Ù;uëw±öÑë”+dÑ–Qz·#?Ÿnöµù0d1ÛZ­	ù\”is%t˜JFbàPPg²GïºÇ°‚®·i1ªhaòú¬vTZ0ÀF/!Öç6BG/'áA Sí&hÆ‡¨é&†HÚHg€¼40ífávP2s1\ğûıB`?ªŸûò²r30¥W•Z64ù†ç‚Éa©ÊŞ[p^üó{OA‡AÒÜ`µ n› ~t°7`löc=´sE,É$,Šœ::{¨Åv‹’óoi¾i åKT€)*l`qü„YŸ?o“ï›ø{€·W2Zñ«:Ú*nú°~‹Š˜şïA&#MP_AøHÇs2ÛFÈ.Áó’eOX®K®Öu(`5)´Òñœ™%R]¬ófÂ¾¦ê4 '/¯³d¿ ğ¿äV±£S„’¨0á>ÉÉ®èÂdsÏp“GR%7=@÷¾ËÅÆ	6TmÔë}*ÆÍGqÌ«Şó¾xjM1mj›%Ò5¤ÂÇ‘“6émŸÑ©WµCyH"æX`vjÄ¶^i×J”€fÑfŸc\‹jŞãIT¡ŸñÃËÓx&çKg{‡ZB?şHÈ÷T<¬€ã;ŒÒƒL*6{”j=›ÀìĞBÏÕà[7Ú\‘ï'¨ğ•^X¶c9Tú¥Ó³·;-G×V¾şUZÒ
„Ùoôb•v»F ´
ÌÇ5VŞFÄe!“+âÇ½Û7„¼ğSÜz£sèy>ÿÈ;ªÿ(ÈV,÷…²Ú(6¹­mµáŒÕ
p`½,(<îo·Ë¡S¸¨¬©JwJGÎlka0'îªQl¾Ï|Ÿä.¼¨ÓaİË5[	>ùNëŞ¤Şûn…ìğàû'ÿT„rXµ¡:Ö "˜RhÜ³®šÙö1Vûí©ğèeÕÆór³¤«ÁĞ1â_Â‹Ï·‰íF1î–¼ødôA•f>%t¸Íı4nWõº–¯ıXÊ&a?±êáùs4²e©ş#Üó“Şå%|¹ŒŸ˜Ú†‹–Ğ½ÙZ{¨øhé—Ñ~=2sİèKæĞÎ´²÷*Á³¨¶º.O'ÆœÂ€óìkyŞ§!|…ø8P  ñÉxŞrU4úY ã–UcºU²ªœfÖªÑÄk¨g@«2ùWÖ£c$óL6+pá»”öÙ“Ç^ª©fl^œIéœ§ıï\gµf¢Çiö™–Msºv%z§?è¯F^İÊİ¦f6¯<ìî‡üÁ¸ñj÷èã{l=x{íüÙâ4å-FÊ´£U&şv±l‡°†8¡Mı¦Ş³¦6'Á@pÖı¡˜ÇÂÀ»æ¥‘ÚÚ\ÑègÓ+Äé›G€øpN…ü´Ò­ìåß”­°ÙøàÀà~«²H¨G\ër79â¢¥OpÉÛVĞmÂÊG’è:DŞuŠĞ÷È9Õ½™İÀ/”ü(œë}w¤¨_6YŸªÒ)xó½}™7ÊµQ*#…Ï(5©n"ÔÃ)v¦§‰«äéi¤¶:€ö¶ÄÓùu¿ İ\A„˜rœ¯÷¹#cRÜ?áäièG}çŞ…¬?ñyï5wG\ª2„2_ş¯<¥4ç­Y¥nDš?®ÅÊzø
‰FílæÄ¦Œ¿©†MQ–Wù(¿X$¤Wå¢Á\é)çzàkUŞú©•…q€RCo-©‰‹¡0Vœ|ğHV'{b/,3/S*œ–Û`·>…JÂñŸ|›íşôxDèñĞğK€F`]Ä/ä,ù49ÒW¼têİd×¶ÊŸc‹ ñ@íw¥F3bÆÄZAbÖ<KA'Jæ%vtS: Ğ%ÿ†_/V¨Éçv?ÍŞç”•jd|¤¹ávø·Ÿ¦U±oÃµb6Şöé¯¤—Ê)ZşCÍÊ¶Aœ½eıñ‚ÖmpÕ*jH‘gél] ¾š¡ÈóádoçŠ0¥î©c,$«‘(¾zDh
<¢Ó`WW´œiNÅ´İä²4Jã2Ô{e{-sâ)˜?¦ZàPŒsñÍS¼.¼éßü;NWŞ¿HÃ'6ùsÑÅš„V@«7Ì×5g2ÊU~bElº‚~&‘ÊÖÖ	%Ä‘“«I‡en÷X}»ïa^íE.ı³-ºÌZ8*¼ÜW[WÄ²¶~#§jİ®Œe‹Ü$Ïµ¾è÷ÿÎDŠì6ë$ò’R™|ğ®Ï™Aí‹¿w÷âüòâ‘¶@Æ#‚fÕ¢E*ºĞê?bÃüÜ¹“
§ 
Ô>‹O¡$ó¶ñsx¿öÖ–(şª6ëí°ŠœôÌWr«„Åà	¿ë-4wõ¢¯ıŒ$½(‰ò‹ÎŸhÌ<Ûf‘g&ú>t·—ÿº1ar£q|·0bŸ*H´úÜNÔ>òA±$şÈíçn5zÀ@•Ş·¡ê+yªqe“d“ štïxüå…)I¨Z¡ÇT;Ré	à?XX1,Bz… Zù¬Û1÷s7ä‹RTRO‚M2‡ËİDÇ…?”'pŸäaÀ@fÏ‘œ™š„MPíŸm•[ˆÖã™'…¢©¾Ì€C?Ôë6â˜ã™˜fövq²ÉYÂYûœ.Sá!5b•¶ÁR¼GÜÌ qº?=—XĞ‡óMPc?j3„ü-°ğçUŸªÚM«ù¬N¨$	W¾v|óq…„»ÌƒŞİxLs`,Liè°·µë*ŠáÖ0H[†abËS‚ø¿hãŠå¬eßK36¤P!Æk´}‹,Œœ‡0.µYÔ«QŠ/ã¾bÄ»ZlàÏìk(Ã×{I³‹óíĞÌB”`Ÿ“f_+Æá¥½Îá=W1ÏÖ%Ñiß;ìXr¨hç=šœ
JíÃÍúG¹–S3ÏQÿ˜:]-ÍwN:‡Jµ8_
´ë××Æ¹Bà!;AfÍ¡ ”nO6Ë:D$†‘îh‹'©õS^hˆÂ?ˆsÉ>#à€ÄHÉÿÕc…ïˆI‰•m¤!HààÎWI§¤úë[1[ôãáE¡NN§½Ë~¾{XQ"¢¨Û–¨—ï:¯ÉWê_(FÁîİíñtMV×Ûj€¥’¼)™c.B¶Š¥]“±‘`~É/ª{Dê.é¤1õ)$Zh<hŞz÷°Û/<òÍdbsÕ"?I„ÿˆÅº<"tà‹’…§'[›µgş¦üæDYa¿ïJãó†Mz\Ü6½³İ­´ñê~nÕµm¼&@jàÚ(H–PxÏC…!õE6DÀ!ìMøüúúú¦b´ºJ¥›]æ~*²>ËVÑ]Â	ßE×BÑíàü*ñ`i#H<m€¸ø§š£§UrĞõ2LfL¿!è³Èº¢µ´O!ÔIH
NF^ç*©i$˜Ğùš°„ù•œ}Ü;IkŠ É¾×ÙUÃz37I(tHÌÿâ±NZP×®<ˆ¦DŒƒKË\vqß¨8¾ü©·7hŒ2<L@g›Ã,«è'ñ\zVÌR½&ÒZ!A/&j›¸`JÑ0sÅûW·BÖSaDX^0b·Ø ¤UîÓ“œ†Ít®¼á«Ì«DC[@‘TÆôGß¨$*¹ù¦‹É”&²Õöã| À­R»Ÿv_'Àúµ™şCT}
ØÛ“ş°—·ú>¿¹' OuŠ[«ÕMë‹Âçqßôˆ`
‰‚ï=9Ú,ZßûÍ0D¦ùs\_PæƒE™÷wµ«ùP+ ~ªÉ}ËN %/5¢˜ÄÓ3ŒNÜpjĞUÌµ‹f’=26³Û¦åÙ‰·&ë™“s‹;E‹6naÆ?±îºAú«ùos>•’šp©_÷Óˆ½Hì8PËo»™·A‹uslröÉj¨è<W×©/=Ï%~*YOB†ä8¢U¯ã%Hıfù]3\¶æÏ¨j íFØ/¦ÁvÖ.”˜ª®ËÔ¬u¿£†SU¹íw©¤ı÷M™®^ÑDêªĞk ™Äãµ¥›Áf=
^Sì.>ZK‡•µ{.5\`ì„IO¼vİÿĞ%W,ÌI‚”0‰º{·÷‚bNBŒ¢k‡I![ÉªÊ×í»”ÆÈÜD?íWÅ$LKv%²}²k·×úZ#Hl×²¾€õØòäòÀ6á»Ú·Z«K­:>M‘{_ğ!”›ëAÙ6JĞãò^Ñà¨š
·ZGìó:¢³ÁAÑpæ!¯@»‡W8i"èíT€ß±ìT9l”¹K™Ô&‡äNDoàe¤ş“i¼á›µáàŞßÓµmsw†´¡vúA¸Õ×ZuØF“Áõw¡|,=ä4É†\!*º]ç"¹KàÕ4l„8ô ŠıH÷†…ï
‰¿'hc™Õh:;„……ëÓ—¥E¼ËBúïµãA-&5 º§–õÏ »¶Ïºà#T(ş{"Ì¶£/©ZèvâLRL¢l+ƒ÷Ã™{6î˜İ³øó_°ÕêĞd¡´pÙç|-ñbš|®~¤
Á‰;ª¯9fÊğïFëáêÁ
¯”<‰¤¥6—­ØnÎK¾Ì2¿Ş—ÊªoüM˜P„Ê’,JşÚµ»›8¹Üˆ{ÉãÛ‰R§.EÏ¡o	NK	bø’?¯nšıŒdÅ/…ı	^«î‰:;¡¿NüD4½SI%»88ídÚ‡ÃÚ`¶nÄØÿV(}ŞDÂ;M¶÷&6$›l] ‘Ô}\¶¢;ÇN³âÔe€KÜ•	¿—îåŞ¨.}Ö¥P ‹şÄ‘Ô›á?GV¹Û]bip²ƒ0"c‚©¬çÃÚ\ş§±%7&ó“SùáÛªµ®vKıpşæ¡ïªv±Í>¨Ì?Ã7_ÙÅŸyo–>ğ$»ù~_À›°ëı[& ¸Sè$]0p%¦ŞQdï{^mê®ùì$ ‚vOƒ¡uÈ°éQ¶Q¿Ós;Æ>õLÕq”İä:ù)q8(`fìıœ†ä6ö4«2ı…t>û——™5]Q½iX
_vaÏ<çé&ÕkUÚ©}1ç7uğÊOFjù-ˆhU’?­-rW©¶ÓÖ|ª°¡ø™ç7F Ü0ş‡„ô‹_EJsqMÚÚ›Û,aîó¢æ*Õ¸4?¤¾I¨ÿLM}ûgºë•ßŸ$;öY-_škÈe`7 "µŸ;¹È;™‡¸eD›³XÄ=~˜œœ3óö!NÏ•üş´­eßÇÂ|á6ŒväUW{“O"V«]ÈZ£<O'bá¥ËCèœIr¶işÅÆ±RXgÈíµ¸#‘ÿ{¨wac§Y}PgWŠÕ!È5‹6sŸ}D¸‚öMÜdH·±!
`º4y\:­½=Ïòƒ
çõfÕ¬ÄNV†‚Ã˜ŸÿØõÌ™±n?[r®‰9õÂù“¡QÎ|ó²âä‘ow5D¨Ÿ@[<ãušÈ#]Áé^ı\ßŠGæ“1…3# Ç÷wmúK›4¤W¹²“œ8Eù6Cé#ì–`Õ/ÛbÍœÄ )P^RñwÉWûG@©½´íÜé‘K°ä>B(ª†áA0à#¢Yƒ@ƒÑ<RA%×7eÚ“Ï.ıÍtÊÔR‡RQH£Ó¹¸Kúiaíãr€’LĞ{¬ Ÿ7:™/rÓe	9/ÿ¹ƒxVÎ%FÅJ›Xc5C’yÛÑ*Õyª7~›Rr|ü+›&1õÜ¥ö+?Ä;6­0±Wô¼Ööy–?ñz¨ôâªá%°•é*õËM£]jÆsµz 5ˆJN¹N«±BUHXq_Îz‡wz¿Ó-ï@Š&ˆ‰ÃÎi†ëï_Ø9Mœu²İæ])BƒƒÕı,rû¬Ï-(¤Ah¼Ñòë°ãÅøøÔ­Äæ"\…ó¿Ÿ§r`M\ ğ…ÈJGáNpM¢¸óå‘¶Œşi«•`Í1“ÜSsjŒ6j±@[´@$ú|c "»¦Œş¬ëíÇEODuœ¡ÓrzÒ¤²}†I•÷bQ·œÂ?[ãnÚ¼Ú“ÔrMhF`|ûXÓÈ1<Â£²Üü$£tËx“LÖuQ Ï­ØÔBĞÇÒzOl–½ĞAÈÿU€„ãä¯ÁP8÷»@ñšÉ¢¡C8iÿ«İZÍîíjISÖ=ß4PªÒAôE;~Úÿ;»şŞGøË:8ƒ†‰’h'»±É1JŸÂ7Ä¯ZQu'P2%G>wµÔÿ
¶R·{Ï]H:úñ²"d–ìÎş³?*æ%Y°nÑ/ôaDd/²Í ı üOMA}nça5×‡ÇŸÄ I49ßÂÕ±†ãlÃpNªô¶“z”şìÔÉ´ì2µ(L÷ßËaR	éãæhÀO¬i¬¡\óü8›RoÅe4o,Åö­ppEğ¤Æ°4{ñ¥KıÀÕñô•ü³PÄN”ÈªÂ^ªk~ñİ^ÆùĞ}ÿVíl3Öz ×Õİ¼Â®4[i)¥!Òˆ…šü0^gÆ«6›6EuÙâê—‡¿vÖ‰oÁCôÒİ@µß A¸×OB×§8{T1é“G,?€êş®„ìc „\
xÀìÏ?ˆı@Ë>  öiòÓ4ƒ¾Všˆ+‡ñlÅöŞí‘D…ù]‰Ôc¸3òqz7YâåJœõ$Áã~‚ùÃîÍÚü?ğ¬râíŒ`{3Öâ3İ‘xk OìÙŞBôM£ÔjTr‹Ï'‘JÃÅS®´Öó–K–W9ÊöÕd©}V†û}†^Î‡hÏv8.ÊæÇ3ÄĞN9uøOêB3rY¥¼xMàµßQDB–Î¢3ˆ½DÆÙ[Æ/–¯µ”]¯Vjm÷wı[ø–¼¶+Bº`\ìïzkÇßjó¯ê0GhóQ¤—ÒÉ/YX~z
,æ%7KåÇ%ÖmC°£iãˆ)fª´ğN^X’ñ]CsoĞ×JŒmÃ‹üçÛÓy•c"tT¤´U×¯hî˜•oåÍê¢ZÂŒÊâN¯`#Ï(ŠÊ4èĞ	¬ßÇ/¯é–›‰p1T¾j¡ñh
3|aÌš¶Kr ~D]Q
_"ìà;/ÅRH1¨ÈÒr¯Ìz e!xØŒ*â:àş0WÏçTáE	×xÊ(şq®”Cñ÷Èÿ7·3Nø¿ö5gø×±gçë—Ûû5ŒÑm÷ëõ§\ĞkRÊÀiÆ³ÅªØ™˜ó×€g[ÇÃŸô-mò¦‘ŸÃÓü¸b2ñTÙÔûÜææü¨©ï‘û²Ä\ÁF+ƒ
0ùOŒ?DKÔû6ıWnÓ¶=á‚WçqÈı·|…Üˆ&ÊÛÍN_MG˜ÇÂ8õkq_¼6ÔÏıˆŸk1<“šŞ…˜±Qú­µºøyõ¥Ìô }ma¯ÔƒËLo½ƒi¿5à,6[ä=‚<ìKtà¯Ò¹ÚNº 	AJÓ…0ıÑ *^~l+
°ê†ÑƒÏ¨glÂûmOt¸óÃfd¢ßâ·¡±^éCµ…µXœ #Ôà÷çâáñ“èóœiùÄ;@7	W•¿Ä²FÔÄ%®m²ØÆzôo,ª¾<œîÜ˜h{6†‚Â±Ø‡W‚.âÆwS¼¼-©ûIO¥º%‚6¾W¹0Õæ(«3‰@ß`„Æc„;ıÁµ jÜüŠ´9ƒ" —m&:EûŞ}  ¶€ÀÙI±Ägû    YZ