#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1620630146"
MD5="ac5a9bc686710999487da94c7acc6880"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23496"
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
	echo Date of packaging: Wed Jul 28 14:22:15 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ[…] ¼}•À1Dd]‡Á›PætİD÷¹ù&A1Dp¡rö¸Æáª	ˆós²¿£Ó«Å¾˜—†·QÇ™rõù	heVFzÑñ“şi|	S@E†Ï¶Fñj¶{¦wÂ;Ç‘®û‹b7“’¬ú°/÷&œ¼.—>?â¶/Z#ºí òx˜àÀ¿İş§ÅG;İ}a$|öE+Úw Î©|Ó¯T&
Ï¶‰¡wü¼
Ç[b²&Q[ú^©(óYd‹ì¸tT-¬c 8{EZz4í@dÅ"'¯­bˆ oœ7õÌqÆÃº€¼ëÂÂµÏ"4ã*|Èó¢	Ç¢„h}9¾'3iCı ^ùˆR!Ñ—¾\]—ÅZ?3Ç70j‰ğñ)ØÕHö(¤wçI…z,?Šã?,"™·¨	šêE/j
å¿ÃÀK±GpĞä?ÑXétKÎ¹ éÎ‹ş+ÆMV/B0×Õ¹.+ú,Ş­u|ìdÈHÁ<V¥¨[ÿİq–Tqİíª]tUŒ> d×«8wæº¸Ó07ìŠ»ß´;QFî‡éxõœÌ-W­qï¨¤¿(¼ ö`rì8æ¬1ÁË )ö²*[ä%Õâ–Øº ¹”Ñr¦²9ê¼öÍmXşt½İ;±t7¯ošn3ø0Ğ|G’4ÒÜì¡åI1_®Ü‡gÇwxãOó%<°$Ø'¿h8ª~h$OúşÀñM•X’—ß¦7«CÆØûå¹ØCiU¥]µENØÊörí3À ü\Ó¦	œE>ÖàÿÎÊÒ@IŞÚº2mŞpª%`wjø÷yó,™R1ø#âír¾ò©Ñê›£ø¢ßÌ>˜OzºV2 >=ÙHá+µ¨?Dt¸G´Ñ~ëÄñc§´U­"¦V·Â¸™Š1ïU¥Üd®”ÚS["ÁVœğÕjiÌb¾@¹Ë«*\æ–XÅùÅ¾³Qêaë8ÿ¾Ô>ÚÃ£ËÀU>Ä÷3°m4âGD6‡±	¶÷E·Ÿ©9b„3âÙ¿şMùc£ÍÛ£ù)|—¨å^I}ûR´„¾G¹ïHh	T9õİÀlU<3×0D±ÛĞè‡CÔt×ˆ­ş[*ç‚¯ÅTÚÀØTJnÚ[éE7*¬ø=¤LªZÂôe†O«—è]‚=E0P­k‹Eêüİ‘Õ[€+§]NYUzˆAüCá¿ŒÙ~e ËCë5ê~(Š¶PÒ#‹:¥¥*6N1Ñã+mğnZêİıÄ¡8 ‚Ö0©p”ËáµØ;[gÊ ã™8L•,<Í?ÿ±çâÿÅ5˜®yÄhº‰æ’ÄË¦l¢|[œj2[J6u…°=“_áÁşöœÜÌY@™	ä¸jKâH?–ó<9ĞÉ°bµS³”¾H3ê³U†O¾zõ‡Gab¥êây,=EÈ²1ê\Ÿ/&‘ÖZ¢@d„Î¾É@W¾$šM-Nİ°Û4©VÅì
à/–a*ú¥£ƒÈBnxjØ]?0cÕ¹WÅ”ô½«Åã“éò}¸<éphkD¹MÕXM5ãªÈ7¼°a¶ÙrŸ^MuĞ*Àú£CAÙ<^†“4)3q~
·äcÈM›ÓÖŞ®pµf*i5Q¤êªTë$s“ß2©DfV=øÒ`”Q €nõ¹’ìLÀvI‹ïnÅJ:»47¬,…Ræò¥±o5<j?4şÍÃƒ
û³ÕjÖ˜âñ›\Øˆw›pø^hâj™>áàp;zY5íÍ¢õÊ<lè\¿ß„yÒ|ßª4î ,øÛŞèùÖùÄ±…UÌp 	j|K> "©F‡s¦¶‡[e<½Ÿ(-]9›¬¾¼éğçã‰zSÄh=Æ&.©Ü„[3‚HíåáãQ2bó}¶]"²%j›€a»zãÊŞ0lbÛH=ñƒöuÌÄ‰
a`dÔ%3·SÂ›µøC¥+²­5¡Ó‰ŒÌ"åCY…bÆÌ»»0Õ…¨!EA!-.ª"¼:¢ÎÔ¤® Fk¸9ò:C¿Ch‚yE'QİˆÙùÍù¥VİOŞÖJE©!öµwƒğ¦|›;–`mÎp!Ó¬WòÆ[]Š6§…çª¼¹³ÀJÌaR°õùUO0â÷öNŠ¥Ùû°fcA%å’z>9‡Ï8Ê°YJÜAkKiFli!±@3
õòŞyü1tÑ|xÒ–ÜÎÃÊ,áxÿØ–0IìvLŒI?SdO §0¢Ò˜ 5àùç|4¬ŒİÓ[ËäAJ07’Y·Ô 2qå8«Úì›{wS10ı÷ß½`ªóY/€kÒÅª\ñWõœ!şˆ5 ù’ÅĞµ#‡ÍÖ†;†)/Ë”Ô•Õ,¶
]%lìrÒp%Á]ŒA¨´ÛÃY:Û(Q_ 3¹ü ×^¹E\
š+”ë¬1oÖ‡©ióÛ‘áx´¿ƒ®u–Y°™`˜¢Âš!=ËğlÂotœÏÂ» ×¿›9PóEVQSˆ;|oQ¡GSå^ÒÃ]"[fD4š]Á-²g ÓÔTåQj×dÂæ[ãñÆHï
ğã«¤€ü—Ø,e(6­rê—^âu^8"X0C~|GáhOÚÎÔò ÛÑ¸ÇU-ÇC–dq¬X¡«5ÙÕÀkqm'Y7˜*ı†Îû;1oe€u9 ç€ä¥UÔñló¿­OƒÆD3óIHiÄë¶ç¹§ô’/I&Ú#p8Ih–ßö¯pA(	­•,ôHwıùÿhmK`¾#U-Ç¡Œ‹&šDp}ì£äsŠjSWM+	F÷˜±3ŸÃkÔê¶S¦ßÄ®+İŞÄ°p‰şŞrÂ@ƒ—3Ä2<Ãâ×Ô/ššiâSHãü.¤&¾Gçs>ê-INnJ^L¤’å 
Z¼·îd‚*Ÿ,½8Ô®?Š²™‚Ü†ÇX|Áêë½Ò4£Ğ{¡é¨İŸV $Ï˜m¯,Ë	/ÒÓrü¶¨"SÒ½úGb¾üšY”¥i/?ßt¤EK%$”ÆÎ“J@‰3†Œª²ÜG9fD‘õBÈ–ñ]xèûªGf0TxàH»×ÛWŒò-\”Ğµv€4wh+Û™Ùnoz/g@“uÿ—P¾¼Í‹b†p‡‡º…–ù {Ä™Ï×Uøå¶KYAû±4E¹àĞäœ¥,S<˜ 7ÛW×¾¯ã’â3yµæˆÄ]®âğA›$rã¥ñbTò+2;†TWÒ¹¬Ntö}İ•c£­_ÕùòP/ó$P•İï‘Š­Ÿà …mğ%åıè )%õß€âwNzéö3ƒ[uW'ÿ±ó£Ø@9|Swíºk=­Kyİ®$şU±~¥‹,Lzèî>>½³ˆà4±>‰=ˆY¦T¢@9¢$Î6Ş¦¥6Xã´,Ÿ9ªyv¬  9ê‡Ó{4r]qG µšÔ¡Ş^?ŞÀììé;QsME¶EîJ’Í˜=ÈZ£##ğÆÂğH©B¯*¨÷
yĞÚØ®ƒØL+^ƒBDBb•Uüê°·æÕ?	ƒqÄşc¼D¡wàµé·AF/Ì¬Ê<"e‘Ï4€ +	&şRwFeãì×IO óğN‹QX¬i³Ùy!ö\¦ÏrS ‡á¹^és*pËsk;1œ=Äñ%ò"ağäû@ÆXÁ¦ĞlÉ¼uäÉxWÍ¯QX8_¼1êÕøøšú–í7v/Á¥°{­¨Äæ,•äéW] "Ì¯wø†b²GÙ @½\‰—‡§Óğ5¥Ôø‹Ì³MkdìD†‹¬İçª±LÒXËOZ±µ€1µNWûÿ]ã¯0~„ã®B[ƒq(7NL¿V¨LÙ‰”vò^c©ñŠeĞ[s‹Öãe,\•¯Flêûè?O¹&DYG¢Ê\^ÏO½ßXV- æŒ·¦6C¦öP(b—ƒÁºeÚI;dÛf0ğY
ØH~óx•2ÛoÀ¨ie`ZV·„¦ZXòÜw˜•	ôİB0áÔÙYÉN8OñLƒ‰‚ª<¼AAìff'í™Ü|¢ÔÎìĞÖ¢¨ÊK'‹b=TÛ=#†çq–
q#ª9Oªë©·í:m)îc‚Ş†zKª=Fi«PòßÛá"€n5Rôz’Œ:–.˜[7,ñŸùÁ¾÷'˜ÇS@^mñ½Ûó­}ï˜×Ên§¢|ˆ9Â³²å¬U1)^˜ôO±f"ºÂ^=,Ø«N½fxîm&uë»R”ı«ŠlÖµ?;JÏ¥¦~Ÿ"æ*œjÏr…b–=WÕÁçÙ u¤$cuiÏŞê1ıd*\$I¼,ÿ•ËwuÊèÊ$Â˜r´Ä¤±,ë£N˜	›}ô+×e;ÙÁü¸¯é™ëö%­ª1Øë«lü­Éy'<ÕŠ'zúgîÀÆëEô*e^ìñ¾ìR½îJûeƒ³!S›¤íîËÊbÙgƒX37Q$#ğÄ5‡<ø:poî¬Š6o wfÂOÍ¤4^ğ×Fıª£FñA'öû·õïŞVö&=ÍOğ4ğ{'º¼5†ø [Bø£íÕ!Bc³¢ˆ‡¥Ã}¼ûß,Ïsx_ELğhãEQts¥Ì‡NÂîñ›óSgW¢Ébj/¹§Ï¾¹à—GQ(Y¼“á÷X+Z‡Üf”,‘'w1è~·
aºcè¤T€*šOWæZø/"$³>KÃ[†¦r"¿_ª jÑHù, rKW@NccooÁõÛ,}^Ñ"KƒË"‡–´âjätß!AZ#cél¡–öêšUkí¹´§%>|5^@Â+mwÑÄÜÏ'·ÁÊP|QM‘518 ¦€°a¢Ùs3•”çV¼]§5#‚$dÉ´
](~)Â­‚Dìw¤»rY¯¶˜;!
‰ªõ½Ón}ƒ{Y«†æÙñkŒ',]¬€k¥¿¡¯²#k‘@œñZÄS-³³A³AzG¼Pe1©ü0¤¼Ä!Ÿ­’°qà÷°€Mfp’G_sBÇŸê­]ªu¿'š;LŞ¥d0?n¦P¡‚óAîŒO‡ã¯yœJÓ~Û8,+yLrŠHZøj2c”1_ıô–È“ èÁê¸ÁZ$?7¾óùÖdí‰Î¦{96Fë«X?Nº 7v1ÍâsÌ¥E­ı·¦‰Y-«ºõ;Å^Õî¾ñp0â÷Øı{5f4'´‰·T3zˆ//
hi»Ş•U ­şÁ¾³sÆ/6Ùµ‚«P®<ıË}xæÄ
{h!*ŠÒBªfñè?ËğœcF÷¥Xä\à¶n¢ÅüÙIBèÜ+ÚÇâdåre7%õmö—1ĞB8Õ˜ëÉ.sÎô,á…&`{tş0êvö3²ºxkG4yIø™—×¨§çç0•U³}”jn:.È‹üú—ú¹î{w¬üM+ôõÆj¨ŞV8¿†áY	Õ¬“³¹Û{wå©UáFŠ{·ˆêjz"¹TIĞQ‘Éü'L‘×Òˆï­nú›2ûï"”!šú«’ÀSxØÿAº±òmê[tşaGyo;°Àv´ó¥äQİïy—„0¶<•@³ÿğ@X-û€„:„G8s_Õ¥Ã4	Ï'"¢“Ç0A²Ärû½qÿWY<KfL¨¦ú€	9Á;Q·Æ8	Ck$¢†;CáÚ}X˜;–V2rX4¦ûøB²ı Ï”ıLFTİ6S8Í»Ÿ((@F§ˆ¾nõô¤/ª‰·q„Îè­75iĞ€î÷$!1½Ö$Âe@MB5Ê—ÄTQ	–Ú¹jXğ%ä¦C«ÒîI)ojÑLƒç ÇİŒÚª}©¾†tSó®—=¤cî!émS$¾ ÚKÃ¥˜Ç8Jîå³i®•úÎ—ÚZ6&–î9bfà¥–ÿ-Rü2ÕàËsrów§’ËU:´šTMüëğ !@ò¹¡C€Ïs•\“l‡—ÇÛÃœBú1’ø’²Oºcì±@'m“éÛı¢…ÙÙ%Èx+¤h_…$úñ¨§š°%›yÈ$kÔ–÷•x®-‰×Iƒn«êrK.oêgKiëPx+€=õY°8Œú€ò¡ÆkC„÷ßllı4Máš²i¿Ô=°ìkrÒ ğë.E]š„xy^üÑù±‡ÎJXhÄ=ÙLVÚN=¾Û‚ŠØ_©(ò3{p´{ µ¬Ä@›ReÕ•Ááûıæ8rØYP åNıGz!:º_ëƒeIN&_`‡Ñ)ƒüÙkÁñltÛU$fvºö5U¥[§Òöº6,\í¤#û P’â˜I–,²öÕİç&
ô: ï%4éy€0¦ì_Ä!*Ò^¬^Ù¸
iŞ'5%VJµ
ğXM™›´Hëª+ĞıØtıÔÖB•¢ãy`É°‡#¹í†âÎ€[”æ›¬H“Rã«
å3©£ÑA‡aYóhÃÉ‰U1ğvñÖÜ»"˜f¬¹´›ñµÓNT¶=™Kz+Eb~"Šq=ª*HIß}…ÈÇ}#ƒ´ÄnàWü8Ú±;[\E¾/’Ÿîô¾ˆõ”?=9†%pênyÜ×|øçyûÊO3ñTõT…óZ3,1£…fnLÓ=i_EÆx±ğœ*ø1»JâèµDRîrî\)>Àß˜#ÕG4N>ÊœAm12dÈ¤|»$H^Vôo?Æ2;ÊVæ`šÇ¼\Ó\õO …cµ£Ö§Gƒ"²v˜’¬/{'ó‘Øé`eeg6]k¿eÀY9Ùå+ô÷xÄ„S&€\}ãí·Ë°“@•â	;ˆÁé•Šı)Š¯ôÂ>’*H F~ï}O½C(I™¼mû1Ñ¹¯ìÓúOHİTCğ$R)™°t¦—‰·}q²‚°ª	ºÆ}™“ûİ0²"9Zt›4;<ğ&§	ÔE¥ÚIµ¥lılåv+"æŸe^ÌáØ…z£O*‡:‚ ã*ÂkÓËé26¥’]ÙB:±“àvÆ/3²?‹D¶x"s²mÑ¾¿ÙöÙ öÌsï¬ÄQ¸¼ÄµrXöºœ	—G|Ëj<ï]¦J]ËÙ9ÓÌF/Åµ’Ÿö®Rœú$8QOü;vZÀõĞ_ &õecŠTKç£uX7¬ñZ¬pÜTÈû!Rº>¸%
E¼”RRpIO%ØÖ(Ò–¿öKš´ÏR/ }è—±û¾'…§¡7«‡X&¤%Ëo‘åä{¶Š$láaùL×½¦KÇÖò%-áôŠ²‹K°Y|s÷ùag±N›#rÔšÚ+\Å+§µF/¡~½¤Rå#R/î¨¦İà_‹%¼dabæ\O·a™€0çr‚ä›éˆu:âš
LS§:£7ã-MÁ¹«¨ü}’— ËCtN}@>àMsLtWÖÿâ"ZĞ·ö-k´_Å4İ©ßÈ*Id û×îk×³u¡w,LE°ÉÚLàÛLé´ ¹´5TÿíF`Xš'Í?h©ŸÀ‹°wÇËØÍf¢iœ¥>4e7JÛÀ¡Nº<Û¥_™æúŠ3èH
ùê_¥eh:*–‚!/Š$; µ ‘çÔi§À/Î
âú¾_v5Ğåö­…ñÖJ:&½Ú#¹ÉÍÖ[¼]I¸^¶_Ôƒ
ËÅ¼¿›V$”#ØQ`cÃ‡àÆK ,µebŠÖá’ÖJ<y†¯¡Rá½B™,äT )¾7oQOµzÒŠXM$‹øÍöÖKC`eÌ¹Ï˜•Ï#]/|›}¥~|vˆŒ€Ñ% ½<á
0ÒÏ¿å{´S$dgÎÜû7HÛçS&V2[¿mÙ¤bÅ£u§ùâÇ-ËgÜ†qÛã1J2Å‚Â^p«PûÁÃnhÚ´¯³t[¦óƒ¤ìp¨S˜4.‰v‹Úyw1ºnRDZcù¾Ø’É_ËÈ`‘ÔNĞ®6·Ì†µçgùîRRråLë<=. w?ªâı:YÿískrğÆøÀŸ‚SÄñçgr™VÍØ:_…h6ÑM§ÜÑ=ë1Õ9\ŸàÇ¬
8]€‡rfŞ´ˆ²¾~wÁ¯ˆtĞà1ÀÍß"£¡]ÉN²¨™"O#J:Ğ°kÃX!hå%”4)=ÂSÌÆPƒÛ¥˜©I(¼ÉÚ
Ã|x«¬×¶_X‘<'&Ï9—]/øBÖş™¸¾$F†CRÅJ¶€_ÒÂ¦¤–™l÷ª"•ñ 9íøW)WPqÓúh@ögS{`ı¹®m €ãz\i4ÚbO\Ş¨4@¤´HJ^Ù2{8dZô¤s—­¡!áøË8	d•Å=P¶Fíœì¶bV ØÕıŒr´u-Ù¾Ë½U¬x7¬š†ÚïÁáã=®Şl–T’¨8*í^FBa¾»ş×hùˆ^7Ä$õã<”	Wõ*fÈ^åñ+ sP¢P…%JC3Ó`O*’ÍxÄw®Ä„¦"K/Xe2Ã–™eÎÌøQÇÀ5ÌME©ô†iÆ+1II d~×â÷Ñ qb$¡}°ªâ8ÕèŒöüÅó†ôÀz>`Í9â_õ¥±—Ùœ Rÿ4ï;-ÚÒÃ¦AÌç†è-aü`(/+gÌ¾)Ï[ˆ #Ÿş)–…–mçÿÜ#GN7óÚ¨"[»W;gOB-ÆFùzÜ™$E‘*ß	‹…JùĞ×O¸á»¡éWÅy¤†Ÿ†ÚçZ¯ÄüLªs*i	Ø°;€Z
ëtqnåî¹ø&}ø)1½;±küŒpüÃäÅìâÑê^;4Í§ö>ò¡YÈµ2Üïaf”<>É§`¹½ŒĞèä°"ÕF$'èW†©»‰yÖ#rç‚d}ëx~Ñ4ïÈoF­(y›ÈÌ‰±V>M¡òÌ"’rşËJÅ™Œæ±Ô¼®"ÉğvQßŸ¾yÛ»¤ÊÚš¢NUÔö‹0&’…á†'†‡.ı?´"ñ¨ìÚ‰jF¶]¾3Nã‡”cÓf28’uÙŒØ™*öøÈá†©šÄ»6†ŒçéìÍKQJãßîœíÙôX˜ÍÇÂ]%ñ`6Hò1ªåp°ËÎÛO—B+O[ÒÃXÊ+Õ†ìù«…¢v½z¬m<©æK9ÏéÉ´qõê{ Øf~¶Ì:	ø8U:64/y¨ÈÆ§pXtXä³ŒIÛàÃŒ#Éaî`rš1¼ôos’ØÌFÿ±hš¨‘OcU+òÜ¬d2¥İJò’ĞşÒ†©åùÙ½›ÚLŒÊ‰âSÉ…LåûÜãcÚŒ¾4wØ§­Úú|MŒIèG+€÷…“4TBØ„Œ¯$eÑKğ/1[8–2\˜ØZÂV”áEâ’±¤zé—IÛÈ÷Êb˜­gÉ ¹ˆ] Ê¤ñø¸MziÏmÖ<şù‰KúYŞØ†EO´7†-V„»Y{@ÇÓ~EAïş,FK{-‚Ÿ>a-¦>-5åëŠèLš†çz@`#zêUÍø2óÆÔ%‚wZ8=@Ùu;yXaš\Şy†?…yk&Ôş_‰/:‡™óeìé¡PVŞÎAáykJ˜X„Ô7&¸¹ãEú“u™t9o’s™DJyÔÑ<ô¯3	â ã]™
³0ê}çŞ“qq"'[æ³Ñø¬±ƒ[&¥ÆQv´ƒ>¤$~õŞ.XAkùF0Y«Ÿ˜¹åR`3Ézoú/«•´ÇB.95F¶:¤	ÚÂÅï»l{r]7¾Ûï×ŸD	ÿ¤bÁÍ³ä¤í¶yD[?î†?@"e5‹°øç¶.ÈPŠKµLíàÄíœaµì5= ×6ù¾-Lë[ç„õµ‹p\â4€;Urì‚?²“Qìtcù²¦šV<óßGjÓ5ĞÏ·ÓIG˜¿« ŞzBÔÜz=ş¡¶ıXuÑû¶ü°¨¾äe-hÜ³Âo¬:.ë—1¾¡nå+ÊØØqG¾`Lú¨±ÂëÏ½:v(I¯_ôz3	ıLøª™îà,÷AFı’t§µËªÍ³:¬¼ètE¢4%·UÉ#•k§#«Ë¬îkKÄCàÆ›5©+W¾°”²$ÄèRó$eĞÂÜ]qX+Æò8‹¯`ï­’Í]*°„#ûı[êÑ2Šõ·¼µºM0<óÃø—é*«>Üì4&}LFü[µTÑÍB=ïÈç—DùÑ·`i/
ÁÍ³á±ë* ­³h”:D‘Éˆ,ä›spNüÔÌ 1k;eSëÈ·½°ÛÎà?á.<FI—	„Bg¼Çw|C8}4#ó%Xüiµô6 õÛ¤Æ2EQd”t úÑÈˆeÿwzÎòÌäoúg7X‡‘¶zÁœ1ØX2È$
4¡ze‹œõ‡,Şy-€î¥(J¿,]å_'Åä·Å(flgÖM/œjÒ2*ú
˜¯œõ—‡»T´…ğñ-¦¥ 	¾~™ÆW_¶¯“²]&_Oöö3]%58âÍÖ†0iıqpÈ×¬+IU3öl™‘/ø" Åh*íÖï˜†£,Œ:èÈ]qn—…ÒÕoßPH8ÿjAef³>íÓfh,œQÀt÷Zu;r3;sRƒ^Ìª¥ÓÃÎ“gué˜{2¹İ‡o0ÖüjÂ«dĞïcéÂ1r|‰Ã¥õOÇ¶¡BÕ¹Ê '°»[CßK,ˆ¢®S¹¯²è¶­ÔPË‡EËlBÇp ¿½k}ÛL­ÉL´3/P:¯³Šáa1¯
Š«‡Ui¾Bì…Y+ÚlMÑùm©„ç]WFCœ…û±™
×¨RQÁ9«,‰Ÿ‹ú0A'g\œ&7¤mŞÌŞ§"ˆ• ­L•*ø>'Ò³å2M'ß«Ã4NUiŞÖùsaA~Y°œ˜ºg»òØSPµ2Aùçjh3WŞCüÎjmwİÎşÖ=å=‹k»OİàØààƒ½kRnWx©<ù5(ÇÊ"[öOËêMdË]æÏĞìxšaföåM«Ïš)ÜcI,b³j2àÒÊ–ë²ıíî†è‰‹’ï´_o$!†b}¦wÄ»8;ŸWÅ"â`Î)asÁ‹Å '…ëv¹Ä:¿…ÿËFj»“IxŸHÒ…ô‹ŒßâR–i$•Ìn ¶EmS¶X‚‡†3UBÁl©wŸòrW%ŠX-÷yº±ÖE¿£JÍBØÀÛû§rº—!ã€úÂu·òİ8¬°*ÀÀ‹ÆdÈF3|H•S’‚Îîİ =Bß¾Ï|Î²0RTMô"pö¤áP"l¨TğƒöÍÚøR\ØŞ×8µ—ÙtQ&©×	G¿7·»†¨W¾>ÕŠh<ˆûè±-øÜ°!±Z†÷[â&ê	ÒÚÈÂ[ÌÉİiºvü×ŸJ¯¸Ï`N¯»Í¡|¶Híœ¶ú‘Ûşğœ;ù,ÜïñT–Ér¸şN!Œ²Şu{îNê¯ÉæÚ€yH b‡Ÿ˜8Y8Üö8P¤ë GUI˜Zp¨>€"‘'5aìS¹rJ©Pa$O@»Ïu¼%Œü9î-Õ7¸äëĞ»ŠU¯Åvy* ÅÕEœ`É>åvÜ±Ä¯àI÷g
vÇEmVœ5hŒóÒàzÒòƒÇZÌ³mÓŠ®ü÷éKW5vµºç$aª Ã¢9±„0ğÚ†h¤«ªØş›«÷
wT“rÊ«øC£´ß³zx,®\L”»— Q‹j?#<É¬¶ÁÃ)¦ Ñ9ÙŸŒ$Ù`]}âÏ„’Ów‡øZ7åPL7VÀeÍ–‰a@uÚîv˜Ï¬ZÍß²î€YÛÀ*¸JbÄP2Î€sÇ37gİ†k¾×6YµPußJtå€°ÂhIß]¨àİ	ĞµÄçJş	K”´YGQM¨vpó€%Í‡õ¹£)j4$z¯~4):#F3Q©e^M äBÛ³²¿àİ†’^´¼äá±ğ\±› sÑ37=¨°©ÂËõ*oÅù«Ès®Ú}_òOj¶gĞ§BºC=Df©tT³W ™ŒÓæK²tòÍ¨r¬mRœ4ÍêrÈäû„S|U?Çƒ]Äø§}±š‚zO›ô@ÍĞL &Ø*–ÿŠ‹i$Ş	ŸVh]¡ìhNØa  ‹„ğö¢A‡	› üÍ£XI ,k‚{XZrÖbûÍÿ±Ç¢°Ï¢[šèhÔ´ŸRóĞ•¼SÇ²lĞÕôv+øñş~$½ê:èœ÷om‚W	3Üúqğê¦•-µæ2¦&™÷MÊLNvsT>c\ßãE/.Ş]}Sö¯‚ Jf¸¨I tWrekiuT1GšCó›büõ»œŒ?óòã‰ÇøˆÌÒ‘;ÇaÇ‘a‘°*ÿU-Úf¿qKÉî·Qé™*Œ-(¬À2(øõcc´gQ¾ÓËtOh%ã"BI¿Çú~•„¥\«<C¦ŞaE…Zcÿ’¹Èb(+Â‚m^ì•ÒEğÑÙ…R¸ké…Iƒşw™ï0¸\'Ç.ã‹-ÁŒøP-³ÈíñÕí­{P#4ïêËgM©W#¢P£–æÎì¢Ã¶	«ëIŒY$’Øf
’LÑï	óv­"6“?×tM±é„×ªf¢ÕlÁìÖÃZ®‚“âòÍ‚(^&Ïòò~ªo=åà6ßØBø{”0àájX<aÛæúİé#)i°à?ÓïT

^®Ü;¾µ¿Ô‚'©h Y–Ş´ÏíIÛé³|p%‘ªĞZP¯üñ«8h©Z‹QƒõÊJcuˆÖdd¨*ú¼âÜ‰ĞG3ÀHêì/g I#IßÕvQX72&”Y¶¿L¬Sbµo=aí:Ÿñ!T5©Z·ß¹’†ù(
~f¬˜©#õáµÔ¼ÈŠ’PM’#D<-úĞNã”'`^µQ+,ißd"ÀòzúÁàW”9°=¶bàÕQ*åì"CÒ‘˜s…ÑJĞæ€˜9c9éoh¹øy&Û8çKBÓ
¹[ ğ;üšJ„'Ä@xC‰Ü‚áµœú˜·©ÖWˆÒ¸ÇĞj'iFÍ#˜µ4ÑÈÊ[ğŒî *>°a½ LàMWs7÷qiÄlJ®‰qÇw@Û3
äµGKö»<-bB›×KÍ×¸%r-ó\<ú$qL}d)¿8ÑÿEÑ~zÔØ£şşÔXâ~Ü<æs¢pm¯\xÓ\¸ÍÕ­;ã4ù%Xê7wë´¬®7Sæë»àùÑßI]úØ_í€¹0éĞkàdbşö %iƒ¡ÃwœŒIe»­×E¬?·F:¥ÔfĞôeæüÁî…lü™ñŠæ‡ıÄŠ™ak^²!^ÈØ¸gs<z”ÀiµN»£èöi*«©Ná˜írGÆ\6F|Ù˜›Ï¨:§¥Ügÿ†¥’àXªœEäÊÀ\…XÈbõy÷–Ş&lB.©ˆÈè× ?ÔŒC÷ş‹¬écEÜt¶ƒKšäQr…û¡N$tŠ×Š´0İ#2}ä“9Ğo1‰-g2>æ ‹8ıj¨Q¾Î—…`xˆ™‡ãÄÚUá
)Ğ)ì† üĞ±6(İ1†¹‚Â©°‰îâT½À'ö2ò!<¦ ÊWÛÉÖŸôo™E÷î±HM“ßU-Ñ¥ ½oeá®%Ò¡ÊIREè[¢p¨p` ›zÎ5‘5‰¢}?\=G¥£¡UHsóÆt ı‘ÅæMT¡GâÓ¦EŞHÖñu¥Ã6WÁ{ÊÖnÉ‘şf—¿ış¾Mª¹ßé‹†ù²¸€ò3–ô@\Ş.‚¦¨‹,¥™•w‚Ş7è1ÄÚ!Ä™§»!á_GZœÀëÅ‹Åïõ’ÿ†ÉUX*ŒÒ' ÆZ—-gÄÓoÏ=q¯øY†…ôIiàıÆ
¯Pın„'I;êjgW&o¯ÖcçSO£4ñĞß,×72«ò­Zl¥Ôj6ª22Î¬ˆÃª—&u Êr4h0«`ù‹†‚c07¦HÆä&.F“Ş;ß®"¦àşó&$=k©Ãsfœ&Ñ^l^Tƒu	¹9Œêºô›ÃNTeÁŠq[n ÙbÕÌ_ÛıÍ‘üş<áNØ72È÷ï@¥ë!¬Ç†€	ï+.ú)‰‰-±4Nÿà
T›®ŸÇë(åP‘%WE-8—¨Ú°m5?+ çg­.OD‹æ5Ûd­¢›ÇY¤Ï¬ûÄ{‹¼ÉÙ÷ƒ~Áô(M›9¾ëÉÃŒØ»Ë¡Õk#Jç.€Äõ‘¹
¯.xV4‡:xgG5MìúÄŞ“Ö=VùE“¶’?¬»o4T²éÏùñ,Ê({eƒÙ>j$5EË¯ö1şe>5q‹ĞÅ
²©Oíë” Ûñ´·‹X'ä‰
`Y'k¶¡OR¡Ã²²ïƒŸ¶Ò?Ø]ıØ¤†[¿^„kÔ>ş›hì;VWÕ$ªmañ<Î5DAßÒé‚nGsfır,||l«(?}g¡÷Øù2ÃSacåŸFÏŠÛ“ey·3¶ä¶}Ğï=µ˜q^Wc18 lğìiÙ@õkØ°6nŒj¤x3âzÏ²—fdÅ)¶ö¼D¤²-(û@ÚAŒ?è^“É®l§¿F†Š-ùİ.Ä½2à¥Èá|ô8!LàG{‚3hÛ¢D´Å3Dóç\ÿœŒV:—%k€³pÊò®ğàŸÕtº_¬Oån3òšúø¬¨ÙÌ_r¶JõÎc­…–	Ş™j+4Ëç»?A$È9zçË[Å`¨g8ƒnP™œ'Í²j;ƒĞ«tÃRß`	Ö‹@Snœ?û Ô\ä¬CöĞ*>0ÔĞGì~* ^\>ÍX û‡»üº6+'\›œ€gFa›]¡ç{m64Np„ÛşÜ¾Š’ŒòèİüMÅ€¹rı0ïõ°nè¨T;VI-şFóx=Ò¿º¦Bò•¿N`+ÍTŸ_)Vj}óØwjÉ­¨/ÎD†)-ØbîŞÁ"÷è0ñå–6}Úôø|QòmYÔˆõ÷Òu'k8¥ƒ±´ò7Ëê#*ÇúüÕ:ª_sÿEà”ú„hë–;¶Â0lX•ùâË~<(9h“û«™jêàüÏLBWWõ#‘Ìû¹cæ¨[8§ìrÎ7¤&y§µµG·£ëùb¸€y1ÒÜ€™›Ü÷ˆ5¢TâÍĞ“œ]º¹”¢Las˜†•’¿wXEĞÿŒÏ ú^a°ùêF¢­Îí¦£ço@õ¶Ìk‘.7`êÃ9¸zBÙÍ}KWI«ªÃ¯ªîø¯Ô–1iDÑD€F(4^¯au­Ó]?ˆz6ygùAË§¶¾3 #ÒÂ1¢téAJP÷D˜Ô·ŸÍFK6}lîĞÄMY* Š1ˆzHu¥,40ò_€+Ş \Ğ],£³¤¬úPÜ-¶¾ïÚ+D•>ò)d.=îú~ØI†3ŒE9Í˜iÆ³ğeËOÙ2Ú x•µõ’Y>Ìğ×	&¸ğ¾S®S…cØ}ç!TÄÇE¹€Fš…®TzïcP¹hìMè+åkås¨j$şÍ0Óš³¹˜y.ÕTéN—Gk}´q³ÙëÒÏ•baë§
Ç„6âz”¦X¢‘òRJr,Ñ/‰"ÔFÂ¾€kº¡	xÎ•ÃÃŞÍŒ¬b3s-TåC4‹C€~¿h""–
Å·úÁ	LÁ|uékşŸ¹;¶±lízğ¨N$:çO&N¹p7i7Äpœ=K¯zg z^“–L¶X)ğ	qÉ­Ğ{3ü7–]fÏ±é„œ*_»O…²úÃl|¾ílrz`t”ÆÎ›‹ï´›Üï¡Fà7¡ÃLŠ„OòÖ<U×œ=?|¯@ª³øÊS #ÀöÂâíØñoÚrµøøöÓ£şcÍõŞÒÒ(¼ã¦´NÒ[„mÀµÌwÎ(@À—k=Xæ8zµtª–üh…Z!O…ı£½Io¢8ä½gHÚ”t$Ï5Z{*	Få4ÓT[€0QŠö‡«~ë>àğ•ñâ‘¸crú.¾Æ¢Óø½€*áQ¿Éîéˆ3¸éÕ’0«º³^~£‚Š+Ñ¤~¿º­Å\,j¼Êò°YÕëKzæ@=Á³ª¸¨°ÌÌ÷$#·*f§©K{ÑÓ"BZâÈZiIšoZ(~$j,µ*O“xæFĞ¬Ûz²±şóŠGu›.€›Ú)^çgî:\İ“‰&¡ışH^.¥ÿ(ve“.W3¬éf÷Ù’U`¶›kOìˆ5mõ
ú1V¹ãğí†«ôÃ,ÔØA$³W1 â®Rê0ú¯êï¦
ù8c¥N«&/|¢°/¯ôĞ£¸lˆh~ÌĞ²–)¦­ü[²š±æ«5t7bPâŸ°ã½í‰*û),··îÕ÷I^s˜Ìğ-?È+%
ÉP'ÜÀ±ˆıÌ“Ï-´ä‹¦tºC1,cö<²Yo*[Ÿ òJ‘œ¿,0ëXGy)Nqúûû°s1Ê¥§(éÉğ%»7Ì¸#hò³UnA&ƒõÿ³¼ú°Ä½™òÅùëBó4ù˜ıiPQZ"ü{‚in˜^ØÎÆÉÃÀV˜.H*¤Í`ëJ"Ÿ´'Ñ¾g§}•ß)èxÛXs»	ÑB5rïòÌ—=ÜqÌ•ÆÉÄÈò€zÜİ•¯(‚™Ü	NN)¸R6ÓvÄfğê¸àTŠ+/ãŠ$X¿m´r‡Òkîı†`k¡‡ÈA^R_Æ_ÿ,“ÙZ®ìØ` :D˜xK¸¶MæÑôÜNû[HtšîxÒƒÒ² mÏšFˆb`¡ÿT´ÕbE›Øö–c4«äL’~ê"­*‹N!Ğfô ‡†O§¹ctyºéŞ¹Ú&Å×s{ZÏŒÏFgEg|Î‚aóõ6ÿäfî§¸3œÓv²»Ÿ ´§Ty"øq2Œ<8—µ¬ü[ËÖtiƒÎï‹µA(ü"–‹È´äTrøY;¶lKy"ô]5R]×şı_ÿÎ|¼êä7±Şğs
É€pz¨S‘=ú6+ért•3îØ NœDOƒñÿn¹(z*’¶8œg¨ØıéÁ´§/ùŸxZ˜™®Ö|şıÉ_™diZ	ÿé2.Š0U¯ –‹„eŸ˜)j¸ÔôÒæÑ†_õ¢›_<š[0	•©:ˆè³›ÿ´/rd7B‹âöd¿ÜŸ!§Õ»”8fÏ—!2äsD<š)ĞtŠ´“²ø*	h1IdÜP#:b,cwÌĞ«à+“ŒMŞpó¡-(aœşK¼Ş†€/]D‰˜>¬è)Ï2à_,XŠ]”=Î–ÊNb<;-ù¨€¿\–ÒÅ7VûÓ–ÕŞÈ)^%£OVÖ×ù^ â\'ãöP 2.â5.™Éí§vXÊûÇ\”ZÉ×U˜k½%÷ ¿²HÑTšfÙØzĞB`¤]Hó¬óªÓi‰œ¯õ6÷ˆ™Ò”ºßùĞb1Gº %êq~Â‰ŞŒS¼eYšÕ”Ú{L“ÍÆ•É<†¹•èÒÍG-úKQ1HN\áã`ë:˜u(ôF°¶ä†Ü¹C«}÷²!Å¬!¿¶ã(O0˜İğ'µcİ¢Ã}äÂ…<]ëšlkÏ¼æömòº^í@–å:•¤ğµ	/³x,‡ßÁş«}Z7ÊIÔÌÏ8Ú’[“÷¯/ ñ\ÃØäª¬ÉA‹¤]üî÷M¢+8ğ«‰*vø4×˜¿h¸a`¾«DÁZdÖVU"&Òeù738”Mè~ÿU0O×P¡jFNS©IÜrt’á ê·1Í±•Á sSØXì®oÛZõ†0/’É²Dp0Ç˜—‘ìÅ‚2¯1åñ¡ğÔ úê~°‰l)Ìµì·ŠÍ
#°s™…À×¿õx ³ü_Y2¬Õ$‡m›mf}X z`CÈåMû&×M®Üï»ïªÑ®Œô´I8…’èÚŠ/Èõ>ÜfP7?&Ë~Ş"‘ñ	Ú’‘ÊZÃÊêÕòÜæ¶ÀÔy“óÙFJ(Öãô‚ØÄ	]åšvß03À1
ı×Ï¡£Xç‡èüiÁßwˆuJ"ÅĞšy‡ÂƒÇ|vJ¥‰ªZ˜!”ïŒ@®XÍ	dVwH%Êè!¼E5îI38ôÿD+‘yµt_`ö"ùc¶­Zœî¿;mP±­18]t¯™üÍÇ,É;^dÅ7º@öL)O#±ßa%İœ ±Ä£#Û‰*ç5éÁÙ™DÒT8.OpÃ—[™; ¾#Ô¨'t…ØGá‘gˆÒ^ÇJáœ¿ù™üt2­4ñáí©yºÈSòp»={dkTû\kµg¥Ù4ÂägD=¡†ú ¦@z:øÍî×öç¾©µzJ§öj˜Jêgc˜bSÒ“!à&³ÙZ+ß7ôŞ>jäjcÜ®A4Eër>vÈO¥Jó-<«˜¼´:ÎN!„*2lßË”½¤˜âR‚Á°ƒ«ãÉg)\Õš‹÷ùVFÃ:?kyÌU#¡ç¡Ñ¡á"…k½.…’CúiˆÁjÃlÉàIg¬é"”õÃâq¦¾ËÑcÔ…[.Ú”N¿(ıˆ÷õ}šìOœ#Ú‹â1ª’)U
[¹;ë±İ_‘õÚé šxq7õdìĞ7˜¼a»Xˆ¬Ì~Ö}€}÷l(!øƒ¹·š·09¤‚8<Ñ}ó‚ØZóífnÄ1øÃ¡m_¶?‹Üî,²›¯@=hÂå0©É¢ñ:\2Ê3æYDøøÁëŸ©?¦ —ŸENUŸ3iV’‰ãE‹€UCî¼ülÅ2—@´ëtkW—q•…×
w¡*Óù—÷Õô<ïÄE
#’![mŒºW¨#ßmÛ»Ãkò®(4kFØ³X[‰FØ¯…˜4špãCù‹ÔîƒÖ'Û‚lI´MM½O©Ä½Äü¡AÚ0'İqÂ<Öz¾Ñ×p}Î~qÎküG¶
y ŒcæÌü`›iËu
€/?5T>› 0Ú?6¬µ>L«Ş ‚V#’şÛÀŠ›J3¾ñ¦åñ¤-"»»HXå–„ÅCÜ9Êp&bçhe÷F±Ó€®jú‹—&1£Ï]`‡¾Şæ—Kğà†IxOb
7ñ»r©O&¬¯N?…9Áä(t“ï²ütĞ‰[KËŞÅÌÈRC„¤(ù¼s]ÇÍc{#‹åÖk¢8ÈÍô¬2s, şT^'t€ï>äGÉ-w¬ÆÍ )iœ¾G:Ğ3È¨0#ì;sÉ–¼æ4°—ç¼ÌÕFĞ¿5W‹ îäc`¥Øë«Û²8›m}}DºÜ63„hÈWÁ¦
½Z49‰Ò…0Ñç×Ô#Q2ì"2—xqÜ’ğ;O87õTaáÄ:t®·Æ°GÈ†üzŠ8,3Ò7Ùù}2lcwÎæxÛÃ²°Ü´÷¼è`ÿëøÖRSß³,L uIEnµ{Îô¤×goÇ„P3Äê=š|Å/Q`L$B¤ı\Öã/^(lÑûA§°[»s\y+Oùmuö¥Y3¦äBˆHz0X÷’6CY®Uq],‹>wSºAaØÃMKô(òP¾‹TÔí¯N„Šæß¬Ñ7Ù‘Êşå½Á¹×óZĞø‘4üš¨5úˆ+N…‰º¹A|)³ÁÀJ@0Ú5²­S&©yMÚÁûöÜÀnâÏoÅõ¸B­Õ<İÒ¡oÅ¯A„F‚2m_A«ºœ©5`æÎVß±Ì«R¼SİçëQ-Z…£™‡ÚTÊP %B89„\øŒó§…¬ÕÃ+I²íë3õıdåG‡:|`PÖºhë¦øæ¸ènòb˜á0ş]ÑÆOÔæ_R_Æâf±'“I'ëAH-,ÚGwS‹y;lE—;òÅ¥Ãzz%²‘Ä{©Øm¿zC‘d#mhê,‹ÛzƒVØ”_úQùôÌ5¶R½æÕÍÒ`·|E×<Ó/±_‘Ã­·ÕSM8æ…¶(t± ÿö3ìï¿»Èi”±fò[¬[™*N»ô>¤g²R”>§€ö0tšOíÌ¨)RtÚº*T™Dõ‚ÇXL©Èoé(¿_œş^Ÿ§o½.·U’;õ|ÿS®r¾Hİş…†ÔÔÅEúnçÕT«ôiåbàâ0E
¤†hm3Ÿ~_)Hšcõ£NÃyi7Ïä•ü¬ŒÈ`mÌâÛIWÙ ä$¬ı£|‰C(—³Ú¿z¬ÛÙ“Áe«ˆ+Ã_»5¾#‚¬šÚŸ¯¾
æ<Œı÷ô\…À%7¯Ï}æÓÄÏ‹¥U	Ä«Ê¨ÉÍ•¬#TBe–G³¿Ê!£g"¦® ïÅúÜCHÍĞ-¿Ö4‚9{´1‘½9%¾Jwf´ü&jxí€â~ÍÜòA4¹ô²3AXÎ´PĞ L"ÔáTY1 0RóŠÈ!MûĞãBG®µcÓ”á”¹>1än-,»ôÏ§k·|ÙÒq§ŸI6…"•r•¶»5é)·?hîhğ£ºí¸Êh‰50^ aËXĞ®ôÚÍS2_×“Ÿ~Ÿ}»òy˜‡‘dUªï} Ş'0kWñAİÄe«=ğáìûó©Ó©DÔ<@L0fæ&e‹k®‰Tú„?1thW
˜^q­ü®Ö\|ÛwªÇ•²æŒœnÅ:³òıÍyğ‹Á#ğˆÿ¢©ª]4Å!j-ê‘è
ñd{”=ŠjhS>y®JldÄd£	ê"tJ>t GÌ*P>ôF¹=¢¹Ğ¹ËÉ3†‰Q§÷_v5
†f ÷šŒ*-l‹êyÓÍó‡ì¹Ç*²€^G_úR®+›şœäiîƒé›v#ÆÏ;xn1—÷õ6¶ÌíPö$¤+(7t,ğá‚5i|gë•İ÷Ú¯êE6ßY‚@ÖKW¼¿Ñ·+ğ…€]Pıh%í<ÿ
¢îj$ÜâÆê‰,fyç®3»NEc,"1ùOëÖwøÒĞUm¿¤ËH EaêDØ3ªóñ†µÓ&èıõñˆ´§ =»õUDÉ…P–ØÁCc²ÁÕy‡o7u°$å‚¨±»Ô‰QÂıå!ÆÑ}rxÅH¨‡Qç´‡z@"¾÷òáÂ¼ÍøI`¼R¢FzİÈ¶Á(¼»AÇ]o@:¡IE_N³‚ª™ÜïhO0NTşÁ?ÇÍa`@À&<ÏÖ-›^ÿ1]fäŸ^<eà{³(U8qŒQ•Dyû]–p</tÊóIªVÑ2v! ”öú››Ğ¾YÕÖµ<u)á·ô«°r?ä¾n¼v×Wñ¸lÌ²Ø…8
+ó)!@WŸ-Äğ„	XI]aÿŒ˜s[$()ÎA±£+9ıê4j£Ë}¹S±ÛÕ*“6PpcÉû=›:]ıÓ:İ	¸ÑxÔdÄüªÎ<Šn~$Òy$JÛì‡g'@jmySˆñ}ZÓJ\M¼ÒyË-”5ï›C¾v`-ÎSšÌ"–¼4û9\W/ Ìåi~qr(!j¡N¢¨ŸÎ/‡Ã—†£YUh’ÖaÏá†gûm—?Mò‘ÁŒ’4NQg[ïZ5½„ç½æş6hÍÿouÄ})ylrÉ ‘c«íòCµô|t©Š„¨ğÎœL•d8’ìªˆõTëÜüQĞãï‡²DpRNæw QÏE—XºóŞø®Ï9F¶ë®aºŸÛ)ğ´òÂù%~Ër7;¶ûœd0Æ$èM³¹°¯;x•ú´rpH³ŸÒº6T)ŠJ¼´ñµÙBo‹˜=X¼¤Ê
IÜs÷`w‘îÙÕ¼¨ÆÁöØ¼L\Şİ?Î†höšÏÆ/ÜiÁe8üË\ÇsX¸Rş÷|=5Ş¨ŸbÃ+ıB¼"Ğ=x€ µ’İ\Ñù¾;ĞúŒËøñŸ
4ÿFMy†´(î[„û×ı¿\æDiZÏDÂå©hÈıÏ»ò¥„t€ñ
eQdã•9Gó´Õ¤Ó‘xZ7DÔ\r§Iœœ"u6ÉU¹ÂK¶±Å^Q‹QÔî>V`X,º	ƒCÀÂ*©Ì Í"¥–ÏÃı	Â±¥F¦^¦Âô}¯¢æí¨Œg¥?¤“¤ó×ÍÄ\sFó–	â—
A9ğ<³(	r¡\¦8s¬@Z„¡¡¯Æ³fA'K5Z"ÚÌ§ü–Ï¢moìg½\1 ĞÚËØßHKS áÛ#Œ}%é²—{31·†â.ql=KA‡B@ğîıPü2õ+‚L+ÛPÂJªo®²‚[z¦Gkroã§!H|5…pä3° 4Î—´+ğ6»—2*åƒ•5©íøä?=Ì}²CGñtO&O&õøíÉEN¼5jr>B–wÔeMÚüv†ºş„2BŠ±]©ÕÎOÿ×Í™÷Öò+s||Ó~«<n„Æn*ğé¤Ş†öÊğO~.ô[ûx3¹NäÕÆq$œ+PìW¢.Å™åòjŠá1ë¢q×ÓkIÇÓ†ğî†Ùm^TpÛ!÷4$ÖÌ¬bgå‹j»…d+8ó;Ş‰&¶ØP_°ğãÖ	 ’t™‰¶âş^gKüÎtÅÇ{§÷gûVğ¼õõ‹×)+VNµÖ‚¨Û—9Í£0t6åôÒø¢v@(Ö€›‹„jù±RxŞ6İ8z¿x¸0õ,©in+Û×­‚×V“B$ šÕÀ‡ÅœËïûm5à®³ œÂÅù‘O/€Y öÜ§<½ÅñĞemvä®eÇæy!C­œ¿‹ã4ffm¾MÓúò6¬‰Ôã’¸uØo5!¶(VfÌİ}Ó#AñÇ{²ê„)ëqF ˆ‰	jj­­NM4Ó¾õ*d¡•¨(QÉ‰¸¬ß¹²“ÚõÍd’Æ°^ˆœù“çğu-ıá—A|ˆİ.75sÜzÆ½u·‡~QçÜÏ2·Kn¾Ü”YXRÇ ‘kØœ–—ù¢Tux•Ê]+¹ñ¬OÆXÔS²œR¿æ+‡ˆ´ã![ÀùKöï„Y÷£l4¦g»Ğ,F\Ú¢W6tÊÜB#g¤à1Á È'«ÂŒ_æLC’lF{íljBA(ƒh?†Ü1Oó@İ÷}¬}¡RÿŒ…Ãe!ÜàúE‹bæğóû–œO=Ÿzà[Îpuû[«2ÇĞ{¡‚ÛrÏnĞW¼–Aû¿é¢10XŠ3IƒeØ,ŒUJK»[ù éñºW¾:qé²N‘îÄàŸ’UŠİ{(agTÜÂıq4Ğ0«XªG´Ü=º@¿½ğòÜ€@…AèzO\pJ^÷­cÍ…Ë!|T¼YNS¿Şøş•ªí°ıªİØÿ‹Ç‘][ğ#• KWJÁ=MåÅÏ
E…&‚Nx¯BnG¤Uoó¹·›}2¾ş# £ÈÅu
Zs8"ÏÕxtÄã©!Ç™l}\ÁÇ0õºR3VŠ)aï¹+«>Òórü¡Åİ5ÊÒlÎdb€H¶ÕPãâhCìúßyF¸:.Ği¬37EmÓXD6
ƒ0p9ØÍÄÀ©H¸ú¹Ge³¡½;\ë8ªìÉ;”é eÑ‹õûÙßl¿r$mæäèİ>y­óäR¯æ…ƒ*˜)Ş…dêP=5Š=œOìLFÌv8=nJ#h1DÉã™•İÇS®]}ôĞ*ê<k˜Rùt…
·ãØ›ÁŒK‰°NsB¡/‰ğ¼¿µjËğÄğô8á3‘ĞGvA“S/G¿ï[æl„ÊH+ÄÒ;J Ã¹Úˆ'uJ9ó	sîtr"=sRc‹s‚¼2âAO ÕO“Ïë\ğŸ½KÌ
ÅpHp³íOøŞzIdVd>vsßíØÚ  èYõ¸ã¶ô	=l
”1¾4Ğ­óÔá—¡º1q³×øó>|T<i¢ÁÖ>û”R|>öë¯_Ëÿ®<ü^ƒÄ}›´Õì$'`¬ª ‰AeXrkE<i¢„|ßv!²œë¸»õ®Ã'‡^<‰ ùËˆRDQØ¶Bbø¢ ÒDºı8N3¶ß¦‚®ı2Ù´±ö²ªm\áü ztÊLád±RÖÍ¹"Ës˜×¶{‰dÖq©vÁÏØÙúF?b¤*ÌøĞK¶k¿#Qª!º•¾N·&/ ÄûœOü‡.Rlø‰ê×Íú³O‡.†wB·¦nÈRµé.g,j`Æ€g®yJ‰Ÿºte¹—qQÇüqlß ^Å‚8béÄ¤/(ßØÌU|wV³ŞTU7KŸjs/î±tòõ<ñÄ5±ôí2­u»Q•	d<è/ö¥ãˆJ+£ü~Âf!„Ëà·Áœ¦İSÏ¹s©xüRq,"·Ïš —Ò?¯5­ã@Ä£t\ÖÙ*€†#Ã‚O‘£¼¢leĞç®ñ".g	]QşOËX§ÌUU%Ùı¡faI\‰Í“»Éë'UJµl±Qz…P°×p¡€ 7PÕÔ¡—MG'\| Ë.îo¥;pËÉOhvÒÚzß-‹îî"x~¥¾yu%¶½|™ 2u:”a&­m…`ºéHwÂ­lSğµô2ßJY¿'?”ü•nVÏ§^sÄlSü”ö.É–õ‡rŸQª9ñş“š³—©(øôÎœ¾´JE±¢«Zeï£ØEû«ÀlòüÕê30İ•X¥U‘¼"€"-ã’±ŞOÌ¨Õ±+_¦Ö˜}ó_“ĞV}Lt™hIÉƒg@~­â:ˆaÔèoNGA¹±Ëî(Ú|‰æ)'ÙCŞ÷Gèµsôİ‡õ0ÌÁPİ™BßÅZs0`\CÓ3‡ëÁ~—ØlµôâÏi¯OÛ÷k]í(WµšÒ°
·;1šOÉÊ!ã~€Z¹¬ÿl¥gìì:.¯ı`òûı‡{ıéŠÔI¦	ìnÑVzÎŞcH%--{¡eÖfÍ}¾z³ª}ï‘+Í­z¤¿ùH´£Q	èAË
2gƒBè] „'¦RàºÁ ÒøÔçÙ &c]¿¬%ôØµšù§÷›ƒ¹­üjº{ñ	ıIşÀ ½±öpkô7¶Ù’lz†ÜØ²Ñ¼¡èã¶Ô¸ Ÿ`%7¾˜Ç>àYDûuz.“îl|§¨ÊÁ@§•éy© Ğ4Ô94GL®ĞJe-Á›K¶ÂIİ‚/}¨h …æ„SÃ_ç£
Ì§l×sğ1NÛŸÈ¨‘.“yXùœİ–xÀhĞ¯—Ë“ucccù8Õ½îç\Uw,ãõÌ”¯£Gt#qİ`\@ğoŒ`Øl¤ø*šğñüz"m8p‰¢I\ÈÔ“•İxÚm@¶óG <XÙóT€¨jıÎceÑ©:N;bÏ]›q¦”­ë°|=ui5;v“‘‡¹pUrc¦?¦íÎî]\!6)]1ù½Ÿìj!æ7ûêì¬ıİ[·—„¾f7À+sœĞ<a˜ë¾ ÛW«Æ»;a¬Õ€±z7.N&k¶ËågµÍûÖ´åèm¼ş*"Ãc8¥O§;¾Üb_m¿fØè·qØ¸‚O	_Ù’ë/%ƒ(ªšJ?h²˜Ä& ıÛ2bÈêËl…ºÆíË,ı©«BHR™í6¬ÎÊïlÉ©­ÎH’;d'5@=‹€„¬“Œ¹*öÑ¨r!ªëH~ÈÖµÀ·â*My™x¿Ã}Ù¥¨À8Ÿ§tÚOîôŒò«th‡c¡Æà©´ Ã7 -BÜŠÛÂ¿åÃÍZœ1ğO-Â33ò,MR‘ÃKX-dvî=!w2#)—å¾ßr§ÜÜİ¥>yLº?ä¨‰Q_Ç9ÌnnÛ_ ×7×¹zGn‘àêaV³Ü6å0?Ò}cBó>xræR{¼'q•	œUm>2Í‘±Â%LA^hµg“êûÌÈ_¸ü¬g]n¾Ò2WéE,-…ëİC½H‡”ıiÎE¡ÔYıo†7‘—[.~Nœ<ki1Ò±uY¦ØwĞ1•|ğz"ü"JÊ†Q;ÍŞHêK.á¼'ä Š,—ƒ¡*ÌœJ„X²Òh'B´¬„–™,k¸¬-uÎâ**ÉTÅ:Œñı,P¶©uŠÏ\ª…ˆ™ÚA·dRåNqxá©p;DBÂY!$‹è|å¤,øMDÁAs.ôvFgr‚åüY¸ØbF€c';óL;ö{¼tBu˜—Vy Jˆa/º´ky¤¶hla—(½İ¤êœK3ÌÄ°äµdf3Xäi¢æ]x(“…FZ«CFé˜Û…ÜĞògF2ˆƒ™B*Àhßƒ_EbîT&‡ ¢B£¨àê)İ„î¹ÑS{@è(ÍbàLuœH¡ãÑ»èP¢‰âğµtØÔì-Ÿ”7zúdõYG£İúk[p3°5Â¿“¸j{î„cy{öúGï2ªJy´"Êéä ;N
 ¿uï‘¢¢qU ™¢¬bÑËH“¶°‚kÓ˜MOò=bŒõ£"=JYD±Şß4ÿ¿kvü,
ÚÆYh%’#ƒ÷ÈAñ³´ï°dÃ¨	3¡üÔ%©ù—/{Û8k‰#QÇ5ÂIQåˆ#¥gÖvUH*E¤ûTúÍuÕcBÄ-òçâø´q» p²O;mÜLõ1UèÚäüĞ„íÖ¿<B]ˆaŠş½hZág´x2¨®¬ŠM¨Eü³Í¾ÚŞºï§s¬şBëÍ9ëªÅ¬ÄzÌ²±¿~×™V’áMvçì/E„¤W‡‘82ºíaÙåyáHŞ]RóßÊ`Ñ›¤Â[$»8¿ãZ#š.œüQv‰¨!hÈÄJÉršäù›¬fƒdÕÅ¯)ú‡e+.Ç:Ê?oø4Û·zå]3nŞ@ÅæN’G÷æ£ö÷m!A}Bgîl(ÎíºÂb
VÊmwQ6H2#Ş8·ø1`£²êU)3oSm±½¨'àŞØ)^wÿéoû°(ib’9’9¤jKPYz†e¦˜ÎEsÀ²ƒxŒ®ıĞAf9A¥¤E¼UÆ9¼+@8jp±Ñ»âV=á<¾>–Ğ†‡E[[´óGNj½É©9O×ÅÉ~Îäàçõm_Še@'Üí>iõóÿxXÀK|AŠtÌ‡²«U)õhï%UÜ¹kŞ™RŠıÂ‚°ï´,üĞbÿêĞ?
5IIGµPuˆÌş"t†zÔã]€g²u€³¤<ª şV7Qõ
éwÊëXik÷w'¿¹D€eM·N'òÖKåphªœn#öö	@¾œÂ-÷¡‡u6'°øætJë2_ÈxB|È/¶[<gŞA¥¿Åo8tÛq=aq½ºj!ş©Šéû«»ÒúÔòÑÊXü°‹Åu q’l—5«<‡-Å—‚\8Ş¾~â˜¿ÙÆ¥°PB1ÌÒCf¡¯¥2på×“oÅÆ–×òÄ|¡;E™!#*êÑ Ë%ó×‹[–.³¹gÃ(r³yã*hÅ ¢©¨¬>½û³ÿìûĞròu›¥?™Õ%½.¼˜²]›}*È]%4Èş>aÙmü§^8Q‡øİy¡±µÅËëáJì_,[êEj÷Ï·‰‹?ÙEúÇì’˜i¸Zö%	E»Ö­¾a#pO¬}Fmé´¾«õ¤ZŠ³ˆV{ÃMTœÉf±ï
Õ±–½q9\­‰¦ùãÎ\µ_u ÏˆãÅmÛ¹]Y é«Êèô&Dr Ç“Ÿãq–µ8ĞR[i3s[¿…xÌw8Ïëöå²Ò ÄE[JŸa”ğ:aâh7ğ8=„`V^ı>¼W!K¼ş]>GR` œÿhÒ‹yššî´6‡K×‡&ïP’±MV¹õÖ™ÔÚ¿µÉZe~Ì?­èY:İ-Vv7ÓÂ¬L=ĞğWË>6µ¿ğÿf zk×ùNK–UaCß¨‘‚ª`7~‰]ˆr©¡aªFõ¿¾é‹ÀAºFY«İÙş	ôÄ³œ[!ş°Ë\‚˜Ç^öÉqví"ÆDá¦`ÙAàõ¨_qK#Â¤×¢Ğ+\•%më]8†yÁÔ¬ŞŞâ’}ÂbÕ•d›Ñ6µ}ÏŞQCİ9<¼á’K0W^!|E© æ'ıMò#?>o±ßL‡=mşB	ò²÷ÚŒ¡!ReåL¡¼”o×.‡J5‹¯)—Å	ç¥}(:˜aú;‘®íÛ4Şv¸Ÿç7™ Õ¿÷[‰}xx“€fÿgÆtıÚ_Icyt"ûEŸd*›¤
B¯ªı7}±G¢/¦Zøi¸ÍçÜ¶V`MêÍÃÜ@”¶Ê¨A½àFíÂ¤{@võæÈ]ÍøñZä”ÉõÚ¿3æY3?ï“iX–¤›?N¶Á²×YG—×J·Zıf*º†ÇĞköô*…œÂ	ŠÒTJØ@!JŠ!L¾ÿ)>pÀt’ğµ\[CcÉK(ë?éæò€5ó Æ·ëİÆºD­ëWBúöU"ú¦@„Dã4
ø#×Uî`Å;Î@T1 òoÃÄ3{j•ğWÀx”=fÁ¨Dã/I›P†áŒËMÊ¿®ø˜«nö»«ô>…Æş’Š»æÄGõ»1×N‘L/Ÿ qÃIxqHivÏ=üfU\ÿS\ßß‹ı-YQSLhå¡˜ëÃ©ƒ`B_`wŸÃê?r,3şÜA$Uú‰î4s0&;(7øãÁûz¤xªÇÃöÚV?…ˆ²Ù7Œ”>Ô¼™Õ½/öİë§Œ¼?¬/v|Oƒ	§¸lÓnH˜Oİ¯!ÀøÛ@tl¾Ó E!ÒH+Es;,®˜²8ï	éÒŞ²‡äß‘ÙëÄHË¶%Q„ÂLª¥[¨ÔeèógŸğf(É †‘÷WıLŸmOQ1•@¬æHÙ% ']¯vU·Š4t.G÷6Õ^7C„ªÉ‚@dC¢¸~¬å>nß¦î
tŒû½ÑW7BÓ9L\”U!«Ea®
æG>nx1$uªò[îz“Z"]3’ê’!}5¨ğöˆ
—v ó¡fÃÕÜ–¼¦GatüµÏ‡÷ˆnÉöù$§J0ñÌlØM‰ŒÑÙÍ'ŞíSŒªF»`ªQ$¼sgó[$4·î “Ü
˜0tniØFc”Æ¡¸ƒ«›÷/DêÜ©!õeşdùÉ8+ğÛö0|¿¨óƒŠ8ÂÖ	‡RÄ&K±U0g(†çVÿ“ÛÓª}ÀWb#ß*.Õa7wºÆÊ’kj*Øøå'¼„F‘3lg.š€üy¶®Ä«˜¬©F0`-ï+jD5ø8å|›Ÿ¼¯á0(:‰…ÌÑ²c#§Ì±Îæ¬^ËÁ,(4Š]íÔ&ç¸à¤ÕYF]Ç„‡ê‡.Œ/°]ÿ×¾À@å"è³ˆÁášN~(Q˜\Åöe	gA²£„LÏï$Úº9Ô·0ğ/	ØKØÏ2›;¸Lï•6Tkëø9Km ®j'Ucµ}ïuÊîœ—eÇåh E*jùV®¾CXI`·¨Œù·‚YZú >¯µ¸­4³Øè`ñÎZ9°œ,¿5}ÉÎ-3’¾ÍôìS'‹T±Õúæç$û¢®úi1ò4X)XÉ*$arSuÈj‘a¼	ğÙw³T+º•Á¢kìj…4M¦ÁZ›Â¨Ğ%ûµ¢'J}><ˆIæQÊïúªY×¬;“ŒxÙP^ârÙo ”yA6Ê‡\ƒ2x/îÓÒƒ„Äç‹SÖ1qi£D4çµ”åU7¹àf §ÌZ’h¹[=fA»;¶/Ì£@]¥h½Æ‹á32C€(iŞİem½Á®˜Š“$–µA0¼øfÀ 9¹ŸÛïv¦›9.97Øº‡©d—ú¥\ÿ7®²{N!U-äbq¡£ÄYä;ç†À‡Æij9ƒ)B…´ŸŠv²çò!™÷
áM¾«¼nzxeînùTÀ‘bÀOR<|§º:¨#fÀŸï×gZ½/ƒ¼Ğ´¨´İ
¥6p!“­ü×ú$â‰Ætôòíf¸/R:ÖêÓ"ŸuõAş[1şo'8¾Höñí«}™ \ÑVäd½Ñl±Ô“×ä!í“Ùò¤(·0è—©… í/,#}~ºNd©âö!°1¨²K¿à°¾Hˆm7ôI×•*i$¶bù¬ÁÁr¯åû.çÖé¬ª¢pI»ÒÃEã]O÷‡™KPŞ­‡,ŠŞÎÜU§?O´ ®årÙûºVCpİš’£p)xelŒé–OºP(ó¶ñ{âöÓ˜½HNr‡$RIŒ[¬/Ïÿs{+]Õ°™–ö¤z(¶İ/eM[Ã•Üq)‹[¿,dyŞGĞ\&¨øû/Ô¯ÚEáõR]nŒ9s2ªcê8<Xµ…pì-ZF¿ÀÕÑ¿³Y˜I±j‘eì‡a2•ÉdÏhZ™jˆ™Â>ıÁcBæ€Ñæ½     .!¢Ùş( ¡·€Àšüå¿±Ägû    YZ