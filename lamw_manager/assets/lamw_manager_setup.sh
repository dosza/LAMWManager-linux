#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3346947948"
MD5="afa88f205f8ae7a9ebfc5629c062235f"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23172"
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
	echo Date of packaging: Tue Jul 27 16:01:40 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿZD] ¼}•À1Dd]‡Á›PætİD÷½~0A>·çO[™j];\,ôiÄ=´ş¹qòæ16¤«XÔòö¡|
»3²ùªi B'AŠ	Ìë÷OñVê•h4¿º÷»wñ»
8İe¨ç<:N×<r–,òÓò*SC©_ˆÁy)Îœyşß#—ÖrŠwù…^0†)6MLšéeJ&O-ÉLôÃE@ÙRè÷QÅ…ı-+†0GâU2”.¿İ†B³®¬ ul’‘ÈQ±Ó‹7´€¿8ÏlÚÈg÷±x,µGÎÓªXÉQ%º‚nÓ¢$ñÜæ—}˜asp~¯–DÉ0Õ&ZèƒÌgê·î›´_A0üBî]lÅÈLãJ“Ô‹€j³Y½Ò:¢”á$\ùLr§Õ‘.[Ÿí}^ÑÅCÚùí¤µW¨ µ€iı˜Üàµş/<èu×R|Ñz[0®ÕÈâÕšôğ©A?˜ŠDWé^:¼:é3³x)Ò0 ñÓÿ™#ÅµïXtGöÿÊ®¶ÅWĞW[}ä¾Çø¥}’DH25>|±æ6¬=]x)÷^; ”Uïü‘ı­<İæ¨ƒ„’şÑ¤Ç„‘©&
Ê¨KÁ®"eE½"i­¬‰ê¯hÎ»Ş‡¤,E-@İ—ïLx×dÃ´v¨#ÌÉS¸Xïû…ˆûÛWw‘<kÃ<âgÚÎŒö¸Îd(‘bÎYú'¬Zg·İ+bäxêâ{í
û¾x¯ÌödàO¨”5¿HJ=÷µÅ"3Ådî‡Aâ‘V\óõ~ıcNğz°–š£…¦ô)¦¿/ÔäïèW,§²ÒÛY›wXJ`¨JÚÖ“FÜ.áhÂÃ€º	ºkˆ<7'h^dˆñ.xpnÍKzá÷ôÂÜ5äÌ.×Ë
 n4ä“JĞÅ˜qyxXí»úûàöœË55ûßEº6¢_økç—j Ò‹=½ªBpê$àêŒÈnlP‚ )®î“®RÍ›¯fSò÷şS„.zl¦î˜+`ÑU—pj°³z.áÇ† û§+j¤l†3FY;§†^vÓ4êô“†¹ëÈ®Tù+ñt J ò€Ì›‰©‰EÃĞù²ÜŸ<+—úeE:¬[3›Ê'áŠ¥MV? c9e*·DC,Èö3|u¦æ7Â e·Ö"¾şUÜ‹+°˜7ÅŸC>L·¡›([œ³§Kè/Õ´ãõ‘6[×Iò¿vñé½³‚v½ğ¸8…Ä'×ÑzX[ª÷sd71+gˆÿÔD¡+X¾hcÙ:'ÂxßÖøÂö8ª£:¸¤t±l:øıÿIkâI¿¯ mAøë´Q°Yy™ñúãÇ©ˆ‹<F@çñèŸûLäU4wZ'“=¢E;{šÛÙ¥’Q°3áèĞ»iê}g“Yj“u˜¡šyPÅ˜hij%İŠÜŒ«ß)w…V†=™>CøXp“à2=×3¢B;ux×Õ™ü?ÊÙX¸f@¯/>@”Dò8R”$Ğ®™øØãƒ>Ù}7ÄL?±+W’Zf¸Ô\±Î¡^Ì#æqä0p|vUÍC °«ÕN µfƒ.³øà<frûßW&$D÷ÔÍñXb¾"w*pÌÅ¡©cŒToÍÎ—!­Q¥â‘q>|L’ı˜hÑ*æ_àlI¢„ø§Ù‘ GĞShÑL`ßñßÑÊZO"2H‘‘ë\rÂ»4×¤1ˆ yÇÂÄİ ÕâÏ{ÖNdõXXšVÁ_«9Yv­]HI˜5c/Æ0é‚ğ"÷Óe¨÷š7ú¸^¹WÀÁƒÜIh€ ·û3’YjÎqm1­æÖ¡stVƒšæôg³¸
