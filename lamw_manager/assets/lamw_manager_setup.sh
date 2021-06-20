#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="661737737"
MD5="3ee6eda8e8654c9f182f6ade282871ef"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22900"
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
	echo Date of packaging: Sun Jun 20 01:38:01 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿY1] ¼}•À1Dd]‡Á›PætİDñr÷o/±ş¹n¡k5Mæ]Íôz|×µëñÎN¥¦Ù•/Ñ¤W½•dBnÌ&â¡y}Tƒoà°¶è)làm%^i•½ÊîB8b°vùÛFÅhqFŸƒoÌÈ¶c­T.Œ¨ŸIb]cc
µŠXÚäv_:µŞçT	8§ˆú'¢ªŠòZY5²v\úÏ¾“g¬;¾S¯ùKSîÁªgá¨‰vƒ/p˜$¼¹P¿^pî©vKb
ô·˜y@Ş>Á”¸GÉ›>5z&'•»›Oªq`©åLDq=>ã‰
rß ¸‰y[¸ƒ]N¥ìÏ±ó’t«sGÇ†wq¹‚´ S4¼M+¦[Zd¨ÔãÂ\’Y° E†D(lÆ¤SÆıãƒ¹¼ş/¦0å*,WcºEÓH°)Ò°ˆ…l$©áy°ÒWÎ™ÆYÛFK8’gWFºÈïBºm1œ­ûµ­î\ç¬gép§4ƒÜÜô’êmSñ5q¼!k¤ğñ+`&«bå>5ózsë>nÌùkeëÖ¿q†?W`	¿Ï–E@ç¶¦£"=c£Äj¯}‹¢‘cÅasÓ "bua³êÏxíá½80NÚr}ÕcdğÚ!C,²^$]s‚Vç²æ6tÏ,OPàhw è ¯úúå>u×O¼W™8±¶­FÙ4ŞµŒJmŠ.E^X¼ï€O4ŞP(¯r¿Z™\òV@?¦9¢49qˆ`jYï´âÊ±Îså•Jø’ñ|4§ÆFÇ’¢”Á`pvÊZ`jx†È­¯"Nß5Í¤ÊÑ7"ãÆ §
<² áÈx6}H¸Ó6‚MÈïOãÃÚÔÅ/â<®ÌÌáŸÔs	Z­…V¹†êİ˜IÜfû.læõŒDˆU–åß`øûŒéOËñßk/Ë¬¾ìÕÓF³¼áoÕ{F‹Q§uü$4XƒĞŸÊtOÇC7
Á¸ÊØê¹gò%°ıIYÛ??„uQ™LœeXc²Æ7Ÿ™fH¡¹(W	š3!f#Há}4 ~*îi–ègü]º6²ª¤Ib(’˜\$ïnİc:òïÏFÇ`“ikS Œ	Yç†BŞj‡i«Œ šPò‘à£ï~‹aé™ğí˜‘Ã[ƒDÃÁçhÂÛ1Õ6¬Åu…EÌÛ:·XÀõç€À13Ykì,²¢`ÑŒ(~˜û“2á™Ì$Be‡İìŸ8Ü»èÎ×Ü«Ñ+æßú"¾¯HLæq:œõE½öİX¶†ˆ\ˆš6Ä)ÄÊgÎ&  <ï¸*mÖ-H	²®“/ˆĞb©ıû	L#é6—,.C¶Ê/~–íloız+-Ü+rQÇ…ˆì lï…Û,>îD‰t•bË&NRù¿Ò|Û>UÏm¡ç>y*ÈÅ	´xVp
˜ƒ¾Ğğ}oØŞ+æŸN™|eèµK$&¥³9s(ÍQ1ØHËÃ‡¬XâågÇnT>€–?^ÔØícÇƒ¿yÉ-’éòC•ÊPUãğÛP±÷²jİ® Õ¤Ñvr^3°pËš•$ns²isÔWêá{]TÜ~™lªÊã`.³İ‚X‹cjtmáõ-×³ËCü çÕÑå“F³…/iÁvá6ùc¹@»½Ë²½p'~$uÆÿùÈã-i®ø;°›X!Doî¿ T{	]“z²"€Mad>t˜ÃÁ»5†«IBà[2y¸h’$ ëöä’1—ië8ˆü{ÆŞû³˜2âš|'|'$– 6ª”€‡À‹¦ÉeÃ‹ñv+“_³îùv28<9[2şt÷6¬ÚÎøĞ¸ó«A…öìñk<Í0÷{A“¼Îi’¨p®|ñæÔƒø/][Ù…„ ş*Æ‰÷$-zUcN>TÈfÊ'ã)®qå­äë¿ôy¥ùÔ:~HS£=R’øJp1Âßå*m­Mßøç6¸Õ&°pi—¤À3­E›²b
½]ÜJÛ{½§Ú;¶™¼=:VØ´"·–ó´‘CÔ³Ÿ€ÀÇö5’åÊ·¢<è8…»MP®uÔó5‘…rÖV{*-Ñ—^€í–4É-¨g÷¿ì€	
JÄŒ(¤ïªé?÷a†_tt>ÎõîG„Ã¹™ÃĞ`aÜ9VTJSîœ,veµø•ø}x;yï<û*—İáîl‚ˆ©'¡åi©Eó£¨D”¹İ4xÕt^İ U]]@†M÷·‰Êµ'}€Òo&û›<Ë €ÖóğK—ùJ2Ál{P¢İk¸p>µ`‹q;íà×Íq·Yd!Üæ~¦ºÒ¿>÷ïí;C†'A+ÇÀÇñê>ç2ÛğXF’0€ĞÀ¾¢Xmæ[ñI‡øŞd=]ªïŠG•¢%0G°ñ’–ãûÚĞ¯kŒ‹Cñic<Ë]¨#fí VòÎÛdÙŸ *Ã³_Y­ªŒK	^6gßqCèlURÂ«Ô*Ø!B•‹ëHÇz`ô«ßˆıWáÓJ™¤h­OÿÿÇ9/5ünË
âGã‹%$­@:4/4:åÙâ¾Šøx%&—f×4õ)ø<FA?Aàãkx(Té[Ì6—Ø1!ßàqå¢"“fõ+tùª¹îÆ¨Å"¸òÇÊûØŒZ‡o¶—Úo‰Î¥°£4-`(æ1bDô®\¿4?«m÷‘fèÁéRwB9– Ì“—äGÚ]´=JP¶~ÇÁIÀ‚b©`lêh`Ëùë¼U«X8»²a<‡¿Ú.î¸O½Ê#­HïÔ”[°)Mmnôw6c\!,ÓÄÚ)ìîª’p‘¥½4÷ÅĞ «©©ÙòêEC!¬e½®•2ÊX!ì´fş 5áqĞÿkÛA›€°¤…íÀ“:]rBtøñ)ò^› ÄÙ{%«¥é6”[äeĞì©£¶È„÷jV¼‹‡VÏ Í¡o•£ÅTŒNqøã¥ò*üİUÆhL€¬s-ÀPÕ¡Ñhv¿ÁªíPÎ~·{Ÿù9t¥üÔ­r_4ÂX±”vCÊ…Âxo\ØÖŠn-Ã‰Êæ$w­`±iç‡¶¯‰Ğ¦˜å’¾´à‹”Îâ±®I
MÚş9ÿh&+Ñv¨_,!1šËÔO	ª !×3ˆŒÌT<Æıb©ğˆyÁ+¢ÛMÏ¤VôQæ»ªAOM!¬˜ÆĞr¡»P8²r'0]»\.Ä0	}İÏ´¶À»XµÍ×àG]GäïÀ£aCÌ[¤¦KÉ@ûõ£g°Å9¿zÎLá¼*Š÷¾µ(MjPdª¾à}NXHÜ¾2ˆnşŠ!Iê`·®ĞŞŠßW[\]å73$ã0nåÉO8ƒ[E_Û½¤¨Mö×M©İC'RpÍÓ]ë
ˆ°6¡ëåğŞ ¡áTÚš¿£§ù0pwÌÏ}5>Ù€QúW°ÈŠj°úŸ®H’ôë‰}=n M+£l!|’à¬&«ıïoÓÓ$åÒ¡gY9B0öcæı8T*Ş*FÚÉX™µ‚ÛEÚv`…¥õÌã¦#Ğ§ãÈ¨„e@¸Â[ÚpĞs	3MÃ/¯ÒÈ>ì©©ßÕÈ‚×:ŞõgÔ±«GÀĞ-N;÷¼ˆ.±ìöo	'`~”ğ4( 0°‹àá"n¢9Øß¾Ùê3+÷ö¥B:¤'äüü©{ÛeŠ¬ »FXåH;ôÎM¦Ä¬ƒÑ/“ ê;FIB—âí“ÒÌ'\
È¯tAùŸ½}5N°¦zJ‘Gú’zßó‚–²2›ö`ğC[?ê)¢,
òv„1ÈÇ—=JIY!¡ãúƒ‰$¢˜WÃß›½#¡ÜğífĞÇÅµióv¾
N^VÅÑ‹“NôÈkë­eˆÂ•†o	È†ıX4l.
ªŞgÂ½¯FÂœ†‡¡M/@jâŸkl"ìŒ yn —t*Š`ìd)9óÕ*e«+ìüçŞÿaŠù]äjãN¿A2úg¹'2m"Kç}f¹7ŠKÆÑwëT÷9ÉQ„®ŸdN0½™E^¨{	¼£qÖ 5“»U9ÔğµÀ¾YÂ¢ËHÚ -ò?åGÊın±Ş3†ª*p¥¯›“XïO^ø.«0™·B2qSÍL’ãsúl3%’ Ë¿öQ¨™Y¹ÚÈÓ+;“/…ÇU2¶ŒbñŠBÎMûü
>ö}=Ğ	Cdm¢¡„L?o«Ò»Ü	ëÊ|ëÓ`Cløûâ l0Æ+SÕ Õ	C5mÃKİgÿf-Ğëîi°/Ûø+§Z†{n>ïëŒQC”Fo<~wŸÖ)®¹ÌÑùnáF›8he+—I…ÁRNdÅÕë€¾,2`HêŞ<kG¢¹ë|”çŒHÊ4:Íú„Ï\áü"û®g®”pˆ5bEÏ×8Ó!á|ëí²ûÍÙ›v•º¬©ÕP¨:æ¨™1ĞJÉ™°á¯÷ôŸIáZJ]ãø­¾Ãƒ5ë&J„õˆ–È¼-õpÆªøc m¥2Lìøñ8•^"Ì×gŞv•Ğû Ä¾ğŠ5Î„ŸpF g%İù’Ã"ƒj•ÿ6Û{õë˜xkù1×NW´² #ü_Ù9Zn+Âûİ#½±†÷² ´ËÊ}X,?“eÎ*éiV9.o“§¤Á*¯\êÇ³.zCZk'dcŸ¥pïİÕ®´w¡±1(yèÉÉoĞNGAC{ÒÀÇÙ^d˜æ©şóN#ıÄ?‘pLªæï/õF£ÚÊ»øÀX1e­]‹8f"Ø‡÷zPMÂ¾{¬¨‰™[Rè4.ÃÆ&Åì¤¼Lã[ßº'°"UÜû†ä?ez‡Ó-Ã¬¿)'-=1†Ï	³Ú¤ënİa(‘f7(ƒ`Í˜Çß:AÙ½kÎMzNs×6yÂ¦,Á¡ü¦´õÎÚ`™»BfQ²p¨º›¯µãsÎØ1]PDÂy`Ÿ
smfcOâÅŒïõ÷$T(åSÖæ¢¨ôJi]l¨ËÕš¹Æ’Lœyäô8¢Â¹Ó.Ö”ˆùfÛ.
Ş{{ŠÊø{µ–› [ Í?wIÂøVÂ¯4‚ôòÈôZ!¼¯²äa=—,‘&<ô?&-*%˜T"Í/¹C©%zÁØBZÿ${ãŒ%&„¸B û1:âÌì Àâ€‘÷)pX«~ÂQyº?öş_©9ğ…eè°§ÿóvQùlŸKğHèe²x]ÒŠ[¡õCÙ^¹‚¼¼Êu.MÕU •C±€o~ïOÜÓÅ¦U|A~c¶$•lµ!=Ò©ëÀ°l|(ÚøFı•<¸ğ¾+Şì¢Í|›Âßo9O¡v”ßSAŒb‚½÷Ûöæy$:Pıˆé£´ŸËë-ô1ˆÿ
ŒE0¥èÉÍe8x0İÈ8ÕZ˜ãî‘0õŠq-5\XË×«0?^ÜmfcIñydËNöÇÉkæƒ¼Ó‰>M^İªpëÛü¯˜m­¨@¨9ãâÕêY¨ÓÒ ›—Ç½×,W›g'úˆ³Ÿ¼­£S_ÉˆRËÄ^’ùç=?E%X†ı#
ªÆS58JVW^8Ìî·D01¨wÌ™ß,BòÊ+Ñè=ôP\M/–¢_á‡î!<ÖøõÌŸ\gãîÖÈTŒÄeË8û'¹åïêÇ\ïjçÜŠ>/=ùIüÜ\˜»+Un„}ºÁ\†©{U?sÌîÃgsˆ$…MøyèÅ¸Í\[¯g“bÀlGsT8ˆ;¤„ÓŒ-€£Şõ_Ú™ÙãıXèç5¾Ï-1Í¹²a%k¼º_—•½Ê¤qR~ä7 õrì•â¢“äd–¡Î·™~ˆ~˜AÔ:{ü½ê‘”Uqf\Ûu”*›‹ü<)«—ñ¹7µ-¹ÔÉÛ¥U7_wşy¯À5}Ô"gP£†¹ø—ã±©ÿ5fmN¶ÉóTüƒµxŒáÄúxÖÿ…Ily1‡º(×Cgê:á,à5äØŒòß¸­—üP\}ù7W –¢{r"ˆòÕ‘AÑwá¢ë”Øs+ËËº¾dwÄÈëÿ|œCW_›*È~ZÛS¬“§Vï‘=L7ìVaÙÑn@lMŞCÙ¹ØvK¿B¨RJ\Nú,?Ñ/øQÌçó[±·Š¿€ˆ‹Ó	ÂtÓn!2fí9)yˆÍØĞ%8¡úïTöëw½‡¸ğ=zÑm„ŸúuéÖ7„Píqsû®é$?ŠsÓ',Wì–~VyÃçg¢0¯¶½‘İ',k/¦Cí±í;_Pô\wçÜU¼@ÜS¬àhø¸¸Šá¸ÀçÎšƒŠpî>‹Â&Ü™KÊ¾|	¹Ó0=®oÂo¨qëWA#ÿK}íg=wÎ¥{ÇµÓ| t¤/™ww/»Ô’ı©rûÕ/Éİ®Ñ°UDÎ|­ü¨°÷›»_ˆì÷}ësf+ŸxY»êÆïñ„bfLêO1W\Eå'ìoù§ıZì"¾ë À#ŠË¡£¡×{	¾¤D-!ùÊ¼Fş¢µ¥"«ş>–bHö!Ãv yíºÆí)‡YëÍH2ŒxÏth$‹s¼U$Œ1"šÄÉ™âÛrà½>Ø=MP±ò?ÎÃeåîÅDø½ÿÄV‡)“­'„5Ğy<Í¥z}¶}ówGÌwç¾˜~g\¸M…7ÁO«åÕ‘2·L­¢%$ÙĞ€Ğ‡FÜ4Ş°àÅìÕZTóyòîëAëodXŞê?oÎ ÚMÿbc°Š‡ËOGJvæü ÓGû¢·jO³-~²ìİÇ ø4¥~4İ£ë»–ªâ"‡YPRs‰†Ğ“çÖ­jme&CÎÉDè&CXÊé©É³3æòEdh‡”•¬£p ÒÌRàõgÏœkòõ´*áxhÓWã¶*"bó??±wiê1É±ÖŠŞ8Ñcs"Œ9ÈR­âÁNÕoVj½Ô‰H3X]!ŞoŠõc£Í)Å;Q=",©È„õ«!l¿'ùÒ´F™ú¶ÆT ?6îÎ”òp˜y”b8	wzŸ‚â(õûæE6~mÔ1»Ê'–D•Ø¦­=ğŠ‰M§?Ç75	2FïsÊÇŠåöB:È<—N\Å®şØï9˜J—«?ÇØÔÊpˆ¯}¹s+©a”=İy4ÄÕœYB(ŸÑäA$šmgİvWÈ¬ş¹ÒgF/æ Ş.@K=˜	d…Óüjr1]å½×k’ùÈÒÕã+tpòVE°£İ¨=.´Õ;1QÌ"òóc6°¤ê†ÜI×f¨ÄÃÂ ‘TûbÊÅt-¾™÷W´J©³ÿ¢}Z\(Í‡èB ®Õ®İIÉº;~6eOšØ8æša¥;L	[i”ª=à¡ìé†>îûŠÖP#âÆ½›˜^<<’Õüt<İÔ-½`´’å=âçßHUghsYÔÍş(ÉZUo4îÅR‹ç
Ê¬ä ğªé yõoÔVdh$[%u—:êfEøİÕÅò€ê_ŠMÿq’K]¡È/ôP¬iCx2ãRÒõ…®hY[Â z*#‘w‰¾.¿¥H¾®ÖÜrË§úWU1‡ìû?X!_rÍ0Dæm²A|×A’/Ê*L´fšœ(Œ$EÅ–‘®ÿ ªq£Fş}¨‹_š”|Á3|á	ZJ¾—0!ØşCårTÕ×e$†bî_]"«Óé1xáõö>şË7¨ªF¢wCmrxıPÛî
~şÊgÚää~Å3¤Ø»£ØS³¥2¼WYA‡z®4ôÌ ê¡P¥½ŞùärÒ•%ï3çF!Ô¸®ì¨ºök\Y ]G³&Š®ı75ÍÉÔLÜNk@,Óşc0
è™lİB[FÇª4$ÒÀ[áQHÛ‰&'úÊìäU´¹V§ÿo8"ÃK2ÀïÜê“oı=eÃìe5¹§˜¸Îã?Ì~¤A›&†TJsş åª‰ÊZ
|ØAğIDQû"È´l¼<~.¿Ÿ_\<æpkØà“Ÿ(Ó cÑƒC/Mì®kKµ%;jRtV­Mımö3 ‚p2ËàY`îÄëú§®Ü¡‰„9«ÿ¤}“ÊÑï>ˆ>ˆ›:y”‘«g[*‚i$1PxÉI|ª5í!A¢jıfßs™F#ÊYí§]yğ{¦É¯l6‹€Sï«Ã±ì–¸ÃËò­zKZÓ˜şhÅ¢š”ª²«–=Œ³ôê9ÇÙ4)®“İ={Ç±ÂÊg{35<×ù½<[%«gL›ôœšgnh"rş3l¼]éÕˆ±Jµ¹ĞrÃ˜m$¤;ÆçñøŠ=ô/“„Û&0t“ç=üo?Ï¶|îiû”b®†3Íç®pÿKˆrz6¡¬/ºÖXğI<Ø Vp5ßçÎ‡|ı©Š¨&‡Ï ‚ÿy¥åxV„%Ìk]ºÌ¡ßÖ )H8L¼¥nØ¥8Lt¦¸®­ÙeM+LÌ,!ÈàMj,Ú0d¬‹éş$İc÷ãÿâñ‡E´±³Å˜v×1øŸÌ¼R°îã5Ø/‚Xñ ÔBçÄcáùq|£  ÉÖªİ]l ›3lZ‚0Eó’ÑŸ'xsğ¹ŠÇFÜüÛŒ]ÆÀÛòŸşø_nƒÙÇjÎ[*ñˆùqÅÓ>óiV?k,½t‡5®Îâcõ©óõÆª9T5¬TbcÔ=´ÙıYù„¶³†€t‡ètÄÈ‡Ì$¦‘ò7Å¬R¼k=PãgCàèDoŠsŸ –'8ÊîåµØ‰Xr»PPPvih¼´fø„îĞÀ×§úğ7îÓüÃÿ„~®®NbÈãÒ…E£‰:QêF/Ñu´§›§m·†<°ÛªÓ 3üùOƒJ1˜lÖ9ZJ	WÈ¤C€Hof/k®¢ÃP |—»kç¯Ô”˜µµùÄ½ì¹A£~ìŞao•‚"©oúhT¨ƒ%ıräO‚¾3ów	sw–WuEË’÷arhßw§öc_í¬»ª£¬ÏíŒĞ–y5HAˆy+d›ë«£¤d‚?«WcÎ7¢]Ó¶`÷…½rX#&İı!èI”7ãÖMì˜¦±.ö	êAóq)F;B•-xôZ 	ég¦Ğ«ÛÒfÔÏ
"—cÛ›Ãòâš3‹Ü·²jkàÆ¨„iJ9ìíœEòVtSñjĞö©NHe-ßsüÜ}¹R=oØA¹¹í§e¸À,ó-ñ~à¸×YMK5¢NĞ	,Æ†k¯æ¬ĞƒAĞAÎîBÕt	Ñ†¥òùà4¡»4J³Ç—q'á§5¿q¦8ÓÄ4,ÚèXm’^\õBŸp{x*>ÈôM¼£óõ¦ıÕÌ}´hqT<íÂŞüDÍ!÷ù‘\NÕÉ]¾\©ú	eÍÇòti®*sü¹³ëªÓS±®ŸSiG’’…ÁH4Ûèí,ú{qºÜ‘½m€UÇ¡_%ë-<’Öïõ@’İoÒ\£Kö2e^‡Wë¤Y=Í[[üR½ó51P½$^‚Upnˆ¸úå¤‚)sÜ!Üİÿÿ™TÍ¦Š»Í²àÇ”=}w”7Ç‰lTq¥E¬HÏ*¯<a—”¿T–FÍı‡Œä‹
,ª«¾6{Ó]Uyƒ¡.Ã,³ú´»(5r™®°Ûôúè>1y]^+=6‚r¾º‹Ï9—Æ¢à¬
4ù‹”“éÆûéz™7ª °*‘&uæ¤ßoá÷«5‡ínJÄı{?C…³^Ÿü)™áHW”µ–ûd¿,¢jo0T]À,Æô&›ŠWE¹s«T<>`d­­«/e«ª/ŒíŠ´œ<Ç"å#DB˜†q|6ÑˆuU“
˜öò¥~FQÉtH*I¥Ò¡¶!ÔŒ™c>5”¶hy×¼œl/œ×’É¡I9Ñ¢ HrÎôZ9ÅÄN<
¹8¨·i—&õr>î,gHş ²äÎ^²G%Cç•[{ø¶2
™wû„rËW©ZjuÇğ×7< ^¼dÒ»^K¸2ê,nÅ MjGH¯VŒi¬'$wÑf29åÑ,ÄR40#ì„#kGúİòö>Ò‹ĞØúæ@YxÄŒò‚µE4úìE±¯ÅP))±ÿy`wÛzÊcÌ7´$`õ¾”ˆø£Å[è%é•ĞnyØK.$aÛR)A­„Òö÷¯ßy}ë¢Œ±]´é€d¦İ–7FúD/Âv"	´ÎïƒßQE{!)zBÉ€Ò­QìŒù?ˆª¶Sl7xû§®2¢â©,ÁX0¶xLÅ;4úÕ>)Ñ¢@ÈØòÿî'û§vÙºRsXTŒ‰rW!à»²ò»¹zÌ—ASª€eâò±Êd.€‰ùh×sN ylé†Õcë­lU†‘CŞ)¶—€_–o'Ÿ–®møa˜ÃĞ¸Ù>ƒùĞŸ‚ª›³ßĞ×8~«,á]ûà^é®Ò{ÚŒ©;ïÌ"›)©GCD m>Bëç#ÏEùR·,ˆ1pát3ê˜ß}ÜÛù¾±ò]^ŞdË'şkh/ÕÊDgÆfDLº»¦N½e‡ê“ü­y;0<kRGÀkhJ‘ó|ºUP©$#ö$©2BYÇsàQöŸQİèÒK5¦šl| ±[Ÿ—AlFM¿–Iëö,¯ºòÔô´GÒ°Ú´a}§³‚ƒËÜ¨G³LòF4„ÕüVï	[ÊÌÚïJQáEˆ#&Ád¾·N²ğ½ÀbP¢§cB4¿¶r·Èì»Åš4X0dóŸ©'n¹¿[?™oec|ùnA¦ ÂÍ—ä×ĞÖPàëøQÕ,±­%<ü˜²í~j?Inh>-B//ò87˜3Õ{XÓ]¯ÆÁÿî‰x~_‡i´lù 	Ö,¨ØåZ$´mØJH6:lq^9—Ô›×RŞhg‡‹óòî\¦Só ˆ¶†¹Ô§SØu)~Á°`öüˆóJ\79hg;”¨áşê{£AĞm×¶‘æc˜éø¤ËÁ®ùÀ³J,¯ı_¤j{{Şxî‰ø8¯<Jr‡Ğ(ªl­^|p‚$V!<ı­`F¶ZÀZLÏ£À*W+Ùe _Uzi;’İ¨d«v!d>I"' è.uYY•«ûÇRåÀ²ÒT_Å(€–Gˆ’Ú¹şw8ùİCQF›z:#[©Ñb¸i€2yĞd»[_Î…|½1¢yƒ ~¾ØK|0w§²G{¦FÇi•+ñ|Ûê‡tùï±—p½àŞ¾Û“¡Ï $ÌVe_OÀpà-ò™ñ]mƒËÙBìóú+Å])7ñÙTJ¨: *Í¨ç™…£¿÷KEvÏ1SRî~xN’ˆß¾zV>Ø÷™«å§YªSóó{
â»&ˆgŸ¢c&\æš$åÏDQ‰‚ÏnÊıôg¹˜ˆÃ‹zòƒ4­ÂQp(»‰aÕÄR2ç’mR¿–x‘éª–îÚV„PÓôå5:²pèÒ@%ga*NE üKYjÏ)ßş€ô#Q!nIÃ<eé/¼4Ğİñ_šş½,†î­¸ğÑÎ58DÑ-åÜ¦·Ş[t€¼¢:èKÅk²î´dï×å«É]şªNt%°\ÎO5âxOş¦°–*$¦½oİãü.‘¢Ñìeç‹É0æçy¯¯“2b~¥¢®6|Ã,”-2[0`Ãê“)?–Ä§ü(±Â:…wVdÁ0ş;mÇ²ñø.pL¨;Rål*ò<ŸnZ:bû—ÌÊÆ¨Á<‹oG×³Û¶ş6Ä}L(÷]1B
R­*š€Wj)¶¯Ù»L	\4ü×#\Ç+I€¹€mmÔ)ºvs:|GFõõ›ã]zEîÌÎ JIéCÉ©RñmªŞx¼‹=›Úf¾CfŸä>ò·MqŒ–é<OxKWò	¨;-˜a˜Zú"Š½ Ü÷Ô	`¯É/Â’k¾¤öL-n<˜”yÜ#0Ém­“oÄ `»zØ[Ækvğ”w"ZÀ+sèıá¼´'÷  €¡İV
ÿÙa˜•îhºµ¤úCø«Ee?ôt€€#—9ïşº£“Æ¾Äñ#êŞ!r¡bë½Q$OnÎ=ıä8Ûu’œMÿ^¢ƒl¯ßıíê¢¨vjù'œ¹š;³ÏêSö«í§k’1[Àmk&vÈ>:KzS·âc÷¥â8ÍG,æÔ‘l‘HKzã\TKsgïáBQÃsŞşÆÂ¿g(?8®ÔŒÈú[7#ºTæp÷`Ëï”–0Â8í9¸i´üãñDÿkê<Ëw¢Ÿ‡,f¨‘¸ı¡gm²¤ş–7?½§9ˆÑ…¸
—>mcaÀ•‚a=¬°P¨¹£"­[E€éŠZÇk8gô¨(­0Uçè¶şQÈSbş)§µdµ?l¸;à,TĞöÒ» ÛmûNB¥œÍôFNı§.1ú³Åÿ}…CRêC¥¬…o­=ˆK­(Cg>µÍÕ½ÄÃX0<øáyst2ÑÓ…ÎÉa™¬
•H†EÂó»fvJªV¬æğ—cºƒ;“¿,;„r­8A7û-nP+"V-£#îl¾ÕÀp=¸7-Kÿ«(õï¶p	nÿ`Ş¯ayJÓ¯»8·;Ó°HEœI@tô(NS9Ğºnı—	z¶ö¨À¹©“?¸¸‹©Ærøsqj¸>Òë·IŸ-ç9%Ç†–†ß—Y^"2ŸkŠ *Ì÷"ÔhÀì×IÏVqt]ğ"|ó"ÅTÕvLªN\¯Š›òSxbÑœİN ¤˜âBV³üN	ş8+TŠSò?Óe‘¦áŒú>ô^"şç¬F?_a0¯ZÂå…4<$ä6+Ÿ®ÒŸ$R¿Ù×ºo2ë:ÌmªÌÔjïD›Kò•¨îôÕzï]¾~ ó°ë(
<ìÏğà0/µà ‰â%[‹LÌº¡Ó«Î²óºD±§ëeøuxâdX+|!ÍwR¾
tƒç´zËÔ²é1¾È<óèÄà/Y¸ìöñò5­®çs$sL‰©¾X®·|¤±ä¶‡ÁG;Pw±³»Lİ:šİã¹A)ØŒä³5;@î²1Ú"æÀ¬×Ï«lDÜ>.Ô{½h¯2ƒ«íåò·Œ%]~q;]n•¶)?Íè\€’tÆÈbI†ØÚ`%j÷ğÌ#t¡'ĞG¸‰Ü×†
™‰ÛoÕéa€oøØ»zká®ÑØ„†	±îu}ıšµ\RV¶ñÉ%qİA¦A¹Û«áTZñ§T­áüÍÊ~pİ3’èÃ½§s&Ë@Eyü?%K&‰j-ÜH‚5Vİƒ§Á›ƒ²×šı;ÆNã/ç3«,4ãÖ!ß-<C¥í™<èYä•ë~æm*½ÿûL-ú°2™6«73àêıA®ü¾=Lç êù>DßŸz8À¸jYİ‘P¦¼Ã 
Wª(zSƒô¦™iíç9Õ = |/DÄˆğÀÒÑ:`×N·~V<¢LÇÓ~¦K‚‡$”¶îU•³iéòûÇÕG ï¯¡Ÿ(M©Ã3Oê·'u×„ì:Ş5?»ğûV>–GËÇ(¾!ÿ±)p¶¥Wêğ£“AƒØèÄq‡$=AÀšçV>Ö?(vdˆöTIÌJªõB–u‹BP“ş}HÛà1’9ÌN³½¸¹0Ki¢Òø›ô”×ôfšË‚hût·Ûïö©T˜­üä´®S‡‰¥êí]ãºé4oÕ	„¬Ü» À]C«YZO°=ÆåDd	ºãb¯¤²w“¾;DYäRÏ‡‰‚—£¨?æn?K”-ì>„üh”TR‰_5Ò¬•,·r¸€ÚmH@:ƒ’à(È!œÔÔìl{i5Ÿ y?f`òØ~¸yéÉµÙ¾ƒFsG~¿‰´Ş…¡·L	‹ÿı0~9y¿™eòß2jÚ0…üuòx-Œ7š¸wÍ¤ºŠÿ’Û¾i?Î™¦ôÿÙ¢·¸=RcP¹ŸüáK±„a)ĞjË‹t®³´îÚ'Ro¿u¯ñ©„§®ÚåF×ÒqÓáÜ¬¸å>ÃäÇÑªv¡¼YÙú¿Ú= ]–ƒÅ‹,ƒCÈ¶ç£0$ŸôCÒ´êü*èN;(-Ék)`â;“ÛEe •éÅ'«İB{—S6jU,’é1ó.:îå›Çi‚ıëcqª…A/rÒ“XÊu”c	è*1àÃç”8'ò!¸>Ó</?e4î{Pø2÷DwÇKëúE«ëÜóı×¹n¹–“Í) ¬Ì¶…ÓI»dø(¶&t÷FƒkŸ8À  ‹Æ÷¹(	ªZı¹4öÛÿ…Í©÷Oòƒ,CvQ©çÈu@<©W=£ˆb·œãábìAL,#%ª5öuÌ´ãÏµl%›úxÁ
,SŸf-$DhämÈòù£ÒâOççF jç3^ÿ•$»Í}ƒ¯[‰\7Z½!ÄhD{L­5öÑèÖJˆ0ú|I´S¨êkšö°tŒ-©«ÊT(6»ßAA^îÚ*Ñş)¿XÚpåu–†ü¹ºeªÏÕŞÅñø[FøÜæL*àNÂóÉêS,äÁmò™²:“YÌwO²6W„ycšG@]ˆï(G¦¾x½QÈ¥m—q•4œ>…šÕ
òA¡¥Í8‹B4«—ä~T){È~¢œî{Y—×^Iù=»@šRF3 öÑH¨â*P²] ‘Ôè¸ƒÏ²\¥ïé$œ¡{Ö¨§­C½.  ¢Ş0ÜGO>ëmOÅ«|±4ó¬õë–)½r7ı¤H|‹cö&˜€²¸l÷Øæq‹ĞD|¦Ş·\VÃPß+TvY¶Ü§yÀ­tÌÒú)¯¸mh'%bSÃ™¼*j™_©göäÄu=[ANÕï"|¨Cªáƒbè+¨_×&BÊı8®ã9ŞHîzü!Ì6Çw¹B@O	ìs=œ‹ù{ànerEó1œn<}À”»y1“Åªğ54‚@™p£9q(Aa,-Àï¯bTÄQAš|÷™bMôõx³$’¬Ğ‚ÒLè‚ehŠ(ßO¨p‡“è²åŠeÙÍKñ¨ºY¹°~Ôk~OVÅÎºÛNÉ­K.²»r²®¸àÄTá¥‰eš½„%îRz²‰E…]AÁQu‹Dp‚w_Ô‘aÏ«ßşEzZ¶‹P*~™¬×W/%ëmè?&»½ö²±ëƒ÷{7Ä„ÑÀŸúÜsÃø11
ÙÛClrí%›ç45 N/ÖòV<hŠ·ş«!0,¤$–:·¢ÅpÉw3,Ñ”á®éqg7ß0¥fbYä#tû·R'îRcÇAâ®•âÇx}znÍ¼€äÃä)ì!³¾¿+¡J0—…u00…ç[ÆÍCÖ¢M’;	v´	?Ñõc›Wd›JTÜ°Áø¼=ÁÊ7	ß[ÈÌSã§HÇ!±µÉ 7ÿĞÇû–gÕaŒWX;ÕW÷€İ£›+¼7àIS™æ’ ÙôNÒ…AS†äÛ	’9óùş ¬ZÖ2?Ş&3{¬´—M¼f82aŠ1ò5ç,“0R¶13_å@rÊ²ÏÃ2s¢Úèá¢Yyı™!/¶`[˜Hhõ7U)Êf8»r_3]HZ¨%CÂå4ÓŒy]KYH ™Â1·å
e}–ëUtS­pP"X~8]%v–˜QGö8õö³K:­™î´HxOx}€vèäWKF–àïâì-ÔßÏ9Yµ¸ä#¾MT‹¿ê‘h£›yµ“¾Sæ‘¸`<E…Ò’å‡±‡ğŒ\2ôB=ä¥¬ƒ$ÙEôË?_Jb«”ĞVtÊ§çùşÃ W\­v­ô>4ŞÔ)]…4•×úµ±‹€'^mÃ”+]éòBƒˆIYïÙs¢hK-uwy\1¯Cov{Ÿ¿St7{­AñiÔ ®xrg¶nÜPE8^"•’¡·S[Á:ğ\ÄcÂ¦Ôgï‘®ÒMÕ¼×Ü“åš>1­(£Û8‘8U ›Áism+‹p¡÷€5/Éê›1!LVp’ÜL4G
ˆâQ"oA	ÉùŒ…Bc„w{=¹Ç9ip±,ƒ´`¸¯×Ri¸€£`É¸j¥š›;—/ƒ¯”MóNµ/?Ót_¢ ú¹´î]á´Åídı‰K»ã¾=èƒZOı3Æ®ı”Ô uîÏq>á?œx³õl€üDñö‡µ°å
ZÇb{×ã$µ&ßˆ
|Û­\¦üD˜*{³Z€ô)æŠğ'ÿõÏ§vóCÆ«äé½¿º_:y^ÇĞ¢_äê8?KaÑÄuƒFª
·¬]_ET‘[¢ñ!ñ lÃ©Ïİ`ØäæMwÛh§ûôé?‹İ-[ß@ıF[p0rPïÒöùö;^Ï‘ş’ãj1´‡„	ô^ıÃ®Ç´†·á»Êâ°*p	ãâWÂZ’QU}_øĞ½¿~hİÔ ’ó$š5ëÖa—Ğf4å‰“uï4a3zŞzf]€2 UB‘›g¿—ÊééÉLp¼ - ƒO\r×š^ù÷Şy÷Ww¦_=ŒÏñœhÊ,ªÇjùˆnÏ÷x·#û–—â¥¬]Ü–
dB¾p¼ŸÙ5® {Â­Jïtj|ï²O÷øñÍïŠ	÷C›Š ½Ë‚˜õùåÏk{gáŠ5a«ÿ¾0u÷ªŞ>¿xøÛô]hyš¼}R8Ê^ÈúÁ•0iS÷y¶-âÑ¥u§D+ŒÒ¦zªô)Ó!V“>Ç7¤G9bë8 ånßD‹/°£UL³ê/Å’œìT™9/İ¨$Á¢kZÆWf”{¾GQ¨h€&„°.C©ªÂ_A¦V›ŸãÁuxQ *2ñXmsˆ»ˆ@ø§C)àòa‹›Gb•Lên£…b¶".W¨%€OÆq*ÆÄ¶ÿåƒ(Ò“ 0àá£r¤XfUÆÀØìÒÍŒ>*B¯¤õøÃbğÇ†şI²4†^*^|³s›ê…:F§²b”Ñë8sÖø4€oôÍçw™Ñ÷A'–\—ğ±Jİ;¿Ô|T8 ÄõÖç:ç»!ˆ'Wã(öóG÷¥i®*HUu]‚4ä*IÏ¯Uş’Å¹{ãD1¾¶õüæìÊÒ¬%>[`Á†"3ÇÓoC{fëÔ}ô’/µ @BäGá¸Ğ§-Ê„Œ§­ç×DŞÚ¨€?«ò3ğ_pËÙLË0_J{QƒsŒÄ«EÅš‚×drÀ×úYâ¯¨‚7z_&„æzZĞå¶u^z&Ÿ\0Vd€i@kwöùNwJÔ+ü¼Mzı|‹â£TÜÇšQ‹¾…ü÷¯85xcûa»tcCodL¢³q¨S%ïÂ„şÈH½¯åáÖÚ•7¨Ë®ÅŞÅ¥ú O‘sŒói¸${¾FûWŸº¨ç€hÊñªøGTBqOei·Çƒ¤óİ€ñ9©ßÆd3‚6ßn¦‹ÈN¹çbÊÿ#À©ô6Ün´‹> —,“6^ÓØÍP(e™EÛ]ÖÅåÌıh{	ù-Ûc«»Y^>1”›0©\]¯'6ÖGm}VøL5®„UèÅ®“¯XÂ³0(C‘å8:Ä†Àh¢3ˆ½z…7îgÊQromšáÌ·sÁªlİ§ÜÒ€N“Zjk•¾İ2W¦5‹€…§úÕÖl¹^¹õˆ
5€m
åør‡ñjíëKŸuËÚcŸK1Ëİ¿½I*al)İ ×íbxË{Eƒ3”ìÇ]À·ÖõR|”'¼LŠEÆio<à@F”ÄŸö€^û6«F¢l—‚ÍıƒßŒÅ<ãCúÆÌÆ‡FÍÏ¢’Èà¿Ê »Ô„3tJÕÑƒ
K¿òXl ¤eÿ#ƒÉ<ßn§ââùæKš¹T(ğ?f¤ <mÂsâš¥§ûz×Öô<ÖG†ÇÈç¶gk(oGu±+:.9·¦(Eİ¤Jƒì7„©C’¿KÓi¬HC*&_'Ş$XÅø+[¶oş øÂÀ¨Ö”÷ghnšÜ÷‚73ê´VšV¯ŞhdoŒKo¦{Ø²–5v–¬ˆõÛ+èNgK˜Úø¼~èînßV¡gåò™ÓpzšãÁÖ‘¯aQ˜Û&63Gğ¢jƒÎ¼Èaò€áä•òˆäÙk9 ¤mÎŸá$ëñ6íâêjá¯mhöXhëñß²X~àAÇ—g¨…ÂìZÜê,gÀ;©S÷éäèys"z³dñÓ®ºæÒÖïÜQX?yìcäáTx›jİFé®Knª¯7ïr<\Ü6 al2‘;cB,5¢«Gè#' GÔ"µ;ô¾—ƒ£­ƒ‚[›Âôçõæw¢„ÆE{ê¯88dêÿ×ñC|C-DÀM”A™ –¯[6ó3}Ö]*ÜûxR’`.@'í®i"-˜yG»KÅHıÂÅ6å¼ø	+[6¢Ú*`ñêß@¡ˆd{«»:W¶îÊwQöEh|…Ğã€ÌQUc}»è/µYü„¸°^G]5éô‡ÛLrşkêÊè‘”¼(3(hÊ ŒåM¸[L¿-3LbœZZ«g,´Ş‰1–›Q/•Â!e¡»ú‚‹m>/Ÿ'ã&ìSYÜ§ÊÊĞ>À0¦BäËÒè²Q©D¿ø™¸ÛPNªå„†„ëd,lHú[!Õ~úºPĞCHôİ‘°ÇLUŞ:ò‡,Äád6§—I?S
Å“áZZ·È$¥›ë»ÌdKkº¡8<s"ÏX4Ó·ã‰ˆ<‚éÊ}‹Y”EZ‰Gè€ñô®Ì£VuW…&³“«9Ë|Üi’1KEIhÀ²eé‰õ‰À#ä“ôëYVU…Ç¤C†:%Lüÿ"ºõ€6¾5È%}3àeİšQ(&”dyãgSsË*ÜR0³°U]z@P ^„ıL» »y†$|ã,êZ*vß‚İ6ßÕ­_ÎN;fCò@3:éÑ•ÔĞzmà9;–Ëø–+^BÌÊ-Ù4rT×3Æ3(
§ö?Myñiö=m
‚ óÕk×.‚[4|±KúØjÉû~­O*ÌWÿñI¼ŞØd@öÔ$ÉÓÁ0³â_Ôø–•Ë¢Ù‚Ijj™¹ H¢nçŠ~âÌk°”_ #…ÀOª@K¢wG“¬$n•\a1Ã•E<lò¤ZcÍ˜¦ÏhàÏ€^í—¶O’Á—.­ œœÑàaÒÅ–UÉ§işMÆ»ı‹[1pØ‘VgÃu«GÄu©_äÿ#¯ÅÕ°Ü
(óÉZƒ|`Ã78jZÊñ8ACå÷l-_§ï„Wòš	ıš¾µï¶½Ã=§‡Wk×Âå –,wÌ<[ï=¼7i^kÆ¡(ÙHÑê¾2@Òğ¨$JÛÚGm°½yÒÖe¥:(­ö|8‹¢İt¬òµ‚D€-¥/äwËÄ¹ÌÁÁf«yŞûµ%*“ÿe‚e’‚y®Ï_‘ˆ–ĞÆ’r`í—İ¥Ş\kõi*+X	‘bRæ§³h~rNZ§I!û¬‡“'û3A½U´Å÷¢ÆIîq)ÜÖ(xG¼„”qî”Ö6öª	{‡Ÿ>wõşW”¯†ÁÀ€½¦û+´‚ÊPû$¤³ôœÙ¸(®¥è²˜?íH48,¦R‚}ÇbOp¾à!ĞşÆïÎÜ]PŸˆˆÏ’¨3OR‹!ÄpjTù»~6ÃÏ!ò?¬’@n)%	¼Ìjÿa È¹÷Ùô9U´Ûë¾ó+Õb-Àòo&5ê?hæ'>Oozeº+ç3†Â²¸¦qTRGD˜!r`ìKyÇnéZGkûvÏÉsìa|½öÉ%–Ôjl³ì‡IpŸc¦¦#åÿü¤„ˆ êRü=Ş™Ò¡â²€$cÏ²+‚'h.u‡Èâji´@á“tÂ  ‰>)¯šfç¬¿®°Å¶Dí#ùuPGË¤qÃ…ïu;? sx}*†¾n­:¡¿¥;~†Ù¶Ş»ûÎT¶È³úïÌê¬@¢±F{êÍ—İÅgcÁÁRÊ†y`ò°züj8MPj–ø:‰ËbDıDù/cY\ÒlÚá‰~"ÇÙ/¹Ïr~1ºä×Ÿ‘:ò”@º]W¨ÙXuy¹±
{Hâ:+ù½ÀNLë×1¢N‹ş&•›1µ(ç·™j6;ô“o®†Áµ`’¤à++m°gÄxú«ã‹ûªëìí“1ÖJ¿ßf:•>
­ò(ÆZx¸Ïı½P—q³µ
-|G1Â\¢‡À:e–šFÿT}
#86¼uÛo§rÄÿ¦i+³ScÍ©ö¥Ÿ:±ïLhD41™uß{[pËâŞ§a‘”ŠJ·+FºƒØÃdÇí_vÚÃpû¦._tğ.ÕP\¤è!uKÂ#k)ŒšN{Ò£•Ş}&¬õıµ8ö’ØL/D
;*Gö™ægŞömQİ„{‚}t•6¦kõL×! Œôtx›ñÙìYfaò¡ªä ¢"iqui3@jwyüjã•Ôø¶Ïu·ÂØ?€mö¨E¸tŸ‘øAË†0ç#?_7•é¤#4çˆáF/{À^À!Hî'fGÑ!À¦•‡h–‚E¬ô‘PÈ¶üD­-ûÉ‰şõº}¶â`	x¥ê‘œ 1ğ0â½ÜıD`zmÊaÃ-uÈPã¸H>Æòš³K§Tb T$ò×Z2U­&¦ìÓ†{Ûæ¯ëíÖÊßÁÛ›6ŠèöŠ3ñb\gHƒ†ÉJØá<†=d¶î‰NìøÒ÷§~ä‰j.vËQ`VoÁ ¿4ßs³Y±j„×_Õ‚{c#Ë©SíR¿@?®t&óÈEæ¡Á¢é0V°…NïQgBÃµÍWrÊİÜŒ4»$H|j>¾SÆÿ$}h0¼½@0Êº1ß˜Á«6ÛúÚç#âÉLØ>i“aÍ8ß“şî\²Ñ£B_ÔmÑûåÒåo¥8á6¶ÍPÉ]?ílêjøç²½+šŠ×nÕ~1czÚb-%.PšEcÊ Y~æÓd½ì³Ü›J²P©šrŸZvÉp®[v#ñœdÏÆ*X2I†İ—/âÜL™à"
“²oV“ÔUpUÂ©‹:³,s¦“·S½ñ"ıçfJqú‡îV(ƒ"øfYN?cÚËÁ"•VY$o¯5¦J¾úJs˜ƒ¬]n€ºµl%EÄ…2Sû*ªŠ°%Ÿ|;¡3¸Üb%,åÆ4Ñb(ÏRAØH|X8@{ĞsÔ>åzÚ–ÂÌhÖğ^öO³Óã\­á²C>^Å(7bÿñÛ«ÓÖïÛ·û*Îõ¿­'¢Í¾£Qcè2D›¦x-OSæ«ö‚×::ıoIpkÌ=¥ŠŸøãÑì—V3¥+5G,P@­7‰_CãÎ.…ÿw\¸Èm§_™åîk‹Å­3@ @Ùê&¦ñjŸ~%¨É@»¿ı¹…;/­ô•Ê9™’@—EâÃ»ÈvŒyç–E´7(F—)[¤Ø‰±ğO	Ì(d-ïhA¯Å¨k2“Fª­«Ùjê7½ÃU3ˆ­İµV0ÏĞ —ğ~j½güJ›<ıZW¤Û1²h´î5ï ¸=m¯ŠÍ/(À)ù±±›ŸÈŒfÇ	†ãõrê
>@•VÖÅt[Ô»¤Œí'O§Ìnw%+«-Vœ†)@2ı¨å“Gÿ uäôr™
Z¾K)kã\sšĞ!"şå¤¨¡—ş{ûU}ÀÏƒÖ9 óµ]+hÔt€èg×Ó×¨‚ü;UA_lä‘¦-ÄJğ‘;ı9J¯½nÇAë‚?.w¹AÑÄ	İ	^"ü»ã†÷ô‰Å:ÂM¾{ãÇm(à¼{(øêYº•Me™ü¥'ú» }Øí<zêKr ¿‘B49ÍÁô ÏÕ}ã†U[7±=J^XdZ2kÏ’ûşbÚi ²•{Ä“ûâŸ±™™ëLÃ.k9Ø´p±"Š¸Õo7Z[ñ6G>ŒvÓôücÍÁYİ©´!—ê•u=Ã'×”×In6iƒ²´$iã²ğ=l!sD@ÇJ²xO”“fæ­ü%£Z8»ÜJ¥Ü”bä¥Ö/rYk ŒÎÏ¤TÔ!Jûœ]çıO˜¦X¡/E‚Xî
|§²Ux¬+P82Äì:„°~+)1˜®¹”ªñºÆT¯@&˜ÙpŒwTX-ß,¨&ü&Á;œ3ÅÌë±TyYfh¦ÆO¯ºËR‚ëì…ç_ˆÜAA0%Æ¢ËÃëeÉ’œMuP¨¹2³¢IL)Ú×O©–+”m0à±Ê¥­£O|Àıã¶¦ˆ²c… 0ø¶hŠ)İÓg7ìE/=0ú¶Ş÷Vûú-é©Z}}6–s_BûÂÒÿ6—+ÎÜ<èGH¿ö»]‘»tX“Á-Ş‡n†û$<;½ÛÁÊkXã"E%t2w’Y€S"î*`²Ş} ØÌß8ËR-²Ú™mdâ˜hme"±SÕíäSc	SL·Šnöœşâ¸D¹±›„¶
 Ix.1ãä‰1å×Â¶g—¢àDÂ”è8›ÈVhÿÈîòS“àŒ«Û—ºçTÚşF"’±ÿ[™J©[kµ›¼,f0­àáv-‰†(@ßÁ6÷P­“®7eÒnÂR"æGsÒn=ÅÚOr•üªàPbuğ£A†Tx®3&¥ÒN¨«Ø§`
Xó¬ŒY¼¯—Ì˜ŠWzåâ_û’¨èİH	f1v¶ò? MB¥Hp5Ò¨üíoŠb*Êó–N#ÔªË‘İhb˜¸ ]YË	Ï-3=á="?Ü8Gá[l±]ËVRP’î³øàè*CX‰o!ŠŸ{q%5ß
í¤cTÙ\ĞÆæ±‹{’§6RŸ@ıäÇöŒNş˜o­qk½‚:ZQÏÄ®2­•ä5}|—"Y#Ø’jû“°O¶KÏ¥_Í‹T&ÖtF©šy@Vë‡ÿÕâ65úõøÖí\Wµ2<„!Y†Ã@.Õy±Uç^,¨[C‡×Ik°»abD6¡\ŒÖŠ	d}ªP¤h#»;„Ç™ğ$Vï`¯J³(şS'9K{0‰¹á0§W&18Ş	u{}‰¼Œ L¢º­ŞÓ“Â |”šşf¬Ç®3å`$Öè3”Ïƒ´úIÙQ©z4‡Y6ºvd1£­üs·'¬?tU›Öé+šHš’á^‡¸`ùÙŒÛBşÊÖSR¾Ÿ8† µ!2‘õÊ7†lïJíBâãŒ¨”Ã 9‡GêlàªÁÔâoÁXâ.	‘©ÅÅáwÜ8ËFŒyé;’÷tOÛTëV©²z§â
ùüi A[^á·ÛäRnÓkW¢
–MäM8oÉËeä®§7K"ˆî–Ï™nz›àe‚aÜÌ¨„ˆw[.{.­…híXRÿÖ½OfWb^fP:5+¯ÿüÅ{î’èÖDÇùæ•·„Êéi!u~ÁvsyÆ+/Ì_p°ô—µÌlg~MÜQY¤¾
ÍB>Éi‰|¸×ìAùï)´k)Vu_¼7!üüŞ©’Ä©Bèÿ¨uû*ô,ƒğòVo¢j5Zi°;%§^Ä&$¾À1&•pgSFÿÛÄoÇ½é•P&ø’óx°kH“—„Ş;Íçï¡ûh¡‹Ë°„ŞsJ(ÑÙU´¼29Tz}‚ *¢3¿P!üÉm)ôµÂqÀ@A`RwÁ^–L€í¶|ÅñádíÌ0p5íã„ªm¬6eåtØğX6ÌÙŠ
?Å£!-Ò³BÕoµE“8½¨@!uµn6#¼5¦†y-¶N±* ¡JÆÕÿ÷&&1Ô•ï”¥R0|'>¤ËÎÕ}ÚŸ¥è’®qu&0übvø!3ğİmIÿ&SÃ=Ì©²º¯j€g(.v°"*÷–Æ
jŠ"©ˆ@ŸfÜà#>eG%iƒ&ÔçG.£vLÏztüw’ráo÷HQ‘7ØZ*cŠ(S‰_Ì;ÕvI€Õë¢Ÿ€Ñ€91ø•L¢ØÍ[	î:º)í[§B«mĞG2˜Ş*v•i+Æ_CÀ"8XÊ|@+¥´şÿéÖŸy‚Ô#ëMÇV¼=ãOªêñ‰S$›tNê„Bqr¬°n’Ã;Ê#!’!5¿³ùÃpY¥NşÌ*Ğğ²˜Áûï”=±zñ4GTukzªİgÒ^@Ô¢ú!'ÚQ!9VıNŞx”D•„k„faøîP)¦ÔäÅÁ] ¿4BÏë%¢™v‚Le1ë¹W[F,rüòù*N¦9èUÄõ’<ÖuÃeSßİ,À3^Ü½­Í™Ôî_Èõé·1ds>Ğ«§@‘¢öò¡'Â;z0l¿æmt"¡5ào“›®vmç—?˜Sßj”ï¾Â[µË˜;"ozFWÀŞ†S­èC>©—|.·{”6ı¡’ó§µˆédLfÕãÊ$ªó0Å,ñğ¶2…e±Ç)ù÷Êıay5ôQøv¥²ˆÿ†¦NA›ÀELk‚…4qxLªš/˜|MİÌÜMr}ŒZ¶¶’jàëÖEóPâjuï.Ç›œ
‘Gs§y¼AÑIu©Jo|Å jæ À¬Ÿc€KâœŸ‹sÊ¤‹¸°5–“¼­ß0W.›5[+Tæº,nšzÖNû8<ğëÒWCüÏ@›_¦İ·Êó¡HwM{«=£`rmûğ®FN<L7tYLA¤ÂWM´—m¢²28ÚcÍãımOVïç:;‚ñ"·o5NÏAï`é¸m‚+³G8@rsüDà&sÇî¬…¤ÊãŒÀÏ–’^±"0¯'Öà&,¹TóvÉ[ú×Ò§sÅİ ã+/‘\f[ã•çˆ
?E=ƒ“Œ{™ÎiÿhÒ¼˜xò>Q×Ñå;.3Ü¶ÓŠªlÒj›6¢G¤øê¬™ÌjB¡íoí5=õç¯µÊPâ~`Õ-Ç
¶q1©Ÿ&ÁÜŞã\şÃö"Æ6=Ä±È¥ûe æ(Òs§¡íúü‡ÚŸ+y%_åNPFyzÓvöZ,hÎ‚Ù‚cÓÊ’’÷ùOq"~B‰+XŸƒg
=„Ô°ÀNä¬­Ò–ÿİvmÎh¶Ÿ0ĞX^ƒ"ºËé´sÏ‹‰Kz?¡RÌ¯şë–a¡I»çæ©V°Cøşô¤÷ìë÷ÁmPâû]bèŸUø$1·ÈÅº¢/eÁdíË˜¶GÖPºrc‚Äù;‹z™æ©ì³çÄ·½`ö‰—Äºòö›ø	å1ÀQ=-8»êª%”ó3Òn Meç¡pÊÑ>ñ{\Û„4ä¬Ùç‹pm«î®¨â£Î®„U2QaG£^]0#¾,’–·7/zN &jJ_h’W¥z»í;0‚OãÀi¨Ã Ú/u +lâMï3ÅIíµ&¯B¶´ØN¨#<tT·“Â7@1~¯ò¸‡a*ğ×”Şmöï}ò÷Ş!Ë²¦:×6şêX{æ	TŸ/	öfÉé×UQŠŞy´3*2·–î²†Ş¨´?×/æÃô3Õ$¬™¸Ó-2dÄ)Îø³4Ğ´˜òĞÕ¢]3Yˆ¯¹;fç”kŸ•êœ:Æ¹hZ =·}ƒX±&} ÊÿM2hÈ‡ŸööSKLcrÀÇı.šŞñ[E™_oJÇvŠ¡B-¥µne³}ÃÍ8ÚKŞr»âwÄ­tgy·V>qovéXaòBÍ¹œ1üR
ˆ<–Gúëh§ë¿r¥b¸•3Éò-ZpoÈ¿§˜ÑE-_
µb2%—-s
£~"›t÷Gr˜ˆ¼³Íä!{\4(‚gV3ÉNÑ#½Úì‡ì6ÊÊàı¨… }¶xüÀ7 \¸"k­¶[Ã'!·kÈ¼ònß'àq±ZåŒÇ¹NÁ°é¹6rªWGªfÂ}‡ı¤v%ÙQ÷˜“~v½ÌÄ‘GÖf5löZôU’Ï’æêÍ¤Î`´İ`Í-øE‚Œ|-¬¨¤i?ˆ¤¢¯{‡cÏæ®@Má!İı˜.¢¸ æ_•ynÎäC–í<1è>îõ\9Ëó¨`yÒ«ˆÉD%·¢ÿl²<D2ÇIòˆ×õ”Åƒ%˜>¹NæÛ¸Ù të®¶µıáäª)I¦?7Š<é <íñçê
İ^}H÷~å?ÿ½éf‹¸>Õ÷%!Ô+B¡mNziQZ{st¹îºÅUa¾–Ğ,*à¡`h@+j¦MË¶ßtûd?¸™Æ{NxtRı_?sKWZ<õ°ëpJìŒØŠB“~_–2(qŸ:¼SÚí¥“ed{EzBUüDÃÑJ….è›ë”“n]æ$6êñØ—bÂ(i£§pnwI‡^EîÖ¸V‚“V—él¢sãTŸId#’'³Í›²ÿÕªÁr¼¿ßUÿ§ë±‹Év·E=Ü)€ÜÀ#şšT‰ä…š	ˆ@AÛ¡W1`œ‹/Ô¢Î‰pH•†¶mU¢ÎbciXÄ¯M ÔTÃ§ogİ7Mì¡#AgY 'üéÉ‡%:*Œ'¥&âQûÊ¨m;àƒy> õ„Ú‹õF9©^é>‡€†c¹—qé+ë)Êø1j;¿³%Õ0q¿şHa,ó5|'Êw;¹%2<3´nTºë¡Tƒ#/ÿ#¡‘Z€›tfmÊù®æå%vÛIË;ÓK_l+„‰^Z À<O;vgrÆ––l("š@Ğ¼ª„Š	?oˆ¬äiÒ£Šë$˜÷¤Ñq9X{ÖJÄ²İÄ“Ë}j¬é¼=&U ‹²j›üFï6ÑìVºø’TtbÒÒb¾#}¦~-E¥¿tÀ…Ÿªó-Yv|ØüR¤áş ‰à¢\Ç+£ÈÀGg©Íİè†nÚJ‰{„‘OĞV*&wz‡ßÇÏ.Üd¶ãŒ¨ñtÃÚ¨Û­3_yd€°2çY0O­¨l€ÏâlI?8¦÷J®™8º‘ ”;DNÌ²òà._4¡º[Ç}(÷[¸¹•Ü[Ğ•¨˜¾¶™ğ¢–T¡qx4n— 8¢ç{V&ë.`,ñ­Oœ¦\k¿tØRß>»,UÿÄô÷¼ÓušÁaÙ^)³Ã/ò‚pËÆ>Ñ¢¥][S4{Krwq[U†u!™ÿ—‰Õg: *tw)ë1e a¹ñLS/ƒûÑ
ùÈàJ¶pÔš«sIÍWY±/d{~«µtk*ı@˜çµÚßD›/6ÿBî@Ipg=›Ú4Ls9–’Êë(cou7ïˆH^§¹CĞ~Ñg¼‚lEµÎ%ğ`ÿn¹Ö'Lõ–Ğ
'°—S±MxúF}FŞşY¯\Î/Ò[Á:×+³>™fİ•Œèš…Ywo_+¾Å³9¥èêFNNtšãğÕàIìè?½\ÀÉå:hK¥|ûtƒ¬åW†ä -v˜}!÷
d¼³Şf€˜„Qòºâ™ ZËÃÔ
}ŒØœ&•Êxë5Â§fË¥V“…jÌv2?U»s»Eû«@2¡G[á÷uïGç'¥è0—Ô:#æ%l·?’©¾œw	U!»ü—+o3AB–¨\Ñ¢G¾jÚÚñRã'J•$¥7ñå|Ç;”³pÏÅWBêÜ<Úšš¨a 0É ç‚È7ù)§M DìLC¼:”íåÇÛ¶åOüvoØ]Gù.ßRõßÊêªJ·+K€À‹Lh¬3‘èB5w˜p™
ÆÛ
®ıçDÄ~ÿfiaá°qÜm·„A¦çt=İÕ²šÀ¢<Ù‚ı´(kÓ%ô&¤Ÿ…w@§á•­´™µÊåŸ[ßÌŒ†TIÎni)Ùœc¥şFWÌĞ­¤ñI 6@ài,.9&;äEmî@ÈPZGÓ–~åt@¦O<»¸œ2`ô7-¥HZõƒ…¡%µÖ…àƒ%!5]‘íEù…èÂ%gèø &­]ØEU¯|S‘¾7·Â{ê/]‹ÜÃù¾aÕË—CM©A#ÉÃ9.wV‚ß6ã[¬d‚ÆÓd¸dÒuëëö'ôxÅi#ŸWØ7º+!J×U1æ×äB*šÓÙ¡T`®œXTÃ¼Ui7‘Ğe€ï aÚw_Š½|ÒÆûÂ fMfõ=S©PÁp“54†1`zv:K×Î…›d€{
_çƒG¸TŸ{>n@9gÎçmİ-¯u[0¨d§Ü˜NÂû@¥N£/Ì
v[ÄØ”\'øtú€=,(j0#ïg ¦PO,-hûéO±Ìõ<ÿÑ¼ÚÒ¢•rhÌ$Ó\0ª¬!£î‚®Ö§9y¹„Šç!Âàíä½[*àùÂßÌU`ßú‹ïúu29Æhîñı×¦`º\Ë’®ËZ³Ç¤Äp«ï˜HÍt›TëGÊôâEÀªQcìÓÓèÄÿĞ!’-†P½ äÀ‰£!'®*üÒ˜¤÷lÁ!•W#Zq¾–ëf€\uúØRñÍ½¤½ú®+*nÓTq^M@aˆ(½Ø—óŒ¸•m@—ÛìH>Şg¶‰9è¸µb·:ÿßg'TbsU•î¦]ƒÅıŸ¥]âÇJAäU7bèô³§£mV°öÄ3‰µ?™]QH6ë
©{V…è)ÕÔ¨^H>õ-›nã.ÈO	iºö	Âr•~.÷,€%×K3#¬;«Ò•:˜È ôı¯×:JÆgbLïÉ€eÉÖ¥‰Ì›l³áY#HvlİõNpWÚF»7bfH“pÇÏĞ_ß(È€êC$ÕĞ~šCŒkVÍ“ü,šèÙ1ÖŒòú#³u¤ïhˆÂ1?„ô‰_µ˜
Ÿ9¶–¤İùIZ…õ–ºiÜçÂ0ğ1ãîQ™ŸOÇ¼$A2]ïo¹æv¯5wèBîèÃÒuvÚÃUº¥.í4“ø‘‘L¥2Q ïä¨ê—°óoÍÑV¸ø‚³GH¦ ¨|é¬ŸÃ2ñ^£7e¤\,3•j‹š¯Ág.ƒÊ})Ü3K©ô·h`­§’Ê —A»€›Uı"Ú‰¥HS¹foÃî‚ÜŞJFf¦çé»eJ·êë&?BhYÃ‘†Ğï¼‘6;üÊ¿»¼dç®}å^ªY¯-Ó.ÉËIh®ñ‘Ö­³×‚4R¦Ë—ºuğIS¬[¸‚:³'Ôåje·#>şœ
fÌ¾Ş¤Œ¢º_—NÁ$öÓ i¢Ó¤_‚İXQûchP Ê%ˆ³ÙÛÅb#2Š‰éï†)+^ÙÊdÄåŠ“Š(<ìMêÀË;FW
ÓH ¾ÿRÎ˜cÎmkQ Z£î9O6ş+ËÍ½#/È©Î€!+ ó™1¦ÕŸkÀk©h‚Ïés•½f8	ª ‹õ@	
&ãá}¤æÉ\¸kÃìWôdßj›Õ‹à]x§W>«İs_nê'WÖ}ñ‹rï	¿è)ä€²H¸ËÉRÿ>–ë´EŒê_6²h&$ĞÅPË˜{ÃlºuoDIŞDuXıUŠ.‘‚OÕ„C±MªH°G†Xô³›ÅS6?áŸ’q°oA†ã     +'È¬“$eş Í²€ÀË¼3±Ägû    YZ