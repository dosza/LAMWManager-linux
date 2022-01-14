#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2039349509"
MD5="89b828ce4342cd209cd91471ce1a4f1e"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25856"
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
	echo Uncompressed size: 192 KB
	echo Compression: xz
	echo Date of packaging: Fri Jan 14 17:35:15 -03 2022
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
	echo OLDUSIZE=192
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
	MS_Printf "About to extract 192 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 192; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (192 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌâÿd¿] ¼}•À1Dd]‡Á›PætİFĞû“î?¾{æÆ†y§ü‹P¸ùg‚Ëµ‘‡ş×e5dªËï½
4mºwÓõè<øÜÑÊí%´µÃ÷ÛÁØZÏÚØ‹•3 Z?8¯Ø¤\\¶y¨Içj9pm	®ÆÕÇ¦çUàòë" )q8taûÖü½=	â«”¿R×¿ZSF|afÃxíGºuÚí.×‰IqŞP”MiÖ Ë„ÃarĞHpr­>Ó¬TÑ)rW¯¡>Ší«m¤‰åÆ8¢äüÖ*Ş«’o+{„îÛe)ôGQø©–ÏDIşO¡DR¹>4qo¥&´n‘éx±Ø2é7³âÊx‹R¢ŠÊS&²òïÒ•VÕN{N{qÔAøt E×O!ïı™'TÅ*}kGlÍéä?§Áé5ñ|ø%f2Òw+0ÑuÁQUÉ°ƒü4ñ9q!Œüş?òza€2õ¹_tFGpªÃ2î†Û³6i	ÁĞ'!Ù'éïÎ¢2:e¶aÙv×VX­w×ın9F?“	ö/¢BuµªÚ‚e{ÍVQë£äåd¤èå_)ã`Åoèˆ#Ø»['ğXqºGm/·qáéVì ÇëRœ'xE³jÃ±¸üíë‹e¼ş—”--Ë“†ô÷Oá ø®¢Ào_eğhÉ©ğRÍİ'TìBK˜L±Ãš£øİÃVAë4`&xµK’¨R.º5\>iSÚÕ•å§ŠC\=AEÀ@Óú¡qOõøè¯Àîßÿ&\Îqˆ 8£ØÚ
èˆy'Iáî
ò!ˆ¡v&H2Â…„cvÄÆm…^÷¡g„=-Îu¸XÅ Á¥]Iæ|Ã•UÚG%r‡u¥†Øî“åñúÕÏ¾ìÎJ^t—CÊˆ«Øh-¤Ç
»"lÅß„õÏÌ{}íOSM+ú3²uü	Àw@A¶_
Êc¶K9[j>éÎ®Ã,a6ÿû76ÚÊâ Ávqu½¸v…„ç²¸£zõÃ™Q–ş*=ëXÂ;ğ”Şû‰î!U;8	ØNf³±£À7á²<ƒSEÔS…»ÑŞË¬ø\>
®_§ÓréWÚâ;›döX	)BëÇ –³âEiÈÒ«uš™*#üsOO(fDC›Y·-™ğå´œÎPĞ,“´4øùšŒW¸eàâÌ²r3‘Ç1R•)M`5o]„¾¹X‘Í¬Ñç6N)Ìu½†Báâvv9–É­•ÈÖbúzëù%~– ï19æ¤yÊÛjJê^ÚJÖsĞ/Eåá} AM½nl„Á’ˆG†ÿàc}7Áéµä#kÓ“fäÖ&œß–'~IH@Ä)ØWİAÿ
©OòvùD¿+/İE³j¥˜·÷èTõl0÷¦¬m¿ê"ãùÿ¬ WuñÛTü{İ£¼.m–z¿@ãié•+tÖl Äº »f¼Êqˆ¦ˆ÷äĞ;¢Ö1³?HÔ7_Š•Ó{®ğ˜ö%È;à;&!û·û'j¬Ì5 ÷!¢29 )úãŒCõu{3E0|¹‚ğÑƒC_ûCS.NçG’)Õ: î¤³Ùµ¯’<á´c„üö×8icü¤€ÿßƒWüxüDXES=½r)ş6qkÒWªä	÷&3?4rjñù‚n'ïb¬r·‚DÚ¹SJê	š¨õ†É¦]Y°`µ‘OcÂ Ñn²â;m¥˜zG=ê~2×VLæJ‚Ïš6êËïñ‹ãŞèjqŠ×!ChĞ‰^ğs-«ö_X'şå<~7@—ßSV ’Í®Í²ŠæìßslILb…–\âL@]‘İêªª÷º0¡ş÷0LÅ·`½cœv‘Õ@Qáh×tA³„ÓÀ’’“²Jë(©§<,V©9€1Â¥½dŸKzO—Tc‹ÁêâÉÔÚdp‚óô¬t	ÜşŞG2JGÒ1 ¶aé–K–¢¢a²˜o8kƒ&¨Qù†å÷zF}YÚ'É@òø¹¶Ÿ«-™.ş:ZŠEòİ7[>½ßù™Ú™úô[ØYL·1mœ?¸(¡YO®cÍ¡~-SYbƒÏ{“éùÄ“zvM_[	…l#ÉÈe3õïÈzÍ¸O9ÙM¢õbWÔ™¿Ş­æ~ÙîáşZtpÄı° ïó,Øw2«ô…É(Jõˆ¡_É˜·Or4°ë‘­9 Ù=2E¸¢fñxnƒ[úeå…¶^|Z3šU¿ÙWë_Ãˆ“ô”åJ‘¡˜×tBi±’šù##ú†ÉÌßĞ‰÷²b#§jÕO(¶ÜÄçbìp„;[q¤¹í~Q<÷Šw†úpÅÏ¯ì"ŠhšÕ•?Ê¬Ã…ÀªÀÛ¸NƒC éVr:O•[HÒ«gLD|¨â ëŒ¶V|#tÜ'l¦A#Şaò){øïŒŠ+ûæb^ğåXŠ¥ô¦¾ĞR¬`¬'>°´gË*›$–ı",!¯/<etI+Íıo Y¾S×LÈ¢Š6[tvëğB¾™õÃ@Çz¿Ê¸×»zÙSNûïFqW¤hE%0ôaÒ÷ßï´¹qù›É‘‹=’êR¦Xxœ¨µç-Ğ3c¸(pŠ úi¿·Pö‘xßîœî'BÍÆÙdŒ4CdTš‰¢ô[éôT,‡/‹:¥‡ØöÒlzŸl˜Ãq®I§ªÁoÒ@ò‚R(ìÙ
J<t§MT‹‚ÒÒç‘ÜĞĞóŸKVà‚a¯EF/RÇ}³±,0/³­ÂÊ¬­»×O^C$½\Ò¸”ÿtBÂó@w\ ‚¾4ğ­{¬Tm^qûxšç‰ƒDÿ©©îñÿä¦¤ Œ4à°áEoĞtVÂsVÓ2şZ1‡ñIĞ†²„[ex‚ô€'JŠ§±›>X±)Ôh¸ôS	“>›	×y¸ÍÉ¯7-/ªêM¯`V¾bÉ“Nãğ :Ì8¯”ÇNÂEØ°{&`¹{>j`ª„Q¢“”¢×¦w¯t"pÎ‘hÎ1¿Lûªâ;± Ë¿ó47KDsÕhÛÀÎ›äc–²í<¢oÑô’MyÑ|aüôxÃª" gØ_q q:X™¹<a 'üa­ÀÔ9¢¶ŠøÓJ™VÙ3åcêM<™Æª Ôâ5Øæ“£åPÌÎGƒ½±Ÿ©-¥,BiJ¥æ'ğ¶¡äèv†bÉûYóøZŸIºÒû&Ô.èeä/«6Š›ˆvúju[…¥‰9bŸ]<í·âR«w`
²	šAéË¬ä"ÄÁñüŞ‰¼;ùß/Q•äŸ>i¸ÄÉË¹6eÄ¤^IÆ–|eÎ5×Òm¢r‹:	…·[‘<ò n;¸t“­ Ä±#^<Ùç}™‚%ğ \¬ôÌîäpc.¯¶vì§'í©í%õO†,0İr=Ù¢ ˆ¸>ë3ì\ÕjçJÃj6<Xè‰7ŒŸİ¬5S;hŸÿd0¬˜ÁQÈŸ R,¡mÏW#G½#íÖ}]Ç!Jí606ŠÑÏ‚É¡ç´¨ªø¸&Øûş9£×ğş¢å®4Äİ–Q'ÙGË—ÁÍ<R[Cº±ÃuëP/ôZÎ&¹+••K(‘,•Ä[ûš°ß•ùU_ã2!¼Ë6u5øúò À;"aîÛ^ÚN„'9Bi‹/5¦>Ì.¤/â+J¢êTs5ĞDæ8ŞĞÒÈ4¸NAàiÈ†«4{˜÷îW¨c™ÍAëÚ¦¥#É9´GäuËui7½Î¹ØûÎ?×êA8æ„Jâ_/Ö–½£k[ì®ÒEû£…ëS1¾’®ìš—¡iÂ×¡OùÇµµ¬i€…sƒ:]€d„V¦í4j”.Ùó7Š‘(w@•e%SPpU’Ê¨>—Ä»µˆxNºJDíÍMüR5şvÙN‘5&QŒ‡¼ºB¸q"CEñòÅ§oƒ¤}oJÈñäãÖ"^ÜÖŠLTğ‰çêf“¸±³D]o‘Ñü¢ÏkøiÚjˆc.ÁÉK“)C‘]`õÚÃ»Ô¨çÎ€C‹9ıü«oA´x:Ha°gwÈx,ûak²A`êzšn"Åbÿ&$?¬Ôr4V+ûÕ©Œ tok¨AßşGĞZµ;I¾cƒZ[³i†xè£ÖèşV”¼{#¡1 "H¿×Õå›fD!åEPÄ­Jò”P”zCòA*Ç#aä"%¥ôs9(Ì¡¡òôW…FÅIûŞwÍf?ËO@½»ĞX¿ùŠ/#i(<&«
˜tEÿ§¯O¼Ad£wïªü/Qñì3ªÂQ®¸#²€òWº|MnƒƒĞåfY¶Æ;ÚT‡ôı006kÓF²E›­EøëùáãrM˜ø½)‹íGN“®Y¤Hç [?q*4ÂH‡ò°ª!È“)ÒÙûê?&©«!i4b×x©I‹–F²§¼­‚NüÊƒ¦p¾îœ‘G·Îqî@-üæhG*NÁÿÅî¡Ê¨ŒEô8n§VĞúß˜œné?r
2UmëRu|7éZ‘ÖoÓÉéªYnŠÂ2Vù]@Rkqİ¥zsåÔÆ£CSQkPè­§-šxô´·ôeqCÂl¤aêïÍœ˜nd¼;,€ª¸šıµN(ëg1ìÉ®]ªqnó`<èF¹`^—ÓQO¦ñ­L-ÀŸ†	CŠ\Ú…wfğ”“•®Kà?ë[E`B!ÂbFm„’0ïœïÆÏLÈÎ$l)­½ÄŠ˜W¸»p2odÕÑŠn¸Æ“ íziĞıl¤o¸È)x(S\å¿“°™HZ`¼è\º‹Ã€ñ9<‚ÈÇÀnqù¶pÎÜø°s=d]-5ô’ÔéZÖ^ŠĞ~Ÿã6îK2|C3İ™¯ß,½hVíJ\†ÀàÌ¹Œ €Ö;Æù6Ø;IB_‡g÷Û	™øª?N†TXÖıçæE/É~8åÊreñ’	_ ó'BŠ\“-”~ÕmğÄÁ~$x33cVRmÃû
ó¼¤^‰rA:Z¢öP—6Ô jï½•8®?j%ä6&WšUOÿw^dO Š‹V÷yn(jÂ `€áĞ¥Œş(¥¿µáàÉCd…·dº”Ñ­c«˜1ügÀE *øX–5>ò-@\¾5‚xù€}ƒ)76
´H`‹e‘e®ë%ƒû×FL¶¤GüÑ°jiOÀMlÛ×??›À3ÖhèèßJì3IPWF¼ù ü{o­L¤´• jÏµêh[nD,ü•%U“A:1à|iÄUSƒ4oa%•:)’ILô»Ùâ„9+â;5vğç¾àñ–ØjÏ_sÀægó[¼Gœ"W1|×4+à ÇÊ)F*J€ÔÕ·Œk€:±)m5b3?Ş_ #QêOO›DéM¶1.±İ’‹uBÄv•D»õyˆç—7Û)"|Ôm†X‘€ï”tê¥–«I0óä8Jø 8$ k»Ğ^„¹hñ€£âÇbƒÏ1ú‰({N™UüµÀOƒ7åÕ‹o¬¿×³ô4™‚€yM"°Æ•°Ú;“æRv^îÎàßªİ[Åœ]BàKùî9·EÉƒÓbs¤yÄXáb<K4i-šçJ*B:rñ
mñ
éG&ÖÊ˜»ç(„_j1¥Ï«cØ yˆ~â¼ã|ä )9 b‹íáR‹ „±%–¾zçZÒdi§ö-§BdÑcó”C¾œG(Ä‚ğ—vÆÔ…š‡$Ê¶ªˆŒµº—BEAKù1	¾’{¥s$ ¿æv)—±Ñ,}T˜ñ¦‡û…š¤Si£W	ìı].7këµÒµïÒ«÷eî«¨‚…lûtÊâ0#@(¤À0dC†:ê×ƒ5ürq}n•lBîs]¹­Ş³Ü3ŸMßJ‰£ö¼dsâŞ¢¡Rª´¨ëª¤¯qYg~Å‰üFáLÉÌ @ŸÕ_o%&ÕU3êHàš ñ;~½)õ>ˆ	œ-9!OT40¡¾¼)^àÔ,IÖ·—`ß¢K’4ÁÕ˜Ièål¾´q}èğ%ZĞD\Qş¢®çaäcç=†æê§?ˆËR³Ïí²¥jjxX2‰–6‚ƒ­3{BíœöŞl¯\`ëÃÇã ‹İ³»­Å‚é†JòLÙuóó	Ú]†!"e«°|ùÍ6¯`'Uš.—U¯$*Ö; ÆDû,í9†V òğV¨f¬
‘la%88•æUÄcÏÿ‡vÑ„b´‚•®–÷‹!E½±§ö¶¦× VD¸ƒ_Ã÷Û83BS´æªc‰Rfaä•Á¸àHšl2h, ŠnBiZhl³>åRîºc3yŸlµ”û¤ùo’Îgi¬:÷şç\8›¡©w’tæA!½‡?:¼äT%åñà%ßZ)Uduç.¥?œ›xÁ8!»{ëlÎ…ìR´*Äâ$½ÁõÁæÑq*’¯æhd,QrÕê!¾şò)\bvÇÌ/FO³Kœ\K ÎcÄ¢İeuˆmZ]Ô4Òg¶Ö­Méd^rEùC“6!"JÁf‰Pt˜§…á(®,µ`i¬ARZĞ®±Z²â†H}Øª€ä¦@Ï–Ö¨üyÛ·Mú"ªç@¢’Jk~kÚ#;‰¡k†½²ÇÛ``ÉâCª”Ïã®×ú¥Ù õa>Ğ,ÎÁù×WqàƒÍ³ŸŒì”PàŞ5iªXy[G3<TÅÈ‘êzƒA¥¾hfdh"QÏ ƒ@*ßÃ‰Ô}şÄ(`Õ
€¶ÁöŞ&åCZ†±eÂsL`ø%ÄE¨Õ|s??‡ØÑ2“™¹vuÙpŒĞ»W	)$Şıt¨%iŞ8·5#Šà™ãLAáU5²Ç;2Q¶ ©ä_Ü‘ä>“Nà[¤ÌFİÓŠMîÆĞù@«{0Ú¥6õÈ°€¤ûÜè8VåÊ?Ò™Íy
„Ã9M
ƒ{ã8çÒÕ¢28*Øuù7ªöÂÑøª¥™ºĞlß3A)P×ãX”;!ş-­Ñ^Dü2FŸ¹´SXí‚)Å³ÿN¶®¤XPŞåÇ$/×{ŸÎÊc’´oÏ¶{*ÀW«'{¼ë[ƒ@æ>I’Xå~4(Ñãßí·u¨ÔÏœÚúhúÎÿ¿ˆµ×¬dcòO¨íz7…=Ó»ÿ_9>Æ«=Ë¯T?öï <ÿš.\+2Fïñ¼ ¯C ±ğüİ/ì[R„ü`šŒ™P ×òïs,Ñ”ü:åi:6Ù«bËÀRPcÛŸ¢{"¦;CƒÖ‘z•˜+ï´%ŞÄM1îõ4ÉO¸°êñ¸p ìD
tÉ+ı¢DÙ!gû·ä±/–Òí­ÏT(èŸ®UÎx]vñrÁ’îŠº ¨À”,f®˜—RMT\2Ké) –Ê@l/Då{w¦ÎW`ps³„"_
ÂÍÜÇ-0ıÔ¡R®Í¯Ñ®5ÿÇ+Š‘¹«ÚÚ¯”»Üx¨.ÄúHúW*ër–€€¢Î£ZTŠÒ(IfrúÏÇS;¸7š"ºg³7UdP”¦t@Ò¼Œ½ıO}ˆKŸŒ¥™{ø ºGı#ªÒÍLz†îm©@€Ú¹­ÑÚ2êıä ²H„}[%_¨Q?+³´ÆïLY¦;6‘ãí*d„EjŒ…o»É4:ÆS²Ì2Ñé_iìš%¦šØ›uŸ·A?ıºEPço‹—íüÈÏ×ê	$,%€‚fÖCyX?Òãc¯tFöXÿ?|Ã
)ÉxvC#=)D(/¹‰Ú.ƒæ«F •³H 'b{á7usWÕ11½H'¡Gm7Y—¬õ<îVEÒ»×’Ïø\htjÚË²ïK–5È…WYPgæ	4R·%6£Æ<úüÖêÙæ_Éš½_IZB]vpLİW0t?¥È†Í~ßâ¢•.zìÉêàQ„e5Y°å	%Ÿğ¥oy!ÉvAÔe‚•JÏ±}j^{Õe#( <©ÏæKÖºİÜm€éQæW§ˆÀ³×»µ˜‡äNqIöx{ĞIÒáÚ‘¼;ïweÖ#"Yµ½V£öì÷ÁàŞû©F¬ıˆ©”,z*‡œ§'HßrÄbd9*|=˜<+en;‰.Æ5¡fnŠ¶Ls/®Şì?ÍêHK·À*\Jv÷¾¹¾Pñ…ƒ•Õ/ò«çuÑ¨.9Ã™ø®Ô:oË)O¯£¦‘Ó‘¡Ö|šÒÍ£Fä£@&pÎ¯©-v½T
„¦„3]Ø!o=—_1ò°û¬xevªøÉo	3­»Z6ÀR(ú—2TÕõç2waù‚MÄ++Gù—Q:ÒÜj…“5´4fĞüßôıøwEŠş¤5lòé‰‹qŠ†áIx¹÷%_Í¨—æ®9i!Ùyãyª(ÊÑ¼Œågî¬.AİN8éëğj-‘\u? ßŸ€\™^fı5ŠEÉ+BŠ2%e`i‰¡¯úí¡Ò“úÆ¹*bË-Ö“/1ÜĞJºM~Õ­€“ÅôÂ(¡8Ãµõ…fLö—íŞ&S›M?c^H];ïl"Ù4¿ K’¤ß~ç¶=hßÔ,ƒQŠ=4öäê~“HàılÖ-ñH]à9ƒE7E ¨À+bÁ˜”¾¥6€d¤”jHWàXõÛoNüEd!ãZš,‹×Š]yà1×œH	É2ìU™ÇçR‰ õ!ñ–-láìT¦İ(Ñ˜#%5´üÙQ©J!BÚ9z»CTôô	^ÆsnlöØûk4ÓÂè³éy+šîuüFö'Âîµğİ$ßlØƒJƒ‘ÖbNÈ°Ü=ã¬ÜÍ U^ñ[Ê¯CÛ/ø­ÛµmO0j¹ÛFS–B÷ˆ{Á$cï	3 	HşuªËÂ: ËÌpêb‰$ì–Ë.Àv¼zèæ4`geH“e'As­âáíÑ¡­W²gˆ-ãOÏ¼ØAÕÚç&1Z,]ù¶Íµ‘£\Y ñÈÉS2C&•Oí£åWjØÇİÂ¿–F‰_{8U£Şx2 CÍV;”#á×ÚEÃ,C9ûy¢ã¥oxGRûĞm|OlÄw]âJü‰ˆJôMHÎ­b*y+ğôÅ_èÓ”òà±ä’–›øÇ”µk$=†ÄÎFª"_€VÒÍîëÍ¼ú!‰{ÇÆe[Ë#Ål³¼‰ šõ™¬²Øã±}l¢íWUšë”\y9¶öz)›ÓEåÖîùÓØä‡†/¬ŸÔÉ­Z1K,¾ 0<ÅÅç¢,Pnïm7ÈFCpoó†š¦¨pâ `Q}Õ3Fƒ¸UıúÈÜãÄcU<¡ie±u^½}¡Ágé^v]ÕoıÒ§—%ÀÜ¤ŠÕÁJÿŠæWP×ñÚ~?Ğµ¶³2\ÆÌÒËÓ³Éß>j‚u-MùÒÚeãü'‘D__kŒ±ºò>°f¼\ugÁóWê›-âK£›oIEÜ,èÚ÷ÍÛPkáåş	÷®²ˆ W@äi‚ı=Fyâ¿m|œ¹ûtp]ä’Te}öJ@hhÑeI¹¦v»”­jğàıú3ÕúçìáZdg9ê…r?æ$ßşŸ'Â­¬ymî·u#éÅ¡ãöæR¿M ş¥»‚•I‡µápÂ.^%—´Õ0-IQ³ìŠjÕßÔOQ6gcn´»Ôh3•ª|*3X•Ê«¼úÄÈÓFAå»Šİ°a/uœšxZ5­ç×‹“ñB€I	Óúxã
ç¨]öÆÆ–PÒçÊªœŸ4ÖÏ)úØ›•­(xvéŒğ}3ÊÏâRS3~ÎL¹æq¾¼Æb:Ú DË$†ºÊ“¦nË¤Ç×9M´n³ôh<S„‚œ`ÒL8Æâ§'¢`_Q'@È5‘<»!Õu™‡ ¿Û(‹İ³w{>UŒ§ã‹/o|^,$Ë!»oÊˆ&'W|F×I
ÖYÃ¾TRq¹€]¦¡’K®§“à-‰}&.‚´?›UÀUz¿ªWoğ¹@£›îöBÂK17'Ğ(„i9ö+Ë0©HWƒS²ãû:5ûq¶ùÛÙ+÷K»xàÍ¨H¼'&Ùœ´’[ÚÃZâv:á½Üş¹Zõ!½l¤I–@ hµØ*ƒ	;­å&xKàåõä_`G„w$!¾Ã&R‘b÷s ºRèÈ	C’ÃîSìvjXùK¢Q³D> rµJnC&ë0¡W
ö†SH¤•­
'â*™»CÉŒF÷i~”÷3i){ŸÒ³«7k´ÍESho +·ôa™œ_ÊQÄØ¥ÖwÁè9¥rŠSü]y*qm°¹şLSªĞ‡ÙCB^ÉV½÷Î‰TìZBl?§€-ıã­­÷"×yş”R£ìŠpy¶ÉİØQËá´=‚ëã¤Ø¶™bêpR"`Ûyñµ`GdVMjŒ%9<ÖİW®n^«ÂğyLŸ­ \fNş&ÙÊŠágk¨Õ—"p¡¼)NÒE0-–tU£‡‰ÎxËo!ŒoŞC’ïçNVBÍkãÔ™p[@ê¢ä“ÂPäÅ”=fd·ÎÿZúr²-Ê
Éõ<#½™š‡^6fq?Ü^66ßfK1²Ğ3RÓy'‘+ãiËè?.’O™iæÊlbÔZ²õGg‡QF“ª€º”Ÿ«€fË`¥º®³#Ïò¹9ã"k2ú	É ¡Sáïro„N»H7ß—Œ|Ù…¤€hy‘‚Ú¬/ê¸-Î R;D\ÒsoÂ'™ˆe›^EwS©,‘şù¯é´Ñ °vmÏ&¦ §‚æ/õ{?O_G•®…t~ÌR`úFr©8ÿ¢·˜r:ìğï—]k3²÷šÆ½`Ù5	vè}$SÁß£íİŠÀÍ¦@B+ßÅÑä7ˆMEşz_¿‘ªîGd“üƒª¨Hş-öw1y„DiÛÌ­¥C1á¡7ßùfKßÙ]ÉV	c»ª|m(ë¥W­ “d`ÑãÅ…ä)Dó/ø¨Íé¾õ§Àå4/Î#AP	1âhSY•–.oyÛoÄÜ÷J»İçÇ4¤R8”ÏÛ‚ı&Ş^‡5´ZE§õëÏU?ëÈ¦ÆnØ‘uÿ:¶¯0÷1ÄSó¢ïß0°vÉHpµ"Â÷~o6Yû`«@X0Äµoø»úQZ]WÍÅbØtşƒA"öe;Ã‰Û4p5ÑÇMºo|P¡A½X<İ¿CÈ¢X.)Wõö$eJ§„C‘6™1éúŸ"#•%;IÜ^İeQõ=ÈZÙ‰şLWsÛ–_oT›*Äx×úõH	m¸š,)ä¼ËÂl>‘·¯˜Ó)é›	yïí€£8¶YÄ€ZecR^ˆ¡tÛW—@ËŸe Ëã%t.?]ëÚ Ê™ï™ Ä†±gëZš<(HgÂeîs’Á[:ÀíNQˆßvg¤¨ÚB<›õ¿(ø‹ıêÚÏô5‚0‚l‹­µÖQæU‚Íf–mƒ‰•õôâmÄ´>=4ä0§ÕîBZD²LıÒí­s½]_¡dS›O„8UVºQé›ıË±„‘>KJ¦ H?p¯ã¯_ÃoŸëDu3ih|h¨ê+ıˆìn"dêf@}ì¬`"ì¢Š¸?Š Ixê½–‚–Ê?§¸föJóÏ «Ÿ<-[ÇÆ¢ßıLÄ÷‚şõGFíw@†[œ
¦p²wßv"4³®ËØn û°CIîø>¹¬2ûx@*:~ÒµÛEWe®i'Á÷ô¤ïGê¨æ²ë†«g¯Zi£ôWHššÄØ­l0˜-fr '‘FDç'šøø›y¯Íå)VÕ„„w¢…¾ä[òÒC²| èÈjË™Ô¿j½jn¸,á×ûä|İiÔRU²U9„«!N“k±E	Ÿƒ	¿aÿƒÊg«µ©-î÷dGúc½©f2“dö4[lànÇ|îõ³ÔİŒ±¢a­3Yud-bßÒ‚µ˜"H[‹Y­¨D²)ÍªÚÜÚX¦Ú"K!,¸5]dtÒ½º+£ï”ã »§(Ğ¬–®‹yÄ}Ç‚/ÏŒ‚g„Å‡È¥j
ÌòÃ< øVìDT [m€ß-Í`“Ór¾{ìçŒ:´NoÂ
î©ŸÁÎ¿Õ/ï–\NÃp¥±İr(n~‹ Éü¥C…¢‹Üée "ü±…ŒvÓxMó¸&¹¥®EÖä×#èXü8`„0ê¶7pŒ95Qƒêb$í{êÌ2`oLö™J±÷u{RŠ‚Œ>%Ãx°× ¤À‰Yë»f+´bzï£zã4TÏ÷÷vƒû)$QÀ¨±;ZÉ¼ş¯¡æ…è§mì·ô¡sBÚ
)`º+”ÏƒF#jíğ2eõwCµ%vHGÊÊµ˜¶§ø‡<pˆ#
;UR	È‡ê]MÏŠ±Š_ÒÄŞ­SğáÂND®º#:ëV[O—ó?óõ’ò“4Í¤æµÔyu”^Ä7RÇ¶ŸSs¨Ë_LOøÑ¤Qk&tĞÉ]ç €k×I1;Ôğ Õ(z‹bÊ¦ºÙödåo™¨ğİƒµŠÕí H`µÍ”Jg\ÜÙ¨å“ş¸â*ğa_Ë
Cã¯´['Ò(9l‚U¨o;²¶Ùkÿ&ï'ÊAc€˜[YRRÜQº=™ìÈ iHfÆ^+Ë”}>RãÔ­|ÉDšoÎ†¹é/U¢ä·ÕÎÂ1ğÕÆ?A"¡YÔÛBw^ °(4‰XRB­dÁWsQÍ½ìÌTRäi§T§ß¥5ÏB”ê¹P|Ixö×u:UiˆÄ7õîØß4ˆ–JÆlæ‡¦‡qlìb4«1»V´©_åëLóĞ¼h)Ñü°ÿ‹„1şéUşÕ9:fŸ³ ’Ú¬Áò^°‹¸ª;ÇnÅ.\°ÀğGü¢şL)åªlFÒÜIlk°&° 9NÒI[Ò‰Kò6gŠœO5›a”­¡Ï£ºj7IÕª@Ëñ{xĞf]Tï57Ù’—GvbL>¸Í‚ôMµVì ì®	´¢»z9Ä¸†|¶Ç ¹TıTn&_­k×é<
+´¨ãîÖÓ¬Ü…
~-ÄG×³?Bµ*sò5‡Êß¶W­¸£ñİYù	©ºtë~âIÛzÁsIWßê¦pl¤oßN¼kÌì)¤³ş6\‡£§ÿå¥e¡KÖ³BYÑ\0cÛö‹Xi$@!ÊƒnÈï¹M€ Û'ù¸Úc‚-ãÈróÃr¾ÖÂ¹Õ³r.š¸:îºsD~o¬»-1tÊ_Ö.>'ÎñxPuA]dzŞ6RUÆAk¹é(”½³›W´›™ó²„`‘¡|
#@=£Ü£6…­îmŸä¯m|,k)öˆHS‚‡k8ö/4k]×àÃ9dä‡–Š`AS:ï*>¥òI¼Ö¿fÒê4WSÆ$á^tOåOVjS`¼6³ò^Tõ—;‡$6V®ŠŞ™U“iÖ*GU½}W{"\o£Éè}én6—:Oôhufıï?Fl"yµ†\ñ­Îœ*e($%hÖÊ6ˆÕşb^>ên+CÖûŞÜ$Lv4j4UæQî……²+{[šQk¬{ƒTÃC^Ú3™zrØ¯ü…æ¨„ñÒîu§ÿôCìşÿb8{î0ÆròÏ7_¹Có¸:Îi61. [Æ¦_@90%èµàÿÓI Âµ`[s~~ä£ÂE¿Ò»ÉÜ'ÛĞÛ˜dh!ÅÓ±bdhiíW­ü´`8´70àˆ½Ê†Êf¬]Å7§-$ëNv¤6;|Ÿe+ó%>Y5èmÒU`Úw¹ä+ô_›;AvdEì.äóÿu÷­ˆSwQGç%`Õs@<É*?çÓd>1Q¢—a8j9Íg7ìu=…á€BÔú^a1À£›)ÕC“äû§Q\ïÄíÌè	¢ª±âÈÙtšØ«ãw.ÈÄ_,@Ÿ¤®åğ\¿xÌ%ö8l¾€	'áõüV®¼ÔıYghØ4ØÛ>ß7UÆşxÛ¶Aµ€K¹„XìófLŞVÚPq‚."2šPn[ò+€Ç@7Ól¦œW€Š˜·Íáş£|QßÈi“€#s}±2oĞï0> Bôr6`Ú¸§éJdPæE»ÈÍç+Qoœµ¡ K;qËîDSùo»`wl&‰‘ÜénM˜”,Y	pÑ<ÿUu®â¦êŞJ:€IãçqÓQ¿»'p¶2 çìë7o~‰~ndŞ?.AÏ­
h&›]}Ë¥n×vq;|e9=u&ÌZ6Ü1"¢PÏLBhQ•3N•«8¹X·Êl—·å1—jšC÷gª²<BóüÙ›í.Ä”M…+BkÊ½ÄªšĞ Ö0A‡\ã=¸œ#ïÓ=P½ßI’–æl½„±FxXÒà/%üåØ9¸zjµ¦ô†'÷c	•«ôi9I8À¶FèB×;ÏÇïX`M9zõÿ4Äş ³Aü6ØQ7e±ä‡àÃä0©bˆ¼_ÎÁ]ÏyÑğÜUÌT¬eÄÆæ—–6|-ä“g‚îÈ­Ëu¥628<F—˜sÍÊâ6=gk•tMKeĞÁÃÖö´ãšPÈñM·Ş¨|îyr½L@/ñüCH_Íb‘Lÿ0N´aá†?áäd_J‹2I  Sw0UÔÓ©“}Ì<÷àó²ò„’Y¢üƒÚŸêµÓä&1 aIj©bª*.J®°êb¸–tÁ«@((\/NsI†—€nŸË*GA€›5Å"ê‰y4?R²ÆÃWÍ gzÊÖN(Ó¶Œß£îœKlPWo–»ÁøâœHœ´Ë’É³fvüÒ|½=óÃ[Ò½‚ªt­xkÂª€„§ôÆ$‹õytAu™¬ö„}Rƒ»ìÿ-¡¬±w!oz1Ú+ËœÊ(ıs‹ÖÀbÀ×	pÄ Š¸v¢³ª\UÙÌ9‘¸«Ş1|Î(§5.êÁğoú2U:Ë6”¬j¨/pô:èÎĞ†ĞĞ§,`«ëA¥aY|o¤)ñ/YæcMŞ€À&´j§0ßze-—*m‹›àcVtÇD¬¦»«­(Q©Z‚oûØıà@À˜úvÓ-•îíËFõoÚtCúåÊ‚n:\ö;íÍg‰~”);±Àv€	;â{kUÏ¼a÷t‹k‚ºTDï¢$N8ÙÂ£ÅšÇˆ|Óæz×?S"nÎ½³«>k¬Ñ:fğıß°à‡Ï‘¸sÀĞàÍÏ_	ˆìŒØ³¬õû²ì{ú÷e²JÃšl!Ì‡{é&È>ÎË»ê·MO½T&R?k:'#µg]¾ÑÅ”ì‚´H"=‚ôRGšÏq’5ŞYˆd/b"·8ÊÛWî =•o"(+ï\JÛ²
·IšÑÅw+‹ ¬òjU]‘e}İ1*·ˆÉh]Ëbf?;ç+-Õ¡¾íp[îşN¹¦àô¬ƒÄ"¨Ş[L—·/=Zã±H÷<e”øbdæw“˜|y[Ş?2ÇÄoöì£V¨)Jâ„17ÂRa‘?ÕïÒ·¬\n©LåùÙ8Ş‘£‚Ézñ¼)æš ÌÙAJéïLq$gŠha~¼Jİ­ºœ>ø>A9S»j1m 8{¹DÑwÎùşğAúnÎÌ’UÓâ#šdWOÉŒTÔÌ6@õ4ıÖµ"jmõdÿ:MÛ)Œ/¾ú½œ•¦Tòñqí]ï.†3{©â6Qø.œ8Ñ˜÷¹§™/	ôñ`¤Ş€Òeº{HG>Åø™l—iÜ½u~¥0WŒÅ16h}FÆvær5œ;ŠVFiØ"åmR¦€÷Äp?ógqÀÑ®$ f?nÆys÷Dğ;–’2;İ‡`oÕƒéÒ]Y>ä3ÕO#é:Ù0&·<Àxš^º……ßn•’ƒnWÒ±¢Ùlÿ:é¬A7„î´Ø_¨ÏÙ*ß~+A9b/Fş‚Bƒİ¸&/;—C9¬÷óe6š¾ÓéVÂÔlæ±Ó2¤cA07şKŞŠ Á =ŒÉÂ­S¥H8'¥Ÿ9Wj°Nˆ[¦qàR9ó¢®F³™‚PÚv3c[öC(~`å´±—iéÖG"æm2²5k&óôéç”Â¢6à9Ï7]ğ©¾ëÖ-$[C»HœˆI/9ïÊÛçˆŠÇ£é`SãŞCp{{¸TNgÉ’Öÿ—‹ré¿ÿ…§©'~X?w&#2IØD‡Q „`íPâ˜kb»-Á@{¶Æf¥oâĞ\ú(í	“`üˆÅŞÅ‚Š¹^ÖÌä±.ıÊŞ)üREi˜4„„1®„BÇÑBêOSÒ>Â¨…!ÈÒ;€°¢JkZ|=œø´ç™éÇºUfø¥§î%ê€€SK‚’iÉ—*÷¼	l!·2ú	çR•Dcø«ÒŞ¨'wÊº#±
 L˜·Úœ°zÆ§ûxö¼¥Ù¸)[¶|T%¹rÉz˜ìğ+ÃoIîD¿¯~ù5#–\S|¸V³©$üK)inJß´Æ·öz_ÿ23æ9(·êG´‹” &ıB<¾1”ì¿õEµÔ9Ò¿­L¤^ v¸4½ÑOû@E3±\¬3qTŸ%«>Ì‹9ÂSï›íË­'}5«}¶ù?Aó&¤!2:ş<aè SI?ZÊ3+J²£É0^XƒaËÚIÂèªÕ6o¸U˜ûÄú,•‘ÄÜ$Ä[±Ñ@‰Õw˜Å®…\ñwn›°b@`)±¯Lt4Õü>¼¢"ÒÒe³(ùK}}{ì¶ÏqôÖ\u
óK;É€Vøu­{$‰Ş[@xë‡»7EXİugQ*›)¢Ş]ø{¢ô^ÒZ‹@{#Hes5ÑšìïJ’ƒ<
Ê,Ï@§Ñ-ÚpxòÇŞe«ÂØş†•!n‚úUU`\\÷å]2$¼éşUVÀsûxÑ›–y\àÊŞ¶¤íAõ&nø<[á1¹>¡bçw\m…Ûj6®×¼<`½Ğ6ôäYşİ³²\Ñ§‰¢Í7q¾êÉÿ°±o\ÿ*!’YRéÙ—±4Ú;m	p4ËÆ‰Õˆ®ššzX«N‘íA:(¾¨â¶ÕA£–g“ÈÍ—`¯TÅ,o·ÉÉ~B–/Öü–4ª”–Òµøõ"¾©¸ŞHù“(,2c½-üÛ‚Xín“ÚQZj5)Ës$Fƒ‚K·™…*<›PŞ·p2ãdÈheW~„³$]DºÁº=xL¡}®s›$
g`—7èßù®ø.
£òó^Û1÷Û¸AXöHoˆïôŠ	­.JNôÚAÒ}³«N!%p–W¾èAù +…Õ¹³t 0<¼¹,ızª‹'óàQóªm,:µèûUÑ,||×¢GÇvÆ¤\Œa–8«>“±Éˆ,p’1Ikñ5)<’ÇlXµwH¨HÎù¾42Ç.¯#«ma¾èä»Ş“ñCÅÂA×~ı„hóšÜ^k;µYoË“ä•aHñ¶·#œòì=ƒqğg¸í?R\@2`É‰V—=ˆï¯Š…LÂM€çvöË ±OUÛşO÷Ìgv³sİ0)Â¾ô¿œ²Âşâ¹—\Gg­–é†¯«!lñşLù²k”7Ç)+	ÈAh[S´´Q0vçØ'R¥)Ú*®±â~F•pİ\}ºaĞËûşo_…zWgèÈÿ¥0H÷Øe6xàçŒ›$¡#sı8ñãw¾˜ÖÕ| &Ø|®’8}âLì‹€Šf±§(B¥ É)OL<•}Ñ€6M¸²2O}­°êMÊ+X[
0%í0É4ŒåüVÎvÂãhNÉÍ$70ÌõÓk£»’ÿ—RÂ¶qcy·ıb¹* »ÏÂbãºóSÕw®‹5†I{U,±ÆúG«$ŠÀb>+eº,í3‚ÍÎ6ºWdL£¶˜¦úŸ3£ï]û9ù’)½ÒÜ]bš.YU.˜oßXBâğŸfÖözXiB·8â¿Ùã†X}Ø«õÔ#bZßTåÜ¼€wö$oMF>½¦ØjÅk·‡PhÒ)²	!%É3ÍóÛn%øXJŸr•ÃŸu~q-¥-Ğ0·d½å¡q}V†„zïñ’,;D§3å=7}yÄÚ®ˆ'å©=	SQCœ~g©ÉyAöj¤=ËùS¯ÖyrÂ°%µÚ|JüX§ê·ÿõİâŠ_6š„¶êñUlŒ9UÄÈªæÅ‡üÁzaiRĞe+ÜİØ¨Ğ rGÜe¥^ß ¹GfÜ‚A¦²ĞzêL»¸ú¢´lµ=¼Û>°º“Y%d;o9†<ù=s‚Çzè€–Ì%Yæıæe…¡	ş\ğ[î3h$d:ÒV€H@[ÈÖøôt™iQ¥š2ïùêFÚYRO*¶îU1yVœ·|i1Ã46$½¯jÍYË%¢äp"ï	™ş`çi¥'S¥]¿³íkLƒkÌ‘€{~p:ÄxZDÒZTc QÑM<ş–¯–#x)©ÈËqÄøûNçaM—B}*’ˆVn‚óF¥~ã“S ökz%V)ÍÔt“9pU¥m~Ä&Ê»Ş ÷~¸dt¶¹ïëáûTÔ»dĞˆ€>H(}ÍÊk•æD€ÔòÒÅŠ‰aß%7Ë) ğZŞ#GP³ãŒÄI¡¤Ã®å·â¿‘Xl„h~œ@©´i;“Bã@:¥m¤ßØWeãîÚÆñí¾aû5¾r–mT§#^·Ã×¤¦Ï²9lF	a%~tùPï½oşø…9—áe¦uÛÅ3*XÍ©üì-jmx`,â"&0İîê„7æ•¬şúT £’‘5Hö[Vî÷éñk\*=¸c@«èîû]Zfl,¦í.¹Íuòˆ3?ï¨Æ›K`<”~	.)Ù<¼|Ï5rE½£û)'ºF­´Ø”‚ÕâIV°Õ½ûH¡IïŞT7[&ÈgñD÷Ïà²"<‚XåeB@A^½×y<;ã€°§>’ 7LÁ¿k–²'©%Ñ§w¼:¿áÔ¹oAINb¼>³Ã?Vrıjq©íK$Dÿ`ú	Ü¦K<#«›MşÊA½au<½7©ÿ%%Ê	4ÍĞÈ	Ôi¹Z}«WeÛ&ìy¨~+ÜÉWeŞ÷¶?…ß’‹§á¼!g´Öû°öÛËÚUØúùë×W™ïFãy“$)AcüãĞÅ>j/Ş"·³I…ÇUŸ›nŠ¼ßòû™’?ëûÑñ†¾?‰M^Ä­túÂµÏÛ)ÄÌ 5´%Y‡Ml‰ûh3ˆ¦îlŞ7›`¯Ã=Ÿ;²œê^qÅhñúáÇ$”P¢¡*Š_!¾¥î˜]-‰­É Ÿ€bš[ĞUH~m‹vè·ş®$¤¦tn3ÁÑ	™}ÄÿX`bad¢š]Í
³+à.Õd'¶›â™Í£°è)¸ŒÖX>°ˆ(ËH9V¹ÜË$”g»VVt/èYÆM«…€‘éRÍ¦EäT˜HT²6ïRô=‘u,y$ëóÍĞÉ^HSpˆK§]Á–ş€Avƒ9xdTKOªm<.½¸N~çŸˆKÜ¿©1Úåâ }Äv019Ê´:Uc–¤Š-"%Ñ©?P 5_q²ÏJı¡n§dÊô»½ùÕBÆúU!Ydü{£5î}å¿Ø^lŒ»sôR…„†÷tÄ•˜şQyŒìvÂÔ›íÜRÑù¾Tœ©xşëéiÖ‡~Âcé¨p¡}àd¶O<DĞ>Çÿ8p];Œ¹~çUêğåå'ıßÈÀò<–³•æXû.åsAú„áSÍŒ¸T˜96ve¢î~ˆkUÈ>©ì#­^Và™¥–cx÷¨ šËÛ½”ï[6Vì$CÀó¼+¯ölK—²»MK6+Ê÷¨M¿Ër¥g6xXn¿\1Úà¼µòµ´<Ë&Q+ĞªÓôja)·4F_ ùQ„8ºm¶©1‡°İĞ¢2?|%®u¹=`2–õYaÔİ €ÛGÏ W$ÉÓZ³„¦ì-|\|…TTÄYå`Tİ*6Ÿ[b`’%´Âœ#®(µŒ*[FaFÕ.˜	ÌŸ1
˜†`zQ8äê{+©îÉ®‹‚$N3WÉÆÑŸã£ %åîÿluì«67x©B‚ë§¹/¹ğÎQr‘¸-ëĞ‹"Ağ5lóu>=Ïaµë«ĞE›¥øñBù&9_rhÊ­TÒh¨¨×tv| Ô‘©M1h¸!'0øL+eÂˆ¡À>ÎÈ\jXZÆ~—õ¯¸‹1}¤ğlW })+œØÅ5ßC™ë‚KN©·‚›¢æ†Gö ĞÉv„dòœÊÊU)„2‘Á•ÿ•Ä;8òUşéÎåUKÊ/¬]ëwŒ"°ìš—h×¾©ïÌÜ<»°|İâÉùAİ?î¦·Ñ©›+ÂU™ë`·U»…-?l_–”ş¹¬ ì¯¬,¥0lsCÏê¤Ó‘I¼37ªi»ÈÉkæ¼Î¬ ´¡¾zu©ÿ9b„ìc£õ¤ˆÜ#GSéa6åûÚ¾>'ª`G¹ÆŒ3¯”à	ÄP·šiQ1©MG‡ÇKı&‹z}qÿ¾–‡E7áj…Å‹cL]©LúËz$Ù,”GÕn©©2o¼²	FBüZ?¶å,«Ÿ¿KiæÁÂ2YtoË©òVêJIµ\²u~øò^+W®õ@ˆ§7ÏİîÅíç²±Rùg^<ªáôşPóDnàÉH®FÚ,ÍZÉ#QÍ®i)ú¹ÆÈYVØpexı[Ä—D»¤©ÓjØ bÃRAŠZjÚ+i}CXMÕ
­·Š…ùµgdcÕ^u­‰éê£ƒBG¿°¸´bä~‚e0‡­£ [‚K-³ufñÊÖl§s.	Ğ(BmK²¥Ş”7Ÿiåy£¼ãÜr'gï’_ıà'¿)CÅëÅÅ“›	ÂöäÏ‹=ü¦Ói\{W ¦Ğ•Çº¶·Ù3!¥¥¿j|kkS~©¯¡}á4EÛCG=Ì×Ug °élñm‰FQÓñ8‡äÿ:Y‹|ÂÛøşØé!óÙN¯Óûlc¦¿‰_{X1§ïƒ7ÜqH8‚§é~ú<SuT¸â¾ó½£ÒˆuıÍÕ;m·ïÃ<‘‡4/2Üoõ:c•¦Â·•)Ôì}ıÓ1ª+ñ±Ì$Ê2M‡ €:ØZ¥—;¼1Üä³<Sš_çaS…èğWÆùİ•ÕÃ›÷}»}-(­˜5bé»3÷›IŠixÙÜĞ¾ª*u6WÃ´+?æcĞC»ãwşê°^%è®à’±òJb¢¥ºñşoÄô£›ö|q"–<AÑ<š±L¥5Ğ¯ö¸0{7´?C	A!N¢–pµ:_ƒ’íõKr¦}ZZIÛĞ;é@¬Š|3şÙ&ÇÊÇê×Hè”¢€-;|8\şî+İ}Ş tÕ|À¦‚°C64şs¿ÙVlÚ‰Ş$ô–VéY'aşNÂÊqÿF;¬ã~Ç²vlHA¶óEÒÉÕ<INDÓCÇ^5ºÜØ*œ¬4ß_ÿ]^-ÅéŞ¡çòÜDƒ)ÒY—Yì}ŒÕ¶u¶,ç#¾DŒ}Iúv;b}àó¢%­Köo¢‘Rl›H¤Â1şU¬´^‹_x‘WGnĞœ2)§P`ËFUö	Z™u¨3‹G^ÊtoSX©FŞï†K<ñğ%ıg_CêÊJtG­Å;C±; dzâššZwºS'ÅO73˜¤±¸³³s`„€âá ÔÓúOt·ãI"]ÛpôòøÌ)^†¹mi.€È°’‹Öömşn1ÌgÎ9ÿMffWcgù	vb´©’L€à^Cºõùƒ·bÔLŸ7‚Í„ôk
j»-ß…[fg\ƒóÇAæx‘ÄÕïŞ´ØÃ9íä–¢ïRÇÕ[@˜Wm1Ô@´ğ”Ç>¬4’¼€— ¹²)èç­˜õ’„Àön}fqï{ˆkªUc±wújŒìÓCß©™êí¼HÖfkë‘)ÚÜÚÀ00A“'Ó&5XDoGà
•`áh{ ù×éûTnùÄ=-â<‘î‘)o¯\J¢öEo<¯aC
6î­ş`ıôÂÂb¿„~æRÌ^?M@T‘ß´÷ªÚ‹¿ŠY©‘„º,–~ï©ÕÕu‹såà2œõÚ;TÊ¬úå&Ê¹ÇSü-6¾í%Ú ½»SÄ)IH7T>ƒƒ h¾“ìe¥K*òœ¼GÍ
æF |ÄÈÇ±ÉÕ#7D•Ù¸ÔM‹c²Š² ¥’±~«ˆƒØy°ËÜ9;5fZ¥¤WÒ‹N/_`sÁ"Q)Ê@©TÓíóÏLãM²ş<W6EıÊ¾£ÜÊ„ £xæ 2ş7Ï€x×ªidÑ bƒX†™X}p~šâuŠv¦Ncq‹¡Ö2µ¿j#{z§Àd°]Zù¬ˆk¢¿7MöG«”´Àe2;ù‘ü]y$Ì„J‘½Ô3óæ“R˜~’S'ñ‹Ê‘ƒÛ%lŞó]ßşC‡Ë%52"ÊHò³\"şó8ÖÿRt‹a‹;ú‰Ñ“í!h¥Ö§—e°ÏJˆÌäı¿
?×ƒé©ñE»šÁÀó¡¦˜œ”i£­ÓÎÇÕC‹}T7··“àêİäÕ—<Ï51k$šNO«ú¦{svhôj2)ˆ~ñª]äk¡zø-“²:¥@
ç…ë© «™¼à.-%‡e¦§íB¨3õ±¥æÓ1q¹½{ªâXœCT‰Ñ+^eM0C>’ûUN¼6¡n6·ÚÂÊÍ¶À`ñw©,Ø<åxq1B¿sAù|±<¢3¯®şJİş©©¼a‹ÓÁÖ} hg,
€QîõvH–«tËñ,º:ª?ˆÁVÂ»`+ˆŒ†Ûš¡MÀñ,o>¨UE¡lŠ÷¬ÑÛÁ^€LO@@¯íb=‹OtÀ.ãPO¨Òƒ‰kİœÑ™~|7{ìÒ“—×G¾·:)?‡'¢¿{u7è?“OQ©¢Dm
eÅçW¾—3†>ß|âáßÜc?ÍÌØ[frÂóH“8vñŒ}˜åNÿÙ{_]ìP{¸¿è;Ã°ºaJo‚ß
2ˆ¦h"ËŠN c+ğĞ¶,pèñª!DŠ-ÇÔ”;O0ÚŸW ¸æ*X’
€˜“Âk$1‡ƒb«9¦µò1ÿÑèİã=4SZ[©/S•µa©ó"ŞÎŞ¿ùéŸV†RMı‡Ì‘ÚèDh£`{“t°l?Õr”ó¯
«ÚÇŠ¾ªu–ÕÈb3•Îü3{óV–èí¸%R8ÓªÇXÜ+Z¶Q¶ŞQUë@tU…"m×9¡ìI>?Wÿàâ7¾R.€¯Ëÿp¼¢)úãÛk^IÇ6™KWûÑ¾|_ Y"/EØ§ãÓ"Ñï<AYŸq°t–úl„š¬¡ş‡¿ŸŠQULÈó¹FÜ7ù,ã°R9MÑ©ÿUù¾˜mÒÓ¶zÚs2$ùU„‹|¥â½qêæ†â*'RN;p€bĞ")0ğ
ú2{N‹®) ëÁ‘s•PÉ›A×Å6ù¡]êÖ~î‚sš1Vv.Jn-ş”Iæ2+~¼ ı4èGºÄî§>tÆêwÓêåCBÃ¤ï’åÂ÷Øª¹4ØÔ:qı7¯÷„Œcq" ±Ù-âªüˆêÚ:´şPLö“‘}nß`¤^²^/Mœ.½JCÓÇQ¢øn#vûË‹oøGlï^ŸÏµÿÒßNİ5ÿ•éš+(Fp<vô	•=»kt¦ˆ„Œm^¬ÂæC¶öì5¤‡R¦ùŞÀÈ!E\IDénˆÃH ’óYø Ô)‰_ÅÈş‚$1õ©«?Êà›Ãï~}hïhx“¿Ä ç00oRÖé°ƒ9ò¨Ù©(mA-"×‹2Ô“‚˜¾,àú=Œ‰¯D®rš¬VÚÇDË¼kú4Eä½Pª)¦&Ìº£ı2?“‘òpXğÒ‹wvB÷~I±9+“¦—J1_•XîÃğë¯Nw?ÉÄ’±vŠAl¦QÅæœ¬$_jÇ‘×Îüğ33>kSÚö@(.»tú›Ë'º?/jÙÆ)x‡íHïÕÕ@~D}YURŞä? Í°]*Ñà£"§ß&‡ Û9¡j¸QT¡Ì4§C°lÕôB"1Re5ÎdòBù—€İµoD±dº*îÏØq©ĞÔ¤ÊrTb:ÛP.ri´¦>O“Åò'=ÃÂ µ Ëã®3(³Ánaºÿ¢í‹”ËÃdÅ–¸Ñ¯ÌóËbªiüi”/ô	*bäØ˜Ä<LğİFÓP`Éİµ°ê“ºwRÉdí07±–B9k˜&ew}aiQ{¾ÍÔR“f·ÒXŞ´B5“‹•ZFRL8ÏE¬‡7°SC³Ïº£Üè)<P?$Qr¯Qt^OmÒ¯ r?É ¦Êg2Pú¥Âì}:@¤øœ#Oy.ò¬ö9½ñ4ØzdYS‡ær¦®­Í)MOLX¥Aùvüæ?©±´…Gˆ‰ÿóG¾TâtÖıÓ´RY,´NŞÑEš6 t#ö†¤4Ô&Ít—¶ÜÉ%¥Ïï¢¯‡«1 Ùf¥z‹Ùö(ó¤.ÀXAà9>Ğ¼êTY:>·Cø†L°68Oe;MjC}Gæ\›ê1@µ¦şÏ‚„£Ùİ›C=Æõu«@ŞÈÛ\”wºÃXÚ²wı‘?,°ãÖ„mpß§ĞÌ9Qí<¡ÙÍz*V
ZôÃ5ïi b)±¿yœG¯a;Ù=¥¡‘Ïî¦ £Ù a;ZrÄ‘ü£jØ"H{®À »ÍÓÀM'%¿ÇıÍâkî\Äˆäz%z¡ä%×ú³wµüîğ<GT`¨c”¶Ğ…ğõ„'˜ç*!ŞütÕ5?Bz‰ÙÜÇtJ÷ÚøÉiD‰ı;Nò)l~°Ò™ëcŒ¬Áq…Î«—wrÕµŒ¢Ú §ø.0œ£ZE¦•z!€@Ä²~\nºª³›+Øœ¬uöÎˆ>R.y»©°§d=D='îÆê;C¬ûd(¢~"ŸÒ0€{ğÏwAjW}ŞãzÕ/š4£ZÇpŞ8-ÎXeOB+Ò`Úš’&à9£¹×Â•HQØå{Û_ÃM4âãV$
>"÷ñœòÄEyó¾M§Qxƒ£ûË.éĞÃ`b(ëÎ·¾ßtÆGÂ¡Ğ!26²yt~4‚³éô¯µóy^­¬l®(Ÿ©äÌÉÊ³¥:|ì£Û¡Œ÷Ô+ãs#÷‘s…y¢(ıIÅÍ¡'AÊC‹¸Õ&=éùĞ…ä]³¯øÂ²‡Ó‘ÙT;öóp…ÚŸ2‰¸ ¢
¯è :Šà/`n†	÷Ü#dïS=÷eÌ.	‚»<º“*bcˆù'1¾¬[Şz	êŠPº]'{‡£“`(ˆ{ÿC*+W"Îíí!È³ık}pg@Ÿ/{¨©m›2x_<óÍH›tºÛ*)ŒíZÌ-X
=¦ô¹ñcÑ' ¡ó@€ğev·Ëˆ7×ˆãí¡Ö‰yçâow-èäkKLÕ!2~C¸’š%^‡ñb–(¢sÃÔ›Ás‚§°QwS,>´~ûæøDKÊâl¢¯9Ø·ÏÓáY:ÑŒ1°‘+'³tF€a 
¶â´C;çä×GGü_X‘Uá\¯öIkG)r|l–WaN)ÁÊéÓ8t©Ì¤‡gYÆyú}§iÏ^ÒÓtèèö&p5®Õ*Õ?Nü´6œfÍÆ¤u3ÁC$¨Œ™#¹{2\ú6ˆ¡!7’ÁrïàmP8¼øˆşÙ6¦Œq:|ò;Ävƒ	±-İÆ'ô}æi 
0SüÕú3eı˜aç+bbkØ.<:ª{¼~ÍI‰5íí¼8’Y²Ğ·ó}ö#çbú<–æ5>Ñ({cùƒ¼ xD¼XµDğf×í!ú|ÖD[F÷j`’`­¼~B±}ì-ŸÀN¿ê“\p3~0Nò¢xİ¸¨IOí¯‘P•xQDÉ„@÷p_µ7°›Åö‰ÖÑ+G±ú©1gÈsZŠ ÂÆ#ÈîÊ)Jâ³ìç¿‡nhûìÄ}¯YcæR€¯¿Ô¸Mm£R•åš”Mó: äÿ
€~Cš-‘ÒtŞâÛ&$UD`¿ò.8-€tè€Êÿ½3Ûq´TrŠ_?{’l*¾¥²;´p4ÔcÌ·Çavİç‹üÙ»Ÿœ¨X€DU?3}xU]˜¶Ú×6M÷ùß—»;cg.êğHkmˆ]½e¥nµëgÇ›E>´]”7–¿ÒŸZ¥,nCÁ¸\Aoh…i×,ê…¦êY›ùâĞÆÒ±
ªPñ@…í4×ˆDP–«T Ğ@Ldh®¶aÃíŒ(­Ä»®rÿ´¼N^ãæP`SÌz"r ©\8D•±‰1Rïà/"·¡Wk4 ã#Õ¨’®&•2: 4GÔ¥‘ĞË‡dYÄ¦è´ÜBQrJ®=Îş},	ÚmÌ-øfÔ\º¡SŞ‘6¸¬¿]ï'mùÈCµøWÊT(¡Ì!~€èÿÂŸVb—[™,¯X€(H%S(Zu÷¤šx®Õ‚ï9<‹œfæ»Øo…Œßo—È¾|Š„WÂXTŸò’hË¶0ÁxÊÅÄBgadé-›­C…´.0‚]$Hª1ª®¨tî=–W¼­z€ÏÏg\fm•`w(Çy+}"û"ğÑ8ÙüŒ¡Ê~Ä ßşR=œšÏËè’î4òiÄC™î„7¡Oø„™µ]-yJ£è0…Á/Î‹°scßŸ±ĞüªL,ÃSUe'y˜LíüÒÈêM
èKğ•ÊQâW¼'ãjı$1Üm¢Æ[¨CxGÆÅû¾¿ø¾ùn´É‰ß®ÙE­¥¸åŸ€[ÊS¨ƒA/iQQÃ!ôÏÛeœ”xm£ßÈÃX^Nê>ÍËFôØ"»ïØá†sO3Q“Á¬*Ø‡ÓjØòä]7ñŒ6öÙ¾]×÷‡]ƒ4Üı§7,¾hLÔ1G™o¯/0%1bü`®ßÊÚ<™fÅ~Fş×>Š¤`WO{æ"«'ãÏ%Â89}3¸y„tzµáØo:Ì=2›¯Ç]]J»dÛr¥g?¹BvÄ[¨cÆïÊÆ>¬×àº£~u[gx‹«èoÄël7kvŞÓ³­Èà°¾ïÆ0l9Ïj†’İa[¬Îf‰iÖ‚®ÿR]àhmìf7.Ô.d!n>õó·çÜó’*¡ÏñÛÒiŸ÷¾kƒVU¹§òl;Oo*ò—ãeÕÎ„½›œ:2öRp'ı›Qs «p['eIuıx¾şĞsZı‰4º¿­¾£‡k‘L;›n²M‹Ô±ü$\•m«½ğtM/j\¢zÂùíK«	ñ)U~`d)–BD£vñxøTPtx8á½Ó)çBèüÀ&_µ#ü½¿Kis¥g˜ßš$©½8MchƒÕ™nğfYä³ü·Ëağ‘“ğÔ“ÅtbúpŸ‘«'ˆúA¥Ÿ³…]]N0ê·`2/x¢<Hnß}k+C~’L”tÍÔpA-±gÓ_°ÿËÕ#ºk;dú”™&{†B|2®h«ÛWßÿ<¶sãRõ¢¢Ï]{Ğ«y¢;9tŠªJVïŸWS&Õî± Kb¾ÎîG0÷ĞI´¥³o|MÜ	P0-h>rx(Ïûd¯m"÷ÆÂÃ\İÁÂmjÙÇ·Èû=½½4›¼ÂæÆ	I	â+Ïû˜KÁm‡¸B¢crĞ]­¶EteC»e!§ı’029õÕ iv(ºÎ!Š&ßk¨>²<¡N:m='äuÑYF
ó6À=6ög_ˆFÈyQ¹*Jº¥/f§Á¢#Ê³J¸=¿[¼‹‰aNg>õ¢~½ı/Z¾"‚E²×h¤Œvï~w=º*ó÷Éâ;|¨ İ;sä±7Â*6ì\B÷LÈéR¥¥v\8q:	D“WwxbQÂ´+±‘ş°Ç­2¿ò°æ@ç¶ÌŒ¼hUËP!#¾pG0¯ r¤LØª‚ÿ,NÕÚ¹Â”¥ÂÓıˆQ‘nK±YoO:c
˜3Û÷É±ÿ=†e‘C¡Æh»é0‚[kÏñéšÑÛ-œ[«¨mÆZÚ˜ÀşÔù*Ê^œàĞ·—ÃNyÓ‘Ë°dÍ´Æ@5ĞÎS@•¡;¹&2¾İíÖµ5¤;r-Â¨@K¥ïÜNVmfN±ËŒœ
©#âØlúX£OàX™&Ş»èfV¡P|àŞ%ú”)_ş¾G7FW=½B™‡
Ğe‚d˜®Ó‘Ÿğ¼1âDl·/í¬eÖJ.K«Ø©Ûs^k4é70€õšŠ Xò¤„Çê)²Ú@¤a–Ã]øĞìy&‡|Ö™‹ÙŸ¿ƒ5çÄY*d±‹ ‰±óœÉL;	ön5`Òİƒ•Q„u¦ÀvtïÙÕƒ]ì<bv;ß‡@ŸD´&Š$JöÏF½O|"…‡b‡vxİXGo0é7êšYÉıDÊ>ı“ßµ‹,sd–Ş‹ècqy/øÉ#ÒÛ’PÁXC¦á{ê*Y³HÊ{”3AéŒT+/wJş<€íò@')4å_*ØT©vP›Ü~Àî
…«ÍÕDLĞ¨l·¤ˆ¯÷ŞÛßN¸ÕrğP#Ss J7ğ÷(º_dXÖ€Ct àß~°”âxS°ƒõlŸwDBÎI.<àœà©0Ç‰g"„I@>Z*H
˜OÓñŒW›ÚÇ¦>Chf¶v_Ådª¼ÄíCZ¥¦©‘óôZ9ÂÜ'©`´¦—UD­  —–Ökü‘,2ØäNí'VÚÓ¬(cë¥òÕLÔO&ëTQ+h“€'¿Ék|Ÿ¤Ó–'æÀ=äìb?)şîGø0³
õ¸në‰ßÚİ›`†Úaªz¹[³ça­AĞ?ƒ–ÏC¨vèA+‘1V{‡à³´‡w#o5ÂÄ—’ò“Ş8ğ‡„ü&{â¹”ŠÒJ"S*O ~Éç`İf-¯ƒ‹-ä®ÿI±ú-÷YƒU&<ãÍk™ûc—UşœQøºÒ‰‚ã¸,»ív¸zºPÀ,J[Š®d.?åİš˜E66Ê$Ìñ X:©½È%K“ÍòœÛâe^Ä	Ç·±¼*ò7ıàŠ’¥–“cKš:C_¹¸¨'å»Ï‘îİek¿3×GQC€1ÊÓĞ“è™¸Ô—f=œºĞÒ@óË7Ìÿ00a ‘6#¸¸Ø[T³$Hx¸M)v¡ z™4ŸÙuG¿¯¡m;9ù›ÉV²/5ü‘È‹~ş½ËUØËAo-n0Ú'€E=TaÁ*L÷¸ÏÛ¿HA¦e|	à¤Ü0«à–§™®U³¸ú›…yDëØçiÂé6ËuïtØ`ô¡[Ñ¸ÍBœ©˜	=—v˜=º²CÿX¸BÍˆ…Õw\$‘jÄf|¬Y%ÆrMåáj¸wgdaI¬Í€4‚Š÷'bâËOWj[I?5ÿ4S¼aa¹ñ$ĞÆŒC'¿{‡Çæ¾Ot¨¶C»-Q½äj÷MHÅ¾·á6ÅšUXµÌ‡›GAæ/to½?Aéíw¯à3Öw·]ó¤ü°çƒ!À ^oZaö† ú€¶Ø’“ÿ¯?Õ©=UFg–U¾Ñ%í5Mñ„Ï„–Gw7QSßY~kw›6UåÁÍ¿ÛåF(Ydƒ’ÎÜğ7«'”[ªÄEÈ”ú—r§·ıïúİÕ,$£-DDdS°;ëë§×æWÅ´¤lµì•ÒÜêx0NõQµGC+È“àEü.7.„¹~r}zò µ€¥ªÍzkÎOSkúhQUTK?ĞeŠpg?ädg°%ØøQkü€—HÓÛÌBD-fˆå‘<eìèÁ`D°Z|“mZ­³®™‚Ş7«Yıå4†i¾ßuŞ0l%ñ6n'X· ó¹^Î:ÄDå²R¡•LYbº§×›HÉ}5áXvµ[CİGû,‡!¯H]ÀÉ×š!š!%ÉiÛcŸ”+[µl!Èğ…w¼v0ğ¬Ò“xˆl~GMª™Ñ¾Š‚1íUlÁÓİJîbè÷G.bÂı	%bDUñ0ŸR9šCbı£ÀÄò%bıÊ|ñ<²ûøkWVjs“FL!6;ÕCè¦i0µRŒ…Ùñªº©`zÖ|á9ô1	ê ®'å÷O¹ÍçVòÌD#¬Ô>§ñìLÂzeh~²)5¬ÓÁ0Õ…b€³_(ü1ÏÀ™ÔæÚ±#…@dD¾ã#·G7L"¨q
åLÉ?ÇyEŞÔTm]ÑmÅŠ»>âfUä¸ßH>ÅìZM1%Fõ+¥ò)Ã‰è½L¼mÀ_sis ÷øR»z¦u— qWD’T9#[	”$?¦FÆ•)ø§ëQï[Ş®ı	¿şª¢Â0l'ƒî”.’ºLS^ø=™ˆk¿T³ÿ<2×˜roş›XO_|
‡u1ÎÎ¤Ê‹Ió‰Èš"v37B²5şÃ+A®ÇBÂ·òú#—
@/Ám·œ+˜Éù¤’#˜7Í–UßÎ’½°ÅkÍDq»#ª¶NvÃ.şª2ïÑú¦V\àû9æÛCÌpTÜŞ)À]×éËš˜0 Ö•ÑïŒƒ!·à^T'·7ìuÁ`6°‹ı~zIù½‡oœu±‡n¢Ù1¸„´ïJ-Š „.æ·6Äoè¢=ª
a|çGµ7à—Cµ4êÓ»¥‡ûDÉŸš3&7EĞ8>HWjÕ~·öõÚÑ yÔ4}?Øz5z­nÆü/ ¬øCæ¢	ó­OÚKØ“3kÆ.ü'íPÍÖgmÎ»[ÄJV‚mBSÄ#Ñ÷ÑŒ:—CŸ¬ænÛçBè²¡÷pRÊ— ›ÇKa’ë(¥Ÿq]ªË«ï¦¤x)Ü®ÂÑ1ÅÄ.a}>ĞŸ–Íø¹#€ùzÂWº¤¸l`Jğí–H“mÃñ†0.èûjú”Ú~éé¢!MÜ"¤O•gß7˜|¤”Ñât$ö¦Ê¦
â¥,ªx-ákbIÉP“íaÒ!oç!K²^OŞ3úeÂ_é?âğP™ yq£œë“&oû?”½N>‹vÒÅˆú[}°áªÕ oe…­Ûš	T9Kˆó%5®>aí³ó[Ağ6Ù÷3kxzU}d'Ä/^7GLrÀòîtï£	\œj5ºS˜y4ñ’w^ËYw+•Ø?•+ÕöL¢~Á÷‹Îæ78è]Ûã¾£v¦b c_;TLi ÏğõŸÛ
N/	d½Éä×\Wÿ]ğ16! ´®hdiæY7#,WãQU‘²Yå`™a‹Æü¯êp<ã¶Û‚I®ĞNB†"«2„SØ¼¯+4HQ™,ëÜ¦ñ×<ODÆõ`ƒ]¾z—\Š»TBsı*ŠÎÍ¿êgğ)€•â”sëRÇ‡şŸIP&;vşçV§Ê~.*I°9˜Vb¹èS•V|˜¤Øp}Fˆšò‡"©Ï]şW³Hìä-ÇKzœÜ ï)EƒÍ¶y}7¿%R:E÷`q]+×ğ t8åuâ¸s7ùz>ËğEˆÆ¹¤^Ïiq”¯¼Å!å‹âÉµœëú]õÈ®±/=˜şu°r.º‡ìôö:\!‹³~$|Oj·êCÓõˆ°½
ëA9eã©Vù]9=ÉèĞ¿¥Œ€XW­aµ¦?eReeO…¡Ç›=^T-·gõó13Ü&¿?G
ÈÜàÖut2ÀtˆHÿ”ç Òµ»º}pÚµôc%åh+†P"MjŞ‘o£újKÉß¨·íŠ¬¬É Ÿ:Œ
ù
¯aÁÎãÊÜ÷?îqßúÓf™Û±9ïÙQ,Ï/¯4á½RPó:u!R;ºK_ëìÎ¯.‚‚¤•Tÿê3šÄÆ7
}e¤ÌOjrÊ Ójî²ó¬XÚÁ‘Û¶GƒîÑ¼Ï–ëŸ˜&Â	‹)Âz¬Â…)mpiã<eQ– zP‘jN¨/¡@SåÎk™[IKÏ›.å^ÍÿC˜hà5å°Á€ñ}n˜q“¶ã±ûØ¿“
Yk»ßm+¦4sÅİ‹Ñi‚X¸â¨Y±¨Ğç*Úei'õç78MKÕÆÈ=dxôú£±H@ ƒïd‘™hÛÛf«£¤^´µ ›¤î¶ù	°ˆÔÒE¢_ëşÎ×bWT6¯ô»; ‚ö>lq)›à(3&ŒÄŞe?!/Î™Ø³AŞÅ€+;`4¢6S¼±n-Â¥7¬J:ÑNÎí›¨Áìdˆå¼ã›‰­ ehÚÛ†aÂ<"ïö{½ƒõVÔ]°bòt0•6¬ãS¸ÎÉíµˆmœxÇPßÎ½¡•Asûüïõ=\ğìş·Cª‡t‘zlL5brh5*®•IC¼:å@ rš0‚Ğ ^ö8—=ÚTltÙğ¨=÷bµ²m‘–OÓî ³‹>üsCMíºgïNÄX$ç½œ}½‹+®4Ì6Æ€"§Lt§8ÇM”•T¥üI?lúÚÕşHúß±é°ğ]¬9æœÅ2Ñ9Ìm ÖO®8‹ŸÔWÃ‚7Ê .Z=üg#3líúd0Æ«˜v^}l>“è^’¶ˆÖÅO'«·Ä2O  t§[¤âGJbz¦"ŞÁ}¨Öô IQ²›ÑOB vùl1¿@Q§ú/Et'„7Î*Ux0òM.v9îÍ¿²ÀÒ"»xÒ±iÓ6aRñ›z…¹¸¤Z†àç
Ô5¢nü–.Ù”è¢(È>V¯¶Ã˜&¢S`êyÓ‰šÕ¾ŠNàyÑ:h§ŞÿLóîá—éaeÙÕR¼Ùë¡íßQ’!&‚M!¢¿q]^¸ƒ¦ª»_´Äú0§òeEÌˆ!È[7n7.»»Ö›Ã¨ú €ª$Îz•ÄWL ¦rÖ€Å¡\àŒq‡8R#+°=´°ğİ†<µÍØ¡ºRï«RN(•Uı¦h?ÊVµ—ÏéŞÆQF%º~…òãØÂ½“ÊMQ|kÑb5«Íe„Ø?»&´˜d„İ‘âERŞ+šÆ¦Mğ¿õÒÑãÁ’ÖcQpÄôT^ì§ì¥X¶„–µÙÜ"(:Ã…Ã9ƒËì´”ÇíÖ|À¡øz³ı¼V×ÈŸÄ]ãÛ=í²
u)À…ˆ û™ÿv»\§q„vşgõ*:ß4Iˆ$¶@^de‰æ)äî	~‘­,ËOj¥$2KÈïğß‡¼‚UâKòˆ­’±¤š1*…œ#/š%ìº_sú)Õäï’7U¯úRfP AW-ƒ%ş¥‡çÕ)U?qÏÃ¶ Ü¤L.[Ñ+‡_„+ğ—­8ú#ıYY·•œD±ğe1ÿ©‚Tş{z0eE-•è³•˜4g!õ¦Ä«pP«÷/ª-&§L8¢0sº
QÈÜ¹Jî®2‚ûı/âfIKá–²ü]ûnñªôA :Nyîjœ¿IÊü  ¤Ùô5èó| ÛÉ€VÌºy±Ägû    YZ