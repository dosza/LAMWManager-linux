#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2289957929"
MD5="64fca68fa3ec874881a9e01c6b351314"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26504"
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
	echo Date of packaging: Fri Feb 11 06:33:26 -03 2022
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
ı7zXZ  æÖ´F !   ÏXÌâÿgF] ¼}•À1Dd]‡Á›PætİDø³a9ˆªSD/µY)øz1Ëüm\¯˜ş·&Ü‚¡hqÏŞ‹úµ\0¡Ã:µ
Õ+ú¨)­2ÎEK´|oZ;Q]bşp Çã\”ëç’İ'ø’!ö6.AÅÊ·ó*	*òŸ»_B%éúùªp{R\È9ÏjÊ4 ÒNIyÆ$jÊ‘¨tÒYé‚¾âx\&©Ë5NÁTn?VkØªT*m?×Ñzpºƒ¾-º2säMİ>£Á9ûæjŸ•|ä1UÎZF^¤¡hvz«õ×ğ5TH8M+Z­%xX}K£6i _ëêl<‘¼Kq¾K«fÇš2šÓo÷€öŞş²ÍºíÜÜKúOx„vN¯f7;’5²Ù¸±\„©@s:¡'±{Z˜Ä2ó#²½sÿVÉš*RI¾T³Hß[¼ìÎ±•èA{õT®GœAl^BÚk{®6„^ë‘Ü2¹Q©î®„¿â™²*ALºpˆÁa-¾;ĞÍ–%J,àà›¼Gş*Ğ×Ö ªz
…c‚$©{*>ó™5ò*ÙøsÜn%şr—r’ÁÛ¥Bô@* ¬iözŸ“e@/Ùñ„úŸ¬ûlù"^ŞÂµ(ç­ì5/¿<ŒÖğ”Ôv\©êálŞf& ºûS?+kğø !ry§·!ØtfaW—{ËfÉÆH´/ƒ‹¥%[£äád3‘ö¡Ü8ádKÑÀBJü¼yOsÿ…_Za®İ¦@*ıŸÖs§Ê?n¯«¦–'3„)Zv’•Ë Ló’ÂHÍÕ~ò/xb?Àl™¿Ù·òRá	>@‚^ªÊa0õÉáäëâŞôĞÏ
!Ä€vh"’mz ø©«P%GbÌ¶G¿Ï>ËÀŞw7å“XÉIú. š\6FÌ`gùçpÎ$ĞP’ø33,Y•¬3qÎˆ\â‘½aú FÁKr%€ô:ÙëÈ7êˆú’co}êô¤©ívŸÂSs‹¶&ê& ô÷ÂêğCœw¡pâåÂj¬àò3»TgılYCÇ¢$‡.Uİ„!¹_ÜápaMÙŒá¿ŸI€Fé:,d„İ@şoŞ&©Šj £DøÌî…>”ÙÇUiK»f7Ÿaô;¬1”O95¸Uôå²é¤<ı}£´¾¦ÖÕd4û×8€nÔp'*¡|ÄÔ@™šàÕX_Öáêç ¦’cxÈı^ £uœ‚G^¸—ö¢yJ‘š]õJ´57íçœ×L½¦j\ùÙ÷ ‚÷NqÇŸHØÄk½¿ø¹ÚAµƒğŞ/Ôµié¬§X©Ü ¼3íœØa`÷,Fe>ZæV?şUxü²8d@,¶µ‘–(fS-v*÷ÉtÆİÒrS=Tˆ«‰¥gˆA5U‘çG1"Xë¡#$åüwë¨îŞc®%DªÂÇN®ÈÛì…õd…U©a©™¶ñïè³F³´.EN„<r‘”('äJ)‹Lÿú<V¢ªĞAd%h:<EÏµ Å¡\‰Š6Vxş›0¶bæ[Úó\¯d=ÖBíóú«kš˜lØ
æó¡0Ñ¦:<$‹Yú5¬ş†
aÅgğø‡0>Ó<oõ•¼^R(æï|ÌÏÄÛø5™,(²ˆZaÄ“³ƒ2_—áí)Å‡ò))Ûé:ùÀNÉ+„s]ë°ã5±HŞMêïÿOÏuîDĞC»ÔÚk#sÁqfÎ½¿‹ÜS'º£Ù×†«w•ŠÖ²œ mXD¯iShTÁ’¶XxæZ¹Ï­”1ÚJcùƒfN±ñú”Åj¾‰_-r2Ûç {)ßYyõg’
|6Õ}T*ÕR­¹8·ªÂäw¼ZUXdn©èfşPŒxûÀ¾ëèË±m¶™öˆåËe@«PŸz°ÓYD¹yj¼A×3˜Ÿİ3ë$ÖŞqÍl?<NäØí‚„’5ƒ¿°[UàcLL4Á=Ô]ˆ,>~µOæÆú+lõæ/À6¨ÁÊØ™ÅÈº7¦i•¼`´e»Ò}›¦`µØ–½†SÈ:ó¾ÿO8öŞ¢rşCq2ÿèêJB—{Ö™_ÿ±¥'KBŠŸ6¹M{JÂ‡ŞÍFÜm‘Å‘ìM_HÚÃĞš§f‚_:Æ4ƒÉnáQ<PF~EIAPp¯ƒ/ MºÏ"´Ì±6?ETYH Ü'¡!…æá¦•r«øÌGÃm¤eÆ:Î·Q‰æ?µÁ^í],…»-©,À—˜ªN½äúT¼M;\…J	;)i'Jo^§§ã£Y¥cö®iÎáB-°ŠM.Ğ®K±Iàç¾¹FdPôæ³!,rê¼•¾ö&}%4XFãKˆW™éášeùS9ŒÌ¾“ÏejÍ·$0bø!'Ö†²Å@&QÌVwö†Å “©ÎWPá‡Í³6k u©ë´OâÏ]©±Å<l85ûk
ÚßøÀ¡ÊZ0öò›“
²?„˜ÂœúšFæO¥Üä—õ'[RzÓ×DpâÁL‘~ƒËhô}¾×„ß†Ê±Êß´e/äF¼DÁ¸XŸËï¸ıO*‰n=ÿ[Ç”A„”ŒqÎ÷³6iZœ¬íÔ©»´Yú­åî¨¢´Æ5{	»É2–¸VºÄ‘ÛW°ˆûf¯wJË’4òL<äÇ:Ô0ÿƒaå	ÂC:Z„NC¢zæ4ûÿ­8M]ª´P…Û¼4¡/?3ø‹l¶„Õõ™^¼Pö$ÿ1ºê”÷ûRõšº.qü¬P$öp »nvÄœY}Q¬‡mUE•6¹#¯VJĞ›Ø‡±¶/¡'B{°»{ùzyp·&o7×€âÀkû(Û‹1°] "èTP?ÈU}WØ?İY}V/6œûík% Îiíúå‡<U²t3 ²ËJA˜o>ÍÓÌeÛÊlÉ«B¨ªµÇÇ¶dšß“5ø"íøÖØÂ‰˜U\¸+,îwHøR´3e÷’Œ`YÅAà˜Kp7sµ,Ï4ôj°hììö ÃÌv˜çvìU;äÜbíóà MÚ—am1s%‘u‰¡ËoêÖ¯SCY¡0Nöè	íô'í' EíÒ<ÌßEÕàÿçSĞä’
NÇÔÛ&›²­k`ÃŸŞ1C×r|4fë£N£•xƒì‘lÍ[’&CT ä7ãÀ"Ê
çš‚èGü=BŒ¦°U÷ÊÈR[ÇÛi±M¤Öâi\[? kvÅW{àÎ‰ã	 (`¦İ”ƒeıM8&%eáş¦Ö‚’	Û²†
jïa!¬,÷ÌZÇå"lë5HMÅk*w¶TÚóˆÕƒÆ_ïåŒõ1Ra‡@›LÂAÔh}tåò¢eßZu¯¨VLŠmö@7ªB´Ùƒ êâDZĞÃ"û·DAçrÉÂ¤Ââ§Ê¨ä¨U"ëõ´Şó~«<İ“@şbôoT¿Õ|D¾–Î¸qÛİª_ÿ½|« ›ø±±tx BËh7ì„iŒôRııõe‹í?Æ•°êzùÉMp0İšÒPŞ˜oJñ ©hºÎ9•XÁÃÓä}wï!Ä´©’˜.t I+	¢{¬²£Ó^³%»ïÓ ‚Ãì~W•ìšğ{9şSHà+Jx¦ÒÀd{²âYGY…]Å_.™y¿zâ@(C¶7¼#Caƒ$×3ÀØJ†9T’¨%JÑ×	„Ùî |Î§@$Ë”g»`!(Ôÿ¯Ì`NÊ çµ	RK4?y{¡ôjÁü²@N™xGï±Î<èÕŞö“¯7d‘V+‡?$FŞTrO<p =j3ã>¸¹]N¶yä¬‚lª(Ô©›ôÙÙ§ÿûöbÆqÄîHBú‡³<Ä4%ÀS*)Å¬*èG¾Ö‡­¡¥:Ñ½ÛÃ”šê+Ñ{Sghmê\C‰Š;Eåpn—“ëb¾‹™A+ó}"Ğ¼}·&Œ(móaï6MµÉ7ª·Êö
|GñÆ©Şº]ä23é Rú!IIaŞ)ÓÆğ°ïK`f@z
•¨Epÿu5Á’°™Ã¸x"ğì\wöŞŞ±³}Ì@X"‰o–ò\“K–…CÂ¯_´_ö`ÎY[åçÊ9½^x5>Ş­7äõ+baÏøÎªª‰NãYW@À¨ Üé?àTğæ„^¶>æĞE<ÁŞUq!P-Ø…ÙU:İ34TÃ™	'Û5'@·9OËMrå2+W;M¹Õ9­9êJåqÂèfŒÇd´)ÊöFW5‘}_P:¢’=‡èå^øgÆsúÀ¨z²ÏxÉ@™1”Äİ¼5¥·~Ñ1¥nygÿ_‰üa‰øÉû¢‡8|ßşa‹Æè)²4+ŠpÅ‡UdÛL
{gÿ>€gtëM'I¹V	`Vÿ›‰§ßKá]`×Ù
íç™ºÃÄÈa`OA8››8¹ı#º½¸*Üıô‚ò`€Piï$ÌêÃç,ÍA¢æ=£	é×i ò[X#'(Å‹3Û¦å°}¹…Nê±ßúc®º#JÓv¦=6ú¶%»Ÿ[?ªÛ–Cè¿ÜöĞc;™WîØÆdò_`ÇM€^"w˜µ_÷%.¨|Ş¬KqE)Ö©šcıÚ¢2.×±\ZY>Kª×¢—[Z±LÍwÔpPú…¢¡š(«è†ğk6ÂK¦5ÿì…?1%¬Ô˜Ãqv¾ŠY½ä’É+£;ıA¨Ã®Ij§ÉRî>Ğæf£„İ˜×§T#b¾„|<n¡ù<ı-ù'Î›ûÈf.æ0î¸$ò­,DJàŒ¯v%È27ËQœ¤Õÿ‘bûÛ‘™=áá²Œ÷WŠï’*Ã É)=èRÊW¼U¸½Zió,‡¦[ôŸ³µB¾ÿñp¼‚}üÒ)Ùˆ®q=5`£$vÑQ¬€ĞkÁ“$~Ùoÿ¿Qyö¶+Ò'cö¬¡­ ã•?%ÕPÈê¤riFÚ¼8eÖ*b·¼ä_SA®Ë×||m/ÑºÍvá\$ÜßîÆÔÌ_0µàÔ6©·À©ú,»}—âÀFsÑRûUØpüÈ‚ ıkYUU³W	ïü¦y“+ı¬ä¯¦±É1Ÿùñ¦o*ÄÔ^p)üÍÌk­ıŸ_Ínyøˆö°“7CV½‘q@8œOAp2[â«nT
fGƒÌ;?ÃOÀ}Õ 
OÔòÎÚUNAj›è¦õÒ˜¼fõ·.%,3¬„2'Õ­¹›-8ü±B0°É6íP«~¯÷’ïÅB+Æhñ²â9PB©QÎm®Òg^Y<hŒE&QœÇ7mìTö#„yC	AÉhÆmšæ˜gÕF'Ç° 3Š¡Y¦_U]Ø2e·ñ¿d&$.Ts:“v,ì&hœÈnR.ßçÎ™\5+æv—g¥¤š²<	ôhzÁf)Yuƒ9¨Æ¥ßçwÅSƒeØõ/§±>âDV¹ÔĞjÂ¾…‚‡ïÆ¾t_¶ş\|#‘Ù™•¶ßí2L€¾?ğ<²ˆäÑ;I¼$§]µÃÜ|™›ÇŒì¨Ôs$‰
¬/ˆ™³ vBÁ€Ñ‰Hc,¿8E…h›x_‹›#,[Xrö’ÛŞ§¿ôÛáú—OçD¯*qûrNM¬¥Sd™ş½ëç^Ø~ª0où[ºSUq:ÌBû¤:ƒ„Ë'>‡v¶öÆNè¦ªà{°o7íŒŞl€ÔÚ¹Z°øå)úb¡Íâ:•àÄL…@tæíÃC.vZÈ"³\MĞüP¹Öø"Eí|cÇÀü}½Úàjò+“rAÒ¿€¶¬	¼å¾Á-Ãm¾˜–°§pØ¶â†dy‰‘­ìmÇiÁlÄèÚ†iâÜpzPºvyUõYòfŸÕpŒ¹h¯‡!Z-£‹æ#wŒÒ¦€¬
‘÷(ªÖ¯~Z-Ò°ÓÈöø%@w Ùuu’–uCJÙvÑ!Š j§-!®îÌ+Y}2ËÏÛ çÌNgl4À%{ˆV	¡Àü¤Ye÷×ÁÇ,şá'r,@İõÊ%L¥DHÏ1ªÔp*iB¿¥…ÁL”ĞöşêUì„¼Á¯*hu"®œ¼ÅUï†|®¥KÅñ7G›İè‚^ /.ÎDæfƒc7ÃcáĞY`lÓJ¶÷ã‹·ù”Ñà5ñééTÔ?ÁKª®Ë
”BŞÊ_£#¥Èì-¤»Äeë®)9É ™†.óxqÎùxt¨(å§O¸#ÚË2Ï"Çıá¢J4*±»ªì‚¨'‘‹'İµ{\hÙ’ &òÿ)œn&?Å»6  ÖÑy†¦–c…{i›í/r6´E‚¬V ¿ù‰éIñ¤)£Ítß—o{¶¡1)+àÚ¡ıõÅÌbãY¹tÀ‡´SöU½i……=²o²m7êóìHÙôñÓOÏ¿âÑ\Â‰nÃÈã%bO—¾Ğ°å+Ú®O“Dš9„çıÅ{D#üÕ
V¬b ¶¾‰Ñv¬…˜}–G>c™äH8¼>µ9Â™ÇpFñ)c‘¶a¿ç]ï8uTà-ø@OaÓ ÅªŒ§?¯*GÎ%5€L7mÁ±1¸yô€VQaÓP|*†–­šsµœs DÓ¾8[»Ã»o#ºO2Cı‘—‹oji«/—ÈïÅ˜l¯¸Rıgçdk`R c3égéS÷Jİ;;İOĞû¶I»a÷iú²ÿaÛñ»™Âât#8y2iOœõË3œG›¤nª‹ş¡Ú[¾q\H³qlÂ†é€•'ĞåwÓÚú“õ°ØŠtÃåÅ½Ëé„¸`°B¢Åyª±¿©˜ò4gÃ<Ï†:ı0/W¥@®°$g’Â½³Ò2zvË#[‘-w‹_šöî`_“‘¦ÿúÒDá>KÆ–:>úŠaC™Í÷•¬¾  ‰ï]a¡>jTkã/îâÀo±Yi@0´îZÇíÉÔq6}(?’W·¤ÛEkÍŠjYè`¾õĞ(ÊkuIo+¯=“¥s@óî8u‘7‡¶©{Aø¯=A:¸PîöCÈ°ß”§]X÷G³İ;°QVK·¯<}d7CŒ”‹İ”n­ã9óYøå®ÆfV3š+ï°ñ´¼ÈT>göÙ?Et­8»_Z»9d8ÇÏ\&ÊhÿÓâÊõÈ§ÍL*‹ŒÙxÂ	lˆb{áH·P¸RªQ×^¤0@Tú®6‘ö»µÁ„”‘Õóbâ››¸‚n¤_P(JÛdq(P`»Úš,½p¾x  ÷›Àä«jmèªŞÛÊ3§Õ«±-¹}‰Vá¢ÉIçœ\#k|A"=İ:¼øVyugŠ³ĞR'i†×“â³1Ç×£Ã¿ç…´4ÿ¢ôÕ¬ÑÁÿkÁ’¨æŒú¤×ËÈ‡š¬ ¹#âa¥ÅChõ#ô#f½ñbAÂ	Q5=^l¹“¦¤Ÿ_Ê;e·%Ù'ÿä¦#ì‰˜xµWup¶ªR
‡òT„·—Ø›qİöIGÇ`‚BŞ»cwÎ‚/OÄl¬*“(UŒñªH Ÿ“"¨ª”ÖKÒ!'ÑX±ò¼<¦`.›nõRA"Ìg slÏ\`–‡£¾§s²™'Û¦î‡v–é3ëÔ%ö4œqàŒ‘ÓäkAsH}öÈY{£blÖîÚõ­ÀšˆÍL,3ª${â.ëÄ9§·Ó£Ûé¿»Ø+t{+õÎÍÁX9ÁŞçÈúY8q>¨Hµ_6Y­;C©Ñ›É£@ÿ^àkÙ;#A’HÍ”¶İ†#Za~NvÄºÍŸóÀÜöÊ{A–dXE1Úr½d”3P¹š{H&|¦™G§İÚ c×6â÷ƒú:z­à¦ô^ÕBªHH´I	~6øæ·—Ø›!­œ¹D[vÊPt§MKeü©¹­´oÇpV !âM@ºGM¸_'İÀodX.v.<Šy’Î¥¼p~"G…¶P‘.›,"cå“ ›ú¹¿ˆ0®ŠÅ¬"ZıÏ²¡ÿcvã³.òê*,>U¶¼k5UïÄhéø1Rk¼•p³¤öxŸh\)v°ã<{ˆ¶?¹½¥Õ#´7o7ÂÈ‡7¡Zè/èI7EÉ§PElÒGMö&ÎMÇîàÇ¥Qz¢sÀ¿x¯0# j9Py„WÍ”»>Û[sù£ Q”{TÁlËTº¥mÆDĞöÁPùí‰ÕA¼ÓòX»}ïœ½^µÄúºŸIÿ/|é7[ æêiú3?ñWw‡5L:¾äuûBSfèlfòo«³ó¬DJóùÀƒq/Dh§>?ÄºµqÏµ…ëÎlhYšöfäâ9›#°Dõå%ã·™’i¡Úøì,¨q:nÎ 2P¨Ò3²Å(jÂ$óYc D¹c‡ùü'V[ì;›2%M/7]Ìùğòˆ0 !£EàÖ­Ñ§µÓÖHq@Ia%Át5ÿ™Ë± ÏÇj¸ªn¡Šö;¡J:j/HP%ÆóªW€äk'Xˆ1IY»âf›3Ç‹R0
ã‡&oùv³IÒß[MµAÏ†üñ1 2ëİ¥`9x¿B¹£«ı
hµ±À?WXHëÏû&¼ÄbÖº°ÏU,§`àüŒ%Š¤ŸÛËhd‚WÌı>ÆPù'Ó³/HH<…Xc5p3lÛ‰Íu›—4–ˆC^lŒTB—
hzqšI["Ø×T?¤µkeêÛrÍî©“i˜'ÉîP<×¾ ¥›)½µy+œX^Ü§Ø3°‘\ğz(´iÕüùZ‰ã«ùïrÆß^ü=*i)µªz µ9ÂËĞ7Ûö¾ö›-*bßrVWø*\‰]=l–lÛëÎnšÏC`%!9-hÔOBş¿5nám±È~‹€`l¿İy˜åwµşÎ“)Ü£ƒ*¹$.Ü5Ëtù¤åm^6Òõí7 ÌºØşÃ¯÷„-ƒ)EŞ¶”4	ŠôBE&†İ}"¾“‘ ÛI5ŠDş‰Œ*½å!}	Å¿ƒQo3çç¡iTjD®vÿùÁNY3^	˜….V1Ãe·¼š/ÃB$É«^VV8È)ç©kpæÁ†qÃKOºÌ•ÎæÈÙ¤èİÇıE¿MÄ_êˆ½ˆduÙ„ñ›„tSyS÷ª}O=IÔaĞó¡½[Q2¸âÁ²Ú95tĞOïÕõäÊªM4ßÉì£bÕŸÿ§;OËÁaÁ*Mğ2PCTÂÄ!…w	•ÕæbÇ»¿¡ª™ğV B‘^İûÖ’*Vù	½R…M¢‡ó½Iùà"@Ñ)6ÊNVà Ù¯pN9¸ÇlrsKôº0ƒ¯(m‹U5¤»è7_|a/”¯wrl&ä~œÇ_•™…ÅÜÁúy¸{ ô{¡‚4š/İÓe@ÜÜOKHdŒKZĞğ~Ù»¶ÀÀg€\°Ë´©èÔ¥ÂŞë{öá¸ş›· •ë8OéC2È¤	CÔu¥iøî}9õŠğvy(2¦wóa†\#*¯˜q.x#n‹‰……÷ Õ×–ñ"½(f/Ì9ÿÍUOš°½cTÂ<fJ>ğ:jQqCüı"?@µ¼$ú,rcÏ8:yvö4\à‘šåí9(D:v›Æ¯š¨S…ó¦Éa|ËL¹ZÕñ™IåW’Ltß—¤î¸çÃW+Hêcj;nP¶¤™¨<MpO»%™73ò€¬ÏÖt=hªÉûLÛ]J¶;;ñTF&Œ¶¼‚KìËÙîÎ#‰ÿø »TzÁ¥šk¬{·û›(G°Ö6 âô)cE)¿’›MËÛğQ1~•A76[tÉµà‡ÒGE0×u­ƒºøó>™ày\pn`7q/ë7 2# t)RôpÛ7@|]æ0]…q¿Zîˆæ»ğ¤VªFø(=÷åƒšâ‚Ñåf®Xº†Ôä2&bJ¨	ãV…,:[’ÒŒ lk§ÎÎk&F
ºøvVu=s’it/‰e 8,
!A<³½½"ò@Ğ‡«=ãòxÔ óiÆ[2OÛOÚ¯}‚ƒŸ¢Ú(„Ãk]èsˆô6—EòcØ–ÇıØèzûñå7ö¼ @‚ºß,Á¢ëòÔ¦ÑNòaè#*©K]Õr.WòSû§òÊáÜxt&êó°Pg$¿µÙ,Ş^Ål–ÁPCƒ=#éMKŞ¶¡‡®TÂçô6#]çÅâ‹(JÁ3YeU\^ùÆÏ°5Ï¸ó71+-IÏw$—6g’"íô”UvNâ½ëHG©‰@AÓ²±ÔfŠıdãøôè¹Ò#>Í#oW&R¢,RwCÃ»Ê½Š“ ptÎêaI3wS,>®—uÌQm¨bEp7D#T¦^î<\®Ï\}Š°ñä½}YÂOœ'£ËìVeõâJ&2‚”Fn4@óğ^<RÉ¦Á¾GíğÛmôw—œä)}-ûĞ_¹õ’Ğ-{CV’ãÆ¤_#N&’
52àRØÊ:;M`„Ä.¿\cI yŞĞE…"… r©ø>Ciù5²¢I×1R‡'ßæÚ«÷‘Íw.OK÷Íò0‡6Îİ%ËÆôåy0‹œä$òªF¨Ğ&Ø%k’éxß™mª‡e
jÎÇ¹Œ€ÿLE¯”â	ÖU êé6N):M{…·E¸ï4“Ğ³ÇèĞ˜XC'pÜfºòş›¶†„ü–³jJN`+P¥~ö}cåÂÖ2Kâ½–²Õ0Š)«@™S¿!v¡?f¯76v~9Ón‹ám|Öâ=%ÊZ§ñ¨b‚‰ó )SE[,Ïà½÷Z#B­³•—RÛ´²ÒÔñ¿{éqE­¶mçÊ–Åvá¾ĞÛqa#i`†=s•§=ÄÌÒGF€s`Â’­ú	¡HN[s.À[	®€¨<)äâˆûõHûİøÂB¬1åë*Î,T{o0DI«Ç¤Wd¦Œ%6&œò¸ã›vF7ïÑs!ë5S(¼ÎÇbµêˆ $g2Õı–oÄ ï—FgÛã˜¸{oÒ$=`r´Šz	äñ&SF¨º½7º!ï±’Ïv
Ü	|İ­txŒ$–ì_7v\ß%ì
å¥~œ®>vLøGØ%³ÀÁJvñú_œ½A‚¿!ü2§i™Å¡ÔÁSºPv¸ˆ5H¯ÖU¶-@ÎHì.YÏâv'¯ié«=]‡¬•ı7R.Écº…@n¢ \ğŸšêäÍğ²2gš!qOA ¤×)èÇcmˆ ğ»Ğ§@ ¨\H),,ıdm38~ïBDN¯AEÁ—âƒPBÃ›=£J¹öÑ»y‰"nÁé¡ÔÄu©ü3ÀÆşÄmİ‡ÅX °èÅ‘S‘ŞbĞ_Wäd"?ï8"àĞÇ•<ó×Fc¸µæå²ËMôVTèİ¸¥b³+%ş]ÑHëdrgA Û¢ˆ¢1+ìß_½îìa¬®ò
åb—:Q~ír›¤â·nØRDÎÜ’@çôbaÔßÍøx	BÌ–ûã‰a«»ÏsLF‰Å$!œ
{<ÛÌóZZjX•¯d¿Ç_¡˜¯6ŸëåêL­p_3'Ä–Ã!h•­vß¦f)N™Vr.ZŒ$?åçƒ`g¼=-îSnÊïÆÕ¿ tºqr¡’'z@0â6—áéN]2ïû¡hYãx/ğğRV|×“—è	NQÀhlvX7üG­µ;Ğwf&—7a!
6mƒî:á)r°)œ€j*×¿iß”!òzv®ş¢ZÅ—>ò»«rá]g”ö$ÜÊßD<V:°'1Î3˜ŠáĞˆw,Âi¦wOlNª`­1Á¹®N¾h±U=ôTF¬°mZïŠ†:˜|şSO½"TãÁğìëĞİ•ê¬?*îµ°ùªà×WæM—C–:>bÛı¤£n‹¯ì¿™×†šPı`ë¡ÓË¡FÒáDáœùï+Á˜ô9˜[¶×(œ3©!EäZ[ÖºKqÃI·Î\ö„ı®‚$Ôv´ÂÍÒ“5™TÑ$-©òCupĞKŞuìZêÜ0û€ıIØ¹V÷BãĞ^Å
µ6k¿Š¯/NrZ®
U[’¹L¹ ¡Õo
_}?%¥$B;f:=ÑŒÇáØÕåT¦Íº¨&
P”@’rš* #’P\S˜h8ÓÅa¡µ–şÍŞâAJkƒá,à•z´âGÊPq¬X‘Ã3°~aÀH“Ù´÷ìâ°|{ß#®£X´ëêœ-ô¢å®šEš&êYwómÃ¥HYÛN–°‹(ù%Cæë>D¾'’M£G)òÊmlXùÓÌp%/øû	ŒqrŸ”N]¯µuë%ş9CB¨cnÿ¶Ë—ñ¢ËF«™îÕÔÉ‰;F¿tÚMo¸îóĞhyö_½â.½i–àÇÆq¬Ò\Æ±Å;ƒÂÊ34ĞºfsÆ8z–Ù"Rª$Õ˜,8§“ÀKH=ÂæØĞ¬zş0k´;*?¹¼!‚Æ¥ÁC™`£6à ‡÷_õxviû'n¥#Â7’½Zã¶cÑ¨ªŸ±¥í“àÒ_P„È—jÉtAúìüÜiZ=|^q€½Ó°@ÎQÌ•ßäùQ®w¢àÎ{¤ÓÕÑëQM·/ĞK¬ƒ„$O
ğÿ¶£Èö¿$j™Lí$«´	›fPu:	©ôÒ<¬„lÂç™Ñ²µk"€2½qĞvom¦O‹ÛgáÁZk)]$H6ÑX `mÒĞĞz9ØJ¿@‡ãí€…—§}-ÔZÏµ2sôÁé«€ŒµåuÅÆÇà]ï~(Î™OsÿqŞ©Œ>'1¾HÒyÚY—­¹â ©*B><?4Şœ_·Ğô9ÛÎâ8½»tIm¾œw/Óá€+"âlÛĞßòìo9²wYÆt„.ª”CÇfùßõ½âO’r§+ErbÇgmzòv!'/ÃdYÂfu¢šqÈ"È÷’ñÙÙ\(4«8>ŞÔ–Ş›61®ãØ€œ+@GùŒ½&÷KõÕ™¸~Úğ‚œRM¤­uşÍÌÜænÆ~ñF’¯g-Õ–gòæµ¦HşoÂ…{FµCG^îúº;¹Ïº‡Ë=Kçô÷­h¢~p½óœQ>u8A¸Œ{
j4OyÔoÄ‘I+-â5zG˜	6ŸÄVaõ8*¶ıLªøŠt´ÿ?G¾†åÃ…rúVJãœ9z¸KàsøŠZ2çÌ+x÷¼`¶cA/r<gÁaÉ‚­ÈbÏšŒ'ib0ÀÓ0òWÑXØZ´7y7Ìâ¸N¡LD0ì?.uy»ÇœĞÄ’p ê_“v­–¾…JGuF!ÿÁ')ˆ¼£”ÀÉhÓ·Æ,†bAÇÌ¥ã™N©~0ÄÇméÁ¢€«N•Èd‘ €wØ?úC^j.uE¥
ÕîıŸ@ÊŸÔ›YS¥'#g¦|?8–7KLKVÄ€:Ú=|<X˜¯®ù5£ºµÁ›v´
?ä@R`0°ğ\ˆIU9Ã*o;¡~‹Qk3R|ğ3\-Qâ©ÔéU–™¬Í1gİà<÷_>şw‡ø#JŠÛ›í8HœL=€±Hé1ë”€}´Ä~ĞÖÉ÷^wÌUjªš³ãÃ½G±ÄY\ÈÏ,¦'	$Iœ ƒì¾ìF¶Jç9½¡o4‘d‰WÕô†Î­2PIz'’ç©sOê_Z*u•hXÀ²”<7RWşÏ•ë#ÿö ­î,Úßtñ[UJ’¬äÓÆ·ï°»Ş}LaÙÖè;QçU9GÁºë€b|r`*ïíÜß‡çñ¦ *Èz!îI r8xÔûMÌ0+g#Ü)VÑk}<ñğô¥´dÔÊNÒÌ8ÈèÈ¶hsû‘NF(<¯şÛ…§ô˜¹pôér=`ÄŒ§»&F*×Öò‰¿ñà¼uïiúğãErP!¿ûªÁJHeÆu×T!6q´Ï“>HÖÚi†dè‹wVƒ¼-
2lÔLÄm§@cÂÑ¾ı¹r›qømÜ8¡`İ~KezÅC	Ã ‘!¤ó klş“ÖÑızEÕGUõ7P…ÿîÄÿhÈS-½GëXÏÜÌä7OAú½Ö4¡îÏ}7±d÷ñ?æïçæ‡GíH—&f0X‰
±æ¶­³úEkvËW	îˆ‘¨>4L¤”@Mœgíx¸)TO±·9'ûâÜç/â7(W¿h‡¨fqÔ¼ØóÄV“ë¢¶ ×Şr?½hü´å`ŸKı$ìÙÍÃeéû „“¯Z°áB(•CY·|–ºµó1sŸ¬Ï;õ¤ê“2èbzëUì¹và®¤vË›àıfM•İ^¹´Ò»ãú±ı6âÏ¨tÂc¼P\¥K&İ$‡oi¹ï}´,Ãª–z)1ibªÒ9
¦†kÀÃıœÜîd¶ÁÂ	<†İÁ=çŒr4Ä=¾¡ÑoãÌ|I/cH€0#ÕÔfCsÂ	ÔA„êjT:V0W0;½:[âÎï´¶P½\_F Áê: 6³Ô(e§2KDÊ}"Êñ–(©	¿¾Ä«wªEerob¬5ş‘b‰E…>c%lt5y*³^ş¬Ø‹æ#b©p6B¹+ÙF| +"+²4´ÂTtä	«€Àv_Å=Ä¿ºzZ¡¯k!9&fyİ°§% ÔÙJò [¬H…mN{KxNtWÚC+ƒäjs/{Óè¦1@/rªŒNÄ]:
 &ÎÏfC}á¹Ã÷8‹}¹!€¹’öµÖÆÕ‘C’§\•÷—ÜI¬®H(IçF¸7ÑZs÷möÊÅUq¡­‹”üSÿ•6YŞ€bÅ	ˆˆ†G˜5¥Øz…àMuZñ—}¼cÆiéñU;¨ºbRÀ&uæÖ¹Ú™n¹ªsÍèºfÉ‡U4ƒÙ¸ÂÈ¾1™ír–Ñö&Eq´ÆcÉíbFÄıWR‹r74ø‚á î´ ±ÅUdh©+‚káÅe¦Â>´"4ğˆ¹Ãtß™m¿=5ºvf$U/ã.HêİÍàÅÜÔÁşÈév/ËšŠgT/L.^{²Æ²‹«ÈIşU ¡Î»ã£®KÎá\ˆ%p8İ(ÎX­º¤kıîÈ1ÿ/µ~A=Y(­Ù2É´Õ_åÜ«ózíüÏÏ˜fı¢¸y¦‰Tš)3R½³—fp.Ut—(Ğìàæ‡a1AÀÄÚ«Ëx“ á"ÙÆ£xùd2ãĞèÑ9Ym<¶£ëÒ¡¼´û†Z{¤©/P´y†N“q8ØòøsL¨lLSÀE ¾ÔşøŒ¬>×A|»‰İ,· p$ÖäÌÚ*ÎtW«B0QqåŒ	~Ğ88mG‘l†^kE;„¦mÇ²¹!N3ÀŒUâaf‡¹ù­¡8¨/Û!¡Â™(µš•{2ŒPî6) mƒâ¨àÎ1+ÌE¹DTur}íèôÇ„¤T×Ug@() |À+Ÿ“‹ìWãD†¥ÍÄšæ§îZÛêCM7™C"^d6¨IÛYU¾:Û îíœ·Ôb¨Šµï\>ŒSÈ—ümÆÛ»‚ÎzÒÖ \ş« †Õ	ØİƒØzØã#9:Ìˆò­EÜ(½]w])ÊZAq¿á±),©’$²`h~NT{ãûíõşn8&Ûq©ĞMèü°™mÚŒØ\Q”ªâ$Êé¡¸ô÷<Q©~Ù¢dT¿ùh$Zxíwµ¤]õ§f˜îWôœ8ÿZÖt9Ø©ŞğXÀ\ŠBùŠªÅºÃ+ÏCÍÔã =§ãØD~ô´%g-sG³¢7JÁƒ‘Ù`ní+ÒÅ¶”.¹éÏ±ˆ¯ƒÚ{Ş°¥èÔu‚r–›‹Œ˜É@Ü$ìdrŒ¤£­­vmê6/™Ÿ«ì2œc¾št`{ã–!Pxd}`‚ñ¶ˆhqb¾!rÂ@ºìŞ45ÌU^bõüMMËõ*ñot®p6°Ë›³ØñTç»òDûº¯ÁXØ	M[Êú÷È˜UÁCF.çıöHlÜ™î–$œµóÀJomázô)g.·¤U×kû9T“búGéì¸¬n©R³”¤Ì4»—XÛuÒÜH o»öˆ2oË)’g|ıâÿ»°#ÒÌâø˜$‡wˆŠICn…ÑœÑÓ^h«×Ï´—ÉMaN7ºŞXï‹áI­ ÒRĞ¨?c–”5ùÅc†ï±¨'œ\®èä<q&¿–‡ Ts@ÿÁ‰°=6)€°÷wÔEŒÒt7W±­v
ÚÉî‰¡Ô0‰Õ4KºTeÙ†Ë&õŞË6.8ş^§ÿÛßikW´ğ"Š@QİŠ¬ò)[h"§t@á¢®}ô~÷¹U@nÿhÎ0XÈ–nÅ¾Ê¹ÌI® Õ*‰¯vs¾5ïòäØœ-ÀÃiqÂåĞv¸«£	úœY³­ìê$ZÂ)*²cÕÇëGä³~*²‚?0…P‡jÙbÒmÔ$´ÚŒ0ìÜ2Ê²ßš6İê”na¸šÄÇÇà….¾¢?_‰r…Ûš€òûw_x/–
z0*°v³¨QPwºô—GÜÑP!\(÷úÏ¬j)?½ƒ¥+5ê€G…°¦Ö|{!XÀ¸¯yÙ?ëz{Š6Y†L²Ğîš¿—ÎN…évUd6ßWøá’£oæÇíÉOI–öŞb'®m€oÛúJÚA¡´²·Iÿ÷Ç"‚,-äKr;X î‚MKn÷NeèÊÂ%4¶L¤÷Y!gÙ¿Âó®Y¸³|Ë¿ƒm°»×¢¥ôOSj%KQí7z<áà­1r¹.ÓÉ˜Tr2¯Í{úâŒáTS–îğÂ6 ±%€ŠÅšIAqÆf†ÖYí8Œ½$:„DWuû”Ş.)g éÃ«’Ä2Çj	-H¤£š‚äé“÷2ü$ñÉh–g
ŞaÂgZ÷BFQŒ¹Ä8	_ÔŠlÔã1¼ÔOe$ÓÕ…ÏXhbßŸêÑ¤àûÚ^›ïÃyA#<6Ë'säï±?‘»è´éúŞÌ\(}’2á«¹SH!“)9ÜuF¯ïwŸQïLOEÙxgÇ•Ê®ÑZÕ^pÄ#¹[«í9Ô»İùb.«X>ı˜‘XF¶Âq¼ Ï®<Ów¼7(E}0cíTûE"æïî¸^÷;©$°1­”Š8±\âA—:¯_:ÅpüÅAˆ·$­ƒ#v6œïø„ğ¿ì*LÖŞ„g	³öá\C#‰XeùÅ^”×?'‘üI7«Æ»©›XÍÚ&Ä¯Šâ§#Y£fÎnÁ­]dœæ®¨±ìO$òz½¶Í…ô!ú1Éâ10q\ÃˆAgÅ[{İÈãxÅˆç .~ŞLîü‰êWÖŒ¨xs-ÕNÓü¿0b¡3E',UÃÚ»šFeáÔ˜E3Ê¦ˆhåîÀ*ëZ­ªâ‚!Şkæ\&ßåùÅĞd´3Q}bc§RJx¿ºù¹%®Í.K¦u…µ1ğo\&âN-äñzÓØkc&qLû©÷?O+Õñ?Ô!Ì¤Üí¡…;/×‘2~u%¶ãŸ·/›l«k´ÃV‰Û$İò2Ëö]nÆTàı~c¾—ÍW%x` ËùzV.ÔlIÿÁAá˜K—X-ÿüëÚÏ•0¼Ä¾gFìr¯™¥>µn–¨Œuj¦tã¬ ‹êp6›W‹O@)M§¼zÁÎÂÈ†Õ› :!S–®Ê6l	Osf÷Şk'4ÅjªÎÇ~§¾D»˜uÅbá]~RÛªg½Õã³¤@fşMÉÚ7cßì CšïA‰	8Å‚d¶ïÜ¸Úˆ/%ı·Õ§mDfæO´@ˆ*ßßVz´ËÀ…›&L	¥¨ØgfzœTCç&dI¥„»j»İ
Dœæ	|Ø®ÃHŒãa£Î®ç­I+8³	Pªºµ ,Æ5‘h{„£BÂòFKi’^èÏ9c»e£€©wÏ»gÌ ¬¤ÆúdîŸ5ıíÚ=0‡Ãf]i’%AU
¤¨_¾¾MDuğ“ÈÒ³W'QÁú‡ÁµÌ8ìÄAdE74Å`Ê*ÜÃõó¢®Ÿ]_zÉxPD%ùsyTØSJª)€í‘Rx¿ô a ´JFéØªd$u}Ãø¾FhGQ˜Íµ++uÅÈâ4Q¾w‘·6¢ä>d†Òi7ëXi/_ùâQâıÌí i¹C3t=}ØÒıÙı‹cÙMŸ€A™ß3×¾I+½êæÂz’ë@}	Æ’TãO†^"®!eİÏ¯BckF¢Í½z=.>X’Ó=è #Iìkù[ùrtêMiùÔ©R>ºOœñf5ƒç‚Y¨BX=€w»¤ŠÙ
<éøl0§ÑÂË™ˆû$ºÔ¯‚]OÚ£;Írï¼‘¸°®+ÎÂ
ó $6•Ôñ†¶#»‘Ÿµ¹q>mh§lWÏÍ~øp!yÌA~$¿ƒƒT"C+#ÎGjyô2é úİğ´ß‹,Cy	!·™øğú–ªƒ].'2i(·Rû±æ¸M‹„T¢Ñ«ãë†Ú iÄßuHbYš9ÙcğûøIbXçÿíHfÌO·!#}œÃOÑ°÷xÊ÷"r¬N`N‘o›ïf&j;NiÚŸ³•ŒÆJm$†Qj–ÿ(¬¾T–£!¹©¢3iì…K»}"í»ó#­7ÖÁó‹k¥z+¿à´<tĞ§±¬ÑAùË2ĞÂKF¼lÕ8¡üÖ÷W‰ÖÆ}+¥›áÙ\ÛKzDRÇ}WÄtPcË'°Ue£ó2Ğ^·°AD“ÕêÆI/ÿ×¥‡uY‘†…îåTŠÊ¯è%i.U>F|Ó¹ãz¢¤XF”ÏÇŠşş<#€±ôc‡š. ¤wùÄ,UGt¦k÷jUNÌu/;G¶Â"6#`€ét’’r?Wà¦kêİ3Ÿ:Â„ä¾§ìmn8ä°§)6´ËÒ¶çŸìÇëÙI¬AÔØ]DƒÙĞíÄSåı²sâ»É¹?4+’›[rÁK)¾ƒKäâg‡;¬öú´ıŒIi×M+5)Ş›êV*‘Ííó7Â‰Ñ²2\;°+¼¯[ ¥}ñ2«ÛÜ»­ÙpAW«/éXîU‰ê÷ïgÒòMöQS*¬fî£1g­MJ­4ş;Ú:Õ=&`m¦tgb:À3«—ÜÕ(d÷ßæÍ9‘7°¨E†»çĞmÂ:ó³|êÁæ¤€ÌÌM|n²7GOêa;	àÄñ@ûhN>ı.H…!Ê*5H×«‰N+úõ8ëÒÍŞpÉ:[ßƒ§¸ì·6¬ ê—Ä¶áî!VR°{dNâ©`èÑXƒ•œsL~&,§y¼ı5ø½<#d±Ÿ©!HÄUGp•	ûy¨db¹|}¾üpÎã&Ahªôx¸jNªt‰x-3ŒqCó§»†*	›>-ÄÂ1Œ”ozj¡Blµ48óƒâr~Š<,.şkmµ@™œZxLr™mş;y‘”À¼Y"OOİS…Zù+Şæ²‡-Œ/¡>_ªm@ùëp“Â%ZUĞÂU˜?YrÔ#ˆ‡é~T¼˜¾Ö@¨éİm¡ığe,oG=ÆK8œÀ	£"Ø´CÙ°©Ä[o€Ëöí‰·õUîÁlÈ çÎ>D÷±á“yt"˜à-½´¼¸äkP»WÌ¿Á‡é k8Æ„åÒ®ñŒ‚³ÜÊ“¡‡w›?q6y¸g†aÜÖ¾ñ…óƒ2Pcşí‘ĞĞt­ ëÅªŠ–,…Íµap 'ÊöÈƒå;|u´Êz"‚‡Â¯Éü¢ûíP©hRiRj›z0çí÷dûÚÃ3Ü•’b\öi?ës6‡Æ¾M©–cŞÇ§¬u§´R‹âMø4·™æM¸°×ÏGQ¯ÜCR²¾-qN5G0«÷»§c/SÌê&²Ò98G‰¡ğÇ+äeÀ9e"(8’ÎC’c /Êyy¼_Õp‡¥t¤èHT_n@l±á–†¿.<î©‘ó<DU‘«-¤7ƒ1ûóØYJ•ÿNrg†V[ÁkşÀòç<Á‰‡oB†ƒ£í%pp×Îˆd§¨æ_×ÜJOpÅhLhÃpSZü D•âËÿH£¡"¹.Âˆ1_£ö•æÖö÷AõãÁz;Y5•[ºË¶Ó7%-)¬Õ¡æÛÜıe—Voh=k+vHõÜ¿[êzyÖ% |ş2`ŠıÂÈ
Ä¨ lÖyR†‹Á[qè,êÆ7F5!7€9ş¡`¿ÙÚXéu¾9™ğÍºY—ÅM°VóäR€Õ_")¡98Ì–ä¾DdIRÒ™%K¿_ü«·Şe±]ğš3èİS–ì§òF	ìó·ÎÅ;¸6‹’¤àY>ôZœ•àÔ,MGİVŞß	çœ¢£bC4:mˆ<Äû3U*²ô„‘ÎÊîô›»;jù ®Õ“Û»_Y»/ıÙ?q;´s¸6/lLßÚÈ|ÿÔ<®ô!<PûL;,Ã/1—}!ˆ=_¹(l@T"Õ!Ó[ìPóÖk¾mR^ÇDHwF_Ó”äñ¯Wáö€O¢q$”&ôX50Ş¼ì&øCâ`Ü_(ò.y`-\‘üj}|±flääˆW$lÆ,:mNOë·k’ÓZ×£‹‚	?L5Œ²pr‡¡¬Yq ñLAÇ6`…ÄR,º|aÚ¸|‰4iHWLúY0±ï9ĞeJ%Æ¢­²SÌ+9˜¹öQıèçy||Öö*	D-èÖDâØù?%bœ¨wí1aĞƒÛ×cĞNÙó½sĞ•Í?,Ò›ôé%QvéB ‚1Z?	xG¼ß›q’$UUN¦ã‘¹XõLA7œËt‚k~’èñH}1ëùÛªF5¢û4¯z'í÷agÇB ?İ+’­ĞŞíµ©+ÆetÎà°-Ïõ
Ypçµ *Äø3k/ÿªŠIéJçQ«x¿³Èm©1·"æULÜsÀWËoøÌí¨Ÿx-E4:ªc‡Q™b4{½ !z*è<?ÓÃNîGl‹zÅBp{fø›ëàR*‰E´5·±KÙÛ–«›}Z¢¦a§JÍ_×æµ¥aÕ¦ÿºbûĞ€Qø£àé›g',·MhĞQ1B¤Ã5Å_|æÓÍ’Úãö¥V°qL°·¡'ni.¸A Ê¿z@²Ià9	û÷Gc«Úˆ.«Ù5¸OJ;û#˜ÀA>;›Aû¼çf·L„%=¼r`Û65‚r†¶iñŸ@™ÃdšN}êtrŸ$£¢ó Hş,¦höã^Õ;³áÆå»İÄ,,ËQîhX·äÃ™*ñÑÃlŠ÷uà~³ÃHvoı#(AœÅ¢rN¼H!\w†æ#,vÀ1íÃü/‹XgZ*¼Ş%pµ_ñ9ëIR™=‰œ>M©4±67ÂÀ‰î{!eËÿ³¿Ş³ög1‹à=±,s%ÕØòšo5ükYŒ´ÂpÖ|çŞ÷»ö%*(¿ßyuÚ}…Xrku)XÈtƒüãœN-¶v•Sñ!h‡MèveÈ„X“N2Müè ­`º $µA(lm,“3ÍÀD‡âÉ”$ªÍ¨ÓÌ@¹æ¶ƒf<Áö¬smÄw†c£Òl$î İÌÇÕ+ç¿Dé°ÙuXğÇ:â@Î|}Úûuƒò™.ÑBßòP‚ÜáPËVY¥æÅsoSğ1	‚‚,ì¨Ú
İ/rütX^Cá`î‹2¤ïÔß+„Á+t“$ôDÈ—µVSªG±‚xñà¿[,ªm·<m	ÿ
26¹$m"päW—ƒä‡2Œzÿw§ªïáG«hT–Œk¡7k§‚Hªèê¥¿~(%O‚ëõ˜œ=‡'I$şŸˆ39|§8³kCM'İ¬İ(_%<ÉïAºüš’¨õU´Œ\Zq’"ÓŠÖ—ä[-ZÜ×”av•$Ğ° œ²?óø=pÂîdQÕ…Ùæîà1x><
XÏáç|ió èW*åsŸâ=ÿ|¤¤
ÓB½¾ÃR+ŠÙŞ]ŠãÖzå8›îğC@°ïÈÑyò,$GælQæq€ÖJdİ”	UR.,‹!€®u9.`èˆµ[š-Â÷7vµ^3[ğŒ@õ	áÊ¸ó, L–JªÏĞ ,r-*™mhnJÖÿDW¢»yâ¶©.şM¢+
şº&¬Å®  #8pùP¡Î×<<BÁ\Wü˜p'ü™ĞZÚXÆü+{ù!¹’)÷ÕlnWË%½Îå’#»t~Eù)Ï !/Y hsŞfº«²6(%ùÊ¸”‡>ƒ¬Mw,8Î6Ùèı9òÊ¦Q1šS¯	"0h•š©.$œÜ?®KN^è^©Û-–Úš;•, ÀÜf¢9Å¸}È íŞ©Ô òdÉ:šó¼’K`8ÔSÜ¥/=­¥è„@èâd¢WÃ=ß:¨FX˜^êS˜±÷º¡Î¶í`?<Îä“ aÈŠ¥ÖyTğã:mÑ§ì0èŸ*¥²Ü‹óz{+p±³ìˆem¯.Ù‹ŒhVë´ëUˆˆb..ùŠ‘“ÓƒsÏè;3 fe’QsÑ!Z51Ñ»âDì['—›”Y ñ[ä4ø)\x´ê -©]wìfH3°Ø8˜ÿìs')©-ƒ¦éTªˆD/|_ÔÂÂø=ğ–3¦—l²æ·…F Œ“ƒ„ı^ğCˆœ0x€¤¿wÄ›,ºõ=5ĞĞúÈÂs7ø`lğˆC‘€éèI÷=”n­›i^›t½¢İÔbş@na„\u;&6f6Av¾;C§u>èïTBç”l"„Ä\ÚQ\9²ÜõüØv;Œµô|jÛ¶@‡×“qG_'”Šš8¬™YcÏ-ˆÅbp¡çœ%+*r ,=	®Ô»£…á&eöpE;!ÖXI]œ· %0GzlÙ_é	í =^”óÅEøŸÃN+°†B­ÉU! `Û„|§±â¹Ä'Rd°E(¾Àè³5óê"q«3æ-ü8DEêªƒ+­¬İÖSöß¼`ˆcGÄH­í¹ •¥¡ç.™ä&E‡“…ïˆv‡lÔÕªDÃ)3/ÚÙËÔ]İVH©Xz ¥ö[ã(™í9+)/p}¶Å×öR$ØyOSuV€ÁB—¨­Œmdayû’5¾¾KÁ&5çf‰œÎÅ 	ö†™+ªÿ2J¡Nz7¾e¾¾¹?7šÒ¸<ÍÖ²ã4ø%ÃdŸé¾E8g–vs:MK£Òƒ•Wãö‡YÎ‘˜ß$ƒ}ƒêÖRó,a¥Âh2J"4­%b ô3ÿÒ!Ğ?ÁÇüIùÁbşï$~4ùá¸•ssÏé%¯{Bwcâ:ã9ÈIµ•¾º3ÿÍ£øÍP˜§ ±_* ¦šÒ¹Ixeˆ…¼=î5.ëCiğã'Q…rvbº¯œ€}ñ†¾Mîr.˜o˜ÖÜæ…Í¸ò½ğ¦ô8]ùºH„ af¡°nŸ'æd”©®oøä^¥74¡?/V¥º}#tŠj˜ùêÊµ-é~¾?[a¨-Ğ§âåœHO˜3´rW?‡‡GE8€{nWXåİ¹sÌ!q¸Á9ˆk×eN´‘'%¢qñRÙYÑ;ç#£…UIo[jÜNnà·„š1½¸ß”D*pŠñš‡İëÿ54XKW|ÈËÔ>Ì¨”*@/s	–
Ò]&ĞŒˆè³èzù×UÖšWÉ.¬ˆ‰Ó?§Ö,;ææÅôìåâ–”†PoïĞ0‡n! «‡Ñ¸%Qåa'c0öz’"èdIY9TN¶,8f%:$ç­E}tÀïII%ÅÇSh§%û¶!á©T«ŠtC2ŒöFşS†ïA¸a³±FÑıœóõq #©ó5†ıò0˜>ÁvÄikÅë?š©_öÅ4O„¡1êiÀS§¢oDåšn.ºâYq
õ|I”ôAßeä!\ù…ñÀ`X;µS-é·¶—È‡úfß%NÅm–¸ÓnñU$c~Š,öşQuHîbò<­¯x¿$ÂS}ì÷Š÷Ô*?ô;3Ü6%ºÅgµàgª_Ê#¢&$&_ìF„h 3•²Ør?«®µÿ	–/Ô‘•ÊğÅwtIùßN×Ô©wÌ¾Ú-²*<–ú¡®¹§×ñ|€(e¦ÿ
Ö¥©ˆv1ræ€©ÙêWa\‹ô!¾‘¦iËnÕ)êşÂÔÜ¾ÚÑ:­3c˜61'˜Éi/İGAK×')yõil´l¦½—cq ”U„à ½ÚBş”¨r½™OˆÿÖ"ÊÑÊhpš‰±‡s0„>üÔöcÖlı›¾Âchöä‰ñŸ*–3ÄV-õÂ%¼M'dTºQ[ØË¤ykœñ~QRÜ”6ÊBaß|1ªá˜Ë,ó­8kÉ~²®¸|–4%ãu.ILÒ¨8?X÷¤íWL˜Å˜Ç€oCìË*ì¾ĞdKO+ùir·9<©–‹÷I*·p¯íîB¦¡«ÚbëÒ—°™×¶¼A˜POGczSá§@ËÇ±€z[]*pÚê-•7IzFöz¤Ûc±_n-ÆmJÏf-Ñ¾X=¾*ĞaPB^õórx^•˜'hMUşWpeZé%Ö+ªÃ¬êIpÂóäDF+« /¼7}‚|ql¼)†€«§ükJ¥Ÿ¨¬ò	#ëºi[Ì´¸÷Çi?ÚTY)\û.zŠ¼Â/Qc¡Dáa~>v&¹c_‡UØä2qx¶?J‚ş‘ëk$ÅQš†çTWÂùî%şÁ+V¯ÓgPe&F?ìnì©öûÏ‹†™Œ6ÆAÒZTİ˜÷ˆ¹9A&ÿzÏ3Efş¦­Øä¯ZÈ%úngØZÀ,Ğùı"öÇN27“2Rã.;âÿ£¨$ÓP­ÿâñ·Ûà- 'ãÀ¯¿¼…IÖ™¦35šÄX(Bõ«¶Üü æÔìûÌkuÿàq,(ZåÏ¥xï&s˜úèé6æápû¾Šô TÍ3öôãı,nívjî.nTA8X#íÇJ*ø 
áq£ê­8}ùŞşßW6#ëf©É+‰Çd5÷5¤}CÒzÙÙ'î¨¥ïÖôIrwO¨ë‡øğÉp*Æ2ÚZ
c-u6Nøc0_ƒ{›–óÙ›Ésg«Mzª}?>6¯Ïˆæ8™v”yà‹Lã­J4@¸5l~¾,¯Eó}g–v@¸wş‚¬‘"•qz 9ZÛX]|è çA‘™ûL×ÎH©9b¥f!:8 kÛTŠ³,fÔt’2˜BÒ3~p_i£ºk+<õCƒ¥Ú+•T“_‡Ë²D’µNu¶çè«qÿSNïkÀ¹~œ–ÿM•³±·™KòÙ–Î“@V‚UsÌk¡–ÒÂÇ°%`äõ¨†–º\ÚúÑÂrË ·Ï˜ÚXšğLôM’3oõ-öİ~ë’Ò!œÏ+³4°ãëğªv¯ós§ÔC4Ée¡1Ç ü9$EÌØ.·¯„kÓ²èwv.LÑj=@iY‡?ïÃrÌ=£âNZbsy¬Wax]9Ú;¾Ğ¾&âIµ6w©ç”^¢x©%cÌÙçoEFÇµâl44¸{É(k9Á^/~ßråò¡ëş®…8ªin ÎtEfÀÎpÓ(c÷¹çµO¼×«¯¿à!É®ğ–¬_‰KŠlp±™COÚaûg«â§[–¸¹Û†¸¼ÊñI‰&8["HY¬•X³£›Ú…X´e€ø2ç ı?R S¤ç2§å>Õ‘É ¿m*wÛ):ötê!İ áÌzsğÙïÊY¹¸œ:’’KC_OÈtè•Óum!í™HoÆ'®Ô×P»1H´2V!ã‚P¢Ö@™Ğ_»\TİCmOZÆ=¢tóÃLš:ò†ø?ò²¨g£~V)xşTº‹Ps;Y—s¥)ó#Õ;
	4‚'œn–Y‹Ã¹yB±*âm’­­LX.•0iä™Ë9‹­4ï¼Å‰sÂ2‡Ì§¶Ögp¢ƒGÌ#Ê-¾ºÀfª7cÃ¤ŸA£»líVÁ—Ær­uÖ™5£ëF­iÌ½p‡ÔØãC#>è’–nÏ£	ñÅòèœTÇ§°@fÕÓPcRË)à¸š½Ò_J zsÎœo>m£ØBp[„7i°*n ;ë±C‰4¬J1’RËDíÓpky~±€Å-ĞÈu1WM»@¥ª”I­}ğ©›öú.ï{]Òü´
·[ÖÌ‘R’…‡8©âĞªe³†°>—øEL$boöÇyÇ‚@o*›ywïG¢
kL
è¥@ıÛÓÂ‰­IpİM˜‘d’®¯TÙqT3v
vì$šŸğğ8™5¦ßÀş’ÔÿPÛìb…l¾öÁÎ©‚AÿQchê#ã¦XÍêgÛ},Ó×%	tãè½¥æ‚6ÊløVgtLê±Ÿ;Iä§!6Xx¥†F»¶Ş×g!ƒ}GGºƒ§Ñi(Ÿ¬gšÊ†xíXu²N•ûû	:7ÄÓ¡R¥•k$WıÙ¸s÷º±s¼šÿP=n!ÂYE¦¾q­ÒÔ	ßİ	SX›îZÕ¯ñíâ3í¿Ë˜ÒÁ"¤7´F×‘âJ%‚¨Æ²¶Ge¶±ZQâus¿ºf›ï+Íf@€n	i¶sĞëŞïO<n½0@Àlñn}u@ÛÌ,ÜJş‰m½ÇÛ—Ôñ¥áG…›çÊ½Œ¬À¡…ƒS6Ü®„Ğj¨œÒôS²Î¹dr_Vöšüêb¾µ:¤ÍÆ—;	İˆàqXÕ•‚Jqa5ÚÚõ”ö!©êQ””4¡´ Omev…Õô.åãHæ;>\ÄàM Pr£ÿkojTr÷G,  VqÉéÓ~¨b+Ç©¹:hšÈÑ1Äº»)(?¶*ß®i§1R–ƒ¥qpxÚbè­˜q‡(æÏ×ÃÊB(”0î°Ù.ì?±Éb0¯º¥ñéÛâ:^ª æ‰	ı<æ$nûTÎ“€„Ë´Ø…Ë§R¢¸Ÿ¥¦ÌtT6Wì

IïİSF_ÚdàÀN[.É£qÄkÆa„X¸µWÆXymâ<çÈ¼…˜Ğ	B/f5'Ğå&ê3o6CŸñÿNÜ·EÏÔÎÅvçİ˜+ Õâ<ÙVFMŞ‹rûÚ¨ç‚ø+%ÂèÅÉµ¢c>öøg§ÕX@ÇÛV§ø_RUFı÷15@\uLœe†h®°hÏG–ÇƒÊˆ"kq^¾c$ÂŠJ/Ç~ÃJÿE;Ğshí'¿'c °šIßõ¥û½xÀˆIÃrSÃı¿:)ä¿âİS¨%î±.¯p'lœÜ–®9…Ne½GB{"È¾ÔŸ‘ÒÎáüÎğõá9QÒÕå¸¹;	…c#ÉeSü%Š¤ï°qqğI¿;È,Aºñìø¨)¡·Ír …T%Œ¼c©;ÄÖóèO×mõ"­½7¸NÛÓ¤X&×Òì™¹ÈÌ¦XçäZ¶MOœª€"¹tı™kaò—a]—æVÿÖÃ,“Úv‡‰µ¯“F¯ïS´ØN^ëŸY+fşmˆÎ>ëKŠâÉÚ(OÁm{{Ì,áÖôïi<ìVl€ú‰Ğ»•mÜÜ‹@`W&üØCcÍ<áíŒ?,–ùâè)U¦ø1ÔŒ¾×ÛZøb³¢jN)Œ¶˜:ƒ®îşëÏ*@ h<ï×Û$  ˆ4ıê*¬ÊñéÎ«ò
–½M:Ï¦;M’£±Ü‰K;ŠàŞ€û­>ĞıLsáhäY»¹æ{Fè­«ŠW’Á{>Ë0âá˜H“O×¬;×»€×Qí~§ÄxªÆœ€ ceö²£(‚]ì5ké-«ã5Â.X»|IenX7´³ÓiéÁWÑÆªÂILWÖëC4TĞæ°ézÍSÓİ…>Êà¾5kºÊ%1Ø×9H?pSul ÁA3zQè&œ>0P_z/îy5¹_Oğ¢ãjpó:=A7ÓS¼ĞAn§„B£[+så?).§İÅ ™()&Éò%Èx§Ñmë8…¨c‚(eUtÖHÌ„^²´­µüDxâu0›$Kc Wødú–»iOë¸Ì¾¨æ×L¸yÔœuÇ \•ğPwTv³VF°A÷Vœ£Ùğ	¡|…J]>gÌ4î2Èœ°w¡!±•ˆÛ[†.wŸÑ'ÿDb*>*CïYS‰³‡Îè'ö«ŠA•ÄM\oÂ(4K³‚¾­suÓcrJ&i¢½—ÌTÒb(ø¢İä”SÖfDãI7åÎ!û’ï´ÜÃËîHÁA/)1B\ãXCùËFÍ›%wÏï@R]7/Xg ®å„ùw [†8ça²‘&Tîúî½L
ĞÂ^üh¤÷çîö^EémÅ‡êø I°FMM#NÊN\îëå|æÁ”úIŠìdïâòéB_
æÆİ˜Å9G$dá"\Z=~t^¸d ˆiÂ ;áR±˜<…ÈEğƒ¶òïNp5ã<·±ĞÔ†I»ÎÍÛÅjTqêš*¹ø}œ°táLN™¬0ª6ÂÒN&M›âT49 ’.hşhbBËÚÍ·T†pIn¥.‹œ˜h¡}AõEO}ù'+¯w¹	Ö(êâæÔşe`—`~¼!âò~øÇÀ‚†>V}C¹ ÿ7f˜C[,@j€’öî&º'şóWãú ØldW¾¥E0 g:º¥¹xªäû´³K¾hE/ÛßóZ;Ôz+ÜËƒhñR*İGm€h”¸a–UÁœ“skÔöaÁ|O©¯º³fqC\¸5TG3°²‰M¶¼}pú{$bÁäÊ„Š¯xxèQàù„(åÅ_„ïÍ‰­ 2Ñ~‘Ã¬ÂI˜f–{VÕ4™‡ÉÖÓˆF?|õ‹&Rô£"š¼×c—ı¾ùÖ‘&ıÑ“Q ©Ü’~#©Ê+ë_ŠE§‹¿çnxL"qàu–îô<>3–sÜõ$Ï‰nã7ax[ÜuÎE<šò4©
réŸd“ÓÉEÂĞ3òân“LÉï±Y‡ZkÃÄWÃ)üXä!Ğ9&!íì_ü‘F_gºz·‹`ßÆ^ÂKÜA)0¹Û—5Xã½kãû‰°ézH“ób4™	ví¥d‚"q¨ß`GQ¤ÜÓÊßc¹»ŒŞBĞÎE­‚
¶ôÅU,VF1ó+Òù	pÓapûªïÄQY¥¿nt€Bî €’;‘f¿e¾Ÿ§bvÛê¤zK@å§{»%ğ^-˜‘³¿q‚ã7ã‡3¦Äµ¦F=2ïö²ÂCšıj+…£oÉœu,›Ä°0ß~ÁswgÀ%ˆ¨Ow®ì[ğ *¹¡3Ëé vÌ0+îşCÄ¤ğÀ‹—|ù*‹@Oaiÿ§Òä³d+R^ğxYLÔYk>,g2ı¶h|áB+±h£WD=Ãª!»a-á¯H£MFX$Tœşª4
3~T›Ğ.Iaÿn‚ò@ŸWƒ ßWª ¥vYj¸;nö.DÏX*¹T^ĞS)¸"<öŠ=ª™ÌnVªPh«5›·¹Š9#´íƒ¿"‰ŒSRÒó}_¡‰ZÓÖ3üväá.™øënçÍœŞ2jÆ­èZ9wÎpl%[	½Ñşá>¸^^“İj)¦èßMà–®pˆ’°Íh]ÄN>F9*vµvn‡/c'ÈİÎçXÌ	°.}ß€é4dw¤?ÃĞğ{E¹aÿ‚ğÜ~¨BÖúö>KINU¹K;Å ÉÑdÂ¿ÛBû »NkÌ>Å“vBĞôJÂ¹ÕOH4:eÌç\XHM€qOá¢éÖæœu9ïe©ÎµªÇjâE§ŠM¼õj'Í0ïô4Hƒ>Ó NKvñôA‚ÁÛ•B”ìÑ\Qş q‚ÌAWIvâõ '`0ÛOTF‘ùÏªÛF{h³÷iëB6nÙpq¢È\‚şb}rôòl³\µŸğDËü‡ÓQz5úàêüfmH¢U$Q(‰²ç¾m„î{B¬Ä¯gğ›=¶a½j™Ôˆ«àúIe¸õq);Ğl­gòÏß†²dZ°V#!y‚"–—Jv§€=ì4™ñ9	ßúTã)®úèWáoÕl<ex}¯À,¯‘ı¤îq,d¥I9ë5³şº&z"’ÎÛm8¯ÍE†ğW|~³3"w‘U3£vW6Ã†|È¸~tÇVü£©KŞÕš"¯xjÚ{¼EJRöÏ-*«¯QQ/Ç½¨QBEFj:Î	¬}İ&39Û4îİN9ˆ‡Àê.v\uªŒ|7²t€ÍPô+Àì¤¨fÏhôLğ8½ù” ÓkHO2rå¢bùí,¯Iô’*ChşàÕşC¾ÕEnf°Ÿ¯œ–ŞPw¤‹ìH3ñ ±O¿Ù}BÁŠ¢<1A|?CFìÚBô×yÿ¸ò£ÆÅoéÁıo¥fsP24QĞõ¢™J+†glªo,ÁÉÃ’E”’l«T7 HàØ!¡~E¡µgß´Õ7âV*Ş‡.JüşE°£hXläË÷Z¹¿RÛÀ¶†`X+î¢?¼IPüñÙÎ@L•‘S',?s¼'70^A –q[;àwõ>#!¥²´ó_§åg£A×Ær*·æØñœ$:U?µcşµÄÏo—ü2Q5áGß‚lºw\/«×ÿÆ0òÛJhW§pw«H¨’ª8rlğ›.8äÓö¹ş®à X	ÿ
¼˜-¹²BÑüëjÈ9&¦=öd‡“Cè—-f[2šÁ¢Rö½®,lëV­;òpYÃ°î•ä«0C~:ôÆıßMë^ûÍhuÏ£ôˆ¼w‹†®ìsyæ^0Áª]t^A±ÆG½ğ‹tô’sC„ıõFVøpu%KûP'†;o‚Š¢w°®.Â…)	¼Ê7…íuñI9cícZ§-A‡íöæ&•¾ÆŠÒNr‘5íOî2ìèÜìèmçw‹i'_É%ˆCüNWÉ˜ò7c	Ó‰†<íÙ–ü„»Uµİ‘‡æ„ä.xx…U
SÿÓ±Vf¡F–ZHÏ¥ ú4²7•Æe^ÎË•qn¨.„ÍÍ‡Æÿ-Q»‹ñ³Ø(!R#¥ÑcûyÊMVô¶–5(¼"Gqyé÷H„ù.jlš${9YRG}w@Ö×®Vu’’€IÏãôeIq^¾>úÌ!§é–$ƒŠút†Ü‚]5\•Új79câô,Ìvá[›q6:+RûòÃ¹îã"»º¤Srí–¯÷ Ê’‚ğÆŒ€©b0-{áäÀƒ;÷0Ô©¯óÖsVX5lÄ¥à&_¶¾"M4Å©h½J@3©céÇa_…gè®lµ†ï,®Ğn‹P{q_ŞôÕ<ˆÃÍ7‹áo`§'Œ 4¯ˆeÜ,[T?ú¥f£+šz Ëñ?«ÌåwÎ}Ôq?<éGÉ	ïŒ®lÓSu¦²‡ÛN‚‹¯.àó«óŠŠĞ†Rzò°´ş$„p†Ô;Íš!…7Ô:¯_æ$G’ÖÜDíbT¡ù˜{D²/…´Kşd9Ÿô%#Å©¹è!•Éq©–X×§ª!º=ë$V‹ö™	 ä-õCˆŸ•€‡ïW¾Ñh²²@ä²»yK‘Â5òİ®‡JÙ;·àß{ìÓõ’½ı½;ùRp2h]Dâ@ìŸ‡¦g?6ÔFQ•¨Ñ2šW>Ğh@‚Ÿ#¦Oqïõq>é-€AòÄÀŒ&@®vÛË”ë¦K["ùcJ
9J­7ÛñçCÛş{,®€&vŠ®ÿŞ´‚8$Ó°±ÃBNmp!—uŸã|1q 2-H˜N_¹J‘;G?¯RÑ)ŠØØô¤cé¿Şxë«C#Kõz)(‚œöHè¸“Áµªr>BÙ‘NÌæ8Z¹×boÂıs}÷õD®+1ƒ……ıæz›hÕÂ!'.:ì¾İl£Xw>TCs~ıznÊChŒ+¹ÛÁEŒ¢âÁÎfôoá
Ğoñ­íR|ÂÕ×‹Â3êŸô]ÂµÚcÑÆ‰šïg¨Âù•„R?ÌpÛ8;æ¡avª‰7-Væs¿#¯öÇò\7ô[O‘*YPk0ğ„«`Iÿâ6ÈSŞìæq)@W	²}ú#1¡Ó©¼
ñ8|Ÿö½õÈO‡ï0ª…§V ´ˆïª­>e.Æx´£Z‹Úÿ÷]bí±Œ¤qæ_ ğáL£ü§ì÷ˆüM¢‘Hü™1ÏD§şnL?Ë©Âµp-C¦¾É.»âø±ÆÏµSx·Q”V!7 ş'Û¨qq[ÜMOÃ×ì¹-ë%ÇŒ¦7WÁu2œÎÓ‹ğú›ù‰¥Ó+ü‰…ŸœÕB»áõuü’Ë)ˆÑsO§0VÿknG­&bd-dÈõ–GÅR@Ÿ`Ì)K_e´…~ò5|ÏİÜ”€¸­«®îO|ÔwPä XÑÒü¿T`‰“Óo&*óÈê[J9cÕõ@3´]¦ééL28‡
È >w2ßG……q1©“£q
P÷ıË”}Œy¬ÔE)©µ±Ï‰g÷WeD9Ú¡‰Dõ˜'> 'v€EÏ¢|Ò¸ëåzYå^D`õK`”ç>‹ÁÍª½Ítm(ƒºC) -æ–QÏ/IÖÿÔ›]´¡Rõœi/§œŸBg÷ŒK7İytÍ8ºJõ¦´Ú›Öe*rDWåÅâNí‹£îÎe]O¾©®=k	•ÂL8K ö6ûÔ9è»@¸á¼W]%ÆÊ^¡óŒ¾g”#1±›”ğ*¦TÖòø8µ	06ŠÑq(ËFh‘‰C*VQ¯ìˆÄ“€AL ²Î˜æ²	IRÈ|ÌS….ö¯†z†SËdDzAÕ<.gê"Ô¢€6Gn^;|¥‘s¾ëÏÉÆÀ¥Ü.ÒhÎıÄœÆ(³ìÍô\Z¸ß9Hö¦µ(…›šñä†hé“n±Wñ¹áHeWQO®(iTh0œ~ijåƒ1Wµ^ÆŠWcL¼ïÀ*ÜËŒJp½é¯ït³SËy*ÅAç8Áº
ÙKºDÜ;çRH®ÈÄ—!ÖaC­-òæB’º÷×_`3O}ª–Ì/§D5¡·‘†¹¯õû™9V‘'÷'Ô¿ÌÆ©ÅşóJdO£yÃÜ/üw®¯Hd¡!LqšŒU+WSšÊŠ´Ã5÷‡ mj#Ú°ÈĞ«J’z‘U4‰¯‚š	‰f&Åİêé›¦)wcqÕZa	â¹RŞŸª¸ïø¯‘qüŠóğáĞHØŒÉÉ%/Ó§Ş‘d˜R!ıÆÎš¨£YşGì¹	¿mlÙáñ¹”,±±ï®7¸9#YÑ€P!›ƒ´&^qµ—û£Sû¦0B¸¡¤IRº\Ú²Ny¿n:¼;D\•kQ’õ_{“5OfÃá´hd¼„oû|A–QJ§L& <0ÔòiØµ&L¦¸ˆ~Šw!OÁï;è=60QÆtz!ˆ‡h-¥ï-YÓ²§Ü´¦ˆ	ss 0úˆX>Lªü~X¡¼(ß‰Ø:×4uQÇZ wãšÁÛN°7NWcŞáH´bıK1í:s#’F§é~f`![»ºz]Û9+…<ù&S6Hòyãz¬òğš[ó†èşóšQÊP u‡  Ù'O*ÙxëÒ¦×¬ÍÛ¹=ôQuÂ¶6Ñ=«—÷c‡¸osÅFô_©•8ãòˆ’(_MÔ›ŒèeÔ)aÂòmZíŒ{ÕÑè‰)µa¿fÍzHØ·ã4ÂVcPÜxè'zX¬Uëø¯›KˆbÓİJŸĞ)p×H‡(ê—ç>»DCšøìä2×0ÿrvÃš[œP›Ü”8Ğ()ã¢0æ1¶í™O¯€¼¹kŒ ¨ñcØ[šÅÇ¼+z¢ ¯Õ$Â{*'YjâÂdošRQ©ÆTtÈçH–×¨ÿãz­oLĞœ”«Ë¸a‡–ø` ƒÂ´µ»h­ô9u¥ çPï0~×[±üœÀV½Á6æ€UIİï¢ÖDéa^3é}ğ+M>i¹×è^#r,ÛÏ÷êPUXq–®{éB~ø^wºIthÉte›D@T
`Ü6ÒüT•³ø´$g,¼Z®Óù‡È;³ÿ×så·,TÄÌlõÖ”•B
.r»ğØÀ    õd-Í/¹Ñ âÎ€#Fïè±Ägû    YZ