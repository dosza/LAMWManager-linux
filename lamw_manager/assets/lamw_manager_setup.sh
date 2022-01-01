#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="386987962"
MD5="66a8e6d69c4322bca28e3525eeea6862"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26004"
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
	echo Uncompressed size: 192 KB
	echo Compression: xz
	echo Date of packaging: Fri Dec 31 22:23:06 -03 2021
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
	echo OLDUSIZE=192
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
	MS_Printf "About to extract 192 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 192; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (192 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌâÿeT] ¼}•À1Dd]‡Á›PætİDõ#ãìJªG[3O§¼
h0>ÁÂo5iØô_Vw‰``EÁÕ˜+J¸9-XîÒ:_³µÛç¼c
ÍnÌÍÜrèƒ UñU«™à2N(Á¢ì@?Œˆ4pë‰ºúìÑíXôñbB*cö_ÆI‰İ:‚ö^‰ãÊK¹yV¡¬ºè§+2†Ğ¤ËMZQ™ì–'SÆy ç—¶=}Şd¿Í+Ä,–ˆ3_£(FË“ =ŒÍ_ÒUæ ƒjÊûîN°;Ìêdƒ–8.uÉWŞ“Èµñ9W(
a’<J;ñÌ:Â³×5ú?ì´Ä;Ã&†Ô“bòvß…²­ÈP„Æû<ñ°OQş;uñ’÷0Gzûp&bZÍpëï­û>pY;zú¯ÖfWIm±¤¶·V>pÛ?•Ğüšp1±ÇQ»@hş0,¤Ÿ‰Ğ?õ¥=O§zibMŒ–ër	ÄRûø53ú'óÁRBØüĞµ¥|—Áµ: »EV.ç_ğ•3ÒCõÆ†›Öì %=û¦ÿ°—Ù˜ØÒò´_6ºÕ’¥ğ`À;!@¿+ÚÿipÉP¬~´/.ß>°¾šu>Å€€ló¾˜[ü­Ü›cEéçiÒ^ÃeË4¤Ó-KSdÅşduJ2µ€ZDJ…¼Œ| ¢çMrÄÖ«~MÖ¥5`½ºG—ÑòÁ@˜\ĞÀ>(Í¦¸ÆC´Â±¶!×®ö4Ù…\NŠ{<]&¤?Ær÷Î$tw¨‚¿\~ì¸§¾ßõù¹RÂÕõWª×¾c¦¼›æh¯œü–ú§¬ìÍÙ“·èwˆjå.ş+¤Oq‡°UÄxÖ­UBn‡0òzFrİ/Çƒõ&÷œ:Ç“ïLZÏ¼æRğ¶ÖùıñvÈöæp#ÑEó=Òbbm7¢¾¡­ˆ_°~`hıCé™ş)œ«ãe˜³¦H¨÷ñuœc+E	~)e*ùşzâ”tMb«È@0{¾ó ”µvè®TCœDï"Ğ3;äé‰$XÒOp|j÷p¬À;ÿWç¶È‰b3ˆ¢QÛ”jÆÊôùı<ò®¦S¸Ÿ£m¯Ó´;1mƒ½ Êú{ÜaoSx¡`-oÓ¢k O¦kÈ¨ÂßókŞÎÒ csÿøJö
ˆ+4Xº¸Á¶[§@Hõëw…Ía\28‰l1)Òë7Ï¤ìì”Ğ­Òsñ½%ÇÕOÅÊ«,]Ì
ûçõ_U9—øRû>I+{|ò•ñH.X¼»Oâ=^²îû¦ßê¹ôIğ+é…	š;pı¤»|ø^šV|ŠŠ„Áçjˆw§]ùçdšQe¤/“ßš65üÈ4%¿ˆİ½ì¢{C´ZÅHEúí= <²Òì¯Î,âœzd¹0ò²_±p¹Z3»¹ssél±†&;]dLÕ
ğ¨I®?tåYb#¼Xµn¯Ô¬³n[ ï0Ç¸Ã¹)'/C³«–
ºáæ7'ü”W‘•[<–MEàiŞsäĞ\1NÛåœÅ™ ¹1¸»–/Ï´ÿG^¿\}K«2°?û)Õ˜¨µÄå»hŠÇKMÍ°òŸm+ºiÚôŞæ‚˜æ1@ŞÅ¤?ei”3§vÔIõNÜ5.ZéüŠTlEïÃ“ˆÙ1&Ç'VñMÅŸ²4ÄGSğc‚ñûJ±ìK}Ë)Š6Õ—Vú£G2°QïÖ‰QH¬ß¤7zœÓ!Ÿ³ãıÏ£5L_sİõZb”Z•é][6*yñ’©Tf€À¯*Şä€èük=_±Ñé!JQÁAó«å\9v‚šv¢¼ÉÊÔ"Àû/)À-1«‹…WIRuêŒ	7‚Æ­ûÁôóÛäµUÕFÌP@FèÂ N× H„ßö2CÃndNX­GİûÀ™@gÚ˜P£ğ„As€ù4<x;’·qú^[\è`qÀe–tv‡TıÂUÊ¦®î	A·;˜Î`|ëÃèëdù§E¯ ¥bhï[ºÃöJ)í¨3öKŒ‹W«À±0ÊÔè¹H@ßwHŸ°­PB›í]ú+OKÄ¾HàÊFwÏKá-LR°í9¼‚‚¡uw©­eŠãm’pâzëg2ÒHY­	-«Ú¬ Ö†¼QÀâ€ûåá"!Aîñ6JÉg•üaì“zxh¨-Õó¥CgöaIbûEaš’•a¢h{J^ÊÌü(Y™Ö
ë_ÂeUó‹‡5½Ò©æJ['½ •]¦
Ü”.i%91B!5ë‰l¹î.Ö”øwP¯+Àéhê%€ğNTÁåYG‰LB¦ Rv}Ş¹TV[Øú;]!Æ í§Ô:Å™~+¥«QªyÒóV„ ØNê¦¿é2w’-Ğ@	ıdš‡ãxÍ_‡kMf9ÈGø×OoÒÆãç€òËMÅµqmçÅ‰~‚º^­bz{‰Õ-	:
Ñµè‹ı õ~uÈ^}ÑãaûiŒ^i·¾‡TXˆcyí}ù}£mÆ²BvMCó2³	Î}õ]“LÊ‰Ë£Æç1FùNW8(ÍG:#¯<CTcÿ#ã°¹ ¢,.å¯¯±_ÑŸø`_^‡ˆqFºnv]Ä-pÆ¯W®¨1)4¼côIÜœ8Áµ‚¥Ô­ö€û}¡ïî`¤ šÓ4Ò·°T6¹kß5c80'··å
/ìêW(QsÿÙöÖŠszÖçİˆ>Á©¶êJšÌ	{›,Ÿ¤»^m¡Ò€°Í9ÀR4Ç_ñé\ZÑs$Ø°³~ÛIŒ9×_üWqŒ­4ì%èğIæÈŞ`† ¢ÿÎhÀ‘hò5%¿¿ÃÅjc#²qóœˆEÌ¤Ä2sÎ¬>êáw˜Åm³ üùpaÖŒaQØ!D@©½wò4â˜s}P3È™ï`°‰cq?"„…òåqĞ¥ƒÜßF6f"@$ºœWe#ºk~£î=ƒ®!#áXyÖªü´:U´h‰¥}Ñô¤µÍäüÚ¶¼©Ü˜ôb'As¤& px%<½î‹ø:²8OëÌ=;ïOñzŞ{'şçŠû-cd:;&Z_Æ_)¤ÕdV\©É€àáÇ{`sl9«m§º³IåÎ°$ËçQÖãt˜Ø2ÃëhDŸª[›Ñ5/›×ø‡}üõFì`jÁ–.7aK5¶CX&Lœ’](Ed¿QÏ%K·õüDÜJÊœ€SH“ÉVéİ%ç2tuB¸’™•òrŠr¼Gª¤ö2f*¸8°Q[{²	­¢/¬	±L‰ 1 úşâQcAIíŒ´Â+"7´MzÕ—Ç[©”ÁŒf²Ö¨ú?0ÌìPìÛ¨;í11NšØè3PøñìDeø“®@ÇC+A±Â'P&»zÅUOûT§ó;=zX=æÙDO@ÂQ4áY&±¨#U´Fûso‹çË®ÿŒêr“
ÑGÈ¹v“ˆÒìlÒ{¾6Æùíg™ÊœëÓæÚ‡ò?—:™Ş¤:u±ücÔ#eÔVçå³–ãYdØ‹Ã@¾*˜×„È+÷Á¨ª’rîˆqy.‰="ñªJ˜jOŸ”qúyb0iü’¾‰Rj\’âå&[xP@YÜ½y±h§»ª…¢A…ƒŸÔ|xÖa–¶‡uö{óõ’s4¯ŠsÜŠœƒQÙÎP‡sYÄ*Ï²y›Ñ˜¶—ƒº•€] ¦ Ã`Fµú-Æˆl•¦X}vø–vLr|MÌiÍzKğúù Z·Df/5|ÂHÀ^S´ƒiaËØŒJc¬#µ~…§ë&úÌ÷¥?Ï<ë½×‚ljĞµZÒMø‹öû{Wê‘h4y†gf®(ºû’‚ãoTïş‘ÆY-/ ä	™Ëj™ÀƒmøkÀ[Ó=ˆ\mLBP§Àa‰Ş­Ü´ ƒ1ŞkƒYAæ´_­xæÓKğ],ç³¿øÌÍ˜'«mØ®=…”×›~¼Û»µoù‚¤‘Zí?£µYÕ©]£ãŠug	a”V:C1Ú9:¶«õ­O3ÌºÁó^ÿ¡UÃ™õó€`‡çX$ARÊş¼
f)şeP¤éZ~¸à¶¦„À­/>õèá,/#úN˜áİ/X[Tß]Ã×|Â]JbõŒù °ëÒÉØÇ“bÄ8ÃoÏdMş¾flw‰â*¶—-Dõ—N.!l»H`ì¬3Èä$ =Dô7Å=fBõiÓï'Ç™™1€K¥ùh»™š²ĞÜí p§®‡¤ÖZ.ĞIr$¢p‚0ô¶;æ³´:4ÁjÑã—”‚Ğoàï	uÿöÌƒ31› “N XšÖº_jJ•†«ëSê2|Ç3 ETˆYÒfî±†Æ J{•‰”´öBP?–¸ZÑ ß „¥H ,w B‹Lè†l†ëÎÃ%áy²(õÕ†,j˜O|7!`à@–_Ï!×}wÂ:kÛR{)¶ß‚ÓÌªpæ„·h³Ô¹bø<ép9ÎŒÈ¤ RüúÒ;;%xÊ {öfyŒgDÊÖMUó^ÇÈ¸súb¥nVÙ–·iƒ÷5	0ÿÖVüL-ZƒH¸Å‰	NiPÚu…’Ü´Ë)ñÈ¨B3³(®ïé	ºkµqSMTÔ’¼“aºi²Ìofqe”’ÏQ"JÊ1¤÷Ñ™`"=ş#Æ}Œ$èoÌ®Fõw¥d1Li¹ô5ØÍ08ó×ßó€­•‚¦¼blÑİKĞZã«vÚÓ_dàÃtóàŞ¬K«ò	âKÿy#Üt²SB”€2ÆëvMu-Ó¥üŞ—H	gviÊ5ƒ8î«E\uo¤ÿÉ‡á3sÎdWñuè»È;¼ÃH8àÛ0î0¦*>­!gyW{6›#xzspa1İSp÷„+æ-Å2	ğ{İép¸ÕkDœè¯CõÊœR"N¤®jpÕ¤ôbeFHœÑ\ß-àkR´n•È8@9ôƒË±ö†üÅÂZixÄåÔŸä#t6FšÑmmê';ö²…Gº–'•ñƒæ,~¸f<¨Wùi
0/‚	˜5y]LE£S55=‰¾ëøOìCp{'	ÍCVf£k¹˜çİ7êùh/j¦^f"Bİ@6•ï«+Åƒî½°?}«ƒıvò•µ¸©”ú)3>dÍ›X™gµ6Ë1'Şk<ÌònáİBß×Œ/àå9Ît]ã×[‘F´èXĞÜ:æŒ¹òøW±êíõ¡ÏÛ–á…]7©	tªŠÂ]hø"æ(-4ívÚiŞÄ­ÍZëÊ~{ÀÀ?aS¨¤¨Y~	lğÔ²L7pÈ™3»ƒ¶ÍÄğßâ†TÈ&©Z¢—MxšZ8ÑŸÍÑm×„àJ‰”òrìòePwµeVùÖª-¯­GÔ¶ı´[¡ú‰2_`o?
}ó\peÔ, 3šŞ<÷ìÅ<²b©,ø4ƒ_]§‡.ŠvÁL ”­\€‹’Hvûz+:Àş- tŞàX¾ˆa ?—Ôí'{ìv…p3È¨KÚ'œAQ®ó¥dìÕ>Ñu-d†ØdiÛù×~T¬šK§ÔÏa¶Íã¾E;úÔ¯¥L!qÿÍ
Ì\ıÈ9m¶”}à¼S…rÖq*b¹ıÑƒb6áN’'€#¡Ròß§¼ †“óš(]àPc_¥—U¿¸ÜpÄĞóÉç6èõí¾]ÜèÿÙÓ ¹@A!xrûªen$v)÷	dC×Òv'IóË‹‹»SØ95‹JšdºíÀ–g&!YC L .bşaPfƒ×¤XCf—©-‹ê°3)£g#İĞìËá»^c/wX-ªĞaÜQFIğ§¶€É&SëmÆ¾BÔÓ¯á¸M)¼øl'ï›3! E3˜fâ ¬f‚	¿Ì—{œîöj_ëRQ…}¼kdµ+T›öÛ¹òiŠ)ë­+ŒP³@˜„û¿»7|—ñè’"tıËK^W¾ÀXô©¹»V¾¶aJJ8¦}ciØÇ®XŠ¥S†¥ãè!Õ{á·Š«]˜Ã‰$şİ4<Wb*»9¿Q]îxÿMj‰y´q£‡[a·&ôËÜ.qKy\Cv^\®—ªß=Îû—€5í ‰+­O¹Ì¯Mû|‹FÌ{ÂVşÄ<À|t@à´(¿|¿X>´B2Á ¦+Uø€;éF»]Mœ ª(ø~‘í.Sdé,©D"‰q’vQhúSÑßàytP‹æ
Øœs|şµ-MIé<Šv¨ÏÖQú’œúRaøÉ´Gtõ9‘>"¾›±ÅAlÇÆ¹"C3A²ZŒ¡nÄØ€FL? Q#Å¼znyDÔ9’§ØÃ*ígéœ…OîGjùŸƒ<fy)ŸÒ{ÿÑì½æÂ+º½xÀŞ‹Ü_¦P¨aV‚u( Ö§xW‚®™>!n©8U9	Ù9LX¡–w>×x Êú„³bNŠ8Õa,+²YCcn9m^6Ïcûı#©¡¯Œz<¾|ä¸¬–bµ/CÏ‹!^É¦~+Í/¹Æ‡G•Uiš>)9a©Æú_å|æd&H	å¥›çîN‡³«4^‘L:EÉ¾6°Ù~Ç†•áGf]û¨­†Şèğ;"ñä‡Qÿk—e WòU9ê—Å: ñ3ö}¸ZîdêöÖëâšÍM‚i0>££ ©ªwvNjâ`–›Z¤İ¸îÕÈ”2$eÿ¹ê€©ÿ¼yû_…ÊÌ*$çœ+L½¬`4óÛ 6Z5Ç©ıÛi‘\q±MU-¨IršŸ®åWkäß‚R]ù¯70û Ú5Ÿ@/½òÃ¡€ƒŸ9ˆÚ0ïóÉ¤Ç´mF)R"d“%a(ç…™Ô ÊÒ~ÒŒwöÊÃ¤u˜Ó6£Ë=2Ó]‰nQø¿Ú.éª%ñ±a¼˜K®»Ş[^úÊÌN3&¢X£RÉK äZ†5„¬°^šÕ®Ø1¤ÈíãÖmsãyîàëÒ°TNŸÒ9Q9ŒIŸÖÂær<,å‹&?	¥Cn7Ûg–+í$7íağ¨Ş£Š
Ç‘3…LxA¸8åÙ½ŸMÿğ&Ó3™:Ô~ÀzxGÔbwDÏqÚ­%èbõ® ê,B´rÏ97Ï¸bï—ut¶R((bŞ©şq7Ÿ\ğæ=F¨®XxcÂXÇœkRÀğö…h!22§|;®ÌdôŸ=YIİ”n ›*{Ò Qš¤¾\jYt<ã‡í İ¦îAÆXh)Q†Š%Ğ™´•ñÛwí„–±,„ğEÿœ…©¸Y…!1ÔyÂ”Ş‘9~»Ì‹CÉ¯üFHeî'{oèi.PaÜ<ìZ~GÁÍtäTµS”¾•PcŞ-ŸÂşÒÑXŒ$¡PŞU‰ ¿§g-É/ÖıaÈÎ˜CÄÖm¯¾˜å‹Pp‡‹§,ŸºyÎûK‘xã¥ƒ>îÅ Ö¦Ô``¹^İ O¶nˆË›õGzĞ<Å-™ü7^Rh¸x*yUB	dC¿’xš­÷-ìX †)è?æRİF^"#Ş¡e4ÜÅ ı½
œáãæğƒƒîÕÇÉ.;šg]+?eSC?-8Œ³}±põ¡L¡÷§
N•¶/M;úBmg|½X»,˜KzıŸôA@ù ºp6±Àº¨üÍ`±FşÄWo0É2ø%Y¤ÕÀ`RU—`µ`qÇ‡Î¨?ûi„EMø¸dĞıôßŞxİ-bWldÛ}Øñ|’)Ë‚ŒCË
ù_^¡?z-ÂÖ›>÷—ºêá’Wã5JlÖÄšˆB™j“mÉŞ’×õuáWt³ì!+Ÿ+]è]Â­¦åÙdI&á¾óÁs4åLÈVÚ”Ê&‘ş`BÙXI…]¢$RËHQ"vChK_C ê{r?ªĞEX8èû9JôÀb¯Ym¥F…>~$a¶«ëœmàN‡Ë¿xõK¸¦D 5oZÛñçŠ|Q
ÎÕö¬8lm€>RxXø²ìA^¶{ïôq™Jw³XC¤ax)Œ6,ïÃYÔÆx6÷Äb”ËBŞ‚H6+”Uƒ<µ:ïÖ_s"ïoëæ«}&D³¢'KmĞgG‘|ö™wö]'¬Tóš‡fºÒù¤I%­…oÏâ,üœbI;Ì‰‚É–RıÂ ±m×+‚$&&¦@ÉD·âµTïûYÖ7ù–>ºõ<óÒp`Û-h¾;Î8´ƒÄ¤én¯ƒÜ‘yÌOË!æM§¨:	Ñè¶“º·²ù7ãBï€¯MåiéÛòGşò¡1‚ê€˜z—šR
7ÉÄ{.S“¦MqC°c§ø±hs/»Mº´º'ÇµLazïeÅ‡ä¨`3æ€ãn¿ÆdQ<£åá 4=æ+ÕÜò½¹…AÓY±V/j.1’È‘è`øÂBğæ°q?o?óHœhV§¹Ú™Ciéçz†óÀAm„!k¢lû·ps2Øïšé”sŞ–vïA7 }÷‡´QpEITA'íÂõ˜‘dP°^ŸïÉM7ùº‰e8´`rÂ÷OÉÉ`uUD‰Äf)Š‡6IîípŸÛ¿u³~
EAÏT@hl>ğ~s%dV~EBÛıTõ)()´.I'Ä§'ãâzH±µ©o|Ø°(=O+I.U< ppÊHm}&¸¡Á6øvl7]`¯9«œtpŸª€Á¾ù„4ã]åŠfqä×¿‰(·á%{ÎfµÅC+QC	ÈÅÀ
7‹}»7f1s‹'Â»ò=CŠ£d!¸àˆLI™.°ı:Uúã©FJÈèYWçĞX´‡Õ¦½? a¼ãIøºA8³Ã™l*÷h(F~yÚñ„°£´fÅpå“°á\,Y`tHoy²ÿm_ìşqíG†ƒÎ|‹ª;WêÉ\¢3¼à“^È4ÊÒH¦øPpéNCDµüW-OA€ıÒÈHàè{z:B‰à‰;İşå/­HôÜ·$Ï¥-`^féd8f?W}¶ÜÈÔ)•B2€•ùIÄ+¶6Ö`Æ¶‘»í	ÀÛtÆ!rç[Î‹&ıAÍ†Æ±;™Ü<„¾ùqMp‰""V]¦;VÜñ¬dï*ãccN=h­zÓHİİq–èö¬“ÂÄğ÷áb¿/ªŠfS"¥cÒN¼4¿`<ç‘…‘OàR%|n¢„^>õ,.å8ĞAFyîÎ'J©t Q&c·oÑN½]c ‘½mûâ 7û©ÙZ$@ÕĞé;"l¦Ñ ç*ò|¹Òímzu¤¯r;õŞ¡AÁŒñn2]’#K07«M|Tk›5W2“}°ı{“ğUUXzÁâò.ûpõxÍ ´u„2	ü	^êçıO—îÙĞC¥†ÃbL
seíÀë
óÓúN+†ÅqK‹CW×Åz§Bè£}îõ±¶·ÌÕ-ˆõ¨’ˆ±v"æ‰"u¦åìHÀN£åÄaŸöÌBl:TV#&*·n­ÜF¼
ßì“É¦RÓåhlU7³•â et\·¯qŞOZãğ
æIWóÆj<È”È[M£lÉ)d–/jÖJ¾jd¢€B“s®5èªuw‹¥Œ‡ê	®`Æ`R× 
¾«ßARH=÷ÕÈ_Ì'/áI¡º¹÷&h’ƒş7€ÖÂ;òüõƒÕíÖiA¶šë]¤œé‘ÆŠ¯ êpñŠPÍ²ÒÍC4â8=¹{ÿiU´¯¢"Œi¬Ê,Ğ)é ãØw¶arf<şu¥îğå‘Ñ¶RàŞŠvüLK3ìJñ}¿Aë]şy¥¯´– ]ùË¥ÕÈJ°P±œİj=¡††1u{ä€óŠ¬óïkÈövÂZˆQÉ"¦‚F”Ê0¡mY¾¿JÌîú‰“àÖµÌ˜ùõ„ ÜP®Óe3àF^õƒ~àúòØRçÕZµ›‹ğI’8¬4D=7#ÉVFuÒ»¹8ı™«’K¢Ü(,ÅÇËŒ]<"	”à†ä:$dÔGDcÑÊã.A‰¾ÂÁ26î>«*I.,›1móÚ¥Äã_Şh‡ßD§€ÆÈ6ü$òGğğ[ ¤Û[ !¨óq«½Q£,voºú#œfòH#œ¹ı\ûjChè„§ã,Œ°ù…qÍ…{_ŒJï1kK6à=ıG¶ +™¶“ØpÊ'§j?ÔUK+‘=—¼ÃzlZ²åŒ›Ïå¢şº0°æİ\Üë
BWe¯âæª¾[è½ğàŠt-}H*â,NGƒ~À{{IÍálßOÓ—ã™%n4Ÿ2€ÊïïÊ»ù#‡Ûi(¤¯ÿ¸È.”`3ƒyƒ`-jºÇOÓyì=P²dç†`HÜ£®l|Ìé¨á°£¡ä›E hF(9ßÄNdK˜2dÎ¦³`_—³‘/ëŠ›I¦Ïâ˜9¸divX‡T<(¹%ÛœËdÙüPxÔpx9/æŸÇ9Í<…—ªRå5O2kKªä‡¼í±È×æL »4ÕÛYS„°ûá‡ºÕg¸M'¦4ˆ^ïd'Ç0›ÎÊÛïÁà^Øi‚l÷•5ÁÊ­‰Gú9>xJnŠ‹«¥¿kÒÙ-\Kí*!×<£y¦‡¨¹ÛÃ(<„ Ë@]îDÀ&Ş˜d²áYÎzRœ™&ÔËªveÚÏß¤°c®EöàœN1X¸iÚ8ÁtJı>OED÷ığÑş¾	Œ£ı¸œİ(²Ú« 'Ô.v«qN­×“µ£l1GÓ’…ş7)~
’Û~¤ßæ åÛ{´J8ƒ­V¥Ğ´ÌÍããÀÚW×	Ü,£æÈâ;jH;g«ÃÜ™/zKıô‰F¶bÕÈTKfG½3Óhî‹¸9fà‚Êo5VÍÎ¸GvöocZ/Å,‘S|áµ”M.ß{“Ssú•âà;Í@Ñ¥¹o¿\ÇÆ´ÜÃ…!¾6¹ªm­8³ÊfSn+œu¤)ÈŒÈ†¨	Ó›Ş4@Ã±Ç44[âÖQÿ¯ĞğN"‘£÷ûpŸtF‰U|A‘ãU±êI	ifä>Hœ.âæëš¼jYÔøè(=~îúdw+DÀö0ª¯ ÑŠ¸3~FÌVâäª9
ÆŸ  ÑñtyÅ›Şä•îË¹®ß’¥~µ8cfRÆôì%Îìƒ²]ş{€ıt#3'ı‡Õ0¬,ÈúWfdrµRß?F %ï
m°JÆ,D+ò_(Ó‹íäÈÌ,á`dÕOˆ%·côÉ®¨¤m¤Oio¼¡‹Àt´àà}ƒ[©—©R-÷£"<.~øZ<Áà-\ç(»ßŞ^¸)a§%õ¯³Ó¼M^¸íq›ğ0éÜÌÄ-qş¥~jcdöw)Îè ™á|wÀ3¤yÈ8¸Æ¸WÇ£é™0«¢zr!ÓDNÈ¼Íğ¸ĞA]œ~Áõ|`K±D´À.v‹[´ÿ“"àHÕ\¿`R„Nú‚kîfÄŞ©øbH(ÿ5«õYp›Š4Zû’®EJ{wÈúQ£¥Ù:™ÓÍ4‰ ºÛ3TÇˆ8Âeš¡YIù*cçå5uï=˜ÿÈ£–ã+LYašá^oìp3#’ÆZ{O€Ùl¾ÖK.ŸpÖn2¦Ókôz¿ÀÌÛœ½OË®Me/TÛ¨ú s^ïÎ%·â†vâSvÕ—# 6„öœ¬ZDèÉš
²iV]9–JÉ¶•õöAG+vÈ¯{ÿ†ñBëZßŠ%˜WW£ìÌĞ^G<+æUë§ø*NG®Ä³Uÿd^eÒ8ÉÔ(0¯HH&’fKØŠ6$#àsinlÌyÄ=2î€:iéyYqÕä;eíÖ li‰ôíMÿ²	B§u¾EóöÛÏ#~	!Ÿw}Î·¤GavhÛË°ût'D7˜ƒ²72©§	CÊ¤{¿< â‚ıó§:da&Z²–Iún¦ˆ„¶C‚mÍ2ú¦Ÿ—·6I·¾:ü]„
zÿ×¼4|Ë²_t!S®HĞW:Æ0{aq.Eÿ(öÚmº`!Fú$ti³¶ã¯ı;—×YÆ’‰»ïåf·œù8`sƒ®å¤6«·S6¨Ïúœ»ï[è3{
]Ò2ªB‚ºpı^3…Xe%»ö‰…¢ºÌˆÂîßÎa£z0zØÇC½|àô¬]9¿mÙOÜ!åwV|úÉ…Ï.&q|ÇÆÅ³W—á .§7©îô‡¥"@K|ÍŸË¼ë	l™.Ìš¼DTê$<òOe3\§^ã]‡×^óD<g¤+Ğ±‚‡¥Õöè~È»ç
Ü%CÉ—lDÌ8]Hô´GÊ<;n#”·gäH¯nPòG5 À æ]Ø>{Ppå¥ÎŸ.ËûÌh¦Z‹È;èö×^×QZ|dûfÆ"'¿õö¡Â|çKY‡E–¯/
¨ı‡¸‡Zlğ¦à¨¬3gæ9 Szç\­ÌQÅ²–Õû¨)_³¡´DØ9ÕŞ)9¤IøÏÔG5\·³˜`[/
à vµ™§•£í»®æÑºåújª©¾c?_Ÿ$B2ñK„öcd¸‘•ÈÇôCË{=RdœèH+/9>)ŸzØ¡öÓ®ê!™ºZ=DíEûï’M¾ÉÂCX€ú
á–êfÒ%ïÁî(Ù@l’ˆ‘#R4cJÿû‰OÅ¡‚UĞ™¢9»µy‘§ÎœM¬ü®°ï×æî®gÂ›İ:kµ9Ÿ	!F>É[`é8
ÅXÚ|M¿Ö'
ßÛhš7lÎ¶˜©ùâ»{¢¶a½Ç§(n™]Ÿ%B#é¤-¸ëÅîô! âBõÑ…¯™>So6FˆlÁœäzßÌğ´s~ÚŸÒÙ5¡Ê’š€½£7˜GèÔo»ŒbØñà¯:¹Û{”IE„ JKÕÃTÉÌÄ–Q”ùizÈVúc7¬+"£€.)÷ŠÌØƒ½ô\†‡F±ÀB_ğÏ,^p?ìªˆ…Ucºœ“Ñ~’³Ë¿™ÄĞ[Í8L+|-aPk|*÷úó_‚5ò}ä”Ñ®êû  <ÙÛ¾™ÿ%"l×š µ/îvTà‹ŠŒ¼¤4ÄŒ,ê™–4CzcıŞ¿SZ]–0(aİ£¢2=(Œ@8 š/¯'„	 otMÖ$!úA£dşi‹Bµ~ëœØö„öHÅªñ÷óøŒ tÓ“”¡”-WP9=êT¢óTòJ‚ù OÁ›º°¶ş(ÊzÛ‰‹¶ÕG~ÿ+£É/¹
~µàŸÑAvT0Ø3±îÅ©mÀXBˆ7ş%8§neª„bßgƒmâ‚­:&ÄÑvRcHğÔ˜ÿL«Ôûj­I¼ôÓ£,p9-óD=~?•şpùAêÕä„ÄKN^™
 Eı$W0•1¬+7Œ};b±ı;¸é¯Ôò~í–ÈMH5:¨64Õ^m­™AïµˆfMŞ¼iìd®ÿ]Ê¾ÛNã³æ­u ‡p¶ ò³ß½—î­º…Qßæ×+Ê>±å©3dcZœc.&áñ+õ(|U%Îz‚ÅX ‘—R“Ö[·~ÇãŞ!>’j²z¬|˜‰$¨”ÓE{Š»×Uäø™Î¾têäQhG½Şnö.+Õ‚¹(1T…o¥8Ô-4§0Pg3}q0Í–Å¼<»ç¼i€Ù«coeÓd&€¨ÿÕĞÎuÑ)ûxÏ£§‘²LJ3ˆ€†²Ëä’K²›`.Õ]Khñ•¢€;6ÂÅÍÌ‘éåGòjòD'»RË”
ú”cŠÏ)ç:¼†ä_ã•pø²R1(tIyZq¶û™¾6(L7Œ"{İkŸ;Ê?Ö²Ù*-53İşPmuC±ÉM„{˜ı­,!n$]q×É!¯˜`)Ô‹¡E«}ù$,¤«Ú‡qŠômüÕÂ@÷E‰£RX¯YÍ]òÒÖ[”LƒÇ¨¤ÌÛ#`4ê[ƒQn¹È8»tï²uŸ&ñüÆ9kŠ¼b“—)ˆNbm‘s2ÅLe©Şš#]Ô¹Wôw˜º*½o’'awPõÿÁfôÅ÷Ÿ~ëš´‰
šÙÁ¾©O!†RKùc‚—ëâwñã‹ì¼‚oÁ"ƒoÜ$±OZ _ùf]­šäÏ–nÅvC§ïşúCdÊ´¿ÑÇ?Ì¾N'îğNŸOGybIl¼ã`ÎÎGùxø³K]²¯öÜûÕÜ:€`sÄÇûæ›AÂŞñıÍsPg‡mOp€  	”ß¢ÁL€ÒÛH*íªá´öS@™ëÇ:ñüú	¦ÕÌúYîu„ö#n»†‚Ä aŒù…Ï@¢M›#Ş^Ÿô™Ğõì‰ÍéÎ›¼äÍ§Œí¥§ç/U|–h=U‹xgKî.±Š«ñ¤UÅ3uÎÚËi–EÏjò¯Ş¶5p·"²Ä˜¤À<€n1Mç~±ø¿¤
É7d—Ñ¹áiÿÌÉ0}TJ±sGù+K¿TnŞWÚ´û[ñ‰º[ï¦bßˆ[®2Ïíc‹xoøÔf®öûAÌÂ(ÒÛ*Ë¶Ô1X±˜­ÎÒ²Ú%MKïÑevÄ+)İmS†Ú~Ãr¬Jõ±‘óéÂâ\ÒédX¶—ş’!$ªÖr¼ètÔ‹•‡õIæóa5ÇHË¡“±b,Q£å¬Å÷UáŒ?æW×Çõ…£gYÛ‘íˆ¼UFzålnŞ"à+Ï9``„‡€lv®@hMkUš†¡YÒ@B¦8IGÏq|¢¶1‚ÈfBXš@¦ŠíÆ^ÉC&Áv‚yãåô©ãzÚ¤sIËNô ¾®UüÜÌˆ˜%Ÿ„Ü´dà
üá˜N°ÑÕ_û8ÑeÊRàÁ]DS³Â‹TP³=ªğã¨ŒÌ²­O™¨áVş,DPY	€ƒ Ì82duî¬asœØ1F™¾òH´.§«ñìiÕA¡àÆšuoSr^˜—'¬_şq?zi)ÇK‘¶¸jÌÍN+ö
íïÈÍı’ªEóKÅUÄo6£`8$^ıqQ3ÑIrl'u•îí<ï¢Ó AÀóQæÈh¼Ã—úúõŒWtTÙ±¶¿p9Â‰ŞĞVVf…•ƒŞäèÉÄ$-1?ëßPi^®~¾^b<’ğÛ•åäÄPÙ‘Ø#ƒ¦tFi‚*şÛìàCè9Sùvô€,öÒ(åuHuà‹¿Íe8¶±·<ãwKr
4îCˆó€?©›dš&šWi sgö„šÆ›§=8$ÙxÑÈ#)¾áªùN²]PA‰÷+ÿJî\dÉEm:P^	±˜Vk”÷N±}QÓ	ßÜ/("çKH]C=2iœ¸iq´ê4Æ©û”š`äÚtµjà€Úíêv{îÎYò~5ÑJƒR\'|Âù`ú»ï•ùÏl	òéï§¥Ö<’Q–¶¸«ô6t¦æñ\äb •öj»‹¤Q»`aXÄzm RwÇ’5Ş‰.9¹­Å2S°2/9Í³ÿfip&p=0İŸ*`1±ÉĞøûbÆŸ²F?“]q#ÔÎap’¡Å6Ø¦O&V×8îÀs£îˆjùÚ*ãÏ}fàuK¨Ã°’[|€‹mQ¢Ñ1*’½6á;Oü0Š™±¹	¢öìíU}Pæú.`µú0!ÁzÏã–e;Ê”äæPù)îàWò&ñ¶ğH«÷àüÜ™ùHñI#qei	Ñƒ<‚¡Àv³Êuå™‡!|'¸ñ"¦Œ"\ŞR7SpÆu3ü§ÔL¶¥lÿ³^5ÃÏzßîâ@[¨—ÒÁ@á¡µ2ZcüprÕt6PgvØÄ„“]ô'ŸC†ÕûÖ\îƒfhƒø €g`ñVÌFu#	Úß^şTèÓ­ ºÉîPR¾x³êİáNN9zXÍjû:“ŒˆÃÁcÁ-V
Ğë‰™7è¦ê«ˆôGµÀêÄ<¿ô‡cß=rËNKlV>Ñ,òôæÊC?ª’aX‚d³z4‹ Òk™Ïq‰1“üKq|‚A¿%Ó
Ø!e?’Ü;1JVJ»ãÁH4ˆ±‰€¨×rëÚTİq]ÄŒš\–@	ş[ñ¥T_à’fF(Ö‹6†{üí!—jRRm©Nè¯ã¤Ö3‰$4h|4|ˆrõlÕUµBøÚ¼â•ç’Ê	v¤,‰tv®ªêw#Û!dR$?a=õ$X-„RPò Ği·bÿ›;W š±‰<‡»½~½~ãò×æ	Ô
˜OVÃÌ”¦LFWÚíAÂY'pê¢ì„›÷BéÓÜPDJ	S	BBÁf[Kgİ˜åwXj¯a3ø~E9úº)QûÍ¨ÜÓ*™—èbE‚ó²‚QV4˜Ó>ş‚ˆoˆÕãFíò“}Îí›˜í-m7òVÜ€±¤ú¢#ª9n·@ÔìXúî3,¹@ZKÔwÖÅ6€€U£„Ğ I‘œĞÃø;à¬O¡	ÒA/{Eãù×fî°ÛÊ‰j0pj‰ê¨¤’Aæ†E–”æİ&ÕàÍj¤ö—¹€%ZıXX@/°ÆN‹«ƒ"¶ ÌdHµÁ?ˆ	ŞD¦9xµøyÄÅf‚‡*^ğúñ*+|òÇÉĞ!a‹C;h»ñ¼aöñWV?Õt™ÇdŞ±Ó‡S]ªë—çvŞS2œuOÙA¢…Ï¸L?×Cµò3½F½Ô³[ĞY¼8°Ó¦¶?@ ”y×Åéáè&ÖİXà1òñp±AGDmû¨@íh|*Å-XåÎÂ
âHLÂöû.Œ7dZıO’¶`
²|Õ°¡f¢7¼ÊUtÂ¿çëÚ©‡»èÁ2€;-«À°?.aj¥ÊúC§¾ß|ôõL-‚º$\°éH€4bús[Â$RZÇ1Úá†¼77+ù‰ràÕN ˆƒµCÁYeµ™ôhÅ‘´®olE1Ùjßç‰ŒSæx2ÖÃ_Eüœ¡à±™èùsív¥ó!É3qH½2aÖOh¯şÕ‘0&w<KÔ½1X†.<˜Í•çÊGªJMÈ<Ì.à6@vÎÈ“;SîW>Ÿ÷€Fø«oõ¨1-®8¨$È€D#jé¤q{Î6-{4“R6amÇ<¬^á;‘4éæéWó±`ITj¡€õİ„-Ëb… \ˆÚkWeÏ–„*røàX´ÎjÌÊ3Û"ó«:Û<³ÑëÍ_<eÊ¸Šl›§Ú’]²°Evã–™5ñ
äZL÷ë‹™&êš§Ì{Üogu<Oö¹ÀWË•Ü£‹	ÕD·ªüŞ]TL(ØR©	`¼5~³}pñcÑU{ÓÅÒáõıcØ“Ğ§*ÉJ]€ ÓCk[4#æÓ¦Œ·?ÜòÅ«À5„-Şz>Oö«*ˆq°—ÏtúÙHÄ¼$?¡£´ˆõ!Ç†Ù~	-²‹ÖŸx‘cÒo†İAjşõymDTl	fáèÚ>¾µ\ÙÛØilÁO@kÁù%?µ¼êÓÆ`§W- ¤	Öw­7ËÁvU¼Ã|´¯dêS€Ú8ÌÍ›%¼Xô¥7®K\.é²
Ì,İ»`Üè“ãŞßË¿èbC2‹hlW@®’h^à pi0Î\®z^Ô³:¬¬ª€‚àª\Œî}‚9u¹aô2hu!?«ä¯®MË‰» ô…úğÇÜ “áŞgû#'íqRÅCƒæ±Õ1É¦IºŸºAáŠO»¯ã•KÙa\_€¸è“9,öJ¤VØãgM1è"„–ã¾P+Ru°ñOg’/®Ú‡UËëÙÌ/Øİ¬†ƒç™/´–ñ#O¶¡›éÑQlÚ>JˆÿÂWêœ2Úöàm!ek€óT×Ïk”ú·ør½S–¬²TV`TñQİÿT³œäûëtR9#JÀwè÷³J¡{şÓÉƒå·=¤ac—B2z`T’Ï¿1iÂòl|H|cr½fß‡k)‘àëI‘K4ERºÌ¤q£È‘Èy´€
‰Ø=C”1.r¨Tºä¸ÖãùSı.ºš„‚¦'véh;I†ïÉ—ßMCV®Ô*»¸R>–€î
Ïûºbb.cXÂJë†©½‰Fº£Lœà‰&9Ûk­)ÆAt`lŠ‹E›Š1)Ñ&Ñ:–T-&<ûÙxŒÖ;“²KS:­vî£)BÑ-b×'éÂ1PD­Æda@ûĞ“õ©d÷ö”^r¡á†!uUü–=İX+	‰fq#êsŠĞË8 B¹~|Î•«œÄ+Œ!'­Ì8Õñ¿]‚ë)D0ğª»w€»	m{â™Ü°ğ“-î”k;îĞn_¿¿ÄK‘ç¨Àâ¥4ıÜªcôXğrÎÌóVDçÑ¡Dş	i	/E\o‡£™cÙË¬…È¾Ü/OhĞ¤n[ësÂ‚íÈSúÒ©ÕÊ°åå{"Ñßoì ¸rw*l#~Gn7ßvhƒTÕ7VòØˆ°íæDáMz»c5×&2«äƒı¨•Å€xÄ€Iş=Î:±8Åµ<zŒkGÍîş£5ÌH+qØU±¸Wc"ı>–ñ)1 Õé¬È;7›i ©å~áüb˜®jÊ±b¥•Ù¦q„ù&pÙ¯l¬“¨£t5-¤Tc]G×	³ˆ0µrÄ¢eKşvw^õGÃCj3ä¥¦Ü¶àëæoQ+<0Êİ¾›ìËS|Rò!°Ò³GÖÙ\iÙ`ÓíèÃßA»9FÆ®fÀÖ9	ä„å1†àv«&;±ÖÀÏ„Zcšaáö]lGÉ†9‡¢ı+èqƒ\²·S‹xìê»…5¿Ìšé8>Y®M{ëÔvMîÚûü¾WIŞvU–bUåÌAhN»›ïæ0B™Ùeôd(Î.î+´…‘íSÄ
¦zí™§QË"©«öìi~€o"ôŒgGşÎœ ×0zU7Z}Yµı»Å‡f7ÆöºÈcÿ˜àCø)ÕuØè¢ïFY½åuAOR\´ïtQ…áˆòšÂáI†kf–•ÏÀIÃAN™-ö`«nÙÛzâÂ@õk]¸ƒ5=ë8J¢k!©]
EjÆ[©	>JÕÿ3DºÊŠYo6ƒçÊ	|6Y0·Ø "@øVÅûÍ	æ$‰Xh­ık6rBa…d¡=vzQgá·]ƒæ”éµñ@?ê˜]Á~W›İ A/àtwÓıVô;„4‚´ØQş;¦vº(ÈIÔôİ¨œÑlSMìïˆ½2jo[t7‘ÕhW1­Ìá%ıpº®’Ux(`0Iiü¢DxA¹ó6ÕÑqLBY¥U>Ç¯4)»w=¾zİøŸ³)3©´Õ.Mx†C°‡d >XHÈò|<Ñ`¢™•ŒßşÕéØ0BO?StUñ2ñ©ŠW6¥/gÈ5ğ]/å\¼mO®ã1"v‹åHû$åòÍ§|êıjËÏbC63:‰Åã×‰ØË„YW˜2¿2¤öª‘•ÿ¹V#D¤d‘V¤j¸ —ï€µ­´>NÚE”*ÜùãI?ô@®C¤Äã,H¿7$í&úi¯è‚gP
ÉÚ,úv¢Ù–ãõ¤¡’ÌÈ-ÑcTşFØı²®›h>nä±¦R¡ú¸ŞĞªŠáZºÑ•›8ÿœ|îÚWp¥µìi‹ûp§€À#ÔèôÇ‚_ëñnâÍ¹ÖÂ.½MHÏÁÑR¾Ò»¼ôÇŞLß{ó( ò<u­=™—+Š¡#Çày$CXX	Í¾9FÁÄÒìcñ¬2Ùpü…†r”"¾£·‚r–¯Ã!Î .Xï@¶#6ı{÷Ë+D^â”ã³¥¥sÖØÉÿS¤›Ã[>“ÿ…lñîMÔ·]Ç_fMºk2¸ÛîÕf3Ò·Ã±ñ0Ø^0ŒÎù?ÿú°„+ğİm15·)Ã_9‘ä8MMîñ<E0fšç;Ú!Œ¶¬(ChKBNğé…¶gF_L¡rä°BX&Ã¥t6şÿß¸ÇbõÕ>ºcM/½–&"ˆÅ¤7=üK†í¯êµ*‚âA$["Õš¼ŞlŸJpğÒ¦ô™Û‹ŠüöÔ*0»Wr¦x\±ÃØÉdñ\ ÂiO˜Â'rœo¢H–æñÎ­.3û_ 1¯§®GPjûI;ú¥ë5nõÍcx<õ`ç›V Oì½uàÕ½ŸD`?í—+‘˜Ã#"±*­>¬–e¦÷„ÏS¥=üª•Ù\CXeû¡)Œ„9e¤eÒ4@gî|[¥¨=°©saFíã_Jëš3g\éiù2•Œ¤]P4ÎN·áCÉW›æãè$SPAùl©qk¨ :KÁP¥?c*¥Ñ[İh§ó¨/A¾¨ˆãüË\<?½t¢ÛÙ_¼2fâ+
İ^XÌÁ§`My4Jsİ‚ôÇ(ğó8„´Hº¸&ÀLN‹qšƒ·óIEox¤_KåÁ A¤JÑ1WEz]vHdTGƒôuÿ×FêÕøİì3SÎÜEâ‹íÅbŠû¡‡Îj>$¬ÆNHiií9 ©lˆ¿Ó_ÙùNWî¸T_C#úøµ£F÷ımdÚ~ıo|@Ïõ»Ä+ºéo&0’*1Áu%ÖÆUÿH‚ÅH0÷è‰à°î‡Æ}¹tÜ±_] “«dÒ>¨:wÑ)ÿo3W*Gó°şê(]±š‰	k•»­D}¹^£[ZÕxÒâÔ‘‡¼u÷fw:#4å§ı Œ˜HîæÏE\}FEztZJËÂLyx5oî#º–é>!è$Îøûm¦\áïİ¥?>ù:ŒÍ³%&1#7Cö"Qm`Ñó¦ó÷YGé¡©úÉmIöíİcÙ—3ïXLÿˆ19°íq•¾½Yêfî?Õ=UŸò©ñZÃ¦8»@{•æ1<Ëö½ş/¨ÇÌ0e­- ™#%„ƒ3¼Ê8ô!?%±áù 1zº$À>.Iú-;ÊŞÃFit £.òÚ:­êh
£ M‡kƒ<ıÉn‰‹şCwÆ½Û£è"E§25ŸCE/æÀ¶Í¹v‡”ıìî:¶.ø•ô»ûÔ[bTÁ5
Y(<ÆÿÃş÷vgª$®zl¦ßFmˆPéû
k4\sKìêHU§CFŸ®¨×³7+,Ó`/(deyÙ‹^ì,[cæO]–uB»–¹Ú	Áò‚æ/ÛÓq¡ŒâB–G›„€™äEf>ßåÉDÚXw×…3;¦gqÍıP)›äªğúÀlbL¢úàşWê\ø¼¹ÀÀÔIrŒ¥óx¼':x”}U@5l£
øÖŠEés‡<|8¬Y~™ã‰2¯/)ghùå´f–ùü>¯+Ò`ÆeİoÕ<©rñÔÔ7‚±—XËç(#†Ğî®	«ïÌÔ¦°ªe¢9Ÿâ¸%Ë ™EdBF[üeÈ¹ç¬Ïãñ1ş@öÆ]ş¸.,WàÒßF;ÃéH–5LÜJõB#{”f†Â²š8ÊN`ÀÓM4ÆÀµø;Teß×gvÂzY–uêfJd‹GŒn¿Q„•ÂÚêçAÁ#Up)AŞÀŸ”M’.™+	$W°}ÀĞ…4üÚú‘¯¬õVR (Í.>oªÓìEº-’"»)¯QYWÅrœ‰÷-?L]–ò/¼‚L›¨K´OŒhï ¾1¦?lâmï¢/üÊ$v\0vÓqe_¥dŞ<A®rÓYâOE¼iJtÔãg—q€V1.î›ª˜#nP–n©K`½ûS)¡ÖFq_ÀÊc†X]k¯‰Şá~ıæÇUvrÔñ[yl¶å¨=©¨›¶j´'-&¨g›¡­-²®[İ;,cŒC•õ­û<ªÉ­Ë¦X,zÕ±»$95CŸŞ}ğ ¤IÆŒT9oCÎ8Ä¾{=}´Oîª±"ôBùO%¹˜WÜÿ”A˜¡C•Ş±ä5WV¶U-(bì¿¦‰æµw9¤$aç±Ø>1Zô å³(ÚÉª¥ÊŠ•İ>&ÃÖœ£àãt’Op=›6 tíCüÁÿÓ¤=õÁúO¡iWDêÒ.İt/[ú	ñ¾A<ï«¹¡×yvÙ (ĞçA ‚Ø€„½idÌycğ4ÌIÇxQ BÄr€2d1’£áÇŒ˜–]ÚAó«Ûè#Ö¸Äd±’ƒğïd
«Š”{xpÃrJX1÷ÅÕ#8„“'¹‹ù‹¾HÅP{M Wåwrc©¼ycW®\ÉM¶ò°\É<ıâÇ¨ã’Ğæ´ıæ0_økˆ¾F&ÑyYƒŠ+ÉÎ1¥~ªÆÄÊ4V®é@××¸A·UËÅí˜ôíÜ÷ºdw˜ßâA®õšJôç à{¾î°Ş¥Éå"­£R>;0×0¦)Ü o•Ï%„"ã%q¤L#KÏ%åÙRÚu9ŞÎğ€½5Hæ®=Öh³…4}}WËŠ¡Æ7¢Şº½E¸Í•€%ñwİrrBhÕ{nìØX.»¡CÓ_½„Â›H•{¡aÁ÷ì¤ÿ Xˆv›¶5½KöSi–¿]?¾p“:Ó5oMŒ°9%oÛM[d„1-cc×šé)l}“?§iô¨µ™*…ÕxàÙ²3íÉ{^'1”Å‘ªø¨ôhz~–àNìm’d`)ÑPA[7ãG÷‘´ıcÃÚ’ñ0—Štø‚:çq!§ıë—ªB_üB¥qvw7CzrÎEµå#™³Œ+@X'¯¦c‚¼Ôy%9ßN[†Lı<£öcfù¿…`JÊ÷’!ñ´.Uôßs°K0}|I‹ºøè"‹6Gî´qÄÚ~¿ÀøàJ½Vê0]Ğ¸w¨ƒõşËv‰ÙÑEŒ#®R&¿"A×IÍ‡Æò Û¿K¡Î¤nó¸’ö&ûÍ9´_i;<9„òÓŒÓõ?ÄGL-g¾È‚N×S `¡µÒøíq.¥¢Ü{ÛÅÒ3Aƒ¦+™:¯¤&®¡˜Š•—_ç9Œ'Û¥²f’ˆîİ-™¤$4kn˜M5˜\é\¢Ç¿Ø\Åe¬{y‡ÄÄiøK-ï¾ûÛ"ÍV$x_ÑPâ´ïéj {µŠŒ¾‘oE£$ï6—y+Š†“{,®ÂÅ‘Í‚8ÒX”|mÏµû7ø3Ç]Om* ßœFc“ÕğÖÇ'©@Tv„Wéã±#î	îrÛ¨t”-˜\ÖW{ú©.%§`zúZ$Wµøó²ÔNş¹æÈÆ—ƒVæ¯¾rå|[7§Ü¹pœjUß€áİa±‰šëZøp¸^ı ÒÏ^àD!R­ÄQ§ö²C-=éÛeûlz…cÀ“ÀX;xÎ_=%±Xµ ã`%q¸¶<ÙñN3HXdFd¸Mã}¬×2jn—W¯u3 m,|éÿ1â²éÖ|Ë/>•iı;È¾d.	Yƒ’gv÷1<áâé
£Ô	SÃ	ã¬;Õp!/?_3)—¿}ÆĞFÍ~	!`%ÄKŠˆ-“Ú$\N\ñÓ >,õ¢è„LŞÒÆªJĞ[=ø€Š‚²+A4O”Ê8“¤I½Ò
3÷®_†:Ë—ôÉœîŞ9ı&â`ñøj?{W…Í
*F».¿ç/«l)ˆômY¡Â|­’ÅÍí>¤µd^¯.Å"¤× U^—ÁÆqŸYXu!˜hSB~WänÏcg±´õ6s!.$oª|ã(ÊvíaÀP‡âZFÊºó$¹Ôær¥Î1¯®ÀuS/–)HTä·±Â¨‰²^“\9÷ğíüï²ß'0ÔÜùXš×¾6·€ÄDˆ-`ØGP]ù1Bd¼CÇ>ñ~¥
ÂKB§_¿|¬ó5­'»”¨ÆŠÜƒ•ê¶D”è¢µbò¤§4$“‡k»şÕ¯E©0K.‡dÛ­ixé]ÿ`›‚á©†+y 3ç¾*!Ù¥7ÑøÂ]åg‘!×õ€tlj‘h*asÇæE“0âÉ_™˜§y½ ºÉ±~Gñ'œë<?¿¸oâbª~¨'Ğ[‹9×¿J˜…úlSTèiæï%Úv³ÑV†<†lŠá÷ş;_¶ú¿†AHH¹](b¹î!vğ)Âu8W×ÓÌºÚ¡¼«Å6¤—3òå˜&¢ëâ
aÎœ~â<æı›¼nº8l
¨ÀqßˆM5XŠ«ËtœIƒüDsR’Ÿ`LOFŸÄj
§ÌR…!*=;MøLëfdÔwuIÎì—¹TÀå|B=´PÛeS@ãˆŸ¥«£2qp‰™fxrq.\¼”ç ¤_ëš	˜u‰ÛîÆ~oŞ*V© [&¬åÑ:µl©EF»&Aî÷Có–éú€[˜ÍbulwwAv}uÅÌwO¡YÊ™›a¯/Ò¬ÓOŠØ¡w¶ñ¼Zc‡k&RqµĞ”¾gĞæ½ºñ®„ïÇtvX)æ3[}ªğmÁ²¶Ù÷‡24®‹AóŒ‰*ÉÈ´«Y°ê´ë÷ùjzÀóW^e€
up/Ÿ„/Şë6¯ƒ%;JÿŒP)Ë®AøvMó`â<>ºQ)òÒ¦ôşvõäª§ÉÎ	TVÇ¼¶9;.Ğ¦¬æ•U³ì61>:¦Nà•‚iŞÏFpGaú1Ní½"úzC?l	pß[Jp+²?¢œ’:
K¡6QkdaO§¥õ$bymjy‹'÷|ÆÅ™æãºIEÒ‚>ÿöÂñ#!Æí^¥_…<¦)å’ÆİáÃ«¢9(ãºùL“ú`;>É‡‹õÅ77Ÿ<B e`"Jî…ÔŸÙ©(ŸÜ¸¬™k7,M`G0ÂÒ¡J²6æû*-$õê"*ú¬[AşNV8YßÏ‹ÍÑb„}~7ãU´í´:`á}Ñ¥Ô°ë[&N´ÙpìÒ®Ï¾«û*	Ï°ãrÉrÊ‡"ÅYtP×ø%0Ûš+~‹âî‡Áîa·‘N¥Æ¹‹5~Ã.Kfğ”R©è(e$ûm›Púaóë&¯¹É“,%à‹ÒaëÑ’˜=!œşûLd/åArh{ÛxcO6á‹h‰²9<û%e‰)zù#“"ê¾½›^¾ò­ ^6#½ L>ü8Ü-0+]u”…GGç¢@±ğş¦®†CìÌ»zN®(?ÔÙ±üıF&ï„ËV„‘Ş¡èûz‘E~™ÁàÔG7ôsÀW-Ç¨V\!NHÆ4%{æ½ ‡±å¨xÓXMã®p³<kìZØÑ¦5ËYd/b¤ÒÀË){9è,jD)¶‰]©îë\­}>áX7V—!‘¯×ÈE©guî…=×Áö‰3ÿl½õfè“õÀñë³²“(ç©în=è6iz+‚";P4Z‘ˆû¢ÏÎÆiKÇÉ$® b z“¨<Õ™a@Ún6Åœ„yÑå“xA‘Ü¡vVåw[_8•*<§ƒƒ»Äo]	Iª–²Î“Ê¨¦2db)E<Ø”Ûÿ‘À“
XDÔ0h&"«	ÃŞsë°sgÎ[:tRb©¡ÃÀr±/Å[ùz(‡Ğ¯"%ÖõóšO ?,ğ8Ã€ábtk·9ÏÑ?VÒ5&xş=6ùwÊiˆ”øß^şhœïñß‘¿×£¹d®Å&>W²("³,”½›Tíˆ0\ER€ÙFØ.^kÎ©Æ·¹Jûæ24•Y«qõg`–`DŸ½3P-uÜ»‰VkñV„7œê!§&ğîĞ„g–£Àƒ†¥»^¡©Á§9ÔÈ¹Öó—§ ©xğª|g*)€jÎ:¡µŞ/u¸å «<ï{E¨]·¬"^¿p30…‚ê0Æ¦ş£Â°12‡Ú²]‹Ğ<Ê_î3V£sØqc¤LôÂ0r«S©C"¹Rz9Ü»Wñ‰ñ¹à¼¡ÔŸáª~ß@—ˆ"2\¹£Ğnpkvƒ^„#ö²™$¾D¡§ÖcëqäJT²•&òSl•¤¿×3TÆÂ+`Õ#sK}{t£/|]\
Üb±DtŸg›Ğô‚¿Û£:ì¢éÖ˜ÍyÇ—¥mZ‘°ÂP‰İ¯Vaø9F#Kx¾uœ#BÛ±ÀHÄl\²àé. ò*‹väÎF@êæ¥şÙeÄ–´*µn^ŠcÿO[ïgÏæ¯@¸Ú¥WRXõ°±Ç%@`½Îú%s¢8mÍuñ¾¼ÆÑ3õ/­ày™9ê6z+#6^ÓÃ›gL${äèî—]‰…°s…CÑüÒƒ"‚:%ùîúûá¼¸çÀï}&ÄÃ¡åç¦´úG¬wŞ¡€Ãó'¥øØ™ô>pøÛ£qƒ¾>BÚ!î¥â¸@À…Ü›×•ì×q0œ×æ·Íø†t¿sj®Ï`Ë|z¸x‘Ógûıà§(t;yeî›éƒä³ã9x–ÓÙ¶cNÖØ©ı®ù0ì|‘C¬:r±„±"øRæ!Èwİ¸“cPzW)fä…À©+ğlw6¨@/ìDƒ?¤oÉ¹®I×‰?ƒu{e^Ëlêµégïç²v~êãÃƒ`5çÔú¨ÓÈpå"€_ìCô–°*“è5:|u}êÙg£´ÉÅ¨\én›*F*-g4 $NÂBìÍfÔzoÚ+Ê%n\"¹×ÚJÍ­ª_ˆ5ÉÇw¹vÁ]úÕÆĞ%–ú4mk,H,OéøSÃ–! ‹êµZMè×ã…*Ú·0Ãe(ìå¸Ùu°ıAcx¶ŠñßÏ¡ù¿ãÿ¬Yã_£8¹•¶g3HŸFĞÌ±:ã›yºdîÕåØæÃ¨}o‹\;fvËP0ü•¡‚ÕŠÙø$àŒs”Y\É¢-7é¤M.cYÛjñTo‚#ù€¨´4_XğœR43›ûÖ¦Vh’º¼Y,â¿õÉ»Ä$Ç®#¼vÆÄ‘¸¿xæ¾<¥ƒ<‚D‰îÔÖ}UÕ÷ƒß2Dpõ§VyYå¯–éúös!ç£Ú‚³Á³7Ïş€mÆ_ş?![¤,K„Xß7æ3‘íf¨´TUŸ‘ìÂUC>«‚Ø“ OøªJr”ÿVFbY|Õ¯ÚŞ»ÒÕúÑíe“o±ğqxsDl¤QCQİT’r‡Áôa^ °ÀëÛÕÉi‚÷Q£Èk	'JÏ/#g!Cß'œ½èwAX¨™‘2¤$J!:˜ ´kO€QP&im_u–ûm"vã%œÆö'ÅĞmşcx.u"5Òa1.xR»;‰¦ˆåy¨‡)¤HßpE­z™kŠÖóhÏ6Í«eø«LË»íÿU©Jù]@ş‰®zó©¾ı­=ã3t®x? àÚíŒc¾À•£Ds*FÃx4d¿#_³.ÿŸã×§ä¦ÈorµR]ãüI %›¯´àIÉ9$ñ®ZJV¬Ó+©#‡­É–¬{7åÀ(8S:²Ší˜4©g|©”­&æ¯ôÄ™ğ ‹Ì÷Û:… |3øe
@ºeµBÜqcêoCèëD ÓùÂ"u™ı6Jßíép€üyärƒ£“ı\\H-²OUiÖÇI3`>PFSXóê­5MDNÃ&¯'Î‰–pl±!gX¹tÄ™™"0õşÉ¯˜`bHf‹(-v}ŸãÔQóRéw‡^MK®î#qÀíµ­Ü½dÀGß>êë¤Çà]¡º•3#?Ñ~HÖsXV»·TP8*dñ Â±[Ïü=®'Îø‹vÌ!¥ÇxøÔö Ñö,ˆÇ®ã¶ú^¨èÛ¹†»X8Å¢ôt§Úb`1õ—GîÈq6örË=‘º)[ ÿZèŞ¿wsW58Ê\å‘:Õ–#ªR&ê";ß*ê}“5¨…àXÚL¡3ŞÿÄDS9{“)7õºNît U$YÿmëFí„äQö_RÿP·mì7"×»,C¡µXL^6Ñ&"î0ß¥Ñ÷$Îr±`Û¸½©n€	(ª#Ì‘Qå¾n-ÛRt>, `•¸q,Ôuö© ¨x¥÷oÔ6ÿ:X Î(ŒÅÿh›Gñ€äF:Ÿ^k¹ã›xª;6Ç¨o¥EÜÇJc¤¶)ØÙŠ¢d0®ƒXõ†¤a}‘ñğ3™¤?>ä«r¥ô~Ä{™sº\™éÓ•r Ÿ®Ea<]Úur"ÑcöCÖµ'…yş½E*¯‘ñ„ˆ¸­¡?>],K¹™%ƒëSÈ¿I®L!ÌÙúÄN¢f1ú>vOu ‚3Â%Bø:İ¾<ak×Ë1ç™”VÖÙ¬ı³ñ@úÍÁŸÏwÈØåAjLşc²J¤²»äí4Íˆt*w´!q,½UW)i-DTJ;XdO³$ƒÙørEPé¿ECÊÍ¹Å9Ù%Š|ª»ê'/vl…EÁB“¤å±;”›É ßÿë‡¹ë—_“•?ÜÀa*ÀŞÙÿÿÂñMrÁs™¾EŞ›)‡ĞİËìKjÈê šntŸÖæàš1rºˆUq”¥ø}0.ÖÀ£eUgNqÔeŞ&u­AA‰qïÊ‰uó»°—¢+=ˆ\¯aßıK5¬ïÕ|jVA
ƒ:S]\áĞnf'r.~, Áœ¨ÛèïÁÎJ¢HÆÛÜíÁœM¢U˜şÖÃİ˜Âì5§©EÌbĞ;jüw÷è˜ŸŞ'õ˜Ğ—“Å¡â¢$ŸÙLB„øU£­×.ŞÃ°·¨¾ÕÎf?šs+Ùß®Ÿá²NÛ¹%‰-éçÁVÑ²”¼¤‘å1ìÑâãJÆ´âûõÔBxzàÉ@ô+Õ¬4&;ÂÕø*PO1ğ;ô„VÕğ¿Kè¢3ß·”" q«d£é÷—,±‡î<ƒ'Ÿ70¯ÿñ&·HÙc7ßn~ğ_JìÀ}4(Væ m„¨j3”îÇçËÉ‹¯QñiWA(ûIQ—©ÏQº×KËÄÉÄ[_·Ä<K6Ù.hSñ<ªÇÊ ûÔ+€oS[LuZÒ(¯t5ì£ndø‘!Š‰”„ß¢$æë¬`)^äÀdm· ‚AŸÌo°o«SŒfÜ›ö[+M˜8À"szj“”°‹uÜ»}ÕÉ‹cÎÔÓ­o¨O—#¦ı‘2>^Û‰½]“¸ËÅ# [ŠZË³´û:¸ûåtkaº£Ã‹l«ò™6û§Ë(j¼hóğZ*òú|UlEGÔ(¥ä¿O9¶"¯,N‡Ğuø$™‘ü¿M}O^wé±Ep­$-Œ6óéhx”³«)½ÜE—¥èr”$âxı—#ºçµOsŒó°–"CuæúåÇûÑĞks’[—Ìt!­3ßt‹iR)k™™RZó9" jñ3¦Ó®­r…ÕİŒdã5¡Ø89!n„„Óånãe¼ÈÙ½  iF€DÿÑb»¥qïİÃ¾8øÜh tö‚¹FÉ@òjMÂ<Ë±¹Öé˜É^ïeßkiÁ¢js*|Y†Ê3±O!î6°sômºì¢iƒ+”Yş=&µîÉ9»uáN×ŒW1>«ö#-`ò%‚Í•|Å§!DÙ'U.2!¡4ªÂä…&)ìiN·¤â^›àÈã¤ÍcÕ9¯Şgø¡«	Ò|©	¤ ÀÀö¤aôÏ–a ø¢`ûÅ£³‹àFê¾Ó˜ÈŠüá /fŒ°¶P}€àQŠıõ"°õĞÜ ¼%6ö¥RÒËSwW›ir¹õÊ—vO¦…ÿü!71 WFc ¨çš‚ĞãQÂcHÜõş‰‡“blMŒe…>Á8úaøš£\²·ñÎĞëNà"n¦ëÜ9k(gâg“‡¨©è»=ôË/
ôŒuGâ(£S¡K€±&¬lm†uy!(ÅdÖz7Á‹ eR'´š}øù>S-Eô…/YQ:ÕTa·J-ù»k'9­š½_CæL@CÍq®’êoŞ„3Å-ÂõÓ’)Wş NÊê°Rüˆ_ƒà$ö	¨íğ6Ëåœ¼a³ò­åÁX¨2‰ÅJb„azºÌ{‡d)åiZúOÍ‰Ñö¤Je%­¢\çüÄZ°
Á Nâ È<#k
	ròhíüĞŠ~
£RÈEe”ánuÊ©ÃNN[¼BCer¨’¥ÕœÇÕÌ™¬üÆàçÍÚO±	4/yƒÒwä³¸p=«øÆƒfx&$y“ÀÄyÏE²óÕ#ãŸƒ7gûªÉ'ŸZØxh¸c®ùø*±vÃüçôBar‰-\Ç¡gĞ>qúíS?ÖŞ­÷—Gê7;nÌNŒ#¦øX$æÕå÷²wTq5k¦ãEïÛ3…Ù(T}\¯ÒæU~‹˜Ôc4—ŞÚˆ_¯hûyÖØƒü¥™Y<ş¬ÑºŠêÁXÎU($Œl3H”æÚP˜MŸaÃ?<_ï­WÒ?İ\MMÔŒùpgõqcè­Ğ[p¨penêÃ«VŠ2õ%Ã`ã<'ÒÒjajj®,É»1¢·ÃJPğ¯PE±Á¤€¬5HP>x›¡~Ó1PÄEÇln¥#'fw2ì¥=áªtÂ»à±x4úè~:tmáó7Ğ£;d„nı‘êØ3ŠX;“ ‚(ñğ‘t®är‘”­Q	l.¼ı'=5#şƒúÜÒ1RØ—E9 `LÇqW°r\¸ÏYó‰­Ïo‹l÷Òïxì½4£2?ußaÌ]³á¾ˆ¦ô-Ò…Ù´é qÒñØ‰ÑÇ {á7Ø‚ oXyl15pëˆV£&­‡7n¨ª^Bù·’ø¡9œ¯Gƒ§J)¢ ymFáº©Êõ¶ê1…~oS@ÍÌötÊ/_€o#¼%Ò‰Ä‰b£IŞ@½ñ7ÌÜ¨‘©¼qôˆJô!ÌB
ÇkU
Ï5›¥xœ¡z£¶§½$>èë*§˜w/å%zo<CŠÔ¯26H{ìg°ÿ«N35ÖÈÖ"˜ÍÀíá©*i¨i+*«€è¹tB3«^xÀ’3©0ş’ô×ºœÍá[­QõŞ²–'|¤r£€Ï`L²…è”‰A…²s);}n€ š³3ëoDI@ñŒØJØÅyp5[V×ÀOÅÅ÷¶ï‘!?³ÒáNİAÚÙÜTÚp«Èà›)Ål,ÇŒüš£xÜ2|ö¿êÏ	JKoDNóhûæ@'L\Ô#?ºvâbÂ¥˜µÄ‡>q(kj(f$š­òãJ·Ú°>¼©²ÕGbfHš§>Õ¿Ó{à©šÙ–ÄƒY6c1ÕÂ°³²Ë4ÁnøèN»RG¨áv!¬Dqz=Ù¬ó©Ïñ•(¦x‹Åq¾cewçTj°ëdxº©£¯˜kh –îj.·®˜"²2?ÀXÚ¬v>$y…J¹¼N§0áZ™{f€èœÁº‰èŒ³pZ„¨éÒ çSM¨z¨Ş0Òp©3~Õ!ªô‰{`9H„Ì³!kÒR	¨ şûóğ¾};Ğº7}6‘ÒL[ká(µRÛŒ¥MƒI:’*üÏã[a khx“±
áb€ó'S`$vñ÷¤¬€W4ûÎYÀ+±±ÊèÒØğ\3Ô8	˜û£Ø’G•¹.ËN0Áùva^ÀˆlÃW®Œ?;º ½Ğüÿ;t†ÊóÙÊOÖ¨ck´µkôæ³ş Û]p¤Å{;Ô¬ Ú^C•¡–Øç·‘×§í_á®((DœÏV'£æ
oOK³;HŠµ@&À>vvK¼+zµRu]â|;Ük¡0;¶ıŞö‚=.wû¬gE–uMÔB!EqÆŸŒ$æÈjÂ¨šˆYLqæñ§×~A•÷Ép”àNíÊ†DVG? TEUH±$v"NQé	’(éÔ6ıp™PjÈmË^Å„pµ†TÓ«)åÏ	MÛ`^
nmğ*=7Ü™×ÑÌB½!^C] iêæébÔ%°µh•.ÊöZ^_ç÷©cÌ4ïpTy'%áÆ)=xõëğÜ‹íá}WIq5h4÷Ô›²<'z. 9ÿwvº¤£ÈhgË0wE…¨ˆ4‚£Š~ªÿìvøÛ—;ööñ²ßí%?l…q½²9X~¼t£äM-!2
87‚$(<–Ó·ÍÅµ]›W±*Ø Ájb›‡4ÜÀÅ	ñ	×”È¼¢Í+ÜWÔJ–‘e…şãN”`ÅŠ¤ñ¤8+ÙŠ¼Ûäu] )%–ÌÆ]^¬«3s‹w•NpXÒbËöœûw®Tz|¯V]Fº`×³_«XìÛèOÕÀ 	à•DD’"o•>dóYndÓğ¥å–WÏ*ÓÄE	Šİ¤»,Gñ;*‹ìã,|ùÊD(ÿUø–-XNË&T`-°?—üBk²w©{ÅÙõ55²!³ò¢ß{¹!÷èß4u[•ù6gU?tü·2çÏ9¬ÃhÖ’\™ƒv*[/ÚQ,ÒGju¾®É•ŸC¥úÑï¿À'O_&Éq	9×4VJÍë,hej5ÃŠ:Ï•›°0MŠ‘øöEÖ¢4kFCë’ƒù¢Çuù‹ŞgpÔA–W×qêe’­şä	_å6S'Y®¢î˜˜·ŸgÆ	N ?P¾ÈO3hUœ»Şw!õå^Úÿß¤„%}‚Ê—†£E^£!XæzÔ'šf¼ç\ƒÜ?^©ÅKœúv5Ê}(_ /"M¿RXEtÕi¡Y5xËğ{%P]¹Ó”"jî†Ö8ÄZÄà‰ÈFË ½™˜PŞÁş  
Ö½OF 4£óâŸ+öæJç}MäÂ©È6P5‰](ÖÕ&qÏ¬’Ÿ£ğòÇ…T×¦UÜ²\ıìGÃ«WEèu€] éI¸ôÖnMçKW½§±¤:EPğ÷„¨ÏÃ³$­õ‚8_ÀÕŠ÷ğ‡¢B¹Ÿ· 'ŸCúlÕÇ–Ä8÷‘5©×Şf6Ù?ı44ŞÕè¸ñeÉCz„GµÙÍ Ì“%^TéÕóê¶§–¤ÎMÍ/zrÇÄ¬ÍòVyO®sI}_[”êÊ¾-‚M·Íö*:‡Ácko›nm6x›Œºé‹ä‰}
VÜ1h!Òù …o9\ÆeÜ6ÆZ„J	½"<8E[Ü×R³‰á«‘>±¸ôÜxÓ¶\¸µ'l8Ññ¸€mr\#iã¸¥ä„&âÜš©H £K™<½ÇãXØ7ïÚyÀÿÊªÂ	ˆ¤€.YOßà•F›ïd€Q}Rèì¥ ×|"¯õŒ™ô"÷%XyÈ–€·%ªÚPKO¿ÜIÇ$<Ã­dˆ4&Ã¥ù‹ıy9Ur³øÛP[ŠeÃCµx”—V}³%*©ÔiM|ÖüB²ê}UM)Ê6½aä÷‰‚4l–|o¾ZI©ƒ)+ò5&Ù0©Y	Î}PĞ(Ò¿eø+˜±¾áım‰Ëç¹DA.îSUwd1Ú'á[4»¹Û÷ÙíeÆÜë¨læÁnCN°™ºN ½ËvsS{™ËÇW&h Ÿ	9«“ÄçÑ8J¥0EØ%ˆKÖ­ıiÉÑFÀwJŸ<?ˆÿâJ¤ñšY…)’¥øVĞ6ï" b­§j2µY†é¡8x„Ö÷IFQ`öÜ"rXğ‰.é d´Pî÷;^¥ß²iEÄ¿±ı=&ûóqzC¢	…¾\ˆ °h1§ÜæTem	®wı3°ìvuRb	PqoV³ïúƒ†Gÿ˜VïŸ	NÅÿØIÓ  ğÔú¬îUfJ ğÊ€sCqS±Ägû    YZ