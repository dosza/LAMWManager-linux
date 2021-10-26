#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="993543281"
MD5="de3549114b710cc3aa1ae11a3c4bbb3b"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="24184"
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
	echo Date of packaging: Tue Oct 26 00:06:51 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ^7] ¼}•À1Dd]‡Á›PætİDõ¿R[åÇ^,ã²äjÖp´çã’‰FuşØH²µ±W3SÛ—ªßÔ]ª‹÷«ñè­/ óüB5\ÇîÊÊ0XF.1¤÷º@:ğõœÒ}¹ó	×è›Şõm­ïË8h¨•zåêI”I@lµæT3¶–‚ÀhDføRdşåÎ£²R*vöQcRúyó†Tß÷Õ>IÕQ ô!òÃ†ÚÁ4ªÆ7„’ÿEwpB<È[f€¨ì~Ù‹M§Î‡ê¦^É¸[Ä¯UM¶‚p¡'ö<Ş±¶‘¼Ì¿|Œ0¸Ût\F&#ŠRçºùÍ]@Îu“`ªáÅ–lwâ†Ç9=nô°5C-ÒWé€2ö‚5ÄP†ÄÙ@Úğo«÷Ä±¼ÒÒzÎôšO}i›I™%å}nJ>Ó£d¢i:^Úª˜è0äãWZ'ëÔXyõİí×ÕŸYâHów¥U€±Şj¹Ñ¶X:¶aÄyš*¨GvØİa \İÏ»Gn àÄYF8ôE¾[–·Yx'+¼C[° íûSç]Tn¨èqF\]YÅÏÂŸèûşÎ"Pòı˜[ŒLjgî>Ù|JdŒQÌÒ\4ÿìT?R¥ŞX@(	dà–9İz^E2~y°¡GÌ°Êôàğ™S*†µ=„Ä¬ÍxoJ·¡+Ñ/@JW?%&îpfË4¥—×O#;Íz…±Z°Ë!_$èÎ<ğúÙÊê•Áº“íÍ…0í,}¤`ºK…¯
KùQÀß{J[®»¶ºÙéÇbÇ.ów|¥ş3Ô—åBr!ª@b&ÙŞEÇ½7	/+Ñ‰q(^Ÿ*ş“’A
w_RZ ¬Ğñça&Z‹4<Œ,m…
}£ş±‡©O~Îmu ­z½‡×C¬\ŠöÉ¼nÙz‰ÏyÆæG²ê¸ôÔ3ÃqõYhBjU‡¬‹œ·¤¬É¢Ñ‰vªÂ[PTnûjM¤Å”<Lu_¢éM§ìôÊG—¶3±¥…1Ôòª¯„fgÅe±7İYêoê¶‚Äuo¸<r×Ó××>AI×
cl*ì
>[-Ûñ÷¤ãQ1€•@ïN,º62¿ı¸‘Õ˜a~'ø AGü¸¢µÕÁœîÈ%ÚştÑ=WˆDÃU+ñ7ëÁ8ã.£~«ûğ"u§§é¡ZK°Ù¼ÙÍšÁ$À„=„w“B·]ûÚÃ¥<"`GŞœ$#'¶wo^=ii¢™¡JÍ©•D}’b›èÇœá>•PÆ¼`hàs$•áÕTÜŸãag¥ÿ~Ä­Ï*jb»¹±chf.©?Ù™•u]ML„vD\¨Ç‚Àõ†lmç"¥Ş8wæ¤6HC€‚¥Àl©x%÷ş²¤G}Yz²,ù±GZaW.Ô&
Hå¥‘ÅM»ScB:Hwb Í3Ş¤lì„S$QI”ò¾Ÿùû¤„µ;F×˜â—
^^–-°¶4ó×ÖWƒŒ$ Wóô%K]¾Ö*çGQ{˜N°FÀøÌ†KW4¨h
z°ßQ¯„‹òÃ‹˜y,=äqÍú:fû
Új(À|ÈˆFîåŸ£5¾ÿ“™Ï1,„ºŠãæm5z®İc3`ÿŒ¨h-iµì¾· ÍşÂ3A0äeL‰QvxØJÈ?ì¥4”ˆÅç;5+Fsê}*D¥L•ìGÖ‚:XPğ…È¢mr’Õa”nô®ıV§ºËb MJÙò^‰ˆÙu¥<1[ï¯äáy°—îàBPÂ0­²ÛwháĞP?‚g‘L=5ØJKş´‰äRw&¢0*©!·‹tñ7*g‘Ó‰×`¨DnM+"_¹vGe€ØìJNZO+¥H¿!ZgÌ™Ïº‘LßÏšÌİ¤â _Ê/aŞr	×0Çx“Nóö"#TÅ0İ.©’/‰¬DF{õ€\D4NÂªÔJêã™±‡µßòwĞ!38Ñ’*9¶µuDkzÊ/`øıºHÂ/;1_Ö¹§dÑüzVL_Õy ş,¦cNúní*æ­MlúQœû¶Ó§£†4›!ùy8ùM“xóè˜-‰Tƒ
ÔÆ¢Šµø}T‚Íæğ )r1È®0%¨*HêS
«Ÿ@‚óyÆ‡—¨ÑÿÄ:ø’­Óö5NçÂ€Ùk!²™3Jmd¬ö']°!KmkÏqC!ã~BùàR¦z1Égp9Pgaë×Èêò‰`ÀWÊ27Ì¦Ì”ÁÊ]]Íˆ²ÏëŒ{ÆcÚ´š) ’tI,´CIßĞÿ #j!¸Ö‹°'Ş…­u®©"‹ Ôôâø;àæ(²ò õ|M¤ƒ›p„LûæÏ{QÂ¨ªÒ9sùÜ¨šï(i®ì`&Öcëbµ’dq(T©®ÎµmÄ4{äàé#Ì„ÂÒ€&Ûù~ÜÈ(NwízLŠÎŠÏîæÆK˜\[_FÕİ¶;hKfÁˆ¸/À2¬ó%çÎıŞ	ŒóRŞAÖT9Atu'’ºå 5È×
Ï×C±µƒ9Vâ¢Aÿ,Lè‘êm©»¹Åğ*ú+²ÿgê ‚ÕÂd1ì{W.ØD_#ÚÆğ¿ŞçÕ
ßdˆ|U€—-Áxa•ˆõçu@U*¥=g©íxÊd¨–H“Şñ?Eæ“Æcö®4Ì×_M·ŞKÇƒîÌâ¿¼¶Ög›KJ3+‰VúE5Z³˜óRd7€¼Vt•2¶Üî‹ÆüI~“Iè›ÔÉŠ¥å®…-ì3b>ÂÓ?l>QÏÊ ¥HŠoÊz‡«(Ç²mïÙìÎoOá‚ÿ=µz/püKœ#èi/OHí×S]e«—öP~ˆ°bãwşĞ~şòğò—c§–ÿÇ¬[Å²İßïh(Ã–>ìWÚ÷ã¨æÌ©ƒÃ+ĞL£x¦şğƒD{/d[±ê½·mZ–Ë§Y¤Í­¾üËjä?#Šù*ñêU¨ Œ,vÑC‹?ŸxŸ^’ÿÙ‚°b¡½à¸è/G>Ô©é—²QNAÇƒÀ¯‘²Yb‹~Tç8+‚lÖı‚˜©l;Çl¹OÀ	ä6gÎ£¾vöÿÊ¦àm6Ğ!^Dşë
h·7¸‚ì¼&(ÇqãÅ¦™é‚†jMS±Æ|Ä¾æ(ø‡—›õNù&uØ%çaßÓ $Ø.şE,}	dæ °½¸×*3‰X¬±8\™6–ÅÑIîvõÌ®ÁÅ¼‘ŸI$UÅ >ßa½§/İÖ4S˜Û<û½’ÇÆ$BI«¢
éµ å\æ—o—/ëıUûO÷éÅ`y·~2µòxÿß·ç	§S)ÜûvWÑ²^Út™‰D•Í„ 7§½óEBœ¨W‘ñ-ëÆR r˜S]wé_$Ò~nc8+¡S‚X’¤¹'âNs<%ñq;'ƒš | at'rš«¢nÅˆ{k³ˆĞT€½ÃyÏÆÊn@€Ú .rd˜Õ–•‰´Ô²	}OIæ›Çh'¾Ò¦Ã8
,0"#±}À?iøfÔ]Çr½rM¿ªhçmÿÀ){5S‡,5w„€ğÁ~2™HÕ0´ùâptì­ÕxWE9Ê
6ÛHYêŒ"è/ÏÉğÖ=£„ÑÎ>tÃ1Ü5‰şuXk"×^of­4mhÉ& ïòTCÖò ²Ër,6œHD’ßôOoı¹»æÉq/Lz’ÇTÕú±†¿Ñ›«UÕ#,	„6¢vÖq„‡€­#0İN…ï<‚ÔDX5pë$˜ÃkAæ£ÛÎÜékæV¤©T›)¶½àGºæìWë/5UjıP(	-á”Ø€éMx;©øÄâp]FéZÓOjÕD±W¼wŠ÷UZ±aChM÷à¸[:#D74Şó4xô>7
Yö\qƒu9‚Û>¹9Ÿh ¶\×ª<dÑBıî’I·»Ø¥§4Dİ¹¦dÎ{É8áô z¥‚¬›ıZ2Kç²Ÿ\y	×ÿ÷Kj^á¢5hÉú.Ñ5í¤z<Íß.xÑÀÎo)‚¢ù)‚\«Q•ù%A½¸J´k×+ KìÀ¹h¨÷? -}MèoN×I‹Ü¨–~Íï&8–£wĞê‚$bªÂbÍyi~5^¤túìA€ıhhÕ»@p>V£½‰²'¹p˜ã+;î%ŒÿÇÃ´p›Xçq7óMùø_yP0&0uUáÿG„ƒ’ÒšØKÒ°¢?ĞiÏ¶	›ûO•-şÑ<“vq±¬÷ sáú$ïd;õ)Ñ’hìÜ ~ÿ›Ênæ~Äw®Xû*è‹‡+³Ó*Ï(üYÓKJ#fë_%²·9FıöêˆZ,ØÂ‹ ¤©2‚®–(¨oe38‘IlX‡@Å—5ÂÜLjzûƒ´©!%QÓv4µãWu$‚kº?sFš5ZMÀE§Öêô3¿!`zÊÓÔş@%8>WcŠ¦&WO[Ë¶¨O5‰q¢ƒ´CsĞ7p"‹¥3É×q‚ ø@ïÑ“ıV×vj‹û°;æĞÏlHMâ®"$P—˜à6ÔfN%4$FÅŸ|÷ğsIşU¯òL…×`Xg¬‚Å@}ğåñSÏÁÃ,%än­4c/\Ğ½¶~ÕıH2LŒÖ3eñ‡ô×ÖYËŠ‡AöÁ¼
¸¢YQdœ§„ğCï´ŞÚ|¢Qy¿ÒyíšKP…*]7‹ºæ^±‡?ÃÑd )¦ÿSÉv«VìÛš½%K¢_/ĞÅ0
óãœg€¼puÅÂä ƒI*lÒÈÓÂú¹ÿÿÛID4µÁà®éÏX¿àJß>@oŠÑƒ±`|ûh¼Şç^Ùñ”¬¹°ŸmRŞL…ŒŞcÒZMš. Õ‹jÑŞxŞ‹¾ên§_—Â¿·w£ê”`¢ıñÂëNÆto%-¤Á"VÆø« ÜÎ¬m¯Ür83øÿÀC>^Á;€™Hûy¡ÙúÑ¿vÜ/¤®_Ò¼‡FßµZÉ}ØVPÖ	Æ:€èyü¶›áĞ–0oÛ¿ÃS1ãåC—‚´BÆÚ:œvë¬	>$$ VçD÷;¢Ç½Š3±ëº¹²éKo+aİk‹æ²K_í†CEİœƒpié˜ÄË¯v'[«Ÿ íª™¿úÎçënYƒŒ2ç›{r>94cP+É1k!+‹å¤:ü«ŞˆGâã•Î4ÌpiÃ÷L•³3d%¥J£»U„ûæÏÙI³	p-­Ä¬_GÏ^ò«À\É^îûK1ş®tI”q”Ôõ÷»` òào¥$²uŒC‰åšfÈæ¶TK{¨ÔFà=b®ïÉ~õÊ%c÷9dûADR.ŒıtÔHõ$fw¥u"Y-ş~Ù±S§òH<°U–Š…«ä£ªÙŸ-¥?Ee„ú-SB2}pŞ_â¿&½’äbç+9Ú%òEõ$-«VEœÎºÁW|Ió‹"–ÌšÜÇ9®›e{uº~IºTz}/Hëé	–·8s2¨£Ÿ‡¶¶‚€k\n$«$Óÿ­/t*µÿ&wE;)ÊÉ•ËqL8Îl;,xd¡qªî$=U·Ä aõ£¥Iâ×Ô\A¬GŸÀ§ 1¬_¯ÆÎ¢¢¥‰ÕF™‡†³(‡œ™…àqAµ–×-PHcüvòQÄ·¨àq°á¤Û´l«-:`à¼Ü+2fŞRLTJ9­'ÓËÑu•«#jÚ3"-˜FÈ)HÕt¤hÑ;Ë{®dsı¶)ÄµY¿!‡ü1vª©e˜‰Ie€³ZIàpéM¼=³÷íƒ·ræH%bI¾:ùgäcÜ³Üº›ø%=x”âd8BAšaÓZ‘M;=hX–gpL/\Üo°rmŸô=ÿ"ó8*…`!ØÚJ>pjÃ:QLİ^_}pûAöìó“=§HFvY;/aû :Ø´$Çá ¶6Ú2í¯ìŞ
7*³ÇLûm)y¬¶XËğôsù­±qªòjÓÙ³í é?ê¨Ó¤qîiê‹æqDjiĞ§º.;c mï4÷8½»F‡,Å¥®}ç@#q#”%ˆæ"7«B‘aÍCÙL³–üfS‡—J|Qe‚¹óFM=Óf#¬ò•,qÀî_^jSúÒ`¹`°¬ù¾í´óõ­±|00dL³‡{&(±D‡ Ò ã!â‰eØ6ô¤ßJ©
=›j5“:èsVÀÙ6Òh<9•ô·˜noi
ÎÁ-ZP{µ_%fkÉéøn–1n=œ!³‚f×Ÿˆa+uÖ¡‹°¥ÏÊ.dk‹}¦¿µîA?'ï"…Ï§Sœü4P¾bì®q*!±hMs™O†
SB3›¸'†£='¶ªA¹ˆ8 x`"ŠÙ»üÌñ¼ØÚœ7ö$Ea™4I¶R×‚Éç;]g7©³}±‡?2;Q±Æ+›ç=bìÕHÛJËo½<±Øş+ªµíÀŸ[4ŠöñÔP5ÜbZEşAôB¢j£UàNé[‘à wô}|]ğÁ³–Šj#ÌÖÕæƒæ®š\â^\Â&Q‹Gb‹ZO½j¼ÔXà Ä†ËÈ'5TÀÂY‹
NOÁ¸=„XaÏß6ô&2”"Èò¦‹Zå‹å
ü¾Â¸À6aÎRÀW;C0¦PS5±Úb&.ZfŞ¬XjLíÎTkÜ]êíîLşæùş-Ó}÷âÊ]È'B4Ö[!¾]m…W$¦*šdrÜ:'À‰ıe$=Á‘YôŸ#Ì|şšÖxßô›:Ç¬$e2‘
ª3v[¾ÇÂLŠß„A¬ƒ<ıÈÂ‡ÌœØkˆ!h¦ğÆHn#º.„óĞê*1q$á¼¢(÷©G98X”´ÔêS‚3½ãïyÇÄ¿»]¡ÔË=' ¿–?¶‰|ìÙ‹Yó<ª–¬o„™£5>¾3ö	QsdXÉÎ‡Ğ9	È|÷¶vg«¬³ğôbÖ¬qGÔşiX|8Trüb{v¶Ëçš-b2ë•î»¯-?‚Ş»»ß’gW&€mC—ÂòÍTc~nÏøNaêßPëÛ¼åóûJQ6\¢rº}r—ÓÕø=\ ÚÚPt¼İé;Dæøn©kLøÈ¨jşØ,jÅà#Ñ`­#”Úupn°‡œP|*Võ³]@–ŒÊ›@–³9M7¡'² mBAõ&ElJd\zÆèAşd8=£O%Ÿ„IÆÆäé–dz°‰±ÒÔ],¹~ß`xSQ9C‹„CæS@}/İ2–ïÑRÌ<ıdÖw¼ÄóıœE‡\½olĞ¡Æ?@öDOÖÒÕ¸¨†Zé­´ªJê’6Wã¯a\ÍdÒ?5Rüu†­`Û ÇuÁÚ7¦g$l²œ¤~vy‚:eyº(V˜;š4oæ"cQ2yTe'`R*ÇÄ\û|I&d
>ƒ¶¢£ëû¯‡[$ú’…C^‹òóŒ=š¶2
ƒfQ£ÁPå}Æó¶ÛÒğÅÉ¡l˜¸å'fì¸ı†HÑ†W\Èó×Æ'\³«JêÊ	^@5C/xşğ½J$Ê½/êGB ’)M‹¹^fÒ´Ñ"óíõUÛåç+îèg¬[tmõ‡Ù¦7`o»ô`X€S¥*šÕŠ£2ïe·"Ù8=CGb]£’75Éâô&A;Š_ÖâÍğ¯Ç‹ 21Šéâ©3ƒ‘—ÈT\–bë¼+ÊdÇr˜Z¶#ßÕ¨‚Ü–ÒÉ9#©Ş“öo\Zeİa÷^"e~ùĞ1ôpØIÈéÅqà|Ø¡É»FÇÊ2-"êï2¨†1­n¿òëx¤ı,‘¨¢¦v‘İãYfFÉk"DÛ›…ñÿ‡'òs«kP“]R­£ø´2hß dbäxàh¸mî#Şm›Î=Çúª¸ ÅÛø4ªøKrIbldEx.…ë½³A‘=A¯ıóØÄktHcEb®ÆÎa¢VÒÑMï¿¡†íde‚?pšbjaÒ¨İ-(´! ×Ù£J3 ‡¾7^†Ä%R_®qö„K¸Lê2‘©ç´?L¨[¤\…ª\(Ù9PÀeøÚŒ€Š÷6¨°ÿ¡Â„uûé¼çğz"ÕmQÿT_‰÷@6¶„»€ƒøn'OĞ\[áwÕqIÄá$Á Ü¾* ‘‘3\åjIğW£îâ¡Ñ£kş¸|ÿy SîÁâCR²%eÀ=J†¬™Ì‰`à³[C'ÙÜãòıô¼£-ÎäéFW¨Ş±±)¤^^fcƒjúqpvbYRbŞ|múhKÑ$ebsŠ¬n»9ûæ
'>FuCÂèCÍµJPnú‹ƒè¾Ààë‡Â0®SråïŞî1j6›)Ê±{Å%(¡ğßê§`å=@ZÊ¯¶ˆk*®ô
ĞéíàeÌe˜-³ö÷@~ÇIÈ“2A€1±¡G’_Ï@a¤Óy!h{3¹lw¦6–#:W—·Êjë·j!aÖªğ¶·w]RihË0l^Yí Wsf.§|eÊ¦wÛëÈŸÈ4„0àÍuÃ^Å‘Šä?)¿â0Ø»¢Şî£ºˆ	êŸÒš=d‹¼çõ2õ}mËPŞ‹ú¢»÷lnïÙ2&° ?%Ü„bùr†mV•éº.¬L3Ó!é"xyrñ‘’^F%5z2x-Êí»\”¡ O±ÒÕª°ŞÜìD<GT˜U~ĞZH[i;C9†N+JçT*`G›ì~šÕüa•éä-éPçÒ×}›ö{:Ù_;h°»DõŒf“³C¹ö*Y¦b²²kY±ì~@d`IĞ?¸N~g¿²x}{&9ç¨`
IĞÃ„É*…á˜ÉÓ¶X¹ç¾*°.¸7D4km‹C–@,éluæUÛsÎÓÏIa¶âxlT1N«¾çÀ^²ÍX»GvıW`Fó–€.o™#¦Ù îú0w*å[Ş³¯¥Ò$vœy‚ğßE=õ0¤xîÏO>ÜÀFí2TïˆÎHHéÜôœôèå"ĞImÀ×ts1ÓÂ»êĞat#²¥×ê€›"A¬Zcœo’º­şG*±ÛÎ18·
Œ/)j>š2&ú÷li<Á.É^¼>•ûĞ¦O’Æ>&ÂáÙÇZba¬3MfprúLA>36•^Ä‘“ ‡M2QV³J{¼t=ˆ“€;¥»Ò!Ñ2ÏPÙøóf±ËAú{r{y¼:ì7&…ÆB‚¥À]˜*©äÌó]}X“ğ`,Ü…ß¦×ÚÑ’ÓãéWAhõ¢A¾=TÙ1æÊiyınğAbµ4Œâ`õ—P}ilú¬(yxeÑïqµ$+7@<ÏS½ÆK“†Òû¨jm÷­í‘…VàãÑ2£¦ 9(Ô Ó=¢ è¨g,Jwàô"
5§¢ù'E ®'&;h¥Ï
§4¤ „$ÈN‰É¢Rê¦Ç*üïŠt)ÜûÈ%P˜‹;‹F­RzÅüîÜ­¦á5Ò9ÓgN&X†€)X5!ÌK›5Lš„Rmo“ªe˜G¢0qî'Uå ‡ôÛ&ˆ™½aÔ‡âá@©u¨TAğÃ[¼¸!ìÈôïR]*Ÿ!Ï•É,Ÿ÷Ï›Yä|>É+ã˜­T,>¤œ·âÒ´úˆ¸X–AkôÇ‹<v ç.ázÎ}	4_íÚ«mä,$/¼x&èkÙ†"ñSä¡’ôsPtÕnqA3ÆÈ\È/¢©Iü5>*Š]*ğğX''±
}ƒ!mr>Êf¯ª¡Ü5×pzıš(Şì ùïMc€·Âç!Jóªj–'j5_–jÜ†Eóîó–¯‘WB¬QÓ¹Ç¼á	 „†Ô[ş[KVêÊ±……2\2LÂš E²à`µâ#ŠÆt‚k;ÿå.Øów“Ô#6¥ÎEÚİÇëO@	¹©‡ª#HØüo:y‰_¯ü»C7$m™s^9Åö­

4gxf8“áÙ–áJìğ'òş6¦ ©ê”1ËÆÌP=y5\%šnŸÇŞ[Ú2ôz¥ûÌv§Lw¡×ËÕ×&0½'4ˆg„9ã,ôŒî=Ÿ¼ßWEÎ°ğg“}}óú´Ø<óÙ*÷ZæZl,Ã
^%@˜t+LfM©–àI‚õş\ş¿à‘i'3^[ì‰w4Jë}öõß8wE?LyF¹IÉ7õ]iê\_µvÿı€ß(ÿB§JDŞg;=tæ‘íM©V‹uNµÍÛÍL	cß‡éÓ)ıRtÅÓ£8îËU=¿ æ)vy}néfO‚hÖ¹X¯xÂ;Ã7aŸ[ˆŸÍ“T{ã µq("oIR,Şº+À¿v§>×ğ‡†p´®šù
/š.V!ajÆÕ]öDİK_â`¿{õ~Wü½ë’·v	Q8Îíú”i¤İ\º}íŸ®.Ài-/‚üVñøÌ©&!`SıË lØtD¸lM9YÿaÁY!ÌLõ>L,Y3!É%†6ÆLëwû8½€5şÀoã V‚K¦rG3$’›ê8\k7wn5‡©A¥+ª:¤ŒÌ[.ú’Á«sÁáQoo…¢ÉñZrjl_ÙCy,f)h¸tJ;/pßû…ár=SÂ_<ŸÌ±}ùO…”cëM%ß»;D%˜rÙ/ÓùIĞ÷i:Îôò)Ë·~¯œ»ÇÜ‚Æ	Xi…'IW#»R¯‰1¸¾Ìña™`°2úÌø å=·Tìd»•xëd‹çF¹Z‹†‹k…	Ú%Zõ6b‡I²SõŞ2˜FFZ©dÊ@dˆórÕ1ßw|µq:OKÀ.=¾›¬EábüC/­¶û5õr×¬'ÚO9VNTêõ¿ù{|”	« ğá³øĞÖ"5Ïk`ó«Ån—Œ¼¿w”0·J|ŞÃ /CÇ¯Şv1-l’q9ÛeWÑøh)úœ¶ƒ~ãÊz;Á´®jìHÑˆX	àí8¬Ê•y‚˜ŞªÀ©¾º¦ñá[˜Â>d®h(Š¯úß©ÂçuÅÏ+Ê0?£î¸K'™3ºÌ¬J#”ó| ùÆƒ¨Öí7BÔHj?÷³2¼”ˆûû­£YÔà&Y‹ÄY{p‹”¥JÖ÷CõÅC°A9ò¬ã²ò=­Ptı¸’º%øzÑ@pÂZ¾X»–“aÍÜkWÂâ‡,ÏÏI.jnÆ¬Rm3©jÏz]•ºÒ®CÊd¹	&h!Èİt	d…ˆØ•15„T´¥å#}ÀËŒNÄ·\‘Á¯=Å¤sú†ğ^ÁÈÉ“JÊŠ¡¬¢#KÓ™­rB¬’´„—ÂAËÿ/.$G°>‘•Èÿ´G“èoÌôzç¸ "r¼;ˆbüˆ
òTªÄQ®‰ˆÁ{ˆ§0Ú)jÈàe6à°’l#½PÓÆ:“™‚NÃâ¹Ñl†õ'¬¼Uçg»vVÍÄÏºZÆ$¿š!,€xüóÚ¯æÀËzÎHåĞĞrƒ¤$W¦È{à×ªÿT>¨ZJc±nR¥ñ¦)ğjÑ7=tÖµâôÔúyĞ‹ amç¶³G¦ş œx
):Y*}C×°…µ¼Zw¶œ|¼™” ë«{„$_w'RAŞW­H%a²‹S“£ûiúHÁùFc\Óş?¦)ş¬.š´s…€%®½6¼÷¼WC%õ$B›8çiKµÚp¶Z ˜I5ŒPlGR$Â )lÜÅªËÍó¨ ÊÕÛ‚/Úã·I'¡N.ä)áŞ<ìXäaW÷°×Û]ÜØ”pŒ¡ÎÁØà™ú^ÌóAñ/„ôôæ588|p¹¯¶‚gOÌzùŒ·ßºRìÑ)G®àÕ¨%PëµgîA`,ù
†¿0Rıoz‘hyeRSØ(˜ßŒVĞàå1kVÇÅ^å|Aü¬½…éÃÂUDí²ÜİÌÚÂQ%ê«À+1¬eğÓtÉÖp¾å8¦äÍÒÆÆÔ;¶‹£ø_`·ÁÆ0 È	3‰ØYœg‡öä½zÅ&kZ/såÒ£³‰±\ƒäÜ[µûŞF£ÏÄĞa•#+k¨@g¾S"yçåëk”€¯BlòªmA‹ÌŒ«e×Å6…É:°Š„I´k/é<Eï4üé}#wÕnéõ¸ÅywÑ1òªæFÇ×îÎ7lÚøfvŠQ)C…rO Gãè	Ş$úÏåÃDX¿âş0=!û	úµ 8ºæjàl©²Ôly¬	áUjùqUrƒº°˜ µiİ†÷‚üZ>7Ï©dÎ¤FºË—ec0¥JO-j›óâk–'}²Êí™‡c`ï„~°¿Xv©r]LTv#ÒÅ¬ƒ?'À%Ãárw–4ÊçÎƒ·uQ.„ÊnıÓä2Ô:KN¦¹K>•óá460‘Î!g?˜âª?Y#Bqz"“Ç\qèëı|?º«¥í¤b&a<™\ª\Ö‰…s/\Ò…°tÎ˜ä„è·Pëât.7o¥è êÍŠ¿y×ãÉ·½4½(ßÌWÒÂÖOÿï<È$’z)ßŞôş5nÙ*~H:œú™Fº®UšÛı†F›yãY“&ÚÇ\Kû€v³PUô==GZ(^fÁ´E1ÙChUœ\(ÅÇ˜Âé%¸4-O*É;“ºfæ=İyƒ ƒEˆçí/’‹uvĞYÇsgñ|¸8Š	{'zaËºù7Óx7U£Èc6¹oœ#‡p¢›íWgq.ûõr/K¬@J¢{ùWÜŞTK_Îî…¯,†Ù×Ü®11òz•ÚJ‘\}Y¥«·ˆèvh-Èœ?@Dv¶HAéOÜçïÅ^5Iu±øÑ›•n
³HcÿÃx?»¸°¦™û¿e³ì<_ıÁ›6Œq¯³ë.{6ïÄ¬Hôª¹TéG}¬Ç–ÿf_-]'å6» f_ÄdÁ*,˜âıï9Õ¸q'÷ylåRs8ÔgßIŸa_Á«? Z…çõ©KZ7Æ$çfîˆ…6`‹”h?ÎÓ0½"x!©(ò÷×üJÂşIB—‰a pn…à½qø{J$\û6½¢Z8R#4Mª£‰·‡QkDE³ò‰Í<°vE&±*¾Ë¨aÏiKÃêVQİ)³ïzÄSƒmÄŠ7õ6†bçó|BOĞæé}Ä{º+Ó1+Ÿl³Ù-kıËğGL÷§:‘ÂÇ#ĞŸğÉ©êËÂ*òºFBMsî_y^šL<½÷v\ôd²#JC›Õ<(’ş|ÉDïà°&G«0ûS‰÷„ŒÙOtb9ı0òşÿqX•2šöµr‹‹Ü"zŒ‚ñİH\AnøeªrKÊA7¹èÁH²ÔÑÔ±K¾ášPËğûÒ¾0Nˆ+ rP¨#Ío–©ÄÔ°í®€UëÈ;¼øÖ¯.Ğ
n¦›åºµ*,Î,ÂY¢I>’ÓmÆ±ràjíYMƒøIÎPtñeâ}
™•èº–ÃNh!ñì+EVVÉNO+.í…8Ù;–)‰+±>JÔ–$¢ËUÉ¡^Æ‘ÃsÂ7,AÈ¿÷¶Å!Âg°ÃÉ±ûí/VÓµè§ÑU &¤TïKoGìqà HB(°¥IŒÆåâ–OÛšÍ¼’G+·?Ûø¹ÔÜ¹–¸êo@v¹¾\íÕIîW‹eÌµØh¶±®3a¼YÖgÙĞgê0Ww©-jÍ­Û~ê`±Ş,¬Yt¸ßÖû¡X j¢y2ËSM#Kæ’/Ã!_±›§L[Š,:Ü¹²@#ÒæÌYá—n Ã| “—j¶WÒk…Jì«xî„Ø5Ü¶V.ì?dó?[;ö¿ÁZö¤Ğæ£U¤¤²Æ„–-†ºÌ—a\ù:ì¨•ñ4‹æ÷¨ú/vOpz~QìÚD«Ã–M/CŠù €“ ¨TáGqğÿ¿SFó\g#`orÕ@ÊFSİIİßºhûKÁ:hiS÷+‚n-î­ˆ:%|@´oS“ÎÂ€‡zH'ÑA&šüÎd)müÇÚ@ QUÁ§e£®¤¥ïŸÆ>Å.#C8àIßõ’Ú§lîX¡}‡Ä©oà¶8$ˆN¢ıWzŞFA÷x)«Òÿ©À!-^¦Kšã.2ÕZú–ÛÛTÕZAÕK4¾Ò„8Ö#8’{FJşp¤^Ò;¢{„IGëñ’P—:*áHz?b×¶ =\í¹4	¹~6“1¨‘Ñò‚)ré—rªM'Ë'2…Æó¾ªW’æÉ÷Kâıå!”¯PbÙñ»Ä&ÃD¯Ú/ºõw¾D®„ÏÜ÷
[;Øì!Jw_jjì0Ë °‘Ø¤‚Y}İ8–Brî¼ X¾Á”?¯-UJá@ÒB
E`W™İ×*ÂæYJYê2\ÃÖr‹¾õf™-ÉFF>³i~İgÙ¢Œ[
xİ$í÷L<˜Ö'¨/­{Zñ$ãÑx~´MòLl¹"Ş¨¬Â/øË´øó•’ÄCíËˆ¤Õ¯ªŠ3²w†¥J[|4"«O]±ş!<_4JİûŠ Ëºñ¤Ñ—”ò è:—ÙÊixî(Ÿf½¬íQœê©&c/Ãn'ó€\@fÛ½ª¸)íÅ$±¨*Am³À^‚ÙPN˜7§¶³$æì–êÅ:ğKÉ®¼1Låé˜ç”=—?ª[×ÍÌ$@:yë£"É	74!#¥T%Å…×}Úw~€³‘™¹;h]ëšk0ìO¡•d›ÜÏ}—=ÀÇûA/õ¿Ê~n—OÕ‰ˆ³.dêòŠzÁ@ø´H™ŸKğ°‰|”)}7.Ö‡0Ş¾c¾ÄÚ£›
Eìb	½`e¢Zƒf$w°‘yd£—1ı¢OyZĞFazV†—µ `æïÜnIAÇ ÖØÅ_b» v8ß®³uÃ*åÊêPùÁ't­±á4¶˜î&;Œ;Ò2>È•"³÷Ÿş•ªC\¦êe¡Û)Ï5+£òç+$ïr0¬½	ıÎ‘ÌuŸî?_²V/Û20İú¥L{Ë‚ÊR‘À€:SŞloaüxÌ¬ØWÃĞ$‘t.¼&H‡—S2cQ¸N›œ@œ“İdÿ öÃò°™™‰ÜBìf5kLû'3±ûIôûğÄ?ÕËavµúù'•NÑ_­škÆ¼×î¼ëÙ:ö¬àLvzşÇhğy:–©W‘0¸…¥èbÇäoW:iå¾itğSôoóşŒAôñÉFü|¤oüÚ>Cy²ˆşÃ‘œøÜè–¶Š¦2‰ï¤±O&INyfR\>æä_>¿Q)Æ	
uPPUe ß¿³í¢/Dís†Eòdÿùåd‰Ô9ö¹œ×°×/Iª²a{ª.ñˆv.3•aIv”5{¨$jèTĞqêGsÁ!Fİô²ÿŠ‹Ç–øÓˆ×ñØy~±y=Í¢+îkÈçÉ6o›F©ù–j~t :¦ú(opËK„Cv8„ç¾Eòø8c¹e@j^/Òg9OÚğ÷«#ÂC[Ñ-R'YV¢dí@f¶É}4ôÎåËRYÿ•|ÈkµÒ÷ı¡}å•"l¶ÑyïmA’v†ÁùŠ5tûàFï÷Õé¾•ú$¬QhT9?MåU…—³¶Õ8u6æ%î8ÅÈ³f{Wö*¹cèVfhê­`Ä»9‘3RáB®‚‚t#(!ó-¯Êb4Õw°$¶Qb¬ yÓÙ#:†®Ñüdo×q~Rš~‹ba´g/ğş/ˆîb—©µ‚ÓêÂ†¥>ˆ[ ‹´¹†Øò'0î.’à‹|>¦Í ÷/Ş!²¥è.zr½2D«ÑO5«y-³Å©ø”ô¤.'›Ğ‰åh|bÜ‹-«Eşiw®ûœº5d1,ıcˆG*?¾äERßş>AñÊ«…~+ONV<?,Ò>:T¶|½ü‘AætÆÉm×R÷•üQa¤°¬cë^Ê½Ug„m¦Ü@Ûf½]{7‰³èºÉ¼§©÷ğ)uz	ÀYd‰ƒ„çUtĞ›61¶ûV‚İÿ 
Ëñx¥›A˜æ¸|Ä¿°ªi"Ø–…áV[{‰W‡ú?×mq{k0Ùò„™„sL®Ñq\‚Œéæ6})(˜w‰sæ(‘¢ŞXæOî"TCDºï°¼íÔ^,flˆKŠ";zÎRó½B~–cé9İËâMğ¾7³(ĞMıäñ™m°‡zsog8ûº|??~©ÇûUDëFBpsÎäVúAàSye)YPànbtAô}Ï@÷õ\ÓÁÓkïB¹ôpº×©ğ?ıDÜœ%šTPÈpvèhGDJPK9ß]a¼hsĞliw³4; ĞI° ]ÇABhÛz]+Ë‡gÜùm^‹ 9ÙÀ`ƒ80ıª˜ËÙó")`"¬ŠyÚÕ `=ù ©„²/ïã¾V—:¥Å|*±×e»êTş?ï_œÂæ	“ˆ=–Â3©ˆá=á•tóÄcµ¿¿=7¡? •BÑf!Ë«*!·
†İú>Îæ¸KeşW3]Ağ‹,ßÕ«çòÍŠ¥Q"Å‰Eu¿İıdøæÙªˆ`[Bô¯Ùÿ[–Š«u6«m1–Ñ°Ş”d€EÎñPŠÜ¾"{Ë2>ĞLY-ƒC•ÉÖD!îĞqW¿±ˆQnlJsÎîwp
ÔcúZ9¨É]Ëi!mCRØø/†D”€S¥ˆ%İ”ì-kvM¶òYß×\øHRDnÜôïƒĞ8!{İG±ñ„Ğ=}á-½TÕªøÍVş–ä_HœËøCÁÜ-2×ü$ÿ{|x+ú^ËÒiíédŠ°Ú*9EP„ LĞŠ1íö†ß¨›yˆ|L,Ş¬ÎŠ¶Ê]h©û !Ûa•YÍX—ÁÓú Ÿ¡ŞD—j0È±ôMß=ª½¸n²F³^zü[¸9*y#ƒÎ<ŸÜ–?0é¼Nò]iµâ¾
yVß¢¥S\²•U5Í;ƒ'i^{èÂ®À«S´ÎtsddË2K;2ËJúm«—hM.Ã³qĞÒW£ŒM2?ŠŸĞÌ“^šÆ«1Ï³ë×>…=üößãìmÿ¡W¼È=&…À$YPV¯Ò³G·ô|¹	ã&‘û–‡´ÒÊ£MVªv°¡—.–7ªÍd@>T‹¶Wf8çsb\eA<ZˆŞ‘Ğ«T¶AâFµÕ¤"1äMeü(fK¯¤D•"0-oMäÔˆJ²éwÂêç-½'mº#÷7^Ê¬lQO5—0P;‘ãUz°wBqv2Ï/ŞqKTé:%|
ĞÛnfÈµ»ÛïÚ›ÓG	zoîGÈ‰ïÁtTŸ)”(Tü¯X˜ÍUsª±.ˆt‚j0rB	ºè4}D?GbåÕÕÖNx¨E‡ó7øşFA®TTÌ¤KX6Ö,ù'Ó¥Ïø¬­neÍŒ^á6h¼z0Œ{À•TCŸ
"·®jå¸òe?:¶“?¥I¸Ùº8ïÏc¿<)\-ÎŠÀ”ÇûŸDà´<áàş¶:*51ooğú>¶±{èP>ü€ş1*„q;5ÑcäA¬~Ó°²¸4	IØÓÓB§©¸3¾™`Ò°V¤8P%¦ì„Ÿá–Tbólë§:(™ŒNé€—¨¸ÚÇı³È®{ô](påp¿F
WeH_sï¡¾\@%C¨hj2¸_Æ·Ó"\˜K±Ç¢ÜÑ Óú33l&v¨ß²Ñèæj—5ÌÒCûl°Ugy€7CÂ““jk4@.UÒ¡[331[«[Y¹ã7Ç—^x4²Ü¤ˆ­ÕÖ–½oácB€‡­iB¯V±g?‡‹}1—šğîã£ëÎ	5Î]Şr\ïk[ñˆ~Y&75b%Cy”`–ÍÎkæ–ĞÆÛ$­èYH(0€<|èb²>eõ~ZĞ™ê.	İQj-{Céğ=¥`â;µ$¨o„XT†”­òc¦lz‡ JÄ›¡¶„Ì†j§l’u,Jê›q³)[©|:=6L&ğ$çX²¶ ,‘Çô‰¨QLä{<´ˆÖYæ4 äëmrY‰$%%ßûn-¡øÅ¦*WûRÆ¯4Şc*ìÂõó^ìä–#àØ ç·n°¨xå³¢LSVÁ²Âfsm‡OXpö¿£$T’95í­~¨¡À™ËÏÈ%åÇŸUêVQÅlìµÕú¯]˜G$GÈãŸT{ÿn&@‡¦ƒ²T'T"æ8K?´R†Y-!Ijz§ËÓEàí…´ÑWÕŠRÀùù}öÜYğäYÚ*ÍW®Èãq°Ø{‚Ù²m¦ 0/½,ÒF“ó”tA[Wöw8“Bu-ŞòG ÛÿİÉTÒ¼ #™¢K¢õ®œğç8·ÊîWVlr#÷ß¥]¬'Ó\e‘½€]:t¾4_J™^Ó#ï Ärs—K|iŒÿCÁ8ÖwòQÍ	„jıéN¥´Ş~]8a:"¤/QdrñuØŒò“C‡û÷hÅ¥@Ê<AÆZµßzÓGa‰©O¯w+ö…1ÌZ!¼–uÑÄyï1É•¹ªÆª‰+§ãfv¶ç}ÍmvÙä†‹@ğqóázC—’Ö—Y¿à¹Xb
¤(¨!;|K(#şm^˜01ˆâŸ‡Ù@$mÑıŒş Øğ‹®ÊbÀ=¿ÊtùïuÓsadâ;i}®ïá¼ËsG‚d·²“@ş™ \(W/Õg(3&Æ¬eñ,Öô¡¾7(5c{Mú;Â›‘W¬S¿è#“³¬·w\Ğ2º°-T”Ş˜vqˆ¤•«ñØ™%Şü!ï¨å<ğ§Êª~á .yşèÓV®ş—]JK›O?tWèº(k‘+ö"ˆI¦ªŒ§¨şYÇ>»8oZŞû­‡®\t"
\è3Á<&
-EÄ *šbMÿüÌÏ¼+2ò'Ç•E_FÂ†‡zßàüù¥Â@Ñ6µfM9.Jê*UO.a‘ÍôpiPjÑo«©|Œ\“(¿¼sŒ¢‹‰Ë6@-O}êNÈf¯°˜L¯¯ ÀYR«Vœi?	 K®Ù¯­^o¿k\bï¦E‡”§ŸÈI¾dĞ:ä*¢ÊµAd®x~ö.ê§ËäkÚYµ¯.“ø1y&Î „ıÔB/uD¤º×NË‚Óƒ]ØÔüÊ#±Öü&^/¯˜ã{g­ï<{çüRã|İ^ÌvúÈ½vÎê;ÛÑ3C eÿHj×¥º/ˆ$7$…Ñn!¸ª"ğjŞ&Úh¶|k'óp;A£$ocÊ¡¦ûã‡/‹ˆpŒhQ6ä8	gX,Ú'0:©Ş.uebGŞ–¨—AıƒˆÇ) '“Ö	Ás	©\hEG}ÛÎŞSÛ}™EìJU“è’H®ò>Ã|İJïûöÄ<ôG9g“çùŠoæªë¢
$íoêtåÊÔp‚ÂŒÌÏ)ë{PÉÑ´SO>dŞÏbd¦ÿZ¦6íaf[køâYT¹gÕ4y7m|°pÍ. İ{¶ÕuŸB—“rCƒ!-k%ùYB/-%–¬—¥KX	8ãHÂ#éíÁõVºüÁøîÉ¤.=“hSOOaŒ}¬õš4X
Ïé­† Í  	ª’ª²‚–Ÿ<´_º‡2C6SÃ[ØQáë‰Ësâè¦`vf&ëG,XKYÊ*kL¦ô6ÊqçG0ÿLÕC±a:‡Û5¾A¥’ú(¾óÑ×#7õ¹à¦ì’»×)·ØÜš/¬ëÜqÂ{:W¥š{€YM£íÆT—-Cß¢6á¿U!*®ÖŠ.³ö”	I{öMU#ACj*3i˜«È½Sù§‹?8iş±Üoc9¡qíÔ¼Æ´6×yvPäõÆ
>—ÓâÍã$È‘„Úç-&ÄT¨ºÁÊaÆ\\Q¦Õ´ÒÛ´‘©}	ü×øÏAX®µĞ\Ò#c&„M^)6VE÷´Ÿ·) /Œ<|pGc€cK6”Î¬öØp½Iß‚À´."ä/b
™P>nw*1Ñ¦a+Óˆl¾1y÷40d1ÿ±-÷óu;+3pãªx6HØõ×Sí*$~zy¹åĞIpµ‘½•?¹o"ñÈV¶µÎfQ§¾¡¿Ö‰j)!9@iSNdjùIyæ3ôF„ymçü%¢Yyš›$½ŠáG*f§ÈİèQÉõE5ŞÎ&$ ü–’ÜûI×=‰‰ZTü+š<&‚'³rŞ‹ùW™A³Z|s‘;á¡“£Â»‰Øá¬Æ`¯+
DÙTÖŒ8ëx™‘
¯L‡
úYQ5·Šæ§«‡ÍŒ¥~lW¼”æ¶C§Ly¶ÃÇGŠÊèË~ ê;ûˆo€™MuüÑ”dxõ‰//ŒÊÎÚÄxÂá)_|‚Ù7ì
&ÍïAKOĞ§ëF_fËhSG|<%îü×#¦dËµr¢Ğmó-¥ÜOómüšHŸXtøÒîÖtvÙœ¡8ºÿıÑƒÒñAiZöJ´U6¶Î¬ÍIş‰ªqùu=¹¡ÜùÇ‰Ã=ß7ÙJ˜wOØ˜ª†«)ÉÏ}w©).³\˜JŸeÈÙÓVûŒëåRÓr³C¥:öxíÓÎrpÅÉk%¢	²!¸JÎîéŠd§±háÈæM™Ó»J³wa¡5©vE“¶€ÿœ?8é2
[ÿ}^îÍŠĞAQ#Ld^O#¬«ÓàúÚİ)p9cA<I˜õLúŒèjŸéíIÖŞ?*©Rhz’$)ÂŒ­PœLŒß•9ñD$Ù¬ml6	|¡Gõ pñ.2>‹š‹2¬ş<n–ˆ'RÍ²’¨FŞÕÑb¨bi‘éX•Åá÷ÑßxW¦ï7îb™§×å!å'’3Ök“Ÿ˜û]”±Ü¢³Æq¹°WÖĞ(Si2£Ö¹a 7³¨“©Ï6|ï
bb©^>ií¢“rÕùuÉŠHŞ\=S•7½õ˜}6s`utJ&°^Èæ+¯{ 98väf‚¡OË¿)L]Ö ÔÙ’NdCÈEıB<V$éñİrü±øôFøŞçl)btŒ5‹ˆô7”£š›íAuV.&OĞ›ù•Î‰c(„úóA²ïÕøĞÓªˆ[Àm/8èmğÊ4YA–^·å»jqjßŒf²j:ïûkÂD9.É‚Á(×—ôÄõ‰Åœş‡™ëƒ-µ¾÷w´M
#ÒêTN0Ä*¦ª<òMBy¹+ ±ı‚|Ù‹êvÔ³Ğ`QE¦!¬Šlã;b½eô0R[ÌÑ¼‡ŸşòÿÑK‹zyĞš4+€05§š8ÃÆõ-:ÑF­,d-w¡8ÜPò?7?2ÁPü¯“¾¬¢t±‚ã6Q$ëÉÏ7!‡.ÀNËÄ}>4œK±ÆXøÿCrFÖ‡…F\A‰áø×TŸ1uÒ5Ùk!!³¸Å3qZÀã»€0mjÃ#3x¿‰^fxËZ
ğ˜„şMšWb8Ñ<ŸN×íÍÉWÀI± úûQZI÷‹¤#‡~"Üˆ–Ôh`›€5y•¨mº¨?Í ç°R{jI‰x»ÉÒl0i<$âOÎ<	|G+ ByôótzÿÁ¦€fhw×fjä†ßGTñk¼&Ô4mÊÁï¸üL Bš6+Õ©[Ù\Üû‘›¸ĞÛA ³Qu_‡¤™Ö•ıi¿¹Ì8S4>ğ¾X³}6ÁşÍçõ§#Ä
z$û…©¹aºİl(NÚ9›áÇ;s)#/\˜Ğ•8şPÛ¼’Ìåq#ƒi¯æn˜zÑO’79ŞVYş`¿s½§¢Ë£RÎAc
[à‡ôí#Çä®w§ÓD~{Ë‘ä'b†+(!Zf§OÆÒå¬-ê{ç°À11Ê0TÌruJ”“å9Áœ-†68=Xª—¶	E¥‘İCµš;.n#ãÏ²FÄ#ìÆezÍmK/ç¦ò¼x$Û]¦¿”¼È3QËÿc£´‚zS¾‰rŒKT®_éY:×”õW…`/í"Uÿµ÷ùIg^Ò®Ø:.¹!@õuRæy´\ò.ŸE>[ˆÔyù–Rü!Ñ…IÊNTÄãw|ä ^ê]
 ïşQ!ë}ÂM6cÁÌÂv`DOó½Gê´…–)À*‘¹5/W%‚ï”õmÌAï†¾&±•gk´àßVUßq¾+ï¤ËÂJÅí t>@Hu¿\_'OÕPE”gj¹˜~ó….èûƒS¾mC¸…pªvBYÆÏJ|s1‚æŞïÎöÉâP	Ò/\)ÓKØò>XEPyt=emSpğÉ:ú!Ò—62Ø±¯ÊÃÚ9hïÂ5´Á¢úk@Êc­šd*jğ"â '¼¡!&Ñ´$çJuq~tD’cŸS@ÒŸË>i¹éÕNîÎÅsô\4MÄRz7ÕÓkâ.õ‚h¸ıªùê\¤%Âès(Òµ!Ù¤{ÈßOjÆ“ˆÉŠ4"e”O:3°!ªÖØ,Z¯‚¥<k°çÓ•[Éî[èùÓ	Â×Â±³Îg OhÃÃMˆ0ŒÁ«‡–’ttzÂÁ†\8~=Íİ°"ÏT¬­º¼¹¡‹qJ6›0FîéÜU{[£Æ-Ì|ûÃ–¹1¬äqQüÇ)m†‘ñş†ƒN£W5×rW3ø0.@³Ñ¹ÃdMc¥ûë1kÌ‹RdŞçåÓ*¡å¦9çÃki6ŸB;FI]Ã#ãÅbĞŒ¶¬şŒÓnÂç!‡#xU§$(bˆ#_0ˆt„‡¡Üèğvô	"MU6(×„èu“î"õÉg'àê°I8Ú˜OÇÜ£I½ñtÌ—ÿ>™A¢Ùîråqº‹Ô807KÏu(¬=IóõÏsî
™ø@U¢Öˆt®z°&Lî%20
9°CO]V‹
R×Ó_.¬âô
¼v••ÈNw×8o‰aÈ´d ~<æ¾ÁÈ³/Xb¢oÅ\:w>1â¡ªê†ET6k'2¿$;ômIÃs³âZ ;‚ïÂ}<fŸõ]»p »­6g	VZeVÌÂ5Œ)×ÿŠÜú„‹¯e9,âŞU~#iˆ=ô6’.¢B%¬%ºw ìÿ‡¢µ‰ÅØé×æQ°få^vêó\»;Ëì@XË<RágğP¤r¦æjüça¾ÆşfºÑav‡T
™+JnÆj·ƒF8A;'"ÔtÁïŞÉ™lİ§–ûÇ{|Œâiìù$çJã×û—äÚÄX¨[,œãhVc%(Şr@£¥9Ñ!Ã‡ä NÕ“oæ¢eU°ÌıCÀry.**¹‡ ŒÊDuK4ß‚Ùèh.p°w¯ÙòQ4M!¿48hVè'Â%ûXîËÙÕYê‚´“1%Ør®$dPE>„ùÏŸ‘µ°qdxu×z_í‘»foj›Mr©´‡Í½<‚šßìW"Şß‡C®ãµŞéüq=TÙ`¬+ò@Rçar×-ÿô‡±ÿz³.î—‹JD¨	hÏ_Ú] ÓšXXÌßsÑòb° Ş2ÒM_%~Ú º³ñ§}#·=äbGYøat‘¨eã¿ğZ¸ÙôŞ› …Vˆ¶”Ï9°Z°$‹½pÆ>§­ÇpÂìX^IÚ¿QÃÓ š;ĞlAÿÔÓÚª6²~FP·¤¾ÒjõW36nqò"Â²^B¾——œå”n.{–ÎQùç‹o „eìW•ÎUiŒQ/‡©˜-8>sáÌë°8€¡q¦ºğ§ğ¦Â®§?ÓK:LæôwéìJÓÿ£€äÍNÜTå]j ƒB‡)M7m8Zú…­Ô«qEÕéA#d(Ø
‰7û^Ñmó)M^b}™w;©#	UùŒUYÆ=ç&´–>Œhˆ`¸¹¤„oÉx¾ƒ\ş·×ÌôiSã5á5jÃ<g$ŸĞ·”(9·Êó) [cïH€®öªL¾S5u0.ïºôøOìãôOôXg‚|F£—¤ŠØ ÉÛ*wÍX±t»([ò¹¿«¥	6pıÆÍ/yæ7„Ji’öƒôM6@ÓcrP×£ Ÿe7æÿt’Š>íâŠNDi'òÙÎ¦CÇÍÇ:mÕÿ–vdN9	…GÒøhÓŒ3ùŞE°E©_¢iÂ"Î86©À8
‰5tüDò.8´3jˆµÜUÃìŞèÑ%4T¥õ7ÂäcŸeóø0WÍJ/©)„ñ¾{¿ #&ÚKĞcÈT…ÏÿA—n1jlEğë:RèıV@rpÊ	VAÚ+EÄvá”§n•éµ]gR+ÑÆ%û¯šq°@Mr&ÿÿ@Ç­á0!)õ+>È0<ƒlWëîxº„9‰·D’á€ÊM©ş·üJSb8m=¿	ùôLH	@aÄ’—ê7Åiùü¶ÆŞÿ×gEQÏ%ZN¼s%ƒéGµœ|s½‘™ª~£¤ÕOøbN_õß*òİÍp‚j¯«?×»xZjèzaN@éñ–=_xÜ¦zĞJàg<)h8W§öDâû“%×õ6/í¦bÌl<‚qş—,rf7ÿù™2ñ‰¢‚(R:•ÌÛ¿ë(Ië9ûÇ&bûÊ	zÖ·´0ï4™M)'b37÷#ÌÒÆ\$2¢¿ÇhÙãÒ1ºµu¼öİ‹™Em;Ô…ÇQËæçÂ´È¿|?=ê°‰å¾W3ƒVN³)<×ÑÓOzYã¥D¬¥/]ûä'zjñ×È„ö¸{Ôé\õ³jOx%ø¦Å¤¿Lc{IŠwŸ~ «*&Jnr‰‹ˆ¥HáÍÃ5ñî¦~ì~ş$›‚RÚCş-
ÙÖåàI(WÛ¾j]'±”İMšãê8òáã#\	ùñ‰Âé,Ó¼Œ®_ßpıµÄ(…şS”»¹C¶[$€$&®_~Ã	+Ôô#õinâƒÂõUĞ®®ã…O»âMèÓĞjS9CENyœù’¢­›¹'Õr5¿ái
—~÷Á¬ƒïuébÒ„”¢¡Şûm5¼:¢EtÜ«³;Yg²³a|%b|SĞW8R¼GÑçAš=c(W¸Xú(.M_5ÕH¹"×®İSD7¨ `Î;å°m/îóş™¡AÛÌœáÃÅ?>$ÕOß»3^ëdûóó$,RQÜ‚1uÃsììãdsÀH«dÉƒ»gAÌÍ/å˜6¯y*å+«\n0†"ñi«ØAcôò[ı+õw?Ô^õ¤Ùú=âaü ¬z1°m'¼é?·c!¨{©…9¼ ÷ïT¢Û] P×)÷¯– 7''“†c!
_bûI[À¶§àY}D¾*½ñ]TL51r.eµÛ¸\À¯å÷9|ÖÀÛfË¶çšÎŠ¸6½½ØÄa%ÀÀ1Y‰óà¤Ãõçu__¦`&‡wøÖˆ·°ğˆEÄåöºV¶/³~[•lá˜@qª¨69Vìß2	è‰´½øÌAÓ¡Ç‹wIŸŸXïg˜k7•ïÊ8Å	ˆæD@m»µâÆ&xZ¸
ßQÕQ…¯5šBúŠÅœ´ h\ª¸~„æŠä;ÈIYx¸Ïr1—ŞxÜ±¹Ùùöã>ç,gpàüş[•àdS­UxšØBh£ì)ùÈš{I½iİ÷c¯kã{şáw+ÃCƒæ"*÷…’1§Ôo.¨5Ëújôp»ù^NÆ¾×çñ<™<]ı(	ñ€9'Ê#&!8¨Éo²Òa³ê…»ågŠK•IfwxÂ×÷¦1-òàbmLSD'5Ö³¡–\Al\/D9VK£pTlAç{¢öd—?#k|çŞÕ*üÁEjÎ}QY{³VÑÊ0½¾0]H.ïwŞùå'´"‡ÛÍaÜ¾ß:âUÑØ}Èµ¿?+áùI§¡€ğç™M¥_>ßè Ç‘7ÿ–ä/â¾èT½¶ÊD'>ªÕ¿¹Ïòk?òÃ~¬^¢[A#àº¦¹[g«KxpïWS,l4]@±ûìÈö™ş%Kí<W³ª‰ª6¥Ÿk×6]uªM±)bp†.uÜfVn)ué°Wxæ1åQf‹~ÿô&	e‰‰H	¾Ègd×§­ó3+ —¨³•hp²Öe©Ó™ÒB):7Ş£Œ£HbíªòÆ_#«Bä¶<Àã„,+v•Ç0¨j€Ğw«n™Å]$€ìîLˆ2h´ãl~ñûPt]ŞŠ…cåËÓa{¢ùcĞùot<².zeªù7<P ûïºTBoE„ ÃËû…‚X5¬¹$M¥qSMõ~˜Ï^q2Í€ñ1ı¾\¶ˆLøÙ—Ú”!£ô&¹N&L™HÜ{ıw¹EÚJ·ş s´İÒW0(¨ŒIõŒÔĞÇ«ˆ° "À+Åã’$h!®ñ!b(¦g27±­1=kh+…·4‹® 6<¨é¶Õç8Ş{Ì½&QôBüBàhÒ“—)=Uåû3¥Ë˜)ù®|ÉbÙD7éËR@ç?Qùïso}ŞUSK›ì=³S¨ğVÏ\Âøl+5˜D%õpyg{Â†"Cú®S(\.n¨oé“ıÓZÂpf ØÁ_|¡¨e¤„ò>,Ó”:Û#KŒ½!uûM-ãø« ÄÍõ&`´Ù¥ç¯¾-ë::Şœæ7[Ÿ¥¼X5©¸ÁÚc‘fB-I€»ò¢ïsÓ]k-ñòb(Õkñ³ÕºMmÙ…ÛÛ“.® 4ı×à ^€Çxg¸AÀ‹“Œ}ÓxÓµ˜ˆXõŠiŠĞÀo-|ˆ”{fÔ„COn?&S8QiÒ¶¢ëîl¬BÁ½#gùÙG²£I«8Ÿ•«³ŞËbà¥lõ<|ğ¦mÂ¬8B‘Şû¨±ïC¯9vÈP>ÿÈ^b°Œ€\úñJÓ¹	”$kÕß(ÏuàºÔE…šCÃÊsØq·ÿ˜¼´Y(­t©iMŠçÕü"da‹|°î2øTòÁÏÍè, „UÎ3óK•ÊoÄïƒÉ—+
ÁR|C‹ÌÈúFg‹i²ô^íiJpq[R]`v4;5€j|áŞÖ	®ÄÖfÍØ…ı_²Fjò9«Lëó;
­¬Îª>×Ã°÷ZÄ×¥'Ğ—=2*’›ÎX}¹i.WÙŸşú¼ZÄ]	­ccÕó˜vPÖ>xßœhŞÎÊAÆí˜©nRh H¸ÖYR_‰_‘ïüD-­ùµñŠ”€»!ŒÔFÙ#K~­ÒÜ&·ÈÚôFu
`–*î+€§ªG+aûÊq˜ÑZs§¡²„NLÔthrCøÖœÍKZ1Q“FàâD;9nM]J›up"@”„+69ĞA:Úå*È¶*!¸„½7¿Çîõä™ÏµN¹=@ÛJãUÄàmo+^Xğ~P6ñ³ìù>wR¤WT3aK„jb ¬½¤dkŸ¶yÇÁFavü¦íşÉgŒ«õ*äo”¶×U%/fB˜êÃqG‚ÌŒ9¶Ã$&÷¤ÄæÑÉn©S¥:•³'ZÕ¡VÂ9¥ÀÎVL‘Zê‰4T\É4ŸT`Ê¶åFÀ=°cÓÚRâèşÏoø¡ê¶2}jÀ.6kSU%@_Œm!bï*oa,ìHìşÒ<BğñÜóP¹Çpo#!ÃŸ¥úšòiÃBb'(şÊÿéºŠ{9‡öÙd«2DR$ÍIORimDºä€<»eDht7_š¯„m^P’ÚÌLJĞw’îé0ÀëØy‡Úr“«àŸˆ<Á¼Ç¡­»yí€<šl0NØ\¬ÒË~3Ì¿CãO­âÅ…yåUÜôøÄ‰kåôvøõ§ôÉÊd‡Ñ
ülóõ3Í!ÿWˆæ^™oÚ#ßñ‘
¯€ªåà%j©ÂˆV¨íF`†ÎÄ@rP¦°.4fMÒ²ÉæmĞÁ•ä9T®B·ŞÆóØK•gş¹ê×cë{³«Áº?'SWşÿ/Õªp±o¸ËaÅ©ä;Ec@¹™%¸ö6iƒpô”p"éï$Å|oAÕgVZ²ö‹Ìì‘!sí¶ĞñĞä—KGôW\Q¹wÄˆ3®üÊohŒÅ¤ŠZ/<ÖÉ_œn`>ªi{4h5L'~æéî’ËşĞÅî(Ñ‡ˆw¤×<LêCrD£9¾S¹ß”.èÏ¤Å576/õ@·¯NEz5Ğ'*MıBî#ĞIĞZ¾ıÄQô+"?|½6ñ“¾`ñQ»4éÕ€lyRMR£§İ6¿!SI“ ivz[ˆ•¿¾YR n'•/<	ùÈK£Øà'‹t`8>RhãïK«I§uÁµÔ¥¢N­%´à·9ÇiAXÔÕıË4¢5KYp¯ÅÁE`,
{pv+(›äÕr‚´•zëEÊA‘‚fg€]áÙ.²IZ˜×€oe5Õ¤ÛöÇ(åpVë^¸YA¥¼’k‰L‘Ësìëİi	=-ŠxÀF%ù€‹$¯/Æl¶ÕUQZgµ%EÕ×ùM©3¿yÓ[û,àĞº²ëª}‡O°;¶ş?&Õ–% îjqŒ§õ,qå£ä†§1E·¯«CcüÍÆl‰|¦MÌ$MÅºû[äjø2È››™0ËlŞ:AQe ÍRĞñ²ŒfasA¦?:Ap“Ò×ìƒŸYÙ¯K_4y¤€½+.16
ıï»R¿X,††>®¡€½ìš÷õ}¶Üª¡Q[è¹eƒch,É ¨:»j<îL_ÉVYÖĞÖR^à½½”	û² ^ä®»!¦Pp‡xBc¦ªò%ˆ-GØÇ¨©?ZYÁ”¾´€ê	Şóî±Rª°4”¯ËÊzjÉßœÕK½Ôs»§HM0Õ?'ÉVõÜ+êâêC3klqùí×#½­Ôås„T¡éKöuš÷ÿ! B[ƒ¿+ˆ)İÚÈÒŒüäYq2øfŸ´ê”%6?X)¥‹õY|Ì¢okc.f´b¡@–ìıƒhTOÀáL³œÏCÀ½ÕX«ç}Ù»ŒÛ“¯×~M£^¾;*¬ÁãÉ°(şÚ‡Læ 7T*ÍZAæŞÂ¼ò‰-t¬úkTM£È¡(‰¸‡úc,°g";¢m
†(,aYVgóô•æ²OÂ>>Uo*P\”†+ƒoºìŸ¦†BÜÍ7–£?üŒÈx<9ò>æSÍ²‰z+2˜‡÷L”+?EzùŞ&^§ò‘°L=‘{^NNbù“«ŞQé  Bù¸*/=>ÕÔ¾åFŞÒ½Ù†Ïİm¦x¥¬Ã7UäUÏ„XÈğìö:j’·SëŸÜÖE&íŠ4òÉ ¢,YuŒæOşÎ‘±<Ob“Ş>qÄ~<Úá¥³SX@Šÿ¢ÕQ\ÜBÂ½Q6®S³©¯—²|Yş¬ÈOÆ‡Ş¿QØ2'}ywívyÀ6"¹î	ñ¯õæH.é™¼â¯¼Rç‚´ÔtbÜ}æ§sí”–îü BZò…Cú&™DN „ÂæÃ½“Ìˆ“¥±Kàg#Sİµt•´xïÌ=ÙÒDjàtÇö21k¬b¸ãó°¾zö]eCŞ~¯”æ•wŞ´ D°ö‹nêÜÀÂ‰4)£1ÊÇô)`ıøµ‘÷>Ù¯FRµ\­è¹;	ÀûÄÛäÌš÷±|WTÜ‘¬7«“ëex`¦ˆP÷1Fblù#ªC;mß8É §èy
=Ÿ(	Ì„ÓÔŒO:7µJÑ|çgúõ¬_~Áeğëñ(œÖl|ôÔÈ#"AşçºË{’ógÏ¬œ8Db±q£™;Ò~â7Hø›õ,`)ˆĞÂ`=8½íixC’U¶©'_yÆöÕÛ~¡$œÇĞ§Ì%vÚßJ0GÆéùZĞ#¨J”²ä~<¬Ÿ¢Xy1@4ƒj„üÂÂejø±œœ[Jî-v¬¢Ë¶ı`»Z—3¦[{tèA­×rjß‚‰kÊÖ+3-„2Æ•ğÎ¶ÿø¬hêÿşŞŞusa]X{>Öô–IWf¥é )P3³Ù‰ÓŠLüØËqğQ3µt/½ö$y‚,ûÌÖ4Åo(ò³}4DSL®¨çtd„U%ajaÅ–ºÌ©å°utÜeİ¡ûüŞÒx?¯Ì¹XÀ 8LVŞ/k¨"Â~W$&å¬ô‰¼$$"î•vG$oOS9ş\¼iÿ}ŞıAw®„ı…kær«²aV=ò“A°|AŞ…’ñ3»ºúÇ²IÇªàfë%³·ãù¯T6‘ªAU!èù³‚?…SuFÚ/“¬Ğç¯¢1¬dUˆ?‡ÚBhİ?½úÙx’Â•å:üÓN ŸzF’Ïte÷¶?¤,#S6üL/?`a~$LñœËæÅªÚ*=ªà@jàföW3>!6Â tMb¡b5ÎÂWìVÇlgaĞgLÜoT½bİb5èš¶–·nˆ oÁVš‚¨ÿš–ı§0y‚@ËœI˜“¯~i¤-kKÈuIY ìš/ğ¦jÄ¾ßìŞëÁÖùL-D[Äè¿m½5ÖgmÆß”…KØ[vÇÆö°Ø<)å›¡’rè,F•ï[Xàz†íùá'æ†5ºäo3š^Ğ4#•EÌÅÖ¬ÑaÔ["“½–ÍÙĞ!CÈù$>~é9ƒ/\ªCšz~Ïß‘°IˆB['btNÒHÓ[Òì ¶†æşcg…Kf±wá¸åàäÌf5:XÃÅäÆâÿŠq aÊ‘6õ»6^^Ğê;^+ê¯=²YÜ‹<Ü~Ûm[¨Šo[ÍÍ†ŒT+6óØ£5L8Ù“8:Õ…ñ¸aRååh¶@†$±î´«$çïRÿ r'de‘¹cB)H¬ô\Ù¹3¸“÷``È]=I›šÚâ<Ûd¤„ú~é½Jbå&å7É<iû0š,"«ù†^ØGúê™+N=!»ä¡OÑ´Z€ªgÔ¼	ôzPÍùM&ós¦F¶N:-Xğé
˜Š{ŠáÖíŸ”Ÿ¹4DrÇ5:}£b8bÆ'^e5Î8*ˆ€ğ–û~'Ï|°i:ıW³×8æÊ°;Y2j¯ññÅÍ@¥µ‹ó•Gèî *5nO.ã³¨>€vT¥hÌ¡fÓ¶.›v$9Us0Öôk(ÑyC‘®æVï¤©‰ «W™¿²ß‘Q6yù/Ú¤µ   aÄ‘lÌ„’¼ Ó¼€ÀAaß±Ägû    YZ