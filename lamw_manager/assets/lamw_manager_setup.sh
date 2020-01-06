#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1877483209"
MD5="104e6183c869d6dc4bbe0bb3fc28341e"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20364"
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
	echo Uncompressed size: 136 KB
	echo Compression: xz
	echo Date of packaging: Sun Jan  5 17:54:36 -03 2020
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
	echo OLDUSIZE=136
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
	MS_Printf "About to extract 136 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 136; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (136 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáÿOL] ¼}•ÀJFœÄÿ.»á_j¨wâD>¨v«×\$kz,[¶K ¤câº§©æ¹ÿgh–Z¤[gjé¾îï(„¬Â§UXje(DK’Õ”+š:V‘®.“'mˆ^ƒ‚„Z¥ÏXóÅœÙØ6{€+ßíºØÉRN´»Ö)÷Ì@ß6~¾Wß`á!ÏÄO}g"~ğ`:ñúĞ‰*'`F¯ÚºÙS}Ãtí°ƒôºŞ?ê9´DÈÙ€RØù¤?ıbWNÌğbh-«z—£Øê›	¡:B7­»yd@…ÀŒÄ/&.ö
ÔA ş¬ÍÎ£»Õö¬¢*¸„n>D™6Ü»RÚ$	TÊ^Ã¿è´IÍYô Ì÷c5#00 ŞóØ™ß@×b~:«£1ƒ‰oö~ŠS;f‰äúÒŞq°ÇÑlX^ëj­Ü[` .bÁèË3XL¢ÈAöÏ$Ú_Ğ ÷¼7©©ÎÆ'Yš‹£æFíG!ÚÍÈŒµe"ùaË÷Æ²Mç#3çÂÚîLwo6©œ‰ŸŸÇc¹=ïÎ„½>¹rwì—çb®([ÂE¿©†élÅ*FæC9FÇAû_ÄòŒÂŸjj‹ÚÚ |ö$Ó2ÔrM :ê“+,1°Ñ5RÙG(ëW_’gØvqÁ
W£·yÕg|Šñ9€=û;’¶}•˜ƒÕz»\j÷‡2j‹Ğû¡›á5¬ø´éQZj+Zí•†•fŞ¨âËûG<ÎfJükKnKWAO*%»‡ÂÈ¦0µˆöÉ>¥©èÔµ¼ÄZc£º+¸ıjkÚ¯ÂJî(İR½Ñû8Àî,ùGÃW!dZêgÜı“ÒÉ.ÖúOº#sÛ¼OY;„6Æ…pF*…(cÓ{ZçD Æ‚îó™mE±KÔn„(«½¯G!…‘ •`«k1¹ˆÑ¨Û–UêÉáDé—.d|,ù÷Š­†~åëG§Âc²×Ó\	£İFËˆ3SÑP¯´~F <¦|C§=JLf"§Él›ú78Îf¨~Òoº¢mÍ±¢l-,AãOJ¢Cê¡˜áŒû©;(dBXn| Ú-Û.I¹s„pp'®¸ú±Äa„¶d„RøÍ[»˜N ^VG³®¡L®\|uó´Œ±¼ãÏE˜ÍA1óvHs…Ü€
mM‚Ì‹¯ÈÑ©¸åØÒÇ­älgák|J3 `"EéÓ¾Ïí¨bò½ƒ“ñ·Ÿ×ÜèAçFd…"d½ù6Ø•"ùÌk¡Á±Z.Kıî4Dïy±Å°n_ı§›{•èª¦æ9Ów8¢¸ú{äšgâö` "ˆÄ‹Ë‚¼sWÊeµù!D!ÿ˜Jn¡‹)zñØRñ}»Sz;†'¦”üDv&¶f^ãzgH\ë5ø±Q,ş‘š¬®OäÑå§è¦©è#UFµ­ VÊğgEÊ)“Zàk¶ÉO?‘ZñÏs—ğ`óT~f“ŞS®¡P›G1õÕşg4™ı´SNóï$°Aºî5ŸC®ÔÛG85:Ö¸ÑòŞ]Ø‹¯÷®ßÏjÑ6ŠÙ9VŒœ, dª7Ëré†@3¦ÒƒâÜ²ô-æ»=>£Œ­-Ş0s´ß­‰«Ö’k\Î§*’”£ãV¾t‰nè³aÙ@\Ê¢!…,òıìšƒns¹ÖR)¸€(qÏ[†‚å•º1»”İ(²ë¾5[ƒœœ®¿êÄNlêJjã3µçns±ßÿhmOé“‰‰Ãñ)İ’÷[×aI4:ÆØe¯.9B†ƒ#}|³¸›»#m¢ÿˆû¾DÈ8K$Ršy°9ªEX'Áğµ?±ö»³¢ä
‡†<R·sIï¸ZCp#TM~óã[¢¯'«s@ Ø˜#lQMS-‘²mü¦}íİcCU}Ò&¬†ú[x:^‚ rÇP÷§ÜŞœ®<›9-¢:u®¥a8 >lt&k"­øz®ï‰„×œä0ºÅ÷¥ÇXdNûª\›rĞˆËy2¤Ì©¾³éU4ğÉQ”t/œC1­2ùÏ²Ç>Ñ®RŠAcw_}<<È—œşFıÉ„‰³
2¹E*Œ‚é´ğ‰?x‚ä”ı4Ëd>i2½?‘6ÿÑwšùÖ"wà¯"øc˜DÛ7•}«ovºŒÜ:³Æµd´*ú¯:Ê¬aEÛÅrÚ{åìÙÇ\Òı^WíÇœ;‹Ô–Ûûcğ7BÕ‰µ¿È!Á£«FP:1—üz„èz·útí–şƒ2/ÁbÛ~®Hs9Á@‚Œ†vÑÓÇíU¯‹s’Òˆ|"gGáÜşaÉópmª"–¼[t‰°ßkÏtŠæ	†¸ÄëäèfÏan @­©ëœË>\bÙşt˜k\*Å.mˆ¹€ÿ€çkANÓ?£H‰å”Z>Ô‡Â-øùÖÍÍK/š	B?é+lŸâ^-ù¦$V€²2^[şÀ+ßöaûÖ9£…ñPƒ,ŸqÔæë€)Lõ‡ëËbkÄş<³n¨Îé®‚À>×:Á6mÓQv~öfÅîù<©dHëEŸ’LÂƒ29	·n‘¬ÔÔ3àbÙ]ÙÅÑ›÷×¥ù‹W¸ôpŸm7†jğ|Ósü6‚¦¬7…ş
²ıLÔI)~”Û”ƒ‚7¹Z{«
€q7;Waf€:‚áq­=EÇl,´-¤Ü‰Õ{M ƒJIo¾ûÛñ¦µš©\+òÈa¤nÄ kÁ:'Áş%¿ôÏY	ŸÁTV”›í&L8ø5úÃ%P°Ü±IpÅ ã¼¶7_êBo)„¼É»àÛFq¡ö„?ÒçJÄÖkrâéÃhîİ `Œ0Tt”£°QEnÖª‹ß·6½e4#%LŒ'È`ë/F›è7ÖÍQmëd,¡¥c2'mÂ;
ÔÎÿêÜèæ%F8¹ğ¨¦ã©´|)’¤zpÁ,{èÏp ÖêåÇ^[ézlìïæ“Šû)òJÙRKk®·$	h|H¹ÍW$bB‘!kí…—åÆéĞS«<’IÌ¢Ì›DàŸ-wÚOldô©¦ëu~ù4d,K}±…zÏØÊe(Ç“,ë¸<WõG·š«Ã‡‘›¢¯jy‹€×Ú,íÂ¸^óD×N/óG¸ŸŠ‡Fœ¸[nôÕ2k®æ	Ø+¥]ÆK Nøï£—@—K„Ù`Ìe¶{ªäöìá5‡šÃ;+˜ˆ#¾Zmrğ“CÄ¶¼ãñÓ÷ÖÒª¶MŠ“Şé¬ïñ‚*ß&r_¨\ğªd¬£¼ía+¸„Ô3@™Ìyÿˆí®eùyŞc!P¢X®ï&·•ŞlX,(ç>İ¢äHŠ†ìÓ"pš›¡›@]Ê
ÎXÄJÜ[÷„‰*PÕ.ãXé¤Û~À.ıì€êÁùßŸ•>Eğ´’…OaHÏ«®hÿD‚'Qş!2:‚ª	I5ï”WšmÌ¬_B‡k^ôÒ«.âZ0áWkE¦/$<JÜ?Ø]ø"e·üMKÃØàŸoÌ‘V)ºiÓn†Í&2Ñ{¸tvj0~ÁÕğ´¡n.RˆÕs$l€“°$sàL_9WÑS1"w-É"yŠµ{SOk@„uÈIc=4Qí!B™ÔÒzØxXô<#ûÏ~2+÷”ÂÏ¥Re4íñ«¤ )&ÉàO-£Ì°rK¶ˆÃ,|uØë+œ0ÉØ"Ë×Le0›èëíÊyû6ìŒNRÀí|j7|d<Mo:–'ü…ê9;Göê]|÷J„˜¡OSí³İjÎİ/œLšÃ.Êë hgÄ€ÌÔ$ÉPÙ"åi@o-‡uN­d9ÏÎMé6u¯{m3mÓ‹ûª9ˆ…êÉ¥nø´õ zy‚ Õljºº=ÊÆ¡qæğ}`XÖµ”İø:ÛA>SC> û=’¥pøÈ=zh‘¾ÍK‰m“¿¯² ¯R?Å5ÒÂÃ¤f+»›ñ>…l”hßš 4şõl‹×_ôğ·v\Ö¶qĞuµÒNÒ$2 áu	‹¶áÀPÖô6Æc£
(É²9#Yˆ…‚5§Û·ù¤†¢Yéã¡”‡#f&¦Ao)ÔQReìlnş?„ú&VM¬Bc®Ì¬¥ÿ±J¥&ÏÚà¤ß}IëÕ¥é‹qå¦âVWÓJ¼öQYtT›ß’‹í¨/‚bxú«G†ğı-êò+«LÚgê©b‘XBH»|’ÚIyLk’HÈÛn8ğ
HòñôÍK+tNvÙA(ªÎ?0XWœ 9Ğ‹d…@H<šÕñ2·’t+÷şbúğ.Ó5Ø!8×ë_Ä°aëe„¨‚?Iåù™•ŸMNß„‡ÎĞ«/IÃO]?ç˜0/œSnÎh½•/ßÜ¦+ícàæç7ii2¸¸6°{°¨™ió mid?×P}JØîgæ?¨l¤M•%r(Tw¡düŒ–ş0ûK¡©ñÃS÷é¡)âgŠ™·Eı;·üûúŞ0—I×Ôéã¨|×™©˜KÛÎ•Ú¨Èi4”	3+ÈºÜná9ıƒfsyPT®rùAS©›5óÄ U[Æâ´Îñylì(òl öÈ6Êh w5jz~
4ñ:H'Í¾ÑÍh¤X	­™¯Ãzï«D]Ç±ÎªV¿:f°¨§¹èŠeK3xğHß¿şéBhà“TãéO“}ß¸ôûâıaß8ÌÄ3­[¬G&»
–3¡(²¤Äa’=Q}Í•¹Nõ~A§bw¶2çnF_cY–½–Ì2-öd_sücËyd*¼¤ë4‚C!¼±´—ÓXb¯‰ÁVÑw'¬îCİ="³—šÃ8I8óìß ¡&›È¬17ğ­¦*1³ÌŒi¥v¦èaGq”gÂ—sƒ×r…*°võLi¦õ ¢„Şa‰ÎÏù¾¼.¬í•êŞ•£É”]e˜O¸Suá¥u«àş±¯8Kù¸ÛÍÙŸ­ìt—? ~ùW`t22¤=@SRV…êBƒĞÃQ¹’a<ÑáG˜tèóÆâéw­¥æ6§•á­Æÿp/–ûgëØÀ $Ú«OUÔîRŸÉiG^óXu¸£c5ğ×â[1‰p³nœq¯[5Ø¦TáĞfR2¨ğ~–ç€`×¾•,Awüs—÷·Ö,?}±¢ƒÂ\£-äµ†±BGp*]OD×õAâŠ—[ÃFä£"AoÔ±ç‡QÂ„Îª)±¿Åp˜Şâò<±»-ã¥&œM˜âõ2"a™1€éöŞ¦	1¹UÍ„`}Æ'èàï¨æÄ"»v§uoİHÁ˜çğ°é9ôƒv¶B÷x©2/OÃ¯YpÊB›3ƒòëX‹šĞ2JÆóğâ*Š‰<æ^ìùåQå=½äÉç[úîdZĞ-)Å]T'T‹ŸÉÙxşâ:2ÏGpYkòêÛ¡µ_èKó‡ŒJá¿ºK®*jEìO*çË2Ö´¡‚Ê:2í5}=™Ë00  
¸ß@ê!²Ç}h„!1ye«HyŠ y õ‚ôÎ™f1a4…Va2\`VÅÖ:?K*2©¡‹a`•ÑÚÑ<Ê>’äiaÑÁ¼ö³VN
8 ÍnÁló©<½ –@€ƒ°%é‘h#¡Ï¯ÄPæe[¼Ü¢ØtÃßëŞÜi^V;Kò4hT6&wÃ°,Œåv	ˆÚö_>~ƒ„o,Ùï]ÆlĞ^í§;ıŠ¹Qsí÷ƒ¼~=q7k0«wÈ‡,¡‹.€á¸ Á1‡lDY¥–Yæ@:yıÈÃŞ‡ızÁeÅ>ûh,‹³ÍB‡^ºµ–ï²‹¿ÏˆoÈÊ³p;U3P£Â¤*]z-î7çÜbË'˜è+ô}mÂ‘õüY‹²96£<fŒí%0 AT/kÄîÿTÏzÖÖï—û‰Ñ¾s~ú.*½;ÉV=¬` FñI-¦k’’1äC·é·[÷Üehz†Å7+ıA¿ d[S,|nä‰M£„ä I¦-¹i-Ò½š  ;D^áK…Ì^uu5ÉŠ¼Œu"¾÷ßrt(Oukö@uqú˜‰Ps¨ZºHe·^·ò0jIÆeƒnïiF°ÂƒTö»Ù–yÒA!Æ)fÎî¶‚WÚâ†«&°O+d&©¦tŞz5EYàn+ËU«ô¦A -ehëÔó\«¾UÃJ>:?=1¯<ˆÄLıuiÌ¤ÏÂ¾Wè|GùÎCåíş5{rÕûdÍ:^XsÒ “fı >c½tBµqçÆtÎg¾ûP6­z (ûĞt™•dBP†ÉºeQV7¼Z‡ıü'£}‘W…$öíÓ¡Şù µ=vÈ6¥Ğõ¤Æ:ƒñ8×˜Ae½¡‰”Ui¦B>œÌh-XÚ5]µL§6êJd èÂ¥©¸Wª„”¿ÍÉG‰Ô|Ê¼i[müµ¶‘÷8¤:TKbÿ¯ÄfkGq×ìØ*^5±Û§*W0¦ßÊÀµÀ”™ï†M-‚oodË;QQE;fJi!ë6f`¦gUaã:KÓ
<ß™a—Ši _–¦Œ‰°á²#1	÷„ëYĞ¯SÓ ,g2í0Tì¹kõ‚ğÏÕöè}rKœÚìá\6Eöº¬ú‰•Ø+Y³Rü‹¸úšß“N¤êZáï™csúú1Õ`Òç¦7ˆÿ{¹R…¦ú£KÜ3ĞuÚ)øS3—ÏÅÒ· H²·{Ømúçì.‰_2ÛŸ¶üıã±Çİ¢9»—èÄ¡Å*íÄú½ìDG'HíJB§/(÷ÓÂ‘Õ|RåªEW-Üéë/Röiµû:G­.ßîÍÀÄ_©— gş2ùİÌE]§…êpcÑOèÕ=š°‰£c3_ŸL‰L b“¥2*²«P×Øø8h™Ì‚hB¨T7É ¦~ê€Õbä¤7|ĞKtÂï³%}”k•Ê˜†«/[ÙÅ4)›Á #ºÏ«¿®)ÌÎºQµã7Îânsµ2Äñ4ÀŞ2búë´'ZKàÙ2ªtgædÂ,ğb•f§ÜJÚó–8©ÖĞ!ÜHû0½^9´N»¸óuÔÂÓî¿!Æ£B
€„ÖIû°˜”F‹.µ½;$Y,ú#lèÇÍpÏœÒ¶ı‡K|²•Qød›Ü…Ú²ÁBËó3?À ê› ²&»-¦¿O¿~–³V¹óg“[8ÀŒ	%`şhRÔ„Õ ¢PgOtÄx½—ˆŞ[z×9IÇ˜•É·+I»§œÈıÜIÏ<‰†×uşénÌ/…)öÖÊŠ!¾äµkXFºú:!c&+ÖXÃVì!‡
%êµoÃ‹Šaƒ÷Ò4J‹ôéH°´­Yçï±îì‹Âµ(õÆ<òZ{ü«1kJ©&ò¨sğMxŸ-KS‹³ğôïL°fãštet¹ë5RTTèÑVz˜2*1“İ,ÜZŒW1.ùaÁ¡QrœÔñP,^Hh=(@,·LËqûõzÕÈ_1µ–Şå¢–S¬¨„›Âšäx-Æü­ ı™'!ìDYT 9ŸÍ‰E;Vh×#ÔjX+XËô<éVVğ~Ò'±1c`Ç2JIDñ+‚Q«ÑøƒF3Œ©şî’·İ¬ŠL1~Kie…HÃÌsÌb8Î~/)räG·`»ık©¾ºËÚ(ãd¯túŞEóu|tpv@QnÛÙû6²øõ29×¹_â†y«7ò?ğë™6Š§Ø"s?à Z¥÷Hò^à:SÒr‚(È'­:Àê¬¶«ì"’kŸ*Éßa:i17øÖyD²Õk¯À2Ïå®#®	/†-¾¢»!Ş²:ùmĞ££cM¡VŞ½•øÅ{Ù=9v}>jy¾_<wÓÃ^ÌÁ~ƒBú›C‚á¦ëèRëµë±]h\W±ö“‡ÏÊ·ššœ1{ÚàŞºOmÖÇŒ°°ÃM¥¹ælj;›GV´ïŸl	vİş.Ã…Æ;Aü'Çc8 ( PãŒ¡Ã¤ï=Â»”ÖÔ@rõ³û,3ÓHªæaé_öøƒcÌ×|„NgÌ4lÆå—s¥O¤R`•Ü#dóİ^î¨+T)Z¼è™˜Š¬1Ï…é)àá8ëcŒ§j÷22‘ÿŠåÃ#X<*Ÿé× "¸f–ğæã\ôÌ¸ÒÔ.Şºå…¦pÉ"ĞP„äÈ†¿fÓ4ÑÊgØÒkÛÿP6PÔAÚ®0êĞâ‡J^¾Ó,jšª£ysÿš{‘[OwÌ¾ÃÇş—6p€üËél)7WÒdÙ1õäŒh¸¨$3çlì™‚¦£G)3V¦¶_¼
K_íª#R^:ó|…^^Ñ°WÔÍ–[‘ÿJHSqš÷­¿’Ì£›÷€·¹Pó_õbÆ.nÆwíµ¦ƒ=± eeÔÄ—&iÔkFu¥Î.íõÙ´ ’ì³±·´&ZBE†ÕHü¹êo?HMˆ	cMJäŠCŠõ¢L’è^îY¦ìÃïzI9
æ©Ãw¹„ÅEïî.ëà3y¸.ta’ua¿nİÏÏ[b$Š¶Å¶ [ T¤…‡ˆQ§e[Åôƒ™S0À=pmnş­
uÄ, A#ı×‘u°Ş—Ä×Cm3p| G94<¸õg9úxøâ'ì(¬?cÉl~9üös´¾Ámú)—LìÉÈ‘ı*?(¼‹Ñş…èâ…ÿÂ¶~…ˆÌŠ˜Ê›vÜ9Ö&3Œò 8Q­æûSl,a$}‘özd±£èESª³~-aK<GädQÃèaág¥O¡u kæŸl>CN·®á½ ²<wÈŞ™>SºÏ@88DßQı!ÏÛë|£]ˆş><;^ÄÌŠw‰;ÜSeC	~S<Ãï¦ê¡Û ’§+¤‹º¬u&_üê•¢©Ä¦Şwi
¦µ’]@ŞÓƒË2!T;Ó%”;ÓVSÈ½HZa#©CÄ©„•GYù&š`'ŞÎ­ˆ!‡ÿˆ¹g¯İäçVhüÎœØQDC¹qrv›BûÊ‚=ª‹—³"Ş#ÁªJ‚pey°µ¶ ¨ˆîˆÊNhÂCéO^\ş¶€p•<qÔ-íL*›ç’U£Xûò.»X@*›¬›¢PUú¼J¤@}Ç¶Ñ3YkpYÉÑË˜#màn¯u
®ùŠ3…™jÊ°IÅ˜öÀ%‘ım[4£oUA% Œ­P§AÁ7…é±!‡-¨aLÊê9éw±8@Ö"7u
’}T:2à‚ız¿·)*Û2©tF|'ìG/åèúËŒ4¤ï±³ÉZ@/‹	‰8ü… o´À&j=Lë«BÛË†iğ\Pß´=¿g{OSğä-¤jo/bPæ“'\MO8 =üBÌİ_§ıPmåá2¶¢üÏ«	²£:¹¿tålÀìêÏ“£+å‘yE³ú›6³d„ET«ƒLr@¢S—=Àæ”Äîcî‚Û€czLT®Oø¤¤´.fÁSn2TkN1@«Ğ5î8Qq“Ód÷
u.«=‡ÂÃI~°~a´šq’=NFØjŠ1¹>ïÑş¡LzİŒ4ğ!‰Y¿„MâÂ[Eb¤â+HBJ®4Ó>pËØšù¬)ì®ÌwùŞîÃô„¡9õ¦JO§¹mK Ø“³¤]È4ÉnÄ…,Îy—¼kˆ€JQ_âùúåş¹˜Ø¯ù€¦bŠVz86~Éû&¹v;3–âƒú$Ü#ŞæwbNõ½tÏ²ùÛŸNŞGHˆÂëŞòry>°¨úßéæ›Ê£±du=‘@jÒKhJÇhG'#ÔS~İÓë¨P£iæß—~^wıƒûHC”­Ô£°jÈ¸›_úÀxµúKÃ´#Ô×,v‘œĞ ‹‹Ï]ò£$ø×«´²Ğ¦Ä$ƒIœCAQË(øÙôa¯äI"Œe	,y£ÁJ²¥ëA¾}øºÒøù ¿!é¡=¼ˆÅƒéW±˜i…FïPñ%ı>MÓÃä§+p¹%¿ÅŸ¿}–$ò|ëà™ínwæ²«7áûé)IÄÊ¨Òİ dĞK3z]+:7=M¢Ä°Òn_¬Ğ†‘ïX—‰"­ŸZ,SŠvÖï HÂáo|(%!™çŠ‡a¹•mP»êX«•£­¬”Î'7/rYÑ-j Ö/tvÚö¼}­%º{‹=Ä¯=‘/6Ş¬Ø"¹Ğë+<@²â÷Ô%®9’Ş;„«‚3µ	ª
‘>^ °¿8åcÀí,½SuJKJñ5GZ]ãÇ+ŸšjkTSÿ¾UJ*l@¶t¼zºÒì­©·Á{˜¼æk
×„pA•Ñ<Õ½l(Jœ¯Šà°ú%hı¼ÉçíYµÅœ¾ÊÕëï/¯ç>½é- g^‘ÌZ¨ğŒ)ìî®ü±.¶ˆÜ•²ÊW–i— svªŞâr…B£3Ê÷56ÍÃ¢äËî®G§v%
9!f97 ä¬ùY{•ĞÄõù ß0è®º:öğëÉ¿5îTÆµÜòâY
Nâıf®cİ#45\!FÈkÜl”ìWêF|¹ô¶&¯oa‡ˆ¸€`a?‰¬{ÛcmŠYÊ?¸4ôÖc˜`!4HX÷“x¥ –2ß«?¡Ä¶ßĞÛå“1û-uxñ¦ÌÅ]Ãƒ'—•H•l™ÿ0åTAÚ£¹¯³÷Kvÿ˜/B¡pj¦¶Ä§¯Ô2³(Ø\¾•
‡Tr{¹û;!§¨rô]ÔÉD=co×mU	P¡›n_(yÎô$¿¾>®Û	¨õã.ÏIa\-Ç—Y©r^§îîÓ¹o5ó†Äİ\\—ñ;ìRÛâÆ9ƒ¹ÏãøL‰ªC¾Yj±*NıÇÊ' WDş÷_ûâ,êßº‚ªx@n(*}\zúÅ¡È”ìAF:ğß_ø…ÕJ¢µ2¶yäé%*ù5šÀ"iÍpïÂp‚\+È9Ã›ójÓ¯Şe([*µös`R1ãHk‘éß-ß?§Äq³mŠO¬’~¿/À_qå¬ª}ëû€xoîgª$ß®UozAbø±ş3Ó`h74[½súÛ)Ö¡T¼Ç Ôp­n>LFºä‚uÆƒÖ¼†º¼cÔ¢åõ¨F:¦^ôbzŞ`IŸèÓ¥WÈdÏK ğË•£ÊÄ€&!J,„Áº5ênYılú®ñ¨Šœ]6>™HÍºS¸Õ®L(šè5û>bÛàëD—¼o.Í|¯"Õo¹í<Ò£3†¹û¥S.ïÕÆËYƒ:«µè¯û9Àù–¸‡l:©hİíE‰½ğñÁ¡9«v/ œÆV¾Ãî5íP˜†ôú?…k’Ò9¿¸–…ëZgcB³KgÕİOg`R*“úY¤éŠ™Ÿ‘î=Krµ0Ü<Mÿaş‘z¥m7Ó·xÂ×næ!Ö¸³
ƒËSãğ-â$pNåø9Kñ<LS§$|ÚKÁÚØ9Ši	<cXê_)Êú¯Â€’÷©†o>şßÈ¡Îscr|lG2CHÂÍ}¾ËTÖENz6$áMQù@7–ø8Ø†O§‰™…Z¾Úã¢øÀr
Ğ ¶w ±OÈ”¢!ü¢ú¸|ÓÖˆYb[TVÄ¨¾ñÏõ!ÌKjÙtùe²VÆeG%³mhõÕsVF¾Cd<Ğ]­Ğe ¬wN=ö<—4TŒ¾ß$ ÔÎëV±&–)dàƒr­¹lúº×z"ñ«Ñ²A•´ù4{¾Lz‹-@½ËXÄZÃÎ¦Ëiªë¡¬ ¿iBö ‚-Ï®dÿî’|™œ
±ş¥Š>FzYØ‡ÕíÚ­î6¸Ya3²[ÊòÑs³3À<ln~£8-eâÕ·¥…ş·Ê!£´n"ëj¬Ur!7¹yÊU-â3¨ä¨fF3mXS˜Øt‹²½Ú™¯¬zRuñKŠåth<#%m¼HUá†õ[Òâ/„ñCÇô—>ÿyuö/íè¹4™³ÎE ‚•Ê«©ä‡æ8ÿQ=‘9YÎcò®¥ˆ¤^ö%*$qxe(•ÆøïÑÏË[šğ7™ Í/µHÆzwHÆ6v	á~‘´_â¬e¥… öû¹ÙíÅ¶ùÈıGhHíüÈX•4oÃñhXLH2ŸFƒ7Ñ2àpÍëMÙá1ÕæÉÏƒa´œÇ*æ¤qOõ©{VTT­+86?}`ı}¶ªÚ°ğAI¯İ«§åš’ò÷ì•Î&KíãíÚ9îŞX¨m"_/÷å”ËğÛ…–Î¨ğßBÄJ8÷³.I³éjlbmL\Ÿ¢e$šLàø,ç{$ÉYÒe8ıgOéü8Ùğtİî)šhĞãÁÃå·:„lS¿*l!+ñjtÈ|Dû »=GY§tqiÙwb”2IëÏ®ññ¢2¸6Ş­V¸æ»Î I¥bùI»{+†é<]“üø£uáXYâÇOPĞªGi5ÒV˜lñÑ#ùçŸ9‘Ch2Rã´“5´CËmØku}3¸ö¡‰™ˆ}Mr-2§=âIûTH\•cß	rvÏÑkÅ]vù¹UiN3	½fP^+µ¾@ng"0vÚ·ş†Rå¦±[&àg“KÖ¹ñ
W¨2t/…Ëàªb&U¾ê|&Û‘Š+ï”qŸàË+œDjòHuš ´Çğ°µÄ/×Xlºìæ­Ÿ´–ö•‹ê6üQ¾@µØf¡7ÚGã‚ÿ¦»^õèÉ”b[ç)rñ?*lŸ9>Èá&yé¢~^ï°ùÉñE•RƒÛd}¯R}eÅ$9‹®kâûZO`v`X­°Õµ{øü5Ã™EN$"…/ag£†€9ùB$ÔZğà?K¹œï/†§_¿™K	€¬2>9u˜X£ÈP1Ø+:ÅÅ®ë¼“_À‹’§¶¹s@nab“(‡z~ÈúgjJÖşœaì c1Äœ®Ì^zãmƒ’6fëbÎVğïñ¶¿rÒj:Œ=é`öc“İ_iE³mS¨	¿++İ®Du?Ş¹ƒt4K<µmÆ“óêX*ğO"áIÔB%CÄ¼öXâXqÍXÁ§95\'çA7-Owß+J·Ìõé›|'şàü§$´Ù$Êuˆiî¿¹é?êàqL½°È†ùpX«ÜˆñO«(ƒ4>Ó9ŠƒÙå/Èş Ş–'@;„¸îZ šjŸšl!vcµ±dóÂ&~SŠåÖ‰Ü6R~ª1„M(cn´´…ñdÙb·êŞdkS‘ì¥YÊuZvGœõgÀ¾[O–1§èu·ºÖ@^Î pœ	ŠB¶­èõÚO‰ÇT7“zqUUµß,òXr´öw"t€üp0Âãdô‹I¦Î*Ü2C
–èrv+…/”1ÓôéríèT)Ÿ$(tëºë„¨!Xaöø	
jIç®‚ÇÄ56F•Yl£ ×ÏÔóÂSóRçŞNYHñÂşBbN õ—¼àÜñ&7ÌªÆƒĞ\ÖÙP`ı2eà7ã‹½TÅl5ó0ª™õãH*¶&G¹sfØFŒ×(ì9eò\¦}ï•t¦¹ıÚ±İİº¥•òËjÆwÂ÷êyä“eÖ»s‹Æ¼ˆÆ‘‡¼ú tÚPñ.Ìõh˜¥¨`¸›Š2fx÷d4zvV¶Á¯ŒCê½tæz[¥IXÃçweÚ×GÕ]w-WÌÔh D>GM¥û}?‰^1/˜?á´§À³F~Ü¥‹b>%/PÚ)“{->è‡DQã“rì;KóJjöÆ·y”S¬²çXD¦ÏYM´jÕÄvbt`³7û>€_úc†ƒq‡ÇÚUÍÿ1œ“ÉtÖ©Š:DISåá¬ó‘Ğèóê4ù lW¡¹ª/¨‡`à¯(QÔ0ë'˜!kóÑ@–9+íWDàÙğGâÛ [œy\öA–›C•Ov_]µ…Çı ¨Zåº=I—¸×G­àˆk1!b)Ü–:×3E7äÓ‚¬/øoÿ9Zõ÷…ß.	ïV|Ä°Ç1%ÿä5béÃB'2‘ú;ááş{ÄDÈ„ãŒ|_.~qéCÓ-75ÊÍ#g<µİÆXş	'²­aNÏÉ¼›79j­|õ©±Ó$UëÑ§W”êœfº^É	J÷hô¹ı…Î&45cÿyŸï¢òXz=9ºë×ô:TÎßJtÇH;5jÕæ’	–õÎ%•…å•[ß7DÕšOÖãE¢ëÊÉx°¢û¬]üßHDwE|ìp¿A\½'ùŒ&Q\¶%ßB2Ü…ßP°	Â-â•ú¿ƒ‰İÂòW×y±¿t3V~ík6&³|'?/)çñ8{f;úI‚®<t*¾hkjIv×GÓKWQUë–±šÓ}‡³»ÿ™]2ÉX­U‘¹Ãã–7½’l:
4“-è8	Bætñ•@Q‰lŒ£İµ¼š7¨ÉR®!ÍÓ.‹¯émßû6ÙoÙlº7Ó6x;ã8\V…ßülR¿ESÇ¥{og‡å-§€µ„*Å+ìD6+ûZÖ>¥38EáïÉ#ó¬'¢`^öú¦ºVmKôÑA«é£ğ>o°V#µN˜„gÌæ4Ÿ°ÍÆ²fêCÂWÌS4œ“d~ -˜š
³õÙ´R°“Ù‰éŞ(‚Iã|o‚Y40jKHá´õÁEõcğ‹zIœ§ğpÂ}˜¸¥ŒÏXy†“ÒÔ«ùvõ1S»ÖÑ+>Œ +œ\u óWv¨åŠ+Q	”v¤÷|ßYãZªn©ôôV oÕD@F—/»…Pò,IÅ>î¶.ÊŠàOÖ8–¹¥¿3¦k˜Ã
ªd_ŠSh4®šQÒ·WŠ‹»ò¯*ä•;öVù5*˜D®ÌŞÜ½`ş¯1ƒ¥‘¤Òv7ƒHà1ÓÓ}%šéÇB0&‹ì#&aÊŸWFøòèş OCs!ş¸…ØR0[†ºæğu\\Éêûî¯GÅSŸ R×”Ê·Î"¡nL·¿ã¦©ÇGW–ø4(,væ¼KávW]’«Ó«ñü,Çråh3å]Z±©q@ZMK NX~xØJR‘rÿIB¨¥¡ûóšc)!+¿]Öá·5È›Íoôë#LoÙ–\¤º"JCC³ó>d7ì;àãöÌÊÜ>æyªaÔÒ•õk¸mÙ	z¸÷ÿI%Ó!^NäÄ<ô~f7È¬|)û ¸ô¼ê™ùã­íÒ]w9hR‡ 3mM”)ı3‚Öà™G9²²à"P{Œæ·z»|°øÆQÎ>‰‡ä"·es­†œ³aÉw3ä›Iî¦L·caÖ$9,Ë20(4N8Šop®¡ù½Zî¥yn´LÈïÕÎˆd3!8¢lQOfC+ùtøÿåã3Ç_~²_ÇUÉV4æÈ’mJ³¶ŞÔoğkğÿÃÙ~+Ã«è÷¸)ïÅñ¯zfä•\wıóë(ğJˆä¤¢hø'cptİÈ!^Š824Zı“gTf
›ÆÆ‚hİ_ˆ7kET.¶.¬„Ævg>ÌC¶Õ„ ÷ò¯â¶å¾‚œğ€!r\³.3o7ŠHÃÈªÕ’sâ%QóU™¡\¼-ì”Î·Nh\½\ŸšápY:r[1Ç=ôŒ¤¶j·¯•éc<YÌ,zt]ÆÈ9˜Pf!§a9<£—kÏ‚uĞDà‡»åc¦´qêzáÑ|­ªÙˆªR»/ârC+ö\?CıéÉ¤¥¸Û,(R^]Á­KÖ¢˜¢Š‡l”Ç‚Ş2‰e	 =’æ0e¼3ÿÈ˜zNú(ŸñŞ¢KÀõ­)ÂÁŠVîj:»°Q®­x"ª¢ğtä?z–{©ó;Ñ¥»[§¥ey*ÜÍO#iÏmR)o®5Nk Ñ\ã)$B¶Ã¿ê‡äÖŞ2()ı/Æ¯2'ªô¹¨7	4eé½»®%“‚z;Ô°°?
Êff¶İûp‚ÀŒãIGòl¦î?ÿk aÜ˜–K8ÉõäNI6´
|Yëw&Ë†ø¥œ[1´SWP5^#Í‰#…UŞâg2©ı@jb:Óˆİ79»ù1ØõÊM´È½)úOÔ5­	(ü¹ù¬Zñˆãƒ4 ¥[4—øC³•Â¨ƒŒ¬Â¦w-/‘š¤5ì‰á;›k…¿Ê‰I6SÏıÿÌÂm÷¯e|ëö¬úĞm·2Ot^>]r:õÙ¹f4ÊÉ…şp¼òñ~g¸¿Ñ¢”‚–DÛ‘ÿÛ{0I/+U1dH[XçÜ÷•+àLÜ¢şØeÊû}ƒ+Š—ö>Ö ÛÉR1Í|°mıæ•r¢_À+…tP4œôk®-¹wÓnÇäld„BõOßã	¦ÔO¡Ï#™-"=
ÂÃŸR`Cµ–š.T¬øü8*O÷xç©º÷
†È6¤x]Eh»×K»ˆj¢¯Ú?u¢|«¹Ó$–ô)}]Ú`Ò5IÉ1Ú§Xö)³säŠT¥|­©Ğ|a¡æÿT2Oœú_¹«zÛ%‰»8¡İ rkÎÀ–’3¯²¼®}Ã rŸ,!»ãälüÔ·x(¶:1A¼²é	÷Š&ì“ø4l•Â“‹:TÒÌüî={ãï%Neµ­¯æÿdÔ$e6MÅXüË»)W‰tšAiÕ·ßWBrœ‹²ÜŞß#°§Ğ²I˜x°ã¿Ká^‰V.ñéÎµ¤ßë,iKî˜ûšÒ3P”¯›C»ñ”QwÊJÂúÎ ÈûL_GüÀÏPV$_@qL]™bœw9o²¦¨‹²¤ïÿëîa÷ŒDÄÔ`ÑšŸ~J3Ôªm‡>ín¡û+=Œ‡ÓK~j“¤r%47œÅïZHáÂC1ºQK,‘ğl§yGĞp7®VäĞÕép¸ï%˜ªÉo?P)ˆx	åÃö©Öx/Yö8 UƒÚ~r±ÌI³l.{ÙœÀÙ÷7—™²‘Š$ßa\Ù4‹àÉ—+0XÄ“âÅxÆîú˜Ç&Oé¹Í×ÙÉ5ªÈÀ65Z°×Ô‹ÅA®^’°ô™Ïì~!mO€~·ô»rÚ;ØKpªËO:†>‰îë‡§}7%¾Ûhz´Ee0,8`{:o”û6à\ã­mhø¨}ñÿ£$Mœ €şl½`ÂH ŒC<}Oó,¹I¢7. ¿–v79Òûš¹à–PÛÕõßÃOú{]Î]	¤F¯’ÿ—‚jºx˜¥¿E~¨¦Ä¹ãâ>t¶åËİ#÷Ìòˆ²æßk«È
½Şæ°ıê™Ò¯_wÜèg8ˆÕÃŒœA"^PŞ©¸¦ÀÓ’Èê	S×€cs¸Ê±êŞXü^.«”øvŠˆ+Ğ‘7¥t‘U•-úÃ àMrÿ¯–­<(¹ŒW‡äÆŠ¿gÒ'ê;¡„õf¢L‰å:w(LÂ@HªiJ–mµá³uın6Ùw‹§/·vìÚE¤fZìC™OĞè;†ï5åuc¡À”¿±w—”v“8HÅd { UXĞÈßW©Î2†LHñ¦²ºv*ì¼ ÿ÷-Óª4Æ¾®å…{Xş9··h7º>ÎÍä·ÚKß+0‹5ÁÆ »¬b	Ê–>upb'•Ì'÷]ä½#·¾(]È'@x	SÙ>–šåê¸=Í3ºòòø…|-¼ùÈ×$ÿÎ+Z3‡”m¨ã–/ç“¨,ùßõœï˜™@vCÆ=ÔËá³€IO®mş×°¾4„^]ºæmGğ¾É‚œ%™ª{é@%>İ(N²Ìt|şİ
M-ê
èÖ«å&˜ãÅy^Õ °Ì‹{ÑxiÜ¼Jd½ 6\AC•qs¶fHÖår“<¹tÚ[ıÂ'õ)ãI#½ÔÅ‰~Ûc…öxö¬`i…xÜ a×Ñ·w„ôÀkxƒ€=¬îÍå]à±R52zo¬û€j/4ÎX~>5æÓºnçJ2€Ä…Bc—;—ğÈ-8õ7à.Ğúâ¾Ÿ£/¬@$M!¢mœjw¸[äq°[Z˜½Îâ^H­×A5r(7È€7ùèSX{>|#ölvÌ–¾—J“]qÃt0ïA¼b”èömKI»eußœÇìi‘BÙÍÃóIKS(¥ê ×kõ¼ğ	+õTz¹á·?<Ş7„|OVQ”é«“@Ñ‰âÑy0e?*.¥À½pİ<D1U-ó‡ıe²~f*GÚsÆLüâ¸şÒñƒõ5Eœ{ƒàùwĞü)dÄBµ-g=a€y"Æ#A(‚mĞ¦~4ójgÖº‹rúD4İ^˜ku=–:ı¨K¶UÙ=Å~hÀ=)ğe.†Níb©ÇãNWĞÏ•_w<ÜÁç3aOØ²Ú\¯H1ŒÎÄNzçµ~r*×F§@wW`œmi•¢øÇû0­R©úæO­Ç1H™HW–#à†xV®Í¡zÓì+¬k ãöcÏÚşUšjbl‡)VI7™A€¨«À¢ï7T™'âöl¥B8Õún°vœ¶_Êô1ÊÊ‡«ìğœÃŞ¥QA¨R·ĞºGö°³‹‡&ƒû€ËƒeÙIŞvÖwÅ½™úÎHíÛ!‘,IO©ËhÌİF8¨!²¿ƒÎ%=ÕfzF÷6Íªİ½øíƒir´ü¥‚"›
¬àçÏÂµ=n—73P!@i{ÑMÏ5jÑ‹NA1aèß‰‚İH8³A–2ñ$Ø0Ÿ™ÛK€cd'ºÉı‘'`›şZd£m¨6µç\¬â…GéÜb3ğ²ŞÒ,}9 Æâe˜×Lİ+#—ÑR}Zm7\ÿ±\»Ø»]o«Ü˜lg<÷Ã¥„Qâë @û¨ÀBa9Øà‡¨HÚ;Z¥€èc»N
Ö–Tª7¯ %¤ÁH ÄdT„£;_òí÷«ĞhË/têîÂøº6„ó¥9Šyúö{Å©®*cmÑ—`bü„Cä2†8I«¼ÈøˆŒ4Œ­‰zÄïâË­¿ÇÖXrº¸Ê#Ù¦ŞFdeZ—ŞœGâ\í¨B©¥ªînŞQpÛŒ·óNİ>ûz`î_Ÿ©v¨%ØÊ´onçãQèƒFØ[¶\²'€ãF¢ó‹1õËK
Æ‚ºAækL¬ıLË–Æ@Ñp]IÉ*h´ X.°¸ÀÀ?^ñûlÔ¹Ì%gâÅtœ±º ıà¦> ²¢Ûğ_4I?ó2:ziXêÚ\¼ÊäáÊa¦)WÈªôx°fC=/ Pr}“¨êx½µp[uõÀ:Ìf‰`7YX}c)WÄıõoCŞ¶³Æ´Íh@$¨r’dèFÖ)+_}–Yf´"ı¥5şúvW“dË—OULcu)SŠaŒˆÀÆ¥ML*şÆ¡úhvû›||ë°2T€BµÁ…¸ÀÌVíÙ%ò4}PÁüzMƒU³k„uÄÁn' ÌFVøå]©ò9u(T¯~*“Šş3 Á°×ÎóÄR‹AÂLµ$hùÕäfÈÒ#ÁQmVXÒ|…™Xy€'}àwüU%à~zÒ?OPt·P@o® Š^•KS$Šœÿná°!Ê_¶øMQ0}X—s:æğ¥Ã&3@ƒeÈs#«F½Q¬¬•ÇâvÓğL´‘·UxLjÆ¤¬f‚T³CÂÍç\µPh© cÆpÌ6¬5ÔÇT@ŠSOïÍ84RØWÕ¦Ø£ù–¦	H2™Gs* ¸üôâÇE'Æ-²îFşIFÀk¢šZå'j˜q³•­úò\ú÷j¦”Ü0a?bš–—MÃCî¢nĞdËbáZG€Æøšdjà0Õ’Ï>ì†·O–3ÃÙA/^Ñ ’ì¼´yüüõ×²#QM›ƒ­˜ÛG0â?×|
vgØ÷æóˆ–øXüšE‰Òî °¤œTµÌ—Í¾h§5yæÓı â$-È´É£a•V^Y¾åâ	rmÇ%¹¬ÙæÄ7ŞkSA-‘“ ÌV\Ó5b:8¿¯‚ıÅİ n‹
@HSÿ0]Ş4©°øéšÇU]úT?(|älŠ4›3°UP¶ì(ï\Kj$‘PLÔbn>?˜ ¬iBw –’u‘f|¢åé5º0VÀËF­Á¼ad/»£ñ 1¿Ó7ø$Ş<ÏÁÇ¡xT†à+gÎmªæºHW
(¸Ë—õH×ÏD@“ì½@àhX¶VÁØÃ{É«ñct¦ïèŞÜdîB‹?•±òÕÉ*Ç“3«“½˜Óo¶YL(Ú±\yA—}zFP´ÕÇ¨C¸ËH¡‘ÎÙ|•èb"mÒ$?Ò-5Rˆ¸Y‰Üòãv¬†ò‘¸,+–÷ü¼¨TõöŸTø¯
œ3&Iú’`
ÚW‘‘?†Û±tJç/E~8çN¸¡‘¡9Õb§ä„Å.îwüZÀoez-³	,bp~‰¶ŞĞÇ˜œó©÷.Ÿ
T§ÒùÔşDä+‡-w÷ Ó™Ya¡’ Ïébäİb¬	L¡Àº E±&½GÄ¡Eö¥±#Á!9Û'|êA7“mL¶ô|Ğ•ÿT¹¢ÏsóS+•Ø0­»Q8OÖ“Gø}³p¹X÷ù`[0\ú«(ü5È¸VÏ¡i.°€9PJï¹)NÊºÅÿ&z¼ÔÿğŸ²¯€ñB")m@P<²øv–à¬\orô 2àò¼æØ¿=ÎÇ4°N•‰"¤H)¬­xÛ›1á=ÒÓµŒLñ,©t¤ ƒ§Ø,ÈV{İm‡ç8,'ğ¤Õ¤d¡C²>Uñêİòx–%#İì;/l¬caaw)PHœÿg˜ãÊìd¥Ä“{cWâ€éÚVÒ°È*F¢—Ì»”Zö:›ÃfÁkì=ìƒÌƒ<9›'w3H fáT»ZÑ¨W‰•´#e 7ı;œ¾i™õ“Qµën± b}¡"ÍfxÔœÛ+ÎóHK/ßçÆÆy|È ñ2î®ø«ŸúÑËï‰Š‰3ªJŞ¸¢ª&b@	)(=~BÂ‡¹]R/-î€ÖMnYÜ®V•yW”t} ˆÕxn!äp&9{”›ú1 J¾¯†ĞÑiİ™§L&Ñi¨‡Às9wë¤õ.šñ –´~wİr]qˆÌ6ÄsKŞ0+?¸ÀÜ5!¹Qàhğ‹lvf˜içôTo}Qw‘•Ò¥¶8CáôŠ¶¬1tk$V/!Ú9jt+ä¾‚)¢K¿ì#7ÙÍ§mïWÍT/P¬å sã$¬¬¤O:ÌzE:[1x&±á¤¨„Ù°Ï6ÿÅSóùÚ¦¿dUs²!´èX)hÅ‘í}8ØÃ‚Z¼¿Î6SSL¹V´ÉÏDG‡—éf%Ğrg8›øtQ¤OèkÂæ_şû^bJ`…-ù)‡IÆöôG6ÒİŞ±µ"~“¸ÏÒO‰o¬=&ff+{QAßñ?'†Ì¬Ùäš=“l”y+ì=4 ™Yæi¼î³\	Oj²rgÕÑ¸˜'5Ä›Xa+¹õ0Hx[)5ï…o§¡¯™¶
âO®‰”»W¥…ğ‚@
³yJàZ½5¡ªöõQºŞ4ZFælâ'×Áï×™Æâ.ŠI§¶ö>`MGŸˆş}»æ¸7´-­–óqbïSQ_ıGÆg|“ã>ZÑ§¹eC—lCJX­T¬zÂ¦Øåé†ÿÃ¢¥›â&3­h(œ7hŠ {úÄfBwªñòñ‚¬ømü¥/=uŞ™a.8};vúrmK}UîŠTª\Öëİ„¶y1s‰>››İÀµu¬”ójˆıˆÁ3ŸUÍñyâÌã-Q•+2T¦zZ$†™m'j%A¤óéÒÀ2â†âËÜG>Š„Â*TòIÅ{0V¼çÃDÌuŒIu®/¢<àu½Øbu3Hi5œ×ğœ/ø÷1dNSw Zÿ};m’&3Ba29Ã´'W¶ÔğzÃ8Òg5ñŒµÔö(èi‚v*àÌ'Ù¼îïx.İ·¥Q1ıàÚşÆ0#ƒ³ô°ö_bë?Ú×ùü»´¼ºøíczº‰7¡«qĞÜ¾.“§?İ>%ävö¿TkÊKïô‹ÏoEóì%’_æéû7‡‹Üm;Y€ˆø_ÒÈ•y•à™x.AÑq·á•ØváW.%ò[è=øˆ dî~ÓzÒ4âM"°ÆÁ§,E\ÒÙ/A g~6Ÿç^Óã~g°VcçjßßqahÌøÏI¡"ÂÉöß¢—ı“ÊZa[ı!I9Ï4°ÛAÅnMÚû)®å'tñ–à‹˜ßRÇâ#†¤vkmÿórÚ›:Sb±ùçpş0¶îíPİ’´¯ûTT#Š°‚rát.'£ÙË›1fuºÁ0?b_{¢“îH<¼ÀJ‚_åùBae‡€V»ïF_ÚŸÖ $¾ıYüÈ|¹A¡j7ãAUı-æaiÛxÏ
iUQèÕDÂÂºÌØy{äŒ!ÈHÛEÙƒ‘’q<[¸zC™„ÉÔ©£Ç Ò7éÊ£µ3Ö!jSæb	P‚•¥>ˆVÊ®òçD”©âÚœDñ½$\¹ŠKfè¡[»æÎ²ùò6ÃãÛ¤Œ9	4RPr–öúÿ¦Kè3[BcçY8İO.M”ïOD˜µ9i4!†µh&fvJ½nSMrÜ5%É¢š[(!k"Pp¬˜Fàä¦_ï'¢CÖ8&İü(;YU“}¨ò'pîÊQ	²Œ§Ò_kîiÌqR•;÷ÎëVt&_Ã½ô4|‰‹ŞP©=ØZ:ì<@ÚRâ½§ûivĞœ&¹n­Şã‘¢'Íaê”08Eíˆµ»y«nQ©…YbúÔ?ZcZ@¿®‘Ø­©¸ùEUÉÉÓĞÿd’8¤§4_ú#4­Ë6»Ø¸,Ko¤•3HP¥¶ƒ[ĞeK·¨7 Ôy…nl€K¹æëöĞ›ì9-HÕV^•™XĞ{ĞPÛ³.ù+¾DZó`ó]*r$5h¯‹òğ3æu!€	ùÕ›F€p 1ºáÖ'¯|*ÙN³;Ø±Û±|§M…'íNe	µtÅ3cptlçg_ e^©ñ§ëq¼	ÿ¸dŞI›åÑ²: ¡ò·câº=ÓÁö-Çì¥ˆGuÎ›ùdWeHD~EvD•:†C@İ3âÃpŸY%CFR2ÆÏl…–?›Å q…œng9…IÙYÜ•?âw İ°sV‘ÚˆİsÖ”­zŞ’Q 
üØºt½ÎÙäT“ûL V­aÒÿ,êöûÁÌ·×’Õ¤+8ğMìxÌBKïÚ2ù¢•1ÄÉßw.”°'[(·¦7ÆÛ`Âiğ3G#mV‹¢yÃK™³wƒ;z0åe×€Ød3¸™v”°p…Q9Ï`éı'
ö¨ËİÍHhoğfğ+Ğz!âÒÑÏq~Œ¤7Àå	×Æ—ß«Ç¾KÏÌK;ågJ“™2reÉš¥õ§•Né{8U0éÒ§1Á#vÜ®+fáØ¾qÈ¾ŞÓxçIÿ±GU8‚ié‡ôëz©|§(•jµ÷€*¦'ä»ìkÀbÃTâÇÕNÒaíœğ¦ï@¸´z]} ûcG eXÆó~àŒ2¡$m>S-/Ç j1,+9!Z]Ó#»xZ4BH7ª•åïÈÇU®™‚[Ú
c!Óäm:ˆ9’T59Y–)9éoÕğ:®ë$n“DªJ1!:ù¯|ÍìıO´0şswÕ=Îxª dÿÕ§ãšÔÎ‹İIÅ3»ŞG­êz\¢ª!HQEØwÕÍ4ŒÕ¦Szo!ZÙ\$¦„fÃ˜ß&E&z¥#L¡sK5ñ-ã*šOBÑ%à±>s="\3XNwAdà…]4>üÓºIÏK~@µS£§ÆŒƒ GdvJe”³z;®eó*{Äˆz`üI&!qÙ°Û“ñm,sRÒ²bD“ï*Ôì@w®ßÁCoÌHäDe)²õ8ì¡ÔÕ²?‡Ì7ãÃµ1yØec)Å`pEÆ 6yÖ©UñHÀbğæ^»$İ]õ ñx´d¾Pqm¯Ë'ÁKo3B·—Éğëc´zæUüË^vsÊ:a²fß³jQõÑ.â¤X/«&[ª!éÂ% G«ù9²³]”yt%»é]¼)ñÑ?,›—ããsú]%::jM¬sÿ5øÂóœdú[š Á+ı<Ã]\b<“ }ÙqÉÈ{êeãs#w‚Û)HAF5ı«¦­Yß¤²û…´¡êÚ é®m†šfƒbo ½§ s
œ&¸Ò€Ì"!Ì¯ç÷Åh¶ÍE’¼zgŸ-MvŞE‹ÿ›¶=²Çrax_'[½£ÑGáy=ŞM‰*Fê¢+ĞÁ^q>Ü‹€O™şÁè
EmğÙpNñÛg¦ÜÚ‰æ>ĞW}	£™jÙËœ<ÏxúŸ„G¾ŸÁÄ:–ˆŸ.ÏŞ$ØšB0Õ…w˜}‰ã…Ÿ’è£S”ëóM5&ïœæõ2o
HÁZÉ1‹dœÚÙt§÷·äs]ŞgwIÚÅ`ŒéÊ?â¥-ˆ‹$Ú>ŸU†ØfeÒ®;ŒsVZJçÍÿ Zˆp'øÏúùP]ì¯–× P6~Ó&‹yœáä´€_ğEëU‘CeÛìà£•ôâÀÀ
Ë@¹TkÈ÷2fª–=€g8Ú>¢5%*A~$ÊE·­ĞQa^Æ\“ßö1Ì×ìÓ’û…º¹¡…>i|it¥D¨±–HjÏ»Ò¾é)´ÌõŞ clM6ü[Â©Æ%¨”ŒÙìÁ•K7¼IÍeR©œııBOœ3ú9Ào®¦üi/#æiŸÿ)-«|ÃJo&qƒàôJxØéW±uTâßz˜Ã~óq2®‘ÔÒö™²ûéO«½#¸D«Åì%æşé®úk>|„°ãh\;'š·):¡¦ßPç|#¦šæ}ƒõ{Â	€o9Ö=KÇÿĞù{ÏQ6àó
ßÄò£Û”_ ÖˆŞÎu _­s>oZmŒĞû‡¬}KoÏh#„ ¬¾g‰O»`HU·­öš¬ÏB•+Ã¡êU×™½>dºç´²ák_i.–~/Tˆ1µÇÜ’Gäiv2ı)Ä£)œÙúıÏ®§µ÷ÕøÎçÆJÚ8M½«¡×èáj7w¶ÈÍÈ}â§¸“¹;s„€‘ŒJ0iCÖ',ã~‘—‚œ¬Âáñ¸ğS!ıu¼ô¿\£YÔ*g[ˆtî„ÃTí°õ½J¡>DZPI_?Yöú±¨8¬8¿‚-»r•ã(Ù.Fìv}ÒÓ‚ïÅjØ Ø#¿åUOVº û‡.j‚²–ÂŸß”RÍ/Bò©?&”}ÆVˆ"¨)ßŒŒù“†ú"––nH1A­Ê*³·úĞÿ‡«<¡¸~Î~Z©1ÖµÏ@¨ÿÕG%°üQ‘E;áÄ¶ß¿—9M—ÖçÍL×¹‡ï=rbß¾1[p¥ÿ%SÓÙXé–ÇƒN£¼ÈNÈÏAµÖÆ}”ú+¢s‰°}üì{ m¦f™×¬æ³“_R©TMPã~1ä¥W`i~’éÎXj6œ{íğÚA&Ğ"ü°†(«¹.‡$7ëCX³…ò?q.Tşú!õ·]C¶w@Z¯ûøçkHÊa#í3«èõ×|Üé/)tİÒÆû¸% ÆæÌ˜{¼dÊî»Ü<[ğA/]E2‚³šáGƒˆ¢;_>£Ÿ×Åp³ÜAmVä
t?¿Øœp¦ÕHNFä3»¨Ëú9ç}i&tfÏ½:±%Eà$ÙŞS”¡æœ²£¤É5ºŞsbQ«¦b¢¸ø~ãüPİµgw£‘?âÔf\‹rWõõšJe!_AdŠÅ”îĞ7Ø8¯A©:\(¦<ò†È|Êb¤?ÓChçI‡ÿu„w{Ñ±Ñ¥ÓP”BG(àİü÷´Ì4™¿™Àâ…Ô¦¹íQ @tyo–ü‘&iŒä€n†iäÌ˜¨‹B&òò–ïùn7VÑF^y¸°Ë8ÏvÅ¥?1¶ÍHåqØ> ‡—fÒªfäşáX”KtY”£…X¾¥–8&ÖÃC¢†ÔQĞu%€¾"“z{ÅJA¼í/èwÊOˆ+?˜é¼ˆÙÓé5a!ĞZ¶Püõk
g“²I&"ñ=5-üO9æºùC†×¶é¾»a˜­Ó¦°=|»ˆ+©[ro¼7„kl·Ê'İ.¯²5*+xS¸ÖÍ3MOqnùeC“íK×8w‹Odlüm3Î!Éëøë'Ã‘rŸ_â¯aÌF<¬ToÍ»ëú¦T³{XÕĞ@ä¶(§dÛRÿ³Í0#ÇZT4Ú#ZŠ°ÄÂHa¿mh¦›ùú¯!¤zú³Ù°õ°•%ƒà ÿ•(%v> è€ z±™I±Ägû    YZ