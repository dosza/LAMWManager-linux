#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1144479959"
MD5="15300ed4cb797267c39ce7baa54ae73b"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21238"
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
	echo Uncompressed size: 132 KB
	echo Compression: gzip
	echo Date of packaging: Wed Nov 27 20:16:57 -03 2019
	echo Built with Makeself version 2.4.0 on 
	echo Build command was: "/usr/bin/makeself \\
    \"--quiet\" \\
    \"--gzip\" \\
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
	echo COMPRESS=gzip
	echo filesizes=\"$filesizes\"
	echo CRCsum=\"$CRCsum\"
	echo MD5sum=\"$MD5\"
	echo OLDUSIZE=132
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | UnTAR t
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | tar "$arg1" - "$@"
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
	MS_Printf "About to extract 132 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 132; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (132 KB)" >&2
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
    if MS_dd_Progress "$0" $offset $s | eval "gzip -cd" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
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
‹ éß]ì<ívÛ6²ù+>J©'qZŠ’ã8­]v¯"ËÛÒ•ä$İ$G‡!™1Er	R¶ëõ¾Ëûc`!/vg ~€e;i“İ»×úa‰À`0Ì7@×õ_üÓ€Ï³§Oñ»ùìiCşN>šOn?ÛÆöæƒF³±ùdóyúà+|"š!,Óu/o€»­ÿÿè§®;æâ|¼0]sNƒÉşo=ÙzZØÿÍíÍÆÒ¸ßÿ/ş©~£OlWŸ˜ìT©j_úSUª'®½¤³-Ó¢dF-˜ŸGfè‘ƒÀcÌ#ZÎÂÄl(Õ¶ŒîáÔ¦î”’¶·ğ#èRª¯‘çîFıIı‰Rİƒ;¤ÙĞ›OõÍFóGh¡lØ~ˆP£SJTYÚUb3â›AH¼	¡wê¶^Ãô¨NF§ &Ğà “œ¦ïÓ€Ì¼€¨8†ëf» JNª_…“
½ğ= }¯óüäÀh$­ÁÁĞPkÕ¤3>:Œ»ÇÃQëğĞX!YĞ\o÷CMÛO†qÿeçM§ÍÕ9uãQoÜyÓeÍm˜eü¼5|a¨(W)
„£“! +Õ
ÔÛ†^pYä;ls@{FŞö­Ö½§×ŠkQÉû]Ü9W©”“Ã`~‡Ñ5µÆº«Üó·9;ùøš(3[YÏâZnp	á
©a. ò­™z‹…çjì”ò­QPŒÂ7Ìİ	l‹2šFtáïÛe6®ˆRIx¥‡_ÏC×§;^!«H°X²«º†	Û§tzF cö} ÄE–Gt1ÍQ8À	£A—¡(P*S3$:§ú<ğ"Ÿü•Ìê‹añoíg¢[t©»‘ãÄT×şD¾1H#ÙMXLeUìšJEPÇçŞwÌ9ãÓºô¼$ ³ñùM@áç¾íZFmvxzê¡n¨	-j-QË)*'(¦™µq«]á—®§hõkRğ°˜„eñ`‡0c6ü«'”7]YÆwŞA2Ÿ¦(s>ujíñe2œAš™&TVÕ°–ş&Ú…šÎ6ˆÜ¼ÎQ|»YtfFN¸¡ H+ÛaŞ©ÙDÂ§–(eíqªT²Î×ş´vÖ¾çØ /íPÌÏgvÈçôÏèê.É^wØ?lıjÔâäMëdô¢7è -ûM>Ÿ>ÁURËY¶"{¹0ùe¨G»Kè…’z½®îÔ´R¿N\EäNÑ	!hqı¸b¾ÒXJQG¸H®QR¥’IB"™šˆ•¸)–ÍMa%İVŞ»0m7¥TÁ'NV—¡</,¸O¥’ib,°j,Ğù>‰:5Qæ<Dß*Ì`2;£ å„+²R‘M ,€“Ëá[Q“6–<¸ÿ¬ÿÁ‡¶;'CˆƒCjÕÃ‹ğÄÿÛ[[kó¿ÍÍg…øÿÉ³í­ûøÿk|^xçh“"Fs6iG©4IÏÏÇ´9ĞdåW”ÊÈ#qüÈ‡~ÏÆ.¦kÁøJ>µ"ß‚à_%à¥Ğ÷ŠùÕô¿
¿ ÷oÉÿ›››[ıßj6îõÿ?3ÿ¯VÉèEwHö»‡ßµõZ£.Fl¿’vïx¿{p2èì‘Ée>J‚‘^Dæ%·1x/
!Ì±y\~O&ğlºIBì…gÙ3rf7¡ÄñXXÏ—Vó{ß˜ˆêd¥Cùõ r•ª<$ğ‰¦‰Ñuì…a!£€ÉäÎuaQF1ƒy„Ä32¼P tM'FÆ :¦³r†>ÛÑõdXİöô¯STP²úœÕ¼ÓŞiÏ±rdù…oºŒG´§fÂÆ«(3;`°9ÓiÄ3
œ©“wÁaØ¼7}^gÑ”¼Õ»{«ü5í?/9ü›Õÿ›Ííûúÿ×Üÿ)^µId;êìô+Æÿ°Ù[+şóÙ½ÿ¿¯ÿfı¿©o>YWÿ/
úÏ rAÂÔsCRÂ‘A4âÛäß™S—<ì „(¶~
Zƒ£å3¢“VkĞ~±½¥‘–km}%Ç®T-ÒihBŒ‚;ğñ<bydæOã4Î´Lâz¤ß&Xo4±,·üø÷À6—6åÅJs1±±à¥ğ i¿ßÆºsE©8Ş÷Ğfáx0jÒJ°ÍXDë.7°<Ì°ŸÂëyaõ±z2‰Ü0"Íêêc L+˜Xş»ô|q€±2^vİİåÃm7º GC‘æwI™9URršOêz#çdp8†…j‘±¥[Ÿ";ˆbœºÌ±I.ê¡9gz@
ˆÇOÆqC•0–ña÷ù¸ß½0T=bîØÈ¡ªX{ÿ CˆÆI«Ogó"ÊAç°ÓvõÆ‰_uÃnïØˆ—x'²ôš4RÍ¸(¶ş@.mİiI[7.	z±;=I–qñÃö4ÍAAÑæn´²®´À_åâ CPš¹ò¢fXéñâ«Ã¹)*Ã‚?¸èRò:ö=ñ&=7ÃÿÂ €Ã¢K2$Z øŒ0{1ùøOÇz|î
Á“-Èã=3›Ç%»yñ«ƒ?]’r	¿×±W,à3¦Š×ÆÿJº+a:z‰êÒyÓ³s~jOO‘Û‹3PMÆ¶WÊÕZnJ¢ª«g'å˜‹ÕÖMu·¹î¶D‡ëEz¥Ê3Şô<{2.ªïÒ
	!?=SVáğ	PÀÉât£ÁÉñK’òÂbµHV´ÍzC›€kPS°ñ*\íj¥íÛwÚãëêø(&ûs·™nvOŞŒ_ô:\0Ø©	Ñ), æá«ãQëàšÇ’¯ëò^ÕAëóßÔ’Õ¥‚X:}*—W«½.Á†G±\—âƒPˆ¨ŠƒÖ­4åIÎCmuHhì!â!}Â*ëG4+/& B1ááŠò›Úç´‚…8å=5İ9ÍÎíW*v‹”@JÖ]©`mƒLÁÂ£÷8–“ù¤¶LÚı“ñ¨58èŒ,`¯?2TÍB\@bçP%½aÚ/"*Òô†CØöêÕ³ÑÚ³WûıWOT’_ĞÙï¾1pg*‚U¾Ü˜\)”IÜ’ªH%»“ ‰cïdĞîJ^äÀš!z­(Øhü$!~³ı„%j¿/d%İ{ßŸ^lsYvÎm8\¼Á¦½è]ï›€‹t‚ÀvÈ> eÒşk²úÔ®{ƒ£ÖáµJ„Õ²!àŠ­RÉK_MMk¥Ú¯bhNSûíb9[UIÖ—±H>³¯€¼¬ƒË™Õê¾t@+Ø Âu¨$`—u¡LO··Jõá.†¬d»¥İ¾ƒ˜|şÉÏkÇ‹ıi/£î&Z{?ãòT4)IÆ£ÇÍKÉÄ
