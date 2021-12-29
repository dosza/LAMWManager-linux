#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2028769669"
MD5="95f5b91ae7da45961129fc7fd4dbfaee"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25624"
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
	echo Date of packaging: Wed Dec 29 00:34:37 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌâÿcØ] ¼}•À1Dd]‡Á›PætİDõ#âdÑ> Õãåá6~Õ< AiŞ§ğ%à)rÎ\ôÀ—§\ïşİc9ùl.É:F½6—sÊØôÈ-¹ù…±`-¨ä$\ú7W@ÅÎ¯@ evYƒ0áçÓ€8Â™c´ylêqaÍø|Ñ²më xâ˜HmB*OÑ†ª¿±}™Zœ©á>e–µp™3c,õç‡€l¬PU×HåoÏ öİîŠ­ÌÜ©…êÑ°(µõ1ìÌ´-47ÎÊ¡‚G{So\È`ÇVe^¡N¼è1jè~ˆÖ3{µ¢3qŒÛ[^f/]®ù¿—E>vyŠ,±@Ñ½:ê~=fÒ]ÇózÏyÜÒåïÙä}cÙ²¦7àë95®5VBJÚ£YtÌÅ'èÌ_å•‡Ï>êœ$ãµìê¢ÚÂàq_ôe3IÍj¹ò¬6ŞÍ„*%zôã‹à!}ıs˜Òó>³«ª¶´âi's;€"T)Ì39ú¾€¢,;Ÿ¥ãÙË¦æEÅ¤‚I†/OjeÆÙ€`Û*öå(˜˜äúD¬:_’A¤r×õFîúï›m#ŠJñg?ÕP”¸ıí~œTrúïù™·XU&"pŞ£)íãÜ×~#¬I+@/’+D("û.×V:HßæÁãÂZÄ„[ñ¿f"ªñ$ôŞ+ï“°òô«mÜÑ nİ®µ}$E¾å®,úÑ\¢|6ë7Ûi‹%êØYJœ–2c-¿É)|r‡ğŠ\Fb
