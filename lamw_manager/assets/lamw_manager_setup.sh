#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1507055575"
MD5="2ab4bc38b147121440cc1bc411bf64a1"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23820"
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
	echo Date of packaging: Sun Sep 19 00:11:34 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ\É] ¼}•À1Dd]‡Á›PætİDõüÚ4¢}kÇtP—´(ê_[ay’bÊ¢üMÏG°êÃ"÷2Ün?Ábï1Z/"2—DXj:‹˜)É³f3¤Ã“A ¦0²‰æÅJ¡#¶•PZXb×8~à+ã& ¼üŒ¦ÂH÷-ü&<gC'Î]œGI©ArÜd5ÇU¥»/ÏÎlU«Ä1mufØíe)|oI˜fyxÆŸ{‘’ÿÎ2ÂÉ`Şñ–©ñ¯<Ì’ì¹á †¢.¿%!·Ax¦Ëô¢ÀıÙg×ö ‰¸¶wĞk‚¯{¹=¨;F~(lW¡£€´ú–|`ÿWéÖDk½ê\a‡Ô8©ÊóÕk¿:sõ
Î
Ê:‘
ë»6_K³ÖÏ5Á ¥ú•Ã#a—‰’Ó[W€yoq ’h/âxùüÌ+N9€N+,é}Ò:¶i³,•m¤[ÏğÖö¨ñ%€áæ{4ƒÒMzLyo\–3jû2n-ƒÕŠ!è¼›j[§YIE@›0²wñÇÕ@áU¼‚‡òD¡·Ğ¹,¦Õüo|ŞĞcšMƒñAÌ)Öbà@F8¸˜)_×ôä i”›´áÑİ$»~¹>‰(´?ìOxØ²øõB/¥Å¯îutÏÙğZáT}£m„Wí|õ¥Kq!“Aã8ŠŠÃ»` (h™µ%4'‰‚S@mÑ/ïèRi}nZŞç±L6¬$‘†®º„æõX:ÌÙär‚ŒÂáZ““.&:1G³>ö²YÅÃİéÖ)ˆ¹‰_i,.  ü‹û¸æ?‚†S†ª 9‰ó›äIdcV]õÖfìKÀ0q=İ¦İÜBs ×ï"„°«ğfPL'ƒ¢‰¼yœÚWª¢ 9õ	°müR>\d¹Oü##d·0Œê‰÷×lÙèÅªñQİ¶P ‹xXõif‹,AÊ•¥OÄâĞ ºay±ìdiP‹bWÒL‹o'ï‘…ºdú†Ÿ~9CYÊÖ¶í¯¶Š¶$Œä‹Ñ/~Šî®âWàªÏÕsP²¨Ÿ„*¯½ ¯¤OÜÕîEqÙDõÂHƒ—ÌÌ”&£Ê÷ ñùÒŒü%,Ëq%,Ö… Ša4+ÅAåß=0ë|8õAòw/’€àƒ)¾‡cÂ½ÉHå!8<ŸÓöRöíÛó‹HVI}Û¨\ğóo–ôÇ±†h!vWnéº"PÜ$íıÕÙæØf5ğ,¶õtwŞ[ÁÆÃ÷¾äMó÷q¡¨•pˆp`ÁoîÈ(óÛˆÛKLŸÚN ”nÿÔ¿IğÍ…`z?ì†g’Y¹òÁo¢ÌÚKpç­!Ú·ñÇ$I6?RåM™„3%—U:÷E«fÃ¹C`ÿÿÂKıB¡N¢Û¬Øü•ª¸2~‡î	Bü`¸­°½Pa/y•z»µiÕåß&Ø³ÎkÜK~ãdêd8ôx¥ÖK‰È/x–Wî>îÇIN«àÕ$¥j.ÕÅ«`e×‘şŸëÄì»[x¡ûıÊséÍ{µDŠ\ælèøW¹PñoCŸ6‚„s´	—¢ĞiSÜ÷Î=È¿@&WŠ–yÙ-IÓmKŒÏÛ2~Ê4ÕT¬|½åI¢u†GyX¬Hv€JméxèévÍ`­#Õ» ü%+13Şµ€ÿÍà~_øòw¦ú¥yŒ"³ùË¸C±ıñ‘qng2’µ£.HÊª¿jCìtlsœ“ğƒ"L½·¤eT[^ZÆ‡àŒìä“T—Vh¡Ws°b;>ø½}¯w¬äV.ÿÌ¸ËÀv(Š½_öíÔ*ÙIö?÷G:ÂnŞÛ‰ŠJ™m3¶ÈõÆyĞñ¿›ÇŠ1©‚òÆ™Ú-K[İ;8©ì’Ax˜XZzœp?¬q÷è¢áş æØp:eTş)±"¸§_·}kÊSP§»+÷š•ÏØÀkÈv@OMçÕLÉ°Ùk’¯»Á£Áñ¬J5:2 D§ƒb¬•&Nü0ãp_íhoÇ§üä âU–>«{Û…‹‹S0=MlZj\É?Nl±sÆsœ
tô vÂó}D^Î<Áœ]j%à›¢Xj÷È¦c×>¾â´Œaé…S“QBsó5$-½&Œ=Æ¹yBÎOu,
¥G«-T`¢Ï¬9º3š¥?5ÿÓz¢Ü³îù«Gü–…¤;‰à*ÛC@¿{TÄhºme>ÚÍ°ùø	µ¥à¹m*Ä¹BÕ>á®Ù1¡ªV¨UrŒÊ’ñ K]%U`N!zo4JéÈ]’´éÍ4ü§¾´*‹±³ÊØ„âÔ69È•Üòº>‚¿<â›OÁ%oÚ‘õÜEß×ú`ã—ƒ¿÷ƒÔ¦“ˆR‰[ı~È^)%@ç<u.šİ\/‘ƒñc“Xõ	½Äg¤`%€é¨n4fÏMàX"IÈXtq«€z?¿SŠCe°»¢<gÓi§l¬8\TÛqÌĞòiº³´ÂÖ™¾±81ZK<ßÈÊ>Ù¹Œ<‹„0›KªsmUš]O°†F'	Û®ö¨¤\)ádè-°
æ8µRë9 3N¢
ñ>ş)FZyã ƒŠn–NÆ,Œı#An>ó&*±œgEyFo2ù0şïµÜ;Şœc÷KT]e„ºI“'HüúOãÿoå¨f"Ëzk.;€„VÓAeñ}¹î2÷QºU—­®Jq›IÕ‹tæeákS†¶û6ı‰Ã°Ø
úİ—Ø8¤Ï Hg`àë|³ĞüJæÒ~4î³†%­ø}}BøµšthŒ6£ÖLMç¦4a£jÍ¤ê÷™~–d‡2+EÙ±º )DJßşÌ§ºQyî¾±¸=uòµĞM4Xı, Å
mÓMè òˆüü3ÔvÖæ]œ[ºN°ŒZbÑâš¥âõ‰BÈÄë¢BøZK uQ6"\‚…&»Ã~a~+cğ”>‚¦AJ‘ûZI_Ì»¶íşğÍ¬ÛÖVoÍ]ÈÄıHÁ¾âª'¤i»9€g+(š“^·úÓœ~fèa£r<ÄÁ¾]…{[p.S,o“(‚ğ¯å^ÁëÀ¤]‘¦e6œSö+È"CÎÆ!õD7UN0°ÊAi¡ÉLú”ÌèòÎátµ8@&5YóÌU^:‡F”ªş·QlLÖöàÈ^h+¼†¸/Q?İ~5ìxY1pŒ‰ŒÈ¾Ä2T¤‘­jßŸöd©cûÍ4@` ¾m+N©É¿Ñ88äÚä¬“d&¶«ûÔgÃÖšé—Ã›‰ÌYF•á™æekÈ¯)áó(y­›ç°îÇÖğ2HŒ€¡Ø¸÷ŞÉ@µ¸ûBÏ·Ö Wİê@¿Eí#˜µ öTb’g‘…GuäOü}½[šı‚0z ÑŞ(	>"9¸´¶X S÷\	|¬«g;CèË¡õºBÖ’aoí›}¬ìyé¹ú‹óùÜß—ºÍ(™$o/ô MÇçüèƒï³9^¬Ùq–sÍ}åã\$LÜ¨şØù.ÿGQâ·FQH!³!ÒiA_eXö5€µ˜Ñéßõ³´ÅÈSÓş‹_ºBªŸ5Z !Šu—ü¸°Æ«¸{0²s‹şÆ†8ëKÓdS@zøÚ!FÂ;µ•¼k3–L¶PdRRÚEÏxÊAöñ‰(è¤®¼ZĞq&³e† D»ƒ£°åI{ğØ8À1õmW®#s9@dîÔÓµ]„YÁ0ºgˆ·++ÉÇwMgë-ãâœ‡“¢¯´ı‰cã¦Ğ4<#®}{ì¾»ï[D´¸şáå¼`<Š¯µ§{ĞmÇcÑG†U‘n”Z÷‰¬îûó;‰Õ¿tØ¨)ŞŒìÈ 0¢>^½áİ©Z‘àóà¯‘çkB¢É=ë‰Ì¯GˆYî•A
øÑ£_-Õfkş‹ÖïppWï»q¨?-‹B–k Ã[LiXŸvS¤¡ÅoFÃ¼ƒæ·.I6%CZÿğDîß¶¿;ÒõIHôÄ†0Íj,sÒ¶‰µ˜Q¿Ö%ùx?ÒÏÅ ¨:J7álz=ÿzÚºV‚áŒÕi¢}QçıQ\6ÁĞı8{iØıŠêùJıbÖŞ3\¨*n7Ò‚4š¢pàmg^ƒíæ ª×’G/8T}ëJ€4k²ê¶õòV@lT}m¸²>Å€ò\>[È+#¤©~˜ÀbÈĞ:p5&NùQdVïÎ%›yéïİQ¥>kÒÊ-G¡İ>W[´!ß‹>×ñjJ'*U±e“Í’‡Œ¸—æ•Í.ÉŸĞY‰Í|‘ k è= k.4şt’ \°[Ÿã |Ş*–xáŞÂ<ú¬»Ë±tô*§¦RÖ“æğ€ì‘á$†I	vZ ÌT~7X¾‚=Y°£õènıŸ@ÌÆï•–/¼B+[€.–±NQMc“ø¡ÃÔüBéU.3LR³	Ağ÷!3ª²Ä«Q¢ë¼L­Ü»)i*Ïlö2×ï­2ôYÌŒvWqÓû­ PHÖo8½©NUR¿05<cÌ §…
‰ûYI’ˆp›ˆıt’³ŸÃdxu˜Pb«	a´Õe~ù”}„Z@¤‰`’İ\ÈE^Û†I‡ÆÀe–tYµ» &ÁÀdÊí":æÕYÉ¤şûŒE÷«(à:È¼Gñ™¦·¥¥¿½œdá^ê…·¤ïwX‹”v	°óı9cMï!Ï^SÑD3|‰]µ^Av3ËÂVÓÜ©è•®r©úy%¢gÉªJ®z¡øÅV‹'›Í`++¿,!sEßè#Ê&ÿTÈÍT	™DäãßşŞßuBÒ=(ĞOW©q5n@€é0"™°M‹{¹Ä6ë<Ÿø6ˆ_#ÿPC_ğ¦óëc<\ë•Gß«‹ĞbH¿¦ıñgm àìåcö0zÙ=ÄÚ{œSŒ}b]([ô•Z÷ïâeÀMU-sƒXjBJ¾%:ØæÄ4KN÷–a×G–ã@#¥ŒRšÑ¦œJÆ¼Tfz/é®×4ù†ÎÉœ4²á¼ dTu-*³ÉÍXÄîĞÀ&"Mü;â}ù•+ÅÉhş†ô£µi•®ÏŸYµP
PH“ïNŠ¶©ç°ëÑ²“äÿKé×•q¥R|Iï³²1ÑS‘ø“šâ›½R­XÄ 9Ñ:_v¦¾
©Ï"ÊEU:WY4s#áËoî¤÷Ì€Â?ssñ£rùT“¥'Pƒu½ ×	 ´YÀõèS¼ÇOVW™µ0~çBSx…3+`\%ÄõC%S¿L€Soø çJV¾G‘Ëî]t/\Ï\ø<ACù]¤ÒoÂ¯D\¸ÎdXßè|\|¦^Âô;ˆb÷ÛÛª­D Vñî}kÙı^ó²5ywÈ¯ZúÖ“N|a‘h+O$ÜÊÍ—4ripÁ«Èm}|0^“±|‹³,GÇßnDRX°<N#ªĞ
eû›—ZÑ1¥ ¼²@Pú>yC“’FğKæØˆdvÇ'zŸlĞ':'ÛCÆ¨OD‘‡İèRÔÍL1À: §WYäT,Ï^‡dŠğŸºu5µL(«ƒß ­Yk€oÎÿèÁñ¼ñ«"×Ö®1«‹»8¢~©£-X¹ì« F0ÄV‚üÅo9 tÂî\ş´^Õ$V”¾º#½¨î•ÇàÜi¶+`p¯C:É‰….˜£ÈÂmW0iciq*M‘zîjÄ]Æ’…KFŸéí·9 ä&ë7c mS-ôš«]ÓL2¶Ø¾ıÒm©HGD|ıGi?É¯0â©IO7-•bO‡ƒøîÌ†m°û+8?×/vè\vj^ìúÕ×÷1æ#RT•‡øzÉõúÜ$ùíßkóµûÙœV¸hx(nÍÿä\ÏR¶¶…ºn£„
aÇğ"p¯LØxqb ½öš Îÿ+Êà«6Çl:/†i-qºë¤´­1–Cà‘ıßı1Qæ÷bh v„@ÏÍ[ÍŠ†MÃ8V»ÍãDc² RPªæËwô¥ŠçĞE›øÂÁ’Î2š‹XÑø¥;àIsc†‰¢ÖG6ÍM»j­pR6¬ç"­ÑÃßqpO:£‹ŠøXŞD_‰çN„Ù²QR–*º¸ÚŸ$1r?€'ôCh¹0÷/
ŞlÌğå°D;Ğ¿1MV×6#ºÖQgëmÕÈ=•1æ1]²™ÉÄØ¼óÌ^Š/†7>u;²r%.¹Ï%4zöÇE$òw·êU¢m¡Bª°Æß0ğÍèÃ—øÌNÆæŞÆèëÌT(§w2‘Ş‚´uoõì®N°ZÏ3Õ'gŞs›.ºIsBŒ^¬%k/~Û	’‡“yêµBLc4k1ş"ppÔ§ˆ‚@+ˆ¬T6+T·ˆnäjpË`ø"­Îj05ÑÛÌÍ(cRÂVÏ[^D‹ôÍGã,?ŸfœÃØb©}³¼Nım§»\¦ uİÈ `/Ç€3=ÍÜÈ0¤)„3æ4ñÓû®\ı^¾;dš™G”õ	’Ş_çq™ÅAÅÛîòvù­T	ñ7#—[¡¦SCâ0ˆ(ºìú"ğÀ§ÕÉ<Î
÷‚®ŒÎTW•z„xs¡F	åL¼htH“ü*°Û¿¸'ÂÊÓiÔ¢ß®4úÍÄ½EóUxÌ|ŸÔÍµmš•Şª;ñ‡W·º¿4—ğœÂDÄˆGö&4öïg×ïÔ*ªB™Óy(iSNäìö$£½7iˆÚvDÁ‘Zˆ</YõÜ §j6~à³v€šLm°¯ØœÕ5ÁÕöNR:,Üw-+Ü¤’GÌT®ëe¯8şF;ßü;Ö3fP
™Õ‘k-ı¥RN?ˆÉ<kİ¾É 3H
İ¶×Ş’„ˆù.;ÈyğiZÙvˆg¶ĞÔÚy9‘ñ°º¨r®ÂlA”ØJáç8ûõ—BÉ [átR™§İä™Œ(+dÔC¥ná§†«àD±züµ¹3,³7_•Áü{û0Ñ©›™Y0·}E‘Å)sLY$mÁú¿6:ıÆí
ÜÆÉ6ƒÄqùÓ³Tñç7ØËOåBğÚMë®beµĞi=M$]è¶bÊr±.fh¦3H¥ñæCB©î½˜á}w®â(×ÓÏ¿^†Ùµ{ÿšÂüœÀ"ŸÒhôfÖÊåoíuşş»è¡&§Då–óºœsW°è¬ÈÂ]l01,9Pç>“’œŸ¸ˆ£_)à gÄÿÚÑQ ²¤<í·,ÿ#VÊX~w&:æ§#şBA^Ç*5¢rïMËÒÕ¢÷šn—±‡TÄ}^œÍihD+¤÷¼Nšnøëer¸¬Ã¡¾æú[63Áç/Ø(YÜ%õ
›Äë“óGV*æ=8¨”ë‘ã-o,™ZeĞ‰ƒ*šˆ?ÇU‘æf½ˆíˆªòÌ&Pİg€Ò,ïÏ˜º™¶*wI9Äq×Æ+‰Ğ?şSìé˜½KåÉe[¢	S71=ÛOàÇÜO½³]X˜»{¹!k­ÇSóÚDA•îR/3y¤‰ª4ï%4[êƒ—9ó`É‘ëĞáÛ_(),´9‹pÊì=ÆÈ¾Qzefõ	 ¿ß5%R]z”¬›Ğ/××Ìî kº#bÚz—R®ü!Àv‘ ôğÔ¶*÷Í¯vİ+%0|ãßk±<Cæyü«*j°@‰XÚ¬Ôv–åúïÒEcÕ¨4Yc×ØŸúI«İCÿ\²* q†˜Ô×¼'û`÷l"ÁŞïÎÉvÍ«€¸»_(	{˜`qÖo•™$ã—?±FÈJSµIÃ.P¹«û? 2•õ?tØŠĞ´75ÃÇš`sP<AbÁ¾ºIŸq^h¸B#ÒFºl|}#ß?"?ª’,~ËşÅˆ³€‰oG'áyçE†ğk…*ş‘Ì™´hGsÚJ8{òæãşVïî9ÇoõÓ/ÔÇD˜£ïºŠLÆ,eş_@HWõW(Á¼ã±.Jë5ré3…2SŞe«âN„ ³{‘$ü»Í¥[ßˆ*`[-9RU4dÙ0Ğ[Ùm¼¼îõrß,hù}Q½àìºáÛÎNZ’ü—œ:ëÔP:ÖùçùrgÏ"gY‡ıÕbê§Æû¹!/Å?=øª÷ã;F+¸œYYí"l½eÿÌ’õY×¶_dÂò‹PéÜ!Œø\º)©Xmñê5Î«.uâ*ÇK›Jİ%›ü‹}*€kÅU£í1¦v—hdÊ·?bZ‚«İbÆšBÓœÌ‰_,\Ñ¢²Y™:äéï³ø‹Á-Æ>Â8Õ¾)ÕoT¿Ç’¨`±Ñrã·à©ŠşÈÜÈmÓbB$âÏmïAñÈ,²ëÅ;àLÑ!_#®¹	ÄgLXı\.gØ»ŠØ+n²ëKGËK§(jÄ“Yıº¾ÚF	âúiñ³z„g¯z±UPD†e^xQÎŸXÏïH”|²©6^Œ.<Ôµ¿*ˆ©dß1éíçèZ.íş?z¸ÉÍSĞl»ºŞlıÀà³‰â%Ü½ÚyƒVƒËz)kwí ÙYâŒˆ5n˜Cûujk%Ïİò{•øBGB|ê­T·ïti2‘œÍçšunÊ­ 
xºô±$o{ß€(ü)»C¬±ÁŸåv¹ ƒxĞ°·÷{7¿œsoÏ85/ü#¹Å˜µù”«ÚU"Q"FãM®@d0ªÊZ³Zù¦j9ñbÉå”!oÈñ3%Äg<ÉPúYe¨8Ê+êÇCìÜ2Œúµ6Ş˜g#&oam…Ç7ı¡àX>!İ-QhæÑrÀ3Ke­*E¬ænò½[‡œ§¨ıõC##E¼qÖhì¼"7’n^Ø«n5ûÓĞÆ4Jæg¡¼ISd2êğªˆX¦0"•Öôv¡Ü¨sñğmæÇÁ  ô|^Øàªv¹g*K­zyØ»ş4hƒÄVv¯<Í¤{ÀĞÄTfì~“Èz•>ùãr(×0 ¸æÄsƒKırRèØ¢ˆîüİ©5Ì¯,ƒÓñ—rtÑ ÿ£”È‰ÔÙ/HWÂ²ÄÑ®©Íxn»LNlV¦[L.uaÌ¶,›vñ,±ÉÙR	sÎÕFÛ¥çjkŠúcî1²é£Tû›Æ­+˜Ó÷({ÏĞşhìÜÖe_É­I>Âƒ}#•ÀHşÏª½x`÷‰ƒ·x øş(²™µ˜‚nÉqYKYS=_q_3lÂ˜(g&NsQªøX!ù*²Ø¿à‹nö˜ï/Û£WMÊK1Ãà@÷>Ñüc¤×‘SjtO¼+Ø®q÷.ö½_k ;QÒÄù„ïBT“ÊÛÙ+z{ëßQÉ:à†fHD?%YÁïh®Ğ8‘Ç!øÉfÁ|ß}j­¦xÖÎ‹”¼O²ù†"l`ò]¢*w!˜šî[cÒ>LÙx¿ó^Q
ŠÙÍÈâ[øæŸÇ‡µ;iãÿ¸¹Ì,Zjqò­„õùş¿…7*Úr¨âŸ*nŒî™“†„z‡ûÂŠVæ8°Ş*!­oçLw<¹ûğmÄ®Â£¿{'k¦¾»w2Va"0¹ğo½››•õ‰¼y`‰ÆÎÙ}‚¡.VOº¡²>ôTÕV=¼SñÁ„ôòén6ŸxWl¤‡ãÑØv#Ğ’ëwsk·7¸Eîñ•çDşKÀ1üwœ\	¾Úãï&º™%ö€Ü€B5Høî)#{ˆ`™P :¡
À>â3ÍØÂí’º¯ 0’ÍhVõ-²e/”7[>¤ºq«ú‰ã/¨"ƒÂŞO{—°¹h[µ¨ŠgÍ÷oÑ‹ÀkßSE!¼®<¼¾¬?c'¡#‡ÈškÂ¿Á§µ5DµB…$8Õ/Uïge¨ó´´¦n´Å|Üİ‚ê¡†øeÑ™f›gü¸àì>%Àåİ)KïÌ0ÌŒòR1ó"œ›1Ø“ØÀ‡Iˆ6 µ¿yû²ª©¹¯Z§»1J‰JV(¥8Jè‰ı¥¼«¨øù€ÉKtutõa©‰‡–i>~RKº÷ªöNİP¡Ùc¸—yÅ±À"¬tµ1å•õ†íKÃË¢òD§q¢†¯Ç\G-5é%ûGø¯ÕÿwòHş÷mŒÜ™Ó¸Â/­ÍŸŸ÷ÙF,
Fì%èİä­ğ«—IˆíşF $'z„Ğ2úL[!ªowvÕe¡5…X®HCz¸d¢ŞêKâÌ$4fón;ñTè]j),’&fp Ì˜œ>¨Úo¸«ıúîˆ4Í‘b7Ïa‹(%ª´QŠÏœACŠ^$ÂÍw2oø6ª×qÈÑË˜'úùLmTı<©Ëåq’²wû˜ãXËvdÄÃ£ã5p‚NJÒÏgLˆñ2è¸=’/‚¹w˜ã¬Ç‰m›ÈÃËŠ§ÕV¶ZÜöøY€S³é]¶ID?–ŠõåUıIzºWùÓƒÏJ	Ãƒâ%ŠWŸLOV1Ä0ÏYÌÆá*í”eU:}!MææÚ«kF¥ù7	Šà­Ü±^ryÊ—Bî©%OãõPÙ–¤²ê‹–Şæ¤EÚfÍ©~aR!)v¢Ÿ-Ñ‡‰İ…(C´Z1º[Í¨µıSîVµÄCt¸Î=t‹õ×IıŠ¿Ë<OzU;ú/¹ÕaëFk¯+æn¥Aòr,2Šå¸’µmÜÅ“Rf¬:iô%GıàP	êˆ,åÄæŒö®Pc”m(>lkğ!Ğ;ÒÊãT;›ùH×AÃì§‰½Õ£kºQÈûï×â§"5 ˜ÊãOT0¶°ëÌß›]‘„=$3¿Ş]q¤ÔvhÒÛ¾ªíùeŸD#‚{lhvµîØhÌ¬3o…dørÔÈKóvFpdh†~ß‹
ÛK¦O9¶ <a‡3x)%–Á¶zÒ7ì„NXYºË
Kü´HşLjÜ­&İ‘äê“ @éïCîi(ˆXSÕÁ6Á·ğH²DU‹#Æ²V^³…¡ö²XOçŞê<I\›‹êü.Ä`ˆæWaoÀ(ŒÍïÜÑ‡§9.ıÕº5—ÉTwĞ,ÎÙ…HK
K­88]4Ô˜üà¾¥³a$Ù»JŞ†£h—+ØNĞG>wŠnàTFMÛŞdi¬tçÜÓÉ¸:mD›Ä:Ô—m¾f4eLr¢ü¡°©h¦–øXªŠLBÌ>Á^fÙa8ÀN|öU¶#'K`Õ8Ğ¶ŠD1ĞV­T9LƒäE6pØ–cÉ0ŒèGîàk¼Å½÷«6]°0ï`zy¶]<öÎ/€Ø¬é®y_,‰¿‰úCã¯÷6a‚Œ+ÔEĞZXnõ$mI?ú\«K?ËÌ”ÿZ{Œú¾¨0>;8iŒ¿’¥à´µW¾æy2sì†±Í!I6c`ÿ¨Í¿·¾#»ïÓ`®å1#Ë»ÖøÔÎ'ûeŒ-ƒ«Ò"è:«¢%8Oo…‡WºÖÜ{­…r©QÄmD_³–ƒTŸ”ÌZwÚ~R4ğ	»(Oİ/P;*W
ŒšœyçâÖ´""v§CÇYJ´ DqÒıV¦¨s†¸,ÂhUt»‘…#ê
¯g=ÙÖ!(U6A7wzŠ)©zĞäNok»€–fzûTß\Ÿ1ÌÔ@#¨ĞÕ×­ÖT‰¨¿ŒpMéb¿Ö­XÇ§g(oÅ9Z0%îÕ¤@c§?iÖã>Øò.h¥£¡¶Š„iÑhM¤µ9V»¤ÍZŞÏ|#JE—“Ãª‘«ıüÛcÓÒ	r>@Æ¢ SW9\ï¦Æ+zAY/eÏ 't3}šÜq"^Šä//O†" 2¬ÓÏ3"- å¢K'
``"p,f±¾%æ&}êZÕ3
#Ø’SğGİ&ÃŸ|aìÒ möœ=2´wL“ ø›ŒïÚÙ[,éòBÕˆ]ÀÏ7~Ö…Ğ±N–ÉL`ú¾¯2¾\ƒSÓŸûJ›2™t­ÒÊCp©DYQT–wÈWøÙô¦z¤$ffcÌl{¹ÉgrT‘®©;ã+¢doÇ‚œ\!ÌzÒô4lìşP5˜¢Uíâgœ&qà$dlVcÎ
æaJ•$*úíaÚ>Jl¨äšL:]0HU%eâF˜$=ašÌÑcî$xDı9]„×ZLãùäîû‘°ê'S¼ôÌùj^}€ÿ=À›l‹rî±#Í´šfZ*NÓ+„· è|ÇP4øx%ÙºX–pbHD›• ÉgÂ¤O·<fWsÔP‹š£XZ$Ü'DéÕEƒ·˜ìšæ&ıhvğ3P“°b›€0%V÷}BÅ“Vqx¨ñ3«Ç,
Ç5»‚¦¦uf±6³Èqÿ­“œÿ­;O¿X+"ÃÊXi`È¿x(â†ŞıFÜmœ¢ ”¸aM…†·àZÚ2ayÿÍ˜JtjŸÄlŠïˆ«m¦Â»”aš¿õÇç“ù;yhhÍÊ­Ó€F¾'ÿÉfÑH•HùYYËûv4áC¤b€“Á¨r¤[éñ*Y†üâßŸ²aüm\|¶}—Ğ/Ú×puQQtŒœ'ÛÜ0­²¡ï*"İf<ƒ‚L}Ñhì}'öa¸|B›ÈCşñ[¯I¶›på Ãµ\WpŸP/ı=Ì+ÊÌWÃ k:ğË{È{Òq^ìO"ı–?ÀØÇÚéVñ^w"’§ÿä$#Ğ#^oë¤=‡i“½¯Çêª,uR+•–±¾FZ/7­Œ8¢Â*ã³U	6[íÍšVûÊ¡¤á=ƒ6Ï~Ç´³Î-	wdhÙ¢¾]Ò˜,ï9J,è¨hsúíö‡´—$ßÆåV¹.g9È&šHÎ¶Y+À/—&åÚ®ªƒÍ£aAX×Œ
4k´ ~,nû‚¨ŞŞ³“1/ëH†Ì´Œ,rxŠëåÍjC"n†u»ÖØkdÚØ~ÙA-$<Ù„ô®´k"ëšşÊO…ÍX…Ùü‰ã“¥I¢M¾åN_¢Ê@'ÊŞVXƒãâÂOK&6›s§P(ÒV,g0µ[JÑ*uÆ©÷<`ê€‰»v1’Öx®6~I u®Á«•S¨vtr¬ú´Zj˜¢„²M@ÁËô',À©Û#ëüÃSÉŠDû-8ˆgŒr¬è;½g>ÕCÊ¬óæ¥õ·ÄŞH¿ÀdcÅè2¡h“î3Á™ÙŠÖ»RL^
ø\ô€LçRŸÊ¨&&KĞ<Aê×`À—‡¦ˆx
u»‹Ë±2§n(ÛÁA¿5Ø;
xã­ i×ÜUî>F5›„Ø¹*–=Š´n({À´7ú-ƒMP04|Ñ%½~¹|ú^á|N½x5UP8è`¹.(W²“ú½ ÕAûX(>RKM×É±špDöôpüf÷‰`j­Î\&mÏíJÍ‘4RIÏ`äˆ>•ß°•°ZNC£ˆ^ú&ÿÑ‚6ŞBv°
¨äÊh^Ã×Ã-j³ñ¡ªîán,–“€'PRˆ"z²02ø°B'LWKÌ¼òÿ8ÄÚ¥á…‘âÿæ¿SN­Àj^§;W‘'ãÄ`±aéìĞT(µË8”Ot\ğ&û´£uÀ¹¶6,C~ç¿ğ²~d9¥LÖ	-’w°ó{Õ”è± îÃşCğÔ4Z9„Õ&]ë™ÙxlÒèÏ
¼…?œOÄ¶âte©HiemŠÎ²Öâ_óP|øÎû¢òe>ÿ0Ì„«ñîÄ+ßDmòD?İ0"ÓŒ3DÁèCÅšUd@Ÿ2xU7ş•`\Ì¢¬İ=à?Å=4´úzQd$„²;²¢§hÃz^,oyÁc)Ê’—¡&”.Ê6?şö=¨m°š†<(Àˆ½Êİ“UõÂ0é—.¹=¢Ó÷kÙÆÄ-Äœ×É»íÈ°:üùtÆgO…Òà’Œ‰C;¤t]nFc-fMÃşÉÆ¢3K9¾b©ËyÑWò^—˜UŞ[C6“ÍL	‚ßp‰VSË P2:x’5û»ÅdºqŸĞé†¬!Q!oÒp†	{®‚]t¥¢ü3Ğœ-œÅrS1Ëñ³N.á©0~ü““Ö¿äT¡²…óŠÕ†}í
$Qü^õ2©ÃLéî4T>Ö³ùváš»İ{—"æW©]úD¹qc¾iË'ŸMpª$"íé0WåÕéŞš´Méìhõ+,®.®ølÀ‚¬#`ŒY[1O€ci¤êU·¦3ìwxˆJWç˜ÁK&“dI¼<3\3RGœZkPd‹òñg²H%Å(`Í<0ß…şÁç×>|³EùÉ-ÂœÛ°ñR¡•5—BÔé°TÕù¤Ÿ`l;¿p›.À]y'q/$_…¡%É Nt{š­v×§f¢èÔÍWFûòL./¦ Èkÿ`†æ¸…b–¯`… ”äˆG7G6xÂ<›	xÚ!©Œên½ñu|ül°ª–Ø}cK™¶‹«·ÆmıÑı±oı‘úéÊ¡¹Er,XÂÚ1êK„-˜ÄŒ«·0ˆ~~WC›x6Ê–‘ò J6ÁŞ7Ê~õĞ>¶%l‚<åq„çšvœ£şÒ üóU.ŞŸQÑíKä…ë¼Hë‹v_Æ¡Ës³EwÉÆO;aªÆì:5q`ÛÔa¦ Ÿ˜—QKİ&ßÆ÷½h†èˆ,£<Œâ‰q"•Ñ!«î?±Q ¦·«sb¶;ÈµğÅ ójFÙÁÀ©>åÈ¿DHO?¹ë©–È-iõÊŒ$¢M7O´}…Ğ—‘8fÿçÛlØ:±l?X¡ò†ÏI8‘1,´í¾«+l¨as{
jÛgháƒi#>ÂÄ!‰„ä?‘di¡ğÇ¹kœ5¯ì^T’á'¥wÎªˆ	šYäE›a1göÜ
ìŸ
ŠQ¬/)¬Ã'ZÂ²ô4µÿ_\ÕHRıÏ4Àp8sõ~RÀÜ9¹åi¶o®ùãõx¨#aUòåS@f_^àÆÌ."a³Ã¿D(N>At2Èÿã‹Myà e¼™ã™ñÂã.ıPZcfÃ@J×Õïdx(Z®„àÏ€°1$Oãœ§›¼NÃP_˜Ó¨V¯óICP³_†0â†Â»’®1÷;œÇ“q”%ùæD˜Øpô]‹Í¨wÚV¤hN’+ -ş_;œ‰Jã‘-¬6#™?&üŞ_ñz]¦3šøÜĞ0(š€9—Ôü»gYr:€KŞƒvÇ³ı§{¿¢ Ï}ô‰’^«ÇiçğÄ)rÅ·Àn¸t÷<1ï	]şUõ“Ñ®›dSõÃ+ä¿àexô8ì®æ'ì¼“ûk[ËÁ³ıW¬gZ¤!ò	Ã„İ¾ä3Ù#ı¸¾s ›¨É‡xò¶ö9tâéûùi$U/+joSsÑè€‹àîK¯ŒVÁÆX3&¿ÖïÖ!mW«]Âğ–—Û³¦¼eİhÌ¿¯˜S˜æ­[duÑ¾ÿhôŒesŸ¯VDÀ„§d÷Q‹ÅÊÆaq<8ğéëié‘%Å8×]S¾e! tz‡‡>ãÍn
“9À–ÒOäZBEç­˜îEtP2Ò
>IU C´¥šáñtôã°¤ıÜ5Ç‹õ`Ø}9ÃR'ÈÆnln \…ı2MácÖC[C¢){×íI+_3¦«xwö5ÖBğ&…}áŸ‘Xì‘Í`%‚š`{%‰Ş=;§¤:œÃ/ÕÆ-9Øœ$ªŞ9’›…®ƒş÷a@HRùØ‚ûógÔŠ‹Îñ+WU‚èÛ²ŠŞ$Nœ`ïV›¹é%“,x­ËŸ4øßçu¿¹j"—à/Û‚Y-;×vÖ—¾OğùrğjÌ@"6IVf6Nßqİè5,rRŞ—š4D…ÎQ{ª‡w>Ìn/×nŠˆ¢yÔ‚jã!¡Ã~Qoå“\3PìY<¡àî¡2Ş(pFö:Ãe•B‰`F2:—œÈC{å–ÕåB…ÊLÔ¤š(±ŞVh{IÜ€à¿Ş¾S‘p•©Ä÷²Ô÷WÑ°EÃU8ĞÓ¢V1%³ÙÚb†üÇÎ›[d†Ó.N?V´ŞÀ«e—&_›A[Y^z(§^©QÁ±€lE`ù´±:ñ¹—5Ïw5q˜ÌÇk9Áu@TƒFó/kæöôKYÉU!é}¬gÆ”ÎŠD-û;k–6(Êº]ö©†şkmœ¢æ
KôtÒzÔæ0rÁP´´ÈÓZŸ4øeÑ}æôR¢Í®åûnØáqÖ‘ú^šÌEKşèoÛfµO½p]Æ.ÿı\f?x•˜'@¦şBËtHŒë’åAô¾B•²ˆi(• ‘±*!„í–Ã?eE>º"1áüšm‡i¥gW	PüÙP…#‹õ£·O.òt»OÙª)Õ_Sá?ˆ!³ğ{Û¬X)ïß=éÙf¬+¯ z»‹à›ŠsÈŠ E`ê¿"¿À´…×‚)º–ŸØñô°Â+Í€Y¦¾òÂ¶ÄtÕI=ÈÙÙGG&_·âİÂ—‚põ0´R@‡‡êkÇ\pw†Ã€vúõpT²ÃüMn•îÃ…iÚq—Úˆ¬n¿‹:^	eÓÍ=r²49á`Ì¥‹øÔ#)\¾gLÔèxyÈñæã¿Æøgrš™ì`c¥ùâ;V9Ïy‰ØœóË
zşn¸óHø…øÿ®ñT“û`®¨+á±/S¢›D|/ºñÓÖBEq¨œrš„rôLŠÓçP‘,âˆ\°©ßïü·K'³(0ãq}¸Öb¡…oò•”İô>„¸şßñxT3ŒÎMŸ§¶É­²MWˆ]¾nÜÎ]=jÂ¨•Âšî$?`˜J¹¯$—¯°—¦Ï°2æ)@ÙO£yœéšH˜£ªˆ`ñÁ¸>Vœxía	úBF¢İ´Ú_ÏÛö$ÖmÃ®Ùp¿u4ç”¨úÕ“=-½LGËÕhrê¿A­¾¡M×ÍÄÛ[J±UH¨]_%’—gõs´š mbCDşê•ÿenË×Òƒ5N hÁÕ…›Ë™øe»SÀÍ£;W.’==¾õe#&jg–SÜÀŞ(pĞE¸W†/ŸŞ®å ß¾{"j5—Nj¼/÷:I®ÿÏÜ5í¤6Åod·ş´bí˜ßRß™Ç0«Š¹Óo#ŒüŸ·mïïç!{3>Ôâí‚ktÛâvzŠ^¢obî·aİNŸù£¯}6 f Ÿ½ì4"³éMŒÔúÑİÿC/è|N^*æÚ7rª/2?œoß¯­7>Ä8ğÜ˜2Øİ½ów|
¬vÜˆc7ôTÃ½AoúşA4TÜV ÙUYÅ²?Æ¹èº$­OÅ?ìZ€<”>Üì§­VïH#øä5Ÿ›!½ ‡÷/4(8)ƒX`ûÃ¯w`–ÎBWsXf¸x6Jôò¨jšS#GzMÜcæ*ĞàT†ËÏe±wc0ûM`¦o•µ»Óé·®)ğÀÕ³'’íÇâj|´¹>º²æi.½³ÿ¹Ú~Y‚±B­éGwĞÍ^oo‡
ÈéàÌNœŒòóú©-5¥ñÆo¼Ûw!è\˜š÷©r5â•§
-¼ÄjÖg EÀœ¯æAŸ¤›£-Å¨W:Æ[»Ş;ûç,&Ÿbi‚ÕE1<áü‡í_Ï:Şßw!õ}hí¿c_LL4±ïnvœ·"³ã+?7îË6Ì¡F?à’ëô¦ü¸ë%L¬ÜJ ·%ñŒ9CW°¤…‡ÌŠØë.#sx.…,t1Ö6w÷Õk.YNš{ÅÂhR9sZÇ¼I$¬xpLdW¢ hÜYÎœ^O­[ª8ï\²®)MİM—º_¦¨¹ü{‚ãˆ­‰¦‘ÙuñÃªŞ€YUÈv¶Àw¼ğaÿDwÏ„4¯o–Š „ ©À ÀKşŞ0h<›Ú;ŠB·İä™íYLÜ/Oø÷2í¸¿3vœ¡üiÑs»]e¥½OD7?r™Lœùg#B›\Éyñ¿–ÃÔÒß§)NjQ~ïg¼Dßô²’9+q…ÁŠ$TO:ş·¥]r\˜ì
â»T–21½ri¨‚9(ÑğmtõíÌëÒlcÍ“gù2—´6X¿¯iN„ºĞ›5ÛšàzQVÃ‰:-E½mcZ6qú”éQƒªQ^#;fK–‚æ¹™‘°q:ŸOeCı’-ø¢fÎ;©Ş‰H9ÌÁ+C9£QÀ)‘SAsI«ºÙ¾§Zş“bK'äoTUçZ¿ÒÁnÀü)Ây:ˆš"ß‚&Â]V7Y÷¾Je&³éòK3ó]£lùûm){ìŞô1Ådl±·²}rŞ­+TÃi%é×	3¤–Ã ëkÄÈºœ^ÅXÕ>–å"(*JŞu]ÅÅş~5ï"‹(Ázmf“B8_©í±~jÚ‹¥`1ÄÈöâh¾ßxX3¥é@GíZ VaJy…í“M&ëÚ´ˆm;
ş•ñœ¨ğG-»,f]Óî\—¥-µ­z~ìBğjeìozŒ[xkÊ’Ö·2Å2®x% –´†(ğCuXT»Î’*é/o´
\Ôø¬	¿x+Şm¼_¨Ë´Ş®g^hşåz¥n—6"Ñ@AÅ€æ7öù,üi«€Pƒ\µ	ØÁÂwºò ÒºJ…Óâ¥ºâZkõAf+~å³ãÔÿÁ§éV$;vUŒ­œØ9-UBx  ßŸDøxÈ©dÜßO·š³ºf€òù¤“•J£0¿ÁòXN;5²˜âßJ›£ä0âï×ŒÈ—ÊÙ¢×³³‘í?å=Ô‘ÿA,:6¥?œßíâAAŸaÍ‹f-åRòŠÆ/jm]zHzZv¤?NËHn²\¬ZğLW^ìO9ÜÂÿnøñ-Üê>(İ)C®ü¾¬y¶±¥¯fºÕ9^|«YØĞÛ°¥¾æÛd ¸Ğ¹zşEÌ £Ì~/c¡Ìâ5°‘k_B½#îï×nÇñÔ­™-4H@Ö–ğÎ¡ã®àS-á|nëæ,Sğ`™=f¶âzÂ Ÿ¦Ò :Ì0õ‹õ¼°ÉÊB»ø¾·OŞ–Qowèï"UÁÅpŸİÒ£Šv¦Û§İHÑ·Z	à¥c`úÙWL‘åıî¦d€rf@x…ÿ¨²ÎW‹jœıÖ; ·j¢€Ğöİ®n~¶Ö (lõ¤°[v\“À*æXpÈşÕæ²?L»b·ÑR_jóëz› pëI5ÇáóíaxeFÙ¬ş0ÒF=¤ç-Ú~Šy¡ù¤—NëâqvˆŠ¤ÓælÕş³=¼zµ]Ş×åfçOùQD_RÓW{£<¢Q6¥ {‡-wåÙJ‘¨â—zX •JC[‚(cÂKXãV–é"ï]­KÔ˜š›³+à,nÌaå6‡HEän8h	$‰»”E÷3\y„!ƒıô¢pæe¼Pv÷›ÊØ¶UåxTA¦eMé¥ÖJzƒD&ÅUº ¼¿0AP}(/cåœÔÖr‰BïÅÀˆåÙç[a‡fº,!µBzÄúKí‘ì«§záWE )Èğ“-M£J–¿÷`hİò
fŒ x ùà_hjş›"cÖ€éoÃH…Ÿök|•èGxHæ9 ê±CãPêá£NcŞ,çšuG—­îÏJ¯¸óCvÔìàüÖ¾™´˜3×.9¡	M¡	ë¨<æÓ'*"ët]Ví„m!Ì,F.Æ‘P3¶×š xh¥HbœD-‚ÿœˆûÄ€|(ÛN$³¦2N2o&ç+¯,‘ão[Ï’5hOãŞ·!iJ‹­>1']",ËÇÒáH€{– õ›$‚8Š‰Jf#¿|÷÷7N /­QùŸú„$Ü;eÔD7J¸^_ÇfX8¨¾Pq 7>ŸAõ’{pe˜¡Oú/tã¾^é&üúşzƒ¾Ğí’ŸğãÇl6Ä„x‡øN¦
¡XŸóW±]»Ÿ8[Ó¡…§„ Á®|±”=”-£x8M¾ÊSàm5¼‘S€uLŸ%W<iCÛ|è)íC8Oí$ªLÁõ e.^ÙtdT8£¹M¹Z1}„“®ëoåƒK¼}«¨YÅÇ.X¼a1¾G¹“&éÑ]Bd[áÜ½†u÷^vC±óñà©(&gPĞ9—³iÃçŸE	vÎWg²6&ÿÑbË·Á/İ¢p–ı¸Aİ‚xGÜ²ázËhxuWC€)$MÙ~Zæv“/²V+É¥e[D BÁŒË1˜¨˜µKï<yuUsY­ÒÌ^ñ_Ö„X×¼d’©}÷~bà8×Íªˆ+JmŠTUD•ZW˜3{ª±åvwìšrµBóäk¿F4üLßN¥®52S~Ç@0-8¦B[ÿÌ±4ñ
ËsùËÕ0g/™;íD
|ÙhZ]OVœôÈuxd©^5='%5wÏµÇ¨%ÒŞ2ê^ªÆR.Š/|}QCCø—¤jË2#)D{—ÜÑúè‘)_.Bƒì„ısùG£Ögã–vÜÈ0=z 	Õç€ÓkT­s <V=Úï[:[Â3ÛY+¿P	µvæÀdr¬ô§\¥"®y»†ºJìç.01ï~¯ŠÉC­İĞI‘q¢@¢íş«ÑŸv¼™©(¿@í ı6	<"»Z4y3•+R–Â8<ƒ”>Şµ²å¼¥TÕEşÉø¥N…mP\ky!®(dôÊı@³µcÉä~j  Î5¤­æ!dí¢Z•ÌB.IgˆnûÜgÜ„lÔ#}&B¹.¯ô÷Ä`©>V!’5ì¢~R=˜Ùà!2®£ÿ«î¨mˆŸĞÚÃÙOsf“^!³Ñ’ÜÏrÙˆñV0l³ñ…ÙƒĞT—“GÑ÷€]-)×Q¶s7íè:„ğ¦âÕ€TPØ†mÍ«‘ùRdi‡!X•ã [îûÆ¼¼ÌN#2ÜVeg/£5 ĞvSÀ9/è›ëe$˜q@pBk±È…`pW[ínªÔv ÀƒR7Äè^AH<÷:êÕze)°÷Ø‚aPAûñE£vKº‡şzõíY˜’˜7¿"(ØÌî%TBé©#›#ñÉ,g‰²El@ÅÓWÚÜ#‰Ë°è–œ7e £­@ıñÊ5=NÖşe¤.Q›ğ$‰ÏÒü6œx†eWØ­—Ôà#Q §ônVOæ˜ÄòeAÒÄw;[¿ÖC¾ø™†~
¢'ğ2…ö­ÌdS©jè’È¦¶c?NïNì»	ILŸ-PÓ­±´°Èñ>“ØŠ¦ğáÖÀ¬8Ó°=#hğ×¹Pd^&A²B{g8í`ï«^‹=$Uüír6¯šÖ`mÆ}‘8m<q3%AõeğÇş–‡‚¼si¦ØN´M¡¥g•Q˜ù®È¦~³CY¶ıt7`°Å$
•	Úòç~i“õO§,e>eß:Ô©œİ¸3şH•À$Æ|³×1¿ ªa{†€ÿİñğûBş‘Š­…V?(ë2ó¸wÑä{ „»á%“U0(‹áÁ«Ò±„è•¨!Ê‰Y ¢´ÃÇ«³#Ôş —š‹2–µ¡½Á4-ã§ĞU“O°ny»·‘lÃ¾´&AŠB®îÆ¢Ph^óù„ÿ¶NmU{;öêQ•q“: dĞ”‘®±± ,gÅûsäõ¤{îbNÌ<‹vAwé B(3ËÈÙyùZµ0ÔZRÿeîô£b¶TbZLsğÀË·VU:<>÷+¯Ñò6Š~CXÄWO@çåv†'hë‹M¦<2@ éå‚¼j½­o‰8Ü`Éd§²®
ª`²äİ€º™Us-óg<°§¼ÜBMŸñÌæà«›.†A|Ù!™3üÛÚ%İ]ƒä(àO¾:‘¯$ôŒşË¯á9’{4QĞ¥"Ì‚ğö(¤ÌÄW¹,b^ÁÚ3“BeÚ‚wI _ïBÈzÿîº§ĞV‰[{PcD4ß1Ôğ^ú1®ª÷=a%ªœÖ?· bœ-Ş”e–7¤\´î®‘ı›1W5Ëµà!yd£}™¾ªf^í|HN ĞŒ”?Èb’X	7Öx‡[â¯e\ŒFjŠpw†ChP÷‰`²ÇiÿËQÉd –ÃŸ¯X£c³8/[‚°Q¿ÜÏ‡bÖ
¡cPĞÆ8˜¸%ŞèJ»õlñÿËtÖÄHˆ=NkÛRc}_^\óˆˆo²„s’¨v4Z69pà-›ü`#VÔËŞær­\FEA‚0 lÃî:uzE÷á®¦³@³òS\¯}äø–]M+©¯•ê}ßˆõÆeŠ(	xÏÚƒ5áÅö‰|k¶ÏÁl8A8í‹:iÎ«U#†T¶Ğ«"¬(sB!á§ÕÒÔBä"ğ±—ù‚·u¨©.!v(Õ¢˜†màÍ;eo0æ$>—ÇyîpËvw	^+	p]/-A=Ã-ıøäÀ4ÉXñ`WE†+t
Ç*ÃÜol{5ÔU;…şY:•^Ÿ¶fª„d¤ $m5 PL0IÃàúgÓmDıeı+­?!%âxœD¹~yğ½ƒZv·8…sü^‡‚ï’ï?É‡B3ìÌ¤^ò,By/Ùà ¶á<,È#¥¶
Û§'Eõ‰ ç9?¾?Ù`MHmGóàsíí©¦×‘ò”ye tŸOÌò$iW›E ÄêëÚŞŒ[çÿ®ZDU®BÍÈÎ/º»“‡¢T[‰ï..ÇŒ‡ıo½=“wZÔn»Úõô/ú~{ìà8ıÿÛ‡¤EK<‰-
µëLğ;}ğ†G’õàd?NÚI)Ì?ŠX±Ş‘»v3nHTâ[ y™@ €ç‘~Ëæß†÷ŞŸ ›éİÌ	oÓ|û7]šgV€béÉ£sº­X/†îåŒÏ‘õ¿0¾DŒ{åƒã+¬¢Z;?¤›m™yãÓQ=r=Œdpˆº6éHZÓhMÅU‘\ÿšôøN\81–(Ø`ÆL½l¸`sí‹ ı·ÿ ¨ı’ *ànCI›8»Ç‰‚F(–¿êöÏEˆÑ…ç+ƒ£l™iàáş©û ãõÙ9gÇmE§>î!WGJüÕG‹ ‡Lÿ`Ú]Ÿ?É«¶&ã#¶4m^¶õêjÀû·n¼é)ørÔüA§o˜[î*pœëá×üâ'!TºHìqoù‘{;°uËÃ”r©äBFæÜœØt/÷ìM›øÍUi„pL´ˆ‘¦9zOK‡73ÜÔD!±¡F§€SNöBÒÜ•¬ºsõëR*¥ûœX÷a¸“s]\~?¯«QˆV/tÅ§o&>æE¨NDóÔ1¨ı¶<…Oá
rì\}Î-4`6.e:>)ƒºI‚”›`Š‡aÄ†tŠc-	n8ôQƒ.Í‹ŞUêêêá¼«3ÎKlu¬_@&Ì‚»™Ï3guL¯+Ùàû-dV‰IçÈo>¡‹Ë‚w‘5NvµÿtËÍ§4ª~TlkZ…æl¦P^µyóÚ§?'|==€õ®dBÑ¶hçîPnK:Î.{E{€Ê0à Ns‘–Ñåµ~ÍœÙ•ÿh9¤ÒÁ'•ô×&œ-á—D½•pÀ1u Áaš÷k¯ÄısqÊfªÇÂ6¢tf$4´[€ºn>‘‹Í¢ñH0‹ôOu
áãÏé÷ç\ÏW„Î¯9©ÈTëÃp$Ó‡tk‹ò¹ºôÚÿŠŞ¡ö0´@¹	ÚLä1GMàz’£Í<ê””…[„ù1YAôbc=MğÒMÇ+‰u¥k¹°aË)-)p0|y¸@×b«’‰sqÂÕ}|·XØá -y>wû0÷ß­»P×}‚ª+m£xsob )ªf#ï†6EÇ{H¿­ÖyÎ¿—oíz ªÆŒ=¶$ûÜŠ½­<z ®­D9ë€o	1âIÎò¾Teh['~ò‹U72½½"6ª æCóM#îæ´267ëJ1ˆn´§ö°@u*ŞEVFRÖ×ÔË #z¸-ÕàUı	Yú\€ÚVr–µ‡=»`[W4‡ ¨xbµõUm©ô 9hê *øÊ&)qÃ~H-óa¯´éV€ËûgTŞÉYSO¶ óot1ÙÙdbv¶ó¿ƒ“ªé½|ÏÄBz?Lí!‰ÕÍàw#OŒf|ÒúM¹2ËúÊ9ko€l©ÛP; ¤>CÌ¾\ÂÈ_	Ì)›µi‚A% «„‚†Ÿ“ª"¥OySâŸgš«­?=BSMW&D­-}Ğ?gWùi«™?ŞÁÈì'¦fİƒÄJ$»*Q™ï}î¹XîË\İ· ›Uû{>{óxlpHÊ0T‚ªÉi£_WW2=_TW8gÕšúÒâfŠqÉ$èDy÷A•sé)Yj×Å2øºJn>ğšÛŒ¥å¾CDNØZ*q‘L¹mØôÕ	Ä<(ÛF‹¬x;x£å³>);UØK˜»|–>®WŠÙUìÛ :Ã UqwÜ¯ Ën|¦ë©r“»ÿ]CÇESŠM~×»ÖÏŒ3uÂ¹	@2S¦õçåŞGK4G ù •´Ôà‹ME`œáÎû+0·k´SåQC„D`ŸÏæå'	áf­~ÜL)àSfŞA‘kV'U:Ê1®ÒˆöœÔVpÍnÄÀ±Ó¦•‰FÌ‡qwv·£Òœ‰€É1æ@„(3| û=©z©5P<-MRân4Mì·_2†ÁÄ~/n™9éJ"5˜Ñf£Ö¤i‚Û¡“‡o²Æ–…`¶úÃ˜İQ.ë½™bQ°"üYs×9 q6}«^à^(ò¦”SVG,ìÀ&ûA²£Gà |ır{Gƒ›Ÿ¿W#QŸx2·yq3Á{*0È2]úsë¡ûwËÓòÇÖVÃÙç
&æ•…•z,çßöÌı/¬ç£Ì
¬YÜ[™Zz$¥9¾œ‡÷ØsÈÈ—Oş+AáúoóR_-´ÈjH%Á¹Š¾LiÊÈµ ¶¹2ö–|•4bÎï,ê4óE6†İëjÁ|§ÅÌ‡êªøè_R
dÂbN½´s|cI$t`1qBJÍU‘)ôg,:_‹Ì:²âgM¸rÌQ*°³Ö…òÙÑr9á/ÿnîzvá3eõ„¼£ÇÅ‘Š|ŒÍ€üà-äe‹ÃÓõ"0Šs?0ŠÇ”_84KƒŒ÷yù=æuÓLRnş€`ĞjI€TÿqZVßËkÿ-ŞØç LÀ87æ3fÜù7æÔR¹ÍÜ‡˜1­ÕÑ’mû]ïx£ıÕpn$@İéâl¿É¬|ÄÏT÷­¨¡U:-êªñNÕ°UéãÎ†I=s „º\if?ä(Œ—¶šbH^Âx³æ”¹;wûüé&%nA<:k'Ni9Ö²Z(+€ÑğÁ™æ\¤c•gb@*Úçâì„è7^ÙK{|×ÀxùE’ØöiŞœfŸ.)P?!WØü($^]LßEÄŸ$‡p¬ù„NzW2!4¿ñƒ¢ãXôÙk–å[Ú%N¼Õ©²3“æ°ù¾ä_°>äeıøäâŒê³©ÕñÛš½4HM64›ÿË)/ê#äó¯×%]‰TC	1éškf…°¶]w5ì«r=û†*wï­´ØÃÃ+ï/õ C®8'A0˜O“”¹Ô’ıYÊé4¶Ó±•ş×û'zê•2Ìúé"/¨ó•$M‡cÌüè![."ÿëƒ
®Re†ğÌ†®ZJÆ—Ù) ¹€B«(¨aá—6áB§zbZ-	x¨~2ûÆ“G}$Ivz^Š»k*íXmAõâåoçÎ!WçšÈ»÷¢Î¸/äşÎÄ¿[ -LÈÿ’f¨‘˜mz¤/ˆ}**Qj—6…1!H ¬»Òq>fÃªAoƒÛÓ«5—i²ssO²ád×‰k}$·Û—œ¶Õpƒj¿áºiGØ3ªRĞg¦aE4r‹ÿƒÆ¸¢³Eù®ÖØÛê–û…Â/OüƒMEZÔ—3Êw•KoQ³£é5Ğ‡2WÔ8#RDÔšŸ²+¡Ç½]¼ï\6Üq¨Ì«Îì/Ğ´_i‰ŠçÈ¤CíêËÃXãÀzÍ
ÂWçeqÆ{¤'	ô»°w°ñ—'{{¤s2ı¤%É¹„QƒÓïÛ¶_cƒ`ßR)¼È%\¦V^dáĞN‹“V…ÈŞ%@E:³äU	-•¹Şü€qí¨_
ämò§šÍçÔ¥¿Erõ+D”?}›u˜w¬Å%]rPùqÑĞµ£ˆv¤.oqó¦ÆôDùWş´¯ê1únPŒZ¤KÔßë'2Šú[×½ÆTÍ\wØQyZy5Ä
ÊÜ“†S2š¬”ßÏt‰D	Ät©œ_ËL»§½Pµ ÑU–|ñq½ÿ'é cƒï:ÑÉµŸJ£­³×¸©Oá:ÙAéRõ¬ó:Ç€-Z›ûoRÊLå_ÒY2¹Dn¼KTêXxb4Ğ)ÅbË9FMºzÍqOëj³»Ú¾ˆË†Ûğs‹¤’ƒ¼˜wXô|.z3#a¢®£‘	)İ²ó€»F“ì&)¢rı·vÑ%ÿ>?M%ĞG+1`ÀH`ÆH",•œ¶‰Ô›ÈyqÓ«È»ôÊ~ôé†O¹ªè7€&„õïNSc	¥½@,BmòhÑ«ŠÑ
£¡Äx|FYš"÷Î@-hÏl=k¯_¨EĞ†«CóÒWìmŸB¶úÄ–;ùp™[X¢9G”`‰i]¤¨?& Ùƒú;{ä«±ƒ+	Cµyœ´Ê«`Â™(º ì8ˆÑD­0PmiC:VÍåìœ#ÂÉÖBŒ*æµ‰Ù_ÂG±‘-£.š5äSÁºÂı«MÏT:ïscZ”$F|°ÉµêÈp›¬ªìûl¶úËxîz@zFj›ŒÄğ²äñbgœY‡õ[„ÑS=ì¯¤Ç:vyY65Ä±a—®UÎ]-ÅF[W«İ¤})cG>ğÑŠ²®í‡±‘•§"Yy.tæ¡˜…Ùû·ÿäûcàÆxç1.½#2¦uÛ9Ótå ?Ü¸pÌ‡Ò\Lµ´VB#XM…EÖŞô˜ìÒˆı)`¢~À¼÷‚³àj‹Ã¹s„£Ÿáò™4ïš–°dˆ˜çów7¿Zïˆâ¦ä•Úqb=è*a=£qZ[µ¥çF%¬¥Ä;ãÃŒÅ‚•Sbab‹„“®Àh¿âo€ùŞnÃÑÿårÒ’”G	Ê¦ÎAA¯b\£FÅÂp1QÜÌ'åc‹cäi.´˜¬àÅÍøy·uuÉÛJÆÑÜ\ızÂ@‡¡‹­wk¯.µ¥d¶äHÎÅ¹'¾n«º±ˆÛ
k6óåsjw	ÏŸù8‰ıï	'½a$ª€+©^Ñ
^Å2á©tĞÀA!UËTY…Ûßy|Š5@O5
TÈÉ„’‘ã‘*ôòœ+½ü¢<?Ìé¦NFµèñ…2‰şaßtŸóß¥§xUe+>ƒŸ½%gÌ¿~‰jèÅ¢VÒİÃDY^™‰Áé¢ø)›¢.È6-l6÷éØtÍĞªu‡#™Ç}€E&ùLGN>#÷!¿T±ú8ÈC(y%l–ÏÁ0¯HÏL^Ïck¿>‰_C³ßK„1Æ û–g‚!'­kÛÕşæğ©%»â¡aè9¤± ‰ÅO5µ8å¤µÔÛ“¨mÉ]?“n«ÁfëÚºòhq~Íµclc™(¹¢¥º¤[}lc¸-J²Âs1-…ø.ÛÍO)œ“ít«T²NÎŞJ¯;ƒ$
à¸¤ï¬jyuŒÀëøOgüS«NF»EL¡,èh_Ò*t*06*CH´İàÉôh{¯	ÜEurâôë¬i: »pÖ:+>Lj|Ïî¤
aWMœîÖ1‘Âî6";÷<4$LÇ‚Tö¸~Á2ãó‘Ğë“¢.hrù„ĞëDI³‘ôî)ÚgLi“qfµŞe*S/4&
³V>Lr½&¼K™hĞÜú¬¹z7b„Ø"0‹^;y.Jœ¨P®k÷‰N+™îïo”ËÂRgÏy»i*_zE£ô }á™õ£aÀÆåEX¦èÅü~·ñã«“ '¶`n{%3¹İo Q‹ ’y|t|QçA>(áZk‡åAú:ıB'BëGdZ&¬ÑWü;­EËÇÖrh~ïÿÑä¾àõ|‚¨	˜Ä¾öúep.¤µdqü}˜ı‘£™E&˜¼s4ã¡ê¥š‘<7(LN¢Å1åµàÂ}˜²= W`ú¦Ò|eÑ[%Hµ4zÖ-RówÚ­OªôÆp g’VHù©-Œtƒ~kÏÁ™ü¿¨÷Ës:Äû,ÉSHs†S¼`Ï´½ğÁ´å|B•¿>¨¦âÎ-]_Iï´‰-qI:²9®´¥Æ`ÄNÒl9–ôÖGá9wÛ¢ƒí®,ÜJİÈÉ†{Ú3‚_İ(œ?[ÙÓÚiåò––ZR§.V9[ÅLíÆÊ®6âÓAkò°€V½âÇ¢YÄ¾)ÒN Ûæ]ˆ«½ı¯y­$&‚ò0ß´ã1P8®º@cîaÂîZMúreVü³ş¯µW§ÈCiˆ94‚§½ª^œzKÄ|‹å¦	Sa½Ò5Ö•\ u½%†¥¹ìX<o`Iç:E¤ÿ'ò+hôËg™d®ic ÅhÎ³´´?±~ØvïÄœ=	ş°¥ñ˜#«!«··)²ÑW“ÖY'gcı.ËèpvŒdÒ@Ì°õy!z¡ôR~„L%5Âï'¨‰1œC'? xÏŒsÄlÉÊ=&|NRÚD­@¨8»¬³7ùz,`£º·h—iÀ)›[…Ù“ö“As†+®wÕ7²õ±7Ü8]“Ù*âÊZ7'Ä¶C€ vÒ	ˆ©éxÔú¢²ÂüŒ·ƒ$ş ºË5ÆĞµ¶ËËüìf‡wQıÚ îH‘z GÍ‚UZ‹œƒÂŒ‚€TzáU÷­ì«zî$”dk¯ùwC:Zlö­R·Ø.İÑuÓŠuuPuBVwc’ß[tl4»Nfzª¾ˆ¾†[jö‹$ºLñ3öP‘ïß{tØ‡;ÉÉ+f< º<®ÕP%yá‹²ÅÒ2^EÅœÛ•xİlSÄ¼°í¦OT0ÖPá-:š•eœı,7w•nÊÿ4Bz´ö	±˜ÚDZæêWZ5Ğ5¨ó8¥€“Â-Tùâ”™Iä‡Lş ğƒ+q­+y˜à!Lï¿à9¹×ôÿ2i‚8lVVàı| óôi:Ó[#×ü÷‘ğÚEpƒC,Tì¢²ôâÍ
MÈI.fŒ	†ËH$¡Á&!6ÇÃSpÚLÛpª0ei¬Ép24Ë´ùçAr‚©eÎÖ	hˆk·­š iá'Ú0µ¼¥m·ÉÏ¯Q'"ZÌû&„´àØÑ¹\"J¡få_|ôñ<aÒÉáèè1åÌYs&Ît§+m@q=ßŸ¶ÓòÍ	N‰…X¼ï”Ùf‹G6g<ĞxSym_2›.{¸vËH‹rŠóã÷ä‘âçˆR°µxšÃçåuJ;Ó01†m~Ñï¢zi6£UÁ*İKãÃÂäÍ‡.¬1ª&¤ñ>°Ì0§½Ü« ’¥Ãw9' ˆno•¸:Y3Ï¸¥¯ÚµšØÒÃ¥Ş5&Á‹À~§0ô«¶ÕF¨ÚTÂÚi!@€~G™¦í‹ŞˆöëêÅ–~‰„Üô4;°Ğ+ÏëFOGœK]ô³Cf„^WŞPw;\­Hú(ãé²¹yDd1Ã\¦Å° 5|NÿPÅƒÛì®„$l¨&WlÉòoĞ=Pıí\|6	+€˜PZÇ[‘¯4óá9içg3+V
J]¦×Cª$tÿŠEF¬Î‘ßYµGSì±ô­66©€Ôj_±U³oÁ-ğekik ®ÂbH4%Mªˆ·ó|³Cã'ät@ü‡{é˜WC>²€ÇòĞµ2TÌ–!aŸ¢Ï /½_YúQü0áe°ƒµxã%´9õA
¬™$ÿÁG6`àï5Èó`® ÆŸ†zmzš®÷mL
cøúz+÷‰²º3È+{DÿÀ©Ç‚’È
Nz~yEQÊ¢§e"İŒì î$*CT"9hºQ#o½¿T@äQy–$£&Ñ§µYq±taÔ^êÛ­8/Ç5F0š~&A_­2°\í7½	LAä-´lüo^ÅsÂW?PÑ¢rÆ
Ø¨¬˜0÷8æ0L{çÓyƒçY®ºº¢öp¾>õü)óş×d›W#Í¢÷äÜÁxÛ Á/ùÿàT‚ªŠqç?“hz™×:ˆ#¤ìÚÈNZ¤³İ«E´_ù{r¶(®Ô£ºóz<^gO­ı éĞpâüz¥Ø¬’>5eØà–M+ÍÕV)­{A5‡8Á	’qWÇ¦<îâjH¯EqõK8~æˆ7Æ§ëö}Ã3¥ŒŒ&ŞÍ7 +ÑX™-Z©CS®¨wˆÄÉ,ÑğÍ?j"ı}ğô˜Ç†ÿ¿Åô„54lâaP·PbÜ|Tú°[uyğWÄ-ÈIzãZĞªBBGµYv«œ¯yÕ¡ÄÊ‡,ø8¦ÊHzb¥&åbCkS=Ê2®Ú¬Ú‘¤¬D¿:ğ©ğìyœµ3jÍy=[ºæèj*ƒX*ñŞ‚+x°}şâï„'½Ü¡“#àÕRU1lz‰Œ¸} LÚ6ÊŞ$©As9¥¾­´îDYMs…”µ&[ÿ›¶»›¥õõŒsSğ<€U|U§ÀüñÆh5.¹<z;9`lLÅS=,\êş˜     ø
™¶Şåz å¹€À
”±Ägû    YZ