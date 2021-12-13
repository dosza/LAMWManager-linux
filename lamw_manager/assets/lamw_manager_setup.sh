#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3144074595"
MD5="db5d3f4283b0c8b9acabb83fa8d6664c"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23920"
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
	echo Date of packaging: Mon Dec 13 17:46:48 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ]-] ¼}•À1Dd]‡Á›PætİDõ"ÛÂ _?Ñ‘ÂÃ_-•­k¯%-5Â<ôl^òù…MoŒ\#{7k‰¼B÷™´SÅáz‰+‰R%s´ôåL@PòÁfXúÂdˆÚlûäÔ×Š)«{ÁôÊšb3‘—/¼ò"M<%~™HKä%ßoÿôl÷=•UæƒF¡îRL†{n‘bÈÅ—.Û/bŠÔ®3ÓóÀÑi
^İ#Ãå'†ƒÄ“[î€Ş)Å©)»>Û.ÒU= %m'™B=¸‘.RÎk¸ŒæSR%'Â²´tVÀes ŒÄóe}€~&¼¼çÑöÍö>G}R GWHèU«æ·!ì²ø•Â^pvîĞN[ª[(¼Êá^l½e—Q‡ÿ^â³¶Ô\Á='Êûğ-œU ír!aY©Îè'Çbİ‹dSğ‡QGÉv]•lí˜øª·;_,XÁú~W­ï¨€_-7Î¶z³Ÿ¦¨[YÆ=™Í0ˆèú¢xæ d!,öèDP{s]}+„Ó®ßÜw(Çu­<n5«·.Ÿ³W†LcĞOÛkz\ÕÎÕ…®BÊqÇvGÎA†ò%Ãè#»˜Öû¤½!`:  \òŸ´ö—ó¶‹Yú’Ó»YzXäà# ˜J‰7Iè;¯Ì°Ü‘±4†ÔËÈtUüí‹RÀ¡µÕsz6fÙ/¯ù¹4zPe"“.¶2sœÉR
‰ïÀ¦&5ßÂlf€WµHlk¤©ö¸g™³BT½¯òËšÇ-ÀÓ…ÿµLÿ,·İ%±Ÿ/ ì"ÿ³Ÿ1ªÅÚSÍnş“ûZŞXœPğ0~xÔ±gÊÒ‡V%b;İÉkl{–Ó^©•¡mÓÖ¯ÜØy	ø5Íæf£2¾±8 ê-æØúCq@€¯ÅçéU¾-ï	¼(ÕW¦Õ¡ÑÚqg·¾|U®œVÃôœ«©Ü»1ùDwcv”ãUÂ-ÕÓŒŞ¤aÑ³ú¦ƒâX¾ÈæZ–÷•Íà§­ıI|¨l\çYAGØ´AŸıÍş%&İ+[ÚÄ´¬Wá¥9d‹!ş½tG;@ıtøÛ"Ñ-ê0Nó	1•	şÌêÒ—hÆÎ+.¹Œn%çAÁÏ”‡`;­°*3ÍÓMçiªø?ö’¦Vhâ,Øc’³JğŞ
F×ÕP¡¼ÔĞñqH±ûcê"d¢Ÿ{4½I9İYkäÚÊ†å(3GV¯˜ZvaÔ €ìG•‹ñÓYR"Â¡t5·¿AX ¸J©ÁË"cnĞf’lòßÔ>–>Ñİ:Ñ‘Húÿ[{¾z=Û9Ê½éÈOíğL°³gÖ¼Ô`}=}ïö#DZ’CÃròÁ`şàš@aê8csíâó7ÈĞ€£Š:8XÑ´ÇÄu5a­äMî{…ıv„ûœäÛ»ØoPÚ:ÒS~m°©v¢H’õ];íz_2ì/FĞ¨¤N>8Ş½^µJ§ù/õr4ËV-'ÂÚ[òzÈ›ÅäCŒ„?x·vÙ&-yngÛ¹ƒDt'Ã"p’^9.ÎÓ®Døí-EÜhÂƒ‹OGŒmÿŞ¿GèôyÁËã)üüQ¾‹±!à‹ÙàPoO3=–º€Òìènßk[Ú¹—<Òª¡p"šïß.•R£|¢ÁZ¿†Ø_ò°s Ö÷óPòĞ¹&Fl6¶İ‘
IY|Ú«qi´eùXö†kJow»oÂ…	~®iøÜœ÷ÎMG8ğer÷J}®T±pmKhb/b'épˆÎ8?Ò~İJYäâ7T*3„]…e/ÄpNlÕ£îNü! «Ü³ˆˆ¾Ğrì—õu¯úß)Åm.ZTrğ/ÎV#ß,q{éQâŠ	¡zV£Ì±3(ƒí"U 1ëï»TÖ³ôD¼ï¸æ§1›ĞBò\ß%Ò2¯ÑCš •µªÙ³+lÓç­§ƒc*eÉ~´q/¨ßu°cÿè‡™«~¼–Û³„'¼>­	œB}l(sÇ­Úì\ˆV®ôóğá]ıeZNé:¿.\¶§GÂX+4r30É¾¸mâŠÔîdZ}ÅÍ ’U&¹ÎKâ•–ŞAL2ûÏÀ³8­«
t+«
ÌÔ'_Ò41Ê6YC±)G}¨´¯ß¼ğs@%y$±PåvòMˆ(ù§]ÂïOWNŠ6x©m8•¯¡=TÄŠ0dLÕ“›ªZ’¬ê"#vR€JTÙËRO 	š Œşi³N˜/4i{Z­u|7êû\Å‹h½_mÃ;«Z(ª¼0‡!Ï/HİŞŒrók¬8X-¤…šX-bŒ^5ãò¾Ë‰+sÆ+p–­t2Òøâµ³lDŞvl@íL=„Y‘‚»Pı‰Fğ³¾Õ~$ó„…Ïİ-úÆŠ TƒÙ_^åw®Ö~.„‘7Gë¤ÔĞ¤E­*¾™0ùy6G0<ì–¤‰^äxTmçA8y¦5²ê†æm<ÈGøÑÁºXWÍ ŠjšØĞK/JíNä¥:+ïÀ—7T>ŸÌğÔÕ¢_°•æİ¤±boº“™–HµP‰–}ıõ%Ù„4§06K&øØdÕĞyfv‘}=–7êÚÛs¶t²	ŠVaş°}W¦ˆoÏòj9{XÁ›ì$lõZ-˜Ú”$Tûğ+}šÇèÊ[¾ì-5‰÷¼DœÖ9ˆ·ƒ]Ç´ÿ øèì`ä)ÉÊÁÒ}h0$Z­ã·g#ªNñı†ŸPßGŞæRÏ²mæ¨dÿÓS¶“áÚ–×ôƒ¡-æÄ™½øÛûKuŠLšñ•@çhä Aï‹/¿atjçˆşÕ§ØboEyFÎCYPÃÌWnJñqãk ½`³ç+~¼èn[­üÆhr	~ÿ^¨//bş¦™KZGö?†&5k„”lãL°Å_|Q™]ÔÅAK;S7xøö–bËş5•‘zjI‹¼ù–ìùp×•¤AÔ/ò6Â9ği3İ•UØ}µsŞ¥Q#œI¶úÎ¬§¥¤Sd/Åœö+Œ`\†|àÍ)%ùÉl
2gÜ5§.I‡™·ş›œ‚bg„ŒsgLå%‹Ş<ëğu>À6uéÙš `ûR*/}p1Z=»sc'yk¸'â±ÏÉtæùn_y•©3ò„’z~;¦0Ì
EÌr9Éb²Nç˜v
ÚrÓğ%¥IU]Üƒ»KrG  ,%ªÄ\¥ì=tYÓécg¡í•vĞ»Ñù]ç¿Uh	qm4IÅÖ’—+šş-¦e~-b÷<IÙ‚¾OGÇÀÎ2€Ì¡¢ÕÚñÏ“Î$¬¢²%ğ=±`ò¨€}ÓfÜ¬¹SxA®’‘Ò+´üB|Íôa>Ú"Í¿®v¡İs¾‘%ÁS{íˆ …×Y"_„“*DÒSìVÑÀdåMæÜ<ØŠ6§¬‰=;ˆ¯»üÈÕ­åU>NhÍÄQ„ÌXØ±lŸ!èc?0ŞÆ¯šHÈñ`úºymWÀ¯¡‘*®_kÍ˜ñ®.Ìç–ÄKV™VQÁ¾ÈjÅJ5¯hŸ“ú/¯„VH%È`A£Äá*ÑdëÚ:&ªD¢Ò±´ÄÃ{daŠ‹¦¬µEmñ–¤‹fŞ;lnoÿ¬ÏœºjÕ®­Eg²‰UuÛ4Ğø¿GûšdM(ó[ì×a¯|u›M.ÉÒEğ·p,Gòè¢¦–÷ÿ<~(yyL;CóWz˜%«¥.;¢Àân„ó„÷*€¥¨¿Ü½Wœ²BÇ†\nBmSëú „š³Ø‚,0¬µ`k€ÿ*­©"w'ïX3cj_ ¿áO~8šMVÉŒú¶…¼ĞõYª»8å„mŞû°$=X²MÿÉ„6¸[hGhšÁÖ‚‚¼E¢lİ\a™Üòº•ø8•ÜZÃÚ]#ø®ŞrKSuXö£Ç²a-m[ìµ»ïM©6¡;bĞFV*È{½E'ú?9C¨W
Å´uåÍ
²Pºº5f\!L…Â;Ş
ŒH>…«~Úãöw©s%	™j%5Ó²›/ÿ
²£Ğ7Ñu|ˆÀTu"k¸fì¸„y^hÑ	hùGŸSŠW
›WE^ïĞ'F-"iªIŒ®=ÕÙ~ÄzYÓ5ã³¡søÇ’$IßÔHä»¨&¯uÙ7ÄVc“8WÔ5…49“Ñ¶Àb‡pùj<´Åˆœ„ßìpûüIeZl%º©|ÙuççİhyÎ²‹Ït2b*è¤EX__ĞFW»@q92
‰ ô†Üq¥dÎ%7#˜üPîBÚ*TÍÛKKóÏ^eoY "k& =ÿAÚénìš#úV”½&ë¡$4ŞºùOâßÌ·¹,m_CıŸkçÿ
îTÌY·Sê‰.Ó¥’1ÀŒ%ÃÊ+slX"[Š{Gàè.3fKg$à'¹Aº{Ì…´õ?¡ld~(Ş×VíÒJ06fRl‡ÜëC<–.']q—t¼u½|å¹;Ö„Âö*9bïcßUT–.,vïj_SªaT:->Qy*ÄQ„Ö“ğ€"¤Bˆ3ÅKÓ., »
bákñOù7Â¼i —SùÎy4°Û|C®`|ÕÇØ¿¢í4F3ÈÖ¬ˆÆ)ğù“ïîÃıİ—¤(°Éz’z‚A=L~µx60ñßÆŠòj¾Ìy{rGZ#­i„jĞÌ¼ŸÅºYZ¢£ Ÿ|¥¡!.öG,[2KäOäÖ%@7Ræl[¹Ñn0¼é‡eü¡M]']=Yß»˜Ø*U éÔÏİñ"\ı‚Ü\'ø3»£îÔqñRSïEÆ~_«P£.y3Ë õsÅ»iSÍÑGR¹‘£½ü¿,?åoé,KXÙ>ƒ­C¾>&	áb?¶+?l(¤áîO,Êë^©ğy(ˆ3T®Ø™^á	úxXw~R×bÔtáv]_)<CSOsbÑ$]}\Tµ+lFeõWû ˜Ö~x¢>RAÌ*ˆæãfS'RÕµÖ‚@…Åéí3;¹ªd:Ñ.§n÷,ËÁ\¬×r(¾Ü7fwr’íõÅ®æEgµZd45¶ÄÒ±jˆšäë*ÆQÌh~Ö!üÜ®	’³!}9ÍAï2ƒPüzáâ‰àÌ–º6»u±¦;yİaEÜè’øE%÷G^^%) 1AH¿2âTûÂ:O§FYÅ2»ŞPÈ‹/1[Õ˜ô˜<$~„u¶âÄÂÂPƒ´ã[µ²±$ÒñFÃjGJŠ­¶*ü v—³$î8ÛZ%CĞúå¾î¶|‡ˆ—s;kO\¥PímšÛaNÑ*j˜ñQ³NGÏ‰„„)õ¿àáÿx¿ë¥¯H3‚şò/™S6­Sà›E·¿6âméì2X¸(M-6ÚÀŠdRùú¥èæÌ-æn©±ï2aŠjá}”ß¿<I™±@=^„ÔÂ€áÁsÿüKúÀÏ	qi€‚²îì*ÖhèÕ­ØàQ™®—áP›(š£„ÄvB§æLµ²:x{ñxLG­äsTg¡	òtìè!ï–ÏQŸë#z¨Ë©©0Õ*Ìã
äY#+S@çŠ$Z"#k½0tš¼;œÔ¼mp¨¦eİ%+Ç ŒÍZJ”C>PÀØ—L	ğè¢Ù¢´Ã>ßã¿üƒp
™&ŸXæM&‰åÓÍ9!‘|JÑ«°&@´7GË`%À#z6œ$âÏ£Î¸ëe†ñáeÂŸÚZ‡‹*†®ü­Ø2»Ğàø3i‡AğFZ&
øİÜÏ~wĞØú›X7ïd¦œ
L¥o™³";ræùñ-…Ä|ø•t5üM²)‘‡Q¥İÄ·hL)ıû+LÇa Ïs(yY`†+¥l‘owË#i­0;ÄUoÜÉAÚ¥¢z¹Ê
@ZÃà²·.!ÂÖ,Ç[Tˆœ-•fù©~> Ì”úáŸê\ş2Pë‹ı”¸àÌzÆ ‘xAY¿@’bÀA…	°–{çaÃ¤MJ¾nŸğa™9ØN™œ!ÏŞèÏ‘’Ø0Dó«ÁLkùùÁ©Ê÷ÂLò'[ùÇ(*Èˆæÿ²M#±"&îòèùÉ2i±"Äÿ+!ÀkP³q…'¢R€&‘0úñœ“ˆÉòC["¸Ì>‚ş¾Óq~Gû‹÷Ud+u”uA)ÔÙé°ÍòÅı„IÅÊéó…[Ûfpå»8iåóÜLM%‰Ù\´o>ùxçíş5ö³«}ç‰~ÿ–ÚìSvå,Öw¹–æA†H¹‰È½Šİ Ô©K„qó¥…ÛÃß&®dç+é»bz“é[Åº‰&ç¨ñBj†ïŠÌ²¸û  pñ JÈCg`µ $‰> Íe“š'[.µSQÌº:mS!HXtºD4DŠô:j½ğgÂ¢ú	¼úDÇ$”o·g„æsñ„B½Ì CtN¨O’¸\}CtÀÚ7~í(î›°ù¤‡[ugä*×øÉ½¡-‘»jH÷ñÃ}^t…Cj^ÈŠ}<¬ ïê×)6f1×bíXd(CÅGİ]uÚãíq€€°ÄÃ­’ù4KY
¢šnÅèîkíüYŒ@Œ¤0ğj1vé_ğ¦0$ïL1c4XîªÕVÀ4µã¨>#‘@"Ş\b¤«“êÆÙ9Èè"ApØ¨§=«³„»İ¶YÎiqÖ{ŸbÖû òkq£-Âv,7Oe)+ÚõW¿äC}¬Pò!7ÅÇŸ¼<·Ş°—IÈ@spPÆÕ¢(Ù,}U"¨/¼‹+FÎá÷KƒéØ›ôÀÈ,ÃÍûqlµû×_pAëY‹Ÿo®šëˆèw-Ag¢.ïTh©Ú°•&Qàv¤^Áõ@Hj$+eô¾òå‚6yÓ6TÏ*‡ ç!ğãl¡¿sh;<î`Â"iD f1" %?wÈÀ&¡…ÔZ4 Š:#RV¯”3bèÔĞÌd-ªtY*ŠrÆ!rA9éÀ3ïÒ2º5—ƒ~iASU³Äõ_ŠûÛº*²Bò#²«„'¹<™&C°6h¤jš. )w&k×è3˜GZÏ4‚|.tË©7“íS>,ÚH»9á}}¶‹ªlfNİ–§iÍ¶ÓæÜOFPìˆ­Á_T
9Ê‹ÏAOóÛÂ[õÛd¾'“‰Øb›ú#±ßN-_@.²(T£ôe‘”#^M²§V„Ky|‹+–Èƒœô¬(éâ&ˆ&”¸ja<Jö¡¬ØúïR+ÅŸÕp{V‚"²µË¹FaØ¯%,-ÿ1ÕkqØ}§v³Œ·×P¥0£€“1:øn¼º9‡r ù
¦|æm^jíÏZPíL9îØ–³Ø÷. Ñ[är9ı1GF‹äoa:‰à·€qóó—®Ü8{Gµ•š‘^ù8ÛË^H7G0†}¶¶!+¦­âãå|¼¼‰İ™„`lŒŸV´øëSpA»Ê%Û*¯*ÿ•)€ GLèê¹éGÀÀƒ_9o&ûg´ÄE¥À9qŸŸfÌ£B»ë‰/¼#zı¥`‰óTÓ…‹÷sÀ©à /ÍøÀÖoºÑÕĞ@Ç6Vu©½lg©‹úÑŠRŒHÓ|Oû>^ê¯#ËÓ$ÔÀt25'Òš(ÙÈĞãş9™p*0ÃŞŞ<ÉË³ëeÀc•t”FvµßU'|¿"Û°¼ÿ]Ù­5½“yaÇ
 :±+‡b|B¡°†¤|ìğ%¥G¯ ò´œdõ†Y— ŞÆ|~Á$‹…@*%÷eXcTG¿2Aê.S”Xåca‹HšÃïgm?]ãoğD½iÂú&hBéz¼Sv™,Ôş1që9é_}SÏ‚üºaºä·_¥è¬D:ÕêFÃí ‡¬_÷•„³‘Ùgçc–Œˆî!8gèÃÖëCs¨Zg˜k´K£i3	m… ¦øFãRĞeqËX&zœ€X\uÒ¬¤Æ»¬æj1 +f%=D®àG(? r}&{¼¨p·IjX»í¨‘±Íı©Â¿¶»¾Ñ?ß:…Ó“ê4œˆŠøûæËãd‚xƒ x0Š“ø}PVÚÎBZ×’\hÕY’Üå/QñÓM4¸aëj0LLq.ÜM÷²ˆ²hióçÛˆñùØı Oşyb	wïZ¢Vê7 Ó;v;·cÛ™K‰¶<tZ_F°qúá!^“+7O¦\÷.û‹¾ğØ'C<\šÈ0ä8#Ëqj G!Áè(¼	æ0ãÖ}ìÎT°›Ü»*ıæs‘´ÒŸ¡²Q"²ÿ—­Oô†NÎ*ß§mœ@§‘BFáÆ¬ÕBQQnïPïtÍsê‡íx¸+ 0Z]êÚUÑ§ıGÿó7ÃK½>úßxô
Œ}úë2ĞzÈÊÌgV%h×í±‘ìo³•/¸K©ğÍ}kIüdşrØ„¨®_kn&Ã’é¹•‚D¸[¶Œ\ª<ë>È‘ĞñRKŒé¬ÑŒ–¨jt,ÙdåQ' å÷¨gGÏ0ã¶bZÕ"b©×o"šÒ>†ãïÒ'7ÏRËË‚½vI‡Ç0@j™LB2Kyg·Öİ-bqw]qkNZĞ†ó³Èñ­b·Ó"ïÄš¾ëO÷$O åŞehnÑ9'¦uy/ıvK¹*4…İ”pµ<‘İ³èK•ÿ¨îıŸ@£‡ lêÀóÇ>k´«&W‘˜Ó±f.hºÉ9le©}MÃM»À3N¦·}´‡#‰­—PGŞB·=Aòs¯'Kl]üÊ¦[·õ(§ë¢ÒZWdnUÚêËa¤fÕ¾wtã
˜§¢€èÃ¤‘‹…R©Ó:á6B*•³Ñ¬£Û—¼Åa¸ÜsCoÌ\:!×şôß_¡…Å»D I1ñ'sš{:¹ˆçQ†¾xÛBG7°¸lØDÿ¢E…8 ¨ö$«‚7]nfB0¨F‹¿9Ğ–AÃíkCóˆêÕˆî&ªw¥WÚú±®•²Ùê~Ûü¾ YaıeV3²E§Š!@~¼U„¶£ƒƒ¨¨âÇöËÿ=+0B…H{—*ÖóÉ’<!C	.zøËŠ€À‡*‚c@ä#¢v®LP’¿îé”Ü	ÿÙ±Ô+gBdİc2.şœ°åázšNPËMD\®}â[ZäıSFGÅíÎ|r1ÖÀ›}.š IŒß©TœìkG~ä12„ô‡*Æ½y$«`p6šş¡ÆS¶á$),1ƒë”szÉN™tŸ ’¤ieR­ˆ5ïí)uÁÇ‚ÒqzÑÙƒHûÇ7‚ÇÈdÑÉrvMë~ˆ{›Q00ŞÛ&Oµú8™õiöïÖ<$C¥à†¬Ä¬wŞ\f˜o‚j.7»:^Şn8 ¨…ÑÒØ†O¦Hd-Ğ|ºÈiÈ¨Çm´øyHÁ,«aO@ª‹4QÍ¸•ÇÉ_¶¶=ÑC÷wïX4ß“tÕähzÕÁP`‰“Š‡º—*m’€¨j7Í
.†+§èÿ¹Ykºsƒoét¢œ‘ÆCCRµ‰)ÿŠ—Âì/õãª`ìK·õiæ,œzsµ’“$V¸/²ì#áãIDã?˜[ü„«d6Ut 3zm\ğwŸÒRşmXôÔÄÜKÇ"_ÛW–©Ê³v‡7ÓÑ”OÃ
¬˜D£ƒã)İÃËŸøŸ‘•mË$ØgËYè/Áík t …+ß¡‘êë>*ÇbÖ_Ë^E¥´
%¨|Ÿøf¯TCX‰U7ïéW¬±TÔÀ}o ¡˜™éØ¼Ï§H©2P í|Q>•Ñso¨Òf@?F¡Â6›wàç~]Ek·ÿqAøeÇ ÀñåiŒ6M¹t‘šŸ'!Ís˜†S.<V¤FNwfä¥\Û:òA,ÛS¡ÄV…éD’ ŒødäÉojg*ŞáA0û:›æìÓÈ|B ÙKŞ$›IkŸ\–}“àˆ³)uøªµÌ[Û)u±yÄy¸?›Køş\+ËºfC‡kddUušLTkß|d<üP.åXk”#¥ å‰Ï0‰Ri¸È©)pÿ~İò¤Êƒ…s¿bæMmo·¢('/´£l%Ôy8B©Œ,š›{L@È~ƒ!@·XoÍ1 C²0wå“‰ıWğïWìóÉrÔèt¶n7Gıgµßìá3Æ+õÎvÖİÖ„y”'hÑmºº@|;Ïù>šKÒcõ|ŒIŠöK7_sëeá?Üİ™™DÊÌ¡#À‘à¹˜PÚà£Åİôc=1'-[W“×ç8"G)qÂã]d§©¹ òù"88ryDàäKíô=f°‚ş*;«Txlã&0·•dbşÔ{¥î’ÛÑ¾_…f_æ¥•ŞıOêjÒÎØ³õq–«¦¢‚¸.xë¼Û¹3Šk%ŸÔWëQdÉÛ ï6a,`Õ˜!¬å¨/C¨#®á<5$	³ŞøOÃ“`ŒóR
'çœe@²$ÙH©y9œ®â<mhÃì‡*R çÜ„uíÀªË¸ô©óªPÔG@»Ğô7°„j”Í/¿ö–@$öìú‰ë’Ò¯R“mU¢b?$•^ºDMùÈ{r¼f¹÷œ'Z_Ëü)Ìyñ_Û¦ĞÙoeXkH~¿Ô÷èÜÇˆ^/ëW+Vl¹;U—«ßßJAÆˆKó˜æb¬2«ÈşôÖ˜ë±Îã¬áÃ°jï‹üï‹sv’,g£ÿ_¨á»¿2ˆğšò3‡bhŠ:®)wAI¾Ël-7È6gÓöÿ˜†Õq‹eàjÑ,Ä*õÎFM’ÎÍFôínšö„¯‘–X˜Z¶º<M®Eê»‹jÇï8–Ù)ãéÕEN"_õ!H/Ó­)êIï&Â¢F¦e­ÇÃÆ?'É?ÈöëE‰—…<a‰ª|~\"CÂ¯‰¯µ©æcª+)%È©T¢ì,ß{¿ãx’Lã*Úóœº…S óm8e[Ùí•Um¤P«mÑoòœdÎÛ.ó~·á…86ã/¹¤páyâiS¹'¤Úi¡…îÜ(o’f86H¶,u!œ.f(ğıeÛ«'Ÿƒ´šİ~“/u\ñ¾¡
#+÷Lò×PŒñ™F¦²†ú©6H_ˆ1nu¨Oèëlû”k3“³j¹A^úÚ§oßƒ`fØ!C1b¯R)ÓNÈJ‚ã_\ÒÏ°-ı	!ı·ƒ†'b0ÅâÓœ‹}¸C`oŠAùN±rßœA¨ùx2ëÑ®pHá^â¢y{ÔÅ&`yB¼(QL©¬nÔ0ãì¹l§³:FS&Å Ñ®Ëåö©¶V’Ü
ğŠŠ-™:úG<Xx7l°„çyâ£:ï\çOX[9¡HÅ5ar,ú€ ¢ºô8Ú—¨7Mu[X™[½¾1+$\%Çì$dG‹¨.âC‘2ŸHjÚX¿‹©.È%’âÍºOLAÎr¤t-ùÇ3!_¾ùá2­›ÎHÇD—©É–É4•À qÇø'p2£ä¸8j;“}îNæ\ºÜ§oYë½sÀÕæíåxTÎC¹÷%ÊsôYÓ‘FŸhä~Å“ĞÉ~v€p>¾ØFT’µ÷£…+ÑÁXM9´é©ß¦ÏòU…ƒ\·/£a_AM×4Û:v¢˜:>«cğÊ_—C²İ˜Ë¤&ü
ô‚ ÚÉ¸5‚M2’r/Ë‘ëÖm|şhVé~^­–šy±&"H³Q¼Z˜¸çV(á? ¹Ÿ†ÍÖ*ÉÜ­‡¿$&„ù[TéFyç>Ó^µ•c5IÁ!JVNm!úÃÕønÒ#b*÷›ë¬Uxµ¸YßVlÍ9/^XL^tUîT&K•„vr(£6¦As‚J¶¡MÓ7»Oqsi”€³˜LE”y½©ù´ä“^€wPyS”’ùUŒ=¬–ôJºk’ö‘êºƒ-d”{$Ù¨^
o§É×ér2Šs§İ:9 Š¯p¼g“|ŠV*Dãë?BÖque‰z‰álà\èE¾ŸÂ7½*?é·ÜtèÀ£Œ»#¶öÄ£Œqşüë‹PTCo‰ï„â£óldŠ[r2E …|5rÍÈ!˜ñÊÓ×	Ï ½‹<¯E3§hÒ~Ñ¦w²‰æfU³Ú^Ê¢qh†^ÕÔÙsEà²‡‹Üû…´NÇ“¡<ï!ÅÄ‚qŸ®­wQÊÆsn}&õ=W–í¼°,3YÃæ¸7¯ÜÍâsÑù÷³©Ñ¦_ŒûNTÁ+uz$İ‡8šÿ¡!"têöçv/4L fSG.£¼š{c“õ*pr9¹bcšA©›>Vñšé™l4îÉ›§xüC9WŠ)³GŠy×³^Ğ4“î—,SêkŞ¸œxãEéŒ§º«‰qbÁ	@n­­"û@ÿ·ï3*ËÎFjèÜñôÔËï•µ7o‹ÀÅ_J–WÙ¼ô“÷_é©4T-T»Ó®F[8ğ¶!¼—m`¹KG_|5ÒÙ­ápª´3z:i/1­901A}æ¦tL/ò@"¦J¥9!|DRº¥¦¡
,µúU>À|E¬”\‚¯OÇßYü•³!¯±·‹xÔØbcÌ6–'µ€ê.(HkCMlèÑ‚¡Ü˜Óu^ïª;`Ã?Y¢~á´¾±ÊŸ‚;Aa'Dr»½ÄÓ×ËÑê,eû)¾6³V#‚ö´3{š5[ˆ/®Sëœ·•ì €–œú.‰z-Ì(ÑÿÁ()2C4*;ü[–‚Gñ’ÅÇúĞ<Q¾[iÇ¼Ïu«é£°((úÜì[ ^Ï@Ä¹Å#ºjE€Ãk‰×mæ‚.ØÆ¹`l$Ü·H#ÅŒ¹n÷‘ó£\³-SÕ»	)¿Êà+xËÂL,I/¬$ğÆÏJ5rİ_bƒ¯P:@çòüFµ1PhMÉä·Œ4xœ³Õ7XœËåİ•«A¥™ÜŞÅ—IøTcôã-G‚ÊÎG«x¥ˆÿÈ¯÷Ğ´Í¿ĞÒfêÖ+7fC ó=([’°å.ì=Eä.HO.˜£–<ÙÁâéÆ,"ï¬6®ë ûåöî¸Ï[º-ïĞT	ƒ[(cØK=»7—ëŞŒ(î&È¸å› ÍÇ×pd:x9U~F“o`8hhÖŠÀl‰L°/­T¿æbâ•$“x¸~–?.³È^ËUÃ¨w%Ê~Ô…Ìí¯+şìY|å 36öa™ÅÉq/›Ğ¼>eC÷~Ôõ{şÃ¢ó¼
‡â¦v–¾;¥XEN˜M]d›ÏMÏ%,^¼âlå[úîéÚİ–øÕ~ùsˆ3¤õå)ëJ­”„=høÉ´‡7†jÎ3	'çèÑPæyŒÃ±($‚VY%€½AŞ\¹XpVWö=±îöDfqæÏ33½$³n? ®Ï#B¢óTw¶>)©îòÖÖ¯”ël©®_&)ê9)još–£GF¼
¬E]/[´Áa3âé8ƒf…™¸gE,š•?şÌ&/û6.ı3¸ª(DWĞÜËVÊËÅcñZ´´šJİÑobô,¦¶ÕeÃ.á°¦Ù-m <Ú×µÕ™uuï´Å5Ìoâ+sÏ¢¾ËvĞ7€>b&ş¦|{|IœFù &H2.ö„-p:íŒ rQıŒÌØ"Ó•ªQò¢R Ö¦Ë`„Rã~Ó|­aÄ˜ïGğ•Ø2WE%oˆr\b:éGâèİÔUêæ¡Hmêé‘0s—'Ë’ Ó<yÆ?MMå­DŒ‡kU3M(+_šd–üˆ–nÒLä©ø"H6q‚K¦±å{@”€ö8ÁÜ‰øà³¤Åş¤Lj´Íñ¢×|Baa>W=›{LgÖu­é·s¼9Ñs NXŒ´áµÁÒ®ZÌ'Aã\ıû(+¶ïŸs€ë{¿…s^RFíZ‘2XŠvÁı¶°“şÈ—.¼şØûP&³…Óñ{zídê“ÂƒÜÕJb?‰İîw‡“Y¼é!ğäg£R!°<;`{Ü™®·	­©×İƒÊ2€Qjj¼Ì)v7d‘3
Q!"7ÇÖŒü,FÑæUíßólû‡tëı5	`*ƒ
ÍQ ”dîëNt~PúBšï´Ÿl­Ú<?Øˆ¤5b+Zä‹ÁïyüP ‚1ÉïğÈĞ*š›BÃ²÷¨É…ùYU˜K*×(±,=ŠÎÄfhˆ™ÇÍÿ!¿Ki‰Çmaã¢•úmÔd6Ô©âoôQùs’ø±‘¯œ½‡¾øÉäTKÓ?Î£ËúÖ¡sÖ	nGfb?šú,[ÈN•ì|˜o?äZ)”íæ·êG‰QğÌ«ÕÕCo	ÖLd£3Lâ"?ÌÒ„¯g—ë¸ÛatO¯gı&{êÙ c/Æ;b.\z9Eó·l9ƒPéçxÚıÅ³]Eéo’‹_|«­ìÓnÙSuLiæ]”[ìıı!\ÿ3Vß#˜°µŒ6ËŞŒQ§ç.°/ä¬È=A§;›¸{ã'ûĞÈÄQØcÇ¿X´´Æ4!Ñ—Î|H£x†3å‚œW
,µ!–:¶²£ÓL
gdŠE‹Úf(AÆBÏ,l”8`ğÕ.Òòßöòß®“!?q}Ñ\5rıe¾ˆQİì¹ç+¦vRLMæ¬*>Å)¤­›$¥hô‹{AÆ¿µ°¥ÆÂË¢èî³ÄB\ÈğxÕnb½‚d7=EĞÃ¶@kÑÚÒÌ‘(å~PÂ df¢KcÀ`j“QåŒÕÛßR¯R9`/W¢uXœJ,«e±³¹[‹6·ÎÚY}rèâ®r“µşX„GW•UËğ)ÚZuuz*P´(`°#E¿ÜJD}L÷¿u¸ÂŞ#ÉùZ°á¬:F—&çó³Fù”Eó‚“ŠÃ¼‰x;æ<Dì”Ç ‡Û‹dwî­¯æ•-‚{{(<©óÂ¤ë­
òúÕY~Ÿ'„¢Ô{*xWE*S×B-²XÖcD¿…ußi_¾¼lbº W˜Ğ]ßŞ8¨zF|Ey¬!ŞºšZÉ•M8c–Q”x§ù‘BHY¹5,ÈAó°·8yÿÕX6Fm2Ù^F…¬ŸNœ6ß”<«½‹XºÏÖ‰Éõ‡Ã¼a`_‘ÛâsÓàWREŒ³~üG^ó†ìZcm×e»=E…JìWvù‚¸ü‘OÄ´E—o‡F,'»9X½eª½I!uë%ÆÃ¿½İÃ9rc“gU{Å¿a_§Zœ<ÃçgP‰ƒiÄÙi;Ù ìÃì Ñ†äfM ·HeT.®6è¦Xó¯Äê¾˜ÛdÃH©SB°İ‰„UD®¦ëV´F·CFõt ş¾µkB£ÜÜqÒüØ0Fÿª‹«uA=İ€=¢‰ØşÚ€Ş<M³‹›9OİĞİ¥L‘EìâÛ.fY>ı³„½>mî.F²N[K*cí0 8k?¦KvÃ¹ÏCË#èÖÆûÕĞ‡ùÌ‡µo‡õ>ÿóAÊmîö¬ ‹°péf»±{f­”’µ±Ş °mDŠè³·U«™R¥w¥H¶p(	†2VvÌA6çÒ(ÄF=#ç‘>ï9S!s€°åÚß¡ø!F®‡c¾|m…Œå_¿ˆøMÂ·Ay£mUTÇöN	@Ê{‰Xî±œ«ëŞğ
”NØñ	ìMhĞ®ÚVO¸ ¨~’+F|‚Ó=éCsŸjDŸË"}>Öéßõ®ì¦v±qáLìÆòS&cÑ×h¼›|'@vÆş{îÑ£&i³íšüÇ½àıŸ1b[ı?t÷
b¯ÀêzI 9Ûó{ä7aZw¹è)4|’(FÅL±˜šdò.f6D‡¹DI“Œ’¼İ£û€Ò´.RfŠkGñ™Çíü6¦›Ø]p… ”Âdÿ
¦éŸœˆúoöj¡Rwm¸$ªû)üÈQ44ÅñD]ÓÖâZ¢{{˜0êfy{•G¢~vCG³¥%Å‘µà
 ‚;YŒGåL¹×ıÇ§N Šızægí&
0¤ÛŒ³õ¿aèĞ3­Ç¤Z‡¡Læ|ĞË3[G WÜù½ÃÕB~éeIŸ5¨kïl5æj”nCÄĞ½GµpE?AQ+ )Ø
¬ló2ù<{ùë<òÂ<äEã4óe£PÆºÊN¾”£f(éßmeklm(cn¼^(¼«öV™7'¤I|ÊÖ$"~s”p"{dkÌµqÊSgâ,™íÖ©O‘ë4®¬îÖ0¾QçV&}“v›©å´)Ôk.£©Ûò?@#lïI’ÌGÖº‰p<°R’Ğj!7z&kDcq4a‘ıB¦±]ºpr@-˜UÜæE™L¡T†™³5ò¸‡TÿŒ‰ q²fZÀÌ ™‚´–A t60 hÁœxŞÃÑ8¤x‚Îí: X>sïAœ„¥m*–§r…Şƒô§{÷ïo-gè´Êşóº)x§å]Àù5"[nÚ/ey¿	Ò5€C$=Ş«bÌ9iõãï†¥1;£Äi6zÚÓØÀIş_)¯À$z´ÀV@lJÇx™¸İùs÷b4öxïŠ{ßë©§Š€yòƒúç4²Üß†Y
Ùæó‹#¥ ‚{ìø©÷Kÿvñ¢p	ÃÜ.7gèÍ'¾›…íM›ÆÉˆ±ª½÷ª°¢ãä´(—İp7ëÌ' ìt#¦~g‡û¯ƒôÑJ@ß\éO‡€QÚHœ­HCØ «Wë3™­ÇyÍtüş^{?©Ùx-Oc³ú„¯Ú¢áJ¡uí]´2^ ÀP–yÓ`•ñ5Ü	Ö#Vùœ%4HœTÌ#ï•’ÉtòŒ2R#útÃñï´úv€a²€Ñˆÿáš‰ÂÑÓ7Ş?ÍÈ%
äTıCıA²™S·İŸ`Â« XPDqÎHÁ[,Ş%=n4Íl0aLÂVŸ œñ#'¢¹jfa›–:B Iº\ij¼	íZ	XquJf2ÏÙípHì°ïÒÚ£ş»U¹^´·ªbºPŠˆÿTKü‚"ºH[ŞSx%Ş®ß\…ïl®>ÌŸ-„¨(cèTÅ”E—1–|çÉ@L•#9¾ª­~¦')Ö#ÁH¹&wJ—xì&ĞìRÓWõbŠsaèjg@ÙyË'ä½ˆ„!t1vø¾«š·q$Êyöod#]`g‹B’õQ]ùğ0ô½ŸŒoŸ“RbZ()m‰*Ì1óËhô’Œ.ğÆFü¢‹vUÁOŸ?b%Uº#ŞJ/Ç©I—2jÑ§ÏÂ«Óıã±sşA«ñ1=+\ı¿S*PòÆáEÿ—Ò[å8Öºæ!Å.‚Ş¬lr!Ş]"æÍF®P\ŞíıVT/ˆ«)Æİøç«£×" f©­\K¼óí¶ó²åŠ™‘"és¸f¤8şÇ¿@ºA–Mıêö&¬œÕ%¤„O ï`9E¨©ei5çàEvmªÀ¸¼êİsºÿu#g+’	Ê{Y§– §‚	 æVĞngÊÅ…F	-µL¦‚f›Z×»Yî_G{Ø=òÆl\GCƒ1f'Ú¢Üª_KX°—ª1/ÚDırtºQ†fLTí øù%m{™vk°®ÑşĞ3Ç¯œ¨ìÏK ŞB®ŸIü•¾h‚«f<·5R8R}©qaıs9î¢PÑPÑÜådv?b˜X–ñZº{eS³¥lN¯`wMŒzà:æß¾'Bæ‰¿]|;“
l¸ùF³jŞvÎÈ§ãnÆ/oy]dp§¨0şµ2É˜6º1Àê/ M#™¶ïM}IÈòöÓâmİˆ€Ä…Š–áİH‡C<UBûªØ¸.¬¼9›ù9¹™	gè/Í~Ü ™0òó7‰-~èŸ†¼.‚áÃxŒ±ëgèÉSÛ†‰lnã¼§Ü¡nZt¼eLætG#M9{Ñpù©øQ&„í@ÍÆô§MÄœ‘Š¶ ->ĞŒ™¡ßû§¬v€·g\Zj–ÇåğÃ} W[Ê&´J•…vª¶ùaZS›Ê#ÓGrÎ¯ã¹f·²¥I¸Ïî>V,ü¸};­"I¶MAGX¿ÛnpıŸsØ|;aì&sN„ğy,õlTV­”Î1ZóyÈĞ÷4&Õ™ÒË¡ıg]Æ
ÇBÍÖ{Šâ…?S¼¹;U´ëÌåN,’ø<Óh@Yok”Ğdi³ÑŸìŠ¾¨9÷^®‹=Dy°äà~î‚;ü’7P­^˜I¹.ÕAªz?ŞtŠQ^mÜS¢P(‚4ñ½’ÏE­PX±mŞñvgĞ~Ä)çôÆ
gúáÚÑv§Øßõş—©ìHf6ÂÓTË¥-ò½mÄëÿoŸñüFnbõGùj]úóé]sñJW¥àê	~ÓÂ*Îu>OÖÆİÓÍ°æÕ	Õ²ƒ$Î÷ü†úoÅóŞ§v•HÑñ¢ğc‡ïqøŠjşé}m)-£+õz¼ã›‘llæ…À™§j¥ÖOõLV›Ì¸\Ï™Iîù±R’µ‘–îyRvQDw¯|ÆgtbØêÑ´DŠo¼ZĞ>¡¾ù®ŠİJbEMÏO²çyâ¥H cE«{å×,@G1ëÕ^§åjÀe|ï}X· ßDl“ê¾ƒ®•³Šx”{·Ö ˜¸ù×Ä*ÉpkÑ>I™ï"Ö°vv3Â¶°£·‹õÇÚGÔŞ@ 	@eZ¤©qHo/"À³ò#å¼'íÂ:Q1¯%†×ıXV©›˜uò•­×~ Ê—;tâU„µmO2uŠm=>—Ø8ö{-,Ÿğ ò2ö6ÙŞ¤é¾PÈ–ÌÙ¡9‡>SdÖÕVm¯ µ3ï’¸qØ# Ë4„wÈhâ<¦ç0SFà™?‰tE]ÔcXÊ@jàQ[ĞL ›	•¸´­ÇŒ¯pxŸ/t°ÁÔ‡R{}){ë}¶c˜îŠ÷*¯PWL/Ì×ÙQzûÑòÖ¯_`G¯ÇrBVG…eIáœæôE#Šh.…;ì %^‡Ê„eŸã7+Â>n§‹8J–Âƒ&/‚ÍUÆ\×ç½Ø)HÏĞ\™0—¼6Y5äÁITL9µ 9ìd3”ÊMŒY+7vîÂÄ×S!ŠoZÔJ×šÑµü¢²ÊÚla$ü·Jl£zÀ/q	C±)fqÑÍgæZÌ”¤[6
•‚C>¯%¤hY#Ço¼a×3B„UàÑøŒıÀE’À™L,ˆïº˜Ùß”@5´ó¢}sÃL\nÿ='^)º·QNì™@ƒÊ(é¾7›·äû_ÔH+2„ˆ¬F2l­o	Eñ÷G%«”£ÿüa|û¢*gii™ÿšD·(±—Êû˜PƒCPwªğ{D¤(ÙU±/š349Ê¸Ş(YĞMzsŸš?÷ŞH[ë«u~ˆvR¿DÄØ©*P[#úyòŸKyÈ’1´‰F;côÙ™I=‘Ybú¹RÛÏ«İ<l#œ¶¡j´m»Ò–JKd}L÷0)mÏµ›¯”IµşNì÷ ÿFZd{wœÅç™òuÿ >sŸ:İ‹mì<Š¦D†î¯a‰‡i‡ÎG@wÁ Ê7=ŒšÔüô(ï€`7Ì]˜Ajğ:‹e8ĞÍhÛ«$¡-ÒKdìbp=yÕÿ›%…ÒĞ2©ÿZÇĞ€ãÛKnlyŞ6c#sôãñú~aÓ=Ë6ÈõÂyàÂ»ye;N^aÖØâ^dœ/53ãç'2ÛÚÖ°O¼,'’µ;ğïÍÁ06³0fÙü.$ A{w›?·÷É¢îp´Ïó ÿËÅØ5ïtÇªç¯J˜µ?¿„«òç
D•)HuÈ¹SfãûbZYÒyØ›¤áb²ı—!‰øú¢šêøÛÂüÔã`1–’løÚÀXô_½u¦òõÈ+*®iGÛ-¨!4Q¬£|{`9¿ÑæRšÿE»èp¢p&°çlmùÃUİSsÌ`rÓ's®bà¡A1—Qàå›ÏÄ5úESmâ*OÚ®Ä£âMuwl@üÇ@TÔH¸â>Œ?„R®°d9ƒs¨ªÁkB±Çèò8+ßJô‰…#nõÃ&Õ‰—S_ç²gTô"	{" ¥o+eSQŒ("÷`¼üf¾Îj½ozÔEüé—vÿ|Wâd¡‰7¨T{[†¬û(Û–“‚"?ĞQÙ¯Pß {*­Áì Z$X ¿:êİ©S`$Ÿ@”¯¶ÄNğ½möÈ‹M@Œ'ÚÜÂ»é|D”Tº¢‰l&±øõƒb€kÇ|åtá"œGF€bôÊ‘­F­úpå4vLœÍÏS“	¤àÜ’şc\—PHR@ mth¶…X¥øóé4ĞËZÕp¡aoÖ‘m;V`â¢¤”Š×j1»5ıı3Ë¨?ÅsÉÃx_Í<ÉX ùHv`ÿ?…ØO.¨(hëİ‚R¸ó.¿¡ZÖ÷_u‰v’ª^OÛÃ÷ê´¾ªïÑA¨s%mT#Có vê3şÊÏJ$°o,N\œôÏsï©V¥¢ÛLÁ¨(ùò)Jhç–¨wr ËšK„ùÔîTo2:G¡b¾í¿ç Eç+oÎá.h²A'*ãauÚîéÊ† @©¢£Ÿ1® øîumŸ_vA ü GvSsW:Š£ÙİË@îàÿ÷4´3aƒ0"Tâ‚›o+¬%WX&…b€aG%É| pR$¥€ÛGw’ïß„¾Ôaœ¾±©‹À˜½Ê#ı`§£´İñÔh˜¬öf¶³$ddÚ¸İªÑãØ’®>6uvä”K {BÚêp‰·zÊËR;*§ä§=ûÇ‹i®Ñ¬­êÄ‹°æÆvDD
G3X½D‘Ù×Ş˜9¸’…Ï®´"CîÌHÿRßsNr÷?—ìi0Öo“>œ+¬$Ç*×Z}o%ãÏ’ªÄ`*ªÇ°râç3?ãß¼}µÁe¡£ÿz`¯“rRa*(ê-w~ßu#dÌÉ^aÊ°$Ókgh(š!UÅÁş³u—!˜ò±Wò^Ş?	¿ÈdÜ³ãyÛ›ûEõñ,]d	ÚPÑ}Œ&ÙÏ¸¶ZqŒ\Š]-A.;M÷RF İÁ@¦8Ó|#<ÊşÒßú÷èÓì>V'9µB%{z †¢ª ,¿“jëéD¹´ %¹¯mè®ÄmU’Ÿ¹	È«ü®eY>/ÁD1DXkñ¯˜KEÅ±+‘ãpHü+Ì[2N˜ÔM«])ß©F&ÔâgTj@pÚ,ĞvØ1¦¸:ºpjlÚ‘P=ª“'W›jœÚŒ ¤š‘È‡;ªüæ¸a÷Zä_xğ¾y1ø<ûÿV‰ƒY¶±C:Eçk{%{»†)³¦O R­Éƒ{C¡÷^Ñ¿¢7ˆ›7›ãH¾B¾Ü¤¹”Gtˆ²ü™ùÜpii®Æß"tÒ4OîérîED:Eæâ×Ôù=0soMPS.­A`‘J"Ü <D½º€š2q·ŒÃ„S‘(ÃİAƒİàäè2€º<;ŸÈ´Ïó%¡L°nGÙVó½î§¬©O\şä”AµõR&pï5Xˆ>é"CNŸ&R¨1—MúíYÖ#¹¤Õuiä[$ìºàu$"®`µÂÚĞ”è0ÂX<M^t‘ûQHyúTZDëÀÄD6¥±e£d>BæÛ¥¨ö@´“È`x!_g3Sˆ–ˆçğhqp¿‘­_dÜ‰$¹‘ZDÀ2yÄÉMjm/‘eCÿ,SmæZ¯]Ùó;İL×U}ç¨¬â#¥WY¦äüÜÔ+¸r®hYI 8´™æõÏ§¼ëºK©\!îH’W“‘³êØ¶K|„“Ü¾!NIO*Ä±òLÜDz p„,~IãÛ–p_·Ş(›da¦\!ó­l"Ì'ô#}9`¹=Ì‰¡oé/®ÉÔúh İ¾ ÿ¹ğKeÎš].Ø1©ÿ·PU!ğŒUi©Åš?…%¾)…ÑR¯tÁ¿õ³²Sù~PÇ5Y‹pÉbP	©ÖE—²¤P³`*-N`‚
À¬ñu}æO´’/çd
¶öc§ùU€ÓÀK˜›aÃœQ Gh¾ÚH°¬¾”_Ü"*ê„ñsnŒ• ƒÔk)?#vZÕ(Å"4å}éµš«iGÃµ±&lËÔã(2W¾$ÊñšØZÛåÅê~%^–¹ø9ˆ:oÂBÓ­„`´Vô—ä¬æøZ¹
Ê
º©Lk’ÁÄeGä<DÈèõà ¡k˜0ú¨¥(]¯2²Å%P:}šŸŠ9e70~ËÚl‚lPö'úu!R¢YÔrŠ›ŞÁÕò›^'ã(–×ßÄJo ó™UœU|¦dpÇ¢›³±'c4Ô#T«e»“tvtbhòOwQ÷\ÇŞz÷ıŸÓNh{ƒBî=$ë=Ó¯NÇ<–‹  ä:NQé{û‘ëXxºœåWYÏÙ4áßuİ6y…äÖ™ŒvN?o#âw¾MS˜MÀİïİIÛ,Û	X–I#AÊFàxÒå,Ÿ÷ƒ¡gTÒGÀ›¢‡K?ÆsÊkäÚr@ˆ]uJ.Z§±T9I%@=‡1~%Ü+…Æ*ëC!ß_^³1ÿ°|ŒÛHR_M]bÌUó	[6üVò/%£`™MÓ·L–í¨Ur‚ûµœy8Qø@«õoÖÀuØÙ©Â€"riˆˆªSÜ¦ğ­“ùÅY<-´y±:ŒËEÙˆX¯”—s"4G€‡÷Ô7(2*|w	—¨¤sÑÀù<°ù¸hùtZ/&œ1ƒ€<Ñ%ô;ÃMô°ìrÙhŞ\=Ì¢’~2¶š£diDH®à†¤`‡–¢‚Ñ„ÏTêËÔ,¥#šo™WıÊ$Xl°	ß³6‹³gË•iñ;'ŒÓ‚ìeğöŠ¹_1Tn0ÖõˆìYİV¾™×”âcå|`·1ÇÔGö~@†Yöî °¹JE<İlF´±Í±€£»A¨@_‹v		ec(CÀp¿lÏrX(ácßÿIŸDKØ%6é…„x¢º=¸Ç¿†'UKVÈ€ÃZ‹}„sçŒ¸‰Ü¬ŸC».œuIâY²^^O¶\Ør™Šî9t¹¯rÍ[˜6tœœÈ!²ˆ{—¦ÙÊÕ©ê9±aj†¸úFeıw&¹‹²'º2uK.n,ûlĞDih‰‚%Ğ†–Ö/pÖ=pm3-…N„Y9T#ôj^pbi·Øãîîÿà"ãÏ¹ú aTÒ‹oz¾›1n«£Œÿ‰ÂŒĞ‡>úéábkŸóÓ€Š2©AâÛˆD°~¸JnLü9ûu…Û]²k¿+õ9„Zé~«$ã&¡²]ıËÉ|°PÖÒ²´:ÛF~]ºÊ`{Üı9”aJ¶À÷é[ÅDç’¢z#Ödäû@}ûÑ&b@œÛ2Ïy Ï¢<C§–t¤‡¢†ë{Šıj©ê4c¿ß0Ù]ÈÖ—ñ}Óâ=\§F•X¬©Bc„ÿÁ§yĞàL$e½HH¼¸€ß¸eÛD†~LvwãÛ€d¥I¾lúÄİc»6¬ªóÏóqÂÊ@ÿ=õ(¡3¦uÜ1*Öºmtrƒ´-QÃÁúføÈ…†ß>5alÒtPY‚¦×u’×+¦ƒeUÊÏKĞ®q ‡Õc¥Â–KXAó‰0ŞßŠ±‹ÿ–$æcÔ*±í“ğiŞM`ëôcÈšğÑ!kàÔá±‚tUrÌ®øóâëër›—A&ˆ*–cè¹?¼°_Şp¨ã7ÇvÎÓ;P½	KH„$Şo÷inÛ*g_š­	Òï™3ÀóÂMÃìH65Òäª×ğ:PÙO“ò½ßê?££Jî>š[KÅÌÄƒeğ(å×v)¯ËÓ&uéÁğÓVNòŸ‹œ)>	Ô)"ù€İ¼o÷ÿ©4´]ºğ'AÀ2<¦ÚÖ½®rC7|t6+ejºûY)¿ÈŠİK.8Íåo”İŒ:Cc´p6ozy:±nªÙİ—¥b%Õà×Úà}¤2_R?}e¤Ø]ÛÀá|¸\òŠ4õ³á±‚qCD`c=eóÊ4"Û/¨ëªgË,ñØnØI¹§¿Çwìjá]7_>ë¬á‘(o¹,ß2­"’İx>'àAÄ
`ÿÄIvìiVj°„/,ñÕú1°1}„DlçÛ’/TH“Ü7³pZSºş™üVë¶ÒY †éšåŒ=µ¦_êÔîä´´Fú!µ—îYìiRİw˜n>‹·¤aÇPöëÛ×€Lò­8™ÚÃ¤XuEÍl¸Ù”İÎÜè¿œ[»ñÉïi^¦¸/R·©PÖ¼](Ú~4,Ôa¹®³q‡PwçHkD©mQhBØ…ïÜUyup›Œb©é}„&ÊH’©í÷–6!"/3ßDËÍ7O‘ùÛ>63–4²ä(»6±Øm•ë‰€éL'¦GjQ Ò^¡ô *;sÜ–/ß$•{wªş§õ3²²Ë[¬ÕíúIÑµæv‘ejßZÃ•²§!tŞk‚Üæ¼Õ2#Py˜9b­_[¨á×<Ùz¾Öø çÁŠóƒ€ØæŞšF3¢ğ÷sõ¨cœú)
õ‡›ƒËŸ-^U.fä%=üybı¥©Ï%]½KqŠYÀã,Êƒ-’Ş4½Kô±µ#ÂÃ®wçƒROª|écä¼jwàÃ„fñI¶x¸Sïû©´/¡w£0ş«˜İÀëx#cp] [Z…¤#“
a5¶Şã\/ê )€	Fêæé6"C	ÀòÍªzÈV3”Áş÷
Í–  W:Ñ†ÚD,PÁ¿Š‘TúÓè¸‘åŠªº©ôÉÌ—öÚŸÜ|¿!GGcÂ—#N/À¦GêOÀàÎˆïP`4“c• 	•Ùq/°ÌL²hÜ8j?íû*ì$[n7Şà¥YA¹ãlÒ|€‚öÍâ¥®kÂ¹€ıpKârõÆÄù§°ŞåO^ö¨k«÷[O£Âûfœkš‚©¦üìj}SÂRÓ©ƒñ«Ú"B–¥÷å¹ZÛïŞÄ}ğÚ	j¤‘«gÀ´™öô(yøcG&ƒûµIÅ8¤Ænk¢ãšEwÚÙ&³–íşÅ,oXKe2œyOWÇø3`iÍ²® @¨pó‹‹è¤ó¸Ï¢&~è
{é9jÁc¥üèËÁÏ·›fI@_Âæ‰?›ûİÕÄ#×”rŒÉcŸ)sÜ(j+:ïGÇä¶Øhá²4z‰ÃšÄÎ–ÍxãæÕ¦„QÖ92ğï—$°«ü‹¸+´¨•¥‘4¬ôj^2taxr&H¨àcDåŠÂf ©ı±{³Ôl*]³‰"BŞïâmD*[xIsiJ“¸™ù;µçË&VæqéáK&´¢îg’	âL.bh¬ş§û£½­}Ö¬Ù1
AĞÜšÂ?vË×	8 p$ÇsÜøªº®È8|]ú«8³mäFaÃN&“0W×éJ;ÁçÙ
t4¹Z~hÈF©ğj’­	#ägİÅÈÕıYäé‰w€ £ahï;JP(}·õF­Æn}2vÏÉka­)ô€®®[ã½I”iˆOıVæ«ø“Åœ" Í6„èÿ£yUs»è/º¶”¯ÌÕ/˜9Í6íáÀ•ëpøõ“\³ª2E6’—“µáºUW’ö`ÔN]²Ğz	|²Âl’”±ñïåüÚç%Bea=›üvéÏQ£÷rƒlÊ¯M&âGé¥Y‰2shCğ$ıu*rx°‚ßä; ır'›êb]_ÿò6µst­Ò€Æ{ê(î¾”[\~VXª~æV“Š{*Ç÷Õ—®ù$—G÷,KÌ6_dÌ0­N;¸ùn¥Áõ8ì°ı;xDœİ«ÒŸ\ôÒ>eñè%Ñ3Ø-“«µXÊ5¡pÎt”Ù¸%µB :²¾Èâ»qXĞ>H'WÆõ¢®#mñòÌ5W*œşâÎùÊ sèU<µ¾ùh’-Qêx“T°+Qğ¢ˆğœ~ØÙ"$áÎ¡†A.ˆ•<ÖŒ%;Œ½©Åı†´©ÊtUÑÓßÇJ…´dYèÆ‡¹]V>ä8'¸¾~ÆauQµÊØíéI˜´šp3>àã¡âù_hi_=ÊâIÆ‘‘İ!(IÍÎŒh„,½ãŞûåó(=Ã»>>øÆ¹é\ó†š†á]½š"É!Á¼áA?±ÿßgëöµÓ¨Â6vÄ÷ƒ`hYçÆÖ…Q:v»úå1˜-Öı`|ºxH¢¿’fæh ÈÁ¦*c5Šˆ«>SFâ•Ü“Ÿl° øÎ4g8€óL‡=HSµA™ºgÃ¦ÚéAùo)‘Óš,ÊşSµ‡û“j9~¸¬R‘¹a3ØænõbYñj·Ê¦š q”ÆÌè¶˜ÍÓB¼ğ¯…˜%HJß¶M8	.4f1zü·½ÖŒGëé¼ Ì¹2Õo¶ "Ş§Ò	±œAøÛ:t¯}*ßÜ˜×±A»k²|t }Ë Á…dÈğ«T`Y}uÇJô»¹:V,eB‰×‘Ô<5V«M9x¶”´gv@{í17ú^©6—dèÓûæáÔ^7ÍsVç-È.DÒĞ*·Å¾›:¯EtşóâÊxO¸hı§c&@Sh:16D¯ª$qÿÔïÄ
¦œÚ±Ú~kiÅĞæ	)ü.üêd”Pã¹tåR<)hCÄvâ…ãï¶Ú–Î[›—ø„Â½¾€Kv6ê»ó8îÏ‹…#‰EQÚq±¼ °+è4Ná6ÖÒÔñR3ûŸŞhÅÕ]¼8è§á&§¤ıFŠŒRÃ6¨3;É¡¬b¿ô*â#ÁFv³Ã¶©'bøQ;†ƒı\{x jØü¶*U­v¹)fÁ—†!‘¥¸ªXc±ËqË)…òZ/˜a÷•»¤È|ázTíx\dáäã9ŸÈÿÍäá«áühJV3$ª›£ævÜ¯GiïvD,W_h¹Šø•ÊÂI†rIê…YÈrÌQ«^ÍªPHŞ›¥’Ø’‘`Àou/S…³Eİ¸9&{uzÃØê­ bGÖ›î&²¿ğ '@b£ú‚B!ª©ÈüîSÍ•r Y³ | ¥º©Ï¨ãÄ)üì«„+ä·¬`ïŸÛC@½ÿjX4*Àf«¤]{€Å‹w±öP]ÙgTˆ&{[ßÏ ¥;9h…à–ÑcÛ‡[h
¸ôsğ²,Ğg,T.¡òwïÜ¤æ
f’êtø¯Ğ°^ÅêÑ®e\ŸäÆÑSUßRûtpp·»ÿk« U€Ş¤I½]†´ˆÍx#®-òf¦”ÂN³ä[aN'…8ïs”axHù…”gƒn6÷Å'õ.øn‡üÁ'Æ’jpÏŠ….‡´Ácçûh)c•fN2”'áXQZxëR-NA¿éQg÷_ıãUÖrïD–í4Àa÷+–Ê4mIszÚ£Áœã™‡%ÁaÄ¬FFG¤‘şÎ·a÷ÓäoÄ4 y:r‘—ÀÏK.µ×d±³.ÍJÃ@	ƒÈ‰ìÌ›Gº£¶"…í!ä¬Í±M™gXşÄy@¬Ç:¨¿O]&²­Àâ®šA0ñÑ³Û&@ÊOòù^D
.nºVÂİ;³­‰L,İÚèšáÊx«¦ÉÇ¼¼ ùS…B~º;¨ˆ\æœMö²^.ºBå²cP$¹ê{š =¤3¤©Ó³Èú³¨3<Ån~À	c=â¢È¡Í„şšİãàºƒ(B%	vü«¨Åôôï¬ÈhÇ#ŞÎ.Â	*n™:²$—¿F[ù¯—ãˆÂ¢5Ó…ûqBÏHŸî>7rDOg´LIA°«ÕB@ÀVv—,ÊÜÄê–ıKm/“X˜•c npá˜.ğøK?›ÃC“Qê¶%=!9CVšÃ>ÿD«›¸XB€Y É ÿ|¾‡ßìş³GTŸÕ„a{ô.u{’ê{ñ7a:Eá šøS*¨œG,z‡(;³şä÷«²ó'ƒ¬C-XvŞ¯Ï&Vûà•ÃhÚFp<98KÙ±šyhÿÈâ½ÖõÏ<TŸiÿĞ.ºƒª“ÅjdO_ó.©ü®û‚?«>-ááhfÀŸ)&Œw¶´ûCõ°Ï®«­wj—EÍ,µÓä”I½tÓ^’pë…‘ˆ¼NúO%˜â–‹c7]!­Nãàùı¥×Åñå°ÙÍí@¬O`æT%˜-¿îŸ+•iÄyXßI„câFÒoÿb:kÅ—¡6€ª¶jAe—KÓö^÷]ùû{Ä±Ñ*1‰-Ê.dâ'ÍCê	šp5ã¹yC]™Âî"ÖÃ§_Yç¨ÀÕñp†(ëÓ)8k‚8áXtQ¤²GkÔßÃd` ÅñËåsŒm¦ÉIƒŒ3ÌÇäYŒ×½&0cğe~ÂıÊç8HuŠŠP:\“^s˜á!³TY,;Kœ½ÂDğÅ!_ç°ü&Ğ½ÓsÄÉ¹‚\ªÖUöİg.l.½Cgv¾=-•ï²æÒeç€oyp`Ü9)B»ØĞƒ·•j^¢îY_É±H ²Áì¾låöEÔ¯ûÜ°£ÑØmç`Øèo÷º‰ıÍ¡9¸`W¢æå[ È
€ù9\æÁê[!•l9H²Ü†ç«ƒ¸…8>*_ùöÇ¯6C…9 _ÂŞò¢oÒ)‘9„ú1G‹U¸Nş?î%Ä¾‘© Œãà®ÿusg ¦ç¹ííñgí_E§1¶ip¯B6ÕF2•Î1ŠÓö¹Ûn÷l‰u»±PÜJyRÎŸ ;î{s8-‚r¹}ò;¥¸qÅ­>¤©hÇ’hM)óôZËNmÊ£ù#Ö…Í¼ ;²½cAKõ¨ÁÉ(otCa	5Ãººx3MdÖğµc8~°äÒoÛHœ}µÌÙfÃ§x&–yº«ÁGË€ÿx ÎPŞÖİŸNƒú€kÎü;Úk¬+ß,UUèİƒ½n›$‡ÙØs~Ä8¤ğ³ÔGø?èè¹Jj…í†!+îU€ÀŸPŠ¬_æœ«Ò<mŠU¯-.¯Q‡oÖ\†(Ëø87ùÏª%³bhsı>(oÒ#Òá*AÕÃI†í—_Q¿~º @Ğ>óİml«xé™×mw›Yµ™©#§#fËY—Ëë¨MVMóXÒoğ{]¹.3
‚Œ fŒ,rÑhìÄÛšC
ÙnMv („ÕQ™²ºó®P°ì"Ê+Éßã˜ó†ë;$Ë­†ä0)`ûâA_Í›¨í"e53¦©šlOy·âÌª`Á^º¢ªÕkYÈäÆQÚ·}t¾åí¸ü/‘èŞ?±•8õ“¼ÛtĞ. ì†ŸMTäù™i5ÊÙLÊfLÉQYâ­•@ê##ab?Ea¹EbGãû¼¢ĞÔ}¤ß1¸?U„×.,{W‹8t²… àiØ°·‘G8&œKl‰íüÿô¨QPÈ:tóİÏjLLkP}¼eÉË.f}dïG½'#½ûFËâ§^´²ÆI~`úCWT»à]Fç¤rg^‚À£İà#Qk<fÜ±ú×¸et'5ZğÁDX?WÉ“I+JYú!‰Ï€t„Œº-3[—lcmÃ7v‘º3:ò£Ë†è#:¯¶=şşÅË3€TŠŞ™¥*ä¿uĞè íÀŸÓÄÊì‡+ˆÂ)±şI´ñoİŠ´M4™;Ñé™°h(½ğ,Íé@NEÓ3º>áz
¶ñöêşnV½É"Šœ&íHôzµá¨áºV\Îğ T¬šÜïaÇ&‹^R<<cü[áëFB,ú›­/ŸÊÇ«ú’è!A +]"…üªæôIWéòÆ­´fÍ7èêuô»Yy7¯qâ·’Šië´Á +8öÜ €RM¾rßZÓ&D°hfûø¢0;D<`r'Ø¹î6U‚Tr\Â}Ü©óäkõòå;·æ"êkU>‹(Œõ®§<>À\qÏ§b‚#RM§I%±X[Ãí`™¸$Ãp‰à#5·¬Ï¸´Ö,9|•Òì ÁñÃã#\:©"8Œ€ƒ ÈÄS/ª`ñÖ'Ó%•üaz‚‚kÆmÅ!Q¬İU«Ø´Ì#¶şÅxPÊÄn¼'6bèIyJ-¹6f…f)&¸o"CĞaAx)æ\ÎD¹
©÷İ7ú=ßÇÛ–ùî‘èI¼/ÁÔ«ŞÂ7æ²óuõv´Mflæ¥?–a. B•Î4Ú*±°„jö&ş³wèà¿É³q‘[Òs•›–r©=‡ò’cÏÏîhŒ5^Çª2;¨8åñ.F›FBÙ·wÙ$Ÿİ›=¨Ëûfnş`O«Z¸ÆHé›PÇ¥Ó
nî2WŠâ²wG´Ö*öºİ‘+6\YÆøg”Ì¦ÉÀ‚¿ùÄM5˜œŒ3¼ËYêÔ#ğ%pßÖø7¿“é’áJWeèº©åƒâõ ¹ınğ¼Rï¯
 Oè),ÏÕ—¯r¥M8º¨jfóÃ}óC„Â|õ‘ó·ŠìšÀÕŒû ŞìHa±ğ+(qÌi ·â“ğM„	ğ’}úrÿ¨?Ñ›ä7Îş—š )Ë >²4|Îúíæ&8¢s{¹* 3ˆR^»Şw½
®Ş±úÑo\—ó}«…Ø$©õ¿œ2„„ş!H÷ò4¿Å×›u$Ğo€Ÿ¨èì†krV#À³×˜ª×œ¤E˜İş8f£Z¾àıl=[â2éˆßëj#ÕzÂÜı¿MµÌècéEÚ*q0>]±juÜÔXĞö²Ãé;$DÕt~PC+dNUŸT§#ß»ÂOåƒÏ†UßçgQ7MŸ~Oz–oØjG7×*Fj;¢ÅÄĞN5sÍ±‘’eÌQ,föl«1»*Åädt¡6ùxD/M×çJömp•1¼»JÊ‚äÌûõÍ‚—ã“xÏÔÚY     ÍŒLL%¼ Éº€ÀµÒ£±Ägû    YZ