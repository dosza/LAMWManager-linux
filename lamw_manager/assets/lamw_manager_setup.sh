#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="824552912"
MD5="aa10b3ff7c5a9c4ed98bdda2c6e61efe"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22824"
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
	echo Date of packaging: Sun Jul 25 15:57:26 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿXæ] ¼}•À1Dd]‡Á›PætİFâÉ:€ø#ˆß©&Ã[HÃÿ{¯Eğ‰ Iÿğ‹TZ)Ã©Ä£	ßÀeÈM<ºA,}áß+Ÿ!”Ì¯¯Ş©Ÿ<¨]dÂ³Dì½Ék€sô44 XJq²)*ƒJ–|í'¨`ŒÎê›!‹äè.1ßqZˆw.ZÀ5ˆ‡Ùš*[0±OÉ¡w>eFß4ÿ;!ê¬” @Ì¼Ñ&H564áEø¢ß> Ğ-!Awİyp„Y¨<× ¼›|/$bNÇ£,¥ì‘9q1‡ 0|¥À¤fL×y¯dcÔMA–ä{É±jk9Å“÷hûğó†¼Û“²L©\yV°ãV¥ÓûŠDMÖz*™Z5Ñ €àÈvš\ú+¾3R[Äï­b-u®Ì­O\·›b¿Ê­¶û
