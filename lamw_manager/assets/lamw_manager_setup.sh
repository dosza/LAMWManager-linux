#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="666062496"
MD5="b5801e8f5efff0c8e53ccc962b25ffa2"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22584"
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
	echo Date of packaging: Sun Jul 18 01:32:47 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿWö] ¼}•À1Dd]‡Á›PætİFĞ¯RQÖ÷‹yÓ‘œĞ6(Ÿ¯aÅE•*bŸ]<ò9*‰6Bá—ïš%q>Ås”ff½ã“FüE:P¡â5Í5lHñêšQ²,ƒĞŞö "ã{®±!%ÛgHèr,Şp_
öôÒË³âcŠ¿I­õ—±NßË’ıÇ#‹Xµİ&ó²Uáõ{|rgsR˜ãù0wÅEüÉİ8‰z^ãØ\)!9@|¨*ò¤®?`ŸmÎT
N‡9a’G;L™.híÍ í¿[†j’¹KÙ¯ùÚ3Ÿ¦{¨Ì=E2„û‘T8w…CÉÖ†óº~º‡O‰üğdj¯.ù;=Â×Ia2	bİÂ›hÛzOòÒ9[¬H:ÂOs‚w$ë­óØó|Şpª•6Q_$ĞóÉ¿p8‚ˆA-Ú,Œµâ©Z:¥òËú#*7cõ¾«e"îåËõÅñ»îlÀb0A\ÀÈà¨^Ú‹ş|KùÓÑƒm%/°RUf!÷0QğÉ$nxiKeœø™‹):(®ÌÆW»Oca„„³Tº»Jjlõ¹µÿ("óQ!TI,©k å¹ƒ5 ÈlnoS—‘.ª!ñİşSò8Nu1©·ÀvÄ„{4µš—Éòã+—vÄ“èl/ˆVNÛ±«à ÃÙ[ŞÈåDí…îÂªÍ}öÖãß‘ –	/ş-‹ˆ”äj-~GOpXîVÑG}ÒSÊa4™ñ@â˜˜|$Øå[jñh-#«ÁÕ6éec°Z«P[¢Ä©Ó—ÚÄL9	öœî£<í	s@İ‡Å? 4õnVÁmRÒ¡Ÿ%Û©â¿ú0¬”Øğ–Õ.–|f~ƒRMYÈ³3, 0Á4f¨:ÿø+ÎĞV¦ÛÑÙÂ=Ùå¶‹ŞÍ‰Á[
x#³sG|öƒ.+¥… î?áåHòt¯ó¡İDÒÀbwÀŠ<vÊ7‹’m]\µ?9g0¶™ãÑ{7ÑÕ}†Í*şK…ZZ'Ëm¶H·'‡¸Ñ·.í‚Õj¥wŞ¬ı-4j¾¬ó$ˆù,2P=°Ú¤>‹şıò-4=\îš GjÌ²1)Ë½@Ï©m6@ZW«ˆ¼¸Ê—µ…Ñş©}Ó(À ŸW,ê>sÅv¯×7ÖXŞt³õ¤èˆÁK(/¥Á¤
{áƒz…b\¸°cn	v‹Ñè–Ïƒ®¾èª.ÊÑP²%å˜±¿æõT^Eª0÷î}H²ut¢HÈ´yà±§³¶ÌrDˆPîÃÙ^Ö{Õ5ÛùLÌáô¼Äœô7´š’]¸!'»ç­iÖT¸·/		B\ù4àzWŸÛ%e©oğŒõy”U ú›éÈŠ¨Ïb‡*¢ªõ>¼B¹;Ö¢`Hƒãıô§LaJßÜ{`rPIÉ	‡
CvÏÈ ‰ÑN÷¦)ˆó	sßá@Ì.§³$âÍ×c¢£GæÍB_BuõO“`¨X*i¼¼˜P|ıE ¦0¯º ÍÑòZÚ0I•‰±ÄnÃYr8FK–Îë¥EøûB[,ÜB¸|—/*$K3Bá»=Æ9H„6³1Lb„†¥­&(9d,b•5IÛ”_ÊÛ«w•M­ÛkHqBÂÁx$Wñà›’¦~ãÕihæDãí’:%ÓÃK|¸H…=mdTºÓ×ÒyJæ…1JP;71ò (múùÙí÷£Öi‡ …Ú¥Ò±)Â8áş¼ïR^M…+„A]g#+UæÓHœkÎàÕ‚ü§ ËD)Ä0Å”9>S-´>İ%5PİÊÅ?)¥ó(ª@ÑWâÎuñ¼d<O€6EëõÕ¡s¹Mtz×´OKÄT+ïĞ—H¹LZ}’åƒ}.zÎ$QĞİüt÷½Ò‚Y{¦~´®ŞncKxû¡Bl¯Ê\t¾ø“lÃùĞYî„ü~OíÉµş”ûëTzƒ±[ûßµÇÔ3H3ì/ù¥s%jZÊååÉ¦Ü7¬X%ba€›ÛRYØT‰ì›}”Ã„w81’/¯«çqìê{79&=®_'1#İmoèßZ›ëîÿ’ÅöĞmÛ„1»©Ö›¼yıtlDñÆUkŒGÛ…ˆ«…¤Í-O	ôtÁQëÇbß%ª›êUg¬“äE¤˜hØŠ&øôìOh:¿·Í1dD½Îg]†T·òd»šfSM·“vÇ¤érØ| ¥UeJ~cêµ-áT¦pb„<’?
«Vi±MØOÕ„oŞ9Ì£‹üı§°ªsZçã­Ã»ÍÙ¨ŸÄ”¦Ne×Üó×*r²ÿü6£óRc¹:…1W€eüpJ^ÿãÆH—°i*ÓMÈà¡u¡Ğ¼(2…ÿzÓ]tÏŠÆÕ·	¿ZçõWoá¹ÀdJ]÷£¹ÅwŠŸg‘wjœ›LüQ²Ã¨DÀğùOW¤Â"ıW$­Fy0fB$ÕÛ†÷wô$’CzñnßqYæ-É'5­¸@„ë)ö{ıGŠáçÃo´v”sMh˜™Gå;ÙÈö2.^Û´¹[[ Ñé•HËƒá=×$=Ÿ[é³Ç†ç¬[MœèV$Xè2[¡’ù¡´UÏèx
şşèÁ·æë‰¡¦æ!ìs¹j Å“‚ ™ùÖ¾#{$7¤§«ütÁwUy]Ï:õ»Ñ5eÙ¥#  PÙ\±@FÑÔ<Ó,=ú]‘5¤1y–ìP.h…ĞJåÌI«0 ?.rp`í?XAÌ JfúóWbk~—ùa5¾=ÖºczõÏözoõµ…-ôØR¹Ó4#¶V†mIfKÏ°pÜ£Âj™íÏSR[¢àç@*{,’“‘½şêc¯e«¢©~±¦†©,eÆ0ï†»²Šë\€Fq1«Ø,:øxTu%„Aî´©“vm?“7yA öRÒE±FDØéÂ/)`ÔHhf†ÔmÒ/2k_5ã¿¤ûHŠlÕad÷Í´ØoÇ¥×İyÆ‰{‹°ã†AE‰¤B aËßíš:ôzQôTEêZ[ÑsWùÆ:-ü¦¾¡lfÃX'U´¸XÓÑ¤×n»ß•ˆ‹yÛ»–^ V>ıC€Z‘éãâÍ…‡x?	ü÷c£Sî	j¾èº^!,ÑzÓtQa=k=×2!¦fqZÅÃõ$i:ììú1˜¡òr%îmãnmÎC»`9¥TÎ:n@×Ç§1£§‘.’åQÒî ]³NH¬„”V”°Óc 4ª:3ÖhANãy+ À2kûØ÷<Éõ­›ú‰™dŞÄw©Ad£İ&8`ããa%­È9ƒ_®?KŒ´Ÿ]W,{y¸Ã0ùdR¨9–ÔUŒŸ·œ^„Ë€‘áz×c"I›Zûòèµñ9ÛøjôÙÄTqLzêkÇ»ZñÅFK² `Bq„¬Œ*?>Ú¶«š†$ @Œ£såğK±¹…vµ—òör–ä‰jÒ/TDÉC$¼ÛWïÔD­¾GsDi"ï’àòo9ÀÓ(o=…ÚşÔ{*‡U¡3İ.	ü$æã¡k†3¤!ÛÙ:!¨
Î¶g„‰ªJş2ÜCŒa‡ huu·°Å†7ÎBNû~©?Ç*‚æ.âº89 ûìÑ­*¶¼:x‚ğÛÚU·µEpï´j)wÇõÎ‡xôZ”ï^ŞÑÑIuõÀq“„Ãl ¡@p‚¤;{XÓRï|5 0"&‹¯%Eù0Sôtyï•ˆ&õÜ‹ø‹jŸGkgKû¤øÙ[x®ûu©æ%Ò	£e­ôÒ›*¤îìîî«Y~/³ÏL˜TRÊ‰¦aú.—:èT~'øo™/+4MFªE÷MÉâªZó,ÄçPÔ [¡r¬Ìö£#‹ ÄhÊ%m5W™ªu	ÌŠÆ±úumUÌß]?í‰©é· fòÍıCa‹—?ÌN²÷ªCïğØŒ«Ó½fşnUc >İC‚Â™¬êªzÑV€˜ªöŒWè¦Š1SŠ24/‰ôş¤QÍUPxPõ]Ğhœ@Ñ`æKÍæÓì }IDbÜ?ÊírëH9¶CD'CHsí©vÑˆé†Õ£ø2ıÑ˜¶áíNRdòÇLe¿k·'ìé_&
WapèÎû#W:I–Ä|ÎûL…b¹(pæÆmJ2cõ™E~¤D½›E[fÓ<­FÆ—xƒ—~w_eUIùfm¡å\76Œ¤-H«£¿á„Ú¨´µJ•â*@¼<‰.^ø-„à‘¥[®ø«2Y§Å­+x:¹¯{/~.ğ)ùíİ¹‰Æ2?RË[DY@ß½õc{¡ÁÎççâ‚ô‚ÚX˜ YÕà1xêšĞ¤qPÕOAp^|”Î,~»•`£<.= ³øw†–/£pµ•ü½—~ôë¿YŒ®ù­òĞ#!Å‡túÕ^kÆhxÎkLùs±Â0ëwå ñXõŞ,æ˜XÅ¼¦ÂÜì§?9–éŒ'!auf¼V#{F•òXa©=òıòÉÖ¨
¢ìöšöaHGñœıÏ2Whš•	|êîÎ×ó^0µŒ’ÒŞB~#0ªÓdÛ€Ú™xµ¥>äÁM¶ÜöéÈªÜ­ØuŸ¼Ÿ7(ä6j˜lú!ËÙ`cÍÒõ°5•å=K.8©çtûV\‰İnÒÎ8JM>oËl`XM>Ğ>lo…QMê*P¥ÈÓ…)+ØşZqVH	À_E9¦?d±•ç0¡FØ¨x€Á¯ÇÚ¬‡ş£:Pw™ØÎ#-Q„ ³0¶ßSB§áÌc‹CÕ/Jû¿:˜Å€)Ô?ÛÙH&°9†!§|p¦™î7ó~"ö‹/’\,(JFV0KWúv«-üÁg¸ê>r&!- ¢Fôƒ3dÁŞØÄ¬%F&E3YE"ã*¨K±aïMÁj=@UåÚ*c3Ş{pûq3-D¯şKÃ*öÍ˜¢i*ÜX	¸¹wºãÔ±\hMn_ÎÓr§~ÿk·F4Z`„½ºjÂ¡›+ñÙ<„vÅ ŠY,dG·«/½Zò*R EG‚ÿ¥£R<ˆ(UšnLÄ#™	t]¡”MŸ6J½Ó¿ña¡ Ÿ'7Ş‚¼H*Õ¨[&ñÌã<kiİ3©J“¡„¾f¦÷ÿ’Ÿ­åê;ÄLÈ#ÂÕwHus>¨j~Jp(J±WZgÂÏIÈˆéÆU1ı#ûÔ~pJ¨‘ûdPH§×ã±Eb¼EşÍµX¢®²ÑhrÂTAÖSÙĞ;B<áò[sô š %kÚêM|·ä(Ün±dş€“„÷î¿Lœm—y‡x>eÔ9‚†¥f¾“0ƒİ¥2 _zó]½Øêy§9ÜEqT»ÁŸX¨±Ã÷Æç:ÖM…ôœàÿíWÜFµJ0ºB_É, íÍf('×=>¿¯9ß!/;÷KŠ4Ë'§îİ¨`êşLçâMT¿]IgÁI\Â«O7”†	pTà§~K#Âù
–ƒn¡?=³NX‘5à'ÎÂåØ	±
š6;†åÀåğ£]PŸr(é¨$“ZÆ(U«WêFÚàrô´„@öŒN$Ğ$ƒ'ÌG©¯m*`ôùó¼ÆÉÁ±g_uª*.Üı)ç’¾åzWüM–‚„3rfÛû¨ıÌ~e²Ğ‚Ùø$<ÒÁÕ*Ìíñm ‘r‚Î;M?K¼®R›f¥¾›2°®ÓÑ#ßûø›ÍíLô]ÒBñÄw†¿£¹tÜµ”[ÒnM8!«.U"Ë´ÎÅÆÒº{ »­õx¯œlO6†kd6…$96”peQ¿ì%à=z½	Ãó;tÇp¥ßô/E«UâÎåá/Ù¥7â ÷0Vl•]cB†i•ªŸ
”*Í4‡^s_Tj§µ*) Â>õENµÙúH:ïÑÁöƒ«€8vZc˜boï2ø6• çÑ/¢Ş¬O3æõõ2šÅi(ö"º6PqQ¶wœÈGµK'&~wÿc¥Ô Rße½Bİ§Igh;øUû)òã'ÉÀ¨åÿw4¹;Åëû-Z&ÄÔ9=9Rî&uûvƒÓÆ‰úøÂ"rûé¹< |kñmé@cÙÏ¶këzÆbAÆ*DÀêÌdµ&é_üÃğÇ)“Ïz™?«,„[FÃ*5y›aùšAÇ$m°˜¸[ÌwX1²{­ŒãFÊy
1túM+^Kò>›K·CdWv©øÀ)Ìßÿ [~´%[²ûÌE±u”cjØòáx¯8ş§#‹ën†Ûê¢L› Có^û}x¿´âú–ów’ÔÍÜ§8ª%AÅºÀÓ¼ÏàİËà¢Ãxq¤3gD;¥ïVÏXŞİÜğÿ_z Fy$H|ÚH7(u©<Æ¤µ6ß‰OA+Ë°Á×ólöc‚s²Ê B”e’Îªi¦Î;â4÷ŸE¹›n©6'÷êi¡?†/‰é:v—²İ6°†'c­¶ÍäwH6uìˆ­Vòö(HÜ&i§÷	 ?Ó³”;¹ØhŸ=‰D«Ü_OHUt°¥*’X‚ÙÇ¤³mWİ…[Ô!,õMwÓrÔ›íVÃ)•€KÂ‡¡ìí2Ò3)RD~‰²1hÀ„Şk©>ù÷ÖÆ%K­Æ¸y×Á&0_EF ‘9qÑ}q‰³1¸Šó›³Pº]±5·fLñ¯†Øaë§?ÊİÆÃXìì
f¹[\m4ómvy~ˆ¤3óÛ.îÇÉåÍ‘– öÿ¦(­µÛ©y„sµÚ,§e‹å¾Ê”ªv‚Gxìø#ëï…£‡³Tû¤–ø}7u{ÿÔ¥¬µŸ™!³şšJ’ã/„ãÓyá»Q0<2Z¥.æÃ±sg¥<çD²_!ƒ¥e7<ŸdœÊ¡‚~ŒÙ/ÆØ€x	9PseQÍ"f‹È–ee•³ÊÌ2*ÕW}8İíéTc
½ÛÊ|—}QÅçÊ!üní=<×9OÄ³J7!ç¿ñ¾F0ÚÚh¥†‘¾!Ä6Sº†
Ä‹on×ş-µ,ÙCoÔÎ2N:o4'0vL
|IŒiQHô¿Iò?«ÄgŒ¢É«ÿ”’Î2_¤—SRXªD‡¯€UwsWgT¦Q®6ï¿•~E§ğü„œLÉ5K? «19»i„ºÿ|ÎÂ>ÒU#Š™ùSCÊmxMœ€q.€PLVì­r6§YŒUZn«è>1 š9ŒÔğ}½|û–­Mv_§D,
hÀ)\•1ñ„ —S/3Éô‹Á¬£&‡J§WUñ¬J,©şÏ"#&(´"\DhJã\ˆä¤yøø3ÉG¯z	.#xØ*L¸ÄÎJ )G½ªöG´”WC6Êº©œ6{)Bk2lli¦Ö’Ş æaÔİzkÛ(Q}Ò¹{ÉŠM¯ÊŒ÷yíñ=':Á
tQß)‰+£l…t M­óî®pŞ’Lè<'r›© 7WjøĞÂTq<„	Ïà9Î¦g#F·O±¼©”ÁÙÕ6…`Ş}ù,È/uÒ‹¯ı(ÙÊÊohğ´Ø-KS)s? ¦ƒÄ*lØë&’ìW;½^6¶ôÂX5Hï×à‘ïs’áNÒFQ½¤ç.»W­ßºf¹¶’©kŠ$*ŒA‚t5r¦@vo+ƒ(ïUï,(Æó
´”‹8¨äcì¹é¬Ç‚˜Xbo–,…I>.ĞAGáÎ]Œ¾µYg.Q"Sd_Jê‹¯y®?°Wø&'¡ZŠC@²qƒ™o8‰§âïÍ‹²Lª¾Hïßü"¥¸³äZóøJúûôCØg?`X÷«Ğ:,]Ò:xySsœ;.Š<™‘1Ã³2"@GèúL}{Ÿ­xØ\½ÚF®Îa²¾(7ìnˆĞŸAkäH#6nË¹ƒW|½ËÑ•´Í­"â¶ERwT }K«ó`ÉE@ò™Ü¸sÖ^•Æm]!¶ÆÇƒó}`\ĞòeÛ,Dqõ'éïº“éİ©OM¦7Wó˜¤›)õ–ùªÑ%-"¿÷P$à†Ïb4±ƒAœã`wı·^¶v\†Kû{kıÆı¦~ÓÇÈIø[Áñn¶¶ÌÁ¾•¿ÆFı";©ê¬¯ÉâÛvâ »„ 
å-’|«"&p-í)h¨;ß„êzÜÒ0„\cb"ÙwÒå}U–›8yqÜ˜ÚTƒ¨•µ {#sÖõÊâSh\òg,ÂØ’—ê–v…òd´Ÿ³wÜş#‘7­÷{˜ç©³vzn;;Ñ°ºîçóÉ¹>S‹¨øÙ­û Ì£WÙ`õË»§õ´×ÒAfì3¤É¾˜'ÖÚ¢3’'‡0:{ÌÛoÉD'¬´ÿ4DÉ7ÿ0QÖo©¦EeÛøKÇ¯Z&óaóßÁğRfÂ—p§V;e¨VõV–Ó@¢SaOöoÓŸõµac89ŠÿÂW=-oâöÏî’2‘£Ÿ›àj)æ›aT(øÒV·
ıff ½ ‘òúşØ´µ"úl¯ñcÅû]x*ÍÒG( /0B:Ş¢ë¤?ÿŞ·£‰ÇGym™ìO~Hôß@ã¸–ÁJ°F[kÜ²$ä8ª-U›OW/eb±
©2®ë¹-ãĞî&)å;6Ëè
®Yón@úvì;2%@H¡S™”Ã‰ª‹ô¨µ
øSN+lP©9zŠÚ³¨ñ/`Òp²-^É3Î•Öêhé¡‰’öùâ1ÊŠÜ½K:Ùş~Ìñaì%'qWşJï¯WbòåÑ1œlÆ[ÁŸ•l™óGŠù<’î¾V'‹œKßYyœGÒÂ&] §ÊÇU^~.«,›Íÿ ijØÖû¬×[¡Âò6-Üçwú&I{Òşê{»Y“vİajÖ—ÏµkµcäünUTX‚¢9'1Ù<£,â^Ñı´>>I§ÙaVÄİ$Çk[ƒ´ãÆx¬=7W®ØÓ Ì™ÅÓ£ê}Û\‘àtÏG|¢bUE¸‰ÇU©ï¾Œ×Hœ`¨;çl†Ç|XGZ,M÷œêš	0->J¥¢JvãcLÃÿìT†æé}U/ïü/"O¬.8@:'€±+yV=ÄÁ/Õî)u,_?&Oå!¡  ²~û«;ìÒÍİ6 ¢ìÓv	2ıL Ûµ„+ ŞTéb‡Ô4·ÿ£¨\JtÆGTåñh¤™ëB ¤XF…ßİ¯Š–²ÁJh&“ ‚ÔÁ„ø‹ƒæ8ÄÏ›z`%(úÂ~ø¾·½²„6¹tC@R	úÄiµŸ
'”8¦¾HRÅëô=iÆTZ¸?@]ˆéÏRl821xl7ÅæAWÚƒNûrX“YeNüşÑÔC öüİ£QıšÚÜ‘¢Ïıh£²	ÈèóL–ÌM#j™…º—v);1…YBeÆ´¦_¸Èï÷{¢jjÈj¬2E5(qG0À4Ì˜6i”Ã±Oš³iŸi'%†‘-Ä1ÈÇ™ËB¦knjPÕ•!şÇv¿ÀüÀ¿Ì»¹å%i=‡Íşv?uÙ¯6”¢£™Y+ã}š¥ei­äÂ »^ÇxMÀ?uµ†¾-C·7ñ«¯8_LHáDèKq+t˜ÙgFÊ™L½¥KQ^¡»bDQL–=J#ÛT„PäÇÈ<Á¡•3}óu–Âæ7ñÉ2ùD7QÕ$sıàs€
ô„ÒdfåR³úzšÎÎ„çÈ`™œ¸† ésmG×r~«këÚ€VĞ½mqØÕOLßT5NòE ”&f÷Ã;PLBÇÉNâUfÌk‘NlÇfTÜıÎš-–VCÉFÿêmö”İ‹²)°üÆ.H[ƒs“:(¤ê>ğÄÎ¼ÄÊÈjp0sRò}ôy"mŞt(×
•„8kÁô«Z£æøCPÆShÛDGÌ‰4“b«éa¤¿½’o†b7Ä¢œbvÔ÷LÓ5'Ì€ã+®4Öœ^äœ>^§ZXµ¥'õ¦âƒvú‘Ì°¶˜!xŠ¤}òúÙñ›r–ëgà*lUf•¤[ğ„Lêª0Oß\˜Ãƒ²«G¸¢ĞF£’hnâ fq–×f‚6½k‚Ï1…lZ¹ÇåmI¡4¸¾Ù°ŠNTÉ C3™ÔÜ tÍÆŞ`oÂYÔÙ¤0`ú¤|L¬Å§|HÃ¹Ygóˆ.ãP5Y9¹ÅfaÅKÆÍTd|_tBú²9¤d»i7ó'F;#úJ‹!ZN¹R\<ÆÚs‰‚
±3(ÖÏ­€†ø¼Ëä¿}g§ğZ¹¹ü$ÏÓ/ÅñfR€]hŞ€3ÔI·"H]}Î€,Ø¢u2ˆlØ‡àğc…²Š¯v?4t²ÄFoÿ	ĞÿƒÍ‰¶wøK-üa¼›ˆä¿p)¿ÅÇO¼5mÄŠ1&Àf¬Å’º
å2‰:Èp9TØ¦‡süå‰©@}RXWıf¦¶Ä¯U!+CÈÛ¬Ãi Éğœ=×ÚàùqËĞ«ÆN0E-Ÿ£°ş³ß<hu2Â$ÑúÜŸ5PŞ­öØmH´³áÏFˆ,¤«²\qõ
V°ÛH¯³Ğ@ë_2\˜íœÓ“û · Ğ5B>GjxÕ	äÒ{#GÁpè4ç¢¯Zê“Ô$jßwàöx‹©À¸N)Qì'›Ø$¿7Å²b›œ7‡y­Ro×‚múã5l˜p˜“~lì™K)ø†ˆìÁxò@ÉØU4±aö9È‰}{Š;æz<&ùŒeD2tœ5ÚÁR©m‡M>6şá{®ÿ‰5…ôá§¼s0×ç£x_\À	¦£ùL\úç&5~vZr<••é¤ÔÅòãMµèà `¡´û´è˜İĞğñ¸e¦%­h¸ğ8öî7\¦D‹%íQ3ƒƒ)W¬Íz›`Ô†r]$æÊN&˜Ri¬ëo:NuU4—½ŠĞ²hRit×ß-?`2J'”©ï~¯.	N$Aï…i÷*ôã,6ñ\‰RI‚HšíâódRİgöW%1™³ˆ‡E{Ó n=ÌÀË›¦F—†vPòóóÔÎn¾Õlµ€æwè#ÓlS€%(î…‹û—İv>Åë hÛUƒj·Æ›ßV<‰= %H0’=†D€3]C«ÂÛ•ûaw5ŞâNãÛüP{CE0çp_FÊ…V`ô+AxËYmÛù½2%’¦)ÂbO!F|sŞ´6ËÑ«>±DúŒca®“åGüÅwò'¯z®"f^XÎúê›\ß0oÿ”+h¤€»u¡›ÔÎr•[yÃMÁ¼L#‹u-1æÂU×öN2íGzŠêcéÆ{x‹ˆ5JÚb«9lqD4[~àÆk”Šú_d3Òg+¹½ûãp¼æ¤J²é,)”œ©± (@m{i¸«ú›„ú·“İ’¾ÛÖîÏï¨u r7†ïæ)ıOˆß{E‰$ÿêU>¦D¶Ê;‚8/ĞrËçØşH3œÚ´Am½3Ê#ìïA}a‰´V‘jŸ*Ğ²ê
ÎÃq¶O’§Jš9(´Ò°§êò%î-v oÁû‹‘!Tsé}ŒV™L=É’ã¼²u9 Œs‰»ï·;ÿT]ÉpüBbTJVa-rI¿=+.m%wiı‰9Djb).=.ĞÉ™ãX¥ñ–´Os¡}*ÿ¶‰ ±)e VåŠÀƒÃJ÷×Aê²‰”»i ê²`<Æ…YIÂŠË–ÁO2U!– EİLTuî
)U`gtÚs†›çm8ÑfW©íŸHÊ%Æ«¾:ª4–º›'¡Ë r0åéÖ ²Ÿ¨ê6Q—'’tŞì—FĞÒ³‡•V­îYO€ïU‰“¯Ìl#j.Î5:Òó!ZŠGrø_ÑEşkùº ui‚I¾ä•rÇöö‹òAí¸3³Îæòtö5ª”¦.ómç N˜0#< cu|^ÑY«í‡qábıg îÓ°-Íéã^â2ôæ/àö†B5Š…•É(Ë›ım2}*Ylb'[*k¯üt*@-Ù‰işó±ïb­»n¶D TİÒG9 xó|øhåËş¿ã"„«-kÇŒ{UËb¹1¦Ú¹Ré£Õµ±ŠàG~À†{Ó•ŠÃ‰ïÃX}ÉøI®£>kıú€ïláHÜ 9`Hd¹0º¡ŞK‚/Öl8gŠ‰D:¥q\YÒªà$W]PiH°¦o:$ía‚À½Â[T(Ï*ú7|ï^¨Í¯øRŞˆ(#/÷ÄÑññWTÚ’1—QŞ6>É·sC|¹m¿>PÌV»Æb‡’êèWOÃ
QóÊK÷ò«Í¾[7¼âaBQè©øµ,11uAQ›`Q=¶¶ Xê%Ö´¼&S½ÑÜ±êVu'XnZ\‰l„tOñ•’ßs97¶…UªM	¤èğ$fb•ñÀŞ—ÓG ³üH6X_[ Ø¹*Ë¨10°ñNì;ÅÉBÉ;è|hÆtõ ´LI?¬NL³e-¤áud×wŒİ÷È(s±f™ ãÖö]%tÁø¶9¢Ô_Õlgœw:èY¤„‚µ{åúŒ8‹°”yûsšMÁú÷´‡FòUJ¶†×W¦õ¢¿¤MHêbÈ&øùÏº—B\ö¨úldŒ@CÓÕd‰èKºSâ¾›¿‡üA¦G ıù‚dïÃ’‘d¨Å…D"g|¤]Ëˆ!LêuÎàñ
$Ûœ†oÉÈÍ%X).O«%t,­pß¤±xÈ'Àğ*Iq’¾6;â(çŒ*voš£?¢Üd,‰â\u£ÿAB«¾è!!¾¼<*æl«µ‚ÀRµBh²#í¬75Ì›Æ_£èO«íoä¢üåä|œë\¹ì50NVÆı°säÓöRÚ´Éùîy5+y¦¼ö¯6ÎŸ7®åUbOÎÁ#Á;Vù=äÿ%Qcp×İ[÷ºRœ*œË[0™‚`½Ô-)¢áú{‰êß*ÖÌ>È±uø/Ş¦†{{Í4Ñû|kÛÚqæ€$¼“¨\;.ê>¿Gã0ã¿Gq`»İ	Z‘{=¨!´ÜfJ06ó¹rgõS!?ÈÅÆßNùËï¦òÙÿJñîø<EÍ'èçT×?:LÇ¯ÀJcÖ$ûeÓöâ{ğ|·å8Üå‘Iö<¨ó"€°%yŒ×ÿZ  4æÆ ,+ÖMàĞ_Tvİø³ÃÁ¬oDˆêÃpëOÍ]`Š¶ÚXÀÂ%(]}¸%é½kQµGÿ·Ì†ºê¼q*XÕ¹ÇĞ½*ËÂsE<ÒÇEçº —èMˆt$×
½O›ÖWRŠ‘l…,7lÑd)#ØöQ	OmÃa¥8u€ı-7hvˆVB÷ T_&SÖ'ívº‚ø¯&|±ñ+u_¥îàÁjy{b‹wmq¸¢|†UbG‡€„{­Y®Ğ6İ–Ë?wu6ÍR‰¶Ò§rHRó ó‰–1m‰5d«6e
Íÿíİ¤úß­³™%FE€)EGÜ¯}iñ:µ÷áº½Ì©öŞp‰z¼£*€õğ ÒÅt°ïõ°ÃdX‡İÁº(ßĞº£¸ˆ‘WŸâ®ƒ2"ÇìO¼Ñ°•‚)K šf¨ènÊØšdEX3±z 0vë*±²!Yë!Çı b©PîÆ=€(=Ç¶æˆ·§ n55Ÿ‹š‘°¾ß^Ï÷Ëv7Ê4ª-Õn³aÕz†:·‡ó}{ûwo	àë!ûæ¦*9)óîRèˆ°vÏ#á :
‚0qùpë$3øs«yû_ö©W 9@i¹	<W(EìâyÀà.lî“…	—ON6]7sŞãª ÆÃ-f•™?¯KT†FığÔt`—´8ûƒ’Ÿ´T¢%HV¦:Ş·…]óEÏÓş2Çİ1à•5<ªjgOVš¦çæ°‘Bİ(¬@£:Å¹ı¢ì4½¡92˜¼Àpõ™Â0C–nøÎâ_Ì™3€+Ôš¨èÏk-ÀúEÁ•Ñív#káıá oC§"õg£7úeûzt,´VÔ:—Emƒ E-šU®\²óp€¶ñÂZu
>ÿgª_BpÄ1 vòrF$‹Ù‘ÉË¿	‰ À3>âsÏá×šåãpºoûA¥‘÷NKşGËğª^£
"}5†‘&Í¹ LØN%)åÖøş-÷õ>’2Ø¥ÌÏpŠ[v¦-J'¹Ô|›ŸÆwwOöz“›/‰M¢¡ƒ_{C4FÖ_1Á—§à›±Ç/ëÆéæ=R4#à™ËÅIÆÈ£×ÕFùÌœ6ÔÉ¬Y7Û¦¼×CGÂOƒõ´ÙiİéB±«|c[®'ämc»*¿úIXşÀ—OhÎUh&]¹8¨ÿ›¨YĞx´åÆÑ­&~˜Áv’[hº+Ä•oğ§{GÀe§(È²…÷+g‰ºCÿŞ¬…ÔĞ„ÓPÌ/8î¨¹¡FIr&àÏ'–aà÷¨å.ä—…Ñ Ş‡­0¼jt‚µ\àjô)sÍ‚èåÍQRí/¬øîÂSÃåÇÄœ¹ùÓ”a½ Ş›«âÒã®S
-¤‹LöHf_§¡’Ùî¬yŞ=	CgÿWzJ6xDm¾#ÂƒéÜq_Æo0THœIÁ©ëmN3àSèÉ½àV36k}RnXÄ€Heè‰7‰dj@öìvN.Üß×F•8æcƒTĞâÒgíé)âR‰¸L´¾áY}]
¶
¬’ub@Š=X¸IC ‚ÆÕİpd†^S[é·0Àû€õi‰/ï8%”Ö^wTO}x^;©,Í1`Ä1¼‹¦Öx™\*H.âş}ğW …O½Ò«[Ğ°0+Šå:‘ÔÀqÈµwôAÍ¶Æ¼zĞ¦å|«sêUkv¨Ì}#ãÌ¶—ãÿo>Ó,YD¹¿}ùçB½ï“²DXÅ¢z‘š`Ò¨?Hî¥àáéKÓé’w‚êm‹Ø&ªÚ1™$ÊåæÎÔø‰™ê,eseÆføûQ±fß×ëËF
û'0pÑÁ•9Zs—;1ïb‡²Õé„œL¶×ŒyFİ¯ô¢zVP¥›“"¯•òñôÉdwÏ#k–mÊ…_6ÏĞ(H—™®»äŞzNg&Òj¼™¶éŠ”M‚ß`60p-f79Ï" ÄN-´sÓÈy2¿C¸8“"aŞ’øîïğ);d}¨šÇ¸ûÔÁÿù•š?êØ­0q@ÅãNc°àu›ŸNX¸=”{ÂB­ıÂ¦!ÏhJïø8à’ÿzHÆqRu-¥4»âÜŞ!•(ÂõË/CÃ3l?:±¸)÷znáù)œ¼ªÍÕ€¶š':å¨ó=ıÀ#ò*äÓùâÑÜ!
œ3N?oõÃæKÂˆît—{
Ì6ä7ŸOä‡+«k?páÇ5ç6Ë“èşs±°¦ÏşÚ×!µ·àÎ®R	€‰(Z•Àè&=ÈC–(çEÜ+QˆFYÜ@ÀØë“ïÒayWµ°MY^ÔºqE97}d¼‡«Hû‰dC>_^¬œ·ÒÅ²à¸RMŸ |m¦ÍÿòW=»ˆQDxÃF¼˜'kÔ¢İ—à– „ÿÿïIvH–F¦Të˜/?57g4f¢eûwÔ(Ü¡˜¢Œ;ÔëW„áøª<°eícÜ_Ì@cãò„t"{y¡Ç’´Šóœíbt~ôJ×>+à©¥Y•9w§]$á¯×ªÕŸxÕN’ïÈäSFNkÌ:.["‹XeßL¡ÖğúÎÏºèŸ™–?QDíûpöŞp —†Bı„q bpÔü¯ÕğßU0’Fdó×[®÷§Ie\˜%fı|¥Ùw¤"7˜â¡şpåú!ÏœmÒº¡C4¤öŠûELDsÌ>[äu—¬¹ Î“ò-É|ÅÖÇQé,şUàÀr-!ªHŞ-0ËAGifÃ¥õk»ÁÔ³,}ÏÒ´ğı‘…µ¡ùª²¥İÍXn¤Å6€÷­O	CÑÃĞãë.z•û bA´'·çb3§ç€ÌVêûÕè*oÊBxêş*(¯>#sÆqñ)Ã‡3èÙ!J[ªfSÑòÀrÂ‹½w/ò–”Jz3”Sûö¶#·rw¹yŒ
,ˆ'ºÇÇ$)×Gßİ½ 8 Ht½íO•{ŠÕ”.Ús+ÍÒK“¨C'B{S†ùbÄvr”Áş˜ªºSZ:<ÿj*©P‡vùr¿&«är×cÙÇ0¢å·RÉàÛcm,HHè'_¾Úí€‹"p½¡ãlÚ@˜1	ÅĞ 8–Xzö‘85ÕcIƒùHCÖº ¼ãÿªËŒ4KhÁmòE¹'…7†Iå;4Ô›€™Ã®ıä—|q{˜D}LÉ7ı ïÕÂÍ4[Ve®İİG`\ıË<rÙoŠµÔ¹1Õ1zç¦|Í_v_;_ƒñ†ğ”lñBôÀ@Í%ğnxŸO¥9ÄQ¾ıo –mÂ…Z²ZÚãPc˜$ˆ-szßG{¨ÊØ(ø:UÌ£¹ ”NH¡{9€“¥×P%ì¾•Qõ*z÷/~|>áPT¹©ÿáÑà‚"Qjs øB{Ü63…KxÌÚšQçùG­³ı–ÕPùo?a‹Ê0|¢ğ¹Ğ+ÜIP>èÀ´eÑhGU õ{›¶)V@ú¨÷ı–?…ÃõH21lÏ¼\¯*¶2#Wo5«°¡íúÀ½Ã	â©]¸q¨®hòoİt‡Bø°g
éø¤€Š¬ÉªsÇéZ­[T±Òx{Éei9C˜0tğYútA&uQVšÑGY‰Î(Yæ_ mùlŸšŒf½œ’É¿W<dø£Nà)n<
‹QY†ßÚoş¾ÿ¨T¬öYÉÌXé,%sÿ(wÇæ'ï¥¶ÿ6½Øq©¢GØ“jxÜºnp§ei³6!­ınQNGB'dÛé÷ÿJ´éÁ„Äl®4’>B4¯Â¨ÆĞĞPn9Ø¦P/£’u<¾ôÛÄ/îÉŞ8Å‹·ƒÿ«}jOÛ<o‰ÍmïH|p’#µJ¶¢‡—-Ï\ÀOí)Né;?>§²O¦fµïeNoxhQÆPÃË•Ö?ÏÏÁlı1gİ‘Léh„.wòy¾'1dF–
KO`ó½4KœG5bÀº³2j_yn¹m¤ÜW~UæP¯Né¯‘mf"éç®æŸM)„érœ‡—X§¡LtFRæêSU`òNt*ŸlG'Í™`D¯ÄÑ”õœG\¾.ì½õHPCÍ`<±|8ÉN?"ö¤è˜o(ï«et>fÖt§àænk?Ii³h‚N¯\ı4>ç¤ŠÂÎº¾8n>ÔziÛ›ıXeBri«¼0ä•VÓñuÁ)ˆ*Cö˜.x¸|ó9:Àõİ°“P×&§+]å¢h‰eô}%z4²$©ø21@b¯Êª
Š.ËoaB}0$	¨ÇÃwcJ1·£ O|ÂOêÙT&€Düò.'¾ »a)‡jvw7$Œ:ú4÷–$îûÿoôà}}çmõYXÇ±•ÍjX`˜â%ì7ä‘ÔF(à¡~<jvJ’•‚7¶`@”…éU·dğ¸mg¤ÎÉ"	Hê˜ûK%&LR±­í1ÇAÒ„ní oÑ|XšøŸ!€öTµ+*" ò¥é²óJØiÁé*K4€I%ÚGÌÎ„Şó(ÎW¿¨‚;jZV«ltå¿ˆÄÎçŠ(ò£TÉ!	MZü ŸùB]ŸÓiØmx¡rı·ØSşØà)QqyEî=ĞòÙ[A×­ë¯ùå…pÜı¥•j\@%©/ËAÆ¤k-Sˆi îÀ$éú¢Sùl¼•M	mÔšÃ-®Ğ3}¨(2­àÇ¥Ëâ<kF§èòRŞÌÆ®—­etıçEÿoımŠˆ£¬‡Ğ9¤5©u"—#*/òîLh®OÍĞ¡	É/A:w'2Iyõùí+‹UmP„ŸíŸóéH˜û¥&B*K4Û¹ í‹/n0ŠæùiyÂGã]`cÑl,„ì¶S‰)€UW&ÆûÊÈsHMJ)/fãùãÆ¢~Ü\>ÊƒñàA,Æ&U7Y«"˜¥‹¨ìVuÌ¥´d`&¹ñİş\%3šÊ¬Áü¢y6AıÃeÛJ¬¢€P‹¶®ÃWxÿ¯Bhh8í²Ş™ @Qv´nûzÊ¼3î6s›2§=n¹ì'féé)ÿ„#EÄÅúo›ºÿ—­§u„R9ÛÒŸ²½mtÚ4ÈÃûhËE’ÌV Ğ¦3aIşA‹:±Æ×“½ˆG²®#qnŒ¿=	ÂrÜ¶Ü°ÈıÁ¤^…‘>“¸
#±¬.ñqµq9>>Úß®İ!!ƒ5!ÛA×Øn/–—uYíFºá*´OiOE¼¬¼íƒoT0&fs›[ rXô.U['a­C×<xrN»Qcê£áû
3æ²Êº´õQvpŸÀåƒ1™Ô‰R¡I
õœ&ªßû„±¹boÁ%ùh'E
5zÁê×ØsP˜ÅíÒ–£¥…ğ’iö7ÓÖ[‡·•²!·ÌÅ°·ÀÉùKtßâ ,Gş÷-l?şª…Èÿ¤Øˆ(FGŒ¿ø·›üú ~Áœmš¹¸c"±:“2FÀ‡@¸`¸cŒ&-J½?á´òbÅ¢Kb3‚ùR¶®;&[ª”Übév«4 ˜ÙÅ´[LÈ_ªıw×G£<i‰˜!ø=VRÏ°rÒşˆg€F]›ñ"od°Æ>ûdßZFÔïÁ(ë ¨Jæ‹Cn³hà?Ãb	òÑ®€-4%ˆ¨A™ã*"“Ü‚O˜´G¶<rû½éâO¿=@Š. K?d“¼ÅäMÇdYrªôTÀLÅ„[Sğ×è;
è¸%ì/BÉ”ñ<nĞLÿ¢C„ÉH·Ëˆ¬ıÍBZ<oQS¾\üXÅT`@e8ù°q€XÜ‹lK‹øÂ½ÓTÙl‹a›DP¤3/·5×3ã†dV»²Gˆ|õÂ#!äÙ·4™¼å®ºè‹]r!hó$h"UˆrÔÂ]¾^ƒ­å?×W•ŸÇË-à]:m¹“'üªZ€*Uó¹ˆÜ{z.èßyÏ‰Ñ“üQNê
RO—zŠêöš<bßÊ[^FŞØMCQ¡³ù“ `Å=JU«iÁå‘¿vP£8g,µ<²öÃ3ù¥˜jF›²«÷²ñ¿v¬êØaı À£qDVçjÒ
Ê58²¥=Z^F¥³}Ö8zb[6dõÚTüÍØ}5ïÕ†›nVC±Y<¾Ì	/‰àˆ‚Ø‡ ò¢FÙqBD=Å>6–v‘<E+Ncç3AŞLç¤¼È<uô}ñ¢G7m+z\Ô·ud¸CP-kú‹1„ôş ÖWÖ•äcnL-,eºäÂÚT¦xù>cº:Å\æy­ãêßí½€Ñ‚P1p¹# Rëf6!}t®K%7VçLiNÏ)&…=Ôo:-¾ Ô„æ!âôœ=P¡od¾9W¤/0Ü§kó1{*3D"m”ßÑÕòöTs1:†MŒ&÷KÃm3Óœñ-×s ›¬iÆ	ğq±‡S¼í“*r&·Å³¡p Ñ}dEk,ˆ Û¦ ¸¨R]æÅ(i—ÉÙµzA—„‹t HáYn÷‰>ûr¬çJ•ö¸}pÀC1,Uf‰Í.aõoú(’#xjĞ¬
©ì¸é?c;ñÇK>uašEğh«; °%
ø„!ùËÛÎ²è\³ä_€#½’–údœ1Ş¨&Ÿ8È;ÓI<¢Ôâ,‘ë£Ì3ÔqÎ3¯%3·_LN¾îŠo)P_-\0c] ·‹¢¨&y±»İ¬ÔÊÍ‹*[£Ú‹úe•2¼´#\‚|æ÷¡«+oàZ—`Dœ?^ËY,rB^¶Õ÷	İõf'Xs¤ljHã&^‚rô‹®µšÓóçıO|Fá{“{O¤NSàé"ŒÉ»uWêÿÜ Zo?8jUw™†	XÃ²’671D'AşGGšÜ,t´î
”zy{»±¿ùËÑ¢«ØQèO¼£ååÍ3V¸pƒHò¯}Ãè8ã{S@¡îú÷}ø…ÅE:9¬†¦Ÿ@¿ÏGmEÆ™¤çöA(İî·‰*bıÅJú¡@A¿Ñ.ÎíØo´äÖ³·ÿ¶¦Ë»–ÏÚG7İFŠbÂw5u†óÏür™S’·z>gı¼!LQ‡P[bäƒrŒ/q^Öe²ú!°MºöL·:mğxª_ùY±H¨AsÊªÍ²¼EşÌ	œoWå{Yäü“¾¤E§™­¬&ÀšHœ5ÉË°¤§	sªY·t!Ãb W­ìŞmÎÏàÆ¯¿,½£Ø¤(Aª›‘®>fC†2M³U0ÌÂhŸMz×Msøù=P,XîJ—†¢pš£b¬çFgiŒT¬b¶ïåA*“’¨·©P™q„Íí6Õ½fmÿš ğÒú#º®Àol‡è“à¾„nñ™òñ¯ÚÏ´1¯İ»îînMõ4ï‰TĞõU9,Š*ŒùfUaz[Ğ
ÌÅ‘ËZâ»cäİh¾¾Í·…;£N´ÑæZ³0^r	|Orà×ÌÍüo¬]Ø[Bü¨ á™oq–<Ä=+;1Vhü†A%ÿ&WßF‹ˆ‡tØ>(Qá]Ù
 [==[êweÁÄy&]öI¾’A³á
•~/)·/ôßÇ…ºÕ…äÇGt£åõ¬òV¿Èõ÷ü,ˆ™Çu˜+“òÂşî’¨ÌÚb¼Ğ%:Õ­ÍuìN«{ «­Ş1ämö…·£‡Ş· á+o}}92{›¯õ¸«µÀñ#À¼Ó¼»1«bôñ+Ğ.úú9A’O0:EÛ%Ì‡°½ÚxAYÕÔ(Ş{4’ƒ6òÔ¿3Ú·ÀªY¤ŠÏA=¾¯+ØÁŸlšø»¨ÑºnExœìĞòşúO‰Pâ$@µÖ¯¼mÛ=f\‡ /³mk'LÓó?qv>F­vœˆ^’ô„J¦r÷
%ÑJüŸòA\üşİ•;¢İŞ~jYsKÍn:ÓmÕİ•¢bªS¿…h gwÛ”m'n#¹ü&©/äèÜKê}E	7ôÄKûğÑÜ¼33ˆ$Ğ–‘&©®¸Û‰ÊshgƒÄÅÇ[[¤Äí*oiNÕ<-¢’^¦tQÄ5”h2Õ.J.½ÈcÜ<,ğš÷u<ÄACšÓO`*¡tÓ×¸i)ÈÔ’_İ‡-Ší€öqØ1báŠC›[$ÖØ\]æ¼õÙYFØ·Œ¸¶sS=7ÉË*‚ÙßªïOö3¸æ¼¶D˜€?z­ÑÛ?F„µzá]íÙ±ˆ8SLaN(†¢Š#†º¸µ±8ÎT¤LÌn¾¼÷ïWN¸ÌcGã”qk r&«ıf{hK‡\EU `D.ÍËÏ†êQzYæ'ŠçºÇ«?·ñõŒñüş¶Uâ
H -Aÿç)[Œ“_‚¹Mp¦–ïÔÇÎb4ÇÿŠ¢« óPe‹îäã1Áb{îy¤€ lÔÅ+š1Ç½¼–Ú’ÈåÚ£pğú
1Ö†J“1`yµ‚'ğaÃÙ^Mµj¨ RNhE'ò	ó§³ür1ôôe®=¼é2v0—+g_^¢iwrÌµ®ŞÑˆƒJ÷DŠƒ¶3µE¥4âgp|–­h†ÑöÆµicy‰4*Üıp=+.Çø¨<#÷ñåEÚØ8§o!DÉõiœúËåïu\îlDòiz±Hy/şš]òÄH
íüÖ]3îÒİE+ÀVBxƒoŒ?¬PGR%*åVHBÉ,«nØÂnj@b·	Ş}hÅl¿¨·†©’ÇÂOÄ»º±îüR9’”¹­âá…¥šqc »0%ÎúÛÛô…iùÌ±Ÿ=kğNAo¤J{ª3ÊÉoåZSÕmØbA‚±´)·®O#Å°jë`ğ+5áækeæÚÆ£¹Q÷D×‚×³ë9áE_<°ê†ìX]ÓAuS…<Iå¼ÇAGÓ¡\W˜ŒÄæ¹Ëk*nh“1ƒ%Œh¼{Jãu¦;[äN§øeë
Âğ)V/IHbwN:™ŒvQŞ€ğw7(†g	›ÑÚÓi8ÿ5ó{±À¸óšÀX²a¹OÜê÷Ë?3RA•QâQnbsC¨\½ş+Ø"íÎaø¦óÎõb%ÒQ¹—}QhbXéÂnjq5\''z)ë“‰¶İß¥±cßÍğr‡…Ë°áf*/ÁÈÇİ¨mîpöP¤¨‡Ö`q©oRíµ’Ë$œI[¤~u S§k›²kÀˆ¬a”-6„™ğË§À™Jş@¦‘Éa-CùÈIÇ1Ø¬ÚËÓN3G@u)L
Æ	3/kŞ¼SQqB¢ÕŒêî¯<m
™–ú{
É|å¥»-İT­P¿¹:¤‡½kĞ­t'z[$¨òVµø/^T(ù8W‘Tp‰5œµtmÇ“˜¯|ùu"Ìõ	ò­ô(DR¼8¢êÈÎJ‚.ëàeÁÈ¨>²i¾$ÎZâ$1È@x
R‡×WW.$$#ñ«É"Àªg(€œ1ö@Ú…±š@F¤©›^l¦ı5h<@Á‰–åd?›ƒÃeVÉrQ<Ä$XoUÃtïî—ÚúZ6kFv‰jJ)|ivÙğç#ínFIºFÂDøÿ¤)KVœ5Ğ›â&Œ›¢4·GŠ‚U¾t:ê<|/ˆ l>èz_Bàæ(7Í‚~¾‘Y‰ŸòÕ¿ìZISŠÂÊ†6M¼„âÊ3Ÿ˜HÆº`y8hQáüBßëq\ğJÛ¬Ğ ¶œí)Í™ÅÜÉÍkó“‚¸e°‡€kë?è!dşn+5íÙ–…_ìğƒ¬ÄòræíFÏŞå8#u´(aZ¢šë¾G ¥ÒW’Q¯¢f1uºA3¬•…Ô+9…ÕúM™ì^ÆÓ•8Üb¥ş²‰6uÁÍõ¿ÌîÆ·”Ù*ÛA/W¡¸óšéj&U´8Ö%æ`[Å	?iĞ¦&‰Ç&¶ÏqH·“¾àÁÍ ©ÃR0ñ ,74¬cbãÙp¬Ë¡³#2}	ïEıf9\¤ıöqùwW§{7eîÈvœ9œÒ
ÇqTıQ¿k
²m‹ü{$BG²l¡äRè+:](^Ê=fÉ ÙßªÁoêÔşiSø5êÃ¢¸İy‡HöF-æÆ(èíwŠAUNÈßR'¶¯)÷¬Ü™¦ş‡ÉujÙCQ!³ƒ„¦¯f¼durêÕ´¼'hÜÓ‡9ü³}7OÙİ²#Uÿ#]»Ë­qSU±ëQV{€ü=Šûa m#°ñÕ~AÿÍ+î/G‹jõ]DSğÍ™eÙ ğ³¶P=àaÁU…PûeI”ãË4†yk¯£G§}ï9ìc´)¾n<KìBÏpğÆÒñÀÌÒ†s,ŸÉôoa£„Ó?Æ0f3•…;º\ıı‡•Ô²~…ö’~r#jƒ+ÍÖ¡58€Ø†úÈ•2!V
§•ê;rg·Rşùø™²»ØïŞ¤Nå¯IëÔğ¯;ós¦ºà.]ûÌ §®àîğê’d9ÓzeU:ÖÊ*ÉP~É¤û€Ù}á,£ŒCÄäÓˆ­Ñ§â4)úx.£¬üÎ‚ôS†1'ğœb£“©#ˆô7´DF‹yı'V¹ğ†q`4è%ÅÚ©T/ZW‚KF“ó2{çs5‘¹Sfï¾èÀœuI% iÇ!.wb"ü»"GöÎ`ø“ÄòÇ¸.Rƒ¡Nî wJåy¤ú™¢»±³$Û/Ì9ÎİaS!‡x :ƒã“úZªøËhæÑN/CtóXdÁ@Ğjè´içGSÍÿmòúÛÒk"öP¿Ì$¾›T*
"¨p	fö~vÅ™¤ùÉl$6j*ŸÆÃkIŸÏûIÔ1÷Ñ,ÖQIß—MáÜsŠ:ä!|7Õ\®ê?Ü-Íı²ó†€’4;øŠºçÔ;“jIŒ£ñDÈÁ­ [¤êPÛ3Ûûº>[‚æDCéx¤d?•íÊœ›²7Î¢À€û—¡ŞK„uòHh<İÓ°ÏÚÛüãT$¼
WÑRaAñ÷n”å­KÎÉ—°öã²7´¨óÈcß,€ˆ$ï×<¦ûñoXÍšNûàá™Dx@=ò;ğ½N¼w~õÛ?£	É,b¤‘à( —½Aı;*yâ¬5Jïè[Í§ÿ‚7yèx–®.Û=¦ÖÅÂ·ıÖy)–‚4€s?ı­àBnFÉ¾üëgÁĞÃšõ²;şbFßêòÖy4Ú‡8nX6`’5½ş6<èòICxò55Wl7=–ğü–úŠ—HrıT¥9¥¯öãÕì`gÁ¹'3Í«öæSí’ó›Áá g•«|N•Â{ÄékGÎ9‡. < MZ³¢ıEDÇ1us:8çfªö±Úİ¦¸ŞòâSQ‰?3„ï5)Fa>Îfeˆ¹ùO\?Põ®Y_|¦Œ›P¬‘úâ¢Êœ°gsdğsGâ[E ß-­½ÍV"#8ò`ƒğ»9¸€ì0ÉWÄ8½S‚Â[VÑ‡¥i¯:¨²Rj…W¤;ßı"ªŸHB½s~•Ä•¸w°¨²\ÔéÔqM´˜›—	<g ª3ø¤H}HhsHŠcÉd§»fG=füàsq×‡È<Àd ş3ã¿µ››+$§ï¿©L}Â–ÿ…,'±'í@³İ&å7ëÍ,ƒL7É¥ÓìIál½ÖŞE"€ûÁ·Hp ˜íÕñ#–)Ü:ÌYHUé±Ğ^RäEdU Z+òV°\èÕƒ
¼ê+#»tÉû\Z>>§I •…‚+´X¨Â	Ä8æÏiué,¡µbÊ‚­Â~ïË÷(Í	+)»ìgC×O½ùE¯#"«˜ùÆéx¾í¼L²BÙ†xs-O1Qò¢õÚÄÃ†Î`u#ğ hK?Xˆ¥HA(ÈÛÊÆì“6|Ô…múáÀÚ§ÿÆ÷(¶m÷äYu²€]Â¢ö½-2—'f£H®¾ıûú$Æ»ìº"“ÙKk(÷_hzòì‰IË~àMc¯}"t*Uš|_)×ŸåÇkòÊ|ÙlE7jE³»-„lë Í,“=>‰¶5å!2Ãjıª^ß
Yşnk”ü2U 4Ä³…äªº¢,î!éRûÇÁ«¿%m›§®ŒŒï®é­ŞÈü//`|  Éb<²°rù=Æ"C¯ØÀWÚDÜ´\²…ş„\êÛ‰;|Ù;İØô2Œ?b.P8z„9g'›¼üÌ¦ÅÍ]d„j(f½qwg-¢;C­ÄÔ>—tlş"‡µ©éîí,Áó¢F¡‹äxV§-"ÔóBÍBÃÁÙ*B\#b•&Ï†oQ¹RF|š26æp#Ÿ„yNüF§åŞ·Ùöµö·	‘/D:(·¼ÁbÊ†a š‘Q®M¸eİVnLÉLR‹N_´ m¡t}ßIÃĞ‰áÅµŞ7 •ÈzèÖÿÃô·=¥èæz!·³Š¹¸ù²€„ø¥ö })õÒ¸:˜ö İßªK3µD—÷´ñ nñÌ½Oß¤¡A§n–NyÛfé91g2+æ£
û›†pÌ´\QºÆ„½¦sÙÿ4™Z‘~_èÊSÈ…T|Û®%È]ËıjJ‚CÏb7†¤¤*À (ºån}¤BJt·Ÿ,†¡Óh¿;\öç‡è©*®Ó?ßvS9ÎãÍAÏïl$b6<s|'°¼åG» \cÍõtî‹V9¡ÂªÑL·„K™J×Öä¼’à€+š´F¨d¡w +6é:÷Xø8ª Ô¦şòïò÷Lî¯›ç7·ş´Ç•Ïe‚ °_È»U)!ıUÔé¡¹˜â]=!ôufw_/Õ:–¯“úŒc:¡0)Œk¥O¾
’ÊÃwŞ·ÙBg¥®W4d€pÜq0aQóÈ½>•š®†×¿ì‘¶PqcWGÿóIz‡§p¶óWŸCÀš1óĞğ“¦DÄ£·ÔÔ^zÁ:IoÉ{üø:šÔZ)±Ç¥Ş+ôÍÒ‹÷ËU›§Ä)2ËÉy9VßÖ^+-`Œé–Öİ\²«0ÿ;­²t­.oÖ|3>CØ²Td¹éŠj-"Xt\€HO~Ö[s,\wí(m—+`8ÒÓ²vÎ­wiŸ/t*8 ¹¦	ğæ¥iä*r·âDíGô:cé¯!Ô¹ŞA÷tÍ'2ìDƒ‚ïË²l|cdàtiš·¨åücéÍWªwk·,ân"ü}¯9^Ğ—3³õ¬l²Â,˜¿
ÓVèª\zµ§+>
î}BÁOäbı¥¹*†b×z	t€!½à½cïWi’o›=óà»q÷‰"l¿7$[Í-.íÔª²ô²ü—5ğ@Ğ°¦LIª`Ú@lvş²jgu¶UL63¯\¾şßÍ‚\6:êçÈ>‡•ãÆ«"IsˆQÎ…,!¿v‡)Êyä­×¶¤zÌ×öíÈ†´®/vÛ!¿è>©Iw8ë«*>ÎkÑÎµrÙ¼›ñZ_Äæ¹eÇRÎ—hãAéïis(±aLqzh||¤@SöÿªMÀœ6uÚ•ñm&£7€È‘Ö/R5Á¹ÚÕ.Ù´<4/hÎ°x¡ÑcaôIş¿¶¶Ò®T-ºo‚XGsyšZÁòSüh²§Ğ.€+ôA>½vôèñ $tcfá|¯ÇÓïn-Rc\œ]ãâÏtÓ%Ï\XíSÍÅs-ÏO‚0—/–4fµŠ~6'%3KÜéŠÿ„qhıiØB4“=Òv$¡">1&Üó½oí÷É‰L7ù™tñ43Q2äğXÒGL 3»Õ·å`Ñfˆ±ãw{\OönÊƒJ'O£úı­wâ`nƒw +‘bPg¹"fÚ)ãµ¬$/BÕ¢'Ğqw.‚5'Ï|¿1å’È¢˜‚h9;Çóx8ã0X¡DÌr9gò»10VdúI5Ä6á8c«ğ[‚‰.ÑÁ­ï½t÷˜Üş|’&% Üª#ê^[İ*n­¥EãY®ÈÂª}ƒ´©é Izr3•pÉCãİòÃ
AÎZŒHî­ä	@ÉFC×‘ßô8¸*/¿Ì³.ñßWæ—7__LGH¡yq2ù¤~Ì3éôáúÿÖ³””¼jÏmÃMÒ@s3b°6e$1¾Fÿ«+İßó¬Nà)ËQb|{š«{¤! ÑÜõ©'„˜ùÒí/)Ñ+,Â¶ÂÿqËö[JÌçÛnsÕèÊé:¬ôŞ%©q1o•ƒ>¨¸Çğ«Ì)ÇbÕ.ñƒËÎ§.GÑ)j‡5ø‹W¡Ö3šmS´tğª!cÕh§Û[*2±eç2ÖJé§Jy×ùÉ-‰n{!ß]6D»©ŸÒöÆÇföqOûÍıâ¾‘^¿Q5a›à-q~Ì Ê —8çÇÓœĞ D90øîà¬“ÁW ={ÒşEx‚¿$Å‚LËŒŒ
6YÌöBº@p°FáxÈ ó½Wš×¼V¢.ğrˆblÁÎëv-¸—÷¼;…„ë5tôWyÂ³¹Ÿ=£´XÓåÆM1¸ññ¯qRWô¿7–½%½ ğ´ÊØ}å0WäPıÎµ¿8†c›0yû:fo¡ìÈZöjY¶ä·İÌÿù¥Õ|²’yÔ¹ bÔ8¶ìÜ£Ê–0Õîü'\ï,bT£±ä ‰lµÄ9Û°×Èöº|i.„pi¸ƒµŞwƒP[€õôş.šn1DÀ†qøZYT‚eÛ¥Q(»f¨“RLc†Ó¼5˜ÕŠ%òŠkÔ‚×#öoê%â›1|eÍ mo_æ¬“ç8à¨qÈHy¥à=&(n8ÈØI;æb©œ£dCaÈAÙÿµ\1ëb7C|¦_K6<}àw:~S(ò w•L$Œcn[Ü8[yÖ'ÃÏŠáW~£€Å5}QËğ|ªÖáÕš¯_€ºg‹ë•ÎÙÏG0ï«•â^L¯l4Ù b;I•½¡ˆ#˜Æ•èÇ0!üîú]F1Ñ¹Vñ¤»V˜MéùçAø*ÄL•Ÿ–õ=>©!Ù›ŞX¸'°5HÂ´- Œ×¥=¬ëh£(¹¿å$c44s™¿î*¥ú÷˜#ÖB™À!ïğM?÷‚ûêµÇ
ùı§ÚÌ¦09dëlVÒp±Ğ¨¤÷×;^+ÅåÿZÀ4»š%Ç:aöQ¿S¹DÄ§*Ñ×hê?uZZN$ò3Ø@¼Ûòù‚©nIÛhEyE9—_R;óâÒ&J($¤øµØÔFœiDtúe=/_“ì¶¹R­(ıÚÂ¼ç—åÃF½ÿèoõ ´^<Õxìƒ‚oD6<ÌæÂÁõJV­R¡ró¦éÈÉòšJ‹]ÊÉÏ*¶ì2aşŞŸ¡oü©QCH¦pöô—P¿Ã¦?øD«ã8zwÔká”Á–F;aP·\åMÒfBÌcVF	6µº–´<UåbÅì6ÜìRë]¨8êehWT;vıVh¼}›[R5VVMü wù(n‡Ç€c¥¿Õ¿A&´f±dÔ£ÒÇ°B9ÌK7ùâ!¥\WÍ3¨|×eRç¢NŸ—ƒA³Ë ¶Ö¿OÑNs°'‰E–¨¢Ğú•¢®i‘.ºJâ !’€ŞëÇƒ?ø#@"ª¢Î„/œøÂØõmŞÛR«c{B×•›’ZüS4N}uHÕZDìPe×@,
5GùçádÏk6øå9g¯(%<HÅÒ(qõjCu÷İu$G(Ñİá×ºë
Mí=(ä~Ÿg,Ñ+Ï?Áø¶#2]„²ÍZ–Zó»&ákÉÇ#µÓB†Û¼æ€ß[ä#°ÔÓöI´p” éÑjNøZW9d"?Ãš«ÈÇø±'É‘~ùD¯ó\¿`ƒ¹f¬†@KïÎª§$Rèì[¹ÎsY 'XFóôĞ—¿´v×j*ùAÎÏâD§ÇHÉjVÉèˆGP¯F}¸üí´V³>bæ~Ô[—^e<M¸ÿÙÍƒ9—ÊÚº}P2	ÃoÔ?×VøØ‡¶9JõsÒò¬ææ1ÈÖaÙGÓÃêù¹í•,œtèe;·°$úÂ $Õ¾¼öÛ_|‘ …     J¶¯Åiã ’°€ğìSj'±Ägû    YZ