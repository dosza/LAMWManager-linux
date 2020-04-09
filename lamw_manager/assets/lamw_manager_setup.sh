#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3640564938"
MD5="b53abda1fa4975393273036fed35e105"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20808"
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
	echo Date of packaging: Thu Apr  9 12:23:55 -03 2020
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
ı7zXZ  æÖ´F !   ÏXÌáÿQ] ¼}•ÀJFœÄÿ.»á_j©Mã1œo·×¯Î.nø9ÿ¥¶‰ı=J|Á9\(“,¯ oáDÄd`ÆZšEk˜¬í{¼©àt*g	¬ws@2«<¥ª1=å ÆÍÙAíµìˆ´¸PÊ0Õ÷w5“ğÇï¿«‘7õIœ¾LTŸ»©á N(ÍRTŞ6p,lÊè¥v:Nå(¿»_¦9¡…2ûBI£Ê¨F¢éğœ mæÙEuuÕ%íÎİ\0ŠlR_fæúÃ›6 Ğl¢Íõ4‰n£ä¿@&‚ßJÍ>‘¯#•75\"}¤34^6ã†?•Å{ŞKƒÇÓÛ=¹P}*jübõ"!äUt=«ÿHöÄ!a}"ˆŠªã†Gÿ"%hpõîƒCË÷¨5[Áh`e«Ée§™«ö°_Ù¾Ÿ®~"—ÕO$KSs9ZL¤/ÇhÓ^² 6úàÿ|P;§s÷š´ëfİ)âÈ.»„¾(÷M©ĞŒ"Å((T§¹.U*(;”.Ùp¢ÛÉk±ÔF>uc‰œ—4³R	õuqà¤:nDF›¤İã³ûDšæ:ÒÙÌc-Hyu­ì·'ƒólbs¥ä›¯@«Ş(…Gœ$T—)Ë[àˆ7 D}¹”MA@,“–!JĞ[}//¥¤cğË™lèÜu"‰P’Z5¹1íç#dàbŒbU˜ e57^“<Î,`,Â^†ìßg$´•kZ1>,úå•A/to—Ä"zª0A(·!ÍbN¥?µó•õ¼Ú+XLÏ×‡’‚ª4Ó­Â•…Ş†íY$o2lx¢QÏˆ‰¹½öÊ¯²µòéÚo?³Ã€p9^/^?ÔZ`–deõVD?´ÙÅv™bÁÆŸõÚi™‡š6 QòÍÖµº?NÄY°ÈW×Kluˆù.á8—ÔY¨Ñı7¥L¬ ş¾c(K¹Æ9Æ³üÙƒ„–EÍ$Ş%©ä½L¿ÀP¼I5°I7;K¡İÅT§îË¢¤%´:’FNº‰g·‘ßñ`´ kº¸KÊãõÊüË6?zLQ'ÕŠ'`0Ë0ù×ìW¡ûQ:Ä·G0ê•ŸØØMÿ¼?!ğI[·…«Ü’ú³Â\"3ÂVÊk!‡C_1¯‘?–JÙ==†²éØ¦hâĞèÇ®¿f°VjjI½?‰÷ì“˜şG8dÆöš…ÔßÖnâ™Ê^Y„“È›Şb©}ø5Lá´³›ÂPÆ(“q=(ww† dV,Š3]”4Sh’›)SYê±ıÆñİCC³:á“ÎQánàÎi!&‘ò¹ïL®’Q¡ÍŠ<_iĞöïc@ÙovüÌš«wÆúš7!;›5fW/n§Q*mÏ5™q	ó.GÓ]ûG>6Ë4×Æş§ƒŠzVÙ7r2Z¤“¸>§¯A¶|é1}$$wRúç.Õ—ÓóÃ}óçº°¨ é”ôÈ<"J°ÆÚìk"Ÿ]O‰A§Ğ!Ïm^}ÊÂ’ë0%ĞœÖ1¬©C{Ùy‰uĞÊ·5h¹5ESˆ&ŞUöŠÉŠúÖ?°È÷o¹Ğ?ÁTù6X}ª.‚nÙã­åÿŒ\òy¿×ıªtnËÙVğ|÷=§âòCû×y<<£i&†~÷Ùçôò†Cg„ŒÕ™{Æ‰4A²ƒ¨ /?C’	w>)™T”›ŠÆPªıORäROÇT5yÄJØP:ÔË½ÜGNb¶fÄuóµ­|È†à#«/<FÒøX@9 ä‘3¾”ÎÆGš×£!tòöq¯VĞüá´@¬pª©k…Ôêrl¶.¦gU0¯m¿Ï;^V1dEçpÊih¾pGê™1 <À=~<íŸUevÙ[¾î4~Õ¸CÃ[ÕŞWÆşŒKŸG2.¡‚
;h6®tSugœ™­Í=4üÁÛÒ4­mvèã„¨œh|§Qz¹³Ü(%†‡Å/M²«\Ğk."åƒÙc;ç§,d¡î0z©–mÿûğL¶n»Î€GĞİz³(7Œ{c×8„áw *[–£‚)ìâ³»Ì1™5?cD
°ôİ–"ËlfØ”^C!š|s«û#((¨5¬úØ©W¥}B¶WÔl¡ãÛjéŠèÄLU=Ò)/£¡áÚD)å…T]ô¬÷Óñ¤[a>rìÒ;:ÿœÖéğVÆø6ò0À­hPJeZåÔ¨à Cè€ øk(%T#7g`œš ´ñåR}OWÛ
a¥“²;ğ')‹3ğÜ¸­q±hEV¢İ©4‰†ş(ıs 7;EÆdâ|ÂPåĞ}{I
“ı_µMÑxF`ÍÊ'’¨ì›}óØ9¯²¦êœ-²Ôú80éî\«´á š¡È’ƒ¼A)39p)Å`¼h9Õ¬>{ò Iw% £ó	Ó×[<r `ãs¹Ëé²".~#_<(k"ĞÃÔ€Ïûõ§Oi‹íŠ
c;¼HD Ñy
Å¦'÷ÀË:Œù~+/ÒİGû)CnxgK‘Ÿ‡«„ª{ˆ5Ñ#Š[ø‘1Ïk×«NIÓ¾5<EÇ¼è4S`Å©äşÈ˜•†Go‡­çnæ&²-Ä¸˜06¹¸†‰•6ÑâXXäfâéF¦ßøÑáã‚%°6zÍĞ‰À¥­O‚µ:Ü¤è!e˜¤ŸæàĞ]uh1÷”˜Ğõ€”æ¶å¬^öqÔ÷"xwÎÚ Íé·˜$ñÛór²D2œÔàr¯1z(¸ÿö>ìtoHÒæàâÌ>9ß!™º³*%˜Işõ²óQ>¥ä´IÒÙ–Px×Œ±q«ÉHÌ¢“9m.ÀÛß’±D—;=Ï³ŠeÿØOÀÔ|¥š~ÓkGãöŠTy6ª;«‡0¬@‚DFésœ^¶$İa`È·¾|ĞÁíÑa”J¦‡›á¢ıpØ5…±XRR\ÄmÜ™®£€¶kå!:ĞıBò(ƒM’wÿíù˜J]	ï{B¸W<5rõ½ò‡gwÔjQü¬Ü'¹Ë°˜7Òt¥¥yäsLkv„_²Š°œh°ä½n]¾hÈ™Éù€§síÇÃ`4	W
 iå–6›¢¾ùDp£I’gzÃ —~ùÌà®4v.~ƒ3èÔw£b¹(»y Ü€¤£èP¾ª”ky¨ó¦Ç§İ-ÜÀ•_ì‚ï7ş_eŒ³nÜ	Áîö	wºá ªL!•ç™ÈÉ[²˜†Jİ ]PõYn!óõÔ‰Mö=Ï`ÿÏÕ‡Ñ¹ë'hşbè‚~£ºùRA%âš¾¦äÂeM»O=¯4w6¥²ö%êz°òê«y-¶™¿EÏV@HËw¿p”[îz »Húh‰€•£—³yƒGûQˆÜ¬34@C-ª‚¯¥|JßÁãÀMOxƒ”cD?åÑ*~°pşQ.Ø'«(©Ê¬4&Nr5`ÛE«?"z¡é]èBñO?]ÒÈóŞŞ®Ûrö®€^så58|ƒ	
`L¿êésÙè}>2ÃTA(ü\µæ&TŒºïKJÀ‚ı)a‚'¯©®ÚvR/'‚&ÿCÃ4mƒªäªl¡'p"ÿq‚îëóm)nÒœ‡±UÊu¨×¸^¶ĞÀ®h¢Úße 8ĞfóueÙôoÛŒMgWõ±8Qÿƒ0|ş=«è?½ÀóÁ ¢taÆ½•4©.Th9;’ZŠTìfİ,~vÀÑZÙÏFë$gQ›
ªûQ°>$]Nlÿåê~ßz,ñÍchúŸÿLpÚ±î“ITØŞ<¾ß”×<KD“ˆ›ØÿñùşÌç?	.Ïü{ï#õ»ìk$ó8¨Ÿ6P0ºvĞyi÷1w…h°’
—G£‡Å!ÆtÇ]D‡Dè¸Uœøäş2syÜR8F¬d’øtıKÈÅO2ŞZ{û,ƒâKQ<aÒ¾§Š³hO5Ú°q’Ÿ»ÇìäÛ€‹0v]áã•T&V”‡gú„èÔWË†w©ìËÙ‘‘>Éá	{´”0œ1[Ö’d§¯»á©¿¯anjÕ³:=V0\Ò„€l®4ÈGëW°\£×Bc ö4&ƒ¹tÇQÚgJ¤ÂNX>ğ@ÊwÏ›[¶¨ÎŸ­<]Î]–ùZ³jiˆ©–0Lâ×¤UÁ¶Ú’æleU”¢Õ!ÌIšô?—~ûÀgl$¢çhr%µGÍ.Cô"--³î©;çGxq[¢ò †„ğ_½ØQ¦ïšàè6Ş%}äsÆ§˜©Æ^^ÑtXÅKIÓP¤¹8GÚ¨$j'±zè2¾Ìİ)Ø"—İ“ú÷W}.Tø½„?Ÿ»Hr¾‡ îmgÍ×>|J„_´mzÓ¬"8Q“şXœíğ—@}¹sÑ?^»ìé cp0İE½±´=ÒøƒYn_l°[!ƒËû·¯xÏãøÔ—ÈoSWÂƒÓä <Ÿ†¬©¸,Wè±¬[„DŠ»/Ùn¨t­İuËl‡¶„ÄßáÖOf=-Ş2X	CÍü}aËaô‹õ%Ñ'H©Htù\ËŠØ„^K²!İñı˜±<®¦Å p‡;Ø8PG±‡ı‹ı¿‹ÂGSWD¾ŸŞ8*½‹,»˜ŠôW~zm<l¤P”á›@_b¸E}Å£Ñ¿1:’2 ıqñ0¯6
»^T”]ªéÎ…²è.Q¢ ù*D‘EYÀ·Öé¾i@Ò¸·rgIyâ=[Û @¤zÌåÅ]aä%w‘]0`¹%¿+ïéKF×*ë€=ïîb…q­ÇœQ`ìô¨}<†* '¸ug:ËÃfïl§7ïaÊˆ*a?LíÚw¿/½;÷)d¥–…-¸‹‚ÁƒÔ1ğSöf¥ô€Ê‹²§
XÖÑLå5[¿s¢ô
†K±òMfSıp¸ÇÆ˜FÚ]‰ÕÏ;‰qğæTtşqB»Iî£‘ÙßŒ–”*$Â’Î©Ã¶Tg{k®1Q
]ÁTeÑBÕ=&²[ÌüEC±îª @'MXã¡eáÔ
ó¶c-¥Ô¶RĞ¯ì/¸Ç"â:ÿºC‘’NÒ¶
PË•ÙCKU;#[Áòcô¬ÕH¿¹¬é)¨“|E‹˜73!`tÙ“ƒ1Hcÿ©O&Ä¶ƒ„á<m”<7"¤tRÆãç&(‰3â}ˆW¼@ØVÀ°üg·„š`oæEûÌñzèÆ=\f/ô¤›éëÂR}¤.-—–(n:<·x«ìvôxE—>pÜ¼¢æH3Y7âj…çÆ6xš:`!ĞG»7qzš»ísãGQ¹°çCbÕñİ^½eD¶±Ï´j ~l–¾ûº·´û Ñ$Ş‹jˆ6ò%ìH)H†z˜ÃLö4­ŸïxQ©]\Cñ,³4ğ›½6^Ì–A“^=ˆp[³Ó´‹ª‚G.]IôkûÀ“ş˜?ŞZİşûÖ¢¾)èZ#²*%õ×ÙÃüŠ‹|.Fğ¡S+Z7RX›I¸Ü.ë'Ø‚úØ S¡ HUqÏ•ÊŸ>îrMÙ†÷tªb3zT;æ]”†àDZJt‘
™š–ñV3«5%Ml­Ñ_l5kŸ¢ğ›[çg*ÿÈàLÈÜ€rÕ]G1CÁBn{ö}>ÿ·'Â É×O/í¤,ÆŸ¦¡}·ªÚ9*}¹vìz°*”ÑÁŸsKH€kÿ«¯(K—Åâ3'9ßƒßÕŸ
ƒÁßF«où&§ílHöÊª˜Ø.‘qÌ=Û´ˆÊ¶ç‰óÈ\n@ÛÖ€lƒü¸eöïßÊÛOù¿Ë²¸†(‡,åœL‡½"][U¸¸?càFû‚'xP}dïù[ìVû«üb'9Ô.’zNH^-¬šŞ˜Rƒ_—"Fnİ4-pá”ï4æšÿRÍè=Çª‰_ïC¼‡¸û¥Üı©6uË-‰Û˜«ßyq¥_'1
¢¶ÉE»s¦Gİ/ì}¢1%¢Õ‡kôSù %ÂÏLPEº:Ì´h‡ –)àƒ°¦#š«j:¦ñ<ÒºÛè_2›Ò<© Y6‹úfQ[Û^¶2™îÓA°;3½A±X¯JDæìÊ6¼eìM×ëuÕÆwÎşÖytÃ¢³&|Ë?µçÍnY—TÃIÕ°2ãyÀŞ€T‡>È×j¢Rç‘‡Q‹Ô˜k°»¹ËWœvaxàŞÁUÏË3…mûI–¯Ô –‚úK«ÀLş<×C6å–£àÏŞIñ8ğ›jIEá¹Al:ñşLëó.w.¬+&Kÿ:GÜº`6"³÷”:~«ÔŠåTjMğµhD"GÅoÈxÃ—D€ã"Ê†³Bµø„·yaøÁÕñ3Ğ8ÅU{³)°¾-ÔÑú½!´{y7‚¦´W³A¹G»Ü°àdD²h¤$’êªŒ’Uj^¬üB¼f‡V
)¿H©¤«H<…î:moo.Cû‚ÉjMşY>EÆß—Ìébê‘Išç½È*a+ÚêNæâ„¤è‹=:›ò*Ÿùc‹GÌu½ªã'sé ±Ğ´ğ­/8Ëİ4ó›0^4·i†+ûÑ“J¶ôu&»oP]‹³!_¸>¦ùÄà†aòå/WúÄìš ÂÖ¾”ñU^â7Şs·$$ºM=glè“?í¼”8˜|‰aÈ³¢ÅĞRx²¢âëüıòrG\\ÇKèQl\»»TXÙé°×Çÿê{kÎö,¬Ñ<Äİç§‚cÍ #Ëu4ê:şßüò´û0}S%lmÅçP½ÿ?„Ú'Aö¼!àÙ¹g»4wå‘¨”X”LÀÍòÙÓ´İ(*uõoSGÈdí÷·*ö95¹zˆ°8İä~ôªè³•e#½Vï‰ÿjßsØB]êù)i±ÚWşâ~Z¡ 3G¿¡Iwáp™òsÈWÆÛ¦×ë‰¡ŒÁLÀEİGéßl0|¶0é™ù±_u‚‰»!;µvÊGJ¸D@dNu–'4béçFÒkÊRf5>_”ášQÌ“îpCìôúlgÖí´“Ô…Ã²)sÜú‘ú|˜Ìğ¢„Ôü<à”+ş%‚öû/jÂ¨ğ²Xä™&ê«°ï¬òò›PÖƒU$ÅZ Ä5Qk0pH§¥ƒìm5oÖGÚ;¸«*JP‰@XZªyC'”³¤vƒ¢NŠâK`¿¾ÄŞ}ÍFG¸ä]ÂsA8ÊÇø³Ìä¹À¡#ËÎu{M`›‰\0˜ß ÔòÉÇ~wŒ.µüü—«D·²§U~Üt!á)¦œ>Œ7%¸‚
üùæØ2SÀ?†h±ó¶$@«ÔTa6²úÁ“•ÁÓ©$Í*õ"¥ö_­¶›»™›ÌÖàä&XO}Uá®HÂwø÷O˜’)i6	„­5r ù•UİÿZÎÀfäµÀ½}bÿa¨HP N/Â
‡§î"(ÂB-¼¡¸ô,G:Ñøİói8é{•ÑÿY?jQ¸g5–:¦Ûbğş}íµ†<6U A¡³‚ø¸jĞ*ä5‡üL}‰’¼Æ9ieÄF™¹©íüeÀ³©/fÀ/<ñÚUÂ„V¨ÁË®AŞ¤Õìğ„ë' Y;a¸ƒŠªTÀ
ÉÀ†Û›üYK±N±$Ç§ğ'ÀGWŞË&™g|®Šæk¤¸C¯
¨w-4òÚg*;)kæ|g±	ˆY¦4(Ô–çÕşùét—º|u¿½)ÜCYBÚ Ü:“&¡2÷º;¤$ŞÚ’\;Çœö[‡dôdØho0íV_~?§éN®é[4™†3 MD€Œ™0‡ÑaRopù‘[â=ÛÅåZ¬X&Œ“"bÙY‰1çÆ½N~){,—ëE6Yà›ÊAÉæÌM,Gşş´Š-¾’Ô“ÁÿÎô¨Ş`*P-v¨,1jÔÙTëCXM5Kş-c?"b§°&[Hv"ÜQ=
Ô„+îOo•œÚ‰Š.HäÄûiá=QŸ`rË‚-Ø¦æ%ë%©‰¿O(.{› W@
ùä~í 6¸jvp˜Ç÷—ë˜› Şü£¡Å9`4•0p#Ğıvïd!ıZDDdí6ª=ßHÚ’‹ÿ+	LTtF”~ê;oAˆ¤ÙÌŠúğÀ—)Ä?Üt…F;é(|NNËË]ÚÓÙpò£y+~Ä½Í–wcGÈL>6Ñèâ1­
Ğ_’Í;ƒ Û¢Ÿ@Á„fq(å	¶jopU-µcVÓ£Ïß–÷m(Ì¶-„zC³r
Ë^»>@`@,¨eŒÂK³Ÿ^ÛJù\£á_ Pö€6lÌ°íY“öœñÌ4D:ZQ$…&ÚıÑñ«ÌéÜ,§ùxgõ	ÈzÆ¦Ï"L~´[0Äb ŠİÓzÈø†ƒlèYÊošLí²Ó‡½-3öhJ‚èş)YAú‰¸ÌÂî¡c?ÕJ“İÃıyÂğÈwĞP?C\Å EØÇ¬\tŠ@T3¦~/“Ø)æ:ƒFG©'€R(Y›<áÜSm¬[ıÙıäÄD>‘ÖOÎğZûıODÁBŠ@íô§C8á«Yg1èáÍ®¾4./½”ô“{É,÷kXG'‹z¡N©ÊÊÃ†™ûìp‘Z‘Ï“!—@Œëu%J3î€ÍÍ3Ëw®Qrì®>'+g›\mÄ÷"8í`.¡{2ôæ8òzÅ(ë®ÆÊÑ=6.L¤[L(×üÔ“7Éßkc‡ „»HÒæ—GÕaqç©dÓİãæötiIca÷=f©÷º®rõÖ¬0MJ.I-±lÁş„Ü†¦×ã…õbÜ+}äò\@ê"eÚ¨Êş{èÑ–i1š…şÒF±y§Ş•‰T,`¬>Úe]0)iBšOıdºäG>2ÀîsÈi‡‰Ş´©—5h2L¹	m¾rj“ĞŸ"{Ühã¾:{Kwx'<İ¾<L¡MnTÔiB3µrøŞîë|‡uÂtİ¤‘I(î”$Ñ®FÅŠvì­Aêˆûƒ¶ËıPa3qÂ:gl¬åÌ,Ì¹ßP Ú _Ñò5†âÍÍcâê7“ÂpÍ£(âÆ‰2¿Ó¥¸$:I¾²K<6nİïûáêò †¼÷*ù!Øá¨ÇòÜ³ä÷,»Âa¥IîĞŸó‘V	Ô`––Êš¤qZ9Š.¢(¢Y-ş±áHÉ‹FÒWñ‘ä{d‰˜öèM‹£ÇŒ¬Ûğí.|åw&è¼ü¦öPâ»Á"õÙÂ¬=‰JYş||["¤_·ûO— 57$Åğ»­6Pm2¬÷)e(1)™:x:¬ª“*~	N^¼¢4¿MÑ%–YpRÕ}Øzõé¡ëF[¡‡x)óËğŞ[»ûÌ‡MŒÈçYHÂõ ¤EÄpµˆ&ç'¼Të68;É4xüÿ»\7³‚ƒ’õlIë‰CàMM›· O¯ä4^Å,ñnXeJõ0‰‚@¡;ú^VÛ–&rø}¦æµ+Ç“TÄôÄûô¤¾Q(ÚX“U
 ÃµüXûC÷^Ÿà‹#Àµ–ßSËÑF xaÈô­NüÏH?MqJÅªpmàæ“…ªí”Zİ%¥kû½‹&¨ã’öÔ»Äçğ4êxW÷™Ø]œĞGOŒñ¸-ÖHcÜÓ«ÀtÿQrİg9İ•,8ş‡÷mÏ‡:K`³¸N£tE®Ò0»ß¥³¶Ê”Oƒ^ îw6æ¤rã¬ËkëV³®ddÅTXLrk“aÆ*q<¬#zê•jsÅ«ºúƒ0Ÿ­¨uslYÖ\éÿ˜÷{1Æ‡¯º‘u“{Ï½ Ìv˜Šì‚oTEw.ÈbÓL¡¿¹ÚÌwj¢«cGÇÉÆ¢ï„„H¹ŸºÉ#Â'˜
V¼œPßxãö‰RÇˆï«µÄƒíKVy/çz=÷Æ¿½†w¬3_ï*³cÂÔ©û‡Ñ…ß³÷ü™+74ÛÊ«{ñ´|¼#W±£Ü–ØôaHfé_^›?COÍå¯†	?ÿ†a"½ƒ|Ÿf›FÖÁ÷¼¯Kn¦X÷Ğå˜¡x|ÀÛ¦ ’ûå<¦­Ø\€†K\X}x»^Nœ„gÛ(·58Õi˜òH·ªU>‰’¨WÆë¡ú‹
T•r7Ûn¢²ßz‡4	}­Õ#äÈ8+oIæ‘©ÜmÿÎØ:Ô;#Gp8“Şâ[¹³«À…Hñ}×–È÷ú|£ì=o0ÉS.ä˜?¢ÍZÕá{¾w/¨÷WµZğ)èæ@½˜Éç‡³^ÃK¡.ÚŒÍ°ú_Òÿjcä¨b©¤DÉ§á6 ¸`s¬Wø"vŠ;=àEÀ's$šÍ²‰M‰Q0RşD\0X‡¯äšsİOl`Y ódéƒm/XJŸJ?OƒŠô/ÿ–ég"ñÛoGøU½²~¨ßşj]ˆ„³ËS‡B“›Å"¨º¡¥ÙVvMşy¾ kLCñ¶Ó†¾ß$ÿ|#*Ú6
À¡Íâß*ÊİÇLt­à”=óÚYÖ7şÂo4²¼LƒÊ¼ï½Ö)õòá¨2¹¢‚Š„ô1ÙMMªª$õÊiÂÒ†„<sCÿ¥¿ÛwOÿ¹¿ôÑ¦HmÒ½ĞûÓF<M¨yÊq¶[<ª7¶ÁÊXô?•=]{iûIRáÄ+”sî Ö3B¡tÑo¿@S=@ûø5^¬dpİ\ûğ (×¹Ù$¦»˜İé$ƒÜØ?rĞ{M’ƒùzH,”ÜWDì.“c0½[±ûaİ Œ[üÖæ›‚ÍçFù¦œ,O$"gšØÅHò\!ƒæqA3ø=÷>Â ñ5Ÿ0îkZÂE§ü)B©éÜÆ©Gr>‰:Ş'gôä–hÜ»–jÉgHa9X¯†Ÿr+½ä¹Wûg@Bx¯(=;±=>Ê§ ¡@ˆÏÛ&æ´Qş¨O©ã_à5FJŒåñU[½HX_`şˆËOU¾¹í^5ÖD”@Ú93ÑÃß¸Ã«™Ú~Üë}!t–åóÓuÇ‘&Jâÿ9rjD˜O„ç„÷ÄmÄ «ÑÙh¸‡º{vgö’2SÆjVA,%Öê÷ç$ƒğ‘ Àñ…ö“È>S,´˜r{R”IƒââÀ\ÚoØÈ¤Š¤Uë&OÔ€¼#u†o
—'»ˆSC8èOV°íÔ9 FQN&í¬Ú‡çĞï½ IWúÕùÆ¢¹5PF=£’aÂğ1´hÿä‚%—8ß¿Õtp’m–<<ä«ŠÛÉ®óFtãZT¨ú1'ƒğ±ÑdmV.Òá‡èm½üu-|¼§	ş@6|n{Œ%0š(«-†RÃÉfrÑ¢ãZ®;K²‡§íà1ªÍ€Hˆv@åNàHãy­jô¾yQv/uÇØÜXïìá&1À×ˆÀ¯/Ôv{NÌú,6qOw¿âéçR;m*5ÈëıI‹_åîO~£áˆÏ3ı+’Ôğ?ƒç×~ú±áfN\KvĞ=~û0EßÖx§dÂ)q•tBàTäÿ ÿÍRß<Gîb½õù#¤¸iÒ‚gêó2-Š¨,}LD~oB^M®±üJ^bVîjâ‘•¹Ô!·µ¹b}DÃéR€˜Æ0zqĞp´rg*Ëa=¡í_À?ÕP‰ôZñA½!á¦Uf*|g¡È›ı9bÀ¸¥	3ÕL![¯m"¹‘]òÎH‹jšü1Ä–d»f³I™®ÇŠ½¥Ô˜.÷kÊ·QøÔJ’Ó_}Ö8’#uÓt‹”!‘ïR‰1èe¨ú)à^É‹1Y‡=—Æ;p-¢bÙªİ36[néãÍÙÌ­G=·–àªäÙZß­TÆ‰CM¿œ iióñáJ²™½ß*¥Qæş"–ÚÙÊWÄ~¥Oòw«ûBsÑo<Õ®İâ+Y`?Ç"P_C¶´¾
[¨wâ–Ä£¶Åô2ıå-9	>½ôlËê—Ù	Á= BEşÖÁ•©‰iä€@¸ç±UÚ	ê8`ÿSpõ½å 2…gX—¿æ\ ˆã9³ÔDç<‡ôM^6<avQr[p¡Ÿìm)êgİ/ácóìDOÔ©6@wt«NƒöÉêQL|œ<jT½ÖbIµ©¥ÎÍ‘JdàÁØ¹oğn^Ûÿ6]UñÏª İQÃ\o´ë¸›Ñé×kh…VÊ9¯ÜÄdvÔQâ2îfÚ<b™e:êÍzz8ìÛ;R8İ~õ9ê}{´ÌŞ+Íğ¨KÔv¼_¥aBÆo”èİsCŠì¹zEƒ)´â¢,¾}ĞMÑ™¨²æî¶·’,N>ª}c£$–÷Xé"Âl\ÁgµÁ$˜†Ù'GÌ C3™æ±Ù‹ÑíH]í’'FÑèäõÄêGÁiQ¨Û¿¬0Œïì—êYÑÜè¾+v~ÃY>¡¤v³£E®•R}‡Ó0#s¨p-&2dr‘ a>±ßºuSpòü´öÊ¹n D¿0:e¹½V#¹šn€·¿ÜD¤×^ò]2PøJ‘]7$oÉ®:r{òï—á:]VüY8$p—WüäŞ‚ŠÆ #G™¾Jz^dïÓÓÁE‰ÇÈ&£„<§A-üûµäÜ<;ÖKIF-8’¦+ÿ!ºO¤ˆ w©#«ö@LH@Ì°ó¸í–&şr¶v5£=‘%ƒÏm™9m,}[ã¿´Á%x±4n¯Q@µ®Â–Y‰V&2:
/Íø€ä`¾ë›Å+LotƒË«?È¢
¶â£Ù_ÅÕ”öß7.Ğˆ*]ÉÃ¾˜ÎDÔ%‰õ…™_r`‰TQ°ØÑôFÈyëSnœÕ,ÿí}W5>Æ‹ytøªı97Ji7§õOY·bĞ:e²kË.páÁÇÙ=gYx_Ï³;»äŸş‚wŒŠjágñ¾Šm‘@©PB×}Vìo€â-Ó¥5hrÑ@óëÎ3\rÅ®	®À»ÌQÁÖqùpóyÖDeîú‹ÅÈAïşĞ†a.%zâşÉü(`Ye±©*b®/‡ËûhkB„ 0P[‘÷%äùéçñA<ñ²øéğ/Ö/¸)¡¦GôÉ»»«áMØ‘él?ìıDƒÄ` I¦ rÚxC2z‹EËFØœŒïäcÓ[¹aÊdÜÅšVK Kåz¤ïCæùÛöoôV„· £dìµ@©6°“rÅĞdsÔ'Ä²@-Ródõ„XâÁ§p2O=¨F;²~Ç6-M(²÷şñì].IL¸ÒºÆÚuÂüĞˆ–ºzjã{ç¯¨n›¥¾q²åò4LÅ€LêğO¥e²æêƒ(fu0N±_Fƒ[	ñ<¢<Åß»¼ñºjTÄı“CfMƒGÕñÜë_sbÓœKuzÜÒæœúX£•aGÂ»Š}½ÇeğÓÇäôj§bú*beb ƒÄ¤P’äÇ…9­‰­wtƒÊWŠ·’Xê;sxÎgÄE'‰¡¡¶‡±ç<#V94÷Z…@G¿şËs	HÁÍ‡Š®Uö\îfO.İ¯üÏ| m©0YŒ7’ŸúåéÈëJC9‰}+¦ÔšÇº ÷8LµÍ ã=®;ËğLQ7OP?@]œÚµ…ZâÑæİ+Sö¾ëÉp×^†ÀŠMsO ëDÖR(ÖP	§¸m­9D¼ÚÃ±4·¹äB±Óªm¹²ÂwéãÂƒsv0Êäï"(µ&›Œöàq?0¹¯™_¹„Z´â£5F4™nXİøièçO¹»M¤Æ5HoÙ`e¤‘e:`$ÚC²SA<¢’Óib¼¡ñ» nşœ‚.8ÆÖxêçó`UhsôáTÿ ApLh÷"®ï¥ZÀ™_®r!ÈÉhÕ/aå&İŞ[:“ü:ö™h"%ÖdæH-B÷ß7G^f$ÆÁhQÕYN
üØŞ‚©—ï^Wâ}Åí˜ü©™¦Æ2Ú#®ÌĞql^bÿÓÖ>åí…2dµşp¦¨È·EOØºwÿÂÄıxÌ‰.ày<…€Iüup{BlNF¢—ŠÌŞí³q)L!áÆúÑM&N'ı~?–pE«D{Ğàd•lzohÉ½LƒÙôşBÃµÕŞ½8M—nx¦ã.Á2	ÌNí<al­”¶Âkİùö“aÙü®šbSşn2†ŸÀ#bá>2oòãô,št¬5o.0Ìà#–Ì[*H
pê¶ÎwêÑe=&'[rœ€xPñÂ£O¶¦TÀ­Íê¨Ìˆ|càÔØ”Îm—¹æ®“=‹õ0¿üUáŸ§¬TËU9Ğ¾Ëa×îœÇ³:Èµœ«°Yë^Öš–]bnƒû=ÙdÔÚĞ^j—aşñ²kÈÁ§rYÊvf¾¯í“4Ç'ü@=]p(€´¸¬è!Çã–«¦ù‚!ÑBE¸¤aÅŒ,%9ÈŠ9~ª[4ñ&ñĞ"İed’Šƒ¡X¬\k‹U^¡šæ²Cí:âyogcK4"b¹‹“ÁhVÉÆÏ|8¯ÊxDs.z·¦zïP[IÆ3é&Ï;«iOf£YxŠJVd"ŞL \\ Aõô¼dtiZ+W€UÕ÷È·ÎÖğ±MæY
#=Æ^:ä\ó¨øöŞÒ—òÜßzfÎ£èğÆ/ClLnPÕS"j°ûPÑ°¶Ú-^Ù!W‚Ö…›Æè!»i°ü’¬R<mß’,w‡˜c{t"Ú²D!ıTx¦²Û“q¦NX¼¸H}–’B’l«†®Íh‹‡ºöê`](F¶5v¼	†e/„h¨ßÇ"dEoåŸg…f@RòIØş¹?Ï ĞìÁÁoVº0ìçv»”ñ/¥|ŸÈ#‘îßGÃŠ?éWfó‚¿õ¢³Ï{?¯‘/Ş¶7Û›d«3•,]‘Ä¦È“Óßkü`]Ø"RÔ5A 9N_¬g¢é-n¦ÌÆÆb¾^ 0cGÁ>w¼Ød`QÚúhäÔ%[e!Â3æà¸Mì éÚ1Qî	Å)Q}ÑîƒïÑ}lï€ÌAa'¦ım'Ë$©ß?üÚ/˜¥]XÇ¤¸Ä~1¦zk‘Që?´|ryÎŒ]TšÚ4&WJÏ¡ä+°èC”Eß w›<ØóYÜßÿí‹Ú"¤³G¡êŞNŠ“@ NŞ¾KgH0ºáÉ¤úÈÏ(ßˆÃ²¥iÑ8øÍ4\D†@:Y$ùÌëï§jÃÜßVôS,ì±Í­Ñy¢°8ÔÀªÓº1òğg¸ŞNÒæµ¯f×”dM!Q]«IßÚeÁî(vM<Ò;–ñ!DDÌ—÷FIiàò‚ëÇÙ¾Ê\X‡×¿£¶¢-GX'êÔ¦¥¸^²ax„Û’ˆ$ò:`Âì¡Ú>;”¸i•é‰¶{B·Ÿ‡>ÒV\!YR´+ß:‰™jqî~_³ŠÃW3"?x­`/*´üÖÇ¦ÍoqJJ¶ùKòßW“ƒÇgi%o€ì>+²íéÙÂb;j!!Ë¼š‡ö«MäâX?‡ˆÃŸPñM±ÑojÆÏ3Zb‘o2$2ÎGÇŸ¿æê^æè	û-¯ 'Ç†5°"ÎÉÜ^«İF‚ªŞ~#=‘áïè´ÄG%Ÿ~¹ãm°²'ZŒ‚İ,ªÂN.?ßB!,¡vç©	h¾Í³R¤éÈ¤à[ËÄ@W¼Ğf7µğÁ5THU>eˆrí‹ÙBŸ´”;¥Ì7ävg|fùv´’Ft¥(–²œÌCƒOÄ>õG?±/Ë«úsÂø‰ìÚ<¡t " %‡£‡½B^´†`³wŸäD¯Ëø.+™Şh¾^ócêêbÙÒè|ÑXsÌ`øÒZøo\é­*É½Ìµ±ÈÈî":Ç=÷)ËYÅ,È=…|¢Ö;Y}éÀÖ¥òM!	›ô‚?ùD·¾êŞWÂ–Ÿú”ÛP™xUtQóa?ãŠú”Pb?œ›cD/} ï”eŸx­eb>G¡{ÖÆ†avRVo1ê|Nÿ<ŠSÉ(ü®wk¾qzõ|ŸŒ:s'Áq‘"ca€ãWaö"›Sf8¶õEY‰vÈÈ!® ­^WŠm[X{ ¯óÅzFªbTz„@tß,ÚïoœÒyÙ»(·äÇë0ÄÑjf)ÒQYÖåFÏ~ÆĞ‘À6Ø÷ºÈKÈq—É¬ÿ©ÌNS™7L]À_§sÅm5t§Ó¶×ŠM“'°»}!Å˜÷.8[÷­“Ÿì‡èBHØ|Q¥ıGí¬IöŸJÆ/w;"%Àå}?ò"K“ç´•z¢«l¼*VJè„ìF3iƒ2 âPxX&øx×(¾5xÕ\<Ò…Je¥ÍÉ`9TŠ%ä^ò€ÙÒlŠÿ|ÛıÍÒÜí•D…wä}Ò¡Yù‚,.—òd?½_Ê`Ğ¡XEÀğ)pFºÀh·€DP§Jâ2á¥{÷¡
 öß/†¡/ÂÛEŠš)¿%…O©ï6ëÆ'G55Š¸ßÇŸ"ä¬d=Lnx>±;ôÄPSµÕ 4>_ó˜WKQÎØŒØˆÆO‹µx¥´â>ä±÷,3ŠagªOèi±ÿd˜‡şj®ÿş²åèPˆàŞ–_|ˆ=ŠÏ#©7+­Ã¼(`§V`’äJ]bÇ£TÑA¯f{ô<Ià»k-ğC+hôºz±îEg³t]ıÛ¤ó>ÚK\‡/ö¤Şl+_øŸç´ŸÉÒñ~ÑSĞ’]BÔA„İµ:Õ—ETVF û1#÷Ÿë¬:D.ù#2¿*°2~şõeô¤Ã0Ø&°3všO’>Ş\ÓävÌÉ¿O5aŞ^Û'ø²«ĞÖ²|\Ï³] )PZ´Çşšæuò‚©½G¡œÔ'>XŠhËÄ²ŒŸz;øÔ„£]b€ûû9.Œ	NáP½áöJn<FœQj»G59ğJSµd'ÊÛDÈY¨¦D¨èR¥­º&úÏÂ±°n8_!Ñùõ›Í²fG!—µ‹³³jáÅ˜yoÑ¢p8ƒP¶ÙT´Ç)!‰ÍœW 5®Ş1\e®Û•óz<>Œ¶¨Ÿ6öºwö/v§H†=³"TúC`=" ğ¿I½šaÅÁ¥]¼=Ø Ê’"Ø®Ç?ì(“ö°¦j¡VÍß¡V=j•WW{É2Äş³)xáH¤iµ"ği(Î5Ş¶t… Ñc’FälœÓ¨¨`‚ãµ›+»€îÅ ¾üĞ·ÃŠ®„àVÈÉ^„GW†fØå’š° åQŸ`šxj¡lÒûµÄøƒKzÏí7ÄtvW&Ò;`®{µ´Nèş¿z8“š‰¾ÙÍFGøä-ì?'Ï_6ÔnSpıYß•Üy9°£üTëQãQ4æ¯ÆTäÌJŠ_Ne£æe÷v<œHéx¢ñVošÖˆk¾Î~(e¿JØí­ëb˜G´äaœÏÓ"ÔÍ`,PYcPÎY²O“»Q~Kæ+K[¤•İùfJ$bı.è¦p[£ÿ0qÍQé*¨ş8¹.=aB[äÌ´¹Ë½GMçaVù	Gcü¥Ğ`å£æİ¦¤€®s³„»meD„-Æ°Dß·‚ª#a—ùş-³ä“§šü!›ğÑ¡uÔ®¬i¹NJ@­`d=d—P«Ì#?¿X`ùqu¢ F'’wÛ(ÀXJ >ÁRyÚã»XÕÇæ}ÊAƒ#ŞQw'n;ˆÄç6óĞ[ö¿kPªiòª©Ä(Ÿ/fÄ|¾å¦Ï½4ğ5¿)ª_ZŠ-U<ÎmSTmùçºŞÈÊm]šîõV“h0õ0I$•èX~L¶óì
Á©ç¸’»Nvß6ÿ•ó} A=›%ìzÈVÙ§[|O>9¡ÿ¬m³Â‹É0¹¥§;˜ÄÚ}Òÿ,üZÁÁ{½vÔÿ°™çÉxş†Ò)æ—nş”Ô—R&VŠÙ“
Ã½gÍïÌsë{—u3è:Y^ğyŠíµÂ³tşš‹ÿr"ÍÂŠÚaÀËÑè™ôYKçØƒWq²½!èºô‹‡“”„³tHÂ½Ş¢Zñàp?'áãcæY«×	9ÅÔ†Û|à‘r!MZZŸ§dJ„E:K.JR/ÿŒ² /%a#X³¼Ø¢lØ£ŸÃØ´—«ÔŠ@q<»mµ”O¿¯O7ğ,Z‰ĞIXéx€’'jß'«ñiŒ×R2Íğ5?(UFn—·'9êgIÅÚbL5³eZ»‡É®	òüoé¶è:)!2Òïú±Õº*ÈU®×Ê×î	m“™•,"/<4…è¿ªrµ³Èìæ‡¬D`¢¯sä°À’ÜnN$)çÕ)ÄDtâ¾e.wÖ#jP+}:bï‰#°.ÇĞ[-T8l/^ì’VÍÄë "šîUºŠÂkn›ùNÛv&Wp¿"VÕÿP¬© n‰wŸ/V¨ze×8|!uQâ…Yè˜8j]¾w›äIò;SÍ…™¼Å–Şs?®Bç…Ì„
vc¡ÉA	ÈÁ¢oøé4L‡E¿ˆ`ƒô­Ğ¢áÚ¼2k)°W§¬±šè‰¹q7§ÚÈıÏN«ğö¹#2ÉArV:·gÒg“¡ÂrÒèÏ93`«9İu‰â£Ëg$GÕàçvb³%œôsEA7™–/ÓÀøïpİ¤˜âÏÅĞè|å;¢>ÅCwï‰»Óùù Eyu›6³ª‹åİtÿRÉÚĞËËÁšK}Yo‡Ô7Ëö#MR¯Í?H’YGĞ)¶(gùº¬9o ÏãĞL“öK fNÛ¥/‹j{RIój;x‡i3wš'’%®N n¤%‚úñsçÏ­A™½ÓŸ¼¥2£o\õµ`×iÜÃå5¤|¯¦U.ŸJu|L>\EÁùy	Ã†‰©H« Èğ‰¦§E‰¯ææí¥
µôbÃ93Y™ûëÈšó(Ÿ¹‘—ğ;à“ûtmu™ö¨_:f'æxš;ôÙZò›ïJ›Ëè‹®¬èêS¢ß¨6«‘Û4éğ·áH*&H+Ùêö~â'%ƒÖ˜Ï>@³RåÉ¹Ml;9æDŒ‘6Î–øpKjovBÍõÓÀ9$ Wipn´±’6Ÿñz‰.(GŒ‰.âiíÛfœ1-|º¨±1jIñiçñôy)s€Ä7ÕKAöÿ‡T³L‚¡ê!c¶
¡8b<aècë*Ï˜ Î'½ôe%Ï?÷Tº´ĞÇR4ñ˜…e­:=gË¹ØëÇ¨Ÿq÷mÈ½ş®ÃHi
™Í2ª@BpıwgBÿ—ögjM&m"l³^ìKã—òìy¥Q¬O«^‘ìDöv2ëÆêuş©Îø~1®îÉ­cö˜ïtRS¤-ñÆ´ µ{N¦8'm¼áŠ–dª[æa$h…>C§¨¦ÆnºS˜4K¼HaçpŞÊ9ùX»L­ØÏ÷íe—rÛˆBn“²ôµú"
¢!Üš ÏrX©¨èXZ¦™ç•1ö…áŸáÅEGPaßÕôCrJ¸~¶’¥w°‘ğlcÍÄŞ½ï³»$Q™ûS©*¬j/îê!¢Ê‰Ÿ¢mÂI[?âa©¸Ö Ô1–KÁ–læÀÀ4ú–wD'O™¾r)—±÷ŸdK‡¦Üé‘¤˜0ÏPmÉ#S !: ÇHo^ÙÂ…mÑv{p9Ç¹)´«FlÃŒ8|Ò«ÖûÉ°ÙØo’¨¤9cæ× KüjÄÙÅAÈÇ\
Ë'/Ñ”zE¨ş>(Â¦6'G	o—?Ûµw9+·Àå?jqR¢Æ°QÄÄ¾åU¸£•©QÙ_Ül¿°ãåµ“‚ûUärç2Š E1‰ğÆíA¥ÅòJˆ§Ì¼äÛ«@§uØ
°xF<=o˜F÷p¾ã†}Âº1ıÀàWDÉGgâæ„ıØğ "F¨Ès‚ef…œ™±s²õJñ< ‚ˆ‰u}=Ø
ìÊdoèµ&*aÅ¾ÊqU¶ŠÕEïODÄĞ‰Z=Me3O=?»¡ç$kf¦> Ÿî]ò?)ßgmåÇ:”Ê´ğSó^üd]$˜Å/‰Lßš	cª1ªåmã “¡ÅMA×‚|ıGLªğtGÇıhA'åğóF*¯“°zK+Ğ”ıGİÏ¾øç_DŞã¤`µ¶[[Æ7ÍsE÷±®-ïŠG\‘)O.1)},ãËü¡I«]›Ø>.xµ˜s¯FNjÕ#äÖ¦÷òìéò]yÛZŒ£A‹\ı¥îy@!Ú=£,Q
òûÚ¼*È|´'Æ¯iôZ)„an`–Ò«Dß
?|lgVëè=’æ¨A‹rÌş®C•µ…†!Ûé&É`©oşì*Ñ‡îÈÀØ€¬4Æÿ¶7÷ À
-|ß›Jƒ®ğ`™¯·YfÚs
Ì0ËxèÒŒuü=!·“4£¼{Pu6‚†’3cå_™ñ1UhaáCh20ˆU9ÎlI4t½d¾ûšæ'ÔIô™s”é+?€ŠÒêEúLTÚ\jL0IõúÎy¹Ìo±Œ4Œ Úé~Šyî#èpXÑÈpRõƒÙk†æ'Â,éòrî%úI<átÆÙK•ò‘âQ¦ZšÑÜ3Î Räop£Tüèl:Ñ¡ğb©4q5š¼X}˜¿÷Ï§›–Ê—ÿ#ÒUÁ˜$"0–%z>R¢œ›÷C²5ó0QßjıØõü>{a5[ºî±ÄíW[{±lq}@æ¬É³«¡.ô½…â9:oÑ9GğŞ­B©i)ï'ôhÚ¡Q,ÖÅÿæ±õ–-` uÎrÏ-IŞGuè$Ò×¥/Eİ¸FoşœÁyURuêá±‹O9ÎcâOÙ{ ˜%gĞ=N[, \úŸÈHy,µ˜_$=¶£‚}oÖÂD
5M€Bh|
íå2wÜ=¦Š™¬ûÊ}I†á¾""Îœ™–«,}TDaóıyš~›D`ÿ`/^³«aÛ%`èøå¨/I0Ÿ¯“_®×‡y…&>D¦Ïóæ>İõSŠîJ‰çöi>†í{7¹\)y¨åtûIİM‰B¹lİ·¥6Ó NRÅ§‚}{ÑÅn{ÚYËÁİ9¤´¸’êqïı÷•ä¯ÏàŒ}~§§åÊ{âd‡İ"J7è­8¯6èQ"V2—w¾S2’€”#ùC 9»%‘Iû&9YZiqÌÊz¸W¯¹)Í/Î¬1p=sª‰¯ƒ-Ì³Ã÷ğHÖqV%Ì¢zæ¨˜Ó¸Øn(¼jB¬Ê©à.M'ú9ú¹ÇÃ°ôØW¿±Yôéi×Ëc!“ í'šfZDÜh'Q.«sx9e3´‚›Ò±ø‹L[N†‹¥˜ùÕXsòÕçã1	usCÂC^N,vÊê¨ àÖ*g‘%èÉúì¬˜5_¾lÓ²»ôÜvü\Ënë+°Àù­Ç¶ò€ò,¨ÏRtºM‡a€öï—ë4×M“]€ğ‚êW¢‘—Â¥æ2€)‡›v·GoÂÑ¬1V¤húı"–A†xŠçL¡3X®î…G¬·0s˜1òh³œ§.<-î¯@UƒøõN{>ĞÙ1<8¹ò¦÷zE),º¬îì·—öZ+0ÃÎªû„J´ÿxD{@)ˆê‘êF¡ß8–S¾ğ"ŸÏr™Ø¸ãÚÕ±ÇÜv ÛLk÷;PiS`7,vGL@zƒ!ÍåWÑE¾}ºZñœ×{ÓÈ¤Áï=€“u]<T¨ìT zr~eßDeÖY8D0\"t:½ïTÎ/9èé7®ÀU‘D½¿„§–BÂ§;ÉŸÎB2~ƒªz'¹¾4g ûèê<T=ºGÉÒ€(ìõ@²ïã6;Xï™76ğøˆì¬În^˜ÔŸ®$+ÊÀ‚¹[7ÿ
¶\hİ‚”çÃƒhæ+éŞÔõ¼ñéÙÕ7A•}ú9Ä®6îLó±´+ô²$aŠiIO·M>«4~ŠZNÆJ€®B&-!à%Ş‚²—Ö"Åkå[c•c) pIÇ˜à«Jº¸[z¶™š’™d«uÉ àÔMC4ešÈ±¯RÑFHYVl"ÿâm‰¡*EáFÕœ¯¨F!w¨uÏ4êO^@‚ÑLô$C«İ¼{±½G¹mœ<ÑœhòxeãK^•‹Øn bç-™Ê`ş™A“€õŸo#–òâ¬	Bt§6>~„Œ´ãÒ)ÀV÷“#UIüaFS¤Ã@Y¬˜¯îÊíüJƒŞ [_ƒv! $tB ä“º£¼®(2ªyA{ ¡®RœÅäkìÿU+)3şº²d…`asÜØrx¸úqŸ‹Ï¨§³f–„ˆşÒïK»ÎëõUWúeŸß2²Cn“&"D\b±ÅÁ§ï>ÓãŠlÛ„(¶MƒfM”7jİğ«¢ÂnÊGêø)l²ß‰uÄäèØ#Áêg±ÿLœ~Ÿ"«¾İ	!™“-9ù(¯Ú Å
š;ŸM,–­NñG‡ØÉBŒ“åæ×Ö ÙRL,e…‰…lêÂI «ÆÖ.©6æ‘Ì{QhPGtÍ¾}Ñâ>˜ììV#¹îz¥$ú«¸Ö¢Ï¿ªk½>ët¯Õ°ŒÔ}Y”OÀqÄW9¯½N4Ò\­cÃo”=¯|.éÇqÉI;‰Çş;g6ÈU33ßµoa
ËQ¬Åİ à¹¡‰×Ğ ÃÜ`–¢C64j(ŒûR’†ª†Ô÷J²sÊŸŸÃ}Ãş±ƒ<sŠqm´¿B;ÌCöuÌÏ]¡kò˜1›VİÔWé üh~.#³”¶Ó“nóIÆş4SwFÑÜËâçyœ¾¶âKÉÒ
’b.™¬ÈUyŸ¡ñ0bÓ?Çìi†
’@­·­öˆªfO_9SB¯¡œô‚=)×85¶@jĞG·eÄuğ°a‡V,*KÓ°‚¡ò`§…^ÊCGıTë"¨bôFÒüÕı…™b‰m
"›T›LãüHpßè¿"ºØdùj®qÂ}A/ôÔ6R»€»óª°h’÷Ã¹á­–¤•<Úl•’9ºUoÃ¤>!4;€Onp‰¬ËÎ¡ÿ^ºÛñ‚êI‘ó­u6Z°ÙÁü¾»1í!áVíãEU“í	šÆ}SÁÖ½r¢e˜L5ûY]Ü*$Äø+;EŒdÜ¾GÁR8#çN¥¼»"®¿Ée˜j$P„vU>oéq[üïe—$È„ƒ—äc:€Åèh| ¥ú;”&¦Ã¿«Ì|÷íSÃá½6¦ AØeô¢éXî* ƒ¥&£ÖR/n×8ÑÆb©$¸-~<Û¯d¹
xƒşšúĞp".äæä¾Gõç0l4Å–õõJB¨ıA¢ÉúÎB«D9¾	
&é¦Yæª—ã3
:J—S@§ge”İB´$lÍzZ8Ÿ9§/:D{|îÕ`my
ò›VÎh_Õ²31¤â‚û–«ÊSÖ–Û ^Ä\ÅÚ÷ÇŸ‰ŒœŒ4ğÇ‰¨±&¾ j’Ì<šaÍ	„aL›ÆaJĞgaÙŸ•÷´†&‹æ¶+×²ÎÑ’€¹Öo5CŸÌ§CT€Ÿƒ•ö&Âô„ïŠd_Qâw5j‹j
E}õŒÒP^.ZÌ—|òór—ú8âX7çöØA8&/å÷uÕüÙ=LÀKûÉÑ±	âi-Z·•]\†a©%»$ª:{¹iÒ\	3rD—'Y„ÔşŞõw„÷@$F“uáéİ¦ªµŸ(.æüW.z¹ÕWöğøó6ôrş``WÈ½¤(æ'€¥¯×MòËq•¹œZklô?èDà¬¿ÁnSî¹§ùVPlˆ'ÙÅ˜?úP„\/¨¤ï¥'¿ºà9DC\tµ®ı(øì5‡İİ«ÈÒ%¥aëdPù€t:yfYx­àZ_ğÓEkœÖCw•aaU‰(•—í0ê ®ûÀŠìè9¡ìÃ#±3´%‘µàjt?fŸÁª1´Ó¡¸À®‡:Ò gYÜ;ÌEÄûŸ¼9D]h@Iî›uaSK…“E*µ$<ñÕ±9xõ>y·æfÔ¡ô+ŠY'äÛ'ZVq­ëu®Z8õßacÁ8ÇF3”…+ßœrZ<†¤¶"*Ÿ-~PB›ùj]Y>#ëÙS¢[ıã’`á÷	ü)3ä”±ÃO‚'İGùÀ~V·P?,aFoéh¯N&‡öåœ+EÇÁP]¦&t-å:9ï¿+Ì+å~p*”ê®?oh ÂÌÿ…¢£WxÏÄ¸ò©R$SX5*¤¢P©­ş¼eÑĞ´}6[wåwÿ]O
QZlÈ …gˆy5æ!­¡ş.nñ¬šEÚÓpK¨Áyé~W+¶@†ŒV8b¿ğã'Ãáïsä‰7x/U:SEcŸ]¬"ÿè9·_Ôh;ô¨£Xù¤Â@ü‹U4)×	K­di1Õ8yµÕAEµ¯–‘zĞØÁK$Ü	$ßZeJ}%în—!~‚LÃÍrÄGöÜş‹ Û6&GY¾]Ö?Ã£0cO¯¼>„"Í¹QÄÎ@ìŞf€Û“Ò„œV×è(&ğí“ÅFõj0F›ŒyÔ)Q:Å"E›¦•òÃ¶0Ro£ıâ Íî|â–Ñ™ArgS>•‚ŒâÌòĞ¹²©ó_8v;n¯É¼­9íFg¹dcÏ0`wPƒQ6òj•p†ZAÚ{Á_¨N—c}"ıÊy¯m€BuÓB«áVç¦èş—~¶ø˜í…–”BpÈÏáiH'_¾	
·›Ô‰"q¤È½{Û,Õk‰¡È>afºOØ*„©ÓßàP·Jò´¡ÓC¹”÷ëÜaÖe¯ÑÌæO¬V£K]•WƒøZ.¾°dkÎr·š«©|™1RDÿRè&+ŸÇ]ˆ©­Âoë‡3>´	‡3û¾Ó—+œFÎˆ´ÃqŠKá0§Ö "“gV ßf¿ÿêº,~ŠÑÁ²­al énTÆ²ç•ÀüóqšNÏ¥·.hÌAÍ™Ï-iøºÈ3â°X­EŒWy¢<Ø R_3™§yÎÙÿ-*êğÿŸY-^v*ô¥7şYıá=‚âƒfçæ¿ª5$åÛ¶••ay7†ÚŸØ­â‡™ø%jt±50+wE¯só<€š»F§ş³Ù¿Şßâ½™àç§Iû‹ÖLK/Ù/ÏñhICT«4Š·˜to†²úV¤Ÿè?ÉfˆŠ§øCIáéAl–Y0Ô¯Î Nbì¨;òÌno2ÇO’]™üMŒ»ÆD’ÁìóŸ_ü>nHÙ¿*BtZÁa#ThÁâ½ÇHS¯â#áµ‰Îõïå_i:€şR	†
İ16Tı0±&ìˆéÒ1>v…#;y¹±Ã½@²\uİvë é½ÚÏ…ºT‹_¤C‹~çO¸kEiÉN‰‡L½‘…@(%Ê0kŞ—÷¨Å!7ÜÃ‹bñS6(~BœÕŸéj&îÙİD!Xf˜“‰N3¥EÜ¿`©Ã-•ùçpÏ»KçÛ:³Ñê(´À´ò‡]X(wè¶Ïi¯qÈò¬æ‚%¾<‡î‘½Cs¥ˆºfŠ=% VPÍCsø‡ÔJÏ¤Œ6_JŞIÍ2gkX K/’÷?šœt_³¶äyŸª‰× ÃÊPúÔ[4Ú9mLç-ö©å<µUÆÜõÎ»#_ÔàRuæ¯Œøq*"Á>,ÁÎæ³¤x `ß­õ:ìP…S%NÂÛÙ[a‹ÔğÄ¿÷çÖ%i²Evr1Ø™~jÁ½N—Œ&Åc¹&,;c¡Ğ´L	NÒdÇID§…üÁåd*3¬*z…'îs¼˜†ì( …;_»Ìéütù|^Ú[T¡“ähúZ‘ĞHZ—uï¿'†° ¬
w<*•„¿TPÀd›ÆİõİĞÀ=—ªÜ`}ä/PœurQ$T•3,¯JL{úü:E:ˆˆÂ¡Hÿàw=Ç´ù\Ü¹“ŞŸ!_{ò¢ÆÚ¼Cæß‘ûã
Ü…DÆå)ìáìM´)Å—Ï¿¶L„IJiîŒ†
qE«ÅfW|WßéÔšõ†œJ•Ğfon€+zÈoé€‘ _UfY³.ØÙø·o›Î\é‚$+2ŒˆPîÕBû(Ò™=sŸÜUœiM—[‡};“é-¯pÛåc>A6ˆ¡†®JÑóùƒÔG‚ûÊï‡úñ†Ğ+Š*v¾°g
2oĞ¤òJ4İemm„'¦Vç)VHBqİ‡hœdÃ.øn__…Öè¯Uj¼S„èöO2óK©êßf$x™º` ªLõPo€Ûb°l%æ·ôxÌ$OG•à16tRñĞÇŒÖ
¬ŸŞ‘xëv[™N/§M]Ğ€Z£Naâ›E¾ÿâ3–D²f^É®„ãTà8¸›hÆXÅµz°#`Ûä’şjVY£³h˜ißôİ§2*Ñ)FIe€	ıÄë§Ør¶B×*´Q³ó’–ÀëâE²ªœäp¹š—DRã0yÙÊ°ÁÆ—Y…õÍtç¯J/Ì jéjì‘T‹5ˆÍg¼ˆ(>Ä•òR!ö¥üœüÒWX‰·½7"øaØ±rs‚_I_–â&2 ×Ãú5)&Ãï€¹¯
“y¥eLÍgæßa…ÀMCÚ‰|G9;B³Ä·M(ZEG2£?ö-ÒÙ1Öˆwè5]öÁq´T~†Ññüæ)ıGİ“Ş-§‡@$ïËCô;RQ4¨fy¢[´î¦,ÀøÈyØ›S¶kVµÕAd5]©mtßçßøßÙÚNĞËVfÂÏd½ü?—/>P¹)Y"Cİájy‹½rN	•7C#råÙån¸“ùR0EJ«¶käÚ±ÀN¨Á.ƒûøæØ¥£ı%`<94dL{‹M•õ™Àoù ÑízgïƒÚFœÙùÒ—:ÙÁ{¿–DÍø;»+qöÃcòD‡ÌxY·O&¾­-Öj
,K˜úÅ#Ãâ]lÚVf`)õ¸Hşª&N{x]‡üQåO´KïÄnF/“•5+#/c	‚ô)çngiÓ­“è÷œ>=f6  |ÊkßZ0ù ¤¢€ ê.ÒU±Ägû    YZ