#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="4199190074"
MD5="310f89096e8d0b8654034a9268c3349c"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20296"
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
	echo Date of packaging: Tue Dec 17 21:32:59 -03 2019
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
ı7zXZ  æÖ´F !   ÏXÌáÿO] ¼}•ÀJFœÄÿ.»á_jg]77G1j.…FSx­£×ˆâì1L­¥æŸ”<C†n0¦0×J|uØ¢&w’1ì©ƒ“©—åÇìu¨ÿ£F'ÀS­îŞ,3–^f’*üÈ¤²NAÚÔ€[ã R?]¬”íÇy*¸á sv3ÙÕK“V/\pËá	ejXN¼3„³¬‰Zå?q¥.Ï]¸@0Ép~{lZª±÷UáÑ ´¡ˆ«ˆ‹t+Î~w;ùdıÁ´|š—VÑ¹ô
|»3z¾çÈ"fÎEWZÈ|şñ	S¬p{ï±o¼€´;ª°À/€û>K^4„[¬ıÉ©nuØTó‰ÚMÔ´sNZln~â¹ì35[­Õ*Ñ¦"‘Í>šİ–À‰szÉ›ë®>y4¾wÁäEÿ»mTqn!Ê }
ø;ïy2­ÁÓæ2>¦ úØ xi½×ÀİnrµÅZŠïtqGÜÑz€`5ye™®ŠÓ“bJÃ}Ju|<£çîC®Ü¿ÿ³m65åÏÏÅ
Ş2TÀşx¥|´#(-eÄ´ßm.c™»ªøÀ¨z…üÂêuÏ\¸/ò_D²ÒáóÚ'˜&77Û2ğ¢ªäÆs•l rïxKu8ı“øŒ·SLÈ}oQáO>ŸÆı Ó½µƒ“p»ŠøŒ‘µJ"÷Ãz‰Ô}/Së3[ŞÊõp.şñÓ‚0Ö®yqs’Ó`lN´JHùf£xÿ×oa±·
÷!íÁ.5÷$Òœñæó JšoÃ÷”hÑ™ğ•ú¸ÿ-já§;íªRå+Àé^îÊi¢Ñ8N…Â3¶»†k7½Ğ 
Ç6‹K?+e©]ÌIÚ®Wœ‘t%'ÂÖÕÑgBüVÓíéç”¥·wÈRU98+wÁu<OîùÎ•i¬ş÷ÊªÆÕã êĞ76kd"AõZV¼]Ë:›ª–$VµªwªÃÅ·¯íğÄ\ñÄ.Ø¡ß.W­x=µZ“cÛ—Ut»A¨ñe@ÿÉô|œÁM yÕçFã´"£H>ÇõÉ§–íé·çi	ÂĞÎ+ÀòxÈ(;´™ræß;1ù¡¢gyQ`Tê?CJK1u7$ˆıuºıÀ€÷oPEâ®3İVF; ÀÜ²(öE"…[¯äse%)LŞ„¦ âDYÉE÷o(åßYÖHË©şìGµB.k“Â€¼ª}tI°Tª•‰‘¤£ù'z» 2-uõë¨Às¤NëÛ—D­‚¾¤ß•p…{`¹©K+%¯KO:ï¿¯ş}(cLY®¦½ö:Û‚Jùˆj{7&ÍïJ<WMğnÕWÊBõ6&‡Õ£Àæî->Õ¥Kı¦ÕC…‹åwjÉHã~p-›fËòıf"’ã^7Û[·'‡™ğXß {ƒL*
+0PÅ˜]TÛ ä\?Y‚OŠ_ÖÚ_üĞßşKE7.L¦)DÀm³¿Ï4e²,÷PÅ†é`Ğn*afIAÊÊ°åc@1v îÅã’ôX¢PZd)WÚÕ©tjDTçXáùJ'Şfÿªs<ÿ·»!9œw?Ğo›uD#ZÎŞc`†QOëAÇ½BšÉ8¯6ù™1a>£ãktpœâË­7âå‚]Ã\ylä”ÔxE‘ÚÀqoî&öº·…é’³ú”Qh›2önÑÉúóÛ¶êÍlè’ĞMnâß¸YpŞ³Ínºk¼d›<:Zœ´íF)u•* ÔŸF—P¢iÈ›ÃJá2]g”Àw±ƒfß*nà¼–¹§c¬p@y›`ÉÓnç¾ó‰9ƒ2ÑLJßÇ¡1èIÛæVGRñn…kcH%…a1O'½¼ÕN0®ê
k¹a‚1	l-¿yíİToŠ2º˜y5²@ÄäQrG˜,o™4d}£+Ğ÷78VúÚf¸S.D.ŸgZ¦?‹û¯ºÜÁ©€Û29õM ù¾‰v~.aÔÊƒxVZé4\ @ØâíMô()­\™Š"(.L®şÍxû¯ó@Ì´ôY+	ÁH*ÂyutEhÒú«ªífÒl,$e‚Â@”×4¥¯¾i´‚çRNÈ Â÷×;”÷D”äH'ÔÊ„ü¾è³V¼öH™ú*æm>/AôœeCYDÆÛÂĞ`±ˆƒºxN‚:ò	ÌFNËÛøvEÉ¦¾ eÂ²à"Ì$Á0ä’©_aÛ ¢±X–T"½›%ŒàNI5oIò­<{‚¯.,„ØáI'hšt:qŒÊ€ó9ÕOiÈZáÍT' ğğÕù¬s*Ëˆ/”ªn4"úù$Ö|äå‡Kò¸«f"²4•E¿Ğ Oş¶ê‘ã}8±İ55$ZÑÀÓ7Ğ“<©)İÿÛ2;åœoë‰Õİó¾5'¥½–®zrâ9›åÃ¬])ßÓâPÓçÏ¦™3&„´CE~;{ÁŒ™‘¸Ñ	¬÷Ôƒ¶ÓN?qsÕ [‰£ñ~om%)sÎ	O;ícx"1:`è¾º=y,æàï#eˆí™†hpO}êGdî÷`<YÊ1›nñûRD“hå_Su]qyÂ/¦NİSİ9ªNßí€^æÑ´ ®›fsæÑjÜQÃòÖ£Î6‰ÏGª/ J(²B«Û3@@* ŠqÖñ0¬ã‹kˆ'&Å×ã”ŸœÑR:ËîôJ.äî‹”kğ õ:¬bÙèW©uµËYØ»PdÔ_]iš1Y%À2Ãª-†ß o]>{¾Š˜«?P·½ ¾wœ]‡ba8·÷Çb÷.áHb—9Â”-âº9i¥Á~êÃ ÚFÀNª“!¡«ÇV„ËÏ*÷:Øû€l 
T”üÒFR×¬ÎE›È‚9Õz¹ÑçcQÄsWâÊ‘.fCÛ7O3G½©¿œä¾âˆ
Øq7«Ñ„6Ë½åàÍ¯xKbùŸ3mæ<k•:Æ¢4å€†ö•A}*ËXsåö÷SÍR;ŞTo7’¸IÈÄ9m¨æb¿“%mæû§^}„r0qRÛ(°}è÷qwx#ïñÌ»{{‘×Y¥•³é@½ üMÍU•7)v¶zÌ=k@…½sŒÎ†§Cp5ÅX¢™"Ø¦ßÛhmŸèuŸ´¾áñ°Kö·ƒ°ğ`É÷<"‚A"Ş{WPĞİPBò’RÇ¢}ÄWf)dûç»”·‘|˜Oû&Ÿ½³"ÄÏaºß>K9¿‡(
¸º£iÿŸxi×/Ë„ÜÔH‡li(ÎãBËÈ!³È²(ˆ&°ÑHÖqÊŞHF¾«&°ïU‰IE9Kş[’ŒF­©³j¾
 Út^o!ÇŸlÆW’A¦â1Ğõ8oJs‘ç#ÄÈT„|ô²‰[ÜØ`¤6Ş4ëô™ŞßV}äÚª¨zqÁàŒï8}Ñ–ãiq€|[È—wUØsJŒyÀöô'Ã´\`
4 mĞÁß¾´PöÓuÁZ3„—vÛcŸN¤
Ö\Çâ/ÑSf²(Í¶Ş]|¾y{‹ 3Cíü.°Ä5ç’3y­]aú)šÒÛ™TûšsWã·‰Cæù`Ü—9†!¢¢Ô@³z`İ³‘ÙæŸ GóÊ³ĞYõî]  ZúH¸½¬ÊÇÃìÛ…Ùh‰HC^Ê3²Ù÷Æé»„Àâ€IfFåÄŠ=Ş­ Úh_6Ìªª—¬[ˆøNÙOŸ[@Ô‘FUƒM…yXç¿É’X.$¨¡ä-â9hB·K¿İ.Ÿ-´ìzrjÊQÚ­kõšù)”mÕÂ?Â?V~îqêÓJ†T<¯CD~|òpJæÜX¨B0¤Œä°¶pÔˆˆ´~B	„ËH^ÔR bt½¾ä;ë·8¼î—™–r‘CP-‡ßÄY?UñàÕM¾N§¤+{™´‰àşÃÍ©b›ÿÓ†~"‚×
¶egaaTqÛ)¨,äç@0S®ŠùA#+ãOjz9àŸÎ¡îÃÖN§†€úµTK*6LT^“‡OJõ¥•ÀP‘¥Ç¸CÕIù}½Q€!—z’¨0b„Ü>,:plõ‡uæ½l-NÖY©²İ-á¼tx%‹ˆs-
PhY)´)„Èìc;W¸ò	,ƒàt¹ùşlà½İ¿ëTQCÚ àı¿9wŸ0qZâŞÌÖò6\¤H%…3:bêjîúfÇ¦_TYZÏ#j¥qã;|zÉ7@µ¡¦]9Öóù×™„³_ä j WÌ5?ÿ;ÿÉCö ªÆîuüş™rN	P~¸ş†‡Ç<7("›Xİ³+l²Ï£ıÔ²_]'e³1@xWû'‰ÓûD1ˆG¾W–ÎÓ£:”UÃŸŠ»°‚©ÓPCÊ¬>B•“ü¾yÉ5ˆ1Ú­Ü]ØÄfI¢OY=€L@Gp;ú´¹]Ê>È©j~”øÍnƒS‘;÷pê‡à! ¤Í~y›kÕŒ‹Nl5ÎÈG^Ó;\Î–¬•<™ÏUBú„‹0Å"’7`Â)°Òƒ” çr2!Ëş‚øŞ›öŒDÆa˜=¥H’äË¬bæDuXèC¥ÚÁPIl¼rP}zv4lDà]¼mM£‰Å·Â@"¾É7DYU7Ìo*‘TeÌ-Îì,*€Ùü%Şù ,¦Eb[ ŸséËe‚r¾ÑÅ£fOÓÇv8½å3+‹œ÷šïï³ìaöæu£Õúø,í/éƒˆ5ÄÚ«BÇá“œíy˜jë¼û¨Š£wÛRà&4Ú•¼dµ€5=ÚµıÛ‘[¨\ ìÄ!o?ÈáCFø¨ ßÛˆ+H¡åÈì2ÒÜÁPˆ™‘q¦zäªŒWKVúE’Váo>K¾`X­”ğ^)Y-ÔS8–´nÉîQø;Ø,ªåWg©HGqâÜŒÌ*?K‹A{ê%ùÎ¸"­D’“úÊÄµ?»EşÊïŸ½OöòĞ\ÚQBMÍc6ÂÊ‘Ú[ÉâŒàÜQfë]õë¨pºÍ|"EÅÃ?Ö §J‰x'~÷…ª&÷jÎJØAÕæêèúF¶N Œ$5ÏÃ!A!tIÍqï1W®Å±†p,A{D”+ñ^¥Y‹›[ş—ŠÉS&C£u“ÖR‡‰?:¤İD„¸Ö‡9\}ÚŒ
ïàÿC•æ³”Ù OÚ]%ã^’ìÂıà`ô}9î”Å[ÛHòú¢3ˆvHö­Ş,™şy‚]â ¤ìT~=ë|·	2“DiÖ5Ùon®–Ü}şqe½j[ÍcY†` ~¶åhç…*¥ŒV`@şT'¨©ç&LM‰Î¹èHkX§©v7¡ÁÊÇrİå¯…„±‚¼I£“é ã/İ×˜Š…ï¢Ñô bÀ­_ÕŠ˜!Ï‘Ìß’³vİ«®ÃÂò¨,jñE^L5$¨¤ª¾šX¿ÒÁCš¤õ1×4ÔqŸÑ&W—ÎÏ­ÎÜĞİÔ€¨‡ë¬l:Û€Ğ˜S »ZôÇğÙëÇ£Vgí$OdÎlJÇ÷æ|µ…›Á§şa§ùÚqCùÙp _œ¹!Hjb5¬-’ò°è‚~uQõ>XéË‡m«¨gœuš¯ø!¼g†Çn?İÕZ@÷Í*^E»;ç‘¹3oÎçåo–?QÆ-8j ÆB”ĞÆ‰µ—ı!g-ÑáZÀÕ¥Ñvöà§,$Ğ0ÓO÷Ù”§»Å "ÍaÒ^Ó#ïø<½¶««nM~¶°+…®scĞ'À¾'z¼¸f…e¢²ÛòÔüÆU<Ô3GJîã 7±òW„¯Şº6~;/“J‹6¹_ï[î¹U—:OÚƒ<œròçİÒç¬Ğj>@:• h
^„©F¯7„?Ä6éjGL»ôtD¸ÚµİeÎZö›ı~Ñõ8’H†âŸ:;TÒÊˆ"_Á R·iuÄh,.ã4·$ÂôX}Û”Á§`§¡´—å ÎÎ§ßø0ÎÆ_ëÓ&zãnpáÛƒVl®/XéMÿ!Ç+-2kõ}‡¤55p–¯8;ç6*?`$•?µ-ÄC½ÉHìpÆ¦	W¦dªè#¡·	L,&Ş0#”iâ„ĞÛlËÒJKá	|ã2¹¬iZ«®$'¬†‡ä|Îf%öáâ]9“ï½ÁNò5ÕŞaV$é¥S`ü¡€³™eĞØ©R‹°."BÃºìşÍ&éO¼¯+ğ|špön'#˜¸Ÿ± !{©t§øí;#1K¡Y˜e_¿Ôì]ª@•†!„CI=mnaS£„ÅbyT~Ãˆ=/wîIÊÅüÖoÆA’!,Í5—›¸å¨³×#»0:ÏŞ(7˜Œ÷Ô¸ÃddWN˜¦×tÎTãÃ{Æ µ²ıâÜHY«Û`AD¨t°ÖÇÎ£kfìì ûæØÉ§íWñß¯[ıäĞ¯œ“õF2T½Ø2º±Ú'¡Ãöæj^3<sãâôŸ"<ÚH¯ÏşïRä¢•æĞ¶Kã]¸ŒLî½@¨Ü	 ÏQY
Úù§ÄF©äwĞg²ë	Ó%9ƒBk@T‡æµ¼ü˜ä/JøyUªbÒò©D¬«ÒíMÕ¨ÀWãÌy]¶ +&Yœò§Ì¦uúqÄPt@½Yï:òÔê¥YªğÑßŒ}ÌÊøncŞ‹-Ş?",.¦»-°Í°Å>ÅùÑ@)1n½ŠWÜo»ı02½´ûËRA¡ÔwüYôğiÅå“t¬I§ü×}`÷\ªé ËÈ0İ£6¼aG`{¢¹Á":›ÄÜB ¬Êå2’xöûNÕ¶Ì_…Ó5„1`KÁõ8Ş‹˜¢[ç€-•ş¥Çã$ÂkXƒ*Q#9¤›c?n€¦ÿ‚?vf Å„/c¦Ba+7ŠähİâgíR¾KÎÖ†ŞŒ‰İgÒKïŸšÙ&9Óöí~§¹ğù$]¾e¨©¯1•{›R+JJN”´´W+IÖÎ¶«T)ºI`:İ”‘Õt†…ÚŒŞ_tã–‡ÿ>¯±Ó!t‚¸5Ğ»Ç»rÁôf¡³ıÑHò{ ÒvÿìâÇ«UĞÀŒ{»±	ƒGgC¥=ÿGÖßë|¨°ÿı_Ê‘öTÂm‚\Ë}#Âò)BÉ:'(y[»?d%÷…Yè1‘)Ø/¯Å:÷ ÀÁÒ½áA_-Ğ9)Âë!‡¯9u&–‘’·(D$´|Á¾†Ãç!n]=\C¤áô\ªIJ½"÷1Aİ‹ÑhÅÖ1±*wzÙ©UZ¡t¾É{§—‡¯pT±õå›­ò^¡éiKö&N¶ÙÜĞ8L<Ù?eµÂø·¼) Vm]¢
d±™|¿ó; RŠÑ¥¯)Ín™~Á:ûyœKFIIf	«¦uóÂ›¬î®i&]=Ôè”Z.¿0ŸìŸ/3Û$w	‘ÑŠÏi)Œà=Ÿí™êM¤H±ú(îßT¤Öí¶şù #;²óCìàÄ£Q)Íy£æìH¦~a`idÒ©ÕàV|çJCnà
KzÏœ¡¬³È2ã­±Ô-ó$Á0q¸×ß´W\§Ì(9Q®ºíscÕĞôB‚ Õ+Ñ£h¹îxáì¹U ³û+É¶¸Ãq:eë…;@Š-!/éaw˜êÏGBŒ˜Shz{í1aƒpjB,¨›9Bïs ùÏ"İV‹ÙøövW{–bA)Y}1”g›jsfPøÀp[¥õkU­~ŒtahúÏZC=›Û®-tËÄ|f®	$ãk²…ø³¾“™Ùå˜M6«_/“G0–©¨]h“>v»•êê•ûLÀÖ«¶
1Øİâ^8øÕi×I£ÔMgSŞ™ı˜³s§CÏ}P‰¨tª)s¸ôæ&„—él¡eÌÆUBûÑ	Nc‚ƒv} 8- íå¹u£qòäĞqE;¾â¹îvÄ“Mfº»õb|€_dª}jW¸­ŒŠ¸¿cP/`x?ïEÔ‘5û_Òß1Ì/n$9cD…R–BÑO6â)\Å°á³ÌC9ìì,[²¾r-Ifò
Ç±‘’öÍ~­á¾¤ÌOFZE™¼"`fÕcŸQê<lÍ|o5²iğ–Mc1¢½ØĞéaQşPä¢ëc t¯çœws9=±‡$Á^ÿıC„ÚkÒÂ5Ù2zŸ÷è¾Pc#Ñš¶Iñc<ä´¾Ô—OyÆú×éõƒ¯éÁ¯øyuŠ&¸`Mn
~‰{ı‰³‡®~D°o©g0ı‹ÜË‰z/hıù——±VÔ6Çu$õì‘
½ÄêXŠ ”Õ}*x§[0…q»oíÖš®+Ë¹Ÿõ$›éB„
 è&ÙXb¬k÷èçNSbßxgÍ†±õt¦Â/aìÉBö9zk+ğuKºê*™ì.ôü B¢†Ú`á‡$“YÿÜVÍe˜°1 ŒÑuh4.º†ô°o²A^ø6Ä]ÚbXn@¹Ô§‰özüQsÌŒÌWD†:ÚQí¤„jµ©p«êg;qZu:sCË/— uÄu¸4Y#(ÀMø@%µL‚èÀ"êMÛ5DyŞêÁÄĞ6-uxöx 8DE(¯rŞkhıçC§Ü]!©öRJ¢/Š-#ë‚†ı+òÜc]E™'L4ŒN·$³L²œ·£T€f»×ò©ÅÆ-şËÌânNî‰w±¥ÿ•9ã£0Wº tÖêìv{ÏõBÀé|ã…]ÎğcëxÁ;úì5ÿzA(ğÚA]s\ŒSÙ`8xM<íÃÛÁÅƒ/³fG]Ê*Ò'ØÇ)*®,=¸!åŒpÔ*d”£{ÍsTI=×ÆÃšû‡èîØ»İÁkÏ	o½Çoç…eË/¬®2õƒ‘j\ÀÂ½&úÍ³LVîİ÷G¤Ç¬†8ñF­èß S¥‚ùTVò›¨?R®’Gv‘9	Î¬¶~r¦©cWìBPG!Z¹
