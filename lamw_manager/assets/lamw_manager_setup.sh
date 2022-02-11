#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2656538955"
MD5="96cdd85a913707fda6d0d18b900c79d7"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26468"
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
	echo Date of packaging: Fri Feb 11 04:08:08 -03 2022
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
ı7zXZ  æÖ´F !   ÏXÌâÿg#] ¼}•À1Dd]‡Á›PætİDø¨,©FXôÁ\úqua,÷ôz&ÄÈXvLaúûZlBD»)ëúÕãş²ËÌ™ù¨âp¨y†ŒO3oÂ®‰œ?Ó;SM}‡ËdüÍòR°TS-QTïaB®ÎÃâ…æc×1’ˆµ“utFæ’qcQÖJkX?qì:vË"uÒÆAßù›9)Ôúgÿæ—€ïî— Ù	Üy6½òš¹Ñ;QviAt<_;FmeÑ	¿ğÜ½ßjE&¼(†·Ùİ©áßN’0Æ¶ÙÒéÄíÈoN¹\şáûˆ–w"Ì‰÷šä-|–kAM*o€c)‚Z•'ìT;>åå¸Ñ'ƒØFXOÛ8©Phw÷æÃÎGº[IÙÛÎoPU95íò¹hüş-MÇbcøôcA”yrg¸ßAÓŒ¢?‹¸À^à¨|›§Ÿÿî7,Â÷³}#f/ğmSŠÑ?EÜ+ çˆõ®{1İ‡¦Õ§^Â•Š‡‡Ş,`Òûüæù
æ Ìıêğ(Õ)¬Æ¿úó=25÷AZÖ5<#UaR£)°åsº‚–ñ7j¾)ãèÄÃF]bÕfì¹‰8âLœRDæ‹g–2[²LöLíble‹…Ô5ÈR°eÙcfÌÃmßÍ­$´ô­CM˜™ÙBëôDÖ
%7¥”ÿÇ¦uvñÚ±×}ÆèjW	ósƒyv;c—~§ôÖ^½©8?@yaÖ;êıVO1Ú\Ê=pâÔ>SyP¬×"ú7ë¾)“AíCMI8+¸V‡@ıq$…K™’ôü–éÒu4'æ"¾»2ŸÓ5\úê:»ƒ¤¯-ç1¸Ã$/*ÛÈ{X‚ kD€ÆxÔ‡ÌjEÛGÉö E½Iİ’¤”ë"1€Wû—J9ãXYƒ°|{Ã;©ùÁÓy>¬E_„&ãCA‚‰2Ø…'=ºã¾Ò¦İ'I=’ïùÏµ1 i]Í<@5W:ÓdÕCGë·0ä;¢D˜ =µµ^‰YÀİ225Ælïê'k¤"cH9$ïÑD¶#˜7¹RÙô›Ô=à”à’–O®ÊVë‚VØâõíİù[zDû”ÏûY‚eÍ%ŞåÊã#Ì=ìKôõ¾z1¦Ì•5jÜ}è4ƒáhi{=¯Šc¸æHTEfXäŒbêîmĞúé|Q¸…Rßx:€İuqj‹`/•W€$SCwP†—“ô£ü¶XóT¼ê #õ<Iİ¡K¤ºÆmu
©Ÿæ„îğ ÷ÅÓ8)TfGƒ‹q§T·c9ò€Š2W°]—å ÆÀ­˜Àã¾¹™áÔHÃ(b Mš>3s˜#
™ûÂ"r:û<s©LØ0¢ÖÓ0h½ˆ7¡~Mêo¯CëñÃÀÑWBŸWBw¥¡x?cÚO;îc[·ÙKGÅ[¨PºG5 R:üùÃN„¯v:‹“:¿ºçÆ‡,ÜTS“.»ß¤´“AÌã-˜¨hwl'ÀÂ]mf)¾?säîÚS¾£Íkú²³´­ÚH N¸G¯¸¦~Q‹YßÙ³Ï×V/ÌLy´_câJ,¤ªbšü3
‰Û1;5Q¼íÇS$a>&I¿ Pï˜ÈÓp&‰Ÿ½P6: ZW	´›uìHÀ¿£Yº¹—ü7ÕV9G×BÁ@ R³'=;Ûèë
ö,¨y}Š®ëF÷é{‡Ò\¹Q€ã;E¢êßÊ·YF^s[È{cÉk—«ŒƒÙ:]Z2^p(îHŠBÉ¢m¤Fö(òCp¤=ZhsíyÿÃ3|Ÿ°Œ¿ydê^ô=ÊÁØÎ©ˆˆë0ıØÊŒßëj"q›ö€#Wİg‰UÂ§Ä'ƒÇ™ó€MXãŠµVµ1û
ˆÙ/Lü
NàOüÙ^œ1ËÌ´‰!$˜HE¬@7ˆbèŒ˜íU+6ü¸zwŸ‹v|uèv¹ {¿zF–R?{kœÌ4†ñ±²‘Ósh*uru2ÄûÀk¢–ö	J¤9Zæztƒ)Şè¢º_l`äµ~9ÍâÒ
±i½VL·¡]AVd˜j0Wzè¬9\ë;W>û6§iÑ)Â Ğ¼Û¿äDŒ] GÖîBN@g
=·„@'U¼fÃO¬Ÿ(ØLX7¶ôQp‰Úè(ş‹Ûï
.,ƒß+cJ’á#ÖE‚Ö¶s=Xb6Ü®Õ¨œí ¸-»ÄS†=•-ÊtklÏáoymsó‚-i¾÷ˆË'u@Ğæ€"ÖBĞ.£O{4.âmn®^Èç—Wı~ƒ¿•üa¹%©GaØVº»´mŒ]/ÍÆökÒfÑÚÍÙ4‹AZL—İD •úFÏbÎ:UÅM.¾ŸsÇ­[£§ZÒ%ÍRw?»ã"ûó#N-àJÜ°j€%DúcTŒ;k˜ş_µ¦›IŠáh]lGc ¢1ËxZªŞ1Ìì•¿8€ö^£†ÕÙzñáº+/ÃrÒàxbßÎk³‹“A9Ë.Nş{›kî–¯w´Ej°(kGBÓ¾/˜çUk9â‘æ£x?¯2ºYÎÎQüç€P‚µx iš·„ÈÏÀ/FCÑ
Ğ•HrLõ¤‰JBîé©°çLˆğ^ÿ0!ÿ2<à
nÚÉİ@äáa×*‡*äqf‡pêÜLD°b^³~ô‚Ñvw²…UdD™¿)‡Mwº“ÿÏàÎ€]¥ç²+ìUÌZµ¸ASÕƒQˆõ2ë."ŸÎ‰ÁXæ‘8{å[Ì|ÃÙ{\úpïg AÓ„ò"œ[$Ç¨FjnµÌ®ü˜-C‹ÓÔëWUµQ[È«÷WåE°'„}JnÖ} [‹Ä°çúº¥ şìë¥©ê!my„v9úİGö”ˆÚÈ–3¦5m+jLç‡´6
8à|r²Îu-^Ï€Lèo,øxaF§gáŒùöo8t	½[jÚ}±9ü)óœç¤)Dx OŠñµ^{3Cw¬½Òÿ–í£à€j Òã#[dÏÄÁ÷!ë&Şv7Ølõ«×¯x`«RU¡,ƒW ƒ6ãÏÏøÒm<È-yú‚
+î²·¨1Ÿ¥uñí£Û…?‰—º-³?Pæ—‡Ùê0ßWÒ¨‘™©kúŒcsÒ`^m?ˆPÇZgúÉ&¢mt¢†×øØG¤ğ'Nüi:äœÊ7ttG ¦O¾80¯‹²Í?Ä³&}:b Î>Ûİ:Qvâ‚Öö¦*à|×_4^#øÃØ¾ ö‡lmIšÎMòom×íb™â×F°.™ø°{ëTÕ\;­B,ÛÙKŒè|ıwNfZ
y¼6òæ8hûÂuú†ºnHL2û“Ñõ³oÍåúa™•™D¹˜-m|?B]uqgTî§¹WMv<Œ×tøÚ	Â·7Ï]Tj¶ìF´w»ğh9\Ú±7"HÄØ‡:b<= ĞHB¬ÂÁ¡u¨ áU–© q~ûÂÏ$‰Éì)ÛCìR«sJz¤J~H‘Q
ëwÇ¤NYŸ‰N[M‚­±Ã3<ıœöí|gHôãñ•„húİıš#Ìc…¬™íQå4CñĞ0çñ¢İAíIrûª$µ®‡±nµşÆëÀ0:İa¬%,©”ÒÌ.ÁJ¯¥èÚKrCÑÚoíÎIÆ"sq“Oû| ó-9³Şbä×ÈÆ¬ïıĞ•®{2¢Áë3BÒÂÓ5ªzï5Òö0ö1 y¤ …~U¤@‘•ÓÊFR(àK¼×–díêmœ÷„$DİˆhÂú°Øl½P-©Muí“¼ó°±ä²Ş7ã.˜Æ_•úGÍÁ¢,ÀŸUALCúp¸»Ë/‘îÕªüA,QùO[t« MoŒ&¨Vš(%dCyG§L¥ÒcøÚi¹œH]?×ã\ºÊæ(¶Îwcsö6?Å7ğ\tO'5"1ÈBîí]_Å• ú#ÍûË)ª+ª¦S&Æq¸¼,­ Û%µÈ”n=­±[;¸:¸7À#›ˆl³›ëJˆÁ™æ7*áŸ
Øê*ÂyÊæç¨JhÕVÿ•cqƒ3óå»ek½\=œ†H1ÅAkV¢Ëm5/–&ì¤t¬ÿy¢3%ÒNğ K(¼RŸS‰°Â\ØÑÅö&"ı¡›+B£´ñ@TıuWÑ*³šã@<¹"«fÄæGÌ0IŸ9¸®›Ì¦ÒÃbÅ›jñ«WC…-ÔmômU†g æƒÀ“Š‹`×>7‚Oj¸4ÈU|ùJ+çÉíüi~®Ihµ	@ì¿o»RlğÒ*<„IÖ{XóÓ°`»@»˜ÕBÌbÊ õŞ9»gõ¦±'ó³JÛú7yŞße2vÓÂ5ÁÎ0á±Ğ$ó¿´ÙcÈ|3lN•-¨ÖJm½œOÄc0¦ÍXO(î<¬8ƒ~o¶ö°\YftüâÆ:B–Ğ|>bYš‘bPÊ©Ğù^NøøåÎ½ë›ÔÃÏ("¬;gæ•qNcKkÒ·K-{CP8‹­^ûÎ"¯T¼S%êàTO½.À¹—bıå¹•‹j½ÕlNÃÙO|Q’X¼œÒşâeî …Ì˜$ÄÌë-|ì»ë¡«D2;˜ê^µãÜaÎé‡3S„UaIË›Äì®-Ü:•7o¸_èR±Ö®Yü4g%-÷á¡Fò KóÚ¬B«mEçÁ4±?´1oÕËubC¨·@{š){şˆp†Ú•
A¸/gNî?b"‚;âÿÍ†9)WØ°O™¤*®*¯´>!& Üé¢Î„L¶ÀŒußò!…Ğn
¢x˜aõ‹üèö3"ˆúÙŠ· ÖYé$^´~Æd¨»5ö;rEïaÚ(ÕºÀwäRKi½PåÈl¾Vd£ZuÄz.É&;Ÿı»ş'åÊ}96»9_8Ûd¬FÔÏ.÷×^­â£µ(©[•‹#à)6ã<OîÑ?x O_Ü[’Œµv‚¸Ğ6Êü‚ïñÆÙÓv0å­Gşµ?Ï&WÁŞdCó³ë=¾v«áÆ®OÃ‹MD‘õ‰HÒé©Šîì‡œäíë"!4ö	(ĞC”k<dP9áO«¶Ò¥X"—ô)c]õÚÍä›49~£zæxCi"Ìñ«_ê°ó	ÌWô…‚ÄüŸ”êÖj3ºòÆä9AîÄÒX]>{9cÍ_vb¸ƒÌ"T¨v¹/ñZpù²°ö¼C¿¾ºéJÑ••Flª§g?oä}iƒ‰•AÿªêwàSÀëÁ£DÏõ¨Ê—ì&ëÏíœ
…éRfÂ­‡šNõÉÊ“–º‹a2Æoã½ ÿ=©î*—ÒÈTÍZ¨,ËıZö0ÑL;óŒP>İí `ˆ"7)	eÕñD€X	L’ıÏ"Ğ©\½­aµùZ‘|#ÀD5ôè<+áÓá…¨—o”4*·D‚¹M’E@¢›+xmÉ"wœÑã<jØ¨Z£¼f®¯b«\÷Óİ^Ü.½çÑ:Uz£Š¿g‹ï@¾› fyš-áj‘UÓÅ@“Í	ŸsøUä†–X<ËÜ^œÔ’ĞÇ¦À/¤Õî†iÚ7Ü4”¤¨Òü °}å…`²ŒÄĞaŒ¤|wr]Â|M=	?05†ŸšA1ÈÒqy6RG¥¬İËùó¸ME™W!šYvg´&sû¡V™p¦ı¬3S‡ß5*üB]ÜÄ²ÄË+“:äñ>uƒQ1<*üjæËñg¿HÀQ‡%ıåŞSg“Éii–]ÖÍ_G½$odô»ÜUîXgµ_Ò"`Á.•¤Ì¶‡Â,P2Y…fQ|ë…çùiQ9N‹…÷»MÁAIS–ƒE ÒìwÖ¸U–˜	Şb”Ív*š×µ ìs~9%=È…&›Qu‚&Aªg¼¬=@º>>çX#Hõ—ªv-Ë×„œısYªçGèAÆ‹¢Ó%_—p²èäªÅÂ¼¼cym¯WÑ Æş=Wªç\6®òe;±`‹Rû¦6(ñ¾Ã½!^:Cûñ[x Fï‚Î…¡ÛebWêÃWêÔ±ï»ÙáÍ¾~†‚J&3Ö·R¯ºÑ¤ ¯=´u9/2»wÖy®°—NAâÿS1¸Î¢Ï¥ûFs%-™o~•Ş‹VòC•ÁÏÌ±¸,lÀpÃœ…¹á“WU]½;bš:’såùöiÂF€›Í•­¼ŒéQBWSğj<x©Áy‘Êm^ñŠ­Mñw{ÎPÍº}gˆçPôIDfØru¼éqëY}ßéşÏM•áŠ˜× y1êï*´ÂÂj‰OÌ+K‚ñMlâ[ñ:^ËX‰[;IÒ`UÒNæÁ1)#õ‹Ê±)Õà‡X-‘á›î¼-+é«qô7z¶S¯zêÏŸ1$Rïø?ƒî_S…Ì|?vcZÛ”iCŠçzıjáø U':w`«u¤öS¿Ìğ¡pMkÜEçÍÇx!ö%È4]±¡}vÀó®»‰x<ãQÚuMLıâè$§GøOÀ§k
kzz] ;°®¯ßõ­L†x 
Ò{Œt0‹¶öåG-<5ğZôq=ğqC²6$Ö”•(éB?><u¨ç+³÷,LkÁìnavls£VŠrˆ{¹E €QÛKŒšåö£ (O<nôG
u#Wox·e»i?KŸÛßÌ«³‰_ú%}h(ĞWnv—§²ÈÃ¢ék$ˆ(¤hOø>ˆg{Ú+ğ‘İÛ…uQI«mv¼K ;ƒXü’;'Ñã†ùeZûqj:+T ö³Ÿ€`P· @¡z¾Ê¶_ÑvÀÆŞÕN¢d”şşÃcÊ=KlqŸ#Èk‘3?j–6ùo¤¾gBjWš,†ì zìâF^ò$Òƒí’Ú@©0àÚ@èšíıÕ’3òW}_}Îûö]NOWWgüãvêĞ¾Ùf²+X¸Ê‡RãJ[?5­r"K‡QßéMGZH;‘íİ\Ë"w¡'ñğÙªÈW	K&z sÒ–·ñœ²%4±ptƒ¦Ç<[ñŸZ‡*ó`«Ë!Ü·Ö9ª£ Ç““v@;·¥HöÉÜev -óOÚä:•ïÑf¡”F(`‡°fè×£i{Rß U¢pWôZ«XöpÒÍ‹C¨şòŸÒıí
a]Œš-1mäKÉvbV;©Ô4P¥0}tœA[É8âjHŸ-gQ‹3İ%×»né×D¤~Îy`ßâh?H,€ÊÊ9'âôªŒ÷Ü¾PS´ÔÑÁ
¸«Â«øNCı¹ m„¼²é)x‰»q\Ë´Ug A°ãñ^ö(í½NÕhÿ·hñ“ÏƒÑÌ<ƒ)Úbê6•O}ÒMæk]X Rs’¥“Aœ°m;ëİ½gM9;öqW¯i}'JM]ÍOÖPFVZ")KÑŠ6£<±8;Ó”c¨Qó Œ–_˜f(‰ÁÌÖ½‘ƒ#½P1Àvòu9Æ!GèàU~Tç¼ÿâVÇé0ÉèTz*Ô·ûM8±)ë„^G.øaP…è~I‹²bàö+	‚‚˜ŠBÉ>òÊşOĞ>“èšM¸=€N|òm2»ûq
Ğ¸ı}$ARõ®{öçnöÒD£™«ï`òÅöÁÅÕ)†ƒ9ß×ùª<_×>ã[uI¦Æz¨á>ôŸœ9JÛH³Ie¡V!âï~&'ÚT»ñé¼–¡Û(äßÓXÅtgaèÛÂsVò¡{»–ÄHñFÖ2–¾Ï¥a5¬Cö(çwœN¾Ç¼•WöÌš~uOX¿±R]¤\HrV‹›V†¼ÍÀc7«uH¶ärŞî)n~	Æ!Òq‡;ÛDé‰ïıòã%ûâÂÜ@}#õQJq”»q^¢NŒäZš"8üUCaÿ÷î„›Á@³ö­ÑBk/Ú×çNT÷ì¹"®s”ƒakB9…‘ªÍtªÈòG	'VV½Tä¦ºjQbßÒHo„Ïd.|X]$¡J ã‹¿óˆªÀøÙì³n³ú/¦Tïù|úÊ)R˜.z–\7{ÓâDír)FtAÔÿ
´—P_`ïÔ³3ëq„1«D¡¡Ó4&^vúÈÜ­:ƒ[¹T$ ’k»{KC˜ckª\öIY‚Oœ°n²ÚòC:© $¿‡ŞÍcAgUœkYÉ³¿+æ;Øm•R’Ql„ç¨Öåô‹ı;†q°“/¬àŸE$ögBÊ“|äÌ«hoR<…eéQ×"3­âju¤çEÛ÷ğ¹Ã_XŒa±Dø7dgì™E
äà³ÆÌ¿~Á˜×ãs<_°+É¿qbhëĞ¯L¹spqM4	XE~Öô¬ÿïš¦ïşgÎ†˜Ctw İ¬s‡İnW<1[BÓc¢,­í=uõ"T…#W…üQ5sL¿^&·Ò†ïŸŒÕŸ¸™ì½I-$R("\9ÛÇ®5)³-ĞHø°$ˆÜ§Z¦ŠsP€"ÈÌñO½ï5ğ/êÎ÷jC¶S3èµŞµ N ğœÑÁbK¤Æ$Š œ«vy‰Â_ÔÀ4ÛmŸê/èãCÆæÒŒRv^èP<±ƒäf Ó³Âyª-q†ëäWÚ­Ä½Ì¨†z÷à­´XÇŞ|{fÏCß~E,QoÅµ©
†®ÕW‹¼§ !sŠƒ¸]—¸ÀÛŒÊ\w;MJŞÉœ¼<¼şAAÙ[3J„ê-3y+´‘=Í¶ÇYÆ1Ìd°áiÔ…^‚Ôò¡4ïæÜÓ¤-QtxŞÑ–¤˜×ıÎP‰T¿;(¡Åı‘lĞhÿ½b”Nôx-å6¾ád9ÍsPTƒxªÈôsT+]KCd¨4Ó­ùeyÙPp‹äß9èÒ¨B¨ÁÃÂšPn×RjğÑc¬®1zœXKßÏ/XRÙç¿úçsZ±¶¡M €çMb‹& DğŸÌ|lù>†ñ'Qt£ó\½ã©©"İ€;«?Fé6£¯eEî¢¶•ñÖSC¿ğ™í˜O„Û³JJÅ¤2?l$§¢ŒƒÃµ#Òè"'Àç1dŞæ!Ææq×Ã‚óWCé %gL>G‘¤È&§ùÂeå”×=¡Ò/Z–BhåjÌóá©ÑÌ}RÏ¤îS{OUËÄLumÁ-“×ˆ–ÖŞ+×ÅHÖ—¦eœEşóµÈq[>5¼{ &‰î4Ä}kô‚†şLÿ©a±Ş¤aºÇ¯˜WU€»m;oæ~4eÅ’¶U‰PĞ`â>ùšÆ;ÙDM [Ààå0(wáŠXÂéØôãS„2™–àMJ¸5Ş5ÉäY¥|.0“P{éšƒXtïŒœÌò“÷°ÍÏ¿Ş…>JùÂy4—i>™ı|Øp¥½ KÃdö™& 5”3èe0’q`ÇÒI¬+TBå–Æâ«&pèÚNB¬|I<*dÁsu‘sVÏûÿ~ë®«Ÿ bğsB,"AM<@\‘se¯)ì^®QÜıöŞJ/ŒÄè;¡ª…fìşÌ:`³k-¢ÚD(ˆjX¥Á¨tõ9¼¹W|¥ â¯ì ÕäÀ\âcëÔµ”¤İ¨äÔQÀ€7Öéâ¼¿¸KätšäkNİ½?!’ß§*UlÎ–¡<Ô}EFŒù×÷İ$—OŠ$§A¿%#À±Ä¨Ó®ƒ/kç!áo§‰ñ	òt•2âUÜ”¾ ïõntæ”ÖÎ¶¤â¢8Mq!~Ç åD–¤!®ğç§¯­St˜ã«Sari6ÃŞhŸ7¤ *†äø÷=ğ±ºc¹B}I‘o…zFº}Næm/³P"±X…Æt+æ2v´¡Îr°À€*Ì¬9;ÑUí~â4KÎ ¿¼««Ìï&
TJ‚d€íbD:B*m˜ WmòÍX2…±›‹„|	ÓÁİ”Òr[—£·ˆúÀ8İ«$åyZşKS9)öÄË†¨ê0«LÊÃò;Ê%F
foD¤Î'îQ¹€ı{Â;ÒiÌ>·¶¾¥İ¥ß4p…¤—³¤^<Q{{dÕÈyÓbj\õ8sùŠœ\A-^_cØñv›Û¡~tEAÂêĞ¶÷*ATß–ÑxÒÙÇK5sYªK[]¿_æXšÑ´7›=¡Şzki…L«ˆ³­İÿé2¨”e3¾mü}˜?¾ªnxVl‰Z¨ØÚŒ3-úİfG\—í;ÎÖ¼6›á:ü':¸¨8QÆx¸’¡ücgwc¢•Qt]Õå{z£6ÌrÊ9]™Që€µaĞ>B„dŞïÄ9åx@Ì[@Ãì’±_`‚©aP§ZùXĞ*ßM×jQô$Æ\ºî­	r2ˆã	ß1LJ¯Îë&Õ3“J*!éÂú§%Šcé‹·æ•gœ‡>¯6I2)Ü°q¬”…Æ/ OÃˆ7ñH_2Í·½¹‘¤ûÙqØàVŠÉğ.8uñw[5?ÆDµ8-Ï\Ô°ÊÑôÚhßÙ§sÇU¾Š5ïû#iBœºÖ6ôZJÀÆ!”ÄjÈ\"LN• 7—RÄ»YÕ§x­kÌÜeøÊ‘ßqjm°ëPcé³)Á¨»Ş¾¨‹
˜KñP:KMoñá™ÊOh“zs
´¢áúy!E„
Q¶*A“Á•‹>›	;¾k¼÷qÒûÑÏä İ¹ÀÊİ¯yÍ\F¤dhØ¢.!’¬ííÉ¦ı%¤n!ıä‚Pu[ş¯øŞêÇXªªº€0^4h$µĞ´ş¶B¤,R<BZWjy?ÿ2U ç²Ù*¦6GL °Û¢XÜ4ÀÚáûìËğ&¨½îÀİÀ¼ÌLÍKí¶HÕÅl1 ‚|÷("¦©Õ8RLòÛD;›aï×)JïH‰Ç1²åîl­èöa*?.d7™}Pÿ¿R9Ÿº&Õl…­¶ÕA¬ËÕŒåÁt©—ª3>U\œ0 ƒåˆÆÖRn$´ûFŞ‘E;`SË ™vÏğ!I@™p£‘S½­CC ª"Ù ­bñ½éá0¯B\¿5¹ÇRuòò9#‰(ïƒ!ŞœÌuD¨£$f«uê¿‰ä¨SCÜ=³Ë‡¸¸ªò\ö«Y7ÀíH«õô´ì•|xª_wåw¾ƒÀ“!,#q”3Ü¶!àëZšBUÍ¾"ûğ­JİdBw¯bãLo¬l,¯¿h.Ô•ü§Ö·\cF¼“sàYØŸâeRH=<ª«“µÉïş;—íI{I4ÕÅæ)tå¢né¤õXi ÖÊ{¨¤²Q.’öB–üıÆ‚Ú!ˆ€V¯/aµäÔ¶ ‘&§4¾‡ªIù˜@ k7x'È®pÏ‰çŠí5L>‘£ø÷©¶†‘e7=ck£6>éÁhú5èe‡»Âåâ>Og’5»”¹j>¨êûµªÚıÛÇYÄÂi"îpO¢zS0y±O1Uó ARìÎåÅ./¬†zÕL½¤ôÏÑt]sMš–A}âpÑkJEGdK}P¦0KöouF5(âÚ€‹ôõçLÈHPW¶Ä
sÄúwÊÆVææ…dºÒ½¥§†OÅ³k8µé£JR3¢ı°“.hôıàÉû]eëÓj'}t$mQÂûÖèìÀe#`“SŸğŸG|‡`¾»4®Pğªq`©"XoäÔ²UÉ]şq¸­Ñ" V\0+-•c»ob+æW!Ø€4ª“SFSTZ{dO2?t£èÅ¦N“òéùÅ»Ìİ;½‰ÔÒ—M(Õ
Íºšb=ùk½†®üÿÛ¤ée96—èKÀ½°K,qcŸ,„äf†6P¤á¬É¹“h’*¡¯€5^	ùÖ_}<°`ò"%

€Ü¡’È+Ñ.öb§TD4d°Òa*YéâÈºĞî–5/(%ÇÏ_˜¬×-¢Ñ[ËĞêºNnYfŞÌÌİ*xóH²ƒ¦yâú2P[6éÕ—c˜(9v•ı`#Ì“F*˜AÇ¥¥…N*)!şf{{ì‰ã$ü©§[ªÑÎcyò„­÷WG¿í.îÄ~ÈcÚíØæ±|DìÃsó´°?Md˜½!r®`O~F¥`9 £ÍÅTï9ù6ŸÆ;ÍÉ˜à?›ƒÕgLpíè=îy"±k÷³d`şğ­ã‹ è5Ç¶i	ŠŒ–I®RÜäf"óJß0“+mŠ?¬™±9™ôz½I4Ïu|¥ú»Éz¦7Œ„tÈ ‚PÕöK›¡ÒïÆr:Ó³Öã*:¯ÿ 4 -S!¢B§¤–Hka“ø~©Ú9GoJU p5KíÃ»TW»ªĞ6¾,Iİ€qzœÀî"ı¦·ø“Õq®˜ì?ø# @&„û“h»ßbòXf’-Mé=ÛX^“´•#çàË¹¿@Lü^× }´(himå¤Î“şi~ÀOa¸@1ç —ÌIMÔdÙ6/]qúƒX–È'tß“*ÂÙ&j]«zß3,mßÎ–±î¹N‡ét¯Ói/~Šd2Ab—ìW}DTì 4ê´}X Zn”=™™š—ÂwËnK5 BŠ0%ª÷³2ÿ&¢aM,éAUbQ=Ş¾KÍ!=Bk¿’`ºµ8 Ø—òäŞ[œ¶hó<Ñ!—ÇÖ`—†tUòƒ:SÒı™à¨©À/¶ã™gÖÏªÛ§¢ôôº˜¨r–^hJ«˜Ì0‹X¦0:MIÿ`Ü³õıHNAd–áå‡ÚpW¤ÚÜ¯-ì­5yÆZæÎ\„Pû|½óv<Øw­ÕyÉ­c³Gkó Q©ÓÃëg¦'¤‡çb#E©2GWÙü†VT—êPaxI™2ÂÃÎ1œÌ"­½ø•¥aàã³»¸ğ•æà±K=¯İş§UH4&„Û@bÓ^~a3£IašöSÖ}:÷ÿJÄQú”Ìª,Lÿõe?MYtïRª“÷I¶ƒÒ–Š*	Û¶”•.&E$S³<´PˆÉ*“ıéâø°›Ú[DP `rş§åÖûzÄir×Í‡UÀåïhQ¯[LÕo¡ï×ŒÌw<ŸÂL™‹’§vñ¦a¯¿™%–ºi‰{ü²QŒ¹ÃGxV<‰¬ç5Z†¿ajw†×æ„ÉRi\O|dğ¸¹¼‹Î‰‡M¹ø½J²§ÓÂõZ-Ïÿ¾q˜1yŠóaÄŒ|d‡š¥ìŒ®,_îaZº³3áúñƒ
Ä¦ÎE6sÔ!è®>€lßûãqtâ}`†cüyëÙ¥ùhm~À›ì· †Â–óŸ…Ó:ˆóNŒp+ß|³p&áÓ0²o9®R³- [ØÂ…ie½ÄD÷äfœ…U*ª½Ñ![¿¹%Kzr]…4ûQö›çØ”rğ»6d•;^B|Äfû“™Ggƒ„zÙRû‹Ÿu”T‡Ó´3e:”òÃ!üŠ…—+‘"^™å0ä8ñYüy¸S_v>-Á”ŸÅ`}ñ¤pë:@8Ê]ÂÆ™C#…¯Hñ¡#ã×ìŞ¾Ñ±ZÔñ QwC€OÜ!¿%{ê!ÖXÄ9†Ë3š‰jo6üˆÒaö§ùÑˆ.âX}Rµè9êÁ,¹}.ŞŠ:!¸$“1òj0¬V¿­àKa
Uê‹æÒ
„¾	¨ÆJ°FÈ0$˜`áÁyCu¾êX!Uı×DŒ!ÕÔñşF>P•Ğ<Í©§·¹„nß²T&9M—U·§¼Õì§åÛ Ê¶fğC×ó)a„»34Ã)F7Îİ††ÓQßŒ!Yà¯ÃĞãF[2¹PmÏ ğt½£ˆÚ™3ü3hÓùis"—s›6ó¤ı´6ØdÃ€ò¤
mœ[í->ü‚ªşÑ›ÎÑ¶ûä~)œs`1 ‰]:#°†Dï: Á®»Áºtá¡@×ìB=Å Ôòà7SAâškÄ®ãı6ÿ8Is2èü—oÓá©­Ãa&Ñ#kk$!”æóÓDeïyÊF¬ÔŞhS]•ßCê¶¢2ä0=oø}Ù#:‰ˆ¬øñ°\›%¤fû1"Ñc?K3ìÚ¯s9BWEL¯ƒ)‚>ü™}"4Š†½µƒxd$oøº†å˜åyVn¸JÙ½­=ÂG+Fs£ëàV¹Ò¬²ê$àqÉ5Ür]µ„"hïÜøÃè¹?.¦­B‘	ÕHÙ»°’µ[âşEUûİÒ°ª^ìÆ”'ÿ¡¡ğ06_™ÏÛÿE ¡Ty^ûm:;O"QGõ.U¹›k<ÛÜ0w{–FkxŞá=lºsŸ2k£Ñ˜@Ÿ§¯ı‡¸è{dÍÂ‹Äz²;Ëü¤:÷,#$N}ô?q@´Ùô¸¹m°k1†Z(à«Ÿ³!¯QX]vÁ…M‹¦G!àyŸRaÏ¡™P…šö:7)ìM%½@KôÁ‘XV†d!l‹Šâíy7ş;›Â&çöœ±ÎÌîIŸ\Mµ2__N3¤%&Æ¦[­‹(AFMÍ.Ùc™ÆA	’-â'Üı}õs¿eåŒkCwMÊ]Ï„Kaq#¢r÷OÑ¾ÚMb‡gxı¹>±}Z¥-YĞZ¼Û(ÑœUçç!Ó±›&#Á`hcäño(E“ô‚(–ùùñõkÀ†Ä—ã}µ}EšRvaÃ+§¯€ùnzß/ÅºoQ?| tyÎ·è¨ú$÷rØR¬,¡¼£Å—¿Šˆ#VäíNõş>!^ç©N3¢Ên†M8…r…Fîì°ğ³)Ï²÷ß`Ê¨öÜEÅEQ¼}@oÈc`ÓĞ
™şHŒ?fÔıö‡0?êL&©İç~ëºñ]q üêláëØøu«Òñ*_iÜÀ
ì…QXs2aaĞÉõEÃoÉ”OT!T ÓÈÍ"lÂ"W>õDi¿@L¨ö¸*mò³ı‹Rü0rf)£{‰·÷ô«€‡Z…‚¤"àˆ!Pb üZæHq‚úúypÂ]-E¼,N¬ƒGì2á«em¼f¤XÂ˜ğt—*™›”6*`•Âµğ,G67Kô?¼ñÉâföÜ°µJ§®Í6¢ÒnÔ!™kš¦¥ë¨¸<»|=oâO‹ĞmÕ-9©,®…f`+b¹G®÷-µ¤àÚè™ŸÜÂ1œÍï%â—£FàÇıÄ–Ïİ;5<šæöj¾-Š.]â ¸»ZÒ°˜__
A™ë“d)İ7âéÔHÿ˜»ÅïĞè¼XËÄt3ªîö/.zDaW››S@œwY«ey¿'›BE7>õÄ÷?‰[™ÿ.A÷È&îø)/ºwåÎD¿¨ñ é9%®İ5£Ì·½Ñ¬ä9EüˆWK+©iäGh@è‹nÓD{{x§ÂUx”¿ùo
ÅÛ©Åú÷Ü¼rj¯2)ÂCôå>¦ƒ†ø[º2ÍPu_Wè¢æiq¬¢p¥¥bº™:H^3ç†6€æ*…P&ªYÌ¨dÈ
iJ€Kt¤³Ä«²gèË@iä¯%û¨ƒ’ñ.S	¹c`ÄpÁ×qO}Ş6iH±MgW®šÅéñ>`Ä¯ÙÂùñöÍ–Õ¢)vüo>†‰)ém¦+¥\<,a<UdÚˆÕ,ÜyTì²¾g»‹ñXHªğ‚Mú˜¡ÁTäö#èÔJnë-3Ê]šÄ_\5bÄÒ{E‚·RJ×'
¥ÅoNiĞ#3¦ô`ô§/ÓßÍÇµ[ÍUi|÷`İvÃKä”{s:xâ‰M1§Ğbwß6«!.lkÏ4‘r¯…´´BÛı:àòEÅ|0Œt\u:lˆÚÓg;,‰ŸNcMi´kyõï«î­‚Úæ9ÇdÊÇ¾¿^ôz´ë©&©h%°5j¦»ö§˜‹Sc×íÀ‘Špj»¥ÿO%TÕ2;]ZåaÇ}ÉóÌFi„p·ÌOM&#»Hg\R®ÀƒH¾àƒƒ£bÕ"²&›`”ãƒÁI+>„:UÃ´|À Q±Ü¶‘U>bğ- p}”TpD¥ÓU=“Áğ'z-½)‰À×X„±F•÷-”g?ˆHŞ¬‚Y´`Ø“¯™j¥ºš”j1F&VÛ)·
³a/ºººŠÀòDn°jqb áÀ_‚5b,,Ü¸¼ÆÒ’L·ÿ‹jaGQaò §Ú:OşQ`’È]ì¢ù6‹†!…T,æ9rÔœİ€¼™Ÿ›ÉOK¥#°lú¸!„æ¼·™åvxãéaàØ4ËÍÎ‰«V}=1Xk:ˆ›Ê5òJ¼ÔCş‹ü+Ô£“Q”˜# öqKÈÙ±C0”®š^îù†À‹Ÿ¿ŠLñRW[q%Nì§ƒ/Jîœ#¼óq÷Jì’Ímpæ„5«îÔ­úĞ~F™Ô"8`W©š˜Ìü/^éPc¬áÉO;ÿùÊò5¿é€[´‚…¬k éFètx‘áhÜXXQ÷&ÖÅœ~hÒÉs÷ÉÇ%iº W%¤ô c&Ü„K+:–öçÃwZìšÉìñıº¢a2Cü±¨§Ög<ãpêÏãÈMıEMœYhÀ·¤Ô¢‹Éub×Ä¦Ï’L3º×®÷à°‰ë#åæ‰>ÜM²è`wnú3¢Ü•B½gR˜ê‚k„®H¯çÒØíDSft¹(Òƒ?Õy)05òoşADÈJi4ïoNê¢ø©¹O
/[râˆjáÿ¸·(½h³{ÎHÅê!”«ÚP^=ÜŞØgä­ì.n¤øC‰”±xüÌÑE/™ùÆb;8Öô`¢»`¾$24éåîÑ5ônËã‹øäÁ¸â7N TÙ¶#-MsÊÛaˆe{ÇÇ[ ÷¸/Ö—…P6’*c]¯‘«—u¿ûÇYhEIÆ²ß›÷À'c-|×¤‡RÚúV½Ûr²·–D¾¢Ô˜Q‡Qµşu…<£„…Î¨Âş,DœıßÔ­èëÊŠ\|iÎ 6Y›áİuB)çÇ»ØlóN•¬G‚çÙn÷Zõçhÿë"ì	ß?CÅkJ?ãÉÑİ«À}Û’Š,‡®Tˆ)T÷† 8ó±µ‹ÉI¿B…gÍ-º¿~/5›±ı*——±:!
Ü°“%æ5á¨ı[ÛYQÀçœ¶¡=L¢‰İú(õ‹(>ä…¹&¶5)‡2@ˆÀ-OAş%AÙ³(gö7Æ}øÎ«Íˆ¶—F¬a -·Bİü.dMV1€UÄÿEdtÏÓŞ™=p¬5£5 o\—Ç„uoµ@uR«FÒş'pî7½ÂÀ+O[ˆ“–×Wòv f¸WÂÊ‹D‹¦…¢¶âÄIlEhŸå¡!ÉSY?Ùxëä—³¸ôÂ”e!å°äæˆşcŞµ4AiÎisÿŞ½ó_Õ*uĞ+Ì1	ï}æÕÅ}C0f?\ÒÂ° ºt#sëŞúy¦]Ñò™÷»tÍ”G*Ø³ö‡ü&v¾°Ù1jƒ"p™6k†Yå’¥ËëlGKx™Rİ,%×J¤(ÉòõF®‡nâ©¼u+¶@0Ğıáì>aaõı÷&ÌÈÍ9v·ó˜N*Ê,
ø™8oõ;ÉûWŞuÇßG±f>õ®“sîwõbŞ®ìğ™Ã?Ä7­öë
D)§ÌŠx²ú–Égiıöl‰ˆ¸Û­l¨Â}ÌúaÿK›vH|Aš'¿rÂ9¼‚ì`Æ.ŞVs¶¼Ñô^í¶ÄÈı¦¿ÓŒ_"ÇÇ£¿™ô*Î[×]ø|rM(ÅM.ÑúXS!6Ü…Ü³{2zæù†|]ÛoRn`sÂÿGVi
¤}Ì&ÕX_n}ü„¥;à@CõIßó	3üôa
’s/Ã¼A{H(ZP“Éñ>^ò…8‚˜Kß›Yş®IsŸÁÃi3°ñ½—À¶1›Ü…Û;‡¯Ç`Æwyg=1Wx	Æ
úç…ÃXbs³¥|»á\»Ãîj“Ä=œwí`€
Ûv«XDŒ7mkD¼Ê©\»á¨Aw¸ó,½-­Q]:$»È9BGİuYZ}Bùÿa¡pv€ûW—ÀÏÑ\u	'ŞâHİi@ênrY&Œ `;Û{Ğáe„; 7/
T±o3Ç.øM‘‡·å|NˆLï™BÚe‘c¶6Bùıñ,6Œ¾)¢AwÆé®1$z™Û"h®R»Ã}üü={BÆ£À‚³B’‘©«ÏR™¼dòü´UÁ²:è	½şMuÚì~Q!p7|Ùù£ûGqûgÒÿ¥wğ²;ª›İSò”P´¹Ë©³'§„šî;Ã3CŠ&©Œ;3¸ñwµ6¾7lSî?NÂ\Ša²¥;ç¹÷Êùo4G±½†ğÇÙ/-|H5Õrâ¨í´O¤Àíé?ı——YŒ?tí¹zc®&áÿeŠ!Øí>Yó/xBêˆgäFİÓ!VJæùcÎ{Sk`[

Ë 1#¯Èºğß`°x«ÈÙK´†»ÎèQ‡ÔÂ_Ä¦ü¥Õkè§ô’`kRêÄãÍs„›ß¸ÆU­Ø‡ï™Ôà3õªã3ëW…¸T<û'ªe(¶Äs¡¡æ8’¿%dVÙ"ùâ¾{ß!å“8MŠâÒòãã2§Í#¬BÄFÕA‡ÈŒ¿§Lˆ*©Äb™]mİ­ó,í›Bÿ‰JÂ˜¾Ğ*Q)Ñùæä|08#GPÚ:$y8¾2y™õŞ»ßW7äĞÉ#Óqï'2(M÷Í8´7¹åÖ•“l__4ËáîÔEnÆŠÔãª¼îXgĞ$ÿ½6ÎRnš¥òwÎ5‰À>×“¾Öt×ıP[qï¶¸ÑÏ.íÌí´—X'‚„am È¯¸¨˜ ®³¹e-ZG½³"£@½¬í±YC½T'ÓËšõhõ=ôÁ
•±XõõXvåjüµXLß/{lğ8Í/½Âœ‰y¶¬“êMPĞ£ò|¤Õboœ÷‡Ø§b´õÖ&SZw“×²@ÛÊ  ó€U¦Šÿ€êæÖMÄ+öZ¸úS:ËG £î-p5(Ë)×ò«Æ=çÔÃ4º¾ğÓygRŠ×g,-†B¼Î¸ît›l=Ë`~ıx çßu›J
ªDƒOĞ* •¶§:@jts&ÚıOˆ,;$±”—İ-_á)Ì?X|_‘tÀM\İc^[ –…h
÷·öµt„Êy@½’~øşoËÌ‡Ö¤¯¼ÀÂQª±–ÏyõÄO'°EewdÖ;Ë¢k Í©7:ËuÚg_Ï?›0!>¦dqHé^ù:XÕíÖŸÍé`åj{m ÜR¯ÜP^Làšmî|ŸeKYU€Æ |9Æ‰òNV‰–ˆ1Eñ`ä&7g3¹ ­æBI»@z¡z7Qm;·I} âMhÙÇÈÀmø]ÿ¹FÄ/èú¥í9(ùƒĞEÕÅàÔXĞ*Ír]°Ä¿)‘‹õÚ°f'yLÚ5cª]U°cˆÁn]ä Uå•(CÆ¦ò÷‚)áÃ@-øQ_¦îašh‡— ¬aÑÕŞ°ü}d¯’”ïe¡HÚ¿ê»ıúŸµ¸×¡Ë»¥°oš•’gø­¶<´”ò™£/:bì0şKD¿ÖÊ€ÙzNĞÇ\
Ñ±aÆ;¼;táGãd³®…­³éR`¬W¾%©{rğ§ØS®1Î?°â¯Ö;ùè6…ç×gŒó¿†LÁ¡%·¤ qFƒòÍË¬¦³².j59øœ­Ô4¼"@ø…?Kf>>£ãğ`'¸o¬¤Çk•{…WÒmO,—mÚºr”;÷ë\—™%óYŒ­†çRĞÚìõ!¿wÜñœ=£]şóFPqW<Ò`­“â4ù4€°V¦'úORù#°Ö7‚(š6ŞíÉŠù8»¦CE8–,öÂú¡oL•¯±Ò ÊÑò‚áâ?Q÷ƒIõ°ŠØH*½º>’f¶SŠÄ<G‹jpƒºgªÊ? wKZœ 'L¶0Tl›¢¼u¦[ÀH—¯"
Uo»oz@ÜQÃù„C‡ö2äø6~´x˜‰V6l}†ÖEZ’·úi¦Ûí&Êl¡ÚÑ/åİKX³b¬0U±ÈívAmr!gU¾×é½ª†´]Õ±P›Øæ:r —y£êâùÚ·´I8¤'¿Úƒ«¸Ió7vÉw¤_8›ç½
Ór`	[ù¿nq`#¿ˆ¬ÔU	›û¦×†JÀÇ@¡‘]è¾¸ŒU+&”—R=?ö)Xk³q¯åÖ ÜÚ˜H›É D–lˆ)ûK-[ÿQ¯tGÎ€PË`åÓOˆàÕkØ|5ä2«NÄxk¨¡nÌû/bïÆÍÂÌÔ¢².jèË 9l%X˜…²<‰Æ¸!/=„ø—¼–["8=MßÌÍv €@~Ï"ƒ£LİÈµNaQZªÇ’§¤Éìô5Ìş´–9\µ3«p¿.ÃŒÂñà…Ÿ¸üc9ßŸv¼ÄBOûSNä¥3’Çá„Çw!9÷HáYîÓ[×5õ7ãŸ}ÇpƒíâäÓ7ìn_6=Ëõ¤<<Ôa« 5?1çóµú¸ÈŒ´	ıÆâ³y8ÃØkÚˆ6 vŸ“o?Ò®FÉPqr¸{Èz-²™YÉ`½+Mî8(E^ÄU’ëèïu/d~&¦"ò‚<œtæõp^±CğCbSoq`œk»59uYÙ^›S!p4Zi’1¬ºr¾.xƒz¶8Ó‹¶½4<ï—ôÔà]é$t¿³À0 ºù´è¸Ãšg°ç‡´Äã0úFcñV]€Ï!M´şDöµ^MM<áE¨?[DĞah±Aa@'Óx…Zav`jÅ&ímwUÙ‘•6<Ø]VèB¸­
×™û‡N°f¨Á|¢œ|Ë†Œ­Në™´ùõkRäÀaµPöD Ä„eÛŸ'%Ü¬<Ë†§AâLÇPdİ•:Q‰y¶{asÂtW!eN^:«,„K÷+,†ªU«ébb.ÄH ½=§­¨ IfØâìÙ'ã$ğJÜØuİä7Ö‚xÀfUêõzKŞÛ“.M<ix¸BÆ®ÎKÏ’>W7÷œÀàcfÉ1î“p{Ÿ>Ø¥õıds`bEÀ!	¢=Æµ”Ú
oÀİš[“ñ¹ÅJ¿®ØÃ @ÅÛ|a¨j5h  „ÌŞ¶Z{Ä‘99—Kägd‡.-'·HMıZ{çwWÖ SÆú&ğ	&šQj tşâ'iÒ÷8xY@KÁÆ”ÜìQLQÛğBò€$ıt+%ù?–^u€äÛ·Ù¹_I;Èğâ˜è~N?€×¬¹=QW½R¨Öº¾/)ı,3ûŞEU¢/)n›™k,á(ŸC-R&éº»öw Uö@N˜Uk:pq{
[Û¬8‰%ÕdĞÏ™ùåúw¬8Àì$ŠºAàñjN•/,ã4Ò•¿90Ä
y|*=ÚI¶%I\'ÕRÕÈÈ(²uª¬˜˜3j*#¿×6][S@LY£×•ñ™{"â‰ZÖšg‹E©XJëœ»zÅs6¹m±Ğ«üØºÊ‹ĞÕyØ=œ×Â¹Ê_/ğˆHpbò'8ŠYöwóKMÀ¿nLO±âmY]ôı›cXQYtÆŸ]´dÙr$äç9fYÆ=øÔñ{Rh9z£N—¼€œ>øsz=´ÖHÅ1ğª¼Šõjeo8å)ÒñáÅªo¸”àÍGeœà‰„>uÂ91à–§Çœˆyüşyş/S ¸lÌçÿEÁ>Âş;VCsŞ¿İ—x¨ô0è¬04‘f/
¢§s^(Ä9ÈŠô;r,bÊ¾|@§|$¼¡ÀIs5pÙ–8®xğ…šWò}7Ïôæu,ÇLP
n—Ã.Œ¸1»ÖaRÀt-+çve¥Üx
ş—›]ƒF´Ÿù½Kzë#°×ªtã#&ş”~+6BT¡`ÏŒtÖÉ˜‹7ÀRY7cŠêËäÜÊåøÖuáziÓSßã+;@²ÌÓXhÍ¯`¬Z˜¤RKv°KÙ±“ò?î§R5ä
"¼¦W8}•…iÆºé½šŸÖˆ!ğ®…å“’+Î)ø¾>¶–2@ =—BBn¨uËïn²úÔ-im`\ƒ}ËYÜa5QR~‡ı°ì÷).dEÂzÀDÜÁ·¶óœï×“Dï*öëiì¤O	‡`ĞÓ3ûî=vô÷æ)øşÎa¦Rœï:Q°@=åô‚@tM‰Ï•ëiG‹K-r|%›Ÿ¯„Ÿ&$‘à­Èè[Ô÷ÔÏ‡8ÿx}¥KñŸ'ã‘G^Iî¬±TğÔN¬&C‰:z—öŸ®¯:&ÖYSÛ[<ï[Wß€»Ş¥fÖ,ËoW¹³‚SôÚ7—8 şÆr»šD£ø›åµTBitcFSA8¤°f®j81¸ªãøùõ™>o×Öóo™xÿ:Ui"t‚<ÇbÚß/ë¦¢°`Rëvs’şÊ•ÀœH6R#÷)ÿ¡ø	šD‚”šZOç@àåNcD®€Æpûö“#ÄËZêøÃ¥ÖãÈ(<Ô….¬0¿É¦£ ÑÖéºîk ² ošıB­œn$¢|Øf42ökxpa=ú}FLÿko
¨ß¿)KĞå‰…4ò½’3¦É›3%HQ³Ğ²@£ê ·ƒ7y@U§êÓ¤ğ^İ½§Ó¦âHıÈZ˜ ¦ ±nU'öLr…zÔòoá%ÎT9´0a†ÃÛÃEßMD¶SG{…-îÁô
lsì94MØ¤Ù/j4Á‚Š>‹‰Ys“-‹›™Dd†ƒ%ŠY¹·ˆæ¦÷$(œùSÀx¦[EJ¿QÒH£úÇ`6O7zÙò…l|…HóK,©mÕ*_gºå"Xû«úæ²BÁ~1ô”…J²¹<rŸd—ú…6ì6£‹¶l›Ût°
o…
7xw’…¬8`Å„{Š<YKùšoG:3Åğ†mgÊÜJBDMÕK2şÛ$0PSG‚‘@Ÿ\½&² Ÿ#Í3Y†S‹—YÑw*ÿ@9ˆw(ZÒÏ}¢ğ<yÏ”›"(½_„º£+:a§Ñm¿ĞŞàQÖİûl‹¾úÈ	ÇÃ¨{öë†_fh“$óÑÍü{…¥ç];¿Eñ=ÏqLÊÜŒçÿsŞğG€Ps&;ıöB‚*@Æµ×²ø_¿LçzÖÄĞr5¢µÜ4+0iÇÜaI”=¨)Ş"ç³hø©É`®\¨&²à=Œ­4ÊKÅ›Y)´½š@ï1¤Ò¼Û»óäÖMšK@}mO¾”\WèqØøö‰ºiP–¾¡_Î.M5ı9%0H"qÇr‚&çÚlıfÍæLXÎ%!õé¸‚?Sèz»¬¼¥.÷G«T”½Ç­¾$Æ}-2Şë’vªˆ¢z©hÙÛÙsâÁ(½[”Ášz¬¾/êmëV+%ù’hÌ	»õÏCUcÔğ’¼ÉğWÃY¶]0PHéíH9l_á°'n}§ö½9i,'Nîµø«5“Ü“XBˆ*¤f¬H~&ù;â~zP<0é¬átlÇ$¼° )ó|hD"h4Ú5”„MCÃÏæ”KÖšx?¯7+ø‡¿H2ù¢"#Vê'HİÖ!ñ»æ‹æ÷…â.ò—1Y4:eàÊôúõl¿!{^‡²NT•~jV*»¶ñëYWñ(qÈNÃÌıƒÇLyWu"®Í"ä¦¶;±ªÒ´I£E§ä-±çK×-uto²…Î^1L[CªíqÄ Ö
O7…$úŞAºsXG¢µX÷ã”µ Å•ˆäùã™ÂšrqÅ_´8ôÍErŒ£Ïö_ı
£g²òGºˆo'ê!T°Ô2ëP˜¾Ìû™-ÇcbìÙÙ„kŠÂn²¡gYş`g¿”sêŒ¥ÓV§¦’é¬¥øíåA—%äÚTØ#â}Qıü@:9gØ#˜ueî»„vKŒE
Íœ±µmı[ÂœTz©’3à~€ñt£Àÿ»?ä¯W½ëíÜá¶*W1ş«ì.ÉÆFŒk†[£ßMïÖÍzáiB—Gİm«ÉB¡ñ:´U¾<'˜1UCr8kõ?8”•D]u¼eªëğnÎ5_}Ü˜ø7¿Á”ßÑYûMû[‡¡+N‘QãíåôÙø“‡°Œà1¡ ğŞ}\ÛıÜÚ‡oq†‡¨’+ÄMgü¶xŞ]Ñ69l¼å,{°ëQÿ['Ây?Ûù€A<ãJz,m›Ì÷Iz¾¡3¼u¨“™‚í†ÄcÅ(í\$e;T*Sç4Ô;ÙŞ>º×³cNkR¼İR•ğ^ƒŸÌk(³n5{Ğ”ûx•c#Xå£†ãFm¦¶ğ m —©ÚH¢èàç@L&G±¹Ú*©¹çÒƒßJfıßãşÀo°ÜŠô­¹ !ß’Ei`u=FNÇR€.aŠ¦ëÍtĞ£°oyù5Ñ1}7Mµ2_8í2@¿³õÄxÊè
—©ü%Î×&#÷-#Õ '=æ™KÎ¦<Ïfô¶!¶a³óú­~ºhÕÊÂz@ÄgäËİwk+%¦}eÒ›%ÆÃUgg¡EŞyƒË¼ÿ67ÛäŠœ“²v1p'ÊÀ'd±b3©M=°5li”€Æó¸ê0BzRJWc //Š­4µğe¹óßr!‚ÇöİË¦…úîøEz EÃ¢ú¬LÙ?Š„vîkX”Šl7=ÿ~,Œ1PÕ:\èkÈ¾37Ü“?ólAéí¼ü }ÔÀO!Àcîu3TG°ÇÔğGeïÒ”)¥lo‚Mú)_Áëöz—ôŒö7 *X€¿"×+Ì[RÅÅŒèSˆ÷‰:ƒÿÌeJÅ ¢U5w$$Œ£nCÇbJ¿;9Æ:4¨:F¦[ËI«X,ã®l”>}LÛ€]4ÅÛ¡b½›ËmåÛ×î‘nõ„ÃÃ¢¶Fe°#‚G ÿ÷ZßcĞŠú´±/¿ª¯­¸ôèŠ§_r•-a1gC¢Ñ´Ô”¾-«*Ç¯:å¶«µ¾kSÏr~	±5sïlãñKã2•´V€&Ï÷r½ºÊG§½b%h1Bš\¸Os–5l5±)-Z7Å¥UTå#è2 KW4Šm·…~)÷sWã^–] j=ıïş~~éÎ6şƒÙªÌ6éß[œ_|8æMxÄüë€Äóñ1tÛ‘>ÿ(Æî+˜qW }šğ¬cÌœ²Å!J¬[î÷Ü*`›!Êßäb;Ş‰–ßX-z;‡ƒÌÈ))ø>!Â¥ô¼¿+*ND=m¥dŞOç‰~½• ÄZş€áæ¦!Ì†u¬“q~/œ"¢¿Î…G‹öGñúœßjü£ùmôÖÉæï|A„u‘Ñá®ŸßıÑpÀÂ±øÑ¼âéD`.†¬Â®ùæVëC,bì·æµá”«ÂbÛL““üRbÀ²6OH†E<N-Î³Cfä%9wfdKiçMpw$?lE>D¥-• œıfïRISRL*¢y¶=m
8˜›t£ræ+OQ"h—‡û×ˆrZ™½Í]Ø®¡ÍI•ZæKg§  ÅeQ}"Èg	¢ùG52o·šwˆ¿Š^\:*	¼v‰‘®NÎ†‰´:–Zçt¼§Í÷#}ğbóå†’éyÀY52c3ò2¯oÒjtØmàšJ9óÆ8'3³şuGÎÒ¯ëäbP@Û\Pbóeô·Jªü´ûÛ~ĞÚ¦µÜR';§ÂRs]ò;8oºï4	-H‹n>ùMëœá(Ò,ì¬Ü ™Ökd{®]É8Ñ·¢<JÏí òÃÀ#¬‹&Õëù:7CmZµNHœBéE‰Oà$X&hq—ãwùG•íÅn„ì¼È@bCr³Åg¶œBg)ãÆï›SÖ¸±àÏfÜ4’7[Â>>‰/”Í°Îÿ¿ç½nÍ¢Moˆ©(ÊüH•5ÀÕú-oNt3›"g]¾…9˜‘rQiÖòğF*0G®e£ÌM$èÔ
¼îdH`Õ{rşJd§ø•K)+
ÉøÚ¹X¼oßø‚½Kûm<.'-zw$cŒ#CˆDˆ4«°[`ºM³N«üZÏ®Vì~ [ğY7Jˆÿ1±•„Õi¦pi»­ÙQŸ!ü %wüŸMÿ`[‹3XÅç\Õ!*P$Å±óƒ­=—4òxåŒK¿Wxp~•úR=«İõo¼úi=`°—m•ş1B´¹Šmü[”dœd£Mà1¾K˜Ãî¡K[ ¥vwÖé@>_#Õì5ª‡\O.Öğ UFüˆéEĞİy=M~÷Ê{j pœzj™W 3óé®åË¸<Fï'ûÎ:‰GPáA×AÌË!y‘Læ
†.jqìá)ÅšYÆ«ü‡)Ûo¼|u~GrÅê@ŞJ1XNJİéÏæ­á5eäbªºƒ‰
Q¶.¬„ŞÕN,ˆAÈAaı·0«~¥s‰0Úºèìräga²£^©ÑEÆÿ‡kŒœ´=kÉB=È4¬¾A8§BÌq6TŠéë‘íl‘rÊcáyaHL’ÄRü‹0%‘İİbÇ„”FSa”wN-v@§+AşF{â0ÚJ(”t‹†ò¢ÀvŠ6ĞÓá‰1+U}6fêyïV­uXo}Ÿ.ˆ]@¹ÖÇ*–˜Â±‰p"ä#Á"¥=àäú‰UnvHG´-E(z,Ôa~Âİş™—0µ¸'ó æL-°N1äœı•áêÌ^U9Ùè¦ ¬æĞWÖÑ°=èÇ¼rø¢mÂKw*o(lÿp€4 †bêÈÈ ±`1Ä@¶‰‰¦
¬6·†Rô¬$˜¨"dïlkĞî”ÂíX¤­‰(ugÍvö½âÒq»)T<ZÉB'õ(äLú1Xw‹\­7K¼¹2å(»‰Eµ¯u¥ÈDä9cF2YY£Ğ SGûØij¤ê|hät0¤asò*ÀÏEÌ•Œ¿•~ö”S)1[è-C>zÜDŒ½±$ç?Åé¼ä?€Jê‘)h=:ÒãùA’úÜ/©!$A«yŞÊ×´KEP "N‰åégëš8…ZŠ Óƒ *$z(*„Ğs°A30q>>ß
Û÷	"w©ìªÔ	:#, "œP3ºÜ¦fZ^+ªïjİ„UZïà6ÃD5Ï²ÿ’‡î«aùuzVŞh|ïÕ—Ñ€úÉ[ìÉŸ@ßE2œûEôAı~¤ ÉSZªÓK{6]èê
§F( !œ½TÑïÆC *\©¦.é^«(ÌR^ƒ,ª7
‰K®)N³–TËÆOàYü,^ïvé[º‰mí!èM››Èæ	İÓŞ‹dÅöŒ¦Ğæ‹Ø·uñ²PÃ·ßé¨==ÈÌÉ¼.ËddÕñÑÇ‹aK"“ôo
JÁŞbN³¦)·¥o%+<uÊÀ/"Ä0%ïöÏ'V9ëÖ}f.LŠfk\BG®Ñ%ï²>§UîQp…~ğÎ.øv «ş‹OØ
­ÈpxI6cóÛë£ëßêbÁ»õô9Ö=Í1O;rwXø«Y*UlA<M«Â%8ÙÀÈ”ÂãA]i8ÏImÛ6_96Å
R{ØÖœ‡M1¨ö\Zç„Èk°Ğ…@ c¾b‡Ø!Œ—Çy:Ê?TÈÁy°9õZ›ÆK™w®qßÓ¥h¸QƒÖ©Ë.
îmnásYÆKp	¥ƒæZß?	¾ğã³ÜbTM÷'H:—MK=Cå —teÒDÊï^DáĞXÊí{~†ëôæÑ’Cô”¥ŞöĞØçØoÍ¥nèé‘×ë~2]‘Z´¥«À¿©êß„Z Óa8làxc`·…ƒİ5ü#a`§Â1sƒØpù˜~6
=.µø’a7ÙçUŞºõ„?¸å,Ynâ}wñ¦ËŸÉúÂ‹K'»§^Gì˜ñ]·Ô|²&¡»m4hq|ìãÁcI uaaCÇxéá›ØÊLGœ?t¼aĞá'Ä5ZaMÛR±2MÑÁ¤²yºï$=¥ƒN-_‹å‹´I_-Pg™fÿÍ†ÈüW¥u0ËxÖKÎÇkØ*bh¤8tœ_KS^÷VX…rWEŠü'ˆL]2' »í\~q¡(7+k.›¬¨æ•åU_ÃõQ½]?Ò‰4I(d]éà#LÃê)¤ì‘^wX')~²±|ëé~" 5ùû‘Î¼¤ sGåØå-›90ÿ'µ”6éÖÅmó%q½I°œGe)‚õıõë‰L:å
@Ü _s¥<tİ4>`ÌÍîœ—½P;Èª˜ªâ•ÍÓ˜4.Ì<š<„ÖÍ\¦†Nı*ôÎy=/š—?‹„rHààqoĞµŒX+ŞP¾JS3×<Q}Îî‹¬­SİšµÇa1ÃW´:üƒ`hk‘G”—‹6¯*ıæxŸŠ)¦p‘#Ö`]¤{Q)T™;­›iæ¥g¶üá¾4ç!eìš˜0wPæ¼ü›öÒ¼ø˜Vı³úäºµ6AQeóî¢ìF£=€ï€y4hÖš3–¨eøaõÎ^Z$Tua“zqÂ4ÂMJ[ONE« 1=ÃUnÅ²Âs
¸6áNT.şG$øl7eäåu®YY†ãp_ê¥/¼ä¹tkÕl¯Qc}ƒÆ@a™HËKRÕ_Dëìõ[}M—ë=UŞş†gE«¿THâ6â—o>[ĞÒ*}E‹:³Wå™®G‰£¸-Ã
ŸÆ¸ºÁi©<kËz£ƒïùfî¬šÙT~.¢ßâ‹èCE‹i†|ğÄZ@xT¡¾³1$~ ?úÏN=/Ôô!WŠZç"Ÿh´?N!µâ5Ğâë¸›ûÇ_P?…¸âÉª!Ë\]®òá¨åjÓBeÒf×"¥Ã÷ÁôMÇ9cb/6t2kææ†˜ªzYEÎíß*Ì*…ÒĞ¦ mœ€íúÁeléÈ@‚‰ ‘]3«´¡·4YÇèò{x¾a™´óEŞ?æE§í9?‰?K”ù\&Èø8H¬ë­Á–ò%¦§ÇF™m©Œ¨2“6a‡ôø/
„¶eNıaå›Áäß¡ªB«Ñ-aê{“Åhwp#–F|ÑıÒÍğåçÆ©¤{ÿE.`¦¥U½DAŞ	,ıÊç°ƒH›ª BEKRw‡ÍŸÆyb7^Nı™>E‹ÿçpãü•ÇòhGÔù¢CÊ©.69»2–ÔZ¸×›ñ&»²VÊÂã*÷°T’7óˆ§!Ù¤GÜ¤.=ëç7gŞo‘	IA@aº%d¾é¦f¶[sÓŞìc ÖM¨ÆLèmóÍ¥×ûù‰k¨/!£|ïWÙ)É¢É Z1íP—î˜»S×œ	‘Ähíi©Ù>Zö/U+9ò´&eÑĞ_³CŸ%ùnÆtôë??jN
ÍmNØ¸±;¡*$*Aé{¯½Á¡œeØO+İu0¢—ğe)<W}<mpêı·;—c|‡¥ÉyŠ$-¾p6gJ›1ˆ6ã3ç«Œãµÿğ+ıè,@<2q©ÿØG²Zë’q§y"£XØoÓ§A[?Ë<¢r‚~îf“PÆ™¦wÀ¿{üey_=ª6m¼£'á.s˜ô˜¡^raZÒeÑÏ¯¼rÛ?ñA<]Ï+ëâj›Í/òÈ?)‹¦Ä–ªrTK¼è Èqúşä¤«±íKŠ5Ûo¾9œäÀÙ±Ø]cag(s›Ô^8=ÿ”
)9LÇ
:Qb`¢ûç1”o§K£"İõZÏ>ºí=–úÆ‘-¡‹Ø6ƒ^gğuü‰Æi
ÿ
¶ıÂŒ2Gh/“O-Ä'‘‰:ÕoJÆƒ	@"ÍZçPˆorH Ú—(×Ñ*d2ÂNà³U8®^ÎW}5ÃÊª¾ªIÄ®˜¡p"±ÍuÍ¯'‚"(òğîØµÇñjŸ…¢DÃaÔ®gÓÖéÔ¾ŸH¡Å!‘?v[hn÷%>ı§|
ãÚö_÷Ù1zÄSã/,=‹çZ"ºèÀ-Ò´Öü’ñ¯åô1`ôj-ó¹qk[Pæ²ŞEWÂ®;Æ{öÓ/;eHUÿfqì8M*¡M³\ãz“9X'Q­]$'Ì›ÂvkºMÃåô Ê?û2“ñ¡9¦‚$õÈl¸*ÒwmÉØ»s´‰x *Ü1©ßdÙ–µ¼a³Õ¤Cêõ_¶=æY•˜<IÙ¿öˆ%³ofË²C)ßvŠÏ”ÍºâæÄAÃ²7æ”ˆ–ep"·Îuà_ñ%H7ş9¼bV£ù>0ôŒÓùÀZR¾„z~µÊ}˜\òûë•Â]:g*’XÍ¿ì=&<ãĞ¨,¹§ºÆâÌ2«4(Ò¥ÁQ¾RjilRÁ°ª%¥ÄìLŒ¾§³‡Šhf'#ûP;¤€¸|İ.sy8H"åÌ{,N–ºà~êÃçÆÇA¦&§SØáëó'4µ€'\“£ˆİp›.[8ÚëÜV£ŠT‡È­-I®
SQGJ¶Dß›(ôK"‡tºßî!Õşî¼P-Á)Hö§¿ ¬U¥·çù™ˆºUbàízúp\«úÿÄhÒi°†èÊùë
®õqô,ÜuÍH,‚iúCŞ;e\[òü[OóÇ¡1vD£ÀK¹©Ø_¤c%»gXf3EÄñÌ Äù±acµ&Ra·¹ûèéñdn˜¦Cü<»Ú›²–{À|XaÀqÕëuŒã”©Ù?æİ'U]¼œæÖkYÖ}is
m	Òz¿ôê÷ÍÉ²ÓĞj˜·Í*V ôn™¹#’ğ]-.b’î³*ƒy>o6)&r'¸Àç}2wMuÑÌ´Æ=Ü_[:î}ñ³Ò°Oê9òë™•u¨2æy‘¡'é`¯9x/¤NY^Ÿâò¥	=‚ÌŒ/]‰	Èšõ”o^?:UÆ€„°Ô!W¤æWYc\ç"n8F>7¾Óg;SŒíÊ£º w¬kOÍìîï~ÀyÄOŸr€ÂG jûh${»EX³‡yw·—UA‡JÛÇÿË¢ÕĞ­Ù0C®|z{iH~ggG÷m8Ó»î¬¼e7ÌØ.oó°ŸvcÏ2‹A”¤Àt¿28Jn z½
;À:ŠK"+~ƒş;w“¹‚Y$Æp(£–2ô¾ŠåuòÚe£ÍHÊög"¼òıEv¤&¦nÊ²T4‰‰ƒuá<ß„}¾+î]¥\ºV3qß|CvÄş-QÀ|¼Ü=å’êƒš½È›G¤\Ã3¨ªÒ×ğÅ4.—èN[Uêz³™×kMfZÏµŞG¥˜r¥9‘=àšoX Âp”CjÖfjãL”…´«™ !ó§¸KïÇ§{È×­Ñ¨˜“²;µ±QÉº2sjèSÕâDüHü#®EÏ¦N½²e°1n³ÔZ€A¤C%˜'`VÀ¼ğÁ„Àß·&ODÕê]NóFïœ}IüÊò:ÉODÃ¨jq-çû¼ZS¶|!‡AõqŞ´ÕU Š¡–­øKPŠŸ„©u’D5’Ë”oU¾7S)·l)ÅJÚï¹G¤&úÁÅ­ñãÔ{ag•äg!k5~8ÓÖ–$„´ãûèœ¤c,›ëL`€¡®9f¬à¥1¬/ës(ŠÔÕû"rS–´™‘–J†õÚb"£)v5~öë¹Ñ|«$M$+¨6ËäF×ºı:'u¶ä³d@¥âKå¡Æt×Ÿª³	H­(M½«a¹”«+¡¹v»ñ/¢åLJ_wù2î PFÓî/ëîáÚã˜pÁ<ÜH§ık©’”*“+bNµ“ÏÈ¨œi>ÅK&óaØ]á|÷@¾KñØıø;—ç¾¨Èş èÉÄà¼‘;7N­pj¼ÕØf!—<æ¦œ¼ìEëÿŞêò¤¥S>WxÜ-ë}ÀTÑ4ŠHV®1êËÏ‘]æ¼L¢E#½:†½[zv€6â@‘}4Ëæ­ËòÅäs¹_E×>-íı@ƒ.æşbàÌÙ—mBIjJv»­éĞ©Î1n¨Æ4p/WR[WÊjÛ:órÇêòØèmëVØUaOˆ9#Meÿñ|~j²¤QşĞlãö•Aì±Ë3|õ‡Æ3oäµøY†p:‹ÔõQ°NÏ÷ãëü»‡­È¥ì,$¼¦ÀQv_ÛáE‡ç°ÜYTï‹·iU™Vhë©r§ÜMfá21ÖÀ‚ã Q3}åA®Gqï 0dY*$‹>ÉØ14¶ÈD^wypzªÜJƒeEhøûãT«ñÈÍÙpİÍºöZ×T"UÂ¨r'jŸN¯ëVoWØò<ãÌeùµ»ì+ğ/?yÚSTx‡ñ7mXyå™“:¿tX!§¡	3)Æ=ÊöWxŸøid ™ç÷Š$.í˜ ®Ïüf‚ÔRr‰n•Á²çôZæ+:€PÙµë{v¿-Å„QQÌü#:(ƒ†õ7Dg-+‡3ı)¡Ìc ~X»Ğ¯ú\ËÌNİ½Ğáóö'â?¾Í NÀ—2Ùëÿ¤-Æ/» Â‘{–'k™1ÿOuKåÄ"—|Ö!–>¨GG,ú8DÆg4‚)ÖÊòf!¬ÛÏÌ+u#Ûº÷ŸR:éö*eC&æéq·ñ¬#ìn¤ñˆm¶9ÜÌÍhUW±»Ÿá~¹‘ğå¤×4õ«wáB. v]3jb-§$¯˜ã¸*õLzë¥1²N:y?Ğ¶æLÉ9¦×Òä
åéa>ız°˜E¤½É3x’yeÂZÍÏäŞ]Xt]HÜ”mğÉ" €º'v&3˜æE"~BÂÓ8şëÌ8İ”ò),Š YÅ3½<l>ÔyöKøùˆ.ÇUœıG9´ªNƒEô§ìG@*’YzØ¹¬ŸÎ’4ÕØ>q=‘ƒÕË/AÈ%³Ô…Ğ®ö†CÇHÆa¯½Ô”?À7§‹IæıõöãÁI­.î£•i1~‡ ¬`âÖÈ#Ú
	oÉıcŞ“D¬¢Ï?•ËCÁ_Eüç“séô†p/”ıM¥•6ïÚk·	Ÿ˜Øƒ?eğ +‚ÇÅ’?uH¿îhô8Ÿj€!r¯::®UÚfÆ
¯HÔ!Ê%tÉwÆ+µªÌ·?ëOÜ<İ<(£1¯Æ´ŒØ€ø±›pü—æWmû³§)"ºŸWİ4xE< ûF;íïÜÆëÍâøAßïËSéÈºõ¡kˆ‡v÷(9”—ÕB¸£	ê“ô¬	ÌhçöºW˜H‘øLuC_àyÔs–%‰UqO0,*#?³£u¥uÊ¸‚uVRºŸWsôkjÏ·0ãmg'6¸u&V.] lHDgS(Ï^#ø¦Ÿˆr’tT™“øJy¾òïBf–ívc!Î‡ìÇ,ı%Fo!‘‘GšşäğT`BNüd‰RÀ½¨u Öãn"Lo[,˜‹@Î!÷ Ù,„ÚÎd@ìiTü€ZÒGuUO´{ó'}…¥å”½…‘Lç}Ì¸P‹‡)DéO×ñ*¡™÷ÿõÃ|¼ä&Éä_ë2 ¾70¹ûÒ=ÕG(+L*œş¦?©Ö²OML+AÎB¾¿Ù«GN"ìàĞ£E"¬¾–Â–ßDô'‘‰]ì•b#æ¸5Öä§$cÄ<úÙ~”uåÑËB¢İ»µëñáıÍoÓxõ°&o‘Û_'â[£_.=P¸;‡e%pïBPøÀ2ôw— sÔj†ğùôû%áT)wŸW¹étŠé@·tA¦„^;ï­/àù^29é¬y5sÌe7£#Qv×
+ÀV
°_Ë†‡·(ù+ª„ñ1’õğ·]_½C–3â5¬•ŸÉ"¸ëyZP¼CæØu¥ŸV‚•$x±#h&5^#,	BEa"ÖÔ‘“:æ÷ª‹æ¶ùN]Ë›Ë®ıÿz:kåÌ‘a“$8S¸wÛrŞw¹ûW¨^éäa´c×ÄÅ ¤Yo{s¾×ßßÊh?/x^Ìqm©hælâŠènëí¼£™ôISaCønÒò?=YCâ>)
ï³÷_¿ùÑú>ĞúsAPbûÇ·Ù¬ô­šnÅ`Õs” 'Æ™G…ën ßƒ~„ŸóL pà¨I3¹P‘Ôo²{Lo>[TÏ@3bzÛ<&®în	<lï¸QÿÏGm~ Ğ"%GDÁw"½iÍ¢êiµË<  ;Êşr-,µ ¿Î€
]ÿX±Ägû    YZ