#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="948122615"
MD5="f0e46b58dec0f6cbd0cdc58d87e837b8"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26288"
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
	echo Uncompressed size: 160 KB
	echo Compression: xz
	echo Date of packaging: Thu Feb 10 18:12:01 -03 2022
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
	echo OLDUSIZE=160
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
	MS_Printf "About to extract 160 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 160; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (160 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌâÿfp] ¼}•À1Dd]‡Á›PætİDùÓf-0oŒT>öŠ¡–şØij÷¶E¶A~6äö )b•ÉÏE‹Bbü”Jšd ê>8ÁæäEËÙ—ó!š¬è>Vëu1Í¸NtJòÈ?±WRÓ‹1XÂi9RœzıÊÆ¶€æaq¼rÁŸoEeCşùÜct à1pyü¿ö ê¤µ#$‚k=—8¯x¤Xûäñ>•M >–10=ûãœã£ÓË€\võ$«e6ú:ƒblaıb½,íß‡L}U9œE´×C
t?Š¤S«Åš¯"R©H‘ş°4Ş6`ûûâË©bğĞ:`ÏñMøÊp¸]úSÓ¡èüş
EwL	#‹q•Úr½[ea€,ÃÀ…ÏÊ*^Í×NÒÅù½éV§ãÏ^æƒJ‰ˆ$@*S’½Œ”sÛP•¹añçEıÁÔ^G QÌf2&<ëËZœÍß¤Úzƒb<$¨Ç«¸	íššŞ<–c’Ñ#šŞ5='BDïÅ„~”Rú'aEÊï7®šQO…Ÿ?ŞŒäÈ…¿ÑÔO¤Xiø(¬™Œz)jûo>İõ;oE|bÃî¡ÒŒššl›ƒ<lé«~wE%uÃ<PÉ•zÔT< å¡kòÆ¶÷ó-8„ú’§ò&R£û~õöôiû¨b8E¶¡O‘LÒ@Keó;Á_åˆÙåUªöRÁ(½ã›kâó!6ü<4&h"Fã&B¼øB#ÈUBjƒ.S».ÓotÇšz—Ä¹•şSõ—±”æ&g~š1¸„d§WíÌ’)ì”qozuó¼Š#½h2PgX ŒÕ!d@v]Î©ïpÚ"çj‰ˆ³ BB$BÂXâ¡Ä—„=½ñX_Ÿì#¦ÁïÂçÖ¥5PeÉÚ3x…ÓÃaİûªÌÅHPåà@l’,à)©Š„&½µrÔ9ÃPŒBzñ<‘@ói¯­ØSê´Xœ\g–”ó!<;5oY
MMŞ¹ , Ş!ÆE
rk<“ˆ,ÖËMAïÏÒn7´ B’U,Isòpîy¬;bÓ(”ñO:º ÓK˜ÆxzDÅ•ÛÔû>ğ\ëÙ­ŞO“üŸ&gUiql\ãAU˜…„á»CtàxY++I…·(i½]m#‚BÄ;,!lùÆµı’ÔÓ3´ß„ìnãN²2¿NĞéDŠ¶è¨¸fš\òü:ğ…ÚV0¥ºè'Ï;©o;Ü,¹1´	Ótüb¬÷jÌL‰Í“L6ƒ)]øNN€¨yÊ|Õ=[÷®[°ŞJ§[—@¬±¤Í¼Q[•aWL§wUÖ¸²ù*éÉúƒ ú¾Öß`ÌMÉBLcwÎ*í5Ü’ë[ÈQ¦ıeæÚª¡ÄaMED°`‰«ÃıöÍ¥åÇ*oV's‘ıÛ§ï“û¤+ 'M©3Ûrâ×	×9zËn^½à¶İzÛj
M¬˜òÄR~Œ­f?µ&…Çñ‡±ñÑC[Í6İ/·YT„°ù*[:AÇôI@?×Ş2ª©l‡æ-ñfE·“s¾²ÊâØÍà†z!%÷K=ÉÑÆui:B›ı£i&7¢Ákâw‚éiºµüÜ…©ÜİªÚŞ›œqÁdÀRÏCòˆé¡°OŸgí<9ŞÉ0<KÅ#O~C ªmÈb¦nÅ¤SÁu´é¼>yë(Î&ªVi&v.×ö1É×’–6Û÷ÃCÀsmï¤”ìWòác¯sË/°wˆZ¯'ò»îdk@÷Ú0u„‹|ãqáÜ—«“©)-¥WÀ'3Ç>óÊ¾ PÛ1WUçh|˜tkeĞy‚
~ëô0¯J¹0…[ÓIî¡‰–êl
Š3°×Qˆ)[Í¾ûY%·ê¨ŒWò¦Ò&‘İÆÉŒ43¡—ZØúÔ­já¡v˜	t‰(<Mú#Ap+®	ÈêR\­Òá2°@òÇ¥ÍÜg?1¹ÈŞÍ'6S,ı7uÕsÂĞöÕ…`,‘§™ßf‹Ùw©#»›‰"Ôjk&Ëš¿2*“l2…¦PË4Jf0|Ö¥YÕq><D…Gªh%FT:jb'[€”5½%àíÙô¸J?]™3·˜?cØûäÉ?Ìşê2oæsƒ l•ğ]˜ıLÓ—ÿ©Uú9unxúµ¾üÇ"“SUFVÒMÜÏ'¢ŞWvº©¢Kø¯Ó}î0òŠkÇ9ØPî^t|ş6qºÖ—¦5S’ÛÃş¹€¬·yõÑ¬TÔ#¡oÀTpáßÇÒèwk¸ô…b™X2ñ(³}ë$é1h@Å€O\n†5 ~X‘Dõ¹[…F¼Î5hkQ@M`À”L5Ô!‡øüÜZŞ:ªI²k¯'¡|¢ôgRa‡ì\Ç¤_Ù¥ÑÎ»clø½ßMÃrWV¸|Á}›(Ô›ê,Nd-¿ Œ‚V"óƒ\î•¨6Ç;h®üA=IÄ²º$÷«ÓÍ=¾ÿ}gœÛôúıÚÍàp)˜^”¬9•DÖU¹ãÃ1›˜gçÉ“U{»{šUƒ¾:lÒZC5ˆÿà>1£M[`<šS/Ó-  meĞ)½èüÓˆäH,‚%­ñ%{á»uâ~tûGã)¼©—”¶ô¶¼xQèã}È~S›õ6Œ^6Aé\¢íoˆãg4ŞV4^6còíd!rÃ!To>#_½0Æ©ÏŞšÓ#€EOJ^9¸´@Ş:îMÓoÖz³î’:qn]WˆP„r”m.„öĞˆ»ª©x”¼­Š±|àØ‚î²jIr*ã_ìş2ôZŠ«Q ©¨LÜ¿ë4d¨• šùçèmV“kI±¯¬Jc‰rXÚ¼ |Bg•¸„…,.Æ>%J÷Úgq·Ô=_7úG1@:æÉ'èùd\ãµŸãÚ •ı¦Gú'#Dí%¸Ùb”“c*„6 v¡k¬[3ğ§ª'ò—ÜHnp¨î¤å\(¡M¿ù’B-³Ë§ÃÄa·ÜmGÕ/Ù¡ú^Ş!;>=ŸÒ£TÁQ¥¶ÎÎTŞîsVƒi«\çè•NÛù"É9\œd%âe-¶Vz0Éëöd×Ä0Ò;={¶¤ GÏi×o¼H-k¬=ì¬ˆ§PTÏ7ooŸ(T´"ìªöäjK³½¨D€@ÈXúzpoW<)”õ×¥ÁêzÄ|›ı…ì)LUÎë–k£Â,Şs©B'ÆœHõÁ ²†¾Ê%“~BÒ&ÏyÕ ¢TL’%ÿ“Ášöæã¢°®	¯Z×5½,Û]îïe–m”¬ù À«*åEõœŞßÈ…—jş¢‰Ù½®êo8,Ø{\‘>dÆb
0²XÊÿ]=I_ÃQ¾„•™Ç|p¯4æ1Ã5,£¤â‰HTğàgÕV*Ïàg8+Cfáºıõ#¤ÆŠ/{\]19ÊL‘oÕK;ü®¨³~ºYA?ïo’w©ÏªHjó¦±°v¼x]d÷\\‰¿T©6%ED1/y5¾'x­m±?L»3³ñf¦?nÌ›Ë•íp¿ĞĞÆ‘•Ú6fÏF1/ü‰'Ïj-pá±½?nóSNa#ÑÇ‡ƒ[ßçquØÆ÷ÌvÍø¦º™ƒòÃ,¼IC¼îÑAú3öqn”Û›îÉù+»İë©ÕûéÔÎ~b{/á4]ßG‡ñ‘rnãŞ|<35mËğZRKÇ~¤1¤–öµÎûây”gÙ¥µ/á![îGN;’×_lı?å»äÎTµ®¥Í?G<zÍn”ÀÔèÍ™­EÜÆ1f1È"_7®kD0Dƒ¡á¦ÁÍhfõ»¥T}Sj9·¤œ‚'ÈâºÒpdğ¥è•@¾Æ°^ÔİFay•¯·´ôcµaS‰ŸJz bÁ…œï$[«RıÂ”7É_°‡¼Ú+	¹Z`2[mş|ÚÆRû²•ÌZ”¹çÁP:°¨³Ííúª>Àv—gJé„ĞÑdÑ€ï8;Õ½\Šg\´¥I—xJâùzH³FØ 8á:0£Ç¥ğ{ìğ;…¡ˆ–(6X<¥´±?Œ[×0z‘ï)¦²Ã—™/¶|ªÕšAÚP‰61²HÃûä§çÔ#»<{W²š(Áæáj¿äŸ…º"De8QM‹XSì])}êR‡N¡Æ¥œ_o)›øªÓ£Ó0'kIà¡>®“ùJgå±ˆš|3_E¾V$á±Ø­
ğ¤$w[ò×nXEù0–ç€Õ³´(·¤g‘½Û@µ3H¦vrgêU/8›Ë‰ÿ'}¥%ay’¿ª¸Íi2?N=Î¸üå’D%z‹à†\Ş›„QbéÉ&ğùBvM’	,§‚”t’5Ç¹şe&ò§éWaÆWct*§ÜHáO»B¾ÕUjŠ7ı$8»\pKT«Mçµ"Ñk¤VğŒ½<'îDÀJfP;•\‹ÔÌmĞs…OÖIE?ŸˆR¹AÑÌ²ÎõfV1»´rD?ãÆ®1yª†ğÅOÆŸ¶Õ4
Páû	'™–ÊÒ¾¨Â‚~ï‘ª¿iwIL›_‡Ë|üŒ°jèÚtòí¤\4›h ĞJs«;ÖÅ-5€˜×›|1ó¾re„ØcÁÜöÀ½(Ş\ZÅcÜí#ØN_uˆã2ÅÚÙı933	ZÍ†d,_ù@Œïæßmw\?“#4ğ!’ím|mœ,ÜB¸]å›= _¤MgÀlüöBy‘B'®f[ ÌŒÜeø16mÎØÅfGÛëÌ:Jı¹­+pß÷ù½a¢ ã•,ëÍ¢ZyàÈU‹oÙY£ı7-”$HÕ†ş·ˆÑ …O“.Ó‹à;ÅÿGwà!¯ã†ÍHw(Ô­·Ñ6ÀŸš‰n,íÀêX`NÇ8­t)˜ˆJÖÅózÊú
FKgW½AA6¬@›9†ÿ¨ËÚ6,å  nÕtrÖP òïnÄXÛ.#Lñ.^IãF±ÉªäpVOß½ğ"J‰î’	üÓ±ï’ï%ñÄ’É²@ïˆÔä±<–Î×Ô\ï¸³Zòeş5BÖzå‡Fª0@‡~X³î}M·crÅõ7¿£Ô×…¥ ÌNgôQBQš€ôÚè0-]ıúĞ-«n•ú%İ%.XH"Ñğ@ÑÁ‡õqP¥½¿"‰ıÍê"0§ãŠ!:¢Ï%§îdôƒ=79¤Vî²qù9^‚9¤€“‡šÂ{‰¹ŒØÜâ;Ë»É9/1à–O$®— ¸‡.ñJ÷è{~™?­-¿(võá\ñX’úuÜ:QHÜû‹M_?5	ßÏW…ØB~Ù xCêu¯ÑÅÖ!wÀ¢(•Œ° -/Äé¶4.ÜÈ©uv¿¬UIä¢»Æ1k«Â"‡Ó¡vÖ4<1²„á+1êáÓÅWyo1•€ÍqN[X¶È=†¥’VI–·ÿ†$­-	â–‘ív$¯fª(}ãæziv£Èİo.MçÕ‡¶GïúÑÄQËŒÂt´^(ÀÈ*<ÁÍjÁO ÆsZ( )ãDã-„9oš]B{©‡›†X$Èİ¯ƒôƒ,`g~‹ğmÌ ¯@xÊÃã£¹jèfÿØ,½îëŸMƒ±*@ÖhàâQî…Z°ù÷†ú‰X•ÿ%Ûè¢"sZîª]ş›&î_iâ½ÊìAvÁ½r¾Çsç¼~Doˆmzšl}q!Ö(¡f,Ã‰9DÕäÅéâÓªä³B¼õ1
½âRƒk-†,Õ:9dsÙ^Ó
9 Ÿşƒ‰l÷lÄäìq…	î1a\µÚmá.ÄîÏ°nÒã‚öÚdrÒåo¶gÊ‡•'fOyccS3ÄVÏ‘>óôŒ
pÏO*M'˜Äcî}0~³^7½Öœè(áx×<-œÃ«}-¬2Ö­°±•È?ˆ*,ˆÙ¶ñz3Èñp……İ÷U1˜g®K³9ŸŠæ‘]¡òÄ(üàeÑ©•;ªÎ¬İ:Ù‚zVË¥Æ:R²äí·'_cÓ<òêeö¶H”t;©Kl™TÍ}z™ôî Ş(öJM%øiŸË†À¬aÙÌÀênï©OlMì‡\’3©}hT¬†£—òé¬ª0SB1„—m–ë=µ¨Ò¹.›ÎF¦WÉ°€±¼–£cÄŸ-ıó§	•i 5df§C h€qv[¿¯f-uağí†¸² ½îÅêNç‚HÅå9€“¥¶›gúÌr)¥ğ‰Tj&›oĞÆ‡,µAÜkŞ‡Á^	•¡‘L‹ ëOS;ÉB5y€“e…Ø—œÒKéå-ûÁÔh%;³4Äh‡,íşœÎÔÛ5«lqå¶Å2v$øË€^_O%"n–˜ŠåƒÃk7FÇ{ÈhôªEË ’Y¹h‰Ñ° f½‹P¢»i°Bü¾ÛöÄãVºu0D¢M­ï·E­ƒ?‘¾ÛÊVUvkå"Cz(Å{Â@•%	¿DƒkC’Ÿa
úØÎ4ùd$ş¨œiß;û±€¶SXgÔC}÷“*TE;ñ–˜ÉlŸÿ ŸsÙówŸÙdGĞîÏtkô
Z<¨ËP¶ÈÑÚkpV^Ôµ)îŠq,­ÕœLÏ‹@Š==èÌ]L^KzĞÑâ6MÅ@~èqÕÎ®µ£Î™9%Y‚;lüÙ/æYº,B ¯şE|àVàgÔjxææ÷ „ÌºöDhp×bº²`Š9}y)xƒ}Œé
+¶$¯G–u\ıëî÷P¬-¦]ÒM¦B=C+1!Èf®t(s^ ”!ùv’ˆ¯l/÷ {ÁE°ùı²ãu¶ _QŠ§û»ÁÒı%¿Àæ©ñú\ªüÖg’s42ê½Ó¾/R#½N¦,Xbk×}oôf‹v×/É±¯„’‰ƒÄŸ0|t­±JuÀÌÿÓçü˜á¯<wPÛF¤Ôš‰…ˆºìÙ«¬Èàü‰ì"EÖª›5Gà±uÑ‡pö<:£ƒú*…òÊeòîátu¡®sän=„
ú¥Î¸H§R™á÷ò<	Ë<cÍ­vòç¤£ÒÄ¡øı*SÄ‰$_-—¡%ÿæŸ,DÍêr3öP\ùrUC1©DMn±æü”Hp˜Èœ'‡iŠY¶|‰#uhØä®$*¦1«L èË°–M…äóvÜøs¦]yï‹%Ùå˜’¼5%DXïÍÊ;¿Áå•ÏtBÄ±³ —E6ôp &ÇBl­D\A]­º_øRGQZN˜ÕŠè:Şö“ÈãÎË2ckGà·$’ôç‡ë(Ö„d4İõZ¦à$AS©Ÿ‰h òhušAB„ÃtÃŞo‰ÿ%]¨PhĞésw…(«\¤J¿Z±LsA î€åGs(œ¹Ù|Èâ”x8µ·î Ğ{¦çs’. Ó.¥Šb¯Ve‰ »YVÓ<©	üâPƒ}™î„ &
¹[ÌX¶¡ù8ÉşÁ¥ˆEpÁ€u°†}Q	#¥Ø¼jˆ°W8È¨‡ÃÅ¡E·}¯ ³,ƒc•Ö—$ÕƒMyáeo€ØÀ÷û¦"r÷ƒ€•ÓI7³1Z¦uä¥Çr…X ¹*£=J¸§_ŠŞí5G†n@–)I™xÈó–"c€CşO!’jô<s×J¬m0+…˜ÏÿğÈìÅQQ›¡Ğ)à„4àJÛš‰‚ìÒ§ã÷}rØ6€]«ÄæŠ!”'?<HOX4fèÕÉâ.ƒG|ypæ«hV¥Ú¶ä±(³<CÉq0rÉ±dŸ{«h.y­…Ô²,ªHÇMÔ°hóª‰fã¾©TD(µ-µ'ÇH„Ç²Ä¹Ñ!™&Ÿ0iw©âÇ'OõUêšV[0¿Ğ0¬ 
I]ÓãzĞ2 ^u&m)<§O£7ÏEå,
‰Üzª•aJ¼¬¼ÄÙ–	Šãl«™I«©)ñ‡%¸ønõn¡ÛIó+ÜÁ–bö~ä”ÜPCRz…L¦,0NíB“J_*¿Z
£v¯ µg­ĞCß;J1ËŸÓiQ¹Vò=¦í&Ä¸÷ò¿“) ïåGî¤²L{xÔ‡Á¨÷¬MÏùèí ç2ío–œ¥¾Ö°ÓK¢)ÒƒĞ¨Î±éüÅô“Ëåz&`3>ÛfĞÕ´L,á1I¡É„ môó§%›Àpp#j¡º“G´4©SCÙIB’“E å&­
yqæÇY»?gœ¯.Î*‹'W×€à—†¼¯ÚÓ±˜	Ï³œüu¯,!ğ³€Ê£ŒMÒåÈ¦è¸*ÖUØGMyq¾µ^÷ƒzaö®Oşh´ï^÷ zK¨K‡ 
1MK$ÿ²S!ŒFÖÁÜ$°ª?ÊØĞîy@ºCKg5¤I¶:ï÷A0›,MÍ ¿é©øL»"¯Md÷1L¼_íFs2VZÌå¾ÖÛ5`Ğ)%¬Y*d¿‰?©…‚÷¹5Mqpó6poX1ñØ®"”ƒ¦Ñ¸a¢uıßn†¶š}p¸.ø…!\Ş³¤>%{môñ»î48PéèY¾é¶x·R¤^ HgÒû„b½'c«¸ó„¿³(Ö^¥³p fA^ö;“ÆRÏ˜lusÕ ¹­ÕÎÈ}:Ô˜Š¾–YH§Ã(¥ÎÃè„Yt	ı¡Z:Ïñn3Kµˆ4@«é:‹Åj;QÛ‘ÕÇ5Zğ{Œà$y1;˜¬Jsmgÿ³Á×÷˜æOœ6;í¿ÉnwÚ¢¿W_ÙbÓÛ{p{k«jXœ{ ã†ø€ğÑšj\´ËF½s<ûbÎ'Å{É¾)Ï¯ÅtEÄu£$ÎápC¡Mışkâ‰‡Š”tsâ†‡EPzñıA,±ÃNì0$¬Ì™Bv„Í%‰)ÜÌƒ‘“ZÌ¼×
©‹K‰1&¼j*‘†^/¶t¯°ı±¾uÿ?£²†¿:&CÍÂR»êµ½;`íªŠ÷Q”ğšPN¡*šÜ'sÛóÈÒx„1‚ÂsÁ(°fôø·v{Ùj*­!Á$U«W´/UT§§Eí•B°1»[,?ŠşV%X£1›‘&Èp“J[¦ÄÑ+2F“ÍÊ{èùİd¯°e—)èDt)sT…Qqd|`/Îœıûù
ê –çmš²ãY87Á½M”ô!zâ–£€U¼ ¢…w-a•lÚQ»ğuÍ%?ïdÿ¥;Xª’ûè6ÚÕĞjmÆî‡ø ¾ïj'°rGV4T€Ùİ:ë:­S±0D¸›…©”7iÑg5ìæi?õ…µ…êğ„|N:y¬îK®W*w+V#V\Lßp?KÈ2§ró*60Tyô}º°n|àEÜ—9ÅQÏá0,_ş¬úFÑË/9Ğ$Ëêß©]¤ ÍÊâAç¶}¾òö¤%²úZáHèb+IjafºuRğ<,æâ.ãK©ÓbÕ½o×ÌàhZš]_“ÏN½ÅÀ›Å 1	T.y/Î+]kp§’ÄÛ¥àÈ~Ló›$“ë.â}eÖ›é¿åµ¶ìã–óâ|K-¸÷¥»@÷&ı/÷"tšaÈ×beCJĞ]2Hdo²B òKÃõ]Şƒ%'şœFüNç«»0?»%^5ğŸLUŞœª±mã¡Ğo(Ü˜àM©E©«xøqma¼{´Ü*íÏFöU|HA8D‹FÌ–$ÚÆ!d¨¡ç$5Ö¡×Ír\¯EQ)<„É®É³oı	~™ >ÿ¯×Š§*®Pè>ª|ù¾oû7E –ßD}HÜYI¸n?Y!FmxbÃVkÕå„¾¸x®šÄ¹AZs¢Y@ì'œOé‹52O­|vÔR¾‹lZ9FAË0ÂgÚ!ˆîr‚Ìİ­ëJ¥œñ\0çÕ	ÏX@¼Ï¡èÛÀ¢å6˜W8qp=$œçLŞÉÜiˆÜ2){ƒ†›Î®xŒ÷»A³!õ¶×yôMŒÕ M¨îŞbg_¾owƒ÷c¥N‰£O(¯ÜéŸş64§qd¹‚'™TcÄn-j)QL|İ8DtÇ‚aä2Œ5ÔÄ”Â¢Àæ¹3|*í¹RqvE	z¨Ò¤ r Ö
3G±‡3›H-}\ïµ}äàêuğçÄø\;Œ4SNTå\*ò“¼x3ä¥™Ğ‘GÚÙªt*| ¬³NVrşëu7Üo,{	²Òu$A _†(ì2²İÛ7æ³²°½|hçfe‹SbeyTp²)'¨2¼=#O„N¯×ôd·»èığ6¬¶È*y"Ö,Õ­\ùÀ‹»oNò&$Ï9÷#ÖÓ^bR¦gxÛ®óAŒ{V¦G'" ‹éÅg†Íœùi¨1ÅĞXNõ½Ñ·%ÇØÿ„ª¦J«/4¢³ ÿ»3»y¨l¼ÏX’7«ªjÀQ`‰îe›üÏR&6ª±4-¸­´ğÏÜ1«|6ÔN)@'A¬yGsƒª×\QfŞ:&$ã)˜Î>œ*u—à_atCÅÓñ¬T»ıVö_ÀËzã@çß¶«ÍE]”æ#a‹}úÉ4	ÒÕ´˜P)¯9¢m¤&–^´_hu.H`Ÿ´>.YÛØÀmĞBá.N”ÒI¡x–zM>ˆl*/¨¯qóW&[9gYîÚh+ğ–›“}^Üå;H[ûÁÊ?Éèİ! Ö¯IHÏ@º‰ºC–¿¦v‹6YÉ½=Q,•t½K<·),+BK×ãñºÏS(¾r¾ûU¯œvs;'tı¹\¶MÊ^…æWf#wD"ÿŠDÉ†Ïßû}¾É˜ğ…Õ'0)ïğñyÌJ;ßMy(ïÆv©"¹$¬b^hµB'¹i}Œ:g¥2 
EÎ¶o…sÄÀƒ¾™"Û¸Ôõ6AÁS	}Uú?¶ícíQ%G™%±j×(—RÆF="êÌHšÑ=“?„ÎKÒ¼ØB×¯b(½¡Š2\$“ómº nè¤‡¹ôóše*µÄ@…Õöh¿¾Uú¹òÃ¿gşMxh½6Esl×hx!OPŒo%Íÿç³,)H˜x™5nü"Ò§”=³»ìæÚÅ*!¾ˆqœ[b,3É½N‰a¤›Ac$,J$B–glÓOÂ96ÖíÓªñ¨SeÕäŒÈíˆòÈpšºÉ6Ïü[Êo_Ü‡]G†´,L5@ã*«êm…ôİ$î“5‰“¶\ı<<˜Nş“V|H¥¤Ï—İ¨ú/ŒtÁÿî°õ‡JĞ™ó«:IŒ/Ñ.ªØãŒÖëJ3ÌRQ=Ø”y‚98şÇ¨u„Ff^F~ià<ûòá²—ë. Ä@x¬ÿò	#©ÜÒÂtÃÚ0+5fÌ+óñîvÒ¥õñ&|vzÚé©Øƒã¡·.²âç¥VcL/FL`~Ø(K9Q9Ñ¦ÖşÄÄ½—ÁbRü6æŸªç—ÑYcæoIrÓáÖZRe™Ù]ë1‘Ì$ÛeL­TI# ~äYV•r±%>Ïšªànø|çxy;_	/0/L˜Ì‘¾•¯<ìõ{ãc_Ï£ı“…$9;Óà”’€»á@¿\6vX=s‚"¬ƒü·Çº|×eyÄ'!¯®Áÿ¾xÌ è¼C	5 —qnÏASõíú~Ûşºx‰Æ	‰ºU›‹Zi±?ƒÚz’t&¬:ç,ò»Iâ&b‚†¿è<CIîz…—Ä ¶ÆµçgO´’¨Ğx-LPÎ¡!Ğãá~şì¿Ÿá¾¯È48®kÎŞHòñ2+Wd bÜá·­“b^”
7zP.=ş›CÈÌšÚÓ’óÙlºÂïÔ›ß½ç~ùğŒåpÇ…åÆÀ?ä-˜8…êÃ+çğûÖµvvñz?Ó—,*±Wò„
¼šP_R/¶	ô4ˆÒCåJhëÉ·\cMˆ ¹¨¸`ŠğÏRn»Ú2é…\oÎdÄÅĞD=„'†'á2(hûB¢çîö>„öş'¯möìØ0gˆb#24Å-_VÇ`‹çM+öæF8‡y}ø:b…".Œ†ws¥eëâ5Ìr‰‚šîöô©obğÅ_ƒ1¥º¦Äºcæ&jÁ˜#ª¤·±€ÿªR åKE ñ³½tÛö¤wõœ].%‡ŞtœkQ‡ÎJÒ¸FÄrGx>ƒ>¢uSà5LÃßj'÷SF—ËŸ‚Ÿi¬¢–&®%–Yv‹i{¨0é¶‚ñ³ºãúf–Ì0c¥AÉA±ê(…gÉ±±Ç.gú¤˜èp¨LÉVÑ“ÎD6î)›¾È÷döNÖ()yªãªú7û#Öjß›ÕôOBà^Ğğ$í#äÈjØ—™@€V£lîíd©ä¼?eÌc@"‚9+Ÿ³_b®„dPƒh±ñßò‡YfÓ¯Ì“. £:ô§‹Õ•ñzê¦Ô#ŞAöáäŒÀ˜V–­ÃqÔ®¸“U˜Å0k¥ÉøR÷Yê&/¶Ónd‘¼'E´k‹1ï(êèX+d•˜<+œKã·¥6HëM¥ø¬¿Æ¢BËÂ%0 Û*°k]ÃSÄ¤Üzú‹Âî+WJ£nm»^„%>ÈDınè`/<ÎUÿ1ã8û†U.YZ]§îÚ›_u¢< 6;VÏä~ó)µ(ºô§O¬VkªXìI _¸7ÜÚ…’·Ş
Âé¬PàdùxT&Í®†c¤å”ß2Âì·cN`¾mË\ÔÒÉSÖTÑ!…Â€²À—³í1]‘u”®‰K†e¾ŸÀt*NıMk½jl²_†ïöÆÃ—ÿœš_¼z˜L_©‚ÓelúËYûÄûçõ×mËÍeÙìôGf?wÇÚ´](VÑì‹ğ»c´ªk’ñÉ{‘ùNülLõ¶	ñDê²¹Ÿ³Ïƒ”-lìA;Ï¾RIaá«ó_Ëg.Iÿ±à¢¡,ä›d0Ï¡Fí¶9H6Æ‘ˆlGu«èÊ©:b*Ç)@à²RÉDktüİœ€JıJÖdÏz­¨Õd2Ü”±¨£ÀàI]Ÿ{ÀÎ^@j¾©‹sü{á€Àõ¬i0p{%¾X²´~‰Rvƒ…a•¸8/§. 9ëèˆ™{³ÓèÎŸ«µå—rµz4lk²Õï<–«eabçU×Æ@W>f!tjêh{)òÓ‡½¿?ø‘c[9Ú…º":8Äœö	9wŠ9¼ÂdŸ/±±¥b{}vgÙ`ÓÃS˜ùõúÂ	ßß/,§r¶cûÁN{³ÓtŸeÀí«
GQGe p ¾LÃ2Q­4§½ ı˜‹>·öZ˜k?ìk“£r#yµu/S+fÉ/“2"æ9]qÉ$K„?¦&35”%ŸN,ëïi…“NÑ·ê‰ì€Š¶ßÏ¤%h÷q Ú5LH¦çoÆÑY‰ByfDßåËs2„üìL/¬õ˜m4È„ÛÄ¹¯XhÑ¶âôtö‹´’0œT•mœPô:ìÆKû|~{æ¤B…0ÁĞØùZ[zÃzMÊ¹¥ÚêÁ’J}ZKù¥Œàj”RäÄ©OGµdnNf‚L¥wĞ|ÌŠ©ß‘‚ÔÖßìGiqˆ]uğBŸï¶ïø~D®òÄŞ!É¹x…Ùƒc?k´èÉvÄWc/àe;å¾ŞÜ6pórÑÉ]§Ïî_ˆ*se@ŒôûGb£‡²ê5oØMĞëï¹é…Ofı`Æg‘“TîlÂG¾±0 êÎóÂ›GÔå—`–±Ù?§À²Q5ò(]_Ÿ^.øf‡\éC1SŞ¼{¶ÖC%	ÂÆÑÃµ„Â	•r/!mÛõTåi›d8wÇ=ëšñÃ{2˜(ãè+Õï2³;€cZë8®½ŞÂ£EDoÏß‚(D”ˆX¾¹•ıı27OÂ¡‰pM·ğ·N€[ÛT’tBP*u_	+#×F‹Dß‰1Â§Ç-j¥5HÙy¼Ô!m%8 îÆNö1\ÿİ¦Õè1kÆdĞxM%üçå†ï§.ZŠwDµ¨¾ç×±Š¸ZO!bĞxÅ,FHÍÙš6Wz£ìõP¿-›#~ƒ©ã;ŞR¤äE4(RKSD“q¤Ÿ$?©qœğÑ
Ë‘åt.,ôıkûr‘¿s\zPÿe6Øp/üA–ö?5½Í|ÖøBDÿE^¯ã=Oy®ßñ1%1Î•©Ö´8p, ¥tãF{¿sUßöÚxì£ï
à¡cV"9¶|÷`ì&5¶	ÄÅõ»¹£pèS`ò]G×msÀÏ8Â©J*åìĞX·–ó) „¯P}|>¯²D'Ö 3ßÊZWz‰^„à¿â
½ò‹­UVšQ³m·“fµÄTqÖMsBÍ)Û’±dğoFæNöM?H&q:ô®¼ÖRéÉo›' ÔÎò½%S–X¿§v€ƒC†Í¹;·ğ¢ïÇANßÒcêHÁ'‘u 0òBAv‘\´&sS£Tà¼}C*£©.Wô¦e¶;Zš\}Jİoº ÿ.K•”ö?à`[¡½5€k‹x§DónÃuÄÎê»NÓÿ»·sCQ“—ü7#›ë¯ÄAàéŸ*ƒË	g§&ÙU„˜»¶¶B‡Ã]Ş2ƒu€§ü,€Ñ¤Õ*ZÕ³&†v­tÅ¯%èÿ¤önNzƒİ+çğZÖêå íÅåoc7÷-ú9[R«ğãò]™öL¯,]*¿pyÎ‹öYä­ûNzË÷wœ—î¸ÎcğxÏÜF±õ£.7¸ñP&4pà·>HDğÄíñaà5¬3U{ÏŸÅ·ZìŸ—
îÎ©$@”ü²ÖÈ$lß»|WÕGú°…g;áÒ ~Ïª ]q<LRV+fÿ¦c¢xY8.w)­%ÇshõÉÄæj¢gˆbXÍ>TA£1cJ]JÃ„ş8:If{.%×ÎC{n˜ı˜^”3¨&øÓ¹"=û„ïG}fæE¼›˜L,vòêÉ6İø[§"Òw©+Ø,Ö`~XİIKtM7Áe6,n—"üã[Cd`Ém 7¤-šêmiTÛ¼ç™hÔô5RNüpQ=i²ó_Ÿ0<i;~^@ Á +~äğ^¨{¦“€Jµ4Ö|çŠ?etTcB)­_gvµ»Mì#˜]31Eç1Î]ßuÁ\Ì›gëtúÉzomÓeázWÂ»7Y
ğ]ÉÎGhQ0hû@İ›ÓÈ]—ud]›‘¿·`
\.r‡Sş	E«±ÏäÙcoŞ¬é¥o«±.¸”SÛægï§Ü¡µ’L»nĞ"zÁvímÊ
-è(èä•`JLõi®bã7=u½İEÙƒÿ‘ç!†‘½­nåmûM&âLšjõÈ–í@UPİòCîo7ühÃÜnzƒ”!Œ4±®`ë;•]?[ÌÈS®›Â¦'0Y)İçED¿{'ìiÀ¿áª»¡ğ|é›À2Ä¹x _M‘5£F$z?(Öéˆ©®U)G‹Ìˆª¢ñšt;@jù¬PÜHÏÖ[¼¿ï}lsùÕ›?8v‚lw#¸˜³¿JÌâˆ¥?mË	èô›W¹Ht+f!eú»)2‰®ÀÆ!4òS[p"·-*‹Üç i¼ÍÓ”Ï×
«$vª~ŸEÇÊ¬¸¢7š"ã³ÍD~'^tjÙ¾ï*Ãm	´Ÿ‹â]ß+ğcåğÛFu&&01óáœËµÜìoŠXØüˆEçf‚&%ë@eÒŒ_SÉËªÖ>™òU Ø \!fs{ÎxİÌ"STf_F»¶ÁˆúÉ{ªn’¶% ÇåÊØ(Ñ.Å¼áŞ‘W(Ï$xGÏî¯cJ2dËUJuPslªÄUw¢“ÚI3ÖHîR6Ö•Iƒ„…®^Ÿ¾ûîf2Œ¼áöwï#7GbJ@â´võ=Kk¹·Šà‚†¨«¨&uPò@„‘m‚+®Ç¡F?â“ éÊ—~ µíªøÏ¤¨ï˜F] @İ+û„Ç™lTåÆ iÆGB8'ÍRcà°‰_(Áî'MçJ:¿:ññ³ß(fÉ`ùÒd¨-ácG;ß°À—y¼46®»’¶Zÿ:¾–áxğ/)/?]ûÏ ğ×cùihK Ñê¶ÏÁ=Ûä.iqŠMı°4+Áº½ObÑò]šÖ®O&1óAG>µvÏ uG6Ã‰¢ÀŠ—#ºwq‹úç!4‡{¤µ0z^	…ß?á¨›Ê¸J0k˜Ck´N(#t$VšÑ}s^î4VÏ·}eÑ`(#jŞIš†Úâ«ªîP-Œ1¾(—ha)yZw8†ŒB;ù¼ì)I·P¦êé“0éµò*8oÑ•â±¨ÅwHZ+Wâ7Ä—S½ä®v+nĞíR$ˆ…_)©²£Ñÿß‘ìÓ©WÅÕx÷ÇŞ<_‹C¿Öj´¥‹ÓÆèT,Ì”³nîMy2N+©<cÑ7is_´~L)v6¤ù_LŠC]¦Œ\XÜ¶„QML‡vº:)¤M¼¼ÿ­³É'Ô,ûÎ˜s¼™Œa°-ü8‰ÉuY¦»’Ì9ÓtÒì:~HáÆ1iÃ]¶òäl¬?øı9hò`œo³Ïÿ˜Ö´­X79¤<ÙQx	YÈ€=KÌãF°ì±YÏŒª–¤án¶ÌL7 ´^ZRğÁ‘Y‡eÊ¯ìè  µŸ:5Ğ»”]&¿— "_Ğ(£(Êäx“ôÔ¾š®ZŠZµ¸~Ñ%¹×Úˆö9¬Ôµì°ß›—ZÂŠf-BØëNiõ¤_B?Ö#^?rİ´Bî™icO¾Õ“ÒÁ0PúÍ º7lï~z!Mâ;bi©<	­å¾'‰N©¼.ÃÎöÄá´½,ÑD¿¤qš(8µ‹‰q~_JPí]Û†ŸhRXá§³QÀÛíå<ZˆØõõê…VÇ‹BØ9zÏ[æ/;ÿ5÷^0GÑ†~:Kå.4,±®ŠŒ4âw²Ô^„µçí¯”ª4¥{…ÊƒhkûÀÛJ^4Ÿb¼d˜ZÖd	Zƒ²6lx#úLÈ‡ÇÅÇ‚#H)KHªøVæ›ìõÄ3¾@"Q3ù	¹Hœ«¯zx2†§àµhÉ€—Cú¹}½«µÒó¨¹F;Ÿì*ûı;:yIÆå"Äidlø¯:”?WCÔ~„"¾ú¥Drfòâ×¥™“M![ÑÎ·\?k¸ ZõuIôı#Û´(şj»*‰t%×Â€¹X;YÌ§e_şAÏ¶§WäÉ‰¯lwƒ†i°ç»J	543 ‰$/:îˆĞõñÄyE+Æ?ö‘X§NŠg!jò»ê1tãI4XõÕÍ Hl'#ÖÑ"|Tâÿ‰O(â„›H¸*'æçn%GÌ>EÛ'h\Hf†İ¾±(ü£ıWˆ4PòuŒñ+üHxUCN„ìêY½Ï7¬$º“áQ|u¡Ú›‰qÅuÑc°á”V+PğÖ]m‰¦ñ™‰v‚£Â)Uu¶}’dÆyY#'qÅÙ\a7¾Ê¬©ª?”ÌgÄ4âaÍX‹¥æßgºyáVßÛGµŞ·_¾­ißüå·|(!¾s9Çà¤Ş»ü	mH“|<†}òâûy4ØAü˜ã}wks?¾¬F+¡è$P:9“à:¤fìhOĞ…oé&ÌâÑSQıW?­¶U¬a©GŸ@<ıÁôoQîeTW ¨CNz¹¸ÌÜÔ C£Æğ‚AÀ6Í_ü?“ ĞÏò»¯G·¾„ˆÕ¯7Ã7%ÿHÈ_„£cÒ+äHÂàn“Ô­ŠÁDçÂ¥—/ ]Ç=4ŞøÅI²ÿïç™EÛ@fW„¢Œ.ıÁÌ (JŒ0f Î‘F" ãñtÌí¼4›õÎO¤ßÿÒ6u“MTÕRÙÈ{±8Tsè{åZ±İyòbÉª
/Ïéoî Ñæ;–ÉXš¥Ø€Å¸Ì#++=¾çÊ¼“¹•¦¨*st#ŒvuÔ”ç~ zz‚ßbµ³FìÅowò¹t½İÁu‹ºOªG¸˜ø>ŠY––<à©L”èBX¥7®¹à
î ÙzÌ-X´f‰Ú?D3ƒè¡9ñô;Ó;êéÌµIJÒáKÊÆùÑRá´ÕŒüG`UÎ»È‰
‰¹!*×Óx‡p$a?¶Oê£¤¶m…©ıØ¦ŒË¸Y ÷Jë’zjOë¾›nP³#*ğÊ¾7Ş‘TŸÛâ'²¢ YÂ}ÇÒ$Ta V
‡SœÊ¿V½ıÓU×'¯ä’;£¬,üÕ´=­š1ÅÊû`û.¸ÂÒ¦‹M&Ä4¯T8Ã§¶ƒ?èz>ÜP³ƒç&°Œ“±®ò<=“%m™-È	Y¯ğÃõò#Ö”ÍvşãÊZˆr"•W)°N°jîadsÇn/VMâ6•áA™â'ç…&Ã´¨ÍPI³¨ÉWWyé©|Caæş¸cTçwÙÌW=,1QÖ›ÇĞ·ÄË&î’Ù0g3Y?ˆ³”ÌUeãdåíŠS/ÎÆ²µ™L.ÉZ`ÔuOÏaÕÔt²s§ä{Ø›Ø¦â¾:ì‡®ÓA÷ÇÓ´9h4:œ´;° UhSÓŸe”lBrE`Ä81<âsím¹T¿1û–b ·şE"U¶·¤ªßJk˜·Ìı^vã]%k…f˜_ı_fñ'ßí¡ÜQ³_öŠÊé
j±¥¡µÑ¢rŸ[ôïû+K)­è‰/‡©G!­îC²|x¼\´±ÖÜ÷N,]–•d!V°8ağGR²v/!%<KÓğŠ¶şLx‘iÔjÀºHè´(;ŒòıœOµëxŠ:_	;ÿ%¤„uQW`Î¨’6BÁÅÍ'˜E™Ò	CêäÄA–Œ¤ò-°|™kZ×÷éÅn&ÊoMy¨ß½Á£œ¢¶¨_ö¥Ÿ˜¯ÛRïø9awx?Ccé¹U)©öÇ¸¹›jŸ5›@ÙæÙñíx£ŒªÕ)ñLÙ(Ÿ-Ô{ş¿
S&óÏa‚A¼›SHğÜêp}ñãâÃ_İ<x¡UõA{ÇŠèDB}€=M»´ø¾FÚêC'ßjè!ØÑá¸${ù-wÂ'˜n<>„ÛËÀ¥ ½¨Ï	ôRç‡§™Ö_2pÔ÷™LN´€O£µøªR!’FäşNs”<C@L¤†Y¥CÊÍ‹@ÃzyNSqš„A[€¦ı‰°9ÔáÕmØ“2°yæªŞ–»ğí9–‡êâ°{¬¸ÓÚ	z¾‘$ üg) &Xñ¼óDrÇì°ĞÁ÷¬"¯ndÀ™T®g¼áiÔm¾qí[’ <•ÑqDXØí™
’4,ü›8ô“’éø¶¥ c„G¥£LŒNM—YÊ	ßYkıGåg†v÷`JM$­Åğ¼~cB†{Ffô,ˆ ˆB4ä¢0•cĞoqaÏÓæ"ÖF~0aˆ¥m¶,âìéM"r—‡UÕ]$ òk1¶¾	ÉñÕùb’uêÌÎ¹ä†?M+£~t-•*©­GÅJ¥×İKĞÌ¾ ê8;¤`c8#—éƒdây'à` R‚á¿96Ì-EµRÄqæŞWøÇÙ¿`®$pÕ¼Ì.±pÎ6¬>#Èõ¸÷¾KTô}ù©@Åö…¾µñ$»½†ÍYøWÆìú¶½Ôÿ'LaéÜÇOğÍ×©µÇ¤®ˆ†Ëò“Å>.È7`:[È6¸ïcÈ]d“¤õDTï´x•nó~×ÀĞ	ÀT
á ÆøTÇ+ò¯8l! w&Æ©ÿænfØSÚı=?¼2$<òEŞƒ'à4˜dr‡¿¡½ĞOÉ6}¥õ*Å–ƒÈÒ±ÇüÛwbyÑ{u3@ÄCñXß’Pæ‹"ŸB½›ï¢¹ÁÅB]#R…¤†5=¨€ nxø Aøj! ÕWÏyœu;(¶}4ÍyY1f§NÍ€šØù0dìÚÏÕ2ãåôzõ±FÜnÄW_^0¸ÒviÄDFÚD#°TM~>şÎ+ ¦,3ÃMÉmOÄŸÔ[ ş¼lŒ§ğ¹MDõf:è(Q]H'³ğ­ÌÚº´2¬<´ŠO3¡ƒWµŞUı¾]v#f±òLw“ĞÉ'†/{Ò¹S¼zÈn1W„„“È¯§f7S—'1ŸtcŸ¸³WÊ† ¼FµêÌ?×­˜úÏi#0eQ'‡âîéƒ›M4iÀÄÀAF_ófÌ¸Öft ’]ÕgX™£¶óvaÉTáP¢Æ¯nÄ#d
Nó1NbÿßÁû\×*~-ÓY´†+ˆÅ²d›d¯èÙä¥¯§cƒZù4ƒ›à¥‰`ÆÁe$‰UÊ|>Ñ	úÕX«ËÙWFÂpÂñ:Òv"¬Jb_²ê¢ò«ˆZ  ¯6´:h¼ÎY{ÈözjÀ.Ş$Oº[©¯ N´.Ğ÷w/¬‚i¸ÇZjÈ'VF&ñHíÓm†räÁÇ9û3QI^~ÍLì7&ı ND¦j2¾u˜VLÔXİçWR‡¨‚Œ–¥qs#©ÔQxˆ(JF-'vlcª4ÙƒcUŸŒ×Tk¦ÚÂ>•ÍËĞÎI¦®}5“üAgÕÙ¤¹ÒØ¢A¢,Ö«çîâ‚¼n€½³®s|=iı{ZİÂ±/ØbréxbV›Æv.uÕRçYü%J¬³.ïh‡$ ñÕÿÃ£+nÍİ¤d»[´¢¡Í3S.!„İt&šû¦‡ÈSı8®5å¿ ¹Œ$Æ!9šıİ«ø% öÅNsyÙ(y;ºä_€´ñ<-ZjQ²½˜óÌVì$¥¾åe‚¥d|\!XGï»™$# Õ®n|4`õ.g»>Œ˜ÚŠ¯+‰ædàu[ƒ³ı¤Y:¤&Ã'm|¼ÿµ0>8û0ÙğÖ!ÔÚÄ`Qi!$V’q8µÅ_8¦ïAÉåGå-‹œ¨€zÕ|Èo4>AbH2),8aÌEñŠÈñJ{¤WväÅÏXKQC¦“d*€êQ³DˆÛ{óÎ?ÑÔÒ†	¤Qr§qK½‹Ë»?R°lŸêŠç¼@–³¤›e½ÛF\™5‰Àçÿ·s3†ûà„W§´KÔÄ9.}½kzå ¶6wåµt%“Eúù`K½—3XÄFé#M\WäšÙãcîŠZ–0•|£-Á‹>± ^>ÃØïû‡ùæ™Pˆ$ùÀ`¬â¼~ü1nÎ>O+îÿ­Im¸¶Î@«ÓW‘xë¯ğ	æÊ¨Yr¯b¶3Qµ)ò{Î¾PYl  ‡&8çíY+íº—™ºçê—¡¨EJá¼å”ü•‹T4Ñğ,¿JË·—ìVıùâùN²Œ{í±Ö´¨2ÿÚ0ËŒj†·¤ÑI9åÌ”F‘Vş®K¯e/'R¼àiÑ¸\b¦u5‡|­ßCÏ9ÚÚş¢e¡îDú¹.êxó¿.†sû3À˜6‡>ˆQÚ™ù±/nÃb	U”sn¥ÙÍ“öº(ıs¬\×”»1!{Ùxã(ãhaqÙtµI23A~JN×/1Çúúw!´s)¬15eé¼/¿¦}hñ½Q‹‰Œ£èéä²áÎ£”TÉ,¹Ï5úI8ú\d Á}Ö„ÍQ£ú}î
ù)Ó2*$Û¡dò™õâ¼§ÎLLÑº?ğ£DMƒ¼^åÙĞÈ±>à©è-™u ğç\N9ã¢«£Õ¾¼
åì›š&åE±FúÕZ‘’0IÛ^ÀÍ#œCÈUò!»pä»`Ë¦F6¯ºjĞ·¯„ükfç½…ĞÒCá)İ¤åßÓy¯ÿDfTMˆ_ M†v©’ŞrÔåçÆ°Ö‘¿‰Í,àåÊÎVêÈóQkòœ0v®éÂ%×$uS‡T`Vüó\›@.¦C*à'ĞÑìÄd÷æ·,E¾"Æ?³be˜nVŞÕ¬]«Û7¾ı–Ä×Ì¹Œ1*X0ÏöÉşˆF›â«µúğkx›½bíROû8Æ)çá`¾ôİiÊï¤šìĞœËıúX¨õdqQ§Û²&Ğ2YÉÂ«ë2'±8-ÿ
¥¿§½ä»9*¹{SeÍI¾“v‡8•ˆGíÀ¶kïúú‡fÊ@æİ&°úòSà©jOıR-éTp¾¨ªŒâ}¹:şIÌ¾>•è?%1kìb¥Ø0ëÃ¨4´@&DGš9Ú9¸Dıv[)rˆÿaK$ˆsp°ÄpÆƒˆÄ˜£:kÍ}_p³™
’ÛÒd–¶
dŒ9ú‘Ä|óÏjn¶Éš~ğ¥¯ µÃZHÒ¢¡Ô#¾=ÇÜ]`Á†ë½1«gæÕ¶}¬™jD÷d@É¯Û!IVàSŒ³¿G²Ş"†»yùq‡äP‡¿Ê¬-´=Q­Í’§ E›áa~ÈÎŞüLÄZî<•f†S|!¦¿ªy	˜yWĞXz`>íæä_·Õı¶¢5Ë¿_Ê´EÙ1ñqZÉÌxV›yñ ğª¯I¹ÙåÂ |lb¬úKşQû÷WJŸş}ôÅ ¬·%…$FUòüË>İœ1§°€€ë5pOxıøpwWïíMr:ªıC÷=Œ?GËIˆWÉ—%ÆnÉ;²Õ²×v{ï²ùÅÜ½©#Æ!•-8r.¬ışà÷Ì%‘ï¤Ì¹{Y>V™¦Ü™C4Ò°,$Â]†Uü-×©À¥…·wb6eîC§åù¹²ãßĞp¼L]·ÅƒêWy~ºIÂ7pX<›ãh{wÅ|·1˜Ö~ñ9\<ßD÷U?è"poÔ
uÖèˆF¡—Œ—aà'ú¤êè+ôã³ÁyÌÎ.*wÅ••ŸŒ2Ô°ñè3F¡²$Iî¡şšÅoGLM´ ¼±üäGæ±Š¯÷‚©_!\ÿ!un¥C~Gk[øy6NOpgû4Z‘®nú©ŞöÍIr`‰ì´å7¹‡¢¦ ¡Œ¿­àñ¹EUkO2´ {o¹uÏõ¶¾t•ë¡ú¶ıï9ÖK‚Ü& çç\úë]ô‘®s{KUíÔıwÅW‚¢G»§úòö¬j“‚N÷k´o®¾Nó†—4Ì”Şš8_„Ó µ«œ`Rñ¸ÄvsËÂ¸EDPön“:óÌÌZ“™HxA£ ÎÜ¢¨L¾ê—™Ë(†nĞîƒ‰BÛP†ğõMt¥øCİ ß‹òp{j[vèz›–×¶
An†'ş`Fj§»àúBm¡«ì’„ˆLü˜‚÷-,7í+sı{„"Œ68ã›õ¬åÂBËRÎVHÌ±
$!ÿCBFs«hÜˆRÍ–<ôşûú°fteàÓîª>â@óU9+„§ÙH—‘zì­Sñ™HxIİ/‘4…±¦v”z_çGúFÊÌC;vSÑj?›Ò°òÆj6`<=#­Aûñ ÏV,˜ımàğëŞïHïsƒì¥,¶2®fUºåÚ9ötªıÿ+|±k*ÙHº`ÖÕ9 Lª€a16€¬„OÖ/˜ê|îà/F;¨§“GB~­Z®i‡–=CaWõ»Z¹ËtÏ{ÿ;„ŸÀN¯b:U…©ï@½$€Ÿ»%ÀôQˆÎ`Â¼Æda,º'ÿÈjpiÁ³Á.Şƒ–D”I¸ë?&İõü„ïöBŒ)$%ÄÌôB—#N]šÃÙrıJkŒà1^m›Í$lU€øÆŒİ]…>ÿ²XÈ=*´ŸÈ!ŠzÍ[“·e@ÿ§ÅK»1bm<Şz’ì
e~	¥Ïhgá†òo,H\›á«ğ•ÑÚ¨HR}Ğ¼Y	ÖZ/d=/Lãğ¨«!çtXç µàl-/<™¸‚
[D³§Ïº#ØşİM§EVwHŒed İD6û@ŸôºR«N¦ïĞS}Cí¤r£ß„Ã>ğ'b×ù²»>ÂdY#÷ûƒLÓ
ĞLû§8fÓ<óYÍ¢Ïv:_ÿ….)$„	™PÁP‰d Ğ º2<Tqşg59-{Gë½§Aã”48H·Ô´\¤œš/ìÃál¯¸!Ø˜Àyªº#ÀÀ,Â	w°ï‚œù:L¶K‹ÃYR°OkW€Äú…ò¶)^6Î¾¬	ÁÙê2DFPçŞX+|'¯÷×AC£şãnøŞ˜Aúø™‹.ş^í¢’¦”Ç¶ÎQ6lAnŞ3•/¹ (6+¥³İÂ…(ƒ;mA`AîŠŠé+d3iïr•ï¹Â¸oøm2[œxmºN$|<h?	³•]-sšKÖÛ vEˆïYjõñŠú’p„”O]7<'¢^{ÏÅsÃÚÛvoAÑÎà2rå·AYÖbZC_Ç\ãy°3‰ áœÜfİâc—†³i#aæ7ÖãÃl_™"j‘–İï‹Ázs¥TÃÚ8,ß©¼éå 0õôP"œiÅeßñØD¦c&§{ë¯SqvïU@g^ÇPV#_\ª¾Wgk‡iGš²­ä±iÂ+·é©Y°Ô½·b`û9JH²‹?"Ó9)t.˜÷‡´s·.ê–WG3¥ñyŞL¨›ö©O7P{è¾$Ëy¼¥©†G‹á<18¤tÊ3e„A_àªs±/´cÍ¨Rı>mÛ §ùÅC"ÙVô”-?Iâøh8"º3,ÍĞÛ°Zü	÷„ûÉH=„ôıLD±¥§Àrßd±_B‘î¡cxÀ	Ïüª·‚7Ğ=¨|P‚F>	¡İoìœ3ÉÛé^Mçd˜7ƒ˜ÍŠT¸+ÂŒÊ“ùÊŒ˜¢ğªkÃÍCDAÆ?©œ¯ğ8¶ãßšæijÊ¶ATŠD€–[Z*U:“50Ş†CåO`‰gÂW­Ep~~Q¼úîuÆY‡Šk)2S{xçàÌ5G¡&Ğ«J}ú¹À("¡í€(NĞ•jêÌ`“ÇòPÅ>»ãv.µa]¦#ê}MDÅ´•X?‡¹5öæ¡0ù¦-¼|iPä	Ì,×c²íß² ïÅÊg"‹ÏJMÎ¤.œšLŒW¿­¬qıuœµ&>Yné;2HUSSƒéí¼s¹G¦Óÿûn¿Î¾j,±ÚÁVå†ÁtÖÌåœjœFÜœíÆCÔ$¾òËsë‹q
zâx>©v.ĞÜüTtId)ôxÅ~éĞ@ñ±şùõğıAúI†ÇS¢¶¸s®KìıdÑºQ¥	C*<åã¨,ñ6(Øçi^˜´-×â±¶{„+I]W™ñ+6¦ä¹ÖÂ*7àEõ†tæÁï"òÛjÅ-	QS)¨13_k7ßƒ(ùãüÑ%&2÷—Ø`6Ëø5îïdì?œ™çô^¾òD¾ãGhzMu«k½;•4jëb0Õ Œ¹HÉ„	Ş/·‘´ñ0s:Íßf7uÒ~ÊakZâQÑxV›(Ú!4íğñ¿÷°ë;™„xw÷zvògŸe@Wd88;¶â×]i%‚NÚí[ÂÑ]€C½¢sÔ‡¨å";Ø/‚=,³–Å=Åià›p¢ïG–£ÄéÛ5Ekç)×„™ôD¡~j5…@H»aèL‚ı.ˆŞo‚3rp‹ııAŸQ™kÁÓ{ˆëi*9$}î¤,r|Ó5º¢++i$Şæë09ííê`]&nÆ¬³¦3d±º‹N[»ŒGL;­ü~e°™<ˆ×»¡şèÄÓRícîHØAñÓÎD¡l¯ƒjø,€
Ê.èÏ	©FEEpòØ~"k'\Ãˆjuk˜¤Ã'rÆÒ‰$!+Ñ×)LH„HrÃC°®`u~÷`'Bèxš@Çö¶ÎIš7eùĞ3€¶äØf}ÑEÕÚ«€—I¥às©Šb®½„Ó@"Æ4şV—¿'[)yÿhì
æh•ä÷RÍRc™À=’O9_nù©tÌLÅ\÷EûııAãHJÿ\JrµXWf§NéÉ:bùæÉcê¥‰÷Ğ5OLç›<„KëdA´œŞÇ¸2­Ë€ï¢Íïfk+ `ÈŞ€5„«g/¿ö3LÔKu9ÊìáÂ¸ÌØçyîÇåÚiŸxÜåÎ§²à[WƒÁ"~u0'~:¾¥²^´k‡6ë¨*8,.Ö‡y'9§®âòğÜ«%ûº	@÷2¸È²I+étÃÊmó™µ§ãÎsN¦Ö€·Æ¸MØÚ |]Çæa§&‹"å/!€ÙI«˜…{´ÚOPÁp>hM'§Aª¨†7\Ô¢øiN…îUÉ_µ&óåL6GœNgJU‘6Ó!½ufP”™òFI¶v9¿,²kgƒ·ÛÇ²ú7C+»²‰xRõ¯)f¨Ã.¤oùåiV5/H·¿^Xé¡0!$¬¼zLhRB×ş={6b¦åˆ$^}{×eÛ\´—rM4ü­:ŸÑfiXyÇÃ6,U¡Ëø{4}!AùJM«åS
àñÃ¢ĞCß+È×³Æ ñ·â-RÀ6ÛõM Õ«¤mpëá(dgeLÏ‘´Ìèy#5‹´©×òº}¹HÃÌÈ}­\ÏZ|¸ö@«µÑÖôĞ3z­™‹L5:ÖíË˜;ÈI¥¢1ÅsYıÕH7T¾‰¬µğŸÌGlûÑzK~“;u+@ ‡Îˆ¬ãXyÎdÄŸt^ÀÊ1!œ}"=Ï¥_P‡öLš[=°éĞ†w«˜ºñµG²}ËjƒtïïãeÅàÚçÖj(ì¯İ¯Ø‡ÄMB´èO²G<x&L– ,KæUx†öd”Ş›áM­@ƒe¸xÄí„¿¨øµÀêü®Ö¹8ƒ”`
éí´/æ™l„[}gÁ¡?˜´4Á ¯±EJ«F®,¹6w0Ùå-Q”;ê_ŒËót³ıİL¦MÕÔY·º5âÆÖü,ÅPƒN< ,±øZõ·ÁqÌ“£İc€BÑÆ˜^qÃ(Ñ¸cÎBK&ÿD\h"©]lv<bÆ–¡ô®nkB¬Fk–Öy˜”Qü:ëhøäƒNø ÈF^yV>ŸûîŠ›½Q‹Çúb 'Qútq¦(ˆi’^ÅÖ©§½Í£ÙØ=Şòj¢»D®sÜÓ•1`Âx[ª"c·STs^«!0.ÇN‘7°õeøTØ2ªƒï8¹+_YV)ÙŒÄä6~{^hıÙ‡Yî“ÍsŸ~¨² £y?ál_cÅÕ“$Ø§º†oCNÃ«5h"?è­”Í–¬WDö¿²T{™V*únU³pÄB ˆ÷AØÒ‹Q©&³ı£ºRàIúùK—©.^^N¼Ìl6%Ba*iÏğMh^§¤e‹T(ó¡(x&¡q­3û%ße+lÚÅ-ÅFËræĞpÁÛ{I›<™g…já#Nú‚‰"¨n]™O ½‚K³3ªÆNT¯Ï–KÜıùÙêè…°;£xs-‹ÒøÙÁèRÉ	ë¨§™˜`™ĞKä×â
œŸ¢‚ÌJvê»ø
®±KıŞëdÌíâ$OĞq¼›‰Ç­×¢08h;=1Éâô’•èNnÑ|’Lˆ¨9ü€Nue!çø´<DäëÎÿ0ÂÛqRÎ™~‡lŠ‘d×Ê¾´ô(rÑD@).f,"ˆÆâ%„`t’a‚€+§9'ŸêI›0nŒ^›è íY	gÂºWô¸5½À†ÄaÔ”?&~¶eÉÙ••Ø¬iGb†k¦ÚÑÃ\ı³™¸PD¾­ÿ
}ìyr3ñÊ3¹–şt\ ÊtÌ~ÈšTı8'/›$ ÿø
¡Âî¬ƒñcÜ:G•Iº$§îğlÙü—xh9Ê2˜©*ğÇĞèru¥mJ·‹e®åï2	=Õë¹ã·6Á:ÛëY¤Ø(¥»(‡	Ñ_;wŞ“N³‚”Pª £?ÛÜ8YóË_+€GÅ{Ã&iœß×X‹’Oñêo«1>ßdUenÓûã¯S}òÎjŸH•š—|(pn›ÍĞT5:Éİ‚3f[’Â6bâÍEÌLfû¿¦2‹ó³=ìTÜ°!=)ì­R‰|ûŞmÔ9âÛuı¿a%Väl0GZÈ<«ÑJxº£çº!ÊËâPˆuTÁ*!Õ—;ŠY=ÓÕ¢Û~’*Ğë)§¿Šp½S±œ­…À˜~¹5³V1òöf%
‹ø¤êªØPÊ+Pñ²›a0m	­}Õ+,™º« –ù¡+€°êzr±wuW-G¾*àíÇÈ*¤ù¦2EÄyÙ gt/³Y#ûÅël)H“-#f+<Âìë&)õc½È]ú2“!à×åw–ìã4óIş¬fWKï:jÿCcšR_ƒYÄÓUÌÊ>Q*Ì¢,O˜ËÀyø0Ä¸‡ñ<ª: |ˆEI_ì9şcF?¡šĞ]|%à„¬³»8ş°Né
*3d‚œ¤w»°C$Ú‹O¢®Š"ÅÕqwüõWC»0)ºRcƒ¤A^¨­ıŒ“®%-´`ª°’#;ŒnF®^i’Àı„±dª 4pïaÓ·tÂ#[¶€×¹œÿ6É$j«¥R&~Ê‡ƒ…·“|>a[[—ípYÈN+°Ş)9!úsöö¦ÛÇòWÛÈ†i´‹K]¼1Û{{ğËõS Béè2ïjù¡¡|Òe¿÷iñ»4²Y—ÌÿËVÁ€}÷çı¥ñî°/&±_{ÓãŠÉÎ¸ú[hú|v`Õûxw‡Ó©îhœÉıõıOGh0j!M¹{7Õ™D,\œÆŸydY#°\y\B¼†›Şs@Ìv´9¯Ñ˜–ÖÇ>ÀpÄñÓƒğ}.‚=%ÓÚã¹1vówÛæ}çÏƒ«Œ€½$Ã(p·ÿ‹SZÄp¦p…¬.íÔR{`[a"%ÙèŒ6ˆõ©´4ìR›»±\ğ (UÎ›ê9à×k\Î¾€<ÒWk,®Ìbüc›şòÓ2AœŠ/ßÁØD˜ş¦
W*a¯ŞFÎ¼ÀY¸wŒ>uT‘ÄÅG_a£!v7Ó uóHº
qv®Ú=2ïjıkn·Z{7M å#µØi$·[¯Ñ¾¡¶4qús™éÚx€¦~Çÿ¼ÊåXïOzj>S½[F["‘ORéÑf}æ¬\Pÿég™”«Ñv
8w•ÎÈâ1qµ:¯ÎÎ†{°¨dÊY¢ŠC-‡À¾^fMB¦•>‰O-2€ö“°»éÄAÉw¤5CO- i†¬Œ[¡°!«?®¨Iî¡“¹5îdCû¤_:¿úYñ%wH•ò”DæÍCL0H…ôºöÙŠjš=štxš^GØÿƒš2?
KÏÕpõ§ûA~¸®x'½/"›çËÁ=A³ ÂÑhŸ‚ˆrú'çÉ-
°ºñ	ìÑGÍ¸0ŞéîpÄqeZÁ£qEy>Sr‰Ğm£I—k:Å0<ø£Ş\RËgárÄ^ˆ—Y¬P…îmÒÔ€s ©÷œÑZnök@¹p‹¢ÔGÜoQ˜9*<û?(‡ä™o[$«‘g<èô{U²–hÔZhTë²PùõLÈ+f¤øH\üıuŸ{0Ü'cÓ¦‘$êvV­Q[X-—%à~¬æÿ…™hÌÎ£CˆrÁÂÜx›"ZßN²fÅ=‚TqÔ…×çÔ³{+dÙ&‚~fJİÈ"2æ‚/^rü®‰k:š\ÜãNëÉÍîâƒ#u£ü Í§ØÏœ<ÊmÃÖøûó¦œ¤ÜÕš­àİõ	ŸyKp›½a ‡Â>R@¾ÌäÃ2¦úZ Ft´tÊ“\¬ºAUë¡z1u~æ~ÌÎ3ÕÒ–Åx­áópnôR›ˆ¬€øc|ip2İè¿ªjlú èú$Ğ{~*Y< àR]VŒzsm _·%Ê‘å—dDH¨ €×ÕXÜìIÍ“É{‚tpkI9!Tº^mâ}ñİu’ƒy+À{êÁ½…¼Á6ÍcfB¤GÉÔAô#DC­ 8[>2CÊÉ«”IuSiãù.Ğ†M;x#Çw â¹³œ)N¶_$$9+gæÜ:qí¶åj­iÎVşFõ33b,Å4ó­@äÁ¬»ñê	b‰;2«¼EFbc¤uw<‹fz~2‡PM¤Î^w‰…ÂzV1¹Qï'v¥7Ÿ8÷½úı¡
[3ÿ_°fÏxŞd/][}6wÔ:Oô—ù0c­êôB¢)Ó¬UívF64ìg%æVC±kŠ=mldVôÉÉøğÎìÃ¹6äğ3ÑRÆ¨ë‘†Í)=:#3˜úac+ê‹²#4^†$pËü £>\`û¦ü&”@âåË)„¾«‚’^ûæ¦3eĞ‚
çpty¤6¬[Ä³§]§ä\ïô+Èÿ…/ª¬®4mT 
‹* ¨2Aùš úo\´®Ï(r¬¾vÒ£V-£|ì*‡õû\‘
·ZÓÒ#Ã‹šĞß\-à9°Oâ 9ŸşvÎ Nç')”ô°wÄNÓÒyéşü\ç‹jÑ&|Fh¯rºGE1»ëçÔ«p	—öQ€Mq“¦SJõJÅ.YBÁgaŸÈë’ªÛ(û%·p=¥ÖHğzËsJ­mJlH^b“»ÃZÅëW4‚÷@˜¤Bkƒ!h®³¾l©×ô·PìĞ8µ™"X}v8»„ïé¹}ì/6z½>¤Í£–ãÍ?¦eK|Û‡™Y¼).u™•ª.ú‡R~à!¥"¬iñÙ¶’iá*ÍÿQoC²wärm8ĞYøõ~ áûg;ê³¡ßf½z<f™\ì¼Åfåzë|HÃT?*RF2Y-äÔcÌ÷õnu'rîÅy#İÅ»Ÿ‚‘fvÏ]ƒÚåuüæäT™Vß%ˆuK‹30÷Q<Kû“8ZG=®áO¬ß+ş,L±¹qÙå=Z¡OÅzä¼Ení³@²Cg+ÏoO0±õıßÒRşÃ‘Ò²O{£aÊ{ÕÍÎWcôşr^¯9&U*Å‰ÿİv£š3(cËï)¹d÷à¯ØÚ! 7—‚£?ãpŸPPÁ+7·´Öz‘XÁ_0ÜL;·„A1v·*mÙ˜@ÒW¦HzeŒ$«tã.±)!GQ¾œBŞõ“Ñ—Îù0ìÂÃĞ …%ˆİŞ—G£‡"?xõ<–ö¬»R£1¾ŞùW"Á"Ò”\¤	i`ù,~"'!ç™¾ùzmÖÊ¬EæHåª2«DcƒYŸğZR¤$_›Ô	§-®ƒpU’ûÅ²ã¹öa¹ôKh¨ÈG¿SS5 BÄ5óëcW:¬	%èª51·&à`°©Š¨õbOÚÆÍWu—6ö¤#ÆyñŒãI$áéŞ7{Nk§këL-ßÓ&·drIétéÍlÖUñk\ıÇj4 8}Š<˜ä„Wa0áñÏZâ ÏK[ˆq@—Ô/p7‹â­]³–Ô-d½Ã?µö'f)­ƒı\ZFh3x©æ4ñÌ5n/µ²5Ò¤ ¶}ß¬.éo@²x;Ê`¯1¯gi'Ø»HÌòÚb<
lîü,P…á“±oÅ  Ø`°E äákåÀÊ›éçvvä0)Œ¥ĞÁ¾ÙÜw¥˜PIşĞ ³d’¥Na¿šdı­ÊèV¡`ğÎ‘ZÊŸò»Kúk ½Îì¨¯HHş5¥²·‘…wØnÑ§¥³uFõàô4c#å¼Qóc–jœ¾ù€ïrzŞ~S0,·JJV–»7}”ˆyW{–õi55e,ÂüáF!°KÈ`ç†††î­‹¾…+U?oe#¾°Vw-¼A¯O2¿eR^AL`¬œEˆxßmÈ'vœNë°ôŒ¥s8MrE½R>òéÏ®,/Ê(kB±t’\B~Ô\#µßóæÚ¸÷èRÓ.{¨W÷=	[fol•¡HÏ½ŸÅ[–.u¼òc§<MĞ.¢]\Iú£vìŞşâMDìX€•ŠŒæÛ"Úö×`¥V´j¢¬ÆCËÕE4ÈbğlXøKS”³ èfM ÑÔ^ƒ³)Á¬©—tH~nxj„ÇÍb£ó# umà8ÈO‘	¥ÌÉxƒ+Æ9;QwE[I´ş“[Ô{²V÷ İ]|4X{T+š—â}Cøh¼swç/;#O2äEO¡Î$£ôÔ‹T5WßÏá kä(àÓhV2õèMùdË„­lòp§°E…!(€–¹¼öF<ŒÚÿËôÓ¢âÀëR.?"œ«©À\ŸãåUBAÆH-v­Š™1<D¯Êò—'¼=Y€J©VTñœl)zcHø‰0]Ø/€Yy=’½20$ÃîÂ‹Q~Ô87÷AøÊã4åyÑ<·ÌŠp&®ÍªZˆ C­†+P+»H%ó}R*Ø‰ğ«zt%ÇûJğë]Èç'G‰]o¶×ÔZâÈâæg?ªø€Ãö¡Kè~Ô‹gÚ@ï¬C„ÖdvFvK;EhÖol!30ëëlı˜!CœÌÎY£ìu ^ƒ\dı“lsm9E9ÜÓ¤‹º-4‚|ªGõ<àVLôT½æ¡~ÑİŞœyXºİ *üpØõÅ§96OÖ6S@öë9¦E_ßIp(Ç¯õ,_m½£ö÷¶ù]µÙêh|ô÷ˆ˜š]ó¬¦(c†Šy3"*ëyw`!—×<¸òB)³áÙLw nKAŸÍˆ¹§M§6¤ÅåŞ±LÖ{«æâòµ#upQª\Z´ªYîæcuÿ/Ø«"öR`Ûò’™ÒûJht@Éwÿ ×ÁàKêğ‘ªiµ¸vÈ)â[~ÙDm™Püì‚çuÏ:’„!Ü¥,ìÛäx±;è8`<ğ³ß|F/:Y÷¨má­’êO¦ß³{„Š$” ÖØæÖï4ÖM#¶ÿÄ0+ö¬ĞojˆrSşvÇÃXçFŸ'G!&}"£©Ø2õOû™^ÛÃW~Mzk§ÙM1qJËZœ‘¨wÑ¸~òê?¡s¨~æÔ[M%­ä5iş7#~Úe‰ŠŞ~ÜĞCÓÏ|.E;§?lÂå|üÚÒcTï únDjD¹k7¬CD‰ååÀ›G­İß‰FéOâ5¬ş0È¾j`Šx«‚iF~ìÇ}9M¦ ûCâm¡HÌİ*ØØ¢B8í`.9´Ñ®NK7òòKi®]~J‘±ÿ«V•æŒ„ŸU„k*E¶1É™Íp1{	ÎC>[	œ¬Õ~¨‘Á¢ƒQÊÇ	d°†t š1ÅhøFbk]õ" 1AûcÉ4J®‹ÅõWJ¥½XlÚ…”q¦FÑ4ğ·båŸØ/”Ê5Ï±¾´\$nBÙâ²:[å&EÄ…íÁ›©»5ñDE±şZE½´ú½>åPŸÌUdƒyœÓ Ö!õÿ,Y³%˜®~„ãùáH¼íİì½ÚFÅ[mÎ1Ğ˜-¨ç0>·*õV ñÕÇ<-‹ <²'hÙ_Õ–«,ªöôÜ•bWêÃJıB¹¬WßÊf*J}áñİS!c—
íY‚Õ±0
ÕïmDMŸ«ivy‰ybJ‹…ûÀwİ|õèmƒªzˆoórOf[›	Ím\Ë
~¤HcYÏŸÀ·¨Õ1ŠñCßÆšâéÜ‰”Ğ?Eşác™isöL¦ÀSQ¿’?h?+ùs&8‡XÊx¸r;»M×˜’kÖ £à¨Ë\è>r.sTñÔaÍÂŠ›ìşİP½9_¾>{p¸ÿ¨¿íZÍ×`# œ!(gº¥œj6¼²ZæR¶'ƒã¹F”HµsÉŸmâ$K›&ÈëµÚPïCÑÀô#—€4m²
Â—‰‰§$™&mİ”#¸İ'×~æ^öY×ûúCÍôÇÛ*\_]ñ÷ .5TéætuŞ*Ô«¤¥l’#Á#—Å—k‹nºÆ‡¯y/ŞÙŸ½}G²±G%‰ãmïŒgõ³ÚÿÓH7‹uçŸt}N$uË¯°yÖù€tØ­Éşä*ÎÖ9£«9óz°ßC´Eß\·AÀ·ƒ›Rã@5“86€‡ «™è;í «¹^ÍFUÓ ŒÍ€ÙR±±Ägû    YZ