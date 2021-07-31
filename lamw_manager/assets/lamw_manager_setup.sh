#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3465215804"
MD5="34f3bb1870df97ea4ddcbb2e7c75dc2b"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23320"
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
	echo Date of packaging: Sat Jul 31 17:00:25 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿZÕ] ¼}•À1Dd]‡Á›PætİDö`Û'åß	Ey¤ü­“½a¤¦yA™W Üì
Ù$UîI´AáC.şÈİÅÖdY:¬Èˆ“PªÑ€ÆêĞçp{Æ\¥¶£ü-7û ¬XÛÇ
€Ÿ(¯fú-oî	îê(´Ä×³ûê2§ôã1¶¾m©şônµ:ÏU0)ÈU·s:ws4“‹ÉÓpbÃPYãÆşë? gT1şì'ÊC#¼òeõ‹ü±^r‰ë/ÛãhÓã@·ûÎĞœP¹Ü{ıÔáiÛ–†|V¤É9c’ªÌİdÉCúlºÀ:=û€T‡\€ö§Fß¾_ˆM_èÒÄ>¥¹ eê»páÔPª<¦CªK‘a;¼ƒEà™˜4GÛÌX©1M å¾µá¥3ç	¤dV›ävpppÙ¼‘œñ·#P¾V/8_Ğ	ÿ	µ@èô¯¸
Rï×µ¢ 6Áºov·øh¥¡ÄÙ^ø÷&Nô?åÌE3–²óşó‚Ø²,Ãi¥ˆ|ÿ;YĞÛ/áú•&“îEûRû µVF ï¿	üúFS= Âº›ZÏ$UH,ÍàDŸìÎJÈŞà«Ì‘Á;(r™˜†+üáıXİ}ŞÃšX¨	{Ms³¾ˆO -é(»1Ôc(Ó7{ü ¶œ®^ï+›U:-TqL_Û!¶'ã7TÕ/t:¸õ~®,škÅk~>Í<¨†û3—¢¨ ”û@¾ì¸ÔÑØ0éábøS½DÀr.p)1Ôbûì×ª
İrø­–ª¿=Pˆ×¢Væ”gmÑÉg®U;ÜzP.z7xt	vÇ˜"¶ï¦ª†VĞ‡ŠïRl6w³¢ÊK
JPêŠã€5Ñ‰èÊĞ¤j¹96§i›óµWŒ¸o}J"_ãáôßWïnğÛQÇ škµ6[K}¾
^³†»v±_ıYªVFÄ—Í‡£+Pkœìè¿wC¡&ãÒcá#¦üZÊ³Nğ§M)ÀÖ±9 -H34Ê#­ÊŒÅè^¿ È[–
yõûExU®=Q1«8Q«h`JMp]ÑàªB‘¿ ­N'»]ÛFu7ëjùÕEÏë^bõ}äH‰¾³²	ÁQzßäÊÔ—àÚ•š ×+èm!sÒ†*Pv²DTÒğ“‰~ßXdH¼ïÚ/8š…í¡%k˜Ø [HKüõ•%hFŞ¢ôŞ3êByIïUÙ}¡kÍtƒ–äO]6<¯åI/ ‹qîyíO}æÍîQô ä‡óôÎ±·•Ík9dù™Ç>mÈmç*o¦~î (¬™r»sªÏ-¯xxJšŞŸNİ[&L)¹Â§œ&n¸cÓÇÔÛ`:şIÙd»œ6Ü`nL+İ´Ş>ÕŞBtö|aU(¬£ƒyT\Ë×2, ^² Ê+Õ¡›ÕËÄ€t}˜ äÉ8o?7¦_v\s‰I%|L;N¦4ÒØZn?†¡NW¤œÖïû/Û%â^ò|hÛÄÌQa@¢÷×/‚|$Mgá`İE‘UàfNğƒÖ0Î43ÿs%C½lÇ.}[O¦`t^óè[>…Ğ—®öÊ¼™İNxëÊşV[
åY7eÒ1[Á4°¥€¶àÿgÙ–p€FçÉ’q×½Š{"—ı½tEx	&ßä3Â(La"û‚İ¿bw‹Ä¸ıÀ¦áûääo?põ¦ "r³¾sòÀ˜ŞkVMm«iËë•„LwŒ…¯	‡^Q¾¶°û7¤y’Ü°½sjP1Õ,i!ÎC?îj&z¾¦ébvsÕ¬<Ñ]¬ÈeËzõağ¿êÓ"„…¡­=#%½5VloªÕø'Ybw;*Æ yßLu&rö*ü'y…C¿ÅŞS» SÕ§7©öûYJÒ‰’DÌ¼”¦° ~€¡åp”m/†JÅÛQD8àÙ<æ6çôSèLwøI²Ø'Y{xq¡ÅÉ¶®øş#[^êfœ{„OQ;A'¢ícSÊÿE0ì_QD{rbn•Ñi¹eBrv¥¥RT“…ìÁñgÍªèvn‡X…3(£ÏFÑı£ØİˆYÖtiÛ†ß±òáÜ¨·Ä0)œ¼“7bMÔúŞèÙª!+U¦ó¼è´!o+Õ„óW­Ü$ıh06ÿ³{éq\x9j3Îie£” [ÌçÚ¾÷°¡¨ÏÎ'˜‰2f+ìêÕğ·o‚b(k]¼ÎV¤D¢Âãœ‘Ì8½ı°d˜‰q©MívR,ï»ÄÈ¯˜0	t¥V©H@`Ù{êÁãGJˆù|áåAE%¤ÊC˜O³Î*!nOÚ-²ş S.ü©+¥ã,—HW Öd§D›<Ğh7M3N|Ò¢¹¤L/ÁúézÇ+ñÉv¾ÑÀŸŸ7qŞÛN™«-Ê àuª™ÙcßA•„ú¤ßxZ•Tä·TÍ”(~údÈ¤‹U«@ôê[ÕäšAèÊÍÆ‹ŠÍ9‚Ê^Ú/âÊ´vÏ ;îµéú% lG?p„äZİ	Üş…üóºÀÅNj¯C	Ü‘Ùpà·9Züç¹ZK.8¤4£üMàbeÄÇJ
^^õÆ”¯ë#æˆû¼î`bdyØ' ÒÆëaƒjÉ“0‹ Éw4V‡T¥e]•Aï¿+HÎ(´yëö£-¢2­\Ë£‹ˆb(ŒIf!Í«­ôI+}œñvª| ¯/»rgV—YÓvÌ[•ÑWÊ£F\˜­ğgK*Ş‰µà16HH™ßŒäÛş:Èú¾SBİç…ÖÜR“ß ß]E³Ó©êøˆÑfÇÖ‹JäïpY(×p7û™ë×@Ò¸*9mgbøxúxù*ˆ;÷Æı\)ŠâWiŒşÿ;Ñ»)Û‡£\N<’ĞUŸwêm9h9GI³|còMÜr’ª-Ä±¸bõ´Oåì›Şèaì+¦eh3º®	uúi×ÑéIˆA:Ì1ş¶-æB+ÅÜ"‰(átÃS0Ü¼CW@·Km<!„¹Ø®fÛ¤”±`<»>Ì¦- ³¢fü6_ÊÕòûI­cÜS?­øcˆêÇ–Ş0º{˜Xµâ¼záÂÄÕö;JĞ0zĞN0R]ñcl-
³J<àT
5 %’ñ)›H§_ÏYÿ{º¥’ˆG{5î[dsfÆ&ÑEÑ##„Ü;uZºª Ÿ! p7sÛL>!Qü	ÈY;(r÷c?Å¿ğ+QIÏi‡ˆ#+öµÉ³R¿`kd™?Şøûqøè.la˜ìLQÀ=!rW OŞç¯U|"R˜9±Z/Ó%İĞ)¬ÃÿYSËCÍ„pbîñÄ¹×±•GÜtØ ÄoëgÆS˜#|²‹åmÓïº õš5ò÷š½K9›»CQ=óµ¶Sáã¸î,ÎÒÛtSõvf´…ˆNmİH3Úcá,¤¨5?^¦|'Ê -®2‡\ñ½'/Äù«ÊĞ¥sâ”Ó’©µÑ™ˆVü®MüÜ{[˜İ ¸ÿ á‡ùÕÂ|j³ÕƒµÄF³c çïŠÏ§®•©¾Ü?¦ğú>!­ÏRæ€¨–9)u¢“Şl!„â¸{Éec/¯Ÿ{‘I*2*&ÎnKã§ß:¡NoıXœ–²…é¾dÔ¸‘y.Œ&ˆÏˆRC„ä"ÎH Î'&@äu@´Äò|P†Z\À¸šX´¿_(jšQ­Vİn™IK
"F—¹vûn'ŒDKŞôÕÒwÉc"±êKÜï´Ã°Şrò‰¾£ÅÑ@Tæ®ôı¦ğˆ7ge‚Ok@!~,‚´À Ğ¡ƒßÍár¤»š‘ÆuT%û·¥¼a6N/Â]Ú?ºásÉèËrqw©0+å3ßÌÑŸÉh1•ô1cÛ»ç.SF!î«3?¤Ç.ƒ}-#¨q½Æm¶´€»^ÈVéèWŒÆ4ÿ½¥†Ø™Èt^U2(Ø´œèGXĞ~Ë¼ƒ{S@—vàaAÕ0|;ÆÜI¿ÏS1ÉSaÁ!ÖCV¢ÄT>©ßï[ß1>:ş”‘ÓÛ%°ÄİpÏó´–óœ™u`+àäƒÄ?@ïÆ`®2Q¶6¼ıŞêÇóO	Ğücí$¿iÔukîÆ Bä{Œ	:L"Ü_!´2^ê5 C ıšO¯ÏDë.D|YW­X¤ŸKxùaÄÂ«Ÿ¬¸èu”"J‚¿¾ÚlPüğw¢ ¶XŠ(ñUWBiüÙØ¡ÙXøt¹37>B¼sº1IËò®Àº7|rnîÜ¯´¶,"W‰Ğçµ«™¸ñ_™ ÀÙæŸy›ú Æ•ä¹ÄêóI±#O©(4YNm` ö€#ÇuN.®p-ñ˜B:´H?Ÿ‰x‚¥xİÑ[›+&ò´yfûO2Ÿ++Â¸t¦4Î*Ñp¡'½_¡ö{‹c{¡ƒ y* ÿG}[.¨xó…KÎîæ§9HÏ:ÌÌP=âİ¯Ò?xİ«uêÚ¤qZJ*Kˆ`ËRó'ùTÂ× ÌU”=_Ä¬Oöõàó©•Ş}sœ«¾µ'ÌñÖ¦ùïÍÛ@?‚ÎÜŒàÆ©RÜûËmÿÛmµy<)Jr<»ƒ_ğéã^:ãRàDfC1‰V8œkûLõ8¿ñ_xîso)Ä{¹%±=!nÄï%mç.Ë	Òîwâ6,Ô|ÖáêÁÛˆI9’÷©AJ6èŒ0ac0ë	ĞÃUÓªUEÎ²øÒé¨í¬ú(®İv6±.û:ÊP¡1ü<N),b	ÒtÄLÖŞÌêJr íİdÚ«ëiKP.»<†Ç9Läø¡ÄwÄèõò;w½22·^5”ö‹µæ)n®¢TÜD§¯N‹7	ÉM¥¦Ğ´N;¼+Ø@c©í°İ¥é£ÒŸcÁÇ ZJòë+ôqóI=ï‹‰Å-!·rHXŸv$ybÄ¢¡Aïõ‚ [ny‡šâ U–¶£¥¥4vj2F%'i¼ıÛ£°B‘dH<«}Ñ¯kê £|ãâÏ©Xt|–÷>]
ÍX§“ôæ¬¢äJµiFÅŠ®§R=WŠİ,ëÉnWn@ıL]Rèó@²éæ-}sb?:À‡T˜ ‹uO³òiz…C[ 5¡  ¡¢Wl<Æ(¨Ù2 ææú¹!Æ–eêÑà,Ñ(J¢\¥kIklø|Úxp<Q\Ì¯…hE¸ø@»éûŸ±±âáoš@?‚á;EnÚ¦ëº‹sAæf5°áÿ”|©·Ãkä‚ãçtÍÆ.ÁæM™Ù’„†ãéb¡xÎ¾?¯QrygW'“¨NĞTL»®/bÙFùÎ8	<²ÁêÎ)Ì'×`§ãY²Uj´É-.L†İêUg¸4¿OÇ¹ğ›€-NV'ÃğP¼‚P=&µÔ‘E”lcmè˜-¸&ùÛºoj;{•zäÀüûÌˆ?¦W¤óÕ ™øŠèhM_I ûØüDÑÏ~H±Rîõ {HkZu¾1ÜFM%Ba4È6“gÎN1Óª‡i"L£î±!‰;ƒVÖeÈšÆ_üÿŠŒû¾€v– 'zÃìƒf8¡ÙŒ¬°‰\Ú{ÕÆóÓÿ»¿r³ËtKek›\z$ô¦~ğ¥¹áA¥©¢Ô+¢FKø¿ÎÅT‘©âg–%¬ò»1Çó’×¬537v)ŠGlİUUŸÔ8Jê¶¹h¹=0½ğIRò°ƒC@ó´øV"™WŠ¬7m0
DHÄK’¢¥cHêµf…êm‡¨àeĞgôz!c(DN×EuÑ™\0ù«Ä'”)¹¤7B!k†#‡£FÊãK^¼í"çÙ÷8&¹éÛ!’&k?ıÏı­qGú	y›Šğ>¬.;$Ñ÷Pw7¥¯QÌšÃC•êc
ÉÓğ î®„ÿ™S®ƒ¿§­­’çúåË×ãê¿Ä8•1^'TgAÜâzÏî"¸aë$|±©ÕM$`£™_ÄfõueM^[äùßdª„;^ª~³6H¼°Ej\D8qI[§¬j³`)ÍY‰²,„?¡±• Å4'ÕÂ¹ëJ=(ÀDyîöyá›eR•-Ş8W«ûu&¨?Íaò
Üí.j¾OP²I|™¬+<ÈÏHÄ 9\9û;êß‘VÌ›?ùTÓ¿cİ¸°+œŸ L‹vUXÙ½V7ºiL¨féŒƒVû¼ĞrÜíÃ4Ì÷Øåı.ĞVÄ',ºİ[èŒ«ÎiÎêĞOb@}TØIdf7«P°åŒYF8Oü,µgí`
tµzÔ±¼6v"àZâ@‚ªW?´×—HV%ÿKêº-eEAKFwÀš:Ø˜æêÓCŞš,ãˆÑà…Êœ°ÅşÈ]ÅPïºV²Ğ3œU­›ĞvÖÖàªö«ƒ¯ô³£µRihÌÊEn 3úGÁS‹Fìa(±¤T!Î½ yhmQ?†…	Æ+2F”B†gt8ÌLà¿\ÈŠg9òÍ}ÜS¨E¾êïKİ¸’<S¹ÛI±ë±¹š×@ñ%™c	t™ı~õ8©•/=‡Rºö¼ ÎM‚şóø³ëòvúµÅ#©P«)~2¾«sıUJg™¥a–‡ÃÆæ–&£²’=İ»Ösâ.ˆ4ì6dÄ—¤ÕpÅ˜l®¬{_=ï]£¶ÈEÂßl lş+ïQÕH(™k9Aµğ­È\f^%–eÖìÉ(Q_¬x§oè•ÂTf$¨P}ØƒÙ)ÜË™ÓÉ°£Ö)ó6W7rÊxĞíŸÓçGõ‰úX˜g6¨~a¯—Ñ|	@ÃádJ “K~@íÏpO©jb¤yéñÏ^Ä‘0°8/şœÑ®2Á†û#©KÀtdL@!"ifdÃ/òĞ‘aıéİärOíø–‡y&†µ²j+àÜ‹Á`fŸ¢7lÿ¤k$f›{pe¸¼ ŞÈ‘‚DñŠaZE“+Ç4øFĞ÷\`ôó“Åä²‡çqzÚ'Z³ğh˜˜Ô‘jO9jsü.‹ªõ÷ÈÑ5Ã^/{§ßñ°ğiÄaŠ8KîËSî”ŞID¹«Ap„½ğÍ é½íÿ_ˆ‚ ‘A+=·Í1•XÂŞ«bE á`“¾ñI8İû‚ˆm(¸N”.*áó=(Àä†\¤Gìš÷ÉeÙ˜Ó
€2©šíL¼Wö¿a}ŸâÍ3½ÿ¦ª½¦	Y
~SãŠCÖomòmÿûªŸ>5Tñ¡İô°æ½ï*¹»APbŞĞ²Mğn¸ÂDoìA¿†¬"‘½\Û xA«é]c‡b‰ç¥IÅËÅ_èÆÿÕe…ÒôoMræ4”(3™Dú‹%Ñ>†Oµš¯Ò>úX|ãĞ¡: ! øÌ||7?®+ÔEMn|¯^€	“:x°úd†¢§Ha­ötœ¿n&ùÌHR_QğE'e¸ÕnÇÜ<3ôÍ±8;ñ1Êj­ØÍ•Üp`ávè©ÿ—Óxëª{[”Íl_U?D^‚4ZÊüÕµ7qüÀÕEşŞ&á±gúG»µh»AXİêÄÅØ,3à¿¦îéI>iş™v‘m!/,³ß8~ˆ½ŸI—Á]Á°5§(Ònl}´“é óN5ğY* zb|HXºBÙäBÿW<êİ8Öâ“:M–,şö.×¬©$)‰ojûa<n?Ê¦xœ•ƒ@©K†§•|
ùƒm@ïeó‘Ò!BP”fWJ U$ ˆ;È=|ß×Š€QÅ£Ê†ÒÕ- 6Šc”M—J£–whÌH×M?G&«¶A˜J•ÆA@î3WM¤Š
ôËïº,^àÛ}«x¤ªËCññËŞÈ<È€=&,“mÿÒ§6PµSñ’4Õ§4Ô)¸Aut`y	’ùEÃúØèXchM		(Ïˆ•ş}ó¦èÈdDŸX¬N˜SÛAR)C˜¹¨; íÂ´Spu˜²ÇôÇÀoênÂ´Ş=k«5Ö—ğ‚¸/_:êèƒÅŒ'É¤Éª¿LÈ;i{û¤ı–c& ‚SK-TÕ@ƒ¶Û	;z˜¾zÛš*¸úë’VÖŸõëâÅ{Ås¼
‘ù4|¾ıwÊjĞWs;%1Îä|Ù»;„İøËM¡Ûa®PİSÖ…[ú_iğÙÈ'¨XÏÖÄm„ÎkQ]{
2İ<åE¨B˜:˜óÛT”–¹½Fî¼¯6°@B¾Ôd²‡§+±™;±²‚1§Ù¾QˆLešüY¯÷£İ°³V’¬ l<Æe+È¹„´‡úÛê]JNÈÍé0~\“˜¹qY6b]øÜìm¸e“4p»º9!»œ3Ç¹HÛ\j¬Ù!öÇ‰œñ©R¦Ô0
ûÈ“#‹
ÒYÂi6ãjïÃ« ÜÆáõØ¢µf¸^ÆÒ ¢„9«ÿÇÇûÉ“ú¨Ï%»~¾’õ—¦Eé‚[P9Á”_xrBLaèy¢1oš­"qÖ4 )ÒîôàókœıVÇmÊ5îÛø¤×¼ìV¡Ä;u(m„!haü´íàyŠSãùÔ¢p%—kI±á8(ao¹ôcñRfmj|š3MüÙ
î^$®Ÿö`1(šşMÀùT–¬z)–¢BmBÛS@g—eÇ¶áWÊE 
u*ˆSŞ–J
s³GâhS/ ^%"¯}mˆ¾›x©ÆÂtÄÃE2ö9Ş‰y[¦èöı06/¥é*Ğ„s¢2”^1Ì°z:
{iI[ßG¨{g®V4Ç’Ô+÷ïu›¡üwÀ,Æbj¨À®Ñ­ŠÜj½_ÄÅ0yPî[Ô0—pöĞ=nş*BB†J%TŞ&›ÙxÛØÃèà@É#¿¾hÍ£8ÏÉ_o«+½±˜»ƒ+f{I¼¤–zJ]Ø<0¦Cò?s½;ë?í(2ñl´2ƒAÖy9×ËL [ˆ0Ö]gºçèO§/æ–£İ8ïL÷(èi7,ıÆ«ğ(XI:¢_’è3­>±EÌPÊ«p}ıhÒFkı¤f“äÊ¾¥â‹Ø¶ìğœ/%”¸ıeıTÒÔ`P‡nÀ(uµ¹ª-	ÃŒöm$œÌ}•âÀ¬|‡ÿMúüj×üÕŸsDøU¿æáÂ”È&¡Yl!’O¢#V«¼¾I£\3„œiohÔÏ<dÈmk:ç4èîásSKp<ÀFLü?IT@(0‡0ä"w’úOüH»_b‘Iœ’<?pÕÜ4ºX	=hØ®mÕ=;‚²„¾I[óafqIp4Së×©¥Stíy´îECÚ‰ğ,ĞG"Ä'Ë"MxZ44¡ŠİèóÓÒmêÊÇ?— +ÀìEl¶ÇhõÊ}Ep¨ŒëW_mü"| Lö¦›Ÿ"ÓcÄfûœ¯M‘ø`}u[o.²~‹D@3VˆÊl1Æ1‡×@şäşOfµ˜ñdê[hÉDuQĞ »Ãƒ~Jé^®çuˆ6DºŒ5´õ&ºãk.Á!\~Yª\ÓYañµêŒ&Ô:á[Üaâä­»’­Æƒ:uY41¸+ëVèà9M'ó ˆHˆ_G!eß÷èÁ•ĞVenl×b4÷?-ŸˆZ-L'äş<°;D"ü£&İõ§tÕ×ni^,¯*ñÙ„I{ã…Ú¿8¦ºº)À¡!®]CÎtMr­W´Ò—=FŸ$İÕ œ2í¤DXÏGkàRø°t-Ğ–¸üBş¤ ¢¶pUY%OÉCıG"ÜÜ²òŸ=âs9–Ó—‹ÒºÖ™YÍ‹«³ôşƒ¥Œø¦³æñ}è0‘º)O­}B>S›VDV§÷ÀäŸè“áæpqûÃm—Yãå¥QêŒ•}™XÊŞõ
#}²Êk?¶.¾îE«¬¨Š«Š(·	?4|¶ÛŸÂ¦ÀşL-¾qÈÿì@~w¬™AcxB—æ¿Yc¸Å2éDÈÎ"qu¿àÓÛvQB
Sìûî€`U	_X±FCéĞAC2‚¿E«"x¸ì ®&!_[rOÖ^å>XlËÛÛ‘Ó|VŠ_5ÀV=D¾ÎÀÊ‚]>§ÙÏdôiğºŞÁ	Rñ1ÔqWjt3;“sËdl4®Ûbé…$8FÏFê)2ªºçŸL×.Ó\ær17Š+YÛOM°¬!Äå¬Ğ3ù¾0“`ØNÊá•TOœqN¬Lbû—ƒëÍ£.O<¼Íë•Æ4#@ŒHµíà!È	PJL±şX¶Ÿ1`æ7ŠÁ™\î™ğ{œu¨ê—t@Ş¶‚vgw pYöÚïWnnA9“Ä|ZUr˜hJı…;'"+íÂqa—7×Š¬Ş)«œş6Å#R‘B‰DĞĞ§=éüë÷×/Ï¶ÄÔ1ı.ô€N°(áÖ}±Æ˜Î­“ô–LŸƒÅÉÛÖ*úNC:E0ªk)GÍ`İ¸ú ëuSå¯ÁÿékÛ×¨’¼Õ0ò@”£É2¤¢0?Ç_czåwĞF8;0Š­•Åûw‹jµûv‘sëZ–nİY¨$«×`ŸWxBkÑë3ËË5$ããëÙÓkÚ$
bœ·oápM•jÑoBKI;ô6O×Êcv§×“*Îä9cÿ·†¨*›mØ.èäß¢Œå+ÔƒLj3Ví^Ñø‘û½ 6qj¿b}Œ>-÷a<ğ=ÚÂ:¤ÅF*¯ªã¼gæX?³×ğÏ2€3%LTìnWû ²†1¾ıp8v¿‹Š«–î‡Á³Ş*öï1ßK-S¾¨ÿ¾upÁ¾ïU¸'»°¿aæƒ’‘49ªM!îö–Àjî§™pTŸÛ´À,2h˜{È¯9È]a	ñ}#bJ¹µi«²Y…GzWnRˆ½gyK#ÄS ‰Ø2ğQ¯ÃßFîºÜƒëjøŠş×ˆ¿È„¯úÃZ¯JAiç6!½„1å	÷wÎ_·®Ç^#‡wëÏÜiDt¼§ÃL»X•Œr§?ÃdMLPFÒtÕù<Ï+æˆÚAi:š7L^ÜDLõ+¡Ìúl.ËÎ„Tú8ÜLÁ±F½Õ‘éCX¡øñ¨*ã÷Õ×Z¿ü»{’útìúNğJ3LƒQ:5i6‰Xsïƒ2å(s: ÉÂ®ƒÈ‹L¹º;âÖŒÇKÀ¹lJ£M`İ‘ÛŒcı¬ wöä6i¿á£²/k)0ÖıŞà²ìÇÙ‰¯ùğ‡«Ü6“×¥
B§2ånù@ß³êD£_Ü+Ù” ï Óà à²y»4?Ä~:>…ç¾©“µ ]¢'>Ÿ@ç‚bÂÆ#V©¾ƒ+d«¬†ÚäÁ»çbqp¶ŠåêJMl(~Ğ’\ßÛ·òn±Ü‹ÕÂ?£[.š[A¬mNÀÓ€^„gUFÉÚ°g‘°‡v,¹;„JyûYnØl-±FƒP„8Iöp©²õÙãÃ–=r£aDh:ËŒ½2n»‡9H9šµNGİš€_»8Z›¯V½åT¾3Òú¶¹ÎH­¢º¿+[×ßÌX“¹Ã°–ò=Å·-.7h—ÿ}l#ÀÜWÃùğqfÇ¡U‡]cö3Œá'rî¦’¾üË0òÆ.Ùª¦ŠC6ç#‘\qİ>õÁÙ.Ü¥tëhÚkk9ÓåÏÕú#œºøög?‡¦ €fsŸw(y«²4¿hûî³+¾i0
‰ó˜p	ü®İU—ğİ‚¬Hİ*dãˆŠ•¥…ş3yPvİ³-²rÇŠØ¿ÖîÁ—£ØúM5¹j0·üC­8™ÔËónHÂøŸĞŒÇKU˜İµš5ê×ıëf ‘Ë ”Y½eoR¬ı¬­iZÊK/‚×Ğñ°êš6›!”Éµà×+UeŸ)—\-¾ú!V¬))>›ÇÎSAñ€"T%_ÓüşMÓ„¦$¬OWÃé¬ß^áâç÷Œ÷ç·<Ç)¡4êwùë+5óâà]o/<²,…èêåH«]Sô?bšBÔ#»'‘ê\ Ô ì()ÿŸÔ8€ØDy¿¨ç["ç*Õéì™È¶n;.	r?…ó¡×)Â©L"t\/9¬ÂT	ŒgÌpÀÔ-RLNÂÖÄs¨u•
ôXs›i!—gÂuo8äşlW{è'ÄòHâ(•¸à9G¸Ûu’ÚTG{Ór±‹xa`{&kÃhêy¹k¨Ûï`çk•µğÚŸ²9²&r¸ûDã€§`ğjQGDìèp9æd&’õb/a &ş.HÏ [£y¹è`¸Çp¶Z–5úªúÊ©öãPŠ£ã<ª˜ÊËş-ÁY-·ÈXë@óÆd H?xg¥:¢¦tn MkIË‘ºÈöq­­÷q—òÉ.p:ı‡‰|®ıbµ,€-§qmÑƒ%	 OÛ3CåÀßÏº÷ÿ%6‘ä„Ì6øJŠKÙÍ6Ê¼.¯5!ü–˜ÈÔ@2+!ÑTÑ>Iá?PÆ÷ÁzTã“®xscç%‘¾t aÕWşsı¢Yãƒ=DÂ¤m‘1'x­ê.D˜œêë`-Æç3­«6àÇÓšÅEbéûF÷³.ßö+F:®ÇS}F¹Ä¡ã[7ösıÿ€¼†Kb‹ñ¡tJÓõì«#¦Ÿx˜AK{óm)È?š áNì}¨Üm«k>*E¦‚xPA†¡Ÿ.‡iáé`b²Èš Ë8¨°L˜$£~pÓ¼^r¢®Ù½$8ìä·!5±7ï_:¡ÖÅ%®[‘êÊî1Õá¤Î5 kÈL¬û]=ÛßÑÈ¡DÄô;”î©¹õ¤ûeì”óÂ\¢a|ôzäOrV€¤‚ú-JÛ´hZºs,"–W8‰¾Ô¦qPhw!ÇÔ©¨W?ƒåošü"2†Ÿò,¶,¡ìËfß*½AúŒá»‡‚ãŒ÷š(Ç=ğ²êmtÅGÍ~eWµŠñ	™ ËTDÒÖX	qUu†¤5ØhËÀÎ’/(¡3jóyœèTc¤Sû¿hÉê¯ `s¤‡D”Â:Â:Îµ
]]±ºÿÑÒÓqjô½…àÿ®ã§X?‚:¶­¬2ï›¦şÉ$Î+İ#QÆ7Ş÷£²ÏfÇÜ›NMt„;NËh7l?LeOaöÜHaRzŒŠÖÁÀİ©mäŞş»3qB+Ğ×Kİ¥ºÎO‚.Q$N±àOtÑÎ?(k1ï2óôhìº>~¼C‘7éZç’ÂÙ6\. ¦(E]Àº€—p3ü¯` Zƒ(&ˆ¡ºØâøÕRb>Â»³Äè"ªv:‚ëËì÷Á»ıP#vò™f~¨«Äç±­&ÚO)2&%Ûà¥3š1ş§ŠÉñ·áãwõ*ÉŸs°Ïjîâğ@Åó¨{à¯óYc
;a‹¨LDg\O6.«Î•õXÚØ%,€É(	Sì«dÚÀ©:‡±æÔ¬DßLeÜ’‡÷œ¦Î|…´€îa¬Ù`?ÄXP$Áá‰âÛ;5gF;àThıM-B‘p ? }šÂò¥^ Z!¯ éf3`Ù)ë§ú%×â!ÊU‚Ğ( ÛS$\ß‘ìk™‚ïJük»½æ=×c¯b&#ÄÆIïó ‚äe‘›§—iš“pFÔ]
ğîœ¿Ç@•älŸÜtEüã8ÅŞãõ6r·KMê£öÅßˆ0»zSŸ¶× ~£’a¸ï%z=ÓÓ‰H@‘6k³ªŞ•%ë>ÛŒ¯öL¯£>C¡H{I£·Ët*ğO“%¦ñH¿r=¾Ÿ„A ×„{å€Ë‰²Š¼óLkœ–G•r¶wÕ9Á´ÖIßSÔ«RÌñD#[åc‹Å'[ñ’ußä„‚ì?=_åüÇïp~å’ÕŸTËĞ"¦×18‡ŒÏÚƒ2VéÃzÔ³È3Ìƒ¦E@ŞÕæ`ò'mš/NÃ"„ïLğT§Lwe™ÕÌ^‹CüÁÏ*Í £Šõ‰Ü£´¨hßÑ©°r»›é!u mİq~"úU‚×“œ
O²û­¢FK[MÈİnbÏ€F¢ÙòùÂ—¿w2ı)Ås}*°ºïl°n\«3µ+šNF‡>†sºÂ¢9®ÿÂt¯¦L	åœ²ºÉ¸'êl-9%Fí öÁ,´¼Î	{Ô”[øMßgWmÖH9Í?'“­š“XÚ†!ÖØAÊ,vT.óÔ×”@İÚ{T±€Q ZØ¤0“Öƒ­3Ÿ¶àåix¹ŠÓpnz×gC¯HíìÚ-Wáx//Æ«z1/Y:2Qs+qÈFÛíutÙµ[µ§ãÙsõ·wÅÿ?ôùÃQ|15g`cçUòÛëŒwäK¾©°ÿ!Dƒ“<\ëFd©	¹Å!Ü®-lpŒPDâèŠ8nª×„6ÇékKœ€ÁiâÎİt†omäğQ¯™dcŸ	Ê´ ¨…s¼ ÃôMåi…t¦'m¶"¿ÆO„EŒ53²nó	BÈÊ<§Ïñusar¾vÃMÁ¬*ÈØ¬Ü,÷µ"»%tUŠaÓ+a^zı=M*Û=OQê}$¨_Øs$¢'q'E4eàøëóı·º¨aû(MgÒÒƒ/šçıW®Ëá‡?Ò[L*=«¾±s{ï¢In’çê„ıÿò{Ï†pı,”‘‡zêªitBsÁkì YMå·ª#¼·`Ã[páztÀÒAõjÑlõm¼ÎxØ¼ÌK¼¾;Q˜CštO i.b~³
lQX†Ã74‘õÄ¡ˆÍ¼åï÷~ÎN8QYOº-ÙÔAâÎa-u¯¦•º÷×j-/ ÙªåÌF7a_¨éÏVùÎ4‡•$èb:­iİy`3šæ²gû'O{×­ãro§eµèT.OÑpgÃfãÅaòÄ¿yÊH~1ß€ªCáVuR@í5QËXó]¬İf¡
²»:°ñ¢:Ù¦KÏ¢-¡<‡5Š¡$eTSÙJX‰.îŒ5uâÀì>85››&DAÈÅ¦°êjxRJç-}"DÓïcÜ8CÄQåÎ¾cëÌ†èÊŸ;ğZ/`ªâU "i!£T‚ÁÏ»>YJº…¤;h4„+Ô´_ÓÕÿúxZBG«¢[J<`>ÇÂnƒ~Ô+ˆ­ÜœÈÉjÌ.âÃ˜6‰e ix(ğrè™–7>5–J´ôà#ÎDb
tfÉM“”-ì	‘½ã¶²ènY>L¬ADŞ<°ó£ÁDcS–ÉNq¦±£ÖtJMmi”‡\ûÁˆòå%bOæÀ¯¦µW§îJÚıˆ=bÉ‹6oúO»Su²o„õ!İ¥(îÀ^ÃÏæ:spŒü‹ÙsrCİãÿeg[^mjÊa­è€ó\âXH=P- !^ÁO«¥€2Ä[Îµµnz¢+pğd@U$—fğòU,?Xµ¹ù\qÖ¾Jyø*¶2;šÂLy¬ßäÂ}ÖÔ˜²vM¦^ĞÔy¦Å^‰n
æ;	¯>P#:Qp2ÌÙ4IuËt(|OH5A—Íz"e‘«ÈmF»ô+ÎOµ0p™çµ~ÚÂOW³~?Ä)I˜¼?³ ¼@`@¬åç¤rÜSÍa<ÏN0QT	ªüÛÉ>šâfVsÜÛb¡¬4Ñÿú9›ğ¥$İÄ¿ğÕPYDOlÁ¼ü¶,Ûs­Q¸‹+û(ˆåw´{0	âë.²\…‚BFyZıRlÕ=³©'¾fÓLÙJrÁ–~›¼³ÿh’hQ©ŸUTT´¶ê4¤+ëŠ/:(v™@µ¦©Ó­C…‚ôÑ,!¿Ä¥!ˆö³Ê¦N1n©O¼5Úèb²ÂÜl]J}šÃ'Íäá_n¥+or ò±Ï1îñµªağ´ŞĞ':)vÆé>nbåû {s†½xIS}÷‚4–ºåJdğ™±TÃs0àz–yµmYWL$’†,à¶ vÏ[Qó"£Ñ}í¡	©²•ÿğ‘Ö-Š­ÏhNÉbúŞõŠPÕíUR¿[-k¸/†OÊâ‹¶¥6õíTÌÿ×S|Ø©ôÓaŒõ€Y6Íôš·¥“`“^o¹€G-^Wh'õTiÑ*ŞkK
¹P'q/^Ûƒªc('C…‰š?­1;=ª~ógÜ*õAÆóµ®!ş¶ËAÚ …-M$*3ğæİÎÔÖ¹™eYg ïa;Äj¶Øw3[A“;åC•b¶‡RDŸ	­İ`z)Û·ù Xú.˜ejÖî³Lm;¥ø.¿”»(
s8GkpÄšèÑ³:›X¬$kg)f‰;FüW#ŞC†€)˜·Wã­ Ü|ˆhj¬áç‚£~V¼]AøöäşPeÄÊÀø{•-Ø¾Ó'ªâä9>ºNTÑñ·¨3£I?Œş2éêbn®M× Ï!‰Ò@6ğz¹´•ĞòMÔıìeÃæ*–‡t¨)fsmà`‘ÕâÔäòí™5V,×F‘ÔÉŸõ‡ËùL°VÈæ7ñ¾]ÒÈwàh><auğñjÚ=½ÏhÒ„/Í·ôØ²¿~[¸nuœvhğ5‰” ;¹vó·ÛVD,	‡Õr2•o8÷o¶’b…Lù:f€qóö#Íu7ã¶;©ÒgãÖ1²Ü•€'oèÕy‰lŞŒpÔ+VäHA>–ş!Û«;ì2SBMÎºa^iï™ÓPÊbYdÊR7@ÖHğ ˜Ò¢8)ö~'Mc»í‡ÉöÆ±,HÅzìf	õ[ êg÷$^g4ğídOS× ášù)Z¨Æˆ"Š{üÜ"%Ğk¹Äî–şÒ(AKôf7Gßd ¼U¢…“ÒBjˆÑk¹æ‰—Å24¥$wWİ®##+@ƒy_m…á¯ şètÎ/šF÷r¨ƒÄÃzÛQ!ÜR<}ó×ô¿LÓh/Góèşú‰wò(Œµƒ·ƒèÍd,©‰3ıU(€YWX‘¸eCp+,¶kÏTèu¾6®¹GÌ›yK KL‹NÀFÈó˜ù0&2š, $º%ê1ãŸYšú\Dî{È*–²=æºÉDÕõ¸Y¬ê)äâ*ôk×K6
)štñc:±A#90\[ª—Iô ¤î*4\:Üª )Qoêçî¨×R“Sj¯|íİ‚»ÅñôıHóšš@ƒ•@ğJ›§–û­ltI°gçO¨“˜eœ®%ó¸óLÎî".([_MB™Éÿ¶’îÃŞtR¼ÆÙz[”ŒwBC~9÷B@œ9şó¹ãù/é[cN-?yıŠ	^\\2ùû5ä=š˜t=¿K RÑ"ódÃ™5y9ïyüJkM4I òÂ$ewËôL|ÚÇC†«ÔHR!v¦"n ø`JÄ,{TÓuôéVˆ‡ÊğQg1b§†¦S~÷8¯a&R¥%`WİÏÌÁÛ‘ç(¿\¾ª‚‡Ob€$,§[;Ş½â¢-_éÅìŸê&5,=Ş«\q1ÚÙ!4
¢=ÃÓ€P¢€iò9ƒ¯–Çâ¯E´v¥`2“µ½LÕ*¡¼Âó]z¥Â/R”É˜S{“¤ÁA‹fBô-çÌ»Øi÷o±€ÓŠ˜üKNÖ,¬ˆÚoõh¼¥5$(OÜ,W‡_ô$EêÌ±¿ H0p\? †‹ÑŒ¢rÁíúG‡GÆ²q¡¢mòÜvÜ³”2ûCUgpÉà0@iOyfx·éØ:†–é‘à2¢¢òe6†”;,u	q0mxî¬ÖpÚ´Zn»‡}¨zÙ¶óBZ´/c‡=tvmå§íÅ÷’¸Ìs>Á«]k—U°>òK% uÁ©·™ôz²M™ztÛ2pü[ò1PNâBfÏ<V!›Û ŸrÈìfwÿø`ïôïóœå9™å÷Eâ/ µ/Ëû—á½U#ƒÅ£>*­mÃløà¼Áé›ü’Ş@½*E›ÿ­"›RAŸã7NòleÁtd¯åÍYòtbïl«û×’cºKİ³Zº,³ë‹ YY>lb_øóò£bà·Ñš:s]éTö÷.Â4y¿&ô"kÊU{º>>w9Nšò 0|“ uOiÅıQY€€dwÈébGÉÍˆ›åÙ@Z÷ÚÕ“6ô@1úKW®ÊË6EC¡O†¬?^â?©)€†[—0}ÏjŒKÔMQw%q:×"äê·dJìcß­ß&J9„*ş”w€éÁ—Ä¢´N}¶áüŸóëS ¦öf©>á›Â·çˆ½Şñ·u/!\Ë$tÂÒO—YÆô0Ø‡Â³–¶PÇnB¹p ˜ÇŒÒm§?¬Öøs&ôÕá-:!ûKCêZp|	ãx1ÕmŸ­b¢ÇüÑN?qgÔ­Wõ§±NÉQ;¶îv§»J]‰Z¸è
X6şgş´èh3ToˆÖĞo´yï@d8¸êEºš°’Øñö¹Æy‚À’ÃĞšğÖ)(œ½	2™g<‘îqíŒ¾QOâë:¤R»è¼ËÆsªÔ¤TÊÜéZ‰áJhvÎàø'.@˜ úº€U	Ğ•‹¸ÀK£bqo¢­u±,Rgh»Ñ•Š"ãñm
°Î"TJ0“4‰ü®²ø)™¢öøù©ø›2Şúyıº0</¸ZËs xÌáZïÓzù¹²òicfûô¥ÜAÑCR¾»í›ßíIŠá¨<8Z¯z¥0¿µ‰œ’Š©‚Ø]lJ‹.Ìä9@*û×Çì¬×˜Ö%Ò˜S³ªFa–E$Ê<xî£Iğµe/>p04°•Kèššáe­r?S]Æ¢Û˜‡òw@$Ş0Y“)ç°¼œü úóíßE¥’KçÍ±3å±Â˜w{ƒ)MeE9ôçvÅéG½F‚OÂÎIÿ=kº®1úÌıS¼Õs‰fœ‰úò z#’ã‚ğàû;9d˜Ë«Ç_ökÆd]©æ#¥?¦­‡õ5Ù¬ö}º(Å^W$êŒş¡RÊo {ıg€“³ÄF¤9È#e³!´€}‹Óİ|ÔÅ{Z¦Œvûñ09‡IpgË´‹¶¬6LŠ%t²¨H~	'O<Sé®>±Ò<Úy›09èÚ’ÙÍN½£†÷ŠÛ1æÒ •âÊŞÌ­Ã/)MŒ/#@ m¿~ª€`GfîíĞIæRÄ%Ö`éN†œTšß³5_”dù4Ÿ†Ïzäıâ}ıº‘½³$Xsã¬-d]ëİwÛÖHš5›içÈ|#K/„¹@VGÁî4ÍÂÀ~	çM¥GS¬jıåæ•Ñ¯>Ä``ÀoáSjçy+SÄ,1àád}Ì`ìM°ø²¤'{ù^uê4]TD{{ßYÊy%deôèehï|öF,V…Úò—Ê"A¹‰ü©ÈÅè´¶mg¤ºue¤•Z xÜ¡s¹Á¹5?ë;¬‡ãVƒ÷£š÷ß9e”€9Çyß¹ŸÇ§¿.-áBVË ¿0†D!¼¢õ¹³h]»AYYîU`Yœìş™éÑî}ıš¼LÃ÷y$æò%Áùû@û7£igàÃ‡mÙsGŒ¨âç$nKÏ§œBd9gÄ{– Öbï"´T&ş¿Ò>šá\×¶YüÊ¡
øp::¶ÂLô”9+tM!ûó¿›©ï?¾\ƒè9‡P 1~ ¨Î‡¸S™òç!¹zŸ»øâ‡B·˜š§avúÍµ‡y-}Ùï›M÷ À
¤UÜÃ´Wæc¶
~iãí-T}ı|3)º7›ZvØ±øå|2_£©:GÂ.TCæBCÆÄıFÏrR5S4lÈO¡ñ[yå–ïCÈH6[^¸ÄJûhgÇ°ëÒ]Ñ.%/3‹'$ãYPŞu\èÈfá‹àqğÓyúí‚5b‘…GÊ~Ã=ëÜñ	¸ *…vKj«Y¿àEÌg}“˜â´/l loN-è4›“4ãî#(O®´â˜+~ ‘Ö%±4ÀŒˆ·™6©x®Rò:ò—Š½QŞ~~"Ìb¹´şËfÀÁ{D8â	Ó”ÓªüÖ¿Ã§À¬É4¶'$•÷%Á%û:e/‚p´?ùT@ˆLı\5”,30e»˜ƒ×5„?Ä7¦ aüC„ZB	#&ª‡ßv‚n;ï¯O”'Á„!¡j7ÛÕ6ÄÌğ£ä°›Øª×òFt&›ÀÍ¸#9œèÌ™ÒâmõGóVÂHx´l	GNCªÛS©øÏ%^ğó¶áVï¯â%²t9=-'Ÿ€"î«”^øÃÒP_°«l™x1‡÷‘bJÓì7÷&pàÄ\áÕ-ÒMC7ğ_İê›
·Û””{(a!=À”7‚áyï3 â§Œ‘ôêR“êSë‚Æ¶&„H„ç¼f±ƒ„ÙôA±%ùÎ7‘•ö#õUiÂ¥3";Éx@^Òçi<5;å76mÌµ³gîëõ„F!!ŠOe6JB¹Ú× mĞaƒN]¬Çhğ>ºDà–é°  "§îìé˜á¶]’Àß-û4÷'|î;qã¸?»ÇHÅÅñ;ºŠd+µ…*Àü¤ëVêvßŞíé1´øÔ¡.í÷B˜àßîşïşèÁ¿jÚ!PfI£›lå€ÄŒ<¿›3çø(¿À¾9şÓùîU<Ì¢k$]#ñ+Ş2şÇ#¼&ŒÕßvhu<s_n|­gŒ)ÜÂ-™t—şø–õ¢İÖŸÊ‚G_e U[y¿œâeæé*‹
ÒE®°LË`Áğß‚¼F˜ïèr‹\\Ş¾â¦RÜ I2¤åDwlSâ$:ë=}Á-ŠöƒäpYKÏG¶Œ’àÖ­µ<˜ª¯r•/Dœö’”?7õVÿ”v£ßìv@…ıÚU$Â¤õÑ	ƒI[ÜZ|jWd«ş¶)MöÔöºaĞ¸TÓ'ÎZ|L¯„uT&G‰‰ÁÎõÒ/„Œ bwŞ/¦cÇıË"HºT˜£”&9(ùñ^j¤&Ê®È­ßíô×ø†Vî0W~ü·*"ü“êĞÿe³SïHïêœK“º]ÊÍÎb]é›Ä‰Q·­îµ"Ì2+º”3¨=Œêõ¿Q©?|=ex8'†¦6…+#ÿ´Ã[lp8şe±~yeqÒİKØõŸnË\•
S:ÿeş# ªÖ hÛ;ÅİEñÓY¨“±„_×pñå‘ëƒw˜í¬ÿî¡ĞèMĞF,ø%èLiŠ«>˜'H]WÒåM|ª7îQŠ ˜şĞ4i‰1÷!°;DP-Z?ãÿFû²¿ám+¬Y÷ı¸GödÜ9g0ÁÛksÿŠ4CM,Whšá£¦,°Ê¡+°Éúñ’@ıöúÓ¬})·àŞ››ÕNÃÅÓDØÔùX4rNÉKˆ„ğ«ƒZü¬ğ¥åØ±Î&Ö¿ÏŞ’Dn:,jˆïæˆÈ¸}'Ş¡'Y"‘,8GgªÄ™fp´]Dù‚·cN['}z$/¸d€imrEáOYû›q”i! Ür‹òÄ>ÖwôlüGœsÆy¤9qÙj0Ièbm„¡ó,Ö\3—+Br=MS¥³Z(Æõ®ÊgTnĞnf`rÌ¶qÄã-Ù¶Qa5u8–KØ!7Æ> 7$TÑ>ÒNÜåF8ÌQµZ)(À|ÂCn‹úc(í&¥âé´ª«†l~–o‘üÕº(ù•q”É’ÆK¿$ïZÖÈĞMü&¥°ğƒÊ'ÇÁ¢=Ìì“·ÅÎr¯1¸•ì·e“NúŠÖ1Ó°7®«hm®Q&0òAáqQrnÑ,ø°h	´†.éiBfmPayÌcÃ‹0ø¸T>^ÑŞw|‚š¿-á°ÅmåY¿ùí/Óìò>„ıS¯“œîØ˜+¤¥“j“:şä7Ò2ÃÖ§¼á.Æõ´¿Âxé1–¬r¦¡ü5ıT„ÊùH)™l*‡ËæÚ @<ËÁúìöö(ŸğÿFAbæºìÖ	?~\Û|hı‘yÙ1›•VVD2ß¯ÇH4¡rj™–ÒÎp{IáxÉ\|•b|ŸŞJä¡fbxı¿dc­jœHN#gËoñ‹›‘Tdó‡ÊÔgÂ,nÃÔÜ5ôsÅJ*Šëp*
şÂHšªyÄ:Rk¸…tJÜ!’¼Sühë§[BY$Ë†7-‘
Ø¸ĞRt®âQM
AìÛQÖS#ö}4€(êHı].Ë×L&xÇN×¡lñÍ” ¾ˆ˜((²á<Øotb‹
}–qŒĞFìok¡¿Ô“S¥ FÁ{dòt×£eKÆXÆ³ìU´v|Í<e€¿®@?¼uÿÑ°Ä·®Ì…¬f}dãQ
`fÑ®€{Şša–pb
éxn¥o0æÛNÀİJÛæÅQ*·Ë¦³#³şã*
jä	jùªh—Ïb¼ƒòx€däûE.Aİ²‡uÛhu¾ÓhtĞëj­Uƒq[IÂƒoø‚
AT&j™ÏcôuÏB†
¥„‡®õêÄù`ˆÕåÜØ–â©1Š&ğ]tåÄ	CsòölÓ*Ò‹¹#jˆ€§#|5n¥±yDÁk!ñ•ñ¢:ÿüµÙ;ÿ{Ï·¶€ ²O}†Xç–ØÓÛs‹G.ÎDğì®ed½EÑûîˆ&w+®ÿ&îl†_¬lG	†lnuP]ÖE0kMD¬‰ Í¿²à²aó2[§„‚8ïıÕë&ñŒ('. ,ìzû,6Ut+­{kš$'šı†ùÔ<)1q¿ÙvpU›ÍüWÚP‡‡³lÁ*Ç*KgCÍF´Z±70× sÏzJ{œ´.¤ÄÄ¤ªÏıSiïÄË«>¦š´Õ¸”À/ôÂ±ÀRŠÆG¦çÖgTXæ	…O¶vB³bîø×>}§öàÉMÄ­%È4ã¤{NÔ„´n¸¸cÖ	ÎÈØí(%J
(Íòsl®1ûÔˆ}ãì¸N‰Ùz:6İª©_»bÂcá!GW ½<Ö	QéÓDÒ^±?H.~'¥dÅµQ–‚Ó%Y¸®Pñ*,æ€ÔãI—q‚?§»m1zÒ«-æÖÜÃ3·:³>çş{HOÎ‹˜ƒcÉ¦¬HÊ‡ay»+@©œÇ¤n®üıè—…¿&ÜÕjkMã\ù'LZ2ü`rÛ€8+»ÀXhÄú€äÖªíy4dé-o4åµW]ÿ(ôX§À½rş	¹N`ÂU]ƒøÅy×óEã¯ë€ô$üø	S0ÉóßxŠ¡yt‘‚is,5à¾ë$uõÖş°[™ü|VÿDâ­_>Ëµ	"à»RôÚêäæÎ"Ÿî‰ø¹Í1|ÇE©·:"Î B#*€ñe)<É¿œxh	â–Èõ0Û´á ³ieÈD£şÆ§s}q)š¤‘LBN&SÅ½…ğÂü³dxŠ%m¤/],l*Ÿu©´¬E~J•ñO¥ŞMâ¡°úÓåÆºş!0ˆú†ßœ:˜úaœœ×‡ê4AÎçwDªRˆŠ°c!	œÜTß¹ ú60¡ı+§rĞŸc%£_(çIëİf;±£îÿ2kƒŠ3İC{cC]5‡ø…€³DÌ\Ô©ê¾Æ†ùD5JšÿÆÙ	jÔgSn[b\&£.GùƒŸç¡[+±A<{a:Ìœ0¹t÷q
/í3‡bï—†±,Šg÷Kâ@ÌTtnóQ†Act’µÀ¦å
Ä³Ë›%â®`63¼°òœjdŞ §j:2-·5¹úbŒmO¿5˜ü‡¼
VL`à·Hçµ¦[œÔT,×Ó‡fˆŞNÛ­Âğ#‹£¤Œ£k²¬ÇÚ‡:·I_lÙèpX}adƒw#°†!Ío^nZt‚–ÙÌ^Ö‹Ë‡ÕCîñÌÙ´î²Î6HaÅ’µädĞ#S6ÇdÎ“”,\“~ÎÕ§»œH¶–¤£Ú˜mùù¶¼îÌJsfqéKA*ˆİA÷PuÜI‡ÈœV|å÷¢ª¡¹ê“Å´46t¬<³C:ñ©Z|ëÚ2Ô*;½ˆ*‰°¤¶Ş²¹%!¼çÃ³ÄËˆÒ²ôbØwm™H‹ÿd¨O±å>d‚KÖ»	³ı“Ù•¦[]àvØıBp2 F@LÅØÈgsfr=+lûÛà:…>0ÖM„!R±.–dø:nœO(y$ğ‹“m?X³Æ`Z½"~wq<ão³>¦Iˆ9²ÙƒxàÑåéG&ÇÁYq«œâj Ê‡x•†p£3±åî(à‘Óû_]i8GŠ‡l3hØ(‚xÈy^j!UÕkU³[Q#íSóøË¸£2Û¸ ş¡^¦õĞDä¨zPQDÅ‚È@©ø¯uêW9‡¸°ÏŠÆjaıf¢=#O3,ÄÕ$dúûS!¿á§ˆK „Q8Oé˜X~R`øü?êàÚv€Û¤4!Í%Qoƒªt´r~£×ñ<^Oy½§Ÿ?I<—š¦[ğRdì°ÉõÃØPíÊïÔ.­!¬]ï‚A³é†IP'oïF@aTĞT`WeíÚ.îÿriÿ …Q^A¯`5•\5ŒV/ÁÙHS9İÁ®Š	DEÒ¾ï|?ÅÀë»¢Ûuù‹¢âDãÈ•\˜¾64Š6#E©¶á\>¦UÓF×)¦ü­ŒÉIï'B¾+†ApÁL“/e†'<¯¶¶ÑU(¬nËK®Oè¬lRÍPÕ(ßı;U2iù¢Rq®hÚÜ<yÊÎ%ÎóÜCÙZşÅ„ñ-dóÄ$Ê‚±»&Æı­)ız+ÍI>ÏID‘{j¡>şn(}œº	~¡¹mÎ ÍİM'0
©‘ï Åw¸Æt/·:?“ÎZ»û/öÊÈ¨ë¥Q»Ûg±‹‰ÁíeãíttØwc¶µIÆÀo:•%­¥·X¼TôèĞo¿&(I¸ü2é?³;MÜí¿x[R”™Ôª{ñ@u`¼?[V?ü[Ì¡ûRNtnÑ\†6=óHèÿÉØÀRûºáç§”~ ÊW¥™¸‹ëŸ–z.ƒiº]äzÌpéˆró1›31 ø 7»¢¾J‚®ªD¾¦7¦Z1‹:eÎ|4èHïpãÔôxGÓĞun÷–­yÂt.Ö‰3{¿»Wœv_}êG™¦×š9(NyB3õ°MÙ¥@\¹aÔ=çÍlØ‡æ…MAı*`†Ñ}†˜çT1Z¬k~xXÚNï`0ß£ıui‚˜ª`¡7¨¤Ot»a;Ø?*Ü)¼,w·J
æ°ø'˜l3¼IÍ†ÿÎANìÙ£%>‘à$”’àÊ¼Â@«6yG¯õNs.C;¹/CµUÓ’[Ò€Z:áˆ}Íxp¨·aTŒ'Ñ¡:-ùû¸KõıùèÃÂ¯ÈímÊ):Q¦,¤}]ËŠó¡ÂÓ+€îúJEãšl`Ã[¡ÊÎ{é/IípF†Æ']İøW”F°«ÏİzÕçêŞìà†ÄMı”^§…T²Ùklˆ!¥İt¿ÇöºÚ·äİ§Û,Zs¿uóÙåÜ±tê²Jµ”·¢5/È‚ûdSÖ‹ŒˆwO?ˆÆÕêD"GI_tó E“e{œê¸EÍ^•öu›ô’åêõc‹s®«ĞİÑï\ÛğÇº¬²"vKµ~^˜èEü€şP·g!¶Ñæ İÒÓ‡$ƒÉQ•Ç¦˜•ÁeA%]›¼ ½qºM£‹=‚™8£ñó•.ıÍÊ÷MÄWÈ²Á†»1dò…FŸI8va&mó÷bm|“İeğSMŞkl”ó|1˜XD˜fE4ÆNîÆ„{ttSNŸ!ShúVL¬ù»2u µ^ÓÚüc
Õy±\ê÷I)	09$M+R¼ïãV$,çÚæv<÷yj±Íã‚¹<Ñ&I:v¥˜ÄNc óŸ¨GœÉg¡~$Qf:m/E´’~¢¿‰…Î‘Zü@ †nT)”‰¥ÕnYw¤ßxÛ%moÖtÔs›b2¼ïS®^uÿCğ;Q®^µ‰CÏ]U½ŞPØè´¤jsg“Ü˜%^c ÙQ½;‰ãà¢ÚìGÏ
àÛÿ2Ø3™K¥B×^%?if­é¼Ò@Â›áìÙá›¦STÜäKø	14ñÿRox{I¦ÃÎ^à‹[U^ ¤ãGbË+÷Èğ/.N÷vh>0¬À\w®:÷b²ô¹@ÂXbZK ½;
§É;†xio¤°
k£h…w*ùµz¶{s¥¢,Àèş-
ºêõ`¾»OÑÕ3ş×Ÿ˜U,kÑUüïp @Ê˜ÿi?ÀrúïZ”Õ¹×C¬ÅİŞµ¿?|*S	Ú®I3#L_ÈıAâµµŒD¤ÄÚI_ã¹ä)Cñ{ùIâí¿³(Ì@—,À‘jç^_Ùbu?µ­6tWHÌœZÕ±¤Ì?w?ù,´CÅ$Öœ¢ µéˆçf¾‡ìô/ÑƒØÂİ±¯À•ˆÖÒ=8Óy×œó*EúÙÃş<9—sW÷ÎÑ(½ÓMí'Y‘ûEuf„3h¶¾ÏL½ĞêK{=5õ;\BtA.+l¢'×ZQ°Ù‹á+£4$|d>m‚×“sÙ0ØŞ¯‡Ñ¡”¥*Ø¯,8?|õ7*ªs$Ü‘§Í‘Ci9]`¬ßå|²s-ö`BÌ:·NŠğeæ·éq¿­Ğ+0ŒˆÄ)É~r't[R¢nÄÜGº-W

Q¬ƒ5ü:’¥¿+´k%vÏÒt0ƒêj3zMì¶¢—‚hgÉË¬İx]qÇFìŠ)}ˆ<\t¬¸Âx•á‘pµlGX÷ÑğL?Î£;Ò‰EÉ•˜Ï0"šxé&Å(NÌ¢°†(–¼c;H˜sóŸl|ö»BÜ©­2¨Ès ¥¯¼†¸üáîRôDQy¼4#ê	«Zi¨}Ty¾ å!ts¾lâ{~A©ÍÏÚRs­Â?‚ËË…Š}$Ì‰4WaQNz›.k4øˆù*‹j0¼òe”òÃöúÈ=:1…‹)s•ÕØ’“„³¶™L\ª·¨º½Ç"ø4%¥SíAòÉá6ße£¢;{A9).T¼q]^~)6Uµ+,øìkn dòô­à½VâàóY{£Î-È1S¿ER!Ÿ{‡'RŸ0R¥÷ ¸V­%=Åûbò0Ï(ÃÁú]$dáx»í>¤tq Å›Ìu—ßÿl±‰B¼lÉOdLSóªñn¢a/Õ,åd›—OñIkNSÑ¥<`N
r†8[½=„Ú÷‘(cw±92goK¨–ıÖÂi"krë*-ImËáŒ?0dšCïŞtW”¾º¼Í3±àßšO[à~(GmG vsG´Q3hE•ï¡ïñr/¨öŠŠz€„¸sÆ±D@¼J|üÊAT$—òSP¬zìø%_:‡>k2s¨pÍÉÖ˜ôO­\ù«ıÿÁ7†ÿåW”áÚö‹ngõÃ#Ûc39Ê)ëßõæ‹c•ı®ˆĞ‚ ÃŞ£‡”ÁR¼&‡–w1½Ft5³Äf¦×úŸ[“Vz“—Ó8¡·ÏÓ€ìó[çQ$4ˆç˜¸*§5D‚¯ÕGàQZ|î©£†ôßw-²™k¥v­?ÆH<"ßİrÊ`, ²Ô¬‰ ^ıs¤”ìÓiâSªWÊ0Ì¾h½`ßíúÚzW®oÓey»Za¯&×şªlGEC¾„otO7î×õ&ïÜqú‚_
MS]Ğvöa0Zr]Ñ' A ÇóÚşmhL§Ç¡Ù2)^a¬S”2ÑM¿ÜO\ŸóvïSpã·³O«å×±–/ONµˆMşõù—¤±â\ÎXu1ÎÆ“íÙíº­<KÏx|½FÁ¹í·yÆcJè ‰?Z„ÅvÂr0šÑ±L8%P¼” ¿˜Úİ¤4èIÆ·ŠY– $#Ñİõî·½;á#Q<¬áUa¢÷ êRëW»le:»ÒÂø 6£S	8âúÔú_äÙ³½6ÀBÂòÔ<Ÿì•ú¤ñÓø€‚zëÚ¯
«ËŸeM{)^>ıÀöüT†œ‘Ù-&]ï8‰³AÀ ?K>ï$r¹ğ ûº¸ç_ø•†K’jKÇ‹l“‰YÎŞÍF¯É OÛÕ&š\/2ÄAkTd2 süSêÔb2uÃ\¢ƒŒ¾ôúêä‘ë­eÁ¨’8*ríğ!±øáÆE2^VM°˜[]^ßa¸tXº	u~P1be“õ¥ÓæUç>`ËL¹B¿"ÒIšñŞcğ±b 7åeï&\³ï}ş-Ì_NIv¿³ÇçüÇ"ÜKğ‹Ç\K1÷Q¤\	ÖyºiÈ&Ó¿µ$Èím7…L1–­è!Ã¶Ì÷‘5ÍD…Å\èˆŞßëZ ôĞĞçë¹Ñœç¶ÒNÒ™§8u6÷şÜQ	š›ÜÌ
w…)·@‹]61Vóe"İfÖ…@âLcD-Mñ‰œ‚U•İŸéiÑ•ép%VÙwó¶å7ÓWŸê€ƒ±Û6fÏœ<*–r¶i¨˜"@R'“ga M[K·+¾ôSÃµZ?Ö´²zWh›Jaè.5´¥ù‰ºRÆÈÑZ*®İ÷ÂÑMGûÇƒıG,•…Äàí]Y–dÔuuæuåÁoÄ[*ıÙ,˜¥g?Sˆ,Òª#X×Ï”ª7¦8*9?pŞÕ2œ–FX¨ ›o€ğ…[î£æl>YäááKmãÜÑFj Fè|rk„ã•ƒrD¡¨8"÷©¡$÷påœÖù—†¡ŞÒ¨Áú«dÓ3uAhh (Lº:|¥ìÂêÌ±O‹CÍ%4g#R™o³ÈÿÎWó…X`Ùİ$çÑ¦ÉPÓpâ·x¤èï„iEĞehR`°Şú%‰¨Ó€N|LÕÀª‚’çb)£%~™jQ]%¹y•Š¦D®û¯Ä¾]ìì%õØ4ËÂéÏ\_iÊJ©ŠLUÑ4$¸(ß”D"…ä²ç»Ë³,YäO•“”ìˆ„Şãù@ÿ•œ>øg[ÛÑ›ÀGÉÉBùøÍÉfàËN-Y\VaZÉfx4ê–0iƒıŠBó’Y 	
KÌ+~O¤´ñdúşqùÙeN+×uqËĞ5ƒúl\ÌüDÑ|xBú3ğÈ¾yd¤æôD•˜?Œ•²pÃ÷:É2vw¿7èkİ±ó›ƒZ\âcÙiŞd<œ÷	 s4­2ŞØÍ²¿[1óvö²É?¸ã4³'?('[o”¶S ÿ‹õ’,ª¸\˜¼si(öEÙn©ó1ZI€rVìÛ‡ÿ–¢(ã€ú+ú#	“'¸fiêİúha-GÙ;xÖür2frÌşM:6 W•Hs qMÙéˆ­ADBl(µ:âõ]zF¦²–C“'3ó.AdfsÁÆd–Ê x5kŒjåşgy¸|DÄl'ë÷âƒË±¯Ü•àr™‰	Ã´G…«6¦ªS^}ß“ÿL¶)öÓÛ§\>ÂÏÕ?4É‘”ù®çZg«ãF!¿X¾ |Ìæ4[ş’]bNgTêbw1ú¶aíHo
N mS -¶n¯c­hªşÀÀâiŸ¤Ÿ&³QN­ éÓ!ÿä\ìŠÜ]¨KXc	 ®û%`é½Ö-b¸y‰˜©”=Àgõäê»¿å‡VÄŸŞı¥SÂ5ª¸RzŞD.†Gí:ï…_‘d>öÊ÷†œAÿ+*Ü%Ï”dïhêmsÏÛÊê¾X ô‡PŠz‚wMWªslík±NÑûò­Yqô·@8Æ…Í†DxÎVP&ZïúiíöÇeĞ@”m|,À^d(¾
à»²=Ñeî=”]ôÛä«€lõ5l ‰š04¹K²ÿŸ
“È³»e¹q:~Å‰›·×Ë§/Aşmúum·@,lÕ˜bÛ"7&µ2?À„
÷A ²ÁÓ?újN>¾ÃÄpçş„””}Ø½«qb¿¸ß®ÿËP ô?¿üğÓâ °égàëx
3¤ğÒÍ '¹;*}`HşŒè°•ã*J¼æQMè9GTÚ¡™Q´à¡¼³ªsÃşŸ/ùüÒÀè×¹bš³¥g$Ö öfMjyúÙí=pá¹")¶‹‹t©:¦2ŠÏ>c	¡,ÀùmK[˜¯°qe˜^üÍ—ÚV./tX?M®—.;j\»¦-r—tÖÙö¨&*!ãŒBÔ±d’éŞ{·	æ0}õ`k/A¬VÃ?yví     kÍæÏ5e ñµ€À§«É±Ägû    YZ