#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1462775252"
MD5="1a2e671df0dce51f81d1b94af39fbb23"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22648"
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
	echo Date of packaging: Thu Jul 29 11:18:17 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿX6] ¼}•À1Dd]‡Á›PætİD÷¹ÿ>
uìŒŠ(Áxö@!~•!¥ÌêöJÜII‰p—w¢Ó]¾¼­|DƒB'2›‡èsŸ†0'Ìæ›àıÔ
ô‡Y’Æş¨%–‘Ñ1÷„+ÎÁ‰mU‹Ia=ôù É+8q5‰iÜe.¥wP‘K£[[Øò	×gfCš>µ•“³¹(ÃÀ–lHÀxRBDéÂUep`-ñ±÷Âƒz6«ŸB˜ü…sdy…€^ÉŸ+±kpB˜ö3£Õ¥ ù2öl·Øå=Ö{n4³S"‘BU?O‡¸Uaå,Â*2À˜{ğÈ®¨µğ”JØ_°£h£s0K1[„¥€BCIèüğ]â»­©Ğ5_3]>¶G«ª4qÍ!ÇÊ»ì¬ÕÙXË867F@ºm¼åà]½ÒPvŸ"#t‰ÁêKª„Ãî¹ùìéºğÑ]Ìœë÷v"œ!vŒ×$DIKmic I5ìüªˆÒá‘©Š–z=‹2®Zr²]y++ñg˜ëk©m V€ –t™äåwkÈ2+ìD7M¦„Á}«PÖ‚<ZˆJiŠÅÁéÚi·¿m{İËCµ¹ãiÌ	7´•Õ0'åÆíÅÛúLŸæï	
4[÷¸»?Lç¶R«—£ "ê¦şA†¨!ŸÜ—èôäìEJ¬:c3©æ.¡âÆ¡®£0œ	1œğè*œÅb¹4V¯›‘ùÚ¨¹oÔTMŞ‰ªgp=n-ßXX.è ÂV`_+¡å4S-àfÜDŸ$UÇï®ŸîR}Š7ş;³f†sIŸä€áA]à3 ò»-õúbè@C­^¬·Ïü N÷	Ÿ
dá­rN†òxæã/¤3q—×{U”ŞY”˜öD¢(lZu×ÃRIçKyá34Ã$t1Â,Š
]Qr7•tŒ(á¸{à?Hám)vŞ¢)±·_¡f0yIĞÜçô†‘IµMÊ”¤²^§ldéû«­PõJ³ÿ6EìxıêV	€üòŸİ‚/ah!…%‡gpJ“ â¬dX–ˆĞÅ9“:^ŠÚĞ(+/¸a ¹İÅÃ'%›'ğç?†"ÌÀÖ2ò?™0¤XVÔB½üŠm ÌB
Ê0ò"^G‰ík©zêú’3ƒµ„*rğŒµ2Ò ë¦.€9=D¿ğnŒÕ#zÄÊŠ¬ÕêÉ‘RÀmÓŸ÷iU`˜ÚSˆHƒöÌwcöF¼fqÍ–£ÚèXéŞ‹‹î”Tòîâ~qû{OÍDe‚OÙÔ˜ÆZŒŸÙ×%Ê¦§_EÛş¢ººf:¬@’pÉ‚´Å0;®ƒò©ÿÉ£ÃÔw¤ÙƒÔF±ĞBÛpÀd\ÙuØM÷è•ŞĞØ½ñ~W?Ä“µ©¡+ióşıÉW\ã¡Ÿ	šîß†ÑÁdCús)\€×Õù[yg ’û¥Ë½-ÁŸĞ”s€Y>æDÉ4¯C’–^Ò˜Sè¡>Õ
@MNÖ-Ü¡¨à=; R½.ÎÑ:³– s[xXëX`šXæØUâyDŒ§ÑÔµ·é%®ÂùñÔíÌô+é $@S-y¡ŸˆE\¼Ü:˜\€‹lf%éX’êòØH
J.×;İnHsÒ	¬,1œøŸt¹Zu‡AËª/æâ Tî ÖQ½‹Áe?İÙÅ\Ş^¶yŸ³•Je»ETk7$nL’»?oáBÈ¡mJ¸ôCÚogÁ¯›£v¬Õg†R¤ÒÿnİW>¾|ÿ{º\Å£~V¦Â×œjCÓøƒõ)«(6íÿ[ÆC‹„üAá6¦ÀÕ|¢`F3¼xÙ[ªâ³kÊÍÜ‹r¿õ_Q^§¢Ú+\?Ñ™Æş”¬¸Æn*ÀÅ$s­ÚçpÕNÖ aş¬‡z £v‰Õî÷ô§×ìŒ[ŞèŞ®O'“@Fé-3š¨@aL»ÒŞTa~JD¢_R‘]–5—³Ö³¶¢(şDïiGa„ #¡Ùìº.Pîxáù•¼hàÏÖŒqG¯ĞyúĞE-ª7uŞÚ¨Ó„>õŸKÎ ÛVL¾Fu2İ8ÑEûz“¡F•ø0ÛRŞ–yT5$½Cƒf%’êìy¦°+íä‚¹$¿±.÷š±:;dXmÿ=—Û<¿@c'ü”WÕ	²A‰JÅ×"ê¤¤;m‰|!d|‘F¨
ê£»ßqN~ıBtºXB£s¡nù›ŸŸ¥èÄİrQo˜ÛK=x÷æÿ®g`Ê¨Ò·û…fOc¥Œ47ÈQN°ŠW4óŞ‰Pã<7  ~,9ÊWna¹\k(Dn¬ÜòVwºÊ8Îsk –´go‡	¸ë Íz¿Bã¦a z~‚o*R5eléMrêNş¡Eİ}ÄªÊÒ,Ì…ÅkxÂ¹Ì4ù`ºµŸ3D[Ãš $6´µ€ÍÇâM¬ÙŒ>,¾eÍ2æeFgkgé—áA½¸¸1†î×é6z˜q`9?!]hõTÔQgK•¤•¾“›+¼Y²fUõO%‘"Èÿ¶°0¬,Ğåb"¤«V0Pıåãi§æı¸h|w K¸ø«ÅdãéàºFNİôØHL>A;#ÇŸßç|ªÓ¼×jÈ÷æJ\/¼\.ô’ÑÊÏ(>yÛÈiÜl-.B•Å’Š†<w;~ ¥ƒµâ>ğ ‘ÓÌ™.‰½ií¥^¦ÿ½ÃL¤¥¬5µÃ÷Ln	óAåàuÊS¨}–óz-©Ñ÷²MkÒ©ÖPÉ•×¡¤ TíÅÀKÑuÍ:}ğêæ¥‚klXÛídV4‘y›–ÊÉÎKdáé„Vzng‰^E÷Öú¥îgWúA+÷÷£áŒ?d§âÓ®.ÛÎ­ j/6jõ±à—˜ÈXHö!¶¥E‚8™•èxM6sŠé˜ÎÌNN,»µhiJ,!Gî8 9Oa”Ìf¶÷\Td“µ\Î§ÙÇlsîÅPı6Š+4O§oƒ ¤S~UÊ6NJÏ®|
nsïwá¬Ü¬DÉîãå#f¡ô¯m^å¿zÎõ‚
§.®Ä0@»:p
}¢ÖÊùª²¢Œ¾oĞKjA¤	ı¡j|‚"ûùÊZÛ$];ñsa€‡º?Ê÷cdúä…‘¬éÛ†Qö²Š	«[ïìXÁS{GR{üÌÎä©	ù2sc7ÚËÊåZNR€xÊZœ‚h"¸ßÍ][ÚˆäĞh·'Áf³5šêÅ¤PHÜFDÈW¯Öb·mbÏ>}À3ùh….Î?ÊI€¾MU	µHY&zÀ¸«'¢ƒcšå¬}í9’ gZ2Æ]¯ìv®u‚Œ{»„ì‘æû\°$–´Üq ¥af*ãw1*5M
Wv‡{ÇFÔ<49†^‰Ş€L¾3š½}·`0š@cX­PYéO³.Â$µô ˆÚŠˆ€<~Ò‰bzBšÃT)4‘¼à’Ö»Æ¬dóVÊº7k7¿@å â;TçÛVÊ3ŞzN–•M5¾oƒ‡#mîå‚]½‹ RbOpòşúı¯h¤yƒ£Ëz¦T€²é–ÖÒºnGºÙu`Ukœ§ì9œLŸMhÜ ”1y¥š‚¦AY|/<Kş¡Çz™Âı?ıcvJ ªGy¿öğM´û‰H‘¯¹P˜ÎÙjèpã(uíTÛ¾­è@>ÊZØÙ™É	2Ÿ8#†*â³(7²a=„|1›˜ú¾»<À8¡^íËÖÔ°D8øGÂ¥Ş«¾tÆÑµııºTg H7jÆu§º+ŞD7“Vdµ¥I{çeÒàˆ„a%§+&[«`÷1r´RUõ¹Nw°Ç¿aÄ±v\å!s~À¯ÏAæíĞ¦§°(„É&”üæ™¢Y’Š=q˜S÷ÚÎzÜ(|Õ2şĞÂîï,èzx/Èo–€%Ïš°O¿O ROP/İÒ.&¸ñÊ/„€õòåy‹şñ_‘»´¹q›‡I#/¥İ”[ƒ§=k"š-9–]B	°4jäÌF'GL?³ <åÙ~Å¢*Á\dØ$Óäûní¨3õäÉ7ÎfF÷išGÒQ†¤À,nƒ3{	,Õ¦_jzòè"oD3À62o\Ğ1MvPYã%µ¡xÏå}úM®12Pö™JİjÂ	a#¬ A`¯ùFVã±=ÙOê2°ğfÂPD—gbnœõïÆëm™L*ƒ‘èŸd4P'ª#Q¤g¹øˆÊÔÿvºîØ	ÿ3@¿‰c¤“{Kóè½éÈŞÜ(—÷ÖlÕu¤§‘s‚WĞÑ&ÿèÍ\$‰LDü“«ò9VÖÔ¨`Rƒq¬Ù¡RùD½¦Ap{‚, A”ÆCt‹º­µ6¨êP?&°¶ÿ~â¥œf)xà—Ì4Ìàë³¾„É5ìğ]ânZ¥ºí„–Ÿ¦'M>æŸÍ·â}åŸìÊ¬±W4•åq`Àö)Ÿ•¯Úİx“Í½ëÍ‰eœ§@âP[¨´œ`ƒnƒçeÑ'kë(«óqÍãºˆG¿¶n@:8ÌdÆäSG ¥b„‰ÇU+ÈjSHı$ôiÆ+­Àõ{[ e£zÛÄ(IElÄ5 å»67¦±û 0=•Œ T¿şı–ä¶Í?hˆĞ§…ıxŠ{®F–Xı¬{Ğè´R”Ş¢q);€Jú42Ã»_?JØßT'g'˜`°FöCc3yı0™AŠ¡™5ÔÎ‘â)Kpdˆ%ÚıMy-¢–H\|ä™Ÿ‡ôáÎÎ÷–	¬8Töô%"¹P‚ùız.S q°pº|ÀsY˜YÃWlk$1ı Q|©‡r±jÛ¯¡~ g	#ªµ­ÃfyùX-¥©‰ŞÌEÄÿZúåÙ·Á“Û	ÂUã}ÌBÓ2ğQP<SÊøO·ôMÅ2zÒ$Iq$È¼¹Íièıi!œtEÖÅ©òÜ””zV—NºËz]‘ñN?x>Ç4ı·µÌ&h»ù~VÇBõ²f¤Ì‰÷‹ˆÇNîpY78œZ3s•B÷aÛ–‡¯pïÜyÆèÙ±ç‹ş
ÿe3ß™…D·¾Åõu× Ç¨4hÔæï·ƒÑOx.©M	ÏÿšáT›y¦3úÓÇvweosh…DœCR ±¡ØJj5.rgêd•Ÿ ;.|$LàÖ8! å -H2üèp}˜ßŸúæW°d
q|}„}zÙ@ç^A`ÌÀœ}Ø!Fß™8w)"B‚z€ËSúNaRÆ}„Z^z¹AKnbã¯£ı)ìtK-v‰‡nq3CÖ¥Â½®±-è}Ûn[âÓƒ&›·œŠ£àï‡‰I¶yˆë
4uÍa¦èÑÂûÆTy¼‹!oWäŞ2ø»‰{ Òî^åæ%DÈ6$˜ü_Ë@í(™®=“p >:w×±q(.úmv»k{‰ÆGô—?ü@6}µÕÉşâcµ†iZ«Û&|>˜xŠ,«a“@°¥Ô¨<2É›ÔÌ65>$`'­µ¸JQ]ÆçålZAø•R=’&Ê“
6ÖÔŸ<‡8šäWŠå– ¨WA-sfô¨1Ó­³ËsŸvIS3`˜t¬İ­ˆ¡Lù¥^ŸÙÇ`€ñsáŠ~h53É¼k
&Œ:z'¤šnÑı¼şõÌÎgAÚ<´%šgÜQ}Ã
!Şøwf†)6ôÃÅvŠZœê9ny+™ß0¢Ëw#³•MÖDorÖAÊ	;¼su8Ñ(”ĞÀs¬fâ«ƒàáßğ@Wsn¤™×bCl$3µıd+êÉ%mø·Í“¨­h7¨š4È¥Äå‹ác³èt_ÆWÕØÒlÈ‰íeºnlvI@j½"üÿÆº?Æ8,c“~‹ÎdÊ‰ùöë3–kC{.@U…+îU”—ûÀï¶œ$iWí·»­l>í<G´ª10P>#Fÿ1‚·Y%7³SºŞ¥¹%Ş+ö³ÍÇYYükbªÁ3#;ñ5`Vt–Ê‹ï89œ|CŸm¹€´Z¿éşç‹¶;†ßÑ‚O³ºáUI©’¼[÷óì€&{Km»d1¯í‹À:òW»+€ü~ÃŠrÖ‹kØè§Qw5€eD¾@sM_×“ëNcšÏá¢*ü¬œa:%ğµNJpp»«Ø	¿øñ¾c" Aø%ë˜³ØJÑÊ´*ïEÊâÉ\e¯–T#ãÿë'¼|ği´êt-[¹ßñBX$ß´¹q,Û—û¢Wî,?C76}+×uéÅ`®t÷ÙìÏp3©Dåvr²±4<UNMHvCº^{[~åÂ¶g!o™ôpc‚I~ƒ	àİ¼À<&Gcq¦$.™o^$›•½:ü•)d…Áˆ²± èíì Ôü¤iÍï—f5Çæ&°,Só
œK†!7‹ƒä:äÅ;~Çk‚#b‚ÖûdWÑÒî@0äÅº60Á Á{f­TX|›êñ=Ó.ÉJ0±ÖlWÿæX^'§”»C­¯³ÑÊÏ&ô¬Jİ?§¨Ÿoá- B°HdŠ­÷WV“‘İRÁ­£—˜©<‹	ä UºëøÍvipAAé+PÚ~³§ëô]äúÕ’\¹KÖQàìª‘bu!x«.ÇHÛºún
,Çt2“·´¦‰c`ˆ¥Û‘Ñ.a¯u}¨ıŞ¡r\&ö‰â–ph¤$T" ´•€¤
òR·_êÄºÂÒÛt¯4–\….-Œr­X·…˜SIG6¶j}7z™ñ”)´kÒë zÏ'¤uõJm7á•õ"[»6oT!<T|}ÍÎ>è;ÌÁ(?¸:••İ<b‘§'N^¨S”ï
•Ğú2©`&T÷„¶×âzÃÛ›ÍüFQ|\üIÅú]{øÜmÒ´N¼v-xDİ2ğ/ú.	ûÁÔ<D~ûT»•ø!Äã™J‹¯)XDÖÔdÉ	ZÓß¬¹ )9dÇ1¥“¡àÈÏS1GEñıµ…?êº†
41ºê“ø*cÌ’Z·A¸NfïïÚlë0Inª•Nc¨†ˆßâkùCÔjÆ°„‚ã°§¸hfr?”¼2R¯2û±¿i 	èøû²	JSµf¬¸’3áXƒ.É'óPZ¯dÈŞJ	ö½2ëEa$TÌª!¸!–Ò†<¬<?Ãı>]8ü€K #ø8(‹]lCš´'K¢“¼¤ ’»ÙÈs²e|‡èÂt«0¹ÈJåø_„²©^OyCƒÛ“esË1Ä7cluRiß™µn)_º6fí¦ÌÇay©‚À+ˆ¿åÆ Ôigû[ˆÃSÇµĞâ•GßŸ	O&&o+ÇXMîçI*ÆñyÅbÃ!E²lJ—ÿ€	„œôÍá±1ègÉ6•İûÿ{Çœ ô}ÓÂDw\V×'%'Çod>TD ­1„~Àphÿ?º’ª*“Ï—q~fä'ª»áCÊLÄ•Ù6¼‡Æe¡È².èÇIPùüƒòÂUV„½\©Ct}G¦°õK%‘eÔf½ ¢5>ÜGº¬@Ài#^¿ÂÉÃğÕøİ»hÀCP\CãlÖ`Nè›gSÉ¼Ÿhó_Øj6¸¼¶{0}Nò½u`æŞq/÷–èbÕÁàváO2&r°Ë ì%Ø&q…m1p_’MÖXA\=Œõ›Ìï–¿¿€X—ÕQ0YG-L7¢»š½T/×\Y©i¸ól:'í§é+P±\ûyfÒÄø²}ÒL¨	lÏJëÉl5Æwè˜pÍ®zÂ÷É“ñ-¢J¢§c› ÔsBNO¿ØS@*«ƒ_³îóQ.°A+){×º¿ëÃÚêëxÏÁ3fÜïHÅkº|_ gRÔU²Î†‚n/pÂ&@*™Ÿ@€FÔ‡åæ‚]LÙ?¹/ïÙ”î²—Ş«ŸÍ!K¡ƒ'Æö5¶ğ(+ #‹îyß¤şÒjd¯„²V6®äÉRİ‹½°xjÿÒ.åƒÌíÍ«Ÿ>1Gª©ùÉ>Õdßê_¨ÕqÛÿ)Zksó##Qõä£ÒÀ‘Â;t+‚Ì‹’FÜÕ³9}Ì†›`C_³œ2Ì¼ıBßˆî:ÃÕÆÌ¥àûèëÆ55W$ÇĞ³7&sÑÙ…ËâÙüÇây?…­ü¥ã¸“kÍ’°kÓãq¦ öWİ†‘|Â]’vÎûô0,}kù»úå?V˜mM.ÉçÂà£nAİ_=™Ğ°LĞ$”DZpGp/ÀlwâSş’Úª™Ne‚$üœ¶F$(´,Ÿğ#Î3?ĞŸ±iåÉuËÆ­ı´¬TN²ìH  ;§ôàóÑüÔ:½B4ÄWL[“7úÂëè9¯­gbú±`·­*¾ôÏ¶ÄÀO²Ó¾ûî°×©aY0M&ÇE+ÊÅ!Ù 3kQä*šşÍr’XVş•ó4ĞêSœì|–OªlÇÆ•øj‹ƒÔÄ%C¦ı/ct}õèbPF½	¸ïÜİëØ¼¤ã¶šãÑåƒüaˆfğ´|kAi/ö—‘)Á"{[Ù£âq/g ëÖG}$ š“ş
=åjQ40°¿±°F€Âï5nŸUø.t£€7jÓ úhÃ/#V‚ûäf[ùî/E×Ød~ª¿Ók.–O•óì“Nlo€E oÑÙ¹ä§4+(¦TpP¡–¢ÿ‘
c­¿°ÿFò•¿”ÊF¥1Û!Š
«EÊ‡¨úÍûReÁ
“äÈm8ÌÈ»<3Ê~°êÛ¬Qï›ü¸5Å>0¤÷&Dˆ)øXe¬Út<m¤m?~ÏÊœ³a°p9 áãÑ»†dƒBÆ)PŒaXe¥~W+é¸w÷ü¯T6ª¾g® Œú´é§8šëº(R>§2~èÁİ*×ú›¨ò°õ¦eº7HÏğFÇ‹õî+õìhÔt9ßó³S ‚ª,XÇ»ª}Ç£ÔjèJ¨‰O?Ww¨³aj|:\Ú]$B'Ry7V‡‹"ŒŞÒ¿*uo|ßà¸87åŸ]Gj™“3_w=¡s`–ÓÿâJ	Å<ŠæÚ¹ƒZŒ ÷Ã«ÓJù¾ë«;µ¥Šwâ4^Ìp‹×M‚Ïø6wØ[ĞÍLš–Ñ•ô-À.ÂlF7xßf3fËªe¬CP™Ìœ|Ì4â^Ø–mí¬E½!âU¥Y[ı	Ùåk›4ö­ÙÁV¢¦l8qO‹â\¡ªE0¤õî>RVy(ªlÀ³ƒÚ©\gT½~#ÚÑ´@Án‚‡_–¹HWÛè³U…Ú!úğš_f0°u³°¸›GĞV¥¼µ8çÚÖ­ã,„fÃa&¾µiK=C%¤:µtn~¾Œ@‹>v²ÖrÛ¾ñíà†Öj«W^w_ÌŸ±Ğ`3ÅF%FbœŒôŠ÷Â&m2ëÄ!‘Ï•XSâ-Yƒ<û›øñK?ò¬ŞÂk¿te =õÁõêJ†eêW£Â«fš7h›M®IšàYŞ˜‰Ëé›>¯)1ÛôBYí"Ü†øØ„§0µø¸n2“À÷pF]ğâ(æ–o¯Hà‘!;çSW¡—˜HrŸt7pn®íÕs2w"´Ç”µ®’‰tc¬èÕh±d9Ì1a ×N@N.bsŒ?óITZ®Íèòœ{îf³Ìg}¼Ğ°H˜3OÙij’3N±šèôîH®ÖX¤S»Li{2
MÔ" ìX'*Pj´*Ô²b/`Ô3É‹½ay·ëúò'¥>ü8Xôø¶Ä1ın)âÆ¢×‰òsxwñ}»*–R4°õÁÿN–ñ£Ô³|Lı&½Şkµ†˜ÇÜµ¦Òd^%0"ş0Ê‡îæ'ís æ’…ÇŞvŠØ©Ê©çùÑµzªu£ —éŞêk™Ö]ûTå»k?$àBé¾ĞÂ±¸IÈhkõĞáÃ|]=‚i\ÏâNŒö¦º“ggÂ;Å+’¨½ë+GkNj"ß‚_])˜ùĞÉ%Ü¾@YvŠŠ»]¨Là¬Ní®£ Şº,>ƒŠ£€ùú€GÜº0ÎH{9RT2yÌşYFÖWRÚx;ïNÜ÷•4†õ^C+D;N/7ï%Pj½ïT_	‰íqí[_¾ğ’´[-Q]ÏcÖêE‚±cU‚PÙ—å(˜%ì¥ªPÇBRšÎ%£ƒ²@{’Õ3Ón‰Š'š4‡©GÑ8gH¯ŞÙ&0–ÆcCƒôÃe£ï¨‹NcÑ¨[ûùâq¥½èà 81mÿx"ÅætÌW(S+¯Ú44ğúd\NóX"† €¥2VĞòÉGµTĞTìÇ•è†JùÖ5´Ó$õÌxnRB€{—5aÓ;äµ'ĞÚ{r,ß­=^µÈ% Íy@`©êx÷©ªÀ'–Û3V5(ó©íBÜF¬-&hÖr¸_İEJu'3E^Ä´E×lÙ—[˜ËüU]:ó‡ˆrÖ Ãº#ÆŞ¬ÃT¦øî—+„mxr’E¬L†EÖC&P:Fî€ˆÃ|;×ªGØF@I«‰bÖë-4)ƒ¢-idjA4–yN`ägÈxÎTiUî±»ÛR“EQ–<°Je@\kÑ4MÌŠ¾x1E¾­ŒÛ(2¸B2AZì°°ÁSXÒ°¡)ƒÈç2'®ù1èêÒ2aÔ²ÑŠ©u—×çĞ·Çª‹ÂÚ¨|Õ‘¹“¥½ÎÑîÖìV¨’i(Mš[!8Œê¢¤)Œu~¹"ÌšŸÅMYÿPD$ò"í	Úµñ‘6:È/ÈƒƒY»¢„Û)´/a. 3zàz<¼æ3ÁÒÀ^ƒYé½ÓIbkV*k1ÕTæğÛ5•â”õNTÙôYuQş\$ş^\­ú¤B®ôÍÛnâÃu÷D›I#í:>ºpj¬æéÆ+1ª
ü6jPÎÛÇa¡|û·†XÕ”ÉU•Èew› ıˆqß$‹¿Ì±Ê"ºÃÍ?\‰
Jf•İÁÃs«DF¯dËÎµšÅ¹·ºëÜ¾R 24gˆ*/ÿ­j„ºŠ§x€N‡ıº×+†BÃ¾	¤Gú•.GróKÀºLœeüêZ±q½‹!ã—óÚ-|‰G®…wÀªJÅV,’:Ë3 ´J½í8¥B@é	Ü†‘zÌ5J[…ùJÎuàÜRG@ApC;ÉH°e¨V”YØ»yæ‘³ÉzKñxocäZ7Ù%§<Rq3‚€L)şkz¬úÚM3²_uØyfå±²µ+·Dº§O¿LŸ»p²mo›Õ€â0BÙö‡R±>şå¥H‰Î-¹QLÎ@´ò^ø ’î÷¬ñø©Í5i“I¹!cÄñ/?ÑwÛgò‘¶%íX’“í›—,¹ãEdÌ¨bîK…—°`×m‹¼NYòÂõú9*ø)şïC†¶[û˜á¯.şäİœr¨-ÜK˜»ÛÚx %SYé[Ì-d#÷—.ã&]¦‘nÚú ¸››fVø·Q‘mÌX"À].W ( 0<tò±´b¤¶„ÒÇt|W–eÙEgØı_á}÷Âçîı‘›c¡Ø(¡_Šac+KÆAÏô£McÅBQ?W*b³N?oûycY­P2_Ê®ş! ¡Cˆ¿9¯G\ş7÷7l]ÔÙœjwe	øc99úA8ıîÎßš>ìAQj¬}ŸDK=–ÔJ<36~&HƒBüO¢%kbRé~/İJÓlÀ¹/
­ãMrO] Ÿ?º×”ÂmxMçÚb]œ÷Tø"Àëá„’ìŠ³½‹f¾ø¶şu™»~´0u!é‡×jÆ7Õ†~á˜†5¢kí,è~ÅZ%òbfŞ#u0¤Ù'cß8´3ä—sã>Y|È^wëÆ¬.Ò¿j{ªà`&ê§‹¨æAòE¥˜í¨ÎÕ9n)€tæIá»éØ÷ª…§gFÇÊ°^3NP`>°Sg @jACÏZÂ6«È–ôU-y¦şvªê2acï	Ã(ç“%gÉúÚÚ¯1ÙNaW¢Ï¨ŞT§å¤Ái´!9_}­è+¹Œ:ŒÆşÆ®¥¨ÌAø@è~~¦%‘˜¼šDªÊL;êjr]ã¾¾u
¦ÊSİâp=¨à!ª©®Yo”Pbà£_§mKrÕÃ#8á)§Ê¶Õ )yl·KNÒQ¼ w¾²3_Ôj ôÔ#}[’¦Œ“ÁÆÊğéa‚š	(z(xR6¯2MÉæĞ|(æ´2FGàtY´LXk'wl¥9¬ÕŞü;7^çéDÃ@qÔHuÎıĞuÉËÀ{í‰8]8WÿÉS‹ìÄxÍ$7®f/‡S¨ûspW&~['5¾fAÑ±®È ?crÈDùÇŠ¢@äT oßW­;±äI5BH4’€øV¦Æ<ĞMÎç!’ K—áíÙIyîƒn‡r~ÜJ\AÂ¼>ĞÈQ£ïe Á·ËK)#9¼pä‚	ª@ù”ÍsÏÏs=¢h|j-Ï³ÍËbt°1ñ›°qÛ¿„«0W§ƒ<	Hä,ñ½ÄÛné/„hO:×ÅÙˆ 5$?>Ok*²p>ĞÃ«óÊd¥Ô-h‘so¨h´Ó?êJéR%3nP7Up|øÓ­ÔóÓgC§d¯Í’£¡,ÿ4õÉãØîsüzõÊÄG”±ü;Œ
ÖÖ–N•BR‹3ş¿JiF4O´í;R´ÙN—î—¤`l8ZdûığE…áô0¹¶ªÃ×¡LŸ,ãŒ€r<(d~å‰ûÙ,Õn€¨?©)¨7uÙšx<–Oty†d%ëé
ˆÓBŸr§ŞŸá8¦ûF]¤kb¼ˆĞæ‘vä,!¦vRE%…£ì¢rÏóUÛñW=qfhåİÈ‹ŞçŞŸIÒÀ
_¿&
x“$¬ådí–ÖOÈ|¨Y"+ódKÅÃS¦ÜGí&.›¨g’R«íA‚®Ã™”àë;–¢HiTÈ›HTß‚°íK;xúÓ8‡Òy„¶7q]r)oåSöG¥é?û´mIò	Vßb´®¨æö6çÉi¸çJĞçÒ4i–ú¶ŞML<T™0Ú%æhÊØÑå†ÇÑÑ‚ÊX3Şô°ÛDİæ.u_»›î”<ŒÏ`2ººÃewBû¿pnŠê.Õ¼`¡€Î¦YMw>‡Ãi=‡&O¦¼æ_V¬ülİ«ˆ™Oß»µI«T¼ÌJƒ’sÁóÊ¸°Î	ÔYnPÛ·“ÿİƒrÎŞ°+ ·Ufº›ıÙİ¬I&Ñèé6ÛËdCÍŸ‰!²1’S·J3†ÙĞ—RÌ”ƒ…Ó_yŠÅ`8ÄÉÉ¥†üßùĞÛœ‰!%ò–×P6”öêÙEŸ!ùB2w}â@#mÏšõIóşmKGl™üÈEPÚ?®Ä¯O	Ÿ\ŞœNû'¦$©=¹O*Î¸á~x©[‚iÅÊ›‡t(»²Ï”ç††GIáü£üşÛoœ¤·¨ÊjEÛk–¼=D?Ê¹àúI¯©9â+ş\:´	®õ]ÊÂ,ğù+€µM‰àm•s¯4µeVT¡P*d,,‹v£ú_šæf_ñ_Ù•¦0üädµ,ìáÿÅ™ã·8è*ÿÿ¢Ñ
Í=|i‰k{\îo5É©nfJ¸äG×Eo‚P]ˆüU2 0®²Ã&!ÿg×ú¾~@ ±3ußi\~û©¯,:•¸eØ3nª:A›÷Ñ¸Z¸·ÅM˜Ÿ¶U¢zy *ë=•„ı;¼¿NÕå`Èékc»bâ)jd®à0q{AÎj÷Dç&·HP\“¿¾	ûô«°pØ€n5¨W]	İ>mö‰±JwÁò$ªmŒ{gËRyÍHfQ9Óúª
^PÑ³'ñªÃ@_
´6±Ö¯œ‘M]³í´Ô~§¼Sf1„çªÜã¼jõı„4TõÅ×ójéî51)MqÓ?ÁÙ2Ie ²Xíñ':¯¢¿Ø1BeE5+em”3›°oÆ
Ù§LÄàçaº
_3‚¦DD§É&Jˆ8¼»Ñ…ƒ‹ÇWÍ
›n)CÊ«Ãf½†¹Şåa|õ{óQˆpz*ĞÌéş˜&¬Øƒ'ü	§ÌËhìAoô3¢|Z™cê]öó·OnÚDiò*ß}aªË÷­„aõMHØ	®£²‚¯BÔü¸¤é!¶Cãj)IÜhæJ6X÷Å÷®ËVä2£•+Kû‹Ø } QFd†ÌşË¡TÛw("p°ĞqJ—˜06D­
²Ôay°ú›X'-,ÙG–,ˆ÷ 7jŸ"9‹Ãø¤M(Ñz{k{mÅŒÁ2 ?%ã†lÃ2Æ|åéê€¢ésÍ—S‘šjKÆ+4$&,²Ö™y_1›š,åùµ<oñ>Å…¹ù×0©ş|æ'àbvYLÊ+3jş¶S‰ ¦ÿP“h“õt7{'Ú-:AÀ(§ü“IÂ±À]¥s¯+*şêíƒ ökı½1Ø˜Ó6Ÿ·YÃSX{_|dcİâ•=!¶ë„4oU@Î}uË0’A¹œóè’DÒç´BŒ£´uÇ„•=?cÑ˜JQù0”|Yóæ(ªÁãYgªZÜtmCï\O—´É©r=§n™¼ ÒÇ8‰®E	|³C‘°.ĞßDĞlcÔ:Á¾Ø’fˆRÈ£©7E>B‹k/p`Òêa[ß×¢¢ 8–2â` $ñ}m;^:ù&¶9zÙ £"¹õı˜Z(µ§×p²ÏkTò
Ø*÷Eüç±Û%²W+¦Py
Ã#ƒ§¦ËDÍFÕ:ú>?5×U…W †ØDj*.ÈòÂí+áWS–L¹!k ƒjˆFQe›å2ÆCeI?mqhÇc¯àó—›şc)­¥³U¢W5mí»Í^\-óãqşOºˆƒÖF¦G©8ÿ‰‘GQ»kÄB÷ˆBS6âplÃçf6àÛ)•¯*–äû[`óÜš!¼9èWÜ¡BÉ6Ÿ¶Ã+3šèØ*}1-mù‘9tè¦ûÙ»=¹“Ü
·
î-ÊnH^7Ûˆ7tšĞ	@óHGÓ}Èîº%ìŞ#ğÿ/ÆENÅèhüî£‹Ù¥ºğ-0|×ı¬™PoU9sßTÄø÷ü:“P1É¡H· §ÚóA2Ä43kßª®8ˆÀ5g¸övQØÒ¥Ğg‘ñ¿qtéÊ?|*óLù Vöxµ¦E¼\8‘¿´]]ØòŞ£GW³{PØPÀº3AfÃĞ¦Ûnã¯šyú3G,z=”Ê„Ğz«Ü2µÅ?Â¢%sÆg+ğR&1LÒº®SŒ
ÚÖo…}ICÉDÂ€ïşeA ÖŞıÂ¤UeÕx,“g &Ëºó`'ª•$àª`P'{F1y<¶4‘Œ'ğÁÿ4»,t&YÊ}"Ü²k0×·66<Fä{Sr8ùÂæRmbiàr€Jå:[µVŸùƒA¾cí°U*Õ#/ä‚vXoşç:©•~>Gİê=CÂ«if9-`thÑáœ¤„6#–²|¶¨noÎjw?oµ.–ˆÄd¥Ñô4sÜØ¿{j)p«v•ôÀì—¦é…3kÈ–›O/ÜQÄsgÅ÷AŠır)$J˜×ØK/¦R	ykrªmÅv}V	3%Iæ¿Ëº<ŞW<.Wú­‚+Ï§'nlğO#š¬ŒôB~¿l”÷©İ¼cÎ(ÄF‘Ÿù¢·D¾ ­t‚ÊæVz%8é3|>1$3\)%ù®µ«®Jû8^[Ù­‚O_»iÃ<?nÏµ‡o¡šÔqğŞUÅÏ+&[ÁÍ°|Êû“Ó`S1 Æ`HÌL·›±á îâÅ—óÜùï4éæ§„ïŠ ³«:Jœo>'”ã9·stGŒà_®±,Æ‘UÇâ!õõY+œHzvÓâ0È#L’æo¼ô|± åDG>4e[l¦·.tô^·l Ó7.Pª‘"Ñq«aºr„Mù"‡dß&ıx%±‰µñà^d·ø:ó¡¬—üîa¬€ddfu&´±1Å2d™
³ƒ²1ôd©›¼-ù¯­áÌËNc˜®4[ÍÓÊÕïáù»ÃŠo`EöUÄ=•zÃ9¥fƒU…À4û¼÷¤8y,ÖZ@*j¦…¤2}ìä½–l¨Û;¦¤Z7·$jÌÙÖ½gãşO[˜¤lt–}ShëÜ4jV`v"Šbaà‘÷©Õ ACih«üÙ>ë’›O+õMkƒY$“Ä	°&6²1	Lª>d…]¸ Y!÷ñQYL7Wyù…1cP—ƒ'·Y	Y|½qÒñ#o5÷”­üßç„Š4¡M	`ñîç
õ¾{ÕISÎ£ëÊtŠTÛ¢€Ñ£´øÖÿôúÌò|Ü ¹~rú›œ³Ø¥TàT!Ô™X\}uX Xç_=‰dƒˆkäéÉÓ½2Â>“WX ¾´¢Õş!×êXK»„Àjn`OæØ°ı™–Kğ6ïñ³wnC\á5Í¯>'há ­–#Úó½Æ‚»u¨ø‹ÜZíQ7Oñ$S(iÏZbÑ’ıŞk~ãæ5HU‰‚–y¬qµï¹ ¬Õmá¯gÎ…ÅÍ“¡	"xÁ#.²UQë¬ÒŒRöÓ¡‰»Mq›ğË]pCûş‡¯|AÕ½É@a	û=âfAÛÜ;	M>†z¸w€'½@¦Êµwê«®v¬³\ 	)º,ª92013Fù”¿Bñêq¥ç†i4 Åğ7ßB>&‹Š($nîXN…Ü J‘™D¨#~^t)
"»À€rMÓuÿèş.î@/*û­ª×;”BìÄdL±‘İl¶aDï¬˜:dûf7*@ª·ZoµË³¡S²óë™;Ñ“‚­óf|Ã'oP3ïzØbá> eãû@
@D	Ğ;ƒş@—êkŒ±…«\"G?Ì—êæ<
[O…^[§ã„á¸Lvãî‚iƒ•è¼ÛèÎ†ğ¡½¯@ÚŒ=…^¹’ËµÉHUcEŞõj‚¢ò¡O'o]íÚ	Oªî™m#MıR«Y
 zq‹[\Åò·ƒˆW¥9næ(0¼zZ“R;0æÚÊ$¢#§ÑıR:øšù€„0¢Îö´dN¯/>k{CßìUû2G×·µEK`ó£	A
x]G/cşkzøäÔ˜¨òX&Ë)ÕµÎÚÛ³Å®V'ÔdèY'˜œÛb*yIm)K¦„÷xJ%¡ş';<ÜIÇÓ½ __â‰yÉTaÁêP"=•!ß-‡HÅì¯E¯Ûˆ€JË¶DØFÃÅõ\¬/‚"T Ê0$q0º‡ÀÙâ:IHYß®)|	Vß˜Ü3+mc!Ç6 è>«')l|Ë_»Õ¬,Å5¦tJn»õDïÎ>Db`×ĞÕOÜ]¶%ÿGòîˆµÈÛÇmHUà¥Uîyyï‹t§gñÓŠùã—Ğ™Õˆ˜ëækÅb55ª8Û»aH:A(i[tÄÌeà¼°\w¿õÑŒ$ëëzıù5ˆ»5«Ÿ=ÀÒ"½äîr!:'Û®Nô4I˜‰LIW)Ã]Æy mãü’‘:ÜÑïw¡[…öÇûôÎù¿x®£oƒ[_ ´}İ•:%åŒ2óÔüÂ~µ˜ª‡8'·cqøxé6mvFÈaqÓ¼OFCãüaşt|ä†ğÈRçûY¼§‚B¯msµøÓeñaŸ¼EğBãsneF5&LÙ7qúq]ı=å—Öc£ßp%R:©Ÿ(½68EB³Ëµ=scŠ&˜Ô.AœæiCfqÌLúTC˜p	º2ê	4obúRUpíXRäúPJîß	FA™x[HA×’¾)X—”±Õx0ƒ0n¡a•Kº%öo«AõkÄş?¨œŒ‡VşA+©A¨DuçMm¼*Í‡ˆVÉ¡ÍÓ%è´¸4‰\aB¡Á‹…‹ñÉ İ›©êzŞ	=®v™š|¢}ÑàM ¼§å82xqc<ü.#™„p±†“‚´…u+,ş
ã{	Fí¸&ş´Rm—º¼R="é&0Nh	å˜FØÚãœBi–¤äj|=½–á$#±dı¨ÿ@Š_v•ÛÏò4²@Š£qPÀòÅ%pPâÁe¹>]q4Û†({ğ˜<²¸NdòŸşÖhaˆñ½±YĞ“ z‹\ÿ»¿è)V…4eKê £b7V0õ ˜íYæYÿ¡ì§ıá±¦jŒ ´8¾ı1
Æ$€à¾×¦ÔÈ#…±áƒ´AFa²Rà¸i_é·ea&µä4«;Â\[Ï‚b>Ù£iê5J‰‡9¶rÆ\’3õ¿Ä¸]jíê?_”‡TäÖ~â¶¥;·‘m—„Q:÷„±gp¥nˆuµş­úf(/¶çòéJğÛéà%²Ÿiî0ŒÊ	Šˆ›WfJ{jª#ÒøZG¨€J"p­?Úæò/-0ã]MÕDvçç.şy2ƒwA¾öfÙç%µH"oõißsıER6ÒEÊ¢tpGNB{Öƒµ ÎfíS3K
ï²Ä2ù½Ã«·.½İlóÑG€Ö"¯4»%kø<â¢±Õô:8uol
8Åˆ"$_jş+>6 AsşN£#O„/‡²¯´uXr=1{Ä]ÉJtÄÛswà­2U”¯ê¶FZ|2[®ÍœM¡ã¸&Â#aW$ºételÔñ{ÉÔÿ9}õD™âIåj²	ŒæçßXûXbÍÚ÷¥Z<ªÈìù™h£×¢1ğ¾•Ø¢>'Ø€PîTø+İ`.á;§/c ¨q0œß¯ó_‹Ñ®éoQïáBËÊÔÇ½Ö„óÂ68ybÿEÕ–òÕ?’Œ‰›r“-pY$~S<ßO»©€èCA‡¯P	Dâ~\¬Šâ™`#îróoi?,
i#Ö°°vXë™±Áåtb—­vŠãPê!Ş<ºãÅ¶½2¯XÚŞi36Øğ;q@³Ï«•Wv ¥„Ñ8[¤m¡oçéÓñÍ6U¾~XœV¬ZÙ<³SW2.`/M›ÃÍ†æ/SDİ»¥ò}¾Ûğ«y	àn¹ë@%úJx¾f©Éºvøƒ»Cq’õI¶¿ó+Óâñx¨BãèfäØû[…Lñˆ{Ã®õ=‰%¹îaìL·Öö˜]ó¼/³\GÎë© @0¤âqùLéY–‡>ÂÙ.‚¯qD¤g")3jœ¡2’ m v@”8¢Íw‚9Á_\JQ¶B÷fmËÀ@„(‹»B68! ç©ÏõßÙC1”íSŒÂ–X ğˆ†[.­Ú]ôûxğ«¾…ê~L!ğÆ<3¸l“òGšŞ+;Soƒ™ü0v	èPĞU‹ªÒ¢«ÇÆ·Ÿ×ò8x€ğ~Ê£¤ bÎ‚£@¡š€Ğ?¸ÍTl76\N5ríÕ)aa;;Óö´
Ÿ!ÚeçÓYfdÚ+#úşã€cG ¯ép„así /¾4©ÙÀ»êÔe<ĞvLŒ8çpk|Ğ6IòºÀ
%ı­uB¿b.Eué  ‹9¢—¼û»9ºwjú	†°WéŒP?¥ŸÃ
é˜6…m3Râš‘_4Y¼Xy°áìyÛÑg]	ùTP–VFüŸr(Î¶§<¶Ñ3_X}Ag*½è#t*ÛÏ5}º´Q¿OA¶ª¤¯~ Z²fg’ËCÅ¾0!uß¿Ôæ7ÊŸ|şâÇu—*x‚@›Ğ©PìN‰Î2tÂÒè*d0IeEZ-î¡›ty­xíºeˆUÂNÇ?–&$4…b7ûõ‘w-›¸6C)(D¾”;W&­Q¼ígß0uW¹eCã»÷«\  ¸’.½s‘™ù¦¯L‘Ï>ÉşS}õ©S=1"¿ûäp„ wFğ<<u?5’¯¨tï—D.Üªİ^{7.=üSÖ›		¡;¯o8Ow`@™´ÖÍ£—ÓV0n°ÿƒĞzöFÂüyª n
÷óù-ÕW¥Ô·T¨~È¨’“,º?~ifşY°ög"ÁÈÚ2‡+¿c|„j\º D3ş/Ô¾£5¦1´–/ÑGF×W³fO¼Á8¶Ÿrm¥v…É#Œä×6âÏ•UšIª©q¢êqíçjØ6'î5#–o§¦Õ”{?€¾è×7 õ: Š¨·–c'<Póş¸5ªZÔAciƒ™ómn±õÎ@3İ»WloL?tQìU¾ÌúFD+´¢|RÙ5vÓÿM¡YÆ1êÎl¬z?‚VˆaTé³Ïİì2ZÀïô(Û›c`f½¶¡”ãw,wî¨0ÏÑ„×Q˜Ÿ¹ĞÈs0ù˜¾ğæC—Kk¯­Ğ2ŸP•·C~S=u“£kÚ-vOMVçØ¦2TpZXL :TE«^{)vô×Ÿl2ñÊ8°aÜëO'ÉÒñ¹õ½€Êğrˆ€Æû6"n´™><zM­¸9ĞÄ
tWhvlıIXG
¨Jj:,Àƒ±¬ğô07`Ü:™Ç_É\(çŸ9ÃŸ‹ÂæáÄ‡Û¿jµ§bØô~ı:é;1Ó}­lZL9â’•m.d§7K†+y(áLÀò(8™¦è˜[ÎíÏ¸×3»·XU^Xş‰šºÕ“xy<(,†¿9K±@hÇ…´©×© ¯µ®U¿>ÑfşŒ…Ç­oúè†î^¢Ê/ıËÀ0ïõ“Û<xÍîNÂ¾’ğ~£˜©µ”‡:dôÃ#
Å.¤Y`kµØL®ªÀ]>"5ØFææyş½m(†½»Xìr˜F#z‡í!BéŠ­m?3@ÈBJ¾@È.6(ó]5’ÜøyRé|~¬–8Ú¹82|
qûU†E­¶6è²Q„fé2fu³öı0ŞëZ ²³Ùß¸ºÅ.ÄC_Ä8ÑXí|–rÖ<0ŸBÆ†øÙ%+Ä4’§©«!½]µ5¹‰dTì'^Ìrƒ¼bÂÓu¿˜Æ Q»$òSˆ¡pX2Z#­"¾WÛª¸¸¾bû¡\e¡!ªhriİGOd0'ó¾ùnê˜¹12¼‘¼tv¡à.D¼ïÅœó¤Rçîcã¬\ƒDÁ5Ê–Ş­¿çÙÙˆ½çD•[’¦¦~.Nu˜}˜^û“j‚ïÕ«ĞÓ®&¡çı°£Es•”£#’©¾“`-ÏJÛÏ%)ğ+‹bJ3g7ÓÛ}T®b›º’ËŸøç½B¼ã!ARÑIÁI‡ûœÜD(0s&¼XR·•øR‡6–â·ºªU%Sl¤c½î³ú}A4„ğÖ™Ü ¬îÊÉTÓQ9×ä$}9sÀS^4†­Õô~–TÈ;ãët'Àã¨ÂmJUÒÿş8¼U$~¿€`Ÿ=¯“,jÄÓŒYh-3U¶˜«£öù¶XVÇjóÓ IÓ¸„Î-m®÷VôÈ@…î±¿(Ş^>”n8&UÔÿ˜
âçF(ê[—ç9æR:S‚²0€ı:ìnœQç‚½rÈ«Åúú’1ÉêÕM*ã:ëãÑç>{·ÜvpñÈhÊö*tqÑÎ İãÉI³MÕ¡Ú­¹KóH--Ó„í„FTºì¿şcQL×îèpşy¥š°,\šædó×zëºóWà‘Û,ZìYİl˜«åc0‘,€Í»ŠìÒÉw¢vmQ™H¡&;“7¯#äÚlç×€EÅò3ºÌè¼A&Ãn_¾áÚ{)«*jÒËŒ		2kãœæq¶s22Àò½Â¦N]Y7ã6°2É=ÚjêraD`U¾Ç¤RæK©3~Òš™½ÑÕ<ÌÀNkL…@/ì'ÖèØËôˆS@1—C•p*ÉCk’òöĞâûY¸û4¡-dd'}nœE’çÌá¦R<ôpÒh/À·öyc§¥Frò=Òí ÂTÙ5íl`P™µµãu¹äz¡Â%0Ğa+Ç´r¾?‡½LÍ†Òi•Û¶—a–AÄª·óõÆ8õ(7ÿ@¥J§òäcğÛÇJO?Ğ†ºWht>w¤/-FTÈ0¶Ş'ƒ.Ù\]QtT,Uâ[ôr‘ÇZ„óÆtÈ×D:šˆõA¬¨
K×÷œÏR*aĞí‹Ca£"VdÎn/ŠŸí5ÎÒÜ^ıéÔVßİğÃ›eÅ ÙjLêQ¢8
Êó‡Yr ·W%Ä\§D|tĞ^²]·'¤ùâŸĞoÔùæ¢•IğMÄ`:"ìX¥ÎB#ËÊ9xK‰9Uí‡V§¨Ii‰A²ÓŒ$$Ï^mH¾FoaAD<‚“:øpşÑ¢]ûó‰š>:)4”?VŠ’µ/¹,{Îßšæìl’x7ıMËå–Ù|¿­ÄcGæ
Ç|ë†JFè®=‚º†x–
uX$T6ät=ÛÄs`;{q=óC:$™‹KŞšCbì¯Ï	+ÃÅ‡P9~ÏzÇ¨Û0ü½Ù4Tü^qnßÚ·¤
âÊˆ»Ş=äml¯‘2ÑA7ıÕœÁaTû†¢Ì¹+2ê;½êYe v<b=¬ô¬û‚w*VMÔKF'šÕï–4K€1bçï+³r«EİR»íu£úÙäN@— Â¯ò)6¤@‚;£÷óüÏ`{½İaK.ÈéÅM¢&BÙüÃ3Üqıt_ İlİ^åèiäÜİæ'Q	õÔì¦œ‹k°-M‚Í‡/	®5Á•Hì o±P×T­q#ó	lËoö	ô7–·d)•²{zğ:MU€îb ¬{8Ú2¾¹yqJkI:±Ÿb>a“BåüiŠıdbÀ…Ä|i<$NaŸùü²ª:øyÚÌcäÅ²'ƒ+t6pÁ\´¢’:=4ÅLVï§¸ÍÄRû6Ø†±–©¸œ—4	¹å}üª5ÁX_aÜÅYßG²÷zBL>µhlì–^KáqÏn°ZwƒøH²Ÿ˜@PdBm¶Ö´ØqÍÆQÜ³Úüào°ŞÚw?ª	øï°!BÿCóñ6¬ÿp8ÂÖîwè¨‡´Hq:‹\‹EÚDÿ@Ìú&Ì_¥µ=¢7ª¸y»É÷ˆ­‡¡zš¸9¥•ßô
%í„#Â·/MówoıÑ#»k+¨rM˜¾­aûïdĞ‚ÂÚù["mA¸‰r3ÍÓ‡Jú#–à ËyÓ~¢–ƒh€»a‘Ò•s:ÔÒFÕDÄI¢é™&åíÆ•IhHoÀØdEš!Mz9@&)ÿ<…‹ŸTêC2:§'so¥sß1àühLŞçÜiÿşT"j@Ñ©iSµù©Pañ Fë0_«Ñƒº	_Öz‰k,—œ,Åqj˜ÛA‡ä3<&&ÍÅ}ÆÃÅÆsoÊóÕb´Ì\<ôB#jç²ÿØ×`QL§..ÿÙêL
";E1Nªa~ò¢ñòNØ}8µ6³ŞG-yú
â[¸*ŠËæ_ùµ6qä{8gª“ë6)Ü@¸êì£»è–örB¸²Am÷’å/4ŒÉ·X¬›‰>ğZ2ÄŠ*Â´£`è¨¨DŒ €ê·BåÁß¸ÒíÔì¥x¤7åşŠÛ÷¶è..ËMatÎåÙ7(6—âçÇ^“	™?7Í•P‰Fûûšwe
Óäªú±Æ1ˆ¡¨Èğãìok©Tx«s§Iy™Ëó8«Û‘"©Ë#O ôöËÂG^E,”G³i‚ĞèmHFöÁ±	H`è;”›Nç%’5ø,Koò¿f>‰ß[h:ø¼ˆEV\ëº/pu3Uú4ËEá¤|Ö„kTÓoU\ÇcÓkA”…ûññº¿LfâR}}U?€å„T|g:¤)!‡Kev1CryÉ’Â¼ş¸‘ÆÈ–§å ,ÒÊï{gÏ(V!\ÿ
¼±ı´¡·Ù²6ÏÉÜÍ®õn¿ïì3ûÜon…Íµ¸Ëõ%ÙNµÂ//Š=¹Æz…ã:	mõqÛÿÛ!¢[!%g*úÅÀÒ—Û°…¹HP?Ö–Ä¤­hT8.ÌÕ›BQ¦/Ø"9%ÖLCÕ ‘€póa+wË5¦å&,ŒX¤(š%ÇÈ‹¿æo²¸MöS»ŠÆuJ€mxæüó+C	å°áù1mÀ&ûê¿ºã;†2ôAúVEÿö)é#-åZ/Ù¾á¸RÛR>#Æ§<RZ`?€ İ…A˜Dè¿I[<"›Í|A§sL³÷˜‡e™X
_Â,w¤JñÁOJí$*Ær`ëñSF––×Hc¬—³›@›‡¢²4§kj"øÃ@øe¯!TbÕºc7]ob¢óRO‰)G›’ô·	“«ÎÄóú?ğ³%TvĞ	@w¬Ä¬Gj£dVq0Z¡C<~V&³²§[M‡ñşĞ„=«ãRœè	ü[+È•‘ÎtÒƒioK’:#¦?Š´=’´êÿ`‡)¹/oãŸº€z¾
É¬´Ñ—T£ïp¬è{/¹}ÀÅ-ødÔ7…œZË]… ê2ª›éíQ„½ã¾„u_Û·NµŸ.l!2¦¨²®ƒ;UÃ°ª¿E+ı)Nêxli	c2p¿Îo>™Ö‰u.æ¯ÙéIëşÁ4Îxûw…ò\é›ø–™Õ9•6C™}D ğ+Ñ¬JÖs‚ãÏ,:”À¤HÖ¢[B–ËB?×#m«[SGb	Ä>5rN´cØ¨}fv<Ş‚£x™ö8å•¨=¼Ğ‚š”ù=Ä\ş^.(Ú ÷å¯/ÚèD¬&6'LKÌ^CO]ƒĞ’&n$©\)‰Ï!·Øÿ¤K+ÂÑ0ø%­_ÙFİ±FË'ºrô¿*t„¶Je–^Ú†$~øı…›“ˆ+À+SbLEİ×,c%¬Wü»™nŞ£F=°ŒAk~Ô•¾äËTTRkØyÇÄ7ôğ±†¶©•kf€A¹ğs`x>ª‡0mÚ¥wÒµ®«´÷ô²qævãeSÓ“utŠŸ0ÕÈ­3díšĞæÚ{LºjÄ°oª§íZh¥Y2ÓExÜ¬\ò}‘KCxÚ–¿SZP =„µëz˜rK©E;‹Ûb‘‚¾¡¥Ù…,ÅèUÒŠ*OÖ®°¬§ÉDç†ÊlpÓo™çø:ß S$f@Qd“0­,Ú8Š `,_ dìçf‘¶	™Æ>÷Û'L!ì­®/{J»÷˜˜Á<ğ±ıİê<*oøV¶
aDò,æŠ¶)dW:du¡ïò‰ÛÙã¹&Å¬ew‘‹LG}ª&2Å‹zå¢Ù2e~Äû áæ#ÍÙo%n#èüƒpt­èÖ–9ù{±åN2îU¢BR¯RÅ¯(RÓSVN€üÕBïZB‚Î9ìˆ&»›£ğv*¶…0Ò‚ì¡äÌM1^à¶Mz5ì„¡ú½~Æä²¡éÇŒÊó§í¸—Uë\‰çïÉ%Ä„~õ®{G¿Ï¿õñ,ü¯nŸå£f.¼«00×ıÜ=Sö÷µjïL\¦5FÄ9‚l1ŸçÎšSÚ.ÊCj¢uò‹ÍÜAì¸šZ—÷ö>C× ÄN Ÿjø+´SØ&[^ç8àf f}Elô%x¦2Dš¡”?RPÇ£ÈàXO+è2Ò1ÜÅ!Ÿ<±âFj¾8îµ?ŸÜ÷hÄhÆ©bˆö¾£#zbJÓ,ûj8úÖÏ* Ë+]lC³ÊÏµ¶ŸeXá‰—	TÈû¼å™ü_k['Á|JÈb}±a,ŸÙ©%ã@~2&şk›¡±{”†{ÖJûqÁØÉ(¦W3â Œ¬9É—©C–Ñº×E´ì¶¾}üù«~¾Ÿ|hÈq½™ÑKI¯M˜Óç%q6gEušlMÙ$+²Yeõoq¼&^X_u/’)¤ÚO7¬Vß÷â@æğTèÂõ1…¥–è—[q  Ÿ\JN®ãVŸ‡<½$¹A®­J¶T˜¿[g®UWæT~|k˜U™kå:úğÖÀÄƒ0Û%Z.’½Æ8+zĞæÜ+ÜëUe£ƒ"O³È!­zP9:®˜jsbÄO	è5û£ÏÒ]ldÃZÙŞsşëœşğ¶‘,€ˆÌ^ıæ¶ q!ß{s‰£Ñ_!€ üŸrXRø,‹Àäÿv–6]
Eöò¿Öd2oŸz!Ûç#’Ğ÷ä5D&¢
ia^ËÀ]¼¨™ĞI³b»gÛO1Ìe.VÕs­/xÆ ÌúÒ7%§fXÆ(.)‚/.ÛëÓ¿Ó«½µA¾hœgı×O-MÉŞ¡ÿP:ªÍM dmXkò"ìÿvCsë¡«õl±d÷ Ü?,å‡º1:Ï4İAÖoÄj…¥Ç5ÏpÌÑÖ¬¹óîöVpë ŸÓ	îE^>B?alÚv2	Ñ¿W­hŒ½2Lê¾`›VF¡Ş)–1væÈPw«»)]‡>;‚Oh^ À^;ê¢l d¦Üáo@ö,Ê·Òi8hWŸsHé»ßÙ/ä‹DL ‘ñmA.iÌ©ixÅ>Õ1‘†ÿ2[ScMQüi†Œ+Åäæ…€È"&ˆDŒ4¡ú¨F‚pG
ŠÓz )·İü<£cFâ˜u*.Á©¿[Œ™böAã9ÇµİPi\ìé©Ğwâ~õ‘¤LµVeûjhÄ
ÇëÙœp#,éİRîÿeV% '%k!£‰oó}6 ÍÕébZéq¶8EïÁKYQ$Kf+Ê› ËÛQa¡›dÁß˜Èï?”Pšc¦lh±ØÓ•*8¾‹ˆI”şèPL.[jûï dhF=;êÉ‡£	xšGfÙ7yÇ(æ¦Ï¶å9àu3xNANôÍ€”ıM!Ğ±Á–¶á{§+9ƒ'‘…€©4¦şÄ¬;9¦'CDWHÁâBwe,×ÏŸ¥ùœëZI—ÕjÀº‰ÈL±pb]˜®½_sr)BÕfKÂ,!x|&©¢™¶mr˜Ö³~ü™Djè¬^.Ş“F¿À}û”Ü€#~¢È¤U¬‡RW¹í]{¯ı´í6~ñQ¥}…~¶©g“SÕ\¢òv1;³káäbXYH±ÄK-]K¡µ$]ø2›±Ã=b9œïOkõb2U¤ºM=Ê(dT°Ó$¦<ÊöS
gb×M—ÿóÂµ‡Qù¼ğ4>|’w<"³{ó!K"¹qòB”LNÀiQŸ»Hl+ëôÓ`è‡û „ƒÎ ¡V÷Ÿ}ŞXö]ß =êK¼ØæŒñØX9k£x(ó{´ šõ*‹\3±º¯vûnÛC¹¤×d&Ò‡ıésölëó+(bSøA³&:İ*òµpñZÁæœí¶µÏ¦ºı*fhÓ„…Ò¸8³cñ}Œaõ[¡BÎÂñfòã×ÖrV€ó>8ö8ç˜‹C†|Ağ\~ßMC‚ƒ"÷KÏã3’ª”(ØzdqEİÙ§¢ÏÈîS3°™]ªAÏÓèõ¨aUO"ÛáóµİÆ…y¸háD)In_º#pe\M…¶Ñ7PÄ ÁÃdefè _Ã% &¦)õ»éD¦cä?é[õ#Z­Hpš•¥²ã5ı9NŠ)@Ø­üğÌ;Q<FëŸœL’%‹·¤ÿ!›gÿ×ÊUuÑğ,sõÖ#xšcL¢·l@ÑVó#—qÍ‘MÑ]
rnx¯W¸á1`ñ²—”3İûK™Š»öşW§Ïã;Œ	çÍQøñ9„F™fñÌU†3ŠÒ"BI&lÓ:óo½0Ø`ŸsönWO»O~ ¬¾Œ‹£(fÅ©DÖæ~Ã2ä@µ *W}óKTÑ0À­kØtèV{#‘],ˆ¼ğå5B±˜w°…š[B?ì^ğFsšü´Ër‰é9ImŠÌj88OÌ‹ÉÄm:ÿªŠ¼Ùú"ç`}¦•wd*6E÷Ã&ØAÛØ•Í[9ëf¹ÔjÓ8–áÅ¶æ2˜è“@›gA3]ƒ=±~)|­ÑNĞ~’R\X3ˆÔDÜ&Õ+´}í³ï¢Ë¢“¸+&QA‚{Ë¹7òœ•òÓ™ÿC¾İÂÒurêÎÚà¿ªÂcÁ>+\¹_í¹wyî-÷ï
Ù¶8Á?Uh35‚©#qİqQS¥ÛÂ)¯R^ÉÜ±ğ2â¹í%rmxuµt‚›ëy‘’8Ô®›üUeö¥+ˆ—µfT"èGòé1â:é)hıŞ¶	‡1y }Xu”¤¥Ùê Löú H½/F/Äd|VŸ.*wëTÈØOvBeR™DÀl#ºJ±n0Ï&Qº1P.ÓåUˆ#!â•lCyÓØ÷(”^í\ô'ÂW¨jçøZ.¾?›b9rUb[›Hœ°›‹H|:€q'Ø;!…×#¸Ÿ¦0ƒj´äÈ{ÈSşW/ùŠ’)¡xú‹°|Hµy:®İõ³™wÅá¢U>°§ÙÁ|ËîÙµï„Rò¦-è§e ±Èîp‚·ØâşÌ¿‰Ì~Ó Dq~TÊHO+MĞ¶ ¼Z«»}šbæİ.İ_ÏŞN1õä¦¿²Yoµ©4ü’„`Ä‘ÎÛ¢Wïã´» ì™×ñ?&‰È¨Î^ÖG‹Pè½].ğLw–/¦@³™=†²p¦œ¾g—qbrİ¤ÌÅd7ğÉ§§‰/í+õÃØMğÂÓğãïŒ'(Úäª…è9Á¥¸ÜÀ´%êÓÆ OóµqÒöCma\è²âÂÛÙn‘ŒµyaÔ®"’vV	a%÷Y1`®P,ë,$ØØì÷£ïø7wãœÆ¥±Y–S¡¡s>N­ÊÛLAU#LÓÜ×ÕJ$şH•øqóõÍ§-²* Â¡Ø»çÕwdác³!F¸LŠèñ¸Šx”;;â¢ó­éñ9>Ä¸ÄM>¯æ gèc‰s•¶w|Õ8 5Šì¢SàïúíC)Ç4¢uŸüIÔ+†ÏE¨×QÇQ¹d…º"·%gş˜u3‘ŠCÙ`rz +¦\
ŞĞdà7ğñäí™.¨ÓÚ>”E&Şèo.ìD¾èpJ*-µÂÒ¥V_¡u5M«ÊØ°=£ÇHH>È‰C²(ºPç˜ÊV¿¢%P‚/ CÊÉÚ•6ÁïOQ~œ¶şcˆ>~’~$¢A¢=.ä»9¶~OPá-9¸YÈ,È¸6`b¼+¬’m[tg»²ˆlDÉœ]Y„SåÃò:ÛÑG ¤Èı9L,şiâç[EÉ‰sÆÍH¤4û
ıE    1³‹ê|‡ô Ò°€ğ€Y2(±Ägû    YZ