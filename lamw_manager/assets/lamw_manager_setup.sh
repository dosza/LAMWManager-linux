#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="34802408"
MD5="7403a9923681c7fcb8e1ef7f531831af"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25476"
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
	echo Uncompressed size: 188 KB
	echo Compression: xz
	echo Date of packaging: Sat Dec 11 10:33:05 -03 2021
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
	echo OLDUSIZE=188
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
	MS_Printf "About to extract 188 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 188; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (188 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌâÿcA] ¼}•À1Dd]‡Á›PætİDõ"Ú’ÁàXi‚Ş'5#­R .|a¹N·ÃSfW.ö#{ÿg”&n¥>0Éáwõº[°ŸMDÅÌœx—Ùsºç^NöºUß%®â N² g¾g®PäQır»Wğ—Ò}k34rê$ÚTDphc ›ğ¸¸ _h	ÈÅ†Ÿ–¥B5îû?Ut·óâ†&î—RVŠYl•AnrÜ–PRücWy· €PÆ3ìô0¨-¯Gˆgı´„Èù©Ó×c7;¤¤`…Ä®n§g¤²£ò“¸À-gbîÑ=äs”’<K¢&	ÉQBG·¼ı0©*²ÓQŠÀá°‰»²|âİdÓóvëÇL+cuHI™§lú¶†ë<§"bH&a›?Wt@K•Œ‚‰´¬+øˆÈ²-Ûßá4K‚%Iíˆ¬Ö˜h>ÂÖ“tõ¢÷+ùÚØÊø[Ï[6Ó-ÓRH1%X°wÑ#º¸ÒÎûhÿ`íuÖšƒyæî-ÉLèU6¬û=½±{lÔ{áÛ‹£hÜÃä†}½ÔNÇ¶Ş‰Ó¥Á·Eh9z!`ÅÔŠ(?}9ûí¿XÀ5zá)€ææú~+PPÌî¼:à??ØGÖT^¸},ËÏî‡¸7Zï(‚¸û‹ ‘©I„k¤‚ÕšÙ)à\½­L^R`ù[P1[kFÒ!cQö•7 ·‹@]î“ÔµI˜ë_*€OP]FuİˆÌ¸¸ÜÜ}¿!,¬„“ıÊöœ$UyœÇ³$Ü²Öæy.F´3c¯Ü>”©:’w®*Lîƒ»b­X•Ä¹r×Ë·2õ†NfÂçÈdÜ?xÏ2¬4QmëØ¡@¾m»…ŒÈ%IGF`—\3;Û1JëN(<¢Øùºv  İ‡YÆlqR£øY%ô¤¤fzÆ$µ]úN^?1GoÔ³±lí$Cí´+Q5nûG9T™ÌD*Q›K@*öBÃd6ÇÀqkòÅïıU&Ãº\íKÊ åFqÑ+lÂ[øõ¿Üzv	Z•ñ¡)}™›ZÜÓ€'Q%¶:hƒ¹¨ç²
