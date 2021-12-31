#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2429533479"
MD5="fcfba6319f75f8daeb5c1190ef7b8892"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25688"
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
	echo Uncompressed size: 188 KB
	echo Compression: xz
	echo Date of packaging: Fri Dec 31 00:24:29 -03 2021
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
	echo OLDUSIZE=188
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
	MS_Printf "About to extract 188 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 188; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (188 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌâÿd] ¼}•À1Dd]‡Á›PætİDõ#ãäÎx¾)aØ<)}ÜQ•Àà/¶eV‡é¨YNôäéÆ~…’¥Z¹EDDr%O1€"±5T5ÿ×òìÇès$ÀK;Cà{\7BØœ·–ú(Õ~Gn1_[Ğ…¢o@€Dô¾İœFœŒÚ™fùŠe&xÊİDymÇ@k8şu½Ğæò.ëŒvº‘LN¹ĞÀ^®¼×ÓÅÎ>|æwDÕHv†æ9³$LÈf®¤é¾C0PÅó[¢a³£çú>Ìaïß)-¦ñ} ] bv±Úÿ­_åÖ…";,tÎ¨YQ Ü?•hÿEƒ^T>M÷:ñ9TcºÅˆ85äLJÎ1uˆºvŸïëQ••Êêè >6Ã”öœX'.ydQõNÍÃr¤4/°Ã…T]£r³‚«ÔçÍĞ@úšf"ÌFUMr
nxtÌJÄA™™(¦æºNÙ\™ V›£ìPÜÙ}éŸŠ‹Zp4t9vS@|,/EøÖ/DÓØL)8e<†~O+Ÿ—×´‰ã'—2]—±›ï=œDŠ•½‚Á†Êµ¬„š¨¼­^}‡jù„o4©3p-*Qò`‚×#5LÖúë¦/¼ùVŠ0éİYê`ß©7u˜‡Àôä‰Âğß…æ$Â¨œFí:ëE!'RbÿúG.4+
¡Q‰ó—8h¨Y™øeG5@ÿG{	N¼„Ì¥.c'…ê÷S’ñà‚¼±k‘»¨¦„“Vƒí­Ø½ÔüïÜóß÷?=¿i"À†F¾É¿õ.O>¾·ó²tœ"è¶sˆìüh­}ÔÖï<vé>¼|Ø ¨ıîÇÈmªÒğ”ÿÆ–O{*™ùl>–	†fÍQ¼ƒ<ÅœÔ@™›!n|£·¢¼&Uüï.,FçÈ$vÄƒ¾ÅX.¦~ØÊt/Ê›PleäA'Ğ¹¶’~HU›%eÇ&(Jœè*”Jîâš²ÃKÊ‹"`ÛÊGıõt¹:	0H±	K£,³Ñ±÷kø0¨KÒt—æM&·UîÙx•ìTÚ
ıñGí@.¡zéLXÆ¹º×šc4ú#XU²bµÂûŠº.ú¦®¹ô8³xøL’ä
ÿ×Ï…ê½Åçyú÷¢µÜ{/oóƒh­ÌgYq¢
,Å‰p­ì_P°±¦ka$ü‚óef4¬T¹MŠnK°;<hõ»Bq/jşáŞô;ë¹=2Uˆ±¸lQyQÂ ésmÖå\Áq÷ĞØÂ!¿¶ĞÑ?õÕºx|­> Î	è¢Ø¢ÄEÃèW±Ìªï,¨Êºªmt Êc}©ı0®X²•O®wl›qnsLJ=È<8¨Ô^RêÎ>Ë"Â§XLúeöNÍà²W‚l±FNtGmŒ7Vó²4z@bt¬Ôç¹Œ³¥^á´ö/sfF¦²¤¬xë…üùi„KÀuÖsBé H™S‰ÉÖº²„oàßI3®
°S×ò¦‚ÿÅˆ&}šÑA©"]?ìÔ:
°úÀíİFüø:•‰iÜ¤dÉ7Bèºò#DFnó=PteæÀuK{88²ÀÙÿ)‡HóK X‚x&•ø®oYÕü†Ñj½‡ŸÁ{àZlş×‚Dn.oÿt‡¾Õc6Úš~cY X&äí )FÈµï¢Y¢QÆl¯Ï¨¬ÆügÇ–´ å³ S>Ğ¯ÎWé»HÓ•T/ÒÓ‹2h‡CnB‡l<äü,o 8Êô$ÛÅ¹op4ÿ7í+Ğx·õz^+r8K’Æp¾…­ûö¹‡òunñGâ95‚†ñ¿Ü(çá]­·EÍÆjˆøÂeS»÷|ğkòŒ«5(˜Í»k¬İ…€QÌçK§%o® yé+¤$A
õQ°£‚¶¯‡ÒıHå*:±$é‘‹`L¦O‡	8äY1O¶	‘
a}#’e£÷`Mwzäw,¡§‹Ò™ï­QêU+ún[œ\^MŸŞrmZC	øŠÜ ¼ùJÙYásw>¯0-=x­b¬ÈS†Â´}5=ÃÁeß¯¾Ï/ç+¦ÕÈ»î'‹q&“ı†á3IK£>ñ©?V±Ê™ h'?ru’`PæÉ¡Ş!à†|õarS{†{ëŠ&ƒ¦Ä× GÅKp¤VˆÃÍ/æÄ„Lµ}É¡g§òÈÁL—íh5œ*Æ> [¢OSxBà‡=Ißz»:O&µˆ›àBª ìáyò7sÂıœëĞØnz™œåïçmÄ¦s¬z?Ì–>—¸UĞß›qEt"—Ë}:JÕòãéJÁŠWYMÿ:Mã1äsÙÙÜS>‚±¯‚œ
2>Pù×ŸÓŠyvk>IáƒÙDÊ¼Í*Š`!·ÌøÒ0Åİ–Gm¾M41¹D³—®xÎj´Î4«SÚÀU.RÄí·R+{FëàÛpVõ¶]êªmY‘én†i=.Á–qkZD©ÆõšÈôtpõŸés® Là=JÙ2¹]Öû5­`Dù<Ø©°¤(`³¹92ê‰_ñvåj;zyG§~.ñÃÜÉÒMˆHR4÷ô½uÔ(Œ³«¼ìÛbC8ÛMç ™6‚Wæ»‡£*õnòB:û	–HšxĞcœU»Ûbå	‚Îë7ÙCo™PpÏ#ı0FĞ¡©6"3W‘oQ1¤øVHNÇƒ;+âCbüBêßFnrÈ+ØğïT¦&!LÒªŒß_ßË+%S1|ÀPÇæªìh(ÒèZ2·Avá*RåF›Ï½ı†ê“ÊaÓİ—İw0®mmV¯5Æ(gøWn”wÅ*„ûøo5Œ:ÑAœº	Cš×«f“`ÈmÉíÂLû¦R·ĞäiGgÜøï±ùdå+ú!ÙAšdUMÀ0©Íøqì\~/Ñ¡S µY82¸£ÿËŸdÉT¿ 0Hî;«ÈQA}£BÅÉEŒ—|µmÉèhÖl¬aa‡æ†xt!úLq6ßÁvù/ÆJ¯àˆ¿fA¨şÜ†°ô­f0¢ÒjÙIH[Ÿ¸¦º?%Ô:¤1$ÿ'gÌªÜG¡áq™/$¶ç³ÖŒ'äuür8Û—¡AÓ¸Õ_ HbÁ'"b¦AºLcs_[û¯¦1jı”“o®İj+½ğ¢«kV%Pñ		l}vµŒ6Ğqaèz›!¡²ªÄ?ğrHSöÒx<€ £	¡õsh¨¿HƒÜÃˆ@ıOå9âk=sI»ºúlaÊ­_â¿I=™îÕš' ö1×¿ønúK0..Å·ûKúPÖÚóÀ4³í‘ĞïR[‡C¨¶—ãï>×:uö8çÄî¼hKØq‘S †åZÕ²¬ê`Ëü>rÌÂdõ/ƒ Â†MùÔíş§Ğm$l…4ğJ%}ùr;OÔö·\9"n¼Š±`x½´Íª9åÚÆr8 ¯ólcA]FéÆ×0„n™ña ,¬¹”úJ¸¿²İÆ96 O˜ ¶»æDléÕnì½6ëNï¦¬0•JXO¼Uµ?ì1EY¯ø»C˜«Ï‹OCÙP
Vq@ÖÒVpo9ÑÛšªÛAÍƒB%Ä¹,úªKP–3ÙÚd•:Ri ¡ÂŸ±ş6O"v7-'­Ÿ²õŸÂôc?mñA4im›sA
t÷Åi/|só«DT:dÖP„¥G Ôl•¶	Ô{¶ôW€.Û«l”áÏEåPğNøëU§ñ.‡3îm¶»g‡~,j›Ï¥Û;-0íË(Ğ^XÃ< ^62ä‘ÊsÖÃqüK	ø7LR~óç¯”ÃÚ(ÛvÙ±ˆÒmıÑ,ïûQ(èö“¦Šç£TÈ%/¡#±24„
s¨¨ˆRnFx0p<%â@Ùr…!§[é_j
DöiU®Oİˆ%o NeBz:o(=6!ag-4\|U5ØîÌîyzCÍ}ÒQåÃ=Oµ¹¤Tç¦˜ô¡J\nyW,ÈÏT_¨Ì”§Öxï¤«ä)ñ[ Q>:‘ÑÇµ'‡è¡»ä!fJ6¶
Îóvl¬İ¶N-ÉÎT!ôjÔÈÒÃ–üÚ„â-]øel‡!Ø¸:¼à×¼"sRå}õ=Ÿ‰NiÄE’èk3üÆ'Æê£³!°¤%`¬ºøZªFp‡»ÏËI¸8NÄ÷ğÙşãô—¡¬ÍcÑS”ß:BVAY"Á’Ùpù×]òÔ¬¤§ß¡‘hÅHeŒy"u[s u©=cÎÅ Wºš®ŒÔSÓ´o_ğõ…™ É<áâÂ2ºÊDçšHÔã;í¡·nœòÏA9ºê›:›P<`ì”qiP;@Ÿ¶ùäÄßú¾~iæ„t›`ğoH«š§Ê?Àø!ß£ÓÌ–@±7ZClwßU7ß³ú—G7=¾F½z 0
[¿°¶üáÍÆTK0göI:]$•ŒÀ•İfT¢¸ôaq=|S)B"²:4y½0”°9~şü­ÔŸÍ$MÙxãKÌHœÉ¦’_W†êÅFk(>	xu¯m£‘aU¸b$6uÙ*£ök°a$ØL´.oßX~PR§ùíŞøç¡üèLVº-¡áo|×Ö¿@pq”¿xqØª'qíÉ-	ÉÊ‚òJ6•Æ“×du0çfÿÒ`î©ƒÖ;RbdqËÍİz¼øyè›ËÄ]}Lô=0^ò?Iæ$»û"pWî–¬¿Ù`µ÷Úåü•Oaœ‘}\Ã€ Ãs­ÙÊ¸æw mÒâÉy“p6øúo!¾'­\_wv‹ª™†?ä§ÖêC°’6ÊÖD¢fé¨1+È\-MCª+óıœıŒ82y[°5¿$ŠaÖdTÊ-Ö\ç—?Ú!uuãV“—íĞ"á» òÒ™(RRÕ>]ö}€é¯SUíù;¤ ø”ùè@ÜÍ¢d¨I4$N,ã8zG Û„Ex;ËpT@Ô€´á(£Õ\Ñ»\ÖÏW™c›4×¯³É"®ŸC!Ô”{î˜~´1Z9 ¸8¸åhZ‡#I¹ƒ~¡%ázqBä)?âÈ“;şñÑÜÙ¢ÍYŞÚ`Ÿ›\Zã¤ïŞ9(h yĞx_ºú5FªCp®lméM&¨£wñö`~ª³™N@]ZC(UîÚï—ÂUã©6¡oròŞä¬fŠf{5YF.&-2¸7!ÿY¤,køyëq©Ò•/ƒ@m´ ì£d®t’ËùšÅ6I´˜$Ã‹—	™T…)7MŒ8¼@m	¸!™å"+á<iHl~Ó%YÌ#x.Æã’¼8Ù?.º¾Ïv¦ºç¾²z’r–§Šd‘go"«óAC$¸œ>èb.ÏDWæx<¢—V=¹\‚©-¾Ù–:™®ÁÜ»ÁPãQœ”Ü7Aˆ	%p©‘5Ë8ø½®$Ò~nDÈß>¡×›¥Ø¡¸¤o·hë/0Ğ¾4r¾ö9u¡b,öó2-í¾ÍxïƒÀ÷EßKDû“>K%å›¡Šs°€T&³õIá¶2ş½t€ä¶é.Ùõ ÈIáP,ÚhÙ(u–QSÊ¬9½Zaüİà2&b˜÷Ø\ÖKmŒ•àpÄæ[â‡,ÄŞ»øñŠ~±©öı<ncİEÈ7mdÜÆŠ‚á¥}íd)oŸˆ3Âl£?æ±¡3çg¢şsÖ9õ¡+3u¿EÉF{|ÍÜ/Y‰ûvÛÖ.êÀ9ıl-î[hF .„')zJ_¦¥ÕX£y±É£Z@_ZeS%+É»¡0'(Ãş|ô!ğ©ä•¦¶+&õâ¶kÊÖı2¼ç¼”°¥hĞ5X=ª»Ç¤kdÙES_Îš¹E>jä&.	 ­#ošØ°Óy€Iß…Y¶3†oËªXxãŸ3RéCOÆMË*–'Úf²#¡e]ö[?h2ÈĞDKEúõéÊ%à‡ÄP09W7<C‹Cî´×ä2‰4>Túo2Ç–ò(I}‹¤ú<ãÍ ©V§òèµñå°ÈÅèárnÕO¦²	èN‹G¯Ôãª·¨¶CYXõ*ªyHsRp’ñ£´å‘á*™!ÚYåƒÛ=´¨õÏÓá¿úÑ“M-¦{@,I¿åE»==9‰EUtÛ‚€3î %¨øLÛîÃj¬g$¹3·ƒÆq•¸Œ&~zoUøwN`3*óú¤œ"dáM1âVí{¨¨b·`UŒv2ß%¸YYÌìnÑı]?)åûFhKn{‘Ñ§uMJ©^ôFdŠ{…¯¨…*'†tÎeîÆg’è¡0?Ô„YXL½ük^)_wWáÓîƒ0b×àğœŒßÄZ½|‚ë"6%G7ŠÅ­\•Âı Ø£8ÒGro:ªp¬N›‡ÿ£k^H“›¥–‰ŠDºÊçœÒ„şİÏò%©…ü¶)¿c´¹çcĞCAé!
ÅTáLS’Jƒv×Ú‰3)Ù‡›èµñØ[\v…	ÛCÚš 3Hé¶±ñÄ£<m€9M7òs*¨‹}ì’´`i*&¬Ùœ×6â¿]9ã\~$ÅÂw:‚¯ÈÌ`ê¯Ä÷3»èrzm!Ò›U§½¥;ºl
‹J]òÜŠÌí£ãÅô›­à÷b¸~**…œy'1ÍÍŠÛ5ô0ä‰¼‹E&Ëo4ó‹då‚é,^kzÏHĞsèÂÍë"X¥{ù{ aç·ªaS5@‚BÄ)6?²Èåf/áû°{Aa!¹Éòä:.ûílõ
RtìBŞ/¥½
ªvEöúqïÙ,ZØ ß—}DÈze*û»€:Ë1î·o×*_FqT^¢WG*6’¤™åV'd»L›«œÚ2Ÿq£«¿‰‡%¨à¬8CıqÓm#"œéõÏ—ş›/k–¥!¹Ù6ÍmJúydtßîh ídÓà=İ' ¶¡o=Wµú9o¢ç!&*f™½Š÷e~øb\Wókwl¿j.k›ÅköŞÆp@påBÔ¨lƒÌ[’.Ñë
ú˜³Êú‘Js_Š>ùKßîlAİçƒ@˜çOÌ~ÒtÓRVš¶>&#Iî—hh úz ±
ï©C&á¬ÖO¤»Ô°Ï£UŸºw€„†¢‡”.fÖRëÕŠV¬ıßc$œÆT‘QKñí:š2u€ıoAÅñ—ÌY*¯ûŒ",ÌzÃ üp:HU¯éÛMpH®s­øp•Ø¾ù¢úûI,uØäØOlÔSHªgÑvñæáGhÜs$6âiìOÿ}Ÿãi^$t6ªÿHQéJ-$u›ò	y†OÇÔp%eB8ÎÊÄç*yŠË­_»‰«£¸»³ÆGD|&%*5%¶˜ãêÑƒ.u¸ôÜ*:ö„æ5ß˜"àH?ë‚›Õ#"û¢Öò^8o‹û@\ÍìÕ-ˆÔª¨{b³'¬äøU·(ı©
væµ—å_â¨7f9kV'Â0ÿÒ!^¨¦Î~İÆÃ¥âyö~	¸øY%+DëÂÖÅª›µŸU6i›§´û¶”àyiÒ†
Ï›ù™»q·UnÈÏ.–ó¶<ß¡cÈ§h_Ş&Ëôî\pÑÿq®åøèçR»Rù¥+$ô_™B¯òW×Kç(çêX/StÇÏBÒ¸9w¢=¾’8äZY¸ó Ÿ¢ğ¶Éa<•6¸í0Õ+à‰ÕØzulB‹´x¥ß º#ÁîXGçûêY²ôéDğ³	¤Umšî/„Å7¿„uè¼ZÉ©D:£%/ˆ8İ¥ƒ	W½7şËÙŞDÆ‰Uû-A{­çJG¦¤;¥yõGıyÙ7¢~v?/ï¿¡wğYƒÿ„oŞfF¡y¾O´m™}¬q\‡¶pÂš¹„t*ZLoFÑ2‚êFÈ§òPÅ»èÿÈõ¾!p¡H—ÅZ{K·¶‚ Ú=,›È†úR‚’9ö9Å}üİcÊ1ŠÅ3D1-xÇÑÅ`'HßÎ%ÇĞ&*Í'ßÍM!RÜşÿ1®%@]HÚàF‰9~›´|İ«ÿñN&A—é†`3ğ&ta½˜4gdbvÄ¥L'Œ3_ùíÏT=ú~‘W6š«Ó½AÛW0—ªí¬t¤\äÒÖ÷½jz¢™äwpò›$Å…kÒ n¤¬š•ØMgñÄjÕ7˜ÓÀœ­Lÿû7—iÂµL,Ù—Ôò9'Ôåz*ê†<;™eÍnZ,Ïà'&’ì#iôr‘Ui7ì­~M‘Æ›‰ÍÆ†Üş7‡ ¿Æ;[¨zG¬.¹F@	‹2…`ˆrñ“°Ïò¯•tSÎ©PÚq›Â±:ìçó´0dW‹iÛ^ÎOZqeùûb}™öt?ûeš¡«‡ûNO1LÂìa}jAg™ÓyÖÆ˜øÜ}ö—ió&$İ»(»ƒÀ’:QıA‰ıoæÑ*(fÿ%ĞÁé>}¯–ê9h÷’ÊÍ¢hãáMjÍâj-òN¡ò«©n4TİeK#®êÖ›êZáEJ¼(Qıä,‹ºÉ@¯T¤¤ˆDááÚÚÂ×?‰±æsÕ]1œˆrO—½šåÃ|ááÛğ›­½¾Ş®ü
nW¬‘<KK;2LU“EÆ¿"¾”Ü¤šSø÷¶-–l‡“ˆ‰ÃïÖåwŒÊ(â¾m`¡H	Î‡X‘Õ¦@”Ê4IKñZÍş†úo˜ĞîŠí†ùkcV‹I¤ô²VİÅ§	ÛÜˆ÷QòL–Ñ²£À8öBG…A_Q¤)‚.SíÍÍùÄı¥C­¾XèœOóVU)ÿX†
<g‘şQîÙä|®ğÂ_u<`Œômû	‹i_dHºÛ`Ú¸íyVhVØ‰V†öç"$öÕWSŸHáO&İğíÂT‘Øµ&­Sª?2U³5ÉÂ•]/ÈÕù©z<–Í\ö…yY#AcZ®ÃNÏÇ-éíÏÓƒH«îIC|ÌoqæT Kİ°Ò¿ãpˆg[ÔÆÒ4½ˆY¾RGQj3¢bíŞWT$1’Áe[4÷¿Ä­º]Ù6¯hÑzF>Y	±¿
kğ«TåşÒîÉ`y/¤"6K³Å‚¯—æ.I€`>¶è+ı^iå¿I©æXc.2ü'*YRõgS(Â{şÚNp¼(ä“wp¯æ~@J7Ó;0)uû™nŸ‘/~×oaÍIç‘\Ãğ"6K!«×‡9›	Éûğu·Q“åe¢kİwÿAáÿ2Eµ½! Yì—A«=[>Èïœ¼{a$7è¡=´xø 6¹şÑ±3Ä\#&’Ìáoƒì·tZ><:k‡n´º¤.ı/µ¾§Šº[’ Î²O·­+İ¸´Y$¾l®HU¦¿òLïÏ=©é„û”!òeìtz1Ù‰_üQÀÈYjCE•*]J7¯»ùcwX>ÜÄ|_²‰9+±IÄü›¤ÍØ…'iˆÍH$âŠ¿Ë‡Ä7-‰(2Æ¢ê.dä>İìg!4%s¦¡ ¤ÌJ¿×»Ø%ì8lZú œpb#M_Iåò½*ZçPIxÇo/$†Ú¼~¢l‚Ñ­ÁäN’ëCäX7~“!½Ë„—ª®÷Zù%ûµ±0§‰²d×^nAÏ²×â	#êdLQ¹ëºì¶“‡Ô;Z6.C†Á‡rmB°Gıä†’ø°¼Ç¿}wÉ|ÓZ¨µkrÿšv÷EkßÒÁw3ë
O>Ë/'"<Y§)]²_dÇ8èC¬ªq¬ Šë4©­^æÂi|èC`˜³ÎÔÕw×âhÀÓ‚Ôt(ãƒ~‚	Sh”DÛ2w':\ÛZ÷}„_Ú•Ñé¬Ì=Ó±ıUPÔù2!RÁXŞ‹*×?)ú£Ã•°äªt[_?8[Ü×æuŒ†á0[
ÎêÀœÁôoâp~¸º‡ÀP5˜ ç©Yöİ¯ÎÍöÒ æ=™ª8èõŠg´8± ÑÒß™LŒJ9s¨ØŒÜÿà¯(^õ2ÏñJ|Í'q÷j/V)‹[Òİ`‹Z£Û•·Š¾2a‰Ôå8¸ŒnA}‘x#®vå!”×%t¸6Ú_ªè"®0Ÿ›7‰®…	» ¥Üˆ÷şèEÙ¶8ø@Z“¼~Âä„‘Ä‘G‡AXb#aş%¦MÚüksÆ6‰ø¶-¼n<r€«Šú¹©”$¹yŞJş®š”­´s½Á‚ïÍv†D_#Z#J0Ë%r,ÎÀğhwxa‡.g£cÕƒÀo!ë	ùïpú±Š 0¬»q
ßttT¨y×åêWCíVîO&ejXäÛÌ*)%ÜAoL®Ù'ˆ¹·¥íÓƒú_ÉR-áálàZ`‚%Æu¥^ú"RW×F4¯8Ò Ey‚ã9µ02˜Ï¤¼—ü€ö†VNş2¨aÙ)Éñà	˜ ÚÉœo½¼T>Ì-tØÁŠ&’Y¦¦K’ó}ØuÉØ¢‘§Ñ9¤5¦Ì	LND	~9ÛÀË(tXÍ)¹ßm"À“…q_Ê°Q^Ú¯r«àßœ¯v _×}Å¾ôùå©P	ïn–+Óg}àÈ¢hZZõdAA	@cuRFöĞñ}ÜW£)˜½¦¬k®A0vvTui‰£Ç‰Ñã–ßxRµUK~æ&~Tˆô„×<¶ìu‘¹¿W6rï04Ç9:±¨áq‡Šûğİ²9XxÁ°°Ğ5†O¬’YÏ¿FaOy
é#¶óTX*÷i,j¯‹dC£Ğ³ØÏz“O/{Ò)]Yò‹¸«‰ÒŒ±QÆAø/Ÿ¸)…£¨ÁZZqpâüæ	ïgnPôc}m¦±„¬Ç±a -,Ü861Oæ í–‰ÏÓY³<æ[”Ê˜˜È0+¡ëb¡†3˜—óı9ôbZéê5HãßRCz0×HÌØ%‘cŞÙ9£×±Õ¾aás!—,¤ff—éC`«º8şÿğ§‡]§ıİ¶s4Bw•‡UFÙ¹‚úRª½1À âr3Hh'` uæ&Ë(°‹ˆÕfS:º@Ş“F‘‰CWÂúŠ–ï¥KØò­YX:[”Ñızümr.¨ù«‰¹™Í’„P¢eéº!£[£ªv.Ò®Åo¹(‡&Æ£´tµ&¿H bb§¨-{OKb³3®zùA¥uB¥¼ÁW²GNn§8H"i7TÛaWNgÅXx·oe}îcY¦ì¡u“Í’Ya’¡AW÷'öÃtõfS™|‡½jİ”zÚ… L ¡B.Á”¦Eu*lÄ9Ù“UéıDŞ$
ÿaûKcrhÓíØ3ÛsöÃRGÎL¡ˆ•šÉƒÕ!†RL;Ç{^Á¯­ğûçt¡`Ñõ¿”¸S›ú™&¼¿–%±Àp%£{çŞ–Õ:Û#ŠA.Óˆâ3tawÚ¡›Rz…v F¿Šâ+9T²â³"Š6•m×Ö{Tj`\[0”Lw¡6næWßŞîó™
Uh0L3CtsÍÜí€5F¢–‘Š¥İ#ĞÁ~€3,Uämüñ¨w.H¯›a–eYÅšVÉˆlR(ùÍu$šæÆá¾±`œ+Î‡ÑL§÷s¤G½/ĞËêék8ÀÀÄñÏR4¬U5Cés¶«S¯ØìŒ^Í—D¥—Å,z&°şD?*ˆ\K%K;w£è81ì)Lñ˜hµÇ[ri?âh,Ö*ª€äPñXËåyîÂ3»cÅˆùŸÿ[(Ë‚CöÛ²ÏîË´¼š1]\´»p,;$~b'ÏíQºeÂ<æFåu°œETy38]û¤xMA£×g¶7¨sn§Ì.·úƒ¿ ÿ|zc¦!>>¾6Ìù¥­‰§Ùò+©<T
_¢[3Ê5¹ú‹BÏf)Òo()›ªhDğÍXd–àå¸ènM-yˆşö®Ûƒœ ;ûÙˆ<†äbC7¦“—+]Ê¨ó$ƒÏ®Dä˜şı’uxâ³Z¦²/ª<\²IÚ¶(ú¦Ÿú¦Òx8¦Îä±³óerŞdöçšŒ¸°75ô@ÓéÏ/.Å‹[qæ lØúBÿ@¦Œ¯áÕõokæ.ş¡§;tºÙzÚ¦#ReeÂ}· ¤æ6›lÇimVŠë^ô¯ƒ9bÕÈp'Ÿ’!áâhÁçMÍ{
-÷?‡]ûQå<+ yú3F€Æ+º¬VF¢ÎPa’35 œAï,=Ç%P'›üÉ ºåi¿æï¬Ùº˜·"¯y)ŸZ¦ÙûjW`¶ËÀ béH FÀGÁ$'ÌI{Ú,kBlPc^?‡ÿÈà ¼­FÉh¸5g¶Å»\Ö-O`ƒ™4³J,—÷]št7™cæsåF9›íªKHè¸Tµ¯×Ï¤÷×Qp©ãıià“âÑd=±Â'Öœmğ-]Øú>^ÌªÏêØ³s¾apf€ı(Eés+RHrP¿Æ%K(á q;gËsï%,:ô­Ñ?Ô*KıÉ·q2/ıŒK Ğõ[SÚæ©ÏÍà1ø»uZl“8)ª†³²›Ù9zÏfÄQº.´ç—Áœ4‹Z(‘.ÙZ‘J_i©5%±hß ‡I.;Ëd<|Lñíä©zôjE-é@ b·fA¶ÄqúÜ
C… `7eãmÿ’ß­ÊŞÛ•Ú`ÍŒü9÷«òºÏÌlwÔ¦ªÃæÆ{??PƒÚËìàñ»ÎÍ€hj2}£23Ñ‘ò÷á$Ôé,›uÛløfÈä£ˆGõ?>^ê1@OĞ¬VÆÖÊç•¸.Ú-„[äFL)¼_mÃ…ÍĞW¦•FÄ1í±İ™şÂë¾şÀs‹­èÜÇe8ÀTÌÂÆ€rC^¹Dáê"6Ìm‹¹Š
MNai#íÒİ€îÌ¥ªùßğ™œ¦Œ|
™ ¼“çÿ#C¥û8‚öTÃ¸Ï@ıyñ.ºVï*/Ñ}äû‰ƒÑ•Ò¿:¦«nö,QQxÊò¯ I€ßÜ;àÛrÔŞ[% E‹Ñ;°Ÿ6#„B"pXI2ŠŒ¢ı3v´u×½'0Ã\ëXóxZÍ‘û±A‚	1RPhß4AÅ°Ÿë~8Å‰U£+)â]}`3îöü[’?+‘	]*ef/Îºä@õ­•)«gš AX=Vç€5&×üjz‚ò:&ÃÄËé¼ˆ‰_8î½{¥t^eÊæMí.š1Û/÷^¬«pùÔ%ÉtV"ûê¸6Ÿ'Ğ^Æü¬µ"–Ã˜D;˜Œs)
]Û¹:^tGõ—¼aĞ¯Tl q9Z@:ãúÙ©n·AÕ•h×Äë}gtCwÁG»w^FJåTòR÷g£%½67%.ı¡ï§´?+rop:X@&Q©•ŞÌL+{Û6Ô-Dğ‰ı¥«)Î"" Á·É£Mc}-†¼”",]©ò!,ü9Üã¼há62²•¨>XNe\÷So{mŠù©ãŠNØ·³"ÀÅí‚NÈæƒ™÷ÛW±Âwìòz¨KêFúÇù²±”Ş
˜ÄÊHò¢ÍNˆw ~.jîºW'å6.nÂ®&–®..]tXî£LÀp! vû_Z.Z|R	œæ8‹¤@ÎÓq(1Ù©#íá¯eë ÚönÓ<×Tªt]Ç„|Qb±jŞÿdäUJ§ÒÂ.a) ;á‰{ŠÁ•]õ^"šnÇr*û½¸…°ïÀZ&»q˜Tüão½±¼¯ò4"aø½ˆmÈFı2Á!ZGœÚ›\0ö«Ì¯cº°K“õVM£TE„A€ãr`ÀÑÏrrîñ‘FzÃuä<—³‘"MÚ~Ñø{nÏªÀæ©Œ$’ß•Ÿí6õ~w„•ØÂØ G‚¸êv€-”Ñ,,Ïuù¦Ì·YbÆ¼×Ê#ıRLË=éæçf	ˆ‚²1 ¦nŞihSa+Äò)Å	ş›ä'O1]¼ó™û–ƒ¡LC´Ñ¶Õğ=‘ÑG¸c0&TvÖØ’”·0këç;Á9ï¦U8üè×p‡¹±Eûqyl˜zhÑs™F¸1ŠÑ¼gÊI˜+<?àÎµ<Ù°­-¡t¼^•nC¹Õ—ëm ÂÌëq¬Oïş$Û"Â¸¼³~^´]E6Ô Ë¦H)„ÿ¶ß’V=0 "ì¯ù!¶6§B;§¹Â@†`:NşğÁc‹0óÆÚ]»YÒ³$ÃÌa…E)©çéİÙ[Õ¥5xÜj•ZğÅ‘XN3A
N†¶õ©' °áLİ	ÒÑ'*·9B|5øü`kĞ”1Q¯Ò#ÕÌ¨XIó×–+<İò^m!w#W·w“?XÿCˆ}£İŒp'[uTäI>ı×³÷—£p2ÔÚq’:½&M†:‰vˆGqtÏ<ŒM³·Š½“{Qñ¨ı,(j
¬îIˆhãgiÊñ\@•Ñı9*·oÛİã6:¯LÙ+'6ËG¾¦ú‡P«yÀìò‰×( ÷K¢İ¨@'şÑ¹‡Ú˜	@ëO${,ö{°Oı:'ªb_RfètÔuåÿÿ5>MÁ÷Ñ Ïî]~Ï´UxDBÑU…º‹âÒ¤IÎy/vµ÷-nó†Níä&¢cÕ%Vü)yø~nœ÷&mÔ}Íc¸Ş3Cp¤ÊehİâšëÊ'ÁšÊZ^_HÚëŠb/À ªüËR…¨^vÏ‰Æşõö”ÿ,E|!†	*?=@˜fÛB¹äØVz¾‚uF«İeÒŸgM5ÊL˜ÒÖxLsø¤ğa,q‡ÉöŒÂıÅÂ³õ~“$Ò4IŒŞ[r[o;f)½)¨2;X­¬e…µ;Šçw~«ì—n€/¾«8³ŸëŠ[ï{»P´ptÛæÔJ+íŒsøá%×‘Ì2dêÜsRîgËÚUÔ;nµÙğ&æŠÊ±^Â©Ğx¡C`b`‘ö
bQ1>˜º5¨µğs%é»~n–­<“äı0ƒKşq^u\ÃCWY,ïÂ(€h®CÍUÿ†=$ãè'7DŞÏhÅ$hTŸ¯­äu }Ô®tì„e-pÌ4ßÍø2Ujx
Õq2ˆ/Oï¡pô|,ÄšÉxêIzV÷ÈŠÉ˜6 Òœºï–š÷
Q£xË†p#úù}HÒˆÉvÏ&¤‘¾(š›ÍwÏwo‡×±]ğú7P®“)³ÒÆt³îXÂL¶¡n¨C!ıF?ÿÊ1(£P&»­CùJv'ÆK4áuK	èWÒAÜ«owbz5]àBQ!Es}D£	Ê½#÷ix(ºğ‡ßmS…Wx@"p_ 6µ\™FÆ\¯Ÿ·°:Eo|3~\³}C†}ÆŒ¥±±{HO= “¿Bëx÷á-ä<ˆèíÚÊ—Q
ê©hÑÿ×o%–\³$õfUk¨‰¢~²ú1Ÿ
¶‡,º„S@%dÎæÏ³^ƒ£æ†N³&´OÎˆÄ®#3<›H\pb(5Ú:ó¥_GI‰‡(*UÍ:‡|‚
løWÓƒùÆï>.YrT¤<¼šI§u4ƒ_Z÷Í¨¨bVÅÈœ¢TyĞĞ™^5ÄÏFÎy¡ÖùŞ¥	dËAÛ.NFÎ“!>Çœ)ò¬Ğ‰½w9\$‰à:\’Sİ¸CÜŠNg*ó_3VÈQ"åû:ÙáHòşQ5ı=Øis¥[Iãa²ôâì”TZ[*ú~	·=;Â½@0kIâª¸S°©
öÙÕ¿WzÛ.[Ì‰ÂKQ³Ñ—²§F“SGÂÅùç/Ş¤¤Bğğ¢Kşµ‹V4kş]‘•6KU¥„šÄÅĞD¤ÓÏª˜Ø³$OäsHnÌúÚòJ#Æ‹g“â?8Ìù„säIµµı²Ä
  p¢r{T µµì±¶JcÛIİÕ9·AªZfÈ<ÉÃ[Òàò`¬ÕÚ?áyE>Ø?»u2 ƒó/•ƒ‡˜¿µWy\RDbR# /ıEZXÕÂ£_¬zğ^äDÀlÊñß¥IÈ”ºõ%ù«'é@mX+4Òaˆ¤Ï“ØîxØ»í=ûnKc1ëâxËn'vÆ^0myÀåFeĞFC©®¡/»Ù!5ÉI;¡BôØ§”øåè‰?$QÂ‚‘²¨²Ê7ï®«âÙÒÜòêğ_úäXÉ0%Ú˜zµlƒÍùáuÈ¤¯*æ§Û\kõ<äõØÌ=’;k»ÔÔ×ÙÏÛfüœÿÎmtUÓê±¯Ä42ñ¥·<Z¨ÜÚëm‹*WKœ(øÚ$'¿Ü¬î‹Õ£\Ô,è°Ñ=%’ÅM¬:îÕ’aêXm¬óšÏe}›:p0oêöÍ6}1)Fät¥¬İèÂ÷>ÆÄ:-`“+E2¿ø–V Èe·èÙtUö„Z-Ó7¯Çı”KÂUQnMuƒJ,ŠÛv¬7iG»)ĞèÛAeQn;}_U‘…€U.k­şzùz[ˆÊ İ´“}‚ÕÙ„—Í}hÃ""º¡{C³ÉjñtÂ×ÄõÄb@¼9H¨rq#•‚ã×Ÿ…ç“sejü½æYÿ‡uJase‹ÙÓuL¾í‚ŠÕ±x“ˆ_X`u¬˜–Ã]<ùæÿN"ÿ¸Á—bÁP
¸ç$¾v?«·Cê%ìŒ;†»]„Î+ª”7úa§7ÅsP8tÎµ1HØ£æ-È5Ã8Öªhå+ØC‰]Çgóx¦‰nìƒa3·Å«à”$›óÕÉGâCBëÑòkÄ„¢ñ5›¥í„0,ÊÊÒôÄlÂáÜšf@u‰Y35Íi²dC!¹®ş'¯V¹'p×cb‰9$ãò¦†ºeeéâ_<Fd°Š/F^l )`lÄì»³ eÀ·§üØdZ	iĞ-P¯{fÊkFªo	ûzB-Ø¡ï52 N NÆ÷ÇS©Üí*~=S“@†Gx3hÈ’QÑu"û±@Õ]Ş<P ºèîãawx_V507Q'ñÄ^µnl¥0-AWé~.t2ÇOêõÓÿÍ\¥Ñ¬¶Ê­ï·^¢œ”dC[ÍÙğgÌ{}wû°ÛV*	ÏŞ’Qø%¾C¼ruD-¢yÁ\Ç:ùDËÅÎ
a»Ù¿Nÿqæ™Òç	mccg^ûhÇÔƒ sa'9öë¬Šùø‚Úã,£ç°È&ú¤¶U\º
5Šğe›Üìíñ+W
ƒ²zÂß~îğY¥;¹©J¾Èrâ_“Ï"wnãÈ7Ü(cƒĞpºöJKä)”9[¼~QÚê{Š‹Aâ'IÈyÿlzôkå³‘7ÂÒQmAÃ”¬7¦±Â~×Ø¶L„tìRœ|»,x6/X¢È719FÓRğ¿Åf úå
ş[Ë+®HQ¤¢@[ª!Uğu´²(k\8fÏmıÖ¸ÇõƒùæãğsŒiÙLßQº¼Ó³4Rd¿KÀğ/M—5.çp¥4|Í™şP"ÊÏ‘u‡‡oEÏTÒQ*GHÀE oO¸<Æ<¿ß˜vŞoE¶qíŠ¬¸¾œú:·/©#ƒ¢;U
˜¥àŠqFƒ
$5ÉÎREúİ ÏyÃèöLOÛõCõçÁ‡­ƒ5¾|,ŒQ½6M"¶áV¡À©ñjò"®"¯}—]}|AQ»ròõ®ÎxSjL®Æ’`îŞÑ`%d<î±}“²£µÉİª)FjÄoëìÌ‘]™Rğçcï,B.¢=)¼¬Ñ´Àäol¹ìƒ/¥g„„¨¦ÎH.»V·—ì]R¬ Ñ0¥ô[hÔ–I|l{Ş\4h8ü¢()Ê‘ÛT\¨fñhÕTnm›Æò‰-è+˜Ö`ùÁæÇá{®ƒVm•­¶×„~…ìôi]›ÃoÜ¾$å4CçˆUacOPjw˜u#=ıÊ¦ôØ¦€ªF?¦¸eŠ@$©ã@Ív²÷^¨ï‚$JQß)º¸#Œ²Â|Eø#Ç)¶Ono‹šÒÌ…ç‘&#rpæ;)bî:7ˆ,äê$²ÂÒ„Óf1ys{ Iâc,Àë>ö ›ùDŞRÏ:]²h¦ó1»‡:X˜íoÆµr<„?Eè­ÒÕBgó…`]-¯é@ÁLMj‹ÓÒr8,ö/˜ÚqŸ)xÑZnbÁ¼s–ámXæÙ°8õ;ìFô@!’yS©8Â5¤êÑkºš&_®5V“Eû9°Î@ê=ò
qí¤©èÜ :·ÈELNÀğ´š²(„–-u“ğ;¶%=µ´P¾Õ®~\Œ¼°Zô&É$ ‘·*7ødåší¤fæÔ{®úÃÿ2›v‰w:3I2ã¡9ëˆ›É¡5åà%ÔÿŸWqî7x/ğ[I\¼£üšø‚
¢wGÖ³’uü7[>ã8ô,'£Å×Dâ_Ìé{CGHÇÍøAHé3`g…åË?²Ø3æªòß•`Í%^l>Ï‰]a5YmVa5g½ÂÀ\¾ôû'ªF#^ 5DÀZ‚g­AZk „º*²…bå@ŠP+/j‹/‚¥;®8©Û4“ßez-ª±öÍå,ã•êSèÓŒ\ŠäŠ°3àrÁî1e(cPb0ş•[öšà‘4”TeTœfAç@Şë¬ûDçF<ò”Bñ5Êy!Êí×23¦‰Fî’õ^ûX–«ÆÂ§Njæ×-}:6ûñjç§’3C]çù¨j
sZÇØ~K»t…((ÆR#Ş6m(wt>@0WÂb„èïZ¸÷¨fw;»9TÊ§**gh¾dÇy2\tj)™‰ğ¥4;—ã„ZEà
Zb¾Ä‚t§‚4Æœ"·Ä¦J‹=;—hRQ>µšÉqzx\	<öx#Æâ×–xFVû|¨Õ´JJ–èşÿ¨Fn>³‰÷êoŒî&4¢Ûì“Ä±Á°œÙoÄ=ç¢z$ÉĞk_æ	çfÙ«=;Ô•sØ0*[EÀãß²ëá«rñÊÏrœûÃëÚyG¥6´£òÜ#øeÜ{"è{¥g $“åfæşp·]¼Ay5°19—…*È@³ÒŒ<´½tÊƒãÃ3U×¼½@Ü4L¢Ã¸(½Ì)}•j²)í¢çSE¦Æ„Ò[b›°‰îo5ÊZ2÷Kì›Â’@`Š/Rİè“Ï¦ô;$mÎÒŞÅÕm	N¤ú“Ñ×„îğìùTxFÓ’XûA|©!­ØqMÁğô¿ü†Ù–_ÀH÷ËÓI.\İ_ö…Ü7÷‘-X´Lt.-DÈ°`¯üRÚ#äYih¦W’€
-F1X€\|ˆ5èŸı¡~ûœ€eÁd˜`Î¸cY¨–øJ!°_~•‚Ë¬µ–§L¬Oò¯©A-#êL<’›i|L©o» @R+u™Çê|ŠŸ=<ßqR«·”%Ó5û>{+½¬İ[İ|C1E¼ƒ~ü·M˜Š|(÷ÿœAÁÀğšr½ùd=;'¢æ&^§¢û©>„ÿ§UÀÈ~qwÑm+PÚr³Äm¯²¢:É¹¼ÚXùìà‰Zît[•ÁDŠsudQë®¯½aìoå—»‚…>…MìBßğĞ ]®¿1PÌ4S0Ÿ‚.¯é)WFœ¬“§4)HX°ã¼å^t«ø\È’Íg˜Xœæê"Ö#Û—{aşe‘ÚÛ2W2I¯ì^e(kx£¡1ÀŸu}‡„ù~éCïÈøİ“vz+ƒé¡p¹“ïÑµ«-Î4·î8s-ªµ2Ø}êê±DB{Ğ3¡rr‚—é‰†ÿ>©ıZ¸î¢]’½õ	SŠÎ“IåÛ|şÿISh)5çÚ=SÌĞÛP'z*©½
#¢•ÓvLÊ²¤ÛñšlC¹ùÏò]5]G~:.ğ%VCWv2æ´tŸR%Îİù?Ã2<İÓ¤Î~êÔw©Uá:æah§¼LöNuï©š¿Á“¥ºšÏ"EãÉ2£Å2gÔ<:—ÜGÅƒÆNÍç¹ÆÖf£Ü÷ÈI¡Ä/Uš$Ëö«ÇÜ$SmŸ#õ»uår]ÄlÊ>8wéç¶ût¡°ó3ÿ“Z*”@ÖóÀóÈ^hòUa
Ç«gÓÊéJ.x¾+³Kª¶pjÛàJ¬Åå›Hm(¯V8¸!…-÷ëµZj…›ÃˆJ ÒD¥,Æ.Q ¨ŒH?0?G+:¤%³ëò¶¦Ø»LËŠùk9ŸSJ-²ØZŞHúîŞ¶NÈ8(3»bÄ#ƒµí&×‹€gÄÒ…ôL¼*¤ˆ¢ô~/P'¿³ïÍz	«€õ±¿e
;¦	!î7xh¥„}Ş¶Í÷¿R·3T*ƒå…£’ (“'ßÌåÏÕ†lï®‹\â/ş™ñŠ_–æ8s°rÚâ©@¶“~´D®dÑ¤ÚqÓ0–èÏ`}ß[”rİó¼ÙR r…°³ø""ºŒZör/{ê,ê›PBj R.Ÿ“®/İå‚×áıØ¬]:şa/¦^½Ú›Ø`|eFŒ~j&š“då¡üÿ4œoçFn~±¥v”Ç+öùaÒ´eß“WtPßÜ ²ª|­(ßRñÔ<¶ø®)¼&ÃªîEÂ §´ó#B¯G¹øÙå˜Øûş[£[ÔŒa½FÈõˆ×ÌõÈ¼ÔR§jÈjÅÇD¡Ê
`4š«üå|à ¨Eq•¬)	¬àØ¡@ÓC·Ül]5[B$eÍÍA3§<‚:*ğ$´v%ª¼<-fp¤(Òä†`I».oœt›’§ÿÜÇ´ŒÏ„XC_õúºM¡ÍÌîp*ç\¶QD4ëÿü&>"J)Ò¦ï_ã¦£5æk^˜Õî5ãÿx'Ç–•÷š°±„Ñ³tsgWÜVºS¤6iÕµ¨öìí,1©™Ğˆ©ö÷ç%…’ğ™ˆò«F ÕT°=9~«•¡)"ü¿y/OÃ÷FÑCÖMŸ½Lc…eØ}ú„#LéÄvÜÄº¬]uGe•¶aƒ°‰÷Â#ÜÇK×í¤•¢‚…ó+'É“\¤XĞ¶KYÉÈ©’†j	´XçØY"H…¶poS¨ïøu7^C1á×ªó¾S‰XšƒÃ¹Ùy¯’dŒP£TãÄIäÍt7|Rß~äÄÑìıá3:åÙù	Ê’‚~P±6¦D¹To­wÃ§-o‘m¾ÂDuÚJÑW†Ö„ŒevúXI~¬Ø)Ë£‹‚ùÛLcŞÃÅèærû>Ÿó\HŠ\åCëÏÅgXºïAğ€^@3)¯ ƒ 4É#¥·úÛËÊÓ_HŸÅL³¿Êf	µ'¦NÙî{ïj½S8ÛW*¥˜œOqÏY(…ÎÏHÁØ°STú	Ÿˆy÷¡¼8Ï/1ñ¦\—Zjıı3ş®¤¾j‚djšVõÓÚ0õzòa2ø»y
‹Ïİ÷÷üäãòÇ44mCéù­Ìˆ$ùõ‘`4Êò+miÍÆàjK]¤æ¾!®º©ızò+-“„ïí±ÉÛ· òˆ†[æ­vs¾ÑW½tRÅºÊxŞ±´-İV¢¹O[3JÅ¢G
ê=µ1©VjqQ´ü0*fß uJ4CC±Ù—<Î…!¯j€£ûW‚™vù°a‡0r–Äèó‹ã{ mã—v‹†xeá‹¶±I@©icÃg¼5H’€“»rµÏ "ŞÕ|§ËêR&‹êÌsÄsÉ	"„	­UpæÁíuÍœ#<!°î­­nE¨KÓ>ÛY«}Tşn†çÓ6I~+ËßTWÔê‡†Ÿ©Ø!ûëV=³všcVL*åjŠEúÓ^²WÖX´^)’_À•{;EÍe…êš€ôøØí.íàûzÄáoíK/ºµå2ËšÍ×K^ƒóÓš`´!j¡b
¿\ı]ë|®ÕÅtr'ºHäïl›JH˜S­¤İ¥ûW± ñåÚ›~Ã+úFê7&U•ø†Å®s•„ìÊòPÔ’yDç“ƒã©Ùˆ—Z3(ô:[ZsP@‘~ÙÀü+-Ü]Jµ£´i 6L7CS¯ô–ôĞVL€8lÎª©±vTËƒwÙĞÂÿ(›ç'¦ö¾ôvŠé¹Ğ‘Ù,ô°2QÍaıo33M;]ßJ€È:…Ÿ&8DÍå5[z‚’,~Ô=í–Ğ‹9§¯İI;#AºUñ¬}Ò!§0d¤P^ÑâñQc±¡çõÉçMz´ÿ^Ñ)£ï("W3Ô.nü	¡ŸZaó0dÔßŸc&ƒş'­±é1xA:nYùÿ5&¬ş‘=ÇÃ´W(^J>P’€õÇeÿØAŞÅì0$„~İíi…R1íü‹âD˜»¾8PyX£ø\?­û
€ä}FjµŒ»ñä¥¨­:uò°ÄFZÅİ³’f|E'¨8[¥LÉ—7çy"Æ”én÷?ºù.&RòfûH4Ğ-³7Aé’¡i qLğ&¸s9®ÈÂöÑK>!æÕ
nş1ºˆ~é]™Å×dMï\¿õ‹£¤§·ÑbÁ_¯uôj 8»1B‰“sÔ/b=kB©ÁÌö©Ç^ÂC'#>…‹2Œ6å`ï 8/B¡ä=bÿæÄNÈ1R¤UÉı.ìËËA¶TÔ®épTh '»®šÏíX¾>'@ĞÜƒ„Œû©mÉ¬ÜR.NgÕ*kÌÔpG½r›5|–§„Ğ#áÊµŸ°ƒ±O#~mb<!ÿÂ©#Õ$zƒó©¿[+‘´Ç@Q¤;	ßçLÖXÁV&Ş©D—Ô‚^w™¡‚Q™ÉgÉiÎaUo$µXà²›Ûê$¯9Šºo\0GÕ·2õä•!ïS€¯1dğ5µw·ü-P:3  &zíS»Ç+7ÓW$âv·o¬{”Dñ5BîoP"Šœ”Ë«m©Úÿfy‹goKXSèÕs+ÉÌGº/V*Çf™ŸÎ…€º~á¾š±Šç<ŒPßı½ÉTÍÊ§L˜M¶¯Ì;ìNûÕ˜¼õzfSå5×î<ÚÄ4s7ÒÛŠ^°›šÚµQã§qSë¸ø·|DÙ>ô¿HÏÛ;¼1x¤:•SM”t‹“æ94Ú£i0U¡,ëğÌ0µD¬‡‘xéD¯p½•’õ+Éç
¯¢å°˜øÊKì¨",UªßÆ'~·¼hÑ^3äo¿}•F™bx7k¡#EÛ°Rß!Û5õñ?¥>“ÿ<ÃÎ¹ùna²Ğ´)gòó—%„g.âÙ$iÅ`¬ˆâÒåôrET§ËEUuA\ÑØ¼ã;7Z¾B¹n³D£·•T|ÉèsbNGYs †BÖ£ ÅôÃC½r¶\/£.´Œ¸Jr%[ƒşÕMÿ-eiR‚ÿ¿î(8	V@Tc’§
õ)²6Êtu*î¢hãLtÆáó­Ş8ÜÚ jb[$ÍK=M$R&4vAB—Æ¶ô7ÀÎœA×[ï6oÇF‡ Ñ0Hd|„?at¥ŞÑ@„l÷é›sÅUû•{©ÏAã®pw¥w¡—ıMûsÍZ¼ÿÑµY*0F¤—w£‹uj PFe°ö"Ñ¹J&Ó5¦œ`Ú†ÇËûáW¶ï”\²?#=s(¥ÃQ‡B7Î‹ö `@²Èß0,ıPqÒ¬aØ]Li„tI]©na=2M=8/éU¦@H}ó3Qù¤FSeuÜi…Â‹¢VÀ[ñ¨·†ÀS(ÆV+Gê¨tÊ5@´ß{i×§Ad°Î4½x×‚?€QK·|ej)®ù üÆXHÈ]µQ§™xâ-$=|˜]±¨JbÅL1OÉau "„ëQ™õ¼?pèúãôó¯EÙêe‰¥Æ›~ÂİÑ%¯P×G,ó¢D]LyßSl†ÔPš¥ğy·“—“å¾Z•|Mú¼7‹ï¢mV¡m“šx«Xzüè€çæÔÇğ(È‘YÑĞO¨ó¼Ò>5wO¹—¸lã^+ÜG™]m>sQgµêzGeY¾/ 3ß9"\zEÅ
l©weÓxT—¿1Å¤™W!õ2±JûHùÎ-Á/İ;·Ÿò[@2—E;6K:ÅM³kÂšbÏF8Ê§Ú$Ğºó¹MQÕ,€é÷ù¸öj¿¿ >X„ÉòÅSf×š“àQi\`•ı‘Aq,No…İF˜P"‰Wí´³~Ú]¥hˆºŞ›FÁ.d³7`ëØGÔ¹4´ˆ*ìPgY\v1"ÛˆØğzóQ?gQ’DVŞ”•>{.LI"Ç•áş™A’ÄŞºsÌêöÁ}åRaœ'±h&€ÍÀ?ÉH
ˆë›xãê—XÚ˜RZ¨.×5v6ENzY[ªÃÜ –TwF¹ºÀS¸_Ğ¹p@Ô²\J‚Átè•A+qY€Ñœ~àsîP[—whZ‘Å©C"	ø!±¤Ø _o‘•ÄWÅÓGGP"çÏöö¡Ì‰ ùäŞü÷K¨–¼8¢+ I#åù 
$’!´
)?«•¼tEÀûÔIzÙçÙuˆC¥§nB)^[kÃ6Ht"2äÕFAGÃ“x1ššï§7úêİ³‰Í‡#¤ÎÈX
Nkû¹ uœ¶ÄZ<~b¨Êi,iùù:^Û.¤ğ›PÚó~Şäµ S…ñ4œä_/^%1d»ØLVÆîP£«&0ÎqÚ§ã	ØÀ‹æXŞeÕ€"àRÉk½;†ylç;ÚØú¼g$î-û;¬Oñß8‚ƒc±¤ ,;çĞ2-³Î‰—[ç,w“|	#Nå//œ”>“¯î·j|ŞïIÖ„iT#IP4ÜIp–ÇÈb	c
*Ü™e˜ÉøƒBH­qw@}ı0
tíÖ_Ù§ùN|-ët_²¢s…ÿ™è…Ä *
„AJ,»?ÌÕªòR½:øq"ÚÇ>aC›fUU]üÎ¼Ùæ“.hìµÕÏB½áîxi¦Òÿ»óï/ó²wJHª×fxÊz=Ç¿;WGbºüfB¾ãC"~øe?Ğ>Ş”F­JĞ»‹"86ú§–q±_´p•sûOd0XÆ¬—ûRWh?_p„@N¸í—e¨(8oK·BI{s²ñR!—?„rµ0•Òbs6Ú–µìfø8W¬¸«Ô?GŒ­‰¿ğÛÜ|>ôM³,Iã"$l)_yõ	F¸Ê–\a+ÿ`á#Œ ñŞİ»”òQ;b)y|·™™‡í/”š3¶æh˜WPqŠhôãÎ`znGµ†–€.(ş€©QÕëreS&qÂ®{KxJ(YñÙj¬¶çyä–nL?²½šçÇ}`ÿ$ôe€iÂFFÛßÆÓï¸â,ÌÊD	«æ¸ß‘â¼—Y„j¤!‚
F¢{S¸Nb~ûÔ!?zÖÍ	¡Øïzm‚šĞüoê€<ù’µŒ%lâråzÖ$ƒ+éz]3â»•Ÿé<‹!k£ÿ3Dlÿ•Œy¼¶DÜ¢šøÜÖ:’t„ÚšC2#¹øbãE]ä÷™˜áòã“aG­¡6DŸŠN–w¹ÌÜ(}S¹]Ç¼3ƒúØ4²2îNœÅ)¼4%ÕKB²ƒÖÿĞ Ñ…^İ2÷ì\|w;E±v×š—³©q¸±÷K^H¤ÌÁOÌ×‘m(Ì–(úÄºĞèÑ+c¹x·Ì¿:j"ßªLKW#º;ÍŸJ:ûÁJ1ºaØ3ŒzV”y2VÂ¨ÖN(l„T[6›ËS!VÌRÿ—dô\-ÈT\äWä<§Ÿ-ÒB+P3AÃT™u×ZãÚlŒÈ ÆÈX(ÖjËıQÂ©…×½•Aâj/’Ï\¯ \H‘çi/¹çâ~âd£H$î¢pÃª²ìkÕNtR,Wä`OÀLÄˆfdš…¢ İÒ¿šø_€BŠUç¹jóÀÊÌø5„ëˆ	‡½İÕÿ³íÆQÎFIÑº6Ï‘BğÊ3®|Ö#(Ï#á8¡VÊó‘iÏ¸0ø[Œh¢½%
~²+=¬§âmó«'î }APóÃa»ğB(¥\*Úaî]ÈQİ5”r¡g¬I©
¾ÃÑøñ…S¥H*ñVæ©~²N~´ÍêqÚñ„jØ"|úÉœòF ûÚ¢u&w€öŒ{\¢Õc8 ÷…Ş.¾«ù¤#Ãƒènápíå$ı0^	/ãlò§öl7¿İÅí)db5ƒÃ$o«?;ÎşmD£¢@İ)%¤?Â ~ä±¹ÈÏcõñ]Å2fYD'˜A¯Ó$  tÕT(W'Ì^KÛe¨Í¾ãg±ë9ß§š/LzGõ^4ğ¼PÚ*{q'RË˜f#èƒËKÊ"O+ |Ğr—”³\·)á5÷»~“—…nÌD‘d ®]¶Üş~mÊ­:™FòıLå7ïÓ‰y²	 °{c¡ØŒ¼Í+ÊGÈx$›ŒjvQÒ+kÏ­$QÆE¥óÚ·Êî¦ôb˜»#R
h’$ÎÜœ*]æ·é›ßÅ'Êáw$®Çª÷Ú	Ÿ‚¼ŠI§¤×™€UË;%o&N|g¹Ê×X[7¼Ö‘(IÁéG‚´ÿ¶VB7x}ÕC€”z«)½IX@ 4 éå¸ñª;èşÒDQßF"ñü¿¦¥á‰ñ 8ƒ9ÙöòBI«Ò†N=ÒÏÑ“GÃZË½Qß¦+dZ_l2¡áÜÂEjÉD²Ğ€“·z A‰$@½åFËSWå3:]ê™%ş¶6ú9¡ÂLv¾ìS`5*›Õe‰‰¢µºóÁÕÆ¶è«ÛO×+_Eè d$ã$UjkqÙ(q?ÈwÇ½ynbAö,­ö¯=ùº8Ga982v_qõÖe cÌx;Ü_ã—Nƒü©‡æşØ½´a±ëÌ‘GcOÈ-~D¬ßvàw„<Hš3{~hÿ» S˜Ô†Î'»3xn˜-p¥T†TnA¬Ñ£Sûe8ÇY3w„Uõy »?óN?é@Tò»JŠ¾çL»ÌùÆ¹¥ˆ”$ß'E›ÿgóv­ƒ÷ú"®Vš^"2–? òŸ„À¬Ú»(ãx;öu"ÂÀ£z~Ïö‘;<‹Sj®3È0õ¥şq·_¸İÑkÇ‡ƒ è÷E;íKFkúƒn^áÙªA°LgË•/§”şARƒ?¨&›D\:,:‚Ï´“áI‰„`ŠÇ¿¹¨‰IhâbFÆ³Hy°p·÷¬ó¹Qù»zÉ:;&ñe:ıÍW#ˆŸÁ!™qmçÈ“Ù„
*ç8¿›ï7Í
²QŠwµŠ»;¿`?ğ1Ù*YêÇmååH GÒõ¥®j°1=7½1PÑ¤q**í^ôóDç©Â_rb6a‘å"3àÈ7¦“=„o¥Ó¬WbfjuõÉsRæàY|ç¿ó¬¸vòs[½\ª )Ñ‚/xß|¼ël ¸Â%ßËig§j¹9k8Åb”Jc«V×«´¿v¡´Ù~Ö­ÿë»;/àÀœĞ¸Ö¿É)WF·¯{;ú’P¨ôçÓqgÒ÷ V›º[npwø4l®}N>UH@h}¥t éø6‡»ÜMùzáMx `ª|D"0İİı@!ñkÇÙ„,ßúù¾Ä1úpU“
¹¹3MÛ¢ıË†^o7bM¼„Z“VĞé]KÓó1N· ½µG×•›¤ë¢°X˜V—"RGØÆ¼P(U"¬q¦¢A° 
¦¢mxièÁêTãC¡¾Ö ’~Awƒûëó†(±"t–^òÄˆ©…–¬ş0ñE¨Gã[3Næğ´,TÖÜš…‚*¹æÿæ§*\Ÿ‹ëo¤FQRÚA7è¯; @™Ö‘æßÍ¤ùÁæÍâAãØ4¯
Ï´1°_üWhXÀg6yĞMı:M¡ÙÒ[Ñ6Nçİ![uSîw;ìYıvı?{ÚçÙÈz¹„¼)Æew·‡3Fä8kåİ&b+÷Ê>pkB†ùÉI”ÔŞÖ ªo¼%®TÊ<dëûVSÈqÆˆö™7§-Š*ï÷ò´uşª+Û@Ÿ];Éü=)L
Ï‰:àù÷€³Ad[Üf ù*Qƒ¹‹ó¹­p™eƒ´x•/ø6Lï$tÂÔ“~Ç>Î7¼­ñğ×\Ò†İFÁä©bAš!`:¹¶}ÁŒè‚¶bq!GÄÀÄ€bÉ¬Éşn˜5 7ÂÅÂŠøt™!®©Ï
³kÚ½õqêãöN½sñåü¢İËhºaŞÅÊÉŠ'NéÃúÉç”â¨1*	»8#ûÜ‘Ó•¬…—!Õ¢%-3®IÄ½Ëü”‚Iù¢¨ºö5¦¹
Ó1lqi[ß_°èF*HXìİgrµ-Ÿ!i‚ÜI@/YM æÍNÖñ“'ıá6¸[Íã!{ÙÛ=ê“@=íé…Dİw^ã+õ¾ËGCwá—•Ù˜¬4âvRy²‰ğY¹0äÊûQ—¼{&ÓW®Uª%•¹ûl³—ZÈ| ³kz¢€~råZ4SgºaÄ¦=Ú;Œ-
¶¹şu#£j¬yŠºé2|¡Ãi] ¢„Ê}š€ÃÇG;cyBÜV.LA¦‹¼6tÒÕŒŸˆµæÏÿĞPoXMBÃ¨áñg›0£·œÅ’I=RÀuÖ¯‘’ú·éEßñ…/Èm"†“MHc‹G§F"â+¥ŸÃÒ˜y0ßsb0qg›±e…p§E;ÇÂi	ÃÊU›™íÃÍ,{¯å‰C±2|8Œùó´ş°•2×ƒ–È +[3Q"”­gS18gêouü ‘.­ÌÖ¬·ÂÛf¶14hècàW€yî©-éEiPĞF^»­:ÁË£N?ª÷£¸°ıÛ¢ıÀ… :¾`@k+§İÌí\–,Åh÷şÃV
Gí²OE`OM®«F:'‘òdË‰Û|_¨¢ƒv¯OÃÜo3‰ñ!T{I–ù®Pª¶ÅWnĞqÖ4ğÑ*½o&û‘/úUAö_d‹&´è]Àf7	¡]×Ÿı¤Ş«ÉÚøéØ6°‹dAÁxÌ&b¹: @z7@Íz i@PöÂIòâU}ß¿—’üÀ¯è™ø!‰ã_G2¾yaïµô‚—¬k”Ï›4LGÏSÖD¦.Š´bÇµUÆr)G`8{Ï¡öìÔú|ÀÊ>Wï*×‘Dj˜(/Ñ—ÉŸg+ø³€[7·—¨n:5Şî<u·ü\m .÷>¤»C±^±nB®|²Z%ĞWQëÖ?a¢Ìá[½‰†³R`—ßO®H¬"å ¤ÕO|‡R$Ÿ()«~EÛì-$Æ%À¼å ")½iâ•7
,Åš¯Ş‚©Ø°tÌ€êÈˆâ@2· x*õªìç@£Á½M‰¥L(E1Ëg¢…b’¤cë<Ì¥_à¶ÍJ³#§QÃ_áæ®ú¿±•vÃŸ /tı†Î–Š‘ZÜÅø-z£¶‡oU/'‚ 3`ĞÇ‰—’ó-SıìuáÄoæirLâ©Ê¦KwwXa7­‰Çî»¬pI76`ú]è±Kš.'‹élW³•”şa'd™^6 Ä|M.¡ô¢àŠS—ÅAh¹±ß?FLÊôP&İIV@¿œ¡pP·ì¾]Ÿm_A=üó¤ıı)OXH@ºu1½›"»íÒı><Ï‹ <&ÂåŠ˜±'	üGï*Âä5H“pÇ:Á–x³G`ô`¨ë¿ØøŠ+0&é?}K Ÿ¹t]Œø8ˆ6¥AøJ0[¶¦ŒØ0ÜÁ%.âÌjkû\¬şË1ãçÎ?év‰«WÉîw\p¢­PoŸg‚Ù I¤Ñ¤	¹M$yÒgüãl¤^„@«°ç“K“~d& “w6¶ÛÄ¦‰’^	j¦ s—£şX_ÄoÛiîş¶¬+şkXÛL>±ë1^Á_@(
¨±VõT&_s>u)¾x‹ÔÔLcKî“®mç›°‰Âûİw­W,@£{—‚C2%8¤†m}÷‹|œ—>8¸½Şêf_N‰*ãx˜#~³6³Rªb éŞ:Ü?v“x0Ê=¶a’¿ß%7*Ç,ó®2°
ÖfÕN·W"?LkğÏÜP
¯†!
4vÆğÇÈ"º•à±¥7%{±¡_!	Cÿ‘ZÆ‰•Ğ,†8{JMç0ÈL¯è¥˜Ï§¤ö F_YıËâkÂŠ(c¬ë÷¯ş80«8%ğ$cıDS“µ$ÑZ?UX_aDq@Àß¡Mjvî£ÖØXš«DB;ğ-GãDG§ißÃŸğ½BÑ¹æ_$xÏµ,x'Î‹xŞe…ÑàhIáTEHŞÆ«êK9P‰ÆÁb¸ì“·øV7ÃRÃ®³UJ?Õ¤C°Æöîİ%-~Z–rÿıb:÷t/k‹^ÇöéO7WtÖöóØg´hhø>Õài•M±CQJŸÒª~Ï Aêôªû)Yp‚Ô®@ù¾ôwRß»`|—µ©Má£›Ô^Ú­…ÙÉ­¿jÄßça¬±Í†öùxì q§Eº èv™½øèõfÍ0‚Muh½Ãé,‘OW<F78ò£½U­UÄ5g/±ğŞô<\Š­§Z:]êÕéµ£yñäA T„Lráş0ÖóíçãÓ«SH7fèÒqn#½@¼Ñ4ÔÁêÅÿØÕÀÂ˜›ÏÔÿ< ¢uOÜRzíC›ÃXIÑÕËyÊkÛ·ûh)ÂÃëc±gLXõY¡é+òjk­ï¡Ö`!ĞGİ—}{=ğ¡%Tú|«ÖŸÏày’í®pm9ëé†fNanÖÀÃ$é ±+ú‹Ÿ¤!ÜCÀSZyfØ—1SÙEôØ"“m=·µ<)Â‹>cu»¿¾e²ÂòÊe8“ı‰úÜ3m-èyšı$¹T¸·›7jKÄòÿÍc¥ş¾v§{¤;*ì8Õíâß5E¼÷(cà|gîÕ	ú…Õ®°ŒsÛÄ¯ó`u!=è»mÅ$tcd7TEêÓƒ‚'ÄÂì-oÜ ú6<öušè‚5fY†Õã×­%÷®UfÉÌØ¸6)wogFƒ‡Í$Únp“Ÿ^„^ù‡ F™Dbv `í«ö„äm¾|@±å\áÍe½t‰áœ¬ V@4õœiù[£³”“(jc ÛBÆB‘áP”Úçäáqñ}:‹¦šjÆae‹xÉ_@©À„o8¥bx&±IÂa¦ÿ©’Whú&¼bl«ğ
¹jĞß´xşµØ…¸ô½³ó²Î½h63o09NàÒRßÏşíŒà@HAŸAz&Ğ-³ıkÄ&V¾ÃºÍ¿Ÿ½ƒî^ŞÓNt¸Ğ3/ÊÓ:ÀL±Ï‰l(o Ïi‘OÜE-å|—LV…ÿ…JLá~MP¡•A›Ù÷«ÈR¼“Ş¢zŠyÚ#…Ÿ®³cÕ=€ùêë¯Š22Ò³£yWÕÑ gq_OÇÙ#¨•[ıñ ¡!®Ü_<aØmåø°Š¾ı5ÅÄG@¦0ª-…„ì¬‡:ˆuÍCˆ)~ÍGä›~)Âè†!XÏ¦FLÅV!jeE¶Ïñ5†tËMŒoñ„å8vv'iUÖû¢ª¯Ÿ1~¯ˆÈÂ—²÷S<A{(‘q~8ır[Ù¹á¸22­Ë0ıålÙÁş4CñçÍn5LÄ([d§Î8²ÍÒQŠ2i@óå …N}î"°x·»Z­MÅÌ ‘Ûl‰ÔíØàvıœöb¦Gøñ]
3î–Ékç[ÖÆL_ Àìğ‰8}ĞS¹yT`ÖTŞx]|òÿglÔ$<f&P±mÉtŞ2ºd, ½™/ï}ˆqíõ	RÿA š7¿…-‚w­¶Vª2-$E6„*›9yWÓ÷Gpå‡Øş²Û&À=·m×{»µÍ6íÉÔÊ*’‡¹CıKw§´f¬.2A}â†?Ã†`óÜiğ X¬jFù}q²ŞJñ]ğSÜW‡=„PØpù4Ò¯I€2#0Íûwü)/Ó§°ê"cmEe§£W|4'dCŞÉOxŒp^ûë=Å~\ZÓªIk©Ãš÷dI–#¥ñÛèîlØN[´S¹QÎÁÎQBÊğx—®{ısmøPïeaõ<p-¹Ò]›‹¯3*”-;ÆÈIÇuÈ9dM¡¦ë©¶{ü0üŒ]ú×òƒÃs6LEND)gmÒ%:6Zƒ¨âe‹¬G=ÁOÊ#&AH/»	H·Ğ&ûu´­ÜÖw¤¿‹Ú]ÑÜ›Å(ƒQåüaÌ_AÙøàíV&9Y‡ßZñÎalì‘!Rw@TĞ$‚;ñİÓM(!1·™›¦R}íì,%]ÀDv¹NNP=÷uŸù~j"œuÖ«€z[Ç—"à6Q}‚$3,SÆ`/àÊw9e}¼¼¸¶IEjŞü*’’ş5ôŸéDõš½AçcXój?AIõ[Â%â2Û¶¯ºÑ.Öş?HKì\#/‡Yø„d©$°%ÁA	xyáC–9´JŒOO=³ÚÕ”„¸üÄÔ]Æ§øC2>qÕIıgZÎ!ä??®Xˆxóæ&úYKµÛ9IÖK‡$©|±v·ÿ\"Š¯7¯›^‘æ«¢¶ö}/3€ò«ùú”[Åu|;Îá•Ø¾b>Óàü¹ÙÄˆ
èX^:Î÷Ü°Gûœ•{Só•G—üÈ³ÙP3ƒÈ^Q}šà1Ùˆ.fúY¶è‰.§'r ?zl¿æ‹Pe‰zGÀ°	*TøX¥¦l¥†
ÔÜµ5!ë™T;Ì’zû$§{ãç5NÑ}v¥—Úìîi†»¬)*0DùÀ×È­(±Õ4GyŸ¸CàĞ]Á‹aè™6Ä¹ƒÇê«ó×}Q_P)`<hÇÈ'Éğ¿qÃ™<&&ğ2^¡c
oa•‘Ù›u-üwou\í¯<ÚJ¢ æ»®ŸJ€õÁ$Få“öry-opnş¼²ŠÚ9sà'û´ª£KFûN²¬1+³ÓOµ2ªm¢X.¢Ó#´Ò0/5lŞÎn5Ôf¼x•Î¡06tIŸûñ™yZ¼@¥eäö¼Ò$ˆh0Úüm)ª¸YĞ;Ùá3ÆSb¸d8`¼Šv i9â§ïöû(pÍ¿Ô¼ğ×»Ëq{2d6‡)¤;üñqLèêˆğc'GU€ä`}÷he®©Kâ²†ñÆlìtEË§›0h@eĞëo\»dÎ­·w GˆJQÍ ´È€iXx½±Ägû    YZ