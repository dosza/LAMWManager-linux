#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3596977086"
MD5="4936cf232530b2a7c68848a4e899b794"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20291"
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
	echo Date of packaging: Fri Nov 22 03:30:56 -03 2019
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
‹  €×]ì<ÛvÛ8’y¿M©ãtS”|K·=ìYE–ulK+ÉIz’J„$ÆÉ!H_âñşË}˜˜·}ÍmÀ(Q¶’îdvw¢K
…B¡î ]Õ}ñO>Owwñ»şt·&'ŸGõíİ½İ§µÚÖ´×k[[õGd÷ÑWøD,4BY¦ëŞÜ÷PÿÿÑOUwÌùÕpnºæ”ÿ”ıßÙŞÙ]Øÿ­½ÚÓG¤ömÿ¿ø§ü>²]}d²™RÖ¾ô§¬”Ï]û’Ì¶L‹’	µh`:~š¡G1<n8s[h°©”›^0ºOúc›ºcJšŞÜ K)¿DD»OjÕíê¶R>„û¤^Óë»úV­ş3´P6l?D¨ÁŒU–v•ØŒøfoBBè{Åß'ÓW0=ª’ÁÀ`’«Àô}‰ÇpÒlDÉ©²™úU8©ĞkßÚ[ÏÎZòØè÷µòDMp1ÃÓãŞ°}Ö4NNŒ%’Í‹àÍN¯e¨iûy¿5ì¾h½n5³¹ZgƒVo8è[¯Ûƒ¬¹	³Ÿ5úÏå*EPC apŞ`¥|Lz; ãĞnùÛPÅ7Dƒ}«t_ê•Åµ¨äİîœ«”ŠÉÇa0¿Ãè
ˆJmUÇmîùûœ|rG”‰­¬fq%7¸€p…Tƒ0/ ò­{ó¹çjlFùÖ((Æáæî¶E™M:÷l‡²Ç›·D)%¼ÒÃ¹¯ç¡«cÏ ¯U$˜¯9€UİÁ„Í_ÀX}ï	±g‘å‘9`spÎhĞf}h
”ÒØ‰NÃ±>¼È'#Ó€úbXü[`û…è½ÔİÈqbª+&ß¤–ì&,¦´,vu¥$¨ãs9æ”ñi]zÕĞÉpÀüº
 ğóÈv-£²;<y C¨jB‹ZI@ÔbŠŠ	J§©gm\ç*·ø¥ë)Zı”|,&¡g™ÀCF<Øá Ì˜¿Áê	åMW–ñwD…Ìg )Ê”†Ï@š§‡|Ù‚Lgz¦	¥e5¬¤¿‰v­¦³õ"7¯s@ß®Ç˜‘n* ÒÈv˜wj6‘ğ©JYy’*•¬ó•?¯œµë96hÃ;3Âó…ò9ızMÇ„º—ä°İï4~3*ñòºq>xŞéµĞ–ı&ŸOŸà*©ä,Û"{¹0ùe¨G»Kèµ’jµªÔ´R¿J\EäÑ	!èâúqÅ|¥±”¢p‘\¡¤J)“„D25Y Vâ¦X67…¥t[ycLìÜ´İ”RŸ8Ym†zŞó¼pÁ}*¥LcUcÎ÷IÔ©‰2ç!òüVùc“Ù)'\‘•’laœ|XßŠŠ´±äÑ·Ïêø¼ph»SÒ‡88¤V5¼¿@ü¿·³³2ÿÛÚzºÿo?İİşÿÏsï
