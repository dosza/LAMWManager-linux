#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1297004263"
MD5="e42a375faf5542c6abe2cc60f767c54e"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="24548"
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
	echo Uncompressed size: 176 KB
	echo Compression: xz
	echo Date of packaging: Sun Nov 14 18:44:33 -03 2021
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
	echo OLDUSIZE=176
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
	MS_Printf "About to extract 176 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 176; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (176 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ_¡] ¼}•À1Dd]‡Á›PætİFÎUp<æ*ÿ3„÷Œ$ØãêJéÜ%¿åjMÑª	x€©Óç'±Š)ê¿Çu…Ám3Y˜/yÌ>‹0,¬®Ã­rc(Ëö´¿Mf{Rì‘¶CU`™o¹9fô•ÿúÃéT+kN!9ó6‘µª¦az}ûL&üU½–“Ù—®İúk¢w³÷ëº#´t7ÀTyĞ	t&ÍÜ-ĞİI¤Ÿ)ª·°YÛï.ºIóg«!+¡Ë·q @ştåjškJLI>Å@)
L•dzq};T7Ç£½/5wı(Ò>‹vœ×«ÒÕ±ß8VäJhÍÂ‡	¼éŒgzM¸ÂXğ©-ÜByÕ&îP´¨æ+så§·fº]o6¡vÖŠSö„¼h}“ËKB]cƒ\èG&ÕS¯•æ¸”A-çMkİiUccY§_T|éRo)|ş,6$Õ¿Â«K6^ímãAL²ÉÕHüc1åIŠm_ªN,D¬ÑJòŸÎi¢k¶ËIÂañGÑãÕÈ“ºìşñ¿L…ÙÊk¡hy´ÿS‰}è©„åÄÕšLU‰¥('buëö›‰‘%š:`%k£Urà’›³é…T¦5şÜëN- omäXşÂÚŒiew×$c-Ä¥ş«7”ò,Dä<§@“UUá
{c_ éÙ`"._^æ.‡›"<Èrm¡ƒoÛñûG‘Mî(ƒ:%¬İÃFØˆÓ…8İŸ» É9+¶½GMnm¸¬“Y¯EÇ~—ùÖ79-AºÛ[+›ğŞü¼"ğ.ÕŠÙVG¡’ê(-°$­î_Ò…«„t–ü©ÂtD˜ĞñŠ«`Ñ&J2¹zrMàÅh¸4j´æÅˆîQCxô·w5Êÿ˜µ½»=åÏi×]nø½fwâŒ™K§%Ä,4ß­àÕHr*rpõ6ïû"8Š£“V‡3Ëv:ÑØsšpjÜkjkRJìm3,Üeø‘ê
„©TÑ“aFLö¦E`’õµ{´~Ó”[ªJFƒE¨òºñ…Wÿ8EÙG—9¶»Ç“ó6>'üœ9î	 ƒ™v¥š’NNóˆÉ®‰’ôr‡»IÒ©~3ísfÿ 5%Œ¼¼$˜1•°Qæ`O¨» rE¹ T*2¤÷¿¥mùnÅZTĞúäŞ·IĞg*°_ó–%«íD£0 "(™ÒVuQÊŸ_ú6ÌÜ´8WŒ˜…¬M}—I=©õíGH­®“çÒnké©‡(¨ìeÄùäûhô0ÂæĞ—Ú¦x-›‰)Ï\0 ÚÕ)jåÊ|½an‘dƒ™]Ä2h‹.}‡¿?IªÂbÌšq.ÇƒYöÀŸa¯X“Vaz\9ê1„H‰UÈ÷"Äw:Ÿâ\E,v8áÙ5pÙ ÖJ5ãş¾ôIÒúZp)DÍ»­ó-µõæÚI[9-¢üO
N±xbüH-êWÓ¦}ÌWş$b]ªzH„8Î„b éulyú,Ì¦eøÿ$ÿPÌd´ ÌVØÕ%B¢›SÕWô‘_îÒ:ÜáĞÂ%=ŒÜ£ã f…F(·&HF&ô ğU Ô—IBv8)øğ½,ÊŒWÈLNĞb©ÈQxŠ&’GÓ±DO£~­ö#O6Ìı“FES`Ë0¨Í²ùôè¯n)xöfâ‡Ri‘|àô·t2Û/¥9›Ìv};Âhº¬–=ì+3—¦ÈLzú<Ã•“ÕÎà¹[P<ê<¨È0W]åg™"¾YF:èœF ¶Lïı\Ìí£ ÂŸ£ÃY!ÆF‹NKÕæ D=7×½J÷ñ½„Yû/}r‡-«ÙÊBÊø)$#{K"Ø>¶‘jÕÇR¤jèÈ®ùNçò±õ'@d>¦‰mîÃŒÓùÁ®—ƒëDZô¶ç½„-¼­¥L1À˜%³"2ıDh{_Ñ"6İ\ÕSo_ĞîOÄãœ!Êq	4†ÅVrÀª#9$_Pˆ—'[å‘œDÙ¿w­µ‚'“À_€Q=pÉ]Î³¾BòºÚø=®Xi·îfª.²ï¾c\ä6¢†¡7w|m‡gsªa!¶µ*¢ Ó%ÙyôòB4ûZù¢óÖ^‹2y|ˆsè'ã^C:´„#ß3UÁÉ½İ:t;Ş0ğŒXÉmu!`eš(&2PŸeø”İ!}‚çşªu1¥ˆËF®!ïÄšûKa¤ìˆÛ|IyÛÒ¦]	ÒÎÇŠsÊîØ˜íîÛ:u‰!% ¯}$@’yˆY§Š
òH)ôj[y=U+gÒıs/;ÁU2¹;Èxç¥êË³›€‡pÿò§²ãù"hÂÏbã ¸Ãh³)Ú)#³®8{İä—hæ½{k¾f‡ÅÂkŞ	ÔãØÈTLM:Aã3¨é>ÀW4˜üOòâ3!Ò}<–Â^’/rë‹Ì’¤äÃJQ+©Kk%%ÅS‚’ı{y0~¤@ãµkC1ÌÖv¢n3¥®ğ#)©knÉ¡íÖ7Ï
z€q'z:½jµßİ×ÑL¨ã¥:Ô®*»òx‘«¯™ß¬ôd<Ùôw/ÏûBSVe-¢­‰eŞÇ!µÂïSrÇ~:A³„-2 ÊvÍ9}8’m»´”xZ¤¨è;ÚÚ,ªİ³óÁS’j¿±(¦N©1ne-™ê£Ãì/ZŒÒ5›b¼Ï‘´;×ûUóñe`3¡x``y½ºâ2èÆN†¦~1€İ½p6=‡ÁŒwÇú÷¾ü«ÚÇ>ÑsÌ|#zíÏ“C³{fË\i–ÑÕ İ#YÃ¸S²¤nŒéW¾ÿå6$ÿÕ²ìÖIàs!f>@¼C Ÿé&¢.¿3ôóÛ>1ŒÊTëØÿóú±My§%ç9&K.½¤ ¼jvOh +²ZÉ‘h,ŞÀ×ª[4‰ÎD˜Çs¬—@ÊQ“ä†mxÅI5îìÚ5,-\¯Uw$kdÖ:vxªÕÃòœ±šacÏJÀt¤O½ÓXauïGZ‡4±X†°ø¥í¡¯ÆÙß^RÕª¦)Å
ôç_Œ3Ïjçô>9"#zŸcº\j½Ñ5.P«@£'(–Wº	l›%LšìA8ÇµÎ°…y.|íÀÓ­ÀÈT¢„]cV 44^•rEá©ÆŒñ–QÜO/è¬ÓVí2x¹.Üx4¿áæµ‘Í“ïµ%cêÎJ÷GP£`o4dÀO¸ÂÏ* ó™°MŠ-±GGpCbF|'ÁdêÅ	‰ÛroOXı &µ€"®µÆ-Ê‹-ñ„»æ…¸$ÛÊ¦+	ÖåÅCÜ:œ½íöÛ$º'¿^:bğp\û¨nsÆÍú%RyÁÎ‰¯}ÎV‚¥FÙ™RJİÙéã"Ğ-²sS?b**H!¾+lNI‰Z$KdFlÄ3ƒ~\êäğY#’öX tbÊ‰ŸGûAš1ºKËh½– ÙÜİ»‚­ÎØÎ˜´ÿ¾ø„I®S6+İôª«`|]ÉŠg)0[‡˜J³°„¤RŸÌ×ƒ-&Ü¼<4e µbÆHJ•\!gşÄ³³ù*ÅÙ2wó˜iª6ŸH>ê+i.Êe\eøJÓæzõ:OlÅéE„ß£a¼—Cm#æpnGé2ó“Ú6›}¤A‹ş¤¶çó¶O[éPæÂx•j%) e"£†=±h-²éƒ›ßúrœŒPDÉZıkYyo>
;ğ‰È–4uuwM1Ù‚Äüê“‰ÆoXôç}À¢=7•<Üâáªà­¿ñì,ë*X4í{L@9›uâµ},p¥yÚsæØ<ëQüñŠÔ&¶+î*#µ×D¬K†‚~?±¡ş	8‰[¾%³f`ñ¿©$ßñ¹\:=ûÉŞAê(xª®ºëÈ=Ø€M?’Ù`¹u‘]"x_Äò!Ú‹ƒ¿‘iéT£ÊS¥YÙ<hÉêVà²÷Ú±•!á÷©«K>¬dªù‹ÀuòRK5³"8Šu¼„\3×VĞ[—Ó·wÎ=‡]úö­¡(×¼~+˜ğöÒ
’Y:J	„Zô/¶m´¦mƒ³­2Í–ÃGãÉıRnVh~uü¹ÿÑ™ø¿yTpæ/Á2ÁnÒj*ãüdó´‰/s×îg˜ËiÏÇ§ä(wˆ®?Šélxø,ówÆèÜ†P‘4kû ‹L5XÃÓÕ]o;:•$úÍ½	9E|lÏ3¤Å•ESËå3>]êÑOÂ{l©÷ +òOµRÙŒ…/ª»OLSxË:àx{&ÌWŸàÑ¾…ÍFè§Å®ªuµ
®zU;DšÕFÓAµ¸ÒaDmo»·Y.İËNB¹—ÂÜûÇĞ6·ºL„gBCÂ‹Ûï(×çûíL*å
è¨6ûP3a8¯bıáiµ ™0•[$ü^]ˆĞ Ûµ€Fke³ûúoí6wƒ9Â6Î8Ãš<Ÿo–ó¾Á­Ÿ`Ÿå*`€ü¢İpU-X4Xì“J•¸iŸ[,÷Å~²$ ‘K*ÚPñø±†µL…,Å%X¾T¬g²]FçÈ	¢:v! õ†k&6³Lc[jÁÓ&?n—f7&¸eĞ‡äîjÜY¼Ô ôßdşÊ¤«$“¥¸/ÍèAİ/ÆƒnºçGõ7	‰)HƒíÙõ°:„RBª5µ-Vi«YÛ[òã\OËec2ñò$!K/=ò}M+M=•BÛĞœ{WG=)µ¶äÆæü4–ˆåÎ^Ëœf	 °Úc°¹²*˜hMÿCÖ–Yé?@fKL¸$…¡}½8Ñ‘µ·!A[øö£ù‚“³
Ü÷«e•ª¡Ò‡ª)<S°³ëaÆâ©Å8LÄ^çÌH½„ÃèL=8²Š¥”ÍŒ%Ã”,aÂ$ëö€s wq¸Çc”`ÂôhU
Êk»qºe+ b)n5À‚ñ¼&g¿í¿îTÿÄåuxÑMÁ s¼usjÆØT+YhÙ÷!áã—s“ L¡JÏá'‰8ĞçbQ¹°²`&Çl dZîï2š3ƒªKº¥¹q4ÊÁ?a·RÉÎ£xy¿¦ˆê'v.œ™äa#DäÙ¢Û„…
miÂ‹&–=–†à?MˆÚDG~ox¸CNÂ™°S™	œÄAd,³jôğ"…Môî:ÎB	Ø<^B|[Ÿy»wÉ[=:*û'ùlíä*X®ìQsštQEB¢ŞâŞ†î`ı¸ü\o¡ãßŒ$Sß´-[à¢fp-Uúr³)… 
ïò2B-¢•¯Š½ÕT®sáõífÍ-ï…–{îWPd41ÏúSß.ö¯ƒxÒµĞÑFÚşlñY³àp ıÍ©E{.aq‚í²,€øb¶5­üà5¨z¥<^d±›Í™”Q‚»#`mWf©j÷À(VçŒXWâêV¡¿EYql>jÒ,ÁŸ±ˆóãuMsvvÊY2‘gô+#Ğ%2¾*ÿ¨Ie‘FöZ¯Y6,™U=_—Gà¸	cPEİõT]hİIrF4˜OÈ©Òu42FòowvÙçxÿÉ/r§kò¯3çİœx¼óğÛ~Ù&¹daÁô)PôEñëNQö9},°Ÿ\j Áóú£Ô”QÁ)?ÀÙîMÇP$ j*ÄM¸¦ÊiáYl‚ºrV+ş3®ÍÁ`¥ĞI¶YcÉÍ
@!ÀÇÚ‹¾Oôîíc )Rj?ú‡Ğ»9ˆ¸Îs£áC€rrtõ"Ë4ÿ¨À3îNò'ï ïÄ È^}LÌ@¢%‡DI¶¯,^ı:tœRzOÑ^å¢'ç›f’‚Üàæ/¢©f6f³›Qn=·2N4R—ñå~oó¯H†ˆä`â$~|ĞmzU­gàš\´.éĞ‡2“šù’ÑB@QCİOAmÿíXü—!ü¿DÊÒÈäØ#L-2²ç'×L:Âç?©¶|ÑÙ6o›Rê©§LÁÁR\8@n%Ç¤wV„ÃÂîU`¿±ê”«ìğ‰1Erò"T’]…FŒñ·ÊycÜÉî›ÜbF2@´ú ¥"¿ÿ7hõw]7ö÷¸Nwá¦‡ÓˆÄè6ñ¹Ú™şXè n}}F*à'Š{É°Hx³›soZr|[È¸P	Ÿ—xjY‰£ò`$O{QÑ¸ÌU pVO÷DÄÛÌ—Ç¶6µ³„§.tc×,RIÔCùâ¨:L°ši¼ Ò,´?ÁL3Ö1Xq,¬É÷òÈÎÓ7Ni˜1`Ê…Q'ÄÓıF^PÂR%B^l
+qÿ8kÊEW¹820äSßr–Lşbg—ÉÙøAN˜áßŸÛSÅAóßh³lá$9æõ‹…»0¢ƒ8|Ğ«É ¥Œ>`fŠ’™{TÄU¢ßô%ìKIkáñÖqÆ™‚^ÚˆìSú¾J¶Ç¶ªÜr‹¾&²µüÑÜÅüIc_»ÂI1‡Jˆv÷KO6?šæì@nlØi
®6¦†løƒ<yd;
{G$®ÕâÁúdEğiQ³2Ë(qÍ\Ò¢~¹ĞÄ˜™Úå9;ÙpÎ¿ñÕh2«ÕÃ¦iDÔF<_£$š}9,ÚëJ}1Rîì;ùÈĞ
OÄ´„m£VeVãŞ R67Ê ğ1÷{?
ìÛ2G«=RóÉşF¾hú¹;+îÌœ±æT<|Øñw,Fu„ŸŞ|LıQU?Yù†¥
İßøx€Èìæ£…¨0`[Û!F-¦S¹~£%fJéäjºa¢.©Ë¡HÂ»TûÌ¡6‹¡TtÃ# \Úóü"u8Ğ…y¡«pQXi¢–ç	Óœ(†#¿/W¥^R¸’‚÷”Û¼+°†ûŒÙ+SéÓú/¢î¥«úwu&-Âzûª4+wf¥`ñëDæ‰ìÔ…1é7ìï(QÍ"Àòº nnåİB©$5lÌn>1aÀüOßé·tTL&jÓÀ£ğ^{¾Dó¸¦Áƒ.Ÿ±›Õ¦'¯Wfm´ ¥âDh9+Ê´Û¶ª×‘ÅJN´nnÃU0jĞú·£rF$…²ŸyE(qÀ¹­<E5l«#tWÃ«é·Ö†üO'ï;í”ØS[r"?ÕIƒë³²ùò+p¥E«ëúşÑı$ºRŸXf©+ñü¥ûĞ›õñQ€‹G'ŸÆ^íJÖU;Ù ¶Ÿrœ("cÏ÷g³p;HÀŒÀÆˆ´'÷â©ÓÁSÔ£ÈQüjDŸ}¾ñ†.'ü¶¼ü<¶Oá£+;m¿Ã zZ8ß‹(Œ3z	%ñ'¦Å¬â€ÏĞèúÀõ£´²“ÿ»¢;É–®Œ”	
E!Z¬ÔÒúc^ßŸú\PÜ©I{áæYrdZAÕÍùmAœÓu¸ÍÈGA]¼úİ(âÙ$‘l«doÿù‰˜Õnl¶([¨|Bş!8cåRÕ„F{ır„RùŒ–®à‰wpõâ³R£<³÷7t»ádı0õwÊ"ĞfGEÓ…zº6„ú\r
ëğÖØª?2ï$1ùl|¸#½‡²îÀÓ˜ÿÁÌ~ğR~…ó ^4Ÿ½ı¬Ä×#TÜÿUz.YÉòoÏZ­v ôõˆ}¿v	„WŸàX¨øïôa o3İBÂ™ÈTµ&ò­Äç¤“R5¼ÌMüƒMö«dØğê\Ñ[~U'_¨‚4²ñ¶î0¦S7IÄdkƒâºJ&Ûéæ`y‡†IÑµ‡áKî‰öï;†×ºØ0kñ¸†ç²Dı+¯ŸÆ±§¹%@²&e^HT¯D=Fú‘s»¸Ÿ57Õ¶|)`êi¥ÃZ‹¦ zB”´«à¶×Tb°/ä Zm6©aÈSşõîIÿ¹™gß_!Ñ"~;#¸Î.±{8£~Ùü.x1şßœc%²k6g]š¯¤'ï-€†³®}8ß¶/„ŠCı|Š™÷Ï–ÌÆ$¥®!mkfÑ2wm6BQyí11¡b‡[òc\„sQ'÷Ğo›x÷şv„;óc]MFNw‰E‰)rQ;hdˆ/í®¹èVşòúç*7bDç…_›ğbOà `™	_TrÇVİ9|sE“œš¿~ ÒåöŠùW¾Óg…ŸScùø$"|8.‡³Wæ5“³F}HfVşX¼ø4ĞáíYÿÄñlÀ mÇ¼ÛªÌûj~?M}Æmê„^° l/†¥½]VÁ=ÿ±šY»Øş.6{ßÔuª•ôÚñé"ë#èN¦ÆD!©çu‡8ï´PÆ‚½â:˜×ò¯”½<’/OU‡8ªj„¹<¿!pÃAÏ#p	Ç³Ã2¿ËQÀœgsùXé«]¼§HÈêØod¯&Õ½‹ã3X$$çæÎk–¦PÒ“s`–Mf›°çz†ÄxÖy$óÉÜÇ}Ò…/
nÿ†ÔK½œ†µÅ*¥K¨àäB0a¿Îk²³J<b‡Š·Zí¤RÙšÈ¢¢ Jªö­à`·;¬šò÷¤³‰2Vüoë<µn‘¼qİcÈvNøwE#í¶ØYÒú&>š}Ã¤ß†NçÜT·:,šÏe¼Ü"o@cwÃÛÓb½$m(UFD½L»ÁÚ
{Ì±Húi\Å†8E£ÿÛø\†©»+DXnÓÍ}ß€i®³îqN'ñc <³Šğ†ô4Ò.Øgn4E³qÚĞ4./Den7.[º›åjé¨m¬É›Éù¼Æjvàÿ~õ1ó™¿Ü4x5‘x#_Ô#®CFS(‘†:QÄKæĞ_vpÑğeız0¬*kÖi'5Ì!•ºìmò(e·şÁ¯Á¹£"EÌ ¹½™øŠ¬àÁ^¸ÿ›_ŠM^è~Z}µ—x•LA³!zeş]NºÜƒtm°·wæÜÇí
N¬œÒ™šÜE+Çø™ÈƒLôèÊgŒ~÷è–ewHşÃæ`=e°¨0Ñ"SÇ	å|æÂ,n°l¿ì”¼è¾õşœsøC	ä»ú]¦]ÁgxL1‡­ €±Ä–‘T?RZLFı‹ì|£OîK!'&¦DÕ²'Älˆe %9İŸEÂªxåC®êcçJ<ç)_m¡`0Ö„'c¬ejÔåÃ.:ãåş<µt?U%+pL‚<£àª÷­5ì®ëgw/‚rBà³fjsÆx‘…¼¤è:øÓ’r¹ƒA–˜ât±õ3TŒ"Â§F¬†VJ„0ÚV¿”P‘ºy†.öM[f52°x¥ñaÏŒòôÛ·:äX‰èŒºg‰5m³W‡-ÔÓ’ûÅØ´jú#F´#!¿ò†@ñÊ+bÅu|ì¡%µË^TÃŠêÆË…bnó€óq^˜ŸˆSeKÌğ|›†Êõú—=Ã
¥[Áğ”¥høıO¡¸Ã­Ö[PK•š9İ0w-sÊ5ü<¦ª¯Å? ¯lƒüBı¥º7÷ƒÁŞ†U‚ö°Ÿ¸úÉ¢å¬•cª+É'•&¾{>'*_æ•B¹ğ|^ä¾İ´S+?uê[:Ç¿z'ŞÏO°+>ŞÉWfm1D?­’£V¦rÍe€]¼2e¾loÚüNv™ûTW,6DeÓÍ{üÑ¿¼;¤ÊêÖo†ıK½š»‹•{ÿÆ²GeU’'!Ğñ. ÖègˆÒp´œˆòñ!Wô¢ä¥isHBÍ¡xQd/ÊÕı7ãz-P@&¬z  ‡Bßjjb•ÊäÃ³@‹z-µ?KÖMGéş`ÔŞË¬p†`SåúO)_üÈò?Òq„f%‡PGz£^¦¦M9=H‚çsW|Qú»ª69‚°LÏ}X@Åµ¾OªàaImï<N0X#o_ ÑJ¼”Æ¨P¶Ã_€Z™	ÛyóGëó¬ÜD[Ó¦ë—Q9›EìHóN_â€ê¿ \LZ·yÊĞf('¹t›Ír‡v(E+ÅxÔ5ûúOï¸Ä$"6IÙiÄ×!Ì¡j—Ó`İh/Tÿáû—÷–Èÿã¥]„‚Òª ªIùR=#$Ïìq.ÁÃÂK7k£D©"›ø}Hgf±!0bÁÈ—ˆœq¨tÀÈbd.[$Îé[ ª‚%ñœew‹»¥ôq†‚¦å¨Ğ†Ãåa6>kš«\Å–¢¼á2Ç:ÙVÅâ9m§aGÔ
D¦döJw×²†3=+ºR­ÅåİŒ=ä”]±ê*	’Ì|ÙÔ¶¶“¨J¾‚»R‹îI·!€Şˆ<4´sS5hsŒ†ğ`cBK70¼_`k—S#à~fH©“5/IÁ¿¦VŒ'àu%²’üø!8v‘6Ëœ¸Pè¼0È‰Z¥N ‚ÜMSsDˆ¶Õ%‚Ñtjƒ»É¶ï´—:ZŠÔüc™X-Áa,Í£¿*Yo§ô\ºjˆ¸:ütŒ†4<1¤³+¿	Åi]p ğÄµ“ ]u¨`‘o’tÓ/¬A ÍAZÊñÁåá¡w´ •u¤Üædù£’ÔW¹ ŸeLI¶ô<é%>Öúî¯“"‚ù9ÑÑR|p1m µ¯»Û1õİ¾’½äwıï9ı—ŠM/ÈSS€èİM½‚oVYütıQö}*¤,D
úNæş1š"®Øç7ÑÃo'Ü›m´sPø×ªAÌ°›Ù˜óˆ|ÕãÌºSD5ªSâ”—`ÿésm@¿@-HÌóZ%œ>Œqx5ß:P†G»‚Ğ‡VY•õ«o²\ZŸ³óË/»Ú¼ÄQ”WşÚrÈÏç%fX}_ßZèf¨9ñ‘Nó@Û´¿e¯&ø_}+à^ŒÙÖ¼r0^­êÄ›W­jº*d¯ RœeÕ>e+ ‘¤iÀxD)‡•ï)êv E¯™?w¼Îî>ËqšxöJÀÿ;D.Ïè¦›nÄE¾ì˜ÕÔÆ£•Ì¸O"øÒÁSùZN"_v~°Áôí<Ë_¤%·DˆPÂ-ëµ~vHÈR×›:ÒrÖ‡$ñ§hŞLlQ…$\
uŸŠÿ‘P+ŸS$‰$WI\jc âşa"¹gª™^„7: wÏm±°Ëìˆ#‡İ+p]Å•P•àk>Š<×/¤ù=êK9³°Gó”C_Æöái9Üç³õ®•)>ÜÏÃ·2ğ—zÀİYŠçõ©½Æ"‡Ï„ˆ"‚;K‰|½É,å€†Ôƒ_º'¥ò’§«ŒN}\ôˆ­…Æ^Ë{~›Ù
²OÄ}Ä_1e‹¯U@µ./pNÊ_åĞ£åSİâ"¢·%ÎÃW<ß[›w™Î(÷Kø¡ºU¿¨'òGòÿzÜ›Gb}'®[†–¹ºÙü¬³—@Gæ(•0¾»ÎZ4Y@0Œ%[Æuµöîêtæ^ò†€` €S3Y¿¶&ÌY7aÎ<¢ZµyÌz«Ê¡>œk(ÄJw1k˜B.'—Áßt¹€…‡Swâ¯°zŒ]f•øB!é‘V±óÌ“cãäB¶—ã€´¹óšËA“å\|·MõØôº´Ñ£Òß¦zKh	æfL¹æ{OÔÛ¥›Z…øƒ7ÊG=±§‰[]tÑ´¦Úª€RÿL,şêpª¯¯#±àxƒÄtÏ“{ùå®çÅÔT¬Q¤çÜ”®o%0û:A`Íh±œ¯­):¡šÅÖĞ_­R·Y<òòL®ë¨# ·œb“¼G?¿Q  mîÎ÷NÌâuOÏğWİfüÀÕÿ¤]ªER¯'– ˜ahßŠÌ}Â2QOÖÿ¶>+13åù<ÑSğ‹}`ÉøibC4.”ßˆBÁ#+BS¬,„øhsøñé;f“£ö1Šõ°åßb”{ ß?fävTQ•Ê-ÁDşûUÿ’.¼úŠBALÔRÙº¾™Tsáiî~"£¹_èy#İ6<$¯OJF† |j.`;Q¦ºĞñNMZ\¤Òd£EóS€'ò}+„RÙY{Åí¶62Ï™¼ş’›wbØŠƒ’+˜èßÑœTÑ¢„ƒ‚Œ•]^«"¤o¢ŞEØ&+£‡ÄÀÇS*>\Vk8MœçŸE_ÑÎò­_¹Š$1¿w±öİ'˜!ã0èëóvSµV¨vFÔéL‹úX«Ğ—
!ôAN/GøÀS†	zybnO,`X2œÜÎqÃXÑÜ¼Ö4ŞEçe>885áÚEW²˜Ï”ùä±øxIÜ]J8¼¢ÖŞÉ‰+™¦f•=Bü®hrSë’š`Û Á‡[Nù2ÒUçÀ½šDÔm2!‰sÎãŠØ*g‹ğñæDòBÄ¡.gT0ÀJØù™fuŠv­êäö}4b2¼ÄÆ®J`"|-É†cW­Ùæ¤ƒWn>Ë!Y¬Ağá¡< ß—ºpQ›·nSÆÀ‡|Ú&r·0øÃêÃÒˆBñLG¥¿Z™²ËHàHÕO‹œÚ g|ÍK¨%¬ŸÈÆøç@®?(_ÙKÍyFà¹"°’‰_#]õ~ÓD•omS)¼©Š’åZÑw§ŞQÛ5 á¬Î¶ÆÅuü™É&oN¦¦@‘õ:Ï¨ø¡Å²÷ÅÚ¥=¡v~|¢¿9,E„µôg•,i‡OUzª˜›¹û^¦‰:á;i@àşîq)\òåhªG'mwè_•­ìóW¢Ïä_E‰)Zâº°i¤g´p]"‹B;N¦ŞİH úv¤ı"ñ¢˜lÈj;ı´p‰÷@èå®}ÊóØwyxJ}ÍQIâ¹vıò6Ñäå\1XÈîÏdè	tD?UQi¢âwË\]ÂOcùÎ†lâ¾×ÏEçúS•À<°´®$2T€®jöY$,õ¡ëi¼—3Ì	'c_sğ°XÒüdúâ,ÆÆŠĞŒˆõuî¶NNØ:ì˜”û?Ù&6õÖtìtÚ ÁeÉë²Uk´§œ¾Wêsú".xO]÷Qt(CD—ğ¢kíC#Y"ºeLVsécËÆ¸à'æšÌs¢!îÎÑòrüF×:;p†xé0X,Œ µ`™OvÙ¡îôCr(6`Ï¦°y¢?ˆïIA2iµ>·M ¿ÚlÍ)‹#ÿşñkĞw)vÿÿUFÁFDÿ•én(
©^Ş^,9Ú·XÎn7.Zl²H®€!´÷Å‰˜ıhûí<üWuî\góWËóÎJÓe< óôïÛo©8Re÷ĞŠ«¶
Ày\‹ÜWî¤gô°¿ş¯8µ®?Ü}7„Ú-U]ØV3'l¾ŸRwx#ÌÇútø—ªU!Ò’—_Ç·}æíñÎUb½jUãÓ‹tß†±ğ¶;_ñÆŒ¡:ïò™?ûaRä©~§óÖˆí¯|T?~
0YëêñçPtĞª¤óT¯íÊ8Ó”7œ.‰5¥>tÉ|‰&°·ú|!h/şËö©OUát½¿ÿOä' †Ã.‚®Ï ®G¥N*%CÃ³m’õvT“jíhé7z±	˜Åİñ}UéÔëîCñ‚Sà•ÖªW¤ªÓ•ÉÒ@¼A4åŠ”"û¦ùŒ'ÀE&hF>]¦ûÜ±ÒâÃÏr»œ!gé@Ä®‘a0ôFâØÈõŞ•¹·İa©¶ùGÓX	š¯»,nÁøbøFˆÍëuqÒv‡l2ÔºßŞ ÃeşL¹‹›#YAÜMÑˆ_÷ÿfÀ˜OˆĞÑ‘Óús‰¯§œÛº}¢ı)+i8»Ì‚|ûQK2“õÜÔÑ·~É©ŠŒ‡÷8Å½±gÙò%+qk`~º²¸™N”Ôlâ€İó!ô_§iØ¨ôöÍv ¦Åµ].dg‘Š3ÙÇw{PXœİ™ßaA×èñŠ½Ip	lØfªF–MÜV…âMÚi(ƒV™Kcöc YæşÛ°uzJèéˆ­šËó–ì°=¡!OÈû ´÷û§Qiæ…¡hê@¸ælï3%k]·W©ÛÆü/L^Õ¦µ‹ø\£D”áÒÍdf«êo°;İ¨è`äÆy±˜$m”XÌk)ksz·MQÄî %ú¼íE-ÛgmM8ón]!ÿ‹öÚ÷ôú˜š ¥0„:{'³ëÖé5bnš¿?³Ço39¡7A2…‰¬x*Ş5ÚqD³5á´äc&S|–YÈÛ<Û(S¥ƒ¶!¿rRhÿ':X¡`t/[êù/§KLç¥ƒ²ï_hkışæ×zn‡¥©¸íJv'ÿèÍxMÄDPå©’›˜ÔÑ6
¼½Ş°ôhĞ“¢Pñc&˜ª¡B1æ©Ø0’*ñ]"ÚÖè¦jÛfÃaÂuîl€ÿ[	§ŸNşObŠw²×‰±õ×Juø¯<töc’±«ä6oz±pş+š:c3‘¯™@ÌzßmÜ!WºnãQT;‚	tQØ»Q^—İ`™À»Å¨ƒÛHw{äÚ7ÿìñ6ı
ª…Ş{±çÎŞÉ“ZQF:XAÇzç+)ö‚óïÜıƒ	ÚæÚ½†]ÌókëÖ,E¶if’`¬-ë Q¨ñGkéE„¥š}Ø·wp"jDG©^ÄYb@¯¥L\ÜL-A¨>~NÙçeÿˆ»D•`løålMÒ°Ú˜µ”‰
ÏjLs‘–¢DÔênúâÍ…q¼ï²W'ú!ğ#T¯†„Œİ*ªÆ®¢OÅ:´QaÔ.'Ñ´¤Rù[ş4¸œŸê3~të$-~8¸ÔÖ+Œ,cK€Wqı;½Ñì¦¬×6®~5ªˆ¡›‰Şòıek>†ÿİnĞb@F}€‡Íò[)î1¡¯/qñâÿÓ8z˜îˆB’Iúb?yï€Y…¸L“e) Ñ—ı; *¬‘o­†ŞËƒ'`ü¼;yK‡Âê"6ºÖêh"Òx)úš —Kkny[çZ¢hOÉP§81³V´«–Ê*í0Ë5‹9¶‰Ì,ô[í£Q>øs•“	ÆÁ®åªö»ØUœ(¢ÒĞı-á«"T­ˆ³ÏCGé'ØåA°ú+ß6/ı ùÂÿŒÌ3\@ymâòŸ`ä#àÎ(Üòê8ÒlåõŒXb»aÍœ>±Úæ'Ww«=Á´ƒ]¶”b.n¾÷*ó-8ØkBä‚Ñ¾&ÖCmËæê8Ç§öŸ!ˆsÈ'7²æ”e>$äğIñù[ÀïÎ€@óüŸD©‚[vèJUjĞâCY~&‚q…dÎÙéŠïí4Õ’”Í>D$éñI„ˆö¢…ËqÁ %ò7<èƒĞH(f©ô1Ö.ÇjZÆÿÙñ{Ëô]ï%ÂÏUb‡ö"ÚcL3:ÓÆ&}:I£ÖÎªcè-Ëp9¾ŠwÇ`•G€}òrtíÜzŸ’Rø™)ZP@ÙŞÔ4LÕ7İºJ„K8ËNŠ¥xQòÖúß'zêº&ÊÀiaé.|™TóˆÑâØMÂõ[Ô°G”pzMßä™áXd[»Í´rÑı
Å´ÑèÙ¹Wš”»1ÁÖlØ;E¼¿£Ã¹¤a„Ó—YH.ÑÅu:o¨')´]ÌƒÙ¾ŸbxÕ!*ê8¥?‘ĞüF Æ1¯záÍ0¯rÏ$íòC‚?ÒËñĞ\NMú¿½F)Ÿ«ú©½•-¦©eDÌ­ ş”î‰ìD¥1åŠóbø',I(šá~£Ê¨íÄ[Ô•‘'ZN=ï}»«é?w[äâVi•gÿÎM%±ŸÙ¿ÑbŞÌä}hÍnxóÌKLvö›îğ&Q§oá„‘Šj¿1ÜvÈ¼ë&ïçŒ†¢UÛ\.Hkµ¢n­o“Êï¦ò¥ÚyÙó”PSXÈëE™i:èzH4Lã2@oû·2®
PÖÏ·‹¸‰>`ôÀÌ:]õÍ–tŒôÇÀ0Ì›³:h“®!“ëCuqISGƒšOH{
ŸÚîÈl:TÈ|cÕÀŒotÔ6 ¸š±Î$Tlt=8–!îÖiÑux·UH±Kÿfò©CŞ
Û8©LNqU$Sn¡~‚Á!@õë9[åêZ^t~¼ú/*Íqˆ…/´ ¯RcÜ1L¸ôcô
³§ı¯Õ×:”*Û‰Öôëc„øŸŞ¨Úñã¥‰
¯8º·ş}Ô©¤ÈöMÒËğy·ÖÜìÈák·Wÿ…
Ì	w@ÿ-¨¯¼”|m_¥ùhG]’ PÀ¼tr…Ša”y$
.¯>±nî2§’<ÓÖÛwÏ‹D§(qWŒ¡ŒfTKq$‰hò"›aTÓÛîŸ+ÇŠ@ŞÓä?ZXjYU°ä’ûei<*
~A_È×K°ßÖ‚LÈéÅ êd«†fn*)vkÿÇC+³NÄXjJHûôÛNôÎL0ş°B9¸Ë»8yoW|l$Å9Œ&%ásL†ŒÓµ¨O·¯ïqo6ê$n!ñ&ŞšŠÈ(è‰¼¯‡Êím+…ø)Ø‹ùğ-ùv¼ĞiYÁ‰™àìÔÒtßôÖ“ JéIYTku[ÉõÌNLE²ÕŸ–'í\¯5.ÚB½|³a¤qÜ¬}
˜“yÈ’@×FñÖ¿»~qÃ\`nÀœ=’ÁgÂc­ö"³»“4J¡ ŞXB†sA¯ÃùÔÆÂ·ïP@ˆ'j-O•úš¹_›âû0¯Tã;rœ,ĞúÔÀªÃHİ£ÿŞ?ÎC!\Z)ä³Í×ÚG«#êZ+‡–y\‘’àŸùÿà‹¤?7N?ñÇWb£ÊıÛhò=
O+¡ÙÄ^™ºWz);Eòîô‹¯œ(ÉòPÒkñ[r±HÂrºã ^.RR´òĞÙ°2?fÚÅ˜C3Ñ~Ğ85â²+GpºgëÆßk°)£ê«®¹¸Úl,­Ña?÷‘¡J)G¬~C™ö®¼¾„(\_¯I½–.§E‹Ãõ†Ì-3k.B	Ç`Ö[£·{¨‡Ø÷ÇYD{Ğò9éùg|å7ÒoQÊñÎAKPëx¥‹ä|q£ÿ9İ³I‰±A3Æåg…ûVj@«µÕ–ÊÛo?XÔå	ü¼1îİçŞd—&Õ¨ëŞ">ÑT‘ñ³|!¾éîâ6ÍuĞAv §.õÄÅP´·9[«F´»‡~áuİˆDàì¸GÃºkŠ¨»bmT—´5Fº‚v¸EÀÎµ \±ë
$İqûªi$/·ëÏªïÿ½,•K	F¿š;Xœé@&!W¶  Ú¸ÄZœë*FQZM7ik]vª½&œb§9ÊËŞ·oÊ¨å™ï¤ô¥Êuõ¶*Su/@³ÿ[USıñœ– ˜mçßgZüd5òïxİèwå
W©Š&Mğ©6òYÖE3~G‡Í±±û• À­“çOô¸«],Öc4S3è™Iı%q1	öph«´ïßtË2-]ly'¦ÜÕÿ.ÄWá¶ÒÉ?¬Ãi‘,gs<¤O$Yš±—v{Oçé™ƒÄKc×ælÅâe˜ÆAá`7Q ö´ÉFh	ªŞ¨ŒÃ§Bx	¬y)oÈ%9Ò$ÍD¸ë·BÆÇOd·KÌÍE½fi~Ç–î_[Ôd˜Şåıe3w¤7Â¶J+˜â‚²2”}TPoüL@3- oóü¦« .,Èì‚]/¨rN¹ã4Joù/Íg•àÀı—ZâJ×®€gÑP»§ŠÍ‘”E!ª¹©€D¢¶ö‡¥\ûŒÇÅğŞÔ®•ï5´»zùD)LYxõvw.„ãİFŒÀCaå¶m bK#€$µ‚)<Œ'ÉGÄ¨§¥ï(TöBÙ_¬Ğí¨„Iãƒ`È†XŞ(îj;&»40wxºÇó í2‡ıÛÅÂeªßY)öÅ³Ê[Æ¢éH£C2óW[†e|52Ö–Z¥ŒŠhğ­ø2ÙTì)ĞîeÅqx)àÖ¦c¿[IwŠ14G¶yZ”ÄÆzíª¢îàñ÷Ã%\ú÷ŒIŸ:ßPhZ-²û76ÆwC.5ã+EãôOpº¯ÔµoJ;¸@Ô—ÂçÀŸŸÃdĞRúäìu-@•*$	CÅâdJ†9Æ´¾¼Î?TµL4pötéü	
æÀòËGğj«C6¤5’h7!œô12Ô]á§£æ×ÉC×ÆÙˆgª	õEÎ÷£…¦èAŠ’ú“âåN×…íË×±©÷9à–¸Å>
?Å>6,E±X}¥0¦øV"T!>TH({˜V×‹ÒÑMP|GXBKög?Ş‘}O}´°™fW›z*Áª¹½O˜|ø€Va UaQ²4ÿÆüZI˜«ÌÍ°cŸÊƒx¦–¨„5Ÿ´S¥•GOV³J£pª¥ş¦è°ßŒ]\ÿ’–oÌk=XÔú;øÕ}-éşûs}\yö‹æ¤å¤sj‡½ÅrİÕ]›~Ë'Ü%É"Òc¥·zøÉÇ¯
‚ª÷Oîí-Ö„ĞX’³‰¹¾Âã£$/TëbI¬~hÁ'°/u¨°‚úMnüOâœAALH©OlQG!¹„Ù¡*P‡kw7˜d¯X†ùw7‰ûãş¸ì)©¡ëP5Ëö±óÀ‡³Ñ.êM[ª ³k8ÏùãsÊ©Ş^˜VÊ¹ç–zºğPàøèÏgã m©»]•>ğ;ó²‚¬´Š1Şª4æ¥²ºëF¸â	ÖãI÷Ê»$ˆÅ!0¤<o)³æxœ+R ö²µşföŸm‘ÅÇ˜Òø¸—ıÇpa†u‰ïÎeÉúÈCH3‰2ı2Ù†ÔöÁÅëÅ<NşÔ£¾^¢^û’†Ÿ8ëÛÆÁ)D±Õ:ÁM÷@Å,h µÏj*”p¥ÖyÁ ÑUWC±|Mˆk\ÿ%8Î÷»àyMÓ¹vp¦ëŸÑñï¼—|}ÖÕdÛcãldû"Y!,™(‹qÓ†…"ªÜzeŒòÒ_Ê$·²âçw EÈ»àµÔ3*Øöê¸Bôkq§Ü1Ê¶À3Fˆ„•ÂáäGìıÒ³8¦ÇH…S$hj =¢áClKş|¹øHAÒ#ÅÑxöÿëe„—uãQqg—ÊAÈA*<»şf?ô 
¾÷ºƒÂ‰7'QpìıI}ÙŠ‚á1ÒÓyáŸ´c§S0.—’~ÒêëË1>ú	†¯eïƒ@bqj©Ïf©Ã:ÁO´¨ØEœddŠBrÔÉÂVğh1Ê¾‡[ÎDÍU±àD(îNï `fïÖõö&3ÿ:â;|kbåæuÑlƒêÎãùößIÛˆ«ÀÌ]ï ©w×Êğ­„æ”Úà=yfæZƒ$CÊhFy¸a&¥|2¡®e†P40çŠÑÆ"ëüşøª*Ü’‹1?¨h³Xı©H“Â(šWŠî?u=Ø_ìkĞExR–F¯[(xjl_ŠˆÓ'n}¶ñˆ{²Ûâı84ºğÃ ëÚß4"Cçc¥zîû—ğIk"FAÚt&…ÎC:åÕñæIı
Xc;ªôZ4Xf¥C,è™‘pÔøOõøóªºOvÓs—¹Á¤»/¢z?×ã-ÿÌí¸Ë§öŠmCÙ1’¬ÿ–³Ô‡{C¾‘@‘,E~î"v`csJŞ¬>ºHXDk¨ã¤2Âª}ãhé•ïs»©{Ó‹|”vo!	ø“¶Éó‹Nàn-Ëˆ.â/Øğ€ä3‰¬ş™»t_´6[‰ II%9İ]ãf¦¥PköÒƒWpWù7§óú¢x¥(®[œ‡;ZÖàä ·¢ğ%Lhß/ä.íglR‹–iÆüŒm×¿¦˜8Û¦´ˆ­Û*)èİÔÛĞ¢ÃG*~ÓÖP!c(©ÂaMt©Ñ4ßº4ãÏÒF„[qæTN]İÔ¢ú7üá`.2PÉµWû‹C(‹V|pL’Ö`0Êş)¹Ñ[
e…î®A©Êá¾†oÒ±/²Ëõ[.¢«b~÷ìvÈ7Ò’¢;f5¼ø&b=²*á¡d"YI[;'Œ—€}©œhcT¥ï1ĞÕµÚ‡Z¯¯ƒZJr©äÃ„p,Ìİ½p@|û9m¦Ésš’–á‡ÃË™f°itp!úW¨»‹)È‰—E›õ›—àÒØi,Ñ6ƒßmYH%¶(.¿>¥ÙîãÅJ¨KæÖmie¼×#ÑÉCª^‹]q»†ËŞO…Z$¼<Ô…Š¿A“ãÍ¹wç]Ùê$:T^h¿²ô¬èI²hÂ´&UÑ†] p||y%¿±Å×Rí¼Èñ¬9—*GƒƒøóGM1‹ úÑôºÂbƒDRØ„6…i1†v'z³JÒ †ëŞsö®ª.¶.%§*„ÖÎ—¬E”š~…N2ïÙf8äFµ,ı‰A£î½o½·eA¤Ì°¨È”•A¸£Ã½eQ]†r¸Õe_¸=Âlp!9|È”YÍBe¢àÀêö!Ê•ì+N^´ÌÛFNÒn¨íH¡Øû6ŠV•ú9U­û÷±ßnOšL~„ñæ„²+
vİZ4ˆ=¬xıJ‚·_$j} äwÎÿ†¶²–© ë]‰Òæ€ßg•#g3:æ®0L¶¾Ú¯ĞÔ™ÀGCnñàÓ¸ºĞ›BOY|ö¥*)I´ÃˆSÒ¸‡¤üÙFîçËm3%,+òù–I7º°÷°šà†Ç^2/½£êïå#±Y˜5ƒS2˜¦HP©‘ÒÈ²zši’ú]]Z"äÍÈ}æ‰;ésïÉí„dõ¨¡ZRR_XˆÄöOã©4å2üù>)áÃ‡Òî¨2@=»ˆ¼kêhŒI•FWÃÑXÁ>]…6sÓ4Ot­õª3q"b~¸Š3cx+ÃØ¶lWÑ‰ îÛFI
} µIA°Nş7géX>ï6dN|”IvV(Ù#Û?1Ú;í9B1
/	¢YÎ[3E1Ë”¨^î1ãâUvà±b|×y†İóA„oİöRXãóa‰©²ÛKEö_˜»ƒ:ÎT`MB_I{c.§‘hjş÷Ï6&c~&Á‚šr”6í‡'xi° ÌÔù¯¼¤ó'²Â}Ñ”+Ïmœm;YSN¢½òèœÚâ¢3ôâPG±‘CÓ%linÛş´Hk”ê>?™=„UX,|m)G Ì¹¡D½õ|ˆ+Væ°leh‰êËÍM´×è˜ÌúÒ¢›ù©È+ù[¿ÑMiÌ—ï{4;ÂÁf€qj±àû‘tÁÁ©OcEáFˆ†­víWá=¹a^2S¦Ù$ÔŸ¾ÉêI3¾K	±¯ãíƒL>ú[göµÍUmÖĞ¶ı‘…d¼ÚNt÷~4ÓÀÊHŸµÚ\Îkmôñ%Àê9¥ÜI­¿&¤éqAD[thH•—OgºÖ°e™ŸÙåqÍŠJÏfz“CÌô4	–­Ræ¨ ‡R »UZ5Û—x	D!.œ›ÀcI8M=}î]a/ºPiÂa·Fğ)úÛâ-§º§ş	åÖÖØ¥wf¿gçÃ%º×‹¤­Á"Kë®~Ôú=Â÷éıZ¡•Ú‘tä.û¸±c<’BšeE–½Çÿø’Lñ—ÒÀˆgFW¤üÜÉ§Ä½HÆpälŞT÷²?×ÑÒĞuMYĞ½ñE}˜¬o„×ãcàaëk†»ã©¨½¦Ò2ƒÍ}„Şº>Ñ=7ce¯8 ñ?şDñ-p ÊdÄÛC/Óõdì]6Wàß@<$¦°ŒB¨™ Ù¥¸ü•8°d_öÇf÷pT1ÛŞ¡·zò•²ú÷…ˆµK(´W¤±¤9jä>_¥4"N¬Š —şÕj8¨:s„íZqgD1XX„5|GÕ$oë…øÔ8¥¸ÓØÛ±0š‘1i~‡©ßbÌ²2¸›È#ZsÚ]aD¶›=lÖX¾õ+cõ×Ó½˜Æ˜yæİ=æ¥hÌp×›1İp¥k)oígbXM<…Ÿfß@B¯‡]|K“dâü¡åpÙáñz¶õ)Õ<}_ßáunZÿuïçÀ—Ô1ºª¼®<«ªÎk%ó@å¹	ıu˜y@æ bè5o™ÔÅ”¡_2
9y‚\éÀZ¯%¼™{œ2Q6ZôMTMQƒøËMb•€3Š²çÔ#,)î¶ŒÑKğ!@QHÔ…mÚ…X O–Ùlƒ—KL²İÖ¶~¨ÂáÔÊ–3¸& uÏWœ@Ugüµãê\7Ü¦vĞóÿ€2N¥pœË°Ë¨_åñgynKg/¯.÷S<^H"å®ÅöBÚ}¹µ ÜPÇM-=½NpŞß•³`,‹Ú„ZÅ;ÓÊ&‰tşîşC8eÜE¯(pM>ş®ÀĞsÔò‰$Ù ÓZ”¶¿T#…=6%6ˆvÔ_vm£RAUxkãŸÔ"ò@%xuØ'mW¨ñ šsNÕS DùCs+*éf·?’†Ñ±B)‘¹!^u€»zk@Zî j½ÑaP5q R1LV`;®ÓûôÈ›ÿq)Y+äœÎI°bƒ%n*ò—ÂuòBYúú–øŠ´oè¬Í†j”¹[ãúèx©¢Éë4+Mû5ïµ§(‡Š-‘ aá·võ’¶èÛU¨&gl¿k~ùÅ@—kD§&m«ÜÇnVGSuzİËbÒä¡ö3Š§ÄµR¤]éì=t
@/aòôÉå4#•¶ëÑı”ãü×ño_Ì´³Sj/Ò¬%´Ça¸µ´t™iíz8R&È|Ü{'¤Ç¬;ûA”»/B'
ËÊÃdªÜù?›Ã¦ï´k¥ì×*·Œ Ï"‘+l4=Ú-¬şu‹”n\
 "Q’¼	~n°ká¤I‘#‘ıaŠ¼T:ïŠÄfğWÍI48:€,[DpÌæ‰3ém=YË•ÅM‘tÛAx?>øé­¥¾˜åJ2„h [Å&ª
ß4ÆøË‹Vª8ÂR]Åj>·óë!Í«è÷ÂéÈtîÓ›™oKòşU;,”6‡³J7AgÏ$ã.‹(è)H¦#‚‘XğÔPO@£l™±>0rl¼hòkÛ¼®è„øßw÷ñ[´úè‡AŠhw†õß÷à—Ï”Ñ¬j#g}Q‘ÇNÌ!nÎi]¼í{¸_˜8Ú-/'™qiÛ±&{PdÅïÀ®¿n°Ü´ÈŒ¤|º?é‘FÆ–gÄİ×Fàe:ØÄìSá Õ¥kßVŠÌ(ü©#îEeL8>%Û»!ÎÔ‹;ô“m‡Ş4¡Í– v5Ş¸”í÷'x
Â¢=Sˆòÿ´äœF02%Ê‹Kg•ºöƒ·1ÓÚ=çq¸måføV×¼®¸ŒrËÖw™õ¢9{É_Yg -V2Au¼¸`ğ0Ò‚¹İvØN(!@éÿênû¨R}StóB=­”xÕëö#;of³63¦­¨¿‘7¤‰¢vÎõ¶oy%£Î"AYéäY1S˜\‚œ)CœÆ›ÚØ$Ó¹Š“‘-‚r6Ğ{¢“¨ê7ZTD9ñcB.:’¥4I½Âm;^a¼RäKOc•ùÕHÄüª•]¹Àè…·Ï¯«(ÙXïİæ¦]I·eüpş€ ½ì>×QµNvƒËÈ¡E¼z$ĞëúÿêŸ¶$ÄP|~=¼Ñ=µp$†MfÉ1ç×£8]R‡œğ½{173ÈÁ»lñî¢÷µ„¿ÂŒ¹ïš|57oaºIÇv#îM|‹e»“ÒI™àº*¤
&_G‡æÖm¢ù#£]QÃ¡'_
L³†Vû`]Âş~ì8Ì–wŠQ˜b£2o"¨ù†‡îœŒ©€øi«:UUA}ô “:×¨ÉÎ¤©œàœÆ‚eáêWtg(ÙHu» ³f‚1ÇÕä| ƒ@SãÓÕ§
¡×€ÄËX·ò&\tä¼97ú<•~ê¦ibÍV{KŒ.?iFY"Ø¯PS1ZœÅál†ÃĞ%šiM‡èû†lÜfÏñ3l	87[[-h¾Ëex¼Ó|HIs]l½´ÑYøu]’!l§5ZDe[¶ ?/,Ò£¹RgÑ¤xãµ.Ì9È~XwÑç­ãÜ]¥3Q­h-ÖRÑX…IH‘£Ğ—Ë!I7¥ÕõÕ <vå×¸½“¾œÓL¹ºsÆ(_õG\Q>n‘pÁkX•øí¸½ğmÊÛ•D¼Á2)•©ö}–JÔÊÒíõŞ—æc|ø:ùg á2²o¦cÌ$ïv×S¥ ÌC.Ÿ.½ê,J5ÓÎäsY¢ôO×…7bsçÕÓş)bwì.+§c…€tª•*2œ7ŒTš™şŞNÿø¸õ;¡}Ïy±Fa lYc¬«ŠØ¿KyúpG|…¦ûö4å¼™]$!ŸØQÆvÏÑ±âŸ"…_‰ŞÇª_¨ØÀAÓWbí‰0˜®İ÷Ûwú.zª'ğ°ñ‚r´½¿é»ør)bhlÀÂqnè^§„ïSì.ŸÌğæŒû&æ¨ûäÖĞ’5zşµ3+œŸí†Şd»©!‰ì‹eiòj8XwĞ|3Í·™ğÉ÷Ù.GS“.ªræPåİá7ˆQ“†ú9GïJÕ/d¶Gˆ˜æÚ¥Ü_+WlYááiP„ÂÎ ‡Ö<˜û·§º´ÍºZ(ãÕõ?±šÁAJZl­w8 ¸4¾3­Dœ(áÒkÛ.Ø:dWzåViNŠî×mSÀ¬ïp½1–m÷Üßë¬¶òòïvÎ^½#â C;^Ô/r®Dì§#©HÊâV[{ô5•ù”\§ïHœxÏ ;ÿœ—£ĞÍ‹4’)ÊF‹:PßšWÅ—ìVEiw <¤’=®œĞdºß°œ¯ñ Ó|Øb"eöjæ™6¥ºï¡j„_y!´‚íƒ…ùKÌÆQ­Îß½ú1¯x9ÿÌ‚éÁ¥Ì5šsÃ‚Åæ¸ äê3
k,œ!ùW2”ÉÍ‚€ˆhug|FcËjİM?–)<PÛ‚WÇ®’øîø66ã¼çiS ?2ä•Êü¶nzsØM$Ò«?bãöù½²ØKà?ÄZóÿ\Ä9ù×M‡‰D}ñÁ0_bæá$ŠwhF*¦<>R.ºïzxPd¼Ü²u€àTkêXøŸjfC…fˆ¼Î‚3öÌ;†õİê¤aøQ\š«·c–Ğg›è\ˆì	Õ eBÃº¹_‘»³{o–òÌhCû)ıÃJv,§®°c]bmxmÏóáíÂ‰Š6pRÄæ»ê5cÿ8îÅ½TºÌÌĞß›IÿÖOûBv*H;4†ò¤W(‚gÉ¹ywË¸Rt:ÀãêŒ¶/)&Àˆƒ­rØ”]CBº¦Xœ•¬°Ø²È§·…9‰×;zVo¹ 6´E‚g»|›¦s:F<@)‘’?S9¾Ì=Ïô9Ä~å››9;.ªÙ5zGÁeenÕ Kü‚P°	Pvì¶²IôE3è´à¥òİï´Ù®å	åŠBï=‹ÑúpÒ<ÓÌ7CÔŞ5«Î¿lİ^xWazu„ú0Ù‡¸=-¡ë>Ø«|úÃä0ÂÍĞ[?ÃURmÓ«CAf‹Ÿbl91«L9hkáYU©„ÆšÉf¡Ò.,8p¾±˜Båˆ%~o—-øİm€-Ìı6½PÛ2ÖDJfœ2w¹êÒ¼À\§è1lY‘©¹Èë)±<‘KÁ¥ô“l¢¶¨£+Ér<ıQÎTŠ±mÆŸ§>#9­ıÌ;ÉçzbÛ¸3vÚ÷=W[Î ®oŠ·Ø 
™½’vuŸ-¡3‡ˆmuäã)†ij“íW˜LW÷YÅÆ‰ÔV«%†¨ZuÑyRàh<sŒÔòÊ02ş¢ØŠ®µiÏLè0iænf1‰YöæXœ«Ç,àÌ@aÓwc³ŸM8¯Ó¸ºL{/_ûc“"íYôí¨"‘iqúÔª3`jkwt~–à°ŞN=‘¨U.‘ª‹U‡x)Ú
R8m õ=…H_ÂÄ3³C¬Æ÷Èæ¢#Ë‰Ñvr³J9[UÈˆT¢ßºN¨Õ[dí?àÓGÎâ‘Ö?‹¥ßGL…+¿’¦”¥Ÿ¢L ò^kîX (ŸØ;¥zÿYZ{Ä?ç'Mja´ou—ÿ6“äæÛ9’vëÂ„kEZ&±ˆÖFåmc îÙK”t¥İ€Âçíš»4·!gp´Ã«³ºPËëâx’ï%Xô—"5¦U¶’†ø^ëò³}vYFOú7b?¸ñâ2¬$oÍÁXa}ŸHè=³ÖBAÿU;è+*“h˜EjÕ¼•¹Uõ{._Çój«ü4 2Nw©…Éü*ITûdÔ«Iªğ~¡ïc;ŸÿñcÚ~Xõb?õèÖF²ğ,EN"é]Ñ¨}¬Ø{“çN·2$tÌğ1…_û‘uòŒ—Nc?WÔM·ù‘íNvTÛ_qFD‹J) ¢şèÕGH	3M¦™Ã˜x;¥„×¾_ùchØ&³UëN¾È('4	^½~bïÃ²„à“Ä,ÖwTŞÌ°Ó9°£mCÏ•™z”°‹u9xFò-_½³1¥ózøĞñ[šºğô&Dş [c‰(&Xzı‰ ‹Ûƒı³aÄÙ¢¦šúÏÌŸV/M‰`óWs'Í|Çü”Ê­à5–¬	m —†@–Îš¯Éµ¹°@æ”h#e¬)yÑãËcÕ½d… Âz»äd¾»0‰ˆpğ¼Ëæê•tVíÇ*)°ª£}úù~h
ßö§M/\Ó¤nğ9“äTœvXßG88u¨œ ›;ÿ©%¬<ıói«@¥É2š…˜£€Åª<÷mÀâï·şİµÈÔ­£chXåŒé,õÆ]œT°L:n¥Yeªé»Wèãø	ÎdoPª>Y¥¨ïîK×]†ª´Ïßéõc!HiU'…ÚÄ7|.ëŠH¥±ş%“ÿY ÈçHøâø×øõ²d¥SEÎDD wÕöå´ío]»Õ±QjÀ[ì“[•'Ã(İñÅŠœËtì‚úÓ¶Ó8¬‰+BjrùÚ%Ë¾R`jkíë<{)ßç	˜$L½HU€ãÜÖZÏZ¡Sh{Äo?ıÙaĞ…Í§Eo ½;—±äJó‚a&á¤øúEhOUÜ0H«Úy¯Ñ´bâ©ÍZHı1À¶¼Oe¨ÙØÍ—jÏrCÁœÔÓÃÕH5ÑìP|LZ©AÑªvÍhg¹<[4k_NX¼»Oøíå
öZHRêR||šrëÈx7KpŠ³å§
uœàğ¦ÌÎ7üPğØ 
L^ÙI¡=H£Æïò‘+FÖÀ#:Àü5l$öÇ7M¶_@"øâ.a•Æ“`íœ¬œ}Ï˜Vi!B"ß¢ØYY0z‚æ\Š³uXä½ª¡8ÄÖíµÃ=0­·!‹Ü¾y&>ZTøa‹ôÜ3dyr¥ˆÓï®¢’ŒÌ—ò)z-gèŠ±)œÈõ*TBâ-½·µ’ÿÊİ×¢4Öé¡(ôh»	Û³I -otåÑïf*ó,<×ØSW]H·†ªb<V+%’X.Àéµ_äÄd
\]Õ%¿o!SäL?öôÎµ&u¢!’ju<B?²™•g´£ßÔr½JÔ´(’´ƒ´ùc/©R'å™8yb|_ eü]ßjÙÿG%é ‚YF´E{ee·u/ƒÄwó?AL+‚ç‹†×Ô2"¶â’]åÃÔë‘6f3ÌeÑó¾w(,´ßŒç´"’aö=XõDØÒÄXÜ,&	6J77¹ù›Ó,]~n¡Ò(ÙkïAª2<šƒZ+|¸‰å¬iÉöÈ¹¢Ñ -°mI•r©òÕË€1Ü¡ü™şl¨Ÿıè('š1` ÷Ìy¥ò{ÕTŞ¨ÃÛ°gèôk-e34´0ø4ÇÁuİbĞ~ÖqØ…Â5¡z$Ø*WÏ:<ÀÖöŞu‘–ãGq=»ô	¡ŞŒàhÇôÌZşäÇÉA’j_C3ª{{.÷ £èHªûQ=©€˜lg€l}íÚKu·1BA`¼cóí¨³¤Ø4g@nTéÆ:@<?A' §(m£ºÁÛ¼…ıIÓ_|é…ÔH<uÎ+lDWD¬ÛUy¬‚ˆÑ	RKÚÍdÎó§7’bAc7®dËÅ[Xíµ¥ñ+tÃ–)¸Xú¾ßIJü@¨İÛ K)2%[R\îÛP˜$0Lâ<x2>Œ€¾»’×Rßª¥š*³r4Áxv¢Ùxäè>·YlìÍ@j5’IqûßA°¿ÍPFûYj™>a2CM‘eÖç‘H"‘)"ZNûA›Y±V9*+óx™KµˆÃi…•²—ı[ªÇ=N'{êvÇ•Ä3¡=üç+
‚¹r¸”´^‚åbÿ/Xıò—Ñ€<S´,jˆuÉÈ-8wéµ®Š§Î,ô|^Ÿ*(iÊ‡-¼@öéöğø÷ïª±Ÿğï@â¦#Á4<[[nM@ç_
/Ÿ}-' ¢’»Æ/ÙŞÍƒ^ŸÖ ªÖ‚ÈÌ€Aæ°yWÒ;=E+°Ã2O!R¬œ‘ÙìDğæ¬È£Ø»‘Â<«ìA	=ÇÌåšE¨ ½Gèà°{ŞÌŒ²¾ë¼Òbî´«ªfÈÄƒ]Ä¼ûûö­œGe»;~­âª;.iœ=c¶tË¯²şøì±n[©¸QM^†ªg^;Õõ8C;õÕ\ÍVECM*u|õø¬½Ä+ö‡Õ÷Ñ¹ŒÙ,‘,€'³Ô	ˆù ì1qº1vfka •!Œ05c¬LapìPChRÙ¿¨Y1áJ‰±î°´.z‹Nİ[™8Y^[ÿxÂËÂ"üÑˆµ°º\j¬2õv¬SóónÆWv¨ÿOMÇİ}XıÑİäeÍ€nr0õ€‚’×Ş×¹wæ°Ê€f¨ïğœLX½ÒL7%ÄŠq§ØÆc¥Ü>5'^ıL‚eN±ˆ^2Mò 7–è¬	°ìæ.qOéí¡ÊX†7ºd†Ä*©¡C+x>°Ë’6{Ùçò¸¼¼}ÚœÂ••Ëiºõº[ÌŞI”ï$PÜNéš™½=äÂkl8Å§mÅ¾á®~®XÏšMÌQè·ìØ.Ä°áƒóÓ´=ı%#VFTkıã3S5 	LZl˜1p]ÈTv‹}:Êû“¹Ú¤Ê`Ÿ–÷x°Ğ²E=Í7a˜N¥óR¤MQ‰ei7Ö”‘º›px@ŸÛMïii“ƒlt}LÀŒ¹¶XeÙŒaØïè³AÒÉşÜ†¡ ˆğx4İ·/®`À­¢fÓÓôÇi¦™¶Ô4EÅp^6#”)guNDv‡rf+¤Eúúa@‘½«£Î¯Ô-7Ûd~Ï¥aÀ’àœ²ÛSª Orä±µ"Rö¤˜–ÄE›MîğM6%!Pz	©Ò#ë¼<Â¿°+Gm­ÔüÚ6£Â±S#­íÃÑ&Ê
Ôßè†?6ãÁäKãN1Ú¼1G½¢sØyX0÷+“mo° š‹îåd¼Ä:YëøÜéh	|FWdÎÁØo9#¬šr$nçö‰å»f—@âQ¨åÄ^"òŠ
¸ş5'ãk©÷Ô"Çk=^×,>¤§+Ô°2„Ê|;Q©Ã@ß!ıè#‰÷"÷Ï¼¿ÿ%µŸŞö,…âÇi`[¥Ç â±û˜òy ÉÏí• "`áÖéøÅAƒü@ğäˆ(Sd—‡+n€&ëúğÁT/Ù#èô|Õ¸ÒMñÑXn²gpÖƒ3d)‡×`è¦y½pËq¼ÍP'Íı&:8MÍlëV/_ãø†®™üb…åAE+ØÆk¼Y˜$"íbŒ”eôEÓ7Sàd|¢_ø-r´Ø‘­ä‡S„ó,†Ã­‰ÔÁ¹©êÖm® °¶jcÈÒ¹öyØßtÃ¾‚<6%§àó›¿êlà‘Õ³Å‡èÀ§ÿ:Ö4¨C™Kÿw,á3<:3Ş'=q;”áØïĞ{…0Z=$OKH!¥âU¦ôîÀAµf¶1H¦ª•ìÂ³ÉpíıI²¦>Êµé³h¸oGGš%úKÛÀ'EŒk TÉãÙ †:€/ä¨„*(‚î¯8¯Hj!JOøhğæ»oìÄ^)°¹WœitfëyA-W 5sØIŠç•âs@˜£‹Âä;M6V‹p§p/z;Yà	öóhÜ©M9!­à!,şÏ_…¯xh±Íc‘^oçS3¸²²b9ğ g,šfÙÜÖæD[dĞ›¤õÉ4MÖŸ™]­âKøÂŒ¹KTwŠ‘{ ‹Uª&¹%EËÄb+’ä¾Ãô,=²—·n`fpj¶;Ï¡¡úÃ P¸Ù·ÉzÆbÀzùºı:wL37b‡º¤?{á»Œ¹Ìá‘¾­ÕN@wË°é”E 
TlWÁ-†¢zÆ{x¢Í€â§€Y¸¯^ƒQrüèeg+òğ±´¦â¼…İ4§Æ(çT;ÃĞğj,œV¯Ëîš 7uñBOXŞÑ%¶s,N33ràæ¡#o¶¶xNS¶ë¤Lí¦Ô=7‹	Õ?<:&Û<n¸(àPÌûÍ*!Úf¾K‚*ºO•u8¥a¯7QÙÌ£Rã(Á‘ê·p°l£8œš† É¸å	BöI<¬\¯¸ˆq÷ÁáÂ¥PaQìuÄûáÿˆõ£t!!q®É#øc™åøÈ8X’	~¼ğ½Ğ€i< -Häà '4Ä}@ò`ÿ	2×T€İ•ôÅ¹ˆÁiÿÅ4	‰æ’Â»ÒçÍsÓ©‹,İƒw—·û¬@‘ä­8à@ÖujÚ€P=—ŞºÿFƒ‰bŒcLÙ×YŠV	Y½®g„¤¡¤²ÆW1Ib|1¡‡ƒD®–¹%’í ¡;ßb1U‘NbÎ)™£÷ôA{‡ÑŸ:¬›Cf³UÅxHyòcM™Á{< ¨d<Hîs¨.¶‹çßµ(~Ÿl×SÑ¦ïjhç@ĞJ•”ëõß¬Æ
M1û°»=Ÿïï%_®ê€âÀC–ùŒ·È9 \şÑ`Û\ØWƒZNJàò2 ß4Yf§Çªw³R9Bc:ú!£™ä$ú`C ´¸§‚z|5ñ²Ö)¿1RÇÕu›¯O•l›¶P¸f§” :®BµŒƒ
ÀÒ!ğğ"Ó~ 9×PƒÎ%-€±lXÓ¾È?N&Í‰œQsÅµV[Ûş Eƒg‹|MvzŠ¼ıÃ?ì±ÄğHsçbl–"¨ô‘^yf°œp'`HÇõ…u‹ÒÛ‚™=óì¶{<}1üı®‹ûÌg:†’zÔ½Ì¡Ô‹6ƒ—èn¹Ûq´ã‚©9‚åÊ}Gè6ÓY}á¬I;o¢Ó¢6àcÈÁ•œß*ˆƒé’\CÁLO1V9Í‘À*¨mü\‰³è¿´6yé06	-~¸²•e;–b-÷³ß¨¡¹ Òôôyq­i3 g{Iú€ñÚ nºãƒÃº+m÷>qã¢Oõµšé7ƒã FÎ¼nx¯NÁ,å*Pú;7nÅFTİ5¤5"O†Ÿ)ÕÇ5ë¨úµ£fÛ{ïáz×WÖÈğ-—Ê|'n¼æV¦µ²¿ËÍ‚`ÁP>t|æÄîâ˜¨A¯¬ëû ™0m³Q·’(¢ø½q^%´"ĞTÖ›émş-üä¢Rµƒ@À#¯—b4Cîò½tÜ“F•*´Wñ¤Àİ§ÜÁy—¹;Ç^×R¿‚T(aK[¾É<x%5\ ÔÍêóR“^Hùıš˜RZCŒ]ów¸Gå2Fõã˜)     >›E3ä ½¿€À»uû±Ägû    YZ