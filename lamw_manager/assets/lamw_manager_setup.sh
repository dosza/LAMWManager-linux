#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1536686250"
MD5="79c82b08c1beaa231565fa3082b1e72d"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26292"
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
	echo Date of packaging: Thu Feb 10 18:10:37 -03 2022
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
ı7zXZ  æÖ´F !   ÏXÌâÿfq] ¼}•À1Dd]‡Á›PætİDùÓf-I
˜/n\V‰².•Uğ•yˆæü|p0,³lÑ…hÑúP?cÒ½±s}FMrâPĞ™>È?°àÆ“^½^ªÂ:Hk:@8ãêtš?á^Uå<[%‰Úç‹S[ ş‚F-ÚK›ş¡ŠsœŠkÜÉa¦yD@£†£O`ÔZVº;á9U†óÍ+Øò C\PàO¥’l»· _tÍæ¸VqÏ¢†–­T?äi‚S„bµú# ¥}_/2òC;¿s"ér£¸ícDíıß[zÔh$|¯•–†¦‘MYŠ‰…<·Êj+¤Í\39–´d=ÚM==FŒ¿šrÊ8M½oë^;a˜ñ=?«Cûqeußcq°z1 ,ÄXŒµ‡şójTd"´ïNSËæ²ñí/¡ˆ¸qŸ„Îû{”1y	b§¶#\ì.‹…Ëgh,ŸJ3qU‚Œ¢Æ¥„®18		æ“~‰ì"¯Ç|ã”@ã’·¥½İ'hÖ]tç{zª*W¢àÅKÔˆ~¸_®ç¢TXº•˜RíîFŒÕrµÛ˜29ZÍ¸‡ŸA1óW'º^3TÆ9«qŸ¡G«½iJÍ 3Mîa|Ã*=)BÁÚFzw•xÓ.#ìúÀ0ÌşCVSaşFw÷qó²'@.Èqu×Âç`-1Z¥Ñû³4·BX‡ØY5'À€(óûŒ"îŠl+lÈk ÷_@«ëÒ^úŒK¹g*È·÷ÍNæd ¸XwÅC§MŸ¤ì¡!)EQ,|êdó:·F×¹İQ”ûŞµVÅÌ;=¾éĞŠÎôrv¹Ö¤!÷ÂàM¹x³›Ì5 xmŒÇÄk”‚
ªŞÇéX81³[å‘:«‹:q³¿QóH…º6Cir€Ó	ÔC…)›lå&p*Øù>şHNœÆhv¼‘/}í ó…cVa xÇÅİŞı%'•»œHAy’‡`K³oĞ~ÓŒ(—[5ígÛG}¥?xÌá“s,´ÈÎĞ¢6oHZ´ú˜{Ú$Ïr…JüaG°¦ó¸ğ~ „ü½fÊÿÔ8ÎWˆ’ÑlÍä%J~ø:_ˆf‚[Ë‘ÓÍlÁM¶Â7Da3şVë´ü!‰		\r8 ú&ıcû§„cºìÂî:2ğ*½\¥'ñ#Ğpz3²?Z¶k?Ô‹tjÁâ}',ŒíÔ ®>" Ïf½Øßı¦İøª.Ÿ	Ş·Oaã’“"ó­b3]l»˜¥ÿ@[ŠlY…Öucÿ+H6²áú”Ÿ„Ïw
ÿİº¦4mm–¾0×/,°z¼àùı:¶c-ìÁwèdÿ‘¦ËÅ„16ñàÑ2Bé{ [yT³m—Õİ8êó1 Ìš­ÇT‘«ËQôt¨B/í³'hªğ}'o74Ü®)Êtç”G¨ĞÉ#©dA="‡U¤ú¬¢j9€±˜¦<àšœØ3ÿ0"j2±#SWA®Ÿ¾ŞSø1¢àÅñÛ½9z{/]4İ°JlK&×"N-ç=®û“¥2<z²ŸtU›’`™Ç,Roc ûáp€n>á(Š®‚‹"¬‰¤‰Vs†¼BuŠwxèˆdá!_g¶Br}š9!é	˜0È*05emCLÅ~¡xç+””c]÷-¥
üH¹p.~©4WFeïŸ@[å0^UQÖ½½eõŞíñ©új¡¶(_	ÛÁ`PúŒd
_Âë«ª‹p¨s«±
ùÍ)†aXÏ›åğë./¡ÕWíé‘=DW?ÈøÚ`”ïdºvZ©­Ã3Íû•¤§X©Í“cËGÚH<n²EàÒ	\A|öËî¬·ç>{GØïêÜáRÇŠ¬ùIEï:oûº¨+ue’;W ƒTës¹ñmë‡Á%£>Æ2ª]“9Ğq S‹I¡q7| g#4ú¾%§oæ&Œß(òcÄ¨øœ‡Ä˜c¾YÈU!‹ãmìrñ«˜US¾şp¦QlÎÜUuBØÂºÒ²LÕ<Q3®¾àÚD8(“£ŞZYØ´fF<DÉ º²2ïVş¾[Ïåúˆ—X9LøÜ2/«JW¹¤§†ù/ó+3h¢cO¾JÙ!5hÛ„EïÃ•Ñğ¦ù½â2ûÊ	~éÀ	¯ õ	"Ë/»…ë1Ñƒ»h	Âkktâe>—Ù©Øßª²è79M“_¼Hj7¸x²° °™ït#xM¤ŞH†ã`}uGê¯îtíşùµ¤ğSâ€Å@ í Ç-•QôMNºTUÄÊìĞ¼_Šş7:Vâw)˜½Ù«ìø
m¶¹„ãÛñL*"|÷ËRRÅHÄt2A9^Šˆ;”,„zĞ«I9H(›:Ê{dÅ!EWG½…zÉ¨÷^5 \¿· ü)KÆÖâÚ_¶”ÜGıÊ$	>‚d`¸¡É¬É®0×Ò\:âØ‘ÉÔwœiKÅF™DTÚìéTCñÉ¾Â†æÑîP-6’}¿FÄHø%Jİš=¬å¾sZ…ÜT¶Ã³ÚF+L/N#\ÛdJH'ÙóÇö­]jmR;ĞEöY'ÑSøƒË
U¯›¦bSh­«ùse¸"Ÿì4UJ©ŒHg{íøÛÙ¹ÚºÙ/Í$ƒªš´öA’$:ğLı¬$«*{È¿{Ö_@VE„>‘ætì¡YËøNu<P¼Ú¹r¿™b®iu3+ÇQ4­ˆw,È¼³1áøŒaHÕê_±gc’=ÈÅ®õî£qRt?g~Ï@ÃÎ±àû°N˜Vµ%…VÏ9Ÿ`UÙÖĞ)öT¡Ç!j¥ãír‘\³ù÷\KŒé+«È½´\yFYªÀ”AÓ?ozâ» ıä¬Îa,RÌY&ÁÕ—ô¤
½¾`²šçÉ0ñÜMoñàhµ+ÎTVo³Ü°\T“]õÚ÷í—câ§†¼¦$2Y¼;~v56'0*OµÅ0şÙÛK¼I2aÕ>F/xHğzSÚl!îWÜßÀyQò„©i¹Mp|
«¯šØÁËäÏ-1+».Içóû{Í÷]½„cœpWf *!Ñ	›m/ß^ôëÚ“>f€¢¦äp§á9ŠÅ„ÏN(Ğ¹ÿúe¿˜û×ÛÙ%}h›
C×w@,Ó:nµ]ørÉüùÓúùvÓ”ÈÀ~™ßÁí;À	T‹â3©¸xÈé¹ÍŒK”³$“Ë
åyŸ6 e£§š¢Ï§|òûp¡Ú,:¸JV/…¨]ŸŞ5Ó<Åïõ”-¦÷³îDÉúI3H{½É[g†WeK< x!¿xT?]‘ÏÔ6V~Eé£/"<[Y„qÁü€}Ğ¼Ÿ´Õ’4ÿ`ØûIU¦‚pR­İz°ı<ÇQ‘½\õ«İà!ÒEÄ›U‹ÂH_…Ëº—´—3¼ëoêĞu–Ä/*ú‡èÓşudØXlyš»,ÙYÂ”céÂ´6w`…’³n®G¹<DÅåîPNYL@‚·:‡´îrc wı\ÀaSGÑÙïüĞK’ÿšx³jĞğĞë^hMeÄxíÜC™%¥Š{ÅÔä©+=£pnSYîü›{ü2§,Èkm„”ˆí*Q˜®ø¿àq,öKO–ÎŒkÆÏâ 9aZ9!ühÑ¿ë¸¾9tûÏÒ‘Ğ:§Ÿ‚ğ;1epË-wW>)k:U~ì…¤à)ÛkXa;çOœâJ.¼½Ğ—¼\tKÚ—‹l›+	èÚ¨švñÍ'‘W‡¥ÛŞü0“`¬Töÿ¸`ÓÖñàA}n"ÏêÁè¨œß}ÚyÔP„y”’ÖéÏD©¤”-Ü9L|[•µøş.i_VTvÉ§ûQ/ÛO¾¢¶””£+äbn¯^Î%({¹)í8Cc‰ä†‰	°Ù°°´J·ˆbO³WûàÅHÀj´0údÊ'|.IíE¢]_û¶”#±Ú™ogÔ˜šß¾<Şp~&îï¼XG¸/jpW³‚“¼³:Ø)¿›@Â`¶·Ïğó‘øÉ£Ÿü4Îæã9]‰ô*Şãî5ÒÊî)iNZo‘í'=§CíA»]ÿÊ$È+ûI‘eC×õì0HmÙ€&{fNİU²ó|¸)óäHNåOan¹•ƒ
êy¢Bto5!cík2EÔr+´Ÿå™‡°é½6‰4ÀÒ>‘²Ù¼<¶:‹h–GŸúû¢¶¼´lµÇÖáİo@hşjÎî9ıø¿™×±96°Şä[àö™EKû§¯9·pBLƒÔ‚d'U‡í™@ç¤7ëjœ «€xE29,v¹œƒÖeÒ×‹”zª_ŠvEÍÓ—³X†õ4Ïs…aîÈ§2Z ET2s$RğK3g/Í÷vË‰ô’:ëu\ıäıLÄñX³V‘»]&›Ï’Z
x—c¬)MfÂO²Ëçvã„ÏÜé“z–÷‚4¢3ˆDƒø´I}Ğp8ö¤ØåpM·¿à¿í_BIHgo¿>g8ˆ¬ğòÚ‰b7ª@>ÿeyèV€ZÈpZ£Åšb„4µ¤D7qz5ÜÄ>­¸Ó†ÍÀ™î
ş'Î#ü’Ojt]Hgç¼ëqÊÇGõâäeƒ–¯QÎŸme›#|Š:÷àœjE/"µyÏ™Èdühñj[üá·¤ãĞä™cìÍ ­UÑİ´‰7ztÚ„*ô)w­ÔfŸ—Ö•=&ï«§\mj—<+†6šsDÔÄğæv>á‘ÿ•`­~ùÜñ<v1Jf‹Kæ\©Ú,{pózğ>à(y††*»ğ&qQBtK²—XÓä5Í\"¯ Ì=Ë´H/´’QK^ıÏ¯±¶=>t¹_¢ÎÙ˜âJÖ&Ø°Ìš!ÂhĞ<<åµYÕ¼S–ÍÄïR—Êğ{@Í&ìäà«²eÙ™¶š·úÊ®»óÿ‰	…ÿŠ7 4tõöñÿŒãuHƒE¿wÄáò½2ÍšàÆÔÇéö%‰.8B‚I¡ÚÇ&è‚'¸Ø	TY6j½PÜ”fÛL€UËP®®ÜÒê¬ùÜ?zƒ¢A0j§íx5Ÿôù^º&Jl·şşôXtÀY~öâ¯;*l|˜¾¹ãó‰eñq?8ÿï>rcàvèK¨íÚêuN‘LşçWÍ2,ß]¼ƒuÒÈ—Ğõ\¢@-ä|Â0€špà¤·¸Ï¾'!²‘/Œ.z49!®'2ÿ#jû†}I-k²ÏĞ¼ds±‹ûÂùP¢'à¹ğ
5	Õ ãUë¹<…4EƒvÚ5;ø¢%s#ñ~8İòGås¯ãv†]ÑÁÎqé®üÖ5AáÇ²„Ûdh%Ç1r§#ån½§)©;ƒ*Äñ·ÆŞÈÍcDƒ#Ëô›üîø/¬>¨é&êß 4Jƒ1¨7ÊªB«‘8¡GJI¿.™n )S8É2º¶†AÎ„«Ç;>xŸğ×1ÔÌÆL9Ô“İ?X1&£™¡¤K¶Ê»‹¢`DÁ…ß•y¤«grbÀ¥T{YIÎy‹dôœ
’KH+£9I‰T×ızC×\½íáœ¹m%(a”ªzïŠTd&ûsG&Ü+äÿ~¹«1®^w´õ#6?Åvnô1×»ë+µ¯?£ÁH¯WåEU¿Ôjq4:¤…*`XëæMM#¿¥ü?ÿ(‹÷\ºø[6üÈŸ^!§0WˆÖ^şX‹ykê.ÈìS¹~ =Æ¿tç¬à>ê8Êm·B®¿–DF†QDæÂUj`™ßôÂxe ¬ñ!Ö1eŸ¶Yzì¢áRs¡gŞ¾ı_[tp‘Ôõós
¬ «Èé'30ÈåGOa[Ë7¢ÿ…%$RY<œÂşa–œ|„‘:¾¾ÇW z9‡¤¸74Oí˜	qTÆ×ÑªŠt–-$»F:–şr^<O…M¼ê4ª­?×‘ Ê§qfŠ1’ˆ» ` lQ§f'ÀÃš¼Y‹şr0‚<Xå>]®æ]õ{Z:ƒ«Gşˆ€¬¨„êN8¹Èc¤ª…e‘r«¸—ÃFl˜É28G)I¾´DçŠQ	eO5¶sß9ÓíuÓúB[{×†T¯¨÷T0ºU@Yb ê€#4Š!pcéç]ëƒ~µåGÔ6`p+™w¨nÍ“ƒK~VzŞã–à`¡{D; çNò^Ê½+_Øî»ÅØv¥™—lµ##¤•|E¿3Æ ú´ØQ7eyòPÊ^ïï½@x‚OøçDY×½4ëğ; Å©\x]ŠÈë*¯R(ZgÍb2X ±k,Pˆ)T(Z×ø"ˆUóµS­åßŞò¿"½¡6Wägoâêñ3Ì|u°‚ŞÏ>`~‹–÷…GÈA`í\y³éR³ÆcëÁÊuõY5›ƒ-mo¹§MKÀòQnE€`öRÖwŠ\º7Õ	 M°’jWÄûa°v¨ÄË64Á¼êúUƒ^-"´<FK¢FàÔı:¤K§]ÃUù'J„Ò‰5Ähd
ˆf/S fêè~Ë¨ÙŸğÿ±õ4ıƒÍ¢Éj/à$åÓ¾`£¡í*÷Ù0¸éĞ^…l)‡“êŸs»,VÉ%±¥uÁh&sõØÂî½¹1(&4‚èå%É2!ƒö° (Wû2šHÒY´şÁ)–ô¯¹9g9¡Á[Îdq]»†n1:»Û¡y(qÃ¼ßê¿Åå<,•ä$Ú†ß“s‡ö%á qa«vÂêØé1Íqªé”Á0 4oí¦6Ÿ~¿HÑ†pGÂÎ.àÑ¼$¦¶ÔÅ»8_{¹a.Ê,ŞáyVÅ$ÌÒø…g0›šÖh'1‘îqğĞC‚K[»P`»ò^}Rø´‚QİÃĞÙñ¿Ò>¶Œ°mÑb¿¿rv¡`ŞµoÂ±‡øÖêb¯¯ø·ğM<ÕX­RğXüû¿“›‹ĞŒõñx¸ŒdlÆY¾åÜˆ¦ÃîÉÙ8$AÀí«HU%:»cx ´Ñ°Ş>ØÒiÅêAè{Õ¬ZW0´Kõç6l/ë·,•©å–õWDëbTO÷Ór5šŞ,6|>uNÛê˜n»ºæ=’AÙ´À0^}ˆ9õNsCcîy‹øí¯yø1ËvÖoÈA§;JK³ÊFÇ¨¨
ş‰ø¨	;÷Y«=÷_›1ŞÆÖÍvGåpşœª`TÆ8Å¤èÇøv	}¢aµ·e+Xt“8ÚYáÚ$FtZ'õmÁ}Í4(òŞ#ÓMªah³z@{º@\(Ë.ŠvòEšé4—^<ë€Å¤<cß×MŒM¯ı6Ç¿½{ÈJg…¶¶"dØé«D'ÒñúÄØ%tàİó¡„à&¿aÕ½tH~uI"Üòä™ˆ5U³©å´ä/mí¦c’3ö¡ãÂæ`ûN-ƒ"ıjÛ¬4­M+dós§;#¯hÍõ§%ûœœ\‘“8!‹KLVÃ€Úó‰ÛÀÓ†hmÍD)½´Gíì·ıvWÓOìHÃê93)Ê£z¡Â•¿?´Û¨–¦Xº&øöp™~ê¶yhÀ²¸„øÅÉĞ 2	öJĞ€úJºh‰k)èN]´HÕÿxÂ¬z¶­õÛ=ó…£›,–#Òg‹é}©v¸÷om'ùA"Â’ŒHLlımœæi(úŞ#"£¤¶]Pa¶O"DÓQ,ˆw»™æ°ğ	¬)×¤.üäÉš³¥Y·Æ‚]ÎêŒ¸}ÖÊÊw^äu¶6>¬ùE†®l7®²u8 6òD1Ùèjõ*>	|;’2—Æ4Bë:x'¹#èÌBÁÑpİş¤ 8ğÒš„ïÌÊº›+âi/URÈ&“0ñCz»öU"ı]!‡~!8ÿNŸ9ˆô~3ÆÌ-gëcº'*©”îŠ ™iÀÇK¹×`ˆ%YÊ,óg•Øè9Ò®ÿ?.3~Š°±KŸ!şCm”b¤­ş‡ôşÅ$Eº×7ÆÒK‹€P®*>NL›åØ" ¸Šªv¿Œÿ£ºØàVp/œS®GŠ/Xi·Ÿ )èöQ“|¯|ÁÔmäx”CyMiNÒ3Ä‚£'¥p×ÉÍ,ä>z“_$¢UKÍìºÿã'>öÈZ¾)RÔ9d¿ÚSÅÏZB“ù[s¼}ä[££àa~­Ú£O~ê¹‰Â@„p‡˜w–sKı¤ÊÏıë¡‚0Pƒkö(Â<ò»÷İT åÄ9©¤\àXŠt€HÄ»(¦ˆª[7D7¿x{ÒÒ7‚åé4<¾39d¸•
Ù:x ©”bT7W/+İw%¹cIZÓ÷¬óğÚ‚=2ä¸VµOşiİÖZZ‰Øg¶IfÀÕ³]6ötç;mÓ,}s·z$cŸA-¯?›]`Ì ²yès»ŠV]šş&@ÆAÆ|ht(Ä×#7:›}7HaÉ+)û 4C%g—y‘•zW<9t—CÑq78w€àr;&aŠxm¦[±oªŞg¢a"X
Ñ»ßWÏÃšÂ$²œ}›áğÛydıçnÅËB™§­Ğ‡‡Ä]szÏ$©Ç®m­°üt"œÄ—5‰”Ã!®®â-ÚpHˆÕ¼Åz…íš¼‰û¯Ò˜TÇ›ÂS¿²`$éÒ©áÁ¶@C—>IçM-TšpFÅÕQ´›<´ª4A.>=ıÕÏÄùEÊ®çƒ½½\äÏë¨{Ø{«JÔoøœŸYØÖ”â¢<IÖ{ÍÅ5]Üb‰îüN´-Z­“¶EñWŠÙó¬—š`rL:_ÌÉ„Ö	97îÚNş¿–N.1ìhøI¾¦¸¢ô´7EĞpšÛåøW›F"ş(#àÜ\‰ô`6®Aìê¢v”
èİˆQá|a»tİÿIa×÷KŞÊ±ÕE£T,Ì‹¸š—‘ÑNêiáb1“
«Ğù|}Ø9ï›­Bs¨êED ˆmX)t¡Èôø¸Öï\5-²k?¥›’¹[L0â¢’G¼d1Ò€öê†WIó|å2‚³Bv|ãèıeìt‰ANO:¾º
‹Éòîÿd ÔÒ/¥e ¼Ïš	¡wû%—«‹Ò™å–h8G±å¹óº?ôÛ°H-ÑKM¸©ğeÀ‹“ƒªÏLPµøjAË=š…GèÀmnµ­dÂGq·¾|õãGåŒpõd³–@f:!'×s†êÄÂ'—>q¼>q;H¥šŸŒÍK›XO=O·MÀô[Ì.7M÷Œ¨/]\É{rÈ&³†\¾L'jv ˆÄ•Œ4oÇšŠ×ØL¹êŒ¯BÛ`D5o^…iíS™õb˜ä¥ÀEQ›Fú J0»È¿(æ˜‘>-õj7P0 Ê’Æ»y±ş7?CrË÷á+h…¹ÔÏ(Â Õøß™jıŞ-!Ñ·lZ)$1o\œËÑ®oV¡ N#Š'(ñ÷¶ ÄUZy-OüºKİ_HW¨6DŒ‘ŞœóaŞ õse>Èş¥¾{¦Y+aúm€Ñ†z4…‘z§Âòx‡ãîêÊ¥²Â$¹¿‰1e­éi¶ ]÷íü	ğp¨S±«#ÑÎj0@(|O½…8f€Ş†^||ŠF.|á‘ù<óÛïksT¢ÎzÚ	'I_¤Ñr§ >2Àá¦–å¤ØJO‰©‘Ñ¡Å¤¤ú¬êÉw¤´ÏFø3ùö÷˜ TG÷vq‹ ‡~òäØéf”ìıêøµ+4(5¡`¯_á¶3#vGm_É¬Ğq 0äÌS¯ÎÇâ ·T£nSC©<“ïÌ™NØIt( dj™‚zØ¹ç‹k‡RÛ V]“DU¹×å–6UT«rÂ8_†¶íûFA	ÇAŞÖ(3b}ª±ÍÂ„±ÆÍ„ŞÙ¸v9(¦8ú£ÂfEÎzözqäF‰Ç«A5>6tq ÏhøµìÑÒnR,˜m¿ŞÇ%œŸøy	 Œ$¢³V–ˆ¥&ÌÀsÎ	ò™×‚[Z³&¹Ôï×k«ÔÇ°
î'ØÈTô’7çRÇµ·F-§µ"‘Ã:©m¨"Ğı<“#¡.h—_£yˆ÷éëÆUÉa|’
	H•oßñF0$…‚İg¼X/õ˜6˜ãë{O	@Ù3W¶@úğ3Và¶‚¹P´ ^®hœ €±B,FuEùeh¥“Î²öŠÆ+´~7 <{Ğ˜ÜI#˜#×ñ*£F¯:ßã›O’3Q1Ü.€†ÎOc% ÖÛå{ÑSù&ßèXÌª®ºi¸FØ¹È»Ç(BRš½ÊĞõH¦®'è#¦îû_t¹tüŞ^ù+&9cÏç>Ii¯‡Ùòá“y“øĞ ÔÑl=Ù_?ÃXÌ$Ÿ™KNaÎ8ZJëˆŞ`À¨ˆŞrÄÎ¨¦Àö§¹Åtña¹]¯&úR)¦:¸øñ‚óâôàË]ˆ“8 ÀüŒïOà^T‘Ğ9+Š\®a¶S0ô¼le'Qew,Hj‚2€˜{ÍÀù+¶OÄÏ¬–0nœ¦F•’ Ä¡uæ¥ö`/›æàä1œ>İqx}­5$LĞVCÆd!Øà(M8ñ,™æv[Ñôf%Å‚8ú‚9m¿ÂïÁ¾W¾¬Üåu7ÈÃÒ‚ªí¥TN†şbÌwNÈÁët€Ê‘ÿ%ÉtÊ¶ñp'¢kÃPl¶ïT2$ÏHËëH5Lw7,qÇ‡±m“U$‹¶JÖkKåéúg÷{Ü–HcÑúØŒyÒğ(YöaQÅ®á.µĞÃ%[åZPCFÓ“Ï`ëÄğ>{™yR[Ş‰ÂÍÚª­ 1«C„:h™DÑ(í†ÔØ‰x^œÏ'jTzñhËu¹Ûo3mßPË™Ãõö¾v3zÅo	ÃÍS›eWWd9d¼ìjšk]©¤œ®)ŞÈ¿h³÷‘ò«mdèy€Å³ÁªÜÚl’(“³ƒ, 8Ši e@?}Ç”í[+ààv‡%‘ìğŞµ‚Áğ_'Ì¥²nº²Ó•¥²ŒB‰Ôe€î^²:„è@?ŸHÎE©QVü`~nwdÜÚ1ú=œú¢M¡‰	F´s§ONÊ­5­g=--6ê0¡åŞáî#•f+?½EÕùÏıí…´ÿU0$¯‹ú…y|G0¨v„|I7©<cFîõ8!Q%Ã±	€ù\‚w0NÖ¿?ñgÌìjLınäšÕ›İšÁ·9U] ­@C6²†}í'ÔF ­,|fj¨eçaâÚ€’/+CÃŠü³ ÀArfÄİ
§„IıËßhı÷>`@·Î|ƒµ ÷±<\y3¯Z|m89»ff¡cãÌ8O»¶FVÉùäS±ò›ğ‚Kö¤”;[µÁ3	(~ùZİé¿ˆM*ìèZÕb4şfû•Ò‰Å2D›™JXsyû“mƒ+ûFşÏ÷oö¼G'”¿¶¼a`UÈªx®¦ÈïáÊ:ŠPeš€+"b‹Š2:/§yqÛ@ğHÌ‡\S¸{òHSDÜ»<Yg$†—üˆŒà:İ5öØG²X‚0÷ÀylşAhuş5¤T;—Ö‹=Ó¶ŒYOÙ8lß±âQö«È­T‘Ğ.ÅÙ;"·¹„g–sHÄ‡;B5
8Q®Â)I,D‡(2íÿ>Ş~;b»ZQ`ÛÍ‰uá•±ñ6jH1ÜT·ã§ÕÖhÀ«‚5X„„b„–M¬67â¼:Ğ‹y™Üuåj™`åAÒ^›™	œêE2e"ş–{Îá¾äÑÌæúCâß
S&išÖÌu=£»\q‹ Ö~¬ˆAbÙ	¤3UêX¼Jw{ö]Ïc“¢æP,®…‚Æ<—k“9Ú¹gtHæ;Ì<…9q´]wï9Î£Ë˜ûÆÔ÷Ãz~Òä ¥4…Œ^u é»äÄC6N@ºº¦#¦t•s¸ğ~…• ˜„ñ
Ùs³\/4qãt&íébŒ4ïwW¸÷}ŠÜŸÇPğœåœ‹À™³®ÈÏÆùnŸš‘Ë3K‡'f&º~n£ışõà½'{8K¥?HxÜœK:ïd–ÊÄÑBÊ˜R¸…SMâªäŸE\¾Md¤{…¼ÌŠ@‚AnoWq®´öNÙÎÛ.?[Ğİ§wÄ¿«÷¦=ßÍÃ?]l4ÈVĞÌn«Älk%~HzO­G¡£ÔgÎ`@Ü@Ác:qªyfjå;ö [BDúRu) º‹+Õİqõë(¼²£é4•zúğ”}b—\9FÓºóAgñ„¶%ñ~¬İ;1¤èŸ-ø+#4¥¿Q†ßj°²£”G÷Nb5>´êS
Ëö01î„x)”]/1PC¿÷à<2°ßG£Ièà÷#ÈœZ_½+KœÈP>ÿÚj+¶Û2wÎ};ÿm$Ş­zÑU‹¯áêëv{=;¥83`gş¿"ˆpÌb"ogw¾*‰PŒ˜ÀâTèJ“àËÁ›Œ yèƒK…H[¥ƒ‘’ã¢ƒ±¿€¨yŸ2¥$&Ea ,ºœ5Ä…Dv™óªÔª~[ùLtgÄRß×£ºìÖôÛÉ~üqF²š=RÆ&ôÒ“XyãkN¾ËïD»Nuœ~Æv!
ò×T‘Ã'·‘Ø¶9Ãaºzôé/~.¥r>Ñè½µ»bXWO3 }@é¥gm4$j¯ÿÃÄ²`UÌ° ãúìİ`$¿»iYzÒ]ÒÇnüö#jR#Jûîk%!3´G«¤EU1TIc©–ˆù±V–`ÒßåäƒÔÔ{#ä LUH¶½œuKåCGrLçŒøcW:2ï–hìP¸ ‡¨¤-	Ã:¿^ø+^,áâ$`W^zpACRºvzMUhåÆBÁ˜Å•˜ë "(.¾x6K=¹ùêjuÍ—·ÖÃøIËèk`E¹éç—8*¸*²ğˆ$åÇ—ÇgAÎ:6ïéO1×í¥Ë‹ssjŞ_—çô¯ÑjêÓı<Ã€¼§…¶ÏtşU<’9„&QŒ'è¼LdŠ/€œ®é/ù€ô¦ÎıiÕ•R>b@NÚÿ
ìµV´$óÙ¢ëƒ²»TÍ°ÁÚàKıÚ…*TÄWOE˜ç—¤ËD5HuJ\ñ£˜ÂuÏËoßÜš3_1óÉÒ

ê«;n$È6)© bû{ÿèf9B#şj|Ÿõ:ˆ3Ê¸Zå ³G².j˜d›ıûÓßê©w§}Ä
 Bö/Û&A3ÜıÅpoYÀ(9_À„İ™*©ÿß6‰&TYa¬÷qê¦Šš%”ô%/[z«a¾˜g³M(^%2SúN\X’\ (-¸§É¿›ìÖÃVãø¯È–`ŞÄ-¹¤ÄU?×Â”£ ’õ¨Nı“LLÁâ»ãÿÜAÿ³Á~[Is±Öº¦mÅƒ~¤'@°é´àg9J2ŠŸ~–±™>w zäÛßlÓ¯[Æ¡Auy¤ú!jsqüÄLmxdõ?F_KòÇ˜ğZ¢˜áûNÊ™
úŒÊÒ¡æ$¹.)n EEVOzàv»çè{AİCÉ5‚ 
ó4Éäõ·Œt~7®/=Égíè¥?ØÈórîcf®–,ˆËl`ØN*«A9C˜dc®–‘cj|`[t‹ÆäXÅí“ÊÎ• ì§ºÅå%t±Ô¤BÜ„ëÀÂ”k/u¹‘ ñ‰5Káõ‘ˆÓ"©U	»F–§†Nÿ–‰àí•ı¡-|@Ÿ“{7®€·ØÇm#¢ÂYP
Ï!C§®Ÿø™€ÁYôéŒ,é¤Çı?¡˜u¾ô¡×z²:‚F´áñF¦LSIF„/bii–ël}3ËYSËÎ%&D)(‡‘FÚÓjC
°!±EúFS~ÌœM4ènTA_vr›ıøh+qwŸ0®tg6Ïìj~w€f!^r3éŸ93E]'pe7]û»F×ÌÀØ.{ù„)¹«1\K, n\¤KñÉ˜¼±cıÕcW[¥úZ öË[ƒİM±- ì½ÉèúCl_X¸ùƒ<Zc¯‹µ“~ñCÌœÊ	4½HwãOÎ`t’ÊDPZ
…Å%U/g(4†"?{ô`ã‰#-[Ğò$ù/W±#*mô¾(PXƒÊÌËóaòò·ñŞß0mÕnn:Æd«ÅÇtÉ}ñOp]Ñå (Xİ†é§d1°@ŒÆÈ§t ¤(1XF¬AÛĞAçH%2Ûp‘4„Ë˜÷Lß’®+†–¼\ÚCaÌ*íÈpU
›çË1W¾J¤·!TJú?ÜVB¨¥¯†, ãVÙ®cûK÷Å3§ŸÎ‡‘?‚QS¶°©öÙP^àYA¢øæVR[­Z$~÷Í_D$et^‚£¾Tû	¡×®–²ÒÉT˜ôˆçä«ı®ä”Ÿm—‡3iÈ.H[³O•úˆTĞjÿ²Û;Iê-ò÷ÇiŠãR §ŒÁ¶'•4ÀXÂ ÎÖ+òí ,ó—nT&²–í·2ƒÕ™7»ªœT’j™[!…qš;²”ÁÜ’µ·U3®®«>Ôí˜­ñ—Ûôy†°N¨R¥‰,Ø¸5Ô»/Øò†TÊ{†ë0Î:TÅoY1Éïštg=ÈaîC°[ÓªøØ}¯œ‹ƒS†çïÅÇİòIşvË<x´ÑíZº$;[ü~>O×	…KïDÛ×®+Hs‚7}÷vÒ²Cm~íŠ? Väa˜(€}ñ¸¨æÎCŠƒÜ
·İÒe†¸±¾ »rš‰¢r‰RŞHtUŒ @ZÅ‰@,=†â,Où¦£Ü‡RKCô£;?"Mƒ¯Õd©†lë¿vôßY ëJÊ‚å.3(3!Ã¿
	9bx)o¶Ğ~
¦Ä¹ã©„×ôª¥\( ¤ò4-Ï¯·`Ta&}é
l§š„—ë9©òÅV‹?¡Ğæ8U%Ó+y½’­EãƒvÀ…-²Qpbn½Ò
d I»æ=LçQàÄÿe[bJê>†­Ûâ9b4g‰—Â5İ÷#„Ãæa(_;ìå-Î #ŞãŞªO|)xyÖ”WÅ_Gå 3æœÁ'F)F3î~ëv“Ÿ|”l>òTŒœtQOa>±ìíÀäméBJE¶¥hv~™¹î0~z¸›Eû9óÑÂ†•›ğ*ğF·A$Ü*şíóè™½®éMSÙ4T éÜ¥XÈqYGWËÚöØpİ õÆCÚ§V
Û8…Ş3$ı­ußÌ@a®×è²\{şV­ì«÷i2P}ü­îdŸBÇ¡™ Ò1,/$cŠDo“D.:ÔÀøã×ëŞˆ‡ãKu¼šÚø[2Œ– n¬èéŠsº¯Ø¥Ô¥™©ZKïZ«s¯×xs[*B“Àr¶PTP›ªª²‹§SûŞÇ¡mg	3.£¿ÉŞUU¼Ü…Åj‹½Ì…4áLÁb|‹^Ï¶ì–q¤ ¤ºÁÿ0ÇHˆÔÿC¦‹Ó*ò¸ÏXå¹‡BáÀ\¶Ÿ”“˜8p‘²NÀQˆ`*yÅÈ9ŠL€`O¡î4‡pw@b¥K<J/= ‰qXF-ÁVbh&tcW'“/°'îtöÙŸâ.Õ>xCE¦8ëló¼›Ÿõoá‘‘Ô¡ĞÃÕkĞ®ši3§`aJ?“ƒÔ B«WŒŠ²59®4¼pŠ¬¢L» ß.‚cÅ¦¡@Ó¶#&«BláG‹b{\1Jä†ÈÑt~Õ ánT`b©\m>Î¬dŸ/Ï*9øàì¾'®GdÑ9¼ı~{LTFÊvB¹jjÉmØÁ£ğ@1çÑÙàƒX ×ÎW Qîmé2E~!Å­ƒŸR+½Z¡œrôF®OVi¦¶âÒÿ\¸’/ıXlLf‡wGO¢+Á\lTìÜ]HMÜOïc²Á)¥¨0„6-‡ˆ rŒIs[Í£X¡U°ív*B¥ä¤ƒ˜ƒºj?ó¬÷À‡OER'˜öi\ C£ğ×œ"Åú`•ù)yøYHõa@SŒ_ŞßÊéáQ×»1!à×ÒÉ¸(ÊôÍ$—A:©˜Ğ%æTÖ¥ï¿&Á'Ó7^VE@´^N–ïghÍcİù»xxRk}öÁñ¶ï–®†N× NrÑÖœ›y`o'm¶…ª ò×èÛqr‚¤Z{¨}ñíÇİÿÀÃW©àrê³÷§ür0÷^gúÖÕ‡Tº ÜÍ¦óğÑÏ@Õå1™êfi©N£‚ú˜4ù;!Ãa¥xTa"ÃHy	´V˜lúÿãÈyà	öÁÊ eßNQ$ß¤u3x9PÇÌsm¹Âa_ +WåŠŠª5“µ§0o³Ãpb/­¶¯T€H¹y§8>½'qXKÂ‡³?Ã#äïb–á½jòÀÿIŞ¹Ê¡ülĞ¸úÏ¡j*âØ1»Hı«ZS“<l½†’t>8VdfÒÁ]Ç¦‹›X1Et|?O®l’/³ÅñnoFÍ;˜ê !Môh5ºk§ª¨şû)ZÉ_€×kŞU\ò"#´m¹™ñ$|«•2{K“LïeqF:0ÅOÉê¤Ààïö¦Xú™]{ÂDşÑçub›ÌuÚÂ“êÄîéGHFòÕ§ÕE-Çjo¤]s<¸6-ÇÔĞ¥fûD{J;>5Ê‹º0Ô‘×òõ…^GŞ.N÷ƒ% ¬ÕRù‚å@.©&¾—_"·OT~ïSdñ·Cò¼Üè\4qœòAuw;~­BÏåª/4rÛpº—ÒeX[CQ#}	í^|SeG3HbJãBÎê"…±z‹gYbBe4Õ·¥çÒGÏŸçL$&ÁÕóÅDØr1c¡¤‘ ÎR¦	Ö9”æ
áê‡Ãê9Îamêj‚2´lÜ<Ì=ìF"¶5ÿÌÉ=	T…>c÷r»£¯.‹«½;š.iWŸœY*$˜vÀAï£j9ŒÃ	kè•§2?‚0JöØ£=–áÓ	°fŒÿC—&8(œ¡^·}6é^Ò.æêşÿÈY,VÿË•'Ô+º¨ÓÂI™Ke¯µuşIÃò^J¡Äf!ú`ewe1>…Ñƒö¹`›T~J¾¼Fêğ®¶">ÛµB
Bµâ‰ê¼Ç7·íN°ã,cÁŸ˜Îı#U¶xê’ÔÚ¯n,dœiºNM°“lÕ„kO^tà› )‘^Ü)é<`ƒÍü=5½­{~€õÑ.  Ñò\°Íïo”Õ‰åz›UmHºàäÔ>0³‰¨sç~  {, o-×šfµz’®ï}è¯è%]–U…ú[şõÈ}H	ûÓY´ÙuKÜä?:vá5œôÿşŸÿgÿ/‡‚Ê'Ev)¯iaGŸ OvAôÖ;ĞÍ+´ÄgÆ%”ü%Á7(Ç6I¾áê•È8e‹”6ñxèéJÊt¢F¤k»G°îÅ;È—˜şnFT¸Êãì²:?ŒW¸B¼CƒH)dú~ğwÏ
èÏíy9Ñõ
kµOÉq;Qê!âÖĞDwsĞ¢°{"ÀLd ûE ø]œ0t˜¼¹/œSÍÂ.Uà	ÍÉ¶Ö"XG&tfl—]e;[ŞFgJ–¨ı’3^p½MW\Gş°êÙ·wÊ‰Œ¬´Ï4HË¸8n‘“”èÅvÜ„¨Ù·’¥/¦_î|@EÙ
f-Wlø³Pè²ŸâJWCVj„Â:AÇV¨‚½³P9¢§F½»™ÆüA t*(¹r_$j1³/#|DoœIŞş:(°ÿ]Çx}
Âº¶“.‘Ãü±mWs¶ „2ÔeºÔÔÍkZ[­*E°\ù)ñ‡5Ñ–7ÃÛ›D
áF°nm¬‚ÆÆ$ò,¨ô/†G¥.áã` ŒÔC<24½3A­÷­¹,KÃE£Fós%Åå-Äá	ÇMñ,0t-’¹ÄÑ¾,ÃŸû@,€@f3ãï3­Z|_À$‚äºCiŞƒõ·;HH¹PØÌ¯,™Õ¨m&™·äãerºAÕÅèj©‚yˆıÚŒ5÷@*!y¾H–n}âLã‚}lÖçï7A:B™ì01½‡fŞ9ËO(ªÊŠ²#óWqƒ[eO\¢ÂqnäËœÒ¦c>²İww¬ùŒ_äŠúˆr©$_gÙ
ß£Ğ7²Èc–öÈ(T†ĞÓœfÂÔ7T~+=}æL¿}Ë.úgáVÈìæ} é-SKM{µ_Sö-ØÕ§(àÙ+&¢:‰÷é««£Œ±ó;œ‰Ë;`å;’Ô‡(èé·QóîÂÎ°UÿVÜThÌuõ‹à‘Ch¹ª¡ÀL„°}İ—ír<12lr´Jlme¯_ínvPE«ÚsÑgè†Kø°”Å_}•Š¾ãu„û™7Šµk“/Å­Ä}`ŞG@Ã§Ğı¸ëPÃìÅGƒ†X{^ËdÙ›DJc-û²)tíœ6Vµ`o³€·ÊäçEşÜó1Š°ÿŞB¤ñwº3ÔîÙ ¢
°‚j†A:€ô9ÙG²Ú·cELGB•f>ç_M¬ìíû?{î®ÈZ@U®LLÂh"‰dãåF¾İuÇ¬fÄøîAÜh#ºjgéüç6è½©6â2Sñ0åóõü9­uıì\O[#÷ÈtÛST54^6y¾óïuÒD;üX|dÙü¥ôÎÎîôá!à=¦¨]è<eó¶®àß¥ zéË¥z.q¢E'sqåğËéß>já¯¦ 0"u°ç¦×hÕ”®³„A.÷"i–ˆÂP^œ@›üŸ¬qñ5Õä–!¤£ø]‰»tÎèQzo¥Xbc%-éíÊFF§…†HGúâÏü›—*»+İuR7ƒ±Õf“óuÃ‡–ñg.Ô[ùp3qõXòYv\¨ö°…!Ìj™¨!¼OwÈ¾ëÖ³GùÌln‘şó®gb\Ï¦DszIŠôû
\gèAÆÎ/¬{céÂ°r¿1»·Ãˆ’›ç]£ŒCMuÚ&Ç±g	‚YéÀ‹×š>ØÕÇD™)}İ–RYôêä|öÅ¬vz”Ñ‡Ü”ª1ùJƒçÕÃ	
T¯RYÛ•‰±«`àÒE4Æ¶şR?k½É§>n»„D,¨ºÃô|@ë?ü³Í5óÇˆïdë‹±G§²¿0á±‚àWºÉkï@Ø»û“KÎAQÈõâxÁ–R¨¥3¦‚YÿÕ8e‰;EÖV"kKoÖP²½F/¨¬ó{rÍ&ÄÆşÓ;@Ì÷Ş¼¡¼ìXKø ñQ[HŒó İŠl+ÆÒ/úuo¨ÖU-²üzÂ4ƒÈöş™Æ¥AÒMÇ"ˆKÓ­3G'ô9«Õª€uJ{†˜|6ûØ:iîõÄÏ™5I®‘Ôôd`ûßaM¶!n¼ÕXûÎ²—HÉ|EK `Çÿ>•»?ş¬ÿŒ¥a‰¥D-º˜QáèG_R–y–ğjQ•ßú†b±ÒF™Óï2E¡Õ
-À'…»‚U¦çArôW'½úå¢R+¨¬[òXŒI-i)”F÷ŠN´}o°>DƒLğ$á"vû’H³ØÂ{ãÖ@ü‡&sV†¿‰ÉÒZÁU©£ÓyôZøWUrTnªVÖİñ¨ò«æ1²3[”<¦$¹jÏg³?ª¥Î(áÇ-œH•€ËÕâOÍ+x{^¥oD[«’Ñ@~ÌQ"j(‰ô×·~Şz]Ú•e’é?İF§´34Ã–„²÷øjJàÆH¤Œ©êØƒ¿»0¢zÖc	mêE­uTéÒ­å÷µ#Æ#m¡§Y^¯±ú"4V‘Ù–]N‰A7FZ“	·Ó!ĞµÁ‰Î.&–äÖâˆcÇ	1h¿o®ôég.ZâDÀ)L×ô.}^§câ–> ú*Í(©FgW"{éÃz›WÀĞŒß]JQJ½= hÕãÂîÄo)VŞŒ/ÑÈøBªÊúœ[pˆjc$ —$™Œb—½gàÏ ¨óg™ìÙxPı¦#¼»Âi[âØ¸¥‚ÉvÏòåŸUÄ·Ÿ~õ\Àğ4–is}‘¾¥ô1¾Æâqd‘!ÚSjh¢„?V©tÈÌoõqêA.A>"×B5é‘++f¶L€=°ŞwÛZS'Úóí­7»`»ï;Û,tÁ"]gwßÙq	¤€;VÇ àN™{Á+»Ñïüôš0\øÏœ~ÙæAµó«Â/OKFUQãÍÍÊŠké“Íó HéÛÎÛáÿƒCl ¾Às:;¬J‘ÉæmIĞËyÓÃ¡×™‡gFÊ[‘T,/¿¸Bõ,€ºg‹ZyÔòÖõTƒê9@5| Æ:ƒV®Æ¨!L/ÏUèúH.IÑ'\Q@ßĞzã’ö__"!1]I%—´Q•'üùCªzÚAA­§auïoL€çüG2&2	D·Yp†ó÷­¢*úÎmpp€à‚ë˜~ã†³.-B Û6Ë®ïV8PÃÊ­æ3=Ö<Ø t²öKë¸Ùwÿè’ƒö¬Bª¤50ğ¦,x8ª|içI§©(û«Ï¨*gWJªÉxtA`
B;í8µõ4I‰ı•È‹°2uYÔ„ƒ^iV9ìN´%W?0”ı,Ÿ,X•$Ì¦{í«µ3BŠ¸†“8N±²¦•Œûi¥Ó9kí­ÏŠG•4Odß,,Q»ºÄRuD¨âxşyg½¶6¬–1jì!şzómBŞ³ş.»õ|Ö¿¯;Bg—|ğ­$Ğ$ã"û´Õ‚÷Ñ¡T¹ë§‘ÂLçÍw-V±*5Ë`4‘3ÚŒ¬N¬.‰Ø‰ÑTDGîÁIˆ…Û<]%‚ª“`:GûÀÿæ6@D‰)x¢#t ÂKĞb) œAË®ês2ÎÛÉ¤‹$_ÃÎúÛûá¹_iê¾¹3·\ $<ÙS÷Ôw•Ğ‡&ei<$ğrŞ)iz¹Ùm;wJ?K+Púaº7²‘•Ñ4T#<Õ»’ˆ…ÍÈ "¶w!i¯,_1RW­¹V\ÒŞÎ+ÕÛÜ½œê~‘ªÚ› ÍÍÄÊ]T%Çµà`§Ğ¹$µâ;“p­€›”àÛy¦¢üy ğÅ—ıpRÈÃ,±Â¨+	3LÓíô&Jé9ş®³´¡6,Kû–Ò¿!W¸åô:»>|CÃùƒ>¡ˆé<-ù¤‘oõÎü1]7T#¶;oËÏ>°vÈ#dqÎrË½áT2‘lıqè:Ä
m­,¸´QL¹µWöøéÔrTäIİm¤~×7Š}‡§®›ãRôKÃü†àñ"ÙÖ,WÆü×ÏÍWm`úÓ1¸©	rïCEKxò~ Æä/<ª²êÆi~eÂ±Ê©6P.±5g[0Wä”Ù]›á“}(”¯m `#L…9ƒ˜ÕıL‹ŸnõÇGqÍÂ“W5€rÖá÷‰.S]ÍRÆ5”YêgµL†3ñÿF[¹‹u† è‡¶]ö¥ÛŠgLm–¢0i«áb–'Ş»ºS.‚øÜêN\ y•ÕDë•§hGteè/êOhığvt?×¡©~hõm.şU:á’Sƒ¤›®»_§dZåh=í¦'±Fµr2µwğZ ƒÆè»94šz7¸
'wl±"§’ÇÊi$ïeù@k);Zkƒíí0Qj(:~şöô¦)!)í^wÒºø;–KŒ4¯! ­à3u{Zm9‘\u™x…QÏ//óÀĞHj¦úUµ±ÖÕ`ÏìÙnAÏmGÌ.jV+7áU~æy£¦Âñ§ë‰ZvŠ‡¼ØîÖö‡Èk9ÍëmÛi³PÃæ¿–7uÌÛx-äù®
AT·†6ŸİºœŒšßÃ´—¾Ï¨ıd-fîµv?®Íî'ä·¹È‡°Ã¿#0Ñwa¹¥6óÄ[¾0™P‘)îV;Şµy'E{D1ªÖôÅÀ5Ìn7üöxŒ-Ğ$Ğ«cƒaN×ÎÅá÷oò—VyGJ)	³?2£‹×;‘öÆjûÑ?{õ.õÂºí.ONb²„iy R ë.–/İYuÁÌ£Ÿ&Î*«°A~pŒ›Ğƒ8G{ÎŸZ,y¨½-OúåŠyèš_ëÔ2ûìAˆ3DX-œ¹1Ğ­³Ä§Ô¿]ôcUNæ¿íqHÄÕJPvo{8öKÆÄJz5>ûòŠvŒ?ÿ0lXßfg7ì9üÏ¼Nzÿ#ª:FBiÈŒVé¹†éÚöQµ©ÉäT›p¦‡YŒı[­Wpå<õÈÜŸS1mAš'§Y>¸:­\>¢~ßTA84qµôfëoAœë¿çöŒáODrâ¼V'%âZG«ÖOO;$D_—“,.+Ê,Ø\Y,j‹_‰Ø3öêøjÂË1¸NgÒˆµ®HÊì™Èlñıı”Ğ˜·Oá½Ï “
”2IªÎ¨8‹,”%ãGİ4ÂÒx>¿B>S½h×¢¡ÚW3Lş–mwĞ79ïs vº±¨ˆy‹½%©’w\’ş«j– ›Í®Q|F”\ğ‹Õ¢ô|7—Ï“á‚ãîÈ¸ÇZ†zÿ@IéïD¡Úr¨i4#è¡©Qîx¹ôDü„¤	ÏÇ¾r·«Øí'q€9’6*D¼âõÿ‰‹²Ö~©ÃıÌü,x¤ï€Z+¿¡çÚNğÎàÑYw”CaĞ™Åä•;§ŠeDIdµÃ—¾°üQóÆÆŒô	$’}&$€v¡õŠîçÒ®	ÔK·¼ÉõaÎ¥\:Fâ€ÑIåâ8º3eLP’ä\Ól&ÏâGù·meÚ¾m5ÇÈÇ¾t×(›`tïw^m€}NÆÁìó°ÉO•šCşpvLj‹´û7#vÛ/İ©dYzÆm©Ğ#	r ñ0S`pãÏDßßpUI_;ƒãîÃ9ìB£İÀ¨Í©_®&}/ækµcjÿŠÖß›]×mìa‡×°IÙMØN6Y…tVv’Ÿ× szê¹Â5¥Ï¡ÆÙ0:ûÙ¡+<è~Q­t XHÀĞs‚håN5eÌ—82ş ± Wm½–ËŠñyæ±ĞôÜĞ¨Â“İhË
/e6UQR¢ŠU]ë¢Y÷ĞÂ~³X×~*Çè£(‘x^ªÉi{fre>x›X|'ƒ®kR‹d=é?bÿ²Iä,îÚ†XÍkŸ¹›yêØ­y.¼Á6ö¸Ç ÷¸61>ti ˜Ê¤²ŸWa‘@sı(š6fœL¨É$×)†0ğÁrRj‘¥Ìæ0úĞ1-¸õ¬ü|ß½Bªıšì'ãt‘Õöª}—Â¡Ş*ü‰lK0’ÿc~^Ê…jœıÕEPN<7%)Cù=ètó€…´‘MÂ!KÉŞüQ}1®jáæútÎÍ°i œ–™’^Ì|8lÃİîÊ©árm>í´oâôƒYÚ’jèÚÔ&ô³ayªO´¥6ÎÔ/6†òÖ¢`<ü<ÂñSSoğõHç¸ğ/ñµ²Ö	{Å½Gë¶XÓe¬~¥.§'ÖÑ¶‘§Ì1&a–Ş8^ÓÕ”À?Ôoÿ!!Ô¯şö=F(0òx(§C/ó˜û7ßX‚%)3&×:Bâ»ÜÉu&/M¿_Ğ–r­ÉH5BüiåKlŒiwhU°¡\£È]
İƒî_@Ş˜çÖ
C=Ú–¢–ÿŞR}Î#{âxw‚p}.Áv«{»œ80-ÿêf¾h­Í¥ÿ£º^[ˆÙ¨1Î¾ÂÿŞğµÚ1]J?.suwÎMtmG'°Ç¦÷=ñgÜöp),Ã·¤‹…O(ÁpKËùB*+ºáp!8ûğÔgÁU©t¸„Á  ½0®H»ÚU(j
Õ¡¶s)²úÍôGwà¯°}ÿï>O‡‚¨8YÀèº~Ğàun_«tF:ùş‘È FH:jxaÂñ–nEœõ$`%Æ¤'Ç1#O¬ÑX‘"èné¼\ÈâûG8»x]fÊĞÓÕ['Jqg2–a^ÔÕ›QrĞ/Õ5œˆ‚&r~òÕz(«¼¾ ,ëO@Ö{ì§ËoñX„„koÑÁ;#ô‘ÖşÏB†f€mG‘ãÑş1Cşgú³Ï¼ù!LînyØ×ÌÓ$Kù›æ™ nlKÈ÷<s1ÎëêªM?ÌşŠ}×WŒ½¿äîDW3§ëˆ0c’BÌ&øß>7 ğîP“y-ıMr”ºW‰@»ú ‹àâ3én`DÏôêî):ØøSÈÁ+ŸÔ3¥ë½°u0®Ä{LÊ‡¸Ö«DH¥¹¹¥CÚGOº.Ô6>Y5, õÏå"9mïbyË3ÕP™>Y	1'·A]Ç™†:ˆ³‰ìHJk˜lƒûœuSÙ…«‹‹óLü´>ªæÉddø;+³‘óËfØSÂG@É’(>ñU»‘‡Uÿ+ š+Ä5™ÌüÖ©ZƒsXÂ¹YVšNÅ÷6³ .°NÇ¤+5T§&ŠÎ"
bÆÓˆ®ªÏ+¿ˆêßÌˆÕÎ QA±vO	šwÇÙâlç©zéİw ²¤´_¨ïv¦mB§q˜&$Œµ°çí¦C«tp™¨
V¸-c—¥­jĞQ['xŸrİ5R˜+ûGß``ç¾óc;ä@¦¡EÁ/É~¶1%ÈÆ(Á=IÑB¼Ì.kÚ5N¸j=aòfÙ©
èØò<eô aâ.â£	Ô™N~H·ã\©ÌNbşîKh/'°ÖŠí‹0Ò½e¢ ñatT–ÚÀèçŞû“û å6\´ª%°¿†ôh¤he¢Uç¿|ìáÊ)ËºĞ1´f[Ö:”LEÒ‹5°1™*Ùìşõ&‘ØP´§b­mÎ3Wº¦nÖ*¯îÙeB§TÌp«Pt2Ù	òS£-JX7-¸iâ'ËWİsÌ¾5„Õ¤6¤Ú¡ì˜Úú3 MléHÖ!hB§ˆluf&Â¼Ûs,Oı«S Å~pT÷LŸiU8Ğ+ûVºµ¨Ô46×€‡fIKOcS®ûÿ.kIò)Û„y¿ï—ªÇÌÓ;T$Ç?ª¬Ârâ(&ï„¤}µ}ÿ]ä4K½—¤9®_ˆ$£q›/6XJ©ª1<¹7™‡.“ô;o•5§ÎIÎpè?ªúª³şÂ5†äÏà‡‚!Pï¼_ŞC\´îê%¯ãÃÊxÎª³„§²jYå©{i=RLp¢R‰¶^#Wn¥‰|j×ÇŒƒ‚ô1PE†ôÍÊTŠòPë¿ŒÃ¼LTµŠŒg >‹(‹D6g	ä”ÔLÇ';uUm&§÷‹;é[ÎãÄyy¹	 ·‰oyyğüıò[íê¯ş¿ ôH(¹Æu‰PSãXåïpÌÎøoÚxÀ–f…“mÒÿH©å·ç²BÇ(çV¡ÂEyX@éc0^n° ^iPîÍPX€ma*GÍú¬±e°MşÄÇ¨8ÊˆªQuæJùÙBÓz¹;Wôì¨Í>İâ”+DšR²ÊêÍ°"Şe}F…GÁijdR`ü7MµVÓo¿ıjí©©™Ôét hyŠfÉoèÑ¤|„Âz–:z(@ØËštÍ[<GâF:E ²íT·Oºÿ"/ÛŒ@ûRéıµ_æÄÊ`C¼Úí÷’(lİ‚ ¦¥ë¢¢~v7¤¤şûXàwû
 ±ùB˜-C·Ã#û	×«_·/Õßdì×Øjzˆ,qÿEşHr"@º;ÃJß¬¯Àsxk6m½vi#ï—»-±òKtƒé‡eMÇz¬uÄÍI¨w­Óp1û•»¦¾3-NfıÎz˜ğ[½ªmäƒjÖ®~2X±K0;$ĞõºEöwl;DC¸í‘4.xUÛDXscEFTïÍÉ“Ø”‘åjØjïÅTg’+WÚöo­2C~†Ö°FÎÆiË÷&!Ôå¬k.¯9æZ ¼Z]•GyÍ‹€œ'¹•mç´ÿĞ¨iµ0×‹YşqÙOdVàØx›|GÚ¢™¤õm×XÑàb³Tcaé2‚‚wÜòªª7úá¤ıİ¨¢¦HÈ¯&4ì„ÿ<é[¦JØŞ·†ÄŒÙ'g*“ª7”,óllJûÔ<.4Ì†z²|*äå%¥6Ñ?ö+i>üİÏ0AëF	%Tü>à.(}ÊúÂVíY¹Ó™‚mÄÑh·ÖãÑ`ZÏD¦hÛä ÓÔ¤úW.FŸÃÓ6gUl,o€K¼FÑyÜ³z²ß~]	Èu;\™áR«y™U=£~ô"`¸#òh±úu€±¦ª–¿==‹`×¨GW
ÌƒˆÅÌ®=*«xoyê·¤•š;Uì©=¨)±®H‹å=ä÷(RöáÀ“õC=Ô%E­w¥	^bv,"ƒmí>É6œ¢™™Š_mpŞ'â”Ri€÷úOƒ§ßr«c
@Qı[®JF›è%Fa.}E`È7¾SÛ*7»¼‘k=VÅËQhø
•æ<ù«~Ò]ÖP¶N†·—É™ÕÕâÎİê™§ÅSîeãl+®Ñ
[qCÁ¦§DÇøIP!ÈS¾Uó¿rqËıÂáƒn9Yi-÷UŸ§ÌÚº?8Š°6r€ı« &íXX.v¹öšªÍÊcÈ•ı\ŒtHO5œbŒ£5‹qâ47*<m ¬å‰åÒbœ<vºb}ŠvkSè÷°b°šjĞK€nG“=Œj¿ÃWUgMNºy…@-‹=ã}—Á­ÈTÄyù{gcjqŠMD«K™ctuª9-ó*¿áNs…äã4ëÏúã1@òı»@XVXK¨š0S,éÌEs’Ù»5÷ºCªØëóAÍŠ`Ãøo¿pƒªèÍì ­¿µ9ó°è—Ä2‡¿>¡¼-x˜+™zåZu	êŒ“ÕøÎJd,Ë•¯D/ìÆwáìÆ('ì8¸TYuC”Ş˜È‰3Wíûº±ş/àD§¡ïhNcìXÂÌ0RÁnÉÓTüİ\‚î—oºµC0Šf‘­»ƒ‘y¯U_K lĞC’¿Iu¹àoí¶ÜĞTÃÄ–®Ë¼±ZÓ¿f@Irwi‘{h¾Ìu0…Ç21'ÜúÀXü’	scòW‡Ğ—Åª+öWsOÂâVÒ²ŒG²õ:‹®Àœš.Lƒ7×qú½a¾Z8…¤Ä,Şmp8B;šÑ³òèF.2	-3
^KoÇ=è2¿wŒt³2ªLÒ	±beéàöñË4¯½’’l©Y(s@¢Õ$æT3JŞ¼¼u¸a{ÓLz°;bP7¹¥‘ãqÛášû3ƒ ×k¼¡:aîƒ7ÌÇêÊáã*—À!6@Ò
ÁWÊ+Ó°ÔùÀ©æè¸;”`rø¿oW0A:<œF—õBüâf6e¤Ï­d=ùÀ$ŒK|l®öy,­º£°RUÇ‹ø‹ü=ªœ¥Â÷èØ×!êLöÙ°ce†ãcá³=O‹¤søÔÇ\Š–%¹Ê·Z–™ßHJË¡ò¿”nï¥E,‰õÉw>Ânö{y÷¹Óôp5”·
k(:4—€ú‹ã/N¥ğÆ2|Œø3Açû[ı\¢¬Ï`î´Zzï»õ´L)ı­X]•'„¶ô•[ø½ùÊmØ†/€ÀP#=Ùã¨;r ú^OZ"moOÀ°ja	xijZØô¶º¥šot‹ä}¼ #yƒg³Tâlì¿Çe4Âè4•®%$ó^˜’EÔz Œ˜¿ë;«Õzıê°·¯8æ{Â-Ìß’JgèÉÁT¢Aa{j­¥ ±í(/X/Áü­P²ÿ úÏ¥Ò¾{à$NêtÚ+p–4ñ@îÅjÜgI”ênÖ°TÑ¸ÊB˜ &Lç‚Y¢®£›DÏïë'R’r¡ğÑbáÄÜÍ¬¤;Ñ¾A€ÖónRNÙîu½3UpnÊE¯<:¿Nò¶û¬È:é|¸Cp³‹-ŠÆÿş‰0Yi{h”m2/ˆ]I,®Œx4ÙqÇ,·9k­ï¨L4µT6bˆ‘òĞÔ˜l,v°üI]àËî?Ùv<V(2ÿN”°xÒ”9Ûç.ŠTãÕW‰ä°#'„Œp®±wç¬Tä¦Ë€ÇæŠòİíÆŠ¬HÙ5A¹+]İ~nè³â¶Ú“XŒYi ¾¨…tRU0¹J¢ğÙg¢_£{fm÷ë ²uÃP„» üwÊ³d$U[@<{(ƒ—#¾h‰‘‹&VT¥*“5ªAº9P×”£[u–©˜	îhÁı¥¥õ¯…‘Ã5)>Ü/•8æ. ¬ø¿éD•¤T|«ÁBÕıÎaÌgäıŸŞSÂPX×pÏIFf
†O&.·êe óqOåÒŸjçãUN·îmDÜ|ÜèÑ}¸ÃAâ²Çä¶dŞJë Äh9şÆ%&ÑÊæAÑé„a‘s½§èg°Sç)˜uº«øì–¬iì¤®?&f(ÌOqA’;~ôËƒBšóM¡„xõ^Ç—`ÁûŸıãˆü~‹%ê{´'ØX`Ñ“ˆk[DÔFƒnı@ğÕåCLO“¬‡4Ÿ“‡ƒ˜}=ÇïŠÌ¿_mıªÍ6:é¾²7–ec~X¶Y‰S>D.2aĞv4LŸ{
A"¹ÿ^2¶	ñÇqÍëİ‚ğéâÊ@ğç‚×“¼…GÊ¿èÏù°uÊ{`æ½ùòLóàv•ˆËÊ4æÍ‹iê»a,ˆïıö=Yq}‚Ü3WŸ=µ·o-íĞAG¿UXW+†äùùù¹i½~G»Ê†3&=@¤¯
àz¥	R§•>T9©Û,}tQO)ÓfÏÅÿ`y_-İ¡6[24ñ>E‡äD]=B(–7S6y\ts¹‹12¾}¹·*äÓâ£¬½’B>sQ}ãö‘K*·ú‘ÛÈ’œ8¹æ»8wcí“—@pÀ¤8—''„^}ÿé@»¼ÜÒ³Ã$W."`e·"êq•î(Gû1Éz4	jMø1"Áim M}ˆ—YnşR1BÁa+J^–c«Î-;¾BŞ´´ş‡¤r(ù†Oá‘æÅF9jšÃ¹6VÁy²ê-(k×Bãœ¥îG¾Cy²LjG0T«dê+öö#XG±6õ…xS˜Ç†Ü~ 6¡¹â†ÒrYĞmv½È†G@†È‰·‡/À´vˆJŒAxøZÓ€ø‹ÇšU.:È¼Â÷Gt€K©ÙÓÚ:6çdÈ{•¾²˜˜gp¶i6E
·ÓöeL=ønjnúÁĞ‡ÔŒÒ•nş[¢ÁëÉNÔü…´gÍ~	Ê@%ş¬¿¢mïk¯cav›ÿyPÚà.ç]ğXL¿’È$ §™!Ç‰»™wo€P„ê¹Zû÷ø&VØkğ.¡@lÆkd‰Ì•DÍÎöíë	Ä?3¥cÍ]R©–R=¬_ªş,xuï)¶Ò»Ô¤%@’&/3Ôµ@‰jÔŸ Öâ‚ïØüRè0b-L³î”ã©)wícÀn®…zöPŠlü,Ï2qğñgÏ#åW®ã˜»Ö¶¼ãÄÀ=TeÎKÙtÕLY?
$ºõHúGuß¨¼ÁvÉ-ãK‰ú“nÅbÖùŒİR¤ÊSå\ü’0t4÷Š,>"Õlèq(BÖ-;Y&ß ÕG¡ó7Õ~8øMxöµÂK¾sÒ<i“3æÛ&ßñÅœØó½°>âÔØã§‡a™7açíÉ®VL=DF¢9+š¬R¬ş$˜\3°GËÖN `ór9™N¬>e¨“yK…£!Ä•Ş¸ÌìÍ†æ)ğOşUEê":9Z€	x´ı:ÛÏm`Ú¢!ñMİšìI¢ 1äó:*’^-¦ärFÖ>'è2kuö†9y|À”˜y½#êè¢*glÓ!HErh²Wxp€ciÓôü "’ÔF<tÚGwXV=`r3ˆ#Y&I1}¤¼¼uıµ»[
†´ØI‰5’P\r=WUE‰ÃtÁÙı¡Şë˜*<`7ÊwªÓ˜ws+Ÿ•œ÷4¾Îz}E+(|TçT0å¼rÄ!±…­rcºd'¼ğİŒpëÍ°"l+¸Y~T¼‡ ÍşÚKì„¼‰J§gÜ}m9¯î{NdRgİ¤ÃŒ2†Úµ^—Ïñõ…ÛMà½"m'Á{¾˜˜¶_ói¨ûÖ†Ê^`±â Ù‰Ÿ§?euØë‹ ³ÍN‘%ä­Kôj…/µW¶ñP¼¤n®ÂİŸJÂzÅÙ‚Î®U© 0WÈÎ 
œPÜmş^Lÿ0åd™‹9×ŞœˆVØä°FN øûİ#Ø~JI4 óòlï¥MtMğ|º½´tÃWkƒ’õËÃÊs·
Ê½ZWêiù=pƒ* ·±¼íCŠ,p)©Ô/zMV–¹kÄ7TÒ¼ß«eC”ÔX¶ Ie‚&Îiøêêû©Àˆ÷OC·| xzmâF•†©,GÔoã@µEmjƒƒ6Œ÷¯mÑ¹kJFC
5îº­rq¨?öY=¤³Ó#ˆ­^¯›ñÒœ¨¦˜J‡kmt€Åáy6Û¾İİYµán…‹fXâÜZŸñ43ôûŞñRÁ¡ºO,)ŒòòÂFµ²yÔçUò°Š!ßóÊ\©İ!%òúJ.Z›éf?­Ó£¬›Â\>pµF.C´…ãz¹êwğ|¾¹iTé‚\Bã<KËäÊf®Ş
F3"®†ÖFXZOéIwœzR„½Ê¾x§ÓZ¢^üÙ>…ßX Ú‘
)zH¦®ã®ŒÙ[Rx S›X}'W¢¾[Xï*³l{ß9:8l¥Ç†ßß/ Ğò¯|ê
2!f×SŠ–×ô\Z‹ôàSØ¤t©ÛuÌŞü Ä¢Öû/øb°û¸Cğá+(¹ÍŞËo‹Efœèa¸ègM³Œ4Ô£ÍE)òĞÍñp:kØ³"ÿüN/œÊÿĞ+ˆaC„Ùf!½LGØ9“pOäş®¬c’¨õH.ú!yÜ¿°é”Bño|ÔHêñ· ËnËµ[gk%1U$´ñT Í «#	™5s¦ Y#ä…Ú€¾-ğ¹#ÿ‹&şC!'_Æç×¸3¬gv¼öYíÃXÿÆÚšÅŞ¦ÑÅ“ nÍİÑÓ7¶t®ßÛ©§›‹jK8g¢4’?˜ÛÔŒcOªíkóóï~EV¶o-ÒYzÀc0bo†EéÏ`Ÿm»]!-“ÑN¿ñúêDX)æ\¥ù²ëşJÚG;YÑbcÛ"L)1è`y¢’wQ&LèbåVoæ¶¡â3TYqÍÄÔÄ+)ùwW¡v"5ì¬Ù*ÊSö ã<3.tZµ‹x.2F·ï¦MT?AO«|¾o´Û#å‘‹Y²ìj9@xùÂ»>¿‹ÿjB9vò¾cÈaNaXON°^}¨µ?á‰\Ù¾o.ñÛöO‰S^‚1÷0’!âYË—¤ÏD›¶ş_«	ÚÙ”¿PÜİ±Úvˆéeiã¶R…z%Ág´Öh—ìÌÄzßÇ==ˆ±Jˆ`%ìh¦5YßJ({İ¦[ÿnßÒÌ¼yjÔÅe2}šv³Í¼ÊJ)}hÛ_w¾×Ò85Qp‚†}½ƒPÖïòö<¸Š½j‘/á>ñ%1jê^„Ø‘o´nÓAj§l(f|@mæÊëmÓLSwYIÜUubRÓíÌ=Ï6óÚ
_óNÕ&÷¥âŞ –À¨F™0m*œÄ{¼Œ± e«„ÅÄk˜†éBúi¯ğbxNıÛ6GÁŒt±
`œÂ`*‚s+yîã¤R?D€›8lFáHN3»;½uG!&î€¾$æ),÷ùŠÆ3-Ü!½„•kÁØ1†­QšØ7uó¡i’G#a•qû—Ì+1j‚>¾Û9¡ÄÊ:ñç€ŸúÛ9ëa°õ‚„_‡ª+×˜fT¸ñ'Í´@ò-qÖÀò>ª»¬~½I‚ÊÔwĞ;Mİ£Ñz¤•Wı¼/Mõ?È	|G7w`IW¯H@ì%|hád¾OFêNxÏf+ß»_¹Ü¢eH9SÔ:"xèy=İÁ$f2ï¥"¯×½F&Âä#c¾?¬’Ü€ü¨vDîŞıˆÑÒÊZğş‡'J¼Ôñ¦Ïp˜×¸8ôÏ%{€MPSÚÚo¸áÇ²•@¤°49!Bá˜-¦ˆõ¯õùµt@Ü–S°‰ZË8ïAR_„Ëêî$3b“1¥¨êê¸E¡&ÅôJÏî³B”òÎuAB8“;ÏcI/=Å®àŞwğÎùf‚ÓñŸ—ÿ·,-òSı¸é'È¶´zäê‡C¦yã`‰w×ç¿0=6cœa+»Jr¡ˆéh«ŒsÙªš¯ÇJó¬òZöÙĞ¦¥w«Ñ‡·¿™l*ØIG¢º¸®ƒÅ§¡ 1Fê€œ“1AİÆ##OªĞ–çœÚV²r¡ˆiö¢ç
ióøôXO\€H¡Ù1Ft4©\¿¶ÙÚ#’˜Ú–#Ş<òVÖ!ßpÒ‘jD˜€toïb<òOÕÙ5&Qã—5Âşï¬	Ù…MF[ŒSİÏ,XCVò™®îDHÜ÷ÚåMßR×ªÅi²è §g­üˆãùGÎ45M.{b-zßÎûëu‹|YI½uPq{=ª’2‹Ü\Ï"â<Tz/O'±RˆCÆoA¾áŞSº;š÷+¤’…\¯\²Íví”›I§ÅÜRïg&­V'üŒ°ªÁ*'Xéı4\5ê~@àMç±ÿùÜZsÕ9|ÿ<kœRÂÊ*ÚÊ¥Æ…Ô[6)Y(ÿ˜öÖê™¡»ÃÿÛºº—x®Ùêdï"bo}_:ş$Š7Ö†æ¿k½<[,mÊçíTîå\Û}ö‚Æ±Î İ´HÖ@¸‹ÌÀ‚·ëÜİ¼ˆ½êÂw.&|oÛÙ‚À¦&R}ox¿µ0Tò±P†8tog’ki{x0L`+½˜çr$²·°qv0t;È]²ëRâZ‹<O–ÿÆÈõ©ŠDú+
¹Æ6ëÂì$pÆs÷ù³44jƒâFRI7§Ì‰CE„©ø1p2àĞ¬n¥‡Œu¢GÁÏßåşŸ@Ig]ï8üT®×ëcT‡­J$®Î!Àk
kñ<™oœ6uL<ôz¼ÒE†œ¡¿‹Ì+|^„K oµ[Æóİ&•Uè½0¸ºÅaIÃ+â2X_·\_£\hRùZÛ¨ ıÖp¡WAÄKÿ„¥˜Ì|­mº,ˆÏ|{é1^ã]‰EÔŸ;ß8ô™pZãpFÑoù]W§õ°äJaˆmõ*¢¯¦.h€[˜ZÏì\èBm~,›Ú%¤×ÚæPìÖ±¡óØÉÅ¦
ú3"Ë	E ÛÀ9„ÅÎ
;PWĞº Ï×h64`Û¼½óL~èã@"›Ÿ©w(-Ş¼(|œ@}t Ì‡=<±¼ôÍ¸M,ßu,›Ü%ªA@Pš Ä›ò¬œ0F¿!X¼ãñ¦|~Bğ‘HëªÁ{şÁ%ĞIºÚ&üù¯óÁb5‡/0õş&#ïëšØ8lÈíü„?Êèä
°ó¼kMš¨³h%Ê‹Î3İoQ¥°PS)pÑ…ÀìSU¥±¬#8ûæZ“¡’
şÒòÛ¦”
ñÒŞvöñÔ÷†H÷z ªãÊ.,A’7f¥µ´ó@&”Ãö•
G¨²Ş^F7l4˜X_zİ±¡ù¬Ìeµİ©ª!l((Q|V^ïaÒ-½G;a‡L<¹Ã8¾&º>áıkìÁÖÉÎı«ö°d9ö×‹r>íRoXiì÷š&S’!6¼o¿Ó
ào­6Û´9|½l$Œ²ºùWÆùwæ|;ÚıM™§‰åZ~`¬°öí¶¬Àq·,¬v­ò’€û.Æi_Æ’6B†ıdEUahBğl€®ùù§×,ïXRbŒÓşxššßøò¡¹d7iÿ(|‹®Å§‰ŠMihÍ¤£² Òm–¥PXNãë«³˜’«©c	l9ÛÙgh+êæ)NÌƒØ@     lP·ùê¡ Í€|íV±Ägû    YZ