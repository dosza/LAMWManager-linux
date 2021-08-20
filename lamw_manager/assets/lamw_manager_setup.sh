#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3177462217"
MD5="a6556a064b078ce3a22e24f7c36aed6a"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23560"
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
	echo Date of packaging: Fri Aug 20 04:02:26 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ[Ç] ¼}•À1Dd]‡Á›PætİDöaqÿµ§Mª¥l½ÁÛÓêª!’nÍ0s¹<4 Øškß§/5œƒP§¥›İ}cŞ¿ºcÉ´Y‰êcäçv¾¦$ïªĞ76º·IÍÅ¾$Á0šK6ÍÆ,2<¨ş×]ëçj—K4,õßªîEG²·G·÷¤Y;S©«ÒQ÷O©9h[ØpeoG~Ê>NJgmdhbnMàşM0üIu˜‚›•¯½rƒõ*àƒ†iê¾ò( LÕññX´PõüÊ´ª‘*2z”³*EZLZ·89
¶Â˜Ù
€l÷ Õ“›©ìoÕÚ(³ãV¬ùzo¢6ñß67+×Ô2¤×ÙÒN„èåb‰û³FnSqÕ)[ú1]µQ¶8Â;’¿?1'_=‘AâË3ğg¬Kññ./	4ò¶èsW’WìÑi!xcQ-Pt"¥d|‰œ-§³¶¶h²è„´í4™µsoWvªx £>í¦;&ı­òyÛ§íø8±ŸgÆ¤pñéf1É6¯ÚQ0›ĞÒy%1æŸ$q¿(WPÁ5[­ÄÌ”tÏ®äÈ®nğÕ3Û›ó±®ëÏÀ‚QÉ×¬ÅÎ‚LÅH³­ıFqk6K8ØRmä@^R¤Á'Õ†ÿ×
ú$õGTiõàQ˜©!=©‚oi3jNÀVµ),x`QJ™<VŞ¬ßÀ6HoÃa»~P*éæËˆÍ8ÆW	–Š69›ŸşOèû$¾ÒŞ…8âÛÙQ}5ãæ[ü¹¨šóø¸|å'òeğ¥(I¢M@»"]kÂÂBæŠáû&yHñÙIjÙ~›ë¬¸st°vAÑÎÄîw–’´ïÈI¿	Àyˆ7IÊ€…2ÈF¶¯lÅ7 ÙÇñâk*Ê~´Zª¶ÛJ.„ŒãpÑ¸õ
tºß|Ê·ƒG_KÇô[,¤Ó{ß‹\f~I]Oø£—ˆ/·?
Äÿ*¯Ï Â;wm\XVÛ÷J-R‘WÍ»ëSrğü#çl¥@TiIœ]ğ9!Ä3’9m´vÁ«”wÅhÒd…s(óìÒÅÅx"Ûëö‹Û‹˜ñjjfû“_}íæt{ö|ez¬¶˜X>!g)“FR[Êfä-ô@D.ï6œ®Q¬ÑğÅ(c;Ç:¨+†Öí¨;`;7ŒÂoøÃæ<ÇPõÚ:Aò'˜WŞ{5)•l)‚Zø«°v²ÒX¦rn;zÇõa‘¢v²Qá%„şÒÕ¦”¡.:CGˆ3¶js#î›^N)fñ+:3êzµ½«¶ï;§Ô¶ÑâŞpñÛZa˜¢å}Ç•Mƒ„ÏŠ#ã}¥]õÇ45ˆ‹u"c&ı±”Ã±<2ÿlBÅşzà÷`#ÊúİcMK½#´ß×åyÛÁ=°Z·F›HÚ’äµEÀ¼úà‹©Û$ínu¢bö:¸ŠÂ3ì)0,ŞØ‹«âoú¨“—Æzëş¹Â¤ØÊdÔmWùBíC/]—&E‚OÓº‹‚€j’]ß­‡2ë¨ÓzLe&	»ÄÅß;ïY&GGh¢ö‰Åí¦JŒ¨‹–›ÆˆÈÆ­Åf”Xg…‡ºµ©ÃõŞJ9ykk±3KZt˜ê¯@o½ÊŠpTe„ËÉté½E«%í­š§ezcØçº†6"WøÑl©	Úã´­CéyÊøOÆ‰f.ÈFpW‰K5q€Mœâª³7&ŒÚ6Ï2zÒ%]#O
Úş Êİn*x¢îBÿİ0kÓ<ßÿ—Oİ¼CI1¸+&·`ÆìÃ{[]•šˆ€J8îW:ç=ä>ú¨lkıYîö;fî'±8IÔ&¯ï³R}6@RCîüÁ:^“ŸIwvùgÎwxEû‚ŞÑ¸í±0Ëäl¿ÿ$£y¹XtŞ(yà—Œ¶¦¼œàÇ†G]<õ·¬s™®¡‰Æ°îW¦G‡Ê;8LÜ¾IE¿ŞÛ9Uò_â¯#İM‹Nâö7~Ì¸D†0›e‡ÇO•¯lVa°§M;$ñ¯7a‰‰úŸDŒiöŸ¹u^˜çËí…úæJó¸ÿKö#¸&zğô‘cf¨Ílt«±ïYó,CvÅbN'…ï>’ÅXÅkt®5$¦/w7ùÿ)éEŠVÈo;áˆÚl(céD-Ö˜è¦z·ÆMëÙæBÎ>=B4HÖÙƒ8*Ó²ÍoLúÚµ¢ÅxÌKİC8ş•\¾Rê¤\qË7‡­øXVY¬" ‡sA…Ç¥¨Úí‘s}®ù|'ÓIk e[l—+»?ö¥Ş/«±œÈqô,My÷AÇñ»1.Ê°Š;v$ÜÒÈím43Õ³*I6m§Óa™W|ŒÃ¹¼ªÛíİ+LfÁ}´qÅp! ³Kw—B|eÙzÇ&Ğ?5¥NVbí¨vÈx¡úÊQšÕ$?¸9ú„Ew˜ĞêÀ\dõÚç’£ıOëØ4¢¸ ÿ¢›³ëíªJ¯~İòíêd0•—‚QXÁXOÕ[ÍÑÇÌ¾›’ô~ÒˆŠa]d@T’(Uí?õƒpz#éÒ¸¼r‹hÄ°å¾ëB…mÄ’î±îeP¿ø^m}-4]/Ã×°Kç#a&ª‘v^à¡…å\Ø‘„Ñ!´7î†<"1WQ0®=²îÕúï%ÒÇ8ÈyØ2@¨ríÛÆ¿pîx×3X–§oÏf¡Ù$¢kÜJ¬‚ÛÍ¦¡C‘·kû ğ=Í%¢ä¼fx·ôdo¡ª•‡@ë)ß“:¶{7smJÑƒ§¬¸|â©Jä#ßÑ&i¢jPg¸Qåb´ˆÊ§ÌEj5…¢Y†ÛÎJ{ğaÔp_„LÒ§÷10]éW6-pH­s*¦^®˜ÃiÆY2°—?‚CT\^’®Sù§S›êrc¶ò2ÿ¡ ı´d¥TQ¤ü¦‰ì¸OÓœ°Ø&Í’é™c\=İÔí&Êzoa¨Ê¥YCwÚ||öËD¯7¶ı3¶1oZçn?uTø+ÉæF&‡?úØ¬Ğ
Ì‘“]±0¨d÷¡C[a“¾4ñB/£MP9¶^”'şO!Y İ÷fûŞÅØC‡’µÔ]õŸ³ç´5á¸ä‘S±E8…İ¦Êæ)7Yˆµ´¥Î¤÷šr Æ8¿v	™$LõÈÓ!ŸÛI¦åºÓÊ¼©2ËkÚÁ={ı3%éh¢±x;…8á¨nQ­î€²4kCoZ|¯†æ±Mb˜1=+€¤õRmÑœ&Ş¯ï@çäOQ‡¥B[º‡!«íé\W\«hPlÙĞ)
®PM(¨û¿8œÂvÊVˆbªÂ)@ÇUÎ<tŠyı\G5ƒ|*4R¹Kc‹I³Ä+©(WG­·ö|€¦Gô£Œ5K'†Zƒfò	=lÁÌşa+]zåŠ!?Á<ì-˜2M0¿Ÿ@C·‚Œ"h‚EqZšEø²#ÈÍpu­?8ğ_RbÃsvÊ¯‘uk·åxÇÎÀÊÔĞÌ^•b’ÒÍYè|#ö™dhB>‚ìƒš}¬CäÉ—óLÒ+òÉ2 "8ã±8O;>@u%yŞM¸÷JîâÜ‹Éú_¢ í= Àöß÷rî!õzëã˜BBo@îv^)ú)H”.‡7†÷6áLÉ<BÒ×PfëSÀ³³Vœ]bR¯ëişœ®Á¿¶uóÿ–<À8…÷¨w·Ï!%øİı¨Ç4¶yïOÖÛâ--üèOçÃXW’ö$ÏÚ)h«Qìaz›E÷! 0Ç]É„¥rhŸ]\ê]ŞíóâN»è`Ñ%†(s¶PKt‘’2Zû¢™}Fí@>¯¡`ÂÏc©~O‹™0KFo‚n±ù·¸œÈ¯Lıdçs©¤4fÎè®šƒËš×t  ˆ.åŠ5¶ş¥[°ßğŠ_T¼R|gû`™áçNˆf¦Ê`Ã1-Aî>$Q4Ÿ7S7o-ÊÉ
ÛoÈ©<zÂT¾µçw>œ«<„à;Ï—§ÛCUšñ…À?-}Lå2D‘¶ËKc=·õH+ö¦Õøº¦¯²ÖDÕ\İ³IˆÛ|•o{ê&¨¹u¿ ³-O/6“| a¨ßíLTy3YEÀ@ÑÚ~Jí”Å!áu-Kr]w†ü¿ÔH?W}Pã ZF÷õŸ²ÈÆM–“Óz¸R„7Ë­ï+H?\MäøÁ¼÷@dÁàùSšVhÒÜ]UÆ5·$ÕsğÒ†5pt"¿>ûÚzk³~è§ÔŞ•¤@@‚.å+ô{íŒA¥¼„,zD‚¸+â6ßÕœMUå-˜RV×E®ßGœß#=1²‚êeHÔNsºMÚzïx|;
JJ³™ü¸Êæ„¹ïû†şzi#–U”c•ÇÀc¬D·oè	¥yPİ$O¨hË±“Üˆ
–ø"®ÿ¤1E©Ëš„É@ÛúW4$ÈŠ~4F²?$ iuqi²ÿ:9&’YûAÔUÎìÿÒİ±áJ!ø?w¤)»ÛîC£Ãİ÷²
†3íG°¯MnĞT`±oF8?%-ë·¬¶·E©ËcÍ$O`‰ÈST¿Qƒ{'sÈEĞ¬«ò‘zÏ„¸-LÖ¥4¡™~¦PN,hnFÌ³«y,TÃƒvÌ¯"Û,¦ÍÖ)ãlëÔ{0{hxPÌ´¹fÉê ›¬{×üvÌk@È×¿ô§uÏ½Ä;%?ùdª´AÇØ?Êe8øD¹Ü'¸éá)ÄàõG€ÿj[8Ú@ğ]Ú0ZJÛ§~ĞĞj<êÁ<òÌ.tKÁŞS@woŒwR¼Æõ”íq±[uõÖ¸DÈPëÑ¹Bmã‰ë¬Ojz+J¥“xôÊ‚Ù6Jí`k`Rå¼²3v·EDÚŠBháÃÚ0Ô?Ë±§=õßùd]ºÅ•Nb¾RÓ¬î{ÍğÜŞ=¤È‡aĞÑ¯°ÿD°nöCÕ¤AHìbî‰Í(Û†W¦ÎYF.ÃîKŸ ³ÈKTåJŞ#rÊØ‡4öş6”Œ»Œ!E–2îà¥ıÇë‡UœKtWÌğ	ş¹*Å?¦ª†x$¯ús½m…­aØN_)šº& †È¸íH,XË59?5÷ì/lÇÕh	²F	/¯Òûò¢áÆX¿»f‘ÄCô%ò­ó# ´vÔß Iyõq£ÇdŸ)øïíS	tç:ÔI¶.¦[H)VÚ:W^z:~e½O|µh}Ép·CMQG¢7Öm&İ+áYö×T†ÔÁÊ,àß34>ylÿ‚\zªBXıÜÈ5¬Tv8ô’Ù[då?^ŒÎËĞî«HV¦HlºÇZ`»	£§4­öƒÜ]R³7	°dz:éºœçˆ3³é7ë;ïtjŒì:¶şãÃœŞî·ÔUGZ% uÕ1HÖ¼ÄïU™ËÑ¾ƒL4E^¿MëmŠ"ÍIKk›°öS®@Í÷š_
å µf\vŞ„Üfç5Â¿‘UFÖâ7‰€>uªïGk:‰ëa.mCf·gï`ëœœâ½•.öÆ¯1ô¡´àHYÑE¤Ëù—©ÆO¡u¯Ë"	^é/†ìI¤'¡Á	¨j²Èè,ÏL.$'`NŠ²ËPæjôHşçØ%*Äun¦ÅNY9A©ñ­o‡(Í×¸$FïıEÍoh—à ·/Ät8C¢•‡ƒùæı>  ù1ƒàSb=K•ˆaÿ(ÀJàËê©,¾¤öŞ-÷‰ôVÅ¸ûÄè¡ÉÛlËÕë±{&ÛjÇpúÈ~4ï7Ÿ„lszü;¿ÄB!é½ “Å€NívS/Ü×5×é²b&§§+T8J|ÅP‡†`h£
ëïô. Ğ^pşexÓñ½ÊèmC¾“ùN¾Z´wk;;tƒK•YwÓ?¹aUÚ¨ø
¨Ïd^¦kåïèåõ—L†Í€Ôš#cÖ•¯Æb×‹íB’Õ.Õ	¦V 1oé2ÀûÈ«@ª—â‚)oBÚçFuÄ.`ØÆÇ`¨…v»sƒÉä²àí™£ş»aù½<dØêåè-ÃĞyÿ¨¥Ÿİ:İnj7dµ^ÑĞDDdÃ@·èÓ¼]`YÛ<ãc{³ùªT‚ãxæùGÂ¾ÊË·»Ë{èú=Œrã}%òo8ÕZàxB6îfo÷9©¦O¿f¢û>+ÖÀY/Œßë"¾„Œ%`AVğä91L,(»R|y¹_Š'İÈ¦óŠÑœª:ÿ:	hOzZDRÍ#•O/S9îÎ%Q#×˜sú÷ø5 /Y@"n·›ğÀfÕÒE¢æ‚âÀ‰·âu‰ĞPÙUÁ[vwV$âaoÚà±F¸°/Ó\À]vÃÔOQçOÁE bÑâØ¼/£TUŸ¦Ã~fİQÈ¶×¡Ó¡ÒJ~½©Œ!|V?•¿¨÷eƒD&]W’Ÿ#¦)®}ÇÂÍ·ñ~f¼`ÉßzGiãŸOs"Êî—¸¸ê.)D¹ÏªU[«~°¿+:@B:4÷”æ5ãÛÊdëÚU<¾:è›¥ŒFRMÅ–dÛ4¨CÚ¾>|=Ñ&ã%Ä&"DkÁ¼;ğšH
Ëêkmn°¬»à20³hQcx)r
«Ÿ,'>ƒsÒºî§6lŸMzÓwR®%±:apêÔ7Ó}»' ƒ1f„ò«ôVDOD QÑ¡JÁØw!õ›oj5’µ‚rRÀÿÖ?¡ Áš›‘˜t‘‹£ ÅÆi/“¸Má	Cb;ñÏEt+}Â$?¤7´& œ\Ùã	•›ÍâOÑ/Ép»êùVhX¦­o·•X^çD»íâí’šhèqPnĞ["<Æl>…uÕŞÒB˜&¦àÕËU»¯?Xt·w“¦xïÇ@ï¥m#OW¾ŞÒL	DÊ§»?ë(Œ)äÉ"yÛ1ë=Â;Ş_€Õm˜ğãw2¯™Ù©-FìÆÆ*¨k©|ÌãjAÆ‘Ä†,0`&}Í$˜Šn®Ãj3»JbUbUñmKûtïX^÷]EÇuà¶w	^î@@cÙ¤Û6©jÎåêıã[šµˆÈ]Ÿëõ¯ëİş3-]Zö©=ákí@ôÙx\u”£Ñm°Å¼Ó<'@c­ñKÂ"ŒÕónµ	Ô6*:›€7x¢âD%¤ «•—^[tzcÈÒÿæ³ÜGuí‘Uê1Ğ:åÏKªjÚººMÚ»_R>õŠ5Û/P40ÎÖ7erm1Â¯Êõ}$h>$ö`£DÄ9Oçgœôé`T°Åvš‡Øçmzò7/opW:ÄF§FËÖîìö´ÒØ´ß\IÖßb’½Eù,°ÉåÌ¶Xƒ¿´zZåøSúÚ¤H¯Õ;R‘ıÎ¡»îˆìTÛ*€A½÷
´Şí0ÄË0ÃÈ3¹çY5 ?!ß¯ã”ä›·|±ÌBGôe£3ëÚAxê0ÿ_ìÔBáuo”zÃBç7PYç_ĞiZ|ŞŸ˜qN,œ„íY@ªøºnÂ16Cq­7rÍİ…½ÉˆÔÀ[äšv™ wÙÔšX&#àÅ^q¸§3•$`;Íù®SÌàÈ‰_$ØÆ;
±‡TÉ³CØÌÈ–+½6òæ éù±RZEÃÇ)c)ÌßİÙÃÈ*Ü.›sg´ï(JŸ)FnÙ_¡½çß{)÷},zTâ.˜++éÃ 4\ûNmw”J‹¦ê)î¬Òè -Ï†ĞNhG8Ün{t˜“!øÔµBA¡bX g‹4P4yv İs—·XÿhAÜÃmLƒGiıaÈ~Œ}âªçn9Üy…ä¤»2oãPy<&¸7œlÂ¨D™ÜŒã™o Â”Œøl=¸ğ•™‹×ª·Ş[®^dİK¯®JÂN$uıi‰•–púßZ[`öoÚPÓœN)úi}ö7±Ç4t¡½!¤L¥‘ÍÙRàÎêé"«*hæ]( úa7Yb
Q
}ÉîW<‰ğö ßR0’Ò¸[å0¨¹¶ü†8Ü0˜7_E³"ƒİ^7áÉu:Ül'°„Q¤7õ½$ğˆ†‡kıËöbŒ‹9¼ã<EmqÿG®«m‡×1K,e°ï4-lƒù®èîğ![¾Jí!Ù3¢Ô&>N»fp‚ÿc£½¶fO+n:ut ŸÒĞJ¼MòÓ¾q}ç„z3€1Cé	ˆèÿ½’£kŠ´Huè,‚¶VÈ› ütî¿“ õ©Dc¨aMÂş?vo–æ.œh]Ü9gBİÄÒ3$È*’,	ÄŒÙè/Ø$‰6xf¸Svøä*•ğlñü.°Ñôw¯ïÌ;,Öv\W”É´  ’0-ùÂé,ôUjç’a¬3#nr …DGØ`ŸÈ/*sWµÉz.ë_óP‡.>+¶z°Õ#ó€éÓ£"fÊè–ÎvSÉmRbw÷…åí–BÜÎ(Ø(²şš±Bö>£ì<„VÔ¿‡ÃØtOÊÉJ‡i2aš0ü Ceç¸İ
Å`Ìß³õâ®s“•û¾îõÒÜä­Ï½'nDYT?_ãÜİF'B‹˜ûœ’7ÇõÉkµ¼¨m¾]^ò{¨¢‚”ç0uM³Ï†øE0!E{:ÊV£>C²;ñ2$?”A~~±°½1'Ì ­®Ì[f…U›£låç¥dSñµu M ú{6ŠK&¸
áv/†‰¤ûMn/Şêa¦åWUz‹’if#•8[‡òEZv°-îSK¬›Šºû’ƒ_@$Ğ]sĞ×[±ësùxÒÄé¯¤i¾,yÎ	Â;s¥Ç¡!i~“£q
XX¦{]·Y8¦„õ$1d‡=JŒºï‡…¢n!7TcäíÔxåG9:Ãi3ŸŸ[§Vş|Ú8	³äËÏ&¹´íÉ¥áÁX¿yo¿ãCëÿg‰a^Ë >`&£HËøÖ2Âo<</`0zwxuˆÀ~¶TC°cHÂgO¾†öıˆ ŸÙaÍwåYµX?€]X§ÃjÔÚf&åuzİ·g—v‚Ó^yµ< €ËMPœh¶X–¤¥Ø÷¦/J,t—bàgŞ˜SÇÉ[=³)’Ê”rCd«Gnàç#R…°dKl”LèZy<ƒ¨-y>^/›ÒG1tˆÛJ¿‘ñÁ3êM"|“ËœÚ&üô:Š[¢f=ÚjrjÚ(/û*/%m+²HO•Ö½§Fr¯cĞZõ|ãƒ6j¯7ÆìW1Šœ8úw«y÷­?g®µUş®U0³Òå×ö p4--a@’gD“å‰i`Î®É¼PË&…£îq¸®rÎÿRÀ÷ÎÂùÆĞÀUVÊº‘ChÈ,FwÙ
é-f•l3lusª8×¡Ş}]/oXaŞzÁîÈ(“µ²JÈ¤D®4tÕ¦p„ßA[Œ£á?äg:¾Òl¿ÆØt–¢Â}ÇJ¬‚ß¹	ãpßv¥ÜaÃ<#¨Ê‹Í½¶RWcùT›j<Âè’ıAêİïNÓ„ÌÒ4Şİÿå(œÄëe
7ôãÏ×Ùß/š@™i5G†Ö‹…»:y D)‹ùúÅïğ«3—X¯±„ebk¦lrœÊÖó=HĞ-vÉ;ıòPìª4†ÌfÛßŠ—+œ³z[Úàao-)OÅ`l2U‘Ä´BJOëi2ÊU«ZXérc“dŒi`%YE^R…HTwí‘ùøÖ»Ê\W¡~vŞˆæ´¦İaçß‡‹5å7N0Ï :(åcZ|ÿô™ÚÈ(FéUË³4O*zOôÛŠxR……ìF†/œ·¬Á%µ3n|¢ID~½ó’üÔ˜©²&Xö©{Ñ8zf¡Qÿëğ®ãéFå:É\HzMÉR.ÿâw&…E¸3’²¦*‰2M6`kÛ Ò}ÂHÅ¹S&ò÷A;éeÓ"
$Ç\ó~K’K04õ¾ßVòYÿ§ùUn(IBªHyä;ÄĞj@¸–:ä:Çæ˜Æàé±!O*Š×[ qá,ç™H†‚ıÆ×£’A­Õ6õ¨û}µf”æ“LWJ–ÉIB­’q¹ëØ„ U[sÒ<s÷8À¶W…UÜk‚OÊ[6.Újp¥v`O×Œ©6¡Á¯“UÙ@Ò')únn Ğ¶Õğ/“‚D©§[$ùW›-·sÍ*â>/û°%‚|ãJX•‡µàzÏÌçÛ%M9şñ^¬Ñ¹Ë¥r!6%ë`¿º`Á=»"ˆ|,O2'ãÅÜN×	¥µ&CöÉPÁkÀ_ÓOCÈSû!r›ºF}!‘q‡Õ‡¬Ë½/&™IÔÁy›@KƒòÌ.v½Œ¯p‹]A]©Ìbağ˜ .˜¤×#ò«¦Ù5"b^}9¯ğÉôşƒã¥¡î6æâœš®¢É}\^)‡Î;Fï*ëÃÕ„Ïe¬ì¤ë-wp}y+çÍ
i_ÂF®ºÊ,|«×€>Ìi–=1ì’1IQDx—Ã§>X=ğRiı>Dªñj¬œ%ƒÃø5ä$è6¶3I¯£mLhŒò„Â¨kÿ)6¤yÎä^×Já+#S-WGkòX€h†è~y„–+—–‰]n,õàc"á2ZÒEĞû?ÿ„. ¢M¦ÕdÀ:½„>ÌEÎS¦8ĞÇÅDÍ²ÄÆ/%Œ|,ˆ5op½M“Pğ®Ô|º9ùÈ‘;†ÓäS±~á¦dì¹¬ Ø6GËJõØˆ‚d˜¦eÚíõ™•´ <Å—²«òêlS/œêİÈÁ³†®’šëV«˜s{L¤ôµ/¯ÜÒ÷ù¤®l
MüÆÆL°®:
]èNƒøMö^l‹#¯=C™Êğ˜#üÜóí`|ÑÀR½fß8¥Ïôx(°3j¨øEgûí­áâX:ÕãÔvÿÊ‡ê8lr’Œ¯$ØVÄ2:öYtµ\áG|Ñ÷÷0Í:¹Xq®Â#Ö–nI< ş™áÜ•]éVŒ;3Êo+	ÿŞù…q/(İ4 Ë-ò³}	GlÓÍ­m­µFeÁ4g0ÙÍd«T[~ödnÀç×M5pÈbÇ¸ï{95,ãu¤º	ğ—ø2Ô‘„]ÕôÍÜh¨§ğ·s¢]Ù“¶ªeç­ˆŠù Ç·5ƒEg!˜Oo×LÒià]ÒN´JÇW}+¦½Ó.<¨4³œŸÑù±,¯ÓàªëñcÒ!Iª8#å}§uµ‚ûK&Ù&¦'h¬/j"”“M,¤¸¾í¸Û¯­îhx0­bê>Ìÿ;â`P~zT‹Øé®g†ÔŒT}ª&ãˆ:£<ò Lšì¨GM.ğÏ·jQô9%l+êÊ´¯DÛ C!ÏaötŞ3¥Yò.ÛÆerµ(Ø ÌŸqôî1®\±4t‹Éqg-E­wyƒVä“ÆEùãÀÇıIÿK#21	€ Müõ85:ÅŞ›ñÛÊ°cQ¹¯ÑŒÊƒøÆŠDá(Æó©“T“j…'„tzús{(¿37?—„Êq¿½UùâöK\‘³öîNÅßôDm˜Cši]cŒÖ†V—¢k@75UáÌGZ"òo¢¸1Ï\vdêÖÒC?fÚz4 {aú˜=ü#
ƒàõé½µ…êÑ7+¾äëÇjÁ–"eJr§†ÅOŞ‘Y«£¤¯¤Âl<Ù“X  âmcA"äqkúXl‘Ù{¦ÃY9´ÙZ u¡4ÌÇÿÅS9¡Cg]²Y´@üäÒâ
ók†T?ßà/·nEÆ*­K‚ğY»“‡³šr×y~İK8R–½™"¾Ù‘ÎKå¤›lÂûØš›ì~|1J¨Ë&pm•T:Mö[ÚÖH4‘Îò >'¸&M¬P¤–B…´^İm¾Œ@Î‰e«¼ÉxÒÎMàÈ”&şèÔ*‡óéG::ÇQí³üãÑI@¶Gô4r6‘Òw<ÿ,ˆPßÓŒ©9·I©¼,Pæ1®üúÀ©1Jf ĞFí9Ğn#îø~½¥S–±¡ .¨ë0éíÃŒjuÑ³é±åïŠ–COÕ¤:‚wÏ=Çó-ÅáŠ{~–•­ƒğì‚ÎçJÒÏ(]~¾4$sÒ×ü·]ømÆu¸Ì…cc5K÷\mD/bCì5›Ú˜ÈÏL¢ì¬WGèššŒ§¼¼Íôu-ù­•ğò%ÇÁ×§”ºœ¯ù¢˜M7Q
»²ªíyÔ•ŒÕÑ<%±ƒÁİy‚Û§H{Ê}]4b¸ ª é[	…§4Õş«…Y˜êYJ›97'»q´G —‚Æ\Ñx\~…‰FÈêê3ı±ù[äjPà±†d€ bÙPU#$ÃhzˆòG\ 9MŸ÷ü‹^J›äù‰619òi¬´üP?sE-cªX™u+œ•‘ìi[¡Ş@¯9Ã³Æ,Í‡£3 #åú		2°O3©å‡VÙ‰(»¿ç}3[¼$«uü'SÚsC¬R°o¨]F¹•XŠ¤
AwŞ›`w]¿m—İ¸wµµH}JêWãßÎMNHT/uiö¥ù¨UÔ‹2Yê×Ï-ß32so›ã	Ú3>„Ğ
¶N+1ü7X¢Tvç1@ö¬QlĞğ7 ã7Üº+±@½aâ+„8˜ŞáF…‡¸7Ä&]	m}%×ãg=ñ^´izèY*¹|Ô`ŞÓ+ûËåGÃ´P°M¤±Î(J°5ÃÆÍŸy¡-#NtI*;ÿ¨_ V^ùMR³Ã9E[Ü²7–½=ç÷Ğ6à÷»ü ~`´t.ßÍÅ.[0¹0²Z[Boê0š^fvê0 Pâ¹L99œD¸}KX :ûHqAËØNŸVù#ÀÄ¤•YùÕ'Ó‘ˆ7¢RÙC½ô|¹¢ó	¶ª[BöÒ˜õÇ”¹ûÍ^Ù"W»+é¸·oñK	DXNz›áCW4i£rRşñÇ*¸İ‹½Ğxê˜™óf»;¶£wÈI,UW.
/Y*E]˜†[—iÅ€a~¨ªÓ°`ô°8|cÑëhj“7Ï”Õg¶Iò÷(dß‡@ÄòãÁd+ò‡ä,®œø  k³—íµŞxZ]B—›b[Š‰}Ÿ¥©YbÒ*on¡Ãù&-Šé‹{ë
GØƒs?¦>H—vÎäÜéÊÌ
#»‰«pÙNÈ™3¤ĞŸõÈV3°ğ<H5±Ì¤¯!Ìî-ZíÉÈƒ¥¨Zh3Ùê?Ã_`À-AîlFe‚Œ/zpR^í
áåôĞ:Ik9ND¥ÆŸø6…ÑJñ-¸¼qjr‡ª+¼è)u¤fØ6ôôŒ"Â²€»²E$ûÇ3Ô}sØY`gNoNhôîDãõŞğ·0„Zrõ\hA ;œkÖª¾{6N},#1Ñek¡Fş_0_lÜÛ#[Ù­jLø4ëæÖ$ÍÕ6=z'
oq.ˆ½	>ô|+öIZ»yË>;Ü4¤åä¬„™O]¦îqôHÑ¨7xÂƒubu¨‹ı=„QDG(iBî¡¼À{Ö &$¦|¨7üHvÈ¹^Äkà’0ê@~£yƒ¨L”“Ï£Õ¡¿§ó>ÓØÌ-¹ÂêWŸÎäËŒÔ¤¾‡Ğ<½)ÇV@sı-¦F¾ÒÎO6ÖXŸ(ı«J%÷×iÊvÑüHì6UXˆìØAö»oÌ»”ËbáÍğzaF­‰lRdc>Ôò¥eaó"2`GR—ŞlÓù~¾a¼Ôş§ò„‚Öu}ƒŸ>(ê|ÑÇ|ç@ôÜAÒƒMeÉK[ĞGµq‹:š£ÏO:WP‚—#õ†–SÕ½E%:kÒl+ÄˆK”d´™÷¿¨¼³ácIbHĞüÜz›_ç5±oC=l$İéo`—¤€ÄÛ66wá‰ÊÈ´‰ë¢åMÆƒíjyZ‚6İœnì†ÓíMW×¹h*$¬%›[{Lä×p\{VUàÛßb“Ï}ñV¼6+TÚU õ5lN ,Huø”ÑÎ+´Q8;ç­¢¤õŠØŠ¤ÖZ/!!=´§?´•İ‚×•ÃmÚ–•ä…#;Ì“|wU44†Pm=ŸD[#Î´p&ì´5wjd@R:­¸-Ìç^V¹a&§Q}jÔ3úQà/æê,.øû¯ƒr/Åd¦Ör‘_w£ ÿ5ßèÀá—š2q[=»C'dwÄª?f¬Õˆfı$Ò*5±Wé°¯8ì>¾›©ÎÇğ€§øJ'1±Wïİ\D…PRæÁq|–&ãšPXQÿÊ¬jxº•z·(
¿q¹¿'gÚÖL€Â«]mrèªFË{„ë™Äv¤5°Õ&9/WÛo±Ãı
E»ŸJÛÿë®àŞ6ĞeÓÒ½ÌÛgF@¤5^D4HÔò¦ÑIzñKV¹²q7Ö³4A\åüé¥(>~íNÈNö0J´>ë×Sk¢6º’\*²ÉHxş“sV¹,&7”o0c˜ÊÅ…<5âÖª±×^x´“ŸvbÆK+¶<˜K@%+ßğ?šúÎÉÛ÷mÛß“5c“	Š[kÎŸÿ‹KÈğÀ
‰¦É“‡o{ßƒ©2vß°€ó#wÂüã4îßLĞOf=‘%ë’µÕ°lÇM&<¼,İX¨/Üæ/ç¶m¢ÑáÕÜ9ÿÉ\ŸÚ*9SSJ!%±’}%¿©pùdpG0 f¸û„ó€ĞwÜÏÅ<G*Ûbd¤áÊeHï*B	$—À/	ÊÃ ×áKÆÈÎéw’zÕL’ıÑE 
«`íl¢¼åïyÙRùØ€£Ï(Âó²ği Ö{‰JÌ¾Ú²tîS¬¬zç2K6ıl¥™ó·=H5=X˜k³‡E^PûêUiW›ZÊæÊt–6°q*2ÙY5¶-×ò‡»¨ÇQú½@¸¼§"«Yˆ\†3n
S(»G‰ ]ŸÖ¨:¤óoûÄj³d8!Åª†Ğ'@ÕrHo[z[Ø¯ÈAFBûrûHLì¡ãVo‰^ª&kC¢ûÍè.ğ;ò\cï‹“<§Eü´ÔĞ5æ¬Û…f±#á«²‡]™È”è)IŸe1ØødÕ/°_Wª/³©{¦+„fI 1£cJSU•Mí%b9—¾y•|ñ
`ïã"™˜ÄÁ5)‰j~ãåÌ]²## Uu|+Ôi"ÀëŸe ü/ˆ³‡„ifóÖã²+‡‘ã ’zÅLh¨^ªÌÑæÇ"ä»gCĞı¢O¬x–ä<á³n~ßï=4zıò¢Ã‚ÔKá+ Ä”U]ÅgÌ€ x)#‡–=³Â4*nWµ›Çˆ(6‡¸Ë<DÍ$æ *Šé
Õ0¡×ÔvO„šŒ×3ôT¢úmx’07£E$¡Õ µÒE’†çåf	
‹<¡¬òvxW»\õ—LÊ*h¾_“¸÷é”{±Ã5•bcJUCJıß2Os2•É—[E©Fí¯Cè¸ëÅ¶ÀNØ=æ?rFÊ²…À«.«Vã¾‡ç¶Î]¡ùl:4Ó¯GØ¯GŒnyvó¬Ÿ&¸?¥ *%Ìz¼yÊYÁÂnWÿ¼­°ònqxŠEƒTÖ•|İq‘;v)Ã ¬RRR4sax™ÓÍæµ0»óúH{hÿZëp1€¢¬$?ÈÆá[mê–¨™‘8î÷kÊ¡ëO›-ìg[İäuÆ]¦`GsÖp¥¤Fæ·JúÇ\ÓK˜p
zŞéİ.6¥ 'A‰…—Fn>¿|Lz_%ül±24Ü!{’WÀ"/é¼#Á|ĞÄİšlm8f­m¡ÂhL°v‡öÎo+pmæ—Ÿ1NìµŞdŠóY°€~gM«ç
¢«Q«2Ø—Ï¨8hì1õã¼‡·iÕ¾Şîª
_;Œ\Oş8ÑOİNrXvåá~÷ß¶€lÛ…!„9CÆ&3.Š<<Wä¢·HLŞŠÁu{ÖI„¤àèÜej÷BqL÷ş”rrëñÃmòA.£¯Údà¤˜ø2<å®ÕÓ)t‰«ä2^¥$ÚîB"º&D“ü•u»Ì°ooüvKÖø ‚Õ
 Û÷}M®g#‹AàÜ^Šô¥û‘\œêH[€J%ÚlàCÓ#ä0Ôo&çúŒdçÛ”Ïª3_WÙİ¡Ê‰ì˜.HëãÿùV†ÒfİYûú¶zgc¢2ïF—›zMñvÅOÑ¼î= °Âi»Fe NÖ›ò»Ë1:•‚v G æè‰áMvpü<ĞÔWD²ñy—Æp¢®KƒšjLeÔsÃO¿îFEÖ•vlº¾z}®iY³¯ÁÅ÷)Ué­dÄ^>Yn:§­Gİg*øÊæ†Ç&.*¼–5DR fr~›«û«ÂŸeÌô‰#IIZˆM=ÉUVr± #]çÒ¨» ]­41ò0QÂcÒÇ¯çİ87Ky'zğ^{­QëÓÚé
 lG·õuú¤ãyGœnPİÿR¸÷k¶˜‡„Œ |‰.,®Q4W§BåáÀWóñ;r%Skc¾'¿@ùô¢ó+°FOuÆ,ÂUA¨K'Á'Kßƒ:õ+Où¿¼²QK¤»:›À|î±Ö|75mÃ§Ô‚|•+¤z³×–Æ\Õgò×Â±Kò7¸õÆr¨õXÛ=×²#YœÃ6=8´B¡˜=86îndşu¨„;M"ŸÉÎª;MAìØi8Æ g¤èÙCGZå%5 dRúE™ÑÀµ¢v›á`úò²õám±¿Øö§¼-™’"Xšğ(½›,`E„é6½’õ[I2†‚’Ii üÍ¸@ÀÙ§”ø©¦_Ìê%Ô4rNlmi «×Aª£ÂæÏŞjYk-„—6Vjóß:ôêt‰RZ„nù†«P¹6—Ó(cÙ›¢Go|SE$os)w¶•¼ï}7ÀAo?0Ïw™'ãVù]ZŠ}$wµT®KRL®”R
C}x£ú]¤‘÷cé\ÃJcÉÃxŸ[|ÜHåûŸT³»«×›Ó§ä¡şeÑÑ»¼ÀŒ¯äWYLè†2FzY&?5‰Š6÷+b»Î¶&º ÷j@¥ôL§nIÔö‡º<$X”Sæ~€’¯odn3Üş6LË{	k5z†ëƒ~>Æ›¡€wvªsĞZ³ŒÍqÚ&øit¬€DÖ?ÑŠš& Š?Lƒ£k"!İÃ–kˆÁÉVÛFÃ¹ŒtÙøş,‡yÄ›j§¾º‰è8T]ï“Ï?X¡·!ê–`cZÛµ~ZÁüf”¸MlfÅ­á…°QDèÜ¹õù6œøäö¢ØÄÙL4].§::rúx—¯vbôš_|Â§f8!a86"ø$7?ç¢˜˜l}Ôìmœ¦bW<¡…¿ò)uö|İ*¸u©¹\h„=<§* %Æ >±™ò{\Şr¾Ùºx€ã’9&f®ÀØUÂ{}©œ·´­œ·1-xË8™FîRÏÃ^“3-)Ş¸Ş¥d3+çµÇÕY$Q&i|(`eÅ
Šñû`9í~Ë;EÃôZÔğ|jÍon4Ù6M®$£lI¡à¡VG¦–&Ä5¡õÙNí„¤¨õ<©àdÑgˆİ.oIQ©ÿw¼·Æ9ÒD2?-=£«‹w †Ÿ:ZÆË7o÷FWO<—î8¤Øµ5ã0pM}wI1«1ªğMÓ$ü\›¢ŒÛÍîYaZ9t¸í.Ôú­r;¬éäéZG|KYë	Shß2¬^6Jı½FÈv›_)#ÆK0Î³½¿y´RÚ¥jiIŸ»ğ–ÔÅçAµŠ.w|ÕáCèĞÍQ¼ƒ
]mA¢Å¼œ[½Ş¡ë>#à«f@æ*3oc§aÀæ‘}Z¦A'ær~@éú¡zkjÖMykÑÈ·rŒÖ!—.âµ±ptà€í®“B vÒTàíÛQq­öî€Ôk§È~=Dq-S«TÃIìèR›°º ±vò96§’Y¨z_ºOÓe–¬Ê›H'ßè©RñnùvüÃçfˆ=ñšSş.Zë9hŸÔÉº`éL'UÆí9Ò´2ƒrÔO’I—âò(ìñ	‚FÏõš3ß•ÍMZÒ\SñÌToâ>zœÏ'~suõi­wÓ Üõ%'…
™Büm2 S;5,¶XÿöÀ'Ü¸^Ş´G·âÇ€gwÒP­ªh+‰öú¯E8TŠè ÈûRê…»@óÆò–p¦vW8öz“Şô(ïN»nÀò÷7¯N4şjø)'b7Çç!F;ZÒH¡S¬*²Ué@ëc2ğŒûzîŞ¹‰z3ö¥¶¨â·lûNŸo®•ÄqÆà'ÓÀ6‹{ùÑÒ°nÌ‡(2n¬¦›s·s
†iÏÅfêì’§ªZÍŸ„¿ÿz“µ ÜÈ?´‚°°+b»BäPx‰Õ)œ†ÎêŒ£ñé7‰Sğ®±€ûJVáEo°¶æ}TæS9¤¤ yOò< óÌ€ÌQ0M’(´#ë #gEg­Â»§*¨k¯[Šj@!d‚Aqğáu4…|~èg€”‡K\%3š1ëŠ‘sæ´MH^—wÓó6²Ì‡¯ó®ˆ¨^ª~¦¦¾%>jwUÚ9#ÉÓìH†_Gé„¡e+°{mkÈğóìÊÜ¯Ø\.G"23šôŞ*pìh7ãíİÇ¦=nü~1
§t¤|DHûc¬=7Õûì îJÖl7‘¿ÄÔv bC±ºu@Q-
ÍêÒ#iåxüvù&µGÙí>YŸWú…}ÔÄ±Œ™rá8òB_@îÍx¤7TV‚şÄªS}#SYà£Î&`ÆQÎÜxôiM®ÌhHan 85`+*Hé“™•°W¬–G’8¤ËÉìï¥íË®PûDĞéXúÓ£NÒJŒ2ÿKøËÎãä_T¦^$•j;RCŞºá|°Æƒ›æskA‚D«<‚ÛŞÔ X¤RåÊrºN×¬Îş¸eƒJ vlô”õ<ŒÄô¹wºì/‰TWA}Æ·öÏc İ×Y³âœi Âm:/ŞÖ—`7²Ğ¸GÁ;3’ØzĞ©Ï†ó- ÑPÖüˆŞ°¬ßOâôÙ9\±üÙ¦€ÊòµÑ¯±Z^‰“r¨¨mäè5èğ³C®\±ˆjÓ)JÚÀA’úhJÅJc“‚oˆôj°‡–¾t¿·ñü§g*plDÉ³¼q²…ˆ©p
Ô¡ı³¼ü“+ÅÛÎq~Û*(ëø7…&-ËX&Ä9ßÕ(ªZ˜ú¶)©1×äsÏ½PxÖQc²Xš|ÅB»‘Âxºs*÷Æd0Îãs« şûã5õì”yiúAºúMN\Sù´·Nvò+J§ãe7ã,£ÛÖ-,é3Â~ZµL-È™ÉK”¹<Şe4Xìü’U3zc@ÊJß•kFNH#ıGYĞºÃKÖ-Båä¼¹¸;Q’4]ÖÈ¾¾½Aéö|}‡ıĞí®&9ÙOá)--bR]“’¾¢‰Ú {ÎWâ•YYyïpÎ×s¯ªõ0›q¼¬öè}tPå<RªãË©ÊfÍà0öšŒo.£ÏMúéSÊ®ioxë_M½ºå%XVMŠc=w÷pûË#é„hß˜yÚÅñç%üğäóëƒˆ
Çû«¸?b°Ëh> Í$X€fœ~ò˜?0p Xxè‘—zÑ›eændîĞ›ø\-ÏwFÉméŠp¬*_çwıòSŸë%ÕsƒccÓ¦ƒ—oÙÆ³ÿvª˜à¨‘sä¬ôm^*Iå,™=şŞQîı.¶í£K4ŞÜßA¤‹ëlE°ÒÙ÷E½ÏG–÷ÆÏ
•b°ÉE2R“7Ï%ûSÜİóE»”ŸìkTxä=íôô5
	«¹N•È%ûÌ'$o@„Œ³èÿ¡+oÏşkã;‹|u	³İ]ø°¢o¹>c<Ha{Îƒb‡`h˜Sõ­bvà¬4@qÿ¡ânLì}óôüÌÉ‹u²5öâğ|®¡€™¨GEqk·j ÖGƒ™_ëªonÒ7å×şÛ€É±HıˆUcó«Ï|Vyxˆ²tÒÏÿËÓíÖÈÂ~öğdXüNæûQ:çzµÊ&Ş˜ÁFz>[…—á*ü8BùÊ»ì©¯ö‡$¿Aí%bræâ(yæª¸ï°yÃÊ^•Eî„Gƒ(„ú¾Ï¸d]€ÒpÑ©ß!;s™
œBşòSnõ¡j­TQù”TªPñÎÓå¾ã|s‰¾I­ëØR„~cQø2^Vı½ıV 8/’q¾oäPC;“OWWÌ,–¹r7ğ´òñòÇ³ó&½>zzœ×”o®J§ñÎ€K>‰åã #MwJƒúUC[tc…]µ¥+àxzú©ú›gŠK¹Q¨Îïš$ˆÑ¸¶Ñ]ÌcWé°ïI?Hø9ĞÓÅYà5>Úªn¸;4¸ô¸ª4;…PÕÿE.Z†Œé€2îBg…ÖUæ¯+½£iN‡¼˜7$öÇ¥ç|&0{.:¹bIĞe™v DÕ¢6Æ—Dí4A\¤áge3’V»;‰¿ëƒ8Bñü*CƒÜób¥0—íQD[ÎªSû¼öÏ]ÔïĞÈ‹ö&i²(‘Û€2˜>p” òŒ–ù|DÊıáÉë*YÅóèm19±¢ˆÏœH»AGœV³4ô®qÓwı¬¡ª×5ÁVVJÖ|ÓÒÚL¨)U*×©ÀKCÒ<Êã½û>´y‚mféË‰¶ùt. +•f
ÂeßŒPËûvËübİdRçÔ+õº—–ñ»•™¬çó°6™Knd<­¹Õ'ÔÛ<[6
¿j¯%OˆĞıƒ†“Ÿs¢Ê"sÉÔ›5 ÈF+0îf÷É©Çæœd6Y#J,C3$S0¸œÊg!¶½RÔß&ê[©Ú¦©Ùu.~¼ ï«Ç	_ÜìŠ„ÉıôÿF¦¨7¤c7fà ½½–¬Šèt3&Óà#K³Zş2Ñ9ÿê06—
°'ºåDRöê¦uQ;˜ÂC"£“
-Ìğn 8Ì¾ïºúÇ§£Ä¥#¶Ğ­ÎØİNËá û±«UTáOk9¤t†ÿüŞD\ ~ªHrÜÂ$è6åºA³¾ÃT`éÆzçé	•¼ â°S£ü'IˆjK8É†Hó—%sš¡dKõğa&¤˜q‰M<¿1nÓãk®¸EïÖb¹-î­ÍyÕeË\zÚ>ù'_y›yÚˆnÎ[4æDnøÃĞ|må5éëŒ&mOv:ˆ%êÊ©şæ*$ªÆê†´qD³E'Šcğ€æ!óQt#óc¬çô`{–Ãúñ'æÓ{DÔš>­lûAÓ‚áB;­“Êåã¼µXGšƒÏùv»Î-„L0€LÍì$¢aÌ	·5øMS*B?Í@Œ6CµÁzAÓ½Y¿ë]ÃÈÀleöÎßo˜ß•ù¯÷›dlÉî°uK¤<€çîšdõâv.%±RX WŸï¿"ò˜s@"ş;N÷}a¢¢—°Œ++«1UğÃqíîô0Bø†²G¹&ÎB=¹£úÒÒ±×üø+,Nß6Vµùbä÷Ó·ÇŠ`ù‹å‹1M&ÁµãiGfXé¹p–ÓÂéhÑ˜¡Ñ
 ÔÓ:§1âü¯õpQ[ôÇ<C"æ½êaˆÙ¬†„c¼êyÑ>MÒoë ¶Õm/¬pG“wˆ¼6u|M[–øv_Dõ·:/I&Ë’Õãµo“S Æa>;òöZîÌUƒS5:¡>q†ÇE61±ÖI±ILP	ašÈÍ¸«Xü¬ùOØT„öz¦@Òß$[$E¿=\Şb›áÑG±.°?wK5oŠPú¿‡ã`M-Áb¾Ç<#hrõÂûƒqøô.€°+'‘oöNFšô¡9~”NŸwƒzÁï×ãÁi\İÜÎ+C7Ohû°ıA**¼[İ{ödîØ2o$2=âK*ÛiŸ÷gİØÁ?«?
ÂLyA2“·¬F@qPc8ºÌ…ŸR‹{Ä’ô6šoä6NaJI&¾¥“k)Ó®«:dŸ%Ö^tbÓF³©ïK›Y{××^—¢6RÇÒuDí®"Ì0Àû¼²j£…:ãè§{1BÃ…Ô+·õÎ{·OwHÂ‚‰Ü`ûÜ³À­ÂZÓ‘#¬Ú¦”ôa3st{ç!Ûéª¼|ŒÓwP+3³—zk›¦šÒDİºYÓ;*S¯t‘ ÷”.’¸êÅeÒ{Yw†É÷…,èNüÄØ;qiäŸ<®º¿‚ú&I\€"	'İp’é»kÃ€..L„`¾Å5L†Ò1ÆÈé…§ñyÍ8ˆl2?öƒ]®
Üş–.,—1¯JlïQ™+Ë´õğøşŞnä/Ÿ¤+©˜š(ËmnŠóI„7ëõW'kæ¿:œÜqÓÒ©ğĞ¨ìÅ¶í@¡Ü6‡*ÌG¼†ÎìL•ñôì;²)ed­­:Gßf®ÚÛª.ƒŠ@±ıMš¯u‹J‰Š'=£û|$«ºÙ·ÿ6jÎ—ºoK,sLsc‹Z‘÷a×Z¶˜J«†‹PÅ&HöõÉ!ÃÅ&¼B9••ß²(oøk¦íˆIÉıfS¨ßZ |g?9
Ú¡ñÛ8šTÒtìòùƒš4ÖÒømìŒäcó ‘w ¹5E<>e}ë¨g%°Zs4!cƒˆv¨3z¶Ÿ‡€ì¨lÄ»šúªÇ
İº„_È›:áøËãV £È“ "í[ø‰ÊÑHyHDvt‚lcÛ¿\v§,rôund”¿Ùæ
d•hZU0PÉ×qëœdÎ€+ÕQ¾åîÈÚX#"‹Úz
¼š^ĞÏíh‚À#ÙEô…u+0èæfÔ#‹Oë‘UYF²8—¤9„ÌÒ3ü§°¾Ú1x³Ó%3•EB}|Xfj±©h÷õëaÇãÙ	Nc%”­¾`¡<‡ÿÃP±íø’‡¢Êª¥kE?Àel™+¦Çî*ëåŠ¥/`pøÔ­d ùá÷ÁxØêÂm¡H!Õ-§^‘È‹$…ªöÇúnüœz4•¥®ejzÄÜ„@2¾¶Yé•aD#E$	êÙ•ìÂãÎ²¡ÁV÷‡qWgµ¾[íÕÙ”•Ó—5EÌvÔ=7Õ-¯cÂ¾RJ{È„g 1r»ã9ı·7™NÀF?I¢SBıxÆ­O&‚'&ÄCÖb‘¡º Ht@iãj˜²Y#²€ÊÕ‡:Zx_©”ğ_j>æ-ëózß–6xxY%½s_)¿¢=b<;R¯w&`	ÿ®•}¾`ZQ„vo²“¦i =Ôìì÷zÉ•E¦Oç¹‹mß{Z;3m7%¹î]€l„€–‚ñ}FÎäÀÆw)¯«ûoCÇéN†µ&ğq=†VJ×É†MØ$ˆÔ4SR‘x-»Â£ØIs<%¸ğ_ˆE2_u§‰›oÛ$$X^[Rti²„‹¾Rf2IÃ+>‡<œ…µ€E©=›‹wøÕQ2Ò³âI¾V¢tµh ÏpÂÚ)Ø¨cìĞÏ‰È%Ã£*”»&Ll)3 ã-ä(ì;D¹YAd\tGˆs&Œ-@c7¡[éÚüäTW;‡VAä{Jîf¥s¥´y SY¢„ü…AYM¶ş´t–«ŞG¬¯ü€}ù#É¸nÀ&ÏeVæ;€Š9³	\ï(6Zâ=¿Ê×¤’İ <Xœ€ˆñ—#Î…Ùü¡2uDôã™-•@ç©ÇFÛàÅãµ|«ñOoêz¸ªë¨
2Áì¿»aüb~ÆCÿ£ŞÊ7ªŠ\°¤y°Iºa-fk5øO„?'Ò@ªğşÑ=%ê`ãfßö—´¦ü‹@µ}énÀ`ù³t@àk1%(­»4«RF(ôö'Ñ²D#p”(wƒ`šOßßúQ*: s˜Ãtï§F9)¬^<[èò{cÆ"_1pğ¹OÖZOëì‰·]TCçİ×CÅü¦d*”‰k³Š®5^ TŒÌ¤’b?òï»U‘11tŠş‚ø–øb¢œCà£RìuÀ«Ş­‰C/ÃGšù ZËCØböèV—ˆSY–w4˜jÙš+Ç{R¥ºöæ„®Kw1fZ_6Ó¶¯¸k˜(!¦†º‰õÛè)^İ÷hgß³¾hûsÈ^•=Z"\"€d‘q#¯°nb3å§ò9 
·ÁıA{„!i¨¤ØVàã–ªØqÔm°“Âª7«X6ºŞÄ$SÀfT¡e+é¤kduE?© ŒF²•Dáì.¢‹öÔi4%ŒòğçAÇLeƒ®¶>ÙÛ?qaG.ÜÎàà%ZĞ11üü&¥¤’¹«Ì{‹‹(õßeÉ/ò‹%hââñ¸~:,ŸPC„"ÿÉjí§JzîıMæ0\'šF¶8o gü¯6×€Ó;÷l#”öFHhUèº¼ïP~¢«ËÚçï)şæ	1 Ç,UQ-íHu6:²I™Ã¹†_¼øÓHPj­C_»–éN#y¬’/3¡ßªİ*âé½^b¸¸_–Ô®'ÃåËûÌÊŞ9'éä/²åX^‚ÕõhäÛfóñ¥»ó—äÂ7ñc¶y¹X |ï¡=1z;}Sp²Ã% oÃñè¾´Dädÿš¬¡šn_YEùí]’¦œLû®JTË·¡°ïÁô²ØÉíkâ=çhˆy ÏµÓ…$Ş	Á¥E5şYã©äWï&rqİ×D<Å'§öË‡æú†zËŒÇˆpg²aZù¶92Y16ÙøACšÂÄk!@z­½[ş8!õKsnk[É¤ùR¾­?5L4î™³Ù•Ğ%sóNàİì¨]²*‡Tß(ÏíNÛŠœ"4ïJ©ApúÁ`à®2÷_D\=¸¸Î© şÈ¼;ŠOT/¦ê»¢8çÈêQ'p™R±£B’Ç¤Íaş2¤}r©Z_2†¢`Ñ˜…$\½Í©A'ÒFÛ§ï¥ÿ¥dd5Ó­~Ğ›Svo‚ªRœºâ)8ã½%$>%ÁX!Ùq‘¿j1í £Ù?OÍÖxÄŞŞıPq#‰÷£|Ç[íËÚœ?n6­eá6èzp–|âiß~rõ‘^$9:àóº-4”vå»4Óí@ÓÙª	C¤¦¢Í”Ú¿gÙzªªn_7»y0²Üÿ¢
){lXòT!$oÃe†´tÊ´òÂç¦P%õTWsQf†Ï)ÁªFZ¾zá3‰©Ò°ûHëÖÎFGEÚq€æÔü¨ºµVó´˜Ÿ0^v…é»æçIM¬/9Lî¶zãxõn2Nğ®¸%Ÿ7\, âf^çg‚Z3WŸ€Y­ï5BCÖ"ûûÜ±ÙÃè.Àßô ‹V8s1(ÜÓÃ-äµKÊâ›Ó$h)ö¢çÚA’nQÇè­¦é»2ú½©?Y~tm¢«¼äÅÑÆ*Ç¢Y^TF˜)>}X«Ñ‚ûUôv„í 0>‘oş8·f¾ÌrNän!òëÜÅ¸ó‡¦­œ+%ı7Zb[¥Ãù˜8l{x
Œ‘À§˜wîÙJ&ÍØ¸~-5n²Y¥xËùhïfZû43lê×¾¥WİvÜ†ÄŸ¦2ãçhÆÛÖí¾j´(ú["Û:Z–'ßàr7Ï5ÎšRÁ}îËñ_PVª´‹áÿ` Ì;7µ‡?'†’Æµ%–Ñ2 B5GûRîI éV{¡ãÍ÷Æë9	´ñOÚâw—g-Ê1MT<±yİvŠB¬!ÿot/ZXË-*øÊáHú’†¹×â×$`«Cc0“hMÿøC©­üB]»¿•˜jÃ=h´q™‚ä_ö¶«s2Ö
§ZîO÷wkèšÂ˜£ğÑcŞAqşmuó?ş¶¿/OÖc ¢5èŒº”ªÜ˜T"¸œ4ŠVl2=¨ş$÷Ä¥ï¤·$–n>’Pd—N3Ú­¬“Pë“E{AeR2eÆ„Ú§÷vúÑ¹åÆwÊ™á1Ïñé>¨vÆ« ¼¬,œŸ2üëå‹5ğ.]êÎ¨FQÎã¾ó†º+«(¦‰§}oeÁ»ëºz l¤¢
ZÃFëW¸5,¢Ii…Vù¢Èt3†,G¢Å¯yOàñÆŠ
x^±VLw«¡Svpîİ.¨ìXôÊókÁÒÙ×´²‰·iÅ;Š±»õ[m.­Ö¡šÜ~Õ¿&¢;kãm?[ ß°¦¬÷È*ÖCË¤è–ñ=2ò>r%ÿãÔY¬«mµ?#ÙÔ+®P]%‹ÁÎÊSŸĞâe¦?~Ñ5¼…ÒŠ2¶*/c~8šïyÆc¹fı4t‘…HSÛs:•ËäöŞş*â¼= zs¶¾Á¿é£§-fjôZ…û:B,NFÛÓå½a2ìbÑÂğÕ˜`4:hg¸éf+ÈË9õ~U„ŒŞ!Y#Ÿï¢E,X­uj‚õ"	&øR1¿\2UİÒõî?•“öÚà£äœtÿMù ½“÷lv[P
ŞAMâÇ)•“fâñœ{ñ1E¡„@¯.g‰ÜÃLàFî£”—”ªNYÄ$ª±S!{z˜™
—°sŠé
H¶#z\`=¤É¥:ÏıÜæ›â¡”sbl¾¦÷Då€¬Óà”Ñ¹-5lÄÒf¼øU×f°§H¡ês|©r„·ÊYá!Ï É1ô°¶K²R4ÇŒÒ?¬Í#eßK½µ`•*ùAìÒ;˜ZLğ6c!·²ºV}M|fı‡j$ß‚òæ|wkÒnTñG ¾A¹¨ã‹3ló»‡",ÕÖ»@D6írP=ã{cÃ{ÒüWn2LG‚\
ê5§!İãWÑPzAİãM”‰‘´£½°&ùÌ.yÂ¯kŸ ­úcüºş,7ĞäÔ5™Æ+ŠŞ¨áÃò8IïàK~ëöÊŒ«;Å2•ë—ËÌñ••&»¨@Mˆ°ï¶g#<³EA8bøFwš!¼ytÎ3ŒõœY=µX’Q´ÊÈø!'£„„¡_:àÓ¨0àÙT=ª›F0±Ø!ìnÑsø÷7MRK‹;®ğ¬Ğ>+\…¼o+ËÃ†%)JZ7%¼ŸÔªmöÀtˆeE;1nÈBWˆ§9vøÌg\Âo®Æ¸¡(pÓ°3$]‹cÛze”(NÎ[ŞsŸÁ"Ä—H«îd7S¦=m› ±È¡p.X+w]M]°ÎGÔêN[Ã¨ONş4<)Y4İ×©F³Îñ(íŸ¨µ¼ûC+Y!*e§Oé.²¬ğŠ©¯µÜ}T^ó8ÌÀ¢²ÄJW±gyïxŒÄÚÿ}0Î}‹H+Æ ·…)\²Õ¹„5t*	W!{š%×„„Ú.ütWxš.DÃ—fCU$Ò«îg(¯_ğU;ñëÚ:¤!÷@1à"¢tÇZl¾‰©ÌN^A{%tdö£i$²|7*´(I¬6!È
h«ƒcÔ{ô#ºN©ÚdE³mqñıUs‚­ï$?‹•r®=Ñà~æÅƒe¯-M“céõY};.ìW)ëÎ»å6Ìğ¯¶<[6#«Nª•}“ò<†T£>ÿC_T§ÀKZ˜öü;#ãjg2šØ»OFkı·©ç‰F‰?èÿ.D‡[Ş¸•‹äµƒCÆ/³ŒÅ†lHn5tßpOÅœä@ó[Y^—Øf _á3Pz€wQ®0/†Òa©ú°¦}	x´—ée?—6¤M±C¬/£¤5NPö ˜ØWƒtu…p½xéİò!s¥i,”qe×ì ¿LÃ)"‘ï¸FNµÇç©# J`¶óşçLbğAP^Jù)WA>i7ñëİ›¿”½êh"]ôv2ˆï‚S MA“è œ«-ñ# äbÌ")Š‹Ë&ùê6»büK¤ èÊ¬(I/¥Jb—Éxœ·¾gc²*è
É/iÍòüiL,D#‘^ßjĞÂ>ïñ£Nè‚wMŞ«a¦äö·nÔœï–*oR·c()ƒıµ™<FıœFÔ'Z[Šî Ÿ…íÁœ9Zû¦NÒÄ	`Ê¥—"’ünHÂÚÓÒÊ1“ŒÑYC÷sœhéd Ó*]Şh-$ıÌÙx¿{BrskMí9n«!6'Şt^9êËıôvqïQrlÀQ+¾Ù=[âá„°|”è,ù )APGp­²Eò>zà­ÈÛ8ÈqÑ#·Ğ<ßüË…¯˜G'¨M€q‚m‚ñ¯T`Å`UæŠ+“ÔŠG\µzÌÑ5¯)ct”vªôr ^Ö8ªè„[hÄVÇAXd›ExÑ`ğbÎÅ—«gDßAPÓ®ôµ÷róûøHŠù8ƒ1^’³ Ü7a·˜G67Á ±ó©ş2°-x/qS;Âf9x³H´ÎU!£ÙkÃe}ÈúÁ¡±5Ã£d9´d‚P¾×nÀq(İwMf„¤Ì÷+Ûä6^õëLKNOÍÒ’ÿƒŸbdşÇĞ_cæ¾×R¨.[¯ñ@ \|VQß¼º2ísÀÙ]øL-`Ü#ê5—’‘ƒ«—¾Ğì19´ÒeŠé.»`u£>ñÙ©3X¾8Î®}çù”+¡¢Y…Y\:ÎZªow^Ä{KrH‡ÒchğÔ'ãØÔ¿m`*íŠ"İÌM]’N1’–¨°ÜÉœÚ-É¥¾’¦hl
!ğè¼ÉYV¸à•¥óİŠ^iàg*u–»ÇP‰øÍz€è~øÍCâKi"™±*
bDz£æûôIJ^ø%k¹[‰¼ì¥=eŸ`Ï÷£¶˜:@±KGk6zı°»VŠG_ßÛÈfºÙ0Ö~dì©›m@Pìò Fİš>üËá—ğ²ñYéï¿Î	ß“T'®{/J¢Ä3Ÿ¥ß¼’®/R‹¶sl˜/U1 õÂaF‹‘õ°n‚Ù='1‰IÛŠÕø_T¹Ö’Ç„÷d¢ä–òjÇï\Å©Uã‚¥{?\M¤N3?m+lo¡‘ºÿFBWAÒt§aµ«€+]E¡hŒ™?+4‰¨‡–fŠÂ0 `+2vôŠ1T_2=ÁÙ	«Š.uÈº•t ¿Î®@¹	üWúòÕ…NS¬ì€J°esÎ%3¡ÑÕE…Ä€?ö_ö~	«J‡%Î‚-´Ÿş;¨ãüCiÑÿAêÎQ•ÆÍ»çÒ´XÆVú©™† <d@&&q¡¡J¯L'í …Ö’ò~Ò¨Û6BĞzğHÔîâP3ÔÛ¨¿ÖwPÊªª¶1äÊêñâÎSò¬¿Ë;ïM9lmsñüRåğ·ùÖ*ÑtPÄ}@öh¼ãö5f§ùLö›Qk‹o
E¬”Û 0…ZHt4±…ÀÜ~1•ìA  A3i½#*€6TêÉÕçì1¤˜Iğ’_Ñ¥˜ú–¥%‘\tş³¬ÈÎ÷ùõñ]¸úÂ5f!ĞÕ?UÊm±k4T8Ë°ŸÜõawG×¡UdÄ¦‡àv^×çn„‘Z«V’šÇ±ğ’¶º[WÅí#Vå§â æ¶ßØ—<Nnt˜Å‹C îS‚õşfœÑ¶©ÊÃ¶5*
ùr¿U ¡Ä®û=»-‚£ó)‰Ã·>!¹íël#¬Û–ïWœxÒ¶É³GZ7	Å&¨îQ²ğå2 @&Ä1½àúe?±dÚtˆ·VBñÈ@ÃX,8‡˜c³Œ)Ş ÜHišâY§E·øÈƒ&èĞŸi»m8E)ÏHP1„W T)¥®­Wà‹éÄ×R?ox\œm'ÃêXçb¡¢:>©†{—¥o9•ì¯Øi	»x‘¿ZíW›†æ ´hæúÌÕ¨5bnm×o©dQè_T‡Ñbú}¡$é†BfÇ„L?ññÀQÉÔ
æx3•º¼`KCı”ì›€B»ôÒĞPëˆ)fØêû~AP
iaõÄuJI8t6ªt§o@¤nõÓ38™h¯@sğa]Sñ`ìƒ?ıSá¢ã+4grÉ3xí™ÿSh³£w-ÔiÁ?Nä¤—­šLªfuáábk=j„¨RYÛíÌX¹şÌùs;¡pæGÌXıÎ¶œ8GWi…UŞQ-Î;![œdAL “vvy¿óe=ËşÜ&1k˜ÇÑwéºpá®¹.¶ûO!¢‡¬‰ìœkÛ‹¡:EA[°÷É íÔ‡åìwê7LÖ‡¬ØÄƒ«J£t£°ÙÁä3µ½†alA°É&Ê(%nUœâ¬#ÎâUKh¢:¸ĞUMğìĞh}ù4ªÒ9LX&Üò¬„<Èh¡¶·!Ò¨íïª&GCï°6g¨£˜%§|ù£EÎd+ü`°Î={Z::1x³Y: Å7JÃ{£'ÃÅx9Cv¨!mOÄe~º°.æ8?c½,ƒ„8VÁÌéş  ç¯~£÷¬A ã·€ÀıWuı±Ägû    YZ