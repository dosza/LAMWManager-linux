#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2938265433"
MD5="04144f6c0e79505c40a977610369a983"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25576"
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
	echo Date of packaging: Mon Dec 13 14:08:52 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌâÿc¥] ¼}•À1Dd]‡Á›PætİDõ"ÛcIz‘—;—¿'\v2” ;\Ê¼Ï9‡:,c-P×€¾aæI ãÚeE	.å®o]+S+/7Ä
¢yÍ-û”VÿÓ–?'sÎòØ£(ô‡ÿB‡s‚‚›ÂÍÌÑÓ}÷xœôerËfKÑuÊşñM=Ä!Àºo±:‰Ûµ=e£Œ^µÅŸ0ólEDƒ‘«èşó¨¾Mİ¤ÔŸcÖ©Ù1ŞÊÍçÈJw¼&)µÆn$X9w/˜Óíè.œ­Ş0u?}±sÒÈ»#¦±_%½é¿ıòqÙRˆÅU“„·Ó§ûğÔËµa‘2FxÎÀŒØ­’. ¨bë¾•¹€Ï,û2KE×[§Ö×8½)ÄEÚMçíÍSÎÌAQıôr°%”2¢x{œüÊGQa	¹ßª?©j¢&¯/—ædæœî!42¨ùeÖ:ô°>œB=ÓIU\C1Ì9®ı9İÓå(òµR*míH{~ÉibÅÈ*BµÙ‰1å–¸ZıPH¹×êJœ®wí4Bo"ª\%iÿ$æ‘;WNõEŸW‡–hCÕ«ö¶ÀY²gÈ‘ë™ƒ„•rSßW)TÃõvğ¡ZÊ¼¯ûë«Å”õÙ8&Ï÷Y? “Ê´Îã²}uG‘…Sn²=ºŠ÷›øåÊÀÒf%”ÎûÈŒ;¦¡Ì¶¶®ç—´e“™¹—z5—ÁÕ+æBèè˜d’oãy®´ş1Ê·¾ä¹¨Æì=àçœíŠYv‰vm~íNé%Òıat3lĞ[ué”0‡_Ó´N$ñà‘:¤P2–³Mû‚±øÉØo{xI6½åoé(•ˆ•Ô¸á•¢#ïL#kµp?d‚ë»‘6 ŒÂ£[µee.(	-ûõ-×4Ü`=ÿ5ë€ƒòw‘$[‹àÅai?‘*Y¶Ü^ì2Çô¿¯|ü`â‡â|xH­ïÅ½B3‘¦zÔõz=(”>’2'o
~Ä%¨W§û•ª¬N¡øNÑi¸˜æ§/î\8µ¼éÄùO]v€ª‘ÛïŸRÎ\"olÒåÛ”¡®?ïşå2n;ççTƒ¿VŒt\âÎ'õ9»À¼üÖbdíëùÃp+ ‡ozÃAçšè¡í-´ âøœQ2èˆ¶Ek7_ /%È®îáÎöXïWµÆ­üh(r\5jj=·d¸á==åfÃæ;zJY6jÊ‡;Åç¨…¿8çA\¹~çÃÏ4Ü Ë"f—†éâ~ K¥QO€~¹(§¤?­6±ïàÉ[qèŞÕ¡M*Ğt$}9‘»„HÿËlµ£1õmÅí_”SáªŸ}”Ì ‘W¶ª@¶D+/Ége4<e\Õ:¼²3”å;¬’bÉk$°tÓèœ~¦ÁI	™¿4!3¬Ò)üE ò^v|—*‚&Êx®A¨ÖÜpb¡ŸT>³ÎuîXÇûÈš@éÍö#ƒäOoÂLpÖŸµÃ©æõ$·sni›:—{	¼em)FS>Qsnñ!.†,>?eÌİgñ§Ï-^‹ß.iÛ$ØîšGQÂT!G0¶Là3>9ì¦lõäqå÷†E'˜ÀC›TGìTÁ%óRíQjöŸaÖGá‡ğå6Nı·‰QtÉ35ıeÓU¸v})ĞÎå–é*äŸ/Á|œÆâç-­!¨¸ì8Öd·O_#„íE‘·¥ĞPš¦ñ®ØƒMBŠKŸ+Ë’¿&[W:ùøúˆlÓtxŠ»úf£i ‰v…$º©GÊ•˜A­4j®,èY@û¾^z`hõ!¨ ˆçÅÌIQ¬‡:—xM+½Û¨îôÈXÈÁáºµ$(:¹/ˆH/ˆ¦§³blK6¦#Ú˜f{
C…C@¶İÓ£¼öUÒæğ6l®lü¿Û7â¾Ú¥Qn¿,[ÆT‹®õ¾Üœã9p:·O¢ÀÛ aÇI¨òí-­l©¼ı/€2åxáçó*™”ß‚wYß¹ŸSµÍÊ"†wMuVŞ˜Ó+JPÃ°O9ÂªXˆäGŒ’€Êà“ñâ`×Ì\ÍtPECXğ¤ç£İj;·Ê|J€áœ%UÄê7û2MŠõˆUæ‚Ëc5È3Ññ+Æg72,ğW9áRÀYßP¼t35V/M;"şœjü€®÷ĞÍç”ş„”"d hF%w§ş‡*½ÆûGvF–ãhÃO]¨çúÇödø³º9¨¼ççda‹ÓÀXŞRU`5ñQ+á¹Ãû–¶¥e1¬àßê.¸ ¹ë’N (çaXÊtÄDãì0	u‹Ã³Ì0BmÛÖ.ƒé×R¾e~Yé¸w|#™KøÍô¯ SuŸTQ]š½ÉsĞˆÿ¤Ü²,Öf½W±73A'=Lc‡Hzë6HíâÊ`çõÖÖÒı5ø¡ëãY{Èµ*æ_øäô“Ù5=í^ÖÙ%¹pû DüîÌ×¼‚>@·¾¤ûûÌ²á—
*{V¾9y‰9­xŸ¾I ô¾†I0ÂhÆ7±´M±ı3Ë—6QïÚ;E€ğÅŒ.Ü™=0*ŠâÈ³Èø=M8ŞïÁ^°aĞ«Í‰BéôPgloÔ‘éÅ¯H?jÑvù¤ÓD7plQ\¢ãÎû±mÏVÄ‡V òk|_=uÉ…QğŞõÖÛjNë«ÁÃ›a´ÅCã¦ìÕq¨ØòÿÜ+ÔËŞóO¬À¦’ß<šıÉÛ^Ã¶_ÃåƒZVX¢¸˜‡¸ÜH9X­×öÕ&ôCYRjÌ/hŸ¬‘&‰Ğ²Ç{Iã|ó-ÓŞt62!¢<O’‹Øf
Î2 'kd›ƒ¤%É°]úŠ ÅÀ¢ØÅoéE¤í“úf¥	aN{Í\÷£-˜øõÓ²2QtÌ´Í[È]Œ®mpÌ(?6å¼‘Dİç¼jîşHU¿*ñÏzæÆ4™]z©¤ZVy±Û…¸®mß«œo
ù¬f­®™‚83áV&WTÉ*~r3$	 \Z<qO‡1 -«œ+¤35×&dBQTf†™~¥<íô“p*ïEÑî©›\³¥ºœT³™2F±v²±,)£_U «iİ•É Ó–Fê:Cğøjù'i+.»Ñ^~úx>ï¨C/£)] ¢Èì§~³¬~òÿÀ%ÀUÎ\t_!}fvï±'¸¬4<ÛÄ¹?˜öéJİ‚dØBw”Øe½ªŠtØßØÎ%ëŸ»ª1><œìP~Eö,r;Zf’ÃÖ‹É™Ş›
4r Èìy?Óf‚6æà@úKˆãäi:¡"á4‡âÄŒ<ájô8PıÓ„ö°|}ƒ$ıZÆâÃœ"á=f:ì<ñ?ùœ±(‰Zû¼­$§tÂªœ£§;/€eµ;Ûx%ú&¦ÄO]*Û”Ù7¯>cbìY¶(÷ibb¡;iñµq¢°ƒJ<D,¯¢—}L¸öŞ2{@ÈÆ–GW0Ø{w'<6‹Èİ h%×¤T‹°â«$9Læ˜‹;ÕÈRùW¢ü¢ËOÛ¾¬ùoÑË1İnñ«,/¢L5Û v!ø¹ÃÑ³FÎ¥ü$aË}R6–‰O˜ëÍíw¿"9z©›Á8Ş¸=h·Ôî¥{¯ŒàêŸÒÏœÀ;üØìF°q ‰ÌÂL:
ç#X,/ÿe-9ÿ†nÏ3ãİ‰uØ3k©_·1D¶ö‡~÷PÒıÃIX=0˜©	è4ÍÓZ^øyi+ĞĞ¸)eå½#z
 ı w›ö‹ Çˆ¨ ;„ŒNgáF+…[d²«NC«:xKDoâ–ã‰—§?İO†Ôµ°+òv‚¼0Æ™Ÿ•œÿbr-0Sº/8şñ×€õ”Æ”Fš%ğ†5jèğÉ–¦öRNêı³+ûyª‰„.*™TÏ5\“(øÿÇ¥hM¡îùàËyÕú°pP¢’~Õ¶â®X ‡BÀosè5øö#²ÔRæfï½/lµsß4·ºôI³ôì#÷ŸÈæ¹ ´sŞÙ,1ä,Ú·ËÓ°yêµ¤KğÂT¼€:»ê]jÍxÀSÒ‡ã­˜.„c,Ô‹zÕúW_5RˆæÀ0²<§Õo"oC÷"|¢¯1?“yïVVÌÖsÓêøw† )Ù´r|˜¼ÁŒ'•g¢Õë7`9fñ“àtNc—e;À²ä,u±â´yv3ö½)%ÄZ[ƒ(_ş²iÿÍEŠ¾®–ˆbùÕ^˜Ûx¬ß‡¾€Q5Xé
p°ıS8u•†²şsøõiÌ:IpÚşï$	°êUÉXEW¼{0Ñã{İÎopŞ6Q8Cr˜¡c!<6`lğ{»şNJ	xñåæBTé¹£L;oşQ.Jàö‰!ë°¦Ê
;Â‘`eæøãô|u”ømÔlA^¡|_Î]_MoûSŠblİò<ÄC?ªÅ›÷Üô§ÑV^zd@‹‡İ‰ƒóKI¼ÊúÔµ5§SAá$ÓäÖõ-ÛP¨[
 L¢Ù sE
?®é~ÇokG´Â6^·77ın¢ìh$H¶8.Çİ‰çeuœ•¢bI¤v/Æ¡²âÄıï4ŠÑ®Œ×{)U?ó>è³Ó˜hÊà“|w^
Ó
J‰¯õ“KuyóËaÓ‡†?4%› gÓô}ø[‰“g–‡à	94ş”rI®ËÚ¾0”=‡DÂ^[YCbş1¿­ÍgËÍ[¢»)kîVüà}R—à&z‡ù±p
¹›@D¿Qèú¾Îª÷WÓ•Û“=š‡M˜g¸Ö->Ú†µ5g„ël^Hçá/_{GOØSiH•Á•6– ªwsH LWÄ€’{HñUX©n¹¿’jĞImìÉ£BæÎÿ¬€çZùóhø‡búÍ±¨À'ÀÌ@ÓëÛí¾˜sj¸´„SyzPÚœ/.ß]°óÀf=6³¬Ù$8
»¢^YÕ2ûr„},%wyy)Ÿ¨­Æ'OMˆ¤Jzò•±Ÿ«¶‘qÔ/@;YïÙ<Ál>õ÷“­Ãè~²aÅÎ[ü0ŸJ´!‹íıã$¾Qõbêéš¯JôxìÀ˜àEù¦VACÀÙ\8µ£N&‡Apƒ.eVÔñ_d<é•°gÍ—VL¢¸rB’¸¼ÑèË@Gê\8Ò)Y(õ”èÖiâ",¾00úı¤Ñ˜x¬7q¼øò?SïQM:#·lÜÜcq‡‡KRÈşæËëØ§­¢ÂÃD)Na¯î‘w¤Ñ%•‰‘Rm	>äT-½ÊnÏí¥®å.ÊY^Q›¹l"{1kÖˆÂ`B^TQåcÛ¶EsR©éYT¯0>Ék%AY‹J_Eƒ"ÙRïo	cÌiPã†T¦÷4HÆŞ¡6€bB3"L¥¢µÁÛÎsØÙ¯gäœlØëS{³´[[›'Säïoè->†»¡ëeŠS÷= I
š*MİªP"¯.¢ ÿåÕî¯¼®ˆÒì+)õÚçOˆb[ wÆ xI˜NwÎck0¬5º@ÓV³êqvwvj?›Âó"åæ²š'r¯&|Y‡ùSbıø`º‚&ià‘DúµÁïáKæ5–	¥€òONÇÁnAíÔ(Ñ¥¯oğmê —âñü[3–«aC	Xr†?wt±Ï—B'êhøHÚÅ!mr	ÿqr`ÈÎÙl)¡Õzx
¾³JÔöÖsŸîîÅk½ŒL	:Ûø’
»¨…à	"¯/œQôàrj\ı"°œsÃƒ™rf'yéĞƒÌˆ-èÂÈÆÈ[@mÕ#wàZYC·å«š0Püì zûò„M}Ôî)q;Ë/H&L&fo/<²æùÕİĞ%¸†¦¼åÅB·¦KE{±”Œ³‘Ğ¹0uøƒI¢`wB{EGór!*öÖYî\}ôèäÄ…å$L‡³
·Çç ÇµÉA7|W}]®ÅÎ	í)ÿX5áQ‘Âd7»Òxê¡ÂLŠ¹Í¨‹2Ëf!šB<‡Ò}ÎœÆ…r¥Âq„Õ}S¯ÿGØh¿k;eBv±¤Ç
â.Ì­¦Q€Ò\3b`.K>¸ÁÄù±?wúõHZÏ—6=ÁgÅlÍ6ıç±
)ôÿÂ¡½+ú{ÑüDÒÅïÊ¥I `‘ ~œN:ÉŒ?p£ë¯9cµ’E„gŸãÂ/t¨Hó,|Úƒ÷C|¡aáS»¿‘RF«Î
êyãMH¤ø)Éy¸ş›Y#q—èôW›¸ =×n¢®÷ıíÂz`æÊ“
òòz)œÔv€:Q	w ?äF­ÃŸüëàl«’ê*š3|—Vt>ƒ[ÕÖÃº¾#‹Jcsøì-hH´›h	E&(²Š•Û@§L¥Ğ*ee²å¾×¥‘î}È¸0¿HÌ©¢ú#˜œş
vˆ]Ê¯…ÁğH<¬:DO…ƒšhk—A‡tB“³ç§¤%)IÊÍ¢9ÆÀ‹fâ¾“^t
×ı³ĞùQ{Ç—¿‰å;±ÅX‚ù Š–²íÆFHñşï!•c¶»4İ
Fğz6«øø‰9+ğÙK÷9‹¹öë5x¶İEpğÔ‹bh£“iÏ'GáQáoŸmëD"C€7‡2œû­XµKü‡2EáïghXÖòÖQS¬ˆé@x›ËøY¡\mPS{=iU$À…†¾¶)Î¸ß¡$œP+Š»±j§Òâ|‰¢?åĞjwb{Â,#*ë‰i¤öŞÕÂ³ÂZÒÆgÔĞ¹šÖdV‰(•99ÜX‚823¹sÓĞÔ<´<uù\Ê?éS¯lê*¶l–O§ô¥o!/`Œp¿@Uí£¯Jdãÿ¬ÏÂĞ¡.Û‡CxZ½’,?é6±ÿg S.mù ÊQè0·[¾¤Uæybİk\µóPĞ{î‡4£"ğ–“è^”#…Ã§¡ÁÀã(îp)^
n+ZFÈ‘-ûe_”³Ğ]oÎŸ‚¤4„-sÈ#a„Ë“vAÖ|û‰}†µõßtu/y[.&Ü¡}vê õÁªXhÌ3öê'Æ^€O&wS·"ññ¤¹$zwè
/dVc¹ËÖ¨áé¼«Gû­
´V°š¼¹„8M¡Íô•I¢²½¡LOjtşı.àüa´5œ!@+æKîY¿RïKsRiElXZCóÇÃ6°·òÚğÂÊZşRÑRx¤U&3Õ‘øtŠgYsµM$NJk{{ÎİÇdVs}•GD­3¼ó†2õÜ…2”hW=¿“hŠ`ãy0{eGéK‘#Ó÷áúèq9]îÏY`³éµÃëã~Âp4M£^A Á¯¯:5Õ˜‡X„ñaèiîiŠş€éIğzO©Ò`ú*e¸;¦F¿Àvø÷¥OŒïÅ êÇŞ)PÏ7Ø h‰]¡¤¡%÷i¥³àtWÔÑ÷t+3hOÅ˜pD€Ö»4@¿ìâà[ ÷1}•¹“Î%k#ª_ÍèÙ<J}™Pé®N£?Më{ÚµËP))´ÑÃÂORREıfŸÿ„cg|;ói9ÿMRlŠR†ï+ÒZŠkÙ
œR‘ÑŞ	zx ^j*íëêœU Ô šãõ]¸ôñ/m[_®¢Üd–Âo5…ù›yå?>H4ñf€	PŸî24âä"°…0øŸ»}2B§ğ;Ğÿ@ ³§‡¤Y?QíPœÖ¢~*	mÿø×pô{©é¶€è‘^¦n@~[¼ªí€ÆUåûiCø#3c©q¥Ş‰ˆ¼]¥3»zSÒMSX½ÕùÏ
ßpk[øV’¯dyøíğ*~iåsë%6İóŠzŒ7—ïÍÃª×dÉ&ÙI[ñEùy€ŠÆáåñ1ã]d^‡ e÷Ô—’ÓeoÏ{-¾SuìÕ£0¯Âê`MCt¤}…ä*qö¼â¬ø¯ù¤`¾v‡EDGˆûñ.è·NLÑŒX¹`ö€×/×Eì¡|W­Œå g-ò¶˜Í	£NüÄÑ+²0u9I.\ã…ıãv)8Å®ig!¬X¯È~¾DQ;Ã’Fƒ“Û¥ı”R’çP§´œ?iR³W#O)g(¶º3h%96òÚ“7Ø}XUÁ™kŸMô )º”x^2/m¶Æù®º,j˜Â¤^ó*‚š×Ï×O/8¸íG{3=œàî8ÿ½í0•*pEHàŒø	!´\:Èh/$—Ü‹cW©^½vLl¡°àĞT…Ú~óùîU›×ÕkWãòÕ´«AÑ('åòèI­„Ã®õˆdš,pDšnã#(Ü9Ñ†Ü($³r`/#ŸãLï\,*Ö0ƒ,5İæ”m­^±\2?d9ØÙÇ%ÀkÍºÉV%¨¾öúá¡I6êl[Ôê–m@ B‡ç”‘ËŒĞ@æšçPj'Ò9GCß’Ïğ9ô)·Õ=bÂv±âô…šôolÆL=ñ·*2­îÇ¹q²+KĞAşæ,ô~¾UZjøÕR p=İ/VC©e…7šf[+›!ö&$B€ĞÊ…¯½":9‚uøºŸÊ†‘í ¯+ÆĞ*ÈSa\äT®¥¶THŸC/Å­Ğæt<¶qÂğø]2V×,/ƒyòf@©$ÄhÕ',OeD¹gÔÑCĞÇŒ0‹7@ŒXíî??lŠ×j!šÃşf¦šh­dù|Aÿ{ZìíƒI„€N•.MÎñ(¿öc™ôFIpê„²ôpÂ«ÈŒ¾ Ü>äu0•8À˜a`0<?f±qïD@RqHºş™á½i¦™?ÌŸ‰}´å\õ+Ø€:ÅmbU9~	]¼w¥,öÊ¬ÚêxOü/é¾Œ‚L+Â³5`ÄAÛù=:vå:¯3òn±¡ÄÆ
‚Ìå#BÒÂá€|Neä3!Ë¶ü
.òÜÄ‡i¬ÔìOrÅ	{øÓB»õC™ú8¥Æ˜ßWğïŸ«hª0¢¤™Û´
€˜¼Mä'PîF»u•I-¡´¢òƒ»”Y?qø*!X¦š«n£Ö4+œ×¹E=}j¢­NQh,eZŸ–‹-å¨ëuï-Y8>dR¡mÍ®ó©üÉÌ¶¹ùIĞ¡ámÓN%‹ï5*R.€ml
ëÕë©µ;ë”ˆ´È‹!ÔœÀ«È‡k^QÇ×Àì$d 8Ç²²p¡cİíi²;şF´¨ŞgIğ?‡ºÌ7¸\Ö—^8hò–“¬_‘Ò¡Ğf”7ææ¶.JÜ"Â4Ú{¾p=pvJ{ÉÅ­…#f?è#poã„öR"MÁ/ói_»âTèf÷^l\ì:ñU¼€7ÖêÕúŞ İ”Ujcó‘°È0VéÅ9²C–³Œä„ƒwŒ#Q„xÙFğáÜàCÍH'ÃùÅ˜áÂjß¢ğìaº1Ídû¬NVm×‘¶K,RÊrÈ’	EŠrD³<ŞWıQPßø=v6i™ÙÇÎbsé¢r'ˆ®‡À–½¿]º¸"%¸5­¿ÇS;¸íÂË’}\Ã‘ÍOY¨š‡VV0k´~,ãËá”ö)/ê·ıĞ•h&vb„O£‡>I¿ß‘3	H› {.âÍ-ŒÀÿóè÷çl‚½Yö?¯pî:ºk®[%o3vÆµúß@šÀ½à!1ò…½âƒú§ı¢m¼_ù[Ò äuÇeæ?.CÕhÄ‰(R{ÜWlÀf6«û\8Î¤itî&Ê´9d DÌ®ÂIîpŞèE¸‘­ÊG×ÄÜ­L¶\Ê	2Ğ-ÑÇrøé[Ä5c¥pÆ<UÉÊ(Ö†ó\÷Ôï/' €+G ~ZMÍš›ÄÂ³qùû¯ÒÅÑ†¿óÉí ¨\ƒ¨BAu~Ÿ0ˆæ|ˆZ!µRŞ‹iiJ÷9;ãÉ¢«2åYJsÌõNæêË7îŒ34İ¤`‚ Šf3î;«›Ö3Vç`Ğç(Ç³²Á.ıc.ZÏºå÷)"Å½JÉ;£`T^ÊA·ÇñWÕœØÙ"ìœ¡äßªu„8_ñ1q³Ø7½%ııõ¼¢îqÏXé³Ùy}^a/pª˜–Ç³/Ğ…Yà„4âŸpwòeãúßF êˆ‡aXªSûLƒçÀ¿Še‚çìø–}>oÏå"A X2éeHÀ½ÓL_ÎKâ
JÚI•#üĞoÏ¬ëœ– §9YŸ¹n‘fd1¬)=ËLËßB;iïâş]/ÒÃ·,HñœSÛÌ€™ÈÙæOÆÌ`]ÖîâÇ½GÃU©g(79ÈbÂ”V®ÎYï}¹ë–š&ı²Ôï!Ä{ÓÙS˜ÒãOômŸWù” fœp‘sRpè7¦¡±ƒœâ'¶¡U«ù¸ÿ^à0>Šğp
s—Ó€åº	*Nó|Qä,õù6-^ÃZU]Š¸3Ñ®]Í4«¾ŠXnÏˆ6?u¬ï/ÖÄËhf÷ó» á#§ˆ|5Bw=úÚ È{oa’2û) RòA~‘Í¯NFwÑo,}‡ÜR"%y¯3dBİ’=á¨†^Z²z»Ñ†…AjÎÒÔ1c0h°°OŒ~ğ~‡µ¹Å$ğ­›“÷Uâ=ºp0çú¶üBkêJ˜Úÿİ­¥µ¶ÚÿËí«´÷»§íe¡å&.º@EEåÄÏÉax$›Bi
&PM„®20sŠ=Ç‚‰H‘&ÁÈ‹Ô>aÊ€8Éª.Èc # V© ™d”9H
µşGöù•×›hW’µ æg/û+;ÆUÂÓdÙ%‹{ÜŒG‘“"1ú|qÁñò±'#³o=½0fô[ïš}+æ2>6­À(‹Sƒˆ²EÚ…,ÚhÜSÃç…Ö ]¿É€NÂÒ!‰0„ËYŞŠwÉ·¤Q¹uq9/×üfè7è§' 1ßÂÿœ˜¤éòŞ„õ´hŒì¾EµØ'(«aÈsz"‹0c1Hù7‰„<üEß<T$‰çÈÇOïÓ1Cõ“G^qküÒİÙX¤“ÑqÙ,“ŠºpÍeéÌÍ#y‡ÍØQ5ĞV4ÍiW¸ø8Å3UÜì7_DÁ óhµt—”ÚŒ«¸æHQéÑ	Ì
Ó2bµ¶ù‘ñ¨œÈFyÖ§ëšBsSÔ2»Á#WíCÄ6Ã¤|wúÀİ'à±Ì ÅÎöOİö1Zü[Ğ™Pd3”™bËb§–A{#wdä/mî$Ò°^¾@J½©ÏkKrÇvğÔš†§{ûW³2¹N@J:kğR[ HÓodçÉ|İ”Ş-î¼ÌDBâ¼´¸Œ‡İ]¸rö’6<†°™JÇRI,8šé'Ó#UŠé35¤şÄ§~lŒ¬~Vì<v¢ÎÃ]à`W~ÂšV˜ÙF·ó¤A¹ómŠ¬¥Dí	1XÆ¬ÁŠ©² øRæ ŠÅheã´/Ê_
y5"xO±Éß³Ûsn¡}ü#Şü ôQ²ƒšaÑÑÇ¬êõ¤£¿ PŸZSš·ÃÁúü;µj·n*ösªg‹Cj|Åd2¾šËVÃ©ùâ9rĞFó¦@rÊ{—TâÈê¼%Ì=åØ‹x¶EJÂíCRqE3£üg8	ËBŒ!ÔNÍóâ¡RíğfŞ›ç{£zk/._¬¹jˆ¼±»ÿÚ„y´ÁEãÖ’œçöA<1ÙxkA-Âi›ŸåO¡m²˜e)G&ØC›+‰?­ÄI'¾5™Ç0²XìÖ“6hÀÕVXî4‡rÎ/ÒÓãr-môÃ%0¹vğ¤™8ñAnÜæI´RÅJ&yà›qA¦E^ï’êÀ"Ó>ò pòÂnFw’CŠT¨æKÓ‰ıÂı|ü^±jÜ÷X¯q*³‹¶Èqre¤;«_¹è‡›©zÌ´ÁöÌSµºÆ¥&0z„{¤ëä$çı‘¿.«n	œbUÆnÔgã6˜`äÇ³›Ÿr<FêuêæšFu&)Ş§¦¶¢ª½èğr”ç³Jº÷pSè‰"ÓŸ›³pÍÓ²Ë7]P Ì¥×'X® usÄÕÊ^ÿ”kÛ]á~Ë>¬òÑV(zõ¨½ñ¨s—3Xt²×ÙUáÇ•~ à$©=¼¢0¨N$CxÒh=šo¸JöIZQıl·'RBŞ]@¾-¹ìS3è$Îú@ø	€úˆpæm÷¢Â2ƒ„lEä«„OMkù½ëAƒCºïK…bjb>Ğ¼r9å¤¯a<¤<—a4£[¼ìfKşÊ°Ëı¶5¾Í¢ó™ŞK~,ìX“RfÁé-@‚âÌ¤sA[Ú-…qyƒ?ÓU´
®¥ñYlq S›<²Ôö*iXñÇú}Ô İÎ÷üßìGşARÓ¥M0WJØœœâJ¹Á0é9²‚®JÁO*K‹J™&Œ™Eî¬ß	îfäŸfÆ`²Ó\±Ò.ş}àO{ZÍ,=£ÔªdU¾S™M!1ÑtÀÔZºœ—Äx<¯Ô£z{+6(ˆiA„3Bƒí[±¤:6ÒŠwÍ8PjàÉ«êğêST&¡ÛrÕ„‘¼„ÍĞ¥ üe„&KÊú	Ñ—ˆ\ª—æÕ,ÊÍöŞÜq7P´€qß
Î!ú1üÛÏI9¹Ù(‰ñÔé!A;Ü5~‹n‹&
ïCºëZ±,‚¤uÙ¸„]*ûgæ æwµDi*eQ[û,µ)˜œÄvzÉ\¹OpøÙ›P'ÁÅğC<ü2çÜâgV[õhCVyí‘ñvÙäkJÊ…û]]Ñ.Ñøc.ïldø¿÷h‰cª”ãYâBà£Äëß‹‹#o¡`î8e0Éõk&-€ßıitØœ§bZºs&éÍÀ»üµÌ¤WpúÜÿó–£Æ€¡¨ß{Ë¥|ìÂ•ÅğşnÁ}ş íœMzI‹€¥bûyyûQ8Ñ6zo[4tÈôD6gB—õ ·ººGø²ÑìC9S$på„Š„ÍäW›P©2wFšŒÜ»Eş<…áî–vU|êºeSÑ£¸$¤Ç6ƒøŸâ™^fãƒÖ¶«¨TgÆnëWJú9ÄÔi^Åö¤´rÕ]'´ªAv™ö1l4ÒR‰qíğNéĞÓ×¹nlº @û
`ÈÄ¼[öæıÄnz§‡¯úır+“b1ñd½RÎ!•>ıôuBmgŞØ–zÎªÍÌ‰WZœ±¸”gÊ;	Y,Cm~mÅJZÖ?mÿR¾RÔ×ş¡~D9û=Ë7Ì\2°aÙ|†ÏŒêF–£ ‚GF±Éz™»âãëÍ3à
åŒU+ÌY›¥É€³Äâ¡@GÌ †UL¿B¥m[œúŒœßXæ>Ïî£ï¤°Ç¬rç³`Ğ›?‚Ô¼[²ü
L·‹Kt!›¸d£|™İ³j®¢.÷™‰K«[	^SWüp–>0½+z>IÄ¢˜_uKàGõ@Tye«Ó'> ‘&çƒ×îæÊš®Ì1@c¢[TJ='é·î™>Ê/–™JØ$|Øœe=±TÄl¾Ó“ôñ÷A¿[kõ<äwök¡‡õ~ã6ŞÄ Ü‹Š@OÍr'ÕR¨±o
uÔšŠ»Qfño‹fŠuAºnö1Â˜ÁÚuôiæUËGÊ!t„
O+Ò’
?¹/­ĞZZ7ö—İ‘”=–6ïKÂaÉ>É£¢ñÍ±W,ƒåë8Öù÷A›Š[— ˜ú¸½~)¥Õ|!¶írg¯8ÙEÿ’IeÿÓºÜñMÚŠÜEíÆÅ›â# ¬dPŸ9gD ÚJóHkN’­Ä˜`bÎ>TZæË#0öÛæyFÊ}/<»k Ú!±.LDIB;Gtô§ú'Q¨kÔÅßÒÅZfñ=Û4~¸6çëñì-b[2BtÀ™
,é†ew]b<àğ+7~xÖ$ƒ'+™n-‰}ßZ²P¤¨eÜ(^°{§ÂÂiG33ùÇÌ}Ş	6aÒ‰§t“;}uüFkç3oÃuœ˜}„±6˜˜I3ãûÅÿm.~tÁ¹\xÅÈŞ{`1şÜğ5örˆXW6w;"FD¦¥7
/WŒ§³óy”³É@ØJI,æ8!F6†[­‚DC#‹ºı³'ÊzÅä
Pi­ÂO¸çQª-vÖÚ®‚QÿÒ f¯¥ÃKÙcê	±Åõwş#Y3"ŸÓ%E‘ «;ƒú1›”Q8Y vt0n–ÒËâ°–€U¿x×âÅqJW.`ÂS±(~gU´”‚¹ùz¶;û> 4’	‚p;3e€ÅÇ“ù,N¥#t A¾àí%kuŞò¶ƒjÇ’èQÛ
ºAgã¾NÔ¦Ñû¬»ÊÀƒ³4ÅXÏ–(6¬¶Ö±h8¸d’’¶èjW[¬<'Ğî!ˆ7~l‘Ÿ?J(š^kHP4²ŒÆÑPlƒ`ñuŞfÚÅv+3Gù¿“-šıÜóâRU8+¤UM•Hª¾ü$¶;HÍˆWBÈAÔ¤³°Ÿ¹Hçš)nsé÷Â¿—?FhøÎÀz2±ø…Éºl£.ÇªJ\8Î‚ŒİUE˜lÕÀlç³Ä™_{ÙÕHø¯b{Š'j„ğŒUª³=Àrú|l#ñeúJçeº'Óë-ÌÌ‹ZÈˆÑíkÊB§i¢;¶^/Ø’vÌÙš“€%Ô¤W#ë©OjÒŒÚ¦I›O§ÛÖGÜ%kŸ'Xı‹´©Î2ä–&ÙLÖ´•Yõ·[ı¢Á'‹Œ:È7îo1Ğõó w^HÄ£„ê˜@ò•£¯“Ÿ²m‹÷1è¯°fv;,x4Ò2B¹ZFùTÿ(êóu›l‚½0œc)šÓû´-XxN¨“)/ñ0Ã£Ğæßœšä©óÿWÜë“íä‡ô»!öğ8&G>£Œ^ı'Di:Aîb­¢T†ıï¢1b¬kÇœn¤—‹P L2•õájv9½!dÆúâxÀÑ:ßQs¤ßÔh'ï)À¯æ¿MKdl§áÎ
1¤bÚ1ê+ÕøJX˜Ï¬ÀÑõ#"é.Qj0ó0	¬=4}¢|8.úCwœ@ÌÖ–´š’C,dvß†œŒÎ»„4á?)~=Óº)¹^Ìi1¯¤mäßO<–*àSÇ]#E©TªiÄÁè{ÛÌ!’Âco^~şù-8Æ›üá(kEæêã_z²EÖèU÷o|7¥êXÙZír‚×zµnš~'Z€l5ğo\·%kï…_İ}ƒ¾ìä@Ì6ÓZ¦óPUDÁ}ªW–-¸÷Šøb¼ T3¨ƒ~œ%Dh¤Ñ£Ûr‡öÅCs4ÁĞ•QXÎˆæÿe‚g*ğæ‰‚»®²B‹xnİısãAœ{¿ıÕRlds@ôIsAaêØ{à­1~ñ<´Å¨-&eJaØ!eäï÷ıû=$ò_Ï·¼<u´¡¢FhçK7jÃeÏŸ®˜ÕfHjíĞ¦Ùg¹
êÖœ=‚÷åÍ´$c<õç×?
Qs6ğv_jFÜòü¾>™=éfks‰L)‹?-óCø
j<¨¾ä}—İó$6sÑ“‰PªÍ„cŠe÷®ù—RU¨éö`8#ó‹™åı—ƒMõ1&Ç3´XLĞœËŒùp‚ù¾Ó+[ H±S‘k“ÓË9N=†úÃC; ªãrq(4ß­ßa¾ _ƒ¿3ïISRœ™Ra)	‚èéEXDÂ‡ì±!%eåTÛ¡8NL¢,ûÃ5Y"ò5ñE­š&÷m¨µCÏ½ p’íÈåVû”ô/zHt·(táoÊ0x1ƒ#¦¬‘ıË«€]Mé`k¥ÔzÅªÔÁâR2gÛ‘¿’ŞRÒ¨œj•Æwğb¼Mb€¼.`-tÎ|Ë×+5&eR™fô6&F·–áüM²1*ËnÜ”™g>r•©³kñKg5u<ŞÍ%›HÎ€ãÍ•’ËD'i§tAÓ°Âjë>¤Ü•ÃË¶07“ªpFj98‰ µ!¯*W@9J|ù’-r Şò©½çFÂè)å+KŠ¤´ÖÜDÕSÜğ
È“Êü4²²íb¤[Cì,¿YjYˆ»İ¼ûLÁ’ĞéXªíœƒæ‘¯ç˜ñ<#à‚ã(ôæB^×*Ä¸u—X¨Ñ¶Œ³…N¡D*üJ›ÃHL”ıñx,m<ğ•Gâ)èœrŞ6 ]÷qøÌº¡]¥b¡öXzŞ%Ö¬òÎSå‰ø=ràHcË“ªw5î7ú¬°O†Öv™a(¶';KbŸÉÛ8µ€›AOç¿ìOv)²ÿ¢’ôGÑ6eˆ˜jÙ¿>tI£Œ7Óµ¥p”Ï'ÂWégé+ü]†%ño0æT‡+e_.©|X1HÜ”¹ä³
 T;ër‡á‰ú3r r.ØqÏÈ×îOÿ„ÇpÓ€6ùê•É„¢:áK˜R±ÂîWÄŞÌ®yÁE¾(D¼‚ç•¾tƒ²7\ZYßıå"®i«[Ç±™6:L÷ëj	Â•1[û;¾…%êTÄÚH½a‹İÑØ4!3ûœm,±p(‹³öCŠâ«”üÁüpÊí™%Ò»YĞxƒupŸÓŞi-gÜ_ÇÊ²Únd™:h„b~‚+3Õ]íC®İA¹K &ÎY	G°÷ök +TFì4‰ ²v-UëÏeä§a!ûgù“îCv^I³·ˆçJ°E½š[îI52şÇ$Ë,ıµß=ì	¹´ş¹hˆ“Aš‘FyN~¨WYq±Tî @Kìæ—×·ÑßQe¯–¤ú25P¢6?¾fübâ‘ç=(Ó»ˆáèê9xk\ 5%à¡"“"#TÓ‡ŸÓßp•±·â}‹ì¾Fyóêöÿ'ìŒÖ°ÈTğğ¦\/ÈSèíü¤4…Ù'õàƒòÍ Éõm:Z!üi8î¶ b³%tFÕ3†¶0MŸü{^ãŞsVŠ‹è¤¼[ôq‚°äëÃ*«½êL‚R#ˆŒ†4¯¬yõ”òÕ "dŞ“+àVqv ]¢ä%K@»ÉD÷óìşØô=354" W®bb‹õA„ßçô©0%–G¹9Ëè+±Çû›†™²üš®lGêsÉEìØtŒÁ+½(q3w-_-³Ù´w¾±×Ş0*w~Öæ`'¿Z–]¹=ˆ6hÛzÂæŒ^Å7#`\Væ.M•ú6y¶7x£&ft#šFü[c¤öõ#/|SMtŸà½V¼Ÿ4QEÎÃó…&~@~² ÌÙoÇUjŠë&è:™ÓØ‰=Ïƒ‡UÇ-:'³üå\ÂUgœ:ò×‡!¥µA>›b1@¿,k¹tª…Ÿ¥;[…Ö¼»š4&u‡(M‹§Û,áÇë‚U4ÎoÎÂÏ×¶öc9–b†”zá@±5¼±-¶4%½ù½±`®²œä_Åö¡É¢H.í½€xT<°ˆZ·1¬Şµ¹¼ölwq\ğûÈ÷»ò“ÀQüÛŒƒ&V³½_V	–½C
ÀAl'¨Cal“»W¡Z'9;&±rŠó¢t}Œ¦œ}Tk‡©|»°ÛØˆTq…7êg;¿Ãä×Zñ
ÆmÏ¬10æzLZŒƒåyq÷”T
–Ÿ{”°…ë=<½š‚]ğ®¦4¤C³5©¹Ü7‘mÀóÇWÀ½+şçlİÒMï¦¸À•†òÿ9KEÓªxr?Äq—+~ÙÈÙÆø­6kÉQÖôÃ/üàb9+÷+ß'0¡º8Ïä^ 3e|2’RüŞµ—ÔÈ:X=½Á2®%ÉèÍ Ş,£‹÷[c¹ Ó9Pjµ>Ö€ŞÆÔ<ôš3±“Ù´§!ØønÊhµxÂïE¤:lİtR)Òƒ=†à¨*éô\ŒK¨V­pªîÎùÎ	Ñmû–I$ÊU4íUÖY/¿ø7üyxdlLkVÇŞ>j~÷5xm†…=i0åÎIuP]i½ù¬µø½•Ê‚ñSE¤‚ZwŸÆ’ÍÓõ‘2½ŠÂPyÚéŞuİ¡I¡;qÎZ9ˆ™Ôë<S¿`¹Ğ…0V‹T¨=§Î²¨²ÏºS¬î'%pkÌ0˜KÄçQş
gjßqôŒğó…ï)ó¨X%Ñb¤>åë'ôèÒÕK3¸Ï×Ã‘o1#Å<F”ŞÇÏøK»,UÏÔÎÜ³sWŠ|;æ%¬‹é½o*¡­cñ›jëºg3À]:®¼‘	&M2×ÏhÚ~ï~†LhSgï}VŒWtF…öS §Ak§vë·R¹Ş¤Ps³=PŸ–m;ˆc¼i3]Ú=nuçzÕ£Ï†˜‡>ó	5¡yP
9ò«u}…é‚Ç8,½ÂtFß_s:T6Hİ…(]šf7rn$}Ü®ö'Ö0g:(=ò/¸zê¥ÀÃâ&4SiËéIƒsİy£Èı·Ã¦šç	ü(NNÙL8Ì&‘<¸9„G¾ºšúÏu&!h‡:4E•¬XU½½irÃõ¢*RQ\«'¸áèpå>!m´-d2íú\0ñ@ıa©Ê«ê'½8ìW=Ş__ÇÛçî®ªY˜ÚšÍ€PY+…ibÌì‰­òYU¤A¿vK­'ãõë~“fÈ÷Ù|İq,‚G«ğ¶£-Ã›FR''®ì&,æÈR_tÈbš|ğ¡õUBí5 ÓØm¼¤8ˆ3hë×.iF÷íHÌ/ÈI^İ‚wìWÀ¿*»„zdOíZÕg³¯’Y'u™Z*Ïi7ÓúA{ëÄŠ|“É¿†‰ÁÙ÷mZI=T‹°xP}„CÀ“7GÒôæ^»Ú O«¤ö—ñ·H}|Ç„ ğåG5œ'9»ºQÆ÷–Ï+e]¾ğ ’È¬Ø¢‰ôÏ¦.‘ØPÑ	ãúhˆ÷3ƒTÔ¾šLcıòL”~;¨^WÔø#!;ËÇ^¸—[¡äNw‰"nELc‚‹ié)‚Ï§f4áÛD^…rÀÛÉñËIŞ§~]ıv©oN9j¨à:6YV ÆsÓ¶Û»VÊ9ÎÖƒAÜgâ*oâ&€ò0\ /ÖºÜ³Æ$6”d)ÀÀ¾ñ¯‹}¿š«µ¸ ø…gì&‘i‡ƒİ±´—†æÿ.uúTïA\GÆ¾·U8ÁÕYYy`[‹³]â¼ÛÓâ/çãSvU²î{CÚZóæº™©ÃæëBˆ“é9ÿ^å>97+¾B‰;¡,Ás„ú¸S‹€”ÜwAŠS”KÁ	eí‹ßİe
5íu|Ú.kó7şK1Y!/
—£iÎÜ—;Kr‰ak,ºÔU3S¢5ñ2‹*'¤û–È§}TóæRÆŠü,N@n–@g=©­FØêÆ›ß\¡.º—üåÙ‘°Xrz·SZcˆL“ì7*uĞ}Tˆ{ûšb)qj)_|.Æ}xZ¼«íTü@ãP7ÌÓY†RcÜûˆIn—;!¸!-Mæí›P10äYhílĞÏç´WÑÂIjÀÁHØwü‘×(è)ß®°"=`nÁæjSíCâ\æ¡p¥ß2@=O¥²ÀO%ŒÍ"&¨"câ£ç÷¼ß(xOâm"Ó¤Œaçó;´{“¾1“ìsûiêñ"HSÊ“gâ™CÖªÏyJ1úéBõÌo¯UBÓoNšbø-&i}'yÕ¹„o:Lh‰Š2ŸVÎérF÷}lÆîêªÔƒ“Jå?B2&Øãe“-hHĞwW”A« 4MÑMãmÂ@x÷Kù¬£wıNôä„âôŠ¦ï$LêäupvÏÏíVŒ„FÈQÅÀ``”?V‘Q`Ú†¼ÄÁY¶&'Æs“I,"İB&jkuŸcˆÜjrÖ\Ø*t&3É€—ËxwmíöıtÅÖ2æËï¸5G
	ªô-xi®Ì»PşúÙ>_š„quA˜™nó§Èÿ\TjùúhYÀ•½l”­9;nÄqôQÑä'–ÅÇƒ÷–ÚÀ¬ª]²J>Ã3>­9À5oP›‹ªI|PO2Iiç0ù—ÄuO¾/Óíóm;ìÿS'|2º,}b<Šl_'²uOvjøëhİŸ¡qù…nh™ËÀ¢!=Š¬gÁÎ+WzØõb ÷î¢ğ¥æg®ÉÙa“‘Àåˆv±CÊ«éf»ÜAå=ÿ4æ5aK|¿Ä„¿OFªØm‹Òå7Év”&c¼2U¦Wà×jiKãEš±u‚©“õMP!òóÑ'	0Øóf=§'•9¥v]j"‹—r'ÑøäIs[ù"B¿Ú š†Š½îèŞŠBP2êÅ®©Åû³_dªj»áôH|hè{år­h!]W‚/á¦ó7^cSÄš¬ŞÇ­ô‡N,‚™ØÂKµy–*w¶Cûì\7Làd#CBP¬‘•k³B°¬P7ÏRØubîÒ)@P~2Õ# ¬-ÜÁ¿”ò+&ívóäù’å..`ˆğØ¤ñà³@¿c‘˜îÎ¿œR6—C+§è~gX\w%;!fªRü¬Ëğe{XsSÏ!IÀVäø8%Óìù¦Üs 9•nKjòúyØ¾™èAã4«ïgªxÓuÌì–ß©ÃŞ ¸^ËÙ®dW¨o@'X™¿LÉŒº!¦]#;ÌœÑ‡éÉ†6½ìjñ(Y}%V
¼êê»rĞÀÁ$q¶zò¬í¡÷WZF¬u×ñª{i%V^ÑPãExè†£ˆêõ„Å;Â¤xC¸6{¾Æ¶g8ğ µE+ÁûîÑü…5ßjœå^y6Ø*ûvó5’?d0
2*KËÑ´¯î·½¶ËñtàŒá‹îÇ“&™“·i‹Ãñˆ†îaNã9u„ÔÌQ|3Œãšt”šè4Û‡ßä“xHşí5‘ô{„²j¶ò 7 öí‰Œ# Â_]ŒÙNƒ*l|o„BOA|aşÂl³#S)Òr©ßÖU%G¹–æë›üâ~ÃÁò6§±ùfIü.Œ˜åä°oë'‚¬şWke‹^âÅTË«G*Ÿ«Ùıe©~Lá!|ıln%¬°ØÕ¼¾Üÿ¿$8,‘kSü÷ihš‡Ù—œ‰©,9ZMKşãÿ=oÿ’ÜNì78x\VøyQˆ	ó^rÏ6¢1ú8ÇHO›,
‡NÅbhÁæ¤vÖC¡%±3¡¿eò°š¼iß>Ûx¼HËÌ¬¿#~ñ/Ú¬.KsOu,İ'C¡ÚbÎ7ì°`Øâx•jX’K5ÆW¬W±”¬¯G7<mõpe…fdÛ`åã\|7ë ”^%áÙ.wWkLi1KÎ{“|qUüM)Ù®º*0{\bp÷@ü|×†4q#+şy©½ğ¨	7”	ıÀ{0şÄ™´3]Â¥ jßİ /)ô4œºÕ"ÖŠ«›3ÖÁ £ûÈ9kĞ˜D5Æ©ßc,²9ØFT·1“(²^EWGŸ`á–Ë;“nNG Ğ}•Ó®çu­ñ¶§G2Tßz'+¡lÁOŞ9'¶AÛô×èš’ó[”œ¢64ì˜1e<E²ji•GÏÜ{ÿLuØ¼Zø‹ˆ)FHc#÷î’·Hœ3¥®¡b·UôÜQ3ÄÆgs(oSŞÍ’q0¢ÛaÂÖÜm|’Ñ£Âôƒ÷;Y)j_lÏ®áC½0Ğ:Üƒp‘>5	Ÿ’ÁÇñ2¸°}'Bª'á|Ú†ejº^¤[ŒÆŸø†ßç5‰êë-’+ó4¤®CŞşB4+.µé@oî~
ù^`¥NÈ#Şão”ŒhÉsM¢-ìK…9
€©b2>OK©à’uëFÉIÁò DônÕ?H7izÓÕ$¿=™Q|isç“•ŒíÒ«S°ßœu¹.ÂI¿r<w3üá‘hÂ“;Í‚´¹õ¸«U"öådÅ>ãÎõjOLš ë"vdƒ<³=ål[+nÁ<ÇÔ†q:I»]ıfY¾Áv;grqâæ	VÚì`s§<ÇZ6O¤5Ë´Õµ½÷xÁÎSÕ¥elÄ‚ø}wÆ–q”({.1ÉBóñ9ĞT«_]ü}>åìŞ0ÌŸIÜÃ:“ )ç Bh•şv×<ßŞ6VÖhbınæ-~áAj„L‚@|K¥»’ä†ìRù>áèäWè‰ĞƒğÎí÷H5?æW À6O5p¯Ã<?n Á¥ãwMæ¦W‡ñjH=H’¾öëë]*cè-Z‡ú3úh2Ş]_‚cëŠ2ªP(¤"€GÃq‡¨fß­£ü›ŸWêLY¼ú”}.ñUæÑ§ñl?Jü/?‡NnÍ2ŞnJô?ÿUÒØAÜqÓ7‚à‰|Ô©l#¿¶:*Ç¥!<„¨ñRw8vvDt±Â—ÒıX90"#Ì[yÑyZı3b|]¹*fRn8«H_[òÿ8¥T:ä ‹]û+s ÀÁô\åYf6*æMéŞØø)“Š×%úú´­˜üæ‰ºk0Š¹ø‚Ë³")E™×½%•„|:ş=jª…
Ğ¶Q!FLÀö‰=±Gæ –Ã†/W‚mÚ§•àX'Ú¶(?'—8˜÷ÊĞræ•ˆV5ı$Ù	J^¼EİĞx(Sñ70é%³–Æ®+7l$Çs4C|ÄÊz¡cÎ¼P‚Ğ·8b®ü…èäWb¯•lê-ùTÑ-²1e´wy7næJ¿¾´u"`ÇLœ®7±!©;ÉšåŒ%®bmå½fº´oñ(¡U<ıDÌeç,>óô¯Çù8>ı'ß,G&Ûe]ZKĞE±;­WÖâï	V{~¯Ú	©(	swá;!™zj—µÒÁZiš°ú‘,ÃY|WU;ä–€×€$qcÅb-|‘“Ût@¸ccù†Ê¡†ä/Ï“1Îš!ÖŸğ)nŞŠ6‡aÁpÈé³HÒÉµ6WRÀÕO§LÕ¾æ*ì¾É-oá%’¬|ƒvPÙuïÆ˜b?U¸p%uş€øMÏŠ§Es‰¦ÿ?ìÔ¢F”Ç
ùµƒÍ.M·³ÌÔ¤u¾«Ô}… Íı€m½’ÊZİÜ£õ¢ıÿ¼Z$J³¹k™á¸­'îùõ£ùëXÈ º{½¸>ÀNeˆ}pši$@C–ğz™›96¢	ŞV~ßöölCş´Ød˜s¾t_¨­û‘g[“Dªb+ w-Pœ¢ŸµôÉ~î›x<Â€˜™¦:
:–RÅµv¾¯ìÍ!JÆ¼AĞòË¦gü9JöFGrœ”d}±×B^,^»É€Ÿ6»C¶”^Rà!³7uÿı½iÃê26ûX\¹¹PøßŸ‹÷ÁëG¸ä?²««è•"ş^|[¿{(ÒE±Åò.AçŒ„4º.EóêçÍfîWá2«“Ü‰;ˆªƒˆŠYr/»(ÆÒ¨İëÅUø!ˆ³SMIÚëµt¥S&ïĞ$ñ9Ò®úËjšÎùIóh¨Ù}£ T0Hr±îz&®íŒ;,HG¶­§¢Û‰†Åw3qñŞ©Ct=º)Ç|£ ÷÷¢â
‚-3ÁúÑdo–iüğÖ„¿úm¯‘Zì<UEB
·Á.2È˜bù÷Hœ«N~•ßŠ¸UFàHA¸ƒ«’Oö[à
I(CqŠ»™ãÓÒ®Ñã=÷C–³ÇÁKîü¤¨ÜE%F‘Ş›’ÜİÑYäldK±# (ÑÎ4LÍA‡¯åmª&ÅÕöÕòŠA"¡”ÖIú¤zÅ(úãQ
¿À¶ğNY8HkøƒjnÚ€	š-²ğt°#ğz=F$¸ğÈ[ëtŠi¹æÍ¨35±¶Êõ”rdõ
]}ùe@ãÏØÃøuñDWjµ-å´H½ù{Ã, ı!¦[S¨ï¿à2uÜÜ-ZpPZñh$>g†pşM»ƒérá'm:»Ú<çc\ŞiÆfÑ@°áÒ“!’Iè¢k†ÉúÜxĞöW…=ã´‰u,ùzÓÌ!Y½ß©øúiëßì2šG&õÈh)·é¹p¹>©Zããg+H|'sáF 2ì2XlúàTm&›hŞéU¨`’µÆ¢gëº›]7R•C°DuÔ}@p£ww1@ÕáÍóØì{íŞÍçlbùsN1ØŸ–';åMD)|P§Rè&ÃÀöèÿDŸ_Â=î¥í9aç\èC	ª	‰z?éh“`ÇP'Lp~Aîf‰,Y&uÏ¼™›Ö&˜Wœ¯ùr<l*‹Å%?à®ÚÃ@ÆFmøhUeæíö¾®—ï½˜EæVÆ‹frmôëJ3¦4ä\¶w(ÆY?ÈGºƒ‚’|‘˜iJéã”ŸJd°ñ†ö!áTJ¦÷=Ñ~ø%œWš>­w
|›F©Ê*ıANI¡¤e1w£Y%N/ŞKä4iVä‚ßòÛİJĞ@.Ò©i~ş»®JÛ‘é‰ÀÙnld‹…7*ûõğ.†—Ê°í'Ô‚-‰	İnÏÍèw°GÜÖæ)s)[QOÄóÇš°q8ûR«[®Àèb¶ø;Ó«lÎ	ÅÏœ?Ùğ……?ïá~PÑNÙÀÚM„ğî¸£hnh(«İ	‘|úğ-de%@(¤n¸ãµm»“ ls(,—_ëğö~Ù‡@šï-Ë=^´uÿ*;|¶è`–‘ÓF•éÏÍ!\ë®'Ğ¾Òpº¼bª†Íâ‘Óªáo0K+úëø> }L„«cÖ'+Q~Jõh—Õ”ğÏß¯4BÆsî84Å½¿o†‘¡-%Í¯Jƒoà›Å>ïgÎh>•È~Ú+ÔĞ™ä'ô9èÊ¾Ø‡¦Ü6§¹ÛÎ>ÿ&!Öe±¯Í]å²@b7|EEÜ_€ì@°£­;‚V;~×WBÔù!âcƒ }&ª³véÂŠSppÎA4îIç&òœsO‹Zn™é¦ü½E’Ï¸rãŒá8,>å9WíNRr¶fè{µK’Èêp@P—ãii—«'­o=»%¹i]lÒtkÊ~à’u°Do-‡XxâhEbHÓõĞOèJ4W_@«ÍD%ãHçùP¦œ]5İV:Ø–n«›%ØF=„CºªŸãƒåÖT7Ò}ìS—!ÌÄ4.»¹IEğãñ¨h©ÚïˆÔÀ¼ÎÁÕò —ÄOÇÕ€‰ë~HünZSßQÕO*H>ÕıîÄ¼BĞô­ç†q<KŒ<Io«LÍ¥,xzc’id˜¦¦]“µ…¹pÜ…ŸĞ.TÑè|Ë‡Ü3Ö ¿aY¡$¤.êÚ E^Ù·ü°ƒ}–a&Ïl]¾Ôc‚á.¿h5ä©@„CÅ"{.×“#!6iSìÔÖli—	#8×¼ÉN‰¤Eé¯›Ø‹Ä¨ú©©– HL!Z§ç_)¡šË(›Ç¹xÅDÓÚ¨g'>J}³r»É¼ÂOÎ©Ş”êXäk¶u]Ğ§ÁdÚÚüqÖ{¤Vx>çşŸé¾³¹î#Ç)ôn¥v°¾Kß2Ğt~ÿD‡´6OÂòr§Ïå‡ŸÊ9¯0Å¦©®fZ&RŠŸª‘¦^·$›íGŞPeJ>3»¡¶N&ğ/ùûÄ+ğ0HŞ}Şú!,Œ¯¥Ş¾Åk9Ã˜Ó²í¹Œs]íÀô˜“xúÓ@æşœ‰‰y(õİ¯°VWqd·=³1¢¼+¹S×w…mIñPæ/ïŞşñ-4¤óÆ1JE3ÓaD~‘;AÕÿÀ<!ÅÂàİç·HšÎÊM™Á­lLfşTöÏ#QõM…M»ÃÈ—¦6tjÈCÒQ|	>ÀÜñ\ú‰
uÑFÿr3Ù»lFúˆ/¬Üü±	ÕTL¯ùÌË6ØÓ&ğ'vÒ£Îüp°8Já'ÿì´ÕÛøãä½„Š6ye¸áÇáÓ€xXîùûí.´iNjUàÿSÜoºg}Í\•ä„5ü¤`Jo‡€ºM­´³År=NÌPIüì¥9vØ&{Š“$XR2ya!
*æ¤ìêáZËH€nñØÃOH-‡eAÎ,, „<|Á#–JìäñÚ6ıœ´8S7£Ê{~#`ÙŠÛ–‰Ü94ÔCEˆ¨Áî9D—4VA$TSTy àºüdˆ?œŒÆ®mR´/„ËSf@´4è¦Ò›«œZx¨tş WÃhï´oõ‚ ŠùÃ2VÿŠ[%Úğ;"İ-Ö9w'Ñö»Ú’ñ~—ùuä(¡­?SS‡@Î‰Ø;Ñ™qúşúà9–¤0Q¬µÅ…Ÿ6À–Ö>m ’F‘2Ù$9:äØğ÷G„ŠÊœŸo©æ™©¿yæõP"ä|‚_ç0e|»t{³µ&a6µèU=ûFèlhÖR—Z[úÆzFÁÙeQîÎ ë÷)€*î©ZO"¸Dv¢Y/1Mô}úRëŞõvkÙYıï=4xcY-0'¢­cDƒŠıå+Ò…äªgu ˜¢@QÇŞlÒqrnL?¡ğ¦;ŒE¼’å}ŠöÉöx•z³ „%IrÁ=m;{[öqœönfë	ÉØUÿT¡³ä'»¿€Jú¤óıÒg]æÂÿÃAĞšbÒY÷á5TŒGNå¤â!ßƒS¿sK–¸¬tãÀ*d|Ğ…¤FMƒQÊàà`ZK9ÇV“Ñ{Ê ¯¤›¹İ:üÇsXõ[Ä°ßdÆz@÷e‹C”ú»şz÷ŸäÔ¦ÀŠ ~ÆæØI#âwÈ³$Èj0¤¦ªê´PÌ¼WÙqçÈ2KÚ‰±)“IÈ©WañBµÿ„aâ¶(û˜¼Ú˜Yr\T|T<h¢Š÷ÿiOÙD,C|Š”fV\ò¦e-èºšd½uQ&¬Ou§Rì‚û™ŠÖØWúÿèÓÿZ!Ê|ÖZµ)ï<»t/ÆÛ+Á‰ßÌT.yµ{\øälªŞOÄÂ {vn÷v7WÏã|û™dÀ@8múø#îYù3°:†÷$›EÁ™‚„ˆ RDÛµš÷çg]e¢@›QŞ’tCdˆT¤º&r Œ­tîä(BÍy¡–}‹é“¬m$ÇıwY¼•	pK*‰Šf?OHF-Tbd¹Û‰VEcìsœRnÙ«öñäğmq÷ÎVî¢—ijæmDİ°_í[*ØÙr+s¹¸Áì¬´FœPè¡ò‹ãÕ"¡Ë^‚+H§•©D6nVÛPH~ºi³Óİúè·í^-ßLjF!×È¾¦Á8­ÎY­:[*àtz¦+Ë`›ÈVÔšÍI¶¿0&Îõ¥Øoúë‚ÍU*Ùê$”ÂUÂ·^ï¾ÙF¹òGV\2­pŞs[&Ü±<N´mî[ÀPıÁçPàÍë¾·D‘í±{é„Ç„îÃi©*Ú†¯×ã?L4Úe¢\Î,r0æÒH{nD”ôÌÔ®ôƒ¡Zí&õ¬”áŸ\˜Qº¬3ğd9Íş+À¯
1bJ‹Û«×EÎM¼oÒë!mÆVô²'¶8F±¾—¸kïº.©ïã~?Ö?å‘œ&z¶ÕcĞK¦©©o=Ìú"Ö°jÕ«\~×n=÷Í¡§¹Áˆ%‹ñ27‘•”,28#)rù“šİó¤Â§éáŒÉ–ÍÌÓ¢°ºUXËÛÃ5q,ü½¢(¨Ù.p$s ])‹n$<Àõã{i„æy"KëúÇƒlù{»Aë`ÚÆëğØ;cÈ[èEo³¹_-}« ôh*©;5¬›µ9ël«	ÃiÅç%U3ægŒ(ó)J¿Şõc–i§½¬Ø÷7ıÕ“h36_‚@Éó¯İA„~â•ØğDNŠdv?!<w"‡û
à61A…4dÈ~Óu*=Îe||àÃ„µuy· ¸(w&‚EïG4>Ô+…	Qº®¦Úõ&µ«œN°C`—ƒv	ûô2Áó2G×Šâm :iY¬†˜¼Nò`ç¯š\Ò--°’½µhÂ°5Ÿ&”C÷×Nìxñ{0ª4fG„™¯Çu=ÇsêC•LÕşó@‚ÉË?; Ÿ‘ŸgXôSbÓG¿7]]¹áÚkN´£¯Áö‘c%w\PÂJ’o8%ˆ’h0ç¬¹æır÷§Pµ(e+/î0çî»qš¨‘D®Áu£èÒ?ì¤¯Ÿpø¾ïr"¼^E6‘‡Å{0jkµşD°İ ‡>õ2õDnÃíÅ3µçMœˆˆo°ú²ZİH€"ñû]	—ù:aèáüØ2?eq[ÜeXëö‡Aë£–TZ`U1’íK…¸ï¬:’eõƒ’¥İ*î¢Q"V×ÿõì¨~ÿ¥Ù½1ÜË> XN®¨¢²Æk_÷Wù¬YãÄ*ş1ÓfÄÎR‹ó>$Rb› 8	ÖåóÁRVÿåy`èå.¨AŒ÷ZRuJ4pìJ×\7ğ€w¾Ö^‰\#î6ö(bšÚ…Ë°D+l<¿4ƒDİï'’¹ƒÖSÙİ7+0qMéÖ±
ªiôŠEqB0M›pşác¤9Ò©şYv|İ¬²#ì¯nŸUÎ©Ñ¥‰sâ™p,óví5¢_Z§–Uºâjp¢=Å–]°5Ëµ…U5|ÆèRÜ@Ê/˜}U/Ïnj0]tQÅüôù|6¨ ›²Û°0ï€CLé€x°¥qíQ…V[rV¼¥áÅß0’¼È5ñèA>¯ujç­Ãó;6òÎfıs'xEıUy”O…‡_Ù/¥ò0C7"Ê¤„òb¨Y¬nw
T¸‹HS#©hª®}5¾)LoÙ“D”ª_oüZËIšUğkIâÍ|‹°^Î/“˜î>#C[,§*tü$Ğ)5|´Y®ò²\¯D>Î×(ª£¶ÜDg|oKbß]N-±E3»«xÊ½TÌ8-›w~Úİù2ØÈÇÖ@¹_"üÍ3p“¦<á¿‹W…„¤£²?sæ¶ßuh¨×éÓ]ÖK2Ô;¹"«º<Öƒ,ãN¡m·"¼Ã::Ø‡9Õ=Rv(½‡z/»nÅhÅ«rT‹ W‰Ñ^{
”‰qƒªŠšbßÖQŠ „Şf¹0	 ‰¯V,CVİf¸ŞÀı-ŒB¹ä¸mú/Ò½4îM?€]gP¼-±Gô*³iI°5‘k"ÿ'ÑFş%È°iŒ¨ˆ_Şt¨7xØ±Éa3¾rHµ½>ªœ[V­[ğUÄÎG¡¿Ö2=Š‹ô3@Î*°qÁ½³ %ŠNHóÖ—ş1‡F”`Pª<äµ1Š?šÕAşkZ¶áê÷¯ÓrlàSüšéØ›!L[3PQ[Ò"‚ó#4J°ıÃÍÂˆPã°ó–À+`Ò¡ÇœyW%L£OÄÒÅÏiâl|‘ğ-˜ûÀÜª~í}Ccß%Zñ-p“ƒ ï¥0”;vÖ.ni”£Iø¡r@gàil¹Ç…•Ô
>Ê!05é\.m(6ÑÌLlnj»É“9W¯©Ñú-ø‹ÎÉ(¥ÜÚr‹GX`
¨çx+}Ì¯|?5’´³Ò1mNÈ(JÏ”C¾ ¥Úè©7ë>µ&!p£3&~ØS‚Ì(ºöì	=¯j×Å¥¤*TÔ²7‘íCé†ÒRû€~U¼J&Š«üŒÔ¤»?›U¸±šyàÖZ2µêà¾ZOìªKBh!Q`âÁ2mp.ÍÖÌ­ùIëv^F¤¶£tåœÛ?ğÑõõÈ¬¦¾›û<rƒàz®¿!q¡ß7ğÓ$’F)ÌèFx§ø´ ¬œTÆ— Ø~NÆË)âˆêÓ×ëc2Ô½”9u`t(’ÿ§äZéªíÑÙíø7ˆ=‹‰¥Düò„®Dr(^…K8ÿX€ËÎ¥&“ó0Ë#FkaÛG´©cŠ¬–@ròƒâïX5İ6Üñşpbõd?âFšÉ)¨X@š7Êğ',öXL¡Q€©b>§2Gú÷öĞGßøXp»4Î¶·¹é=ôí3×ˆÙ+şMdpSk¥8ıc(“wXv1cDòx¸³½Ìë$¡dJ³€îõr¥©Í¯ºõák•BTù'™:@Ft½¤Ì±*˜Æ¨Æ%§7œ7‘¿Ò bUáŠ­MƒXòá&cÁLÈÈ6aÅˆW™)Dm¾C“äiŸ·äBK©Ş$–£\gÀÛ/!ÑÇ‘ 	‰÷–&XÿhšKÃâƒ4}`áÇ
ƒWeñ°VÂ¬ó§ª²²õ¹~à™…=k×ÒJùcƒ|T‡r>Ë{Wè}(şPêZŠQ›Ôíì¹.¯@2^#³%0¶æRíº&$}âD~¯Wèñ‚ß×nHöc9fg[Wâc²4f~0TjMküw„ì&³	¢<(´18‘{‹8ÚgsÏÿ¾­56·1JLXö~ÉyPÁr‡\‰mùFê)v„°L“Á·6‹Z^,Âô¡ä?8ÿD¶©/‹~E àdÀaÔûpb
(ğ£ıŞıOœ§†’fPû?§Q ËÚ<£­A¤kœÉ@)Š	GfHkó¨««4É¼Ó!pÔõLˆˆ‹&µYI¶ä:DÇcª»ãg¢ûıˆxè¼gÆ¿˜à «`/ƒãÀ_Œ°¿I4˜B’ÑL¥ì'®œ¥_æ…(Qm$[Uğø¿|KÕckÙ»åßø$Q­
ÀfmvÉ×à¥)sõEAeÍÛW¢ã_Í-À³Ôsí>—«Û9îRV#g×j›á^Ç†3OÚ:ÈÆ,'ÌO<ë'C{ÂÂB-È£W”÷¤eÿÕÏaÁ;ÌÌ®9(½Õ8ÜÑ¯–„©½e‰ö6@¯fgX–
'şh`7~Ç,]g·ÆN?D¼òm
šk;H6WÆ~~ãWÜMÜ-°w”ÄÍ½âJb'‰Ù Õ/é]ı1çpM=Ìù	7G×ú®U½'?ë»–Å¹lÒ~+…óºk{
f0Q•HAú€¦×MÛø®Ö1½O£J….	î‹	.\êò½›àõ´ƒLı®ï÷‰qÀ•¶á
™µµT2a‡“ b¢	ŠA‰ïM½OŞÁƒvÍS)}u¦Èà+­µ|’ÈuÖ½½úAÎª‡j?Ë·ù—ş‰V´Iü¤ÛËî1“;mÃ¥Ñ_>¦‰!6NY±Ë «f(¦”NéGÑJñ¦ù¸ŒVn¨µŠ¼š!9Šw3£”SA7;+·²‹ÇNù”¶ìïN?…èÆz'AäÓ‘;•²I»ä'M%4rjÿMúTì$ÕÛód” f"ßTxêånjæÉÓÓ¥ËÕ6ŞˆÈşkÎ¶Ù¿pŸ“QŒS)ôæ$ÎnŠ<lÄi´Ë+ZH?£Œ3!©ğ,`Ÿ2ÿ!7ÜÕÃˆC¶Ñ³tPg=GÛîùûİ”n_˜œæ$ /jÊåHİ*ì@µsnÙŒHGĞş‡B}ñ~qÌÌ›kEˆs75²[¶sÂP”H³z7êAÛ3ÇgéÜñ…=:¥ĞËG.tTÙï.ÿ[`xgX5èYĞ;á¨ÿ$¸?mX¼à „O÷"™aùGü’ÌıÀØªön”ƒ?´ã@FÜf«rÕ‘Íj¦ÖHùj«Œı‰?]ŸŸ]%Ø’O}jçËÕ–l2_¥u6m55[¥}X-ïÅ½¹(Ì(Mâd›õ(ÜòÆk°y·¤qíš‹v!¿YMŒ¦E5“	Í…×¼%J{ëfdLÕêtó«tå@¡ªb®·Ûè1+míÏe?Ğ¤Òë8w‡¾¢¾1)ÔGå12l7A¨!¨d§’'/â“gÁ¨Æ¶ÑïÆƒšq‰äCm~Ì¯Ÿka\Ş^_m’s€àcÅbU+©±Üî4ÂÏ×¶›v•Ğ6ÌËDh/°{‹TúÎœœÂa–Xë.ÛÍ[
3 ‘ú 4I¾Au#æÀÃ!7MŞ@oØŸícR×H4Z>X¨  Pæbız¾±IÍ?×*-@,‹/òZÄºZ}õ/‚1dH„ò½R%—V l,˜üúûM%ïË%Ø÷VÏ*o¤[ì÷è~±_ÒÆŒÕ8ãËÓ½‚KFr¨ebö	ËecD?‹'‘QchŒB¯oÜÊìøVWü+«Ş:]wŞ˜×;d ="ˆñÚ’¡ZUÅ#U®Ú\,M­ázzwâ+Ï´f©=CA 4{uwS»
}«Qåu)úR™yõ© k¢^ÂõhCxê[OÕªKZeMÿ)fV”qº,Şôeãÿşí.àD Ñ‹Ä+ìA‡±bƒxZà~‚tgeğÇÜë¯¦ÀT/ªÿ˜I‚ã6åÇ“6õúîŸ±}0M½È¶çTEMïïlBE[ı%Ë¹N·O¯ÇÂ-«‡ƒíÇd'çøyÀ©x[öTÚœêl4PïNœ+‘€Õ|5FDíJ:Tr‡¢q—"pH¦{ãC_«¶˜mseEWò$¾iÒ«/âÔÕ^j¿kìKœ@Q¤+‰ª˜wÄğ•ã†üîø{—ºÎå“JFršÉæ`‰=­Ø‡±…À]ÛÕ|õ½»]Û½J§Ø¤æaE<eâ:İJ&€`Ô+.úeY§<Í"|±Ï)<\›ŞôoòtİÊivˆÑÍ^÷.½ãy˜nÕ¤¿XÇ4[¡iª‘.™( éVõßu}±™}QWlÁpÉ–Ç±EC¾¶¹~X4ŞÂrÎJ¾BÈµD¯£×czFÀd|úÀÕ9´™-B[7¤¶ó2Dn­³‹>Ú$}<r'‡„LÂôG´ŞgjµŞš/RÓ¸e4Šh°¬÷?5€wDIÊ« D/ı²5½!
Æ¨ã”Î­l¿ôjKáZbw,'áF]Bê_6pÃU{X»)Uñ<à¤%®ò.=±ó÷ˆ‡Jæã¤°,>Áº]`İùÚKIŒ÷ -ÁµÆ&®XI)´ÅÇ]2ìÛ ÑdŞ
Ãø—Ü;r=ßT¬£€2RµUá‚Úæ.|vêÒ¾¸×MÇÄÿ€T­_¥.¦–Òwzö)4tÒi¼­$ëv	ùn"À’(˜˜s{}şşµÌÖ4hÅIşGA{¡æ½      ë¿P£ætø÷ ÁÇ€ÊSÇd±Ägû    YZ