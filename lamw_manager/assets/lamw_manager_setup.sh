#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3444310902"
MD5="150678665d936679ff06fe0dc368a923"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23600"
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
	echo Date of packaging: Fri Aug 20 00:57:09 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ[í] ¼}•À1Dd]‡Á›PætİDöaqı³ËÅ‡¢N‹“üešp(ò»8ßKMÎrY‰ş¬ ~gE€9‰7h'§‰®y¥ç!Â´#G†!Õ<:Zò¨³<”Ï¨ %€j$)Ùá$ÒÂÛĞ¥¢á”»ÕŒIZåı+­‘%Sø6G–![Œ‘R|Ä±ZL~¹¶nDJJI»¬äÌõ¥ŒpFØt‘_m÷Ùˆ6æ¯ßC2l©–Ét™˜¹3Ÿ¦gÊ™Àoé¿\ë)¼<ï…
T®ìC)t/ƒ¹¦Şm?Ö¿¸¨]Ê>UœYÎ»œó™äê©± ‹š¤©v…b«'êsúGÉ`«§Ü2=ëª™ÇÍ|o¬´Ëz~˜¥sMÙ÷M€‡\¤S{2Ví—:j‡ò	ğ^>R´N4i:Õ}×{ïNc†7"FŒiN?áPeoZë!š"l¡DQİè5î i#´û3¬ßÈD†¡ˆêëõ?S5y#âNm.‰›a™•™­‰1lao{’İÎM¼"¿Ü—Ü ‹¨Óû/äj¥$v-÷„‘mİ°1½s“.+CpÁâaSNq¡Ó¦K3m*›¨œ÷H,l ¿A²qÓUmgÀln{­]V.…pËšüÑ«øB˜ˆ«^«f«õóß—rFó7u¨9´ıt{‚ÈÔ!®?ÿÇÃŠ'iÊM:jšÑd´÷ß¥¥œF²¨´#6ôo nÓM]où&ø+‚§køÛ@ùÎf¬é/,•‘-›¸[9ÖøË¢œõé‚”ö}R7h¢Ïÿ7öZïŸ5t¬Öf±_Y!¾H®wÙŒ¿D¢ìÓ‡š™„?Æ³B—GÇ@yâ…´·¥&R"ü\wåKêJNûv§­ËÉSn’M^™ôîh‚œØóÄ«¶kÖóqÆEz4â+ÁÀ1îEh²UO•IËCÎ2‚Iêr@‰{³ŞĞN0éZlÌÀAöÔÄ8İû´«°±‰Øæ¶ã´ŸZ˜±•A#‚1:†¦
Á£à“y“ ÒVc¬)#§1À#$ Á‘=·è‡´Î€MÇ ”I8&ÄÏĞ»T7ĞRÚc/eHJ"³ªŒ$nÿB j®vVôb½ª¸÷;¨ĞvxİUÏbeF”íå0¤‡	ÃÂ0ØOÍÑYØjÛŸ¡'Ï31-;wÈğ=\âè€ddõ@Äû’Û„=šı·Öíªm¤d|›%ûá)OÉÅuw#Ø|‘sÃèSÉ˜òèà¼™±­ÅŸ¬Éı]j#êÿ¿P7’/µÊî„'l}º0èR¿¦BæOº\ÌfÓm¡Ğ÷²00péàA+ûÂ9¶¥1Bfs‡7ÇùW.‰åÀ#‰úÒC¸}L»â‰X+X%WO®ñXìcE	|@;Pf8rb¸¶P¤’õ*`Ù–dåÿ›‡ÃS|ÂQ_]Wo«.ÎV–$Âş‡äê¼Ú‡á"¦D¦Øì
ø·´>“)æŸ¥üÌÔØv™ñJd(Š…lzÊzCÌ÷R>XÓ_Î6§RÏÎ›H‚ŞÑ€s®¾g0Sèæ~»Êg¢Ào ÕÅlºâKOîAvµwFÊÚæØ^=ˆÏf×ÊŞa«ŸïN„0‘ß>.§õÆDh/ÌÛmSqf=5Ğ²¨\óÑÌßˆÕÑ½DÌ:ÏS²Ê5k—šn¤Îé4Ñg?„0î,Î·Š®†aµQÜµ—TèS|¥+"fª\¡æ‚o±Zyj—>0à÷£¦a	í›
º™¸äÔŸaà0xSzÈC»©Ïiôı·n½å¦&|»ÃF_åÈ×‰2ö'‹¾PÆ¯ó4®g¿I@AÌúlHAïŠ&ÿğ…PóÄ‚×“('gi>ô;ïÎG:ıË¦§¬z¬‹¡ÆsÕÂW€,;¥´ş÷°EdÃ¼ÍåKÙ`ıbU–t™bÜuÒà‘„:Ï:•æ±zœ‹æš¼ğ5÷iz/7b Y)
j¹~¨æqm×€Mñƒ>VJ«L°ÑÓsŒù¦¶ß2PÊ`íZ:1BDñ£³ØÅşĞ28©¦ÅqGï2üZJ‡d¿Hí\t4ÛBNóÒÒaÎŞEvÆÆö´7›Óà»NãA[ ªHkjÄÆõ,9XŸ&MÛİÃ‡¬¹Šïÿv1Wäàj•ÖaÚx¥ùËhr[°3Å™A©+‰pHAäöíúeyÉI,uì¼ú™¥„úÏ¤76ù-áSù¹ Üg¤¨M­îç@ÕiÒ¶?ğ\Àx5*§¤ ‡]ù¶Â›@n	:ü¨	êUÊÂË7³±5¨BE±mM1a÷…¼Ğ™½er¾ñâK« \2™è­ŸÎÒ– rœ¢PËqx¿÷'¥Œ”ğhkìPº×ËG6g8P5\ß©üõí<6f‹\Ì{ÑUgŸ¹K8X›£åÕ?(áb¶JQ±§SËE#C«¦0[XÔß4wù|7×›gí—¥XãÒ;1NÛÿòm­Rmxl»öƒåS¶öß&#¨—èMüıuóÀ7ÃÑ‘Õ4¸!8€°DAãë  {F[”{éWÄWÁ$Q˜púĞ«RÓğúü{Í»h›_úmuátÉé°˜E7#gİ¼¼Qãm†å˜†Ÿ|Øh)•«9t´Ñ$ÊN½´`É¡xÁÈªÅÀiVåb0¦€ö-_6Ğb^µùÃ‚´¤>ïšwî•9éŞdºfÚöSj]{F´™tYVæ£î‚İf|¶+/:]ªFs£4ôÜ«åª¥ÃÍÄªP¸…úSy—Á#c±æ²*8ç
Ç‰@£ï=È s–ç4æ˜½D‰› ‡½w<Í¯^‘†	Ï qEw1ÿÂ7>qŞÿF×ÔpıY,¥ûâåªFysl““*œÉ•ÇVêÛ èÙ=|´hfèıÅÊ‡J:Bsê‰Ó‘°|-äV_ø?Ê½/AöÆ²Ö)Ë´c%É vçrñ¹!­	]íBæÑøÁÃ#ÒÚi%é`©öë%zÂUóÖ¯¥Ì¼51T˜) o¹'vŒ±, ` \`8+¼*oTÿ]İó!ÊfK&ûZJŞ¡@õ÷Xã_W'Ñ8-O_Öb²î˜ƒùt`ù`vt(v yOĞü·)F´o­ceôçŠçW~ñv–)ÔºIÎv0Ÿ›$M5¸w³«)v~kjdU”­$Ú>“€a”^úë2ˆ.c˜t#øXœCÜËí.§ÄN²|%ø{>¬¬zfwßÍ¤êPÄïÁ!6Oië
z)^ˆïÆü‚£[¡şJ0–¸çÌiš{XÏeE´Îdœ/£CĞÀ†J‚@´ ´@ä&O<V“¥`)´Üo~a–”û¡V€3ÒªkoçûÙ2À`‚à0álWq76N…¤@yá¦$QíC(¥Á”±ËISÎ½ò Ñ5îğY’“ÛÌÛÒ¸OJ£†Rˆh“¥:HVn Õåôpò9Â #µsxúß¶ywòÒìqªGïYH‰(ù•gØ‡¬Êf,sÀÅGL`är7ÓµÂëC¥9W	6|
A/‰zHÃ¼Fk:ñ¥™s«é+©-\ÎE
É–ó0•æ‹øğˆ>Ad' â•mu[(¦ïTMQ4.ÒÍ),Œ=àİî¢#Íd¨?ùĞ¢'ìÉj§v:•İ=¼?şB7[ºÂt~»[\B›ºT¦¤ÒïÌû(æ? 5õ…&v~~)Vt½2øšiİFjÆ•3z%&J	'æıaäm2¼ÀMP0Æ]oö“uÛàBĞì¶¦údB;]d?¤rï.'f«¨f€Öá®ÏBhI“«çÙ1‹@«"ƒ£Åj"N6GO¦Hš>°ÂPÂÙ}É‡•y5µÒ²_ÃôûÒ|hÏ‘.ï>ş5œ§Cw¾kıwßî˜Õ»O"àBr;´ZL¡±ıTWHCŠğ\~,6„âùPŒÚ*8åá9kÿÏD–à»ğn¨–Öl†Ïx¨Ã¥PpÅë—Ï‰]Ò/`ƒRŞGÒÄIN+_ì®‹ßHı-ï*yÆ:˜œ7j­q]ÍI=Áti&lĞ‹¨ê£ƒ–¾ANúàLü1oâ)ETiÕ”ºø`'“.°}`»‰l¨½½Yô†SI"” i‰†ò÷góÎ÷ĞvM{Š8—&ğ%bu-æBÂ~¾ú!ƒĞ
Âô°SÖLQÄŸÖ[RòàùdYU
âÜ 9-F64ä=€ÖôÄí¤’„Læ"` ¹5a(fÉ“Éê·ØW[ÆÒÏQ½¤ßÛ	èÏ,O$´çg}¡Î.·|ï^;Sòèi­š$÷yÅ]¶ÑKîğŸO€Gr4á¹«‘ù7²Ã<½Q:™Ñ`c#ñü}ä:úğ>DáZ™O^‚R·6{:‘âpğbnKU™®wDQkµÑO›ÊÈIH6æ^GºÇ(ß0&{Úåí„uàÕîÙv#7Ù`(©òtpâË=®65Ÿ9Í[ òá/ìbît"Ëˆ;ÕÂÇöàæA6UïÕŒ¯{YuıG¤§K"ï‘#5{íÒÒfÛŠ6Œ³Ô²rÇÁªš”ªª+ì=²_{Ëëu¢ÌYÕ%™Öd…0Âÿ“ª_æøµ54ıÌ7}K»E_ˆôìÂÛÌ-äûİ9èĞÂÇûˆöş*õ25U³¥_eK©XŠ·Dx5}%œ
±ÕÊÃnü™!±E(–n İ¢DŞıåPj¤JÀ”%@\¹M5|u†2-0w6%Ÿõ,‡¶³Z'øÎm‡ à‚¨y…^>à¾¨ıÚB6©ñ÷ÓñN†ÓÑcM,X±"Ö<TáEÒ?
¡'&eãŞgSv-B´Àgüv‡çÂŞ†*éºeÇÔ4å÷ÖàƒgHK+B0ÂëXU–E„§¦á¥$ÊÌÀ†‘ªãFideŸA«œ_2$pã±jÓõ{Ÿ	®†ô…Ç‚ŞjÈŒŞŒ8(Øğ
}:È…”ÛôÚL+ù*ØwÿÕşğ‰7kd^Üävl¥'_?"æàOª®{·î9»_EÈ€"¯³avÜëËà³Æ¿*E{^›ÄŠ;ÉCÿxÓ"îÕDm[nGQ¤0<nó¾3Šş’Â_%Ò]#oç< ¶ ‹‰ãoÎ!Z$‚±|l·s¾8›T0=Ÿ±ãSù×w´J!éŞ\8 ºİ.{óî0´5ZZ(—ÕL¶Ø¯œiˆÕ#’beı¤Q¶}qAk\!Íï¦	cu—ë`!41v©h,}ã?ô÷(2bä·@Áö³5ƒòNI·³‹pşÔH±»‡ßE@„ëÉ©Ò0HÇwDü)YŠ›ÃÜb8Dø…Ã”½£Pé?“\pÅ~”‚V_¬ìhz„:|0V ¥œh<¾Œügæ~’=ÙvWÔ?_§{>‚:õ„Œ·‡Tª†À9Ø™¦íÕ?0m lº”ĞTä…«}‘¿ùß¿SŠänù6d,ºãùV,¿!}Á˜˜"´ÛÀ”]ü¤ŞÔ@¶m¦	“œs‡ƒ‹â£1Š3•f¥ÆÅúŒH´È°rÓoò¾oÜ{{ßS‡mÍ8¤Ô‰Ó×Lÿ(íU¯ DMËòx¤s‚¸!öÏelÄ‡ÁÒ¬åŠ™Ãœìq¢¢}cø}/~`iã~°ÚUó½:T=ı]•0/_ ­Ÿ‘ëH`¸´Kg½eÎ¶€º=Æ\ÇµªŸ›Jp#éQ´îÔ ÈŸİx 
¦}"BŸ†›â eÆgá˜­óÿİg)AÖS-LÈ Üf-)Ø8qÆò“µ¹­˜%M*ïkŒ'¨²¿‡eF|5®¶´1(UÂÊè¶l`Ö	åI~n†rId¬U.â{°ÜFe“Ÿõ£.İEÊl2XiüÔL.4KÚ·rÈæÎ3è	L—["¥ÁT:ømØò}CHzJsÚ›'ÂÆğÅ÷Õ(AúÏ©yG˜Yr¹†O+!È1eëWB¹!œ_$<Yr+¾”%û2¤ô„pm0Js;Î;İıÇUÄZÕ?µ6sµÏmˆ.À‡µVï•èG]á{Éo¨[3_iæà+MÕÂÍo¼#ã?¿Tˆ¼Bå¸8ljg4dM0õh¾·àÍLª’Fè’	…˜]F!©öj\0Ntİou€rÕ,¯¥òkÇŠ}·ÜíÙ¡ÿTh}‚fôf7Py¿Ùm¶GB©Aü#’CÆ*ˆoTD¨U„£åYfí¨HÕe³Õ†‹CöoÁIŒKŞ~,g8iN¡pÃxÛ4d5@ôæüìÍşF7Qº..«­Ş×àp4BÒ¾¸Å›­2‡VºıA$R³uWõ!_@;B6½UŸèÍ:®ªìûÑšÆÀ³–$)˜.‹Ì),SºËn œ—«éš¨E.Á 8–te8ºœw¯–l$>2k‰½Æ°4¥TZ+¸@=R<`ïK˜®vù°ìğôÌ±èÔ•üºLvˆt;‘ô@÷úy|ÜÃ`a[vÍm”lúOÕÌğÃw¨g®âúùHùÑ½—~º€Zßi9ñ:áDçÊO!Òë^Ö	ÚìÅ›FšèHª!\6à;#2­(OóB]5¨RN´¸"@¶ÇĞX8§|s‰¶×MCöÚì8¬»‘°¾L)ÊñPÆıh/›‡6jÁÇsÕ–36p4³IœàÿLámŞˆ˜¿ØC°óJ˜ÚÒ6i…šR}Çt¡ÀQÏt ©»>­8™;ÜÆ¨´?bğoø4MMx.CMI@‘šjÒ¯N3ïğºàÅ§Ôt—ƒÒ~Õoè2G,Ïl8ªWQÌ»F¹ìÿÍÊÜá%¹br³9ª/ÑÒnéjTÁ]¨™ŞŞãJÒ6“u9´¢,òªÙœğ5I£=‚ùÒªèæ†¼rÎMzõÜ¤Ó[zØ(90³c-Ûòú*Şz×­ïOÑÕî$zGCH4~óIß¼'GÈAo±|µc“6ã'ãl/AôÏaüæW¸—:zYÏ1”×Î=°?üLcŸå É†Š$"è´×õ!½F‘ìpÒ†œ:r¦ #®“d_4¶1ÊÎ±õ{O­Iø°°7‘ç­º:kM‘84§ÉbñÓºÄ,Ï.oíÆ'N şş«÷/#ÔÅtM4Q\÷bÚmp)-KÇVYÈv#Š:xœ»Äi¨CÏCu†Us`5ÚÒ1Dé{;24º¢([ÛÜÕkôÖ-Mj«	GÑlÂ¯¨‚è¥Õç&î5h>ÇnRœÃ_9õOÜ1ÏÚÍ$µ•½S_|á¼’X„a~¶¾yZ¬åÙñV1Ûí£˜q‰¯*ÔÒgÖÁ€RÑS³0#-\é°—ıˆÜÒ=vk()ìjTÕ°İ·î4TÖ´äGp\£°ÜüL‘¹yäN)7’bmıa—t$Ô!ûËùV+ÕYHı3xC12›‚v=¨´¥€}{±hÛ‚²ìO/L˜‚´-n$ WG)¶F å·Sõ8¹Ÿæ¨ò¼úNühTÊñTLÍÑ¸}#R ï»Ÿ†tÜ»<ĞçtÀû-€ØÈRµ
&h$ıs1 T€õ¥ƒÙ¨ûb†ü[nº‚´ºÓéÀÚF=¥êy¼œ†Ü˜<gZÜB† ÃEuLù	¡¿Ÿwø°]è@y°6o	ç =ÎÀµõ„/ŸD9ät(I&$–U½èâ±=ú>­|‡ÍÇ-‹k]’®@È%¤»L[}‰kWT¯1”E±Êfç¾"’¤Òå¿,:e’Hªéß» ëz•øğºyZa*N¨¬ö€ïİ?mDR[ ¼0'œğQ o:‡,(°b¾ÁÚ¿Ñ7	ê•vD´\^Á»úÛÜ`äúŠ(íF¹ïx:cˆ‰eU²‰§"¥|@%q–”€…(•ÈcfESºI[`ã!ó£cèM\ÅĞWƒæ
áDŞÏüŸœ3rJ´ë˜ŠûhY=d-T¥"K¢¨%µ!éXZÙ-ÈM`:å\PÄU9ÔpŞnHµ|°œDS°MLİ­ÅúÉ^y”û–¸ ø™°+™ÊC#Ñä‰À¾ ïÃRµƒU“Fî¸œ8ğ&ÜàÌ[>f`µ0 /­¯7Ka6©
÷®öüúÚÇÃØ:Ó°¬şXó3{£êéÎ;«2õşœ’.¿0óØAZ~÷¶Hu"ô·Öp,R*q®I}œlÌ	£i|äÛĞøˆ·âÒ]R´~gx	jÆ.–Òo=ûf“>ĞPèµTEåƒ¼TZÛ´™-ò¦^ø&²ñ²b^ö‡æëiÒ'åHõr§F<zZë	¯oxÁ:Ó®>‘àd&X@ÏB³Š¦ßêª„å¾"aßKSˆçÒç^j¦}`|–µa“ˆ\6e¸é4Lš«™q³U{Dª»"¸ğ¸ë%ÀEºÈ‡ÔÇºSÁ¨©¸%MMsV£÷»Ô¿N#w‘WÙ„ j‹óKË¤ê	óğ.ÿ±¥=¨¡©| ùÅã“©üôz;hIÎíÀé ä ]t4T‡1¥Ï7¶™ıì;¹üõ·“mQ·í&Æç’ïë jËL%èñÉó£§¯İëëe¬Æ~¨…*ÃÀUùmÀ‘!	Æ”¦ZPãO34KSÓËs.ü]ätq@?ÿÒó§ÄgVâùìnr—gªû¼¤.’yx†òIké®;u°V3¹ îu{ÍWÌ ÁùR¹j˜®zN<J(ğ,¿İ<­uÜF
9!PYÊbMˆcŒ{½AÏƒ³XéÇø¦*{ó5ì'$]–õL]‡!2VoqşöØäìG NWÇ‰lŠùÅ­{.•øöJ#mÕP#‡g”åq´ñSq[' pĞ.ßã^mëUë}>ß%ã)'ŸÔ8r¤ª0“2²şÂ7”ç‚…[©Œÿ%––Úœæù­’Ñşy°z_ÄãÔûD›Œ†@äŸØü´®u6%{Şb”úgŒŠÅO"
«€•vÍ¯Š ª<†AÅ®=Å{2+˜¶Gûİç
´3C5•‚o7¬”²ÇÀıûÉ´‚oÛ¥ûb’‰ø´UÅìk«sî¬ENó/ynøÈxP”ı©Ú§ªÂ®)ı‚_¿ÙÍcºn®rf¨*ã°	³Î«s^	DâÃš]Â¢o§Rè>ÖÄ°ºŞ.~”)µÛb¶ôÂD2^óy Zí8‘ŒTA{l¤>Æ?>Dƒq½˜¯+ß$zÊŞyÛØ½OÊ5Ûô‰šŠlÀh†§ª™A£FHÖà`¹Æ÷õà .’~Å¢5iBªÖw£`I«]ÙûcŠ¥PµxT¾”œéqSB£³à—jÎ‹‹÷;êgàv}²ë»ö†c™7Jó;Òcf†+†ÊÙÀ$qJÉÊ]´Ü&y½O»Ù:†½t÷Ç°âuÉì™aË/OŸ…ÃI»ì¶6Ãh¬G"‰zú»Ğ–íæeû•XõsŸô	H„—äl6ç14£gçOhNa‰mJîä/€*Ît„ŠËœ/+¯@ªh‚fãä£í½ëOC&^77[&û”,NfJ?šH%X.$¡íÈèòD¼-Ÿ’Œ|‹åÊŞ`»üíZ-˜y}‘1äÒtÍS !„©jÌ¬×üºK€KsXõËéí
Ái„Ş—|/]3D†ëIM_Šá·:'ÒÈõ—¡é('B¸÷3å&/÷ğjÖC$Ö8¿7et?fÌÛ"°”&sõ#ò®C«ß•Wüª÷·xĞH¬J¬ÂáuÃ÷ş,#oâ¢EpIX=¥ß(aj­\\5l´4IGnÑg§U»0¾}ì O8ÓzŒ–—$ajrÒ.ÂµÁVĞSûlû‹1ÌO2š¾0Sòn5fq¢'…òM'öZÆ;cT•Û×Úw<E*LgøŠxäxª@BhTŞi–¯
ÿ:’Ü…ÁÛ]]Fçæ8vipĞÂñse€ˆ€¹ÛfÒáû9ÛR‹sÔŠ*(ØğÖœbÎ²<Ö‹RvıœVËÉË¦»Â ÆV_€@Ÿ‚n¦-wFYqtÚ¶b«7fvÙ$ãîç–›ŞakÚ´ÉÃ¸&{‹ªĞ/•hQõ%u€ÂøÙcĞ]ºU$ŸÇ¬^ik­ïÈİ)óe\´±’°zæMCß9sŒì/åÜFE5mKş‰Ò k1Z-Õ,œó¥Á.®)c¼µçÂl‘‡èHpWYl.7íN²Õò‚†Õ1ÏâèwûlŠÏw‰å:öµs8Ğñë7¸˜ó†ù`mZ­mÃ]SéØï1õMş&æ’‡iëo@³~õ\*«µáãÜÜ#½^8¤Ş
´™-$W/&éærP5#R
$½4KéEÀ6’¶ûZÿ1ùRĞ¡vW‚Ã`½Ú¾¨ó¦Ié¢ì=Ê’LÊƒy¨a:œ°Ç]Tç	Iu¦Îê2`‡ù‰Oİ«’UêÕ¿„Œ¨¶Ú{u8Ó{õ LûYt3\,j'–€
’KÈÇO$05ósÒÕû¾Ëº‘ ¦Ó¡ [)ÍŞâÇ¨ê²ï(qÅŸpwªè–¹Ø]29`ÿ6ˆ½Ã¢8ˆ5øÂÎ#M~ö§÷øYHÄ.¹`‘sÚı®5 ŞÌ‚¾òÓöá#0ŸÁ‹Ç³›‘*;@ûíÎ±¹¥wI
ìØºî–«µ2GjkµTicÙˆâ‹æ\%`ayùÙuB£LUü]C¶^mq~Wx,ì#Vá2g.LGIPÆÆÑÄŠÿ8Üx¥^ú€ï«-? QL®¤rEä(Ÿ4 ’¸ , ˆĞõ›—8MV™ıÈ’¶Ş¤ÿ« Ù:Ç{ÜC7F†½ƒ˜û¤èœÇ\CûSƒ'?s ğs^aĞgŸa”—ü¦®çy¡§ªº ‹Öƒ³Í±¿R-ÊW%-=Jr o®Q¹¢É}¡j±"ëGgs€)¬ràõ½=X9örÓí8C{wa€q4fgNørggËªŸ\eÙAš0S•àÒJM¾ÒgbDÍê¥± ¸¾ó½Äš7ùãÇ€¾°5î2ê×+Ëˆ{*ƒ½H¾'2ÖëkŞâˆ?!k€K›y«ÓşÆ£‡òèaƒ|õF²Sô‹ıèö­²i.ü+¼Š’Nn,äî³øØHı“øİÈ†:ŞX÷pï3CãÂ™‚zIé¯» øßï<b\‡–açÎ1m={«TTïé s• ½öiGoÅåÆ$m™KĞˆÎÒ¦œ ts Ö2§i¦?ƒİ»ş¬Ÿ©ï`/fO-3ı‘•(åİEvÑÑ7j©Â?Õl¡—ÄÅcÅnKâ:áó°Å8ÆÍ éjUXğûµyÌ®ÈßğŒı1T¾>$²õ]ÖZq,Û²dÔëKão €gèA \£")Á6‚ô“ÜS8’é'¬€Šç4‡”š8È^~}T’¨´®ö‹ö¸>§4În‡È‡óa“¢€á°ƒt«‘?;‡»­à‹©½Åãµ]¬Ú4 øÂ¿ĞU†MÏ\Ÿ+ŠÊÑğAsÍO’Üx‚ÿ¡!êúšù¨ÖP{P6GùŞ}nâû‡°t7Õú;Ò‚ëåãÒ¶c˜¨ÊcîÃ>ûçN<ïw=Ø8=rÌ™$ó›K­Üfµ‹—âëä‰RKaØtÇJ…mÑ+W¦ka­¹ J7<yF’L2è-nñ€mìÜ•…\+fß2	Q½
µ¶ÊÒZÔfÑ×¼*YT5SêkU]uæÃP+_o‰¥Â¯I$éòe^r±x{}Lm£B0‹-ªË¨‘¼¥üu§I½oºÎÁT¤oz½#_hê÷p£Ln9†7'3¬t	lØÈrôñÜ¨^0×´é']äú”-<Mğä›©µYËÃ†bŒ¤— C1<çÕ’ìºš•®ŠŸo"¶x„|íÄe|ºHmûÛô
õË§“YíR¢Î}ÜÜ†âîêx/àÃŠ×h[ìqÅv„‚×Ğv‹àÓp÷†¥J…ÓbhcÈ˜*Âæ­aÎàÇnı
ÀzÓúJÛÃš:0«²¹pİ8,EW'>ßòc{]şıÍË¢„†«8kL¸„ï÷Õy-àCëÒ	LQ’¤]}ïëBTÜ­ÉQjtv(ü]ÊJÜÉí­·ß<+*yzX´S  “¿ísV·Î®œ%®À
Á«0”¢’µâeÄ¼WzÌôTv0ëÜ¤ÕhÀæçl¸9ñ7¶¬ü3ï-7Ô`/Y{*wA:wUÊLahí ªğÕCÔ“,d)+acï@<Şšá¿®”NĞ-ÉP~ÛMS9X9ê¦¸êÜäëº¦#c¦PÒ#Xá
ËêÄfJO´ 2°Ó³-YºÆÕY&ÎêªJº%·~XN ¼[7ªRÂ¶Q¶]Œ¬•˜îoùÕP×ÂŸ¸‹ÿh¯/Ø[-í€ÀsZˆ7¼Pq|T%½ÒÑ´\MœÚ­CWNğ‰4t²Æ}w&ı8Åcõ‰ëy”Œö¥Ñ8æï]FÚÓ†iqÃsï—¶„©¹+r¶ ômÙR´‰[¤ŸPÆxÍi70QØ»z,¨`¥^ÒSXÜğE®uóÅsÉÒ‘“ÔãĞº&ºb‹Îâ¡1ÛşÉkCÆ…hşíj—ƒ=µ§†ì'ŞšX®aªFP, ›*BH"_Š¤n˜äÓÀèl)¾êGqĞ"VònÁ0y¼<à“ùÍŞírXÛ-Gñ?~4<Œz Ú£{.Ú¨(IC-ö0wÃÚ¨ôAAçœ,ÁQ¦è!¨»ìF İE	90‰z*ĞÇ››ßOP2ÍíS•ô¼©†mùAÈuû÷¬à/-É¥òó…ÿŒ¥6ñ<Øw;SçyxÍ*ø-›— ‚A%œEü	8bò^ÛêæXjo_Ò
½]<tèõ7òD­/ô¾˜…ôÉP0BK<¦VÎíG“-r“_Ë\Õ>OR‡ƒ£zÃ´Ç…—9ñï¨µ¸ŒSk f?¤œVíT‹ñ¯¸Z;¼F@z%´ÇÜ$vüR¼â@NÓDÁ¾ÓZŞYGwh©ßo¡)-úö'jéi‘¾ÛÈ¾ûO$…JyÙmÂ²ôêk¼b%Û©£+¡×P¸"¹şœv2„Ú¹,ŸH_†0/ù(g›„êlL-Øaê>+0€`Oiö ïû©éøër¬á‰ã´Á_Q¬ëwà†Ös~= ªÕÔÂŸº$îCn,ûZGŞ
¶9æËÌÀö>A™+”ê½ª–ÌVÑûÛTd
¶;¼©Îx<ÿãNÓr]|»øìBYçûU¾¦¬–FóÁ56ˆ””ÉÈ>â¥8f=R§–är!P¶Dïå©ÂºøCœ4´ú|åLx¬õ5ã7,M&‘”Ïÿ¿OşÅhì*¡i"ƒwG®‰Ç­Ì÷¶ş­‚H›^€€n›¶	:‡Ø ·p‡uƒm“­ä§¨
_Ñ³u!wB4_ôÕ?E¦Jj°Cè1|ªikoÂšMÈ]˜»Ş($j
efâŞ˜lh–¡_Mq§Iztåİ¤°‚!l~¤€ËåÌ’ê)ıÃ;SôşxŠû…â‹3fadBj£±˜
·À«ìr¶-²û¤ìšÑ€Ç¬äÏš®-˜:T:Ó‚zûï—n¯¥o¿N°•šl®?Ö"²@®GÓ~ÂP¢ºŸQ#>7õ/x_Îş+Ø/³éÆÈo8ß÷æ™‡qÍ%¡ß»[V”™Ó5Û­N«—ÁôØ,šŠå›ã™üI2Šà¹gXà§vèáÑdÓ¦*f¦1õê²„¯£]\41@ªw¯àÚ•ñ’€'pÛbC3Æœ-y$;M-ÿO«ìô'ÇOp9@}†£œƒ—ù #1M/©nm¯'…ûbsM·™òĞ–WDëûWçú6ÿ¤'Ì
¥O²ëßj…I4~xúsñº“¾²A}LõTÄüux:+K™7t^6€u[Rº$Õ¦Ù¸Pï+¤ı¢q…Ã=Fıa–æPâ:¼S?XëpÜÃ:·=ÈÀÙ4A¯V³Y"!AICHğwÍÅ­¿kÌ&M½X+2îKİëò\†×I³Z¡•¦k'Š¯<Kß‡àPE·Ry‡ÆÙ‡àbÉ¬È°ĞGê¯Néğ;ÅjÏvì‘ñ˜‰ »AªdÕçÎ/´Öÿ¥ÏÖ›x<Ä=Åï*¯âUk.—ĞbŒ¯ÏE|³°ò®ø(×›ş½ÊL(åOKÊv'c(cnƒmö0X©3	‡™Dxwâß¾ƒ‰ş|(ÁÈ®ÂÙßX(;Õ¸!½k}[-áÊ‰¤ÉÆ‡6‚c«MtHış=]aÉÈù&ër	œéƒùìwJ\´GPrºhv^bˆ'l«òÅã¡V$S F-İØÂ7Â‚€{R¥ï›^±ü,i¨ìIs”DHşìl—ıî1	×}Ì‘ãJŠÇXÇÙ ©™/LVÌ”‚“ÇÑÔwáú™éÑC¹.Ä+B¢Q¶šŞÌ£½E.÷v@ÛX?§D9µR®úk{qGıJå{ÎbÕ#< 9÷då)!õ„œ¼…1â®SÆyÈ‰íZ.;³˜Ø	'Ó¹¶Çxe`T2ÆÑõ{ØXß’Í²-tÚÑ){’Ø'œ<=/€ŞÃƒ\b¨ÍWb£WŸñïdïÍ{Ã‡ËÊ!İD}ûôyŠ|„ÒT—ä€©¯â!VÃ•ñÍàîFË§8nt¸ÄMOß…äeä¹™3ş¢.}’—¬PXGÉN+cÅEãÒº‹N©˜Od¶{çU´ğ×£¿¨Æ<z)5b~yƒ…  :ÀzÁÛ«šP6cK@Ç@$Üå8W3röjûj´l0Yúyd¡J¶^óh~Òƒ“‡¢ "÷ß¥“F¤¥º¨»ädşlv=IÑLÑÄ‚¤ÊVM=ëpÏÈ³[)¬s­öH×f—A’Èª2şAù]‰pe ÑB{lè ×üéò«ÄGŞ4Ãt¢k±ìâˆŸä‹Cl SöÎª_×VBS3$¨Ğ‹`4±w¦ _ŞåîZL<•şT´qP|ÚA4¬U9ñÔ¦¤ E0µgÂ±_=”ß°k³cîr¦öD¢ “{éÉ3} %á¢-S3ªµ	ZÊûÅZİ{ùshlW½ÿqÒù†²t„ßKöÕç®$µ°å’aÊ‘9Ù‰g k¹Q•$ä¶ĞšGÆù‡¤D€‡×¤#¿O8»*®K1#Ta¬QmdÈ
:ùg³à”tå0‰äpê2ÁI©‹œJiîCÊ¢,œã`â˜8rL•õw‘Êf ÷Üi<Ú	RØP
NÉ“~iMàFç¨ù>3«ßÖ®Jªƒ"Rœèu5ŠÏ¨ÖcŠ¼F„Ümi7·Qò6ãV'ÚW*/y|<•ºƒõÈ9—‚Cˆ4
˜G€p­6ÄIê7•übğ}ôGäïåC%K”Ñ%F­¹å,´lsfía”g©ù-Ü¯"oÊ~—x¾.qŞmg(z¬}¹	!“Áù¾ıE<¸à;99±ÈÕĞ¾'R¢;-*©şÓ©ò¾W÷	=vÙê.k¡I¬YœãLÅeâ9cuÄ,  ÄÈß
SfF©óhŞ\å¯‹œÙ^ÕPŞT`M8CG¢­«ßo¶Û(eä¥GNf"H·dİg0{¢Øì­<l;çÒ‹ÂÂ1±¼}û ÛƒÊu¤pœ	º…ix/ä û>x†Æü}»_QA‡}a?K|Bê‚^Ê©b…Ë1}˜e¨Cl)8@Û’É	‚Mu¸}ÚwĞõAX ‡+²“~L{óŸ	3÷®¢T¥µæ°!ç¶aõ0vÑsé9ÈZ3H9µéˆ;¢-Ãv¡ƒ´D…s‹…£´’°B_>İfwøwüâh%¯¾%¾ßGU%yrĞdùÕ3N´ÍŞ„¥?ìB\8)¡áUƒeJï1U‚æº"Oÿ©­Áµ·a„ã'Èà±ÖäµC‚¡Úmîeî/M´bà#Î ­èƒÅmlá¾;OËç,g ìŒœS}±êşÒğèæ=ò0Y2,ül,ÇŒŠ›Lòp‹!vó~§é‡í0ºc_dN§AşÑ¯­ Z-²A@œJp?îÿäöZËv²#ˆö¹ıx¥§JØ¾ÁÄ±|8œÒ:%ËìšNX%qG3©´Æ4÷ÇK`MRŒ–âßØú»3„];Õf†*ò6”®<ÄÀ«ùgvşÑïÖIt™ßYÙ”š-BÏvj½}zuÄØÖ¢wŞGæ¾-mJš„`:È÷8ó.KUX-ÍÃ$ãè[)ºâ«Wk¾WîÈ"WV—ıÉPÃ†½¨ŞlÉ.:ªÅB"æ´|®¾úHöTÆG„ÓÆ#€ûİŒ .¦ıÿçÄYîW*§—"Û|†ğÆÙüÓScq…õÄ^#D¡h'ww†rYeô™İ;[lUízsÌ*õlpˆZÚ)‰»±â²¹¾Në>|Sã°”%‰ıí‹‹@¡Öiz’F°Â-bëşíÎtó{ó1J5ş,SôQ]/àúË…Vâ›×¯ó%pí–Z¬;:F——\Ã¼ê–Ò=b©\¯±±•Òã	Ğî›¾İ”{[×8äq…ôZ²HO¦HÏ£[Ş9J#`‹ú’r!ó\~>ÿ4*r5ª'#Y-_)•Xk^”yuäZH]	ºg·ÛnCÙXÕ¤´+0pŠíã8+JÜ5³.¼úÄnM±}%ôS„SŠ»ÿrø¢Å…›?ï<°<¤ïƒÒ™¾h-ó\íÔõ<’\6˜E£àk%À]ïÆÁè£A X#E°}“ò^ºà~r¡¨”+ôdVÄtbè!¶²G}
Xş.øík›9ÔKê>´Š£`†zLbW7¾´ƒœ@á#ïÕ(
w¼ÑŞEC¦=ğ"6×‘…„ÄüşAÏçL˜Ï&’§dmÕfVué÷<–@ŒÄ[ZfÃğCàpä¼æZ ‚ZZ9Ã¨S_[…to'İ²Së1ZÃÇÄoWYA_fÈ k[$á;¨$Ët¿¼_º½™5ğIÀ–ı·ÅP•Ìğ'üA×ÃZÿ[p•¶ŸgõnK^9»‚¿\÷¥ìƒ"ûG,ûÎK"ØUü@ÃõƒgoP8Í	­]E{Xiñ,q|å¥I‘å *¦äŒ¦Iri¾'£ŸN€äÅšuªRËKŠİqhz§%æ™»’¨õ¼æH*løò§
µôÁ“ŠJ«?*0ÒWA9æ!u†½T}Õ7àõ>¸ĞÍ…t¤°QóîSÔ¬¦'/¡ãf´L®5œİµ ŸÉkz•;v]&Ó‰nÕï5	†ä“×4d¹ÉÒ@zöºñLŒèœlqJúå@uô¶=9QgD‹¾–ï´h×•âˆİ×£+°L1Èsäj(>›0‡‰pÌ&QÊê…²Èâî¾¤Ã¬#>ß58-dèÇa­•óSœò;£ÇWf„øs¡núú†¹£šÖ,XSNkåñÿ¿8aJB%™`+s[/BVí:õbñN>Bz@Š•#Ü‚öpi¢ãKé›§~ºoGTt7!iÒ{Õ–txøëÜ=b,#OÛ~ïjÁ¦…£38@¸{ğ7âñû_<Šºmå…:úĞ+-ğ!ˆuı¬}²^¼ª/øÒ/üB	V©t€©| lj1úğD /¦èÅß&IÒÆzFFn²ĞFm­í^3¥T«%CE.¶Úßyáè-àDU…~QğT„¸­¼O%z¨høìÍˆú¼yI{ÊùÏÄ6î>óT÷Îøk(`{I¿ü>Ü¡üØÕx:¡5ğbÃúáªÁ^Cb‡mŞ!^¢·ßcw©iì½.öî¿Ç÷æ_ÙÃé97€lçš¸:±»—#^r¥µíËWÉ¾€€<—MØ$é$‰8‘s¢É•V$>½±}swnÜÌéÙí¿ÊÚ¾%‹Õkí[À2«Èq^[=F’èÎßŒ¡×Øõö|¢²xû;‰vÒÏ«‡3™ÉªLÑ¥løº<Ooò2ôr÷ÉEÒõ»·)};¥z20:|¦rj¾ç8EÙÇ½jc¯Ñ8oäÕH¼Òœ†8¥·©ŸKA ¹]çÈÂ%ª¦ö†cüüçã¯·ğ!OyÃä>Ş¯ß*ù<RÆ‘ÎéìM%Y¡ú>ÿ–xµ!‘£?ÃãUîœ`±Ö, Ö|‡n_£SLlMÉø©3±ğ¿ŞFbÛhs„…¡8VúñÂÅŸ›áAÄ`kù]~ƒÛ‰Ìsš!şÀßl"ŠÉ g•|ö5ô ğwDõ·ÚªBœjSğ×;â²ô7PW=Z88ê€H@±›R<GÌœ\è¹$H³²Wã+Ü9ÄºÀä`x¾RÚ6}Í‚y¤¼T¤åI­ßë$` ªna4pBú±Íõ8I>AkE‰8Ğæy]ê)S„ÄBY>x7h€u¡\œZŸ%±3+ÀKäÖæ÷ƒí¨¯ lÄ"é#„ëC -(*å¨0Yµ1^Ã÷3K­à	Lğ‚É„­jƒà>÷tÚ.PÍÍÌOnÕîI†}ï»›KÕ‰½1(Y´ÓŒpˆ&WÒ´mšŞƒcé:Ÿ/£HOìŒ4ÁJM,Kf5‚ªJÙÒY] ÜIn$ZN­mõ ¬R¢›ëƒ3œó{Ê”kG…F#Ğ¶÷Ûª«GYø
ÁÂFcfM\€¨€;GçFùé/Ê/ya²™˜%œ¹ÿW{¨å§5fb¯¦gáä‚«~8uTè5¯S\çóZ}˜HâI“?§Éb»Ÿ}ÜÍâvtãls%]|ÔKİ=ôJ@ãóî­€ë?§‹—ØLxïB³i„Ï"§ö“°ÿÒò”6LÀã³z‡ìÖ‹†yú™üw„ó<øûú‹Y^ÒÄïBUY:|ŒåyğõÄÁ‘_½ËõY²XW®,—:æOVË?»v3;&phgXÒV*[9Jˆ·èÖµf–NŞ¬rSsLK—šcŞvÉf×†sœ zÛÍA“jş}Ûáù¨±Ñ‘8‘ÈtŸV‹Øù]ƒ2 û§]ˆ³ëóg,Y¨Rx`~Œ™¶ì}Êéójïèâœ_Û*vzÜFq2‡ı×ë£Ô&a†rf'®|ej5a`„r¶&
TŠk…\ßFïlÂÕ1 wÙXjĞ•&£;J5¨«êœ;^UzwèCL­.e)5\ƒµã;Æs‡Ìçõ¡h?­´VĞòKw$HeíÁİ”3½Dä—F3%œ~Î0ÑêİğÜ©2l¤>Çã$¥Å¼	ªHëà’´½Ò¯¼+¶€œìÔ³¥a”–ª.äÔJñà`±óQC«éí²W¬xEg“øÿS¯××ëZ¾Tæ4§0Âù./8MC„;ßö[’“Àp1B@c‡äßÒHV©”Ì{f0ãf¬&*—WnYI"*;ÓçÖÚßß#Ú¬Á9j/PpŞÊEõã$Öî	°#º€äø1¹æo`uíóˆj|Á…¡•ŠÏd[ùÄÕû¯J!n™¶ ‘·)ÆóŒ6…Â
#"{M#UNšøåÜls½¥^^O`›{ßâb¯³mÃÀ`Keú£¾p]Rñ/íÈıªğäsÔK¸0`gØ”Uˆ kO„‡ƒè¤Ï´+ÁåÒ	íI.¢L9DPg‡=0tÆ´Qó’å¤¥(±uDH|œ©ŠSB Ú­íF›”Sjğş_Şìñl8wëÏĞ03Ú}a5VğU¼VÆ>tËk~e7Çt{cı?½ŸqEÎO†Ö7ÏØ¾hÊ- {êÿıô{“·ÜïÏ7ßTgìÎ±6ÛX3%­‹À’ñä²¢Y@šı1ã.VÀÏ\ø¯BÿpÿĞ¶M#øJ’¥ÖÑ”öC{r—­K&=ÀÆwå,<w¤ŒŞJ6}2i¥ÁgN©æ¤ÊSœÂ¥;’ñ2KiO®0ĞÍl*VˆKh£º÷ñÉËÄLj”[rÏ»şé (]`•j:Ï‡ÏP¾r5{#MéBÂ±ñ>ƒvJWt^¦y–lå$w„¨Lá¢ö…µO¾æ !HôMC¦âR~w)Ù˜+yÑ¤˜ÕIsÂÿß	1ñ ´0Ÿ„pNZÜí=sÄëïsévd¹Iª×3Kúå@iŞä$vIÎƒ¯`­"®&t=b†O&Í¦B±¶:)'zÜbÆ‘-5~+Œ·®L$â–>R Œ)z nàJ”¨aš_ŸØ‚ğ­ØëêL%Ñ¯r N¥íäGSêß	ÁÁ-ı/º÷8®`öCd@Ò#Êİã_÷¾Uâ<«0KÌÑÓØ†ëì3<›—^ú<‹şQË
(ìJGyƒ:‚hVŠA]ZãŞ¦q–ô8_Y²ıx<ø^ó•Ú‘ğşšÓ®\¯ÃFºŞÈ»Øêosr‡$Å…¾|¼Xù›_„s-»FXhp®48ğU¿bp–‘ÇÏ(1v9L2Z)¤KTÖÍ– ì'¸3wõò3 Wˆ×«-Eé®Èş·”©L„‰q± ®İ»‚iÍ—V×÷R‡ø@Øóª ÎñjÃHE‰T»¼ó‡]×Ã"ş×³ÕÊ.–Ê5$±8‰®½€	ù.T­ì¢;ùqè¨¿Y­§a×£(ß”Mˆ¬#a£‘rùÿ°Æ‚EÚ±g6Ó¤&y¬}@E7:¨d§]³^08›.&Ÿ3êˆFnhİRl
ËĞ¼4Ã)Áşÿ¬øpãÄì›<å+*`+^ÃÙ%nîµàşù^ğÊ~è-„§é³ØnÑ£â	rÀÑb¨›»àÇÛ3có¬:;»Õµ—5fû‡ˆç¡q·æF\÷WHiJ&¡6Ë…1ÈÍÎŠO××8[tí/4L†şò3‰}ß˜hdYÜ¸øõØËÙÊÒÖòF{¶ì§²Åq`Ï„5—ñÏr¤tj3&·Xb©qÍÙAïÔ¾9hq ´kÉïË.BzT2Á;ËR½l)pÉød¸µ¿wsĞåY¶áÍ·¢çœÅbıjØ04Ó¸ÌÖJyœv²‰®>#ø»ë{ùöı®XÙ3T±VSØÎJmª@ĞÆZq3é©9Á.7¹¢Äü *wÚõuCÌõ[Â½&ZÑ„ÈÏ‚ªo Kõê´š¡ /2"’Pÿ «à…]f|8­É>Fç`èÿ¼¹ÎIµËãá/^£’ìb£‡ÌòŞ8EáÆŞMÛûMU&äÜõİÃw>Ó ïÄA¾AšCqq¼ıgÜ_~?ë¤#t’µŒ¿ºøÍ£IÒŞ’g›/ÕIÔÃ–eÆÔó)¨¬::6ôÆî;Z@œéBaÖĞÂ ´E÷†ä‘7Ëº‰`ìc¬Í1:4ê›·œÑÒ£ÏŠ¦—ñCAsbÄ˜–"ÏjÓ4n‘b¬rŒÿÍ$ğL1NİJ.aÎ'o,ñS{äÑÎvNgc6ÑºRLÇ¡üq‘ë¤†UÛ™LHÍêõÎ˜ÌÎÔvLÄX“ß§ªärçCİÕøÑ\Àa½4ßÕ÷æ…TÑ­ş1©+ğûŒsK=Æ×]‹¸‡EÌÜíÔ¦0\Ü®ç=Ó£Ï$ø…Vu±ê¦±øy“Ÿs¢m|)TÂÑú³÷ªSZeÜÍ=IÃ¤ÏÓéi!ä™i¿ê,» ²óS½x`–é}Îågf˜ÅÇÃã	ÿtU=xÊ²b õ<’Ñ*¢í‚–Ñï)sØc&©†·|% ÎíCÂW¹êûô/¡¡/ôÿzV?jj=BËÀŒk„sŠFx‹éÇf‹ñ(XWflu¯$¢•‚? nÃ…©AriÇÓÍ>¡ªÇÚ6NTO¿s–IrE ;k‹ØÉxTØeØÌÔÌa¢Ÿ£0Û­ÃŸ$WÍ—Wu|ŒÌWZ$@®›™™¹645æ5Şš®¹¨dÓZ†?…®o–qµ_¤q0Şè'|qô­Sˆh|T_EkÙÎæ‚Ÿiß‡ÈÈ¿İ¡õ}£8âsŸåŒZM¢òFÆöIîªŠW¼ã`µÊ¾ì"ÿµùµ‰Q_ÿMÕ,¿@½q,^Æ iböR¨¨¦p|¯’ƒõÙÀª[1®÷|Î8ü±ûË×WË'´ı±ú;Â¡Ü˜s>ùÊ®´Õ*‹_³8¥/Ğjíú¡9ß‡^Nƒ•=Ç¿ÿÏ©)B-!':fÒˆ.¨^TÙ:ƒâæQ£:Ûû
ÿm4 Ù¡á*°(:;‰Y¨PÓ]H\°,+Ğ*©œz–-û‘mz¾ğñ.3ö«·ıÔŒ0#\’<»±Öx‹œ¿ôM"ûbZ¶bß
R£Æ’©üÃ]¾„2+ä!oñlİ´fùŞyDR÷&Ôö!sù	ßúlÀÄĞ/ïòÂ/(flâW?èİ1İV]Á$ºº=eA]GM:´½¹“Ùõ×CEÜ=`ßé<îååqTQ´½9ß]À´ºÿs¤,k-6ÒO€o7ro÷í·º`JÆä“(Õ( 7üé¡K€QdX©Ô†“‚©›Hë½¨¾üP%6š³îG6ÒÎ”lú¦X~–Dß¾_İ¦Rë²[ŸĞ†şRÌ˜TBŒJŞªĞ=.OpÀ¶;}p!s?ÖT€!O˜¦õã¦”§ğš`¼İÔ´}Øº3.²“MŠªbö,fxòJ²dó ˜şÕJàWCnãèWŞ2èª'~ŠgÑş4v‹ßİîİ•í7UĞ”qB}óVÏE1ûñi“Û_µC—U|yŒuUDßŸbå
mÊGû$b\²çÁYŒ'~DjõëbW]÷O4Ş®³p/–®.à2’kEÃL„–ñë2‰!€^O\Çdio´Èd¿ÃZ‹ôöñ¾wJ µÍçgfÇn–‹P€FÑå°h–áŒÙ¾`W¹‰ÎeF°>¯×XöZ¾Ã’Bjf.‘ü—ÑŸİ}şÂ~¾F•8PšâÂ ğf<%¦Ş€•¿ZCO`- 57u_6x²9ÃsÙa˜u`%‘íªfBÃ½7'1ß6v4õÛ]¼Ñ{òáÕ»¸õRã%Ì’ôG•<ğ;È²ùzQ
Î'œX]üÛü^ò$ˆu8úkmôÂÆ—†™fbÛ*G²`ê[¼t…fâºôòõ$^.nšõ8üÁgÍ­¬a[0Óôßºê®¶Ÿ<›f0ôÃ{„È+z*o~±M¶Í6b³‡†ÿÓ×’—pš:”?ŸWûA²>Ñ]ö¦~ñ‰¥¦z¼óà/=A
é€Z. ¨(EUd'7s©WiøÇÃ°‰pŸ©õÔ0?¹«®±·ŠœPu]ĞÅåøAv]Ÿy[
I”»¤Ş›¾Ò²ûş—1À×P`ıwœÖ°\í´ÅÍú‰¹.-—{g<V­s¸®í
ªÅÛçpmJùĞN}k[m%Òùƒ¬>óiÖô]ÒL;´š×Ì®˜4r_“Éd‡!¾¢¤•©d%¯#œ¾&æ
/÷ßNyŞ HZôÌ¹z	¬óõaŞ„8~úÈĞ+…˜(Á"ë`·++wvßµà˜’›€¹Îúv_\³7ÕRÖ2{Ñ¸ö0#ÊRk«*Çæm÷¶D±Şˆ¥sOœ=é_İmø‘¸¬Œ_Ì¯ptYY·À³­²êÜÙÌğŸÂ5P¡ŞDÒ®>5ÈÊ~<$7¶‚ù™ÔÄ.3RšÎr´)7(ËÄ?µB*¹ÀIY‹QhA²ÙGpYPÎ›ÏFùU­‚Æ»Éu‹Åx´Ãöæ„ÁÛÓhæx³BJëÑn§ñ^ÄùE•—K™Ò°ï,Æ™ünLìR¿Ñë+“Eªu/9¿u™-`™~[ÓÏôè/j+Ş>Ìs8ó'éµ­hÈ-»+Ç1$Ô4á{§OA}yw´Ä<¾q\
Ã ‚š\áæˆêyùƒÂ’!&ÄÓ³¸3ø* Ik|³ŸÑwHlè…ƒ´µ?Q$]n·J‰Úu»C¿ÿh=Ôz	ˆÑ†%¼ËsÕcá6ìg	ş‹Î<¹2¥É‡qny÷)‚ı©¶:c…šM²ÛÊTÌĞ¿¤|œ]~~T›ÔãyƒmDŠ+¼C‹şµ‚"eÂ?Ïúê×Bou?Ò„Æ»W•Pñøı©c¶¥b“ÕªÚaX›È0›ö|“æ%÷q#ø±€UUÒBNÌêP'6qŠßí©3s^F-©;±âø"~Î©[[n9Q.Í¨’À9`§¤¿˜u–ı5)`"Û¯=ı_š%:Ç¥¬Õt¶/Q(,çûıq˜Ht:³OÚ†~DEúš58Ã…qçò­¶½aøUuÄÿ¯ÎÚ¶,¬¨zñšàjvÃ±É½•wŒ–ãõÁtKPp€ãE“ŞiíÓïhÚT®M×?Tïe‰©A:0KÂL/¶ö{ıÔ¢r®¡V'fuYs½HÛ\0ºÏ€ÇHŒÃÏ³¼"¾„€zíïø:*€É >‡ŠPôl	A_"õ›—ñOÍ UÙ-^gkêZv0]Ìƒ_‡çôÁf{¼©	ü= Ü£|÷½‹kŸÏÌVã63ZÒ;¥ª)v.Zš˜¢}t~#KĞàúj§Ì“ º~t™†6Õù$/npEà€ÿ'_„ šiİ¬©ü$¯¸'o^¹­ºÁÈ.g
ÙÅìŞ3tç¾SWgÅ7Ë©sÔ{°–VÁrµÁMæ¨/_AÜcı„^4şõ·Ä…AI?_(LtİK“NSîZòg"çAÙ =G-¶¶ü:j½•FãÃsJaô;î"
_A=İAl- ´ñSŞ?¨|š#ú¯ê¯×ÌË¹•<ä·F…Äíİ¼ÓHw7§óFÊLŒì¶‰-Ñú×šz0@PŞºÇöŠ2g9É Â…ëUß†À0nrº·€'A{…Û4ïEÿ¦•Y¾Ïëoã¦ê”,~6ğRy%uÉ–^_g~]=ıòAì‚©vŠB ÿ•Åæ ±|‹•7$ l(¡Û>ı‚óÜ…ÃÜ‹±÷*dï'ÃúóuËV‚öŞXØ<ˆ¤í	µáéìÎÇ—ŞwæÈM.­°€˜äÕ\»u
ê"gÔ#B
nŞT”„”%·]RõÀÚîÊ¯Aï¶©On±ı¦*›¨,Äb©åVyºqÕ¿W@î<3•Bœt]+Ö¯É Ô]Ñhæ‡£	„é×Ä6,f  nÜß<¤ ³÷m“D‘Œ4r„óVšò9©\ƒàÌT~ÌQ¦n(BÏK·ÈÌ“K½ß(±½²"ôt÷Æ>{p!QÃ‡4/á`ÄÑ¨ìFN~¨´Éğ—!+Ñ½ñbFsÜ ("òsqmî<½fQYe ,Ş—¯á'îëÒÅyKÛ`Â5çğµÜ¨p»~3I+ª«¶IÔŒ°:–AP…·ú¶ËñI/¾³µ†1ÊK·Œğ†ZJ‘Z¤‚Tg¼f?WPRSéh:ÈDµî–‰Æ¤V
YÆØnø–†B+ÒÃ«†İh7ıÎ?<¦ª$5iXêZ¼âşéïÉe:(Ah…2Ü•œM<]–ğ…n2|\g^ğÚmÛÛöHäÕ}d*	ıc[°&k¿(µù@ˆ#f’¬LÄ©D3şøx,ï«ºHKZ  ]‹=AD$ş5‚¿š0=4—õ½VU¾,ÏÌ«ë…O‹Ú+‡[ıuxê¡
Ö–ĞİGµÿên‘zæï|’)»¶ëB¼ó Ş³şv®-qgö¼Ÿï¤Zwk}ÛtSÜ1G¼$C7î×ó¬36ß¤¨©:‹Œ=¬¥­‰2à¨ÄŞ¶ğ7•+ÔÁÓÄB˜tsTI§âÚKŒ!«¡ßeˆ.×cÊJQJš>Íf!Óq$ŞsgStÂ4ñ„–Ô×7xâ½"]Õ™¯Îè†¦v7Ñ3ÃÒ²LhçŒŠNó©v˜#¾ä²-#íJŒD•!&ãÓ°69¥IÅßÿ
ı‡şsXoFf_ƒ°Y¾c~ÃíÇ1Á5š{€µÌ#m?Ø4<mYÖ©ª/õ`ºY÷é4Âü;c yÊÆƒ‹Ë·D–¸8Çó?£] ëãr=dsı¥a2ª®S Ê~Dõ@ÊÍl®Ù4§®7ÕX¶Ó?jƒ"Üx·ÄG¯†®„uÄ*Í,1ğ4ê(_ş…À
ÖÃ5Ù¢äkcè~“Ÿ/Eæ	 –æF;e‡íÇ—EôYl·ÖöC£Ï“Ö.(·rGkÇÃ5¯‹4©_Ã•ˆ„Ñ­2ü¥‘£r£­ŞØ{ÉT["¢¡S#/ÃüFly. $ ,~É‰­)ãşå~Ï—)ö¥~Ä×½´ğyÏ÷Úq2•¨.ë’®¼º„ÃP;Bc0YêÁâógÜÔ|ıøZ™zõ\<ÆÓ¹¶SÔ$ ¢+¡ËÈ!€Ö¬e7ÿ×ümVçP™ôK Ñ„ş¡ü?Û¤Ö=eÀ	°àDb½Úv“«@b©?âLP¹ÿëCjÏ_ÌÀ[RZ
PH‹±/8½Äs¼°^å¤m}:,#AÏ–_ÖBÁ5~/1ÜÆ	cb0¯UzØi›‘²®¬…Zx‰ruÈ«\Ã^»BHE)ÍãSE9ôë+¦ï¤T©]Éo*0ÕÕG³wÒV0c¶I†¦F,¼wá¿d¸#ÕÏEúÌß÷“„ÂÙßü/Ciš>3	“[Á9J&lb:$?ÇĞ‚„UÈ3¼Úî&¸ÏÕ½¶&&@»z[ğ¨·Íx—HR@Ùä¡“}Ğ†ædïy¤gÄáYwaî–Ûe¾œÉÒE_sÜÅ‚õX‘¿ôŒ—»ÅNÌ¯2ù}9cÎÅ¹ybÊ)ÔIE;¬ K<x£¸—3+ªC‡)€-OM¼b‰ù¯Š‡Ù¦äFr­{hÎ£Í1|¶¡Øä×êqÃ++òQNˆ·R5PÙŒ ãµÃ=l¶c
(#W3RR¬÷çòc`PÛMvfÏÜœ±%—ÊÎRQÆ`v|bÈ¥ZÎƒ®æ¥@5â k}6ûgR†Äwúoê)úJÖõÊ:Á£ë¸ó	Äåÿ™cA: Ø²ô»æîD¦†srM†ZàíB¤ÙÙ°«&Ä!ÍC¾l”Ùıt‘àÑî–ñ|‘¼ü^qò‚u¥ûût{Nít‡=úİ|ÆKcÒ§K0!å·(aıº“gòÜÊ·şÎÎ"ZÄC/¸(æÿ
–g?|Á‰<	qÁã¤›Ì”«!æÊøò§á…şZnÇ7ÿŒ·<*à 55óm‡èT˜Ü˜lb±Øw²ä­H€½ÖÔà$Š¿©bwÃö[˜Àº7xA:VµÿoöåOÕ¶sÓ €d‡0D×y8Té	@µ’ËÄÈ#,Z³äãğÓôìİAKÅP¥Å•÷¡nüÖ9“6Lñ6Ç[OYÿÚè!V¾Ã^×¡s¥w¡BiíÌIúåAoˆ”'‘ÜÛ=.x+¬#*†dSÔ°ºhıÙÔÀúâş£Iş¤ù†&msåå¦+ø?o~h×õ‚(6V˜×(•·’KÌ*dìBÜÌ§†“‰· ‰KS«ò¸€5xK9Ò±dµ˜Øy©Res‹¥\yû»ùı<´}
—¬ş':›B†ŒĞYBs?q…LİÙ~ŒÑÃ·80ë¡tÔğüt7a’¿£şpõzŞ×‰QÎ³›{ó+>¾ ã×° äXûucPÂ°Ë8åwŸ8@µ¯¬SÂÌd’wafŒL"H…Áş<†ØÔÇÄs5Ø¸EC—î©üî/LC¤¸H‡ˆ„«'Â©¡Š‹'>e3ènÆwrYë[s«›'Tƒ9 ÈFóxø0=Î“v†Œ„RD·î[®Š7ÿ*ågîY>¿gD=˜&]!£zØöó’9Âƒ ¸òÔŸò‰WÍ°xÅaIêHÒnAáÉËñĞ‘=kö?~è­†Å—œH![”£†ö( %ıÍc‘‚ìVújiµøÕ®$Kübôøe‰qN ùÑ­à}AïT§íèAqm& wkš–ÁÕõ"LiŠÎ øfñÆWáu/Áìë xrÉk°`ø[ë$C‡¨¶¤EyX†HşÜˆoãeL1$®Ê.º´æÔ6á²gc„-%¬U©”$Ôä¥×…p¿ÉßQSrû&}HpBŒ¿–…òA(‰ö²§ğ‹MÏlJÓºyÅãû®+íkzÕùï-‰Kk¨,^kWñrÌ\GÙ’aßq•z)g…U1?Ëù‡'Rÿ:ìE~XJİY?}…¦„jº|Ú¬ºë%@Ûnê&”Ç+	áºd˜ß’¸p®ØÆèO½ÙzIÕÆÛ™êcXÚ×Ã®‘w"÷Pea ¬ğa“œm´ ù±0—İ!vÁ5İ?øRY¾ûx¹õ‰YÅŸ{'E¯~Âêˆ8İy4=ñœ¸ğ=¶Œ[ˆZÖ¼hï¬Ùr½ºÍ…×šFİ;kß\+ê×ÕÏmÚÑ2g…ôÛ©ùnÈØ0 µş<ãÓ–Qê´/Øç(Ã([Áe”1K‚—ßù{&½`	SG•¸xçØDl²=¢F¤,á¼ÕQ9Û¡èúöùÌDdYYH§*fÑ¡aÛ‰i«,ÇÄD ÈpYV6eC"/lßÁ§MA=ù-Òâ`¿µ’“jNë¨|Çº‚¨‚¯˜áê?şƒ"`¸µõ
½ÊWàşŠĞ.ì +dõC-u	Vù´tÊßƒì²®bà2®æäªÄS
¶IŠ¾¨Ü>Ã1¨ÑüõBCxî(Uœ$÷r”J@h@^;™U÷Ô0çjXvV©/¬Ó¥J’‡¹Tm\ÂLl‰´õß¥ ÏÕl»û) “ûŠÙÚ[Œ‹cÑµ69öFG\ÜJX…2jHE´a²Å÷B8*(Îè<­E=õ_> ĞKßh:û3,äaË\Ác‰5X›Ûƒš‚Õ‘ˆ‡tby>,¢“İ,Ôl¿ˆHö
Ó¨¸ş|Ÿµ,å´Ò· íŸû²(“Nç¶‘ºw·ˆŸş¥œšAOéh›ÊfHŠ§‡Ö†TòçbbÎiD´ßË˜~['É:ƒ©“î7nÖŞ©‹ÏüEp=¸‚Ø£ ª>ù×š¾ˆÑ:²¸5Õ-Åßœ‰‹ÁN!lúßA¤¿Bn"7×4÷e¬‚ÁŒl&5°:¼Iï0k’]F¼¨·-ÚĞğÁsõ47P’ï¹Ş<â½ŞvO_"”F_‘á—·‚j¶×#XÎ`›€³—‡&QÆÅgMÍFÎBv0‚¥0mKw>~HÖDëçd¾ ›%ƒó[Û‘«}y,óÑÎk¦Éæk:Gq R;‹oÂè#Y^N°3`Ó`|u¯^w86ãiŸíbgÚô¶yT8]J$«Añó®¡*<—I/á^çù¾Rúó;$-É¼´‘ÓŸOjwÌ@{ÑPª ?ËÈ GúU*@RçÏL±¢-'(ç Ô~Eğ¿jo‡˜üÚ%r”óK—•+2‡ÀÎ»·x¼öÜ¨RS(å†È;30Å¸İµşßs,Â¹Î<õXZWrÓG‘=o$l©µÇŞ ¢“ÿgÚÍ6wMù¨¸Ğ‡ûò3	'	[‚VL®%ÃçBmB^7ĞùºüùˆÖúFÍO-YµİíƒìÖüDónöaãæctYa^©–c`Ş®t2¥šƒpò1æ^DzP»l{­ø–
Ğü›‡åÎtªSe<r$*2Ï.°zŒbË=îàÑfªQşêcy Õ[Ú„Û#hÜ¿A¸äÖ`Æ#±Dæ‰Îæ[:ª¯¢³/BÇ5¬FvôYÉµ7ê€Ô\Î„tIÔÄÈ,•úë¯[Nó|Ø/$‚PY¸|tfõšĞÑh+Á÷ î#c±ÙïH•üDu@ 	¾æ\´¬wL'ÛÔÈÂùbŠâgbù?o_ââ# òx9íÙ‘ö¨j;Iu”¹€çO`£És‡>Ài‡ğ ¾T§•9y.èÿğšï~ä2Æñ|p…ğÔ°8ëœ
œİ˜m;ml½$¨kå‡üeSı%ÿ¾¸Çÿ«£ê[±”±›fø³\Ëã1µe@®SÇÏğ+ƒBUU÷@´®¬µ…ÃşØ¾eÅùÒÑ\ÿ×ËˆÙÇÅ¢óÒnÎ³fPEv/²w¯Æ®Y2–õñlõPqz×ÜbÇ¼üjr^Ÿ–Ùê¢¦x…ØMGµûƒÆHfÆ†lÕ7@³Ÿte!öL9bşÇú*Üãx!†d[XÕBüZø—¿R£NÏÚV(‰¥o8A‘lõ¹Jlnh/€    À"¶û°s ‰¸€ÀìJÖ±Ägû    YZ