#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3202333516"
MD5="9bfede7d835f857e106580f9594a3cbf"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23396"
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
	echo Date of packaging: Sat Jul 31 15:40:39 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ["] ¼}•À1Dd]‡Á›PætİDö`Û*ç¯Tè²Ê7%ò/(Z|“@GµâÜÄ+ uŞ ßlt´gÏ<Œ³*8KYmA“Q5ƒ:L%0Ç™²Ènå0M÷ËUq°<k=t v†P¯mLcŸó®áİ_¸8ª>´·Ï
[ ê åÅPFÒ"5v´Ç@§¼€N~pòö¶ä˜ëqiGÌ¯ª„‡×¤½6Z•FO Æ@º+½iëüÓI²l^vGsÈùvÿ1ì/ˆ@ñq¢”›„
âÎÏ¡—‘áP&¸Ì¤²”ÛÚˆ¤`ú[vx¥åX‚ÜIØÍašÓj•“ò""G™ò‹¢2ƒ7$„HbúqÎ‡¦s¶X5«C/"–®o¡½.Ç1ñØ~2.hkÎ€Eøp£6åÓ'Pş]áâL€XM"•‰#Æ©lxÖÏÍÒZÜCŒ=#]úüunSŞ#Û8Ğ2ÜÒ•ÃTŸØ”KşôkÆYš.Ü ¡¢†Îuß!iÌÙºã³=z©´`F{MÀœÔãn2-U·Ûs2L…ªdÙ•‘äN=•`–À!òË˜Ş:« 2TIé»8mˆü(0JèÄÏ,ßY¡iB8”mP„şôZ¡ÄÁİ1m!ö°Âã|†=ûÀ%@£æÕé‡ü>LZ³8ëx	#ò*’ÒõIÂâüÎMhmØáäş[¸¸F±-%2¢êzRk­UÕö54N»ÓGt‰šNÌ M 6U­¸'ÏÀKP9&wmŠJF
Z£Ï dj¬x§Ø8XÅã!ıLWÎ²0Õâ5lãÃÀéFªåæá^{ƒ[ÄBã gãgæÖ¡EşGáÅÉ!–`új4ú	Ñpm@`ˆlUUÁ6%íØåóå £¤ÁÅúÍı£¢/¥t´2¿ÔÁ©@ØQ8‰ıÍøªòĞã…t¹ÀüÖå×v]şf<zS±ıiÓÇ¿´‘ƒ•ÖwE hÍ0Øô<»;ª1^|fˆJâ–>q±tÁ‘R‰'æm:îìNêG ½¼D«û­úNĞ@b(2SÕÄ‰fo„øùâ¡İr	¶Æ©*JÈéLct†¤õQÁBakĞK1Ñš¹)êQëGÀßè¸,™ÙyÆ‰o‰ÿ_›'ìı­úoÒÆ‘™d”…ÒvºFÛù¿‚Œò°Ø_P.ş<àôÄı ±´ö£BJ^ğ!¹,ìÑ—T¢›†ÈÆî´ğatŞa²j‹ {RAAGí½'0ës~½nK";B>†Har{û”$3E»$’ß^ÑuP~•¾„ÌxQS*¬¤‰óŠÏg5’'˜ÒWu-Ş:s`XGdä¥“éĞ@˜›ÓôaşÁÏ3‚ô,8âçı…í~«ÜÃªÜKJqõ@W™ª.-mêÅÂ
ùH×
µÊ—yğãšıLoÅ!uá|	hqA‰Ì]%G[‘@M¡™nŒ—‰ı©EÊwørA£Tå.¶ˆø0k•‰ Ÿæè®}÷,1—¥îKñM@´Î‹DqBM*ò¯o¹
ÒØ€×STñBÂ*,hc®Í1ˆ¸ËÏd½Êe-_»vä(xœªtU/“ *ôñª•€êrN,¨•:g>§hë[HÁAú§ Ÿ~û±ç”±z9
êôÖAjÉí’U"ij>Š¡F‚Ÿú¶OrÇàó‚-×\ûĞ{~Af¬£ÚKS~"ºŸÎ!Š˜)©ûÙymT7×lƒïŞ­ F±Ê5zHµ¤ù¤°a¬pmjÌÁ¨#İùğˆEdTjB…[€†ì*ÊE¿ÙæoÖ1¶J¿m;òã>ê¸à[§`!Á‚ŒÕ.I¨IÑô§•Vyı•ñõo
z¡§AğjY²ø÷AûçPÉ
 tqê<‘ú‰˜ÌwÇÀ¡ô'k’ÒØBrĞ.SP\æ£*`“œmib‚İ¯ú…6ò €çcFŞ¡‰%!©Ç†Í) C‘•ºGí«-D¡+¿ø¢I&„lÛ/•äÇÉd$ubÎæê½Ê*-Ü@LL‡#ĞQO§
Ö»4c¿Œ‚»â‚…0pU£rƒ£…Ò©¨kfGù3Û·àÓğX È´¸Wêê9y7É‹¨&'øí¯åWg·“WCZBFPaœy£äR!ZË™hÊÍ”ò
cµpğc€¹Æoßo¡¸¢`ğçÚ­IAË<¼V“O5ÙmªQ`¾†Û™±.øø;8r¼›¹¯*0C_ŞtŞsíŞäô	 j“A×iÛ¿jq¿˜ˆÖîğ üu´Ø>8ƒĞÖBI.şEû,†ã€\åŠ¬˜‚ÓÌ~.¹eY-Æ#¤©hq,¬6ÉÕ÷Ä]÷z1Õ1)&Qt•ƒÛÜF®üD3kÖ¦·Piw¹$„U/­ı±M
:Ù‹!âœ®Å½FÔl—Z+¡rÌ @ëM¡/Iyó}ŞnDytû¢qÉŞ¦êŒPø	©‹ñ,—5gXì™ô¢j$³ã¢üš©8yo+¬¢ Ö:Gb?£ÛWx@iX”}·_@¾Ìä`nû¹œÆùR=?
Õ‚ÔıC	 J3IÄ)‰1ŸWïOöè»œøfóĞqzï´ÅiPƒRô}ıï"Ü¥Q*hÅˆ?/Y±TÆuŠSw¨ KšÔ¤úFSÃub|<®TĞïµ8êé>ÀXÓiÒ¥}ÆòÃß•O’“	P“ôn0ëå$i¯[6‰Ê/Z2şr`Ÿ-«ÇÎ‘-¤WÒ)ä¯6b"gj$}ÙÆââºğDø²+Ş?
 8Ík¡“K4Ã}!­¨Ÿ$³13¨X"Å,tÖOµšîg^£p¢WLØ5£xÍÚ9›ÕÚ¸û­~P–~2–ÔQd2±zX/~5¥æ.İ™ÿ[_Œ|D ”Øí¡…}}ÓÔãŠ°ŠŠ1ì×¨ıD+±â õ±®ZHnD¬(;î ^‘×µŞñfæ¾	-	êZ<oä1_bo+Ó»ä  „Ï‡Ò Oê˜	Î½å@Ø,œæ£š1Šÿ1è£•—ï‘Á¢•¾ú.™ÀK­AÖÌœŠ‰V'éO—Ù
