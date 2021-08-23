#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="569504363"
MD5="41b32bfbb35d352f24a0ab9a10439492"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23616"
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
	echo Date of packaging: Mon Aug 23 15:07:12 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ[ş] ¼}•À1Dd]‡Á›PætİD÷\ŸƒwX¯ÙE\—g%9X{¼,.ïPüåêR±0[Ë%äFùd†èÓ‰7meÁ¿.Õ:&¹¡×çšHDŠbD"¶â…°[7–õ]ŠÜà‹ö#³Âô'»AÊF^W7M©šUˆ5Æ¦k¯O]lNlåÓ,9·2|(â{²kœî;U4|Ñh\‡©÷`(¥cºv^‹ÌÎŒİccñ69ğÙxê Èµ–z"ãĞèãˆÎÒ°ËöàNcD5ù@½¾Y$¾äœx¸Û"ÛØû^ú=ÂSTõô	XŒP›\¢û@â¡IÓ¨]ğD¿J¬ó1¿Rß `NB¦©]Ÿ÷yNş!Ôówgb.­§j;P35Ti¸bå6ZØœ­êİ	“j®}q‹±µ†jÑ0·µãbì6~ßĞ>Y©áÃ²Å@º-_–ÖDÛ”Í•=Ë å+çêñSjÜ"²¬¿ùÏµ~ˆm·€¿Â²5ìÌÔ­Ö6Æ¶?‡(äRÌEe2Ë'ºÎ°Ï6ˆ½CJw¦Ò{cıã¤e¬X8ù³³e%õŠ›‹XŒPd·ß~Âc™î„ÛĞ¤¶Åâ4.äÍéö4ç½ú»œrìîbš399çR©Q FAÎ5ÊjÄ]ëô``¶+=Pï4uğ’Ç7j©©\O$ï1Ü}õäŸ¥m­ê¢l¿±¯ù”Tƒş@cò0š 6¶5¯lÖ´5…\Z<rÒaGÀ–|§Wøy¬aíq­zMgoÖG*ØØ€é4ÀxĞªı¶Z8ÚbùY`¸^¤éâ‡‘”Š&©XÙ-EyÅ]\ÄÅæ£°Øp/×ß½bÁ­öíÏ6&Tã·ç¸n<Ğ
×îçÉC(H±í~f|¯_’åh‡†ƒÌÉõ?ÑŒNÜÁÂš3<h†z­õ~|[±¼K$ë_’¿şBª§àpÀ*ä5"Í¥w4c‚ÄŠó«5ÃDÏçş	±Äe
sìj
«ĞÉ°Ôİ­Tõàm &._¸îÏ5c`k(á„ÃÓfÒ,ßÔï—JÎºº0»®Êğa$çmP²„¤6­”ò†h*2Y[YâÚò÷›;«ı¦y75Ğœ`ß²×!dzÙÆ+¹•‚ˆ$šV¬¤`/K“É e2{‰Óøÿx5&»ëØa}`…@ŒIoh¬ Æb¦Ãs>CÅswkÎîDÌ‰.¼ta6GÎ»‡dBQe–íõ5=é+òŞŞå›²L&\È‡ö!}€;Xc­İ¿‚¹ÒÌùp¸oòÎ2ÒÈ“H5;Õ±|îÍÊâ´±ú•¢ÌWniMÏ§XìE–‰ò±L¢JH/í¶*C+çU©w~Ìuhù•EÀ­Âx4Ù{Ü
°çh6"&ÿhz|/y2şÇö XÃ¨åûE<´óÖ¯~óç,7ÆßÈ~ÔÕì9½õZ´ÿ)–ç³¬chÜİ[Š,w>ŠØZİ»˜,“ĞcÉ“â·=ÂŒšĞ —À Œ,ã>]£ÌÖ0ÜÑÓf[Ë{ÇñØÑ§:¸-u?†/Nªœë]±.x˜2)‹Œ.9±pûpÙ—Á€¨Lt[ÙıüñëU¤;íÁèÜ~Z0jæî°œjû«/rş:ï;%zséÊšöo-×*ßtr‡¯eU[H,§áÃÍ"¥ÂZ†åêàLO;u T$¾b×sÏ—¾ÌØªõ{íãÊçÃË™>S¥%„&éÑ¶ËõÏXäÄ@§‹ĞÙVöZù ÈzE”{¹ë—íÔ‚!xúsYYÀóÉv )¤Y)‡<cÕ[&—·1nœ¦šsp‡Ë¾ı¥Ú¶¨%­¦ÂEoªîı¡©¦± fcL‚!ábèOXWO”uHŞ]K"Ø—ì/Î~ê#¹0µ¬lµäµÅÆ|ü‹(·Ó].0¬£ÑAõ¬9åy»ÙFï™íÉöïßº`£|U¥ÌÇ5Ïuîødó¾?õ)3'M|>ë†*|„F$„“¡K¹‹ôÖÿÑ™d/doÉ#aºÄ›º¯öäwµrÔné#RvÏ0ÎŞN›×Îàäl'\–È²w_ş \Âğíø&ícÈº4Îmä{»6g]šeÔ»u»ÂÛ,1 bÚICdX\—8ïÊ¶wÕÊH>9ş¹iÓ,M1éŒDø7,Ü²×ª•Ot¥Šö÷š¢À²Ğ©8Ö™eº_í×C¥‚Ë1€¿±ß~Y˜ô_²<gybA£s++Ów¬èÿe:ÿoQ±ÛzÏO±FM¼‹LmÍFû<Xo40Îª¼ï?üµNÑã¥ÅYÑbÌk\ÔUÍ¶şS¿Ié33zNïøÍHuóGè¼Da;0 IE=ÄïÉ3o×v€6MãÃ{ñQh*±½ˆëÆ±ıZèo%ëdqgÖSà$Ä•†  ªx«$Û‡ı_|(öŒÇ½øŒJé0Ëµ!¬^'¢˜s„¾âİe8Ï
8×{õM†Õ8‚T6İe…N‹?‚—}İqœ™QñQ‹±MLU8O‹é(ŠçB"®e©Å¼Há«9ü¶ÍËJ»F£0º­È#I›†È'ÅâôWôD2N¥ÈúØº¥ÃL±}ò:à°`ám!şkò€ÌˆİãiqiW,•LôÓBÆwZÙ÷«
'ğñq‚·QJ‹qñ#±‹¨šØùGíÅœÏÄœ2CemÌŒ™›ÜÑR£ò·4puƒñjÓ4¸4æ,ñ9¼¿ImôBR}È9›¿6-ÆŞu}V­IÅUîe”8« CceVM({ûéİ›"qq`L‰"¦M„ é³ğRüL«şò.q¢PYØáğkÔ"·
)ÿ¿YP&É§L»ÍÚYò-HşMùKkLÌÈÉ†sÏ0İyxI••-+u†-‹ìˆ±¤Ú)m°‰Ÿ t¼økâOD%ÃŞÁ¨+UzÄh0¥/‹*ªPgÑEô€mÊåìï‰iœ Á+r°„JìMİ€ÇÕÎae”ñE•ŠÁ©2¢¾Ræ4Àº¨Hu5i
YÜ8Çû £ó,°Ë
epõ9Q+~)	—5¬v”V’0ó¢7¤S-`ÌR¥âØŠŸ<™äuvCæVĞ×6_5¼©hAÕoút¤Í»¨ÒH¹OåPÁ‘æ…¯Ä?­nÛ‘LJŸ¥^¡Âr¢ê„ZÏå™A¾Ö™¿JÉï
Ö+zš"·T~ØÇ©kh×n¬l
ÒŞÇ\Œ%ªH,~Æ‘%‰"Ué&ŠŒ˜ç6%³¤°Ø¡Ôº¾ˆ÷|f=/ÎKÜeoë‘ÂSFóôÍ)	zÓüÓ¶éQVëäy&_ëü~¸ w±æÜ½Hó{6y•t‘ÆÜ|¤Œ¨BÇœøÙ ©Ämú£ùVÛ4(*#3í6Ù3‰şs1½W'—;=`¢ÒÕKiÌÂ˜ã<—Şf)À¿u.Ô>LJ¶R°1Iõ…ôÛ”¡*X_f‚€VT·äÄûõ/ğëAo½i¶é|Õüo©œÁcw·yÂg,îXÅÇÔ‘bØ¶‡tôP×13Éœ pOY9É|¯o§˜êØ^ráÈë”º]âgJ8«—½š6Û¬tµÿ` gf;á!G¢ı±Ãñêl²ı},’»@Rú;$hc·WWkÅMë›b³>séTâ*ám^HÏ	C‘T)l +?ÆLÿÓ¸‡£Sÿ©oYANë>:Rk}€x¥ğšZ¼·;‹<ÿ˜=wrñP©[FÏ´\+&ã¤.¦œ›jz“²|î¸7™ÛÈö.áé°ŞğÓZ­röˆVu±‹”ğ±êh¦ÆrÎíYŞlUşËk4j.,Ì5g#üÎíÌÕ›DvyáÎ‹=!t2û_µ†õş=ŞÛ¢3¼Bó¡l€OüÍn%e“‹û`4yÚ=¦Šu…šÀU317?ªÔ>ñ{Ä)ı7YÕ&Á¤bmıØà7\÷	QÔ?ùHùš8ãLàÆV³JFjS–79¶!ÌÏt<‘SÔÒc½£çØ·|*,_‘› ²œ>Ù)-1}ô°.÷*†5©õëÈŸ°yòI‘©ç„Õü×]Š2~O´Ûñ‚5ãÅé§´	WZ²åtzFR¥™Ì@M]¤8ûpÀa5ÀO¼`'x¯Zğ™Ñê )>A†FÉ‹HNóäZÕaê4×òxHÁq~ÛkÉ­Š €®í=SöL&æêU)¹"´¯¡n}·°(¹8V’;ÏÇ›^ò¤8Ÿ	U‚Õìº»uQFx©S†‰saq™¦ÈŠÛ&æ¦+KıapĞ‘Å£a5Moée€øzîQFœÖ™ÏV;·Ú}“l)Pö}KAiî4nX 0ešBÂ`šµ´ÁVù ~¦!À¿;<3„ˆìãW{ğLdtú°¸'Ê”ûtH`ŠBŸñ[î¼¶0Å)¸ˆ+ˆRâc'³boW+Z†Õqü‰Ñ¤¶åùsúåd=ÁLHÅšè%ò¦HŠğZØÊSˆò(!3YŒ_úÌÃ¤… ™²—§z¢©›ev'mÓø_é/F8ŞŠ_ı™áâ³¦ô·Û°@™‰Â1H&¹O}©kˆ_Ù¾r-Äß)9ÇPıZ©«!T€"Z±H .."!j©“w¼)Û…Ì4Œd"Õš©TH~"«·ƒÎŸˆª¡ZxîuÆëI¥^¯½ßÏ—ò¥êNr12äÂ…H™öÑ›¶q½ƒ\ïª!&ÖËæ6K1ëxHj;WóëÅjìWàÖ~{¦¯	T£ëeG§çr¢ku«Ó•HŸ×(W‡Ş‚²Iç³‹¬ˆñB@çpZ°µ{ı{énÍë¶gâ# _ª›ºH_2÷¹ûÌQbîì÷Éêr3ÉOxúªã,a6hN O:„‚¼ÁğyB(ÇP¶K@ÖTŞ~m Îâ‡‹ØL)„¶&qµGÕ²—BÈ/ŞGİİå[…o 0|Ö3{¤Î‚Uí!½í.İkpLµ#½²-×m¨˜ñ±Kş€-¼¼•üâˆB	ÉĞŒ*Â«—à 
Z|»e~ ÖÆ¦Å1$µ>ƒç*%ÌçÍâéÓ-—–ÊÛ%‘xYe‰@¥ZÄà­ú²‚²X^h{iëğ\c`·ş/=M#ô^ÔÆr¦P‡ûìMI½ìf«luû,šÉÃPÆa7R¶¶ØıÇañ‚!üdy¸Ùlª÷¸÷,µˆ&=ìPˆ6­Ìş?b»MYµr8£‹@8ïx°„vXT ¢››q³ÂuD"£şôİŸ	2H˜›u’N‰|„Q/ÛŸôNıîUÌ¬.k\ÖW,±àùŠ…eŒúšZ¯=íg[°ˆ•X%ã#[[ZÎ”fHûS^¢rvT:Ğ ¶¶{nP¾ÃcˆMbtx $‹ELC½È”G¶)³åÍlq2¨ç/Ñ±ú3›~õ/¤.AÊ7²`rÎÜŠ×MÒa ëŠÿDæ)/ËÅQUQ% MÙ§«t(­êù0ZAØã1„å}¡ÇxšOKUçM²üÍÕ¤øy+bœï~W¯¹è{+jŞµ‰âä.¶qªy=ÏbN…4éªÕ'VNáU* àCÇïCîgmÅsš±Ş­§$ğùÄºz‘.BGO›§ûÉ&Å™·ÆsTÍ¡FÇ‰déßÿ1#;ôhJ‚$âĞÅ™n½öÈrÌû1ƒAG3Š[c‚ùWâÚû€ßñMª2eŒV2&,^ilˆ8’…Êğ¾B1°hÇ]Ÿÿl>©Æ©HáDªóÿÒ/v¢I¹k%wI(º×-Ş9¼ÔÓë.Ë @Œ³p,äxs§-E>-İh#Êi8éÊeµ|Ğˆîó åâƒ}Ó²tQÜíá ¹ò9Ê±À‚ôñLdTw)æ†ß‘çñ•.í@‹×‘ïFTáï¥¯‹§<Û03â½¯8y½Øªò³ùÃÅÖqÕ·jbqø~¢‚îÀ_Ã”ú`tQâæît©€ùEê«i¾í9SÚ"ÂÑC-D.m˜((Z4G·5ÔPÙT(éIæRLOÃê[…işf2àf“yKùtb½éºğù«»´QiğQµc‰µ¼CA±ß÷ÖU¡¹—ÄH—%8£'æß8D™‹¶B—‚ì_ºeØi» =ì;ŸLeNË9ó *İûçÃ¢7fÂsp'bÁév-N‚JÇÍ¢©nÌ\Cï»émQS-Mûù "ÀgƒØo •.¸,Ôï¯¤2W}¾¡SYÊ-=£ÏaùëÂ¶,ƒû•ò•ÄjÓ¤=à`Èz¿6b‡î3à+`Ã¬äcN’hŞnÊ	M%}¸[|æ1õÑ;P?z•C!gƒgŠA6`yµ
B#i~9ef‚3ËA«Kù¡âêtqÖ³¥¹CBŸ&|š+»À"«‡w8ÏËôLå)PÆ÷ué@4Pğüúrû˜ìßËs¾úë2ôTid¬I¼}/`0ídLŸnDË7ğ§{ÿ—ï•×Óf•9#cXß“X„˜GÔ5HE&2¥¾r¹q¬[v8ríŸ)ò”G¦€Ëwè¦˜kBC½[ÿÙ#Ë'Ù÷ˆ²'šÍÈÔÍ˜—#<\ Ë\hâ&©:¦”¾ÉWì°Â¡DO]ö<0ïÈI€;4ã}ºÈ\Âìé©ë`	àîSÏ9¢ÅêEÎ^¸ˆggEŞ8©÷¨³~¨x¦İRÇcµp'Ú6Ö§Q*ØOÜ|ÀÔp\t†Ò?¦…²ÚrY4[¨cÖWC»)hß@ÎS(Ñˆıôì°È2Æî| §Z$Ğwh\xïL¯FÌm!.¶nÎ,ô&¡AÙ. §SsJ96¯ë=¹ü2öF„h’Zú¤é¡¶å×Ö’Ô“*l”®=ÅİüÒÎÿêñÊï|0£Ğâûşy`ºBBóÖH.aíR¶àÄ")¼2Ïåsî
zb==ü=érİ1†VŞ I(6º]Í¸Ë5JGxÿø={÷™SIEÓ&€´,qjŒsÙÈ3ã´RÑqÅä‰úó„.†wÚèÜÎAúaÍ‹
„¾Ë†±m\P$Ç-ôŸÌF˜&›û<hfD¿8¸eĞOPQ¥>-«·EºÅ½iç_îÀş£áÙ)fqg-†ƒÈĞÒÛÎ–×G ã'kØ–ïiCÕp/tôb}2õ¦taÂ
´·éÊ‡³7¶ìe§gj­¥ôz‡!—³úÃÁ‚•'! möV*RÇ'‘áÈE0ZÔ±UÌ™æpâN"Ä¢4“{úĞ^Œ:øQà´°øà—´„
?Ô`‚ŸkWÔŒ}ƒé|“¯wqs8Ì~¥ÂvA¹6´t~®j¹åR¦ş .< ¦OZuRoüFÅ-—±°Šà5-¥­4‡I~„¦(;¹ûCàDæÂ\	ƒ–‰ rºîªc{©œj’t³= £FEFL(¼ĞW?B»¹E\Ò/´K®—¦ïD«X ?A
4©6¥¸öŞ¨]£Oñ²zŠÚh·iğÏŒ”~F§ÊQÙW—àº‘¶h5Ø:\UÓ†5ö²–k0†n‘°ÛşfåÃ@îÀËÄ å#™‰³Ú0ÚÂüíÎç[gßÃDß…~Ì}" 4?lÊ—<‹ëoP$‘Ü}–@ã Ô
Ó:0/©6™AI.û¯R\ÓH¬¡vïdƒÇbƒMö1É-lˆ•,\ŒN½‚5G]™á:.DbØw¹> r”Xëïò§Q)>Çãg#ºÃiÛ4	
1SöÑv»ŒQ!“¬üeê€cL½µ–•iü¦áû<BZ£IØ«N”Ğ«QE¥Ÿl¾b.Ü¶ïRŠ»lrü°z=iÑŒS”p]s¹ó.Ÿf¯ğemoå¤·G¥WÎ¬+Y­ûş˜ã Ú9¸œŒ¾ˆ5+¦·q•—èÅr×RÉb<»4P¶ÚüRØU(-h¸ÎĞÎŸw£º³ùPÊæluzÔØ>-AğÍz-w&8¦à\mù+­?ÎkL.è¡l<¬¿³Â~}İœ*ÆUÅíacy¡àÿè¡yAbÁ”“ÌÍ•ÙU©7Õ‘­v4P>CÏM&""+;ëúÖLGš2Ùó—A×‰–^¾¥•¡’¤K®â'˜4â–l®K<ô“ )h¹±Áı¼ÔÑ66+şyOÒ	ô~×Kw8›ÚÇ_İXyĞwkí¨ÈŞv5$0–ÔY4^vÏEª­×2Ïe½wFĞõèk¬Yhc#òhw9ÕñÇÎVW\Â¨S…7.³	ÿv=ùV~Çêˆ¶†­A'…‡qt°W@½×n7áÆópPu„D •—¦‡Èè
41ÆşïQ «
©Sİ
);NmO«f(ŒÜ)	·Ò¡EX‘grVàF~9…’ÆÔYëùÕ…–V&ü”­~ŸÏ[:c«ˆ—I#sÖT%M‰ÊùiJ~âpÇ;^ÛÍ©YÒÀx÷Yw&Õ–¯×¡£"ÊT£ÚæÍrÍñ"õ`f œ2©—Ş<é
QG–0íçêEP"|ïæwÒ"ä;ZÙc1×ä¤›3•lÑTÍ"s-¦çòç•ğ® Ù0D'$aˆñ–ƒÇBë‰4‘9+©‡ÎPjŸ¥E6ANÔÈ§÷!ö*\"Oúo›^“Ğ¢ºş%œ#6FSãvÊW4õıJÍá•àuvIVÊ©
¬‹&tLìˆ6¿L8B^Œ‹K‹f—Ë[ày	Ò39Lª¥Šüwâ~„­®½ 0Ñá ûS“s›?æ™©÷ä®4ÚÑáÄe @PP)z4Ú¿ú ¥ZĞò‰&@>2k~s­r>C;Ç§Í2¾Ü%eçó5¶Ñ¾Ü<_EˆŸE¡R °·õûä§çi“"œ•LÑÏùvÏ/ıåûøe¢2Mï»ƒlŸíèş~>lÔ6*ÊbÖÊÒ×&–*é³£ w©ìšx¡'ÂvÈäPló`âĞ-YA]y:ğs³Éç4üËt&ûµú2ÙÈ/¤7\¿CnÀØ²uïPÛCOÁiÖÂstRìåâ¦‚?¹°Š]Öpkæ Ò^‹vSóNÀ"÷¿–à?aüsõÊdY’*2gE©™ÊgÑ2ë­0‹)°ÏOZa	UıE{¢¢F1(´Èn£‘÷Ó²‘Â·[E+C–ÊÏ)Eõ“òÛ†ÿûÉÄwxUŸÍé¨+Ş5µ¤U˜õ3ééthm]Í—­<Ô‰u+|~-->ÕK¿¿çò À¢dèlQÄ)›œ¼Øq?¨yR6 y(RJ©ŠN{:&£À/éàĞ¨+ÅL(ÅÓq®jü­…¸.ÿNºÖpà1&®¢m>¸%¥"—–‡˜ '6¹ú	DYûv8ïøï*õ{_7øKƒ±§Øé«I¶ÈŒ üà]Òk¨CÓ,ŒgëÌ:Hş•ªl¹>'Ì©š1 `”üQ4ñ*õíçDHî©Í²£p0B0iúwŞBT®Bz˜‡Á7 u|…|@‚³“EXè	P5ÉJ¤ú‘ÔİÙì=»IÚK¨ßAx˜ƒ÷–.ºÕÎšgÛ±‹Q¥ñ~5÷¼½¢ˆi75—fD “`MöøU5a Î´„Gz­ n£Ù~æ!ä@j'ÓÁÙ“2W5l;r<5GüÇmÓ²kö‚%0Ğ"?xˆ{è>8›"=”y¼q‚mb¢¨×Éá}—ö!¿Ëàt¡A#jD	ì¥·G ÿ-¸ağw%˜ñnõÍ4IÒ8(4u„Üy}£ùñéM³ˆôÜ:æDÑ]İr4è Ãí„¢ˆmˆ›pJ“ß©²4 tÿãî÷DN¦>|z kOYêBcÃŞDh[óóqó0db\a!´üó.V–X_1Ïõu9|J?­Ó²,¦äÕ¢K©}P³oóòÚpíLù`SíÓz>±\t;èu™´î·Õ™³ä~ÿ«Ø8˜O ›õ<éáô5Ejú²'Ÿá¤iãç5´Ó*Û„Ğö´Ö#YY%ysÈüâŸ¾ˆà¦ãïírâĞŞ!¢ÈUX>ŒÈAÆ3Ÿy¢x‹ÒÎÜåvØÓİ½jU¹ ŞSÖ@©æp%bè9&¥BĞÚ½Ûs¯è›+Soéîvˆ~Äf°J_S]eîm8|;,‘˜‰®jØ¬s"óCºµ+R |K ÔûšŒakP`TÂYîìVoÜ‚ïÍ«9S·âƒ#Ta‘ø–ı÷hlp”Ä{EÜL…Bğ©¢§×¢Q—˜\a‚ÒOÖ‚>‡ùÕø†¶5Ïİ?‹ˆâN<K“'R’íJ;şL*Op>›bnëcÉ,|@Ö‰;³«Ülœ1w‚4n3j·a:ÕÌ(%N™bR›ÎçàËßÀ¡U‚–šç­µßgèâpÛËE"e“Ê8ıS›­"ôá˜ÿÜÑ>L.Zöùîÿbvù¯?p’Æ(îÃ>ÅM^]cB“‰Bj·•xÜOéì¡h®o:'ÁÃP½ã¦ouÿvL =…AˆkcEú:@$UA­Ûœ8ÁÜ˜¾+ÌÜûgˆ}ë0 q ”8ğdòídå»û÷İGã„ÿÉÔN3p ‚„¢ÑF);GbÚ@'Fh‰æ¥ÅòP²)'Ú*ïş"€íÄ]rÂãàX/Jk>Dˆ¹e£lÎ|QŸò‡˜Jâ+Z»ygÌrh“ŒáCà¦aY&›7Ô‘ŸWB@JR¡äKş6«l‘eÕ>õq%:Ì®jq“s±£«€%L%äÖã©4ï`i„A?öÂ)¢„şş)I?Ur|®ÆwX8!&U[P0•HëC8xÖ*H‘"§o²Éœ&'	ÄçÕ.Lšşğ¼ãñ>-Şás$¤M9¨Wò#)eyàÙ¿sÀMvï°JªûühÒæOZYîk5:¾6ÆVÂ'Û¥{Q“ÅqŠjj]ü~ 1Äií–¤‚ª¡¨}jJúAú¾5‚ª
N[@¥QÅÄbfFË¼""êÄìkV”¥ÈŸhÓÙ€ìL±æ×Cxf×‡ô_½e9“·KÎ&ÈŒ3Ñ‡ÌLÑ#âÑñvÆ²ŸØĞª®wâ®Çm°¡ÒûÌ'3˜Ï	¿º´Ê´2İø¥µaæ÷Í‚µiˆ÷cevÉÈ*<8Â]zÔü4AÏgğ’—[§·ÆÅƒkel~q-,Dæn/±€î,©â–ª¦üM+¥yQÓ…‘ºR¹$ë«Z¦~÷ºîyd³ƒ8µÇ6½#ÊÌÙSTKCì§B¡yÍ•ªœÜÄ%SÁUSïåu±7ğÒ^µ0§f,H%45‰6©ç†Ÿ£´í°a	+:¬ûgá80ÇµË•_ö+½ÏËsä˜Š]}}4U¦lÛ&SE—"V"sK·°ëXTªüJ‹G,¸*ğ®Şfj	d¸¢/k†Ğ>\u\j©JS…Gù?İU ~ö,¯â_—¤¬ OJ\/XĞgk»ğ> ëÛ`5ÿÒÖÕ—A Œıœ•ú˜Ü•huÁ
İ©^€ƒNy…V8Lª8Uåò ¶şEªÏ /zãœú*&°}¬™³ÈÒ
³TŞğsomÄó³­ênaı^½GÑ£–€v^áj"Ué9×9En%xE³Rö3¡T†)õÿë©Ãüæ/ë= zÑM+_Êò,ç·%$ºê˜ñızÙ¶fßİ1)ŠmbÂÍ’RT½ô fê@>Ş[œˆb7w)uô—Y‡”¡¦‰n¼æß7òqÖ­½oLÅfÃ"îÚe¥ã§ÏZr¹HT”àæ/§ËP²¡óö?y,ÉŠş'ƒÒ“e#¡Ş¢4UN¡?”)”WsÖF£¨Ö3$=ääMáå»íêcçÉã‹€qmÅ¸Fy.nš¾eäBµmñwåpjC^óo)»‡­»q®Ã”åŸAÒn‘±ç¸«y€/+}F„t…éKJúº¹\Ú£+?Á—1¯‚ËÂ¿z¾|±ôMÿ­Ë—'šÎ®éÛ×dô“10‡ÖÅ:uä©BÊ}ş±g]‡T"‹Ã÷ğç Ü;ß5k¦e‘òèˆÈ‡Át_šíãj2Y½ƒ£RÈµí‚[*
t»ø)ºRôd}&%
áSx/)R3Ü!BÌd`:=ô`òÆ›.û¶nç]"Q…ñ£‰¹ëâíÿÌéË4hLñ/âVÿÅ›’£Rº uÌĞ;,Z¸·vÜ¡fQšp_^9¡Â•»Oß_?³4‹ÒEÿâM;%~ü0¢óy:3whæÃÔM®ÊÍXîr¥—C„éà¶GİdÖüf™`ĞıÅºA®·I¤®hœç-øÄlTæ!%¿_àÈ®üÄ%ÔÈ?öóêèrJR`¼Wë<ƒU«'¿$KÜ³Tıeˆ‚gtÿ +1fdÒÛ–bÅYĞç—6Û´ÜÆ\ÂbåihıîÖ&¸÷3'“ğ
ŸÅiCŠJŞß2eØñ@+ÒğH‡Êdc$5\h‰!Ú@†ÊL¼Íõ,è­õj­g•¡<…Rãù”–ãgè˜™jõGã=Â‚R1aº¦#ëm¸Ş´xTİïµpÄPa…}áÖšåË1H+‘ûı½·âB…zçc]eÇ!iÂ¸
]ş~ùášìæChrÒ}RhC`§i}'eÉå»Å+Yµ|‡¦í^»¬KËíú¼´Uî¼HE/†[¾şx+ËR”µEèšGFc¥á¡g©´ûc`P‰A½ä1_@İÙrÍÖ(Úó%Ì_ÓãC¶Má¶š,¿W…pç:„3D¶j2ƒ«/¦gç	x3Z+%“Æ°İé£p¼¤uo.â
`€	a·»u;$ŸÓRg`·.Îk_p§^Îh²¼¨§‡ù×ˆdŞH‰/¾Øü6ˆ[Ü0DAY¹ã“"‰gÀGì ê»ßÈÓ)ÕQ{=”Æ¥Tìvúç{dæ–@œL#ñ©P«„
_ãKĞİ@ÓÔŸhP»şrêèï²D9b’£ Ü&sè8Ê Çé:wdå~TNĞ¯ñp 20è*Ü-”54%êROUq2KD.$6.j,J¡NCŸ*ÿ]†5¥(#Æyğ‰û3·j¹-ø¸®:ÆßZšOùåäĞ¼Û$á?ÃKIÁİ«›æÕ [õÙÒä‚ä“¢ê§6èUç94[”âv¹X¡øÎº5vë’Üs¶Æm>œ²!;4aÅh’#>y‰1E­	¾Â¿mÖÁ¾²µp ¾‰ìĞÕÓ¹qı;şÚ'r%ÁÎ7ÿ‹ULø”·XõW(iıêrl°£â=3Ù<³=’NEÂtô eÌ`?@ào¶pß<*¹èìyLşL>ù@x	GjtŸhÔÕ)q)q
<Ù¥ ;Ö³"(}ŸB”yo`%9L}™¡¸±‹S™
]ñL…°kØ†‰—t‹·4ãq„¨•Ó›mènÄ¹ü@¿smTx
Ï0tèåb÷é„^†¹ß8ûiâ]P‰Ú#nqm#.z4ëÊİ‡!÷ÅéÔ,Æê´Ÿ¤’×htB)°ğÓ"@Í„“_a‰üdøX ¯¬îÙ4ÌPWÀs‰lâO1ˆ)uEXî¨}qÒ‘r€ú9Š·ó÷™]—ô.˜?•Œ2Ø,Lÿˆ²¡uµCjßr¦Ï?Ú
°5UM‡„Ü.<Ü-$™¶$¼['ulr[[¡¶hŸŒL´È%Ÿâ9OG Ô§OÍ‰b¹¥‡Zàèú‹ï:¹Ï˜“9=”@½3’lœ2…DBô­4Ÿb>\@yp‡ÿ§	lÍ£ì)iò’îã¸TŸ°¯ı¸‹İºXÇnË$;Šg"•ŸOYèÚMG”.7ª <æøö– =İe‰=xJ‚<£Öà.NaÃ¤p8CºFg°ÆF[Ôğ¤{ş•e$~”÷Qí²ÎÎı3,Õp°"6 ¾™zö[£%Á;ãĞÑø~ófwÕLnqÀ;ÿİ›!åÔòNì´‘}ZˆEÑ—$‰Ô&áÇl›SMg_Îµu‡9ïÚ4G¹£º÷äjqd€™ÉôNÆşÂwÌºäİÚqáùU±ë™ÙjÑéÅzE¤ Wh¬|+¼b¹Ü×rŒ/£6–9­¥Ğ™ß”2ú >&°¶bšÄ9~q˜éÇiùé8ŠU»÷iõ»®Ö.Ãr'©µüÄ0üócáÔ¥´`Võ1ÒÙ˜NƒzAí‚E?É•e3u¢üá€Æ•Ö1 ôsc ^,•å³ë¼ôRî¨ª&ä4í4™ù–ØxÜ·Ú¦µÁé¡Ó2szrçg—£F`›P»
Jû|” Œy¹À­ V€¨XdKÉÚUHCâXşÇ"x˜Uh£ÄmégEŠêûTÎN¸¦íû±.VÓ­ÊJ ¥#ÃA5æb°à?a=ÕØdrYZU«ÑO”FÙ;ıta@Œ]ƒÔn úúÃ€ŞÌ$9Ã9ƒë¿wï¤0Ø²èû"”°Rç®øğ3›ÊMÁDªXäf›hƒ_‚ÇJS%´8kk÷3sø,zCTIöv•%‘³|+<„º>°×/MÀ^4Gãã#EsÀîxQÂfírºmÀ%g½¾×†]^`0ùŞWô·ŠFQ|Ñ³Ew%nW¤ÎÌ×.R3¿ê_›éíyñ£p}€—J{&}Ëh²ıÿ³Ó¨ß=¹
"Pû²5»+Ø	‹î7Rsm#«IìŠ®hMmığ/Ú2´x3´€¶I`ûê@OJ»R’)í†¯d>ç+œ|Y@|¾¢µ(A*ËsË¬ö¶¢Üøí³Ä¿şòcQ&LØf²ƒ’ä¼›¦fX»w%-‹OE9Y"YQùqaØjCZØ/{¬ëşQN{Õ¡ 0YØ3İKCñËqƒ°š\dOã­êXŠû@šëFv/šäæ~*>@‘”-MccÊcoV÷%A D¬…1µÕ!iC«¾”‹z›¯ÙV›@5ŠBt£6šÿÙ>¡JÃ€£K$V+g…,Ø‰¼t&$„6hq>İ#¢X „Ñ¢Dµ ÊñÕºã†¡%YÎWár	µTÛeÑj7ª"»nf±
•„¨%`5$],Î(†~iÚ{.$àÊÑ.c¸Ğ^9!Ç.‚´”üH{Çê"ğæeªê$1' #– 7M²î‰Ü‘Êê¸‘İBüüèè:ÆæbJá1èÇÌ]©dëhÖéÒT'ŞƒÃŒ"½Ñ1<ˆ¯¡°Ñ©#µ2!¸‘Ìò„4ªÙôL’Ô]‰ÓñİÏQß/&/jÙCbĞ^ è'ÆPy_½yàU-bn½/YÚ“¬å—¾;Kî¦Fã$Ü«
gcÏ?w€şÕãÊ?†˜!^$ÏQË™œ(åšœ0ŠLtN¯´{6¸ó¹EÎ'~s?»ù+!‰ë5êèİ©À
.­XÑÇ±åÑÙ(K›6U×.ş›¸¡wJDlå³æs*8àßoy¾ƒ°n‡i	Z?/(¥ƒ!ï8˜lBó„ñö¢D¹_Şúœ•b…¹qÔùëQ2·‚€{	¿!Ğ:Qaíœw—ôıê—)ììGxªš§rV[XòúöÔQ¼:2Êf*¡éÊƒ‹(°uĞnÉ)®Íä`·»Õ>rç€O^ˆf‘æ\bêÔjÁìr:xQ*·Âû_Îˆõ#*Å:¦Šx‰Û€€U¼G~(ÍôÏšäuxeD5@…eWõóI†GPZ–ˆb\çÁç0òê ÎŠgLiÑcR§Îí‰Ö·UYı5­4•	ÿT1Î.C,¦Qi4‘UÑÕîq é4o°ù‹I·È·h=Â0ô$¶íüÈ1¬Í3ÏÖ¶r½ÍLŸo²V ø:1t£Ík{Lv:òã¦+V‰ç×§.¨ÖnÒˆn3aÕFT™9$Z4!w9â6¸íÁŠXó<ºàM¥„¹|„Ê/şHmvaÌ±²1±MÂ&„«7²
KçFÆ‰A‹„‚jøÇI“Â•@º,C|!·z•€?šNh—´Æ³é19Îæ‡èiÄ]–më=Ê¡@­¢!&ş¶tL§ÉĞòş$ÍGßƒĞXòW°U*"a¢¡íKlÑxõ 5@	($\«/Õ&Ÿ’0 Æ—ñ›i±D ±óOº½Æ”( <fXõÒ<;¸ºÇ-j­«ğW¼˜êmRa’¶†ç´WeÉÑ\b+Á)©öµ,.¶›>ÂRŠ?Sèhüb½?éva!vh%8¢+'WLWt:Ì„P’®VÂNSğsè`Í¼Õñ6,CúÑBªÁ£Jš\AÓüiVl@ãæı:ƒùŠ¦e]rö³IÌ)C±ÓÃÅl	PUŸ2Ñë8X—£²Æyí½f®²?™D1÷Ë²_ªÖ¼%Æu2ûv“@k„É‰Ğ=—îf¢î0øiÓÆ÷ÓÄ}')`wpçßhi)óQ²äL?k&š¸µs$.š3Õ…†Õ,@]TÄ»zE×=İzÕ3¤2­ºä—˜8‘Ÿó÷Á¿y6R¡]ÈZy›ìùNìÀÎ9n©ú2ªAqø8ôA4ğ™¦Ê¤ŸÚ:Óç…³ªâK@\võh­ıÉM°Ÿ¬ù;˜3(¿ —)™QÍ']Õ»N7!4áºTüO¬­ÿ•ŞÂJB}à]ÎÅâŸ$‰{lô3¢Ûã?u£OÌ7²ú†ÀÎnSd¾Ã {ó9ÄEµ÷×ù	 W«¬ù
•2sób:n­-)Ç^wµdóNkAr~RFõƒ‹«N¼<J‚ö¸Fô</;‡éap !o¾øğ"ÂMÙ¦z5Ç¶b
’QŞQr²ô5õy|e›¶ÓøŞ:ñòî€?½yŞYìUU›öñİ©;¼iÅyoA²¾#¯c{9¬·²çOÉqa¯ŒŞ«L;>}±˜°f%ß½è.xt­¡°¥ëhûiãKğó‡Áø¼$úvÌÀîv°.¾ĞkôB½Çü[Ÿ®KöÒ\Co	HkÉmú_0ğëÉĞŸN}.ífq‰dâ§ÍÛEª>¢¯O* q iMºuûÀ—ƒ*Ó}Aj%±t“Èk¢:«F-ÜÄˆu–”\šYFoxA=vÖ)Ú©‰0Y½–Áˆİàª1.Uácx3ñİNÙ@é„CHsÙŠœ›ş">´ÂÉ™÷E$Ô§ÊbIé'€¡Ğ¼ztV‚WïÍ·ºJ úáQqŒêjan9²ö]‘ucğÍ³%ÿ•]~mŠj¤{¿êı^¬yDû:ù7„ó/ÁyÛ½VÙÕŠËôb[ İE÷Œ£¹Hú# ¦á¿»çÑS|¸Râ©wæŠ¾ü¬¶šbM`Q†öà¦E]Ö¯Š˜üL•×í;+ÎlÚÅ` ¤xw«×Ñ"Â²„hG[ØÒ8#Ë?io¹aìz™Ì;@¿Êl#©Êô?b¢´´tL1]„¿ÒİàÊë¡aÂXù0m\ï¼W¢¤¶;ÍA4*VhaíHúöuK+üò.£¨¨:#œ©·Á£7»J‰w·«0%åÀwõ6>ÇW°ŞÔPÈşŞ“#Ã„Æ º·¹˜E?¢×®†›<Âê±Ø…Q¯zÎŞˆY-•7õ-nÌU}ÅŸ«>ñì ·õò½A‘ü<l¦pÿ‰:1NÅ>`v¡tÃ"¨µw‰\¶épˆ‡+T,¤° µ(ÿ±vÑÑ2_£5~‹<È¸ÖˆìÄ„ûò BK¡Y3«$¯™R›_ğqŒÎnšêïìª7e}Eé£8’_²0û»¢çzÃå¶RÙ%œ}.MŒ'«vêÑ´–É=a_Ë!öG|
•….Å<.¦ò½ÚÂĞ9¾İ¥4¤ØYK•Š7’Àd ßwY[‚˜AÈ¿BzM0¥‘è}><ÊÃJ8YR)Ø0Fñ¤®'8’¡g?SfÄ„ hŠn5BV{¿£uıÇätÁb±§<)­j©Bv=¯S»0@i^¸·çb+²»POlcjq¤xÆÍ¹YMáÛwşÈ Æsã#¶“®.èk¢Z*9ÄŞç}­x±}İ²¸.³8«OİyĞ|Cº»7ğ‘ëb¥—OÍv}ä*äi÷{+œAI	K]0µä Ò­·¤Â†V=yOmš·ƒ‹qìÄK'd—âY
†â™-¾³ÌôöYë€œ»Ò÷òO†Àç/“j¥S¾h‡ì+ó&p*u¬.Ê3MlST†ôf6…2¥š¢Këg(Lœ0Á† W&ciQâ…ÔÁÑui%áQ\yÉÑQş]@ã°<öŞ°pËu÷ñ~×€%¿0ÙR»ã*HuâğÄıºì½M ¤‚lgQ+êôZ8£ Ûzå$|ÚDÇ«w<»l: LøsD¡…¬4mÛ:È™éWÓw/ÃZHAzm“ËLu4pÊ¯ŠQù’ ²IUº€ë34û‡ê5”ğ`œñCÂ…ÕëEÒãi…48JºõV‡UÁ<`Ş¼;ŠJNv[3OúÕî¥ØÍ_Çh/xv3Ù	mÕ^g¡¦×#Ôš)b(Z(N£ömŞZ(jï¼ºöJ…XO‹Å‚„j<ëgt2ï¹8¦M€|ôÍ·O	6$†YI+#&RÓ€¸î Tí¬qP<¥óÃˆ'ü¥óaÕŒmÈ«½¿éå—4i¡ÂÏÚ¯q_;y/jìšog#z%í³(V™¨bXÉöó]ú++BsAé´*8n2úH-üê~éÈ"GWB†[€CvˆöGÿÉLƒ¯ïs…˜MàæÑÈÒ¦{¿ ÍñºÒ½éÛJÅšƒìç'Ì"Ru‚ïÛ‡âAòˆkÀÖòÔgäæŸ=nª˜‘üĞN\8h–ÓõâX±Ğ‘â!ó:A~â|òòè«äÛe5f<nºk¥:5Rí_9$İä»#sTQ-Wv§•Pm±1i@]u1ª=•ÀĞÊ¦,ÈäoBQÛ×}ùºœµ.Kd¨ıŠ‘Ÿ¸Ä‹TU·ñ6<;iÌ[Güb„dÏtjj?èŒeƒÊ76»ši=‰¾ÆA*šötÆÙ,k©d(Œş.UµŸÁ‘A+éœ ²ÇpÔN]`ì ±´´­Ï6|„£m¥­AÓ¶±oîmÃªä0ĞÓ#FúÚh=Õí×|4Ş•Ù›ÕÍV¸†&åc)´è3ø‚mGİGcô;Vt~Ã*µn-ñìš±‘št£úÍŸìßu¶.<sñÓk×Ög¢ØD&©ÅĞ‘> L9ñC¿0'‘¹ş³¡ÅË5³Ï¯,[I¯L&]×`ú’
}ğïx½ãı_Â{Îã1|ï‡5£<XD*¦ fN¬››jirµ
­õ¬[ìöXëH|œÃ½Á1J¹îDïÀâzëõ Yõ=-õBš+cÛnµ€1«ÀH°FG“JsWrÃ¢Qìvc Y¢±‹ŞHsÑï¦sCWVg\Ïn§;•`…^(9×‰úm“%#¯DBSÅ^£¸•¬É÷xGbî@†&­¬j¨<vl8şœéÕ/Qü>îˆÁŠ¿’l¹< ,İå„Ğ°{ht¾ş›ó®ç¸Ø×Á Eˆi5©º
Û’3Væ­ÄÙ2ïP¨hŸ#™ÎÎÍ¢®€WÇ Ü1Êêêö}K)ş¦ıºÏço{_êfu× 8¼8çàÏ|ì;…íçGg«²;ILÅÜ±¥¶©ÁLÁ®¼w¸Z4sùcvÉ
UáŠAëªêMW«9ºJœ@V‡ÆQif™¡7á”½gÀ&îKpE ÷,ˆxUFûvÆĞ]œÌ;ˆ+ß¸¾qåÈ]Å(>x.ÔŒXÉ.˜7¿HÎÏ,ù.LĞG¾ÕDsvö¼½î½ZM¦wwIËPì5·ï†Çzİ?ëoæÓ.Î zÊJF8[°İ!kçe…]ÊL•Ÿø=ôğÑ·j=øgiÔfÉBéi ÁŠŸš6¹£_ÿ/Ári¥Êæ6(bòˆ
;^¤è,LŸ©»or³áê4 PrXfÛFÓ˜_jyşb6ŠfµºU\KÚWúâVé^Ï)O¸—ÚßüÌÅ7HlÏj™‰ûab–‘Öø¯êjM¼Œtñí,ì,	3{ÅÙÙ,j¾!¯±TuAJjYgÜ¾4å%]ñú›eò)”G˜^rIËZÄIsÍ{
7·ÃßgYy|12èÓZR¬Nò`ã ¸´pîtRĞúù±¤¢êjéÛ2Š_˜½¨º#s¦R¿úêæÃ>sòp6[
ÑmÆ£9«‡),5zkaHrƒo²;pUˆüì£ı9ıp í):|ÄşÆóĞ0v¹èm#:o:âëô÷L¡X.P;ÅìÔ£=(¬#¹Æub Âp,—“H<Î’Q¶Ï±é—ÉŸy‡'…Œ<L,´Këİ$ñzŠ¾3W×`	µK°^U°°›½ÍôiÂ¬ O+i2œÛÛ£ o	jˆ‰ù"´’ˆè7[¾$›'r4ûK²ü=ÁÌs;sx¦\”$"î^„ßŒ2·„æ‹IA‡vëºçRf”ÓˆkO?-îQ(mè†¦–³Ú@•âº29X«á•Ã;È˜Fßâ&Kpi^ÜÖ|¤V×›w¹PòpqgOÍÚ[à_]&1‚H0;A¢ø¼<ÈÃ€È`¤y 6Ã>ôâìG’ˆşŸÁfÈºN¾º$¥$ò£Nì·s gK~ÚŸÀ+³aª† ÛCüàï!8Áù8Ên%S;&(Ëp ú¡.Ğn²4“«{"#¢Ozp±q¼RÃ¿'Mˆ÷´©—[hDÖQôØ¨ÛÄÀ~d|Wè^F¤w7ò1Ë·şı‰qû‹˜ÚX¹¶ÅåŒ3ûFïî>ä=päh&L¼q0}«®+hã7G¨ô;ÄÔ<0*|Ã®FeBÙ‰qŒ‡jƒ„¬[ ãĞä
V¦¼è‹7¸tÆ”ÙLş„q†+^k”I{3¨äŞ¾pîp$‹»Î‚®³âÅá²n‘*€J§ÂoQÜæşWË½lúÅÃ§vÈÏLŸm®hşBûjfkpÀ²ÿ/çÛóÆÔQ¡~ÈU°ŞœL”†Ájâ°[á32Ö`ÏWØ0Î=ÂÌ^‘ıš %@xâ<$$¼)rÏgjœÿÖ9\[#0_öE>¸UÃ†[´Ò÷™4Èı5«w>
1ÍšÁKF[7ê; 4Æx#aèK÷ñO)”uèÛMK!ù%Ä ¥tÎ¹*ÆİbÜexèÑ³9·ªÃ“g½b8vHNÑ ñ›:OÇ§k£l)Õ{@	Ÿ®L	‰ Ã_j}².6¼à±OøP‘À÷¡#K+.–Ïõôú,ˆ.^ ù]¤àÂï:Í%7òé_ŒÆí±Q·ÖV¹Ë<%q&HÜ­%¹ÆpÍaúWôX_PöËÌFx»Å†"÷c­¬SÉ™0ß·cŞe!Ê×÷«×ğÊDòt–_or/¾ä›jgìf«áÄ7¢,$äWç„‘!€\_z©­4kº#ÁşÉiÃƒª½RØ	„%…XÿÊŒõ‘¼IÚÿ†ıb›¼–Ä®`„ÄÊkúDomì´»!4ª‚í½éÏgû‘·˜Ôš}8 šÆ.Ã@ÿä¯3¿¼W@-E¨û«T[Í4]hTTøÖWX—R¦s9:–Õ(pd×°‡G¤ônçQ®:Ò[•ş?ºp)iA]¶[¤ ¼H)¯[³•FÜ,~Z
/f$´G¬u®EŒá—6’êşlËˆ R^ç}Í~=Ôr¼)˜÷>})ì½“ím]sò
â€ğ¹ rm•â¾àsw‚ \=FØfr9şàV‘ñÖ}H[±Ol»©µòM\óui%Ê-„~	8ÍN•—¸6,5œ3ò´w±ç¨¯d>æ†è}øÖÒy#
qgÎo*‘kÇ¤'La—E!I!Úv‹H2P‚GçÊ¸ı*è­fı^LeU`İò•`/dÂ¾ëçÙë3DpZo²NëtéJço¨‡"V¹øsšã¯uÂç»¤®ìÈõ „R‰^XìU5w³ûøZß_ü:»LŠ¾+gÎÿûkî#›°G¡`Å/ÙLş7¡«ZÇÀvEk®j“J’„¾‰<“¡êØ]0åe…³;­>@¤‹hAÀòBn(¸sõ#¤É¸‹¹IåçkM‡'ràºíğ'nã\A‰áœÃ‘—p)îE%gèV"O„%ï–Z+‚ø·³¿•@¢®iq±1FêqS[ìßÑ…ä$MîÁ»B´Äó^Höqá
–‹-[Ó%/œëA<g— •‰ÿáõ9>•®Ä.ãk@É2ôqgê…‹†b…E£¹š7šÉÛ‘xBA	âß/–3;zSL´\2ö5Ö#U ½ÄMä/…™‘$ÚN4µ¯<›ipÂ/Òƒ;ÄpïÆÒB °v|î›1V×)q#0@ÅoeBl·à©¬ğx¸"¹uàn¸Ëö	ô·/³×}ğÖ¼‘æ±H÷íDÀ–ÙdVó¶n¾$› ?Â¬ŸÙ²é×õ¡z#¿Åõ<CLA¦7Z‹Ê2Ç²UÿÁÉÚŸİÔÅœ<æV®<Xkª–1e©©³Äod>ÊpßHÉ
Ü,£ZpC­×>¤‚\½u`s»¥·ö_±Âïuû$üû/°q™SÉu‰ìƒÑŞ^×íÈAîÿhg9/êlIzÓŸáŒÆ,_0Ñ Àø®&Òï×2×»šL	âÅØm«èä7D#¾Öo³ññ M°Ş™fpÅ†»=4³$»äØKy6ª©‘B[¤ÆSGJÏ\½±-£ØYÀUbwã¾HõÆâicó ¬×ßEDÃ« OrÜnú´L(½T›KŞÊŒí—¿ôEÖªf¹­LFÚebƒ½X‘gìßlå8¤-;xÇ6`õï™5œ+ù™,Ä{ô°4<áJ–Új[cÑÉTâsôK§y!üğ•¾}ì˜WŸ³ ™m’È•šï£QÕ›_Y9gÇ€b E$´nERÓ´AOP^ˆæ6/FJ6³½Ô3±™ƒ‡l6„÷œ9*üGAËÃ×<Œ	Hºs°ÍíğÛ£bÕ‹Ô“BËçWß07É‘@K.?¦~Œ¢çDƒú–2Zı92(´zh/ƒÂÙùã…h¬ùâÔ  òÌRM±pkü´<XªÏòÙ#}ŞóY\8æä?çL«÷ó€^YO3I5rŞD5¬í@‡`8ÎA‚{ÙBÏBrêçT„ŸSıõ™¶hd&‘bÏ(
,²ÇÓŸ6ÃeÊ[¹çí^ÓiM“VUüÃy´ÂÍR”Ü-Z95’¼÷ÜP’2·­£vãqAÛââ‘¬ªRK³ÿ¦9×¾7|¨ÚæSŞ©—üßUüq¬YDƒJff2|éŸ(¤DÕCr¥ ¡zñ,Ò¢##ş¨ö2s÷zœoÔ4¸³6uÀ–°Ô®öéùšë=Ø¢«ÈªˆÀ¾iÆ[;~ÿ‚“¸^­W­ÿX;,‰„wn#r™Ö(Ïï¿´Ër;¥d	)êëWÅq*É€¬Ã	ÇÈ8õ¾ãş	ºbØÈu5%|³†GÕÚ^LÉ—)%Áÿ|GyÀ|Œ¶Üò<c×1ö°–EÆn!šT*`ÄÎÿYwÈaşQB-Ÿ.^ËÀÂB±!$†îQ§738î@É¡ÒïğQÌ¥U/ö\hoÔf@†z=úädu<Ëƒ7¡´s^ë[?ªÁ®“n}©'¾y–ã,"&Zœİ¾Më-= qÊééQ>ëøÒ¸ûpæsÃ=Õ3Ä(ŠÇ‘i)·#ÎbÎ§õ¿—C<LçM« ²h‚€Ü*UŒZİ¨œÆ•·ØrZx9jèG—»Vµç\z…3¡š²ä¡±¹Ù,Ìp™_YvÜQAæ“°àÑ)üÑ•İ—–òšÂÑ8•-Òtˆ3?iÆ›N	»L$N R”®û‰éğÄ½¥¤•Q&äNÇ¯qVÌ CGbA	h»ÙqÑAtğ]l¶j©JÒCÉ ‡ÚYÛà*.ò
{N´Ø•t·ıàÎõ…¬Ïdšcxúñ·üñê_ìCO¥Ozâe/ìQBB'<­æ-­®»î•7îRïhC¥Wr#|7ã°‘#â%©|˜„§åÒh^Ğ¾§”¬·!ßècñ®†­³ì£Øælò–ú,RÍûo¾ÎZ°è;ô/¶¡¸:¡	1ŸfÏ¤Îßº§r‹ÏqØ……V!q&<}á°5c—5qgñ~ãŒÊöS˜SÕ-Ñ.XX¶“”æI	aD¼Ñ'3“®±º—ûÆè²h†±ı•èD:€ ­$TÏÓ§ë"à	}© ÀB-Iö;¾ë²Ê@ó:0ÓÌ¶İ(sI¸ñm\™ö ñ¼`‰É[
‡.Ã÷®¹?0çª°È#Œÿ¿ç ÃÎV'¿Šñ€!à«0ı=Kw!¿À¨¢‘eÔ-'–&¹ªH-]”šâÊMêØ½SÓp›4KĞo
Ú\Á$HikOçZWõê)œQ.
Øöt	²¡â`¤>=Lú·;İæ
\YÉ•Üîş%ü™}¦·.c²r:"#À¿.¢c§^¨)nmØnŞâuM$#«P<£q<ÏÉ[)A¼§F;{Ç@‹ô›ï×6â(vşÌ¬³±?oÜË²,·Ç…æéy%<„5ú•70ºJÑei»@ÃŠàRnY FfÄ°¦„ëz×¹%¸¤¹— ÛÖù¥2úÖRó8êŸ©³À6­ní&YµÀ^ÏĞš–º*%Ş~DB\;:SÁZõOP’\N}uÑÀNùwUñB?—M
q†¥«‘v\¦Î2ûÂ:ŒW?"š%Mª~ßu‡qØÅ—©ÓğSÍ°òCâGÛ›™ÓğS·\)}fÏ ı5ğ3ÜÛ&§İ\ì_Jy}’İE±e¥SO=ñÚ‘sK£š))ù…×Ùİ•‰HĞ…
(á=gÊÊe	Â°Ó#œõo¼0îwoƒ~]›r‘TY©"G¢32RÕ¯±`az`‚†ú{™Yó
?~º–.Ã÷B`yÇİÛêßq•-áşÁ»w(	|f®DQ^€½˜øŸšf‚:blûÿ{‰ı7aMßJÍÃş²±ß;%tì”ûùŞ¢&¯Yñ8"XU2o§·UÈõˆgFNæ§/±A@_]¢è÷“tçíäKN£`½ëo·)¯Vñµ0³€Û&	xbƒ³Ä}Ic_Å!gó„Ñ4¯uä%ÎĞ³B2¨-]¿¢I3‹E¥ú`]Q…K©\õ|0Âiñ\Kib¼}Çİªßx~…|´…”2¨a´ÀŞñ1ìn[Åã% c ÙšHö¼æ¨øù¦Ö…Ë‘sÊi<ZØ"ûß[åğĞ–dM éÏÓC,lnÆµ™İÿâ¢‹a\Åt×õR¯Ä‡ôX­_#?OM1¶^’nÖ%“p 3'~‡Äß.„¾JÍfÏbkƒ!5
°©Û¡[ÊÜ®ô+°7ƒÚCœ 5ŸæíIªüµ]!œï6*M¡Ùk>Í¬`G]O÷m0şeÔ®
[Wzµ=Z5ÉªCã=iIRF²o%S…c°C´;Ü#Lš–*œ-®}ĞØk«Í¯ò8·«X@ß{Tt#¥?uN+¥m›ÑÂ"öGaÚ¤¬jb·¿8D^C;Œ¶ »?…’_BÓ0=Æ<¿»ãT]ÕT
±0a.¬·yµÂ—Öü¿Ñ­ÕYŸÔÇIù/v‡v¼¶º}	ÁÓop
y~‡íC'ÀH×¨i´Yş&Ÿ,ŒãÒR‰O¾*8ßší‘‡Ûéëc•zl~ZÁQÛVƒzUÛ>HÚş"is[<)§÷—,ƒD#%ÉB©¸c²,‹FY±D¯ùÑb¦m<|Z^ƒø9"³³öˆ:˜z{Éæ.;2Å8ãäñUĞÜFZ<i-ìÁ«@çEâä¤ãQh²îİÖˆhŞ4ûgí’á„&'ˆÌx8Æ¹xå1?ÅÙyŞã´µ]ßI	ÃlˆĞˆTH køÖêÿıÎS.ëï<Ïïºœ¸V‹®¬°]¹’kï>õÚøÂ¼¢úà‚ô¿“EGbÚÚ[!òjyÇu'#ú8‚pk’Ü,×‚ã3+ì°ãkĞu1ù†q.eL©I]ÿá˜°sV¾!;“Ÿ¨úùÚaœe˜í4?’sxo„yÕA¬«ÁÊ&Nw„Œã®m?JÆsñ¹ôõÇQ½PÛRÂ&Yİ’JD&Õ‰Ÿdskeäs@[òBzäpc\\«×DB3H}ò'¥EÄ}°UâeØ íy×ÙÛ$è(–3=äËßMrÃRWZGÅ"'—\8‹Çtx»Õc³ü·!á&Î˜½*Bz]/ÿ¿9;L)OlE#œ:&,„AúÎˆ8m‘ûâûbÈœ·¶	æÑåRÚoÎgıÛÀ’Û÷äv®®öá¬^×å h)kë¨İ½KgÑŒSÏTb³8{P ¬Ì.ıùV{œ_½ƒ÷³F,<wÌº¸7‹DõÕéÊYàC§vtA6*T¿Ä¬ö–9¤©¾0KÚpB¡Væš sâ·ˆŠj§¤°ÄU@(¾­ÙŒ@µşü8B†ÈÌç„¿4½ÂLã\³ÖhAÂ}BöxY¢ÕêÔ±Á€Œ$g{£sØÕ¯)5Cc¡şÕ,ÊŞ¡ØÌÏòÃfçvr{1E—Sû»¢Êª:QË|~¨øÔ±4¢ç;v¸ød¥UÜü– RÅí‹õ­6e§f+ƒ4C_Óù‹Ÿ„4N¤n¯…œûúfÌŒ¹ .iU·wyû—w~>Ï±ÖKÖÍ¬¸œA	AÛ¬;\C'UÜÜŸjsşÀdâ]J°ürBœoÒ:S¯NKß×Ş9>¯‚wˆëJ0Z¥âú ^‰#l î–Â´Pz¢¯t¯
Q´rr‹Ëhì>+Uá5Já]éGƒ†Q:w‘kì“x9Ñ÷FZú‰È8Vğàâ/‹ŸM”Q*Ä¹ûj7Í~‹ßwßû9W-Ÿ
ØuÅ¼FñŞmø¤¥*8)š ßÒjrïÄ}0¶Y¾+°ŒaÚõeş"Îr¡¥Œâe~é=}×æ ë¢(u‰W~ƒÊg']D—¼ö¤¤#üÃŸ—v½Kõ3‚Ö3êR5»ŒxÅJ©ÛxğZ¼ÃC¿h·=R¸û–µfAÉ—«ùû\söBl¶m²ÈèJEÊµêr¶|€p56ÁŸú÷–ºk¢ 5M‰NcIExk'A/Â¤w{£`>ˆòO‚h¿—¦¿Ê\[sz¬bTÊîÔŠ´UŞÊ%[»Q7Ó€AíŠáGb|­œ ù:G2}ô(Eó±Ó¥‹¤Û_‰6=¾™…’“ò\Ë–€ê£[Y
Úé4,6Èæ¹Ë›'¦ß‘ŞïàŞPÎÒı†T¦› ˆ|~pÅÂC½›râ?ÄÎ»:„å×ìU+Dà„KuNĞ©_P(XÎİpPzİ·§£«Ú¥+úä{`	]k_S‹óÍ1ÓL C»a<®§‡ñºŞé¢$cpêq¤şBğj¯Èb\Eº’
 ƒG4>¡R±®­kpEùÜÈaí<òÙ]å¥°ÉŸ:“2×y=•³İ~…xÑ‹1‹ÙMŞ©çH+°±]o ìny|Cø+å*Ù6¬´ú-H"!¸C\‡É¢7ğB0Hn‰WX¾€4g)*AünÏúŸ†€ú©BUÚ¸¼ØåT/mÆ~.ó­nVC•,ÈÚxLÏ(ds²W*w¯÷×‚É%elid ‘¹a. ¤»&êÉóI$ß™Œı×1€$ÆJÉ5ë•¼AÜéƒAâ fRF—Sı1´¬fÙ!½e¾ú6"QNfW<Œ¶²l][Z„v;æD.3æú7Œ#ZŠ“¡n ˆ’úREàÄğ…a(aã‘ŸêäË3ë”ÆHÕN„,	©?ËxW3vd3ş‰ÍÅ'/+à¹æÙ—œŒóLYY+QNş¯Ü‰ÑºY±08*–®ËÔt;†áâÎ)|»ù.¾ıœƒ–&SïgõÄšğä(l[‰ÏÓjÚ>^[çœ)rëmu·n6If½Ÿ·kC¶uW£ÁçD§pëû*Ÿs¢ÈhíDÍéCÛÆ‰dÆîïR•ƒ?İF¼¦÷•W;Ú[ñŠ#ÍHtñÚp¬‚ê%ğ§lşk÷¾+Vnp³EïE+µ;‚áQ3?E©’ÅrY?1ÓÏiÚœƒC7ùGè­ªks¼à/iºƒgã4Æş{O\QŒÙQ·»ã'5kS*Ñu—wü× ÷èg@Óò&SÄ27üÁ2Ül6ùé ÷.¶€ÃH1 ™KÍÄÏõe¿¬Çş’Â @wÄj¡ 2İ¥*6¿­¡;`Ûu‹dp×·‚~ìÎôæÅĞî-á‰:å Ìœc§~†Ú‡YúìğŠî~ô½T¹ì0^’Fö÷"S$‘¦vĞ²ÌaÙè\AÃ\9ÌUÛecŠ“Ø¬ÉÚOqP5Óàœ¼Yã¨J‚æ!!9eX}!Ş­ÍèÉípöˆ2¨ÿ[â“kkªNÊ²ñbôLĞDGmaPğö'¬°<Zâ¸(Çgw^qxu‰´	2ü‚Wâıt7-x€ÎD£œJ.¤àù|ÆÕ‰—q9@.1(„rñÖoÔ'èQä~/¡p£ÏËbÄ´'ãÈÕı¸]â#ÇÑâ•òö‡¢ax"‹ 5ÛL)"u™óŒ*ıÛ½¤Í#ŸÆmÇÇ\0ñva)[©1jÍš+§'L°†Ôç&èà½|ƒM#˜İÂï¥„x#P£Hie¥\æÁ„Û‹:Ê[õ*5ëgF‹%Fš 4³PÂÖàÅÒîå–UJƒºZñánµ±føàÃè·áWZÙÓÈ-@ğ…­Ùcb64ÀŒö´ÚÖóÛÙs ñÓœÖ?€}êÉ[.p†œ;?Ø–dŠs%®Fïbd×ÖV¹Ö‹¤¥ZßáUw¬.…_Àæ¹ WŞmÌ5„ÖúÑµ«Zt?sÇôƒ.óIdÀ" Cû4ƒ×Ğ:Æ éİTÑ Ü—”Å×}q˜­Ñ”?t1pê‚\†Na&}RA€A²ŠB‡ùVv‡y«h1şÁ>²¡©nÔÏöœÑŞj#×È'ƒ3K¹İçV‰¶åŞx
9ç?ön+b;£|¿iÒÀW,k3İV‹ßg ö™‹^>7Ùš®K§p§Ñ$„Şãş†w£ìW²1$_ÀßV3b.À´7Ùµœ¼Íä‘*ˆpIÇ³iÙEÓh©Çœ8#ê $’¯Ë¾".+ŞÑÕĞ¸º™ö÷ ‘óµÌ3?'òËB¥ÿ}+kFI/ãLNO2÷¤Å—š³uâwı;­-&Ú,ØJ¶Şï6PÆøTœKÙC™‘†™£ĞŠ†?š5éwa©F ì´R	Éœ„;ûÙ¡¨…lÂÅ‰ÊÛ¥¾3¯³ëÒ‰ù¸³Oì
ıC@ëô‚å¡Ò.ÑŸ/n[ÇğÚ…›q	‰#¨›»aØú9í€9³äøØ4ò•3±N,hWŸÏÇËj€óÑöe¾œléÍ0¿¢‹ÀªY>Š+U'Bÿêa°k<Ë¥éâHœdHKjÚ/Õ»ì‰²vvÜ÷~FwW°éfqÄ?&À»¥½4pdô¨Úµß…
ò5„>~š|Œfùe¥k( ¾ïéŒ'riQçé¸3ÉJ…	ùi¬¾²j!ô7~œÏTX¦¼ÏQ®8ÙCÆîX&0 ş\íb‘î_«î«V]FÃœBrğ6˜ Òâíd+éë,q¸Î‹	c¬*º.¹’¬yÙs€DKµ±ªG>ñNÖƒcşÔ«5èyßp6ômË\ƒ¹•û€®20»p*„^L y¯N_+¼B >6<0ÃP§9TÜ|ÆDˆ¥äŒåmy',jOcµ‹ıÙO=Âg-@b©IÎãíà7f¤"À<WšîÑ¢Æ&ÑóÈD&Ü,í-}BüœèGéXåºœËçbá4Áp,ÙKôê½{úVä„<¬aZpji­ ¸ø=»A§V“ò‘ˆ†iŒ%Ú6TRw	øğC95®´9>‰1qY
;¾796Ñ ò>‹¹=‚ÂØ\º=éU^^‡‡ŠüŠqô'µvá£Æü³6B P	òw_˜—*¢aÆG1¢R%ó$,9ª^A«´aŞÖÑI[T¨ï†»•ó?fq9´PÎiÂh‘¨ÛûOÓ½Áè {•rÑİt Ï÷²µx;*¡“î	ÿ’}4M—¹Í¤ÍŠ?-xO›V+œn øJã
-¾J[|{nTbwù³•ªĞöÔzô„   gy ø$êG š¸€À%œS±Ägû    YZ