#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3900580203"
MD5="ef2a89b424216b2f45eff60f38806787"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20716"
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
	echo Date of packaging: Fri Jul 17 15:55:18 -03 2020
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
ı7zXZ  æÖ´F !   ÏXÌáÿP©] ¼}•ÀJFœÄÿ.»á_jçÊ}fKİÆñnU›ÏŸØœhZˆcagOíãÒ‚î›²6cm²[×(Õ€¿şŸkdh[eS¤ÿÕüej¥†3Qï «‡_‚9.æ|ü§áA¿Mó¼BñEYÃg%}ND*­€*ÍÁ÷%f”ğĞ1ÎÉVîëVZ1aÓ¯á%—;³Æ Më^€TÑŠüåä¥&ÏIä°¸3nQ’^-f´ºœtÁåWÚ†`H0…ó’TNp$0âó@
:J¨¸©ì"wÇ9¤Í¿ÜbÃ‚1[û 2M¶ÍÓádç›Bæ–­Hùelä®á{“ˆçŒ'á+{*`ø«·ÀË¶2Äxï¥iø“Ìˆ~ ûëS 'ã Yà¶¶´óiÁ­2ÊzÃ°H•É$¬úƒÕÃƒÄB,ËBh	i¶ÂñÔZP~Ü'šéßğ”h‘'ßÂ& €FqÉ§áY''9õGcĞ¥	+tXÙÅºÇHEŞÿuO8ib|Dâ¢ş<ƒù–´İcu–ÒP²¤õ¸T5f}lgÒRh7-DP\–YÌğÓQŒGD…Ü‡O¥ €—¾r‰¯ËƒRƒûŸ©xÃ°t¨œ
¯Ï“ÒÆP¨ ¸ ^;*ô$@qı¾vä„ ú”¥µ‹ºM…hõÜf&—‚Ö­†û@§£PxÄ¦úf,CN­:(‘Íq¬‚S]oyoÎ¤${ìÄG,vÙÚL|»6IÙwÒR™Áw{§»”fŠE(äÎsNş$‰×ÄñU„,1P‰Æ©¾;é.²²åÔÕ™¸l-öµáIiƒ)Ì† ëF¯È­«w,ØÂø‰§\„3.nòéË±úœ4çÌ•HÀâª©”{zÎç‹¥»¨èAx
×¥%[Wty1T‚¹ó²Ë‡µy’\ßŒRµÛeuÒÃÖhQßŸ«%ÀÕïAd‹cè­~JÓ‰Ìâ	¢÷îÂ+¿§Ş
ŞÛåWíkÈ}’^~ı(@RtÌ6‘yŸ»~
ÅØÓ¢…hZo-Rh0l7*@Ë9n9U=3ËT9¥óœC(¢uâºéßúÌi¾Øå0u2C7ì)Õš-LàúÙ«á söN~”€FºACÑjÁ•XÄdá-‰@ßO…œOàæcC7Ësw·½!	Plƒ=í”Lœ3³´ÛWHØ]CßÆæŒN‹˜[íYüMò`Õé°*ÿÂ_¤Ù'õPÔî0á'`š…•XÑØghëE oQ@”…ÁYØ™AF¬Ê’{@MC!Um§áÄ‰aòÙ¹®P$»ë9ÆúÔ¡•ƒå*…jà°’ø+‘ï€õíDlÎ®F–*(#Où.wÖî³©å‚şÂô—‹×4Oè¤V1Ö
"ğÆ/E’øŠ…ËäŞpnùsú 	åÜ	ˆAıÖ¯mªM–lé±/T{ô>	ĞıÚæBçn:Áó^m5º¡Š½’ZÔQŞâ­ìB–äÓÇéÍô}ÔXo¨êÿæVm;B´n[­V¼d¤"NòÔ7_†‚­;#f\!Eõ‚Â¼[c]µ\Í&6ûE´Ph]ÚÂÚôñé(ıÑ›½Ï0Ü€5:7ÍˆñD˜Œüâ×‹Ûæïn©Ñ‰ø«’HU”[Ûúj__!å7¤®;ôwøXÖì§ö·¸†Ú½âNˆÍ^­Ke«D:LÅ#È“ú§ØËqÚÅÿ«MÚÌ¯§Ÿja
küíĞúñÇÇVşhì€UwñÜƒ+>Á	·¬¡êO›aV7…Úßƒ£A;ĞŞÊ|bƒì¶ÌÍ{x¸hıç0TîÏ;Y9¯w¯M¸ÅaqøwbÑía¡D[ûPö·C¼@XBç*i o3XŞ”¼ë
±]»2¨ÏøÈËğÑ²`J÷D-¾Óewû¿•<OösÒ‡
UÇ“Ÿ‡‘Q ¨c9O8Ù£E±¼ºğİ1ªÑêÜäW1Ë“¾›1Xô½aµ9†PrtÏY¸ôn‰ü¹>?#ˆË§òö˜ÈlÍD:ÍÕ³1ŒİsÈtÏ‘YŒ¦8È5šıÛÎ®¤ç”Õu·)«i³¥¬±)G	ª» 0…åÆ’¾Q®ÇTˆ’Óâ,B!yşc­ÄÂÿ‰q¢À³­åéOÌ÷¡Ù§Ü¥d¿—Ó…ÚêÆì“­4Çàëîö2cFöRº\Ò–Õ€}Ò‡I*<Ğ°mµ¼TiNİzp{ªÕ¥\Ô	
İw‰Âÿ†eim}Uı}‰âÕ’î>q£³{}ÌÖ<%ÕÑ%†Ep;+,íÅ^d“è¹cëªË':BZšFJ{7_é^?µÅ²Ã’™á$°Ù,ñlsÄ±†ztûã¾8§•3™“Ç-à‰ŠO·Mbğñ–_ÖÛ#l5O"[o©²Ö½alúI=œ±ÓÎJÜ~ŸŞŸáÄ~ïb¿ÔÚN ]ód†¥Fál÷-	KÕ{»”©¾Ì«ß‡ùşğ‘Á@P€PÁ$Ì‚2ÓXĞÕï'­NîâøóRnŠÏ—Y/iè¡ì¤ãnoíE9ë’ß‡ãttw”äO.Ycå¢Úç9\)%µÍı´h—#Ä‰;ê¤Ô9L­Îµ‚…_"[öèÙBÁğó}‹s%ä\$Nœ  4™³½W^ôD=q-á›Âİç(ÓHS!d/ŠcéÂşÍk¨tš*Ù{É
Ü‚~Jœ>(ç…»lo„ídLı6=ÛÆ
f“Ê_JK+
1–--Ä^LƒÅg‡)o¦&NsÅ?~-~½ÉÖZ«'½÷ÁZ0û"oòağz[œ­æŠï3ÉìäVœVñpÓj/Öö£xj™iM±ğ¯%ãibùÚHP|ƒ¿¼úµea!¦.jb™@‚D‡ÃÂjU¶[&ïâ Ctø^Ïæj{T “³B‚<	^d¯û—ÊAúnmƒ	óYCHœõ&V¬Áí”À \[Á¬Ğ}îäÏ_‘†	ÇN­eÊØ ñ»9
ü’ÄU…[Ğ¢
eîf,fÿ·Hµ UNjCŠ/„ „17ı>Ân\.×vr¨S×v@A¿‡%UÅ©nŸRbòxG à¨Ş¬‰~câ–×…êĞ0AÙş<ÈÛİ	”Ám¿Ôàq¥1ş®Ğßš;@C÷·Ô›Sa[§¶1µ¥MªˆQ·BÌÑôŞh9«v,“šõØÒcnyW¬¨óa4EYrj2íC×ÙÔRo6ñ]½¹Ç¬ß¢-.uTV7›e£W¸áãkEf9mÊ•Wè0¡ÉnÚó _M´o3xCY9ˆ™Î“Ê$&ú=gwJn±SË|sÔ™!$ŒkøÍß‹0¶¼ŞÕËŠ›7Ş½b~Ü{öJ]Ó¦¬µ§•¨êªóšÎ&Q×(¬.°D‚¾×fD¨Âçû`Ñ´ïzwîİÈL¼7»‹ ùD)ïüìBïªıŠ§p5/ébE¤™æX!’q†Î¿Òò»ÄË6†“gn¡“è«HLÓk3Yñ.É{í+íX|Iy­GÄïîj0|»ƒ¤i…E{Ö†b¦–¡{Á=?7ÌŒ4Ç¨jßg²Îİ™›*æ%ùNuÆäzE£g‡d½îC0U|ôUÙ¬£ïf™Äñ„º4/U2•`‘”V’\:`îN¿9ªŸåaj+ø–¼u¡¨}#üÉ Äß´‘üµŠLLIHóÉä
9\y¦­ÂÀ
$¹ÒíkkC¼¡OÇ6=Ù}şç{»8‚Ò"f%™Ï®Ï	TÛ9ü~ĞUo÷ùB**u"v&º§—,ŞCJ:u:‰‹Ü0Y‘[º})ÛgÈ±ùy(e®Å"Ù†Q@ªi}¶õPyö«‘FxÉq¢İé„®ÖË>€5t¿µ‹Z‚	m²Fûá0–Ke.ÕáïÇKyh3 oítœDš¶ª&¨@Ão°‡œ~–ÔŸä-iV½‰¢:­ÎÑ¤7Jkøe²*ÂoBÓ˜Ô’ó|"SNBù5‹ÅHÉ3—ÍÔp¦5B¸mÁ“Ê-pØ°^‹ü{›®Ÿ4R!R×~Õ4Eóèİßõ••b	"GvÜs c‹]ßL5‘Û‚néQ°à Jˆ2Î¤±8R¾æZİÖîÕOİØ°A‰ç5;Qj€¸>„_XìGí1lè|fLUáÙT2Qøâ V3½º	d^"!)[åI>sIøîï»Dò8	úº¡‹?@SvĞ*î%™ïK'—¬&\égQUåÆ£*Ÿ»A1Ó¨Ød8üÃH—zwX°À.F½Uô_ ³„ééòõZST=Ïæã˜š" `Bşó÷Ó&ÿ‰ ²Ü5÷¦íü¡İÈ8yKkO¼nØD€ó›);T‡Ò¼œhXJn(F'ìM{Ÿ£ÿ'|u4r?²øÅÚÂûØ71RÀÛP	5!8¤»U‰9¥»u¼,ğáVDC
‹¾á}êØB%ÂdL$h0˜¿„øäÔp™ví$µ0s@ïÊk+).	è™^~‘YA™£¿ãˆXš¢wÓ´^ƒ:Y~)È)°%[—Ü‰-8ÀFÀwBîZíNûÇÛ]Ûğ5cy[E²©UÃsu+ñãÊç=°¬•Íµ¦±'£‚¥æÛQiVCH¥Ëj
é9ı~ë2ï‡C×±ß?;ÑÈK=ºV¿+b)­†¹Ã5k|`‹¶ı¨µç‡|ßhÓp"e6äØú*aRx®®ğôïÃp"ŞO|×.(şÆHmö`}oÆØJ62j@p70õw)·¨ÖÂ×<6qÄS°¡%µB §¾‹=P{-™ë0J5k¥„8¢$j¹@ˆ©Ÿ‰Mí6ºó!ıÌ«•ó= ö«@å ÎÕú&.­±ÏÕµ±ğ3ˆû…õ÷1½UmUB¦¤å2F}´9W¥
¦¾€]Ô¬.pÕ¿UÓ©ËQçÔ3©@¨Ş4?ìU¤]Í0¯öÕNíÉâ“å©UŸ Ó—=&tµég®NÁ¶{C}6uÂOÏì}›å	Ş`Õ™v”“ñ˜‚±¸'9WÌêí…‰S`—óÌé¤¸*°2=Şèp0¥[¸ø‰|U·pú°Dô$Ø±pîOÏâÒ+è›Zö€4bÛuÉùJ[™ªâ}CŒVÁÖÖXô¤‹òÙÖQ¸ÃxÊDâ&ùÕRa+ŠÑ€˜|5™s¬w_„?™Éı«Q};ñ¾Ô»œÜÅ¼MoÕ²şe[bõé
\ZÀÈûrWp¤Ù™Ğ/5êS r›-¶p¬îßÀ»’DŒt¢½I:ñ,[AÄê6X÷C‡­ì‡÷ÑGU•R™k`Uä`™Z01¡.‰q†Åm¿;¡¿eäRL€,^KoÙ™¨¸7¤’’˜² $WGCÖÿ<ë’¡´‹W&õ«‚÷0ş¿\ÕÒ²t. ¾…ÅÃ£oÜÙ–Rh&Ú¸GåPè—¹õµ¾ ydÅ–]>çtZ}_ö‚·ÚwlÒã¤z5æ?Ò	nPn wÎD³nÌ~ª,UËoƒLî‚Ù03R½qF»TÚ`HœË8l°Äãd¤¥×6\õ³RÓ>'
÷–iz÷,LRîLÛ¶!:kæŠñ•	Æ"Ã}_Q%´»ñuœğøùñÆvÈ<±‘
ïpS¥î™Ia©hïhş¶Bê7“.›€ZÀé-2#¹¿d“‰ĞPcI£‡*!uA­¥µªÑTô&‘§¤Æuó9ÃÈ¾kë{Ç\#(F›‰B`oì±Å”Çcç‰yš€ıÜ·ã¢8Ã6>S	r[|ñ¤^Ñ}şKO­1÷ú³)ŞNä&ùÚüÏ¯û'Pè-öémõLŸ'P:*ÆYSQr£àÚLyzÒƒc@¥÷
Ğ2İ'ƒ.=V)qô}ü'àÌ™Ëí ®#óûÑµ8„KyK3g@X‰¼H‰ø÷f¯©£aˆÂt“4/IWµŒÏ)Â†Ff¿®İ¢—– Ï$X#/WËX™Èh?™,8•0µ—ˆ‹²&Xï×úİQêYöQ{ZÄüo"$(?ôTOíÄ²“?»¦ˆæ¾œ‡äy,cğ/ÛTß¨êm´FGÈ¾‰HgsÀşÂwãn/Ú€‘_bşßáòWBT|Mã¿ãSİCû©¸§vÎ»Ğ4]èğ=õ9øÔIş}‚6ô(ôÙ‘.‘¥½Eºğ(†»Ûº^êÏ'îğK¨gY02Ôk&}§ıµ‹ô +íŒtµc¬áóãÛŞÖR;´Û¹‹†/$EëÁt±Œ±2óÊ4ÆPr+cÂÕëƒŞÅÏ„QN.şÎ=$VeÕùdZÊ‘¨ÅîŠş	ZAßÇÎúÎó;Å‘¿l#~¸cÓåvÑ‘·d@ßIƒÿØ.
Ş¿Sñ>ÿÃ:â/f¶ õ½Í;‰TÏ¼ìäég*Ö¡ÓÙÙ)ğÃ…â«y V°'N¾#İdºo|XÔ2¨²¹ ÖP•¦9uÅcæéQ6	.qŠßŠ.»>ğLö
²ù_®¤ò¨³ô¦ÃJ.å[ÇÍ5¡RG[Î$imì¬xÙñ]Õ§ni¦è ¾LˆœªËßò^5–¢²%ş¹-#²k¨Ã»¬Gk¾#Ö.IÌzµDèü(}›bíl=vŠ§Wö',[* .PEšGÏË×€;³#ñ4D×<(uüÑFƒ&#YÜ÷K!u'Ã†uÜKW}âı	î€Œu ¯˜òyşôXÇ¼°Ö¿ejŞ\îˆ¦U°&R«KB»İ‰!T’ªéåÔ ¸`¨Æ]¢û‡>¾‚1©ÇË•·yu•ªs~Ïn‰ûiËÉswüNtöåqißpì9¶UÛ±ÅÏùm*¥	HS´»¾€ÜE¯d³½éÎ8º„eÅº‹ìÏM¤_õ¥…ïºåU©¥éùDÏ;ƒ õÑD.¿[&ôĞà7oùC] «ãÍ•‚ßœ™EXòd*ìë]y=ÃVæCm ÿ:ó;õáÙéœV€•w:Ï” Å4¯#	 …16¨ığj­(Oy¥X¸.eˆy9šK½OÖOÚ~àÖ ƒ
ŸÌÑav(\†qÒÉI( 5&ÈŸê¨:—UzÑê-aèp<¿8ø¾¤‘€»¨¤™K½î….o Âû™U“hnwû8‡z;M?³oéñĞÓÄæÌ1Äj(ğÏ)V2‘k±'ÌiŒPé©)ìZe°ş{÷‹ël+Ÿ²ídUvî}÷Ë1š½!rAíÍb•hw¤AÎ‚Q°ÉÊéQ >sä¸éubå»£ŠŠ4È0Ã“¶GÏBÒ8èlò,UşU%·ôWcÎÕ4—øómNôğÆí5\-Ü©¤b÷"UÙóµÖ@”ÖÛµÓ2çÆ38îT‘á‰ÈêÌPË†8¥ä§A.|(TÅC·4Èó)Õ	¯³ƒÖ}dÿ®­ÖO™ –9ju“qxˆïelÖ6t7ä,±Úw¸¼^µ'a[’`¨…H£œ~:ò¬Ÿ˜2IEcÒ™ä´lå#î½e\<wœ‚sR‚­,Q5I’‹~ÜVX¤—ş0´Òñ7¢4ÈZ®cVŒŸ® SP¯ÖŞÍş;yÛLéÎ§‰ÄYšîHåÕoÂÛ„šĞgiZd<ÕÆ¼’šŒå+ÿ@Jg¸Á¾6ñõFª\Äo—Gœ"d ·Íá®¤QFı©B’…Vƒo%“Êb/³^HèÏÉòÆé
ûLG?uâŠ;ì8v„||ò’a–x8¦¹³yŸáI]ÏÖ+Áš7sÄBŸp¾µ¢@Mòæ¸ÚôdîÎ°Ş«6H¥È§=œš”İõØo?½/åÎâšo‡TÕÙäş¹õå4Ë ª=ù%q’ªš™ÆFy7Óó¨k7¾zöÆµ¬\ŞhDÌ]Ôöùtz|+l3õ*Îß|şÑ[¤9äùx™ºoÍiÊõT­ö"èÏ7~o‰‚TJ«[ÊùH‹;×GGu-‰=%ò$òÙ\dÔÜJód©áø•†Ór8ªX'YP‘İÈtEQÅsx“°[â4D”çÒ¯îİ“û¯a/VªÀ$ØOI“/NTkl‘Äßçáz$Q^_eù\ñ‚DkX@ôÍx“Öï*‡e€-9¾f¸wEªİª.
²-ê­ÂAîíAŸywR×VJÖ’nªS”;é",Êå!‹¡`[qO±‹
á_Î°í<­†
QæŒ@2é
±âiö±PñåÂˆênPÛ8àÓºXf$«¹DY‚kŠğ“îÉ€hC*±Y‹?¹CD»€kÎ†YL®ér€F]‰ñ µ“0¡èKôTJ…V¡~¦©,ñBÈo¼Bî\|J¬„“À[š¹|.æ\ª8£a»)6ÎÕ¬Ş`ÉâäÜU[T…ş OóªÚFH‰¿˜<<º&ÅU­õeô‘I )¢¿ú¬ğîğŸó’
îÌ‡÷·İ{
ô¢V=aÎµ(íøÊ'x›±,wTÉ½ÒRc¨÷¨–˜óåáşÓSî- œ_âDì Œ]bpH¨1U×ÄO,m 5úîpĞ¬~ì¾úÒ²LØaü²£|ÃW4éÑË•Ï7ÀHü<ˆt¯X¡Ç&˜‰I,åê/B„êç@ùÍ2†šc‡»ÜÁÕ-D“NùNLÕª¬RA1â¢ä¼ËP“a7äh<.Ñ?ÂA–óU‰K”ÛiÔ‰B­Ëqüó#ñÍ§“;hi¨÷ÿ¸ù ¢Åü%ë0²ìU}‹9“µ†B@®¡ö²ÚÀùù†çk›"90ºí§(‹ãš›oËäƒ§uQ¥üf—¡†í[Ê}«ñ-ƒó	Â×†ùn– Ÿ÷šü¸ëP‰x¶2ï&–Áàµ}Cs,t…^äÇ=°í[ˆŒ‚q‰ÈRÖîd1)Ã%İQå0mAn3ÛCÌÃå|ÅD[`:Ö4Á— Ù«AKoÊ±K©3ô4ê¼âñ6 •Yäã/k“Èù¾zKc	jêqÏ$-êp÷#µÈÜ×ñZ|ú¡|z™¢õÿ#\ÇYùbD€ÂSÃÄ Ç(1¤®sÿdŒo·n×I!ó~7ÂU'b½åÅsoY	b|qà4é^"',Ábá·‰¿#>,‡ĞI‘Ø†ş	éì;§¼ûÀÇâN‘RÜ‚¬ôÓ-¤k„•[h¢×(f B¹d5`|›1º»’¿úáÏĞÂ:x?íg4z|¯t›+Øô•ÿgvÀEÏ
®°®SŞë¥5TöÔœh’ŸÏ‡7±gŸLØîá”/—?‘ıo ŞıÎ(åçšàÛÍ»I ü™"›,imh7ıkNmmŒPà¼‡Ø¨°uÍl*f©›Úºz—µöÂÄ= ¸Ğ^®½Ö[3Á2"y
g.Îœ,VÒG¾')Ê4Ël í2,‰ĞùEÌaâ÷ ôºôô†+bLÏ>ßl!£y`a*`'ãŸŠ×è~ÈB
+^'e32;1øƒ’q^€¸.™Y=qŒĞ©iå£Tù{›ŞÀ©(Ê¢å³“úg’= ı¤ëÂšz£ÅØ×#/öœ—şXªˆ%¥kœuåæŸ9A°¦ßKß¥E<÷ßsÌË©b™hb …+Åˆ½]	À6‡Ô;tŸ$İ&@1D7Ìïo{Óí‹TsÊªÕZ˜âÁÅœõo•—á­ •mÎ„‡–•$bÑØ?óßf0#Dåı7@|]£@¼­2Q'Ò5J<÷åŞ¦Î}¶œšPvëëeÆôøŒƒK?;Nê
;,ğZ5`öbÙáÃHjÙ ÓX÷ïõàı¯§Zêö‡.¬73oÒäq$#‚Ád<xa´ }{äFqMöéO=–÷¥wŒ\tÙØ ğ7GY»`=”wÕTPâ8Ul>aæ²F’ğ9í¯	joéYªvâA5×ıGÆ®ï6‰wgˆ·êÊÚƒ,Ãœ³«ªN†û±–l$ï¢;ş!éV[Y3 Ú°P9Ãnb_ê‹ĞZ×¬ÜhŞ!°hl%#ï ¨[ùÓÑåj<Ñ²
Ü½I	âš±fÉı»VE5–Á!|»orÀìÖRo.J“$=*† ŸSõßH2(á?_Õe9B|0Æ
ëï“/%wDÖè·nX_N&¹RŒ>“Üïú¢4àÃaªş!äp35ã|J·?@®Şï*Às°ï|"Çz¦Ç¶7#tšLØl†’Æ‰‰ÿkãkP`ÿŠÛöQ­é8MQšßª’Ç‘uË¤Í‹•&«à¢†¢o=îdËğÇ æŞãÈcèË½Ì'°Cx½Ÿw’t§±CÕ)omıÒWD]HäÇ$p¬Mø0nDÂQ?ê–‚¿‡îè˜úêÀê‚$ôtÔ[­aí‹|ÿš…ª_ªòÍ]3µëpL`‚°à9t)Èm¶îvË²”—K_)CÄÆ…Üõ[€¬f—‚óWº{**İÑøè…újV9V!o—Å8¥¼f`;Ö%(;ÚÌC,&~ sF'QÄø°YŠS®æ¹GFL‡²,ßûÖ¬a÷ér»~ˆlÎq½‡;†¨\¡Yf³À/Œ^}#êªd¢Î­§ï»qaµ	&j]i*±ïïVtó!µ(¢¬Ö¡F.àIŒJhH2ØÃÊa©-B=¡ I**Ã=rËÒ-Íƒñx7d2sá½—»tÈ¢)	=MíX'|‰0¥¦¢wÅ\÷ËÙ`>ŸMøÍş]¨c|VÔà4c€gÇQ‡¯©]jQ—Ub%ÄÔğ]Ï~¯Œ¹IÂ²;	8=‚ª8*]7]p3%×ÂâÌ+İÿ”bíÅ“Pèc¯»¬LºGÃ´¯×ĞŸ	äOJ¼¼ænà³q¯ÛÆ¼®ÿı«¿‚±Û5óÃ ş´n%Œj•r—ªÈ;xB­ywÜ]j|PwRè¯ië©şğÅHÌ4|®+À˜ÊÀÒ¥¿Ÿÿoø‹z“SoŞ_=ß:@+?*uUÏjî|9ÿgv­÷¸t‹•‹’6SËlòU¦¯—¾$‡Ã~hƒ¼WüªqÖQ°$CÌøB\á˜
Y¤ˆ‘ó¥ñ'°ôIdN8¨šÙÀU ¨esº-±ÃêWĞ¾hæ¼’{üB)
Y'pK&u‚+œüašÊnZ¯…öI2?¤ñUÙ"6»T{gcpC–Ÿ^OXp©í2)WNˆq«¬¡~o•Ë#+Ë·1*_*\+ŠQ¤¬mW€Ô>ò!šä´î‰úÂŸhĞŸÌÖÃT:”úè®¨ˆªRN%
‡œC¦6A=\¼·üİ†évSß­µ\xúuş±"Œó¤úk1B“kŒh_0²ƒÃ _o¶üŸÆ (K_]Ò"W˜F`À{Ÿğ¼‹›×P¢˜›°Méî—Úß²’«ñP8[éz.XN`#QuYØ‘à-„TZß)ÿ*,SvàÎH÷oÛÏüË‡ô“hAŠ û Õ$»›ÇåKbÆó»êÕƒÇªÿ|åYõO¦Ğ]X}ÉĞ£7O$™ÊªÅx‘£ú@ø/Í1hqækU©Ç˜ÁèüsŒ-$éGüƒú]zú	8 ÏPKnjbj"NŞrÃ$ l[ìßÛ†$çéf††‚,o©ÚY8€“ñP|F—NÔ“â!#cSÃ¬m+:ù›È]dxüÔ7sI:s¹1vÍQ¬ø^zO-.û^\ï#ù+Èµ Ø£Êc‰7xÃÃ?+¦5†ş‚7{gK|ŠmçgÉ;_¼—ZßErj[ŒAE‚^Ÿ*Ó¢x/.Tš†p ‹G¥ñG—[boç½+üup]òMv$*aoİ~ŒÊê×så›ÔòvµÅû=Ğ³µÓ€ú¤Ä¬ jöŠ^#)Üˆ°ÙdÌ++ga£ƒ¯iaKFïVÒÆˆ±Ñ¡Š‹81Çâ9™İ	º…8<?"Js»ó3;­PÚIÅpöÁÈg`Š<ì *‹¿,}ZÀí´İG.œ¤nÇWµ^>ßg-Ó=1q\§Ö ¥À"k
¯®ç„~b÷ß¤4Q´è¼Ã7^K¿ÔÈ0'F»™]öD[Ó;mfgõ‘ENKPOÈ+,’
+@Î¼æfr Uô‘ªyHºÀ¹“P#l†¿|OVG¨¿;ñ˜ÂÂì&58v_µÀ„ zÒÑ:±	m+¬êíUº‡ª
â‘¹ád™Œ¼ô!Äà™e|[4Şõ¹ĞEü¦¥o{G<s]âæ"‡9ît­±(Œ™å4	°ìÜÕñØ	Á8Óı7îCØ¾>™VÄ§¥Ÿ¤¸Ò¿R55+„à¸]
å“»JØ¥{EÕGv•uæ(ütœšÒ¿OøÀl¦8"µTïÊüÊ„ßş8-+Úñ‘	>ï^º6üğµ;:ªáµƒ®ªçAGAşT—ÊİCb¦òq8ŞdahJ§xå&L©wŞZw ™ +¦÷"Ëù3(W(fF=â¨ŒŞ¨˜p¦oáö~æ@‘.§9 Í‹kªE[Ó©n[cÂC¸’$ÏM.û.Øˆ0­YZ¢A+¹I:’ô
Sš—®ÃØ¬Á¶/è›Î—<èAmHHñ²²%¿õ
™vBltjrÜ~-í·Xù¾†¢u“¼*°âèP[ÑyærîÌíâEC˜’˜˜»[ô9ÙŞ^|ŠÃK²={^­ó<,Ÿ½†‚¼ ’GT¯‚Óº’k²`<rù¡²§p×Ä[ Yú¸l6.Ô•ø­Wª|pñ|}Yˆ“9v<*ªæàNşĞ
ÆÂ‰>şr„kã¾Y®BTõp:j8;Î0‹²Ñ½!Tÿ;³Ñ¹¢j—lu=øA@,”*Õß±VP©Â¬û½wŒOØû°´u«3åuÜ
}Š»	G©œ5¦èZ‘µÚ#}€…XQ:—PxÖİ&¦ËNƒòåÃÚ«FY²5˜Ûšİ¼r¸6[îBÔ‘ËƒçI²ÍjÖV¥‹ö*]¦ò&ßä*†­BH/Ìûw“ÄöSsDêË›.ˆDœØÑİWï¹Î‚®T‰©ã¾<†¤jâ9Ö[~+>s‹©q­ä)“È‹šÿ‚‰'Û$›\8¢ÆÁJ
EC§êúØ8‹è© Ô¾sN4ŒP¦Ş¼I«[úKWœŸñ:ë<<Š<)«@Ët ‰Ù§Úa¸Ö[&ş+¬ÕZQƒô¨@¿›#†é‰À}‡@]­ßaa2´±“œi˜$Ø{m•‰»8¨ˆşû`€ûG‰xë|èŸ:Iÿ\ß·#í|3Eò%ÈP^ÿ¸¶œ§7‹™²Moù§¹³}Gú˜{)ˆ3$öE¿w‹…yµóˆ­ÌŞeÚ4m\zìF@o¼=²Áöİwõ5—ûPAAœĞÿxÒ²ÅO¾kô¬Û:uÃ[k€¿I{#S]0Á—4¿*±Vex²ô^ğs§¿aMû;” _“aix&İ% ìÚªXñÊ^¦ç¯¥Q}1éZçßÓSs§wÿ
ëéÛ„ŠêVRtIs£yÕ²å˜ ‹|	íwÈon5DõC½ˆ”Ãq{ˆxÖ†¶U üœµMN>bŸu±¼Í$ÈıgĞˆJÛ²Eªü©]°ÇJ›­r0…Â¹&ï) gÚG¥ŸÕÀW‡Ú™‡á¦xš±í¬J¶«2ïÜÎ¯®:`" †ˆ7@müÕDÚ«Å¦”Úd “Nxå‡o×©AyöOG«æS~0¾¼3mÉÏ›Ö×©jš-²æÒCÖƒ|’´m¸=úrÈäŸ`èÛd>¸EÈR9òƒZ•ª‚Ÿ|"óFZ63d„:È%‹Ò)•+aªãØë=ÏIŞÏ»ëŠƒ.£‰ÌB¦äÂlİâ%	{G½èÎÑKkÙé&fõo‰^2]È-óáĞ-ûØ©‘PÑë~éx˜© -úšôx#LJ`õÕÍşœêèv€ËÇõçô€d}3·¿¸Ç«Ã_]ˆ~~;µÜzZ8±¬Ä'ø³à“*Ù†ëÛ–B™<ÄÚ™M˜Gâó>¹·9µwãş+1VjéØãÿMXo:ô˜u2ı˜$’.sâ¶3ƒÑÕ‡†‚¿ ØËÃ´|ÙL[`¤N¸i48½¼Ñ·_‚  è€ò=Í›¦[|]m¼šYUwÑ´% ËŒ7;/@.Ó‡Šª[§sµq5O•íÊŠ‡£z6â°‚‚/—BùÉ]äm6£×pt\G£¡¢£ëW¼Ù´ûí52Íµ$¦Èßycõ+’¬ìà‰X?‘mz-´ˆ+ˆÿQ¹À;×wqóÌ©>ıÛŸ™?­< ä¦¤]@ıÌ‘T°òÈíÚÖaş¸®ÏïührJ<t/µn€:(» [‚İL@Ög7Ô¬›“®ˆ~OŸşŒZ”ÄEqóªL0‘Íû{Fp{L"ñå	ŸÆ›Ì‘Õİz×"G`)"¿B]•6M?òi+m¸K|àUóîıjôHSF/Í²T³Ôôe”ngl7¡^”ï*sTáçq¸”?ÿLµæ®P\NÒ–fX]wÔtØÏ¤Âëi>âµÙ?tş·uÔ“Èº1†<tb-ælüp*¯7³HxèÖkã¾rõ.o=ÎˆàáóvÎ¸¦­ İ?¶ iEXô­3ì„*k{JræNSÅfËö&ĞŒ¦T.Ìäé ó8ˆš´ôlàŸš:"‡±ù!Ãf¿5:—5Ny2ÅyrğÉ¶ÀVÄò1”zpË$N•@cóïL˜Ê=ú9Á¬Å…½¡ë8z	zmfˆ’~É:*“¸!P››wdD¾~'fë”—É-[—
ösş’¸0nÇ6°v.¢¶aªÄ»<ÃŒV¶ãeO˜6®Ò£{á— L$:í=ÅW~ØÑF'Â3A_(>áãßâQ¾c„êï«HZ.{I_íŸÛf/ÆÈÉß7œÅ#ÊcSÔÿÔ5!ü4CV-‚ ãFã”î4v©7›Õ`K¨ˆë¼ş4S¼Ï8pÜÙ$óğÀ%r8Îxk}£P§
€n :V¨­æGPƒº„‘G÷œ®ƒõeÅ"Ô}d·![Şß“Ò|šÀt&ğÄJ¶‡Ú€ˆõJ'@/S¨ÜÊBğ$è^¬Sh“"Hõ¤­õ•c8è+ı‰œª|ğÑWPn³)ãuZSà»¢wAJ1X‡ãÇoh>ß¹K„‚7ºH7ás±A•óèu(”'g¸¬ë.<‹Å`ôcÙ	…¥Ç¥@hWæ-ûâ·åß«$,Ìàè
–ß<YÃ‘EğİJà&1Ök¶I»ÅğÕÒ+ówõÑŸó"Ã‰î€[˜\Ê™á™rc¨ë c™¿œå17° ÅÇa•Ò1-÷Ö6’}Y"(ğkÕAS{ÆX<á¹²±„š‹÷õİ¶™…|JÊŸÿ|v‰LLw<`ÉPÕçu”íh”øş1ÇH¥’v±Èîµ+¾Q_¬nEj'`SúÎV¶·³;é5ıò¯Õ‘"¿b;ªı Ä8Í[páï®BW—w\$i±±$*œ%aJô£Î¡ÄèÓÙ!Çàşp¾«Í =jP³Ùƒ'ÃU8érEM{o¬G Í‚}{0ÉÚÚw=\J.·XdRûr7QØ×
n/É [ºš*=Ğ¿:TW}½Õ|ß;4U¿OîY€Eğ)BZÿ.¹QÍ¹×PS­FÔ8;=‘Æwğ-œø=’‹ï´Ñiâ;ªšå,é¯–¢1Ş›2‰ïú'h×úÚàsmoÉÿlòÿ´:b*•2ï÷Ãæ‡HIP%9'^Æ,ãüç¿ÒU}‘ó««FÆV74]ESÊXö2g™ş{²xÿeâË¹\=ª½Š`ÔÖ‹mîöK e{ÜË.jr"Äõê=–ºò ^ä_ß°¹I752UçÚ+#1r]Xï«r˜
öÃtŒÜS<Øxã
f³Ò8…XhWJ½Ûœ×ëåvñOn“zcÛ§œàÀi&çv¦Ïœ3:Òu»+€lÁåTÌÏ'Ubï·“ƒ
úf…¯{ç
ÓyHåZ©ŒCÔuszÌÛ•#/“¼R/ÍÙÿİvk¶?b¯İ-°êD8¬%~Ø¶¹"Ì¨‘º±Æ èXŞ©>sĞÛ™:,à XÏR~&}í Ç¸7g¨¢‚}ôúŒáÆb™·Q‘o_#v<bµœ»Ğ¾ß˜ôëò(:n£îD»L›|CiÜÜçŠ?µü;îM±¦ğª‚'¡ç}x£c[–~y‰hcóıï\‡şoÉÑ›m·Ø•äà­›†Bı,ˆô4æi×¢ğ—3ÿé‘ÈN¤­EáGl­-v)ÈxÂ8qZí—o´ÆöÓy36Õ»8›y¸	v' ÎØÓqáô|0ÖL)µ'ÉcÍüÍ]¢—0q˜kÉ{g$!(lK¤=´Ú¹Oğ?y5*êB¥…†wrAuËy»–¶ÀĞÕ?%•0˜ÓLR$•
>KÙIÕ/îÅ¶åLêJŒ1Ùén‹luà«ƒ”[[€”)W×ª¸4w˜Õ+˜1 ºÌ\øàÿ:_²ËñÃ%më z›¦»N´™íuÁ•·>”%ù÷˜ûŞT6•Yß¸ÁP>ŒeòÜ#~–i©ZSóĞKÍUÜxS~)µLÎï°WâÃ«Vu˜3‰Æzˆ"5wøfc	­Q:Õ=uYÙ{&S(°[2³8»ù5;§Éº[zeµn\Šq±°+åçAÁ84jüÚßtR;À”İD+Ş)£—wÑ¥B.«	gV3•XÄ\îòÑ¹w…²9Çn6³»[HUå‡H‰¥†„"™[&}oàSÅNRÒ¶™”…‚Mª­äb,€håB¼Q; ÷‰B×˜¤¤Íc—Ù;ë5Xê(‰
"lq€G²é%M%1îÓM‡^ñÊ¿tr^Ò)ĞÍé¢ \lfvtº1¶ê4ˆ" `µí_Š‰yĞ%và2»Ü/³é.
®WeNpE±$»$¿g‡Qÿ\ˆië{V:åH€oéù»¸½«‘ielıÿq‡2ÇœÂÓu'¿æòFê*ñ™âõ×” +g¤ ²”EÃT0ÃÁè1¹èªğ4§9•ôUÎQùğ@¾î–®ƒ’ÏK
)ñU‰Óı°6Şú¼?<º;üäÕ@Ÿ¢ò}ÆøşÊëò½›UpÖÓ¦”8ù8¯Ä[nt'äZX ’êåÂTûH>J˜Çûñ¾]JÌ“.bå9W’hCWkÛ}5]øGX¬TşjÆcM‡¯-¼Æpv Ô·ìÙ»øßóˆ©ÂTı£!IF¹j¨ .ÕW}F‰À±dRÈ*ûpï‰“%Œ»ëÌCêsĞ¢]õL–[}ƒêòºS ÚfŸn‘›¹ÜSeÜ5-—#Í~ş6"c¾Ü%=‡¸¿õ©Gxo~¥ó¿ú×¨,hæ³ÖÖf×É˜Š¢®ï=´µ¥åíÎÆø­8ÏŠvlÛmuVOz¬cqTÿHÏÎÇ‰ïO[Eä7š7a‚‹A6ecÜ@ğn^-vIXeiÅ‹<Ïj=ŒØ1d¼Š<“T-˜qeYÅ1áå^æ+nmštµe—¢˜Vf#Ú%Pc6ò7Ei0¸öŒå}WáƒnŠ´4K–Ç5ykaFÁüú!î‘Ó6)äË"Ş$Ük­·ÇkfS¨gÜ»jO ù÷½öª%‡m0B#™RëtWdLªdéìiPe­fÑš<¬¤›šş†@"Ô%¾R¶ÍŒ,€7Ï[KSC‘HlCHøa~ô]²Î¸˜Ez€:{Å'r¢À_B™züõp)©©ŒEbI[åwVP?H00h±^ñ®¢)f;\?U×¿ÜÖ½‰§Ê™#®[aµúè(³ÈÒñŒwßÑŠˆ9y)·¯ì^¶ˆ†«9æb“Ä)5ÊŠk¦‹?Dš Õ¶kgßBLYCğ»îĞ~7Ÿx`Ğ„|¹>kÙ¡Í¤6Ì²±½Å¶vs]U5XƒC7ÖiTå88Ná=ìaÇJ¹ÏÙL¸éR&8æúHÓàèZ|<Æ–t…2Éb‰,òæÆF%Ş’q=9–P‚ÖUßİ:3—e[m8»„m• Ûk[¨,…à]Dœ$¯sÆóM‰/37²=@h;³äV^èU§‹€—LAü xfå!VXEÌ`Îûš]¦MÖmİõ¶ünˆ÷['ÁÄQŒANíZ) Çê@/Z·D@cÊ1„©'Æ’r—,»Vûã7Œ&²]Œù÷¬ëg_‡”îßÀ:MÓíK‹î¨.7†øĞ¢¦_}œ&ªçµÆObN®}uÒQ¨€JáO·`è¨nQ'ıÈâ’ôwšÖ ØemY€*áFš)§Py)jRáÆ:1‡—V%ßtÎlBˆZË·¶Í­Ø’‰­/*j6â­¹´Û±º]yÍ²"aØ{gP—IŸxA=V ª2®”oß„ŠFZÔÎV”ï·qu/£~t ÒèŒ÷ø×°+DGÒÔ0&Í4f¬İÈ„õÙ¬#›Õßu,#°u×£5SJºú‘i¿¤ùĞØV¶wÒÙ3	|äWçlŠ`“zB¤™óx-tqdõâD:ãD(’Şu´ßùj%ñ^…ãÉj™+‘¡
ã¸ä{_Ãé½NµÇµBF¹ä?¸äìNá+§ÌÌ§I(,#N d’îRñb™^Aö0ä£|g(H[šs~U!¡:‚µqİPÉt#H ¥Q¼k=DÉåŒ88H*lÄğ,Æ†Şî[s!qEÿU¯ÖÁw¶(?øƒs.éSƒÇ‹fHav(c•È™’+•Ø®,-”‚‘3ùäÇY zN€½‡•Â¨%RÎofkKD+ŸËÊßAd†Ø˜D.s>¤±n–Õú\PŠA›‡ÖÌúÑâE3÷=lÄğû•±ƒ‡×µ4½ôæ6YpÁ†AÕ¾>lU ¡’¾[|îzk¾Ü<˜Æ³w•Ì+ã’W -ı·ueìèAŞ	'œ©AtGô8äB¿«‰ÀÊûC¶’¥"~DúÀ—#ÂšıÔÌ%Ót„í†qÒd§ÍÀÂÎJD¡C{é¶¯¨àä:J3şuÃ?Kë@T³èÏƒÀ3Ëš›Ïş½¹û"Ø¡ÎÜ®.Q\¿®›õÒrî|SM*¯;6)ùJÏM¤ï±WIìÌx<ŒÓTÖAZ`¥LŒú~bÚjgxØ˜VŞP°^ˆ$Š.Mº¡x‰[µL[;iÒ?1¡×¨‘?åpnU‘?VÇ4sye\Š¤(ÂƒÉ`¹l›/²GB¶Neç°Rù¯ïÅ×°Œ´+œ3x™§?™pØ•@u¨b¦ŠÆ"Aºïëéhsz²¿×Ã¤è£IÊ£ç§è5îÃSz íF¯íù²:HøBWösoæèj´c‚^óèµåŞw´æj]•kUÊ`¢ÒnŠAùyÓ¼`ãPØ¸Nu«Pj9Ê\”ZÑ¹È©ºÇÜ.Æ×Õ98‚ğE%ÏØ©“\\¯+Túin¾xÃ!cZª.ÈäßºÊÛŒğ‡Mï"‘y ß9bÌg9ˆ_Vc„ììT›8ÄÖ{iÚF´K€RÀ½Æÿ§ÜŸ‡¨Ì,¬Xª¾!	”#&ÚóAŒ¥{ßw×.{Z
ê=è€å:µVK0t
@]˜hpµ©XÅÜa:Œ×k]0´ï®¦™_mJN}ˆŸš¬¾"¶àEºhĞp·ò3™WKœDÕjrŒ)"÷A?³ïÎÕ¬½Åî‘æ'µg‡:¥Ú²q´WN"÷—íÂóxK=¨noŠ.LV&>ÑDzÿĞVàD‰âPF4tßÆÀ$œRÿdÊ£ë:åíy_ dÔglBú`èhÖ7Üú¶¦s(ÃñÄª¿Ô¥¦WiÉÑó^†Â’å…ÃME¡é¦†bÿ>;÷Ç±Ä0ºÀ.zµ',\f ôê4UêUÇÃ‚l– ª¡c1Xò{5™³Ş Îc×æŠÎ´ÇêNuoA9ÕëAÅƒ¨˜Şõ÷á¢ı£ôƒÊÛuœCj~…GÅ|°ğÉƒQÚ¿Õk”6˜­21-ÑËß(W²ÅÍæØ­F|jíl¸Ñ†¶€ÊäaøO!¢3È|û…H‹ŞV¥Oİ­¡Ùš}¾ˆHmÙTõ\ôô,ßÿ^zÎ9;¤[b„ÆQ ºRŠ|h@rŒn÷£ö 8à¨ãÙÿß{³Ì6šŞè6R/yÏ–ÁáÅŠçÊ'$ cÅ²ò‡®ÿc¸ÓlƒH¡¬÷W£#"È#ğub”Wº™ÿE"áÆÿm¯Ğb–VBØ«ekĞ!Ğ4“#±l	@{	ÈÖî¦‰¯öÇ®z:}>íş¶ßÍcHq¢(t1–.İ×Şo_ïuŒ‚<hcşeø¢åq ë0±YQ¦®ÿI° ¨ÉNaõ4şôaîÄ·‘Çwÿ»()U“¤Ós’Èõxå¹&¸€îØ¯öuµEİWØ¾ô–¥™¨Èşf«†[øã
ºE¾ÂO"qbWëÀáM™’÷“ƒ•}Dôû©Ü¬Zs½ŒQ“dÀ5º†ßsèT	fÎ;„¡•–ç…¨ì«sÉ©µŞ´J®èúo.`â1TÙ¿Ó¶x®Ê
3/ÇSÒFê®ïÙÖŒÙŞğÒ­4 k;yM“w·gP9gØçé‘ßhºÄšp³î+¬ˆ¥ïY¼J²¥ÔÊôußüå2“ûÓ{²ÀN-Nÿo‰m…ƒŞÿwè-´QG$­vu!=Àg˜™§ë»DtG^ˆH¾şÚ.ddQïş-öš`qšB!ö¹ş¿¿ôŞ’İÿ!x&>?jVR«P“8|Z PÔâ]Úå‹œé¡‚¾U”ù!H˜ºÂ•¬˜\¡O‰MÜš~ğ%,ˆ½ŒA7T¦Á1>™¡,çó´Ö¬¨Ã9Û³~¶¢×»?‘¤ˆKûfÍ±âŠ0úyi›şğ¸ÄjU—LwŒ^òQ5UÓ¿A[ùt¥ø=µ†öJ/W¾Á ³}àÓ¼Ù	Cê˜prq7“bM)lvAN‡›aŠÍt Ô+å¬õóõ÷¶J3¬@Œ”9‰	 ]’U¿?Ü l„}(† 0c	Â”ÜS¤š¤¡’!x‡fî˜44k®¢EÔtĞ«Tãêb’h5XÆİpe²3ıë?¦!Dgh÷I™iñˆµ·ĞÛ˜Ô&>¿|W¢‘lã­ş@	ëKVª*Ì>BGT¤êxîİ	Åuûåú‰‚ª©ş1Ü`lµåâÀ–euÀ°DqºØËO¯Ô8 á:1†7kJ:î?a"l…¶ŸÁš#]ˆùX%T1UÀ·î±¾øà QSŸlÑÏ»-ön8|uÌ&ãØ&§GKS{Iı}^«dWøŒG(rlÇw˜q{-j6laznafeX€ş‘kC¶f3J…Ö¡Îÿ$û±Ë)Šæ™‘Õë›Ü¸š4ö4m¸X6êªŞè¸VoÉ-»”•G—3!Åê…RÌG*±óØ^®Ê÷6¶óñ|™Ê>ŠÌç=İÀã~¦!• ´C³ñH2åËæ‹¤ƒıømùzåÓKuºoAcæú×Œ¨®’¤jñ£téNß(¼e‚˜mV‰š	wÇîJH~«ÔÍì^D’
Ö<*&§p½İ	©r%]Å‹ó·Ò¢Õ£şÍŒ•„øO¨5Oêuxù²„n¦oúæ¦‡‡©R]ÿ»ßpE±µœ^,&ÖcToá8ÖÍûÛCZ“(©Z–8.·‡ånÚf„N¶ÑDi––Å¨¨QË zÛà@ã8¯2mÀYB&FafÔ°J¦„íÂ4¼}³Ó+¢S¼Õ”|ë´øDSzşÖ¼æÜâ³í¥¸Åº.X @C.Skëªúz’ñå@èÅ°)Lt*3/ÀëécÂÔÍÒ ‡x ¨B’Ç×*¢«Óy\ùÌáÇÏÖÀ†?às¿ÆÈUöØ8ĞKÙLÙò¼É§a«xGª=ù¯„skÒÃ‹µÇ2Z/ãPRğî Ô1äÆõxæ{a¹¦I_èj“ìwüÙZ^©¸ùË—Ñ'YİÁ×ò6aS.ª"Âyîü˜~ÒòR8vãT¼pTĞ@…<¥Ü²ÊµL²}mùlZLæÔ¦v.
G¾‡gà,«òğÿÕ¤Ø® #kÃ?Æù½:g #÷¦8½V’!İ3½”¦Dka"OY[Ë¨Æ‚bØ ˆY›3²(a£“óWš¦e©'!ç]Aóä²–¡P“±~ı‰äĞèfÖ–¤¯ÆDÊ´f'¿ÏTè-±ßêä·ŒdSQhµ‚ª®˜ó>¿^&’9dsË•æÓª˜V5ø#HßU’ìX´†¡;tûNSl¯"…«'Şà-f•aiŸià" ÀÓVl«ü}ËÔ~ûûvüíÃqäVò¼<~0»m×}LíQ/Ã¤€ÚcòjÂ–¢	„ŸŞœs’ìXÉ¶½Nƒ@Á'2Ì«óIbk&wûëñËá!xÒÂ*
ÕaÅ¸G*këGpÚ>îÖàÓƒJEÜøÿ{tSÁÆwé©>shÙlÙ¼ÿ;“$÷èíHîZ>DåóÌşFñ{MÒ³âNÍgÃî_å,b- Ú*3Ÿ‡O†â)Ü»ĞÔU´ +R}GFõjªZèzßÊ„ä?^NF=ÿƒÏÿ%³ê3 õ’»\!ÔÌ³zó¾Õ'1ı\f±‘0)š’š¦ßùkˆì\ÊËW
Ÿ2GlÊö7@X»Ó"¡
d¹šT8Ë•ïnõ¼Ã¿_VmCáú<í1UîgEr~ŸŸÚ›üYñ~¾Ê÷µx3cÕ"	tS°‘¸âÛ‡b9â,êøĞZ†º¦P%J ø¢:lFhOpKÛ¢F;æòk>åí¸—ö<m½h÷$·{/\ø÷¥)’{R/ ZßröŠïl£Ã“:2;œ„«Ñ.fh‚o"ÀÉøÒ–Û†{ÄA)ø³¡Ä¥öóƒo×aiàdíN¦şãË8ö'ú˜æ\
aÃÜ“š­õea;âİpª:<ÅBã“CØJnÏD)#á5kWáÌåe‰ÜldmI*á—TË^}êUK2]Tûr‘|™„òvI@ëŞy mo ¥‹òúù|Á‹\EVX»2%QˆgÄêèpÈõ#kJ|„Î,Qg3¢[f`µYÔ³yö+Ğ.*ˆ^»§èFcóí é{Á¿à\y¸`Š¤ëT†œÓ¦ÆıÚ/$Kí»şèõ"N1'  v©P¸MÕM’ãlï‡3é&¯¡ßêÖÎ<ÖĞ>™{k)V¿¿—PuŒÓğáwÊ±Ó£„>„=sıì]Kü
ıl‹t¦ÈO}êŞxªŒ®á|Ç–43Ì ¹HúèXæ©$Ê€…Ç?eş…QzÛ¦@†e!&µ¹ä^RĞjåcU<gˆZgæ©½ ÕüğØ†S¯´GÆòœèÑ·¿×ÕÊD3z C3›S+lVµ6²÷x~øhó’—åP¥@’.»çdj£K¸EŸpŸ¶›Ä&¡O¼®±të.t¹àøë–•éô-nîÕ¡]tì·.0­Kt‚D£!Ğ’×oòÁ¨wZµòù¹,lz¢¿È8ÄuPWfïdî¬¦9:È˜q8˜un»iO\/TøPCG‡i`J¨-;mìk-ñÓÍLŞÒáÛUôe‚=FD±€yÿ£GYÄå9×‹•'zíoÎeÆš@ò[›a8eå}mæ#Š±œóşsÑC/z•†ÔÜ¼S,i=“”>„X>Ó$}~™«ôƒ­~8ªğCy`«H’‘Ø
yÊ¥KVUK4v††÷ õ=ÿå‹ œİú´ÖBÙğÃtù3ãRINû!f²=£ºîd¦œ¿úá¹'­Û#8ïGÕ ÜOÇg÷5ç|-é¨a[Z•"‘‘t·ÏÏX-TšÕşÌw|Ì9ÌÀ÷¬­]=[¯¥-"Ë=‚ä”	,øßq`.ùZ¦†ÆÄ
#ªd‹à*ô
H‹Óæá}ôQ:Õ×
Û£ïa,jV‹›m`õ'ÁŸpleH0Ê>K7†©Ë3CI7Ã<BåÖ0W}35¬-.«¦Ñ×|ñÇŒ—7ßızE£»Öˆ´UwÂÿ7d6}©²k‡°%Û˜ÜÍ‘(ÙOY…}cèw%¶ŸÑ
è™ÙZ±kğ-:‘¢Fw˜/iÍC5K˜Ëk[7¹§PÖß:û™&|ÇÖ™¢jW?ƒ.Ä„N6O¤ŒÀ}Dmª®ˆµèQ?nØ£á×Õ7u6¹£-l~ÜÏ:Ò‰ö¦ÍwÁÅ›Á3> WZ@dÒBÓŠxâ}åî>UÊ·ã4ºãh:WßmŒÎaş¥sxçYpjòÀÜOœ$Ëñw±Güã[hÇ$9C¬‡€7FÉˆÿUÛ=Fı6œ·ñ¡«öTı5üe1;©eD¿Ò¬¨Ş÷l_Ò¤¡+)À²°*Ê¶X0Ø$+ãÛ M4$¥»ÑŒä‘òG¨	!8J\HŸ×DéË•ŒVo£ŠóU¢Ş70"ˆ2¼˜MŠßõ“È»ótù£ê¶iN61IÉCE1xÒ¬€S“[ åˆĞ“‘kkK¥3:Ù¶HóC’]‹œ}êœãOşSWsÃIºŠ@>jŒç=ãˆ\Ö¤Óû6¡÷¯Èè–ôşª^Aş³ËÈ_WËaş@}y¢ÿR&•ç{LİgÛ¼°Ì	úÈßÓ0yõÂ_ñn™ÛåÊèp˜«s9Ì_4¸pıZAÃMq±š`µG*\Í÷ÓîO‚‘ÆvÇàZ/DyÖ•WòP¬¤déÎ]‚\4ÅRòË;4pÛšE›9Dğö=ÿåÿî¨4#WT&½ŒRSÏVVát¶êšFˆ@äËÉ¥W÷hã{Åm† [Ö$¢//ßh—:Ïáç<Ì¨D…)¦Š\bDâZìi~6}HÖ5.QKœï¶Ón"*¬%MhĞ§qZ¿@÷	½7!¾Qtšÿ0n?I´kÃ€c­NÕ²Vş¨Íôºú¼nÜ«K¥ß¾YĞ®ı(ÁÙ9„He—şB8„í´‹=Ç x´&wK1DEbcº˜º\ÈOŸòü·ÿÔ¶}„ö&„IFÅ”Qv<ËÈ_hë	îR¿¥F)³èÃ7Ğ±òG–ÒJe‡‹\7ë/¤ã±Qö€ş)¬µjBïRĞ‚àBFÔ&ó²Rutg‹ÎÎudİoò¦}´êmUê1ı?ÇxWMä«	÷²&6¡¤±1ë0Lh9À¬ğÕ¨wšú43œc––Pçö¶ÂâÁ2.oï¼q¢ö–ÈN’¦‚I¤w¤ïçÿ›^Jğş›7Úìu6ºÇ×hÖnúºUÖG%BBÆˆ®Âç±s£ŠÜw‡Ó[zúÒzô¬—pâ§ônëÙQßtq”¼ï©x´iÊAÊüWı1šH0û­F—œVŸ^kÀ@\ENYÀ]xÍ ·nl>'r¨#íã‘ƒbÆ5ölrfbí…„ë¦nİ»­ÉÑñp´ Ôºg5 4´ªAÒ~rNŒdHyDVOà&%åMóXVŒdşÿTt=uª)êĞÏ_ÌİíY çcÆ³‹ÜtNß;X1ªfSÌc½¦³Ó|ÄhÅ>Û´b‚Ôîx §ğ/&: V3İ$,\´ûÄŞáÌväü“„4üô®¦”lâÚï=æ,»ˆvY\w`i@ó*yûù&p9pi\“PJ³ªà¢¯1ÎÜKÆˆœÆä6tİ™³¬XëˆJ¬‘ÃìZWßœà…Y˜‹iwˆºÍt•vÀ°fóåìûúÁD„ütdÅá*=KÙI-·lš^gí“>&°»2ïCÇ(x'b?Fv¡&¦ğÔCãıCû—İƒº)–ôÿd?JºŸùˆ{éÛú¶¬$LªN2	]´‡„j²ÊÊ’pÖ’Æ-|`/ø¢±x¹øüg¾ùŸ2`-)q^Aq¨]â äAMµŞË¢32 ñ)OZ8[õo{8€¥Bh R‡"2ÊJ‘€®„Æ§şYß†¥¯[`_`uâ"Q(\ŞƒDŸèïß^¢%CjOşïãàdNq”€À“78,øÃÚdYˆGÁ<bı,†¶VªUÏ*òÇŠL—óêuVtª…:áDs/"rÏ[ùïş‹Ó‘
!h5#^5(T¤¤'©…ÄSF¨Û'm5JÆ¾g	D¥­[Ì9¾Õt›ğÚ#ÿ»Ù"DªÏƒšÁxõiJ>ÇgdŒa:ÍQ2;µ‘bßh7±„ŒDæŒ<}ÕÄ_
Ô'eŠ<ÆTg.@sÔ4æU ·~~ÏÀÍíOÙÅ¯$\-ÏÄşÏÄŠüo¥¤°5ÜØÒ±µöõåi³ÔUKîÃ½ÏcÿrA5m˜®¢|Á}Ğ¦Nú$»1µW5_â‰íhbìª'„vˆæ}
ß$
ÂŞK¾5,ôİ6ÌbqğG%ÓRsÛ1y=õÙ¡mâ°6‘`ìäÍå˜¥ù:×4lÈK<2u›œ½›‘bX=³şÄ¶®Ü]<ğš6<7œ‘8—j œåÍX,¸j&ldãîLiGo\¡ËX½³,"_wÖqëúó    Vã„\æß Å¡€ ÅˆÚÑ±Ägû    YZ