#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3480324423"
MD5="1c9698360d3564541a7c2ebca61a8202"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20316"
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
	echo Date of packaging: Tue Dec 17 21:19:46 -03 2019
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
ı7zXZ  æÖ´F !   ÏXÌáÿO] ¼}•ÀJFœÄÿ.»á_jg]77FÚI½K	.+äÒ'sÖdô=e©³XŸ¤oß*ëœÅşW¼B³¢ÑvI<©IÏœÔm†¬Îk§ioUcùk%nzf…¯áÖÆÓq½T4_P÷ßr¿|WH³ôkà,Äƒ‹ºÿ±v€$çÁgUÔ1éü^Æ55Œ-¹ŸGz£³§?sª¢4	®ìh¸.u1®tˆËÊYd`Ö·&!ªwY$¥j¾ä­¾SÏYtWt!jYÀbÌû¨[G%¯¶(h¡T`‚ÿ±n„úïÂ5Ø¯˜‡Sùå³´MKOÑËëºê÷æ«r“PtzŞ7ó½Ğ”/‘¿ä«4>´ë@ÎñsRÉÂşØlÈ„š’pÈùBT«§k•=Ø,Ú;Zlßì6AôÜ}*ÃÑNcQ`9¶Ğ¾‹Õe³Ë u¾b@Ø+S1mÑÕÇØ¨¥0¿Š^ÁŠc‹ıSxD ä†.d‘ÓÅ_­·¤¢®c€»i¾<šP…s¹·¹Ì¨¦ƒÀğé±‡ßÊó®­5ˆ5¶Şzî;†ìQaéJåp†›Yiß¬sˆÿNQ¦F”eÄ‰¨„¶
&MbíáóVÚ¤ß-y?§?Ù£ëg®ë{ñ•˜ÊBIR€úíüœv:pn`›ö+ŒXgo.¥C\ÄrÇç,Ì=HÄ°Î^‚šÊ¬º÷»÷/:ëÃGEØ­ÓÆï&H¶3L‡ëÓÇ.x5­›ö–‹Ôô%©‡¿æM:ËTÄ.ññAdÉ‚`3^,Ôğö«SÔôn
@ıï)k{2ä
Nuıîš$/Á)Éİ¯<:Ä¦"ß\_ÔÁ[Dëøµ¡¹À¿ê¤ü·UoùfÒzlÅmÿh ¡¦úßËm1¹Ö6İ¥©şºTZ²ÆMS^2IËì™ãÓQ7¹b±Ç€Í³r‚®‹[Mµ¾‡É12mÏqNÕ÷zEK;671å2<ÎË5¼X’y{ÑtÚ*Uj7ô ŸÊyÑ1´ˆ“4-ÚZ™v¦[&Çvî(×Æ1ám5—"2Ë
+	É–}ÁH2ŸÓd¼`œ­NÆ8‘fâÒcz }¼i'’Î×ë°*2Úu ¶2…çS!GP>˜ÿ[:”H‘­Ôúi'Ğ0ÑU“3£¥u-Ê-lOøŞéä0¼ÏOı:±[]—}Æ‚İ–6tô¾B©ãº„üT‡W¯^¤¾È|.Ùn’/D†x›#ßÁÙ`R]2oB-abtt|T¦®Z•€³óïr‚Á¥ùä ÈhõSŸmĞ`‘]v{²Õáş´™«ğ“dÑ²ç§À¦Eš¢w…	áª%³2#£‚Ò•Ç GKYİ0ÃN]XG'ı¦{ÙşÀa êÀT_µ“(“éNÚéŞPå´gÖxŞÀ|&èÅøÅ¡„azZÕÓ¼Ï¶$ÛDÔĞK7#Ïl»ê¡œPç'Ş_Ø1Ä -QÎiPğkpn3RhPªlŠµÁ^YÑ«^ÕÁ´ZŒÃÙO³°äÅµ<ˆáìÌ_F7P ©8AØIØÕ—	.¤ø0¥ê¬§“–¡¨êÇ©†¥8:ï³Êy®#GHº\¯ø OÆ|¶áÔ¤Î³ÎÌ#TÇòôÍ2ª–ºxLº–pÁ©¨Ü)…““S8qÑ[üÁK__ªÃ³_ì^«h¡q>?v,„|ğ*³Ğ|.i¾|-§$REjÕğ„¾ïW0¥3M_Ö¾í.Íˆ:w†tÊQ=Ñ&õVÑÉÓ¶¬P¥8¯Ö·…“ÁvÕ · ÀRšÓÈ´,Jâ ÿıL9ÖÖ—™ï„@eù´‹ò°©k#l™åÿìj[NÊxcE‘»°ÃzqSÒÕ(†  ÖPI?‹‘…1ëÔšFq K¨Ù¯Õ(aç¿š+`ot€ö&éN$1•\@Ç?víš¾S}'„E½«B.–E
º£ü]nN<Ìí3©)üŸ,2pU`nš¤ÏâúM²Æ98Şåí½R¬Åİà=¦R}ı,w®Eğ0¹ÂRÉm8DÛ^ÛÉ¾`{ìN'À}<Sú›-ö½Èq ìŠ­ş]H—?‡ŒIîº}F©^)Á4&ó²4;âŒ:wççÏ½¹F´in‘æ)GĞà-„:~}âŸr{K™Ó{‰¬pU•¨QN÷lÔÓ¸l+»][X8/Q”ÉÕ)Ú:åæ½O¼Şçÿ]˜·¬%Hä‰eùÕX¦†_«öV{Ü5—O
ıüÆKøoŸÔVJ¶Vâ9Â©y}wI5ğpX!‹LOU1S	`ÿúí©ÅıÎfıç­ÈWÃP$íÂ×ƒìV}(aĞÿ”kŞªô†@+Ù;ªî`óX¡‡_"şK½?RÃctÒK½3eÏù^Eõtp3ã5^0pçLğÑKyuuB°<U¥Úm™rÏ>Ÿ¾Á,ƒ2ğàM…Ğª[ÅQxX{Nï+º¡şôê ÅòWŸfsE:å´è\3kU$e';áX¥ôªŞX9(Ò°’®M©'Ú ô”û–-ÃÃ”,¶Ïj‚$¾x¶ğĞ«Ö~:cNÙ¹ä£Ik|ãõQ˜nZø»n¬«DeÜªnÍ÷áÜmàD¸!®Ş²}MÕ´•ºÎÜ›é»¼ëñçÊ"­¢PIyŒîƒƒœrİƒÆÁbà!÷çJŒXä
îkæJ³şÀLc»ur¢kM$!Âñ")¶xÈô5
N\ğ¶SÁ&;M~M­¾âÄ%¡çS¥6|¹!í*Æ±±\%cÄ(AæõÂ¹o(7‹rçÇÅ	O}š*ÍOb=Ä´îz¾ÅF^?qg´>Õb²†j& 0÷jXA ÜDeıY ZTı€wáóA¯7?Ø8(d‚?'¥ËşÊKny8³iép˜¬=Z
œ°Aæ#oQ†;?ïB; ©óïÇXŸ0FëÓï¸g €s¤íXÁƒT”2ßÙ¦¸Œ0ˆê–)?$Q8µ"Êathy~)Ã±TL„yÓA‰¤mêê5¬n>Ïô™Í~µwt-im:¸„“ºMÏª0µÍËÁ‚Àç¯¹ÖúÉ ¾áy®ÎÒ®c7¥gëó7$×¤Øú\¿	ÉÉ ºÙıuÙï®´XÉ~£ˆ‚¡z_,MÔıá<B\=É»grMôa­G˜İ¾/T_âO¦÷¼¢
­†0~®×ĞŸHï‡Yln»¡Qı‡Ü_¬Á ±ù2ÂN*İ¬x-ƒĞ˜8Ìd§kwq¥ŠŸ¢t7Ÿw!¡ĞØE­˜B‚À§.:eõÉŞéÑ5<aøºVÕ|²?½`äÆ—Ë)bb‹gËXƒe×t~wE³cO¶Ú¨İ	ŠĞf]Y_trÊŞsCêt™^1Jœï½1ß„_§³PN UT©Ú•U°bâtàT¨¥D"W£Kø¶93U÷Œ$Š‚Ÿğn/Á[Y‡Ÿœˆ¯ÛşÑáM&	Ü£ßÓş½İ1¨Sn<Î¼ÑìÇj]¨±b4ŠˆêÅê²÷Šıw7·¡Vñ†x84t±–BŒH^Å0¨»î#^Åk =‡Ä	ûA»$Zªû›ø£ã›ÔŸ}üø÷uã±°{ÂÈó9C¼g§Âk—’ˆF5vã€²|²cYÕäıNÙ
Ş&GC¨Óá@kmêôSíäºSkM ¸Äö†!{GgPáM(¯jâD„Óe½
¦Cé°­E8¡Şs¯EZÖà¨W˜G7ÙjM¾8i¹eÕ9WkK%4Â
¹UT¹”rÁ Œ‘sbæ%= =„ğZWÿÅ„B—&«7
¡G'§’¬&r	ÎNÕ(>/ÛUmzU÷?^Ş
l ’hx¿cÒ@Jú‡º7	p‡(é‡ú\¥qS«ß98vû;o6Ô{’Ş3d(ì¿X’ºèq±ı#ùpÉ ¢ãœ“\É–Ş	·›çÿáìñmé™â^;­Q¬¯¼Xb?Úß!6uÛ¦øØ>Òie™÷9u9õDûà¤ŞÒñ6«ÌåÄQ@™R†\6¸¾˜¯S{l˜¢ğºµj²œ›*°	¯Ş…ï²k¥Ã@ş)»•¯­¨<Ë€EJd1Ì³Ù|tş×Òbğğähñô•K‡RÙX=$·Ïy™tıC5ZY9‘qÈì›òÕ¨ıoò¬"YÙÚ	‰[Îi¯——¬ËØÉ;Ò‰Fç”âœè«Gï-zl„n5Á¾GÌ:>bNvØ©†Î™aÊºY¹óô&z!îé@é ™›®a9T³…#¿ƒa¢)DzyA˜Ê{½|¦e¤6‡0IñøOÆl›•¶YJÛW¡–lı‚s‘‹+€£ì[ÀÈ°a¢bÚ×Ä
nñãBîì­Dë™*’©md7ÄWg^ß:şáÊ¤QWîÿ&:³ÿŞG*Å2®ÁãüLæ=c0|¿Qt8É·‹ŞÄœ³¬±ytñ{½¯„»ú÷n×t)ãÚâZzWò5]1öí×÷}fßt-PÂÂšñ¾ï¦c‡k•éc¦ş²SdºGƒ(UŠJC.Ö 1OŠ±xŞ#‹\ÿ·àîuk®È-%§Áèõóì`f/ÉçxCBHD‰,Ä¦
r|õ²şw¡²Dâv›N*Â°òEr&Ô+úus¨æ©Hja›•¨ÊPC³Oˆé×o8R’¥$š¤DxïDªlGxğ¡•ìş[ÛƒÇ¼ÚÃÄ*á³ÙqÅ5ÜWúªÒñ‹›±i·Û¯gßRå–Sƒæ}¶Tëİ~lÔLªs²|Á"°PÂ= œïDcÇ»sizå-åšåJà&ı„D'ª
Ï4Àj!Ašô±'š®¸‹¯ŠÃûh÷b1=3òg«
_iòâÒW.ÚlÏÃòî¾ZXrïLŠØBúÅ®=]ª'd;°Ş9Æ’ï¤A´+à²úqö„< ñÿµ’AàÈlÂ©òØe}àI²öRF`„`iäÛ1Wìqcúíë­±JKR™;ùãr7×ËÑeJdÖ=ŸäDÖË^´¥µ¿•ÔÂweë^`„5¶²õìKÔ.XA;uÌdtŸoÅçpŠ+²Pn¢ñÌwÆkOOkY®-'[Ap<’CîèË–V"œ†xBcª©‡›/ƒHe§~†òóûM0¸¯D;R›Ä/öšTÏ–_òcPšÏ¸¥¯á  ¾®i8°¨Y÷C5¿ÚSˆÏı¯™HnU×6Û,û‡|œƒ'Ûåßî§,(8Õms‹ølˆY–È®}b"ñ¹<°ŒÉÈDÜWò5ã•†¼	Ìš ÍoB÷¸-‚øĞÕ¬å5"i8„&±\åßAX]m­Û8A72rĞsøÂçÔ2fì£»ÀQf×_=~ï{e¨ ğ“P*kŞZuŠßX^Ìd&—OŒ_»"+fS}xŒ_½¶ğÙs™4Y›™(İ
ã˜Uô˜Iœú¨v‹xøà"'kO&v†ü0}Æ)êãéƒÏK¦›µ±6{°(É±Ö³Eo«ÿH^ÁÜì™V“kØùÓ
nêR¨µ?Š¯ÅÔ¦·É¡koCgb…4ËÇä»‹€Ì{*	+åº–·u)S°Ò»^´÷I48~>—±ËÈæÑ' êw<ŒŸókt³rÏé'z“yğ×úÉ™¬P·V×=-ç‡öñàj§˜ç>ıUlr
æğ”{cVoL«D§“g9-"*m¢bY9=}ÿ•ªô ”NöHN?„;	åxšÍâf8Ë•0iÈæ5g T\Ï·„¼J?4qËéŠ.š‰uÆİNç'A”
P¿íÍ-Íú¨Ö	-´ØPÕØğ¯ÖÎ¬1á†`À¶.,J:×ÉcnºF€©;q1¾0õ‹†yÃè÷QÖf˜hésæ‰¯0ùÓ¹±
µé]zı,ŒÎgÈ)[]³gªµX'}oóì¡·«{´î	z
}¶‰YV$P£*5^T¿à»JV(Õ¢Ó]ÜôìpM¨Íğ´mSu£¶şi îû¨~Ì÷€“ƒÃ­‰Åºü:×@@¬Æı[‹ï|‰ª{ÍÊ#(Iòkp›É'.	»·ñ'´ó W’IÂf•0V´g µi!©Tıìı…m¦N8ø:c\Æ|³ãÓDØ€"##ê”ä9Ê/¥+„ˆÏú÷ÎĞğgÜò…NımÙPu~W÷U8¼ZØ¥‡«¢Â’+ŒK†XJšÛıÏÊS2®¥Ù’ŠF§6RÏ“È›UrWû~²ODc¡4M¼8º‚wùÚFa»°¤à´hÜ’zÆC\¾8iï¾WÖ³Ÿ,ì,¡¤}¥Q‰_`3İzr“2k²Ãïá á$XùSsE(.ëŠ=r;˜¾ Qé²ò(X7ap€<[Ú‚'»uäæ5y“‚üı†Ÿ²©‘·9“–B7˜‘t¯÷Ìjàš’”+EStâı7*@"«ÃæH™Õ¨X?c«h…yt/Ít
ö6*®t¼µ9•ÀàºKNUWÁÂÚğæ½¼º·²†8YŞö`†½èD/Íx¿@° š"şxŠÉ¦tıÙé:$•ôû´Üšóıö…;¢#ç±?¬C7^²Zm€y'Öø?gOˆBˆ×M?½¦­ˆœ;D¢ª¦È—Ú<òCºf,î	¼ãlÖdâ/;İ7CbæZ1~UâPç‹ûOÍ”ç#~nj8üì‡Uz›ô $œĞÌ´¯ØøĞïp>`ñ f“Ø	S±ëIùp*Æ5(>,Ÿ'`’ŠU ÃæÓß£N¶	çGÔRpÂ~Â;İ°eœz##iL®\ßæBZY!½sşŞµf.j„2™(‘©ñÿ°© òéõìãıÛ€C ¤üÍ:÷‡?w‘ëôpòYÂ/4‘lr~Sê
~"ÂeN·kˆD”‹šs	Ùf Ê¨¬5<~HL¦×­Œµ&‘¤$°šXãAÃl©üâ7´êØ
íä•Åkr•37¯ß5'iBÕp$ôŞñ•çú`©êÈ×3c»¾£€)d¦ª–×a„Yç…ÜR¸N6'-„Hİ4Hú‚EnÏŒl2íOäzóê®£>±Pä'/³7åF6†¤\
í‡óŠawR…#‡¿ˆwØ¾~‰42ş®ÕŠ'é¡U™òx#“õ
Q$#â]–İ7¶«}µNB3]D>>jûãœ'ÛîÔ¡ƒf%AñÌr8dª.çÓ“A…m2'4ş`—ñ»)ÎËl'ò´½şHãx#.üui–c(Ğ ¹€YÕ±›_åuõ¢øı}ÑÄÓx®S§{ÑËø7'è‘^O74İ–¯×/‚~’€‚!ÍRëMN«FC~=Uj¦Xı×@¶´‚ ¼î”Xñ øŠ±ÁWËZ‘İâKiÿ¿ƒ«‹‰’åXZ6Ï_ÿò¥¦'á†öÔÓ–r†[nd4AOğmMX(+UÂÆF‘ÿ†2Ç´Ï4A|–ªJ_qãš<Ô—‡Bìßóş[´°î'HO©û˜çs[%Î=;åÃzˆÒ;•.ÍW€Ùº(HtV·ú„µ!ûûw†ºÛxÇ)¿…à‚Ó×¬d‰¨Î|f–81/«è‚ıËüËéŞä€E}ö´zB™uxøANI‘!‹‰PŠrü¼™EœvĞF„‰ÜÔCËïeoãÒ>(;¿ ‚]•vv-›w¤pÔG Œ±n‰øhŞXÇö”0üu¿Rèš"#;^ÙLünPv!À‘ğùÖË–t†_ßˆ/mËÃò«Æ6íµ:Î‚êv×Qè‹qšÅÂ’~Õ™&ë×«•­F™c½%Éš™óÈ$äásµ-äëŠÒ›Í“˜ôJÏí‡I<¸•-jT1ÄX7$Q]äÒ´~`É³…gó¥Ââ‡­‡Poëa¿‘±WCÀ:Ü¢ne¹ºkVãæ@¾¯ ÙÏX@KU—nÖ¢eğì›EàÇéa’aÆC[Ğ‡œtOM¨¼¸Ê‰bB<òdñ6öWìQ)…BrÄÑµ?q,ÍÈvÇn@?¦»/ÃÃTcşöA¥/n@NTªwúMrJ	•O£Û\fòÕÉŒ£ğ©ór^„ån/ÁVünñãR¨iÍ
šÊ¦cAAPXˆ{şÚG@iiÊ¡ô„aÁ/Ã¥Q½`ĞÀšÃaá%1$ú@^%^ƒº‘ĞhàU)Ëƒ'¥ÿ‰…–<`ıõå†i'tïŠ%Ñ7­âqòØ{kdÑÏÂIù€Ş|À´öpQ«şGnHhGœë½ïL±‚.ƒ½ï»0J…ÆUşŸâ‰«mR4ŞP+Šşf„J(“	u•6è,S|3–|4şÅZ?}Ônnç.\ÚÎ¤itRs©"O{=­@B"só®Äísˆ:yg¦1¨¾C?Å³n²L£i8¬ºúâ<î×u1øÔ¾Soùt‘EºWoH|f®³§kuf/ş¬şVT{¥–¼÷„ós²ŒÕJØéY,»˜„´”ñ1·ïQ-ê0TFü
JxCŠ~öûü–rÛ
Ê¬[é¦Ÿq³ä/u‡µx10rş/â	,D¤Añm²“ÄÎ3ÎólWˆ²/Zí°E3Kñ`ssª"®KOËáF–²¯¤lËLg„«)`”º¡¡˜ÖÛupëH—²B½P9ŸÃ¨C>‘â	Xi-)©»ÂuØ2›#_ªÏÕÛjNßó‡bF'æ¶{›ªCs¼=¢Š«'y2‡Àéœ“æU3ø ©ÏÄ4- ½§³d1U-»{q¸Ïğ?S•¤oËĞ€¯M’%œuúWâ:Ì¦¯?´Jñh?6Åç… ÈÃrPá
Œ "Ó~3gM”İë^“„_Ÿ½|ÖéPy²m((òkYí—.çÈV‰’ÅÔM}ã
"sıvefÏ$å—Ù‡ı§‚çd+©ĞÖÓı®»aÛ-rPÁ‹ôXET¹S4W7¦éÍëb#reB¡ N­„NY€ÃÊ@Ä•£ìÁô@MotŠ`ì <Å¼P@İrS[OO?Ø÷GŞ+âúo˜öÛìMhØÜj…ÛÑçÉˆ"3qÙ÷?¥ZËÈdE“İå¤S')³ÈÚ÷«¥	òª7Ø Òzy„‹;‘¿1:Fy,²æ÷uëÚ|U Læ¥¬qL
i±=4ê¥Ü f–4tÒÉ"%ßFLÊÌªÈQ!Z,´&Tç‚r	ìŠ041…‡¤Î–ör–·?…I1v®S™ğ	BŸ<İì°G‚^
ª"!ÃwægÙ¶ZçmèÆPµ’3@ø¡–hîÚ]†•ÉÃ\,¥ş±X¢}f¹f´t06„^o™½D(ÁÔ·§ì¾Úç+Æ à³gâ?ˆã±”'º2j•‚A["@#Ä·$U_¬;´8¨|¢jœ—ÅR®6·yJ½6áÚYµ¥'ÓT’©8ˆOÿ¼AøàıÉA"F³l¦^±÷†Åe?xXû{øA¹œ¿kN_×+™¤ã»ò
Œ'y|n<ÙYIöÿôüÒPs®{¯¿ƒí°+N{Ê©¿9…¡Ìğ
?ÌŠÖøşn–ey“ßO+ù[VlˆÜH³ZË4p[‹¿œÏÏ¦‘6Âà(.º¾’%ç‹îv_ŸŸci—á(µtqvì´|Ò«àø:tGf»jÉ·oIÎjÕ" L°ŒğFUCæô_7İó»¨M—…`…4Á…D–%ƒ
FBûüÂ0ÉlƒşjşîÏ ”Ø¦¾qŒNCî¡ˆtŞ»§Ç	Ô)p,Z×5•ÂvSvL¢o³z¦Ê"ñŠÙæ`‰şú.%é¢j‰›s_é_Ôa¹‰Û÷ æØ‡×rÓEr©ßX‹şÖû·¬_â¿Ø¹. A»÷wÌ9Ì˜&QgïÒ(Wo‚¡ƒsB¶m­£<ÛÖ8ç·1®K²8Iû×u9„ı¢ûGØhĞ÷ÚÃón&lÆT°®í¬x•zaİo×Îc\K&w…·Ÿ1'Î^ Ø#†§µeo;D4üºğ4û>ÃŒ˜î‘½9×^çÏ+ŸÎ¯b.‘?@‡JÔüY®·º/6lÇÀ÷*0
ú–„ñ€¸ñ;Gµx8_NíQf¶ôµ÷_@ê›ü´¸XIC%L"™Nò_{€‚êX}6où9…©b;qƒ·¹ª_Ôq³sD“õB™¯)aVQ–•ÅÃ\6em|WıÄHçGiÿx©£¢7ƒ¥°)İ;5Ö·6ğº€0­Òh[Î¬şè5ŞlY«Vœ$Ë¿Şj<lf/¥§›xÂB—Ü˜~É"yY2ô^^40ÅÔ’eøkJçV4ÅÏ%éå¢u¨6XÿÀ4\êiæ›­:’áˆ56ÛXšM•½[¯1Û:˜½f]p^+ŒÀ9¿Tà£ãq“"yš_7Usz¦€–¤æÖ¡É·ó¹&¡zŞáÎY-ë˜P£`D¸ĞíÏ­¶´ø`ÓÌ×²AÏÀÿ‚0õéÖ(”“}ÛÊÕ¥ÛÛÂ(«ëcÌÕ”­{²“İN!ëÍåää³˜"(z<›z#g9_4ëIª½Êık`êöÄRuV³¹ 9ô•6¿;@êèÏ	FIR’Iswöç5…“=X°YOõ¬ëdYª‘Ñ÷!­|xÄ°í€æs™ì‘Õä°Œ¯|“{Â¨µ`™~#æ—|¬âv@K9ãzq¶RñmPœˆ;ÛRN²Ü»ƒF¬É\QY‘PõiùéŒœB#·Ä0/ãTö"B<ş@œâaà6•¬d‚ÀA¤ëáÿE†¤on ”½W±¦_™xŒd„Í‰V??ÒÔdˆ¾‹­4IÙ^´ÚFP(—q½"©€ñèã×C ©ïŸæßªÊ:ä[/&r
A|PàùxÅ®±¥lcÑ&¾pĞé)ÆÜm#ıï_¹¼8B–İ¶ıR´½>ÊzH˜¤ÕmKûıÊ5aüÄ¸>—!k~¼IÎ0¨}§ë8Ûƒ9Ouß!›¸;êÍbª}n2?l`eakù¼R)¯àMe J°ğˆ±=}z´ÓZë),ŸU—›?½<ç#ıeLn}2İadt¯ñ hå—ş˜…$’š,k²aÉ;c³w¥6oVBà_Pp<|Šë¸*ó€Ã –F>tãtÈMşĞ«:7|‡««mÍÍå»èpëDî|˜:²,^)j®iÍèJÜ¸?shŞî
¸§Ù1_òk³¤™•;? 0+¹å@…Ò\QQÆå´˜~tu´8{÷Qç@ÓlÆ_üh7œêuMaŸ›Ägø4@òğÑ†Ùº…>ñO6üjˆ<²)BÌÑ†( ŠÓÓİBÑÃ´˜©Æ ôär¿ëŠ˜BØ_Ş9ú”ˆ²gÍET€èÃ ¹şh,ºŠÌI‚PêuÈyïÁ-}š¯]\ :W1Zñ2F/§oĞ%í W>ü[€;(fUø¬d6
I7¡R6SŸ éŸ½nguTÎc4ÆĞoX\àÙh?ƒ/&o”\€n ÌûN„²´°ğ¶† =V-ŠGïf£c':äÊ¶¬µÅtÜ³¸¬„¤;‰ÔÔ47/î¯rğ• ÏPª{Ä„z²,Á°ú`/pq /ëq]Cu#TAá¬²ÒüaÏ(ÑüDÂøÎóÑÉA°
­¼¬üÜâdLº¸û-*Bäâ¦4Ú7î£Vƒ;¨FæÍ âÉøéÓ;ª?·¨SRàZo?SÉfüf½ÜÄ	^FV:¨
P¿Gİ²¶g×ï¼ëÀş2Á~Nzãbfy¹%gâIÙüü»?›õù2Æ(SöUÑ|¸Û­ÆlIK	ä!â~ò-Å`úÛ$}¹l5Êø˜g6awÅE1ó3)àåÈ8ÌNZï›Ô/5¾àJ(AV[yÌğ_Ï¡¥ë|:)Í5ÿÍœ&¤åø'4ÁãA‰Zê·å5ÛxœüCa‚7¼}ë¥ù·,Èbm¹ó¿WR¾àêtMeÖÎ<¢­Ò—€ówK Gk_Ì•<îtû;E¸Ğˆ“.+Á“,É[7ÄI"àxEÏ@AÀ$@n6Íİ®sÕ‰¯÷Â“ˆr	jH
—s™N»½b@ÍY†	ú¶B¾ğkE”N°8ıZÉØ^‚ì=­©'§;³¢
÷IÀtÉ]jx9b“Ÿ"zñoÜT­ÔÊnŠ" '¬^Ë£¹zé¹›Şâ¿hŠş‘O g³Œ²¡Ö0Gwàß„§Ä®k5ÿØâ4õ%/exÎG°„zL§«;ëÂ•“ûbRØúŸŒZ9v,}À¥h)S›u±¤B½LìÖaæ—˜råìÙÅösyÕı%Yñƒ(¨ã:S…/Lu4Şì“üÓÔ¨¾'YŒxÏØ¶°g÷sÛ«ıùÛò9©3õ]gõÌa×—	ÿ¸WaAğ2”wŒ€å2g¹7°k‘è¯šØIYEH/şéÆyz5ş.6¾0öÏÁ›‰)‹5¼R2tşÑÚ­ P&œA2Èc0]VI¸ÌàX^å©Î‹pË²®'@P±¨;nŠÙ¬yxÂ/7Õ[÷”leû½Yà¼İvJevÀØGŸ0±ÌJ457v·„ü‡š˜Ô=#Uü=äÎëma.5ÙÄY¢‰õ¾‘ø@•8Š5}ºxù
XwÉ/º™^«û)äŞÂ˜Õò™°¤¶Õ™äc$âØÄ1.O*Êû¬&•,V æƒ›Ó¾gt3ÓE"ÎÓPë–P4ÂÇÅÊ3O˜%*:óä<ÅH›…}Ï+€Wh\¦¸aÚM</b÷ëü‘¬ëş­öÅã™lèÏä+KÊÉÉB1ÂìS~¬ÉO6Ëa×¨;‘«ßv•¢ób/s†}q„G9æ¡ŠX-D£úm7µfµ/gä'ã®‡ÊJ›t–PÖ_Gş]âˆ÷‘§M~få^Ğñ‘¯D6åÁî,á9“YÖ±Û{)N
q–á/Şáy~œúE+Î5ŒÓÖù¢]ºå¢í ‘ÎTé#§“ÌŠ7ÊûBáùAÏÏ˜BòW©°êİ/Í—<˜ìJ§İ1x)œÓ;lqv|êûh°kU¡@|f^¬Æs'¾·Î*Çxí‚Ÿ/,Ï˜n¿³)u&Ç¾Ço¯µç'¬fİ»˜zÄø8ÆCvÏ®-D
VÒ‚¨ŞH"2}ˆ*Š
@ÕÑ¨l+UŸfi½–>]i´t:'Ïù\ï`Ì‡<jfşI"Tô}#è‘ˆ‹tu¦µŸMìù˜Rù<Ğ-ì8{_.ş&"Z–7ÈhŞ†ïàQ·O{óÏ`Ö·ğªhÊ¤€Uü&€ö¶ìòrÛ-IŠâ`š†gsÖ©3Öæ=?g¸dŞ¡Ú{WŸlú¹	Y•ckê—j/Úwúcïı!¡²X·Š<Î"»j\ğt£Å47¤ß³¿#>?7#Ñ¥\eR¢õªR•b±­u ”^…˜L³ŞØò}˜0‚ò—$å%ëŒÖˆŸo4°C=4&ÜàÁyÏ¶¥Pä-Ÿµ]†`z–ŠZ­RÏÜm‘\ÌÍ
ŞJÊSÖ·§È|…»Bc®¡®v7-}Š„zŒ·P÷‘³·YT5ŞZøíV
«ÉkÃmñØşƒe•Õ€-Xp
GÀ¾bLšå-RYa[SîÑ‚YşeÛˆY²\×ä-.ò=¹Æ´ÔO÷:£÷÷Ÿ	Iƒáëñé¥Ô>V÷@ñcJ-¶¬|XVô²—ğ)gÔt´ŸVˆH÷IÈÃpX¼¶:|ùÂ®ˆ Ó/‹â
òFDz/‰æ¦ÇR~á²ç‰Ÿ¢µ»H…\!wöÛp®•İjç‹„oqˆ ·Š°E_ºúJ”O1>êVbrQrYWÜ\ÄsÃº!zØ—'ñ¼‡t2P¡Iz…è1!	µôAlY7Í²€_PìõXâHìÌŠLyÜWïù/æ19wzÖtÎáÛG‰oH` §5<y²“$ìNt-~§’Lÿ!‡‚ştäk›èèCß2±¾›İÜ“.3Z—’|Q!²Ğh!”—şˆñp¿Ìµ¾…Šf|Û`lcÆÓ°tK¯Ü“ªÔ×5F±²áÇ){‚Gş†,.«ş7JÓ4ÖEE ŞÜw“å£A®ç‹†yõ|æ*?í´úiXEs»	óºâıO:şãüßÀ#„ºXÖ´=Z ×5¢jcMËãîeüxºc}"I	z,GèRì¸®nŒ]ÒëêàâôÃĞÉøƒR¸7Î¾rÈ@ÌáøoĞA­X„!´(½YÑ#_{AÅl¿ûï^	z¤–EI@Kqi°Á’‡€¬â¼lB·$V²¢ìÃ-N? iÚMÊ~Jä„æ©u­È®NÕnSr*j¯fÆPEúëaL=-…}5åÎğtx†$QKF‰V\Sü¢Z¸^Øs•Â¸-T”Ñaÿ’C‹½X$åæU-éóùñFÎç¹Å336İnšÃ17ÛÎÜ•İ2¡™1®ú]9©}¢q½ÁåÓ´¤Z?—mİÏ0	“(T<ÉF±²-œ›(É„­@¾hØUáãëµfõkhš@¿|fwöëÿŸŠ´¯9R-°…‚…ÿ#pÈï	5z×¨!„¢sü÷À¼qs‹Dƒ¨k€
 Å;¢Rš“n`öÁx`²côş§á!rÏıãÚ³Jÿ‘ø0%ÃşÑüWè‚¿ÄÔ™¥4Œ%·‘¹] ¤îÖËö!âöe€Ô¹ˆ4·#t êÎÀ”Ãß8X{¤ Öõ:Vr´ëkZvĞ¦>_F¶ş„'.Ò™YËä=¥Të	b©ršRİëÓÍe¼ô«%WR¬‹
Xc”Ñ%İ¯]pA‘BíktKİö¦|¼³\%•dÄkÆı÷`³Œ¶¶KúLÔ%ÿP0²$l<¶–Â÷XÖ%*šßWa0Î€Û3Ëa.|î“hÒbÍ‡N¤T…TcnVÆŠ'÷B.¤ÆÚ82å¯ö/ÒêâÏ~?İUƒñH<`µ¡ˆD~+ë`|ø6~NÍ·µ¡%-(P¾G·–"İ!g¸>½' Zi»Ï“ÄS~X	éxş*ü>íe;xxwÒ´œi·e‡(óBË®è’¤ä÷Üéº:cu&«SİKe,Öñjà¬‚(Âã&ÕE ƒuÏyTÀş%|7‡ËpÚqDEq(Á`<<8U‡ªİzÒneqQ:Ã³TÂM#?ágÕ½|8IMGZvWzÂ?1>¬—69‚ïÓw‘0×§C¤ÿûÍ[¼@¬øuKG®Vuwn¤÷Eà¦^5òÛºVœĞ­ï°˜áîMÔ¬D>¢ùò4ü¸—ÅÁ]®†ÿùï	µs
_ğ†ô&€Ú#©v˜†}ì§à}}$ûÙÎ„fçÇ`(J4IŠÀ}ho–VÇšh~ä†®UVèUr‚Å¨9™‰ÿõb7<ğ}#?Ï>˜7«±ÎQ÷dF(x¤d¹+Ó§íL~K÷Ş\	e×¾ p¦R­|„Œ²OaÄƒ}ÂYMáº[ì’‡R¤‚\¿vŒK’À®	dTèm©Ù{÷2p¬ ™Eı—4(.øÙaÖ©WGdÀ^lf`¬}¿ıëê=\>S–ÄËeá©Zè$í¶ù;×bÉïoŠÓÆS{ÅlëŸN»ê=ˆ®Î±ääi’¢F4öry>üËãÌèòê‘CRº¬¸3.PCË_ ¢P/Ú»`!F_ŠŠı&âŸOUJ¬ªÂ¸¬”sŠL~_<ÁZÂ©q•úYi’ÉAÍïä=¼møê_¾Õø:/Š¢ía	B²üs!ëûgÙv…xpúŠö|¢!hÀ‚\ŠYñc‰$û©?¾C"uƒ0˜zÈÇIO»69)äNîO`•Ì‚A—Ğ'ª²0›jáJA7A&ä(Àhìğƒma³Î½D)3uœó0S™ò¼(¦şkˆ×ù~ôÆí½»®3ªgÖš¶jáÓëC¨ŸTëî#¿rg€˜Ì/„Ñ«ñğd½H&V÷(w¨8“)B ¹Éó«ãtxªC¿Ş
¯“:ÖÒÊù]Ş&Â8ìu¦’Şx¨9„ËĞÀßZ3iòøióÿ‘—’Ê¯uãyJg„xo)&Ñ*x~zTÇ” n;IEâ¬t„€—±,=æô>VŸĞcñ4-8|ÎÓ^ÕV Ö^áNñ~k¯„ƒÈà&oÂ^S¢‰¢Is¶R cÌXÏŠ×†ürĞäÊıÜÆâÈ²ÎDIÜÚÉƒ––]µG’onßŞ?…D¦-ÁTƒÏâH ï/£Ò:ç®e	Ä69hz51üĞ¤¼3PÈr¹Ç² 	ª3`5¹½Ù»s½8õ€rÏÇ’ÎØ”QjYòŞØG5©°TtFjõCç İ,’hD?·“¹@§Ó²Õ5ø`PæJ¹ö„Ê8^hr€†
öÎüyÚæÿ‚Ë¾Zci5–ö"G|Àı¬ ¶ÍŠ>:÷‰Š/ßqÑşºÊœYŸq•¹¨G¥àcµ‘­XYµ¤Œü­I¯õšM³­
Ê¾Ã»+•qõèÁ!Uü$äÄæ¢FV>‘ÿ=À‰Úç!qI!qA7DDl£@=(T;ƒùãéÂ×}\è6iÂ#6„ü±ÔÏÒ7©¨ÃàË^¿²hÇÊåæ”æ2úÒÄ4óAë+=3Š	¤q®)šı`{aÒÂC‰J;çÎó¶sZ;9?™4Z:Êê<'¨ğĞzÌ²îjo;)%V×¢+Z92ğ½¦.^iU4L½5N’r0;¹ 9ri-¾¼(Õuj„KÕ‡{ã]§ê‚oUÎ_åÒ="cExá˜óÂè)8˜rO¼¿^
ë‚À÷egÉßÁ^œÛ{œu`²aPÂ®é•¢òE.ùÉH‹nZ0%;X˜>Î ¬¬IsÕäÚ–µg¼£îZpÃYğB"•Ê'{`¼E/g¤^?P h4~Öõ»OšÔ¹dö«%èêšk¬À-M¬­1X!WÌ²A«öÈ­Ç ïÚúVÓÛwu?©{/pc@ögœ)•.|zk¼ƒ¸vüÈñĞ›ëL£NdåŞ§Róş1&²ú~*íxb\ğîXe¨k)Ï71õîé¿p‚ı²‘o£ìÓÅ’ÎZ;Ì
Èf½|ÍO^°¾åô=šÀtı£-» yïèN”	<´ù'ò? ß0•axäı–|-åöså	˜ƒ•IÂÇzñÊ-+îb%‰¯²B$¼&éŒ«âÖraøË×<VëRûs-Î<ìõØå·WL‹·#p0òÃü¾ÕIÏŠä«b:Gİ$—d4l.XFU„lh¡9¡‹î
ô›’^+ô„Ó—s¯ıƒÙš„Ù!Ç:²ÊPa€`j V²h£»…¾v¹s•¹ŠÅnt¸ª ²	§ëyŒ"‡¶@æ	“/†@u¾éA¦çœ`{39«ÖÛ9jÂV]Mş ¡Ã¡c–°)u3/–Ù4>…’{dmf÷•­íu:ı©?Öè™®é-·î4ï¯¤sÕ7‹™E³±xß»dJ"Í9xœ,ì ÒãÒÙö=³&]	ÑeÙÈrkdª.©ïYÁ{ñ‘ÀĞ—ÒZãè16À;Â—¸ìDB>1ãKv¢5PP†OÖĞ¯×Ç^ŸºN}ÌÛÛñzŞ”ÈàOĞ:lôcUÿbù3G31%r÷OàïNÑIYn.ó2øo—ı/Cc»‡¶-n*§‹š"ÌŸ=LÜ5j–L}ô{{‚ÒŒ !û¬ È7Y½‡)Ç`O+„õ´£Ç[²aùªd<çˆ÷&¬P¸èà*s[42·€T£÷Ì¦ŒR–s€(Ee1¨b'V‡;ï–©êfôšÌjĞ®»>kLm"áû+™mV¿Q†Ş}¹0=pÀL‡ä5Ùbå=Ó%@¹¿´>¨Œw;Ä¾Sİ¾šĞ²Ò
à‰ôÙ¦o2E ÔòbrÆœ¦0+å×Â¢òfKÀÆ¡ÊŒ·Æòë]ÄVÏ…zRƒÆÍáY­@Zw?–^>-e™×¡©P~½ŠEŞ	æCÀ'ñüË¹Àÿ@Hù×ëaâs= 5›­oÂX*£EŒ"~7j?a1%¬üC[íı7a²õ|òòŠXxò±Œ‹]ŠPô†jmj¿ÏÃQ§ñ½…Ï¨Cn÷`ÕÅyÜ
jµf0LL­:ÂqGJY%P•¥ù3©Y¿JNé'£¨Û“ÿÁ|Û2–:kxÄ@%ÁÓş¾İÏàY!KØô—Ÿš¿ŠĞxõ¢Ã¯æ¾á7ã}ğ¾j%"ôñDš…nÈdÂ%
OØÆönÛ¨~ğw 1Sáğ³_U
)ì;D@4_İá^.óƒ¶^ ¾¢\şÛG°ò Î{¾va´1j–Ÿæ/~ì¡5e§ dfáÖ€İ«ˆ$a†›î•ËÃ\Ãoƒ» g76E°‡}êt”İ-ÏVV„=äÛu)›¿ÒáT¶5İ›~™¿Ì}ÔôRö€AyÊ©…›¹MpÚ¬µÿÃ]ŞZl€_€€!dO 2IßÑîĞá‘Ù%bÑÑ·‰ı\²ğÚÀ!ÒF¨œ-â…úT]©NzëÄpäh·q“Ğm¼– ûââÃóÈàí•¸ıN5Ağt>J¹F:oÚ!ß¤½Z2B(3¾.ØëHmÍÆbO¦J'ËƒaüH‰³Umd~‹é<­%ü"Á Ãáı;ÒMqìüòß(¹!]Œ¾dèèaî©­/ï@Uâ0Ğj^Ã¾ š(Y{ò¤ª°åTn¦óš*‚â¢RÄ§¦¤«é	áúâ¾Á—ıÅ­Gs`JæX!‰©wXàXYJ#kW³ïı9WÄ¨Ãtk.){ Š© ‚¿1T ÿx6\; ?»ŒK²3	Ş¿›Ä	´±V÷ï µ¾—!ÏJô¤Ôjs·2]]gÛäÏhÿş
c½y’½FÉÛg9¿œ«#ŞÚh¡Êÿ¾fÖ42—Çxmâ0¼4CT…¡éSöA&H~›³~YÛ+h5/zzªNœŒË°å^[ƒ/q8.,4ŞËÊW‡è‚™Àı~? İK6ï³|.ä¯wz7úê%şóâò†	Æİ-Ò{’â¿†N©‡ìV™?*«6r{â°:ºœ3†ˆL j†÷<ÛtïÙ`¢[uª”ÏG¬LÈ-)âDŒ`IVlÙsøÒ#úîëægFXbúÙÆŠß#1¥›9umû˜Ôæ·şœ‚¾*5Èn8
#œe$O€s¼º[i_xŞ '‹VPe¥ÔÍ;¦Eò¤„"ÕïôQYÃ íúEC[ZˆãÎÃÎ»Û4Áhø@ÔİfBë•Š–9¦Ü¹Í÷ö¦ıäßŒiA—hTÔËŸ™ğÙ…ƒö^k?üøÇiéÂb‚5^SölÜŞï'ÏÁ%µ'Câœ c;ı‘/æØhÒ*HJ#ÉVql|^ ‡ üÇ+è¤KÓ:’M§,¹{úññïÙ½zd÷Ê±í\hk2É‹Î*İ5Ó‹mj–j{Ø}Ñ˜÷5n	eØ{º~Éo€•#¨ŒÄ÷!ß7UAÊÊXÁôÉM…Ïği¿÷¼ã¥Õ ¹>ã›_øâ(§É(˜-5Z/ÈÆóä’ş€VlU|Î²×’=·ÌäÈ5îÖQQ¥7»ˆx7ıtº+H™Îp™Uœh©Áõur©òWüP¥<è6Ò®ï7ü0¡0ÉH;oõbsª¢÷´“*„Në~7Hl˜¹ §g9Ü¯ò?‰ú¡€ŒÒ^¸šÄÍĞØÄúÒíŸ ×ë#àHsU'>4ğiwZØÒÂå»z†Ù€€¦¾ON‡ÕõƒY^L­#·\cJ·W¿Ñ±ŞĞc›NìGg!:^b¼ÏÕŠ­èú†ö35]Ú”nòçcò¢Aâb‘ı]c%‰¾ìúqiè)êêGU:¯BÛÜ¯¸H`°ğ‡Š¨¦„qDw7¢…&¼·$-¥îÓ":¼Ş\K°ªòDH¦“È£G¢ú9Ï4Sì½Nãví<‘n¬óE\˜É¡Ja«G ¸OMOë)Æ›Vâ¨kŠ¡©Bı¦j[¥ ®¹„tòóíËHOŞ½¸…p†Œi™yUŠå[3ïÄZ,qŠÔ’ãe|hñ÷”ïG–fšˆ€-RİÇ¿)‚Óì4ù~	İjìx9õ¥(): L“ÇXÌŞÒ+‡ĞWÖYD­¿ÀUE?<EFç¨™PÏ¥	à?F´b6?©½è»n´ş`]R¨¨øïÜQÁ•°ğ)P—‹¤W‹l„î™P®Öq¾»¶Qƒ—`¡oZ›L2	Ä:¾o€È
Èvä’ó¤%¿ÍTÆ3R~o@»1akÆí‡åÏ ÷v¦©¯n†# ı:¨€Ã10„AéÀõêı”•¾ºı ÁÙMœ&w!•hÉ–d¦<öZö¥¹ ¡Z-ôµ÷‰éãb2$U9¥{=Áz(«¼àaâöyxV;ŠÍŒÇ_zŸCôšè´}®À•ó»cëI?`òµ:Q4Pnİæ²ß³ÅïŸØ€™JdÜÅ©ˆ^Á…SnU¤‚yBötöÓwÈ‚PS+ÚM×2fQÃÕÔã¹È¼ï†vA¾ —]GØ²§Yi–>3W<(yB³ÓKú\áóà”<ØÕÃ"{J!Œ·.h¤G™j¡ß„çšÖÖ$Š.ÂPeqÆ'Ÿµ„#¬lâ¡Œ&ìFOÏ×7+~oñúƒºåsûmÀşÏJ.Ğé$öõì}R?Í Fï
]t—ì·ÄİvH,úÕËXÏß‹ë:=€„²É°ÒÔÈ:c¾’e~ãŸö5{Åäb„èHs8.Zb!ÓKÙèÒëV+şSÛm¼Ë6’”şpº[”J×Zlİ v4XjDÂºCÙŒ–ª#Ó•Ì3uB#û²Ü‘Wäø¹®:ûkFâëfb!)>\t'Ï"Â(±!ÿÜ€Yt—'v±É¹Ø®vòQOÄy!±ÃZâ¥dÆû™ÃK±g50Ê9ƒîö&¹ËºÌ{Ú¬•yÙŒI?6aqQ{5c1_p·=|BÆÉ¥“hkvnskoÚ¼"ï%†Ããx.n6«4º6ŠÅ%nuĞ~^¨Ç 1jÄßÄø¼šÃgÖN›4^YA$G)$KH¡MÛ¸Š‚âJ¿QnhTªİıZ {¯ÏAj’.q—	=%çÀnáÅß‡uq¨kµ0Éoíú«	§„P}*ÓtæX™Ö¸+›J\™Î3¤ë%ÈÚ?I“‹´õşxWG>Ãœ=ÙA‹çvZ?mmBnµF¸§öšwAa³c[uã¥LÖà÷7©#`èÁ¥EkÖå‹¡îïwõtB·ÏÁoŠÑMÕG¹İ'˜5‰7»nÇ(Öb.œ¼÷éB¼T“6Å<Á“zÿê‘9±p,qİ ¹¹3i'Ãåû¡ô7OÇÛ#`~x9•Ë7®zá¡XaG)]ò½èò,ˆ€za^ç§»€¹Uj~ùor'+Z†=Ô›®³â"G#5¾e½©*Û*NâZL>r³·œı½ÃØaô9C¡¤Uà®¶ƒc"wx›,7`Æ3ª—Íïáùƒx|,êR•ı+çÕOÉd£´v9Ê[ #f“ÊnÁ6¬¾<B*“E£²?@eÿøãúàå¾ı,WŠÊ zj–c5_R¦{UÅ‘“ÒîÈTEÖÄÎ.®Rt/BÅråy|î\‘	üíÆìTrŒ`ô»”“:°î.é¢Á¯à¿:ÑøÑ|;#ZåM)‘*#Ò‚Ş™æ#ØıÊåoNø <Ì6€Gÿ>R„…$¼i°áçÒ–iµC·‘|lg[µ<2¸85e¸QÈ;¿³Õ½¥ûj>ïœ°y6DÑ_Eƒ‚Ù}_ÄÅôìÈÕˆğ%ËY&¼¯˜ñ"ZØD¡ÉáJ…ua‹Pe‘W€ã¡‚øXYM†
›e&@ëîbpc¬wñJJÓÌ2`á±V=^ª2ÆÏMÔ@:½Ç0ŸAŒÍ³mğf«ñ7F„UHâ*5’ÊèyI‹œlö}æPÓœQŞu&¼{±Ë(­4,(uĞT¯HGŒ¸ÜvÏ×ó,láíQ¸]e\(¤÷göÜV¡ÿá€üˆ=Ÿ1ö;–¾BµjGFˆMämõê?éX&îäˆÉ­ò
*?‘R^´Á%ıÊsvÄà<£ö×½Ş¬C½1Õ{I¸×ş¸–ä#…uz-ª¥ı`¢¥-p"ÙŠ>~•V/FöyŸWTl3J7š®R%ó, :0fvm\™t(µKm™i5¡²ÿÎÃöS.óşLÍyƒ¿Zm#¼•Nè“áîl´Ca·”ªvAğP¸xÃä[µ·2 ¶Éºpø$nc1+æ=Æ÷‰Ê’…øÚ¸wà—«³5}:MK‡&Ì¹•¾nl[³+´j'½Âm<‡;Ö¦òÙ‚ĞÚ@æt"ƒ3ŞŠ@$¾ÂIîò:›üÚ5©””!‰“MÙ‹5‘sP$9áACâ¤iEÂtÜ%(İ>„Svt¼É›¼Ú<–J¯ÔojÉëZê^Bíeõ-~/$¾pç§@Y‘f=?Şn×nÇš#?4´j{O¼‹`–
:”)¢×f‰gÙÃè”ÖÄA©¬Ò7i/yÙ[ÚY§ƒäğõ¦ÿŒ†CÙwp°ZÜ¦÷yô·Wüy²«±Igö›®ƒôî…°8‘:zCuËş]õÆ%îãJ-ıhöbÚ6«#ÀĞé´‹fI¸Ÿ"f|5ÑyŞÀWxÌé’]zöÎğKNpÛ4¡yıs-DŸh‡ÄÒ…¤Hnh-tU7ãôD#?Ú9„Oùig5·cƒÉzÔÒÏÛë#y‹×¥ågŸÀšşñ—måAN–QÂßñIEkİTÉãj”¡A°)ÖÊzä”áeÑ—1jş(Sÿe»:§1™ 9 r¾0ZøæñBĞ NÇaäŒ1¾òA4^)ˆš «øˆÓû€u	ıçĞÁßº„I; ŠN9­—Í¸ºæ¾öƒ´PbyP2ÌqZ5i‚Nøµ’‰›ù1“RÕÑa¬	›J(¸‘Í=‚—Øz,(dN »İ/#~ŞgŸµïJy:'ãc+“‡ÕŠ$Ä¡ì2üAÈZGH™î7ûywÑ8î’Y_x¤8í¤<+§|áÚß§öÔNyd¥AûÔQ”}:ú³ì­˜jÛ–æLÚqìw?g¨Ñê~VµÑqj†C1t¢Ğš“n\]¬…ìj‘`Hm?w-%ê× µ›?¦Ooz »–·MH†ÔÅ~ğn"K~ãÊ@JÓ ­qêÄ‹ŠÌ–Uû©hkŞÀWs|ÙÈÔ›uŠ¤i®¼
p¯µËqÎQ­ÑÔHó²àa¾–ˆp`‚K$ùçMA,İúÏ¦ú<¢¶QÊ›š‡µÏP‰Ä¼]ÿBs¥ª<?‰-¼i0AÈ÷“N‹,P= y¶ërğ£ÄGôF)­B‡Ğ+ªXÓ')»j¹å¯ßábü»# øåN·iúüK6š!××ê2i½ñ³İ´³^Iñúsf° ºéüìq‚5ïÿBı=Dm?¥²İ§hÔbıh4\dÑ1s,;¬rıËêxüRÄ2škî¹ U¥­£ë°ä¨…ç&Š~•Gäâ¥ß\˜"°OseO¹BB)ASâÁÆ@=t«ß•èpP¡  ey+ö§æ¾ç\uµ¼ÈÃ±Ÿ	k:'D›4ğ5O‘TÖ(`‚‡rÁ\ß»SAÔÛã	Ï¹¢âI5re]uìĞ8H|©\Ş˜DS4xa1'Ä`Üû¨ğSÉs&ğ¤Œ	Ô‰ß…EşŠÍè5»D3q 
Z‘Û·ãOÀ$ÏÎéÑÛ¨Iß£ “ÅEC×[Í3pinµÁÔ¬Ç;­,©Çş@Ìı‡ñ¦—AbĞr«wÅúa'9Î„µé_m“Zfü–:+9ZGÙl…{ç/GY4”é‚•¦ğ§0ğ³r,w£Y†vV“Ujœß¡ò¼õnr­&ôl-³KÙO¢¢ue÷Ú#ÊtÅ <|$(T
Ú·849ÎşØµ Ä;ÂLìœ0ú{>/@­zDºd¿ØÂ¾–Œşò‘ß²‡˜72ôİŒ·C0¦ÿwò¢¯±öâ•íòx ”]TTíc~V9<<A#+”ü×µÚW%½&ûÿN*öí/¬ÓåYóe~G+×>‹ô¥‚énÍ®å³G©ë·Ò5DûA#V†Õ±Â°ë_:k*Æ=Ó@Ô!¢Éº¹×Øv,í(À±ô‚ ìÁ'EÈ\]-˜—Œò Méuä—)	öƒĞÜŸ'KC–?¡òIÏÁğ‚ûëCìù¬ ª£@ -GlL„%]çP-bÛ­ëìxC´ÖŠâ™o0YÔXÙãÔÄíwı¯;ºGúş%mq£²T,& +pZ1"¬ôÿ †P‘.XåÑÀ¯ÇÌÖØú|\VÏUº³’k¥Sƒşı¹f¦ÀiáÜI³“Ñ)Å|¸ œTÑoÛûæ•O|5 vÏ‹0Ë­æu‡Ş-í¸áÔH‡BéÒ}İ¿¦­yM¨+ØÔ}í—û°õWGèş©ÅÈÆ"İûİEõ>{rÃ~¨qA¢É>LĞ‹³k6IiW–`8ØÿqÁÛıúy'MügQPªŒùİ»Ûµ{Ñˆ\ÍZ`ÈµŒ¨3Ìî Öp“i-¼fæ@>À¿g`9=\QÏ?	¯KêÔl%ô~&ÎÇ^>]ş¹^E‘Jã´ &@Ì;ÔYôBq¤™Lg/†ÉĞÂ2Äí'ˆ+g‘Wÿã	Ì`§ï”à7[ûR»ë^•*X#—ëS5i·/ƒ>ûÎÆÚlŸ²Tó
Ï*'O_ÛÛâßäñqëÛwà1/˜{­(ğ×Ï ˜J§z³¸43eóHOŠ@¡	äÆôÒ;™µ)‡ìq]Ç
\Rx+Qj:êh,´õö½n-9ğ“N(2N2®¦0ç²JKÊ·#!¿‚Ê³tSpòuz†f¼ì¥°êI0²òá}}IkÖAäê3z!iImı´jwm‚°ÄJDæğîú¯dPAgJ¾ŠCÔ•Q¶^ÈZ«è²:Ò^j²ägÈq0Êï6Àx6µ>™%ibÊË$Ës|¢İTJ%ÙsV–®êIN7ãWTö+@÷‰Âi‘ö³6¸Ç¶ºñ¹N­3vº©ö%Œ¸|` ó˜(.<öÑ²¸²øE¤,ØMSB®™à.¢$‘9_×°ëë jt-,Ë¯+Âxê¿MµÂ¬ın™ëštîù]İÂ ³,H°ÜF‡4	°8cä»w(´NE·æU©š¬Qã?¼ü,±åOOOŸem*6EuÈñV°‘"d•ÅjÄ¨³n)4 †G*ŸjÆ2ı)CÛÓ¿(òb} ¶UW õ”T¡`;„òŸ[PúX	-ÈÖ÷wùÉµ2dí‡¦nÈ³ =p*Ìùy< ÑÇ¬<ëqÇs=QªI2ÎÀß!Xò°>ñN(¨œ³§€Rç¿I±ÌˆFw•¶3œ¼”<)¼Ğ;ßXj‰•ÔP»oùk”CX‘ïªà~f½uBĞ³„Çâvğ”ß ¹Eûn#œG!.8¿øÑoPÊQ¢Lû¢òŞ‡÷l„^íNÕê•«Øï²ÜĞpCg—<i?6¤aûı9Â"åÜQ#îª45”~PÇ9¼$æÇoÊ£¼«Ä‚RM^±õIÃ×,Àé¯ÀK]Z¥'e|8,”ôÔ®=)QÖ—÷O°šº42‰±²µ`·‡Ê«Zp¢çÊilúÇ–ì½BàK]³s4mO‰zcT„¿ş¬º®ã™´€øæC‘ÜŠÌ¹'3Í¤W µß;“§MkLè HÙJrx•°ü¤³¶ç‘×Tô!å“2qéÀû~IÏ«!g·Fn† ûŞW¸©ı9ìLgÜÃ¾Ğôë„hÕÏñÏ›CbOÔĞì“#ó`¹˜¢—oGó£ƒ¯€&¶¾°çßP3—ÃlR [^öµ™b6Ñ_>àğ³
#…ù1éÒänÜû°Ê,§M’¥YmL3B5¾ê6H€oCz?­CÉEoA©   —h™àqŠØÌ ·€ XA´±Ägû    YZ