ÏÇkw®Z»ÓN¡û,gı‰õûÇEŠ)ÚÔ42ì&©Ú=©Oç¡y•Ã¸prô_›tAqL´´¤(=7••½Rû&ç$Ás)FS·e Ã»6Âó<õ‰Kéér	z§Ş§úÊåM`×m.06wÑI*â,»>0MÆê)7ÈÏ<‡T	ŸâÇ®âÂ3ş¿<¨GU¤ÁÂá¶hßå Îç7‡¦1TV¹Ñ0ºxsƒî¤@E'ï5v[«§%—u½æø#'6ì}øÏóÿÅ†ğ˜Ä<^Ÿ%åoN±¸ÏYÎÓÔÑvê®\T³_$Ë¡|ö>}ÃÚƒéX°
êu€÷l<ªû_—1B¬wÓä/W{"§¾O
'Ä“G#w¿ã”‡Z]5ÄáZjÍëëÂªÿäİsQì˜vPohŒ1²Á]ÔüÑYúC´¨O‘E œKzvÓØzÇØ´A«?mõ#®§~RZo¦ÆÃN?ûŒ*îˆzŒØwò¢
ƒyÅãú»ÿ¬#‰(­sÃÏ‰rÿAL¯Ç`‹öñç-ÕÊ­XH¤dƒµŠ€\Éªáë‰5©‹læî±Ô¹{áºH2–y’¿Ÿl«ËÃøa—¦vÙ¥s´Áí¿8Äd¦ÊP1ı–ïÍo+ù”ÀïÆ"¢Ty­7}A¤ŠÍ­ä6@ …ŠÜ(fÖFY#ÈDÕõ´±8]Rí$e
Á|îÓ² ˆ#¦êÎÅ|„™\G¼«Nfåÿ—s„7RÏqÛ8H*qd_NyRvÅÇj­V-ö0ÑıÍV!zÕ¯m0§Z°¿F,Ôä[jĞWĞ58üéáùˆÇ–F08~»}z¤ÿ&>…»À’9áÁi)a*í€5Ö%ˆå80ªJ–fl…Å{z\šm+¤CI<•|RW¡Ø£s³@¶zÔ¤ê„¬ú†•#çà/¡”4yø¶éB%ø:z˜ó'<½
&½!ÊëfRî€Şf£¦/}<NºIfËGxk«²»âü° ª]kø¾z·ëÓÍ&f&Š`«!wßS‰Gğú1(Ê©#’/–~I$—Pf¾ßpšå=3¦¤Hèºµtğ ôOÃú(ªôç­„ùÈ©ÒÏUÔp»q{¨²ÎÙ*É:ÖŸC5¤Ÿ7xV±—¿s‰h¿/š!Ë€ş/‰ú§ôNºìÇy2eÍx¼»a=Ûÿ$Øœˆš¦s»r=?œCi@a’$„ÖÃkteÿÖŸ?Gßù*=†0/š¢Ÿš^&MÑ¤Ş 9ú¦ “A ø•ı‰–ÄÆ…ˆ%_ª¿’ÕÄû®ßµº)×š¬‚³Nà©˜ÕÏŠQl·¤¡¤±qsûËÖyÚÙßõ}yP¾KpÎK#û²J^ÉV¼*Š6ìÇÃ5¨qTy$,4	w4oF‡øº –V¤b5š­ßª“Üûp¸6Î7 Í 6£ÜúT£hAl¬ñ©ËèšÒÑu$D°øZ"œ`T)p¤bïÑbÙà2¼s b«Æ\ÜÜIX¢¨É¡ñÿŸ1‰‡¿¥“‹×*!ªÒV-b:Î„†Û-=}yPL
Qdë0Gê™4Ì¤ïS
t)l“`C´¡YnN–à9·a?Ê]_?ÉçêQ>æÃ)}QˆÌÑò`ûßZ•ïÿG‘b)¼ş‹÷¡QO“ëÜû²w¬ìÀ×)<A³™‰ 2šRÂ•‘ŠÉô‡rñ“ÔšßAıšÏ~8 5î¶çä_àˆ«DYY*á‹ø@Eüd¢ÍmbN­C5‰ÉÜ­Õñì<mªÈ%§úÓ·tV„%cyü9è€¸ş-Z´{0*ƒ-—ºòuZ°_
ó
l ùb1å¼Õéõ²‡îk
âtiâHgŸ£ÎºÈA;ÍÚyzâ—:Lœ[±nZ~ˆWÜx‚ş¡”“
ÍÓè]tTòuˆ¢kD&pTŸwTâp›NG5èHO Õâ$ìâÈmâD‡ƒµúkl’ª«âAiW/2“yŞ~K=¿ÿh+o¡şëdõÙcpX«5²lt7°Çh»ÚñË¼C¶òœ¿î…Kô4ğ%ø£n£Àx[ñüxvÏ½©Û¤ÂúŞë. {'ü7J÷ÖQi×º8®À¹¡ğ8h×s@àî¡±ì¸P¼RĞƒ]]ÂrÍ#šÊØ›'IE“»>…kú&‰~>ÎŞ“ç¸Û ·”ÓLéÆ…2B 2E|Í=>)4…64Ù>ãıõpÖA'Š[^<Ò‡$QŸ#|Ä®{Ús{´¨‡ ëLÜİ„Ö?µäì*¡"¯7É#’ıa‰ĞÖÂ1<"k°hœ‹Ô+¶0_?V O•t÷›øw©O¸ëüİ§ü…ê·p‡pÓr(Ö¢qmÕ¦|;.c™åd¸.”F&Œà'&}‚C]Ú’¸×İˆl,;ˆI"@}3èóüoŒ–£n¡Z&Ô‰Ò:S»D‘ g‘P‹gsp…şÿŞƒÎíº¦’/wÈ4P3¬Ÿw)x’4†ñ¹®¢ÊWÉÜ?£´›/Ù5ÈC$ï5ÀÕœ‘ı"pŸ¥×?Û2İê„àv4Ó(ŒfD|ÀÎ e†¦0ËÓõ!
Á˜úû)ñÄ1®[Ù¸z"½¤­2"¥4àì#²ÿ-4ŒÉú¬YDò†hçÆ> ×ol•ì½Ÿ0q^ Ï¢ÒãEŸñ¥šCÅ…bS|ü"Äªõ<5ò7Ê¨ 9ô“-M0¾K½~¯.íÛomÈEoOWNB‹é¼¢¿s¡ ÛU×|v’ìgk5}]ŠÌÃÎº3/r)”„uŸsØ²(O6ÇïïÃÂ’ˆÜš…SìˆÂâ‹/x©k¿oë†x½‚ğ¯]B «AÒé0}I?˜e‡5+]Èà«(OwÓ™zå{MÏQW(—ÃtÙ¨¢hŠı³ôYâµ°ç[J—DUC¿^‚9yãÎù=pÃlRŸÓö|¾¾ÿ®0¸œôYV"h¼ßL~VX–XªÀr8„ôZ¦‰İ1Ó@IU‘İ™˜Ú\È<±TÎïÉ`sôWª÷ö¤<–N#$URîq¸9O)æ…7˜eÍß¯tMÒáäw„ÿì1œ•"ª1SÈFÅ6«é¼Sï¢œ‰á<Õ:jWA,¹[3Êb9NªW”˜rƒüÃö¤ıÜBU÷ÿ÷rıo–^‹é^iÂ[}ÙˆàgéX$w±I†ÇøVCªĞo¿†YMï±Ú@,¢¬Â¿DÁÃsV¹¿Eø:]Ré±îi6ÑF«“'¤®Ÿ¶GÃ!’­ğ] ëWùØPß}Ä¨ÊƒÊ¨Ç!Àj±¦L2ŸÁñ-lù÷o{U’Bƒº ‡×j 1^ï–(\û•~\Lğ^S–}¹XÜOäïcSµïäuLağ‡N+ÈBD­­÷ÔÓZ‹çĞ¹=8jµlZdQ~dì'!G”¶” ş:©ÕQQ}Ñ9«;õÔÙ¼×öâä•T‹Ô²“´Åä»XP:1M$ûåÀDlï&h–¨È.cv{°‘úÛµ[ºÑ¯1wÁ­ñıƒF¯-VÎó_Ô#´{¹@ğokÊæë!ê·%}dJ¾Nƒz÷ÄÂu‘ˆÒaİ×0ÙÓ_§[úÆêg­ÿÒŸ²€5BµÁ3'9Gt8è|„&Ù€"îg[ÅÔy´^ªßí·DúÁog2½+24`{ıä\nœš~ùÜšáî?ÓêøÏÊdÈˆ„1ç XíèÍk}»}ö$fòo?÷%XŒ‡‚á–õ.ü—GaIMc5œt,×æ×ßUæÊ´•"" V¤ |Œ4ßmšd]æØ s «88 ô]œ	¤ >óğ»HòÀz.ª >ëq³A¼ì©	9ƒb$óÏÍ{)ÔrÙŸT&Dø?;‘†L@‡š.†ërƒ[4ÇÚÇ
XìÄcN7œŸ
 `âKôR¤ ±ó+İ" ŸLD~ÑÑ‚ö^Ïü¼®]ÑLJoÎJtYmÍ(„Ô_­–ÓnºßØÖ†%¶!*Ä´Ö:éçñ-$”&£©~VPTêÃUÀ¢“Ù†×‰ìÎ`È–Päv’÷Š¸uHQØI!eŸÔúÄ5÷¿CT€ˆ¶-¾K&tˆ‹)y#Ò›´™‚èr ‰c<Ï=DŸİP×Ïï–KxU(çâr)«°¬'Ã#lµı®AÑÌx@'4)Õ@è_c¤ A¨xÀbJß’@zã o^~ïúT yX„h&ÿŞnÖLÈŸ¨ĞÛ±2(Ğ@]b--;íœæ_fãmíu€k\