Ì¤RY½Îøèˆı³,†¼3h0„²¡Xm¸ 0àª¹>(o³@&F¼ ˆE’„ÀxŞWşšÀ(hV/ÂœD49ÒWU¾Gwê¢Ë åïöÿÈÂ€¸×}>¦š=•ÈY	dKWÃNÎ•ù„ïfG{ôŠón”œ‹Òé‚úãC`{İ®/Ï:Ì˜XÌ<‡6„›ƒrÿ-¤ªÉ³¨L„‚-rºxr´Õ;Ã& d’5›{Ræ!fQe©¼4±õóm;wlÎE'zD²oã~&ılõ0€âæ}æG£ò¦TÄ°SÑò?$ºÆ’*ÛÇdiÚEgyJiß ËÙŞï4+bU¸‡Ë#˜gwt?lio2©#CàÙn®Íî²¦›ÛÚŸ)ˆjE¹kå Q~J´8[Ã7?¬Q6¹À3ôŸ&°IMÚªÒÅó•fúuSÈ` ¬Œ1<x§CÀláÚºª‡·—†ş>ßëõ‘‡²ƒÔÍä6µ¡UM†Œùº6Õ$øtè}ÆQ¶&CN¡FMã‘4ş9¾h×Ïl¾şBó_ì-BY©¡ò7·äM&çzó7”Œ‹ªrÜ–€÷f¤ÕXŠ\xû±‚ q–uá•:yƒÿ¬59·KÚ|iÃ®uJ È3][÷Ò@rû	³÷ü¿¥êÕ÷&3úóHŸœğ{­:)ç;TÓÚ¾(ûÜ¥u*2_/
Ü,WYl×Ù“GÖÍC ëë2!hI×CLCâpÆ› ZØñ|:ÛG-À¹K.'9->KÙˆgLK¹übæ?Ã/”%ğ	kåìÁ£	ƒš¨QíƒÖù;ÿ¦¼ÈëqÒ¬õéITS(±Â£®]fiÖ0ï™°èí»ş‹*Š¢ÃÌp æ»@|ÄPÕ.ı tJÀKPiÙ Dï-nB2l§ILò~.cÈ#íª„JàGPQM».»¨}ì~VÑd"ˆ½›õÖ/Wv?8§;ì[‘ÂÛèÎYãêMVi×KY3áÇ¥ NˆD&(»üéI„À“$()\g^å¡n˜¼ïE÷ƒˆrÑõıÍŸe¾äÆ3—¯Åq/MPsmP¸âxfØ„%_ãıÖÃº®ìAÄËUÙn8²8Íe‘©?²Yb{ÉŒa™ˆ˜¥¯:ÆïyH‘2x·ú j Ø d”‰vùEİBsuˆ5³.æ4/5T¬Ò÷åRğ[¸ÖsrBƒÆŸ'æDM*å$O¹PìQNÒ
Ÿ¬²ÉÑãíÖ$ŠäĞ‘G—ˆ
j.{°š¯ö‹~mX<¶M°ÿŞö 8ñÃ>O¸ã×,™¡ıN»Q¦R…,îvE¸¢[·3#–‘#í¤pJÜ»†¶´ò‚Ãj ®]nfÂt]…’/ƒ ÅIã«Ğ•"–{(ê–=vG‚ÅîJ<"´á#L=8tF5c(ˆ´edŞÚğI9{È9›ìşUslbjP¬Å hùA@…Àíƒ†ÎZ
ˆJ¦ÁËz<ÄŞÏÉ~KO<P–QzÓeØÜ8Úè‡Ùï”_Å\\9¥€Ë§d.«P|?ö å@ğÑ²ğKÿc2h+Ñ|I86IÂÍ›g(Õƒ€Å…Äî¤Ïô3ÆÛ:wã~B“ÍğJØøºA‰.‘xéhø2hãÁ¶jvÉè¢XXa zä¤yŞb³µó@‰ 
ˆğ²áºã×`®ò÷·ò,Ğoâ¤ş®¥_tLó>¦3ùW,óÍ£A<Fïîê¥J ×`Tie4ªŠ‹—uªú9á÷\³á<LÇ²@)­â¢F“ÍíŒ.Í‰ÅÆŒ‘Ñ“¨ÍŠ9[4t¿‚rÀ Z#Z¿1ÖiPÍhOüUÀ‚|°¾(äv°fª/ÍË<L[RÉ¶Õìdşmf1šÛÎ¾ÜòPm[l,5Òœ÷ÌvÒ×@–èßŸıRî=s½ìŞæ(”À.+$2…Ä;-j¥ÈY~ÅÄ>|ş¿}å•H„sÙÌ¹ÆÀÊ~ËLùmÛ¢'Då¦©×åàÅ¬d
[Q÷Š2È–F[ââàÓÊbVÆ®ıù·<™‰Šìsæçd[ØÒ=dÈB¼ô]]ÁíÒÍ§mrÚ®Ş«5»H¡8‰\-Òè8ŸŞ>İé”©*F”G7x°Vç7yb¹N¦·QkëÏÜ+éig!XcGTHj»´ºiAJiÍ­»î²ôwL©š8EGMuşÅnS ìaF*Õ×ÏhšæÂSòjÙ]OßÅHöí+ì¨•CX0b{¥ı|Û2ßIz»>ÆÏß#^fšvT?üğ(¼áÈøäçV0³ç–_P6/Ÿ°xµ=«˜½ÓmOã†ïÑ#˜âá¼/,K3‘Ğ©Úª_é¤7İN•¹4ŠÈ¦(È¶§j3/BÀ#¤¹ÃJk¨à—G9¡UùÄb*¸ÓÃè;ßApÓCÚ:m32Vÿ›ñ‚mG e—»lOÅp¡YØ7\Í—æT•šŸ£©ŸRœw‰ĞÎUFWği{1;¦é­„Ax9´à0t\ÊKÇæ?<y3µ†çÔcÖNRD½Ğ*SF p‚ÏÛì°ŸàÀ+·üÚ‚Ï„»è"‡lúÄGÀTˆ¹úJ›ÛM—øíüt–ƒ}(›n›ÎÊdüc_4îĞO¼Öe3âíU_¥Ï­`Ëİéì¯1Õ­\°}J°:³s‰­6¨k?‰l’" »ç´væƒÂ©zÏ™@	<" ó»nQØaqjÙóÛ¥¡šÙ`;#á
É~ÓyÏç½k@©ó#ïPµ¹Ÿ³Úşú™F½F?˜NŒl·™œø!N«¢ĞĞJsÓĞQ‡@)\î<,ÿi‚¥©”g¢ˆ×.¥FÃQH”—äUƒ|È;msÂÏ'vR»ƒ¹@y·iv]–­µõîb88!$ÌÆ~S;K®õätâŠ;ŞE=ñ_â} N,H
]Ë3{¿ğBµJÿQÁ°<sğ3Óú'™lJïFØ+”ºkCó±D+ƒœ›E–7€ı<sAPZLaSæÀ~G¿NeV¦-B5å?ToiCS‚wu	QgòÈWœC(†EüÆëÖ97üı¨>¦;/©ÚXíˆÂg’ˆTäÕàª{©fÜQ$<ô½8[J8ÄLDdß8R.ÂÅü„d–î¨ÚXíl×ı@¸¥wV!,ºÑ¦>ÿ+fhj\0Û;„‹±®qÆ§ÊÊé–Ì>ºÌE åî f ¬YÜün‚» ‡„oÙJJ_µpŠµ?-1@–É0¾»©U¤]ó½çNÿş„|@“¢Lo„æ´vì©°õ©©Öby¢[É”H%¿ñş‘'æ|ù¯ÑÓíbâ‘RÛÉvÌ5k jÀù¥rù†Œá¾Ûç\Ld[M G«j_Î+l7¢á¯šs!jç¨ &H„÷Gâİ¼”ñ2ª–sş‚ßÒ¤v»¥ë
xöÚÍ©ß{ü|>7éä!’uÿ`áøt–<—yi¥äA§€¯ÅD¨<ÅK½Çæäß§“²d®ÆkIâaÍ×a @zûğÒxzhÎ#…DòH5VoÛ•ÑûÀÇ_9äÛP¡ÔÒ¹®š&IRD	å¬+²Å&¢Bø<ºkCé‘‡˜„Z/_(’OG¼z0©ÃL8°õyk½š×Ÿš>½ğCäıÀ6½†ÊåçL'Âu75IU‹Í(ğg£GSQƒQ8åò‹a‡»ƒª3`Í°8Tvõ~ßäPÏójxı4ö¬¶Háè@éà[Äôµéæ“Xtä|6gÛ ‹fd›i:+@,XÙLåü~†"¶­CŠ5ëD1kÑ“O„	Ë(oÀaí0K­¥CËğd4S³ÁÕØ•x¹“joÛ%‘»¶~Ô-ÙÆ]zÈP¶äÈ€«¥‘?Õ£ã½ø~4P=_’vÀLRFa¶@øeó‡§ˆ>‡öş{çfõß²+LO‰¯Ô¡¹› ÿVOâ°+KAı_¦¼q±:\mkl>¨~ñÛû9IÇCÂópã†Q'-*;äç3x¥Í¦%KõÏ5àItFÈ)Óu„RîÌñ"‰‚DÔ¬iá#£Æ‰^ ãc_‚C)Ó8iÔ÷!gLípĞODæ³§ÿ¦)¦’ÄÂ4+§»À ­Ã´.ôªiô.È)Aöú°V9}tö—‡€é‘Xí‹~Ùk¥á(*±Fšš£!áô¼€+eEB†«\ñT+QÂwÁ¢ïJ|ğâcÆ’Ä®\,HU¢ëÙü,¿Ûjè‡DİYÛëO……"­+ñ6ó”âÅ–Sî(şß†S€¡:”˜n	¬ËÛ&V3=š/Ş~_ãŞºZmãæ>âUŠÛÎ×E;¯ÉF0ŞtŒ@¦Ä¿Ç}dëY‹Z­Ì7œ¿	kX¡ËëÖNúqå5²˜ŞôbD5|˜6Áë²l-»Äì¶„×½J{3â Z‚GE€ÊK1‡Kñ¥–Vê$·_ò)«Ô,QŠEY¸,öéOÂÕ›
¾­ÚuÉ²ü"ªm¬ ¥¼ú«´Âáåì•ÓT0ïìLVˆ5¦ËÕ×qÙı,‰c'Âp‡@ºØCúC¬;²÷ù¦O	DÙ‰° Ä£¢%“´c¬İjìæø¶¶nR=ì:íJÀ	Hì$feµâ9Ğ£Vj8Ë·jNB»òòÈ´¹L¢Ráî’ûo$‘¦$Ao*6Ë8	f®‘Nu›1Û:3'ËRcj‘UfãúæÒ¦7¨røıF‚Ú?ËÆ…¢d˜ˆÃpØh6x½¢º…G`¹“BÕ:°Ë›J2yÿ*`ÛäætSåêÍ*†—¹S„I·<ìÄQ1#`72A5®ûéùê~uLN‰#ñ‚mpğgU:Ì,£Õ]ÓæY?Äf¨Ş_}á&ÀŸ×9h¢Î;Ñ`F>íº]VßàÛR~×0,a?–NÜ†}v"”^;iÁôàBPk'#CÕêà4#ÇÎm›íûÚ–ÍTQ_‘¸²7£jÁÒ¾+ÂÈBûÙöŒŸ‰³şÍ»ªŠI‘­².ãª—Fo¼¾…€ ªŒé?Ò˜’V¨jßŸŠ“]z!ÌVã¼¿Î‡oï[ó82‘[<ˆ¥Uísl#—\Ö;³4Icak}× ^f¶¸l+ivŠ 5Bq!†ù2IåŠÌÿí#ğª¶=üB	“âR„÷\i×Â6è˜*:
¯CÀZ¦®\™¦¢5±²!?f;~òË
K …
Eß9cË'Ï;|&i¡ºøaëêñRQ!Ûè°µ¢Ú íEtõÍ}<IöP"fáx~ -ãÓŒ‘œGü
t©ˆóvFû8†iE¿M]Ë`š€
MÁ#Ó•«áNIôO@øƒ€>?ÎpûHû<š=è-"ïÈMœái÷÷-}V‰îEP*‰ßj<RÚm¸|«‡ú©Ğ\5N#Z”'›µ¹‘Pß`|ïQQ_%â –i£ÆÂNZÛ©Äi8!–WíWNÎ	ÈV­t3À{Ó•éN™tıó¿rÆTÁ_ì~ª¦˜dí;prˆqíĞú¿P*„µ5KJ¯ÈáÊ>˜
*»Ù‰‰
æKû $û¥±¾úÇí’Ù@ûûÀô[VjUéqÄë;±
¢Gúû*L*Èê%Øêá¾mqÃóúw²šE’öG y-Êß,–K”ÕPhıé¹¹Ó,«õõ€m»^ğEœ£âdšÏ‰,ö0Yy®Şæv‰Şr/MÚœJÇèªpá»l>v²µ2›ûö¼o>:Š@`d0TiW,˜™H°–Ğı’FÁyı.ÒJÀ½5´âkÍÏ¨jm5¶m”m™3ğâAà¶ÈRI
‰¹k€|UÆUFF«
‰ÜˆÄ¢ÖÔªã6Ï|e#<³öwàq°HÜ¦‹ç01`ísTmº`Vİ	äsèT“éb/¡<3KÊTyÃ%Ú[„¾Ó·?†’ç
SĞ¥‘ÊÄ®ÒtşI==“]»Gbå†ŠoJµÇşº» wøÒâ8$ƒ	•7»Áê}”=~0Û…Şvñ>Ğ\ZùfÒ”x*¨Wõj v,†wéâm€¯	õñ’Îníê­›¹¯Ó‘ñn€$V’%)H´“`ŠKÏs™‚§/¾Ü£zÉÑ‚‘ì¤aJ‡#0 ¯å·:IÒõ¹+&árùŒNû¹™¥…	u˜˜F¦È¾™Ÿ€k`%CuÉm	è
µ¬È®f7±æ
†ô¤kLæS•ä·ûB¶Ij:7Hd˜Ã)a…ÓY}–î28Çè3ûš¢¿Z¼ÿ®‰ÙVŠqs‰ÒmÑ’ªX!çbtRdChÕÙjœùŞP·Aƒ1Ñ–8ªş=¹èX¼ÅÉf&¼O5Cß˜£lB¶Á÷ã‘Rl1PÔIû¡ğW¸\¹ñµFˆ?Ö¾Ù/T]IR÷X!â~–ùI‰ÕÉ|"=T[¶©j^|S(±+Ds¬ê¸å*ÔTOlÈ fpbºĞ&+Mù¢åLrCkğ½MÍÚjU?Ü»Ç–ò×(	…ÕOXàâN{HĞ!û,ˆ×ËÎ3Mãw~,™fUn3bíÖò¿/PU7) 
µaœ!Ä­…Ifmå‡°ë’‚ı*§>œ alĞUÿŸØÿ°F`sXÈg¾S˜oÌ@\ÃÇŸ×óç†æü²‚—…ò×l–¤˜¾çfÒïëF®  Ù&NB€÷¨tŒ³FÚnµr!XIQÃàİ»!};¤óÍŒÙÒ¼¥çâùraµ°˜g:åÂÖ¶z™K5"0Ñü<ıuÔI4éZæ^,¬yeùmºşÈĞİë¥³ÌWâ•	” Õ	M¸aÅĞï¤'ÄíLs‰ÆH¡‰ÒúàêeìsEüR”-ê
8šišŠ(óM×öq{êØmaµèæ
½J0‰S
ÔäÀ7g«[ì@ ŸŸ¸¼‡œoG}zÊXßoOÜù§±ÂĞÂ“ŒBÛğiLK>6DÀAb•6çÇóŸXöËÑã–4©Z¯FíÚî°Â )rêÅXœéì™ó¢¼Ì8gQØ/Cw¬6nœü"lnkıÃ¡4'©£
T-ªÀMeŸ j}‘Ü'n°UëŒ‚²HMÇ-ßŒş«êèÊÂÑK…4¬?s<Éa½Ÿ¨'VHnÅƒüıÜÕ’slv³›Ä«šÙDû7êª/áå2J†¼(”GaKÑÈ?K#·F@\ËóÉe\(tC†xØ¤º
[D‹©urc©«'[Ü$+j„/:ÑE.üÓÆ~nú¿Ù,3M<½} HÖûÙùÖë¦UZ.i½¢Ø`Mî¿[X<S&»sÀñp@böömçÀËZ\¨VËõ™xŠöÉ±Ç*ç3Axg¾ .µ»ÌBÏ¶V[qÔ±zßL4,Zõ	"X·ZN`
âï®mÎúÆÄŸ£ë>LÈ’•Y{]TàŞc;zÙ+Í4Æ¹¢,0vt?Ñ|uï3)¨úõMÚGìï¯}ø88…„Zÿ´µV‹~8§óŒ/ìÍ¯õƒéÚOûÑ¡Òï#=Àğ‚ÖŸ^Ê s#Ï‰%w¥×‚Wn_(ÔÜŒa&Êîñ“^*ó-UDÑçªÉèñæÈú+÷ıGĞ-·Í$øø4MwO:}AŞj^So¦7èìA¼î$ş–¹,éÖ–Ùô
O½!Â€°7)gÀw)^ˆtVòğz^¦š8`Ng™Š´.(ÚÄoÇXşïœ§ O¹àå5²Í1ìp/ŞûGÆaşıÿ	o6ş^¥‰‚dFĞšÖoÒKM0>óæ¿wEPÂìºv?mèÚ´GM<™´\ ´#\N»¤Â„°š½4-Äà¤İş?l¿(ÏıA”(†øwØv”‘	—˜y dPq<˜£ÏèíXt V:òªŒå"<Eş`ÊxÒ»ZùÁzØ T{†æIŸôúÓØ€í½ç.Hİ„ôıß°X»£	döF¡\B4yÜKÔvóáºøh£Ô5XúÌµ'˜ûQtËh ëáò<dŠÍ¡ìC˜@	6O¯fÎ*Ï†*¶ÿ¥¦|Î‰ÛÌ«Ÿ*È´ôİ«elÙfj8“K®g'–ó±Ur¹gMMUûş3áwé #X«D>şÎŒx—TYR€ƒ*X¢å+±¨FâQŞ*„%‚İh9šœ1Vb`1}^ËézÈJ›ÂâãUQrªì+á°:†³ùÇoÜÔÿ„"ê:C;µ5Â—ºUù&Ynp#î¨ÑŒ6Û©ĞTD÷ŒdùĞL(Á«äÄe.¶A-È¯WÅ}py£šV–Ø“!V63ë+ºP5S‚²š(±è1S,³oáçf'PÀ×…¯²Ãñì.ffªOR%º"x,;ÿã®À‡´i’{÷Ä¸¹F~Îï»\$;u¬î]ôtñB`n£w‘´~L½º?W¢œàsÒ|©Îä6lŞa[Q[ ö²(Åá‘5Tj[¼ (P~Èp#ÄuĞ™¨sTàUàÕf¹®Æ˜}‘·øL/n®˜bc˜yşİë^…j#ß†âe}fBÜn«½},´¾c£*)§ŸMtÉˆ	[L[ıÂ«ÓjŞwÎJ¯7bppÈ<¨õ·JëGƒ`!gnÙÎºrg„ØùÑ	¦»zÒÂ‰ş.ÛÕŞ4+ˆaœüƒ”¹ÑuW%Mp!PÅ	ó;CeBEªÊÛœ°­C®§šaÂbŒGL+XĞŞµİƒöQ4q]İHÙ1§Dß­6'ƒÅMÛ>hÕáÀĞGtØÁh^âf”âxI}¢Ní5Ñ$¿¬Ukï$9J>~ÉZ_’yZÙT
™«ùM({÷% ~ğÕÀÆƒp‹„²x°¿z4LfêÜ3—}*Œ×€j¨Ã¨ü‹$	0EÄ¹ÇÇÓädG.ƒ‹%Ì ğ™I²«ÎC?o¹¦©ĞÏ'açÚÈŠ§âCv{Ÿ¥QGójqhSÕ<í9’İ^ş¨7¶ïåà*=	ÂÔc³;UªVÂA?œuòrºÚ“Z}D7­{¶µHBŸ ğ7óS±8[¨‹İ°Ã]d*‹jkºußÛ÷/>Ê‘^ª
éğJ¯5ãÉş7>ƒfƒvªá¾òA^µÌà#Äma‡}U‹¶oa¶b ~»UqEÖĞ‡ô›7¯‹dßàéÓæ$»”É%÷Ğ9më:¨³”†.r]Ÿ.-R&,„išÅ‰Å¬v¹cCßÀ²ê 8.RÒ©lsš”Ÿz.8BƒAYãV¡û¬Ñ”Ê¬eğ0|Ç‰ÎzoÆ3§Ş½\Ü#Ü…Á¸†únâ¼kìåàxİí—‚bƒHP”$yâ)#ş ëuÿ©£"ñæÊ&AÑ-Ö»,6š3™ß“Ê¼Ãr³ˆw.¥ˆŸbNl½çÉƒ«û¶Š{C~RYşuö¹«-×õgÖª¼öqÛ¶‘á`³o¹»RĞ®…ø×£®°‘Aa^Z¨C²êT8Û_VX_5…*0‹¾¹Zÿ¥ïÒT¦´ ëRDJñkuİFLªc^åŠĞq÷L;UÌeÂ[9B]¡¢œú—dl‚Ë;MtŸ4 Kñ3•NuJÇwÆwÌŠh™#Š¦ØwÔş÷äØĞ›™UWö~ï`Ã/C‡Ê$ Œ)gOXä–F¡LSGïÄ#O¢¢TEw\¨ğ	qûPñü…³: ”#ßX’6$ŠÒ—ã‡”ÌêÑŒ@¬Å+İf´põŞcQiÒñæ’_²¦°=\²÷@—yx¨ ë®¿ ¸ªDŠQEÑO¢ÃñI*D¼pÌ)‚ˆBB¯lEUòå	Q6¨½Ùá¥‡ŞhL½‹>o®‰
3Dˆ‰¿³¥:¾ÛY©ncœ¢‰ØYŸ
_ˆÄŠAÄtµ¡|U¦«¤)Âù³*m’üAé0#Ô3Äş °F²Øê(ÕÂ6ìô’÷_ÖK•±m,N÷ëáÌ]Şÿœ±…n×úÚ@F™K–â§É»VÌ!¹Ëz4Ë¹Ô¹¶Ö˜ôQYuA©Íšug‘ÌÊ:p,—¸®ıONÇô‹¹Ù¾9D·U‡Ãÿ¤²–et0Ç¶º4®şïĞi]×„ÃG{lÄÈÑ1AıõÖäB0º›ùtRq…$<BCÂ·õİœh^ÊúºÏ?‹Ì(`J§„Ñğ^ã»Óî¢$	g=MN¿½Bbë}Œßˆ1½ºıæ÷4i<ş§Ú†zhÖÎ×Ò~`{–yY•¯Ã'õ`J2“IiêÉŒ}ĞÔ¢«\ß4NÅ——ÅÊÎ{Y×pB¯=*‘LjØªUŠSÕè¹ Mê+ğö°¿-sE&‹±7¾7*à^À»ÂŸÛêxŞ	Ïwö°È¸õ"‘>j:J§9ù/ğâó}Qøhÿ>?'²«cÉM¸æKÌÆêf¦Ó›Ä[ø×AOÈÖªŒÖ„í`Xğ|‹™ê!Ù×¾ğf„…GöÇ°B8lJàc˜²Ú(îHvÕÎ²\yD-Zv73¤^gOÚµBuş=o³J´@Y°Ò‚¦,Ì@”‡·Fi¼©±1¡¦ˆÿ û=k—¼7ØO§R\#rR6¦˜|Í,Îï:²W=Ç÷Ì39ËíğYşâËâYïceÎø†xp9h¼lH¯rêtæï1e	=4‡‡¹æd¸~¸e_¼$À¦?D©EF¨\—º!£ãX¶oyÒú6U?®JóÙ¿Éâ5²êYÚœêİ5W3Ãñƒ° ˆú-¾„[ç«P¼üôµ6Zk¦TêˆÔ×êĞhqÃø„l¼ug¯­omM^–²ÌÅÔİóĞe"ÙÀ²üµëHó]+€®CTƒ‹ÙhÄB¦'‡²Õ€UbäK ‚"÷B0±u”¦ÌÀ˜z’‰iÉ"cl ˜¡›C$–Së`Á0 y Ú‚ò^£êbJ[aQG$×5ÖÕC?=±"ÊV·»t3ÛfåÌ‚ØÚL«öA[RûJælÏG¶ÇdŠ))¸òı@;ğé<şÜèB‰ëôÀwu@Ñw¬eZA ìc½\…‘²)Ç©°ğ
ƒ•øÇ3äL?”¼ô¤Z	@îb^««é#lF‹Îr­T‡FÔ´h¿=oê°ÄY”FAÍï+z„İöÄ#:©ÅøVö n‘[DU§ åÑÂEê“•ë•HÈ]»N°(xQ3KwŒÃTÑö š–Œ§&6§1uÒÌS@zÅ¬M_¸şe+6ıB$«‚–^Ô¥*¤ŞAUÃ8Õ\½	’Z¢Dš¾#×"¿¶®‡F*ĞŞ]Ø=l[È;ÂÈœ¤¶µ Ê¯Ë%órk·q£¿­İ²·ß³Rğqƒ5çY¼ıÅHënnR>QËüø ¾"í 6z¾z}Ğd¦Y‰›ÁŸQ,(×8î¾ÎŸ"AZBşoìdkÃY¹y}JŒ P>óÊM¤ùÛÄãª„ŞÇj½4ÑÜªdLÇœÄ·Ç#°% áük—fê¬¤ ¥H‰‚G	±›“¿†R–’»/È‚ff/ÖV]2è¹7	şT³t…L]ß)™:ÂúnI§'Œ Æ5–ÇTÇˆSaÇïÏYİ4¯¾-ÂJ&LŞ¢ZŞ2f^¥ *ªtŒL¤*¾,èZÓ<ìê…Ë"©Ö
<mI˜»¦ùŠˆ9HlVÂ¢çÜè›qg<¨tº˜Ç#3<Ëı	ËDxX¾ª	“b`A§'ùyzõV8<_Zù^)^/h½-ØÂµ­…ÌgUJ·Jÿ´€LHğ âSŞÿNŸûo·g‰æü6øƒHcDEA”QLKÇY”mmñIÊ=MVØ!¡KiÌu}Ò°Ó|HÙÃKî|ß/â§ÃÓLˆ¶xÒĞè>áXW?r.pŠ¬°’ÇÖX™™Nñ¨ V¤â˜ùw©\Å,IË-¥Æÿ +U”IfTL¤¸2èíu t·[?Ÿ¶7`ïi…¶Dl(ü-§Ç8›ê¶ş½“Ò¬ÀôÆÏ`{yÍß»ÛÎ¬š%¿„@l¡@ôó¹Iäê¸H6oÉé›ãdh« ®!ïÀ}^÷Z wÑzÒ+ğÅDÒ=z 	š3ÌšNYFÔ¶ĞYF{ş«îí«K¦@–u»µ–A™áˆÚ”â/Ğ?Ë- |<‰Ìü	;wµü%ˆ‡”Ş[†ÍœØĞ®úépsÀ_Ñç%ch>x_Û±öšß™‰y­¾6|„„=‰Aé?Ü§Tg Ï«t_¶Î‚´£ô ÀÈÀOŞ^Ö&¾ÙÙ{5NŸw¹ÉÔHG‡¤ôTuaß(JQŒCiuØ=Zx%KÆõùi6	7»	ô>rÕ°­e±gÕ=ü
¨œ¥­Ğ, ç—Z’„óš¥<Ä©|ĞP¥. pØâ/YiÌB~oÙø9:|(?ò&ä†mr¤4M‘Ÿe?³u÷Á£Õ¤!µ$|7©``…©Ç2–©õ+é^k_™m
9¦šaZ~ÉóÃA8+cè‚œş
yQÚk£Î-aÔ:˜Q³$ÄÉœü‰z:2™ş:à³‚š¢ĞÒª
n\¦ºG	ÂŸ7˜]>fEÒ£îpíBşÂ ­#|?rş¿Rã‘F¯1@û4ıÜŞÈ3‚È?„À’ñˆú?WÕZ2°Ö €Èˆ&æYŞŒoı¼ğ–<—·Q4ç	Bó!te1r¶¡M+Ñ~öñãˆfGM<C§ßì§ÂOYXÎ6òÑV¼Xè˜±Øº&~×Pú·ıÇâòyMÇÇÈÿóEÅ–=hï‰ª|\@‹ØRùJ}“¿ªõ{®—
nİIµ{‚“»¹¶ökIøİ$xúæ<Ú‰½1°H Zù»ÕŠ†±¥=ËO9Y32õM¬e'Öµ–hoèuÇ°D=¹· ô6 ‰ÓÆKâFâÕpëÿ¦o»êÿøÏ`cfˆMõØ¢$¥X™¡†Šj’eF>ÿä•‰êÉˆ1ğ‚Õ£ ~t1WôÂ6ì,>ÙçÌ8ëoòíÌ+”È›Õ&Rn°l9×š;ËZ¶Şß|Àá]^f©Ãır	ß_{^0óÇ½ï\äì=aCÖÒ•å/ok¿6×ÆNu¸¹&X1íğX¶R¬Ë“@ ãù5(4·”Ñ•ûuÊõÿ²şûèSÍe“×ğò²8é‰üÑ®Îù5MV››("«UU2»üø!M%Ñ‰a]ÑhpÛB[*ÛŸv0æO	ƒ!ùM2ŸğëS$´{–øŞX\KH„íØuÜ_»®q" ßıBZà¦”é'Õ×©\k…?)µùuª
¡$Ö{š„"ÇÂ)\@ëÌD(÷"äßB™è‹æYËôÃË:x%Œ­µ·>n¡¤ä?2x»¦’äÄÿOœÑÄdJ.éá¯‡ƒ8©€«)W	—BÍîq&Å‚ë“Ÿ~«$ş–éÊï@ìİQ1K?G¢naêC¶Ò«­Vá¡Wª¢àÕ•®%Ãõ«Íw!kàÊO ½?ôço§qp7MºzÓ™œØOQŸ
uœÔBéùŸ¹½Åsê¿8é¦ø›,#êVŠyø³¢ãQŒÊÃpO6p”ßÙó‘kÈlXÿH“ºé£Ô±Øs“jƒX·DîÏì×¶eèÃØ²v™\ßzL‡¤j~ôa˜Qı¹,e{fT[$µ“”ğÖåéKKİäè¾Cc3<!ñ«­Œï)\u@,=^çV&mÓ<û¢Ó(Ó­ÎúÍ
C %&ùÅZv­¹Jo€¦
–,Œ?£–¿òqQ5Ş¢Îb<TáÂ<şº3*wÂ-Áëeé9Ğ‹½¼Ğz@Z²ˆ”-[ÉÌ¤`Ylûáş©Áw¸Qµ°QµÀ5ìf	1+MˆY£+X/A±ÒJeÒ:+z;%ùòXwÖhBñ˜“û‹8z\¶j à…&›²óİb7ux‘¼HŠNÌ~äP©w% ø3ÂBo¥áoáö[$€£!ØZÂ‹/ãÊ>ıˆ]dİğ“Ù˜öHÖõïø«º½ug,6/Çç^ëIe¸2":÷Dâ"â4ğ6Xœx„*«¥Çğ¢LñD1Íİøöé"ì¦J<Â›ô ­É½•ucáDC3šì£õîú¬\¨ô5x©ì§×Ò¬ß†Ò-Øx_:ğ¹!QO#&î…D±“{¯q5³ÒßOË»q ‰ì‚Ÿ,÷­7@‚Ójühà~è<	²,:’!ÄvòêrøÉL¯ñYñ°×$'Û1ÂRŞ°gµ¡9¾2½C®ilÂçsŞ§ôù¥rE6\«ìPvšŠÅ”~vZŒLÎNîñ7@X#¿¢›FòV!k[`È7[2[Õ–È…¸–¿GJ×Ïg]uyMhÈºú®ÛÓ=+6eTÕn9ûÆ±¨–tJZ¡†M+-‹Î-®ÚÙ:ŒĞlæ=J¤“]>u// Ç·–¯‰9´tğflÍÍlS/£Éa´)N­VyE„„Õ?âP§Ou›ò›õS¢—>ƒF‰ãäŞ]ıÎvàq’Ê…—$;í”Ş3çÂ×îÓV9 È}HªĞµhÃåÛIk[Â„„1ò [VÆ¾ëÀöŸÉâĞêy(‰RCChhV¿(I…PM4%Ûçy@ç³>‚ŞZN&.1ˆX0Ş| Šî€¥íŠ1![íĞ©.4GIZ¹ÿÅ¹ê˜È[ãªÂÉfÙQrhõ&_Äs”‡% cÔ\vêÃM'™ÈµRßè»w¦€€j`“åa.McÍ4*È—$†ÏÒøÕçA9¤0Ê	7RŒ›µåk²·4 \‘Èú(xK£(%kÎ£9q x€¸šù_õÙóQ a™±ÓŸ!ÊFÎ¼SÏ»W¢ØpğÀ[ğ~üôóbÿ›!NTà³dd„µ‘üÍ‘àÑ{€4óÂ­Gù{|Ê{Ç¿èyfzšàd)G4§„„ÔO¶ˆ$}£¦²T$«³íĞ5¿İ»Ë	àq±=#é_5—›â¶fS1b¤ğØÃz#n¡rÉUœ·G¹l3ÙI%*Å‘ùˆ”íZ$+ì{ºxøÎïÓ£”²ÚòQ®Ø‹^íŞ±`“_ùM¯S;™¢ÿgƒŠ#	\GÕ}¢SÕ.Õhs¯ã¢r«}gã][SˆXŞ„ÖÎÖDìm“º¾³¾ãş+Êµï4-{äIÆqWÉƒìæ{†÷¿rê”„ùš¦fiSµBİ;«´á°­yH!'¼pÈˆ•eê)°ñŞ}ä|_J¯4V‘ü¶Ö5,È6~Â„v­p_ƒZÍ%£Ùºìàtê^¼õÍ‹üÚXû›ÀŠPêÌÉÒ­»í÷FjØ5@òõ£ËEé>;ñk‹JJ¶y5æÖ_lYÍã{dŸB2q?ü{nO~ü›…K©??ó©ÉÓ8\š*WÀo¹NvD—«IŞ¨j¶wÙ XŞ5ëLnI÷)JlÎµ³`e%÷0[®ë.®ÆJ–u¸å´æ•8T‰cö#Px¬Ú'ég!­¾iªÛ!F0E\/#2cŒKÓºJRˆF‡ARÊjŒ6Š˜G¥óØdá'îõr}9í¨NÕÂÕdUxÃ?¥?§aÇoçehrz]b‘?ª”:äÄ&6T3á¡şRÑım`O}r—;ƒ7Åh›ñœQnãOÈòzV8İs#äŠ…ó	Iİ3½zÅ‡:Pä¢¿È#Ş=~£«hO9gárß=J]r‰…ŞtÜå[O¼b·³k÷:]áİ@M
~İ,2ğáˆÈÕU,•e96Ø
¥íĞ¬8ë›ºÁÅ‹ö|Ò+z)÷Á`†·ÇŠÃY‡év.rG^f)ÖŒ¸Ûíşf«ò½ßùY”óvL¦+D×íË¥Ü_%'ƒàRÛQô¶â¹G<'u ØMüKa¼@h):ü.Kµ)Ójh‰–}I’ş¿×bÌl‚ì?#^g™öœB0ú%82WLI'ØñJ'4¶&âŞøOÄûğ÷¯0ĞŒÈ8Öb=fnzRJ•°,Œ¾
ËMJaÓhßtFé³ƒ–út óûÁql7‹*½Â`ˆI,WlÈ"fÙ#ÓÃF˜f±0ãPrÜ&å¾Ò,àî².¡ĞÖ±ë… [±}OÙÕ×çŒ•ËóÊºì¯TçD“ú~yø›=*z­GLTX¥F°÷ŞIÜ¿ì7>+c9KzŞŠ¶ m·g32XŞ»+Ø:É¢¯8~UüUlsò:fWc­Ëy½­ù1€gD–^nD[sß²T‹)4#¿È§ ô€ŸÚIƒ­”¤@ªçÃ$Íƒ¾GõÎ§ö0éGEj\ålŸì`¸‘DÓá{Û!Œ÷ò[³[E/<°ÉwªWN,¡OodĞx¨¢|dc%\«Y‚H€†•Îå!«½H®˜W™p>¤|Òsñ´bÖİù2Îfô‹¦Ã	r5,@Ë¢ÎÕ¨Mcˆ¸^ãøHâÕùlq&¸‚¦H´–0KÚDØî1hÇà·ÔüÂ3õXÒâ£Ë6Ğ¬‹¹£5•ÅîrKXØlRúJ’©oáÕÅää¢˜ê"w».)éà
§Ê‰hÕİPPº ÊnäÌ;Œùôµ­¼yË0¹×>‡Æ<óÂ¬ƒÜ¨0Z,½Šì5Œ¯Ó3°YE`o¡¢+]³úsŠ9hA2U†¥4Ã%‚ÊŠÑ¦äÓ(ÕÎ¦ÅÙG¥I¦)*İ=ÙfÅ4êE‘÷!Î!Öa(CpIÖñÍÄdª#c$¬J#Jiô£ÖLœkÜ8IyiEÊíÍ~Ël8ª¯w‰Z;úó‹I¯ÑA7µáÆm,4xÙ½¹Æ@]ƒÅå*gØªoŠHE1Ç¤øè­‚^BÌ•ìŞ¨—6Hhå$¤1JC8*À#zœ¯¿-îõÄ„Õî~ÌîTƒ8:‰ ÙêàçÍ\§PÙ£Ãš@ö ƒAñuÉY$®£n·–ûúLûH:—Ä“@¯^s¤«§yJ‘wÇÛ~Ô"íÅyœ¥AõÆhÜmØ(íÊòDÜÁÊÜÈ£&+Åş:¼.Äú¬ßk:*‰<|!#èiÄœ]e M÷NxĞ•¬“ü÷YD¹#ÈI},LcıñÛR´ï™X(1"ÛÄÄ‹ï´™r‰Æ²»‰ø÷ØW$>C¾`ˆÕ3næ£\Ó‚ N~\}ôVdh@x$”ã«pGsN%šÁüF†ÃPèÉ<®ò™,Ğ÷Éª×*ıI`q¦4BCn²0 ù‰¼Ç\>í7u˜>2|Îe“‹ÚY½Ïy×©ê<áãÇkj±FƒmÑÌ®õCP‘'[e‹iµ^¬Xîã¦‡¼¤25êİd‘ÇşŸ36ğ‚º`ÊG¯'mÊiÒ­†ÂFÖB¹°BF8§°ï¤ÜïW´=-Ü‘—êmH|²Ãu­z¬VÉ|\h¡Š=Ô°ÜŸF‰móæR KøGŞÊ²X`•‰ÇæVÓç‡º¦åTj< ó(‹d”œÙ´çS]#\Ù±5Pò©›…Õ<"hhî”“¯ûujO|Ê_öEéÄ^@ßíºäöáNÂÍ…IÎDEÉ‡’z!ã/é«Å˜ÃWe ¦L”Îè(«áåoî`Aı(UUÙcºêP§“k‚Ò£Ñw!¶ééKKiÓc3ï^yĞIä>k #?§L<)}…Œre»4cã!üŞOÖ¶­|Æ˜Ó‹Âe^ª¤³ºF€¡¸qSÔMı¹b`œDkgåÄ›ÊsE3;÷è‰gÌecj)ái©=ÛQ°'”ø"@ò¥-à6>ë‡M’5s.EÖÆsxóh–Èòˆ•”'ì±/]Û]}‡uûïrM’ƒğô8Í£á e<¤~àRBch“ÖUe¬æê¦«Í·ıåpúuÑ>ª.«aWT
|ÄV€î]däjÒMŒl5e›¥Š¬S¡œŒıÒªy¡n0®°¿š­XÑæ2‡;¿“½6İ“ÖS¦­¼Y	‹Ë…`Ş»wB{NÀ~‚©†J.ñ(Â•½ş˜Ÿ]µÕ	·\§è¬Øµëèúì2‹æ“œ“Ì·MGA½½AN¾âÕàŸÜhª«m^{–†ı?Sb¾a´wk³)ój_‡Ğ´ÜTåÁP7vò?‰ù$cÅöqñª	äŠë–@-Gô1	¦ˆdc…*L½ïSá÷4”zŠŸ4!1àG•SÿDŒû¤œK?( Î…Ñã4m+õ@1ƒ"C‚ğÑœ£¶èæÜ=·T7»¦ŒŠÎV'˜Ü7PËm1òk8bz¿‹z„Á®’9Ş¤½«uúZg_@åâtèëW”…ìºeà_¯!8ªŸ‡¾æÈ¹kØR2}âõÉYh&Ãf¿T¹Æ·„·¸¾š1-ø_^LÄÄÜ²ZüN\Æ©W­GÂç5gcQ´@nÃ=¦¬Ø­ljÊˆ¶xB©6¿øi*„ú¾ÃvàåÌwëDhÉË}¯€ÀU~ˆÁúô1yXu¬Îóå°øñ^%ô¶¶ÎÜ£œø‘ïjìùÒW%ãü^?1©ÊTq?P×*
à­&²µî1’~?ë’–„nZA*«z„µ…Í×íÊ®’¤pHÛqŠé„ù8°¬©âÁè½Zb…C	ŞGfèa¡şÚ(SzŸJÎ½‘ŒOc¿Êfız©lhôD°â»åDÏ‚C"yÂèTå”óH{ò¢X‹§H-P$?kÆáSjâ€LâÏß/PhÇ@¾6³Ö‚ C¨%Ê±Ïş8êx#Xiê?¶Õ&éjï¬$'YfßıÏp<·ñé¬>XŒıÏ>;Ú¹
1½–B§/8éıAM3µÏÇôçŒMªÛôÌ¨Zş±Gò{#-‹ŸŞ-t½çe+,ôˆ˜õ9€·¸©Ê¤„³€7—b ¿1Yİ+3ì‘›x‘ùo§¹Å§O,É‡K,G(
Êd½b³©ÂÀDÖ¿¼hİãÿ.ï½Ÿ‡î²ÜÂ©.ŞÓ|À{ÌÍË€6+Àª!ÅàohĞ¾²ÔÕ.;
»\X%³ÕÔ#XŸïé(Ì(Å~¸)WR–GG°£d
WŸÕDD©xÁFVR¸U Ñ¦‰ác‚F„Iİ¨‘“¹YĞ%AQy7ĞÙ&Pçøå: úãšZ‹ĞØ*LÓ>-ß[`	¦’LÄr» PUÊÕU3Ğ5ìq?³DL)ú,Ğ“!G^ˆ""éN±Ğy7PÅù#''1î¿ §¸Üh×DÍ®#ÛT»øá0(ùáx÷Ó‡<–ti-ƒh¸y-åF®±“+ùÓñwÒ„­A1l÷†h¥%U›“öä#‡jìP ~'¼“tÌ¹nKƒÅ§ê‹ËÉ3å`,ÁïÅË^RÙ ÿP
åÁÉÖB§æõI³vxi»^rP„Şª>ICÚö=vµÁñb]¥‰•®jŒŒ*ŞTmDÍ²cm"°F{£:½’÷<`}k½ª‘$ë©|c.ÎèÁ™OÉ{Pğˆ½7ÓîCrdb§÷ÒßG¶lyÎ­Üá€YIÂü1ûà İ·q/òd#Lác‡Kğë¹€¼&•6TWÕ©Ê¿ğIµ×ª¸KyNÕåYôáÓ¿
G`u#6v¢ŠêTªj$Òy—`â’”lì¸’uãúßæ—F¡©Å¦¢e~GoÓuÃOPÅKy¾³X%Dî²_«¤â–.²ßœR&½Õ<Iun]ËFüÜùtpf9UÜK6†•Õh§_mtÇTå”åÁ¢Ø6O,'ç´‡5c\”7¾M\5e£ñL
àÜv¦š5/¬kº3Ê•Tş5M…“ô:BŒNXe\¶å#Lr$}JH¤/Œ›Khš”í^niâ/×ü·y°•˜‘k¸°®	¬«È}©ad’Ü½&²è_¼™aFÆGÎà…=Æ]~ƒw¿£fĞİVÉªT×qø›Ó°ñ…Âœªökà™Œ#s›Wà\F¾õŒìq…¤ÈÓ„îeÂã—™ø9ip£VJæ?ÂçxTÏÖT¸áïÍ]Z•ôÇŠ-­w%ˆœ_T?_¿9iñÌ•)Óê‡+‚Ïsy0¼›øã÷İ±ûŞÂªUÑÂÖ–
’Ï¸PÌƒ.[\‹Â*²»X®W4¥œóVcLÎĞDãID¦‹=„+v³:,gW€üíw«5ptZè¿+çê'„%‰"Ç¿„¡ö©ğ
`¢Š.ÒİÕàC”c©³¹I™'›fß¦h+\ÍŞP;(!İsjÚ”’¼kKÎº°şU•˜ t­İİ—VkìŠğ3PGÓQK´ŞØt~Sâª9kùaãÏ8õúò¾<)?j? Õ[{Ú±lrUüåÛŸ?ïH›„0që‚(t'È×Äë”Y?‰y$\ãX?0âBÀ¡ñ„P–Å÷í+Ü)$:©‘‘P2RA%Ö½ú.'‰m8ü)ËßáÒÄ*å:g…ˆ%a¨#>‰B ÜºK{×6\É[«û@±
YùY¢[…xœàó¯sèÒİn×&øä¦ÃwÜ¶7$Z=;8¤»Ô˜k~Ş¨²Ù~p[â^Ÿ~ã«!âŸkc¿Ø[U¤ÙH$æ-ğ–SèóÂì@F>¨§GË¸Œ.´‰?¸ÔÁ‘PmÑåæ£œÑ sÌ«îÉ°ó˜×9tŸıG´…g3ÆlĞg{MÛè¬«şüNÜ–Hc±‡È¥Ii¬p!ˆi(Âú´É†M	ªÎ‹…Ç*˜3ü5DõÜ7Z- I—;
Û_Ğ'Z\Û²°ÚD t5€!&StX¯†‚îqï5å¶†GŞ4Ş‰¦"mÌÙÁL ÊÓ?îP°ÃçJ7[»“íœmú¯¥Ím9z¼%·İD<Çš$>ÛxîR)ùßP7
_9!›·m¯Êİ#æÂ("F…¬x»åÎ†ÃTğfL©Ê Ÿ»7ã;yR(mºè´mÕ¹µ—=«)µ´M|¦şÃ6Ñ˜Õ5€äÏngıÖ?A5B9tÉZª£™¨ÛmÊ¡%ø%E=¼\?ˆÈH›R®s¾LŸ¹³ô}½ç]ÿyÃ¤ÓÅ™0¢±¢Qmî'üÿĞ0-Ø$G9	¡»‡Ö[zUA Vy\ùY3/óÍS‘BÅx#zÓªÁ]n®StC<5ÚË>÷#Š§ŸBOÛëìÁZÙf›%¾ãÓ7-gìÙÉÂ\¶éK»kòé¥)ªgslÔ³'¡—²–ÍÏ1³äã—‚3ûª^/ü§K£ú_a³ª<!` .âŠ{BõÂ-(›DóXt¸Û(x#W ÕwbcYH¤ÚÂ£+#ÖÙ»ã:²çl“÷}¯è™;‰¬Àƒ¢†qğšÅáÿVğ
yü¤c)ó~ÄcĞ¢Â0j*60{Oèwñ ×É;à¤@*¿Cş;?ëÔï‹t’35¿;Ô¹¢¤ìĞWúe>OïØxŞ:»ùá§8")½™÷ş?$$³¾Ó51y’E«ÙÌ‹ëNiœ",k$½üêWË™!¸ıÊ;ç $ŞmëŠG®I»¶®D¶¡¾ıí	»’Š`lë€æÅ3˜\@8‰ÎèHğXzÌz8îS&éÎ{º"¾Šl9ã¿™ÊĞ¾á$î)Ÿ5-õ•MÚ+V†/z*Ûô<m:d’Ïµté| TÛ³z1b_ßšøYG‰èğ7\sBÂ´ÎÎò·ß±«=‘‡©f'/´i¯—¢êÆ¡¤äW³/¶òDkÑlŸëéÕŞÌñ›’=õ¯çoƒißğKs8±ßËùÜ‡hNÚÌtËÉóv€fhš™DÍºÜ3`¾ëK(ıÉés€,7pñIZš8ò W["VùókFnöô	¿ÀÒÌ:rãjQIe9[Ó.LO*ge<V×óŸò›ıFì¸âëSÅĞwÃF¬²Æ!vøGÜÅ÷†Ä©²o©fqkWQ­í-V?3®¨™…Ğ·n¨òãqeFÇúÇÍZ|§èæş·¯’X-[ë#tÑ)Jü¿åxŠ J"•vZ×€+{øºÿ	İ5QÂlé°/ãÛVÕgİŒæ¼´/=wîRCRç‚:íØ÷+zİ¢[-ÌYw´œû$YÇ© ùÌøû°«†±.Ÿ—+°_MÉ%vÌx¸¥ozÔquÄÃ@ı@€1Æe>12†kü6´0ûĞÇ7ğj„äìà"ºQ‘…à“ä¦ÀWñÚxÒı"‡K,æd?,®ué9©‡¿Ì½gmyûÃsæ"kNDFerãWî‚máq*Ï>Ü±|nPÄm‘\²î¬¦Æ"ñe·ö<™’Ôn¼ìO›¬™ªœŠÕ[7çµ·—’b‰MÍáB“5Æ¹MK†Ïù%£%¹ŒÅ7½êµÀêI?<ñ'RÏöe:ñÍõ/Étt_‚±Ì …‘ÙšµÒÕ‚;ã.õÃÕ`mí^£É»JyŸÌ—äXPŠÈæõ‰Ø~ô~Ïß:åFea ¥'¤µ×m„a³ê,”9÷üŠ°ÚÈÍ@r„ü2
Ó„ÒI7V@¡ú‘¾×Â&xhz¦gNŠ¾	0iÀãVms|!tŠ+å‰°„³x“vêÒ\ƒ“bŒ{‘ÒAv) )`•!4ïı•Á[ÖâX&6ùº…¦uŒ»kAáëMğòv´È38gŒ’<ùàt°~…‹SLSÖzŸUÈkí7Òz‡n*ê`LC¿F&Í?J)§è|;Ö•Ğæ7Hêâ8iÛ'D†xP‡òYaÌ2ÓÅÖ_vWa8Ÿ!¿¦d0ÈOi¸£›zs":ùE%N‰#Ä…s‰?Ğï{Ÿ›Y›©8¿)[ƒ2uº5‘ï;*‹84å÷Ãğ‰ïàf«Ïk;Ûk¸ŸœÑ•[+V*íÃiÓËâGÏê6BÏk&Ğº`zA˜¢\8‚~\ëæÆ-fÆâÙ©TêÒKÓ®7—‚ƒë0DR~3Fy÷Ô¢LÕHVÁÓLº"Ay‰eË™¤¨—Š~Á–¤7ºU[³,BM'SíÎ²™ğ R¯»ğSw®ZX<qXÙ$¹.µô $K,óª;‘<er†&:jâoñ!Õ6J!˜qµ†I¢È”ªZR«ÿ–¼›gô=tWMOrîcÑ1Şó¦º}»@ãg4‘Ôäè` éív|€†·Ó3{ûi™14ÔÆ>¼şæ·F--,ĞßÜ«(õÍhØ£ŸÓ öùXîm~â½œ´”â^?Ÿ& Ş)å„K.ÇM‚¹®	Â²¢kI–·ü†õ½Èwº›t),‹håfB8yimòÃßpÂĞ}Ïœ}Ûº
ã•”oEÖó>°0jyËõ5ˆ²ÆDÙ´4ÌŸ	ÅŒ&–öÒ±%À:5¼İQJÎîÅC	_Ë,Úô-qŠlN0¦¦ûRíY*:Qd¶k-Ğ|×än~ÛÔ[; KhªWğÅ¿¹vP2ü¹7wÒ‚åJFUÒàf¶†÷	~dß¤é6Ä ù“be 5âİg%	M
Æ¬´®¾ÊÌ_úhü[ˆ×TÁıv`ê<pápŒÙœ­­šÙØ¿‰vÂ×Î:²Bq´T;3ĞlPéÛÓ€µA>Æò6´*@;&‡&¶Ì¦‹¥€<O¯ –e˜³yí6øÛCgİ?µ©æıù|Â—S¸œKL³aŞxuæ‘0h<Ğ{ãQcôËñ¾SêˆÂn2¦	Ls²Sı‡æ³Ã@æd§¾Ï÷¸Ò½Ğ‰W¢À-áI`®éòE¬=ÁkLëæ2=í•¹hGB?D×K&~—÷71nÙQ¹º°ó¼¨ûe ^Ïëu¸O[o9}'&]2«wJIô¿iö¾zòEóT§l?ß—õZºbM½ûUÌË™@ˆGœ^Ğ–T(üıˆE•T7»ú¡·ÎVàóÀÍ¢TúÑQh7d4$ù‹UETD,Â4Bè>’,f£ëáØDĞEh8•İÁıo»DØù±Î065Å»ª´a×’ô‰ÍİcˆdsusMÎfÜØ-Sãú,BF%<Sï÷N:
89/_ŸÎB4 ,e~{|Iº’}E¬0w³81AİË«pş»SFW¹Z$Ğ÷z\bODY{ˆåÔ8s½ŸˆÁêªs"ÒW„1![H“ãrÄ¶c1y¾8oÇó
P?S s#R|LßöÎ‹ê®×úcç›‰†3‚c¼Âsë$zÛQÃ[ 1z€vÂiñ#TäQÔkÂ“L'(¥{n‰zı£ç:¬«ı¾küâÌn—A ®ãB–x²¨nÓÜEÍ{‹8'cJ3HÌúÜ}Å);Ó}óÎÜ<Öˆâè€gO_p’R­fm6¢­!áÈ:•Kñ–O™¼ô¬èãˆ)3XFŞè¿ãA Ş8årŸÁ
IÎ§¸?z·[;½ª¼1Iø şë*‰_ú6fƒœ03HŠ—pAŠ‡íâÕ•µTàÛĞ Õ%2éâ\9hãÔqôA©ƒÓç/çşd¤©ÆNË8uš¤‘÷6Ãƒñ„ÂÉÍ"­"ÇS]º£Ç‰f`®w‹ePE¾K`*wœ»Ô[7.Ç|N"zf!‡!F¼ã~á|CbsNãşsüTWacÚ„±D‘›+9Y’öÜ“Íhf_YÊF"pZğjøBæÚİ2„Éª•G±¬ğ‹óË¨¸ÜØHˆTä2;îá8ÏÁPï£¸æqƒİq¹ÃäŠâ¼ufÏÌsäÚ+›™’Àkàè`vA¸íQÆÇI2,4"ÇÚT×ëåÙîCL—×»é•Âgêl@tßÍÓùï´²“°ÙÊC¸ö²ùĞ§!Hœ±"v%MÌÙ¨úÁè3öÆò„×_Ñï\Fïiö•‰qãĞR®©¡j]›*<Çû'Œ®
D^PgÃO
sÁX+q,¬s_Ôz.hß©Æ*yHÂı÷Z	T[ê"§Fs)í}ªÏQ†°çáT‡ßš¾}*l^!º4²·5›äEÈ‚~¢u^w&,è_zÚ)©Ì¬Âà™$&!o‰ãx5¥ÛLğ U‚Õ¹…¡Í°ı´^şDEœ­\=hÑæì?nm*àáò§ïl+pï÷‡éÁ8k3} éªŠÔzşˆx…šJ‹!r{|˜úvYÜ?’äÿkX5Ò7wXı„õ³x
“Šè ŒRÈkÕ_^%ş–èÓe¢ø.Z
ã®wÜî«˜£»×ÓĞJqÕ†G#;>Èv_}ˆ£»­‰f¨x ³?È58,Pí©©û„~[·{Y¯Úœ%aÔĞbL®»á<İNÎ“œ³
¦Lšƒ=ƒŒj•ÑsE2­©²¤¹ù¥Vh€Œ§rfjX*ò³|¶ÂmaSèÌÿè	ŸöWÜOæ+,8"²†bÑ«…Mèd|lÊ¯ù¢n±»Şo0eruÛó#Â/~#ğ/ß•şôÏªâ
ÓójÛ€¾Î^»ä3j74˜…ôĞ÷îŒ§Ã¥	ldîVõ-’áÑğµ&ª,.Ş0Û8ngN¯¨s4§Šnæş¸í\+ÀJT¬ÌrfFí;HòŒwó±Bìz÷ß›Ïÿ84¹{Üi­v^Kï˜ôY%°è›MƒGš]Ë®Ø"İ|‰ vß¯t(­ HMò!A¡G çËt&ŠZã®mV>»'UúL%7 u s‹¡ğjÊ—çL[“‘aöé+i\ñ¹¡v[Uƒ"Åâñ¡ËûG§Lú~à¦c*_]e„ñ­ÿÒøórÌoúñH1;+K—İ?ÏŒCFV<Ğ‚ˆ&¹¥zúNş«[Ê‘¦êaÒªb»Ï‡.´Ç÷ctjô
_¿Ó¸¬ËÂïÕîş,Éo¦>ôN?×$Y1ãÌ¶‚Q3ì(sBÀ.C^®T7ûÁ’‹(cÙãU˜$³ÛefM¶Y_„Y_¶ºñ† |>!ÍâxÈ®V¦Q¿fŒæ¥ï‹—ºQ¨RE«ËlQ hæ® n7}‚kÙï-KµkÔŸá«6Xû®¿*ûÙºYâˆt]¦*>gÍá”ÈÅ<ŒT‘lò\£ÇÖa_¬^²˜ºvÔLm«6Í"è/2×^ƒ-ıİe¸ãTTv!@wåòÈºæÊéÜ@mÚ%IÕ4BXµº¾Uú{³qùÇJÈ¾ÎŸÇ•„	ş2zş½§ıÓ”lÊ¥Å¥`ı„GG:&lIÇî¸ĞPdÌÆˆ G5û06¤õïC¬é(¤‹˜a„³y)ê'&~TãŸ¨½Uß€f•It"c_SËÎõ£†6¨ºÍ>}#ËNmÍ_PöYª¯X/ ÄÕ»#rÜqEÊéï¢–wÊÈº{ÕÒğO÷ØXí!]j&ùÖ”ybÅÂLú¶ÑOñ£D×'bõœ¹½+]W1~ip=Cw#	Œ%, şwæËõ|M…âŸÉÑgBÒWpWÉ[»ğ>#Î¸cÊd-*1à]S¯¯>˜äğ¤Œ|kAçÑ	0 n|‰–§µ~1¿¤•L/Ia”-Ë«Ş‘°2;:2’f
»Ø:é¯J¬ı`I§	¸âÚÈ	İÅ€ÀÏìœª¿Ÿ¿%›Æ~Dojñ_ÏHEÁ™“¢*ë·œ.İÖ°»t62ÈÌÿÌ–HCôÉˆšjz#«·hÅè–QU‡)„ûvïcØh—ôıÖó¿ªó‹ÌF{÷`æúOÆWVLw"Õ9¾ĞRû~)IÙW`1êCBœ¦9Òqşá%É®Òƒ°ëªò CS³ç9Ud—ü{È:U†Îš¨ °àä¯ïaş%ˆfƒZ @–e5Uua&èrñ’­p\JİÙYrB§ 7à$^¨-Ó2†yx=Ò“€¦ñÉ\¿IGªÌ@½D]¨dM14ÎşßPQğ;É›ÎÚµ1.Y&Mwşp@5kó‰áÄ\9Î‰ şTBº/íŒ•gHg]÷a~ skÉD'T„Å6ùh‹Ä™‰Çñ2¹Kˆ‘'7Ê…êo×Ì€^ƒŞpkmG/ñ”›$ĞËDÔÛ@‹*zw,Yì
·Vå˜ÕÅcõÇ.ióm:ĞŞOL~L>;7j»Èg[7ûèºŸûMr£C6uGV=ç±(epuBÓÅ]¿X&áWS0¶˜ofÄc¯ƒ<œÛ%hÇÚ«,{F!s'r²WÓ(ïw:Åíûn~ÈÚ¥š…º3½xôGf‚0y™B¹?£¨o«\Œû¢!eé'bstóºd<;½ucô—-Á¢¬±³Ãjå9Ákò%
æU*Î›Öüı¹˜QyÀ…×)É’(hS+r[°lFXÙ{x&än´L¦·æ¾Zãu‡xº_¡|ù+ha=¶@õä4IÄ³CÁ©xê]¨´¢Z[ÌK÷°(x–§JÙ‚ùFõÚU ]CyùVT‰–z	q$•\IÄCé½§Ş%jCËËñ€!½Ò£DŒ/Yo(Ö™ãNeÅ&vÜ¡±¶¥ÛğŸñÂÃÊ ¹è€aÛ
•ø!ŒnºL¶ˆ¢¥skÍWKC[|îvV	Õ‡Œø™Ü˜XMÚnğ&^Øa·—;¥´+ÙACÙKnÿà'7L“É­ô|¬{¶Œô¿‹kFL+‹S[œ7]ó`yEúEcõî÷Ë—Oå
¥³¢şFø"û0yJ"Yï'Ä^#Âş–¼Ğ¿µÃ/FVtµ@“ƒz’K{\/{•J{©xNMš•Í›q¦‘UExôİ¸X¦‘â&­œ%{™ZG{¶à)M’A©ìŒUµQ¤K¿#WÆm1²dÜ^ogcÒ†!wgß­4ÍA`µòñvu’ !QüË¤q[*W>GD*É	¿8¯(àw:³YnŸ@7¸î•¼swö®œI²3Šsıéoœ{=œä+º%–t¦,fcÌ C…YõœqtòùuÒ³,—å¯‡&)Çu.GCšÚè¼åÆ^RÁ6½½j:_g´0Õ©Ù	]çšIPøÏC¬CÍµàÆâ;:{>:<ùeôŒÀÑ²(¥Ú4‚2!Ò¨ï PvLªhsbû?]#Š6êX%Î~3P¦òû‘ZjÜx“µiúRg·--waù¯æoÿ0÷Œû
ã-‹Yû¸Nê’íB:ÓS~Mƒ–°<¿i•ªÜ .¹¾”Í¡õ¢uÕ¾ß19&ig2UÄéæÄòúVÃ=WÈİxfÁ^Ä/H«¨³´›¤(:ûÓæ¹{/Â²²KcØÏ0EÜ{ğ¨$áìa™	åXK]ü3¤ïp®WUùï¸»‰±jª"õ,Í†*·z6îôÅ%Dº,#Ò€yvœ…‚å®³IgÏÀIà° T`“Ü¾Z²ÙĞczáÉ‘JIÉ&b†°ÁE,	uy5[/~$’’[@s†¶+¬^¥p>3š¾#/[c_k›	a³€»¦².ô):Ë&À8‹ãÜ™±sqË»íõnó“EÔ¬½®ßò€–¯-’®
¹bUqˆ¯®É+—z/Z§º:A–ja^ˆóÍ³=¿,WPlƒÕË4* ˆ ˜æxkôôa2qôdyÜÑ¿šPø¥wŞ4g¦¡,s¶bÛPâÕG/uG‡¯„×r¾Oêï G¹úm»;‹t)Œ8¼FµÓ\pRâîÒ+l¢à:´«±B]=æ¹÷2¡ßS9©ÖUF¸Ñâü#©Õ5ùhğ¹'@Qİ¥
}‡
˜›Vl’ÕèÃœiö{8êuŒ&¡`Ş¬CÜÂÍF[5³Ö¨;Ç­l4vwO÷È¤äş|3¸² öXğö.¬zµô5U™p3xqdï<jç¡mF¦)BØy9ë2±'Ifˆj¢AÏbp’úÀ^ó#ytÇñ¯’hÒ‹2'bõ'ÿÜÙtø®Ğ¬:ƒÄU$®9Ùêx"XÙ‹Ôz(Éú~\ªšF`ÚÌs¿şÖ†Å•ÆõãÆï q3 Z>İ„£e‰Ÿõ-r^NÆ”ïÙO]”iı£Ë¼lWœ]wèÊ@¨n/Ûõ€Š²8©Rò¬H?(»ş¥¦ÉşnMC¶ª;Ã¬TÒÆˆÈ
&éX@Á˜Xš’ğ{j?
C–7³'àâ^ENĞ¬¨óè>p*–úÜŒ6À°šg€J!\é$œÛåM~LÌyté£Ğ]XĞ,èd9TÁÇ{ÙqŒØŒ|ê{•/¬¶”úaÛ â9Pğë*8€¨Ä1´¦X­2È |Põ¦š)üT '—å+0ş©`§ÿ F†_°ÀÃf^å«.oUnt4=*àWŸŠ®îÛ°ÆwBÇ±•JÒªAÊ‹v¸‰N?0GÓ#!ÒËŸâ$!3¸ñg¥œöÊ)[V[ ëPåy¥ŒS@Eõ832ë7Q“¦"b„¬á€Ê#ÔqBl²:¢¿[+Ş˜‹÷2O§ÖcØI×n‡M0Ÿ&³æR–f‰È\×ìR¡î¥0dßøúşHµ bGR9j`Ê%2;¦_éÁG“tª£´/“ßg™FiF-ŒHÂİÕ¹»ƒd’Tû_æN¯¦E	{¬]ñŸ"ÃBâç}ªş£„y+<1ğmÔ#Û¥1²¼ò=kxÕÃäyŒØ{á ÄÑDnmï8pË%§?+ ß¥Pp‡ÉÏmª”1gqj.i¤ÑÃ)"páEm}¯SĞğ]‚ ÌFÆ<Åñ¾[¶ •‰=W¥ÄèÖ 6<™Ö?Æ]bEg—·¶ˆÔÖ÷fÔÿ,µ¥`K æCÇ`	;ƒ³#Y*¬Øß\µÌ«û3,ˆÃ1öÉà‹ Y›–àØdš’V£ĞÉDb‰#ØŒ€üsÀ>Zf}wWUwC[Â¢ÎM~ZÊ–Š-„ûÚáÖI˜>{3¦“fM­‰¢&µò"Ğ½ŸÖŠ ¼b«,ı¸²ıô7°8‰¹¬5\}Xâ„›õ±ìÈ~`ù–¾,?_<ÿ›ª$'
B¦\oßÒôZíhq’"$ƒ¸æcG¸íî‰Üè3#¬…Î¼¬çŞ~fÙÁY_Oÿ(…²´J"ì/ŠoÏ¡”ZãYextÛçÛ™€£-Q=hÌ‚ã»• ¯’FîUy­‡q°]Êç½rÿÎX9¯ÛÈd¿ŞušdTb'$¾2‚QRÀE“0u| Şé1"ÒeT z/U)°=—Œµvğú(œ»ı•;pL÷u$à-:¹[…X¦À\„©6FG0ôä@AÂ±*¢më\d zu—ç/Ä#¢çp ì˜àóEµSÖR	gUî¶wâo"t¿Ìô‹\RmçÂõôŸ!z×inmÈq%¥w‹pİj& şçc˜ĞWSœ™SG¨ uÛSğ¢×~ÿÈVŒ7ÍD°=•[Äõ÷©³êğö­îôD¸È®Ãtpø™¢ç›~V‘÷öÍi®9ªjHŒßg»ˆÚ–Ê|‚õê½6é¯O Ş¼üuëHt‰¬ß+ÜĞÓÒŸCèì€>$­!ÍõäÄoçr?Š¿Rê1VtB\°şÔ“œùH“É:Å÷ÀEÑ²ìÂ#¸D¯ñÒñˆ» ¾IÇ©Æc¥-q‘‘Y	™‚«öÃzîø¡­ÏG2@«üéSâ¶N4W…{×¸ Fõsv­€qIß	RE`üA£Ø÷ıqĞlrü§·o
rÆIïå>Æ0¦ÕIS~ùòÕÿÔšWQÍ9ˆo'¨Jôtİñ@„™“`ÙŠ†`sÕÃé§–´ÛöaÛs|ú3µæUy-œCúã"Ë¡0fİJGÜ…râğVn×ã E	¨yÏ©V¡ĞK£tŸW[¸Dú	ñEKùHv4¥U:J{4n=89ê
Ñ¿ïc&Òä»`%¾ÃŒù:Äß|9G£@ O=ç^pµ,¨üL&Èz²˜T^ÉŞ
‘n(ÉµÒŠ¤êiø‹m,,‡Ì.}¼ÿ®ıIª›ş«\wïO]9ÈLUJÌËÅ4»0<êídºñ.=a} Oæ‹sâkß—Î ¶gX™áxçâç+SürM(¹Ï‹•3NîÛ”œØ;èçß¼àHŒKáë°²Iöô i¯Ü¯³”W.,9Şæ¼k$Å`FÆ¡¤ìŒ°	æ	B“Ù“ÉÖœÌâĞx¼‡şì#S„ È;iEI3él:jšP»cÀúLN\ëÄèšFîa†ÆÙ…§6°J8v‹$Ş§âêJËú Ú,nÌõÑWø¿÷øÜÛüX•õ;çAØ&Ï‰©ÿ‚—ÍŞr8Ã›”Zh¤’ÛUxVÚùLyù'•­¼köª!×ÌBNr:ü1!Rq.¨,@c“‘z"»>ËMFä}i?€©7.^w“¾û>ğ©å„ûÀTxóT6ÃÃ¿S<@°8˜!‹sGÔëWJiÕsq‡œ†ÛGµWw•Ï±¹1™|j“Ÿ/¿ 8?,èpªÙX{\™<¤Õ:›¾k’..(Jæz¢ÜIĞFrÚæè3Aîee«©aïˆäêJU%°.ìKÂæÿ ÄÖ K+ŒÉ—}$	Cw=W…øA/$‚Ä|)‚%´†EyÜ‚ÏÂ¸QQ©”XcÑşÍmp+½OÊ7È£EñVUÛ-eÙl‰£×¸«àa§”Äi›ÜMâ}ZHEëÖfùƒÏïIMlëBzÛK–0+íÑ§qì]0Íóï     eöR_ƒ–±ÿ İÆ€š¸³-±Ägû    YZ