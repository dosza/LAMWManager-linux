#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3127375848"
MD5="a9074805c53c3d430defb8826a77621b"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23964"
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
	echo Date of packaging: Tue Dec 14 00:09:07 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ][] ¼}•À1Dd]‡Á›PætİDõ!$ÕE¤ÇpHÄ,G•Ï¢gq¦L"4¨¯¥÷$3Z!h=¨¹15²uI£ä!uJ2X=ÅJ(}#ÿğwxAùæaÍmó¤4û®·RÒtôiMH­wø|Ë°"7Z—¬¥î ]sšNëÒ³â?	wç´ÊVÕ}˜fó—º	XkOÎ GöŒè£§L>€&hrê’Ÿ„{cÜjn´é½}ûÈ½xŞ#ÚfÓkœ¹lÅ¬#Jøîğ”³«ò‘öê¼NØ–ÄëÕâ-à„*¡Ê²ÑlÁI¹z.Åİô¯Ô»DwšôR…Ac;òFfçõh2l¥Û¦°fÑÑñ¿b•Sí1˜u±F²ş9”\­eÒfwúé8–¿}Kôò=ëbØ™ƒ[õ\},1•õ5+K§«>ºSya}åX·¾ètƒ‚{ıõB´Z#†„öï’Ş-P&+E«Œì3§jEô®²b¹/8Ó »H¥­eDÃL\'é¤Ë=$
