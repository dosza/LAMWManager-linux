#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1243617099"
MD5="1eb3644b80103f1b4908ca5ac573ecef"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25668"
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
	echo Date of packaging: Wed Dec 29 01:02:48 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌâÿd] ¼}•À1Dd]‡Á›PætİDõ#âdÑL¢À"iKåyä«P„ŒUªœIx´´Ô"'°ïìëÙ”‰Ğ‰ìX‘lÇüJç ÅØi¸a…¾ß?*¡ø…í.hÆ‡š‚N”wÁËOa§³ 2òÒ¸}·s¶Ê Ø¿Ïä®%)œ-¥æI‘[–JøíÜq>Ç	b¿Eó]¶«Z®™»³Me3…’ºŞŸ«Z&I~U' 	Ë¦]ÇKZì¨¿ú[Íè ö©|D¹µC|VY#eŸX×üŠâòç/)>½ßfS­ªÿ]LeæUÑ.°ÈñG|Xè`„IW¬ÜÏL×Ÿ²é³=ÊAï	{›R5ù®Õdáí'.(l—œüqÎmŒùò‹N64›l;jóä½·i¶ÅuÃ³|/’(d7B5ÉC=ô¡Åª4G†M¾áE.´^"j‘bkqæâê;ÔNHd}=^ôÊG§XÏÏİY_hÌ¹RH¶¿HßÊé­€–eSOÆoº2Nç.Ác|GtH«ªëZÇŒóÈ9)Èå›µoŒ¼¨óY<ò7ì‹}wàpƒA¯Ä¬>Èøæ9b×oT"›İöôU»5Õ.ÛôÊsĞ°ëımú§l\'pz¡XáÃèíô|°OÒúq¡dPFn¨kñ¼AK=]a´ Ç·ô§ÙÅ’;ƒş\ú½%W	T’¿ßˆ,m‘×ª•¡±³Çã©}QÆ*şWî¯ûİÔ•QA,<ƒÄ‰?§ +ËäU!ª¬î¸÷=ØürÊ~Óe]aqJ”z=êö=gŞá`s£íwĞ›fjª	l:[•ĞÜş)ø®y‚Ì¨|Üãgrö°ĞÂ*Ø‚¤9G%äµé,óˆv†PxğÛW!¹xßE:!ãeq—~x•²i•ŠXŒÇD²@äğ—¡×ğY/ŒVEèô²wå;İN8…³nĞ…Û49’Š#`w§ícŞè?ïÑ'åz~İ±È	4jãøÈŒ“îœx3ğ 9'H¤L7F&âµo\¢kÇ`8˜>a–¬^J(i‡È¡˜Dê&%ªÜ?cìá.çt |®i8Âa½È¯(u5
