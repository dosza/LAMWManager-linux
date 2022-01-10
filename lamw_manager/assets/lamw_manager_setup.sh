#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1163843148"
MD5="5c608ba51968345d8e58948abfe7a353"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="24296"
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
	echo Uncompressed size: 172 KB
	echo Compression: xz
	echo Date of packaging: Sun Jan  9 21:12:58 -03 2022
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
	echo OLDUSIZE=172
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
	MS_Printf "About to extract 172 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 172; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (172 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ^§] ¼}•À1Dd]‡Á›PætİDõ%°íç2è4‡…0İ¯
õJ´³ğ v‚ve.šªÄñçœt½H‘~¶âCŠ<€¦ØiqÇÀ`.dàš¶|Ş”Ä ‡‰y‘Å2/·ÛLÄ/¼OW\±¹oæô²q õ©~ˆ\øÈiUáˆLQ¯†-hÒ
g°æl—´B·×j&cóúÆÛqÈÏÎ©>x›ì1 MÙß…¿"Ÿ’…HSÛ
›Ÿ)èaü?»l­MÃâM˜`ÉíJ We³ÆÑÆ ¿Ë¸‰¿üÛ¼n”İ´m»£ÁmÊ"ˆ"AEÀkÑø¡¿	·ÌÎù¸tãâuF B6"/+]FŸjYqYšjÙI™€–G{‹ëÔrH–Ÿº‡5ŞgìS¥¥ª®Š¶jqÔÚcNqQÏ²W‹)ú¼u à‚/ˆFÕbÒkşâÖ™s»”uñø=¢¬èã9¢ÇÊä{•ãŞz&½Hø©:Şç"ç›†ì§ªNªÃ¥Qøğ(y¾¥nÏÌ²tom	':ŞĞ;åƒ ¤ äãJrIİtæ:íq²«§~ïàWPò$ÖpİÑ+9h¢ÙÒ¦^fŸˆ¥Éú_o{ D¾°îÿÓ&I(¨%7ĞœQéò¡â…¬€µdù4ª!\.ìj²iN&#xØôş¡¦U+¯P­fÌ¹]Ã–´Ïá˜]YÄ0ğUÜŠ:TâqàMœ“BĞèA><¿l`Mêü¿Öşû¡ƒ†÷jL‰¡  şn§1æœ)“{ntYf! ±~gÈË®‚ë^.Îİ®lW°… Å|ÛÅ9o¸+&À~mòlòR§œ©3zlšGÃÍsÅa‘å:ÏEÕ€ßiFµÓŒµxlœå1ƒ‘‡é23ËÃ¯5Š:,(ªiÊÎÖ&öÀ‹ãIùÅÛqşÚ/~v¡ûRúÿ¿YÛ§$¾>JÉÛ¹”XÃdë•¹eMô·Õ•˜˜õ„ıÂmùlªª¨#P°l=3}eèj~¯„´5."YàŒèÚ½';š¸	¡O—$Ä;s/Š8…ë}}’Ê€†Zj`ÛOf×W©¿ù6O¯»ˆG •U;SÌ)Y[S†¿Ö2JdôFâ` ,ÈÉ§ÕÅƒ‘òI<É†…Æô†-«I,æÓ\^¤jpÂEºXıÕ×lû]m6FÌ2$°«Ù^®ıÅÁÕ2èIÇšÀz“Th×—~3cMsÕ%}Çø‘Öá–vR§R±å,KõFMÏ‹Yx/…†÷Õ.é~·••–Ô¦œt)’¥Ÿ©IôMÙN€EÕ3€ìe!­o\NïA«¤æ(_¹¶ÜÉºÊÁò.Ğ¥ñ·€Î jR7¡zµqjZô¶Oğh}ytG.2i›eŸÀÚBB¹•:¹'¯ÅSJb¯³sÒWµÿx5ÊƒÌ ú¹şŠ&;â@t*àïŒ†õîçş”ì7bÄÈ;àeĞ$$­ºÂ‡<ûhSĞÅğ1ï$™öŞ»X˜X{]à`$¦$rùÁ®ÆúXÚ-Q}Xzy÷
ĞøãÖ*5ÑA>¬íAWKRó95úR¯¨ŠÅy²Õ;£„M¦tƒˆ;~ôNØ%²î>½P†õ•¤İÂi•{²}^táÖÔT‹u;á#¼º³åµêÖWj¯…ilL$GåLj~)¬#›_y!ç¢ğØI!1•xOOÄ6oı¦&H§'j^¬z	²¾Š\Hà#5±‹4™S^]¢ù‹7ÆŒçf#9õÑğø£¨1åê=CÎ€/Ét_°5œ?Ù
h8¾´°Û·’öÓ›ªñ¹ §k xÀtósĞ¡ÅC)k}»AY;ı¯@/.£§º¦Ãºˆ‹1XÑ“’ı£{Ü*B¯$MˆÁ3P¾ ’y>5¶>Ôé}¹<Š¿‘òÌtUaN5å}ãèÓ¾ª×(-z\hicI£ŒÕh÷şâ<o[FQäU`ÏQ,J&[…Úxº#\)fJ¢”O31ÏCò±qÚ…ş¬˜e%å¹ÙºÏòy…9c¤wAig9á¯9UX8ˆ?–Ğ^hÖ;?\côtP ã/šåñ5µ–¶†9Ü¼¥?@Ï&5ht, û•ñÒöxS)‡_¢HsW!£˜Ş…·ÛÏª ûzšÖ}™üie‰jºè‹q1‘¥î³ z,Ú4~a¶# ›Œ°Ñ(
æ¯ÛfÂ/¿ë“ÿŠ1`ü!íÆĞËØœ€ËwŸ”ù­;ˆüº™Éˆ^‹&^ÌnòÖåkSm™N,ìàXZüŞt9ÖÊ¿LW§Êò \³<P¼áªv]^ì·@’è9K3ÀÊ,fÃ¿Y‘‰ª¾‹k(_æ'ÕzVKŒ1»Ã*ëæ¯«òÁ0·ÒV0Ãã•Óàº¼®n9°”ë®¶%,¯ú ì¨‡çE”£HåS˜L;ÓmA ÌNà›N¥ [¥1ÆœsµFeú”‰©ØÔôëû”“YÙ.¸>ìùØ¾`ïmØşP¯È‘u"äD +
QeDWÿáû'­w÷q¼ÂÙ`ü5:Qu_ ÒÙåÌ^©C¬~ğÿòÅÚ‚Æ$v„§x’I£&MÄè˜eB¼ëÃŠ}EÓe=‚Õ¬Zë—„0¬1Q6b‡>“~Â ğ‹v5Vù¹tsi+ü¾ÀÖRÜ-ùï3YÂ
ïœ™$Bln	;7µ›sâ·‡säõí8G$,#ã“«Âtº®©˜l¿¶¹õ{×ÿuİ¦¬¯ Sá²‹0Oz±cÊÖl·€*öÄC2âÆ´ÛWYÔt÷IétCj½ø,°q }%±Å ®‹•>·b-iÒ¬ŞÖ€J¹»tUÂ	À"—Ÿ°w	)£à¤/Ä¹HOe€8$AÒÍËvŸE·ö4©¦Úÿò3„£'‚*?÷À
,*e¢„-5¤/M›.Ë¢†¶jYSçRbKßcÛîR¬3 uÀ¡÷*£×¡¼Uuxa/G*Z™Ÿ*OÎg™	7Û	‚¸(E"ÙiÂÑÙc>>Å´;Øı~ü$
? .LÖÊQe?ªÂÈÎD’Í”HÆúôqÔc¿9«Ù<´KH"ÊoH0lQK¦ÃíÈñfÛy\•ş,Yrµ§Ù(”lf· ¨+S¿=4á‘0vˆ#yŒF1¹:ÅVè¶Ñ¯H®‡9'â¸FPƒ™àÅÄnp‘aô%ÿ¸„ÿ'!§"Ã‘RßtòØt•/ÑøA>¦@æÿ‰xk¡²	 cª	©{<_'{³“8˜1E5ŸÎs†H”ŠĞãŸC)rGü\Ò1vY;`ıĞğMÂ­£Ú]Zà§ê/ĞÓºBD4ñÊ¥§‘ŞÅk(6&sÿÿë]µ@yÕbòÚ9H¤u ÏÙ×é›N%øğĞÃªÜW‚LBÅ×‚÷ö«F×ÛÙ³s° ±ó•(~<zÓI¨¿L±ø´A-ÎW€äË¦‘n¥õßD-¨Ÿ0{SÇeµUs.±O}–âhÆÍb¬^­Ô”ø9Ñ{n)ìÕÓ«¹ª°¿Ã•ód[xxg;íÏRœePÜC0±'Á¨–gW–54ªPò·[|¿ŠüÛ½sÔHµ¡ÂˆåÀ¡ulZœäj|nGÀ×y±»¶tNŸVEeÓX·XóÿÌ	‚õ£òÕãˆí2lM½6"­¼ïãDOfÌ|	/9))>çF5d©Ì|(2H}ºõ»|É)6íİÂm;fª¡+¹…Ä„`cÎ,õ§ÆîŒƒ‹Bå„ bÀã­w0?Ğş}AÖùr7É{CløéÎ‚¦$L
E©O­½ĞÚm—ÿj {î½Ì+a˜<‰¼è¨ßlpL3:¦H ¹JÏn8V'*c`­w6t—:²ù,xP®íuB]Q/ğ´H_A†Z¿œøÈ… Ä^5Ûn½¢ÀXfLBºr_8”C €zêüŒjUIé²HË(	¨®@xš|29·ùWôKÃm4Ë rñÒmÁ‰™Ë":ì?Bv)æ_«7hú×63VN¸Ì5şÕ>uve%Âe1Ûè’ïÃ`iÛ³sŞ]@IäŸ\¾,K[/]z‘€GïI•ãé¾F|ybë!h/& ÅësXÛ«¾1ºí/ş½@õáÃ‘À´åŒ”ËÙ¿İ²À‚3€3B·¹ŸË“t£n'«âB	Ï¸î²>u™‚ÆC¦M/Î…„¦ğw
x0Öänı6~ñœGE¤ì<V©ó`,äµ¯äÉC$¯ó3™
ßsÏ…~x'w~¥„_³õJQ—™^RŞ`_˜¨/r‹]êm×hÉWÅˆçÍ›k°Š.›^VGºÍBÀ+şÍEh,ï;Nà RöŞx·[iå¯·›•Ñn.ºd45ïçqÒ€ºg‡ı#.å3r$ ­™Î¸0e}u9æ‡H9&|Ã&Àâ¤Ø#¸?|,ãşË~
şr'<)è]ÎÏYfÑ~ÛdŠUrÕ@óXåH*éŠÿÛQÓ•0Ò¢œ\OI~©è‚í/o…ãrì?¶3†Ô·OªˆD$gÊÂGÉŒß¥ThÕÏ|ÃòÃŞb->œSä¨=â.;\gÕ8Ù„ùC–[TÉhŞ!Š¢>ø™M{´P$C’4Gß-òõ;’›Çèß,t–TØ¢,xXrBèÖZòÜÌ$Î3ÛÂÆùØ,°»H[Îé–v±N™/¹¦‹uÄ5‹‰”ÓYU€ùŠ}[§Saå`ÉÊG‘vÑú¾½†Ağ1§$ëÙ¥‘9ƒØÙÉßRQÙç‡B¶Ş¢Å™p#rÊ! Ï…À5,€Çƒk¾Ê³°¤ÏGğ>úÎAÛ fôƒˆ†Qè¾s­xöLØ ê, Wbr@_Ÿ³ÿ°}÷Ém~\Ec„(~PñüŞt--&E]î)Ö›ê³wÔ%}œx»:jTl.‰ß»{†êşÅôWoÊ¯‚ì‘”Ãk5‘vÒØ6Ÿ<ÿB~T„×_eå‡^Pàhëøº£ş.ÖMŒyO­š\Nm5$²'5pGS½ÊUL¬Oîpwga ÙRÊ”ê=¥ÉˆÔÅõÚ˜i	xf ª ;JY%Â2aÕd£ú/Ü"»‡øx±½²|CŠóƒğÚà+c!^µ¬¿”{:øœ>¤èµZÏöã½L-¢Ä™ŸC¥ôÖSm´l«¹Y4Å]¶v§ÓGÓıRuEĞØô‘óŞAEÁ4½¸%— A¡E G_¸o½ù÷|¿`]_í&s¥—	­øêâÛrw–Š	İ7ÂgPL¤ ÁÎ£ğfRÖ¾—kÁ}¶[§²-©¼š7X4‘qä»²[œØş]ßT!î¦|4:3»?ëÁI¶Ü|¤ ØRŸ¥Xj:ØÄ:•ıy¨4,M\ÄÿM.)YÕ±Ói›yÂ1\;–ßÊ£]9Í0RSv6ÕY9CÏ€¯©6+Ê¤6ô’ÈW“ÊSR½¬	"áy–„è‹]MÌöW?U`|'f«Kè±£½Ö_,ããBm‘‘±=aºûl~C/ÍÉg¨X<QĞú˜R³aD9Q¾Ş?ÁYÀ—UÚ&Õ×‡Ä`Ègò†2ƒÂL`¸=Ù„‚ ¢Ñ‘KÕ£zã3m(c7*¶¨ˆ›%ÂŒW)8óÌ2?' Òul	Á[]%¾î¤J#ß–xQÇokFQÂ÷(}ñâ{nqtQ¾oqÍ'øƒÌ§QPAÁtøö(‡9K‘6—‚%R/òÊ>P0úE6lİİ–¦ÀmşÍğ….o*T$C²\úkSš–åNQ¤‡˜¢æÁq¬yŠŠ#³Í&½BŒÎÕ[:•è%y?¢‰Ğ°
/ªØ!ÈÓò“®–»e8)<×û”á×ÇÃ’“L¯+#GaîÉ)Â°/Oå°ä{Uk†É
@…B¼¸ËPëÚ‰ø&øFø‘ö d š]Ò¤¢¦†À~¼yi"ó¥÷Ã­Íùêc]Š×…@C?«®M±ù÷œb¦Â¯{‡Ì–à„0&ÒûøD©¦<¹ã—ÀNÒùìù€¿í/%jkÅNÚ€& Um–×‡õäøï’lÿf:	­$ÕFÀE,NCÆ'v
£É&8«¾ÿ·ò5Í:_j“1¦¨9ñ§:Ô×p´­¶•º+Ğç¢›ûpù‡	ã“­$*´²¡’¥ŞxüåïÄ‹ÖÆ¹‡åC	Ş[KâP
Å]£ã¨Å É­h´rx(j -âóL‹'ğ×à	U-º…ö¥Au>¼
‘Ç?šË­†¦‘iÑOÆÄéöÀ‘|B¸œ!
	pXU¸4}ö&”‹‡¾g-d!cæ±D@Ñº|Th,ÕÍ…™ˆ^ïÑê•=noGÚ¶Ö+„å~T]…€>ovå<úº¯“^ÔæO·µ¬F®éu{6¶›®Ó·KO®–ÁÎh¶@6] +UÒk¶Î•ˆîÏÖ­Î=ßÏÁ‰wbû_¬ˆ:½ïEò¦£¢x£FèDôßfÿ1LœĞŸy.ÁJÜjÔ²as¿g&-ç÷oi´gàl'‡BÉŞe‚}¨¯¹Ş[×§QJQèpÀßÓoÌ®"9óÑ‡¹{¬Ÿ@Ìí„¬4à‚Š!•ÿ¬zĞ«âà…«€#rkv,|“vı&1;h´&|­^òÚÃÉMŞä.lØ¶Ö»>†¨?oŒ…0×&„nÑF¤8-q^GúSrX«º›œ¿¤5æÂ ¥à}!ßf…´ÃYÀê®\mŸ4àÉgËOXKèÄFèIl×ñwk[·¢¥¼ÿ SÉÿd—Oõ%†ÃJfDÁ±A;‹’Úõş43®\“Ã£o hèø9V¡Íh_ÖÏ£{qü:­xÒÈo§ú˜¬ğÌöo'*—
}ä‚Vb¾?×Í%ÉkAÚB)ÎÍF+4oõ”-èèN3ês®—Êüš$/È]T$™h #^Ë¼¤Ôà»Mí­¤xÄP	¡ B’¶:v»â W ±÷°ç€ö…E„¹²¿—N+Æê_¿ùˆ’¬HµvÂC‚Ü¾ç}$HÜ¬\F'sàa÷‚ZÕ´i~ ¿·r·É‰PMvæ¿ıä¶L¯•k) áÕó„ñôK¨éµ“ÆZ‹…äºhnÈn± KêV²õıÊ¼Ë‹ãas’ÉÄR{Ú½lÄá®)°¨îƒ­´œœ«µ²³iÄŒ1õÃ‡íœ—^Íğ·üÕ…&˜ÛS+Î¢¬U§Ÿ)ˆ2F°Ë/ä›³¶¡÷~[EKNßNôæÄ_%¸ª³N‰W;AˆÏõv­?§jÇIœK¹×QÑ]nˆß¬¢¯ÉA¾y(Y>L¯¶
h^ r»çW…å™#Å‡Œh˜Œ#iñÒŸI@ÀiÎëÂÄÒäz%±öÈ¼ÿà9ÉA"<b0P8ÖIcËP´ŸßÔÚeBØsK¨NëŞ~é\u ôÂ&N¸%ïà0oÁ²æ0˜³=½(„\ÏQV®Ùs·¸ø^®MÎöö?ç¶Z•Û¼ÿs©@}Ú‹…Zà®xÏ	2h4è2\K	GçKgá<Øc!<0·,rİO[Ì¯Aç­Àö:dÅò&„ÁAŞÍ³"UkÁØ*}³’_P¾œ6;*Ù[? J«2ãk¿×µç‰Àh‚YéÀÛ[e„Õ=Ä?ç…gw¿Vmî!¿Èõä·gR ñ²3ı7î»rb¡‰^8‚jÃ×ÓbÅ<•aY¡âvR§t÷Q£ïp/ÌÌOSç!§ğı .C‘Êú&ÖNJ¢4…C¿`r(å—ÃCOz¿ÊYkÅkUxMÍjã9)vÎá#N¹óSM›” ìƒ`vˆ¡‹”~Ÿ8B¢u:€œşT!Ìë0óàv/u·ÛFC”EÅÕÂåäåšÓ¿ù›Ü‹L‰NÿÜÑğTØĞÀË.¥3Lİ¤Çº¥É–ıçÙiD!E.¦üéC›†minñóšîx#LTà÷×ØH¢•vÊ¬Yî‡ÿ!ÚÔT@#§k¥~¾Ÿ|’Î±5$zcMD¯O¼à’¼û!®Ñ:CGÊ‡ÛIï¹”ÇYòHPKûÓã\q¦ŞŞŸŸ<ß&AÕµWÕA#9óæ\¢¨ÿÙªÿIµú¶Ø×÷›+ê¸ÌU ÷{»	ò« 'ÜHÀ<Ç)â»ÍêjP=f¾YóU)¹n»ÿ¦2ê>Gú[È¢×ÁŸæCÄy¼^Ìqà«4–VŞÃzu+&ƒ2åqÄ› …GÅOÎç‰V4¬6E0ÂUå0¹ï"œÜ¸%'µ§®¬„Vş1w?!ˆĞÏËsÒª¥EšÃb•8‚¨×Ö”ñrÜâ/ÒŸöX¸ó_*Ğí‡¹&où.’wÛ‹vÅËÁªğl‘{ì–k–å´i¸)\~íu¡Á«§0›Ù‹“ /¼w,ùvphuöQ	¿BÖ—s:~xD±` ²7_Ö/ÛËíÕ¶±n÷À8Š4>)|]CÑê¿~eV¾Mm…á_ì"Ÿ#W±°ÆxöçĞqmåaá+&ºa&—y=A¶Î¿=BìU¼ßã?wkÜ‚Å$8Úq„Añ:eİ$tKô³µim©Íš¾úµ$
Ö§u(¦DÌ9
†ÃX+œ’¾J$·¼Yƒ Ÿtÿv›Xq{ ò‰×œ4ÁÒÿéS¿½õXÏø8¤]«‘nh’ÛO®ÈJÑ
¦«¡&·sV:€7#µ5ªÁ¯2'Örºíìk –¬/*Z$½³¬›x”Š@!Æ÷D¸€‹Tğ½£¤…X*ĞÕ)Âµ­ÌÄBÍ›6å²óÉƒ°£õİÚ¨èK"4ø±KK$!2ï
Ú¹NBkÑˆW³ªúUí¹qèºo³:¡>ô×yhF£d»OÔ¼–
äM²¯:-§gkáÚ–Òúİşï†'¶a¨ŒÜ{çøÙèP×U\_hŒS¯­¡aTŸ~;´tü[¼ø$%d_â0[Š&;®•Õ©•F7}ılpıÄ¡_‹È»“Bè>„¡H	-1ç²Û~•¬À4om˜Óœ¨É4şË
²¾¤øí"§ØeêUèèT©?Z (ÖDlqy…ãº]))®p·ÏŒ¾Šü¥bXÿõM˜7ä8OC¢lëõî¼¹Ñz»WÒ$+BtvÄNımg§Ç¦Ô„lÜ#c”ç¨q›ÅíÕ÷¡óê+”êûçvNã–ûú%ôò× äÀ°ô><diŸ€¯
].ÚzÁ¸ó—¾y_
X½‡nøP”.×¸qëÉ©V«wD‹…qÇ0àMºÃ½ÈhÙÇ¾üûå ,£8g×•xî›„/ØÚÎiÛTp€û¾jØnÃ„#§ˆ„«É)ùHSBFogæ:™o—ÙºúC‰^lTc­iZVR†.(7¬5ÂMãe„XQlyXÀ²û£ëD“ª·Å<şÑoSjâx/„YämC¸=q)«šÃ€c%X“…9§$”¿·cúhÚ¿ÜKrÅ2q†ø¹0uHK€¨Zu_µ68Éê=k£f»¥¦år%B™h†Æ1á2^ĞNŸ­Û^Z«T“Ì|
f("³S=?Ùsh¦(@˜j)ˆ‘Í¼MXO3õ$S]›İ-z°c¤HÀY O‡TE8?u™²İ4¼Ùÿïgh¦¡Ñ§úcUê2tûã•/§•êPC¾a˜)q÷‰¤ÿòD8©-ˆ¿ö¼ç§*o¡`˜UâŸõÂ~8vù<NË(sèZ©ÑÖ´	(LÔ"rË&é6<òª_ÈG9pîu\·Ç°OoQ¾ÎãJòp:<ÆÉ°I½”ª7°/sµr…ş»¸İ²óÖ×=rQURCèÔ}q%Å,½3ò¢r}„zysCËs.D›oğ"£A>_÷§’ŞqFã«NuNVÜ5´=Òëõyè¬#€îè ù+oWª¿½ÛFa[Å@=ÑPwEûQp †v¡¹>¢ràŠ½€†ÕUÿ¹£®Ô°ºŞ¦QäWO˜ï–¢ĞşëàåİÚ ã}X¶b©¥/¿ŒÎÚÙ,B{U&qÂ(ˆ BÂg°Ä =:À‘ò4¶u$üz÷SKí´pA)]zügR†Xz˜~íüÎmĞåyµ8âèi¬<‘;ßãeù4õoüÁF•ÏÍ“F´¿î#’öw3¡Ö>†àv¯ ÒV,Á6q‹Ex¢û²aóOSp õ•~ò_54ÃŒC®¶Ô&ò<ùKòx‚Ç­˜I›B›àò¾gwÚ·³˜³LoêŸ}ëÙäšÜ_ˆ*™ĞäşáÕ®·‡ò‚fRóÊã~Ì›l„§Ïİ×ÿ+.·ºO’²«MÌá-Sn÷‘÷˜š¨S‰‚º©$ ½$§x­˜â¢f·uûø$¢5‰¼rÇKşO9š$SÙ7¬Üú/•¨Õ6lã~Ÿv7óQg¶#é§]$†8³¢‹Ÿ	MR“-ûˆ§¸ûp¨{Zª'xOÛ'õ÷—˜g›Œ¸å)jï…q’H·>Ó5ÔÊQ=¾}-eo{b¹ƒ8£UuŞN»`ˆAƒâóæ[e$g×ØŒÛ-V6YH&ÖüO…=Âi—:p8(ºƒºA@îŞ€¯íÌ k¦Û¾Ş!á,BgK¶áÛ£ö¡H9[ë|ãÙÈóL|ü§¥0Ov—üchŠ¯.ñY´)wqCŒ°ó„;›È[J}[KMÃ¥7u¦¼ê«Ó1À.›‘±²şàpÃ­7oùuXÛínw oG\h‘``wYù°7VÌãšv\½wm\ln„…İß<E°%ÿé>T«Ù«ÀOXLç±ûõÈN1{- Ã¤ƒ|Z.Í‡ïoà˜½œîh'‚ªG?eGüaOÊú…ÀÂ„Éw=u@ù`.ù/ô½–Ä½œÑ·¶al‹¥’XQ€i”¶ÈÊœÜŞ.Wï¥ÔsªÜ9MP<AÙc+Gış8Y‡òÉƒò™€OœRbÓPêA¶/£ƒÙ¹°èì?c%¼H•»?¬+Ì Ã#Wõ£Ç3ê(Ú0ö[çùLéXM|Í
³².RªÁİo+üµ\1¢Qç$sÉfx)•ÒDz¤«´i®ÚFO2)”G«´B§ºwÑ˜Š7‡.$T<IãÁôw§%OÀ#VA¹0ñ&QA%ÅÇ»A¬Câ‚X^šI”M™}n©û8;.OËj³ô*>û&xzgD‚¯Oá@ŠOgbí3GÛç3(ÿ¤|¶a·}“]=Óª>á[Y®…‹ç¥I&ĞG¥Ü
Ş›ô/BLıèøxy±%¨fA¦
Ö!! $±6@k±ëØÈ°pt·»ÂÈ¦3÷{ÑO9¿É¶ĞÎ¶üÃ3¤•oğè“ ¹§ÔÅmµõ¼}Émx…j¡zUŠ²ùıÿR]´à-« ·d:ƒ¬‡ï¶kY'‡N›’»½Kù#ƒ5ø±D=ş–‹£‹)¦ g>G»”ÚäI¹fØv‰”è¿¨…DxÏuãÌ‘ Wİ¦İsÊ›6’‰!jx«¶½…Ç*hş¦ç!œaÙfQ™¯—|òC©Gy¬Ç[ÔÊD©×_Çc!ïª¯ˆ°µ»¦™gœï¶9PòÅš:»GXT' B¾Mú{ }%H-{£ÉeW`f‰K´Ò-ÖwSl¼7ÎÔÎN¬¥PŞĞ¡ß&Åúwjø_ëÊpHÕ¤Æ`LÎ
MÎs‚^”Àa¶™J“´Û¥.õÕ‹@;ĞºhjVØÿC…(ÿ$¤Ör=æÚDncêJëZÔ‰mœnÙ‰¥„<Fh§sLP rŠx¼ş€××[ç€¹Å#7{D¥,¥çÒˆ%)˜KŸÆ(,Á4H"õŞp5{Î•¥'åkP£ã£«WÕnMü‰k_Ì•æÍ7Ì¯ûÔ(\¦§¾VRïë9« ·hLH”9ÍÙC¼Ô €6€.,CáFmÑ:½@£FK:œÕ‹1*cf6ÎK[hØ,X&ê·š³rCÌÏ(¥#ØÉÊa˜!ô1B•Â®s±Ç¯¸š1[%š}5wäÀŠê¿
X€1x´Ån¯MM³$Ã§»+Š -^óûâ¡ŠäìøõB91ºğ“Iy9nLÊ¤’ê­¨u}öyIJ+âh;|üpçˆÖ¤ÿE­®­°{ç@f oh?põ×mÜÊSŠ‘%Ä¡NN%ìëO¬·Ù¥p-ÒcĞÉ-ø×U%Ê¢å»Ğ›¬ÆÜÀ†Ÿk‰ú†ïÿ£÷š«_³Õ"±b[<ğ›ıÖÚ \L?äĞ¯ÙPÑ€ó"¾qâ¿1ÆYL—™µ³¼@á“´¤Xt<ğà3‚9ò•lÂá?áùÙ1-R…y!´ğ¿LÿÆeúb÷Kw6J9¨–=‡ê_ó€ÕpâZƒŒuÅ8ÀşÏÒFØïRÏŠ†· ìRÖ6ÑÎğğÊú	Bµ%ûü4Nt—S[Ú>pø2eôüÎÉ|H¾»İ'‡ò–¬™Wt[ˆÑîNƒ"Ìö×,3‘x:²Ö@é<ÑùlS©PR¡€Õqö†|"I´z¸ä®sŠÊ½iFloï›èÅ`GnH£¢r'^DKwIÇRTj{h²P¤™º”ü´`û)ƒŞ16éXK‰íåµkÄ“­¿);sm»âÚİ`XE†à™â€:¶Tk‡ì³^X62AxÎãçİíÀ£÷Ë5áßo'pTÿ‰0†BæMV¸Ğkİ¡4õV@N%_Ú…;$W/£¼›Yè[ÏRPx~¬br»RñFÈ©5ŸF?gE^ÓNR2¢Cj¸~§‰\=äÉ,™Üãà3³ëÙt¾/ÅQÅ’}E“È:Tà½ñ¡àÎfÇ¢JdnFÊ+hPAm\`¿QF·SÕÖë¡X	n-ùé â[õedi°©[‰]È¶nhü+0x÷•„(3’Èc.Wic3Ïœ³1©3;r©Z3Åİ˜uâ¦]”üî‰¸×ì<÷Å¨779ëTÊâº¯cv~ñÊÇRİñNËâ›U&3*æ"|óL§ÕƒJÍ³ ä‚ô«gqÁ"Œ™+×Ê¾}3d¦ì[	T¦'KÇ±ÍÓ arÍ=j&ˆ‚G˜5Ùw™¹dêİwdêcÍ6¼ÿŒ[f]hn›$Ê&Ô•Æó-›=Èi¸zgum×à §Ì£D:„ŞİÏ,
Å?¦m};Ñ»›fƒ´op^i>ñ§±èRcŸÚ°B‚³V*LQô&¤´°˜Yı86¥óÀÍè03G±*+iÀ“w˜` ¹v·ê¢ïİpÿÑ¢LZÒGÊ“İ}]&›åµ|¦Î­„¼Y—CHPåŒ˜İ…Ø7¥Ã„ÊÆg1Sı¶,bpÛ>îf×Rêz?_ĞK Ü
CtÂˆÊA ™™‚Ğ˜Ó¤«2
ØÇy*BÇ]Ú‚ÒUtéÄ³øÓ»µÖ S*€+!@y­ª«±O×¿JÆà¦L—TñazdŠ<ëú"	;ûÜxró)úX~(q}wˆşçĞ@Ñv¶ SWa×/!_‡·U;{&şW×»ÓÂ¿®lch›¯š|Ég$ãÂÓŒÆt…Æ\‡QµÕ(ÃïXD:ÄøùT¿óÑğ¢·î­Cõkÿğ§ƒş¦dé´^àVÔÁ†ª¡d›gßêá«w”#40%Ã¯Ø·ıYYK¢R?>ÏVĞ-àBrå¦¤KÉ_ÒÔ0cïbPO0ßĞ—êÜw`«ş}UGj$®T‘m?îÂåïµmÁÿæ|‹0¦ˆÒ­Ïüª£ät%ê&å±[*î‰ÔÓ©}:ƒì°4ûÃfŞ±Ê¢D¾öİËæ€Îò…ã»½‘]ZÛQoóŸª–ò]`ÄX…4^êbÚç¢Piû€<³7ˆ4çÚuÔ4hoÂ‘Ã	Şò€Îª>) |¤öd³}ù»7†î[”lƒBüˆFô˜ÑjuYÅÚ_”ö"xEr6#òUõË¼pXo<™%C³uD$Ì—x _E˜¼r ±"Ïh“lfd9iª“î1Ã.8Óãü˜M/“û›Úüù¥˜ŠÙ2ÈÓ56ÑşÄT’,»ÿ]õË"A%g`¶+‹£ôV1®ØÖ‡	iG5æ†«ïÕú¥c]}th6Öó)÷û¶™.~kLßÔĞDU{Ïi.BCÇKßÇä¦ ”ã`bT×	œ¿9k]8å}®ü!ÀÊO£äËD¹A8Hû˜ò§=‹ò
‰ÉåĞg†äq‘ Äv‹}`‹ÿ4S¸ĞYÊ8¯fÒ:éCÄïÚ”óååUˆyuñ¶E&‰Ö»Û÷rE0†ö;ª†TÔ³Û÷lŠ–§@ìé°ŠÉDºÜ÷ö›çÿ¢DM^v¾S1o³Yê:¬«MÆş:Ó´½AkiV‰è\ê7n½û¢üÀ<9èÏ|U¨§J.4üÚø=]ß%¸ñûóÕ?Şü¨àÁæe}­÷hãr‡ˆS= ëx½ÂN¦Ü
ˆÏğº¦ØP½Ò_2o6wù,û€8ÀµGqÄçş€nÆÎk(½–öD¬İ>ıA*›ßå+P¿†—
ı2d5¿@É_+.uæÕtØ€éÏŞÍÔ1YL-ŒÓDI×”–%–áÃÔäÚì³Ã®ÂğQ§ØÙ6«ƒ¨ÔOoì(B‰ÍNFIO]hs·i^éÌKÕ¾ÿpz¬.d]ı¿I.òÂc¶:ğ©¥â!Ÿ6o{ÀJ_søjã´î,€¼	—Øë&	wnĞp5RòI¤¤ëS²ñ4Á=@øõ½ÿ~úDOŞ´YˆCÔÒÓã,×8«Ìµ mK?| ÿ”Ïíò^Fh˜•‚w¤âû ß×ëì¯Hß"N¹beÇp˜‰`ù)rÓMi5uƒNÊ]aQ#gõñ¦)%ªYyÒò°İ÷]Uvó’òmŠa0ÔYÓ*lwVt.Ë3ÈàŸŠ>à¼,¯Û›2¥œSšõ`O$yv„ñ: ·)¤ª]“dîò(ã½(U˜üÜ7$l¯?TSD…eĞ]P¡LMô<ëCª‰ó‡¬èÊ…µPfÆÖI†K]c1íÌ•T§çR²zta5Õèâõ™ü¿°•‹L¬”¨¥ú{–<üp§u„Z,xÆ…ı*g«ív±²¼7I6K;©wOqø†'C½¿	ÄwuØ«¬pÂZÑú^5¨‡˜b"–X‘³eB´„Xa‡WJuŒŸÚÅÑ¯ªN;Hv¸¢ÖI>Ô6¯Y±é`D’ÀÍuúeOì4F	·tJ0!tŠÓeıE'™=›vkCßVl*ÿÎè€äì¡÷Ç%ëÖã]:‰½^j‹DC‹<Šı<µ‹ÿ©•“l'°$ğc²RÂÍ¢^R@ã™ÅÙ47`ªi($Åz"…P!–eÌš´YBwáU“éu†—ƒ&0Õûä¥£‚£•Ó˜Ö>øä"U2sïMoy©`«#Õ€ñVÂ‡§ˆ”
 Ÿë¿&MÆ³If+a×L0aãâÆ'ÀEÓâÇD¸X ¼˜ÉÑÇ»gé€™£,ÜşÕ“ù©óĞú~ F=Ü

_j,«gá!€^½ùòø±¿ªjğØZ§¨j…-Ş¢şFÜc¶wuŠ¡5«C¿Ş™èl€¦Ë,¬¶]e1Õ&-ş%¡Ú8.ÌõVCP°RnpÈW(S‹”ãEê(œ-{JpöªÇÉp+†N1¶ÍÕ·gr ¥ùè=PzÅºPGıÆÁH‚–ô=Yæé‹|G’]€¬l˜ÚğùÑPeÜ±ŸQĞıxåYÒİpÕ#+É®DWĞãİY†í7`du$Ø@3xhŞÄ"y2’ğå5ˆwæÕQ¾­t¹Û'Š‹ˆDªCÄ<öBX$:\ÿìïÆjOÏ””¶† Q% Sg×ê»b ™Sd^ÙÌ§Ç·®É£MYsB\¿.­›!¬³Pò»t}äg«ù=›pv'!›úDø´Ì:¼[W‘vè¦×<	Oüi)dòVl¬l·C‰itœ¦å«ñ2ÌÍä¸-•E oÅh8odi§Ú^#ş• ¹¨¹Ây­Æ4f ¬ÄØUâíí"X!Õ£J¹¼0ÂL¶©•Æ+ò1N•¨œÙÊ„ÂŠµ0ŠTºà¯6WÛ-5GüÔ¾xæQDß²a—È^1hP—‡ĞĞŸöĞ6 µaö’Tpdğ•1Ê¢-:~Š¸Ci…üÇ†çæ+–¥A€ê¾ *Ğ“T”#<–¨s³|+Õô`ÛI¦H]Ö‘L%ZºŞAP7Thv-‚À (sm_‰Æpæı4Â;Ü–ìqC´ìC
á[şóÊ•HÖ²EY^½Ú¼P‰ëïôô=¿	[×ãW~8s 5¿^§ˆ÷¦¸ƒez8îºô8½ÛÒ†•AQ.œ÷‡ôT˜Æ]Ò­”ÿ¢|ƒšáFù–çÑé.p_$-%ô9zûT’ *&ßû/ÈòúÑS+n‡u–!ÛKÄ‡UÃUÔDEPH\,#´İâWŞ”`k!¢F…ûÈè×,Šê?
™5#<†EQ"ñ¡x¥o–âÔò8æmM¸ôiÌ˜>›ìÅ/Ì~ÑF!¸wsÍaœi’kM…qøhŒœ~Ş$G€s#ß2q‰7¸³—x¿¾#gW'ËØã8U^>EÆÄõ»´Ûµ…8PO¸sŒdYJ›Ï@Ø¬œZªïŞ ².DP?ì¿#ü|_¡ìJ±Õg%D…>P`6"hD³Q_Š'™¿ou0ğs²Ú+–ÄÏÁî'Äo`æü¨y,Ño*Ş	ŸÕaLCZã¯†}KáÃ·ãBgÕUXE¯ZÃ@õ$™ÿŞ6ÜçluQ°„]í¼ıßu]*ü™ç”©9øM<u=±ç@7»ÄÿXíôòt‚íu;Aœë¯EçLxDRe)°îŞ[AÜR,Né.Yô½ÿ\ÔurÔg¹K¶h|×ˆÉ½"”ÇègÍ†É”iÃÛ±T°fl©+Y¡&Š‚÷;úÎ»>û®eŠåd“üë–cúÅêúîr&ƒLÉ Âw%ŞEÏÈ^òQ5,/A]¬±×a¥]K†X·²N
| QÁ®wy‰ïKŸp5ÛñèT?KÎxU¼‹n-ìMğåÜyıDú1º3‡+&:«¸70ºôe+9,ô·ï:ÅÊóqşÒA# J\Ø‘õNñ1*¯5á+à2O`ÓÎ£Ş¨."šÂzÇp~GBôweÀ`ÉŒIâãíZ¥6|-Â
±ÔØyZØ”ïqË Ğ‚z½ú:’ÊE¨,
H¯®k÷Ş MD>­
pş„&Ù,ô4öE4a¦×NrÛ–İ#96#sSQO˜Èw¥nûÄ"„–­	’ÂšßtÏpì­6Ôo{´×áMŠthÏs0ßz÷KF/ë(‡_ ½ïô4¼OúoC×I8³şäÃ§áÁNº‘f+6ñÄÂæ¤ì[°H
=>é°¶_6|¡YÚcYÊ&¾oõ¯ëhrÑƒkg”‰Ë†K]ò:o'/:ı‰ô]E{"ÿz{GôštìB7™ëˆfq»áÔ¯‰_Q-—â I²•×ë#T£PÚ…8*²dïçønçïÈâYUR¢6¤¢šne/*UÉ±‘œwËÈ7­>mÂîÂİ‡˜’)Ô‡´}gÄs@é)½|“ƒàË&{êÇ4ğU¦ÃhJŠYŒ^ËÔµuã¸<´$ÀÙBÖ3Ú'À˜\PUöíÛûõC2®÷´QÓ¬>ã\üTôéÜÍíurNÎ”&MÔ€f¨qí…‹¡"o÷P´älUK¿áA`ò‰ık½0ïğ²¨ãñOÌ}töƒx¹Øêí~§U8fÑÜngŠkï¶lHW5›êÛ¿ååªSH‘‚Àdc{&·Š>)wEı`ƒîGi×½Ç ”0Ã5=ãÕ{)ƒÏÊ ú —Óï´YŸŠ¼ÛGymçñ(ØD’Şr” ¢­é8œzhXrÓ&_rI°P!Agæ‰½°xÓAs“É¡.ÙğÂ>#´…ó˜±"å7UÀ³áˆ)]´Ø[y§vOC³7óP¯Uøÿ—¼@š«Û¶ÿö¦È®o9ös%ùÈ—Â§t{å8{³RvjŞQ›7±Jñ»[[ŠnÌÌüI&øv²¹J‰'`#›¨öYk0ıÓä@ÜB+Ğ.d¸lhFDé €Úd›Ã²8üİWùâvèïµk¡t&MO"#¿¦¢F]‡ıUDºçª˜*±.Šä¨Ç¿Éi‡‘"ä´péÚƒ#ím•Æ{å¬ìa{Ú°Ø±DìÓº²aâ;Ş¡’Ë«˜çØã'Œlœúb%»ñ2áÎéúïw	2ĞòÇÆ4‹ªüŞ‰?‹”A1Ãûp'“‰]æI ¿; fø,Šh‰?©l“ë¼J«o_·ö©Ù›DsMÒ3÷ñ—àü¸c~Eôz/
Êã™Ğ¿­úÑ³T‘¦·LF‡]qÒ«3F
È­™@9ÃöÜÕ·¿è¢8IvÆ«óµ÷é2—h¾rl»,ñ{ÒB±;Zïi@ƒ©X5b/Óª­Kfu—Ù©ÙG«ÑÄTÿÕ6Õ]™ô¯âö¢hã›åd~Fà^ç¦d±ÙiE#i–UŸM™<p‰PƒÒ¢hIñ©ÅHDx®?Íwcá/?°^p½<€;#ƒĞ¿AWC:¨’#Éİ¡—-×:ªÚİ¼šZd¼TJ pŸYO¨–à¶MµûŸ€ÇıAÛJ°}¼è*œ+4Ó1ê	ø‘í82H-MlGÌY6uQİ[_s	Şî¦QŒ ¦IÙO´*Çj› tìP©6½h«¹pÙL¢Šh„…ÂÀÂ(•Â…,´ëæÏL½ë¢%7!ãíêìDİçûC+ù’b4…PgãÊŒ’¶×B_ÄOQÂÕ{	áRzl9ƒOÔîÚ}‚ü& üjA]ÎQ"¼F…­¦lêgèbE$FÛK÷û‘Är+¼û`ADà)­-äwl'áSÑƒ£×[b§´Y›ÛŞª6¢ zˆ~ÑZƒÚLQ\?œ2~ñÓÖ Èñê·àc,¬„ó7kãgÆ°?,¹jvÇYÁZP0»åìeÏÕ ê
™Ğ<Y#ÎEH”±cğô0&³´Ğvµ|™XdóML7O¬Êà¡"&ÚïkÊP¥35 ÑVoå>0hêKÃ+<bÍ¦eX½(Z=…%äñHtÔü{+_—°ñ²øë€n$•€ôj4¥ ŸÍ¼ÿìÉKË]=¶ë Ş wkıÜ®ı$Œ*-fª¿æ‰äÎ—Í4b‘êöFá^%I%ìü&* üôïtßsAî’ëµˆxO‘|Í¼BñË4ä3hîöÉ|ÜÕ~9TZoÒ†£CF2)M<,ÑUé)FQ3xƒ•BÊY´.<–¸wŠ“<ƒ+·:™8Xúb¦ÿLAõ»íàA¬şäZtfæéÿl ÷ş?™(P:Y¡“[L û‰¤9ó»@'¿B‚xİeøT¡F–\…ˆPW†n‘-$Z®ûdy€±!ï5’mnZ-ã’.L)n“ÆÎ™`–™§:ÌYŠ±ODÑP,Û§ë¦;_enXEm½Êß"Ú¹ö±Gæ)dú1B
rú²fäÕOF€dİC$0…l3H<Í&92ÈË—î§E f†øÜY—LÁû–'Ÿ<VÉÑÖKß[	½‹|·@ck½£†€¾D­8ø[‘…çñ×x¶=@W¹Í2êéÆ>LûcÏìT.××|[QÙaºµe}ì@ñı¾Îà‡J[Í„ßĞ¢'Œ?ŒĞ7Â]òUq¡ó8ßEŸJŒ‹‚,s¥KœVÓ“¬n€5³¹ÆùÊgµ+Ê×Zú'étT"Ù˜qãSÍâêİ1İ]m‚¸Û)
øÂq|-îš¸‹Ù2è¼G8¬Ç>×™^s7g-’ü´€	dóU!@cÑ[fêd‚wQG-1[Qß}9ı%Zûe¯ÒïÑ|…8T’§D¢­‚ûp­İ*C/<;ô»™™ûôgö2›µ_¯c‰Jò;‰kj!/SSŒ!†[ò²U‡õJş›'¤‹ƒº)-x©ÑgŠ÷>drÎp-ˆ*Ş†Yª¹„ûæS*â¨dÙŠ²›¨BøfJ~˜‘Fı©šD->šûK0oÜÈ­.=ü—€AŠ»ò_—h©lv(Ê‹]Åj°_íyñ£3&ÆÅwoÛ¾éTÂÄ«23ÍªÄqDŞ0óYî?W“ÆŸ ArûŞswÆáÓª0«ˆ
¹®óPÜ’v…VT
âJF(¾)!üŞ¤¢÷ëM*†éÔWrüN¥
†ŞH¯Ó@\ÌR=qÖ·˜ÈıÍŠ‰CÅÆ¤‡Sãô‹ÃÂ¯»¶9±Y@E7;tåàÉG}#
vóêÒ)è0Á<Ls0sGÜón\ 5:JÈ‘°ğTÿÑSpg~ÀV©´?'8*øÛf%³ç¢ÛèO9ä@±%­ŞT¬~x9<’ê&_UHß‡%áT!ÎÙMU8U)yÛöIìqJSˆDÏEH£-€˜yd2®jZZ¡ºdæé©pÇë°¯Ì”©ËÙ^LOÔB|ßEÆqt4âp¤Ë®Ğ!áõAg†–>#µI „|ı£3?&·ÉÉËÂ€S²@å·gm˜)hÂjü§¹rzª›oşÈ
¸Æƒàz.3T2L2ĞÆ­hĞ>]ª2pX–°eã"”d&Ì¥E½§†úÌÇ·>›i±®µÚ;˜²^°MöÁó‹ùwŒË ä@!»#hT  Kp#ƒatˆÈã6õÅ®7q†ü„|®¼mTÑ?²U4_Ø{
³S¼ú›š»“ EİurÂDŸœãÿ/3=aÉŠÿ.ˆgqMzœ÷á¹Cg*kµE’²@.:ô«R	ë˜qS£OP|G+í‚§Ë˜âÀ#éÎŸL*}Å*FŠEÚjÜÎF]o3Ç›Â2dN||ÊŒPà~?.`]VÍ4ŞYÁ¥ÕşBz2ôÒôf‚ÿp™PgõKkŞt¨óta'ÿ^#=ø~.¼û”_óNïhrÌz¶8¾ÜX9*’…±SÔŞÅ<Í„AúæQå.ÿ0ºèuéÛqĞÛ"ìƒš4& ˆŒ4x2îØ¢ãVC?‰/XXíO¿M|·2„£÷'dS6§„bÃW/øı5VÂ§ä%õ¼*}bdÑ1º£êB
¨æüõˆ^eö‡N¶tÌ°ÑñøÿıH½{Î»HUtûáIšY#áÌmÓXEºÏáH5…s&3)À/ğÇè&j‹|¹|°Yï4+Y•(o&ğK|hs7¡7ØON^Éhåtj2Ìr]_Ç7ó_n‚DïÄ_’ÂHÈ—Úˆûœ°ÆÜ)aÒUg5Ğ|=!O!Êšxx†O›’\?„•ÉUÉøŸÇYôGöå‡Vß¼ªRæÈ×ŸÜkXswµWG×ï}À3à·×íD/ªh«ƒÊÈÇ–XNò6”÷²ØÍCàÓ
ZÕ¯ç.¬VõÇí@N¼ßğt/1ï°ÖÍÅ‡SSß
ß]İú.IŸ¼ˆµ»tk.˜Ø/Ã|¦¼X‰â;|Áµè]W@ h°cƒ¢.{5æ7ÆÂQ{K™şS ´ß%Gˆƒ]ˆâÖF™0ôÃ7ÊU²go•pEŠ€ÅEl€Å)Å1œJ`X¨³^á¹Mrºrÿx‰_4Øü1»*_`‰pîºsÓÿ–¯v?/t Çµz2£¿E3¾’ÁäUVÃ…˜;›SàoÓ·¨î"³¶ÕŞÄÜÃ‡úq{«A+ÀÇ›àCB€ZŸpM®Æ¶Öı%ğ±jÈQÃ(×;4,Š½Óç¤=íÂ2¯•j7unİ?2V ø¦™`3–¬å'Ã"ï#¸AØÁûzü¶ºn©¨]›¬ HiuîëlÎÆ“‚ïI,YPGj“Œ¾€·«§àußô¾´÷äÖh[…Øá-pÒšA©êkÒ»«BFöü~®@;Ş²z^.ä™Ä'¯²Ó†fßâ·jÅ	Ü|í1gUèRµ"Ù4…ºü\,£U}æÛ¹h85Jr·ƒ4¸TW”Š€„p¶ÁİIqUŸº]•[?]‡Êøe:©Æß‰{šÔK—dmG»xtÑĞ!œHOA á†p-AûD¤œxá™9ãšx¢NŞ¡Ve>G/•ñª“¦è½ƒ…”üùÑòH‡É,d&.û,+*Ÿ‹nÇıÑÒHˆ¢˜Gâ6Œü5úé;ÔeÃÓ…ö{!NÈ»†«Û*Ò¸3)„,~Ù-¢Qe÷´¶_sgIt}"¿Ëû«‚x€6 ïÉÊ'V-ƒ][s[Kê]ÖşmyşX\Jğ­>eR m˜‹ÓuƒÒvÆ½JãğÈb™zãZc€q¡(C€¥JˆY(vË2¶‘Ùå—Ç˜Å_W±·:A·‹®w88Tôßy«ü<îÒU÷|K•­´t›û5Y1¡~\ĞN:Å{,¿á•éOm±ìL2ÖÖ6zÌÉĞ‰# aBÀ)áãœ>çdñâoÚİÿ…Ô¬\¢BoW}k­|4×¨_‘;÷ÌÊyy€{Ş>ô*hg:¤ï¯qV°ÔH6"8-c¡nŠó0qÍ¸K¥ºì½ô¶áoÚ~E¨õbù˜â$
![VÈåcòÖ3¡Š1Šu±ì±†º¢WÂ†½;9_Ë_;UË?íH³ƒ§Ñ¥¯Y›Ÿ˜tÄ—é%üŸG÷¡Í0.+\¿/â›&iT…ªz>^b(Ü,	*BvÄZÇ×bN½h}q0V½`NÁ«'İº—
¤ƒéåˆoÜsÒ„rc¯Æ£wáğê>^ÈHŞá<¬Eì¸%²4nå
îá)0à¾ Ï±y$7#Ç‰ÇB¤0aåŠ¨Ó«,OÕÒA~Ì¬s5uX)¹×ÒÅÒ±’¢xH€P¯õ*;.Ñ¦)î»"µ`i ñh dx;óë':D”Œ#ú÷ìdoÿÌ£ÄúÒ9Éyïè(»Ğ3VH«~UpØcEgŸC kcfÆÙe&dİU)×ÍC¼½Ä8ød@]µ-U”6 ë„„Ş}œLÎ£´9Ê£2y÷—® ÑoDÌ›î€À²†tÚè¨v i[|˜’»ùÒjUmZM¬ Œ´ Ó®?×¤Úƒ'†šË6bÄ‘ç\sŒ¸{ÍM–Ãt|7yşãÒÛ@ôÇˆaÒå†í•µ¨¶dÂ7>½²Ñ9¡°†^¤—ÕG‹gFJúàôïMÉ-3£º!½bÆÈÄµöÊb8tdê_Yh}r7ª§Œ²Ãiq~*³ä-e*ù$pıç£BÛõÁò–‰®ÖµtÄšªéIB}&ç,X×˜Ø™›•
*ññc¾LdÀÛ
f¹TH·,iĞÎÅÀ¥¨cÜtÕ³?ÖŒøòGÛ’â»œ¨·%÷ğ­¨_
ZÕ™†/Ñö‰uˆ]rc(—İİùÌÈfë»b\/ˆâ4!Öã‘×›Õ2Àß'¢¦º5ÂŒöÄJ91-~ÚgT–CÓv_Ë—’ÀİW©Y¸rB5Í³Z— {hÿÌüŞX¼R’tãÍÂÿŞ¦[¿6dø»ÅÿÿD¸¤©K~ì6KC8%PÛÆV`ä/Øz:Oêeñ,~oX	#"}C¶¯*«rCx&±SØ*ĞÃa‡êëZw®~dª
.RësWWî'#¤1˜«ƒQŞ¸ëOÏØZı£J7­ˆQ) 2ãh;Ş&Ru…-Ä¨ÒŸe„é…¾/ÂÙ”¢_0¸®¡‚öVZJóAonâ‡áKXÕ¹«´˜Œ¦‡‹êÃÀO¼Ùú¯+,¨]¬˜áu¸[Ğ¹È)FH¾á 8eÿ§–•«¾şéÂÈ¬g]ï0,1ùfB-bt2; èBúÀ¿àácx+ŒıB1İîk,Ö·öî>=)Öj™…7nı8ˆldª¡®ãaC£öï„÷Ÿ-ÑÑ¿Sşİw<²< ¨îíMğõ–aë,\½Æ(õÓÄ?ûQê|¯¶Éøõ «VİÎês5•ºïœ;@œ­İuã ²É¤¨‹©ìÄN"ªÆOè.½;¬¹Uşv+=°“ğüı”‚^ÛS{ÃÕ´Ÿ¸_2ƒÅú×æğHúÀ!Òé<*‘Š%^7Ÿ†™Ì‰l©HØKy¹Q†GÔ ä?¹{'SŸyã5²}Rp¤êï®Ìû¸h¤èßÈÎŒS×èËàS§A¨›Ê‰t¦+¼H„‰¤ft†wÄú*ˆ!óê@e‚íéÛı%¤ÕY¿â†Â‚$#ç kêªzìÃ‡±ô|İNc…ªãšr¨Ó1ì7«å>Gmõ4iH5Ü(sZ”µÿñsO±6WHv‡íF<ÁR`ÌGl>(œô£±´1VŞ[•Sl»xŒ.Nè‚Î¾i/AøIW¥n+C„¯7Áß¹ÙùGe2,µM`Ş•¶g…	çc$å”¢e-v‡#Ñ”(½îVÌ‚½ïMö“½òC”šÖ0f(Â¯F>×°şş»îñN}Ä•0‰‰µàVíçÀ+9}v	ñf‡ÜDoyD°ld#‹Ø{¢A%¢\ËÀç HæòW§ÂáÂŒJecáå=hŒÍ²ˆ3¥Ä8,–
^kÅÂÒ5{xî¤ˆŞä&ÛÖ1J±Ğ’8¸ak3ÄÉ¶)¶<QÓ¿¯f™æ™ÇDVG®ş€Ùñ"”è`Ö9¦ÿ–mT9Òí±vş¨\H=‚\ğ„óu_Ó!O€§…½OALuòV¤]ùéTÙ‹7dò­Œòş€CK{ vãy<áĞAÿ‡ú)ê¬¦^sìDF†[¯ˆd´M!¿D^#&YñGiµoïì¿­‚k¤5ÁTßÍœ dšã·\.d‹
_Ä—`DÄƒŞàqß2ËÂ¯tµ“8EÈõI«°'¤gÇORÔ?•LéEòÆÑi
Ûxu3Áë• dga§êa¿fß…²€KûÎ½PFÑJ1fÒãq£»;½ıuÇ253†T‘½r¤dºÇ(Ic4!iÃ®–¶oË9­–´‚Å½ÔM1¢Šxóà©óêd€ÿÁ2wéôştÏKş¾<Ÿ™gæÀˆ ]Ş·S¼ànœÃ7/èä9¾ÃˆZ™EV=ÈÉAµuÏıáÜ KMYYĞf´¨<‘G~<Zw˜ŠÊ‰Øôx´›¨€íÍÿt7İÚ6(ÛÀ£îrœËêaÖ”,ØêÛ^Y“´ÕH)@‰FÆ%×º[kİ¥ñ6¼º¤õ:)¼±-cüâkÒšü8¡s&‰’¼˜O¢Ø·-*÷7B´ÆµôËÙvzû}f¾ˆ.ß=S·«rŸn[Û"ÔŒNoZ™¹p´îŒà£*Ÿ›2L4É¾‚Tùâ-eËˆÕ·`ß)M9š¨[¨r.¸¤[Tãj‡£ƒ¤Ï‘ç7N
±~óÕNÛ’…=LJÿdÇâ–Ã¯o‚};«Çh!cĞ$ÏZÄÇ/ı<¿ÉŞØıÑà+ì.ËÆÓ£~Ä¡6/jz¡ãA£ä''ô/Öwy‚Ú9»OcT€ul°¤Kd˜¹7ıËıa×p÷ŸØì ö2Ğc®x&‰«¨Ç;ª>§}_Â—£$ËÇö&>}¸í¼ïâ¾ƒ‹û!Åğ~ºs*.%'æí_ÆîuØ—‚=çÁ÷1¶¤	÷^ôXv}%p¸ã0»Û ÍÃoıD½0YcÈJÓÒÈæ÷–ñõœ_oØ•$›Y:vehÔáÆò7mÏ	G²rE54}ı¶%¨%Yá…8à€”B=ª"0ÂÉ ÔÂU'!s€WÍ§mÄ¤póŞpE%Ä8êÄjãÒÎ·eöe»åA&§Hÿ]#t¨Áö*uêØwøS0'Û¨¶áè±Éğ¡üfF¼Á!s)W]Vİ_W„$!ËÒ®|«	b‰»ëã1T	Lî"6¢¸M™[PØÍ3ü¤Q*Nb]<¸F¦şbsªl’§}Ëq? Ô@„*õSng“^2²’ïŒÎvR[³ˆH“›ÑŸ.E8‰•‘Öüò;ã•-j]’¶†5İpÒ]j_š 8‚/òãdËåx¦âÜ÷w“ze—H™·v;8h¾øÍr¦Ã@0ÖN¯”‘G´ğœ¥×°>èRÜ2x“Yš£këäŠb¶Àl@lÉoqJ÷ú
U’ï"/Ú4p}Ñ}ÑöÁ¯äPŒù‡O7tÆÍyp¡t“dê£³3V–h9¶Ù0Ü†Ü‹imF©aŒüGLİÀ/S(}¯Î—2ğÛôÃŞcXLŞ}ˆØóx§[‹ıaDƒÖC„æØ“É1ü%Ù½~Ck6©Š6/ğ±ßªµl8)İWíÌ€`Y”€tmşã¥U%uüÕÄŒVVèc<¦éÖ|±“„iWV37Wdì‘“pı<óKÊLüEÆ_Ã/éIMƒpyÑèz]Èmëæ;úJ„/È\r†Õ³æ2T ˆ€ ®VPwëv^=`Öô,N¡-ºÎ¤J\’_´8
¥5Ä²¯vël'ºŞ¶Ö¾²‘ôóä¦K,ºÜï5ËX6†	ñîªç¢¿C´‹¥úuùNn[%zÏ9Äğ—-$%"–’ÿDïêmõIgÉ½CÜX+¦‹¥İ6İ{é8!-çğÃ5¥jşú+ì%áw©­Õ†ÁI1Œ˜)#Yˆ'ª·\ôœ‘•ôc¹C‚UUÁ>JäX?¸=‡/Å—ì#û@ ?WyëÏÈ£óÂwSq`âìr›–TRF¯C÷”µÖRvØåÃËù’V’PlogñŒAwUÀÎ`“=2j8èºtWáéùûm¯vÉ¬ùc¾C	ˆ¶½Âuøe(%ÃL÷UR4c£G™³cÍ›äÃYUc<òéHš%³
yXÅ$/×qU"‡çZéË)dËv0³	9ôÙâ$\~mZ3‡¼u‘S6D|»Q¤ôÁ¶$hã=ŸWlûÊïÆ€3é1ôö+:¤Âû×ÌãJN-ÛÓ4x¡×üÃŠtï…Y~Ş~AŒÅ„¡éÒw=÷ï“‡–lR—!¼)Óİ!ÅJKûzñÛù;cbğ×/Ğ€Kt'rdŞ0c/tæÍ?‘¯ËÏÒì€Ş„VÁ³GÀ”Ç–›¥N7E¹™áƒ¥x\ø_jŠ>P(|nTá‰ü¶é
$&Ş…t8@¡IÀœ@Î0ŸLä”M‘/Ñ*J—âûU…ˆLˆ¬|ê:·âæYçƒíZu‘1Yã&ı6¼ZqÙ§W÷2¬W‹[[¶lîÃÇ%Ñ6ÒW—w÷­#”­Vãh½‰¹Àªd¤´EŒ:Õ£n{ƒìªô¥¦ÛñÎ'›/ÙÖ·+›†a<)Ê,Ø9œNGqB˜Á+võ•e¼¯ïš´yCÙ@«Ÿ"óZºÍ©ÈÛX× lDîÒ“ı©À¡AãÓë’¢Äåc
—V‹ıEâ"JŸ	m1´ é§jŠ“‹òüïğ8:Úî/5&wi2?÷…Ÿ)–`ÍBWğÀ%u°M­µ¡¤Ta­'¼R{2ZË“y†øõ,—ÅDŸe7åwû*ÈşIl**K£™‹KYñ®3•+¤ná³$V$P[@ƒ‚©bì»›]9Rœô¼p€#“ş™ãĞl¹”€–=‡ƒ ˜ÜÍĞï‰1ö£ |c‘š*ËOÚ!"è€ÍGM8OçÇdàÿ•i#õwk	Q¢Î°".¹â}Â€ËÉ¿q&9FJQXYB˜s›¿Ò:¤}<~Yùg‹xºaëõ…
ãŒÂ€
êÜ0·Ø#ÇM$T4Ãó÷¸ğI5÷Í—·9¾¨şe“–HÌ¡Ë¶N¬İ 0õ½UU¨ç€jËµÑ]İ½¡d#»Rf*ŞÓx*©(åA@óåhTce‚–¸7Em¹¾¦!`e¥fğs–±‡p×x_¥ütJè XÙuş#,Fw’)+Çh·Rp˜ ¿8óIşªv˜ÿ>şf) 'RÚßM¯¨¤]}ÕÿBíáåÅN>˜îÕ_wO$oÎme	¯t'IJÔ®÷gaCI“jkÏ¾8`‡ˆ1'ğq‰9·Ağ(Âš¬MÄ‡:˜ãeºé+»àóIyO¡N.Şk™Î£†óÁª?‡U¼+÷t®äÃÎLÛÇĞNúy¬¿€<†j!½æ\cP¹øtÂ¿Ñoå`Ëªğ?³H±³æ s\Â”ì÷Ù¢z€ŒA4yˆÄLƒ³$„­RWù›ğÄf1}¿³¨<8GäærT½dy„>Ş?¿nuOÙGÃ22âì‰+:{±@Z&y®¬I!ƒsÏ$#}5p%¶¡"bw„lìÀÙŠ¥|Üä(İŸË©elÌ[—xcÆæ…ÿ Ér XÒõ‹‰ğÜOp¿´ ›­À^£$vÌ´¯J†*ùU¯dY°FNô•9ÒÒŸÁ–ÜâT¾h+Pï³ğ¸ÿËÛÑ<HlİÈ¯‘Ño¢ ¯åÃ,¿Úåöó^ÛŒË\»÷à3wi?=Sz›:ÌSB‹HÌåõRÛPÜ›lÏø¤æ*ä:Âhz»Æs?? ïO‰]ÿ°úÖ¹ˆí·á%
uh…qQáU°üïÇçÙs™éîÕ"›©c´˜‘İM–#öoŠvPÿ!7M,KŞ.CŞàY&ƒÒÆ˜GªúØj
ÌZëtÕ/X^½yÌÿ€e˜h=(…BwëÓ'b§ö]WÎ”¾IçG,°v•öf0\ò-Urzbô&nlu¨'õ£8wrµŠA kĞÉïrn­ÅPæ¬5Æo2˜˜mnT¶Ehñ€W¦«nu0a÷à¯î$#tåÌ®–üqoÁŒÎ³Ïš‡Ö×púy˜š”¥kz+şã¢>l­‰k€FcÓÕãñÂw«ñ Ÿu(\Åsœk ­GòÀ4>¬…™*Å¨%]kXëªô]%Uz[’Œ>¤'Œ¯"¥}İZ3Ş%1*eõrc}ô“Q¦#kz”ªg´Ÿ
”—´öö^‹·ªªuYßŞ¬Z(UPdPË\¼dé_Ñ!Á#¸Â¦“8ˆ IPlMÇÿšäeÕ`åèÍã—®—gÊ-Œ³VÎåƒ…	ÿâˆaV³½Ÿ%â¡ãä
$|“Y0@Êİ­úÔC)M±šœı­öd‘ÖÑó\çO!Æ'º0üã¬'¬¹euöh&*×å>Xm›•A0J^8
Ôæ‡bi­¶äY²_„qÆöùŸnEŸÿâÿk	Ó{HBM9 ¨xzU3Xzak^Ì[Ò‡fMw=Êî›Nê.q5DŞ±áQ¡Fîû:'æ2¸nl¤Ù_Á[wÒ®eyÍ|¿»tÌ.2
ÈœˆÌ3ƒ‰»3Ô¸_‹…¿şäæĞĞòB£oL0sêPÈò19+LI†î³o–;5%7p:•¥§S(n|^½—©v’ñÛµ¥
¦ŒƒøO”í$¯Ñ%Ï7µšºˆRÚ(…J´ÚÚ>°gxnŸ¢¤ÇŠ–¬HE*\,«‰¤â–uâ›p$¡÷ƒÏ¡[€ÇS€#Ó‡sü:ßö·ÄøGaÂ.ŞŞƒ.€¯lI £&„-	æÏÎu§X`xõª4ÎºÁ¯çS~ÂÏ>{)ÂG«ä¨ÉÃ×sD2ó¥¿´èL…WHz”m)ç)Ü„­_@[fÛíŸ…?|ÀéÒXHÓc+Ú<ÿ~Z¹/|„‹—È%¢¥c ß$i8V ² ¶Å\,û–¥g–¾BX5™œ0 Ìü­.×Ñ*DÁ´¿gNdXÜƒç ¶‘B4½,;G¼dá=áÉÉw„â Ò8™D»›¦H±76ç#ö0#ÇÅ¼åòˆ˜·ºZ§ÌFh#Ï|üäní½½Ä˜ît$®Ñ/-X¶ğæBe¿'®µ›ëqZ¿ë={ßàG5Û…K'bæ%F<2ö£†íuÚó–¤§ıëny€ÿl·l6Ëpëã	µ)¦Í9Ñº†¥B"Ã.T+°ÿ7mGÀñSQ¢Òß
3JëS`cl<IÿÄ¤Ÿø™Îæ"œ*ñö,ÒYÎè$ésO”…©43
Òîàºóñk;ø]6>mÕÓ ¦TÎ9’8ñàxÒ@[gyWAŞA/ïÿÎ£´ûk·dµ5%M+½ù­´iFç•é—áhF†¯I«ûø—„t…oPM~r[Ø&Ê¥>Ä˜ÓÄ"},,è>ÁŠô‘Å“xOädo½íë¨:ßóI¦Â”2Ñ#’Œ«ÒÛáš…:Elg°z¦ò|àB8+ìË¸­,!í•ä'ıZIÈŒ¬Õ‰iªo\..Ê7ˆP¿GyÅVg„ƒÔñ£I´W(!çól³QO¼§ø¡D)}ƒ?ß¤­¢/ø¹¬¤v‚i±s9åˆFÙÂ¬1wd,3WùD¾± ØP]°(&wÁ¼V+•D"Dqôñ¸mw¨ïe×è,ã’ü€¼S®qnr=ÆÏáú«÷õYîhšøØïpMÉ;®é›ƒKÉ—d1ÊµĞ¾ú$XÔhQ²+ş„ea^çRhò5fÒœ"´Š6ÿ±r\î#«(¥×úR–ÀÇ4/ğ@]…¦.0ª£Íö\Š‹éÉ]7]!ÖÇÊ×‹Õ%;¯î¤\•çÔü‘4ÿåá;ÔˆÎLå›6*İ­ Ï¨a¿ªëé Šî/û©>€üRJ›*Ë€ûÇFÑ=Njmp>°ØAwd%Mkø` qµ¨;lÓvä>¾Â9æ|’¾¸JÄ:ÄYeÊ˜2Ñª–3-šÁGç&ÛÜ´G´ÆAa©æ|TËº:ò—KèOƒx´Døù‘zœbFÔSÚ‰ê÷;N(£™ÔÊ‰^àRQSPìÁÃ¾ö"}²<¼Ş­Q+i'‘…î"ÒÍ™³Y˜C¦X?ÄóçYAs„äßŒÃ ¬,ÈD*à±àÆt‰^ß+]}å(ELî ‰}rUàş^?Ë§k¼Ğ…:¼ÓÏ‚)³»°/\ø+Ğ)
”X9AojÓ³<¿ñ.kmIH‚ê~bCMü'Úµ¿®Ï¾¦FüpD›~<qÌ M0y¦Zñæ=ùÎydşW˜GeG‘¡©A_t0ÿ²ñ/î‰Ğ…‹”M\Ál­áúÑ&ÓˆƒÖ¾sXÂŒ2ş$—†„/W~Ë$bpk’¥T¼ŞÔÜY_
RÑ‰šÀÈÿ±N‹,ÌóÔ”ØßóLçzsYƒãÁ}^Y`ÒNŸç   W4jÁ”gƒR Ã½€ÀjJi°±Ägû    YZ