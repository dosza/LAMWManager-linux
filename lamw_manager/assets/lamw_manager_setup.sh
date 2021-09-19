#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1889352688"
MD5="bc161dc1371ee608c97e8b768022a964"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23824"
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
	echo Date of packaging: Sun Sep 19 01:06:52 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ\Í] ¼}•À1Dd]‡Á›PætİDõüÚ:‰y"üL|ìÉíâ‡›êpï×–8
Ås¦Oày‹çF/ŞíÍúÑĞî[ÛâH4	rOØ®Şî«(^X¡ö¡!~zR.àGÄ…Ÿq;Í€í…pŞ}õ\šš|¯/ş3Çè;‹çÖ“¯w€uzqÇ*¦”5‹“f±øt)Œoÿ§C½Šf½ÛÒBäš@M«SÔ›Ò+‘!”e;@ƒ1MÀÎëıj^Õ¿[¯àE4‰ÚAÏ`¢,P12ptdÀ½|ëT)ò¡^Æ¯Ò‡íniˆøš«˜£Cn>¤vŒê¤–12q²Á!L½@|Œîéº=+C¯Z=šà#5cvÿıÖÒºbT÷x»v9àŒ±ª£ŸÕßŒG(HYˆ-Qrb&Ò„ò·Úª,Ü¥¶ö–cºÅ€4°¡î¡#êF	Á ²üpÔ%€ î¢–s›f•àÎZÌ+ñ]·½³{Ğò_X¯cO"“T‹b»Ö.¾R–Éfz¸K¥wa—×œ_[“÷±1AO”î]#¼ìóNdy¿í Ñ˜wKü{ˆ×á3ËvÎmöş+)¸ı£®‘ü®µœzL°ÊÿÑ.î‡">N*ÿxag#ØÇĞRh-«c¥&SˆøF2ı4Tt®KÁeVËi©ÙaébQè$H¥¼-ã†‘ô4Ò=nºÇ†Øn²ï
QL53v—g`ÏÇáx™˜jb%—l»=>wÇ¨¦!8Œú‘=¿¤cıK!lXi6‚3#²gø¥€Ág[àußV­Öô×¼4«Ã²©Õ7Û^´mÖ”Ø”MtÇ?kxR½sÊMe+
™æš\INHü™ñm:Ÿ*éE(BjQY7ÅÕQiéúµŠ%o£¶j?ì?-{ôz×Î~­4åWY«}YùïŞzì¬¤_V–zÃ†=‰Z`[Ïp'Ûšúëá¨ùx¦ëj4êèJ£‚s€Îññsò>ímfÈ$êïxfÖÿCÚ#’Š.üÃß¥µ2<½¬?øê¸öş‡´«ÄñÑœ¬ÑO×ìÅ+šzSÄûÅÔÃä Æ®İ$jÃî	™Ğ ×v~ı‰x´qÊF•Ùn àĞªÜ+}öOÍ	 fD¿Éâ½²JÇlûÆÓ1X*hºh*=ı”p „†\èÏj³ô:ÃÉ>ãã@NÊëÆå„­#ÕSœc«kwlmİ›£ËŒ'o¥yW~c>×¨«Ú	O)9amvA[VæÎÔŞæeªuÂí>¢|Ûœ 7î2–}€éçIN/]A*¦Ì3h$^ëL‡Y•)äš/ÒÒ 4`
õÇ†JÉ¿‹S¦eb*%!8X1DşS$É–IdÛ,¬µ‹¨Srµ9!Æ7âEÍA{FÉÖ4s¯Ñ@X¾õÉ=úêÎÊ*%Pópš}$€”¼wÄÊídª”Ğ„‘ÇÉÊ÷ˆ˜8Æ]3àúÜfö¤€´k¦ÁP–H‘•nf{*³¦YÿJ¸…í ;o£8kÔû›!Äı•ñŞñögld–Œô«[~àÒî6S[Û
LÎ¼ïï$27&ûËJLSBô	øÄtˆ`"4ÏÑ¸éåVd°b5©*{ü‚F÷ª~	nïÀ\ÅòWl±şpŠ4<Ó¢¡U´·ec§äW¹ÌµC
·#jW)àÁYù¨MLZ2˜?JÇàE—1	¢EXºä‚Öô@İYÄ¼o7¦"vZXL9ŞÍ8"1^4àWâ¢Ü¯ñ ê—S9ğ|LÔovĞ"°'³dó4yÉ&Ò°áUÁeHÎâµÅãtÕÍ˜rËµÌxşxı">šçY+ëøÂH¼æÎ¤?àU,`+‚kqD¯œÀePI*j’½°Û˜…€æÍø«D&Á/b‰Ÿ/£ˆ XmSÄ'Úÿ9ĞTø:Wú’Ö¸”×«*(èÂ3CøLäÕ G‚+âäy€ÛdÊXğØoOC‚RB¨ú[ˆ¹4K²–Bs¨kM¹éŠëÌN>É‹[L{S†ŞÄ¶S¾şÑBk‰€S~º•CT3+´ÜšxĞ ıYñ1Êd‰?+òfåŞ¢~]ÿä½õá«Oİş•YK_oPZ½”náşn‰Í³·c¡¨„OU–ˆ´¤—p¦7ûág»4¨u÷p™P¿ÚP™O›ŒL"&{ÈóVDô“j&ùá÷¡ÛåÙ>£èÈ+‘ †c‰¥”+MÈ¢ãû‹2l\J´ø¥š
aŒz”Ïˆgè&O7ÿ.eõË˜ûz®!€YÒ‚	XÚèNZ£:"­Mİ'"L„#§^ç„èú©àC¹A)Mg$’yçãùKh¾çšüd÷³sã(.Òö“q­Èş!úñÌ1¡w0ŒŠ=“'öÆúİ{÷d˜Œ/¦:qó–>ÈH÷Î÷lõ\Ïaì|Úãí²´Ÿ‘º”ËéÅ-Yu/}ìeÂ$›S}$wú^{²ÿbBÌG.Áqˆ9ï,›Bl£x°]ıNt!Ü6Õ€³èqÿÅ¬¼ÙM—¨%ÊWW†Ü„%f´#^öK) H(Qót¢ÜÒúõ<oPÅFÒ§‹dõ…ÑkY)ıŞ¶xÕªËHŸ–ód9 µ6’ùˆ×Ä¶p;]3³aÃä8H!§xÀŒ_Lu’¿‰<:gZE(âìgy‚ı»]e		†6üÕÖãÔ¿>2ìó8×¢ü°£[j˜‰û¬İ©¡Û—t-xÁ“~]@O¢H2S[^¢àóf2Qm´+e­ìD“u§¦[µAs‹ì&—¿B–=ó£ïp’åtm$‘fŞ "ûe—-“ë“BMÒÓëq×ÙèÌ…Ğ«míL5‹–UÚÕm{-ãw?R™ª@—båe5H"uÿ¼ ã-?ÅFzF?¼û$F)ï4ôªA)Š|ÔfìÂx4ê|ì%ÿÍ»#½´%|ÙÇi§~ªœlò»Â®Q£hÅ¤n|Î¥CGâ÷>‘>!=+øb;r};9
à¡Ü™ì£ê¡‡x…Î3×Õ:½Ù¼îÎNÀ×oqÕ¬¡_Ÿ§º0Íš½íš"OÕÖà© ÷èTš	ºñ×HBK$ÆÄC.º‰8¨¡bçpÓ¸”R9‘üÄ¾ƒª­˜¿Èªnzq#(Û„ÑÙ…é/oÈ®‡É
¶ ‚‘öàY¤Ça^ŞÙÍíaıù©Êl½?ŒA¨¼LmV|
:{ÈîÿnĞ£Ì!Nm°Dş[ê	Úô3KËÛ¹Tè¦øpT­‚è ˜à•@P~ü®\aGtĞ€+¦ÿğÁPİ#EÚ^F³	o]nEÖ%›´âË©õñŞ/~@S‚%U|¤¢†Ë¯L­EÒ‡Æ1:lªz¼ÆnÃø“:w$ß§l³¿ƒY$dÆæ1u¢¨­ÁhO‚‹ı_øº”‹å˜GVÀAPÁ•ÿ›x §‘ƒÈ#MYa S¨£HúĞZ´ß“®
}×#2/5°vrò9z@æZúGbO¿Ÿğ”Be ¡'Z†œãzùj_÷š,¢Àb`/Í‡÷%¸ígvÁÂMMÅ&ç„-Îj—+{T·E?¾Ù†*ºãí»ã{uç<- ÌAƒÿk†Ü~¾¶‚ƒp$êœ(² î@	^´iTf1¨_à9™µü ÷K–Â™ÅöÍ	=]Èp7¯q«D‹‡úŠKHùòµ@
}‡`[£„ÏI6ÛU¡3şİ;¿¤@nçÙ‘œÈ
R%ÖKöüåÜÜ…úÉ*èáqW°›;Ğ‹OWú\,¡Ô„ç1};È÷Îşµ‚fş_1(d3†ıIÌ4òœ¨ê¨¤ûk$^¼ìrŸŸ«Y±¤³ƒR©®„#~9’'éHJ¾3ƒƒã†.qQ(şlR=¯]C}ÿH¥~‡?|vB¯t×ÀÇ¾6YC^+Sª¢ÃS³ÿˆ$k© 0
Ëj¬Ri7›ÃÌ¾€ï‘]kEeş¯¯£‡¼.1ëCì8¤;"ÌhgÿÑ¹›?¯½b‘¸ ï—”cør¶µ+{ñï?8†K”(³’]]ìÍUğUö(›Àë¨÷ÄuÚÌEWWÊ¦eêc×ØÚI=xƒáğnó:]Óïö;0aP¦ölõíŒ…ªÂ#[á";wñ¬^§Ô®Òƒ#:©ƒ® ìê
6‹ªô¬‚÷R@fó™±ğ &Ø’M$“+İ§«WğÅO’—ßf Åå£&­–÷b‹’ß]y¦™œa©·±óŞL*œ[¼ù™Ë:30du4şCŞë-ËpÑ¶º^ÂznØ¸ÅçHJßöŒåIÁÏ@JÂ’š@¹Á½Fÿ1lWçÑ}?&Ò—	ë Mj	;±»¿ÙO ¤²ë¥^C[ôOÏ²)øtº­lä•Ç®ÛÑ¶wÁfŸ©h/[ÓK‘]G˜D’Ù„x\áÁÛb}[ï­—^àÙ
Ds@aL#óé¬ò•ºı’#?íğT‰£×%Øo¤;¶¡3ÁVei>ÁòÁ¬YğÂaÀXhjİÛX›«?—•%õ@P‹Ë{%‡
ôÿêoŞe2péS-Q´'Q	2÷(9y8àê§âımt=š‡uHd>ıq˜ãy@É]ÑgPŒ	8°â§&¹.|DM¯G9êoèé´ˆ¦óŸÚñ™Ş«Lw#}^LJ0g#'ÜHs%Ä2/ÁzwÒ¢ŸÃwCTÎÆYºßuW?Ûê]á-•”¤ëFW$mIç0ÓFÓ^ØÓI ?è ß€@æRÆb±G0{	=ÅĞ}=%kƒÙéó<ÜuÔìM¤Oê*X?zÜÂ¢1i½–Úô µ&Íª<İ©ù#:êô³Éˆ¾[Ñ£è:-ÚöÄL;cIÚO»!S¶p\N^ÁÀøúÏg.{ÉÉÛç$6r‰Ñ3¸ Â'.ÁşªÙÌ©Ø·l:4nç¬¶;ö\>ÄÎıFJ2ÄZc—1È/û’¨ÔğwwGgvˆi	ù²¥Q^–Awbé”sñ_,!=8m´ÒU˜4œf¢b#ß©v›Ûkò¤ÀÁ­	¯tÇ¿rú—ó]qÓ‹­šˆ&¹sd½sûpQÉ’İ0à†›êÒf™T¿æÕ™—†½0öµwĞBÃXÚBÃ2~²XnªœlcY¸{$_YIc½ä”¿6ô¢GK-IÿùçÕƒLŒÃjÚ‹&£ôaC¿ñ²Q&&µ+2‘ıD\aaïê¡ÏE†D®ùY2ßèÕ¼ù”Ä¶%¤Şbèçóë%T.«w
rµ²GÏ]şGÍ&7Cò·WP¼…ÇÉàR€b×ç£Û2„F
û§&~;Ëk}=úlFŠäéªNón!5J¶[ !ØDá•¬ÉõÛ)6­øÜˆÜÒZ§ÈÈZ	ıÆ©#S¸’Ë?w‰aùÉ*ß'sÒÁDÕ¹tı¡·¥0“9L×F»PAUmE_·áğ ä…?:ååyps‘`ªË¾FG3f<×ëöÕyU5òúèö.VÆX‘ÒŠ–kDDZÊ,N]®h*bF¤gŠ²hYÄxbãÂäjé¨ËD|‡ÀÑà´>ğ–øX',Ïò©øEpe'U*Fmí>‘|(+¡¡i°z4´ıÆ¡ğ<Ç¶Ê¢]i{ÏJ®í&‚óºØjc¦L›g>ü@Ï*½}“Œ	"TªXIİ’ÚªÙ{vÂ[ï*9+j¯¹¾àß¼Ş¦€v£µÔéœŠˆP!ÿ+f¤ƒC®x/‰šëcéwz[}^åyÀ?(4A´ò¸€âÅ¡‘Sá%Qï†óÛm}1ÅÊ\~ÉLùqo¬µÁâIú>Òœ›|ÉÔt”§Ì’œb9v*÷o¶h¸-ÊH/Ì„=AìˆÑK!üB)1é‡Išş>is?*‹¡¼¿àcÍØTFÛ„1
IaF“¢ÿWÖ™WçÓæ3éb‹Êôò‰&5ìbƒ†#?¶½X—¬”ÁlZ§±ö˜{µÂ@²›aë÷î5
º? [/µŞcøÛmğ(ø›d44tBşÁßŠD'|’Ù4…&„Š˜rˆìªŞÉ/D­"z­m"²°]%î÷^ôG! 6¸ÀQ6¬êZ;'Û¶9¾-öu ¡š‚@3ûª¢çuƒ;õÌc¬ó2¹xAîîŞÀ+]é„uoA Ğ_ŠxÏÊ²:©¯â³EğlZ6Kz;ƒíoëî: €ÿº?¯A¬º·í{±Á³L"Şç†QŸ§Ñ¶©/JßA’îèÆlWq =íÅm5
(UùÀ`£³F‰“b[Ù¦øòŠŞšGıî.uˆùŸÀ°ñ›êù57‚Zå6µ„’£ŠQÆ„¥÷uÊä‘7²iÏKàER÷Dlh¶e7–Ë¥.d_7·ÉÎù‰`Üv?åõ&}P#UâúvFÕšêm*¦Ïä)¿op
É˜feá8¡·êÑşBÊœ_ß±-–0è“G?A!Ÿò²'K,¥m†mˆ‹îğJ…4£jœœfa(qˆE±½¥çÃÜ[tÜÆw9 âµ–ö°<-ãù[Ï˜UJ-!ÇY_«U.÷ô/×ún…•aÌÍ“bŒB²_BÄª2ªz÷ı˜|hC²†`l•wÛvç×€¨x,‡Èş‚ÌoÁ<öqİgà]ÊJ¬ƒå`«ÃJÖ+©obÍËÑ× û$\iÒ–ƒœZ[ƒ â™Zk©vã†§ƒŞlÿ4è3g>$>nfØåŸÔgôœ÷ÑJ&CAn«Õ„K´”xHIRQá|q©•(ˆ0ñê-ƒÒddunÓrdX°)¬Ú™¨„Ö\İÙ”—w¨ğè’ÉÚû†èOÿ¥òÖ[ã{Á*ºõÎŞ¥¼Eoµ%XÃÇ2UÛG«jzşo>=:¹4u•æˆ¨A’[I}Î×<P„L²¨gc§X1ØªM¥¡<î6Hùšùç+{Ë_¹néA³B­Gy·ĞäA’!Bå‘&¾êùe¤Dù3ÂY®ÈE€2uVw R‘èfgdŞ!k‡+ğı±‘‹›o2™1TéRR9Û@ÏÀj2•§óSµá¡’ë=õåå¬ wº4[0Ñòô;kéa-ŒŞşŒZ™Ó`ç/“Áo%)û f ìkRËƒvÈŠ2»¿±º‘I²À2Ùúj&V7º)„qqÇ.i97HÅĞa&!m´:‰#6-míC×sÿos
P$Éum˜®J’?Æ¢¦s]ÃÑ£‡ZÕxaëW˜/öqíg%^æ˜…C?<Ôµìp·ÎçÙÉ\Hævˆò°N~ëM~³ê˜eõİŸ^ıÛ?‡²c‚A¨
y–ha3^
lU¬A¢­‰Y›­Š6÷X§ÔF|f£	ßıZ2×Şagáolš¦¬&ygŠXëx#òWA†Y„¿X¡Â&7FfòüD(Ä†ãj^ˆ¥/Å…ç%2¿øÚÍã¼n+/l 
É†oÁÌxïäª.2k˜ü²¦§ê%ô·Í4òÎ¤óJöLsÈ©<eOF||½ãU›®Åñï©ğRrçLPbñI¦+ë¦	T€æĞ«ƒØmƒ%Ç…±+qÉ§|IXw´LZÁ`Øû@Y¼NE':œd–,bPİ¼_V€ÿMUEdé‡ŠJ €İÒfî,ŸÇ0\(ŸğX¡¾¡isó'Cjâc1S›s¹ÈÍ­ÁÛ¤ó3i-.åHS¬Wä›•	º )2d‡,éİAyXUÁŒ©
4Ú'çÅIßğíM2IÓßNÏ¸=öZ†d²'Ñ‚<-¼V¯+¥‘ğ5>!
Uÿ@™ªÓVX‡ë@ŸyaÅÈ²£ˆ'4…¡N_ŠßÜÇ†#†0†‡UPaRl“;×ê‡?§rõıQ[ãgÂ@{²‡Ø°.ßbÈ==•áÏVT¬Ûg¼3X"ñ2ò(Dsº_DU„×³š«ç¬z…CŒ+“ß~”ñÂ	ÓœÂršPñf“~ÄÃƒvÑ‹.wÉÿêıÀ,xMDÜÇ¬£ çI­Jmí2LŞ·ÛneêÂ›†‹Šn?ş#QsÀ±ct˜m!¼e)\à·®øt²Œ%C&%QÑKNFÙÒ³zŒõDbàUá€pâz Óz®b ú‚³?ø½¿¡­àzıŞtàø‰ÄğG˜Œ™om´¥4‘yÄX ¯òZgB“ı”ÊßşÖär×ÍJŒ‡S2Dh—¯68tYZvB£‹t_}ÿê{7şÍ´[9^…•·î,`¬9ˆ@kBQ¾x¾1`¯Y'76e”|µPp@84ñÙ2CAå<,'v?Œ
À´&*¡`LeŸ•¯xÎ‡?IÁœ’†½OEz6X¸Ò˜„ŸéNuKTZÛuöt`%©~‹gú€kÿ9	fÒO¼ö—ìÃÆ.·Á,§•YKl@ğj|íšÈÃ¨.¾2¼®­Ï^¤`C“ZWõ'x40õì(* ÎşQ¸ÁìNFå¸„âÊ÷ìW*¨Ş²f[ºr4[‰~¾‹ÏÁÉ<E^&t$ë""Ü°)#è:$Ìjõÿ@‹	È¾À?VE½ÁO¯Ã,1S¡rÜ.»*Î£ß_0ı¥1—ş• ş›ø$V39rñš™€ğŒ}KËƒ64|Ö²BôëGã~”iÓnZ&é0hé‰ã…tK™­zÈê©ë›5ïV)ÕÔ«Ñ£˜/şL<İøÔÓeŒzw`?bÇM¾ZêÔŞüN3Õ™Ì†ãóƒDíëÄZqVr>â!ŒõË´-4¡hĞë8ÀçL‹BLçË]ó¬ìÏ1Ê·ÃÔ¹‰M`Ü<:Àv ñŒûåÇ©mrÍMF&TrO-	Å"¬ÁQZÍ«§¬¶yÖàU·;%‹1=­Ş1ìbèÏ~°æÜy£­¬¤˜Şqhíæ÷Õkîõ=bj{û\â;@•çvŸü&…íšl‹ö;$¡ÔøÁA¦\åÕªª496o¦Şp¥ï‘ßé|^q¦“æ(sAÀGKˆ³2e^%ÏYRhh¦¢­°l"tµà²µ·Õ¯14sü°a«˜çEş|ÊÃ¿|ËÎáW|°T»¼qaÄ}pu”DQ<ëÅüMêÒ—™‹pÑŒoŞ"ˆ£±³‘ÃÄ»ø5©dR>›Z¥víö$õÌ,•_ßbo«nÑ^Tã™“Û²ì~fU0•¸ÚÀ}zŞYÆ©`CB‘š•±a¿šÔNÅt[z·ŒşÆ$£)AQ	GiÈ›¯˜<W0Jèy"ï Iõø€-Ú#xœ—ü…1z‘±]ÈTF°\JwÅ_İ½tÑƒæŞ7ƒÊàï­T8è”Ú¯éí»‡WÎui(…>}²Gªå½«'*§æ¿—F|ÔåşqğN‰ ÈÖéòwÌÿY®¯‡Ë¥c<—C¾#}QÙírb&•Îï+íEE´kI3Øªe
ÀÍ5Íõz“JĞ}zƒ{ã€,Ùµâê¡;İ÷Gx%!¤ã=+fÁlß3Ü€d9—ÿ,86Ş‘—¼aõG"Ø v«âÊu=yW<WcbÌ‰£­yÊoP‰Ö¡]…ÑW}A¬™ /³ó6~¡ ¤ª-©hJl÷Uv‡…ß‘¬}+SáîŸô6#½kÄ3‘QrÔçätˆ0ãÖşëäp¤ÖŒ;ÜR¨ÍÁp‰ÊÑ–¸|äA_SlCª»¯r‚Nm•%ËöUØ%‡MÒ×9Ù#sÑ
şºÁ5Ó¢d‰ÛÎAï$5±ói™Z½¼"znÌÍú\j·wÁVN™ÍI]˜^<ÒßîÙG£ì®/ {‹ÚFüs“X¢^à§kŸXğ¡˜¾ÅP5MHu”€'±"4£
ñ`’â¦êLWá9®O¥T°G‹±òU¯¨Ît‡ì¢İØÒ“8ä!P„“éöœÂ®0©›''l ÂjmŸõ¤{Tp6–†=äN˜Ş×GÌ›×jrUÛÆÙ6ÙñÚ·¡ñè¡“Ş¯RwŠJÖCfê˜‰²p‡ñªø%È•î$¢j"ä†?íÜóë&qÚD˜éíºsq àbÑxŸÖÅúøqP=»šU81Â$ã†Í1#zË£Å³§/D¬ÓétVö?)1ç¸ğÃŞqÅk:…^'b–âôˆ+™g^íb_ûwW}k9Šêmi^æyíQÇ­õ›Ó–mÅù@»Ü£tüOœf Oe‡¾X‚™I¶·4sTô!AŞNµ_·cFCPnÕ4ú~£n¦[8ğ®U«ï¼¸këÙòáIó¢o»İ„ÃZŒ“¤FMŞlŒäÿäqi@–Iˆúğú7ÕÓ@Cöv›/ ÇuPh—¹q6”çÙÈI°.<¹Mşòß™]kÈJF´‹îyb£ûu  ¿j¿óq¡ÙòêÆ¹†Ø+»2Ä±ßÿ—lƒ\c\`MLø.¬r`3È(ÌïoNF\O@6|ßjt½+Ú>¾D\5-E¶íÊŠ‰¢‘ëøEÓKä'_£+˜¾P9+_£ P·½P~ñ	­äãp-œÅEÇÓ! :¯WpN—	W‘ÜªA2Œè©–«,@Ä-½Çu¥³ºzÜìÂw£ [S ´T•>ö‘øİo6½ğ‡`×2«ñv…@ZjØ”ğ”¸”¨”Òé,ö¦ÒíI–Š­3ÿÁq®ğLõ0=4;BÜP9ÊÇv$ïú–zõ8åxclé9©fNF”í…ÖÕdÃrxôK§A"Æ Ûø©±j@.¦{ûó¶	ú`Ü,8<[ß˜K	sê³»ì—U™ĞßAQ"à¢©¢íÆĞÛ,á…)‘ó_-£ÚâåE:öÈMº9¢¯€g	FX°›ˆ6¨é”u°–±||G+{Aóq¹áZ#K‚+”;èÅíÂq-Õ ¬„İ°ó„úì9Şa­HÕ+o#°2ÍÈ	Wm¹âõbç¶íÑ¢¬†ıÄº$ô=Õ;*ıh…*Ø™ÈëN$~ŸˆÖSHBuõ“º,HÚòK'‚ïì´—¶êƒ
OW‘Ğ2 ÛyİâhdhgFgÔjÍ&/ş~S]ä$üuqíğ£Ï`¹ƒ¥Å$‰ d»ÆCFéÇ+õw4tü[™;œÉ'ü‹íí§Ï]ˆLÃ,ß9€ùöcÕğú"úà™1¡ºT,¿í6vyYšt!k¥l‘½ªèCùñvJítÉDfy6ÜYkõeO°uò¶n½½7Ì<d.Ğùw3{¢.@¦zf÷tglƒ“åÍÜ£ÀÀ;Ç5î®~‘ØlŞÏ ÿ±ƒ~›Dg&?2û_çe‰æ!b[6xİ*¸–ÄºÒ*Unö¶±qT;Ê6Ì¼,DßÚFX¤¶óü¯GÅÜp³ŞKùÈò–úÚKWàĞƒ¯ XSv£|¹Êá6Õ—üR\Lº œO.L?sÎE03eÖ‚\G¸ñzf™ÉJí¨Ñ©§íßÍËÇ4ÛÚûÇ¨ì€ÃDìß'Ñ‚›[UÙuß$HÉS,!Z0_dÔxÔ›¹6I5ßèk€'bK7Ëí°X–mSÄ_öë kÅÌ°‘÷ë•'¯æAA‚‰{%â¶ğ	,Âá.e‘ÙJ±_Oı ±rqà²ózM…=¨‘ó›`1†c¡!‹zİ6G²*u/®•rÿÅò¸Œª2mQº›ã ş`Ø³üzc`•v»ÕÂAJ™åDXÊ€Ef ÄC)u	q ª<é˜(™`S$Ø£—ñÛv\THìSì¹i-™^¸ )Ïškdø2^ÓïÎ;!
l­íîş¾‰?ªÙÆÉ Dßf9:=¨»&DÉ¯iÍwÙ5ÕÙ…©G0ĞÇ4áµ›ËµàŸ[XÅrdn1¬5“[‡¶…“HDÓÓ !Êå)ıÉ¬:é"s}ÏÂ öûËşO) ­Âw ú‹øèRDÀÚvéÁÁ‘_İ{€ßÏ4¾qFşvËf^×v7­ôÙ¹¤ùCÃôzÈŞë`!~ÆüŞV>ø#bÈÑ@4	 ªÒHg ™‚7q¯xJ3»­ˆ\A,kß¬¼…V›ß İ ;â9»*çmüCÜÁéóïEVZ} \Ü{Ğø³¡dp¿õ . ?•¡FJWìJ˜Í°.(?D•f;=Ê˜x¾pr÷šš¦¡Á˜G%ğ3ò¢*6‡)æï¢C9¬ÅÈ­YJ chOìcgåK²C‘%Û Yg ¹ìúÁ€g‰˜¼QvGöÎ¤AEBi‰´<aÈ·~ãÔFS¶í úšb'QÛ¦—#íL¶Åûÿ	>çĞœÜbÇğ5~×qÍZœêèPãq×¢Ş=ö°Â.„˜
ˆ3Ëæº’ŠúVùæ¹V:nkh«¦Ä*£H¬6¢D»Î-÷ŞöcÈÊàO_:54Ù5lÏ"„œ––ï^Õ·ö.D¤ù"H›­ `‡W’À5göSN;ƒ}Éº“¸ºl	ÅñzQŒ¨ìË@¨Ü˜¬vÖQƒ>
æ°f`4$¼qé-¿97· œ37/,ş‡J¯,p*fËjÏPS¶ì2ÌI¨­İ”¢ ;Ghoî¹ˆúŸa3È9.P$âNYdéŒ	 Ğ Ìõô¬AUV¾Õˆ¬ÄoÎÙoEÈÂk .!eØã¾¦D9eS:é)"1Û<h­ˆ——ËŠÅÜıPÀ•d½@Ğ`B|ÜÒèƒG~z¡P›{Bíƒ@n˜)F…º%Prz™Û¾»sß|T­0Ì åS¸Í¥ş¼ D`omƒ¼óí¬ŞÍ—hëĞ¸NHO÷5†‹ùaå1šÇõõwø‰‰åì¢1Nİ+êê¬Â'åöÆù¸ËÙa/ffGà‰cây%6ÓU·r‡ª7Û·z¹u7;¬Dv!D,q³­¾ÖsM>xŒ¹B^3h„ğÅäÌ×N é`ËÈtÌÿÉT¥_‘+Õ§”[wÕÙ’^Ü¤™@âì3P<ë-ZàÈ¡	iIa"H•Xí—"¨ÕÚ)³x[×2oB²D ã¸<®":{'@x<úñ6İ(ôİvØ´­‚ÀYm„ì,o»:„ÉDLÒQíu—q×zC†º»]–÷åÙ$NqVÎş¿¤Á±!%ÙJG“~úéQgZµ¿Åqtƒ.
MÊ~^ñÓĞÃ&ªƒk_LŒ¿íœOr•T´™˜Š]f-EÂ6&Ò ‰]Mƒ³` ~è„u¹C§ú+ô¯"Â|K†êô×ùèMÉ4~XL/ûÃ¾FàßX^¨£z,l¶˜#ßyl¹®&ÛÖ>B\hµù&ÉÇÍ¬·¦ùcñÀ Ç[g?’fV×W­öPù3)4NzÄ,ídcµH¶¼W‚48G†à<(s×‰6Õn‰™Ş] %Èâ–öå(Ÿ=h-æ;ÀòY¿'¨3ÕYû>‡eH¬ü+ğ{…T¾ERŒ/;
åAĞëêçæOQ”ŸÜ¯Åàæì|†7€D—ø)hÆêár(¹fÌ`r!` 1¸JÜEi’*¥™3ÁÙD€Ï´n3&Î]AdW'»Ö*xA*²E¢`(ÿ>€à·®sÏhÚOœsÇ°ñô~bè×”®‰L.)=Céù‘.3A´°»Ş„KãÎ±¢NhïŸæ˜©Ç„¨ş¡5á¨·¬äDƒ _‚ÿOVN>Á?×;Üñ¸p={ı<õÓ_±D¸~±) càÆ»N/óS€ßS†‘Ño•MÔ‚ÍVpş$ ¾¾œ!IS`D2Mıa ›qIƒÊ{/aÿÇ”œÒ5QÇàèÉ–“fí«L^· “­>äúÂÍŒFBÌ‰n…­ñÙ÷´Œd÷ÀÑÿİDŸØÕ­ã˜ãEæP2Ù™C.,í–æÓ¿¼YH ÄŒy·¤š,XtöÀë\¾âÿ0fÈ••š±âĞº¬eGúQ6åÅ/ú7W~}ü~€gÑ0ò¼øÍß"úèĞ//lzíî÷I´º¶íXâÂÍ"ßö²ÖÓˆPğg©¯D½ê´k­›ÍÑ"•¤E®ûyş ºì>Î+{…ÃQËe\è#’%ûAüM=ªi|¡[ĞÙºÜê(µ²¥xó3"ÏÕoïš
I36çağcm1’/iêİƒğ§åå³,·ø¾2¼éŸ=ójŞš\ıxúĞSÚS	lfiùÎü›A?YÈs÷[È0–¥â?8¸—ö6&jÜø}«C‡OdÀ<UÒ3#¿XlZ#$õ®ôèÄUŠxZ¦WÄÂ¦Dô‹°x	Øo®Õå(LH4Ø¥h&£Yd#ûÚ)I¦¾sÓ§£A„«&ŞŸ•ÃRÓì±Ä€*¯"¬HÖ$Xuû²‹R¤ƒ°—‹Ùç90	{0åÛğOL0Î3ròc…6±Æ>Š”qx[Ò˜¿O q½%Ç‡"İ™ÀyVáÔ€ú‚ÀğSÃµÚŠ’/bwk1cÎœ—Æí…,„xœX_&–%eT·Ë›1‚[¤Å?Ù~}Ê±×½rÕH+£ÌÙ@¨9€G]RıS+¥B­ß	µ&ÚGÅ¹öEfş4ÿ<0„¡’àë±"}qÜ=²vAºÒŒcÙ0
&¨1 ïØ›}bõ¹¾º˜¼øÆ'×W !dØõËKx³¦¢«§ÿs»„¼EÇGáM¦Ã‡!M(ª£šw&®41(‹ cŠUáçH~=ÂeİÄ'˜i{°‘^®ğCİœnEk5£Ğ)iğ	zmİé$3‚O:„ğ…„N!¯Éõs#ĞÃóÈ$ë?Îì_èQaq2bãxH‘@Õ‰’Ô#È®®XÔMN¾“@ÏUÉ¬Hİ•š1RŠ·êÌ­;ô°zAéÛ§˜ÆƒAëºä]U)w.j¢Ln¦°æóQ1üüO`ùÌB­ıC*¦.š¡u{PE?š7ÚF‹$õ/÷şóØ	)oÚ¾dZÂyá@éÜb}Öè+”ŞËöŒĞ‰ìÄq*L°Òû(e$Ÿ#Y7Ü?2y&&.%–ìS3ê*Y´\xæ™;ÎS\©›DSºË:x8 ê7ğèâ¶4GT%ı?|@Õ|@ …Å†ÄTÚh;–ğÌ²n*m¤m÷ j¸£s4d»qıÈS š·À2@óè‘İüw8 PM„B€`ysÊ'Zö,ö"19¸J‚.{²¼t(Æ0Ñ°4wÙ¿?NÁ*XRÜÑvüõ±%Mş¿A<ä¢İ¿sED•±`ÎãNŞjX³KSQ{KFk(îÌõÇF÷Ü¨²¼³Ìã…:è­Ô›<O‹Ó&å”ú°üÈu"şöe^SñWûPOá±G1F÷^ãùˆËç¤±ƒ~B§ä€åV2Mù"\8÷G*’ù4óùÇêFÁòæ£s¸«¥X(af/Åv¡X© `\s4Cp¾£V°Åà0z
|Ş…T“—‹ùNş‹¨HÚI60×+DÏwVŠ‘¯]°(éØ€‹½Ïò‘CQjQ*£æpÜ8#'¬9²Zm®ô®ÅÑÊZ^–g$3ë3_9ê—ïÒ(«4ş'-¯Ø±9ƒ¬ù¡ç¨EQ!÷ZšñÁÅñ‘G;¼R¶3‡YsÎ`K>í™OşÙÕ¥/ÓTB¿“iümt§5XÌOKè™5œ%şÆâÓ^´ş/"äé³ú_/ò¢7Ÿ	¤P¥Î-ßihFQ‚•–0óÌ'gÇØ™ÅŞ~oh\
Xw‰Ô¥ë·„ djiI¥eV©Î'µ_¸xùÙ&Ríò)€Nµlß u–ºÁf^!{øß‰}5
{Q¡Z³AéóÊjĞH9€ÈÉPM´Ê¿äh|Ômf×şEšßºwlóôPåkZh§¬/üºW ˆ‡¡åıà©æl•Îè¨z}_n2<u€0+”jóğOÉg6Á†BÔ&ND/H}5h¬­.‹_ß¢,!Àr*Y5{^ëùì’tìÑı¡ŠÙ½p\çf9ÅõïúuãûP™E©DĞ&ƒ ¸úKNÿOYwİI/×ÙØ\0Tø¾HŞhò¡R›	QUÛ3-qÃádëØ´æeîÆN6WáÔÙg‚_”Ş]F35Ná^UåêqÜËıŒau´d¥OüšÿÜÅ¡á§’}{ªLN8‚ë<
”×ì”NàOd‹s•yûp¾Õ…¯äçÊl”NW…Õ§Ëbcôãh¾¬r —k™\öş(ãTq¿‰moÒª'dİ×”º%Şyj»˜‚C`ß‚CêŠÌZ{Å€hø ›*G÷„„Õfueºæ­dÇÛß(ôÀ1š2ŠYŒ|éŞ8j¦]D²à!rlWíkóïË„£ügNûe5Û˜À»˜iïO¼(¼Ÿçàº£k;Õ…
Ò_Ó¥,d"–]ÖÃ/Ü¼İHp—QUT×Ê§¡5ÊƒG‰À·!DÙÂìjÇùaØîûRKjÂˆî1ÁÌÉƒ{A3ä;Üc”àƒQô©T4q-+¼×µÊ>?¼£x˜* Kñ³u|°¼+‡Rå®¥àË…Î6~£«0Â›¿x©ÜMSßªhâ 'íqÃLÕKŸTç•B²ÃĞ®	$m;qx°s7IF£RIÓ€e(û|ù)Û³QNøcšğ5òùuTŸœY¡¢o¦_óJÃ¢ûHÓ•dŠØ—'Âª–÷Ü{ZáI"Ë,‰É!~°”›ƒwYœ°·€C'$êuµ;"wxœTò²ÛèLp6/ÅB O¼Y0şÂ‰¾N3s‹eÿ>Tƒ 0ÓÖ–î~Ä¤´gW>x3ßßO» ©Ú@ˆØe-ia×3±	"˜R«ğ Í$,Xœìù[Ú†ÂÕ%É…ŠjÎöo-Ò¦R|\¡´Ğ˜È3@WÆpÁí­³ÔØ™¡SĞ…2äÏÕëÎÏwOºÆp¨#OÍú±›Õ®¾pEÆôĞ İŠõ:âŸIV7²JI üN«¶aj4İÍûà]°Ò %]åè:¤A/¹C{_@D_´ÕÚş¯ä<g=£æ¬) ó.÷L¤ªBbE—î½¦Œ ÒI*^5
9RÕK´&)ãşÆ¯3o0÷P§Ï·ÎÖ¾_ƒ ’û’­òÇ*¡ZK>J~,#oïÂ­jö‘¬¿ïætİ­c#Q›©uç´>ÇkÈ^ÚôgõÙj}¹!­vAk•àòh›Î-øWº46°[a0ˆš¦ö>i@è=“İ[BigW?Ï’˜ŒF!úëfW•5	šd•jôq€ŞõT~BÁ¬€V)ŸÄùBoˆnµPê|pu™©ºÄ»(r×d 5şÒïì¶Ù—fÌ¨°ú¸Î…yĞzÂ@Çµ¢—Øõ¸w€ï´Gyˆµër&v"2Zié¥ŸÖ‰190¬LZ§Ÿdôç`—C'şÁßJ<Vi‚5¥DŠÚªPNb$/¦UÀOèõXCt°şó¬Ş¿0æBÄ`ı5wøRuÄXËté	S™Ìv!¶…ó§€T8f”0FêGÄö E™ô—N•ÌåqB¹­¡â¹oaA¤ÒD¥¬¦I
“±«c÷ƒ`ôéM®è~ê_ùa© ïd [(iï‡¦XÑ{şŸcàı[ğŠmCµ“2Ë+ÚL™4UÛ»	qı¿Ò8ÕQÔ!°“½H+]a#…FÕçı4Ëa3úb›×qÖ¬Û¦ÖÎæ¼“±]ş0.'àÊ”5úl¥È½>½IöŸ~ç=#£wµƒÍãçl.Sœ®sëO’0„
öë*Õ^ùHsi  •q$bWmZi¢—¥Ê6–Ë'IÛ®”ñ˜DH$ëû÷–¦O	µZd9K5øÏ!Náá÷{îª–'W\ó%³jíQZFiS0ŠØqìxÜ <Õ	¬·ŞPÙ*±CØ˜¯vcœCl\ÿÒ1½ 7¢	‡;peåóûŒ!İßaŠKü&QÇméğ¬†z{½“*ÌÓum—®ª1‚¦Ib¼ïB«Gš§(È§É‘OóV= p~ß¬orJ€:”‰ªn")›5ha %xµvşÎxĞ uÓgµÅ#³Eed4–X©L“ê•tûÌ¨@¿ıºLéhŞ_­ab;™Lˆø=æ©îp%ğÉêÎZ…—»ô©İ/œßšmÕ/HÈ³äğğ¥ÀÁØªT‘„Çu”Ğ˜ñ÷€ÔËàĞIh~0£ˆ¹ßì1ÒÌzöƒÖ‰g›óŒçr·X#uiJ?†Ì“ëİŞäM(¬<‘í.÷Ğm3åÚòÖ’?`
ÖÒ“7>) xÿÃÿÁc"ŸÙ/»’L¿øX*—w0®’=-ğåOcfLåªşó€HÆcdæuÜ[/ÙÌôW!¿=³ìğodA)?ËĞá¨'ùU£ZÇt	@Îøé»Íëı?Ê’*1äŠL÷tÛíÎHjüçàÈ+|TáÑXHšı˜ø!±éºİH)E8æ©ÒçR¯Œz-¬ØH¥í[È¬Hø|U×g»‡ı„õG§ä4+f/ Á$KÑ+4Ûæ+yÂº‡8Ár5@,ö:2hoÃqã¬?WÙ¸4Xü U@ÈSíi´¨Bi+¨W§"xqÁ€\æcë·~Â¯ƒc—ü¶•4á2¦)§1d'fb¨Ú"7,ÌŒ&çõDÄ´éÀY²oARÛ>8À½T|^B~Õ¤W>}ÚH±J¿ò&v9C)k…³ZXmĞyìØ|Â¸@½²Í›‹á•öFLÕÇ‡YïIğJ­Krİu°TJ~ ÒíG¶ôjq±©„<¦~ÃîŸ>•{ñ‰‡J¬|Ø<MÁ°7&4¤D¶W¥ß4›µ‹Õ\œÚ©Ìl?ÀÅ©å›6y$“x¬£ÕA¨.-CJ~­Ò´=„*ÂÜÅM5Ë=^èß+ò<Z¬ÏF[ò8—Œ˜!½xNU\í‰F–G¦Z®Ç¼Š²~8µêk™ğ¸-,à¢%¶Ã3àŞ˜ĞH<Èğ†GØo$H#€¸u¶¶riéBn‡`Ü@»·£ Zçe6ûˆç<ÂãÎå‚J¨é± Ò#h$:Áøq]<%Hl¨q•¬ËRKóiõµ+@éâxr½JÿA.’s®ß×0öN«<ûÕĞÿ”¸y[Ô`Úicşc¿¿¤:÷ÍrÈ×ë;ÍçÓzğxÍË‰Í±9mê<ĞxI`®€IÓ~Ÿö)±œÆĞNaÄÚÌzª\Á–²;4W&’ğÃa\Mëvon!¤hô„.nS@¬×Š´w\²}M7M“ÅĞoQ’Z˜¥„×¿è]^ñúÊšÛ¿Aµï,ÄÒ#ºr˜Ò¸1ÍÜ6‘„ge.¹ºóĞDÉß=|hC,á¸.;éƒÁ)ŒV¶†µ¿šmu²„[Æt·uİ<ªÙÜÅ–®Š…¡æ*—_}Ø¤i&ñ»¶4Bzv\ÙZ±¥ÄØX^ZÕã£se\é:´U¾rh·8¿!‚#^*o»ùÿ‹ÖÂó0r~P€óÜ¥n,‘œËí¥î ªä#ç|ÿ— ÀRÕäñÄt
¢q¾A>øÛ6~†ú®Sü…³Ë
Ş«n“í‡ô1QÈww‹%»6t¥Åøä¬‘é³ØæRÏP;ù[–OÑË\l`ÿ,´P êÆi«EÒ ‘öcXÔüó­–ø»6¥û$m‡%ÊMÄ…)"u^kÈOáriÆÎáVÓ„Hmzw´ AS!â\CÂSÿøÏV„ào®"ÓåAÎSmŒÊeª¢­‰nğR…¶> k06ÿÒâ¶0ÌæÚÜÜ1w ÷Ò c ´yâ½Ïûq¡Ÿah›uô®;P²É%9
™Ö4éïR&uááüU˜xI8›™°<-›vañK6¨é¬è2†§gš¸_ş™–—#õŞ>qTT,„p“7ïM9à.l8­¨î¤	gfê
Bé!U—MtŒ]U¿”¼©û™NUBV±£^BváõÚQ>æd[j€ëğ·a0a±ÁšÏçNebïqú	…ô#±D\XéJyÚ¾ÕıIEò_i%±ÖœåÉM\üÓHÔíO½2jŞÄâºİ²ç‘;zR†²èc¨J˜Q:¦ü‘úØæ”/RY\Èœ»Õ
—=ñbt_sŸı,Š…	‘¤/¸Aa+uª#È›HxhQ>±•ØóIİ”ú-%¸Œ?tGÔ¿ÙãD:£ğh”W†ßQL“¯.Z­¥ƒÅ™¿B\ÙÌ(|şÕEÂÁö
´òİo¯´lhŒÄ–JğÀ_ry,»A6CŒ*ûdÍ”q<Íî;:Ùß[ˆÃè’R>"|ˆUj3Íñ/£…tº"$ıáÄ¶U›×s×ªT™a+È@óîÁxí›ÊŸŠ uW0Cá ?İû°¹pìÅè#ÈH Ú.Æå~Qı/[™=WPT¿Š»4J=9SÙª«R q&-åÂÍß½¨µˆ‡BÏ:ñØíSxn‚ŠœÕ±ú©œØ*ˆ›ÇÔ±º×²õ¾¡UÒVØ<ÍûãàLNÌ
/§'f'OĞa6dmZm8ßÁ‰B=ò÷]€y2Ùşi6dJjçê²ĞzdTÇFTé[ä³ÃåÍEóm8»É¥0Éˆ §Ú=°2=¶IMÉ©‰ªCZÚL–¾N$¹ìv¶ïf1féVq?·‹²Šuş®IJƒÊ 2py#Êÿù Ñ¿3Ğ¹4JØhÈH–iíÆæTÕÖŞšÏ`÷R¯øQ*^ş¢ÿd& æ‘ hä÷7M¼¹Cœïùàëo>4cÏ(¤^1Øä<€œ*X7W€I°`ÉMÒÚğj9xê€“´2m¿BÑzã–œ–¬Ç•À!$yÛÖNïFë½· Uˆ&4W³*æî„Ò®÷&PôhFkB²?¾}o<rô/«hQœ$à‡ÈhOÀˆ…\±Â4İ§ŠTaÂ™œ¸5óªÁ„9Üîıİó ²™…6¯™ï]²é„tå&íÌ0G"™1
a¾Ëí6õv‘ÈÅO”N™uÊ†¼‘X±;9\ƒCıœ5+› Ø\*»×gşz˜À]»¡·ımÜ¢úq±œiÕ àÿÅ3ä`L!~[¯WR%õG3mYçø“+~23IhS"gI-Ï* ª°/H©{gØ/şN%jİnÛâºª«ˆìqÍ»[ÿ+E¡>F)’ÜÓAğFè%t!ÿ'ãéƒıÒ-‰ÕUe5"é{…=ÕŸéô#ùXw#áˆS|ì3Íu’`‘B¦O)L£/]îğF‹Æª©”cM ÿ)>e¹ôñü<eôkS­ÿšF`vEkÔ$ÁÜ_,ãUs²Â}øW&¡ê¨148[êNÊLñaÁHêŒ“SŒ.´ë0íTd.ûôPs‹zMM¤Ñ¦6‡Š‘:$¹4†@¢î©—[òCç‚Xä@GÎd"!ÍpH3Òİı}"röB[¼Â7.;?SŠ´g“Ş¶Èj
hoÀUYP€Z'MŞ´iL{¾¢ğ…ú¼ßKîõº lI÷ØØ‰Øƒ>ªFŒ»a2õ½ˆËVâu›çÑ5Ğøç‰›ëè5PX÷–¦‚s1*^&€SUŞÀ……amIwE°laC”<5ßœQ?şE¼çıÅM&ôÂo8¢l¿ŒMÎğ©¡”ÀªÍE”›Ø„QÅ'´j¶M'éQvŠòO*oÚjcïÂK™—æ#2ØòlçóDdu–üë8ª§¸}ñ[+ Æï	Sš˜¤¥‰4ÍÎBK%RR\%ÁM°]´•®n4‘ª±£][ —kHn¯´üÊÃa-Féa¥µå´fğìÿhã¾İªSD¥ôI].ÏaÆaœöãœì5ë[„’øiì`I-ês2=#cV;EÄ§úëy…¯Ù›+ğHÎj8£ü“^ddˆ%†#*û§¶ç*ŒUÑr0Æmáı`¢PAç#ÎMp+Çó$ƒd,(Hÿ…×ù¹Bø»««G¤ğœ¼…‘ãK^Ã_6…¦`QmlC†äT%ã®¾¸b…°ØŒğ5¼B¨OéE'¿ìéì“)k<Sú¿şv¬|À½OÂ@¶¡íkÆü°ÒZŞÑ0l"è‰_ÂG@TìO%OŸ”@÷†Ş]œ”gÌkãí	ÂVãçi0aÁ7RND¶+]¬zÏ8.œ~­nT²Ø,“ÉÂª˜30 80Ùù^å°ÚÎÄÖ]×7ÌsÁÛ¿R8MlZGGínn|<…Ö,…À8ÿÙhK-$(¯Ú"jpg².´œƒõØT¶ü·Qö|—/7ìÒ©!ÇKëĞãl»}ü èø3UjÉC&CşP›…ÅqÀNáÅ«sûşíL…ÍIáŒ?Ï¿»yÃ<ıRÀ§S¡çô_79¹Ë©İó3«xîÔ±•
á›4„RØF@ùàå„oòu±0ÔÆ—ZÉÊ5ŠãŒ5s¯MçlÖR†áös6ß??F­n_ú\ófÀ¸aïÇkÖú9¸©0²ĞXûtñäâ})/ùÄ°H*HiJR!TJ‰­ñár&v=cä}>½ZÏDÆb¶Ã}Ô˜sœ…§€<K¼ˆDØGÅÉó±D-¼hÈ`â{áí¤Nš½ÓBÙ§Âí®Ç"{O'5Ú=Xğ/3|+ş^Èc`Ÿ¼œ‰tøyÈf°Ã9)>–ãğLG¨Z×ÌóKËæÓ¿´¸£º¦¥“|‡è7{à›éR®óÆ5Ép
ïMtÚœU!:@YR…?(«åKÏ¢»·ÙØ=œ~;² \RŒ!Yüê÷ ”‡~+ÌÀhI[Z)±^d²A«½[‹?J£8§‘	)Ş-ZÎ°B„ËÂÑ nb…Ã	#š,œ›Œc‘ÉW?lšŞŞÄ~!O·Âbàº[#3xL1áÍB¸İÚ.U°éGŒâÂÖµ8‰.wn.çIÒhœÊk[4VÕ İm¾8•ß‚Ÿ¦+hXpVùŠCucœZªÓMƒf3TG*\ç/îqË®åQÂ#W•Õ±(ğ¦;Îr‹ÁÒ~$‹TõàËóÉ–¬ÇÑl½úï?ÓÑRÙ¨£Ñ½5lÀ]øl°8’©nª&Q?S¶ÓÉ<s­Õğ¶$	íÀZ>;«(Ê†!9­Æ)„;dÒŠtöL¥0“’·D2~æpÌ$&dæhEoááû†šÉÒ?[p–ÀşŠ>ç)x¨¿4–Z£#©àñÌ–%qf¸Õ3{Ÿ
Å$İfJyÂR !‘Òš?9éHZæ±…aCBnP|@üJá6›l$‘<›¨GäËzñ¯.åúZ$œıU†i”Nw`x[ëî>à	ÏMPıu¼ı Ğœ¾cV|
¨*›ÖüÕ#RR˜cH:4¶ó=cRDù =W·w¼ÍC»<)ŠoàT±I‹nÊFĞ
ªƒò¦5`jæš/¼j†[	«%LW.$ÆÅlí+(~”°6ö—¸°Õ3~Ùï‹œ.èn@„8©[³F4™²ªbü²epg¤8X¤hÅ"
§´©æAóÖâ º?ÂÁ"Íë—EâŒy
³&ªötğOÍÜ0ôÊ>‰,ëÜRÂ8È" {OÏc“P—)-ÏvøRªJ[@6õâ;jÙÕŸc* bšv‘D…×Sk”ÄÍoæ)dÜ–]Ã¸¤Ç ZcLÎÜk± Ùa^i73W
Ø·Î~ï_!£Ú„ Ã—ÑN´)†6“aÍXRúÈY`S}Öé-†ÁÁj×÷ùÚ‡ö‚ş»¥VMz¦DNŞth$0ZG>1iÒj!ÃŠçÄ7ÒÖÑzY”Z«ÖÒ,Ì40_æóv_`5CfÅí/„´TŞdu•®.ö\éûyÎÊ(ŸI¾ë­è“ıBÙ¨b°`Dù}û›áæDí¥­ ¡cÂËÂÖâëZ°5ä Ï`±,}e¼õ°+túm€¶é	ÂÜ4
¾œBrípé?Ó6u¥ßgLFŠÅ| àk~Œ	c":1Xê³_¶l#Ãe¨F
*vg„³ ’\CxÔ™„Í§ñ†D¡³¦LK¿9»Sé5§D0BÊ—2¹½ÆÌ€|,£>£æ«H&µ@MrÈK³A¶*•¼µ˜jk,³Šï
û‹µu‹çõØ¤ÚÓ;¢= &Ç›b^}”ˆÏOSÏÓ…Iƒ Ciùùüğ3ßS®Ä5ü·kìã9/²˜Ş
ÆÔÀõbk¿<µ%SWg™s„D¤ĞX÷”9ö°¾Às³É_M<É(-\€;Mô"Í&>¼ï–ÇììïJLƒD×¶<ât£­fœÒ§N7's4Uu÷õUav4$¡FäjInLºß)Cû—§Ül>ñxÎ†!?)8‰g‡TàÕ“~FlL]UVÌÔ6öÎ”Ä)æî(î^¹¢aäŒTãVëÿ¤¾ÙbQQœ	RkRzÑ—äÁIã»ÀßÀj:í×q¢îú1éÅÌÇ>uw–ª,‚]e†uÏgñÆÊÂ›' ”™7f¯X·c/U_C‰F#hôt±f+°~`ãğM™Ö[Ï·ü%Ì\Ä
uù")­‹/pBö
ÓÖ¾í —rëèDÍhëÆ9à7Q;~È5æP3qŠzgr5àPİö€ogÎ-ãÓ½ [·)ÅO Ö¤]Ar¹~eZëòòQîiGKÿyƒNÁôèÇ'j¨@YÍãT˜}`dË”>°ëG’ÈA4‰Qõ˜C_@dnŞ‹ïÅçyu©ëÒøŠÍ=ã}t$o§~\Šm¼8Âène©±‘‰ ‹ñ<Œ0*o½¾"ÙğÀIïñh[šøÄ"A‘*ı½¦Aô' ½H[ÆfÔ<>LF“…wô³¾'2O´†=uû¶`ÏƒWê©İRT{İÕB !X™¨èÜ¼—>dùaÈ&+½‹ñ±æ"¬Åì)¿˜ûô*»©bOˆ¼²Õ¶%ÄÌª„­½ÂE! g 4Ÿãâbg_-‘kÌTt÷†]ñƒã"Ûó?¿q”I¬-û|¹‚¨ß7âg4]é`&-Ùè¥2ßšã«ä	4~ô¸ôyìA*‹ ­á‹¡yŞ`)¾È²8_ÃÀş˜º‘“igğ€?Üç%]zQŞ‚
pàé¶|™ä»Ü¢L ËXšËâ{vfÎ©6|KRNMV†¬Ÿ¨5÷<ê§ø‡	T„˜¤O}óêÁ«eíªNi¬é›Õ°k 1œ
=àüåºúSÌ&›0ÿ„î•ı­wœÎÄÁX)ú±ã À œj/ÀX™9é7}z=£¯%¦¡fõ}8¢ş[[ŞÕ3‡üfæ¯§&'h—ç¦o~¾;y$å¶~èÓùgÅˆ7NííìG›·Ê<–¡ş·ÀÀr£¹b}¹õ«ó"^77³¾¡<f®r]ŞßG°šÜoŠĞËõaÛwâ9#-ŸBÁÜ.jÄíÒl(ÿo-$iÓZ±â‚İ€3¢‘[›'¢˜â‰á&Æí	a£ª÷Höƒ-O<7¯å’Û/)„;¥Ãˆ2sÿÇÌæÚ×èäßÎ~-Géïğ[µâàÉ\Ã«ë_ĞÑfü§SOÖÜwmº )Z‚Ò„ÿG(õ/|/å‰Ï±5ØXö°˜;¥vœÇ›ÌİÌŸ6ôíiòW«l’2¤æ¸†Ã^½86Ú+ÔM`ØŒOĞb´.ù˜ÏJ˜Õ=å Ãóiÿ8ë’»âõú„›““Ä+Q»ìÓÁ9ıõ¦øJ1û¢7tAaï*?}î¬¯ş6—ÜetLãÇ[s‰Î×qÈÔ	–<Šœ|Ã²ìF’¾ğ¥¬“I­q?ªİK…X$Ù%b—6×üüŒ	7ãVX¸„œ¹H¤òû¯ûGó¯8B, “îJ¤™^¾$Ñ»)Û†-ô˜¶ç#{¼ã¢ˆnÀ’gwÕ¸İHvğÀ-£i˜ÓI9˜^íË‹´µÈü"…ôïùÃmÙEÓğ $Åâwd,Z“³2Å©@70ù­Lm¡¬$DÈ•r`Ì6ßŞr¸šwØÊƒ¡Æ)~céŞw5ãÍ.¤Ùb®«^>`©b@xÛHNë¹Åå’ÌÃ&p$n%4°‹»Ô°«s·g(ïµ’¯5J½¦œX«²óíy§€fˆöÖU1æøYÁ9.gisD+ .qÛ~§=û1
WcF+ mfĞt5Şéü`²î<¸yÇ,²Æ1ppZ2nÂVù2è#ó8nˆP G?öÅzÅa€˜`¼2ïrF)o±Í4]µy*I;èò¦Ã‡MêöG"UøfUk;Ó¯“ßıôªçØ‚4˜å«uüFà3r~sîÔ©¹&¹9@È7-N*!ú}ÈÛÔ:/G#Ç:Ô‡‚³Áî{/¨#Ô/±(IÚîÖ‰gÅë4L}†3Z„™×ÂÎíÒıÇxÇ;$cä¼4‹Q*My!‹‰‰»ÏCÁÕ‹½˜Ì_F‘ÄÍ2A™’ÃØVĞKò¥çÎ	ÌF3’dŠ.®/%9saŠ~Õjl³»¬›ÙÑı3ùq¿ŠLÁGJ>ŸƒŞ_ÈïB?Ì%è)-¿ÖÜ©|[Ší;?KÏ‡mdÎÆ=ğ¨³İ8¬¢ ÍÍû*î3Æø6¾°"ÉËo¹LE ®°2{	U_íÀö¾rÚq¡¬uéŸêp 6§tGl‰@¦‹ç Ì:"oÕ}lÎIi?{Ù&iÒƒ£Cc¶‘¹SßÌùóì¼MÒÆtHûÒ9Ó~}wt™t¬Ğ×“g$£p{ÒTÂ°Fiıå@°>Š®àí›”Œæ˜Ğ)oP#ƒc "6ÔåÑ¢˜‡Õ†r(wØ=­ëé}÷ípJÃ•­©Š¶*F2@ù‘‚s¨’‹şc¶væÃM4¤Q<¦¾µĞ</‰´#ÅHgô¬Í# ¢êj¬‡'àU8#Úš]Æ& ‘ÂØƒ©©GÌäş)y­LØ'zGğƒıÖlõwrôbA¿ßnŸlJ2…˜èØ§)¾/Äu•VsBeãaLÛ( Š]Ñ¥Ü„RÒŞ"ªUÜD²µj™•6õ`g[/hA¹§w`w¿¾Eé†‘è–DĞYÉ~t‹Höh¨ÎèôÚ¤¨²•’›-Mœà<•lf¾Ô×ç{ Å!ë¡ªCõ³GÜ²?F$Ó/Ë®' âJtùh…=h¤àõ¸dznäËbÜõİ8IÛ-O6cï‘ú×?û†àµé]Ó‰ŒèQõß‰WjÕZá–fõ¤*¥Ó™ÃÁC²ZEÊk æxŞ–(eßöó"ÊEŒg“àFÃ`%ÌSV}¶™Ë";áÓá é3ñ¦TPsCĞ6¹{‚+ÙéÎ§øş­ M@>Öz†L¼Õf—â=î*·JqÊ.•Ò-"^~õÿew"7lbYeQ?¨	şnL+$ğ×%?xkâ›?U™°B¿Ò'üFŠØ%Ó¹HÕe7=«FN¾¢ÂfZ®\]òJò¸Õ©Ì¼Ñóå'O,˜}÷ç¸ì7÷¼æ )¨‰V*©éœµ¡Ğ;udJƒÎñ‘PÚ©nGUË©ìuï@_´ƒãã¥–Âsš>Ç-=G-7Û(ËÁO•DÅ¹«"IÁıe&§£Ïz]Öİÿ<Õš¸ÅZ€ü03ºÛ² ƒŸTÕ€ïÚ6¢zú->1ªOñïÙagj"Á$Ô€xÌµ8LcÁw¡fù+Å”­© š¸`ßŞ·,Äâ@H’€±‘~o3yGYïaKPç"N ¯Ö ªä …a­ı³İ.‰õë_SsÉ|S3.=q˜Ì«¤ß™PkÏ•?IŒM–¹ÙÔ„hN;âGo¶j÷¦lu>‡¥¡AjÊ„G0„·LpI­Ûia›7Ú{Í	ÑÃø94@ÇÒåÖt6Âeú‰‹ĞÚİÆÅe¾Á%©î	ïnÊ˜ «/2 ¬¢"Û·€ ?Û©d³ïøšOaÓ,e?<’äÖR 8ğ«'´Ã?F±_Ş§x«è"d*Ú]İıQö¸JbkÌ…şw7àâÉÆn­a*+‘…gdúM5È«*?Xä˜:Ó
{¶û†ê­sÇ‹™µ{ƒ…Êr¬-¹ışL/éd—¯I¯½(-Õ¢2Šã	ÿ# Õü˜*ñ\MXõ¥–´Ñ¢ä_‚‚´›@ægÀw5!*¼¼°Ç &À”[S]ël]M@}ÍqC¡Ö—A¡ÍÌZBEÁ»•oQ+­‚’I"Ã›)"£L\¡ƒ<ãcH€©´«zJ„JÜ[’_âé\æoÌÿÕè:÷On5¾fÅìOGéóB‡›7Ôó¬ö³F}¾õ°·#Ö5íI~#J«r‚d¹†ê;¡6à;ëHBŠòäGåûB¸OUÖË<ˆÿ¤wL±îµÕÒ@ÇæfµÈ71(¼à‚«JË^#Z¹ûüº³1S¢=ê%3’àlmø~_%a˜;/
¦ìá5´}¡w±ÇR]ªä.38+ùrzqÉªiâ½ƒ>[Œ‹ìó*,A÷*èÏqCÃÖ‚\.ğÙ#|nşÍG^<EQ:>ç	Át(u€Ş—ùçK*‚ŠêÃgF0 ŸÚ¶&2ÅtGö€¦ÁLf¨Ú´,lÁcŸ–míR'v:Gh—ØP˜™"©åò­c–ò>’J›îúix‰·µ7Êv ák……–Ğ—bÒ4‹t±D}a4f°Ÿ?‹ÔeTÌ»£¶·gÕX%Ù°\·\ }ö…:ù–®¬¹ZB§iÚıÕéıü­ÌÍ¡Çn„ö3Q^ÓXŸ/dmâŞœş¢D6:Æ¡3Öíß˜O(Êë‰c›erúƒ4ÎûÏcÿ{Ñjº(ßh„zÇ"úG¿©ÀNUÂ;WO UË­HÑÙ÷™$ğ=ÍT±à<Ïô×ÇèîKk/Å+Ÿy¸ß8–¡r÷Ü‚ÁŠ2a¤ñ‹¶ufĞw]F)v†DÍPJÔÓ2òk¢²Çàæ‡ÂÄY „öSğiº¨8L&ÌSÄ}£îyÿµªìåÉ[Êğ*‹òíj¥_/	úükmÕÓ-¦©Ÿ
Š—öÿŸó %bcõ8V¸\z›ˆ{I &/æÏšg·Às"àY£ÃÖ'œ{0pÁãèş:ëøYK½T·¹;B;œ»šø%æóÓİonHëPøôó@ğL¥…µÃò¸3J§÷şb+5¬ ¼_H˜;1‘Ãš”9tûV¸9m„2ñ§+!Z
™I„sÃcÑ»p96ğf]ë‹ÛöX‰È½”AÄëñ}ÅëMRğ™}V@e;1-„mø¡°î¯L?ÍğC–¨4e Õt+ga]$GäÍÊ¤]¹š„0‘‹Ö¯mì™a{é6äÍ©Qõ7Ç/wÄßàmÜ¡2X_ëzMä‘¼ 7‚‰¡ƒñ³QÁ–ÿ¼N»ˆE¹]vH Ü¢éCŠÈOßVıì˜=mM×'y‡	°~ˆ¶­Eºõ&rù‚‹€~_AsIúÂ½Xû˜Â*»×Ã³ØÇçÉIF˜F€'h­ÄQÕQ¼²˜¥ËØÊÎ˜ Ê¯PÔ€çÚl&ïáO1cÆ?¨+
ztÏ áãpöò„œãğ9ºWP¶â°Íb•á3›ôVÚD/0œDz¬JéÑ*ƒo¦¯ĞÀÃ¦ÅÍØÊNğd qA"ÈƒŞ×lO"–ÌÓêk§9=+ypŸğ^ƒæÓ¤|´Ù4Ñ…v(<Öl_SnJıƒNlÊJ€Á2 ?6ôvƒ6ùh±W½mŒ™DrsaFŒ+FŒiTˆç‘?œZ×·Mh Á?Í´1/m%Ï”R¢nd®#P"ñ³A ,[I‹JåÃ³e3¬Œ|“%ìDDbkjè9Õ­šÄ¹œ^’3¹ô–”ÂÌË!@ğœ'>Ô:_„aöjåy÷iê?/vSxKD‚Ælİ¯ˆ“lşçhÇŞêöTÔªbóW$ï°–LË’ÉU¤°GÔË%š
x“¯Ìá‹YÒ¾Ghû¥
Ø¯ó&¯ï›ÁPD¾ş!‡ĞCÂÔëªşlÖ­’Y”GŞáŞò¾fÎ%‡÷ÌmÁˆó`:eÖ«ÔÓQ£!¼äüÜÎ?	ì)rBúÅn+=şpë`ã<Ê©ÅzQvM
Úı›)¿æ/õG*Ö1B3íàgñøSVCÓz{ $]!-lù‚~ŞVÆõëIW]Ş¸‰NÒ,úæ$ÃË"+ÕØŠã5våYúJ×³«â!ø»:[¨c™!__İnêÆ¢ÑšÖĞUJøU_Î˜ì¨|VÆì£L!ù:{½ÌŒ7/¥[m#+@IµÖ¹lÛweÜp-”M“>*´Wş¯“ÇÜÂ·Ÿ‘m²4Gø­Âk”%³ÈrD´±ÎóºªaÁù_ŒçÍÇÖÜ)`Å›”,!Í.7•Gš™·e,ÃOBRò¡¤yêÃ~—E 3Ò¡õ¨ˆ«Bjş¥ô#«¤@°Íƒyå‰šY»“¿¬[nóNÂ_s¹ŸÄk‹=ú4 ‰àÔd˜ö“¯èØ± |¢ ÜÜwCw;    ¤f rvĞ ü é¹€ÀúÊŞã±Ägû    YZ