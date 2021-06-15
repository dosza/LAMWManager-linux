#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1913663088"
MD5="2f15bc21ea8cacb1909469b5a71b912e"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22284"
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
	echo Date of packaging: Mon Jun 14 22:32:10 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿVÉ] ¼}•À1Dd]‡Á›PætİDñrILÛ êL"×TêZ˜îÇM¬É6ƒ‘6³¾º6 u|¹-é{ÿæ‚½\dî2Xÿo©~İñğB‚ˆıˆÇŸ"à›ë1³Û²À(¸=‚Û¶<XÌ>„âf³tç–Şİ}Øytš"H&—`Ç—k©)T®9ÒïİªvŒÀŒƒæ€ä	4Î#TON0 ó#íÜA«Ã˜Šîà[ë¼Uó1íªİ"5^<VCº\¨-&Èx!ˆ@…[ö|´3Ùšà.ú7ŞŞ5ÀK‰ı°³Ë«*”%rè„Ú÷‰•bÖC2c™›ædb].×z;Ì ¤şj“p`‡ìâŒÌ¼øïåhğRÙØÈ<%WµÜ”Áíœ„UÓ,ër¤›r7À× #êõÂQxÊÇnL'Uém8gã›hõµÁøÑAØcPœ(^ˆÄ§,>àñÍœQ¢QÿO°F>€B‰ĞäK^‹±ê7{,ƒÑ6 üÃ²!ªˆEÀz²IôÂÒY==l"-2"¶°—°İMó˜ÚÓÒ¤P?×xzÏ#¶hR«éıdH{BŒ~b#– ×êa€ïu0Å‚ms¿Í¡ÄK<òÜyØ¼ùk¨À/>P°!=VïËC°—4úÕ0÷ÖË´õù£áâÚ™……×kXÄWæeùÉùFÄ#–{ÄÒ—´=_„qõA˜?i¡mp‰ú«Èx¸b@`1ú|¯*3ÍÂª3×ÜæÈyGDŒË*ğã¹¸D›»[ùº ·§4õÑÂÏ?wœ³]Š Ò6i‡-İ[³àe°G±¤
·…G3‘¾¸sµÛN„1ç	€
Í¢Óô=ÍckFF¦.L¨¶ĞÒ‘îQ99àU·ÛcÆsoš¹²}2È¨ç¿’V
Wİ=dD›2µÒú§Ãx¬$Á!ÙG§{äÉû&ˆAÄ¢¿¹Õ\ªlšJ‘ŒO¯Ê¤êXs®Æ”k)òŠRn‰'ÔšK§ÈŞZø¥—Îma¬i½Ïüq­¶D&Ëv×BÁ§Vÿ@Ú,ôGÆ]Àìc‚MğD}ÂUXéĞòåh	œœ]YÉGÙ|/+éd„Ù­§öSpıñ¡‘vê“mMroB1gG ÃAØ¯£eñÉ…Dkû)tE.­Ú;ğİh¶ÆgĞàİËÔqe‹Á5¨ê×Ä{8ÿŠ6÷Vn÷œä^ôŠî-˜pa¾T*u'H83Òv§´áğw¼_tTÓ6PFÀ¼«Â¥¾Z*ÉÓc/—ŠäkÏÄ^asÊnÁÿAlßXQœ¢ÛS§»;æb%X¶ìû×Ú
ºVCïgx‚*V¥G"Œñá|Yı8èa¯Öµ©Ú`T)Sá'O<•”vòÄ:ş¼®ìU¿s†¤¶H<†z±qH4yüş¸”Ä šç{»\…j
6í }µ¾6¢†Jô%1GU7A-°C1ÔÇºlÓ~ÑĞËtŒ…—>s°ĞÿëTã£B˜—$$‡ê(	PZ} WòºbAääÎóÅê«`yIJû—/E›«·Ä´ƒ¹nl=Øhü®¶•Ÿ@lıÈf?P.…˜tìkv9şX¨Û±©×-ä™¥R-÷T=\~æÖ`$*ı˜rzô;z|ÂÜ¿	ö’BWç&*:¼Ãˆ¢¦¨‹‹	ØX›Ùt˜xQ±õ|Özö9–m T^¦Çºk½òµyk › óŸĞª¾
cQ1I¾#«ÛSPh•iY³»­ø‰°Òjÿ¼Gü‹ÄÛıUrÒqİı®ŞJ×-Ù Çğ,Õ¯Ùù·™îTÌÜ+6>zí—Hşø™Õ²÷¡U¦TH/ÜÚşU€ƒ¿{ª¤ø±ÜÏ·‰gçŠ-Ôí¨TıÄ’D,H8!İ£_À2'®Z¶~^ı8a‘*ğÎıTìß ‹¶ÏÃüì†^qxµ°ÊÊÜ%ÁÇõÓ±Sÿ¡g{pÿß›»u>ïg€¿d0‚ËÕª–U¿|íÖm³upığkçã5±êšwãpˆ:,B‰RˆA”è_{óXa—øÈFp bgYq9+îÏEòi,ãT i ØŒÚÿŒ_ûŸó†Ÿ<(ÛàíúÂ­w¬ŞâdÚwx`¿ïFIÄAÈ:Œ =[X{î!ÖsZZ×ãØö®Aôyºı„Åm¬$oR
·’ÙĞĞë'¼7Şr” ”ªZÃ\\$ˆ™Ì¥¦¡ø€7Ç¿¢{Ş­Âi- v†S+¶5J{ƒó÷Â Ò¨;’~4(gáK}i%LÔ3r¸Šİ˜em@XÉïÿÍ´Ï¤Ì:õ¥€Õõ†İØ¿xAƒóŠ:Úê¦b9±4©“Û^¤mßäé©ºS"Nüæ#@%tY-Æ¡Í8Ø÷
‡ÀÁò)ôPrC#¯DD5~»Ë(›G*WÇOv Ìë@Ë7¹CşgY,Üôl¾cõ"Ayİåí5aà)Òi£‰ôÎ+-Ú°¯ïï0IÒ#R¾eı%÷»‹öoi=lı-y.?-¡~ÍæÑ{ÌZµªÈmğòUçs¿ ÍëËÂÚir~—Ï÷‚>6—A‡(‡Pã¼|Æ%"$vtÃ$ ·ßn¬"÷"‹í|‘yxKÅŠéZ'É—åÀÕ•Cğ=·ªÏ^Ü1f-ÖhkBÿıØ¡aYYg0cá“Éµ«ZE'Ùå¸ |hRğ|¯ªK½Œ+ó~’ıh¤¤!Xjo:¤BO; ‹Nò—ßóËªK—RâüVwÆå%Ù¡÷Ya¦ët-	Kw`ñ³©;IX;ºƒ•æB$øêëUobn.#':¨g=]¥ä]í”MHu	Û|·ş¾a7i‹ğùVH´f3İr6úİPşım\š%­íÒ@KbXï³å<¯4é\€ãÆ¡„Höì šäï°Öx«tA4ÊÕ¶ÅˆnXˆïwn+1‚”´ÒÄeæ
¢İp^ó]S:…zùÁÃ”ŞËŠ™ÎZj@*åƒ:ûñ¾@˜Sa–Oéù‚Ÿh©ĞL,°øÎTà§LrA™ñQC©ÜkcxªÛ–»Ş+JÊ›ñÏ§)=ï¬H›ÉØyƒ0yî ]Ä0ØôÎx;ñ	ÍÕÏîëúQÈØ-è #6a‹^mòÅM@öÍyç”™£øQ%î[ç`ûqÌÔ'œ®bÃ®®¥¤‘SœQsÅ?êÁr½dÓaO™ãÁµô¹´M[-ôÊd´ëšZm¢Ç7+šVK¹î “$¯f…’~nK¹zÚòiŸãHq¶*QÃGÅÂ¾…[°e¿ ùğ?²àÌÉsêÈD6j´6E'qö„šX¡Ô„$|ÑŞU`½:ô—}qu„Qè<ÛHÈX~K`@ˆÑÌa!q¢	vì»hêíÍf†¼7ı¥]‡j_vfY7°uYÕ±ÂÌˆTaÕDAs”]F¨fµs›²•’\6æ¥ßü)JP=CËÙü¢ïe:6zÇZvl5¢,ÛèÆpPÍ×^¡§xí;Í*Ä€¥^[m s¡?¸åˆª<|«!¤0s1´I™•/Ï¤;€™¿gÍ)ƒ¢-}ö­-U¢æVsÜË§Š‘ÆC­æ°ŸÔßT1˜ÊØ½\eöø¯b" m<óqOm˜h}á­D€[mÚv®TUÒÀh5³h>|È~»‰ëßXô
ù0AÖØ·Ü‚d7#ÊÖóŠG­jõ!³¶Yú–’#cCˆ¡rN+µSla¤xPZ²î!”¢tQÎ!ı5ü)÷ê[é–ëÜ›‰zÚV¼¾Q¡nÙz|jFQ6yKı-å¸ŒB¢?Ìuiø¢ûB¤òg ;Su7Œ°¼ÃÜ˜³§]Œ]cÔ]7 3 ô#iükÛ"@PîNşg!£y5*)I¨•×H!‘ß¦]OrÒK6Æç×ñB·)lOÅüp¶*
\‡™Bö@ìzm)WãÊ¾8½K“›$îÃùœ×íŠ—¬Pñt=%ÌMÉ!´¼Å8SÀl¥ŞŒÎm
PfFHU{Ô2aÃC8=ñS©ÃD½ZvCóÿECSì“×– „Ë\ÇÙFë•‰bYÔQ—xWÔ“äæ­‚!hB^ şÛÓâ9‘nhØ¤æÙàôšfİ=M‰7â…ïX§uVbÌ`lPÓéMğ¢ÕqYıá[ÕAoì…úA]fğH–÷ÙdÁËhø!®$dÆ¦§®lq©İ©±R¾ **p+ÄBˆ¶n§²ßgÕ1›?H-Ò@ãÁÈŞåÅÊÎšÒí{I¿ñ ,pµò3Do‘£`­JNéo'òfµĞÁ–^ıˆÃHÒáŠKí÷ı”Æ“|›O2BŠĞÒÀ nj¶;õİ„tÕ2¢ôîÜ£z6+Hy+ëÿØŸ!°@—lµc¥ÃTŸn®[
pÜZòïô­>ÌrÑÓcÓ^Üf±áëD­³ûQ¯rì~±–İ€›5gAÛœìm•-§;ıæ²
ànŒÈÁ¹u
´­Ñf—êmí*Ër—»İ äé‚øPÈ´ŞNØs9ªïÕMºSr¶…)°FÎ1¯¨b¤Gˆ­3ô¦#'y`¹‘dæË×Ü™tL »Ì+N–IÊë¸­î ‡¯)Ø+¶ŞZ·±u`ÑÃæì.4…ËêÀ3ê!´iá‹ 0Ú ¯"ÓJ/ÃÃ“ã#¡m5şèé«’›œb´–ŞêıXı—ãÕ®™û‚r½‡eÿœéÌÛC#pq>¦§yéA)ÿÏku–â+±ÁÆyÌw·h‹S-¢€yâÜ®²¨íõÚCZú›“t B
XüU!éõÊOµ|ì)ÀH	Ÿç„!x€*ª0$NÒõ¡ÙaÜ²Bhi¥Næÿ5vú§Öë‘«^YãÀŞ±ê…ŒúÀÂ£}ì¸ıŠH@òpÓ•rÀÏ \A_ıbíWáEg·Ã;K“oÏW”ûLCÏ6Ñ{&èX˜-`]ê!2“ŞÛg—ÇBt•t·Ü-œÈ…3#Q¨^joÎ’-ÎkÙ~ˆ	qŸ²6Á\`È¤æ ›ÎÕvIçX«³¶¹î|×·¦‰Ëx¤ÛsÕ0mNC¸ûÃ‰Í«½¤7Z š`<9f!Ö÷%÷`[rç-ETz…ßAÄ5úT#¿çèĞKn=‰‰Ğ*hvqÑ#¾öˆ -~çn™â?:¯Ãx\ì5óˆ±äò&õF¼±4--ójû0Â,ï(déi¾h7
a]:~Äµ^À¼vÒ×°m’$(AØH¸-Q|SĞÊ¬”b­ä·ë]6ºï¨ª–8×—Ï³¼?ÌàÅ=×zæÊsÈêb«İÕíÄNŒÔ|ÀğÖLàt&V×üë¬3áš,· VÓ{Ñ×È%\Ô†kÅ·RÓĞ1V·n÷—ˆ dìY–õî¤IËÉÀó+§,ù‰ŠÉ©Ó5*§~jÛÚü5òÜu™6ıÑÅ%ZµœŞ˜Ó«Óì¤oT®¥ü)]ï¼Ç_˜¹~%¿:¯Ë„AGó5wü:ãİv†ªí:%\‰Ñ„·ïù,*ÀšK³&ÉúØë¦a9ÍK_k°SÙ /‹\KõŒ°qRYµˆt{;u–Y¸ğlçåY›€¦a m35ÜLåÈ(KŸh˜h¨ºŸÙYUèUÉàò
»*{>*n\µ š|…wé•„•÷JEB{Jee7oKÅ·¿¼£Ù¥`[MlL]=°‚©›„Pwñ;h´bˆÓúq5Ï^Fø˜gá³Mˆ²´œïÏÊuŒë=Ÿ†ûJ®dÍ;0p‚â?™t­AÁÀ”Û±N¦Ø!o²gÉÚtBaÄkëónsi¦¾²B&élÚ7GE"Ò><WZÏW°Õ 7ÉLuësk7â-%¨Eúj:ˆ’[áŸ™—,Jåøs­eµô+5Iê0O!´ÚéÈÆá¬¢ÛÊrƒ5¹fRH/ÇÎÓ½šÅµx7Äÿa§°™ıbú”Ê9ÿ©á©—÷NËs¾ w²Éäo‚GØ~.TÚ-=Ìß·“ùˆxd“¿F}Y:´Ñœu´Ñ™÷É¡ùj¶õÂcÃ"&îØ7ùêéŸÿßjXÂÚèldÅqéäjÖi-”û_ bßìG¯A<l½Ï"®óÚj0èo3Ï)a!£É‚.Ê80vÈÿW§ÈÜÙ& påPT=ÑeIØŸ“R|Š¶=‘ÑKiy² Àòíù7ÃŞ[I=l¹Ç¸M¶#…ÀÎÿAºBjîkàfßXæ"Ñ}dìEBLZçz>9H³	˜J·ÄñÉÈôä<ù2ÏGìáLIQÎÍ$ôwö¾%ŞÄ‡…¨Ù;Èô´óŞ5Şœ~Áñ;ÿRTL¾BPI
¨IÏ—ÙÙ:Súƒ_Ş°k;ÓX† <´¼q1FO‹CèGÿ;X·
jŞºZ]‰ºÔŒÒ|áÌg³ÿëÊéCº5U`\69º¸^UAÒú4 œoL¿oŸ,Úv:Hó
ÿØN Š}ÑøYÃ®JÔ×dG‘Î<¨dv¦şØLÖ©Ş…yàDj‹JÈ#9“¯3!|¾ğ#\à×Æi¢1	ú0•åT®ğBRƒ8(·«çÉ\™0¡ Ÿ-û°w´DÍY‡Xà{ÑMq=vï}Àjûu/3|ZêmÄigÛ„Fvd\•^Ç5½Ò,şZ$‡½Oò€§S$q ‡Ú=ôQ;x·Œ%¾¯X¢w˜8áI°ªæ]ôõå¼êxÎ=Ê¾4ËipĞxî-Mâ8Û„ù¯>8lRfÌ*\Uç
ÎXõiÀji>=ARäh‘–’P/®8ßùñ(Pœå>90{s}ùI
èĞ[ˆ~°Ãq–GnšTwu‰¶{Bóo**´%dg‰+d¿	Ñyûëv 3	ÖÈË#úÎYChÔˆÒ:‡ÒühÁvP•WŠ[…¸g§®s2åä.6¢"ó„èbˆøX!¬	ßw¼JšnÒG?öíÂdéPÕ à?‰*ˆŒËzŞ«c­Æ¬¢­ä4AKsP9F?ÓÏnˆõÇW§ÊÄ5ùÌ£84Rê_ÌËuë‡+ìOÜn–¦©æõnş/q= R­ìå©În,È„Gñı‘W¦a1Úö:€wLìNZÊã˜—û|Æ~å^¨l€lƒ´ÓÕ±¦“¼Üä¡”-?ÆòØ÷Ö¯‹p8ƒ}Åñ¡,ù¯Q»ñäÒ+J$™•]±á1SÏ™j‰Ö`9š`šG„®0.møAúDBv`rŞÔÛ~š".`û’«gz#¡(²ûs/ğ.]°ãò®Õ	@tq¹D·¾’” a{3S·%±ƒ9¦:ÔBæ(µÂXM†O=Âìªaû+ÃœºÎf^jŒ\i‹{çk;Ú3á0`J}<š§EĞÙõ‚È+ÁRO®YÒ%tøhKU…EíuVZ6CQUKy8,qXFÆ4ı…4¤0{UÚ…ï^õŠjš{Ÿ´Ä³\UòN ğÔ*‹¦ŸğDğ1*†ïpõÄ8rÄ°e¦† %œæH±Öbl°Ká¬•p+Zí¶{ns§o°çµu3à
AM¼}ş–àì¾ådS<Š²É¹ÔÉ|#Œ¤3«'â|`*Î“»ÌQ“
ú—a8ˆ¬\F[ºµš‡«øıé){ˆ$µÏå&SÑ.)ºÜş„3 eİWñMÇ¿ú ²$& ,!ºôu¸	¿sßv+Ø,¶l&3 CÁşŒT ¬Q±ÁFmKÓìeÆµÂœóœÌÒ#9‰†P‹/lÆx(BĞ{%åµïùY†ßl¦ô‹çG¡0Y]jñ\Ì1J¬rƒÁŠöxÉlÏ…go™Øº'¦#9l¿¸D<9uÆ =GRòõçôYœÍ|,1Ôcø\Fl1”&}]É¦~B_pµKİ&6´ñÂ=ĞQoÜáqsø©óËÀo¹ça^×»ÅÊ3Z¾Asz‚<ŠŞ@~Š%¾ è
˜ã³]×8–£G¶ÿ¡ƒÿ*èû8‹Ò§k+{ÚN<O¥ªœ¢ğ»Í@(ÒÌä,×F•:)XùÍğ§nâ;È71kÌ©eÜ>_’BŒ3JXÅ!Š¯õ2dÜ/1Şª­Kj2:7!ÂèjF‰µz·1İ%ï)òLz…˜¬[v/x"SÏ÷˜óè™©/Â¡f|¥5ŞÛÊÍ*«îD×[6Ì¤n‡¿Ì)7{ÊÈšÇ¸á¬Zi­ğf
½µşÇ†Á`nq¶k5TZ:Èãe5øZğlÃcW§ÉB×Á‡C!9KŸLŸ§Í» [€Òe¨]¢[Ÿ‹â—çV¡e@«IHµ«ò4"¦•ì1Ä:&}ÙìJJúôN/!şŞ£/L¨—ğ¹ÃeËÖ56şŸ8æk¤ë}/ª”]pFÃ€Ù!k»Ÿ»Y<„Û“'K4ªØËª6h¸¬ôl8‘Ø4éXdu°Ú3#Æÿ13A7„4±ø¼MHüØx¤›yˆ}1ce,ÉH‡:IDT¡ÌÎ4º+,`56€ Ò+#MUÃÂƒİ:r$æ/€€R`hÖöâ¡ÄÃ[¦aV“òæúCŠ1K¿Î2š¦áŠÕ¬‡ãvª•Øº _¸BèL0"W[d}h°°Rf©Û.y¯Ìş§¡ó¤ËKBmlÃb*(Q…²w*ĞKŒ2îİ»-IÛ ÃJíñ ”¨ò`•õJDñ¦ÒØÍ‡¤¹íz;D:íí¼“K¨­2+df·t³‘h#=õ"_"qàŞYÃ«ènáNìÌì‘•îV’ <Ùç}¢ŞP¯ø	q9O¯«‘_TZÌ—÷MÎÇl¢,¿,;MšV‡ªÿÙµŒo‰_tk²¬ß$=
Ô*øzdR0ş')¨'GA· [ë}àšJ‚ü
dé¿X µTí<yùùLjˆ,LØã3ˆıoC¢P—Ğ Fk[Sbø+äÎ€Ÿœú&ø×!Ëö$Ñ)ùës‡[ü+†O˜¸”ì Â¢Îï=,9«’ºñÄéqEtÎÁggœÂ[í¸Øë88ˆeƒÉàã÷ù‹úımkül{,^Ñ¨}éƒÇªô†B˜ÃíŠÙñ¨1–’ÕTNë±7je¸»j
(¤oŸDRrš¥¤ıóA~æÏ¡«ƒ,ûê«™ÙÔm~xJ%~r}ùPQÒš~pæ–§d	mÇI\<ŞY»hPïDÜ:º Œ|¯¡QÏoÜosVNº|ŠäÿBî?Ä¡Ã-Á¹}—óÁ¾}‘2Ân—ÉŠ×)ÌŒú Â ç¥×ÛßªÖ ‡tHFëØNĞWPI¨.f‚ƒ‚éóUjØ1
ÅØ°âdø	ièù½“kïâÚ}¾\…·İæÆ¾/³Ö;ï7#Ÿ%ôf€<S€ÙgVií„«„ñGÇø½½iUŸ"Û;ù©-‰e‹ÔAŠğAå¸%^¥V;ä«U_ŒXën8QJMÅ–âÌª&4wÏ¾Ãšá¬É
»× Æ4$\ŒŞ_Ä±sç¯àöfk¹¼;âÈŸ!şú+‚İSØ?'a¹”( (kZ†İò^òµ¨8§/Yşõ%CÛaó-Í³F­ÑäÈhy0URJô<:&úH€çÊ=Ù$)n>À­DËıÍ¸š9lõşiLK|2•ŞdåìBÅ7®…ã	É(°%(—êğù®Ñg{¼~İ$¾û•2ûÏ¨fq²ÛÌs9"bÎ#Ú®ã`cÌè –Í
y÷l[ÿÚğb5FÚ!¸¶·`¯br‘¿¦ÙîÄ½Öš€+¦ógADI³äÎˆ˜´d+>'1ië2ªt##H9Y6­¦$ÿ3uä@…ˆ1âÒJÊG®™ÂG`lqvXŒ3½ÉÎ‹ÂëÎÎyU ÃÃ¾û¢ÂÚ¯òbŸ\î)Ég8»Ôló.&w½5ûYcÜŞqL@éôò¾ÃTbU«Îà–GDöİ4äuy‹[åq,…¹¹¹h÷eû-_Ñ„pªV®‘ºNËéÚ¢8*x;é„›ôÖ¯)¸1¨9y|Q†Úï-§a¨ÕDúQ¥mTqyl™¬–[‚2%—Ÿ3.”+jı†Nmü¤8™ğ{çåU8ğwsåÛElLş¼•Õ;ÛQĞ‹7c¥Âµz´‚ÓçØÃEËÀF¥n–«3y¨nÀ£¹ôyœqş.ÔsğŸ’Å4Q76	ö’kóZÖ;ÔƒÇõ¢·¡)±¾_Ç«v@‚š¡¨‹´ì"ÙxYÛ|«kÀ=õÂÈÜçlşÇ†£hÉìG2V|WDtö(7aÆE‡`öEy¨°ÈôO‘1`¯*SÍ~:´³›Rca=Ø°Ø,ÛÛè¸ãmï^ª-šI,DTÂ9Z.Õbı^õúÔid…Äqê
*ÄŒEŸÔßs*æşÈü-pYv†š=43·–tÇÒã+‚c€¡1îcv€ˆ„^Œ…½r§¬k»Hh|-şæ½—¼İúllø {Gß>hº9 p0äJô!§ÃIúî£]Æ‰q¢ôñ|e²)ˆ!æ–ï±™yãŞ©ñã>/sEÎô` ¨3.NÂö_‘:‹õd<‰k9ÿ¶zæ¡ĞË ÷oHêkT`Æß¯œpğ+é ‡«Ó ê€DÀ^	ÅkÛ!..<¯YŸù8ÿª‰5SI&Ş\¼¦‰.#yQ=ŒŒÍ‚ÀbyNuˆ?¡Xó1¸]7’VGK½Å°Îo9uŸ§AõòÔá¼*;Ö=AÅÕü{²Æqªm<>ÉBCÚìOÜ4—ÙW7Ü`²fqäCã	Ğ±f5 În
Ø,
Éç*ÌúÔóµ$¹Ó„Rï¼şmRÚ‰ñhÂPÏ`OÜrSƒ»{æ¹»Aö,]v§=Ç¹Â&¡…²O$õ>8IÑÚn²EáLÂ¤•í­ Àõt¿~»`(Ù‘ÁI¯´ö)ë?iL»f‹‹ìëäAÈ×Ëô¥kçÑõçhWç ğ5Ğ €zú\6.Ü*ß }Ó­ıÃ¤Ò‹GŒ¤î±Öø/|>ä´ÅïT
.Bá\ÒèzebğWtÀš$Vx“81¤BÛ&:ÙQ#=ktåwğ–®…¨ÆÖÑ>ş<§ZÆï(SÉ#{éKÙÔ£×f[u“ñ„v{°©‰Ÿ‰£º!èMïşxÖ^<RTáu«¦ı$é°9^€Y¬€õœõqÙB+a˜:
1ğ*Bƒfø_¼ÉYµ»?¥²ËZ½Íos&¼˜tšğøRÈÖìB¬0T£±€­9"Lè~u»äe<¤¯,ÿ±Eë*S{FO.¸FL­
#Ë2Œ88ÿbVQñ@îÕ’0úÊFö¸cÛ­¸µ2/ÃŠÓƒĞ+ákø7õÒicÑ¦~cŞ?ìÉ=4p™1òË'”äN}F(È	Ş{2Fğñ -ÂÇr‹B>w/¦ãlÕ5Ø
€=‹[sÇjw»·ÄQÜ…€*µní™Æ7yÛXzÉğú³î'P‰Ó‹p¦ògDâĞ¸ˆˆà¼VšÀdp©şŒM¿*‚u¢ıãçf†”¹0hº-Í#GåZ‘„Eo²~‘‰V½œ–+uúåí<ß#Øëöïÿ|µ¿R›{°­ `úªUz1WÀF¼B¢_)ÙlæØâZ£ÂÂPc“Q¸Kéúˆ÷é˜. ¯zò0*ù¨~®äC é…'ßWT $Çˆÿ·«hc-—í]]`Í_‘ÄÃñ%¥ –ìNB²t5ôì‚p\èú8J)<îü¥RÒ›uÿi.´¼‡âÅQÙİÌì‰ÖË"8bY“ıâÙ”çP®ñ¨Ã….âRºGLı)[ğ×w¤ıe c…®Ge0×[â…Äìhò°Zçy.;1Tx(ev˜³UˆÿÆõpşìÀj è4ˆãYJg²Qå—GñÙK¥ËœÄ€™b€“@ 86m¼Vjäª´wM;67OH ­ü„ØÅ%£Ìz
ÛĞæ¡ıª‚YhÕ¢$./ttX‰Äïrˆ>‰Ç:e€sgƒUıÖ^îu~ê{@­»§aĞºD³Í\çô®‚aGüYæ†úrsVİX ºòõÛ7$~&T	úæ•+£vœ¾SŠ}º œY§Ãî}êR®µƒ•¾éŞüÙ¦Ÿş¤™àÇÄ=¿&0I6EêˆMwã‘BeÇdh5­>ú7¬šò²ô‹ô¦X«½şC=ÜàYéÌ	rHwğtê„$‚Ø_9Ö“3‰ãMé2_~odøMã"”âäèLË¢ä¯¥¸|z3,ŸQT±ÿfŒJW½–³ŸXµM7F{ÉŸ2EÎÅŸówJP//ë¹H?Q}Íg® Ìí4İÔ¬Ë@?Â.0x[s	·'úŞÈíC‚S‰Tš2½=:š2/›i›¡_FÄºLÓÊ{²f¢÷:ò,·!pnôà»Ul2ÏÆ¥Ô1w@©öÏ›˜¦’<ì„m¡B’ë¹¾ƒØ>s:†¤«Ğu;~Ô&ùÑêıTóªü9ıtS*†L˜ÿûemT«ËlG¯˜”®æû“8Pÿ]UôiÌ³ÚïªëpÅúJ\M5çto,kCÜ>Ò,ìLŞ
_Â\Ònaˆ]fF¯eÀo¼ ĞY)ôZZ¹,rºe¥³W‚Š“ÔpïDuıª6Ú †¯y/áºìÀÂgëÆ{Våš~³EQ¿;©ÑU9hr>iÄœ‰3´9*8`´­í¨Ü@0â6WwÓæoàêoºâÏ-Ó‰Æ*896àŒ:¿Ò|£}üÕ5j£ZÉçÕ­.?hÙ|1Ú„ì\Ç$è#êF—ıxGs@ôÓqã~:û^òôbg"€HbX…b)X-„ğ¢ù$G¨~_£Óƒ³°"„°$ïÑàCwáµQ!Z†½@©}û]ıé“0ªÙ§ˆiûßzŠQ.œmŠ$pÂğ|íJ¾õ'óšP':<6¿ƒ0X6Í]â@×ÉñÄ®œ®q¼ÖÎ6\›ğd$ŒÕ,O‡“%Œ‹é…ÄŸ}æ„`ˆ¢S>ş_Ã‰›m²¶ƒYá¬©˜ò÷&ï˜#_’ @Ez;òD$z.æ@ªDO³kûpÚÇ,Õúu5™Ö¯Øe-…-ßnÑëZMßÙŒL4+'lşˆdKWrTºò¨›B~Å)Tbp‹ !ôª°ß_I$·²·àÙGM_®Ásæ´
‚z‚,?Gú°/KD0Ï+íªÊJÎ_£‡ÛÌ÷ÖNgºàŸde¢ÉÈ[œB`bĞ&ƒ%›62å†0dx£nê!‰³®0Ïøù^Ôl®	\ç‘Ïb×%Áu ™Yäêzt‹&ÜÂQ²âch EÅıãƒUDà¡~§ÏNïxÉ#š´š}Ãi4ÿJ5ªÙâP&Ô90œK{…6Ğ7´<¹áÅ ¶&@\=„¸ë• ÿ¤p†
–Uÿå€µû6QêvNµM´®:ûÔÿOÊ{*¹p¡RÃ…Fr‹[Î×jß/|IÎ)ø5ŠÊT	Lç2Î¡ê¥šWÕi6?<L*–¥®â¿û"­ğ!?zÄ	•”ªn~÷­¦=‚©ÅŸD÷è©F‰3‡Éò*}3Ívk'¢vT©4}ºç}®¼»İd»×zVïX	B2è+z@_òL+š5j¿j¾¯ÇdãƒÿğS¼äôaëV d'Â2Ìr†˜S&T›MïÕ¢Åd¤ç¾„—ìßÎ“%X*-ì7yµsi¤_Zj*®wø‹u[,Şe$$½Ö«0{Æ†v†…bH”.B7tk·¯¨Ä÷%?—ªÆ¾ÏƒIÒC¶nù	×æ"!$éÌão?DæjCûãFİb¨ú¥öÈ£œ\€Ó£D‚ ¢q†d]V,5÷Ä­‘‰ -=hAŠ°­!TIP Ïü¾’œÀàLş­ŠNºmS]ˆÉƒQÙ‡Æ{Æ]«ĞùW™æ%ø0ĞÄÅAµøNóùl4)‹>£Ù‚‰ƒşS*´İ1d¾A¶Ù~ÉŞ°µ4±;Q÷¯"lW">^âH]¨şÂb¿»ÏˆRá£	U ?N•Ù×áügâxÃTÇD#ı	X¦Œy8	øÇ-I»¾¢Ì“Åf=›ŸÑÂ²à´à,HòŠr«l€º3Yrš9“ıÅÖÇEç¦ÀUS–j2”Ó§X_oKw\¬ãÿÜkQL7tğ¿÷âğux}l’*drDu2°ª¼rÓOXÛRÃZQeíoq®fËÙÔù­›ñtt¼·"mR'·Brú–Í‹–Ğñ›[WŠ4³L…âÒ-ÈNÊp«“‹¦4³‘[ÆhzÎzš?~åXq5ÕTR4®={“Uj¿1»ôÈÉ½1ÑtrÖcX|ìç3û!şæŞ]ùœ¶3ø4¶-L³º–‡ˆŞ€~/Î»µúï†7hs±%CÁë—x-0Eä ÛA!Q*ÎowœRgü…æq#_–õQ)~Yú®åù›¾EYd
ƒGşš×@`¡Nxî 1›æ¤»£65oÈÊ˜ºgt$ÔJÄ2-q‰VY©—úøIÌ!Š¦¾È–-®EWM4áa5•‚SNGÎÈÎ1V§‚Yz|…~Ìİäæò\Œç,FÈw4[P^B-Â7Æsw#™õ¤[4t*–ˆ¿Ğü“S¹Ü=Ó7vqĞ'…åÖî?Z;~8 ¥tæt‰J®äfg•ëÙÛqg¬éGŠÓÇ&F<ƒÒn‰İàŒ2 ¬îAM[UXm´×ªü€—§fW4ieŞ·i}c¾ø7‹yŸ,”Õé	Tu¤á6Ö·-¿t0Šû4˜„1ãG÷ç¨÷½WºãDM…Ÿ¬äÔf§‹âÉIBÓL¿ŸDÊíad>ñFÊæFDÎ["8±ıÚø¦:dÔ{VHİ7Â—öÓ¡Ã{«õ@6JÜ.?X;dBöè?+#Û“‰4Ñ·j[pG‚ºXwªßó7÷6f”QàtQhóUŠ7ìİ/²[·Ì‹KfN	¬¶
@¾_’»DŸQÿ(¼§¼½¿ZŸ»Ï—ÜÁBQPÒá[Sé_KQµ·Ïä€Õ’qXg$¹B9)l8ÀÍgi\ı.+]î¼,kÇc\± us”ÀOŸ®iÊtw'/Cİ¦å‚±z_.Æ~ë:¦=£õ<Ë ÊsQN$¶µ%Ó¡ª†~«2Ìu,‹J>Ù ß|‹fê³ÖK!;wMé ñÎ‚ô’ ÿ”`ä\n
-†Ö±öhß­j]kf]¾*ñ¯GIêŠ×o$÷±BÒİ^ûcÏ®—ÖõêlŞØ°ùŒ¦9*“A–Xe´0#ºYD§'ŸrgS¾ŞX*=¼¥F‚OS8‚ìıºßPA`%ZLŞ IÏÑşÃ%YT˜+Tƒ*şmÆU#Ã‚²Ğd˜ó*"6ğÁíF"ÎëÕí£„ëx™¶`ÔJpÖÆ‰oànO\z
 á¸Ş²òyñ`ááŒªU~I7ÿ&óÈ?œp¢»}3˜~Ô]ä{u+øÀqy‹Ûšß(låÇuy•68dbKİÍ XQuáô`Nö>Ë‡‹(­&85àZ_g3E£Ë³±X5FÀÉËR%CôœK›Ï-MÚm&„2Pué†éãë3i-´eÌäYÒŒğ¢«Zò/¼DTc`¸ÔŸÈì¨—–LşµŸb@n¶$òÁŸ…‡•Z7ròÿ¯€‘…İw¦õYz§º~Q::#Ö÷µ•yb8kíJÈ|nï²$KWø;¦|ÉÈÖŸV	’*)íÕÛ;†[İ1Ú+kŸV_Â¡Û¾ˆSÂ›­|l‡"\ÆÈ§Œ ¥gá‡ñÍÇ‰³l2çµV…C e¨ÍÛd
dH]„8ı¿S1è	²ü<´Ë~‚æ§À6Ô÷c³Ô)Àˆ~S¶†ÇzôÕøÎÜ·s¼G¯`W¥ìPî ŸhDŒu@^ŞÆB¿7`%í$àóP5ŒşiwWÂ	P¿MeÒ}îiİQù!g—Æá‰÷ñÈ£õÈïäzº|Î1rÄÄ¥y`s¥oÈS+Îœ'IXi?59ì­‰®Lš{ˆİJgüÔdjÌDDóìèğd®Üôù0¦n#n9b¨eÔ£Õßv)™eYp¯Ôí]bW:ÌôŸ^Ä|5"Ê{G…H I)]oÜ,å‘l7À#æ©©ãdã "T1D±Ãü+l^ÊI‚*÷Dê:Y ?èg¬Tò³ŸÒdÅ±Éê‘.‡@Ì“,{hùLI³1Bøê~»á{:‹/œ˜AZáöÌO?òt3´V4Ï½jÿ_Ëj:[òj™®‹bÈ¼˜ıä,í­Bi…£ÖâO?ä -ºœmë-:èNç8	?İ]t{´lËcäK‚8 –¥2;o»ì8—J™Ş¨|DĞàN9-Q’½¿`®Ñdp ò£Ø˜X]uçOòCy•z\àTíŸÎkG%©èbG70İD?qr§¥9€í™pÉÿ"oA#gf»QÌO8ÔÉ”xè˜Yà£{óg»ïš #k)ÄekC s®ÿWšt£¾‚ú	aÑ¹]©Ì{ÔèäƒX*òR\oíµõX&•K2`Ğ¡ÀÂSeRG9ZÃXğpe¡çºÅ¦»JT‘,r¢7è¼"‹ÛFº|O²­&¯{ôİÕ‡NEİ oNq®Ñ0/Î;ÕAË—-Ä²K'h(ÛBÁ#Î%–şaDmª•9Ì—çÖÛ¾ G Â…d™ÅÍ¼$MÀí¥šĞ½œMVìS„SX9±ŠäÀM]{¾ÚYf…4Ìzó¯:á%ïk&ç‰^(4ó^#J®¢âá²ANÛ÷åä\OæB€k£nR-°BÀÄu®­e’dclb 3§ãÇ c¦ä?çÏ¢V•T¾½#ûçë(ûôàò‡I À# â<…1&q_€d‘Tµ4!NÏºüÅrxõB%ÌtdÉ`*ôs×ğcm˜°H,†y}5ªÏKø«TdC«@h+{k~mµ_ñ=ÃÂsËÊ&è;?GÛ{—xzÁZÌµÏğe)í1¿ÑÚR#’Ì…õ¬h[Ÿ–QUŠstlıˆ.ÜĞ5 æ]üÅ³(ö¨N ›øP—šP€àkÂÏ1GTw‡s#¶O¶‡Ûª/ÒÄöCšVH»€6[ç;ÌO™R#}O«6ßÊ§€MÀÌß·uS«}g™ÉWBl1R¹Í×+–{Ú´Ú­âDø](ßâ¦°oö,åûĞ#l:”Zä
5KpX7¶8ŒMÒÔ#ß²“1ğ;Ë&[lCr˜Hîä–/p±J†í§P42CÙiªµ¡¼ ™d¿Ó½½¢:eÅˆ¼¿˜ußÎ„jµğÕ¥…T+ınıÑN™/½Ïpß›âDŠ¤v—Ö¦’˜	–äª•½y8H ’}šõÃ+UCö
Ö¤&E÷§³`òÀ÷SS&1,Ó'Å¤èş~èfeHˆÖç³!Ïøë®Uh<æ·³†kàô¢p4$©W'ñyâŞëL@yGÉìl‹RT’G½šğ¢Â™+£&y;Á%¿7…¿*‡¦»HßS[ ‰¥ˆ¢Òš’ÔjïÉ6ùÛÑéÍr,9›‹‰UZør+Øl oYusÖ¢¢\Pk‰tşÜ¾-±ÜfµP¥È	qa¾G§%r±üW–x‚ë‰Ÿ¶]OáŞpWt$»Èâ
òqROıXŠ<İNÒø"Jš&XòÄl¨ı_»èğ‰ã+,Äàéncú•»fe:'é³9¦ê£”ïp&Ó%&°›@@å2À Qómã¿h<ÖS 9'Ä!¼±€!=­ÛğVäÖìš®çsIíĞ)Ş-öã¦Œîz†Å`-§D#¦ÿ§³,Ó½ä‹¤¶/â©>BÈ¯Ş×Ø²w¬üïÜ|kq.‰¡£tÔi‘ÁÔ¹\I˜qƒ³\å©³şeˆo—F…n3™ÄÇ»dDôT4¦:àÇ:º$—İÂÄ—Á­Æ(U§‡õ-c§/^«òÀÔ´ç”²’[µ·ø‚
X/µòš us‚hOZ£ÖœÓ„ØˆPDsLßO®Cuê¨[ùl¥eş.&ë¯Æ2ç°M2~¯ @%v%\n6m½+ÅHWâ–ì	ØWÒ?ªê’QõG*ÀÒÃ¢Y ‹u(k§Ä	LßÈgH*çÂ5ûÅ~U5ÅÁsåËÅk5ç{†ÉpäcAj§6Ç0EnŞQ.î”	¶ÊU…L#}Í±ùòÏóUØ„hã J¿
ôõ‡“`•€CL‘Mõ§–s®¸c}Ø1:¥«J0¯Ä™dlƒvœ¾Ñæf.o+¥~¿fF½jYâiòrÕkõ;GgÒ…+îöã˜?$ëu+å¹ IÇ¾’¶õE9ÌBÁ‚{3Ã`…¼	I]»°¯[B¤m>v^WÀÉÏVqhnõeJ¾Ô0õ»Íq©DWË9·ìo9uÎSOˆr„‰<ÑHåòKòN¿¤ëd•[ñFCØ~™í‘T}»çß?YcW’4é_„N‚ ¨o«KgfêÍ8¡¡Ùà-N\Dâ/+øBØÓÛ„ºšøµÕxŒÖÂàhª~(ğ”òÚµõ;Öø@âP²¥o¹Ã›ÀïH€W£3ğvÕş¶áìÁy“wiÑÚ	ñ(zû4ÓÔRğãG‘\Î#1ƒáv©Uı¨!LíË­áe•ë™á“ œÀÿn;'ˆ&gøÁí#äYhVû¼ì.ÄPÑıİkb7rÙ}¬…ãhª¦D‘ÇÈígş½6š;Sşî|,Ko‘¯Oµ¶·R/Ğuº/„{3ßSy[Ü.Ê¢–P…‚K£˜y!UƒY¤Ş±d”­_ä§Cµ
…”9ÆË	>{NÑ³¬ß‡°vÖ}ÒoPf—èúíğäø‰¸$¸ê†œ_M®¤78Nu’×ŠµKÏ÷™‡!BÇºÀ{M°W#Ô©áfÉ4ZØ¡ù(A;àmŞ´|U}4=Ü2a”ÍÔÔ?·Áº—©D[ñö¡=¦´Í¼ŸÑ”GİÍ%´¥Ëb	&#9ª%éHIò×Úu„—Î­§üæ ójBw±
À[zõ/™¿Êxì~¥­ø·EP/‡®±¢JíóƒtuO7g~mŒ‰²O®8¾+®féVªGc¦ÙM|§hÛ¸	ÿK Ñ\Á‹·‰uy6îµ¿TÑpÈ±iW^>÷Â/ŒıÔn)»±Æ><Å9Î’"aB`Œ³ë7i&Ø8f«W _À±Mş9¹µ‰¦'®SÀY‰Ì†ş‚"¯ ÆÆc¶d…L›nïàSÃÚ_dløÚÑ¨ô­éÔuWŞe™ü{B…&÷hƒ“Ñåê€ÈÄPùÅpöË-èDg*fÏ@‘aw¨û¸u±§òÀsÉMPRdÍ^a‰—t5ŒÀòi0	Ô/sHLZäíLñ€ÙmsS„¹M§2ûÅãıW«_H	Ö^£õk¼½í3Öavç¨17ğ®ŞÃ–=ˆc%ü,è´‰U¥VRñ/XÌ$N»˜-µY+)×kUûã×
Ôÿ•°šàÌ¸”85•1‰Š^UVskıdÃ°²J‹¤!Ö¡”W;'\~ÒWkoUˆ5¹­V|Õâ¢tÈ—µ©ÚİXlÍ’5âi½ÿh-GÅ.ÿ¤Egr†îv7©JBç+e‹Ãˆè.Ü¨¹İ
“NO¸J“)lË"G†íİ\ÓÈ
&ôûU«nšÛË”O’½c×ã™MLj\IöºîI„''°^[	RØìT†cºv ¢õ'kÙ@¦·@Œp!#/—µ/ñŞ3È¯f¼d”G#idÀc`¨[£mÇOÙÍ_ÏuÇ1òÄ,/ÉøT[åu¼ûâ¡[Í[§ˆ/‚Sv „xír/4O •D­áFtT3I‚EœRĞ£m´~·ÿ¦ÕÜ¬è>·zí {ˆ†˜æŞ$†™gC¹£65‘ñ^»Še‰Ôkõ(HF$J*šE‰-ÅD0XTy÷Ï¯mwğH!Ö“YçÉ÷¿Bêàà;-<°Z%çq³ôø2ËO-j¶Ö›¢¾¤i::&ş3/0MZâçØß–¿>!ÛoÌ ãmXqJ4|Ï'İ¡ıYç²3Æ¦|Ö÷‰îõÒ2¢´q2°+2f…Ev2ñõ…k¶ÚÃ˜aœ‡P~¬¶}î¿¨}2pVzo·™I‚&[aüm
Uòá¥¾=Êò{[Ê•§xD‹ˆ¡®ş¿7õ×êÖSETÎZğ¨èÌW=Tá»8Ø÷ì¾„>q:¦l¡¤­6¡z$rMJ¾ÚäuW˜uú¿ªSãØĞ¦È:&^P4êí@>BŠÄ1g|p%2Iø-…x>àu¿ìuûlŒºXCf¤bŠOˆ!0Rd†7QÜù·ş >ÍùïÃò£0$DZÚO~/ğ&:Æ^º”fº 1_1?‹¥2J£‰-‡™ƒÓ}Ñu’øƒßX’
Sê&eHô;‹Ìzc†“;R‚$­ÀÇç!†C®#ùãóÃ6ÙÇ©6ÿèJo“©œé¹‰ºßß0&Ó%Ï¶N|Œg`­m˜¹kèÒz[©„h%;ûzÖ+€zƒ~~}B›DĞíå¦«-»3…¸H…‡G+İóğÈ@IË„+/o?zu-çfèŸ@"½Ğ˜óİµt·!oÅYš¯ÁpøĞIÙ¸óË@3°&1½+ŠvšÕ!¹u‰ğEäDòFíÇ<!æë:@¾²£­§<ÿI3Xœ&7–bœ|o¯¦r[´İ<?6dW°‡ ^ãŞ:Z‘‡å»ë\4TëÍäe{RN‘\ó‡DS1wıí=ÈªŒuñàÑ¿¸šxŠXue†3+œ)Zñí&h­ZG2s¶:œ˜=Er‚ÅŸË†Õ¬9q¿ò>:nwKù"~8ñCo²x¾?®²jŒuv*9Êq«TCúZ`¤(ÜQ ¯Õ^äß'ôÂğ¾Ë,GJß…ÖğÛáA_éöLğ †óÉ6´ä~±’ÈbÔıÀgPT¿Şéßª9`Ú,.·ºµ»RenÎìg_öØ²h%¿àD<‘™d}7êÌcsHŒ'uù5Äóûm»¥°”mğÿæ‘4n9¢¢ÌQ¦T>œä!Ì}qN¿7c·Åo«¬(H5d†ñNë#³ô­DOÌ¨J“<#ü‹]jÂ¢,<{Hd:HÑñ¶xê~³á³ÊE“Z·ú1^6Í[-á×¾T¶i¡¡­ÂÏàÁ–"»ƒ¹$ÖÛ/Lù7gí¢•ĞP†£zbT!x LLÒ3’¹Öß&\ªI05\:à+Igé¯õ!3<ÁVj‰è¤İ£¶ã'ÄûãF“ËFÚŞÇAçâ™7RV=>İï§'âËt3îôK‹˜OpÅÑI İêudÆ–"¯eøö8F¾ «8Ìôëd€¥¨åÕVª·}Âb¨1#úâ’ˆ/‹şü65½$Iî¾¡|%Z$b¯AÏ¨p²›ÕSşã›âs|óò7exD„¬+a©1Ìÿ<u‰NkWFaG#”Éj7 ¿H)	–E¢˜İ[=AÅİ€ú«pGCSæ7„åœq7Áä>uMêÛ>ÛT ‘öNÏ[¥y„z|’ãî'îşêÏŞ©-èŒ+A¥·à &™N£k­XéÍ6lÎÒU ´”]…¥uÿğUÏÁ§ÂÄ{°Ø(ó¾àµRÇB^£Y¦ì•°[¸—n%ª¿œ˜GÇŒaÿµ›u¨/»³„g`„tû•èJâà6¦`³Nğ‚VïÇk$‹ŸV£ø"9[Ô@à÷–d‚%Ùı Ö\2ÍÖsÂ§PYóTxNeş¨¥æœpè5êòÚÌñ¼(‚ÉÏ„¬®-»¤‚nN	+ôXJ<tŠ,õØ&!¨`ƒnÌ`ÒÈÈÆ=Ìæ±5ík.³GuTA–%Hâ1Ú]Ü¿!ã(á`ùi-š.‘¨®¿¸ƒü3ÑŸ´1ˆĞ ç&P)Â~F±+?·Â“
=›ÅƒMå¨ˆà‘ı-Y±s’Y.ÓR.³õ8„KáÜhAš wûIÁÍêÏUáê$e*›P'zy‹C×YÑó‘‘fÅ‘ã†	Yí°Ÿ*JD¡ò”+…”qÿ¡è¯´Œ†X@Sb k£Œ»Sb]r­ŞZ–ôàH«s‹ÏÉø3ÂÃ2_Õ^¼Š©ñº÷³ìëWÉ|¤&ÃºvËÛà®aÇh^É±(6/â½Å:ì„Íµ#²{­ò;uF}"ç±Ú‘@r5Ú_Ò íoÑæV§8=yßFF·^S‰Nıÿ‰ìŞ¶ô8ÿpÈ­Ïq~öhùĞ7ñêvÉë‹Zx(¿ÿ¬jÄ$J{+¡Œ·ó¼£M.]®ÏmU‰î°à¨fÖêHsôÿÉd	-Luıd>­¿ï TtEŠ	Ô™=#EXR²B²­©y¤Ë¯ m¬ŞÈÕ&ºÒæÊIZàô¡“eÆÛk¢IbS©3;ïsl¬ÙÒ?ši·»«O#>±WiŞÀ‹óº/õïCê©šÄEÎ£U#Ìö$ÔÇvc8GÀ¹¿y1:¯–æ7¤íM^.Iò…²Häm ƒ ºj)Éa`ìÈÅÅ÷ÀKNô_êBöß"ïÁ€VxŒ}A€æa­je¨¾””$BWÏ½Wf“å">€ÀŞUxÒcÇÚ°€±±Ğ­$ã¨«
_Aoz†6M®û³²è/x@]/V_Ü)L BÙP×à41
¸ûw!Øéˆœ ò&ŒÇ-)­îš0»šd–Rƒ5mº¬éñóĞõáÔ‰2¤9ÿ˜Öğj’³ş[‰•”°({§ÅA$³*$›|W‡l>»ñâæû±‡¤÷NÕĞ'óš\²Eq/tˆä\RhÌ“XEÍ,·<\$†©³*Ê\‹s`2‘’=[xÜ›Ä‘Ë4ïdÇoÊOmÆ‹N›:ê™ÃÖáµ\9½¸›è¨PÊx%ş$„Úá+Yt8SÑXG4XôÒZ1±İmBJ<×r¸7úqİ¹ú;íw4O,é+B¥ûRéA_ÍãLó'æÉßîT•Fäëf<…h=d)%Ô†Fœ[ò¼´ÜOo}-•NgÛóvœré	‘¬B1Nı®Q3[2i•Å~Š	Å"œ\#ıK.xYÿåŞJıAn/òş‡;;Wu#ÄÂWJ"hR7¶\Ş‘b¿\yÜ‘êqü¢D9Ç±«tÊdú‘ı`w§…‚†ã ´tğ*MdN`«lìĞyr/ jRó?9¾à)ÄÁÁO¯ÔÔ™MõşëÕ£¯û/»¿‚@ËÀÍ¨G\›ÄÈ¨úªN»eì+ªmË’nÚd{S…³3qF %¾’Ì5Ÿ–N03\ÄÚ	}uã‚S,ìpØİ+!BÉ-k™åqƒñ.sb‚±	ùß^Š2…µ¥
2¥ªZj¹ğhm[¯±qÜğDŒ2MÌôÃk“cjY™ŒC¥ÅĞÅ'3æÍ~6ù-H´ì½@ÌËœtõ6h“¯(séş>ù^+ñ|m»£¤İl¨e²Dù-È‘¯(	œ%
áû×E¿‚ÑĞ*>?U½Sk3|·£“ô+dÕ•¸‹ßZğª>ü#]ÔÄ>0"Ô‹JÀ¼©m»²L÷’çôó-è¬ÍĞs[OBËRÆ*ÊÚ:ÚÄáÑÏ6ÌÒçÉ/²	fÔDwŞùe¿\ì—íóóRr´ÌŸ}ğÙˆ”áAû(e¹i${Ñ/iõ„;(¾¾$ÿ¾=K
÷àƒ)7®vF¬2Tq*Ã¡˜“8ZŸ@şopª9Âij7’ÈƒÀãKocV?@ö¬_EL]F©ŠşÊ#æ/Ã¿Ëş…½p‚é:Àˆ»e[ËQY*½¦lZÂ=Æ¹c\ßş7:çŠ™”-W¿[XÎ×˜¯òü‚Åj‡qzŸ»G-OòŸ—2ŸB8‚‡bæÔÄxKÎk|·xá[Ë%hå´$êEAµm*ş|`j)“Çc^ãıêNH×û—Ş¸$ ÷í„Ö6÷ŸfíM ‰‚ÈF‰mÂYäÈÌœP{½&0Ú5H–«¡êXHR ênÓ[E`Füm&“³fãa¡¢å TƒB2=n³#îYéÊ}>¼!„Ø÷Õé"xyìñgŠtT.g¯~ÿ‡²Àä/0 @sË ĞkÂ–±Ø/áëI-®· ±D9ò—“åFıïàªÇÉ”hŸR{î%üL§´Ó0v€<Î¥ñ/z×wÈB3ME\9ÎOrŠë÷&rë¿ó\T|óëôÌúOû}Né|Bë`«“ÍûI¸…Õp+>³(ÃÓLÔÃ£•ç‘-¸ê#ß·Y¢p$®ÁRØ«ç
UL‹À+Âlæó+u@4Ù½>¿TªOk>)3¾WWù"ŞdtùbÄ±€) ÓW€zü‹ñú©©9÷ÄŞ şşålím9œó=9êéY|	‰¸/2Ü]2›[ ÇR¿fÂ¡ö³Â“ÂÊ¶ùüª‚„oÿõòÄşó¨I¨d†PoÈúÔ ù¬«“¡I·a¨EæãRVJD‘H'jîço/)sW¯8pærz¬gÀV:+ ŞUCK ]æÒ»—Âı3Ğ‚Á 6â‹,zBÜÓ7;YaÔ` »,#óî˜Ù¶|ø{ ~í³+Ï¡ã·¬éˆ–ë+K
Ãkğœ¦ô,§7œ±¹C¾·…32›"i³á!\Uãı[÷Pƒ$ÏÁÎÚ÷Ş Õƒ€t£Øà£ên­QÚ½[Äè¬ôÃs%í3ğ!Ì€şÂXÃr!#0ãw—£éÁ=éa y‰Y’1§Ì4N¤ÿ Bz¨íøiÔı~#ƒA(¿m£±\Ò»;DğL2³ÌÚä)Ê;Ó½‹Š9ìÅ>¡×ìœº{Nñê½å×Ô	c!ÑÔÄ
‚AòT1o± ã%¨ñ¶æéÏÏrˆ¾Şşt¬Æ<WäqÀúø‚\|¥¹M•×pŞ¤;x7úG¨DR5ºa;Â0K‰©è$q¿ĞcÖÆW“éádQ²vØ1Ñ/¿Ùó£÷^‰¸Äc>À_s 8qAÃæ½&lÑ|Ø>¬ñXí«ô~@¡!°„˜86ÆXKÙÇÑÙ¯cÊÛ¢"@$ş5rfÏèIqMÉ¸Î"Û>cK‹…—kŒ««¿b„z‡”Ù&ºöOî˜(À–Ò¦Ø½_SÂx&Ô3SğªÔæ5SóRÜùeÃqÌWñ$ş/Ñ\1z«?{ùËW`Ñ·×‘¹G–¬Šh³ùóúøE	[2¤`û—ôá<TTüš)ü¥÷H­\áO´TµAŒ[sô@ò_N£àŸ ÑªÄ‚<Í¹1t<¹£,Åó¥î\½zaÁâ»2é†ø Êí(•ç	½u÷ËøâÛh~ôEâ¾şó7ÈX&“ÜŸuÇƒOÉ*aí²‘ILG|ˆ¶÷e0å[†NM7rÈ‰<hK3Å|LƒDŠ¬#éa,zÔè8Ì2}&”‚¯nô!ö5Úv…1’(úkAfª
’|Xˆ48h6&ÚØ‰í³+T¢©b2z¯¨¾šì‚œ
Á÷½Âëºf
Fà(ulæ@cîƒq,2AğpŸÃ5cÒ¨P°Ií¯ "[ÀÆ>0ò—cô¹‡^ZH íğdõ¿#©ª¡Íbja$m6_WaÛÍX]¤]oy+Båuí¾/•4şšá »„úèÅ°0†‡›æğ¹aô•ñb–)¾‘yx0¸±ÎÂl†0Îß‡ˆ™şC·½ªm êtî/ù”›K9A§)"ÌfpooË€n }
]B•Ó‡ÑTšX lÕõg³Elµ=K/ ,€°"­AÍsÄV‰0 =étaÚJÊ³Çç%ó­¦cİŸ’¾Ø6}i¼Pw– )}q©XI/%ğoÿ™¸²ÚÉÛO«u)®°+Ô…—Ø!íN‰_„[¦•º>çç GzçèPLc˜¢ù×Z¯|wšƒO£Tûöt'™*	ª,ºIàSÁ,.fQd(ÏRc¡m
­˜z×õ=W<°‚úzö•Smò®(ó×JRùe³}WÍ[0&`·
	öóìŞ	M›Ò'påÓ&H±7Xtñ—	âŞ=:×ä‰¤C7¯í~!zI,Öâ÷-‹Zw°onBUæ•ê%šåÏ§HÅ­ ¤†x¿la¹¹İĞêMFEØš#¢İfŠÈ›N –?6`¶¸(‚{¸ÕİàÓºlÑÃ´§)ÚÅAâ:›®UXgIşß«t2eµ0„=¯üCúa5÷ùˆi´.vÎ6ÅB„Lû‹ÚBw<5ršÉIz'Ù7t“ºëÖÚøÈ9¦df$,Ü÷q[?ÊÑ»QÄG¬Ö¯'„WÒ6W{+8;r¯r³èÃ¢“}ğcƒu¾Ja½á'œÁÇal±sßú’Û,?
©ëdHÀJïŸğ2,ØhôEı2gÅhîÿ‚†í ğî×0ê+A8g´T75È)ÃT,ù ã«BÆt($D	`q™?i¨æar‡É…¢‰pî££QÏ‘RÅèË›ÃáÃ‰+¹:©–èV¸TÜ~¥ñh/´p7Ü/"EUÌA,z—ß•jM ¼'W:ö{†½B±¹®,QåpnÚwCİíJ¥2¾›”¾ƒ…>
æö¨ûbßŸG•‡áÀ-›Zg`=àÓUz‘|Åâà7t‰ñ]sx²…š»tJùúaR;s“#‚­Ú˜<m”Æb6¿¬ #€Uöa)@fÇ¡ı£Næe~âxT¹?1¦XnËÑª&\ş.›º<İÜ+3€PÍ‡N5ë +Ğ)^n¼ÍMêk»}ú‡İÊİ`‰ñ'tdìÜİş@HéÉfĞu}}®x:Ïi8Ş†r¯à^Ûæ|£Øöšã Úë•àAOĞmaÎM§¨ñà©™YG
~uúÚÕ>R$Ic†ºLJÑ_ykº`/ç{“O·ñ\À²aJlU]Ğa¦š:Ÿ×]TÀÇ¦¤ì’¨¤ #R¯' âUbi¸9I;É}ÌâƒÿYí™àèÎ³ÁøÅ6Ì¶2]K§˜cxè{Ú™€ÆI/ZË^¨ÉÌªŸ£2œ"Ÿ³yH ÉƒÂ7rXï‘ëØ¾ZÎƒ¼‡°	XZ}Å¨ÒİS³$=!úıNäP~Vd^M³‘©ÁÈš=Şßùj)$xnï1m¼rğFWªÎ%õn5¿(7Nr+Ä¤[Œãt¦ì3û®˜Ú{ÕC>ÙæNÂFL‘Û!EQ"MCÙ¤Ò‰Şü/ £Ê£®=@Tæ©ÖGlyÂ(‘µÖ‹­{–:bS3Ó_lÈÁeƒ%Ş1hÃúß²T“:Ô®&Aç³´€Ô<aj³s™‡•l¬÷2?Qe+ãrşY6û=¸%_Òù“¤l±,êzO¹cªÜ_[´Ã:7 #«Ñ>•'Hù’
K8X-"@èÂ#ÒpÆkÊ´$~«´Ta–î|¾×áµwïGgÜ`ŠgúÿŞœTBwY`‹€’±Èxá†˜Ë£‰÷ó~V„>@X†oÔóM6ne‘dĞ™•ß„ş¶dÎz™.*ñşûƒæ¶ãhĞY5µ³ÇâOóa¢·ıaEÛJ^‡³ázRÚj8ƒÇwyfUès4µ´²½f 4ŒZWã8ÃöĞàq\šƒE×q5OBˆºQÏİErDÊ¿»¤ÁP¶«¿*ey…Í‘ÚûŠVfÎàzi›Ğ*™ú2ıÜŞÔÇ
¸[`1L.ÿ%qÛY×1:å¬¡ó0åthÖgv6-ˆµWú™¡ÛòW{Îh¬uô‘Iœö7Hí\ĞÊÑ—Ä<ŒÉ	'iDLÜK·wÏ•hE”5ß—9~½oöa¨F‡‘ZK¦Å$ËâôS4c/ã€ßHs&ÎŒ²hçµ²)ïM…¾U”Tf»Q4F~TUaVq™²kGaYø¦ctTÅ=u¨;ëÇ•gÉ?‘ŠC&ú=÷7ÒÄ#%F,ã©Z–?«1ú¹[äKx]s0i/¤øuOmcòJÌçÏ­JûW=ÚyuÀåéÙ¾‚F´ßƒå½Ë§„K~Ü@“ğ¼Ø‡öÒ!˜5Sëƒà–½‹ğ²nÍ^oø3”2jƒ%ÿøpî¾¬–;O«p ß¬PÙá4K¸áâ ÌÊ§ÒíS¼eerk6ÆÓ’Úxù¸ÊcXädIã	^›Ü]a%	qe$tªğOÑØÉ*w/ÂËçDnúcª†E«ıâ7+HŞqµÄAä}‚JäWŠÉ8Ñ‚Ë q'›]á¥Ì,3	`¶xıú}’"ËÅá¹¤l$›ğ(êßiˆæÀF¡6»ÜAMd©8&9>†ìØÓ±gB‹ÓïÓÕøÈ?»ÿ·•¯ +¸Ä×âÅ–†£NŸq$µq±+ÌX$À[Ä8¨Î=vŞ0‚§/i>Æù4NC‘ÿFxLÍ`{Á®ä÷¢/;zÆ|¯îÏ+@z¤ò˜    o£9¡¿i å­€ğ¦==©±Ägû    YZ