#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1020101876"
MD5="d9784bc7325fbc145a08851a580e7d05"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23916"
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
	echo Uncompressed size: 168 KB
	echo Compression: xz
	echo Date of packaging: Mon Dec 13 17:31:23 -03 2021
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
	echo OLDUSIZE=168
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
	MS_Printf "About to extract 168 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 168; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (168 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ],] ¼}•À1Dd]‡Á›PætİDõ"Û™`¨fÂ»wÊêR_B?–kƒ¨Äzgza=şèAtÈØ%íJ`ª¾¶%ÅÔíóÅ%¯«~ö}‡pÏÉ§Œ>ûÑ Q%p°š¶æ¦gØÙÏÔŸ{È"ÆÂ³9û¯~ÂÀÕLìĞÏ9ªùı3È|_¯š:”œÌÑnPß»w¡"ıÁãÆ€ú½Ñrrí¾€DK©ª>©h1ÿ»ÑıjEu¨
M=‡ˆµÿò€uòs‹ÈK·D×$6ÔƒuR”p‰|@P~XRä,@\©¿êBn™ÎLƒ
$Z
dÒ€ò÷Úr=—ğ6.dH¡ƒXŸ†EY
…ç™"ìİíT%9˜åß?İXıİ®ÃS'eÏS¢†8z@uÒ¡şl—ı,Ù‹RYx¥¶ˆÇïÀŞlU±ïGqµ j?nVÂ™é²8hp^­!™nà‰eÇ3wÌÆRQñ&9‘b€q..  ¼³â­Æ:ïÊ•:*ƒrˆzËw’…{.söwl¥…è·ö>Çèõm™rJaÁĞìùD½ãx3TÙÑ]8º®¶X9ŠÛ•øb5…Äfû¦¢92å€g9U¢ğÒôz¥”§«2£ƒ­¿„|;ÁÆ]ÈÃº#YlW8©Óİ|$¶-zâÚ1¥duúp\£]Ø™€
e'ãWŸÎ&ònÛÔ
İK·ªœµÏ²î1)¬}SøÍ9ûƒòË£2B8swcóÜâæk¶gY‰·i@†Âæ±ÍòT.hz}|WÕÏÌÚAóqàğ¦ªÀx™³PI~ÿ m\g0L#æàõµAê;.îp7[Q¡-Ã²äa@ÌİiQ%º‰Ã$(.-9}\KÍïYóWÊ¥U%Û`¿^eİ|Ë´€ySXX†­gDÈø<×{Àr¯¢zÂ¸c‡iñÔîgüÉ¼?¬Vòª¹UC4mlš³„Û¶Ñ”/‰‰£œ1fª—m1;ğŒÜ –óhİ¯+Ğ-0w«æFŠ9Ã®™±{¤ò#òjA˜8([=yÚ4áyË¡(Ñ„·Íx8±ëzô±‚”Ò9údø!9ª²¿:à÷ˆ”:NĞ¶h5İ\ nñ5/F ‹çCS8a|”³lÑpïF}{ş«kÿek}hzkŒ´†sBª2Ù‡ß™ıókDbÊ^Ô¨3–Âd—ªÅn5ÏYÕü±óÓÈ–®¤\ÊÂh&fí&K#Qe™ÜUçù|¢EƒáŞğ²)®é³„®Ìi–¶İÀğ÷Ù&ò85óšeÜáæ^¼¾At´W:NŒ‚Ÿ§ú.N­·Ğg éiWw±
=O¿-{ºBtı¬¾c½à'EĞrL4îFû—şö7K¶‰96Æ9æÕ4ˆšãKş">ÍuQä–lŞÑ7y9‚ú·¶›Şİ£ƒƒ6¸¨ú«ù…öV|¥Û_eVòìôc¼£¥‰ÁÄC…mn‘cĞ1#rîÿ õ1îe«³C¦¶J‹÷B#êé¸?“eÉØÖùİ—ã?¦a‘%$Xî&gôpÜª}Fäš©Ù»ô²İü„é¶ƒ©ÒÁ™Ø°‡$.åıEí[ß§âİZ„ßaà¾6w+E·¦¢ŸÏÒg;î¸–rkÚŸ™²¾y>Xß©ıgÇ{v±˜†/_‡çˆç`]“KVÏ U æ¯U•?‘£R&RÙ©Õ%šÑá!Êº2öã›ä‘s[H¡o!Ã?I[ıÓÁî,‹kÄ²ñP³„´æê+¸.RlÜpç‘V]g½vû¢2§ÈüÁÍòóË#±ı™İ[$Áö]–.ÊÆ+_À z6ym—õÈµKõ#Â›„8ÏsQ¢&+`×Šjû¼*ÏËšñ¬ú`·~dñÊ,M= (j…CÿÓİ›g7ˆS·k:¨TKŸMûEÛü¢‚˜3Oòhèÿ9+şÉ“A.;uË‘ü+5ı*£-‚-7u—hhI%íÔfŞ¼0,©"ÉsÖrQ? 8ëIošÉmBã^¡vôÂAûüLPïu‡äØÛáB[‡¯.l¨%E†Œÿ¤ñÖq;ô•ÓîÕ}Z©ÇZpkª&ÂÒÓ]ìÁm‰ØZÆ¢Ñï1ŸÍ,1<¯—ğ‚†•‹&£›ğT?¿¾2ov öl¾tw°ç^2$G?Û²¢¬ÕPÉèQ˜Ê-Ø+)ƒµT‹ºü¥ì¾æ.:yöX·{µàÿŒ,!^z¸yD~¤Ô+cà¤•Aw’SxÇè…:BXD_›O3Ş&ê3•4ƒùø€÷Î]—s®½#õf\ÂqQÑû`h`å=½Yxsg¾BêC÷~r=Ø1Á2]«t«Ô“‹ÖdÊÌ„$ÛôÎãä°Ë®KˆÔ‰EHÇCq/‰µ†Úk±(x™ÉÍ4q‰…(,ìuÕoØçcD†øzDô,Òé«®+ê[œ‹h|¯‚ç>Uíg¸HÛ­IIÀ}°I¼P´Ÿw³—êÏ²•Ã0gc÷¬ş·æ÷‘åôdùL¸«CJe;C!N¶n—>$VØ•FÆ©ª£+²–Ë>« <g3ü{Påµßl’[&ÖùµAåA8]ôeø£ùHaè‹¯y;6OŠûè­'æÉöe×Ç"ÉôøS…ÖOŞÕƒŒ,×Ó¿©i¾¢5S*ÁNväq):âqÛxÔøè¯òy%j~õbgœ›W3€Süøm9ÇÁ/>‡Øı —wb’Å#Ó`Ãx7Y1ÎfcÙX%kFÚÍ.ÚÊĞ¡xÁ<T’{8Âø *šw‘Ú’ºyŸyˆ¥ƒ[¢ì„(|$UzŠ‚Jçf-'àÍ£CxŠµb†¢·ï¿FİsBR±ÄEÏIÇ›·/½Ê¶7èÖáE±º G¹/ÅCnúŞE}õÄ°¬÷£\Ôr*Æ&pmIjÉ7¡¨¸˜Tè¡€’hÂ¬ôYÎ!.©ŞG‰çÅoÈ2Ä¸’W¯œcÓ³…œ·é"XÍâ)éç–,¹Gœ„Uİ’ÓìÑ¯çd~ÕÆ;ıÔ¾Ş»¡âS3^xÂFÅ`EyL%K($6“‘zE?=ai¯,åPÍBÏbÑ±>2S	¸Â¾™^}mÒMáe&A‰ÆiÄÊ	â9X/K<L³ûï®‹)‡™; J‘ŒÂIú¤¨ék©¿¦Îò‹0ËÏ¾í–ïÇôN5h¼O¤8|[+«Ìş/8!fÒ…q]=].õ*…¾}m­nÌ‹«hÑKS„=E-…­KüdY³wşS!FÚµ#mW¡dÛwÃH€•	Eøº„ƒ»¾¾Ãú³jkOúï¨ š½^Ši}€Uz)ëÖhÜXÀä3¾}V<k÷®….ÖñflháCøB}'h/A³ºÓœ½°Ğ‡/û“GÇÅè*ë"N‰NAA
šÈMjû:;Îëğóœ:øşüìêÙ Û3VÊRü2ÓÊ³ÆR³4d,–à5ÉÂÂ‚X2–”{ö	²mãï“O.ğÓÀ¸¿¸®Ó_Æ”?•I°ñD²ì:‡IU=`ÛôAS»”oµ¸ƒäåHt‡zH˜ñ- ­k	“éı4_É`Ö(¤‹ÀpKtbü	äàª]z.˜é¨·gE:•8—à”J|›Õ£n—Cü¡f°íjnj´Ø9ñAè¼}—J¯„“FÊdñ?¾áƒù§“;JM%’º=¼İÇåõë·‚	¸±S;G`RÔ_¡æ½‹œÜÏôBä“E¡3ösÇ5x—Ì·ú-O¬z±JB±¸Lÿš!2h¹×°°Ë<È÷şWø¢ízÅ*ƒíOŸ•Í…–AŒ’É¡špTj”§.™ÍWT ÆËU{¥67 ë¸…}·•ó¡Õüùl^¯:ŠS&X(a¶kßÎw+$»¸ ÔŒlÊÓ¯¦ÙXa–;‡ç³·Ì8§À<n.Æcñùr7g§ÔÔÒí›Mem!D÷Œ†’şuY0—Ä DÜ*Ú
B¨s¹'Ãğ\‡—òüø?~Õ—bÿgÍ¦Ú¸õ=6(ñâV¬¨J ä®v¦Òv®ê°#)Üô”õuh‡"ÖÑoú”‰&ÄÁí Gùl¢©Øj*Ô² 	†UI(É{‡bYEŞbX²{Ã?
pâÅ‚Vo“Bb÷¼M×Mİ_¥fO§¡šfJy–ålcXJD O™Ë]WªĞ™MHÛ{‚×–AI/ƒ´Ú]˜]ááér`Éu›^Œ"L€bUGßék/jéÑB>Xªî‹u"Šöæ’Qƒ$ÉÈÑfêä¿°ş‹…XÓ¦ª½ªAû±øT0ß\6*aÃVÊÂbÑ¸"ë¤Äİi	¨Úßt±öá*áAÔ­ª“Mey¯ı “Wù•e*^Å«=&Ğ8ÚƒKŠk+`çÅmv7“şå¦‘÷£{*0ƒï:„:^.Ò5j6ÈFd\â¿4&ÈµçoæèÍŞ´ÏP»Z#¡5ñı•+hÛUKÀÿ]ÉÀ¥¼¹|ºUñ¤‡v‚dXÛ¿òø¹näVCac^)oáÄëÅı©«+ŒI´À¨	„ä•Ó~o×Ÿ•¿‹ß­©ÁœCYâŞa£ÈiLm¾”ğ*Işè¯”·¬Ê«÷é²ığ_auZEÅ'?œß
-wÊÈ%XÛÃ9‡ç4ŞRä™>-˜İ™°æ‘[˜±C™`9¬q,Ë„XP¦dáctêÀÁğ›˜ö‡NÔb­ó°9RRÙ¹×
?ğY˜û1¨Rİ
¼nÒ'j2šQeLnØ[+Q	³>ÑµnÓxü>Ç²÷UV®‘ê€-1ÓÙ“øóˆªx¤ À5]²Ôb}yq›×Ÿİ×ç\5¡ÊÉ–CĞ.çM+ãœlÕ¤Ïo
ÜOª(2WİÛn`¶* ¿=­JmQî6°ÌXfïµ¬Ÿ£%YuãÕ å°Ee¸%Æ8B=
Ú=4:1N<mÑSO_	İ¬îw
›ş¬Šx×R².@X0~'Ë@£ÅYşŞÌ£á,LWJóBå7;)Q2:X4üp»' ]íYãÛßÜ_ğşa“çîÁ*7Ã=œ˜Z ãÄ1Áõa'ÇtÖ¤æ=ş '¥YLqØ,	£F!¼«|2ú…¬‘¥GZ­ã‹²®XXÃæå€XÅ‚ÚAwWêk]•®ı*Æ’WY‚_Qµšzú_É¡Š)ş·—¨.K;A‹í«ç‚y÷oÌebÉı|1/ÍÈd›’pKuÃc“ şÔBÌ÷ÇW°§« [rWÁOminU_ıv¼’pĞ»&©Ù¸ÙÖŒH@áÔ‰ºÌ!©G+óÆ0'y’Ík&şDåş˜p\<ş9[ØbÖºˆÖ1Bô3›#I$ÿLÒÕvèØD,RÇ/ Í/)	äşy¨—oÛVÎÒæ)¸§Ômº}öT{j©+$×&²èÓ,²n-˜í{‰®|
	–L Ï™\³üº.Ç¿*l#€ëpÙ2iæß«Ì—pšæ2£6u¯ûbÛ®o5ì
ãgĞ­ö7n .Ôg¯šã?áÔ!Œ¨ÜÚ"ÛÍZhˆÇOÔ]]¨²O‚¨dWÉ’(ÂcÁÍ:/Îee%AğÎDîè%;Ïª'V\«÷]­Bv%İÌpR&ä6+õîõÚ«œdÂı§Z|ÔŞ~cÊ¾àôQÑ	wX‘ú:ø8÷dP­©kÈu'˜áûÜ¥o#şÖ§½B®\åJ#¤RÓEûòî+g³A®o8ÿ¿ĞĞ%7´È09÷ß—/™ıK*İGUëêSdÁQEóÂ¦û f]ñòÎHRü?à]IşåäşB?_ÇÖ¢g®œá–G<'’yÍ4.AtŠÁojrD&Ød>ûÃ	>,2¤bÉŸÇ*«?Hœ¤e2ÜØÊå>:ÈpËû™N™öÒÿßÏfÃõˆRpÊ>bšÍƒÖ’ÏsI/ÂsÈ<ê†¦$Áª50X¦h%Û%b2©C`§²Ø¹ñİF	$WÔàLÎbo‘W3“oYœi£á“sÙNw=´Ä¦†‘¦¯¯Ø4Äÿ¯huÅCùê>Eì+-Æôµ,¢ËÓ/»²[Ú¸›îÁnkŠiÅIÖ-U ‚€&Ò{AâwûåWPÿ	±¼·šuË§¹^ñdµ®M{NLRUîB½ÖèS~ò–K,å“ãÿn2f:÷ª<²[¡rë]O&•ö@FÉN¹ùOr0oÚş¶²53Ë3gR@³95Y6Ñ÷±+>~-Ú!ìw“ƒK„ï“ŸÈG·9;`UãkŞ¬ÙÔÇyàüq;5’J‰$MÎ;’ÈlRì­Ğâ–‰0‹¡;X’ˆ®£Çqø,¡•vIbËå
u‚Œ‘¯ºp_ıç:·n‘®R˜øª1¨Ô.ÏîgN²öúã‚¡Y [çàµ¾/×J·‘j ï.\¢£ÿKöËñ"2¨IÖÀTw|êl’˜ãZª@™ôÓ;ˆÛ¡jE0‚À‡o¶ê§h)QlòFy| «ëJ4RéLD¨÷Ïó6£8;­¤S†?Y6l”Ë[R (Sc?"…¢âÚ¤$5ãŒZO Ã0æ—šh²|_q!$Õ-Ì¬n¸k³Cè
lkp{ÂRPdÄ¡Ù; vÈaå:dúù®ºôÄ*iö/İş†3”ól•7’îğÖ ÒÓübšñ™ÁÖ@Kª¾Oiyõ$â§šX[©ãSİtmu3FµXüTÊŞ€ù“•Óéõ&ÇÈTb®ëÚ/]Ş¼Ğıc@ÑY×Ä.¥ê¤ŞòÚªYU¶M|s	¸:¿Aà«@Rñ¾ÀcÕnvEê
)%æZ!¹PoÍ"ô1‚f5ŠP‰v¥¢wü@Ë³	Q`8’T*
ãˆ}ºQÿ¢Ø,¬ĞÈú3p‘8Ø>€íG\|ˆğ°s¸"ãR‰»ÉÜÒ´ÙOè^%¥Ô×ğ|ìî®oö[İÀ—­ˆ¹UZ)RŸÇ,ògÂ™ÄÚ–%)ÌäSD
‡ğÁ…Aé¶ü!N^5“5íÂ_¥fòåÓ‡Ä¹UÀjÍ±…#PX¼ÑÌ|Œ@°ãP§0ÄóS"n±i’äáøï½,Œ\ãqO±o“‰8¬ëÿ0	ÁŠ÷P’åÜ&WânY~›”…Qí¾ÃdÅ  N,lœû$¾”§äŒ£ŸÎ4›6~JİìsåùK—¤Õ¹eÄÍÜ¥rÑ)âoı¯»ìW' d¨Dº€m|ˆS¸ ™¹à2ÌÓ¥ƒVÆM°3²7=eƒh/r<t»´Â[¨½"ÂSQ~]ĞrŸĞÊ}½-dEù¯:ÃU>ÿ›Iê}/Ç)ª£OâbS„·*‹I%ş${vŠ1¯aÃÍ@ÃÇœ7z’¨ğló°¯!MtÆ/<9-êË½°úQü6(³Õ83ÕÀÖÿ"
)Ö+ä¬?Ü˜T8ú¢‹é§ƒ};Wy©HthÉ€’å,¼zåyã@‹U÷½İ40,ùƒ‘¸™½¯qÊºW% ÍãëÂ¤G;­ib÷ö¼ìÊ_qUà1°^¢aÙ™İ½K*¿ZG–ºÔù¼ÏĞQWWòc@iÓ©Aæç“O&¹ñcôâÜó‘ëşÎmª'Ú£hƒñÓÓ……6
¾œ¬=vúß(*ÙÔç¦‡Å|±a8Ccšhhã*7l±¸>øD@2«¯©LzÍ‚·R»³ØÆùÁN´OàAı°_P Âõâÿ×ƒ÷Øó.öÊ'"I¯/J'wM)¾4öû »Æ%!ÛO™/8ÄxŞ9¸Æ
U5Â«+ fv³5“ç” 'ÂkW)Çıú)–Kÿ½ìz¶¸MîÎ¦§lz±7:<jĞÏIámZ,“ötk^õ°©†ŠË4ÁXŞV§äj>¦Ô1ƒc/îòP%2sşè3ñe)ÿÉB/¥^E&ì¤ØŠeW
êáôîRõÓ¨…ú,ƒM^ÍëÚø$hÃoz ãHËQİÚ¬ÊWaâ4¢Rº	
†ÌŸ>UAç."°ˆ“Ü5;/"ªªu?\Ğßß7›ˆ«ÀÙ=öŸ¢A7_,mm¦ò­c‹—‚›ê@ò‚h$(-C—h·÷ùİ©”‘UÁ)õS¸FoO­7ÛJµ á~UîÂb4÷Kåö¾B—ØHáôe2 FR8 ­†®3¢NÓ3ãŸŠ²Ä°Å£“Iœ“^16âéÛ@i™d;Z … v¯6/9Ó­YFÇ­-é·€º»wE¥ºÏJ`í’eb/#×¦ÖSØqkÔêÑ¯î¤ 8ğçnñOäUåâbƒV£R&~Œ€»öç½½QÒŞì‚ûĞËì3¢¶YìõMÛpnñ=ñš®h¾®{tòó¯È\ş‘Uuç0ÆW×m‘¬ê­­½‚ğ×ÌEÆ'J o«ÆZª=8ü¬Şë3ÑópEeÒß‘$ºBrO_Ó“ÌO¯Ò£ívHâ136Ø¤8)^>~/ŞñTHÍ‚æ.—êİš&@+Ñ=ŞæL¬s‘™vû+Šû³6<İWÀT*İù,ßÄÑ½ïJÎ´?£N¿vÒkˆ–›ê“œÑ mÕ2£õN ¡“DNşÊ }¸ÿqY0 ÇPª=¬šÕ2ğ˜È…?œÆ@ÏÛ{Ğ“®)ë1ñ5üç2˜é4ª ;ÔYº.üX“vÑüÈOva¯?`GğqyÉ	;fŒ[yîUrjŒ y/ÓµàQ×ë,°Ï;´•Ñ¥À²Š†„Ô<ìİğê¾aOyRÔp,0O¦„«ªÿ·7>ô—')¶)ğRÄŞõQb0M£úËî&^J—Zz?aBˆ›ê‘Cšh-€qs/Rvwƒgh×ÔŸµ§Z‹m2kvl
é¯-L­{uWúêI¿¹…¶€v*zÊ³ã%=†ÌËäÖöı’D¼QS-S[W²Æñ½nG8H!ƒO‘]ÉÉÜ—¾ãxøqËkJ×¸,«e'¤–mèàï%óôd=YØ‹C³Ş	FŠx¥9‚ÓÅ,©æ-,í½òP§Ó]E yÍ¥‹B®V2%OÕ	%ù˜ÈîšĞÃI&ÄBÃ§ì§èµ®ƒ˜a?ï’ö\D˜oZá¼CÓ4Õº‘k‘ BRy&¹0$ÿ êƒPü)°˜V+ùÏ òj¼ã×›å©úN:éNApŸfh™Ë…¤·û<P¥¾Ö”æíëÙØOÈ€U¯k£2º­ÿµ0_3SN[4N5@®"‹xËˆ­rV;‚Ç0«ZÏ:™@#9„ÁPÀ$Lµ2õ] d‚qÜL‹"ÓEü¯ çŸ!•ş.«—Lß.my5o2úó¶ö`ş’€-¡©¶\Q.ƒRçDg&k·Çîœ˜©>?½røT¯m±U®{çè‰œ€ÿqÕ<éËaĞ™?d„Ù-íÍµì·1›eÓq÷ü©ökƒİŞ`TU'3Q¾Ufö`;õûCååCLNwdÌ:_8¯nø'ü/´È†º¬¾^Õ™ö<éFùsLÂ´Ğ‚VÚ ø¾®qÜ•VğT€|ŸÚ¤û¡'K:ÒPL‘=U_¶¥N?"äşÅ/¶×ÇMA<W´,:sln…‡hHx¥3#’}TïöÛ$ÓŠÔüNS%Ä—cjä‘Ão¢ı/}¬“ÍújÙNáËÙ¤4¡Ë¶×ZÄ±«bÙ±ë¢ÉŞF‚nTUCTÊ8¡Q"NeFÜ<5SèM•À­n°—âl÷+»å0ZáÌŠ‡’7¥èü-£GG66ã…!Ÿ¢<)bºÆâW0{ñhË#™oâkÓ%W¡p•xí  ¿ÅÈéàá©ŸPõ…¹¡iÜ^ıÌ :vÙÓ¦sòÄX8B™ŸL ¶¦QƒT[å±AœA¹²ôœœEXÓ;İzÕˆ÷øÿCZ;=ÉA†_?=¢¨ğ4ÆH¿~^±§‡†¯êƒ"l¸ßác+2,²¡èÎÖ“^ }ÈíÎŒÛç*Dj$LÜ¦“(~Œ‹	8y8âáÔóg¹ mieûJÇ@¿w" rŒf‡‡™‘4BşØoP³GÁ×ÎE Úèul}PŸœß°Ç(vµp·Iî_ÏZ¸ G(iüt*à[ü¾ƒ<(±h4‡GLFÎÂÏùò~†¥K~<Áeßà¼½ì
¤…ÊÀ¥>òUg,hF¦F9U*C(u—lG?š™ÏÌdÿ6^A1y¨R¸óÙDäß(S¦¯ÔÏ®0uÜÛW·¼€l €·Î–ÉZO~ÉY$‹Ø\FX*¼ 7™Êb0¹c¹¸O5ÑMu$@T$apô0“BîqkaŠÊ.4}è-¾S¦~Q¼™÷­0dqøó…ŞÏ‚Ç§B*DXŒ#ÖZ2"p”Ee[d½ç·zUm‹î|¯¿ùAŸ1œjY&Ô?·.ãa¿å–×Ş–O%QIÍÆ‚Üa‡¦&*µ)³şÆ)«qÖ`’ÁÁÅ¾ÈäQä'!$ã“KT’·k²…& )næ;Z+]r&|cèwœÀsO¼9eU‹ğ0]Ù#Ùœ^»çRo‡‘iY	ûé[DÁî#ì8qi¼Ş†½×àÀèÄ(ÁUh÷z={ ÕBVM´p„„™¶Uv°GSİ±‹ˆÚã]Yø˜0$èD„«>l¿l©?„ƒ‰øH—´—©Û?RÒë §VŠM8R‰gß‚ïŠÃáñİ›^¥<Ãˆp¢¢©«ĞÎ€!8c‰ˆæÕÄ!qËJ*KY´>Æz s·õö†Âëmoœlıñvê\"‰Çû¹=ÕËêíN§ƒú4^ÔÔj||ˆÂ­<³g«E ­¦~îæ\j«ÎØFåÅÙ»ÀøF–”6®£B&ßÀRöŞÄ£İGa™g±‰f7Y«ß©i¨_0fj«çıoÈôÙæ¿,X?O[ÔÚ2¾åSÂ²ó)×+C¦Y)<ì	¨ÿF'p:¾÷«%G=÷A¦»·/¥]¼•UùåeÚd¸Wài‘Êx„ªµt1_vƒhÛà^pÕÁÿÍâ®+4ŸsŞŞ$`¿–2‹m‰a{K^æL@7˜jF Äò$ıÊ@ÂıË>(.ƒºÑe¿Ç¿*wn¡Ïíô‹ÕÌY¬\`Ş°w
T«¾éMGï_Ïàñas}å‰@œU™:x`[H‹ìŞ]Wö£î›EÈâ©Ó]M€‘Á÷øU	6ÙÉäHß†7e-¡œ*Ïƒ?œk^Ï •sŞÔ³6G‚~íˆ!3¡Â½y&8>†èCcæ5ÑBÊ&Ça•]†l„³×‰¶¿™H2>Q,¼í7½ò)XYN,ìè›ÍaUk·ÊFAäádã6Ú®ÚßFs@¹:Œóc/6£&ÔˆÊñÊš{?l×ãby@ü#wë¢–Ä}»ÓI²Iù‘M‘ ÇïÎhÿ¤7‡dáNDÒyRG,[Abõ¦qúš	ß‹äÒ$‚¡^srÑDŒ0ŸŸ37¾Š#åfl,üÌ`¿ò[.$M+­Ä¦|Ö¾&K¸n‰8£–ks“kÉ¸+]ß5)Ú¿MÊĞÍok#~ù}Ë¡¹ÂÇƒ/åqXïè‡ov{@ÒÎcq,â‰Zÿp¬ö‹ù\ÃõÅpÚå”ÁwÉ–õQ
í¡¹º£xSÑ© äkı@‹Áãõ“hH1²ú™MGÎš_2zsô”‹¬(Ô¶N^—(ÊlKäïz'ØË¯÷;UvEX
³Ş—å5Öèõn™’Îõz,R>ûÕ{z…Çn-\(üÜœ®VoIİ©9(ß$ÿ»rÕIDÈ²Ü\Ë?ãºâ2TZTŞÅâş‘öX:Y­¥P]™ÉB‚Ì¦”r:ÎÆÂ½Wø*9¹B-.A×ùëÓ?CX¼è•&ÀLu“:Dz””Ñh
½³ÕÚ‰\Ñ®óì±3	`‹orµjô9M’ÉÅtKj#é˜xp¢W '.Œ>ieaÄ"šÅBÓí<kTdxÉ´8#—á—ÜkSğU¥à†ûO´kˆkÍ×âUà?J2VÈ_NeÂ¼Cš/°õÎx;¶ñ©}¯58†^€œ)#šb¤³®¢w"V£:ädI…-0U®ø+»´’¥SÈ¥ OwÌÕæ^õ¿&Ú†(‰Âßq-£jôº:¯ôzÂ¹hN6UãÜcÅo¿OÆ¡Ÿ«ñ¦ğmÖ— !NÄ6+Óê~ó¬ê,NXà„†‹—vÚÚ`è‚Á 7Å9>Ğ¦ª¿ºêLö4Êò¸ÛmÕ*ûÖ@ŞÍ›£TâÂö•øÿºrÄÓğ.¥xÌpÒ ¾äYZ{ciÈ
ì{Èv,…‚i#P¸ÍÛïT´˜-wnåÀİ;Ø9»GI½»¯Œ™‹môµ‘4fQqËwó± ¶ÄôÉ“· '
²Rn M~¡Ğ¡YšÓÜZ1Z´¤C²%×¸Ow*%á„å1û§Áˆ?oàhPs/š²øÔg"h{YÁmnº¿«(ÿoMæeĞ7ÖZG!def÷›@zXGìi­·f¼Ë§±H |DmÖ5M„y7•dŞ\½÷M
ªrÑ<-ËÁxlà­Y=UĞÕ1ú@É­ GOøÇÎ+§0[ŞG úa´¡ş&ŸÌmXÅI­Oáß¿K«Ì*m;Š_ï/ùÔP¢şŸ‡Y™ª4ĞÔsJ–‰É‚@ÃOÃSßÿT¯Ji­¤¼á‹úrèœµ…4D™I<òô©zhóœ@tm¡¦vâUiLÀ·Âj6È¶%_Ã£øp,·“ÙmŠ(p5<PäÚ¶‡ĞÇdò¡F \$–`#y[šœ³—&2¥‰l+ãg:ó„¤K¸ûƒ(gq¥q'FÑ&CDÓš’Òıãôšÿ~öŒøø­™»ı¡3î„¯[IÙ
»à³ÇÎÆÙ,€§É”°ó"ÑásŠÕ½0€æ'j¥.zCulwN¼Ãxn@Ö‰m•th{f˜:—P/ÜñĞq©y­}7´ÅÃšJv’½F<ö¢+‚ë‹ª>‹‘`9ü7'Ó’uœ‹SSå \Ø›FÖ˜1?ü.wôëI6].Õ[‰vUWˆ3©>ö}{!HÏ6_452?%ˆû?ü1"¢O¡m·òŞ±Í«ªÙÒás–£{İq
šNÅ(Yºˆ»n5›5_h~ ¿´
ÿµ¹øÏ¦&\E1jåÊÀuÁFù§Ÿä¹bÇ–z^#®àôT÷ò>PñBÿt ë›³‘-–óÿovÏø:ødi¨¡Ó-”±8» ºHÁ'M~Q<0bÁFã–nğíĞzö9zö‹Ùo†Ñ&@>š+&Uşú[z<WÛœq´ìaş£”l;~¦”$~8;³ığ'n1«_ãGœs$ÕpŠJ&À‰aBÎ§³o©+áB»!¼ÆO…kLˆÑ‰;(ë;àiÂİt®æ„è£¼OÆî(¼ˆY‚sn8+˜îDé™Á±Õ
ë¨r“v˜i^#	{³~˜NõÆG¤Kw%+”4).ùJU×ãÔPwù§%âWzßV’
’Òú
RP,ZMŠq3µ-2¢›ş è(ÛÑ¿•¬ÑôivÁ•	/ÁhR
ñ­K¬Òr¾ø[óºnK¸/Ş9Û½ïÓK¨rÛ1VîîQ¨Z
ä§>¥" –µí—JmÒ
¹†¸+´8¢UŸë2§Ç…œ`Ml»‡á¿ú6j/”²ËDçÅWPgäbHªŞy±ëí&;aLx0
Å[¼À4'ö¢—Ù±Ò„Æ3¡ :¾4ûJî¾Æ¯±¹Â"°æ_¥Rò“NÍìEYNÂGğş,ìVwPíº†"*ÕğõA|6mThŠ&?¨0¹!é†c˜Öúƒ¸´ûÉh´?°‡à³0‹.#İÃân{ò s$}»›õä'† x†P0àƒ°R´ñ¥ÜLûä½8÷j©=%•¹$àí¬Ê£p¨Râ&×3Š„wë€­Ä”~n]¥Jjï9„Œ–Ú)ç¾qôœ¤İ]Ş5Âz%»WÎÕÖK6¯ù]^©0q79Ò˜Ñ¬BGcè_c¬N¡ïVÀ½‡IßèP•©úÌíë>: »¦#€d›2Ç9ß»W”¡`¶Írê
p@ìELÿ Ñù¦ñ@€ÙÌŞíşºï½“ÑılšècÆeÉ‹ì‹q.”×KÍƒ±º„A0nœ¦øºÜO×Ï9‰\ßàâl.N¢©í‰­r¸‚D2¨İÇÛ ]<Şy±ŒeÆnQN`†µOh¥)ø$
ïùsöÛ>2×ñbh¥¼«¥ u09'¶V±ÍxìøÔm²¾NóÒs‹fÈ	¼ö˜¹€/İ;	Â£3ÚIEıE¨>òÖA·RWFì‚Æv€%õ¥áW¬Í:`d	£àÍŸË°'ÎÑËÑvE>˜0îreGİóç„¹DüÛŠZPœIK÷€„¯¹ˆ­²I?6¬ƒq`•:B4†ğ˜(øe…ªŸB†Šn4T{ê;-¯I»êeXú ûy˜ób®ˆ^¶Ø9âBò¢~¢!VE;"¡Ûq!ğ`F‹¨Ğ=ÇÙc©Î×÷gWÉ2“oH†X&Ûìpä÷£H¯éRóDİ¡èv¼T*+j_k¢@³b¿Kû1µŠêß(7×û¯hsüùu<pÉ$³@'„ä’Óä@S*7@Y›BW¹úÊ£W™¤+EbclpÌ€çNâÎÂETN•K”† w¿ÏÔ9ÏëñFŞ³³V6X­R4ÒG2Nƒ×Nz[G’ˆaàÏ&Ê‘àxŞü®÷³O²Á[@Ye`¬kM<ƒş{İŸğoœmÆ»@Ò0u+áï\Cyg}*íE²ÁxÌÓÃà“%÷¨zÔÁñÒŸºrš‘	ªˆ\üÍ{^D½1—^#øî²l­ôŒkÎ!n}†—ä#²å¿ ¾«©’,nÎŒÂ”oú…‚nfÀOÂîÖ÷.×©H;Nˆ:¬Â¬8f	w×Ù‰òÖù¥bƒ†²é§!×íâ¾‘Oôz˜'V×™g:ñËó2õK…ö öâ şi³¬ˆõïq¥¿˜Ó—gÙjÒXÄH&KBû%]ã{9BÔ#4Û¦Tœ®ğ¹uæ€baügSí8R¨Î®~«&r>í-“•n¾s~›<²«²w Éê’Æ¡›½mAm£•g_¦ŞÃÆ‘_ë©¤rŒ8½a(
®÷ AÊ9 ‘¥…Ÿ]æ‘8ˆîùk?2poŠnçïy
×Ù×"XõÓèkÖjô—v¨ l†AxÂ¼b† 	Ø¯>2mÂ—:fíÙÂú-A¢İÍoGê3Ğå#LóO,e!;Î¢Û³oëİXV™	ºÂìŠoÿ9Oø@Ói«& ÒüxÂ•Íµ½ÿ×Ë…^`òû£¥§‘Ï-®Ü„¼bd+şÒ+&8‘Y øÄ‘ë}±@®T nf~€HË»”ÃêEÃà#._pú}|wÀwB?Ké_[)\íÅú‡»•Ê´y¤o9ôÒcWlWÚ*±A:YÀ`ª¿º¦œæ„Å%I æ•ár…eÑ¾ŒZ×—§ÆY3 |GkN€(°Ú¾?Öne…*z&`¿¿D+'Äë6k+~¡EzFé˜ú:ğcı‡–yõ£Br2Íå1Ó«‚Ù{æQÿ\-Wóq5¦íÎæ»²×)˜0q„ô2ôA¾¡å=ÿÀ¹|+k¦:(‚Ô?,ÎYñV+¹öÇ0;í_KVqX2å,$!•kH Í2|£…Ìy±L±fmy…çÚ·ˆüpÚŞÿÏò-„T'nO¸z¦@¦;	›làqésMŸÊ;Æ&Ço0EMê}]ƒLåyGÉ½z˜ÙÌX}£ ëşOQ>(šŞF˜u)‘-×È6³nÊí ¯"ØÜröĞU÷||†ØÅ,FmèIw×³î6Êpp S-ös¹T"To¯K«§G¢Ç6é«ùD ›G³Ö'õK"ª À¡5nJm€¤B¹¨'Ÿ—K[Çø¡!À!Tq€Wz!q£¦*‚ª!z«ç¤†B%î÷0ÄÀ“ì±ØŞ™‚—ünM6õz›{çÛ
=-@¾—ºwsÌ9>]™”²s%öKÉÍœ¡sªß¡eİJ]†¸{Òn'İÚa8çïxU¼fÔ‘fVP®í…mVRpäğÊ×Ä™D½ô9ôCÂÈa¯­/	¯ßÖîFëa`?€ëFß¯UMaßÎ~$”åûû†76Ä>‘v_«°ŞB(ø©T># ¸"àrĞ°¬×âŠ!Ùšî8Š‘Áœi‚ë8ç‚4#Ò¿YË8„Í"–+Ñ+íŠÈfİëU pÛø>:²aÂnK¾Ÿ Ïİ5Ğ–Nsœ|3z_j­ã»}ãJ¬Beâ­=z5"ë2>66‰y‚&FšÑ´‘ª·yhqÒwv`án­3’U†Š‡@Vpï>ÍYy²ıf€¦èc(n).ø Böò±!œ€q Õå÷~ğ‘Á#(i»–qêıEÖìÈ†2æ7‡~ÂbP?ôé@ò£“²Ÿ%L,ÌYJ˜‚@/ÑŒˆšnJÜ†5ÆnÂ17¾§ŞqxLÀA²7€‹jÂ«ZBÃ„úìlv§5>}·‰gø+/¥°úì}Å•Mà¢yÚR/É õ[5«“ÇI+·…Òú"©ĞVr˜Î¤…”ã½³·7‚ëÏ4†½zÜáeGÑ.äê¤Â	«½Í¤4‹ÀK[ÎÍçN_ÃR¶1"ÉÜ˜$*÷vĞ§N¬vQÓğZHDCİr›CiwY¸Lê2ºÚEÊB²íöUl2~iå ”t?íSĞõ$^9¡ı˜HH8ùÇêA¡È&€rR"í@t—b{b‘DMLö ‘*¦Œ*ƒ;Í@İ­Ö²oœÔ‘m{Ş”Ù…nÆÓ¸·ÔWV|…6üóİsĞ=³g¥n€¹])½@]Øƒ6û¾.>jæçƒâşS´Øv‰t…rĞÂM±B04ê< ¦Ï´± œ©÷w¤È‚<
„UmóPÉqÂ²¡ØÇ	Ã~Y,0…šzÁ¨(cƒë^Ğ7¥]Æ¦`L»v»•*\TTÂ7øPÔ=òÑ~†$‘d‰š‚ñ¬r,Ùdvk‘~,aæƒ¶ãìæCø„¹ãF+j°”ìÖ1İ
'Šƒ³ş/ã2Eã}ÁsÑS­`SÆ2ÚfPÂkåºÅ@4(JëÔû‘kWo0®ÍY8ì¹€ğ·®ooT	|#D]äG‡8¸T¼ÀjÛtñ¿ü­óßò´ÉF
³a„(µn¸½5ö¹ùsç®ğxî(±yŞó_óİ¢å05¥z`œn Ó: y»!^±¶C¡ÜN”¡çUŸWÖõ¦ÏO´Yø¯ÆMÄf+;¿­ÈÉŸzÊÊ+W çZ%+m+ı–æô8µÖW&X¿†\ö|hO)Â÷ëà5…%cKymø+ÕÆ»@Œ>švã¾Ü8›kÈnË„¬GuæŞ®1ıF.^¨¤#9İ{:É/”‚A@á›Vn›»îg:
Pz¬à_všQ™ªs®ÅçRVê@È)r/}šL2£ùÃxğk¸ÎĞª«4ÄrÊÌ1 Œ›õ¬+¿4wªúÛ…=9@o‘‘Şh:¢(ND–•h¸ì%ó@eÊ<ÄJ°q'·ïğÀ²@Á2¿…9Éæs¹†ª2ı[ç‘_’…ÃÔ{ç_ò(ĞéS§¬8“C¾ğ?„§Ñ4Œ¤Ôv
ñ~Ò?0àÕİGú.³«%”’¢ë­Ş*z9KFDÌgPÌÇãAf:tRe1¶ËÔ©tËÆ^WÓ<¼£L§hŒüÿ×÷æ¡*LÔ“±„ÚvÈòëÚã`ÚH}‹$æA»yWk'K¸œ¯V¶úı#…x´(ßæ}%lpä `<T<CœL+¬K¨Å 5e0P´ñP²ca‹ìtïíe“éøav¨“=¥5n9®§]µPÙ;¯dÄÀ8«éËDåÄ†ca9z7ÅfÔ¼©›²ÚF(ZÍ¾¾‘½V2ûL]Ó¡qóÀX©ø†˜ÛÜÆ›L3»·÷ög}w¨˜á Ò3¡èÍ´§äŠ‰cĞ Yœ-–ò´C£cÙ"3yÖÚùUÃaW5×í‹û¿‡Œw“Èµ8·O›3X|¼UÍÆ)cûĞ‹›&uÕÍšÂÛğ0´émÀ83cs¼åìÄx5=ZVL|Ñ+	á´ö^¯oo\?“{ĞãK~y(9Š¸BOKJ÷è]@,ylH•ö8~ œıChÖ%§%s³÷­R´¸¼W¶ª
UŒe÷¹UJy‰;¹|‹X‹#'!ÀÛÖbFã·­/JXÃ¾ ´Ó¿ñ)€d»1I–iòkâå8,…l"´©LOè1æJ¬²sªÈ5Y@6éŸå6\ ÒS…İÔ&ÈåÁ$n¤ƒİáBùƒ«wAEÓcx”D.À~ßÄÃØ^ƒQ™!Cšn½b”,¿>~šÎÒ}ôTß÷¾Cxº"ô–û:ıİéÚ¿Rogœ Ê"+:Ñvû9·’<¡Äs6,ò\9éøÿª)‹‹v‚O–FèU«;:µï†å¦Åc¸§¤èdl€ørÔ'Yì±ú^lÄ€ãÇOÌŞIeŸ,ê
…Gı‚—îÈİòÀ©T”(Õúoè-×7·Úá˜ä"h¡µ°,ï[HÚÖ9L.vét¬\Ìcª`;ÉSÊéØ*¨İ·•v¤^Q ÍÎaZøìÚ†Á®€RÍpísmÑtuƒìÒ'È¯Úå!‰H(ÍG/•ÚaÓ5ò‚L09£ÂâÅÛº‚™n“ÊV&Ô]¦~­Mh*nM«İ&EmªRDôô¯@·ÖÇúØ ® Â#hßî3qP)Ó(÷ôHtÑÍhÄöáõt;R’x‚lëoî`[¨ âÏÂÍğœœ˜‚§ê2ä‡EÏí³¬Ò|IÈV‚í=sCÌĞ™•»Ì%Ñ9ÒßğˆRdªN©ÉrH¿–Bf“=öç”¿Ò0cğH,QÏò×Ö¥%CO3i¼Ã¥z.ä1Üø¬_•™‰Û"¡tº}š¬É¹*q¡²>²«â÷€b1!'ÿ°öPÁr´ëÓcpÁsì'T>OBì6!‘9\,F{˜øŠ‡(l“Òá—ï?ui;{«½½Q)Şu„ŞJ4š, î ×üĞBÓ£Ló÷z6œx*\ÊƒÅ/”ª¡»‹>âôĞ›X	çz—[ÿÆŸïò&Ãp§
Dı<*ô—›[òŞ¬SĞ4-û€€@;T§«á4¶82È>şN?Í†Ydj²3§ßçKÔåÍ
ÍÑæËZÂÛ–ÍÍwxdËêZËU²ş_‰òÈòŠWkÎ4 téuÙ8±f/ƒTzz«8®4#úêÈM.nÀÀ»¬Y-,ôÈ3nåíãi-ùŞBz#sşß7%VÎ:ÚBmšI|/”Åš‘ÔíØ°¸Í½hòd¥skõã"Ø‰s%rü£]qa*Ú™|Ï¡½M§mÁĞ5ˆzXHo/½ıïŸõ¢ˆùs7í±~šññşC…9‹ëŠÍî#¤ã+p¹®g€U“`Àºi}xÖSıuLÙÏğÇğE€6Kİô)¦¯_g“c…á“ëø¹Eü/eÿ8ÚÊÛßDZjôóê‡²ğD®BƒS‹¶Úàæb ­ºÙ9y‘¦rµ$£ú/ªŒïsºØ €>€¸_®î®I†ÊÀŒ}Wçhz#«L>µ=×˜‰p+¼Û[°ÜFQf(®/î·[XW^Ågõhêf+gç‡á"‡x\¡ÈQZ|+=†.“ş–¨ã¿¡Y qiûá¼Ùº+Ó@0¦JÇ,&Y/{R°U^ìú%ú{‡h²”‡†‹î`'#ÖXogº$œØ0Õ¿
øû%3.eàV­QìfWH_ÏäQ74`ÄÇµr¯ş2Ø|[@»_©«¬U‡€<Á³Óñ*‡&}sÀ„tsˆ‹42*¼qµÍÆû§´‘ØÅ§Ïé[‘ÀğE&6ò»ø§ÛácVÒâ‹7Õ’pÔÀˆC-oğKøÎh~G&YH	®¿¼]k–Gr¶Aé5A€ÙÓ·|•jÖÙî¹ı½96C¨ îê4ƒfıúU*%š#NÓÍ43x/	vtœ/}c85 ¡-”×imhBJ§Ûˆ…osw±5lÅîmÄŸ	ÿkêº—èÈŠ x¹«§¢!ïµzˆİ·sWg¹.İ_¹–ëB}±î§ÒëÇìÆa<íg‹£!`;„PØSÅÏUo@¯y2ä°Û³eÌe]Ë¸Íš„{pÀQ!‰Rd á|¯ÌÖ‚”¿c¤ƒ¢®šó•…rıMéÔu2I¿Ej“J<-qŒ 5ò¹äZ–.É¹ñÌ­®¿v%ô<·m:=ôÓ—´…y¾™{x¯zDR˜NjjÑ¨c,ßìù
­ …ğTªi?Bğ›'l!Œâ'Â.Êo+÷Í¸ò	-ù¡A(‘*u½ë‚š(4ÆÅ1sğ?²*›­%enl.c!y»Ø LoéYiaÏˆÍ5è }ı'ü zçÚÇZ
eË dÜ«%>GM}`¦]ˆ€	hÔ¿‘W©º G±Êßd†ÉøÑ¦r,ä"â’şïİĞ(1Ò ˜ôûl§˜ƒÄT,n7¸”?­f°½¥l¿ö¥U«PLLo/+»?àz‹€{’‡àK¹{óaû‰$×ëû+Æ:§§¢7RwÆŞQ€RÕ{Ï+±:ä è_9w½Cî;B?…¯û,-Jşğï"!«4%o°·L|’îV¯^(0nŠ2ÌshòÌ„‰£÷”-læEòœHRó\Q/½EíFé4ş/lB¿"€ú-ô[Ú®*fœ¾<€ìA÷ÜèjBŒké¸ÎÚ—E~*.¡˜ùú­–ˆÃ¨×‘¿„¶/¸ùwûlñå{13{ÆÃmoÀıòPV¾VPšÇ[âV,w}©ÖÇè(Şè_ÏEvÅëlZçMVWiÌZvê”³¡=TZİ
¯öIù,(HmëËöÅgÓlšN³?l“ÀÆÄŸ½p[/`x&rº›ƒZÎEª‹ÚPSP¼şì»“¥ó´ùÌ‘c¡FË0q.âŒ¸Ëo©cÒ²ÈòW	 
¼DµÚ:b»!'Acr"r·G×kCßšûÚãeê³8sevÙŒºL-»n·u„>œPZzâ	` Ê|Œ}kp”É*Ã#†-®©'Ó0…¿2DºŞ5V#^RÚ¿XS”2p}%SÌŞNm„Õäøì_»I]¼ÿâ†óôâ ”¨FU3ÁöÀÛnà%?ê=‹Ï¯äïüÌVXÛ¹ä}X’ì€†‹7ÔuüÊnºò[OïÅòHîmı	ğ‰çõ„“ó³(eµhf;F€‡şæ÷êƒ"˜^áäj´·1t@=ÎÎg!ª¶şK$@ñÜóüVóy×€ÀmÒkK[Mî«Ğü=3¥¤ùñL’å{w±1É©Õ-NBÎ%S2ĞvsŞ PYüÅNsìÅÕ¿	?K‘ñ»»x¬¶›Ãi4Ì-s™j\İE¯<”áålœ…‚¢,n’	œcú¾m”e´ó6/oàñ9/|°ãÍ€ş©j4—›ÂµŠ NÔŠú 7®äŸÑÜ­İO“:¡-5¡®â øz&÷Ô7™:…Òf†±óømg>àí–"®gécşf<ÖgÕw`!ï_Ùpw„–şíš»¾'´p{T:‰œÕvTc¤‘z£h„˜ ¥cOğÓƒx‹ğØ¯éMFWõ+Àe¬¸©¦G©FÂö e“–4V]œ´$èõ-¶ãZDâ[ÏÍì-	`Z—Èõ®ø¹¨Ìè‹IATŒŞĞçVø³jMÜÀcëšpÔ&§5Şìgˆxv{lçıË#$ğhaÏ–îÔª.0j9éÒäÔ1(f£úOGá<GQ†N Ÿ‹+5Ã…1úK»ªğ=_'æÀßõDqÙ_`ÊTù  FÓ¢àƒÕ˜-{£–\$g}a{°ÊL^»ÀgIıy>ìAòÀ²zÊ0İ,Djá£=™j$ÿ~3;k	ıÍˆW&¸Şæ&Ç
ÏÚ¥şú†ñJ†B.Ÿ“Ì¦¥½U6	9v	¼'Á”¼>°A«.ÎÆXeè<võÔŸ[€ÑhÔñ¾ûÒÈ7H2¿™oªª]Vàî}à\LsN¾›ŠküšTÕHpIL®
LïoÀ¼l–¤äá©*c‹UZÁ>C_+E/‰}ñZ>®fiw4åĞ-ènœåˆöÅû$Ô5èŞÉiLuÊïLñà<8É¶¸(è¹šH‡'HI¯’¹KıäÉ!5dæcÀ½Àÿd/¡é,¿g²½abõ-A…|K[±>±Rµ‘£p&°C¼ñåÁ—ÿm‹¬ŸPf<=S(X~K5¬ù¡iw!®ß¦Áxb½÷¡V…2a»ÍGP›k>·RÓ–BíŠÜû·qËD
[µ 
./]¬Šı²äiËîêJ…¤·œ'åÌíÔj4ÈF+¬ôyÎÙ²;T=û‘—ßÔKJç+åıÛÀİñïÊù¹ˆ]G&Õ ,}3ËkaòxÑÆz™‚ü“íæ÷û­*o†ë§»’ÒOÃ÷WuG–3v±€Ï	 éÕg”y®ú%ºÂ8%¦ø#_çqÄ9òç;ˆc´¢ı°›ÿíT6<?¡³î†+—Së°(³3?L°#%Š S}®œÅşğ:+Ô.ŒßÇ¿Îà7„FE¥àÓP,·OØÇÄ³¶¶¾ËZ¬q'ÅÉÇYŠ™ÄO…zhàÛ]™×Ìk–qÀë}®!g(Ù·Ò°WÄ+°q™˜.0[bä«xçñÙ+ıH¹çŠYŒ·Ö¸™šbT;oØÛJó¨_{%õ:™è¹.Ìnæ¤Ø5··Ğ*ìº?œ
ïj PeíÕëH\èØ[tÆ6Ÿˆ²“{ÑÆé¿·ík)fçØ kÏX·ğÁœ£)ÉIjrËy?Å–â"¤–».¤Sü++¶çÌš_zŞ.Ë¶[<3¼lfäOZ@ã18Ñ{3/niá!w¿õt/—r˜Sf³Ÿ›í Aàq}ĞVæÔùY;f”İuBIÓ‰›¸`}ÂsÅÚYš' sK]Ğäi„‰eÜÀ‘Ÿ²†£‹PĞà¾é‰=sœ©íU@VÇPvíÂ@È^¿Ä7+áÏ—[GT’[iŒ‘Ó¼¹``·XXsÉ®sŠNMìV…‹Bà *d²Õ€ï3¿½^
³%E[?‚Zßiª™”6c†F¨:è¦$şiÈá	µí:§

Z±¿"@â³‰œ&ôï+é55J$oOÚïLzc9å@tÌÓvğs±K!ùÌä $Ÿ ï¯¼Y@zÕ3z±Â­å³Yêê"uLßÍ¦…"9ÛkîÏã’Ÿá<À!Ù.°SÈÄ#&jë4+µÿòt+oa@Ğ¨+abù'îûIxóÊÑ°ÙSÈâsš}¯}0X²<ù¥f€LŠ¢~¾ˆkjäÂåã‘ª…î|ªÑ¨È¥wû'2no5ÓBª$$´¶&[}åColµT³—ßg£êÊÚ§ ş³ƒKkªYµÙa×åM-§sp³ğ“”¦â	2ãTKƒ+“Ùš½QäÛ¹®Yô Gƒ¶Ñÿa*Š¤
M–ÆŠŠX;–\ÆnŸDbÈ¨b¿p;CµXHv¨ì/HÆ­p²U¼Ÿ›é8ŸRÛ±nh÷\;&]ÀÄT©•u-0ôq>Ö´‘UßüÉæ©¼`DÙë¯(5ÃºVg	{äÖqv­­y˜>WP›nÚ+˜÷ˆY„ASü*Kñ ÆÈÛtØuƒšÓQİÂîUÜ™†6_½0ÖË•’Ó=c¶C[.K›ø±¶ü9C¼|CË~"Jİ%º»?ÉÅ²RĞ^—CTÜ¾ó Ãş-ÒzBÆw6[Ï‹ í¥¤5xy
U‘V=ÉÓKkaZèŒ‡·ª•¾*ªvûr¶ïDÕ"#Û'BŒ³v~rCß°AS( ‡Ü$+©D¤Gâ3ÿùW×{¡à$s,/ß™¨C·"<ßÙjR€ ÑÄdŠUƒ•ı!­2cöSùC€ê 0æ$0“Çµó©k“3{ÌÙËCm»!ØÜ=ıx{0Æ²½+jÃ¾j/ŠéÏïDuË\@®Âš”â‚Mì/7›ñ@-9AÌáÖg>r†Ò¶¶â|Ş~'ˆáü¤èDù“>Ëny2VG¿7?‘2	|½~è.|€‡z«WºƒDgõ$4&`üØI÷´ó©iÃ¿İ½øœÀTY¶«–¸ñuŒBÇù
iĞŸÃBdSı±(Òš2pƒ)dM¶>	ÉŞ[3ÇMõÒL‡í-•>›â{ãælu˜ç¸ÙºŠ_€Ë'›!ŒWT–l¿3CBøéë€¯ıƒs­Í_v M+úY24c”¤8+q¤Ò‚Ë·:ân¢“9éÆh¥”*ÌÿQTàNpp%eÛ&låå-”%*ßD„V*÷Ó* a'ÕØÓ üã¯§úçÛÎ5~vE*üunb¿Ï„|ì5 W1!<Û Tg‹ü©Ñïz&ƒ–+knF¾T*Şµ‰†Mv¦ëéGİX:Yûjå	ÍªÊH [²û…—Ó±•¥7Á½b’÷€QçínNhÖ˜ªDTGh5ÛÓ,÷àhwBîe˜ÈA>=h‡ºÛõÆŒOÅ	€ı¢NQBôª’Èÿ5£‹ÅH%‘Ù7¯~t5°L§ĞVÊ§¾úä?Fã }!’£Û’±IÃşQ1Ş§¶xùƒ™ ™Ù‰ÿVdykú'ìd|ô^ .|–˜/Ãš©,¦Ÿ‹Øñ{fŞO„Ñgµ>çE8~²Ùûf¨l]8îiUÀâ \{«§Cqd7?å¾ìÅÔ(ğdÕ‡×ò}Î~)ÆæØi1ñLI9:tÛntíè°m»kÑJ\a=cA@¤Y?ƒÛ·ìŸkFÉ¼©¥”C;ÒÓ#ñê²õl2Ó ëU¶OL›l°­2u¨^:g¿K¡_&[7Å=¤BéÏ¯UË;KĞÎá90¾ù6)§¦¸qFî™*;O@2}¶WàÜ*b-fBÜ¨Óy·;Ë×€/:åY7BË ı¶L<x|²A”·¬“ñ±‹ù{Fd¯øAËS7yûJ6	k@t-ùfş·—¾âÃıº¬.²‹¡³Ş7±n[ËÇO™Ñ¥R òe¼äiŸ¿{vË†[`g3ãx_İ%üp€ÌÌ'¯I¡:ª9#/ñÕ·ı1ßt™ÌÁ°¨ˆÄÖià0[½S•ìirW¾¬XÎğÂ\æ%.5©Î–.˜ÍFßÕÕStè‰»¯Òîé“û¿ Í#vC¹Î3ˆODhÎ(Ö£›Ö­Ã"‘ÃMÿÉ"íä¤Qk¯ï3ƒ	A—èi%wÔÃ,jy¥‡›†ô¡FÆvvşGcû·ÜMG%å:ûË¥¸údÔ¡H—‚^2\ŞeÎÜ6Ã³A”ÛL>´ÒÁ»p'pI6nÄ Ô@XE¹¡'Wÿ•P,b.¼˜ü=a0˜“qyâ¸]šáQ[Á¯|YÖa~sşy	>ˆ¤Ò¾£¦Š“/¨Ô:ÿÄjyûòã	»c>/e7şlpZT5sêğHg^ƒÕ'Y¼s	JŸÌ…\t]°ø`“ÓêçññÍ¬b€B{J×_+¤€Læc_YŸ\åĞÓ<7QÜ¶—yPcæ”D0;ÈÌ.Ì¼;~‘Ãs¤wû8›;£ıH‚üa¹–šUg¯Åâğ€ê›$ê'&İİ‡Ÿ@Jt€¯K ˜ˆÕ
 ögæ;Xïì“eÜP•l`Ì'5·˜®!Vã¶Cç«¢¾jÖŒİOÀ°İtÍL7oÜ—äûA,¹:İ·v…ñãİ®Ò—“é;ÛÇ’¡Éø¿Nù-ò­[€¡NšŸ¤Écú5€¼î‡ûJƒÂnüAùıPªoÏ0‹‘Ã˜ñ°“‘šF n6¤şkÀ§€Ñ‘Ìz‚l´(jÔî,Gö5L	‹Zô#»Í"^}v.4ŸKææ…êÚÓ[.Y©Ş°Ä iZÅy6A%ë>]ß(ÌŸ´ö&b0É!›úÉQëû"3³ãËÃ±h­€8ÑÿÒUJ»]ô×¸z$ùìèşæò^˜ûLRw¶°5Ày—ÏgÜ}¬‡ ¯næÉ•A;·£Ö+Ùß¥+mc[Yê ìÍËÂÉpÎÅj‹ÍáR‡`ÛNnB¶œÕº:ÁõÔ¥2àíõ+6 Üx%LG\Ù§ñºwğHŠ»é%;íÌ6C2ƒºßÛ\¶]´wä¾S\
ÍBŒÿ°v d=İ˜90´™ÚFš(Ã¯ë?ö•”2Ôÿ4“a˜òx‚Ã–69‰ ôÚÔ’m5÷:?ZŒò>‹×mdĞ$şè¸ó…·!˜ÜpKû,Ü?ô–ö‰Á#.9sÈÀíF¨/ù"…XñÄÍ˜/"•¾¢¡[;ĞÊOë¬’|§g}¸~¢ÌĞÙƒ<XGÅü<ã6Ã•*Xn’Ø˜V5?ÈP¼†ÌæA>Åh¨ßKM!ìaè^™àû'û§¸»Æ?GØÍåŸ[-~¬7?áU"Gôeâ–¢¹jsŸC:Òhİ¾k_;şIÎæŞğ4Oıvœ?ë6C`à ?vlœuµãµp™å‘v 7Æèäûa}	=‰‰)‹×®µùOÍ9Ì¢)Îè=ÆCÿ—Ô_!§p€;I.§2i¨×ßwY`êZ¬E¿¼„ó¨ğKüw=#-ehtÂÀ®VP›-)5‚2}L¬{Š¬Í~şoåLaA¼(: &ÀywÌÖ)-ñq_ÎµÉÃ&ò¿G.bi
á“RÑ·Õšç)¶~¯³]À}q¨Ï´ÈÛ²&|á˜í´%êr‘>2	Çrïí’†p–Øîv[}ÊKÇmX°Í²0vÃWjwM,-ø¤dU17bÒ"Î½ôªVÌ»Û†}O^”g–˜’zİŒ—Ö‡³ö¾÷ğU"9ÅÜ“Õ#«.DnÂ]©542N“êu>®+€ng¤e*›¡—#»¡Á'ªèŸ7(¢²síÒUÃÒpáh#âlpêFøÑn<¿uÌs¾tö2áäµ~@Ó“öå¬qf'¬Š$)»‚4õHßDxÓğ;·Š¢KTkÓÕ3ãÑ,cVçêµT#Î!çêpÇĞ}¬À6Âl-Ğ•ÙWÎ>=Ş,|/yÿê:¢ä£ÔÓí¨ß^»LZ¶ño”ˆÒç~åj­¥"h/ãµé]Paåk• ÿ-‡Œ iÍwSâ'ŸG)éÇ´/0†_}Ê³êÀèt¨>óøDKä ú(¦t\5¨’çğ~dS¢Ó‹èeZõç˜M*ÍTáFQ7JtÛRVHP'‘®êê¡÷y\rÕCÕa8—¡ÎÁ5,†ÿ‡ ªòFP£zŞ±M¦ÒÖ¤o?Õë–>Ãn…µY¶	EòË°—
Ø™óï]œ	3&ßBUa¥@Ï}ÂÚÑÌ°ƒ6ht èÃ½#,ÑuÚ{oÆPPùô;­7¸Ş™Å<ì Ä&×9<^¡¾".+AØCoh-Z —éBu´g«)	P¥PŒº ½[…2“²š„GfıçJa•é~¼º¾õéMßlx4&ÚjÊ-Ñ‹k@Úwm8$
·ñ«æŠ¬„Îyñå©BÉEİg³b|›2‘¢u—¿X–K"j5%«”%%5~@ÁÓÜB–ÙwZím÷Zµ¼‹kÒ]£ ±«Çşæõl~ø“zfœÜlÈ­O±Œò€‡iˆõÍ%S –E7CƒÜıp¦GR!nŒ0=	Ÿä‰Ğ‰K+gŒ©›m‹Âg…÷›º:"òyÛ*u%àÊ!uWóx'i~!.v¬¸%E¡gOš!ú-ó@›«¸ŸN&_ÔóÛ²¥ÿ¹KïîÑ¢¸İõñı-MêO—™œlK0ü—z‰´4¹'ãÃ­l˜44Îrñ¦x…h<@}¤F¶°€İM !›—ç±ª¿°¡¢çØ6€r«®tŒrFáÙÕÎPÇcÔRœÉsó 	Š?rTÎ²gö‹R†£ï^şgÀrÂ}˜”ıv#šÇÊß>æ	QÃ$òÈpŠ=.sê*ç¸ğü‘àÇ[6&YıĞgÔNÿvä‹v„—m-¾M‹\Bä*á?WŸënûÇŒÂĞ7ëCÜ‹ÕR©R!”ÔPºÃ2ğgú`Ü(«§«¸ú³’Úœ÷y¦¹Wİ‚•ŠHîª>ëİtJ\ù;©ùÛ™À¸-V8´FqA­½’7öŸxÏ&ØE:«`èJ3 æq‘Hê×IX±+¸½¼L¼Z,Ùº1Üˆs‡6E¸|ÿyôªªÛ¨×åH%°Ä´º?®RawªP[\½ÜÄØ~ìCµ¬º'FLÙÒùÍ°‚N•-]B×¡ˆBKÓM	Ñcæ…¦Éö×IÓX»†Ëá]*è)‹Òö(İk¢xJà§1¶q0f¹Ô£L×h‘Œ*‹‘à7yZ&Ö¼9D"Şºå¯„ÎÊĞß.Ë…Cg/GpC—ÃÇØ"k£¤µì1Í> Uİ³æñ-zIÛQ,ïÄ™ 'ÖâjÍx[ù6Uù§>$"Óæ€A¤éûÒ©­~;ubè-Qí±]½Ã=ÇtÀ*Ã×r—Û!z·º/›‰y6å
\øZ¤ÜH¨öMaº¿&P%û²"‹í+  ì¾®ÆÀL*
J–XÁÕÃ»kEtòç0ˆ×™Öy÷pÀˆÙ_-ZoJD¢óÓÇxõßíFn?ºç\ ‹÷—„-òRcÀÓ¾ñ21ÛáÒíÇ®“…ê®ŒkB¡Ò	„Œ'¬Ğ±b‰›1Špúä|„ÆC°Ãï¤xñ•èSbC|K«iif30Ä1u_VŞ¾%»½ÁPûÃ£éeæG¶yÑjL¬ËYr{î)öNwÇ‹ğ4]iD­à„åĞî¹‡3©P·N‚u}ÜsÎ¬Êsp äÖÊfÛˆ®S§@]ùÉpó‡%›úƒí·ó¢YÁ¬:òÙò	„”õŞ„ùKtw%h¶»öõy#Øà|	-€ÛyEH{1Ii÷ş!ÜK+b+lİy_p+ø™¹"etÒşxö]¨ØD¹z¹°~}ˆJOSST…ÒĞY/rS¬Ñ@ÆO1æ{Ë4®oäâµ„ÊÛŸÿĞEWy	XİLyÂôØláÛİà¦+\¥ŒéĞ1¯5ƒ6\wÀ½qbTYŠ6Ã£áÁùZIQˆŸi‚ÍÍà+¹–Áo.nn±õ±Ğ
ì3)oƒoS³)ùËd~Ê‡OZöÊ€„u	u³ÿNNÙgÏ8XğùàÿÍœş®,Ë–UoÜ¿Œ¨¦5o¥D`–úbÀÂgp:v»=Û²9yÑ‹‡t¯IqÇßÉT*p+&C›f„‰ÁkV”>)E±M	­€˜àÖŞƒèğ#§ü¡û¨IogÜĞ'Ò¹ëRf3·l€]ÉXb—õóÜ¹ØÍaäƒµ$*!”İ[özgš%»^»JJfdÃQ…ÏLŒb#æç„}Y Ñ¸ô-SâYÿRd%!b^%¶È¥ni¨ÀÃ›„rt¬Íç±—(VY|5_B1M¿›<¡±øMI[?‚~@lÎš˜›rµ÷şº­`°»—À°W|eƒ¾?Ì„áºØÛêqSŞ‚:2”. Ò4‰Gƒ•ã-×îM#“şøe¼ã»=$Qï¤n’c÷q°¨4<"Nx-_}µã@"î0ÇßèyFÍß_œ ìòÏÅØ4—{%æ©;*:ør>8Ì.ü:…É‚¿óŞu°¦2KHûƒ6^é³Dİ•ì‹ch¢rşu5VD[…VcÔÓ Od¨~s6ÒÊj îòˆCğİ.uF¿€‘M£Re4'22<d«Ú³ğœLÅH˜†~o|>3¥à·ÅåÎ½
M·zÀ
,¢Í('Äß€ŸÓJ#¶·¼-•ÖëÚ(İQ–óÚÁrl¬ñ,9f^ì¶’'SsJÕ{Üï°!İ°×¼´IŠ­M^ó‹†|¬R
»}»<nêŒÉCZ”ÌIb‹»\WeÃ§ä‚X¢)5Š·aiñTƒ¹)ÅgøğY¦¢÷Ñ›A„á ŒÍôª ºà¹4y ]}@öû1›à\GXZ&÷vÕIÌ
X±mÔ\ŞwĞØı§`Û\äª·B¥"Df†ÔÓ;@È­Ôg
º–ù`^){çB§ÇjCW,Ó³¼›÷Ø'gx£Ò&5óé\ètc†
Œ7XŒk®ÍÚõ±Úê¼6Y¿æ¦YïX·qæiƒ>sP“‰Ü*¦ZpX†hêï*K¼©ÍjŞˆïsÒÉ.O ö™…ò¬¦	,Û÷,£øÚE3Ì§¤¤8¡SŞ˜±ûO-0oefÕËÜO:^Ş£îtlqÖC¶ˆw©ãXÉã&şäÏuušÍUÛØ@'ˆQ¦Ïf€hGT„åÈyE	úB
ğeíâo€^À  ;Æêçœ‡ Èº€À¹fh±Ägû    YZ