7åVf|i›ğ©\ª~Úö!É·l."Gr²ç‚æåÖho#üa›ÈC²‰¨ k·°3‡ilñÜóÂa˜>W¶ä Ãö<
R‰ÛÛR›tÕeÿ°u0Şï¡Ñlïzİ½q,G…;2NaÄ“57[¢ú5¨á‰³K¨I\oÿrrWÌIéËy[SX•/$ÄJìêgÙ¸RR“¾9=3çTxÜ½Î~ëäpß(µí—IÂn»½à—^’0Ô®`ø¶ÆûŞ_òZseÂáû*û¿}ı—_3bâ&Ó¨eƒ+ûÃÊÀ7×·¶WëÿO¡í¾şûÿ·ş»ÀÒ¯f:ó¬ÿ’ô¸Ÿ7–HüëÁÊ|ÏeöÄ¡¼¶ËâAoîb£.¯—•ğºZ½şu¸]R,``øíĞÆ3ç0ˆ¦¡TãJ–ÉïZÒ%u<Ÿ´£àA¯7cæ¿Á@¼–¸„áŞK9¸Xœf¢ù9 îøèt8¿Ÿ‰—EÔROâ¡Ì«LkÓ@oM®ƒÒê{wÙÆ{”³yF	Â)¹y~\I¢’ŸùöùºCêš 6­½ç¡wbÑ%ç&!~`»áŒ<<ş:uCØDı´F£Á•m½¢®å×ĞüÓ«Îñ^oğ3ôõö:†ÚØŞŞ†‡ƒAï¤o¨¾Í¯úÎ}HÈ_!d£Tã#¼ãD(~–ş´©Å”ÖyÒÀh°Äk¸H^Æâi1«r¡XÚ4ƒ¿DöÒCNÅüã?äºçc’• ä¦¨¤*‹Ÿ\‘3Ş|õh+G}3<5Ö,5/U¹œT„.‰E±‡<€•Ï€lQ5NWcØú1hšñiR«İ}X;‰5B•Û A€Z4¥)Jòç)âé•ü€Øo×#ãİ¤æÄÖâî}§–*­îZgºï˜!˜«Óch­:™,^ÇmÒ cÂÍ!ü¶œ:óxCÜ¸WÀz¹0ä;z9Q[õu? h„B]t‹*C\«TjûQ~kàÏRy=Äxˆåœ†?y„şø3Æ¡óPì(]w_-üŞP”¬^EÛBRÍÂâ`D’a*ÆuãĞv©íâEæLÎ$!zÛxÏ­D¼ğ”+îFIÏ@jrf}Íìˆ‚LMp±BsAqaÃğÜ5~03=¶ÄÁC’×Bâ7®¦$ô©D•¨S	I‹õqµºeY `}Ğ9zıÀCçÇMˆX€/ZâcÃ¢åÆ $˜*òb“¨ÅÌhñ€T‰>ãaRåµ]ü»S;´ö;9ˆÜCàW×›BLò—ˆ>wL÷w"yg@"%@½ûA<àE$`¨¬î¶Z“Y JÏéRâwY
Kç»-íu®W¼ºBŠy~ò¶Jì‘N£&?û™µûG#qÓYË‘Ü‚£lwdBĞ h©Ayø™‹û}#näKäŒ\FS)laB^]è€å˜	ºæ@ØjâË@#è!]î8ÅsìI¡˜0ŠqÿŸ¹‹À€|ƒ3zÅÅ(Õ^–æƒ™ôG,2Û# ªàš–ŞÔ‹HşR#y4|+3Š¨döÎ]´'ôÄÑ¨ç:—ñõm1$ÒW-T beÅ wsîÆOT§Æ¢<…ìB#"¬©ÄcÇü-vÏ‚°äÜşÍbo'VÛİ‹nN†ø’ÇóÃ0ÆI!e-éT1Îœ5“¦)Õı²ŞTÏË:ãµ¬éåDŠÊ°z+
ƒ!<çåğôÇhq…nB^‚'$"ITw7ğ½$€‚<åÑ#ÛhìÚ?Õ®ªsŞ>~½k÷İ0ıÄ¡Aè%ƒÙï¯å ‹7JB¸“ı$Ú`ul\q±§XÖ:ìoäÎ¹D¦ï(¼1zó®h”\ú›ØYräöÉ¥ªD¹ƒ7%¶bR®2@iÈ©â’ĞËôt!=È+kå§'j×y;¸§ª(×b´S,İ¦ıäÜÎ˜oNiÌÜ×½ÁË!„Ã.®Çp´²¹bÖ™˜1é?Î÷ƒ9{ç€—whÎrqœ½Ã½±”µµBƒ˜øx”­Xzà1Æ´?ÿÌA0ôõz‡Ãj¥‰ïIg¤Òï”/ƒÔ¤My(l„´1²ÑÈ!ŠÅd<<é÷{ƒ‘qƒ(©b'¹ljhwjğk:0"|"¤!S±0Ÿ{÷ÄJ_¬‹%LMï*÷Fİı_ÇC7Å‚o
WŠ>BÄŞ¹7È—èÌ„‹ì2ñzç®—­¬ïrsövnçEjÃãŒø÷,'g/ÅUóè_±¸w.ùl6 :&Ù²0›\P7"5csèñwò ­Xr¹Á•è¦ï;é{iXò|AA®÷ûC9ˆRNiğ=¾ìB”Y¾”s×‰…Sº#Å{Au_ÔXiİåÎ£Å¼9»mQvz>°3şvO4“¾<ò^ä.ê±¹ F¶%jjêíi±‹ğÕÎæŞ@Eî¦i Á3¸ÔDF¥ñÄ¤ÜÇóÉ3TY”Ãk0¸Œ-'%¨;E—•‡ƒ‰`õº]ŒGQAÄÆ^€]ù¸¶k:ÆÌM—>5ZÙ¾Ålhƒ¤Ìyì`HuÀ]˜mwBÎ!ä£—»']àµ=.î
»kŠü×GmÇd¬Èî#ØNNVH/BıBwwùS¼0`¬÷dXÿD¡¼Ïv±Ò!ÈÊ`s¾% ¥ˆ„H•6byã,ß3õ,
“:æ¥XåKz	¶Æb†¨-ïöÅ:Cû¥ñ#8¬]Áİ<“ŞB¶ìC¦y¹³óF{¹×Ña)KÚ¹)ïæ}¶ÿ=1äã¯L'¢F˜Æßhân­†oùµÚ‡¯I‰NœáÛJ¶Şm:Ç'ãî¨s”$ü¥:…yî)„ìä»R6ºıÒ˜}âñ^gørÔëóótÒáMmSTï:Kß‹:¥_Ÿ»Ş‚ò»¥¦r­³KÒ…Æ´yd[µgâ¡…À*Ø¥ä…A_?NMJ[¦NÂf§›‹êç“,Qœ-ñÙá—‰åGBî€"³9ı	ö7™¼ãŞ†×/!g©;èwy¢”Æ~ßHT€Q–5yˆ>À¢%J¦´}…âÄ^ŠÒ=Ççİ­¡Şî’ÕQ4”©?ËŸ
ÁäÚ>¢Z%Gö2ËR€²€¨Ü«åaVILX	²„aÌ¥™D®Ìx”]‹ı°\èØ©Õ®zıÎñ/ıÆÅók„ûÁ:ÓÌ…1)ù´Aö“¶ÕÜüÜA©jÒšÅioÿrÀ*ô€>Né„ÁL÷”ü—,IÆ›n(Pòä ­ŠT²ö«äç·:üz˜“4•ØXÄÚ…¯Ÿp`)ä§dcƒTÉ¡ùñ(q€äÿO% ÙÜ¹¶v•§¾Áf«.D€	hÉÙ®œ¸â-Aş][?D™Dğ‚ï?¢IÈ1=ïg%Œ9–IGŞëTcÖf|ğ ÿÿ…zÌŒ[‹(IÉ?2MB+ö9\Z
¸Á¼/åÔÇÆÇØŸWa†yV€	Ÿƒ/ª%B u‰ÛXÉKûâüÀêò‚ÀµµÀ¼-íğÃ‘F³™‡piîK8¤¡±'Òa|HÅÁ³Ôqå$» d¿²s¾|ê$š'ùªñTZÍY¸÷ß¹SÜU'
]pqzøğ“«ÉPu¥Œ)ş=P<C!üL…÷¡to GÔ5Wk…Î”Z<¹xø¡3y‡ï*¯ÍºĞ:6ÖAÁZæTR-~ÖÆáD-a*ùr3‚Ü%á\à´nDbÕ¸ãQ“ëä«„IæM¼rûRÖ"ËîÈ*•Õ¤£
®nôëâRü‡¨%Ì©a|¶òOµP>›1L¸õ7½Î¢Ir÷¿í}[wÛF¶æy%~EdG’Ç$EJ¾D2İ-[´£n‹”’t[Y\	ÉˆI‚ %+ç¿ÌÓYó0/İkÎ<&löŞuAP )EvçÌkÙ"ºîºíÚ—o£¾ê')NØVe5ñ‚!«6ìé×ÿ”eªQˆ’màq~û?ÃæúÕ¼ótµµÒ˜Ñ¤Tò¥¹ƒãJ&ÔáeKúí²+ïçÀ#=rJµRñÎV
zTöAxlª
ñBà¿FZ«”Mz
pIé‰Ì®ƒä*»©Q7rÅUz[}=†E×9úeBïIê…½1ÖpCG“…ò_‰d«ÕËax{ZÌÔào¯hÌigŸ•©"`ß+ßuO¶¨®à¶ƒioWWápáŒ…[Ï3ÕnaŸl9SªìÌÊjëFµ:£óA•9i®›«Š\0IÅÚ(£»¥şÎ)©n¬ÔÏŞbÕg?Ö+¹DórbC¬9•åü+Ôn	£ÕWÜun(›1P•‡
iDéêsN(gTMÔÑˆˆB[x0z5²7ĞT-"İŒdÆÚF­!Î	8À5=ˆÖšT²ÍR6’ó‘z2‹”^Õè"ŸÈàÓÂ´æá¦‹#9ıÙ¤ßKFI$Ò5ÃóŸ`¯†Ó¢?ğ/ÃÿG,Á|ø”ÄßWq?¬%ƒş}\\¤¿¦ñ¯—Í`ÜÇ¯°s£VĞärÒğÓ5os}?ÿÿ§È¿QŠÓ‡h’ùY‹âŸø#´ßĞ¥Mûš¦QÅÁÒŠí«J2yÕ“÷¼„¨/ZÆ\N†°`.k“„ÿ@Sñ#òÎ{WıØ£ï¾ìö;ì£ü;Á²èÚ?NxŠÃ±HA8,ïı¡öUT:zï=Ùˆ2ğåkü+üõú
*
e5aÎŠo?BßäËi¢¾ˆâ'Cè	ì\×Mü6øú;LGâÍşaXğ.ë¼û“$œˆ?²Ø¯]ŒF4)p¦D1®î«ô›HšL4ŠIñh§©…äÅù¤}YRÂ_ûçÁ`HD$7Fcás<·ôR·åf7‰I³Â(F]ú¼”¿"§Yz°ÍèL¥ÅÈ…ÄÀ¾”'µÏàŒÜşmÖq÷/¶!ÈæÕM$(ë¼œ+õ9†gònpfš#à]T:+ŸÕ	DTÂîÔïTß%]Éª›µÆÔø…»#ñŸ­õ¢üÒm*Xxfª[Ì*äSÖ¤W O…Ãä&P©“^3XzB§2º‚syˆÈp ø‰?Ğgu=.HÛ>!n^ åp`¦„ÓŞ×wıq –çW §Í>·Û fk×RÅ¿‹Û(®2G•*Û›®'g Rl$’1n±Ëïé…˜mX¬’¬äÅğõ´)5!ˆÖÊ]DŸÛóÄDû&ó‘İkY%Mİ!)š)d(–çøòó¼Ğ Æ­|´¤ÆÇ` yò[4½XpÑ¨N’¸å÷è¦·>8±fTÙtîR\äNÇ:"§P+ÃÅ_X 1ëÿjU…f"I Ø\5îˆĞĞ„ˆ;ü¼èŠçûøXÓ;Àûao­Y×
ó¼˜¸,µçÎŸñÁ×*)ò}<#Ğ
í£{a\Š›!¥Óä|:pk3,?P#³˜‚Ç³·…Ó‹éW~‘²9¿·"´Á·=€}Æ:Øqænn¼¥¼¼ÈÂtæËüÁµ@Êáï<¯<Hï8€£`?Ùô‡f1·A,£°„¹,ƒ9”sÉÜ¶ŸâĞ°Í óHá	ŠÓO$É½È%¦vP±³Š)ñC‚¡ÑÑ¯3¹óuÛ''{‡oºÅ)'çb}¿ ¼x2şÄ3\z,»qŞ™ÇÑ­H	*§5øãÄ–İ)åS­Ò9[É¾`¿0äîİ¸~V¯ä¡bêõK¼ÿ–‡q>ë¶½DrÜß†öŞÊíÈîudq:Êû™.G†Ç‘t8šíot?îFYo#ø=÷}:ŸêîÊ<ß »åä>BwÌ+|…œÏä¥Ü2¨Ù¤ê#e»‚ıÎ‘‚¶Ì«Y¶¶g~§ÿëM ÇğK¿®é&)·v»›§˜ÅEìŞ=Äw£µ¡™I†^çæ…¦]ÌjÎÛËÓOšhg˜GëÌ"Áíb9K¹SÃÁ¢u¿t÷~Ì¬üŞÌ)İlûÇüIùI—Ø0‹ç®Ù1+Ì‰S|û³¿ºµUÄÜé¨@cø};¡$ÏX~†ˆä€ápÄ½,Gr’Úz"Ì±*x9šæT^\Åe¬6ÆZ9 Ç7[“pµ~pŸï]ãõcò²«Dk~×š‚W*›>{2Ï‰Du£ZŸ]&¤ŠÜßÅçÎßÒ‚åÑµUIßb5eŠj5(åæŠV/à¯V®­d^P#W @Q1+ÆŞ^ €)'¦¸H¸$èYLÇÃ|¾”~+ú¸–VøC&û–Şb(Ñ ä9J÷£JH×Œ@´OHäİ5ù»d£¦P	È–NşÚŞ–QI|ß™Wš ´½4ú†ø ¢#cŸ¾TdLëË_~ü´bµ*X…â3V™nò\œ7´1‚IxÍåq9[Yi­ï¯¶}åùŸÑâXú¨¹Úº7€~8€M¦å¼®>sÿü‚zùœ/Dş£ô¼=¾
¢pŒ&øG~Ó8ŸïóÚR¼:n1~æÖß…#¿N07uaœ&Å¿úWHøÂe	"‘oì|UVÑ•f~^·´‘^=¯‹¾è–nY‰­Ñjâå§‡¼`.z^À¸x1ÛbsÒÀàÛZG–ò¹u³ª0mâÉŠpÕÊªô,ì¢º.†sB;ŸqÛ'(İ5ü…Mg}v&vğ¬²
ãò­¹¥5Få”ÊÙf
®¬ò5ó`\Òêp™*`£¸€‚Cƒš°yÛXğc],¬ü˜û#sŠ1Öñ”a#W
'ı¶“´‹g|®¯hpœ4N©)ëÅkè£69‡Å³`âMJŒFö©i¶ ˆÒ%÷—ü`Û bNşx~+8‚èï&9MÒÏEùæ€òŸ…òÈÊÖ¬!g¿dü¿ÆFs³‘‹ÿÕXÆÿXâ¿ÍÃ»JñßÖkÿÍ‚şf„ùs$‹íö€íñ0`cæÁ¹àÒy°Ú(ÔÜù†>á¥Â{ğåƒrYZA¢š/ƒñæ”ßì½ÜÙgßítöĞ©½Ë«}Ã]>e”êïÚİv«²ræ¿mlo4G+*døÁN§½Ä_­Ã»ô]÷ô%ÄßììâëMõø°ı¦³w"²4ÒäHVUcy×3Ê¤d›FÂ¿Ÿî«6ÓçiV4ïŸôö^}ÛEÖÉ­_yÜrc0y‰Gª×Ò§Şå‹q›¯ú^ÿO/ñ
S3ÎgUV/"tü\gÍ‰ßwÉĞÀb¡zŞ0€;SìĞ_Æ£R·V~<«ÂÍ©ÜĞ¼óØ˜œ9e´ÌG"À690öQ}OnwVØï?Bµó€ˆ0Ó#ÄdNy:õ§¨&¦)»aÓ oã1³Ud.İ€c¥qæ²AèÇš?ø—}õ¼™àv(¿4å”«$9xx1yÄĞ*”=DÜAëºÒÀn“(İdàA“Ó»³Òj¢²XŞè)™Fc8×…£úE8X±ÃGôÓÉµÉC‘»6
·VÛ+š™$s+ÍüR8<Úf§(4+Í	+kFÂPÄåEV‹uÁí9ä]}%y-Å§ŸWxî#ÁË^t3NJ «üM”¤H„>PıÍÊ4·LZÂ»ikµ²ÚEîùç
PEÅ1\ƒ¹.^qIt‚ÙB…Ò7x‚¼GkuÍ6¿ú*CD˜ŠÊâsOµ–"¶«hAò©Óë’ZUZù_ëõ³z}ZÓ¡îE
¼íãElJ<rM©ÌùC¡ĞÃnó­Wıy§ú÷õê×Û?®™HZ@È…ia.ıÌN`NGˆÀG3Ûª´²uÅí#¤AÙNŠtÂ¥¹ƒğÎ$‹-²²éïïœ´w{;ÎÎß°T12”*œìæ k»¡d©ØÓ™*é¤u´*¹GÀŒCŸ
›ÃÍá¹Ütn2aÓ$\9 ^y78IåLä½À¹°F¡ˆ*%ïüœNi´©¤ßy7Ò’ôÉ‘ÓR§ªŒrfaQKq²à^†a¼ücTªSÆ¤ô•€ÅĞ¤/ÆMÿü=İ}Šœ	¥Ò¢dhËA×¦sk#=áö„uµ*mõ[­`XQéS~0áºoU6ÔSÑ3 ©X´`.™Ôr±bê¥¨„XÆøØ6R†|çá“BdƒÒ“È½^=„ƒ†ñúh~dÒ5F »£ßTlb ‹I?É‚Ïq“£sêõ½ìpœ ›—øMcƒ øøŒÃIÀıJª“Š4Xx›¦3%ª‘Ûœ ?¯€ou¦d–¿Ñ­KÄ|åå,ƒáŸåüéÜÛ
@òÚ(š-0c7ÍÊ”ËeZÎiu	Ø¥ógã;uß–m>Ê\é‰Ó‚,0.wT8µÒE]¡jïÃÓæqF2›Î(aÖµÛMËTûûFFÙ31EƒôsGNòB·›kr«Í²¢2‘#5´Êº:ú¾( µñn4¸å|ûİD°Â”Şê† ³iï[zÿ‡ò¶¥İÎ¹V£U|
Äê„a"	„Ãîb ¶ĞkÄ-¡±9=7‘FNÖ¥P7ñv6M<¨oâCÖ©a™‰È*âfuŸÜ¯@¡U¢é˜|1²9úŒ‚+òK?>·áºë»V«ázñUÈ…ÿÓ‰v¡w„Ì„Nî8øX§wğK?ÑVG#¦¦‚óÜÄÄºğØåÙP/\•qI¥9{ŸU«0p>ïëˆ•€oYE¥
¢PU¶¤…lD;'iMãÆ~B 5d ótó€D7Q2¢®åŞJÛùwÚ¼›EštPÖ8A˜AØávî!bëè<‰Â¾ÇaüˆÑÖsAÜbïÒÑô€™õÛÿÀ5z F‡œ ,#L<Ü¥^Nã›Ì>µˆ4éŒáØ6LÎñ&Hªk§ÄİŠñÁÛõåûQLWáëw8u.	sJ˜Îù±æó¯¬ìÿ}ŠBºĞ$Šó¥?UjØ3e‹=‚Š˜}Ø¾÷‚„â'TÜC¡TÂV5¶M¨PDÑ=¦VŸ‰×‡“¸î(1!ìş‰ªˆ1“sµz“^‡×ÕéØ›b‹tEğkÙÄ=X:¡z|¨Œåt©l¸
Æ)­N| RäÇj âìÂÑÛ^ù¨$Z8N	Vq1p‹ô·tò¨<ÄåYÄöúg¾¹®ë+znní'öœX²²û÷³ğT“È$ı	£òGŸ–Áƒ¾Hü1'î?öûñ?mfãÿl<nn,õ?ËøïwÿşØÿÇÕgù‚~^ÉXïF(wQ
ø3Ğ‚åhæ'_(²{yùh çº9ûÎ'¬DGn·qsˆš_0ğ{h&Ô²c§~«i>ÒKG}Kn•â:qóÈÕeê*2~8ìh8`Â¬‰I6‚<kleU£	“¹½Ihhô!åğĞ9„N®Y'zä:Wùh)N€Êe;›–cª	´>èIxt‘D)OBAvwíD\GnW`MÌ²İÒªrş¶z}Ô~‹Gn®”,HX®Š˜Ê¬YLË¿WüÒÔáÿæ2j0/aäF)TéJ*›ÊsHZm1qM•¢xAø\#ºš¾º‡Rš{vÉÏÈFK–Å±Il2‰Ìùf¯zçğdn½˜fv¥"E^æ¬ °†İÄK¦1ç°É{8İØn;Şº©²Dê‡ÿON»¤™SòdÂ°4C¿‘¾:<ê½9İã+^¼‘âëmyÓ4‚aiV <ğUò”9’%^½häıìñêCb¾ßşã·ÿ«4Ï# q˜ºÕñËMÂ“Šx(’Vk•UVQ«Íªph¬±5}·Êsë/ò€S8u…I†2·
tD«"hÕŒªôéË>GúTÕL$W†#±YËTÑd‚II„¸ôMş–Ò¸’-@&ÃŠ¥ˆk™W|*MmHFªh)1ñ«w~ÿ}›ÄrPM4Î¤¸oê÷jN—˜qóïı“vçpçdï»¶Š‹¦v>ñ·$™WX^Ïbì¦Qg®µ
«4æ¾Ö½uDûÂ¡Út‚%ë\…¥hMqÇÒVòòE“ğb¿¯ibIj(Æo£¶^[7‰ÁæPã°İŞíãîÖÆ“©ÕHƒ€Ø®xĞ÷õúÑÄÿu÷[&:ËxïÅÓg:	f´šI¸İgUø?N:o·Ò·+öñÌŠ»¤ñ{/‚cürKİ,›ûLZ7Å¼…şà›ÆtØóÆµ™¨Í„
nUäƒı“®¤÷@=åŒ¦ŒH''¹«¡!ÇRkhm“j?òòroç°÷& ‚éuÑ¤Ô-fÌ¬­ÔÈGVÏa?Å>ğ‡.smµIeí ˆ-'ÕâÕèsxt‹|<=³˜&üóÚ€& âš÷ø×Ş ß¡jjx—–Õ{(DOÇß|­×{G¾CDßÓ±zÎıµ1®Ãyù¦ÍØxŒÅ^À±ê·ÿğB96™©+[›ú»…ÀÍ}Q½;%0úŞ0‰³p´âpFÕêd]újy|]}‡
›Ÿ°ÑxH§XĞ±ŸüµÓ~ÆHÎ~áM‡‰ƒ€Ï¼x—?ùB”ê¼ä]G	ÕŞ|ûß×·ˆÈ_SRH2cJ1¹ùe%EÅ†³R•F¨Ü"[ ¨]pÀ¥)*œ«f5×ÚÓ9Œ•ºÂ(Fqk×‰h>ljYî@Ô:8Z• “Ÿ»I8™à6#Œ¶¸BØ;¥]´Â
†o:İùn‡ût¹•4™ª] @f(€·‹aìQ¨MM¬¨R4›ªmkÖLj”LYr,;âÇ®ºC3Ä™˜S<–U2š´Vêğ?.k¼—ÑaÖMñ—é^½¿óıÁ¦à)³—êo0CÄš™ìPåC¦¦<g²t‘ifMğjHNdï™Ä€)R8"ácæçñ¿ûC[’Ì= yvş5:“·-”¤¤mâ'EšJŞ?ÄU7#4¯ò,Á¹a'QTËÖ.~ù ß?¾ƒL²z%ØÖj¶öXy»ß©9Ø~Í0Zj'Í2/™m4{:;èœ­i–;E“Í‡bË²ñ;mkuTö÷^våıˆP{ßpÿã”²Ä$À· .°XªANÂAˆ¨ÿ#?‰Â˜¼êùOà3
´C}m˜½U1øG uM]¾ØN»ísMém©A*sã õ&ÅJFƒªl–ÓÎ~K7·*<†¯ÜE3ÅÍÒø*µ%²ƒª…™ÑGÄ†ı½WíÃn»Ôëì´ñÆ+Xµ:úş8¦]sö(
¡¬ZøKşèå¤Õ«64]æ°ÖƒÃ7íNïÕÁ®Vñ[XñmÂeúcË-hŒû»‹-êË}•lÉvfİsj•G Vı^á6­ÕøİFKÅåv+©/›˜‡ø”Ï÷VŠ¢m¾-ï9kùÆOt!Ê`”_t¹=1”4%/.(Â–Ñåû¸ÿ DšÙ£İªàşP&ìWÜV:íıöN·]¯<=C0¹k¯ÑÖÔ^A±ùAA9÷d–`P;ÅYJ)jut´´ Ùİ4M€ª*AeÖ™ÒÍÒÏ5KtgÑqf©÷¢k6¡¤(ş(¡J ÜøÒœå	ÿ=™í·”fü¶>
î¥¨ÎR†ÜáğÔôü +Shã•\¢Øx©şĞ–©x4w©jëLL
,l„Éìv€#;ü¶@.Áx„à/bÁ8‘~-ìK 1)hN¤(S‡œ<3*Ÿ;{òEŞ—yĞ›ö	×ô½F†Cô‰áÉkK»/\Ğ^´Vİş¸GWá}A†Y¼d¹ÃYyªxÕëñ0ÖŒ¬ÃaY8šfa^0„í7øœÅ³º9_DlÁhÍ§¦öéqFdû
bã`zC¢¥ãbÔ‡h2qD8…åW>ª÷šYMvæ->íùy¼Ğ´˜}Ç(sÈ‰§OŸ²jçª€Fºl-¬Ëh^&é¹m%Uñ*½[£nÓ*qc½ã–ıÎ89‰‚KS}Qÿd¯÷·iËQ+•pÓ‹-Éà®ŠÚ^Ô<nÈ	#5Y3+­-\k­°Z£Vµf¼øHl1Nè°RÏ¤±~ØÄşˆ	¥	C	c/DÃËxŠ-%Ó•
3v—é¨ ®
T§+gvŞì!O²sÜÛ;ÜmÿĞZge†&~„WR¢î®Wš‘qcì&¿ı3
B´Ú&ƒd35Áa`úy´-‰Âá+Æğ>É…Ø€“`ÑsU7ÈÙ	x¿W¢¹˜],İÌşÉŒ·&g¼Ò˜MvÍÎ+hÛN1=BÛ,¢5Y¹K6¨Ü|!ª^BZĞA0|çñ 0ìÁåØ6Ù*|{´EÓI²¦h(šô÷½cÁ7äƒ×ôéøç`b$VÄĞ‰˜yŸ¡£-7'åáî·‹ÍèŒ¤Ø2[Í¸ëf€±E”İL‚l,jÛ@ÍÕâ¬›º©Bq¥Ü¨õı ÅéÍñ4Ò÷º77`O¬3¤ÉÔ˜ckaÍ”l™Ÿ¦£É`°l©PõN±@1Íî,ÁCHÉŒ¨L”“í¾V¾<G¨ÕUÖİ{³wx»Òâ¾á1|l¼­)âêÍ$¹â´9ÁİUl˜2¾"=ãSm$Ú*±‚9ÌÊt[Tój³ºÉcá†+ÔH$ÿ‘@Ğsô)õº5×šµÇ®-‘‹a8ßÁ°v†—C¿”D ­ÃLcÒ»á§JO”ÇÑ	k0Ö’ü-·8Í¿i4"è³“ŠNÅ;wnü6Õ´4:lKú8›FÄş’}–²$ÚV‰Ät°ïÜùóù<@î•Ò¥áàÒ\}a5Øq»A`ïfÄŠõÔ·/©HÜp/Ìœiè7C ˜Åôæ•}äô¯½ y¤nc¨ê:sE·
ŠˆGØÔy0’ª¸LrDÎ!GDç l,œ1z7Å²˜n–cÇïRsª%´ŒÔÆJ­ÔÄi¾o·kßìÿûšquõ|4¤Û»&V€¶÷Dã{ø"t‹¸ú·€9k¯‘ï{Ó>q³Qì€8ÿïò—uõâåéŞ¾@˜-,Øÿ g\ç[¼øÓƒÚnz§8çØ%8|k.yŒšéy0¯
#-›—Ø‹ŞûI+H`Q/šÁ›¼ïòZ"Í¡–`öu‚e!¡m÷(.48¹¹Û»ÚlL{DfİXÏı‹LÇIÁ.4—fµ…'ÅÙ¨_)İb›V÷XŞ–7@İ#?Î*¶Ue«\*s¬|üVÆ™iå£uÙ!GçUË\ÜhfdHYÕæDL`°‹Jú¤äá~f¤q«N†~dh¿Àævnv
®I’ŠîY[Ô¦‰³Úx·ÔØJåfªş^%©¸g† ·ãO¼ ‚6Ã3å7XëñÍUí§®şKÛ&µµîrÜbÜ/8~©´'Uvz©é°Ác;CMp¼·ÒF¡{¿´ŞòØq^ÖÑxxC+Â¤	óÄ<äˆ|éåBY2¹æ8¢u!à½šş-è¶ª>e–/J„,QûY¶ŒY?İ³iŒ VÙ³ğÛ˜ë±¦úÜJ¿²j§°›só„J“1e9ğÌÎ`0 Åœ„LÆ|Ä£
˜ˆx¤Ì2.‹'Œ+†®‹ÊYé‹5¦›Oqó?Ğ‹è	ĞÏj€óuâEhŒc³îW¶¼+}ó²Êâßş)ï™ŞÂ(gôHD<;#OeÉ7k“ƒš'ü\ÈÒN³ú‚[ˆôßáï5VÖ
yË_ùC)¢‚ÄFA1LÄ±éò,,SDU.Ë¡ŒeIG^ŞXMmàQ°Y¬/±øu4c÷(§`ÖÔ¨´˜©‘¥ÅÖÃÉzµ®#Lø]gih
3şÑIŠ‚`ŞûGŒ3çƒŸ=1Åd½å\ w®`L+Çí)eÌîåÂkû#qÃã’bb`0 À=rğ@èïK˜[B(â(!A0 ÇH$® 1NÌ!e ù[AµRÜ§Ù.0˜Ê²2*Ö"Ò›oô_)S¥ø¦6¬Fğ‘Ağ,}¤ÿÛ?ó½…?ZdCší#/5…Ğ{şÈ âØG† Å…÷3lx‡'c7^“³=¶†vä“, ·Ñ[ï­g\¸Ò®.˜›•¡9ic8',Šn×–ÍL[nÙ˜My?UµkÕÏÄóÎ0sZµ³²±môG†û0W•ßÙ8™áB§^§X‹ù‰Î¯œ‰‡ÍÏNmãh¸Ñ§XœÜRqú~’vçgµ¾øÄM`ÅŠ$&Dº%YÓ«%§áÛ[ê¶Q‚™´§Ó±…’ØİfrMgP
¨Ë)h†ÒÒdOüWš´Tz‰ì5½Ø‘]À§İªJ ì]övÉî£( Œ´‘İÙ}™„§ÿÊ¡	$>â~x)YSkß£ë±‹.­|Ë‹ğl†Q§‡r£+ŠvÇæ1’f,»’L‰s][³]ZZ±JwcÂIÍìá…NÜs&úâ€üÎÿóœ r/øds­ôGà3L¶3mÅìfğÜ_‚•Ì2[§oP»_îÊ0§’«Äµ*EõCÉŞ³‚‰[%İfo/<Úîc³.8œgíßå¹¸(”ÒÁ[JêÌd¬ø
ëZ€Ug¦S}avG°¦õdjZd9jfF'»‡çsœf>Ñíâ~K3×²8}àkú8½Ä—?ÖMVG?è§ã¨ùØ£gàu'çşEÍ„wjÖ§İoò yzä²ë‚ñ°iø“Å›*Á Màu3µ=] 3Lo*/ãàxïÕŞIoçÕ	”Ñ;8ÚmÃ¼ìÁíÅg~¹Gj¬òop³ÂmD^¯Ø,%íò&5µsj\ŸEBVÏ}Ø‰9Ÿ7ˆp…ÄaZV2C)’#†DtäîµVÊ—ÛÈÆÆ7í6l§!ÙÔ£çŒœì9˜;é¸QıåF$â‘a6BÏQvW.ğvlÌB9#´IYHexQà¡±;;@£wä·xúád?²,qÖìŠ*ÚyçlÌ;l'†ˆ“ğXˆJgd™cÌ)8µ¬dîØ˜e^—.’ã0N^‰°„¹SÄv†|º#ş[`’P6ô?KüŸ§à¿á÷Í\üŸõÇKü·%şÛmñßŠâıô­(n|º'
ÅMœ)^gÍÆæbKš©]__×®‚+/äöd½vÕp—¨w1ìO•×V%øJQv8®B{ÃªŠäE_#ŸI•VÚÕ5¦Dı)"ØúW1?aï;:8î´÷ÿF‘<à%Š¨ğaïû£În÷-}}…ß‰SÆœ…)ªÚC W>ô]×ìoªp)Eó^ñ·êy“ ı@…)±š³.ùûGW”‘WÑx™ĞÖO¬ÕbÕ‡ìGÍTëÆi\¯Sı²Ø2¸.T«";‡&R`72®ƒ œÏª¯YI™ş|ñÕ[å¨Õo_Ï#ë™±ÿSï|X“Qü…ñ?›§›OrøŸ›Ëı¹ÿßÿsÃ†ÿyòÎÇ ¬éL_Ôz’'Ær¹ÀÅ_&ä[*"(Zã2ÊI\Ã‹AzI•HšÊk]Oı¼§!ö¼¾°‹ Š“ÌÄŠV7°9ì½F/õÃ]ò«$šã0	.nªˆ”¾æ(ñC‹‡É*j¯–’.ÀÜ¿By2İ%ÿ{*Æp×Å)q´fÁ]zÊ½¿³İ#¶sğr¯}xÒæƒåÈ[¯À’ÕÑïyº!™Å}¦‘•Ñí~Ø}ÓÛİ9ÙAßƒnKß»¥âårf!ÚK×±
\Z"™—ß·÷_!-0|3é÷ÉœÙV‰‚9'ÊîYr–‡×~Dª»Ş8ğ‡ìh+=ˆ<tJşÙ£”ÎšÃ[ÀEİãcªû,y(`×¾¦døà” ¢XãIm}“íŸts/e_pğLwxi}J¥C$É@ØëÎL’Ãİ–{9F„UùZ¸ÿ£&@CÒS5
eöÔzÕZ×³¨`ö‹”ğ-Šîp™Ïs¸~+“şŠÂ†¾G©€ÃúyEÑ"\­Fî[šb³ûíÉÑ1¬ËƒKdÊ¢*bˆÇk‹ñèøDkmâ’yúØOjı©W›^Œ`Ó¤èÉF£ùÌ±@§èÅm N¸E‘Y—RÉîêƒ{ 7ñãî$ÕÍ§_?án%Râ“úL¡ûËú¹z“ñ¨jEgçz®ÛµEÚu	NG+÷“hÜ‡gOzO6sm#ß˜»fV>Q³Š ¦Üê	ô¤Ö¨5\'ã¦3“¦]˜Íg®šªycöÌ™ÌË¼a:R[ÇMP$µ[e·VšO1Ù
ïÉ8—5§uGİY›UmÊÆt{–Í>s,ö§ºùéö,Ã|ÌÍ3á·Ô±~r›UYûvÆÜŞ¬£Èœ}f7›ÔÏÙ	³;W×9êC•/ªÕÏ@%’íÈöÓ(böË¬ß@A‚¬Ÿ€Ù£¤Ô‘Ò½á2HŞMÏicøi4ÁĞ3ŞLd&ŠówBTå§šßQF´LD3]oo·-SÍ€„GiTRŞWc!ŠÅš—…ÇMÎ'£D­•»şñiÇQø“ßOĞm¤¬ŠEÖÂñÄëûzàĞ” ƒF‹ó}9hööNÚFz;ŸU÷&¨«"ã„X+ª,íû$„ıK­ÚÂ6kÚ}ÌçBùØZá¯WÍ¡Ú ü%Iña»µæ‡}ºUe,í©ñPÕÄß­8š¯y:¿Däš7ÁÈÈCZGüQtéÇ›"\tü¸Î_Â"JªhH­âSRÖà^]ûğ³ëè¾æptÜ6kóJPFÉ>‘jœ˜®ÓiïìS©bï×ë©E¾7T…	oò”PrOe)JEÁù”OŠ9#F=¥“.ãE|è¢9‘ÁÃêâ$6€sÒÃÎ³'Ù×-W†pSm¸™³^?«Õ{ŸX™ï_¨çBTr3™„îi¥¶BŠ°Ş#ÃÏ3ø}‘MY0†+^‚Q¯|–êaRÇí£Qõj\»ˆ|âA!ÕESë‰w×³Í…ÏF°9p¼µşÅ¥Á=ß"y&°iJ£äí	è¼“4n
#KãASĞè=Ãk–’ÔHb‰8˜T~¡µg5ÊYrÓ¶8ajeç¨ÛíítÔuAç>V(Ô·¨FE<}‘ZyöêøTòOha}¤¸)éLD\u@WÎÁ7¯]ŒV°Ö£ÑÕSÏeòöxÜi¿Şû¡…÷Ù•5§¬5Ó[·pÛ8€ÖBí+hĞÁÖ¬Zå'6œS-ô—ª®6I#9õŞy.açL.&âÒÃ¢jÃÉ{@€g¸©rÍn•ÃåÚÎo¤‹i—°–y¬¹÷Õdñ3MÅÜ©ÁŸ³½ÜE¸(ŠP/ôëÕÆ‹şPMí{ïş‰	Œc¹Ó~Óş}·ÓÙÃİ£ë8ßwz[áâCŠbrc,sÚeˆõ|4p<{4ÜW8Z‚óFuà_¿w~™¼‡ÍJı‚‹Ç$øp>½Ğö½ 
›ò¬‘Ë°‘¾ıÄ‰üî%ïµ7—ïúUY—Ãi²‘~£ç®“ÂĞ¶Ü‘?"B‹§çW\€ÌFŞ{ŸñázC† ša:¼ˆÉ+çÜ½Á9»„­jàÁ.Öğ<m#eÆáÜ™‚Ş%¯g2!ä0áßë"}²CI¼‡ã*ö×…UÑ³ã
„MúíÛ§Ğ†Éné¢ä/¶à*™—v£Ÿ“=˜bßïìÁÍŞ±Á£ÅrXO…pÚÉ¶æy»xğ^ƒ¦!çş;”ëÿ;Â1Ş¾wT7k_×'‘S±úS)	òÄ¢a&måº§Ç8Ø7mhf§{/ÒbQöİºÈÏJ³›óº¨sMsÎì•/xhKîY²
ş¿U±’Fµ¿Ğ¤1Í©Qz^ªk šÎe[qû<òÆp_}?ø ;şr}¹ÂìB_ş®@NÌ_ÂåöUñ[ÍØ¾e,%î²ÒŠ?_ Yå·Ü|Û³ÁBV­d_íÃÎ×h»?…¸Â!wµİ¬m¢ŒpÍÜnN²©µûİdÓ¡§Ö%v<åTCDd04~mì'0×¹Aİ-½.Œ´şÔ\'ÍüõFƒ'›ğvuímÑ‰¼ğ€îalšÍj£Gùq.bå_Ò´ç­i¦­YÁİ½ú¯ø ‡Bæ á…°åÒXó|Äâ›qâ}Øâ*Óìá,	á_öYª»zë¶`ücê]OŠÏİö§·á$óŠWf>Å¨Íêí–T!¥	ÌzÓ*f~$2>©ÕĞ-{ ;?şõ?e-ù>ñfë&3…5æêèLÇ
R 1…:ï×Ì¯N3¿)ªï$d?MãD™öRµÒ"“­NêÓ²ÒI6Ë»ò‚!êÉ10°`kó[C¦A³)­áv\ÁP£,Ÿ›ÕÒ!+% !F£@_(®BÎš©¸8«Ğ	•Ósku~ëqÍ™†]ŒB…é0h|öƒÅg³#¾V¶2k%Û–[yÚÂ³o©åøÍQ÷DK-ŒºÔëÃÓƒ—íNv±ÆÚ6ÁÒÌµd»18+Ök'µ†¬u¢cã³qÚ—Ã0Á:Tİ¼ë¿ş'{y£@7pz‹ñâj×E¥ÁçÓ˜¬H&*:Å#£’ f
Ÿ&·#DHs‰Â3x ©ıë?ØŞ¦ÂPôCtÂ¼Ñ³Ó"D»¬T_îdÜ-{Çã\û_ÃßàËÚÿ66?ÍÛÿn<]Ú-í¿æØİÙ L›êw³ã¦ı±€á±&c²*ú"ö¾\%4¯p‹>İ'u4^‹Ög½üXøîOÙ]áá'Çá|«Ä-·e3lIİE2 lz8®ÆhC#²H#”÷¢­Â€ahîWı*uÍKX.ş:åqÕ?ê¦¸Ö‰ãè¡|)Lús0i™ £ÂÃ?'ì¨dŸHo^äÈ»ú=&U@€$4+¯3õ”äƒ¥R¹AO2:'HÚÔŸs<gÆÊôÔh9¤İÌâİÁ³ÇôL˜™Àï'ê·²§O	K©ÍõbÖVº§ğ†Qoà£Íó ­ÎÓ¿Íb7¹=«%"6½iQ«Õ˜™V8ğ²jte¾Ñ°EÉ"²É¡˜ÈMëuó)õáÑ=½„;}t·V+sÏDÍÃ9«²Å‚Ø$JËØŒX2N®|/b^]`£\‹ï¢Åî‹¼ãd°[›Òá.PLÜQQsïd<›¨›éä|ï÷È`U.îTZ££ã	(ŞtmäÛ\^œ²UTÈVEâ+hí'¿`÷ø¸¥cÈ¢>Õ'“ş‡'DÅ„
êå„<”jMƒÃ6ÕMy¾á 9³j|‘÷ÍÄ=af¬L6ÒHb“ÂÈ§°¿;Î˜¥û	Ã¯]oŠnQÁ'†-;ì%ÔŞN %œ}I	{4)YâÍ€v%¾¸¢·1v…PÄOè=xÍW¦ô¬+•ik'CqMwˆôBk¬S¼iQbNcİâıäg^0Igr‚™°ÇfWËS`…a¢Ø&`=¹Ã›	TŒŠÎĞGĞoñäÄ·Çø-ÊÉº j~â™€t©ÿÍN¡6ø•²¡kõ§ÒÑåbÖ=sbf‹)T‚³â@Ùzæ2/E>M8­=ŒDàıö¿;$pÀGäÖysâk3	-PCs *(“èÛ…“q<H0Ãûâ«¦BøÁ¢ğö˜ŞEÅÖ^”Õ­½S.ôèù—Q°ˆilĞèlÜ†³
aSU3Ï€;†WãióæÏ;ù›À.uP6Œw’[àÀ¦Ç¤$¬È¼§KÖï}äû‡AB•¾‰Å>°÷ƒ˜1âÌ³UEmÖ?æú²pøßÈˆ¸ ò6úˆ«¦J¥J9};6 ‡íÔï<ÛA6¿‡il*Ú°$Àëì.=Tm¿s'YzfK´‡œßú¶êß)6Qº^ºÛPÒğìÆgî‚¹Jš'ŸxƒTK%î¸WÌ‹±ÊC`¸…sÉıÜÀĞ"›—Cîg¨ÖY$òpŠC+§Ú¥Ú^4ĞÓƒß¥cZ bçZcaè°¦¡Ì¢	Ø@ÛÇ>{óû8ú
9é±ıÎ‡_~‘¿¦ŒkÓ¤•mg"¹nˆD\°gp}"Åc‘w0UG‘3âÆ²J“U6YåI6\ï™»Â‰ÀÑí{?î&Ú]•µ"½ˆD€Ó!É ¦c¼	'Ş˜BBˆÑƒp?rDDîÈíŠa P`M(•Š{º(ä”_š¾6"Ãö60®’6SM
õ€X"û“9uf¶ÁumÏ‡ë2iÜ ·,yGm™ææz÷"‰.QG±ŸšD™¨dë©bál=ÍâÅ˜í´5@ÃQÉî¥ÖÍ´p7µn§bÏnl[ Œ˜½ErËÅeAdÑ§Íl›bà•y'a:ÏH9c¬„Ì©È"sòÂ«’ 7‹`'dÑ´D°q?k/T'¸†éî4»õÌË vYpÏµ™föEt™F|m/—èŠ…·¹.ü¢BËª15mÖ‰ü]:i®>¨üéÏCoì_"„Ğ•7„6MPíå+G ¼W § %•oá+µõªÎŒ‚¤*%*ÄÜ5–ßcQ	Mû$Óğ¡¹+.o†E‚E<ĞxÅ\Yœİ–ˆõP®{}ç ÿ¯Õa?®Ö:æà¿à'£ÿi44ÿ=^ê¾Ôø °_M'µÑàËà?¬77šO3ãÿxãÉÿáËèÿL ƒ.½ã<Ÿ¼pJ¨-{î^XæFüîyŞZšÁ}rxQ%×·>ñ h‡‘JöØªrÏ’ºú5æ³>sñ3Y†Î}î±w‘‘ZÖ¡+¨¡ûBşx^÷^Ôsæ4Ïë÷ıI³X ˜Äîx¹Éfâi±óiÂ‘Çpå_¾¨VŸ×ÅW‰x–yÃšó¼äqÚÈK4äQ8b­­zè´Z- nä¿`ÎIÈ‚Y¦A[NI6µ³¬ Ÿ"	$>^Ì+SÙÉ’¥Ñ †C7Rå>FéE~ÂŸçu¨bF«Rj‰…%¤¾~ƒ ê;¢ñ†U‘ÌmZ¥•`I‹›Q=óz§ëŒ®¨WÔ#~W $´KRŞ@­$Îdká&Èâ«Uõø›*•R’W_“ÊÀ…ZPJÛŒl¥9húÂ'¾¤}‘Õg 6@Â>	biÓŒı›\›°ºœ[~nuşÃX~>ğüßÓÇKşï¿¾¨¿äøo¬o4²ö_°=-ù¿/2şg.ùtcCa¥1W;ùÆdÜ1ÍªØÎô’5¹ŒP…šğ—Îh™jDãKßujİoØáÎAÛ1M5ÏTÒ$ÌS–îŞáÑqw¯ë˜­9³¿=»xÉ5Egé'\ºágcæd€ól‰¬ix¹”&“qƒNß´…Y•lUµê¬zÆ»ü.2§Ü‘ñXGÏÉº—º´Ûmw_uö¨±ÁÚ¯.Ùìa0æÑƒ÷pŸ<Â±@äÊòäYëÖGÊè3¹X†äÓ0mª+§:«Jƒ Oèò†dß“;$5TĞ×ÉĞ‹	yüÇ5%Ôw2¤d¬¤’C‹t3x+)Í¶éÖó
â2ªŠŒ©IOõdÆaÚ|=Ï39 ë¯9«z%¾ÅéÓ%‚qu¼$›9Cåüå—·"ÁL6Ir˜ØÙ5â4ñ·Ù–Ï‘©¤§ÂT›º&´m‹Õb¡]]ÄB[Lk¾äØiÌg4B<Ã6PX
‰TğÆ7Œp[„¾7³DWyã¦NÇ	ób%Ê[ã­‡xo ‚-ëZ—¦F[¬)ÍÖŠ|Ô1xØuö¸é©ÚjèMÑk,J›‰Ê º‡IIµËĞ—õ‹\öØvşPX Gp/q†ğÕvzòÍQÇÉB³­èA/ì5şò.LFpiBh™5gÉAÿÅÿ÷‡Ì•¾2ö½?áßò¿Í<ÿ÷øicÉÿ}ùß+>ôŞPŸp|¿F!–ÀÜ'›°šCğÄ'*T%À0Dè,‡§á„&;ç¥…³‘ÀÂ!
†Á‹œ´OC·â[•Ü©C²nUe .‹àÃşO¸8/Ønx=†Ş %…œ[!O~DıbT`:ÄSt/fH!·€'¼&×‹ßY öäyˆÆI÷&Ì‰U/B´O×ÒMü1’0&îL³PÒ<Ãó:Êl©&7•·î(ÆÌVû¯]´Ä”èı1d”5õÂÇ“ò‡’3.Ôï¥ñÎM?¾ßÓîù¿a‰ÿ±±¹Œÿñ¯Ğÿuø<`èÛü`ŒğœBp’Êìš]ø^Bşp¸¬Ï§—Œğ"jsEyÀP†Wşèjh>yÄÈ5 HÏ(Wüaûûî–~*L‘M ƒL®ÒCX¥«+Î8şà `!'Œê/yè#Æ±õR>AĞxú‹=´wLû¤È¤Î©S˜mÍÑ‡ÍÒlèQ°†¨:ñt2o ‡1]Ğb=ıë)	ü˜Ğ6e’ÖhAHu×ä)_'"I¾Şû¡½[@CÂ{§}Or9“şè=ºĞ	]Ğ¹Î¼> ¤yy0’{&j.'’az–H^çÔì’P¤ÒiÂéÀµŸuıIÂgÊ³¢‰2«—Úl8íìëTÊU·3½Ä“ ñõ&$±„RjëEsjÓ˜†œIbÜ2<ó‰¸‹EŒë©ş†QÔÆá5¥gAÌÙ3
f~ 3u<O—ÄšpRãLSœ¡bQŒƒHò„ÚTŸ·˜xäDÚÆìbbušO£wqçC¯ïÏÍÒ;?¢mDï< PÌ*µbMo‘×
Şj¢¤Là#ísâÌÈ@¡Áª2\ıNçàêi]Œ÷íòAm–|úÄkê/¸hôÕş;ÀH¸—~œİ¢4>ŠH9ıÅ4 ¡pÊ°uÃfÌèÛO	¤6ÑYhÛ8Sê76gp‡£8îÜ×F¢?lsaFèÀ»aum&,<N¹0µ1dˆ›³.¿l2Ø¢õÈu#è@–¸;pëeÜô’œu‚1{zÁş{:V‘(€ø`ñv ÄÖ%Æ&Ø­hdÔBÄ™­ÿ»o®oaşosãiÖş«Ù|ºÔÿ}‘ÏÃ‡_ÏãÉ¶ş¿Î¬6ÖøC¦)şX>Oşƒ¯”*ÁE2²Lı:ÎÃ‡¨F„o¸ˆåîi& )Ÿ¡f”eğËß;>”ŠÇùe¢q½$}‹’XŞE­ğÓ7B“¾šYÛó±4§R¹iÍÑ^««uú2ûNùŞ˜¢k	š&È^ê×òİÊ—¦ë4GL|îSÿ™Q€Òyø{T ²B7Æc†Æôû•Ä$Y¼†ìàëi
”­3ÊÌ”EPµ
4æEè*ÕÍ`™šç«@c[T’mó43Ô¸L £Ñ”‘ÁB].[+˜ù†z÷¶»³«€õ®I Ö1„‘ Pˆ3MQÚbó±ÔÏÚHï¬@f&YºJv>ı¤ÒYvQdLIpÏúgû”ërQv	•uQOfç.ì¿ÔhÛg+ê¸9‘o¯èšn¡ê§ëæ5â¶Jún¨T´È“Œ-µÜ‚ÿÑÇ3®¢ïú<Íñÿ›OÖ—üÿ—‘ÿ%´úhèáTş÷©Q â˜•å™+n—Âà¨Ôâáy7ò}¾/Âá0¼ÆËh¥¢4¥{
‡,¹™ø-wÏ•×Û#„?$3"¨°Uâ4”gú$Š€{Ã½¨Ï‡á¹Ğ×;íİƒ6L{÷…Üæø£T¡HºdB‡»úq“º[×¹K^RJ+ÌÖÉ-•QQÆ#Êpa6Ô™øÒ‹¡ÿ|ëÜÕŠ‘…(½ï_w¿}Ævtã‘h5J$¤Ú{•D(Küiğ¾ú¬
ÿ§ÎşaÄDIÆ¯ÿ™IÛh‰úQ‚uÌ%X]î´`C.&}Uâ¯ÿ`¿şÓ(ö”$¢IŒô÷ÈÏ£Šx@Üºïğ¸=Š¼>Ô‰Œìâì‰o áH?~éD¡A
àMÌ‚GA@/‚-Ì½—¬ÄÆù‡CÄ@ˆ'0~b”Ó³Pà*~=Öy%`qåoàM4&[k›¼®JôA5CêÜrBüé
Qêj`u•àHM¤†Zb4ˆi§¥fB—w	˜ ~`HfSQ¤š³>ÅøF;n"êæ£TPTÈ	ÉüŠRó~‰#œ9ß ?Ÿš•¨I<Õ›ÃÓºXõTÎÛ!¥.¡Ñ5nş˜æÌ¾Eô‘m#ŒDSqb¿?`LõØ	2jBó …1~aTfâû¬éë0Æì;®áîUÔaİĞWH\54IªN‚W±m<3×hõ&—9-Z¡Fç¥Üò³ü,?ËÏò³ü,?ËÏò³ü,?ËÏò³ü,?ËÏò³ü,?ËÏò³ü,?ËÏò³ü,?ËÏò³ü,?ËÏò³ü,?ËÏò³üüüü_ñévş  