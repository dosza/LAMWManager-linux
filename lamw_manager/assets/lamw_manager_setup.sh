#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="932091888"
MD5="53fe4187e7a6b3bcf166eeb9fd6653a5"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22944"
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
	echo Date of packaging: Wed Jun 23 13:29:03 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿY^] ¼}•À1Dd]‡Á›PætİDñrˆÂÜ?èÖí™4ÚÂsG¿íÿ]Ö?©¿”ù•é‘"Ìå´IziÄ1ó³™ÔˆòQd°Iû`Uè+¡$VHx*I8t’Dcr-AÙ^‘%]SSOú‡/Ò¾ï­š ´‹Å Ùš»Õ%¨°!|á’¸ƒ¶áƒè%<;øõÚuDÕ—ÈWš anÏ¶¨fùì ôú¬çQ JEÿŠ:ì€›Ò)™ÃFrŒ½hPŒşëF¼íƒß-ÓXFÏ9¡v/l) ;p†Dn¤“°ùo8†"²Üw²Ø£œşÊ‡•Ê+QÇó°/çü†ÍEôÚ7Ä©ù˜åµœ˜|zƒË¹~­ğş{	6ç_k˜dn·ænv0!ËJ*ñÏ‘ƒÊOÁ‰yµ#3Z%;4Š @Õ5Å¹˜¶ØÌT Ôh5÷éÄÉ«÷œ¾ÇSS¢Ü=_?àAAañ
¤Ë¤ë«' <âIĞj$*P¤ü^AÛ0{Ø,ƒgCY-8\íËA\†ˆÈ(…ŒÑ2´f–‹®1æìŸÑéûÔ©{™’“Ú$Pa™•rOñ³%e<øğ—T<¾3d±ãºË˜š?§&á}8/»ƒBPé-wƒPfv¯9İ_æzĞ83Ïƒ,8tæ¤Ü|°ú~2½`„0Q×¯´aAíR@ @!¼µ!˜±óšŠ“:vœóZ²á¦&f"Y3ZÄ1óİG3Õ.†$S„£²…&—iSrÎTE˜J£EG*“Yïô¼µvÄÕò;•âá£#©¥,‘,v3ÏK†—ËªÖşŠR+2ı±²ú?®Æòˆ*‚(Ö®?l›]OM¥ ²‘6)•M–:aaN#ûË˜‹¦EqMÂ¦°Tw“•‘„,\ß8Ì–@ëÿA
'7Kéz‘òWŸoæÔäĞĞ©‚†“Imt¢Óğ+Ló´« âà–HˆŸËù¶vCíl
¥ ²Ñ"è–tº(ïÇyz´ÜA”Z¢ ‚û…8NÂ9İhDvç·4<,Ò÷’õ“C…øqßèn]Ä6Ôº¬ÇÄ+=a;˜Ì—šÖ9•ÕdW–\t.J§«8½r LZa¬ŠdŸV%HWô•ì\…xş’¯™[(+lÕ]sŒıu§…c¡øa˜ß{^ËñŸ‰w¿æÂ§VÁè²Šğ.A:¦NGwÂà}©µäÈÆì<×HÏàU,Ğßm­ç¾-L<Un?~Âşy”Z!Ş¦o(ŸÍñÏ™FÍãÃ&¨ÓÃ7äîõŸ˜Ä)·4DçHİ¿ÙaR•ñŠr×Õ%³ÈBF!tr¥‚4(4¸ZÓ‚¼şø€µDé€h*äus–9ş²‘ÁU.„EeŞ²î®…WYUÄ$Ä¸“ñ@§Šæ¾ş69ñT´ƒ}*~xÓµÓ¯O‘M&<³2 üú¤Ù‘›Gİaå>€êìD|kw
qasis?"{y5oaQúiYÎº¦Ù­ùcèÚAŸC²Š‹MÊ¨FŞÍ˜¹¦.IÍUÒÇ8öH[¤™£.6—D›ê†¨û+ŸSÄÑå2]ik7¿û‡zE83‰ÓÀµ%)Ghº¯Nh³úmÓ{¥[úˆAÚ\V¼êô®üëk·ô^í˜	Dİe¡”´—®üíAßÈ²€§ƒ\RÀİÈy½û5ë°'â@©YR²ÊÄ³ho!Aqü!{ú1Ï!¬‰æô•»!pè_ çÃÏWä#Âà¾îÙRê¹>ï¼Ü€6_GYáñÔå³Ätäq`c’fñF^¬?ÂE±ßàf\TûÅóòÿ¯ŒŞšû’vã¼ËNƒÀ«\ÏåêRäaCW½9]NePC	ÎCÌÊ¶2ÔÏ+òz æyèğvÎ|-5B>y”S%YÚøLÃï‹0ÒÚ>°Ugı²±ÅØÊE}ˆ§çùTÇôN—0Á0’enp„›;
@`Ync±‚É³)´Õ%[SÂVü_†í×¸J|çD×Xû»¬=¶'Ñ®J¨àîLÂ.afË;½„ïÏz¨:6ø`T”©Ø4œd zyí1Jók‰j"Ú'¹î@0¡Çª•Ã?Ô)¢æŠÖÛG,¦
'ßªì.ò6ÕÍS|xQHS èÒèFë/J2Å¥Œ}Œ1¸½ŞW°K÷†>„Oÿô~]ïO›Ğm(o[È'‰Š"€y×‰ûq€ïU0ˆ­¸şz.ö	İAáÆ7t8.¡š‰»85f!9ĞÇ¢>#Q³¿B9ÑA‘½šÿ][Šı¶ªkò·êÃuvã»4Ÿ
HßUÉ³æö(/ø´|`<Æ1‡¥a'ó ø³…5lzÃÛd`ã¬qA¹Azö,«ëwgÇ~14í“î<¸¾û9®ğåğC›=q\~Ö¾´O3MÜÔÓ!è«êpzŒ[ò¥^İhlvØ2y½K¢ûd¢v–“†	ø†;Ö¨vL$ü-bĞåNÕÑŞ\EÇgZ`uÏ¾¨/â«­¬‰á ş¡5tÌutíèË(I $ká¦”Ì†äM¾Û]}å¾¿o,Í¾ÖL°¾Í;ŠàüûŞ[¡äå‚§U•³É¤…ş€¬T¡1!“}¸>n¬½ÓE$]'¾Õé=~>¸O4Íæ’LÄäªús g8D¹YŠFƒ«Lµ6Í¿j,‹‚IÎ»úw³Od24ğ§ÒÀİQ¬ˆ»ó}A~Ğ¦ã®¯–«ÌOæêlc Æé±€ÂË’øÑ‘ÅqÊ»Vèš¸õv¼Y‘5VàÄÊŞXox&Ä)\“{P±®Ú£`_«Ã•ıWf®[‡Öæ_á»ääoáËÉñêV«Òî%ƒ‹²iøÔµšcŠSúD,]›ŠáÚH	VçıÒ)ÏD¯Æqµü@]à¯pV3ÜˆEPÃ6„°ƒW¸¶Oa}^!wm¿l™ÑÍiâaTŠDõ[S8[
åÛó÷"‚%˜`€Ÿ=²±Hãd@º$ñfÔğwüÉèìÕªYkÙ–XÁ†ØùMD	ndì
şÚúü<6±,*<¶…üÂq|öH]óh…İ¨rèaZ±GáeŠRÄ¢4ô²˜>#`j©_¬¸"¼ÙàÎ¹FyÆĞ8ãp¸Td¿$ÒAÕ÷sJ·¾ŸÁMm¼)mh¸,Ù2m›ò³„µ1]0‡Vh $Š‹bøLİ'öªO2_…¾|¥ÛóTyJİ¶[yúælÒ]{~}È.k2Àaˆ‚¢­>G–„¤ÉKãS	¯7Ü÷ı<ZL\Äl\D[zgæzûä€ò™ ¶¿À(ú_ÈüJıá«—Œ³ŸbÚï§w0ûy+£“zÂe]ƒ·SL0ÜÍÙ%cpÓÕ«~A¸&ıDi-­E°.².éRˆ¨K¦Eİç™{_æo­Éu²(èæg7ëP Î±%ºÃˆÆ»Ô
ßØè}$yêzˆHÎb…rÈIv~•"ÇpoWó °eLÄ‘5,‡vòiÀ±x¡”®şÜå8}q}
‚!W'7ƒ6iL”-Š™œ:)Åş'ø$|‰uÒ±Ò‚7Jö…¡[^†óâ
¢î²!úv#Ë‘"u
ÀÖOµ[ãƒé5›~32Ëèñ¹ÿiiÎëÏ^œC—£Ä€ÓµLøˆrhêÙÄ:Wèiâ›ßÈ=1`÷E-&HúMt•¢(e£ÌâH°h(BÏ´bqYBŞü¢+w6¦Š"Ì2ıÈ*%¶~^ÏêDù4„ó]×r½wèñÍÌj¶Ä‡›‰ğôåuw~‰á+š“†÷ß „”ˆ9§w9ç©M%æ²ˆ“2“^n ™„¯œH_¢_’»QŒÕ/¸æTYPØmfE‘A_‡–ŠõóeuŞ ¦ô·ı›ÿç  ó¦1ğ¥}N=XíÅñ_ñ(Ç/úºø­©;9ıë¦)ø|tXÖ°Âk‹6XÎZ^¾©²Ö™¼È×tğ·¢"ğ“¨ìKuqpåÊ­³ú±N„Û´ù34Ñ|sÇ½Á—šŞ;qÏ/ÑO¥mÒŒóGîPd›ŒƒÚùcÃ&‰Pê<¡U2Eœ7í¶š¢O<8¨O\HE·ø¥Jöª¥rÇÌi§üR†9s.ŒüóÀR¯Íû¼s·y»ĞÈTKÕrÙÔÈs5rä©´±ß—eàşàƒaØµøjL3M‚ÓyUcM	ûˆ¤:•‘T™½'-»ıˆãÛÖ3D¯´¿•ÊyÖZf/Gô÷:È&N¬nuÁ±ÿ·­Q~ï	h\¸™A¦»É`›óà¸¤jbL©ôŸH­é^&Åğãdºu •ûó9–Ç›ƒŸËkøBšıSßnÜËÂ~(~·Möâó7ó­üfáNàmê…QZFã–³çôü¨´#'Ó0“Á`† v&³º¿Â>³ØJ
Ad¯£Mû‹éY3düòÈ»„–‡ØFe¢µ…nœ.•–.ŒıØ«XZõ«yÿ"&H".¾½¿-¹ºÈDÃ4Ä;qğn›-0èÁ§°@J†‰ƒ¿Gæ–ÃÊcğ›‹<ShÇ^w±»a¿*ò~¾¯€•ŸÄ€÷_à=NË™Q—JÛ&?Û¬ƒyšsKÒufÌúÉòh-…åÔî%ÔŠ÷tõ-o©eQòK_şı¾¹îİ½±ßd`‘783?¾šRMWûN‰¦_9ÇŒç¡çQâK¶a‡{çĞéû€£K¼Ù*Qà¢2„ª†€qèæ¦[fÑ»jÚ À•À›ª2Œ$?ë7Q8~ÃgMãÈ/ßæŒRëÌœşkE×¹ÍÄÊÄ,7Ö‡™õš,TF-/4b#Ù—ÎÊO[gdKz¶mÙšè—¤ª."÷âÒ5&wıòÎ×uŠ eX\™ 8¢ğ.„$ÂQñ>… *Çóõ¡vâ5Ù*8õ2ljÔcyã"U
ühÑE59P‘t<Öbü,”¡ÀXÌšİÕy yâ-³"&o¦OO‚Æzğ)p!/9r®æD±eÅı×ã,!.9‡¥àCTœNÉ3¼©µ&X>ıÌÆ5àÑ|w)e#ÎÖL³ú•n÷<Ç°DüshOÄCŞ=LŠc¥Å
y¹Öı.éŸx'Ç¢:q®íMr"ó<µ2İVVˆ[]â7Hè‘‹º-Iláu1~uïËWÕúŒ˜·=gP É€6xÕ®fi?Nÿ)z›Páb>îæMÜ_Šš¶õdƒ`Éòé–Î4#Ä%šwÁD°oraIfŞ¿4¼ê;#·ÚÇÑwSu;)ÒïuZµØ6|M¥ÅìÆE#šSkƒŞ ô¤Ï€;y¼M"QwÃÒÁ3=qîÁ’p]å&m`v=Ë•¡˜Ñ5¢Ú’ëzÑ=°Nœ1–ïìRÖ¶éi#fôX7íT¼<AÅn˜]÷ŠæĞM¢˜½Ô!sq‚[l¾K­;útWëƒv¬QbWfİµ£íá&ƒÔwv—ê¢§a÷«Ó”t¶-àaT[~%S¶rÀôÃA°…åö`Á íÎğŠÊó™èqÈ3ìE£±RÛâ\`jy--µGø‚~¶ŞoŸyhİ"»/4]‹¨—GÖ©±bZÿÚNæ>ƒÃõª ,ı<y‘aÁ¦x~…	ÚY“Iãò6ñªz`Ï¸²
Äpb×­ìN^²ò"œB8ÂVd&Â®%ü•c=ûv‘ó…êç[Esßİ¹k.·×ól¶RØØÿuóûÑÓÏ³¼rÈ+M<Ÿop.Ywˆú:ªıYş
Q:Ş0(1¯Ğ'2]SEmíné/xÿM4)[ÛbNÎ–lNÅ¿íàî÷ÌÅ=%ÒP¾rãAsÄGV½húÏ~Şë‡Óå](xÏu•Ù5cÙ~ÈâŸõ3 €0áíSBØğ±¸A§¨¿+âp|	d$ËøQgáÆ§ìÈ;gdì››òb6É;…ØˆGz´4P÷®C‡b!ÃÃá0Ş8·™‘Ã
5¬eZ×¢ôdD°£Ğ,s%Rÿ†ñÄSø.R@™½øİ4xƒÃ¿›sn}(=UC¹ÿŒ‚1¡‹O\õièP$Ÿ£Ÿx‡¬­¤öËUöb1¹á-»ëô~[¼ïcn”ÉÑü•yQšÌÎ§/ˆ&P‡2ÛôWÿÚ!va#0ÚZZKLC†)rdWËjE Ã*_öî-ƒ#¸~tÉ
97U!U¡uŠá|RÌ#\p,µÓı†sB4—éŸ«`§'ºx'V aPÑ€åÎY/!è¬¿İnJ_+³-XâãÁñ=¤hŞB­ç¿+Jé™ šÎ–Ù1çnc€ÆÓO®½}µ‘~\ãl@z#è´¢ÌÇ 'Ék{x¡Ø¨é_èˆ)Z»B@QW™36e6Î&`@Ë?B–¶x@«uc”›÷åİÔo·_t=,svmèÊNŸaÇ»/¹¾jØ0ƒUœ}A•>¢¸s 	}¾œF	ÿ0Ú§¶ôbË‚İ©GùfêeÛ¥ıò!ú|Èß¤e¸\Ğï{NZbK{†K@&:›‘r‡‘ßk#iÒpUäb?Zö;\!ÇäFJ6RƒŸ5ÜM|UÓËõ™ˆ¥–QW\´eã¥¹RÔ)kıÛ2lkÇºwñ~òË«‚•ÙÉ”×äZ ‹ÒP¯k	T„ú)ÓÁhGPÕªOkGüHÜ˜íè5Qì‚÷<œk÷ÿÁr,ğ›ÌÚùÓ“œ[P3à
Şì‘H°uß•Ò)Z@Eå§ñ¡¤Ú=dE-1‘3Ì£!’˜¾Ğ&+zMaW~ñ™%«\wMpnÜ»Â”Ÿû¢qsƒkiE¢çˆn¢ÖÖ*OÒ•è˜ã¿‡“)'£\¼h÷fS$´³ğ1„Óş_®`™İ1%Ö¹urc„Ázº¶ˆ,“4Ì“Ê,«cÜsãuô‰^@LŒø×ÜÑ	Øøúzk”ÿ‚„rRacë[™ÅZ>ÇÃ¯çër¶í‹/»ÚæÄ²—×3!â½_Ô8ÅYı}Ë˜=œòZU©Ö³Òÿm;^GŞ’}R§B¤Ënª®w7£Ó‘Ğ9}É¥‘c›–aØx]=C;Ø?~0 2Bí˜¥ù÷ÖãQkzb%k8ğŒ\	àò·àõÁ 
=Ü¾¬b îq7£äÂ¬Ä§e›—š“ªHí—"ûJ¤l±ªeœ!º<æ¾–É¸OëG6_: V1ÏE¿öÖzeP@˜“zM±ºì”’sz®3Äî#»Ac–
&3¸ˆqOôÒn
!{İşÙôxL¶±÷“V€•GÌzX~7šÄæ!¡vÛ½\ÇÇšhÕ5Ù‘«àDw	º’ù%»ŞÏù‘' »Oûgø\«Qå‘tíz(ùã¥ïÉ{×ï""Î³':ÁU¾/Zåïyñ‡Gêßrók¥8â¨g×a‰N.¥Æ0?»t¢Sº|ô¨»î^+l}÷¬ò¼¯pÂÒç¾²åZ‚°(¢Z7æ¤àªy÷úÄp0@¢sãÆbT=d;Ê)ôMKâiİQïºP÷Ywc­şá$N?íûNaõÉi#ÉŠ…µ‘Éõ9h”rq{íïÈ@´hÑ22ë¦´|@uX·bÆ¼(5 õÅVt†¢7-–tÂõ+š›H*ÔÏ5u"_Zc>ÓhìvªÔıª2à/ÉĞ üÉ¼cüÚt0R€k	¾“ÄX+E^Âp·BãwŸò‘éÏ¤½43Lœ¹F÷R}Äî’ƒ­gaqšİXû°:¬"”º©œ9‹n ¼Ì¡+Ü`©¢g¹ëRe<Şr±£…,ši§³ÑZ0eä¦*ééÂï3Ëá È«'~ëÕ],Š5Ç§†'ºË°h¸8öû‘£Á0äÁ#R9Ø°˜„å—B_jlnÃêî&‡¢;«O!td`
ĞY‹ó¡ı}[h.ˆi‰@œ¤Ò/{.ŞñP}3ÙĞÊĞáSF/y‘º^Ê ¨ì§©\íy¼<xº:øH|õp4±Í¨4†=-&:8«»‡4¾VÄO'ÙûÑxÁïyê»¿C â!h)¯ÙQ‚=¤èŒíñ$”`¬B3 Æ¢6é$.£˜åú‹Úñ‚ÂúyJ¶]ó[{ï]Â»Ûó‡àåÎ°î—&HÇÔ>Öóæiô"dæPfv:‘âPÃ×~¼ñG
"³ãúÄ…¢*ZJ˜Û.ÜÛ÷°6;Né)0ˆ³¤åWhÊ¹ÈÊ¨A¡5Ë)9 ¾e4×pr¬1†&©Õ[UªP+jÅ§şZ«=0  /Ğ¸Hyf$OH–ñÆ#¬o1k#uFÔ6$kâ0á“ÿè6_rşÌøjµË¯f é ./°ÿV«ŸGÙ‚.C¶šıê©$HûÓex=¤z_Æ]<*4õdâÏCëŞ^ŠÂà(è¬PŸŞÊ´zÈºìlFfVŠZ"!‚…çì-ùŠ~İcX!^ÉI…i0•«ta•ù-yM£Y×Œ"ˆŸŠfoš!Ÿ­€Ñ Úä›»…ºÛã
£ÙRÒh¯VÚòÙ‘VbŸÀ,'Ç6\e-S|pbùBwÚìù±™Ãùı!aiBı°§ş°)ó«ÃPbµ}ö$z7Ãb$µ°d¿âÈ(èâ›xN°ø¸€ƒ(´ÁËı?©\¥ë«½àq6lÂ¢Epa(‘›Ó°U–€(‘*îUÒAgôÑ½,ûC¢6”§P Î3&l4bvb%@y5û³°Š`3&v¦u2b¶«vpî~´€èçv}²Ëh¦û|.vp°v4(›…@1ÛFÿ8A-—À£Jl©®×{ïºğØ­× ŞC!5ªû¹°ÛôÕ|[ûoï¸úòÍ*–ÿ×îvVpÓ’ì[ó@Wx¯îäÈ/ª®A¹M«+·]şÚşñòùhÍWå–¢)pÃ8ªGø©ôLÚ»ëÄ½˜ØÑô.$ÛM¦TlÍ3y.NIP¨Tò0pHìäc×ï/ÁÎpÔ¿úVrÕ{(â˜°,-&º—_vğì‚ân^¼ˆ–jâŸv!lõÌFcÔD­7üP-Ê7ªP·ÿÔ
 |Aw»îs†zZôÎ¸#¯ÃŸÒî¼AcõìâH}Hì›bØø j\Ú"ëÖPê­ï t¾Jº?&iOÕäQÏ!!8H´@™¼©œ‘Æ’Á>‚ Ï(Š°sƒGHâ½¨ä6%¤·]lær-Q%ItbÓë‘+“˜òóç`Ás›ˆP§g3ÿ`‚å4‹İÊ"ª¦…TUšàÕ8£)«]&Çøuki3:Şzÿ’k!»ÍFrõ
²YÊ"á(J;<Ê“<ØdìÖ/ îØ:c·õrĞ|ÌˆüãÓÉ3M|˜#;!`?£=.~^k5MŸ(Ö —úÔñºú7šã3Ù¦^oïOúÖòR· g(ëEŞeÅÙô³?0N„7ûRãÇ!ò@×®‰ÏCcR­4ÇÍS ‚.`%¶àİÔú‹§­0¶z¬Ì Ø¦ÏIıªV¤8ä-UğŠÁ,gnÏgcK­ È p"ç.ñ,–¹<›ºIŞ+õÙêRè¼:k4‹”/-ÉwwDlĞG o£ñ÷-*AµA¸PïI&Dy!½y¦ş5ôï@I‰ó•?×‡å±j5¡'É…ß¤6ÅYH¢Xy|õ©Ÿl…u•[^ÖÑÅ<}ÛÖÄdmTñ#¦Û\fİD—w¬Uµ#/BWÃÀV9`nÎ0)&cD«M²¤“nZĞ‘¿T8)X¢ås|ö„ÍØüChüVÙkI¯1ñ»üÖ:I°Oàs.ÈÌcÄ‹û›®tDğ–p}-·^æçÒ…îÆ½=Æ[0*4:ç…‹Ñn0~i?‚"º_.ìÆF;ë¢8–"váo=wâwşt×GÓC7ÃÍ w§¥a\’›øP“º5Š€m5µå•«—[ŞÄ®Ì 5­*LiØr°E¹WUiªr¸ĞCOns7ÏâüÛû½îU~€ïtV=
ë²¢øÄ
Udé4%ú¥:§ÿ¿Í’ŞTë
¶î7áä0E>I1 y0[®š3ª8Óî+õ:*Š~øg¦¬,ç…mÖ@úÙ+º´Bí³(şµè‡Ú2RR[Ãz6
¡Ìş9Uâ†İîÙŸ~œFš€ĞŞ/ØèvÕã-<¹—ÅMSşÏ#½FïÚ“-¥dúš@„RĞ_Ìà7d‚û$ØAZ4ÃZ;*›47?k^BÈ›sI0•¥d)ÆLF7Œ–GB«t|Jş‘z],=2ºïs«"'Xïát?å8ğ­.-°Ã<~‡§~2Ãœ÷´*Ô¥ç,”*»XóâÔ3‹O%bK±\rÛCfåÙyE\%Ñ"!T¹êLv Ğ7÷Òç|§rú“EuG6ğgïëöCvnº )lóã9ÖVmyÓºèªM¯L\t]JÍj;ßÜ}ˆH€V"˜±êrI¾íHª,ƒõPçÑa³4	—Å'kÇ3áq.Jšõæ§õmSmÁG}pë•O5RØSt¹©-Ì©¯k3Â´DÚ&êëİïP“İéöÔ.ßr/‰=äÌŸŒpP”’Vº ÎZã´»n<ÏÆFG'ãp Ì%„|‘èj§3ù+
Vâ+rà¶JÏ†7ÕbÜŒ¾ú‰§s›éó¢¹œ	Ô@œÕÎ—IÍ\¬‡®“G"ÇÊ®`£ãoø:!¥*ğbâ8Ä¥Üt}ä§€BGetçHz6ºÛJÍ¼*ÒÔÌ[—Šñ%hãÇ«7=\ÍËq
Xô „üoÓ¹î/G"U¦5ÇıˆŒZù›seŞŞú“*0SëöÈqÀŞeç´kÁš)œ™¦Ş&Ç½´\˜OÓ¨ÿÙ-º”Pk8òÊ£eĞO×˜¨{<.bª¢„É›ër>“°§ÁŞO×ï; a†&ò ]CWíf¶¦=üä…ğ=/y÷&Øãé
ÚêsáæP}ÃÙ½‹Z4ëÕTÊìÃß5¶æ«ä¥añ* kV·§ì5IêJ:×^—ÔOæ>
[0<ZXZ¡.Å6ø¥q#w¯4;NEáQĞ”O*Çˆ,GƒÄj&Ãy~«Z»Ñ*N9ığø›6–µ¨gæTü›ãIšÊ×yG_€ì°Œ[1Ğ<h8ÃêFİÔp/ä†­[ÅÜdS[Ö Vãàş†Ï¨ãöié%/›NFR6šiù‡ÜUÎ780DxàNJ£R–[(!_/Ñ£sü'Ç8‘#Ó?.W[^Ò±+÷ïlŞæYúéó+P°ÌSâoË§ÖUñQ÷?¯bÚA—}¸D=ãn´|zNho;©e´ÈíŞğÄô¢ÎMFÚÇ†‰o0”Áz²R>¿ÿq-WN`º`³õ»FØ¬ñıL±Ji$Èœ2½Œt¡oµM‹8¿Æè6ˆÕòÂ7h±b]¼M ÇÏFã„„ÖÇô”9l›ejN-‚m­íß	iÚ%©Ä©şé÷ºé¸gåÓÊµ‰ˆ²/éuU†kfÊEç
Zº²ŒáÌ†\äP¾W2ß/ÖeEòMÔ\]p6%ÄŸÅÂ/ú»ÓÀn¨^"©9_ç?æ)®ÉRœv4Ç*AŒàŒ¤7Fağ~ì¿›%Â™ëµH'Ê%QĞ›‹“T]4JFa}éá—%)×…*&šŒ5¥ïQprËÒ;ÓİeÉ27ZM>×²–9=µéÎê•"‘°˜NFsàÅ:O!pæÈx‰º¹-¦ÃÅª29ˆêgH«»UœF‡Á KŠóGì-:Åàí˜Ûæ”ÉZ š?âD “ıïk!ªO®öq^s®[5íµ&Ù‰³†¥ğõ}»#)é’1œRO¾JûFÙmBÚ½KŠ›Ü¦oŞ¥İ§_5œÁ›Ññà?æøj€˜@àíêõ¤Æõ¹½Ø[°+¥r¥ŞxÛÀk¯üj|„cï˜Î& ©ûK¯Ğå¿Í#ÑÀáÅÉwã·hõºµs£,€¾„`*c¤8Ácˆ\íØ¨Â¯;º’×pÏšü@éÑ¤aJµ÷|íîø”!î9ø`I†æ»U×€}ÂÚşÌ
X¬Ã1Z‚ÒQŠ*
æleÍœ‰]-´ñˆÄÏ®”s×vyÙ$Øä¹6€–[Ûl¼ƒöí¤»/Ìû1—uº³B•U6fÍø ÿKX4½‚ÿi‘EY)¡’…Ç
Ic»ö)Ø*
Õ…5’ˆ‡3¤ öz´]ÁÈÒÌ,u¹ˆß&…Ÿü3%å%Ş¯¢ÑÓS=Œ]Näy:¹¬öNëÎºÊˆ>I2"Lû/äÍS-¬Ü4>uË³ãü*¶–¶è¡ ÜÜá&ÅGñ€ºĞPCzÑ-óutgÉíĞå0éWã§œS|é§ê¸±'¶fYØœï9«Â„O«jÉ3˜¯ô·ª'ßïñü•âS5Ÿ‘.§úš¦Wbå8Ö®è©p§­[Ïù)¢§ó-c˜†â! «ãö·­½`ƒ‰šÙÓgÂï™ ",!€záãåmÓâÉPõÓ[àñÎ›ÅgQpw0É¾DÂ‘vÌœÊ®	oB÷Ù{]ñ¡Ô:°µÙiBF
ÊÔ/Št€c1FÒ=êÏïzÂÔ°n@œşµÍtDsj°è **YFÈãn.…ªG[aî˜Óu_azöàĞt´9øñÿ¼ÿ^3¢§@.º©Ş5Çl¹/,¥ı#V)›©y1¶”È?yôš×Ú/
Ã‰xû!fó3´±œ÷‚8e;«U³¥š•ÒPí™u,yÑc§ûÜ´ã®Wòúß™úØh’;Eh§Ï@„àCË2ÑC`jİ³p¢µX’l×<[ò	Óš*~.Ÿ—¤Ak·)øN¼}İKªñXî¾TÔÓÛÚØ3J³Ê]~V0˜oèª*ÊÁ^7IroõØó
Åºc¬Ê1Ô1];yŸB	U÷QÈƒÊÓ(5½0|ô{ş(YÚĞrÂHC§XáB¬Æ¦ÉL© àíVîsÌŸ±í”"œÌÉÒö°aRÚkõÅf&~£	{âÎŠ—©¯‚e63îBQLícR`Ogõs×¼í%åóÕH¢£`jâŠİóê¦*XÏQëH€¦êòÜYy×™ı‡U–Ïij×êìKÆR{¤‚ßÈ‹1õ|6²Ÿ^LZÛEÛ=œ>òµÓ×¯ŸF9ÊDl¸ ú^‚ú?Rß*ES›a|¢ih|pâÄ‚Wƒvtà+€ +WÍg{`~là]Šâ÷^™)Ühv7>"†n«F34ë›ú•çRø›#·ŠEH½øDÚZM“Áƒš?/–s	—ÍÂß¬3xª­ù¶X]WÚçIÑy•¬şxıvçXkÔ1Si*sÌÎ«Àµ'e³ïçÚÁ®¿w2Ô¢¨Fß€C(º˜ò×J/Şo¯âT”kÅræcQb)ñ5ãæ!×<”§Ê\S§våT"»›ÀÓ§@KíZ¼b”„Íº±ÅûJŒÛc£&é s0!“¦¿Œhp°œ'SÑ‘2ù9§%jKUv60á*DQí5$Ç¸k°Í…kzB¯"¤ò06#B0¿â2øÍ¿§Šsßœ¬:?Nöº3%>ûû‰<
È¾@Ğ/¸ëÑA‘C¿ÁOšÔs'Ñ@‹ğé>C#é¹ŞÇ‚,^ßeÓùÉR4nÈõ(W"Šù›”$@5Fdx°Æ¡b¬3ÿ,e9ZÀ‡PÌ*XbÂÉqÈ‹u†7ò/v*vqQ Y¶ ²ô³Ïx!úy*˜%m¸ÌTÏì›n«™–-0‘-8[98}7Æ¾Â#R‹™Ï«InPû†s‘,ğHüòº(a»Ù-9³Ò¯#¥Ùõ…DUdKêLÖÚaÂ¤ı%h
áï<7„o9½ÛD™®	4lhø$ú9ÉZm3Óÿ¯îì`˜&rbÖ*5
r¢kzŒı2_—éN~ãe¨7ìH
¡ A87zp..š†kÕfô(S,USù
µ]-ôW •ÍBIôaÕ¯MŒÊÎêU•ä8³Á8ın5		¶	È•¤‚Öªtõí“\¸_øRö(R‰azVNÅÛhjMD#û^>QvrP3¾ö‘D½»Ø{Ôv€—"[iûYä®’}e6K³¨ë àçC÷'e?fî¶éÂÒ ¦ÂÏ ¶Œqğ½!€zyÃ²fĞñN¤vàá¬,&7/Ó:Ó·A:yCåª^&oZ\ÔL¬ImK¬(Y·,‹|Ò$øß1¢=Ì	èC#G-¼â¢¥àh>ãæL<ÈÀ^=h
Ç!Àæ:?Ù9¯$‘jÎ1¢3«ì?b»ˆºÁ\$ˆÉHBŒf,TY‡ä^˜]†Õ:+ÎTöTm®ó’‰4´ôÑ?ŸD¥õ— Ø˜íªctq§±ğ¨Ğp@N¨Š#’HI@ü~]³°*®<í¾¦wØˆşhŒèÌ>o8ğ¡±Ëñ"ùM‡0fB9 v<}©ê„<5Á¡¯Ê9+ÚùÖrc½Ó]×…§+À6÷[Yú3I6Ÿ¯ı¼Wˆğ*¹…ïò7_5õ;p«*Û•ç¶³!å*ŸJQÄù¤º
cıT®üS±]Ğ3C«ùsböºFñ9 0üëf¸
ÙªñÄ¶éög›ªH›ŞÙMMì“¾\Ôj“&^ÆŒ8Ùİ„gˆªuh:¢M¢aL±"mÇ¬·äXNÊ¨c
höĞ.~òNt:“Sà¡Şµ;Œº„ÆU’~+¾Êe½è½HYÕ»)êÜh.ÉÃ-.‡||W¡=8à¬rò‚äwâß±ÕÊ_C,_•=¬g‘ 1ÚÕõT!òºØCõØk˜’
_I,E,³X·ªQÙ¸ZĞ]mÅ;â…sÅqŒ-„"õÃ¹ÈĞ{Ôïh×F¶dÂ‰´¬öômr´¡zø.c@¦ĞGƒè‡í}SĞñ¨5^Ã˜Èâ0ÄúıiŒô…pÇ_¶•êS¢Ş5qSµ[ä«#/šødØvQ²jèĞrÜh>yhÊÎ-<>„Q3·ªGSJ}.÷²ÌÑ¿ciiNÖlØñÔï z§Ît9"©lqWÀ „Ş‘‹”3ÓY¨ÕP‰´VIqqu…"Óu~Èçzİg²1ëWš?%{µ¶&”"ø§ãü\Ì†7e;çpÊø^¶a:œP,ÁÄoÊj‰Ø	4Iå	CëúzÔ{÷ZèJ7(øT¶6=µìfæõĞ Œ·.7]Dåì Š.g¶é4*	tl.èIFÏãÊyzõw¾é(yI%œè,ï=/ÊG2/Ş°©ê–èİÁ€»â¯§?“:€r¼¤QcÍ{Æ¾~\÷Øµ&fì’TÈzaìÂpQ2Cø’s†ö•†?%QtŠ*ÖŞ°ÆùO×(Ã§®Öë?
Ë°I¨j ƒ@ø›®‚"Rù¸:U71æ}~jä#IŸÀ§ÒõRÔ¯õ=¡´a]¾›!`‹rh Ç|»9 Yİ=,fbÓÏV{†9PŞÈsŞdŸ‚	#¾©Kî2ª«A/ı&Û> ,QPó_%`+êá$K¥“EñÄì×Ë¶¨åò(šÕSæ•ß;ÒÛşÙ{kã†œjÁB¿= h¹~¥Üái³“Öşâ><fSõú@V’ÅÙòy}ùÍu-¡Evä!Xû/b´³ò&yhğ»0‚ôî!°|OŒ8¬WÉÙŒV ®¬Úİ=O”õÍğÜ?P÷Kfá¡åh›êİ2´1²üênáÂe¢‰”kÄ9&§„t‹–µ½Ïïñ\2t¼ä´më0$¼úºšæ<ÑL~1×€\Ù*A®2RŞËmş_wùêûöšÛšë/t
Kã÷üÈ™øHĞÕ4HÄ»8Bèiƒ¶ÎÏ.'XLmHe1hÉ¢C.ç–‹Î‰tœ†é°ìöŒùŠÓ@SJıqéÚ>²ÔÎÂ´'¼kD”O7˜+,*ÊbZğ@-‡Ÿ¬Ç‹İ9£ıAÿÒ|/…Àmv°—¬Sœ‹g‡
Âe_<ôİ#üÔ½—ÃÄ‚È'êÆ~.=Š‚È9ZÎÆ=3Çç {§[‰ú±‹üÛåÍÓ	‘8Äûl7@º dznùÆ¹KIY¦-Vª;İqï£ˆÜo‚^_!;ã]# ª¡’¢ÊŠ¢Íé (²dÎLÓ&¥ë‚J}§?¶.Ç,”.òéx¹ÿn©êñşÑ›ªzÜwgˆoË­ú$?;s–»«1ræKÌ²Ëñæ¦0gÌd£ÿM§û5:6ÿ˜îC—ë.ROsB×´XÎw2u+¶Ñb«ÓØëDeÊÜÿã @wé>«ôbv¼qBÓ†ìÿŠ3‰WQÖª&wNêBNëÆÔÜÌ}Tô7ƒÒ<ùŒ_ÃÇ@“P:–F²Æm )½'ßİ{uÑ|	”¡Æÿ_â8¿JD¾+g›Šı·@ÆÜ±S!£b¥íˆĞÃîÌ¡÷¦„³~(pT7ƒ_ÕÚHLué­#Z‘M¢r£»*$§ø/şÀ;TÒsWÃÛ¦‰U/šŸIè¥õõ»Ÿ(úb¡âS**Õqô“,"~MÈUˆòûŸLz‹ãúås:2Ã¡ÙHDú9Ö–¥O3Lçc’%pwN#è¤lv8[–,Ç˜™x"ò–z«€«·]ßåÉ7P Cö´ôŞ7å]Ğb¶°+ˆXD³æ¢±wùß^•^{1Í˜qp‹LgiÅzÃ0ÆŸæ÷a¹«ü4}ÅÈı|LbæíøÚÑüò-°~”gßM(RÀ[réf@yH¸q‹ôù]ÓSš"å,»Ãc°FDÍäêzßóëWÊ\Ò¾Ğ§'+OPÊ+åï pc«TëTÏñ%Íß{âáô•#û”<û½ğ¶Û-íÕl´•æi¿­ûà Å4,%Æ·jÆÀ,®B“Î¾KµĞ‚< š:Jş 	´ˆÕ†B‹\v /F×dC›[P-ö±
­~Ì™¢ÁavÎ¤ÂKh}„E«X*Ã1²ÕÒÅìÓ‡•ØcŒ È.}¾@Ú¾â2’Øª'“ZHÿ’­Nî#TŸ‡Á«í	â¶‘®%›ê?@ÖŞ)ñó^1Õ¿¿PˆÂ®R—¥ #Ç+0víèÏ{ı«QaZÅl@e,gU=bõ…ùC?.éÔK?,~h+tÒØ¸àcëô4²ã-#’F•ªÕFZw¢fç—Y‘ÍÆvïşğ¼Ü‘SDG	¸êq÷¦%åê‚şôQo…·¨’\1İd4$5zx	…tDegû ¨0)HK®\8
à÷B„"X§:4†İ­„,gsK]§n3lû­\±?ğß ğ»sTœ\W@ê™‹K8ËS‡%kSˆ~"$·ÛÈ>ğ¦ ƒ_0;,˜H—¥t¸ûICßR;ØÙVáb«„u¼¿N)Ù!Ì_PÁ13‘0
TŠÌ}ˆš¿³½O Œ‚ŠÛĞ³zË]¾g8¢­z'iHäá_ô™ñÇév=_oÈ!N40r2ã1ÍŞÑÍ+SoŠE 2c	Va•b·'¢ÀO|SğÓ§WÏøvbèÈÇ; €iJy=mI¶šĞK`¥ÿãâfg…ü+õHÇÂiÕ’ˆÙ6›–ãŒğúûVvHIXê+KïÇú Ü8¤%ñ¯ÄútQ`pUD#½¥ÒœÎêä7öİh%¨¡½¿Q°“Õ’¦Å†Ì²Z(r<l6B·ŠĞœ
P ƒº2~í¬][ù;±ÉD|¥x*û‚ †?ÿ8ÆÃâæ˜í¡Åƒ‰pÙÓ`àP:]~Ù½º²m1LŸ7³!ÙRş¡ûŸêâ‰¸VLıôÊMÄHó½±	W*T»íƒ¶\+Â3†ŞFœ~¸ğMŸ‹Ô¥É±pÑ²'mEnÄ<›Äû'—9x0irë¨h®H¦®X&˜ TĞÑ—İw‚¸ˆ	L¡Â]æ#É´85üÿ0&¯ì®Sİñ
îªî4‰hßªÈøÏC$­¤şÑbN&'q+UF”Ğç¨Î±#º~İŞ„7¤ıts2öH?…§ÒÌW‹úzÂÔŞéº
_s²…x²Sg€`.D/ËÙ	o®DT{{HÔä,Üƒ¾â»1ÑœÙw$	ù4»IµWÀK„›Ÿñ¯ƒJéÆÇM¤¿œ’Ò
’€rìßÓ%}¯Dw.\.Eƒ ÂyŠQ¢ÇCşd–.)ÖQ0 [~£â‡±¾¬ECÄ›}UIò/™•úîĞš‡˜^£… …Äµªæå7-äNDÈ£©ŠT®ƒÍ­#9‚?ÁïviùPTşŸï4‚uátUiiu»’½µÇÚÑ«¤¯5ñ	ú–ı²ã£ˆv T}C!p‰Ìm°cS­6y=Î“º]l|gV„Ö¦Ü6ôÖ
Ùl‘PBÎ÷¶ ÔÑBK1Çsı9€È)ÚÍˆ~` ASø6`/4_*BÀû`¶ËVâ=ĞÇ::˜ òeFU*~¸YhCj`‰ÛËåø]†ÊKæÃ DSNõè®3ÀÙ†8Ş»Ü(.ïşÑš“‡ÉFËaœ÷¹ÌÆ ”~¾•9µ<©ş¢¹]ôsìÅñÛ´P¨‘ê,Hµ3u=®“¤Ö¹xŠÍ™Ãj|1İ.Ö}$ÕûªÒgHèV¬¥ÿC=G†V!ºªX…qÊ jµ?†xšÉe"‚´=3”H¥õ‡òÖ
XfhK¤oZ R2%¯:^vÿïåïùx¬çs#ıçî$.¯{eË”ANgãÚ¾˜{Ü>cÈD‹»¾!DJ¡"ø€2èz7R£&XÕ;sçªÿjäZÁÚ”?lg—Õ¹™Ğ]­Ù!–ƒÜáñº·ìAàX¼k	7NMª/¼Ygç¸èÅ)ïbaÒHuk¼ßØEV”*¥õÆü÷V½İ¡fî?Ö9¶¼T+,N8¾	]ëÿØ#`å*˜ÊÌ‡®KO
µÏ6™ÛÀJ¤l]e“ım\7ÃáôË§Ö5(â¿!”ı3š‚ÑCl¦ØU—³ô–¿>Ñn•eĞ,d]AŠız>ZX¸ ‡BË1¯)‹ŞæİÍÏ!0MqŞ²èÌbê7Möƒ½%M8õkµDaÃé›€ØsÌ·³D]’Ê<ö¹^œ;ãG‚5^‰Ú¢bÔg‹b¡ã‘à,{ÂŒãLöÛsÖ¯¥‚Ë+W\-u<G_äş®¡2‚&‘½°øúâiiw´ cN(@OïåÇéí0£U‹nà©6–ù<4½îÉù¼ù†v›ÕèÿÒéÃÉ-ë'QA6?zŞoÈß¦€mP÷" &¨eM]rŸ)bÆÃ+rØ6|:0U[zïá·CÄ—ÔPµÓíšà³¶åÊoÖˆ>ié¿D:hVÕ®¿é¸	Ï)ºêêÛjÕv^öÿ2w©GmÂqì *Zì‹–x<­‹²~Ô>šİvi.Vx—Ş;ë]xOd»ˆîÜ‹®Ãs¡ÁÔ‹Õz „Hçh†Èçş¸)–8dÿsa‰ŞÆÆFt>X~áŞ¡rísUo¬‡J¾†[<…B½‘€a‘ÃV­ÆaºïàvK@Ç}(<³MnÃ~ç]Z·GÓ½;7O$ì˜jçpÇw7ö@`H¤—ãø¬ª›Ò (Ğ3sO¬¶oLbÖ¾-[I‡<tv¨u•HS¦Ò€‚Ê¤	äc‹úÖ|¤­[YR*$‡Qà6#ÕûN»á”Û²Zn_.®“ÆÆªöI,ª¬xúòãâß#jÙ¨ÑI)sV%†ôï}Ÿ¢*Š(Áé8¼:ğ¹s*¹¹8/ju[›$Ê0|7¼ïRÄ½ò×7üMï¦Áøçj°?ÄzQEÅDúË—¿™Çd¶JŒ†¥ÄÛÌ`;jbe“¯i²›Ï6—I6!±ÉÛøÖ Åß® ÊQÅ<¸gUfL_òŸ¨EKx$E›œÄŠÆgÅ4Q¢˜ï-yDĞWÆËîÜ²U:½@FEÉÔŠÿÚ$Ù1ı;(¨iñ‹ær;æº®3ƒ;ç€ˆÄA©KV#‡
y aU¢ ¤İS UeqÊÑ†»=N¦ê£|ãÇå™¤Û©A¯äÊğ€#ıæ‡™€î§¥Z‘ì-ÔÂŒÖkQ€Ø¥Èß:Sìï#q×ƒ„±ñ¼ûB¡†Û{Xßkt5ˆx‚ûŒ2
­öx+hñ‘FAø|‹zFgàÏu¶0«qşÃm9HÁçı%o›ÁuèP°	éõ\p)­	cø‡°Óyo£ÔŒÄìéZT+®Õ"³^Ëj×ÏÏx-äÂÀ_Çå¾ë–Ã9ş³\³ô‰3¤sTAş&ÑˆüPÛEê5˜eÏsµT|™‚/Ì)ogIáèW¶³Ú
¿c \ÖÒLÃÿßµ´^JÓ½\ªKõmçÖô'%KMHó6”ªòã¼9(oÅ§hÚóP÷üQÑ!ãZgtãù8« ?[¿Uö^ªÖ­*ÈÛ§õ™¤ÀîPØbYêËª±¶ËåkşUs“ôHÉG0LX	&N}…4>)!—¼ş,Â\¾Ï&Ÿ=äN°>‘êójn,T>:¨“!õ*ÙCÉh(Ô'¶f–´ÊSoD³c#Î1KàÃ5/´á
Ç²¹TWJ`vdäß|;x®$NÏM‚kx°D&Ì7[uI>/â·{sbtGzÌ¦Ş²FV€Ë%šüS,˜4’K}>M²¸Yâ/FÍh€Ö½~4iã¡\àÄ/ç„Ÿ²¼*pµ0‹ÒÅ£%?—áünÀ¦Š=`N³FkøbP÷ Rp'iFëıT\M‰s,ñ‹‡óA@×>$3øÀª¸©lÃ–7n$Û¸÷ûÑî~Ïs'hEP«A˜ÙÛ‹#ö¯U‰¼s†ª^EŠVÁCÅYÇ6éj æ€½yóĞN;œJ^97@t=oŞ·¨,§ı	Ğ1ïÄÜ>Rà_)½ÚL{_•¨e –fÌ«^6ÿ¨R.67C¦"Tr#e`³$‘is¿›¡ôëşg9îø|IfÙú Œit3–+fRPËwo]¼¹ªÃ!\r½¯öw“PÀRµÏsæakz¢Ú»ÜøÙå©`ø2ßı8Ûê³fÌ„^–	ëg›İª¤8Cv¬˜odÂÂ†2†=Eéi0xFv]˜Rt7o$äg]mÕÎtänÖUíÎşš“22PNß½	lÄ–ğèê§
Gº„¦ÓYÑFëbF$×)*ÏC“é¤ym²GdäKá‹|R5sÔ‹'­øŸóñ¸¨‹·8$zŒ¦×ojæ³¹9V…uµ>9@JrµŠ%–'µu·•›œ­­Ojûïâ]ãnf-H  ¼õ,Wy˜fyØ!°o• @<¡é.ËïtmÒ›V}LàXéTüeÍ²š…4„>`YâéŠ‹ç;É3h7_S¼àB>e¾Ç°O"P8›¿€ºKT_ò5İlóÌörŸW›L¶I<Á¢¹\°$ñÎ”Áºsg·ëÿÀ¤„ä³6Ä%t*8jÅíEüû)áÜí” °êÏš‚¡gŠÕS^‰Cà«	æ¢¤cŞHc>r½"‡>ş>Vwãišô¥oËÄúºÃT£¨F‡EÑs=?qÇ¬C¬Ñ0ºßÎ(ô(ıÖaÇ˜æÜ˜<k;NfÈ+b ˜¬—Mî\]†ÿBH†Ï2İ£,…ÅŞñuª÷×gÙ&z!92ÔĞË³µ|óL}/ƒ\8Õé ğºÌñªôó;ö­Ş²ruÂÁûz!£kŞ<fúOXŸœô÷Ì_ÜEÄAÓ··ëDrgÂ¢ùq?ˆKéQ†îì˜‚,ü¸~`JæµHÍ)/D|‹†8”›ã#ûƒŒêv”É×Ä«ÓË°²§0–¨=¥v’\6ÇÎUÍÂ3²TóbÖ©‘B)3ËÔéNâ@Ø
Ôwg6	ñ¬å°Gx¤Ñ£0şï#Ÿÿ¦Šd
äq½pT-[ª¦'Gí™EÆ¤Ô©b}¡Uº}ïÃI+T/)¬‚DÀ†»Ô–š4n6+£:ŠÍçŸ‘¶ÎwÈÌ3ÏÖ?+Ãä…»‡Y"·n¶tkÕ—PÖõLÖypŞ¾Ä.sü-Œş­lBŞ0òøÚñM‚ƒÅÕ¥¿ùØÓîÙ…ÄÍ¹Év0½º•âı–×úæ6Ïu<SëÄ_9kU(„”Ò±ÿ‰İãŠÂ]×àk#Ö²šNÈÒÚ³’ä+úGÑ¦qœ³ŸC}KÉ(º9í©õÈ¨®®¤ì?«Y˜†0å„ïd	vT¾hÊ8¾®&nO~±[My=ºš+m<ÿÖ„—êàˆ§²_ô˜ë—~\ö
Ác­§’”xî‰•{W”­×å!Uà;ÿózg]û¬ºïyz¢Êãû¼@)°,HÓjj\ï³|rI¿¸%ğmÉ6=ä×²ºV¯ş!¬ÙæŞn·I²Ö•õöŸˆ#s¾Ñune]‹´B³oÃ“«vğöîA6:F—CÀ,’6úûdN¼šª”®itË‘2·‹Å¾¬ûnÚ±Y=2á¶`égSÚ“ÌQÌÔ®NÏ“\ì¶·ôòîôÎa­—ü_óî0!E-®@Zè 0f(jæ|½'³Âœë›¬ğúëT`‡@ì¤Pº-çÚöŒÚÅmŒÿ×öüÑ €1F¾?¤òRÿ•ê¬eY·ÊçÒ¬Rî'‘µxÙEÙ/’ˆV¸¼&ÄaüM¬ËÀkKˆúm¨»‡k©:¤dvê¬$ií™ĞY61ŠÅn¤$^”p÷R-À{:DŠ Âc©òbÚ¾¡}*ºès¸Öa×5°ËSëªÁ”’ïƒ2 o€ÿP`éµ¤Iœ‹\NèÔ…NB¼ƒHW
Jd‡ºˆ¸o$*…t«L¦ƒm&k¨tÜ®~xì”è«€ÛÊ™±‰÷ašqËÇa°´©åüñkLlQ”a%4jj…ô§x­B;wúôk€¹»té’Î{ZÍ¨E€UÒ™
õæÕ“Ó†R_Çô~dD÷ÊäcÏÂÍ«Á6C$XdÄÊú¬¥Ãëß kû:tØ†b#'ş¸6Ì¾qÅ#—ÃEX\ÿ®š˜æÍ@°ù¦åãu$,v¹¡w§?39k©ÓUBønZõyÖ`~tŒU*ªÍÙšÁª„+Ÿœïáå|I—ã×ŸÜ°q—ñúú‹­g5q°…Ğ,'¸ú×îSrWåu»}ø‡C²Ø›¼s}P£!e Õì£k¹3Ae-·kûS§N2±Íşh­æy-Å=m0À”éöÑWÓ}X¡|„|ØkMaX;w}»Æï¬…¥µ--MfÖ]›ù•¦õ&Önq½ë*
P©_MŠ€ØÊ&š°¶é·^7ü4«±ÿÏ¤ÃEÅh«êdU´úe !ŞW}NrË™ä°´rğÄlÈ}jD„ZV˜¯„k¨ÓögÔ“kµÍ™ra=y&½ŞiQ¥Ğ.óÀ‚"KÊÉ+\«‘uö?|fŒ¶{\o—ÈŒ1­8I¼Reëb5BúJÅ½,´NÒ‡»éUt”rw3ĞıÓ‚¥»Q |·	áCÄgâ·Ù•€šSyúó+˜6OZ(M§µ¶[şö!ÓÌw¦,ãÖıÅ7iÚÉåúôáƒ|‰—ëÂŠnaü]ûX–ëqÏ—Ê~eØ`‹Õmh_"ÖÚ³ÆofBÓÏæ×ºªü&PJTl£­ˆP‘qØg€yìaø9`®K–Û2KşƒR!€vŞ/õ¹?WÖ]†$	*¡ß\ œ2b™³±7“QÜø
urÁ¾úê3¾ÍÿÏçûƒ¹kÜ^xè¬\7Pj®ˆ»4/£ªº(ç‡PùœIOV]Æ;˜€§,ÕÊ\‚JçÊÆ¨,d`òşe™¼l¶{ØI´ºP\î1aU{¨lS>íÚW‘@Æ¤$vå—æ8^Š‘¯•iåÖœ;7ÌÀ÷vBO."GºHÀ/’ÕE ZTô•šnò‚–Ôx«AÃ=M+#'Ú¼ Q»x³&Q+\y¤½ÁÈ
…7–Y‹‰‰~^yÃHËô6AIé·-	İo¼:Áö’pù\®yö3D7æ¯qòYü¾y'„,@Rxv '. ­ÖEĞ»1÷~1S ’¤ÛŒ>|g(R|õ(F¢ÿ×:&®ˆË÷«0j7u//Qïq€§Â›"ÿÍºæŠêî?PÁ-j^-·cœâ°0åÄ•¦+»©æD·İÕ#öÄ7fır¹üìóùV&Ê±1éemË¶Z=.XTeù±ÓÌÁôV¢úgD=AÁ¦’•I|ÚFY+ú’ªÉRÕJUY‡Îë@€É?ó·]=c§âµ¸ÂÎ’R<¢‘ÌÂ8 *Š9ş‡¼ÔScXÑ=ÅºŠ@ ;¶êZJ€%¨Ö8UÉ¥Ëu´Š¹$¢u×Æ+â,À]È^³kÖOÈLÆwL5™K‘ìü§y)¶LÃ6ˆŒXõ"¼J#xÈF^gë.¥Bo“¼ßµ%€àINâş'…ÿ6z{¶Xëpë=d!‚0š
µ´.Å²WÌ‘g.X:i‰ ŠôX29Èç°Fü³šØ³r=vêšo‡YvÓ½É™;z ğÏ{Ÿë\‰jù[«0úKQ“¬sGµÂãh‚ë{ê’z¢M•§*ñu†Ãß¿|eÖrÂo©·º*àªaZz˜XÇÒœçÜO<uWû9,ú¼|¾ìi?}W)Ï©ÿös‹oÁb†lÕ%v¡¨dŠzo¢MPt¢Çò  |)AgÒÜße‡'Ü¶eçôjôØÊïØÌ?ü±:eğ81s¬]t¡h<(”ˆ+XØ§:•oó!4Ø©ƒŒ6Ã“–m­_Ê°HÜ¯X§T{[ÆAğ¦ù,oÿ¦¹UdˆAìÖtÓ¾UwNf]Şj”l[:»Lî<Iæ5¤ ©$_‚!´1|œğS¦5ğyT%,qWó0^¨8êİù»®2Bş!Öbí!àµ&†1=£$Î6×ßºƒÑi»0şŸ-1Ül!®…Dùo¡İ¨¯XâìiøhpMÿƒîœ^÷0ø±İy»ë|T®ëÿa<††Jÿ„
Êeı²d"µB©l“Ü`.)^;|x( nvº/ÈM#ibË¯U~wûƒ§e{±'p7™ WM¸ºjÃ–»—¸$¾ÕE"I²rKÌòQåbvu£Uºf…ÄqmŒxfrYfˆm¾ßq¢¥`ù®àğQI2ú/ Œ«jÄ¹àv‹"|×y0Á½ù¾¸dCw?ï‹\!IÈ÷²èÀÿ©ğVA–“7vJôÎh‚`ø¾ç—0 ZflGñµ“'Ü±®x5< .y3ïM‡Ÿ}v$™Pß!dIAxgz«Q>¾ñM­jB½>‰×BŒËğôvêa ŠÇYlPV¥ãZœ	T{ïÀâK¾Ì'dƒmUå«¤İcUrjäşl bò'Øê×Ëp³²cit9‡ÂuYN{4ëÉ|rK­×H¤le?±W…¸R o·¯­ô1#m-o3dr¥ĞÛSö±›úe L°+ö{1ó¯eRÌÄÃs8H!%ğëu1¸c„Ëq¡³wÚ©ÃI¬WözÒEÍHî kû—7Ğ>ƒºm;s—Í=~O÷ÓG‘¶gÖkŠ´äw˜:}pæ‡[¿ˆnô±ô&‡nÜ SËî±rOÛòï‡' ¹ĞEØ\ìà(hŸÀ6¼%ÎŒÎF÷u…÷Km†ôAİ.‡?µøêÄnM¥jâOø$dßÖ	(`ñĞì…S€ÎóÕÙ§Š¯EÔĞ&«TÄ-F³6Xd¤Qa²çLİÇˆÃE×Q@uh$'UÌ\à‹©
JGM‰¼ÒœÔ¶x,
ŒE“öÚ5j¨ƒË=‡ØÉ’ip`[”€¶½ŸA0fg¦É}Â»âí¹–hEê×cBÉ²ëó¤pP±ÿ¯©åµº;ÈªädÕ“_aÍLÃÚ~ykD–‹ı’‡6IsÂYhÍµu¼¥¶–åwÄ€}M{­$ !g¸YIå„UeÀ3“>ÏÈ\XS'àğT†_€ä¨XÎ¡e}8«2IÆvÕLı*ké3<e÷XÓöf‹=q¤Ş0–/'+:(ÍwOØwÛ»#b Ä·ŞÛß/û
˜Âäø\û^XÂzx7ßá`¤GìÙ¼a	®?ªhCÒL
¶–¦Q{”-ÖÎó­ÍNâà9¹ò§G¬d¼tÊÙé}à‘nõ¦Ó}…Ü¾
Ü8y«^¬²ÿ¶#úú›NP­÷°›-†Ğü?àƒx·4e8İŞ±ïBRnÇ5D«3Ç<’hÔBËÈpœå”jE%PRÖ'¨QşJÖ|÷µşz¿²mä!½,Š9æêúPé•ïôb)ìÓÄJ¢ŸK+l
7yNI<%›ãÛÛ-k7šcåÖ<´­
Ãdz˜VäŒkÕÍ¹
0ã­¤˜ssõ¤YÏƒè¶õ7}´Ô—9ŸF$[ğ6»ê×÷=ü¬ø¤ğ¬9[ø…ˆº‰løQêêv…ò”Ï|:@#ÀÀÖo¥>Pã9?Å¢/Ëa»]yÉ§„ı®BaßØ®,¬DqH²¬`d‡uã/tØ?ËÕñe€¶ [ªWFhé¥-]/T½Ñµ’‚HÓ =iN Ø{sÜ[,ÀÑ‡PEËùö¢œHÊ ˜z¬µ«‚ÀP›IÜüÿD·`Ô™imlr¢Çv$*òèÖ›*‡„B^…^İëÚJ«øÌ	Ñ„»H5;´”“Óc ‘õüGCÀÓtñ§KŠB·½s´6-•*™BI´wmåÇñ;„Ğ=\Gš
×4ÔèUÖ”ÈŠ‚ıa¨²¾Ba 2“¯Ò{@~İÁÏèõ'²~¡NI´QXX G½<­ô?\ÙÃp§É½Æ¯ Lr½W~\£Ât·FÒ¿uæ‘R™ÉÉŞnòbÉÉ1€Í;CÑò8‹7‰Sªç  9‘­ï"+#ogä OpÅ•:p1•³§JJ:ÀéGjºÒvHó±aÃÇÑv˜+[ï5T1èîa¯¶>ó„æì¹€qÌÀ„'°AóäpACú¿GÿáÿR9‘Ì‘+×!Çí0cmìéœU&™2¬ÎÎ\JW*Wòğx¤²’´ «8«ÖÁ>Ìkã]=UÑÏ úOÆ Ó—Zjû:€"yœ!x„c`Ñ¿1³(“rjM¯šÂI­ºZ‚ØŒâŞúšPúa/¦Á}t"^Îò­X¯ïz°î÷<İ³Ïè’G¤ÀÇ:Œ²&Süî÷‚!èä=HıO	­
ÂuVXk“d^ülãLÒ0ië†Ã =48qh…Èe`‰ÏXg%T9ºw‰màÛ\Y¨ÃDÊÇ­Á%Ñ”ù¾ŒÚs'”èmğÌ\BW8x`§êpmÅ¤pÎä;ğ®HÉ«YWÜĞ™
OóÕªQU™¹şfˆ¶RjØN´ÀV‹+ä˜$¯»4ï{O/½n¶?ßš:ëZs‚ˆ‚§Xe2QfÛ8Ôñ ŸÌ¨GIs1®9ªëAiÕP2ë`wŸ\lÑR8Ç”ª­‰ßŞ¹`-ùíädÌ’è‚¨”²Ã*èİû ~óœRîtpRĞávÆŠh9¹ÎÓRŠÒV¯Æâƒ‘ŠxHpö‚´ÿAu¼ƒñ[j1ˆõËºj•¥çkÈpG·*G©#ôR¢şÀjŒ´Pb›+=;­BiÏc³ÕWëZÀBR^_?­ø³(Â½½itXƒºëùÇKD> ¿İnËıÌ[A,-¬kàidíKÓèôÍvr©*aP]C†¾ç"´¥ße#{'àóÇû‘OÏwëû=)í¥†Û_oÙ0œÏı9C6*›tp¯>ıYÛc‰ü‹f©»D à‰ |oµ(0Ş·PyMxwÕ´eŸø]ğ=L”ö/äG‰“†—H8˜ĞTaº¹õ<l¦u`Iƒ]Šv–¥YæØOc˜EVuª¼¡J®:~$jf’Ÿÿm³c/I§E¡¹–C­S3Y©6ŞÑmşğQ-;™™5Ö[ÿOı«&½2ÿ<OÉB?Ï«ígÊÖÎ²€ªHâmÕ\ƒfÈ†ày?µÂ½V‘;¡uÓüU•9®¨ŠÌO8EÒÖnËØñœ5³œº]–~âÏÉS©Ìâ¯wk?CªñÆ^ÏäS°è=É^Ø;FÕ7¡ Ù˜Ì-Ÿ¿I†µ®1s˜^ßÖÇ•ßÈİüi ¸§£¬¼¯màõ´£Å®´ø§Ä¥f©‡ˆ7dÆÿ[xŠË9y#´ª)ôÑ8Ş½ovóD‰™R*Y VÛu¯Dxn®Ò†)éÙ©~|1/zpÜôÛ{Ÿß­Y­ˆºx‹C‹"ç‚ãîg£OV_‚bpŒr— sšõf.Ó.{²c³ÏÉµÛ½ŒÄœ­8nsAa¨øîhµ3Y3§Œ¡ ©`ÍáÄ¼õ™BYVøé×,ïm‚mµÕŞVòö'1{íèº­“U·çnkf¸}©ãü§‰yë-ÿ¾¼K}²f ú"éŞ]ZË\ĞV4cI-uªY  ì'{EÀ‡îB,”+oòGÏ­l«Òèøšó-<4en£,}Åá3ñÆ|ÚDƒõ”2)£Uœ›¶ñ³pŠ‘ËËZš¶U´GV&wÍü$³(¤B‡w~Iş) °Ïw@Xª2…ùŒh ™IiÕ¬§¯_
¦Z&üêëÕ‘šü@¤/(‚Ox­Çi? ¦X5;vEy,úBKŞ{N	bXdšl¶L—REÌ Å<¯Î·Rh·ùògR¸\	»İˆ™k
:½vùÿòı¸
ŸhÀ*±6_èëJÁèöùÉwœê¼/'4Ò&—ÔÆÏÿQ~Â%×[á¨^GzˆËGye,A‘ìFSkç6 —ÎKläÊWîàoß¸²ø8ÊüĞfxˆ…³A!U?\ %P3Üdºà--hL¢K"æuÒp©_LÆf
3‚Ê²£ˆrü:)é@PàSÛŞK´€ÿ_4æ‡Ö7ßA!,·!”^¦(¢@i ßñÊdÙƒRË¤&+qslMÈ¼y-$•xsï77£0T&6î§ğzS5§$ÊeÔñè&o?ëİÉÁøéùáÊb£ÊŞÔ¢~„`E±%–"©bÕæ¾¤‰Èù8èu
û…yx½yÀÑâİñ‘ôOYøö&NNB±6S=± :ûcªş ƒPò6 åsJ%úfS¥ÈÀFA£~ë:¼0Åó„
W……“°„b¨mÚpå¼k.´úM²7µq÷Æ™wa¬ßÍŞA“i¨‚Ü…^DkfÒ¥¡Aâ˜Åt4¢RjÙ&î¹C.NoıëAî¶şfm»²j›¯±Y¾‡£v¡­ß6Ùáœô‡ò­ÌaÜWI¼ú'ÿ¦¾¢L¨hr‚›„*õê`µ·ŠúMSÎBkˆ¦ò¹rªÉrâ›wój”H¥:_ ØA?2ôÿ
MÈ‹ÑÌ0^åóƒñÒ§Å”X ±üŠŒX]:ŞI Æ#vò«ÔÛ¿¡d”!CnèSw‚3 ºP2H¼íá-à;è¡·/øAØÛB~«ŞO~yQ‘-Ï:Ìúº‹ßYBÿ¬5    k@`©•^ç2 ú²€ÀŞ‹L±Ägû    YZ