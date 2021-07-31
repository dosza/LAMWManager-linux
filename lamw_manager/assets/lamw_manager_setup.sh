#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1971418583"
MD5="d44838b08a710acf2994a1c2aef303b9"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23120"
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
	echo Date of packaging: Sat Jul 31 04:02:07 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿZ] ¼}•À1Dd]‡Á›PætİDö`İßğu èÛéĞR4×”·u…¹Ğ|( ùä´˜B~»m÷9±b&ù¸äïñ˜R<Í–Û[õ\²rfÇw‹êŞ§âs%G¹YN¸k	…Ä5Pp'ø×^ó¬ã‡Kß¿MCµÄT¹êB~õÀôÓä)"ä‹ÉX#Âèa1öÑ#é›Ï>ƒû[”'f’O„ğÆ)Æôs¾ÏJEjqÉ(pé™ùéSfáæaÕ³9àP¯ç˜X—BB®JªV¸è®Ëüe¨Ur­!¼|Ï§â=« .Så"ğÚü„„Å˜VÔ÷¼’xÌÃ§fÊ¾Ijè=ãvUA³EÒüéü¡ :4ÿÓOÑTjà6çáÔ~Ä/äñğd½_ïàÓ3ÚŠ&á÷Êá«ıâk»š¼~.şoÉìÄšõ³X]f2R÷W¯ª“i<µ}ßYx'¨p+¤«Ìç²x£‹¨uÄEqåEÎäi‰•aN±Ì£õÂb1ò®y‡.z”±ƒ”	¿_0¬q>5x_üB6¼z·­Ã_%˜%×Æ½•;h"S²şoÒTÁ’Ç·†t«vxÒÌú¼9³®s¬·Ô¨Êjææõnßñ•f»€Ò’)L#÷°“"è$6Ä‰°|y(î<_'ßÒ%úZ4iÏÉX.¥Üö<SCº±­’àS@¼ì‰ÿ{Iš±ü¦°r—³ í›åş –Ä›®!&8¶ªdR<Ê¶ÀiBğÀÚ\û7K
W6 ûoşælÒÂ]YíYgÖ?*T¬I++OæÜîsÈ‹XØJ”œj—ˆçjF2yMpĞYbÒw¥SI'™^õƒ
>4–Ëœ”Ï
‹°›¯o‰-»&UJÔ8 Üÿı&sf$"Ãï’&ğáSyvOe'XÖ¬%5²Ü,†‡å[}„Jj­8\Ç'+*`ƒ¡
‹QH{0sJY¾WÇ”c+^©3Og{KØ?4}Û7Ê~öJ²v¼ÿnˆ½Îú¾TÛâÀ4&»^ z¨:»ªÚıêè½¤¿ƒ%ˆ…÷~3JáßÕƒFb2¤®hYÉd†Ùß~/¿Æ'1ñWÉyÁß²msŸ›8—~º =oeÂh!›™¢Š­º<¢%–ºfäÏGí‹¶ç} ç²£ˆ‹¸ëîÔdMğNDïŠiò]Ğ«qËÙ/æšn„a­mLƒÚ8ZO;à
*”cÍîAû5`Ù^Ã,üŒ|GûæêY»kx•ÏmÆbçúZz
pÁ‰‹>­œ^7®–—À)lüÃàÛrÌ„Ç%‚ÿˆ4+›’;(òÂz×¢ş*òñı¨½„p12œà|‚(¼¼{E
ğí<àî¾kó9$hE" Ë™A=J”Æ4øSÖ¬ÎH(O`PÆÖqvLœ['ä!KĞNB\Í_S7c¹AƒÂZ~8ôèJı Ë¹H–ó‚PLŒøL
Xæ×—€İPJ¶än™4ò˜´™(» óô4ÍVROõ0É[~S;‹Vßu±ë¸ÕŞÆ¥#m#¯xfcÛ/C?D¼w¦ZwáÊõ øÓ	¾¡ÈáNÒ\Œ¤qwĞ İŞijß:ÿÜµÿñ¡)Gœn«$ğÿ³8œ³û¢7Òàæm…iÏ×ë?|aÕåUñ@ê ccÑ¨È·>ÅŸî¶Ôõ­€øDÒ®®
N¹œôÇÅoÇg­Â…l€÷7©vók[¦è³Ï@˜b.•ÂP6½óJ2l&vC£Ù¼Ö3^ØßÏÚt9øÆÁi‘šëP|m×P©ö`ÃVÆöé'Ìn/%|;UqÖ!Z¼ eDŒÚ%½TĞœ±ƒO›LÊ+§pµß©ÒYÔg³I÷ôĞ{°xƒÃmñ¿¨c<@V¼¹gın,xòJÃ+SCÿû§‘të  °QîŸÇ2v[„ÖìÙ! Â¸ÀY}ßİ Lá7·O„ºnP®ÇäĞÓ'5íœ/÷.:~˜€¿üºç‘ï†å%g\1Â{c:SLëhE•Dêxó×£ë?`ªş
ÇO‚ƒ”Nó~xôîhîßÀ÷IÂqqÛ¸TX¢7k«2”“,­Á‡'CöiïÈñ\à™"«ÔìšsLdÒ.’¦m*Á€ÜxÜù–@¸Í¾[[ıK¾?® ıúE¶:nŠ²ûDß„UˆÉPS=ä+gl Ë2?qYÏH`·>¨Úª<ô¥TJO	‘‘¼`p}¥ùrOQ¡Ù@$ğ¦Fù¡Ö1Àz0¡ïói÷åronYëx‰òZc÷‘W‹n¨\@Ö¥º¹ı'ËÑZhØQ„ÙÑõÊ –÷½CÉY=Šócµá6&°Ó ’zgpeg_Rî¥Ä…¯Ûc&û! &ÄœšfoFÃÇá¾è·­­L¹;Í­ó_ü…÷oøRÕ[=æ—ÈÁgx»<Jqú|ä*¢Ú
õïŒŒ±FF{ˆJÇº˜’Ş[´e")È?ÂgeˆŠ§cù6~·`aë™œğ'‡>”]ÉÃ
ÙºK	ç²Š$à*¼±q¸sÑZ48&0¥»§Œ¡ÿÆ¥¤G‰¾™¥}–ÁSñ9ÆA3m÷Kë£¾ŸŠ«klÖ]B¬•Bb©:_ò\	¯4ê¼îÛ°}ËÃÄ7Í6fjQP¨Ã§>R•‰“—Jä:eÏJê8 ³¦Ä‚¿ÚFò™¶_tÆ…Ón+kkb]]«M†ä£:åÍe§"Õ’v=ÜÕ<ÖÄˆÅ&ô<2—Q‹ùü„ñ­–c­F«ëÚ•Ì<ë·^Ğ‡ÃÇq J››y?ÎvĞ.€jµä·•:È_¶‰­Iî±	­,³#CpçÅ[BA”°£Ë×\‡=
jîŸR&q;P³(İQûu~#˜{Àªë´ÂU‹RP¹v¾¨Æ›xéâ1åÚÿ8]òWzjvÂ&«ÎÑj‹ÂÍÍŠ¸üá^ëI~¸Zæû¾-aigË*%wÍMnÈ™;¨ëó[\ÄåtB>)ò6ãçFs£\rÚš×/1—¥äıG§®@!ñ£®‰˜°´BñÊÃÙ,†ˆŒç+íßî‰‡¬ÏBËfÛlW³î£ˆ›8å)›rõÓöi){0t­|Oâp F ½±ØiÑ=’Šá†Œï–3¯‘–´.UA4¼Ç$rA´ôZ»ÉúS½÷İ%{¡S1Ø›)¢¾Å2"®ñÒ^Úîø8ÛŸi»€kÌ€ÓUÉ”¨óÛ„ñ»_.şOi…ìÓ$¬­ãò’˜M±/ÿıô´ş)í!|ñıàLy×*®9TÕ5qhIV·”-Æ]k»Œù„ [±=Ä51•éóÆîÃ%ÎÜúØüw«Pü²…U&"qj÷úb¿îL5§S/w™ú’õæš»qéËT×Oìó—Çö rf{L<`ÉÊº)£Ê¹/*3/|ıüg¥'ØS`@<;rÍ]ŞèH˜Ÿ£’c;±­öQ™’–¾ÇVÚ¨:u6İ¹PnÒ20ƒ2c<J 1*üùF_ïP«R<K¨ #ŒĞ*²õ&âÖ®Ğc‹:ÒÈUq‚]ÒıèO²âÉö±÷½Ò‘­ß"míÙ.U•¢ópº§5{‡ÉÇÛÖ[o‰ô¹næ!Ò|œ&JŒÓ›Íì¸%)¦ıF{;÷Ñzğ¾Ï9ÌXƒt&WûS_ÅÛ·`FäÅ®2[TüWÿã¬[q‚ûú
1ù„·éKp¿»hÓıXZ ìªÄ
…]nªHÆô‚ÉÛéb£ºğ	y”¼¬– «4°¯û™ëQJÑÈjH™©W6s?e„±Âé­^ÚìI1öÃ(}ó…µøz^[gnÁ}ûS¥Û®¢j}!(†¶.n~9n`éu-UÌù'^úª¿*jòˆbÑ+í:ç¥’4*,İ=%”Æ‚£ÆîÅwY|pœNµeC¡¦NãÑ%fıxWüzxGØ Åcê©ä½3óŞ;m/İql•ìÀ[«q1¼BjO$»¼ªÈë˜×söÀ³g=n’xvÓø¶\ò”b¯È@q(kVù)-3PôgùKÒoCr†½Z¨a®c¡	ˆ¶¼`üºı<!*©‚Ùpï©ˆ•ˆß•Úaıf9ÍJÆ`™©gQPÒ¡_¿
CÏ(‡¥ã² šZèD9É®Ñ.áW˜FVÿ.€şFÊ}Ş†ıÚiûH¾ŠÏÔlÚ¨ù””ìÿWşT?¡Úî¤
áü¿úÏ›¶ò–Pçzï7¼»såíÜ,€³”zêìŸ¨
NAÙÙÂAuê¨êÆ×®à6¸®e½”¢Wdi´©‘ü÷ù“JGãô6>®Ò_n!r€ÖîÚ=–Ğú4¶Š^ºfÑ¡·èÁP\şšíÆŸÍŞOƒpø) ó.Ù·rYV‹ÿå	T×§eF¸ôAûPP+âó•T¦wØÅÅcïg«|ŠBøgƒƒ¦n°Hæ±òâ†¾ÃîBŞÆš ³¹ó$K—­r1‰[Ò ÷°ğ3¸<Ô4ùf £¶N²ğ€§`¿fĞB¹tùïH®mÔ4j#(w{lO/O.$ 9'ßi¢|2ª‹í¯ævs‰«¸w¶dEÍD»ùw!,~/	›ìÌ P%~ĞwÌ 
}lßŸetÒsÊ6¹áS¼^ÉíEÈRBâ„í3ûÛĞÄL—
;4<Ê‘¦uuò¬¶2ò¥' Í£Ä*—¼ŠqO{‚…c»AnFŒ\‡uÛt‰	ú½Ñ‘–£p8Ë‡øyË0iñy¡^Z‹c	‰)1,¨iø+˜½™)Qï«¸€ÇsT,±’·mfß ÅÚÿ¡®ÑRŸŠ)vjQ»’À-Í×…xSfsˆÙC²bï´‚ Tû;	¾¾Êó†×¶  Šq­ƒ;h[¹aÇTŠâw~ŒKµAP"†V~R&oÉ}R+Ö„”«­¹DÎâ+š3›ñvkÃlĞ³aÙÛ2dŠW7¤]8‰ØFO­²¥•ÅŸŠd[Ô_¹c\5qı˜¾;Q|Íqš_èš”ì+õ‰+ïÃ¡çûc |vÔbh[H rZ¸Œz™L]a¨ù
 Şàá×?‚h¿ÓKñA=—e	É©¸@oXÏÀÃ!W“~<ö8Ç­~›L¿>::ÒpÈÖvÛôé^õs¦ÁhÍoo’	®$\p¤G2aáÛ*S÷˜$˜½¯ÉP5¦;Ñ–ÅìÓÚğë¯ÈOœ«ñl÷4äİÇ¿şÍ5 °«ì=W<ö\Õ“±G}úXgö|lûLŒİ/Ïà/ıIü=¶Íl2ª¹¼*s˜l.(×sèm‡¥vH²ÜøŒÅ‚¨*C™5˜¡ï/7Æ…¢öÑ£Q¨íúhıë<Ú‚êQøÈªîºäN·ÔÚ¢sh3;(…’Z^‡‚ódd´«¡¢äó=³>Şz£ÀOÓ	1z(=İ“¯‰i-µşekœ„¡gs3,Pqë„Æ¼ïØU¡)¦’"?F&õy~íúT=;#RÁ»¯’µei%é”(P…Yà®Wá`$¹ş3Ø-b¼µ2Ãş$F*­bºÿä ({¸iœ@Åk|¿>¹áU»/»a«œ^£áëld6•ã2./y¢çkğFxŠ~Ç°MY™ÈÄwag)’é14¯lj{7W`cÈü	¬?Y’é9÷ØV°)­'Eë€tfhóU¯©ÂæñTæârú\9F¶¡(ë‰ŒÜƒùú‘ ñ[£˜‘F-ÅÂÑ<M{<„ÒvíÒäù(‰í¡È¸VŞ±VÕ¦S°ÿ‹Jˆà£H+z4²?—_Ô†‚4¨ìü™{6b<K½0÷Si—Ø$B†]t59ÇGÜú¥ 4ì,á}ÀHyŞK	£õ»ÈYv$´hHÀf¹3Šòáï^!0aO¦³!©¬,i”œS-ıc¬³ñÿN±i<LÛ8˜í$ŒÌÉR…èKË‚r¼§ÂÃxâµ ‡G°O–êÏ8šûĞÅ©j?¶‘wKc¸»7ğ%SËl¾ª1Íä_úŸoíŒİõ®çÇK³Â‰ã© ‚q?L>hxä¾h¦T[wfÜãÛS²bÂÑË›í2l<_˜(]0YIÈ^1§€v¾Ø!µãÙ*%t
“B&‘|Ì'Ÿt0KKş`cAë6Ê’7J˜i^5æB*bñn	Å3¦Š;¯x“ÃßšÁ(Ë0D"GQ`q4µ¦úıNnVøqäŠøÁ¥_­)¦máß­H¶åxpB*ÏOÑ®çbKtzt®Êâ%Ä’áv˜æ”ï*æòÙÚ–|·¿£éùŠ8§I…W%l¯DÕô•(ÚŠeR&!`Ì{82Ã²|‚ŒØÅ!7«zŒPÓ•ˆh®	)‹—³daA²ÃYĞÔz[ìxq–DéÇ„s!ËÖ4J˜¢‰Åik>*Z=”„ÕÏït•¾Ê-÷—s“vdÓ/?gñ2 !¥Ã+OV÷]@ô±Z·jÅ'½=‡:_6ˆÃ³$Šçnhœ*ØYS »àÎw]×D…S‰u7™ ¾ZÓjV8;c÷’üºhl$Z¤ã/Û VEîÆ"ê†]Ğh@Mlös®óXƒ.[0dŞ™òLïŒ§˜ëiĞºMpß‘)&0ã`#Ë5yGtlÃMy c(“Ä»NŒJ%ÿnI)pÉ '¢õ/˜áùU®a#•C":øUˆ—ÏéV|–äÛDÍâ/°@‰GSósj&L®SFÍS'‰Ê«BEºù±wÂ+‘–ÄèøèYF^~êrÛGİß•»sÈ~eŞ©¼Î¹=bd¡:©]C?A„¬œÓ¾ŒjÈñÉ²á0ù†U·áHş™0	ë2'{-,”9²ßhÛwÑo&/åûD`æ¼©qËQÔ¿*Øù›ƒ:JËAC³«‰*7EdiÚİÄ8=¯³·›“PKæÑY‹Q¦Â†¹=
MVQhJÍ!ëÍ²ÏÖ85j@T3#FšŞÖÂ7Í©doÈN#@Æàzm¢ŒGº™4š7*Kt'†‰7¤òéËWáÂ˜«ŸŠ±øe³••#èqĞd	ñåä°«y®C?|Æ0Ñ|âI*ş˜È†š¹9yµK½i˜j¹"Á‡ÊtÀÆïšÃıà1ğ&tÅA'­¬;(×$µzÍÃ·4ïÇ4w˜‚åöZÁGŸŒÍ/—ŞÌ0¶¥6‘"añÂŠ3ˆPÈ,Û>²sÆ®‚–´|¨2LC«ïü!s¢xÉÙ–óÅ³OOšqÆc•ÙiDp’Ôróê\Oz¢ïµCœsÿŠí°Qò ´ãåèÁÁõd¡İó»ò,ÛBÁ¡Ï°]íÄÔşÿXQo.nØ†Ö”F;´ÙÈ`%YĞ Ôq—ÕY#ŞŸ5hEZx=o½ïnë¸ˆ_"Vú+ØœÎÛ†@ª~ÛÈJ‚ÊÉ–kVìlÄG *£Æcál |‚l~˜=TiŞŠ»d4…h3Cê£öÊ\«FDsiÑ<jÎİÍñµ¹7»iğ"šB4s„U¼|Ğ9ôóZf lqµÅvÖ.³?q–ï9ói>^ˆfK[A©ÔØâ†¹´¦
ØGµB4X^¾>4/5Q*¥ù¥uİ¥ƒ¯¿ÅŞ¨,¹×V„.‚í_G8šÜÏg×©Hãx%†¸*–ÛÓø,ğÓ»Ø¶äõ.-TØ³24u8wâ-{ÈsÍ¶qØ;r#ÑTU{¿wËÉ™BìF8k?³»ŠíŒ“¹rwDaex¯ò.Ròæ€O/ş–åwK”Î§‹=¸ğû2SY¤ºÈ9‹¦Qñ™;N2øç¹İÖ–BÇ0š%c³}œÔ¨ĞjàIœ[²§Şì±ÌyùîÜ‰gDAyê­èldücÖ,;çl]s•M•X¯üà²R¡P‚Ì©¶GE éŒ˜DSÖ`m,ĞUÂÂ®ër¥ì#÷é{!Ï”j¯ÏßDg>Rş’×\zÓr¥¤­j0^ûF8k:Qv8lõÆª1‚ˆl ›qîûXŠ+\iëÊ–Æ­Õglïÿ¯’c“l—*±Ğ¾½qôyíİJa§ØpÀƒˆ×0èëESˆu;é+Ş­ä7" { ç4#“0·'g;î®@€éÒ5èN´ôI‘j×‰Ûáå%¼‘,µS8"[97É$'¡<S
hˆ«Ò·.H<}°v¬9dşÙ–Üe;„Œ"0›!nàñ¹®Û¢­*÷9Ÿw”iUO Qˆñ n½¶6×PM_'Ôâ_‚¥ËA/R9¯ Rú6A¢Ü2™£Ê9Wš?ÜŞó÷‚ ¢Æ„~ŞĞ„¨€ŞdÔWm~CÓá;
‰><Æ)™×^·ÉI–tlË—ì‰·|OÙ’ÍL ç@2Ğ^ñ%(º|ÁOÜQB'B]Eñ¡¶ªÀ7:Çª®?2cyŞ‘¢*—å@cWÄ¾ÓGÃdOİØ1dÆ·åVb5ûñ¦t¼SÊpÌs¨n—É,û	‡,Ó²íÎÌ0Y/G¹³¹õ\å\eçK©Fa£¼NP9G¦¤ÿ±g„´§H¢_#±ên²…ı—ßßÃqú® <*ê<pk¶K¨J*¤n …AæCĞ.s¸Ø¢®ZßÙÎåÀG­{¤BµÆdÜzufqÒ¬ßhÏ9Î†S—¢ŒŞf|™²‚É*àjD5+›¥éMkê''ÌÏ@C–²œk‘ïÁX¥œ+`Ó‡~mÍĞë”†k~Ã´O£ªºÑ/Àä^†pˆ"³,æWà„•7Á³¢ mta¤û]÷ÎçSƒ€œY‚dÍN±~uoËv-ãs¤±ãz.XöÉ…ka'¡G(¨Çó¨Rë¥VúX¢’ıVjß¦B¼}C>Úb6+E§)6TOşÇH9ıS‰ŞpJ™Ñ4}¢
˜™º.jü¸ë–]e5—¹ığ¼ŸÓ”H$ïb‘VC"+nosq8G‘ØøÃü5áZ«óí$2ÕÁ$È§G~t=UÏŠ©æˆñr‹uÈ.‹—µ°×-ŠÉDÅ§03ÂØ¢Kg÷Î‹½¼Ò¹°XÒ}%ES³Ò]8kZj¬Gô©ãŞ°ZÔ’nŠ9p"
ğÙ°¹Ó
ÒT*É³v%´752µ½éåÉ4Ø4`Xì9ğ,ïmkgZÏ­ÅÍ~RåÇš_ÃL¤{}«B|oìâ "˜Q`8ÈA‰~!I;€fjÇpÕZ2aéçc¡t®á^QËàå…!ˆ‹£›ï‹¥¿Hem¢¢hŒ¯ìÊo–} ™'•&›ü+î$=AÍJÆT‡³¿’³4•†,yuÈŞµlû¢¾NùÉbË­ÃSüP .6Äƒy§ıÀîîşïfÊš™ø…©Êáô‚¶8ğE\’ÁA`ìˆ¥éN?à†ÿ)ŸàÍ/˜ÊR	AC¶7âÒƒ¤N=zİƒXGd‡¦°‚>Ã4=båÊyV›¬Wbì»+Y3œû[Lš¯ÀÛòZÍ‰^JiÀ§â3»†XDtjÄHñ5ù›ßïzÆf@Éç$ö×©UOÔÔéäi€®M2GşOemw‚Š—b_Gû9>f^óté—ËØhê! &—îBOnEÆ“Bœ&A<••ò†.OÒôˆÍ¦oC¯­¨!·|Mäùt•píÊ|
ºücP‹Ò±]<2í²h q*n,2	ÉÈĞ|hßê'$:}ÃÜ"›?Üıl¿»ê“À¾%JTwèıZS«\vwåîÀáhØT3ÈDw6‡ß·©ß½ÿ5;èÉöR&ÿ¾“ç… /Ù‡³'ÈÃ}UwR—8ÛSÒúm|É®ª^u¥ÅáDjIˆ£QVnX ŸVÔŸOÒ"òø.êğˆ‡èŒr %˜™S•óblğ2tá…¾*ÈßÎ*»ä†¡Úejş¶}¤ *d…JpÄ±6î:&‘½FÄ:3NnÄ_#aÅû·ôsèVúòpŸf—­prí©ºšÈø/THåÌA´±4Ù±í·m±€i¿s½â4ÏœéƒefïÌá/úv=úWia]‹9qşk@EÄûª0³¬Ô¢¶y±Qï*Mnn\
UÚÃ¶÷ô’i"N²&ÆŒØ=‘YãÙ‹ĞvòîIŞ>r–÷äÍa“Ş@cÑmÓÓi¾Üã®)c¨t|f?h÷´•G·Lú€­›Šìô=eîÌ *=‰f‡ÚœË+â,ˆÍ‹˜ y¾ÿFã)DwGQ)Â÷ªòİ.U ®0ÊÚ¾Ê\›é‡e.¯Wõ%îÏÆY©ÿâ}ğpÃÃä´1Ú’í¥6d1(9Å&‡=òdz(„$Gj´6‹ôg}dI»¹ëB½ØúEâcÃxÀq¶×N>iÛÅşïû<Ç¹qŠë(ƒ¤û 4¸AõœÎUŒh‹€¨ŒuGùŸ¦«xÂˆ¥›@Ãf¶>>‚’DÖHGSÛtM-J|ò¯ÃùüU91ú8(ª£‡(²ÜÎQ‡¼0]O¶ÉÔ½5’~n_ªˆö{Ä‰Uÿæ[Ë/oóG°˜áÍf«¡ó#ŞÿK°c0Š~1lm4r|Œ)h±]À“[<®Rzfİ.µPÓ¸d¯527Éãçã cl(;÷hÑĞ†‡Ä¶ëhî\{˜¸¸íÖ›e¿)¬½Î|ÙÏè›P½µÙ‚mË·ã4#/ T'p²Wµæ™E¹èFïı’"‰ÆU´Ønë×´éÒöh=s7Z4pİìú^†u¢**„ÆIEJÉ=æÉ¶2XÆ;°$
9Ö¢]ÔÑÙçÁ.çÆŞ¨XÊ¨¸Ñº»õZó<‘ôçNÁ{ùã£»`ÇæÂ©şk­›$ù¯c=ÿÌ™Áz…Çs7¨ “ß{%½M!TR2Ùij¹{¿~k­P ïÉ3æ!JÜ‰úïZD'@À7Ò»J/¤‰G¸>Ÿ,Œ«a öÌª‡ï …~¤<Ôë½ÓFkUÅÂP£Ñ±WE#üÂè˜9½GÅz‡é£m'Wá¦(tóYœ4SºH££365²WV¾Ë0Œd¼% 9ûÌÂgzô€¦ÂTğ»fâ•q&«½‹kóIÓ$O©a%D`ÇRY`Àëda›÷¿`·=ÑMDÜW„ÿµñLœ³}L#ˆõŠß`7>³å1&‘#sç¼F¥Ó»ä6{ù¡“vòÊ½ir S7ò[TîyÑóÀ@2€­0©Ï.XúÊÄ—ÍÒÿ/qƒ¶O(2­²~Ñ¯UÒÈvaÉQä™×û—š7uªğÎd—»$—!ppEß»Y¼Oé@+Ç<±iÔRúåø¸OCª“„Ã	€ç¥~Õ,KªI@J5%¡}ê­î‰a(½'U_ˆ	¥—t}Lça¡i;A|ıÓî}Å-æc:PïÍò¤í.p._ŞùB&ÖfÎŞ
•nÁiT=€É°F§”×êÆV·-á5¸	ˆc‚aTy²%2”?ÆVÃŒë ÖÓŒ¹­0Ş>ª˜]á¯@…K€E™)¼Øªqb; 8<›,ŠñY›X¡û›ËÉ½d1ãRq·õ\eÑ1kWVĞ˜ÙpXu9¤FÿS–É¼ÌJÌÿ˜äÇ²yİÊQBù±¨¦KÇ2‹´itº%9–ïı]Å9ï’ )ç±ÆBúàôÄ³Áı²‰1ıü4:^ÌèD.Ù,èiØ@l_|7nÕS×w³I¥Ä'ÿLWÒáŒ(u›ºGœsÍî¿JÖè¯Ë¨ái›ô`¥Xn[t§švùXÍ¬äÿ~S&¸ĞC²ch?o.îÖMµ~C¬•À,Jï`å.#Cğñ’*Høyò?N€gÕî¨^¿5ƒÔ*:N=W ´U{Ö¶£—™v¹=<içôBù`™D{‰/àÅ‰•:.÷¸7Øô&,ö(Ó‰5ÛN°°ÿpìc:¦/EÁ^Ë±RÂˆÀ“mgl9;
„<µÍpÿ¡ñ‡:Ç’FT]†Ug„½h1>^É›MS,zXÖÜà\¹aùÊ/“Xİ“¯bùcæDGnüc1ùÆâµ‚·]dY- ô]g§´ËJãPgĞêÁrÁS†Ly™Ô“ŞŞtÒVr-ÊLÓÊ°•£ôøVô: 46â¤SêeÖ–IŞ± ÆÖ*aË…õÏ²†­Á_·é*	Y»úvªYAˆ{ğTæ¡Ô=/ËÆ)œóãx—Ÿ6S/¬Ó/·g<4ƒ£5Îø>y#BßdŸ·L8-½îø°ÕJjŸ¶p£6ÓµØàH·<ŠzÕúsóR³	¾ğ…ÒGÄi–Æ›M» ;„†¹˜ù—I•OõÛªëOµ£8Î…ÕN&'Ïƒ%*P"iOƒ 7÷AJ´µúñ,i}×Š§ì£¶SCËùˆèÒú¼“SŒ³ŸÆaU*M›V[ÖŞü½¿íòÏZ3_¬å.sSpšÕ¼U,c<$êŒšïö"ÇVì¾Y=é³­@–ic–ã¹Ï£½ à<Ë­Yi¢7*»(ÑÊ^-.İ¼¸R¹ÛmçÅ¾÷¯İ/Ñ_¤D„°ü
^ĞA:›Ş :ª\(¯ÔÔÆÚ‘iÕû/ÛS¯İ”r¶j{G¯6çÛ¿&pPzĞ‡"Öi #ä¸g™“'ÇñDé:•m*_nŞq„RÁek/Û}[•E )ô–ğïÍ ›×¶}wŒ eÊ!álí“¦½JŞbd2I 8X|?ëÌšûŸ‚GóıùŠ¹ìnÎÛ~Cÿcn;ûç(ê_öF„çSÜş¹]„¿}´Ã˜Ï•r“Fi\ÿZÔsa<5¥6æ§ëP×¾s£\ÒÜ?EORM2ÿÎx-öQCËêÀèÁê§0í<iÓ»Ù}¦éÙˆx­ÇzàÑ
ÁYxÖŸ“=U2u-t¾¾91(ØîùæËó5"Ñ8]cWtaræâjn•T€Gq$ÙBk“Ğ@Ìi¯»ñşÔWåTÒB|ìIiQ MŞSMÆËä™åë?Ê(ó·˜ìlJ	Íd¬%ßçÁ=ÆÊ~bÎÉ²êe\ü<_ûñ6H:wÿ«ÚRîvŠ£J¬û÷a"ŒÆ­mZÅ–/İŠúuĞ¿h2AÚ	¨.Ÿ!­~ ‹B®<KÍ·Ì×SÉ_ñ¶SàHÜÚ×R…áÁ†T1Ü49X
ª¿èašÅSßã7(ëØMÅéo·ÅÚ‹1áˆÒh·óß§íÃîÀ`!¢®÷`ÑV¬Ùå5²“oÿû…ù¾1Š¹Aş¼ `ÎS	@hîsı}6²¸?ñó©:"s¡M¼ÑŒÚá*6T;,B.çí!–."È+S/øm]ÅJÄYEƒÆæWOtXŠomhÇäèˆĞ°$tm¸òµıéşİç£.ûKeq,–¡M÷5CğEÕÈİBÑ{¬ª£™è)¼Tä(c Ò‡ãÉºPkºIşu‡Ò.µ9«K66šÆ«(*ÆE
e1©Çş³ÏÈn%<„FŞ¹­Q‘İUqd~ˆ ÉmùÆ²È0¹!ÇÆßm1Áº(w–”4Ò·è»|ˆD‘0YAó³ó6›hğ³Nqş?®è3/ğ:)NHÿ W5æ-{YçcöV[	‰Aé,û†?B·h¡ãoáBäéød§VO%ª¥G„kl@ÁŠÛb4‹RŠä¼÷¼YÇ¢P´tíõ£LÇÖÀ¢ ûÉÿöŒÁ(fç‚Ÿ‚…œÔÿ"]éšœº‘u=aş‡öÃ~£¶¡²Y9[MwÖ¹ºÃ¢º_Šâí`ÌsÅö6ÍèÜS0ó8x4ÛÎcóèÆg÷.è¦Hdäç}Snñl‡ÉjªQë¹.„ƒ#iZ*Zå»ú°‚9½·x—œm$]ÅU¿dtøµ6¹>¾Êú2l!òÌ™‹û½§0â$oÚTŒhC-ˆ˜¼Mø!k¬¾”í¢×èßgb•(Î'›š±J.ÀÑ<U~†AØOÆ|~(
Œ…ĞÚØúÅ¼và\
ÿ0KC£+ÿ%‡åÆLı}®û“`¼CÙb§±+TûÎÆtxˆ3%{kNº	\˜.…}‘áëRC
6ÎÜpß„e%Â°FºÉUZmZ^8
¬Ô3ò:º¨¿·)Cæ#få'ã…0.Ã
ŸØñSw£C¶§*ó¼j“.Vv<úö*‰X1Ì°‚º¿W¾âxb¡b»|Z#µÎlõÃkiOÚtáJSh•ÉÏ)’[*nr5íÉ¯·d2üjƒßòõœ{¢™îÅ?;W-ÈÈ.Ôº¦äüƒå2’ğ7œÚwùÇV>mÅ˜Ë¹0­ºÜF/—aÀ˜ïjÜx¥AhÚS©µÛÑYİY·	”¥Ë)I>èÂ=ÎVjWÚf°Å·ç™òô¶É²gïm­tl´W *Åõ„¨Ñ„=ïäy ì`”h9%¨¼_=…ó}İ|È»ŠñúäšeXU$lÄ¾šImä£jş¦ZÚdFş'‹©$N*yŸêı.\yÕ_1N£å³ z»íCŞÍ¢Ù˜=G}êß=±µÎ3tVZo}|ÂÔ4ØF?FO©UÄ 5s`5¥y¸6;ÊyäÔ©ÒÉÂ3°ÁÍPPºÌ©ó}õÂa1kùé 4ÜlW< 0Ã§ŒdUDš\ææåŸê£¥yÔ7#ÿRîu/Ob´)Í’Ô[NÛãÚ­Î+Ú¨$ĞW„}9¯Mò*ÌÅ×S½ù~SØ6iXj£LÙsav#Põ²½¼RÜ^kZtej&…ÿşY6q ¯,¶B>1 ÇÜ!‡CäÌh(Œx0ğ©(ÙÅ ¬Ì„³“í­¤>heÊx»åOØ lfdn®¤¦ü•X¦ê«‚%ªC9b×ÚN?u¨ÎM"I4·›78‚ÜTĞ#“IWŒMğ‰œŸÊ,ñ¥~eÖ‹XBÖòÃ¿\Êé¼dmŠèé¾6î‡ü¾›úçi¿Û­C¿ë†*¹"œ¿.^[J¸=G (œêºo{B‰}E~,Òqî®L¢ĞgÂWß…ısŞbûÀBê>	ĞÅ–Gø}à½~®ÅXÛÜ(Ct»<3ş;Ñ±ÁMÙ`õü+æo¬¯ë±·ÖŞ¨è·Æ—ZÎHOi‚ÛÕ;+¸(øëÃêÁ„EIzÉŞGæF|Ş¢>–«*z+•z1Ú}y•!åïb†œ3â;^ñùŞÍ#QgçM¨ì…å{T*T–i†&·ÙBƒÿºYªĞ˜ïuËÌğw[1ØêèšŸoe±È$–	›249Ã!0aèÖ’õ¾[W•ù¢ÏPÅyÉŸËrxPCeğã†³´-gèSœØÔßp'õ€ıdqŠ¨FlYuŠpX”„ø‘5îë	Ëéœ±wŒ®¿9³¾3ò‰³ìÌpæÚQ/­È{eÂÌ<?·°ñÇ[>¡?Ô×J¼Çñu
Š
ôÒÀ€V».v$1»‚ƒ5¿#C–¯¯ÚMaì¿N*§˜6³‰…ÁYÃ+\\ 'u¦t0$…Ûş%W¶¦´"A3âÖ`¢ÜLnwÖı\wg×ã4#“¹ÒzIø¯±ÌÚ>¼”2~£…óÙhÅa¾åØKE±ÎÀ1­§oæE»`DÁ¤ÉLëÇKëwú3¨îaIÿ£¢›ÕTh_”¬Î5»*rÈıSQ….ÒòM´f€évM•¢ô±ÿå†µW_İª.úL¤4"m’˜P¿BQ¤L©í¼\Á ÛÚÔA€´ĞÆó¡‰‰êôJÔî³ÌÖ²ıö#L3·÷Ö¨q›E(€EÂ'OÙÿñßº€òSg&ä"şÜ	kAEÔ[ëmÓ>9YÎ»*b× L?Ğè~şjKO³³õjEŞ§‹]Iï~¿“¤• °)‚#ÉäoĞ¥‚Ú,œg3ÕDçº`ñÄÅÛ&†…s,Ó"»<>¨ rÕëOMZÛ'4¹Ùú[dš:…ÒÉÕö+†s«£êìÚĞ±»(y6GSüƒ7*å‹ é~õâŒíğU¬=µ?æOÚC/t7_º«d`í×.g‰‰$gFŠìé©DÚ…¥»rvRº¡ÒÑfPd$§y/¶„K!ç€d1·$
‚ˆ³=c”ptñÿ4p›YÕ…ÚûæL.85Dà²oÔÈ{êÿÿk*Ö~q¬äqÌO6æ~æĞŞª|‹paŸoÍar³çANQofˆ¤ë6$¿‡¤`‡t¶H3{’ÉÇ°‰iöfrÎWîÃ;¯êÔÆ¿Òò»D—FøŞœ–il<hşÈs °˜Dq x#Uzyp"®&ED;+¼û£7M–ynE‚? 2²!®Ê8)–3ĞªM=µ¬~õ’6(ôö”àl|íê×«+|gH¢9|ßÖbş¯ÎãíÓdJfN(4Ó¬È!	ÿ¨Ô
í^¶ÙW•Mó~Ìp­=«ÁTAí¤ì*'(.Rr}Ğ{'˜1~ßí=!;‚ü¾šëØår¼ò	’mÈ>H˜ÌËâfZeŞÎùqª_÷£ b¬";»ÄƒÓßAQóIØöh¾Úî5Ïöä.÷şãWbşeŠ¬ùî””v{O€¤€ºãp<ÉƒPÛ` ¡<LFúxt×7õ×±v•ÛŸ ñGSG8¨yµs¡Q/Ó]Ï:©:?¼/EjG… #.®h6RˆX$Gt'Úš °È±ğÃMUş/Ï2üz'Ç³F|Sÿ– ë9üì‘å^I Ûº½¬æúXİÛ‚{"†òğÏu|ê¿ä=˜rì_(ªËøœ”ö	z¦iõ^hˆ®:öÜá?oÇ)`%:_Š°~b¯èšlù”ˆ¾7.õ¶âËæ;6®È;ÀÒ¨cò†òªM\,$B~ïÍZ6‚äXÙîÅJ+ƒTw‰Ùaqùø,ÏŸ¶»gYg–©€gh™8 ;E¬ |a
Ø‚†ùN›`İüšÃ{¿¹Íkj«{ĞÉõ?}ı eŒo,F§ÍOƒ¡D  JËİM!ˆêçˆ¶PòªöæˆŠíGšğs?î>šóŠ®ÆÚ‚9%)_ØR”%)”ÀuÖºİ‘¨)¡n4?â€¡“¢:ñp£-¯ÂR=&ühòà	µš¿‚å‘ûn´ëÚ2Zi[ˆ¢¾D]'RñJ±xó/e&›V²Np0¸Ù³ÒõÀ5‡š;‰ôvO³ù£ÛUŸ["3/ª¿ Ä‡!;.LzªøO½•-Ì&FpI«¹$µ²ÕbA,å-~°)™”ç³¿p*¡¢WàŠg‚Ëì7ÊéµäèÁ6Ü|¢¥z&˜NÑ®İú¯µ—ı IxW•@ÀÈ
â6Å§ »[İx„¾uæ'zF¬İ5ëÄ©mÈ‘­=œàJÂKØ\à!ƒppxÃşV0ÔzAª‘èÄYpi‹áÓÔ}Çğ¯:¡û¨ë£{EÛ“ÊœÄ%%Ş£ÜĞwN¹M“EÂQ`k®GÜzİª#s‹Á”kq•ƒ~ÿJmXrØGÄŠÀ‰9ÀÇİáš>yGÓVK÷;Îø†)•}ª '½	pß¬#ˆ„­ˆ;Àä©[®F¥LˆKİ,F2i}vn{ä™ò‹—RXg«×8²¨3AÊL=ÊR,„b:óh4u&¾™‚<äÔî"Šğ¬´“LEs«‹Î~®ˆíÙIwDŸìŸÔ…AG(¼Ğœ}“ŞÁO§S‚ªÙ@.c×{v—ƒ[ğy)üó~ƒ·ÿş·$äÂ¡?Iòè"Úm?Ÿ[wøb¨È­Å: w¦719ú]@°ßÇòŒÑŸÖÜÔÑ‚í¹hôë8~îI1ôäÍÑ!Z3%ğ°Øœ«y2y.(1ìN%ØŸx‰ŠïJh‘e°åNt‘€QcZö> ×W1ÑSİAíæ¡¼H|öº•¤CĞDçF¾ÅŒ\ƒhåDüm)ÕF“âªÙ©*Hüé9s=<,ÅÃáß
Ô­w‰Æ —×¸üıæØj!ªxšl¢;áeÊåeÍÉRJp[ ûl ÊÃ¾ŠX¿÷C5mì›Õn8« ÊSnÀ€˜hâ£çæ‡:äÙö-—¦¶8•Ú!ÕG›bœ¬8/î~˜§NIŞ?¸ÕZ¯gTy#Ü8å]°·ahò^4
„¥P!oé„é{‚a£©ï+Ct¶J¶p×Ğ¥G=l<¬ª nš²—'A´j!z7za(fúİõù±e„vèĞ¹1Î­Us…IÖx4x‘ºRrñ„“ a§Ò)f¥8„=Ô’üŒCià;ª²¤Ò›z6 ³ôê´	ÈpádNdTÊÍ•»4¶4«~~êüĞ•µÿ» u¬/N¿™«Õ3y1¯wù„À£9b§ozxh¸X×G¡“¿KQ˜X#p«Là;» ‚“f©·ş¼ğmèØ	äÉì+MdU'+ãÔA?¨ƒ^h™˜Ùê¸‘Aû VÛ`_øà×^øu h³kŠC©@HÖ7,>xpSÓQ€÷á»[=­-HgÌÀ u¢‰c£7*²®AÑ¬ºH 2ÜŒ>‘Ôx÷+ :è	ÍB²b²¹%@e¨nØ}URªí«ÉBÅƒUŸärÀåè£°Íë=íxk×›ÙÑûÍún|ÚpÇíÒ›õiåDØ, à,UHwÜÍ±NÊ÷L%l!&øÚ9í‡»`[é5ÑıÅg w•vıM²T§æõ˜xá¬26FÈm€ÁN³ìF>×î*ÆÂ“°MM´J<†+dAC :Á‰ñ WÙgù/úÓxª48w„šWíbÄÛ í?2ù¶RÚ™ƒMÆ5ÅÆ&Ô•o–"Ğ[]Zn
«\\ş ñ+ÕQ¬Ò
3€¬¬†fYAT%íŞÃµv¢øUs²ÒH
%óè¥íš^İÛãºgÒ2[ŞÉç¼ù5Mß$=2–Õhh@q‰‚Şr—³ÛGK®t,;Cdé½–ºÃ±—EœWØdB 53¥™iß>Ú#
Ëˆ}ÊYQÅ„¡vöBNÍt$Şå!0¡îNfs²x2Hp¾a wüÖh¹€EV[µ²æÿ5ö>ÅL§=Â4/ˆ7Ìz€Ù·G˜Î-ŸQÓëE6@zôÆİWûIgã‚YS€Ø´\³º.ï¶vhNóµ‹-½rŸÕ}>bù9§Á«¬¹°º‘Îèn/B¾¦ñVÒ±“Ñ‡ŸüØYá”Kø1»*1¼z ²~7üJd]ÛMÓÎ;ºÒ\\Æøö‘~0õ¡ûwˆBXÓzoËÙŒª­B¨_Ú{áÑqÙ¢èå‘şâq}TÍ*N×nšAwÒ‹på•?ï£hM¹<Rí"‘B«Ş0]¸’QrĞ‰§mt=ÈåD4½¦ ;yàR|ÀğŸÖ}oÛ'ÅœMÀRdZôá»uşß˜cH°£mÛ¸}×j=fğBˆ°ŒäZ×ëd…Z¶ZÇ§¿ÄŠC·Õ¶y¹eawìµÇÙKAA)¡Nô)¨#ûï™¦§™"2™”XU½Ñô·¯…£å-`³îÅ=Cìñß³È½= på¹‹m+56–ïìLë,-;DCÿ57 …zä÷4áB¯HŞËJK„òü4œ+ÁF  tBø
OÔ0¶º_L3-u£¡‚‰v¿~†Åìµ¨/è7ÊM;IÉJèP½à¹Á¤.½ÜEÚó¾œ‰‡ÙWZâŸtzš)ÖªO-B¯—ğ0)÷ŸúË»7DğÒ±®¶Ìh@©Û‰¸—‰€zT¸™Z•¹å2‰˜n £Ú­FÁó$4\¬Èó‡Š:úJ¸g0O¶P·¤¢ˆI‰Œ,İl‹ĞÊ‚²‰;Ñ@äªMÇÀ,’v\T¹~¨Ç˜İFév:»Aüzùö÷Æ@)Î
ø)QÈ¦Š½¶y)8Û¢î@W‰h´‡X'J)1O#ù‰/Ã)(!ql´=¶†:`¤Y
Æ8ÃúÈ4¥y|­5µ‹Åæ2#ş›}‡ıª…f>/’ëŠáóµjVâ­‹ì@9ö¹Ye×‘˜‚V‚2«H}¦Úü¦£ñ`º zíƒÌ{zK~‡*pç…,Cü~B’LX’†ù&í©Ü›™)+ XÓ‚ú2QÇZÆ2/*OE€0(Ò¬‚\hR£PRM’ˆûÑêÉh²è{ˆšÊğP:chÆP—5W¢)tKL…	ë¬åt¹•7 ^ ´4aUlYd
kÚYû´ ¿êÍCÒ/s7¨”Ü>5¼,Ëœ¾ì˜!_ KmÜ“/Q'¥/Ôãz"R)µd¯Ë’¡tÃ¶(ğMxäŠ~8ÇÈTN¡øƒ0Öh%eêÄ-+hœ°
p_¹Iœõ*-Ñ*gh¾Û™Lå²(üL‘cµW``æÙ‹ïÒ~J@IÔÎ8ª¢¿æcw7l%šh6¯ôd<<¿«ÌÀüC†j‚,o¼XKƒ3Ù2:gìWS5,±»77 U’1U×¡16İ53^ÿ–K<ùü¹z˜"ã÷.]Á÷5º[ŞJúiI?•;e¨¶=¨˜´\V1—=jƒuœùæœ¬ŸçÅÃ÷Ñ¹*¦ƒƒN#Å6°ô"¢üÌ—ô@‹:L)s=mEÂy•&RGø¹ßµ€Œ¿ÔL„YóU?Í ¬ZŠ{‡NŠ$a¬aìn¿¼mÃ/}´h æõJÃt,ŠXöB¡­3‡EáÑü[,HÒ"Ö-û¤e$¸DÎáRÕã®g`şîINhT|6øÊ'3)ê€æ«S*?¸'AÇG¯÷ö½;Ïq4®ëÛõšu‰¤O}ÆqºKrõU¿J_İ <&;·šÇNÍ…AğñaœÛ¼EÓ§f	‚8µ#±!„Š‰}e2>…Ó%.óÒï—Áüï™i:êÊ,Å¯:a+š,ålÎPgË[L¬¿#Á_Ã.+İ+øLIM;î´e4~ŒÁŠFJ>T²ş;	I–÷\ÿËzæv3Á;_ÿNUäÄë3ª‰4œu,Ä|¦v"Æ îÒgq“³&,:^­AÒĞÒuŞìTqÖ¡ÀévS†Iá+ĞêùoÃ¸×^Â7‰§mEº‡-èdmıèbó4˜ÎıÉÄºš$ªĞp;ç³ŒD°k6&L‰`øş.*¾Š¸ª{ïOÄúwU»j‘Ûéa¢Y‡;|àë 5²¼Y”â QğzjGç¬çyIF2IzÈøéiSİŞs;3T\òŸ¦S4â'y~êµ(R2ÿ»ótØ§ã±ı4.BÆ¨¦âÌÂµ6¾.Ú– ı'³øæÉáÇæ1ŸG¼ ¸3‘ÄÍ	ÃëY7FRšòXy–µ3­} ‰ËŒ¤wŠ“\©ó–¨ÆÅÓÑ\5Öà#å¬>h’ıŸz…æ"d(:;Îï2
9g|Æ L£%‘œ[[ì½ğK®„ÕïgÄRD’:½f Ü7·éø ÇOTIhÂÕßzÖÉzCÜ)!âè,>ß©èu±®‚Ø8Ø"¦V¼ø«æ±t+¸(«ØàLAª¼[œmùŠ8'ø¼‹lk¦N¤´"PŠ,ğA±l^V3	o 7rF¤ºB WÍ"&ÎïürÍeŸ!ÒpÑ¼°²	è8HÀ_=Ğı…ÈÌQ°Wljó/Jû™rFœ†ŞÇ8ûÏö(S”ÈUË;Å¸(â¸M¾jD%å^gGg¤ÔÏ~V(Uƒa—=$ít<±¯v¿_*îî±ÒqâWşúP¸î9¬È˜UhvW‚Œ©È.ıX¾
5ëí‰<ì¢¦¨ÄÅ¡\;âœï! GğÈ)ĞwH\şÊLåy­h³U¶Õ5sÀ¥Õ»%9“NÁš_ÁXNö»dc¯µÀæi¢›349,x(ãwXäzi+JŠöº—’ÅÕnN/ñ°KõÔS’ãDUÀ.Xu£ÈêÖÏßÁ	Û—ÂsIşRëw!p;Ú—îÎ³®g:4"?$ã@À­hR6®VyÚî÷3…}Œ^L¬lx^ D±ŒvEÒ¢Ck*›ÿ»ù»ºzJSQåh¤.–1TÍ&$Í´©Œ“¾ûyß<z³{©X'”²ìC_ŒìŸô1.¢Äß©åŞ~—¢mMÊÒ­U)\m½h(³=àtS¨«©ËÜÃ2«`^¸)%Eí!xÚ9Ú¨«0«nß”ÕÓO|Õc¤ü:_|.9BßæŸöœGl²’…z@ŸSöÑ¾]9³a0h\I0gH›A”
şŠmä¸=‰É’¬³X*cu3ŞTeœäOµ¸6|;9Ö[æÀËğ_å#?‹›B@ÛÈ%2Öó'ü“N@Ç2º4Q™ê1ÇkŸÛåÙ>Â©{jl˜n—,¨Z‹'¿ÔhŒªét`«Ô H-OôµVjå‹‘t¡ÒûHÔKKç+¤G€Èm »ËôÃä×²Yv‰i>y~áó¦™iƒƒ.ù°qkK£ãòª:cß(]N’à2”à,%@Âe—WÄ!4eü,KjNÑMß¤“N†|‘1‚ê@Ğ³W°ÿZsÖÍ±OµhĞ¬Ğ?tÕı‰¯3S?I†Ì £Z"sîy@"¾q³¤€…ìö_óPswºaËŸ±³„¸âÏ½D`ÎØ“Ó×Q{Jj]¼lDÍÅ/Kˆÿ<–¦=“Í"a_^
8÷l‘%OròL[ğë4¨3ov GzyÎÕ5*ã÷î*`mÀ£]½ZÚÃg¤µR+i†Óh?|¶
{ï`ŞûbW‡gË !.REí
–±dA¢mBæŸK'ùiSı$ MOÄ%¬ú¼ƒûÿ`¸òºeëiÛH7r²!N²gDP“ö cY’´–%$êØ$bâ,ÿ”t=_cÌËåğğĞª7Òâ+/„·Ğ²–]û>÷Ô¤•ÿöT(§8§Í[5A¥9}u³xzsüXrfçA1‘?ù4ë‡aí­q ÿjÌİĞŞ©XM-]zÓèá€uïIŠ2Dö¤`Ì\3‰*ÿ~)ï1ÏDxö,Í`]˜ãÆ¢¹'ê{2Ê>ÿyv†j9·¥ñ9ô„Ÿ=£ÓÉ#F:Jÿ¸¦ ms+_OG¢Ã÷¾ˆp›¼öŞ ¿
Ë½pĞ)b¾üÀ­¥ğÀm[Æ1¼+,¶¶¹.İÅl±Cy‰:˜ıÜ2é‚À¾÷ê =b2]Ã4ÓÿF»|»í2™TIùğ¹
~:±K˜ë¹ª™ë‡'uHU–Á€Hó«øÍ¬•FSûÄ,WŸ_úÃ»“òÛp7øUØ¥ÜüY â ÃtRGL‹aà ~ì×]‡x›Šÿı_‚ıvÈ:¹ßßyÇˆ*“ó{87Bs®6ÙşˆS2Æ=V’1ä»”ùá»~¦ŠLDf«ÂtOa(ĞXZÍWp]òƒ 
–Ôâjş‘Ÿ®şßq²FiˆÓîªJ,l¶Gzj<¯-œ‚zÏªpÙÁV~¿\ğ-%Jn5@ò	Öû”{' ¤³BÖeH+ö:ş ~6•ƒÇ\Ÿù,±5€dÕFïİ\¦É¥„ä<5ØÂ§óR>añ¼ûªW?KZøTCváâÆzàsÂ÷ù«å’7ó@€'ÔJşìYÏ–^øeÎëVæ\ãl	"Ö®Ayiæo›¿‘˜ÎdŞï›äõŸİË¸%‹}­à®j'iä¾}iıÄ¦\¡Sëù…Ÿ}d­É½ïÒéJM‹>Ô·“ñğ(jB5lğß±G‚Iª›#=°û‘PóùF€ƒXÚ°j5:¸Té0*¤ã»œvÑPpß~É.§:6D‹˜1™’-{ÍıNƒ$BIî™c‹‚ôL¾ŠÏ“š®N‡%'¡ê]L¦P¡ûBv³Ğ î_§ì4Oëw¡©£Öy„4ÄŞ4xÔ:³;ôLpÍ×àsÅ8ãØå’cPñ(ß¨üÚXŒÄ2â§d»EŸµ†<0iëP1KŒ€r°^hsöĞjC›ÌÜÈ–½²4ş-S¡åJXFàèn·Ñ×îÕ[é_Å¬ 0[ş	TåOvšÔs’ƒšúZ°özzü /©Eö9İ£â¾¿KKXæXËQI:Uå†#@û¼şš‰–TÔ£`Bû†ã`…ÎY¼Qœ·ŒÒ]Ô„U¡×&v?^µK¨Mß>¤jQú+jk¹U¤Xs£è„¸‚€=·ê4?>bò’õ!Øÿì:r7Û‰Y9d{´¤İáz&6*±®«ªóĞ¾ò•sÙØƒs¦ˆ’|¶FCOTÈ¹†^€I¼0ëúÿM#'°7ã¨‘‡è•¶¢¿“bÁ¯ Wwıü14£AÕÍİl™ğï’…z¶Õùô—GÀºbğWÃÂA£Œı'‚’ƒùOi%Aºø¸r|{ÂTMëøëBâÙ¿C)Â—‹@–·¯n‡ŸàvÑÆ´öÆƒ#f¾r¡¯£¸LV­*sªÄ[šY¹ÛÖxõØè:ˆ§.¹¤“©—šï3€¥¨÷&éâñ×Lª×v¢Cù4~itO³º ËüN?öÃŠGÎN©Ç¼R…!æº‰å¿ò~&Ë¶ÑtÇ¸®Ç’IìêŞ;ù®+€tÃq9U>¶[V‹|7î©  {Sfº9¥ÀššuÜ5ê¨ÑØ3÷h*VÀ–¾6cMî‚ğ×¨î›eg2wí9Îû¡4I @+›ãø‹½â*ÙJ÷F ¶­SßX7lşúõåèÀûƒ+¹Øø¯ò˜bÂ^ën_ÅÚøüŸmúĞda÷'eÒó³]Ï8ÁC¹`a6D¥ ³|ÄV¶†™/ô~L	ğ7Iš3„|^Œvæ¨:Û”ÅWTÔ\®Õ°îå<Uº×$.t~GİìÔ¡FG&š™z‚z¤‘d–î »
¹s3Ã¸gÉM&ó%F]i2ó<›^÷ÀˆÒ%jÿKš‰GºòÎ¡rš¾#I¶¨(0qAY{ê]¶¼`ğŞL­Ç£SfQŒÁÕMHçá öñªpÓ&‹‹ñÚíCY[_iØ'Y‚Z«$ÒÉì¥òSı3!­e&!÷§“˜›¸©6«K¡ê Á¶Ìo”¬k'|j©`LíÔ&²Z?øùÔ4–€VãlNèv³ìØNr†$"/Ï5vô•#¦5œÚŠÒû½Š=gn¯ÃÚ
†I<éÓ2
/ŒÒ©6·`Lòî¦jˆáRË÷´ÿÒ†õøZñÂŒv/õv$(Ëv°œ:Ò!– ]×‹khŸ|íÜd´¸Lƒúæ	ˆÈİ3rDÀ@ëæœùíÂİ­€j‡;É6¼Xw¶Ó"w«şe¡/£üáÂWÛbQøW&-m;¢ˆN¶jƒ™-ÂI®ÔhÅb#n³D4›øŸ)|+x‹õN–Ñ¶,é5sÉWw<´'W Mš,
!Whz?Ù7O;ZÛ2U°ÂÿË=ƒF–œ…I"²6;1ÏéA;ÿ§~Ö¬¥5ÎÈº%?$şˆøªçİÅÕ{ÓÄ³'×ÄmíÙ)w]‡ô×_iµ––¦Ù]X±0Q8à &5Á.t°4®@è¿U¯ó%”«ç× 7˜à•XB‘<M”°eÉµ¹4ƒH®¸è~¨ÃütëœB#^íã=­k™êü[ÙÜßúR·ğÃY#'²ó³Pæ!È`nñEÈ&	éÌ/y	œ‘Ì?–¹ôIH‘P§Z8ÃŸ¢ g¥ş¾Í¶l¥îğœº3úŞÒ8±"ûm^Î’âr–gU¨? ìôL?æ`_Ğz„×Â¬O˜biE÷âœšÁóLRUD%QãÚ„ªŒçw¬ĞÓ­7­½¥B¶"ÄQş€	iÅ™Œ‚:Àûôƒ±å:!ë1t0ÆåÂ±÷ÏÔx{CÆ¼p6!  ¢
îbêéö¸®z9i¿¦ìÈ¤ó4±ó„râßZbƒ»Ş°Ûr¬‘êUÏíúÙ7nP„‡»ò€PdòQëy€}s>}ùeYİŒeVŒ²U(ÎExsÚó×uEÉx+?~/ ã‘é%“:Ğ=@<Uõ@*(wU%½}Ï”;0ó›ü´Zd	j.e/şõÈE(¥ãâ*yaêN¸C“I%ÀpßH–c¤ìÏı¬}«¿;È'…Ú1¶PdË/£é$k‰B‚Gô×9ñ Ò¯‹Ì9~Rëù™¿Í'(ä»ª¶èæ§Oˆı3ªR™¼ô-‘œÓŞkc{Z¥²toÌÆ9Ä<ßÉş¦!Ò«~›€7ĞÊ$êEÃM¸§]|‘îÿÕÕélĞI6J,³ ï#P5Şz\!#w'ŞÃ™&¿Qsb.Îc(n‹ ´oÒ÷fó?ØŠµ=°!@“ÀĞslfy–.÷© åó½XLáKàs"éë«™4ízvoÇ•iÒÂK®upCÑgÜc$å€‡F³E«UãFËb·B[§:ı²¯ª™äì3”šsë'ºÑÅ×LÙQû±êF=¦	9r÷ıXO.PŸI‡¥ÛÀÎ©Ì+—yÓjH"š„'è»E'hcvŸèßAğŒ<XÓF›j±w¸7=ƒ0©NYáJQ¿yšXÖú¸şéÑœ‹t¿_N\k‰¬«JÌN¿K¥iIö/©.,‹(.@_÷™òH¾1cØãŸ½‘B‚EÀĞú ç7zml.G2Õ$Ö»iYûöjê¤iB6„ç
âí å~wà¤lÍ>-™ Šçûmï¥î-pp29‹ºAU›lŞ‡©MÖSGèM
À2&·]ñÙO_ÿ'óW{ÿ;†Îjò*p¬–˜ãRê]·©#ìe î€(¦{7SqûOÆE€j–÷S~k¦mJFEN[éÎby§ì>ïMÇ8UUSÇøÎ°?Xã2Éãv{¿Uv<;%Ğ¨®¹ª©
YGÕß:–1:½&ç'ğı›f¤;/¬¡¹òè.¼B>C£1©­ÀùQ‡±¾ÚY~ıs/JLÉØ†QhîåæaX.Á”:£ ¿Ám0³±¦ÿUœ0ŒQjÿ×®éóm;bÔI/6ÍjLœy›-¼Õ„ËO ;Ó¤ä¨Ø	O¢©ÁZ’[Í©J™®P»K †Ù¤ùŞ¡Ùpœ&ä‘ï"‰¸«&–2z¬İUNbÃÛxeôÆfyÓd…WiÌ°QÕƒ`0¥ÑVï?@~-Üp¥°³Ëpb1›PI7ï‘–2ZkÚ#63';¸•Ñf_ŒŸ®CwÊÿePú·Ã$µ:³Æº@R9­Ù¶;²ÎñêÚÏSÈ¨óQ¤LUŞ=UøNËßÑ™m[¢s>“Ë½!"3´óItÈ+d6[*p¥±µñ'U˜]&Ø°q=ñîÇ‚òÑ¬øïTŠä¨kT›™s¶Ú²ÕìLâƒÔR›xm^ãrSpş2Ár•á§L¬3FĞº"Hc¯_¾SÌê
•YjˆÈï»Nôl”"œ`l¼˜Šîõ–µ0‰„›;,¾¤Ÿ´	ûCmÃØH+BQ9âŸŞZêH0D+jº_>ÕÉÔz“æ)ñøÈÄµE3»´î [N‹w¦`åÕ Ã¤.Ìd±h‘AeM‹Í‚5¼òFƒ³àÇ’¥TÕŸĞL×Ğ… mêÍÛOÉ;%s0B¦‹><$@¥Ü,†è
Ôñf¦`@WëÍz/z w´_Ï7†Jê„Ÿ…¿ˆ S¢úºˆà}c”–¢Ú‡ qXÂé¨kœ2ğå„àOÈÿ]±²Çû3!ïEh•€ëSCódª—˜"+¼6=›ÍvErny­-[8çH¨ÌÒ$ŸK6Ğ.±6T+ü-ıÎ¢ä@ãuì=íò¡:Ì,+CĞ#w²q7&Fñ‘ÈHT!oÜ{ò¶mCÍO‹yë,u"?¦]¸vR¸°«šm›w`´ÌÚ«³¯~[][ØU8ÆR1ËW]k÷ı«:Ö*%ª÷ğú7‰òâ“T¨aKY@ğ±ò“³ hÇÚ¼Ëh öòu{qÕ‹Úweh÷YÎ™W¹×5{óÔ²ZŒùõ•fbŸë©Q„x«›öß`—Øó‡´šØ»ÉÛœ ÕRB‹ÑêÆ¦ +oØQâq‰õ‚@/ğ\$¤µ¿øJÊô)pË,Ld£Z­­á42 ËÊŒè+¼ã¬syuECeµó¹,ığ+ÖqEâ²Ìli‰ı¢hµİÆO×$Ô˜ËBî·–dÑZJ_s»"ÔÙ×Ù<}ÿD/šn¯¶E•&Í­&2—JØá/GÄ¸Â:ÃÕã®6ê+D¤È¡2^ñ”,XF_PWUB‹»>1*½šêc™àuñ`{cÖĞ1ğ´PK5¥’ÆÂ¤xÙ¤¿ŒáŠ9ª$ìñ_A#uâñh=†	¾x9áç¤	!° f,Şê3~äÛB´E˜}á\t*r§}Å=¬Ë
œR¼hê[ôj«†;:âÑ)PÜbµeóZB”ªt¢–;>åÑ×%Ç”BÕ\ĞŸ÷†KKÎµ²£¯jÍãu°èÉ'q.d›•!İÇ¢–ìrNíüÀm¥i1¡åj³t\`çys•/Rj1Ö5áL&¬[SoÄGÆ½;TwDçU;c“¸$`	Â{S–‰:İüŒxúµ™,‡1v¥ağ­wøôÉjîP„ï‰KøKÑ,8nR§Œ0ŞWÓÊ2Ø,à’”jäéW…êgÁıMä
<4¾ø§|Óñ¸Á‘<›½†$¶Ç^Hèj™¿ù€‡š&øÒ›Şà“ÎgşŠØnµ~ÑØ:h©µ9T”–ÔJ=Ë‚e97EvôíÊâ)²"É™NR'«-•nÅ+…š|è‰¥¬1¼«Â3ªI$‡½œFUŸİõ4 YuXÑŸ*¨\ÜÔß5mùñxš¸$3z~#^z\ü‰ì>gN¹ÓÑÖ³q~a«Ú*¿ñS)%Ø·›i”§ÃİÂ¡¥^ šaÇÒ3hïç)¦>R¼ZATˆW](SÆ‚#á« NFªc‡£²¿­´J}õ5L1œ˜>®ãg4S¯¶iCÆ‡ú±=e·“å>¨rXEóhÅ¥àgM¹ziÇ.òÌxú:;3¦dÌÖÈ²®‚%ElšM¥Lg;1gÈ
 ¾A“/ò£^$‰-eSòûa49l0\´w»¶Íº·­àe¬—>ÚÈ4AãF±Uæ(`GŸ^fãš®[2ºtfí>ÑÜÛºÍhÌAó'ée ’H.>Â‚Ì¿pqùÛÓÁ[}Ä
ÿŒ]·ÒKvãpGT@pÙ¬\im°Î> ÜÏd˜wdXïÉ”çúûŸ®èD&Åkw·Z˜‘ğF©£»@ÅÃ»ÂO÷tÅ×yÇ&DÀL ù½ÔÁ­&|õA³h‡Ó-¶0õ3[µÄ}Kl"v‹Ô™òğ#¶¡¡Ş4ğVÑ\à"ö,ã, ı‰5Ú‡–.î(÷±zV&Ù˜:Áı»Â^ï§Ò©ÅSõd´6Eù#Şã Q7Ä5`½:Nö
×É}®jÓ»v+icm ¶™&g‰ARG~6…¾p-!€dèË~¦>ß>’o=0dûX/„ÁyßÃ&”Ò™Öxj¢=y0‚¢Ê†£¹˜ºœJƒıbIÂ^ÙÑ˜(Ş~qÖA¨ô£Eg£EKàè^º-“Q¾¥*Hµ%¼ikñU§ÛåÎzşb—-ç«ã'Z>°¥ÉYÍïªämŞÔÔH#~m³Ëâ+5 f P
¥èCŠE£   ¶7òÓ; «´€À,¥ŞY±Ägû    YZ