#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2440022435"
MD5="0eb2473520b41f6d8336257b561a1b73"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20450"
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
	echo Uncompressed size: 124 KB
	echo Compression: gzip
	echo Date of packaging: Sun Nov 24 18:37:12 -03 2019
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
	echo OLDUSIZE=124
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
	MS_Printf "About to extract 124 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 124; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (124 KB)" >&2
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
‹ øÚ]ì<ívÛ6²ù+>J©'qZŠ’c;­]v¯"ËÛÒ•ä$İ$G‡!™1Er	R¶ëõ¾Ëûc`!/vg ~€e;i“İ»7úa‰À`0Ì7@×õŸıÓ€ÏÓímün>İnÈßÉçAóÉöÎÎöÓ­FÚ›ÍÍdûÁøD,4BX¦ë^İwWÿÿÑO]wÌÅÅxaºæœÿ’ıßz²µ]ØÿÍæÖÒøºÿŸıSıFŸØ®>1Ù™RÕ>÷§ªTO]{If[¦EÉŒZ40?ÍĞ#‡Ç˜Gµœ…‰-4ØPªm/
İ%Ã©Mİ)%moáGĞ¥T_""Ïİ%ú“ú¥º#vI³¡7·õÍFóGh¡lØ~ˆP£3JTYÚUb3â›AH¼	¡wêµ_Áô¨NFg &Ğà “\¦ïÓ€Ì¼€¨8†ëf» JN©_„“
½ô= }¿óìôĞh$­ÁáĞPkÕ¤3>>Œ»'ÃQëèÈX!YĞ\o÷CMÛO‡qÿEçu§ÍÕ9uãQoÜyİeÍm˜eü¬5|n¨(W)
„£Ó! +ÕC
ÔÛ†^pUä;ls@{FŞö­Öµ¯×ŠkQÉ»=Ü9W©”“Ã`~‡Ñ5µÆºëÜó·9;ùø†(3[YÏâZnp	á
©a. ò­™z‹…çjìŒò­QPŒÂ7Ìİ	l‹2šFtáØe6®‰RIx¥‡_ÏC×§;^!«H°X²«º	ÛgtzN cö} ÄE–Gt1ÍQ8À)£A—¡(P*S3$:§ú<ğ"Ÿü•Ìê‹añoíg¢[t©»‘ãÄT×şD¾1H#ÙMXLeUìšJEPÇç>pÌ9ãÓºô¢$ ³ñùM@áçíZFmvxzæ¡n¨	-j-QË)*'(¦™µq«]ã—®§hõRğ°˜„eñ`‡0c6ü«'”7]YÆwŞA2Ÿ¦(s>ujïóe2œAš™&TVÕ°–ş&Ú¥šÎ6ˆÜ¼ÎQ|»YtfFN¸¡ H+ÛaŞ©ÙDÂ§–(eíqªT²Î×ş´vÖ¾çØ /ìPÌÏçvÈçôÏé%ê.É~wØ?jıjÔâäuëtô¼7è -ûM>>ÁURËY¶"{¹0ùe¨G»Kè¥’z½®îÔ´R¿J\EäNÑ	!hqı¸b¾ÒXJQG¸H®QR¥’IB"™šˆ•¸)–ÍMa%İVŞ»0m7¥TÁ'NV—¡</,¸O¥’ib,°j,Ğù>‰:5Qæ<Dß*Ì`2;£ å„+²R‘M ,€“Ëá[Q“6–<øúYÿƒmwN†‡Ôª‡—ágˆÿw¶¶Öæ››Oñÿ“§;¯ñÿ—ø<÷.Ğ&EŒælÒ®Ri’hs¡ÉÊ¯(•‘Gâø‘ı6Œ]L×‚ñ•|j)D¾1:À¿:NÀK¡¿*æÓÿ:*@8şŒÜ¿#ÿonnnô«Ùøªÿÿ™ùµJFÏ»CrĞ=êø†¨­wÜu1bû•´{'İÃÓAgŸL®òQŒô"²0¯¸À‹xQaÍ£°àê{2gÓ…LbŸ€,<ËÙ“@0Ãø¸	%ÇÂz¾,°šßûfÀDT'+Å‚ğÈ¯‘«Tå!q„O4MŒ¶¨c/lL&w®óœ2êÌˆÌ#$‘Yà-À€ k:12Ñ1í’³0ôÙ®®'Ãê¶§™¢‚’Õä¬æ­öVƒ|†ˆ•#Ë/}Óe<¢=3&0^E™ÙƒÍ™N#éPàL¼ÕÃ~à½éó:‹¦ä­~Ø}µÊ_Òşó’Ã¿Yı¿ÙÜşZÿÿ’û?ÅÂ«6‰lÇ¢A}Áø6{kÅÿo>ıêÿ¿Öÿ?±şßÔ7Ÿ¬«ÿıg ¹ aê¹¡	©áÈ ñmòï€Ì©Kv BÛ¿ˆG­Áñò)ÑI«5h?ßÙÒHËµÏ¶¾cWªé44!FÁøğ?±<2ó§qgZ&q=Òo¬7šX–[~ø{`›K›òb¥¹˜ØXğRx€tĞocİ¹¢ToŠ{h³p<µGi%Øf,¢u—†XfXÈOá€õ¼°úX=Dn‘æuõ1 ¦L,]z18ÀØ	/»îíñaG¶]’cˆ¡HóÇû¤Ìœ*)9ÍŒŒ'õF½‘Çs:8ÃB5‰ÈØÒ­Ï
‘D1NİæØ¤õĞœ3= Äã'ãÆ¸¡J˜ Ëø¨ûlÜoª±@wì	äPU	¬}p˜€!Dã¤Õ§³yå sÔi;†zëÄ/;ƒa·wbÄK¼YzM©f\G[ —¶îµ¤­[—½Ø€$Ë¸üagšæ  hs7ZYWZà¯rq ‰!(Í\yQ3¬ôx
ñÇÕáÜ•aÁ€\t)yûx“À›á‡‚FaPÀaÑ%O-|N˜½˜|ø§cO=>w…àÉä†ñ™Í¿ˆãİ¾øÕÁ/I¹„ßëØ+ğ	SÅkã%İ•0¿@ué¼î€Ù¹8³§gÈíÅ9¨Š&cÛˆ+åj-7H%QÕÕ³“rÌEjë¦ºß\÷[¢Ãõ‹"½RåozÀ=UÈwi…„Ÿ+«px‚„G(àdqºÑàôäIùGa±?ÇZ$+Úf½¡MÀ5¨)Øx®v½Òöí[íñMu|ƒı¹ÛL·º'§¯ÇÏ{Ç.ìÌ„è–Ç	óğåÉ¨uxÃcÉŒ7uy¯ê õùojÉêRA,>•ËëÕ…Ş”`Ã£X®KñA¨DTÅAO	ëVšò$g¡¶º$4öñ>á•õ£ š‹È‹ ¡˜ğpEy†MmŒsZÁBœò™îœfçö+»EJ %ë®T°¶A¦`áÑûŠœËÉüGR[&íşéxÔvF†	°×ªf!. ±s¤’Ş0íizÃ¡ lû õòi‹híÙËƒşË'*I„¯?èt_¸3Á…*_nÌ ®Ê$nIU¤’İIÄ±w:hwG%/r`Í½Vl4~ƒ¿Ù~Âµß²’î½ïO/w¸,;Oç¶F.^ƒ`Ó÷nLÀE:Aà»ä Ğ2iÿ5Y}j×'½ÁqëèF%ÂjÙpÅV©d‰%‚¯¦Ç¦µRíW1´@§©ıv¹œ­…ª$ëËØ¿
$ŸÙW@^ÖÁåÌjõ@: lá:HT°ËºĞ
¦g;[¥úpCV²İÒnßCL>‰äçµãùÁŠ´—Qw›@­½Ÿqy*š”$ãÑcf‚¥db…›r'3>·MøX.U?nûä;¶‘#9ÙsAórë^4Ç·ş°Mä!ÙDTµ[Ø†™Ã4¶xæyá0LŸ+[rá…{©Äím©MºêrpÔ:ôĞh¶Nö½îş8–£Â§0âIÈš›-Q}‰ÔğÄÙ%Ô$.·
99Ï+f„¤ôå¼-‰)¬Ê—Gb%võ³l\©)ŠIßœ›s*<î~ç uz4‚o”Úö‹$a·]‹^òK/IHj×0|Sã}ïn>z­¹€2áğ×*û¿}ı—_3bâ&Ó¨eƒ+ûÃÊÀ·×·vVëÿÛğëkı÷ÿoıw¥_ÍtæXÿ%ép->o,‘ø{Öƒ”ùËì‰Cym—#ÄƒŞÜÅF]<&^'.+áuµzıËp»¤XÀÀğÛ¡gÎaMC©Æ•,“ßµ¤Kêx>?hÿFÁ!ƒ^o4ÆşÌ	~ƒx-q	Ãırp±8ÌDós Ü'ğÑép~?/=Š¨¥ÄC™W˜Ö¦Şš\¥Ô÷î²÷(góŒ$„Srûü¸’<D%?óİót‡Ô5AlZûÏBïÔ¢KÎMBüÀvÃy8<}6üu8ê†±‰ú=iFƒkÛzI]Ën ù§—“ıŞàgè;îíwµ±³³‡ƒŞißP}'š^õ­û¿BÈF©(ÆGxÇ9ˆPü,}»©Å”ÖyÒÀh°Äk¸H^Æâi1«r¡XÚ4ƒ¿DöÒCNÅüÃ?äºç=c’• ä¶¨¤*‹Ÿ\‘3Ş|õh+G}3<3Ö,5/U¹œT„.‰E±‡<€•Ï€lQ5NWcØú1hšñiR«İX;‰5B•Û A€Z4¥)Jòç)âéµ•ü€Øo×#ãİ¤æÄÖâî§–*­îZçºï˜!˜«Óch­:™,^ÇmÒ cÂÍü¶œ:óxCÜ¸_Àz¹0ä;z9Q[õu? h„B]t‹*C\«TjQ~kàÏRy=Äxˆåœ†?z„şøÆ¡óPì(]÷@-üŞP”¬^EÛBRÍÂâ`D’a*ÆuãÈv©íâEæLÎ$!zÓxÇ­D¼ğ”+îFIÏ@jrf}Íìˆ‚LMp±BsAqaÃğÜ5¾73=¶ÄÁC’×Bâ7®¦$ô©D•¨S	I‹õqµºeY `}Ğ9zıÀCçÇMˆX€/ZâcÃ¢åÆ $˜*òb“¨ÅÌhñ€T‰>ãaRåµ]ü»[;´ö:9ˆÜCàW×›BLò—ˆ>sL÷w"yg@"%@½ÿA<àE$`¨¬î¶Z“Y JÏéRâwY
Kç»-íu®W¼ºBŠy~ò¶Jì‘N£&?û™µûG#qÓYË‘Ü£lwdBĞ h©Ayø‰‹û}+näKäŒ\FS)laB^]è€å˜	ºæ@ØjâË@#è!]î8ÅsìI¡˜0ŠqÿŸ¹‹À€|ƒ3zÅÅ(Õ^–æ½™ôG,2Û# ªàš–ŞÔ‹HşR#y4|+3Š¨dö.\´'ôÄÑ¨ç:Wñõm1$ÒW-T beÅ wsáÆOT§Æ¢<…ìB#"¬©ÄcÇü-vÏ‚°äÂşÍbo'VÛİnN‡ø’Ç³£0ÆI!e-éT1Îœ5“¦)Õı²ŞTÏË:ãµ¬éåDŠÊ°z'
ƒ!<çåğôÇhq…nB^‚'$"ITw7ğ½$€‚<åÑ#ÛhìÙ?Õ®«sŞ<~w³g÷İ0ıÄ¡Aè%ƒÙïnä ‹7JB¸›ı$Ú`ul\q±§XÖºìoäÎ¹D¦ï(¼1yó®h”\ú›ØYräöÑ¥ªD¹ƒ7%¶bR®2@iÈ©‡â’ĞËôt!=È+kå§'j×y»¸§ª(×b´[,İ¦ıäÂÎ™oNiÌÜW½Á‹!„Ã.®Çp´²¹bÖ¹˜1é?É÷ƒ9{ë‚—whÎrqœ½£ı±”µµBƒ˜ød”­Xzà1Æ´?ÿÌA0ôõzGÃj¥‰ìKg¤Òï”/ƒÔ¤My(l„´1²ÑÈ!ŠÅd<<í÷{ƒ‘q‹(©b'¹ljhwkğk:0"|…"¤!S±0Ÿ{÷ÄJ_¬‹%LMï*œôFİƒ_ÇC7Å‚o
WŠ>BÄŞº·È—èÌ„‹ì’2ñzë®—­¬ïrsöwïæEjÃãŒø÷,'g/ÅUóè_±¸·.ùl6 :&Ù²0›\P7"5csèñwò¡­Xr¹Å•è¦ï;é{iXò|AA®÷ûC9ˆRÎhğ=¾ìB”Y¾”sß‰…Sº'Å{Au_ÔXiİåŞ£Å¼9»mQvz>°3şf_4“¾<òNä.ê‰¹ F¶%jjêíi±‹ğÕÎ%æŞ@Eî¦i Á3¸ÒDF¥ñÄ¤ÜÇóÉ3TY”Ãk0¸Œ-'%¨;E—•‡ƒ‰`õº]ŒGQAÄÆ^€]ù¸¶k:ÆÌMW>5ZÙ¾Ålhƒ¤Ìyì`HuÀ=˜moBÎ!ä‡£{‡§]àµ=.î	»kŠüWÇmÇd¬ÈîcØNNVH/CıRw÷øS¼0`¬÷dXÿD¡¼Ïv±Ò!ÈÊ`s¾% ¥ˆ„H•6byã<ß3õ,
“:æ•Xåz¶Æb†¨-ïõÅ:C¥ñ#8¬=Á½<“Ş@¶ìC¦yµ»ûZ{±ßÑN`)KÚ¹)ïæ]¶ÿ=1äã/M'¢F˜Æ_kân­†oùµÚ¾‡¯I‰NœãÛJ¶Şm;'§ãî¨sœ$ü¥:…yî„ìä»KR6ºıÒ˜}âñ~gøbÔëóótÒáMmSTï:Kß‹:£_Ÿ»Ş‚ò»¥¦r­³+Ò…Æ´yd[µgâ¡…À*Ø¥ä…A_?NMJ[¦NÂf§›‹ê—ç£,Qœ-ñÙá—‰åGBî"³9ıö7™¼ãŞ†×/!g©;èty¢”Æ~ßHT€Q–5yˆ>À¢%J¦´}…âÄ^ŠÒ=Ççİ­¡Şí’ÕQ4”©?ËŸ
ÁäÚ>¢Z%Gö2ËR€²€¨Ü«åaVILX	²„aïÍ¥™D®Ìx”]‹}¿\èØ©Õ®{ıÎÉ/ıÆÅó„ûŞ:×Ì…1)ù¸Aö“vÔÜüÜA©jÒšÅioşrÀ*ô€>Né„ÁL÷Œü—,IÆ›n(Pòä ­ŠT²öëäç·:üz˜“4•ØXÄÚƒ¯Ÿp`)ä§dcƒTÉ‘ùá(q€äÿO% ÙÜ¹¶v§¾Áf«.D€	hÉùœ¸â-Aş];?D™Dğ‚ï?¢IÈ	½èg%Œ9–IGŞ«TcÖf|ğ ÿÿ…zÌŒ;‹(IÉ?2MB+ö9\Z
¸Á¼/åÔÇÆ'ØŸWa†yV€	Ÿ/ª%B u‰ÛXÉKûâüÀêò‚ÀµµÀ¼-íğ
Ã‘F³™‡piîK8¤¡±'Òa|HÅÁ³Ôqå$» d¿²s¾|ê$š'ùª±-­fˆ¬NÜûïÜ)îª‹.¹8=|øÑÕd¨ºRÆÿ(¡~¦ÂûPº7€Ç#êš+ÇµBgJ-\<üÎĞ™¼Åw•×fİhë ‡`-s*©–G?kãp¢–°F•|¹Aî’p.pZ7"±jÜñ¨ÉuòUÂ$ó&^¹{)k‘ewd•ÊjRŠQW7
úuy%şCÔæÔ0>[ù§Z(ŸÍ‚&Üú›^gÑäÛû¶æ6,ÍyeıŠTc’Z @êÒ¢ J„d¶y€´»Ût Š@‘*·­(Ñ²öïLìÃ¾ÌÄ>Ì>¶ÿØKfVfU Ò´ÚİCDHò~9™yòä9ßQpø_Í“	¶Y^›Ñ@Têîôë‚?%•j8FÉ6ğ8¿ü¿Áè	íjŞæ³µ~1#¢ÔòırÇ”L8ø†—-é—ÿ-®‚Ÿ¢€ŞÉSBp¬Õrp¶ZĞ£RĞzˆ™.$ÿ54Z¥Ñ”¥ KJ'8ÈâC4}'`”ıT©¹â
ÅVŞAaÑµşŒ2¡ö·„$õÒİg¸Š¡€£öÉRù/£©b+•ËÁøöÔ˜©B·W6æ´½/JT°ïå¯:'Ï©~àvƒioV?á°ğ'æÂ¯å3Õú~aŸ\9ÓQÙ™—ÕÕJe6BãkT¤µºn¯•¹€HåÚ(¡¹¥ç­èn¬ÖÎ¾ÇªÏ~¨õWs‰åÄ†8sjÍù×øºy$•V_³ê¬(›QPU‡
½ˆÒÕ1aN(§TMÔñˆB]¾Ç‹éO-2İŒTÆÍêfµ.Ï	8Àw£5é;È¶HÙHæ#Íd©¬*ñE>‘Å7¦…ÍÃM5Frïg“^w:œ¨Aò!]c|ş#ìÕpZô†}ş2Hğï 3b	şà`’ÄßWIo\ö/ø{?º¸HÍ&ò;^/Ñ¨‡_açÆWı~ƒå.ôÂOÿUƒQÂïıüÿq(£§7Ğiæg5N~ä Ô—ßĞ¤Íøš¦ÑÅÁÒJ¦ÆW¤?æª'ï¹„¸'[Æ	.'X0—ÕÉ” *‡üçİ«^Ğ÷PuûöQı`YtíM¹?&ã‘LA8,ïÃñUV:|<ÙŠhdà+Ê×ø+üú}ú
*‡BY YùíGbBè›ŠœMõYüdâ=ëÃf¿Múá„şÎú³¡üFTÂ_†¿Á@Àe»?™'ò*ö:èaã!RJœàê¾J¿É¤Ó‰1b0¤x´iáğ"=_e–tà?„çQ@ƒHfŒÖÂ³h<·ôR·ég«Ä¤Y#©£/}AÊ_‘Ñ,l:Si1²Ø—ÏKõ3˜QÛ¿K[â!îşÅ:Ù¼¦Še]”sµ¶@1âLİÎluÜ¢‹J¥³ˆ*ØÚ­ê»¤+Ye«Z?£Y€¿pwäCüoÖzYşÊM*XzæjjÌ+äsV¥W¢O}ÅMà£NzÍé	Êè
Îå"3ÀNÃ¾y<ëë4ArèöIqó)};%œö¼¾›aÄ8Â-®ÀL›wë fk7R%¿ŠÛ(®274:U¶1®·œ‚J±’HF¹Å-¿§ImX¬–¬äÅğµ´)U)ˆ6Ê]FŸ»ó[ƒ‰úMvÛjY'MÍ!)ª)dF,Ïñåé¼PÆ/r¤ÆÇb 9y_,›^.¸xØO¦IÓîÑOo}pbÍ+¨,³™Ü¥¼ÈLDNù¬©TÄ¬ÿ½Ÿ*IÁæ§	4'@„†&DŒÄãˆèÈğ}6Ş ~Ğåm¢9ïZ!a——¥úÜùâ36øF%+–|ÏT…Bıèî8.åÍÇ’Òir>õYÛËtÃH-¦ xşÖ³tz¹!ıîÊ/¤¥tÎï¬cò]°Ï8';éíææ[ÉË‹4LçFæ®%R~åyµäAzË	F“äÉV8°‹¹Ùb…%,dì©Ì¨Kæ°ûÌ‡†‹ìc …'(NL;<\$÷"—˜ÚAÅÎ+f…	JGs¬ÎÔÎ×iœì¾í§ô¼œ‰õmì‚–°âÉØÏ1éqìÆycÏÔ"%¨œ.Ô¦®ìŞJ>Õ³ål„øY wï'µ³Z9S«]âı·4HòY·İ%’áş6´÷FfGn«#‡ÑQŞæÈ69²,”ÁÑ|{£»17ÊZÁï™¼ï£ó¹æ¯.²º]N¶ºe^i+äıFöQÚì(3†Nª9S®+Ø¯œ)hËü¹š×ig{wú <ËB,ıºnª¤ÜØTìv–b±;·[Ş@ŒÖ†f¦z“›—/í’ª™·W§ŸRÑÎ0NÊ"Áír9K¹Uƒş²u¿tû~Ì¬üÚ,(İnû§üIùÙ”Ø‡ç¶Ù1+Ğ‰Â…)¾ı¹£n¬±5hß·£!JòÂHàgHo@^#îe9’ó1=[O¤:VÙ/'aCÓœÚŠ«XC£„Õ&X+c 2¾Ùº‚«³€û¼w-×ÉK¾é­uøms
ŞJÉ¶ÙSy“HÔT*q¡õ¹eBºÈı]oï´ÿ’¬®çå4«)‘W«A_?n®õşZùáúj&‚¼ù ŠŠYµööÁ œ$7*p™,pI0³Ø†‡ù|éø­^Dhãº²Ê?,˜ê[z‹¡Dı1çXQğ¸ŸtBºfD²xB"/è¯«ß+®±Á:éÒ©_ÛÛª"*‰÷E¥É‘v—FßTvdÒ—²*B}ù·>¯:u†
V¡<Æ¬Ufª<gÄÍuŒ€?°<.§+«´õÃÑ•Å¶¯¾ø#j+5¿^İğáĞ÷a“iú§'o*Ïü?¾¤^¾à…È?V^´FWQ<¡
şŸ$çï‹}®-Å«cñ3¿ön<ksS“ÊiJük~…„/}Y–!Òğ‚a¨Ë*Ú³ÒÌ/j6RÔ‹šì‹©é–#¹5:U¼Â´à1Ì¢ç%”‹—Ó-¶‰&ßÕ:Ò”ÏM¬ŸµP²I&(®Ïªå5eYØÁçºÎ	ã|ÆmŸ t×	ğ6ù™,ØÁ³òÌË·a¼î¯¬*g¥TŸ_€¥¦à«š!_£0_Æ%­_è6‹(84¨	i[7m?ÖÇÂJÙv™STˆqÎ§r¹ZHôgØNz]<cZ_5à83hœê¥8©¯¡Oq ;‹gÉÄ[”•$Ü¤i· ¥Cæ/ù=Á.¶NÅ.üñâV0‚è¯r"Òßjä¿ƒ‘ßüMFYÙªÓåì—ôÿWol=ŞÌùÿº÷ÿ}ÿ¶ÿí*ÅÛ¨Ömü7ú›åækÄ0Ó,¶Û±ÇnÀF"ü(sÁ¥!`µ‘«+¸óBvá¥İ{ğòA¹,­ YÍ—ÁxóJo÷^íì‹owÚ{hÔŞáj_ãM>•—êo[íİV³¼z~_ßŞlWµËğƒvkÿˆ£6 n3ëœ¾‚ƒøë]ŒŞÒÁ‡­·í½™¥&W@²ºG\×*“’mY	wşzº¯ØJÃiV6‚½ä0xuÜÉY¿"¸¶$ıìº¹Ú{`ƒD./ÓCê¶«^©×'zÄˆŒ,•ËGÒñ5öğYÌáÈİoØ{„ÏÁ}1D€ÀhDAˆ(¼"tj»MŞFlsK× b-|¾`_ÖÚãK`»¯Ÿù¢?ÃNû/¾zÑÈtKĞ9”+ÚòÃ5ºÑ?¼˜<¨­)" €õV®c·IÄˆæ+Ğàq`3S¢r*Kä•‘¦³xç­4 ¿ÏF}1E]`ıôríÀá!ÚçÁÍÕÃ£ÃÖªcÌì!óË|=ÛE8ì…³“«	f•æ„ŒåÈ·=ThÇŞê‚iø `=up®È¾’•ü|ÓÏ+<qÀKA|™JWõ›F’<†ì8ú=ª”ˆ¶ì±„­v¹æZy­ƒ§:òµeœ ²ö/¸¾î%2Š5Ñœ¨…
¥o‚<AsmİE€_}•D0ŠÊbÚÓ­%OêÚ‹
UîsVü´®´ü	¾Öjgµšø¼nBĞËx'†ˆË¬°G™•ómò¡{,¹ÀïƒÊO;•¿nTş°ıÃºpã¹0-ÌÃeøQƒ	¬ÁÙíöy6³­J; ZWÜ>B Tí$$,Ìİ<h¤Õ$iR‘öKçxïä¤µÛİi·wş‚¥Ê™¡l4Qéäd7óJVÎ’œ©’ÎIZG³œ&úTØVSgyæÂdR×HšX@‚8®‘H%r/Ö	ÒŸÆB§äÎ/è”16åô;w#-Élš9#uúÄPÊ,,j)îeïôáŸ R½&¥¯bœ!º	núç×h’GK(•¥@Xš¥XX›éìIs$¬«Y®oëßzÃŠJCù´Âuß,oêPÙ3S¹hÁZ¶U*©ãÂ#t¤¬„KÖˆx	l[)Ç¼ó0QÈl0Cfµ×ë@8h×Gô‘IW÷8D\G{&åÕ^ĞOÒìÅ³çBŞ°èÜzÃ`;$'h~%ÓÜ 0=†1ÌÜ{ä¤z©xÆ€kÇ¹i˜ğO²µÍÉáç
x«³%¦cj}Hzåò#‘ÁÖOlşõÜ—Û
@rÔ—(2”-°}*ÍË”Ëek´ÃĞš’©ßKçÏF·ê¾+Ûâ(ñc$’iF\Hî¨´ÒE]J êàãµ0è‡8#•Íd”0ëúÍÈ2}&ıu3£õŒ„kèÎœâ…nFkj«Í²¢*‘‹#µ^{Ígâ»£·ƒÒÛ¯'|èn&›–±Š¥øß•,µèfF¯ÆX%§0Xíñxª§İGiã`­·„Jà8÷¬º —óN¼«Ë>!bâíl6 ¾I83Š¦1&=È›Õº"’½}Ÿ\Ä³Ş¢ÇqàŒ£+˜òË09µàºë»Z­"	½üªÃ…ÿÓ‰v¡¾”CŒÉÉÜÉ´b¶×ÜÁ/Ã©±:ê9uDr˜
Îó°ŸëÂ>Å³.Xø‰á$Ujæ=Q©ÀÄ…x¾on †ÆŠ²NzE.¤\I=ËÈvNĞª¬Â)Ç~úyÌÓõq_D¯ˆø{+“ î¯fÉufÇØÈIštÎÀl[JÙx'£Ç]©?_ş„!¸Ox+l‰K¿7~P†	İR?¼ÃY½@!#É”‰Æ‹¯êR/”G	Ù…{œ¾¢)9(×YUeëªÛĞ#Ÿaš˜óÆ#M
g,±8LRïóRÑ2‘¤²V¹R¼ã•Ù(˜aÉSTØûëÙÄ] dÈP¹ˆ>V†z<ºÄ—Uˆ® Å(‹„òC+™‡ÇXî9ägÃ$ó…¹ŸØ .pÅÉß5ş3û‘Ã|÷¾¿—ñÿ²ÙÈúÿŞ|Ü¸÷ÿ}ïÿûnıKónIåK:zy­|}[®¼eAÚáKßp–b¨|!ÏŞ¥I¢‚ª˜MĞÌ5$p6‰d$;rc¿e‚®šÜÖ»¨&ÒtcÚ¦v‹i>z—Œ{¬•à{Åáæê²eâ;7œq4è©Ö"ÔéI–®²*ñ…‚
ÉÜ40Ú2<°ã¾k¿¬Òxä:Wşä(N‚Še;›–c‹£>˜I¸æÕw%?„rØıcw$ıúñ»²5|ˆha—¥Ç-­*goiÖGíwXdæJÉ‚Då
q HI§,Àt$´üëÈZã—†	ÿ¶×zn	¦b‰J)*]Me y¦Ãè¡Ë'ªıô G¼À}ªå
[“¯i¡„#Í–½Er21’eqLR “L"›ŞÜUï,¬ÓÌ¯T¦ÈËv€ù~°3¦³„ùZ²M7¶›Î·©ªªÚáÿ“Ó½ i¹%]öEš!^O£ºoO÷xÅË%&İV7Ë’¡È*§ÄH†x‡âağSg	fûË¿ÿòa•&ãó¯á(¯¤fU“ 7†.IB*J OJÍ5Q^ëOŞ_Š
pÖõu±nîöRhÏ>—şM±ÕHâÄh>¼"Ã¨£!RA‹æTe’/=
FzÔÕ’¯\A‘x¦iDˆ˜€(i #–ò¨ßJê³b¡Å«Â”[©q+ÅP¿f€DÔS %Æ9~ı.ì½o‘øêƒ£‰æ™ˆæ%1@éÄ»ñQ	« ïìŸ´Ú‡;'{ß¶´o,½ã0ñ?WC½*rk…'C‘6ët«YX¥EÿF7ñ	;‡ªH³	–lr: 5ÅK[ÉåKOÅã„Ä¥FC3›Õê†=bÁh¶Z»İÓcÜáZx:5ë©#èè£ØÏ£ ú¾Q;š„£?í~#dg÷^†>3‡`N«…‚\}VÿÓé¤3÷y»êÏ¬hEÉ¬¾b8Ê/Ÿî{UsŸ)—„[ö‰YB>§¨×hÏ½J¯w7.¶YVû'5Fl…xÊÌ¦ò	G§'™,A¿kŒ§TÃ }¹úÄòjoç°û
 Õ:¨Vè
2ª¶Î
ª}ä%+ç°§b8Ğ¾«6ß-0rANˆåØÜtÊB÷ê·‘0¤"†Œä³%VGéòc`.°áòqzQ»
3axÔy^íÓê@àí.íö1ß¡†wiYİ‡Êƒñlñé€p²6az*!gOG:œŠÑñÀEóhzôaŸL‚HôÉ¥Ò/ÿŒádè·ƒrÍå#·2"šáğsFhéİÁ4Éâ¥JJx;•Êd_†zíş¡òN=±8a½şG¹Û$áôOíÖ3Aç‹`6˜zCñ,Hv9ä„ô¤Lßuq–ğı—Ïí}sÿŠÃu- $}4šoS)l3æº4‚VÎáëC'pš¢ÌlŸÔ/ù¡b	é…øP©/µC4;ù!"¹Ñ“ÅG—ÔöH­ƒÃ²Y0ùÙ¨3O&¸Jí%ØKÅŸ´+Vªƒğø§owØèÈ/§Étí² ‰‚B¾X‰,¹G25±¬K1”‹¶¶ŞĞ-‘ş‘¼’b©úá$ñäİÑP’dœ"±³¥épÒ\­Áÿ¸¬ñâH'mgÕËìeÛúĞ&IÀşÎw[’ÎŠrÜÌ9k†ú¡…^Ìª$Á¸\{‘p=ÇV¯²7cº2X)R i½açgU–f+IæfC2;E“-İ–Ï‡ôÃçZšJİ˜äåÜTIS ºNó-’ìĞxÍE™dµ²©ƒ–ï‡¶º¾“dĞ	üšaöô†™e 2»e–CğĞHX?G ´Vî°@:{ìÉÉÅsy.²4ê(ïï½ê¨{¡Ç¾e;Ø”s`ããşZàŸV‘-ays¯Ø¨bŒèôÃp²ş:æŸÀ±fm6­ç\K¬‚N*ºk¿mË}é´Óê(.+,*«@ú—ËuLŠé‹
FÙ,§íı¦Öm</³¯Yµ™fŠ=Ù¥ñ>ªT#Uu3ÔÈû{¯[‡VF·½sĞ‚Ë^+•AÔG	m£q—ü}8ŒB©İ<Ò±ÊaÓ¥k=Ø9ÜyÛjw_ìë¼ M¸âhúñu±E}¹«’pÎŞÜ¢’¦ÖØS®î÷*ëxVæàL[	—VÍ±[Mm®$b(Ó{3E{¶£G<s˜oÃ©)ÈDY‘6—áE—Û33Î33Î:ò’ê‚"\	½‡û*”¡™]ÚÍ
.%Â(Åm§İÚoítZµ*Á¨£r€P;µº—î
ŠŸãÊ¹£gzk´S< tDy-Hgw7MDP0ªZ š5úó³ãçÛ%úóÆqn©w1šÈ#ò“Iè(ß¾´©\àÀÇÑj¿!ğÒB`‰ÂpÜG(5Âg,`0•;¼6Ô¦¦ç']«[Qj‰bãÕ3±LeĞÂ¥j¬3Iä ×rçØivøMìD°'Û‹  ·»dªì<Ä#1…j$QM¤”©CÏœÊRO¾È;Z‡¥·­~‘|ƒº’¡!†7Êw“qm¸ŒĞñ
D4×üŞ xK_9‹}Aşy¼f©Í<U	·º£ÁX7Ò–†eá/ ‹œ ¼¼Åç,ŸÕÏñE,–ô*¼tjjŸéCµ¯À‡¦·$ïÙq\®æMfƒÎóXX~ù“74j²”·<Ùóy¼YÌ¿ƒ”áéÓ§¢Ò¾*#ó¡nÑX8—Ñ¢LÊÂØ9TÅ«ôvºI«ä=õ.T
MOâèÒ~æÏ<Se/õ7•ËÑ(•ğ½3lšÁ·^'tETÖÒãQ/ns+­.]kµ°Z«V½f¬Úèš7šÒaC=wŒÍÃ&	‡B>Î¡Ò,”0
Æ¨,›Ì¡eğ,óácÎá½Â×ÕÌGäƒ·{È“ìw÷w[nnˆ’@Õ0Æ+©ã#\¯¥Ûú‚şòŸè$U{cÜDÔ41ò&¨¯…Àû$‹<°';mÉ¢çª®“ñğ~¯.ds15šú™ıSX±6gEÌ&»só
Æ6d˜éIlŞ 5D©CŠŸ¬½Ô¨jÛ”^kûÑà]ÀÎé`Ú£ËQ0hˆ5ø÷è0g“éºCÙ¤¿îK¾!×¼¦ÏF?E+±s3ñ™qtåæ¡<Üıf9ŠÎŒÔjû·a-ó(/Ä²:Ô\Ã¸ı~V(¤Tµ¹¤x²¹3(7ˆröÄI!¡ç[ËkÆ•ı©;{J˜&Q%«ˆÎŞÛ½ÃØmX”Šë<—¸ÊGõòw‰åìîÁò=„Ò„Õy}úÉº²Cg´AAK´ÅÕymçÅL¦xHr'¸3ËÍVù¤0&ÓQ45VøœÕ¿ÌAX¢›¤ š×•-ö¯…›µ|‰"Ù‘2†Ï9¬÷ãÆãj£úØw%Ò"5tYÛT/ÇãËAXîK¡lÖ€ŠÇ	‚Å]ó‰Ô•å1_æÜY2Ó/Î@´›cLÊ¦b¤Eñ®Ÿ›¿-MÒV‡]I§ôkuAîMÙ°”1¶)H$ÉÁ½ëçÏöó9_J—º<÷V®áÚü³¨"ˆôu#5œ#L+~‡¿yI…¯ÇwÁÚÊŒs„‡YÜj®üxâ-áCMé›¾–ù²[ÅE6#õ‹¬‡ª¸L2êf=/ÙrSt†ÂÆÂLÕ»–%Š^å™%¼EÍéC£ëÿVıÆK¿Vã†ÙÍÚ7¿Ç¿Ç¾šV,¼ıt{7DĞö®l|¿“j‰o®q`±<ãÛÖ‰_˜ğñ“|<9—åÈšxuº·/QT?ÂÆ™Ôx‹—ºPÛu}±×øùîÌ¥Nƒa#=Ua¥‹ñûpÚåÇt¿d†`ò¾KĞ*¨iµ`´$‹y°whXöØucÑ¢Å.ÜŞõfcë\
çÆz^ŒI=Şè¥â•ymá¤HæutÙ-¶á45å¶¼eX45ü4¯ÚVµ>öJ‰ñàñÛÊ É\fËŸœË†´$V/syš“!et›¯}@À.ªÆ'¶£×ºÊ,h†*baçæ§àW(yjÎİ¢~7Mœ×ÆÛm¤ÖVª6Sı÷"ZQ*Â·ÃIÅ°Áfx¦üK"AŞ\õ~ê›¿ŒmÒXë>cóâ~ÁJgVë!¦ª‰RÇPìŒG„ã½Õ0Ú„¦òJ,ìcÇ¹¬£Ñàš¬r¤VæI8äˆCeÉCY2*¹æ8é†t#¨»&ÿ&ôÀXUŸ3ËŠ‹’n9ô~–-$cº@÷ÌlËqSö,üıv&æÃÈx6}~•va7æ+p–½¢‰ÓN¿ß§Å<å×oŒÚ) b_ĞC˜uq\Z´a]1Ìw¬ìä%‚\c¦k†ınLQ$|#l¨>Òë$ˆÑÌŞeÁ u•–öeU$¿ü§2da’ê_/ ñâ˜ È*)ó´À j´å!e=CqJl¢M}Ô{‡¿×EÉ4ö',_V|”x[¡W,Uƒ?ÓåYjµÈª|‘CìÊmxy}7å˜€=`³X_r+Y3£:©H0«Æ´²œ“£Å6]â¨z®#ö]©ûÛÇ9)
‘¹÷„ f.D?’ÄT½¥œ³¡PM*Lkãã=èØİË¹,¶¹b¥ë’bãIˆ€@®2bAxëK ­ñˆ	¡Ê?:Ê„ÒÜ%AÂêªÕT«D…†Şƒ`çK•Qş£áuİ1¥L•vR›ªÁZ6d[³<âŞ/ÿ™ï-ü1¼÷µƒ)¬)³ç¬Q…@p€]!ø	6¼Ã“"Ï´eè|«4‰‡$ènv7º3µ´«Kæ%hNÚæ„ÚÏÍÚ²•iË³¥î§ºv£ú¹˜ÕfÎ¨v^¶"¶ş(—öª²}['°°ÌutŠ[˜ß‘èüÊ©‡¸l	õ6J=ò7É6Ÿš“ÈŒïg5Àşâ¬ÎˆÏ¬4+W$1!ÊôÊ™^/9Ãİ™ĞÔ«’Ì¤;‰Ó3Müm¡ÖtFy¥`tymw:FšìI‚ÿŠİo®¬¼Böš"v”2ğ)ò]V'º2{»¤3RäôDéßîì¾šOûá•GMCœÅıñ¥T’M5‰>ŒÂXt¥A\Z†g³rx<´©`‘G7±ˆ‘´ıµ­Øƒ˜ëªß˜í2ÒÊP™Tæhf/4T_@èËƒÎ{ÿôœ r/ødk}å÷Àf˜2lgÚŠùÍàÜ_‚•Ì2[§7(Ï‰İ-we©b©Uâ;TÍCÉİ³‚‰5šn²·mw±YÎóöïÒÂ\Jé –’zsY '†Ä†áDÔ›P˜İ“¬­y™ª%9š¹¸îàÄù-NÛ×œìqq¿¡ŠlI>ğ5ıœ^
ˆËÁ¦º+bÅG½Ô8_>ö(,ÊãxİÀ`YU	i}›Å-Øğ«KV"¹ì¦`|4Bêâcù¦*`eœAßL]¡KtF˜Må2÷÷^ïtw^Ÿ@İƒ£İ\ÁKìÑA"àxæËµ<RsÀ›n#êz%®a)—7õR» ÆyC(JãóvbÑpÜöcÜŸÇˆ@Câ0#«}b%$§DväöµVÊËmD#‹Âm½¬ÍäËŸv!êHB?xÎÓ’ôõÑşƒ9'/{NæNBVØ£¿¬d"ƒ,µ
;DÙ^©ÀÙs1¥ŒÄĞ%}%B(#ˆ£ éÉ± *Ô#?ÆE˜‡—ûHslÔY•n(ªhg^°qïô±óŸLÇÇR”:ç Ës^Á©æ<@sÇÊ<Õ½t“ékéš/wÊ¸Î˜N ¾ßÿ¯J0Y(k„¿‰ÿŸ§àÿá÷­œÿŸú=şß=şßMñÿŠüıôœ(~LîSâ'OÈ%µêÓwñ\©ğ}øğ¡z]cÖµƒìÕó¸Ö‡{V­ƒn*\[…l‚eÙãQÚ;®h¯AAü…PùN=÷¥íY[Z|Òve‡WaTaß?:8n·÷ÿBC ÅwØıî¨½Ûù¾¾Æït‹Àœ…)*ë"‡+0>D0t“*paGµiù·“ík¥š±\†4Á)ÄW”‘XåÑø¼OĞÖÏ¢Ù•‡âC?×èúƒ1¸>°ò>VcËà*U©ÈìM¥”ÿ9p¡¨¼EC*ÌğåsTn”£Z»y-œGÕ3gÿ§Ş…°&ãäã¿6õÇ9ü×Í{ÿo÷ûÿã¿¼Ñ)kJéKbÀ:OëÄ¸B8ÓäË¸|Kåd„ôBk\ySIªx)J/ğ
ÁÁĞÎy I¯„¼¿VwXÄ¸7÷qÅÉô°qÂ¤Fl‡G'{oĞúÿpüjiïh<.®a¯õ×=-ši²;®¢ö)I8 ÉÃ+”µÓ=û¥"İÓ·)ª7tGØTªÔŞÙû«Ø=;¯öZ‡'-,Oİp¹GVÏ¼›ö™¤2øÍ¬òn÷çİ·İİ“´Ëè4÷½ÏG¼S™1"}Ï)4ñi‰d"¿kí¿Æ±XóV€>¤O¿Ï6e;¥-6M”ü³éÙôxü!ŒÉòw7Eá@`¥Gq€ÆŞ?”Ò[÷¸,êSİgÓ‡rï”N	‰KÔŸT7¶ÄşI'ñ,Áïå@îé¥Ò¡	jÈ%8Ü›öÉánÓ¿!Â®Š–°
øJb (êµBåC¦êÀkn˜Y´3ûeÊ?øÅš¸Îìğ¦ãêÅ¤·j¦p!/R*à°~ZÕc‘Ç‚Ö#÷‘äì|srtëòcÿ™²¸‚Ø2xİCùÍÑñ	¶N‹rhn5ˆ!ãÃ¸ï€–³¢zAï]H‘øBƒhZ2~İsİød0
§ÕŞ,¨Î.†SàÌõ8™X5›õÆ3Ïxc÷ÜÂ-ñrx;zh0ì¶æ?°Å°v%[òT¶677Ÿşá	[ô(a[jê†–Gç:&c×ŒëÏÎÍ\7k‹R©J’QîgÙ¸ÏtŸlåÚFfI·Í¬ÍÑæ<¿ÓëIµ^­û^ÆBjî˜vÌÁl<óõJÈÛ4f2‘y› ,¤º{¬LêVˆo®6b²UîÉu¯,ÉÀJZŸW­B­Ş»=Ï\BxÕ_Sów{MææLø-µ)¤Ÿ¬.¬jßÎX:ØuYÌífƒú9ßd~ç*‹:G}¨ğÒ©8M<t"Õl?­"æGfM6
dM4ìÍJĞ!İ.£é»Ù9m?'!pãÁ\@’ÓÊãwB|}ËóeUÓ;@æ¨iaØéº{»-•jÇ4tÇ÷a¸B@ÀûJ"¥Ü€¹,<Í:püY%­Ü¯ˆ<Ç?†½)Zì”t±È£¬=™½ĞìœÉ
Òjq¾/­ÃÓîŞIëÀJïfãàìÃgBÒIŒ¢ªÀ1¿Ÿaÿ’S«·°­jv;\¾û6W9zÕ3ìà­‘¿¤ØnùaãES|]YK{jêš8nÕ3 Rú’Çy5˜à	 ²5DE$¼ˆÂ=
z„E4­ {¶ŠÏHY…k{õãO¾gBÀÑqÓ¬¹XT‚adÈÜ„TåÁô½vkgŸJ•{¿YO5ƒ.L‚ ¤¥öY–©8:Ÿ1Q,˜1ê)tã`s—Í‰ü£œV‰ØÂ;JO8Ïd£›¾òZá§ŠvÎZí¬Zë~%Ş¿ğ‰Aï%(ètÜ'bµºJoİGb|?Ïà÷9:hÑnÓ¨
P=˜4Lê¹!™ŒQ½U/â0œg@ƒ
A5ÙÔÚ4¸LjÙæÂŒgX8¦êjïâÒbÎo<ãáBª“¥N3òªtŞ©1nHıV+ aÔ»Ï0Åº£$=“X"N&•„_¨„zõY•r®x­Öœ0µ²}ÔétwÚú6br«ÉÊì¨A_”B„x}|ªø'Tn?ÒÜ”²ã¢KE¥O7™öÁ×o|tI
°ÖãáÕÓÀêrzÜn½Ùûs¯Ë«ë^Éh¦w6né¶1îÙRí+hŒ;ÁÖ¬RáÎ©&šªõû•	¿Ø/†Rœz÷<ú—°sN/&2ˆCºXTu0yO¸•ğ×~4¯0Ø±ëüF9½$¸ã5ícÍ¿«&ËŸi*¸UƒËö¢ï i*=	Ñ¯ßU/zMÆ÷îİ&0¥vëmëÏâÛöîÏû®İµØ
C,i¹G—ì´'*Oñy§æxöp¾p´DçëõJ?¼~ïürú6+ı.“èãùìÂìQ<n¨_°F.Çõ4öã4™ªïÁô½sù®WQ5á¹q9˜M7Óoî{)ºpÓ†£ë‰dv~Åòi1Ş‡‚§8jô¤âa0*Æl±PWæÜƒş¹¸„ätj`_*ëË§m#%Á`üB#*“Á¹¡B
9lğşšLŸCb¨»C‚nà5Äh<ª`}YXjî¨@Ø¤¿ÿşÏ+Ts+iù‹ËwO&Ò­ou²$öİÎÜì=2M‘›TH §jk·KúïD!2.ï½Ãgà‡R!ç;Î£ÊVõµI"‰ 8,•’ O\ yJM±szŒd ¾nA3Û;FË²o×E>+ín.ê¢É5-8³W¿à¡­¸3dÉÊøÿó²shtûµISjNíòBcˆv!ÛŠ@êçq0‚û
ìûÑGØñ7‘ëËæ–)s\š#árûº8Ö°sh:—É»¬2 È@M?ßö¬šÕg«Ù¨}Øùêuk÷àSˆß3rWÛ­êÊ×ííæ$›Ú¸ÿÑMö1z¦Ü^ıSN=E¤œwSVGáh…únA0û5©ÿö¯z˜€¿Á°ÿdşÂ®nÄİ™Èğ
è.º=ÚªÔ»”·aà"Vÿ.­Aõ|nM#mÍ*îî•¿Ç8Ò6_Hµ]–¾ÀšçK®GÓàãs~!²µ*Î¦cø—KŸÆ¾2ù!6 wÕİÖçïÇ“LWf>M 8û\½P¥	ìzÓ*æ~”ÃzµC‹ø¾Ò™Âäoÿ¥jÉ÷‰›mjäÖ˜«£=i4Ôs•¯…ûÅÕÚ=EõŒÅ³dªµª©Ú¥ì*Ö¢Ÿë-Ò)6+¸
¢>Ã£¯`ÁÖ·†4æ4´†ì¸F F-Y>k6ÕÒ&%(#A£¾(®BQÍLùóœ×è„NÇãù|mqëq- Ã:8ÃtPZ.‹Ï,ÒßG¼VgÖJ¶-"·òŒ…çÖÓËñë£Î‰‘ZêŒéèÃÓƒW­vv±&ªNÁÒÌµd	µ48+6ªõ'ÕºªßeÇFg£´/‡ã)Ö¡ëæ®ÿí¿Ä«kw‚ä-ç‹m?äSÃg	)©L´S‘G"’:+Q"44
„N2eŒh*ç
 ©ÿ@ößşCì]`*ÈĞşõÚÌN‹ÕB°Rs¹“Ş¼ê÷jÔÿèúß–-Î—Õÿ®o>~ÚÈéoŞëßëÿ-Òÿ»µ Aê·Ód³–DBT9¿“Š9i•}}o~a”OãG»§û¤/€÷Öy‘Ÿ
ãş5»+<üìy|±Pş \Ù,]b™è`<ª$¨C3²LuLÅËf ¾$¾—TÂ>¾º/›—$,Ÿ•z¥®%‹9ê¤xñSÏ3ñs3ØkŒÚûS4iÚ€¼ı"'*gC9.£^A{5H¦µ.JB‡’ we¥T§Ì£ $m˜áŒ“.Di“B­–CÚ­,$„=¦0©¿ŸèßZµBŸbœvRëù¬®ÔMg‰+ 7Ön?D÷>Z¤=ÿ>[ˆjæ—Í¬~’b€,ªÕª°ÓJãvQ‰¯ìw—4bSF&ŠoÆ@O©ıši)¡&âË¤¹VF—–6¢$FäĞİJ^àc)-ƒZ~|•Ÿl/}É]`£|‡]¯Cï,G•³k·Õcó?!…¨Záe¬ú¨›)q¾»d²¦A@—7¸.†˜2±6´„
E®ò6——w=/*äyYaí'›yÿø¸iây¨¢>×&“ŞÇ'`È†Ñêæ¤p”jİ€™·Ø.–ñò`$*ÉEŞ’:ãOHØeˆ)Å(-–­î»ñĞ€Ä&8!­È(¸X˜fSL•&WvØK¨ÜN'‘DÎ¡	·—6Ué:Ñ‚=¦yMG)0nrîØ Xú%Eh9ûW¦²*])ÑÖNšBŒÿN—¼Tâ`­SôkëxËE·ÖºÅäO\0‰Ïr¢¹àKf×ËÓğÇS­a`;‚ ¨;öE^Ozˆ Ö¢„¿_s½¬ùµ¡qô˜Ú_íô††ïüumtn†*C+äÈ]Dª_xUgÿ¨EB)ÙT8oÙ`3k‰KqHÄgu€ş=‚_şO? È“)ï1¼ÇË{†èèôxº9èSíêLvGìÂ¹ˆ&¤®×á„}ùUCc_aQx¹OErãNåúÒËˆâ4¸Ú}SÂ—•DlÅÙ¨'
ë:ç ó”ÌËEŠåÆlºp.òğ6ä‘ãµ.G‘«—Éé!©†NUd‹Qc·>²üD·¼ú9P$!0÷ıDâì“UûBÆ?áçÌñà!ñ ÚŸt2qP—Jû“†Cğ\(Û)"C¶ƒbqSo´])èãù]´z¨Û~ëNŠôÄV8(9Ä†mİ¿Sl¢2¼õ·jÕÂ4À°o!ü:%ÍŸŒA¿Å++l¶YÌ‰‰òC`·¥iÑİÜ¿Ğ&—BşoP­·Œï¡Y‘Ş¥ZA<ˆĞÎ‡oÒ	-¹s­É}©‡²nà/£†^ßØÇ<¦Şü.–b^zh?ÓáçŸÕ¯§i%ÛÚp¸>ÛÿÈ›2Ë]-O¦x,Sà¦K`|EË³(7DyK”Ÿd€qwìÄØá)lšN/˜„Ig£Z\É(2ˆIB{1`6Â{ğ4‘3)A£O.Ü<éî¾ÎŞî}9ä`o)‚Ò©ØÎIc– xÙ¶´’¶·Uğõc Õ¤ñ>ˆ!r/1•Ó|0ÂÌ. »íÅ@vrBæ`ğ[ü%ïé-ÓŞ\o_$1Â+ÔQì§!ğ§QrõT3p®f‘”ìvº` e÷RçfZ¸›:·S¹g×· _Âİ"µåâ² a1ÉfêS1$Ñ¢“0¥3z;³VBæTäƒÈ&^Øbuòäeæ‡”WßNşoÚİ	~ ¼ı˜İ˜ò2xv ¥Ù}Q3]b±HÈ!°í¥º`á]®¿¨ƒĞ²JBM›·DâpŠ½D«ÊDWçˆ.9
/\ë*ÀF	›¦tSøêµ']”!§J*ßÁWëUŸIuJ|¯ô×E~EÚ'…$Ã‡öF¬¹ü½4vòÀàse1»­|9@¹aô¼ßËûOÜKj¿iğğ“yÿ©×?ùñøşıçKÍ?èµßÓü?Å÷¿ûùÿ¢óoê;|ÉùßÜ€ÉÎ¼ÿnn<¹ÿı"óæã#çíğºbaUO¾¶!A	ŸUÅÎìRÔŸù‚P%àÎæ¯¨RéÎxú^µóµ8Ü9hy¶.Í™N:g´»(Kgïğè¸³×ñìÖœÇ‚„Ù¿?»xÅ²¢³‹öô]øÙÁß˜Cxà$W"g.—Òd² nÄé[àÌŠ²êÛ•nÕYåŒYÁ|3‡VxzÃ²‚‰NêWÔ»İVçu{ëYH¨ã£=¿¢{ş|4ˆŞ‡bçøäÎ"—ñŠ”U?z¤½YŒ†e(õ<L›ÊÊ©ÎŠ–!(µ¡2Wß±tl¨_/3^BrôBjª} Ärô½ÌP
±¢“C‹L=Ešç8È5_éÎÌ+WPU¤íFrr6“YS†iT$Í<<ŸgjB!×Ÿrjú7Oëq™Z4`,WÃfS¨ù~şù{™à¡š”„â¡±=ªk$fÁ VªSáx[¡P©KG]“t®ÅêP¡«,£B'Éš—œ8M˜â 2Û@ÿä<G!]2¬—ßÌ]cÊÿCo<ƒ+!âıJf~[5po ‚çÎµ®ì¬¶8SÚ­•ù¨cØñöXõÄpû2f¨Ö§ÍDq@@İÃ¤$ÜhlôH$.x- L
”*‚±HĞ\Àhµ|}Ôö²Ğ<k}
è»õ{7ÂUp€¶ÿë÷/÷ŸÿúÄÿ)?9@haRö¿ şßÆÖÆÖ“ÿwÿ÷…ôÿl »6Ó@åÄ#¥7b5ì]4BüÉœgS1
?ˆ‹0˜’>ÂçÀ’AOÕó®H1øİ°ÏÃø‘ ½<4Óx1yé­¼H¦ñxtùò°õ]çù‹šüá³ü¿òb½T§è!œ¢zô¢*Œuà 
†0#¥cyF¾0#sBÀfÄ>wõg=”¥Ô3­g&‹áğ¥…´	{ølRMŞ½¨AŒÕ,ã¹j´yLf}`°úCØÀqwNÌôoft”óénÄª¤•TÍ¬8­¾ŞØ“zk¸šŸßp4	GÚı¦^_ 3¿¨Ñ«ñ³÷çÖnÁR )‚KöñùÅ¤7|ÊT8‹´JÊÄ›è#Œ¡zš&O§îLÔWaëÙ:-‘
¨Ù+Ş‹SW¨«ƒè„“)Ñ˜xVDeóziÒi{ß¥\upıAF­ş‡[P3º†RªE¹e’Å¡*ø"ÑxæJÄÊY¤œ/‹ÊLõôM€2ZPZ		pîã¡ r0ótˆ¡0ØJd
œÖ}
Í–*Ú I$N$E­1Éâ„—Å ]¥oQ&VG×˜ŒŞ#‡0R=XÀÒgÇ;?£ucFo=¡PÌµbİlÏÈm¹	5QR!M_÷ypæd @ıŠr¹Ó>¸zZ“ó}³|P›#ŸIx3‚/U¯÷÷Äú—º“ìş†ãn½oğøK2 ëdj7ÕÖvSEßœ$p´iœÍ‰vÍ3¥nóCµ3öÄ×À3s¸hafè ¸†íÔ „¥Iá”ß©c&‘êË–€ıİÄ´¬Yp•ÙÁİ‹¸àgRô‰>&Xì-ÆößÓ‘>Ådhœ¥b‡ZO_¢—.²¨‡V-48÷|ò?9ÿKö®¹şåùÿÍ§O3ü£ñä^şûE>~5:O&Ûæÿ&ºV_ç@a~E>Oşë^¡DÂËd™ú>ô¼‡QŒßp+–Ö¥/&q¨È-™#fVeÔ¨>>T‚çÅeĞø‹"IŞ¦öi–»é}ú‡4FŠáÒ¨¹µİ:ŸHsj‘«Ñ#Zìfd6NúùŞ˜*B%’@w	(_Íw+3]†¬Û1ù¹KùwF N\Í¯«>HaìbŠ+9!,‰ùw™Q’D²|ÙÉ7ÓÛç”¡”eÌŞ´è"o‰Êæ‹
p¦2Ä/Ø•ä¢aN3GŒ/$|‘ŒåÊòÅzå[âı›îVÂı`vM‰æCHÂú4J>¤	Pş²£vSôk¬Şæm¤·~@ö Štÿ ‘üâñSª‹2c:wüşà&¹QÑÈ.BëÉ¢¨'ósö_½h¸©ß8xoşĞ!_:äSÇ¢·®·Uzï€Je‹œ>	ÄıÅFòÿcHDôÇùL*(ä½ÃëÀş¿±ñ4«ÿñ¸±ùôÿÿ2òÿ£)­>šz8•ÿç,ŒÉQY"JJòq¿D ™$´9*½ø†xŞÃ×ãÅx0@‘B¥E²4Ø¶ (l<ÓëIØô÷|%¤8B|
âX¬§¡mÖºŠû¸7¼Ä»8¼p"—óbWk–z-İr*ZR;ŒÏáîeÆµvkg÷ dï¿TÛé]îE-xIêıã‹‹¨A×©Â½%”—wÓ
suò¹Î¨G& ‘a‘‹ŒjBÊù_	ôŸ·Î]£U'KûŸ‰éH¶åJu"è¢DøÇşûÊ³
ü¯Í=¬"Q´xÌ¢Ål.[6zW%şí¿ÄßşÃ*ö”DO²½È¢Ç!²è`Õ'<úx‚ÅAj‚DVvyœ$×è«Ü<Qé q &Ñ£("ZŠ¢è9æŞ›®&Ö‘ŒhØ’L`JäÄ¥Ç›„†Ğ,xb²?Àµªˆ L¾Ùh›º*@	=éµ1‰òäŸ”1âóFGKô4mÔõª1¤½š BrÀ\pÜ'P‹F$âAÑ”úÀ’ §…œXµ(5·P¯â^?àşsÿ¹ÿÜî?÷ŸûÏıçşsÿ¹ÿÜşÁ>ÿÁ!$€ h 