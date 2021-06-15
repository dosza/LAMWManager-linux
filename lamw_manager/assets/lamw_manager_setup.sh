#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1440135202"
MD5="1ac774bd5a4c19c06c68dfb1b2b30f26"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22336"
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
	echo Date of packaging: Tue Jun 15 17:02:56 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿVÿ] ¼}•À1Dd]‡Á›PætİDñrù;‚¨qº«úI™ŠÖ7 @7jßL@SjüáhTmX†¢qCA¯EÏW²1ÑÜGuíxÅÔ #oxÇ÷.
ß	"°_c*]º@Ÿe)fĞ”N<O“x=Cîş=9+x•|YÖ‘­@ÌYZ-¤LI™Áp©–’öxûì"´m¿™k†®’pÀ«±GW¥ÔÜ…cÄsQ°½|L-ïØì»ZuIÏTx`bÇxÉ7k¶Qï¤Àh*ƒ¤A}!Ô‡\wÊV9ÓõR¿‚Ğßı%}Jô Ã´|gx	=PUó˜ƒY/u£n…Ç‚mSsg&ŸÌı»nä-‹Sl'w¶—3Ò·FË +/ĞôWŒG£˜†¬ß CÆ S!FÎ1¢H~Ó7ÿŸkæ‡èö-©él‘XõÜ_cgJ”l&¤	LıÁm½=ÒûIÍÒ±§ÀYöæ
ˆ"ct±<<Á}²ğš_ÎP…şy%v9ñW¶&ãÌ"{ı~w"ˆº_O\Ò•ĞÓı]{!u»6g‰ÎÔâØÓ/p°`æ~ª€Xâğ¼rÕùlÄqÖ´gKğûÛıäÜ>…²•æ^3´ƒ&ãæİNWô`›G‚:÷®q.y"Ü»sŠî.Œ/óJ(œAã[ä°cˆ¡‘ÅE\R+¢®õ\Fú}qÂÎ`PÔGôöïó§Ïæ°Hïk3µL#0*ß¢ ]z¡è¡é¼×ñÅ,¨@JÓôUÉ˜®i	ƒ¼óæ ıJvP½ÈyìtØl$äÒ$ûÅ€=ô	•·H‚‚õyJR¯~’ÈÆ7÷ò?;ü_½ÁÓ½éèÊ't4¡W)îŠÖõõ\“e,IP^åzpn
œ÷å³™0ÑWİ60í¼Ã¬»OË4½ïaÅè´·éSñÚÁÇ¸\w0Ã¡½ )æ£M™ò¤3&é°a°UŠÄõÍ?é•"zl0ºQğŞ6ı=ü££kÅ›øËz>újÅÑéÛÓ¹‰Åã¬"qá5yÈ¶Ô|ŸÃÃ½İ>11T0Ù?#¤Œ¯½yó¾FzBá§«Ô‡Ğƒ”… ½ìÆ=4êÉ2u¾ˆcûĞ™Î`a^gWÜµ&7ÔŸ8hå©å}õ".CX8‘D]¨}õÊí˜r!i"£É3™j…\ÍxL±÷™y³q£½v.[oÄñ7ÄŠŠ„³)©ù—!ğxèş0q‘ËÉvÁ½Ë``HC²sj_®WäePe[ôÏ•¤6±ÆAÑ%İBopM5]ï`-x˜ª‡Ü,âËµ–ÇŞ‡ÿÆê…íGÉ’]‚ÓñÕ_¶Ãqeƒ+TF {ÆP‡I²ôí›†™jâå÷%îñ5ÃóRÆ Ø÷í,ã|nÿ§fŸ3]–ú•GÍ'œ˜(ª¼.Å7iRJ[
-'Ô^Ô_
(80û‰zê:Ã6cÃ ÂíútÅa3ûÏqyÆšTSùÀ2Ík!´ûô·›ãÈî±H¡˜ PCsõµ^ó2V¾„!i¤òFé#œº6Ie]±ƒ¾©¾¯w/øøäÛ†Âf{JišåÖÂPB“Iì"F{/œı=éÿ€ÑeB£(M½^ÎÓ„DôˆuìÀÌ¤êÔ¢u( >,!)ÑŸwÄD¤•;VK%zÕØ“~í;ò2µÑÏfÔöz JIx`—ô+!õ>Ïc…šÄ­ Ğ½IÁ>IµÀ=³Œq»=îÒzı‘E2Õ1Ó«@!€ë©kMŞêU4†7ë©Zõ*ñÎ¾›:Ë;³ÔZİì‡I9¯ëO÷¬¡DúÌş˜I\÷ÇöÈ?¦Ó¹©¼Kù†Ğ¦¶åeš
Ä®<Ì‰"´šŞ£–½YÃĞÍ¢óùSTÓĞKL®š£6
Ü×rús3eá:S|…;šy¦[”äõ0JdÌÓrø•E~Øø“è×Ÿwëè˜šj½/R”xÔÜÙ‚âØˆß$è^\|?#*Aìî(>ºÉ¾Z!øÒ ½C1ˆ¸Ø„ÇW®/ÉM¾ğ† ÷/×x­TK×ó:F ]½®¢ÌsÉ¯›¤ğF74úÏFŞè€›ƒ=>¹DNxyH+ø¿2µW-j'ˆëø“j[º`Ğ”wíõ…èÌÑY«ÙßCĞ¨{O÷vÏ"£·4­ ş ¼Á‹ÈT[‰jM*›ïiÑg×K?Z;ıqÈä†Ë‹ˆ(Í&»/uUÏ
ÄŞSn‰‹õÊkõÅY¡£™…FïßÄÌ?Ñ=.¾vUl,BG¿µŠŞ¹lö"‹ü|~bÈ
_‡î¡¸ÍmsLğ}N÷1¶>bZÎİÅ•TŞz¹h{Xàİ_ª=!6µÀkŞÌî˜2=õ˜›0HM³ïèu¿êËö/7A˜‹61ŠŠKfQGàÔ“wò]Gó”q-…}‘+é7È“¯eÇÂÄØ:Vİ0 /<JÄ“(‚ß¿³äØhÊÃÌÅ3µóÁä_Äõ¼¯Ïrv¥p”Œ…ÖsKVëûíŞF'(Œ>OÀéñ²<´¶èÛ¯ÿŠ–®a¬ÙÚ˜ì±*-˜šËØîàètqoÇÖÚĞO¼Ô¼<Ó2H´/øfxúgÂ òƒÅzÎ	àä©qø&ğ¶W¾Ö·áLc.™¥“Ç<›¢w÷dªûCh~Ek[u$Î½	TÃ	™+:R+ğò^ı—ZrÜ,Ú†×
Í·7E÷ïÂ›«ÒJ4’®âe<ÒçU×QaQgÇÌsªîu83ßkº1îÇ~„	tÑtòRt[D_ÆFà¥€Nº¨Øıdm³ÂyõP	)f¿ÑİŠèn˜1`,tèGÜ¡µ28àh¬¡	‡3‰Š‡Ûıbğ;$—**×~p,À¶‘ñcK-_œØóè…´ÓäÔÈQ	€eØ[èWÌpdÿ
ÃNùÕbÑj·É2Ê²McÀ¬ç	qk
Ä"/V¡ÒÃ[â[Ìš?7¶[’Ü9ŠµœİõgÕ5Óï¼ËºZŸITÆ¼ıh,E/SLªöĞGÔÊÆ~ÇB³&´h®ï`^™—|ßÔ¾şüÌ¨á*#Ä%Hı`¦“=û<7şÈïŸj0•ºû…ÌìÔ›©÷D¿•G1æO>ğ®
¡@æ‹¶X]êeµËğt·\{OMe€Á$™Ÿ¥„¼‡|.ğK£Bºîvã¨L\ÿ	ûÔµ8KCï”OùwŞ¤!$üœå†r»ŞÍu q¸0PÂs½|ÃÕgÌm.Xa\èûcİ¯!Ö3G¹’ø;™í³ş^ß. ;H+BIç½Õ4}şå˜QşˆGvŒÙ˜m‹ç·Å±I“&UÁì@õ
{µ¬)âFÚéDÇ­ãÄõË1›k®%µ×•2°ºõ‘›ò/'8²—¡Åæ9o]4w6Ü‡P‰¸Ì“¯jñ…J[±»Ê¼¡&‰vÛ³µWÛµ‘ß6Œz‹éòÍúLhƒº”œI.ª­¥È˜,]@tTmvL“wù²Ô'%W-\°-É‚ıÜşˆ,Ë°Yb²;zŸ–JmagùèCÀznšğò¹Ø—@ÈŞ	Å\[Ÿ_âBíŸœèªwĞr&áŸäìùÂø6¥.¿ã²'sc¹Ã¿¬é%YShGÖ1¬ÑÈNáÄ“ìxQNÂøqêE¬qğ\â¾­ñT×dğ	Á%èÈ4úÕ¬°ø€©g™w5/4|ÍjUŸzyÚh¨ísÚØŞáÈL˜a'Ëvî«2$Cˆ¢ÈV
]y’óPyİ{ñ_Üu‡¤¨„â= )=”}w8@Ş•ß”DÜ·v
)xÀó ¹•ÆZ˜€ò´&b{:8‘ğkYLàßú!csJkË+FëUYK0u¾W4mej­ƒ.Ùº²Ñ„ç7®‹Oèşàˆ)ŠŠù!6¸M™Dõ9N0L.ğ9?´GñŒêwè¬ı	"Û° „Ûéíâ'¡c}·t¦å1É- ÁzøÕwÿusà=<¬ˆ‚Ï¦v‚½nt…ğ%áÖB›S¬a“ÊJM}‰JJ+¥L\ŒÇ›ü”€¬±}<»‹íQ<£®é¤Œl].òMQç¢)³]«¬?œé/¶ş(ánÎXjE4Š©³òGSËÅ¢G\Ù@¤«°ü/Š·2~|‹¹[@!lÂÌH„Kg®Õ1h÷#7Tëõ³™°n¿|:Jºo%ö[²Zó@»e…£S=ÄÉû°‹œ|üˆy6ïr®âÉ3ÉÛ	ˆKŸ¡q˜;Tc¾€tì¶FÜjá˜å»rl1)[Şä9Å¸·ÃIOL§£IåxÀŞˆùv[ÿwWšw÷óÑL“şëÃxIòÖ¨~BŞÉ*S’Xœ2Ç2 Od ´Âª,êÁws¯)Imî6Ê\OX­î±Jƒü¦èÉ‰Ebá¢¥–¼`B¼KfÅIŒ–"‘%É×2i½sJ-É¶&9îšë<i¶ÿrÀê¼l¤Ü©)…5À±S~q_GÓÌÉànKı~kÒÈò¿œ|ğÌÓ8›£9ÄO(Ám¢¢”ê=fVv¯f.rOùCí¸™÷ŠŞà´Šàå¦ÅPÂ<	–ŒÄÒí¨qÃ§ø“½{¦I´Æ±Ä'óSw6®–×fëÜ>Ø(:'mö=ääÅËØ¹M;_ô]<U¨ó‚™}õç æ=Yd0îTñ¥=ŞÁÈ™[]9B-]5éö[ŸuÖÄ—ŠHß|#œ×µïOî*Áò¹irÿBøtßf?vÕÂkWĞjqÔE¨ºÂvDù|è|OıàµCµ¸¯QÛ—›Ó{é¼iu¨ğ–÷b}á27nHVriëñ˜°;VÖéXÚjı%ÈH‚0¸ß…Î¡bŸÓ|3“Ü©¡m²éb»â
Ôkú¢QÒOV‚ÀGO¢ÑÜ-Û÷˜VD>!)±£2 ×úÚ–!iN¯zï×Ñl!lmxÈŒ0¿ÅŞÀ)™‰@fro.ty¤ÙŞ*>GúÁòbM„2ò@û{ôgQvê§ÅË‘ÿ/£«xöŞ(fgˆĞÚ*Ñ,!¤&¸Ë^|S¨È•;ëA	\·@I+«%“Ø©Í€Ë©wÁÀR~ØÿóÚ«øå*„°zÏb¸CÒ2sYŸJ¥m‹«0¾	~A±x²ÆÑp¿ÂQ7ñb¢ÚÔMùŸ«qŒùN,~Nğ“s{“	Çv¯`¿ğK—ğ@¬9R–}aq3B:Év€ƒôƒş®tó9êjü×æŞèğÍ~·g’1¾v“?rC>F gcÙL!¾Ó_ ü´9ÓrM9ñ‚-³cA5•Ä¹ŞA ¶4ƒÀ›7·c&˜vQ¢à¡È´iÔ·*¿õ|Ç@ÓIjíŸ—=zM’kHY,ŒoL+½XôDlıÔ{XmcCpô§ºj®{ùÌøÊø’ÕiÚLnı…†İ†‘jËoÓı÷¨É€PŞQŞ	„	ÁOÃ«Œ,Ê'Ïmç°Å	‹^µîæ)/ LjrÎK¦½¦óOB€{?”éJbË$‚ÿ©ÔaXkB	°lé²—7êTtÖ$Şw©ºT'Ö?¬Ê®’¯
Æã•=™jşûù&–EtÑs+[ğ‰«'zXBóF\|U¶'ÊÚ}eCknŒ¥_ O›8‡â…š^÷êàLç\z9n»˜a_7;¦Õ9$SzwÙ+xÙç1İ”4ÕÂIh”Š®uéÄ|§SÒ‚;¿^2¹DiÈê|(ã¥İğ†Š†R9ÚTüœÙzAMòP—›`bàri®UòH&ŞRğ·uŠ°FŠ± Óú[CyÔtPÏ MëJ«“cc-Ú“îoœsoÃŠAIÔ{:(HSĞ
#LŞgRÄ½]y¥–ÇM óÀ'µ³-hZ‘.fãG¾¡\İ´‚ÃZÒöù~Ø³L$¢Ñk‡¥×Ô®Iéö”Ih÷]œ¦,øê¥Y.a%g™ áaG˜Î—ºõ.÷Ä„›kh¯84Øëş-Ï°ùBÄÈ›Ë951Ú§ò¶™Z‡­±„oú¦ğæ²#;ÈóŠôÜôÄuxL»‚Èøb²%¢qhÂMx-õö¶àV.¨Íåú‹_ÌÁº¾&Zb Ì½aÆ'®’õ"ãI‡EvX·û]ÊfÄ®‹Û?;í5TÁ‚8£g†‡\x<3÷ıa^¸î¼7+ZN½}Ò2¤PÙœ\ª	æ©rÿD H9¤ô.dŒ¼œH	iÉWJ9à¼&ÊÓà.
Pá‰¶Ü3˜Ü¹f¶¯OöŒ½^HBkx7İsTn•VìıíËö±“Ãy ®‹/I¦¬¾£P Ùñ)§mÉÔÀNÎ XÇÁ8ç=yÒß{DÜ#ÓêÎÂS	Ò¿lzˆaÁY5+¾¹c«Æötœê‹€Ó1¤\Dÿ­ö÷…ÔZ´ª .¦Œ]p|TÂåü‚{Ô^™Ğ'Vhd¸’;'TßF~óÒp®(÷w/º@´ör ë°g·ºN	…å ySş9«íÔÂÎVÆ_{ıªäPS×gâ·{’øíğ$©ƒíëıpW}öĞ#w´[zŞ}-"<§˜&Ì`Yalˆ°ã-üú¬vÇ+Øtsş‹á4‚†—=ìklÁçÙe,óMú«Sp*SƒªŒ˜·ÂW× Û1qİä,ÜòÛİ§/2cÑ–ÙÑQD²‡•YËá§œğZcüæşWcd xzO®'é—H»æœnûÇ„L²oqp|pb"J3Şª+×ek+yC³D(šµ^ufbV]r?î²²PÊ%¤".„³¸ˆ ‚&mÆ[]µëêS¦ùG-\6ŸÔó÷´"ıjj~ì¹G6xÔˆCvˆ+‡i;¯¢B0½pC$´øÓª´FB¸@>:²ì«è‹ù–×ïJ–I˜~WhPæãœ«¬Xõr¬²	cIÄX.€Nk"u[RCø6ãe•Ïô¬ì[¢ô0T¾Digôí¾:Ÿ‰S$JÂMÃ½Åò¥ÂÏ†JÑh„W¢4A®FíeÓ!r£Î8@/ ä»—œ·Y@}CÁqtM%é}}çíºŠGí—h¯© ;EÀbíò
{›#q{?ıÆŸ˜xn $,÷×ì–ÅËY„Ø„™¢ƒN£'+¬¤ÏFaºÁè¾€ı™Rí·PcÇnĞ;¨Ñ¢¡¤kŠÍ{£ª‚<EHœT*‚Ü¿×#1:qB}Ì[„:Q=·£E·°ìèXÛÌFZ#:]â·ñ/RÓ0»y’lj)›::Ã4l9D=°R'n]zmÿÛ1{áÜ&d½¯‚Rİ
©Û
#%h3Í¨ŞöÒŒÉË\{İæåºÅ'çê¿Bè{ó¶[Ø,ûù~°s`\íÜy°ãÙg­È[Ö¸eÊjï4>ø–‹Zp/şrª!5§²L•„#æ®óóñŠÓ‡GÌ7‹Ä¤LRYïµM®İ}¹$ŸYKë|uyÉ˜âî`/@Wtáœ¶Ö4'2cH¸H2TwàÕ)Ê×a½î×>ÿ¢õ™aŒÙ¢rÒAÏŸñÓëÒ‰àú,NTß2…ßãÃÔ!ö÷èõñ{±ŞfÄà*{ôœ•˜I
WâVºà%Ğ‡càşHÛ'à@4ş§ï})“ğúBÚ5[~íøoe÷m›nÄXBËŞn;•Ú¥ngUaŞä¹7Lüo¸(/JŸ9ApM0"¬¨âªÂTŸ˜ÎõG"sÒtgâ¢ÜÄ7ë¹MĞ‹„§Q<ò7ZøK¿Èô¯AÑô…¤±"c/üÁŞ·Œ¡^íUI·é¤G±­ûõ·ÙKËr$Œ;J§=¸nBs—UbŞª’T®–şö%³8Ô¤Ã^µ‹I¦}ˆ°à¹ƒÿ*Ä6	U&<øx±Ÿ–à¥ÙÒŞ$Åë¹ÅÚlnÁš•+ÏÏŸ³„›jcÎÀyömÈr<ueà%:z2š¦Ça&¨X²´Y­d°6ol¹òôoã•ˆa=¹ÜÄÁå™¯|­y)Ë–Oæ¿ÁÃÕá¦D -ƒÖ˜ ÒÜÔ—‚“2s8®åÕ“F8™µa£¢9ĞpİEƒ™Â>.Õe,ÂÄÿ P,Ìt*/ÎÑá¿ŞÈ*Acr‘âŞåİlê%×0f¹wn¹MIÙ˜3¿*!8¤_˜êù:1r™Å«^ÒÅÆW.fm7½úÓ%DFg#¼İ-q—´*’Yí
{í=¶ìQmp‚‰Fniä’ }Mœı1¢–^QÔl·ø;2Y[âÃ«F–<CÎwµ¥?’¡”3IÅ­ˆ°¾Nªœ„ohGç£dŸ\7L†0éÕIpZ‹µÜ¤ıœ2‘N
qIñ¢Ç½^Ÿá3n¼óE}Ôè
P¿5Bİ¨Ä}÷ïşpÊ¥
*wíÜŠÁæŸÊáfç|M¥­(JË$'õÄ8Ò¿kã¨å (ÁÁV¾elª›ì°æB{(¥QŸ¹K^®Ñî•ô¬ª@;tæ?0cï©„â²#sG™XöùıÏÓ8Ö+G=ûğJ€˜ä=ÔªÜ–=‰bñ†Líu ±İîà6Ì•„G™ñS<.ÈÁ¾-8^E½oı‚M0=[½:Nˆ$á‚PWñ‰ÁĞãôÄ=?1Ša8)Â”³°çkM%¹Ú–'t BsÑébçÒĞiè’Tô€v7¹ÃsÊ#ï]ŸÜ ÅŞf˜cRÅáIt'ïm>¹8Kšéc¹+Õ—A:¤re[ÿ˜>È@öÉjUu¨:hÌg›ÿZi]Pf_ÒYimÅôzL–Ü_¤ÅbQú?_"¹\¼—»(•cu½L§D”„I%Ğ‡J/)§Ïgô8a[0o²Û/z½–¿?ƒ	¿9z¯;¿—€í½Tİ‘ÉäÇ@Nx›5âÃ¤`3ÖÛh6(&r¼y &câñò.ÚİZp`tôà;ïM¡œåD‹·Û‰à§ÙßÚ—¡³´€”êx½_
3Ä-yLäuI{ğL«5µ¹°³‚ã i/.ìsefçºâÖÌ)2i‚|2'ñ»ĞCpH\/l3]•lôs~îÏnÆ6&¢(TFíÙ0 ;¹/n„¼¡İ@°[˜º«uju¤¦|üv×¼o`ƒbÚô¤Ûí$½·ÇéR¹œ¸Ô?\¦ô÷…PqE3 OŸ0Mh!®\ö)b+? dF Í˜'Sâ•áZïDi–7R«ïŠvƒŸqœc[ª6\ºs•ZôúU‹õ=û•…šv‰«hu[±O¤ @÷“î,6»5°è®;¾ëT°–‘€œÒ*
U)Üh(M‹ V"CšîSk?m8Uè3ÄêÈu’ïĞç¦…îGd MÇÙ%S)7¾İ€¨¡zÛÆòêÕUiì¯ôLÏ>å:4³ñ1İàæÿÏ9G”lD#Õ~¤¬dù~Qh³¿ÚHÊn:`–«x=lªq€T8’1_4”·^¿ø¬Z:?€‚`—Jh]ãT
"
W¿“W7Jó¸¹ÛÀ8×3hN=Cz`7Áæ‡{°.N…LõWEHc¼zÚ$¨‘AâÂ®®Eo¯jÈ”îÖ‡{ÂŠ5(1)´İpå*)nÏ1TkD˜ôÑ)ñ‹»v5réÂòy‡’³aÕÃ;…Šp¨<˜c<NÂ€épƒÆ¦&ÅÑÇZDÖe 7
/)a§`Tr£ ÃB¦ˆVÛ,cpÜ«ùo|çQãÓ¹×n9Äm¼JJ™#}::»™ZKä«¤8|~AæyUouèĞ¦ıÇáÎÉ_½éj·{)ë¤aâD1Üïñõu¦‰è{¼üÈë…áÜgĞ&265²€;ĞUÓÓ%n,õš~ÉoÑ-!M²“Í~{›N¤!¬U0°AKtÿ—Íªğ_Şœ ªH†‰nW³äM@,ã^1ƒD@Ğ+æ´ÌŒ? >­º,z#Õ@ÌKÂ/q©¨à;É#§·30es•K‹äĞdau™§³jìaB‘¥ù°2şó³¼õ7Ádjï’QÁËz²¾°ymã“ÉşN!(ìª†Î-eQÁ#®ñÌı¯ê:¢=}u;J/˜5×GWTış /øšˆW›¦zÁƒÎ‘iƒmBìË5dKÊL’çš40¬ÊoğUm„~7ıOeİøWkİ„'z›—‡×œÏÉ* [È£0^¨
i¾5í¤cõˆæ3¡Ï¨ÊxpÃ+ı½¸ gœ·CÅ›ë·'ZïGÑŸâDmL^8è4!¨!) ªsğálXÕk•oÕéëH™z
û0¼iÃ…=iÖtÁ›ö¨Ğ“ÛÏ¢o.N¹
 Š3Û5Ñàc
†<®Êq“a EØÄÑl	Õ¿T?ô~Åmı—åµ)+¯óGN‰g®§®8ìµ©;j9n;îàˆSxÿmiÕ…0€6Ìç€=û?üœ#ÑºR4E¢Fmx7á§NÔ /À;ìJYÜ'íJ «É?óÊWìQ7?¸È/@Îœıì‘n¶)ıš9J†öEØHïîL–‰İ
;jSY‡³ÎóMÒn2cĞáF>â0P~5É§víG«¨ñ›Bjò¯1G™’˜Üœê«Î÷¤Jz-wŞ#NZ$²còËì²¡ÑµƒÚú>3wp=f8_Ë˜TpÅkŸØI-«…f8£¥^Æ®ÆùéVğÙf?jSàÇ‘›ÕÏQ›¤Á‡ãÂ˜ú#vw‰¯¥4µÂíıˆ#~&£ƒn>è·| Â3"“™<¢ìš8·êç’UİØû~Y´ˆahÅ¹Óôè¹p.¯hò«CfCdˆ¿÷›ØƒI¾n`fh|Ÿ™VvŠ»zx» pì})”ö|:;Ë«_Ax¾÷(
 FÚ•N¾ƒşnµòNxK£ña„"˜$mÍp=ª5m¢³5şfÒ9êş=°iN0,·9üd¾:"óH3Uâ–X›§]`›WŒ½ cOª_÷ÓE¹Œ …Ò¥.Ûnc¿×ò9TÍšİ\Í€|¨såi
ĞHJF)Bd)W££±w!¨îèiÑ·Ó"cQF²TëÆ~©Ó	µËì sğQçMMP™«–ÿÏm|‚VÎED‚y‡ã¤|7˜qğ›ôìJ$ô9\ö'°RAoù‹Ò‰…”MEÇÍox®(ç$¬À„ƒÌç€…ØUµ4ó£¶ÛÆüõ\œN1´°ßvù¹P4Ãş¡€<«­"{Y#3í?ífj ix:ÒO
»òÀ×ú¿‡µ‚2¼õ­$şÑq1ÖªŒ;cBàÀmgô7!c[/úù¼p›Ç?ÛxûdÿhØ"E¹KyÂÆÎl“Óéx³(^Úé@©Rb=,~¬®UãèóÉ›Ys^®p/‘~9b‚;;_´;¢3‹BóEÂ—ô=«ş«¬Cxÿ¦;îçß4·¦¬¼4fX‰û•Ÿ—­\—Æ7)':Fw-}gN†©6Ã•@ønD<7Pı_ 0®pÜ[®ªæ!™şáæ}K	F@½çÉ*mê
àçFjæDó†5ç‰p;ÕÉ³„DÔÑ^Û¸Í÷•ÛK¨I¹ğw§Ôoªğ±´ ò÷!EúÔĞ2£lVv¹ÌÒÊ&ã¹¥ïşÅ¥à—Icˆ9Ğ¾†?•h:X-æ”ºæ®¸LtÚlØÑñ»ÂøÆ2»÷k¼ÓHü‡Zt…kUe”ÑJŸms¸[bOì>¬a÷ÙYĞ×»üg9w¬‘z*7¯œ•àRÔå·Ñ™d'¼	İœ¼…W&¬¼CdÃÂóPe1TòDğƒ¨ƒ2=g‰Üâ0iGğ‘£‹ãe>ÑĞ¦RÄxçQ«³J÷û
é•Ëu·­Ü†Èø•Ø•[Œ¸!„<öµ\\·âù6¶…–lğ¾-ƒ¬q!×_°¯KFú“ŞÛ5uq°M9a—ü35ëybœ&2¤oÆŸwuPA‹½ê,Aˆµá¥ÿºòW·¾â=˜fÊ¿ÓB ñ´ÿ±î#O1A2fªQ×ÕŸ>ôí*gØ¸æêk<Á­ª pÌ¡ò©éXuÅË\ö´-Sƒp—8‚­˜G7¡†Ì‡F
 ºŒştƒo•nÓE+«qLó®Â@ö-[ñœ=‡;GáÚ‰áx*‰ñøÎœ~Æ N˜r_Š™·é}JŞÁ8b
‹*$ûà.zÕšå'¹6NĞ%äº­'C¶¡8a
lt¬íWÏom­òõ VÖÁ=æİ9Ê2Æ5e4õ”éhC0cm Ø)	hÛ!Wı#e…)ºåŒïÇsôªğC=ªäS=.Hüáo*È[ß±"6*x(½5‰`Ë:fóÓO™,fÇ8-Ç†úÀ[³;æ÷…ƒª:]©5¿AĞtz9¼Ç<„Æç½Ä]Zt¤¨	$æ”Úƒiİ0³ôî±’v¬ô„@Õ&/Óç¤«˜¶)‰Ù
²Çõ¶¨³»3(ƒ¿óP9ÿ>¤åÈº0wğ9Ë4;¼şñ¦q]Â N >KK‚Ø$“‡òw%UæPz®ÓGìkò'”´³õô-mæ_İ8dYY&­J³fnÉİóEôõít3®+&‹”Hu‰y™â’Ayoìñ$¸*šÍ |ôİî6>©l¥£!çĞfË«ußwÚ6ÑÆDµLeUœ©ÊW¸¥Ê%&¨Ã ê™ñ”á‹¸í$NğŠY³zè)¤Œfº`)¨‘ùóJ™ (¦TohÀõ%kHúiJˆÊ;‘8îO=ì'@95F^‡Ögù„êİü¿],OìBavüs˜NZB`¦\«Dfº]ãC7Ä³i
~ ¸÷²S«°ùé»ğæ¿mœÒ;U²m-|cÔßZå•~±#wµÇ¢E,ü>ñ:5T/ğÛjI?9xÖÀi ï´éPëé½Hî¤9‰ 3âLô½–íõ2ıÒ–,T‡mLÙ6Öÿ®ßğâ²L\Îğ\µØ¯‹}¿º¡rcY;hóŠˆ€ºE,¿êY{ó+Yw¥½D,x2Ğ$ÂyöN?ı…¶õ)	ÈKßl*Ë8QTq™Z}q³4€Ašæ$²vuvôî*KÓÚ£YCç\b3W&hÎøô8ß;:ºÈS[óÙô¿ç“¯C£±&BÌïHDés­ùFòNÉ%s.X#¹òV:!@xäçv?<\¹nŠy1ê‰.˜.¥ JŒ}gİ<‰f¬bşí›tËW¾2BÜIÈ!;,ú$€H`£‰½0¨£’èe¥a$ù ÇÓ¹‚bå\‘Ñ°ŞÊ ¾ ?BTŠá„²|RüNåZ>uhÁB‰·Ó'pw±Å½Ù·ë{½S†3fƒ@k'™%F†í.ä¡C¸ø²¦" 
…××÷ÃD2HÙõLÓ*Î?ÃİQL-³N×€ç¤J!T–ÃSËãšÎP¸–E'ÓZ¡ünú|¡Ó¾±=ã«Ğ’p$ágŸÆ•J×H¹Rºò†}zÙ®¸Î	FL
Y7İ¢¦x€|÷ãŸC@JS95­‹Bc§¶Ö¡;6ò`Dñ´† I›’Ú›{‹3-İt|u²z=®àÕ³Ö\Ñ9ÏWŞ ı¬ö³Õğìâß2\½z ,DÒïG@ïBw(:‹¹œÂ‰5ã>Ámóä1'±	ã'•‘Ö°üò—øïÕœoZp×>S*¸QÄ†Q36ş®7Q¯;ày´¢	—<òÄZæËoñãLA-(%|j7¿l“^d=w¹TFĞiÑÊÍ\˜Å„ú+ıªÚò¿R·R€&ÏóD°<f½hQ ¯X2¸í¸>yôkc1tâ€û™ÙLAªˆµÆ;İJ·¨	²˜º23‹SrH¹,‡Dü”89ôw–•"sd3+©„¾oÙ¥Ê#ƒGı=ˆåu9–Z£œ¾…2*œÎ®ñ³é×õd:V–?56‹ˆ{¯êi—]2İc=IÔ“Ç¼‘FñF‰$[‹Kæè™€%Å•3q¿ú3ˆÀ€3O%°Í€•Şš‹ôĞåİT´< ïø£4T±8aşR‹«x|hãønQ±¥0îñ´"‘W¤5Å™•Qï:C
\|d¿S’€ã¯FUn{*/¤]œ"¨'ıK™›ÄX9Î3©–ğã“·CşÜÄ$Tc‘ö“—YEŠõèù%,óŸøÿ ±†ñ~)qŒµ¹oµoÁÏ^‡fü"³¨ï´D¢ 6Qæ,Ô5$2Å–H})L¶ìÕÏ¬bÔ½]¶”ä-¬Ğ)MÉËŞn·¨T‡A‹FIåqÆÒ›"ó{³í£ƒĞóIâ¯wÔÚhäÕ{÷íc&—İÑ’‰¥µG
±=“#£Ì(Úz³úØJ™úœ­lĞ7~^¾K±:‹âìqË;Ø¸­RQ•ÀÏj-<
7q4úH¦,`¥” iş­mg*›có_~)¹H„½@rè‰6©ˆ·\1É¼<Y3ß …$ä·!$¤èñw“+wù¿ğïÊ®×n]Ç÷>€‚»¢İñ	Ì]OŞ¬c6ü¤WBr‹‘ø¨?]¢!Ç/Şƒ¶ôÑ	«¦Ê(‚I°h•:Ê!3éÆâ1ç3ô>@Å9p¹î8Xt-ê{<ú	‰æ§Öş	˜ªÊRW3Æ6ÎfI¿Ş|nó/¿9¦¡_eš9›²MWv=\# Y¡¤,]ÿG5	EƒoµÃ­}ƒjıƒ(SòVHFQ…D¼GÑÒÁ)âFÄøÍ¼ƒ gv'p,g–.v¶fŠ¿õñc@ÿ¥z øFhÑŒ¡ÈIw<-÷1O´s^=ÛÌzÎÂA@ƒCzQw»†ÙŞ?‘H]¼Òïö´ü)¹‘Ò|Ts…Œ…¬éjp	Ãor“Ï¡Ï‘B9L‚Ï%xÇc+LdÖ]'ÔtüamY|4æJbcü ‰‘7k	¦Ú)–¬9Ÿ¢á`RMŠÈ[Æå>PW£¼C¶ïô˜ÅÑ_²záÇ>)&UşŒEÈbüÃñ#‹—UoË¾ï&z^}ëc,²Ì3õÎŞ—õ?´;x>
‡‡×A³7¿	?Âe9fÎÆ_JÌJ~ê§o…Ÿ©]í5ßé“àBw÷¯%kŒjâ–â9Ğ_bš:Â>¢Gb
<ë™»Š†!
K”ás+½¦ªW3„ŠëµAàŸšCa“Ü nİºÊU°$XMƒ©=¯ô÷¿ô³yDZ	í5%1—UÓêèƒ4t×"„·bkÆÍP(Á€"søô‹³2Ÿ*xr\ù–àî—iS»1Œ¥Z!z”+Å`†:¿ŒE=(’Øş-›v‹€Mrc¡wõ|²h>ÇaûD)¼ÒÑy8y9’‰ñ#º Ç«XuîâÿeM©İ‰²YÀºyª'á+xAk-úŠl½Õsg¨¤r´*üïÈÁœÌ	$ÖœÙÎ&oÓèß¯5¼Æœ”Äh@†
Ù®Ô9¨âæë½,©;°QË/˜8Ri¦d³H„^¿§ú¦S©q°“j~•ÀEa§Räù¼â‹Mağoˆ%KÂ,ÁYDµgÊDVÖ•£2p÷y½ğ*Põ2É¨u’V„•Àa¢øÓÔ!ªî@k~`?µêÙğ%Ñ…{±õ¢³UØô’yæ~NPÑ­Ëš9rOtlsgúÏµ}§A~ŞÉSn6H4ºúm¿—™5ÈYo5ÜÚ²á}‘ê$ÂoWdI¨ÄËš/Îğ”'~Ğ]
R’°ërJÛÖ*7ëI,v{å0Í)3Ûâ®‹‹+Jfêö>:z»û^±¨Ü\sj4NNœµY*/Aÿ§æ°ˆJÀ+²ˆó}æF9)¼4}¤U•›Ì/”ï88c
©<äŸÈ” \ŞüzIãİÁpaİç/ì³œšà^•Àôİ G? ÓŸÚj½ËpÇü¬¡g8G+¬ÚÔ±d.2ãTa]%
œ4[(KqÄÂÙTFpaäÃÆ
b´ÿ<ib²
·|Xò=‡¼¢°Šòj`K¥W ÿÉ]îÎè§ºÒ”Ö%nİÇÁkšñßğùh+@×P®â<çÍw¹ù}Ö¨ÜHÁé&0Éïş€ ^
ûLƒ·\ö”b$¤zØÈãÏÖ'¢ı^n•yól¹ê³q«ƒ>Ïi“Ã<'‹ˆé}K/DUD5³…Óø1á{Õ/v'ò²ÿÍÉoîdÙNïÌháÛ°Ù2~œ°$"øqúî¹Uø`³÷iG4®ÓwQĞkkË9o>àË€ø>©Âxq‚G³ ]`˜øÛÀ«]Ú´è¹}¾@EJ•ã%w-ë!\c«OÕt¼‰İ)Çâ~6ÉÙ4Íl×Gæóú@C³Wjœœ-géfãÕdÿã³,úìë H=`˜l×>9jÿ•‚Õy¸‰…«6ZİŒ¸ÑL/[³+]^Rœd®|WZGÃòGè?$­‡8ûü²÷‚ÒİLa¹©jPI×†Ê+aİ–}ZÀÔCd*¬ÚòŞÛ3ÉÒ}ğ¦¸püÔûì`Ò®½¶ÎŒvzQØŠ‚U{mnQA¥ÃŸ}ïƒ$·ïĞ³G†­%øSÂnîÎ¯”ºÄà(K=şb,?ÿUø[4:H²DÜEvNíéÌíÿ~ê¤{€U^˜Ä¦øFıã™c«,Kí]ÎæËUîÍo%ÁijÁ |'mß£zÃsÁÌU	>ÕÄ^Q ¼Ğmó~½`æE°€‡g9=6êRëéµØ¥–Œ•A»\F:¹y(
‹hÏÙ2[.×š—ZhË»–™¹J§¿(ch0ŸÂ-÷ñBÃ¢ùëOPyy6–,2ûø›şY4<fºÈ)›ŞıĞÑf1ZKA›{oì­êïÈ·HSÀgçóÌ¼²NÉìî‰­ÓdW=Zseíİr‰O¶¶ÎÎ>”´èTçHƒÔ,bßdãÿQ·wxGŸwp[ã›¹Ëlÿ£«ß>XÁ7/$Ò2$o“1zÅ=Ö•‘—n1ášß«l€ÕÚ8`Uš„sòÀAYÎ;óB©ş†„¤fŸÈOLÃè!  |P7ÕÍ€WÍØªAµ—S–ox™ùÌ_¶{¼G„m³,ƒî¥†ebÙ\Ö‹[éšÍòŠªHá`fï2j_—Ö»TŒ­:OÊ$ä

ıÓt¨‘^’rãÂûG´.n‰ãÕ?^è—¶àµ¸ğ¸ğ”%v<3eb† x»´>±0m@»ğFÿaMĞZ:4cöşewLj9ÒÙK%é7JƒÙYÊnê#×Vµ?³œ.œYËN Şóß!ò¸©NfVbø[®Æ|İşÃo)È}îNõ‹*oæŸ6‰‡>ûM”ríx‘v?ˆ ™äbH¿ñ)’UªJ~dk§¨ <Ã	©JvHw>E?‰³(Jée&0Ş=¹Mmü]Âú)?½XÏökôoIæªCeæ:b˜ŠW_=|æá²I·ÙaT!U<öÂ¼wİ”µ+øR$ùq®x«€•Ac”/"zÄ!.Ì€ÏPÈ ,‰ÈÍß]fE\uãøm^l£İ“z)2©}îGŞ»†ËM‹)ËoAñ“@ pƒ›F?ãòŞ½úà¾íÿv!³NX±œÒ:Ö°…5®iÖ9æu™îl&íüŒG²ikÚcã$Â„°Kı¤É×ä¢^l­Î T…åà~‰sËq#¾aü>äñ—˜B_|Ü«}ş•ãp$sö:í{=†Ù³©ï2C±\CdXİíS>øBPŸõªáæ‹ƒ;©ô(Aô©³ŞÕ“{„µº‡ufİ|Ë±Ä¨Øİ{TÒÛL°©¢ÁÊ¿g´Œ6ÉÆ$fõ™a›à(OØxØhI•BŒÂ²ª sAaJÙ'‹š(Ç:áñ,ÚH‚“˜å'6¸Å±Sš}ŸxTr*áB»ªƒI¼A9×Mqü{Ÿ.Y¹á½Ú/Š:á–¦Q§ŒåiîjõŸQøg]˜ıO4ÆÿZ–ı²;ŒZã¤ãJÿA"ÇÚa©UÃÅ4‰ü<—|a²&€§m†”…åPİ.Š1Â?•bz°éà¸ùå—Š|ìÖaÚ/$e·ı‡ÄXÊßKÕ˜UNØñ4g;_V†" aT|ÄYİ©"óèìMßŠ¬,èX<êC
Ì÷Åo¢Óbët+»ÔóªBÌÄ8RBÅ‘ñÉæµxônç¸²ûöÕ»áš¸TÕÌã‹âåÈØ*%fßmò[üòŒ0ƒÇÂ“ã‹L:rè"¢ôQñKì>ãëêÓ?Mw„¥ñE#+jŞ:.‚Sû¾¾'ÓV1Õ’—ÿm»4ä¾é"7¢Jñİ×M°OI 	9ğzH¡¤Ğ”ú]y‰Â\‚¢ƒ®ÈIFÅ® é3õc¸Šœõÿ_Rïà×	¸È)Öæ[|é!« õ;D2‡¥"Ô<†}y­eöC¬n;|[[åàKBlbÅî¯§g«3ú¬ÿî€Ü}ÓÉ»³NÕá:W_¾}qµÿòÔd1à³ƒN†–qù÷[L¸qíşäï²aO†”¨ŞÌb¶!ü×¡pëäáÔQ}Æ†8z ¹ù^Ü~è®ÅÓÊrx—ÓgjŠÃìq/
O—®¶Ö3(E)éİŸHµ¶)Ós„¬-DÌ¸‡2Jk!"Û°+ù§ğé€„ö2Ø¾0ÊULPDWa‹·Qı“¸Ÿûõyô1£‹»(Ü€æ† ‰ÓÓÃÜÕ­ŸÒè4ĞVM-Ä¡6çÉû rÿçrŒ<Öıu‘y4Í"e*Î-½_—¦$‰‚kÊÏb÷jªÍÁß‹×në9ğ–T·í£@KÓûÎ¹B¸a¢âÃtş³V@¤ët)M©±	§šä°çÿú-Ì´3F bÓHï×SşMOdÀdìù®› fˆª½åè?nø>ıTm#ŒÌÓŠÑ3Çì·2xÔDÌòéºCyÖ«%šŞPŞE—QûR‚Ê&|K«¹TÓGR¾ôIs„·‡¼ÔN]¨Âşrˆ˜a¶ä³dÑ¨Ê‚R%	d§xÇ+È !m8tÎx‡Ñ#C’ÎcÇ>èz»&ê¿iU“ @¤:hï8#lˆÍà½}Œy:õEàP¨>½tR\[ÜdwÊ$>–Û¿k$ƒõ*Ê$8PšÏ°ı¸Y„e5nz9OW´Õf¨–²fï›­ÖáİÚ“)t’ÏÁ)qŸ™Ä¶K4ŞÜÚñ·§ó!,4ÀPÉ,®©Â×%!é»â A\ ½7)Ø.‚pçíb9g—J9èËnğ%ÍvcB
ÈÿJØÈAŒdëãæã\·„0;Zj.§
œ¾1p	3±W•=ã£´<©HÊ*ğé¤¢8Şe3áVZ)4ş-,ƒ¨ ”ØH¢óÉx½²~÷¶K‘Ïñœæo¨«) ÉS|™­¾&ÿCqÎIæë Ff¸C¶Ò"Èu«ªöªl;ùö/ĞOofå4Y#Æ©y_9Ã:sŸoúˆf`o{í`¢g1n™äj‹øGõ6­‡¯ûËÅ+5=2cÈ0ˆ¹ùJ´@‹‘…ø’ofæa6øîAVÌÑ£7ªGçß@‡Òˆtœ^(ye(ÕÎëtl¹IOÿ'oõàD˜‡¾ƒJ¥qmñz,Š&šò£áJ¼BøGv&rKfHÕa#à’×kz‹'UŒÜQçø7>§³º¦ô3]•T3½£ÒâUÕÄ¤sQìøÕêüv|ÙÆeÄC£ÉÛı¤ÿK‰ÃC-Î›æ~qğµYù;ØÚÉ+†Ç¶Ô U.;ü]±”´œM©íÑ‡³ šxq²îÂ&=tî‹ï‡~-ĞÛ¬åæò&ıpÆÓ$)ñŞI)°"~µ&'©ş;–’*˜|p&¿0ÛÖxˆeã7€æDö&â”z{ç$º®{w/"Ê­nĞ"]?U«j1¥c2¦Æ|”ì ó;edÍİİ”ÄÖV§æ˜8,™9¼ÖÏ¦ø0Kò.%qÉUód«ğ2ÏpQz¼ŞÓÚ;è9•ÒƒRŠã¢°¸¿U”³U¸s—%ëX÷·	/«oı[¸Ùé’ ¦V²iĞ£•¯³FšãİvÄu¾i§RA§y”ÌgÚ9lb“:N¼­ vLï6F"¹È‚+2.E§ÁY0{%vÛı9¾v•ùËué™'F1NNs@ÁÕëOÓRVŠÑ ÕH'Íä,àGï˜àzä‡P^âu¹›KGÈ«Ê	ím2è³çF`I8ù	Ãïú¡;]£Êøë–lÌI;–äÃÖ€ 0¡Ôx’õSiÈ\PÒ¨±Ù10¿	F˜@üÕûuÙÒ!mÿìhXwm¡–.½4ˆ^êğ|Ù+ğqå½ªVŒ÷lÖ™Ù_¯õÍÊ(]
Œ"ktÇå—¬LÊòµ0<Tğ¹
åa|œÀ‚ˆ€£¸85¢¿?˜	ŠÂ"@EÚ‰åfË2m±?,@pqP;OÃZ@K@bR¯ãC5VJ,N<Z4,¾y§6K:|ìİ÷ÅÚŞ>•dÿkPtSÀzs¶@B%Üš]£’|„ƒçØI\á‚–mK[¬)CÈDu–Š^-Ã6°
P|&Q®“láºP:¢ÓâCŒ•­Ù|5ÖÒ]{<ñù[ÿ&ˆùB•Üò	ü£\ÎaşÏƒÏ;}ÍYk}¼í6âó¬–¿Óy"pZ áËbpæ–ı!êöùñpÅ7€c¾©k}u£Í=œáUK¦«ı,£×ÍaQ\İcÁwµÆüvTâªOäĞßŠûìKğ4^CªšÁåò\ëSVÛÃ^ög†m§e´‹Ó©G-rA2­ı €S§(0m¨gc£%ÅRrâ%æC‡¹í¥o`NPÆr/pMx†¨! ,¬Ù'Å††ó¶¥õÄš}å(ˆú†lNüÌL¡‚•Õóß™P¬§®u
ğÉÏùôw‡©[ƒk±É“•´n@[vCŸ×ó‡µqkiÚÁáòÂ	Ò`Ù¤ŠdÁb-×.T¢ÜCë«€§¹*uÇÉŞÊ­ï¡ÔÌ€A¼s¤`»eåC)Âv
¢èJÒ‘Øõôš^9.D6À¹‹8[2¼ı×âUV3nÒd
íCrcõ@…çN÷M)í¨Yæ†v[3Ö·À ¢kEë q§X‘&4DâÆ¨U_8´BÑƒŸEÕ<s<ü¾´o9Ö AË·2ï||UîÜ´w ¼»»pKºÙCÈL-a-
-¼I×íÅ¸šùAÓ·9w'®/(p'µ„šŞ:9ñşQzğD–aªªLÅ£¥WUåèoe=E–55¡å¿ÉĞîà“ÓyòıÍh²÷Õ`óç†l”`*ï;	Ò¿%±ıô¡A&9-İŒ€@İñ7+@ciİ‹©X§ú…y	âtÁ‡­˜NöEW¼…™Ï,jyK‹­¥†n¨é°øj÷n)éÓJ#ù¹+“–5÷˜r+§y¦ÕñÆÔ\	{3˜`…·³’rœıqúGT’@Úq­\Ò)áá Û€­	=Í?÷[”:ØFÀ7ì~:ÁÑ­¿D ({IßX>#Qr. ÕZü@&§è8]öå<rü§11?ƒåV%¸$»+ÔL5º3½WÍÔ‡­»»ÆØ¢=Ö¡GÇÃò$Ä„c0¢AíØğÏëùZÅ½Uƒã<,&bŞßbAH®âÑÔÂ‰GÈ÷L¡ak|ô£ÅP½&÷—UïÚ_í†‹Vã°Âcµ§u60ò0Sgi{n.f^Ğ:fOw[æ—G¤ù‚÷û&î·b½&nD
“Ğº ¯sœÓ¬¼jò"A³Ú,¤˜lG&êöA>–®³
mgí,J>`m—§«mü:'.¶/şbº0[ŸÀ­ÜSæŠ–İå÷!ºÏÌ"óÏÊ•¦G&'Ç¥@[ìæt¼ÃØËd°ÀÕHÂZhrù;ËCä?zQ`ãÆ	?û&ØÂª¬¬']õ^„dwsEZ0élŒß }-¢’ 
 ¡ãôÎ`8Ò®Á³‰_ùŠªt*üBÚ6³œEéÅUT>üOGã­š‡øÄ hèdSkÿ™âÑœ¾ZÚImæÄütíÆ3Ü×7}Íhšn¶†§«€£[Ùİ’Á@N#ş×Äï€!È»–·C¼ëÀ7ª	"øæí=›ŞÁÃ¼µò»ºÆ& ODÜe½fß?[=Ğ&³"ßL?7²ØWĞïèİ¸›6/tWßÆXKFLuıWFV€/¾Hóı ÁQc¢ìÍTÍI}æ{ï3Cì¡‚ –AEkYçü2şÂÅÁ@µlO=.Ç«Å^‹,òÁ—âl¼ZV!ÕXö¬ùÒ´<r”ÑçXd®ju‡G;r€»b(ÂßiQ MN¾ÿ]]r G¯Î›‘•ì£õO½ß©9Ü¬+¨ïÀ*aqšÏî¼t3Y&âh/v:¶TL&§éåûcb\ü'Øiãé0j¥OKø˜|Sí=n«ŒÇ”&b]AzÌKªã{À{E\L«Óôj.şÍK£Ñó,p™óJ¯²*J_zä|b8¢ÎuAÚŸË¨‘7¬Ì"/F¢»ØQÔG±%–réĞ†No:Ä«Ùt‘ƒÖ›N–7Ld¼>c¾<=–iE,'RèPçF6ıß‚_6eÚé^iĞó!Ÿ:LìíÒ:ñîB @IcĞjí@W,T>­n$T,MmXÜğE©0qŸø¨È™`šë®™æ
zˆÅˆy2Q.¤ÑÚ&ófü\tëâ;H„“i‹“w°â±˜â-Ò.€qñÏÕºlYÑÁ”^k³úPå?:RmŞª…Òípå©+ÙÜ›®D:ÆÓêÊ‚Ùí*Ä÷óGyö}ßf»L_ıï/uyHÎ’^âB.&Uú­ø¹AX,ã7KŞ±ññ¤FêPaKé/~Ø£|iòò§d©3ÍøÌ\‘ğ„{â‘’èàÛ1‘˜&°ï¢Å¸™"¹Ò×<[€ïù[1¿Y0øW]ß$+Ô¢ºÅV_Qí KÛ"Xp^O]sÍ b4Ä¬İ‘ìn\8ÇJJ­	4jÏû ©'[ %}:I¦—ëğÛ3‹»Ôöbğ¨y~Bo	„ØõUÖ5“‘C/—C;'akšƒırğ-¥ş9xVb¦Õ6BüaéßÓ V‡r…Ú]ÕcÑ©'mœä¹F0‰(éæ£ªmñ	Åü3¨%òn+Á-Í Ò;¤¬¥
wÎïu~tŒx˜óĞ„şùûhÑvÜ&G•nÍ×›Íq»Ñ±:…IûcJì`ÃÎåñF7±«A]ªj½1‡*è{„8^Ïıt;Ïqo`ß†·xJ„‹5 3¥#È¢ÈU´œ/\XG×,cš­¶<5…òÉÙx*‡rÕP0ïöbÄ&!'|U»’÷â¤Å‡'šH€Îı:bøzYW©à«×U¿-à
Q4½4â®k —Şw»ÚØ='¹TÜÙmgóu¢Ì©i´È3¿½(DulºÒxôĞ¬9â¢¾dŸuŠËcÚ·œ>Ù\]>Â°Æî³îsâV0ğcïq;²„!Ê l‚*”Öû-ô÷$ñüß:şçR7ˆ°a•0[D„Üóô±
NiÎ©$8PN¦Wr_çAfTÃ±ïu—õÎĞµfg‹6Eï7¼=±2ˆÁøˆ ³Ğ„ç0vçKÁ$¢P$¥€Q’†µ+şAhË?~ÛŠ!¸%(µ(€	½ıİv{©)‰°™·Ô4¢`jêæ¡Cì#R²¯N¨æJ!8M3Îybc,g
Æe“‚*fª5À“>Æ±"³DÀ_B[¶ñµ$.m­¹gâCüÃQ5¸èl7¾ˆ »®¬¶…o*IşÿÉTÀâ&¡ÔJ¿šÅ–ÿ£4xzt‘ÅOãEëÁÕe6Y›OñÔúì]Æ¸PJè=olèØ•Tùa}·=ƒRfuÍö@k*]»^è?*0o÷õ³SŞ—îÄB|Æ‡Áø§àûIÚFdı‡éÉ	”gp‰•öÊÁ=S×%&¸
ó,pÔ…ğó/\}ˆK6¾<´¶Ã7Z‰¹ó ,Tz¼ƒ3Æ›ˆŒmäÀI5+†Q‚E/³:X`¢/c–âÃFİŠ¢˜ËK_ÍÜs=ak×Ñé&«Æ;œx¹êËó· ‰¥)âØhVÉø«?1Ë¥7.JøâÊZdÜ.)ñ •ú2Ğ©/Ğ¬Ğ"}XäÓ„î[¦÷Q0>\z9ğ–³µ›æ}q5•û²RmFñ´Â•÷:H`µôc—ä=÷Ï^<ŸQF‘ë”xk#Òqc5*ŒÚ0ÍwwhiÀTKÁêÁ:¿­àÏ~‡ï„sÿQzÑñr£µîÕYdâ–½¿I?êİ&ˆ'K½æÈ=~·bÄ-%ëÔaÚ”nh‡ğ	Iïm.EŸÅÿùá— uc0?3âÈ–X
¹à“¨ŠÏÀëMÇò¬(*Q Ùya&õi¤†G+WE‘­Åãğ
˜«o‡§Ãû{$[á„\µhe½¦y†«ÜzWÀözáğ6ŒŞPÛ’±ânŒ»Ğ¾Q§§ƒkØL´´$|ôÉä =Ñ}õ|Òh^p^»Şµ{wIJNáä5YGq¶Té_PÅ–ä4¼,5o4LÃÍ¸ÒÚ1`®=¬tÚg^B(İç™ÙıAL4¬Çşkë¡NäÇ¼(]ú#AzF'·
zªî¾(µ'Œ®D-
;ÍA6ÚœZ/Fg9VŒ›ˆ®‰ÔöªUAcbªFÍµ8?ÑcÔ:İê÷A"ç¦c:¿Î´º†2‰pyoårësí¦|îk›UÿFş@QÇoV„†)âïz«Ùøó\j®Ç¬Gèî:êN¤,î²¤}1Æ´HÄ®ƒm_%ªn»°@PÊ^²tÿÉ‚a>ò)¢DÈ` 'ÚÆñö>Í‡APHÁ‹ïB—’Ø!ç{y"\N†DÓ³âióÁJ4*«†,`™¶¬ü5¡CihìÖ(kı«ş¿³¿a¢šóáË3É¤L	$ü3a—…E]ÜøBx‹å¿Œì¥åã€¦H“ÆÀ¡ª¿¼‹<rÛáhêºåa9.¨.ÿ½˜×Ï¥oöÈ¡X‹ø\Ó6U"ğ}$B)2\3>H­?T”Km~BÏ¾t~¼÷ùğµZöf‡QŒåoµ.ª˜§‡å”Mf	+ÆLĞš^<·•ˆnb—µ=6FŸuîOÁùNÑó´|R}Êt±OÉx“"‡ìŞ‘Ø×Om¯ïoéËEU¿è»«A-£ô™´›ÜvC•S|±u÷;‹š4´©åiÌ©8T3|@€PÔ‚]ñŠ>^úşH×(ÂéŸ²Û:V	°ÉªŸ³¼¦ùqÁòvºû——°õC,f\²k±˜H©õo™|²M‘I‚nôü–¶“dîì>9§ş	ç	Ép"$q‰­Ìo 6“6)-‘ç¢¦±ö³Å´èƒï%¦÷fèê¨YõÒŠÚíÅ³°¶i[ÒeO
 4Î»sÊ
´ANı¦¦ ¡Yg¯TJ½ºTˆÁà¹×¨º*GgMÛÉ€+ân3UDg7ášíñœ&t;2÷³4Í„­}¡L›!UÇ›—vyîâøee B÷à¼Xà»,«@½ˆÉğÉí¥8/ó˜vK>™ÊNJf®|›ÅrÛÜÊŸõzÇpß_•ï¸Š ôA¥ ŒwM˜éÆv-BÇ[‚\+ÈØ=%v®O7è
ÌNBéêÀeš&©•IX,i<ËÃ˜ÔîĞâSËÏ™Ã®…ó*êáLÓXUÓ½§Â²f¦«à+as± 8-SŒo7YP·iEYúS8[“=!{d†qÛÜKï¾$‹ßÂú>ÅgæY×cwÖÜ:¢Òf¯¦¶Xòa ¶F!çş[Æ¶üOpÊï+¯Ö–b¹œáÉ #ñ¶åŞ<„œx^°§9˜¬q^=îÚş’Q÷ı–µb®†ö¹ÁÔHs6R¥Z¾i'M'«¼æa™,ÛÌ‘ÛÓ_X™èÔJ£«°Ä×ºnmQ$‡ñâ[a³©1)Gz±—(Ò¨lúÿ ÈÓİŒ‰wÆA`”x†5İ•jìœ¹2‰&óÜ¥ğÚO#ÅéÌ§„ƒä5Ëòöß¬IöãìDê` øëßëÈˆ¾ë² ¸°hAï$Ûó4œ	ùÈYI*g<Ÿ€Ú8œ“íëü]ôRâÉÄ<âÄÉï%ƒä×÷Ê†ú–ÓÑ+=éô_|Í™a4î¢„k?ZË­Èğİ8Yº µ¿Ãv1ÆÑº¬Xr†t¯oÎiÏíÎP­„’’´å„¥FŒe×¥İvh¥çbd°ØĞÎu/4 rÔÖO•$Ü Dö¯>o\De˜C¹Æ4$‹A÷ïõØu®ŠwP_`²›‰fg¿NÈWXCõ×ao×{Û Ô/µ%J9à*¨	{“zˆ|¦kVièAºÚkàüÊ½Â³`_]Y¯ğjìâğÉ­}•£â5ïª!Û›)Rˆ€iÚÒ¨[˜‘@&›ltµÛ#q CaZ´J„™#©şıŸb@u?ub˜×²¨1^É8Û¶ºç+ß5p½[¤úã
IÓ6%Üÿİ‘ÓmÈVĞª÷³ÄÃAŠ¸.ÄŠª™ñÂ­ˆN“ËĞó³$x¯b
V¤=ÑÆÓ6W{HC¯Î¿*{O7Y8".½›^'1sK7X@«ŒıŒÚnœÿ38ƒxÉ¿Â‡Öbí°¿ÔÖ_Fw(|<C`¶@–ƒÃçIb¬ÛgnìŸµVÎ‚/Aˆ¶ÈĞÚî_å©LZ¤Pƒs!îghÌwŠª.½“oîsák!ª)!/vFÑ)œív¼”<fy’”j”Æ\,$9fÔ%Ôøãsn“JezÓşšU8†"†^9®Ùô£1—H!UWèrçWvÂèl1xñ i«Ë×’R³¡¼oÓ+P¹Çã¸,ş/åc9‰;<‘ÓRVÀL~¥–¸Ò4x*¥í
­ ºÿLMµssd“9J«¥.»êxSëCin!ÆÿDäS¨º¬•¸®«4X»jxLş®Ğë'{”2VP~şQn…Ë^¸'C4ªbÊ“ÃĞ S½#äu¯‡2‡¡À·›‘‰N£µç2AÁ{¯8£nÄ5Àd¥nè³8©±cn2Jwª!º…x&EeO–/naà\¯Ú4şIR»½5˜§=èl
ö=²‡#HË”ˆòÂËr~·›O™gR|¢Tâ9^ª:¼{w*|w¤;™´Ú¼ÔíŒáJ6î×û'ªw=øU–³/ö£„ïbwYnºá§ò—‹L‡DØ&¼ïvdé¼š—Ø¢‘HLX¯Kå³ÂùİYr©¯‡¢Ïp¯ áÃÉ9vqDJïÜYm-ßDˆÃ–n‰İÔ¯£¨½QIĞzA3@3(Öş¼¢;Ëú }P—"·ö-ñæjîúÄ{§¡´·Ñ•ÑŠÛ^–“à¾ëRCúÁ)‡¾ìŸvygŞÌ$õê+ñácºt ’-H†Ãj-ÁÂÎÂCo4×ˆüØ/iÄ/\±Q8l»ß`å«5ú«*^¦fÄIq^•‹0’µÿ¹E×N¨ q—Ãuª`f×s—>”ÿ¥õ>lw¢êêÄ¡>e‚Œ7¤šÇ>uPïZ,'FñI|DGäõ× ©¸¡iÑ®ÕÏd¿Ö€Ã`NS›.”ŠNßæõ_[Ÿ©ë‡ğIó1Ø§’\É\2Û’CèŸ]#MÑ^Ï¶ÏY,(çw°h‘q/ßDú³w5Ş?œäG¾XòaD¹³tº¦!NÈôkjËF|'UÎLì0÷2Á‡C¼˜¾‹0ß¬bŒŞ
Jşì%+ó §EõTB%µ>/»ècà%WêÙü 	4İ…^îU[»uUoûnS—H4çdã5ûV<òü‚¿\‰Ú0—(€9‘¤~Âg§nr^´ßSG»¬ eS‹$kË#=ğAŒ’3nÌQ,ğBBu”>±ŒàkĞŸã¢uèâèŸa•ReNyoEúuÑPe²2Š˜:ye°8¾½_É_ ,›2%N2³ú¥ÜÂ7p7Åøµa ±8¯íg9{À•	mĞè©¦=ÚKîdtæØñYEPÀ)Pÿª::âïk0ˆ·zB€¡˜_’Zıy§K‰|ì¦_@sÛj¶¾›LcXñ÷SÈöûş´uNuo™ˆ¾D/úˆğ{û
<™©­ IÈÒ>Îd­f@he¼Ò°¯JuUë-2õHâPÖ–]·³ˆ•4ªø‡.‡fg˜]—Z Ì³„½ò}êñ¡2Ä½”^¤£cì÷û¶Y1.X©çLŸæ»U>³Éür'jáÑe¾â<È%ÛöhÖdãV({D«@<0
Ö)ï‹µ;¸ç0õ/kt®éîo¨¸0_Ğ7`L‘^ä» ÃU#ÒK/åÍéŸ)­b»°oµö¿L¤S:v¸&…½å°üú‰ğ7ŸxgÛØ+ŞcŠzdÑ0ô«ËŸK%ˆË–ÑÅ¨Óéa±©`YİŒ'­5u‚avàC¥›Ònx{XålŸ¿Y|îg6ê–¶—–ÒlÑ|7Ûëô°ÍvXkWï}ß÷@–å‰ê´ä“údøn/¸‹„Ä»ùß”ö’‚²=Ñ {	,   † îÄ#Ìm ›®€ğÇ+µß±Ägû    YZ