…s“ZLŞÜ¬$'NT\ìƒn2ÃærÈ´ÉŞ·û/ò_¶QÅƒ±¥Áun´aÍ~õŒD>ÖVXF¼_›œñô<Ãô=BšbcwÅÃ¯,n±'ôzeĞ<`J:HQíÇ†®à~9˜9£$”e‰ğ}¾.g;	¸#¤™Y}8£¼„3Lj<£ø˜gÂ,–mµö]0G›şÿ`íµR±óH]êfC5š fp
‹ĞñÉ€{¿Ík´¦£’…›`©?½X1:‘x åt··6˜ØŠvwõúS¥„&†XF?şÄ‚Ù”:ÛègT77óIH³–K_â¾çiş«wÔú9ÅW‰Ÿø‡_”UxÆQSQ:Û©ìÅĞsy¨¢#Ã‰ii([ÖEˆ‰ Ÿ#‚,­Iå¯'ÓyU™6€ÓT:¦ø+üü¢–•è®&ÜÖğ¥xÎ>—V´J4YõÂªB}Ç)IØQ (™Ê!.mš¢nO;W-.µĞr“¤p“ïÛ¼…‹Ú¾;™/ÜŞèi—o°r:¾&¾Æ¹l³½˜¤Re`ƒ¨Séé|–¤1ãpbQ}š›™+fVi3 ¼tS§„œ”)äXh¾úµQ’uT¶I"8ù]”?Z'£Z”´Êê¾Ã<­€dÈLtiøòìe£GWØNwı\Ûğ!h4\7dr­¢C>X‡dK>ÑZõ rœéy•¢KÆ+º¶œ¯µ#¬~“ãPãÎjö«…äİ‡J<‘hÛgWå…	mTâËtqÚ9?ıË´µLíwÄ*ôÛĞğÙ
I½å³=Ã"÷*±Âz¥N7ıç{º%‡N±mòRPIZDT8HpU¢°à‚çÎ*f»’¢S)Ñ‘úŒ1Än6íeÕ-EK9"#¤¤ƒßöâeç©Ò&>¸.’
÷”ù¼tFég½ø0§ÁÂ©øcv,†´ZƒS²û¢fÜ¬8K–ÅO]«Í|Ğùï:í´U„®8™>k\ßıeK+è!3wì–…B£t4„Åè³Êä¾ÛE©×í·šÄêQV d
&»ÎVö‰èğüN®ú|ö1?§oæˆRt½•›W7N¤»È™—©I{ÌÄù¦VLèÇ[Öë†m6|«¨dåD@ŠÙaºµ`êÓäZNßS0ƒ^¹İÆ)ŸÅ“èÀ¹´›Yîû­xFtş×­KR›fĞùnVÅ ğé›\æLMÛ>Kı4>7E9¡r	éÜ¸87F©(éÂŒtùK5šµ†D`^4,ßÔS-Îğ@ÚéÚï)v·”3|Bzª¹›h5OG™ªìyjĞ
±É»ë¸t¼“ªæ¬ÄíŸ;qş±:¶ë9¾üÔ~ú£}èÙš«dß–öùğËß!tmy˜µCmäwcHF$nN§0ÆoI‘Ìß+ãŸIuÅ%¤"åQñÃY€ÑG!"ñ‚\È†$VRÏ@—ÈÎ0½¦*¦…–m-zl7û«µf]Às¤÷dÆGÁÿ]r;lV~°&Åuïxë=%ø_ÙE.8#I÷¾©|TOº_PÜ‰Æ.×“o•a4#å“oü«!ß*Û-ßõNI\`4öJ(Ê…2ÔVv(ud•š+¸Äª²¯j–â/nóìÃOÁoşêıLPğæï‘mN‘ÍXOŸÇo0uSo|]M^ôò•œm0¿-ÓXÚÇÅãsKí¾{µ·ˆYàˆX	J{e§TNXFd\¥k§ËôwC#“'*´çèCı­yH"2Éşş&¯VæeK10r+-DéZ&§‘šÛßÉ{.‚§½hËkA½Õ½¼jI|ùñíãÀw¤ê3®„”íiO.ZãºÍxÇè|˜Ø®²Òş»·u`˜‡éö`›|à]¸u´Mÿ˜óR¼&0WétEÉU²]/ÂW3ZôµŞ˜¯4ĞğÇÇmk=19,§LüD‡/okiï§NÛØ[8ö “_·«o  ú†cş}Ì5	*5‹5ÄC”øCo¹ï©xrìŒÜë>IjßìŒ_hS ç+ĞG'Kgò2Æ0O;x4î¶'Nú|•vxºFqñn³+
Ì„‡ŸïÄÓ5Ï…Wx$šù–¥A	H1 &ÊAÍ^,:¹…TZSàY„.Úò–{|¾ë™¹(Ù+¿m¿ŞÚ`pbc)&¾W¹4Ã“M‰±V†K¼	Péú¤‘0Ÿ×şX4Ó2ÅB8ğã9„—×ñ íVÃÊ©¹f;‰ó¸±üØàw–ñ+ûS™ çÌ6ZêH`•i„gÓ\%™Óãò/ëÀ˜7Ø
âóAáÍ—r¸k78"æhSµaHıY;yçMÔò±±¿0›üìÜ{Û
/×¢spÔd´z¨<äöÓ½iïN]$øeÜ	n‚ÃJšB¤‹ä§±Rh+V5…TÌPËT-íD‚AƒJœıâßbş^©šc8‹O<Uéşwœ‘\Ïô¯~e0iïÉ~}ğDP˜ıÙûIYê¬b£ßïZ†€(€£îæ	ÒÃ¼Dc±ÉÁ,-a
«™£ÊĞxWëÙß¼”Ã¸Ò/ß}r°mrQ;‚à°¡^.Y¥=ğ®‚GJgê‚4i(¢(ÌËy
©ÁÑ#÷Pr˜ßR*üvÍNäzG©E	.¼ZXà%+‘¼#;í½îd¿üÕ
ııŸú%ÏñD¶Å:òÌ1ı÷=½79Í¾ÍüdæÔ/ÃuA¨Io|äåı!O(ÀA´šjyPÈ•ÅŠuıtWÍÕ»Öd”¬ï­Å‰Ø¡'ûLHYûN¢‡Èn[*h“Ma#ô1¤‰x†yR¿JX*úâÔõ{q½é²ŞC|gëÈ8qWõ'Pl\:Ù°—ÚÛ{'†@ÉË»÷(Wå§¥z¸Â†ä¤À.V×67#«É¥¨»ô­³·Š¼‡÷¼‘å`×Ìó
n•>¹ìÂşò±äÓ.ÉYK5±<è/d*ªƒniç–…‹ø/ç›®ÉK¥h^Š½Gîï,…Å˜&F^mƒ!¥ªñlÃ»Kax¾ÀÀ~	×8Kåë(Ñps›8Áw2Z»RV»wÕC7\kG4+Oş¡a‹Šû2q	öæ‚÷:‘çÏ” ·ü)ög“tcdLúhQ.ºÆâPOHLŞLÄå-†6'Ê0ÍWt‹5›¡
úö:ÓØ©¤g[QÜ˜VÉ'*9«'KÎüÔÿó›<¾×°ï|&öqªÄ>Wã»¬êìsRd‰&
Æşñ.é3qÊ>úöä­6@Gµš‡g¡ºÏl†—ÑìbÍo2>Yå²9ŒuŒ›¦G
s»­J«·Lœ‘ùñ šõ?pË¿ãµ`Uù’âa£:•ÒSW	®'¸Å;ê—›uGDm²5 ìÎòÉ(á*­µ¤
éÂ.£–ŒhÉ5=Š™-àù3×ó<)İğ³Ñ©ŠÌóƒ‰sNõYfP_JòE´„h~’ zK_ñq›¤íOŒ‰g]Ğïûİø¨‹8°YÂD‚÷Ö×]~o±+?ƒ“Šµcmx'ğ£• ©	ÖÀ%ë#ST¶Ù½6"¿ÔJø4afPO‚p½KŒæCä³JøÍ>Æ{Ì(¢”DÍZ‹i\İW‹°øˆ KâÛ=Èé6¬T)ïàãŞß‹âDƒ™S°3ÏƒÚ¤GOm_ë¾Å¥^µÓ ¢‘7¡Ç]uUC½Èà§@pa`Ó°€µK~ üPò V_C^‘–/(’§ŠŞme"Üá!ß¨z…¿$ö#DƒöÛchXò¼m™e© ïâK=üÕ‚5DÄ+7°«gYa_åh4sğ2ù¹‘]f"97)ZÚ·7îº¼Jš`*Š¤S^À4îĞ"cÓ©^ˆñãªÒ«Ğ–²jvF“j!+P¬n¦V£ĞãD)¬±Czk^Èœ½ã¥¸Ğ?ËÍ[§RøÖW´Y‚ –ılƒ³@œb3ÙI…ëÉÂ¶Ø NÛ‘ïzÖZÃ •”?€|wÖâ“{Mí¢*~[I¯^‰/“º@Ş‹Ao¬ïP3E;Ó¿óV¾B”Ì£?ùğÇzÎd1i1ù1z±ä%òÍˆ'%? 7Œ­ñ«³c¨•‹’K«f¶Ó·™IÊŒ”“E(!…pÂQFõØ—QŸ’~¼Ş¸¡äŞh]¢"«SŠšj¨v_çÂ¬i¢ñ®Ø²Ô€ûÂ\×üV #»5sº°DÓÏhôR™Ö“†)·úa|e–ŠP¿«ÃûueıíÌ?ü²×ÄÚ4`2v ëäu°d¦‰2$b^„B;2—¼\a½'ïĞí;0<³(ÒÉçqü½*á¾¦H§XªxZÄEĞ´§¿Z´ÔqˆXgâ+‡–ıâ§3½Å“7óZC_2¯Ÿ·‘Ì(´Îbv1ny{:K^fKsü"=ok\db©_@ˆoÉı°¨áƒ¶@Ä	_VŒƒŠîÄÂ‘û¹s¥mã§s‘˜ÙÉˆ|y²e€‰TŸ$ø½¾OñÄ÷pçÁF¬í§€C4Q	{ê¬©éÌ fêPx@3V”À¥Ä>‘5*'¤ç2q]ÊZg–r–qe§ĞœÈí…Œ¸ˆ–c-&×tŸR[q†ì6³€ğ +‰»)jˆ—‡¢E¢ÃÙÉF¦½ó%İríFO\»µ¤.˜g…Â*öÅ?"¤ŸÅJN«P3Ma'GD
|«g>$Ä Ø¿o`n–×µÀâüôÎJQîßV/äv#ĞnãŒÃ¿P•_¸K8`ºÜ–°şa1È©©fw§<İš­mRE¼"réÁ,‘úùR¸Õ<RÖÛ¾,+Ty)¦æieSˆh¬$ãÒÿ¸‡­AäEPüÆ±cä+6CIir 
gVò€¾_
zÎÂÎÚÚ±;Ôº°Lí=o°«“Í’ÓAêz—âNEĞñ°V-ÔÒAbğ¨U;$†K½ˆOm	Z?]ê²ËÊ ZJhb¿¯;eàï,Òy/z†·!Š÷€w÷æÒŒéUÅR*¨÷Ü7EÓkïÓù•[áRmˆŒHfT
çÅJuÄÅ5Ëu× ½°X¶‘EV.ëiöÓ«‘v[ÁB/ñúg«É¬İúöÂv¡ñáÊ*'}ç¢$›¸HJÕ-õØ ŠƒÙÁ—ëØªà»É‘†ÏêFC³º,]ê÷k:+ì½åÈğc-±K—ñó¤¯èJŒ—;4<e9i¿MøEü´šPvnÅƒt7f?­·	…µ²óP`íã3]CÒo/Oê
¢3'b÷!„½â™„XJ°HeÄä½!¯ekÇ?ûo:=-yAÄóf,Õ‡…†ÔÔÓÃM0¥î¿@§pš`Ála·?äûÛJIî8™ŠˆªTD¹U×ÊÄ¬Ê4/½mK3DÕĞÜ©wcàÕ¿ì­§,ªÂNoğ|ªğ¥İ’-ô>¹‘æPR`.Ìo!šğJ˜ÖìÒ4©Æ¾•qlQ	Œìıqì3§xï[µ:š|ÕØqµv?_zZë3¥y\%Ø‡L¤üÀÜ£“m›õig¼S0lIÃ×Ì Y7bVÈFü ƒ;¤í‹œTñ‰û}ë/ıéñç×H.œp,ö‚Û¨Df=7ål±„aÍ›»§Ûí—;B2/Ê†‘.Ëvõx£(âke|'±ï€^Õ€j=Gr{®R†ÅÇ$ğ
0LÌpEQ©è™®É\üë QáÉa^bÔ/÷±Æ¬¹»õ¯¶2f[·ëØ#P_Q°Õ Î”à‘_×údÆK­T&ãJ"§¿]Ïl#*O<s1ºÛÌró]¢´t>3x·õàD#ïïÙQš©†@ÈFr@Â=	y·:í,)üñL?Ùù›?”¹ÈÅ‰µWóX”„«{Ö,B§¯Ë·Tè-(.Ç¥áçX1İı2®©æ÷±ç²üi¼oÍ*ŠúU-¼ó\	Ñ^rİPÒâ&e©QÇt‘2fé%ñ¦êÆ ŒøÙ&¥ŸããeëCàı>¦í®şbªš±Ğ…ø¤3Êã+è|TÓSÁŞj>¨Ì©¬€ŞBÅd¯;²ˆÖŸ›ÏÎ¢Ûyñš	F­øÂ—©}Bom!eCÍPIİ…È2…EâûÕ‚Gë![]sÈÊêëx¤ŸB‰±µŞG)Ÿ`^Ë\„m:TËß8˜Ç•CÇ ›¯jt›m~1sYŒÿ†’j“>Ê$,Å¾jç-¤]yH²©.¢#ÅS.,‡Ëò»Q^`×v];7‹®)Ã‰³gmıä–1)…–dwÕDjMËßEßÄW¾”µ³µ‡Ü–³T¸Yè°q£İ^}¸´ç¦á”ê€5‹ziWfA°}ÀC÷”İ´‚ªmçöÃİ~ÄIÈ~ğÿg©—/ÄS½Á§p+¼…¡Ÿ•¢pàX©¾¼å“Ã»Éú¤;…Æ9+CëNßØÊ£¬ñ×XY«çÏÅ<V<¸º(V­LJUBFÕ;0¶¥tWÃg¥óî\“µë—×ğQ¿m_©-Ã¬:Ñ¯­gJ¸1^.Í»]Óù…kÿ¸|ß3˜œ:7ıìÅ\åé36éÊÓ‡Â8’C‘`)I{×GÍğ?`x£É ÷H‰M”¸„F":u‡GâÍôòKJçı¾	aƒ€ÈO>&Š£ $(}@ÛB¤R€4¶xõ¢““…ç^'W&÷ìİ1CìÑaç©®ûŞÉ~M,óÓ²vÁÁ£Á!ÊlˆŞ£Yıá%-mı£Ë/Õçñ£Œé¢¯›ƒÆ­ˆXºxğ!¨Fœ-ÉÒú‘i9 ëõŒáç 6ßc‡*§šIìì¢¿œ¢‚Ú¡øĞghïİâ¼(H‹³U	Ÿ‚Ãğ\{ÛälØ¸K³>g½ZñövêùŞÂDpß¬a/0»°Â„ã+Ş‚zÍµ—Qv^Goby5p´BÓSxøGS&ÛĞ7©ÂS˜¶Úñ#nà¬é(§eİü%üT¶úUP²oTg:ó©/Ú[é•âFè¢èØŒH¨æÉ‘¢MİhåÎeAYõVtŠÕô?y«ÔæjõÊ#SlúûšĞU†¾ gV^UËÇl “(–®xiÄ MôğâÙ¬½\¤ş™56ìÅû.5Úr#RØ­¾t»Îÿx/A C\é:Ç˜ˆpt†µÄX[Í„¬'QÁ”+È’—û®ye˜–†î
KgyQÄ0Èß4Eµ²–¡Rc1P}«±B’Â¼sf¦RÓRtcİjìdY8¾QºÕÜhV5™!€}áƒPÜõÊ{Üe&ÚÆüÖ»°åt\v‰‘5{Øá™Àİ±!1Ä&1…~Ag#“ÿ° Õ‚Œ˜EÉ/f(R/ø˜ƒ•6¿Ö–µÀq„lïGí‹üTôëØ,ÿ¼şZô}†i<9+e5-|3æãLPšTtğ]'zEğ½®[ñ)æ®În•#VÎÂ(d2hŞ§x´ˆ£´ûæ‚RÃW¯¾=ú‡jïÄ´¶<4‘%¯†Öı©Î°”4a«VäÄY›ÿIVÉàğˆ[a&rÕa^2w ×%.ÛÊ(r´à·È'ÂP6Î‡â¦FRøsú²_‡ãf9+puW’1ƒòâ¥£½dòÀ2Rkğõİıe²Î¹-‘:oòJËrÁ=’áN8®ÚvÒ*†\Ñ¦Ş^âíXÇ%“€KrQå;)®õ°)ª2ˆÕwnÊçİú:€ÿğuÄÛ6†6»™ÓÏVÀ¯K5ºu¹¹¬ª¢2`D ±â9§æ…H‘ßŠudç ©@(İ†E€35gUëô§ıX<ºn&ö-¥\n‰Fú:K¡â¹)5Ûáİ"ù‹a2€®±sL&‹n‰ÆÂ]íãw†EâSÅ‰°Ñ.Ã‚\ZöôÙõËÑîH=?²KÙõğìä©û-JğÂÖS¾xvZßË%k‘÷í/ªæJ”Ñ?8´‚ñıS«Ò›®Pj5Ñå’h,öåÆ·Î¸bCB¨^cÎƒÚŠA©cÈíI¾EÔ«Ôøëe®ÊO™„ù°	$"Z§J°ç½K] uw/VÌè¥Œá ¿aWXã¯ÈZ4¨[Ë2€ÌKépóÊ)@¨*H¢`::!şõüÁÏù'—mT[%ş.ŠİÎŒjÌ7€R¨5¡ÅxëİÊÙ>xñØ%c‚!ò’Z9š?ÛîQÌ.w#­Ë¨gA\Bğ™zT©Çö¡¿•u,+y¹ÉÅ\V÷y°mò€
³D
Êj¨?O’æô"³	táı˜8X°ª·?ƒËu-ã§.gËh¨ã"3D¢´è fHéOšƒÊø©¬À’ğå%ßz0}2ÀõÅO{ìäŒ&2í7æ»úGŒˆ 1/® ã€¹ãìY‹²²Ä‹= ?e›ƒ^ÖIÀ·Êïùà· <ú‘xmp1 9Å^Ö‡]Í±òİĞ¨ôã¨J¹Ù8vvÓà’Á¾Õ›äø äOesçAöÑG;ë÷éş‚ëöÜ×À¤<½–j2:¸wí‚¼ÕXû@I>úùÇÿ ú6é ˜Óª°è›N0wòœòÉoN³]*«Á_¸ÜÁ%åÆV§ççˆ‘ôüÿ.BÈ	‰ÚÅîWíãJiR‡†ÀÏNõ¦Ñ+ Od“ò6ƒ±ø€¯û-0@ö²x9ŠfnngvR‡Ü«Ç3Ş÷Ì`hvcÄ’Ş¿µ2æğ8ï­L—Û­]A..i÷¹SÀ‘£µñ4ËÃ¶UkÙÈ×Ëy×ìÙZ²b6ñpD‚¥6çDµÍù¨)KyÊ?§,35 Ê¿°ŞQ¿ qfU@úª$Ù$À<Ô<j¾¨Qo ŸÁ„k¯@¬œã!=%Çf¢¡Úäîšöû¸à”)²SĞ‚µ”†;1øYŠ÷pèÉW	¶]qˆĞ^Ê™ZÂïr€ğÉ…
!‰<×ÑG	Uæë„µ9 a‚SxîÔ•íCê_ƒŸ'„ü¬‰¸³†ÿÏ˜†‹¼8÷kZ!óë5…áÚ›\ºA¼Xüf‚Ci)çZg¦ÀÌŒüD‚mA^(<©5-j‡õÿÜ •5Ó.{’õ!òÃµòšƒÂ{'ø\•º¿¯SÆAŒNel»L[Z”6ûS“5¿”o'£-Ve£‹Ç»=¥}PAz0¿>e4Oéİ"èieÕ	ş0`‹Úº­6¹ }ø7WJÿàÎd¾¾ŒäZ0úÎÏ,¯ÂMšı}Ó[êtjı0EiÙ-áÿMËßíÜÙ ’ÜZ>È"ĞfVéW& _y‘±Õ\“¹3gÕ:Fyõº”8ú®5¨·¢5íyŸ*×¡‡-Ì Zğıê~(m Úåc^4xÕr…jólxú´jc+KWüÖ. §ÿ—iS#€¶îÔ“cÚ¯çRg2Ÿ(¾Ş@Ğğ e¸KfBçœ·\ôr!mbü´µs?b ¸XÊ8B­ª§x´¨cÔ*Şãÿ\“=œ0²Î‚sƒín£ià¢¿fÄmÿòQô,Âìo¼AYÈæL:ó~C=w«ğNnÑ©~Ş¦[3€/n§Fƒ³½T7Ußõ³1Xşbyf–£o‚@H‰¢HZ®éAGõM” .ğ22µğå÷œğS„>¦÷å+lóÜCNæ§Ì:o‹X2ƒ)¨‰'·6»qpTxZ‹*ñğ	óÛª¹á—¨*·%ëÉ&èa$İ×ÎL
=AK½M’^ËóŞAÆ*¹›l§y‰ü_T'6Ê¸…+š€fÜYE_ˆ}¤2†C³¤Å+çKÿ<Ø1]‹lwr—<åœÌGr4«©w˜õÔÎâñŒÎ­‹ÏÕÅ~a¬ëºß¬FŞş&ÌÖ„›:––'pG¯¬Õ°ıYq‡'£wÜşsV'§j7inÒ¨2mœ6èÇ‡ÉÂªF›Ï")-æq;Òí9{r§S7<À°¶'i\ÿJïéœ«€Û|Éc¸g;:‘[	4	zÀˆ•Üú¯Ëg
…”7ø%H1ÿ`–v;+)AÌ–xñ?z¸£4ÅòtdÓÒåU<ÔL2	*Ñ°È[i£~×â§>×2dA±\£òdªœ
Ì+I¿Œ0x”#Äƒ3¸†€DÓÒuâv'b)èí¯ Ä#å/Ä¦M¡ÈîøÔæ
RQ®lÊOD”$¾tk¾2ŸYºÙåœhÅ•q(ËÉÈB³T†~ö0¯¼M#ËiœŒéçnøL¨qk)¨+d<LÊ…š³|Â}:öĞÉÊ)‡]Yy²ÿ“jtÃ	”ÖY½$Îx¹±V'kB<D\ç¶ÄØè±a;—‡k£79‰¼]Õè=)Ûª®İÌÌ{#Ä´1ªìÈ»/X*ìåìq¿iÊ&fÚ!Ñt&èßœy½:ÿBìÉ",[=¸ä·X Hi¹—Ğ3]¼Pªx„…¥M:ß©ğtAQ”°ìKpÕ«ÂB!µdh¬†ëtëğ¢4‡´J´µoßcœŞ}§Ë•—Npıa½^tö†Z‘)—W+3áiK:Âû{:Ä¶‹X:0vO¨tÔí.í›?aApÚÎùè1ïõÊ.Šgƒ‹»4+§EŞì°«¢æ½1m(	IšQ*Z …âD¬Å#?5œrŞù¬ÉlÒ)²öŞ¢Š‘G8Vd™Ôë×¿%ìÉˆ•<‡jÌ&Íœ	˜ğMLGw¶İeğCèÂ…šJ…6Œa3·ÅìÊw.m>¼!mp‹2QûßfŸª;dºo>÷™ãF”AdÆò›ü}> •ÂŞˆ‘Ÿ;QLY;Ş{][¸çd¯ô9Ô {)Á¬İ>(å£C&_÷Ô?IÒ–§,ùK}ìŞ)?Û{Å—:Ò»Ô&¾šVlÜõC‰CÈÑ —=õX×
õ {€‰Ÿß÷óÇÇ@#ËT LóÈÃca¿Ì½Qq‹hÇv¦—ijËso4ıVZíU ‰ÃĞı•µïN‰¸G>†-P‘ZÍØ“<êš6\Leâì&qúà?*“¸=‘º-ÚUà{ºıÆ)j°Âµ\2Û Ç É¿î›V ³¬ƒn[ƒ«•s¤äô"3<A«³êÀÒíkIß¸¬(Ø‡ßPBµH¹`•}/AÓ4Óì**ºÈ¢¥œ–P¾;§ßğ\²ÎKlÒ±Ñ›ïGÃÒ§ŠßD–CšŠùÚcÇ7ë¦OJ{ìªş©!sÏ.Üºç;’¬™ó”€ŸF—"‘µî?©€Vw[^Ğ„ ƒ×1n–á‡®Jß~Ï{X¿•ÀÛ—:`ÌXCN$ºTŞ>Ş¨Ê®şñë‘’séÀ8<ˆ¯jÕdÃwaÒõ7 ³l‰Í‘,´>ÆÈ¸%";ÕRúï²g:ŸG­zn6nn\«Vğ€—oú&õäo{[™È Ó’ÈhÊ«ş·â®Ğ³ææêN–½jf¦zy«Àêá‰íîzià;H	†¶˜#ØÜÁ&Ç_Ÿ/ù	t|K`à!œ¸EÁ,â™Ï	RÙˆŞ<T YYÚsè¾iÚ¼+1"+Ëc[0!–Új³âæÌ50‡n-Æ#Ë´£Š¢—+Ã–<#)+1·Pş]@Ä0o'kcÒ×‚â‰ÓÌ”y§`´ÿTËşbŞ/¹4Æiß–SÒ‘’»í^aXÚ%ÔLkŠ¨¾ö±›ä¢ƒ°û¯îñ¢Rr­¬jY³nÅUQ~éŞ¬ÉòB«NaBàk³HÔV7­8QÌl—1»¡2Q!`€¦Vİæ2«JePÆt²Z¨”S‘Gå‡`Î•Â+J‹ñª”+neÄ?)çH¯µ_5SŸ6ZÙs“qıïÔù&Šñğ¡°¯^ŒãúùHêX“$&HD¢§ÄôÕ˜E.åëYQõcÊ\ì Œ kíIœ´p³bJ.\¿<è6ZÒ'ÿºHG&ÔµMÈŠËîh·ÖÉÑ­’Æ5'|Ú¥Dû0âãÊ„ˆ~!((+¬Ğ¼%%j(šs‚<Ø´YG¹ëv3èUrdHL4Ğá*ö R…XƒüŠF‘}Èv‰–•DÇÂé¢sè]ñZsÖŠ…
#ı0&­"ÛêÀ¬rL29µùQ.<%ıÍòc¢¹7>;_MÎ§•e›»bMùy½û“j}Ì
P@Õ•¦e¿ğë8èrUmÒg~ewá|dv@ZğŠ‹ì3‡ys]•Ä{
?ª‰TĞ|ÿıâ·ÚÌÖœùQ5dÊF0Ÿ#{8|YÊo´Å%Ù+­»ÔëÌ=ìhí]y`ÁŸ^´44Ígšìzîèmekş_Q—Î]$Ÿix¹@qúlï÷8¯M²HĞ
Kc½à7ÇJÇğÚş®Ù=C¨+hL»¾ğFğV¡I^V\"Ëµ9¥/•Ì²L‘dÍBYàYŒÂB±5›a¾1OŠ®ÎBàŒPib’Ï¾•94Wg¢"Ó68ûí¸\`ÌàÛøåAutl„Hc+ã‡vıĞå±Gº^:öÃ­CXLãÅy%åÓ¤Zs'¬ºp:øv»@Í¿Å·3(áï¤ıKvÏ8‘jâèåigçë¾„q/y‰Àh$Üº)ßn+nPc2Ÿ5Ä†]änã´‘x™}ÆÔVh{ÖôF²ZZ%©­ ™Æ¨wØÂRí#Oñlv¢ÔYQ¡Q¦±8OŸ€ÃŒ!‚:<F Ù.´P	Íb}Z³Kò7ì%}uW4vRExaÎİËOÀ¯‰>¶dÕyúáh's5.^Ú÷`û¨­³/;²¤(„ªpmqEN§Õ‡ÓŒ¥J»_Ó„°MOW§¯'Ù[Ÿ< ¹ë<Œ†s=_Ù0ÅBÍÿ>OOÆNnó@x›˜Ñ"L‹0F}4Y£Zü±…­ı:ËÈ/<±óhaÒ³]M7¬†mGò$ÒïúØe
‹óOÆûÉc#Ji8KJ²RRë˜áĞ—Úì|	p<Øƒ-!v²
‘Ê®¹;°eR‘ü†@[~Ş†B{D$´ú*jÖø7I›¡íÀÀÑBEóäñµš“²õ4ê|u+Õ5·Ó¥™ã<Lée…ë?àŠ]â¤oÔlIwojï#‰3Œâ|ø¨$v˜1İ3 €7.c––*Ìõ2ş*°Ÿj-‹@‰<ùæóÙ±*Èƒ@YbŠ:ûİ!ÕŠï ğ)^5‘6Î›1BÙúş½«6ğ[¢Î%Lw›h;+ŠfxGßš=iº’W¦7‘íy†ÿ1 Ty…e“Ô~“—NåÊQ<¹CEüøÊ=}Õ‡;¼İ7Š7aBÖ[¤2ĞL0%hı¸‰|¼EÄ2z@€nØ'W\)hVbW€İ…óä33mæãì 1—Uúez–VÈ ®Öj)õ
P¿ØÚnRåN¸4ñ Sá“ ğy9;ù¾ …a	]™®³o˜JrÂ¸±l}ZËòS=œîN7Ô•§ÏR£ŞÛ|½sÏîÔúŸÒ°ı˜–|f˜%TËÄê¥~ùÜòšÌ3Ägùf¥ºÀxªf‘Ë-xã)â‘ô»½c”ÕX{móc”ë
¶Îê]Z:
Aï™¿Bµ¥‚–3¿EÊ™IVõÆ%Ö~ıå¸ªe{A“ÿ­ê´ågˆõ/:î ‚ÁÚ’•Ô(§âQ|Û%+×/@ËQô£îZxÚ©¨!Š-óö #fÄ@GJkI †µ‡móÊÈG=Š=.~Íoö>²Ÿåñ„`e`»Sõ®¯Â€Õ£/"Ä<.…u¸§ğá÷®¿2ógµ¤QpÏ›™²âô-ˆî?‚Æ×4KƒŸé¯ãÌü·–Ø$š *õÇ?Pñ-Õ¡àñ¯¯1:oX=êÛÅSÌ †-Ú™ÉMör+’ªI•Vªc#¿úŒ@2@sŞZ,;/vlïÃ+ğìôªNŞÚxY­fS+ki~á™ÖU{(q>Iôæ¶8O_öÙß3˜Gx‚ŞXŞP%eN@ş™=Š­ß&H"ÈwZ¸~ë*•0=À?ôâ2#Ø-iñ´ÿ|ÜJë0Yß««ÇMì©j˜™æj¤.Æ³ıˆ?ƒš§”2ÅT&OÆÖ,¼PÊ¦­ù¥	ê›EfGE×ºì¢Ì\,é{*pá.!½ \¡$ÙÎxğ½:âHÌjl‹WõQõğ-¸ğ®Ê5†¡m¨®İ	4sCvğì.ŞïÆ¯9o9­Şhñ«±-°m1Y²ªE¼3Ü5…8¤¤wHl¼°è±·$Ÿáìğ”‘úàÅ?–„ÏŠØ™^i.`RÎ>´Ş“Õ ´ñàè÷ºâ¨ïS¸÷KPøŒ(¹LœİB‘|ÛÎîïK,”È¨©Xú¸1ˆîAàîä_1A.ê-_ãÁ›ë]™¾*Ãw§bøeJcÒâ[£ïû=ß¹%Û»d)´z72ß™ı!Ò‚'B½Êm“ ²hGpÏÕDıË‹¬Væé¤Ò„æN,$82oÅ¨è=o>úVwÈïÌí†ë;
Óş€èW-ğdÖMCòC
ŸûGqú€-èd2»wF>²ÆÙÄ_‰öãaîhã ¼×9åÊó­ô	¼j	#*Óou!y0•KD2.ÇsŒ1¡¾Ï#×¢2iş±(%ÔÀÑ&.8VZ¤ñ]¹­‘ße# .ÖƒFí.àÚûí
y¹É–W“º¶$?€XĞÙŠ+cu¯Éà´xN¬ıÖc` ØøÁå@sAÄï©IgÛ»{f¥ç¢ç"O(róÂYŸ,väC‚=OwÁ_¶ÿé; $Ô5ïúû·£5´İøÜğ“D²¥vc~±Ş4[çÕasgÖù6OéÔÊgÛèm–o/»ƒ:ŠôË˜«¡Å>„˜İ¨³}¡§ùÃ›¸W5_Úå°¹+k$W
Kˆ*9”qW>‚5¾|k¨–Æğ©å¦DS2[wä¡² wÍƒ‡Ğp8 ÏG¡êîOiIRë‘ıš-Øg¬²”ğy|W´ŠQø’7{V•›jeeÖ…J%u©öq]pƒ†ü@dpÍ¹qÇ;ù©q´‘æü‡]T ¡+e|j™üŒÄÉéèDT–¦êtÈÈƒ"‘x#ÍúñIŠkªXöÈ!±)RöÚ{À\¿kc{0óG¨u]|Ô
‹;U:mmw²»™fü8=ÍÚ9¡Ùdf+hA#9ø’9*‰mµÊ]Ü½¼‘m\´PUj¢vÉ‚âŞH‚Î©ªë¡ûK/1?aQ5%a*BïÏ<[Â¥`™0¼ûúÃ>O˜šqLıÌ0|9‰ÉGÏäŠˆßkÑÄ ›²o±ãa–Ñœ±¹?–_FÆÄ”Y5XË
(¿Ebî\¡ êòËŸ>[VÜïæLã-®š›ğ—©÷l<–RşEFÃ»çĞó«2,Œ‘P6l@÷@¯+Ç9_àÅ@	x
³?GŠ+	9şyM6—cFrôWë&ùµÿjv½úm*(¬¸˜A‚ŒKËâõìXhöÌ35™5^ßf,¸“NwS$.Úi4rq¹¾¯`ôE„±”5[j­O§(ìXA —«-c¬QC‡Ÿì)d 9ò®Jó>¥¦¼›]:yD‚¢a<yÂ†Õ“^f¨Ådˆ-8Uğkëz6¶	‡IVYHÇø$D%`’«“Hà»”ït%ı0©(]¾0¡ „¾«]=«”sémı\Ã¹ù~:*Şläæ¿æªG¦cÄWó0}ßü/‘§y8C@¡hˆú¹­sUGKÖı/`lKZŠÏM’PQB»&X”Ì¨<T¢/MÁ¾ñG‹&,p:fI$è=ŞÊ¡îœ1°e!&ğÎS(H!õˆgòdÈV]Y´làØŞŞÙJÈqêcŒ\Í:ÏŞ\{¼¬&Ïı¸j*	õõ…5SıêÅ‡oáWl„Ùe¬“æ‹à="Ø¬ÛMõ	·q´/gİ BuRŸ”k!Ú©)@2®'Éæ_7)ıº7©kŠF!_IiÕ%‹,’£Q†cº(ÇòÈ$h}Ø…—{âJƒhåŞ¢ÜVä"Õ'Ë<šƒÍ±/	1D7O¯Êâe_V™âx•àô^…øzèpü{Şö²­'&ÿGfÒ×cDOüFNH"Ó!,¹‚Rb8,VhUÉvÉÑƒaŞnl$Aÿ×‰NìÏè[ÄM°éÕæù¾ñEÖı4ÈT‹h:>¸Rñ†ŒØé.ë5¾ï„¡L
‡‚ª'Y¯ÅÁS—tÙôiEx™æá–Yù¤„9o´cb*)vAÌ:ö“QÔ¥I¡xÙ3CŠÚO=%àç†ùÜÊS¦E0:'&I,Jµ8ÈfMî4š¾’ÜÒNÿ(GëDÜ$¦dú¤—‚†Én¯Bò|ÎšLˆÑcgokÈåûú)¥¾	¿“4ŒñÊQÁW5…ıéŠQ+ÛŸNùü¿qx:ô0êuzØ…’¤¡õ‡	ú•plËV$è1²‚á2Y÷eÖv“pşŒ±ÓJ†ÆZoÔ+õÀ’….šºkITéÆg¼_FGü# Ûg â7h¿îqÛ;ì3×\’!ü‘ß%Wòã©¬èÄX$Î¦¦!ğmöê‘Ê€Ş$´\Ò¡EÈÃrğİ¦l»\¿ô o`™å¯{Ï;=ôÎÖw—ú–!Èoœ‹BáçFÆïyŠ3kRÉ°Ã[«`¸ò±×0ÜĞ/Lâ`7u2Y0»0ö*i2Ø* õ’×ÑšÜ1TÏÍ9õÉ=ˆc,ÿQ„şf¸‡š‚ÒÊ´—sø _QòóX°Ş£šm¥pÍiì±úñ,ª>Í¶EyŸÃdpğ­ßyüh‰|ş$O¨Ïé†µMi|0h~ÛĞÎ-˜X\ÈHõé—9x±L¥‚-‡Õ=,›ıM-²^ê¶÷OÕ\”ËÈÅU½øh©ËÄúë?«nfôÍÓÀk¤T'fTR¡‰f”úÉÿ‹ É@j¿£g8õ)_Ø¡-tÊy5¶ã;KüËç‹˜‡;ğ“YrqOéòs»ˆ²ı†åµ¿Ê6ï€O5½0¡³å%5|W@°­!şª™ûÁøkí6±ğXò&óö2lÊm½~¥áñ¤ê^2æˆŒ·Öw'B^ #ëõ#.¥–‡]R¿y‘d©BË¥ÀrÅÄ=¿;}ÒÑŒß5¬8ï#Î¦WÓ‰âGu«Öv“•W¾áXô9ùÙ7Xáˆ“ãL2o)±¦f*õ>z(µbdÊ‘¦„ù.NîPx€Y~G¤ãsTˆ'ĞŠU!g2µëÄºVÔ6‘9by”“–Q´z…h­Qö€ˆÿfÎÜÜ\ÚıØSÄwBR(.ZnÍ–$	I‰“óUÄl&8ĞgàrÀË”›õGã‰ì©ÚãÑ$­Õ3$PŠ0Ç¤ñkùmL•I‡ŞP%ÅKx¨á­\âEèÚğ
#GºPV„–½4Ò?©^jßÚÿ¶ªßB¾5£6öƒÔ¾îÏ'œ"eÏ"68ûPn€*Gtfšt_Sá¿‰G=iå˜3’a;,}À sçê-ğ]Ğõßà@$D½h*Ş4Ñˆ[ˆ<#à,ƒMº¤VÛ Ğ÷ed‡µç2R)>sD[yöhk°ÀÏºyüxX(y‚‰÷±¹)‰®Èş›µÄĞ7À«lxÍÛf“ÅèÉœ«ÀMgÍasYŞjñjfƒı"(i½¾ıäLto?0	üu¸ŞøXÆásG½Ş&ãŠ†›¾êÖº¨ÍÂæ$è/®áÕ!W§"]\U›-WYõ•¶¥«{æ¹µD"Nr¤y2Âa4¶šÇÏ‚Qü­7‹íª<'ûL™JùgÙ@l‘¤Ô.ÕÑØ[_Ã?;°ûµ1,Ab¼şõFØSÄõ_ŸHå9öÁˆ$F@.®ÃÊ9àâkjC6¿Bƒ6²û_E¥sz¼~Pä‹å¹N÷Ï½·ÆµEï»^A¾¬ô,½õşàLÅåèª&“£átÂeÁ}o“p
 JeÒ°¶Ø¼>T;K[” ´›J¹é*ZÜD@ÉXrb]º¡Š£Ó½eL®qoìS
›Î·ÀûÀi¬Îêi×5¦ñÆâ¼ĞÁGú_ƒÀA|æ=È0Çõ[ğ¾[_¾|‰•ƒœë¯0ì&
·Òµ-iç§ŸEg¹¿×½¬ÃöT‘ëºÔ¶Ç5ñ‡f/u+	âïTT/»÷··úíã¦r© _ğX[ê—iş‰ìW$Tµ=uWÄ<?ÜéÇxÆ}Ş9=íe Ã›ı
,Ìî¯[û¹J•ê¥!¤ª-ü·Fb§~ÜÏ!àn«µE–ÉoxäªÔ—°`Ç#¬ÉQşº1*Ù4‘?dşéİ¬{ò÷å£‹ÃPj´Ïv[á¢h¯M‰ó½¿f°áLYÛ™WˆÉK¦÷«+‹Â„êÒÚu²M
“îÁ„›ß@$É†ù[]cI	 ³Jö2C4‹ËEpëØø£¥×Û©)îIô´eÍ?¹ßéÅ³Ïç¸}(P}Ÿ1r½÷÷ôÛ>ºÅd+È¸†i;PEÃ²\µ]ÏDÉé»ğÌ‚µ¦FXq&ROÄGåÔí…¨_¬‹Í£A/ñ²w R¹+ÿ\ v»VºRõJ27Óœ°o)G—ÓÅÚœÇ^Ó†V`?ÚÄ7š2½ÓÖ{ û{ì’BÉXw¸nqe^ëF]óÕÇ»«Û9ÑÈ˜¢¨=Ã&èğXõÚëò5¸œ›:ÉOßdg8I@¯õ*suÑÄ/I½¨T1¤ƒ0hÅ¿4_7„£r¤·ü+ªºí	¥X©2^s-¥H–¯%ñNÃ'8IMoÊ›³¶Qıï„™gËßƒ¿„Ê—*·v´Æµ2Úú›;|‹€òåB5ÃOòycæq¤¤ªğfŠF!Õ¦‘I8Á\q·§&ÉüÄÀ¨Q£î¯@ …³Õæ¸@6[¤r(s`Rù6¦Kµ›^0üÅVÖÏënğäüŒëÔ÷PU—êïë(ˆò;zúH¨åDÜè‡Gk¹×<N²†©nâ ZÙVdË2Z‹šY¤,uÿ£(kwK¿#¢q(÷( ®Ğ™,âÉµ-cLp¾l­Pµ}ˆë
ôó²Of´p²õCñĞæ˜#5’„î<Wi¬ˆĞ[uª‚#W¾(ñõ/@=şÑÑ¯Qmó~lqÿñKï¶Ğ—pxVÊ÷².Ò¸›¢EÜŸÎ¾ˆ|•Jj¤`ªó"<*šÔÓO–÷õ‡bV×-–y—&•Ñ•N¯©x“LĞ+.?€Kó]‰¡ÄUÀ|Æ6)m5ÆÌ‰mV$‚†>Ai3J&¡0à!;ßø¤úÑ­!•WÉë§°òb@qè4B‘î=õŞ~nä<øé¶]‘˜û¡”9–¿çY­…ì°œD[ÒÀqP;)&EÛTØe”º­:²•Ã‘ùv…©€ú¦£_ş×('¨àş9)ñ©F„¸GW·x7[kµlkPl{+6£fÏ]DÊ`^[s%:$%“ä}0JG×+¨êmµ§ö…àĞO[ƒc
êá³¯D/h*ğ£õODÛ:ˆ³7•[MÊGøã@eıŸ˜wÌÓÚÿ4½`L¥b ˆ*¯¥C¿b`¬S\<Ø2ªHBÈ]øÛŞ~Èá„Qa~:h-jI£[ÉÀ²ÿÇ3È9´Ğ1¿2cZzÙìgÑMdÕ/:©è­8%Ín/ÃÔ}q:G™{ UâKòÜÈ¶fÚÌı_¢;Õi‘…øÙPª‚Í€uµX¾Ìvw5Ş‚fsa²UŒ\e"%#qŒ:Úî4j„•µÍ•<&2bn?j1ßƒ››ZÏÕÛ2-híğ€Gtœ	Í«„8ÌÂµö_ßáiÛÉ†KÉVU¤6ÃCP™YÀg¢z®€^@« cKiÖyv©ç”?\¿ıæ†ÚòÎ.é®rX =³ÆrmáW HWQFkGx0’b*0‹*Kn’ÈIÛVÿÜó³kÓŠj'eô¢“>‚5LF±_¼h~¬ù6]s‹XÔ”~.…x3v¢ïó¶Ó@¤SË:c&3ÈB„¬¿= åUñüãIÚ—íœOŒñèÇö}™öù^ø+^$‰Uây–ß¤Cë¾–É÷$!8ö¢lÍlM‹ü|ØÚIi+(køõÊ‚$ü·m<{À¦tU¶U_Jşí¤t•õ_î§tÑ£;0ÆTÑ©Ñ„†îùß1ôş¼IÇhaÜÿÆvèy¼İØTm„‹½¹‰éÆm_W© êE¶Œ ï'ı`‘:#pì
Ë
Ïe¬#b¢…¤Àkˆ2û)L´I/)ÂV½iåÖÀÔYºã8-Tû¹HvOÇW-ØE¶„­oœ»G¨aáQ#çy…eU€2Hú‹;SˆsBò-ùCbå¡$„¾õ¸›WÈie.#
V×›åëı;~ÖúşMSÙØ©‚×™ÌÆá~,™\T+Ÿ%e¸Èü©g©±„€½˜Â~ÒÀv£-gú¿:ì.ÀûjWÊ}øÁc‚_™E	ô)Ï˜F€ÏVœŠ$náîJ¯[nPrÆ¢
É5üµÑu;6š&Gš²Qƒ1CŞaVÇÄL€jŠÇÈ±Âöí‚ ‚‘ ×²bœÕ©FîÛW†SğÀæIı›|´”²ØËÎ]~dªÆ¶*§	ÕŞq¿|ê„Ä±ß¨Cypôb«nÖ#ÈÙkìp
ÎFÛÈCƒ¶qŠ¶Í©YÔÕ;,v\1Ö›÷øüAøÜ=Ó·£Ñî.ç¹~Øj÷4?G<qÉïù'Â÷]Ë„x#êÍyF±m?´(:;¸-4
€?±ÑõeH—âÒ÷UŠÉ‹‹Í¼÷] IûÒÿõÛ÷Ô?#®gv¹¨|ú'bØs‡«ÚFiD(Òìe Î¯^ÿ+Å--y)'=>Ãz„şñwsF©ñ›uÊ$ºÊ›ºì¬²áb÷a>tJ³¤¸Íú¬'` (°¬A€À‘»ä~ÃÏ)ZJ¢fd,©¡=—hÙu‚zM|´f­3T	:z×Ï7¤Ä`&Gµ`#Öç/ !ìéèœPùÆ'%íìÛñ¶}²ÂEGÿx«ï¿2˜b8¦›7°…Çêg5¨/ı·‘¨£ŒrG‹n%8H™”F›séß(©=×Ãcr áØÌQÊÎWr3æK
L¹ŸÇoËê­•Á+eÅxdÀpd³k‡ë…áE9Èúk+eZùïS¯_ƒâ‚ƒJ•Xx~ÒjÍ¹©$Fx=*yË´ÊæÛ‡†’=H6çièÜ{SÃ‡ş©ö{Z¥Y:7±<°ş=ı=i[Uôµ)¦€*Õ	qMŞ0QmÎ*v™9æë?& ˜ÜÉ‹%2P¬m©t;¾Í²<‰cDÍæ8æÀÇŞû8Dä›³hDÊòÍl:jiÈÛ':Üe9 ú¨ØÊë×:-ÒXìí8 ¦<,25W—ÏD½ˆ‘~‹:©~NY²ædÀUÄÆ»?“¯]Íƒ'³0²Kİ©ìØ]0¡ÂïõØ	‡ÍLğ
Oí!‘Ş ÎÿUXVgg³ÕbÈÑ+Œ~-a½©òf‡qÀ2µf6ç½õ&|—ı“ A\aÊB4É‡x _®IÈ×>“±Õœêk wîÉ5§£Xs“Â­Áª÷ ²ŞPïŒcùë‚œâğ$=¬LşnZ]í	â`ó—aé†¶b±mZ ¬`Œ ŸxËn%7C,>D®µ—9,p@†u“29Ô”ĞZ× ÔØì]]ÅÍ&Í…ZÏş¹ĞŞñy¾bµ¢Æ!ê’A¼µf"üc@u^còRMÒaZgO$½6Á–•Dá2qq–zîİÎVW@/[Ä÷â‰ÏÀ7_³¾ç 6§ÿ+ì,ñÛÀovICı5‰¶É²#O3'j©0ºcs›xo¿Ï	láÍÒş!A#©Lb%J[ıH/äpR¶ÈˆøÚl1&ÒKo èÚ"í}M7™xÚı—‡ïÌå
lšDÈá<¢áÍló×‹l,ç¿ÅSæm=Z†Mœcõ½è¦uUô¶› 3#ñÅ@:vƒ¡4`9¥Ö^Ÿä:ì$—ï©ÎjÂô}¥ íCÇäVÛ-²ßy ü±ì5ln‚øëZİ0p’hôd7“ÑB)NIë±ã1k‚9ÔEiP#Û¦[•G@·Ÿ%E°åùüw„Ø3ì¸Å.m:_5åRt2'Q@Í†Êc½§—_%è1¹{ü
Ë0Ï±¶Òéî‹Ç/Òå|%ïdh5ºEî	ä(1Wy¿øíM,‘»w{ªı54CløÆÍ@Q³í®×&óåqëÈä#z®–"PWÈ¡©&ø²’#ÄÛuğâWÆdºÑÌH> bã`uZ¾‘Íl¶8!×rÎûË÷²g¤³I“sÆî«A¢W ’šÕ±Ÿpé
ˆ1yb¦ì:_‹ıõÇ+õ™!á ş M=‡#Çú>D/>¨Š$q&!=rwÓüÉÒ¢ğ‹Ö’TÍè¬Oi©dıXw®?Ôaî8hŒÛ?JˆCN4»„É‚]“ô
ğB¶LQÊG¤j™kQÃqòÃÌ{ƒ¿*`x ¤,Rú×ÏeõØ.¥Ùşš•í™j4cÛˆ|÷oVÊsmi‡{i³“ºh“ÄÀlİd %GuÇ¡‚¤e?u+nâA@óÜõÉQáÕ• V‘uİªûÅ(°x¥İ'ÇvÓ~µz!‘˜úß¶§:Íj±§`¡u¯ô=Îa6…‡1õ¤t®ô»Ü*g ëËËæî½Ôû§V–ëğNÎDò°z©«nXè„²4›õ.Yşkc© úîç“`›.+nFéìHz]•‡ÿ¢n\õ¥é*ÆÄ­¤±ißì•‚ÒèZYØioKPëaĞM¯S˜)g55*½×²q¥zTõaıa#!-DÚœYù-á~tÜAp‰Æfæ¶ítíeæÔóæÄ	*Jô­#ys#eóG§Ì´·±ó»ªY/î.5N–{µœ©¥ †–ŠàƒâôÊ™	÷ûN$‡
ËU-+`?.ƒ3 gj24¡Õê;³(öp+UúL)&°;C†d2øûn;A›ÔÈbû%“Lù¸'éÈ#½œµØq*àN£÷ –çHví³i’-uwQ¬ZCÎÏ!„¹×°}‡QŸ¬`SÎJúÓ]WåYò¼#pÓz˜;xÿ¿?œ ÊËmPÜ¢VÃ¿í{išş®"IãÙ2IñÍK-ÄµßUó”•zòn’rM£Vz¿•#ÒäÏÇ!ö4ëİ0ÊÌ.¯£”a²ËkÏ%gB¬“VØÏ¬6Ú/y´E¡ö“Ú{.ë"Rºy.'/×r¿ßp{¹ÂÎÉY¡ëÕşU©Õ*›ÿÛrq1­:m1Á eb€ŒÅ2ÂÿÌ;ë~$ŠÜŠmn’¼hxÇM­Uoâ{<ºûEæZ§ˆZ‹Ê_½l÷Êò×ÔK…PX/VZøRë²
:‘…éòŞ¹Ã­w¹H×ïJö‘U7IS3³EÀ3¨KtıgZ—<ä+öOîå7”ÃÜãAuĞºËMTğûÁ¤mk¡‘Ë@AgşÛdêÑŞ]i 	¼†€D˜Í‘–ÅÂ'™‚Õ“%ÿ*KÆ(g0¶Ì
s0EJ$mÇş¢Ë}…¤)²Àø™D3ú*ÀûŠ9ºé¾ ÏºØ{Æ€ı¶y°X‘+¢GÍë/	GşPtWŒi ­Ë•e7Gìı1ÿ€«30P	E¨r¥ÁÉ)ƒDèÔµÜEGEHåcÂñs¸³2T¾ß…øÕH_ö=KqüÕŒ9/B©ÊyŠôb{?SR¡NTÍÈJo{ÛI¨º<åR×àGByq-ä*é?OŸîDb†7F:J¤ÍQ¤¹\Õrò„vÇó¥Šªº˜|Ûª&~eOÄşáüå|9‰.Ït˜÷N$×6¤¥ÒÉâK`MjœT³éK‘CmjŒ.fÅI|¹€ªy\O1ÿ=ÏÒl	zÀ5Ú=œ[PÎÎ*pƒ¯R3O¤Ûi…d<£ÉØüÄÓaÒÜƒ´H``"¡aPòG^Ÿõ'	Zäø­Èù‚‡#…¶TÈÁ–çhtøÒ*!LoÔÆú†T¥d«``Øœ|f`1ßF1Û<ÿ•ïã¹‚[{’–Z'2º<1c-O¡¦VsŒ‚.Öc¥¨¾úÚTyfEÇÙı©ÇóúĞS
¿]ê|E(%ÔÙ(¥…¬ ¼—æ[LHõuÕáoÓÅı/*±Ñ”{
R§cãêÔ“›jiÄš×Å•¦Ğòä¶Ø£]fòàêçw°I×;ˆ¹}éşIÓ
H¤© À~²pªO`qyI£ğ¤Xİâ%`ÕKâëKÚÎêµÜ_c¸T~µôû÷bt‰¨L|jj‡ˆ.Óª`(æ>½e)äe–²ah±À#ÑañrH`é ÕØ!•²©lXÄC¾c]ŞÒ)Å5ï\(†@;HÔ®À`I5„ŞÕLíÉòò  sLPu®ƒk?À*G@YŒösİnâ.°öÔô­òZËãšMç\§fòşî šHSõD$ÖóœÁ*™æ4·zç#ë€ËšäzÇp2ª>[¤^„şş·ÈÜ^5ÓLÏ±'Q-	P?¿º¢:@cD§7ğ”dˆ–d\4á±%Ool/M’…5ÙBîá²è3²ìöô%LA@ÿÔÕçõvg[“¹6
»à§ı¾oC/åBá®²ÜÑ+Y2–M-OjôÃQ^nïJú•ğ=MNáK-¯|Ö‰)òÊ|!6 ÿïÛû{?$ù+ßÿ£¹ï5Yä¸v„Û$°"7ü|Ù—ª¬ZŸb}aöCÓÉ,ŠI"£!
©_†Û‘ì"ªzŸ×zY x‘3 RÈùÇ¦ô¯Âùµú0Â&{i\kïíÙ¥3øFæª£úË‡€ÍKâopfÓ`ëmü~¾Ó·ğ„§¾äz=Y¸1×ø©m:gÚ¡‡Gs—oæë†¦€–—}¼‹­8ÀÊáhS/lfşg¼XC[ªÎ^ °{¤†ëi(Ô¸{Ñ/g“ªN·^m‹é¯èŸr\õ'OS	ç56T%áÏ¿~ŠÇbM‘¯~dó÷}Q|EÙuôªD_1jëş÷WV¬)]*À{‹ıÁ:û´ÑQH©Õ™„Š“]^°œê«›’ªPrbË£’µ®œéù5M¢¾Í„®•8¦…‚YE<Wˆ¨¨x³Ï,/G b2±Ï}½)ÿÇ–HˆTü´ØÙ	ÂWÛ)jÚ.nÌ˜ÿ£Á+F¦Àj+¯jÅYÖHÿjK[O“rœ£Ú¸«‹¥d)29bš`Cly]ØŒRaxWd»…Zàƒ…nsşt–%¦äô„p îtÏÆAxOœ‚‹m½k?].zœ ÕWTÂCöëxh¶'!‡;bé¸š k1ø›B0`Á=µÆZ«¶Ç:®pA®¶º+ç!E)ıó¼¢àVª8a ¢QS?'İ‚Épç27’“{Çºñ3,…TÄñÓŠòùœ)ˆg£Ò Y¿¥/ ÿŒÂÇTFL
—°N¹Ä½üA´ŠI5—;=àã4ó›`»yØ$à¬D÷Æ+õ œ1şuF\!’(æPì!a¨PÌ©œ­¦‹‹7
=¬Dìæ©ş•(è@ãn\Á9h¯¬>‡iÁ$¬|ÑO­x`¯{^}òŒ4x—u³íŠ>3ì(¤ğ³ñ•+õ×\{(d«V(«3s‹«">|£B+£&ğ|€O`†v•Ïø­ñƒ÷¸LÀ_™õU!5=±ª4ÂTßæ^ã(©¹o¾¾R—HQæ[%`¢õH…-ÜXb4À]îš¶}"JKK¦PÚC—…¹šÁv¯v’Ë=kĞ7ô:·Ñ€dTÓ)é"
ûÕ£)qè2Û ÖËï›7±iJ_S6›#.Ó/]ª€${KBßÔÿİau=ğU²N¼šÕIOKtUN„ì-^RlSk<”Å™“¬áy ıcû’/w[˜«’”OlAn[9ÉÅ"¥h…’a“"êFè3‡0]u®bF1héë¢„Øã’Oiœ8-éDÚra –¬Äz)KüÀŞ÷ïSÄÊˆËnQ“.$Ñw¼_ahŞ¬P§§\ø›=¸è‹z1ú@/˜{D§SıJßMCõbİè«‚ïxèÂ`op8sbwŒ¾xò­Æ¸‰U¶o®®ŞvË±'ânc÷$]  ¯kC%w¨~´ß[˜ªOã_œp²×73àÇxu¢1DˆS~âµú$&Ú#à‚òËîCÈ›GŠØihõi,£„R¸Šåğ»‹F¥*-ç°v/Û»Ñ´ö#?	@îºH¦ÈC‚éÊ[¥t¯Ñ•=¼ˆhk[³ô£¼E+wøİ[íúÿ™^A'AgDrM-b`n,†8è	æ~‹âwğšA®ü+‡?ñİÈ¼¡U_°4£½³u óò°pÙ«ïÄ¨Ï/A]cpEß	N
$´$u5ÅÙnéûxL!$‰»e+hñú×ÂTª«4+é–§cHG*A|Îıbixï…¡„FÖ<Û…ï>M%‘q·´¿­ìø!ƒû`K{úÿ¡¿VË(S CSÇÆjUOoUDÀq«xÌşxÁód[ÅIĞïIEq¸³æ4«'Ä51ÙjDÁ²êª‘Ñ&±álìõôÈì#tyˆ£c£û‰İß™¸>Ò¸ÿR¡¶ÚVŒ? NšXíaùŸÔ!¥Ú¯4sºrwÖ!ÎÎ6ì¯}Õ«à¨±,ı‰É~›ô™ì¶®ÔÏÉÔ¬”ò1Òv&ØP_.3.•p6È-a–lhù¶d¸Aã):9*99‘F-¥“¯×CÁñÉŸŞÚ†Ã ­	UÖ ˜³;éÃpy2÷Má…<Ğ§`÷Ÿ¤Øµ„ñ0KÏe=;˜‘ÄMy´{Œr‘
	(›F8ŒhÊÿËÆ©ÎÏ¥ÄXŞObäOÉÓÿm>~vjz7õ«Q6´›-ªìĞ±¶¨§DäL×m¯µB–Á Ò‚Q!·xS6f;åï­JÜ0·»;WüÀ±IÓ¦æt/ÚgoÁ<÷8H„à°Aó:koşHVFÕË¤«ƒf˜{ Ì²+IÛwÎşAúpwu;yÑƒg¸"}l7×Éy—Ş´X’Á»ŒJ¯AG]2¥†ŞãBä‘Ÿ’Ãˆ&úÛYĞ%âíÆ²d’o§óÊıÿñ¦ßHHbM‚fg8$ó†ÙË›Ô)e¾Œ„Íßá‡%Æl“óí³¦>w07 êğ›Î.6gşÀ½ò”¥h^Ï¾C¶F§%rdo?\¥K³€Ö¥Vm"jlPBÜ—ò©òH(éêclrÅYÿg©0ìŞhÛâ‰È7¾õ¾G3+Eás•x	†”®)vlo|Pğ³Íà´ì‘Ïİ‘6´Ö2 ‡â$ÒÆèñ</Äcÿt¿)+Œ° W¬º³©gıê¨]¦iÕ®Í«á@óş+§÷ËcKüé…ù—ĞÒ­2ù©/‰^¤ı©°•gs™ôJ-y¹%q«‘ÜvQ¦‘ç01ÜÍMB×#;ê–ItÎşæbLg$¶Vô—#LÌ¼”	}çøç$c_"_|­|Á¸Èå†„œî§IwŞ²ó¸. ŞÚiS'óâo8…$N©È·âÁ$ácÚu-Ú›¡Gp‹Ê™Ü›ª/ŞïIZê¢o}ôõ´K	ï"z	®÷zÚî5©ö)áŒÕ®–Gv'%)O{hõY€_’óMû¾ˆç0,†+Diæ^¶‹Ì7mûãç'äM-X,œåÚ”Û'\bÜˆç ñ¦ˆhÃpuJP\ŸÚı³Çj^ÈşpöÏFN_<C¿iÕ^öœ†Ü"R0=¥íÿÒ“ğşLÏÀB‘\ÛØ#{ã,>¤aá;_¢fG§İ–ñ€u;(°IZë¤ˆIŞ°>ÃzQ°MÜÁ¯UDf_ù%|wÕ¯Üc–]5V0[s-0¹Vn^z~è¬ßJÓÜ>^®[Îr˜ÚÃQƒ]š–Q·Q­ ÷ØL¥¥D9»ŞşWŒÚ 3É±j#»kÔV=>§T]éúVn¡À$X/OÑ&è1ÅşW­ì¶WüW5èU] NógoU»-¹[t!8šU¤§òO˜ú
`…Qw?î™óJ›\z»ÿ-> w™GJ;3fTŠ¨´¸NnĞÂXiĞ»]›Ø¸‚Sü	£ş¯}HÙ»4xÄ>@W‰îî·Î>=6¹“3¼ö&}TtØ²bÿ‹Ô‘#U KÔ¨ê»dğæ*Dn^‡íº„H¸‡`Ø¦ÀG©¾RÛÏŠ¡S 8ùÏ~ê§iöJF<³"ğ‚cØÅ®N"3¿×lVs*„¾C­ÙÑ¡0R@êWäiÊ¥ºJŠZó"àï÷©èp)§uÌÖMªDY:ñîåc±ü…8%C…cß•˜œÁv¤  s·øns Â×%€ğˆ
ñ4Ïq4÷E=)·|JTd×âÑâúïş>¡¢knİf¡Fêf®’² ©~ ¢{s¡ş’¼şÏZñç¾fÙŸĞvGu¡ tÓ°§”$õé{à3Åôá™Éï—üŒ^Ö­Ât¬_#|ŞJ°‰®Ş¸fmfsşgƒdÚÂm=$è	èQÀ3±~Cô†`Gİ¨6éuIHÒÔäñá'­ëgKYŠ"YcâGë_Yi6Dà­Èè³t8X¸Ô8äD³ôçw9“ª’ìª`¾nIö YP°fälhoYÓV6G«Wûğ¨×İÊÔÏ±@‘Èb°æ³BörÛÔs#ş¬ŠG[J3_[Fg]´Qêëq•2Y+ã¢å7µ²7¢$†Šy4õóÌØ/­æœT±uı…ÁûÙƒ$MÑ¦5wİÚEå GWõÜ6…2Ä5E¤T‡Ò³Œt ŞR   ×Mîù§ ‚²€ğ|^±Ägû    YZ