mRÄhÎ&í+¥:éøàùx€6åš¬üŠRx$ùĞ¹aÃØÅt-_Ê§–b@ä[£ü«Ó¼ú›b~5ı¯¢„Ã/ÈıòÿúÖÖÎ‚şïÔ~ÓÿÿŸù¹LÏÛ}rÔ>iø†¨­sÚ´1bû4;gGíãó^ëŒnòQŒô"27o¸À‹xQaÍ£°àæG2‚gÓ…LbŸ€Ì=ËØ“@0Ãø¸%ÇÂj¾,°œßûfÀDT'+Å‚ğÈ¯‘«”å!q„O4MŒ¶¨cÏmL&w®só‚2êLˆL#$‘IàÍÁ€ k:12Ñ1ì“Yúl_×“aUÛÓ¿NQAÉêrVóV{«A>CÄÊ‘å×¾é2ÑÎÌ„	ŒWQ&vÀ`sÆãˆg:8S%o5‚Ã°xoú¼Î¢)y«vß¬ò×´ÿ¼äğ¿¬ş_¯ï~«ÿÍıcáUE¶cÑ Êf_1ş¯×A:ıÿÖ^ı›ÿÿVÿÿìú}UıQĞ×<È	cÏMH}GÑˆo;8dJ]ğ°ƒ¢Ø.øE<*hôN/Ÿ4½æó½4\+ğlë+9v¥lÑCbÜÿåË#§q¦e×#İ&Áz£‰e¹ËÿØæ¥My±Òœl,x)<@:ê6±î\RJ–ÍÂáÖnT§5`›±ˆV]nba˜a	?…¦ó’êõ|¹aDê?UÕ' ˜Ö.±ğ9téÕ0â C'd¼àzpÀ‡ØntMN!z"õŸ×I™9VRrêÛÕZµ–ÇsŞ;Â5‰ÅØ¥[b:ˆ_œªL±Işé¡9ez@
ˆ‡ÛÃÚ°¦J˜ Ëğ¤ılØmª±@wìäPe	¬ytœ€!Dã¤UÇ“é"Ê^ë¤Õè·õŞ‰_¶zıvçÌˆ—¸YzE©f\G; —vÖZÒÎ½K‚^ìNÏ>’e\ÿ´7sPP´©-­+-í—¹8€Ä@r ²®Vz0…øãºpn
„Ê°`¨¡-:“¼vıH¼Q`OÍğã?@—0ö_ÀaÑK,$š ø‚0{>úøÇ{|îÁ3-Èã=›Ç%»ñËƒ?]’êq¿W±W,à3¦Š×ÆÿJº+a:}êÒzİ³s5³Ç3äöüTE“±mÆ5rµ’¤ƒ¨êò©I1æEj«¦Zo®õ–èpı¢<¯”y®›$pÆE2]Z"!d¦Ê2áá	¸WœnĞ;?{AR>ÀQXæÏ±–ÉŠ¶U­i#p
j
6\†«Ü.µ}ÿV{r—CÂÄ`iwãÃÒ“öÙùëáóÎi‹›™—ÂòX Ò!aî¿<4ï¸q,˜ñ®*ïUô±:ı ¬.ÄÂéS¹¼]^è]6<ÔˆåºY@DYñ°n©)Oræ*Ë+@Bcéâ^JY=
 ¹X¼x±0Š	T”gØÔÄ§ÌÅùîÌt§4;±_Z¨Ø-R )Yw¥„U2ŞW<à4XHæ?’ª2ivÏ‡ƒFï¸50L°€îÀP5q‰­•túi¿ˆ¥H³×é÷`Ó¨—ODkN^u_n«$¾n¯uÔ~màÎ”Ê|¹1¸R(£¸%U‘RvAÇÎy¯Ù•4|‘+†è•EÁFã'1ùğÁö–¨İ®•tï}|½Ç}dÑI:·5âXñ˜ö¼swd.Ò
/Ø'G€–Iû¯ÉêS¹=ëôN'w*VË†€+¶JK,|5=0­j¿Š¡:MíÃõåd%T)=¤<’NRÕ"®H"kYtÁx¶·S(¾ëØ‚İ‘6g±5ùü‚šæçGKÂYDİ}û¿ò"ÅÛ¿h’ÔD9šÉ’I
ÁƒÌøÒ*ü©\*Úö!Él."Gr²ç‚æËµh¯üa›Èíx²‰¨ +·°	3‡i(ğÌóÂ~˜>W¶ä¦ Ã›ö4
R‰Û›R›t'åè¤q<<ê kœö:íÃa,G—dœÂæ&fn¶Dõ%jPÃß”P“XpŞş9ää></™’Ò—s$¦°,ßòHˆ•ØÕÍÒf¥Ô§(&]s|aN©p‡­£ÆùÉ ¾Qj›/`®E¯ù½”$^#•[Æ°7Ş÷îî“W™‹üŞ~+„ÿk×ÿù5#&n‚0Z6xÈ?¬|ıw·şto{¡ş»»Wûvşû/\ÿcéW3¹ùÖIz\‹Ï$~Ízp2ßs™=r(¯ír„xĞ›»Ø¨‹ÇÄ™ÅÅ%¼®V­~¥;â®	$6Ÿ…Ş¹E/¹ç!Äl7œşù³şoıAëÔ0ÔˆÔIc0èİÚÖKêZ^pÍzÙ:;ìô~¾ÓÎaËPk{{{ğpÜëœCêî;ÑğªoİBşQ¥¢üá}Ú Â¥Zún]‹c§*oB.ñÊ'’€ÎBğDãÅ¢Ìwƒb1ÍşÙ—JKÊÒ—+mkºUÉ¯ŞçXËÂµ~‡)_EÎÂåì*_é!šE@—¨o†3cuqLóòQï“Ã/Şˆå±{<ú’OlQ¡Ä<Ì!ñ²00#5j¹}ë%q Êm×B$(šÒÈ:yŒÃkñôÚJ~@È2«^ñRsdkq÷‘Séu:ƒ!J¹îZºï˜!¨Ãœé1´Vé¦%·FŒ	c4'ğÛrªÌãqãáîĞóHá L×‹‰Ú©ş¬ûÅ(.ÔE·ÈeãâK©´¡EùM?—Âˆè‘k‡Œ·€(Ni¸ñÉ#ô'Ÿ1&±K hí#uá÷¦¢dÕÖ!$q~@Ê MxÙHrn€õ DÅ¸>œØ.µ]¼(»€s
IˆŞÔŞñü€ßÆ¨'i½"÷`šRÏJàdl‚ñz
j
[…'J¨Ÿ Şô½™i­%
ÛˆŠ]ÉrÜ8õO(S‰*Ñ¥’ƒãjhÃ²@´º g,ôº‡fUÜ¿ã)~ùoT‹L«Š.‹×†	(j+3jÙXÑjl$5^)Ä¿û•ã^ãğ¤%‚hm wÚ.Ø³|Û_#úÌ1İäxr÷\š>@]„ ğœ	è+Ë»ªVäe«ÒsºµpÑ|o¥ÍõŠW Èbš¼õ§H§Q‘ŸTòË/„¬ä}ÄMCf-Gò ¢İ‘	AÃ¡¥†cã31.î÷½h¸/@’3fM…°òä·’õMĞ,Â_*ñAïçr§(c/ÉGoÂ(Æ}g|v+" ğ>??´ò£”;X”÷fÒ±Èl€¨‚ó¹ôÆ^Dò—ãÈãàcX8ØTD¡­såÒ á8ˆ[xr~Ğæ¹ÎM|XC‰ô•ß²€8â2¬’ó8<‹Æ÷,ĞW2‡RŸlÉ’—V†¢¶‚ÌDƒ"»kÀzåJŞÏ~­W<^y–l3óCìƒæ±Í•ıÁ,¹tóà”!Kê­¹5Û‡B@â·ºÖ^›Tv‚†¿4zç}|MâÙI‹Ï“•8ÖØ€e~,³:y‰$i”´ÄBO·&7cª¶-Ûâ5¸jøƒÓÃ°®®6O÷Ï’Ô&×œ&¿+yÌõ©Ú$Ï€'ì(±Îòe4w5Û!÷XŠ¢áòmù*°C¼c<å¶1};Báí8öÄ›¶E#·ˆáÄ¡!çŸ\Ó[B”;JTb¯Ä6P—¦ê±¸ª$¼Bzì’Jµò“ µíN¼}4ª0*mï/˜´Ÿ\yÁƒôŠÆ}Õé½èC.ÖÊàâb5 Nv–Ìº3&ıgù~p¦oİcˆ(šó›gçä0eà5*bâ³A¶béwÆÓşü3ÁgĞéœô3¨¥&xv(÷J¼S¾ØR‘¶3æ¡°ÓÒÆÈ†;‡(aÿ¼ÛíôÆ=B¤Šäò¨¡CŞ¯<Æ¯Í$ñ8ëÚG¿ûä.(¸^hOn4Áû¦Rz…Ò¤Qü¢—É½hÒ§ÆoÆ‚¨¦×3fS1»ÈİšX„€ì…Ëá[÷!™’}R$ƒoİÕ˜õ­)|0gçxÿaN¤¾6.Èüåä¬’¸UŸı3÷ÖåïC:ÏÃWH×H¶,,iÌ©Lã°9ôøë‡§Ğ–Ü|Wèé$¢›¾ï¤¯x¤‰JyÌ´ğ]ù¿ğ†00ÏHÏhğ#¾jÒŒÉ3šù"š¿şÄâmMŠçöœê¾(O1I¶×›67ZÌ›u‹²‹Ğóyú—Ù÷7‡¢™´ğ™w"VÏÌ95²ÍPSO`»Qn]ÓqîØ´O„fš²;7ƒM$÷Ïš±°ãª4„Õyñ—±ã¤µÇèËòp0¬[·¡‹ñ`9ˆØĞ0Û¨B#7 ÁÜvMÇ˜˜ [¢éÆ§F#Û±˜M‘)gPêx>^Î;€Ù–!¤áBq<xqp|Ş^ÛSàâp¸¦ÈuÚtLÆÙ}
ÉÉ
éu¨_kâºäŠŒõŞƒôjâ?E÷Ù.–ÛY9 lÎ·´‘¦ÂF¬±]ä{ÆEaRÇ¼«|AoÀÊXÌôƒ®Xrè( 4~v ¸sgÒ›nàù4oö÷_k/[Ú,å’¶®CÊ_.z—íß¿÷CLCxÃKÓ‰¨Q¦ñÇ×š¸F¬á«Ì@­vèá»àF¢øJÖaÑ©¸«áiëì|Ø´N“ÚS¡Naf™ùášƒn¿°¦A[<œysš`åw@
H‡7¶MqDĞIúò×Œ:~uêÂ~Ö´@®uvÃB:×øƒ6l‹¢öŒa´X»AÒ6×"Fƒê,œ;U41)m™:	kn.b¨^ÏO²Aq*Ïg‡_&V¿	YE:4fH6ú,o2;øÆı/Ÿ“I$ÎáSGĞ>kóƒ—ì&áW«D™eaUGí“ l nQ2¥íz,·¸{òk˜w±†ú°V—¼Är¾C<ÂŠ´†ÇóiV³LìY.Š‚ bO–‡Y&1uZÈ”Ò{óÒL‚Yf<Înı¾¿œëØ©Un;İÖÙ¯Ç'5w÷½u¡™sÂTòiƒìíŸöÔÍxfîTà|hÎÊm9GÎ›{wGÊĞz7¦#J<¦;ã'J—,øÓ¤E9©ı6ùù½¿ NX<Œ}ü˜ØXC=€¯?!j`ıÃds“”É‰ùñï¨°	äÿ& Ù¬¼Dîğmnè–òÖl¥€0=¸8ˆsUËs)¿÷É_d¡sòÀÉš¨Òñ¶];”¢‹3zÕHj¬Æ¼W©N¬Löà¯@*şt”ÖÁ’3¥aüÈ ì­ØŸp©XÀı+¦|)o¤Î8â=Ãş\À»ÓÏÃ°˜ğø™J²ıR—œ¥”´+¨¬Nÿ·¾!R‰° ÜVL×¥Ş`È!RÃÈqb6óğ,MÛaåú44¶â:ŒO>9 x*nœ_wã:£–ŒàW™NÁ¯ƒ¿EÓ$U5v¥Õô‘Õ‰ëş;…/l€všÑ5—¤O®v$CÕ¥Ò¹ø×F¥…x2•Øé¶º©+®KW8'*ñ´âáwÆÂä-¾a½*Y„Ö±±
Ê¦0§‡jq8³2°&jkTÉ•ûä.8ç"¡U##Æı‰š\…_&L²fâe–‡—²YV“SJËù%†	\Ç((Õõø¿V—0§†×Ò¿CÉ¬/`Â­ÿĞ«,%G»x£~ÊEÕ¨<MÛ!Z½~“ˆO9š{xAËÇÿvB'|'hfÊ ÒÓX.”i¡äÚû¶î6r$Í}Uş
8ÉiI^“)ùÒ–åÚ¢«Ô%Y:¤ÔUİ¥:<)2%g™·Í$%«ÜŞ¿3göeæìÃ¼vı±€2‘$¥’553r²“™@ Üˆ/ô}0ì.@™Ğğf8Ké×ÿ#.ƒ_¢€î`QôAH¯ÕrpºZĞ¢RĞzğ"3M$ƒ@54j¥/h•—kC'ÈdqM?à²Ÿ¤£˜[¡¯•Ğb˜tíÃP¹Óşá_½vWÆI g18l/•ÿ"š*)°R¹ŒÏ‚ÙùTá×WVæ¤½/JTÈãåo;Ç/©6›p‘Á´7#Ã†¬ÂÎ€¾ğk9æ`¦Zß/l“+gÊ•æ¼¬®fT*³:Y\YÖjº=Kà­ÌƒTÎºŠšß¼İŒÕÚéXôéOµşj.Ñ¢œXgN­©‹wé‡Ò‚÷-›ÕÀNÎVÃk]Ï6¿0MÊÉ~<+:ê%Súš…¾sğbøgdè’¿Ùqx.ÎoÈösËf•[œËÌ«°‚ÕÓÓy—n´c²¯1¦C>pãYR4Æg?ÃZ»MoØç‡A‚ÿú1ã´àîAÒøû2é«Óş9?÷£óóô×l"Ÿñ¼ÙˆF=|„•-NúVÄõ	ıUF	Û¢ğß?Ç¡üjI§™ŸÕ8ù™_¡«|Bw>ã1M£ÉÁÔL¦Æ£NÒsÑ“L!îÉšq‚‹É &ÜEu2åØòGœu/{I@Ï¡jöl£úw‚´H0šrNÆ#™‚Ğg>†ãQ:ü<ÛŠˆ3ğˆ
7~„ƒ~ŸAªå·@«R>ıLB=©³©~ä'ƒ7ø	¬|W›|šôÃ	ı;ëÏ†ò‰F	?"ø>#àôÎÍŸ ’…ÿQd¯ƒ61Ò À‘'¸:\¦O2étbpXŠ¢-d/'ãQfIEı1‘\8ÇñÚZ´³±½‚¨5Æ|üÓ—m8®¯o¶‰’JjüÌTaC­4k$Mµôê¤ò9Ó‹mA{2ùÌõ'3ÕlŞ¬nVMI‡&üyaJå>°ây©yKTj?r=Æí¨øª;›×´¢¬‹r®ÖØªÊ©mƒ{Fá~é´FX¬
½¨v«ò.è`XÙªÖO©[¡Ä{n6\øJµ—ôWnRÀÒ½0Ÿ¨i85È—¬“´ñúJ¼Á£ôÜ#R‘!ÕfÃATŸM¤3˜Ã\—Xk¢-™)£ü[&× ï›§’%Ëô²²…X jÎ´Íº´ZäSiáÃA†¤#Ld1#OH¥³»¬xˆ7Va*ºš, "Å5_ä×Aw:É%ãr×i©<°„*ä^”!Óë®ô‰iª)HXs§[Vüjbè‚†Xã=SàÂôÆÙÉ‘ù†IkQ›ãK+/¬©•×KØj{§[I.E,À0úø¢Î©…›%òqødd¢±Ê{ö½İ–4Ö+	ÛÒ*½º7–†›\
ûø‘ÜENŞr–\
ÊÄ™ˆ„ÏiV(ì#Vú…ëf*çœÕIîë;»t¹™ ·3vo²	™™…)åWKÇBUİfÆÎr™ì’–¿­Ëßô9˜r+B@à7\ŞÅM }˜9{—0˜ä^-N™]‚Ñ‚:GGhBöwî2Ã†?³ØØùÇ‘È]éûaS°¿e†Åx7á È~–ÇŠVÀ×«İï²1ü	À(ñø|èÈ÷ûøš¤&^Ø@àë¢À‡öÑß'Ù÷,$ÍFı[q”›í}1@Öu¯·†›¥'ñçwH¿ˆIK9Hİ	A÷ùLºÔ÷¹¾T÷jE.s?Z‚Ë²)%kÊ
Ë¤º­¥8;Œ&É³­p`“¹Yï 7¾TâÛg­t°g[ªu0¯™yÓúœëOR4¤Û7ªh§*HIjVrâ£{œs;%O	¬ğµğPâĞ4
—‘jF¶üš!æÃy9‹{^,=zoAÏnKùÛÖ™Ñ}Ûº/3¿¾f½eD—ån—E:n]@[†Îßq¼U^Ê'¯ÌÜ7.Óñ1_û)»Œ+–tZÇÇ{ï¿é§ô¼zËmüµ—ğ±Î –Ìq¸vIR9Wkı..¯´ÃÑtÇ-]åR­ÑI«œı ş.P)å'µÓZ9W«] ¸4HòY·İ	hWÀ›¸ƒg½ÁÎày_pÛÜòWàóıÀïÆ<ë¿gRãmğåKÍ_]ä³}»œì»}Ë¼Ò‡ÛûJ~ëÚ<Ó†‡ÙS.…Şoì)¨Ëü¾š×hg}7ú?ß ğ,Ïıôq½Xé³„ÿí<øüwî¿¿¼û>ÍÊTÍÃ¡4P“£šŠZ(NMÁÀ9²X [*Š·*ƒ…²erxsûvÌWÓÿÖ, n×ıs~übéïÊúÛfÇ¬0NÌ\±2á†–ƒnJé‡âñ¨e´"£u±Ñ¯¦ÂHàjÉ(^öãñ¦«ĞÙ˜LÂ&Òš¹ì€•pâ˜G{âÛ=–°¨KbT`F<]WĞõa6ø¯gKÇî!ç|ßÚzÿ—9¸¸+%wAåyI÷z¦©¦¿×‰m›’ÜßÅ÷ífû¯)aµ½,§_W	R c"úZç¾j”KqÖÊ×W3(¢¡/1&‰Ìêå1êÕĞ$‚ËdI(‹‘Ï—òoõ<Bœ’•Uşa™$¨¶¥zJÔs˜ÿY'¤|$ë€»&Ê‡şºú½ââ¦Ğ	È ]ıÚŞV%^‹Q“œvS£'D—…ôPV$„Ñ–şéËªÓ·`şÉ­Íše¦gPqF\ ĞráßÏ—ÉÊ-]šBüê«?¡^9wûõê†Ş¸+Êrü®òÂÿÓëULÉW^µF—Q<¡ƒÚ!áŸ%øvâWû\R
„ËîT§~ïjtW“ÖİêêÁ|„„¯}&%ïˆg£`jREK”Îûªæ¨ ~yU“Í Á)Ç¹:­¤Ã”â˜)âÕ„6o~´ÌÀ\¯{„@O»jGŞc¹¾L}}qt$“ê3fWyM¹áwĞ´$-ÀØšq]'ıuBú‡µec~&Àø´¼=ñ—0^÷WÖÑY)Õç°¬ó|U2äkæ+ ·¦IàM`³˜@ÁŞ@UH	lİ´àx‰•’‹;É¥hMêìI)zµp˜Ÿb=Éæ”G÷ªÃáVVMI­xÖ|6Jò0]–L¼E‰ÑBĞ=(í S:äš_l²u"»tò§‹kÁĞá¿™å4H¿ç¿Îo~Î£”êŒÿe‡œ¿Ïø¿uGüß­úÆÖşëşëü×Ëÿu£Z7ñ_ŸÖè¯V˜ÏÃŸM³Ø®Ä‡‰ğ“Î	…8€©G¡.ál79„§ïÅÓ5³4ƒd1÷„ñê%@Üè4EQ9ûİ`Äxô/†6:BG»~Ø€h * ·ó—~8 /ä¿2x©×'¾bD~ø*šólÊ¾ç=41"i
{ö<ÌŠ!åF#z…x¸ÂË\Hì{ËvZ2üEè«ËÔ§w^ˆOÙ°ÖO}Ñ‡‰âñÈxÕÈ…«@h3< ‹¬>mN³Ï'OÚï‹ÇÄ5ã®\Çf“Ê½ áEƒùÀHÔÛDKä­I§³x›D9ÏF}1E]à+úéåêAˆPƒà(µqgõıáûÖªƒg6Ëür#ÿ…n€#ìÉ†Ù)p—„ŞLsBÆräÛñš¨u~¦Ã•‘‰MÉÕn²"ÛJzEQRM¿ÄM
^
â‹D0+¯ê7q’"å†SBôÿˆwo%[6/aŠÁl‡c÷Z·:öÊØAegw}İKä'6=G×PôøF¢ôop£ÜY[wÀ?ü!ÃDÃ:hñØÓµİ)7<}&ÖoU0¹¿ÆŒÖ…–?Ãc­vZ«‰/ëf@™O $%P˜µ¯¶RbaF^9a‹¥hôcPù¥YùÛFåÛ?­Û‚Œü0-ôÃEøIƒ	ÌÁÙ¡]¸7³µJ jW\?Â(Võ¤x\¬õÊ‰ãÔÒá¥y¶¦êíï·váØİnş©Ê¡lÔQiçdÓ (+ó9œ©ÎqZ:Ìe^äm*¬{Ê³şna2ÊiÚÄqpƒTDn…u
pC¼Ğ)¹ñeğ¦œ>s3RJf…TÏ©S•{)3±¨¦8Xp-Ãè9AşDÕ+aRzC0tö$HpÑ?»F’";Uš”AzèÄšbyn¦½'\±¬r}[ÿÖ3fTú–·+œ÷;åMıV¶x*§MXË[W%uœ„ş(K õŠ5"ÛVÊ1¯<<(d6è!3‰ZëõKØh—Gã#“®îqĞ=dÇ ÆÄˆ@ô“\3pï9—ÇÚw Ü0Â
	Û	:ôÊßÔ7÷ß1d§z©¶ÂĞ•cß4LŸ;YŒZæ$û¹ ^êlm!1mˆäxeú‘È„®IÑÍşéÌ—Ë
 âkT—ÉØçeÊå²}œ€µ¦¢æ÷ÒøÓÑ­šïÊ¶˜%¾œÃaA6çR:*Zé¤.%PtğéZã‡$#•Í”0ëúÍ†ezmøÛzF[­	Í‹õ{NÉB7kj©ÍŠ¢*‘K"µn?ÍkÓ»â€QÇÛñà†ãí73Á	~£‚)¦epèûï
