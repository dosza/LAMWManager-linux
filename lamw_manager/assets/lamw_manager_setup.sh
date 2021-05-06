#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3025759550"
MD5="11d8b6d719a50dbb06fe7c175b201ea1"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21164"
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
	echo Date of packaging: Thu May  6 20:40:49 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿRk] ¼}•À1Dd]‡Á›PætİDñl<Ç–µƒp‹ãĞ
fÔPzÂÑ‰ÓV½Š&ÇP._¬¤`°Ñ_©:©§b¶’N÷òæuDx›Á¢Š¡ †ò£qåI©¡¤*òü2…÷¦	©üD±%ÔÑ.Ã2“†ºVË‹\-Mƒ¯à–%ñˆÚöÔÓƒ¿V‡Z3qü¤¬GT]]2÷a¨k¯ğCg6™£c“1>Çİ¨¼ˆ– ÷å"8&KQÛn bˆ€ø¾ÍŠÁÍ)XˆW\{$3ÕÅRø® ‚PÌ³?<-‰·“,nöÙ2õ–|¶5<æÁwX+ĞçÍJ
l~e+G]V^nÏ¥âY‚ 7=	kÕ¦»ÊwCM#êêIÿë ¢¢KÑ°àÎ¾F#cp
Ç_Úqì± DGz'ûÎL %’ª'µËnM.ÒO¯/ÂøSÏhb‘·I²&Pú.DÒí¾ÍHÒ>(°d,V2F 8C–ï±MÂ¹äE;Ïk÷K=ı†*ø+/.Å—b´=‘|ÑüçÄÑäE½ã3°çEE©9r”éÚ;¼ıä\CUƒùÑ¦Ù¾”*>Š.[Ø®6İ5·P_şæ›,«,…f­İ´´¨¾­­nÎ#‚x¦¿<¼X=ÒS€Q• +,àépêëæ\í€"Ò‘ÇLg7"ªõÈG¸"wÎ˜!}EÖ>ÊÁB–‹”,6ô
§b›SI¸¯… ½ll¯³˜gåM,1‡{èRp<±%“ˆ®ç×W­tÜ›§¼ûU0uï­@*‰©/kÔú(0z}¥¿	‚Æn¼*p¯‡¥…úÍ*F%¢ôf*¡k‰˜°ã°™ÆŒ†àAlÏ/´Yş|ĞÅ…¡–ZbÄMT+t­
rdd¯ªIĞîc|º‰sMõ€ÇmI!ª—Br]8€ÁeFy ë_u„;åA¸Ô)ëîå…k?©+Ÿë¶¦˜fXìª`p2OF#ÄíÑ±«¯¢œãÙ·èõ#w©S
ÇC¼c8dú‹R•J>V2fµ¿51âmyÂR†”{ÄÆ–„µ¡æmÙÃI^É
ºòĞh œ0 ş AzÏ±üÖ°­ÜóaÉËlúP İ¨!X›e Ç:”§XŠ…-Û¿gõoŞå«~ĞŞ³µSÍ±8Ë¿Oª'á»ærCÍ`òM*È53B1ôTT°W§4{
Ğ¼„Y3)]çqn”3å ¶j'Ë0Õ6YÀS™‰ÎSúûv>–e)^‚ŒÆØÍ?dfÍ«?çc/Ü1@áîê*öåÖœ@ğıJç±ÆàÛ†?6xwS¶ü‚ŠÈïŠc{›h×”Á/~J6ÿpºÚ
8¨wé9Êè2ä?SÛVıöF#	.«Bö¾ì (æQ­JØbpŸB¤J\iÇ¹äÏ$*26å·üd°òğ+Ş£zôøôÃØ"Y¤1Ğ//BÃÖYÉüx¹ñ+G­—!Õ¢G,Aıh@åàëY)R+ïCø‹®~HoR‰!,PáÁˆ”¦m“n.™sıØkóˆM9š™-.gL›²Ş¢Hş’QKŠÛw<m}ùÙ÷ Úv 03ärÂö«Çİ7>k¥@‡%œ8!^´F»Õ‰5É%Ö¶ıDuS*±.·ÿød|Qõ¥êh¹kÏEµ-!¸ôÖğ‰ƒ‡:drôıç¦\ø0¯×ªjcy¢ˆÌîı¤Sa¢uVı`4+,• -•§‹ mš!»«¹‹Ì9gÂ­0àŒ&ºÔıÛèşW%õ dÉ„¯¨ò¿ƒy+Õè^åÆt‡Æ ‡ÔVVnÆ1.ïNÎ¬Rxª9#ş¶ÖQìL9´Óûš ½/_;®F*#³I±é•M1ÕàÌXFëb‡âÜ÷ãKr{:¹D{Å$Áç¡ê9ô'oM»Ú,X§¶ı­üy$+|†J½å‚‡´Çšs‡Mğ_p)_6ÉÈéBíÙ‚`vÓ¯ÓŒEÚg}«•ç`tOÆØP–Ç¦W7•¤K¦}ğ'-µlêŞìv‡ğÁqi˜/èÕõµxC*V´ÜŒ¢m™&0ş	I«[fmü5½ı‘a(C'|Œî‚ZÛ‹|s^;f¼ó3­ÿI¡V"	ß^\:ìPv‡In>¹¸ª<¥Ì¾3*<	ÚN%¨âGĞIèrò½Ä7-¿~äÌBà’ojËã—Ü$·w$@®-Ö7—ßwÌ·×íX¡}Ù…¿ş§¹›A>ÙÒ2p¢°6şY‘çéúBuêc5"[„ãÍ7dğÏà1«ÑmGµå#Æ· utÎHAä‡ióõÜ¨¬]ÌÅx­KÉ«Ÿ••ã“æ[ğ3z×	
*øSv1u=İ-½?Ãü÷µ¼7Ş’¶öÉÅ×üá–ğ©ãø<µ)é¼°ÀëÜ«jú?&c±eb¾¯áÈ¸;«ÍˆßZí6â(W®d·Á¨uzj|6YÑ*.RBYxš@ ö­‚j§$t}”xíÏ-İ_¦”K@„Nî/Q¢qÖ&Ï@Ğ'·sùâ¹Æ~zmåö`díÑ”Ö˜‘£«^
~IĞ
¢Ë•m½‡@;ÌÓ;û3ZÄÛmì˜)Bà²9aA‰Ìáê9¬Kur‹w¡š'aÈ?}
ß¢EÓÅ3\[›¡ŸãÃÈz4v‘¬~zuâ'oÂ_—~³rx	5¢U·‹VH× ËÔ¾˜£ ;5*£kÁ6:yK^ñ~ë.=ß´j¢H.,Ÿâº2®@<q¶›ÁM"FÓ8[“‚zì§CºçîÚ.cŒÏDœÉ€2b«¾ÃIº®Dã´_SÜ(S¸üWŒèaKó —:ìÉrG.6(³SLg­|â§·ÉÜe:ãí$õºÉL†//½WÜüè>ãP¿Å]Ò5–¡~ZöïÍXr(Ê ÊŞ{bNP«`DEíçV’¶mwİ&ó YK'€a/‘É7¢0D¶Şú”â9gÃ‡¶PÑ‘’&(ÌÊ@Í<“è±Ÿ–—6r>nşé
v9„ñvrÂt{F>ì7bßì×—ßåÀ«Ó‹L›hl°î·Ğõ†›‘Ó(‰rHğù>äoWòPÕf±¥< îÖdûlJág•cìOÛ‚sıÕ“Mã&~Ö
<‹cEŒŠY!^²Ôø0ü¡û”çÿÈ"To ©Ã®¥½¹`¢i/ÇÚéĞ/1Qh'ëò°ÆUe‘½Ñ1 îbv=ÜıHŠ&BÑM¡ù§…4Ã*\FÒ_‹Us	7:©F´'UÛ6Ü‚%ã¨š+¢¾Cˆ›I†¹©ØjõqÌeüßª¡© Õİ`åGöÏğ³bE İ3Aâå$‘Å~Š-Y»…]°FÊÃğGˆLN”†¡	8	rºœsÍ(^¶cz;,D±¥wJ_<¦¾™á:RsIâ©ªf]lä@ñZ¤o61ÚC½yŞæCa˜AX•¿ÜD¨'4ôûN„é¯¢¤Í¼=iæˆé˜o‚ë¡øP»ŒUğÚ‹ÀMìï1[NhÅŞaLKŸU=‰l|2d‰gJµŞ–Yhé ÿàªD~k´	ßp8Ñ,Ğì:ö’ÔÆÿUGHC´Z†">ÓÆ ª ŞJì<uã±†‰Ü¤Îâg¥Ü6ÕãŞ°	şN‰2µ3~§àÌR¨Æşdo¯·:‰Æh­³vÂ—Y`‚‹€¶ÛGLY~Së‰†ÔùÃ÷²AµC·C[şì’—È³Ú”s[ír*u‚s¼¶Õ;ÅĞ#ÙËaQÀGlrYÚˆ0••Ç‡©
¹¢«}­»ÖıkyrªLs»I›ö:VF'WÖÖ„ä¡dĞÆ€`ªÅšvÚŞ² ¦öš%œ,¡èŞF®aÍÌOJš=”B‘~Õ¨.öÌ¸ËÀÊ˜‚Ö8deÂCO»*fÎµ!sùdDq$:Ê@~‡ğ¹kW?˜-Ÿkwä¼îš¯å+Wò#e³æˆu_Pš4,
M’rgìKÄèK0mÅr·,e–ƒNO)ê©z’«2ÍEpmŸa:U‹„ŸFÖ”ÙY14LF’ª‚pËİŞ¼<Æüş|º+KSÎ(3«û÷zœƒÖ·IdÀ‚yŒÄ-‚‰èä`Jv‡5	–M,ÆFEExÌ¡ø/¡f‚LnP9v’oÃş;Äú);KÎ^Ã5×›‘†]Ãú^#úû×ãŒÀêt*ìPs‚8ol´	ÂÇºn†›*ø@8¿ªÅçı4óóİ›Áğ­œ†ØÚš¢>ÑüáYe~ÿqªwOÈ5nĞ¢/ÄÃ ^ìÏpÌéàÇÜë®Å3nïĞÏëèû=éŒ³¢òÁ 2¯î!sìë*Ê ¾V{dWÈ:iß%ÕéõÈĞT¾:zÙí~]lÆ?ƒ-cwäôœÉ|3÷eÿ^J™êV­![c_‚ãß•ókd­}ùlU¬C›[‡lÉğØ…êşò×r_÷œ‚Waûû•û…¹oÅM|vªl6"œ^`Y£ñØA¼¥ŸObk¨ÓB®ç	 UÚyX‚»¯² ’Á•SMáÄÊ4g;["ôƒÂ˜¥	5LO"şcİŸ½×°ÜkÉ]g“”Ù<ÆqhRcÂ™ş¿…Ã£“ÌYÅ#D6e‹&”%GÓìüÕ¶&“,»©m=_é[ZQ
(·Ï`7ÛGŞO (Ì‘¶®‰¤¦Z•Ñ	šâš”³¶-²nqês#OÃ¾CŠb©äDQ!Ív$‡
fz¥ôj¦Ù¶®°ä§ï(r´¸4ÎøOæ™å’…Ÿ–$ğš1OUŠRš®XËn3ñ_0’úıiŞ	ªÀ9“DMŞ¿å}ì¬©ÇË3EÔN^±¾ÕÎUå}z»¢Îˆìã4õ7§ÜYÖ†Ò¯{’Æ“Ì¸°ÔâãAŸšNW“­jAëÉHÉãÇe¯{4€Š]ÀjOºœÚ»ê¸ê°QîNïÎŒ!x÷ÿúûl‚7”>Nµµõdn"}`F¥œ/HÕ)¾‰STìİs§ºˆà§¼q	×Ø80”ßæÿ4«M"¿ë.?­àn5×N‚‡V¤–S6·G,)íáø¸-…vİØ¡_”¯Âv®G†_aoÂıÍ©“Ùæ 1<ÙûÃÍ-¶~ÃË,/Zªó®9û£CâˆĞ%6©ğCÂ|(|C^×wèA‹"™°´’ÖÍ¥|7ÿÓ¿)nñÍ`Ñ½á/áıüZá "èÅ\îlY†í©½ÍÌÕ¥¯ù¨;§“{|·ˆòızÑ ½&ôå…q¿æMóû?'¿«@İ¯³ÀOˆ¢•A¹/‹#°•*‡í,˜uÖU¬¾Q–ıñNS?7PõR­s(kÊ5„	¥¯ªQˆ6ón6â1j>­Q²!«MDÕL¤HÒ¾ƒ ØS‘‰<›&éÓŞ©)Ò%ƒ§ÌWÙ£nÖàGcše÷0¶Hã&CîÚ¦İJpÏ¡oÂÌYí+„t…âqWÈ„ó„ºÆàNtÿ¿ÅÙ0yFÈg~[‚qneÙÑ§;ÛÌ…ò¨í@Ib6ßŸ¥Yˆd¿’ƒRÊLÀ2Õ$ß›¼j=,è/û`‡ˆbnÀK¯lˆ€X„Öß¢+÷¶Ağj^Ö”…$ÅË4AÙöëNßËM±7'²Ó^t†ÌMì0ÏõÑ­^.	Hµx$ËLOfš“Š,ÇÃ@ztÂÉS~®L®Ê¨™Hd–öíiÈ/š†”í~=Ô"ç¢>äíÁrÃOûâ¿os3ïª¿¬yÄÿ ˜‚ævßc¼rj*T;i±ØY æPP®ÂEö_WÈ»äéı®c$,ZqHxWà˜ÑK|af/œÄæÍ=ïni—øÇâÑ=¶´ï©ïmÌd¡\hÈó.NºÄe2ÂmÆs°Z2M?ïL‚Åzë¥Ê¤Ò¾}PşIr4oÔ_¯áĞ ş“³ï¡cªM1”‹nF_îf½dT¬éœ»ê¦ŠUªB¯"˜õ•¬Ã6‚ˆÜ­QhÔálÖFšm…»ßü2Ñ3èxÆ£ƒ5.h¡Ñ¹}cÇÀ_^h¼ÿ.Òpƒ»œÉT79$m«ægvJº£¦¥."Æ@FÛ]Œí­”{¤‡ûÓYfg3t~@K^õ…¥SušÁ†À 0P)£p~×2º©Ş'"P–RìQ*“È™·yĞÁêšJ‰Ósï:eŸğ”Ş[#qñ<¯¬ŠÙ&ÕÙŠ6Jr®$Ö˜.É=šW„I6SôäF‰bãÄâet
¢”¹­OqI*÷UAÙúş dïæn "£¼‹©7$HšzuGVE«”úçÕ”–ÿ1¸2:vò­ÙÒÂ”Eh::ˆ	@wî•nJG!¼Ié0ŸÈì}OLÆyã1¬[Y‡TFÀÂ$:{è±ÊM¸ëû^xs¹ø¬KUĞA1ÛJ“iˆŞj‘ˆ#¤`xó}@#áá¼SÍ8çlÔ¾ü‰^g­Q‘%#›kR¤sÇ{® 5ËÃ×…¨Aî™^¤Rùá)ùİ,­-tıróE³x-•Íº$®ÓHéGní+¸,“öhW
çnQ¦ºÉ(8<åRMÆ¼Ä'É	É‹İ´Ñ<ôï2…0OÎí­u÷¸Õ¨©»ƒÀ> „ÊøŒ(³ÃCÿ;%`çiçy ­Åôc·µá‘~œè“cÇƒì+û„Q^†õvxğĞ¢Ú‚)·’¤0ß¦ŞQáo»Å‹Ğ7‘Hù€ä¦…–*ï}'‰<! Ö`ÿilzÙGS¡¼]}:Nê¸îÕœ(µ#2·È^>İŞëªô+mäúœUÜè(
¯èÉÏÕåâFÇçÁp1 I™¡m«kƒ— 3ºxÿ­ˆS®€§µ%|ë¤ÍiØé‚w¶àJLmNÛ İÆBdŞ%¬Wé8‚²EëBdºghuz}§ë<ÅXvióó·ÈÈÅ¸]zJúmw ·”AÆ%L±HÁÖ«Oà¸AGé¤/€g€Æ¶¯NüN‹méAQU;êşIÂ“KîRìz‚ù¯‹Ïû’V?™ªhCXÂó#7fbï?Ã‡ Oc“Y;öE6<-ÁNád‡Ål¦0’>]wMç¸]¤zt4¹ éKi¯fŸó>8/·Œ–Tl*şB‘®+6Êâr³RJ‹‚d£é´PAã•‚‹•&qy½ôJ*ïn$é.Áœl8¡¯®¼ËËsßW¸Øû•zÇWM­¶¤yûøùh©õP|{˜ï‘ëkâe˜°	ÑÇ‘•D«,²?e•(€¯†|ƒõ3á€êÉ";únW‰¡R\cùì¸–ñx½Qu¯9Y£¨_Ô‹lîø´á5d2&dD}6k C]‹	Qj4Üßuíiãˆ›•¸K‡w*£Îş²¿
ÍøO<B(B‰ô‡âéPÇšHXÓ÷7r%íc.;æªX‘ïšJ$o&+.¼³Ûsm—‘OªÖ¥@qÙ˜BëÌí³ÄÌı¶;ÔIsÒ4ğÌÿ|ÁßZ5¾<Ğ{¤ü$ÉğxÒı@6æCATì¹¥wÑsÎ¾ÆÑæzí²ævô´D‚óŸFmúÉ;2ÑÖ¦'aˆ«º"R*Â
Ç]²k8^†.(€ò•¶M.zcŞE6j5ï«lTpùğµ˜à}Cş© 8@.‰ÃH³y8ÀÕìßÇôØsW~ euæÍ“j÷·«`ÜåÓ}_¤×·©Ÿ*Çöœ‹jú¿Ï$9¤·¼‹†UdDÊò¢®[âÔÌõ2çƒœ¬Ù32‰Çš8›®äo9{›å$OLUıáipvªx¨¿0Kî,í”PĞÍ‡å¨úÜúA^d¥(†°İÅBŸ,Ö˜í ¦5g½Éq°!œf¶üˆbŞLÃFã“‹ÎBÚ¥ Òçk±Ñ«0á§¡´V°7†Ç`°vúØl<~‡æ$!§kxßµÍÆÜÒ€0ÓÿÊG¾²wïDı·i¾oµÄ
ÃĞ~ÙziÎ"ë¶/oøÓUõ\ËßÑìS7à”e½VúY½^’<‰"üa¾ş¸´½Âhnób‚×t}4ÜuÓ‰ÿgé»¬£ç`‡?E½I
zv"ŞPÉb‘)L
A.Âıí²İr›V÷ê'ú¼Aà.£U' hµé²ÚØsc=¯ğów ei tá4¯ªáN]ŸI–`7ÍÆ+ÇÉé¯á¸gº§Öa‘gd¡­­O’˜
eÀåÒÛr„;»ƒ_G¾Fv@&<{<âñ¤mı*\úK18‚‘fª[©U½Ê[Ğè¢¬›#OIÑ:¤Å¬üzÁ‘e…¦R_ÑáÄÈ™$hK&À“‚T_4oIUıä“Lge<[u€;ŠW)àøx¢¬®o(ÉU† J¦{ÛcŠş5»#²âq kÏ¨õWƒ¢»ø†”‚v¶‘«–g«Ú_õRl¯Àukİ‘Ÿ™Å­GÔîF±ŸáØŞí«Æ­ó<Q"ú!É|k¼è‡~ÇNq”„+İ&BeÓÜÛBŠ0'mps[gRÈÊÈúÏ0/y‹V	—ÊeG¯NÃŠ[7§Ô]öó–‹PĞ™›»$?n×i…mıİCaunë‹_Òå±ºÌê|°½©09&öV±°Î‹‰´|~¬¨‚°eQÜ0—·Ô<Ÿ°(ôh"a²õÂêA@]¡2ªiß<•6›)Ìşà~êáÂÜJ5–|QÅíU
'ú	g‹ùıúÏI RS’E@ı%¨9¸3øXÑX<¯Éºcç²„!G©ãôìËõ°R?UÔçîn.<Á2-,ƒMtg,tÎÂ…R¶ÅÿŞpK	hÚ2#@ˆÂÿ_Üæ}T¿túF`—K´7bÿ-Qà°ñ
J¦µ ¢¼jYè_{&/	êNP–s‚~\<mªgÃÊ•´[¾	7(öl¨¬{fA" D3#å£·÷z'>­³úBu„ ]4x<‚HÆâ¾5õF«n9vt°’^j&êx…+¶lÖ¥M ®»Œ'µ·oÓpûè ¤ş¾öy‚¯!õánîé(;qOœÉƒÂÄê ıšç~äJ-™Óªœù®HÆ†è}™šÆIh²X~<èlÑCp2dØÃ$.EZZìóHQ%{7pË]¼²¹—³´~îe£±]‘`rIrtCÊÚ3ˆÇüÇÇNC»b£&!ÈòAm×ê—5¸o“ŸÁ¯ÙüÕ™jaŠA°qï9::æz8IíÂ"X9é)YßOˆõ1ÌZ29\¨GZÚ"ËÂékmÀ>ÖYlÃ”5²À;[°	µ|ˆ²1¡!N²·Úø;°•…BØ _ ¿d´CíTş+£’t)M‚Œ€vU!M{´ß*ä
‰!jÒ,àM5éÕ×æ»q=zŸ‹©|Ëÿî×õC~¹réˆ¢Ş¤Ùâ!l¥/áœæ_Y?A†a€bÅVV: µLºlĞë¯‘™C@’Z_Ü«©¥<ş@§+¢fè¼ŞT&„ù²ğ €`Ø¶ÒçtSZ‡B´¨ªM&‹ébúˆº¶˜Û_
­9mŞ²¸UâjVºBÇË¬H}KbA:»í¦™U¹µáıYî½z#?*Øí³²óŸ3½sN°K¼£&ót¨í§×{z÷€@â4”Iœ†è¤]è»s’ÖFãòœ½oş4
õ*i.>p²›(;¢U×JœMT`Õ&PÚg#İ®OˆK_E
†Æí¶ù(²i±U~«ÀÅë˜fjÆïâVE{‘+Ÿb?’å$ÿpÅi§ƒ‚• ‡FTTKkÛC6êÆ éÈ"2À&öáJB§Šõ×Ş»¬d€	ĞJÄæ63¥:\‚óø¥Ë`gFûcŒ|ı6%éˆ[ÉdİP†Y¦r³ê+–ÓæêÃ'Áb¥Ûç¡§uÖiR…‰1ùgÕ‘mãêÊèÌéx?s¦]X,"½îé|@ÿ{vë¤1âªƒ‚Ä,¿*‡'İ?z%+…:#Vá6S ?<ì]t5×¹© /„ÿ©áˆñÒˆ$`Ö€±Å‚ÙÄÑ?¯Vñp£¤¬É©¨MZBúëÖ†Œáé½¨`°Í6)Í¢wTöm±PX1YÑ’qëË”×3áÕËï¤Ø?+è¼CFFj?î_*¼“fAuŠkÓ@k nñ2ŞUéHÓwp¾ğ«M®Jä!qü“»D‹¶2•?¬—Áo&¼±p½¡Ãw·{^ª÷(!üùSîÍ,/‘x/£¸üÈÚLàÖ|MÓs¥ô¡Â”Öv#½,tóø	Š.ôCº%€3dã‹¦^†¡l–@Ã%i|Î[³n›9éÉ&“j«/q-”¾ueMVâe°ŠõöéôìµêáÒ55“‹0	¹LŒÅ§EÊµAæH¦„ººĞj¤ËH%ZL5½n•—Ìß-’ãË“ ĞY<sCWÆÅş¨lUçXL} ˆ[“°yD>´+[§ç
ºÈĞû:4ÿİûì	g/y™%’êªÈP}?ˆ©X€ûè«Æ66#¼1AÙùpËŠ…™#[šù¹u^³‹óâ5°Ò¶KaÈ*úäOO%cş;ß¶²Àd‚Âå}“h@}Ä¼ú†çâ’šÄ{Úù”Œùsç%Íî5z¾”pÛ±Ö(±ØşJ\ÿ§N™-Ób¬W!²c ²·È_»)6¸õÚÓo±Ä´zÂ>€° ¤ìÀŸUYµû’ıC¬t>Ös\˜nb/n™¦`äÚR>Õ°—–Å16ŒPFJ&dúß·Ü‘Â^»iıçp¯A7Â¦¶/±V|Is)o%rğÏ¾ØÄh½%—[b)ŠÀEJr^G=§S>.Š‡@Jë}eÛªOoáyğq·ŞO¦¹»ä<¹ùNâKÏ K»& ¡4¤¦s¾Ü©ØñŒ›/ÑbKÁM±Q–/A´s6 Sz6`g?”ÎËM
®5±«.RÃ'¨ÚÙ{…XìråJf¦D‰‰œ@åù8æëEçİ”0(°pé‹I
º]b‰æè|áÿ·É	gÒ'p;9Q’!`E1â¿1|‰v¸p·UÅ¹ÒbEÄÍÚ¼,£<kÿƒªîÓhÕIÀt”‘STqyÓü„Ÿ WLø~Ø¦­yÇrêHv£šèq]¡5è šùßX¿¹o¿´ˆæ»Îû¼vì·¦”f¾A(  Aho‘BèÏo8á9…˜à=sÂ$Ûgì6Ê]ËA°“ñ?&µÃ£	anÍ%8ƒ#yèÍ^[‚v‹«Œ¡pë.Ø”Ê¸V˜½§¢sú¬fÔ`Ä5ÓÙÂEŸ½çßà÷ªıNš3E+ñlĞIñ×z
sÍs~#®fF×(ÉâŒÉĞ§±Ùçg5Š5îa9À p¼cHqà`²ÃIšŒ²êµò˜ó‰Ò¹¯LĞÓ"O&#>,ªµúŞÈw‘9}ƒÖ2z<Aú9÷4n/8bÁ^¼s8/ºÎ V4,ØçSS`û—äŞN{c¼wä„zÖ¢v/¸2š+¿x‘+´fê
 ®Ùh3m¡?C¸q¢Ç{ø¸ÃEÙ€ây¿ºÚ˜ñ½!p¡š/ù*³RÉ‘˜@²æk-À¿5²&×Ğ±É/>Òh
qCEõJ•?Ûå;Š¸[ÖX¨4¯=İæVÀ¨K–‘#Ëa6§ßóûç#l“·]{l‘:Pr,íŸw9WŠjÛA±ó”]#áä3÷P‘R4ñ¿Õr0³ï®ÿ“ ÉÅ™¿}0İ„\I­]¾ÄÀ–~îÆyÖn±‚ÌúE Î,ü=AäKíêE…¾MşAë%€¹ø8zÕk 2mv´ª‹ÍõÙ†PhLsVKòÔ‘Ó
#LÊÀnƒy.˜ÀNËûÎ\T´â©´Áëì« ñ>†ÔË5]EuiÔˆ¬ò˜h.ŞÓ…N[œWÄpS‰›Täh˜]}lÁğ!ê™v·7™Œä0ÊÈä)ïDÁûÇ¡é©^ÙÔ\X¥=o®ŞIÅâ–N=	ÚLbQ­¥4‹¹äé€ÃøÂïOt­o©'ÒPõp³°'£Û>'åE2¢ÄÁ€Ş­OÍRGeĞ5-Hã,ò6…Š±ö“ŠiYÒ hSFÖ°ÚÃc›äS	îÑ’ÆC%ÊÚ¶;”:)“®yœRğûiAİÔË™Ï{ƒª»‘óîºîÏü©aÎ&›$å}÷ÇKi…IÂDñlÉ~ıÍu¾nrÁÕ&)te†v©ÄáF*ÇÁF6Ç ĞŒu¨+µŒïĞè´·báhÌ3t¹·âCƒW.¤’µÄİÉ2ušê²gª’HRd‘ıt÷.N‰r`/ÈVG79ùD·ÅğE.«½¡t„2ÒøÂˆbòwVP.f³4QmZ6Q¢Û²‚1yw§3¬»s£çE)İŞË7°CÖÈ¥¾ŒŸ
ls€ZXVS"OKş,†»bEà-K¨pè`C›»0Ü4–êï½5¸wâ0×úô¹wésì¢ÎYƒ2Ój‚!Å49æ¶ág²İW‹Ÿ…ÀJÆ†B¬Š@ºŞbÌ¡gÿÄŞïÜ(vBJ¹9¥M¾÷ÅtQ–æI–]Ù%¤ ü"Á¶ñÊ1otpêÒbxÌè=ÀŒÈ…İ:1ì*˜ˆ}¦E%œäo§ığlœûo=ùvÿhÖ1ËŒ<7æ®»¥ëx÷£¤åq”˜Ñk\<y†š±Ûgi¦ØS¢Ë_S¯ ¬ÈèõÇ r¿É¶éÛp DÜ®øeq|’æ(Æz{LÎÛ¤	Î&°9™ušOêÛİnJz-®`ØúÅPŸ4z5F×U"ÂĞóAFà¼HĞhnv¬Lº—: ƒÖ$ˆ}SD>ºwÔ¶—Î4_˜eLÜ^ênUúv†ÿÃ¤ÈÚ!h“óùÚ4©Ç†©ô£ç‘ğ½}¢	ºı¼!cDö±¨8ï,àıÆkä6^0Gö÷,p¿QcH_?À¿ÿ$(»q5]Œ±îd…\0ø&xœjÏ
•À_æ@~ÖfœÁïw“ıY{j	¢Œ¿a::i‚£c¯–ÛOqÈ€—_ùZ£l–úoÇ÷¬~ï7Çµ5.C:†#´bìÓÂmJìœæÿÙ]Rg©FªÆ½˜ÌÏÏxÁ
»Övˆ™bo´³I!QöIáñzÏT!DÇpº¯5QLƒ8#ä´‡ùéÿ’Ö¹E9º
,.Om ¦Ÿ´3¢ÖMÖˆêl]–¶Ñ }9¤š+w%>¾™Å2Š³P®‘ °¢¬Üğ‘‘G5Dra("Ğ±f7×şnÇö!÷ªa3$*FßÈÏªê—XDà1,óÆ˜yK~jtEL$R_igØˆ(!ˆäì„”Á†xUB×©ílŸ…‰À»#Æ—â€lgxNv•/ûğœv¤£z¤¦¿\¥…±Hš~V‚èäÏ8QÕxû‹x÷l'—n¬üÔN`³¢AË¨^¹1›ŞÒ¦Dè‚B‘¯!2”ºÀi©ëÿo1¨û.À£Å/±]¼H7—«mGk>œÚxdNŸ¯ÏNxã®±ÈŠørãòyãÑE’‰
¯¨õÜà€¸¾*
<¼¹$³ZüÙac7oªkÍÌŠ¹à!—–¡®”D‹Sıeñ‰ÚÊ„!"\½ÉÔ®ÏÿWb®:àË;qkçşo9Ì|Ï»†F=µI¯‚yÒSç€z¸¤=OÔ¶…D’ÔM¦{ujVuP	î>Ğ®Vïã>Ñ‹9ªy×.=ğáApöf`Ã§%+‘Ö(Íß±ídë£Vî`Ñt«	õÆÔ›æ?£;"v#u‡ïâö»BLÔLwÂÆ§÷Q‡“³]‘uHâû°(vˆ0£ğĞĞË‰—3‚,Ê_LT6…Şqæ&2Ä²zRtöáAÍbQ4F¿[‹ìù$ñsZœ’?oDüSÀÎ¸å¹Ê ²½c@Şl£óÿ;u£m…ùàÜÑ8Ìs%g†Q4–àöa²#íw‹1éĞ/¿}•ûszÃ—H„ìÛ­ºÑçbQCcbÖ1qRcRw|.4Ç!tm¼uğêö+YñÊ™Â‹S¡sjpÂßTøej®ê&óÃİÖE¹Y¨õªôˆçSké+9šv÷«¨Şó¡–…d9ı‘â“Ça¤L\çİ4å%O±¸ß¬²u| ²ƒ–&Ø{ÏM)˜5jeÚ‚L/
yğğ¼V5,µcÁµ¤Îã½0'}N•˜K	÷;e$æ¥æS;¡#’Ñ­³8‹•ZNôm‹}6<äËó7?øº]æ0Y–‚TiDöF  ˆplE·Åô!.WWL-’¢¬l	l¨R0HĞª­„àIæ#hBóQY ú¨ed‹›J‹À‹
<¬1ÆÚeväzE"¢€*(xİ#lÙyQ&hÖÊI¥9hšîæ49Ô©òïQŞmÿ:c#RUÿìS©q~µeM'÷âÑ!É%ç­£ÈÈ0ƒ|¶µÁ¾:=Ñ“_>WRñÕ±öÅó .*±Öˆ#K±›»Ñ@#Ó¼ëo_vì‘¾‚«|Ø(á×oWôzÅOD,ŞÑë}ìôâñ—VÁ£ıg²{ãTkæ™£®Mƒîù}¼N2±¢ŸI¶>»§Áë%ŸÓ‡¤ƒÇ5³¶­…Èí0&©MA	ƒm"»îÆó³éYŞÏ_A}†Nşq¡ãh%x”(I×GÖŸøßÏÚ8w–à* ´W×ÀÃÂDMFF©ÿ¿Z¼P/°’—§Gºµî®;VËÙFlÙyXnè?ãI˜ªòìùÖ¨OÇwŞ¶MÌdÙR÷Q‰ª}û¦t Mí<şi°{„@¨MC››üá‹I¢0Ùh¿iF·£M`ø]œè«@yõ£f@‹ÓTŸMåo«o7/F8}ìÊ6Ïl©ƒğò«˜<™ğq;&°=^¨üÇ²ƒóÎ<|‰J n«ênƒ9¨{¯}	„>8Ô EéÅwË¹UVXÄOÃ-ÓlÌ±”G«Ûoó%ÏÆ»$Cß£!yfzEÂfÜ¨ÒÂ  $Åe.§¶ ’Üšö1g.•›"eY”wöª„ŒdeK1`ªØ®ô˜oö"»…qjUQ˜+Ô\aààÍ‡f$…©	¼à¢¦!’!ø0’[¬ñáûŸ×8‹…¯=Û%ÀJÛÆC«Md·aÉåhLH¤¬w 0öÿ?@NÇ6€OÔt9„DO¾îĞBÀô<ŒC^ F~±ÁY8¥!°t3)^n0ûÆ -ÈzşŞRk¤7`¦´¸¯J	¢Ä–Õ8Ö—)Nè- …ıŸ>×i=Í¦Ò‡e¾ïw+rÒmMêEnwQÜ`nLæH*vá¸^Ú°p*‘Õã’Òx±‡»s\—h‘IÊÓÔ©Ã<3aÓ%3+Ä¦èWgùFÆ¹P¯ıLk8_v£Äù*§–9Õ òå€°j¬‹d;´Cœ³‘®	ÓÌ¡ÊÛ0Ñìu:i³Ô/yØ‰ÒÚõìû©F˜ø
€$Ç¶€SNÿ[½}|ÛaSTÉz Íî -áş‘óå]Úˆ»@q‡l-s1º‘Å3m#‚ïéÌ3?ğDX–kZÌrP4€“FòLá;÷:&ÄÛohA]ÀWãÔ^"¶ì"ğ^b§R*N$"á‘eˆëd¸üšèˆĞÚfÑÕZ
?Z-Ïº©¦'?®ÅŸZN+—øeşnñÅª„ƒ@Øùõ Ìª1ôğv?G´â‰áÕ¥.À{ëá±¤a3-AE}2Ì‹€5Ó¤[Ó¯lÃëëİ%÷Ç\*ÿ#Ü0£ UÒó-Ñ˜½KÛ<[uê‡şå²±è"†Ÿ —˜ä¶ÉTĞ/VExKsğ.=˜n"¥¸Ç)ÒV+1Hºnúf'…1lPê’IYŠöŸbüCSØ}·T4Âu}q”O© û;Ğ³1ìò~‹2¯¹^›[z")b¯.±.[°E™0ÅwGQ%¹ü{Ø+Å]âSz=)¡A—-Ù´¶´xZÆÙÚ‘ú2ÀÑ,•–-¤õ­ ¸vô#I‰šeaãğHC?¶yœübE ø£«úšˆ":ïØè•Pep¨%º•7Ëb‘«½+.?¯&-èÈ‚ykÆ¤‘%t&°4[ ËÎ³×¬á	…Ò †Õ&·p¯ˆâ+ÌÏ`„÷†ßÏd…¡áE#gŠÏå›À/áÌ‚æîW€/Ò„’‰F3ë?qãÄ@ï4në)H.!LĞæ°Û""İ¼»„ùNh™Œ´“J³jôĞCùè39ª]Æ
Yd Xùêclˆ¡Şûl áäl¸B˜®hM4OøA»˜†zV?8ö#¦§êäôR:5‚âÈIô›gŞ|nN"¸àâ&1äZ9®J†GŸ—¡…(:À8ÏÙÙuwÊon“ğeŞÃÖım™R3×¿}WÉ€0ÏñJ½`î+Î¿a[T
NDõ?r|cau•Z‡>ó
êkk£vtóE[2GY—Í»Ä¼'¥Ã­BÏƒ…)3=şÕğ¨ªŞHÑXj™j+dBõÏUÜnÌ¸™Êá’>m†d9œå7õS6ò&*»å¥ı¶oıãˆïÇılİæ¥ş)| ıŸPŒD~gj–SÆˆ´jrÃën$P%CÛúÀË]Ó¬ıú FTİ‰“šŠm¬æG‡Xö×@`¹‘¢òî^YÀå‰É;6¶…Y+ÿèofJÿ5y¾R’óÃrä,D¦’™u«šIâÃ%–D®eAmÊİUÉ­@rÅÊ7İ_æ÷­å\¤ª-³‡æ­“VâÂöÍ¢Pw[¹¼6¹Åñ}±æÂŸ=è°0è\û…• F-²‹şâÛæNê¤ñ-€XWÁÄùToYÅ&¶‹´¾„$S‘ÈúâhãÉ¼B‰i%^rã1ï·—YQßr#Oa¼µ¾¶<ò¼çƒ&M$®åP#w3MOI6”â;Ï’‚Y5l ¢§Âw9'ësÙxp´M{š#†pA0"XşG›QPs(«6™\ÖZáA×\ö”õÖ“ˆ—˜"ñ†ÀT±¦İÄğôşP ØÅ]¾ü™öE5kI2fûö@Pœe‚r¹o~UºÕà^u¼ÙYs º‘›=ìª©‚ñÙŸGò3ñêÆåÕÃQÄLÀ–d†µ€5¼à¯Æ6D9ÆO,ò|E°%@òméÀiŠv	¤YêÚSì[ˆÖÈoú‹_#s¹ØÂ ·İ¾ûé3\ûdK‰›¡…Rƒş—F@´KrŒpdiŠ•îgˆ‘eBäc×¶ÈÀ'ôpR]aQTÃ±]í£-Ñ•_„„…°£„¨fZƒÒÁí™8Ù<dYš1ÑŸ½H9nBÍÑ*ªˆNxßè™¨2¨Êx6ŞÈÏAcYE ‚Xç¦™ó!¶°Ç×á[TÚ4¯æ`ã«]gÇÏá^•)XWp-÷gŠãc9şÊVòÂ2,]‘±õjTAè—"“fèİ0hû®U:˜ÀP0‰Y„€tÚ¹\ËÖÓ“ºb&‘?*i‘B^KöÂà«êÄ#Løòá³5áß»†.ÊNØ=!×êšGb9$9Ôw×¯¾ùw€Û•ç€.CÜq€o!$‘{z„ ï)Ò¿‹V¸ºrù˜‚µhÅíüjz¯OkQº¥ê¡R‘ùôN’ËFŠ¯É`&š|±£Å8~‰‘>õpNv¶1/®»•gæú¥ì]6„Ø¤w!éõ£Å°MHÖ³›¸ZWå`íƒÓå€Æ‘’×FA#Ÿkb¢85Ç<rí$ë¤M>˜iêªA·¤ùièúÿhê¶^rˆKyC÷Zó1Í³­$ƒ¶°õ9ù…xáVëÔÕÄC©¤PÌÏU*÷Dş¯áª»Ü8¨rŠ«²|¬0âÖğëQ”zBÂ·²ÅR¶ıßsœÑùßƒ>Qù<Ì1ñ¥ÀE¸ä©“ôIî5C¤—¿N¬JÇXã›7kóªT?‰äü¡?ÉUbalx]x6GÏ§ÌQˆ]õD™˜b–JÏævíôwaîí/\&­Ö†×B²ü¥ß@O’¦¼d©1ÿÃğQ/Ù±äh‰èÍ|fªRa™›*›¬RË‚ $Âl!/nPcº5.Ø>OW%úß_¬E1š&Ó=H %»`¨Z>mÓC®JE¦–Ò¶LjÚ5;{ğø—eÇıKÿN¤”ÿÙz4ut7b¤ü²IA]ôßèéGZš2—.ª‚•‚{ÊfLÁ¿c¨Î®—ñ~§á;=*ÊCSÜ’·2ì‰×@©³Z®ö ¯‰tEi2çKÁ¯/YöF.[Åsw¶m¦\"vWø´÷›¥²ŞrúÖÖL@di~¦@˜oæ´òS“,è°ÒÉä­~0Écr†ˆˆˆ[ş]¥YÉH@³ç‹|FÜ§œ-µIÙ]·R•8$Pã¢”®döÙë´"±°Š@ÑÃ+¿
°ıış%w¬…<¶l}¿™ğlå®uñ‡ZuÓh¶’3¾×tš7ŒN”ö ÏÕû¶±N¬ƒ•{ó±E07_k|™–q×'âBU×ÒîÈ¼&A@¢T+{SHt(u‘mŞ%U,ú“‚xI½€Ï¼ù‰tÍh	õR>Yx°NÕçôo o#
~(òêº«´vùÍŒÓQ?€:»7:¡˜EòuTGnôq:B÷ˆjÀ¿Á°‰‡àf¶ÒŒş«Ûœ>k>këæ8­«/&M¢(·bÍÈÜgÿ´(ÊÄÍzáR·®Ôê™×_5¤"X£”ı®-êåüšÚ6ŞĞ1*^äƒ£hiŒòöêÿç¬6"qLåR·áfêm>ô	£È!+ÂéÉŒêŸl£½XOrµü
¿2™æÒÊbZÙ}¬›é&®—y¦ı±D5Öì?]jL[`¿ËD9zñ3÷L0µ» /–‘¡%Ìy{¿V·,U:üVn#é¯=7qr~Š~–(N¿ÙÄÙş(³ÊømÅ 6Å0\6‹Û}÷5ñ
HÛè>GX×¯1Ì×†[ïgJãÍ¢Z(’H”B£k‹ösYŸŸ7klÕd©æ Ùİîó•İ¢Ñiúk…Ù‰!.ÈÃá÷×#N:ÁÚ’ğ\Ó¸|-ƒÓ5aqß‡ÃoÚƒÎ<Ù,œ´¤'øëŒ.¿{ô±Î‚X¤3Øİ­å¼²©YâõÕTÄ”‚¯´İ˜Ü²„É»©Ÿª‚]&ğ‹‘Û0×¶vŒbbFÜ~Ùî¨JPˆ[ì>BÁ^ˆò¨tùÄ¾Ê@àÕ»/±@eP©ß}ZPÑv¹ÉĞà‡¿ÜLB…‚BM- f-İİ%<ßUZ¦R[ÖÅmO%õUÛ=ã—Y¥Á~{¼<Gb­"vÊôªä+Ø?S1Å(˜‰éO¬-Hç¨P,G;Â% 9øGá †Ÿ²æ±Ùx©àœ¬d»ìhÅÏ.êÒØ;O%·¥ß|å$å€ªËÓE–>dh€|6Äò€iZÂ;WN<n–¬²iK ü\\_|bÛ£4¶æ)s"ø‹‰õÏÈì,ÖÒğØnä)b:Î
“7³µ$>^sÛšm…yağ%=–µõ­ p‡åjBïbG¤@•wÁ˜Â.%šğ·ç¾R¹ôÇÜ*v$¯³bÀƒº¤tˆØÕAÀk«”ñhöY¾™ó?®kKcµU0$¯¬7±å•4qïl6#>>öŠ©„;œQªğçòk‘ÈØLÁı‹ıŠñ*QÖ	KßóMÔ,UÆsc¾G^Ï1ˆÚ÷GóÍƒ ‰G–ºQŞÍ¦H»ÉÛ¹äØš‡¯5œ7Ìµ€:Ñ÷5|ãŒ×‰Î6aŠÔnÌ|ïmº©÷n¬Øwo¯´ıün†…ë;ıÕ"uº“Ş5k´M­‘™ì¨Ô(Ÿ"³Ie'¯»ÇMØq¬ã%ïÆ"Fò—Zß»%YºuÊŸ½fª?/>X®.ã0©¦·2¥Ç)‘S’ŸÏC…¿f2©„.O¯õ¡²÷±]aÕÄÄiyòªd_Ï¥8æ¦1x å¨s $¬”6Ñò†~ª¶iÑésÌèZS-$«(%Ï§>JÍ8ÏN<@Ud•˜Zıì·»fE›‘õ6kªP$,sN¶K‡‰‹Í8Ã¾½—Ø°É“-[ç|=u=9 qmä²İìÜYĞ$õ^¼‡Á‹U
rì- µä=ö,;°€Õzñº;1ÛşGp¾ò(Ï¶,È&ºèNYkÕÈ]8ÿúÿØÏÍ¹è-m–¡+çZ2ÅF³®c‘kû„¹pĞ Ç,SMŞ®æíİëfCS~ƒÒN§ß”`˜$Ï#¥^Î/"ˆ@]æğ–KìÜko”>"¹póÿŸ²¿Cô²NÆ„ÈÈÉÜoíN›ªyš‰R‹vp»‹/L¹«ëZA‚»›ßİRìç@<:ù{OE”“†êoFf`w¥¦€L,°U^õºM×Hp­qq ûöÜ?J¶òƒìºŸ‹õ•îˆæ=”0®¬-0¾sÃ)ûåÇÂZ§¦$F½;´tËysş…N¥Û!¿×Ë°|ôğ©Ó’Ig?7u¤»õ3‚Ô1$X` ¡)˜³	\©NÄŒN¤{é6Äƒ.†“\«¡//iÓáP=éâ
àê2j^röÿ
ÂÇI¹Ê8@i°›—bg`ViScvêTêXcZŠ¶.Ö…¡¸F¨6vª*Ãåğ¡±ÏXĞ;c•Ë9›©y<¹ôû—Å0–ôÒ^Î|óì³H‹´e±N+|¼±³?_ kBİÅe%^U «À?û¾ÜJe`z,¯qÓ\‹& RñÓq`~ykOE•î}LT $¢c¦a2K¿.J½eú:çƒr¼35ã¢H°l®Şîˆ+.šÙãı$ø09ı‡b#3Cu²¤’Ìml8R$½Væì¤’¤‹1UNÇd¡vİ4zşjÈÆŠ»ÓŒ˜ÓùÍ?ó·ÍÓMiê¢ŞÅŞ©r))ÔY¶{¿z˜êûVI$ûX›}øÎ•½Î7‰;£´†lË–²öâİ8 !Ÿğ“š ÖG=Y$CuT¾“º@´n?¤ëzÀ++3/Åá<&ªMåªÚ3Åh™¬)#rwaâ£â‘m¢’â—ään>h‹¡Ä^÷»æ3lÔšøék¼Q‹¸ê¿(1¾Ş[®B‚ŒZL¾A£u÷‹W™ÑœX{n£knC‘`&d›·1™ŒE©!£À3Õ±eJİ¼qe¾ „ĞFËaŒ/ÅWcÌì ú®‹e_"qú+¯¼µ‰DJô>Ä…éğ¯æ¯ íTY+hşe—^÷B8ØU™Lxğ¨¨(æjâıÙ.ø¸¤Ûä7´kÚHí%U›³£Qg)	Æ$HV$Ó×3¥Mµ«Ú™?Û`?ø¦vëwÏp­ç„“qÜ¸×7x§	C‘´˜’ZÍšrëª|.vÍ(A')”¶§poÀKú[Yb@y;ÇxJj['º¬%³½É¢¿¹ÈL¼ÒQ&BÒ÷M–½“#Í”<­¦qP™¡8lƒsÆÆV_®ë›G`_§êªoÛØ#ƒ©.Í$<Œñ=oà®÷¶´Áp)è@©¬Ğ{
.ÁM&Sa©ÿºß™iÂş6,ümqË=_!%É¦ñ¡x%o4¸R¥k¼ú‡+Îˆg=M‰±Ë¨ª|úß}‹’î÷~h`AdÕ¡¡Õ:½÷jO›‹ÛNäşÇm>ÎóvlŠÜ–ò _ôÁUæ³¬	b˜Q‹.s^_zÎdS¢}A}r+Ğ{á-D_™‰.>…D¿âXfİï,5|øn’Ñ'‡#Ã»|‰Tš€ÑylVß¹i/™MX …Ã$3Ë>ˆš@âı½w­ªfÓ#0˜ÏÕK*²4Ú¯V×Ân.XaFüaÎokıj¡*O[p;î¦JËæ^OMP’o;®Lè¡û~5\9ãäv…‘lC[íµC6_‡7¯bïŞ‘ôS_#¹6¶šB´´Z„0SÂ€yêæ=á„íæ¹ğ t$”^æ“0¼Á©¿ïƒù^³í–¨­ÑõÇ[]^õŞ!2ï¦ÎÑ¸aœO 4 2õ7Y¾©Zë¥'âá?İŠß$æ>(ı]€–Èør{¬”å(F&`pÍtS gj>MúßíGeúñ
üÚyÊcïÛze´aSìáÓÿb^x-eâ¶H[ÚòÉ¹ãîc~X½Œå•¯0oœ·|­ÇO±$<ğ@Læõ·yR›×ó6¤İ{Ö÷xah—•"TˆËI¥)@™0I"Ô‘š-øŸYdİpÂB$zêsP
\%/Nmˆ+h•ĞôqåZ×‡Lª°÷LÖÂ%#|Áy	zÖ=)ÆjY‚Ğ¤0Á(8-$<İçÇ·	J£êÙvoYw\¤&ºFnJM‘Ì}ü—TÀÅ£y“Ÿ3!}@])±Ï0M¥¯el°e%§{\8ÏLÂ¢,İ æõû¡˜6¨å&h´½räØi¹;Úë½,Ù'ƒ!è¼€iˆ¶‰s‹¥Ã@'åRfJí—Nƒ\h­ô¶®öIõïoà†ÿÿÆ¾8T%ÒÔù}6µ»–QĞH+ÎØ&38€>B ä©ì1èÖŠ˜óıÀÜ$µşÙá}«î¬Y
#!¯"†›MIZ²jYbÀåjî›ÛŒ4âK7ó"ÑF—y=JŠ«Ø.ä y,äÜşJ¥õØÀ÷š^ïª±êĞM”‰6	+ÈôTô-;+vÁ"‰«ÎzDÄêc	B}AÓã¨ö³ûæ!Ëâ7CFñ1•º©ï%bÖ]¤Ş8OŠoCÑ‡
dæØVøSãÉÕ¡]êİ‚XÏö¬Oïy¨¶'&Õ íõÆ¤«eÒk	ï»Él†"ú`Ê¥–áR.K}­Ñ°zÎÏc›½ÑnŒ¶†âyÍ»Ì?p*üæè5[ o‘“X£„Ã	f)”fi¶c^ÒÍµØC…ùØÈ–>ğF³J­<)…¿L)l3‚„œ}e†˜B¦ ¤	›?¨²8^…˜g‘ğÿ¶ä®QÏXÌ~fî¤E”½I
y=~dôîÓëæ#,P°¿Tú³}‚<Y‰X½=#ª‚àF¿ mm`¹%‡AáøpÄ#á¤ÅWå¬şîë‹ì ¦d¯°¼‚ìå"·c¢zT^Ø¡Ğ±rÂÃ3ñí©4 ²§*™à„Q"q’{ø»Y_có‚iê	‡³MmÁ)EaÂˆRŒ2µÓĞ\±Ñô}Nç­ÿUåÀÇó3¯äò¸sVÑµò”
¥àÅ¹ªâW;’5òõ5¥5…mm ÎzqÎ 8ç§Ò¬‘¬D”ÅN‹H˜ÄT3¬jç‘UóX²ap}û¹†·J¢èJÌ–»p¸¶gf“=*:d"½<T¹ ba}F-VŒÅ2oZß¦k†vQUGZÚı‘÷gûyxœ<í¬€0…ºxÃ©XZ]J™ WÄ³°ÛcøYB ø«?„|Á>f)_
Rß¶®,½{¯Â7ç:`G äÉƒ*°ÒÈ<ó´@Ä° ëU~ÄÍYœ«(iƒrÒ}¬2»p™pÈËŒ4Qb¬°·)pp‘Æ\µò¸¬—û#M¶=‚›9<ù¶Ú£ —Á°¨]ŠCpò#ÎË°PÉ 6O8°~ól÷®@l,P×Q^A!î?)7?´:=4M§´ñWÒ~Mza™*ÜY²¦5¶ÎÚ•J°ôál¶‘	ÅIXAÚg+Ä
Tşº,œ$‘æ”3ëœ*"{¡ë³AGW=Ü…rÁs±ş‚
èÒC{¹ƒ	’ñ j`€ÚÆFkuy1?çUû?ıÎKTDWÉì•‰ÊŸº
ê÷^hå”ºÒõ£°T‹î*¢ï‹6Ç3T°X~î‘-E…«h­»ÏòQ?A?á»Ë¯rÅ÷á²ÔÔ"šÑÖKµŒUÍ²Öçôs½g\DÆÂ…ÄyÏ³a{–s‚(Á¹"Ò}“JbPÕ-‡±§Cø‚V>ÿ&ıu!€è‹ôFõ5ágié¶lÜñ];Çåòæz©}GÉ\–şş{ïÙgÀ§¼Xss‰à ¿Àì±%S&k»v;¹C?ƒ^½åÍ±äW[r™„Ú†[×ƒ´IB›I»˜ı=	¸>qk{f“¦0hJÁËÓƒ1ª0xXß°ñ}i#¤Í\¹d­ZEL¦ÛÁJô»¶İÛÄ—kÈùU•nâ¨Ÿ(ûbº¹v(|ú‹h¢[¶ãSj0‘¦ƒW{ÿıót½ñz~}İnF˜!ó({'E-O¨¥Í¦ôeÚ[u†¸~ìNk™3zi|Lã_µş®¸·`Ã5Àg‹“t§‰¿FI¹µ{`l±†²>ó(íä]ó’³FdÖŸ&ì¯fÎ‡qoø"÷Ø¤Ù_Fs©dö5LQ$5ûæÛÊ9ˆ"3NÜ²Cºd}b²d2B1 ®L¢é&…Ö˜éâ2MNà™5È¢÷àÈôg3¾¬vhCı¹|—¥•œâN¿ŸoÆ`,´ƒª®üá\yÃY§6¦‰“÷=ÙÚÒ4FUuEÃ¼kƒ@-E;ÕÿĞcì™ö-’<İ±ñW^ü\Q—’–)Ãa ir#l…BZ¾CÙ]7xŠQŸ‘×TØëğ¥ÿ}<¥¬Œ@YÏªÅÖØoğ…µRîô¥7üŸxEÇ—P‘
ŠQŞ'+©B,ûRÙMsÏ›å6ô"¥i|›ÊÑqæRhëö×êÍR«­I‡YÕ{¼ÂÜœ_11õc‹ß“œ\Ë­‡„Nn r-ç>å¼E ãBA`VÒ¢È[Äêªä'°bçÛËµÛ»÷AqZ²`(šŸuÕ'S‰» Gxãğ˜kw\¾yv•ÀÚÅ9x…+y“~gs	Ta÷«‹MşßŞƒßÑ 2Ku'˜ÎRıÇJY=“¡ŠğxçkEÁL,mƒ±%%ZbZeœ*¬<¼tnpûxpâòıB{FO»*Æqfif@Íëï3)ë3¸Z¤ÛeuOàÒvgO­\Íb)>òä¶İ9-7ĞÚŠCv°$@O)q.©JrzVûâ7“z5×]»¼<X?¹şosàÈW×\Õ]=ö û½š(vøÍ%D¦õhô‡s“Ã52dªL®câoşì¹–</A¥4¬¬¦X’¹§¢şÀ¦‰zµ:Ù	5zdŠü5ß ƒQ¿e(¬DÖ`wÈ+r¢ŞC`ØHP^9İ‚¬@ø/QÙ&è|q¥9ÉCt°ù
K¼@¦5ççJÖÛxUõZúñ±ƒZ0È&oƒ·»¿'ÁÊ4ú•£r%O]Kõa¹Û†p·„á»Áô¥YÇAq›>‹|ÿû”„jº$¸H|LR£ÍŒˆiŸ#3Ìê€H¡dô#à›I¹)è´ñá°ÁÖQ:ÓB¹h
ê¹ûÖóa–°¶'Rä…H¾µ`8 Ô}]	$ZW+55´~@‘Ì‰ıVéšéUï®-aÆëçødÄ®ïSjb“ÉxF2õl£*Åd ‰Nñk|¯öH[)ˆy’Ã»Ç®jÒã‹ÂZ§B¬52Ü5™ğz›‰ouî—¸E'Z› `á”óê?…K[?mve;tav öË˜8z"Ó”ì\d(‡ËÎFFÈ™o„1IU]ƒğ ŒÈÓĞ?)DöÇ5Ù„ÉÌüì´2_œæeÄn·•.JËì	5{Á­ªš¤énğh€şÊ½‘3Ø3â?¾?ePş¥Õs	2è0ùZÙÔ~o?ğ<p‹V&Ä™9·«£ÏÒ½Wh£àæôL4úµÑâ(DÕ¼}Çwƒ
³QKœÀW `<Z/ÊWóãó¸Y—éˆÄß£ñ¸åjÓLÅ¹ kú­;èó¥Ÿö¤Òhæ?Ñk©wñ]Ø$Šÿh"]èFˆ5œU´Y¹…ÂR«RĞ‘§6úô8>/*>‹ˆŞèj%4Ş×¥›–Ê+PÕƒlÅùj#!Ş^ÍßS´ş4"ëígNãÊ|°ó)#8iƒˆªy+oÑòz#ÚŸ<Í‘áiÎ‰TY;K¢3w+™É\¤ã!‹„WíÈ®y…ÕıüjyòÌLe„‡Wz‹ï©Üğ¬)"xP¶èMÇç3õ¸ /ª»ËÅõM²xXä@÷Ë¬óŠ»pw^>eš<®lÃ¾ï%pò¤ l—F«{É(·æİ‚OÎàyš}(™İô,*õºé†á’Gd…‹“Şì†aªÍ*ÍBçº¿xèì8íÌ0tÆãâ œ6L‹§°Ü•.ıi7‰îóo§"#6Ë|ö"<jîj#¹¶Ü‹Y°.÷|'4¤²®2“Fœâ[6•û@Q5Eõ„_(õCÜ@íÃóHl¢’he¼P	šØæß îâ™)8İüSjÑxRQõcp|µÏÇ?/›Ğ‡o¿/í[ûJÑ>b—ëàjû³§+\/µU<NN¶ ¶ôö ñA’%!„L%€'=èîÄş'@¿K•PÏ#^fÎV¶Ôº¶¼@|Gäíèı\ÎÂbo™Q¤«œbİ ‰UáA¿Ü3¥ÂƒU„¨ßEjáFH‘@‰.FˆŠI¢(2èC¾€¬U²`_¤{ÊKçd§,ßNú»Ë„"I< Zf$¥ÁîŒ#ùêMŠŸ®k®±_¿êN˜äò `#¢)¢Ë‡Üá	Fôx¯FïúÓ­âu+ãï½û«­¹åEÖgZÍÜ¨d5ç˜J,àú^	¡µNá‹Ã~îC ÊóPØfrK®ùJœ€í‚¤ßº­4‰xßÖ Eƒs<Ä„í‘çm§q²æà…æ¨Z½%wÏ45P!Å‡ŞÉíªî£Ÿ|¡ğ£} ªk*BÒ[¾5¾ª;5™d³ıî”’ÖR„ZĞ·y¥ø²¤¿%¸^ÁM@:JŞ¾=J@`&å‘Ì7Ø«ÌÍKÆç•Èm¶‡…É=øT…Ã™v¤ÊÑ»Ùÿ–şà’ ÖHG¯èøyZáqd‹òqd¢û"öÉ`6Û 0Ş‰ş„íoØ¹ÀTòa6å–Âº¶dVZO(”ºĞ›ÁrPfMÇ‚MtÍ° >5ù`lJF¦;¨Ç %–PHéG…«¢vÔtaGùR´İ2¥GGVô¶#À¯#kWnJyûæ¡xL€Ò=bæ¨'ŞÉ!†FÔóå¥­‡í7\†)et+Ÿr¼cÃµÌ•hK²İp¼İÁÉşZ\ÔÆ/QıVÀD•¿ˆsh¶ª¡2¯Ï¸Ãí“æ®a#Ì1Ul€ı¿€
¯ã˜Cüğ`ìm—   ä·…E^ñä ‡¥€ğ6ØqÜ±Ägû    YZ