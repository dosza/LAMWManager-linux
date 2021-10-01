#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2227613176"
MD5="98dd27f604a5927ddb6696799f1061d3"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23928"
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
	echo Date of packaging: Fri Oct  1 17:43:28 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ]7] ¼}•À1Dd]‡Á›PætİDõ‚`¯ø×œ!>w#cÀïÂ×$£ğzĞn;ŸÛXbıö€ŒjÂè¬b‚ö5Ì*âY¦¶Sd+è_õ÷Éd)‡êCœúŞíÔ1²$O…MûÑÚŸ‘\áw[K?LãŸñK%7—”2ÒUõ£Ê\´ Ntî¿6A‹Y¹K­¤ã…¬8—ğì¼ëÏ_y¬BSß€îRè¶Ñ¨w€Øõr`l“¾Š4`Oas®ò	šVÍ ¡X,Z˜áø'íDË 	6Î+èŠ—øÿ>h¿äyCÍæcr¤øyR¢tTîKï%éR~„èFTiöÁ€/õ(Ó¼â,aµ›àêÊÔ¥–ÑlÈ”İà‹jÄd‘Ìk<ëÛD/0âª@w{&=DfíÄq®êÁ®&j¢‰‹–V—'¸·FWpWÍâ"{Àÿ$¥fãš…&KKIá>Ëñªc< #‘×%¸àà™9›+Ø„SŠµ10ÄZr8=]E1CË-åpÃC•(„ßEzÍ¤‡ª~"î)û Ë`aë:j“Üa±À<‰Ü-o9ˆ|=Uò4¿†cX¨*R8d<ã–éjÒz+ªChÛ™âÄåšRe©Wh¿–jøçX¨Á™WÁc‚xÆ.Cİ=~5¦°5F[ôe‡;&‹À\¤4É¼~¹w&ÇAØ½©Ûbàm0ÆlFxä-7*`jDô×1~ \ÒeÂ½®»­%zuàLß÷	ÌîÁ‹¼1UwİÅ³§ÌpÑ23ëü8{·ŸøÍÂ…6Ê´:Öÿ*¬€˜0ÆıæúaiæPÕÁ½ˆª‰dn'%tÎù¯èrlYõr#ªEU€€ßøÔ›¯Lâ„|Øwb˜jôçV&etÛ2,¢òD‘†V|cD*A=‡iZ Ş©X.[ß°&‰Jo¼P˜^ì¿¼~I˜^ªı1'¨}1=ï™ÆÆ¾Å*ñ³WmGÑk—ê ˜÷Ö=Ìp¶õ¯‰ôù¦¬„H3ƒgCÌ(bFbÒT±Ô=æIÁèÕôC96Œ“¡Ö®7ÿP8U”­¯OxçpÈûÙw¸2@2—°–íNbÚ®G™m3Õ–%
ùƒuÌ×}‘Ÿ*Ü¢a<°eEP\6ä?Ô?–zC¬P&bšsó˜¶hÉcê¯]ª£ßœc8 1l©çM½|#
 AÊ}LåÈÎcÂâ7×çø­èv§/Ñ$ƒG¿ .Ôeö=Âõ“É"¨˜ê[	6$¹yÒ	à<o_N«Œ-ãâÑZ ^³œLg9šHX¬o ş±Ó"Vú
Õô.Ê8à÷>3snÌeé	÷¸ÊyŒ#ÑÌ©Kp¥[á±ò_nå’ÈQzø=3½§g«Ş†Â.º<«gímÛ@ Ú)ê};<öHÄ#Wdœäšó}ª(Ke\|Mæã5]²ÙÖõÕïĞxL@¿»—vånl¾ôDè†D³b°?rx‰´}£"æTĞÆı¥YP#‡`››™Æõ=pÓ´äĞ++•_~(BÉu®JŸyö2²²ÕnÁÃï+(qõPKø•}Ö¡¹öó…µÑV²UY=ƒªi¥c¡º£æ«¾Øpg( eh–8ëŸNsQ;Ìá”V¬ÿèEÙ‚B2Ş}æ f‚…0ä‰P’¸ø(ù²ÄäÏX.>%ñÿmHçæ‘‘çùâïXw±?RU¹!›ƒ¸MÖJşxĞö s0ãQ­HkZè}‡–CO=şË›†˜Á«Ò41W‰T#Z@„Úï
ÎÈÔŸ¤éÁ,8É,KJ#ˆæKN!4háåF¢Õïañ¸¸ƒÒ i¦†xWmĞ)õ4vĞ[ÃIw-)|Ÿ,-‰î f°¯°Ò°ÂúigÈ…Ûœ¿jø0[+NµUçÕİ‚oÔótNãÿ™"’˜–·ÔIµŒñÑ^49›÷o›v©I…Ekùº§ZQzR~s—h–=ƒQe‘dĞ %Œß.5–RİFâ^iì6±¶,`_ºn<A²ÀU-Ö•µâ\;œ?;”îCCBµ.n¥o›°
øfY ­˜]Zª«%Öá—n¼$ŸøƒÃ«®¶Ô£WVbcxÎ|Ÿ»(‰(8Óä–‰)/NtYÉ‡xÜmÈˆğÜ|j³é­hä’Vfb-¢ÖY3cmZDğSó+TÓŠp½ğ8›Ôj“-›İˆ”yJş¬,	¯îñûh!…õQœhÎ˜Å\|¹ Õ¥Pˆ‡OPT¯ğQkÍLAOTvİİ¥Ø}A¸±¥UDFõ›rÌéØ©iÎR‡Ò~}•Ò™à«”TÌâD²KÜò–ĞòÏª„mïEËÚr_?{e/îæf@&€]& ÓC3Añ(µPGšQDÚ'ø†ÉeRNÓ2Ñ'…Ëd I-$BŞ½’lUs&ü.¤©®F"p¬Á)ğO\Ë-‹VÓ¦Tq§ÛwûÖ¢ß<Ù•,ô]gò<˜cùd4“ö+¡å#¯4üø7#¢Ğ)Îê†Ï¿õÉä@œ&,•ù¾@§(ùö¿ùøtå¨FÜ*ni‚{%¡î®?a¹à%üÌHl¸ysÄşÈdAÕ^Ò	Ø»„ò·é15-ºt¿ç
X\áàõì_Ø~ÃË­L³°PÊŠà=áèš?>o/ÏEÏ'Ú¡ßfÉE<::qÑ0ÃòrQÊõ<¿*x»‘_ÿÕÑ¹WTİç–~ş£‹ÁîHî8R•D>6ª[õu¾êª½ {2P!”à4R$‰#:ÉÑ¯aJJ„íÌ„zcŸŞğ@í_ûáÒ-zH˜7”í@R5õ³—ÔºGŸ±ÆQõııâ¿èĞeg„õ±G%^cœä-ÜLq¶'7O·w<í´á÷¬ğ÷°kW¿{a³4	GÖE:Ô­Ïëàa7ù†>™Úw•ehfä’r`ÿş™ÎàQß£1ôÅ6(JÌ)×l›ÕÙia^«šx0ßÿnÓ!ÇÿÚ·ŠFXˆJèbj63p>É_Hœ(óÙîÏæ#vF	5ôëõ<GOšx¡}á¥`ÆÓ¢D¤3,y»¥V=7=HÙ£[i‘NzkxÕÎ2…/»‚Â;Ï	¶–¯u|êºh$W~T6wãCºË:"ÛÀöû™›ÇÙêâ•¨eFŸNÂl‚{•\Çë/€›sá×>uÔXH*ËxU6amÄŸ–bÑwîç‹t±_™w§Ræş^]éÆŒ“zƒfyó‘Êôåè„C³ı}¸“üîw‰ÜK½²$39zO†¹Dfµßn!CSÚËíS„‹Å”Ö¶ƒºÕP°qi~Á¿İÏpÆ¾á-éÜ<?5/÷2–WAb#ËÎyJüçn2[áùÒèÍ	0m?ÍÈDüğ(+L!pÅ“OÀrƒ¿B²r±«ˆÎ±Q8C>²ƒ‹¯@ıeğVÉgLª¼¸Êùü&`7ì1w]®ê_Øt[&ÔoÊ’?ğ†àÈÍaêíB÷;Ê¡àh¸Ò&4÷ÔŒ‹YV30EGöŠ5°ş'"DbâF´Ênòş
¹@×ÓnzrK…©÷Fõk~‰\	½ôÁF¨úóîŞ'KÃ¯1k0ëôĞÚØØk®P`ér½Q¶/ç­ô BŒiJñöˆ¢˜¯K‘”4‘‚ÉƒkÂ¢Gø“I õÜ7ò‰ÇA¹Œöş¯ÚR…Ş¬¶£z©§k©êhZvÅå»?'¹*<ƒq&ßßã‘ÎCÌõ;¤ªõ“RÚ*Íâ¸·_ÅØ´ñ I²ğ?°ÁNÜ%J’$$}‚É¶Ñ5-B³Ó7õá—­çé8õJØ1gq'çHæß8TW÷æÛNîu²ùNòÁ{Ñ€ÄßŒ|ˆÎ‡2rŸ¶ˆI…“_j_‚„÷«Ü}ÂeÄÏZÈK u,ùä’¡Ùßâ$ G.Ü8_•ü •R]{.÷¶- ÆÅ;‡Ğù¼Ç¯ãµè×ÁÈ™DTsÌ2ŸôrıÊİhê	¨)Hn±å¾Ñ\–	>µ™ılq±Éf0C¹­ ¸Ö†Pnúüj§[[ÎÎrÇÌ±œKmZ«•N´ñ}bŒg0"{3ËYÊy¬N›^.hx-…êiØİGß‚·¸Aá72k†]]2à†ÕßÒ~7ş=(J›(ÓÊ­JÊ{w!²%µ„£KÂkÕ%“–¹G@×ß¹RKf–@ÿª¡6ÂÇœ_¯{«!³¾Ğ)Xš<‹ŒÊåĞE
×cÔ²òy¹«AÖmBCYâ<ÅŠN;Æêi0>ƒHäû!‡ƒ,,Šf)²Sóf ‚@%‚l§â¶gœ)Ô!çìÆ;‘» ”lÜÈûë×­«…®pê¸µ9µ·à‰5'Ÿæ‹¶ó#ƒš¼Å|‚5qÍø\¶u˜Íf…·e¥)tS«œ–¼#æ¯™;Å©t!šI|Ô:˜PdÓØĞ%OµˆF97fV®~ áÂŸÀ4DÅìXó&õˆí¤*\Êªqy—w?“q"…Y5h•½‰ş”†n°€?4z_H2­gùİ¢>"í±FiòWi‡¥Dó Œ0’-6: ¶Wf¡8CÁŠ%½‘^‘Øy]†·>/v°c¾YÄ.üú|oJ éZ(~Ñœb)&¬ıØå”Íûr Ø(•
l«é#›PaX¢/óÁ9uşÚFSe¤Ÿoša?^Ò†ipGYÒº±×™` Î:t³µ†«Ë"›QXìŒÏ‘/ıwŸø¸“ïp”¤éÊ¾&$ò÷ï_Ëíº¸^¹x›Vu<O}TZ(Ã"@0`©L‘›ıu$Rc,ŸŠtGì„ÿ&®¶ˆ[­}û>¹ü‡IÚ09 *ÀÚ6ñô™¤Ø–"m“w0½wøBQu¬áĞd+Üa6zVŞbH×})rGA)¯*×¿‚Ëóÿ½rN®\ÛÁGQJBR–CÒú2¯¸µ"ú¡)Ç,¤ãşÖ{1ñ@İ!æL8õ*Q!0V07?M¹Ÿ7UMcóŒ×iÿ)¹ÄğÕàüo,×ßÒôXJN{¼àBIã€d‚…¦R›‹Ú°G†=W¿¢¯ï‚L,löÓEúÄéÄÚŸ26–&éædÇ$&	÷ÂIø.~¸Öpîa÷¦/$Û¿¼zƒÇV[’ÑBÍ¯„ÔãáKŒ¨#Cj_æË…7íD&â_È¤Í¾QF¿‹ÁØ{gCš“N)åÙÜ’ç¶şmX£“CÀ"'Ëƒ½'*µ™]º§l°(Íá=ÖĞi]8Ú2•[WØz•á$o+åÁ÷¸>µ—€¥¡Á½±PùØdhJF?¥ÂR³ïÀóºÿìí6¨à)ŠGÎjJäÙÓƒŒÁˆdRR¹¯
9s<ÆœF9Èh”^;.ˆh­Ëqÿ€D¼3–\vÔòfxdy*âLoõƒ™¤/DÃRF® ’Š‡· ¡.oB—»,¹nK©q&ã/ttğ&d5İÈªûƒ#It{äËDÕÈ¸ºÎôLIUz	-%BÈŠ•–Ï¯}9òßTPñZÿ|âöE<òVä«B: :ûÜÿ8³23ÄÜ‘íÊÃhX÷á˜9&[…W4UÉõÜú…\ÊıaO+ve»\¼o9Àî~~>|bÿb{Ãj×Œş>úÈÙŒX+LÚŠ¨©£ÆÿÕ»ìÄ*x‹B¢j®ÌÆ‘îº£9wYVB^%-¨ ‡¶¹°u|å3”]ñMb13
s7sHòTä¼‚d±²—‰©’ÍÕ3úÛ3%Å± +Lüp†äägã†„Öú9 \fCh»™>îõR	‚ØgMñI(®ß•hréİcÂ¦Î¹B×(7œÂ· ßHf£oæ²epïÃU+ëfÌô
E ru^*u‘¼ğÇQÜd %eÔ‹§[-éY9şì›Agœá™3À*¤·Crî0û •ri™Ø”š>CDÒ!Œle[m’4ë-@‰Épò„†…mæé³ «…w±CÊL+üJÎe17€û›ş˜ÂlFx¶1‰¯Ê¡€Wë†úúè´.{á8¡‚wrÀ{è/«ÿ|s3KìÿôªŸÃb×+K!´,â‹Ğ>ŒílL‹ğ9ğYu}£'Á¨›C‹r!ĞÁÚâ(’ŠÈšC¥Qn	"9£‰
›ëá»;—ızaÁ‚Â “î¯Œ¥˜;1dY˜?HtH]!P¯x	sGN”.®Š6°â&á	¾2ÖçÉahR#dğçµÚ­¡Âp¡ìÃå]…Å½¯•A¸oIô*ª"˜ô e‡Y<¯¨ØNw^˜j\|š‚¤8ãlVE4n’à’³YXé¯)A¿ó&öİm³ş‚Œ³:zú 1jºKË‚ú/•>0ûä¸±·¤`\s‰p(Ï®Oñ lÉ6
¿1ÙyoC[În~/zëp÷W"0ûg©®”,[›7„SvT¶ÉºÈ,e"Zóê×èƒOYWØ
Û]˜]NèzOÅ„´ö%ü£¾¤xKñ·V(q\Âï8Å™ŠU#´{J`¦µ©½2!‰%G¶Hl±*Fã;jT›+‰äµ½Šó¶ÏÛ_gaØ|jyxf,ÆŞ‡ŞowëÖÃÖ´È]k_¾²ñÙÅt×ÁÜX¡Nƒûkè«pïÆSÃÈÑsb#–Şg¬>ÑhÊ™Kø¦…÷L@ÆQådu#ÅyÚÛN7¦5%«ØÉfÃ<ÍS?˜º‚°tÖ÷Nìh~^ôjö 6ŸÊÆYòšWkû®Ÿlñ¾©\C1ƒ…¼Â 3®¿OÛå3•wğ
ã”=8i0ä‘xslßSö ÷¸
ôî³Pişèm©¥fISé‰¶ÌhŸ´²Õ8Û_Ašğ`ô½=Óát=¢G®÷Om]è‹*½[°ÆĞ7¬öëÀôx;CŸÆ£¦¤4’\İ—J•§&¹h•YPï«å#´—J=M¾jsõxdşã_ßV
â'Ñç°iÎ–ƒw =Bõy=# Í²ğÍ`á^ wı&²Æ·ŸL©:ü§?64Ç¬;dß")táJkd c úÜŸ¤‰Ÿ™ü·z¤Ì3_í-M¸c‹4®yg|(Oœóİ!R>LªAÒôLôOŠ'Ó¬5‰ñy:_be!-WiÇÌKXä£j^§uÍtööÑ´{ÅuÄÖD¥\Æ÷HÉ§ ˆ÷ß”{+q5;hfû{‹“™ï>ÁOŸØ§&–x©%
6 …ò€.¢`…‹C sEò˜—‹éÿ‡.ug.ˆàù’Ã3Gâä¯3¯ò‰İ‚&ÃYúæåFÃ)j\í:¸2\”cãõÃ:j+MÈi‘®
uíA2~7h®ˆpN=qŠİŞTÈª•æí‚«ıYíh«_«–gíDÈ
vš5Ø¡Òúşƒò"¦¥+10ï¬CC_©¾%ø¯ğ³ÃJ>ãÀÚz”
4¦ød3Ÿíö©…Ó]B;‚Ï|˜®Cİu¡&¦	Ç	½™§äQ|™‹yˆcf4Õæ&5+»e5êW¸rJXoB ıs3´ÉN®+'¼ùFl1iA ^ØÎ¹]rœ€WN‹”¸Nîİ9"ó:aÔëUç'z{Û¬å„¼`¨µk7O
8EüèÛ^Õ%½(>y>ùZ:ÅÜci†,Ï@ëh«g N[4Bjìl3³l¼¸Üi§œ½
NnwZç/„*¿ó7J3ãÉ¼QEŒ(àó”Š5K‰V½a—ÚVë278.ZÉÙÉ(VƒS%y´ãéÚõ/¨7ä.šª)ì-o0¡FİAa²Å?ò8G<ôTe\EM^ÄSt¦­Ó$º1ÜNtuq˜ùrMøÆòî›®ø€uŞB\Ômf‘´VªÒ$ñÀ¹^ãm	Á‚¦Û¶·…2º[š=ŸØû÷ÛPİ†8xŸd6)é¾Ùx-Tš›k~Ffò.›N~‹˜Ú’±v·ºTg?äF?:ÙŠÇÎ\~Û.D›€°a]‰©_Ğôv²º)ÂX½G69È?~'GËZ[^è£ğ¼0z¡ô#m~ıZSm‹xu±£HJìÕ.dÃ9Ëš¦i…øbİà‡·×'	²¯¥|p"¸aâÙ4vøÛœ-Ÿ»ò¸][¶@jSÓI€®fj?£ó{gšé!µH&Ã€_f²CĞÇOŞìz z¿g„i÷y´Õ?]@°ê¼¤¾ÁÄSØèïK¶µõÅ¤‡ìÉJ7ìïkSÜ˜BpÂÇ‘®‚ÛqdAzüG›&¬Øğ¯ú(2NUøY[ŒKãyÉãç~*é.,7¬Õx†Ln‹HíD ¦Á¥ª npiÂ	¿–é¼s0
ãKç>ÔÏÅÀë•Ä\0µdx¼F’BÔóÿœMâRSĞåHòYéşÁÄ‚TwHì]sò4Ù„É<àÓÁ
 xnJê üåNAX‘\xË!Ä<ì”¨À5›LÚKzÅSCJe×é;{~Òå	©—Ó Ç`(â± º¯8bg¿¢¼…¤‹v?¸èTƒ›°œ—û„J7	ÚbB;Uïƒ¬ñ½Îïóª„0ÿ,æ o01„Õ‡f‰=*MçwàÃo¿âl1S9TúY4^JëcP‹8‡QlD *¯x±w1¹o}•	œõ¬5696€„šÿÇ”´ğÖ»@Ã»®Ó1I$ù†{üRÔ<+dá
ŸWEÓ2ÓÚ×¤b˜rt‰QÎa”(üöc¹ì”2tÍ“6÷ßz¤cóğ¶d™FÕïĞ.®Ìo~Î\±ÃÉNŞZ1HŒÿ^ßÔënÏs¡2í?í®ækLzM‡ôVs¢¾ï9ÚôôÈà7aS7§êùIMóÁ¡MÕ&ml“wàdh{ù!Ÿ`£!c_Ê÷÷[p F7xŸ;W­ÃÏoİ³ÛñL2à/ı«Ì‘uU‘»¦H"win2<Šóu˜Ì›$àæNÌº†±#<ŒúÖã°3}Âkœ‰©gá M°qw ¤;’Ö¸ÜÍ0õVS ÜI±ÆfªôÄóèØá.Qè¾KJ®kJáÜ»Ö}çq¬\÷¨\†$Ó¢Z³j[¶çØÆ™Òï(Bc‹—öâ,É]Oœƒ:¯ÔĞl“¬!œ—)˜'šd ­ÔQ‰Ş‰®T±åˆ E~ómwdï%&¾„™ÏoH:.=TÊh"’ñOV¦{7² ‡I¼Z´k£6êâ½Œë*BÛ„ZÃôÿÔö€a‡íOÜèdÚ8°•Ñæ7#æ—ÑãŠ§#ÍfúÑş[µàë_¶Ü–n¤TÀF‰Š”ª©<;şãİ›ÙÔîql€âú8¯mAÿÀu-ôJ²­0;e»†¬Â-™P‡1Õ4Pv’@–A?ŠÉ‘tKà$Òàû¼lTL¼ß¶Ğ?bSæØ\J’7‘~òì0¯3L'êG©7â®B¬pÈôi€ÙÔ¬9\”|2kmÖÍOö£†ÄMo})4”4P©jw½!mÕ2R<[ïºĞÓWù%/Îó•üªî[˜QR“7øïİ]	¸ù·.Ş,¶<(¤‘™îÌ+uX-ßßµt†JWz¿µ„0ìRmóx>s+4 íôÃ1Ò†§¨±×$®ÇnâV[HÆ_†}[„ËğaÊ3¸©”„E?ÄUIÄ¾§áïf7 ÎÍ¨L‡ X–¾/]™Ç¡Ë‰öO©rŒÁò,ÃÎË\ißÅTûävCÊ;.İ‰oßê)ÎãîÔÀ$Å’¢O‚`£ôqÚ`Q
Ô¤Å“ÄÈ-‘¤ËÆşÊnÓŞö†0Fä\­“Á÷æùÆĞ0!B²V°[ùİØRÎMsB§Úæ,h™è9@ˆhá©âBbÇoÊ»T¡;™¢h“Â>lDÓ}^Ä¸¼kI´‹´»È©ğŸ¡EJpÃE¬h;VÄ[(ş l´Å?yÃ†øûôQ›Èæ8àÁ~óP¡®Pò¿uHS .f*ÿ…4vŸˆ€F JùïVÎŠZ ÃÓ¾NËC4<U¯ª~¢ZM¸ù…æoìW9F£à…›òc•Ş+(deCùªİÓ¿!—ÊP€©n!²†şöÒóxp‰ÿóë%ñ±ßÛ-ÍO:]F~’{ÓÅhõšÄ[z²í¢Î‚(ŠwÇÅ€ÓëËñ^æÜ9gqÅÒ¾Yq*˜ÖàÿJ¥cA=¾»éöÙ “Ën2#EMİ^Ÿ&‚ì7°–›ãRCOì¬…àôe±ÒÇ¼ËÂ/ˆË¥Q ÿ“¥´.ş—Ì¿yÎqé	Ü‹öÔó7Ö½™ ±XYRc¢aÁJI7ÖN+¬âû"û2Ü3{o1ë¯)}w¥òb¡†­õ@¹²‰m*5’9ISà~|ç¸3LnÊÃaa0ŞXs¤æQKV9gÌGÈ4\UXcëœ`PC'Ğ62¦Ùä|ñç=í|ä€uÜÈ;rÂT~ˆĞjÜÓiÔ\"N{æà´™$Wœ,×Ûwª»ì"U°ç–)8£ Öº³‘š6E¨·¸,ÕQ£Q§y¶Nõ¯L,´¬`Ğñ2¡·á–{l ­91Åç=v´£TöQÌ€É¹K¥scG,.‡}[±Ğé˜ŠJ¤'¨WšCrÕ¨ââ_W(Píhèºk	‘»…-©#9"¾9+¬ıêpĞ,˜y!g{fÏaÔv•ª36.b\Õˆ’M™vmùCû>Z³OÍ¡k&æ8|v=çÙ	lM´ŸŞMŠ#;ğCá;‰âçCé-×Ÿ· d&@ ¡XšM‚dÿ?£äØ*ÅæÒøœ^ÅÿSuB…x¨–Ìó«ç~2ÎÔFØ@zG"´v÷nlZàL‡µ§ 57ŸBŞbïŠuØÀ¸„ø»:/oU¸fy©93vƒµ?‡'Ú§&e`F'…ıöß¨šé™ciÌÂÆõ3fÓp¾Êég†î]±qàÿ›_5'YSp“ü¡aûÌ;èíÒÀ€cñep„"veôEuyK‹ñŠæ·*Øıë¡ş‡‘HÅ›„MXn s4+RäÄëYn´É„pj[Œ÷9[Iı¼ÀT¼—Iò^áñ.Ñ¾4âŒ©IÕg¿@«`ÄÛJÖY*€¸è46ä¢ç"‹EĞríC†°Ş³>¬¥ÊXNâ×{Ş z²àİr8ŒŒæ×t™öd‰4¦UÌH8N­š®‹×ûõÓ˜,Ìxaè*ÕRª
ÔThëÉ÷S3]Éş¦MòÛ®§©ó¬§UÊÂÀFÁí×*6}mêülAµ‰$>YªÜ¡¡©¾Œ¬TÉ¡{i ·ç‹°q%"SBV44å38ÏÑ£rTöX!šªã1š¹¨æDèv‡Dé´/½#ï+ë´-mëUJßÍº‡Ñ¼BBõÅmòx×ªy©ÑM9š&?µÇáy×–xõ}Ô\šb¢?a s‹<&iÙõnóIUJI~“lpbûóCHãíËÂ¹‡=$!X$P@›Xç¾-Éû'ØëÍƒ1iÆc’„äšç˜256Ë&cõ8VM¦ ¹¡Q$4]ôŠâqN?İÅÔC‡p50Å‡Nh³W’¹C¯ç‡Xæ+mo#y·kÔÙ=â=p×Hu›
EİÎ:r/X€í8NLé´Ÿé!u
“¡ÔşOÆo-ì¹]…Ší"¹.ëaGa½GziM¸Sìo †Ë•#(«®™-´#ï)¥ü(„‚Ìx³!ë¯ãœáÒm	Rî¿¸z^~$Á¬¦<!†Š‘îGü¦#_Í0%â °ŠùÆ
<ĞşteÓˆÚ˜'‘ $¦¥ÿZıÃ›şó”8p‡Gv<®DJ’éo(ÿù†Qó µÛdè=*Š½ElİDcMØÄ|½2|¹iÍü^xRm5Îvc¹†Ú‹—Ğ¯sFÊT_H8ª!Mœ¢¦8xC‡”Ñ ú~-ôGe+”'H‚àq–ÏuÒrÜ°\ÄâBysµªh5'º½l<”Ø{6F`bZóbpŠV^Ç@¦†ÓT’Ø=M÷Ìê@Ë¡3wÌeô˜½©IÜ9¶Au¨½;;ßU$<·è¸Ãü&
‘6jïcêñ.ë&/Ëiä÷²"ÈåJ{ œMñ‹á ³V:oì£ç^Aq¯Òf”rnÍjhA…H]rŞ¤ã8zuõ$Ith½j®9@LšJ­HÉLB-â2}£Jâô¿Bél¶Àü¼SLÇX¦€ÇEÃcw,=‘34É½h2CYÔ‘°›Ô]ö'dÛıdÛÇÂ¥©NÀpİlÉöR,½­ÈÉãÔq˜Æo^äÙ“ĞÄ<şåèñ±Şd‰3kæâ²1ñ:yáåcÂßäÅAê€K¤l´B$Ô =;!{.IFJZ¬ÆÏÏ’bPÖ5¨†çİs8#C°³h“[ÃèôA !õïRÇ­äĞÿÔªÅßğ+Äõ° Å/Vı¢àØâÇ½EĞ‚3‘WÆ7]H[š¶6Âİz¥ı±¦Ru‰Œ»>™‹¡#:åBûF{äÒW2ˆ|Şô•D²w%‘Ä•€Ã¾ä7M´:Tr8Ğ=(í:¶2¨vklÿÁlÈŸâ¯²eêÿt›åƒ2®bˆ3>ÿÇ€EnğÓÑ˜£¸¿ak%9ÍK?ÛêÂXŒƒ$¶Ÿ›üŞşM«yy±?£–×\iñØp³âı¼-Å»g6„›4€®¼¢xªÅ½¬—"â§-VãÕ§ŒïS€!€&íÀ7À4'sru>µ=V¹ü=rÏ§YÙå™øjwÇ½Ü ÔeEÚ|FÈY/Sãè3aÿ2®p„ÿÙ	…£|Ã;w]wöa8É³a¼€‚XÒIO·LŸĞ£ËÚìº~õ„u;ƒÿ•ñ
\Üõiœ)«#,+1äË0?æš‰5%ájùÄkz×^ÀÈ%ÎšÚ/şI×ù5ˆwøå#@R"íY•¦]HïgÕö{q¬L·Ğ8Io9yĞÜì¯xš*¡k¢#(I»'m`õ9´EÜ›([jÄ4	€8‰cüÈù_,{ÕŒlR¥²òç™Wò©ÊEb(HASœæÿÄóïn®!9€r@ïŒÓSŸ#-<”ŞÍø1	”cÄ>Ğuææ··xZŒ‡dárõ
=Ñ)õ^KàoÏ›«Ê©J—L1o‹Ï‘½˜ì#pÛ|¯œX9-—Ç^,YÄRæ”®AËH-IçŠ5/ÛzÏ¹gÀ°{
òâ#'r2YpŸè<¨ÏìpÎƒ×ĞÌduY!¦¼	úıĞ{‘£û)+Æèïò-éïıõ¯‰Kj5ÀH6"lŸïF´?O9™UåH7d[Ö0ºÊÕI[¿¸~~I¼O# APÎI
o!*¦p€ÖÖ
¦óª_Ø¬½W1s¥ îsd‹bû²Gˆû)x§GVÿÜÚt^˜î=.{íĞà#dIáÌ:’zO}Ëœy×BàŞ¸,|ÓÚ;ªRybeç°¶ÍüÍÅÂ\ğş.£ÀE†)À„Ã4`Fõnò64úXø¯=8¼Ô€B¤k	¯ØÒØÁ±à	5§_üw™ïÓãEw Ïp×Â_Q×0Ó›°¨à"d´ªT'…—,rv«¢S/ïY,kDò²9Œí¦._\SB˜Š“ûƒ:°R†Qîqm¤¼‹'S!¼ŒĞöÃû,•1uLkV:¾"ŒSÅÈõSÖ¸Ÿ­²¼Á,ÈÄ	,Â]éÓø½l$ñ„ƒú¾ÍSõmèaå¶!A8¼Ô¤‡Bü,ºÜxW¡7şCÆºœú_Ñ%Ø?†íş—<GGÌ…PX şî‹2%¤éÇÑ\ßƒƒ.ñ05ğ“1™¿pÆ'M¬Š@Hpmğ­
mä±ıéNÄ…¦–ï›JMÇ†ÉvÙ2{èõdû3Å·VHş½›¬¯8ş­tšıÄ(=Ş39zg”Tãf4äSÊ[¹­Zq;ÿB¨Ö´z<ªò¶nLz–š¨“Š7“Ë[TèÙ„<İ«:yO´†9“Ìõ¸¼ÙÏï·³Ó"Ôøm¸ÎzáSyiqÈi—]áÓ‡ÁÖè0rJ¨—³k8Ë‡5£õO”ÀÈ¯âˆƒ-[L=l–ÿmúõl«à3¼ĞM€"É†İ¦¤F\1aŠD¬cÑ	”}Ôªò„†jmÖÑ€`€Z”4ØdSV*‡Uâ/„ÈãcŠæKø¨ë·sÒ¢K·¤Tš‹Æ;5‚«q^TTÓÛ"·ËÁ„sşÓõ¯*Ûæ¤¨¯V”/ª=—”aˆ9ÃúŒ9Ÿš'è«¯VE÷E·;¦²ÆÃZ¾¯fI¾ÒĞú•ş­\­“ŒsG ƒ°¾ZùGÅ&­áµr6¸ôÔ¸¿´ÚÎ(, 8¯«Ô-l è†]¡jU‹-<Z›AäÓ¡&(ş%» ı¾H9J…¥îgsØ¦ôo'‘r®j‚n!‰¤ùœ *o	[iô§€ò ‹şbˆP¬Ï£uè¨œ±Ü»8w©Rgxy’‚.yüº K—›^ÄH·>E¶íwh‚Ûâµˆô< e2eh¨’öï×A b¤É&T=$˜bJ¦ş^iª'ŠäRş0&s}ÛF¾êÔœxèœÜ&gÖÏM€yİÓ=$p®ƒ¢J°÷È|hğªr‡Á~Á*òÆvëcÚC¬]¶X´‚ürê º»‹jêuÛ28ì%¿$6Túy5"Õœ L9‡ÛjP¿OèùhÎ×|oœ»'ÌHŞÃCÖ“ÀL¢q9MISxŠ™8ää½ìğ×Ñ6w¼¥MÃF"Îõj’"rP¿ƒÜ¶ĞÒİîC×‹­Ijg\:ÊÚÒtrv’Y#4£D3>©Âã£ï#b”ö°…$Ò˜U™µe–e,P¬R{Åš¥Œ6G¿çàÀ.Ef¸éèüÆw*ú\«åÂi%¶‘iµIÛ< NVDMª!ƒ¢ğ‰g+a×Ğ\»K3µ4kÁ<ÌÇßWl8â¤!Øz í„nØÖ.ÀËzy-ãBä­„X JáÔ¨ëH®peàç×Nƒ ³»ÂvÑ¬¤«Ó9°
=%‡ 1Ü`¯Ê"ıÌ1F/Üb=ÅÒn§¶€häë^–!lÙDÉÈÁíØ§Â˜ª¡:İIfSñÍH™h¡yÒX¢§k[ô­1wÿ`j;iAG®NEûÛ©?3(w&ö€GH©×¯êÁ‘7Xw“BYM{Š/A•ìè|ã«û}¢ÄG Ü¨Ëš¢’x»¯¬¨½Å”ç÷ªd›Û¡r7–%°Pè…İa²Îî<½¹-k¨ªÿ#ŞäÃ0ğŞFß#*íîM$p3Nõ[5·dŸ7n õ\Õ¯«62Å°U./¨¥l÷çb“¿ítiæ`¶ú‘vĞRlğèh4HbLIá
§‡1q â©÷/V j²E=HÕ=bC<Yd£Ix=TÂ³Uùâ·´(}sÇé¡Å¬iİP4 ìrò–7¾Huİ ç—Â$é>•OÁ6Œ@¹ˆ(çãÿmÒÀT2)Ó@(ó{2ÃŠPßáZ$ÁhÌµ–YˆÎõÂL±·?Ô3ÓR½¨YVêu)‘èé@^BgM ËF cˆÕŠ0³ï‚ âo`Øşå¶KÌú%şƒL‘ò€HjúñD)Ä]Ñ{c—Âõ¤ÅÅtÍA‹aŞ ÿ"?| wÉ&g‘ÅÛºo©>Ç·T[=ºs„ÇEÒœk¤ï`ÁìnÏMUÏşØÓÚIÒmš€×òX}~şšš¶¾À“®Ép¡Á¦#©ŠN8 ‘’nÓÒÅØ /bF1|¯¶˜äè ¨KÇg?ı¡:kbR˜İb·qC €Qİ¡P~›Jä ÿZ*9Èšyt ;ğü>¿µFbXgi¯}çog8ªíÑ¨ñçRB^3¿©ŞPÙ stÁó0ë€æ¦ıù?§y§wD£ó)’åGã§¡ÕúVP| ™ÊÃ`«äX×ƒ«3X«S6°÷P‰‹/
é¥½nÍ’~KºW)ŞÎ~¦ß‰P’lAkÆ&*qšè[r˜ğ’wÆëù°ğS1‡Šºç) _ühõdĞ…XÉ)L2g$ÏŞƒ–}¶%{p—W³™¢8“ˆ´wPN-Xïjï¯³íBœôÒäi“êtæÙ¯úŞ<§¿NµøS&¸)ëWcKÈ]`T&¸±KÙÌ¥ãt©ÇÑ»åÎv°«¹Şj2“Jß"ùÒĞ‚î¶¯âj[G¬6õb®µóLúºùñª«ÍôãL³À9ºÒÿƒàÆhÉ<ÓæñÒ?m%ŠÖÑ‘ö-öÃU:™ …Î“#U]Ø^Ú4CÚ$XxµúºÉâ…—AN˜î“ı-¸–ô_oÇë02Ÿók
¦‰Ïı9ÍH]1;eTB&:']¡·ú,.”ôò' ÙûX"°"ewø³Şcï`ÃFWçˆEÕ±r<¸Ñ¾s1¯ê°$üúV¯4]&á«4é¥IQÃ¦ó+Èbˆ/ıˆK`«ÄËì “nŞzä  ÈrR:¬£¨d+d¹àãØ}ÑD ÷¢ÏØª¦dÇÜƒ¥²>Õl!óÔQ(Q[Cv®!+—óo†›ÈŞ|V?DƒşwİrqÕ&¡3µI:g<·¥7N»´ú3ç·İ42ıo ÈÜ¹Nµíı`G.ƒİbö¡#7NÉì'Ö=¡øT«e:{%'785u@ïì–¡¨ÓÉ
v -©GcmVHÈÉ¤ìÌ÷p¡Í“ïûßƒlp	‚°Ã– Áåo’kËšøQp.šw/˜¹¤Z¡§Lò×LhºÿG¹ñ:Y*éÃòÓg.Üğ|Ò‘M¾á½XïÅfêÑšŞ‰…çWİyKô\Ï{Ø½˜}¥¾œ€ø*»'Ğ˜Z.êğ›	*ç&–8ïQ!Ÿr’z%aà=‡¹É›í…ykÃWvÓr¼šw»/e §Ã¢±m]âF±8	Ó±ÍƒŞõ[£Úpr7€ÏS§)’xfµê‘mh(g.Û}“ÉYyQ¾Š JXwêâO;N[s]ı% }§™Z¸3DHJFX,¿ ^1‚/WúÀÏB&~ÓÇÚiìuù#hJhB×A¿ĞŸ°"1‹Í· ~ÀíÅ¶Üæ+Nñ €Ï¼`°DòåÆBÌi£9ÂbyC³Ñi¯LàMğÎWE„ÑìwíwSC«V7©ÉÚeµ°^â‡r?XÓé„UŠ+u?”N#ß_£üÓ»°h‡Ûº“èÛ±mï<^]à^Š€ÈšÚ|P¬WÖÓ´Œ¸›º¢Šíñ©"yŸÄØ¥ÿWb•<k!j2L­c¤Ûß%"!éÄy/¦©ÏëPêkòS­_eıÙoP¤‡ëDÛï `e4IV1ãÌW„G2áÌZğ¿ÀæF|=\Ûƒ½9Æ­”]®5£· æJ6PòÛJFÕ@Y;43¾3F˜³ÙƒIª	òi¤¨»€?¢†Æöf´¬Úw#»NU`ŒlYzêù1>´q³ÁAhãôm×}šyüíŒB,ÎQ5Ÿ`cÁoÆ0I
…ez&|[ò‰£L	ŠD(Xšß½¯ãÎÃC„5ğŠ¯KK0ıålöTëX%0áÑÅH9£¶P¬$Úè„Ã—Rê^/Å‡”œ¿¼WÄlD ß(£œ‚˜ç›W§vk¼¶Ÿ¬ü%]Ù{™ûUZAïD¬+Íd£2QÛ6>z2rÍ›®ôßhaYàTb²ì’z6¡¯©ã-³‡a¦ĞDA§³íwF~>Õ^nœ‚ØÊ‡TÓ®”O¸4´lyA¦àNVĞ" sÂåe3³S(ÍæèIâåÒiî›~“V›êç¶,'qµ%Æf;V +%oõ Ù¯tSÎÉËª@ı|<C7ÙŒp‡YÌ‡5I\%@àwˆ:ŠæJÇKjŒ†Ì}ï=š­–‡êMøØî ø²+µ2$á¨vs}Ş:f§vüdˆèC°(‹o‡*’¹D‘5ÁÖé¿‘^UpŠö–òE·JÛ~–Êß¨fÏÅsf] ¦¼/P5ó£‰8ÏI—Ş˜é/c§¤Ãv ºìnµT®×*ğyæ#r_Cv'æÎnƒ$g:é­oîÅùæ@©ã5´º.Ï4>jíÀŸ
¤¢¢k¶1B*U¿ˆlóWûül¥&Úáe(3X†6/FÁvÍÓÇwÁT¨"ş“cKÅÆYwÚıäøÔ,@Ã[ğúZcLÁ¾ƒlİRß¼8C`-WƒåkG\ö<è~àø7Àİ”ãr[J´	z¾"æ]0Zïı9•ÅL¾2h2Í|ÆÂ­Ï|t’OÿaŸ‡ÏĞ°¤šİÀâ!nmñÚ’…ÂKğŞ{Ç0ŒÏÉƒäÇ!os‚ÎiÍRV)<œ³ZZ{îë6•ı¾ÿøõ)>²6gŒOÜXc¡õ¯f†Gß´§}ö,<„8Øeg
‹´A¯’I*¿	rìÒ:“^	8t“„'2±ÅİÑäŞtq-E>ª|[R—#‚‘ï]µbšÍOÈy¿¹Â©s&UÄÂÆµL,Hg)Cfm=ÇÌ?42df.L4×¸µ¤Å»ˆüîŒá‚]G'Á‡ŸØ@­õ<70Åë\O!4Nî³kK
}‡	pÃ®k>$tóPó=œ!YT¬û4àó1±ĞÁÅ)Fñ£.ß©¼ÔBzªÛ30Ú¿†dœ?	LwÔr²¯Z®‘}¯X:ËïŸ‚`ï¨¿°Í¹Õµk‰WPJ4’r}ûĞ5QÛÉËNåú˜ ã÷lÿ³
„„™'Ã`+f*ÂéN—÷Ö'×]Z‘uÒe<Š8cR\àâ–jhR8Æù¬&€ì±îœ|Y(>¡HÙœË½íıŞm{ÃÿäC›/|zëûÓ¼·ƒí†fÅû+É;‹İ¸çÔä…ã4ãKùz6ÔR+/¾ãˆŸ×l³R"B[°³ÈF Ï‘[Z“Ú9u91‡„wn×'·ÕÁ¹Œ¯ğÑH%Š^3°ÚÉÍ ¿yGdÄò‹ŠK%†!l½$•7—™“½sŞè•­‘%½²n;»¹hÖ#pşµ–ÌcS´tfJ`mÊ´Ïá@|B`.…X:|8ÅzÌÂd·®$5Ú˜0ê¤%ñEmGìØÀl\ÊŞCºÙÀM§>ìBö3”î_û†~š–oO%Ì0ÛàôºÔ	Õë«|®5:«¹ŒÉªÖéQhf¶İˆ	KS–âõíNòÙWøD¾OÖ`?¢ñ–ù%}O’Œj÷#QÄ¯PC”£)·ŞÇ¥F„%9İ½'fKRs§üñ¸å$äõ‹vTXrûá§¸ÍlB=İ9Œó$‹–m.d/§s->G'_„‰ÃæÊ?ºÍ±·ş»(²pGëoíæZ‡o±=f FgñK±8ZìèÊwŒF{‰4—’˜4„—Úö9Nos’5“Ô¢ôBTĞäVìÓ Ü'·uËVVTì™ø;“ÔÎ`–k2ƒj£:óX«
íÒMÂ;üOıV1G‰Ñ|›ş—ã‚y{Á.ˆ¶ÇÚ¦YĞltûÊ”³pÅóG;”†ïvrîBk¡~Ánq9ƒ]Â¥®%9r¦VÕà¼¸-[öÎ$4´ºËĞßßÅ†:Âîÿ3ÆˆçxÃxÅ³şL‰ñj*Ò¢—GT–)f8¼¯Ã'…êµù¤ë™!«jzı·Ô[èÕÌèuƒÙ„Ö³ĞušBÍÎĞõUO
e€MıË«GÌÍŸí$T
&áŞ9OÀvËWˆidˆ‹u}–ºìªj¿@eÊ#)]Œ˜C¤0zé±Í¯-0«1IÍØİï Ùo¸]à÷QN,ë‹Ij»Î…»³™pqlaÄ#¾‡[Jµ•¯ßF9ƒÒ/Vğ_GÓ+eHüá™Á¯û8Æ‚p•öœ°Â{—^«½á“t\1¨¶2Ï1Å$åŠ<”¶1d•£q:!ÙŒkğíóU‡ù¥W¯\ÑeNĞE7*âãyà(ã¡2ˆøè:çó†ÆJ¤N©À/ßÃÈ{²Á•?0*è0¨ù–šEB×Èø>
#èÉI!"TÒ¸k,rj¾\¡D›m]´Èmy•zÜçt›J;‘ö*ÖæØ ›÷×øØ·–ö DíÀVjÂ\† ;d²^˜“\‰>iß¨!èşhµÑ˜ü+MO¨ÜU5Éñuí8ˆv¡u¦AvàéB“¦ àÁ?XÔÒ±E™—7ª¢	Şø« ïùEÑú¸V”"0·ˆÅ¾ìà«üRZ¤ûO$ïÒÖsêf7Ú`‰ã‰vÌ±ğhx|8ß,//¶Cş«¿üuèÛ¿ğWèAu½±´¿½ebLÕ5A¶!İGŒ ­'”’¼„5¥ÂÏÈTm±†4fOÂ$Ë»ü#›Æ¬|Ó€†t9]yÒD5p”2ÂîãU'u›w†§²´±@òº	/rTŸÎµÕõCH3®³:ŸeE•şV8x37ğâÕã«†rPå› _¿S"›I”ªàÇS±[¢oÛcQM\ä>ÎÑR£ZöĞiO8Òëš¸ï[ØÃà…}yGQ³ó=qh
Û‡kevÄøuær	…~ä“>`ËÂUwBÒu§K¸®9*Â? „u…Ø
p1Räób1¤sÍdJ&CìâÙkS'ö‰¹¢Â§N‹jİÉ£CÆ­ßÏ7˜³”IÅ2ÊÊOàµ¼Üà ™â±€ÄAÄ ÖdkÓ&§ß±I?Uûò¬&6ÎÁ{u®wÉ“ı 9ê£p†æ Â Yâm­I¡i¯€çCö3¤~6Ì½~‚¼G63ÃxÙì²qWj#³¨ê6ÌÇG°"˜­ÑÓÙá™ÕÌbêóGQãhuııÆ©Ta‹Æœp*…PÉ×FïGW+´4‹˜Uq½²·Û‹Ç€¢|áàtŸL¹dOûS®8©÷3§oì»s¿B©G×{*ö€‹?!2FXÆvÕ¯ŒPìCÑ}·€À(˜RÒº/PQuvÀeı!`·¬’‡RI`â)ù„+¨–"y•]ŠCÌõè“Ì~ ÿwÜ·Ç&ÆŒ2+~È›“#wú¤!~Ò¬¹Ú@ª|û2×§Àu ìHÌUd¾èî·é“CxPŒD“†¨MƒiN†wd‰À8©¼'²˜ïf7Ù¿à ÒU…¦6V^i‡‚OZ˜Ÿİ¡^B«Ü¡åé(|åX/d~Ó%ZöÎ÷…íf“7Gå•üG4)ƒ?àDYšZÏû.Ÿ.Ñ‹ë¹ßbƒø§•®gÀÊx{[\!;´ÒõÅğƒyÇ•+ö—®ÔYäˆB3ÑtİLù" öÒF{h nàÌ"Ú0aëm†¡A¶¼·FHv‹ô%¢N*Rìßn¿IO‹NÃµÀ
²•‹kúByE tøGPB€äî«$ 5ó…™c9ï»‘E~Ê155g~ÂÉÙµ™ÚCP& ^K+ù¿‡¼©(Ãcš0ä-MZ˜Ñ_É-‹)AäÙ+zh×&Ë£%¸C‰–¿ÏeW>)íBüÔÃ‚MÕi±~/°²3Â6Œ¢½í®~îîhsJ,jà¶~ÚÊ­På€PiÇ!@*÷–‹u†¢ººç7C>\œ‘†˜—=.
9‘ı\çš@üÒÙ%ùSşË*ï©™Ô·‰D	âÉò–ñ:³ê“B®Šjj‚ÀÄQ“L³0pø}÷}öŞÈN¬şû+Ej‹Eˆ¶‘–<t |(G)†ñ}'HoWÆOiuL
¨aT÷Xëd“,)3jÁšñáMî!ãJ
•@ÏWÚ³6joşjóZ°‰D8ºşc9\}B°2LÁÏœ“9mDhò†{ñ›Ñ*õ».5ÖB‰&Ô_E‡ÔïŸV¯“Nk;º
k£ß|ÏnT³€Ukïf¡Ä×z¾WımïõåBãˆ­csúÚ{™°1·ŸŸÊ%¼Á…ÿÔ'e÷şl¬!%Ä³¿'0_9BëçğõçÂÆ÷¸0„Š–‹&"ú‘‹–­Q‚D˜äZ¡±M1“bYöîŸ¥æ¿z„]|&:4@µ#£½oÂd$á/“@‘·MÔU×ÛÍ¤ó?âJgaE=¾yÊ5âˆ'ÓJøş½”Ífq^]z+«möçê,üí²ÃÏƒ,¯oÆh:­M3•Vß¡ã	S»ú­aØF”Lÿ"rŒER×‡°ow­¶49¶˜
Š¾e¬óÿ¯{=á&–a$5›f®?t0(<vsÜŞ°/¬ÙÉºêÒz«d	I¿¯1)­:ÓE£Tà-]b‰.(Õ{ì+Ã±_k«^ûçÑº®3‘ZC*‰AÜ,yE	Ùx§M\É9C¿ß¬dÏ3Û½ ã;+Ö¾Ë€€ä€…‰dt+œËØÜôÃ’#"è(Ì¥¥÷Şô„›CyY¡W/è¾ çïŠ]ü9Çã²i—¾öù°A›¬õ‰ÕD;æKd%qºA¯`AxñÏÒ¡–Ù™Öø›<ÕZÙ™pz ³&$*·+“C‰lÛñ€/œg¿¯F:²í¶%;ø‰á å ï—¾›¿eƒ{Êş™{[/)Rr÷ª¶å/ã>OON)ûàúp…rÁœ•ß¾Ê€’¼2µ4ækAaCæã1•Öé³%¨©˜/´‘œ9&Š¹ †¸WiÍ†öÌEJVhğRß™ç‡¨hÁá°lÑlğ…ê@Û¯%ˆG^Èêœ¾¹šŸÓèC”§ÍØönÏ{Ó;–Vú=jv~¶xâvùFOihÛ•ĞÎï•f}=…,‘2qª×Ã7aîFz6ğ¡+>8}ã”¦â¹ªv/)nÍŠÚşÙím½š¸ ¾¨ågí¼øU­Ÿ_–ëøª¸ŸWCO4ñæ3æ‰à†?ïòYÈ]©{™Ct¢İ"{¥ÖÓ»à&“I3GwZÅş¡o#æló£¨Í KÃ=’c*ëŞnï«E4«´µÔˆ…Û7ÔfyğRªÂA¾1ª?¦¥ò=Ç1š[òügg~Øûï×*‚*” Şf"ˆnìóèh…YÂ¢Àñ²‡¤ù=hW¤ îŠ^:–!Q°ùA„ìZğ“ìr£¨¨¼“Lª¡eùŠ0Á{›ƒ€Z¶ğşÃ©­Š¦K÷šì,Úú2×ŸT‰Â~j«3 ?Ï©‚=İ
Vâo|¾Ÿ<şÆæB${Àõ<$“&Û|àˆWuLk]h')ÊÎZ¶z¿9ª*öŸ¾è‹—ìm7UbuPS¶‰ƒ¬¸"»9…Ä_Õ¤%DãŸ€.I|­µsˆ²/âú
	ÄX?`Ü×çRM¬îuCªö†SYÁ/¸½İ&=dÕ œû8È³$²ş[ğ£LÂj¾¯è’U%7@ó'ì¤ ?” j{òÖ¦Ö–4Œ›[-~Ü!*'3Çtò’Gò{ïfDûò6Âëv]hG™
:èsØÁÒç¼½ü+µŞˆiÿ4Ö+Œçï;?Ehl¶8…qSÌ¥¦ã²ÿ‚Ù›°U|`%¡<ä¸Óâ7Œù™|®p"='¨ˆG›£“2Êwô€¿ç]ê6w#¨”ï‚
Ñ¹[IêT=CAxLÑ©–*7ÍAÈÿRIÅ¹Éjf£Dã‹ì˜É,ü#¿}sˆn»‘eâ]²á¿6aÚKËÀ=^µ1³Á¶šÔ‹{¶WöM_İ‰A—· ä}ñnêì
¢M…h~Ketp?›ê¤êúoqOñ	¥±z>h€²²&ùßŒAÙµgª¤0ƒÂ5ı´Q¾$Åq*)—ôúÔ´ªÇw©ĞëQ9¿’dV˜2˜?6Ò{;ëz¦m~m¯¨aTÊ‡³×ªü}àkØ¯Ú«E½Ô.$Èÿë1°JÆ›oå}€6»€|FfAFyÔ€·ôÑé‹Õjã„S}Êa”£0ÅVã˜›à#ÂœÁ"wœz†›$‡&W;	èõW4®Ã7wï?Ìv-³Ddq?nÕ#›Yc7C"¢§ğS6Æù°[±o6©ı’‹ç¡±ª/£¬_fÚ…	aé½Ö¦¤É½¨eM0M¼U˜İ 3°C–UÜ¤ÚÜ×£¸Êútm«Dçf€O°Ò£bÆ•n*<å¾M(ËÇ Vº€9Ó®ì;96¢ˆÅşÒÁø­•J'CuÂ¹=t¹ÙnºtŸÿ¹Eç{qÿİ%ppÑ@ËïzoY|ç÷‡g•v ´N#˜:”-À¶ĞÆÂöVh—WÁ¡è{–#æ]~rEñšş"'+ßˆâ|0‚ù*#-!¢{]ç·İÁ­˜Şû"êéÀ÷xÍ&MœëĞÕ ÈsVÃÇRœÂf¨)Ô^G"éBE­jáÇâ¯Eü‹äŒm$ğ¬oœwLº0bÓíŒ4Ê¿ŒF©¼¡$Qª! Óki**U©hP Ußjiä®e!ÿ-“Ş'ç+â0Ø:=*Û4ëû^ßkQ9ÂÓhæK\‚iÉ‹‚^yUÁGe%)Ó$ö×¦÷%¿ã?¶>UáÃì»èzÕÿqÄ²À Ç™ˆ»ÒùX	˜Û?È ‡¹Â’o^# ïğ`YhÚ ÇÅ
7FF™`Íä3mÎì·³.7õ?É­5 hş°¾¥Rr’§GdgiÏÃFœH"»öyĞ™½~N‹c¥â¢î+µ7}‡SlĞ	Fù¿Íÿıò=£?PPãˆ"]/ˆ‚şõ<€; p_€àˆô±¤ş{HªÖ²³ÀÙ¸jí¢ÎmõØ=7º$Ãø&±
;FÌñS¦‡‰FB{'Ö;lyüXşÎ¯ƒÚ´]f¨|şŸ·[?øú²-ïs·È®±,Q[r/ÀãËÄÖŒzßºÁñ¶OPÕã[íÖé@|Äí±ÄLzÉÏ8˜ï	 45Õÿš5-R¸Ç6À¡ÇÓ.O²Ú #ûµ'WWšÁŠ¹‹ÏïÉ1İ»(MU8‰–ÿR62Åû‡˜şk‹Š <k£ÑÖôòœÉÚ2övŠ†Ç/†ğ€¾®^—¢nıî~z‹lY›
xq}¤¬ç•†Á1ß˜hX¸éJ‹6t3DŠhGÑÔ«hóÂ™¢WˆN¦63«–
Oš·M«ÄDÚÅ6ËcL«Gê"æˆ©ß ˜7ò=Ã™%Èœ0p‚0¹‡æÑşx±]‰cÉ:@¥iÅğúwy ¦¡üO&µ´iÍƒ=,©?ún¦R‹v59€©j½fŒëÀ¼jª÷äÀAœ~_1™…2^/üumúÖëæLo¥[-¼Ê Âò…Àğ¶¿ì¢³ı[.9”¨ŠÍ…€ïÆ¶mk£æ–¡eñA³ ó¾´¢U}ùÄ×­BDP±CyB|wÂÊp±µ…¢/å¬E«cßÓe†·Pö¤qE6çL‘e¬:±‘.û`ñ¹âÏˆ®¾O |¢ı*´;V–KÄ ò.Ó,§½ ®÷ÁnÑñjHØT’ºà³«[Ú}µº«5©Ú…áùr#á}Z+°ê¤{ Aï·²Ä'Ñï­±óÉ‘ÑV"ÏßĞĞQäAwgP¡­wÌÖ KµX)¼tšG„«»ön´o/V%2å3ûy1Š')ÏÎŒzß*Å¦Á¸ésb­.Y!];Õ¹ì¾÷7×+!÷'€NòßrmòzoUÈÚ{<›zÙøh—wÜl+–·Éµ•5Œïk{C}¦Ù»)4UÛ›’Ù0º.ßDHÒ#YBBZõx¶ı™D¿bÍ±*nÏrTlØÕ\cLEZÆÏÙçÊöyzï.úàÛ?<:hôúb{ºLí‚@Œ= ÚêV?ğtTô³şºŒã ¨ŒÈ¦ºŒa‡Œ-^,`¾Ñ®«Ø÷_\±>åQsp>f/¶u KXqĞ¢_KÑºÅ@ÖÑaZãˆ¢Ã®%A~ñI*‚öŞ÷ÖX¼0Ht”_ŒéÚî§Sç<4#²‹ÃáP)±`¶˜¿+ÿ²P›İİkeÄ˜T´¶À)eğ¾Gî¥ø0'‹	‰?Q$­½ÿB\èÆ+íÍ³ÜÚLXà¦Ml6w8~"/?†×5U5Ò“lU3>†Üã÷ƒ+ƒ°Ğñ”•(h™E)¢Ú?€â;İ8®XÔ/&ö.*d^û†éG€´É}Ï—ŸMãÃ5@ã¡ÏÑ%°?‰QŸ:ôïDÜîÄKêÜ6‰ÓÓcl™©(uS:·8¹CEãÒ‡ş|mßÁ‡*m2÷Ãİs~ƒÓ"_şOop6çš­ÁJy²‡JÄnîY›]'Ö ÃŸ'Æò¸š	Çk·=W]Î7Y_ß"‡¦¬
jnæ³`Ø^XØŞf7€¦¨A½ª²“¬ ãuÆÉ~°©W÷… ‚æØ)’sëÊáÿºÇğ}3œÓË¥é…ûºÇã7¨@6Ó6Ù*³îR0•¡{ùmU}à7/]CnZÌh§ÿÄ~&ØO˜­’÷üüÆa~ÓH;KÈ¯'XkêèëüvÈ×¶²ıôJò!¼cÅ'©ª‘<“–- h|yŠ:¾_V8cJÓMTù.
ô4&mhŠÆ¿‰3ì»¸øiP_`ãqY–+jÛh))ĞÄ÷ÅèÎN!_šlW½…™À£öÏ/ƒfı“–˜?3záñôgãƒBq¼-!Ú(zÁ ­õw¢°3R(³Û,ßÆÊI‚3_Ì’t;©vú‡(ü7Ğ„^åƒÚÁĞĞ¦;Ìi´L×n¬S²|
C™1‡Õ…S¢È¤i€&¥İ…ö¨§ÿCñã‹,ô®$ãìÓP:Çæ…áJ@Ü20©Šö[$î\°l\ƒ”ªy=nyæø)±7&zª”º‘îpş}ä2§ÖÃ³'êÙ	87E5¹Äû£ã±{ òª/AË5‰'®\¸³¥Sl@ˆ{(Çü®Jğ\8 É&HåòÏ¸íá³A–ú½ÉÅ9bgro@“uRİ@ôÈ£®¯şœ›+TÈl)?n™`Ky)^Îlˆ¬¬óœFùæ?vd€üëğ>2l±’|9ã^õ±ÿ¢d0ñbax‡çµWZÀÉ}{ôãJPQÉ(]/Û®=µI¢Ö‹AúˆvŞJïxØ8C£¥I?ÀW«²Êo5”ŠıkûÓµ¹ÏÀFWÊù¹ïï(œºãq"¢Qı_ôMA"»ívúAÏ(ß*íŠ ´Ã™Ï5˜XG™ÓØr_â,ÎU‡~[©¿…ªnAŸèGü=¥ó·İvÍ‚S"ç}VécÛà¥Ör¼{õ23(ŸÇÉğAÃØQ ÜQWşû1˜\ãÎmúÊÁÆÕ¤Óº××ÂŒG·Ük©	µmÑÀšé8tbéQz‘tL=
ñ~)ÿy[‚Ó;O+¶Òœçó]èn"5õL¸LVÈ^Pûê°–7M’éŸİ²nëüŒPƒ÷ÙXŒù‰ é¢W:753XP>ïx# óìëÒèÈÉ#:”¡î,GÖWiaÑ Ûıåj4W©Ö_¦78Á·ŒDi¥’.ïİ½Sxün†4ñV½÷ßs¶™]ßr¼ Î,#m%õlÇ­]ä;W›ÙÀ³q¤RpÉGhµì©´Qi²©v?6)Ö4ƒá2 ½Lß»¥¶}Ú¾sJ\Ó¥Õú¨/p#T1ÒHëÈ÷îİõ´H‚G…A ZğC 7ñi‹›ä›š% OòÓwÃ?4ŞÂ•ınõ*¿ŞJxu¯9¸+5ìÛ­€¹~iõb×§ÍóZ»ÑaLô•áÑ¡7hÙG8zôKIÑp=
ÖdÅ©mÚYá¬_“Xİ×*±Š#§zÿ´„¼Rt±E&É†¤¹ÊÂd#Ğ*c˜3nn»PQäò PpIpQ‹ÆŞÕ§Ï¹‹™˜ş:ñ@E˜œuª¦úì|ÔÙîûÛèó6¸¼<è…XD¸'ÌŸ7ôc•%Æ <ŒuÃ±UŞäyewŒ‘dÄİ1AMáõ/$qèaÇ®Ö oÜD¤ålg[7šòø@ù²Íby×´„Ê­ÈÀ½EÓûå™]²5¥ü´ŒsØ…éÓ2Ùƒ“U­Â	$Û%ï¹8m$ö™KM‹L;²Õ4¯<GSCüu" 2`ïïãš•wQUszæÖ}b“ù¥<èqUİ}î×ëËeå!áß­,D¶Şá$Œ¸ja‚ı²1üb]Eƒök0Òiú3ëÖ	JÑÛvÚM·hÕ õ9ñxé-K>=%ã9¤Ç 
UNêNbXİN „.(
6\{`éä–äy{°9Z"up ¸ÏĞªŸŞ»æükkºPµ÷¨¿âôàAÚb¥®D6A’2g/k/Æã¯–g§ÀaÌ`Ã€Mš´.20»Ôô*a°ÊÜŸ9TÔ ¢¸âù½¨İÒéõ6Ü¹Y8tïÃH¨/9Yö×çq±ÑÊ†hĞ,)cÕŒÌs~…Ë7İ8|&qİGARÂÒv%$ãìYİÔ® {¹§TéA6'mşŠ¶k5ˆ&¨—úÑıí	ô´¹¾ñ²C—hşhâó«÷ã§¾]ô÷wÈwTzá|Õ±ï™H€m¶z8¡ÔUûæ	Ğgn/H×ü™A¤xË}2ŸAßLXje¬áè9KB™6‰{-kœ9-k¥GšÙ ŠôH>Î˜)c@íÉ‚¾4×äHï|Oÿ#&ŒÊÍ+•xZæ›X’WQü	zFØm©c“â²eJİ[iÖz²·àä,dŞ-u)äì¶[)¨ 	ôê.¼Áëş2+l¶T§p°nZ¿ğò¬bpÉıâÒk©Ì˜7ô;pvSâk´7›±fşú´Ì)‚² ª~;ày9èÔ²vµ×5§3ÕFÕgğsíY=¥m)¢0Ô)¹ó(®ã¯y…œ'5PIôòîgî;æ'—¾S.ä@TÂ!”È¦qc¾[0a™üP¢ª8¬yÆ&5gşÌ[OÔ§ø.~ƒxYâ‘Ô=/Òé|m¸w ıÈG¥úU„÷´{¾È}ùùT/Ÿ¾_n!¶U˜‚Y•q“#²yFQù‡rú©­Ó²JI†ßÏı·šÊ“®ËÊBqxè÷ûä¾f5$ƒ­9ŒÔÆ
ŠŸ=vjÙşœ›Y¬¡şŞş	ª|_HYr±lÿ¥&Ï¾5¦{¦t—ÍÓïÀ«½—<›uzD~jHÁ‹WqÿƒÈ‹–ËÇUşğ´à/9`Æ–ŠK‘2%o„õ:eÀËşø¦¨R¤˜2Æ¿Í2¡~ÂLŠªB£ \¹ˆ·`Ü{P¹sªåD®{=ògâşnò‰Y&b°ÉzÇSZNlš|à¯nàŠ*S…8‚ègë¾[á9VWiAyÉ±Iæ]ë·–bÅ³W¦-Œ›rfÜ¤ÙIî d~´CÊq¼–»Î'àNÔüFpO¨âb—:3üü+ñ›fÙí8¯¾+şÙ¤ì£g~Xî6ü0FèòCv JªÓHüÕ9n-4A_lšË™²+Œæ-J•@ÿ0-…-sïôè9À~.Ä¶@øŞeûü1¤ØóÌÜ}¬k¸‡ Œ•2+Y½)$¼n·NôÀ<Š¢ĞTÙ²•VØ'¯"±@ÓÃ2IÅYıà×6E$êQjL²ÏR]Œü¿ñJ|–SÕœĞÛôÆÖ%“ßUÖ‰xg”kEvGÑoå°p_ƒ[YsÎÜæÕâá°‚BÀvk{+EÑ u¯%ŞĞ 'áİè²Şt½]yZ_ÿg>/@h'†c½s9Ë‡ ¡S[di¡†èH0.DÈ¼ËXÄ²ˆzK^²¼ÂZ9>aË¶hÏ¬‹W§R¹’×e ´ª¿ïlš$nAĞÄvOú¦€z’çÖ.¨õÔyª§.oÎWŞªÛ…7d¸ª›êï„WåU¿—lDQkP%Õ3ì Bß:µÚÎvÉQÔĞB&°Æy|ßœÈÎT‚]%ª«{9MÛ)ØGµ&zZ-µ ’ñ=¯ßšùñPk‘!‘5­ùü”Şe[F9Ôœ(ÇÃZz‡Ê<@qgÃ¢XŒ®í’%>ˆ¤tË³êÀQ2ğÄ˜jÔc×Ã‚½ááÀ¾O|ãPñ%”îáe.ÚexF<­S?.Ş&±‚ÚO°üe>ü
”Ómšo•bÃd—Tx—‘bºlóŞ ›Ú»®Ñ!¯Q§ÊäÏ ö¹½'JäªO!óÎ)™Ã:+»¢öÌî·iyŠìB„C€˜CáwVg®§¢“µåç¬t«ªó;İ$X²O^ İ9Ÿ´ëså<²×ï4PÚöõ„Â²zş0!y .¿ÒR;>î\\Cö6š-Àû!€_şØ7o%v±¶¬¹PìÏ?œ?á£h bIès{'äÜì«ønuZq'L—¿4ÿğÊÌ†8‰óÕ(Ó}¡Êš½Åú·+èP«Ä+İü—Â¤À7¡éÙ'¤„¾
`‘.ñŸÀ¿ƒ¤|ÂëC•»/Ú¾}ç™A	µanŞ(e±Á¶ºÇ¹Ûbw±?`umÙ1'Û´7–¼ZÇë+HÍ­·XKb‰áEl¦é¼ú¯fM‹±Ë0Æ<@Q†€±8‡Ç¡$›3Ë7hqØ+H%°
ÁÿÎW¦¹–èğ™ˆ»Æó¬ÌM(Faß£1ƒI2Ö¦cĞªÿEO%F“5<tèğE€‚¦ıóÂ6A‹*£$_yW ¾ıpg’F¯Ç‹ÄUí|¨ ‚á­İHóÏÆ„  ©™ï­Ø&o Óº€Àá”Ÿ±Ägû    YZ