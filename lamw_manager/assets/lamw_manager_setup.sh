#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3598596336"
MD5="f631c29f6475274f3014f5e5be038888"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="24928"
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
	echo Uncompressed size: 180 KB
	echo Compression: xz
	echo Date of packaging: Mon Nov 15 05:49:20 -03 2021
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
	echo OLDUSIZE=180
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
	MS_Printf "About to extract 180 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 180; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (180 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáßÿa ] ¼}•À1Dd]‡Á›PætİFÎP¬aõûAƒò ±ÃPZÈïtŸñ@:*bLÁGÕœš}&SXèóP(è},ã°æR}Ğ	ÍN!e%(zAÉ%ûíB›3†µ!°§iÄá#êdÒ¢»•³’Õ°ïÎ°Ì½ŒzdÀí/-RyÂ•åØ{/]#hµ.ÆÆß¾×wNø% )ûõ}€#|slÛånÂM)†Æ~¦”ô[ø'N6’¸iO8(r…şºï0V3‡Y$cîAÛÅtTƒx‹•Qj]š”*ó‡5KèeŠ°¾ÃÌsÃÌ0‹¬ÁSœ`<HÚ¸€ACÕ1ıŞ9Åí_Š¼—$‡´wY‡sƒ.©œãÑib
·•A»°ÇÁ\±±6+«–{uMˆnn½‹n—øbo´.©|¦êv¤´h:jU›äæA¿rÛ=ŞäZ'Üß8ÛŒzN“Ä~;8ş…óÆ<]æ	ä¤k„]¦)
÷Lå ÍşÄ  fï€+møy(=€Ô€è°´¢¶çiÄVÙ‹-¯YèØNDD`P7V„.à30¼ÖIƒ“^ÎX–4¹ß» Cô)Ç:ãÂšN²Ø¸eOÿe
Mò?}/I´²0FÆÜdlš¨kX-bB'v|šÁÙegá¬åöx&Ş*#EqÍ®MÛ‡y‰÷:J…ãÏH/k+8±ÕP±ÅËµ¥A¤Ò8LÆìÌ€Ö¥¤î—õ ø
ÛöÃkBpL¬úQ«j®‰u%2 pDnéf¦`Ao9¹Q¤çu@­²Øäs)Êælºrìå*à†Yğvåmb•{¥º ¸‚Y/1Ú6'îŞQêæ&îm¬¹C$Ü¼¾¶ÇZŸkŸ\¹Ëëqğ^­£5’hq_ıWÅˆ/VX£'R±Äİ'Ë¥õ{Fâ“ï¦hÍ4ôÅÁ
Z>{•´Ï«7&$E‡‰X(ë¦­æ–”rˆ[®‚#$¢8Î…Ÿš8á‹P„r°ò)ÆåO!ÔÆ”—[L|†>¤§!æC‚İ;ÊíX?ŠgN½!Ñ”¼j{Æ<*XOºÑá=©Ü‘Ë¿Û¡¥¨X*»,¢V²ÍĞJŸ)d:)ºI¼÷°ûy¥:XÜof%ªi@»˜ö›…‹$ÙÊşÒÛNn‚¨4,‘Üú`#FÙ~Îiƒ¨ÔíºãA.ªæò‚{º—F¦ªùyï7yNÚâR›#eş'ºR3çdöÄVS¢"­Ş{OÃ‡TYù£p›,œW9Š™hæÑ¸ŸùLB»‰yƒÀ¢œ“28à—ë2†Æó’8{Ú‡ô¬Ö c® Íåæ® ŸïâØ.vî•·‚74)Ea_[‚›Jãø»€š9şŸõæ/:aµÍÉŠ¶ô¥q´X`‚+š^5õÙîÌ$Şø-Œôäµñ—P¸ÇşD|b:3ñÏ ÚSL‰Â€¥÷¤|˜M©J	b‡–Œ8Mn¯¾& ê³=„óˆ?Ôri°j“ãå	‚ÿ†é’ 3!nğƒU#	ÊË)”ˆ¾ğˆz“Ò=fyØC|‚{È¾“4h’8áµğ7èãNN!åpÆíwé,à•wÿF8€HµÆê}‘kJÖfö#ø°—`IÁg”¦5è4KÔœSŞOmŒAÎw-ªÁT¼/ãIšÂq-Wæ¡d˜§3¬üí@êE†,Âãèë_›$q¬«1c®¶ÿ³+
|¡}»J_9í¤nÊ„£ê)<S®)Í	îó}}¸ÿÌğÛ û€¨Ğ~ê°„|yŠE:—£Ô6“‹•Î¦Tå Œ o0
sI9Lld§2œÒ&ÒBt8ï¶EïÎ ¾€•âdm½1±ç†Îc©n{É'H°¬˜X(ZïÍLZÉ&pCèDº2_;ÆDâ3l­C¨à5Ò§õñJ²ñåÿ¤…·†Úšè¾¸6»¾$,C¯ÄûL2éÕus¨¸¹†¿dùºsqÜÑØs
@Ì‰ê»-óÊ\‘ce¼˜¹•³uh1°@fGKŞ·R£p»•ìqC©0‹êF¦åŒCß	+Õãª¥ù/n·m\ÉZt9œí¸EóNnû0ò FÅTŒ—4¥Ğíªäï”†[ã5–¢±à»–/æ6Ñ4¶äPùZó¿åĞãjòôÂÿá¾Æ…ÍyŠµ¼¢ 8#U›·¼ØJÒ¹sÊ€ÓÏ+í$ÆÑGŠõ-c¾qT»1+„3Zykş9VêñäÒêë1 2ºËU¦¶ÁZÕZŒ³|RjDa Fö‹íR5¼Vÿ¤§»÷ÓTÇƒõÏ·ëº·Aåu^×T&•%¨®).Å’ä˜/=|ÅÁGs ç–Š{ÓÈ‡CjòÏäw=8fùèñ2ÏAZ¿‚Ë3Wç×³ĞÇœªFÿ™ËÃğ™ïÅÁªŠ%ãXÌDùÚÒjçÖâ3²™¡@yÔZFµù«¯ÍlÈÛ,-ÑKıÄkÑk%DR6PdqëòK¨‹°æ/74·³J9”‰uŒõ“/¤uòtœÉyŞJˆ4Ó#É2ïÒxèÅ¨ÿ†Š| üLáÁ€w¯³ƒß×Œ­(èQ‰ŞÔÚâŠ+gÖbj,
Šõ°ËY4ÁÀE;^hûŒĞviïÆXNzÿ®ù®5æ~§8pÁÊrÆ¨ê*UÍd¯º¥aş¢îFNlUÒ€[ˆÃ…x«Ø˜õZ=ë	¢Õ|œ6yøËyĞ“™},iŒ¾Â=Îµ„‹	’Ûp÷%
—ÂM‰İÈgMŒ+}á|Ûnâõ&ä¸Ö$
0ßªÅ3¡j ûåo²Vfõ	t¯ ”T{J0u,÷êË‡}C­!òß´)ØùÙF·—~ØOgº©Ï3­'p7·ØÃ)êwQqÃû÷i=…´"L>:¿ô¨™‚À
m›«pà+w×ÿX—©Ù½gİãâ
"ú
…:3ö¤*H1~”%B¯öú‡âf,¼Õ„ß-â`\ğmæp£FÌ9e˜o·”üj‰¼.Ìd'¾ÒÆ¯ø®(5¢-iåHkCœ)?{äëGS2FWnÂ½TGÊ{ÃyZÄÛïºÿÙ¯òPDˆŒˆ˜²Ú“‰1)“\_oVÛt=ŠB±¥¤O8¹äòjA#·•šròÇÇ‰0%+UA\}s®E¯Â Z;n¸ad~]+£ÓaL×‹ZD4vIûaŒø~…ZkİŒ|©¥-…œíê/Jbïq¹´ö¦óĞÙ{4Ò^†¹L
Ùøšy|H[¶wHeó>áR$ı`ëÓêFRâÍïD2à„R®PÂRœİ‰É-á"9`«hDBAY,Û*×÷-JmªûØÀËqÒ‚9‹ïW:r­¦—-Æjû	dÜLå·m´KF¿V7Cƒ
%˜I~­eÖu#Ç³9#4X—Ÿ)o#Ÿ§K¶‚jËşJ.
BtÁ¬8 1¸‰{|÷~ë	Ñ‚í€Asy€Ÿ9Êÿ½-J²â»@Š\]êcs^×ĞN„³¦uÂ9?Á»“  ªL¯æƒj”<¶¢Kõ»ë6s«õGı/´=áÎ÷ùİÅh›ÄwçPò»~"q$†©ÑÛE»rz„² ît±.ØJÁÒÜXğõ”úINuŠ¯ÒöP cÅ¿ b“dĞÄä e=Êççë.”e	yª0B2‚ùä´îí‚§Ğ¦“ÍÈÑTvü^6´ËâM"®€?5~
&WKé½{©8™9Ñ5Ì×è‹—‚»LseMg@Â)ùp}ª …`ÁÖÓ‡V#ç¿­ÌÏÃ\˜LA~ï×¿q@6ì‡øø›YÄôæû‹‰"½Gü*+D3LCÀ‡_$¤Äü=å ·lµ£7mƒˆëô\_¢pp§ì6gúeÁÒ>³F>¿Wà­]…ıÎ/£›¨'•jx8l4¯*Gí[vî7) {J~é-âg¾ykÀ«î©Rpùqvk·="8.<¼´àşn‰BEi(yzßø^GU¶é¼Şd‹qê¦p$“œ3†¦±[frº§¾İ•»šcg‰½8ºÙ”ñš
'Ä&pFvA	'ÒI–xO~ËK§§şåmËG”èhëéùtÒ¸«Yµìœ_Š®Y†>i¢¸P$‚ŠÚ†:m¢Ìşy€#Qõ¸Ğˆšî5°ôù×İ½¬ÛµÀ¿ûÁ¨8Éªúq¼Iá.ü,§GîKŸ°’8…¯GJ2´'p-“k.„eÁÀª§mCRxã…Q ‚ÏáÂÓB„à¼Ê	U;}Ù~kö~ƒG´Ü‹˜f•#¸¼Ò–²HÉí [\³zo‹Şd.”9 ï9…ô!_™¬´Âùüjw[ñÜàp¶š¬ZúÚ¨ şÜO_‰Tá-¹…æP`äÑÃqvÑ¥¹× ¨¤£ı_ôö:b1€‰!2ëÃ‘ªíó2É¢v\?Eèù˜O.DCµ­ñª¬åFáƒDæ$Ó‹,™õÔ\ñ_ù…ñ¶·f&BwÇvlBt³¯_SŞ4ÇáÌÃÅxİ8PÉ€â“øœ3üİ¥Ô–MŠ‡<ö‘M.*mzËÕEì7qYÓ<õf3~ªzÂ€h¨iæk:pÙXöD\,$‘6qERì_·]}<JĞ“LOtŒJ¡ğ`N–€|Dì´æP‹/**äa¤ô/e’Iæ­Ãd"=+{ÕÅî*/¯N#('ø«RM"£ZÙ¤şewªÏ%¢-Øı•«†7­>éäD”{êH×„óË¨¯µÅj3JQ¶ŸHÑŞƒÕ£áj¾µ)¨„…Aš-É.GBî^!Î×¬
l3Ç¾JI7¼íúfó%Á9Vä÷*®šÑ÷Và%Ô6tôÀ™&º§S^‰Úâ}M4Cm+^	åJhÂ–Ú¢˜"OÜÆ3Ö£|^:~K„Õ«ŞÕÈû@Ç~¡CUı”5ë/d,à­½!ñãÇi	>Ò|#æ-µĞ„¸Ş–šHV2¯U+Ğõ.Š·öÏdgÌƒIï<ĞtàjZ¡Î ÃXŠ
ZúR_éëlç„S9ŒØ
¿»Ëj¡ÒR‹ñ¢.é í"ìAEåq Á‚‰mÑAŸ(ÉxÈ!62à@j=X½˜Äto’›wm=]’Y‰=J£˜`æÉ’·ÀÑü)xO±HG¿[ïbÛc&|¨wP¼ß7ƒ„ ¤‹dçè·®º>äiçÆjØdpLr–¤1ı¸Å^%Ue¼ºìm mGe¢ÌìnÒâó8Æ\Ö^²¦íÍ›¯ÿÁ¶Ç­HóÔñŸjiŞÉj½ÙqD¾Sa¥M'CÁõàóu\ÙqgE“µzŒpÿıá_](b7ÄWíWÏóhAbğ_éçÊÂ÷Û~ñCõø­Kö—a_OÔÒ<X¼ù²¨ì‘—}³
ía	â¡CN¦»ä'ˆdÓ¬½”ùV®‡‚^÷ÕØgÍçç$‚P°‹ï§Sò¹1ë!°ëÎMYrøqœMR7³Nùáİ,Øë>[Ã=(:ˆÍ4÷øüõXT)¶·È^vÎ˜³J-(Ÿ¿İ×¶¨ÍµÕ×õ}ÚR™ı)Ş4ÀÄJÔTQ³õ1ê§ú‹Û04}iª¨ÂUÖEÖ¤ğ#—X;éö?c+ÀèÓ›bÅ¢pj6İ|­¢ÓT*¡15¯4~ÉÚËı4é1ÖøÚÃz(èí>!‘»Ä?Â£Ğ“‰3‰‰Ã´)—ù„è‚ø¨$Î\>IÏSV²2”Û!éu‘­Ô¸‘¾7dO QmÒA~×ëƒ9æ@ø£7@7T¶óƒ‡ä-~ĞÃP9mdó*’B£ı ®¢‘æU•jûš5î²Hƒùöù(Œ4¯Ä)‹
¶Ô	ãJãa.c¿:}å!wÚƒ¸K’`[ŞBMÆÏ`ÍÎlÚíY£Ï¡Q
ÖF'Îµ>N»LÆf~†ÿ­I9¯äjlzsñum O@%-»÷~º‡‡hèwÔçì‘li«À‡ÛrÉ ÿ:”±÷M›ÏæQ‰†ÀäfÂ¾@9Ø¨h»Ô_©Bwø‘‹8Á€_¯P0½<	¥â Ö	Ø¶vöuÉ’8İ;xí~¾
…÷Ú})Nok’Ü\¦Rçf¨JúNÜµ|LwîÉ#ü¾(µ¤+@+Å[YpôT¹¹f«R¬ÿ®D†Kş,¤“ü=¦}%´ÈÑk¨ç?ŞÍ¸]|,Fåÿİy£Øÿ[äÿ¯6ï|İ½J¢j0EóÜ‰(¶R&Ÿ|é»ªĞñ¤-+Ï3_e]».—Z8XÅÈUö©l|ƒfª]B~ÉqæŒøj¼¢RÉ¼OvCÍ¿†ã3Wş£U
8–TÄLŸM¿ğøg„FÓ7c.™òƒî’ÂÒŒ–¬THZ›q”g@¦uØ Äwçİr5˜z±™[eEGÂİË6±×»øÂ»¯à·0˜œ‡üüÓ´Åï2=Wiw	K|BıKÿ	„°´Ñ÷ì¢Ş!×”îKëÕ/l>eå©Uæfåò	ğé_C­¢d°üäUé,²’šÖ|ó,¾ß"¦Ğ¬StdÂb)_İá+àú÷”[Fğ\UEõÂPZûäéÈ  õ‡<šš@ËKïÊû‘ò–M0ƒ,ªäI öpSé<Lìœ=!ªËOk©VÛü“F9Ò#ê=Y¼ó.ˆ©Vãä;IÏñœ>ö[î8sÊ­ĞŠ4×ƒ=Q«fáb­
êî+uë¨Úú¯­,g9ÚluÎûVçg7îÖÖû1ˆœ|Z0J™ÜC }V~Qª|×z)äQ)$Î¤_>~x°&Âá‘°¢>D…Ñ#;°{W‘ùz³woRŠ¿ »¡¯G	…1#+õq¬+¥’=ÀÀ;ı•g“Ú[!ã4=‘e¿>ĞÒ'ÙÂ…"#*ïG%ˆ% ‚<X›§Tˆ¦äŒLˆ™úçáŒûã´=3â2®äü>2Ã|ÂíÌ­h™jsŠ2ºL¬vyÏWsàC¬)Ç¢—#›t}™í4n&„5ô£cgw[ñ-êºdúKq—z—&@E/÷BbOWyh‰`I¶øK¬±ğÌÂñ²sİt¥¿µ?l/©Çéiü¹÷İâD‰Üíüãæ ö¦?Xª÷:ıİª ²z±ıi–¥æˆ@ˆ{ ”-SYÁ{N+*³Càõ3„ày–6Õ‰§+p­j_Me·ˆÖ´¡æŸ>Ş=Å©âÈ)jıQQ›ôy3—„\'>‹¥W'XÅ†şÄ|äqLßìºEÄ)¦1pÂñ[ÏÆEMÒ—º„ŒR4%4+H³VÅÕ”¶ì¦QXŠû§nşEW&ˆm?]`hXv‡¸`e±»SiWnsØ;Î1
/.\l5t©HÍYj˜ù÷¹¸»šqe&Fàx¦¨ÚtšoŒÓR¿¡yã£¤šCHD$™ŠÈ§½;D‹§#ì¡}Ã9ÍCşFÎ{Ç~J;‘_ßõ¢¹êÊ´¡WŒa¸ºOSKÌáÁ¢É@É¬ÖŠE¼R† ‰ü»@¬‡İ<Zê,à2ğ^«»cRPèä…ÿ(óIÏ\Œ¬’†<æÒı•ÊºU‡B Ì™
Z´¦õ;“qö‰ğfë›Ó“ŠÅíáËİÖĞ2±HÔ™Üš®õ9ŞV®Ü ëÜÙ±KFtIi»{d\š™/ÀÂ²X-š¸u³œíÈ§.–Ñ[f[IQ:E2êë+p$ÛOI	tñïP²I|œñnS¨ƒ5Ñêók§Óvl4RC,ÚCµAÄ–¾ı*ôÖ;>o-€·^±Å§Ë®^ølTèy`lìÑÀl‡DÊ»‡ÚÚéïÿŒ;Ô×•@IŸÓ¢©‹mík©_\‘í áj¯¯ËÈ½¬âXÜ>Ûì…I8ê¶ñØ´¶ÿ¢ÍX|ğV¿¢Sz6ÚT)¾XÍ÷ÛL_8¶=ïè?ûS÷ÎCfq¸ºTúz1ûy;1=âxr’‘·­p˜¯Åãâ&,Ì5¦—¤ucFĞßi;ôœ2EL ¶Ú@Æ¼´@°¼kBw·óÈ/	ÓOh:H|ÚÛ8½÷i¦2§ãØTèğûxY.tkõš¿ÃZ'0?Òxâ~“ıƒBòÃCÖT™â¼ğ$wq¨Õ0âÍPÄ½NâBUÀi°úÀb¼ŠA[  Á¾\nTIü›ğ:)»ÖyÜÕ->ËÆ|ŸğÆ<„Fi¼øëx²¿gV=ÎªeëÙ`->âÃÌO QÍKkC{ÿ—õÔ'Wfáöãá˜IƒmšAº¸¨9ïêêË„ûÜò²_`!(-YÇpXª-‹ªV Ù3òV»y=ˆŠÏO÷¤ÎÔÆßÇça§Xkİ"m-àTA«;ØhK6|÷ÓÚ’é³ÒkÙ:©\&ä*"ÑùA½óZŞ©k¯4™`ÍŒ\ÜÊÖ’Ê'ö¸vŞéÎeñz:P‚£8Dóbä¯§s› Ba;)`‚	ˆNHvæºält´¥Æ­úšèÆä¶Yîcqöv“„o»¢6ıM+}v‹ët1ÑD(Ëeœ•”^^Km£º&¢Äsï|IĞMt7ØNíÊ®·}ŠíóŠPhÖ_ò¶Ÿõ3ÍßUß.JXòïzƒw¦E‹¡.µ]ˆ
IrzÉuWÔDÒU!9 €hTĞ»Ö»:›ãµv,­¾q
¼‚#bÛOTjÀ	á|WÚîk/³Ú¼JÜãENRRÆ£-xa¾’íÆ˜=Áw¡Rï´ğ8ys@5j2¾Â$y¸»*mY1ıT‰HÒ·‚±1fÙ=×p˜÷yNö‘Îüê·"*ãàTz í¯óó`”¾x	BÎ	Ù»©LÏ ‹’©.UP±ÔË=nÌŠ8Ôz½£'GdgïuÖá†ãğò,òû{\¼¤O|UÇ[~x`mçuXM÷{v5EÍğô~ÜjŒµ×|‚	9ØĞßøÌöÎ¹Úàƒ!‡ÃÂ°­!:›¢ß÷ª¾]İÄ–?Hª> ÒÜ`H–Û¦õã`æRaÑ1=Ú>Š§ğ{~j¹‚˜wÓ·¯§ù	8m±®¦¿-¯dètPXî*#³J:ŒHdºî!ú„IƒÂ‰%iAg[Y#§˜‚^q$|ChGìN¼¦èãÏ~poã®^ŒU¹»“éÅ4ºï¸š•°©9µ~)=,õÊâ<¨*áòF"5_†‰¦ffFåşJÁ¯ä@À~éØS,`[%¹ÔJ‹l<pòQÒâ†“]#iUNIôµ–ø!c‘i¯@ËbB§]ŒóÙWÑå<Üµé«úÊÅ™rÕ™KW¸Œif§Ï5ŸØÀkÈşŞCm'ld{Ë!O°\è,³YL*€ûàş;r]Á-É[{HÇ3wC™€LïdÇùĞÆ™ğºçâf¦_ÙV‰P¤†B 3‚µ·;—òR¥Êğ8ö*p…Ø·‡ô2§R¢%ÿI:Iã|úTôwkÛÚïèP·í`Îz\Ö&¶İ‹ˆ­e:¥¼ƒy	¨û–êÊCg({5”ñQÈÜH¤gÆTO+»ƒa%ªÕMima|Õù0‹#6pü‡”áê<Oˆ5 ¿Ku¼Ò^›ş-]îLÄü7êU::L“:<*úéOÄÁşÊÕÄ³†.,wjÇ ìB%­œO$Q¢ "ä–jÓï˜3a~‹A’|š~_…±›€ÏLÏæ)û„G/9‚ö\S¢º†´s®/RüK%.Kút¥åJı]rïpĞbã'ÊWüÂ\È|÷'¡H‚°eUê÷‚¾çKGc¦J?<jÄnÑãY¿¯|Œ5gKÖ–‡kƒ»¢F’+ÉH—áÑ/šÔÏëú} :Æİ{ :Ã(iÊ€Áˆñ
uöÀº&pÆö"` ¤Ÿ–Crª¨zü<S¿\#Vš	A;ïî‚dÚáÆ
V€xFãmg 6Ç§=²{dÿ„©‡wË áŠSQÛçr?Óhˆ«ŞøÏF±Aiq¦Oyæ³j+Á«{±áÎUæëRdk.ëkUìv5A¼¸DF% RUEOáéÁ
Ù‚'©[’í¤Ä^éÈç«NV U0
UĞÒq%CŞ]®!ÑNKÃ‡!ó+çtŠ²–ø.ƒÓPHŸœ¯Ò@]±j¤ıûSöåfÎÙ‹ı+àÌ|ÈY 7Äã‰sRn{ÿúg¶7Ät¨Èƒ»sâùQfX>÷IB@ÛŸ¸›Š˜ÀÔBÖ¼¬™mL~GùÀ¡/tyuv&Ù; 0?tÙÃ.”üG‹iÍÿŞ¸WøĞ4“?O<AËIÎD$òm¨¤p)ÉRÈ˜cÉß02…'˜*¹ñnS&Ÿ­N¦e0#IËbù£¿/J³Æ†¡{ uÜdê|z¸åZÈæş+›lØ´ŸMú¼íÖu¤9 ®°i t«ï«ZëİÄŸáxÅj˜™úÉİEÇ&w^¯~ÂI*éî‚ÙˆÊÁÿN¢áÓÉth–öd×Åw×“×¨…Ş-òÀÊ‹Á#×bc7(<m›Ü2fˆæ:×­2uö|X5–e2æò»‹»ïjÓ5 Àµ÷QD–æ×ôV¾Î›æ’TWjpt¡ˆ}ê|ÿÖoİGÑŸ†E>Jæ­÷9²¥ °RfÕƒ¾İ[„zu5ˆò!¹A¸Ê÷,•<Â½rÉÓ#©ªº	C„'”2}Èõyâ‚­Ù®!µ³™£óIæäÕ9±qc—¡²½İâÌµk¤7²(¾Çn˜úGÉ±ğY™wq¤›ğóÿ‚¿îüTLTgÅÉæÂ„ Öİ†ó*‰‹÷-E@ìq‡	 ã¨BN\˜[¶nŸ¡âyrQ‰%¦îxÃï«ÒŸº‚İ;}]:b%#wÉß¹®?R‘HËZ^ÃÎ4!cjNŒ*‚ÂíHc|ç¡—kóµ@AS \^ÿ”–3	õ »Ş.·fêà;ÑÎÄªõ\r‰”¹+öWXÌÀöXwñìt‹ı¦	—;M»©´ÿ­+jM8¹„œeR’tóîeÀˆšÍÜ¢u‘6—¸2Št‚V¦aÇñ¢ÒàØŠ«…XP™–óR¿º},ª8’CÚ”@$'í†ú~Ó!¤á²·Ú:9vÖï©µÏã7!
 *`4äõ‹‡Î¢“¿<,º|oYÁ…€è¥Óê¸MÀS”‰j’•ªu£&pñÂÉi3®ÎyrĞ‡<?»+Zz©)U´3¢I÷ğ˜@‰£~È¹Kn¸„Ì÷×gñ~¾˜£;>ï€Å@c¨rºŒRiƒzEónBXGµ}ÎÍù))ïÇrĞÉFßìJ'9¼Òø»İÁc]>®ÙÇ±±øÌh”l°gÃ7Ë)q}×C@|ıŒ¹Òˆ’ÔãKË=¸NÓ÷gïqO‚I‘‚GÕŞõB³jÔ1"Üƒ:?Õ } /µT;TE†,Á÷Äz©/G‚9ĞÌè¶Ğû%>³ã|~øÜb.-qGUîşx##?$<aü!?Ònx$Æ§ÏáDç"×~"RL"æDû¢HßvZ|EÕ^MíÈˆMİ¬s;¿˜p·ÒV9—&9u¬À¿iCÊúdcåæıWc‘{	?ó2ƒ£»Íú°ÈšaÒ­¦˜eŸj$]åaB”èLlÅüó¯uÀ”â¼ÅAöÓ|í]l@?¾=Á.Íè¬|ŞUa<®hÕ,lM¾†{1fàÑÂ‹ç–G>ÓzysĞPÁW¨±Ú`İAf‹üšT„P.âådkCÜ·][§AI:?	K5DäŒøRh=û<eĞŒuøG,á¿›móñ<R—÷(^~\¢ã…UT²–mŸAUØ‰z•Sß\@å¬g]z¾”s³yzÙÒÓÆùzÔÓ¬{HÍv{P½}¼oî+<LF›I³	7£>G>Q=2šwŠÌ,)ªtIEs!G—üCPÀ|¿&Ğ°bO5Î":7Éö¶IÊôXd­ôëÎ!ÃrÄÁï7ÇZ9wO¹ûÍ™vÚ²C½Oèn«Œ”#ès¹•Éè„û›”\–ß¨¬lÛ<§ÙmTsª‚¼„šÆ9h‹ö.ÇÂg¸ÖíˆO;Õÿ'¡ ãĞ?”Ôµ	éÜ*ß„—]+›„"3Vç]©ƒ°•B[F®O8[Qø<Iœ¸ÉN_Ä[™ÚlEBæ@½,§ æMŠ\IÒÿ‡WƒR¯Ls#wMJ£³Pá7Ç-^øbræ,½ÔÅ¸u»+ÇL\>Í?|îÍëqD©4'¤wâ8dÏKô­ì…ò/µj+ÈT‘h“É|¯ùî{‡Íù#œé£Fğ>ÅÃ&ÄşÄşt>;b¨›‡îióÉÑU»Í£‹CEÏfˆ‰Énfí•AŠ1©´ñ‚°c`ø3şÆŠrÉ_.6ş†E9[O=Ş«J¶ÿ-Ìd.úÏÉG]~Áv£ÏIí2?¼ç‹W<*êå•àùPj¹#í.š]{˜´³ĞâyBÆŞ÷A¶>«ÿáßz\”Ê?‹hÎşÒSe$£ò±'KÙàø¡’S~5îú(ÌjŒ[:E,&¸*³&¡#âÒ/J¸Ê2ò´-‹¨…£ßM¬kd
áWØW\Ñó•Š‡ybqäZr-âËàSèØ[C£Ş!ëe[„>?	°öáû øK–O¦à´îì¨£êIüE«KSK†‘CÉP‘S¶‚,‡=·„_¾0~¡nD¨pãXNzx
·|áa»Ÿdª7¹RqhHšŞkª0;2õT‡¨ú5°L#|ï :‹Ğã¬seÕ~xWDÎ³ eHñ¯ÅâûXQs®LE­eÖ;øÕ3éEÅOä¸×"|B#ŒF={cãjÃcñÔ…t7”q`Ä¦š¯ÄƒXÓºúJ¦ß:Zùx­©søÖ`©là÷@‡{&7RØø=íø­ÇåÈøbõ®*³Û…ÏF`ßdrŒYÍˆÅ¶6õ’,9zá1vùşíï¹’øzØ©“âI²ÁaÇ¬/Y0ƒÜ”¾ã¿TûA K]aÃãV‹ré×ƒõ¯@CŒ¥ìÊ,
eÊ£äÓoâÄÄüœ«kµ.9|ƒ™ÎÄØ\tCZÙ`3q{l‹’
¬3—79+g	‡°şÄ°­ãê2»F3Oóİ¿M©í/ˆœ
Ì0µ/o¨H²P…İöÖ#ü‡GIÙN!¿Õ§Ù—‡È?*B–G÷·Óš]LqDœ°‹ttªQ4¯dÈ•T‚³FùÛ»XÎ=ãš}öLçîÅ®Ò_	ùƒ¨RŒÅ‘ª&Iæ€²övÈñPİb+½ËÕU©ª<Ûf$qÇUT‡F@‰âOEã¡Q*­Oã£Ö!)47Št¸0ö©†Zaø³½Ô˜²èØÏŸ%;3O¤º_Å;Ø[ÒeİO¥ú¦0&"â£+½šß3¬à%E‚>ÍB4GÂ-9]¬AŸO¿3 °Eí{ÀÆ0~€±²W:As“9ØªlƒÏâçÑqQÌ·ªØš=©šTÎµé–ãŠxFRù¦R¦µ/ª©Ó´gËHyzqÛûöü1 bÃÍX¼3[…ÃèGÉxgÈ½ûGÁ}’N1ñÃ z™n‹´Ë1û &2p[ä÷"^<„İ‘+I½ÔÆ¬¶sıÜ½€mî‘øbŸñº)iŸ{Ò§ìtnB#V8UÙÏRw*‘Ì%—xG–|ôZÈä½¨X´+èBlJÙPµjàû˜A!?/³ $7“`q #Úë}'ßn%îº˜œ{˜¤ú6ı†EÃoçÚ–*ÊiÏ5$‡áš8-soøAËÛJ»GÂWwç)³Q›ñ/g-j¾bÂÉÎÆŞŠ¸eRq£šØH¡ÉÑÖHrµqB}'+!"ÁyÔ<@‘\WÎÓE ·†ûÔRÈp|>XÎŒ¨-õÄì"šJ¬a<Vê®-´yÃòæÂ©Œi‹¡r¬–¹Èº?Ôey?Dˆ×<W”ğíç¶«¥{îBkr”üAôá6Áœ6øö·R™ÁA¼  ÿzPhç±t†G¾bç†ô,ñĞ«=G•ô¼ïƒd\¦šş>ºãí¦¥¨ÊT¥šççW=ÉmfÑ<©òGJÓù®U‡¹;‘ZÍN?œş%.Â:µôPGáÏ.ÆØª/ê´ƒÌ¦´nÄNµÓZÖ„:@E”Ãg‰š6‘qZX«ÀŸı?3&à”Çl€Şj9³1ºÙÓ—v$+dö%D¥Í(ßİA+Ü³÷\¼¸î[Ûˆqç;gáE>Œ²DÕæo1¯ÿ2{“wp(æ\#ı„ÉL›·èÊ¬rš¬÷÷`\´<?0Í×YõP% ijßîŸèOğøkÄ‡øæƒ8ĞÒæÎÔ>ÖïnÜU`´ä,P?©ÒÈæ‡ œXş Ë´ä&°¸lU‘<w½&´àÜ²¶“DÍÙ`¸ş5)ıá ¤ Ów²¿šÀ4˜L¦Ebú¼’ŠŠ™C5®Åg°e›Ñ/-qáM¿`œ‘}í8Œ†	`.øD÷‘(åFU†ŞQú®&š~*ª´!Éxı°±üæ‡[„bó›Ü‡Æ*HP
@™Ô4ï#¦{‡1V%‹ğD<Ó£hc¼'ó™õÇÊ‚·„ÖÅxÃ2™—°†VÜ²ßÛ=“ÕÙ¨fÉ_\Î²^ãÔ{?ç9”N€Oy$N®Eá3óÏA³û©}ğ…Ç}§0W€¹Ë'µO{J}¶$bìİä\ÎTÎãbmUÜ!Z¨VT%2 Ù³o¶ĞÄ¸,€ÙÄ`ú7kOT‰TµiÒ:ï‘à
–2ôjS¤ùÕØâ`±Ú»-‘‚TÍS&‘,¾flº\ø´Y(¼ÖúÎ…qí.À¹‚fôŠxğû kÛÔrŸÃƒ²o©Ì,ûÕ`Åe±M$ÿşÛÆŒ(ìû˜‡ùÑæÑ.ì«"ñÌS5¼;‚‚[”ŞF€'>ñD&;Ì$ûìÆ·§{]™ÀYÍ}Ô7–42¨Ğ(Rå,ƒNù
êD­ÅĞ±û0¿'7Ü¼²æ²İ‡é,İ[ì¥¢ø9œå‰Œ(é·U &ÛêJñ<pÙ¿/}³?ÔŞâı…Bã–V ¦ígã–¾Ö@q…yú†g[Î­i
6¶¡6X@ ñª¥¾ûÊ^.æêÑA·„áK5é0nP¯d$Æ“àöúR¢’bâ¾]ruùØå(|•±é°I<‚íCÙĞ¸#¤WVO}ã|ön¯^Õj|Y+3õzBĞ«”qµnßèdb]ğGy˜îµg.U²Å±º¢"ÜÒA9Û Áƒú“RVu?½Êf_©5 õê@¯Xx4©zJi¹¥ Q†°W0³nÊ7*ö°ñQ¿ÈVò@—ËÚX?€Rl(‰ãB+2T	ò(¢ÖW}º®Ğ|`œğ¤>c](dú?¥0øëVÛÌÈñÖ)âbÊ	YàÙSi³^1i:}QMå5´«}Ÿ¡›dòÀk¸jraçO´Çÿï¢&á·Ãg"òšÊR¿(œç9ÜO%ÛT¶™ßB—Ğ´ÀPÁé˜5V>¦™““¯~“ø”å¤”Õy~ÿTŞ
eüÈ’¥-.TRFíµH:®à„•VW!¬[>·´9Å
Â.âvÅ‘}xºê#32O9D94Œ4v@vÄ¼nğ¡ëÀœk:eÌ„“Ë¥d_N(~zq0ê4ÈÜ;‘µ‰odsƒám¢ò¿º°O´$£ê‚š[½KĞcKû¦&UıÌğ<qn0ŒZk	gµ`³í%™‹y¦À=N¹< T‹ã!…g¬¥C¿@5_Õğƒb¨Û=Jƒr ’XùıAPUë•‘¨PVwó‚#ïø="ôö6'şFO§~S¨}„=©¨_¦³àŞÅĞ~óşæ˜®“ùLGFõ–îïÛ,t°c3>µÓŸ³ub'ˆbIÚ…MİBc s.qß­(TŒÕşŸ)¥Q')>ª|íÍçŠ:6Ly½Vş²ˆ“J‡¼ifÈgÂMó­RH¼.$àOÈšç«ºóºúh$K9F ¨Tv
¦MLwIAQ–K¯€PS¾8Å£kpè/S_©` QáÜX¬£¿=áãOubŸ«O{gİ;²z’ /I‚7%£h<j]–ş.©‰ Òå½g`Iö›
=Ÿ%7˜w&4~¨ˆåPh´¤NT¯<&5ì1ÈIG	.…0ëĞš/	EÂ¿ôVŠÑiüU/"öqÄg)í¸¹ßÖzµO–dùõÉ>Ix¢çâÛlouo°µB=–‘€;òÑ2ø!ôYN5ç7BÖÔë_ilª±2ZYÜ¢;¦³sœ0Ç+NÅl?›fª½—b;§¾Ã§blÿ–Ë ¹@½ŠZƒ2&m½àümÊŸ.^W#ÃR5q–Ü6ZÂiıeİxtë~Õ|ÉªµÉ=:&`»,M Æmá‚Ğ\ñ×ßi˜2c7Ö-%u"XònÓX¾¬Î›Èp„2ŒÒ/*¾4˜GõìRÒw_,ğ€rS “¥ûùãvaòÄ¦"RÜ<ò­Tä´A\Ñ­êÖ =J˜©º…Dƒyœ_9ƒ¤ªCZ©®Øí'G~ÜnwF>0şêÅ=àÍ¯\¶ÉãÃª¹ÎQ­n]À9X"Ë+€Ô¨\F÷Â4‹{=]sÇÃ_]åŒÉ7O<ëg‹ü}´åçñ¿êü}"İÖ_†ƒ¤ÛA9šOÂè
gyMcRô*H35B/oáêæ¦a-ş»|†Y•‡7©¤ysK,ë¡YsœB‰Ä«ë[€µĞšôçì²ËÖñÍ3)}xû­Sn(=<Š!WBÉC¤b} X«‰d³;}	è“”~BÏ9ÃíJÿ¢³s&ˆ(“˜TVöÄÙ]Cè æ§Šv6¿Cœ™3©æñˆ°–taª¤GjÀı2©?ë_?<±©Gòí>hEN?ù¬Ø×®Ğ{{¡\¿-Ì/·ê×¬PÚ‹lNÁªŸ}/DÆmb)†ıƒÿmFÒÄ¶Å‚ÎPşT{nÆbx!©¬K¬'ÖÊ_™;»”’½Å_ÈÌ]’+ä®-Nõ›ìÄ“àUq.÷0''¼÷ë…ÉÀ6üS¢‘U‰y#’8eõËë½î¹ÂÂw`Šq×²}¢[·áûÎYåñ?¼md&aU†œ3Y#Á’lN0DØÖdL*y¤¢‘õ¼ÇŒCv<m9¾|å²Y†à•
õßt ¥â2÷ÕB±ö°Yj”L$õWŞÏP^öhæ©ØÍ[†•ZŸSí@ºU£-0ã?9ŞöÁ…“@g®xŠCvŠŞ×Ì¨‹º<®'3DV¿Ur,ôÊ"êÈ)‘¢¾Ñ×I:’s–7`$?Oéj,bA 0Áü_ú;|Ä`ã‚"Åãg™‰ó2õuAY"_úsX€ìA»w®R¦~O|†2~qÍî:üÚejú¦®ûÈ,>8ö^V§¢qUeØîÒ†mR…e¢™Êr¹sÄTk‘<ÏiÖl)Ò3…!¾øA¤åë*,‡d>ö£Ú± ¾&ç*'İ?€Ï	×ÍÀÙ<±ë‹´¿ºf	ˆšİ“~Q”“ªMYj3Š§®ííÃouîBøX0Sù¹´uïhÕ"OŠÉ=ŸÚ êV³‘2ëµa(bcÜ+l‘¹FŞzë·É.êîw¤°­=’¤–Õïî@×RiÓlƒú-õÂ¼é6Íé^‡óƒp–ìå5öŸü¨/}¶<2XÎš\y•%ç'é­Çmô“Á½§ºHùxexü1˜}qm!µ™…‚Aa®8‰…j6Ä]ÓÛ+O]Z ózù[,u¶i˜;Ò]SŞ7ÑÊ–yT:K™BÊXÓ/­3¾ÎNÃ9èğ¢|O&B™ßàPÎ_‡6ÎcK©˜'½Ç)…ÚÆî“c0K2YŞÒûs°^F²"ÎÙrª&ß bz-H
%l:áIj?Š2³:½ >l	*B–ngU³E)`æ/’êL.»GÚ¡Âi§ÉPšÊt=u]¬É¦µğ|*»&dı™w±ÂÜ2ãç|ú¨|
w¯<	 ¡$áİ=Åà1šJ\§Hb«<6*+Õûvêx²¨Œ•¡Ï¢…<qÜ¸çMs
ÁcÖ3¥%2ÀÄü·}d¥·¨·*Şpôm0j¹È—7z`~è¸¥CQ¥„·)eƒşæ¤’ónŸAÔò£Àá‘.àÂ|f³è·A[/•—öíÏÿáv—Zf¤d!Lc'‰E?‡¢<ö¶’ÜI4ß\†íTÀ-EÈ}ßr÷Çr¡Ïr\Åg¬#ZÈ×n+ëà0alXê•»ãİ.‡"?9¤íÂşm›Nz8Ê?^.Ü{3›şÓ¸É&7«æ@—ïİé¢”§ÃÈÛÆi<UD¿ğä`ÃE"¸Š-¡t›Š‡²VˆñMÊC½×˜omı£ÚËôä	¡NŸbécéñXê·f¤¾´¾¤ÄušzÊ!.K‰óç#i,ó\ˆ¶¡8T\àùA\k4­KkUù7+õ„éVCòcK´­†Ğj"‡Lfeï}h[@x.ÒÌpØ+´sÓTän®·ÅwY³Ê“1Ñg7ÑúíÜŸi…ìAça€­æn¤˜ã™w:'x=*¸ŞJ|8DÑABEÃC¸¯‹16Ùõw¾XÔÄï¡ÿYªÔØ_Ë¹g¿•O¢…êËïK¼áÍê>ªö,œè]©åHOJ‘}Ÿñ1^\S;|ß§>Tó¡”˜ŠóJ ¢%W^Y§ªèÄ£ĞÂ»:àºÙñÅ2mdË¹
, øYŒ_0sk›ò°*ÿ9õû¼(ÑÀ¢vĞF«tMãõ-ñIşä­SXtp,7î”§»Í‡TÚU_Å—›x I¹Áµö!F1q.È,ªîİ–Òbïø†â*â -Ş™í‡ÿìrb À]]»ş£g÷cs%Oò#'¤Ip6pA‰¥Ê8[…£Õ¢<H5ĞçÛ-×S%sš:cü4d¯lÕnPf(¯¶£î¬‡LNÖ²¯åÆ‘Â-)×)½&%]iŒ-’°­üßAg{WrÚûË!Ğ*)Go*ñºA=¡-<ÏGË:aQ*8¥}Ü†NŞ³GzJxúË*wî7¥=L_àãƒ ¼€q	êoÕ[èu6”Ä*‰´ í<&ˆÓ ¯	„K0',^‚0-+çÔA„tçÂzÌ…"ú?€—*6Ê ´Èb¯4r°nÜx£Şâƒ|‚!W,aVÇ±Í!bz2_Ã™œ‹Ê¯†-ŠG¢Ù…®É àuo4.k(BÓ1I2GÔAÆqI€a-Ÿ’ß‹àQşîÓpwÆKˆé˜#'€¾idéJ8ÍŒ¢ËíFØˆ’«¤6oaG¾èÑÍ›¤R<¦òrCKFX †ËW#8èH/âáÉ#û­xkcq~Å´«Œï3ìµ"<q³æHª–Ó(‚!OWş4¸ÙxÆÜ<ƒŸcP¨À-|ë‹-×€KYE:Şpı%«ıá!ŒÛx îØ‚½3º`ÖÒÏÖ©n@ŸüÕ´[,ô£”ÏÃ¯k¸IzûÊè•®ÌØ<²	óŠèzk¯±,¥i'âÜĞ®‚åÍå­—îfXdZze˜À³½‡ÛıÜ™ŠÌ4zIY^Yö»E¼^é\…¥´ªe=~$Å4EIÿzäÙ|‡è¢E_1CdÃáæ–U¢wkS64qØ*‘$¡X¬Š&^˜İÌ:zöx˜ P²Ÿ\P™ ¡ÑÎ@Ü¿ Úí€‘‡@ê/‹âvõw»i±ìÎ;Y[µ,ìŸéD/‘=hÙ½ïŞh[F¼7Ğ#ôıÖp¤§ˆ]ºáÒÿX]è2„ÚôTg24Øƒµr4Ót_Ù#8ˆ†#ÿ+(çh[dJ"ÈB¿®õÏ.	SŞƒq?cØÆSLÿ¹fŠ¾oŞvkv;i—KïÑ®f•„$Öp¬z¶æo™¤MU
şNğ<ÜaÂL6Ó»sjÀ:H›U®±€&ˆÎ3I}0¶rdyùT>2r·/À'¤ÉÿLNU0FùO‹´Ì¹Î:ÙGös_sÛÔš¸ÃÈèv©v¬¹Â¯¢“n®&¨Aé¤ÄÒä¿[ÇÀçÕ‹Â&õæ}& B÷AJöHr^œÒ7"0RL.h˜xŞrÙ<ÁT™œvä)RƒOÅ¡¤…5²n§’¬9,µìâ„ş‚{ştÖ§|Æk+îÏtñƒÚnFb Ú¥\u-˜è‹HrõG=Ü(òa´ÜÛú‹´‚Vôx&ıÌŒÕ[%Ù:›,ëÀ&Áy¢å”…³ï«-p_K=±Z­V¨^@ZÀPÄg¥ÿ‘¿k0ÌÀÄ˜“Ã˜…kLgˆ˜¥	Cª®V3ûıN…×'Sûãm6o zd#†‘—vL(RáŸUßèÄÀÊ@ç]Quß*–Öùò>’„‚{ı:±ùÇMª:Ï¦“,·}½ÀºëŞ#K+´šYÌ®‰>Ï.Ğ8WòpŒ>/¥p¡q}¡À7ˆ2ÎÖıb¹ú#«¯ gÙâÕˆô g,dê)µ*ÓÖ±c‚wüüC;´
ÿÅwj:\K
¦~ôõKà2å,T‡®$¢ îÔôA]´sAaÔQn²’z¥–±–8ÀÈñèİLüj%	¥*ylkw·=·&e†WD(‘'7cvuÓ6¦w,Â®Á[V€İäâ,PxòI«¿×©ø¦‚YEV `æ2ac?å\ÇU(òúN#C7Öµ2£&-»¹àæQ¢¦v9641ó÷ò‰k71©"åVóúØé‰ú2&feÈy2ïıjJ+Q>hŞ¥Ël¨7ä2Iº©Ï”U×Q;8Ú+qu `„YÃVL3vÌ\cÓ$—fĞŒà˜GcÏ7Á¯ÏS}xRyıF<~}YFİÁ*âGè5õ 
…#[xüK­m“Æ‰Ò¹Ô¸$Õä~ÀÚç¤ ÂÌğ¤`æ@„­b³ä•ë0+‚íÄïhÎÖ5şGúaÀ9¦	é["ZJ]õ?ùùu&€¢òÓ¤^ÎçÓ~´W-P™$ç#ËB©Ñƒ@şÎš²¯Y»Ÿ³™hš)øå±¼£ìıßöV]ÌTO™îBpBĞ–‡i·5+7ƒ`_˜ŠK‘£“Lrñã~©ÃÀ;İGSßùÆ­]b”¼³ÒçOş‰~óÌ‚”½ÌÊ&cJèÁ˜=C·ĞæyrHbÎï5JÖ
ñø#•ÆÚ‚øV"Ä)4ö&&`ô£µÕÚÍhõu$ö¦w×;x’j ®sîc¥ËJ/1Ÿá6ÅàM…ğÌvwö8@Sç”â>1´*Î’O(­ˆÏÃúÙ¨TŒ©ËÂ^˜]	$E*–mTv{k$?R éÎú"x·¶¨í<YXK™ä{+fôË–àNªá;<d¨Éd¸à37-«Ô™XôITÂV¨|·)ËpÀ¸šKb 9à2Ø7G&~¡´®Ì'¼ØÃP„÷ó;
 ¥˜ş~i¥}¯ä…ùPœI`ÊŸcCö§ºœi­qÇ¦Á—¥{õŸHS5ë”ÇV±Ín•°Pé¶kAÙX|›,¢^£¬pİ¦õªÉ“ôÃ,£4™ŒÈ	WvQ4ÙÒ$u Ë×íÒ‡p¡‡fíuQAüÅ‚Ä5—c€Cúzİ;B#ğÜd°Ò'Ìabÿ[Uoqù³MÒ¸9âğ‘ã'EúÉ>oÇA`x˜\nòx¤\‰Ë¾†L÷úngT‘xßë€2¢úÔš`«úê<åèäLÏ©_;šhÆhùUÑUÓ;ş9‡b/Jã0­`ûü şÖŒHÚÙHc€-Ş•àµ± Ï	f¼$Ğ[û¶àEâZUºmQÜn/oAõãŒú}˜¢ÈºH¶ãËºëÆÀå–7Ë–„ÌwE”Õ‰ß;ÈÁ$cGdíÂSsÄÅ]]õbà6íNO©:šÁtº2ù"áZ’)PÎ»]‡C¤DùBTTy‚Í5F±<­»VOqûùÌ9mEîÂ|_6$×~1«ÅdË7ˆÜÀøÚ»BˆÒ˜pW$nBB¼D‰ÖË4Lş+e×ı¶çòÿÆ‹ß–ÃzÂ±"¿-"ŞN‘/2²sûª"æg÷ [£GÁ¿ìf`j˜¼	ìVfmî~QCçæw\hßÚô?QX­»Ú±·¨¿¥8g§ĞE†ƒGFa^İàg–û=q0:v¾tá6	Œ…îlœ×i İ‘ÄÙc +ä$‡y‰Aâ{.l*Íµoå‹(´8HÂÑö—jÖ0,Ù(QEŠs©„\;ó'îËùû9ìÊZã‘á3hår}Vnd¶øÎh Iÿ¿–t(®IXGŠÖ‚‚•%QyÎµ¾¤Å¬^lcWYö´Ri%Ü5î	ş·D¯l÷ÂCHpe n%`fvºË€sğÉo¸ 
vG‘IÇ¥CRNUlç*xÆù#`iïïsP­$|ïZk@¸í¨ISï¼°Ê‡ˆ‡îüàã^/¹}T%¿÷ÿ3?í‘ÕNp+æ–7•0ì‚t ™­\v°Ûà†uÁ•™ãm%S4S</%/ÕÖWåQ©Úñ_7Å¿‡Œó÷ª77J"Ú}íaÕ/ãè“…GëHv²–UØÕnM’ÓüXæ½ZdT#÷S°ÏG™õÇ¤ƒ.Ñ,ß´ü¼¤°§-ÿëaEåµï§rfqLONúíÉ PÀ,Û÷Õê$H@È©BÿÆíK!ø|™Á¶ŠEyâ©ëmCóØ#×O‡èe-öåµVD0Ëõb$?e¾Ëù}êùBĞŠÒ7ßçš‚PRÑYŒšÏY1?ª]ß~cÖ&Í3—r
Ö‡uÃ~ÑÙÇ²–a¥•<8J§ö‚ÁÒæ}SF‰t¾ù»­R˜¦="Ñí¯G[¿^IŸøî>ıZ	gyü¶*à½ŸåZ´—˜R$Š¿ò!± ôa~ä¯-r à™ ÔCA—E¥ê0îåÒÍ·yñ–@(¸yOŠ(%†åòG48‚³´4)G›ÕÔ‡´éDR3¢4&ÅéT•¯BA^v6©¿“•Ìó‚ŸDşüXAÆb4¾óÑ¾¢ß;ƒ²ô{Ë—mL0ìCèJg¸äYï¿€q'ÌºÛT$-/X)Wè¸Ogİ–·LÿP¼şp+^ \#DfÒü¯ÊøLÒÀ¤Ï­UNÒòa}ú¦¤]PØ3=¸®êm|;1‡º'€ÀÆ$vF8jèM´w½ìÇgUw¬àİt\tåÑé”QƒäSå¿ıWqÇ#‚U6t*‚ÅFØòn bÏq©Ó{Ñ®-’šmùQïÛ­jã3$ã†­8Â­„ø¾+£ÇzØ
ÆÀ×…Ég)ùql Êñ‚ÈêËØ(Ã‡b
_EP…mFês0¡IÍÅ¿†ZOYUOï[tş®Âà²­æ•sùí¦d6óÕM§læø“w7Ä*²SF.2zÛI&1®#éõêòŠ }emÁßÙri:”:iù›mæ7œ¼€“)$´p#Lâ]¦0å„‹Ğ'y¡ŸÕoÒş–ëŞêZmF¨Í¦	QhöÿìEö¥ÅãËÊ2`ôV
ÉäI% V#ÎóïÕn•âßâOİ¢á›‘øOˆÒST/‘ƒTÇ¨~Bth£&‰§3ÒÒA‚™16ËÂÉ-ÃÀêŒ¾ò@7]ÊO(úƒ€ø•Ûáá™€ª©+6yWB2êxï¸ß@ñ ŞQ\FÌÂä8¦sX+‚J›ƒCI[µ*Y)"ÿîÌ¿xU%‘³¬oØIçÉÅSóµàN¥)¤óö&àY&¹¿j3aö|åoÖHt ?Y¯q—š>¿qø“"Ù©‘Ü®a}Éøƒ’i^á¸fÆEş{¿ ·:ØuÕøã¶-©`ÃHèq•EAçº›õ¸v*áÈ¸[Œ­=âıíV¢^Ó&N	‰@Š¹âaé¾§<–ìˆ‚ğÈ‹‰„ªq’p]g>0Û¹ÌÆŸ»<d
LSÂ]	ßG(.N£rCøyİ4XW&ö3¸5>nXë’2Çà¬Cä'@'÷ö¤2"2€q—dü>neAÔsÔ.Ä]Ú½ôë<MLäJ9ıx½:V¨8­d¾ºx^±â/K¬‚şTB¯ñğ{‹ÙĞ}ÓDşYt0å]Mc«É.mß}‰‰Ö_ÒyÊ‹-Şş(jšgqÃ«Ü¤â}µ†~få{™]Â² j/»ç±!‘¿Ï™gÖµBi·W ½¯uZÒì¿PKÛØ>±Ø¼W Êk(£+ÓêVwœ©éYD´1"q-¤­)òØ«Ş+ØÉ(¾ƒ¸>Ğ`°é¿ÛF¼´›G¿P¥’fv4n–â:é>nTgzœ‹>;Üls![q*ğò<ÕS4ùrÍEÙ|¼ï~ál„úíÖ_¤ú éÖº<‰#ÎAn+€s¶–8K¸i'¾BoTĞmjûv¼f¡ØÑ›bìè¾”÷g·÷m’>«D²I_‰Ä˜š´|2?ì^øT»k~Ãæ±<uÃ›fY>È%JÈT‚x¹ñI{ÅVĞmğÜk·ÅåŸUGï%Â. .Ñ99–ö}˜ºP¿…:¿+R€y/>8–šˆÕ}sD­p¾CÕĞ¡»‰6ŠLü|²QMÆÆ±ˆ m+|1N3ûe0”˜;ËğOO»î‰e…½-ÕœôSigÙm³öLPOVÍY¾YúËéO…—ì„W‡íÙREÜ1Ğ#ÎˆÕÔQ[øƒâe—ÀÀ§Æà4º@gIĞ!®~×ãŸËHÏèãÅÁc°ó5¹ÓÚq}q$åò¿1ŞBcì5VÍƒœ {nª-9ôÊJL—3qãìòó‚¾Vu3¥g èCÉ_o¼5³¨mÖÆ%|pÀ‚‹DæE5>ÉÅXöãÌELêêÊÃŞKJÏ0²	ĞÁu4õ>í¼¦™TêÙDš…+WîŸ–2”'†W°õ>CaU«ÿ2×TvĞÇI·))Ærš]vs0îÎV›h“éFŞâ±–F¤jF0¢æô¬Ú=ïyÌÂ”7Õé8¨‘…5î‘,Ê±5‘ú&êè²nFzÆ¥?	Y	yÍRX5˜›WÍe8éØ¾]"”@-£p…â^šw{gh&Åî£¢¼Ì00ÓæÜ/[Æ*\‡+vPÎr³rõ, ùU1?°
JÇüª»İÌ´ş<½¹¹›Ä¿¸¥£OŸöÜTÆãMk´„ù†v=8¬0ßY	üh5ó+YUÿÌ¢L} ÿ*çÑp€dêIÈ•À¸"´˜ğFû¬¡Û$*y^V¨¥|IA×gjÔ¿L&_•tkgCŞ%A±ÆÓy"œ%İß€ÏXDd_É;¤@üœòµ5AÈ­g†9™evÚ»0ÂÕ2ãŒŸU&ÌZÑ0ÌO_óª?¿ÈœôpäÇ¦Ä+ï=Ã_}q;¿T+BşUt}ÚJ€bÌßWBC¦ÔÇÑ¡*Ü¯µÔZùëéK'8¦^—N”YïÏêÃÛ®ğz·Ê&€o @èy‰ı|Æ3‰sŠ’M°ƒí¸ˆEAh}xí{E£²gìIoĞ?Ä“¤ÆWÌí:ô»eüD|îÇ¼­{Ñê±Sd¼!ÏqğJí»e $¨ùÍ_ı V»ê÷"XŞ>ŠzhÊD`Ô:˜Ûê$qË
§³ÕB[Jš“d…{Q”—+#·–œ.L:FVĞë,f–¬­èèÒ4 ;àŸá¹Ÿròª¥ÚÓ_Y‹ÄG„ˆ¹¨_¶ŞKvÒ¼¦*fÕXèºj5¢LĞ»Øÿçİ^Ü›Ád(ğ­}íug¥iƒr\¢4]Ç£¿!Ì—^xN†0‚¶KU²97g[cOk>Oï\ïUUìÀ’*¢ø´ ÎÆ-Jrç8)”ÊY»Šp–flòck<„L¹zâ€ 

í±“ kB#ŸÁkÌá¹–€-9æš½HÁaÉ¾>$hæÈçàÆşlóî¨ı[¤õ¼Áîİ«B“ˆ”9Ë¬½è¹:®%c†Ñ&êF»cl­Mót†ÁSÆ+÷® ½ïÀ&-'?Ø­bŸ×|ñåÈ«½şš¦b ç?3ÂvÄ=şĞT‘Nü%DLDw½ˆy“ÛÈÇê}3OòºAsgdG/hÉÉq
–rÜº‹l±Ô¨È´8•…I@÷ã-u­ŞYäçÏ&¥siyoéKÍB/×7F>EJ¢3 *¤G®Ávk/çzÌÖÆ@[ËŠJ£–`„©ÖG$®Õ	)„TwöØ™©låMàcUç³_ÂÇÙa$„«6^ÁÃã7CÄr !—èíP…"TO6¿€$^õ'1"Üš»&·Ø!i—zŸCµÆ®ˆ¦”şpvK%# Èî€İTî]X¢lkz*/ÍÓÈã¾ùÙu Û'ş|@¾BiYÃ¢½w¿ÍZ³¥É/óEIÈ[Î¯ôÓîÁê3F%Ö—ª(¼óà˜¸3OÍd7|cÏFë©£±Å³=Õó¹ğ|»x¥®$+äidn„RóØc=÷Ã×Ü0Õ;Œ8…<“u‰œ=0vKté:°¢¼Æ×o¡¬¡1ı8¡3‰±éA	"Âm2jr®şp[Hq˜ÛÊB—D°{4GêGZFU˜ö6EˆÖñ-âä-òÎã›~1ë+mñ¯Süv­ÇEğqóŒ‘Z…2Y>Ò/•,7¶!‡+69ËŠBèôC	õÊd¥¬æ:™Ğ
‰«˜}âi¸Ké“àÈ™îw z«‘&wŞ8Œ=Ï¹³÷èŠ>Á
gXg)Éırı ¡(L&µ*ŠÆëáÄlš»æ½‘à¸•Sâ¾¸$×+Ã95»ôSJI­ ˆk›$“±Ä“ãN-È1«‘†{4§
!ÕtC_Şşôƒ/@m!áªıÔST>ô	÷Hİe€QXĞNäâE¾ÎŞc•«^(¥±{…³¸.y»Cƒs> A“gİdÊ¦é½ƒöGıUœ´Ù€¨P¨±öHD	üÖ>ëœta©@G}Áw<·‚5§é|ª·JÑbÎæÂ¾cNÔ–Õ/İ•ìŸÔ'ÃàK±AL‘}"	ªª´lÖBñ¸Ëø³épRò1á¥—îc££°MZ¦ğÁÎ"c'_Gcv_Qµãº£+™&æAnšÃ¿—“Åk†1'”Ë-IÁ˜KK«ƒùs>5W$h÷ÙÓ]¤ñIğd‘s(H™òô¸'F‚øÏF˜è3æRƒñrô.Z½áÖrÈx‡ù·X¹ŠIÑĞ(TëSdœ‘RvEÃÜIA2ß“&ê'4«ÉpêèƒYFSÁõU~){ˆ8–~ƒpk¡•ïÕúoŠ˜Õ!áˆ‘ââ„©©°†Ûß‡v­ó™œ­º¿Yüæ¦ÉqQÍÚ mèËòñVT¢ ò¿‡Ôó=­;=¢ ¥ï37¥šÃÛÉvØQk»¿=ÖwEXçA7â÷¶¢¹?‡Ép”¢CÖ8)R¡ «éˆ‰âÕˆ9n>}€‘M`ÑÍ½Óåû(ÑF>”û-e“ìù<&4×öÙ8ZoY‡Ğ1šè_7ˆ}¤âPä•õ¢„CQ4jñ1éÑ’·°¶¯ıÀC¾]DÛ›Æ¥‹ÈŒw2(Üé’¸·“C<”»¼VkÁÖä”Î]b²æÒ-é—¼è¢KûÆ¹ˆô‰›å¯ê­¯ÅV'cÇšÕ‹ñ‘5ñÌN6ÌÀh~ÎSm¸Ä_¨úh”
ù¾OAØy¶9=Ç`E®şÇëMæJÍ[>ü`éXÂUğõè!ëàz˜~bĞF'z>QòYK©ñfço7ÌcV»ëyŠËa!nDåÕzdZ›:,
ó?Ì²Û'Í1´Ö®A{Ş/b÷ @5‡J?f'ïfù+Oağ7g£P0%2Õp¾ŞqÊÇÕ?x]}"[Ùsr W?SÁ¦Ï‰şÉ«e0m(É‡ƒ}ÙS^9¬È\µ§“ã‡7³öéz‹‹±GŠòâÀF%B­è¬`ÉÃŞÿ!ı¿‘ÿ®BË½WøëxÃ¯R‡¾Döš#Ófxù&Û´ ÒvÚ×SDÄ†7š.<VûdàÄÖúÒóÛÙºjİüXã}õºw#´³A¢pı
îPp©à{òšÔj;”f^Ü8zVÛ±q¨ø[º`*àPiM“ÏÕ0F¦éõyª
ú»PŠ=0¯³uæ›•y{•˜â|ŠÑ£½={‰®Uİj˜0‹SF`.ÊEïvei<en‹ZEye{c—ZG4AÈ#äÙÓmayËZx!~Ôª|:¯D95.(Ş÷L|ï_÷iúRÑÇ¿;©Ÿ!4Ì0«|c>|‰Âe ¥.ˆ µ¤×6h“„½(yeplÑ»MÁ¬şÄièBuX¼Ãù—ìaL<¡«²nÄİ´^€rûĞ”VúcÚKXšXå$—ÓğÜŠÛ®ìßV){ˆ‘(wë‡.YøÒ™ ÚŒhË&.g*¤ÌŸã´æèï©WÙ¸üŒ¨[ƒ–‹ÄÔ>iVó!ö†“Œ›Ñgü&èáƒ®33¯NwL$¸ åÔü6),>N+I5Ü	Å‚Öºp“ƒ‹¤¢t>Îhè\Ø—H»¢ oÏÀjÖs”Uqc° ÔPĞşs‡µƒâº´ê•#e‹l[n¢p$,tİkW#Ñk`«´sƒbMû­:t¬z8ÚÔ2'×3“<QWÊ„röm8gFg­«]aô%!v©nµo0ßxi"KÅŠÔãb'ßM1c\së×RejMGÚ]„íIæ€aÒ,(*}ä¤y9:‡²9ªÚ­Kd©æpu[³öó”°q—H
Ó~tş?iäòGÏÙ'¢¥Ùı±´?­J/úİ¼ñ~Ÿç·‡’EÆ±•ÓXù•Õš*|Ä’º¶¢Ñp¼pô‘›šp+ût”ö/îŒ¦J¯›u‰×Üïu0q4Ùà‡tŸõ½Ã×t5çûÀ¾ (Si6R,6{wHìŠÜ<¢4Ğš³ 
¯âÓB²Au0X˜”3×óébÏ'köÓ4NÈ—G„ƒ‰)ó‘ôa®ô·Ş÷‘."²ƒ¹ÒÊVrbcdƒ`XØ¦ËeÁàîíC/î ¯Kò‡`™y HÂ¶!ı5	pMº‡¯öiş¾“²uÉ^¹39Ğô…£Co‚ÌJŞeğlwHFŞkMs1˜…ŒTgD-ø|°Öw½ºòôÙè¤3[GŞø3Y„7¦\%8ö>[dÕŞŒyÂaH^y=³ö½¢PNÏéA3Õëİ¶<{,Àzt>YB)`¾×öŸİ™{·dp³„±Cto­•jMq:ÔşÒ÷<·r˜¦`ÓJw’ª€¸õ2,¼ü91ŸÉ9UN	óá³äXË·Î®cÍ•Í°ù_™ow Ñ¢»²»ÙùfË÷Wú»¡µ-¾Å ”U†IåFÅÚr1aP(!ùèŸsÌ[ÀX6USnš'Ä.ı2=“õÄ¨»iª—+şLå<Êp7öMGc-ÿÁyŠ˜ı¬)SIêèM÷*4Ìw	m”¡ÚB6É•EñØÎM­GÔ½­Sá²ùÔ£Ë]Qê¢ïŠ=LòÀ¿|cµW_¬8İ<ø}ky°ÀÅğ0ÏväÚ7P˜fìÙÏ{ùa—^İèFì$%d\‚!SÜ²Ø´
¦®òtærk‡@«T¥ï> ?åô@Gşdİê]ŞğyÓò3À¹JLÉ9¶İø¹R˜¡Ş<î­©×$êîiGñtŠíƒëÿxÆˆ)ùMÀE:BA3Ü-Y­ì“ê!ĞV¸Mr]nÖ’W–“‰QNÿO†!·çÚ15KÚ{HfxÛz6?7,½nÊvV;‡éO—WÍà‰*H±™÷ã|«Şº2YNBDÁ&Êm·Ce¯rsRV!íşºj¿m3’8":‰JŒWÕäı8	qf
#¤V5£2°ÀºVfYIpºµ‚í$êf&*$/Ü1yƒ¹g/Åü;è£IPöZ°H$Í4&m‰«”Bš™„¹øî·í¥‰ÔĞ!<yE²÷Ä¼´ò,Íb`ßNCjôU¯ˆ4û¦Ë˜ìÉN†g¦oÔàT4ì{ìL"|áM[ËÏ~¸t?ÓG¬s‚0ŒûÎÚ†)µĞ—ŸX××Ä¦ˆõt%GÆÉÍ(“bæÏc½”ºôÁb¶’’­¨Jux9‰£Â½…òÃãÃ•)N6A88¶t7»Nd­ s*µ£	öÏŠrGb^­ŒaBë%Ûj}2~Ğ®ò«š£ª“ƒD­}Yˆ…T	ùVY–:¢mÇü}ä¼èCl–yÍêH\5jU51SFÏ¢Oüü=<ğjeòs<Cªz²şøïa#ËÛ¯0{%Õº»*ìrïºY<µqæd)àé°Ö±ei…Nâäõ<8t6]NplêŠSTÂ¤_èG*ÔJC²Şd¾Ó^û~ãµÓoÃAãqtqÃ=íÀÌ»TQ~ìƒS ÃjxÍ—
 üÁ˜Ó^å€Ø£ê_B¿­Ëo^‡¤P?_mmÓŒ¡ª‚=ğx0>ıdãà³ª—RD‚üÀ‡ ´¸ÔÙêDoÂùµgšsF£BJOs¸×Xüñf·ú§ÂGÃ¤‰úbˆÛT
²ú–u[”» ¦A.ˆ(AÓ_ã0ı†vBt´\E¯áè™ê"‘.=á8{óèjl€~>`ƒ69haĞóq~po…J"¡]äÒğïUåzµ¿ÙÖI|Z[Á Î‹Vtà)ƒáv@Etåù›rUÄĞ’0±şïfìé,M6í'Ú§ÆÅ@ÿÇÀùEàcª mª-®™¢˜’ªñ¸’Ï*5À=‹Ì¸Jg‘¼şk]öYAµş393].Îd?ÌSƒ¹ßŒõHÂÔù~µ[@Í…_Š^ÙZÓş6‚q£™	§ĞğXØ=?ÉY¶ûäıVq·Æ/½­(&nyÿf>2Úä?ŸvÈvÆ"Òéè!²+®ME¼@­É«!¢µHù—î¯ ¦Ÿnu Sû(•ë·ƒo<&La
Y5‡aÔÀ^ëU|¿çÌÇİ2JyD½eP¾}_÷TÙ5R}7)Å„©}:öZë°Ç„r”8‡ƒ%¿DæÃÑ$ìÒ¢1ïyªw¶Ï³ÿqÉõ¸¨øeŠ‚V
®A«¾ñÏKHn0Š‰’2Ğ-A8*-ñ9ÅÏSF;ÇÍlm‹•)%·(ñE"rï‚:ºbÙ²kÜŠ¹›~ÓÀçBm‘“ÜI?âš¨õ”ŠÁ®>³.†ìÅöé<m€ee´{?KáĞüb†ğ½Î 7ZË2&7ôkè6¶½Îô¶^l•QÙøÓV—è‘;%–“‰¥ö9AƒØ~»¾²9£kö^¶
ÉĞ¯üM§òL ³“C §¦ç•ÉQµSØhú]¾¶Ió/MÄ
™RN;1zk¨TŞ¼I¾±½ºEt/õ_òAO@(1q±«¡­w.ı™‰€p_a§«gú}~S_,eÂK‡s¾çVÚGš>&Ù/Ğ?®¥ñ¯.^ö…XˆòEÀ‘8ô2f¥#ÙFíŞœÏŸ´pağQ!¾ÌN¤åµş@äê—¤g¨^W6™ß§LdŞÖ«¿;îŠ$¡tˆêÃş3ß:å„sCC|Ñ3_kÿnIÊ1tá¥lqÎD†_†XØ°#
vVl±ŞºS%Ê@ŞèeÿÙ)ÌÔêrÅ[Îğ®«›wn%÷ÖGi™ƒşm‚'§Ktü÷ou>'Ì)`¾iì9»`“9™øWó%ˆõ‡V@R^IÛ…Çä_ [’T[TÌ`¶­3»Mê ±gû·Ï ¸6²3îŠUK…»NçîI#PDÉßk;.¾ÀçÇÉø25ÉmêšqÔ&Cb/¢ƒ XJ™®”ğ[ /^ôH“$9óæ}Ó{8ˆ’Şygäz³;?Í(ƒ ~àº8—³şÄVjN	‘ò…¹£Ñ}ĞiŠbÚOÅó&+Ï²¬XM)øì(åBfOİ]¢àËºVhÏÌşIsh È}ë0…7Íö›ñmbfôFH7§ÑIYK. ş#¡şİ}? ¼Â€À`‚Ÿ1±Ägû    YZ