Œh‰ çHJ´œc“Rù^%·¿BaáßùË‡;—I¨
©
³B¼v”+e:¾–&…òhL€P„¤®ÃÊsİàvAĞ±1o›×¥;¢Ÿ™„Ğ,*7±L0`É·_
‚k¿ûY¯¡şÍ2‰®šÎ½ÈD_¼J9µ”ÛK¦êíà(¬Ã™YĞT—â<}Z	Ø’ÔÙmÄ9‰¦WOÔ$ı!—œô“¦/^I‘È]µ3ÉDÙ¾Xä‰+Ó­·Å¤@=ø7Ÿ-í&®Ï¶—Ë3aZnş³f#5T†¼.æCï˜Qè AÈÎ—ƒ:ámÙD¨¶hXäJøì(÷iu±¸9ò¦ğF8Aúpyñë ÖAb
ó¤k'ÔÒècNXÚ„sºó53'ú8BX=·bduDş)Z	qmöh] uñ0„”†i™ğ‹.? @Í2ÆüúÄãMmH/¢;Ş¯(ğŞ2­%Íê; Ôly ’B(cí‹1CpªHÃé`,32k[õË²’¡Ú×u-S"/MÏãø†›®#QdV8WÙNbè·°õ*¿"Êpæ¬î•Ø¹¦¥1‘“‹u}¯¾–³ı“vç9ƒğiüÀ_±ë:Ü¹„Ğ¥++(­’ Íïpâ4á+"ƒ ˜Ëx_ç—äş8-d»§¨=U^…CÉ[ïºC96EnÕF„şŒ¢9m…•æp/Sa_âÏ|æä5èTÆ·ñTÔÿN^$E+Ô(“£í°8	(?YO7ÑfêØ¼´üaƒ»bTılø¿7k6Z__%úN}¸FÑˆ^°'?œBu°´Õ}ÙÊj,2š– …¹Œi
xm]ºX³£%ÌMq\;»=@¥ôñ˜ªÎQVp#Sàf÷¥¹#@ç ùíşÍÂ‡´àQÑšìCvUåa5´`¤Èc_'©°…Ó
êzÁ³äÙËÂšÙÑî~ã†bc?ìµ½@d…Ô¤GG"’ß(×a§Çù1WÄqİÉñ€+ }`ø_áÍ¢	O—ı\ªåV¨ºØÑŞ”èÇ§F¯$Şw)SØ ù'nË¨†~·“ıE(¾Â¼—G±7,`Y½1ƒQšdN%Ÿ
øŸ<wVğ™=ƒĞ÷ôf”!hòyGè*)ºÚÑH©’²!&N Ñ$có
–%hJQá#rà|ğ©ŸAX˜|äâ.Ì@½ÉÓÌ–aÄ2şÿ|+ÍŒm#'ºŠ³¹™y™²¸«<_Ìo
ö½³µFTgN/N)7)m/.UGÇL»UÑ[E¶oMîZòh…,ëØè§»u°z¤aê_ÅÂŠIYô3ö7Äc9h<Åè“|1JoøpÕG^ÿ 4Kyióiğ‰]º»msø^ >ß4ßššiàøŠ”úŸ0¬‹+$R]qÑ`è\ÁÂLŒ|U°pVß‚
Ò
ßï{8¿»|‰:blœpòN*)z¤‚ô,unBbX…¢Ã
İÄfĞ-Y§¿.wöğÀƒ¸v”—èu'óM`Zó=qr(—íÈùK_<T|ZÖMğõ}ö\J¾ñ|òŸDÆGs³K´ÿÇÈ:¦˜c¡Ãi@âëÆÔçn4™1'=XÑ˜Âph†&¨SÍùÜ¡¼!js³Õ2\C‰I~F5ëà/ˆy&ãiÀlœSÑñ’œ$£×ÒSñxI[<7)ªÁ¡¸z" ¤ÜÖioõÚ•VÜú³ÔÔcßæóL9ôòà&u•èş‰'åj†ì‘%f¼½åˆS¾Öë	›‡³–ñÙ»şèê2‹h@‚2µjS™DKLæØŸCJª"\±ütp	¦~aÀĞ¦Ô°dŞxNp¡n³!yñÉ¸HYªç…€Î™Ó¨\äÙÃØÂê›øìq0Ô¡:Ê*$pk—«·Q†~š««CÀÂ¬r’ÖFØğÙ/îXštÂ9º¤§"ç‘6êCw½ H£ğZš/<¾h .¿G%tVVÖğ—±ı…gŸ7¯ó6Ró®ãËî²º‡ÎQ¿òM³4g!zæMG8ÉğôŠ™vÁu@õ	¡s….Y¡v[¥®V¿Z­¿ëƒûÆŒ²™]ĞŠ	sloŞKúú5Š÷‘¨÷øñÑ­0ˆˆ?swŸR‚q‹®kbt6ßTL`l†i0üæF5€ıZX{‚Š°€ˆTšòÌ‚ÖG<^V;»²ªêÂÁ¥BÆ¾HªNı†YıµåëvWéJ·àÆâ:ËË“³€·ÀÂL UmjĞ{ä	èKÙPë%İ’q†0Ÿ§9U:ÏeDæš#)x„ÀÑ80iğ¹·áZĞ:Ó¦Üâ³HŠÃ'ñ‰¯Y‡¹¯H¹ÍcÒâ8¤äæ¿‡†};O¬ãdVQÊáiJ<K”6óĞX>l'ÄCìwI(}KÓª&Úéqm£×Ü^™şĞâ[I 0à`CC`"mûMâºadg“òÂŞ!Ãfûú[…Ó†ºïj²/¥YèaW"Œjé13?˜3Cfh$À—KÒ3v'Oz8I°è!dÇ`Ô_B¦UE€õÏ–FİfÓÖ>SÃ
K¼™é‰{Zóá
l¢ˆ5 —“…7ôJ°®Ó<×œ(â~ÁBÎFhUñ?*…4iN–È·»¹Y²c­ğK Ø”rŞ”¹g†LEìª¦ĞÙ¦øøà’g¢ØÅ9$cöĞ ¦jÃ¸c¹PwÑØç"¹çşfÒèV¥EŒá —ãƒ€ÄÌ§®¡¸¾of˜Ê0ß_E€Ïü%Åûè0ëë® ç$Y±hòçcãÙ±Am¯GôğíË~µÜHë ?@\C£Lßá‘Ñ´h£:Ş¯w'¡vGP?³¤[öß²­Éz*?yuŞæè²—r/s‘œ¥,)QN¹¡hW¥Á”ùöhˆU°¨ÿô9Í7#œ«Ï¢V|Îğej£ÅÁ{Ûfo«š—"Ù^ÆK¹ú/¡)z¡öİÏ–›'5JiØ¬ „fë»®¾d”ìİÆõLÆ‡o™ò¶–Ruİy3îñÉmË}ú>
PF Yósz[
VÖíO{‡—è{›çRœE¨ûD™*zÚ{öÒ)Şw¥¡2îDÿ»wlG}<"{¢+X™Ÿ’@4Äê’aSŞeÕŒöe¯xÒ÷´u¦{ê&{’m&Ú È¯´m£‡ºeõ
+
Vn„á¤mâÈH©' †	É5P¤”Ìf¿ãPJŠ:@*x¾4RğÇÓ™[í¨œôÓçn©Á¢ÜÃŸñC²ŞÈbÅŸT`/“Ûÿşó”\òÂùC½dÎ ˜)GÜıFÆ0JÏÑ6 Eˆ¿ÒÔn1Ù½Ú¥ĞSy —4³ÿ.êâ"Ş{ö³Õ0šFuVqÙƒ ´a]‰‡+”—ŸÄĞ2p£M™ÕÆÇã>ñ:'¿™ì}üÆ:s£Ìæ%1DÈHÿ#M|Ú ï•¢Ü®NĞå5Sgæ&Æ-†íŞÅ.¹ÛÎã¯eïm‘ÿëìu½TÜ>v6~îÃŸï—ÊBt'*RW¹,Äf”»¢l}?%‚q¨°“tm;ÓEÁË¸©V	ÉOÍv¼R³wôAIc;º¥=I F=tÀÕ#{§ãpó©ßìñ÷ÈŞ¥»Ì‚œ¼”“TvĞìú’œwÑ"¤ëÎ²„™ÙJö9-ğ>}ÌŠ2úÙôÒ¬É¥`’¯T^»ØÜL»½šÿ÷ö5ç÷1€è‘Îõ›Md7Úşh3ãïFinX£A~ÙŠùÍ¤ŞTB‚ŒãúUzô­Wuğ sRmÒøŠ¤’~7£‘‰–™çÇ]gyÖrş¢Á›ehwPU [•¿ÑÜş¬»ÄDÙCç&H2p_‡.iPæ× :))(ë¦3hßìlû	•dT·-Ö±èõòÆx]ÇĞ@F,É!00~Å•¥Læ%Ù †ëì°Ó³ò8Ğ¿TR w ¯d´ƒø(»QÊÂx&¦PÙn‚CÁÏ„¢„"²4PúÒñÍ8–yã€*ÍŞoÿY~%–;*tx¤—¼^ZÌä¨¤ö`øœ´>“ŞWİ»ti£sÓ«Ö}âNhä­^¤×¡YÌ‚¹Qˆ8/Ê-ÇA0Ó317GÓ^YÌs{†f_‡ˆüM¾øùÃfİÇA‡õro[”×	AÕÅŠJf]Œ3½H~ü‚·‹8ÿ
ØJaV1O+ä»½]´³ÜAî¨}¹+ ¶E^rÂbìF<"}B¡úÖÓ0si£ÄsEç©«Éó5Üşïuå©Æªò(fQÉ6[ñÌÕ²ø(¯Ş£1'ã)aè.4˜7{\SïM~Ò¦„–92Œ õ
\Ô@çá5	èí|éH–X@ç]>·3ª^ß=l¶shçÁ}ÌœUêÖ†ıBŠ>ìŒ»§ˆíÀ¯Ş ’ìÍ~£Kr¼ÿ	H'ŞH¢,Çg|)®·1+j±…•\tÖqÃSRıhB÷Cê’©+ÈåÔ•çù‘µ×{I®D/2ÀŒº’0o•¨¿¬ÑT¼„¸ ÄwîP÷+¿^ãq[ûSSÊ= ¾ Œƒe€7:Íx“ô:çjÜ9‡n_âîh_Âò4˜%%¡KA 3zÙIA—ÁBún'±_Õ¦ñõÀ9Yè¼¤¤eLlçˆzº[HÔgÒ~Í@ôã¹“ƒ´†ÚW¥cÏôƒç¼Ïx]fœæ„y½×xÑT®0°Å4÷s¼¶Ày@ øò­
q¿,ñ³¼lDl»ÏÉ–Òã 'ğìFwYJõv³$š-ì5%TfSã‰xSİMã„×EIˆuB¥' G»××úâÊú£-wM¨G<æ´!PoÛ~ QfrW]2¤,Yºu¦Ù€a)ĞçQ8fDb.¼ö$U˜ºl—Lˆf†N[xÿòY¶"@"sß÷Äı8·_áÁ|dj×wúI3Ã7–ä‹'	€Ø‘ô‘¡!¢" øçê¬ùßûª:K6¶¶¬_¡‡@G}”1c5ÑV
]“"»¡ZLkåáD‚»Ï˜x!Âø³î¶üš_€Ör?åUÅ¬y?şt2á†5|áÃÕßZ®g#?K(â`oşœnÅ˜`à²ÒÌä0]Ê¬Nò™'\êÁ %ô
§Ãô¯ÙÆ¿ò¯	†+nÜHªc\ÛÕÏû­¢ª›„¯}t6›ò9)GZÎ…Ñ!ñ!×ıDˆÅØÈ¾Ê_·‚Ïôêj(ÆÅS­ÆJ²ë rC-Š<p(¢Œ~jÁKyáB T^ÔŞ#î#ŒU?]NC°¸MEg°˜ MŠÇ-¦z³«‚kSeBöŸY=îO±ƒ›mµ„e§G¥ñö_&2B£}R”ˆ¨J-"+š‡ˆ&ê/İÖ)‡ök5<tØiF~v-À¬J‹zİö;5â–ŒD<Šm¿VWGMyœ™A’U •u
w‡Ùd„Œ-¬b
F?ü„ßäÊ ÷5ÂèZùDƒ+Vr/o±ò	æÿ6m©ùSEüß?ìn6=‰e/Å•Ô7$€‚*ŞGœ%ÀÙTRƒ^k¼&o—îËÁ¨Rù2$ğ7.<ÎÆŒ·Ğ»Öó©İoËö4J)<,Áòî7öÀ¥Á"_zãbWAÑæÚç@?_*é2­‰‚iÔ„Á@Ş­PºÂıëÂma	lOR0¥Jõ_•v™àœ/}öH-‘2PŞÑS.QÆ
5%è?°#ÎÍ\^qQ™º
’+ñ"IÌ³‰$áîµŸ&ßMN£ÙÂJhw•€qŠà¿¶:=5@?¬"ómşX­ŸØ¯¡òìFVº¤Â£ùY.²e¾™hÕ˜xá£§Bø–¬4P/øûJ™¼
¢m™º‚+Ü¸w˜•§½BNë«`ÿñ ÿVÇŞ¼S:+~¿A"NvkÏK¶×ó1|.Eø~®[¾À”Z¶\{À24ÄŞmÚB¹?«fc1E£ k·ÙOÓ]}«ÍÛ "<³§j&âıÍj0cO˜;æĞ…^JQ‡D­­_Òüµ˜
§Œ&¦²ÈŠÇnÆ¨ÁÑú´FÂv@8¯Ï¤îÉ¶’Á°µQVÍ¡=}\]j¼‡a!FNÌÚÜ»Hù‰èyôö?‘B
…9Å (lAş6•^Íd–XøãsV[ô…0¨ª¶bÆA*`)¼a²Ö«â¨J:êiÃJ—;·œ®‹ìŸQê`øià"`–úJ^íğ
„ø¥[L…‰RE:[UïÓP–/Q*<OÛ'NÂ!cY•T1hnèÇ‰§R`Q…š.cÈ1­€ÎƒøÙ¿ ¾="¸÷ÊÃ1˜)ÂKéÏá¬ÈS¦ÆÎ7n/T«Ã†»˜å¡xúJ,9áºÂ†º“€\›>1³§Iëöê´´ªZºús…-„ï,v®ãï°Âî¤ÁéĞşÌ2öu1YUX!ª=§Ù Yêù)Ïx“äkÁˆå;â**áx}©£<ËiÇÛYg@%0·ú”(a´«Ù×TÒTÊœÁ}–v‰OÃpÊMyŠjÔÔi½Ëï{Œ‰0T+¤|ÀÌ›å|Ø>½dkøh©¸= “/®7J¬9WÛëfìyİµ™bF.	/œLÅíÏõ_Îäs…¹kCSù}÷±-éKfÔ#,îê<"î›Ló 
\Ê8iK`Šäc³AgD	}y ¾ÿÏ‹«'&ˆšU¢Å‰\ª¥ÉhdÑQÅ±Ì\&šg’›ò{‰¢ÓSŞœ24S;äw~óïÈj°#£¤,¡ìîîÆÎá<³”·ÛPÍ\aŸ2k]‡¼Òuo…Dm¹Š°r†Œš¼ŞxBú±™ÚQA1¢•{ZqZÛZd4‚–´î=.ã¼ü4*·}
«şOù°îûæ_'HöÈîn4ºæ;7Iîì4ÎVèÉí;fîÂÈMh“FŠé·İ5ƒ]f+Ê…¡(¦“ùêÓœÎ|rõGÏà(V¡n—.ìÊ ëÚ İ³%ãÈ‰$OÙ83Ç{\æ®&¨7Z²×^©€w|'° –¢üàYªK[O ú÷˜œÉ.r“kT³à ùt)åXÃHKÒ%•qÔ{	¨a1ıàşÆ‚
&É@$Ü
5ÕÄZ«G-õz;…îXÒ¡oáãMxšÉ€cu¡šÈ^…)—!µI[Á¿áÈ¾İ•ªdTì)£+¹T1§ŞßËÂZ[w”UKñJœùLœ1Sî¶ÌŒ|Ô
Ie}îĞTĞÀç[¿?“ 0ŞÔ¦röG
í*Ë˜'8r‚>åw{1U¼Ö"4VĞuò¦xÄ¢`®¿Ñ ²ŸO	8˜Ç?„5_îV=N_OI¹RÜë3=Õİ¦›¡mdóD&²Ğ¼éÛˆ1¢<‹0Ôˆ°¿IŠ> šUÑc&U÷Ìœ|jd/÷%›%ùœ"Š²9qÒSsÆô635âNÃcSÖÖ†kˆù/ËÛ&ä…/Ÿ&•m²€ùÿ›¾¸à5À„z¢Äe8¨9÷Í<ç´.Ã¹ÄË{·ÿş€qøY	´Pµì;¢­Îİ´û”oÜcœx®k˜ØX¼š-O€×Izq½*¨–f\‰Ì«qÙâ	0¬v-ùD[ÜSç|Q<>`RSçyá>4>‰†±†¡[ÊÛÑØ(ç"Ì§MHø?D¸ƒç¡¤nM5f “o>RÇ·ê¯¾ƒD”€lPQÇ¾ö¹ÊÅ*|×ÒOwˆY’;e2Éš$ *>hİ
ZÍoî*h‚DŒpòõ„\Eõè!	ç©kH_uÓD %m,¡W=DI-ÉÏôÏ¶v/\Â©‡¾Ó|&ûTTRĞ®K~–H¡kn‡{¨{¿fÚÏ;})c„ÑÊZÌ>‘[ØC
>‰!ÀW}»ƒíÿ36­Va˜ˆŸN±YÅø§‰z•ÃÿšS¶õ2Rƒšg“q;‰QÊq7j’S"¾9g#¸ûóM·œt°šö ŞAÂöÜñ(ÑÈ}Voõ†¾xççıÓbd¸:v
=Ï=V7KcÔÇó÷"[Ö$ëf¡K5GˆMœò•m•T|
ç˜İ[ ¿âS7±© İ'Ü•#OJ­¡Úm¿Wq­Óh*!+—àDZAÍïKâÏ)#ĞÃ,Õ»yDï[Œ/é“×jêkX†"+ù®Çöiš@evó>É~Ö?„¾øò´Õ­&¢
Ûï|iàV¶Ü£Ë òe¤¥ŠM¸KüŸÇ½ºv™_ÛS)ŠpNºÈ÷‚Â]^tİÖc5s^[zÆ°2•]Ûà˜(Êşæ~¾DeãdH¤~ç½¹q•çFy)`+U^öŞ­Z7Õ«Öƒ^	€àü«ù‰c™‹=ÀV±ëd2Ë@o+…ÂU1wº<˜Îz<³÷:zĞXæ¸À»×ÇÜÀ—wa¿0æM{âDt]ÃàŒªhÙ§Ë48$XŞºeÇÃkLä$¶|5~ÚK>½VÎß¡K#ãÈ1 ~d'àù»úÇ lF r±Å¤OÆøÓÍmyY4‡sE÷c–R¡‰?G¾ÛÙTP§â†áÌ¥ğt·î•Ô¢OÈe¼¦ÅnÓ»õ[(É§tÏ<Ü"£ÀÙ*¨_5z9k?ĞãÈ–öËÆ»ÆoÆÇŞOæu:±Zw~ıŒ¨¸¹ìŸ_ß˜Ã(zAYÄ›Ë¬Ÿé6qmU—ÉˆïÉv‡F6®ò2ÑiîÄNPñºÊ!°Ñıì-".’{6ÓUàm¿1\Øöl ]â³‘Û0cÛ¥Ï¤
qYº²×:—<èä—Hs©4ÒËGÄÑæ'QN´ÊŠ3+?S<ŞPÕK)–  Ä=5 €ç±ÑŠùÇ),këùÕ:"ûŸ÷Å‰i•áºü_dÜÔA©¢şFj°iLÏ°§¼±è¯³A:K®Å½nRµíş—Ğ‹}WpĞİ8ÉüŸÛ Ì^¢Ø¶Å¯šÙƒc¸ç¯¤÷ÖZ&ìpUäíÙŸÁgò\ˆ
¶ñş,ašˆUE¶ó_jûî†ûJÏBa:ppXÃ}C
D¢ş*”ÿ–ã	Ybs‰Õ˜Ü. –Ú­«#½.F@\im¾`™¦'Ó‚â#;ø=jÄ„¹aöAîøïN®xè!ßkÆËÅ“ÎCoqµÏ `8 ÖrN·ˆ.³ R›û*"İ¢¼°-œ3-²à°hşôá°ùØ¤×ı-~uê‹B8À7#J2İ‰ùcÊD‚yÁåP=Ò®¿0xì(\}Wuø“¡ï)$#äŸ½qGnmÇºT@äX,7õ—ÊZÇJ«cş·“20Ô}?IIT•+Á	 8¨W¶ôÁ{êp£ë-vÅŸnøL ?¶xÿüÀBòF@<ÖL·{Ôx:½Xßˆò¼q”.€Â¨‰K,Åä(örHã¦P^Á*q¯İ—‚îÆ§1;ö*#`±B‘û¼îú›Ë¯UÂ}ÚÎN†{ÆúF¦ég$ ±…L@Å@/ÏDæ(RZÛÆO¹Œ;k &õk»ãH‹¼bdµL¾U’i©÷|LkQ"ğ³eÓW b÷µÆ`5±é”K¥Ë\4½ˆ)"\—È?µíî‘š2Ø>²æ1û”{M?šx‚Ÿ¯ö,Ví[À®:Œxxï?iâhúT}Ë–õª…'jÇ*‡Úp1ÆI·$;–Õ^±Ö‘ûLá{ß°ÓÊMù‹c»·s¢W„xï~>Qv_Ÿèº°ÓW£¾Ê›œä±ĞxÜIW«¿9zÊE¥vB3_¬G¹á­ÄÕîœŒÈ_…`øÂÉ˜ÚÄÊV·¿so˜T^$"Æa·ysu-ùşLBó©‚xxKê;×Ät¥ÿuà›|h-Š\‘˜vUÚîÓ0öU«3ËüYg’2õ‘÷-ø³ş]‹Jå¨^ç™^µ€¹0Oƒh«ìnuò&õr@»ç¢¿%}ñW<_3}ÈcZTõcƒv°fŠıÒ‡Ç	9p¶Å==İ?‹„Â(ÔĞò#kıŸÈ)FRM÷oÅ‚R°"œAh”Õ_ÒÜİ”ä,É9±TªÜé¯YÊEùÖÀaçÅDŞc‡š¢z'–Â{iSEeî¥dÜòş‘“
S)÷'¼õ<ôa2_ø&%å‡—–ãÆ€°PÁ3ò–Pˆ­Èé^±v©ŒûÏÏ ğ:rùÕô?ş„¶3®VaÏøU³ª!Íœ¿GaEr¿®!ØìN_¬¤ê¿H9y’!vº6ZsRŸş_‘8öls&
z@‚kìk)…nğA±«>äáğ"Î1ŞtJ"Ñ¡´Ûº®L1»ŠŒò½9¬ŒgwvE’IrVfaZèªBĞìv1D3ß	æ^‘Ûı
¼/Ş[ó¡†GËÅ‹ú[ÊƒÂš5Qô°ï´tJi’éúfº’Gè4²r›µí³ğ£´"µ„º-“kzÖ&Ã*æ¯SAíú\»Ü2’fsç©l)AUrH;u’`5ÛÎè07õÒ›¾Q,˜á«ï>×“ÇƒëÂû"²ÁÍœ(Û\„İìQ·ËBÇjt·h8M_\lÖº³gE?ÔXÔpgİİ‡¨vó[¿Îµ+î«WSğ…MèøüË™@½*Õ]» ú¸µ+¸uKLC’@@yÃËl bPG¢>ªí±)¨x+hÔ÷¯¶³×Ê]Ö364ğ*;Æê¦3šs*ÜØÂP¨ÏĞu¶Mr<.ÙŞé¡†}P£W‚…¢PA¦‡öUÉ„“Ï›SÁpU|-Èé{òşí2TrD¤¥ 
ß›Æö¨Ùiok•dÛ;¢4@—Ï…§V‡^ \(œÇÚ:ÇüY‡³ÆTÓTÚĞÆÕÆ°e–[A( ƒ%Šÿ•]„}FØ0œ0P9Â:¦GáöÊ‰æ*½ÓrüÀ1¸¨Á«G,EÃ€aà ìO‘ûñ%½É¶ÂÄÃ<;ø:5:¯Xfìü'ôeh?¢Úx)ï÷Î€`cc:ˆ\˜€F“íÇÀøôË/'á$ÉKñLwÊZ‰‹Š;4Àg;å²Æmæìk /C ¾d0Ã³„_% b¨/O5ğt™GÇ+]·¯Bøı}36/ğÏI!f¦†¥MıœÀÆÓÏtèqö§_4O	`†²ãJœšMšª)!ù·ÕúR0ÀzIœf	t4ŠuW²Nyb(Õ½âŞş¯Ì š^ ¤kKö¦âwP÷9ÜÙsııÃèßXzÿ†Ñ‹é0…ÿe©ôÅÏ@5±=Â¤­”Ñ˜Œû¾"VÒŠÚRxÏ¼á•Åöíú9Œ+§’TÓ
>wÿ!½¢P€Lû°–¶+MD_»íp„åÙÚ!I¿u½ò¶Œ4•WşåèA&&>e ÊïF5Ü?"[2ÖêK¶İû’¹ïsd=¥[—œ±Âëw"}[\0•UytkPÀµbPÅÅø÷•`7À`+NMı™Ã0ôn1ÉaÏò}¸HÔl¡œkÃæñ½/‘'l²HñNõóÙ9Lğ°ÿ1rßjì‘{]n<=]ûZ~÷;gˆ‹¾¨
 ñd‡YâÇb7¡h¶ÌÆ¯úo½Ü­»-Ó)¶%¢sÊ$ İ'3k€×ÈNˆÎOõ$JÇâÈHıi÷—˜ä/(Ú«åÎ
¨İÅ	‘fûøû¬Oc[jÆ¼ÇO5]”«ÏhT v%Ñç’óÄ`“ûóeÉÙò$voåüŠcŒ«ÁSvõÔ¦ÙQÓCĞ¨lCC	æƒê“cJüfM(tÎ’ü¿S²V…vÂ(AÉ…€Ş÷¢©|äM/œ4/¯hTØ¯·Ş„Î\0Åâ‰ûU@ˆrcSöğJğ”@&‚ƒˆıÍÙ¹Í˜j•U£E@Š_`¨÷IVÃ·cõƒ|°áYCKIêŠK¹ öğSŸğA}NU³]’q6µ4Óò!Šè:ÅÓÅJ!©SğœêÁë„UğĞS€8Ò½š4GèÇ£Ö›Áy|ùéeíÅ½*ìŒQÚ~¾³½0Q¡µ˜‡ µÙUµUÚwóØŒü—é*ğˆ{Ç¼‡u¥RkC›qİÚ\¥i¾Şıó¼4Îìİ]Ãi9”~+U™Tşóˆ„Îø±éÏKyğøw‚u@í+±ó…ÑEy·R9úÙ¾KSÜLcÀ¿…êq©¼«2ã…iO¤Ó@ÂòeãËT«ù{sÈò’M7Ï0Eõ|/‹+\/3hğ47óá:V:I~ zá5 ©ª¿w9{?Û6<Ô³Ûh)A¤^€b»Ÿ¾­ŒhêšT±×è.è8ÉUH?ãås*‘Çt®<Âj¬ıÜó‘VŠ~`MÎÙháxÍ°Êêº ÓÍê"ÔDŠú

íÎÙjHÔzbwŸ(KY¸›E&¹.„\ş/}<Mej¸-± ±ZA®BAÑë„tmç„wk…J¹¡.EUøšHBNobÏ¶Za]n-Ûc;™Úd—AûŸ“M5+Şö‡n…B;İSÁVúiîH²f#¢Œmê¨9ëFŸ—ŞÃ'#ë^Ì¸¹ªLÂN*	º$ü×Ÿ6ÓYp»ÆÅµÅ5BOİïœ°{Í!ÂõÁßúxª0İœ%¥X†tlåÁO­%|³Øì…Ğ+š·”vc†*Ï†#›GV\®˜îÃË’jõ{ÒeV‰ÄôRz :€‚OƒôÜ®™Û\	ûF'­á ğ÷à@¹
ı2eG?1¢&S.G@™0O>Æ{ñ"¡l/"¹7~];6ï†M3y*M‡5s­»8H‡ig†ˆš2¹& ,®nÿ tA	Æ’0àëŒØñòá³g!hoAåîS«—İaÀwXsôßø$ëQjÏÀZğÜÔìàê  Ù)‘kÉI÷KŸ™8yéÁHëËKQî“AèXO˜sØêGú%Úÿ»ÍQI©›„W7M³|WLc"o^¤Uf€½ÚâæÙ–aÔ‘´{–JŸÀü‹!o;t =#…¹&¾â»ØÅNyŸR¡Í¶(ŠúÙÁ!å‘ş2ñ¸—+6C¼;€1Cşf6ÕÍC¿ˆàÃ”ÓîZwyrÿ/ù-Õ^±N áN¯¢c?x«Ä]’#ËšN¼ yn­Œƒ~¢m9“³7YäÏ§x7ïŞÂ<ü5°*½A´uOP°·`=û 	ædy‚3ÎvæTØá¬ÅÌñªÎ”|<YôóîDÌ÷»‰>Æ
×Cà˜³ÖèŠ;¬Nò=øa^N<¢ª§†!(â–H¨‹x@'9¿|İÃêy"ùÉ>¶`øêrÆy‹®ú-F¿´¬gNœÆC]9İrZÁt„ıg£û(ïš¼‡TÈB^İÔç›Œ­§-b>V&ÓlË©<È’¿/$İaƒX:{Ò½‡ö-¼/lÂ8½öC2K³Î°LÏÊî¡¶óıï“¨
#<|û^»{ë°ËÿëÓÂÑıDòğ¶‡û/7æ›ª<ñB“0ÚÜBÂ!ó± Çº2cãœ™Tÿ{b»±Ì0ÎF2!³–E%yˆ°<1Í²Tƒ­»Æ|ßŠ¿s­£å“+ÁGZ‚°f²’ÿ³U(ˆsÁ½æ´iì°á»;¡'àŞòÿÆ€*õä™-uˆx'F®™@‡‡…şFÚ½À{Š¶õÊ:5j218DÆ¶ rµ6R¦r|xPÇå„‡4½bÉtêb‹¢ãjd(R*%¡†_\íÃô™ÃÅìSõíTB²‚“I8‰í«×Ñ™X n6½™Q¨öwV„ÌŒauqÂ¿DşQ|-¹x°É’bax‹Ömì4RfC,#-çD5İ8Ë•ÏAšºĞ¨‡n!éwºñZQÔ>¢ó¢©P¦ìõK¢¾Úâ ]<ÎÏòM:/P¼Òqí»âÛØ¡+5”’’º8Oîhó¡Cû‡k8$åÿk/z§ ÃXòÚSNŸ–ˆ¼šbS…®¹TlúÂ4š‚˜¥·Åæû†íê¯+£Ñn2k=|_Ä™êğe 1{Ó¾Ae‡¬¬™Àôe_uD!çõı±½vk.Vøãtk>6â-‘Âx•ÁùÍãu‚#–I"ˆ<úXÙÏ  åØ>õÔ
¼âò­Şí¯C”oV`¼1C“ |K¨ŠòÄŞxıïÍÛ5ÃüMÓ2i­B7‰ræœµÑ+up	º‰š…oÖA¢İ2±æi/ÏAÃÍõè!¹3Jc03¬¿ñ°ñaÓôŠÑÌê|À1?>g ¨õ¤›Ş*¦k‹÷¯f‰*)
8W–äÒY%`œÂ&¯&©²êË^ñ0'Ë!Ã}¹pƒû_wVÈU.İlïP€lÎOMy)„‹4+nÖQ½Bå|ÿÄ)&ué~!^ƒËõ [òªLRÅÍ@Ô[Mİ`êUUH¥–„ŸÏÉfïî÷26µ4ÜN2€[
BïàrÅ–eëV_Äåï6ÿZV‚vK¶ñp¸p9‡ò,«^¦³¹=K&tBœ½Uìù­šü!¤÷±h#L^_Æé ‰M@k€äµ^Ï°ékğêÄĞ"“G}ÌÅoûânÃ$êÉñ£´?>»‘Ç{†¤Nu*4±1¹ŠÓM¶›Ÿ˜Íº¤TPï|‰27MˆÃ«(İBr±R0§iËÌPY_ĞÌÑãkû¶Áwı˜«vçMğRn;°Ó2h[I‰¹î¾½úÿ ŸäˆÒYİ"3á)ÏÿökKŸ	'Õ ›Øoó© âˆ/òğ×
l«¯t¸„W‰\>š¢ª^Ï»5\5LúJ6èÿ¬Ö1[Ê!~¬Õ+ä)æ ”!M‹e]	~<ş.bø6‡sæ8z½	¯#DÛõ#Uz ½Mk¹×1,zXØ•›ÃÛ„š‰işe5şHxb¹QNg=$?­$"×÷(`%ÊOÌóßmê!w¹¡óo¥ƒ—|Tömª¡j°“0ÿ¶mË|åÅ`¯–0…ò¦¹í =êã•ø(LmÓçÃH×.¶ƒìLâ-S!@D—lÙşTrFù[hÈ#‚;Á¹RÒÖ ~4Ğ€úîc†vÈ{ÒtÄ>3†×ğ™RÿE÷JWXVCÓÀrÑ{··á½»3>c-TÓ%Y*;ÄÓîs(Rªãô
±•‡a|¾Ñí*û~ /zrnÜR4é¬s‡Ğ™Z ä0İÖW%B¶Q¦æ-@Úµ}¿˜a·­X9åàÎªÓXyšJ…àti˜qX˜.jŞ’RóOà™ò½Í²‹°ïË1Fï$ Òü?y™ì—ş[3K—ˆÇ.Fê©ãˆb%ÊI~‡ı 2.,C¿¶µk3Ôe½b†LèJ‹”iºUƒ¶tùH÷‡úlŠïuÓyznªÙç$2laÊ£7>Òm” ³Úñ5……|™róPÿFdc
ô­gÅQ‡»s"5å_âZ`éqhA3f‘X`ÿ¼’D­y?^ó^Zàú‡@B¾{Á2ÙŒ»	»E3£?”“…Œ¶éÅ·šVÅ”ë	¥ê°Ÿ®AÅ+0mù³<ÿøWî¥j¤Ö=ÖT'ä*?@O…s©ÙTæU_;®YcJğƒ£o¾×jäˆ`îÃ+ØŒq±¸(.0–¦E	„Z†Š[˜vU	 ™ıäŞHÔfdYbëÍBhnZPt6?À"&İ¢w2! ¿t$µë“Zï Ş§!Åº¦gA €­Ó[Ô™#©¶P)Ô‚€¤É»,WÅÇT-+åÀÙË@Î™“:Ö¬şªö%¡Uø}
:bo&ˆŠ5>•Xdtb¸ğ¨›]úø$0äB¾$wÒvø–~7W@ıtçv^xãB[Ùé¡ÕØqÑì¶ ğ/±MS€'—¯8Ã™ ?‹®Ë¸x•
.—®ÛL;ä}Ÿî@íä¸Ïò2!!eæƒİçcÂ¡+V~¿|Nï½nÁ$˜Œê	,zaw¹áøì®ò°>X“Ç5OF/MÄĞŸ™3ªß°–|¶ba/Ñ{¥Âã»éÎ²›)èŞ5’!BÖå’ù#Ó7(‹9§íA„i
7;§ÏÍĞ)R#aB‘ãÃ]¤/eĞ5 !ìF`.|\»¿µ{ÑÎßïôc)ÓåmiàJş9€a¤#È’ÕI«,pÜ%¥)™´[v¿Ú¡+™„ Æ/slŒÕ˜“ÊF‹yìLÑÁÍĞ}Ô7¡ÿBÀ[5tÖøM¢²¼õ¹Çsqßc§éÑ8ëPŸ&±à“ğ–ìç‹{µ–rhº#îXÁÿ§å”oÓiæ†×õb†kˆŒ\Wì«£¨EZKt&’ÉØ>!Nç®T’‘xı>odW‰–¯†(fû"lÓx=İ·OrèºÀ%Ç’´gsH¤Xë:Šcíë2ÔôJ‹M!5ÆşXÆëÌnN^7ÊEOœÃÇ&à¤WCsOÀ4jNiªz‚·TWuò.¿üí’Ê_ú;›ãŠ7“Ùä%¹«]kµàm¬â•éâ› éÓı †«ƒÌm½[’İ’ J5·(åù$>Ëvç–jª”àå/ÕJ»µÙHãÔS,rrUƒ¬£qšê³¶¦ßxIÛC‚‰¡Ø«¯…–píëwp^õ]ÿ†¡!%Õ§Ò(luOĞÖÃåf]ı³6ô´‡·²Şfí–»˜qš76…*õl??€5|l8bûähĞÈK0{ «îæîv#Ê‰&ÙÊ ½š²×EîJv<@=mFòO†ş3¸Ô¯²Ò—=ã`ş‚mÄ±ÿA@ôh^«ŸUX"G¢ˆ"¯€œfà¹
w—mUÊP'x9|¨AFzùË]Q˜ ©gİ,Õ²Ï?•¨9ù sÊ×­x­¾mñ"ü-ş„ĞÏ@Á¶Ú’ÎPIöƒ{ñd„ØiNÌÊ*ğÅFqaljˆğÄ	÷SnâoFyº‡\ÃoêØ@ëdÛ Õ†émÙ#–¸cò§$ Ô"mwFjÒo¦Ñ@Ÿã/±EB‚·#×´}Î¦4l;DXÿ(Î	‹ ŸBpx1·0ÚişÑ¦]5€ßKÎéB3¬š4ÂÍ#<áWDğvæ °ÒÀ!.Ù34\_ŒkD÷À½3ˆkËOuYµ‰±cò  OpÌ½ÈâO•å¤     –Dq\§È ¡€ ŞêÎa±Ägû    YZ