Wjt3ƒWÉ	0«=Oƒ°Û}DãÃh¤%´ğö%–±(Á!ÖØ=V‡^BôÆÓÙl@y“p0fp€R“'«+:#lKŸ"ŠÅ³A9À¾(Äãèºü"LNG-8nÁü®V«8„^ÿ¡ìÂ¿éÌD«P_ÇÇÃ‹vîdÚ±L;(Ù—‡ÀL÷ÿIº…ñ+ÿÇÚÜzÕÿm>m4ôÿ}õÍ,¨¼ËøO¾9Ê—ôôv²äKu}¤XaB:àS?EÆ-ä=éÿJ8¡fo6Aÿìp%˜lÈeßià@8Ÿ[Úà9E^Ât1÷iùZÒ÷<k7Ï•bëÿ2şÈuq8èy‘­¢°[‚‹¹JgI["R@ÚèäÄ`ÚÙIò¥
ñ Iá³ƒÄŞË63¥c+İŒÚ›I¸î¦€¿’gd¸¿€k‡28(_)YŒ#ïf‹V.ê…Ÿs³Ê£úçR8¨dÁÕrDèk28Öyô)¡É^GòÁ?æ`R[Jå`*–È¡î#©ĞÕô¤÷§üI/m¡+²­`Õ/™¬”­JÌ(‹`ä"§Ùµè4J¸‘F24RxF%r‰ìñæ.ºùşxa¹˜f~¡2…ë{N;Ó`:K Ü<ÓUì¦İmÚ¢©€ğ÷ñI‡ÔÜZ9C'‘fÈF¨§ŸŞv¿9Ùã	/¿(]Ğ¶’Ü­ht\{Š<WÔ%FúD=€ò/pnÎù×ùõÿÁôLÆg12ğ8>H='&ANÛ®ƒ’0‚¼öĞO”×ú“¢2åúºRÉáîX)î¢ÔÔ(cÇˆ`2­@oèpèlPA€¯9¥˜C–1Pƒ êr¯ÂğÑÁsÇ>êÑ ‚H<Œøüª~«óìŠIAS!ıRtºÌ'tú®#š£.9(1vìÛaïc‹¶PlDÔ¹tõÕ0t’È;‘|_±Q_sÿ¸Õ~ß<ŞûKKG#Ô+Œf6«Õ­U‘C"t˜6–qÙ(‡;…%Zãİhİ£a»Ğè`6AÊ‹Z…CÁYÿ»şbAŞ·Z»İ“#\ƒZ¸ìÔÓxïÑ'±EÁ»ÃI8úóîwBÖOp…åÛKÖZ(¤àø[7€wÅ—é×Uwdcs«³ó÷A›íÅK#J·ªîR„$\½°ÿDÌÚùs½	ÎÍKo¼SV/ö;Š;ìtÂbŸŠ˜I;9@‹kúT0VSİ9Ùô‰­İ3˜Xb‚Ö>äó¶oÎª}”ğ*š"½”“ÙÒ°©jiaß}Ã‚çQvÊ¥,ª¦|&Òİ¥Fá”Ğ¼iù:‹Ñôú‘8¯ÂÇxâë«âŒî¥%k—û¥yqÇ_:ŸÄ°©]Œ±‚™ğ}ãò¬Ê,EtxÅİ>~Ã[
(áCJ«ûX¹şÍF¯âˆ‹lJO}Cìä“‘~Ïn}ºMàty£9èB$A$ú”î×	ÆjàdÆ-LxsäZ8	¼î˜8ì‚7-3‚ôï¦IÆ†_ïG(¥R™Ìâ‹POÛ?VÃö$–HY¯?¦L®4I8ıs»õBÒë<˜¦¾f¼’]~sO¼@“­.öŞ>ñŞºo®Zqˆ›Ù¤ç|²IñÆi«•té\K¬¹«ˆöG•¢Ì‚˜¼×¾ŠğB›î£}(Î—·ÒZÀ»ŠHo@£È’lKj9¤Ú½PH„ÉOGéx2ÁeOZM°¢P¤M´òš×Á?7ÿÒdC¿œ&Ó¥Kıƒ"#²ñJı°¤TÅ²¦b5l‚¶q§MÛ>L%ïôÃIâÉ»!êîQÁş'ö²´­ÏØt¼Şo~°%¥ÍìÙ:'@xÅ'‹Ì0†Uâ±Ğƒ™%1•$˜LivJ@dÛæÚt8Á•Ï™]’ÍÙ2Õq'ÊÈK¹ù7´’ş®ãç®°B•´µOSÒcñ
NG©sày‚–S¨Òs£q:İc_ÑHkçÕ Í®
Üj16óô¦ìeR{hQ¿Æ½?º ğ¤	keƒªŞ‰rÉ2§jBqtvjôäH–3B£^Ë³R]6ÂgFx1ä5õp¬×r»™Àõ½s}0¾ªÌF0æà¡€Â¾·R(§İuœvçÑ§Ê0JP€»1d%'‚È=Â%ùz¹6–1òMWaTàÆÜH¥`G(ÜÛœ±Óçr^àşÄÒSå±|µî¸V¹+ê¯[tWÆ¾€U;	èÉ³–e~…‚F4Šz ¬õÇücNãqB~AGüÎQ™káMë²Ó2’ª`”Ÿ.AnÛ7¿rJŸtZ]!gs>å/f@­óU²ş’b¨£ùM6ËI{G™7^–9b¼Úò3dOG65Şí54?·OW0³: úAó}ó›V»ûö`ú¹İ<hÁ*Ô‘‘îµëú¶v]745İãfû›Ö±/¬´„œ’pŒu
ÃÁ/¶uÎ7'{ûÒqÖ¦ÀùÙDŸ¡á§ièzlpÈ'èëy-SX…IÜ¸ƒ½÷fyT«Je4îR (Š&½ºƒ¿£İ<Z¾õ9‡…/¤«K1G’¥ó¹+‹ùH¬ª\ŒÇƒPşÓª×]ïz¡$ÊÉT},†æÉ,úÄÃiw ÔG‰!æNL>vÉ„ZEŞÌ´®¸ãğWNÁµL˜}Q?Wæ÷sen?ïï½m½ï´:Ö´!ÅL ÙØ=Ğæ²â¶ŠH„—£4øı9É/­9”ö¿Ğ"p“5€ÜÓLvl<Ìİ¯:wçOcÎ¬+%Ê7áÔ¼GÃ»
í¨Å{wö<••ô2¡ÓòW¤$\	1xM…A´Ê)Ãtê¦Q+ò‚NI‡¨h·ö[ÍN«V¥è7±Fô=·>£³»€bA»€Î]ÈX ?YÜN§R:]A-Hg77MDYWõ}^ÖİÔÏòÏ·)úóø8—êH¬6¶…0'È¼^½°G¹@ÆÏŸ3£ı†(\ñï)nÄÅËá¸È7@5B›‰` T@â&#PÕó®7	ë“š¢Xye`LSùjáT5æ™c‘ºİi¿íî¿ÿ®àb@”H“vDŒ7œL•3•xBÊ9(hL˜SÏ.D9¥/>y’w4K°5°ıË;<¸`Ü?â1¼y§‚hºY¬Á¢¼•R›ÕUæÜ_c8ç’£vPyQØ9Œõc‚–Ïêçw/“íF©©~æ	H
EğºKGÁ5¿7Ô’6ÙÉşzÊ†‚ˆ{HÛºÎò|¹Æ8j4™şº:àb1åÏú;ªı
&ÀòãŸo¥oÂŒ¹#j¥ÄXÏŸ?•öeÇL»‘EœqÎªE™”şÆÉ±âI{»Jİ¤VR9y'
/^s4=£ÛÆ,c6‘U~ßôrD©<’„0‡¨uöŒ§p·…	]ªøEsE™—X]ºÈja™V‘z=Í8‘’Şh4¥m˜ì\HIíæÄ×±jM-Ü0¸ˆzÇ°…ïI+Qh;Æ¨cèü>»†5zdªpúë¿ÅÑİ;@0 Û…ˆ4Õˆl#IÆãÁ[!P•¤µîX8@È`áÕ®‘ŒuKüúêêªÎªÁ$€E‚â_ãÕ&ro~ŒÉ^ãpÒ˜VÊŸ‘Š4ûİ—
¤¬Nƒ¸úéßº°+öõU¸¾×¼keH°Ÿ.ÏeÿaÑ;99BX_3xíæ'Cdæ€´·cs™±kŒ¢VéE±Ô8!ÀÃ)Y>õ£Á‡€!:ƒ†Xƒ‡hlg“éº9ªd­ş¶wä”ŒUœÅÕ+›…½2ıM,*š·fŸd¾gºÅ•[%¹kÈËcÒƒó´W1ˆéİr'K6åz´dĞïÈó@NôU+JUÓGx˜•:À€KT“ùåã©ÍN±b—¼¸<aÃ<¡C²m5F»”iÔìX ©ÒI¶6ê¥µÆG5Å5ZÚJˆõâpÃÙh#Kª1?+”._–˜£=3œ	*©`…Ng)‰HÓC1J/©P$ı¢heöÕªE!•.2µyê®U†§W"qÍ	B¹µ¹¹ùüÏªğMJ]óS`±ò@8W8äİ4•7Óú+£A?n<­6ªO}W"k“êª¬„ª‚l[ËÎkŞî»’W«ë¤+Ã?'CÚ÷Ø;fgÈqm%ÆYš7 Ãi»`0Uê7MswÖâ,÷s)¿ìøé -[]%Çdşe*k3Ø¥{!Õ)Ï›ÙEÁ•Õœ}¿ûİòİ`$şé€ç¥PF&Åõg5Z-D¡":{ßì½?*˜
·ÀoI!?AˆÏ–`ô‡y2[X‘ÜÉl©ª›‡eÚ‘oz0¨¤Üà–òÇ“á´NéD_%ôV®ÃDü]T1àÆ½ˆà[ 'Ÿ£€VİœÒW½¦·]€Š¯VrqR¸ğ£Aˆš« š>Ñ
+Ü5O}Ù¬rb´Iã¤"¼€BVÓ$Øv’ ­!	‡‚Dg0ì4ğa†´ìè·(ù–axšß¬~ó[ü{l«¦ìyÃúpĞOF-³¾øLqÅdô%s’;0şİw„îlé}¡ıİ¸]«Í»;Ìeä‹ÒKN5ç="…ræRBVöŞp^9{Œ¹‰³7KfÈİ?ÎáVñ]d&X€KuÄç#s$/^âõ‚c;-	çâzÉ™”,jŞ“EÍp©1fË.ª'ü—ü<~ ¸å<
´jïÅ•GKÁ§bmÆÛ”ô<!ÿ"Fa×[ª=æd0$dUçkD$ÂÅ¶I#S‹Ê,"K44O7?“È}rî¢ô»©â¼:Şné´Oµ|ê)¸ïŠŒ#f^YµÃIÅ°¢f¤¤üŠú®¹·/WS½€úÓÂ44ğ=m
Â ÖÊÛLû¥nBÒçG4ÆçÑŞjG\Ehz“Pºd„}l8Ó:®Éc]z)`„³@8T^î”%c³kaNÆéÍbyÒ…Á¡À¶?óéKfB1øM¯[Y"cä\sç[Én{¿Ç†@g\¥ØËôQTÚ…\˜¯@ËfïÔï÷iOÇB¨G¢îXtWoéçŞÑ˜3Ó:H˜WíÙn‰¼t^iËî(ûİ˜^îl€|Jè}“ F —{¯öt¸é
;RMòë¿)(&	9Şôäc
º!Ğ~J5p¼ª˜ôp'‡‚b*;ˆ¤õ> =øº(™?„]„4ea—á@iª!±$ÄCM‚Eœ¼B’…(HC¡3Ë(ZÌò&*0GâÁ
0ƒä4^:ã¦¤†ZÖ2e9Ë|G%Š+l†SåM§é‹›.ÒğCvt3â6²t¨Ö?$³`ıÈ¥Ê-å‚%ù½Ä}á[.ÃÆºK¶›'íc¤İÌ<ô¶Ï²6~œå
% ¯nŒèp£j<âàyèZÁ KC™Pú'8$‡„2…!å
Š•®¦	–àèÖ<(ÿÉK}¢í/æ¯TT
fŸR—3+¨”LjßÃ¤İÚûõßò-„Œhå4Â‡Áæ¶Úlí‹s£†$ô0ïƒ_`šã)œÜ#Äx¦QPæc2È 	qH§ùîfw£»‘iH›ºdnQ‚ê¤•aÉV!úİ¬.[™ºÜ°2[ê„©K7ŠŸ¬!#œÅÎËV$†±–Q†q²g’1sT!öñ\K
êsŠMœ_…hoÊY§¹4X÷G¥Pchù ÃÙ/Šµş¼LÎ_ØçLÎ<*ğ€3½`Æ–3¡iÊ)Bw:ošøÛBÍàŒ½\G™kvØ8#MvÇÀÿß¢‡Èoqı–ÑŞDœ}åŠÈô¡©ìOAî¦:4ÏÛÛ%+µÂh]Òu¬¹ûf:>é‡—¤÷F÷tì¿ıñËÒğl|x5
c³åZ-–Á,@æ‡FÊ(ŠV*	†v,Ò;0KQõˆQ”J.x
8ñÃ®¾W8 —¤âı“ãPv°$¹g[ë+¿I.#Ra=ÓZÌ¯ç¾A0+*¬û\¡¼u·²‘eı©fƒï4ä3·wË
¶¶¸ÉŠ]¸IİÅ\°ÍÎ[•K—eI”ÒÁWJêÍfœXhFyo. VavOnò¶	wz¡èØ@æÆ¼ƒ}äkì	v¤TÙãx}C[û’ÜSà1}™-…¯ç×¦İ<F8‰z©³.^BìÑ»h*Yr{$.
ı´ìšDªÉpmø6(OQÌ§ü®Se=ã+Rµ|UUeLŸ+]o—hŒ0«Ê4ö÷Şîw›oÑÚñàp·èR ktØŒùh,7ĞLó_áŒ„Ëˆ:(‰k˜JÆ1Lİš.(qcEi|ÂJ,à3l´ı×gøoĞ×¶EÅ0j+yüJÛÀçö¥ÊÓmD#c„{Îı\yÈ5%/»óåö¶¼)ä)@Ûñ\2@)£s©öD	Z4‚8
Ğ‘†¢÷ C
M¥ŒĞïŞ‡«kÖŸH-§VÛfk‰‘t’éøHj)çìN™½É+ØŠœ»^n/˜g–ü£q2}+#¿æ¶×Æğå¿
şs• SQç6¿Jü·çOŸà?ãóV6şÛÆó‡øoøÏ7Æ.Š÷Ös¢8ópŸjg¹×ˆ ¾˜Q€·ªâÓùKÃ'¡z]c¶Ë„ìÕ³¸Ö‡K­ƒaß*\Z…Ğ>$íñ¨õWtÔ¸ ¾'ThFA–æ-İ´>këB_xö`ãŸÄá¥O¦°–¾=<8j·öÿJ‘²à#ª·ğe÷ûÃönçGz|‹Ï$cÎÂDÂ;~¥ü™ zaqS£/ú È+A0‰@ğbÀ›œW|IiW}Abúuı"vvDå±øÉ04„qĞ€ QU¾ÇY¬J*™K5¦Š›$ŠÊ;QÄRa¾_>GåF9ªµ›—ÂyT9sÖ"ğ!„9'÷ŒÿßØx¶ñ4‡ÿ¿ù€ÿÿ°şßÿÿ©ÿÿøCˆ±¹Ó‘¾d çNbí—(tƒ¸˜ÜSÈO*äíx0ÃxèÉS*á\V^=¬oo6†«êCó Ùníò§ø¶™~ëœ¼Óí·Í]ü¼¥_¿o}ÓŞ;–YêireÆ¢‹q|ëZ4)Ù–•°ù·“}M`+}Ï1²šğÚKUk„]G‹™
—–TñÔ•ù•ajó.@8ÓæZ{1ˆ¹`Šó(N¦„6È!œ*i^»€VÔìp(Í¢ª¬{¶å$/¡|>uÿïTáã¯{úø!ô†½;s–ÚÍ½¿‰İCè»7{­÷Ç-p:ïr¬y"6¾Éï+NÕ?ì~Óİm7»»{íÎş¥Y_äÌ\Œ¾çT¡ø4Í3¿oí¿E^¬y+ĞõrØ~±g§S÷bwwÉ?NÆWaLĞ»Á(
âp «Uˆ!ñK@)½ukÀJ¡ÎÑ•}:},aªÿHÉğÅ	aØŠú³êÆ–Ø?îä>¼È~à{ğÉğÑù–¨CËw[oöšï»ïÚ‡0HŞïîø#Œ¡>K´¼'1@5G­·ò²Òxë@ãİÙ0³ìï½‘Ø¬KĞ?ø•œ­Z™÷9ÈÉÕóIoÕLá‚Ÿ¤T %ş’¦Ì¡®BeQiA¡4º0O?NÇ˜–Ÿú(WÆô›Úmu¾;><Z÷šGÇİÃ£c£rO6õ£pZíÍ‚êì|8é?Mj İmÖ/<^Iî¥	 •ö–FëÓ\6àou²Ûº£Íñ Ó´¥'Ğ¨.ôn±h§^vÔ÷œîwÏªõjİüF¾qskß1I7^ğ‹"è°uo.ÖÜÏ
Ê9!£Ô!+RV^DÓ³3âãÏÃI¢N0*„4SrÁ!€—ù£jàÉ¨«wlØ;]wo·¥RÍ	êƒ xò¼øXI¤^_`ØR¦g¾ï:0/-ŠF-wÃKÚŸâñÏaoŠ6ş%Mwcœ¨É$è…f`±PØÏVóm9h½?éî·¬ôîı¥Lğ6ƒ.«ƒTU.¾'-ôõˆÚªÖ7pë±ßËë©Uş¼êóç/È½¸RşìÌçd½`Ç¯#µçÖK][õœ 	x/ûÕ¢&˜`;ş³æ±ˆ‚æ0îîTefú^»ÕÜ'ª¼HXåTã0hbÒñ?e”r4‘´4§âèlÆƒbAQKiáÉøõÃş»lNÜØd·ú8ˆM¦_Ejt7ºÏ²Ÿ¥®ºQÍÎ­<Éå¨z‡á$H`P{áUMR›‰qóª;#ÎÉÑ°	£¾µ¡ß y&Ö“4?IÃGå/ƒIÚRÜ©w_­›Å®FöÅJLyJš‹H±^}Q%JÈÑ†z œ}-{3Õ±}Øét›í-¿˜{À*Áı²)+Ş¡Òƒ~{t"İ£vĞ´õ°£I7 ’C*}’}Úß¾óñœ†¼0	ãáåóÀJœ=j·Şíı°ƒö*œ–ªazgå–®°-U¿‚ú ×ÙÅÉ†îô+vš€dPúıÊ„oüc)‰£{‡¯XÒ¦çùŠß¸yu0ùH˜¥Ñ0ˆ¯+|EWá®µ“rĞ€X¸cï7ş]UYşLSñ‹[UøkÖ£çI3K~ı®êxŞè!`<wï™°”Ú­oZ?ˆ¿4Û{¸vt<ïûv×Úï}|cÏáşËë_çhïø¸µ¦İ²ü™VÄÚi­&¾¬sÂÎqšs›(é°%DgŸêõJ?¼AììbúV(ı„ãIôélvn¼ìQ<n¨_0G.Æõôë§i2UÏÁô£ñåâC¯¢JÂ]ãb0›n¦OôŞ÷RĞöfİ&’ÙÙ%kåÄ0ø
î^u‘=tgşÙ(bíÏ‚}Ğ?ğ?á@	_lİsÅ¢e¤$øµHÃ
¡Á„o…<vÙrj2}öïşI½B€Gl¯/‰UĞ¤şÂ"ıã?é|ŞüÄm¤ O„® v™n{ã=bß7÷wèBDW2ãsi%â‘N×5ÈØäcÀ¿d„}õp
§¾Óiö]ª{ù1  ³ä§ÔÃtr»­/?'™O\@šù$rúëK¥IØå¦EÌı#ïëY‡†nR}6èè@üW…ä›Äµ6o­
ÌÑ´WšgHmÔ?şuqqÆXQyÇcñó,™j*ö\Yiˆ5‚&B•6zMB:5)ƒË  ªC‘À„]_\º›Ïh¨ËØpíH•Z’>ßş•Ò¦‹BÓG2Ás£t€,.Bš™Š‚:¯Ğùùrmqíq-…:‡é0.zö’ÏÌ†ı>ä©ò23U²u¹‰gÌ;÷ı©ßvÔò^U~rğ¦ÕÎÎÕ$ÀëE˜™¹š,qu‡×jıYµ®
C]™lØèt”¶åıxŠe˜ñ éÿøwñæZû½âğ–ıÅvçWÅ}Â÷³„.r&:¤ÆÉ{(ÚEŞNÙuvŒ^µgÊí½ÿHqûÿ*öÎ1†± Åµ™&!Ş(`¡æt'3/Õ2ÖØæ[ŠÂnèİÏjwÈsa]ª¥ 5äëßû€×S58%H5™ÜaÃà,ªlUÿX›Ä!nÊG.UÓ¡z àv@(ÃÒÎÉê,Å·-¨f»s'’öíšÈ§»™‹šhRœ’Vïñ˜¤NÃx.ãß/ËNÖèúÚÿ¦òCê¯‘Wì[äÕ'é,F½(iGŸ@ÆŞÄSv˜[ïÏß
®
øcë‡ÖÛâ¯†Ê3d²Të)×–<rXÙñº§3,‡…²Óx‘ı˜Ç5A-s•t‚2©Ôcgµñ¼JºÁ‚°«/rŸö;;õº% 2q¾äÊ©·ª[¨._·%ÊãljC÷FZÄ§´*™—9*@æ\Õc‚LAÏa,„ÕQ8…ÉÅ
\­<BCÎ¤&­-ÿ©±A·Uğo0ì?Û‚w[oŒ¯¤°ªÉ«›.Åº­Ô»”¥êUqE£kİ0ŠFÉ¼òñç?ŞşÓ²j¿_ûÏúæÓ§Ï²öŸõÆ³ûŸûŸö?·6 2†úíl€ØÖ<‘0,—á`<AãN.£x<¢g41%‹Œ{1	âK0yg	ş“}º•DybcŞÇÏ…ßş)»*<şây¼$+H~W6Ë–Ğ_&*	ÚĞb,“G‰àñ²¨-	L%•°w×Ëæ%É5•²@¯ÔµdäÃN
Ü>õ<Ã’\¥†±]‰&;6 ¨ôÏœÊöoåNo»©‘ŞœpQÚú-©.WVJuz“¹§‚¤ó=ƒ|QÚ¤·V}!íVĞŞ!fª¿øò_”¹Âûç¤ãFfLA$+uÓm·ûn?D³×>§ÌøÑÎl£øøe3£ŸG<£/0.ªÕª°ÓJ?QQ‰/í/œ$YŠ5—‡|ƒŞa@¥^%¦Ë\_$;kåÇëYJüƒ0*9lÚàxNiƒË<™+>êï2@ä9VÇw8Ç9ìeÈıŠ‚#›pLØ4vÇRòÂ‹/ãeCÄú1”zDe·¼¿b1¾Šé˜®(Í¹šÆk[şğñ²ˆÈË²rÈ7êO.§şÑÑéü®H}©M&½OÏ$Ò†!ÓÍ‰t 1üÅ†Ú·ï,ß¿ÁHT’ó¼#b&¬°iˆk(ëŠ-2JÑ])Ğ¸Zd/,—i³*¦)	WvXP¨\N']ğÏĞı‹9áÆ´W˜‘P-Oº`zG<’ã‚ û¡çØAC«Á+Ê¿k¥Dë9Y°0;i­Rª5C1˜ºã*Ãª[35b¿0aºNÏeˆæ¢Û.™=EM@ÇãñT_¯Û±8ø³•@‡p¢˜#=¶PLâØ‚õv^Ö×ÑpAÎnM.Ü¡3©xÔLËõCš} ¢axÆÊhØ5„*ò ¨@²¯Í¬%¦&â?lĞF¨~ı¿ı€¦°§Çä/¦3nA4ö46¹ÓO‡“Í»°W  À£GRU¦¯ÿĞĞ€0H
µ•©îS.Ù©bVk1qÑ7í›ÎÁ”€å ¶Xq:jÁî„H™ºÌ¹kÿ-ëŞt¹‰ç½Çm|ÇeUÆ›;‡»,¡?ÓíQ±Ndë…•4G=r÷Â0ìú6L$!HôıDÚÿí=U‡6i?áÛ¼ñà’ííû|‚üB„ÛÒTi}ÒŞÄA`;uhÎ6P,nax–+…é9¿‰VuİoİH‘îØ
F ç½­Ûw‚UTŞvş6ã	ZŞÅø.#U¿NIóì“_Î#ÜÙW«XúåÇ iK[ü»9t¡ÕxÚ?.£tÜ…ü¯P¬'…ªÜ¶…)=ª†^¥ZA<ˆĞ0Ï	M¹r­Éûli†±n ‹"}ßXÇ<½ùU½&¼tÓ~»Ãßÿ®~=O+(Ö†#’¹ØÎ„;ß”‰ø"É’ùdŠ§2®`šYÁÕE¹!Ê[¢ü,‹ºÏÍ±cS„§ :½`&)ŒsØ;’ALWNç³ûg#<üNáÌCÑTXm0Æ8[¸y"¸GPA_v¶[j@éTì ±ğ¾ÌvM¶·ATğõí&•¤=ïI rO1•Ó¼ÇÌ.Ô§íÅ¨O²CæÀZ[ØÒ)ïé%Ó^\oO’áj(¶Ó¸Á$.¹Zª8WK³@$v=]0 :²k©s1-\MË©\³ëÛŒá®‘ZrqZ[Ìa34¥ÑcÑN˜32°fBfWäÈ¼Fêeeƒ._\1šü¯Úİ6h¸=Ën<ğ2hP¤kc ÙmQ]bMHH°UT÷Ò
¯~Q¡f•„ª6o†Äáàh¨>*ÿ	!ÈÏ•m^ 4Íe0€uÖLyğÍ[OBz—!§d%Ñwˆ•ÆtÕ[FARí/üua-±Úä‰–I!Gác{ÖBşŞ*Š‚xdˆŠ9Z,m+Œr &AÏû=âôÇ½¤öUËX€ÿ2÷?õúÓúÿOîî«ÿao¯ıúÿycë¡ÿï¹ÿM[®ûìÿÍÍzöşws£şpÿ{/ıêã%ç-îñäbaŒT¿µ=å_¯UEsv!ê/|AÙp|óIlT©†t|¼}¯ÚùV¼o´<ÛNğT'3–«”¥³÷şğ¨³×ñìÚœÅ‚‚Ù<=Ãj£ÓóöOôóğvğ7æ^8Å•È™†éRšLô¹>ù¤´¢¬ú ¥kuZ9e±0ÿ†Eë}zØ²^gë=™–RS€w»­ÎÛöUÖ³¼àÑ~QÇ`D#úød}Eóèø	ö"ñ´”5­|¢/½Y£†4”é1¦MÕæTfE«”Iä9nˆï99VTò×ËğKHá^H+Ü+J,¹ïeX)ÄŠN52m°©sœ|k¾A±™W2WPQdÉK*s|m&³ºÓ˜›y¸?OU‡B®?çLºõYnE÷ 2-º‰a¬™Wl³G¨äüOÿû2ÁOBU)	+$Oc}TÓHã‚/Ø`X½Ç“½•vÂÔ4iìš¬óàÊ2æÁrXó”'	8¨„|‡u `l
„\F×‚ÜÓ¥ò73E×F[á£÷Æ38"r¦ì×¹öP·
xéœë
ÁÊª‹3¥][™/;Ş›¡ÁÍ-ã´š¨¨y˜”ô¼İnˆÁÅ®Ğ¤—Òü9	ÆH€ÃÍ¶“ãoÛ^Öb­O/ºãnıŸ?Œ§p, {úºçı‡?ÿşHùOÅ€&Õaÿñ¿667sø_[›üÇû±ÿ³¬Ú<º_$½‘h¨a¯¢Æ>“BÀÙx6£ğJœ‡Á”ìáp>á­«wI†y ö¦ã³0~"È,= ^M^{+¯’i<]¼~ßú¾óòUMş‚÷³ü½òj½ŞÃÛ¨ş¬‡ªÎ€JÓ¶_â¥x_[èw°®Î&ÕäÃ«|yU’NÓ¸ßFI=ò’FÔíaQÅ31Ó¿›ÑöÊ;®±”“ød ê	2B®Ê¬¯jXóW5h7¾o×1–o8™†Ã3”¢‹¸ğnï‡Önšd½"aú˜¥­d‹éåˆúoÁmŒ Tª&+”0GñO-JEÆ®Dl@D~1‚mçÍTEêˆWãI8R÷ç	–ã¡ HNrˆšy:´ß»&¥ÆA`ˆ!¢„–š¤äË#†6Ê÷Ã+ÜKuI»€}ßBÀL,bäP!âÈqœê…}”8³üÎ÷hİèÑ[w(Y£Z¬›õãy§> $J*¤ÇÌ>3gNa®¨X]ÍöÁåóšìï›åƒÒùÌ×0?°ÌÿvO`Ø‹0ÉNuä»¥ŠgşËa@§Ôe±­]­}ó!Ü&>›íêgJİæ+U!fĞ*ˆ¯A¤ãö<r…è¡ƒàädc$,=Nø&Œê8èÿ°¡¶,u&\YÍB"Ë2·	çDÁ7d’}Jì-ø}'#½ Kè©¾#tººÀp,äˆó+íƒwú¿»–ú––ÿ¶6Ÿ?ÏÈÆ³ıß½üyüø£³d²mşmŠ;kõu~)ÅŸÈçÉÿmÉ•J%¸LF‘)ÿñcÏ{üÕˆğ„kôœ~5‰CıCş±çsÔŒŠFˆğûø±R<..(ƒÆ\ô‘ô-j!d½‹^J¿H5Lúini·Î'ÒœZåfTÇø,wNócö›ÚUó­1­E
(š 7Ô¯å›•é.C×i÷˜üs—úÏŒ”Ä†ß¢UmÊ¸Å#®¸ç„°4¦ßg¸$Éò%d;ßLS lK(3R–t($h‹<ÊBª›-"àš
d¢@c[DÉ5†9Í5®Ğ4d”*·P—+ÖF¾¥Ş½éj%Ü*`³iJ5k4Ì`!)kÓOR-œ&À3v*ïÙUÑÚbûµÒÏ[Ho­@6Eº~Jv1ÿ”ÒY5QfLYpÇúg÷ë0Š8»ˆ…–Êº¨%ós¶_i´İ£uÜÌä›+º¥¦[ªºéº¹D\VIß…Ê9ñœÅÃÉAÊÿc`$Â!c&Tòİáq`üßØx½ÿÚxˆÿp_úßÃ)Í>êzØ•ÿ×,Œ)PM"JJµp¿Fp¤$´%*=ù†¸ßÃçãùx0_á™=j‘¤Ëbã˜^OÂÏWZ€CÄŞ!Mœ°PXÅIÚL}%Ó°kÃ«@|ˆÃs'¸2Ov5×iª×Ò%§¢Õµ³ÁøÎ¾@3®µ[Íİƒ{ÿµZæø•^å^Õ‚×dé=>?z¸Nm¯«–zJzåDƒhzÍ:Hša®F¾Ô5gâëlX'S\şM@ûyéÜ5È("ÌÏI8úóîw/DÓDû:”µFÅÄî†­5¦¨rı¹ÿ±ò¢kË‹$êîXw×!ß½eic¬VEñÿ.şñ¯ÙÒíÈú¢ˆ‡(¢#6[Ÿğ0èãz=(	YÙåv’\cÔWsG¥M‚øÁ—DDO¢ˆÆRE/1÷Şt5±¶ôd<@‡d]";.İŞ$4€ÁSü©U}úÁÄ›º©¨Ğ^“®LşÓ‘J<¼~ÑÑ*3=6êzÖêT= B
^ RpÜ'Pƒ81SôH}d©¨S"Ç¤·,JÍ5”û«x¸~øóğçáÏÃŸÿäş?CÉM	 h 