HQBrSœM-mı ÓC2:òk!ÆöÉLó..o`0€‹ˆ³¡ùò±±ûäÉŸœŠ|:ì}WZ¦Aq§áº€9
§¦ö%Şá–õÎ:› ìA‚“„uéj$ü_8sL«‰.Ê)¯ì¨ÜHÍDÓÕ*JßÎ<°ò Uñùn2¥¾%X:-sÀhÿŠı@87A‘ïKuò(ˆİ’)–vi¦&7 "C»4Š»ÿÙüL¾Œ‰õ™ı\aš¸$~†/9©Ğ‹ƒ­ÿ€&çşçO§‰•ÈjœEÚ¯0CÆ/øˆëŒG_wF}©†qîîZZZ“iØ#}¶ğXd@+Ú§ès†GŠv"¦Ãø¬Ñô„ñƒ>ÀbàÆFVº©Ht€
àg¾êç¿	M
í¸ôºøIğWòRÖ™Ê!ƒÚÏ;ì{B¸&°Dó"# ÚXÂRÒN8”şuµzƒ“á,¯ƒwh1Bÿñô€AäÖ˜±‹Ò¥û4—sÍñz?¥òŒ‹—J’?2å}h¨w–“oY˜M
)9-LSüŠSÈ4}óÌ‚± ¦÷Ow5Š$k¤/Ë’.îı†ym÷iT	®ÃÒYó,gÂiúël…áX!GÍh„Ö“˜RZä¥%ORN÷p[û~™˜>èÿÓ
>l¸ş6kƒrÖ` Ø7Î°êœ›y‘‘ŸûÕ€¿bPİ;·oö¾í¦³«¹ö”=A¹Øá'Â§G¦i©i‡ÙYUˆ¹g®QĞno„úÓ¥{cÙ¾­HÇ§$°æ¦¯*z.ùı—f(êÕï‰œ±ÚVC‘{\`À¡‰®H*ËaÚ¹¥¦ë+kì	¨İ†Ñh.êx"C•¤¯¯òãRã¥–«¶;<á Z?û A­Ù2PÍpgu²Qî›(Éİô|gÙrôMıêÚÈ&§/üà×ï»¡H;c—±û(9_ôa€Ğt9Ò®•j ÁÛVf`	¸Ğ´TZc‘IİeücFK…PPÔŠ(	âCMĞäŠª}{ìï,œş¦·ÙõÛ~¼PXÍt™…›ú­¥´ÃkÑ éV“3ëÛ)­ÿl>n339vÓjZ‚d!íıu!ˆÒ~L¿ùÃngßd–¢8ìµs¾DB‚9°÷Ä>Š‡ùŒ|væş»ª°Ùª©.Æu¸Ä­¿x=ö!Ò|ï<øM‘v®K/¹Z{Ì=®&Ïvú_Xğ_9Â®=PöÀ+VÚ†”æ§iÿ«¿OÅy»%qZ’İY¶ØÀï§,Å} ÕccÀ9wÏ~m‹U& 4î_y
©	ƒÌ’£¸ıq)Œ#­M—ö$»h4kÄ‰bØD…ŠVNâçä¹ÊmŒ;Lœ­$ÏùuCâ¶EóÛ¿{‹	G	ˆäŒ×¼“¸’¾]°Ç†K>1Å$8@¡£
È¹³ìaåOTöK2ÕÇÎÒ-Öõ÷ÿ?^Ù9”é,É]™^y¯üèŸÊ 1gI4–$!;¶ãÛWúf×eº†4Z"‰Œñ {™Ë²~G—‚oä\ÄïvÓ+µ¤Û1UÒ	Œe1oÙ±küuË:ÏXæ#çv¦ÎOÔ´ıÔd¼”üq"FèúĞ0yîëœÆ…K8¦Ègk’ìªÊ,˜àµbš]‡˜<]Ñö®^ŞFİÒ–b/cÑWF—í†öŸ’_"™4´*›Ü¶vÍÔ­(É8-Ü^rx¤İåª´ÉQÿÏkÛÕeÅì«¥5¶f'Ûïzá$4¨õX	®³½8w ¿çÕŒı4É7EıS«›4e_·éåQµŸËAÆÂ<ô&'9ä6«ËFµ
?eñu- ‰ÀŸ6¡9_xSøŠH=Ò†•ƒ¢Ã•Ú!ZÌİtğ%‚€º¿!gød¿p×õ,Bèİ¥çÓD®ıü6´Ú0Ø•#îth›ápÏSšRÚiÆ^ùœÔ¥“FøWÆ	ü{ÿµ¢‰Ä»W,Ò¶^iñ¥†¯:é¨š4uÈ¸Ä„ê‡%i¶ægwRn ;mèå·”¸Kö:7éS@–¾Ğ¢ÿ8óR[•Æ¢ºjBİRÊ\§êC¶³óâJæäÊƒ*³>˜I_ƒ”üLï½¸€ ø€i“†æ^eB!ßÙ^M£8ã346A)¾Ã&·C¸;‡X,+	F<÷÷0óÑÃQ7²°ÖİG•©}q %ÜÚN°Iš¢®çÌP[¯_¨~:Ppmu­Ä'˜®ÕÆå3èªÖàóÁT±–§Êµ K÷CÂXÂ
"@6üEA.èåø¨Ä~ÜŒözìRM•ÎŠû»1)4G0"N¨•Ëµş\ƒV O£E3Ào5‚E†s‘R:[YCãÎQôLáÙC6L¾83	„ÇàEÍ›jp¾}å8#÷Øª0Á'†2Şr©PÄü¦xP’€ÔG¥+ÿpç“õ*â‚Xö~è‚4q-¨q~VG‘R!*±ñ‚íúhÑó™’êzm
hæÇKğ£—×È6*<3ÎšHÍJ¨\–¦sS%H£¹TİHW½Xº’íaÈ $ÕºGÆÿz¬b:âJÚß0ÿ¾îc<·ô¨)ú4ßÈÏìİ+RØŸõ4 "=™Kı3 …É‚ø¶tNá—MDìU£T¦÷	p[ÉVé=´¸‚VfÓ“ü¾ıì•jt;³†Û`#iwGXà–ğ­˜&££Î˜İÀc^¼\x(óÃ¯Ú{N™‡â×ÇÁèÖµ$küì%ë!Ÿ?‡Iª<sÌç¬ZdjÑ	»Æº‡`K°yœ’Êxmö•FÆ~«´Ğ´Ü±‡ï•PÓED™„í{8–
Ë–3$FAƒ~P^Ú¦6[*	?w¹¶Ğ\[’LC¤›§†…ÀrkÓÏ­æE3š#ë\ïÿ¾èó¿¬2ªÿ@“]îÍÎ”Œõ13Õb»äÁ.SËıÚHgõƒœşšÏ‰µ³ÌºêNDJ‘é§¶ÍF¼G¸Rw½]Ë =/YÔ9qzQ˜=¶|jh—==M3Ço_Ñ”ëMôÉxDlA“ß~:ó\i5jHÙ§'ióÈÛÌË_byèåÚŠhÛëÜf˜°¤C¥'t¡Ìà»Å[ŠÖ ùaà×cEÆü„CØov´ŸfÍ€Óº»IÔŒ¬°ãì®é`³B2	£=™
«Y›À€wWƒè{wVr³Lõ·T6©<b|Áf˜¹VëĞÊ7:ÚÅû6êLÏøÂnûõmŒø5„úFÀd¶ÇÓˆƒ¨j˜àA‡à6•Ø£S¯Dã±÷ÿ-úûQÇ\ğ
_­‘¹„ìåCûešNb!Ôğãù0cä~ü`¸±¶uÇÂ¦Ğe®JŸ]§İ^ràÍM“)õ ¬ªÛú¿^<yßw­)æ/=ÍC—1/±ì1g )V!~d†>…”:l¬L{ˆÒË†~‰‘õ'ûù/7=‡QOúu,ıL ¨~"¢ø0Û(æå‰ûÆ]™–îWÖòóŠ¨:|Å„¬ş€œéÆ@Y% ùM¢	?%)yG`ãx¼	p´Di¨pğwÇê’<0q"Zæ“ª¸È!îÓÃÃ;Orr˜ã¿œNë(œ®c¨;nH‘ §ÙWÚ]—¾lI®K6:ÏºÏë¨ÈëØLcşÙ	òèüAÒÕr˜"ºI{—°‘b9D”‘Xrìçİ­îs<aÜ:0»OÑ‘Jö'ÕçäSA8|@î)ı@Z 3å*±—Ş©İ–z¦!AF
ïÙ²òR«6Öˆõ3nÛÂ«|ÄA·RŒ0åskê´Ÿ_Êû.Äû¦ë\Ç:âT½L–ØeyçÍí¬FÔwø›¼Ë}Ï¤å~<µ¹yõó06vŠ]!8×ªÖº†¯ÿ›õ1jñÜàÁ?äÄ†Ç-±váŞzÔücD6Y£ûÅ½ÛÍEôİçXGo‡æ¹PÄMVpãCR Õtş#Éñ£muu|O%ÁÚˆ§ä¾@røûûƒø­XğİŠ¹oM³)}9Ğ4¸t{TÑ¨¿œÏ‹Ä—sÿÁšeS˜³DCœ5éÒ{'›X†E3Gäâ]õ)’‡\%h0|ÆYñJ³²ƒş/j]¡üŒHö¬lİ?üG*l¹GóÑå>nÒ ¹O€WÇ¼ö˜Ë„&Ôƒ¸Š*zíñQê¯v	x}ºsb‡\dA™gD0”üÔ3¤¸ŸvÃâŞJò!ó€Õäá³ã‚]!%wŸ:Á°šï3ÏG¦<äÓ½m{ô·-@!	5çáš„Î«{iä»WÇö7 Š@G2Å°“Ä^,Ã˜+uƒPå´á+Ú¯ŞÎ\vÚâuïuP‰´%–²œŠ9T¥éÜuÙÛ z×[›îÇßD$hã Øª/YEÃpùµÔãlûr{×‰{(œ¹OŒš–gmÁË•kÇş„·1ÿ#5NÉÂNùxö=…İ3¼r]rNˆıZ>’ôÎÂƒ'£HÖ ],.~n¯çHÄw8Plè+¸Cßø;7öDµW4e¸	‘ŠÛ×'f8-¹O@ğVíxVŞó¬"¤RÜºvÍŞòSî1Fßœ -Å·Æş¦Ú‡î‰Œ~à'\p_Ş½òşo†OR‡?!iÔÊx-ÓfÇaò¬µ6z)ñ§[ 5¶4‰YU=¯c»÷Éøt«è6ã÷ušÅ¸OŒÿø öÏr³,¡}ö\ _oO³PîÔàtdÖ¸oD8$#\Hr Gm˜ı½Å©?€›àAÅ:sğî‰7aÏÀÚó7Ôé¹S&Ã´º!ááeéöò)2Ôn»JÑ`Ö@ÑàPie¸×RZº™?Ì0Ú3öU›©š;øw¸\ªFIª`Ãè$©Ïï>Jx„µLVjçàpí)ièeé´ãœåÈh?îì3(x	Ê´+%…È„@IUWÃË(]È$‰k‡”.R²ÓZ	ó…“ùİO4'iåŠA>ä`€6‹}åJn3Ó™ïw¦¾ 6U:Ïtê{æÛF¹¯.U]q*-aHåw4ìWŞ‹ÇCTµ#CîqùFŞøÀú¡°Ô6FŞbÕ
Ó‚S³Œ=%£ğƒXìÀëÍG»eğR¯ñ8²Owfà;s¢Hõd„BdÜ'ªfÜ` ¦ÙTóÑÇÌúì%iìÔ³æĞñù\
ÉXlø?BĞ.+ìÜ+ÚÚY‘Ãw˜ÇR]î[S/ßñtíÈ¯ò™†ÛdÔ»¾riCœ0÷Ì¬µÄ¡˜ª)
”¡ŞÕ8ğº»¶[r¯]4èo›´¿¡m™U5ß±Ìgâ­-¶Ä+WÊ²c!üÃN%Ğ÷QæÃ²6J?Ôt}5íãoH'r>."¸|¬—}£ ˜"CÊBù%1 É}d–CRC¢ˆk½¬˜ ğ] ÒÎîY3¼¯˜ã§©ré²İÈı¡üÔô¯,Ì”4Íüjœ¨!±¿£W£‡*xñ¯œR~°“æ-½^2±C—˜·W#26FV—ïn‡êDEì-£ şİDôş‚(ŞŒI–|Ä·#š ]ú.ôWk'ù˜¾›3?!ıÅæ<ïø¢
Ú£wÜ{¦ÖÔŒ6ÊËÚšõÚ´zt“¯ŸÏ]7‘1‹äø]È’õ+`ÊæÈC”î^&í¶”˜¶]a~Jõ´È{Í_A:æ*èô¬ñ <ÈüÒ™3´£m·ê6ñ#ÇçH†¶a¯@°ï5mÃ"Æ›.+EğòĞ˜–ÿÜ´6ªl	äi¹°ÚÄäztRÁ˜lùv–3Âùl	Bïäk^ Níé“¿LYÉ8µh
ùµú•/wPÍwdu38ÊbğAö¼ù4+8w‰ÈÉ(lJ,‡ ¯N5³_2°tçK›Ì·Á¤¦Àú)ø]ÈÂNPµë)~9+PH¶»Dd+ÀÈÓ\õ`Œ¨Ì…~/7ÇÀpµÍ³Ö©½õx7	ûªú‚<®åñ¼Xc^¸úé	}çõÕ!Ù‰	­¨'–,I=ääAµ¡‹Ò\LUşGÇC­×ï&J³N‹àñ7d[¯E{é%™}¥ jî¹ä‚wëõç$ à
Zë¸OĞ% ˆ2­ì[•ID‡Å‡âbÂxÊĞŠZYé:&ÈäÿîA¤ê’£{Â.y*Á?û#èÓ­xq¯ƒ1móÑK—iÜ¢Í¢Oµ– >yk“övŞ¬½ˆÔñ_¤»=çÁàÛ3^e‹¬äÚ.¤Ñ‰é:O Jİ@Ó¥÷78\ğ¯cî±§àuå9gZâQıİj/æAÃ-R>‡ğaXTï9»!Œ;QuÊK°øA÷®¬æ`¬ıE_bé¯8£:^äR+»Æ„1Á¥§ŸŒW—V–ÌÕKòl<¼Èe2˜¥Ä|‰’ÇÄ][“¹î‘›ùYCp<·xxğ)¤h€0>•\÷‘¬À ÿ±qRªŞ§…=í¨:‡&T‘D:ì<‰-Tóèß³?ÆOŸPıdq‰:	“¯R®—Òë¨ŸúÀ1¼Ş
ËÄ  6hBhs´ñ´\ƒ•Ò¹uAÖ/úïßÆÛ)nıİ‰°­È=3#ÁâöVÎÀLXIç ·İxU‘°bJµtöU+•;¿ÙNuÈ”nÂÓÚÕÌt†²-‡·SänfR¨gßöVrİ»õMQÑ»å¯wâE­Ò…ôœDBšd­lÊ0ÂÑ"bPë<¥êˆ™Ê*GÒJŞEyKñ]€"r¾(5CÓRâ;ƒÍr]ê±lccM;ıØÄ×åŸ0ÇT€%e	³bäfšîÁ_6Œ~'M¥çMĞhÍø	<¨n»‰UÁê=9ëéğ²|‹Ñ˜eVP­öcƒeM5Ğ™6ÿ×«Ø·(åvEû.VË´”Bà‹««#xzªt~ğÄÂ™G%:ú¯J4™°3Ş5µ›M ¼uĞ÷ˆİ[b;?½ÜH0˜ˆ.¨Kª§‹šğCø˜em!İÔân‡Q4µ7ÊDÌIOşí±'´ÖÜ½°T®štÂPáxgR±êW¶Â§pèI‚JÒßÁÄ(±1a¾¥ü¯¨v@a“ A[ìÈ1ÙdrÏhIàÚªYÆ–6se†&šD„Ønşƒ†vx³Xæ³>€(NUµËî8·úÃ¦èxõ ïòğ'œó¨8!®x¥œ}„·‡à.……ò%–—k_ ö7à»±”Q/f*ÜhˆIn«ynjM_¸B>Aêı¤àôêg)dUhÉ9ª"7"…wNûŒ³+J70ƒ%ıëuİ—aê; ‡>«½#8¦Ìµo¡±áW)yüØkŠgò£ÓËÔZi©9ˆ+Üf'¦
 9±ÀŠ§ìè©K ¼:LĞ‹üëõ×:FÎÊ•ç=Ş´Ä‰ÔÉE“\_”ô¥ ò¢„m–M™}Ğ|S (?Í6Ufë‘’
UQf3¨:[g &}\\e¾Öée§7³¥_ü³™ö¿©¹Û~2{ø_/ÌÙæ3õpë#A£
ìĞÄ$Ò#t,·#oieúÒï%õä.Ìu¨Øe,iÏïéˆ[[ bF­Bÿ(‰
ç`Gê7XÛà6n¸FIÅ!tÙ’GóË1‚DMîêñÌ7
í*ÒãØ²¦3ä²´>ÆKá¬ĞˆşXı0>ÙFg×IÁö¥‡Œˆ„ßTËÇ 5÷=ó”´ª&XòŒ®ÒqĞÄ1^Í€€Ô?,ºÜ¨S3Œ÷‡››|˜bO@U=£u™Ø§¡`[µPş„»Ê…‹ìáC‹sØñ°÷NZ=•Oã3–ßŸTŞ*×ªşÑb33©ÆËäIâ¨pôç9Ò‰9&Ëc»5œ:Gàqy’ˆ©œÿ]T¨b»›åˆÌcãIáày¾â ŞFôÆ³ÿÿãH½Ö_#¹(ô‡8Ô˜OÌÆ_xä,üBXóï¦?«¬¦fï×¦?Ij{Ó:cm4º¶–ï@ııÂk÷ğ˜D#ÚšŸ
&–*˜J¬ûŞ¦é=dµ[¥XŒè²©tS1şPÒna%Á-o$BÿåËşAÙ'âÙ„¿ò~HL!d%§»” A Ê RÍÉ–ùÏ²¤ÔDÅ¾ía7E#ÌBu|ØŞ2¹[ùÊ…ì¨„ÏèK`YœÔ_	…=D¤P7×Ñ-®¢9sXáï_- <üNærg
-±»p$Áo~Z™ÃiÓëvº–øğê>ŞÓz_{‰øCßŸŠÆ¢«9©ÖœìëVºsg¸X4fÀ èÉi0¡‘²¢)Oãû;Lü”?¬E× ZHµmƒÌi3÷¤x³µBÖb~ÈÍà¹ƒÒhÖVFHq‚‚Íh:™ZÃBM…Xß‹bº^×­r—ã5LqHZÄ7®ÉVFºä'É1ñ‡Kÿ¶Uê²;&&å|ËÃ/ÏØw:f™Ó\6ÊDsÏhKò¾É€D?ËÃõ¹‚á$vCÉ&8çøX^‡uGwÖYa2¸Ëxƒ‘Wÿı#ïÔBİY§$VKØ’€3ÿ´şÙJpô~µ»¨@š•&Êİ,ÿ¹ótMÍ‡ïX§Eş€tkwWS8rÑçn…~]|Õ4CÑZ\Y·†RÜ,wm†ET9wp»]µÆ§zd­E‰õ©~XV™”4ôãBY*Åê%«¨İ0NÀfà?™~0Ş@àŸQ_IÒ÷,¿(<äõ‘È!ûø~
,NßohÒƒ+d3ëñ•;JŞ4ÔZüpûHƒÎÁ£øÎ‰Ã²C'ã`ıÖ–†uÚû?Ã'‘ÖšK^ëŒÊ}¶h?°|ôø=ÃºÕudŒbëĞ‚|,[l7X‘³·d×¾kõtiş&.å\Y([ß}gµ :œİİŒ÷tªQŞŞ~’dÄÜ–<µQãCéÃzKo¸¾²=ıÎÈL†8º2rHKEÉTDúÁ¸\`{õr$‹iqÃ2o•B€ğ'OîE’şq„GØ8ª‡RÊö÷áO‚>‚åä¹ÄŒÊÀmÿú\6pa!:hÓ®ş‰¾U#‰m7ÑP2º—7ÀI¨[Õ`…£ˆ›ºAAÑ%¦/[ªbÙ¶Ÿ@!êŞ¢í;Iå×î[Ó÷dÆ!·^œ¶®m<Kß°,Ã½÷õ¤ïØ`õÔ³V —¿¼f÷}ZÎ”®ÅÀ°Ë’¤8Œz‰ö¥YìLb7±
Ä­L……rš=_™ÍJ\›@•9ëº´Ìé]“¦!" Ò ÔÂÉş"ÿy•ïŠ8ƒó äö7@œœu ±+o‹æ%¹fI|ôÊ@9•"ÉŒÅY×lÄ°ü·%
A”#ŸœQl1ÍÛ¶À“d&ã`ê	:•O'¤…ae‡f_Ì	ûEEtÂíiÈ*ä›”Vö>4QóËv £îgh¬ây·FÙlæï¢ Ç#R>Ô\ÆŸ€8!éx‡DædÍâXlmr÷·bßN3tDÒéÿRÂRÎ´B¯ëÇpyğ†E"¡•vy°ˆa6û§Êp·Àîv;hpãBíQégjF‚ÄÿMc_Pø†caaíPôƒÈÇÉ˜¢xí‹C3bA“o¾Å ïpª™WÉ§„š>oI^Ï3¡‹³ŞS¿çªàåaüÜ=nuù57P"Cpãı³Ï_œêÃxÒš`§;6Ù/%¸ëZ|1Á^y@Dıua<B ‘ŒÖïEfî¤1¨0w2íòp†b¶Ì^Ê÷ªæÈŞ ˆü†´»`ÕÁR;­nÄ9¿„@ŸÖÎƒ¶í¯­ÑîßĞp©*:„²Àr½s6eÔC`Ä½YÇÃ½ƒ\¦6qHIup4+M—;©ánâ&ÆÂ3ZxÃK°j&¢~-îPv-ènÛ 5ËR0ûÂ.|(BwF]6ñï¤µoã©h-ÖøÎ0:Ì|>H12=$½ˆìp–r»1,>íãºğáÄşç‹»ØÅ]ƒËĞMzˆdäÔ¹üµ\z«$¥Ò`Q XàYÌPĞñ»\Á«ŸA¸96±¿$Ğ-c@şs÷ø`ùkLD@£•ÊYåVY%yKjÙínç„¹¦!cØOwñ¼ŠÂ”óğœÖ`p_©I~áûgØ×Z×Pî€	å#Ûª.­»²”i	Äè5dù+}{(¶ŸãÍn±gÈ‰œM’¢DÍğ|"×µœü8—c[İÆiy´Û1à*•ş:8D3l³&m 9,¹	Âñ¹<ù˜
Pã	Ë«Ä=[ ëÂ»ù#İ—Û"¢]ß3’ùÿÿ*)`lşÁà|$ËH2	ˆYÔ›qö­^FÚ·sdòVM…~	<4}½“ƒ•+ZÙÏ0Ç=H[‹ßØÈÆn‡ûj·Ù·®ÒÇ7®[n¤’sW¯‰a!mr½„U*yŠ8õ)_„ĞM?¯MCcëÃİææãôppŸ
zŞ¯—{N°<”oÛœ‘‘Ì19üOºÓ]o–`¾Äš±'±ğô*Ú™ïÇRò*|íF’<}¤L„™fõê9jã´5ÈÌÃGi4iÇÍĞ
re–è³˜Ğ«Œ•µQ[€{l›—_(àıåE4fõø$~¯¯š,á”}ŠRM‚»‚ÖH7,Œ|<7’3ùg &q÷¹ş6Ğ5ïV”¤}ú›ãåb-¼¡ˆ^=oR¨Ü!w€Ü6ÃÑ(ViYĞ^BÇ%Âd5ÈóD_dÏizÏ\¤g]²²r4°Ï¶(kj‚DzùŒıJÒ0+êÇÃã‰ğ«‰Ú(Ã-qœ<„«1_‹¢"¹HëÂõÂõÓñ» ñéSo¥•Ï§/‰µµkÈ’&ÏşGúÚÉòR9Mqû˜„Òk!¢ÍoXÉÍãXèo¥³sï(E’›;óÆí‚dâwBKÜñÇ!ö¨µ‚;ä8•/&À£™÷sX6C(óÙkTA™ÜÀòÇsÙ¥°F“Ô…ç	m8x¹éğb¢îÎ^@¢Ñ•ñ=›ÀÃ0Ü.@(Å¸‰ÚßÑ>ìsZX†Ì@èôÜÅ7Dç7Ö‹UéH;,]ZŒŠÏ¿jş^µYÿR’=´ÑéİàñÑ÷x›¡ª£„JŞ‚Oî³÷¿©ùÑ¸©ÔØ\î Ô$ĞV²P®±Veì>?r¤(8ğû–'Qs´òU&¡§¼ÿùtpävf„	×=“íe‹üxê"ª“×­$Ûe#™¬"%ÃïPõŒo>Ôk‰3:4äyëÑ†GÁmÜllîG%0`×lw—‘7Í’,YR“òoÄFm©ö]>#´-Èã¶QK Ü 9b†HcäÊÏÉ§˜†¡íDfÅ Tep£ëil-¡>‰!ÃÒ)1Ÿ_/ßÀe’ËŸò-ú/I‹K`hlşhÖ@cJ…zH¹Ã[åİ‘İÜ_D‡²±Ã”Çî±„ÇÕë_¢Ù{§§ÿ±¯ÒX¹€¶<röWlÚäéšŒŒ&ujJÚ˜&&K"ÖÀòÄæšıwÉV’Ø:³"xw¶ì†ä úW&0gßŠBAz%çàxí[«˜i›‡BH¤¦¡€05.Õî--¥—Ş
šyJƒÖÿ4¡wû+ì(İiQÀn6ıR®á¯'lMa4hqœ,$ôÁoØÏ1ƒZpÅuä’İªäè`¶}ıûLo˜¢7´šóªp$Zƒ_¬Wè¯#¬”em¨¦¡4öˆŞœ“‹'¯yñœ
¯>ôKÛB–XWƒ„İ	 _‹›¯Ë—W™±›/‚…»qæEÅÀ£bkø‘ï†èHjé ˆd;›Ú.+ßîG³*æ¡Ò³¶dÄï($Ê›>©×ºıÊ'ÄØïò3J7Róì¾ş³<•ãhŒG+Y(­’Fağ¼œhGºÑQ­é`”´è“`ÿihÎúJN·{db8®É¼“-ûÏ£ïSáÖóí\€Ÿ—`á7U4V”çtÕk²ü¥U¶åNG§N§¦`è÷}|(1Uÿ˜€l‡ß¡1X´,Mn«–Y‰V1¶8Q¬4aiÎ¹ç B»0Ô¿2+Âø¡¯Àî”™—…»ßáÏRmv14Bğ ±•MÍAtÄO˜@½Mu)vÂ\GW$Ä‹bó†b8qw"İÃôMQ½âİ%ÆB,Ÿb'Ç2ËÓ.ôØæqñ20gÆ…Ï×_´$(Un¦H«§%L4Áu84é“IZ½5°ó8ãq˜ò!÷±cª¬Ì‹¸?¨È˜ßtù¼ÓpÊ©ûûøŒŒr ˆ¥ÅÁ0+ï%˜óØüŒ‡eıDÈŒyk’Û§İ³¿%Guİìà –ÙTSø»•j2ìÅÅÙqìõÁ‹MÌ-é—¤£–™éûÅKàc<÷üy9Ë2¤R_á^í6CQ!77+¶à¯s©I%|R€¾KÈ»FJ2Ôi™må,Ñ|æäµ²Ñ1xÍÄµ>x\Fª3@%ØF‚ëÃ<R6*‘”˜*‘5š^(©üŒ·òıƒd{¢L±Òcû?t6ˆà9åäØf0S‰bÊÏıFåMVŒœ`O¥
æû=·¦±Õ>Ac1²õğ›Ú¦7•‰Ó
”ç“Ù~èñÜöòTdvgßŒ½S¢¯ç¦Eş­MÃ˜d²)wşÖ,èâ,¨¤^ñ‘ +³ü­Å„†èÀ¡óMø“ˆû
g$ìbÔdHÛõ93ã#»9†`½­¡
ózÀÛ‰À/±ŒæP¨şÔåQ{e˜wìH€sÅõ`è<> '6\c}[rö =åV`ÖÍ»ë$9kÎ…²=*cgmC5›ğÌ–»â¤0¹zîŸú¬S´åCwñİ%dõ( Ô¦o»ÜÂJ¥Òe=Ş‰‹p¤Ä‘™qj[w–“wÒ®MXğ0¹Ö<ŸGûH!G ;tşnrÔîcÑëóĞëüÜÔ5	{ iN•\õ#Ë“ıŞfƒ;êŞÈ†•*z­ÜÔ	Ğ`ÿ›éãŞuì=VKpš:pØÁnÔO®Û®ğx{×Xow›½ê|R1võ·•¿ŠJåÕÛ±u{z~§ú¢uÊ–÷êÙD·#O9s·êÑÂïüßAÂuï”Ì”¾,>C¾S™W@ó.ò)jÉÂèm|A9Ñ@tï
26k“óŸÊmŒÏogŞ{‡ŞãŞöS°;„ğ§æù„Á3ïğk÷»”±	b¹sÂ£’¿¢_ëlLşfu®«Ô3åC-qÅ+}¥í%3ÜÔ„°{öM¿Ÿ#´şª,CƒLÑöhº–I¦_oª›X§4”Øÿåv°ógèíüíSå¦¸ã$‡¹p°	cß8kP½ùÖx· tªÕgôç o½–¿hIy4ÓmbÀˆ-—Ù²Dñ¶‰•líc®“\™›°9sW$³  kàtC—&àÑÏA„—1ò «¤`Ö—ÃÅ
æÌÙÖy((ÖfyA½f¢ÜMd	½.b_QQyr{a@uÒ€f¥]oÊk?»dKÿÔ­é½~Ã¿‡XXÍ–W¶@pœÚk¤Ó#–©LŞğûæÇj·Ã¤l ñ7§¦5|-÷ªgø…]>o³Ê½…¦(•“²¦,=Ìq=mûPCQ3×8„à‘À••ÿO­–AMı7jÜÂàC½8<tzˆºz¢ØYM«÷£laKä Ş[ÙÔ¡%àá›š4bFŞĞï»Êîˆ“î…Ì¥8±„bC›´›>¿úIzåÆFüZÄË¾ÍÄv!Q7#i\{`ï¶­k–Kdf¢´*wB&'5Ÿ0/	 F(şñ©ün@h]O0N!SY(g„_Ùå&şö±ÈT^X¾Ø§Qv
¸5¾g«#NŠ‚xóTá53ãŒoÇrÚ(9šcµ¯D©{•¸é†D[Ò‘ø³ŠÈá×kÊÔuÅÿ÷n%C¸czÓÃëæ€öIív˜Ûìw¡„\Ú¶W/ßí>¯˜E©ß„B¼ğÌƒØpî¶¶×l•{~={€àø³É‹õmĞp/ó‰ï'^øÃ9ê1íµûEß3åÅGg]åˆç©«¬±o©…åÛWEÉª9*Çâg¤PïES¤aéÎ‰Ê×'[¸ù¨+ö"—zY$ì_F§Ó •É?í**ˆïáƒ¾ÅšÌmĞòà	˜öö]™3%<Ğ”ªZóÅ>´ª¨ïºdb†’~­ÑŒç»+(¥]¯Cú½qY—ê¿ÛÍwÇ§¹,¯[fí‡!´éoõ)NfRy5”Ñ
›&fõŸÃ¤Byß¸P]”à\Øç3æZ°z‰¿Ì_Láÿ´LMaPçIcj‘0b”N¦Ã¥›ÚPä"‰û¾Ö éëyŸÅr5‹=¾ÎÃf®ã¯»bn¿ŸßÊğòá6 İ'*(•¤|/sÜ„6›wÔº{Ê'µ˜ùœ;N*qweÖÇ0•‹Ş‡p°¸!ãP†?	Ì+çÛÎ¢ÅV~·8±dúQµ÷.T„Tkò}DgÆ òåÉít7}0®¹NË»EÂêÂïC3d"dïÆ4/49[ï'ésiŒ÷¬6¢¨yuøHş
eWP²8Ó$D;ÜÕJpLÍì%5£0Š+%Ô t—°ÀêÏøVBO\á«Íè*_×²œò^ê8;ÊN~„óa3PöÃé¥mzlÆ©4±JzÎP`B§kù—ŞBl°>ş·Âî9™© ·	zÚ%oPó^VŸ·¶íju®‰õ/d/ó,K‰ }g‘ŸN¬„'Îº8gŞUõÊs.—¬Æ<4šİ†¼õÚ¯|Û,;ø›fòÏeodÓƒTg÷
nuVÕ´2:„XÑ-tø:ıoÈÍ¬Äh0Î’»Á«`Çã¹ªıò‹Bm*ïŒ+Ò73?h¾%Š…=n¶@i›&Ñfrï7,¾oq‡÷Ù% —«'§é©ËB‡Qˆ,Ôwr½‹a&¬ˆ·oóq¨İ=‘!æ€)pK8[ sşâ¸Í¼ö¤Û0iïÏ“†ÑI³UZ~%Äµ$ŞHò7+E´zîd_Èu]ê¯uóÒmĞtÿ#åmÁ]~¡w2 6ô;£Ş‡Şò¾p|(Ô-„ÀÁIÔüƒå»4ÈcIÁ qû9ê¹jcŒ,€‹Ÿ©^hcœ4UÉ(pê°â:•£hÁ®I÷âv¯İ?[?o¸?4²P«”ªÿâôû1næbFÑÉ„.)DÃ< Õ:	i×©W×ª&<P(éíÇĞÜnÍQyL[ÏñÇà÷ömE\Š	D¢ Éşqş¸jøCü~wõ½°È”şHcï“µ#ñÑ´|¾ìu$×+AËÂïR›X2\GúàÃÓÖL	.È…È'ZDgÙ]û¢g‡CÈI|9„C»¹ÊÙ…[.CB{}ó]Ïå÷ØmgÍlIğUB£¤¢ø‰ëD*R&qc”‡ f‚P½“?pÏÌUƒ™íªf§k¯.Cxa¬‘´¨wÜ÷ŠÖ˜UufYrÇ½Î>Ïf¶¡w'ÉbR„Y2±zxI“I£Í fäulK±ôÖ´¾
S]]¿@–/ÓŒK^wºjRzíñR¢şĞø¶¿ä†ªTS¬1õ¤£ñB‚¢HNø—Şã'üæÆR½bÙÖ!e½‡¿$ªÃìº¬v”ÈbsP¿BZmû1(ÄÕö§aú‰6ßG;ãËäˆ;€19ÙƒW9+6ß*5¬‚˜!©¹+¶í2ùti uHĞKÖL–ï'«”Ã”“r,{‹ntu…´aşÒeğ³
cèËØyêÈÒk=Ş‰;5 „ÃTæ?miş#rÏlËf“‚ ”´j<bh
´4›ëıH3‡-·z¶Ä<‘(«ÙJææ¿Õ8»£x«#S8ßY-p—¹U'ø¡biä4¤BÒL÷òEÜÇ{ÊçavÅÜŠ!„”dˆ|Ö 0¯ÑL–©{Ş«ÕA²a¼øz)Ô¾(Ä±
’F+ÓÓ·É­N¾!ŒqÙM>mê¦foÍúÁ4—ø‚´–ë–8ye¢p(hUPËºê¹W¿İi__’Âk­¥³·´¶;Ç$ºÓ Gh,(@²ú)1\J‘F>¿>Aìù .tè‚˜™måF¢0ä˜Øå{1¤š¶Ék†Œä±¬ÇÊåÇ§ª}ùúy/ªmªr{A\“Å‡¤:
ñ¼ùø¶à«£¦Ö@Éf»kÅûc˜!IsèØ˜›ª–T;YÀÁáÕhCòPŒ§˜­vÍé>i~U?Y§]o ëÛ@Ü\ı&å¥Å­Ú035Féº?ß¶s¿§ÇªÖ‰Î²%§z5Õ,#À’N‚^é"ùN§·°QÓ€Ú¯öPóğºiSLc!“*İ{g·:…P
ªBKÈ‡Ô.rYš>¿”¶î•µ9Ÿ@¸•ğhù“m3°$G®Ëğc²_e?ß–ã%à4k£=‡û·pÍÊvíÇZìõÄM‚ê\#i['É©$¤A“ƒsúœ1©s…ÊN|XÿiÊrˆuö‡šY/x¾©ïŒıòüNBßv7ç½¼Ñ|‘å”6ê<çÀGò"—Ü¶|Y×Šµ£
½SCLÔªµÓ9.ß»©MÌ¦8×ƒå½½~âó,£¬#¹Õå§</#ü
ñ‚K˜Šá×Át'ŞŸ§â¸NÿùmN!òÊø"d&)çy÷¯,ã5F·¥Âëâ@ã”›5ˆb%3İD s0¢ —›œ\QT!›´'bˆĞÊº†%t
Ş'i	X|„}LÁ~õ[ß¸‚ Øé08/-iô*©ì1òËe^tÜÏ.ó2gÕzË(ûˆêÄÕüçwL8rgÕãÓé°)XUmæ/Å\õñ=§s
4ë…~ä°Yã3ÍÓæ£95Œ)Á2k9‡K†Ê4E/Ïì¤˜	êq­èÖ£ÔÌRÎ’Mw.aÏ9R2~«^CÂVûIÿ– ëò—¯Œÿı@¦–W·[Féíö…ïË\±b&^Ú§­Zhå±Ôè­÷˜©P™'”ÿä|¿]²Iu KX"c¥&®¨¦•F¡Ş#Ôâ	õ@ïËñ‹T÷pôØ½ƒ¼ø¾Úf=Ú®¡Í"1"ŞÉ¡ïş3oíÔ’¥=¥HÚU]eèŞ€ç¤³PûûˆÒÒ1£ÂØî˜(:}ÌSµ±¡ız¹ì…–'*×cD­wHÍ¼<©I·5'NÀêOhÔõsëòêfÃp£Àu&4×|k®#5ú¹o6XNv»,¬5º'S¤oÚNE€ğÿ¹Ê|¶Â&:İ;n/ ]«s¦ÛŠb€Ÿ‹,›Ãkªí‘P`ºs9Î–ãµÎèº2jw²w'aójÚº³OÃŞÊ—´Qx¦Hh`61Ÿ‡ïšyà¡ÏÈm€§ıÔ²úf{‰=3ß+/ŒĞ[ ( ¤—ék°´"o©ùdØqzDW¾AEÔEL	D&“¤.xQ|y ~
5#ìo<9â^%Ş•zÃ=ÅÈ-´z`uïù¿"];+äĞ0æô•‘„rWK÷Á¥_­ÒUÔ‰,Zg¸Li¶2æ§ğ]\dCüë
€-İq&>¦OXW¶#Ü¯ı³±F?QµçF+tå£º»jg~N1ÔËŸÀVB3³úãl¹h•7-Ş	›òèIhÛ6·Œ6õUñv ôse#±G1I(ñBqÙ*6íØŸtwCŸÁzä÷T²ìÅaPÌu¶_ƒpÅò¿òªÑ£ÙFáÏA<øÂ=@YŸokÍî$…-Ü2ß»—må²Ş}-”Õ]qqXfzjêV)ÇÚ°AK©‰W¢¡À¼ë4Ş¡ÑĞà7?l+2^Ò÷òxLÒŞc-ûA9wSÉíq™ŠÌHÃPI…Ù ¸‹8%Rº°å•ÆÈ@LiXP+SbW‘İ ­  CÅÄ¹†‘ßr0Z†tN9/Zàª3;¸E‡Fsõ˜ßĞó¸C¾=‡:5¹¯€uj¬Ş¬òÌ{ë5°ê>ïºİògÕØY„S¤Â.(û– ¸pOÁ}Áé1›OLb·Û;§3àº^ŸjJáC'(Œ°¶>ßß.Õö?Í
5OÄÅ±²O‡ÆGåÚmÿ4TÊ¤•ª«ÖMaQ’Æ­œ¼À1á£IİÀ~?¼'}H¤Á`ê;i1AXæösIÎãO>áÁ&¨8®ĞÜ:B‰ò2û¯øxµè!,bfÌ°+*°d³˜¯°£¤ûÎ¡8J°E2õÓr>ÄÆ–öM;aYŞµR”†Š´?x´˜Ñ:Œ»Sheô]/;•X\E•,ûœBcµ¾‘ìZÛ*g!ÚÜc"£J–DªÅöªà‰‘ºÑç]sÅ—üyHìÖ7ÖH
—`öìâÎæï,ÀÊJï)S(²eÎ„Ù:–ı5€¤eù2·ópXÁOŒ"/ÂYtš>h÷Ï]Øójª×ı¢ öø±\‰ÒÂá¤ƒÿO­¢8»İÎ)—ñŒHCşüè…KlI{<))ì’IûèÜô9º$E¶§qš¿wâÎ†I%"+İÙ´©WÛ†¾CL(8ÒÍ¨m8Je:O°™‰xUó¡¿	ÊºXZ‰pKÆ°u¬¤l¢Šo)‘äªŞ#cä¿+ãÔi½eİM:İ¬1˜`…Ş>IãØO~
Æ»‘gÒ/n5Dû7“Ê¤{×éÙ®àÿµT¬#b(Ü¬RnZ““SjøGY‚
Ï[Nü²T/àœcÀoaM(ÅV}ÁÌ´)"ı¥Á¨ÍË]ÎÚ#
°Cı#¾©iÇıZ`‰qN“ßÒ—%¬FmdkÏZH,kyÀZ_î°Î|¼Ï\ıÁ%3‹|JÚ¦çÉ8Mùûäç8>ªˆÛLì™7˜x	­Å{ìK·Íúd·oùOÕyƒa²SãˆˆR;bHâ)Wî&œ9õç¨–‘•Òù{ùË[òÈôü·6ü±*]ız	çYlïp™JÉ«oGyœ]óVw2‰Ÿ¯ÏzËÂ›p™n)ÕòÏ·A@éX`ä^T=b´¡!¢ï‰-}»B¦,½ª&s¿¾ÿ?ïzù¹”ô[ño Ä©¾±0:“˜*v9Ë°­ ¡h1yXôX­Ÿ—À
}ˆã`ÊéT	ĞèÆ“ÈlÅÔU¹nGĞ„Šÿ
šp²“h”-ûßC|-QßFª~@]˜àn	\Fø¸vÕºéeÂG³P-×Ë)6U·¦ğ	ZeÜ%æo32ÜÂ*õçv`QŠNãĞ§ÛlT8M©Oyµ£TÛj·xå.P5É€¥¦©Ğ§o)Õ|qâÂÒE¢¦t®q»MiœõåÊôf­@ğèëZ½L?åãæ<¬!ú/³¡•$9J¼à#É9>EœıôgC&Mr½¤fkd¯¢nYº¾C‘|¢F\pêê”ïÇcRà/Š(ã†\zÆo6öÓàuJ„–^èM=ı—yî
Ûn—HÀd”mÃÀg3å¨eÀBVê\ Ÿpêã³ Àätáb„|«4$‡âÈ`W`Ì§Ü–ô¡gKLÓ„ºlüÕé†Ì\!]Â”¿~R§M³yíªzØ_®¦ê·#«Â×š­©‰ pq€ÀñËÇqˆ`†ÍaGÉŠßë|‡çkÔh)©+Ÿ‹å?upTJ~ŸÓô°9šÊÍe±f× 7·
õ¨¸Íö'>Bƒ]ßn ›áÒ†rXT	oà‚O9~é•v²Ö•¯€lèË1MƒÈFY*ÉGé¸%—~š|+5Šö9ÀÈ˜wÎ+õÉ^)±•ıØ1İˆDºçëMŒ« .aé«ä³R—ÍŠ”0|´ñ CéÈq,½ |pÍÏÖfğ Ä=a¿¾SÌŠt)FİÆqQKFv@{8?ÂôÛ²0UXæÜ·€¨¸Ÿº·İC„Êm{×ÂÆ0Æa+ñS[	qºwŠœS¤ïo/—Á/üqE]
ëÌ^…Ìï¬…ïvsº0Jà“ŠÁK?øÅåá¬=ŒbS‹âVjÂàÚË‹Ü”ÿÔL®Â1©×Kr:ƒÿGÍÊ·|¸»?|¤+v]^'5æk»•¤&ùázp~Í9†¤È„n‚ƒˆÄVxÊšÇÉÆC—ñŞÜ]Æ Ö‹ÖwLÈ¬®ÙŒF6ÚšK?æå.sÅñç{QKÂY‰‚¯Hñ;¦‚¿uş;iàA»‡Ş—Êâk°ŒúC¡)&©Y@ÜG©CÊ‰Ó¯Fä½è"ÔNƒ)ğë‡Ú›"úâ÷¨ÇÇ*k¯/Ã|&ÀÂv`äÂ}2ğ‚;êİÁq6°kİR£M5œ’|"œ#ì²gÔlÅìUGwJÕfNl0RårÔ+é¸A0È“/–©cl|û’4ö0›!äÍí¬S"HôULöÚägRVœr9º]GÍO§t3RK,c-	Åæ#İk%ŒÊ:Ì-{eÖECYv¸³ËÈ¥³^,óÏOà2NğQtßFPıb^›7ÂùÖ»,ãzie¡¯ëôı_GôÈ	»™Z4fºm&£á£º;jM©şç·ûªÿöÙ5,µ’îÏ‚µ_ à8ewEò -m­î$V¢ozw¥!êı¶&êÕÜaîçÃÏNŞ;¤*…Õ(@mŠ^&à#{0s‰8zÅ°f¤«5jÔ¿×˜±á‰ßE`PôJEb-Dè¯ÄÕÑaå¾‹õŒOwÑÖ¥ØW:zÿê^¥tßæ˜é}“QÚÔ†q§.2âk‘+åñ`šùËhQFÙC–ùß¯ã€Î`&VÇQ¢b	@ÊéÄF‰Â	È\\LµŒÎÛùI†TÃ—qùa‹ã½ÿŠˆê+fOİÇMÀŠL¨½”7(Rh¥hÂe¾ŒÅ?Š´‰¨ëão¹|Á½!Ú³çD-€iƒ©Í_ñJ¥[‹²nÄ'Ù³?JËB¦I|[‘»ÃAP<6{Õ[X‰$g´t;}ÙdÃMädjK×\§½¾Š…Kî3üŠf-Iû)RŠDyªbş\iÉ®±İ« [måêVìé%šk;yÉõ6Åj<’-±v²÷z—õWKsy?‰‡ÿÖ?“3•º‹ìşædÃE†	vÇ…£ğ‰…‡Å}SKnúÒEãeÁMà‹÷X†E"¼¿y¯]>íÃ(D#úW7XªXL…œ½ÂP¼ÎJD”’¹ëEr<<`wŞüš!À’ÆÌ_s”0õ”6üîòË0‹=işåÊğAV¢#eF«í¯~Beâ¯‘x\3Ë™Ghñš0ëbT1Eõã!;÷»Ÿıh˜yëg¿¸ÅĞ`)oaùœı™×{Çè—&>‚˜­ñâ¯ªïÖ%jI¹u8™·™¨YYğsîkšº=/Ó~iĞ¥3GÁµ4²âÏ‘MÄ"eUÖ3âÆà¶NløÁ‡ŞrÆn¢Ö©/S/.¿E®em°št^€AÖîñêA~·ûütaÎ…çÓí4„È7µ™kPL=2ÂÛ20ëû/Ó $îçµ‘JîÁ¨œÄdşÙ‡Ûİ¢Uª»tû6Bs‡Ô#lÅøÎäG¾à«³¡öxd:%Ñƒ5â)VÅŸ¹N8j-¦ cpğ Îh0c$ÿj°YŒíÏĞ9£líˆdò{Š‘Š;’"	ÉŞWIß+•C/0J)ä´òûŒyPÛ&h÷Êë×}ĞÍö¼Û6Lø^8^
§‘l5Éf#I½.ã÷StÄ6ZpÿW¹ñ*
¯¤ªŞ'5ÛÒ¶Îõk:ÚZ!T}¤÷â•^æ0®÷àDØŞç&Mø­—È¸î¤zSV¢x+±Ü‘.±M¬PÏ¼+Ïáà?7ÿûÅÕ¼ë›1÷ğµÉ§]|2âV‹—>’aò­®§gÆ"E‡ñLnôMB_ÊÊãèbÌô²(öj.Z€‰k•€2ô	Orñ­Ö'Æ4†Ü+"a]Ñêğ'	$µÛ~˜Kœi-¬9í?ÕQ<ÏÒ¬
•ë"Uy¨&–‡â@ô÷	Èv`d4¿¢>ˆp«ÍëüÏ„=Q\ò108×,ã»5Zº{ë³Nóêsâ¸!Âiúµ®şUAáŠ1zİû°¬>ªÜÀ}'wnØ@…¾j‡/4»]ˆD|³şSAíÌ[Ã…x‚’şV…nvÁÃ6æ¦m™Í˜©¡õ±JuTkÕHïÌ”ç½ó#[UfêÓÍĞtÅaG%·Hã‘‚¼ÀÈHwl×ã{îèÏ’ÚOî´öZûô€Ï€£6íCì7˜Fenéuª>^¥»Ä'÷©ÑĞ›™)¶¸‚'ùÍ¼¾\l5t=€¿Â)*–n!ü‰¨‘‘F&‹( ³-åÑÁ@œ­’]ºn“®ÜÛ~Ÿçå Gr‰'0“­Ï(g @ÖÒG–q`S)ìÌ­˜g¦‰8ğ‹/_tÍ}uÖ×ãİX‚Œ]<‹Âb°0®¨“!N!”jPØ’\‚@ŸôXzœ•ì8?w­œ[G}Hë!øNê×~ûZ/è¹Ñ›p¡á ™â=[(TúrúLaò©I¸tIÑú£¤€²X§oµòQäkJŠcISaøV5“r¡‚™÷L°ñÍ¶F%Óp¿uÿ¥'îòÜ°.‚0ß+Qğ7Bµ“Í ª¸&°}¢.rÆ™‡ã„“şåú	”É²G®õ{‘Tÿ«Vó1OúèšëŒ<ËZ¹IiqÎÂ²‰Ådzs¤n@½tŞÊA)8/êÇ,‰År×ê¶ò-¾' ‚™ˆ:Øb>©<ÍyQO´m¦L™ã™XN®ge¬rÇ¦Ù×(A<k[	æ eÆ„	MÈeTÓe‰:[êğÃ…ò²Œ—Áüàš<Wj©[ÌX5_ëç‚‹º>µt3®ÌHÂÛÅJŞÔÄ³·õ`îNÔS
 ÷îuõÚ¨2ÁÔIÌ ¸Œ¸®4ç€9‰rµ‰¥BÌ‡@TĞËM!’8´v™=9c›ıfƒó‚ÌFk…)62Ñ9rP_¯ÿ{*øµÙ÷zÄÅê® ˜Ä€ÿÀ²œµ®.!x7wwû¡ÜOÊ2Os–ì4§Â`²Û)¢}“c¤ÂÏ¨‡yƒÂE¼ı¬Ô{˜ÿºÙŞ[7‘},dzO¼22 e=«¦™²a ô?gx;éW³pÉØT¼0ÁÛ u5 /Ca'wä=ÉIkÏ1}‰¡½Ü+)|É)Œ~àSN¤¬T
²œhè÷7sÂç\È>Ô0´Îgä¾›Ña&×â£reÀ£x38%k];(….n¢`ìuR8#"Èk5Îğ$ÙËY®gÒ­ñ'R:rîy/x{pö†Ft¶1fRĞQo …îL†{´}à‚·„¹!Ø •$wßj3%Œqfš(_aîİyb!K[TãZË6d3ÍëêÖÃ;ğbñ]ù3}ZÎ¾D£K¡®jÂM^èbAª
®²ÑÑíÂrç²o¬ğ‹¯M1Ö(ŞAÖhºGÿË—ô6\jcß‰»§²ÎYŠ™sÒ
R8»è +Ğs\Às^IU(’]KnÕ›¹}Ù—¦–¶ÑÍÒ¸í«şªéDæi‘ÚuÜ¾{âï Ú?¯£y,.Xm‡Ù€‹ĞrŸècuƒUV
,ìŒCi/'°+‘!bôv°Rs&·R8ü‹Wp€©¡ÇÌ¾¤ÄˆÒÄ d hš½#¶‘Û(õÇ3ÄSÙ`EÛ']ÚıflÏ@âjq"ôğî(\Å"B'ÕE=eùïÅµ“áàáä¬P¤OpÖˆ+ßŠö¤†Zo¶
%…{¦tpÑAëäÌ¤3$5ë~|H$PUªÂ^ö§OÒ!Ê(M5ü-H·MBæu:_ïôS¹NI2‘ğ¿GRõñû \üÂ²ÌÂ3Œ@q7ïÊnSĞ`+ÍY¥6¢ıëßÖ)wÏ:C(jÿÈûs×ó‡|Ê‹´-¿ÎX~„MÙ
&–§S¤yu+ã£w0*Zà„‰¨#•AÔPóDĞ„uzATo4µËLšÃUGë4[M'Êß9|b`r¡± Ïš;hÒ}BœÆş]•ò'ÏG>2à˜íù:¥[Ä÷»Ü|éˆr„	E©ç1Fıë”‹ø€‹ë=èÎxù†°òî‚](	R–+ÜÑlB$	ßH_Ş…)»_¬()1UŸ|ZGWŸB^×ûŒ::B È±@oôxõé”tÆpH5ê¿jÌ©!Ê‡zÑY(ªTdğ·¹  ™Cøé?+n5Ğõ0ô.Ñ¨¦ëÈb ­Y£#XS6Â-9Ğœ‰¢VÊš†É,_;ÓjPNR
ç$7lªÖd¶Ü¶åÀFAmx„x÷+ç‚Å2ğwàÇ™qQ!Äş¯
¹æéÊgØè$/[`°Ôˆêz$DµNô|„5#\8e[q«W,©³l¤Ì¾ÿ¦©*ÿ>'òàş}B‹)\Sìˆ;. L(C»S6º´ã
~É lK-§ ìgÜ{º.Ú÷¨2føÃˆ0²¸G‹Ìu§‰Z²<èLØıTáÔCıê<oÊ8XTŠ‹UK¡M¤â¼”§€“Üw´éu†D?i'ö…Ş ûosºÿˆ=ÕÉ÷3íÑç)°L_°Ä§ƒy·t6ptv¯÷ı‘‹¹:±¼S,¢y>b¸ôÃÀ"ò½lšºQ•ù˜ÕÓy|3‰yVêöç¤•Š¿Z'šªˆïE,?”]ÄƒÉÑCDÕŠ¼k>—ñE±ûÏl'ü1Tí“ Ïpx½ÀÅ7Õ.™oØcÖÔRæÈWù‘Dã0^ä+á'Ô\`‘Nš	­Uƒb] Ä:}ZhPÀñÓŞw¬-Ÿ9ŒÓ6‡’-"Ä."Œ `Xş&Áƒa@;¥Â«aûštÒ„µ¶Z²T&çßà„ÅÅk:$P&‹°Ì?®Äá÷ËÙÛo¬!e[9îÊ´DğöË7c„uóÓ"¾²¢\8æ5·‘¥gê‰¿UeÊ¿Ò$J›ªËQê*ğ·l®Éu)Ü£|³^.ªyøfÆ“¼L·—b2o	–ïøŠ’•ä¶ëÒeÕñ/¢çˆòıQ€
·~qxşnY³òJşš¦)ÁLÆ y¼!ãŒoñ4}¦9:³«¯0°wİ='C´e^ÉjjB»}ÙKşâ¯ù#œPgLœÇÉ´X{“½sÏAø—h²$J|z–á7kKÉĞ¥ß7V nßÙ71ÎĞ·,ğ2Îa¾bÿlQWÉk£!¾Î‘òmğêì•9çP–„3Û6¶´ÇŒÔì¨7 ™¸ûz‡Í{út gË"u¶]=xq‚«&0Ü½rV`Ë¼Æ4-×xú6÷`ôÏ-Â+!5SOeá¤¿?HÄM±½×*›mq—³µşWïrzC@6-ò^†Š};4Nuk—Ø#ÌK}-aÖ“¦SwÊ©G«ş/áı)²É…Á±—èS¡ „9qW0öH‘²Ë
GŞÚhô¿Õ„±cœï:“£[âÄnDƒ	ënZe:\âØi14&ªàŸƒp…gÇËî”TŒù¬ÉÉ”}Ã@<ûË_m¸Gq*­·O2ü6 ¾<ß¯Vı0àšççK­KVQˆÚ©T§Ù•£ zÍÂ½cæ(w‡Ìã GÖ@«jH‡S	v,R5¹ëÄv“#N°¯"íØu+—øO>ºËÂEçhå£OÈ¾L«h.ùƒ™R€çŒ\¸mùÔ­†qä«ØŠÊÿ3Å‘‰Ë$¿O‰òg ÚĞcÀ “Æéi±oé74ş~ævVBÉ¨3ÿaX”ò´ÆÙĞ0cè==zëZ2’J¨¬ÍÖ0­xû şŠÁØÉIIÉ
2.øïğñ•%ğ“Q«àOAìóÌ¢O*šÛxò7°Éª'ËLáÍ¦¢@K­èæ‡¥‡(M9è›ÇØt—ÎbEhe¢(ho¨›CŒ#³Ø}ß	ñ÷Øc¯ÙÁ_âákÃ,w—Ú|É…nÛ46Ç®;ÒzˆzşR¯°²ĞÇRH'\íÏrÜ|´!°PŸTUœM¤¯ª¾«¡£¬:£zé»çû©ÇXÖê½N¨9{FùïßzQÕãéëu]BëÆc>‹¼"VŞJn*¨mx”ÌM‹áxKÑÁ¡Èöœ”×CìÕ”Ù'ú>Y#—»£¢nA?ÿA•µ1ı+nZYH\o“‰¡Û-TÌ—.î °ÜHØ¡Še¨¨zŠ”¹Ïò'ëœBrrq ®Ö7?:¼V»v,5O$õÀ’IO+ö{÷°C³‹YGBS®D‘‰Ì¹IÚ˜yTU1$¤éŸñäíeæ%İÏæH:-“¢ ĞÒTíø5¬éh³<L¸¸‚æbº~i˜!&»ÔëTFÓut…
6ˆ=YŒŒS“Ì4§Úmù¹™!…kœ!0)R¤6©ƒşH§úèßsãŠ	yÛø£×p#Ìõû·y’¯¤ ñù¹ú7YúœØ†¤›ÆˆÙQÚ£uõ0uB _›{.Rèõb©NFÓÌTûàoÖzèš,,x:#}Ûd0uÍÍ4hNû­-Bæ9Y2ú§‰±«'z¤EŠRÕ¨øwÏÏyáğƒ¿cœ¯:tUGoGh§kQWLáq\N…ïƒ S§ÜpQÂ<E³A§•¥í:!l\‘J­†SH’ö?ï&ĞWbB‰ıüx\?QÒyZZ˜İ'Ñ5¿ÅHR¥=æÜºpS®º~¹¬pãõ¹¾ÄplÛÜs¨•ÕjÙˆhh]´¥Ií’gÚlŠ”X!¾`D58i¾G¨uİÿàz«<Ñx¬j˜e]^!l=Å€§1ëI Á“šéÉxgëx
¾‰3q:¹ÛÆœ%*=r*×IA@ÌÚ!¼k í.VâÉ6nèš’l¡¸¦Ù1÷ú|­ƒLÛ$÷É1šOQ°ıj>'J7úÎ¥ĞÈB·¾¢UÜÜ'g?üéÜ dX,Â¼=/ÄáQşÈZÀ öÆ%ÁÖñ-SÒ‹G{Ñ îAÏÑ$¥L~œŠR£~. …¡ªg*®’¤iêQïKo4N'T’ ¤°³oêô«tâVáRèù€FpÄ“aø0XğJnÊ8hÓù­'İ§C.hIÒé›âäYCª5d‚{s)Q=—›*’Š›ÉJğílšs4ÍˆsØtÍ~YE”Éo×½m‹‘‹‡¨ÚÑãè™ÄØsc—¤ƒ4BË°cf <ŞaÊ²ËÕ·8$ªz7‚­¾V:»}w©Z/{¿S;EÔôûšçVÆbD½#Va¿\ï+×¡˜¨‹Â9Êº“cqsÍúO»MŠm_Yí³¾lÀxï’“›æes†q&s»)s”'‡o¡Çµ2_HÀ®[:`$O'!ßË°izÙçŸ´c/Ù4AŞŠhp2š«6ä´îï.óW\c¯	Âd§…ÓîõR^«ú÷AŞ1É`©DÀb¡s¬€Š†V,÷8—‘
æ ˆI‰o³¨ş9Q1é.`Û]ùc¯h-pñ½·ÆŠZ†™néı®õ€™ìáuù.;#—iËö%,¡ÁeƒÏ<ª¯¸
Dg¥êº…²òÏ9âP²,Ÿ¼Üªp]ÀgÅûLŞæR[Ç‚Hú~ç˜àlsjci	´L¨^"Àp/]”ãN‰•vı@­¬=k\rÊóÿÕ2yóßÙA9qÆqŞ›«è»AÁüÙE÷#<2œ9Ò=ìÎi|Â¡FqkÅ„ˆå€ˆIR*œ”ÈÔº8_›±ÔaV‹ÉìsnÙè)ÿ¨«ıà…HØk¿xºñ‡ƒ(’W²6ƒ8 z’C]û›ì3ÜJ’¢%E³(l—g1†eåLr™Ï2€5$&9<ÜŸêØ?‡Ñ,ÿ4ŒÙàlbô¦,n(l85/ :9MáÍõ½o-p›K®,¾­fÓoö©V–sB*€ıÎ?fDd¨k›é¤eqXËøÃ¢€Ñë‹”9Ô›ShËß'5/ìšB»îAVS@ó‚‘ï’’ÛÁdé·õcøŠh€ôZÍÈ“`
Ç­Qò=‘±Z![£&H ²$±ÉôÂËSÕßyuMÎ"ª P'Xñ-ùŠ˜°Áy¨J|ø/üßÍ¬sß›ÎLÎWT%M©wØ+Û`ü±FíÕÌ”eÆó5tps}DJ]2MNˆn˜Îü@t(bWíä
µW¥-=–*mê1Vêú×h¾$#ªd×«×WX|^ËÖH‚9ıIWq
R±]jùÃ€€–úm«2¥~eNU)ÎiEO÷Õ`†÷¦I›¤Vöû/MqbÀR–ãy¥GÙdL8è¶lgÂœ&2×/‹/€[ıê¤Yßd£nz“>†ú^cW‹Õ¤pAÅFù2Ç÷ÔÙ±Ûre83¸H)ÌÍ†Ô=§PÌEpïºËÅˆ´ÚÇUh;—¯Nó§mlı;Ä—X_øÙY¨ŞjÚïŒ(DË8ØÈÛ·ˆ¯(Z4`íw²lô»åZZÃqE¿ßÜHÌ2ù?ÛÖÍ‰ÿfA'~»Aó=b	å­G.`Jù-Ëúî=£‹"en­ŞšßjxÛíhÅm;ÒU9Òô›q¾lDyKJPY…ªÚs v­+U‹k9£­†¨¹.È…@ Vvè‘µåä„_Ÿ bçnÒpl«ç,_â>ùê©€Óç²¢òucâH§—«.=“¨XÁ-£ÈT0Ü˜§!‘>Êi6Æ¦Ÿúº*ı†“¤q·4¸C9AEˆ@uwJÏÉMQ:+)W”ÊÀÍ¤>Ù± Î7$ÒˆĞ÷|Èw±Bn~yg­0(GWï0fn)A:ç°a‰erF;Y)³U e¾]mÍÆq®v*ò3Ç›œH² QfûnÁ4é…¤ªrÿ‹"ÇŒfAY E7FTeÁdFxÓ÷Ø³ mV,©L—Şô¤%I,*†a’v¹7êx×Ò÷ûJ%áNñ¼ùĞó(OÇB‘Şœ·¶çPÌ«Šf)m,·^=<Á21×Q4¬ —3tqQ8®S9Õ„¤‡ëßN´ÛÅ1á‰bpŞÆèßuD'¸âÚ*?¥2…²D¦ì´°é@ãp€q‰mme²–ö"nìj<÷ÒÛ[ [Î8Xlté‚½/ìì¦à)^0-Û[“(7’}:ğ¥dÏZk`p/ÇQ/êBÕeß¸fœ±E©ö™JÈÒSS$ş=b<–|âpüäÕÚ¬‚Uˆã•ªÒÓg¶¬*K$âû¾ˆâ˜mŒß§EpŠÓÅ`³òñ·f(Ä™&1¤‡McÀ+N*¨¦©¿®a€Š29MŒMñşRjö}5äÖl#å¯©¿äÁ56ZÓkÜã°8rbYR„9Ğ*ğëŸù`sø™óØ\³ûİ[¸W€ªXÓËFÆiıÑLØ7 ÎØE(HqğQåúÊx–s?\jê£»L|$½¢ûh¹GG]ûƒûØ¼GI|dğLÏäpĞÑêÿÖì	0’r¯>@[ºdâ¾j«´¿ÍßRÛç:óCL~»8sê·Täÿ‚êï}ŸR•ßuZTş•ìËA=Åë­ÍL-vWF¸¶5Üô¶ïì~Œ€Ÿ2Š˜æ¢ésÀ›5@ø‰Ãç'ú¸õ‘Ê(¡ŸIçÁ•}6PÂúd+3›œ*Ü]jV°•Áz<›¢–èÆ—“-—²0êË‡«¼¦Ó½4)H(çßnü‹$»¬æ› xQjÚ¾Í)µ–[ùØùïÖ¤ä
Š¸4ñŠØXÛ·´—’Ú~Ÿ¤‰ÈD|·\<hìAÚ ¾…[?h#‹PçEÜ©šÍ¤ù¢Îé‰;ÄìP¶çˆĞ¿õyâ¹iÏ|F0”xXÕ#ù´38½.Ò…Rƒ&æì0$c–°Ô¯¹µ&°×AòõúZÄbf;®üPa 'rš/rDFà}d_'Ã‚zòS}ók\ÌG¶3`Ü¸V^z<òl‡€ü© $À xlo_ñŒûz<oó»é,î-Çªû$CÆµªæØz
£zgyèmµš†®í½‡Ó…”¸¼ ‘$¶}›¼=¤ÍÎ+9æ%¸ø&B›^Ê\7ŸøòÍÜÔYô®Æz5|…tx™„"{:2ûhbKİ®;¤H-F0y¿æŸfÉIQúßa6™ÙèXÑ6;ºOòo™Í	P
á7ADeƒ…Ô¦",æQKg¿¾A·é±å‚TúO{à»á®Õ':™éM•!Ê›gioá˜È4€ŠÀPZ7˜Ó.+îFqşäc^»¡wC;|ĞP‡Eâ6³÷>SŞ˜;G#[ürÏG¥)EÓ5Ê–­¨jlï<~ò-V¹ú©¢Uãæ×©dÔ‰#M …ÖËÙ…FñÛ“åêÃr¡½¸ğ·Dwı˜õÎ6ËBÀW”0à”mh`ÁèÜ[m^|­Ğ!İ¿Có«áu;›©<(¬¿8ZŞÖqã   Ëb`~Rè) ÷º€ÀÁÓ¢±Ägû    YZ