ëÜ/9‘T£rGùøiC–{	ŠNs"8J¯Á?±óœ$t%@L·ÕsÃÙ€s™ˆÃzVYcÉ÷PuRnÃÜ5†@§˜1æıÌkin¯4)Ğ™émNò¯şÔ5‘¹tœ‡;¯Wi§¤Ô,Ç‹/Øï´¿ËË­Ÿ:¯± Ä,­UG9ØèÄ&ãOZmõÂàÛÓe¯ÄÃÈb2û@‚¿¡êhõİIw˜{lìAŞ°àK‘ø‚^èmıÓ¯sfÊ9jòôæñ+Ÿ:Š£’ÕÛµ2	íë¡qRe¡Ëu@{'‚B´œòÑDL†|IŸiÉ‚VhÇ´”¾±fqtng„Ä¬ü}<¹wşû¼úJÍJa¶­Óğq½˜‡5º¢ËjÓI C”hıß’†¬(k¶ó~È„±¬À{³T~¿'	lİ³$B­cï}ÎóÂŞoG6g·-Ü£°à!ŸB*Ìñ™÷7•{0¸Âa9t™D=¼TB}öÏ[»:åŞk±p!Ú<Õ´¨ªôœú­ùM7´¬ğg@ğ¶ =Vµ=ÓÔt6|dÖ^‹¶æo‡²Ëâb?áà%ıå‘º_Ì| Ól3”jØ!éAÛ†¥äèƒyYO¥Ÿç~WHMú´Áp©S ½2ÿPNuC)¶ßf³'»SF‹p—[
ú°°4Ö	[l2oßqªÉP3‚
ıÍ_ş1z¿-úV´@ñoæÛs­±…¨±8S‘ÚÌåô2èzNÈ˜ïKØß"
É«r9µK¤˜Å.që&y±OO|Íº€š–2î*‡m!áöã1QkÌşípDZß.=ÏT­ËFÇ›ıD	ÔÚ01jGRŸöiK¼Û’óN»¢êfœâa†r…ŞñÈH8ˆ›| €Ó÷¶aU(o6­‚ëK\Ì²,}¶(!í³§æÿì(/*ŞõhÑbUU1ÕGêhÆ”"]eş"¾<æO‘<ïI}Kò{—ßÄ°Õ9^b´SH:ˆ£yHhµAµä™Í³5êì‡¢s.áé÷á(Fû“ÜıõxÙ8¦P'5«Y»šC®|²áGqdtµ±Ö"*³­BrTæ²-àÖÑIƒ(cˆ¥|ÎÌ9ÇKù*öñû‰:Š‰¥½eÚÌr6¨x•í‡vpN-
ë†¸¯'^ ’E‘`OÀ_«ùZA…mı4©r½8¾uÌvã B2a{ı..gĞºt~!Hy(}B¶:y ¿3Ü®}Yõ«¤‹+=ÈT‚äè÷‘ilS_Ë%}y;.Q§Gòå#[…Şâş™“!¦æ§Öğ\îşwWYòšCOğì³Œ:[­“ÌŞ/ïˆ5áR€*ÖÄ‡!éš½Ç*t)JõÅ¶ÿ?Ìéù)£Êtù9p%M©ƒíh7Ğd×ˆàjŞ¢cëÉ(Œq\±ix_°®`¹Qß“1Æf0Æ§Ô°ñÙv¾-?¨{7:¬	¸,¨¶“ï”'äÖAp-ş¼Ÿâ¶Ğ½æ#p….tOzüÁ6¦4€Kø¬ãÚQW¯l×«%Ş¨“Üı.´yİå°/ÇMª¥ àÇıÂÀç¯GE„3dûzî9‚ILÜätD"ê¾JN°(ò0±¾ôÖ’eºPEÏœJ*àæV
Z†ìµÉÁ=ÔfúÔf½¹îŞ x.PUÎOi¸m±*Ÿ³ñÌtø|msK2[;>Zñ`k,Wœ*€\&Âÿ÷dº¸`+uÄNxRR_ eéµú.ËÑÈ…ºy ©@"s/ ã9Á”iÿû­ªùÿó/í–£æ‚”Rô¼÷<.ıo$ÔE°4jì=SsCŞf†³c?bE¤†™FúOÑ«p`cÎñdé³:aÅÖhqÙš+´‡ô5Z^__—ù­íËThü'’Ùº`¨ğëN£iDÜº4†ù1Ò62Pmæ¸óMÆ¿¯ıº@ÍX ¡`2$Á;e907pcIˆßçÄGÇ
´­¿;jmitAÏHjÁ¸÷{Œ÷ù˜™I·@…T&Q+^D±–ª|µR (ÁÔü*Å¶ƒ-`ÿ·‰ş×wÚ£uÌ‰>úZ˜Ìá…×Ú/ãoÔéÈkEíBkø-Ş¦aëË_ËP$HêÇElœ†C¶E»§ašé¹í4¦ÚÓ5Ğ¹ÿf 28¯IâÒ—$vwÆÔŒ"÷6®QªzE k£€v_vf²×ÍSq+iñ‘ë*÷º;!mEÊ%›µ‡”úÇTu"ñ|ƒ,ì–şä—Yæm¨À§ÕÌ¥V ëC6ëä,{D†ZK€_%Àüö­ºØMÊ”  …¡™|ç¹ ÜƒçLğmô½6"×B°ã‚+’3Ú;„Z¯Ø]=¸ÒÂ|>ûªnFŸlmÏ`È|èî¸äØ½ÉÅv‘¿o|/Üx4UF.$Ls,İÉõÀLHŠ¿ÊÄÁS§ÕÉ"=ÀK›õÄ½sàNPâÂAú»º˜“Áññ\•µâ^¯¸V€!ÂÒÜ¡Ù¥O÷û,¯ÇH
ü$m¤’´ŸßEÉI±´$.™æüE,'$pş™Ğ’é×á.ğXèå+×ÎS‡ÒšIr"êx1ŠY/	^L)â‹T±^—0%†XieCOaÃôñæ=/oÒÁü^”Fª›
[öÊü]|È"”U]7Mæ«gŞ`v”-ÆÀoàOU¶wÌ´˜âÆp¤•?é—®G>G©NbwŸ'P2ŞÒ%â€'è°PêÖ¹Š/Û|äC2³Ë„çp“P¢$ç{ìîV:ëömn4­…	şq{u¯›Ş.ß?[øâ‰©B¯iu
6yY€!ñDq>¶ìª9	Ïj×ûœ³[İ¯srÈk5¨Ëî WcŠ£„|Ğ!ëY¯’g:ğÅm&¾3˜ü0ñ=¾I†‡zÈ( ±w©p€<Wƒ!>…Sş¾gêKÕø*6söÔZœ¨Sj=ë ½T˜·EÖõ£yU;‡pH»?0;b-„ŞCë=-!£	™¼#ØÃ4`wÛ©Åioş¸ 'ğ+¾…S–Õ¬:kóÏi|İŠØ:òÎ™ûì¿İIëçL(Ö©-2©V)zI µ‡BÍÉË³	ÅÀN	…—¬¾]WîĞ¥N¸€ôéÙ–G}blúºíøÖ$Ï3n~Ò-X¢+œŞ©J< _éoÀ·*Åh_s‹’ŞÿWñ…éDù©ÖÂÀo`¼ínØáæl¼ó?–Â²üéMŠ<r?Ã%eíOŠRL´û¬‘ìnsDÈs–ÜÄX´:}g	“¦-"µ­}xWf‡i8{ñ2¶è':XÅ¨}·ÑvaD´â¡û:¤b“~©âÉ¯¿àõ\Å®ş§ƒRØ¶¿<p ©Á!A¡šà:´–,Ë87@[¾úĞçPíèVÎãVücÓí‰½è¬às¾ªÍd”Tt†“¡Úäí#[Ô&ô`î¸Âşû™§çV…@úë*5-ÑÑÃí-‡½ñj˜à‰ü-Fe¿¬gÌİJ@ÿûœğÂ>"Q—\ÁAX¾¹CµDÃ¹ä‹»›:)º€{İ²rœáa™(}ŸWn@å:@ÓaT6q UÇvtÃùô5ìÕ)~z*iüÄ¸
ñİ°iwşRÀ×3ÃÉ¡o	•bQëÕ  o¡;t0zQ…·ß–.%-	ø6+xõ’yÜ¼êğÿówwhÂmaıµúÎ!êë¡}°QšˆÔ~	©‰6:[ÇĞÕÖC²d§nG*Ë|DŠ…‘ªB,/oï¸½İ9”‘ˆ­_<ßÿÕ5ÔOû˜‡©{ßËı{´NNa+º.A)\	iÂ¨Æo!¯§GúüÍìU ıv¹´ØÈ}ÎsqÙóóÜ ö1jÏÀeY	ÌÜ¯Ãÿe¦ÉDºÊa÷ç³T{ö½¤e&Š«Ğÿ)×.=k£ÎÆÉNl¸ÊŒrwïu :B<ûLhóªÃiK;`øĞ™M)º¹²İ„œÃÁ%—¢¡üií¹KèZ&Ú*¹”<]ròÚC\òT‘0ñ¸@­#ğ…F ˜ô»QtDDXŸ8`¼®gò·yÄ¹º²@RúƒºéC
~³4·ÿÇ€´ß‹,fÌ.Gt~ˆÜ}z¥Ìàª™L¸ßŒø27©!ıÂ›9I?¸à˜†tu9*è_Ê<ŞBşbö‹™Âµ–’ÔñgŒ–´®€±Í.2Î¥€b$Îí@oÕ§z@®òÆ:gIñÜcZ
·…ÿİ>ŠñÊïldê/ÎO»`CEêS#½÷+r \ºÃÖÍP×ŠAÙrKc˜oÔŞrë­ëYÂ:ZºLY¼ûx&½…ù=6êîYùLÛE´¾ğ\Äeò6Õ/|©Øº%SîˆUâe™ŞL×óİş®Ã,Éñ”c²uhª‚U¢Êi¤5·òö·Êô{“#àùb6M<{Ÿ-b¹ş‚GÙí+÷E“w;«º[bŸ¸ìõKoóùUE¹H^’mÛØ<°²`!Õ¼ÿ3åV×fB¥<©Is;rÃI©U±yàÙªûY ¤”¶R¹_6i«®Û{Ö¸yŸmkjÓvu=Ç§N‚F$SoÑYdPˆV•„à:g•š®@,ƒÙÛ•T\;R&JÔÁQ¨*/E±Œ±Rôì+kA‚¡#cW4QãT
Á‡öVÄša“™\Wê¸7¹K#å¹Í5ôş˜P·Eêa#N÷–»ôXò†íŸ±ÿ±éBÛZ³Õ¾ZŞ¸Ã„ÓÔ69±â,Õ™x êt»|?4Çù9ñÿÌq`_£'¼ËÁÓÎš)²£/;óaõ@-m¾@Ùº¬éò$ªÅpÈ…éÊái†ĞXİFŞıã‘Å®Å€£JæÃnEø¨Ó^QK/Ûİd¾ªdcW™Õ@C•§hKäø¶ØÙ?ÎÏ·…·Y¸±šô$Hê§•ìæS¡6DgœHáİ(Ò²yaüU6-Œè´Å“~ÔeL¼±šÃv¼¥ôd‰Ãa;öÒoµ¶-À^§¿2òhKspŸÄBûh0@Ú,i’ ÁŸ¢à»C.#jÍœ¿Ro«\²³ÍrpøS`ô˜[®ô÷qtö‚ )³ç¯ßáÆUÎ\sÇÕF+Øa›Jl[ÜÎš<şçnM}ÀÄëŸ(¢>bÅEqúµù´÷\#ë¬pÿ˜çcÔ“õ–•×÷Z£u=‘£vDeà°vüî„…"a~²¤@ÉÍCÄƒ^š+§`.µ>ÍqÙÆâ0c­ õ;-ísŸC,²ĞâÑ°Ù‹HZÇĞ?ì»ßÌ
2€ã³ì7ûk(	œÏ¢Ç"NûÄßáˆü†Ş¶S˜?²W³™1^I$çÉ‹ è[í ~9Z§İµÀVL$«ñHÈdgııS…FìM#štåÖÑ×ğôç1„}µWwæ´İ–ûF´ı9íÎ'ˆ¨G\‘çáa+C«”Úòh¿S5’4õK…œÏíùT"|To
ÒíB†Ü™'³!Jqú¿ãò©÷Ş£¿Èæ£_’3Á»—‰±[4‘L/%á<FÁºÊz›WSÍŞ”'‘°\:M$O¸Y6»Éz>ŞPÙLÍ2ìDôÔGÒ>mî˜âçûvb¶ºŞX£*â.ub¶ä„Ch™Vtı_´ñ}fnâ Óy°{ø°Æ·ryR²Ğé.ze²ÜÊ¢ûYwmÈ®€à¸ÀVÕ„ßÉ÷¬ ¼ ˜"¦éˆš®#X=©ugMÁ‹ìõacå÷â#ÑŒ
°ñÑÊFË„íÌ‰ägŒšZèÄèI¿¥UÙİX¦ºâ~p–ğf4ì} /wkpœîVRl‡¢¸ímØÍ‹Ñs.é8¨wÛi(-Sb41h%W“ĞÂYì—ÉŸLşöŠ€Z®±äR´[ÃE½=8c©}ZàE¨o=
Ş{®{c6"]‰0Ô‘AÅI
“¤¢Ü¤6*ÎÎá‰3)ÚıÈÒ> ‹Pº‰AIsHvë‚_Û6íÉ¨İA4‰Wnì(ßú&§ô(bŠü0¿E¶²%RwRô°¦Ğ•Ä“7€,àuhú4{G;‹İmM1‰ÃDx‹ô
ë=Å£z…„şlPö‡&Ÿ_©Š“tb»nLŠ¸^N\+‰4ĞS
:°!:Ùi¼kfÀšDw­MèKº)}–EüwlÙqº„“Ê`ËM|-»ı:_çİİÅ¦Vl´ı5ƒœñÕà™ª\<Gº7=W¹ËZUVÏŠåıa.'tz¦¦ˆä¶.Çt&D¢§Ì}¯ïÂ»Ï8Gë7¸Ç?7Õî¿/–HBNh®şdÁ”LÚS(ÛÑ)toŞN¿¾0ÄnVîˆ¨mîGº»F„tz F7A:ÓzÖX0æ,Ÿm…q¾Bi+œœe«—Õ¿ÌÄÀÈ§Ù–óOEèr*Š+r0xgR¶7®ŠY]9\J§Ké^éæwT8LJIà.wM£¢	“ÅŞ®}7Nß/6İËóğ¹jŸ’¦Şƒv´ÊÙrlÓ¼ª$Ü?ğ÷¾¸š6qF³Øı2ë—TşïwC:s(À:$Í²5ØØUÿğ(Ë††½5Ùğ·8œ”!“äKû¿“K¼dzËœ;-ë3ÚêEÚÌQ‰h2Á¿/¹ ÌÇÁfÑ­Ï2œ’õ¯˜jêÄ6QPåwß¬£Úw¿Ğ[©
x@I¢<?¸&é¬§Úç	ƒ#d†*Ç%@æü–Ôé¦–ÙÜ„ã7 ê'XØà“Lƒ¥¨1UùFCÇ{aØ]ËËUÉ«jc@5?iÑïæŠ~Âˆ4 ­ïª¥âƒ(ˆU—^u®!Wº§‚¸]_Óc";P—6l´'v…,Èa[ÈG•áXù•İGå5òËW¯Cl¢ºbFÇJÚÆwŞ_.[V7J²Í8T)³yc|bQıbN
”§~2hDâÎ˜h+–±¸»íá8æy_œÅŸKü»xj¢ù·¤>ßŞhzÃ˜¦ÿnH`âöIŠÁõi=ñ2Ab—.2>xşğ>œˆÕ\ğ.èGºŠº˜pSËZ/±}²*yªX¬çz×ÖôBLCj{vyÀ<pá£âeÅYgaCi›Á+¿a	<´ùñÎ=Å>@ó²1uñ£ùêº".Cğ˜(qöM¡9ÏŸ}²OJè6<ğyä}`†ÍF˜…¿	¶™_³$Ï:02(îP`ğí2ô®İ$ß.&¢sWa»ÀôŸÂ£É¬L£¹SèwY¿œç<ôHÜ\ÉM?%Œvı2FÂ$vDë³fÿÙÅø+QÿDÓòh<ñ×ÃÈ¯Nİƒ¢´råÑl•²ë?bJîVE+2Š±¬A#MÁ§©p”¬©5±Å>„vw=q3ŒÀ”¸P[™ÏnçŠÒ(KÇÔ)ş¦®ÊL;„ıbM®pq®±(u;4¬§„C·,tĞÖjØézåbÅDÚÙÅoíâó²Œ5ğK—‡VÃFŒ9aõA‡4Ü†°¢„¦çˆG¼´¨æ¬ƒëˆ -¤»+½Hf+ÊÀ©Púë5-cÖ^'ËÆc*šûóò–ÜŸÎ ŒXyá~Pc»ŠR¨ 6;/î?RXZÿ&{™0~‰Ú>/^ıãü´YPG‚ê˜×ôÕ¬÷.÷?òŞŒffá„Û5|Ë$èrñ›=ÙY¿Ä£klûÃİZ-uqö…kZ‰{CíÎó€ÕÆUWIˆá¢í¾ƒ´!/<| Š]ÈT<Ë`(ÿL'i»£#')ç×¤a):’İ5_Uyº“†¨Dï{P¥6'³.vzÓé³Ú£0 ç¨h}¸§õÆıK4Ó‹1Á“ªéx´­Kãq°‰ÌÖb.ºòğIñ¸D5exu;+ë	3DÅ‚&³¬â®hzùÛv/!ëØ×ºhéD9ºş›´ô)$Sš·nÏCœ,©§\İÆ¡»ö²5•g–í­ëxÎ˜>“ĞxíYã”—ƒÍjE¾p×<½|;ue[à}Œ>ÕÄfQâÑæ–A8Ai"NºjV(4›¥ÂNÅo2‡ÓÁÀÙï+Eİş{*¯HÇl^ã)öOqì…*ÔµG©]2ÕYÙ»”¹Œ˜¯}µ”÷…äTq&i<ì˜{XH6ŠèÉTsG×·`x%9†d“ÈŒ¬¨.[[·fÔd‚á\#U÷Y^Ô£HmÜ6w2Ì³òrĞ†ôµ$®åª;ücÄ½˜# X0Wè8×]Ä'˜ZÖÿB– 2ñ²ZaIs&Ş›'ò‚—’ÀL¢O¹™8•4ßY—+d‡µsõ	÷ì»ènñ4)t{nüİ¼,KôÈÔ=aUU‚š‹b+-ÿÜ~MáD,¥»1—Ğy½ßÆeõfï€6ÇÛH©±ÚÉêËh0c¬Øˆ”ş¸‚.1¨IM<ÁZ"ÇÛÅ#àÿzİ íg•–JÕ;¬Bx	ûíZÀB²!n>ÉÂãVÉ˜´—µ°¨îbçe‘±Şp2Œœ#U˜f=Ì˜£}Â¿–rjF)ÁÅ•Š¥x"ï4zœØÒ2-ì*º]ê°€Î¾}y‡P LtL«³‚]õeñø0[A4¬E×bŞGŞ›îr–£ÊËî{FH¸Óõ DMíÉ{¤ipâ¬áé w¤¬2†T	 	MAïA27}¬÷|¡u+zÇ'teÛjnÉ‡ÉàÏ&Sô“/OåÈm_ú5±*M[<P=½›1êğ*°Ú¦ŸœsÍXKuÿØÕ…¢£oöÙ¶èÍXUu8í0(Ø8L4±¬ 2Ët¹’ã¾ƒ­ƒÏÙ<B«¢:!m44æÚ
€—§„İ}°¾&ùßG[knd†æçşÑ·D'mÎ© Ly|Œ àE#Ş2™Ïp¨š9TTÊ7Fƒ’à×õZ
·g8@wOb/N£gŞ /¦ÃÏB¨ÄJØï?Ò1ˆ$ƒ?SèBIá@RâÎ€Â6”tºûúz-B:rE†v×ctX"Ãlf~ËŞ¢ÙxM5Éş<£ø˜‡IÀ•Tf7‘³÷£Rê“şÄË¦‰r´2bK¹3®MØ ¬¶=Ó{kN¥!»f0ÅbnúëP(}T™‰Îœ—Fİ-¶(–÷ì²í“»ß.,BKòxµ±éNKõÃƒ:…á>Gı~òx5Ci¬S™<MH_Dü©ócŒDZ¥°bÿ´œv@Ä€Cõ»øÂªüæ3ÑÕp
$C,ñyÛğ×ã<U1-¬højîXH>^mj“,t'uæEß£1¯B~IÒ‡«u«µ-×swXw|)1#ˆìØ6”ÏH­¥²,riI×“§§›s"‹¸TÌEÂİD¤‹\œ’)„/EÑ{.³üWš€ÌD	£ú[#Là—Šg>ü’TK$ß¤¤­åìUH”o%¶MŒÊ¿{&†qJÎ‡Añ¤í2®ğğs|À ™¹Ì8˜D‡}J»j8½Üe™[¤ó`¶ úp‰E0½/,Ã@}3Ó§ÌTÏ£¤o‘6d¹sº¯©YÂMc,‹‰~Ì4TYXæY;ù!pP¿_öâÉÏîš9ÖÎÊ™†³ı<ô»•‹©az÷ÿ¸Jeèå³íUÿ‹^UÎ×*cÖì”RÃzõÊ àúàÌ…·¦Üğ×_W’añ!ø·/Gå53îµ<ÍK8¶XBb›çº	xÜ„fşÛúdÄY5ÄQsÖ¯—M©w`ÿ¿M§”ûCÄ˜b‡„íÙQûfÛïé	¼	tYµÊ8uíX.@í³6ÔöñL¢;Õ§æ«Áúy»µ»0Û\5èÄ½èÈ.˜:rdƒ_Xin˜²Üã9¬œöˆ ¥À½íDFì|şf×k›¡˜,/­Íƒ2jú´:[ş1·ìgTÔm¬`|±\ê{İ“óGŞ–¸‹
rÏ=ˆX´r	ƒXVq÷6ü™ÎaŒjìç?Ü»àë!Àİ2l¼kù;Û€Á¬–a#®WqË¦¬;rÂ!›¬:o%vªÆ ½pWŠ––Z‘Ô®¹šNd†ıŒ­a«õëÈê¡¤juÓa:½tÊ9jÚ\Ñ½Ğ¾Ş¥\Ì@˜ñ"@ÑXBµBç³}^jÚı/ü®nîµØT-™Z#Íì;v³P[Ğ÷‚b“Ç@W®eAÀ¿º­ É_«Ó;úDÇÖw¾gIi²>R9«’Á iºÄİYH–Rİ y¤<§D ‡14<*ŠAùÙÜ.ÑkĞ.NÑ)krÊ–è¨9>zR%yë„ç2Øôè».m¾öqµví	ñ²áC8¹ƒùXTÃŠ†ì\¨ëè•WÆv@%°?œ{3Y*–û|6f€öl«iÓ³>uCjÙ.l(Q,¹WñØçi™V!X«jÔVÑëk¥ŸI‡Ã±:†g“4áPÙìC¼b¾WHşş3ŒãÉ5—ä€½¥!pŸ©óYÜ$úZÜj»Ñá·A7¸°gÆ=ëÜÌ¾\3AĞ–¶2%e{ˆ!³§µMmÄfvkßY`ä1çñG·äÓ6]”›“h{ó#æBñÓ£+àÿ/?;v@^)˜À*‚8¹Ák…û+{‡Ö|oä	ø+Š<Ğİ¹‰Í[äj¾3~Jö£ñ'n8Fbê"Óô)·YÃuò¸;úÁw¾ñ¾¸#[4Ö6+.«AWá¾8Şy_Ão3R/ÿ¹ÿºşr=÷$88NÍ’WÚÉµÇm}@}£¦.@ƒ|–io»j«w›°'É6ß«ø*ls< ‚Ô©Ú‡ñ×ëX&)tP	,\)Tg›Î2<šc²1¢yd­ £Õ‹MNï:yñ)¯ÚëëbÑÑmxzí¿3påÖ{º]„ˆ‰½ovst<ÓYi/.NÕı!mZ‰Oàfó«ÕÍa_QæŒ¹O^]’hÀ@šağ«ÁBê…}æöúŸ‡x0Ô‡-‚{©‹Á½fµ ÙâˆTLÔŞW^˜jpûˆÃ§iÒ8Öİ›gÿÜZÙÊÏXÖ*áz!…-˜üosÔÃ¤Ï54ÖÍÒ¹aÌé²)å,Al£~ÍÖ	B?+ëÒÑç‚ĞR V‘Áˆ35§°©_Œï@Æ«¤7Gt-'ƒdI@ò‡Hù—%ŒÅ
îkö-d8Û½& TáZ;²—/:Ó|Ò¸¡vq°¾ˆ\½Í>›“r¾qfJi¬>°7d¶î„ïş„WÒ»/7†
ÁHêçÁq&Á[…ÊÏY_àQ¼yûìÆš-£ôU`	ßu—ÉM€8¡7ƒ<bBÑÃV—_÷vù!±÷/ûK£a9Úøßã=<¨E­aXZ.ä–à6§jŒ¢jM}9k`DğgÇH~©F,‡­¥e¡ba;+´=ˆ˜•ÀL& oÂ d*€ö8ÈEï¹¹Û‘[NmNWĞh@
^phÀíØpÏúö‰é'ğFSÙ‹^Ôsñ‘yğ~®éÍ°ÜÓÅ³ÿÊeğ‡TÆâº&ù"6êéQšJ™ÀÀp>Í¯†ûè&›ƒÆ÷·ù¿d”y]ûô!7º?Ğ`Ã|(Bx-	İD_¯0^ÓdFí ËŒu 1eopw'Lš.OHôŸÚtVp¨V=¸ ã³	Ï£¾›åBŒèd¥´Aº®3–ÏÍ0_¸¯-Ì¡ê›GlÊ¡¹1•hÓÖ?¯ ®XZâ'–bÊºXLÅ"øV$÷!O\Ù_d·ïıDÜèw	òOËQ<ò>£îîõ@Zf@_wÒ«wd‰Í¿ğ#!—ïZ4Mƒô¹…´7ÔO<IbøJñahq²Yv·Wd¤,…o¿áëÖÄ©_ ’2%ÁM[8÷.X©Şé=ß\Eæ[ÚsbËÃ^5¨¶ù½ÛiÍBD?<Ûœ8LËqÿ†^{nF“İ!úŸÒJP¥´#•è©Ö‚Ø‚®0°Ô³f4@)ñÕx¯¼‘•Ò¡>"µ­ÇâTJW ÔD¿z~€ §´i7S¯ÒÂå¾ƒøô÷×ì…‡	a7»	ãé¾ ş>úÕÊî×ÿKÎ¹H1„Œğ­%nŞ7øuvÀIéá‡ÜĞÎ#—ã?tÈğñ ´»—®6ª*˜—¸V×öæQÆY2– 	+œH{—>Œîë¥Â¶]ÂsOR)A1–#¡6RÒ–/øõ±\áV¸ïXõ30îü;¿ã]ÒÉ¢µ†ø‹9,Ó<ìmPfm‹•ÄS~á{—&œ¼U1T(¨^™h‡(­İÈLê2¤’îvn@Ó´ĞÉC°=&P2hmO+ü^¾Ôs±H$ñ}1a\É7Aªö9ùÂ¾ÕÄ®¡ŒùdNĞ|àC;™DyÁ@®í»}áº{sÂ§UT_Õì®Ù„p6šeÔÃıZúry+xQ“	à¥…sÇ`rh^µ…‰@áçÉ±ÍÇSÆ;“Qê§ìÌÓ™#¡ñyÁ¬(®IciD$«x zĞ¨$œ<£ñ<xÙ¬å·N£\wû/í½šÁ-¸ tO(ÙmU:5_ç—÷[®ì$zZğ¤O2ÊçTÎ‰W‰ñÃÛ×5O¤úÙ¿oLO×}2$n»Z_QPBcğÍt#c’-¨:	PH%‘#\"Îû~²Ôˆ›Æ¯”,_àè{ŸPøºw3·eì_NòVÙo0äjT2¼ÎÈâğ»]SGÌZˆK´—0Æ®…ÎÕf7Oã]5ZÚ’ê¡¦àäp*ÄıÅ E¨')º°ÄïLóNÏÉn³×€0d©÷p%Ğ!KÖ=qµ\X-ıE '¡‚a¶CÉnÓ¼%ynÆ±¦{tÒ1öÅ†½52óÅ1‡]şÍ¬( ŞDoM–ÖB&=•QU\£N‘qÜİfÆé¤X‡MrñÁ”Ï¡[7bŸdöœ'àfÂäÎÔˆ+µe8Œ’›ûÿ‘[È£ú½æîı”ëÁÅ¡ŒNñÔA„B»=¡Ï×w9ß¸19$ç€&ª_u_2±7yêOaÄ´O‚1ÅÍ@+i™¶Š¸ÃXî‰+è-kíè,PËèö|‡oFš¬ğ¾Éİ¾ã|
d]¾)TÕ¶ûçhX+® ùm§ã”«¥…6ó¹ö†Ÿ'z•ch–³¾jLÏô€õÍ2³%Ì4ˆGsj­uêÏ%íè#\rúŸ&0Ş€{S[Æm2o [~V¾;…L…Ìdhìjxy¸OƒJ\>,CãCûµp²òßû•Şv¥a)p¯,5 8ædø)ÑMh{tÑY2Jü¼wá`shĞe OZÖâ¶£›Ô$™ĞÿTóO‹¥f™úCÛ”Š:Uç‘ŠêÓÄş^’0¯é½æ˜sO:{j÷bäëØ^!øê4€pÔ“T2#SBDêlÁ‰`Ë3ÚWäÌ­ßDF±4KDu İÖ
š“j‹­¨x_™‡çà}mO¶¨«"ä.nÒ-ÿ>gıéR´¬µJ!'Š}%á,Wè"†¦ÊŞV–tuüµŠè+O?ÚŞiÃùUñI³ÓÕ ¼Ï};Ñ£¸¦~ZØ‚H0ê®zT*D5E!Å01°g3'‘<ô©ßêÈ)Ä­:)ãNòuÛ“£áqqZcw±u­úâí{ğ2GÿØ¾°ÔQÃÍÕdJ>#¸ëEšÙ}Ô\2e-ÕMªÜ`ÉÒå–tÿGÜ«¯O½ÛÊWáQl6c°.ŸÃÊ ì.M“8—d¾];ºöƒèÌÒ‰B|}ì^Â$²?ØÔQ1N3—Óçœ\Jw„<u¬.TÆÇD.?ß¨(Dò‚®ş8gSms…¢”ôcöæË~î¼PÌ¯*âo#*hÆköSDâ\qEhUvV³ˆšXeèô?¥*WÛA`5gu­t(ız\Ëq{6—A4h¼İ€¼öaşâTÎ]ô”vCN¦*«×‘8ŞE%%/h#‚k#cÖuø©ÍÁ.¢$¹`ÚVn¾Ñ-Tü;¢%%©†Ëˆ™µ¯|V²ıêÍ
õşfû"6e
òBƒ‡(¤öÛs‚ÜŸÑ]”±ÖZ‚›ŸùEBÓÜr¥¯Üƒ~˜ß_¡½®Xoç+„#™?o-jŸ•ö€˜SQÚ¦œKX‹B=ğä¥¾‚mÌ€İû:€ÚÏŞ[ñ¼™‚İÅó÷|d>Ä˜l£ÀÄÎMï÷V…¹ÕªëÜ°|C)IƒÈÅ‰œ0QVM,‹“ºîU³!€7Ïdh/ËØ%T¾@tü™ŒL[5rq!l×/Õéòøˆg«²Ñ:IÍt©–Âvnh` §Ów`†‹ş)ëb­G'‚Ùƒaz‰Z«õ]Şà´¨¹…ü6y;ãœØ7ZÈ³J)şŸúµŞäÜ÷µŸN²^)ò[!^SÛZJ}*t½R:hñğ§˜¢ÄâøÊ¤:`ÿcbZú\™ïàCT“ó#6á Ôg ßÊ®DÔV07u¸<Ù“K‚Ãì'Ä²†ÛuËpoê3aXöˆ9 ¬^ é°ğu5­62p:”87	xç’›Pt®ñ—¦9„)¼è}WbÅ;j25ô±´kî'•·,ƒãLMaIÉaòùê6û«}áòµP…Åâ_±]Í[™[ù(‡,›"¶Ÿóø›ó	
É–¡»:Ãm1@êCP¼ë£ş”ÚÆKä³Ÿù­èO%¹ÿ»	ÿá|q
YwJkâ3q™İ_	‡w®õF(9VÔâ—äOìà½{šÁQï=í
¨Õs\_UIY¯KŒŞ©V!+#ÀÁé/ï1ƒjÃ¨±˜Ğ·ƒ{µ,ë)îu{wÏQ´®c‹`W˜Ïk`RîØ0^FöÂ“º]Õ«Xµ]{¬àæüV|ç][€´Û%ÙºÂìÛü=ÚcÉp£1×²c%.häé%@VKŠŒ”[õwÖÊ¥	b|ßÓßNxÂhîm"|˜¢œ¹{,Ü×ô»Iªmû¥aRpA,…«z©‡NóĞÔyä JCÖ4CxÔ7Ü§¶!­ìÙ•”¸åÓA¢ºQæ"hŠ×Ä!ˆ)<IH;3€o-¿JSV­ï„+½©ïİj+°ÌÌÎ4Ü‹`]ˆ¼q~ñ1¬õÏ]* š!™³-b+Å£çP×°/÷¤åa¥ÆNåFË'Ñf÷4/bC}ïÕ—ÂÃİù:‘9ym<áX¶ÌW…ô¹dD8ç.#·…_Ãİ±Ch‰E˜åı0¥d¶ıŒLT9füJ•Áğ¶sÁöã¥Ò“^¶wq³Uí€wÍQŞL‚(c ›·:ÈvŸY^×L`Í‰¿M±tĞ&Ê[	ù®äõ|ËÏ>s+AGÀ½jŠ´e`Æ|ÏMÜÔv‚%†îóë|œó›Ì3À³à¼u+Ã°)|p+eP\É¾€kTën—•I
V:”úhtF$bd°|52âsĞš™AeiB,&Ûî€Ã8|—Â6ŸJ-æHSÎŒ”/÷ºõN‰#msœ?1gû¬-\ãÿ¯yNl L44Y
Š0ålµ–‘9mLÖÍ	É>,l]Iw™/_4¥H
c„İ(šõ¡¶Ñv2\ß³üŠ¾»ÄÏ@ 34ğEV*_Cn{°×GKÒÂ÷à™‡t¿j–¾AÑäíõ´¾”Ut/&›ªlÅ‹ÆúKJØCô¦‡N‡Ï—+ëYš3—«ç~0Hq¼
‘`e®ˆ.±C§IdÍZãuRM|–è4Ş…XˆÌ¬'°é®—EÂs¯©¹Ê™d7_DB11Ríò¨ãş¦ÔècsdŞçˆ°¯sC›TâtH:E”œ/köØß î¼S-/•Wy9ìƒ%ÎßMÔ0+ík…ä-ÏG.Ü©”nP×Ô!|€ršòÂ¢Æ_Œ	šÊh+Øü*Éó6ém´×úÍ0+Hcƒ(Ö5<'ßB5g)—ˆ;ÛoWÀ'ƒD½¶œq—w‡TƒÈŒˆ\Ãò>…Pœƒ7İóÃ¼l‹)’ıƒ@ˆ”-’/AÂ·Ÿ‘CÌU…†WóŞ¬Yc¿vÒHjØˆ8}BŠÊõZaö"»á”G,f,ˆ·9D*¼ÌÊªvãÇ/*ô&zÀª˜Š€Db‘YaüÌö"„ú`õkXwÏÓ‘}u´	e£Kc²„\ŠUM!‰¢k	µ¼åÖ(F´u€#ğeûél÷®Á Ÿ  /[]0
´öO'Épƒòöƒ[µ•)~sP<_è@Œ‚ğˆBH¥­ˆ£`g°»ÛlÜ!ÁiõzoÄá¡xÁ¬nE^9¡‹$¼ ±éJ£¸íâÛğÒT:zX¦ŠäCİ¶]a4¢¸JŒn¼øiÈ9ˆÑ«Caœ9\P'’ùf·Ù–Ş‰ñ ÷ù¢L|yÍéÍU¢Y½øğëkĞ®h$ê³¨=Y²ÆÍ§WñÑW9±½BQ·BùÃ¹ ½¡	Ş0vùx)#hàÿÓ¯^”€‘«å¥úµ¹~s%wè]…
B·-¨y~âãƒ9‡æER‘ı'H3Ñ°qSÕ«8Gºç§ßfØL%tñŒO€1ò¥ÄrÛôş¸ct(l§Âô£TÕ©õû™¨vJˆ¦Cˆ»õõÑ´8$®½ğ<AÖ¿ù±]Üwd^yƒˆh7±G‚…–ÚD½I@¥d4‘3Ş±	Šêïş—	«eŒ½ÅŒ~'ölpy»†daËhg‘êÒôñ yıÆĞváUkuÌÜ¸‡l~àË!E™HÓ•’”a`I;ñéW7˜§&_ºí^·ğùà?vç>yø1âÓ^0’h¼—º"Û5Á­i<•¢n?1®SŠYqMB¬C$“ì¦‚É^‡yÇâ[Dç»mZ£Ä¹Bt9×ÉÓÅÜÉÌÙ—MX'e¹¨•úX‹Ä\ûæ†:™¯¥Ø&}:íønÏ°˜aN»^‹ Äï-èıi|\ø
–ñy
Ì³B}%eöÑ…Ì']Ã$5Ø¶*3Ñ»Ù€ª/S>Ş¸şîéÊçÛù§ezÁ»àÁP8¹]ÈûšU¶)epØìa½j%Š*˜4²1*nH^|e æ1ÈÏßİåsLàÈ?XãàÈ¤.{ëÿéu›°wO×úÙùñıÊÔ¦À
ç²gOÁ£Nr÷£ü[
Fãxë2>¨Î9œiØ,¥«]”\Ó|TUP>]÷då	LMRñ;à'ª(ÓÚéÉtäUû]Û“¹ŸF›õo&P‘1ûÍ \¢i‰øİw+——TTĞŸÈóşñX­êÑ0Õ¤uTi:x†|ß.÷“ˆ€Å%ne} †Ô£+ç¤ù44ÌĞÑcŠí3¼…I¥Æ²Éº.œS×¯µîÀX©¡3öü/5„›Q^Ñ(1š#Ïò›må]va¢Mq„'‹iAÉî‚¯u%-bÔ9æÂh©ó¤-ÎÏüU %’
°î!u»>ÑÄîª“e0•Ñ©@ZgŒ»l}à	`8)ğÊ0û<WÈë³öİc¡Ñ¬FO_nŞU.dAsr!GB;ë“°öoErša^©ÍH ™t¸–ñEI>şàÅ¶‡."ô1ùõEÛ;ğòH+!ş—¾êG),K{›‡rX-d+É<‡º›e±ĞñÊ)VFwºÎå~—f-ó¶{DÿFØó—¡%4ßIŠqD›1l¦ê×ÕQşş¹–™ZÆ'¿!øÎ>)š¤–ÎCzøı8çlJ¤iøˆ-v¥Djg_¿x5§
ÀèÕa+¾_Vtë~0Â{S"£”ªR=£gr’Ù²ÇÉ¤‚w×“ò;Î¡ê€êŠ$Ù,H§îãx	 ßù˜HøÊ¹dÑ}:À(IÓm@˜s†Xşò’¡m¬œ&2cÒ*'³ØTéÕíÓàšx8Ü˜pØšò½Myºo•cÿ)uÕ°x'0¶»p/­ˆ?Xùíu¤¯Ú“zg%ˆ	8’ù'KP|9P–#To ˆó0‰ËMÿ§R)Èİ«§Èû€w£Y«¢ÉìlÏHy…Mû3Ù Xêµâf§­2·f+WšÕâ^I:¢Û›ÇÎsÃÚ»Õ%•±L¦E¥PÃG9  gÀİ ı:• ¡+A¥|®pZZ¨©çÁ2!#\‹).Â¼W-ÅQr˜!Ä˜¸>27İÒàÜ§bÅ„~òmÊe ó¿À2¿sÚqNcì<–x“ŠT”$±ë!=M…q±mÉàT÷P‚İìN;éWQiìñHh¤Y1¿È8CèD©‹+Ùô¥k²tè¾â7åÈ^à³Ú‹eö±W.£85ùm_v.QñpJïï(»lá…¿q×” döO¤[øbÁ.bŠñÊv}w.OÇ’Ş‹¼×»PíÔœbR*µlÀhUZüêuìv4T|Ö©cé·ı#J œ-<ìxÂ	ƒêÈyÉ¾«·ƒÛiÙí-AÂ`ñâ7¿!ÉIâ.ø~fgÛş­WLó$Iğb±qü…M~ó¡ä5dİ¡0ÒaÍ‡& YÑŸ%ÿRİÜ.òÎD_0ìğI]]û?1¶Íß/­d‘ªáûwî’ß¬©ìîzôwµ¡Ø¦.?Å Ãn¿Ğ’¯E ;BŠƒİWFDNIù¸Ö^5*²³ÔëŸEZD¿ÛïÏÆ#ÛÜ£˜R0éš@|ì8ãt¡ªØoI–a‹åY†;ı¹˜o¨>Ü"q|şÀÅCâœVG¿¥ZúJDe1±0°ÍFÁÍšÄ“à[Bòì·5¼fÈ¸jñ•4‹Ñg+¡%qucÏ‡Y®óÄ²ÏÜ~JHÃrÊc»½ò–©K÷ücLëwİÈ3ÒµİÿW€…Mhü×zÁw h¾}ÏÜ©n³Ê˜¤d…•:™„ƒÀ(¿tÜÿê¥åùğÎ®/^¸G­Úø ^Ş¢ß.ı¸)ƒK»•!»x±§~ö •ÖKY­ŠC^„’»®•E7t1Ñ¦¦\‹
DØşFÄ›iø)ÖÑwyûçZíš}Ášú,ñ‘Ök×é¡ÒGåŞ…e	¥u˜
ÂD?Bú_#¤©gô?Ğws£Å6ş_¡JZ2#ÂP*÷Š&£VğkÃ¹”õ€<¦S‡¥5nIª›ûÂïßUiÙ3cç€¹Ûì_´5B«jİn­ÈoO¹Ïı1íØå[äáê·y$½n8øX²D1çsZt$pê³Š'Z›˜Â›8ò‘ñx+&}•‚¼6(]›œœ[¢~%öåuNêÓÛ/¨±öğÙ=VÆü`•fğ-s«^vN²€In+‚`2ö¨ªÔkm$·Šù±"Zn¤‘®Ô¯ºıA¹i'ÈÆĞEW¯YéÕ@Y×ˆáN¡š.½¸„Ò>İåÄÏäLm|¹ÃÈIÁfë® :ú½BÊ1ŞĞÒÈa½`ª–œŞ“ßS`€)R®”ŞN¥ŒâØÓ^¸ß wŞ’[q®§Š©."O(äº†pºá<×ÊÍŒ@_VhkíGË”²“,ŸÎ²Á±á]pgªÕß¾¹,ç9ùİ½Pg6'HıªfOõL‘ÎD-'wòîÓ9JYâÑ:dïAj;ãH…^]ó­» ±Nä5a¤Pœâ-&.—üü}:ç*ÑrÚ¼ãö- †:I¦=y=ú&ü&ı*¥˜½ õ¹ãô©,şM‡€µµ> ĞZwg¸Q‚›ß`í`²™`…ÚãÚªñd+@Á¥æ‰’Eì(®ˆ&¢Éœ°›ºï"iƒöÕ§Ï^š,((ø£ò€Ï‡K${hø	mÙªK
~¤Zwö¥};A#íTú'µ§Æ³óN#8O0_Dâ ÃŞ¬ÚÇ†·Ç‰QK´˜9{$[$ŸmÀ¬Îöƒúß l­›	ñ”UW"×ŸÆ{¥+xßı–ú2åµü®˜Øå‹îI¢^Î#WNz¯¯"JJHTÂgL}­q¯l–@ŞÈt2“†J|¡±bE
î¸qãâmÅäâŒ¸lƒ°ñ¢zO–3:9£’H1¡Ü€RB}ü.«©¡p°Gz»e,Ëv1q—Á´rÔ{‚ŞTÔË½IµƒZ“ÚàR6 ëşH¤NTöAeÛLüNK”d2Á]­RªéÕ*Ö™í';ægÔ\åZtÃÕ†6+lD‡e£kmî·Ëgxa;hàD¬é¦Dİ
ÍsW9ÒŠ3°×rA-3á—y'ÚÜ$ìœQ®)pÕ(H…zFxNŞp8¼ğ{zps…Dj=²ÄŞŠ<ºjÒJ5T+÷	Š+s‚wæ7æ‰PğÀ…í39Õ9ëW;]ˆk„³9‚ï‡(Ñ(@Şç­Ò!»2ÖıÅX"ï6*	l %î{Bî	‘F4ƒ$iğÅÁC9®CØ¡†6Îì$}ü`ˆÙ“íœ =à ŞøD«)ò4é?ŸÄ
J–[Ó †£¨íçXˆ~õ±¶-,P
uMÍùáÉÀ'C­è·ñ²< Ù£ôßçøÂÊêXSñ‘1ıoúBUüE…Æ€»Š
Ï:-ç«Ãkü:m&Ş­}Ûµè„hë, şÓR–“^šÚ”¶ì&zÊ–µ4ôŒĞßÔæÚÆ‘ÙAkËœm3z©ó‚ínŸ|Çè)wÕ0Nm¥jÎñ3px[RuàwÖÎ‘ Y‚q…°jÉ7|ÒºÅJûõ²FBoğ5‡UúÒ¥|©,(Ü~é¶8úÈ¿İñSÒıU³lµ²V¨çQ¬Mp8°·¥
Œ¢ŞçQúßV<®ÊFÄ¦Õ¡ë{õ `-ø°­§›?˜JwÿZÑ—b"6`ÁÎ'LÑïƒgY¬Àm5ãÒ;Õ‰³ ÃN²Å*>œÜÉ,3vI„àÚ³{ğÀd´ûá"	¤…’Î¶O‘0îËMç@­Æèşj+mê@×[5¥
}#½ñí»œÁğ A	e‡Şœ^Ôn…³¾èè‚s‚‰å——¶á_”3Ó	"ıö	 l—¿øÀ¥cq¡ë‹ÛàÍe¦:H&vö‘]M4·srÊãØ+•wü Ê=œ+¾»ÛÈÕZŞuUëpE[àõ‡òHÙ`:‘5;–NäwÀÍC;ŸP©]°¶)(M€ULÑHÁ¦ôYzC·V—“ğ)ÑP_ìw$+À	Ë8ÿ6˜}îœˆ9bKôŠ¦÷»5;àkùGlòšê’æó;Køg¿W4\ì{Ò_EÜ{óuškb+í=_)f‹ÎæªB*º_/’5BŸw†ëv˜óTqÆ8u6«3£dÆ¥¶(fß> ºúŸ]Î‰¤eg_èl³ß~áÄTZcíîf]M™3mC)C–]0ñw;M2/ù˜£H—ÏA•t%Í]ğ#lñsÖ Î°áV‘\›Ü”óáí·kû_Î*êep°‡æıGVâä›IhÎiV!ÌÊêŒ½Ôj‰óe:¥Dú7¾Y|¯ÓÁùÓ«2o•âÊNëµ+¡F/Æ´µLDF\œdåF‹£è¨mèÜx®ìÎ.Mıô=LeÆq¸‚:®5‹Ç€Aî¡±u+jËã0¿	@‰w¨£ÏçaN#UÉ_ï®¥ÅöÅCÖ4µ‚Öÿ|ê‹ª„¤Ø£"qƒGñş¡¸œ\÷kÈ¼¾Rè¾Øû·
2Q³gãh§†`¨qæTì*ùNÖm…ÑoZZö¯Áô8f³«¨;Bxãå«{F"*ÔBÒ­¸ Ãnd—Éaëe]9òâóe{“Hu…º¯¨äŠHÊüáKu+=Äš‚y£²ª;¿GœÊ†à¾|)YÓv*FÿæË
dDv;~2‹«Rd½0Õ°w¬àÆsp×'ğùŠúÜ£
»öLä“]×B½B ító‘ïÖ»TÀ‰2Ãá9ó>(á”Ÿ†u3ÒÏ\™@>>lâÏ
‰Ú¿~éÓ‚£Sí}V¯øR–1Ä~½qTh”ÔJ`‡\9ídK'¸æ&U¨V
Óò³Ç¿h²ƒ)‰·Ï%#"Ì(á‡í	Ã„°’g<ØåêÄ~YIÀ]w„IÔz_,ªiÇ¡w!´ÏNgOıƒKE	­Ê–sæ)¤?™tƒøTGi—"wœô¸K	˜3äW‰­
ôD“üm
ÉÆ9kÙ"ğßêK-Ñxe€v>n¸¿µ5°ŞM”³ûôFF ‚@œ÷',d™¯ÌMúÃ*€_WDW»²½ş/Åç–¬€O†(C4‘M‚A€J?Â—ªœ·‡êì½ƒfqE·¬Ñ¿öÄ¾éÓ×l“À/7õ‚<X{—¹Ÿ{Xûƒ‰*då®.B˜¶²¿EÕR/êi»¿q'r#”ŸFé6r‰s©d­`P#ú}”)ïT‚‘\Ä“
Só”ì^¡jdC ×·8äèµO††–äş¼Æ¯]6];OwÓI )¤H‰ÅÆX=GSe-Ú<Ü8F’”»ÿÿ É„³‘¸ğÅ¬eİ ¦=Ó(}‚FÌ%©1/rïñÆÒÒê¦É‰BÖfç3cÉÔÇf>ğ1«Ÿò]á“W‰v}á[³oÆî‰ú>;ri[“Šõİ±T¯O²Å€ÇJbo5#)’²o[ëèP]É4¸yÚ‚ÅwFÓî©¼TÑÛæ¾„€:RI‰İäÇS6À…6×ÿ¬L.Í«6û¢¶AİJ_¡Ê æX¸ç@æwSŠ’<
¦'7.ñ$T±ÇİÆAUR¥{’33C¼‹7úÎ˜ˆƒ¡|¨–¶İ)`#Dt2¥UKâ®ú¶Ÿõlz“€zò¬ˆ‰7R£`—YuŒOÖ”UÒ¶Rµlş.:¼7µlÂ,0ßà¸I8¡ã,gŸÖİ¨Áç.­SÖ?øÀL“ÁDÙõİí”)¯€©aD¹Óã¼ü}{µMèùë†hüÆ3˜²,+Â©Éº¡dÒĞÚó»wR›Ü‰Œ¬ŒÅ00ä—?ıeqÖtF…ïôèt9‘åB(¨-çq³İZ”ŸdÑ‰…¤VúÂAÓª;> ïç´ç‚xë®’W}hâOà±{=ìEñ¾æ
•/}CLåCä¦×Âlh7”|¾³¬)ßsñ–sux•p9_ĞNP?{€+í3{h›Ø,/8?çƒ‰€$'¶»ËØ!ËöĞ¨W³Ÿ ‹zÓªjÕ¸µLùTÍ»{Šøi‚Ô y7tÑYoWÆ„ö¬€[0šW8Šô«ã“ğ¬R+S¢gĞB—"é±‰U^2ø+ÎWH~«,šï±‰ı®Î$3’Ô›e=G¥hK:|±^İ6ˆNEnç¶V# IÈ±ú0ˆãh¾ÔTôÊà›ÄÒ8Jl®ÜŒèŒ#ÑÆYÏÈĞ¤Å%+Õf¥O¾±7¡µ‚„!¯Ï}$eÀÕDìÑ-–í"
àfîÎYa'sVKK
÷€JK(çrÉGyMÃáCO¿ä¿ÂÓb:R`xB39ßíõR¬{¬Íì¿%¨¡du£º$—gœ88T3Ğ×ãZ<¬•˜t¾eÃbF%´ÛÍ¾:LÇÃÍÛl9JˆŞG¶ãhò’…ŞÕ VJğäJ7#5 5ë
ºR{gıã°6Be'•î†şI9Åî›İÉRòƒ†œ¹„‡°D*:7¬˜H&%bc¾ŞV«"#6½âb*4û…™;Ú«âB±@œÛ÷no\üÎ³ÿD/ÀwÒ•á|AÌ5â~şS¨î5ÕÖı@äÜfe„¿­ez)¬(&€2øvB¾„Gû\SŠ&
ø‚A¸Î*?«èšÅÛÜ*K•MoáèÙ •Ò©ï\ 6R¥ıZ$=üYã¢—7‹ß}‰dèpKYúW…¥!U*ãÜ¨­Ëê'—<'.	ioÓxéRn»¹5/4†Î•	ó-
ø¡á(ùçÈ2ó²(Ê’©Øâ1Ü¼ªLßq¿WqÓs“ÖQÌ®kÃI¼¹¥R5!yû”*ùr²!ò’°‡ä¨X»¶Šê!×ö ®:© ò­íy˜HmÑ_i+&‚9ÎÛôµ€_Ø:¹B²0¬²ÄoZ&)Å4g¥—èŞfĞ/¹gG…ª-—p’í}ªaàfcAbŸ/¥ân z¯Š3kh~•–¸w®¹#NÄóÅ_<WeÕãŠ±2:Y/¸lZ¸üO	DeoI~âŸÙ‡¶±0/¾1°Üã(Ğ­däö?¥²ÂŞ~Sü-F)‡}VI>Dƒ¿:ßÁ<ñÊ=-86*2çnNX.`uöÂw_=v×à…³®İìÿ©·pì"İˆ`„1,5\ÓÓô
uÀaOG˜6ê®eÙ‚ª,$X€?"kÂ1Š¼BWüñZé"XƒTU’ÿÙÈ|›rbÿ¨rQÍ÷BÛë;{¿ná@‘(M&Ï»¬p¦KøZr®?%Qô¡…£õè€éA0íå5cºúUpnsK©I¼ÄÁIêl/qÍÅè†³€.ùê:öÈ•U{b8gyC§êÒL˜æ!.Òö1¦‡BÚ®+\[ï¤ÎÔ¸ŸYs…“*ReÉ½ÓÈ	×¼=ÄšªdŒNfs5‚ˆH9ï©¢Bš¶Ï½YÔüüÉUGîDœ¼‹ŠİqÍúªñÄC»HĞ}¹"ø%ú‘§²œãÖ[nI.uü–7'Şİ{Âi:ê˜x\Yp¦©5é6hiÒn‚¤—A¯
$G‚M…×vh“g|ø…/G2ïC1óDBnÄº} á~»ÿ²“æl1‚·‚,ûkŞ‰±“—˜hI>D)Wƒd±KÏ1EÌx¢êlËÑ\r4’²ºèa1¿dsE&ô¥·¸ C‡£û·-¨™öœÑÏ•"éîÇjÒÕ€OLO@=ÎJààx–/ƒ™DqwÉˆÇPáºj^_]i%£®j	âÔKqu¶¨'$”¡Œ“¼·b#zÈí¦Öa;Æâk‡<"†])ğÅW¹0ÓÚXßŸzI2D;Q«ö>ùW”ŠÍĞ¨	1¢øú,’V\ŸhIR†0PÍÿq <¶ZµÑBµa+˜.îÒU÷5Õ´·Ø:å@q@Úª‡&jQhå¨Ë÷7#«±øš:9­ÎbF>Ç®XÔQ¦ÎÀVıe	%8¤­í>ß §%Û‚p0f[ØtT‹o8Wø`¸Úh¿ù0~ÄÌló;™'ğ?/·ç…rÊIbÁ?;BNp~Y8D€<Ÿúò$ãÇd‘š·ö0kÇ,…¹ú:Â/ ·Z³Ü!0–Òp¶úå€B‡vt²d¦t$ÏT–+¨Øã©V±õ€Ì«Ôr°£êé?!d1;‰Æ=GVAÛòÊO9yì¼î$@™ÄMp¹ˆ|òq¬ÕK²¦ÆİÒêa‰5©ùúÎ#Òİ]Ò3ã‘Zy ³f>ò.ÏÿlQˆW÷®s+ôLïàG+/_4†G«.}š_ØıAs¹€ôo]+†bç¹î*å!Ëò·ÉÂö³˜Ï4ÔÇ—èfê¡)—R–<(u8,¥_òu°²NÇÊiõjm|$7k©?ğ ‚Œ^ÍÎôÅF”ºÖt»¾ÇŠ•-o{›ÚÛ”P£u¦pß‡ºóº•šŒ=‘BÈ´¤`‰#PRÉ¸Ú¼R:]~‹ÑT1‡¨¦yìXwò…¶.€ƒ0t89jÏ¥³UWìxMr<l lÌıë4ÒÇ^fËk5ºî#MÑàÀ^÷?ü©0— â›.”Ñ¯=,ì$ ôÌ”iÚ-¦`7ayxØæQ@£Ó¹
è.xQô{$A2Bn´ñ,ÒÍ?M&ÄÎ)ÓÏˆÀÈ°ô÷ÿ|íbênª]Ò£˜ëêà ¥u¸DQ±ŒÀ5¶ªV ;õŸhë¡UØÇKÃ¥&¦èÄ÷3Wg¢.[İ- 	3³Ä·gçF¡=©ñ„~+Ô°§j7iIh­¼À¸‘ú\²×•<Õ«'‘0y}|é€oãÊ8Œ¥fHê¼;Ï 
ÃIÉ®ÖòCŒÅ)uLUdÈ1]ƒçúcáá‡Fä&o1b½R‰Ş3£ÈD]9ÛXô;¿ÒT˜•uiÜ=¬!|‘)6ßÃ!ÒJá ¸• ö¢êqïT½L¿Çö|._sõÓpê§¬"<$”`¾ÏÑéŠNSKÏvàkú_ôÍ'“¾oµï³Ş•ÅLO¶Ú÷,™’Ô2´#øÚP£yz²a“¦ÏuªKrÅïtˆÁ3/8Â‰b ÍĞ^®"ßÊ¶o×õî¼/Ø!¼|pT_>Ö¬%á.¹bãP{÷¹vŒ'0mï¡$&¨£9	¼m…®œËÃh`h“5Ê‡šû¤2MP¬hš `ƒ,GÚ0yÂT	äm‹$‘‡Fq~eÙyì.hÿ#Nò/æ˜¶†cı "&*Í…RZËGç£×ØHÜÇòÀ7—¨ºÌz4Ø?°^PƒŒUY_ôµœsNdíXvœÅ\ñÄ…¹2m×ÍX>÷À8+÷ë+i‘LS\é¶*&á9’RÂíõÌÉÔ±n>(€. ˜¢hW<©=Õ§’%¤,tG[¸X¨Ê¤"™çs¯••kê[#ô¢ÌÂ¤É÷OÄ"“ß•¼B*Eø§½Õç¨çˆÓjñ½3·MûE(¨u`Ñ{YÜ7T)™Umƒªçîä6ğrıG÷ØLßr×XÖ¨zít“¿0’H^k h±Qƒm}^Kæ8ªĞ™'¯*
}ô‡e’ÙiVÊ½{{rQq%¶X3€&¦ÏÍv»Y Ü$?í˜1‘/|8Ëk‡^°·-¢ 4ékmš“gQd^ i¾à¸ÙÖªHÇ‰ó³j3`8@R®)oA½¹‚†ä ©tÕã ­{NÖi$VÏ¿òñŞ§ª/Å&ÙÜQ¯ 4—Ù0¿j0ûÏ–@YÍÕ;—ÏŞÍÃÚHóõ›“÷İû7^
1èQcig¸‹ŸíŞÏ:÷:ÃÌ–O,ò;óŒ¤®Ïc©^&°íh#&˜ñDYìººK:
¦Wš{ŠR°Oô3Ã×fÊµbÀM'X~ß>Ò{éØR¤ˆxÉŸ´ErêCğ?¼ßäÙÎíIÀMl)à®ÿÍY‚E¸Ù³#ÙéÇûãœgä“$òÀH4ˆ‘™fêôN'S2}¢ÂéT³=¥ ¤TÃUvÀY8ŠI‰ÙÁÎÚ„6ş–2B~f*¥Ôğó©YsŠ“;·A£ŒÍ\£Á}ÙÇ"WôrÔTñîŠ;|5–x8Yù¼@”ÖñL–
ÀBBÀ¢«Ezƒª_zp»çöÔ‰ĞÁ00N(n‰qÔÆğ'h*ÑJö¿Ze5ôs%ô4¿K±åÀôz,:ÏO+Ù†€gôÃ‚nG£Ş›ñoÊÈ—TôQÚµGıpFJÄ÷·š'YÂÀ>d‚»vÓÌzé|‘‡•ë#ïoöõòÿ`p¥ÉÆ®ë8F)Uº^B¨î£9³Ó'qzU•=œ		Ş&lk(nâC«ƒ·&¬ç\=-¾)‚Ø\#;·ş	e¹ËKÇ\mO¤ÓKšnâËC~şm{ıøÙ^^@Aâ¼g½±’†K~fCŞ÷îˆ®Ú>­CE¤d5¸Ä™®-½X•).Dú›36R;»Å'DBŞTÉò€ÚéúŸiåÀ“aq+jˆÒôñr9œåõèÛ¹qä@Ußj[4–-&muıw©ï‹‡ÉM£S×óZHêª©l?°6MÍ7ÚÓÛ ¶ı—K8ËqR–GïÄ6‚C–Ÿš›ÈDB#„İ;+>-³¾fÌ-·ú¾!#ÛÈW¶ÉçU<-ëf›'ÁõVAôy;â½ş—Í-ÎƒfÑ¢’mT½AãáÌŸC¹‚P)™ğ[N²ÊÓ° ìO°İ%Œà|ÍÖàa=aß·YË÷¯‘;÷4şâì@É7=‹–ƒÂİåHñİ¼¼¯ñ$õ6™Àæh–·çŒ<€I!Hó]†Øâåöpú¤Óâ¿ôÊ>Ñ/³öq&>.™áÂŠq’niÔ=ohå´ˆ UfC¨ùcU›„FÅ`m"u0©M:N¾V&»US|N
)Ë,Ğ?œYæ"'øÓÜhüšÜ¤ú "zedlrÃ/2àÄ÷‹ä	Ùµh{	T	{û:¸š•Ô™ÎX~œ "qÂ`%zªk§øñaËQÙN•Ï½`©¶‹wÖ$²pŸ8›±¤œ°l^q<²"ïtcB!%v=èº¯P|ò*Şúe@âü )˜o;~C@;®R²jÛÓ Ô×uRåxsùb‘jAüïNó¡ XD$l”ı…ÉDÌ;÷i‡ÎÈoã^A…v¾/d„ŒvÙ_Ä~yô-´ÆüÛ×z®Ğ¶^àƒ#sàp(pÿEø_@ú.)İ´UCŒ^¼XŸCß• 7Ø¸höeo¨b:ˆˆ?…§AÔã¸ZP4ş´íBï±Œ¶Ÿ=ÀèT7\‡
Op¸ëèéAb¥oTtXÍ%àwy­`ÌÔÁ6î›rŠ2T}•	Có¡³^Àüî6D“ê¯õ{È"ªÀëj¿&’Y˜*ĞL:½.ñÕ o°¬Bnaïáozéî<]bm\_Î ŠJ1nXİì3RâalİIÓdÊA«.±?zæ,cŒ¢­ÀîV®H×ğä^²c´YQİSŞU[*ÔPpqíÆ%ˆ8îªğğ¾A)øìò»l=—?J¸\‹}	òi˜fbv\)³#!‘™Ó1
©f¢-j«v;•Ôwş°Ô>¾_ôÜ<$riÛùİ>\Ä–	€¡V™ø|}¡0‚nìœ„=è[ı`ÃvBğİ¯0CÀº×xùwåôwà‚¶úhTîiã¬,at.dÊ<~–BØÅÿ{–%¡Ü¼—ÔãøD|ó!{€—á´>ø'•¢ô=ü•¾¨£»:Vï›|*?œ?·ÓŒT—ù´û©{Ø$qe†iU†fræô¬Te-şâ€,ªBàW}²·Â]ùp{LYİš‚O¿°Ë'ÿèåçJl&üŒ«(BW4ô<7ñŸà
ÂŞÎ0ê¶ÅA¼Sş0Èr-S¼<BµçI¸'ï«HË‹;ûI‘+Õ{ˆW—ü“©:#°Ö#ƒJí2®3Ù5Svæ)r€m}ˆè"ı­
§ådô‚ş-·
Ó¸®üÒ½M%WqöŠ@~8€—%ø	èÙİ­ÜZj¾’ı:p}äGâ‘p3Z5,Ã“d)­Ÿm 5åİ:“Â!ëÍP’Fça”¶`Òû±+Ğ/.êŠe|¡Ñ«†¡C‰Šüÿ¨z…ÖÁ'¦îïDîÎuÃVóú³ŒŠI !3éAËğZ“_ëP~¿©İm“«]Ôğ{çé1_y„Deüœ¢.0­¾z°3¶vS^‡õ{µ»rCqí ™ğóø¹5L=,Ø¼†lğ3NP4Ğ\!±yƒzEMK},Ğ+d+¢'ºşwŸ£zœŠƒ¯05J^¾M*½ş`"ÔŸÒ˜1a•ô[ş~cšd õï$.FŠb60ó/&Àfç"švø¥	tE6şŞìA˜&–îì·
Ö¥yD^¢Í#ĞöÏJİ¤‡zÒÌÛ;œv9Äoğ†Ä‘ ‡şì_Ä¬5(ÕßáùYÑ_2B¿Ôå¼)zdµn7;‚(7$)íOÇKÌ úHwÅ²TJ~`ıã2«Óoö‰Epò…í@È£1nLêk Ùp¢ŞÏO5ŞiÊÁk— 'œË|ÁÁ\ä\ÀS¤ûn@CĞ/C[ö—`dµÛ#F=~8¼2z–)”˜‘M 9–W	€wjå’XµSñÒS=.÷|ßìÈ…øÕ+ñŠàO$ÇXÂ‚+ôşœ+‘I‰ã?ò*ÌÆwŒòbé¦`Õõé‡ÉçAO(&¨ÕÑ7oê‰(4¸mèY\ÛÒ„y]XÌ47´'®ld@Â÷e›Âíx¼›S=¯ù]Q•5¦ÂÚoÊ¹ğoÜ[%C†¨Œæ|´¦íìkÿÂ®»¬NF›F¼¬\µ5°ÁqBo‘˜Ø2*@P
£oL*œ?%Gıú-í®Óå–%åıq-o)2o+UAŸÿWÉù=ƒÀ4œfE´OıyÌÒ‰¾Œ­]\MM2–ŞÄËYìù¿õşµ3ÂrÅ.N•©+	ŠÀÖác%¬%£r»FF†ÿöä/±ªSKöˆOçı‡ÆoÛÕAM‚Û¹t¯™ãCYÔlÊ°¶·OiÂ'Ûaz¯år`0éıWºÁúÊ–Egl±\Ñ	ùc»şÏ2 óÃk_!‡Í‡üø“–ö¢ÁyRÜ‡†šn+Gw­oÿ`ñQpBmÚÆÀé¦]dñsR-|¡a3!›ƒ_FÿÑ¥Ù3èCÌw|Øå[á4m ›'_mÜqí´†.Ç³şËíSÚ£Õíˆ<tœ}ô¦ı…d·‘G°ƒuÆóW@è/Æ¢Òö}–ş·NF WM§BË¡lÄ;OUëÑeJ
÷#áñGQÕ’Â%ÇİÒJzÙ;ö½{zA$…¸ÏUKŠ·¼ ¥É)åP“†yà—·à¿ıV¨íkÅ7b÷zŒ	ÚÈşHhÏnVrŒJtmµÍõ¦-GtŒÅÓhAèÇÔD„Ù‡ê¾ µ£qK‘	ÃÓ´m¤c•šõ±îÈäénÂ`e“²u¨¨‹¦‘Ê#6á¯„åâEÑ1]pµµ*kg!a:7Šö@ˆ:ÔuïKåª3Š¿›ó¤~ãIX‹tˆ²Iò×—3°³ö¹M!fëûq*†»Ç¥|Ï@$¯ŒŒ«lòÙ¨@Øıy9m¢ÿ>¼Ìw¶Ëâ9C¶*\àñòœÃ¾ÆğMÍ»	P£I^çÀ½BâyÀ×A_:şÏ_É]]å9ÃòĞòtÉº`ıu Mƒ( ş$A¾Jİ;Áz‹ÒŸı^Emê,<£azäú,,±ô/àC‹P&súYæpoT]9LÈİşè±°)íiáåG%ºÃ
8úe°ˆxïo$hN7‰ƒE]6ò^…¬3ixHvşr“P=¹şùÛxª½µ'!ÜjÜg»ÇĞŸe7–Bœÿ­Öø´¤)¹Xj“Q³6şm›nÀvÈÎ7„Â:ÄT;]´çy JR5UOà„ÌBÊE,÷vË`¶ßR+³¿¡G¯%0T†x°*îGƒ`=vÑ;¡W5F^Çû&…1·¦™åÆSÃ 9gòÍa2ºTí0Ç|[|}û”û,Ïö…£á(™òœ"í­Ÿ´VU½z¹×.cÂ¡wCZ2ï:çtöuÌÿ=ĞÙ…ëÓ­¥ÈæÆ¦Z4á§«N™òw…?1fj•kûhğÀUÂLºştHÃPõL‡Zh¥} í„½V÷¡ÌŞ¼E àoG¸Ï°Ò÷
gG¾K¦Hwoä·ÿ !;èÍ~h²'>Ú©u{ÃÄ¼^“ÌG¸Ö *SÅU7´kK_¸E=ĞÅİœ‘éjŸn¾% £š·9½¬aQé©<0ÒÃ-Á: \3Ò:S€çvèü‰°%ÕÛ)ıxX³Q»hµ¡ÊJÊy¡v¨aáŞn‡É–  zG€gß8z(±LC„Ş0&&RŸË$DÃ‹/`GGXñmÑIr×÷5S™OC98Ù•^ÌĞìÀ¹Äšä…Á—7›XÜé,}à 4ç#uøéöµçx.ÃæX^«SqŠµy¨„Ì¿ÈõÛkBœG4·™óâË^’ó:Èù×t\3Ô3Åİugä'ù©(
6ÏE7I}Ô5ô>U‘°çVÉÔ}’…AÁHÆ)çÃ­	˜í¤h’	Í ©QÎŸİ¶@éŒ˜>»K9fç@ó=µ¹´Ş&a¶Jà˜Ş;„Ì_\´\r†öÃŞÓj@™=ß¤©É¸!!Ş7—!¥õ‚ä¸~zA\*â³ªç#é”HŠ¹ñ•›‡¢s ->Äƒg?¢o³k€Ã¹Z9šHºÖy·G°¢‰¸¿%»£ó
}S0º±ûPS.š¥[;ÿ7…8× 	U†¸‘®¢©í´|ÿp–"–R•£Æ6Ø‰a-Å¤w@ª¯cİ,nO„Õÿ¦@„ÈŠŞ¹9¸Ø0Á2«•j9ÌŞ¾[²æğı*€m½»ÈÍ±ĞF„”1.³j/Ä¤€QšÚ®/İõhˆshVrcMÙääD-'ÃOµàšX¸K±[Xô	[M5Vî€«ğOÄ¬©Y_º¦UÑW TƒëÅú&ğ…¬#H1Yë'ÕåáµÃH:ŠôSI™¾
"½RÕûŸ†<ÜÀÆDã± Ç¤Éœ¡ì  
Ğ|µ·û ôÇ€ÔÅp0±Ägû    YZ