#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="4079360945"
MD5="0835714cd60bf244d568329861648f89"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23440"
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
	echo Date of packaging: Sat Jul 31 16:30:50 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ[N] ¼}•À1Dd]‡Á›PætİDö`Û'åÒ¢ Œc‡¥Y @%¼‘Ö­/êF­ª&Û8)®ŞB_ÏØW<¶"Ï‹R´B:+ïÌØè×FíŞ3v¤QU}^İbÀbï¨9VõXƒ.Ú{^‘œš½(ß3}PıÍU©‡Ì_©Ö”}
‚‹(Ùú‡Šı²(
¹Õ´áª ›Ã ÍíQ¹(aÉø5ÃÍıĞ‚
"]ıü²“8ê\­¨ø2ejtJÄ‹Ñ™I¤Vf]‡Æºå±¡T‚Ç?rQ©Q¶P‡‡ŸÖè™€]¾Xµ;>y-§·ƒ4ƒ>^ÚÛB›8>§íÌ{cüShXÂÆ±“BtG‰;÷‚€ÓAß­¹&§–ZĞ»‡ª;'<âÈ0òŞì¤Mh5Mµ¿øò}Ø½Ö’Øˆö½Ëê”M,5Ä«œisR›-ÀçÑÜ÷¨Óò»Xz&G¤ÔòìıéTÙö†Ì^èÌ”Jÿ
õahĞD÷ywE6¨ø¼]šx´|½BÎMñ2 ™â§åÕ÷Ñ¼¶£O® ù=Ø»Ú×ã)£I{/'‹ğhŠWxDl²“f´ßÒ†|ùªNıi!Æ4IşÛÃ­œh{5UI_ÈÍİØ4Â\dŸÙşK–®kDZ³+Â"8¡°¦¦¿4+‘pÇ#rW†HÑZ@pS!‘¢E^ˆ\xEL÷äà¡ ‘6™Ö5·\<'gâ8Ğ„:İ5İàñ—¸…©W£&ÿ‹¢(¬rèšs¨W«d½KãŒ—:g<0ãF1İnß^`¨%ûß2ëbşÚºét2é:ñRZÙ¤2Ã bŠ?j«^.á~p“9ˆüŠN±MÚºÊa§~Pìm	•ÊTí x§Ê7©3'“ÉobQ³P»"Ğ«¾Uqã Ÿéâº6zR„*ëö.ÔÕÕİw$µ ÜZÕÎ¬]><Ö€H 6›‚¡êÎZ‡a£€ è}Ù¬_éÍäq#&ì‚aÂê›Ô˜@¬›oÿx@O›@`x ­F
Ô|\ç¦ÅÏ˜İ„I¥×Î«I>(r¹?S>¾”âlîw4,2˜!{¬\•!‰mÌw±=ŠˆY³¤wO!&-u?C(ºYİ¹ÑØ­¤ú‹¢Âh˜œ…svÃD>êt=¼\ĞïB(÷İfòóh¦£¸K_,”s~äÛLwÂÙ }Ò¹´ÂT5/'X—õœ‘mrãßG±K&wEèìÃ¹j8èy•:Ìp^±C	0N¤.Ç“ÿ0»DïV?Z«Àõ¦ÊxU³ZŸXsËY»+¸ô.™J)hÀvo‰ÍÙ3Ì uˆ |‡Jé¡åïN‡`V$Äw4áƒø7r¹w‰_ªSl»¬FÑ$™Ím–ı†·üœ~Ç!QpñĞW);W0ˆ£(&j$yŠë†i×~õ}6cÀ"ü2²˜ê+ñÇ-ö¥Ç'ú¬ãqvæóí÷vŒ\ØtĞÑñ4u¹i”uºõšc±z&'h^ëæ+5½uêårÎ•;´ÀTFHsååÓ†{Å«TäHÄÜ„Òê“ß&ÆÏ<‚…Ÿç~d¥ô%ŠH„©Ú´*°ÆiĞ]ÑgoY ÕeRRCä©ŒÒgª!@oF\lI,‡«¸µuÎv»3»­êEbãø]Lÿ˜ÔSDÿÕœ›Íâ¥Ë`f)†À|D¬9%ˆß¢g½JØ_—qµ/9ÄÙ©ÓNûW(µkG›ÿ;jÔé›¤bs³B¦;QxQàºèï€	‡u˜K/¦l9}•pP½W…Ø‘ˆQÑhe¯µäˆ'Àà¹%‘R¨ãmzqÂ«;“»=œ²›ÄİÜG\İ´µN›Ø¡ÅÂ‰aó§¼S¬yíšb?oÒG \&Õ,ı}vbR2£s¾¶Ğ‹£/5t§ûÅ ?œ¤”(+æI(g™IÿÌ'€”&xİ‡­fYÓ#üNÄAå`·¤‡O)”üıı`M@š‹asö9×¤½ÇºS§ µZé!e8Ò$ÎGF­drsq$NÔ2àõ)ŠL@)í_}¦€—’£HÊarúø–\V¿ùãEÈ›ì^tv]œtÔ˜Úµµ¿>ê›ò‘LO >,w3‹3y>˜-L>âë¬cÿqÔH³[-Hgğ¶­Œ>$m„>!ÃÌX'S÷Û€òfÍì–Á¡Ö¨ä3#¬¯¡Ä—–OöŠFŞènÖæÊÔªvƒ
WrHr¿5´é­árï!¦™“>=fÛ0LŸR—ä§ï¼^9µlm/¾<“hyÚÛg3i‡ûL¹"_J£a¸‚v›sV©üÏÿc+_/b”ö¢ÎC4Rvİ9Pë'…š„:›4g2K àTÎQº¯@-qsƒìúLG^NnÿeRLh£OYÅãM§êt }…0šÛ¿ÔëÑô52øò†p±;
ªx«·£kv›²½}/ql6‚Ñù
G‰3ËX„9\8(¤äıíŒæ${LE²ĞıØã9¯Kà‹šnËƒ,L–!ÒáïìM{¦|ˆ<ÙàÖ¿|k‡Û×Ái—R‡C†Æè:äªÊN¥,t×'&Õ®×ê"p­TyÀle`
¢â;×júÔqwp¯-Ä°Œª€lU§•ó–°“V.*b×6’¦(!‹(÷kuâÃ¦~èˆ•9ÏH26â|ój ±dÇ7oÁ¯úÊLùüæŞï«ß'g102ÂÃÄ¯ÿLZG¬˜ŸjùaÁG‡;5¡R\**FŞÊœ@N5ıáujƒ˜æ§ô”Ù
(¡0f÷q ;ËïÜñ v0 ­¡ğĞ)Xû¥X[‹¹)’ĞY¦jõM¯çÿ"†$Œp5,Òø¦Õ/'QEcšÛªd «#rP"5e_ÜKµWc`|‰:jzSŒ•´O§}Ş¿>«Å³=*à|F@ºÉ÷>û\Ê~e©oµÊ€eıi@uUÖ75”z§ ˜µÄs–ğïŒ4†Ìê=üUÆ
éŸ3`2Ü›€š ƒ™ñÅ%ò¸?°i;ÆgH§ËI%Ì£KÎÔÿ]á²îàfî)7QlÇ¥ ^ŸÏÀy³x¸\ÎıF ş]ÇËÂb‘»şå„Ì	üÊ§ÌãLƒh@œ×ĞH^“îş‡D}!”·ù ‹µ
=Ê–`Ü-d€Z9Eòş>·´éªbk¯Ú–øıbg-‹çŒ/ê:@ª~PAg*ÖTÜ‹şÿu’üT“SQ÷aÉÅ¥DC¥­ü±şê#ŞòÀŒUıç+Ø!Úàï_åÈâüœ%ââ‡((|¦òcö¬!.4…Ñ»¸1­H6˜zXƒµYWøçÆó@Rr@11X@kìTMGKÏ^ãBÉS‹Òµˆƒ)üU—ytWøåí;¶#` òQ}§W{`yiŠ›:çUÈ“:¨JÙ& Wõù=ÌEel>«jîÄÿ(â@èºéõ×u~Î3J¶äGfë‘üHdÆãA`ø‚ÖU"™ò»št ¯‡×*ªì6åöÈßö’6I+á”¶†P1»8äõ^q"sr0ñ'ÚÚĞ9ŞÎf¹I›*ô)L­ÀÉKğ§ÄrcàcÎ{'ÀJÔ¤võå¯µJ÷8YN‚…¾W-Çé–ñè-!™‡ZM¢ñ#	yHşWÍdZ7˜´3¸¤êÉ^uBl-¸ÛŞĞI¥uàÛ«yXÂL¯^fk³çhDzIu¢’‘î‡$i‹Àó?;HP‘f299dug²UÅ9E¨`{!‚PŠ<\È²—õ…#ĞŞFìš(´—&ˆ@­',ß„’t"t-`*vJ4ş™°Ï]~F	sæEĞ!ì/©qİîè³©¿Äµ
Ì–©Ç‰ÑrÓ	PC	M·ZR
q3i|†UÀn›‰»ÛÒMÂ#¥£:üĞºj×:Ácâû)ô)‰±;.Üàò¥œ»Ş#¼$Ÿî„ºÅ/­òÄÖøQÌdOpPGa€Ëï­’6¶",Œ¼UÑy|›oBï7{Yë‡ÑŸŞ>^}«ƒN¥VÉ¦w°~ùHÒš‹Cê¬E%áTİ@3b¥”ol"â$?¨Ò öxG¼(ÍTmõƒI¤æ5³xãA0ºÅL(ñœ£…¨É5V|y5}V.+ÂC‘½cw€\8”µ$$‘pl¨ËvĞÃdú9]³¹UÔÕ%¦ ‹CÏbh×ËÜeˆŞ&ˆ|‹˜æ¿ÂLÔjxøHàpêß\öDsjV§4^Ñs#V¨è–! {¹…<s<¢U'²#ÃÌ%ŒlãÌÓëd*ÉÎıĞ¹J#C@›®‹Sbô8^ß„cÄ´êùÍÆ· r³\ 4†³Ÿ¡„†rÈüV¿WU
¯qëZP÷	Nâ¹åS*Kº|¶7¿¬QÛ\ÏbºîÅÿ^J"8IÜë(k†v*‡‰=Ûû|NÄä¨…ã`ƒøs2)tnJE2 )ˆÉ/wOn¡Ji·Äú`)Y+m­¾b‰Ø¨è½KrÏ»X·5Ø±ò’q½Œµ1Á¢l(hn[Læú›¾¦…ŸÍÜı¢"hmyşç¥¥‰¿â!ß—oxD4±u¹Ñ’ ÿÂé¹±+Ñ—,îàYY'ı€|h~§&¿V{›Ğ}ñëªr—®¨ÆØ;uj‹‹bhŸÎYø{²˜´LÕ3ê&0õ%ÇvıÙ%ÛŠ¤¯Hıœ­,mo«[\Óô™uœÅà$-GÏ–ëÂ¸Û{°×‰Ab£–%›£=Íˆõn™İE` ¦
aAx
¨n,ûO2u_<w€SÖúyT^&”ênÜf§¨óáˆ»æ1‰Ñÿ¶Óõx­Ú»lB½Ã«£SÆ£›‚ap¿ÖéùÏu¬‹ü¶åÆ"ßÃŠô°!«.ô`Ÿú	K´.?€¿`k™ğûı­ûZ¼Ş;¨€¯
x¾ÖnËÛp·YDn‚€µ!–kÉ×}¯xğw«È±®!Z7òkŸ6 $%ğûËYmó½6‘ä“ak9RÊ‘kÅ$„zøÓáÂ[İXshóMôŠÙÖ¾±AÙ¤Eg¿°÷«iLm¼ò@°T´Ğ'æë|â@³ X•"ÿÌ•Õ(ìıÏ|XÌ}6‚ùC±.2Èš*LâıÑ°NÎ§@éÅqßÑµÔÎØÏ)ĞØ·e±óÎWğÅÊ4\#„)pq$åÏ“`Vi†u7 “©—Ä“yˆtÙø/±íZ¤}9£4’±Õv´@¨šßÙeß¿¶úãƒD…í¾æc3;Ö‡ŒéùÑ :tÂÅN/$—35A !}@ì…	úëQ’.t&Ç-—&ñŠ¶Œ@“kãœÌN¡`_ÏËf¨glCè*§€ùÔ(«@e"_5ñş@)"¹\aŒ#cX¡£‹„ï!ĞñajX?¼y/Şİ"Jİ’±Rv"^®Ì%
.¦IX;Ç?ê4O5³R[Ì§¦ı?Kñw·Û -SÅ…ıx˜(ı,ïf¤6y´¦!»~¹#
_!ÚµÔÚq(j£°ÂÂ¾*uuÂCİ¨Át­xş£á1
¼›—&8Õ0U?ÄZÊˆ.h¨ÍPL	'¸x%½^+@P½SÆR¤"S¼&<JĞ+™®­DJÑ_aªÆ,UƒÏ µ«oÀ@^ÃK<û¦Ê“vœé8jò£E€wt’8ï#HíÂËNüv™g³P˜ò¸=8˜œj}Š¬Å²Ì/) ÍóŸ)"3S;šÃö;ïóYD ¡}z¹Vƒ¥m#aĞTFõ÷7Pñ5„j¸F KD­ÆÅ‚æÁ•*îø¢™	(ie( •mşÒ­}^"kæ¼ÕŞ\R‚§ív&âä1_ß.õ.É.„Í
.éóš€Ä/Œ’y¾_¡|³„?_*–{ê'e¦ïÒÒ™(åtÆ®	¸Ó‹_U¨­å)Ó(³ù|!û‰‹4ÊOB°êX?ì¬Rö«Ü§ü¡—°cÙuR¾¹¦ßúJkZQâYÖ!GÆ—èx÷Yş{GLûvdÊV©¸|>H»ÉÏUX¢“'$k¥– ÷é ¹ı «W-”Š‚ãÌ¬m)×yŞ=‡ÙmĞD=îÔ4g±S 1†àŒV¢™­$&Éiè({ÿ®,•?•Â{¡(Ëç£+-øèø}hómÅT†K3[øtåÊXÿ.ÒÌ3¹v±]bïkú>']QaSÁ2U<RSƒá½›M	xçF’Ú`
ô7œ'ª«v†F-¿èÂRÔ§’BÔi<ÿ)6vª´ !&Aåm	ù\—ö.C+ì¾øín
…İ6imğ“Éyœœ—‘ş„K%Mµ±éçÔ’ù¨ã€¢£’–¥Ä7+Oå‚1šäıƒ¬=£8ì#—ğæqi`Wãi!6¬ oNgw>+úwœ6‘IWƒ#Æd‹È çÓ2÷¦—XVŞˆ‘®t[p=ÈóApÎ İ…›éŒ´·¹Úöævö’İÆ@‘;C›¬"`ŞA½/‡È¢H©ù)Q™æÛ¹æÎñvq ô3‘¾½ŸÅh:®€érô§¨ÉÉÁsìç,ªy(’] 8…aDY!Ã¶:G:×èI“ø´öÉ‘˜-‰èÛujY%S£³·Ã0õ|ƒÌià¯¨Û‡?S³òêe}§[÷	4çŸµçg=7ï$²Špø€ÑÔ áÅcZÉ¿‹ãj"ãÜØX+QŒ@t¨ùÀµ–†¶C±¼k‚ûÈy4|ßhâFÿÃúæÄ¸¼Iõn»Ûn»™CĞœ”I)°<ûª—¿{·§ú‚0Âı6¾_½_ï#ÃæšÍE ]NÇ¸°ğP ®æ¡oå«ùüò4`¦ôB=/…Xƒñc¶Ìô~ğñzO’ŸîØ}Idó*r%G.Ï\ı¡Æ&Ñvk@‡Æd±™7­É6>$ üBÊF·5-nfW|}IÎ˜ú<vZ#ßÜÜäãhagæ4ß`x‡£r°2vˆ£÷1âfÓrê çY¾<ÂP:ÛäØæK£ïÕ SÃø¸55Z´j5ÿÈêÜ•’œé/¤ÀÖ7Ï^Ø‘×Y-N’Z‹°÷"•fCó0œÈ w¶ˆ#ß,€X$F}4çÿ³JC€ÕÇh_º¥QN^S¢¯j0n1‹p	UËŒRï»M©zÂÕ¡R¶b±œßoÄ÷Â¾lÔÓö$ãF¯‚ÙÉğıIICÃÔì¤½N ²•ÿe`É%[(ÉŒåŒ{N^AMkÁ‹¨ãÈ€2ees‡Í\üÀIIı
ÕŸtşŒÀ2ÙÁFÅ³Lq{˜³†Ç¹7¢O„OD^¶µ5oøZZ¼ØDeEyªT£²É–#İP'¿û»;À1É,cØÏ¨\ÓŒ{ìY«-[z{S.j µJ-_ßwT08ñFB*K[ö2©ûSÒzGßÊ¼öŠ>\?Åjã=GòJdá$ÖÓÍcÙÎW5ë¯€À¡¦bµF×Ñ&Ë²»÷şû£Ë]æò”HíÍ»ãÃ0ŸOË5 &_¤€tèvQäÈ EZÅĞæ ¡Ğ
?½¾ìPßìTXkz£y·Ö²K<HÏå
ğ£NÏ…ùÌòÊO•Ôıµ[;SãyÓ JÇÔGĞ™™PE›ˆZ4%–<k–µ¦™²Ÿ×ÜĞw8N¬ª¡Ï¤ßoÛ*=.›újéÿĞ¶´ø³ßŠîd¦o öø•sá@GafğŸ,¡&şËıuô‚ğ‚®{FMy½§ú&h-Y„3 0+wPÑ\ÿbˆa3×"t{Ay³›$íDAYÇ8É> ÿÕˆ"ZH÷ÏÖEÔ¹à Æ¤z×B^uÁo1ÎgÌê÷—sàAg= ?º+m_‡;zõ¶x¾ï©ÿ.€¨ñ”?rim®ìëaf±|%#Œ‹3´váY<Ë"l®^É¢ƒÊşˆÜÂ›Ál­'Y¼Ï!dB ¤æ^§b8Ä²D&‘æ°É¬…ƒ%hi€V¼p µ¥½ÔÂˆ5•kæ	ã®¬Ü?ŒÜ!&œ{¹!ág ˆ3Eªìé¦5ÿrÒµ…{0h’­©$V¯r€Yl)İEcabÉF®d„Ñ£ãIıüe‰asÉ4… »|9ØÊ‚î‰_Í‚mÜÅ¨Õ…;–€Â0IUÿäŞÆe¬ñoğ_ ŸèWC•/ÂÕGGQüšäMIdÁ¸Ş8tÀë¬NºŠ9³èôõÆ·¬tØ[Û?·°¬¡§˜¿Ï–hì<Â{gŒ~/é€™Yµü¤]‰ !¨-‡5`>Û˜_©Xµ®™ƒˆÍaÔ¤÷…ÇÇt(xÃ$¢ó¥«Œ¥ZSş‹ªåò½Qã{‰&b%cèg´$Í€¶zŞåN!->É»öaì\¢¨IÀ>ào+{õ`ğB1é6z†+Û“°gE#ĞåÑÔÁ4uQõÈ÷D†G4sÆfïH Å	·b8ûŒÉ{æ†o‚Ù:ŞébŠ¸ÍJÿS//âõHr†×)qz‚ê;Gú6İ;]‰½µ±AÙ,Ğßg“	&&º‹0üÂÿ¬Ò$ìĞYÇâ+Ò9U¿Oº°ú§ÅHºuéºôYuŒYíC·oMW‰pÈ _÷NÛ³U[	8ƒ¼ç0´ŠOª³Ö;N8~YÔ$IõÙ½°î€ÅñQ2CÜÀN´è_³™+Éšûº°2¬·“ÅúÆHÎm’€pß»1ént/I¸u™n‘è{ŸGı¨M(€S¶‡?Áø$Ñ÷ƒÏg(Ğ=’96œ#æDm	[{°õß7Á”µ<ÇÙÄ‚3@ıs›_¶ªÄëß<hE3Ãdb2VKáóp[eX	¯’%^a“Vz®?6x¿5…‰	Vpnøà±Ş"µ‚%Ô0–[_\ø–@Ût]cùÀ(F\@Ï}Îzî´^À[P»ÚÅloÒÿ®‘iºƒ8ñ/9ÄJ¡êxZ#(à%˜êUŸŞ«ôg¦°ö=T8’éVi`ûÓáÉÑä¾ª„ˆ"šÚX`g±Ñ³%şG,r«8Ï›AÜÈÑ‘°Ö÷`Ä’ÃT=;ÀBT„Ú5URMÑ–Ã Fç°‰Å-6Ş¤yå„¦¤ğÌ„6Ñ‡ğş ü‡N|ÄS “¿˜×ÙQÛáÖ‚Å¶åÕ‹üI$CKXKy€³%pôøj36öHrë¥I¥±MÙ
Ú¦M·W®jõ´J½©†–ñ,y=ÁëÌ‰7/Y½šš0ÚvŠ@è„°ÁÌF£>“/ÅÒnpy^?§(‡ˆŞ¥ıtH:•rdÿ=àDßğoşO†xb$‘ú¹@.eÇ+¸*]ô¿šğÂ°¼ôö’.Ë³³1Õ°€ ¢nq(y°œÈNŒIc+œ~~+©eÖĞ"óÆFj(,‚+na­Y@†î(ÂQ’|r³9YKÚ<p„ë
=[Z|;çfo)ºE¾Jj§v4Ío. fK Ãá©ê.:ª(’O1HAûã ;‰zø‘`~ÓÊf…ºMæ3Œ÷#‡Ì‡-Ìoî#Äı˜ÚÀQsW(r|ÂäïË%`v“İ<Ès8C`±ÔZùÌÅ›“0ÙîJôì­ÿÁÅçgÎğòQÅ¢ªF³¿Ÿk(êS_Ã!»Ò60¾y…®Ô{ªÄ/ã_>î…U6'ãV	' 6G¼&’ÜA­·ƒJàÈÁ¥Ú]@}$-b›o¨·’')ƒÆ×Óàé!¥Ôa[e–Oë×„ñ&ĞÚeLé‰˜ÚXF™zÊ”õÃ·½ŞˆŸhÈ&¬‚– ÄSÔ›üM´fúµ™Õ§Ç†H—ó2‹Ñµ38<%{Â›ıKWŞ‘ šºùÌ¿8òmlosÑ™ˆíhD±¶É	RÊ#`IV·™_sZ*mÀ¤ürˆf0C”Ü†Ë¹Áš³²î¬³×0XbÒáÀ„§Ñ³mïîå]&ÆI<-†våêíâÑä4Üo¥§o:ËİQ*NH½İ2Ãƒ„ÄÚeÁ.æ9zm÷¼nxdøÃV]UåXšWan?ºÊ"Md™«øöÑgŞw›áEó&ñ›¾Æ– väØÇs"g
%oÎœ­5ì.Şüç¼€÷£¼´<S9ì5gÿ”’vÙBCBDzÑb4TQÀ|+:Î¦\Zo–dd	ñó‹t˜°3ñÙ¶âßyÂá´¢±„OçÖ_! UJã:¥Ùÿ1?"âÁğ“Ş…ìÄ³köüÒ	³‡.¢-Ùƒ«	“7Ì%­uä•uLØñ9³û(Uê!ˆ/±)ÊxÇQ²J‘•ä§§—ú¶)©™ıÓP—OëE•±)–op€¥ÊÊx}:,µëşèSš”¥Y£¤“À¤‚iÊ÷AJ­tQ1 ÿ:›äf†G®¼%½Ê(Ğ½3°¹ù6œW†¾îÂş:\ğNŸ(¬Fh²y‘¢s£³ lèÄ°ªÌÚGFÄxéLîÑÈiê«ıt5B%G°i»]—ôA>VŒ°‰^(¾¥¹x:@K˜,öDş£m¹­=^Ñøzä³@9`i:ş{˜yFå|gÌ	ÄÚ¨.>¡ÑÕæ«7¼y×^*DF½0û|ÛÛ“˜/×ìè7coÊ;¨^ÏïŸÖÂ±#ÓæLÑoosñQÈš×Ytû^m`ÈFKÏ•û
@/(!_2ï’Æõ¬´¿.ó·€#ÆdtËš+Pqœ'6#<Â ™Ü…sª’#n;àòÆŒ-¬Ì?Hœ1[`O$"#uC®ú*ìuwÃô YŒ¡Äé»å*ÖìÓä®ò¹nL‚ÄâÄ&j¨úqâ·…ÁŒ¸×Ÿlõ€]°Æè"¨ü*uk¶u oZÎ2‘áiDnÎçn,ÀÓâº¸æà1$€wçi´ä5°-Y”_o£:ÇodBÁ­Üßp&%™ÅÉğ+RY|C{Q9ĞÊ\Â&AèBN9R½Ä‹"X7Ö••{W•ÿÇ‡FHrqóù(‡ı–ˆŒ‚#,ú(JÛ„ñyõˆö²À¢ô¼Hİe=¨ë+Z}^šÎ w?æp:  H|KP¿ºïJrxè*©O››Zš¬&òÃÖ¶y2úÇïš‹–CÀ\E÷‹½Oow–Y ìåŸÙ"vÁDøš”†D0@‹¦eØ.dx'Oï/q%(mt+[şAY_ëVå†ÛÁ¶oyhk¡­/á÷úEC"ÃF“ßÅ¬ì$ƒ±ñî”Àe¿¥*í¡X^CÑÑµ´ËwÂÖĞ]º×5qÎãu¾ÛÌw²F-ËŞÿİQ…°·#SBÌ!óŞì²–ğ¢ö0iÏ½ ŸË3Â¯œ–	{ºË!›4´ÍDù7èn•NàÖü.ô?ì­ïâØ|¼Õ—óvg|¸UWP‘³pè ÿ|sÓFî­Ù€B_Ât^qeÜ~‰n/¹¼Œ=Ø®§'zŒBİ¯÷D›˜ÑÛÈ·ÎôÍmÆïI‡Ã1B9zB˜­Ã:i+)¢Áv‡ézø‰|Ø6[Ã‹YQj©d/Øí–¿gl=˜yÎ®¸É±"4©SÂõM§&]ÀíöµàŞw6Q†Zp³Â¦Ìck¦©ö>‘üß7•K…r	Ü¦`S€‹T zhòç¹›L¡Y±ÊY-ÖÄ2Éç¾—Ò¤&‡G™·l‹’¬£5¬Y;ğB„/ÃnM	Õµ*>ÿvq.»ç¢»]»!BLŞ?FÖL,Q§[Å@–¸Ú=ºø]¸ø›İO¦„ã< ¿ÓîşqàÂ*k¯H™IuRŠõ‰û’ÀŞ¸¤@K'3š½l6ŸÊ ¶P]†ÊÔ$EÃ|P7>œİú›h%•cƒ´pî5›ÔxŠ 9!PSLù,™os&2ç²´1Pi™úÀWaôIF8o–-A|…qåA1¢¤!ËIMÔœ{Œ¾‚Ú:‡¿~TñvãÌAG}Şeó\×tvíVl=g½k0?Ì=€«R÷²zÇE¡y!ĞJ›y·r¢…V£™ÅÁÑwLşåú÷iÊb	,&“±ù£x‘‰À¦'>h4Vš(^ç¡r\=¿‘dÌ›B=P™óÊWˆŞ¨¢¿LÂ)3jkSsÜüùŞåò£ºÂsš¥al}!
yòEåEñŞ<8õy#À®k¤ë$n{ú±2Ra~YaX§şeù²f’¬ÄãÏm‹srFÈÙ¯d±RÿSn¦³…fFóBÚ¬/bDyC}O»Ü
¹<újû&—bÿÓ«nªïŞ€jnRwú‡ú0èı)ëßebîzÒ5`ù‹@àÓö¿D³å¼Õ(6»€üø¥•±Ëú·hašŞÑ+O>Nğ>tÜ§`ˆYªĞFôD	|š”k''¬V#"D ¿øD,ğ4ÊdgÅN&eõ–N\"ÔŞäùŸ@°ş9uóÿëÏÇ±QóTË_¸(’ãÜAÙµà¼õ(s@„öŒáXºí¢`t3Fm

Zâ!)VÍRğo6	¬!‡â—Ë8ÆŠZA¶…¼H«‹ycñÄ©£Êb´[)$ô*8e9'‰âZÓ1±¯x0JÙ©c‘ß~
êà«ÆÚ5Ã4ã”8sr¥é‘†îxã(Š¢_nü¤8\Ğ 7!“Y,¸‚ö…â×Ç£\9°íJ })VÎ[ä5ÃY?ƒtãuÅšş®ztR
wº1ıqJ°y}q;¬”•İùìÏBÿëÿ×†6A ØëwGD"Ía×Sş †u	»­AÏË‚©¼œ“êC¡üO&¥•—JÀ
¡ĞçŞ(-î£¾?¿š¾-< ³ÃŒ!e~ß#gÆĞ¶\ªZÍìè`·|pĞ(„$+-øæov­/ç$4­1Õ¦aŒæjw_„MUÊeŒNËÏó¾” îçüRåß/q]n·àùT3Õ÷•
¼`„tÔo_G;Ê3h.Ãô~Ï»,1m>'™‡\CqmİİvÓ€32C?ZNAú4¨¸wÚHÀ$ƒTTıkFÌ]V(¹¹yü½ù3JXk²w|å>U2:C¥òÏûMé!ïÊ¹¦òÖ-4•'²ŒèÓÑK¼Rlb'aw2|%æX˜
¡#M ‚GÃë˜¸1E’v4øc.ÿ,ÛšÑ=Efp^‘vèäÊG§Öõ×M¢ˆ‰|€uxê:á>zğ*ŸP<QrŸ@ cd4¾…áı¦i^„Í#Mı„'ôZ‰3ÿ'Í¾İE­imÏF¸«ØÁH'phæó+_•<°³i’>Nòß‚fòPR-_İtP@üãkÄt>Ñ7;fhb×¢«9H-"c—€{¡#¥«UpªV+l³¦·õ[65Ä»d´Â¤Ç“ğ›â¥¡Ë×½*” ®h’„Dr9ÊAxü:4j‹±[Ú¸X…?­b°8;Ö+Ÿ£IÚ¼yê¾½Ùãç’Ê] )`V€Æã{0³ôæ²Uí†Câì6ÎÄTÎH,ì^2ş³S/ZUaLşxµGËboÓoì^%ÂŸõQğšÖD£Z¬vØfÉúz/8H)·­óš§‹)X™ÚY¸ÔãÙ&[´j	-~ß¾úıò­ŠòjĞ.–‰Ä¼2x±O‚†4 .ÅDP„Ø¾A‡ö—˜spœ$å84Ø”Lš›õ¤fÿZ/,VÂ]İ”ì¯Ş,š ñ¼–/Æ8+ë¨8®°‡öSzŒ/JD™ìvÉ£q?Ÿgs„é.ñÎYSı™âJÆ‰qfqâ gú…:»XÓĞÜSä ôe¸’×ŸlN©FgîĞJ<•áî¸Ô?¼;lÙD]°\Ü)¸ãÚ¿ ñÕwF
fö²æE§Y'€»¤CZ$M–ßr
E—3›j‘Z%ònçlI ºßAhx¿ éìÅ¼—6oğ\;|l·Ç˜5uC,QpÂÎÙa$8GÍ~Ã»¹Ó`‹ô&Tú~Uÿâ³©¸/éF?"İFvğ*K!2€j.ˆE4)­]wŸÃĞW”UµÉùtİ¨ U|ÄèRHßVÍvR77ŸïıëUFÉÒ3>¯ÅÀF¥x›}á:ãÄ#Ÿâa3ş³Í²¨ã(f¡Ş“Edã9ˆ*sdP?8ez3'ı…àÃ¿,í²Ÿ÷zo=ÁUë1+5òe÷÷šX‰N‰S	Odô;S] Èn¨ŒÒs}ÙGŸÚ	Õ2œ~™Ñ 7áEÃÚş•İ&P:S×èâÅâÔ£2nD|Pô!¸	—#şéºU¢fs×š¤¶¦û¤À¢nÇCunë`=ğc°Br+²·ÛÜd)Â|ö Æ¸#ÇîÂSØ¤BÎÛ:`_±ÖùãIˆéºÒŸß–Ï¬Æã©“üÿH¥õŸí’K-f“˜õ©m²Ó­×…×¾êO‡ï´ƒì<i{–nüXÊàb¢yæ«x¥°“S~èbŸÔÓ ÖÈdz†ÛpZ|)›ğFc¢°a¤nŸ<:GÚäj¯` "ãÀLËáVÃ„{ÃÃôÖ¥áÀH¸èWÓS)¿^nl 9Ü@”°HlîS˜ş Çå3iµı­kŸ,­Tî	Ùòîƒ±X¼ëå>‹øò`EÌÉú¸¤4aüM˜½Ø ÙI$˜¸óRïxSòü%}ñGÚz,RIì/\÷*+¦òf|¾`"CXc§-ÈñOµ…9?ƒ,ş®N	‰ xŞ†(@œ¸*(ˆP±¼úr 5äd÷ïõÓ¦’·§2Zu;ñâ†¢ã	àU‘€ı¥ËI¶ä*ù|VÇ€„Õ‹ˆì‚Ty•ŸîQÎ8ÙûÔ>>òâ¾ÉÙ?q¦*“wİ8Sã= ‰,ƒ8É÷áÄP#'s-ƒ·}q\¤Ó÷gqÅÆª8O>¯‰‡£@;é²ñ*øuÇ†ã`šÏ`ƒÊ¶ˆ°i‡ğÔ@oåõŸ¢£@À“Ç­ª`‰.,É¿+ÓìNãR¤š¾<@ğ0+¡0tõ?ãUo»Ô=ğÛ¦!2ÇQ´Üç¿{w4–\µoïEµÂø,D]¢
MßÿÄy+ÿ²¹9Pe©ÛN¯.½n>Â&ã j˜¹‚t.”A$±N„í)PtX+2ƒâK™!’-êğŞ0†€Ğ²Í~=RÌ„NE=ÓiÑd§ò–|ÅĞé¸å¢P“Mò‚¨ƒº;»©ùè,†Èïç,Î‘“~hgj,µR*0,W°]ú‘hgÛ0œ	³ø®´<‰@%oíºæéè•Úï”e#i<<ß,çx’2ùŸr®e›ˆú[’5ğ±¹ECLí88é3A¥0c[—r~{£F	£R¨:±êw$µÅrodÊñ-Ô]ƒ)U±÷µ9£À\=­t}ÇöÉ¸á›P @ww9„+‰F ãhÇí˜Îi$Ö~m9aÅMŞøj‘ƒqêû4˜`¦=ã(ÀÓo>y{¨%ĞhE‰ÈUË`«éĞôÛò…½g¾c‡4”Œ¸™…ä{€A!²×?^hõÂsír‘şŠˆ"Î™èsD…’(.Ÿœ³Û[—“Wd-ÈÑ#—§ajA;óäû0ãH€BWğh«“?@5"7M2
'eşÛ>§µË¶ãĞ2SÏŞU¶»ŠLReÙ!K÷ù]˜.µ„›ù6üĞ¤xm}!Éváµ÷bÊ·öJô¯}„==¥-Œñƒc×İtCŒ¯ŒÜ¾K•Lèo+ÃOÎ›™>:qYÁkàxµò»Ç¬ªs¡,›†`ƒÕƒII]:VHW‡	Ú/[
ÒiH¶ä½1]?şÃ{ØO×©â.­r²Pz'œÏM ÌÖwyÖ«ü‚UÜü'rÖŸèqãg.¼`Pa•aœÜs×© ì¼f]«¼OüØ"ø‚zX¥¥í	l`ÒîÊšôĞìœİ»„âqŠéÑÜU1lUHá•Î•vº.ß’–$¡aÀÀì};è‰÷ZoZš³Ó	íq¬7ofşhJÂnT?Úe®j»¡0«è÷6°vO¦œÊı!’.TÇ ©Õ¹€Dw¾ŠLÔF¨R¦wìú^`Âù$EÓ"#f^s¤<„º=nÇİıòÎËr»Š¬¼´_c"«…¿°ÛŒ,üM_Ö|bCQ»r†‘ø¢)4Ş¦„šàÍ€Åµe¼LÜŸwôçíyàvÄü‹…ñ]"!6´JØU÷vÆ.QÚ'IŠYØÔ‚HiÍ`¶Ü!	nvü*Wõ9ÛŠ;_#UKGªx3CMN"tÛumNác<³Ê5ûÆµ)§pføZ/ Ï	PĞ××µY-æG><Ù`TPs‚#‡`.IÍÿ"ÔgAÇá^•DãDÎãD•s@6ãöã_“ì­0ô	$ŞlæÚAbßºLŒQÚ%ÜŠò¨¸YÓG
´´@tB_{„ ¤§«0Es¯>Ôp/†ßäãàA2HAV«ÆÙéŠy'‡¼ËÃ”÷lN/ŠÎƒf4›t
Ş´6VóÙ¥Ê5_ç¸¨"Ç1¿=i0bĞ­
®{#M™İ<íÍDJ´Še¶Ô¢+1ÈÕYo)ÏN¬Ê‡»¬šQ[+¢ˆÏbMæ.	øğ"º>â£z 
œû°ß_pb1u£¾I{å*âÅßŸZ§'*u·PEFcÒ=Ú½DÜ{†äİ}¥İæK JHvK‰àèÆ²ÿ6êy™õÆÄƒŒMV›ó¯`jô—^–± \¹Pñ%.U•:í¥Ä(ËÚdb
guhîŸ+fB¢ÖñŞM¹'Ì¹Ò)æ¸`as®ÅxÄÌÕÁÏİNõBÄ»zg-ä`nV"»¼\J%}GOú<J,ï³„q1ê+6yEãŠ¶	h7âRÏßJ˜ìî§ˆEÌƒW¦Q`ã‘:hÎWğ1éŒX½JÁè<X\îüÓv¤” Ê= 6õºõõ¼aé¢øÂ5Àä¤èacu0µLL8…(pS;-V™,õ!¸‚zãiAÙ`ÆòÄ_»LH=4¿–¯šiÏ]ó?ÏÕ_e@şÜ²¢-‘ Uq”&‰ƒÅ1W,z×yÑ3>	ê=†ëŒÏ‚ÌuŸ†|P·Yÿé»¤8_À–|{>°#,œT ¶EãBğê±Ï‚‰[E¢¾œÉŒ£,Ÿbİ½—xÊî‰k¨Ay÷–qp…l¥œÃÖ›³$•3™v£ğÀÁ#_ê­ ™q½çúv6
{5Ä¾“§s9Jgd_©îfÛ©Vc:
Låç^4¼´´mCìº‚Òê—ŠSÓõ!÷¢Ò	0ª…&æ¿Ÿ>–²×—wCû}¹‡ˆZF¶¯öI^ø7ôŞåÓ›@ÎøÕÒ3›zÜt‹Ê1Íz:È4ûŠÛ¥Rpá0}Ê»eœií·c‘‰õƒËdêÀc“Õ÷J„}:´şN"‹Å p9Î!^£yH¢#Sµ(B¥ÀéU9ÌNf¢)ùiÚ%ÚŠ`¿¼Mğ'ÇS‡òàÿÒ†Y•ò/!ìSNÉ¥´ò½ƒÜ:œ˜Ï’Ö–dĞªôÂøÂ%9¥å Æj§{˜sÕ‚Ãò¾?\€•ìX=à¯ÖÜv/ômW›Hœ‹_ÈÁY3÷1é^5ì<ş2'Åæôûæ‡ÿ£l«/†æ6²# 	£*ø]²ºùĞìÉOÎ®ÿ-.HV©½E§ƒœ%=±ÅC¹ñİœ§`»”¶–X‡&‹¥Öè¿Wñë '<hÆI>ÿD©¢‰Ó0&àÑÁ£ÿÿèƒn¢	—î¦'p8x*Î:œ&À“…ˆšg~€òø¿Ûêvq½r™3ñ8½b4èĞF’,Œ\DJi$:!¾\ÚïÿaD«ë"<eëå]~Ûh‡ÿ˜_İï=Rª¹ü=¦9“°.Î5h„Ò±ŞƒİÜhwŸ©1WBdÿ5#pš-äòúíîøºı¿ùÍÓ<¿ƒE!xì•ºœ¨B¦moÇõUV¬ˆ¥ï€çv¤³MÁk­ãbÆ± Ò)­–‰6Áş„@åFÏB_—eÀGùf¿ˆ6ê© ßÇ6J÷Q(ñ†Ó§Yûø§R÷êúK©£é{Óp è7ÆÔ‡ğ9ÓëÂŸ²+oá
öù‰ü82«¯œ¿¼X&ÄßuC¢Å»`tfmŒ6·ic“²wbÿ\mÚ‘0Â˜`nğ¬KoDŒŸb"¬²Ò^¢ lÃ=¾ÈíN_ŸŸà<œ³xŸ%<25Àæ©Ïé|‰J´AñaEô<ŞŒOÚÂ±CÜ¾ ®@î\÷”FßnTù#Fº’THHSıë(æ-ù hÚ×6Ê‡ê$Ì‡l›—ô]·—ÿ ø£Ku:˜‡$Ív×k]·í˜:;ÈŠº¨í(‰³®ºB[CÙ;Te¼ü¶-‡ZlŠÊI0sø0Œ¾ZĞ§s?Ë:U[ •ªÀ¶½°)ÿ8sß£ü§ûH‘©Å½oÂßZ¼)6‡1d¾Û	ƒÕúó„1òk 5L·¤ŞìšßJÖ2#¸ åH¶{kS4êëX$cNÉ÷¹êö-rÎŸAãKãˆ*ó’6ë/KùÅ÷U)ïÓÆP‡*<%}òRmo3‡Í+˜ÅE¤‹wşçné‚½â{¡2tR‡í)•á*ÆVk‡,	P'êYŒ±®ª²ãÿ‰ó÷_Wıä«\"Şx'1
ÂÊ˜"%Xç¯ùö’_ntî®¡(÷'{‘=6A…[mfĞ!2Æ0›²pŠ,p-€ÄØnsîœĞiY$	ó¦ê6>»¢ù_=¨¤èEĞæE0d-W^\”ª\	N"_âÛóäËf,[Lğ~›DÄx¶GîÜåK‘åPŠá¦fF•‡}KÄİ‘C‘»¶qXk*œƒ’"–iÒEè%Ç½8’µ^"¤¬V½s­bÒ#(—L÷x… 7FÕÄu×m–crÁƒ¿ÖMB€®Ó|®†Ÿe³£ò—ºzÙUñSeŸl“£ââB—d¦'’'Ú¨£¢HÒ‡ö(~QzÇªãû’¥˜jc!ÿcK%ÁµzXg°·+…%eªÛC“¨zBS	Fák,Åp8ÈßÛ„4çĞ!/`=g©[Ïë™|}&áEš[|CšrE#Ÿ¤›¾%òÚÚçˆ Ã²PPÙr :)ìS-uó‡*w5¡M/÷¢éàYïEÇ ¯½æß.!ÿv…„·b–†	…cSkà­ûpœÖï£K¬é“ë'y3z+ƒ·¿–’êä'ÕqÚõ°Uöe»7¬†<ucâoğ+7hÛ(¤Æ$\iç¢—bÌ-¨ƒ÷
ˆ v;$l^!0ö½[ ÎØ
ñ¾¦BƒËÅ<WËôES‰óĞºŒµ‹ğøV“ìNVWäŞÜGbPŠ’³¦´Ò£lÇ*nc-†·QI*“µBádh£IÌ§Ë´7÷Ş9©ÓÒ^„‹åˆ’or,Xk´õ÷˜Ñ}yJı0ôn½¿¢Ø3¼¾˜ìWUŸB/ÃÍQªÜSŒÉ«!fVğA@ñ"ê¾Æ¶§#¥ßüZğAîc¦Ø†YI	Dı8]º
'[”§aëÄ§m?ª8kFô5üZJü	’&R;æ¡€ê:²Ú-,g9“]ÊjvÂ‚÷ÎK?_G_åëä]²À\Ê•J/wPV›¶¤âí§Q.ZùÈëH5¦1Êşsºn-p{¥½êİ6xæß¾æ£êñw÷¢ÈœÓÛø •–±r}¬üG	è±„_$d	[‹"úñĞ/3úñ—À­L	­½pùŸ²Ü7Å³h”$"F6=Œß[QYe²ÕÔ©xã{mJh*$èyéitçvHì¬ø
8Vˆ„ŸïY£¹|}&Q¼t©‡§ŠpÖs9)³…‰/®4Œy;Ãog¯^kÚtpÈ0ú‘=Éüİ#‹ÊVûq“`/	'î>]|Â:•½ÒT:§:û9M±™¹§ŸËÍŒ­ØæÏb1ßPø-rI>-¼gÜ&w8a˜-3e$¿[ˆÔ+N^7T(¡~¹‹»X»,J{WÀüër{U¸à*µN¦üå4ØLÇ&KpˆmlV•ëY7ßÀ-ŒãCï#,rÑè>ß¦¥Üÿ9•ÌµK*SyÒqœ¡àFpPÕ>…r=¼éîŒ|N€FÆµ–¼ıñcqÇ'òE©Ó¬¸c6=Ô/–/ÏÆDótÔ{˜_lñã•óuğ1uñ]•ˆçì®ØÌvãx<ÄÄ	sv[÷ö¸Qç]Ø¡ÄÛÇìˆ?¶}ôÓœ%õXÅRoBQ›^˜„¶À±¡Q¸Ÿ+&‰ò9ì~ÖPêx@eÁôÄ$JEuåÄ’ç&&*31mÅ÷!áë*o4ù ¼aQ¸4RY½ëŞoMåºÄJ½ALN§Ş_š·‚~¦d
|ƒír&´³¿ÜT0o-hmŒxTÃ`Uk"GÚªé÷Ş‹¢Lò<t<JSÒààs±©·ğ}
J•F¾VNò8Œò×ˆzöÒĞÊıV«^R\¼ÖÖ]kA<»RÅÔñ`õù–zPÓ³BÕ¯p!åùtµfƒSiC&J“OvO­4?›‚/f*Ëv‚U½s%¥„€åÜCÜdº@·p&.ÙÑÿ»RÉÇû7 Ô§öİÔ5eaFö=Úu×ŠfÂğ­¥²	VD¾Wğè™œÈ6Yàæ\mÅzô“ éC¥ñÆˆ£Èñ(™êÔ]…m6­[KY‹ÕC‹èÖ,¯v÷HVBåË/VFF‚€»ˆRÍ-ØÂO¢(ƒT9Õˆó²#zËşÙ{—¤~«­¤o0#L7¾ÃUÔDÜN¡…j4B«=	&øÅtºÔYàjwÑØXÆ9•†`Õ”ª{ß cãi——;zË:¸¶x?‰äÓØÇGC2Œ{v£tvzK\óİÊRt4ş±‡ôÀæ£2T‡v¨¶väÊ$w~‰ú
º¸SuêÎâtu”wm­Ùl°ëfB¼yXäq©J,XiIêW“ œ/¥~üò-?}ƒÊ;g,4š	¹cCKGè°ÁH¨ÀëÕèÛÑWp Ù”o™‡à­ĞòƒOtX%ÇvÇ_Á@ZQònù} ‡Î9Çl4ğõy›L‡º¼<H#Q…bÚ2²_PˆZô¶‰4›ÒM&°Æòÿu‘¬	Kq;İ	Œ5	 ñË¤è„
¤ß ÿÎêÆü†è¬3ÖxßòõğÈŸ{­ÌR³†WÒË)QÚ•®²+3¯ò¥İ®İ#ëÕƒ‰»n’7äq•5¹Äıº&ê™Lº¤I´7ŞëTsœwçôóë,„mÎ,y~Ë\Ob ÁÖya\çÅ>™Õèq§^T]v•ÆÙ–0Â–wºŒ¿ÜjS#İËü
÷—ÃÒ=là¼í\ÁDsÚ£\Ş±Ã#cQhœø©«=6xÜñDı°ë!|†”Rä¶©zõàG-yiJ‹2U`Şâ€¤á–«@$÷míERĞ¡å%vU°ÄCŸríÍT„;acïQ}ÏLø‹Ç
ìq g"#^hA1ÛZˆ¶â8S{²´exyø0‚¿S¾Òñîcn8â“Që¯+•ôPt»ivŞ–5$øº"x§èƒÅ\ˆÅÔ'‹æ‰ğef¢åğqzeÖ³xhB±Å„Ã²élö<uí0ç´çbÎ…C0ï„ÿÃq¨©Z³¤t—İ/q§ª"0&x–Ùœş³äı²LéMÓ\äéú‹,ŸßÂõ|±P( İ;DV¾˜?T3ş)÷`.r1òF|}ƒÔY¬dÁYY/¿«Ùş€ƒ sãõPÚè»åó¢A¾)ş2‚gaÉ#Ï2ª×¿š|¡Ú7‘øªIœ?º^©]Ë,7#!–
'JFèn–Ø×ìš›à‹æk·ÅQğ6pÕçÌ•I<À¤¦ÊS
ôÓ†.£^„Ê-¨VÄQ¦ŒíÕšSm…k^GlÀZ×»ë(JœS½Y=Ì+Wy¼^î¢«„tágk`AõwLìôLÒ³×O2:@¸¿ø(!·#µıèòŞ¯û·Ù¨M¥Ü½f"´f6|z/¶°‹ª ‚]íî#šØá“¼!ßPöõ" `ÜläOHò%Fp\aŠÿ« œµ_«9ê¸ÎÄ†Ìº½M	œ¬·Î”¤v¢¢n^Í0(‘ö¯Â&5¹òp¡¢|by ¿Š_Õrsb¼ìp¼T X¥åb>oªèr9£ô¨2£'Sy3ü‘\8­[…Ÿ±¦ û¸e®N¦å®uw,zFª:şÿ·KYÑ7´’$ÏJ—ª’DûìU*Î®†¤Ò9ÅÖ;Û£¹Ü\iJEÍ\õ€ê¾.õôïD’(\¸—A§DW˜´‚êk“º+Í¶0
êHfêIóveşQĞéŒ‹Ã<SàŒ+[×ñÏã©d]³£ËÄ†L
6…¾°3¬´ğoŞ4ÉJƒ0##Xhµ™Kß£A‘”äÀô$G¢¬[	®«Já–[õ–^à("»_oi<g/…§ÄĞ–Œ`G‚Yå1dÊ¾¥ĞÕr>õ•µ3ş1VŞüöû ¡ÍUå¨úí‘He3‚×:(Q&ğ\Ïœã€Œ×pé÷Š¬òq²gI¤±â€6uL«ñÚú­QúéLˆ8™‹ñ“êàâY İ‚¯B¾ÛVÚxL½»)¤`ÃÛÔİY²]w¯ aGøëI¾Bê?ˆ%j2åÛxj†ÊØNü·}½ƒĞ!´‘
7™™7L¨ÑÕ+ƒ6í«'1x<À§ÅV7ª?Û“Òõ–Qã*¬³wlİ%ŸVölôRl/c·ÇCWÏVÑÀ'ª§®ñ>%¾&ÛR(Ù)øÿÉåÊÍ 3œ'&‘–ıjĞÉ
Y”mr>Zo0×uOÇb€ŠØûRMTV;à¾—C{æ~İ	Úÿy«bÚ ¤!¤s¥Âh®Ô WgûYí±ëõŒÃ óU[ÿ]]}DnH=RÒ):¦@¤ÂÛÎqU«qÉÌ*m1AuíQƒ`Õ+MdÇº2Å`8h«É4Úã¢î¿ÄÎøTqÎÄ ÇÎR}Jc=>¡±ğ´4 Ëö™’AgÜ:/âbÍ1$Ñ“CÇÛ]ôµoıÒÖ!Ø™1Ÿ¸SÕ·Ö O·4~Iéç£ â`Ñvâ§ò€ŞR˜CƒmXäàÛ`G¡'gXuëb(ù^J±ˆ¸™ı±‚5vM¸;äÑ\ÆA¼¯¨«ÔZ·FÑ`Ú†,µ%Ğºß/|l©0ŠvÜ#Ï¶÷,ÿÿS§on5Xhaši–%ñX¥ÛSıuøH§\à„©äûá™®æ+d,wDm.­úœß.¡ÅN#½¾ÄD`Ïk:Î›aâ` µ€¬¶RÒbİ¦pùcÉ4ßeN…R5•¢”hV–œº*dQK÷“PŞDªz#nIÌAI3OÔF4ÿ’ÜI¥º|Ôg\hÃ,u#dywŒM'G GñxÛOLş2 1Üêª]àV^›á¾-J'1 Ç@©ÅÅÓ|ØØIáD*dVH¾F“Îûäù<¬(0-ŒMİö`BRœêàŸ‹wGc·}<Jƒ;FıêWÅXS?…kA>e–vkÑaKGë‘ÈF—„TµüwRçF9B«‚gª(œ…eõÿŒ	7Nº¡…ÊP»äp…ïÇ¡*”:ù­brA<W‰ëXæ9Û^ƒUÅñF09½TVËò]ÿôvÛ×¤o­ç"F)¹ø¸JÁË„x7mrù(¶EÒf%Í÷ÆíRŒ}ôèíÚbO_GN_¼Š15ÿÔÜ"Ú)šRGÿàPAj£¯®}1Úä²ÇY®ÿëßÆãõ‚j 6÷H‘o/è¿¿‹èÂ219„—Ù";óÌº2‘‚ÑÙ0¡8~l¼0†[ò4:|Ê<#ÓÆ9íìñœÇ¶µŞ¢ÄuajtóZ­P™ÆzŸğ­aÊò—lØ†V˜ÜRéÃ~Ê| ø²*ûä>%¬l[d¡š™re" ˜8#*Ï_ üëMÄL‚„Í4²ö2ªHüÿóO5W´iê1*ô«;v­ÿ1~Zcñl4¥ÖuÚŸ4•¾i"£bGœy+=‡Øï‹ã«‰Ù5O {Ğ÷1mûÎw‡7"}ƒĞóªÔp e'H5hò)(
îUåü¯ÿA¤È?,C_ÀQ­ÿÎÍ½•?á*M6È5múä= ñ¬t+Ö¹ÏFàécPWWEû!—o3ôXk¶&¤4ŒZ­ë³O2Áâ!c‰çï†­sÑî½BXì[·=G]! Z9¨ñEÕ«İ.5Êƒ(ÿßË8ß'L
=3~­•x¹ùLïfÅæRí¾˜[#£’…ÔáÏª{h<·´µ¹+8ƒëu4®IÁ–Ö•ğˆooÜç?³J!Oø•PÂnt(¨Äh3rÅÄ1¼~ÚFƒ's'Åÿ˜`ZË$&tqWZuS)Èî­y—}¸
. W=ÇƒÏY ¯[—¥/B¥Êwˆ½?ÏkŠÊöĞÁ¿±·0x+çß…hØxm±°'Çç³;QŠ®¯Ş|RŞ~¾kµğ«Î‰óQ3ç/ÎHf5+{k>º#5çœà2af3:Û©É ØÏ¡\İŸ)6gQşMÚ‘£ê°W“Ö=zU{+\n*:Zs×¥¨Ìg—h»1s
<Z¿pµÖÚ šìÜº”¹›pHUpmbM~’ğ!ÌİúÖN3Äu½‚,«·åÓ^é[Õ¼3ÄBŠo+.°2ê8ÀS°Íí–³Y£<9u ;Z'qÀ+½ç¨qãWS>ÏÂaTŠÍ^±E4—+ÚvDÄ¹E¬u#‹«aá bo¸=…Ô"Ü'ùÆ=Œÿy¦ÓuL;Ò‡[Ø÷›TŠ{×Šö_ƒâ€9‰Œµ©ıà”MPè«ƒQK“ª=k¶õmûKªr&Õ…Öe”Â/é ºxƒS#V±n¿{¢¤nïúş¿7ğMù{cC#}Ú€ÒY´A¬,
“i+½5S	±R#~OÎD|ÜìeCôî‡˜;Å eØŞìV}´·GÅuœ]÷«­r‹Ä’|²÷â_ÒÌóÏ•—¨ÒÍD 3İ#;ŞSÒ·&Ï&ƒÊĞb`$l2±j¤€XIKiµx¥ÌÀw…`·Èå'L²“O;fÒÏV0¨gHW5üM°ŞêÒ çîd¦€A¬ª.æqÿî‘À/§ùb:«İ0£1R2±²Pg°‡–f×¢}XÉ[›NmÙ`ÁOöÃìKh¦¬¿ ×páoÆ" ·í2Úûôa­¬‘crâçP×2¢½›„}Àô54Áû3«ùÅdŸÀœ/%¹ì6Ùí'hòPf¤Ct—ò]+pç·&u¬pÀ¿û‡ö"€rœ‘çSŸ»’‘ıÅhå!mãèGüã$sj®Ş¨\Öûísd&‰ÓÛİ<c†I2·ÍÚç4,öåføä|- ÇôXjü²*‰KwVY¯a†gÌ¥kHI*^EÈ]rC ğn1ÎEdÊŸıç]—E1ùåÅó"79ã×™ˆmyèí¢mÒA^°¢£ÜÊDéÀÙ¯'!”;J@…™¾:Ê¤iÇ†·D”¥ıPŸç‰
jWKèEÛİĞAHøÜÂÃ÷PU¬]ğ“‰¹ßMZ[ıb"˜Ìyù¶eúğ‘’s$äáûôûC“ÃÑ>dÊ¯&?¡ÔşŒËú¢>Ú›²êş	k€ñEEÿeˆ—M|şßØPóL±ºBŞëÚDK€¿µy{Ş(îÍ¾M•“\ä‹Uí ÷—†w,¥ç9â6œckÈèÎ¢`"ÖLæŒ>œ¥¨Ø#Eì¹SõêIPô'ìÙ=‘‰‹·®ÚT»*Æ‹x#ïÚş\”øQ„©wD¸"öÑ˜½Mµcy	£˜ÎK-ÎJ1¦,7ãï›=Z¥±Î?«¸•lªhP™Í«xl¯ Ò<Å\tŞP¢P?k÷ç*•‡»¨Ïûƒ–Áİ¥±İjCÛWêfË1Ò0mhğSš[¬ÀooXeq“¢Í^ajÏ%9­a{^İ0;~nfÒıLaPÃÊ¸šŸ”XP^ ~Şn1µ”ÂÓC zîk¯%ó¡&êë6Õ¼ºø´HqâXë&¤aÖmÍ=¯Õ¦ÿ¤Ûè£#í÷Ã«É^E®«Pb"­†Cí°iƒé›ŠdL Û@WLÍb}Äé¿­´ÖÆ‰¬*İÊ6ÒL™ãb6ûcæÿÏC^ˆê‰†ekr ½rk¬„—†	†Ôî­‰?Ÿè $NYÃEÜš?å3àòk«ĞŞüxåæÂù\`ki!6#”qûh¹6ª)Î(G?“s•NFHË*™LÀÈ
½õó+ Ï6"‹©ëøYB3&Ú$4ôû-Ÿe¾`u¥±“˜¨÷üa@D Ÿ”I×|.8Ñ2µõŒUw$;†ÙXÍ¡…j)Ñİ4¹
bø"İ2ÅÎ‘HoËÿ˜¹¢>4¼jáiõƒà»h‚£§Ò?"š²td8ïUš¿ªr`Õg¦Ô kR{àÒ~@Ü+òï2AWŠŒ|‰iq«aˆjØåğºE2Â>~¦?n8ª¦İØ!9±´¾zeü1c~$hÄé9ô¹…ŸìØ¦R—xCÉC¨XËÍ¸ØUü¼ÑgXPó+°)ÖŞrÿPQÜN;ìŸ4½YÿÙi˜±«[t397xdá¬YÂ£ì³YÎ‹¤èW‹ˆ|Ş·3®„îÙEê­Ğ„bnKvõ789wW%ƒÙ;s	|‚nSú†ÎÖ"ïJúæ!Ñ¿éÇµïg¤•7Ö³3ÓšåqştîÖ„gàÓ})»æaÀº`Üi+HDqM„s<úé–˜n:%ÌãÆ½ÍÏÆ 8˜î>óÖ8ÅwösÉbÀúÜ²Şõ€²åˆş;¬Ò8ã¤O3èùW’>
µ_`17­MvÔ@ƒ°;V ’«Á½&YêÙÓÖ*”ÌõŞ1l³¦ 
Lu—N‚¥¬v{)Õ˜:t\Çùì)’KÉ¸îékÒ4ÛşP>^ô1ÕÇô]
ñÌï>Àl(à{¢Ÿ-Œzx¹„Ê1ëbœYŠ¿’ ÜøN¶è…ç'=bzeiMbáá2 8Ã-Yä.Aª q±åZĞZ›çU$·^g~‹"èM{Ä|•?$4ÎËÀâ!½¥QpÚ‘«Ñõ/4PlÙ çCQ›
	¾ƒ9¥íp)Y¢ëkl-ÎIŸ2#›X’ĞÁ…7>„`¾Óg-zìÃÃXXt	ôNµ¨•S…ª›%q™Q/‹ ¼ß½ø–îÃ‘‰*}Ü¢fe‰«Oíú‹õ°U¥"wkk­™>4I ÷÷‚š}ıg£]Ç:…sjŠ[ƒAõÀÄÇúSWÆ›²xoÏ|‘>HKº«úzÍf.kŠ ‘}ä±·Á·/;ßç3ù	¦G50S£Ò'ÒUEÄcX`Ãn…š„û`–›’ ˆNÿÏntÎš?ƒh	{~1òÒû$„ã—œÆë°”²¤dWĞTcL
—øwzH±!×è2‰Œ;š«’»`½Ûvã”,°Ll˜Ù¨‹¾*¸Å<®…6n=©½š]×G§>fÊ¸…‰•Ÿ>ü¶~Zçš'H5>İ¦÷&ÙlŸúM­¶	\~}"šŞ˜¶B.¬O¾ñíJ—
é"/lv¯*ÁVkl‡“G%ZøN§Ğ)³Š¸zéåH’ÂÃ1Mß”çiš×œuÂÖ¹S¶ÒñHBRs îJ£rWH3#‚š…ÜfñÂèÈˆoûkè`Sñ;ÜvÚó¬÷,’ÁGĞ*âÍª#ï„QÑïŠA]
öô>~ò¼Ø¢ï©ˆ[ˆ'^Ú“'(ı\ıô{â¤Š—.(“ã¡r>2ÛŒÕxçÃ:İ²æg¢ùx;3ğ!Ìùƒÿ pª/o‰àD¼A¨BÈò‚ömJı1Ş±ğz„4"¬Fèr§>HF`újÄJ*R€Öÿğ­º¦<¾]ôÆ­HyìtcåPÃbMYû÷T6}3 ¹æp'I‘O¼ÉÌXJSŞdnÚïPNÙ×ç'èA£«š>ş¥ŒF–{Ã„¯Ö…:^7ˆèD$hk,Ü|&<œ`-ëñAû7™Ûnùß±Uëï8=’…Á2àgh§3ÎâÓ/”ÜÁºp×‹gfj#Ì†ìíqJùpÛœÀ¸O­.ŸºcV¨•¿-|	ßE+KÅFLØL#"ØHR,åY´U!v¤B“wn'ÏBİNf#9Æ®kW‘®ØD.¤éN±¶?ps5o0m ÇÔÑŠQ«²ótùÊô@ÄfÔ›K>9ş“ö•ODŠÀ¨ŒJyÀñìPB–"¥¬«ÈµÇœ*dª>Ol]ëvè©0Ôá–O2”Äõº5ˆDè–SRß’¾k²6GØ©L8¶I¨	íO3,²’ŒÈ/€¶áOp42?VÙÊ4ğÜÕ´DZq²ßËJı4ıPƒM¬M2‡y¥-€ªëÓ‘•‹ëŸ’ãNöòq,ÜƒLà~èY«eLış"úÅÜâQfĞÁÛMÛaO0Ó®Féğ´•ÅÄµ¾¯Ë]t IÙzZ ~<§üô"â×Ù¥è^}[zcIÈª‹µÔêb	İ#<˜ÿÑ‡ ÀìCw
SYÓPğrƒÕÊ,z™8[Ëëd‡K®Ï7¤©ZREìŒ·j:p¤èNG[¼©ÔÄ.®‘ÓzÀ›Û‘
xÏn	{—Ã«œæ»­·±©×@ ÚyWëÔÏjåAœ…Œ@ÄŒ|Ğpëé°>úORz7UŞÁ¦áUÆA°,#°½àn<ØéÖ©Ãï[=Ø¡kn‰ÙÓÈ‡Äš²Íª¿W­k’ÀÊƒ>L0•¤ÿW.Fû´hP¨KLğıíé„TÚn&b@üõt6””’ùŞ:ØèP«†³‹µĞrÃ”é‹œÅ‹Ê¢Á5íZ’)Å}ç3ŒoosUïémÁ6]wbâ¬	…”pİŠï¼eÒx<Ä{e–ÄxShYh’ØŠB;§8Å.8ÉÂÛŒnS"æÓáğŠèè&.ÂY©‡c;˜ÖÎw“Ñ‚‚œš¹Pu‘ô¬aº¬ƒÓ»\EºaRnHˆî3ô&LJ;jéÑØ4|W•J`JYlõh!vï÷mçs9Æh‰ål,ZRâÖéğR*ğËAegÆôË 9­_÷è‰¢UèÕÕ‹Ïˆ&…º­ %¦¥T²k†&M$nù&#	¡"èS””Q­ia¾Ì§L1¨²b¯H¬×ıåGy¯~ aD¶§ÖYü{N&\4õ’uÜ=Óê%Ù³ìzv#¿á:ÉgÊê¨º©šo›Í¢4=º÷|dÖr¾jC`¥âväôª¸Š§[_V²ˆú6%Ä#ñ³ LrS¡ÓW0åíš	B>À¢D¶ú-D<EÃbÀÜĞ@/œ`¾ëYîç{Á(„ĞZ¦^À®Ê¶¶:3y€vÀŒĞ“¿¶A#i.³Ì…VÙ	k<ËAÄêqú&EŸ‰/ä£ ŞqÖğ+BuÖÇ¯Ò±¨hŞÌäŠ~'`GÈ_Ëì­iö¯A|¿†'Rh÷P«’^Pc¥”`@,÷R¬ŸYí•¢¿OCŞS;ı!sÏ€¬$%(®™åãã{ÉÄeè/äû¬lSÇYÑßL½îµ°BDAa<‘Ôİ-Ûœú¾ùáÁ©u¸FFËÙkÕçñîˆÁğŸbãÈâÄŸv|Jô/#ÈlŒ_4M@â_W87s êv½P©áüJWí&Æ¬&¿tñÆœ[ã8ï@¹øDsõŒËöÑâ^Šl*CÇc])À1aœdOb·®æ…]ã_Wd°r@„f£WÅ0®q+Ç¦õïŸÛ5ü–wPœ$sH¸#Ùóü?I‡$—B«=	?õgX‰ õËÖŒŸc?6*5İ+ìÅ³ú€€å”’ê¾ğ:9uRãÌ[]SoÙÖ2]:ƒKÊ¾È|¤O%ç.d#w¢p¤ŠæI—&®ZÍIv’i×Ê€¤e8Lk¢DPª{ŞOÁWú_’„vZÇŞà   y	Ú!œ&+6 ê¶€À…/ç±Ägû    YZ