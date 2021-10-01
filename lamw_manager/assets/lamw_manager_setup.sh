#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="388377373"
MD5="b848f536692b0e8f9d77790a72cd4c76"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23588"
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
	echo Date of packaging: Thu Sep 30 21:18:31 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ[ä] ¼}•À1Dd]‡Á›PætİDõ|V¬ü¡c‹Òğpè3Ä‹–™LŠØªa=¯2ã5{úMrdùÎØBRİ¼!=ÍLœGDzÎGæ¼Ø\U‡'ä¹øñô<zˆô•°S^Ñ:\u°Yò4E»SÉæ ë\+«ú³²fsÿ-K,A ¤´|ıe\H_…ÕÎì_Ã"¦ÉOf|o(&À%a} ê'AfîÁ¿Ah ÀPÓçÄäVº‰¿©`dXTû/D»Ãâ¯ç€˜¬[ PgùNE}V –8zõèbp}¼ì,»n”ßË
B0ğÈó´çy¯Æù"hvs¿¦®7Y´[›¶œ¥äO»¨n© »ï5jš#–5%l7-#ÕüáØ>lB£·r_°qâóV²“z¬½»ê²ÿÇ3’Z×)CWº/3'Ã:ß< ğ¬Ë®ÚRE7½×ÎÆé^Sş–Ş}&èªóaŞJÈ™)YÏ•ë†ÙFnflŠŒıIüô jØîU.¼ª`º×w@ZC˜Ş(»%¥Âc¥¼Ë×j
Uæ¢ê½>4,OX%%Ù_äIÓéÖ]?kMSãîè-¦¦q=`Ÿô_—ÿEémX¥³Ø•8€tÌÕ[?%Úh˜ûôıì¹pfú…Ìî>H$v]“¸³	Oe| ,¹4&«¹hrè½vı¬ .âAx;vÎBM¶âZÀåpÄí©é¢ñQûRLpÄwmÀ‚×¶=®4qB)Y[CÇÌó¬ÆöÑêW/|s´ öp´Iš*ó™U,Ù)ÀoUu7—NçM¥.	wmdÌ;&¸–yzh¬jhñ3f&ÛM¤›~şøœFÂb©ûqk¤ı%9ËÇ€O9à&Yœ;/¾}`«ï+ô6tqÀÎÿnŞ_:õ‰NS{Y¯NLêv%xY|héx¯a‹NÂ4>fó2Ò/0Fä	Ë¯(]ıüÇ‚ü@î* Ç Bš"ÿKˆCÚ=İÙà¬Á!şta®ä4ù±UWx ¤ŒCW?óÚû7ï˜½Mèùa€$1<¢Vß#"Ms¹‰…â\xÌ+p	÷ğ™8² ä³v,©şAkV3eA+<qİ¬Pô&Ú_1ºİ<‘=SÚB®ıë‹åŞ8æªhë¥Ûç9Ï	ÒŒœ%JÁ_ÂÅÒ†|B{-hÂÈ+1_Ç³26Õla–z/!óI‡»1F œ±ğs¦$¤QWV<¡@ªLÀ|tì¨	rò°·i6W¢ıiF —‹!+ÈÂ©¾w‹/ˆÛ‚ÁÓñèm€Gı0+Î2*ê©9œËi6mÎµŞnØzı¸_ü<™ú8<Ûuˆ`Íğ=Äi&œ>GåØ«‰z¤#™´ªuÓqßcÑ•9`xÿnh–c’n—g4´„íH7¿Ãİ†<¢ì4‘Hõ;)6HÅºƒ‚7l¡…ô|¦r:e( š¦ò~Ô`ü» –ÕÑÁÂ"u*baWÄâ4ò.2–}ìû%‘*l.óñ¯ÀpõL£Q:Ó•Â¦©Ì6<9íËDß³”¥ñiqó#5Ê!h†ºà°Ä¨\º=íG8v¤ÚmìPıƒÊ éU³±g6ó3½lâXY›DİûËÁ2îZ>2²;_ÏÙaG`ÙS=Æë(,(Ê <5ˆòÈ’!
ı‹~Ø«f¨ò` Hßú<MæĞ'¸¦Ò!<y/»àÅÀÂÄÙ P»qÓUZªÓ‰u¾%ì±ßL)^[ÂmV ¦¢jJ-}0%	ƒ…àBp¤ÒnÓ¿·³+<ì¼PÈ±8wÖQü*U‰*z¡gñ¸g¥Uä_şEİh–‚:h·qQ¤	ÆıÿÚ¢`.úsá[­é˜tÉ…Áe¤5´³É•ÀáG¡"71ºÔ”æá¨Ép‘`‹íKü)5­±€—¿ì ôMUeqÜÛşwµú2Ä‚çTD–:ÓqA'ª]^F1õ³Š#}Ræ”µ¬ÖÍã"W‘ Lz l5w æ0ë 6ìŒˆ0ÏÆ|^£C‡MÑ'|Â¢´U›0•œ ÜĞå“Œsş´î'ıE}I@0ÉuÒ4©Ó#+Â—¥I^Ça9ïƒÔãr.1—ßZ¸/ hêĞVøTéXIKë¿kXô²
úÙ¦Şïáª$€Àt¨´Q°8çÃÍf.QfcËÆ2ŸTÀQŠ9£ÑƒˆµÛ“førÃ‚®"óô'ˆSûiƒ”Ô	•µ“èÌ¥=1¢iñ0É#¸¨îBCtB¥¨>P02¼E¼^ÜOGÑ™Xô¯dà=İóÓÃnÛ;9q„ÅÃaç×”E1â4¸ò°IªŞ"¶(D©„W,.‰d/¦dŞôıĞ¶U»ÈÒq¬$è[GPXšû#®Z˜/.GEÊBm.¼±ğì¯ÈÑ«k~]}.èyó¿ö6ĞÈM‡Öì.ïôAs¬ô †Îæt´Ü‡<9ç³çreX	-c.Ã:ºD±?›¶9SşÜù†ó=GzòU¸É gÖò‰˜—W?}W
(*Ò¹?¶ZL¸4îTÄ²/™Ğ}M»ºÚà–YR¼gæ¼‰OÍ†z“i ·>I_ôÃº}g½Úµ:ÁQL^ÙVJú×~Ä79³IÏæWJÎÅ©!<ÁÇ¶†Lx"á1gİ™¡/]+v¤Ñ=Tªïëñûâ lTÂ¶€Œô€Ê$)Á‡[OzâàR68Ğ^9èöp¬©áL*;>¶ã×ğøÃÖVp•Ëlmu
û?û÷ §jå>2ı†2#°:8Ëeäp-Ñ•vx¦<!¿Ò~I@ß«¸ÕQ'EpFá;YüÒS…1Öøˆ ÇxÛv×1’Hÿ ‹á\Ñ(.fÚ\"ßt2^P…ø $Œ³‡“Hx*è„ñŸ<.´tfbLX*%7-Ï’ceÈ”b—ºK8— A=€ã‹KA<‰¨ìR	Xİ¶µ\Öï#õAÀƒôÇn'`Ÿ„8ğTÄšzïiÔ¤±¦·¬|4©¯Êá´SoˆÎ‹7ÒmÚäğ·›•?…Kb¸ 'DŠ¦XâºÖAëĞ£… ?Ö7ÍL¯bŒ=.*ğ^Ê£Òc”^µ3mòÛD¾½_~³¡“»ïœ!÷5‰yğö„SÑBƒÉ¡IÖÑÇŸuWç»†Tu:D†Ğ«ğ´ÒìŞÀPA.ŒÌé¡õ3İ›İ*Ïõëv¬5Äš@AHélLòÎî ÆH‡:+¤›Ò~ç'T]sWl‚Ky2d·Ç/şp. Q[É$õó|ıŸL=¡M°õ¬d-Õ«Guª‘FßÕªá<b3-¹w(èô¬€¦@-Ú“İ›ÆU¾Èqavv!=ÛI2^e…yˆF‹•Hï±
±±’À1¢f«Êó€j{¾¦õ:^–Ÿ¼¢¶ ²	HîS P·'ş;§ÛP_õP‘†eBš[6,mL¦ÈKQğ´ AÃ†ÑÆË×Në’{(†—	¤’ApRe^kCü\™ø_)ax¹‘íISñ´y¥â¯nÙ(¤‚;˜Ë{İÏCÆaïú#b:µœke0j- ÅÎR,İ´ë,‹uî"ÙË´¯·U=âXÇÕy¢§^“éoı‘ØÖt)ĞÂ®ŠšzWjØ.Ò|I]Ö…—ĞAèn arÓ/ñÔ!íĞhL‰¾ÊÒc²w_ô—¨x¥¯Ùö~á	0Ù1Üës«ó®®¥¯õó²ìÓ\XüqçµcãSZ'G„ò-÷¨õuÁ¹O«”¨”“]òè 2¡h¢)%Û2ŒÆå¸”µ˜‰bZù?Z€MøõlQàš£Fµÿe±¤(hÿLé¶dªûØé–µ6?rhŠaÃd<vef«8©5O]8XM_\
îu‚´©UcÉ.ÙÜÌ c·5ÆdÂ7´Q¨X
¢˜ÁMÂÜ|é&I¨<ñ;«™¥È äHí¶œ°/Ö,JZh‹xD­(¦¡”¬‰dúT*,´¾ëö¢¶ÄÜ(at"5B
61şcOq°”{qÿvï£”™úó÷®›rÎ5§ô,,Oş´2` :–tñšZ9Ì9-9ğ[b—Æ…X@MÚv`\ã®Şháå,»,iDª+Î—?ğóĞşŞ’áuMú¼:
*YÑXà‚ë¦7ä¢f’š0#–²£á¯Šv~Šôkqf½œÁì§Ôaœ! Úö'ØÀ{hî‘äšaÛbzi_ÒyÂÚšßgâ f­÷~â‡/»	ù	dÅ4Ó7HpÇ®ÇRQ§¤¾QÉe}ñeâæmÈÉ»ÓTŒQáS=…£™£!eòŒ ¡®¼Ä†C-ÄÍ„<Ù¸ƒ—Ëè»7eo£tL¶œõÒ3ÈD¢ïÛ zO¶‹Yèô4ò>ª¯ú	:ÎT<gY/I #šŸ0œˆÅÄFÌÀgØVü5ìa_å;¾6x¦Y³î±ç•wèãxÇg";T©üë¼|˜dkDÎ`¯²¼®‚pIƒÉ[¬²¶Òà=JoõK™Û\Á%ZS~f±?˜7lb|®0Ö?	Àª¹á7ôÿ#&Ç9_}cğ»„Aá’¢Ûæk¸D<+½t†@¤œÉ/fÂ+¢à O£½3·îúB_Z+ÊXZ±JQ˜
±)Ôè©ù˜5è£ÉNÇ*ú‰4li„*¿ç®S†¯ë3CâésÏß+ÔñÈU¤260*Ş!¬oˆİb3yVËe‚‚bÎ‚®jtï4Ù>…=»Ô¹†İâè·r³¥ãm%¯ÍıóÑîÓj[ƒ°Oš¶U¯èV–wGÃÛ“	Æ*‚¬AûqvÀ`b {+æ ­*Îß0PEtZ»-ÿ~–²wöGşfóÿî‘z(Li]ÿ¤#:KSÚíºÓ¯ìÂºacb<WÀÂCI%É£6ÕŠå‚ßqM|³EØï6š“wƒñ·àÙ_ç]†m×~#„KICü(©áUgir²t½>º‚“©†BÄ–W—Z¢½R[%)Â+ç#·dŠƒA5"]m¹fóP/g«#iQ!N
{”s(pÉ‹`(IÕÃÛXœ9­ª­WCÒ.4yW[^|ZÊóÏß\;¤Fìún¨¼„P¼±ÕçÃûÖOÜÑö"ºØ §e2:ÛÔôv3u”Np›‹³${•êÄv\°õ›+B‰¼„Aà	İ-Û×aÃS&·R¦©İPE·™¶¤ “©œ²D1 Ğ¶¨Í‰^´“áFSÕ¾/ñ0÷İÙñ\vÍ¼i¿î”±	,õ|\4'*(‹3'&x`Ó‹*N?a­­­;!Ï³~cù—L™-;àŠ4à~íH?OFÃ$GÁğ¡Kğ‚Ÿ¡a(‰Q`rÆÖ&æ°ö$¨”x^WŠ×åa2$È!AË@×N{ÇÚıYÅ¤6u‘Nš}U®»|Æ¶Ãe§œ7h~ß¿ºšÑ‰,|‚(?råÒ¤Ö‹[bÎè]g2¥ )'¨èr… FÀ ˆß…g_Š‡Ød±iy……¶ŒHÄÁµà¦Wÿ- é´)şğáÑQğötHÄa;´sË‡µ©rò”Obøù Räõ‹]× [Z™U3ÂqlÎ$ëÛrä_ß,•ôM×Íc€ËË~ï=r)ôê<˜&òæ|”(ÕLİöÑÓâ‘C ŒãU–ò+ßá¹_
°Mµó“°
Ùq£53.VGPrH×»Y¦=¡KÏØwçŠÀø<9ä¿fÎ¨t’â2Pù…†§ßóöL“ÓÀA[Æ×bÀ°Ú?-@¶Ğ|®Aş'y´Í¥Ø#Phû5Ş Áğ¿‹!e à]µbêŒÓÕ7 ØA}}–	Ie6Ã:;w¹x“¶¨×6a™#H²Çı“`j£õgKÂèNü€cUÆöš¯×Ê÷¹bµxı-ĞQ€¬G‘P¡ÉHÇ‡‡qƒ-‹jk×˜°¨¿‚Æÿ»½®± RF+cg˜šüppüËE¤¿jjíì^ÅBqW”İmëš?ÃŠ‹,¥»Õ†Q`ñ÷Çâã0¦bÑë]yb—¢>¬N
…øéîf¢ieeGV/kÆ(trk	«p\©ÕæÉnRĞV×8‰?F5yû(—Àä{Ò÷À	˜à¯„…ø?vÿÕCÀé¬¶šúš¹' ÊC|Û‹|e•» İg·}SÛ£«	é4[u­ùôögw¿`ò*KĞ¤Í8óĞn‰ıQˆ4nó;Ë.éVl*„ê×íŞN,=šU;OQM‚v²…|Œ´«ÒøÓ?ŠWeÖ§ğàÀ´Y¥wÁ#_ vIVŒO¾Ciæ&2
9`û·œÒ€Ö•š”›Â`ôb$”-LŒÂhÁ»k›Â{7öQâÄ ¾oE¿Î—qgs,¿@ñ­9½{-8ÀpS?BpÖ.x
ÏÄ  ±S` æ¥ã(ª 
±ƒŞÅóÓ/¬óé}wø¢=•Û®_ÿúºc6|(1ö©¾C¾#_ö¬±5?İË—(ùgï”z'SÎZ§®ÖG?…Uƒ	5áÜ!4™”WÓQo ÿğO }¬Íäİò—áu±¡¦é±V«hñz,ã»Ô rÖ$r2•>¼%ñÍq6Ã#2¾2%.V1ö×OJï•r®ïÛUÁşeS_] Ë¿›•#n½à_¼öúJ…õ†‡W<Hlº5ÖÑNÓÜ[óê$rğ:•:z ™'aljïËœ»Ğæ:J×\#a‡¢:1¦İ¤9-fªÒ“m&)`©2ôJË’^¼Û~’Œ?òHi» qwíLì–·_dË¥½Ş*Ïo‹©nF‚ãØ&¨ ô©•…(´ ÒˆétTÔ'mÎˆ¬5¹¹c}E3î“ÎĞµãçŸ'è,éÏY­:ı<²ä¨…PYi£"âí‘6Ã?.b.b1ù÷•kãÈ"	«Š>KßæI¢Ô‡¼BÈµÌn¾h²“*Œæ£­¾Ä¼şxü7¸Ôş;~ˆá¯gÅ(0Õa3TO•mxØ×˜u7Üö…jc_ÚÑ‡ÓÚDzàÑwWÉj!‹Ö¼:ÑËÌPƒ·™ƒW!ıÙ­ÈŠ{‘úm˜'§€«N† œk’Fñp–ÅFax¬Ô3uvw#Or–€õî¤¶'C°L`Q9&5Éwâ(Šõ³z{TM9@ıLÏW$°Í<ŒÍ¢X(+2´"+ÈˆiÍ ¡w#ƒ$ØéÌåùı-]¡æ‡¤W‡+©°ìĞædƒÈbÿ»EWl˜gNH*¸'ÑX”ËªDÅ$«lx5jñ1²äÕ¸ä~8ín©½5ËÛ_kğ[ Ã–ÿw™Db½(:^ˆ,ÌSV¿¯eêßIŒÎSI´öjqO@È®R¦r>¨¯ğIÈ…è˜÷TïgEækl×ı `å³ƒ İÅ0(,A=ÏÎ²û¬ÍÏÉM80‘ˆ¤"àÔ ]9$0LÌtã´z	H®€˜Yû'ÁmÓ“}Gà¯ÂbéVP\é_ì+cñ] Y ëÊOØ%9l u›ôÌ™Üœ»Uü)ÿæƒÒqËÏŸw¬XÒÛ•º yùpEUşr §KIÅ†Ó¶¬ùÄ,Ê<ˆMZs g3ñ¨l~h¸Í£N8}97MD·œSCê,ûz‹cc|í©©¸’BTöSœ[ìö/T·Ã[wì3İ¡ÔŸ³…Ï}Ö^¶fIGzÛWšt•t@Õ´ôy@V öW¬‰I|È]Í³× Dâ;º;ûøİCH	7Àëajtìô Ÿ0P‚ˆx§»kO5)íY“BË«ø0CäŸ\ß›v{t"¨z/_YV`æ°,äÙêß*;«ñ7ãPDºÇº:EbççO%ä:p Ïn `–êÄÙ¨¨ \İ§µ5µpËkí£r¾Ğ]^™²ï
ÆÇeà§r[²´f1_ª>…{6¹”ä“îîa×&¬Ç³Ãı¿1ç€t}§¯FÏËİ¬B ÖcrzÅ¸%¨ BoÚ`8¤c½c€İ«ègL²‘ĞKÓ`¡l<Gï™¡®JÒ†äs¨Á¸=Òû†±Éfí£¬ÁÁÈÍĞøQû—¡.ªã;İ¤ï¥
Ù¯“[ì{oátûQó×yşUôx±æÿú.÷ë“Ê”H..….Í„¡-ç(¬µæÁ|Öşf rñàú0F>li Åw€Å½ûc€èöña|œjƒl<zú<µ!Êb·ÿT˜¨¾ªhvv_†µ^eÛ…ó/.î—ó=µêÙ—8OEi6J¶‰ˆ•¨ëÉH¢6v>èÛ]3ÍSopi9Ä v´ØPÎğY)VÊ ø>] ÅzYÏf “å.’qZê*¢‰j<ı×©7já‰ÎĞC|Ò‡Aöâ$1§-ÌÏá àGpWÅ”ï¿fNYø;¤‹©*sj—û‹€—kv±‘Óãy#nL]7ãñãıküš:bQòÂs}Ì·µ—/ï U5?¦äÉÏV8^àbÚì‹5C–âZ"Ê˜‰å¶±‚)D`Q‘¶Øú¨rbêIù„Ê:§ü[™nVâã²K1”Ç’,¨&ˆñMÜPÓÆƒ‘:´›g"Û$“!ØŠzÀ~e¬WY
37|Æ[5«Ñ!ãÇ²÷.&¼–|âĞá‡C_²ü¯ÿ}Øx
võEÛ? ãÂ«òg³#”İ0M«Š!ñ]K½õÅAş™D
kÇEû‚/Â(@Y„»ùª°)ãG8½5qa¹îT$#^^=+¢Á£,F<_©Ô8ÁHÜ…¢ÓvUŠv-ú­i5Ç	ÿİ—§œ)šQP ©
‚øy¾ºEqù]²VË›­åóö•ÕŒc4¦ø@å@˜İmÜ•¶"aWj/^ÅÌŠÙ
˜Ïº³Ô(7?ş¯ùrÕ¥rb²ÎB¢«ùw²œ¸¨çßESêa•BEzÄ`æâKíÄ'ju­WJ¬š÷Qïùšt¾,8È"_KÚ	!ÈÌÉûhPåY„Ã]w½ŒkNó2?Hò|dœÛ}Ë0†®lßqi¬Å#Štò»†¼ğ¾
vsÎ§oë†åeÈè¥R8ÿ2aÇ­h?•ë-¾ã’f),_<A&º/¤Ò‘G¹r#[úŸlT§´ŞİM1ÕÚ¨Ï¶¡«³ãÃqn§‡s^Ï[BL¹¹nøÅ2ó[örDùoæÃf÷ôÂg¸…çÎ¿Á¦¬·+ö½4
Ï…œø@ĞÆV”~F8ÁİíŠx;øÇÒ”˜~¶­XREY1yÕ"W/I“‰Nd}<>p{p¿Ù{áªS¿d¿OŸ·D[µšÁ¡l¯À‹¡*´—nOÌÕ×ıÄñWu‘ŞRŞXŒÔ‚)€P»LK!ÄBdEÑ¦mÓjêˆSïÚîğb"ƒ! \MHœ8pËVòĞjÚa }=ãN™™êÒófîB_=bö›>>vtm(#¡Ï–*­éÈ
™Rÿu	ÔIùĞI}y…Îå¥ş‰n9ßkIÎ5¼Ç6Ä(Ÿ9Âœ*`A>ğq_B0ˆ‚)ììp¦~y˜¶eŸ'vöV/`¥qÁ=ÎØ¼!PIpXZBöÜ+$ÍMÓ^¯ãî2‹KŒSéş\ï2÷“VSMé°EÅQ‘ºbmwKêÿz¦ª{Me Ùë ğ"Ü‰Çí>²œ±ˆÏ‚V_p¡ıúÃ—P?—õp™K§[~ˆú=„coNléÊ<L¡áú>Ä5V‹5$"ìĞ çBn‹5ñÈâ’|rlM(öiM’ßS HĞ|)5e›*9£e<ƒóNŒ”Zİ’I=È^ñyŸ–²@ëE\¡á)ñÙõè0p8êDµ¶¾I!cM?Îæªh9’úe»˜9ŸJÖ°ŸrÁ¯®¯ó}ÒFj8HnE¼ƒVw¶D:½İgï×¸ï´úÍMóÚ9¬åE»­$ßqË&=6Ç½ƒF
ıÍóµ\j”DîXLÓ‚«şªßÜ7'J–Şšæ,	[Q‘xß¿K èPI›R6¡Ã(“Äß±ùóç®ÏqpNã±2át,'ûü>?ñ\E"êbYh/Ç°ÇUÄú§­VNæ´æù´ É3ó£Dİó‡öM<Áo+’&®â§$fjà9nÁøå8Ùo¦ôí\z	ûó‘È¿TYT=.1âÑÛ ÔìáC-¯Kúÿ±ÏŒ ciW3/÷†÷ÉåpN˜NÚ–ƒ…gÆÚU$jŞE<H+CáºÒ+”§i¶átÄb!Äu¾Œğkd±“}¬İ'NËäN±´Hó3ĞJ-Íç„Ÿ3¸Táic8ˆ€ÕY·à•|ï~ˆ’ZLî‰F“Ä“å»Æ¸Q,ÙGÚ»Ãúû®(#ÙcjJ°{½´}Áø^L1*şzÍ,ø©›â|´×ù¯ğ³N½²5d"™dÕY}_mNÂ¿úqx2àş³bĞexTå´û’äÒXG÷Ç+XÀ9¥Š±WËµÛNQ{‚F‹¡²/`ºàè¥>9Ø‘¡¸òp,‹·"$ŞÌ&µ'ŠÅ¬ŒØè„°Õóá˜‘¿e÷^†ã)JXŞô}ÂÖ)r9eé—I².¹Ío
¢Æ¬·ñµğ÷¼"êµEŞÁ÷×BË«IŒ§8è
£u8à0®
Ü<¥¨@²,†LU°Ó	¼É<
Úİù9»O¤¿â)Å8V0³S˜%¼Uy>ÓJUä~'$«ŞÜ¥)ŠŒŸ¨LÚñ'ˆIî[Ñ …«p·7‚R™pDwyøÅ•ËB¡¬iZ°ˆ¶ıõÇò¦·Ï„½øÓ³3 ô«±­ÆÚ5Ô[\à§I5Üœ‹,‡#ìWöQm*8mÑœ©ıœ-±˜ÃÊ867ÿu0~»=Å,q„¡·ÄĞ`¯uİºåYµ#ö™´tÍÊĞl=:GIG!›LĞİĞ,àæ–"Š"ˆX
Ş_«ºÚµKnkjDuXÔ$Y£‹(oP†™Ö?ş¤Ë‰±ÌPg©aäËƒxåc)i*ÁO‹‘›‹DŒŒy ¡z5lã)QgSI…‚T¾ha,ä¸ÂÚWÅ3›û6Ğa®·1$ş·\s¼¸¶/Æ wŠÁÁılºàóï^NAß4¸Ú’¿t/±§È!¿]¬éÚ
•MRûLÆ’û§b@^j—ëQì¹@Râ8šÉ"ÄÂæ1|G¸L	9å³(•>¢\nÒ–/Wg›¦³œhß;ÉPÕ›}¿NóñKG¨Ôu•{M|ÃàÄˆôXërwÒ­ååAÛèîÇMr;³”¼™ZÌûÎŠUYq£xİTÏ®‚µ°xå"~×ƒ…75æíèM6.Õ8éÀ¼r„œĞà#k‰âqæ†;ÌğpÖq5ôÀ»ÙØÔ-™”ç¯ù¥Æ™±TÄĞ‚¥ºBŒÇƒF­®£%!"å{—ó‚®¦6“°G>}_&]ùØÄÇïĞšîSS˜gĞJ9î^>xŸ_äú¤I[…|#ıó±›{±.g+F~GÉdò¥DSx:1
WGmæ1ÕÚéN™à¥¾ß,‡×
ä…©„DÍëôu£â$§‹®s½ì >iÃ¹Ï:–QMÇ®ùiÈÆõç¿Qš“2T¤™IJ”ÑóXüãüÃ%€Ã¬¶Ìú¾øáPYİ6¿–[åç¤Çö/Ìµà[¾Ÿ.¶^¦;411Åï#`…şµS¿è·…¸4ªqéıãT`=üA¦]€vÈ7Hò+}N21e.ÙÄŸR Yš‰÷pAËêÿYçé€ºrşèöìüe—˜ıfP+ycb(Äm¤–`è…‚…hå÷e
41Î¿Ëe%[iF`6®¦|%¿Ííüêz_îÙëÂ oÃA,}>¾5%>îÓóîÖË÷i·ÂÅHWšH›¡\[×ÑçÒ$wég¤ĞĞ”š]0É’ŒeV¢é—(1Œr˜'øZWõâ?Ë*İ.í@Â³Zÿ/VhŸë8’œÂı_ç¼{/"eÕWä¤Á&ˆ²ª²ELÃõ"Ñ®
t·¨ê¶wÜcSÎ§¯¬ÿ7‰6Ûb0©ø@K©jñÌNn7I6*6K[TñÅ™x'×Öxå¿$şû	ï"™Ğuçğeâ›•óHB|"½•ã¤“gÙó×¢–a(ğOÑŠFê”ëtÛí‹³Pé“$¹”#®BHo£FÍD6
Ùòó‰	ß ­_;V&‡ªB(‡àà| ×:?LÔ@Ş^µÑÄ&ëÓeƒŸ—[_1•P;³6!“ˆ{+£ïìs³ÜÇVmŞö‘%³ŠÁ‘–»ê@ğ›BWoìs_JµÇ´ó\¡íFšƒrëy[~]ÑÍmYÃ]3ÖÕ
õÒİEüÄYMÃ¨ÚÂ/Bƒviûˆ“ïÌç‹ù%‚y&v
•]jälìÔ¾m´ÑFÿ&®³,ĞÍb¡ãñ”¬šVØÓG,ım:Ë]õ¾€'|›ŞÊïrŸL•¶7Ò|4õc[ıÛ–§±[9ë
‡Hï˜à±Xì)%Z¶Z½—¦ŒšÓ¤¢F¸<ë&Ä¥àæi…DËÏînD­SŸuj­/
£Ç@AŒ¼3s ªî°rÿºÉL’¬¨~ÎTÍÄ;´â|«ĞµLÂmT”eh¥–î¥N°Ş¬êù]ü¶Ößñ™½
'ád1*zÕrÂ™”ÃÁØQMXîº|x}%àr»‰è$úhÿDkòè¯ü[â=C"è Q|áGe¬™›Á/µ)sŞ'ïÂ~úª¬\ —Ó)laæ“ûÉ+³Û/ TÅÇ++ çÀù0¸`i/’oşmVÇ;ïSWJíò	¾š\zP“³¨
öËÙ@ş–¼¸ğæ@×Ù0	PÎôdD2 (k	Åô½@¦•.í›ãÎ`ÚpxiÅl¦&/ ³Á0» Åûˆk]Óqr÷í!iëŠµèÿÕ{¬ŸAãö,·í7·ÊŒ¦†‘i±rğiõún…M¯Y€@(°±Ì‰×›W	Dğ{«jµ¬ßÎqıúìı¨Æá$±0 g—Ë¢7úe‘™Ø¦pŞãÑ  †ÚW×Cx/V•ép •ŞTœlí}Ät¡]f&)a3Ğ~—-Í'İş ¬z4Y Åc—
3Ü]úëoW›µŒ’6KçÆkr¯Az)€HÀ„·ó§­"àÔ°$1BŞs÷¬T²×4ËQØ—ÅyMÃ×1´;#upÜ‡Å°ªCO:CĞ`ac9G%ÃLÂ`„)a Ú6k¬‚z‰y3c‘|©şà:y¹wÄ2¼HO`ÏY‰àş'MÅ³bÃ%ñ¬EH”è:“ßsvÓb µ”eü1O.à_ÿÔñß2ä>ßæ¡
GıRê!®Ê`µ@:£ë@Î’lÓofUÛ.µ?‚ùq/£l´C i‡ë:¯øE»_ÅÚéÒz‡Êº{X¶Z<iÖ‡jğ)wBÊ<R„+´)¿<mô¹üæ,¶îCö¿úÄ4­­ÿzk«!—Œ`^Ùîf;m/ø~ÄƒVg],Wúu­ğJ&‘¤F+´‚—c¤t8ÌÓœF@ê``NàÊÍlÌy2³û¼±Mê—¹ÖNk”)0äˆôHDï’qC&XûĞ”O6†Ş¼,º{±6YÛënN	¸z¯D
€’lñÜ¡ö÷Î˜E+–O¾Ôšš·Aøûš KÁ@´Ë®ä™]|¤±”5ïÉ¿äÏ(W>%oR¾u7$¶µ.r/˜Æ¿1K&Å·,3mñ¡È­—;aøĞpç}—gÂ³(g­ã(?©Éeæ¦oglÒ½^¼w|Æ…²”(o
ÊĞCLy|Ïër•Z2díÀİïÑöY†É`ªù	)\Îp4(ôyh±†úC<­eâã£Ë1ÕÊµÑÂ8uéDÂÎ[ë³ÉËòWc°–g\ˆk¯*k5?`Á­¼ıR“Íù¥®>¯a8êèÅKMÒÉü¤‘bbµRfuÑx\øÏ±kşµw¢IŞ¿¨œçí"D·qü
šŞ qCêõÉ–ÛûorãB~_{‚[y®®%3 x•™È©5aêZ\.(Mec¶±œ9ƒ SXpZİ´İI{1×7ß„ÁÈQ	Z¦ĞËGõ'“>3œê:Á7‡9úUÜÕ‚b ¢ÛB‘üE²Ëe,Ëñ“Ñdö¿ÓMq:I´)Re‡7yj á¹‘‰ ÖõV\ØZé!ÕQP¿u#	Ï‡ÜPã0àÀ{ò*—Ò†aULø@S{bñƒ/hkw‹•Õğ `Â‚b$ÖH¡€ÃÖQıbÎ'é´¤FéØšY­Ù:Êj'FöÇàaÍøPè<ÎlGG™FØ%|ª‹P¶ôÜ\ğI#9Õpî9¦%ê…âXTµà¥òã±2bŒ®æ€W”™İßÃÀ\Ñ4åFÃ”öh<¡Ò>(`58’`N‘ã.ú70C•%‚–Rs>­ÜãfÂ‘s/‚?KI†+õÅiÃKÍ±A5z÷€¾'ÑÙ[8 *@Qœ¥¯ùe”°”ä“Ñ1ˆ|ää6•2¸™§êpâÇZO	«\€ÒÿÈÜúş+üEV‡MÀ¾š<#å¶ŸµYÍHmÓwõidûĞ˜«“èŸŸ#¶Bÿ?åòå¼(>a<Ö_U?|ìD/½?Fñ!‘HûßBÛ„½o2Ş—zá* /	1_ö²ğØÄÓ›ìTívfÁ
Rm‘ ‡’”qœÊ:Q>4¦âbŠN¿K½#pğ'ÛŠº´@—™7àáyQ•3sœASF¤şÚZS¢¥6¶ıâ*4R(zñ¡P1œLoxÕh­êÃ#õş7X8È‘8€ÇØÄUPbpzCÜË=)™”°Êğ+Òl,é;CÂ9vH‰ç‡A¤šL_í}'Ë_ç#h7ƒğÔäÆó¨ë©2(í<Ìñä·o¯âã¢k¾ì‚¯S&mŒİí×w¦Ñò4ÑZ—H ´BÁqâææ1Š<ÛL}Èß´Xûã/Ñš9Ÿ´4‡E8Z´Ë>ÕçTu»F#HŒ¨ĞÈóñAùî'`’ß|ôò¶Xßl[B3Kå–*pù£ İ“#î²Wm3¤guÕ<®˜BÕ¥»†pI¶¯7¬Ÿ^	Ø…±eZcOšíTìÆ©ø<Z*„ĞæÖ‚2ÒC	c=tk
óÑ[ïêÙ!A§K†mlÉõP¡)¦yÌ¿ÒÖÑK\Q¡-û×æï.ötÕ[±¸:}ÁfY«¾!íÈ×¶Íİf!7ËŸÃÉ\æ‘¦'YKI·ì˜P(ô/ÄŠ×qE=†¼Ëœ¡Æ{ıù™-WrFMó…ÉÁÄ? %õ¡p™ç‹­,§„$@bo;¹ÖóÈµ‘Ïs7Á"ÁÑé×=Šß2²{#9ÍUìnÁˆÄñÛÊ¢†7Ğ,Z®æjkMûïè]8Ï§)êèºïzC¤ô+ ©†¯@
Ôï‘ú¶ÄîlòÅèd0DÍàü)cê>»»6Ä¡¼G:M¸ƒ>¶)LÓ›w¼‹cw,±Z{ªöÌuøSƒ¿>Ô·Ä-ÃàèŸy¤óF‘øZÚ,ñŞ{IöÈ´ï¿ÂíÅ¾ÊÊ_µŸËÖ9c –9.^Xhõ…0æóôíW\©ùëHõma:œ˜öXı|¯“ú@T×By#Lø/_úÀn¸à¬¸lá5?‡²P6_géqoš+<V_GJM	µÑ…1rVq©åfÅ%bÀá¶p¾)U˜”mÁH^”ÍT_úÊF«OU”2>ŞŠöQŞ<·§fÿ.(Oái#D 0)H€bÄ#o–0
3øŒVx4é}~CÏœ8ãÿ¹ÊŞ»×€qÖF… ÊÆA8&ÓV@¨’…mjÕ)n± !şU»¾x[äĞê4§u"[¡¹1F;ÁKü›äÜòœ‹XŒ?Fyk¯ò¨1RĞ5I×8ªŒ‡ù'KÊé)–ó¦ÀSGÔÅyZÓÒmAXA¦ÆY¨#µÒÁşÑ²mº3àëaPæº&A5ËL)´)´C.-oÊİ€Ù+"w½ÜjJ0¨Í.NÃ<0™H€€iœ¤{c+@JÊ|í´NeØMíKÕÿ.ÓGÿOuÚ’xKçÂ½ÈKK·  wY:üİ†_b®D”2İB«;İ¥ŠÑ]øßTÉ4k}Yo‹"2³.ºx St5œpA™VØ¥‡²‡!MŸ/‰TÄ	5Ì™Š’˜A³Êø'®ş$Id®«sÀĞOúæ¸€öò®u`~	ğkAÂg{y
š²™l[µ#. ³èÑç+æİƒ6…7uµñº %Jp>0Ûƒúcà=V{¦¾ğ÷ˆğ$÷*Úç¢%Š;/’Ó„·ŒˆëeıúˆZÑ~#Ûªx¢f@éPºYŸ0¨àƒufÙ€56c?nG&âÀyü?ò[ş¤iŒ ö•Ñ¾‹yâ¨Èzç™ úi0 Âã;y½wPÏ8‡©ş5€@.–Ÿê¿¸6ÑQ— G£I6Ÿ9âº¥S[ğ¿‚w4'Èé%ÅÚMæîDÓ|N¯hÉ›àâ)0Ä¿EÀqÎ?3Ğ¾ƒ„°ğlÁjğÆA$Cèß }zœoË»onµ§0Û™, L#==jjmjDº¯ÚöÍ˜÷ıW¿TÜûh"ÁIHòaŸr(áb1ÌaŒLB>iêlÚ(È‹AFÀ(×YÙ²RQ‡¨ ú²H öíªğ¬gcúõYDÓÖmÛ«SãVlÖ§ÎóñïûÑ+^¾K}¢¥¿>Ã·‚Áî°XÏimªÇ¿Ã”wúu÷'º¤+œd¬B  ÏúôIee°k›8¤P7$@<~)İf7ZZìı"êÜg÷ª*Õ2+›ƒˆ²©
×³ÁûÙÃrS¿uú ß±ï_×èİ3!µ4‘ Øõ(`óƒ½Zª©GÊ©\£šÄ–”1ªDĞ†º—ù±~3X@´åZ† H·ÏîÜ|Ğ
„ÔLÈÑ‡µ8hw‰Ìt½¦²È…CT$æø‹Hq¶]’‚¸QúÿÕ£y`ùÊSC~N&#‡£2Mÿ
k[Ôç£ˆÆİáh.Ôê<Êl}Ô´°K…¥ÁÕ‡‹¨± %Í*{*VMË_å.Øoôş©Œ°ûˆŠŒªD†’]£+ì(äŸÎ Pğê3óFˆãğ6IÎ{3‰8V±¶€5¹b¼›xFä¢(%ñ&8’¯g%q©Ç750Ù*òâWMƒÅ¬ôh ¦‚Â!UúÚ¶‘0
—­n×›[Kˆìg+).RßƒÌFÑßã´Í!øó"fÀ§õ¢ù7–G×s)”psh²™ñØŞ.•A”õ¦8ĞlçJöÇ¤=R9ÄfÕC×d!C>Ø%´œÌÌ	xÿiÏ	–Z»$¡Ëã¼6O3³{ZÆ7äÚ×ËŠäåı”îÁï¼{ËH¨ùşJ9ä7¼tzÿX]qogÕP:|Øû÷†(?Ÿ.•Ë
²@œ©k‹WÍ¯Ç€ù‰ã8ø¿€Ömî3éTÔ Ò¬<"åÆ»Õ·K‰Ñ°:CZ;ô %’5àw.“ª¾ZheOÃ5ğe"w÷ğ"”¼³2AWñÊ)'îOKiƒ :›Ÿ£»ÆgÓ9=t÷Nƒ_®]ÄmuZoHÚa3À.§cf>M/W|ÒsØÑìi£©Ê—õÍW&¡ı£€•ßÆ¥¼”ñ	£ğÓ¯RfPù¦ü‚…x­?00—ë‘P<iRc]÷fØ¦“0³TÍrÿ´ÕÅ<Ú?M³'‚;^F›İtÇ0B¯0)’ü,=Ì71ñ0–ºåëáL­rşTp;è©áÌõiÔş;/´àŒ¥hÖj„¸zå£NÃ€²â¶G*–_o‰ûÑRbı1d¦æòKê¾­Ï¡¤÷Ëás0ää\¿»A=SÚ‡y™±†ª}¿oœoğÌ”â…<o5ôUşIKèßhœa•Ø„ÿ‡JÈ8~ş<æ!ÿÿ mpršWÃÈ\¾À5©@ÀHÄız++¤ªH?”ó½òS˜`èóâ5áØJ¬l9\¬È<m2!í8+ ìÅâÅ™¸í~¡—ÒÆ¢ëä’=
¯†ˆaœTˆØyåBt?â½îÂFôä×0É„9WT¥‹°k@Ş’AG”Ù­Š¨g^À1;‚Xvå©HN€xo;tº™Ÿ«ñÖĞÈYb­3Q–†±³Ü~YY°ğVá÷w‚}Ü¡%¡·Ì¤#`ã¾*´;¥jG¤ód'D6”šIf£òC£. v)Ñd`Ô­ÀVu’ş
™½U •y¡Š‰%)>K–ìDë4Ånàœ¿?Tb™æ©vg†®©#WmÅR×Ã:Uç¯œCöLÍéÂŒ)šgŸ	—?£µHÏ¥çß3ºŸ5İÄvuÖ„ÖonM(7Ë”9˜ÖŒ©R5JïápçëÅ­©;µO6‘š€d\àª´)
µ“âµƒR$Ê/–Cn’ŠŸ&ÎòP «w( }xòeOç6X!º“o°†tÍI§%ŞägÀ°rÉˆ¤è%ªvf®«“Ê eK¾Æ²ÍÍ6n:822‘ŸşäĞ8ËâYü3£ïÎÁáƒ øğV¼1¥Ft¼ugF^çÏN ºcßë•íÒNxTJF<Á/Ô^ªµÕi{ğò¸Nˆ8õ&P7N»¹œƒ.æªØ¾ñï“c„:ˆ¢8%6_ßoa”ÛÀL!„fô*/A:ê|ûö°Ù4±v ^!onKşev‡7{ygG«õ¶¸>:›²ÅÊ ²dßš!c’Ş…˜­pßÄŒpÂ1Â02RsmP¹²ëOEù¦ÿÛn_Yo¿fsÊ¡Ù¡ı50–ÿu ñãŒ¦Àªm’à^ÏÁéøŒ‘è.2o†öÂ£íWÑ¿<@Õ°Y\Åó
l)mù˜Œªm•><ëÑñUIÇÙLæä©óU7ÈSn>Áj°î©Ù|os¸¦@ÿ€xØ¯óh]ÁÜEuˆ’Õ4€4"¼\xbİ'zÜÈ§4ÍW’rYæØº"Ïg¾m"¸Ú=I¡@ufhÁq§ÖÛÁ`Ö<8Ÿ«ĞXRl²ò0mË$Œ|7b,Wÿ¥0ÿëÙˆöU“ï¾RäQÅ6˜zác^ Ñ¾ÉÅºØfÿbßKQP†7Œƒ•vÍ$h3Ó®˜õ˜½«´ìè–&Á~§¥º)ø;óãŸâ…wş©±^­-R×
LcãÕt $Çª
]$¹µÉ‘êğÃi	rú¼œS/ÑÓèÀL|‚››Ü¼O-Av Ğb™ï:¬  âœ(SéN›ê'+‘×jy°&Ñ¤&Ì:]F©)„GŠ	ÎJ¦lĞ q‰ÃyÊò'?Mâ98x`{õßã*†Ïrx‚©Æd)<o¹Ÿn`Àk6{OévèB7¨òÃgõU·»jb½cFádÉÍÂ6 ±»ğfYPŠäB}QMäğªÛtrM½„è¹x½¼N¤Û–0ÙûãÛ¢æb4ÃXKü\x±›¨v™l÷XÇùìhˆVèóo0Ù[{—¶ÚÎ’Ì‡—ÌbA_‰”ÇÿÇâÛm»	IæØSóÇÊgÊzsmß<ÙÜ»Á|Khó„qi²Õ¥_ÕÑTü…lüŠŸwÄœ¨GŠ<A) O^zŸ%‹O¬Ä˜vÁ#eÌÔ#>E§C°£’½¼òkC¸ N%ĞŠ/u¶†å­v,ZÅ¸f@ûÓ0ğ²Tmr¢¶‰\“{¢Ê%'bp‹näFhò‹#¾g%EK«–…£„¨…aˆ£á
÷k¥+äßÉˆsªÉúıÙj")>®l	Ÿø< ¿‘ê®ÃŸòÊ¼’-He±sİˆÎl-z\8b#7!ÔXcƒÃe<zb]ãÙEDÓ'+™ÃÑA*‘E¶p¼şÓÊÄ¨‘ö¡úÆUğÂÌ°¬Yç¾0æ3PK!¯†…Èìlq£b•H¶U…²’¾»£ËT¯&ˆˆj»MœY*fU-ÊÑªsòƒut+~	‘™¹!÷‹J-b²N]ñÖ‰ÄV#Q-ı6¹à†ÚàØŸ[~ë 1xÂ¡'6?U:LQX¦ê™Qƒ¤®uä0MEÜœ8&¼ŸˆªVQ»ÆÚmq“ÓO805°séĞšR¥.~É°J†´7o<«L;æNæîEŒÉ{cÃ­-_’ÂÄøSI³p¸Mº…ô}œŠ…I~Ãë!ø<ÇE[.¢½læÃU9Ñ“idœ9ãwåœ6¯óTµœRDjö{Í(÷Æ”¹Š‘…;¶Œkkm&òßóuWt&Øäf©³Ô€¼6t¤ªî/ıµcù¹G‰¸ÌO“ßíòì:ãFé #|D¼Éò™³»—J±@¹çZ4õ0ûE:WùFfàg¦øaö?r”£6'Wğ²EÙ¦d©IbÓ0•4JÏ­õ&`pEÇÏKh}G»¥Åi¡N•{YÏÏ4Àõ¥z,vqñªK³2»¤9Å=Á•<±â©Û\ÌÛİÌ_ÍÚ­‘„ı¯[¼ õ¬!“ßt‹õ-Ï‰}–Ñ™ªy"X,Y‡Ü¥F×LìeÆÊÔÒ‹Kƒ@õV G»˜§¼ĞÜD‚İ(Ëb·Ye¼ÈÍ¸ˆ¦ŒâìÛ-ÂÂPS tŠŸ§ğKŸ¤ó”!¤¯~õeN	p(%¤T¦GN:ß3ÅE}ú±N8Ê!Í¨óhBl£ÄfN¼ïeÀ¾î¸¦KÖD`±7¡ˆë–jÑ¯Vª¯­=½Á}Ê³"“ÑaˆÿÌ¶ÏªÛg(psPûû­ Ùæ¤şve€„Á;ñpoÆÌì¸ ”R×ä×š«ñ6¯'—â§ªInæëVêÑïĞøÜ¿_q7ÈqÌ@õ‰W²‹²[S´¿‘?(±Äº¨¹_Mâ†ØjØÖd£½ş_«ÿ[†Í¤tPÿÔ‘k-ü¿c¾dûY@š l]G/uø§IDØ(;‡3½PS8ĞØCX³ûRúğz*få¼Í(‰éÅpÇã¾8wÎ«	ñiõ)@qÕÂC•ş=K¾p(Û”©Êhó¨5 ğV)*fA-wö]Íˆo]šÅris%wêt\÷}ß\p8’K”d4´X7g;6[ú},qóaà ÎŒv2V¢Ø¨7Ş,ç\~o“¯C˜ZØf&1nY×
}pe1l­4‹6ÛäN )ïY•[YÓ¾ªV˜JaùPrœ¼Zø;À>¹ûyĞw­nŸlcÿrÌ!Åq‰e2¿jø-ƒdaH·ó	8|Á†–ûƒ#ßnÖ¦î²{	b`1ËSø×êG\~<Íªi÷Ëzè©QåRñI
E^”'0ì'¼ÏÜÑ%êØ.m«©î–övQâåZ¡×ıöò&ùÕ/ğ.ëˆ'ş•Ëò-víäggÆ¥©
˜_’Ã¦“orõ¶*+†G„‰»29oµO
À…µÈS£¦™¢ÎI€¯·°bş§škŠ“Ï·nô>VŠÈÿÅh«ş““.ÊhyŒ55€DÌÕ(Åâzÿ ,¨òæ¥vpçº†h>1_`çW³ªQ|l¦¦o:Ây»];Âëœİ@aH½dp°wz~u€G!Œ¢k5¯¨¿Æ	şXˆ^n·³¤™’Ìz”Ò\ "	,CùÄMTnMûÉOdB}\išı‹Uâ
¸)Œ·i|–qvÆuW2¾rÑî{­‚,ºP&zü{¬â”é®\ø¢ái2¤¶šîí ôoÕ$dMÀ!B•Ï
<bWÇÌsuh[³ıÇ	&‘wı“üÂ|®úãfp˜µüÀ×.#œ¡â<+L¡`"é%xÑÒ§ST,¹Ö’?.ğ‚+%Ïáğí€^$Äya²eF´¼Kš2Ô’ßaè£‰âì]x}ø=`ÔtzLÌ¦÷â“%BºmÑ;~-¯gúíB¹àC‚èX|wÆi¿:ßNlª<8ùBVkï%€äÀAúqƒ•„è6»şFP®_`.²Æ;S®áSĞ©ûó“¬^HLbÁM?v·ŸÔ§-ã k^Ğy‡’Švëgİ›^nTO‰çëçzşg?YŒ(|éD¨C3¤@ğpgFkÑd"ÍTš™.µƒâY\Jğ¯í¼©jÜ?y
xY/ò!*²7m(Ç"CíEoÔ¯j‚Ğ>îFãÅ¨£øEBg’‘‚Ûñş2ºIPoŠK­šÚÈ !]
ªV-v:.DDŸ‡Ù¤¥{æw*`’ñFŠ¸İ»c–ßš7–>Œ0õD‹×*Õ‹/¦ÚåÃ-aÉ}”T¾:°ö¶»ÁÈËš›:D€y)t‹.ÃgCKËP® da·µ3¼53·^'ÒÇT‹mÃ"øi-V °ı‚É¦p7^è3½œq]!»5'ë=ëUO¸3¹_½Ì¤ÖQÖŠZĞ ¢®îèJøeÀVû¬Ck£ıêÉRƒcÉªz­$#9|İó‡\ı¤2¯ÂËy2p@QáS}ÑKR€‡QAP{Dz=5¸Ë¹VíS;Û¨AÔ?^9	Áq—ï®k9âxĞş3wß!±£qÚü­£s>û	ö®‚ ÃˆÙ…¯$ì¥
¶3=(Í¥a¦A›	0âÁº—76B·•%ÓÄúlğ'5Æ€OñäÈZ¼ny]h¹û“Óî>'w(\Üz@°ïdx*|I’MúÄø‰Ô×Åæ®ßŞ"TÚñÌâ)ú ÿ;nsj­f“Ø¯+°Î ºv‹|Ö.YÂæîCP3{È0pÎ36eIÉ…ÌV¹Ò<kÒùrÒÌÉ§ş >BCÎQ#K¢.[ã/¡[¹ 2&[9üÌ{$·ÜYìË'?”›Í$O-ó}îÌ\WÌşÉLd¥×[L¦Oº÷JÀº+°‡%}O¤e1Vºgü«‰ˆŒ Ñ\ÅP®|q8©Oyh‹Ğ>nœú¡æ0>¼V•¾ù‹(6ñÉ33m±„>ò Â¤œ15ïôü‘0Ê§.÷*µ_G¨eé/PH#4$º“³6¬‹MVĞ&KD™;”rµªøØöPİ¿ˆ~™­6®¶'¸ °@ÂöU	ëítu#½VãÎÆËt/Û¡Pèÿ2OERÍãû´!?X»ˆ@HR´úè™Fƒ·Ã øJa²‚6ÛcaŸnø İĞ=Qú67­Ø4¦ofee+X¨9!4Ú6|´˜’içVğKÁŸ§Ü"bà îŒú;Ïp'RÍ¦TÏWSdâ”î]é^>[¶ìg3XÓñî½Ş!³Şäx>ô«ƒ·HÒIó‰ McÔPGŒ[÷ëüìøzLK†fYš€[q±å¥rŞc§¦µÓz›‡º.HNê^À‚ˆ˜]’o€²ID:Š*+ş
‚ñ$Ù/ÖÊéİ›|ì	ÿ§+z'`mæ_ë’\åÈË<çTèi³0™Ã$_“é	.¼˜!]:¦4ñ‹q¦ÛÃ“D½2s°d´ĞB‹"‡¸Ş-ŒƒN@2‘ŠQû$KÍ•öAWp#Õ!;-	m¡%6X%\*!â9NîI…7`äp|zŞĞevGØŸU>ëUäf`ã¹ì í®²I¼¿,ƒeeÀ¢6‹K­Ëz?ÒÉM”DŸT'a[0¿€ÀÂÄ»ßâ 9ßøİœrë[œŠŸ¢˜F¿;–+KÄşÌUº	ù¦? ´`!úB!İY=â•}H¸À9ÂÅh½bºõ‘…r¡‘•œ°5:¨#{Ï‚/%µS¨pÿşàö~æñÙÔÜea>ZfûÅÉ¥!GêGâvéïøi¿ı©Ë\3·”1#k2{3I¬Œí\^ÊU²ÂWûe§ä ç8‹ 13
bzy¼4¸’}WÇ`šúDX†«&}^K²E@ªz/o/¿ˆ}ŒšĞäŒš)Ê=ÑÕ2¯õÇOM¶0—$RÎÙ>/€kâÏr¹Ùâø¢ˆÁÊÉàòV·á\hô©eÈ¢…¾2Urô„Š¨)Ğ‘âØRÏáôü@7ÍÃéÓ£7¢»:_+Ú‹cèõtJ1¦Cpâ6l‚h—×1Ê¼)ªÛÁîÀ±Ç”Wí(£ÏÒ¢2zÃcT•¤®|#+ü8´r
Åyi[_Ó÷ˆ¶2ÊŸBı}àÆ2›†Ú¦Ó˜-nğÈ1¬¡„Z²aşÇóÕVïØµJ?ï½2ÅG—÷æ•Ëè‘ßHÏ…‘½áÒ&i¥&+ùÂ`¬à2bëÑîc¡FT?~ ĞÑŠÇ}‘U Ê3ëËOVXì‰¹¤M|â+ ®qn;×rG3æ;_³¦=¦èC²·ÚäjWÊÁÏôPÓA«­FÏä¿j¢wøJšÆàÛŞsô*é³²ã´GC+Eëøä‚@r¤=Ó“®D¯(0Ù5.*qõ»Ä¬³0F–à!è/ÏşËËBYi{^É·R%>Glûí¢›Ç©ïD·~/÷ËÉh|Ù‹Óô<{X¤*£j)ÿ¦ÂvÍ KèuQËeÅ#3AW.€°(ş}Å´“:Ålo™ë,@İÌUªÉA, 0±w‘-ù%äã¹¶\İ0¢ß³ˆQ3V40-¸Ú~G¹Ä]Z¢K9†&Úk34'acy_9‘*~™_.GKªMx±ÿÉ"FìSä=eÜ€fæi£YÇõE¿÷ø/FâøÿâöªîG¿Èa›Õnƒ¯Ãiä¡Fáƒ±Á«ÚÚÙ©ñaø\sRwÜ«Ïîn³HÈÀ“"óªŸ¢"¸G*TêZó¦Şâ>Iá)“¢æ[&Ò2¾–|÷J¡ââ"[™/ÂXOÜ2ÂÍ€pHNk•&vó9ë®
5è6“ˆİM•7/ğ||Íö´ê¬ñ‰3“¨ ßrÂ4éª	ãSĞ§`×ĞEvßÏ¸ÒÌGe.H0éù4]7åÉc /P®÷†G [–Óñi‚g´‰&Ö¢M—ÓvO`¥6"Ø¸$kî9m¢|ş×F®İ
IˆÀh¶µ.|yñÏ×Ã˜ÃFÄJp-"d’g3íĞ@Ú»•¯Æ"Ãuæ$˜+{öÇÁ¸è\‡Z	Wt& 1±™ß4ò‰…fAèlAƒñgÁ¥DØî‘ƒ4n¾›d&Nö{;TÙH^e›ûE©¤œ.üÎ
6­êa··W#Ğ¿K²¿J‹zz‘°E0Ã$4ÙmÎá †kDPĞŸş³$2"FP(ˆ¶€c`¶¦Ä¿¿FPyêé0K· }]I–Ìƒ;
İ9iN0%ïÔ!JŞI¢‹ ‡q%'87%°NËˆF£ÅO‹Êáoá‰vØtÑ>“¶}5Tœ¨ÀÂÅí;e¼<˜pÈ›«ÍèĞìuAç;îÌÄËÀÆğW´“šŠVŠ-»„ØXß§ÉiÌ=«H®Ï~„ò§öãuW•Q¬fÌ/ºğ‚o‚ì9ô
]Eõ3 H’%í†õ^áõPà/Ø-šµ•×cº5íóC p·õàlÜ0!ìÎ³¼3yî¦U£Ëñ‰éZÂ¨$é;ı!,€PBÕñj¹íé!$(mûÎP¦\øå"À‰+ß§ aFHhóò/*jÿƒØ/Á·”×İ]“K ë&?Ñ¼–ıö°XŸÖ¿i<ÿÓöÃ$ÿoS˜i†Œ‰jÜpAZ'^J3Ê|~[š·êV«P¹ËyÑ¹é1Æë:äíÇûJŞ0·ŠîFXÏ‡ñótè/-W@6y‹Ú {Cä%–hE9w×›€¼ìùV|Ú$ä%RJ¾Lu“¿{U5zğÅuˆ%¦îQ/§ä$¬y&<8cg»¬…nÚ­EÉ}cı_h_ïİt‡½¶9¶Cª… ÚU×ñÉÅï‰IŠª¦«éøŞÏ°A·û,Òw3ÇtX}…P[÷·ïF"SÕˆ·ó7¤à‰²ˆªƒM³YÊS7™ëq	É´FPç“—lìünB€”»MÅ_Ağv¿6Ëâ#r8¡”æ5u¹ú‡Ìèwº%O˜&¯’‘i6‚ğ£¨àh\‚“az`°‚šÚ±È­Ò±hzö(æò/^d[©6syW;¹øI^Ë‘©ÒÈh-r½RC‹Jwe¨à!íÆ« üê¼Ş°q˜ÇMvãõ9…/ñ”Ñk»*LTj9ëCßİTã™½}Úáo®´ºè_Ú¬*€	°‘o×¶J(ÚŸÁ¯9°‰y#€÷s<ıÒ” ¢cé[Aİ*S*ÈÊôäWHÆ^¸ùµ•@ÅiÚ1¥É˜ÜFŒ™¼„°ıãD£ı—µL|êoêæğå“%Â7pàuµ ™ñÖÉß¤jƒ‘fÒÍÅ°~¶3yt‘[+½h¤'•5—Qza,è
äQŸjÉë ¥àı %ãÓ“&HæhâğzcòÛx œ€—!+*éÿ>;‘4}Uá‚O¸šàF_QÆ*¸™Ät­v›_¸ÜÏC¦íÂ£ZÔÇo‘Î¡òš8†!ı×d_ìˆå¼'§Ö¥ŞDİ!L8¸ZØÄ&¾gÚ}Ô›Çk•ÜõùÉ•ö8O##dtÏóhFğ	‰ıR·Gëkà|¥NX4ËÓ>#NÚQ[Í±ƒğÇê‚I±@³Ù’½»ĞWVÍÔí~#¡äÖ[¬CBÂ¨Æ}õ†nJ(Œ,¾ûT¥æOÂ³O0«Ö'‰ÁOÕ*eùÅ’õò6Z¿~Ùt•íƒ£üº”C›o©*@`¹–âUFØ8IilÇÚÊÛî ï=I~Êv\ì¸|bTƒÉ€PòT»A<r‡ÂÉÁd(q(*<öZÏÁ‰s±-PŠÛ¡†J+cKÚÒ‡
¬û1LJùÇÕ:XNr«‡PÁ_‰aëæ{ÊZ‹ôz<uÓÈ.wû¥Êšù‰‹¤ÃDªêc r"†B92ã-;pf•EÔ2/~Â¶™àºœşÆgòšUÇƒ2Á0½#Ñ‘{†	«—?dvûëxÇ'ÖYzÓ”µ³[kÃïz“¤·Ş¢ŸBô4!'-4M2´™
İ¾"ö–×î¾Á\¢[Êzñ³0ÕBå/1¦ÓUìÆb·µÚYÑÊ“á~Íf†ÇJ§.7:Šëó^ÿ‘FÒı>Ğ®­‹â´^µİŞM6ÎŒšzÛ(À¨õ0}®ƒp#¹µ>7p	$&@˜H{ëšhƒ›­+CÚxç­q‚¬Çû+_‡LœXøPœ»ß	áegÇ®¹èxn(`ÎÇªÍ¦¥¶TÀ¼·V†V:¡H«‚~G×>Õ)¦å?«„’Æÿ¸Ö‰Ü¯;°­á¦ü¡¨ĞtlEıàD“
LëŠÊoú~î<š½A·™€n©;)f=»1õ^Fà›^ßÖ•^úŠù3\îR»_Ë1(\7ÈpÙ|í} LV~{ãåÎÁ,0¢ ­^äA]õ2©ıK„e±^¨ÁÂ-rÔX$¼M	á¾¢æÈíâ.¯úÍ£hÉ;éåiÌ3»^0wå¢IŞÑâ¡—ÓòÖ1¬%6IøEP¤+zám°ªy‹t•À,jh¬Š,,Î–í]Š³#ûdã‰¯ßQ%·‰(Uä•fóí“ğ1€ğ©^M¶§ÓqÃıK <¬zÈsôtª_?F™Ü
×dËœT3'”$HL…ƒë¾¤9•:’)¨^OÌ%ÌSa{åğˆQQÁŠ…éïâü£Í(P:àBg­îgûjXsÏòcß[„İçAÁAÚŸÅàI¸^»G¸‘Â@ä¢¿z]Œ¿Ö÷0@<Gä7„-s40ÇsºL0i]?ÏŞä]AÕ({+.Ã*£iéSFŒU.œëİWq‘G%éTo¥»w—^Æ˜|ÏKJÚyZ¬W¸PıïÊ¬'jÈ/—=¥=+²äÄLGE~6ÊH`Wå˜õƒôû]óÛÄ¯6ig·™·0Ş×Üºß•—şPùFŒc.şe÷Ärî5ksÄøÊ€Ç”¥¯kàí—~>’\mãJµœèOb%È°\0™ f>™¼\êËúP+fUÑ½Ã"ç³ £ş8šè-ğ°õ6¤2ÍÁ%n½ gîù	ıtÁ>7â·„Ú¤UˆËÔˆ!¦úó×á©[v»x>>¿îÂ&åÔœ™ûíQowJjñD`} Å?‹úÑíÎ@ÎB'†rO­ğ ü?¸Ú·ê/ÓpÒÍ‹Ò	¾º^ŠR¿§©Mñ2¢ºâ%bæ•ˆhäÆs÷¹}+}šìÎ}‹Ööïïoìı€Ã„ñ;*â6#Ÿî]ÿDª÷á*<óåRnĞ¶àqpÿe÷î-Í€˜E8s0ëjAc=î´,ÖAË‚‘aLXê>ŸªÒÇÁ¦ĞAá2&‘•uÁ˜c× ÎÉ\ÛÈès?=É@kÿ[<SÛòã§¾shâi÷2°/4;6k%|äv$£[ôÊ+Ä¨æ°ÈNix–7k\6ä?ÊV÷*J~Õšã»½f`P¸¼m6aßj¯‰‹¶·âyœïĞàşŒúD x>ÃtÎ?Ys»¾”/y%ißík!t¯§È!ö+–úzØdòTú>5Ü××¼áƒV«zÆ`¿Ø3Æ›jÔ#?	åºªHÉËP¯9^†,ü0“~GTŸÙİODU¥!¸-jOã p}ocJ~	,ŞÊäêß6JÄ'e,Àñ©(ÕØPÒlÂWÈ²ÁDc…ş,‡vš¢\†úÔÄBLf_ŞzÒş7e¿Ş¯Ù~ıå;:å%I–ljÖù—m,¥¿óìïÍÓI2“fÈóHgN%ßŒİnhEÕ÷f3¿°i
d”Ë%ï]òZŞ^÷şõ½Á“IÒÃ‡-ä}í¶t÷Bµà9`eñƒÏ²V2dKµRœ …Î&~óÚOë%É°7n’!½b“ı…–Ø‡Sæ…p·t#Wc‰Ì§
Ï!7‹,vFGñ:Ü;•ş\×'¡M”„œ€„û,ERºÙÙ;ìˆŠîUÜ©`*RWV~•z–u~@~‰üaWME¾‰  ?p
ğèUJH½·Ø×;·ŞôÆ œ£J‡«€ß”ÈÆÄÀ¿ã\ÑSC 2Y¯şèm¡.
«ZÜ,açÉùÇ›îğ±Dù¢5lÇÿ–n˜9ÓRTŠSŞõ€‹sX´ò?ï]×ƒhAÉ¦/Àü·µ¾“Â®sJ)G[§$ò–V4z {Ÿ-Zjõ $~MVæ‹„ú±i5	-îq-9”œŸ®¤4®å–ecÔÀI+·.š¨>Yvê˜É!WÜcê²›xD7ct•îÙq^ë¶~@Q0BñH’œnÊ¹èåÅÙì×•í+ö[6ÑîÒwÆª$ƒiÀ<3à £Jå7©a0’¼ndM-X¥â·ÁoÏ¡ã{S©
õöH²ihœ÷ª”ñJ«Ëp¨d;œ·|'Bk[+è}G;ù[cj½›¢tèOØåà^¬6â×“WÌ‚:ŒŒçT'Pˆ¼÷ À1Ü:¬V¶“VÒ¶!‹©q+3¶wŸÕf_¡âz*@5¬ş™mş³yX’8ÏÀÁ>i“_nƒSçH[®-pO?
§õíN,5}lOAè6Ğ~#‹9·ñçG &HSÄz!ÀAõj.œ ı§vm~•¢ÛacK¨Ÿrb^€c¼b±öFZÂ¬”JlÌB'Ë(‡Ò«ıã™ûÕ”>6Œ˜?˜ÖY]k£ÿ×™Ô¸ÿx@0ªbàs¥2ÎóƒpûÿsPqAqqÜœEfÃ©~–<˜q‡q%zb1ƒ7hw'G¸«úT&&™†W×öeV±ñÕÔÿC*“è "GÜÉ;L99²ßå}ï,—ÃÖ­ä!³àùÊå'Ò4ËBë=XûNïT§V½9ab	CNèÃ„İò/Y½[«iÂ¢*w¼wÍûšãôœ3³Œğõ1BßT\Àú&œ_9s)ğ¿yßöq¿ç7‘æ^<bÑ™g%S‹«¢È¿R=H÷¼õvúL1_mš#%½±B?O‘/şË¨÷œq¥şõ™ˆÓımqÈ•¡»÷½ù´v°¹A¬İºuÖ%š‡+[«°Şï÷§‡Bâ%Ø|ßlH’ÓêZÑùÍ4*&Ÿñ5,NåK¢f×ÅÓ¨ +·GLi.“ëöhÅÕ«)ä)»Á§‰4Z'Á4¶–U-–x?Ó2÷K!êg×¬U€şçˆ)k_7éjlRµôèŒ‡[÷s3MûBÇ‘½ÙSŞé”ûãi·çB¼bÌnË8MÈ… €Áo¶µûkã© 0¯®(i¶˜ €¸€ÀØ½Eñ±Ägû    YZ