ş†§Eô3i§0‚õVBt‹kÙtª:*İõÀ©>m;„IÔÎ¤¯uöĞsx¦L}Ñô€_ÒI±bæ?'DñRÈ­/ı‹/‘¦İÀ¥¯'Œœ—S»»?ú¬j~ı3N}×wËı:üÑ­Ş<õ‡(´9âÉ‡î:üNš%enŞiÉ¢UĞ&€õ¡	šQşM|–-?àğ0  ;½”?·„sÿà¶Câ„ì!Ï*å¿LA¼h€;ÇáuúïXòéª®ìû“È©0]‹[îušŸQ, KıyÄw˜ø„	hÛÄjUH§,}ÜTÉÈfwÁ¸2¡AàÀ S0,ÏÅº‰Ğ±µVAÅ¡®œmÀ°îñ›“–@¿ÄˆŠsTjZ!:æ»‡w­uŒÕp–šºúË½>Ù±ŒÑ§û ä;ÃÕÆlÏ;k$ë-mçs
eò4Âl¸MtW)ğÍÍ?`WFıEq7gÕÜœBÉx{r£ÄcÌ¨¤mhù™©µ~Ü—R,ğãÜ9™şÒZ—BÓ#Ô“ó;n:=zö×fx‡ÕI«ÚÄº©
X<r¢!Ø1v¦v°pËFRÕ-úÍ7›}d´©ÛªùÑıT®ªs	)İt¼ö0”Ì½Éˆã=8:#æ ·ƒÿÓJû®&Š•|Nqìd”¤ù9Z‡Q”8å{NøOÃ‰`vNî‹îÈ§:+1Ô²ßWH0A+”âÿ=²±»EL¤`êy¦Õ#^™OC³2dë¦à‰ô%räYÔWÆˆgÈcï6BŞ:š›Z‰¤Oß-hŞr\|Á@Z –ìSB`6ò»cì‚yŠÛf’«¬T­“N2…gÚw©/ÍôÍTó}!)0SÊm+5uG&ŒªË¢{"Úˆ—rÕ„ãÂÛpÅ5l:$—SEùÒÊ~0jšÃİÆÎÄÛïÌ¦ƒ³ª%zÕ	ú©¤·ô[r„–V`à´)ïÁ&ßŒÔŞÔVqK¹ª?ÚÉÌùL<W†k‚N±A­oÈnÁÆ—ãöPr9ÀõaæèÒKûæE·3ÃŸ‘F]õÍ¦Ì–b ª6U£`íÓ”Â\³¢(çıõ_j~bõ¾”ŒX]¼ÀT8]UQğ¾m¾*ğ©ˆÃ|® nòç£†‰4nhÖËõ,”şèü‰ L±Lk[İ0,&ÅéfŠÉhçp.På¡|{b	Ã†ô¡Ù“KãÍú¹¨mÏÈrS˜1+\än‘@E¡+aDìx bè5ÂT™Î'›¬Ôd×tĞÛP~DX*ÓœŸáÕï^´úZŞ£Ã«ˆûD++¿Ç@Ğy@ïúIçuƒ9|ğìH‰´²ÈÀ”ÂîOC½`v+o&Ò	=y	²™Y‡µ>a÷ñ¥–7ğY 5&Ø™rİêfOÿ­´<%¡”ªd`¤)ÎÉ1Ç³¨bë’ôĞÕ»~Ş‡:òÄ³Òvd´ äúïqÃ|˜ó1‰p…Ò0¦CëëÃ;µ¬ğÊİtEj¬—ÄnKšt³ºÜTÆÿwÚÏÃ¸ùw-Bí›(Ò	ˆa§Hò¨Íw'_¸ƒøiÊŒˆúŸù@·VœÀÇu¹]K²Øß‰%³Ìı49†€l!-™„Y58” •ıxD¤µQöôs%UR+|Ï³ı2ƒ1m,§?šÅò2¥=¿`]ã¨ ¿óL f6¸8$«€hæ^ïm/ö6
ãFq)ÚğºˆlfÇ{ñÄÅáVY-Ñz¼`Z¥yr+ *é®çögè¿. WŒÙ(dÀYônŒxoº>æypøYÛo<±†âYczP ÙLÎÈ3@K$ÙşÿzJ£Ü£*Wb¡ÒfIÇìwÈ·ˆl¹œ	¤1Ú©Øë²ûñ€š4µ[ôË^ˆnT©P6o½ê±s,÷—ùÆ}¤m‰B/ÁH&¢X„¯Å8*–1Ò4¢¸ñúqµ¬õPOPèFú??ÉÀizò]g×„¬íävö¢vaµù[FÃ›Ÿ°l˜0ıè–k~P^¨épıéJ3ïf½O¨÷Ïn¬™”˜:}w©1f:6›ZHbµS¬nª0Lˆ+xšt›]çˆ•é”ÔãúÈ½ë°Ï+£n#"¥m²ğx‡ßîÉ_ıdò¸@`/?DVQO˜ä™†ÊŞ!©uÅí.**dY·3ˆM4H0.5Â)f}#K~FÎÊ„¯?0ÄòçÉõâ"”é$‚»`¡¨’ƒ¤3^†b	a½ç avxC éÍBâEcZÈñ|¾¸”"^JE/«Á#b«øF;šOO;i"U¥rvİG§jÖXd>’îüSĞ²5F~ğOK@Ûşô	­ok VàQäù’ñ¦b·“KíÕmÓ-|KÜñÚÔ:İ¼ËdiÖòË«é²1G#pÑ…6VVh=¸,O¾*à#W"òµywèë™äø^ÕpĞí Xµçµí€—âÍ0™Á¢.Ö$ôÀ²C-ÈşšJf©=¦•xkQ	Ú®‚û¢Yı5ÈSÙşòÁ³Ÿ3‹˜C,±Ÿ>3 "àÖ¸IæRp’—³¯Š4Eû*ÎqÜmK±ÊUß9ÒĞ§ş?ÚWEâ’ÖÍöê¬Ì¡ïèŞòFßr€@6S±¹°&ÀĞ(k/U¹H¥çU½¢	«İû›K¾áFØ@²º˜Xb0Y—@»ÈÚêY»Nğ}Y¨øÈTN!‰SÖ
J¢ÚBU¾{ü
7â?Öéoß±Òî=nH^âZ0™yV·ŒÂí&s=ÍÎÑ¹tú}ŸDSVBÙÑ4x­ ñN6·|˜Fš…Iè÷d)SáÎAõ%2V\Å¾væñH…à¼Ã3@=S¿!¬Âmõ,5¥9yePßÀ¯’¡h¹‰ØÈ%sîãö¡ĞA	Â•Éf¯5L{Í­³Ï¶Œ
šçu_:~ª{Éüú¼Ñš‰ñäî‡~'Ä±«6¦;Š3¼Ğ±aV1C¹çß?a6~`Ÿ»<3ˆ8&˜—¢GÑ_ñé`[øêÿà”$Óó;Àó6Ûâ…º‚áÁì™`c£,B7M ºsÈ|ñ{7ÀşÓ}A*ôùªhC:É‹S?¨z…õBŸ÷È§ÁìÍäÏ´b½Ú!ıÆÅB¨ÀãOxÍ„'~†_]ÖşÜDÇ÷?Ï™m“öó>]gÚÛ½ÕÁñkşO”{ó¹9Vıuï`ØSAYGÁÔ„ ”6ğˆu\¾`*â
!“6~Mol!‚60ì?Y‹ógµ (ûUÔ¶€"Z­Úµ½_Mù¾÷ØµeïùääÃS–&4r¢ú?vœ5¦pèç£İç‰óÉMÍÕõ-šL„,†Á´S©œ`˜¾ÛÁş%şo©’ü+Ú1¾«›Jõ©7vîĞ±ñ»´?øC@¶Ü>õ)É¼Ovj³í<…'ÚÑrÕ–¸G0i« 1ùMªóvn85xÜ%‡S@g+Œİ+Jú¡e=-ÕİI¦:,uÅW[²b¿†;6	`ß¯r±ºŸ	Gn;Õ×Ã‡k¬Ç{¹‰eO…)pk=¸Ì[Ş(µ†eñQ»EC®‚ŒtÑ(äSO¤ÃRŞõöïiØ…TÙ-&µµP ZHZ¤¹—Cé/¶²•èu·¦9©c:«À¢D‰ÇwHv°êæ…g¾ñ:ä&Ë^•?¡xW™lŠW¾)å©¦e/Z{i«Š8ä¦åÿÍÿK°8#N•Ôl´÷*„›OqãÍ­Cˆ¢mú?¡…éÀ·›ĞCºŠìÂŒ–Š8û¶~a×ÊÏ\­UhÑ—Ö=è¶²‘ş­&m%+BV²„™©Î¹&÷˜)]ß!ÔøË‚i1Ğş@ö½A‘ãaËÙ‘÷}n~Ûw’‡2RGÌC‰ìËÄ¿…ª€«|»ÏZ#İóÚ:4.èyêõÙ7Që	­®^„Â#Î¯%=ú€f–¢ìa¼)Ü]$¨µÜ<8MCS½i°n±’õ‡Û]$B`–7.:l´§J¬RÎÜŒw
™â+òB`§¢Y¤añÒ“—í­ë[¡©´“²[^Ÿ;;¾­GdÄcıÕ(¸}™öŒf=‚(š¢„÷‘XøQsG=¼	§Eõ.GÜä‘$¼| Z1í×Wâ!“©`/m™€0|?îFUEÍSŠxº=fxÚyÌ·[Ñd®½g«øµØŞ‹ÖÂ+ğP\0´		¥NBn•>Â¤*Ú|ƒcT	O×‘Š$ühxÔÄÁrO(İRãİi¦n¡Ğ®Ö³k™ÙÓL¨âGs­'ù·nJ¸»æÿ…uP€½2pØÙk‹e±Ş&?İ º	©qD ijlİI(~ãêÖõi«<eëZq‡aîj»÷Œ=ÆqD=ëf_†*G‡ñ—	öÙÑåÿ†¸½ZHÏjt²ì˜/>ÄWPÒè‰%Mñ‘&"#¾‘~9èM}şŸÛ<à‘#¸¥…
ŞY¥èbY+Ëk_^OÏ¤ßZ¼ÀQH… úÜ	–:Ãø+L
şVĞaio:J2‘ Û”É\Äí\M÷Ö:Š5öî}2¬UŒ±cÍ¡+@+s÷º®²cùÒbœŞÔ›×‰Êcš¿…-… QSïH"ôc2Â›`x­Šæ~$ÿŞ-¿Ù•ğÂ@œxÔ$é_j¥¹†ÎĞ~ùb‹T[‚”ÂAºÛ^*.‹öŞÊNq¡c§@Ûn]N1˜Š~4…˜N	­‰)¿:“§¿£ x5Ëšg(E&ÄX¶ô“iè¥îIÓ®B ‘s¢$÷LÌupÿ%3/í§ÕĞDæK;ë•?ÄjçwXÇ­/&¸´9f*¤€®\õo5“Ÿ¹ØJÌ_ıZv—ÎÏã°ÏBõzÛPøÚ¿œ¼»?Qã¥ñ¹¡‡Úº¦Sj§œ¹½	øõWâÙòÈºÿ\c-¦¤w|7H3ê7Ì§¿ï ¬†"ÈÖ´È+·ñ4@y¸ßòµ8E‹¸ş‰k™Úû`­U)Œó}\aT»wØÉéÉ·MìjDØèÂ=Kû,J7W¾Ñ8œI* È0DçP½¾ëuT‰ĞÊßäA$pÖÂ«AóßUšNä)@ÙªéC\½Cæ£»ëàR(’Ú¥aûCµÚ¥üˆ™ÊD7gØÇ´¹¿‚.¹KjP…JâUÔW>3iXÒ±ˆ¸ŞäI“–>å×ìc.ı©1D03Qì%»–ÆFØ"ù¡†UUõªnífcMÉƒ.ğ"8Ã&#OµÓ¹.…{Y^$Jğ?à	hÆ6ÈÃç†»)@öı¹	Í¹Õ;èw”8ˆdT`@&´RÀ¡`cˆ¦eVû®ÿ™äQí”7‰1TOñ7V¯aŸæR]y”c¨ŸzÆŠò¶‚äéß¨8í	Ï‡š§_ÔÿHÚa‡NËpä4Óº”ÿ\™î±$ê4p¦c(÷jğl³ÁJ] uˆğ^0<y|ùgw|ÙhŞ€Gâ*f%<-b~jÏç²åD9-“ÉªqWˆ¤pWzu«í¿s;Ÿ4ºÃq¿×y¢AI¸ìíÜTÃ§BÍ:V<òó(³\G»OXh}Ì­÷mÓJ˜ğ©¿0Œ˜}Á*ºô;ı4e55´ƒbmùl„§3ŒÈõåé‡¶yi jò¿R«2zˆ1ãÎ^(GåÖ2:; ÄÕÎ„ÂI}ºVÈ¸Ù6ÌñM™2.	ço¹à(ÛŠĞÒLL&7Ø€8~uşA²<ÎÚÚ÷­»;•îûW{~¯˜&5ÀøĞ\ñu$Gë8µP¦Ô[[ä“ÜOÿMÉ<½â|6ó” ªg‘Õzr>ZÀ6†–ˆ›õ*ú+˜CÕä¼¹@n¿ˆ:u²Âo¹Wc1ïBØ†¹Ó‚ıuã-Hè}ó…[ywkL×^›ğ;&±“Jy²&.N©ÒšGln,û!ŒgX¨œ I±ê¸K²¸6øj%³¸Œ7Ø	ØÖB„Ê¶ÉüÏ™çÕï!£ÓÑãN—°©(‰Şñ!<°e»3
Ö±–îj)Á«´(·ÍY/¶sù‹»=Ò~‚XpvvÏìJ€-2378;R
­ô‘ln'Ê±¸íh?2„}&Z?YCóŒd÷ôºƒˆ7™<Võk<ÆÅäb\ï8w¼³ŞÛ—lÑ¯fÖÜ
×ÒÏy\‹8+§R0âäe6(Ô˜Ïæğzÿá?í•Úæµæ‰’5†_İ wÇYãotvjs¹,ót@$S¹úç¶	3ğªF²öëC/ş
ÇÛS“ß”å¦Àb¤+ˆ;ƒ´u
n§<wıxü×I°z~îAÕŒ¶Ív#%^Q±ú=_æ2)¯Ì-@øYÀ™Õö‘‰’”Yíˆæ—ÀşOš½)şğ„4V„¡¤¶’%½fri7,ĞÖôË²ÚŞS*O;9’Ÿ¸D-FÙšp§Å_®Ù5-F°»%d‘zM»a íXnEL°ø±™¥ü1”ã±©á/)á”ˆÒJm`£ØhöŒ*_Pq™çRË±â™õ$bòU¦8Ï[“ ‡m9É‹ÛGâ8E0€ƒuÏNw´{æzºµ5++¾ª(‰ù=ç7ÿÑòÙ³êí3ş=("5fíÀĞ–şGáÊ­	3#B­z0j¥CŠµ¿Ìé÷ë®…qÔqÚf$â?<_6.j‘H˜Ê×îw ÅŠO±diÅ‹0Y” ‹S'á=°m.¤Ã’>àõ:oŒúÄWúù0Ì²”Õm V4L¨ı3{İ‘¤ 1h”¥(¬rÒ™bAb|ø‘[êáš€4õ7ñÁÇºÔÒ3½J“o–Zğ¹®ª»O4úb¼vÛ¬
B*Û’`X2W95ûÄ…/õ<ˆ]¬¶/@h„5¤3ÓÊVú„`Lï`Ö˜ˆËû,İ‚f4@ÈÑÈUD r«ø±o~
V°;ŠK¡£{¼MqráµPª””Ô°rËAçGEX§kÿûCÔŠ!#î‹%ƒAoëå;MÎ Z‡iqŸNŸ|L™µĞç Õ®£s^–RZc>C®®zú—`Ä®óR_dñ*œ¥‚³9ËÈ8®;„ éõ#81B,åFÑT÷>L#ş·o˜¸bfFïñuøZ¸ÌÌG°¥cŠĞOM~Lüq7Ûm@R¹ä÷–å6>;ŸÑô.?„œ·ZPF\ŠkÀæ
QÈ1o-îLòH–	œuÚºŸ»Úã°½:ÇÊm’O¿äQ'§?Dİ4gƒ‡kôæ6MA@ËÙlßjl"Ğwk]_Á.2RvD§çÙ1öD-içñş_¥µ±ê e‚™ôUÜ"n/3^Í£)ÂêW½[ËA6ÿÜÖS@î.Aƒ’¥ƒ¯ÓiM¹lnpw¬£Öaè¶¥Gv{$Ò°ûò6ùlŸÿÉï_<ÉN¢œÍbì„p7º+G£àS“.ìªÓÓåºÄLZñpÑ\‚î­>­ùA}Ú"#\:ù+ O~»B ÿˆb/Ç©¬Ğı-D~§Í™“&¸\Ã¥g·Élyb,Ïn{šhÕ´(ş«6}şè·ÉÔr K÷®´‚T8à“õÃ^Éf‡´°»Î#Yzqx±X6\¥gè¨Ã¢à!«­¶:¸Æõ½¹&pCPû±óî8Ş_xT‹kşÀÕ£m—½k4ªsë?'ä/©_&òláÛ‘R»]Gqésõ·ál	³¿€ş`  +¸¤l0·Baudgv2sP9b*Uâí3fJ¹‰dû+Q#–UëS†Ç›Ó”k;mğeVÈkÜ^üÆ8ª^uªÌÅ¹ÿÃôÅ)b˜EImE¾Œ,=J`«Nâßmâxo%Ö‹"¦vCÊ³”é#hÓ9|Ø?éª??rÕC‘ã¿­4:3Ñì|JÅğØ‹iŠ>¡v«ØGüOÂV”C“ø4û»Âtï)ã	;«{5ĞƒT¶SJ„êZŸpõN2ù6jz$¦Js˜Jg^¢Æ„k¡ğ:W)²¦íÖ=^¥‘!ãrÄ=E¦0ˆç&¾Š/¥t#mIÄƒ¸Ñ¾âKÙåË(¤âQ'ê@Ğ0àßS¸Î…ïµÆ›pÇÉ \xw}¤<!“°û<D]@9úÿ‘¢F¶¯ÄIdö5ìÅ?şñ&†…N¯¶½D¦z&­°‡e«àÃx5ß±%J(‚?gÒÇzÚÆQµ9.—ĞÊ‹qkÈ«€«)éÚT²éq#Íy†%0*
4«KÏ—‘ƒª>W¾¡h©ı#«ÿ°Y9ĞÈL‚è|"{Ğä  çZoiÀî³®»ğ&Ï¹©UB3Õ(ö 4ù
ñ`T"{Ÿ15[8ûG½úOIqÛ7.C¢ÁI²`@ß7E[MLIæ5mŠx7%­¾–Ì*7ac‡‚^D\â(ğ6Vv)‚F^Â¸^NcÃlS-°¦7-ËÀ
_Ü±¾»ÔeD—Cõ²L“ĞL£6)3A?ÜRÙ†ËÁÏt	^¢¾EK"7~íoASã/´,´ ãß\ŠóÃ¨jÌí;àfÑ>Ş{®»QrÀ¦!A‘äEï’çêã‰íÌÇD‡=ö´øòé®²h	šŠòBÎóœT ÛÊ,à€\”ÿkªW1;2á£GŞ@ÓÎØáï<¢Ìœç_ÿ¨ßñ²\ŒŸùÚ6ØÜª›cå»sÂq‡³RMNƒù‡`I]M”¼V/uÖ£Ç°X».=J<¡8¸¼˜›kğ…ÌÕU8)ŠÍ’Í¾àúr«ï~v4Qåm¬âqçşºW iÈ£jçMë¶x×[™%[—Ìí%}™uS2B¥ ÉÛòğ 2¾¾ÎÛóØß»òù¸©X6Ş45‚ˆÃ»J	‡~AR<ä}˜ÒtR-ŞiP¬[D~ú­­Z7†@#û!"^ç¡‡›Öªñ‹óõÿä…%ul)ê÷×§ôBa1÷—ûÜN¯’(ÆQöÓs›D(İéçªyh?Ò{dÖ3hijH?X"Ù¶Á©İ+,"ø¢2ËIª şÒ”×¡Bé(-âÖ'#®Im“7ªP© é i›R¡9¨¾.¢ Ô¤63?Y±¼xê™Ãàûàs,	Ú"J—cM¤fÎ!Éş×ïZRLíV7Dj4~nµ:[jÊŞI7æ»k>2¢útı£è`éÎn*!;ıïó,ĞÄĞP.nu¯×¨òW„!OBÉÌ%^*z{Ò›7¨H“&ÜV\'ù‘!TBò³•­ü\S©ZmGÉ8ËzDòËÕ8®KiÇæM`g°`şŠJuår*â7Z0o¥H¿0óY¾›Ş`(à¢aÏ!cã ¡$›k@f:«PÊ –éúşz$i‘ERÄß{F'ØI‘²BÍÎå;Üá³½µÒ¤‡m°ùXS6õ›TÃ_¶B_fµ®p–8ãªizœËıØ†]rû/m<¯Ùèuù±ù×jU\GaÄß…Ÿªg@:Û6EmÒÚ÷»°XI²ïŞÓ»Ty"…a˜izº )évàó]Ş2IÆHË	cğõ±¶åŠ-Zp>{EDl"¹¾@ãÑÉ¿‘Y®z…NwsÃ=;ÈSµ_¿º–4B;q‘3.gç>jÕVa}¢Õ—}”2›8×‰‡)G>O^ 363v¼ã@Ş-c[C¿MA—öÓPÛ.~ªwˆñ$ê•ZDü·Œ/¨	½ìÄ XXˆ~ı\ƒv¶…æâé,YP"„a0ÿ'6°« ¬|ä=„÷:â0BÙ×\ÃöDh³ä—6Ó2@C	¬»z;£Sì2íÀH	‰êŠOIí;(Ñ|šGu‘a$áçÊo7ŠLbU®$Œ5…Ş6ÿ^•%ÍP#÷.X›'/Î<Ë¹ÉG9â„ †H¢Í'YPÙòæ.G÷ìŒú¼¤/€eLÄ›šeÈÉÍ˜í½WàÉUlĞR#)Oä†­£˜É-1+:í*x/[N<®¬F¤MNR3½3çcı!#DâŸ8ëß“À°/^¶pÓŠVÌKe“±-‡DÖª™nT,²@ä`V˜•Ş™!]é.T7.ş¦^tÁµtwš…¹÷ÿ (‡ÍYğê_öW½“»şE®1/‰—é‡¦1‘º¾UÈn|:7S6Ê gPÈB†ŠöKfÂÃ›Mô±œÊdì¸@•İø Şú‚|½nU>Ï~=-t…ùÎ LpvÛ¡7Ä=ÏŠåïjaU	şÅ +É•:í©
$âÄ*BŞPfG§Ø¡L@Åõ“é3„•é—¯2Eù/÷E1æÊ¸Sr×FWÅÙİ¼Cğoä«<@©Øy&ZÙÏm8··
‚¨‡ÊÆ‰' =†CO~-½rÜß†WÛ(R/x!ÛÉ&—Ë—LÕ=¤U‘3Y! ‹»Jm‹*ò…yôØChL˜Š
E,ÂÃÇÙa@y—óõál¿µ1½ëŠDÛ‡%9e0·kˆã«ìõà;‹Ò21X†ïÆZæQ°…¢f±!3§ŒM’å(Më½óI=%Î˜^¾7Á·É=U¢g0$Y÷\·?íj(n3hWßWÏ¦İ¸n˜ªâMÖÀˆ—ÙÄP>Óª^_ö½ı"Î4†äuj”Ÿ/‰xŸk;mıõuÎhf7çà§o:°‚yDz‡7àç™]_Ã<N©©1'á³lÕqmı”D¼ŸwY_Qw2ì
ÆİØ_OXÚ1ëù›İQĞ™M·‚ÊÔÍš¶£ƒ	¿ÒMKJ&şvËÇgOËü¬8w€;o')ôgÔ ì…mKÈ‚Œã°;BÌ#JFğÙ-Å—wûtrS‡Öe‹?^êVê¤ş6)˜ßma#ÅH]©!¬dŸRşÿMùÂUı–u‰Áóşü.ô„Õ’Uãœá'cÀÙŞŒß³óÒqRÕjœ™tÔ=VöŒ:¿L%0(%µb1e‚Á#Êl±Ëbhf9 IóEIf
Ôá(È˜s•s«£+4ã©mÙÌ’?.{|f}‚n¾Ö)æ§Mîñy³kB—ÛÖ;/ñûŠeŠ…ôm˜®!şætøÓPÛYj¢Š•J;˜–B>Ô˜asæº¼z b:É–¤”SšW’íµ3…e4¿€išØövÔ.~¹.Ü§‘Å>[Á@x^0%=­¡ÒjÇ6UKíKé´„Ç½}:ªæÂÖ×¸µÆöö£¨^v¼IÊûµİ”Èêi³‘r¹iøV«lPã!QYê—ªæ¢!½%£<Ù8“ÓPùëÉÙœ†&9pÇæ:ã†@]‰ÎÙc	X…Äš´í1ùè2v—÷>ª'•òš§ø1ÍßúNè¯×W€ÀñKğ<7@½ –‰Úz mZÈˆaoéàİ[‹3
y9÷CŠÚgã©™lzüq„x\’Âjô0^y´m¬ÄU—ËŸ˜Š­µã<¬Yw*„/m:4Jh5QÍ&$|?	±à£âeˆüyÕ9ã*dù¶ÿ4_Ş¡/ˆYÀÚµÎ<bßdFLİDâãŸ.EkŞµ‰M6¨~DˆâdÏ&ŒŞÍŸü«Â³é„{JTf=rRCIVñ·§5ş#$=;†xÂsœ’w"¼­ªÊrÙÏ.Rí\^€o;­«lºn!*ë™ö6©ã®¢©b
tlÄ¹—Øèh¼©×ØçÉYr(tqÀÂ/~êÙ&ºÿúm(k+ÿ¾_ÇĞû’¬¸MdC
J2Xu¦ZÄD¢m¤AŞÂêBúÂÇ'}´éèöï_¹n€¢!cS.B©	|pV‹ÿå?)¹PÖ0'G«·‚ıg5°óµ·İ°pÎ]è¯û¾s±ã×:š¿òö-Z?ı¬œ+¬ß8&¢J®7‡J _¯ÆIAšõÍØ¢QÖ{¤U×ßVÒw„1•I¡›MZŸ"SOgPã“<&p›àÆ¡Ùş6ª$\4—¾÷gŒS½Ù‚ŠlQI+¦Am¹ÁUŒõZ¦0¬YUoÃ’"K	°O¨Yyæ]pÇ,-é=ã[bP‡)§fA¼árÈws ©ƒI»ÕátŞi‹,ñ>‹2¯8C7(‹®„œ‘ß>Ï“®¥"8ß ß1Å°ÎËÏ'…?ÿH h¶B‘lOyŞ%v3{…ô¬ £©^±îwè=7¼k†ãş$ˆÀÈñõÄgk€–õPŠ6'µR‹hÖ$çp¡UE™éŸ 	•¼cÜP½dÊê5ıyaû>t°Ä©ê¤Öq}ÉÉĞ·)ò]xÜN•oPZfÌÏ‰@hA|ÉàşN>;“•ØâÜ¾‹`QS®"mÊN¢ëé<´¿Zit§ä7)wîm¼ÒyŠA·kÓç„üwF¤šÍŞq%gqfNé.·è“mo°ä«ß¦5Â>Ãñ%~C
;Ş€ÄëÕÂşô¾|¯U 3Ê¦{˜lÌbf,Õ_:¬»
0zñe-Ùñ6¨[üôìJ¸ÎK­ïùVòu“v®ƒow˜¥õD zn¦´NâÎ:{úqãÿ‚;‹È¦v½}Ç¼c‘úT5' §e>aqøÙ·-pMæ«ŞLTÚÌÜš_Œß:Úé(m¦Ë—È{÷Øåœ´ƒñ¤3tŠv©ì+™òÂÚĞ¤<ÑO ,Ü¥iO*ì~Öö…âÌ¾Räô¦²¿Ù"­¯§AYUNéHàë[ûx¾ÌEeéË»ÒÑK-NŞáqÑ\£6§SxUÑ°!~4à²,Û+G¤¢&…Î5$ÏC²<çReF„RÖ«Ã`Ş¯õbfĞz„æŸDÖ²îjYxçñü¢ËL¥&3Ş7bš[°ÆR{Úài[ëÒâŞ©ôÙÿ=§’ø(ûxGCâû.m@d/m¡8køë+áK*2ÒŞÖƒ®óÓ§gÙÒ’“ÅY#¤¼;YQÃş6H›Ë‚˜³¹¸(†œ„(iãz"Á|4msLF×uİZÃ>NŒYïÏäFD×FÃK@™>üJ¥%¶ûÛŞ,›ÌÑı‹çõ	êdÃô×y‡pÂvÁñ•²_“)ÃoEÑë‚Ğ¼@ĞJW¿-¯KØ"·<«#û¸ÅÚé]ÀÁ1a»¹Vùv”'ÀÙ×;ØìtHÈ¢	ì…±ç½ºu·“Í°gÌ%«>şE¿ÙO„‡<Œ–ªÛôEÔ•®Àqe{æ9lË¾¿İêÁ«Ã#A‘'	Uµg(R–ŒşaıPàœµºløQî4fÊ»1—V¨ÏÚ£¿€Ey/$;'ùgjw{KıİGÙßõêíÄsĞ^@ÿ-$G˜×ˆìK÷¯Úlì8¸+)¥n¼7û¥O“$œZp	§p^FÜdQŒœ!xn5¥E?ßØ*Ê¼w¡*qUÍ=½Î{:ŒŞL»œãÿ‚—À‹f ÈIg+]Æø[SêÅWypvï;myît4îãò`5z¥}ZÀ/¨WçBõ€ñoâˆlxLm7!åû€·¢|îŞtäi‚Q0èĞA•¿Ğv{«K?6#j(Ü÷ø_±?˜(¦H;ÓpúE8kğªæc$®Ç¼cjûàn.ÜÃ³e4Èº.rÒºÓCnñ÷…ÕŸ/ü¿‚B©¨Øä6ÀÁw”ÚÜ©BQwê}&ë•öE'múRÀaÖ7‚h¥ÌôbÒ‚Ÿz|÷½÷êG®X€FÁ|r7ÑØ¹¸rìÕ@Üä·<PÄŠß;ª:‡ÓX\—ş7Adú‹D6Ù‚“)…V”SÛOã0ò";Çõ[ox¼´r´ûJHËNÃ)E7zqÁ ÿNšNGë‡KXí°Îx)F5~#/>ÉZı\ÃØÀGŞôäTšş›¹ˆ¾¹ÑîÑc+„ïsBíøñî½¾KæER:¡ˆŞ@ÚX§Éò?J‚Kw×@hÔº7àL€&i&âW¼ŸQ*;~öRMW†­Eì¢Ú*LL}[Ç°W†šcÖ±½<…ÿ/™ÃrZoçì^°_DH¶œ[P´
÷õ&O@DÉ©N ]x›äzÇo!?À‰¼Fu9öQ½ä
‚ÖäEî#1øÂ’yñÛ“ŠR7Nt‘6´®R`7ƒ¹Çrÿ°«â+Ì9Äƒw<z¦<Œ6ª1>c@6±|Û›Å€2âyÈ7ºÈ0G¢Ï­ğàæ<cîå‡˜~”b’hˆû“YøıÂÃÓ1ŒåîéÑ¨{Ö: š8??³î]Qãk”¬£¨†[t1«	÷šì½=Í
·"æh³è¶Ûª(Ğ›¬ÚÊcï#¦	z%-êá£¾B
‡C!˜+ƒü¢ÖİÇGùîm›g¥ÚğÄ|Õi~ûş»Äô`¶Ñ1~P²ÔÈ[3éûƒ¬nu)G„ĞÈ¹˜öUf³z]“°âè5ƒ€åFï¸ÖĞı%H_:İ¼ÃÖA0=l0OEö«ûèÆ½ª€Zë÷³™‘8ø!	Ó…Ö¡Œó¥®°m`o„1Lõ†máúÃÀZ" ŒüÕwƒñŒ¢4—Ì+]æcK_<3H0±ş£v8œÄÍ`CÃ}2|Òxşq³g8‘E¦'¨‡WB"ïøfäÃÊ	¢ß#åyµ±†/’nn£š î%¥ä
PÅ ‚y{²1ñÜ_w|–›|ã(²6ê–©µ1+sßÜq¿îLW)Üı4Co2dŠ‹‘bû¨?óÁñü±{8‡•Äu)¿ûÕº`çùSzGöjÜú1.P×ı^j)V}H4~ÕøaŠ)Æ­Ñ¸8 {"Z·m‰O©hº>İ9sŞW¬ñNğN°¢şâCÀxŠ5•\aÈ‹æ¡+ê„iEó­VæåãÀ«9
µ!ëÓ·?å³7¡ëAßØ]
(±=DFï3éºH•”¥â‹nETà‘³í7!>ğ6¢_l¤Xs¡V9£Œ*)ónôm3(o$(¯—]‚:üÌ´@y,½{@«vÉUàª&X“˜ø”ğ@¸•Ã)5Ó‘ƒ“Å$òI 7'½©]¬-¨î¼dşıy®Ó?FWJğ¥F»÷ëª¿‰©Exx9R+ıwVÚ°g=3;‰íGˆ~Š³Ğp	q-­D³|Ñ¤8ÿî2[—1´˜nSí1Egï5~¼Zó=.lÈÇeMƒ’Şã}`sTxEËZ –‘…n©húdE’ö*ù”y|—§´¡[ß£y7HcÑC– àÑ»“mSl¢T!}Î¤úšŠ…ÿ6XÙÖMîÛyeuêBÜw	F=£SÑ¸$×¼Áİ ?ta }çïÁ!'›†èCéƒĞ«ëù­²ü(˜¥©Óˆ|9‚‰èXXÌ` ãC¿Rà&Îú¦kŠ}Îïu…iØ [Î‹7‚hKc çä7ƒŠ„ÕPmğ&WqàŞ£ø‡Yæ~m k$}âÑ~ğ(9ÂïÖšPz¨Í$Ãg¯’–ÈH¾ûôöÉŒ2R`fy âƒ*t ’Ü†÷8§wó2ÅQæÖäA-G…(ä0ï‘"Ï·ÄDßRNŸk€ÅJyÎÈğ*ÕƒßI·¢:½ƒZB'‘gh å¹ìSêÏ~ABŞÊA¿¢iIt§Ãš	?ŒÂ˜’ŒğG†ĞZm¿«‹%¯Ë—o¿C€µıx’Šéñ¤©~<c¬Óˆd•ö<«š2û¥–Õé°ŸW«‰¡v|Öh´°æÛ‘aR]Mß6Ô8"mˆ®ètfò†²è7ñLgú¬ÁÁÔ0äËúrw“Eò­¶®$+ŒöÕ.Í`\¤bW†™-<OŸš·ã4I$âWRhlø-åÏLÛôf‘Ñ­•Oo*ëC:áŠkf„ãĞo2÷á²Ä‡m»(nû)>©H£nBn»L/A”’Š€^:¬Zó)íZı"¿‡Ê¢ÍÜsx~+•ÀÜ	ê¿
>ò‡.¯>v‹y äÓÅŞŠƒuL©³üÅÑØµCr­í„o€;iÛgDñš)Âì#—5ş.!ï¦÷[ä•ØÎTÕÁ¤ë†Ìé7è<–P±ñïÅ!€´7F)‚¸Ø¡~ô\êq¤şxŒÖó•½BfYq*+ìŸ ÕÕdD@–çUÛ`[¼©jw’Gqó®I]yO•k…5j'µE	ı¢Á“2­`µµÔ“‡İ/˜‹¨dö)ì™ã–d³‡S13µš¼î?¢NÒQqmV7ƒ~¡Å7ºp±<åwµ…İ7¢ * ^ÑåìNÈ!ff&J­~B/ŠØ©ºæXaş $\BËİÇÚª=)e½¤´9`^ƒyÑF—
‚£6±”(y£½¢QhÒv<âç>ÔÎCq@àIs£¯ÿÉ½Jdã­ø\7”şR»…ã¶œŒhG?~5±áÏi4˜ülæ|´gß¬8È|Íxçú“+:Ø^¬íä´ÀŠ2&™¹[œÒ»ÄwşüÙ!~Î¡€Kì8Â©ü/"dÃ·ƒ™'ÁrŠCqF)ş†‡ñêšà¯ ôÊ¸Àm77zå™3E.s‘”¼ÊWDç[*öìcr4eXzÎë’'Šo™53Ÿ÷©&gÕ¯?™‘XE„üÍ·ø”Ü-œnzgÍ ËuH2ûª=©(‡è.>	gû»‚®ÕŒ|Š­=Õ=?ûy*Ú'¼˜e5BÚ÷Ë3´£­dï79	—WMC8… ády#=‚+;ğqg¼AçÃÖ8p…ŞåÃûMjû?ğ&SîÇ
1™n<XŒŠö5ûÜ2UIh&D–*Gb.ïå–b÷2»Æ{¾ÿ&i®O±1uAšëz¤XCíá,aI0š œØü¯Î[~¤ÁJ8ÔF
òñÜÊ~è%YÖú‚4±YJÃ¯E…¡4£ „‚¥ŞGÏ
áön4^tÿ½ôšHbRxSı¢¤¡@Úş§a„6»ÛGT\Ã\³¡¢Vñ»Ã–#ì²e³údÎí‡È¿e>M–Ë@Œ¯O”¹¹ZÕ©ã4çõç»Å³]`ÚPîòm 5¡aò5&»­÷~:¾€¤9ö-w?;%íVïE.hef Ş‚‚ëÉxø[VîÛÍK‘è8[.ÿ¦Oûx“œ›&ëª®K1DAª¼<Ü×i$mŠ™¥Z¹%=îÀç»«û¾88­o’«ì0~÷ùøBŠp›Ütá\Š"úšDÓş™7$ÏÀÍ³o;Wâ¨İ<HûyÒyÉ8ÒéíP+¯ñT¥Ş:é­_8UÆ÷ŠtO¾%İ(°?F‚9ÔL´¨Ñ—İÚd›ûVlÓ6ìBï|·­”ùém}úìëüîöë• ğ Ê¤¶	áïp‡1›MV¢«î…4B>Ğ,j+Ú{Ñ,CLâ²ZpûğÒŸÙ§”u„Ø£âËŞ9ù8s/ÕÈu®ºş¬µ²X-ß×oÀÁáS^ïxMÒ_v^˜øˆÃ›\uM‹ä2^`¼ÑlĞöÇû;‡¯ÑüN8‚AÚv;XÙ»}ÜLµ©eæÙßímVæº;ğj
œ°Œ4’˜µú!Av>Ø CdÀôû\€*±›@ pªŠG¤à•­1ªGÄïÏäÓ}ë‚Äû°wÄ—g©«ƒ¥áŒÙ¬–N_’×›iªÅÜ‘Õ-s™¤a9×*ÕpÆ¹TŞi^İŸ™Ób¨Ñ\®Yâ¢j¯üFx!p!(‘cá+oŞEó‡öõ³qåv·lõÀw‹6é¹îÂèµ°tŞã[~GwÖq{Ã–¬(	LâòM$f"Jä_Vk×âÒü¦Æb¯gc=îuº"íµ+„lì¡,\ö˜´*¡<©•°JW–˜Ÿı.6ÃCju=E0´îş½Õ÷=³gË )œÇD7Ghş¨^-‚‹`(r-‡;Ú0‘Áî÷í¾·˜„k,E ‘¹f“0«	Ã*±U1%/xè=ö‚kô±‰©¾e¼#ŠÍğ˜“ÇGéspÏu@µƒWwûH¼ÚšÙÚm-!FšŞğòŞ¿L(€Üº$Xë>Rß³« º¹êëwÆË‹a) ¸¶±/GÔ4§S8gŸ¼¥U¿ªİ»»‚½!Ÿ ı­|×n'èÓàó¶Âv=r;û@Œó–p¸¾37ûA·¦ïí”sHëA69ïòxoVÕeÑÍ=÷œÔ•¸©3º9iĞã¬âwW
“¡`OõÙ™Ù…¾é]&8/Å‡Õ§û]¯„äÍçğ˜ËäÁSW§¬ ªJ¯ÅÑÙÌ:pÌöš/7¢ÅÌ6Bë\7¿¶6w´c¼lı!Öª£·qÆ°ôÌBËØsÅ¬‰Æ1¥gİ„>n”8M¢Î®@‡öæGONµÔó’SM7Šƒ_ÇĞ´„cÀ½Í:ã<z$Ë Öbëë“^H®êŸ[+ˆA­ueTMŸ[ïOÎ-cBN®}+9Uèn›òŠJÁüF	zıÕ³À	ØÑ¬ù·ıCî«’}¤üG5úìzïUhÆcBBïQB+`o£pEåêŠızAJmoHfî6àòŒ‘^0t·¡ùÆCHq·I¼
ğæ€UËäêÕŸ²ö©%´Å¹»ù¡ìğaş÷$o&ô+ÃªÄjU‰¿MmuÁ1¡ÒÏĞXLD8„?VdÎÙ)a4~6qNxÍÎ˜Ûµ¹9« ˜«âŞ%¤÷Š_g•Àš;ì{}$~&\™Zvj×À(¹ p6AHÅRFÆüéÍ¾êÊv§…úà+øŸ\µ¶fwL˜ß“ğ«ÆÃ‘¡ÿU]+ö–æÜªLi27q©}–Şàş¸Ö÷ç‡Õ^Èº¶ı³ÈCrK‡<å øÊÈdĞ¥¯¾K»¬â¶!Ë;Ïï5¸Şo—ûe`š1™^ÁÑÎ`5ÌÙ÷„bÃ/Z»ÅYş¥ Ì"YÙ™¡
œ#7).Yr·PypÍÇ$à©/¹Óê^ä`8ë|õD†fF W	bbôdR2×>ªà-áË©Ü'‘x
º“û­1¡“óÆÉ¥G"ö·y»½l•@üÅT¾´Ÿå•vÇ™xaKzz»W²Qœìp’ZtÆ}Ïİ×‘Ù)Ô¾Ó…±àìšDÅæ‹µâ›[¹$¤Ñ!-ÒLÑú<@„Ø¡İîk"—UŞ:ñ¬KÓ? ÚÆÿ«™Î_ (]îeİ~ƒ¸
DÒ#î‡"Šø½·`sÇû+ğĞ'P®)G-ŞŸ¶•éèò'0º%pì*á&Háú<I m³úáÎóàû¤ë28sP:Ò‡“B•*×Â–b³„¨M·ògn]K;?ç6ıé)A=@ã\şV¶Ã…ş:'"£|²º~¥êm¶–d@Ê2ÈEğ-Å„óMWéBÖx¡EåíF(}ÿr!ËRŠcã2Lî„M	k¹ÜËKà‘ÛwTMm­È)2î´‡)eF¿Û	AwùÆªÚıÕ5­_&XBÛÙ7Ï;ß“D”SÁ¨×¶ò3œƒÓşpë9#ÃN: oñ>ŠIg«’»»ç'N~Á$Ët˜/å6Ø7şiKÃÂÇòEâqõªÚt¿®&'pŞ‹ÏİÃıNEY³%€Z¥öÛl^¯ÆÿoÅ1¦" MğìY3[l)ÒQÉ0+4ız3m«Z€­@"o°øÏ¥ÊNyÄS˜¹šNì©òJÂ\fğ˜J$.ªsØ3ø…Ãyšpv¥çÔ	>Ü8Ô­ìµèWÆ#Áí)‹
Úû‚Mä^·ó‘×PFå.´dİó®ÄêHÙ1²Ü÷-ÛÆg0W$Oj1o•;]}ÙMzÈS%*Oö.¸
p0Òöt®Ş¬ò³Bˆûz¦’ñĞ$Ö¬ÅkSË:ã<KœXŠFb¢ß7«Ì8’^^,ÍğÔò2Ñã=ÂÕ7Mq8³ ıçòåÅ¾ëÒ]£eÀøG7›Î,tºĞ†ºvu%À}Ğ;ÁÑ›ÚƒsFÛnİCÜÑïg×îÌ…]£«±µô5—Á#µŸ
%ˆfÑÈvVÈ(0ùÏ(‚Ä|a”¸KKÕ	÷”…İu(8ìV5{bjs2µPšËÙ½îTqò@4›J¯8¤öª¾œ—  ó?ëz˜í“¶C¼~½µo·Nj/G'aÍıaIÑÿÙ›ÍÌ‚Ç/†>¿ëôÀ+â®äôÆºWUğ 8?~aõvÉr†Šns?‹¯Ä˜·Äeµ½ty‡XØwIë–[)aZrğgí
7 #|cI‡Ãß&ùH¾Æ„¸ØÓVíôå´r·¥è¨dÙárüK3o^w&š
°Å¨Ewl¦9èu|[7.êq´É6½4ıt ]œíœ–Á.‚šÇ|÷Ït˜o+Vé™aÑÁ:QÑzU†&ÕfñÄ¡àÑ Š',|œÒÿcl‚#¯¿DRÄGS}m¨:VTv<$+¾cæ_Ò3­4¸o¾K’Õù7"=w‘qâ=şÔÈ9Ü’ÌÁBZ³,ù–ê½Ş³Ê^BÊM«ÃZM3pºü‡k~|xîÔK©X±¡ÖD€\V’ªZdÙàò—^rè½NŸCÿ{}Í
^¦iİÉÕF³ØHİ”‡ ‡¯7é%js.ÿñ' İ{¸XÒ<~­¯­à³À¤½.ö²G%õøÒI¦`H;­=’¨²gWsŸÁÜÙ­"İeURöL&¥L–ÿæjab¤¬Úõò—	½ èëJ}Pd‚°·°©è`ZÓ©[–¼º¶›«Úorèİ'&«eÔ|–[A•£§ÛšN/*Rp
èÚv*ë¯ŠWå>¸ˆÌÃ{
å?æ˜hX„èPË¢Îâ8‘×˜X£°Væk"½è¨'.q+VTïnušs’á¢	ı»¤Ü>q´G´e’(w”¿‹iÒ˜!¯_vèõ´E¾ÒI—ÙSJÆ9å )ğ$İ,u×…‘Ş>€ãÔò^ğ/:RnÉx¥¹{†ai¬ÕY²í~ö¦Z:êp¢ÒHˆTb(Ì3CcpâÊHMÀ¾±½òAû‘¿ ‰–+Ä!eÔÀÇÕb³(`0”«‚‹jÑ™«9İ¢ÜÑüœÒˆş¼ï¾—f1¤€€AÄ:ıŞYŸ–rLÔİÏ=”áP2ÿHL³94µ¡7øS%x-û°	eSÈéÆ$.Ç¾p|`Ëdˆ]ëÌx¿›ZÔÛó+é¡Úİnu¶`y1QtÄk©<TĞú	R_‹™½k–ªuU#ÙMlÖ¯Y^IÖşf@ü’ê¼áÚé'#®¡yĞ®¢ÉÚmbGŒFbälë:Y˜nË7IzÄ÷Á.h- @sS
V{¯ˆifPú±º!RG9b
Iè:N…¿/(ºÙ,¶ğÿ"¿&ß¼1ŸôáŸ±˜ï)6;fEfAÎœuš|0ƒ<ı¢ƒFêZQ½<A[nuËS0”ıĞhbÚË¤“@ÆÍWÇÈ).N¿³ñ˜TF@2Ä;ò¿°}>õ€ôóvÌü‰úä‹ÇaªF®3’bè.,ìG®rgç[ÕõnNr
öï}ò§ĞR" ª—0ƒo°è¹¨#88}øˆ_@è™]OÜ“#‰B¨İ³Ò¹&gó²¢Øfl˜ÒDTâçÕTnLíE­ë u²€Íìä„ÉU¿1r;òÌ©O¼âî+cJsÍŸ°pıê£R^ñ„ä©¯üÂÿ_Æ¥x0jÿ+UÄ(µ¨1HêŞ6×/ROV*Åyàdél€ëd ş•·z¼0ÑX-s2â Ÿ[^6	Uee_ëêÕvÇ^ÄÄbÍ†ıSƒ„ü±º¹œËÔ"®?èÏQ¬Ã±u"hÆ¾q‡—›ß´®{Ö?.kœ·ä5ÇÈß»0 $úškozìßêÔäš@Ä”OÙÎ*—ïÇ•çËG–ÿffhpø#¯VC‰tõºÇ¯Âdo.·×ôğ–Ûªˆ©ùJOf…ÎšKw}âWó`ãîyÇ¦¾êQ=PÃkø–Ç“:{±¾#ÔÁQíe\dRáÑ‰ƒ\J
N5n™`m¯ï¦¯¦E‹¿qC«÷³<‘ Ô¿ú|%Rd¦LÈ0–ôSÆ®pW_bIn”½«&©yv˜&4u¯¤òZ»¸©¤ãâ!Ø*_Àfq©ˆ›ûi¶À¯»Å²væ÷A¡'ûìz_hn&`¼G|eqQ¿ı†¿‹8{`4K¹nuõgfÜß‡üêyÜæà¬¾‹W“Ûa-Ïñ0¢Œ}UlïÂvUwü.T„{5•`æèªNZ*ËgwWŸÚA¹/ÏË9M%^…¼¥f^W[ïœaºİÕÑ² )úZ¤l9á=`0û[oÔŒúÁ6ÁÍù/€®*¢¢òÊ2Sÿ8,IÄÌ>’)‡IhHr(`Ü tÒ’Ta/	œ–RkImg/÷÷´YIË½êÂ³ÁÓ›èd˜K–˜|l’¤IÌáæ?ôíáşg&!~.gÄ/Ò à¤nâ/›ˆ9×]ÿJ¾	©oúùÅµ­ ¨¼Êÿ ÑŒÆ½s”Ö]Á»’á|2¦W[ùÆÅ©¿âƒŞ«ÛÂ\V¨Ú´é¨€?¤ó.ùâD~&Ó£½2µAó5ğêgI·|PÌez4™FkCÀÌåÅÕçáÎÌF“¨.ëº,‡!;P;Ğ]9Vµç£A­aÓãÆ†_’E[!Ú«IAbËÏ†/dn%´r¤Ù½aUó-`ßB`#oK$Ğ¼Éß¥ëÊBAºğâIYŒP<kv„õzîÌT!q_™gû?pòèGyfÊX%e3ÅÁ¨Ï…SL÷DX“Q£]Ã| óÃ"ÒÛå¬ÊJ6âúÑ:Ú3œ3‹ZzıÅ/‘»Ìëo™+°¹to`(Ö­7­}ûwFÈ@ë¥¡ßà£Ğ˜!äd<1¿—ÙD@uólíÃ'ÖÌIñEIp¤–y–zT;e…ÿıˆKÕ ê÷Û"!s¨_n|4öû®#—Ä×ÅCJ>ŒVY#[ªMËŸÍyô hŒ‚˜+ÁñeAz#g1¥Šò§9o’P¼*&FG´‘	³'B«5wmöïÑÜ¡‚`şì(-]¾,µB^i\‡l€‘µª?èì  H¿LpF¸º¸AGˆ9ÚfÛp¯5éù[‹dïØdfè²BSa2Y·mÅA”]ÄÇôI¨;20·ËHÚ:l-%§¨©İ|Ü9¬ZXvZ¡
cÚğßüö/Î$şß•ò´N#ŠVºÈÜİGÆşÅc!Ó«÷<Ê]!•évIifß0Gäİu-h®g×ãyïéå2ƒ}A3rKêÆ¼‚+^ı•ù*wg:9ÿô„p«ÙoÁ;m"iâãîÈYú™Înÿèd;‡`ìÄË¾øÙuS{HÍ —Ê×¶ÿnGÊ^UŸtjÿİÀã _ëÒŸ‹/PFø¥ÆSÜ,ú:¿v´(ãÈ³/B¥ß|Í•Ò—„‡NV2!«Ò¨O¬ü\r—40Q&u‘œå‘Î¯éû¨!ğe*ØòÒQv0•3àÒŒ8‘›ÄŠ UšÖ÷P"nÒ˜w?}Æ1ÔW¸†’ñ+`ñI ï—çËååMş#¦qbÙ}Ô=Ê£ç;.ßÕÿ¹of“ŠÁ@Ú¹UÄ›LÄ/Şz¶<S…[W¿}.‡Ê%Vê€Bş?UYiœÇ]\†r}fÁœi-­‚¸÷·Á©,jÖ¢Q«ô¢Yxä8ÛĞÎøiÖªhçM‰í7ş
Oºèğ74Øy¥«ú™´³lGm_D…POeîğJÙSX–§Ã±âà}Ô l,‚}…ÎÛØØøß• 9.Î‹_.hMc€b§ßUYÛÒÎé÷·¨SMórøŠZw6Å°“Ãu¡†•·-/ŞGB(yÁĞ{ZæÉ'¢ÍÈ± ÕÜÛX<#8´3>èÊŠ,}Î²–³äQ"ş £ˆÉ¢§2;Iœ/M²9u"ãÔÓ>^—ª•&ô3„ïØS0ımõ÷ß^0‡Éd:ß0sœüS9d]VÓ†™•ÖrPÕË+±»ûŸJnèÓ$Ş—õcœ7¡ÑL¸EÙ“–¼¾ÊŸÓ±#eŞ?Gº‡!T/-DW‹PÑPD v½¢(`«$ıÌ¥±4Î&#&·ëøåg}!å©€•
2øCV,˜ğ$' @şåŒ {‚â×hÚvmqšv¶15ã{rÌÖÊ-QôöZÛÏŞMñF×`ßWÛ7ù
ˆ„İŠJ–k˜İøÏËæş[N.ı…ÑÁU“<1‘Z¶ÈÙsN/z
Nóvã®*[»á´Hïº»ÌM§=|PeóÊ©‰Òß´]?ÉÒÄ ¨®²·m—*Ê;wf™[—•#N—&˜7ÓîÕ€cİîc©‘
å«LåYŒ¡3ËäŒBõuŠ«jçtÍ>O±Ô]ß;å­<ãL»mŠüöÛO(›‡4'ÖëèŸ5•Ì¢Âš‰^’uQA‘ ı§ğÑË/õa S¯ÿÔÉvy­Åß€_VA	uÇÜQ£`q„ømaÚd…××àø…ìJSˆİuˆŠ²Ñ•³§­{€i?Œ¥*9V÷çÈ-Í8êâ„ûh×’€¡®ñMà×a›*/ƒ1+Q‡ïæCxG'K6¦ Vêúxå’¨<}¾—4)áÌj×ÛxÎ(é…&¯”y±\ŞËÄ¯*©X¾ı`«¬¯ÿĞå	ºÃå«‡btì…<1Èóï%‡ÿ}eàI´ŞaÒo‡¢Ãk¤À+ÛQ Ö`iYßQBˆiüƒÖÔ…SãÜà“ÔGëAr`ãW”…Fwnå\A¨M¯ú_õsÒ'!·7"ìÀ;—Æã”v.»Bîâ4%Ô}oî©²&íúªKÒh–ˆ1µû‘„${pİyHÊ$G`!kŒÕ3Ñ²^Šğwìsëƒ°Ü°hĞ^pé²Fbı–¸7Váì{2V×S~·á#?gß@S‹æ²1¾ÒH£¶ú¹ñ¶sn@¡¾\ î‹Óë˜
Êµ©Œ>WÎôNÊ¼„·úÉ`Æ‘Î»ö¶)”Ç–rpB’+ƒÏŞ{ !NCfU%H¯?ÒK¢uğkó<&$CÑñçr¹î`|$˜l9K—®†0¯R|!³“ÅrGFÚY©çd»Ë2,‰uòü¥E/Ï)J<|_’×îÔ…W¨X	ªBèS”‘`¯%F}ÇõNa’7µÂ+	§OtjjnZŠa9ûÔg%vVgÉ`ÇëOM{VÛédç2gˆ¡=…sS‹}‡Ñ‚Ì´q›>Zç‰:Î*Í=h@5˜GŒL7&õÀ‘N¡õÑÜ× %_OGªÖR÷ŸgMÇpª¶/?òş5’¾ªÉpOÍfúÏÏæz\'”Uú9ù¿Ã=NGÅ¼¶ë¨îä`£3Qà¤ägSÓÈ––e¶…„Şú^ïíùÕß?g·[Sö¢3^=‰p}<[¡ìóîôdëhÒQÇxJ«<ÄV ’¯_YNâxùÁcä ²:°Úš‰[2ÃÆØ“¾¨`ıK¯tt'ÀXoÉåmÙcÑ×e¾]	« ïb‚¿½ĞõŒ=U'ï¬!*`½¿dú€`çFÁ+“ç ‘ín¶÷ÖlCêu(¸Æ(…4b	ÃğÜÆoë™¢>™Ÿ@CŸ	>É?å?ÓÔ£„i)ë_ÌË­„öÒ&®3ŸCTíF=ÑcÉFÆÀ!¡¯»7 !¹ŒTÍ%g(–´€ïAH~ ¹j´TúnÖYbÂAòU<F‘æ™¼ŒV:?Wïò&÷:Ü¹Ò’×?`[^lÀÎ…Ây§ù<¾—¤-]ßf;Iµ	¦ê¾T®Œ+>™•JS¨g™pÿËSÖ
|ÊiÀ„E&ÊG4¼MxÂ·{;÷üë=Á=Í_ÂAïX/)o–‹ŸSÏüí^•3¼{ÖGáãWâÛ8S•˜µ
Zg,zwxâ4²j â`øAòÅVQ÷BôW¤ï±H}/íÆ'š—&/&[/eT:X²”pw=­^Ò-hi@[İ›˜ÒÌqZërñ=¼Ç‘ë¦Ôs«ÄçÖ˜-S	ÎÍÒåºF%8¿q‚şmèıåÍİ™éÔ"\à–#Ÿ??w_¹ÎãKAlÊ<­Šİ(.ìïpTæÁDÑÅ99paséõ\ûj.9$£*RAœ š]Îxça(çoğ†B:xF-9Œûª¹º6 ÍHGĞûÃ‡¼©ÒóÂ”Q¾jgÛÅ?¡ñ
y<4fRºu–ÈiU*}MƒÕÁšŠfÁb¸ÑÎ¦ó1äæíŠ…¨kšw¿Í`=¬ÀE¶+À3™))n´ÚrúÀô„uŞux~ŠĞ ¶"Wb7W4únP|ËôÍÿ”1Ü^ÄÏèÎ'Ëæg/íÈËİ±c=R¾í*Íe°ä3Ÿ×‰œ‹ÅD¶H`×c*Æ€8w•¶Ú“ŞÛÉD±gÂŸ€ekr£Ÿ½H¨S/C ²6zÄ¶Û~©ËÜD}¦;L]IEÛ@õâqaÎãü+‘•m=<
²_~®7§@Û\ÔGS¯*uçÀéÜÕ4®4E†e”'#|i‚:døÃğrì5¶j|›»ì–ú¦ğ.>˜µq¨)„..)?xİ÷ÅÊıÖx ®Áã50F5#!>àW3	™	¿}¿û(ˆ€’KK^™u²µ<ì“¼–HH§öLÂcqNÖPyúI(‡ûæ%¹C1G©°n¹CÂ4É+ÃÆ”×YH~”ô_èö&"èãÆk6;Aô¤kÏ"ã;6 ‘Ò‹ÔÁMcõà2% Ñ˜@«°Áq¨†ßd\(ƒ`äúÔ]÷Sì)ïÌkÑ@…’i‰c«MÑv¼(ï²Ñ(%>ê]ÜşQP“×¯‚ ¼@ ~ë‘DCIyzÔÇ®ûW«’Åd¶¨ösİ<Ü!sW’,P»åÖŞªÅğÆŞ°tãÂŸ´†~Q1G¦è´…‹µsŞÁKÃQpÑ“D2¼YDJ…ÍšÉùÛòÂQê‰:Ú§Ï[ÁÓTšoÎ©Uh!ÄÊÓc#OÅY2Õ¯ãóQ/lA“¼uS¬ú´ê0æ\—èQÔ¢](W\ÙŸ[]°e,X”I©7³×>Ûmù¦ğŠúY˜Ô/IĞä)Z•İñğ5…q.ÇwÔÇ™ĞîÄöÂKAÁîhqüıdh¿S¯ÊLÆ½jjß`%ê/ò>ÌK;o®1ÿHM#¼€/¾¡®;º¤¨C;‡ú“ù˜ 2¹şYŞÄ\Á°bO0MÀYÅ(áäx—D&xª5éB<—FX=·Şzä<eÉ]1É“åª¼"Tí²2·ªÄ³ÿh{NPÖiCÖ’ÕÙDÿ	@A
_“W"¹ñçË½öÒB ÄÔ
#K¹›½®eKWušxıóo¯ˆ`…h³ÇbWltÊ‹)û·îBÔ Z¾‚¥Åw™åéVÜ÷}Ş(Õ!W‘%•Ùaâ2‘hDrVYz±Ì ©6§‡†;Ğ¥«İó~m[\¡b7Mu§€ik¬3‹zÅIÒ^A¶}r¤Så6ĞbFK¿/S^Ÿ|­R¡\nÀb+¤jÖİØ+4C§Û1¢üŞA£Pdˆîÿ¶	¨êæ,¯¿¤â^øj%£´¹sN‘ÚJrõÈò¢Xÿ¼®ãh&x;Wz‡5Û:ÃUEˆ‘<ª`ÿÏV…Üø38]¤£t5v¾dV[D<ál:y>Í]ZšÒÇó¦ÅâÆ¨ìÆb–Îd\“¹úc°sÌ0§À’ØõpRR†…N•ƒY×Sƒ­õñ¾¬¶øŸßÒÛª½-Ic3+–‡%¨;®ÿŞAÃuF£ô –0‹EY‰m‘pP8Ó¯OÎÛUB‘İå<W‡êÂ¨€[’ÃêÂ˜æ¥»ëú &Ã\¯ÒQ!sÏF›AîÃZÚÂ5ùÚÔ£¯j,_–®İÜK÷¨`0!=døÓ#ê¡ËG[ğsº¡  xZ ³²| à´€Àƒ_A<±Ägû    YZ