7u8ÒmcÅ«°U‡Ó vY<Şò±šH¹Æ­"ï‰R`ö^â²X}ºµ$¬¸gt,#šd¡‹ï–wüÅÕºB9ÕUÿ·¿7kMë9ºtRß®*°»´BŒÉ–¨Ùxıv
n`lÕÍ‘mSìrÑÄÊ£Aô^\=i1ú\,ÚÉ35¿V¤n“|Ó‰v|ØôNVQi&´V½Â™Áƒyâ²ú›y%=½êŒZ7‹ €Ï³cç4bNãWêûÕ”)+®²8Ãmâu´Yf‰şÈâæÛ’x‚í€©ËÅ%•Ø)Å-Ğ…ôğºãš;EˆÔyÍ÷Òıf‚FŸdŠg×˜åæÁ›z©JÁ	IƒøëH{òN?ÈèA‡M©ó‡Vn•»ŞÅMnÄçByCy"*Õˆ´í\Ç®zü¡5ç²ùôÀ-T3„°È¯ÄÀ;B­LA±,©±`9Å ¿‹ÂÙ/>]€[r­¡@=±¦Å4c$ğˆaâc{VlÍ®1568Ò4G]ş[dÖiÉİDInöçêú ëRM«»%p¿í Tˆ<uM5XÑn*F•£¬n™}µ\£Át½‡úrEOëo£_øã»²CöÃ½ûÛì¤ƒƒæ€éû=—¾>	y´M˜vƒÙnêı™?1ô‘ù[Å§p ı¡Œ~Î,×)ƒ÷Ø{ÓØf•|>kN4ªÚ	¼ôÎÃÑ@|ÊH4ß†İÙ®‡Æ"H¢J]¹CJÂB[_m¢á¨1.8q[f2İrLTJR÷kïjá‚Kà³g{Ä“Éi-sn/V;Ã½+’µ‡¾œúàéÁñ‚¤’œÄÖŸ }z0;6~y¥ÄE˜×ÑRûóy´_Õ¨‡åYìĞ.ãÆyÒ7·Çª,¹«^eehúµyL(ïÕ,<‚DªgÀXeøe—×üôT)s½5L¹Sò‡VÀØì<ÎhÔ€{1å£~ö€ı1²2É€9°?L,jRg‡ÍE'_Î½ÖøÑQ€ I²Ç[«ù»÷Eî:­ÃS`õà°MAÖ§êZjíĞ;èÿwÍ;Ó àÌİœiqr¡)ıZ•XÚgµ*uèYÉÈ^ õ¨E·<HµÌ& ±Mr™fJ°ø;ÊònßàVNÜ8‹ÉÊœ$PÁ‡W²,ƒb£Å |ˆ¨÷_®±«¨Ï9ß¿ÜÍ²lÿá4ãW?ÇF÷9`½ÆKUÈª 1º-›vEIG†Gƒ†µ›ç(…>ƒf–Fl+j<5×ø3Ã½mui'kâ	²Í—Ÿ¡T­)…ãTÀÌˆÛÒ‘Åè¹<üAHÄnŒ9£ó¥ZÔÂÒ/:æhºŸ†Çç¦¦¡¤Æ‚÷“ÃJº…Ÿ½‚^ÑóÑb¶ş—Öx‡Î.ğëƒDniˆùKóA-Jâg}gèûÂ4ñ¹´•]¬ñ›¯*f£ÿìšE_Mò_ã4yÇËªHØ>»•Ø±ê{‡d¬éªdÂ	õéVÊZö”Zİã¡İÄÈh±T˜º¼éFÒ^È„DÅÄ°òîÊÕa;Ø¶RÀŸgŞ øé·á·¯«Ë¯)±°Ü8? cy]T,|h4ôğ×A2K^‚¹ø0Ë*”Jö½*G%kq½~¶õB39{”öcd÷f,NÏŒø‘2Ï±L[z¦œÑæx£æƒÏß×`tˆ"Â@Ëš”w”êo¨tÈnë7¹bS&DfÈø
 Œ}ˆÅcm3Qó´JÖ×Å.Í÷ónÖöğ /Ş„8"?ÍH<PüL4øû<·¦a¢&È¿1“H~s”$»L
´û3†í°¨kÖˆáH¿¶o&ø¿£¦;Ì£cQØı°m=Wº¹ÚOeÏ€é÷íçŞ3 ªE–&)åNí!Îb…(lşô•™ÍÄ°,ùÌ—˜‰; ¡e˜í6h>_•ºD¯e7e}”	 ¦uTÛI?ÿ…’%Å`äO¯¥Óaíğ‰#:?_†œ™,F	œé~µî¤[u²7
—	ŸÊ¤nJ×‡õ'_¢k×/5wr¥ÀI•‡jÿbÒ%“è·ô‹dÔs§È\@˜YÖçÀ¿Íïºv) ğdâ´T¨{šúï	_d¬M¸äÒâå‡¦DXÃpÌå1w?]¿ty4¢„°„¢–àYOóL$d¥ú™’ÊZy~23u8“G·VßjÕ-’ºPç>	­¹’xí:Iù
tì°Ãº ß÷dåÿûó+ÇØ/g•„Ç£pğ{º™Ş1zÖCe,ìtZèQAnC¢£²:&D‰¨Õ+ƒæ@Ìµ	´§r›ÕN?]qnå‡öPÅËé‹Ìkc±4““ñ˜@İê£_(ü^*® ¼m-ò> 4¦Iúà‰³šòbH&EHtê.÷š˜Š¼Zšªš·UÒ¨öR÷Îzú´´ÆöÓÏ3AeQr™•
¦om¶¼‰¾CyÃa®‹üßáÎ¢†<˜ÃÆ6İ¿ù3›^ıI}ñªñÌ9ê<j[ædOíÄ%­÷¶i~¿]Î©,³®œ,‰åibîğqÖ.äs7ĞThªƒc¼·d>Í3ÃàßÏƒÎZeÛœI‰gÑø\£¥@$Ph…šúj
J'ßÚ‚â]N4vxï;¡ë#Á•µœà	0C3¹*†Ch“›Ø²ƒ’òP™
5~)1Wú
v)É8³ß»©lÍ³N,uRo§v6µ·ğ2òWó9´|@
Zá1&¾°pÃYTI¹:Î€Ç@ÜÕòıÇi$ãšÜµ’çRGÂ>€ğïåÂöµfí~ÓÛA_*QÔ-@yôŸù‡†ÙáüÉöhKüÿ¼µ9Šú9y™¬v‹SE‚Ê*âÀ1nmõM‡7¦÷›â»ß+>”|¹ZÁËTÓ¬©IJğù·Jöî_ébÉÉĞfHl›®d5 Rp(»TÓ•)%ps]K(Ï‡ÊÛ-Öıˆ\ûúlhBU¡‘n [9ì3G§Ğ¹`­[S»%”Ğqó<7©«­pŠƒÎ½pnOp•Fc®E9—ÿ´Ğ4õêödÑwc’kŞ<•‰.ƒü"Œà2â]Æ r-ˆ7Şü&<;"f™{BôÂGc|¿j<D•P:U(43D(m²qºÁå-5ì¨[~89§µSº+<H¬Æ¿mvzÑ‘|²	ĞŠ$¡ I¢Bş OÓ[›}ó â>{?®IÃgä.(àôóM¼ –îûÿä3§9=IÚšïqú„(´óÃFÅ×Y¼ÅÈ4,AÙÔ= ×õĞÊº)‰ ^ÒĞ ƒz=C—•Ô‘ŠD"ŠûİNKS6çmÓ($põ|à«Æç£<‚–†¤ı&sàşpk›+ÿÓRN®)‘¥8ÄAÓıŠ¼r(‡ 
¥ÓUÃ:¬İ#w]:+LH]æ"ØOígMy¿IâŞ£©ænÛk½7¯Òh•ÈZş(ıÀôÅoZPSM¬õ¡¯ÿ6ún
àòDà©ÌğCÌŒW£©İ×jè‘­H™Ô.ÁÑÿ"ZÔ[(Óå`ºJªŸßÏ—éõÑñ]|šîİ™Ç§ŞËÿUÿ	Ë‘° ˆ–${Eø?ÇÒ|ÛPŸSM/…Î9‚áÓ«áé¹:ï´»<lApÛFW¹Ÿÿk³ìÖí¸XÇx&QŞÑ7ŠÇ.Îğ[#õÄ™Ùï`‘ıÏc=Vô×NrmU"% ¤9ÜÀõ”Ã¢Ó4SX)XvÎ{¢VòérÔìH:y\{Ÿüz)gxÙ®	-’©\DÁÍYu½Z÷@€`‡*Müfíqû5Dñasd«_Xtcù|Ní~ŒèŸ°Oš¶õ/w¢áLCÖy³¾<Ô‚@kEG£fÁèn=­|hàIkoú/ÇˆB’µDPd!yp<°ïe»G[ß}€q[1şÎ‘û‡5»(G™Öµ@Åº£œIBømoéªrE>Õó{îm›Î5ed_˜[ŸmœÏ	 r)çó~À\$n7kAW%pÆ´‰¶ò)§Èıc6(]ª)ìŒ"ù@ÙÓ½Ü¢°]¤7–•|HcàŸqtHS±­\&#h I_D‘»´tÑ[ãLé­B‚+¢Á Œdİ·«^âsJïh*ğ¦3P‹„“îa"6h³P­NT‹“Äí›QYŸ,\|óæ7©´üÌÚ‚Î_UÈÂT—{„e¦4ÕZY%k:9Ñ_€¾½œ¹#Áïí×…Ñ^¨ØT DŞ%°ÏÔ‘Š@ËÜ>İÆ22O{ÇÀšØ{DTY¨µoS„"A÷ã„˜İçŞ%b *ó¬KÍs•9rÅ˜%£õöí_n] ı†bc#M$ÉâH¿ß$W«.Ú5I²AÑª]ğÛJêš#™ßÿdh:ĞŒÀ¯ïèdGLÉe˜%nÛg¡0³‘>s9»ô2u¢Ù55zïP ƒ”¾ÕR ­|aN!äQÚP2^s#H£½ş¤ÎĞ’l‰!µL_²ä‚\™nàEóÑgÊ Ó9€@ş&dÏÔá­‰XsRWn[s¯Ê°·B›¥&Şã30³CâwìSÆ-g,-”K,ª­×É³9;_¿ˆoB¢fğ¦·"Ìšú5Q–rŒ³m––Û“İ”¤¿İµëtÈ§²àCdõ+§u‘(NÂŒÈaÄÆ­VŞÌ$Æ†pLGï©Ïş˜Xrâğ§Å)3y~¥“‚}µ»ÿá`ö^‚Z²Øƒ]å„‰ÙwÇ©ğl}sí*J¨ÂV“ßÓÂÖª,÷â{âJÂq˜˜İİì˜¯<’2kÄ¼»|Bî]°GßÜò}ïÌ"¡20^…#T…•íî½>˜4Tà¸°^óq„?4=U'¿aAırˆ½ä	¡ºY>ö?‰u<0~±
Irr"¿ò‚Á3š‚Î-²‹ãJ ¹x£ºÊk­*ïˆV¼¤„Ë~‚’•ïÌ–ò!ïÄ¿€¶­©¡Ù—¸Pqşî¶9ä[lr0å=ÆJ6$•ÜmÏ¨Œ9)ÿÔ—+•¦å3…†—3¤Ş—[«´¦Åkˆ1\0ïãÍpôåTy9òáô×¨.¬”7‚‹ ãişüã.mûáÑ°\]»è¿6>h“­$8°(0p5Ø…h;$Óìîİ™=`å§$æt¤¹Yé •J½%ü'×Ã~ÑaÜ;U†cÂ·×Àÿb£è-¨:F\ü>õÌ¸³­æ~c”Ñ*KİŠ0ÙLæÃ®éñŞ	bn4Üğ•ècÿaAa5mµÕû¶T^Ÿ
Ô¬àkøÉíà<³¶œ§ Í®ªÏä‰·ğ…æ|rÛŞ½®­u˜Ô §ÁD„jû:†.“0‘x)š&Z=Ø¾/µÉ×¬*óKÛïnBeM¢~‹¢İÜ¢®zŠÑ§qc¢ˆ÷´*µ®ò‹Dëíoé^c¯·ÅfbëOıcÔ×ô¼ÿ„Z¦sœ†c®—Ô$v†+ŸÊÈüêØÄl2†z u~ÒŸ<†G{D«rŞ©‚$‹”º`h:ûÊÚ
ş%Pı3û‚Ê}'Wx£-È`Ì›º›ût`,Â‰:ˆÖ£sâJ_]ULÅøìD»v*ŠÌ„›*póĞŸeğüÍ×á(ÚôÍ:½ŞhdëSÚEH&q¿ˆàŒ`8ÇrV÷a„	Ğä!úøIPv^‹0æ³c
Õ´0aœQl(G*Û½AêÓôn~"hwœ¡›Wb>[Ì
 äN† ïNd(á(bŞU“PêKŒ ã)G¾ˆîiAÈ %«ÀoºŸé¼ZJjqK¨IÏ’Á%JjfZ¬•¢§ôšê™o4úí™º"ãÃÚÖ>Œê¸eYüS¥Ã´©÷™gGP”§	'ıš>%GÜˆ?÷@ÜÄn^F´ñ`'[÷&«ßoLIş"I%ŞÉßzê–€LÎI*ïÇ °Üôècp¤*+ãŞ¦Zv¢'c‡¿õN¸)?bz|DÔÏ11 {;µä£a÷--{ßÚ_’Æ—&B¬´$ûg{Oë[›RĞ„oåÆÏ¤çx L÷“†JƒÙ‰å-Êív®.9ƒmªdÿƒıßßòØ'µ}H/Oy‰şÏ23Ò“õ“–åÊ+áÉG,:rçÃgYßÛµ¾ÄŒx6É›Œ^3#JƒUyNğñ]ssÑ~¿6_ÿ¦ØÍD‘Iå$_|z´ #6ÊÕô<‹~îIV1:€N³à}÷?„šjH”’§ğ`Ğ¹ XtBHA[já_§2$ó.Âqà¦3ÆA£÷O'…[~§“İXÛØ©q™ĞıVZh§óôÚéÀYœå §«‘M+Á²Ï¡ã3ÎVšPŞH‚Ç
¥H¬—ç½£äÑğDd{q=«Ò M¶¢ÏkÆAöyÆR·$00÷üZü †1¨|?×ş.%ä!%)}•ÂÊ	!ˆ^·Â¨ÓªñÚfë3š1œ”#ç›E”÷@¶»G ­¿LX.ñ|‚©6_ßGÙd2¼°\Ãw„¥ÜñïpÈûtCîğ÷û¶ß)ñ¥úÑˆ×#œ3£Çd©†¾|GÑó-4!¦aµe£ûjíI¸Á;K»`ÂÜq¾EHÀ[hBİ_zE±°æğ«‘íb§BÚo àÌ•ãrL£=ÆG–Ÿ] t
“nİ™œëÃ m£Vªoó„cÙròÆ^Nç¤@o?„zõÇDå…½ —ÒÏî»ÂÎ} ÍÁíaàô·ìw3A¶ª6œş7½cxË:)Ô!œ–'Mz¢[.Fõ~>ãª™–¤i\ş *ù¾6Ö"5mÛ§bÕ>²íûˆ¤ãÂÇ#Üü–?20úšŠ:Ú?–uBõï–¦Ï¨WÛ>"ãıÆ4u’òÛ
ÿy˜–³Ã« Ğ%uçÙ«pğ==ñ ç±û/ğŠ¦hY›®x~w#'‹Ò
Î#RÎkarÃäC\bÄƒ´á2ß>İ(X^v¹Ğ2nÁ²3v(w,·…ªk•Â˜çº^ö·Ô8Ğk&•ô‚Ia~"²üÑx´š`?ŠúUz6-¦l÷båsñõü½ØÌğ™ÎÜZ}=:\ÌÅ¯'Ñ™G†æqUHAÿÖş3Å.×ĞEÌKB4…TÓÕÚ /¦À@Û‚/gŞ ‚ûR,ù¸¶eÆ-c`5Y^µ¯cæ¸{€Û«óÿaÃ,(™®õ©Ğ‹Î\oët¡-:G3ïÜâI°VêJ„J[¶ûH»¦æ®]Ÿ=}Õ¥±CçcÕx–İ%q®õı#nÚ`ºö×®d£¥İ|»~ÑÀ,¢©Ùª Êí’Øˆö*‡%F+7kSÅãÛC`X:£S`nãb—ìºè‰?›ƒJ©†˜µ@c&Sq¶£êæbáÛò€à–ìx3¨¤n’q6ÄÜMëÀõàNd¦‚´:È|È7Q¢Ñ@mí^ö
Tuôüw÷ü;¥Î8~½˜MÃ_S7VSù˜_×"	]¶jVnîxæÆRîÕû6ûzô>ÆÂDõ>gxŒ¬v~õŒÿ’I‹¦«Ş³Óx/éçšUé3å3ã€’‰;d;¢˜c{¼ô“¤wGîÍ-¤’j¾~o"ÉãóÃŒBó½ÜeYQ¯°Ìé	})€ï§y°É”rì4)şÂsÀİuj†zØ@ìiGU qsŞG ‹Ò×I
•Y­l¨)Û©à>´[ƒÔ<›®—í¸Ä=^öŒêlP±§?=®Ä(~Áç¶ŸˆhÛ+& É@l}P7÷Q&.¯éZ¹ÅH qyÀ®®Ëñ1%@âybz¨àM>NqÓ“Ş…†Ä˜pa_¥„0ñW¨b×Ëª­@D½ğ×IÏ¢B‹H}ƒ)õœ §ÁÖKü¢x=4-ucÅšM©OTû›D²lËÊ‘“_"5’¿?¡”ÚC¥WÑQˆƒŞ#V.9Î½@¾ù3Ü‹&§²¡¥é<ËÑœûä¸Nà_¬²¯İ¤ÜÇ7~¶¯~À7mN=±"6îòjHá·×–"0òWÚë
ÁõõÑYlùÿW0{,„j­ÖG{Rò0qF‹ôØà©NyæÜö³H\ÑzSêDİFSŠ*Øâ7NFßÊ|“Ü™4CÅEâ¯Ğ"
a<nèëqa_cÖ¦Hd/€ç&p}zÏ³œ0~6Y¾ré [œÓ0,Öß1¡E·_W:ğÀ3ÒÿäısE$‰Iy×kG‹¬º^¥ßU¬Š8èÒ‘zn#
%6ûhÌéêß†]O]¬^×¦Ùvç‚'=n¯mßgÓZr_ÌNW´Á´b³"ùöŸ´pœ6…?3‹ÂãOéS”iZóÉË™·áæj[¶¸‚¨.xeKUéîÉRë=OOúJ)¬jÎôxŞ¢ôÕ…À6ôş°È87
ÚÓ‰8%8±€W1NªOõ;Ürè
ƒïÄ'qrÎ–ATÌ±¿L¥…ÕYğ¡! Èp	È£gŠ€Yâk´¤ ı}y1†¢‹Õ-f—Œ07B°È·Šÿ/<Gö¨ú>3Şö·­R0?ï]®-8Ä©\‹ëŠÚ$åb(Ç´4ÊrÉÊ4%”2LË{é¢N« äÁi'ÒÜ…Œó”Çw±Èle¶ª¦4Îğgùø³ƒƒÍgÓKÖ¥t!‡†¶yo¬y·ÙY”†ä¬œtE“°"ªvláé”(†“ßaqkj@ÓA<$Ö[YŞw˜dJDã?cÉ?a¤S®‘Ï!P¨Á8P’œ×±MWm…_œÑŞ?¸ÄÚktToÙÈØµøÑAæ™-´¥zåÀŒà¦=4,\™W9[æüz?=5*ù]Y13J¦œNŠ8ù:¬kÄpôBàßQeúÒ0Ã"¬‰oHGÑsß·Áìu—ÜóÈ|íÿ½@H}~l—rS´¤ğ1·…µá —Ğm“ât·,Å-!D›bÔÉ<@ïq’ÂÓ^Ûƒº@¦vşi6åŸFåşZ’Òîî6›ßÄÆ‡ÓÊr¶Ï–çQô™a/™=ÿ×mM”ømMÚ	é6±Ã7²Í®ğÌ©A#lND²".v¿Lë¯F;ñ>Më·éÀ"Ö-«È’#b¡ë  ïrĞ’‚qA¦(> áãÙ%³Öò«åÉÒì÷BwûçFÈQõ¬—ÜiAè'*04ÄvõU%ãÛá›³2IÊ°øj(j<h`å(J˜Œ/ÀÁ`û&×¦;Iê¸ÌÇTã{f7š·;Rû^Œƒ.a'jlo3Oe„ÊØFÃø—«:«N¼Gb6—N?nÖÀ±‰<¾w—j‚(™.ºæ®cf3÷ïŞœ‚,µf¿ÍŠØ-#^›é•L¾KÁ5f²§²#3x}{†Ÿ¡¢}tDÔÈÔtœ»ÿŒÔQ…zørôJR³Ÿè‹–±2FÓºc×1zê ç9N sú„Ç…ZóV†ìüûqsœ~Cèõ	ÚİJË!¥¼6S¬‚¤4‡|+ÏêhÕpª“Ş~²†Ì	ƒPâX}±íû)Å¢… {Á<³ƒê5ğLÚÎ ¬†ïÜí;tÇÆÂ:5p¾	ò6Ó£@C{'{€2;øËI¨`ò¢æ‹ô€ÙFæ9Ìr#JnFa–ÛñE_u6HæõLÒh0ï¯ÏUØjâÅNÑ3Š’¨SÕC`=Ÿ™¤è‹ÛD<ßç¹;Æ¯<0Û¤Şı:Y;K¼hNJ½ó<Ñy'Ía)/H“}Üu–‘–ü•ËkºèyÍ|lŠéİ(Úzyx/&Ä7zvä#>5{g<dˆŒfaÜ 
çêö<—c—b‰¾À‘2÷KãXä©¥V/“ï0è«¾LœR`÷a#‰ß9ŸjQ„Ã~ÍšczmîPBŒ×mJì¾Ûcª™²"³Çé›©ñ·ƒú«#Òjƒ²­+ŠEMAø5up æ‹òV<“®ÖÇsS’S!³-ŠRAcdF)7´¥Ææ1ˆS1¸Ç=,1ëu;¸,³-|,ÌèPå †È£•óY“¿q+¥Aï¹ 5U)ïÙ§R…äD0“x:ú÷Ò»[·ò–İ"Ås¥ùF}&pä«Ám'ˆJu)ÌwWUŠÔšÁø#8?³Wõ-æm±ÚC¸¤ GÂb˜H‘¤¨ºÅW„¦l5íÉ#"vÓ2ZG{&£wY{>"ËFÛkBà¥ÔÑp?b8+öş°×ó÷Ô uµ¥„òÁ™Jäçş»s©w¸†Ù8‘ÈFØŞÎ#TP.˜ikEW#'¯SÂÓ&9"¦cêOšvşÚ¥ÕJSº½¡ê`‘ûœ§v%f`Ü×*ÒlšÚ>Øğà*Bùşäñ;óxÁÑ/ p8xqŠßw&¼ÒäÆ™ìç«úÄS8ş4n½˜­ÀJ5’·ÂÛ;7…Ğkˆ`9Ti‰Âp{ïe õk€tÎûÁwÑ‰Ğ%>ÚçL_Ç{‡1CNM§èå=6÷Vb6HŸ&¤ï§w¯ì±’!ÑÂ!Ÿ¹DuĞ7¸Í™£èázïµ·¦xC£‘*œUß=Kz¼w`¬s¼"½˜' 1a¿yLw<	Èn@hü…h«|]Fr¢wÏZ¨’•ç6ş½R©íxˆŒËæxVpDt{göç^‰ÿs(¦5.ª¯KJŒ¤
UÅ$iv¯\¯f#}šµ¦vûîä½û¾÷@Õ¸ˆ[g|dgp[“í^*ŒÌ4IoA6l:;Ï¶æÎÜÈ!xQøBè„aÑ6n—I´ıüÚ[Ë cÚ£[PÙĞ)>IäÀ&±ØªÂ"4ç#³ÿsnñ-/Jüİãß‘&wRMØ•q¦Â_#;ß-ìº®ê×BÏ¤?±ÓíIº~»šŒ<ç7Æßl)yU#óBNYî'°Gƒãp }‡‹“™ä$Óa7#Ûš·v½ş°ò'Õ7DZÏ;¢F4´$ÅØ‰¬;6AzÉ*®íõÄÓMâ5 öÿF\ÄÌ»d¯ØÒ¶aïg»ô#Êj-BY‹Pæ®Ó68xèŠ^×æTñÍ’øàÉª¼¯Éô1XğØ¾î½y?Lü"É„Lß®_
ëT2;¢:ö^é}Tßäg?]tf.a-‰şUC~\Õ3Û­¢¾ÕŸúbß»,g#ô@káB22Ğ{,»ÀÓº¨‚2‚
Æ/– pµØb Õ|¯¨ƒ›òÇÒö~Çöïìßñ&3nâ—GÓİşº)°mRsPİ["Ë‰Ô¾r| :FÚ|ƒ2 #üDÈªà?Tn 0’Ù‹Ç¤à‹…ĞgO®sşøIIJh†)4IB¡QZU›ôsv“$ëÏv7@Ñ3—f£ÿco=¸T½Ì|«£çÏÏ9¼QzØûr<2{=ÎˆoÇé27d<Á›’~C?W‹ğê_m«Ò£…rJm4!
LÅ D8u{Gé*µ¢“î…vª|bíÓíócuçP¾“ü/ÓĞœV0M4G÷Û€¿
¿X!ö8C5ÅNq¼õŒwÃks{a}°ò¡?x7ß»,„¯'W/Ú…Á}9ºåf_qñ=*[SXÊ2áñÕ9ié†ÏKÛíEBGQœÔ£‰Xª¤½x:ĞeøQ[ø¦4R9r¸·-I&÷şì•¾§|É£™nhëÄ>û’oíö(ĞLİ¸EpPÖì“RÉH±?f@èëRÛeÕ¯3"¾ fœL„ú!‡Kï5’GHù5¶ÁcÒ¤¹ÕûÙrp16Ş!†å7ÁH‹šÅ¸¢g„ßdVDB~ñÌLgÖ~u¾¥Ä×Üı
ı+³ØÕé¤!w’)îD!•^íT¸4Ó#²hœ#WÑæUÔ4t«@ÄWÓG£ĞP<|ÌˆZ’²R9ŒÒWNuWABÎ!2lê„à™–ŠkfEqæ£lxà@…{÷„Ÿ¤Ò™‘…^¡gpøN`eŞó`hêbşº¦.Úy$.f¸±jZsÌÜ5rÎ»"ZÅÈ)®î`ğ†N%Ä–šÇqVxã›VéûÚ!Y_køEeÚ„¥ß$°@;HN­Õbo'zDÈ6ZQ|ëÍl!Å<ÛËP÷_³/Stx"°éÛÛ€–?…Àä/eUâš\q?í×Ã6=ÀÙİv“\Q¸è_‘6V"§xG%6/TîõşeÅV
7²ÂOô-ÀÔÀœLãøtT§/åïGÁ2˜,¥ò§Ÿœ£#+±‘rÈ˜ò&Õw¢Z Î„–/6êï/£‰#¿ª¿"ƒ{İ ‰¾–ËÔæì¤¨)›6³‚[V»ı¤G3cŒù.Ÿñtı@ç>]¦±ÁœZ‡'ÁêO¯È™EâİMIŠ\_n¥k>.=¦^´Úw¯¤¨[ö*p™Ş›ÇKÿH?–'ú0‚½j¾${3&Õeî¡KÊÀxWHÈ°Æ"9Ç¼ûb´¥ú*x>Õ33ÌÉçà^Ãz•P6é5wîĞÏĞ4‘!©*…»yøSn¥ 1 IJ9ĞaTª3º‡tƒ-3ó–œVG9n,n©†€úÕÏ”#H_Zì×zà/2=€ªk:ìÀ,sˆUBÕOäŒÕø´yÛ_°ˆá±_$`¬/}Ã‹Ñ‰º'§ÁO6ª°íÿbCí:Lİa†\ì(ğGÊ~4 í1#°?Ì0=½û048ª²KÔ|JP¡%jBgudÕ„JœûL“‘Ì­RÈßIJ¼²‚nˆËBá†€~‹ñˆ¡ !bF£6ÅÁäõ£×€RÔ_Rh ¯ôfš€ÕWkìˆ§h#Bù1]HÒêğ ¥>›ÖÏ>ÈÀºIş¬Î¬íQCõ¥„òy¸ÅU4à=?Ñ€f{+ßö‰ûE†AØäÁb(¸²¡=ò‰˜ºİ1Ò‹´Ò¹˜ŠAFWmnAÊ¯ŸE¬ŠŞBd€ßgã[³ÒŠFÃH¡ÕÃcw2‡,|y2ï9u£”‹
ié‘-SOıìtª>¿KÑ«È…ácnKá^@4X«Sªë»Ê¦ğ8öW`x
Ö.<I(CÓyÜÊN!Ùİ IWÑKF/|aèqtf­~WWè£Fš%ny<bVËíºQ²é{7šµNeÛ ˆ€˜ˆ$ğ¯ì‡ã/ÊöídveY?ÍËÙKU:ÊdYmÖ¡›Ğc]ZÇ;IƒÌAy ¼²"ÚÂ´“„æŸ¬RóóÜ’Íæ»SĞ¥SäøD~ucX€àW.²%Ñì¢ZöÑsİ3Kz•ÅNPÃ,WIîE´UĞ®@²ş¨áRvb„.ÅÆ1cà˜€—éSp‡­.÷À2^Ğ7É¡â±¯4)­ûÍm!øz­Å”.ƒ9G"%a/«#‰GµŞ±‰jK…?J‚&–“ Â¯Ö®7P¡Œü[ß¦ãÓ0#>…Ó*òŠ<®üƒñ’À™Ñø¦ÙBÁ:Y|;Fğ]Œ4F”öÕ<ùÉ2P)ñR0±rÿ<ÈBmIæ“§~!D[mÃÁ[Üú.´×µ¼C³›æR±ÇbãÁöµÌ¾øÁmcäzdM±@ÒÒ•âIº8=ÛqœŞò1—x„ı¾`-÷Ä	#"W!Æ
Qv9´Z©‘ª™})Ë½Õú‡â¨¥ŠD:„´:GÍ‹z£Ê¢ª¨ÍÆÈËÿ g^—°½0äx@E¹ ,œ›Êî dé(Ûpê•;ŒÄ+u«B\ >Ş"ÙØŒûjç#äOR!àÛñ‰©+?_•$İ„¹²€“c¤Ğ5Í¾gÊ©âY>¬›hõ¤ºsJ)î 07¦"´*IşP²:V:ÿ!°¹ÊJNØ=±°9ò†B†¹Ø9åP6h¡á†W”øUë‰ÜĞLŞsé¾MîJ.5•+ÄÛŒOàWÒ«XuŞ8åÕÃ¾àÇ-O˜˜Ä"ğİs‚»µ¨şü¾ŸÅ?÷·¦7ú§Ï>'ªƒ?_›tÙÜQ+ïgc.:B¹`¬ÉÅdFä—O¦&ñÔ¤(	ì()OuŸÑ”§ÉúQÔMf?óÒ{8İükœK„×•í»Û›Í×… Ç(aÙ[H™£"-È¯·2d]¨°)…’>ØÀU @´³¸Àq6vnMk)µù`&ÓBÿDh„î\¨'¿±’Å¦¢>äÓ©Šjx;€È¹se’TÉ±Eğ]‘½ ƒ†m›IÄòåaİ…x€ã7°9é0mHS „Ô$¨FÉ)*Ó¤EO=£õ&åí¨,Ù”Yò‰‚EuoÊÔ¢Ë‚×Ï<åÊ©drõ#«bŒ0eĞ¼/…hãË ¼,ŸøH *à\9 Ê³öQı:÷1~ê½Hcü‡O>ŒÊpÃHÍ´Â¾“ĞÀ·îÇ?Ôøôj8ÿ\Ğ†ãTkÆòô¡Hr±Ó|ÙeåÙÌ‚Pëõ3ÙñÃ•r,+Îm]äĞâ 8aë¹˜ÈŠû¶ø±e]~ùÁw—ÊòFŒ®Ù:;Xbœ{w¯¼­ä·PR0 ¬'7ËÚ¶f Gt|ä3ë!Y! ««úæ×Ë]½ùxP4“	!¸¤];ÎØ«_Çs²Æ±x¼l1G
"ùÍµ„Oj2ç@ÂšnjÔ¶©'ÜÚ.W05ä*óå¨Cñl×Ô=ı™Û%â_.Â¶˜
–‹Úeæ3<â§†«Á‡Œ¼Æà¹ÆÄzt[Hr>&ñH”Ñ\ô+:Àl1¥éW½x¡¿»´"¶ÁOVPõ¡EÉ¢V]¹ÀC×¢:eZ›²>ô;}L×UnÎ0w#\´)vXt¦\¿ô-ygş¡f04™^¾1Nº´õMFµ s¹’Î—ô}ü$†ëÜ÷R8%|SF„ÁBçô}feïz"ôN(’ÿëFŸFøÂy±A¶Ä>·U˜¼ e½zÖÌ}=®`·r¯a÷>ÇhK¨æ+Êõ¥AbÒùB"2ò‚üè¨^Œ¹¿ån$œw 2çTP7mD3Xv„G}'z^—üíÃÎò%ç<,*©Ïø˜©J¬6S\Ä†î—ºº5ƒûë°lqáVó ¸„Í0×U[+ÄÚ§ùÁz8üğBs ù¡7!6ƒ/CòQt¸ü»ğÆ`<»Ê6Bô}˜Çœ&U‚4ÁM’²›H!û~[«ó İÖFEñ=\-áo*~©§ÅSt°‘H1›/u¥]A¾–Ô®ªTeâï[¹ğgê|ÍC]­zO‘¢5¥ªß?Ú88Qê{j2!„ ¤C1¸¨™[MÔ˜Ğ(jpE7P6˜h÷ÒÔ!j°g.rw…LB+œ^Á?]x\ã0Cï•ªfi£‡
[>_1ltT‰(îiÖ|«GÊ<IŞä¼äTÒ/ FáÊÎ¼{Ô ’½!±§PO?.`Î–6Y"·V.j`ZQpÂ2,ˆîd…VUÍbjR D§iË’Ûµ¾˜0Ë7#¬¶|nt]mG–G÷/—p ÛVºô)½µêĞ_­ÎDòM
Õ¦×»™Ú
t-ÜÕŠLşDÀaï	lª›™>óö«ÎıÄzÜ#9ÏÔF#•”İĞÏ(_á`™’ï³(¤(ş€sÎ´õoëëd”Õ	‘;o(”Âô(H]ğ»»T#åÅ¿¸jİÖmj„w]m&NmtÂT¹·ƒĞî‚=0Ég/¤½TP (¬¨ëõh—¥Ï/Ûã+!ïB2ªt*TgaË¦gõûù„ÜZg"Léá”#Ò§É‰„Q…ôv”OZù”g-i@Eğr€Øë©X)Ó·%c_ñæPRcBö¤ ¯‡ÂH($_C‰ÁF±d*¦ÏÕ-7>º-Ìî}Y®`‚¶E£cè/–‹°ÔQØ[Û¿á›¶±hfÎŒ_¬÷°,˜[§D/¥°®q×Y§#k¹CKê…(Ï“…Ûj.µÉÛ¬/¥¿O¢c”_×»6ùÏéM¥û¾fÜ^ãp6JÌ9BÃƒèDîØäãÃ’ÂŒ\@Åõ´º”ºeÑ8'ì2\	À8Áµ*S.|7ü÷#Ã0ê:¬°Ù1ƒX’‹é–[İªâ˜Øë'bÆ<Ï“fA[}ÿ˜Ù T(#çö$0ß~ã%¯av§eUÏ_3W?#ªš“Ü×¹`%«’,(‹Ş
C°gaçS³pjÿtu¢ÍJŸpqQtÅéùÉL…(|wCc\QflşœtoRiïœ¨5R©¤÷$V»ü†W°Ä¿uå¸Ÿéè¯†?jÌßïêq·ÆÀÕWß™¨XÇ>½¢ZKr_“<‚†JÆ5_«ÈqCŸ¿i{cOÒØÀ[=7<5‰WÆ8ˆ˜@s„ìæDÃRœtÁ>˜«Øi¿øî¯ pg¾{2˜˜óİ8Â~NËşè3˜™]®ŠÎYnFJ¤GlÿWöYrë«+IbhéQRTXËµni^ıZ {=}^­:ï$9å9zÓ%†o‡øJdıñC­¤?î'ä}ŸÅúÚº47¬L*Lå¦$%O<è¨Ù½’%R`›\‰½Èb+4ßö½UfŸÓMKcÈ¬YëJóôºö»è¸£ºş”
ĞN'XhĞ,ÖJƒxÈ7½Ğ×ºˆ·c‘¡ĞrEŠì§E%+¬E<FŒªKêÓÎö€hó%–ÇÌ}e²—ÊU*”ù«]d™y‘]°À{€ ”yØßğÏ'àH;A§_0nùó™å-_‹ìI†W|È,ØÑ¥ ¤ªÃÃ“¤ƒ§îUÒÍw4!_ˆ­ÛÙs7ñÇ	lcm@.ÓZ›ÅóïŞ^rÂŒªÂv(xzŞ£r*lñÒn‹Dî,4Ê”X;¹…D^Ô?5u¯‚’©¡Á¼F'òá„n³½mİWÜL%‘Ìl<?´œf_eœnsQİëÚz
.>I¦×T-p))Zml4ª]Å5şÄ3Úy3EtŠ}IÁŸ?øüN2À½8ÇCµó¸c7Òº‰²¶IR¸éÙá	ëÿL÷/ÊZõ¨‚ø{¸>/Âd|"İCÉ\È¿º
î)–Ù)lUK¨4‰kO1}º#ÕÍ’°‰RPŠ~oš•Şş‘½û¦­š4ùH  ¿¾yÁ“Öİå¨´D•¯”;ƒ»óbE\xåÍÑN‚œ–›BÛ	D={OÜÉ*×8B¹Öo$·óhOõRcwT«èüâ´¿¸˜ØcMMtp¾ö© $ÓË<Ö£H•?x™¼_BİÀµu°×ä"+&¬!ğ¦nÏÑ%‚°šyŒã‡jŞÅİZ2ÂLøH="†q~áô†(¶b¿ª³à˜ÎËuÛ“— p%WöiĞ˜‚ôD}U_i.á×r8½­"öÕøK¼Müiânûxå×h¨JÇ&¦-„V)A6+@ĞŞŒÁUs@ü«—Í£{cŞÏœ¦¹lx*6_ÙÓ2BB—İ~Æİ³ùõ,ÜwÌ¢AHü Y¯a6#ï·ùÃh±§«øÑsÖñÒÖ¥İÌ3XêåèHmšÇC«ÇptÒµßÔ«İ×3òVL²V.$ƒr†U‹¢÷ƒâQ6;^ûøºÚãe¦uğB}- e~œ;OdZÎTĞ¥IàXíÇ„ĞF İ†¿Ü‹WUÊa{ï?sŞ÷«ê„¯Å8âıSOƒ‹üaÈ4 ÆÇ±ìÒüz¨‰Æ?;dˆj=ß°6·°ÿ tb:0T\†•Ğ¸)ƒÄ{ÀÕz+{†´ƒ+áãvüGugYÕ%Ù8ÓÅ¯Æ6Ú‚yhö(aF58ê€¿‚ØÚ$~Ít^…Ä*V„º¢»£ö}†Ê*tÚ“Ê&˜2Ç±Û„u¦ˆú>1iœ2¯|;ŞûÀÓ7m Ï&ô$¿“ªØº–WÆ!S/FÁıÙ ´)€J+ãHo"j¾±PêËtDÊ¥£ÃÜñ°Û­‹¹ü¸¯A<¶`?Ô! :Ó5ŠUHœ²|®@Ù¿!É¦”29Ú&å†"2‰h_¦ÃŞW€Ú 1NG¬]vPHî™!µûvDòO¼¤±•65_Ó·AšhÌ§æÄ %wò	˜pâçHÍÍ—u†‰Ç„Ãsêœ(›ÛYß—¡ŠµuĞkR'Õ¹û VÓ¹Ékøy×Œ£ã²Aˆ*qy³í0jœ¯ÄWÔHŞ±4ÙWŞÄY¬_/k\šøhÌ^BCL¸xÈâs§°O×Ø’OŠU.D# C37-å$h•ÿ—¨ÔÂÁ@¯Æüæ;ßh6¯Ø¨±ÅÎH]ªj¥nnz"@?»Î­~Â“Bo@êêÔæúÏ’Óv'`­CóŠ;íTÏgF©–ü%ÀùY¡b ³ÁÃ³!Bb'îGd3‰¢ºÑáy'ãŞºÁQ»â]k%~7l)ä ¨Ô+]è8£üYô>ÒMúû%7Ax.Š “ê·¼=µMâ%ëİŠlêH” ŸĞ‹Ñ=«(”ş¨c•¯d	éÿ×¤c?2:ƒà¢_™ETĞc3mÕ=ßA™kšı$@’MU¥‹'óØ\‘Êpé³x8é÷D¨®BúmG‘4\2¦°Î?ôåõ<¥i	U™Âüªxìâ,eÁ£	 1‚Õ88²j§d3›ë;Tye¾„j%²Z;`¬¤QY{3˜-„VëxWRBg¢’{ÚR­Èc›FÊò6ŠH8CaÍ* œÈ±O·Gãª p“·´]zìÇ"õĞ½á¹7ÁÆíDG©Sÿ!\w´ËÍ6C¿cou«œ¾šë!xµ¤·£0:„72ı“M½äËÏD‹8Ì]Ê°a­bCÓ·+‘ªXÎPÎµ>sÎ×xÊÉÚ,"kì+A˜BDÛ§j!#Ìg¸$ı¦f°a=g‚!*¾¬±]ê
º.m¯J"åR+[DMÍ°l'ŒC›«s¿3+=ZªYôğKõHfùÏëD–ª§>oÎ}ê`klæí³¾¡’RîˆÛİÚÈÈN˜‚¸tµm7 ' …ı›ËG»äË…CğU+âË-$hKô‹öOı"!ååô/}6)ù2¦àà›/:[y2~¸÷Ò>I	¡c>ß¢ÛVÅôˆü—W¤ŸŞf­¸[ÿ¼gŒŒ¿ïR¦ÉÉ#”,ùtE!Í"x¦Ègeù)óL3QûPÚ8ˆ5µ\v+/JD\Ó£RT³BV»ŠšÄÔĞo"W
-0_í¢óv}ªÃToŒìTş4‘˜vZñ1fSx‘çÚŸ@05o*Ì[¤*b Ë.*8óMHÎ–˜Ôªşğœ¨‰t\V|ïğşÛ*D€sRÏàNÛ®˜[i7uÑcb˜5ò\¼éİ¿Y€–œe÷ehÄ2öÉDH±¹'ŠàñFKrÄŸ§®;Ì¶ÀÄÁŒğiIâö$U>ïú`ÓivGX<8áÔ©¶¬ŸäA†àÍ"µ©[bÑ&)g‚ğí<¡j¿@ñ¾¥nØ{ÎDÈšNÛ¶1›ñÓ™Séß¯Tï7Î ä”°¹,ôs R«îL{”—vúPeİ«µÔ9X"kÊG©Á}Gr”OäÒë„µùsÇñK§c&“«3ŸĞ-6ôş¶ÃğÔ4}.ß•—?5O@1µ;R¢µìbÑÏ¸pÙ´ö©ÖHË:¡ÄH¸ğ@†"E£U!¢bdKÜ9À
bÂ	ğêä>S–ğT$
Bƒ×§÷a™ÊuŸZ_k˜r÷2òàrzº„¿Í×‡ZY4ÔNğ/Ê‰$¸}c›&ñ£Ÿ¯Õ%e˜SŞŒÈ&˜CD7e–!7è@p»	(°ßÆBŠ>°GTŞSqˆ©¹&`áØÅ¯¨XÙ£	ˆ%£Æ3JßÓòÔ‰G5²ùé}¦?LØ|ØºŞÈ…}TÂq
r"J„˜;ÒX>¸"üøòÑ]ªÜÇ:|U\’øÆ©gŞ&P>[k±PMÍ ¹¹˜p4=5Ó½åŞÓöã.ß0pë£4³ˆ 9Ó.ìğDZ1~Ã‘¸XØÛøŒØ­áš÷Ù>ò,Õ|q†Ë¥`dÒ¥¸HXs0ÚjÔêe^~¾ .FFU/7Ô>Ö›n«:å‚…º"S¥5o®+d¡ ÿ‹ í½&n©÷MíïY¼ºV­ÿCş9d¾›îÿµ"™Ç<_Òñ’CŠRE Ÿ®ÈdY2™óŞ¶¤ tÁM«ãFŸ[Åqõº¼\ç¨î°:ì¯Ì0/‹dïDc²‰fì:MüR1E_İ§˜nãæ
æÖˆ£xĞF!cì;D0
q;E£ğÇ~Çºó?P2½ÖÛDQĞIrí^Ç ôå¢â?÷ÈEpm&· †*/– ìçÊOŠ”{Á¾SÜ”,5ıÓ‹O¢²††ˆâ¬³ìÁtEœUÌ´İ—‹_ylÁRïBI>[ÃhSe©Q<I”»¦™úç"şë6ÀCì22¹ˆo
jlwŒB¾´HŞÔ:ì™gë²šË¶Ã¾(ÙrŠSö¶ñ~¨«"§ğPH=ÉB{í=ı¸7‰±İ˜d‰VEã‹Ø«ñ^İ‡%)
ŸÍ_k"üÑĞ"^ä2è­ÁÎz<HĞ].}S£sƒ!zâu¡ècü ®~ÿã£G/U^jæÜJÂ#Á°õ¶A´Å‡©zµ EïòñÑªÛYª'”Üˆ8ÇT¢l4O©¸AôK¾ˆPÀïÑiù•I­g… şñ<¯Å0OŞ¿5Lï ™8‰Ñ¦áF³iáƒcä¶'JM›4$<Ü‰IÄV°Æ/UŠ—»~ïCá¥w˜÷X·-Ô¢vª~ãgöï´un}¤›ÙJ<4‡³(ƒ„ÚàÄ5¬¨µñ¾şaÆ§bñ¯É ø™ú¨bİ¯8å[nó.úıb Ï+Jl¨…F§vsKn©nM¼nqÜÄ-7aË1ÔÿD‹9BŒª­şK)¸^æõÖRê©sdé°WZŞm_H­3ŸÙŞûmœTü[Ø>ëëu),¥¢w%–³ìÀ.õv!]Ş„kÌ’P5ìaÁÁÓrª ªêë®/Fx¢ÚqFı„Sg‰„m¬L\O:œ5}ØÛ<¶î¾¡#Yv.ÃÇéY›½ìÍÉàücÕ°ui?ŸÁ qe7¤øÂn÷¶Sízp9XÇõ’{^Õk&á^WA/})î=ÇARGˆVØÚ7ü³Õ;èìGEÚó¨gd¬V Bm7³H$S2½‹ê•~ôW+ej… Å2¡:9¸9AaáÏÌ‘–Hì¸%xi@ÿë	%|@šäê d~¤ÇáÈ[¥+Ó¥ÇÒgÚÅµd÷€€şX`brWàW³làhçû¾[ôéÆ^=Š]!X\tËK»}C5Ğ~)]ª]‹}×Xg»Ÿ›T
†A–-ùïÜò,?µ7Ó¨ºîs#ê{°À§oŠ?Ã—%çğ×üJtXs+âÿÊÔÆ$®ğ†^@áw$|O®ê{ıh¢­×QEf¡Ñö}ùç,GDö.•pİKâ,K<ùYD/BÜİ€Q¸h}·_±ayG¸”A«}z$)š&ÆµIé¤ËCH$côªy&V¿¦ŒË­âÏâ}²ËšVLĞ¾¢3ÿòÚ0Í¼^†K¾Ã3ãğËù‰7ğ]Ü=tœ©X÷G˜Tö®&/uI&ıKÆø7ôL(ºyÈZ…I]Sw° ú'×"MDŒw½x e­®,áÎÑâæÓû¹E¬(“™Éq=ª¨Ã{¼->´C#ÆzÖúû;7Kõç2î)aÓ?ÙäÜ¿?ènœ9WÃQÜ40]µêèA•Évc[_
ûÎ£mÌ¥)¿ê›¹•şÓ¼dáß<ÖİŒ“^|Ü6Ó:¤Ê7ıºÛƒ$t˜ei4ŞïVÓ+ıí(O·¼¾÷ÌQg*Òsë·‚8ØÃÅt§§/Bícrá½ç /x9^sC<àA`­ıRUÒşûªec(4ûVÛmD­sÙ€?TÖíöí“C+O£
´
+ş{²>.RcM?lú
ö?ñïÛŒ}”ÀjJk5öÊ7¹ƒáA=0hv!;àšâºŒ‰'»¼Hs)e•ol-bWPpÔQÇŒÍÅÌÂ”x«NNíœÙóÄ¾H/?ƒ'Oÿ®,>}…Ö_WRƒy)·2’îåœ ×™±‹„¾XwÛB‘Ò®&b±Åt°sI§¾Æ3Q›µÉşŠÄŒää“5¬6	äÕAÖgjèµ“~ÇØ’ıÂèİÂc¥*¬šÂˆ€{Ğ_<Æ’7È (llTŞ0Â]û»r¡
Z•5¹U·i€™u!åÉªŸóÎ9±æò|äjï…iùu‹'$;lfÅ¥ş—AF#%ØıÎî.†dt9Úè/'—F¢ÁÒkĞ=¸'‹WÃI¯OÓ® >lšM,,}rt¨kä¤B¢à™°LBhıo±Z™*ğÈ4•¬qzå«lNÜXX{òK)}çİÇKtñMãp¨y>ğ‰|ŞšÌõ»nóÉÙƒœ ÔIé6İÅ§¯k{ÜóÓò½4>ºéËNkÛ&Ò´š÷ª›S^éBÁªâ }üìã¦¬à g¨V‰
NğøĞÊP« 3gzñ Vè‘İF3ì 7¡‘2ŠŞj²ºU£e¢TíTú*¼­?úµWj efQc—ÑpVQ%­÷ ]]:¹Şx8·jô‡‚Ù#B®H÷ş<xµT°'÷u…‰•Qö)"²m?¿Iª6Ü‚¬Ÿş(£âò++û²ÖñÈ»ıŠlÊÚza$¶Ïjµ&5Ó§©yog’ÛËo{Ÿ¦o}¾°õ¡;Ho‡óòáÇËÉA 3ÎƒøU‡JàÌx‚ÕŸ›&ó”[Å]X‚h   J€¹”#Ñ ¾¶€Àdep±Ägû    YZ