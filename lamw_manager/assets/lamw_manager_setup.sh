#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1191555416"
MD5="b3e2e1d426006226c9befb1bc71546ac"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21500"
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
	echo Uncompressed size: 132 KB
	echo Compression: gzip
	echo Date of packaging: Fri Nov 29 21:29:32 -03 2019
	echo Built with Makeself version 2.4.0 on 
	echo Build command was: "/usr/bin/makeself \\
    \"--quiet\" \\
    \"--gzip\" \\
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
	echo COMPRESS=gzip
	echo filesizes=\"$filesizes\"
	echo CRCsum=\"$CRCsum\"
	echo MD5sum=\"$MD5\"
	echo OLDUSIZE=132
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | UnTAR t
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | tar "$arg1" - "$@"
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
	MS_Printf "About to extract 132 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 132; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (132 KB)" >&2
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
    if MS_dd_Progress "$0" $offset $s | eval "gzip -cd" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
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
‹ ì·á]ì<ÛvÛ8’y¿M©OâtS”|K·=ìYE–ulK+ÉIz’J„dÆÉ!HÙn÷_öìÃ|À|B~l« ^@Š²twfv6z°D P(êĞuıÑşiÀçÙÎ~7Ÿí4äïäó¨¹µó¬±µµõlgûQ£ÙØÜj>";¾À'b¡òÈ2]÷ú¸ûúÿ~êºc..ÇÓ5ç4ø§ìÿöÖöNaÿ7w›Ï‘Æ×ıÿÃ?Õoô‰íê“+UíşT•ê™k/iÀlË´(™Q‹¦Càç‰zä(ğóÈ“–³0±…JµíE£{d8µ©;¥¤í-üº”ê+Dä¹{¤Qßªo)Õ±Gš½¹£o6š?BeÓÀöC„S¢ÊÒ®›ßBâÍH½S/ øû¸uò¦ç@u2:0˜ä20}ŸdæDÅ1\‡4ÛQrêì\ı"œTè•ïíçgGF#yl††Z{ª&¸˜ñÉÑ`Ü=ZÇÇÆ
É‚æ"x»7èjÚ~6ìŒû/;o:íl®Îé¨3zãÎ›î(knÃ,ãç­áCE¹JQ ÔhX©Q Şè4ô‚ë"ßa›ªØ3ò–h°oµşë½V\‹JŞïãÎ¹J¥œ|ó;Œ®¨5ÖuÜä¿ÍÙÉ§·D™ÙÊz×rƒKWH5soÍÔ[,<Wcç”o‚bì¾aèN`[”)Ğ4¢ÿĞv({²qC”JÂ+=\øzº>õÜğ
YE‚Åz}XÕ-LØ>§Ók°ï!ö,²<² ‹	lÂÎºlí@R™š!Ñi8ÕçùäodP_‹l?İ¢Kİ'¦ºögòAÉnÂb*«b×T*‚:>÷¡cÎŸÖ¥—ı0 gĞÌoª 
?m×2j›°ÃÓsduCMhQk	ˆZNQ9Aé4Í¬ë\í¿t=E«ß’*€/€Å$ô,xÈˆ;€³á7X=¡¼éÊ2¾ó‚¨ù4E™Óğ9¨Sûä€/[)àÒÌ4¡²ª†µô7Ñ®Ôt¶AäæuˆâÛõÄ¢33rÂ@ZÙóNÍ&>µD)kOS¥’u¾öçµ³ö=Çmxi‡bFx¾°C>§A¯è”PwIºÃşqë£ÿ oZg£½AwmÙoòùô	®’ZÎ²ÙË…É(c@8"Ø]B¯ìÔëuu? ¦•røuâ*"wŠNA‹ëÇó•ÆRŠ:ÂEr’*•L1ÈÔ¤@¬ÄM±ln
+é¶òÆ˜Ø…i»)¥
>q²ºõ|àyaÁ}*•LcUcÎ÷IÔ©‰2ç!òüVùc“Ù)'\‘•Šlaœ|XßŠš´±äÑ×Ïúø¼ph»s2„88¤V=¼
ÿ€øw{{mş·¹ù¬ÿo=Ûİúÿ‰ÏïmRÄhÎ&í)•&éùàùx€6çš¬üŠRy$ùĞï¹aÃØÅt-_É§–b@ä[£üë“¼ú«b~1ı¯£„ã?û÷äÿÍÍÍí‚şo7_õÿß3ÿ¯VÉèEwH»ÇßµõNZ£.Fl¿vïô°{t6èÉu>J‚‘^Dæ5·1x/
!Ì±y\O&ğlºIBì…gÙ3rf7¡ÄñXXÏ—Vó{ß˜ˆêd¥Cùõ r•ª<$ğ‰¦‰Ñuì…a!£€ÉäÎua^PF1ƒy„Ä32¼P tM'FÆ :¦³=r†>ÛÓõdXİöô/STP²úœÕ¼ÓŞiÏ±rdù•oºŒG´çfÂÆ«(3;`°9ÓiÄ3
œ©“wÁaØ¼7}^gÑ”¼Õ»¯VùKÚ^rø«ÿ7›»_ëÿ_rÿ§XxÕ&‘íX4¨³ó/ÿÃfo¯øÿÍg_ıÿ×úÿgÖÿ›úæÖºúQĞx¦šú¢ßvp ÿÈœº4àa	 D±]ğ‹xTĞœ,Ÿ´Zƒö‹İm´\+ğlë9v¥jÑNCbÜÿãË#3§q¦e×#ı6Áz£‰e¹åÇÿlsiS^¬4^
ûm¬;W”ŠãMqmgÀ£ö$­ÛŒE´îÒpËÃù)°VŸªg“È#Òü¡®>À´‚‰åÏ±K/Ç;!ãe×ı}>ìØv£+r1işøğ‘”™S%%§™‘±UoÔy<gƒã1,ÔP“ˆŒ-İú, ÙAãÔ½`M:pQÍ9ÓêP@<Ş7ÆUÂXÆÇİçã~kôÂPõˆºcOp ‡ªJ`íÃ£y '­>Í‹(ãNkØ1Ô;'~Õ»½S#^âƒÈÒkÒH5ã:¢Øş¹´ı %mß¹$èÅîô$YÆÕ»cĞ4E›»ÑÊºÒ•‹HAiæÊ‹ša¥ÇSˆ?®ç¦@¨üà¢KÉëØ÷Ä›öÜ?ş4
3€‹.yÊhA€àÂìÅäã?{êñ¹+On´ 7Œ÷ÌlşE—hìîÅ¯şt9HjÈ%ü^Ç^±€Ï˜*^ÿ+é®„éä%ªKçMÌÎå¹==Gn/.@U4ÛF\)Wk¹A*1ˆª®”c.rT[7ÕÃæzØ2®_é•*ÏxÓóîÉ¸¨B¾K+$„üôBY…Ã$<B'‹Óg§/IjÈG8
‹ı9Ör YÑ6ëm®AMÁÆ«pµ›•¶oßiOos¨ã£˜ì/İ~|dº}Ü=={3~Ñ;épÁ`ç&D§°<€tH˜‡¯NG­£[nKf¼­Ë{U}¬ÏUKV—
béô©\Ş¬.ô¶mÄr]ŠB- ¢*zJX·Ò”'9sµÕ ¡±‡ˆ‡ôq/¨¬Ğ\¬@^¼X˜ Å„‡+ÊsljcœÓ
â”÷Ütç4;·_Y¨Ø-R)Yw¥‚µ2ŞW<à4XNæ?’Ú2i÷ÏÆ£Öà¨32L°€½şÈP5q‰c•ô†i¿ˆ¨H{Ğ`Û¨WÏZDkÏ^ö_m©$¾ş sØ}càÎTª|¹1¸R(“¸%U‘Jv'AÇŞÙ İ•4¼È5CôZQ°ÑøIB>üjû	KÔ~_ÈJº÷¾?½Úå>²ì<Ûq¸x‚L{Ñ»=4éì‘C@Ë¤ı×dõ©İœö'­ã[•«eCÀ[¥’%–¾š›ÖJµ_ÅĞ¦öëÕr¶ª’¬/cÿ*|f_yY—3«ÕCé€V°A„ë QIÀ.ëB+˜ïn—êÃCYÉvK»ı =0ùü%’Ÿ×‡+Ò^Fİ]µö~Æä©hR’ŒG9š	–’‰nÊ½Ìø£mÂ§r©úiÛ‡$ß³u¸ˆÉÉš—Û¢9¾ğ»m"wÉ&¢‚¬İÂ6Ì¦±ÅsÏ‡a`ú\Ù’t€/4Øó(@H%noKmÒU—ÃãÖÑø°‡F³uz0èuÆ±î<È8…OBÖÜl‰êKÔ †'Î.¡&q	¼ısÈÉyx^1#$¥/çmILaU¾<’+±«ŸeãJeHQLúæôÂœSáq:‡­³ã|£Ô¶_&	»íZôŠ_zIÂ@R»A€áÛï{ûÉkÍ”	‡¿VÙÿåë¿üš7A˜F-\ÙïV¾»ş»½»ZÿßÙyöõş÷ÿãúïK¿šé,Ìß±şKÒàZ|ŞX"ñ¬(ó=—Ù‡òÚ.Gˆ½¹‹ºxL¼N\VÂëjõú—ávI±€á·CÏœÃ š†R+Y&¿kI—Ôñ|~Ğş‚C½ŞhŒı™üñZâ†/åàbq˜‰æç ¸Oà£Óáü~&^zQK=‰‡2¯"0­L¼5¹J¨ï1ÜeïQÎæ%H§äîùq%yˆJ~æûç#è©k‚Ø´‡Ş™E—œ›„øí†3òxxö|øËpÔ915bõ{Ò7¶õŠº–ÜBóŸ^uNzƒŸ ï¤wĞ1ÔÆîî.<zg}CõhxÕwîcBş!¥¢áç Bñ³ô¦SZçMH£Á¯á" 	x3Š§Åx¬Ê5„biÓşÙK58ó—ëŒIV‚’»¢’ª,~reDÎxóÕ7¢Y¬õÍğÜX_°Ô¼<B@TårRº$IÄò V>²EÕ8]<ŒaëÇ iÆ¤I­vaí$ÖUnƒBjÑ”¦(Écœ§ˆ§7Vòb¿E\Œw“š[‹»Zª´ºk]è¾c†`®L¡µèd²x·IŒ	{4ÇğÛrêÌãqãAwèyäÂïèåDm×Ôı€¢
uÑ-ªqY¬Ry¬Fù­?KaäõLã- –s>şäúÓÏ„Îc±K tİCµğ{CQ²:xAIlI4oˆƒINt„E¨T×cÛ¥¶‹™809“„èmã=O´ñÂS®¸u&=©É=˜õ5³#
25ÁÅ
ÍÅ…Ãs?ÔXPxúÁÌôØ-H2\‰sÜ¸š’Ğ§U¢N%$-ÖÇÕê–e€õAçXèõ7!b¾h‰‹–ƒ’`ªÈ‹M 3£QÄR%úŒÇI”×vñï^íhĞ:8îä r_]l^1É_#úÜ1İÜ‰ä‰”xõá#ñ0€€¡²ºÛjMf*=§K‰ße),ï¶´×¹^ñê
)æùÉÛ*±7F:šü^ì'BÖîCÄMCf-Gr²İ‘	Aƒ¢¥åñgb,î÷h¸‘/A’3rM¥°…	yu¡^”G`&èša«‰/yŒ ‡t¹ãÏ±'e„B0`Â(Æık|æ.3 ğ=~Ìè£T{XšfÒ±Èl€¨‚kZzS/"ùKäÉğ1¬Ìl(¢’Ù»tiĞrœ4ÒG£ë\Ç×·5ÄH_µPˆ•ƒÜ1lÌ¥;>Q‹ò²ˆ°¦ó×Øe,<Â’KûW3ˆ½Xm÷ f0<ş¥58âKÏ;Â'…”µT¤SÅ8sÖLš¦T÷ËzS=/ëŒ×²¦—)*Ãê½<*†ğœ—Ã7Ğ£Åº	y	Fœˆ$Q=ŞİÀ÷’ 
ò”'Ol£±oÿ©vS•˜óöéûÛ}û»ï6€Üè'B/Ì~+X¼QÂ½ì'Ñ«cãŠ;ˆ=Å²Öe`‡x#wÎ%2}—@áíˆéØ›wE£ä2ĞßÄÎÚ#·O.U­ Ê¼)±E“r•JÓ@N=—|„^¦§éA^Y+?=Q»îÌÛÃ=UE¹ã ½bé6í'—^pÁ|sJcæ¾î^!îdpq=–€£•Í³.ÄŒIÿi¾ÌÙ;÷¼¼Cs–‹ãìŒ¥¬Í¨ÄÄ§£lÅÒïŒ1¦ıùg‚¡ç¨×;fP+Mğô@:#•x§|¤&mjÌCa#¤‘FQ,&ãáY¿ßŒŒ;DI;ÉeSC“¸W{‚_Ğáká ™Š…ùÜ»× Vjüb],ajzWá´7êş2B¸)n|S¸BP„ ğ"öÎ½C¾Dg&\d”‰×;w½le}”+˜³w´w?/RgÄ¿e99{)®š§@ÿŒÅ½sùË·`³yl Ñ1É–…Ùä‚ºÁ¨›C¿“wmÅ’Ë®D7}ßIß{H£Àê”Èà
r½GØ7ÂÀÈA”rNƒïñıc¢ÈXXÈò¥œ‡N,œÒ)^Øªû¢>ÀJë.-æÍÙm‹²‹Ğóy„ğ·¢™tğå‘÷"wQOÍ5²-QSSoO‹]„¨v®è4wôZ(r7M	^˜Áµ&2*'&å>O¡Ê¢^ƒÁel;)Aİ)º¬<L«×mèb<Š
"6öèêĞÈÇh°°]Ó1f&h˜hºö©ÑÊö-fC$eÎcCªîÃlû«Òp!8½Ü?:ë¯í9pq_Ø}\Sä¿>i;&cEvŸÀvr²BzêWš¸C¸ÏŸâ…c½ Ãšø'
å}¶‹•AV ›ó--E$Dª´Ëù©gQ˜Ô1¯Å*_Òk°53Dmy¿/Ö:(Áaíîìç™ô²e2Íë½½7ÚËƒv
KYÒÎUHù{7ï³ıûÏaˆ!oxe:5êÀ4şøFwk5|Ë¨Õ<|MÚHtâßVš°õnk|Ò9=wG“$á/Õ)ÌsÏ!d'ß]‘²qĞí—vÀ4ès¸:Ã—£^ŸŸ§ƒoj›¢zĞYú^Ô9uüúÜõ”ß-5-k]³.4ş Í#Û¢¨=GX-VÁ.E /´’øúy¸pêhhRÚ2u6;İ\ÄP¿Z8Ÿd‰âl‰Ï¿L,?ò éĞ˜ÍÙèO°¿Éìà=÷6¼~	©¨8HİA÷´Ë¥ì4ğûF¢’ Œ²°¬ÉCôY 6(Q2¥í{,'öR”î9Ö8ïnõ~—¬®xŒ¢¡LıYşT &×öÕ*9²—Y–”Då^-³JbêÀJ%û`.Í$reÆ“ìZì‡åBÇN­vÓëwN†è7.ßj` ÜÖ…f.,ˆIÉ§²·~ØU7rós¥ªI[h.Hs¤½ıÈ«Ğú8¥J<3İs^ğ_R°t$oº¡@É“ƒ´*RÉÚo’Ÿßêğë)`NÒTbck¾ş„ K!?%¤JÍ÷D‰$ÿ*ÉæÎ%°µ›<õ…6[u	 L@K.öåÄo	ò7@è‚Üsü!Ê$‚|ÿñMŠ@Née_8+aÌ±L:ò^§³6ã€?Áøÿ/ĞcfÜ[DIJşãø‘AhZ±ÏáÒRÀı3æ})‡¤Î86>Åş\h¼
3ÌÃ°Lø|Q-©K„ØÆJ^ÚçVoøËĞÏDè ®­æmi‡×–ˆü0rœ˜Í<„Ks·@XÂ!Í8‘ãC*¥[('Ùıø Åh$#ø•ğıàS'Ñ<ÉWi5CduâŞãNqW(XtÅÅéñãO®~$CÕ•2¦ø÷@ñ…ğ3ŞÇÒ½<Q×\9®8Sjñäâá7†Îä¾«¼6ë.@ëØX=k™SIµ<úY‡µ„5ªäsÈİr—„sÓº‰UãGM®“¯&™7ñBÈıKY‹,»#«TV“RŒ*¸ºQĞ¯«kñ¢–0§†ñÙÊ?ÕBùlÄ0áÖéõÿmïÛºÛ8’4çõ+ÒŒIj€ ©K‹‚z ’Ùæí ¤İİ¢N(Re(LU-kÿË>ÍÙ‡}™>û0ûhÿ±ˆ¼TfU Ò”ì™Î‘Tå=#####¾ˆgçòï¡á«¾“"Á¶*ë‰ŒXµaO¿Áø§,SCÔlƒŒóëÿ%@OèWóÎÓ¯­Õ¥Ò¯¨›;Øn dÂÀ;¼lI¿şovåıxtO†’‚c­U¼³µ‚•½a0€›©B¼ä¯±Ö*u‰&=¸¦tŠƒÌ®ƒäƒQvS£n”Š«ô¶úz‹®{ôWÔ	u¿#$©öÆXÀUuO–Ê$Rh¬V/Gá9ğ´˜©ÁŞ^Ñ˜Óî>+SE ¾W¾9ê<£Zø·­L{»bøWádÀ\¸õÜà`¦úĞ-ì“-g:*íyYmİ¨Vgt¾1FeAZ£ëæ*§"©Xet·Ôß9%ÕµúÙ[¬úì‡úp-—hQNlˆ5§²œ…·›GÂhõ7ƒ€MÊfTå¦B7¢ttŒ¹$”3ª&êhLD¡­<¿ÇƒÙhW-"ŒdÆ­ÚV­!ö	ØÀµ{­5é=ÈKÅH.GêÉ4)RzT£‹|"CnLÓš‡L-Fr÷gÓA?Oå ¹®ÿ¼v‹ÁxÈ¿Œbü;F±ğà$‰¿¯âAXK†üû0¸¸HÍ¦â;/›Ád€_sã­ş°Éõ.tÃOÿÕ¼IÌïûùÿ?F¾øZœœ@“ÌÏZÿÈ¡u¼ø†.mÚ×4*–Vœh_U’aÈ«¾ç%DÑ2àr:‚sY›&üšrˆ‘wŞ¿Ä}÷e·ßaåß)–EÇşIÂûøcND
Âayï´¯¢Òñ{ïñv@#_Q¿Æ¿Â_o8¤¯  ò§PVhV|û‘„ú&_ÎõE?ù¸AOs]o5ñÛtèOéïl8‹oD%ü+Â°à78¬óîO“p*şÈbo¼v1Q ¥D1®î«ô›HšLµƒ!Å­H‡éIû*²¤íŸÃ"¹1Ï ñÜÒKEÜ–›Y0Ü$&Í£uèóRùŠœféÁ£=•#WƒøRrœÔ>ƒ0’ıÛ¬% ÷/¶!ÈæÕM$(ë¢œkõ†gòlpfš# ‹.*•Ïê"*awêwªï’dÕíZãŒfjüÂİñŸ­õ¢üÒm*Xzæª[Ì+äSÖ¤W O…£¡”&ğR'=f°t‡Nutûò‘`ğ¨oÏêx \,¶}Bİ¼DÊÑĞL	»½'ïú3’ ,Ï©@O›}n·AÌÖ®¥Š“´Q\enhTªlclw=9•b#‘Œq‹]O/µa±J³’WÃ×Ó¦Ô„"Z+wxN}nÏo&Ú7™ì^Ë*iêöIÑL!3by‰/Oç…0nå£%5n8† È“Ù²éÅ‚‹ÆıpšÄ-¤G7=õÁ5¯ ŠÈ¦K—â w:Ñ9Åµ2ü…P‘°ş{_Uh&’‚Í¯&Ğ 10š1b‡¿=ñ|k÷ğ~Ôçl¢5ïX!`—S—¥öÜùâ3>øZ%%C¿{šB¡}t?Œ‚Kqò1t£´›œÏ&Cnm†€åªadSğx>ëY:½`H¸ò‹i)›ó{+B›|Ûà3ÖÉûD»¹ù–úò"Ó¹/ó×)G¿q¿Zr#½ãƒiüxÛ™ÅÜn±ŒÂŠæTfÌ%sØ¾gˆMÃFæ6Â'&O¤É½È%¦vP±óŠ)ñM‚¡ÑÑ¯3Éùz““½Ã7½â”“s±¾‹_Ğ^<â9.=nœwæqt+R‚ÊéCş$±ewJùTë´ÏV²/ØÏ¥{7®ŸÕ+y¨˜zıÏ¿åQœÏºc/‘÷w ½·r;²{Yœò>G¦Ë‘áq$æûİ»QÖÛ~ÏÄy_Ouwm‘oĞİrr¡;æ¾BÎgòRnG™	ÔlRõ™²Á~ãLA[æÏÕ¼N[Û³¸ÓÿùÀ1<ÄÒ¯ºIÊ­]Åîæ)fq»w±åÄhmh`fR ×¥yqÓ.¨šËör÷“&ÚáÑJY¤¸].J)wªc4\¶’—îŞùŠ•ßÚƒ¥›mÿ˜ß)?éfQãÜ5;f:‘¸0Å§?û«[[E,$GÃÏÛÁ5y~À
ğ3D4 § ‡#îe%’ó®­§Â«b—°¡iNåÅUl¡QÆjc¬•c r|³	Wëg÷9ïZ¯“—]= Zçğ»Ö¼RÙôÙ“y‘JT7*±¡õÙuBªÈı]|Şmwÿ–,·®g•ô-VS¦¨V£¡ºÜ\Óê%üõÊƒµÌŠbä
 (*fÍàíŠ 9AnTà2Yà g1óùÒñ[»ĞÇµ´Æ:0Ù·ôC‰†!ÏQ’ğ¸UB:f¢¸C¢,ènÈß%ÛØ`
•€léä¯Y•ÄùÎ¢ÒÄHÛK£oˆ*:2ñéKEÁ´¾üËŸÖ¬6C«PlcÆ*ÓM‹3"³@# Âk®ËÙÊJk}reˆíkÏÿŒÇÒGÍmÔ6]8Â!0™–{zòºúÔıóêås¾ùÒóÎä*ˆÂ	šàøILo`ÿ}¾ÏkKñê¸Åø™[ı:ÁÜÔ…qšTÿê_!áW”%Tˆ4|oì«²ŠxVšùyİÒFzõ¼.ú¢[ºeÇH°F«‰—Ÿò‚¹êy	ãâål‹M¢É·µ,åsëf=TlâéŠrÕÊºô,ìáu]û„¶?#Û'(İü¦³9?“;xVY‡yùÎ6ÜÒ£rJåÆü3WÖùš…ù
0.iu¸L°U\@Á¦AMHØ¾m,ø±.V~Ä}‡Q8Eƒë|Ê°‘k…D†í¤ÛÅ3NëkgSŞÇõâ5ôQ#çañ,™x›£‘„4ÍÀ ôÈı%ÏÌbTìÒÉ-nGıÍCNDú¹F¾ùù­Ï2ò(ÊÖ¬!g¿dü¿ÆVs»‘‹ÿÕXÅÿXá¿-Â»Jñß6kÿÍ‚şf„ùšp$‹íöÛãaÀ&Ìÿ ‚sÁ¡!ò`µQ¨+8ó|ÂK…÷àËõ²´‚D5_ãÍ)¿Ù?zÙŞgßµ»{èÔŞãÕ¾
Ga„.Ÿ2Jõwîn§UY;óß6v¶šã52ü İíìñW›ğn+}×;}	ñ7í]|½­vŞt÷ND–Fš\Éªj,ïúF™”lÛHØşûé¾*`;}Î‘fE3áqûø¤¿ôêÛŠNnıÊã–ÃéûKÜğz-}êMQ¿'±ùjàŞùô @šq>«*°z¡ãÏdè:Nü¤K†ömØ÷Fœ™b‡ş2•ºµ6ô#ÁXNNåÁèÎcræ”Ñ2Š ÛäÀ8Àë{r»£°Âşà!^;Ùƒ	=B¼Aæd§SqŠjbš²6ğÖÀñ23[EvàÚØVg.†~¬ùƒå²¯Ÿ7s@àÜõ—¦r4.¦Z…²ˆ;È`]WØmRe¢›<hòqàî¬´š¨,–7zJfÑöuá¨~Î&CF¬ÁğıtríÀá¡Èİ[k‡G‡5Ë˜™CæVšù7t=à|ğh7˜B¢Ğ¬4'd¬®	C—Y-Ö·çtIô•ôµOœ~^á¾^ö¢Ë˜ñ¡„q•¿i$)¡ÏT¿G3†2Ñ–9–ÀÂ€›¶Ö+ë=”P~®àUTÃ uñŠ[H¢ÛPJßà	Ê­õ~ıuf5`**‹Ój-ElWÑ‚äS¦Ö%hUiå#|­×ÏêuöiC‡º)ğ´O‚°)ñÈ5¥2—Å…öXH›o½êOíêß7«ÚùaÃDÒ‚ñ‡\˜æáÒÿÀ¼ÑÖàlŒø |6³­J; [WÜ>B”í¤H'\Û˜;áĞ4ïL²Ø"+›ŞñşŞÉIg·ßîvÛÃRÅÌP6š¨tr²ÌA¿í†’åÅ¶ gª¤w’ÖÑªä0}*l7‡çzÓ…É„M“på€>xQäİ ‘JJä½@ZØ Ğ4*%ïü‚NicSI¿ón¤%é’3§¥N¯2Ê™…E-EbA^†a¼!ücTªSÆ¤ô•AÅĞ¤S/F¦~ƒî>EÎ„RiQ2´å kSŠ¹µ•Îp{ÂºZ•Æú­V0¬¨ô)ß˜pİ·*[ê©èŒ©X´`.™Ôr°bê¥¨”XÆøØ1R†œóp¢Ù`†ô$’×«‡°Ñ0^ÑG&]Ãái²;úM… &Fˆ˜ô“,ˆqï¹'9Úw ^ß‡„íİ¼ÄošÀÇgNÎWbRT¤ÁÂãÜ4u˜)QdsbøyœÕ™šYşF·.ôÊËXÃ?ÊùçsW°,€ôµ/P5)Z`Ænš—)—Ë´œ‡¡Õ5`”ÎŸMîÔ}[¶ÅPæ—Hdq!¤£BÒJu9†ª½7L£’Œd6]PÂ¬·#Ëô:ö·ÍŒ²gbj,Œ¡_8sRº­IV›Ee"›DjÜ*ë×Ñ÷5Zï6·¤·ß<V˜Ò[t1-ã}KïÿPŞ¶Ô¢Û9×jcŸÂ`uÃ0‘„Óîb ¶Ğ$-¡±9Î=7‘ÆSvÖ¥R7ñt6K<¨oêBÖ©a™‰È*âduŸÜ¯H¡U¢Ù„|1²9úŒ‚+˜òK?>›tà¸ë»V«!	½øº	Ã…ÿÓ™‰¸ĞPè;B
fB;wœ}¬ÓŒÎ‚üÒO´ÕÑÈÂ#’ÃT°ŸûÃ˜D»<ê…_e\CRiÎ>`Õ*LœûûÖ&b%à[VQi B§(T•-iaÑÎ)FÚAÓ¸‰Ÿ@ÙÁŸ <İ|ÅN¢†(ÑW®åÜJìü;îfcF‘æ”5NĞ &Fv8{ˆØ:…qFáÀã0~Èˆõ"ˆ[ì]úc" ¬_ÿ®Ñó ­h0:äA`ağK½œÅ7>µ™›ˆ4éœéØ1LÎñ$HW×N‰»ãƒ·›?È÷ã˜Â×ït.	sJL—üXóù×Vö'ÿ:C%]hªóe0›Ò¨Ô°gÊ"{1û´}ï	ÅO¨4¸‡B©„­jì˜P¡ˆ¢{2L­>?So ;#HİQ8f,Bàş‰ªc*ˆs½zÄ	¯ÃëêlâÍ°E	º"øÃlâ>,ÈP½>TÇÆrºT6\ó”V;>RäÇj¢âìÂÑ&Û^ù¨4Z8N	Vq1p‹ô·tò¨<ÀåY{ı3g®›úŠ^˜[û‰=ç–¬âşı,<Õ$r IÂ¬„üÑ§Uğ /ÿGĞÄıÇ~_"şÏ£'ÍlüŸ­GÍæêşgÿıÎñßÙâÿ¸:•/èç•Œõn„r©€?C-Xf~ò…"»—§‘Ê°O ›³Oà|ÉJtäÖqë7‡È ùC¿fB-;¦qê·šæ£{éh`ÉÁ­R\Ç1N¹ºÌ»ŠŒŸ#Î ;™0kbRŒ Ï[YÕèBBÅdNo}H9<´E¡¿Y§ñÈu®òÑRœ •Ëv6-Ç¼&Ğú 'á=ĞU¥üŠawŒİ‘ˆëÈí
ŒáCD³,5niU9[½>j¿Å#7WJ$,WˆELåÑ,¦åßÀ#~iêğ‹ ™k0/aKäF)TéZª›ÊKHZm1qÍ+!5âásPèŠ|u5iîÙ]¤?# -YÇ&²É$2éÍ^uûğda½˜f~¥"E^ç¢ ˆ†½ÄKf1—°É{8el·oİTY"õÃÿ'§=º™SúdRÂ°4C¿‘¾:<ê¿9İã+^¼‘êëyÒ4‚aiV <ğUò”9’%½hìıäOğèCj¾_ÿí×ÿ«4Ï#T q”ºÕñÃMÃ“ªx(’VkUÖñV›UáĞØ`:·—)<æÖ¿È3 ’8qêb¤Êœ*Ğ­Š UsªÒÉ—}2ô©ª- $W†#µYËTT1QÒ@\û&Km\Éˆ “aÅRÄµÌ+¾ ÕMmHF^ÑRbœãWïüÁû©å >Øšhéâ¾©Ÿ«ù¸ÄŒ›·÷O:İÃöÉŞwMqNøÏä0¯±¼ÅØM3¢Î\kViĞ¾Ö½MDûÂ¡ÚlŠ%ëR…¥hMqÇÒVòòE“ÜáÁ8~^aÉÑP‚ßVm³¶i[0‡Înÿô¹[w¦V#|`»şyàAß7ëGSò—İo™è,ã½OŸêC0§ÕLÂí>­ÂÿétÒ~û,}»fŸÏ¬ºKê¿÷"ØÆ/Ÿi¡›esŸJë¦˜·Ğ>d³˜6{¢ÑøJEm¦€Š³™PÁ­Š|°Ò“cÄ=PO¹ )ãÒÎIîjhHÃ±ÔãZÛ¤·‰9…¼Ükö_ ˜^MJİBE`ÆÌÚZAmˆrdõø)ö?t™k«M^ÖƒØÒ	¹S-_NÃã[äãé™Å4ièŸ×†D€ˆkŞç_ûC|‡W£PÃ»´¬ş z6	8óE´^sîù}O'ê9÷×Æ¸NéòÍÄzŒÅ^À†±ê×óB97ÒÀ•­‡N¡‚[èÜÜ×¯wgFß%qVì"Î¨ZÎ¢K_-?UÀ¦Â'l4Ğî#tì'év2Ò³_x³Qâà#Š§^¼ËŸ|¡‘ê¼ä]g	¯½9ûß×YDäo(-$™1¥˜Üü°’¢bÃ^©J#Tn	‘- Ô®ØàÒ.U	³šë íiÈÆ…J]a£¤µë€ÔDO†˜Z–ˆZûQ«`ò³I/	§Sd3Âh‹ßS{§´+VXÁp¦ó—öwmîÓåVÒdªvQ€ ™¡ jÜv.†¹G¥65±¢JÑlªv4©Y3©Q:e)±ıiìˆ»>Ş¢š!ÎÄœâ±¬’ñ´µV‡ÿqYã¹Œ6³^Š¿Lçêıö÷ÛB¦Ìªs²Ák†Ø¡ÊL‘<²t•ifMğjJNdÏ™$€)R8"ácæçñ¿ûC[’Ì9 yÚG]ÈÛ—¤tÛÄwŠ4•<ˆ£nFi^åY2ŠsÃ<O¢.¨–m0\"üğA¾|!™dõJ°£Õlí±òv¿—¡æ`ø5#h)Nš^2l4»;;èœ­.$Ò,·‹ $›İË²É;€µ:*û{/{ò|D¨½o¸ÿq*	Yb ã-ˆ,–j0€p"êÿØO¢0&¯ºcş¤ÁÌÚ–q}m˜½U1øGŸ uÍ»|ÁN{>sMém©A*sã õ&ÅJFƒªl–Óî~K7ŸUx_ÉE3ÅMÌÒ8•·%²ƒª…™ÙGÄ†ı½WÃ^§£×mt@ğÆ#Xµ:
ş$&®9	ûG…PÖaZøKşèç¤Õ«64æ°ÖƒöaûM§Ûu°«UüV|A›p™şĞrãşæb‹úr_%[`²¹E7M­óÄªßkÜ¦µ:¿ÛH`©¸¼¦İZêË&èŸrzo¥(ÚæëØò‹–oüDW¢F¹!ñE—ã‰™ ¤™ (ypA¶„ˆ.?@şƒhfŸ¸UÁù¡LØ¯ÈVºıN»×©×!˜äÄÚk´5µWPl~PPÎ=™%£â,¥#jut´hA:³»i""€‚QUŠÊ¬3¥›?×,Ñ7sK½—»fJŠâªê/M*g8ğßó×j¿% „4sà§õq8Dp(5Àë!,e˜Á6w€§¦ç']™B¯äÅÆËëm™ŠG—ª¶ÎAP`a#Lf¯Ùá·z	Æ#_xÁ£Æ‰ôkaYÕ¢ šH	(S‡$9•/¤|‘÷eô¦sÂoú^£À!zhˆáÉkK;/\Ğ^´ÖİÁ¤GWá}A†y²d¹ËEyªdÕëÉ(ÑŒ¬ÃaY8ÚÍÂ¢`2ÛoÈ9Ëgusc|±%£5/šÚ§Ç‘í+ˆƒévv—k >EÓÙh„3Âe,,¿òQ½×Ìj²”·<Ùóıx)²˜Æ(sÈ‰'O°j÷ª`Œô°Eca]F‹2IÏmëP¯Ò»5ê6­'ÖûØ.`Ù·'ÉI\š×ç™ëŸìñş¶J"m9j¥nb±%ÜàñUqBÛ‹šÇíùÀÈ›¬¹•Ö–®µVX­Q«b£/>R[LÚla¨ç±¾ÙÄş˜‰K/4†&^ˆ†—ñZJ¦_*Ìá.ÓQA\¨N¿œ=h¿ÙC™¤}Üß;ÜíüµµÉÊM.ü¤,Ä»;8^iFÆuŒ±›üú(Ñj„ÒÍÔ4‡òó¦h[…£WŒáy’+?°'í®ÑsU7ÈÙ	d¿W¢¹˜],İÿdÆ[S€3^iÂ&»f—46¤˜¡mŞ 5Y¹G6¨Ü|©Q!4¼„nA‡ÁèÇƒşÁ´—oÔdëğÎÑ~Í¦É†CÑ¤¿ï¹!×<¦Ï&?S#±}3ï3ãhËÍ‡òp÷Ûå(:£)¶P«wİ0¶Ìe7“ ËÚ6Psµ8ëæİT¡ºR2j¤8½¹=(}¯ßãæ&ì±•BšLÍ9¶ÖLÉ–ùI:Û˜&Ë–
¯Ş)(¦Ùİƒ%x)™Ñµƒ‰r²İ×Ê—ûµºÊz{oöO€{q%-òá;ãmMGo¾ É}Éæ¹«`˜2¾"=ã¤6	m•ÎYÁËlfe:­@
ªy½Yİæ±ÇáŠk$ÒÿH  è9)úÔõº5ÕšµG®-‘R‹a8ßá¨v†—#¿”D ­%†1éİğ]¥/Êãè„5˜OkÉ0ü-·8Ñ_nh´AĞ©“ŠNÅœ;7ÛŠ,Û’>JiÓè‚à/Ùg©H¢±H$ÈÁÎ¹óûóy€Ò+¥KÃÁ;¥8úşÌj°=ævƒ ŞÍQˆßSß¾¤"uÃ½s¦¡ß`Ó›W~<òQÒ¿ö‚ä¡:áU×™+ºUP\€@<Â¦®Èƒ±p¨ŠË$GtáÙJD´cá‚Ñ»–Åtë´œ8~—šÓ[BËLİi®´ÙJMÜ˜æûv»öÍïñ±¯WXÏG£aÊŞ5µ´½/ßÇï¡[ÄĞ×¸ÌY{rß›Î‰[˜bÄù÷x—¿¬«/O÷öÂlaÁş`œq³xñ§µİô1NHÎ±KpøÖ\r77Óı`QFZ¶(±½÷“>¿ E½loú¾OÈ/h‰´`´„˜x°w¨XÚvâêAC’[ÈŞ³1í™•±û!™Ó»Ğ\š×©Q?R.Ëb›V÷XŞ–7@İ#?Î+Øª²U.•9V>~+âÌ´òÑºlÈ‚£óªe.N4s2¤¢€jó"&0à¢r|Òáá~ftãVıÈĞ~-ìÜüü&I^tÏcQ˜&Îkãİ©ÁJ%3U/‚’¼¸g†"·ëO½ ›‘™ò–Ôzœ¹*~êê¿46©­u—ã#¿àø¥ÒTÙé¥¦{ÂµGÚEÀñŞZmx„îıÒzËbÇyYG“Ñy¬“&Ìó,#ò¥—eÉ`äz˜“xDˆÖY„€÷Šü[ĞmU}Ê,+^”Y¢øY¶ŒY?³iŒ VÙ½ğÛ˜˜ë‰võù,ıÊªİÂn.ÌW*MÆ”åÀ3íápH‹9	™Œùˆ'F0ñ:è2Ë88.­0ú]TvrÈJ_¬1İ|Š›ÿùÃ~D¯HFxVC¤×©¡1Íº_ÙòZ¬ôÍÃ*‹ı‡t¾g>z£Ñ#aHğìŒ<•¥Ü¬5Oø¹¥fõ%¶ ¼Ãß¬¬ò–/*¾òGRE‰‚0b˜,ˆcÓáYX¦ˆª\–CË1¼¼±šÚÀ£4`³<X_‚øu4c÷(I0kjTZÎÔÈÒˆâëá‚d½Z×&|‰®³44…ÿ†Æ‡Á¼÷aÎ?y‚Äd½å\ w¡bL+Çí]Ê˜İË…×,öGâ†Æ!ÅÄÀ`€{äàĞß—@[B(â(á€`@±H(\Ab$Ì1!e ù[AµRİ§Ù.0˜Ê²2*Ö"Ò›oô_©P¥ø¦6¬Fğ‘AÈ,}dğë?ò½…?ZdC¢ö±—ÀšÂĞ{şĞÅ‰ ,Šï'`x†'c7^“ó=¶†vä“. ¿Õßìof\¸Ò®.™›•¡9ic¸$,Šn×–íL[nÙ˜my>UµkÕÏÅóÎsZµó²‰môG†û0W•ßÙØ™áB§^§X‹yDûWÎÄÃæg§Ø8n('÷‡T’Df|?Évgµ¾øÄM`ÅŠ$!Dº%YÓ«%§áÛ[ê¶QB˜´§Ó±…’ØİarMgP
F— jHK“İIğ_qhÒRé%Š×ô¢-º@Nw«*°wÙÛ%»¢€0ÒF¶½û2	O‡ş•C$>Îâ~x)YSkß£ë‰ˆ.­|ËËÈl†QåFWí-$ÍXv%3˜—º·»´´‚JwcÂIÍğğB'î„¾< ¿ó_^DéÃoo”ş²`F(Ãv¦­˜ßûKˆ’Ya«`·àÊKb÷+]æTr•¸ÖKQ}S²÷¬`CâVI·áí…[Û}0ë‚Íyÿ./dà¢PJo)©3W²â+ljV¹Nõ…Ù!˜Ö“©i‘e«™ìvœÏ±{˜qøD´ƒû-Í\Ëb÷¯é7ôR_şX7YEı`:ãÍÇ=¯;9÷/kî ¼S³>ı›îb“ÍÓ#—]WŒÏHÃŸ,ßT	m¨“©íéazSyÇû{¯öNúíW'PFÿàh·Gğ²<Ú‹lÏüp-¶ÔXåßàd…lD¯Ø,%íğ&ojÔ¸9oY9<÷s$>o!…ÔaZV2C)’#¦DtäîµVÊ—ÛØ&…›v¶İlêÑGƒKFNvÌítÜ¨şr#ñÈ0¡g‡¨»+ø	;6a¡œÑÚ´‹¬CexQà¡±;;@£w”·xúædß²,Œ8kvEqŞŒ¹=Ävbè8	…ªtÎF–ÙÆœ‚]ËºAæ¶yæué"9ãä•K˜ÛEl{È§;â¿Õ&	õi#ÿ³ÄÿyòèQş~ßÎÅÿÙÜ^á¿­ğßn‹ÿVïg`Eqãä(7±¤x5›‹gÒLíúúºv\y!·'ƒìµó¨>„³D½‡aª¼¶*ÁWŠ²ÃIÚVUÔ /úB¨pùL^i¥íYß`JE0˜!‚­ÅóxßÑÁq·s¼ÿ7Šä/QE…ûßuw{oéë+üN’2æ,LQåĞ¸
ã3EßuÍş¦
‡R4ï«7ĞT˜"X¡9ë’¿tEi{•A–ùmıÄZ-V}À~ĞìHµaœƒKuªßã…,¶ÕªÈÎ¡‰ØŒë ÎgÕ×¬hH™ş|ùÕ[å¨Õo_Ï#ë™Ãÿ©€w>¬É(şÂøŸÍÆ“íÇ9üÏGÿ_ñÿ;ãnÙğ?OŞù”5¥ô%1@­;‰±c\¡”ÒYüeB¾¥º ‚"¡5.£œÄ5<¤‡T‰4 Y ¼öĞõT@ÑßÈsbÏë|„]Qœ|ÅL¬(auÌñğèdï5z©îb_¥Ñœ„IpqSE¤ôG©Z<LVQ{µ”t †äşê“é,ù?S5†»á(IY¨£5ûîÒSî¶÷şÎvXûàå^çğ¤Ã'Ë‘§8^%«£Ÿót?B2‹ûL3+£Ûıu÷M·}ÒFßƒ^KßûLÄËäÌB´—®cU¸´D2/¿ïì¿Â±Àğy0Í<¦ß'“²­“&ÊîYr–‡×~Dª»Ş$ğGìh+=ˆ<tJşÉ£”Î†Ã[ÀU½ãcªû,y `×şDÉğÁ)AE±ÆãÚæ6Û?éå^<Í¾àwÂ@îğÒú”J‡&È! a¯»G@$‡»-÷r‚«òµpÿÇ› IO¨ñT\ÖiO- W­M=‹
f¿Lùß¢ê×™ù<‡ë·v1¬é)lè{”
$¬ŸÖÔXä‘‹ µ È}K$9{ßÃºü0¼D¡,ª"x¼A±O´ÖĞ&.™§Oü¤6˜yµÙÅ8Ñ9Mªl5šOtŠ^Ü3 ÃÉ·¨aÖÀ¥T²»ú  à&~Ü¤ºÒÊŸs·©ñI}¦Ğıeó\½ÉxTµ¢ÆÓs=×íÚ"íº'§£•ûI4îÃÓÇıÇÛ¹¶‘oÌ]3+Ÿ¨yE€Pnõz\kÔ®“qÓ™;¦=}0›O]EªycöĞLæeŞ0©m"IíVÙ­µæL¶Æ{² ÎeÃ)DİÑ@w6æ•E,PÙ˜îÌ³ÙgÅşT7?İ™g˜¹y&ü–:¶ÑOn³*kßÉ˜Û›u™³Ïíf“ú9ß#a~çª‹:G}¨ò¥Sµú¨D²Ù~EÌ™õ(Hõ0{4g(ud€”7\É»Ù91†ÇS=ãÍEV e¢Øo‘âP^pªéğí™Ëˆ–‰¨`¦ëïívdª9ğè1—” ãÃƒ÷ÕX¨bñ†æãeávÓƒıÉ(Qkå®ErÚqşèt)«bQtE…p<õ¾ŞØ4%À Ñâ|_:‡§ı½“Î‘Ş.gÕ½)ŞU‘qB¬U‘ö}ÿS«XØv­AÜÇ|..[küõš£9T#IZ|`·ÖüÀxÑ§[UÖÀÒUMüİš£ùš§ô%Â ×¼)FFFÒ:â¢K?á ãÇuşQRECêlŸª²çêÚ‡Ÿ\G÷5‡­ã¶Ys±¨5Â(1Ù	©ÆÓuºö>•*x¿^O-ò½‘*Lx“§%yŠ(KTœÏ8Q,˜1ê)ít/rC—Í‰˜V‰Ø ÎI7OØÏg_·\VÀMoÃÍœõúY­ŞÿÄÊœá=¢’œÉ$ÄpOkµ5ºë?dá9ü<ƒßçÙ”8â%õÊÇ`©&uìØ>Ú¨^Mj‘ïO=È3¢A…GuÑÔzâ]ÆõlsaÆ³Q,SompqiHÏ·H	A lšÒ¨y{Úïä7…‘¥ñ ©?hôŸbŠKIj&±DœL*	¿P	ÚÓå,9i[’0µ²{ÔëõÛİu\Ğ¥5
µÄ-ªñ"¾È[yöêøTÊOha}¤¤)éLDRuHGîÁ7¯]ŒV°Ö£ñÕÏeòôxÜí¼ŞûkÏ³kNYk¦·6né¶q ­¥ÚWĞw¾gD³j•ïØ°OµĞ_j8¬NùµñbL)©÷Ï£`x	œ3¹˜ŠGüI‹ª¦ï	 1 ™á¦Êov«.×¶£"]ÂZæ¶æŞW“ÅÏ4p§Îöbpá¢(B½Ğ¯?T/#EÚ÷şı&ånçMç¯ì»vw¹GÏq¾ïö±ÂÅ'†:ÅäÆXæÄeˆõ|4pÜ{4ÜWØZ‚óFuè_¼w~™¼f¥~ÁÁc|8Ÿ]h^…MùÖÈeØHß~HâD~÷’÷Ú›Ëwƒª¬	÷ËÑ,ÙJ¿Ñs×Iah[îØŸÌ¡Å³ó+®@fcï½Ïøô‚D½CPÍ0›D^Ää‘KîŞğœ]Â?ŠV	5ğ`xØH™q8w¦ wÉëÙ…§L(9Lø÷ºHŸƒìÅĞ‡ÒDƒ¬Á&á¤ŠıuEaUôì¸§I¿}ûƒãÚ0Ù-]”şÅ\%óÒnôs²$ö}{Nö¥(–Ãfª$€İN¶5/ÛÅÃ÷4y8Ş¡^äß±PFˆùö½ó º]ûS}ùH"ˆÕŸjIP&.P3i+×;=F2`ßt ™İŞ½h‹EÙwë"ß+Ín.ê¢.5-Ø³×¾à¦-¥3É*øÿ³ŠuhTûMSjNÒóZ]Ñt¡ØŠˆÛç‘7ó
ğıàpü-”úr…Ù•¾ü]˜¿„Ãí«â·š±}ËYJœe¥¾ ²Êo¹ù¶gƒ…¬=]Ë¾ÚÎ×hÜƒïBüÂ!w´İ®m£pÃd7'ÙÔÚùN²hÓÓë;rª)"²˜¿6ñ u®DPgÂc¯#­nnÒÍüõÆÃÇÛğ¸ºö¶èÌDŞ?¸A÷16ÍvµÑ§üÈ†AŠXû]Zƒ6â¼5Í´5kÈİ«¿Ç$2	/„í(×¾Àšç3ßLïÃ3~…cš=œ%!üË>Kï®Şz„-ÿz×ÓÅçnçÓÛpšyÅ+H3ŸbÔfõö™¼BJ˜õ¦UÌıHd|ºVC·ì¡4ìüø—ÿµäûÄ›­›ÌÖ˜«£;›(H4Æ×y¿üûâê4ó›¢úNBöã,N”i/U{!-2Ù:á„á}:B6@:)fyW^0Â{rÌ "ØÆâÖiĞü‘†Öğ;®à¨QK–ÏMŠjé’•’Ğ£ÂQ /W!©f&.ÎëtB¥ããùl}qëq- ÃF¡Ât4>ûÁâ3‹€ŒŒÙ_+Ï2k%Û–[yÚÂ³o©åøÍQïDK-ŒºÔëÃÓƒ—nv±ÆÚ6ÁÒÌµd	»1Ø+6kÇµ†¬ïEÇ&g“´/‡a‚u¨ºy×ùöòFn y‹ùâj×E¥Áç³˜¬H¦*:ÅC£’ f
Ÿ&·#DHs‰Â3üJö/ÿÎö.0†¢¡æ!Úm`¥úr'ãnÙ3ØÚÿş_Öş-¿òö¿[Wö_+û¯ö_w6 ÓHın6`Ü´?0<ÖàÏdbLVE_ÄŞ—_`‰›W8EŸîÓu4‹6ç½üXøîŸ³\áÁ'Çár«Ä-·e«#
z8©Æh¼LÃ*o™F(ïekÀ€ahîWı!^ê.›—°\ı'*tÊ}ã¨ÔKq­ÇÑ1B3øR™ô§`Ú2AG…‡NÙQÉ>‘Şş¼È±wúLª€ 5HhVŞdê)éK¥rƒdîœ iSÎñœ+oÑS£åv;‹wÏÑ3af¿«ßÊr>!T,¤6×;ŠY[mè~œÂwDı¡6ÏC´:O{ş6[ˆ	ÜäVô¬–ˆØôÈ¢V«13­pàeÕèÊ|£a‹’Ed“C1‘›Öëè)õáÑ=½„;}t·Ö+sÏDÍÃ9«²Å‚Ä$JËØŒX2N®|/b^]`£\‹ï¢Åî‹¼ãd°[›Òá.PLœQñæŞÉx6Q7Sâ|ï÷É`].ïTZ££ã	(tmäl.¯NyVTÈ³ŠÄWĞÚO~ÁîñqKÇ,E}ªO§ƒˆŠ	ÔÏ)y(Õ†‡mª›ú|ÃAs4aÕø"ï-š‰{ÂÌ2X™l.¤‘Ä6…‘Oa	vœ1K+2ö†_»Şİ¢‚†-;ğjoO'ĞÎG¾	{4)YâÍ€v%¾8¢’Ùƒ˜;B(â§Mô¼æ+SzÖ•ÊÄÚÉ…c\Ó"=ĞëoZ®
1§±nñ|ò/˜´3¹Á\Øã%³«å©°Â0QØ&`=¹Ã›	TŒŠÎ0@ĞoñäÄ·Çø)ÊÉº j~â™€t©ÿM{€PüHÙPµúSéhƒzÁE„uÏ‚˜Ù‚„ªBqV([Ï\æå±È'ò‡İÚÃHŞ¯ÿgè°C|Dn½‘· ¾6“ğĞ54ğ¨‚2‰±]Ø9·á«¯Ò Ì°Ç¾øº©~°(<=¦gQÁºÓƒ²:UâB¢wÊ…=à0Š
AÆÆM:°W!lªªsîpÇğáj>mŞüy'ØÅr”ã…ä8°é6)‡NVdÓ¥hç>òıÃ ¡ê¾‰Å>ˆ÷Ã˜1’Ì½UEmÑ?æ÷eáèI*äm<òWM•JJ9};6 ‡Ôï<ÛA¶¸‡il*bXàu~ª¶ß¹“,İ³%ÚCÎo}Gõï›(]/İ(ixvã³ŒtÁÜ%ÍŸxƒTK%î¸W,‹±Ê¸…sÉıœÀĞ"›—îCîg¨ÖY&òpŠC+IGq©ôôàgé˜ˆà\ëâÆX:lh(³h6Ôø˜Ã©7ÏÇÑWÈI·íÇ°?üü³üõ$m \›– ­l'ÉuK$âŠ=Cê)‰ÈÁT	EÎˆË*MVÙf•ÇÙpE¼;fbì
s$GoàMı¸—DhwUÖŠô"R^ÌF¤˜MğT›x
 t!FB~äˆˆÜÛÓ@¡À–"(•Š{º(äÔ_š¾6"ÃÎ®Ò6SM
õ€D"û“9õ	ÌlƒëÚY×%&dÒ¸4nYòb™&s½{‘$
—¨£ØOM£L£dë©ál=ÍâÅ˜í´5@ÃQÉòR+3-ä¦Vv*xvcÇeÄì-’,—‹N6s°mŠWí„)ÑåŒ±2»"ßˆLâ«’ 4‹`'dÑ´D°q?k/T'øÓİÇìÖ”—Aí²àk”föEÎt™+F|m/—èˆ…§¹ü¢BËª15mŞ‰ü]:‰V¿ªüéÏCoâ_"„Ğ•7F	LST{ùÊ ïÈ)†’Ê·È•ÚzU{FAR•/ÄÜ–ç±x	M|’	2|`2b%åïM ÑÀQ$XÄWš¬˜+‹‹Û±Êõcoàüôÿµú0ÄõÏZÇüüdîÇbV÷?_jş 	àW³im<ü2ø›[0ß™ù´¯W÷_âşÏ2èáÔ;Îóé§„·eÏıñmÄï×á]K38O.ªäú6 í0RÍ[WîYò®~ƒ”ùl@À\ì¹ÇŞEşEjL‡ª;,³„î‹ñãyİ{QcÌYĞ"o0ğ§IÌbzbÒ´ãy&›‰§}ÈÎg	?xÃ)wrù¢Z}^_QàöåjÎó:ŒˆÓù@æX¢¡R¸ˆÂ1{`mÕ§Õj‰••œ„,˜gôLµòL#ÿE	¯gYA¯1Áòeç¬ƒˆº‰ªû9ˆH/ğs6]¢Ò¢Ä2%}ıĞ@£oix‘Ï-†cN3Äœx!”µcmSZ´¼¡UuÍç'Âı±öB*:¨$=»ÏQÔŞ€ÌU¥
Jò8n‘2º¡v–ÒŒ(êš4‚æ8w˜­“¿ßô”ìó"2Ø†éF'] ì7Ø	qæöO«ÏÇÿ€Ò?ßàòÿ“­í•üÿ…ç_gy_rş·6·²òÿöVc…ÿöeæÿÌEÉoŠnŒ¨¬60k'ß˜‚ûSæ¢YkÏ.Yã©ËUª	iG–©Ætcpé»N­÷;ltÓT÷L%MÂÌfNYz{‡GÇ½½c¶æ<r4DÌşöìâ%¿)<»èş@?ñgcæd€m‰¬ix¹”&“q£Nß´…Y•n]µê¬zÆeÎü®4§¢²ñXSGÏÉº›ºc·Ûé½êîQcãhGg5´ÍC{Lxtë‡£à=ÈÇ'q.¹tŒg²¬uóCeôÈO<X†”Æ0m*ŒQUuƒ$¥ò†eß“;,5TŒ¯“/&ô¹LHÿ×”XŒ¾“JÆJ*9´Hwƒ É±3Èc¥ù6ız^1¸Œª"cz²“ÀÇz2cÊ0m†‡Ïç™œPÈõ—œ”«Ô÷ó„ÙQ ³4`ÜC›I¡bäøùç·"ÁL6IŠ©ØÙ5Wñ·Ù—ÏQD¥§ÂTŸº&ôm‹Õb¡_]ÆB_5_rì4æÏ°Ö†„â(x“F¸=â¾?³D×yãhÎ&	ób¥Êİà­‡xo ‚gÖµ.l¶XSš­ù¨cğ°çìqÓc-´ÙÈ›¡×`”6/ƒ<ê&¥«}†¾ÌYŒàÂ7phæ…BÄbŒyNøj;=ùæ¨ëd¡ùÖ‡ô öÿò.LÆp.Bh¡guøo%ÿFĞÊ@{ßŸòw	ıï£FÿwûÑ“G+ùïËèå¦	[M8f"ÎÙÖòz ÙPáŞz,!!B€Ø0ÇC¹Å9/= %v"Ò‘” 2¾7éK¹İ}üÌ)=Gğ²ô|¼x5ÂÍ´Ã¦Ğk\Á#D—g˜’ô4¨A‡æáÚ–œ*YCKã¬Or>Â$­§·š: lÚ‹ßX j«¹ï"¶^OF¡7dióï¡­­Îo1ì}„	õâ~ËÃpq¡0j¼SÏë0WbÊŞ„HvûEˆzê£©?Aò£1†gåÚŞÙ„³jnšÒK”ô¼³„N^Ñ˜"ÁÛëàmzğl?«¾9¯nÓŸóŞ5í‹*û½UéóÚwŸºò¹õˆj¤8ËU¹÷¨æı=”àËlUl©ô…®Òıb¡Ö»ˆöRtwÅyı§•ÿd,`8høñıJå¿íG[[9ıßöêşÿ÷¸ÿïr:`èÛÄ¿`‚ğ¼B	tÒıù5»ğ½„üaqK9Ÿ„‡x15Ç¹"Ç\V…¯üñ9ÔĞ|ü‘k.[òaçûÁygj™Ë¥wKaµõõÛ&8X	ãÀ¦†pBÈ2Œc«ê/¤~Š 1v€öîÃÙ€¨sJ:bÏØCÍÙzy“xêE¨TP&‡¨fEŒ­x6™79ˆë±û0¼6'cí`H"u÷Ø>>©£/LÊVGáà=#÷½$îtÂ%8„¢è4(³¾BŸ'ŒÈ:à‘Î¢LböòFƒõ´ÆÇ7ş4¦-) ’<Õóu9>èlÂÃ®{ Áš8tr©{ Af$ ½”×3Ú¦øÎ¥mE¤¾Ô¢Úğ²kzV9F‚/N‡(­ò‡'Œ	ìC_E
tşN¥/Éß‰e’×{íìĞ)ÅÔ C*Z9ÉÀ ß..¹TL;²xŒs‘£×Á :éÍŒ‚äÆ‰ƒÓ¤áé“–H Ôƒ’˜iI6aIvğ_ÏŸ&|a>-Z—ó:¬-¾Óî¾>`¹êÚ³KÜMºÃúG
…Rj›EKxÛ [C­+!ÅYó©-÷h¥ıœq|x=Õß0håcˆç‰;Í¯Ñ†IIìiiá4]¥F:V§%“ÉC-M"©ïR$i,nAƒ ZbÅCƒº`0±:Xt“÷œŒøj€‘ğåïüŒ6´½ó„B1ëÔŠ½}|F^+45¨‰’2G·ÏgNŠÄX,‘ ¯ÔÅ|ß.ÔfÉ§^SÁo"^íï±ä{—~œİ¸à¬İGğñd@w0éÙ¬«ÎfEß$p´iœõ‰¶Í³Æ¾áT:Kù÷Xôç+-lÂx7¬±©QÂÒ¤pÊ]2¨!C˜²Mùe›Á ‚©1^²ƒÛA>néN¾‘Á‡‹½Ãxÿ=¨}_@ñv ¢á%†o'”ÃhlÔòŸç0Şÿß·Ô¿¼üÿd;{ÿßl>^Åÿü"Ÿ¾œÇÓı]ÜZolğ‡´²QŒ‡]’åóäÿ7ÄWi°LF–©ÿÁÇyğ Íàr©„ m€©˜0¯çæ˜È2¸J3³¤áÁâŠ2Ñç½ß*É®_çù!}#ncÓW·*÷·åVwğ¶†)-_á+¹›©[üÑ
Ñu–¶J]“-^Èç»™_Í8©J›cñ¹O‹‰ŒÉmé¿ÅhBvB\ßg:`#Òâ¹eÌ0²ø>3N‚”/ƒ"ÑÓØgÌ-(CNË 1hPF15ç(*ÀB›²ÀÈ£¨$ó4s,?˜ Ô\¼¢¨¤š·Ğ>„m,Ãdä¶ÙÍJl†âZÏµ1Îèˆ…©I^8Óeb>–¶(sÛ}g«f"KyÙy,@iÉ"û(2¦cp+£–Lá‹m\¬$ÛÒãCW4àv0E=™Ÿ»°ÿÒLÆN®h8“å¨ˆÏtˆkøoi]#Ìk„}Í"¡{ÊWü·pÆŞDT§7@İhO<ığßÏœşÍ’õkOØÈ¢F@¼µFİdÎrò}Âˆ8ôq•¼_Òÿo;«ÿÔÜn®äÿ/£ÿ?Jh!ĞÔÃû¯3?¢@õ1+ËCüy„·ˆKdÈGjŒqóû>_áh^ãé8‚ÒQğ(†.ïXr3õ[î«Œş–¨´Ø:‰
™dÅ‰?Äez/æç£ğ\Ø:Ô»öîAÈŞUúcşHÓ£)¡ƒ^ƒ Š¸Iá6ô«¼ê–V˜­“ÏTF52×píG‰ ¹/½úÏ™È®VŒ,DY Rµõ;Ş#ÑjT‘HËšuÒM¢róÇáûêÓ*üŸ‚½„%5¿üG&m£a$6êG•Ú1W©õ¸è’¹˜T‰¿ü;ûåF±§¤rMbd"„,í*†${ûŞwÆ£È@MÈÈ.¶~{¡oÄÜi’º×^hnTÚKÖbc«ÃbàÄS˜?1Ëé¶%pd•ğërv×à½©&1km“ÇU‰>«(„6 õ§'tkxWTÔSš,EHµÄhÓNË»(Mß#`šø+CUœêFÍúã¤æhH¸¹hĞ¥úÃ¢BNH	Y”Zßßæ|ƒÂyjb¦ˆÄŸ7‡§u± ›©â¹K7õ„bG‡6:ø¢;™İ´7ãÆt'±@U4ØÌ"˜Y=‚ŒSçBcaäœŸ•™ø>«Cú:Ì´ù×‡Õ†uX=ô•:/M²‚|U0Ä«Û1™«¶z“7ÍÒ
ŠÆK4Änbµ2’]}VŸÕgõY}VŸÕgõY}VŸÕgõY}VŸÕgõY}VŸÕgõY}VŸÕgõY}VŸÕgõY}VŸÕgõùş?ÿTl  