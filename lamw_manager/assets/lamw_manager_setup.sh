#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="814138104"
MD5="62ffd7fa13180200ca3546ac3e4705dc"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="24312"
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
	echo Uncompressed size: 140 KB
	echo Compression: xz
	echo Date of packaging: Tue Dec 20 02:00:40 -03 2022
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
	echo OLDUSIZE=140
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
	MS_Printf "About to extract 140 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 140; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (140 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ^µ] ¼}•À1Dd]‡Á›PætİDı8(ğÃ#u.³A™n˜(S¨”½ìd¨ïÉkCıñ	ı¥Ò×ÈNº=')‰ÈUssN ?·5c<ã—ûéÚ²ŠôÁïØ÷ŞİÇóÏÈV—1 #ŠZ÷èqşÃf&t#u&ª	|rN
¤Åa‰zÓ#ÅLƒ ırè0Æ±ú%+¸Ç9ólª®„şED¹k@m³Qèß?Õñ4æ‚Wcøzä—Z i$Ç“ØSQpóåŸ—ºHë¯u7Ké—üı:ÇMe¡Ö¼›^öZçºÛÒ»ŞÙnå£Ë´u¸3Q¥˜üßYùşWWÒÈ•zaˆ	À¶“S ù$øó¤áR³¤ÄTˆI”‘œKxª×|™f=ùõêz¦éÄíóBoı·™¢ {z jm¢àÑKÑQÿ}µä›)6Ò.oÕîŠBŸ²+$ş’M8ú
—ÿºÖ>áztó³Éó3¨fL_–!àufUÉD…š>v‹ÚÓL°eÿDüÚ“9îs«.ÎqŠöeÂ¾œ"øO •`0ë½Ğ)Cy4âc©&|êÅÆÓ·jÉ¸âPıÄnq÷ôM4@Ô+vÊhn5T-³Iµ¾_N<í9=ùNÔİg FÔfÃ·ùEæ²}§Ä©üùçFÑ×¼O–ä5B±¾úÄ_Õ‘iÁ€_ÌoªÓÓV‡·På×ìíÕ÷h
q2¯%É‹+ñ!Ğ†­†äJ[>Ÿr˜ĞRcÇ_öŠ˜Q‹Ø¦ËT[Î%ë†¡B$’ÃÒW¥Ú…‰'U¼Û–:0A²0±€óË<-¾ÙêÒUŸVKrn§ˆ¹2ÀÅúz\oR	YEtOÕÑÅ‡$Á5ƒÜt;Úıéjô©Sû,èğGAááÍ5ñÅ*”áÃw®U6¢³Ú
D©.šÌO~*@EæQÓèİ‚ÁÊëë&ºªŠ_añ;ò9~ÇØî&%²B
¼[¡ü°ğ‘Di·C£b©]†­D™ÎxK8ÖV8>á½Œ­L©wX¨µ¸:ì/†P¹Æ¬6ıì
W •VÂ#¿lëà}º÷ô@päÎlèÍ?pèprŠ|+u‡RvæjÚì{ÀYÆ­>ÎÏ!dc¯épîû}¥fºİVäÈ©°Ã™<Èa•aBöMmí¢50ñvÇ.jÇ¬rÂú"ìÜdêY&ËíN;p	2 ¶-Ô;+Â¶üIJôuèŞ"Mÿ£fÒ”eS,uu"RÜLTh„V‚n0÷2YÁF-i^¶@…zµû›ÍÛ¯]Í[§SƒlÈ–‡)øáYt<GOg ®KMğ6¹€GJi<£†´ÿÙY°c”áJ6ÕüøêÔà	‚hCÿ…ËkXÚgÖ;jïGÕD’—USIL6¼¥7ıQëE¤,ÅÂ™]J@éáÂô:ñƒ®Å÷‰.‚ó!CW=ƒãÁØ‘ì¦À+ŞGóù¢¶Æøi&Ş`:[
ß=÷ŞàNK²ÄÖ ™®äìäıe~-'@µ—ìªIôÅu—»è]M6ú>b/ñ{È"ÌaÃnÉY´g7’±|ù®*˜•ç÷Hûo?ºˆŸ†AUeîcqL\àGÎ}­Ç$nIµK¹•J¢kAÈ2}¶l703Eaq2_Å¬Dú7îk¡ ønÚí…N«šÉ…Â0Ë9™…#°–Gƒ$Ogå´5‚y…9bü=zLöÛ3"p\OåabÑ²)*2îîF?FújMOJ®xeç—kÅeß×g¾ÇÄ¸ZC³¸îÃ•Æ6/å6Fõoaña¨˜zbA8U¼+ÑA@(^QA&é‘1aqJ3‚Íİ´
«úÏ  ööHíwTıºÖÏ&dTğ8J!ûy“:G#Hàƒ¢uØ #K	üp:/ZøŠ“²0<¶C…_ø8±À<ğÚSõt_ÿÉÅèyÌÇ{ÍKïk£œ¡4Jİn ªÒSùğsPm_%MJ/|Ã·<§‹é'›\9Û³ô#dÔœØÊD,H.t®µµ2Øš´ÊÏ_×Çb÷åøiíÒW	ÔİEZ" `¸¹`/‹Çò¢S›—;!\ÕØ8>y®Ó¥úÅbí*;çƒ,\¸E¨·Êªê9ÈiG„MüqÕDœ†Æl–u¨†¤îÃ…CçÕso¦X‡—„"AwbãEo4WÂ_1¥Œ%ÑË;94péQ·§Ñu%6?NdB†!İĞ³4o‹üAfg¼ Ñ¡_2Pi­Q´zÒ]Bæ˜äÇÖM¶¨<Ém‚&öF˜6>6DBŠÖZÍX‡ ­ZxHÓœƒM89bOu¨ßõıê¾ÿIòGñèìâ€”>àˆFH·6³®Uş20`õ¹x KèÃVD™í¬1’º)P½æÌÕT1)–/7ÈPâäí³÷¤ŞœÂ’çVÁòÛÚ¦˜˜í*ıäÙ¹{Z†iØ“À‚jW®€¼¥ÆÏdQ¬cµw9óF‰š-aù³®=Ôã¥]ú’Xµ´Üöë2Ëş¦°Á †¥‚<¨b$*NS)´Uk’Ê¨p&`ûª§¶q!°§¾åÓÅ@8†·Ñ­õçÒ„)¢İYºl÷V¼DFûŒÇ‘£ßÍ]g•Ys#fğÁmí¬ãK_•°˜w¹e1ÅšÉÃ ^©y£íÔ—½—%h{.Z©;|R3yŒ{€„fPíjL®#ª.Hßò
R&r?˜G^RÛâpÈ¢^İSZ–xs<`ŒUmäHª× å00§Óçw\Dˆb·ÊÎÌÁ¡|§cPÎuD»/ü]¥^ÈÏ«Y^¡Æ–ÕÌë­Ëng ­Z,”,ù$ŠSS­7A@’èfS«Ã¢¤.¾nT!7³
¯“4–¼Ùõ-,·E‚®ùÇÿDZ/ˆ¤wÍig!øX	Í£	[îºÙü¤®v&KÅ¼ÇiŸØµêôâ+ÅZù¥±Œ+gÇ\÷U·ŸáU$Æ=²®sdµ	»’¨>—Êöi3ZË½Nxò|lÏ€aOH-G6t
`¬AÍ¢è!|à¼––j}l$ÅÛ–‹ç;®;I*)¼!±“9R±ÍJ]šO›k/õ®úÒØI¡ÇÈj(ÔùÄµ'Ğrã'ƒHYs€v©¡FøtÙ¥§ï3öİ®|îÍnZSÜD[ŸÍozMS¡“œ3è5¼äe¸ïí|:
'ğ‡Œä›”õğ&;)_õFô:á‚H»ãåáÿA3eg¦ŸıAv“¿ğa¬òœ>_ƒWŠnä*Ì¥CúİÜG@o}ìèz½\ì™@ùi‚>~dkPèêKºôõ¸Si9 <æäê¬}·›à‡Yî¯&PqÍ ×ÜVBÚŒ~ÅaO¹ÆjI$>.Ó–¢# Ù9­ú½´RXfK‘üªÌ-%h®÷ÉdQÖ×m-²Ùv¿4r7ÔÿÉ‘/à	™ç.B½ĞqIm<NŒ“ôÄe`ø+?—WI“xò»-İŞ1NQ¶z={w6Äº­Ñte.,2z="ü
I™ƒcš§zÚ²Ñú(£Ÿëg øˆ¥@Ğ‘ü{×ÕòOò7m
e2(&¦PV2ĞFpÔ+1AÿWmî²––Åx|)©ÍpÎÊˆmÉ 1ìa—y˜³/B»Jg0y#)R»_3ö3Ò@“h¤vŠÔ‰M`çÈeq”û–dğt#ùÊƒtES®şƒŞ PP4y¹nÕöAwğö¶ÿÆ/7GâÍ÷¬®PzÎ‡# Ö áİ¦CWä°î±b˜¬Ÿ’¶âbï	ß	àÎ'¯…¶«\dÆšL¬·gÊWú­,)$MbXl+¹ú²-÷ò`Øëêæ<„Ç¹Ug‚B{l[švÓ“½’Èû‡×ç%Ûµ¨bÃ“=	_ÒáU0N‹¨U¼REŞ!¯{ì—hÁ`¨„G<”y¡í…d†ß²ğ±}İx\i–¸‹ÈB1õ•<õ™êN‚W:' Ü¾ó™Ö*ó´¨,_uS¼ï<¢>*Ø§J–º›Z{G½’HôüFùO‚oyTC(5gz;”ñ6JNT·&!­`Á:fŠiôDÊU…K§¶{·¤z$è²‹	¦ƒx¡ˆ.˜Çö|ô1o‘-Ù.Qw;Œm/Ù|©³!88†­{²j—?ş†¶´brF5‘ÅOù4‘;ö±á"ÉÀ/Ğ•mû¤48¡vÙª0C”Íe™i2t—Dıà‘"‰lÏâÄ«)Å–š§Â7(.k*0M©ˆiQ®;ÿ=³İ¥VVtgjWKøŸŸ-©¸p€ıMBã)ÈLœn0VÅ ¼KIÀØú'ËÛŸ¾§@OÎßDÇ«ÀF‚XÕ($Òtã^ÙH¡GØâºØšNötlüºM#f¬s¤TZe¥?Å_»§]Èjƒ=bW÷¿bœ‰¹ğşÌmXÊ-vÙ)8Ræ›şíúà±“¯²vã‚OeH‡åï›Ä#sÄ¦æ§@/ÓIÆIß¹ïkşN¹]@¨é«û³ĞªXbE`{v$x2ù1çU’Õ_²}’™Æ›#½ó¦YSÓ85!B§_+âIcQ6“s{3ŒªGõÀøÏÆ€àS‡í^ä‡Ìos¥¯ÜŸ'Ü$Æui´bl/ú;†÷‰ë¯ÒzÑ˜è
z´ŞúN!‹+ˆ¯Y²<™©ùCf–~—ªf¬ë±¸şøkZkxÿ[ÂÙÖ{~š¿#†9~îé,¥v¡ásI‘?WŸã&\d îÒ_š‹t`Ø™¿K€‡Š€èzU|¹*‚jQZV2Ê`‡FÇüXcıˆgàPTª­‹‡ÔãÛ'ŒR'IQ“˜Ü©S{ü1bq~TW¦<cûÒUÆ2X”¦€hgZ¼ù*<Ú†Î:ÏOÓ
ôìA|‚w¯gz(ªÇ)FÂ²İevãú£© ~&¿*X.§ ²YXE^æ=$˜e#v”õŸâd¥ƒÍÔkÚõ½3€j2»KÙPªh¢8¼`,¼˜?ÇF¹ğí7ZUE‘€&PJÕìzõÚ=#ÈÑdªğLš…Ãş«ŞË‹Œ`Tùkz$\öXı‹&,7¹†O%°ËÛİ·¯#.fbÅ&†zŠÙ€UÕÅ"œ×%ÜçŞÊS¥(%°.t7;BPíõ›³d<µ3>;ƒk§>RR}§ôôçAòWlªÚT¾µ æ<“IïCŠ
çR*JïÑï´¯£3×iSÌoPù‚Ûhz&Íá“ş«e²ÏX:M“˜ª àßK÷÷Ú5:£¹ ªeŠİ@@É?8
Ä=ÿ+ÏQç4°ÃÎ½{k¨i¸´rï|ÓñğIš‡Dæ}íMˆwâÈMKşõØÏæo(Âo®í±¸-ó2MÊzPc_vÙå¨¶_„	Ä+6²VÇë}ºVÛáVà`«Ó°áÿbØ€¢ËPjâ³h'ªÜXƒî˜U¤_ ÷Xt’b˜äF™-iõ-m2¾W9õ|Oÿ!ı‘Go»)M|oŒID\B7‹ÖøÕ‰ÒØÒ9|(3™pæÂÊĞ¦ÁPµÏ@YSÂ¤¢Y×û­Ÿ§ÒPÑK.æ¬è#gŸ% N)²ooÜ{Óô @æ;ZÈİ²i‹½Ì¥-Ë°fè	Ÿ~m{(ïNäÁùÑ9û‘ê£ê9‰]ûX»†ge,UÂMæ;Ù67"û—Ü	‚§›”KËeÓ»?Èbê–{F…MüÉã·bóŠ[X‹÷ú_#É:ä°|Ö‘39İ\2xé¤]!‘ã—ü£q6m2$qò3Ô|ó?¶dÑ~’¤Ÿ´5]O&ãœN™Mx£ïX±ëÎà”%yµÃ¸Kïua‰yf=àPşå¥‘˜BÙÉâ[ˆZJj¸k*¾×t]Ü™Y&˜åmÑ),‘Äúx»c*Á…:ö†{—ˆ×Mgár ‡ÖĞ.‚wéÊ£¶,©»rØ(?u­ì6„%‹ìá£ ‘ÿş,ªRÔv«ïáÑ?šTObÖÒÅİ8Úkp¨w·zŒh†/s“YeVíxƒ²×ÀÍ§u5¾axAÙ1e¬Âø\Q{ÏE«;4ß3îßÑázÕfœl§I‡‚#æ}o\>øDyR§â¹¡U»}l¾³|òaËDhGz(èŠ¾¯ã2·¨¢êG;´ç7WUÎ>Q¬§8IPÉnŸOH®]²·âTIÀ!ş?Íd•­%‡`MãÇ{<$1e¾2ˆccJ7¯“ª*Ô‘ÁÛd0âi`<Æ@3/â”¾[kºiˆ=ôå·(æ Fæ;+6Œ8¬xµI*¸à¯»ÄıâÔálY¥—›9+÷”(
[ÍÚxV±šd¼-] DŒ"Â°Â§Wîcô·÷>/(U(’”×\7$e²ƒ1²›±Í~ä8xrMöJãÚà‘gÂ®Ã/¾Å#ÿCgi›xXuş.ìL‡àX·]G4ÁwíÀ¦ê0OÙ‡æô~Ûc¯¸4åïzšûôOZÉ?¡~×½Ù9ßZ4O«%:Z@ˆËaTEK¤ã‚| iD«İ¿~ ú;=¦¦cï}RâzÿÌC\2æÌefã²‰{±4]-°ªL–[L6¹.‹ü´rÓÑÛ=lõ¾üÒÓ‡©øŸ»š¨®zDºÛò)w¢Š%à ­Âä4„ñ¸Bõ;ÿNK¼pA6Èß›®vB#L†ó*\9Q¤¸üv­[áïoéZ-Û—´NKx»uà´Lg;Ôm}˜§‘
AsuVåK>ü¥XKì¼‰7'ÄÓ³ƒ¸)ë19ÒxŠ0wÈĞR°ó‹öxÏÈe80UßXN@ê JO' Ğ6æIÿc%¤w75/‹'@ïØÉÙ‚+îÉ¤<bîû]?·“ÁheX
”Û†A:“ı³*ÿú4•k4/İlØÖÚÃÃÆ% ö³H^²ç´&‹œ®©r³@ûÆD{ÁédêbmZà¥Í&ÁÌ8AâE¿¯³Æv5úöSS-XD3Œ/e+S8
ÇÏÃ»0®˜~!3zn)#,ŠûEÁˆAú^OóÃÊ~>™óÕîóïò–¢Ì\+Ó!¿p±|öÕGC¦ƒ_òÔ­^Í› ^Ã\Å¶ô,‡‡¹öL$¥Rÿ0-p¨ñğ{KPS”©Üx.(H¤ÌñyÙÓ¾wwwÊ5ç—ÂödK„‹`?ˆ$8AŞ6 œSlòïCŸE0:	ü)!¯ˆ§`éŞ	ø[í@X´A[èJ
ïdDÇØìŒÒß~|]C#—BNûÿ€±ë‚"Ò|îH¾yR…ÂÜÓZ‘X	×Ù–¹‡]œÆÀ	ASİ.wÕ¦æCÜêfÆ¨„‡>êKgß1íLy=,´ßØØú‰o|§ÍZHœaÏ-b¹Mé¯„ÖÓèkÑYÒwÀ¯è×µ4L½/4şñ£¤Òêk9
,Ò3ÖZ“³ü#%3»Â"‰É|ÍÌ$à—#ã:©µÜÈØôü0ÿÕóáß´e³Øâ ÜhÏVßo†Ç3Ú¤×Å_\Ø°,†ñ–×C4iàRà1#„i’Y$‘`·|×ê,¸‚0‰Î\ªÏÁQM.–¢>Rñ%Ä$ååtï<É»Ø5ğhëK*-ÀCj**^^ÙUÀbù ¹Å¦¿9©‹í)Ò„ĞqG«Ô –ù1¯bù\À²è‹¥R`[Û†7 }ı/á¹ü*™&NÂÔDÙû±aFÀ$®‚}Ë ³mœ¹ÔÜFûh±Nk÷y	¥–=ÿlZUğ´SŠmwItAùk—F<Q¤ªÄ\I_?í3–?_I“»€i’IB)©ÏõÁ©£‹-Ÿ <ºd’Ë¡µs§’”zÒÅ‡Á#JhŞw„RøÎŸ¼Âm[¡óŸëÜ"ÀiaTıİÈ!º`ñû{,ıóWŠDñºåäWh1_½EÂ‚—˜­ÊûÌ¬îk*Ò±ìµğ¬@öÛH*šR²ÉZ1³,š˜dŸ^m;½HRÈÇó ŸªL<ÉDË†¦ÄÉİùWœ½³]¿9i@}¹	(qû³!>5Ü’OU‡D«¡³p„e·=ÅÅûCö‚g¾=TCeèlİ+à9$˜ŸÁiè¹ìB#Ùì­ô\O»?Ê,{„Õñ£ZĞôò. j@À›;è±%0¿5jwÂq	ÛRÙÔvÒ£8K°;ªúÜ
Â„à¶DÔJëQd®ç”ö„j_£ğuòOï<_‡ê2İ€b€ÒâL¨¯ó:‹ôÉç]ş¥¯«ãVJ°NÉ–úYÕ,Æã–ş%›El¹3¼pÄZâ“§¢P4®
‹I§°İbd»ÑAæãtn¹+)IG¶Z±½ 0¿7:lÊødüºb•8“/Må¸Ã›5ìT³YírZë!Ú’"l¦p}ÿû‘Cv©…)¯r²ˆ1şR	ğN'™~nÛ
ÖğsZµjõß•+´'ó(¯Dâng;)‰`\¶£6ÊFŠè»“ ¾xu²Nô i~¾üøó8dj.wmÅâ ;5U2 )gÌXQC¦ª"1¸JS<(£ÜáàE/ìd–7“"yşDÃj r€'Æ¼İ %ù#·Åş–‘ÖG£NÊ
÷Éƒ’ÀBÂé‹=$…†ådoª~­E³Äwás»{a1AYíÍé<~›¢—2Š=	Ÿ8I’l®&Ñk]zÉ€I§’0¦WÔš§¬Òìº2e5:‰Ã›diÛ³wÚr!…!L‰şëoœÑ!¾ÏZî!ouš[¦Ğß0ØÕW-¥áóR\Ş­’£˜­lÄáM1˜ÁŠ*%ô4ˆ"Z|rlA÷(5”'[©q›}è]+ÓĞ¢x7„úõÓƒ²®‹¢…®S•„r ¿á·‡	#£€ä¤¢|Ò8­Ë½ĞÖ´oËòß)œ›åƒ»`Y Ø#[tX‹±¥±ÑÌî+aâ¸èQÇ ğÎ&^®•½šÑ(rìğ·ú¢ ™{nw4lJ Æ|í¾mc‡•(®k'ûòï2W
V'J¥E‰¯¼
I.²5U ÏìÑKœ(/S„Y Âú~Róõ Æ¶TÄœü&À’´LádTÀ|¥õ#Åà4};Æ}Ë¢Öç’˜rÅônhôCqaS\Š&=Ã˜ÅcŒ7‹õ‡µ`gä¾¢™§/êÛl…—¤¢»¬—Ä4JL*$6‰Îåe³_ó!pİpKàÂkÍ‹­üA
Có°‰¢‡À-	X×ºa‘‡É1ÍÚ=µm–ZxK’ô6Qz^N+#è'±|Zãî×dŞ/®4GXnfÉV›x0·º¬µ µKÛÀŠß§zëº
IÕìHÙF…²ÑÇ©g"VÇéCCÂÜ&GTğd€É~Û©­a\;ŒëÏawí„Áø?ô¾ïF%0¯ëT²	ß›KÿobU}¢ÜâøÑ¼2‚ı„}VrH¯%deW;S¹şíQ!×Æ¥8kaŸf	¡åî)f;jU¤0ªmI>£Äaxg%/Ê@;vØ›bÚku@S`ª¹ \ÏüŸZši;kn˜Z…ÏŸ»ÎªH(š †bnş¹ZLÑÌƒ“_ÔÕÍe»¬CP]:EÂäÚñ5B6#u6J8&.¡hÍEi+& 'éÏ;¬j^¡–Qï>~åŠgØÕ—­=Ì°g²ù¡i~ÍŠÃÃÿ÷ô$r
ã^Ï_¤¸8apãò¯Õ¿+tõn·­²BÙ„oÊÇ€B°$
cÚñU³ã<¡wÀˆÜŠş™D “bÏTÌO|¶ÿ2m:Ò#n‘E<6Œ	œ×4¾Xë2ğKÇ4°õ—…ÔÚdHıš‚`ˆª¤ ÃCæ{¤Ó/¡ôÜ\DF´XIoJÅÈjh;¡‘_>øoØø¯8á™mBæA©Èƒ–&ğ˜W{C%³»àhr—ïHOÓ±`·¶‰j¿3ç	/û¶–•¤F}ùıï]ÅÇÓTñÂl1{E!*b«ıÈR… ·ã£pâY¸Ax¤‰›£…tpén¸ÿ%ƒ8B*ÿ4¦ŠhL1 Ò26%Şº£¾l¥¨†Wıôß¡Å¢à,ÑSmÙkĞ¨Mäâ#ÅEªîâ±EJ¹ìäÔ+Ğë²ß:%İÚCş@”	áK+¾	¾"É˜ï’im´yz·ªÛ`Xï	~]ÿ:eúş«Ö·
¯2<„d9“ş¨psüG€%H6yƒßå;‡,•Ë^vCÕeµòès±P/¢Ø´WŸy^Æ¯ÓS‡ç¿ø1´ºÀ¡·ò¨Ê}%øbZHÌ¢Ø—×œVAúæj“°©4‘õcÁ2vÊ6Q3”ÉÏŸƒä[­™0ƒaûaƒˆ>İ˜ú¼`›‡»3##¥:âr7™z–ı	#v\ğ‰ä@˜™’È¢Y#2”ä˜®ê £ó¶¸ZñEù¦»HƒÍÊ½uD.ĞíìAœht’ä‹©(Öèp"Ïx¹+ ÓfÜ30Û»øw®ê»[¾3à_²Xr«×ğÃn°Ó%‚qÜ×º(
ºídäÂCş7£Çê5±òQr`ŒL Q„†s>Ëçs¨§Ğ, Ÿ†İ”TÿéÜF‡€²z=\@Š<GÉ‡ê?á<t•şÛŠR5<»¤ïô
1H*ó¹îMPÅài|o­¤\²ÑtÂckIÙÒÚ5ÅFS`´f¡ét`ôº<+ûµ\æã GÈ‹	ä[ë°èU{¿¾‘ÑS¬ßÎ½¯m}yõsâ\°ixÎ÷†#èUf?õèK±œ•-äua|”LZ~˜ïÍ¼cüM¼ùqc	óxÍÜXr#ÕÌ’#àŞ/“nz[çøŸİĞ†…_¼,Ğ%ã`¬¹Eõ,U(MÃ6Î¦ˆæ1ˆ™Óv”½Íú)>ò¸hTrIQç=¿+ñÑR«‰5:ºçc­c¸ªÊa#ÿò„¥¯.îd ŞóŸE*m øZ1‰We11_%´mtÙ¿ô¸ì¦2'CvFBƒÍÊ–ƒéşûëš|±z÷ãŠXbXş‘9vÍÓPuÃõ_FàŸ=Wİğ´Lß¡ˆ× „º©i…"^„§rù(’loŸ0çEÒ÷ïW©UÈ¬±Ë€»ÁP¿o¯d`Èá‰©ĞBU˜sbî2\Ö	Ìäà÷4b|Éè÷š\üâØMSMp’%dÆlVìßğ	ŞË’MMé›¯Ò÷€Éé]5$fğœÕ—[ûä¤İÊ÷¯ü5^Z®fÙ“Ta	™R'fY¢Û®¸<‡§¿ñhK¤d¦OLêS@€ĞŒp¨À©iRc£ì™#Öæ6å½iÁÏZL*Fœ>¾Mõ2—õ­·XøL-„b]¤[WØºß$»÷¹å¦!¯ÌdÒjZS~’KnÈ|FeAŒ`˜VNƒHÑ2¡ï*>14"WõÜ»‹	¯†åèVoï©“ğÿ?$S»dòAÜ5gó5kàùÏ³ËV’Ñ´½NilèŸ\—ñ‘­8›Ú¸J¨*hF€äfDøÇÒ¹Ğ×uyEBâ]¢Û'[´~K„,°aÄæK>Ğ•ÉrŠöï•Z•®{İ¸¿&Ñ¶®‘ûûQ÷hù‹m6püŞMl<–ğ	…PNÊ.ôk¿CHçÁÔïµ0Â§)ôq
eP`^w"ÃWÈeõ	(àç YHQ×Ãúı· Ë¿6~lø°ºË(;{iµåÖñ¹[z†°Ã¹æĞò°6Á•)2#üî¼•&›O–ë"2«Ãì¢JèB–ÛL2ä.¨4P3ªAõ=à±×³cÚ¢ÿd£ğÙÔ¢ËÚ•¥Œì¤§dÈ÷ë7“(Ùï;ù<ÒİÊFw]Æ#u6úNx–Îá×J> õÛKšw}Å±¾…:¬$HçêöEÿùŠx€æ$ÎÂ‚ø&?5ÆÇãÂìu¨Òi÷ŒÍùë¹\×M9{2„Á°¤¤Z.Ú¾5æ;F£q»¬€RŒãšãrùÚIh­ìñŠ/pè®	×+/ÀöÕ'/µúÆÁƒ‡Á:Ğ¶ãƒpUV_¢”LÑR$Ä%úXÉÿM´Ñ11³Ğãx‚ÛuˆÁQÆò#iE÷ÑñÆÕ€LêìtùÍßßGÙ{IÉÒM:Ù“ú)RmbËü1ëgÀİ»MqË®S	#òY°'5ŸÜæ+µÙßL{Ù=€{-Ä)Rİ»‹ëˆåçÆu‚f¨ø“êù¬QLæ	.0qpë4ÅeE.ÊŒÎ|Ö¥¦^Û¥Éhìñ]>l*ÉİRO/ëKò¼6OÀûbÄSSÄŸp^—?"RÏòĞ±’g±ıÛÏêRÄKk%„)ÊY?n×ÂÏ3»)Ô"®…Ç¬bÏqJÃ•»W5û”Å½½ÂuÍºî¹0ãÜlÊ8çæ´¨@ĞˆDzàvŸĞBB,€Ö†KƒÖùÚI,	‘Ş~ğ!‘5
7@³®¥*üŠ_›nsgà)ñ¥HÈà×=Ÿºòòç´´&Ğ,Wğâ‰*Œ“ÇêÃi¢‡@È9pExÖá'ô”İ¡Ò«v»½[Áå:<n‘zÂ:ö ÎLç÷ßlRm?é™ŒñeÚòŒã<´F²ºè¦°­™RÃd¸éAv3’t‹lñm'h‡İ€»„j«:û¢‘¸I-yfIyk£]&ø'k‰q¥™à² ™È*y}«ˆ}ºÙÉ eƒ×c†JÛ-tß„ŸéÀ¾ÒÄ&ô;æşMù½¬
Ş2IªŞs‡#³`‰òª~/C3[¾;fŒõB=vİÈÇØ¹s%aÇ\©¯é]æ¯æY‘ù3~K\aña)™I¡:ØÙ¬í¿‘_‚ı‹Sx* ò÷“zŒÊè©Ÿ’A<Ò–YU ©fJ”ãv;Ö¤4¨µÅ6Ø×œD­TØËûk@ˆ\ú"ÂråLf®™ç>†ŞtO­é²0ÖJ5…Ö™Ğ™ÿ9¤½»]qn-ß£3{IİtHz}ƒm	lå>bï[cƒI±ºwªŞMíoù.ÈêÙ›2N(—?’äïŠt™F&™0y°HŒØ¸#¥¦*^•ª¯G€6ZõY%“SÊKj}Ğ™Ûôµe´DæÎG«üå›Ö#Õé	Ê“–¬7¥î³˜*MMo"NãÔÆÀŠ{ÂìhªGYÍb$õD!İ"¨”ª…Nƒp¨H¼@­yô6YÙcôØ›ØÀÆYãk‚"˜ŸUÎFäÄÿ“V5™TK®8|óoµŠ£8>DÑuiêg¦ïÍ^…äA¿$âµÉ6´ àQ@9o-{îaiÌÚ_>F[KÛv–†¸Küª-×y"ÊçÈ‡0At+à¡/¼©ïLCßt@ª†ü¤ãÃpPna9ÛÍ»æñ¿±¼Zô<ÉÑßÇn;ëşQ¡B‡bÀ¼¨a&f$ŠËêÛÉ~5Ëˆê·«Ó¾÷&ÚHô”HHüäì¨DHE»š§	Ğ½†„ÉµÉºRûš1ÍØ©¾QµÍ»ÁK é¶ñİÎS·P†Ê+ÀÛ§H
\ûãó3’Çßğ¡”FW¡	o4ry“nwÜA©óq5YTë¸ÓEê€ÕˆN—ÌâHAg*+A›—›üÌi._HßR³7Æö3íÈŸŞq¦&B/”É%vÙËw´µR¡¼ Òx£ e"Œ„¤²ÒL~§¿
ÇöÕ@î©$œò/Ôï1 ã^9ùò.mpâ“Ê0x4—÷ ãñ§f!ÀJ…éqjúYí)]º«’Â,V¿s9<” Ú­wè‹>ûbˆ^µméÕYÄBÊW/RÉÔU#ïyÿö…iñ‡(qäMÉÆ+ÊæÈN‘©C*®Ã&CnÙ)·Òb©2vÓ½SN*Aî¥b”×*{‡T^iÄh»p—!±ét¬µ©( qª6Ô´«öùª)¥ËœgCØ÷½Ù”“gfš)ò³èrº|«VQ ÉèÔl¡ıVñ—dG¯ğæ®.K÷ká™iN‚GÊ ¾íx½
W¡I)¹˜T¶¨ËD`w@fD×ü ŒÇôÑ)™½€—*`Ù` ıÌ“1ã#¼÷°–®{ÃÂ¬ş ‹—¤øEQ¢«Şºû8üD?ˆ]%º–ŸŸZÂíPdkêqö“VšŒrh 'ğ)X:^ğçB`^¾âcÄ?ñtÀ(Ì„ÿª0˜?úŞuşŠÛw‹‰'¥¾•İQ…Ÿ#ú‹FÆ
Å%V•¶G‚!¨¡–çõÓ3¾7¬{H-‚ïşópLæ¡¬‚f7Ö§üĞu.ŸÃk”¹²¤@=|ÿå„K#~ãùÃœÑoãî*DVpè’0&Ö×‰ÜŞ“}j|5«ôÃ>#²×ÌëK@šc¤ˆuh@fÀ¬¤q¤rÈlúS_1pß‚6£»îüq™®ãªnXE:«ÎÌTÑ¶„r‰p7Ú÷ˆí´XÎ¤N?/LfHàd7IÑi7°S™£Ëi#5–ºĞºä¶#nùC-İkaıè«£)§³ä!œäRu|È²sv´m>5jè¤ÄDøˆrƒ=½‰22©÷‡Ï6ğ»ÀáÖ5r±£’bò¤ôd&#ÍL¨å¶O]àW1ÿıÁSö˜¬$/&˜úÜeäkË…²Å0ÕønG9”øËd, ıör·/¦2@À·­ä»¹)jmDõädJ6¬8~Ã?ì-©´IËO[$İÃ/Ä4Wƒ~¤ÉI2•	otX
lH¸(ëç~wdaê€ËôUûÑ‚$¨ğÜûã÷ı[w–Y]T¥MÙ²-	!1Œ¦Í—H¦T³]Êmˆ£¿$¦ªÉ´ä@ƒ~ÄÄÈ>N×,Å8şËéÖÅÚTg·O|Çjv«ŸèÄø_º<4ÒzNÛƒ´ÂâƒUú‹¢!9_d(å-˜QµéÿAE¯Çêˆ?ŸRå¼fšº‚B~“/hşŠyÄ¢ŠI;áHÅäÜ¡‘Jó¥£òM™“-Oi™TG½ŠD
?â]æM½E‚qn@­N,n€ÕÄs301†j&½KÃC¹74æ$=ó£¢	,btp`€h’®À=1yĞÕu¢P'Å¶ÁÖ¸éªOÂ¥şö×ú(Ì>ÎÜí%ÜŠK‰¨°à	8ëØC÷AhÑÊë¤N4C·¿–ş9•(¸–”ìéFÚsM$ì[—5­İm;‰BLéópùŸãRWíÏ*}	ÒÕÊŠÕ9úw‰†İqÏÔ¢OæÙrUë—¿¹B‹Œ´ïÑæï´!¦2ãì3Y5™;w˜ƒ^c0ˆòQ{LÑ•Ìl¯ú7c<q'éşŒÎ‘JTÉ8ê+·‹n–T¶ c£zÈÓÁÖ½¬F[¹„ÙÊUà)+v|õp×p},ñ³„ÉüÓÙ±ÌÚGZfO
‹Ü¬jFwôŠˆi"%KvÓ«`õaÄÓN-:İãhœŸ˜gİ¥‡ï_Ìzp}”@–’_·tÌSÄúë¤…¬ì×fõQú¼‘mN“›/™Á@6zÁ¬ü¹àf€™2'q§êbJó Ïª®İ€+"oÑÙ˜~¸¡6¹¨ 
M½¡m¯X_öK£ï!ÉdìŠA‚iÌ5»;¶Ì§™P?õ§R“}‰À¯K‰´J‚ÁÖÒÏæ²øxõ}€µVg\cäGş…ÙÕ•ûcÓÿÔ†ß2°;»ùX[—ÒøïÚ»øíâø«Ç%›Ó¢%1Ÿv€+3ï®#IÿmmI3ŸÃÏz@zäHf ‰CoÔ•‚è3fùØBûk„iÚé‡Aã´ œ_Ùæ¼nòÃ^Q¯``wjˆàx<Ù«±JÓÜ…—`öG+Œ1D±„…ëÛr·  & íµƒUØŠ¾*¹Öù,Ù…şFíÚ&B0w‹¼L¢Ç®`8J5¾K#&´”MU¿t3fÈPÄ¤gh×şå’öñTSVêˆx4ËXEc,µK8ïŒ£´“çp0–v0•‚•GI]Å=ÈĞjÏËi2Du¤èÄçáiß]ûµûûÎP¾"©mÎ¸Ğ9ë'Xu×LóÜ¡ñ‹ê„{<¾¡‡i|@âí¢º³ÃNµ©IÆTvlÔ"JÙd«%ŠnÅşrŞfËÅñşèÁğ)Ëzªüæ›Ş$)¡ş>åİÇïG©Û}o'T·¯¢Tš÷$SC.°JßéM‘ ÌVD…—ñ_¨©í  JêbM`neEh¶;_¢uú¥ŒCZÇI«ôFi¢·zT¸´ç0îpOêiyÆ.Ó9 Ç¡ÈC %MºÉ.¬ªÌêŸ“}Ëà;ğ9Æ¬l”I[Š,/Hºœƒ(²1ıµ%¤÷†‚Xè"eÇÅÆx:¤2*$8{Æ`êÍ0ßšWCu_Ÿ[˜a•hŞœU¡ÿ‡ª¬Êı†å*µâ›ĞUş,Åèw:B±cÀ@drš2fÃFû:=µ‘‹[áû ğCoĞğğUƒ_Vû4ı³3#5Û¢­İ(-úæÀ˜^4·IãôÆü°%¦¢¢ı³]«5ßÏáÅ‰ÛI¦¸`²à_á8œl{sê{êQ›ú^MvÌwÓr¤Ò{¹\OX¬Ïu$TÙ¾Ï'ƒfÊ›‹[jù²ä¥(e¼^´Í™Å— yÒiÃ>írËƒ®ÀMşär:`;äb×oÖØ¯¥õ’»SØ\Š‘‰¼WÜİqŸòßîk¨m[·¹àó”Ãº9ÅRUšâÙŸàF-¢~=tÀ|5¿e^›â‹<§!î¦2Ò<³~qÏ_½ ŒFS¼^£}7ğÖ;]É>mkó:1e»1`(Ö±bŠ|*õJ‹ı«ôUpÌá¾~hº×üÑ|Xcá‰!XèöÍÒj¯VZCÅ YÕC*Îd ,g(Ü°,@İ<Ñªv‰ƒ'œËBnıè?¥Sß4È(Ş;¥lFG´%º’Ù³œ×„·R«eøxœõ±¦~w>r^Qó“ÆŠïd¥§ˆÆ¶¡]‹ùÖá9©¥ˆ}QŒê{Œ~Ô”!¿Ûldx©>ùHŸØ!ûëVjĞD=.
÷âB-¾h—#78R:g×iäõÖşÕ*›M|çä÷mG®·8Èâ,EMKõ€k¡´ğÓNáW§BÔX9cÎ\İ¢mN1=u”üˆ”¿€)FÁÓùbĞº3 %<TæŠ1xÉ°öyÜŠ-3^N3—Œ¼÷9Yúh
@eù£ş¼ñzıë¶ / /SÌ¼³¤æ„¸lQÉM–ù£¥ÿy˜'{”…ÙLÛ˜¹[aC¿Ä7H}·â²ÛµÁOªõ”›['²% mÁÊÀ6 \ÜàåfT1™[S#™ş5˜f*4«ûJRœÑ6ö~Ù}41ë³I¾–}`eê]Vq½”ºçÂiıå+oå'Š ^%â RËª•ª“ŠÈ–jkQİOŞ _gè"|²{Â\&¬yb\ªzÒr€§İ—/‡©Ï•A—öU1€%²Ùº¥š*¦`šÓµû}I_%úæ}L¿”l•ü9T˜m¯ßoZ"®Á^§‹]-4³‚•39ŠFHõñlùØçzôüÖ¶\fgÔaì#ğ«cŠvÑö«’Ù%Acõ!À&A´:RÂôB(} U9rtkjİ©-şŒ5)ŒØJ•ï QGz"gå¹—7gÿÁÍsF›­Qe‘Ò†G€vû©
“+ºÑ0EéK¥•ˆTŸw_†Îwg!!¼{&9 İ‹æİo´âñÁq^iP0³?»¹Ó˜µEÆßÅaÓøúGÿÀOìy&z’¸ñ.k½MD–Â<táCJP’'É\2ù9ÂCğö"rT{LºÊ¼Ş1/é¶Mí{ˆ>ÄbÔc1±£¡z«”•˜8Ùç™:¦?íy§¬å=sÓsgˆqŞ‘ÄQÜı8²}I”ĞÍ£Ú(|åÃWcÉñ±,Ë)~õ;Ô™—ı&‰iáz»ÌšyòæO Óï.—Öøü¶^•~¥Qñ]],ë@ı=+zoMŸòƒ—¿âÕ?ƒÖŞ µLV¦ËGe?­t'vá	}Q‚ãPI{0VEÀ;ªÏüı2Û¢|Ü€#¥·_Ô¿fáÃÛb0u¡şŞVŒ†òÚ®<ï"ø<ãª'‹‰0ÔLj,fxFÅè•ß{Íà1€ ƒq%=H!Õæ¼Ü„êA‰Ú¥€å5sy²–v<öAá¯M-m–Áæ<ãÏ\ëù î‹ö9Ø}ãì‰$9æØm©¬æó— §Ó]5d5æ’7p«FÃDÉhRO…{ªzKg f€É(cı_=øÚÀpŠy¾¬¶Ke½}B ‚chi#÷(5T‰ó–3±ÛÅ¼!÷ÔqHNé8kW¿ÑKĞü»¤¹ó òÓ‘Ûì`ÙêÊrè‘ÊÈa£e)Ûİ©¯¦ı §•³‹œñuCÔ‘¹/>€›À8fÑ.FÕĞ÷n)óì,ª ¹üX:É¨–½ÒĞÇ|*ÑC[®¨0é²€¢T²³$`Ç=q ³˜ì:”–“zå Ìœ*Û­G}í`RíÑ&½k¦tM›ñÊ›ÔxßIMÁ³‹8"‚]LŠëämµ°Š{²ª»WÈœÍX1ÀOµUmÚ3îŒ ô²$•A”‰†(û ¿‡Jºı)/›¨¢f­…RdÍæé©MiÅà„•jy’¶”æj@o,Û*¦p IaãMàµïfLçÓƒİ*p†<ıx–wÁæ¨}Ì*Øÿ›Jõ4¡åtöìªxö
ˆW2uÊ)TÑø0óô€µ»=×m«m–<:k/-øŸl@œÚ¾ÙPy&‡ª§€ØöX‘Ç)ŠH¿†ıT_~QÍOiñÈX7RW)‚Í”Pì@jÔ4l³³Êà.ãÌqí¢h£¸ÎˆŠ)‡BÓ	ºë“ÑÎ¿ıÅôÂYÚb™Pzn•£k¶ŠÍ[->ò£ÒëJ?æ?ã©w!ªâİõÍÅ`z„n#zBîÊ²µÓåaÿu`¯|£Í-ÏV[W‡4%¹…‰
Yİñ·ïrgØ:ï¦íşÒn]ôÂAÕ;ßûKìÚkfrOæüxû¿“`=H#MŞ&Y8‰8ş§[ÔÅ·*>$Äpfç!š 'h¯FIü; d³„Å¢+QšOÛ~¼aş—"]Ä«´NÂğLO!eì™š††,Æ&}ºbğ®Ó‰R:í›<W×ókÈKG¸[+œƒÇ×â_3¥XrÔÇßæ#‚qÑ–» µÖ7cFm†!¶V\,1î!³^‡WÚ¶NSë“zk¤İ;®JHšë\ÒFóî4½íEóuO¾wö›˜+&K®&p³Á²‹Üùªcÿ®@¼%­A¶Àğp„åT?Îğ>éöW§¨ÿƒ'EXrŠ¬:4Óñt(¥oÙn7şÒÓÀ|]ú™"ı%£ééi-7 `sÏ_mÛ!?'¡‘>‚PDj£xY	’ÅÄ£ø ½·¡µèFæşBq6Õ¨`c±İP)LQrúMMjš SÌƒÓzßaŒV•Á’i‹9’ı•äq&õ±‚Ì&6UóŸèjéş‰tÇO¶„³Â¶Æ×ÛŸ€œ•£õvµÃ3‚«2.£DÏOÉÌ
E¬Dó!	–¤ğ;•|tb1/K–œ¡§èb—…U'GìÍCüØs	D$ÖSíg™§ÒŒ&€ÏEOäø{®|¨onD™	 h­Åe?t&Ğö.‰+‘\P_¤ññ±å9¢ø·”ãJ¤ovøœNÊVÛã¥+x”dbÕ‰+èÀ5œ…0Š Qõw·ıZ€šáÙJ-"ÎwÿætÃYò·oBŞzêôÊ¿QöCˆÆê;.ØVûË<¹›4©ğ—?'PnA°^ów12<ÂÕª¤oZqÒA	0A#-‚J‰…Á.ü½æË‚ú‰ffºÁ…m×ûl6=¢Ã%“ˆU‚‹ür¡”†ÓÉ©óÖßUç L–rfü,D¦QÏ>ö>İ™}HÉ«¥(7‘QJÈ©OÅ{°Çí+µ5¬Hñ{y©­ÌR×±)ıæÀ‡€ë[¡õ«­e8×+F1PË"ÄÊuX˜/5À¥ÊŠs8\_:Opq×…OC8'-)%B·PjslğÔvÚ}©D6Sø£˜§VeÓvàÁ6”€2ßÉA#4R§áöº>ûXAòÿ0^áºöêúXØÀëçPr¥Jdµ&ÜB÷ô9fHµ©èÃº£À)iCî†àt_h@çwIÀ?g‚Ñ¥Ép–=2l£ØX6"œ^ÚJïµî 0^<7_·oñ(Öü&£– #Û¬emi«ºÍ…~.*Èk>ô4ú¤mˆÆ@F¸iØLXu)(rÖõì¹?1w!§¦.¡áéÈ¾>2œ3g§»Âm*ÄMX»ÑÄ±ıßı¹¹Øû¼MÈo@z·:VâP¶Q+A-~Aü%lµ	àBİİµ¿í›+ásix…7Û*¹ïÔÊ×áàÿdw¬ºªzB3Àrı‚Ë2XÔÜp§-ªğ>XABbxœÅL‹Ğ‘ÕÚR˜mıØ\ßÏ]XÅíÛåÑõƒ;yYØª;ùisĞH˜Ü¹,X#Ù [|¥ƒ¾	&©“¹¸Õ)ÄK·ÅUF/¿5µF:»u\$Ş­ZÂKl)ÁX^€§n”0eMİMz$Ú¿SMÎñ°ÿog	Ô•@^wˆÎà¥ğ„.å|·˜¾’àIî3
È!c,İ?¨µ‚«ñáâX†öÃ	0é˜¿İ2ôÒêl"»îéØûaq‚  õ™ÀkÁà23•‹qL.)aüàë	ÉàRÌ—3Û¢o/ö¹”}æo¶ñK˜%Y(ÌJ0ÒeiÌ0­ë½eò& ç1¿3BSÎmíä;íT\u½$Â%DÉJ÷áSóƒÎşDÇpÑj»Î Ê eßP2ĞË?mşÀ¶@¯ÚæJøyilİîØ:ˆei!™¨ ‚ãí¯hE„Iß|ğ¸_ö…b¨9	ZÍÄÊ}ß0"aÚ¾J1™ÿ¢ë*,_KÛÍÌFyÕÑ¦ƒ%’}DÛªn „Êf±àsû±ã^î“Ú3o{5Õ¡uğP˜¨zG…ß/C×<h’Æùü+ò¥[ÎcÈZ‘Ÿ’N6L(Í€âî_¼×§ı]aQ2’á;TƒÒâ,ƒ0ú¼ª„Ú’2~AöCş{æª-Š‘;â¢Üš¯Ä•»2KÚ7y´“Y=ZDÖ$ÖÅzR¹›Ì5º}¶3Ñ×‰á{Õ4TN/­ªXƒx³áÌjƒM^ÍÏ>&Ù}wèh \iÄŞƒ	É­)-¶„ñú ü´?#÷j¨vÂï†MàÊ<¤1ŸİÓg¸štq²0Öâ{ğèêÿªşê¥ÒãÔSqªÏŠ"öŞ^ø13?h+uYiY1‡¸©±ÍvÆÜK:É ñÅâ Õ_;ÄéhI”†˜»ÉØ²['Ùwğ"%‡ÀÕ§}^%Öâ8dZT+W¿
Ï+ş™>ÜÍÇ^;. %£³ˆ’ABây7ÄCŸƒ	”qáå+qúZg@¦ŸÙ=[î^ÃÍ=ˆ?'FÆä¡}‹¦¯}]|Ğsh Ï‘/ª sI-Ü,ûŸ5åK­ì¦Æu•¢ÔÃ‚?Åj¿€E»1yO£{Ã‚ "r?àOÒ¦&À?ò;8]æhN)Ğ
‡ Æ‚SÍ_’C£æ~—cºÈğØ›*ëÃÖ”‚ãt›Y®wzáƒñùÌNÿZÈwº°ûœÄ+¤ª:°q‘á²å;¼eÁÁøÆ.ù ¦ˆæ÷`C‡§–ÌùË%2 ßúÈ¡a«Àc3Òxƒ­Ãº0"–÷åüb#õqò^ùP:hÖ£ÂXškJ€u[Ç]wù¯©ôR x¨Ì¥ú£‡yÂĞîœCYwHP8–}²ë†K]/OAÉI>e¿F4</&<«6ÄĞ·gu,£ğ5ÄE~€ÚòtÀ*ˆŠ¢!cŠXf'ÜnPEmÓX×ôÙ§q¼'h¸AğsJ¦M¾=ü¡G Æ¶Z¥Tt3*Jñìî2”ö+ G]7ã¨Ö³şAWåÈYØ£ÄÇÆëññly¡ lpÄáH2´—ÔX¬ÔÛ–ÅzšWKeï+øg,¢äc	÷¿›L¨Wb2Ë´ÿÜgÌ9øªökºôPgØëN\+!$îÉ%E'-d“¡z{şôÔßë¨P HQ·‰ñ_ùùDó6ÛQBr$A¬/iƒ¿†6DQä[S=Ú„55´Ü‚Yµ–j·µ«éE•OÚPÜÆoqv\t¤Díú‚yuâ¥ÄòÈ¸]ZO*Jƒ'€ëFÀNúéº”LFb$mï:lı½°ÁÈY¸„]_É/%-B(Z /Vi-Üÿ9Çg	¥¨ÿ46 =›%9ªß½
À¼‚qn–çÂ±È,şI&Iµì‘&|•<çDaıŠûAèl¡JãcH7:Ğ¡+²jr›4Ö»cT2¼–­Ã‹şçèfìOèÑ¯}
pƒÂÒ©´ñQñ{×ÚÄÕ‰-³µ ŠhĞZzŠô›œÂ†Ypƒ<îæE|j÷ãyŞKÍsWª`ÑL°M,OÄüë)¿ÌòJd‘¾)-$³ĞÅ‰O#ƒA{CAtx¾cm+…g›PJÈX+*½ÏÓ5—ªé§‘s"¼éğß‘"zÚ%Mi©É3k–Ê& 9‹ÏRĞÆKŠ¶;[šU>Ÿ~Szy«Ö;£K ‰ùŒ bóx(6e•0F^‡u&L nIığºÕßèÉ6ü¥Jh@ù†É=ƒ¿Õæ‚Uåû'[†15í¡2rsfbßYçè{XmšrBf
9<ño%T	6Ö–)|ı‰¥ W©Â=Vg°¶ŒªÇ ;EêíìÌ«@hÔ bfĞŠ€¡®{à†9	´åÙÔÛ¸Tü(#qœ‘òôÖÙX~KøÌšuCu¤EÙS„K""`ãµ}ü€”ÆôŸ‹6ï¥eÅÄo&za–HÍ²™S7÷ß„±Íd2&>¯K!ó,o‰”Ò[ ïÔœ`³Ş[şRvÛL³ÜlÉuéq»Ô¥y¨ñ¸p}w”ˆÂ¹ZuMh¡ÄBC©İ™M|³à‚€¸)²*¸ü˜™½G\oÍ6zr|¡‚Y©e½½k£ì¬÷Ú°å¹å#Ì«Ò"Üè•Û?<.0°Ú0¶›REá§¹ÙñCÇ"Ä¤n9,~›zCŸnV$rÑE1*xƒã»ŸLƒU°ü´˜M¿ËO½XÚzK> -³»¤Ü«ÕUè,Ä¾]0h9póT:BŒ„$ğ×;Eå¶!2* Îã<¿¹$R«ÂPV7¥‡Ÿ®‰íµ¼l[?tÃ‡«À³†€€ÜıV;ûü°Òü3È6àÔ<],»D©½Fˆóœµ²|ºş	ìjÌÂdŠá3\±aÀ1N»¥3ye¨=éH‚ÀXD›¼ÇóÇnéYÿ§Ï†éêv¿u§ãËÏ¾«jËyı€*˜Í_Ê”4L¢k¤P%ÂÕ_¤?Í˜$ú$&µ`n5ñ=”ƒ¦Ø¡h“öY“3Ì[&±CHSQ|¢pÁºÔiÂbC2‡ÜqMú©‘õ^.ff‚—–†ÚHæ`•Å‡wùì¯¾×<ÜHIÂ·×QLÖÿhß^ø¹ 6÷ÿ×éŠÊrıë «¨P¾^ôŞ4påi~û{Ck„Ş#v¢‡Ûr Š²9¼³¿L‘ÿI5úII¬Vn/€`Œ¡à†ï»<„õööÜ`qÎ¿;Åõú¯º…ƒOÊl)‹‚gON¶:§ •vcõÚ36Z¶/Ö=:Üé‡¥bÒÜ ŸöÁ"±’×¨k¶Ü«¤¶ş^ó-´k	„[ëªXÎ^HjRî°hND£Å`ÏN Åñ™àgè.o¾s]ã/ËŒTo+AËş»ÃÂÈ˜(<9…¡?DEc¦M(Ğ?ÿF¶¦)Œ FJK°t…3¬ší»óÛ7áÿr·óÈÁ.#EvA;K€¾ö­İÇÌø'zFq; Üc“3eÜƒ ~
d6BÊDñ4?s;yÉ7+IÅ;%2Ušèx§Ã]ÁbÈ4çIvÒR6ù“¿à«ÀÎ7äIÓ?‡×]
Š_ Ğß,S´$çî³ÚrY|fÀÎ–AœªÌî§Gr‘
›4—ŠÃĞÊpue“ß"Ùí’CÃĞã#Fkˆl¤TŸ,G¤½XT&üN"b#yxÇX^òvE…‰»ŠAÅøÆMQ×¶&QrèL=V Õü¡+ÕwE6D£~Óf:æ}zpéŒ[Ÿš´
å;²’X(yìÛ`î³‰JdÿÛ)Hqd·rµõ;†áÕ†§¦±¥ƒÇ7áä	ûÚG¶àpx}˜,3a+#®ÂK'ä!¯QE´"ÕÈ¨FüÑˆ™7­œ¥!†¡#{9}lü×VÑÃĞIŠVı"~'«ômş{ ÿôœLq ¬{£Ì“4"¹ë'´ÇmaşvF€`:¨İï	•³šŒÿñZØQö|!)	zÛÓ'„b›ú˜qŞÚg‘¼L“Ø»d úÕ£Ë5£íá¬¹¯Ô‹¥wa|€ÎÊdq_Uy{»/MÓQ‹øØ«1€İ£ Ø?_¸1GÜvzYAÄ#úT#‘rö"(eñóV¦‹+nİD
C¼çú!ìï—ËBPc~ZHšwDd¾…Şng%ËÄ5ß²¦YNHü}zÓÖ%üçÖÃ¢µ\E®á‹l–!”šoƒZ4)¨å‰‹:ÏcÈé÷õ áÙ$z³$ìÛğH±îECÎDõ'¬ıyíDò½º/¾øÆX|IÄıvØêò­ªea6¹wll¹=Ô`P¢ÌŒoÁ¨^õKf©-ÓÎÜ`°¤5Oïî´â¾'EyÚ<4¹b<š€ƒ&:íÿkE ¯L­’ØEé£ªAÚwxĞ…;„ô>Ä;£;©µø’k=YEÓa°_ÀÊC3>Ø¸ÑÈ9&v»€1£îåD?Ï/z1¾ƒŒÉÍ	Céü5\¶ü›Ú©ğx™àÈÎ7q#4Ï‹øaúD•ºFÙ©ÀB]ÙZI¾eäŒĞwğ”öDÓÁ¯8İ•?’QV¿iÏn`$f¯1¯””R)uGâîÄA‚äğaB¦EMñÿİ5'_b?ÀÔ¥ ?™êh¤s‹š°½ı—0¢"@9_¬áulSvo%ebªI|Vtûò Ø˜¶Fğ²” ÎP8~·U ƒLÓŞYsdüåÿ·Ñ¨ëJÊ_°É‘€-™IhœéÏ*´¡™UÇ9C”úØÍ ZˆQ}w—vé(%—Ş»ÔóTOöŞ%LY´†Æ¬?¬¹ÆÂ9ÍzÖÓÇ(KË¡À"CŸ«§m7—½Ë? ‹ÒÛLÜ£JĞ6•L±O_×~î‰±+"ºXi¦Ww¹7)¯6›Ù8O¤&}£z¬pä)¨_ºâÔ¨PË+2şbå$ƒkK˜Dyÿ9\ÿÑGãnÁ©Ş¤6Öó‘?é›}Ê‡‡Ê®Ü
WÑIœÈ¼À	¹QÇ(¸½ª­‚xØyÙ^±ÌıÔâáHê—Ê“¦ÆŞ'2mjË_±aÛ„A:Ê¥…GPİß.’™”&ƒEÍ2½Ïq¿Ød–ZØÅ¢ñìØ!ı«‰9g\•+Ö'?:ĞF8)zh@¬isÔ`Õzé7yÇ#¬~ıwÌ2ÿQo]95Ä|l˜2V•Ô%»ÀH0^1/’µª¼O°ß
ÚeDMaœ9rûSGÛj±MŠÍôá¿[s†%‘T‹ÙÖ$`èú¥:Ì¥v6¦]}Ôü¯N§a£l~qUhËÅ*CQL­Ü]võ64~!z™ëz®±’Íèçé¥‡æYßóBèÓÉa´{Š!e¿ë ë¸ÚÒ9)LkğÿÙ¡~îF¾é¼‡ß6½+„R¶xl "S[š®ÀE}Ü¿²:‘–Ãí¨ê—¬;5>oë÷¼;8‹·¸_Dp+ø…ıR®¥²ÕáqÉ£ú<}Ì^Á¨³ †Ò!ßE2HÅUpñ…©iÄ™GM'î±VúIP$ËU/Š9u™ªâ\êRlŞçG;f¨5¨Ù—€³!nÈ¿CªÀbo†SÃÌJÈë·½¡DP qY¸ÎÌ>1“íİA7Úóã8É[Ô¦°ÈŸ¡P¹»Ä9«¦BıDD?k¾N:Ñhml{¸¦£m›³”±¸fú#ahÛºd ÄVˆuŠøÀX¬@£'6˜ç…7 ˆJãõSSM¤é“b%^ô|òü³‹Ôaš‘Q!a»‚@T·Öñ´ff¼G´*›¬a"—,Ü°Ì0‰&·¼PøĞ[òBŠeüØ×¯«‹XÔ -Î­ÁÄä´?KtÖ#Ÿ”é£Á&;/2.½'o“aç´‘ÉCš° œº¬É9–,{>"ŒRä›ÚÒKÉ¶[eôäÁL<ñ¡Ò†
11›ÙdŸğœCŒóN¥<¤à2~—ËÉ‚QI^Áº`Çñ_Ñ	‘7ø6ü›‰¯?«–ÀED
×‰À'Úl=sŸ³¨“ş‹s¦Ífì^æ‹³ô¬ÎvfÑ±L3ŒÇÆæğ×· pM,Ï9C2^“cv[Mt)›[B*56‹2«
d2gçÀÏïø!7ÈjçŠzÃ›)åsäHKu©g~İÏ“,,Œ|¤[z_Ñ1
ã•«ùÄ\Hdø?G(¤¶Œë5miÌ½$«àF;„¦“yBóK{Oµ À8b¾?±<Ø’púÚ~×&p&=F0R^â¤$û¤ù§Ø| ıÂh$Ø›qÊF‘¤=ÀÌ³V‚´ãª¦™9í„Ô]U`òó$İ¡AoZz÷ô}ôÓG±±I¡!1°,ıÄ®~<©Y¨Ò¡\üõ³•6K«ƒ–ì}·­òoıBpÂc)Ÿ8¿`˜O}HI‡F†-(z¶Åœy*')ôÄª‹Â5òióQØØgº„ıİ ›ï¡›óàtŠ˜–ßzØ“ÍÔù!%vpúçä>ÚÖ´©Ø ¼u3ëŠ_`Pñ7’öL{‹6Iátö@vcÚOÓkj”2SOÊ Õªš%l£Æ¬Mìãº…g§òkŠ› x•jÁ½V{@ Ê È»[€oëxÁ
mÓÄ`}.Uœ\uEÆÏvÿ `u0Î	Xë¢B4_Ôp©±Ã¸xú*À&(V?ÿ\RAÛ#hõæR“;U¸ƒ‰µğ? Çúö¢k~qÇ‹İÅy×Š…›­imÒğ„HÓ©Y-2·ïè¤9¶1''à¢µa=V]ì×˜S±$¥ŞÇÿš»á«ØcaÌá/5Ú¸ìóë(JÖÇQ/ŠMëJk.Ü¢ªI®Z2Ïöl©#YêY`Â²C†ğú-¯Û¬Âß‘/üuö®Y0‡8üÍÃ‹0nå,‰*Ç†m³åõvÿYc‹,ÙHg,6¸ñ±ÀAOÊì©ß§qÕLØ¶H€°¶ëÇ‰K»	=Ş×ºµµsı½›%8¼°ï;öŸ(|KLêú§[ú¶¯Æ¶¿¤“šúËJ2ƒ`1>+S}ì0†niØ¦¸ÕÒûB\÷Zÿ‹Ö#šçÙ¸%ÎpTá'<(£ë¢Å‡;­|â]|¦ŸÊ¿¥Š¹™¤R0'ËÚÙ_5\À-†à
øm¬mpšöÅ3ßu< ¬y¡Sí*À*U¹Şì$|ÃÌ“Ì2{I¯ô&£/K%qü"ò+;Æ·>;	s¤ª|+]µ× "gZP¼Œ?_¼ƒ0-eJäKæ„ÕQTüX³ô´¥ßm[4Ñu¼xV6X$ì:ÇÎA{	qÖqôÕœÀÈ+8uM¶zÚ{ŸûÑcËÈ´70ğÀ@Òê5•asÍôùpı²bà>R´Ğ‚(ÙkÒá¦è:à5¾Í6ÀÌ¹ÒånÎV³Ö«­b'»ı7{5_‘ÑÜm7|l<’•˜ç…‡ÍÎ%ä Û(l*S„˜Ãjá‡gÑûÉVK…€uÅ´w0†wA‚57“<£©còz¢Cv”Šè” –oApë^UrôsA~FGT=>}'·ƒıvF–Ê@äƒ¤.$È³2KEGíãø>8äıfÍxlkBH>°‡6)rçPŠï
¾iÅ5ó%5.î¨ÒÔ¹’˜,–F“iFS"E%Êˆ(‚½Z=»İùøÌÓ_c$3"Üÿ—ßê…Â9À»ÿ–V×¦),Ì¹ŸşÌA­¦¨¶fé66(Êq¬yZ«ö“äîf¹§¸±£ªşÜ "—µïNsµ{ _äDáió†
«¥|çiŸ:0iq; ‡ÀšİUdzj5Ÿ	vX¼Â1WßÎ1#3ÆÃ­Åtı!Ğ,Ç%^Ä	»&·ì@TäÎµÇO}ÖdKšÏõ`Û­=UÇA	¯şœ·â¯¢£5ÃŸÿ%÷#Cğ
Âê÷Q¨-Y3ı<Ò¡REü»z(Š"3‹ş~:yqäÄJ3)Mékü´Qk…íúÖÑLr¯5XĞ ’HkTøÀ³æJ…‚<™JÊtMI*4Ø€m+§FŠä$|Tv €H‘ç‹r_u Éù3êUJ·£5¬ó¼Àá!	xşGîuaKÂ”š«sÁşI}.i-O*èø'›—‹ş\}æŸÂ†œ¹­yäÆË±Nü+ÀşwD§ŒÆ!–Èˆ‘ÉzĞ}²§«œ¯vXI¥Ÿwr!ác4;¸{ ::¢)ÂB‘:8\è†a 9ùa
Ş€´ÓŠc8³¿&!¬îÑŸ¦ƒWWšQÖ6)¨d’2ÿ„Q‚1àÚs^k· -·Ğ¹ p¬aÑgü¶?p<¶l¨(éEÏII nÚØLs’ª¡G”‡·¬‡¸õ‘{ñàÓ‰l¾\şLÓÎºã¥‘·Ãór;Qù„$¶_wH¸7ĞBH/¹øˆßÕ”L×ôßçIH“¹>,¦·?Ağj¨~¿*g˜Ë	G_Ğ£Â$åv6¤áa>pSKo31×å(ë:mnË7I£|šD}ZCĞè’ÇİÁÆİ™x7™ô0:ƒZë>ÎÚšúÉ¸£ÙyWÇrÛ4•ğÉ~rp4şšç€—VÏ ~¸ƒ"ù)–ššó*'s¡æ9­È}=Ä1ú­ñÈø½ûúÕ6¦g¤½ÿcÁÿbq’­:rıœóÙn÷¶“Õá‡D ë) m_*¯˜¤q¢Å1
s®5ìïÚÖB‚wRÍ	{Ö…p<ÖÒdA<œyƒfíîÁ·ûEL©,j€Ï)–½3;xO‡¬£à0\öşµË+mó &0¢y†¼j®! ‡Z3oy‹R$[‘¢U†ØÂĞÈÔ
çvªêúİõø|=õo÷Có~û´““|FëÉàüîS¡×@5û‘ŸìT#Ó3û‚$Ëb±pº¶o—ÍcSeª6¬#øO Ğ“¹ä¬³è°?ˆàOŠ6× ‹Ù'7İõÌØùÂ{™‘mÍoÆvm9SMÌŞËbäo£B«jïuXj‚©L˜Ë<‰ˆª¨‹z€rñRÂØ%Ä;RõWë&ncM	p0Ì6™åH îÊ	oõ5î:œg½ ±ætL)g˜d­ÔˆÆîŸ8Kfwû[ítŒ-.şXf:£åú(¤e³ÿW…xdëõqâ¨õîËéŒÏßq"«1f»ÈÇYäKy–j±¤•öG&z­l¬#»«‰’^O…(jaº÷Š7äÔ(Ug"E/@Y«®é¿!TÏÒŞSÎî£&ù"kíÚ@d<x8Óöÿ+#õQcªmoÀÎçš:Õw[ N•‚ :wk³ÚúıŞ[Š†<€	›Z¥?AÆ’š3[›Q¶à¯•~9­‹ÈG+çŒ@Š›~X9¢æøÓVkUÈˆ¶› J”Õ]u°KL|Íwá–9ä»³E‹t…^ÊRœ1¾øz„_©vüuÏ½iü¬È]E`â€ëKË>ìB±•SÛ%¹L÷š!»K.×k€)‰Û¸â1Ñ	é’Âº €âÓ$=,j"r¤¹„ò?\°
5”‡zë$ôëç~¹8A¥çŞÓÇsx|“ô²\½®«%Y	AÔ¨À—’[kúÑN-¯D÷ŸËK]³Ò"f…Õı¿0\NÁóì¡)LwëønÕ=l7ôô@€2	¤ŒÕR"g|µvÂNx	°¤ C¨¡lGŠ,#qªÕÎÉûßôº"¼`:Ò¡v~{¶î¿_¹½5	m¶EÛImç°óTp„ƒU²¯—œ ØZ… |s¼GPCšp$Éúíûã7”NNe§Ò6‘Z/eY›6:v/ŠTiìÉ^¶Cïõä³à€¡¿Ã\iÃJpÓ 3>†áGé(ZÉxcìœù÷Xñcc›îÉ6@ ?EÀÈî8ÂWV»:<MÊífä¹#ÕqÍ§ë?/†eoæ5a–±1\oĞï™ Ş[—?Ü`T­š´Vø	9õJJ‹1‰ØQıË}káRß¶,ËWÙõİ-´ °¦ÙºäÒÀo±6·^Kåü'§¶TG"ˆ_ |YïëßÅTƒØ²¿c1Ã¯}>³EñêEëIFÖeLyıíåeQÄeîgÀÃ`ŸYƒo–'¦éjì‡À1uÙBÔë]<õ½Y|á°İÖDtˆ¦4b`…\ôCÒôÑ"´ì#ŒèE9¼¹ˆ§©ˆm±|ÎÅ'¢zLF1}ù¸:’Z7÷p Íök5©~©í+wn‰ÀãˆDîÙHêàÍˆ_«úßÿ5â°Y†H¸Ñ°t|ÿßà ”ËãîŞ÷0”lL™t£÷Z¼¬.K	åqë­*)Ü†Ë½Îx İ†ÊóeS1«|õa4> SÄKêt˜Ñ<KíCœzFÒ‰¯Ã_+lCùÜ•äI{“¤÷å–õ æWgµ,cºø_?
º'$ü–-˜ ˆuœ¼2=çmû xµ&ãK”UÖ	Ivi0(oÆŒgä±‹|Hÿº¿õu£d³}‡tÁÀB¼ÛİqÊm%å`¢š‘yïºtƒB‘˜N˜-Ùì^iÓ °økâ¹N_|²µë£›“ÅägDLV¼/òîCÔø8EÑö/Õ_Ü8gÁßgœËé\mtö'
ĞĞÈí!%5\ÚSŒV@ıô<£¦ôrã²ù©7¯*;Ñ+æ†…|÷ †	…RS™‰òÔ±ÔDÇòpB     ®72E«¯	 Ñ½€Àúéwş±Ägû    YZ