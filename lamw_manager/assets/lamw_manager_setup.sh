#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1254971985"
MD5="f858c9d77effe22fbcf5d2d8bf1c00ff"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="24964"
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
	echo Date of packaging: Mon Nov 15 17:02:46 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿaC] ¼}•À1Dd]‡Á›PætİFÎU»YÊ´¾EjF}â|OA´ŞğJÍ)..IpA-¯=›± ¨I4×RÈbÂ™Ë‹§*¹æ›Ú zÀ®ãe … æøq–ê³ÖŞ»¨5Ök
áµ°"İÅämgò¦Q¶v1ƒ#ÊÚŒ·Ö È~|İ/îõÚñşŠ"Ò{Hİüî‡lG\ßù­Á•xo'w6í È® ê!íÄ‰R¼Ë cØ~£'i€VtKR(åóî€È×®­áÃ¼¶aÚ‡ŞãG—™yÓŸÎëë;¬¦ÉL"‘¿ËnlSE%_ÙTÔì=]TŒ±®u™Ób£d¶s‘Šùƒ%çg*³§˜àR—îµ|FÓÓäüzR3=«q*—‹o2ë™Àß]ªèê]kçËÂ¬Ü³Ôıõô×Ì
+‰R³£Ïø0\4¶Š|}Àfï"¶òZ#zjİçÎşf1J`aS†ßÒA„Ö¢İ•ƒ~ &ÿo–´6%rÏ÷¿§÷è¬î¤€¼·¼#‚ôÏHñƒ>µF¿m:¶şóUİÃFÜ4Æ×Éñtä¹f´H†
D›}âõ üÅ=¨õ\½9: 3â†Î¿Ú€—jFü".ºu¼§V(‰o¸¾3.P¦)†LSS1±ö:,:]Ø~°˜U«0$f’‡§tE‚|m³BB¦ê`u°÷Æ­Ñ¢JªtobH°ùG~ÊFHùe„¾Ér=Vµ‡Œï¸Áù®ÉwÔ¡Œ1i¦  Ò<£õ£d~@QİcØ´ÒÄ‰QÚ¹N›5]WÙäÅõ}öËw“¬‹¿&k]nğ=5Ì÷´Õó¯[@ÑQ¼³7İL©¹ƒräPõvm‘ºóCX®ÎKó?}0ø#Óø}‚° V½òÆ˜˜äcÖƒ*ÅoAOö^AWgróMÙÃá;ş&¯Ápz…FZ5©GKvÊ6Y¬Y‘”Iè ©kÅ=c_ŠLØ6ªCcé8·ñ³{ù†&*¼Á¡jô‚"–€/Á8«—¾oè4WTsÕò
ÖÓ´«dO!\­\½kÉb$èy@ÅÉe0|™¶É»@øö÷êõÁ5u¾ü´&a€ék4‹8Ç/ÁÜ}nÃrSÊ]…<B`ï%¯­RÚq‘ª¡"š F1§‚—¹YÍR³sš ÑíÃ8Èşïuièù.Õ§Ê™şvŸ3ß‚Ğ²Å$¼ÃLßíÜ([‡Mxúá×9%H&ûÑ®%K=gš4Šyq]Âş
™Ô.¨wucÂÂè¨‡|©Ì¬ôŠûİ¼JóBôÔ³È@ßë=ÏØ+c9qZ­¾P.
kMÏÒ)SÜÎxwQ£†ƒ-È&œöèõ×zëM‹#Úû›°i¼Saˆh• ÅtĞM^-fâlÕC,PdI@a½+OÙ‹–Õ'E–*P!~“,À±íšêz·±ü¤È,ôş‰ '¿”›!¯$¹"ÕÁj’{n‹‰ÙJ=‚©Ò°ÔıTa\«P}"^ı¥­IĞk7 ó_B®tHÏL<‘¥ùNy™!kìŞG
©uë?7ö˜TÕòzúiyD§œgš•O;ˆŸ3³˜öåÒ‡öåÕÁ,LÒóÅÇP3!Mç°m_Û 5ªİqn‘iJë"ÊÒ^cñyÇb$ÅaF{	ËOn0¤XÛŠõpY§%­H š7gûáÖñÁu™kÒ•£aT2ÚxbÉKfõè;Æò&.»øx4òætND¿eäösšÛ…’ÖT$Æùzó‰î§mc¶6I(Û@8¢$|}ÀxĞ]Bh´:‰b¶xC2—´6;:pì|ZFş€Pç“Òº-¢ÿ®"ñ1_â?šGÿµ\øÅá?ü·W$—ÍmzB]V½ ;ÄôßHK@Ó ibDÚ…ÊAqgÀxg%­Oúƒóqöfë:*¿²™>k$P‚&±çidĞ†[…Ó¨À¤´ÄÈkeìâÜ ¨/‹M½‚Æ4Ş@j&„ Ó wW¼z {í:[	q$®ëPş~õŸ5ÆDv·YtÈ&{­„LT3§®Á‰”:®
a­‡ŞF¿ÜBEGŒ·ƒæğç%CÓ¸÷âÒQõ«BÀYSØbMİzìğ–4ë¬?Ü¢ÁyE†[IãÊÓ'ª8Qâ|{š…s(Ò
qGıh±³15ëÅmÑ³Ãj4U<$¦^.50ôíGäz{‡ÑdcÖ{!¹!Œªë*PÁ|mÈü«¢~fyŸOÏ/ÕvüÏÎñ|Ã‘VÔÏh$¨s,‰÷ELk–¹|­“ó D8ÑB(>Ñ‚Xgıû¿İ´¥‹+PÆrÇ#ÌÅø§¥ "¬™.Œ›‡J‰âÁ9ÒıõNbxÅ[G9å<$v@jšúiyğãœåùè£ıS°ñcÆhÊâj]6ê 5»sĞ	ËÍÇµµe[Ëaâ4¢‰G‚	¥¬}?:ÂŒß—3ÔN$0ZéZ,¬~Á¦/]5¨Ïúé9oíÛf¯Ñ§%«ĞX3_ÍÅRÈ‘e/ÌŠ/¿íTKdXÄ%’åÎ7t²“yıvTê&?ŞÛU†®¾Uš|-&)\_>»ı "Ûé	v¹¾Û¢íòOöÍ¾|Bf\ağ9İ›(ÏÊu8ÿJ,¿Ìh*ö«ûjĞŸ+oÊœÙ¸a¥Œ.Ôx·fäŸ{g¾¬?.‰öØœ›#õ€­ ŸÆı"º¼â[¼­S¼o‘²^‡¥êõ6rŒi±ÒRœ ÄíğSb½Ğ<à
‰êÙzLCWZIj
ë·‹ÈÌª`[:° ¼	ŞÑu‹ä^n‹+Ò8WpæíDoZU ïİË ˆ9YæuÈ2m@{ ÎÜL%ß…ŒŒ¢s˜¨%'µ‰gk@½Ò†$ŸóZÍà¯D]ûùí:6Ù}K,aLùÓzn^µG:“ÂS7l
^ø_~|Yâ¿~äÛ®&¢ùPşÏâƒ“¸ÎrO¸êË“<ãœLãVWxäÌäbì?ŞéÙ	ø; Ÿ¡'XzqèRgî\‹ÈWíÁWÆáFÚfÉ>;rMJBn²3;á†õ`ÕPòFH¬Ë Y©ª9+zkÇfŸ|z õ_Òˆ?¶n»`×âÌÎo ñæ_â=1JõœÎÓâ¤†‘§Š+®àÕI"S¾ƒ…~(-Ìö30n›ƒ›C…‰\¥YöP¼&Èº¤ñQÊ˜[/+éÕ”m…=6’fÓÃ£şZQ©§Íı¤S«jGï%¢»Û0CwŒ&}Wş*Ö%•íù©#×Qœ¤eâf?Ëm…Å.½IhºÎ×	·òã»ôÔ~‚…Œäš›$RÜ"šğäî‡-ªÙ²¶Z” ÀVÇ*nAÆèÚH´yî‚ùÂ˜ps¡®•ÏíÊ§‡,Æ&e/°»«ôUµ@õóeD^¸‡""Eğn<¶P¿ó¤rå^Bsw++Ëä%C‡qÙÈ1ô¼EwÛà¾Ã2¾1î¹Î4Âb·[vÕ/ª[8ÖµVr³]•›32U)šù’¬UÊªÙ®Ÿlún‹ı>İíÆI”5Öõ¶Æ"•X&D;oª|Ë¨#­ø’‡êÖÎ¡ËĞÈÊ_Jèú©ÇêÎG³ßİƒAXˆ~> #Vä]Ï­ùË’êŞPµ®çÉÂ2¾™ºŠ>F›¨:@Uz8<(™}Ğë×kí[N” ˜Ò(K €;¼\#o08+œgg[MÇ/[È!^®’:ÅibØ Ò÷ í5¸µC‰ÜäŠ»lı®‚ÂÚ;’£ÔØœ¦šòd—Ó•í”=ğ/ùûa0¶4ü‚gôÊR%´¾<(-õ”y©bÔèjuüUó•‡ q‹Öšîc<ıùä)¢Çõ‰2
)Fw;n$è²)}5%	°èDf\ö×m?V­UŠ\éİğUDè¯ÏœºÑíâËk•¬E-HédE`¶#’·«RóBğƒdkd}éŸ_ÌñğŠóà‘iT? .MjU!’.Ìı¢¢¸I^¯ò	•«¨›F.ÇKñFQÕŸ¦òº’c½ Iİz²—j@ÁYĞkYË² 7Æ,ÜNŒ>Ïó/fY„…³!cÙ\®­üE\s	“Âè¨Nf>P†¡ËŠÑ|o„Ö1ŒÔ•i|&VaËSÀGI“ªÌ.(,ÉkŠÔ”(6×ëÈy‡âÔ^¯lÜEõ†JTôËÙî#b¯“¤ğ›ØJ@pô÷¾}tˆmÆ‘fÓ61L€ú4ûdZu/‚dãŸÒÿnË†,	Ú8SØÇÙâ°–ÑcÊ²•ëÿoşÛ«ÿÄ`ì[UŠ>+6YÛOdª5õpõ}kÛÓÃ6õ×ñ4d ò¬¨ |H°>ÓFT0¼ÑßÀş)£=3ígš¡qOß€À+`ê°OÀ4Ì¬gÍ{Ô~ƒ~ˆ´ŸÀÅw‘_8>ÆvI°ö+â”½Û˜&ÆscÏ¦E-a˜^8­²mhõÁ7L+	D.ŒH½ğ<à›^é¯„³Ğ³%!Zj“¼¬NùUÛqb¿¨«éJ®‹¬Ü6)…·¡ÖTİ9‰åøß}åïakŞ:Ó§"õø4áĞì¥zGP(_2)/‹ÌÙô	qğÚO(<'‡Qqœæ]
Í‘U€œ£6Ö’×£|Ã¸‡şs’2 ½çUÅ©¾ÏQ¼ÈÍ¦Âìıy)éSõTb7=ÏÎ7$" py?N‡Ãñ>F,¤8PÛDyô˜fNU*!£[]ïtˆ¥8Ëğg%q­0Òx›U³È•áúb™&^ª"u«ê•0ŒæŠío¾ëqll+vöOŒÿµ)yØ^î¨´ÆÒ›;ˆVştu¤YS«v•ø€Œ:U‚Fú‰EüömÏZá¥½9VöL«¼¢ Ïµ–ë{Ó[<³“7ÈñÇåğ2¢YUµí–:?%¹Î<¶7ÒGÙôÃ Íîk³JØÇ–(e¨¨;8ïÕÖ„XöaHûÀÖYx§GêH'ğf"­®zµ^èUK5€	0áÉ ’àÎ¶“ê8Dô&°´Ç®øÂD/Óaf®fšÆî^è1~U–!9äÏaH
§R¨Ää´s{€xş±`H@‹iÀ¢r¦íH¾ô>_"ìçiLÒŠÊÌ6‰(>OÅxªè[êã÷9zXKbóÁÃÛ¢m|¹–8à5GJ©¶äpòŞ’
éciÒç´O$àG»ŠcµB7ËÁ_6ïtK—çi¥/…§÷ƒ‰0…ç{ÎI•»K fx‹ñ!$K8Y¨ÿbZïìı•²%¹ù/…|k‰îsš>*jßÄ ê¹ñO5rµ‰StÂRE'hh,Ş·qzöÜ¶… ÌWĞšøp¶sLlÒ£¼ƒvŞ?
_©Ñybâ+2BÆ‘Ï¡¶ º»qzÛéú…«?9	“)×ò7Û¢Ìg`ñ©Ğ£ÿN\EºûøÍ¾´C¥X=j(5ã•—¿ŒYÊâSÖÒ)†ªü<^õ•™©¯Ÿ	šNY¯ÒÇÄ(UÉ¤X(âßÍÁœÙ. İˆâ»kë%ÍÒ8İ®õCU¼O5eR1:¯øëzŞ\âĞçÈóÁŸà¾Òü>™W#c©£]?Äd4¸¨d@» Ÿ5—»¢º£Âhãxv1$ÿ^3ğ-ûÔ ’fæÕbºÃS‹÷âË É¡rk’¶Şõ¿!rîõß¢<«1ÈtàrÊ3ã½ë=Hä/\wSTjÙM‰ßÅ"5"ú •³Ï¾ş'ø9«Lœ"…v„¤Aù`~¥šû¹í	®ªÃëänÓ³§Á.191ÈßD‰‚çõçZYUw•qp˜`z•hsşä™ÕÂÉ¤{,Õ$ÓŞ:ˆBC})/Ø3ôÆ%ôfW¿æÉWû¼Tôi^Xb` º\Ñ ¢êùàHJÕ5q‚¥t—
~|µXCìˆ)ƒç©+xˆc]o=ğáîG¥àSux{¸>&X~ĞgÈ\‰¡×¹¬¿éÓ8»»¾š2Ù¹HÕíÈ‘Pˆ*0[	ºMí¨%÷NÜÇÈY·{ƒ~Xg±ğ5\!z)ìlÈ–¿ïŸ:¹J>T<ƒ€ö&ãİ¾rÇyÙÎ™x6¤ıhùõ„çóKÜ¬Òál‹Ôú¡ñ:ù8¾^$²ˆÃ0°BŒlÃŒ;ÎòXÎğ¾HœÍ@dóZk¦“b“=¹1èâx@›gÍiV]–SŠœääEkrË«zì2 «ySş©¶Ø¿¶ø}ÿÈÅá>F0fòX®›ï,ÓÅ±ñ¡KÁñ	~øVMpF/•s\KWµ•.ğ–>ªó>}CéãHëô‡qZáêFÂ‘JY_˜”RC¹²~²1gsŠşĞy€­ëºBzIÿ(íÛ8wy°ÍAà‰S0º?~f L|ÀqÕ±)¯r9T|s–ëü¾…*À±üE†Õ—poÑğa*ˆjİ_ğàUw&À5ºÚˆV†¶Q§T¿âÎ$>ø¶Ë·9±*i\z
ÂŠ6&Cî¯¯ÔÕÏ¦v?-LäPÔ¦¿ô‹Ñ˜4Ó©‚ò›íN¶±î‰“|„­@>(ve¸1ço²fÅéÆ-‡-N›{w:/L¸à­°ŸN¹m3àÁ+Ça–¤0•iíÚS¨‚*\ ±Ëè¦§é©ÎõèÌyIÓ‹‡}<ãÿ7sµïUl°àOF¢REÆÕÒPl:3•Ckö 0ÄAV–Ì`p Ö{Zÿá¢ÔU©Nml?42¼*•a†,°?*ù„œh*Â4]N¦ƒÆÓ5–fşÜêÓ;™~` Æ6”¯ŞG¤9ˆb­8Æ{ñAùVã-½DQµêÉ(ÂRr/òüU^ô-7ùFâ®#r¸ØYWÏÍYÔFÑ÷ÓÑ{‚ÔP·|$vâùÅÀ[aï¢ûl¦Ø!Úaì.o3×¿ûñÍŠÕ]íËGäÎ%*‘,·÷@ĞïÁ-¶u(5>9ñÚ,A×]À”×Md6ò Dø€Ğ,aˆî€l¨â:›60¤bŒyTå¾íLÈ1L½ú(	p<Då%¹ê†“^é>± ]õœSÌÎ<¨h|P6o—ª[xèï¶š¥‰~¥*¢VDsOˆ˜ÃŒm&N=^ûîº¨jÜÓnî˜p©Æ`ÎL×uĞáD:=WÆı#¨ Ì4Ø5JğŒ¼ë%xÔY`éG„å„|ª\Ğ?XN0›`¶©­6åÕC=e&LÏ|R’Å-²©ëvËg°X¶Ë„Ú?JàÄ¹ãrÃ/MšØ–éí,"0®APUğn!q¾ã[ÿ4ˆ'_tûHüBŠ°¶À	÷gÖyü0øGêkßE_ºl¼öi?Ùyyº´Ø¯Î2·pU?ÓË’*›	`ÔY•}ú€úAö0VW§ˆ¯ d±“|÷©}7#®”ï2ájPXg9zQó¬¬¨<ğzZ5kòÀ4Ó›a1Í ğ1?7ÃÑÂJ8r'ñÀƒ §Ë²FÒ8Ïx`ä°‚ßk?84 ‚Ÿ8ò“a&€©0n'¢wÚ;Ê?”Âr1éNaÎUâ«’@s
û<7íÑÑì¨‡”[a¢ÓµÛ« o¶¤*†e&µ\~Ú¶#§rèNvµ£s'pÜVÙÅKh	Æ¿)…"@ş5’s¤X›Q#ƒ#Éøô‚vÓ Ì°¢ÑwiHI¨YWÊ¾üS>óVfíË."Kd­Ì µ4Î~à«9xš×bĞµ^™‰ùè²½ÙiW]ßùSGÍ`ú´Û¸Ÿ´®`ÊAìÎ×ÇË>hû™]Û–ôêıíç2+€‰;åÄhHFÑ–ÒìÚÁ·Gy#˜•^Æ¹r¦5°mWÅ!8G
jD@C¢€=U{˜™x>¦éœ¼F—–¢¼l=x—qì‘¹w°ÑÃ…ä™lİ2H†h~&QåK×èÒ ¶†~;©V:¸Y à´W˜Š÷uğºÌø÷Ñ˜	àz‘JÄ³ãH8ùÅs'³†z€Bç¥Æeô¥xº„ÒüªÈTïPî¹3 ûcU
ˆ;4¢ælP‹Í	ŒmÊ ¿ô_yMa×ötø€¡jÎÎ9à¥• X¬¦¼E^U¼M¦PìmùhdşÛîëvxã¦Sï,Ë÷HFJ¬W³ë`âöYÑ­s!ùïõå½8óÉøŸÏ??ÜJõdg3©×ğ„³ÿ~h	Ì‡°î†TØ}6ªPGÛ>vÏŸÜ¨°åÓ˜FÀ¹ìïÃµ€åÓêD=gÅ4~«	O»»ÓiHı/7³1p²aâ‰!Qd¶X=jgk‡EŸ¶À+ô·¿5Ã¯ñ‡(sàçV42Oƒ?4LØ‹¸¿{åànUMLÕõíş³.õº`o9ÁˆDüŠİÿü|İğšÓ¼™á8^,f–õ]h?¬Á ´)G_&‰Oqq®„Çúãb$•-ª À:nÕF3
Ğ½×v"Ó0m”Ø¥¢|YQ=Õ8ôğ£»"åsúø\v#1°½4˜“ë8Ä2İ={=g;'†%Y]ŞÍÚm2-Uìoc·6„…r˜På®+Ï °†˜Æ’¶ÙæYéx.HĞŞOb2ü5®â¬¶”OuºÇ`Yÿ—|gfƒå{büÆÖíïÃÂ
©>2¤AÔYqªş‰Ö1ei{`Ôƒ Y'÷É†Y›^0Ò%z]Æ9ßP/³"‡GëÍõšÌC*ÀğİêâÔšÌÏx·û\_Iˆİä×&(/¯I´©"?Æ‰= 1uI»„TxvÒŞ¹–Ë
|¨/ípUÎ$éäå<²Ï ¶–ÊH°FYVïÅÍ^g&¡É5;¬„4HúhÅ×0{X«oôı´…eÆ##Ÿà«Ol“¢Q¤‚´ÄèµÛsòé€V¦¨À§´éÛsÆÖï@/?üÎá$@ïş<e¦Œ×ƒ?ÒQ@3–°Øóë2ş›E¹lÀÊ¿§×,õÈ·={İÚRi4­wŸWñ¦Ü{Ä|««g`¢£•G#ÙOÌrÜv#Úxúb·Ÿ/³>w¢N”½´>yñÁuXş&åø+«ğšåõ`ŠJËF/Ãê×·’qËsz/ğ„‘Öô­„sQÒìN(«›i‡ûX·sT–jjiÑ’Ú=ŸĞêLªx²‡ˆX<ÇG›ßnŠLX¿ÑE“,ß|Ää`×ÎÊŸóŠ<Ä¢áXı)êÀ³³¯‘4–]9b¿½7Áø… t(àºòí+F¼lD²sñ\İ’qLÇI”ó|2¹éà¦ñ3	¿Íû–éZ˜FƒäqÕEÂ~S!ºÒ1Æ$–¨à½IDÊJ¨$VYd:HšRåàñÈJA£ô¸H“É¯Ÿä3şş®í)jılXÛÅÅIÚt÷ÌU)6MXk9Õ†í ©ÏÉE²€øó7*Ü‚K]^'>¿â
0ğ,2PQÑcÏT¯DAÛ¤Tº»_±ƒcıjB§A»Ùër­ƒée¸Ja°Ím…cÒıÈÅãš×o³ÍáIƒôe§úê@ÁaV 8ÊV‹‘ª>5\M×q})'ĞóCcSãk.:=kÇ$Sê'ŸVpİò	€'šÌ:°•ğ?Ü7Ü¡‡[ì©‘¹N>ÀL†©©{äªÛ¶YÇŠÃêÜÄÅzPµK«™dk¶‹ÜJê
æp7Ä‹*Ÿ7!öOÜ·…?æ)¿X+)B2p¹FTE/I'u›M*¿Ğ·?Jü»lÔñRšÄ6Ğû=ù%ËFâ/Öƒ;íåaêªÔ¥…b2| óñ×¶r'u¼z=	‹Ê&ìù'6Eèê“™€cşÉ¹† ’QwÅ
B‡BcªÄêF©_f™Dá÷&E˜yIºãÏáçÒÚbÇ-§Ş‘Ó›kÖbivAæ¾Ât Ú°Âj<5÷Èªh8Ÿâ³”q@µ'ùî­€®!xğ%‰¹‹ÕÏî#
’öˆç£±NãÃN?VÌ€T}óg¾¨Pb*Ì¿œk.¦%´šÖÌå»±¸:üÍº<!O-sıÊs„Dş×e8Ö'Om†¶3ô´ Õ çX·¶Ô°Øp*Jê÷Hù¥]å®5ªÑ¯6%©„›uşœ±ëuş€‚^ø1R*¦çšëS†AÈZÛOœ}íKf«~Ş…<¯¯GíÂñ_rKˆİŸ=Ãé¿¿÷€›Ú†}’çœé¤fõ%¼Ú‹mo
Ûœ|b–4—ã‡»‰–Ãênú0—ğÇ(™{8øŠÓ¥ï¥ şîk”`Â¸)Eó$wÃ0?±0¿Á›ßJà–XÛ
nÔÅ{ÎufÎ İ°v'	tëNËš”8,Q]Èi__ ˆˆ íúgFß}°³1šĞd„VñÉ ©…K†B¼\NüĞ)çJ{…m`*ŠyıÉ]Å´q HuL±'@Ü‚ÜáÏFwR.$kéÃ/™×3|/`¡á¾r¹ÊÁ&
³L°üK¡÷QÎÁ-³¢•<²‘‡;‹ÏrÒªË‡¿o2o®
j±‹6n6>œ,±\¡Èsw3 ÷W_Òÿ‹ ìÎ&‰÷ô’˜¦>ŞÛCõâÑ¸†—‘waãWÇN*Ç)Tøç‚“Ì1`h=5bËˆ7ËŞ¥æ|Â“±—¬/°ŞÍ=IÙXOÒqùòª?W“ÃÙF+9Ñ,“wÖOv¼ŞÏ¨Ä#s¦¾£¶}Bı¨b{.tT¬U;ZÏò‚ØKÂ²¤	`Oø"Og57vy×Bj>(¦N(ŠSƒÙÒXä‰C>qj.@s~5ÿZ±d4Qò§÷¦=Å1¡œøá%/¼¶Ë=AğÂÈŠYÎ+O^²åÂÓ6}&Ÿ¯M&øü	ÖåÁocY™=Ò F¸¡½âJ	½;,/Ô.[«‚Wfú{Î¹ßJûÅAd`¢Ü›­‘_$5Úh…êpõµ£C‘”¢pËdj™©›&&Íèú­<•GÍ ÂCîG©›e8½öÂ¹köİz	ø SCÁ®	ö±èN.+ëSÆÛG…W¶J˜4}w<[¦‘civfÖ-ßKóÉ$î 8-İ¦Œª÷˜&†?ÒY±õ’Ï¯*áŸœKåA‹7^½!æ?âSû[S/ƒ@IÚ€“mËuÉÉóİä§ ¦ËZàÚû_¬ÃÃ8WÅïI±s 1QøqüCp–ÂÄè=`ê(¼ıÄ´›h¤wñ²ğûÎòƒE#ıúrì/üÔJLÉ(Ş@k¯ôğti—•¢0¦²¬Úkve! ›ÛüT*CâmJF…Òø;*ßsÙ/u"<éØ¼NŒÈëbxq]:Z…¼¹èŠ8`ç$uªUšpãºE‹ûƒYh§îşšbØŞAb$‚s}¶ œ}BP™ıÛÇ’İÌñ™©«B3²‡¶-ÜµİYróz³ép{ƒŞî†`UF‚„ v |DC?OZÁ]X«ÛÃ^¢“hÂ¾û%s|6rÂ*h¿ğû($¿/Ñx^9Å9jMıµ<Ê®ï‰"ø2máq»qMİÍå=J[ì‹Ğ¿ÉªÚ–lÆ×‰C’Ó€ÒºÜŠ¿âá½²À…äna%]i0Xáö¹C¡Lc×;ÂFv†µF(aåíRø¤m?éîf£ãæs+zO!*x–ızd¬£²=@Óv_ êL{Rg)¨E©¸·®FN;‰u7¹@qîÃ{®ñè­këõ—o‹+ùhÎX¶	R.İ„1¯p„‘1$W\Í­:÷Ké®ÊÕú²ÿŸêÙÌ´û¿±€à4uµŠU<íL§.í•xÓ‹ “üó*)ƒVëŒ²WÎ³6EÙxg2ŒÒâ˜üÆ“¹DÎrUoÊÜCÄ…³Îô/ÏIH(Í6ùÄç•"ÑåÈ±˜K	¾¦£|¸l_*©	\¢oöG/“xnO éPS)koô…¡ëHeL¿Áç'(â¿ÍGüÀ¥&ØP
1ì©¼1 H!ĞÆ–Vœb +ï7(ÒhüŸÉÇ8sx²Ì(©t}ËX’^éÊıÚüATRM¢©;¿ŒeÁZ:Í:d˜çÓ¢Â#°5ltæ¬Rk¼ú¼/d…®ªİ®9;SwU¦"7qx“Ç2=ë,.³ÌÂ‹ÕûáÆOe€}<Z%]Öœtõ÷ã–B¨æş
šÈhğç’¢ĞÌØ¥ş=9±<ãÛ¢”yÂ/1…\Œ¹«ÿâÍ½}¸+j]"9a¤ë1KXÏ4<ß?»âĞ) ¢å·VéXî-Æµ:;	sÍRı9Mü9ùò×u„u©`íæ:^C´Æ %ÉÓ`óÁÕB*ø¦}?²ºÜÉuvÄ¢TÿMa¯#ı$¶Ñ4ÓÅ-l‹qËKâXïİâKá-Ò`ŸQ|T¡yÉ›˜ÂTy¨1Èm²øªµ.óCdÜVNicĞ¢NİºÇ›/•wß‘£).§çû)ÍÄ’7:†.ğ—êÄ´1úÙ.=‰5,ÓyëB,¡'.«oĞjw±ñæáW^m®‡İŞV Öñ ¤{˜U7a-XwÉ!võãOs8•2YèøÆé¾K;›Í“«ÓÈê™c´@Pã»Û7‰µ5p1»Ãn1¡Ígk†;)D½ÀšßšÚ„Wñ=w“Ìv\—ª×¿ö©IBº@?	fÎ¨×íLñw…·ïÕ‰ĞCxŠÂ`¡U©ù¿¼°=MªvLÂĞb/ûŠÜ€Àãò“Y^pŞ¸·ùÚğ®2»‚×1ñ·À4y»è& f‡<sæzÖxBÊS{j9PßÈ°M«MÔ/Èât„=	s:S_ïe¼5?Û™•Ôè¡.”;¹Rdd\8'¿ö	±Ã1Ó=o-Uf^\h&–»±={Ë~cà’àõu ­•oc¼câ¥œİµŸı/À(èëß»©å°_^.·‚ò¿ÎooôI§„'Ì,/ÄAÄFàÆÎ´ÆÑ˜·N€mWp¿€j wËc#=à?Ìº	Èqô§E?güxÁ%# “aÓÈ£!d)Ö'×’8V:6UÇgv¨J/=w“›
?ŸQ»¦ÁB0ìØ‹…–½8øÏ¹wt@şõŒmC¥C•"ÏÆµîtpGVã½e,k ®®İnUÁŠC–xq_Æ>A9ÑÎ†'i”«ìT9âŞúR›¡‰Úy.ì\ïàb×9UmyÂÁèàÄ/!yÅÃ2¶9çÂO/–Ás(¯w³O;j·2‘²«â¢á
@'ı«â.›ÎU‘ÜºfÁ¾ô¬	Ú	(£}£ôKOôM¬ş<¸Yò¬‡®Ú4Q´ÕQÆ“Å…ƒLè… ïè$ e9|ÊñjÅ0ĞS“(õqğvZ!±Å$rÜA8ƒAĞª©ø­[ZŸØ	üøşAİş5O”T¼f:Y¡y,£`§P'‹ø9˜xˆÀŞÍSÇ€0 ‘
ÏßÓ`G´SvÙx6pÄIµK”x³åº¨+î<75ºü3×­ñ¶"ım³îê
ìnn(M"à/¬—ÜÇÔ`Ó+nCÃ*[˜6Ç³(ú„,'Ué£&1röíRæ:Ïw™4‰ß[´ı m«ª)¾xô8* ÆÏ‰¡´0uNi ‘ü!îowYÚ ú/\X2ÊU¤½~xú)ŠjŸ¸ôX¼ÚÇS’lòéÁ¬Õì?¡µÁyØı²Ô4lÄLæ0µk{>Fèp¼4Fj§šë:UXíÖ¯èO>H×eq[>¨ãÉó†ÔdÇ/¶%Šr¬œ`#2z^»«ú*‹åÉÀ‰nã±vğØ|9²8HQÆ±œß$„%Y#©‡XE+ô1kç_m
‰ö$Ä~ş~ÏÕŒv­±¸dÇ\Ï´c«+¯§‡PE;À(ÿ|eY¦ª†Ü×Ò“ûWÇUô’l•¢6Ìëv0©œé_h.(Õp±Ş/öVêÒë	8$’Ppæ€Uy0×î§€(ƒ²ÎãíÕPy.>nq§Øÿ<4¯íò­×Ãiû	¯?Üğé6G¸ó{½ Wa“ùš6¤sÅÑ0©ë.WógdC™öĞQö9î<è±?A^<{o‰<­Ä:ğe_ºlE{Ñ¦ş!œ	‰0P,ÑòÅÇªTyÇ7nXõö*Àğèà³¸G@ì‡·>4Fşø{-i.ì¨î<ña[îşŞ6XëšéI›‰iâš%Ëˆ¯”
š½ËH-ëm=lÉrÜÏkÇ Ğ¢J–QxìH
%C5dh}Q¡§ëubÛ4À,8‹ƒ .töö>§îUv±És&
]]×XĞTloÚˆpÇKÇÚ× ø-èVLdÌëILA	l¸3ZÜ%It8>QÔM^@(°(€Á|¤dœ1 1öã¯ÃÀêÒ9/ïºèP¤˜„±2 >Ÿ˜ÜjıU1Ïr]µšğÈxı2VUI_z¾¾¦ñÆ/ĞêGÃÕ1:~„·©J¬¹ğz¯‡Œ¼šÏ¦T-­Å[Œğ¥„”±\©äeîS¶_awúº>L²ÆjwœŠ…³î¯W ï7ÃKğ¢ˆj¹^X¼¥Í Âjàz
V÷ÇÒ	HØI»€7<¤E»)E
[0]Ûiíöı­À5 ë¬€aR+b"¦#4?}:nÊÒs9"ÁÄDëÌÍñ¼ÇŠ®pCìäÖcë)Æ¿ñIqøïõ@%2›:s…oĞÊŒ²Q2@^Â[Gï¶…dlôfX¼†(İœ¼ÃvFšœLÍEæ~§)U¿`1œŸ³9âa ÖUI>TñÕÙ$OûŞª4*TcÔ;órGvJyÚÈ'=SJ†gÌUWŸÉî5D’8
^ªáŸSÁÑã¬çlûM“Ômê{^,WÏíL•ë‹=`lüÙ‡‡?Ì×WgK06á“m'l]³ñ!™Şµş:dzİó³B¡úJ¶~©«‘Õñ£ƒ“ågÚÀè7ßX[Uç<Çİxğ?àañİÿˆÓmT+øM_SMÎÍh‡tÎVÛzQ¯Ör^³5u–2z-Ì™UÎ LQëİQ˜üÊŞq)~0]{Æ'¦¯ÂñùáÛbçk”~éÃşSŸĞAÎö›H–I¡°rè^¦Sß2éWk^ŠñöÏ@,P³	¹&­è& ·µãi“_+Ås®î
¼Lá–WİmÃ'S÷&"¥¹ŸdY:FE¸iS
ü5?˜şQF6/¬oé t¨“´ïçV<#:ršdUZÎ9bh -Ûís­\+©ÅeCàùª·²ÇŸNIHõpC{Âù(9xà‰şün$¯ª™/hPlMoâÇ´Eóı+
„8É”ZrÜÎza@|&æi©›ñE0ÿõãçú5K0D:EÓF0wñë¿|e¤?©­é†…»Ds<5Ÿc]µâôB½"r^m;]ËBY‹~¿ĞÊ)µc Ñ^l°Nã:&yå‘]€Î¸\_ûS˜y_š#£ZcKæÌê™ÉQ?Ê¾¦wÌã‚jíüs6Ş´ş§ıB;ï79à:Sğ5)° ÚşXÍu%JÀ”ğ/fµƒâ+E‘öá82f	jÿøö¡ÏNÈa…µò>}Á?ŞÖ’[aËéT„!Š-&¾B {!ò—_ë€¶Ï›ÿ<ËˆV(?ò`>ËmP¬´Šg?ÒV>5}‡Øg‹Éù8[¿8»Ù
’=N9Öğu ¼ï·>Yñ*5÷³²80C¦Â÷nºÖêàn‰3J]œEÌè‘³¿KèÏ¨gzÖB(€§ñhZb^&Neº½c¥‰‡&úIÇT¸u¤¾¯CSâÆ¹'¨…¹Îu¢»˜ëQ<¬!Ø!d&8Äíñ{¾ù‰m—Éÿ+Y4n^†e­3¨ráD–hêÚÕB¬ ì‘»üw¶ætÿa
‡
[ƒëúo¢1ıQIÍïÄ›5BF0†Ï¥üùûG¹ÿ4°ŞHåz@û0Î§˜2× “}t\N3ã&Êm’à6³dÎò©œ¡©®˜1*wéN{ÎJxFH©¥Æd•ı.%¦sæ0Q‘×»Ô…ïCJÇ±?Ü—1î”šFáq2pQŸWŸ¡nXª¥NÆ
õñgCµŸF	×?¾gç5	@ä!@Xİ§g÷rBíbRê¼p,ØÓaQ…Â½gbS[õÓG(]ãÚgi¨şá;Ÿ QˆWd-D5¸]llAÀüÙà'#ªZ£µ_+èı“İl(19ßŠˆ:"á±ÚE‚fÑaçÈ9
şƒ%5–Ûş£¨n?ÊÑ¿·oÿ×GzlVaC!È&ÕoT-£-¹µğÜ¢!jPbƒúÿÍn¯y‘;7¡Dw`Ãdù3°$3ÇĞ*7a½Æ­`%f4ÙkˆÔ0b‹½ÌœÈ>b¨öiİ+¶Eü€‰öË®xX¿Ûf;ä	ë? â/Ğ£½–t÷:C³³¥`bÚ—xPßï»VhÁÊ¡šŸ‡v‰±8§Ï±< YÖÊ$‹³=è$û¢‡uÁÙ íŞVì†o!"àå‘,Œ 0|±…šúÜ%ù>TÿBUŸğ¡LohÜµ\²Á>«—ùL`6Ì’jšÛùdí¯ç^N"C·Û†jD¦û0%µ™hy$ ç\l—d8”!}z‰yRwšÛYš£FŒİaÛ–¸p:!Ï‹%\Íl¼+	.u‹e:7ÉË‰eiÖñ‘çO³İ„È[6o\)ŸMXia|l?kd`òıò²ºù”>ÜÚµ¬±ëå Åø°ìÔœÊ,÷ üòÏëUÇœP"?(èr¶6`°©1¦Ê»z8ìj%Ha©øfë}È–[³5xj€B8?r‰AÄYj_'A^fóøÉ­§RQU+(ˆ¹B‰ƒ.êW’,KRÊ¶
ø¼j“t¸+bî¿}L^–t—
}ğ¦3æ8ÛğÀû
V:{”5±Ü5 3‰ÿµó6¹P€¥VéAuíB"…Ğ ¯İÚêh"ù°ê~p7ål-¿ùŞsi»ØG©H˜É÷gºş…;¶m¹l´Ş_÷>ö'WÇŞßn3¶È/éßóş™ÊLsÍ
T#RPniíßÃÀz~†Ì,”LJ¬„Sh€‹c4Âıİ-®ûŠd»ü¸Yv:söi°U g³=Z€äô>LXƒ áÒ
Âá/5q“¬']¼ó/Iôô¦Ö„9¨® 54¦Y>}ù¾âé¸“52J‚}«HüRŸ‡õ›.î¿ı‡xR¹Gİ¼ÜPoù53ØÕâ‘Ÿ—Õí}kÅ0µs<Û4¨ÕÉ/ ÔLíÅLŸÎb#TĞWí÷Òn³)ìşŸ³B›nÕÉx:şÛÄ*8ÑÑjåÆ^3Q6y¦ÈXI	²Z*Í÷®zç´ì•zÇùç\y6}"é½‘˜ï˜Ââ(˜(ÖHKl+hæyä3YyçVÖošA4œ¡ºşGk7Âû!íXpÜRŒv»‘Wo›^bvïã¢ïP^­h¸çšËÌ! éMAów’ü¿Ãô^%ãOß¹É¡¡Ÿ”Õş¦£Ok>è~lïÅ­ÓÇŒ\>Òíë7í…ZP#(Px3PüÊ÷ÛÓ,,“!0´îFÂ5ökX2>.¡ 1.ÖâØ¤°ä{&å¦Ö1W¬“o.Èe«˜c´¸S7	b«rş`‚@T[Àxé¼¼Çİúí‰q0‹¡©jOmmüŞĞ6ÙÁÒhXHŸ’å»¯şDëëùÓR2ı®¸_úA_&aº´¸vDI¦Yid®+diÅ_6íæq¡Q;]‹04o¤p|œv@K„O=ç¶]Z’ƒç‚ehÔx†Õ_sïqí& ‚#C/ÉÃ†¡à»%šéof”ZV¨¤–¥æc©´„ÿäÒÄ*OVFÀªº¬rü_Ûi¨Û›“´7}—ùñ‡™Ú%¨âÉB©«©N­Çş ÀÜÙó¢ÏÛêìü\8šPŒÛôç%
ní#`ù1û½ ZÉg¼ä0	’_8hëú¥Ñ_$i“ÂMm«¯7ÒZÄšˆçÿ—vë˜İa¨…R•‚`Ò¯×µó­™­¼²*Óú›!s¤a*ÏEv¼b@=e*’Ş›³ÿ^•øjÆ°´µ%ÌòğÇ71pi¤x5š(Ü¢0=½²/¼ÿtHçò^¢]P]rdAH2Ö@ òêÜEˆùW÷8F ºjœ»G[b;¡î€’`÷í§5[àDXB@´…Úqwœ.
*öSy4YÀ€Ã½fqoºnªÄaõ§J›x±’ÿáË­_XlÉw\„;t'WÆÙª§³Ò>#7¶©n$ lpqĞWãhš3qş)0iæ–§‰Î­p¬5p6×A2$öfÌJ~ÛÑ)„ÓN,›?ÅÄ¾gø‹9:Hù¡iBVìÂª‡ÃPÁJ”¡ïâÿql`îO i¨G´$âç>õªmƒzD¡GÄHYVŞ‹x•]˜%XZŸ ½EU©(ôKï[F~CÇ˜Db‰ì~¾¹ìô˜a®z_xrBı¹ÊŠ2Œöã2äˆ2_Ì!ü‰¢Ü‘ß—¶³b½°xWF¢İYs&3å¹Vığ’Ú`!´
«ıQØàº‘åˆlšò“·è}) {°DváÈö–İÅ%jfÿ­XÛÿk¸Ğ±«4áƒœDœìèA‘>wŸ‡¾¤c<%¸û¤>d®˜¤Õ)dÑø-qP È}›ü	ŸLƒ,RÿHıé›ñİİ2¨këŠTC7Åe^÷-ü(ÇÉÄŞ;V¹O_pä^¤…í8ë0}¤â$€a]àúÃÔ°«À2O,ÁZˆù\¡ä?ü‘²&Ÿ@¿cïo9‘Y­çäHaçGİÀhú4²ÅEHÂó‘’›Ó-'¿Wgb,U*Š5Û ² ¸Äi‹SğE ‰ÚMj|6«?+ş´ıE”"¿'W)'Sª·‹ä6ë.)Ó‹ù©Š(ŒƒRÇœë† ºÛ+=é×ºí”tˆ~qöŠæÊQ$öòßÚÍïeW;ÂE/|qK/j²µÈ›v¯s^Í¯xd ß¤¡ÕºiT8B®
^Fò4¯®¦ßi†ÌMú<³	„úú&À¹é¥jŠI£YuœÇñ5ÔÀÅn©})hğü¨¢9(â‰OË0µ1úXßãEœ ÆÇŞÛØ•Ê"˜#a²ñ[¼SxD-k+,ßíî¨§,óOë•ìë Â¶oF€ï¾şxøY€PVfFy.
ÕìºîVlq.lP/B‰{QgÃX-•Ò¼äÇÈ´óÛ”ˆWÑÂúÜ7IMjù©£¡Ş¹[ÖĞí»œÍ2ë[¸PÊÁÛ.°4–¤Ô8$gôÔÛb±'¾æ	¼¡ı€ÓÚƒäòã™E¯_g„ª_÷}4õĞ¿÷ee%©qëü6Ñ¦”^6ã'%pB<¡jr£nj4›|Ïæ¹ºÄ³ÓƒM‡SárvÍffdLù¢•G²#%¹WDÙ"y/Ø]¥ _Ü[_=s®C•4iú	M+şÑ}KŸšƒİOgÏ/²â«1Rıª¹&°·o©A xR©s¾e©{Q·òMù~cÕ§‰e*G¬d5¸øšß¢èéöu´`syJ²Ş{`¹Zöõ‚í%Š¢$K…ù÷ájã‚@ıWwswD«PşÙ¢#ñÿ°]tÌy…¹îŞµ}@î˜ãû÷,4ß6\~fİRÑšT8CÙœFê:EDÎÒLğF’3á§uEÚ¥àôBĞÆIf\a9TuPU£l9ĞÇ]À”?!/Eş0Ñ^<FiŸ”ş)F$Â=÷›y‚58ZYOš•Z Üi¨ääŞVİÿÃ\vêypd²#©·Ÿ.Š2¾Q
èÃŞQõ7–»°Gş³¦ô|öò¤_Ñí}6–—Jè<œ^bİÛ#²ı¦«ãÃ«÷ŒåÖG»Nú¤Ğ…ÒP­ËÂ/LÜfò	fnŒ& ù,r«îb-±Ğ9·_ı>ã2`šøòƒÇ¨LNMØÚ2§ üÿĞ²Môô[šØ¬Àõ‘Mp#9ãmğìejÔ—{q“?#YZÏ’TóÕµÊ^Şfq.£]gxbKgZ,•“{B[¦’cf$2C»Âi‚³Á»e'‰†0î›s¶ÉO^†²xÉß¢6(ĞŞ6?ÎR]°¿³Ÿø>VÒ‚×)ñ_ÂÂ2.öcObz\w?i¼­äf!ãR| Úfkë’ÿ¨‰‡Ä-Áî-ÅoRøz"¶†Ûm¤‹
OéÒ³\¢Í;§•`Ë
Cä7X:›1giZ¬ŒLò)o^fzúŒÅS?»@\?e8{‹˜ôŸÏçús·æª^ª|†‹­hĞb;|S&¿t[”òp!°èï=,M6[€
øÙ@ËbË´ğ˜vß<pŒDCÂø¥4ªÑzµ¦í1"WqŒ7"eIYkÁ„:µ‰$8ÖgÚyRó#Tq¹GúÀË°šNx›ˆ¿ûRË
Û¤qÿ*ş2cVùj£PE<ŸôÀVõgÔ çëD½“ä íÆïòª©t5¥ª'4D×Ö„?ÀoÚSœ)DºŸ:‘†	Á” †3-Ma=T1wñ+¤?Cx3Tóİ¿^Aá	mÆCÌÁ0‚ÜRğ.ëØáŒyk²	ıœ³ìŸ¢n˜aÍêy·.­Ï¢«)
Öƒ›vx…Òß»Æ!ïë9ú09ÇıS#R“A—|ƒ&BS&Ñ·GøYŞ/Ø´Ç<ZûQêƒÒöoév¦‡„#€<…òƒ÷™éÉz%á[ÏÎ°—]½_Ê¶zûobÊ-q“Èİá!iidâVØ•Ëg˜(°Bq•Ìœê!ì0òŸ<¢^Í,hYÖ¤¦Ç¸ ‡gw{²q:ıaIòæÿ(?heªú€zÀïV™z,A%/Œè¹ğfÓ'€H@È iÍiÔxÛâæKÁ¹(9TGğÒ*ñ³óiòşqÏòçÎÁ”¹<-Kf®[ÖvQËIr\Ğ8¸é™A€ÎÅ‹ïó…ôp;¯Y‡~EÕÔNÂ×eàBÙ i½C!‚g8ß\˜÷+š£!+}éXÿûÿ·dŞ)e_MÒEç ªPMÙ¬û9¼0Å½™nâÍDØmî8Œfa‹àC°)µc$¢f‚u'2ƒO 0­ÿEİá0ıÈ Ñšy«ãHbìÀ/Š(¤DÆë !Í8İHSùqWX–íä;e•à=OGånnâ[COøÆĞJ u\_ı•S+aøAHrÿ—’ÜŸ¿Âtm%Í%¥ôÖ‡Ê¿\iáT¾}0»‹ÑI±ÔI¦%ï“†¹à™ñ‘’_XëîìëI	ñf:š¹¢´ØmÇQ'ªi„‚³*íÏ…FmËMö Än$~•S­æ[²ûgŒGÈz¡…ÈF»‡ŠÏ©ÏÀv©Âl<3‘úz“mµ/×¾„|é –M)	­n§«vic3wú
é9‹‚:åªÓô—v4Æµ¶Œ×ín…Ñï²KËÆÈc
¿oñŸÆ‹–2‰Wß—ğ­XaD5üzâïŸ«å3ÛO¡¿LvòlßùW~ıkÈ‘ù]¾qçwÊ=œÄ×õ7†³ég/“ã
œğëïÂÿ1C÷‚IrAhwõ5G?·Ë`EÉ—æÏ&VŒ…"Æ?c›«71mÊîö{bzˆEÿÄêH^²r}¾á òæö(v›ˆgeIèOÿŞ’çñã¦5OëC…»J=wëé³Ëuy÷IÍJB-2ıÍÜŞSØóÛ2cû–Ê4MàÁhìßHß(İRÑW´²³LÓ|3“À×aÛ¤œÍ¨Y™­ñÜY&´ÎÖ¡;Ë¯¾Æq¯Ö9Sò‡:Âd†{óÇˆdvì¨¶’j§{Á¶Ûzt¥‡¥¿ú'QbaU€çGúO‚H3±|zÑÍ+CíP\‰u0=E°õš€Û”à]/d6	PüÒc«)«ÕÊIG¥k¨ô×ñMlêîÉ-©LÄ´|:V]ìU9ÿ*¨êvÒB“4·Ê7½^Â HÏ¸ˆÅ­ú¹Z/äo/{ÖAü1ÉéÔù¿ézğë§2zÆ²™wÖ”j/ë"e‡.§À—N ãÕœ·Tˆ[ÄBø+£|¨¯A}¡áÚ·%®Áan¢af—L]í8j‘©o:@Ô'g!(<š'ÔDj¼çHórçírV†ä€“Ç¤ eª+Ú¥ì©­—fKw4tf(‘İÚE•sR†P”8'Oœh-p¶Nà„l¬z>:Ú¼ÒŞ™,-Œ]»^(lÆµaZ×nLìP–Ç‡[¼ÜµÏkmÃ‰ƒ2ËÔvÕ‚p¿
6»Ük2Œ%ƒ'Q;
ÛåƒNÛ‚ÇX$[!LÚè¯®÷Âa¥=«-.|0l¦Ù+‡Ò<s9Écö.5µ—”G˜ hVô8OØıã´âš–³m¶`èˆ³³xëM³ô"[š{D¨)£¡j Œå"eî¶Mºszğ,y¨×cw€Ü@"ÅìtÏTé¾İMvã/ÓÚyË×7ÎFcln»âÕvÏ$P‘~bèıZ‹Æ EªX¾™ÿ©ÛãÔz¦A¹]²û‰—ãSQĞïK#^K~‹Ii˜UL•¬ìKh­¤ÉMt›(ŠÍÁ÷_ÿ‰‚¥oÑÏ9UZ,Áÿõ…ÂØÁu!ïÈ®±ÒÇxü)Ç“Âx2ıfoÒhËVoq1p")ğ"x÷ÔUQÈòÓ›ör.2€cL!!9uQYYúâÉ‡¹®V={Û‰ÏÌéı…QÇ±¡‡]´óä6\lœWÃÜ«4‹ÔQ‡„ŸŞÊß²}] ±²e¸Õ–U)-KdŒ;¹h:vÆÙM~Uj‚^9lM6˜ñø8İ¤fåñå\Àá(Ø€Ğ˜»÷êC9·$fÄrK}ÂÀB×Í9r†ìu[] ğãÓ+²(y°ÃÍ„$69qé'A°U7c½@hÁºúõNX9½ğ•¿ıh$^¬0ZÜj?%ˆV€ãÁ“í³mä>6`r¡ÜL±á¿ùl_~î-4ıQÇÔbÉä›W#TûïøÁ4‘é8‘æöFF<1*F³~#mlc«ó0]AíËÇY5¡¶vCTärŠÕYå'š–Ó~Ì§ôçí,ÿ¨Wn=Nj·m˜[R'œWŞAÁV€÷í¶7A;T“„G¡ãbÈC àí…zä„*‡¿ØÔÎ‰—f.ÔG^xÜúDÙ9úlöˆs Ê€ë¨¨ÑÖcá•¡©œ®ª	ÑÁ½z»àû:]lDÖ9~=Ï’“w…]ã
:Ùß	\Ñ×èŞÜÖ,dÂ ĞNSe¡VƒLSØ Å]Yƒº‰é·[ú»cõèé¥ÀÓ÷?kSùkşhà*)q½9#®”i]‡‹mak"/|-ŠÌÜ××]	ÃP‰42ğåzF&¯ xXšWš@È²³·Ş»ÕøNÔFË[Ï*PÌSHlRG:·Oìµóˆ=,2—ğ8_·èÕ\ÈĞJpÖÙÁ¹7!¾ui‰ eÔQ‚#ànN÷/Õ+‘G!IGºøËtê¹=Ç!£ƒ›/j¬pÜìf@aá6öL‡L(J©Á!ÕK’(«óĞ—Û›¬Z{µÈŞ1g&aŸÖ{SéØñîË<XT}r_£¥Q7EšziÚ}ÛŸwkúøQWmK°LçM‘² ü<;/6×,·U	ÂR&sö)Ó|Nÿ®ÿÃ¯)_œ²>³¥kÜğã‚Ä‘#¹Ïé»7˜óÅ4ØÇÄ¤ò+®’hş
\ŸûÎ>Ö?¤ñ„û*læS¦TGmn›xáb CÏÆ¿`ÂielEïoŸvŸOÖV%äçöÙ0½gÒµ×3èe”•q‰9„§’·[[uLŒ)Åo¬V-EÙÙÇæ9¢ô&â?MClUt9<ÛK”£ì%)ğS²dyFŠ¡¿’sÛ²\ıáÀ¼Ï­]só4ª¹‘Yõãîÿç\ÃwŒÛ¥òîæ³q\DtSÑ4.Xû¬{ê¤şZ—/Y¡ƒQÊ‰D\ˆ³s’9á¡eÕ«ƒÃ	kæX}¦lÙe$£öYüB‰Ò˜£éOä‡ƒ[¦T#1‡DZ„ı"gõî¾{q»‘Œ<cQ/$éJÿ+Í²¯,#T2^!ÄÆH­ıŠ„Ô¹(iŞ`úO½?Iè&Id—QÇS‚ XN~…•=ñ™R¶p½“–ÑÑËnlİ:¥"Ü%›\¥Ãñµ”ĞÌo¬)OD¥“¾,Öã\¼âíB%ãìTÁË6}ß}FCºÛ3Åäø…oE¿ÒƒÖ<)Üj›W#tb`„Êò[@ËŞíÅŸbFÈØ¢ìqTnëÂÁå„ï•¹Ìîá¹½²KïSTİÓy}/%ììCN-3¸Çì:E8Ê2½¬ ¶Jd¾¥„oš/áß×®ìñU‰+ïş†%E	}‹/¾ı%…d àÿ´q|ŒÕ{Ş34¾+¡Ğ°2Jw‘ş&£è!0ÍO(ñ}ãá³¼ÊıñÛ7Q]kÂdÌUœzŠÁiîØ‹:s•]µNdÏ¤Éä †‘ìùÀq­áOõD#L%ÊÈî'+CÚAzyÈoo"lZâToµ1äÈ Ô*´«nœ[c·ÆBòVf«6ğhÿŠ@Zƒ…2B\vNæ”d_Kn¾ËÏ*ãòlKø\6ËÜb/æŠï}¾‹o/‡f« z¹p`DŞŒúodfº×ZÕŞÓk{[•ÔŒmkâ¿ÆÄñĞY°Üwxmg
jÙØ-4t£©ôA¸ªÅ€m(+£PbÚC¼ƒ|Ø!mÑŸ4Ã¯[§Ã~?gQv9‰pà¯^¾à!Y}Üò+$ÊE¥¨Ór´0"~½¥'oz*L¤ÅÁIE”ƒ¡ékOoˆw^–¦ÄŸ†/K-’öıDW’™ƒËb=ã‘CPø³"k&x½`Ï™€£hŸ,ÆtÚ!%H+„´
rLœ1ˆ4¯
yÙ©¥™Ç- *—Qæqó
¹ b4ş)áK ¾aèÏ ¿™Øæâ0'àu†U:#ïQo0wé—¢c'ğöt°Ä.´ó:W q€ÜÎ8ıš1NâHÚ”7J$súÛ¢ÁTô8caŸ+ë!ÿŞiBä¦ŸõÜ™´x¥ww<Ó˜X½D(“M»²ANA˜¸¹+fÁm¨ÀŠŞo‘gçY—nã6³Ù.”àN¼XÓ6ë³²³v”³ÃÈ¬añ¹Cõf×‘8¦ºF(Öè HÒıËåÏ‡J–‹‚İ­	ğLNL_q†¸]4=ï¶›÷V)é’…–(¤1†2ÓÀ-(GúÕGëºÂO{¯!¨¹Æ:Um*e£Ö¹ØN©Ó9£ÏÌ¹4f€#Gö
‘XÅPp¥À¨ ¡dÊ-Ïwbò_c,>Dá¼=4e<¿‰¾‚<O% áÖ›øÛí¤şıœt$($üêÓ’İñôc†èš*
0äÆ..¬¢ …ÆwrXrŞÍXƒÑn
y·8T€LW\½[PÀD›¹äÎ=š«WËç]r3$$áş,‰Ÿ­˜?Ş¾?V}L¼‹‰Èé.ß'0?MfÀ–Õ¸ïñ¦Ü2¹ˆ¦‚ª‡±TxN£æ®´ À°Çd¸Àj‡§øS¥p•
Üê«[/­5ÒÑVIyÂË4š‹î  LüÎ#=æuw¿sÎO)£×¤øOœ¼NW½­`KK¿tÙH½dŠŠ	IubÎ»oO¬ªPO$rĞ‚ùMµù;Ê… ğ¡¤¸Ôßp‰ìÌ½ÏqÈt^pÕ»ªh5XYtZú0Í œÕË2@m éD·‹fÁ­„7ş±‡ÔÕ!Èéó\Wùu__¸îğf±±{½	‚zæØ¸^Ÿ›\]ÔÕµ®ìş`Ç¨‡#_¼6ç¿‚Hªq9+$ŸÎ·nŸªíõ>Q`°rÜä*N»Ê”É-•¯c}|n}¬CØöhğzğÒ2Èš6N×‚d âÃ 4²·“y9:XU7ç“úî­>ôàQ`mXçÌ;t-+¹z@í~±³Gó+t‡ˆlà´Ig(ÜÆem¦÷X‰zcŸs}·h]§ª2wç·D›únÃIjvùïÃ\V&³0ÑéÇXÚ{@G±õN]1î3Aâ‡b‰“ôôí8ñ½=Z‚måz‹ÍM´üøš Şb[˜¡v¶q{øÁğ¡íK^ö¿.
‘CµúîS¨·}Oîxz²m*pA@y}  á³Ï2ïÌŒ$ ˆcB¤n»ã ÌuÄÆˆò©1Á~ToJK‰ÔS;ĞBkâ†ñ¹*°ÁŠƒ7± ê°Áêã™÷r¸Õë oÉÂ&zKz©	¿Zıôú½Ÿšİmâu¾ïÈ±ß—*¹bôĞÿ]t`ÓóÛõÏ³ıÛÌo+qÏ¤«İÆÈè7Şª)P  ˜3¥’J/É0fuÓZ«Â|ô®=
>]¬™):òGÔƒ©ªAï,¤YQÈüƒ>¤m¾M#pÏ ÚádûÃ•Jd·ôyK_9;Ÿê„Ô³¤ñGÍ4¦Ç6—ÊÌïaHÌÉv4Œ‹^ÖPÛ¼)¼BYï*ˆ:Ü¿™·ûvÃG‘;†ûÙRLWİÚ¬ê±b-”Ú!e°ûL+ës¡Ë¿÷\¬+6oFÉ³…~åQÿ'8}5mB*·•"ôÒF®ósÍ[(P¢æj¤¿‘Fùoçùø)è>yù¨9`#{lVMpéjƒa¾GÂÀÙø ¿©a¤ÂP”íÂ¯ÎúHsi öíZ½¿ğ•åG!FP;˜>…ùp„ğg
âsÍa”x[£¸dMõæ
J°j¾Œ†”>SË¶ •İy”ªƒÔeãŒHSÈyÜfÁ}¢¡	¦^S‚Y’#NF{^èS‘33ØÓíaæ";VîmÂ²JH']ş¶Ô†I$ŞBmŸR 5*<<ù†qtÎ–ŞÂşÁ©ö41"§6¢ğ©>]ŠÙ+Ç3:¥æú˜"²İğˆÖ°kü®./pÚŞÄ§¿Ìõu÷_‰àWˆ9+Æå¬Ï˜?ğK…|c¾Ö+öŒ—	JØ#Z7‘5u¢ªBwV{:"
˜3ñçğ&nÄiÑüõ"ÜæCª÷‚¿X%ÆïÆªÄ8µ…êÁ}Ø©q|áæ@Wï¨D¢¥†j|î­%lSZM/Ï0]FÆÑX×äNÔb(É|lâr¯÷·¹GÆİV1ÈÆËïÕ~yNÂsÈÀ×nÏiÿOâeÿxø÷¿“«eßf&ROö*ªĞÉa?õ©2$“¾^Éı¶hÇ?Ò¥{Z½KUJ?¢ÆI£±l†y«q„E1e˜š÷¿×¾Şºıã‘]³¹5tMÛ©íöLØuIú!œ»Ã¤†7Â:RZf‰nGX4Æ+AØƒtäBeRÜ×î±ªõÙUTÔóè|V0_ï¶ÇcÄ§M‹êßa÷Õo(èS%&Òğ_F\% Ze
_Ğ2nÄñ˜n½D‹+Yó~²×Yíêğ £H¹…Èÿ1j,ÌØU}íÌĞfÍeQ	ÜsZ‘£0C"o3+K òcµˆL} 2½”›Ü•…o·ÊÛLŠˆş‹™'y¡E÷ujR˜á+^c½jÈ|k÷{ÙÁµŒú^Îù]Ë·¿ £ç!ÛÂìpâJì#5óOt5¦¶©ì€Ã®œÑ,îjX9F>¬½š?œ5ˆöİ3Üc'¹ßÚGyù#TTãõ‚“ÏFÕÃpŠïF
O™xî|Z*8c¥éµ¤ÙZx¶©ı}ã@kYp½ÎXOhvÇÊ¬•øâT<¹"ƒÚ·%‚f5?aôº—İeÈyÕE˜Ì í_!é”È¥« åcî.Xa;$õ8çÏ¸·AåæÛ.ƒX„Eá«(K 2â£c{n¿á´{ÌyÆÍ¢–=Õ·L’°da|-û¿?[qâZ©âk)òˆv>:3T:R²7.ıBñ8|lä¬M=løåÒFù¹ë#â•´Pã?
Êı&Û|ÛeFU§Òğà5AYl‹g-PœÍi#/D±=ãD;Âô2ÜÊ?ºë#£¿y]G›ÌùBd$ÌT>U&×ğELşş³ Çß:uÇ‰4%·øÇêÖ&*\…“kW!J`àoË«§v¡g‹ù®¯’”œ Qø¹î°˜oy|Qüµ)Æ³óèÓ‰ÿÇ[œõ:eÇùÙ&ú®G‘öƒİó]y†ÆİÅõ²òôK¥%–şØ^ÚËLWy›P-PËœ„R"“{6¾‡4ÎÏ-pÛÏûìÔ=2$¨/‚¢fæ‘#‰Å®9:1y»õ#¯#C!­5‡tF!÷dJ"¢€+]CS×Õ:0‰ŠóB+Ôrï½ïã,€üFÿ<µ~|=s¹×éšê†,OqÈ‚1àhDÇëEèåbl6O·wl˜5sØÒåñfô6OÅ TÅS¹u/×İÆo¢¿u<5r	Á]¥d€&`_8îÆb 1ü´g*d<ù.’¦™­bµÃ•¶êØpj¢ Å±"’d’×–OåLlÉÅšÚ_cÀI‘Â'®@ˆ4#¢qxH*šß;E|YV;•Z˜+t‹Z6\Ñâj2Z;J‰|Šè-£OÀW4´´ïòœ¯W >t„¨s~O%½OÙºŞóNñåúÏ…¶Œ	§ææ$sÖä¼ÎæUŠeĞqî…¡ÙµOpK9Üæ~:¦’ZºçWáÈñá6nÕõüÙã™o¹½¾;ci-Gp¹ìîßäÁ²eç«°ôeu±Äõ1–Ÿ*¾6P%ËÊµ ¾µÒÄ—EÊ}®?4»‹šùòá¯š{7Y,ce°+à`ÄŞØ#ÿ‰÷7ëÅRsi`nRÓ5g¦Ä–S(¦È}Â‡a­ü¿¯`1k†kTÑ1ø«j—e\ŞÜAÕ;º™mÕ¯q«&ÓkÄ
ß*’9®)Yš6ßÁôÚøDnIïVV
}+t³‰ñéşÅ™”é<‰p¨m]Ó¬Ş…ü±şD¤ş«¥Ñ-Å¡ d1ÜüZñ=eRI¨ÛŒş@aHÄùX…
«‚Jošÿ~wKÒPÓâåºoÙ•iÔ;ˆ§XØ¤*qr“ïœ€B ^ÿ½S)%ÑVOğ½P¼¦¢‘8¤6eµÈh¬{©»ÀÛŒş“Õ~ÿBÿ
–Ú ÄÂU ôü‡ôÃ ÛºLk:üàWÈ€4«ƒÚÆø³£##¼¿ğ}›”éwWuÍÊ±’±{ÈöuÄ´qÂÜ¼Bï/”0çÌ§ ¿¨]ëV÷fí'„ ú…(wO\j%vïÍ|Í³ÙU®¨²Hÿ\œ7J1vº {°‡–6>@¾!X½¥¨‡ÔO!íüôd¹åŠG»C\êù¸ÿI>N¬:XœĞNéCxŸÔæ
ÿ#"GW
†à{!5ÚòlÚEWÄ?}×¯Ó`­@˜ylØ0Â~ïé|Ô#fı1dè·ì3öÖàäş$c -NQ‰´µƒz/»˜”"[¯ƒ@“¯›ÚÜ›äöa-Q,î_î}£U-dUhXX†=vîê È•|g­iŠp˜Ñænê{Z‹Ú†7¥ßÙùìËÓúûÕ“Ù¦¾‡íG³#®ëS ¨™b‡FÊÈµĞG…0Ú{-ó7ƒ_'õ-Èª0JÊvû\ç{æ–zøÍ¹íJĞÁ´€åe¡d½Ö;æ:Ü¸0ñúWïáŸg1ÓLI¡ÙXà–{[VÅoß”kÏµªîá¬JÁïˆyàOVµ‚ xÕ£gHÙR ¼_wŒ8Îzû)ç½ıÓV¬vÇıs*ùêZ#ãîë­ôGÃª± ÀŸÚ¸&¹ßù+A,	/ÿ8›¹²İKÑ-ä@MRª tÅC¨5¿´Òbhİ*e4Îrz-`–ËÆXÅ¢ûWÅGÁz0EÖÇ;_djİ]Y#£ÊªF(¢ŠiC½¹—OÙĞi ¨±­~2]ª!ê%àYˆ,8ãGöµõ
\2á*ºë¼M4yC ÆO÷UÍTP*x}¬a·	Ò#¦£;L‹}ğV$‘–Áë¸R3“‹	ò+Öošòª:TŠ|¾Ì¸À­"r#–a}ç(Pìøx ÕVg©’„S/aÆ €P»0—†^ÔJ){¡;¬ú¿Í¶ë!0â¥k³å¡<eÛ8P‚„C2•Fˆ¡[|ˆb|ëİ+Gå6Ê‰!J{¶ù¾\ÂÊ}~Ù Øöëb”ãÇ8äüJÓ·ÍıqùÔtû¦¿f\Uñº‰Zc§18©Îj*›r™k¹|  Öä°ÕŸ%\HL :nLĞŠğÔt@~pà4fë~±±V'§Iúé<Ä±—ëÙ!a^Æ{^–'Q“°@P½;nÿòà ¢“Oòÿ¾õ×ú*1Árh÷ôt²Ò£@p÷ÀÖA°XBÀ§ÆKªÂ$­°~x}èNØ¦ØsV7Tw0Éd²Œ3Æ6,»ÃìGl{nœîZ°PÉfY§[ÅénÄª‹ï–Ã£LÉ_êÀÕ—kÊpe öÚ+º`à µ8ô,VIÄ‘COî·,R¥.EÓ4àûF¶Aó(F›ğâ[ÚŠ^+I%$>_$º¦²³Í1Ù¸Ôw”9² ŸMÒSŞÉÄÜâÒü•6-æ ÍaC»úîëİ$n(ÖûõÙLùğÅ’øûp«i]NóÓÇâö5-HĞ@ãÕÂÙë|+eZ³©vï—Û’»İËT³jç†÷Ç•îÜû9Cnû0~zFAHv	ej, ©ÖwÊ+!Ì•{“µ`h˜Ş^˜éù1bÀTr½¯‰ËÙêáàfğ‚oAæzøÜK~û¹Í+Ç€-vŠ”
‡¸‰8?vVÙ˜u¥Ì”P\Ù¾@¯±Æ^f!«¯Ä©9:*êÙïî˜èlfûÔ§ed>#š§^-Mèá§Iş)j»ÒtÎĞÜ$–ÓÔA3æñËÂÛõ²,ò@—Ğe©K´9ÜK®8ˆ_ ×Ü·Õ£ã„r¤ÄúÈ„p«–=Ôª7p\-ˆâ­qk¶F5P®2Æ—#z-€qp4ìx‘ğ@Ó4tWµ/wc)¡ÛÈÍ¼ÁWÕuçË.–Zï$zÀaëe€/™ˆZ ‡IüBÆ<¯BÙ›®™ÂÕ^@ªÎtòÖ9kÔáÖ°s"Q<¾·w²‹ô]°>„Ía°ø/L7D>ªA*u£{D¿x´»W™ä|01~"Ÿâ½_ÂSå™ ÇŠß&®¿UBãø;H¾QF—è
^"•Íæ	<á¬ÕP¾£=ƒ´<†ÓZ!
@Íˆ”†‚…
h“™HÃÚ ?ì©¾–-,MŸ±¯¨ísn†@Ù‘F¸%ø£ûóçØ/‰éö‡¾ß	Rád¦´ÚŠ¬şÖ’¨z@j–DÙŠ´Z2Cœ.ÿ÷š(=ÃŞ”/x?Bu@ÕË.lËAfÜÌËûãÍ1ÅÔ1LWZÎíˆ=şó^»‘Œ^äŞF‹4{†Ü¥EëÌWŸCı Ó±rœÂ…W-EÇO@!:l> A†bDén^‰
™.Ëâ£ZùQ»Ï²Ï`GpÍş¥AMĞúÊCEHß`¼’Øìâ—MêŞr½ô}#R}×Eˆ2fPÓã½(<ÔjLÒºi ìƒGCNÕì¾6$ªÿÎ_*©MÃG#“*Şü	ØïÑ_übó),ø2T/4Ón\ŸØÏÖó4[±l‘°TJ‹**4C9ñ‚tÔO:è8š¤ùâxİz^jO R+Ñõã ¨nJp…ôĞç“iNò+G÷ğOùiPÖeÄÑÉ0 -ç+óÀOãöéÿG$ü‰Ğr¿…l PííÍ1aùpÑ}ó
@lÉîP®­Ü¸ ­óöm²Tr§„M•¢)Kkw‘Owì«lÕUvJ\‚×òkóJÌÆNf!QkS{æ¢¿ş–Ñ—Óƒ¥€Åf>Â¨-ğ—Éña´¿@”†š>)»z¨ºLöÌbš/-¨Ÿ>/¿óR‚J<öâLWŸB  )óXLéÏC ßÂ€À”ÿÿ¿±Ägû    YZ