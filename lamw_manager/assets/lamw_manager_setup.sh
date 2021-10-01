#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2788205823"
MD5="1a4fe56712cc025fe70d23233254a3b9"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23628"
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
	echo Date of packaging: Thu Sep 30 22:49:57 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ\] ¼}•À1Dd]‡Á›PætİDõ|QÊtS‡g’Æ5YL,ŠğøÅ@]¤Í|Ñ˜¥»"ÜIF†³
<"m e·Ù?RR¹˜ÔwCk¦s¡üx3¡‡Ğëç¦Í?l•èĞ¸Í?óDŞòÖ!ˆÄ”¿È½¯Üˆ˜ë5èSá„Ê´¨ËíxƒØ1 ´{ÑUò”A‹D’Ô Ôcr~->¤8^æªÁ…’UL¨ÙŒÒåÄÕènNë]±<J®«…õpŸXz|V³+cÕZÿ‡»BäÆˆB£wMÿ½»ÓgrÛ`x@›ïüvjèmCŒ9>¾›+ŞÄAõ;¬yi‡ÄŠ©úDªä”#n£Nò<ŞÇï)¦Êùî`½TO¸ñ>é2‡ìµÈ/îiÿÓÉ çË"ù¤N5º;üÖx	†2.£^š{?ÿ†j§.H‚`XQ‰YÖ'°d‰Ğ·ôÂgf“ n]Vßæ‘G’38ˆi]µPòÓb6EÇnAJ |…´Ø;‹El¯“Ğ eíÎkw{ŸYRƒõ¦tú,tÕx‚Nßzùÿ¤y"÷«t¸bjVƒ¢fkqØô…Å©’:µ“I;bÓ•ö!_ƒÀ“iåÃšQÿ+]nğ&²ø^u‘jSè@ƒ¨õWó.pÊÌx¡D‘~`((~8ùqq½wÌU¯ÌoGE-†yûNoß 6.£ñäçAÉâÂÙªs È›Ì¡åÁ"*î-âƒÑ}N¦åLÛb†•î_
ëß¯q^Â5w~‡ewŠ|	‚=m–à³HC²aíˆnÛğuªzpM€”WŒ§1`zÁØ¢r_TOGÖV‘Š´]y*×¿§‘ü½c´÷ÎSU§šÆ†™˜âP¡¥ú0¼9šüwñ¨ô•/±%®‹ò¿!))-ãºk\mİû±¦È9(‚Å<¬@/ğ…ûú$|ãò¥¾—Ï	vEÙaD4¥ ­öI–°áøqçÅû\0Y5>`[©M}ÿ†™"”©"´†(´µßå¾Ö3<dokmçŒÌttõøÃ5|¢måk”Lº¡öŠRE­/ìŸßèĞacVÛ½z“í‡úÿ"ÙâœDzÈ† Œ€¤^fôÒ‘«¶­õşâVqKÊÌüé%õ:~!Ú	ìŒÇ±[€çZç.¦4Š4‚’lKò~Ö–‹ñ¤ÿúz{¢…
\IàaÕØ7eÚG rÒúY 3‚’¢c£uF/æuÉğå)ˆš‚/wŠ<AÄWZùÖÊirBIuÊ~®ÿ^
Y,˜-ùG%Èàî:§±Ï”å]Qè*†5"<ìè¡Õ(b>tOƒ.V•ùKèŒkj*ÌZvª¢ ,r.DÓ`êjxåUì¤ÍÑ+=×Z@›¼Ï7.I„93Çä½5~Ã7yğÔz¤;~:øöî:s#Á+km@-%RJ¤
àÌª ñÍâ5En0(§ŒxgœæëÉ#Œ«*/ä”ãŒ&’bšcY%€Œ_ü“jÑÅ¨©W¡Ğ±;o’ã8u›”ºâ_ø4Ëì™õ™İtä¤9N–nœ€1Ùˆõ®‹+N3SA:â.éX…x{¤7³…­²£P<´Ã3ó˜ÂAˆCÎêÒ´+PeçW"hâ”8È#8>È,&ŠÂäpH=ZXB]¾mâ2z¿Ëñù+4’aêÙR#\yG¤‡Š§¨Ç Æ.ê;*4~=qÅ‡1áĞdğ[¶üƒE^Q·@”Û÷úp.>öÖÛš¢¯ãÔÙ‡’1”öß*ÿ¸fŞ/ÙßãÉÎ1ç;åig—Æ¾ümFcŠ_ Øá	×áyÁÇwÄŒ«*]z™úØqíDŒĞ»š‡™."*«ÊÃ@©ó:Ù'¤v6v˜#åoßË_U›Ì¿Ãvú@Z	Í5å«ªØ_!ØD¼üaíÍ®%*¾‘7ÃØpVÑzc2ËQp­Ü-w µ0ê< Ÿì½@ë<Îº8Å™1¶ÿşÄuSØ‡¦¤%dô’¥¡`#v‘şİ…è‘D`'­‹ô²l)Dl‡¬¶3Ø‹lğïÒ•¦•¹Ø¶ì‹bwBqÁ~)JlÇBçÜ¾Ñ&?y4ïÇL{2‚AüTt)n’;&d}€ÀX9É:y,ş“ºîGWl"?W·3uxŞg7'ÕÖ³3 ©šôA¿Ù@š^Û˜ôı£Õ0tÄŸùûaª(çRKq6A³Ê,{B¨æv8º¹»ÛÔñæÊõCëÆíqÇ³›†²Ğ¾®µ*úW‚ú7A»…„}óŞ¢»©¤§üdcø&ßi Wx€Z#ÇÉÎ×ÀMí(Z—a†óUÄ<sò ;<‹ø®akëß‘^C§ÁWÀX¾†{e9ƒİ+Õ°-Ëi­å¬0¦ª³GÊmm:^ùØ¾ceçœa¸¨Ñ®´üğŠØ„½¢„îÂÿîgJAá,Å*»®ùf`<¨!¤@ë	†’¡%wõ'ïYN¹”'ÈZßÀ·2ä“òM¥®yƒFjÆÄÍMäw>çG$UŒˆMå¿åÊ¾Óã¬Ö)ï,ì?av‹ å¾6kb!P™ˆ Şfybkô¸Å\µ¶«zx+ ßªv^TœË£éıÀPZö¨ÿ¿ŒVİ%™çbÇ…zÚ.\j˜˜Êì{{Íˆ ²w'LÃ—c¿ˆyì¦h;ÛB»B“^ZÁŸgĞÕsZGm†÷‰:\ø— çè1şbH{‰\´çTY¯áˆÏk!ägäÙIwZ‚—³M'JrÎ]6å¹'F[ri›˜»¥ÌU—(§9z?Sí–Ø¿rF2ÛÇÜû@”\<Õü|ş»Ã±öp—µ[y,’>Â€mÀuvÇ6EÀ…}_N7ÑKÑ:iCèC_WmŸ´”ÓÒr¿×˜Â
MVàFÊù÷=í/Œ«®|Ûo¨i„!c	H€£ÔÀ7¼zB»5a¹3·<NéË¢rëjg°qÏÎ)T¾hsØì–¯8£—ìNç–DÑ*°ˆ"Œ`ÓĞÉ¤ÀQ3µT/Ù‡­‹ŠÎÀÄo$gúÇU©£·İãiì€y2±k6i¡ëĞşz€¬–é¢t~Uğºæï,mÎeÙié³$OYˆŸ}£¸ÕlHŠtf¯—0°ÏÑÏ)Ş…ÒG•šÌ`sV,qK×ÄPõ­°Ib»w¢Âsìä²¦ØY±øXEX®–÷~Ó™Ú’ĞYöy®T6:_ÁjæˆeãËÏL8;+G6fE˜.•<§Ş7K-U„ÿ—ÅÅ]Vx›$N2m-s`RÊÈÆ@8qq KÉ¿Ëö!ß†âå¸2ÖÃ¬Ü *8‚4ê)F.´ÏP›:ç­Û9r¬‰Oƒt6âo€éBmQLÊ„máâÊm£9M`@mÌ”a?õŒ€ì˜İÚçzX!kk Íà6áòP0;W	kŒ®ïÑÄV¤ÅC;$6ª€#A\K®Ç{”«Ÿ‹¾÷6*0êê5ü¥ÖÊd÷G¥Êº«ÿæ­¤ølh.)YVE„Z‹
˜Ëbt‰Å{Ïpª„Aï²éúùjTî]\R2¯ìò:<°©‘,i»Ô?S˜NasÉ±|1LŒ¶A|ø°™¤¼a»‹7.9@_œË¿;”$]ÂòöTÚæ™úô|ë1¼eªŞÇÌÒ²µù ›Ó|1“ÜÙ¦Ï}e–hÇH’cÃïßŞ.s´Ø`aùÉ 2Réî´ÿOëIªG¾oDEæÙ-9èÃu“¯1uîÉ³HT–ÖY2$d.±)ÿ,P0E‹¦Éş„Ş…êº[bjDÏğaòµÚĞó”¢™„ÏXşOóôˆfOÿÑ (2^JêHÓN¾CÁ¨,I¼äÚÉe$Ks’`_:b¿%F<¦ğ–ÿ’QL_õ K¦ÆCçÆ l¹Ä‚}oÅ#úÂ ¾M.ŠÍpä«YÊ7šôèù'ÆRŸ®¢û¯},¯äê©Ü&SôqXM±>ö‰GL>@?ÌÕÇ<ïo¦ph‹šúKR*á²"0Ô®çÚ$Úğè«N7i-vŠzTs‹Ä%Õ‡ñpûõÂ‡ZƒF½ÍbÔ%ÛSd80Ôœ•àûÅ6ÌUƒ¼õ=…Ìç±bñZeĞİ4ÁÍro–Ú+wîY'İ¡O›ï´1/ş(ªÒbãÄ]$¬ƒåI—r©oyBz•¢-Q¤ÙúQ™FH,h šÃë³A¡n,T- ŒÀÌktïÈ§rLW%ÛUskùèiYò8^ä~ ªü=£óyk”\©œ%.Ÿij-&miáŸ1b_J:ºQ£Mİ‰fÙé&x_ŒoÉvòÆ½:)PŞgÀIoôWVcÜ¦û¸ßï<Ÿ3a†L¬)	DzD©Q@+XÀámXôTº¸R4€¿csµ¤«˜…@1d)¬Ê³ùò­ãKÓò7Ã¤LÇğt†–Ç_ö`ÆøªÌaÌt]şn@ÖWå¼¦èñŠ«GîòH\*r\ÿîè
Iµ‘~ä€ÃÊ¾Më›Í¢Yö®nR 0š‹Ö%²Ybw€n	Ç…¸UWş
ÙÎhä¯ñpYİÃ"±¡dÏÁÑN²¿‘nªkPN7V
»šTîSMY¼ùZ`±¿,Ì
I!MÈ0vxŠ¡/­®àuÎÚq<ê€Û'f¶·ÁÑˆ¦!îõÃQL™€Î©&ªbnÖ”5¢›¬yjh–ğ¥T/·âë0“®Şpv¶ôAòT¸8í.Û#Ñ2ò¨°Å#]eU´>ì AF &#Nœè:¾l,µ—Ç	n*fî~Q³©M_à¨
óˆJ‹ŞQ[òF8ĞÁÍn{¬ºœ.Ë7ìÿ¹O)á°ò «¾6ú=…3ƒ”àJ¤>Mx¶â{¨øfIÉÓH7"ì´QÌÃnVáû@ci$Ş‹"R€Ä-ÉmßO~ˆIÊ¸§XˆÕ]#­kHêÚ²mx ”F¨¥Œ\ÖƒIå˜‚.{Ô9õnUİ¹Ô³Åqá ›ìô²ô.’ç=Pæ
®uHÛ(0½n8MŞÂ-K[MRù¤Y¤÷y5Ø$ï4ùù"úò¡•»ÍÁÓ½û$Ü%â¨‡øÛ±PfØ¸t°ïy·İ¬'­­¹Ô®Õ[[!öØ`ö×ËàÊ2R–_s«Ügz®8³JƒÈ{!;oÔ/ä—W!Yæ&­,Û~3ˆcÕh/ë‚RÛÜ¶¢{úEøŸæÜ>tj9> ·÷ªú´sdW¾¦wáã²ª¸#KêH"fºª`±Ç-9è8o($ûOŞ£kES›EëöC_DøX|:‡8P»7`i*ÚÎä;¡p¾‘İ-C¦‹mfpÆÙ«úĞPx¦úcŠ‘ã¹‘,&¶™Ö+N9>¨=±ıb„ŸlÍŒÄém‘~*Ñ¨f8ÅïÍ­õ¨|)ëMØv1Zf~ÍÍ½õù¹"‹õøñ4S{úÖæŸ0~ãLjI1Ô™—Ãi?©^¸3ËTQõÿ;m¶«CÚM;Ëyßpñjy®”n› £ø²œÔ3îêÓ§-ì“æz[“,ù¯)ûxL¼Øß;—¼O@Şƒ‚`Ÿ"1bAQ€p­N£¥ZºçŠÜ¿Ößd}¯B Ç¾8ei›ƒBIÍéàV25SU êèù´0_­7®#@ËO›Ãˆé™ÎI7
w—~lÕ<ˆ© ~ôJtÅ‰€I5Waœ¸æĞ„Yšç–*ˆÈé”ÿw¹Q½±H¯kr'†n/¿Õ#…Ç+F~>©ÚR†$| ãğù¤»JèÕ	é'c:;WK­€Ûéx‰sh 
-¦åîÏWfoe.&^—2ç\A$BpJKÁC¨¥ú#Ÿ+ufRÕPĞ3ıbo(Ô+|îLQu°	'È¸˜{9$'sãJ‚Q¼Ç§½±æšóı.cZÂq¤¤¼cöLç³Ï'çPCÂ%1ÎhÚL½Døİ·Í‡4ü
}"çı ıaTE„""Ô´è}¤‹¡–Öt‘ô¬6®Åîx”ß•*:2¹îË“_#‹°p<d°4H.lQÄÒïY)‰ĞÃ¦ã¶ÑüU¤Sö'+Š,‹äõNS8µ)ÉÅhšĞ”É×²]ÆƒÁ’}áwåÄ<œ”“j¸5á°Íw›ä?·Õ!®¥B?¹º•øÍ5òrTãQª¢¿û•ƒy	_Pm.Ítÿ¡E¸óC+[µ»Êµˆ„íú©)c$ı“ág¬tt8)IM‡9Œµ|WÙ™â=ºçÂ¨ÊHÏóZ‰‚ÉôÂqL½¹ßËŒ¢²H‰YzŠ`
[$HøİÂàrVnŒ¹ü0Áw!qí\oAğHÏå¡k¦ªƒæı"=±Í÷e^F7'†( Vwä+8Ş#³#íûj”~nÑâğêèxÇ+8ÅğHx-ñÈªeˆHÙ´ñp¥{7”®®WƒzD¸:¼·gÔ·XŒãiw
Ü &†Ñ°ìR„¾ÏIsjµÊyç„İ®™ı[ëBà,.üZ—S.–ØÉS÷£D¥37Äx˜úˆš!–´‘è„¢¶‹ßSéyG\ùKÈ±ì¢¿®4ƒ‡7}ôÑ=ú¾]
sïBB‰q!6³WÇv<?rCWx}r–]ærÖ!Ú%.ÆYE•7È1Ó¨ŒÇÀÅÛ‚Áã™êÂœ†sÊ ïa¡a›;® nàa­Ur"	ñ>uª¬£İt›$´ÿiú9œ	€2ü:v[ªà½ãOYû¤¸ı¤›ãùÙØé	™ÓY@g„c$ŠQ8hQ! ŞtE<7d¢ÓëÚÆÛPB=ä²?;¨İÑ¹r£ƒ÷l®m;1MÀNøCŞ0GYÁ<r×Àç†íª! »¸¾©/¨¶D^P¡"ì(XIã‡0PŞğôGÔ2ëö?“
%ÿ€Èäb¢:Ñ-?Ö*„ôC|I*Õ¼ÿ ìŠ*ûÕv' ùËØ·"vÛk\l #¹›Kµ?Bc¤†ÜuX^øHß«‰ ¤‚Núï5Ö´4ÿŒ±áEDvö”Rx”®êªwàybk÷]½1BçßÈÓ­M¿Š¦uÇTT¡-ë¾ºœt²j`ÊïÒƒTÙy}4 =êĞ·àù•ĞuòÒ%î£ú¡a³rúĞ"²@ÆÍ¤ldQHşX»¾¥¶.LÚlb±£<NdBS&F0²bvi%y‡J"”°ØYE³rßàNûîöCM¸5¡Å)Rzlˆ^ú9C!NÊŸæšº(pN• •rö‰˜/¤£ë|ÅÕm¾§°is¨ïûãù«WMu•f<í’¨t>ı“a‚ßN{ÁïÑÁ_¨ªÚİG7ØÕ3.¯~_…3™%]ÈB½v",yÅ,8±‰Şğô‚‰8Ng†3Õ-@œ¨Šğ­iüå“+"l«İË	®àº?|[l«CNµB?í"£HkÄÄ0€9¸¼o+s’Å¢Vj*ìĞ¦†%CÓz
pßLLn2•iísúÏ7XV’CşR§<…:?Õ0»T
°²€ß•“Z¹ßqîÃ<¿g^xİóÕj‘(ª•Ä´µ””#i-Oê kÚMÃîâÑDŠÕu\SË^°0 ïº/<»|,Å'stíä,8i´W ì¤6G±³JMã;XË£°ğ„K F»°;ğ×ÓÖ„)+òAå{_o¿ß¶ÒÊ­ãM_Ã¨ÕK›Ú²\ß;´ÇoPôD4n6ıeç8SÏÁzÓˆ°…V ({à|QÑ‘@àã‚:RZ-Ì-&ôÔ£`ulä3J.¸¤Œ8·d{Â›·¿¤p?ÕEŸ¬Â%u/–s†§²Xœe~Æs¨íìD!˜‘s~—`í†˜H-'ıƒéù D®ZSØ Zuà¶¦¶´ıE 3 Ên!ˆ%~Ÿ÷ûGÍİè#šÉ8Üª¾ëù-½Ü·í Ct^å<ˆëB&bĞ_oóçkiC>%aj1º%ÏiÄÑ¢bÔb`• ‰‰%eyŸ½’4ÑN?ö±¦©Ñ{Î@?|E*µºyZÜ~BQT³;;İÇºQ¤vƒj4…ç¶VyÇ±ü”4sïÍT¿‘DD?£¸Æ7c>cÂéõŒŸÜ[MA½Q©a@ã2©¨ÀàfDÆtıaX¡[²8th­»(µ«ãºÁVå Õf]•÷ULs 2úç›|l)g¨„óù
›ŸAÊ•çƒD‘o+Ş`£ÂÏrª¥ 2¼Uläs¡d7n^ÄüĞƒõÑ¶¡3‚ºÿ²W~òh¦Xà(¨äÜÜe
¥fQ·`†½ïù×•ÏüfÕ4• j˜ràr‚¼RÔÃœÔú€ã}Øú´O”’­.d é
åò &J 4×œ°ë?
™p!»'•u{éÏbÌçïÍ¨š…tÖŸÕStb²—v°7¾÷f@0t­"KKàêH!"AvJW±?P¿K¯WÍöÇ‰[nC¤J¼l’¿åú¢±e¿eè@‚$õúl)òC!®×êr¾2³D£}6“@‡ÇÒŠx LZC?‘qÁ¯;"g‡©DoÿÓƒMêI¸r(bÙût´XÇÆ
áªJTş°¬íºÛĞ,§¼«}ìÓË5d†z†²Ë²¶€0ü&R£vè˜¢å2kJ¼KşFZ|Uå¤à]ÅÔçà¾è‹K`?APB—u¬t&Gõ§anĞ&ËÚ¼º4^¨}R[ ÆŒgæÕëşx|åü„µyÀÛ¨8ÑFÂ±ŠhWQ?5Š\ğbW `ûz¹®aÈ?¹@µã{|…;ç)äÉ¿Ç¢Q=¶ôÌèú<5ÅR'ÜÛVåe»•a¢ uĞ¨ò™:wĞR¼c°c²5îÿl"·AÔJÑ*‰ğˆ-&Ö?oæÃ ¹{ä=Pç4Fôª23¦"
ï\¾AÂÛº¢ejD7Œ”ÄÅ×	bÀ¹–éÆ®`ªÆ<X[û”+òáÉå«Ôœ~èó¨0`UÍ\û<¼G}/»«2ˆ×äßr°AA¶«ª¶æ”½kü-Eh™n)ª/83ªn­`om$	SìS_F\Lí‰1¡<É‚xjŠ]:òUË¡³÷.”œ«íô[‰o\êcêg$Êë–WYÕpßµû,§·Ew?y«Ä|‘ìD¥ìb\š®…k Ú÷3Å0›@R&¶Ìá‚%*6=è1=Üpi'Ã§êùê‡ )ÆizÍ¢©TIz¦¶Û+¹<ÀvÇì»‘üó&ÑQè;NÈ]I™…Gq=š½ª$ßf"õ±tŒ‹XÅû)o’pÉ``	kŒiğüvúÙ±GÂÔb¹W:ÑJÌ‰_qQH_!ÿ.˜øÀœã¯{-11Ïl1­Ùº¹–n><“_^Ip…gâ'dĞ§ÍN‚‰{åá“ç(ë÷Ç²r*)È½_ÇfÆb£•›<gÚKC˜Œ¾Ëâxqñ >CT…©¹YÖ§àWÛ7ĞÄòÿ£ tç¯c7ÏŞl_FFEV=\ó•ó7Å^ßÈ° (SK
Ë2òÂC`‘Q&¹ˆOl¤¿úuüÖ¼Î-+¤„<r±r-2¯bN¦ØO—‡†Ï(y(#°«É
äµ£¼²æÑ9"#…Á‹ÿ
MµÙLp`Èo¯,åŠ*H{_
×±*SX4P„#HîÙ|)Ğºl2÷ÉY7I¸HxsÄšæ£MuÁáç_M_±¼“Ußif±£u‹¢f¶Æµui™ÈĞ&ŒâÏÊ%™…hh;Weˆ6†ßÓzÅlão÷-›¬Ô­=ÆÁ„ÍöÆ®àğ*qNÓT³(˜LŞ4'ì,Î9à
ï9‡ÿÒZ¿%½d¿ !dÜÕw«ÕkæÄ=AòËØÍ´bÚ£$®ã©Ğèis•QŸ«¾ä½¾I¡±¾ˆÊkY6\İöÿw¯òç'ÉV<Ğ£íª³4ûè„ÂÄ¼ ÂVB…ÖD&2†ûkä¸Ä†ÚQ]Š´„™áê$w×¯ÒÏÈ¨™éZĞp4–İ¥¿CYßÇÇe™ÜÃ)uæFG½<ôO$X*ØÑ -Y·Ö˜FÌY8­3H²÷$ìˆ)¯M«:ÖF4±ÿe3T¢›ÒwìgÇ´%ïê€uFó§…åP'§”A“t°—×\‹–´
Š5Qm@‰d{@Q96K†ZõÙ”—Ş‡FÇIÅw_¸]è¹%jF/\­{	8­Ô(4øö´}Ãj6ve§^º¤ \cËEûó¾’³]<}·+âáÑuÂ¸¡	oÆbf“y&J<aárÕƒÅÛ‰ñõ8nğg‰~C)Ó¹ùÙi­–Ê,a’ÈídÖ'ÿ~ÎÍUi‹Êª|é‡öÃÀ¹Ax}N y)sVôMŞ9É‚6	Ğã	(İdÿ;óYãŞ]3°A |ÁúàP÷5•È*ÊZí/)1QÂıDIŠ\Ù©û-}s«ÍÂåcîé1{ÔŒ…LNL ?{•ïìÕ—Ô·¢F„ÁÌ
áãK	†ß#¨eòj#yÇ÷ê­*Å“ğÎ
=Uı±•O(«Å{îd®ñÎ˜Áû2Q\Z¾³İĞSHwD«¥ö§G÷3¬ì÷ØQW_Šíd)œª@Nµ»¹¬eÊ@q¬ßÇ»~d‚:JÆbÉN	L¯K°šöÎQ§İÖ?5êl¹Ğ–1†ÄÄ,€äÈÑ	É¨¯ÆùCú«jÄµåÚ@Ñäş?b½˜!»Zaİ3oå|V<ÄÍ>t¼ŸéN”ì7jŞÒ®öœ_…C¬BŸ´ãµT¥¯‡p…ã“ì¶ú=ï+º9„ca<ƒ”óè¥n÷q¡b›èÃ±¢V 4š÷öaKÇ·É=©ŒYiÅ\Ö-ğ*˜Yu£ØÖ!a>õ.eÙêx0	A« c§q(~(ùPñt:İÜ>{‹•åE|æf½½eô²ôû“¨¸OPâY‘ÆZ­¸¢À¤r7²µ]ÔV^n¬EåúÉî(˜#
yBß5˜U/]³HYİeaÍ™¦S¹íŠˆU˜Cµ!’eL™©¬½úÎ)N¡³ÛiÕNwÃ¯AR•(9â ´×ÍõzÑe'¬Ë¨¨k– ê-ã#öP.Wıï£*š':ãKÕçÇÿ¼ùı†»'¼ßı¦ íH ;ßkÃUÉY¸Y±%`—æç]ì›LPæh’Ó
ìU¬áƒÜ_%†ßéÏ€½çïD§³kçIàÒšäU„`	ó?Sw¿>¥Ì%øåw¼Aû»ó› ÌÍıœé_ŠÀÜ*ì
P
ÌšûÈ#M=¡¾3KøãÎ–±V\-ª^°ëg,‡”(ù£²}K©>Û‡ŒXÿØß‘%S#P)Zî„Ùİå,ˆ\ê¦ÍA`hôuşØÆ@„šäæwÈ29óz‹&SïİXùÇRåQ§C¢€56Ûºc jèú…
³SÉøä±±_Œ] —õ‘-öÖ¢—¦ÆD¤¤‹£+TWøS»²A(İÈ×êç¸ck„µjÕÒÕu¡³„/âr¯zË®òËs*Öê#K,£¤¤G‹Æ¤Ö÷š=F#@@ê_à ãe9{ÄÿîL€EØÜÍôÔW\2?ã|2›€8üÂmèién)ÍDßÃƒØpÕŒS¿æWìPx¬F†ğŞËs=8ßãÙÿÜ·¤'GÎ­ú:’Z–ÿBA.[]İà¢>lSîg8à±7z8³~ôh¾Åï+q–Û,Ói-óŠñËÛ°{çä;2	%ïê©Ã!¯òÕfu$pq_¯¿G-ŸŠ	»Ò¬éodx#Ãq:{¤õñS»0Wƒ5€1yŸÚ6âËÌg]Å°‹ti·±I~Åªå¤ ?W)bffëŒ72^Ë®Ü› Œ]Ä~‘ÿ´,ñJ´E¥1¹]w+O 0âC!ÖÅ(éyóéWùöä½…Õ®n”Õ÷Çõ:‘Ö:{Ç˜ÓœË8Ç*ÆI¶íÀğø]'ÔnÊ²9@rs^³Nû0‰½coÖXˆYRB¦–Ÿuª &üNmƒV{3‘ÕÈ‘'7ĞR—O¨Õá¿(KôkÌw±&sÜ+M¼F&ù ‘õgœ8jÖR²Â–ÏF{-/ÖnµbUø¦bÛC”…´çÄJm„µÄò"¹ÏÆÉÕsÙ£şxµ_@/ØF¡Ï
İ˜ø1ÏŠºéÜ€9¿ôFhw¼*:èe±C¸Àú@Á•²1CRƒ~[Eğî·4JP÷öV¶è+™Y+¾ ’'ÒM¼%fÍ01wµ¯¯³;çü€D¨ü9šâÜqè_>‚‰F³ÇÒË ¼ÍowÚÛ+[5"#Êù¡>-	-FÜU¤ÛPªÔ&‡j!‘K®u*ç¶3ôL(^¹Ó	ê†Z•ø´öŠÉ·!¸ÒLg“é4ÿ‚ªDâ#Ú¥½áü…{ÉÊ@¾Î“¢mñáËzúĞ–}JÙ‘¹«:€A1vğ|»"çrÀ*qã¹œ8˜	Ûî!’<’›ÆŒåóyW=œ6)E„@Ía´XNâ¿ö¶pTZÊ-Ì¡ÓÃÖÒ+9¼wD•”Vª E³W9qbJ]4/¯óx°ú`hPB|„Á>iÁîÒ'c2w2Â”S)LÒÚ3±f+¤@³—RWVDˆ’DšXW1#fô@êpşŸ^ŞÓjLoï/L*±Òp¹ıš–
 ÔI(„O{û¶\9‰‹§ÖæqÎ¸»ï¦híTI;UƒXmzóÅ ĞáXñc<cVf&¿aË½°Ñ’ËÕ,ÓØ¦ïô¡1ßá ²¹ıäéƒÿø›7
;èoèy˜ªGXœµ³dCçÅlÒ·ëÒ<¤‚ıB¬SàmÍ™ÂªÉJmcêÂ--ä¡8£‡›ä=Ö,àÂáÒëÁÍ:nà†¶øP	!
Põ­Y1V9‡ÙÅLÄc5)ë=¬İ5aJôeA™±¨	\
gƒ³¬÷÷qjJÉ,…v§pç§OiC˜ÛvOî-4>"“¹õ?íOY}O˜şoí“D%æ–û
UšÂÉ*ÃM_—şD}á#0u¦Ê¥‰Á°~±İï}>›É(!5ÿP—úáu	ãR€Ôæà‹Ëóìˆ˜¹Gìücõ
,#êÄ/Úâëcwm*ÆCÚÜ<Ú¶XÓsêZ?4\p4äVX0¯P=çC Q}ßÅçJàÖ¦òï@µà*°XÇP›{Œû/ß,¶ßkEÜór>?°4ÜÌ.*à+Ğ^´Ñä:=Ğ…tİQd·5/lv¿yb½XÇî1ÚJ[‹LŞ?pA–µI‘ÆÃ‚Ü0áÎ†›:ÿg]‚ï«ŠÇØi°2>ÄWøMz½º;21r¹èß$÷Y–~µi0´—Åi=	®å6ƒÕƒ×e-'ÈÙÿš êà•ÑñáRÛ.ˆ*…™ I–bzß”–«†s4sKHPÏ+¤º9eI™«
w¯8FMeï%5§Xú˜Á3•úkR"P¸xÀ8ıœcóª WfE¬ú/öñr±‡ëYôY”¶[W}ÄË¾~†·î£aÿûØ6¹8h™ëM IÇZ‰±¹1¤±–İp–ÉÍw<ú)¨L‚Õî¤à7{¾…ÏÑF¬ií]Š~ö,qA{Rp³éÒŒmäÅ¢2^ÜJóX9)ÉGg‹ ËE[<ª­_«:ÑNVèå'ëïZŠåc§¨ÜşG”7şWÊ¼5°ëk¥Àªb&õ@.+òmà¶½y_¶AxkŞyıëÿaŞš°òÿlo[ÿEn}–&5(Álë(ß"ÊÏ.<mSy¾4—«ÇØÙÌŞş¯SrKÒ~ÒK-:¼Ç¼OG±†jİRí’2“u"éòôŒy Èzú±C¼KŒ†–s‚cô,ÿ¾VYãğ/ìÿ÷ŠTÌ¶*ù§†i—böÍî®F”™âS?*§FY"GÂÃÓæ½èŒ!`é8E{KD¶IØÅ`D÷¶–B‚¹N>[±È£QÅ±QyÙ8Í:…x6`á2Õ8Æ¢yÂì¯?o[ĞtÊx<‰75Bş ø ÌPs­±ko!±²VÒ²”ÀQE™!ÚPı‡ç2Vıˆ¦—†÷%u•YDSŸd@¯şÚîÕ‚Ÿ5WSIêÂ—Šo<”šB"(›kî´Q“Î¯˜‡L›÷mÁA˜B€‚~§•e	¾Éª«­(9­p>Î1~êe'¡úö—Â¢jˆŸ¦oÙ*@;R,îÇäAkf5pÛqÒNa˜ŸF¡Î#nkn	ŒÚ’««U*RÊ‹ø¹×ÏMSÊ>a=HâóÓ7‚õGŠ¥…E¢sU¹Æ–¦$a°¯!úğk\Éi2)î”>	Ë=ñtƒ¤±×zÎ(<sLÏ
9—	_?ÑÆ;B2}‡ÅDÿCÁ¤]á%i`X¥‹skH¹e²Œ­¥)sv«íœ ò_kõù^4§$Z´~wäTnˆYhø¾êáwŸÃÜß±Ñá¦¹#rîÁp!ªoB·†°l‚Å)½öë%ô–µÎCuS>Ç·Õ}ãh“Nq‡T	†A7:L-yØıDR^5Ë½ä=L»DaË‹b†üİ()´ él¨š-¥.\q9NÈe©Î½î_Ïê	ó,K¾¡ªïi%{’e·‡}a\\‘BQ!q‚½KbéÚ“ÖAùÆæ>ZIKnsg“ÏŞDŒcÿv’+0ÁEcçFN=;wN
­“ÔE‚ÄÛ²gäpï®3ì”TNo9şth†|šÛƒ7•HV'ÿTBkˆ;+/‡—s»gC!ÂûQ÷°¼2nıQèrõïß×Ÿ‘”ëà\ywíäxĞfÅÑZ»Pó¾¹.*<`X-eQØtkÄÑÑC_&Õä^¡8Üè>r©Í&h¿ZD¤¾'˜SÇ3B÷=) z"ùF•ª”‰÷#óhàÊñš_G;u¿1¯ÖÆ Jt«ÃƒxQ{R­fEíâ8”µEq2¶!À·Ò÷`52·iŸº¥Ä€ x]ÕŞÂX§hêîÓÆğ¢¨½2µDí|*RrRAıIñ’İ¾/ur±†¥%ä–a3¤+©Js \ìª!Şó+\… -°Iİè§õ‘›SŠ©@Ìˆ0Òv
Œùı¹ô…™‡6îTŸî}íø F†ôdÄ@¹ÿƒÅœf7í,‡èMr{ñä´§†e*ßbípP±)(&Œ z¹5:Æ‘=/t2é†K£‘œ–5Ë1h[ú²˜@¼NDdKÈüšöL¼îø¥O3YÏXöXä¥µ1b®e·G•'­XŒ#gì=ş”Hó0çô˜ú:l19)ÖØfd›¤ïR§N´qiIÓ9^:0Áßıà¿hz¨—<dNü€æ	õ(‚ùO<Z}Àœ¿ÎAˆèzŞÆµ•ƒ8RvI[ÂŒŞ»lŞq…3t®C•]À@“,d*+Ud—«‰í˜Ş°ù—zVğ·È*ö‚!½øSk3Ô · ç ­­DÿshyT1JH½àÓ,‘öAS©ïÎzÜ§xÍÏùQójÖ¾hÅSe K F1Ôš°†h@úFxaå_§P©WrE|Ğî8›ÿ[í7Ù‰lK¢—dŠš>+t
QªˆÃŸáqêÖb”_ªnÖÇÏ‰ÿ3äÀlâ«±ŠûŞØÖóOŒÏÂb˜`iğ–¤Î|ïQC½ZĞOBh’! Uqvı³ßŞ—ª­(D,ãì±æ÷®É•ÖèsjŞPü×µá%R)ˆ\·8½2v)\ê©ì ¦R7[é´N¨h
qŒ…˜kdâŞµ.5ŠMzD1ßĞk yTÕ ø·İ˜Ñ)÷0”'¬#H:#£aJLÙãÍ¨Ùî¤SC
”º›yæ|	ñ`’a'Î¤ÒÑ`4Ü—ÕY[í 'Ê±…„ÉÊ&•Pµ|ıBJX˜Õ”;*WNáp³˜2âÕ<ÁR3Çñ†f×¾’‘ËÑŒks6ÒI4|kÎvèšQX:—†«ãjEŠÖ„oäU¡èÙ½`‚µ7Í@Îdì2^g¸ğ¯5|ûlw
"ò0È}(õM7ÇÜşHãê­
4·Ş¶OšŞ()4§â|	Z †+£é6ˆiÉUCz¡’¢BW?23@„x~ü~×ïÈÊœTé,²·¿Øzkş"Sâğ:À?¦ù(¥MÔ—ÁÆ‚ïåH¬<Ã&*?ÅJÛ›üâ\Tµ"™¶PÍ’J¤ì€t5'Ü%NÒl&¦-`3+aayN&5ÌkŞÊ6je†å#óN¡2(ĞUúü!k+	®m·Ø®+ãñó²„¸³Ó´°_Ë'=\].kr;Øq	2}]ğîÍ¯©¾íæç¹¯ˆQÔã´|‹¿ğµı›&ÒX!ÇÖK8êõdëI@ÅOôr,+ò(‘|ÚwdÃw·˜¨… °—ä{âÆœÔAğğëêDÌ‚ÌNUnlm.úìœ»uZğêdõÑ;$Ã}ÿV‰^ÉNGÇË}-¥ö«œU …
òÕt~XÁïÛpÙh 
Šé¨®lèæl®,b/Âhªy÷^Ğd Ä%“8ÿT­úãDu¸)PW Éì¾~ù¥™LË‹ «Ÿ£[¸c‚’pvöHsøë¯0ƒ•.º%jmšóXn±o­a”SøÇÎ¾Şµ´ÁWÊwGß&øCK|ÎI¦è )¬+íò‚7+2½øÓû9Ü«Wš[ğßŒ¢Øo…¿iR&}[@*_Ë* Âc­só+Øæ}°GÂiwSá~O7Z»,	=†£¼q½¶¡BÙvZ°)zR˜Î±‘ÃXà\ )«Œya’İ”™aìkO:ÙA­^àG$Š´v>¤ë«i0İ@—‚F™s8CÓaãódÀìÍ¿ÊÒR‹ı,Õ _½°‡x¢ú´EÖ¹~§ÔŒ‡•§Ò^3)¹U.,Ô«¦û®Êæ1ZÄ¤êç.Zù¤¾`×er>®…áPœuZÑÍÁJÅ	»¦‘ÛŞîÇpƒ§å5µœ1‹÷¿ì„gQXr.°ª,“óæÁ€H¦ ÒqRÉYÅAkï·a
A"Ö_º©F”“·0EåÍVÁåãŞğsyM6p=~môÅLX£+Em˜Ë÷HÏ±@q ©‚L	Ï£Ä"K•1“ÁÈ¤}iü«DwAjmõ¸²L»\]¶õ¾j²Pg…;ñå›0ó°e2xi#4ê•‰˜ğLjñˆuSIÓÓfªá™|a2/µ4›Ñ9šjRÎX¯¢ª%õ.=dı¼UBkH34mØ½	¡ß½·f~üÉ}/„ÿ%‰w—Ó.ó.Òo£¬ú¼îÄ!Ïã–ü'"Ğ.]Hök´#^
%"òO'»¹*Ú=¥á¡6!)Ï+M%šxˆ1a:Í>Ö ‘q0Aá‚¿M¨‹¶ŞÖ(T©-eÇj_ù/ÖbUG é&Q¦˜÷üºL¬¢åt®êö¢ŞnIƒ•[é<NxÃ¶=–ú÷”%ÖçÃuWF6Bv·!7\ñaªÎ×W|½ˆ–’eïgÌ›Y0™Š`•2CØ^°áÜ´+Î™Y—Š¿­Ç!EËq°,^÷}#b¯ÇaÊˆÃÌ#¶{à’»R‚ë¨ô,ªÚ½Ê¯  qÎbFn¥&ÊÅ½Õî=ğ½@ú{a‹&ªrK^DÛ?ÉŒ(¯…ÂÄT¹zÈ[öKá€îFúˆ0\/»¯`M#°ªô7±Bs±¯R6ûó|)d-”^¿;==J„œ‘Œˆ9œ—4^£oo
èãã9Xf:¤õZË¹(ùV×·Ù>Fª4°nÛı¬%ZBºBºİí÷]º¹·øOŸ½†n3ï•¶ NÔÃê¨Ù~|â»o˜Ê•8‰^wª¬göÙ[~%Pà‹ÊÔÄ–©Ë†ÓP—EğÉt"YöRvnu fç(´ÌYj_Pe3j·]¯s	8.o<£B%Î<kªªÊm‚<=vàèQQ5e®òdifä—FÎuÖÌ´‘Ù“9ı )4o‹q¿²Rõ€;À&]¢{U}p&>Û{€õ’+AİIùäÔ—A¼ZSãİî™…K~Ù@%¼5ú1W2ÿVNF¥×õÙ@ÉzíD#äaJ¾süóWxAeÕ³I8ÍÈD8,É'`HY;“Ì”ä­ÿ5]!™°M? pêĞİà¡Ø}W+,0SîD”»Vc€Rb#0A{&®á˜ºÌSˆ¢£Ö¼ä„~¶s«qöùó10: µKğóÓÏäş³Š%%a`,Ğ4W-DüÅ…ëvó­¨—å
F Á{6ğ õ`¡ØZI‰Tk¡ÏŠ†U\±¯åDåÂVïGÊ?Õ0.$CU»)“·ôz²["³Z¦ŒF‡JM9Ã™_zbwÑ­êŠ”uQ„ĞK~Ø1EUşàÒTŒ²dÕ»$.Ê,¹ş	mı>ZÀ‘ø¢¹å¶=O˜~›D“|B§)C´ò»~#ÿ* i
ñ
æfmOr{ìo÷¡è\FÀc’LÍÆû-Ôv“j2x£PëªÃÖQØyhî€@ªí!Ó<XÄ-˜Âóû–#©„?ÿçGë?F]{‰GÅÈ
w‹êø½ÉŞ|C¸_fÇ”Fû†dJşÌ CÆ‘rµáLwW@n/K€@¨[:¨îÒ\SéNmjº’ëãÕ/,µ¥­ÄÕ5Šód¡lzU{¨œ€-%½Æ’·l|>ºûE§x™w	 ²İYE_Cø£s¥¶'KÈİmÈ3î½™ï¦À;ËÊ_¦R 'ú>Áiµ<ß‰C'ãğ@ğcƒÈHA/~ëM4‡+î5"¨¿LÒFJ‘—„M3…¦²n˜¿o1M5…'•d·şØ¸<TÜ=¯&˜0UYÎ9­¿>ºVl¶svKöpµ©~Ñ™àS…(x¶æÒ2¶¹@®çztÍËÙf28ÿfDU¯S3#¤Æßoã¥¤ô"Ÿƒ	¯Ñ÷Í©×~~ØYÒ§ 'vWÉÃÄè&÷ÙÀC+CÂö3B´>˜‚TZ}yÚÇüß˜[¾Éìûò§î[·¶‡Xl}PÅK7t­QÅŸA«‡‘WM‘ÃmÈ0mÄ¶Ç]¡ædë$Ğş”•,ıœ:q#ü™\ÂùÈé<C·¨ƒc¿rIŠÙ†"Öw&Ü·¥éÉ÷³Kôé?³BƒwOr?Š\í|"š½nš®ƒ—¿g–¿R'üy‡É+åf»¡z;&ID€§ôÈ‘š••æ³k{'µÈ rã¶×S¨ÏÕÄå“6C}Ê'é	Y›AP&1—¨dİª“ê,SÊ5Ï.À”<¤%[§?Äu6Á™rzlµã¯Ûğ‡9±${;?Xá¤^ÇS«èÛf²yyr·béÕ¾ßäztwİô1‘·LôG$(¥.lNqşÆª5½M.¯]„F7`“ÿF V{ëÂOš¾§i¨ÿm#)ââgZ ?·`ˆ$üS‰ô`mƒæ¼ZRøw˜¸øøxE—Ø+7÷SHA÷Ğ=&P”Ó€Î†óÄ.•cÁù}‹`RàCaÄnKp}£m>)ñHOâ 7s¥óØï›É0Y›¨qÊ(–÷,±îª§sSÈë.yæ;gÂÎ´Qb(|&¾1ÖÕO¨C™¬8sÜ…±°¿7ÒX?v¤qıäwr2Š¶›İbi)³U«yÛÕ?|'¿ææ›Ğ.‘˜5.–OİŸ0ê’Cí{ÊÈ/¶·%J7M¸\ß‡8W7âÈJ™òR“éù^ùwfÏ¸Ù:æö54Är®R†«Tº#dÈ¼8d%î,+â:ğ€ Â¾ü6ÎÀ^6¦‘4úw Ò,Í$Ò¸"Aù=aXºõµ\ÈäM¦ÌÃ÷#·íş@n/xH‚\uX›u/ˆCí÷ĞMCp¯Ór6çÙ¹°ŞS{—[Hÿ1ŒÌÊB ò¶ñ˜Ç+ù-½¹*Å‹»ÇïB®mº+ƒ¢Ìİ”•–CàÏ1·ŒûaZº¯_·üšoÔR~ˆh­¯jµw÷å‰9B~åĞ–¶ì8üt¢ûóéD—§ÊªôÜÓòóm®x	Ì".“o6‰4·k+Ø
6ªYŠƒŞ¤ª	Ê${š*˜]Î¥ïv!q·LBígŞ˜3¾£Và`‚Gü«æFjÈÇìg[]EØ`â«Y95c¤¥ı(s½·%%üÕ8Î7¶@úÔ áõ7²I¯x/eC.9±ÀãnÓl˜W)çz] \ÿ±Š7`&:>‹Fÿ@^8~rö8,*| YÃ˜B°ù‘b[ÂfO¹Á|ÄÎ-cšÀpÓ4nfâêah§´³;‡ÉN6ï‡ã¶)Oxö¾±º<Âè_õKOFÍejb‘’–×Ğ)Ï‚7)D°ğN¿âœh85	÷™_&…`È êßĞê<Äë¶7ävJÖø¥•Ò	+•wAâjœFë NyÅiÓìOˆGõˆ°ÉÎà×¨ÿöWc¿¼ë´Ô‰ß:ÙårµE(ñŸ´ËtêhA0B!C6´Ææf¢1C_è¿3¥Å×-Êh00ÆŒ¹(R8Õ_VÜ¾ˆ‚vp-H`‡”Şcm²ŸŞh¯›t”³)­Q ˜B‘¶›²xúû÷£¤àÒ—WLu²¿ûiV.í×,Ò¦÷@+/Æòr¿˜l©>»~í.‘+ŠCè4Á)1hõQ£BşİdÀAfkëÅLtï˜sŸâ*è›òO°=ƒ},ï6!>®˜Œê‚ŸP5 Æ#SFµ`ëúxYGTÆ|+òğd½EêV’Äá£Çùâ«€˜
¢TÆk@Ç,²\c`Zª,ñ³—y	í©Z€21šè_¤YµLÒƒoºD6ø5KäÒk«1Şrš$à1ÛUC0Jñ?àÜ6´¶3l§ËÓ³zŸF]««ıM0ó¤j	»Æûí’¾úğˆ[œT ]’iqAïÎy"*œ9™¡ 'Pœç™L¨æ¡w	5Æ‡<¾÷İV¶ÀŞhğ0;òòÛ	sÎåıf¾ı³N©˜¡óJ
éä48@càwP&ùÕFP¡\_rs%»H²öZ‹z†+~P9,Û$¶™M¥)•q¸/‹ãé™{;uTª¶¦DxÊğÚ$Gúcğ¡Àÿ»*~&wËD¬M[™…Åğ$A—%Æjä‰e/ó}ìÏ ¨äğoò-Q¨l¨¯czN!Õœ .!§	k®+ºfñÀ$ØçH|!ÄoŒz?T¢«“¼ú¡T´3ò ›õhƒ-Lß½2°şê0Íñ\Û\Kâï–µ®B5f=¤^ÊïWÇ:ÚÉAIéát*Çñ·™æôÄyBIlÙßçÅ¥=falYÆÓÕ „$É?j”#z°vûŞûÿb~Œ9û¬E¨||=Ô0Mä¿Ñ2—°›7Ë	“­§ åc ·pë·&bõ?Wl4WcÆ‰xOiš,)ú­éË2L[AŠl?³ö¹,Sew4QÕIzÒ‚Õo˜ù³.ß´)ÔMÓùûğEv>ëTÁÅøf,(;*3¨»¢ Œr¥«¢ÄLX²‰NÃæôsö"`´dG;\¦yco[¥îöµ)€‡‚Kº¼æß—aÇj€B[O…ƒö›´G\«HCÅ}%Y	ö
ëÉSİ¥˜g¹Ç‡Õö9‰ùykmØofû'Iö_ÒS)‰c_¬eõš‰/v7}ˆ¨†ÊÛGw˜…kNX™˜¹zÑ}(F«5pÜDÿÑÇCö-:÷äj’ƒ]Š&_lR@¥­ÀbxĞ£fÄ+‘â|1Ù?+n˜·Ÿkµ|ô°õdv‰ñ·DãPŸ²©Ù‰ø‘Â­e÷lçÆ­å·XWş’A}tB7ÜÌÕTJVJÕòÖ?!›	ºœ‹÷‚üI
í:š~F¡ Ÿ”pÑ\ËffPÁéVæi$gªI¹hÛ‡U¹mÿ\ğøçïá|Ñ­~Lÿç?Z{–›Ñç­Q›Í±ê‹]Y	…’QŞ©l j£«>ATM7¡c½§@9ÜŠ'öøW´`£ñÈ
ñŒĞ22Æ=œÕ'¦¨e ‚†°“ïo÷y‰¸óĞe™ü\°ûT'/Æ<şİ­&ü*LšÖô‚c:ı]Ş³|M1Lò~£gtøƒË;ÚE3©WIâ‡Ä27f‰$\€'İà_7[l(n”ğìOK¨™¨ñq±Ä€	5 Ìõ¾¶â‘96“Ùã‘mÊë]¦D\
l}¨Q.¬û,é!¸ÃñQ3OuÃ—iİf 0)¸j}û×ánÀü%wthG„˜ş8yG/[ m¿M½ü¼¬£H`¬Î‘°«˜O&•’0#šp~ÅJİLNêş¥îUƒ
µü}.Ü­8’æC‡üD`y}[8V›T5ùğôBì)‰c!éÔÛë€]l¨Ê-äÄLx¹À>|ä•æ}ºÖì¥ûî
m>(®ú!ş¶m®w2¸=°ÇØ%á#ÔÂ­½e˜	7°·¢[$ì³%!”¬$’ 2€Æ’dCÈ,tÃ|—œ½³nÿ{—|[ÿ1C}Jürê³X'ˆÆ¹2)ß§ã éM&Æ9Zi…YÅèŞÌ¥ [s4‡‘ çRBÒ‘îtä)z#&¢TNËuÂ-QÑúT¶¥¶Gv»™îĞuüœş/¸ß$×Şâğm7:4cJÒdC˜V‚²ùéxP.3Šá†òÂ& ØTçkÍ¾m6Ò™=Å t×|™l13¡}ğŠ ÈöN?%Á„òA§À–Ñä±E1ÙöqJ£oS]ß|r1ù˜©’Â}, …?ºuõ"İNR´&•¸Wönvœ¹Ãâ8»ê}.ï’³J€-}Ÿ÷ZjW>]Óè{è•7™Ø^hm¡Ì.÷Lc"èLŒ(ÃN"B°Üém€•>ZğÚvÉ|TñaşŸÔHÓÆË§M?¯&Ò¡}€èŸpd“|@•óæxa…·
´v{iä5éêQÉ §g'Vò°kCÒÕ'Û¾-J %Õk§¥¨^Ì•TÂĞ®-üÕ‰pup¸ûÊÙâ<xYGí¦^dhVÉĞdbßjå ‰§ñ®ÄÁ@TĞŞXv¸”…‰ï8×U!ï¿fVâ®,+ ğrØÔ‚\H
UJºÕÕ®Eúûôı!§üëz&ô/Ñ4ò„?ÅO­äAğV7èFNÆPPå‰Š%/Û!Î'ßÇ¬ I°ÇgÔÜ¼÷ÇÉ|éó
æ/¼Šh¨|K,¤fÖ¥ıV;ÙY“Œ±#ÿáz±»—9İ¯ƒ ÄÃ’tj¨ŞÁıÌº(!´Hª •Ó¼íœ…H«R8nƒI³x–×T‡ ±ĞÔG"klqÙyŞù3C¯Teûnÿ[¡A¥‘«7QèI€N	ÕöÖP¿»1ŠÒõGG¯¦K‡ŠÑ<V8¿)àûV‰$j	”,ûX™'†‰v£\’¡ò©¹Û¸³'cÌyƒjîM8¯WÌs@ÕôÆ°O½YTNb†aÄsæqV–Ä.#Q¶ÌV‘¹}ËQ»¨Ñx£éÅ”Lõüş‚[?á5oÁhÂ×nÃ¸³‡ZG”âæºZµHé•z¬ğÉ^0í­¬nkRÈ6
"‘C%˜Ò¿¹n=êBù3•«yè¼k0ÖcH˜ûõ£N>0,-­FùVOt£$<úó0,ûà©ĞŒÅ‰‰U"cÍ¿òê›€°%dü¡L#EÌ´·À­¦d“•.¸…0zEµ±‰É˜¿È¾‘”#AF§ëÎÚ}‘9/NB£…SG-I‡0Î¹€À«ÕQA3©¬<åÖŞ$Ûï‹à`	Íû]¯eĞ‡v *qjÌhâÉ6ó"ôèù€ÜB€	‚°ë¡6	Î°Àş^DêV¼UA·ø¿¹NíªÉ;©š‡¨ıî¡Ø~Eÿõ=İÂ06ÖÌb÷¢h ğ½ı±XISş5tº\‹Q¡s+yOrÕËz\6PG¾WkšÕ„ª0ûj‡?8Q6“}¡\ÃD´®¡øşãˆ›<h~ÿÒ:»1uçXy[!ªô¾–8°—p÷¨˜ßÄ§Ãñ@ÜiÅúBÓRÕ9x®?r«M¶FXCHá]Ö¹ÜZ>Éıyb¾¤e¯á<‰±——‚½„Ğ™¤«ˆVØP	PÎÉr«ÉßeöïìĞö©iA¢ãD¼W.PnşÊ%È°È4]Z—MôúCÖ2Î'ÿCM¶äNüV+)ĞÙƒ˜¼ïL\ş?^A°ôíø}ŸIÇMFÉd«)‚Ô…~»¡ásë%à‹Ócæ£yB”ïÊ‹ó{Ò(+¢e[ö9£Ôoİ|\À*’Ûş”V3N˜\KãÒIæ¬P–íã0
–‰ÑßwÚĞ;f«Ø~CóıqG¹­š‡¯¦ğ'½·ÑÂ€ÌÜÖÆ€ÿüò4,ıj—é^5˜bÙ„o^ä@ëznû»Œí™@ıS?;Éš³6‚`™¥¿¦N‘¤Â “Álß£^)Ï©Jj÷ãõœÛ¦Wƒ!]å?Ë/§Jêå¤•,?óğ%ğÿ*…è'Ä`F7ƒÉ@€ˆG?âŒ~7á^ _íPÕ‰Ğ}áŸì,@•ÿĞÜUXx'4ÛeÎÿ¸5™ûm3Uï¤Y%v–s£Ìçø…`ŞlØ)­ØñÉ *9&ËŒEDßô¾Ól­UŠ¿åºieé;ğ>ôjqóKk@½RKåâV¼8×è5"‚~,ináÏªË›Â±j§åeKó:×	|ÒDN<'%¨Êg—“lCsüÒÜÏûãİÏj_ëèK;©óÓŞ¶ÙÖ³Œ­rîañÌÖÄ„DüİÃ$–Wì5ôÛ¬Àİ×±Œü¸ÀË–sç*@Ílåí¬6Ñ"5.vÉ`ÖC8FyåC…4—È_øRÔ/YåÂâ¶>¦³ÔZ^ü_iª¡5L@\ı”nWµÈ¼s­\ğ¿!Á´J0q¥nåø=àC‰;ûÛv—†vfC~@Kz±nöq¨É=z)DÛoåöP9~Ğ·ªT1È¤ä‹Ù‘AŞáçñS}<ù®)ÏÙI}yñ	 Sátƒ½Ncs®Ëƒş’èùİ	ç7v·È}Î—éÌ6Äà6ó”»ùOErÀ˜Ç‡†ñ®Æèøƒ–¨~ÔÃŠ ğ2•¾ÇÙNA[[F.yH7‡ÜÒä²ÄYµÒØ‡`û¤Ú¬Ò¢eI¡¯)ÀşÂ3?BÖ\²›wñˆLŠ#£&•ù–†ó²Í["¤çÊ®sÄã¬‹ å~:ÎÙt½¹L¢„´útô­	7úèÁ£WñkŸ> ²©aÔĞÈôÎ«u¶D„P\äÂérÇ$›a¿­`÷•ó™{š¬fóÑòe/¾#~^–&Xºv§´ï·5ÇÕ…ø  ÙëºJ:!ïc¯%õjwñÈBõQ?e¼8ö ÁE6+\à˜dKs.»NJ_a®øèd2\ê½±U*°ŒÆ”_DTÆ8@çB£EÓDÖ™0»u>öÇü	¶^Ã¬6Ï¯u¬±ŒÖâa«Äìí;¡RÖ÷ÔÌLHİ€8~Ş«ÛıyúC²ÎÕ-i¤û×©Ëƒ“@b°€)Çjì>ó~^V±‡ÕIa9ç<+B\±®‚t2ZôJ°s@™J8,¦yå.‹nz»oHç³¦é¸¼rB¾÷ğÙú$*Nßùğ6gÓ]H“èPì´4²¨2ˆ^)‘@-I
¯Dó¹
P!M ï°¢bg^(vÆU!ÙTcÙì !ñdåOú¹XÇñgœ÷	6G#©Ò¢’ÅWÅKK1ˆ]$W…¹‰ «”M”ŠYwà®Xh–4^ …G1eüH)¸/9<¸1m < ¼>Œvù)mÖúæûŞÛI ÷¸lÄ[Ø«aš±ïY–l?ƒ”Õ—eï¿ÍñÒÚğ‚ÙÙus0ióó;5ÿh<µ²Â§ˆ” Å¶ˆ»êĞŒ®öÑi¦c–ò’-_gÅ±\·nØoãµƒaà–j
ä–mût¦}.I{ÆR#7dzY”Vx`€s\Rs¡Më«˜KgY ÜìüÚİhLñ­Æ­Èëê¥‹C.*4ƒ³fß)3áeü+ãªñZ?aûÍİˆUç-½Ä-ØxE4/J£ùg2¤`ïhÒ”Ìp“ùèƒÂ“Ğº¸h3øHJÊÍC±°ïór„ådàëlXÖys¬~¼‡”ß>î.ú y¢·¿ş§j€O–w‘Ş?ç?¥‰U¯š«„¼&kS±z“¯pĞ+D®“¿P/	×—HLY$_½Æ“³p}“ŸÁT½WÑÔr0—Ë–y’ §÷U›ÙX>·“©â
g‡Ôi­¡ƒ“¼ªØC;«âˆ{S÷æ[‹‘ªşéuŠÏØ.Rá2•»E˜ñ£8ØAeµIˆBÍ¨İ¦nzÈ{×yØÉAv@xÑíŒI¤/h?9á—e^¢3Åk¬©f’¥ÊÿGŞOd.è4 ‰«šá±@æ×-nd·a ˆòÙş¿¥oTíÖ¶:Ò‰ó:§ßI0Ù»Puè®wuĞ8-¿ffÒÂì-+›©ÛN4zjW@HıŠr"ª!.M(§2â¡tXîµÂ£™~Ùùvó$ÚûàIò<…hGé”}ÜQÈ"væag³°[·6Û›OŒ™•L+ñÏÙJsEL3Ö1„²éŸú+‹,J7‚x¿Û©§à>+HùÚ%E‹ƒÆ}>ÇqvıªW²»‚XpÌqÅ@<˜h^	8ù$°ìNá}aÍ¢D.œ{4”Õ “2ø33®ò`›µÚo‚rºşÊ+&ÎÂµ-mgú]‚$¯jäF´?(l€±8‰ĞèŸ Ü>Ì3x¿¡ÀÍv°÷DÏ»f'ÚúCFR¾Ñ¹wÂÂô?Ç­Pà%j=z
ï{ş@aú[x|-X ”(¦!–ñ8Sí2€õ­›R\Ñ&GsS¼ /ltc¶TÑUN)Š¯%²›8å€Úa@³TáÏÌ÷Æ4ïO[»Zˆû›zÊ•Æ5Y9ŸÎh¼g«Ãa—ÔÈÄæj_Å
Ë[­bjğOİZ›•;“)ÇèÂÀU·,×8ûï{^éãù¶ÇSx[­^­…Y_Ñ‰Äæs_W¨X€†O­Nyó$ôLb Îpáª#—Ö'_çÑSfã“(ğø.Óªêåhsß½Ê×:1¯-m;'°rY{v«Ø±®¦Ê!ñõzlb¬Ñ(¡OEc„˜?Ô)µìn©cB9?JÍwS}í²îˆ±:ØËKŸ:	2W	{cÆ—®İ`E•q!æ˜õ}ÈŠ=ë³i=´çaÅ0İ‡S„:XnÛ«lAŸÌXO¡	e÷ÄÉe‡Ç(Àqùô	™„QåmLNì<}µ)şé:¢J@ö=¿?ñTN…t~¤Æ'=òG\ÜÀ/­I¥)n¢‘(‡mAÄ¬iÃ”^RÓHQÁåz–óCüïŒ@³ôÏj…ÑŠÓö3áô5~ıMĞûÉ(¯¾;Ş
¼ëì„údeQ-
ptÄXŠö€ŞohRã×$2Bç*S©‘ mV´z[H3ÓİÓÅTy’ÔAšÎ¹ÿÆãgrîº ‚,»'óÑ7ëëšùÎä2cï28KPK°úó ïTş
#Ò¦hklt]ÅämˆHó.>±¿D5¾ñœÈ«m9,Ã´ÌŞ¿«¤ª1¦ñ­;?óümìÿå·#+\´Û­Ô£†ğÔg¥mİ5)UCÚ(ÂŸì‹Èî{h}¬¤áí¯ıe‘”|‰®”çWùÕœv¨mµ÷Ç•S±‹ñ˜ÜÅdïü"Ì¨9ƒUP´cœé¹<VÿL;9fÀÈĞ#¡¬åWÛS´×S]uğ¸fhQS¦Ï¯‘I{\o«w2mz&3Çnh¥ŒU MO ®ò2gJÙc…oS©ßv@0s¡TMó{Ÿ]ÄŞÍÔï£›q”B¼P2›İhÊöá§œc¥°:gœˆÁDŞÿª®i0p³¤
°ÌJ-À³94£°Ìág
ï…”ˆ Á;’€ÊÍ¼±ú|%…fû6ğiX•½›ğ®Zv¥à¯C¾â{äqGOqX™r÷•Ä÷zğÌTÅhZ4d©’üh®5a•ì3U ç^)……Øû]£‡TAGÒ?S»†ûDPfq‹úd+UDv”Ìà¬=€d’w,pÅ0±ûzÍÄ›Çx4ã!ã¨ö~d÷älr¼4LBÄN‹#âãí|ÿş¤4ìı5!xGg´]„Ú!u¨Q“ìa€Ğ§¥¤K¤\ïo‹å@ú¶3áOt[U>–!QõÔhİC¶³vÇ$N·Y¶ãÄ ŸLXÓ·Jª¨|0Ñ«õO–°œz-=”¯ìâX{ôO]ôwƒãcKa[ÚwÆRüª¿ùmşYZËqI%£Zâh÷x? ¦‡‘-âHÃ1ú¶@°»e+b.'8ùZ’òùÑ4JÿA€.XG%ÃÎ"X‰®şò!óÛ3írÍœæŠQœªµ©0“.Ç95=py†™éh
²gS¨Ø;æéö	ù)}2÷¨D>N""!lØû„Iı¯v(öà§•î¿ßI¼)Še´æı'†u_ğ ¯O~†(ÑN6Ğ2 CšjûŞt.®îôxWÎdbLÑND_çwÄ/€	é¦(2ÁŠú>ÿ*<án¶·”³æÄœÕm5º!Ã÷=}´æºwüur¹‰tÚm´9–93|¦~á–/_Âï³„p0Dƒ”9;—NbQLqì­‘~[ _EM˜Ã¢"¯%‹Ø²t)å–4à£(Ç%0ÍqB#÷BPî!«ë‰Àv}Ö>¦:–[ˆ’VŞ!-æÏSµŸC¤ï¹Tk5¦ƒ×ŠßÜlv.uÎÔ;ÖüŠ>Å;´|TÓ–ŞÚ°­˜à¾7.¤Ş·¹%•üü²Yñ,ŠÍšè`Œ˜úâÔôUÜá&ÿn}¬³ïßÓ–ôOôTî‘áN¢9Nu)¥¡Ìøİn4låe£Ed³oVÈÄÑ|BæV6®ÎÙ½{ßš¶éz Õ&XÚhXsn |oª„é¸ÚT½"PnÅ¯èX¨ıcş+06b°r.£¿À²ê!+c)ºüê1°”nËÀl*):vb>8Ãò|‡eJé,ËÆ9)¡@ÄçÊ~&Iü"+ı/Ëµ!1iÕ ´[½köĞâ™Ø©Ááİ#õh¦×.MÉ9 BÓ<Ø€#O¯Lo=’	-4ñ¥h=–Ø¼+S§ØC?;¬?Ñò´±XWòŸ:†ıtLY‰û?bŸ‹>şŸœyóg¿º^¼N©ú“a]®J¼¡pÎxÓƒ|*æy‹[¨ÏÍˆbP’±—yÎÙJı;ÿÊ³ëÈCŠvÑcçcQ2‡Ê+ÇpåĞÌî·íqw Òıå•`ÀFWOğ0Kuµ
V}@Ú#!ü¬2:Éç €Û¡]ÿŠÊöp£\ˆáÆ˜Ôùf<ƒ
§¶ø>²¥|DØBT0oá.“Ùô	Şıõè	KÙŸİ§Jš
%Á[tÉc„i]m†zÒˆEÌ…Õ¼ˆwf­^—Ş4 ¾«ÏœÌ¨ÈR_s}„©[Ò=#øy¢/“„‰“Òœ*Ãü
[nGšqA•ïƒ#$'Ô´Xf#HR?î¬"Ÿƒüä0¾C¦>¸Ÿ«çu¨ cö` "v}wùv Ù~‹~ÖÍ‹5¬Nû%g¿<nÎ şÿÛ3cë~”ĞĞşˆ;_è8-®8vrñ^¬g¿¶SŸûª5JPá Vş,©±-º]´Ñ’šu|÷ÄZƒR!å¿˜Äİ`<äd7Gt&4á¡e"2<v§È×ÀÂÌŞ²ÕCË@“~Ô¬Â’/0Õ»îä£ÔÜ	ç1B÷ƒ°+Ş{‡µ†A£¯"íq‹‡áÔ›òMıå«…éé1‘0p­Ú¶¿Óâ·ç	XnX ÑúêSü)b5™r9¹ù—AV·*Ãÿ¾×D7ÙÍ/¼Vù•ÈßGVR~ ê¾_‚¨¤«^œ;2ø«:qn±Û'Î€qV³Sš8o/+İÕBZ}¸ódOVBuhYL›Ë© _ÈR¹:ºÁ`v]Í`¾|sÄúÀŞêÎ‚ ò@+9~og¦¾ìg²œ½›o¿Çt'úQÆc EôZRAiİ*q¢ã¦Zoü^iÔ!ËÀ¡OÑ."ª‡¢™Kz÷¾1#¦h×h™È—¡3I]¢¿-e$4ÑSS6àª'Wî <Hi¾ªpbö3\zƒ×Ä#ÛAŸ'Ã§Àiò¤7øÍ84…«[T›Gíß#EÜÊ­qÓà~3ş*•çé™á¼Úcw“JgåBá¥)šàãµÃoyä Jë¤hØ’x¶W  ¶$±Üö›¡ ¨¸€Àƒ:º±Ägû    YZ