øùç¼4ªåEùÙÏèÊlo#?}éı‰gŒEwI‚ë”óªJ.3çc“dÃ2¡,_#ÈÅ•¢³Ê‚ææ^;’¾«-:U§2Ûo šª©¶lÂî}„Ü"¬®L?4Æ,ûXßÏ“°û„8E–JĞ1Ê8>äİô&—Û§,5 $]mİìç!L6§Ê{¬8X…qû—¡ÖlO¤ëÉz_éîÛæisÔ¢åœói³È³Ñ¾Ì—Ë£Äs#'H3øDÉµùâ–Ü>_×3Œ°rûÈÅ÷TœV§ÀKF…]Â*ªš„ì3šSùÄvªùEÿ»PcdFíß{ŞE’ñU ±A¾Ê¡mdjÜúZëøóáRìMÎwÂÂ†+O*å¿ÕË–€‡xÛ-­§è‰.¢`7ú‹TëUøs¤¿€W#H¿‘ê¨¯¦` ù+P×>¨­¸)VøïsÎš“ÀÈP—`&Õä‡é{©Š^ë¦Ã¹‘0õ?ßæ4µxGùú@¶ğ#Y™ï±Î(}}îÁå¹	WŒ"bÊŸLWPX Z  U¶›öş.zu/£Ö«Là¸¤»HT}x„)üU¨öúvaß°9ŒmèçéÔTxMT'%\”	Ò È‘ÓáW¤¦€™pQ‰â9ùÙÙk—Š˜¡\K¢Ô°¤iæÜVÓâDSZ‘@·É*´BÉ' Hé‡$@àî2™N¢å°mên
pÚÎ>ê ®-[”ĞıÆ¹şKà†ìºtÙÏ’¡5åÛ«MïsÕ455”…FÂ†.*;ÙPáÄ°2¨R6˜ÉŞ—;±Ìää†bÇ®"Y­—EÓc`ıÏÕGøUÁ¥ÚQµëLã9¼‘VdŸèæ¼À xÆáez$í)ø_.ùé8×îcSâ=h*=Ço‹µÎ6˜	­ƒÔ)HænĞ§ˆ…q’˜äåH¤Ÿ?W&Gt•&"o¾™VØŠ„’Ä4çV©›®ú¡­u³ëÀt^g
I¬3ĞÆ~ü*JÔ;Uâ/u¹8ûïÆYíô#Ç$=ûËª{‡Ñ®=ëÎe°`æjø[åduÄ]’§$ÏºCçPŞ¦GuœfKaQ˜<Å»0WG•t?ùs[ï( ş¾s¹=p–4è‰¥$Ñ$à8¸7}	p,¨á?Ñ6¹I>!=ÙL3eài£Æ‚˜´=}†Œô?}…b¯¨|¶•.¼š×Q¸Ó²>©#‚8’°¤dÂıÀÊin €ºéºw7àòfC‘î#{fı·É¦§6ÿíäâwÕ¡å•=u·Mn/wpûÎä|Ğæ»‰£PyÀ¹^î·j±Ì…eSDxšjz8|Jœ	˜unSz‹ÂÜJä|¯zŒh-ç•øá
ƒ4t¸<, ˜.vt
€¨_4N‡À¦3ûVÒP¤˜„´8œ»¥İ‡_;bŠ{µTU®õùFb8”[Vš\2tÙEß\†Âœ!p?µWûË :#€–åbwŸ÷é%TÂÈ“õñ¥Y6‹N¥%BÓd§iıW%%ú=½8êĞ*0%øyÚß‘ö/5£ñıœxœŠ‹¹×Ëmx
­}:Š6Ybô®‘ Ä€}äsìãµ ‚¡¾ƒ$>öÕ}v/‹÷è~ûë–HƒEÃ@²¹&—ã½üí×L)7>‚ÎÜğpõÅ‡=\Ñ
Ë42æ¥ÛÅ¿ïcïiùvßv²(Ú,ÖiÜ»ÅµLÅJ˜xğ´¾o\‡t@|íi%I¨÷ˆÆÎë„n‘ÖZ,øàºUO.DÛ³Uáu‚á\Z[É}|}<³ÿCZ¤´5ÿ'H‡é†Bæ˜Å1éñ­(gıc.!n…á¢¦qƒ?0O^KQ¢|ŸÎW²U8EøCƒw‡UºûÄIşM[ï´dø<z'¥^XCÃY¿"å¹cª^õdœÕ¥_ÚPøø©(æMˆ~hCêğIŞ9ôuÇZ2UF¬çíG	†Ó†É†Ô
Í	öSò@€^-T/âÃ¯qL,#g;İ<d}œš>â;hŒTª¦ìU˜ü6J5)…îI!v7Ò!¿C±|âWàÚ±Ã;) ı8S!…É~»æ‚UÚ4ÁÑSó	Ò†™‡X4$ƒH®åÕã>aÄ9Œ])	:!ÆÙ‘ñàV9œ ZëO…rØ çmuU¢Ríâ¢¡ÜŒ=³pFâEïûæ/ÈŸÍ†ıı’›)¾7{9ˆ6ÖèËïJóç¢IŞyz—{Ó‹Ñp¥õ®5´ìØ(i×u‡Óü4=’836Ê5:=õõÀûgHÇWåşTEáh½õ¨ß=#‰SGnİAğ(
jN˜E W¥†3)”—Yëuéıš‘ªñv1@>³ñ(M¡§è©6F´«ezC>Ä¸ë´ÙøÏíRhô^‘bõf5¹’§ÆG®¸å·nßõÂ+ê¹&ã‚ ·¸T«Ê‰Ïá-–'€ÄæLrQ?ç]`™5s“{4G²÷‰é„ÕË$GeÌÛsq<U·Æ³^Ìåâ—è3c“DÄyÉ÷/ŸU3S…è0àXiİî­ùø®[”iŒe‡®½-yë€9bĞmçY5‡:8-% ƒ&¼5zfŸ³»cÒñ“uhŸ›qˆ8úLûšB˜XP\Íf®zy ÃÈ-[b`>qş AY^ªdF¼ğÓ‹­ ¥¦¥p×r„×­_‰Óø­3©õRI`è¯ÕZñÒA³XXÑ¨t0µ~4_Aº.ø•½­¯©ê´Üø61³áĞVà“ÅÙÖPê¡Ê`å³s¶È¸—V’‚£ EíDS´÷ÿµkOæfØ‹Î¡¤Ò¦W3yê•yğo'°¼áœ^ ĞÜOIgëÚŒ®ÿş«ÅÇP—Şî§d{ó_¹^¦ûÿ‹U8[‡Ã„O $Ü;7DA÷jÔ×-Ï-¼ 6@ŠÕ)ÿdÑAaìŞ•Ñ<Á»
è(´è¯‡åqÉ‹RÑ¡ÎB(+øC ¼q‡~†€ÊMß]‡‘?FÖvX:°\Üœ@¥$ >`2lÏg7BíBÌÓôœÔDêxI:0Hæ–•zS}K¼–’]
Ørøg=Jhˆ%ÉµH|tòTŠ/‘­å:ç6‚Î½Ñ<º9;Kñ“­R‹O–U©öL¶ÀÎ]mÕ–î*£‚yÕÿ›ÕVø%§¶I‹‹ÍPşÔk\QC¥f/$yYø/”%[Vw¬Q€ °QeSÜ#†Aàá§Ì³âåU*²'­úàÏ2¡[·-|$E»EãA½šß°‹u™ ´êh7½ó´ıâ³¶â·¸céq-< ‹ö-#ğ?â:MË:ç… b®¼òĞ¥iN-3÷.E5¶î3z8íıIßÃƒí 
wP‚fûTò›‡¡ŠÖÙa4‘(,!Ãwf¾#%á˜9©R’Õ#íÍäÜšÂV]F ~{ÌÏŞDf‚¸aÎdO§S†„‘ ©P½íknlvaÙsşŞ—åÏÏZ÷°BÂÈNäsIü•Wšjg+Ü’¼a´ŞR£šv|ê>#Qïİ½ÌtIº€ïàädíéá”>Ã¡ÊÚfàÚUiCEó©œ]`„öª¬ªƒçÑ
Ü¥ÿ³+”(ÈöR¾›ÅãCÃzÕøUÒÌ"ªyÖ+µƒ^h]–]ÎÒnÍmôé?ƒŸyè[ı<9Ö«Ï(@Ãpi°„q-ã T"V RjØ!¹·§YY£Z‡9ğÈáñ<hrAÖÍlŸƒz¼Û¸ŒÁe–IHïEopAJJ¼¢È˜˜Ûä«mMáÏ<´ı+¡òašß}³ñ­G…$“ª•WùIBPzŸ—1¯û:K&wÍsìlbÂ"ÂòW}”–.4x‡µAkÊn
Ë%£xéU©ü=C¤Ééöôş±Ò	ığºsÏŠÙ¤ÃOĞVû†ÏkÕ?•ôÌÔÓ#s§£9LIjÈ;i­{‰ÏœšÇ›Æ}yFáÊmÒKwtn©”U})ÜD™-ø–‹r?ñ:J5›¡Ï¬ô!©)®¤J>Îİ]ƒª-\ƒo(–xX€(èUíö—ó7¹Æ
7¸}P-ú ƒø|â–Q5æ}6MïÀ5õ@E:Ü!„,Ç>ÚÔ¬L¢ğ7„â$Î‰95ÊĞX*Ò8cmHıÍä†U )	9uã[¯Á~^«TN£ÍixeïÎ;P·ÃSd}UŞ¥4ü—ÍyÜôl&I eØO‰ ğóƒÄÛ› /JN~7¼]qáBØj¾ÚMz±	ê2ƒ•È6˜Ş,ÒÀc“V"ƒşrA³'P®Í¥Ub{İV‚è:¯,ÿq~##H°b}1¾µ7ê6Î0gÆ_(€´z\#Ó£wıŒ•¯á€ò—C6V½ß˜ÌDEÈ×¤¾õú–_‘2¨ ÃKò ¼*ŠiÄüG#õÁát)5pÒÏ><ië€Ö-5bÀ·Æ>p
šm4ìbµÆƒåŒ‡iû	Kˆpğ¥ Í{g1P‡%©Â§LK”jÙ|òÃãm…kÓÊªé†ì¢ ÿ¡|€½Y÷5 #]ÚƒÍÉzÜóuğ¥ÁŒ‚ ˜Ó©£Æ0Iú8CylÊ8÷Ö×oiíó›øˆ§“–j	¼¡%_…³ŞÎšß²YKƒÒ›sêÓÑL—[ÖsvıÚ™r³Ì7¾~sùJÀD‚,yYµùŠ5ıPıI_¼‡<+Ù]gÿÎQ˜ áíQxÄÕ?ïi^—I1…˜®–¿8+ŸP­a„C1C°Q¤^¬«	CÍKCáukD5›KVGÈ—s:É%¨sÆLm^´»njöÕºm¦ß+ÛŠ:CH+[±Ş;¨‚OAT²In	6P"š#Ù²ğyçY9d¤ ÙïxwúÂ‡µnRGÜE;>J¥Æ?ş×Ò
¿¡ëYo¶ûšßÁ
´ÖG"®ŸEaGù)Äd|]¡¨ß/şÍë+–³Ö³;Ú<Ä…A€°ø EÚé8ë÷"§/™‘x­QæÌGfYKN
¢;øø7é —	[iÉ<èÛÓ±‘+öÄFÆZ±W½¼#$
˜å¥Av4Àò¶¤k¹á´cĞm¦Cş‹˜+¶ğˆŸ‡hŠ‰s½{µò¥£´Ğ¶2#ùé¼xĞS<§»õ~'Kƒ\‹¬}Î²ğ!Ê²”‰¢o§±ÔbñÙj¹h‰ˆP]A3Qí[bí~–‰7¾Ø«t§÷†b	 "7Ê£VKN'Õ½a“Õ¿©ØÙX¿#(±%j3¦ÜÁG¿y••f´Şmœ¬At);Âv n_>­!5†gˆEC…mì9{?oş`5Ğs8¿’·Âç­ƒşú«ó¼t.±z¸ùñïñ¨a¸ÓŸ)=‡T˜Fö·rDã yQ"ö_Û¯s¹ÓCm£MÈV9šF¯;<–wX£äCÛoÄê1?J¡úí³l‹z<ÕQµàï`Éåb¬~bé³É?Îä¥UĞ®øï«Ç³†·7=SD­8E/6f:<yU"@†¬Ù>>îf–2»˜“ÇQ:E
2¿èÈBóıµ•-¬X5'Æ¢Úcz$&W÷µ¶†‰Ëk$ôÈ†lë÷»ÿ¹?í#—ò’ğ‘*ıs —„„”÷k‡Âf…ááŒ¯³ˆœ ;kØİeC8^;4zúÂVÓˆMÔõUÇùy™:âF­}—â‘PKlŸ»âª÷éâDp°Pû’L²o[HäÊ•&M/­zàe;cFr6z|èK¤±àPÏ[km 	^'t"¾Ÿ¥Ô(É‡…€—pç®šf‹qh€š—‘é·…»Ê(0dª°üºÛ0î°¢&^ıìvù^«‘Õ³³øøúT3Y¡´:¥¾+Ãë]—‹Ä¢_ 7I&™¦Xl¦õ akfÕ˜î«‹M¤¼ßÓNHÛû°sk0É¢N§¡H›ü(·¶°a°e¤q÷–Œ“Èkuª6¾{x¼w†_9)i1CŒ‚­.RâÇÁR©B€Î‹Xik8Íà6…µÛ<e§z%±x÷[ö¹p‰•²Öp¯½äÂ¸”$rê›Ï=Ü}õ©'Çß tÄÑs´æ ]3à0É×hƒxÌÀ)"ùÂÂ÷{†o4–ï³\•ŞÿãDmIUŞĞOïëÆ«’È¶­â‚dÆÖEX]ø%HJø5§ß·¤\ÁcNÿÑ¿öü2z	îšîÅˆ#ÏÃZ¯ˆ30+ÊùÖ×˜[OŸ/õ¦²êşp·Y``8#åÕ&©œiğ°Æ» R¯ÛTÑ£rÀ °jÑmÀ¸K!pS©™Ÿ_lŒ>:Ó:¥>ÌwôÁ@íÄpl–Ò‘X"öµuîĞ7DŸÒ@ˆ‘·W¬öˆn'¾—›‚İÎèd‰[aæ*Lqš˜0ÕHdMÜ†k`ğLÑ«DyUïİØumP!«1šxÊÛ5tòğ]ç!Hã³‰€ò–jää±ñŞ }k]Is»aaİ=s©îŸRIìÅC¦‹‡±tãEJ •ßÓ‘)ñ²Ø×l¶„Á•QÛô:4ìÉxşÇÚ4H¾FÈßbúQYœ¹º*.Ò@<:®;tõĞVi½cjé?cü•]ÿş€ Äƒd7‰oàò’W:#pwT„òÄü4Œr?]ò‚ cTºR;²_Ù2¸cfZ‘N¶Q¤„§*gŞbW¦PV ç£oŞ®J5°ŞQçPizÕ{«sË°:^ ^É5Ğ8¸!&~Å<µÂí7¤`Ágx¤œfB4}M4WW@EÒdİyÅNzL©„sq}–øru@‰î†%{ ¾@èÄ¸ıéO~’ˆ!YR~X„kù(dCêq©“BY:&ì(ñæ_ñ„ÉhV7c;(H	”å)T]©¢7upj3’² ÈNjHvAİnçxhøÙ¨¾æ«<W§§a&´§¬'g?#2€g¡É{ÔHÿ–GCB¢[…êG°‘a|ÿ‰á·ÀíĞ^y,-£ñ®'AÎ=éY³¢OuJ¡¯›Ÿ–+nfMJœbwøße\â:EŠŞÂ
Øø6”vvr+¡å×`}dùÏßE´%±†{aa3CÈÄ½œ’1ÛÉalz˜ŠdÂã”èñ˜:¬8ƒúù>Vª©l1Is'ø”i¥äV®!±• :"Ó -	%¶³O:ºtàE»F¯{ø‹H©Í4Î½%ånÁƒ5MhÎWHe‘7$¶íNÃ÷S`Ï0âWé%¬Ë«÷3ÖÁÃØßnè‘g®Ê4rÅ"i‰_N&>>V+
r>"	Éœ_H÷IŒÄ)J¥GKôÀË ¹?ıbÜ°"÷˜ÜAÇPq8£UT:œSØ
IT‘nÿpug˜'Ê&@ZŞà
hy
ómwzİq`[Ívìv¬ò`µÓ¥šMê3uüã ZJ+ÎÂJŒ‘+Ûm×|ä)6Ó¼ô×Íë[–g8æãW<VÚ7ı=Ü}¶¬\ÆeuâÄ®ÌÉ]€à7ÁÖ»jäĞ!5	‚g$<uıë!F…DkyêÖ\¢x†Ñ<x¾ŸTK)òª Ë’ ]Õ~ÿ+oLeJ7õÜıbkØ¼!5wÚ‘ñ1<äV‰ˆ¥T?û„hÖ»6"	®Çr,ñp±i-Ä}ÌË5¾»/Şg%Sÿšâoá‹¦”Irë’ÒŸõKY
C¼Ù+-ä«ØÀøÄ†Y^6M!±b=şÖØ@Fîfÿ±²nEæÉO¿ÔÔCâŠ@ë&.fÆ%óI	ĞX0¢ıñ£ƒo›ò±0u¬cÿıÇœš£csÌ*ÿàøL@êĞØ·…nıuJ#§ûzBÓPÜİWü*ô;š‚Wl‰à’şù¹ë$ğïÒ—ÑüE+¿Y§²İÍÊ`ÓP’Å¯I30†âq9iÈjX*¤|ù[¢ëöp«–ÜÛËFz¢ZxWÚÙ&Ş‚ˆ2şh«>£MY)C‘ıc£n*ŸÍ´gÇjšÙôšQ9¨P¨r?]}î0ç‘t©Æ ØªáP½Ø2¼ÒØLççX…{+Æ~ì8Ì6J³aAè7÷£=\ğïêU­~“&Bá›]¨¸ëGMo8±ëPfTësYÖ•fŒDıàÁN×.8ò1W‰¥¡òŠß¬59hM	·ÜĞn¬0
ã¥İÒ@ÿŒs¸6/ÜİÄ·„#œ(·L Ùq—Yùb4P ÑF™0ØnÌ¤/ü	–á÷SŒeÂòŠî­Œ0ˆÈ¢¾\KÔK9úù_ãöäÔ¦—,gg7:Òƒ³ßÍiØ45Y‚çÿÌ#€«\iŸcêº-lEzğĞG	&?–”«ñ
|¸¤Õ¨ş¬Ñ²Rx´Q_øQ…®!£Kÿ±FĞ®üù»…ØÉãYÁ](ÓHrÊæÔ­ûŠs‡ ‘Uí[ÆY: ËFñZøZÆ¡L³ÂÀª ™i·íGWX´@Ì ×|¨@hš4 Gõû´b|ÃJºµ§éZøWêê$Éš¢y_÷7%AÅÆ ¼—§µËT¹v·ÖWckEÖ@k@2fP–­1ôØKGjÌ‡çÂXï{œ±òU}ì£¢mƒ	Îù»”k{|èïë•êêRF|9é‡E&ÙñöC4ıXnu©N©))È‹¸3›'§}œ½Å•ód~Šiµ^3”¦èj;U'êÓÓc_vbôÚµ‰åv"§ÍúRfİn5¹˜"—z\€ÎyÜi­Éxß‰¹~ÊI~·í=4~€XvŸÔÓƒ¿rçûï3l&âùHvÅ‚’…‘Î¦NW5µn¼©æd¸Lú´È%[Ï.Ÿ¸ûˆ½Cy‡Õ‡ä¸ØUÎ¯f{×lïŒ µZ[Ú¨|¬ñÂÈ†û†X]l”ÚÇxªWÀĞß‚J1½ü¾Ú”tTTÿÕ"
Õ6îtA‡)Ê1§È?8àÀíŠuV	$¦}àçÛÚ!‰°á~ìÏÔ¬ufÑ¤ÌDQ¥Í¬ÔDÜ×=dù´TÎ~~g@VÌôâÂ¼š/|<rÁ
Ğ€ÁÆ{ë€Wæ8ğ!Ø¨VmH¨C£’uBúÌX¿¨Ø*µö!.·s¾½8^¤K>Ã¥=qÁL1›Å+ñ(7OAtìXdÈºSvü¶C”{ã—VÈ¶ã¥¶™Ã>]bQÈG!2‚nxOˆªJj=Ä³˜N-œYµEÌC^\”±Jc;YÎ[Ûæh›NAÃòM4¯µÛQÂfj95ƒ·;ük„;Û+­¡GyDÈ!ëëèêÛLr&S tOY÷&°}fóiÁ—|m©ë§$é*¿è%‘«8²"¤¯ BìK îkÔÈëo^ÒÜ:,àºò9a	C&Mv-åSÓ¿ÕÌóO®È^M†Ùk¡xdƒ°‘„NÀ¥éªq2æÕ}âÂ(R#ï]üÏâS)°*ÿ­tšâvRÂV¬A•Å+AµkÍšŠà.’ÖŞmI”e3YrËyVß¾ÚğÆs™–¾Pã$ˆíÀ×1'‚ÌI‡½úíÃ„ä‹l»*Q¨ -x_î8GGº®Væ¡õs,•U	ùbk~ÈìB€@zÍ±&z<r¦°+Xx¹yp4Øy ğo­œ;ZËÿ†’E¨ár­8ÂÓÔş•=‰>J$s‰òöš±_SdR‹„Ä¸°w,&,‘z¹NºJFşÒ¤aÌ3-Ewğ(Dê„©Â‹ã}(nÑÓJ³¶4E´¸lĞ´ËøŸkÜ,ºÖıWÓ"wïø€Í‰Oå:•Şªz¦;±8½ªª<C? hq´Å±R¯´ÿÓ¹ZS‘ëÿÛ}d™ãëæˆØHŠ`)¶£è­Ì~œgİÿqã3ç…á?¶ˆz0İ…
Òõz2à]Ó£Z¼F@øjO¶z¦Œ3›;ş’ÁŠ«B¾%EJ¹¼…¸~²üø\g%T›A¡úûmd‘Úã"pÓ‘´´™ÿD[uH¸H,¨®æ’Å& ñüÙÉS Iå 4æâÎcÓZ¯?`,Ô|é4× "#‘x·~Ä_Ønl¥hCµá4ª-©½ï–¨DJ‡ˆhj¥$¯û€Bräµëè*§í$®ß—qø˜Øb,«áÖîªŒ¼kt$Ïó‘î‰6«ê,Å±Œ‘–ãK¸fĞæuv™aN˜û'm—°%J† ÒŠİ¨qİ×(¦€àÀ×rÒouå è¤8½­¦!>âujWûXf5cî¢4êZ+ğn+ÀdNO™§Hü°]Ë†ÈW‘ğPœ»™QÏùøcÛ[	£Îsl¬›ÓDıĞ	'zU ıšx¢·®Ÿª½×ÌEı2G˜qânVH›Aà0¡y“rõ2øqs°¢öÌ€v³ƒ+íK0ÌRñæ¢ãÿÅCE#[“b'Œ$}ÇXVûï¶ÇÉ\©xËK^3VŸ*Ít§c£áˆoq¸0(‘Pö—	r¹M>ÏxE!<$òû|£ë÷i*úJ Û\ï«öä[¨qéQî84ùT™¯äëBfKI~_*`áç(é}àñ^Š7ú&ÿ°à¶CéŠ>—°ÍÀ'‰â¸jåş¤8”›¬óĞL
ÉdÔÅmŒ• ˜uª{¥\Ñ}Ü¿I_LÎGçzBÜ¥EÜÀ˜Ô(®"‰GÌhá0À¼ÄVîyZ<Ÿ
;&Ü…ÙìÌÕ;jÏà¥	·_bè£â]m¨<ùÑKÛ]ô­1Ü"˜×M½|Ù–U(îéAµmJi\aí±¾+›Kg¸Æì˜’W‡÷—rƒPŒ…ì0^RÂ×÷•Æ›¥ñ*P/ÀåŠ-;I‚cû¾ªÍÂ7úã&äÿ¢¿>Eİ´ÍÍ?f¨ZpÂ¼É|ò{ı®{/İTÊIaí¾
ïÌ_u, ½7İªïA,†n£Ye5Í¢áI23RcÔTØ€ë--®ˆ"ÚA¶Å¥‹ƒ}«'elfÓ–DÌ¤¸Ìl¤æé" nÊMõz­ßv6EaÎ4:EÈ²'Ó”ëÛT“_˜ÅC"ÑœÛµ”AH;–:ˆ;xáùë!>Æy4Ù¬!«M¡Ô<}_0Èóv6?+`)ğ³sï935·…ÜLÏac(¼êu@©7¯Õb‘â£0›5«&í»Nn|Ù¨u2[É0óË½A½ÕåªÌ A m^j7ÍúÄüç–zßı„Ù]Wx^($@~ÍÜ„ÅYà;bî¿WÛG3Ç±DàŠ(‚‰hÚê£ûˆG8œÊ¯ŞÈùÒvì•&7dãĞÁÌ²Aa+À‡d+-º€ôùÏØ eˆÈöŒTŒWKNqÕ@L+#ÑÁÕÔ½U‡”¡ú(¸\åhÒõ P#Ÿìùœ;¯¿8¢uó‘i6ˆRT¯ÇE«×z{xÄÖw;ÍÚ¾½ú¬OË—OË4p"ÿ…E…®£œÖÂô.é¹QRÂ›•ò ø+x‰Ët	JÇ/ªV=şÉ9~ölNÏö/¿¹öŒuğz‰QL^?¨­‡~ˆ*\RÇCM–c;oÎäTŸ{ 5[ÁPã¬É:Eki"_ünP5ô—Ïšøµwé	¡ÜZcbÎ+I^…ÁnAÚÌú¬H7è6} F×†Ş–ÂÙÂ B\¾Ì–;ëÊL şëi.µC×~Ò­võ¨£ÿgjš?ûIÅ°Ê8œ-lòdÌ(€ h<•‚åîñ†µš1ÈÚ÷2$“òëë,{ÒonqSe8b­NŸ‰”‡+¡_Z*Ì(‰(7ïñf‘T/õ|=Şá–óÌ“¨y¦cñ ”ŸIx$]n!Ko˜GÙªßMâ<!îA»^ôçhæ#P	’vØÂÙôù&ø–¢¡"®>a1üÚ›^kÑÆl•Qãçpr¤âóGÑØÏŞ†»+o2*mbÀ"¸°± Š%Tn­+£Mö¿1µW£¬‰©û’…_…p†. ‘W(­l°Eq3Ç;ïÃ¹—•aOÆÜâ_“\CE~2Ié¥6¬NVÏ÷"Á²sœv^9'«ôO€Ë°÷æ°[6óø3u³½§ZÍ!ÂE$‡\»UGNßt$-Á^$(V@ÓÁ ˆ«½X‹•}Ô
5%Úq3æ:Aöì‚·œøEµBÑ›!ã€Ëáe‚îI!÷©álÆœò×à!>ûóZ‹”ûvêøeÄPY5S‰ZoN[À-+¯]Tgâ$óouUP¡^Å5òÁ£ï(;™ğÆv‡¾]9=‚Z”{u­›2x,>¬î¬ê ‰-§°¥ØãçUÑµ&ğ½ÍÌKĞ‘ÿñ:'¨â¨]úM·b3â¦O®÷ÎÀ2ŠÈáB¥ )ŸõÔbXA¥›7Æµ<M2w$2œ%gxÀ ´FşÆÜ+
Én‰áÉj}´äÖ	MûõõªœöìÊm¡OÖ6òğ^sœÛ?o-ÙºYÿ(¾×kÈø*AIµ7–ƒDÓÖ›"ğõ Ñ(ª%a˜0|Xìºİw²šIDÓ?KE_À¨Í¹gYEüÁ‰ÍÁØs#îX7Š”RzU0ı<\`ëôgTfTòşSdÿøğWg½¨B9–A-lÁ¸›{ JÔ´V»SÔÀWXªKå«ÎŞ-ÕH=ª¡OVÃøšà+àŞŠë_şkcØáù~‚¯>À,Š!éÂî³MŸ§.¾8¤q2\7QA4òºK4‰Ñüg>Ä7÷4‡Î0xo}}3®µ-iXÄFGO'á0Tïğ˜Ş·ŒëòöpÑ¥¦ñÖ¦ö&k3æd‘,öÜg± -£ØÒÒº½@ÕFË‰ÚşW=¾ÇèI‘6†,îeiB`ëôv½Zøé¨ŠNcË³í¢šgŞ‡ˆÌFÏ9ŸìŒ…ŒÿNgK™Û^%ú¨‡`ÄğggBÛAOyÌi4$I¶1ò±rÏ›í.‚Hm£B„ğŞD¼v†M‹_â±UíèŒS5#³ ñ›ğ?ç]6[ş¯«Â"2ó(,@MG ñ
á“Â-±ó ^Á®UŒÕ°ÙóJÃº±šYÑf±!ºİ†)Îz¶»øÅ{…«2ÑğTF”[Äpô§C­T*;&5À•è\@£ƒ@Eät“´‰‡}RÍÇƒLûµµuô#û>ê²ºˆñé'îtaüHƒ[È•?ë,¨aã	Ünù"ê®¢B!„9¦FYÅ0yÒë»–~Û¬Kş#Š’‰Ûœã¸Jìy¬mĞûÇ|¯¤Ÿ¡>¶„³­M—"uëäXêæÜ‰n%ÙfR&ŒÌ0İBCèºqjoò†tÃìX]Ğ+`š©ÆÇD²Z	x£X¿ŸÄĞ*
°`…
ŠÓH‡wŒŸávâ&@ø?K»î^å‚¿’m`fš»0]=o%<#1Íì“áé¤ß½÷=Ât[“î1!p†kKÎVÃ	ÍÔÓxOµ¥6ƒ¼ÂdËˆ9"ŞÎâaÀ±‚
[æ˜
ÑÜrÁ@WGNJ™·Úö‰ÃãËÄS{îµ#­Fú<pñŒC+½}ñi¶CS‡
P"Æ;‰ßê4ÍÌy­É{G]úc	‰İ|ã˜Öİrì&ùãÄg’{ÊÎ íÔÛãÑŸaéüï-¾¬ïöÓ}1PÌCí Şcæ—1a­Ü
bú«uzÛü×Æ]FşÚà¥IiÛÚSöyÛgáâ÷&çOîJa1MõÇ[Ó˜[n÷„±.ŞLk½ØJ/‹+†´ÜÛè•NÄA:Áæ]ğJ®ôŞ©)ŠÃ‘mrDû_µP½V:ŸìM VµÕâ_½Í¯‡7ÕOwİSÊğeÈ0ö­F;¤B·sR{çlâ¿Øo
¹5ŒO0Âî¢Zş»‘w ¬ 3ôPq¹û;¯UkÂ—ÌCÑ‚¯Dé¿®N£L|!Óµ97Ô1`¨©ÚÔ
[vâuùäB˜x¨ò*–òZ—Ø0¤ƒ!Côjj9°ÿx“”féı32Â3d\	[fŠúBÂbiGÆ>ÿÓ%UJn½Xáûf€!•$[mU·ĞÛ˜ä{4³Sò/y›âÈzµŞCNOŒ«€'qïw‚#¥S»9ØĞv)æ¼6ğŞ"RP%ä¹%­ägŒšt\'õ’¸ÔĞ{®…jİP,úñ’rÓ—ªFæİm‡†Íuö„!Œº57øß
[h†Ê~ha$×+!ÅlÈÊ§¶PªºÎÈbãßÚ {kI4‰İÌm"NÍ¹¾ù¥¤›ú"öç44½V<Ùm?¯¿wÿ(÷|¹ëH†D–FÅ$VÛ^Ôš;«Éä;Ö¤¤’‰Û{ÀÌOJÆ_?<˜H;
Ã°;ÚæJÖ^U¦©“g÷²ní(™›°˜³$ÿKŞ‹&­÷İ'rSU3ıĞEzÑÎ§–mLÄ<UhöÁ&&–ĞÆÍ»áöÑ>d±Ü¤J*¸ï-ßñ!ÅJBàëıù‡uQ¿§q˜Äa¿±ÜÅ[MhgÍô¶‡ó^™ÃgÅ|œÓÛ·`¬¹<~ûK; œæÑ(Y.xb#Óà'–¸ÛŒ½ÒÓ³Üª
Eñ,¦ÿ¯©D‚”7OĞxe!ë¢"Â°kïwt.{©ìŒúQfƒ<¹.™Mš¡·ÓU¿#/7eŞßZ¨Y¬E 9C‹A%ÿ¿cÿ(}IÔqÙ“0i§M—‡ˆÿf¸YqëE`C”£Vô’Aî!©Ú½^ã0­¼)´˜]&êUCK Zï5º{Lí²õn"ÊvÈõBJÂN¦Ş{]£Nìi69I®¥ä2Ãù©5óÁÅáXm-Q¨/LN™D.ìƒğÀU¯mş±è•¡Ş5ºƒªoŸ*–ğµï®Üê±ê)îøòV¸è’ò;xÍ¨g©Şƒº`x¥9£ß×ûTx÷ç±!×Mf•¬üiÖc³A0l”SöW{urWÌ¶U@²áªôÓZFs£a±ÍÕÑê±Ìärh2&®lmê `€°BW0e¬ÜˆHí€¼µ.nÂ³eš×\´+ƒ¿@Oüùˆf€T»…XEöøg¨Ü¦­«lï²ã<(†\}¼†üzŸ!n‚¯jÖ¿<Ki¹Šƒö*$Ír&=. æ~S<ÃÙíwÕŸcç×¦£ËßÏG.¦r)Ã(E+İxpÀA<ìÃ17ñÁé½M	´ŠÚĞmTË9óÆhÎ˜5qÛ?DOİU¾V’‡~hÛ?—lğÆrù†RìŞ#Áƒ°†~ˆ*ØÊ~X vp]>Tuü
™xË¢it–şÛ~>0QŸ’–ß¦±½x
¯¼İÍË&Ø³Ï“«S3ÃX9ö'ñ5&’9õJ*Md:Ë’a•O±Ê‘.q½¾ í»Ès½n¸Êxˆz’7^°ÿÂ`°ãÚ¬n-kša¬N›EğÜ	É¿ld~÷ÑD’LÈ-5«Õ:âô$óÌZ6£àk¬ç¤?Š«’³¡•ãïdA(t„;©ZÉF išz/IœŠ‹£=óÛdåfõíÇÔÅ!xªcƒ5s†˜p“ŸÀ'Xô…À/5;ú£Ç;obp#†dô)I_µ šã•<uJÜi„h)•÷¢Â 5CÇ5§zá{ïé_1á÷PcYRbï~cÄtn	9ø‡Ôa«øNÍíbc&µ˜ÍÚÓ Ö}6&@‚Aã.àş¬Éı{ë‚ƒZBaÅ£ÓÜ›òr§ÇWgNÔ·Br¢ª.ÒUörø-¾j³ô\¼	Bs~ë€ˆ¿SÖ)å­à5îµí %—|À^3AHÍ4ÙÒhLío3’Ø”h[©@¦ü¸ò9œUPKŒzô’BÇ^>B$R:°glå5{réàXùÙYk‚b>*øîÈğsk/G›~æPXüğvêœVó•NRKbfü:ö<dOÆ ¤RCš,–¬Hˆlp”%’úX‘°×ŞkCšÎ”Äm`¦ÑÕ¨˜
–®m:@F¿/Ì^¥bîP0ê0â½rœ¬Hı†{k Ix‰/¢r{’,T†íU¨:“	r´³ƒEÀµçYÊ^º;#\{²6
ï•Ä÷x“©Ê.XØ=Â¦nî/AÚœDP	RŞ¹7Ê'¯zÙ,ÎQ o<Eıs„m!ú[ıù!I®ïë°×[\zÊº›ĞMÊÍáÃ<{cówáİ¤}.R_Âbh&g×ó“Õî.S=YM…‡”Yß‹ûq+¨î¡ØM´-ÚŒ¾–Î|¶?#+ô¿kUËtj)³Šó¨8ÜXPdZeˆéH‰—ãJşâéë˜b¬ë• Vé¬Oã+W¥R"JX*ˆNx]ÿ+×ùô•x#…Ã_Ç˜:\æ‰Œ1y=bISÇ“ĞM„uúİårõHáÓ¤LöAšŸ²†Oãsdm9¿¶–F3=,}Â.^äƒVx€ö›Ò]3¿6À,7ú•óôMA43«acı—dz+M86 Nœ6ºÌ´³líT"°EZ°Šòü>û9ç‘Uùß39C¨Ğ9;¬ğ!~8*ËUÆÂ	qLs¦v¬À^<:OœŠæûÒ¸´¥ü@1»³ÃÀÎ _ÚØt²ØD8'9ÌÄÇg',®Êò=q! ÓÿĞ­/ˆù¨GgËË¡øÆ™²ô@7şƒ¨ZÔª½½•ñT‚¸%¼VR§¸´¨#Úˆ‡
ïvÕ$ßPWş-&E4æêW3fvb”ú`cD­Ñ-!ş
<òN@t{ÉSaÂ¤á£?mÈ˜¼›ÉˆqØ’(Û‘Â5“wş*{•åDGJ$?vrY Ø›Ñb†¿`„«|¬±úšÊ[¹‰òwò>z IT5Œ !‚!L…±A‚¤¿\/I\Sşß| $~˜®=´\%Úú¨KÎês3D•““÷¥-xÿ±Úåò÷k6º´ÔM\we¨£Úåè³}èÔèö¢Üb¦æ¯O´!à‚òC]—]z>Â±Gü'›yãM´‡ª¾¬xrË›ÆfYõyÉú«áËÀã%¦ª¯ûê¿Èö£HPu\ÉU¥>É3eñ‹›Pö#ºÀõğë“kÎh÷$s£d^×)oÍÕ›ìz„ArRN=¶­æ'¸ A{™šÀâ”°éÖEd 7xJ.ó3 ²”Äµ#ËXÒ×Ô	ì#
eñN«a"ŠÑbå«Æ]]ÎDÑªÌÅ·ğUµò†dZ_Q[_#)@ıE>³ŸÜdë4!Ñ½‘¤»t°¥Ò„ õîsûXzgÃıá¿™EFcì5jt«ß°f“?«_•'¬t¿§ÛæğÓí+ßêëæZi¡ÎK}vâîáÀ<M™®„‘<Ã¿-c—¼’s¯øš@»5ä4¨Œ„‘€²åP¦6qO›PŒ‹}öÀ Økğ3ÑšÀİ6vlšÈÎõNZPIä1ÎãÏPàE5¨ñµècied²®ı´Elò¥¹\-==ŠçBJ"å¼±T{W-ÍpT½òúö¨“\&L}ŠîÚ¥âÕ±Üı[%E*°gô²Šõæ[…|Q_‰ô“£KÏÉ™Ïğé±Ÿ-–
Æî.C!àpyVQYµyDKñŠ€°’zCrÉmó }=GX?ëM£³Ñ¶¨KL¡Ä4«%¿Şdj•¥ø¸ÒÑŸáÛåØˆşIw0%O³Âê‘*—…Û`›tçÙ‚¯i[2\Ä…S’ÏaìW¸Ûüoi}Ìt °UGxİÔ×’}Ïwè›:™N÷°‡5®Õ·óô·Âš£¯Ò	ŸpäçœO7G1±¹Ó®à¢Õdôm‚'³}†ÌÒûÅßmY_[CÂ~á.	¡to»€ƒ]@«[øÕÒ˜è,n×,B	şx¨ë¤‹”õ¸ºKY’›²­Ã,+°ÿŒï×•óÆÜwJLWÌ‘§÷]´"»Eş¡Ã^öı~ºÎ0ï†pşyüÖêÎÖÓ\³­sb~şS€€ÎE³Õh¬Áã²CÄõÄÓ{WÉé¾m(³jo=khÓ¡ØàëìHæ<s"øıP¨=~CìÇNDÛV½ßÅ¡p¹%úÜıÉß¢Ïdª^ˆx'¤øbuÙ"¿IW†Â²Q„&9mŞPı½"ÿPå-µñTïR´±*FbŠ_âe™Èô>mÍú‘Wrƒã{—Hmbäu¤£´5'0`BÇY<Z
G°Å)ƒ$ù7cfxbƒÛ9s¹o`.¹+î´õe]úûZ›vDfA„Ğ·Tf[&æ‘±&ò†½Öb§–åó@¼œµï‚¼Ì™›¯…§lJ.ˆšÍX¦
œı{U,£ÖTY}Ä6tt«7¨¡´Øú6Kû+ş³‹}y
A>Â—¸\T]r:õ5Úrc·š<à›©B-ù¦W Gä^—İ–¶ÕÖ«ukOòµÎÙtªÍcvEÜIIvíÚàš[xˆÀ¸a/¸•kÆË·û¾fHƒƒ9x`Ê£{a¸èÎh–
gÑñaÙt*dÄ'8Ô(dD0óe¯P PNäà&ú@Ö‡uÁıqÖÜ>/h +(mĞÇ®Ù~¾Ã!À'Òl6ÿ“Òroì	WåÍ£Aº4¢±l¥$R<”6’ö9¥S]·€*Å‡¸§Å…@™:*ä€×ªéI3u7!n‚­¥ºéæ‰°ä‚­»µbŒl”È¸ïavyŞ3µº¼c‘Ó{·Ä&Ğ0áy˜T*øêmŒÇ)zÈÔ6L”ÊªsÆ`Û5ĞıVHı}ßÏ*Ü†Y—ÉÄí$P.3G`ß›Ú?DÄU–=ìgl¶ 6Mûw×TÖÏkËDñyJ‚7'„&(mßSWX°%ËPeu*æO®W,}áM»PKy9o3¦=Öz[†¡ËÎ;ã6Ú×`ŞÂbÚ¯ó{„Ğ*°ñAVT„2—ßm[ÆŠf×Æì$­¥yÆqíô¨|"ÑZ´·volúîzuIéª‰Ş]{)é÷ÜÄ‡ó6îÍúº&ÖıLÜ%ã×¿™ì}–"lì·qÎÉUU‚WÚ’ÍMÑùƒÆÊ=`ş ”Ü6œó‰J¬(l‰€…›I›{Gíáù:3‘åĞ?ï{Qò¹>+.¢©†h«FsÏÙåşkLªÂX)ßo k[ÖWÖ¤Ö·Ë`æ_WÔ\t½Bÿûz6¦Äºñ€\IPxüdË’cÇğ{™5“¬1Ïí½#A°÷’‹2ešÙRÌuó¶Jˆ4Yj9jûÁ–8”·ª:³eTMDo’¯«ça
$ÉÃ§“í
¶ÎŞædYÀÙv?a£Ğ¹_;¹ª)ÿÁUaÍõ+Ìb);g¶¼±úÑ$Œ\AwœˆÇ"%óÉÍûŞ»7›äË£¶?ÊA)Ç}Ü^N`h†R&õ@/-NOa-É¡Å´Šö¿cø7ùU”nl½.µ­Íœ5ÊDL#Hs$Ò[R-½iêt6”/ìlñ\¼jÍÂ½•œ÷U@k‹]¸ò½3I7~D(³¯_X`Ü‡¦înÍÄGÿ3¥n¤ueM«²$õ'C¼Y æ1j±v7l…¯N™TÅX‹.•’À1Ò×Â;7ø·ÏfU98 Ğ²Ëo`gòğìË[Ú'âbä÷ÆX’sÖÚúÕxQÂÙâ½öŞÿğp‰°Ô‚b?ò„ÁrÈx¢¿@[zs‡ş©Õ®ÜUôœZšuæé³qâ÷şÏUöcà~C
¿rOœ%Jâ?ú¢H7ŒX<ØÀÖ5&±ƒsŠ…‚L†/™„g´ù%V51ÀvY üxÖn”µT. ãÄ›@ˆĞ³Åg;ú¾±\¢ŒğeP–1İš½Åï’É2Ô™Ñ‚ô4)¶ìï›„9Ùóõs½û®Ã4µLûŸoÏbT«o±™Ùo¤¯Ü#à\4–¢°[1#1:sD c†V4ÃKMu™x ûÓ;“jF:áı¸÷:qÈ"(´ouœnA»>Î¼_lm™ŠÈ¿W‡Ğçcß~¸"è^®É
ëÇh—‰ó¨Å”tâ±ŞÆ¦9GœÙ…nSx0€Ds’„ïÚ‡
Ã¼¤9ÚLE“dòÊ'ŸÎºÒ,…'"¾U?í3Bs÷4£Nœ¹ctF0inuú=øáàÊÃÏÄ<Åä€eYw~J)ı[¿CŸu)¼k£üÇ“ÿtxEªCìr¾Q¬’èNm†èã‡äÉVæ›©ÖÃ|÷ÜŒËaÌáİğEszìï/`ÿéÂ$²Ôg›ôFJ,ä…o¼Ê®¿!fKİ´¼RÑÂ*æå(‰¦yohŸcKÇßÎlä$ùõZV%%¬ÒÉméŸÎ;-›Í´Y-fñÛC\W¬ç±a7	}0ˆ“¤ş™¼]¥z·d¯Ç?…ï9êõZÜ«¿.P³Qa©œ’áîuk]Á¶Üü®éhœ#òİ•ÚK™Ó¶ÀŠ¬ ü¬c¨)„†/KR1Ó‰€T˜Áô˜ò¤-¡ĞÚ?R_–"Ò²¨g¯]“À*L“Rÿ.7OZre4C¿Œ‚ÁäÍºê(Y.Uì>ä²yh„Ã°@Î d9ZM-Z!©¬="‘w„£µ{¥fÄ°Êq&|e ÿsM´µ2³+;â×£v5b‹`Èá23£ôTéÀ{¶'†¡WÈ õ¨g×uÅÕdLËÁ4x¬Ø‰mÌı†p§¸ªœ‚ëKu’´cDíÈ¶ lÀ©Ö£…H€knÅÑjæru˜ B;ãÎÆRFŒÁ¼ü(«,’AÖc’¶í•¸åù?ğKJË‡ûƒÆâ@xÿæV'	9İUlò±öŞ£jØ“f·j}#§½¤Ì¨9c½yŸ¹¦Äá2wØ‡ã'Ê;Ólk¬†]Å™IÒÏ°ƒº›şæ°GPOngñÜñ.PÚX¯ÆÈ:†ÇO823M'S¸.@Ûx¨™:€åÛIoB–ñ¿¶6Ğ3äßF¬«‡ÙŒ‡”p'¸
rwº?7³I·;Ôug#z/|ƒJW–*ÊktÂJë1hC8Ïæš<‹ÍØ÷»U³{ŒqŠ}°™âÃQbeNøCÈÒXš—PÎ`ø9W’\áFFv ï]rÉ‚»Òäœ±)“…w²qé­Ñ6)NRmt'£Ö×æ$‰î¦Ì&OJ„ØÅaòÛfæÑOkÄ*`f¬O'ày°
ÊÌyU>
Äü-tG²©ö²#‚ê¨Õ—À/£hRÀ®
6d'ÔöİĞ§š»ŠoSíËŠWQI+õ«Ï°ÿ™B³óñœ†$³Ğ%·ˆK.M+Šhë²zşH|ØoÅD`ª†p¤U —r‡Ú*üË ‰6+%2ìwäi†¹F–ÖpVİ5\tùÿ‡Bz  Ó;HÖú‡™ªr¢;·Œ‘… ‘gX=ß“ã=-æéA/†ÓE2›sŠIpÏ†œBÌ®Şêzô,8/®RÑ ıš$KôL«“=Ÿâ‚7U¨™¨GÂxë)A@­À…­ÁvãFñÍkÈm’O…Uò„;l$#\©@êHÆ›gÆ…XX‘iI	EŠ ZØ ¡—$úOI­³‹[èƒTŞ‡øÿÍ}œãDœt¸x$t.‘ù9šÛ&‰eé»ô«dè79ÿ–™È5öäºmm!lÇö,®²õ‚}Ì@À VŒ‰†Ã•Vk\U}Ó;şNÉmí¸~²ÙwÉŞï<Ñë©÷zøğ·j…×õ›JšÛö¦q‡0¡Gó_/2"Êğïßâêˆ½Ó£1œ¸.Û".{jfH2×½¶‚Ú>K
¶54Ü±EŞí|¹×‘İ[ĞŠÈF3Yœk•[Á¥=çaë3òíj,ò4åŞú<0<ñB"&ô¡"r¯iA+¦.rÀyšP7k}¬™SÉ„c}ÇçÅïÅü1¶—H¦9hÍnA>`å´w`rÒMSÏ¤­C4Àı{}r°ÄG–¸ÏŞOÈ'Äo*Õ*¦bŸ*5Ì"Ù’˜Å=|]œµòIİˆ¾¾›>vt@„Ç¿k»Ø6¢“ÁûiÀVÆİ²Â,™æG6¨îúù’Ø4£P
'd¾ìz‚âŠÒtâçµ£sSm{ö
L…ßÃñú›ûS3xeßCÈ
Kc5ô ™s[hÍúİp<Ê_=z6û#¶#aÅùŒfœº²bM÷,È†\“emV+zJša{…ò
Œ'àÀÀ™9˜”ª1ó‚O¦¨¹ÛüY²vûñ½}¹ëß“è¹Jõ±Æ\ŒÇúÓ¤óğ¥ğJÄÆ(¸,NŒ£0›	 .µí+âAryW€üi“%:~MìQÅÉ›]{||} ”hûúdÛ†4’xn¨•)
½Ú-•¼Ãããq-ªS	"îSû#qèÔ™ï¾óÖÒücM®÷ªE^  a› ÂÔƒ¨” ä±Ìã<5J?ÈîûĞÅ-úËqóÍ¾YïDTğù6™2PY23™³U|mù®oÉ‚[˜@ñróš5òªÕYzä£À¡$êVU²ÔÖPÂ	ôHQ×¶ÇÛM¹<„ÖŠßµS{…FR{öWìt3RT%±—G	c¾s'?äk„ ¦Ş¦µæ'K¾ëcùÜëJÍGqe1µxkÔúÜ$9˜ãõĞğã$^'R«ø˜hôì2SÈD¡ØóS$G<ân±ETİCªùÃ´t|tÆ«‹®ÆM`öNÅ@”HD…Ã\B+%äƒg‘,²èè·ò¢—ÀrWa™×xÿ`ŞTU$ŸsKñØÛ;·úy¥F$¶ÖL>ş°N'€ÕRÚá°º
ü ¼uÌÄ/ô°—o P“X–)u¹¯‘}ÓÚ' åµ¬ÍnÃ§›ç'>/E²šØ‡pÅpÜ­½Å™[îñ»š<ˆVí"iÆcjŠyö~¼• ì$P¥’ŠÃ{Å7¼{@{µ®‘Tº	0wï}‘¸’š€L á9ßá@iÒ´|úøŒ^ù—´š|r]DV9šeP!0œa÷r”î/f+IÄ^Ô;ÍVé}‰«Üş¡(ÍA$Köì§ù1!¤ª¯¿ˆºm92gÉˆD€+|Œÿbàİ	¬-áÉ¶ƒåDŸşÕO_)kN‡è]ØòQ<î{èùOëÖïÿÕ“·.í›Èèù«}}ªß¬†‡ãúw±S5âñ‘Şí;ïÃàJÑäÇLdNs¯m¾‚­°5µKÏÖŸD¼t)XÃüæÊ-Í´¯³%ñ œÇ Şv±ğÜ»”gÃ4QĞy‡pš¬şîu°Ô@æàub*‹YÁ·–ÊîtÑTÖú(¼Ïö¼ÕØ•E»>¿…ˆh0Äx:×õ”*3thPÉ³ÜcALŞ ?ÙõF×”¦` ê¼oë‹ZcB%õÊÜ! /#CuÛ)ñ]:ôU-¸ ¼òµ9Ÿ2kPîSüõº‘8'wd¦ñ‹©²ƒé*½›BÇ}!îÿwı‘Såsßd€Áœ’¨ìbŒ³¬*c¼9ôx´$èOÉ5-,şSÄÁ×ïıX9ç5œ. $ –+[òUòûñ}³¦r2@úÜŠ\ÕŞEVÄš€ƒ°Ò•´Qn¨€’™%8|«p"Z”#6˜Ø´!9Øì2O>l}0B„JoDûkûÄ}è?ÀÂ1·3È5 àÏ¬§Bëñwä2ÀÅ€iİĞbûæÒÉÖõÀ0¨Or}ƒ»øl¨’rJTû¸ÏË‹ïˆ‰&DŒC÷«®Û`·çq‚çrò(hÄ!´^W4ÚîÅu7§ØÊTìe¹†èæVD˜Î‚ÆWˆ’ZK0¿£
·Åè^AéÍ´S`÷D#•¥Jäè†z¯u‡MÉæjw?ggaG*€Ãä‚Å³ÅÕ]Q‘8d¨9N5ÍH“ş{"™˜İØ.r¹ZÔAbJnJÅG"h±.âpc‹üDSÿ0”$CÏsº-Œvı/°¶À«İ~í2ˆò!ÂÚ¨cÌ	¦ìT‰Ó\»´*XˆwxªàÉN«yï¬G[c„’¤è»cKI›\€Å-ßjulgkµ»ÑsŞ»ä£o¼ñ5¾ÖÌRÙ·WKÊßX!eJ
 ÖçrZc»”?’4"Ô fJò
³b2rˆÎ—£¯1 Š9Y» ñ‚6ÃìÇ››uúz	WqÅ ŸÕ2¨9»-LBÂÎùO8 “<„’…Ïvì?¿õK~ny\Ù.ÙÅ¤Å)Åå,˜…,ÃÊÌĞä5>‹¼ä­VRşZ‚¸œ½Ñé‰1âÌç\jÓo?š@Lò«í_VİÿÄí	åO€¶n‡2”bÙŸÃW}|3ôë:£¼#ÄÇp³ÔİÛ‘9ú(czÙØŞ2»u|¹SÈ€„ü—¶#O“Ú²ômLCkd`
=üîw×Å*Gƒ[©–N“ÒèÕ®ÌJLÇq¢™·ùLL´ [`ÖÏÛl¤çF„ì,É*°«6üZ|WëyLÄÔ„ª–çgêßQAF„£KS6”IªË;$Ù¨Äß\-o­D~¼ó´TÂÌ=‰€këeÛŞGÎçÙ$yR¤.;¬²Fnò¹‡G¢öËô4G’O½Ä»dî[ÙÛO2õCØ˜—‹Jåê~¨€\öBèH…Ïº®C˜Ñ-E(ø¯a/¾DëÛÏB»w£ZZ½Œë5Œlš&¡Í2ÿf.™ÿCÈ$gb`Jz0"XF4ÁƒHïqîÜ.GÜ›÷x?ì pİVnüG0ĞxÚPSü¸[Q…à(WÉ ó©S»pl.–% *··çÍxõ3ƒ§à9Úİ¡Äğr o#­1ÆÂú¯#Yü-™…×¨Q’µ·ş¿C:´UûÙ…}´?lU?·éUE{¹ü>ÌÃZÃéI@×?•3ónncb¥\´¶ñw‘¶+zÌTÌc©¾’sK*I7`Óz$üÏß2Œ4ÑU^êD0hèÛ_dJŸTÌšÁDxÏM±o1qD@yd\Äñ¶¦ûkªDfÎz‰0†düĞ8ÏıÈl>îêagV{†ƒ±hĞ¨ƒ`éÅÇH×DÖ$°n(\«Ô
—`¼ò×%¾PŒÁMŒëWŞU¾Rsxš·­ – ç\#â™’øôgã¥`û¶J¦@¡ŸİÁà=7L­»–tË/Y‡wíhg¨+à–Ó²ÂFÓ…–  øbd„øş<"ß}o¥äŒdôCTi˜5©&[ ®$!m^ehÆq'#h+IòÃ3»ÉY¾Ì€³Ëæµkç¼<uš²èSÜÀúOqv›¿|õœ‰“YBL—¿ÚÄŠ'ª"MqwäöæM5Ş‡§…‚L•t\ooùµx‘CwÚd0i4ğˆåŠA-01ŠÌÀ(3ù¬hâeÔÓ¶Iˆàõ–r¥v{½©çÙAG‚yfMÀS…wÛ„ÊcG`4Ş×ùJyGßdŸ*®¶Æ¾/ø±„ç—o]õî6Ğ»1Â{†Š—6QB+µ01¶ˆ&ÒÎƒ/P±Öºö›ÂÓêÀTĞœ¬¢1³ÇF¶ŒP<™éğ 	I`s˜œée)™Ö«P¾à'6}'B€…U©?ìa´ëC$OëÌ‡ÒXA#zWZyèLî8QÜè{<ãÒÂm!£°ÀÇß¸ïŞW¨:ì}\'˜z'½²ªu_¹[£
½"Ä‡háP4¹9òÏ)u¶İï_?W+ãK’/1ı;©QŞù8âõ.<MwPt¥cé‘¬Ûsc÷RV‚
œ…º I²ŒWÃÜ«„øN>Øúà¢aGÒ“Ó"Ê‚níB“²7h­QÅrX˜ÌÒ‡Òvt1ãò{£óa4¤Õ$äD?ûkÖ?—Ï]ˆOb‡Pİ•…=¤¼İê3lNÿÈèu}ãBîsö	Ÿr†xöÄ˜Æ9÷ÎWÔÒ~x‡áÌÆ.yöXÙt˜áhoukÚ’Â
RxÇ	]I·L\ğÖ“3è£[ş1oÍˆüg¶JH&t“œé¬âŠa&%§óC4¡ GìêêüjGü ‘óW¶Ò‘t„Sùÿ´ï ‘¢ğOÌmöğ«ÊS†““Òı–åz;¥½^³¤ŸÇ`É•ß`YDƒSökâmÀvwÑ¨=j|:*#”¶xjkX¸qRÖ´wP«½ ÕVÖk°÷{±DU`$Ü~Òg EW/oë¢Ÿ$Q Ğ2D±?Q>‘kyób 3¨œ‚AÚÊ Ê×ÏHkÏ™¯,*óìáíIIüD…Ç–½+ ƒ‚W[[TĞ.í|\œ•ŞóƒAôÂä´‚Â'E5«QÑ ±üøö´Õc¯¤à[ü¨o¡ÍãCõ‰Ìµq	Q zßÉã(:û¡'òâ"×ê&²Mº½`%¸ +0Z­KU²ØÖ-4©çBn˜ujs¸’¾£é/(Ï_Û’ *X.!ÄQ[î˜h)®MP/È ÔMÂÅ’lïÄ$e6ç{‡HFr†‰åhã¾ •Y¼{?§ÕaåÃP·Í.i“–×èíû_­óöŒk<†× )îĞy-‰¤×_ÏŞ¼ÙTÀ+òu
ëHQŸºÙ<FèÚÍÏñä;ŒMğ‡Èo$Á\¥ìJÉLıÎHLo<Lƒ@NtXëÍ½!ÏA¶úßE½®F.eÏ9…eá£Tmé1¡Ks["&¬éª.À¬sNÄdc´X¶ˆÕHN¯sê¨å7õ´oè’£J„ÁAÉ÷Û£!)Ál…$U€ÿT‡=“t[òWØ’5[©]S™7éô‹?ŞÂÿ;Ğ/¿)ÏF3R+æºmi:è6 Ô&q #;kI.ï‚wè¤Ô	T–T¼şmhšš\*òÏ2¹óa_³h?Íiû_M&B8?NÔ—ğM
®‘¿Š(Æ#}¨ŸWÒ„šöt’È¿•º
OşY‹„ãTõU…Êt‚§)Ã†{I5LÈ'{Ù¢@¢¸@İ\Km;i¢zß4Î9¥F	›^¢Ú_•Á	©›zP¡P4HĞH÷rdÏj`@øj°ê}4ZL!fUDÜÇÇ G»¬âU:)î¶ZköL œÊ[—9èÎ{.èU©‚9o°XæíŞÙxÒÒ[ÆìÌÜšSIø}Ûµ¾É|¡ËF:ıÀç¥1¼-ü‰­‚U`?·+pÚ·JŠ;ñ¦1Î_´Ÿ§7)‚ûí’ùtjKa–I ÖÛ{AÓºì:ˆ%ø®°–`ûxŠ®&òsC´#0›×…HÛÖpÙSìÎàƒwş[uõ÷¾Ì{( ºî¡g?½rÂ‚ÂÈ¬t¨£ Áü‡€ö¬²u/ú™œ…íH¶lëëy§UŒÂtS`^ƒÜX¶)\ÌC¬á%‡e/¯}v>Ó7ı¨3k
PiôÜ±WIÙ:wÒê`Gú²şÙv:©-K²“¸X¥±`® B¶~ßĞ÷!0œµhx]æo_^íâË±^!ˆI^´’ßy-úµÀXŸ,îfl §[–UßSfœváL’ãÎN’V:¬B2U=Á¿ÅD¾©Ä
)c‚ü¡¥‚{äQ÷·Ôfgïåœ³‡ş·çr…»…­õĞŞø- *…ß5"ÆÓej×Äegµ® ÚÂ	¿TPò`_X&·WFĞ™*[ëÓé¶äbB½¼‚’“Ãƒ0ÊæÆw9¨Á÷èÄ%_ü\½ÇÎ1£K
h¿£3ëƒ›˜çÒ©NOG ;ºïHëQÑïğS{rô¿±D{>#SA{|"ÌkÓk¿nƒ­¹?›Y$…"®ö™î#ïá·¡³vÂCØ¨zfPrå^Ğ==/ ”q§<–Lu£ÄC½l¼©î`@µÄİ­¡
øNê «Ã4ş’¯Öƒh¦zšf$¹´=Ê×tÙœˆñÓñH¸f5&Œş.ST’ªy
˜«Ô	Ù³^ÍõaÄY2ä¥(ğIiø{ú	µVzüÇ‚ñãZÙêû¼³v3¦ÒQSàÇïD6¥Pg°…2ÇëH²vo¹ß°v8HÛ<Æ»Rş¢(ŞQ4œUVÿ2Løh…8\×xï!K’Á-ŸòçV;ÿ3IBè–úfz¦0±vk¨ß²–ÍG£dë\cø2ömig\5@J›ª‹¨6öVëBÀ2à~Ùyı¯4O4)PEŒïà Ğ <MõJô­e†“hµ¢¡áå­.~Ó2ßY¥ÓãÈvLŸŞ¥5ŞÍj;€û×ïœ±ÙOJ&²[…Ö{NJÁÍ$q£”êÔ™t©ÅT‚['#.P·UÕ^¼µU2²Û¸Â±7HLUÅm¸FcAÜu–4”Siù;xVÖ‚ÀaŸ5Ÿ-z´í†R’ôÔĞ9)âZ’l}7hæb>PI*ò{YxÈ™‡³g'á[ÇiÅŒ±ä™°ÂS…Vo:èb©rx-ÇóQuñÉÉûĞ@ÚÀ4ÙúÌE­>VŸ7¥îM˜‹¶§‹¶¶'P z-ƒÇÍÕL+g›Ï•&Àû8iSú/¥\ ä;ÔŞ¿Å5ÃÊ]@/RpÕ4fçëD>îL)<§Ì½%[û‘é sŠ”Ë6SÒyÙÆ/³UdØ,`m†Óˆ:¿ôwpçI,ºİgE?˜_QNÙ¯ş_Ñ[û±…ÁDşcçU
Ğo‰ÍYÜóÈ”ã4×ûĞì#ÇNŒµÒ¯İ;ÊØ,XA+Â’Ø¦C])?ÕÏjN¾ò¥´­2ğÚg
3uàí¥ßÄH1,ïÂ™’/vH$[UfHq,BAß…,XEÂ
F¤©D¶å‚ó—¾İ^bJdÄ²_ˆ*XÙqöXcI¯Ğ±Ö«Jµ0\qÊÆqpŒ›.^4Ş=*ØŒç¸¢ò®¨c‘ŒhÕÑ3iüğ‚~jÁâÕuxÑ­Î¡ÁnÒ÷QGq*o*®ŒmÇ‡³d2duñ/›?›pWİÊkcs­Q‚iR\ƒ¨'•ƒuu©,²—¦`á1Ik€H AB-0 p¨¬ d—ò^d*;¬BÉqT)ûO&Î®²!(~ŠL®öh•<‹³ñ‘brÇoI@˜úX°í2c÷5›Ò&Mä@¯T-(frõ`¸·9¶Œà–uÂlóDu+N–Õ%CôÔˆ{02_€0Pú²b1YßùõÒª<AÓ{lÛfÍQíhùÂYÕ¤¼@9¬3ã×$pcÕÊ¬¿½´‡ıtQ9jn”×Ö+øCô–HÇ7I -hT*4k™xdiY8®ÊYnË:'ó¶>‚ÓŠ;"{0dÿò¶¨iËhâSl³X„AC<x¸ÈÜ£4ttÕÒ¹¼Ñÿó#ƒÂÆ
â táóÙfzºò…w±µÔ^ÆyŠÖ0ªšƒ~çáÃÌ”3T¦÷Á1!’òN‡—Çm_ÖV]ò"nô~ĞÙRæş÷Ä$rõ‹"£ şGèßjÿiX)!;;é8ÆÔïˆı¼ÙŸ
ü“€pìŠ¢¡c}¾+—,!ëÅÆ¾Fr©¡ª›u)Ğª§3Ï‚íÌ	¤Şøqıp{òû!Ú¢FÑ0ç~U'ØÀÆ…=eF“idvŸú…–şèÈöG|½6©k?WãÀ¢LİLt5nr~ë~Ñ‚¯×ó7ãDÜ Ç³Àúòzé;¦fe[.KTQ™•¼€Û­>Ûåî–e4:;¢Áz§Y¬ÌÖnA#,Mß©Úğj.l–[”ĞN1(‡ Ë7:mk"^í}€Â¶)sùË>‘¶?@b*ÚúV€ß7,Ë—®ÖÒ4²f?LİU—Â1ïÕA¨6[%Mñ5qE7œõSµwĞ’UÕÄ@OÎå¯îÇ¬º ÅÇX‘æÚ‡Õ°PÁAÄË­2ÚĞÿËß¡tùÍµ–^ÄÑZ;ßœwå¿·jc–!}ß6i\OG9—˜sPJ«-B„cŒ·ãò»“Çt[éÙª9,ª//;kâdâĞ… ¿å\6ƒ‹®¤Ñ2%p…„†,MÜ§õ”…Oc·WıĞU*r³sõÌÙI·jö3Á‚‡g”.&xiæÙ÷àZrg>\œ»Ã"†}0“ÛjDßÖ„›LıĞ>62¦Ì%7æåI<Í¡d•à˜aëhäL\Ód®ÿ	?­¢‰ê`¡ï£›±S²¦Ï7Ê»4”¯_A-&Ë<Ÿt‡4i^Üş/÷Üåğqå3po¥d
%¦ot¡]´öóâ8b˜¤˜?âC4]©¦rÕû4~»ŠÃÓ5+Cn"°ÌGø™u‡k×¸î‘ÃiLó…Zk[¢XŞèóAå°”õt¾Ó;€!AöyâïÁÚ×›yf¿w~îè<‹"PBœ‘o€Í
Ú†ˆYG—»™4Â°¬A¾o;ß"!0š‰s—`+<'Y—T`ŠçvşÌJï¾*Á‡éê#9Ğ]ü&<Gú“n#ÓWØãùKG„Ä9J	ŒÆY¦6AÅLy%k •)ö"Ù‡beêRÈblû¯YM”#øb€’b0HÚ$ìo£#ğ© ç6"0!yŸªˆÛ0~å[ÈœX¬éøPğyÜYõ5‹•ÕnAq—ÃA¡ÕşNÙĞ>°Éü¹tT§ZG>EÁË‹Xº–LpK{¡ıAPÏE‰ øN\ò½t•|*1ï¹»Ö™¿3>tQÓä¦ñÁd>-‚™/˜†™%¨½CoE¼9$è‡»:Ó:èµñP&¢FRRMœgÉâ‘š,J š=½]W+°|Õ)oæ–_šÊ5Ö*CÊRO'ÉGG-YDÌ„ºÉºWÀ$ç™Qr ¹ØvõX³8ê¸Ö@¢*»Øu¡Ó´ó/KvyÕªtÿèÇh(¿Ûø&»qÓ$¯Çv?èøƒéScØ:²:l “û7æºZAµş¾7„Æä-}}	%Ğ5§W8yM‡²@™°/1É¹ÒNseÔ~ŒÃ©`°€p1¦ûEİ*W7à0aª~Úù*òG¦D‚ê¤PğXèi^ 6R‡ÃÈìVêjäÚ³ì8=†2(/şíf6!aIf*øMXOã÷?ºíjê½,N{dÉ{òµéœ†õ„àkæ+K
˜&¶qZ6<ªœâ0D¤‘ -·§£áÖ¨õAÒ©mÕh¥’^»z…\RdM°±i›j>ØD)—3gd5m•Bô=êÂA/n¶º·Ÿ½]‹•ôì³˜\B(¹¸Ã0`®Ü¥İß¬”W†])ëş_õí§Şı‰r6ts
 ®†â¹L’Cæ´Èè¸–EÍ=Åñ¶9û•Ï‰GgÓ³
Î¡9Dx9ØrI%ˆDµ§’¼@FoèÏiÎ[¡„Il0ëÄ~Wib?!£G¬àwª^OÔ·f%óRïÿƒ0-C¶¢*İ^4°©\7ìÕw>4S$ˆ‹ŸgzëË¼·H*=¹ ÂäÁæ•t¹À”DÒ‹&ù­!‘0’„_¹—k‹¡šèjÏS0µíka
DdXòÛ;çÊâşÁ)³¯é¦÷B³ãG»ªLiÒö6Ld©‹è]¶JoJ*ÏZşŠõØ¨âg£:ÄªÖy‚Q~–‡²›sÆ€“ŠjPÄÉˆdœ~(šÑMO·C×¸Š›£FWnğ¸İN3íí÷Ë+BĞ&_>ìED”±ïÕjù8¸‡fAêßáöºÏù|ŒÀRç
#–½Mm=­§Z:›ŒJ7ÿQƒáõ€Ú•Öaño'âjùì?ÁVé	ÏË¸V¬Ô‰ĞìZóƒ$Ô(YºaH=@úÊm{xµ¹,ÃÄQDî¸îB™Íª)İ<¤dBz½›€,)}L\t×	ğHµùö‡Üˆì•ö/1ÁŞvjÒëˆü¢b
HÍW.B˜>öát{næPË‚‘/4<Èa£@”/z­ìi<½`\0•ø/&ŞTHrB=Ë0Í4Ï¸¢xRhÊëàn¹ÁÛŸ¼ò‡|dÓ†FÕøQIKòF?•ÅDÄWƒ¨¡ënÏì ’‚œ~|,DËşş6›8ñqô9óÒVd(’ÈŠ:Xìºk”ó¾±z§(»n” $ÌœÔ³  È€ä?%±Ägû    YZ