#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1940199149"
MD5="7df476b257782bb740bcbf57980b9829"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23540"
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
	echo Date of packaging: Sun Aug 15 21:21:45 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ[±] ¼}•À1Dd]‡Á›PætİDõñ8'{i×Füª›Ë÷|–Ãè?°¾T:»ºcv^:Ü¸°²Zß5© ÷)§ş(n—÷]8úÈ
/Ï+=Õ‡®àZ}‰²_mB#üìÎ¾ş×øb¹eØ@lÊ¡§%¼Õ<ÒGìb5R’şfº²ÑjN¸‰pšmp)Ãşh!í>khù¬‘_V¼’
Wæ>t¢¥^ë.R8ì0íYÎ˜—Ò¸f£¾c5cWíôè=dàÓŸM|ZÄ¸á•óØİ+3@Ä›Ï5vyğøåÑb€o%İ®•kYPr}ÜWŠ¨#4¤£Í¹G×{5xŠÚË\=?‚Ø6şc]:ş+Â²¾O1iı™ïÇ	#ø_óÇA¸İ-%ä5%ÖpöĞO€B+ÅÃ´¡€P tÍõß­„×–©z‘üf ÓÚX2râ'´ËİQ–²òıœ^D¬ô¾¦¢ÚÃ™9 ÈV¾_$7ÂKì©›ÜnZA5mÓ¶›ûÖ™K³~ºæâu¹ñVÇæ'·yÖ‰3XÏ¤Êù÷ù‰\l‹Æú@ï½ÁÊÄUlşç™Ê²Ã¸°¢jAC]{Ng@&=¢)Î•	sŠ–qãú£Îµ”œ’}`û›¯‰-å_ü^z_$ÍQZÃ¨¦‹ª)vâûËÂFÀ-?¥•*±t©‚…¾‰Ã}½f°o7++>”–:„²ÜÊßo¿3Ò*Ğšs˜Ò`Ş–=“…fÌ9a«É{¾Œœ»Áš[Q[Ğ©Û‹ËÇã+ÉY¦€±4Û'ƒëep²Ù>©Ë*Ûºıkf½îÒÅ)ÓÜ³BB²î‘`ùW,Ä[â7ÈTßŞŠ{%~\ºİ?›‘Á7p*Tßq¤ eW/£òÚ}Æ:–í	ŒKõa’ü à¼V«Ò>ùÀn›J}üNqºí:ëh½laôD Ûâ;0šg0+şJŸê¬H;‚%ZrâòÏ„ÊÕ^DU¤oõø—Jm-ã{Ø7bì§Z‹*'°¬Á¶Œ÷ÎÛ§³ëgò¾×ç94£†–v"Bê“»ª¥±øg8[í†»pÃciX{.İ9¥v¨İ4ÈÏZæ®¦_Cş¥lFŠ|pÙç¯•™;#»àj¶büè»m”ëP|µÅ7Ö§ÆsÕ9¬xÖ£}k˜ä\}ÆH\@8”–‚Dàá÷ nÕ¯GÂƒ¾*öaøÆ .ÜXIƒÃ(_¢¹·«|ÒØÖl£8SÍ˜vİ˜	ú=¾E=™­-hŞ-OQ—çs++(‰ˆŸà^[ÒÄMLMQË*‡˜Ç{ÍêN’õ©XôÉ`¬mMë}6_Hd0•x;d<âãx·g ğÀ_Ü¸%”!_‡1l«ÎOˆ\ORK~.ccnØl›õ7WüSU4MT!¾hÿïSmşQv
fè
Ì¼ö2•OœCæ,Ïy]—>PÎAÔ¥Š€²¸j¦ºEUã¨`¹™Gú!R:åÁ,Ûƒ½emŒ#×íä!·ÿZsÒ¡‰X Ñ¡q…7½Åır €Fc¼lS]Ôİ¿£€p¶NfiïÛØ©´>E#Ògê,Ÿ¡ƒ†y$L±j¹Qß¿<·ãUi»zH‰‚LKÉ³ùëM÷IyÌÑ†Œ¢,_-¤èN¸	HÂƒxN¤øöÒ=)èWÃßâ„#‰µ7d).yWoõÑZ›¢­u€F0‘5&â†%?×§}fítæIÚ^ZÏpş¼ÇÅ}é¯…›§ÈZÑŒæJ47€©Ş~—ºƒ¹a@t#Âq­Œã6Ê3›¢û3?š‘h†‡¼‰TìÉC°ˆğ^P”Örb¢£üLš ¤xÓ›ÓÚóµ5e!ø†Qç[´Š„»ıË…Ş‘>ì²<!zU!	?<İ&¾Æq¡õ¨©[®á¢…À8»º«à#XŠx‹‡çüü×•¯•eÙ—ãíèx>[öHò R`%ÇÍ|øÇå[DêfØ‡Óp ó·Ä¿i:ñl)µ[Ó$‹xÉU(ÇŒ×w"­ÖSŸu§5V¢­`Pø[Úe`õx%À¤F$)gPüW¥ñ±ÏU©×Á×Ñ?h˜™@ZÁ1x¦²N¦äSÒáé¬Ólâ`¾şéµc¦¤Cê€²š¼’Vš:İDÆ"*Î1ñrSyM§æ’›WV)öôÑ±¥î ¨*+‹¤FÜ>	ÂJ1\b§.Ó¥*ükNàhG…Ï1°å¡mÿ™ğtÀ^[l~*ü	Ğ]v/½É?Ä¶ÅL§y\Ö.»¿1ã 6ıÌèôW½ğì{p_YO9
–t@b»ÿ%Ô|.Ùß0~ÈÆyÍèƒ/pĞú¾Dfƒün´c‡=îÌ`d¿XÒ·R¿“Ä™¢{3¢Ôh“WIQ—j$vÀ÷üb;ÿÊÀ-	Ø4u?ô[İï,øÉx³‡*õCQú,­ÅîÃS\øgŒ íŸóxËË`hÚÉ©üf×á|ãójöëd—A°Ó€Z#BØl\Äà—6ˆ‰‚Œ):"’'bp¢ìtSğÙæ­<Lrp§3gÀLÆ;À™åéÕÃ5çF¸aÃÑ[ÜNŞb÷RoÀª¸ÕÅŒËö3ÌFSAÌŠdÆGÙ…›xJKguàièåÇšy -ñ£.Ò;¥ïğŠÂÏ6¤­ó@IÀ¯ˆgz0Û+d;iá–[rÿœGX2ÀÖ€_å¿’®\·]È(RÕX3Kş  Pÿ®€M¼R4ÔMBåIüY½›Ï»Ë¯Şd˜NÅE÷ã‘lÀ+‡lR&„a;‰Ã§¼>£Y±3…î-ŸùÈÉqÂ†é•­ì±šJÕÄÑW¤UÌ}ğNIõ¥ºş—E²Ğ“E,oÁJİë˜á‡ÊAŞóÿ¼nÌ®ÁüfÅˆcÏgZ}Û¥HŒ½­§Œ­$Jmb´Ğ´jôcs"4 :œ¶p>U«qa&UĞoô>&²Ñ£‰,û¤‡AWˆ<òì@uâs,"7}Õ)ø46Ÿ0´Nõé_OC©“„øR`VpŠí&²pWkxUÚc­A˜CÕU‚ñ¿®ÖUŠP1Ò<vû¸‘ZNyb¦ç:ûïR*Ö>Y üÃJºœ³½şËÕ}˜g%ı—~ªaFœ¡A	~”•ÇQî=l¯¶Ö\;ÍêüuáiY¸6šÚ½†aØ{SFŞZğ¿’{“î¤Ùmƒ	 ¢ÂÏ–ÑÓ±ÊÃü”§æmmÄ@Ç(]Wy°Gzïö+ğd"MAsƒåŸjuÜ®¡ÔÖE6B-©”ŠŠaÙ÷rf:Y¶'º2ÀüNÛˆx‹¬0ğ«üµš›Pe€W	äıGß
G¸/_[ºØR'nHÕK÷³;fñ¢ŒŸ’-™íğÿ»V5D_,áL+ÿt¨ñ‰¼5Ïÿª:¹};«Ã	±ÈÓ:>(^™,EcÎ•ÇFl;gbßúôK[¿éó‚Ûª°Ûjã¹ÆWuáÿæD÷TòÁà5·—z@Â©_²úKmíK’<`ÊÁÒÖ§:(\F×Xx¨JñNû5‚¥tÿF˜ğh#ë>?Ÿ’úˆ´êS¼¤cíi`9â´qšÌ½7ÉûL8{Ô‡Í16^/äçr¢Ä6tãOœ8áîFn!¨>9ıl“?H@\ºåÅø´Ù†-çv$Sı{eslãŠU g3O`R1Ú«Ó2~(\Fæ”‰|P¹c.Û¯¤\MÆŒQ.BFûÉØŸ5ÚäwÛC6ÚìJ6a'ıâ3—©¿ä}g1€Áˆïg~æg„wP(-3Šx^¤„ípL‘soáˆ,Y¤åÂ¨±«
ÄyÖ÷‘V½Ş…ÍÍu‡±LÚ\e"Ì&U‚Ûjü|°ô‰—×¡>· é6üäq‰om‰¨#y%ü^ÍÀ­G€Àu¬ï#òT¤Ì«X«4%x|mXaM2bÒlmı^RßiC8BKqøp gùl6Ë_u[ªÚoÅ.Ñ-YC“ĞÜ­º1ïŠ–,Ÿt)ÓdÕ_ÁÕ¤†hr¡YÕ—­;,3¦1\Ìıg	Àw%¸Ìê¥ª‰>	XøØRN-8W¶_§1ÎkTuè˜)(%á¥2Õ FœLad~Voü.ş& ÎÀg»_Rïu¤`Xi!+)DÁÜ§–êÏZ±ë'W`qpîî¨0UJÿ«³T­D’
<5Qœ˜Èı{cPG>İï‰\½w=÷DSy§1İµbNh~ØHBdã`²÷>Ú}ü„“Óše¸KÓ–OlBxrœ»*G¿b1}^&ÇÌ…˜Á§‰æ%[`ÉÆ* åàêARfºGçİyE Ò˜›§ÿd =NúL¦z)OI[ìfÃzÿ‹jRÂ’ÕÁ©‚áşGÅf¶ü& LtÊÛõı×†ÿÊRÍ²DRœs­ş¢W[ü¿ŠÁ$<}Ù€v¨ˆóW¤$öŠAákĞQó#€Å.©Í	Ä³˜Š¨º<ë†FM++ôN¥/ÎïííÚ®ÇVâô¬ôîè«tIe¯}0À¯”.w¾ãE_íeB’6GRõÿÆ¿VĞğŸ»ôí1ŠR%üçJâğïiÂÔäğúîWñøussî!¦eaHµeWÎ7‰eƒm*5-à{úM4ê•A¬Yc$Ãƒ•Ç‘o-ªJšì&t£Í¶íŸŞ=pÓÉæW
^*„\JUçrÿ8²®qZÉ)]ígº­˜#g@@ı?Œ,é@ÍôĞç¯1O¡=Y/aI&, ×¿]ºoˆOİİO83!«|›ÕitŒ<ôîZX¸İl¤ãŞp§¶„{ÏC=¬ïÖ¾Bğ,^DŒ’æ¬´n»[0ášëaæÉjø­÷Îèq,p¢
U&³ïXï=¯%=øÿvàôP=N+@;R©õ¬|çÅB1(I‰È,G÷,æ®¦~´Ä^££MÖO&Z«Ä’i~9Ú)e; \#=³|ä½6 Lqˆ|±Gß5—úQtdš‹§˜ßÈÁP”Û|Ï:“x:5Ñ'×´h
ô7åc}y&‰ä¦"YR€£(å÷l•©øƒÚ˜Ê-ÏŞ@º:€³T]oAZEG#Zy£¬ôTsjğıCé¿L>f5:Msr"DšM7 06sÊå»¤Õ›å»8y‡ñúFßêXı©•ó%¾'Øı¾ª
¢„¤A¶ÆX’BÁœÜ{~ßÏİc„ı¦9á«UØl}<i-õLšFÃ3‡ ­Ÿ¢u¨/èò1­€J€=òÑ6F°?fğí§,Œíµ@\ëkâãş
¢ï‘ä‚L¡¿Ã”ªF÷wœ¶A_˜¡ƒï9Rÿ«¼]`ÙÚ˜Œ¤,¥úYoÆD©/HÆ•.`§'Ì5½:ÓûÖØ÷ OI.-ïqçÂZ±cY&u'¶zôR1\4H^–LË¼6¼²[¨&vDÙmÅ"F¾j@wéå£ºƒ< 2ıŸ! b1·Sùñd½íãÙqfD¸—r':xÆ}­Ç×uîy %"Î¶Â2Wü¡š.!8ò@¹)¡iE´¼rú&z–-d_ß©âÉQœnf·%ö2}­}dU}|kû¸Dƒ†R•m•ÑB'/ü‹µ‚oŞÏÁõ{ºı¯’°×cÖü¦ï£Qşï­¢šV³yëïÂÀbBŞ–÷ê!òË'¦(7*}õAdµğD± ­BU_^gí¦’;Y¡s#šÎÏJT7ö¬2nSNè}(ø5µ	„RñŠå]…ì˜/7!û'ÂuVv	J•÷Ö[T¦'&Xµ¢³uÊLnˆ€-	.A;aXÍ† á=C'¶Ş>»|SèáÚ7óuèûm
·ı#J¯Ø¾dFÇmI·¨šµá¼Û¯0cs3?%FA`CDáKûà1_ŸmnÄ?mjÓÃŞ|jâxñ7¨¨OÀQ+Áƒ¼–Cäh[Õá¸:¼æ—H‰ˆ•ùöún:Êâ"D±vÈ¸Ãöfhag ÍìpŠ€;NZ[~¹ÅÁtr<¤¨ÛÉÍ^Ÿ²³n0Pv«„p€Áë6SÛç®ã#›áÖU¦Õ7‡ö½ü3µŸÍ—Ugœ¸Ö4„ÓÔ·¡™D~†„­{ßYĞÄ»(¡ü²é”Éíi³ïOîzÕMÚ±ñÜ]/SP@fçHÿëâ`yß&(©«tüø8ĞÌÚëJy}.Ñ£ùòÿ„î×C3¤©×¸#×á
D ÚH½t‡¶Pœ·¨­n\V&‹)†óe7%‘.ğBo“ÆTœNåìR/L†Î£o­íÔìË›p­â8'‚ôˆÃ‘eĞ¥íß&	-Í—UšúHÙÈh-Ğ¤(IrU7E˜%`abQ¾3ØÒÓ~"İ¾×+íwğú×«½VÊİ.mX8Uêg ×øøQ®3»q6W
n¨ğ®ßƒ¦eÂğlvÁi~GáP£xYgª[j
RHØ£S§¹!¾yCS"Ôïÿûëm'Bå…ªJÛØõ¦æ¨fÜ8şAkr¬5}q’À»Í ;]ãœI¯ş•ô!A~'àh–·?U%Á/gå›‚´Ç`k¯ÿ¸ê™ÂÙ~æfJ'IQbi+ğx¨L©œî¨0lµò÷ùæ#"·IåMàší6ºûkºì¼r®ŠÁì»NhãäêÀ©åªÒ‚¥šÕæÿ	0<)à{”KšğñÑˆbÚö¶Â R•®ªÙƒ8ógSş~Ü³Y¾½Ê™ÊlGU3zÇc[Âú³Î"ñ¸ 3¹%{iî€Z‰e b)û½À,vV_’'À
B°^q“¥F2=‡Bò PF~œ@0³	‚Î9`ößë(ª£¹@^ÇâGË­ODx»³¬¥)T=î³Nš‘@{éî€3=Äx'NhCÃ÷”lwã8vBéœù™Òwõ\—AU‡–vÒR®Ç&)æ¤¥™–ù£GŸüñ Ë|:H¸JƒĞˆw+´‘|€†ÃÕÍÏunp$Ş§Ô—@ˆf‹¥ÕJ*îF-‰ĞŒ*àÍå-h}JÏN³ôœ_İÀ&EÍ`Í–¢‘ei¹vÒÅÏhİAE “P]€.¼&KO>EÉğA$¤6®Ê‹Årö[oÇš"Q1álÕ¿ùK÷´§‘§P9‚Û'#Æ‚´¢Ê)*Ÿƒe´ÑÂˆu2Ú+ËF[œ–_·ã¼ão¨Ğı‰K@[…=?l[BÚ8Çy¢^ltª-²s¾ºR·£'ê!şòaVsÕ}ù±Î/'öğ`†,ëÎÙ´p›jL>"…`õyÑñƒÃH÷â±ò•«¿şávy„ÕãN°Úšğå€È¿Ûõ`½¬Õ…œk“ƒY–×öyóˆÿ”U9Døa£f!olt3?Õ~z8µ³ªí}tnØº6¦"¿Œlïy9©Ë¼…«Z$¾\­ğ©äûHµ/1Ğ‘¾EœñX î­„çò;Š—ÉM»g»‰kjRúÚ¥ãlg¤±æòä®†K‡XX¬c±—œ+¤SäFd¦Uà³i
?+~§èH™‘plRà– lÆ¦CÚ‡gÊÉè«qÚÚ¼P}p«A¾:ÉVépèú®¯Œã]Ñ¿±¥¯`ÉŞ&XªÏqY­,ò¢X_í½â£¾sk5pæİhµ¾¶ĞşD(
ã1/†jÅ"ÒùÚM	•XA¦VŸã…öÁRÎŠ»¹Ú`’W\öØåÑÎŞŸ¡d$ D 2ÓÍ4L(9Ù3¾ÄÚ+NŒŞÔ‹2 º““yr`(wTÂ7Y?³üö¶Q”?óï®¨ôríUk’j(½ÛÒó†ïÕõA'SÆYOWÏ^ÁpAâ¾]Q<“É¨‰îˆ&’˜Vh[QrHlMÛVÕóâÔá.8§CPÖF°]{÷ce<@JşÓX˜&v†ªø }zb‹¦ÙÚK0Ô[¢ógTĞ.i$Ú’E¤L¼Ë2p½óEåjnƒ” ]CÃMYÛÌ¬;ıì‹±p)ÖS0Âq‚¸zY›Ï*9éÃ¢—Á/QG+fQÔÙ,ÅJR3DÍßş®É·¼"8?4\ª©"~mÔ¿ö²æä]Vd™÷T‰&/é#dM;iè«ƒäü`#ÛšÚY©Ùƒu³É`T*>Ñ9,‘JÈ÷6Ô3Àíøv?£àzsı/ÆÇ3¸ÙÍäwKTğMDüàvŞg¬CÄC^
,ßüÊõÑ^O‹’Ó5/öMó3¿ƒàËåu×úª,i¦àZĞwŒNà¿G«À9ÑG*Ÿ¿Ë¦ôHıhÄ«[tÀ™ÀáìAì¤Î:B€ò¦ïÈ²~¢áĞ¸1ûz•ğ/ÛÉŒç#±ş@$Ô0° !¿Ï÷Í‰DUŞ‡S(H½¹¹¾A<ìî©%HùMêúiJzqkì•§HÎ2Ê¤­e)Nõ™¯Èäc£Jj«§hÛÛJÇXl<;™¤ğMV$øPßïç'i› ¶ë’ü¹ná¾Œõ(<¬ŒMàÆÄpkCç*Ø¤O&ØGWZdFbÇÄöÃİ2ÃàËJ­ÀŠä;h‡¸Xq3t),ß2Bµ=3õŠƒªÍÛ©Ì9]Ü¾tO¹ÇTF»wITüÍÑÇ[æ]5i+Ÿİ³VÛÕ
/2;MöÄ²Ï5·ß¬1xˆ&2‡uxÎxRbKµê:ÅÂ¾÷ÎV<Uğ6jILç±i`pÉJÍp‰àuVqÄ¯ñ²º¸Z³CgØ|&3ÁCİÊĞúïštØ*”¨*!ŠP{9<j<JX‰B­pÉíìg^yJsºØ¹½Ÿ"Àc¾i¨×òÈ«İ•)m(ÿ€ÿÂµæfĞÉ9ÅP±
<Î¿}+¥¦J°Œ>|º<úZbÓ:ŠKù·ı)W)”<¬$Îì½Àr+w÷ø’2ÅvC²Å¶1MPe-¼—`ÊøzÄî¼ªôş<Ğšå2¼ê&ıH0…L=d;bŞ8P˜yı0iC˜ùò*½ÜÁŠÕ¸ á
æwÏª=’ëPd;ìkÜ*Ff^ò•‹ZQX•!êˆ ³-ŠÈ#km¥‹0Ëqë @ÄmÌøÓ±š§¬„9UèÄê ğ
ğÄÆ¿ô~£¹Mş[aO¡’ˆ„÷Ë®Ê¡:ì¡%c¥‹~´d]t)?Ğ¤CÙ
™ëKS=TÇù€š³ŞÙŒÕÓÈM‚¶«ƒâ÷©š¤7¥ç^2t´ßİ‹y?³¸wõgƒ6‡äÎ.Ei$;“÷\­QÄ¥QœpËõµ¥B)ëñ2VÍT[B,ycü;˜gíO»¸Ğæ‡EDA¦ÍÇ}$ñuv!è[±¬á2Ú¼¬7æfõo*ş*XÌŠÑ“}Òí³A) ïc™Ò“ìF¸o©sÑÁwd©ÀGOMÀ Kø˜’½áSNç\ 4‘_k"Ú!ÁpŸ·¸™ÍîÕ¢8ÒJ?!‚|÷E`ÒÄ>…>Œ+Áğ—$MeJƒåƒœ0·ØøâK¿M…hzÜ´nÕK+â×Ç>h7Ûc‡'X=zü–W¸¬Ën˜‰\ÛíŒîÜ(¯Ã{ö¡Ö=‰«çáN9¿1§QÿéL wñølüÈM2¬üXò|ÌºË‰(/Ù‹Ïš’u|ÀVC€{ºwéV3ä˜4şÁC+¿Aä°›¡EĞÀà›ÏS¡?&#O|Û‰–¨Ò œ)@U“ ÅİhÈvÇÓü¦Ş’Ç\@ğ¸É^4·Ã°,6ˆ#7{ğşËØ(‚àÖ˜õQÎ	Ñwíá4¢¢±8­5%F:J$°šÏçyLÇzReã™kSµIG Àz“úUŠ8WŠ’î!‡ù|Õ†I'ƒ®‡~ŠM ğ¿‰ù/NA©èt^ä
?b5|fiµ;°$£È¨$DŠXûO‹ãß]¤kş&Ìx“Æ hDğwÓ‚#1ò•‹Œ›[ğh{´¤‘ìF•5êK‹U¶§Ñ¹çy³À¯rn’¾2¹<şœq ÷ÀëÅJÍ…üÔ"Õ›ñ&¼Êæ‚Uõù:+]Ÿ\¶ÂèëÖÛf±«òGMùïô‡üMäâ·'5\Âä­ïdzr«…a¼­»QLËŞ	àqÊè	àj-Õó©ëıæÓY`¿Ş}¹y"@n{:XOÊ	"pP$îÒpùd"D,´·hOm´ıõ›yI7^n„–Âı úÚé:ÿçq2®Î•˜ˆ`ñ\ÓÀ”N:+DØVegm®Ny}Ô1óÚêI=“uĞ¼×Q©EÉq}©2¬S …²G¥ª%õ·Hâe*j%~ØYM¢˜bIßª©sjpYTŸè?}”Ö?BRØ–ŸõÀ¥Å>¹<Ûï½ô;ºd¢¹ üı|%©w±D#­Œ»æ.û€Á¥,„Iw%¤Î	_ZĞóÖÜJs¯ÓÍo¾ÿğvJ—­Y nªÉùV¦CĞš—YXÈ£Ÿ\õšmåÜƒÁ“PÖÜ$IĞWï–SVQàV‰›e6-ƒğµ§ş\Í€0Æòè¨8¶Uô"Qı\`cì˜(\…JìMàÔ¢Ó ëÎwä¦qüi’ûhŞ‡~ácÜNUû"d¼Ÿè‹I{¢9ÈlÙœ<—ÊXuÒë–ñ>×ƒF x`àr{ßD
ßg(µªzFU—N{f‹¶%Ú%ã? ÔÃ]Q‹tÒe.Ò¿Ì2ãL™p&6%J€x5QD„¦j9oV-ls—|Ü0|?pùS!GÅ
§7[µ ¥ L;!bÜï´ƒ3dåd¥(v­ó‚§àr;ÉìÔ±³†$â†+‘¥‘:ÓµƒÚ+ß7êf_9SõTXÇKç” ŒxAø]Û™’Qâóc‡\[×øé5" ]“ ªM7‰%j:0 ]ìW¼Uáá’İ¯–ú‚²¶	è‘EêöÓûH®H6>f“Ï«)^‘ô#C*@ÿc(jë÷1q<.½}ˆ9P®ãhç/Uòg#‹Äü°®¸
Á_K}¬Åé©Ö—Õ£R‡µb¾Ñ¡İKÂ.;[Ñ1ÛxêÖ¼:uü]½›¹cIÍ4®{üë_a0KÛâŸiêÚªN	Rjÿn3µ2Ä–/{ımXE+Æ«Éh¥ÎÄ—ï6h{—gà¶´Tü—tòo²´¯½ oP!ìO3o„7E¨9yÁZ¹ëqºv@h‚@õ´Hi‹5•ï}|œ`õ{$=L8"•o©Á8ƒ-ñ°R7ôLàÜ
æ.éŠD—Çv#@?ÛqX‚«¥ÓğÔ$KiÍóô§4nò›lVúu«Äêÿu¼ü¨ø3È›]–"ÆÍ>”e‰¿9síÄ&[8À‹fuÃÛ³‘ÈËèoÉ3ŞJ‰z]!æA”òÍS™‡ˆ\C&ğµ#§/•[î¦‘)!Ò,å´Hğ]î#aª×q?±\¸2ÿÕ¤Ä%xÎº´§ğCô~Ñ.Æ| ÄsG˜ÍôkP)dp&“…R'V±ŒÇùÄqnêH…lv[4£©Øt™dLHÄ+O3®èÖ6cB¾a,‰?êŒ¡êoÀl’SË¦/v¥­ÈKdëÁ3Ò3\|rÉ J2…	‡~°Ğt¯İÆFÙ>ÿRèW¾méíï§(P(°ƒ¾_/.Ã‹b× 3¤ù!.­®W0ù¤mŠ¯e­gŠZúUFB'+K¯ó¼¬ŞñGFªØÓ^Lòm4göºÚ·-¹*œcòXc`ÄÏÍomgá/;=zç©qº^jûÆ°òCØ &(;_ğPÉİÈ¿óávl\æõÉEáíÑ‘šKâ² Áeb¿ñjõ¥šMháZvcÁ ÔFÁ­eêŒKNA£$˜L§Ô–§ä›)¦Ü¹<@T"ÂÓƒÄ†•TAØNöEÒ7…ˆaÏm¡CÌŒ¤1	n6Ô+º‚¤tÏÙr­m¯D¶Î\Çç!ğp ×+@çõÍ°†wÂ‹¡¡.@µçs‰ZÕµoNœ0ôãÿ#['‘0¥ìá~mbš-Õ1ĞÅª‘·ˆ'öÀ§q×4¸Ï”c«éÓ›gë“Eæ3U®²D>ôÉ£/âù^#LêLc™j5­«‰ïçày¾Õÿ‚Îæ¦í‹Òû0õO:Òbnh›„Ø$)€"â¥H{:Ø|şêÄäa9úzÁkDÿø,¯ú‚Ğ$‘z•£œD^Î™MuÑòúnUZ´¦œË:ãCk«%
ùÛé Ë[¢÷;u¢ú1ó#¶‚	ë¿"° ÊùiyÜçìÜ–ç;S]¨£hÏU@óÆÉß"µ[JMnL4IsZ‡Íh—@$v‘c^›Á°K£+
ì¨ZÀÌ/ôÑßœVMO=2‹HBGÆñë:IF–ß'Ó‹6«”¹v®W<.Õ»««uŞ†ÜA’$“’ƒ-7·ù3Ò£XGqÉrÒ‡6ì	t8'BŒ¾Ç'd‚ ÿ£ÀxÊI‡T&vxŸ\™¯b•ÿIYÆ3ó›½Ê+DÌŒ|§®°îÂ€€Ä÷•g_|ø0Ø™İ$ÒQªvSÀMa)?ÃÛóXĞ´…é~)~zs…„´'+nŒ9GİŸÅğÀtB ¾VÀpäÎ£Ÿ»ö¼;Ğ»]S ‘|ÙQ’7sŸ·çQífs×C¥_/ú®và‚#Vi»ÍmîŒ×ßÍ_RéÏ(„›÷ë fñÎÿ“©İ¹Üd~½ğòıˆBÕ~ÔB`2TMØd©1ÓZÔvÓß ˜SˆéPa]âÔDUW­Aùàšš;Bé€Š(àà•KåŒ‡Å\LAa¿~ŸtÉ
aôÄ;Ø¹Ë°é½Á&¤}4É%y<úª§èºäšb” ¥–Jæ8
tG‰Ş-5Á“=ÂŒ•+ ÈMP•OD‰â†ÎSE%Í÷—F…V/Ü}½âèu=Èm!³Óå¾çˆ>Ã*Éˆ–¬mµ†Í3-ÛÍÇzo¬şî©&oX2Ç¨]‡¢ø–Æç£—Àzì©C9ê$ïº	úBÛ[=~BJÌ$·~xÑòù`¥zVl4rL« ÿÖp.„À´L¨Ò"3°Z(@Ò\FùW<šïB‘ïÄ£1[¿ßm{®yÇØ‡4HÀJk“©‹›‰†¨Ç—s©6Š²YlÄqÑZš…¾Ê–ÙãŸNx‘¿Ñ0ÑF”8/[õ¡÷ÚÍ´wğ•Ü% i;,@%›C	oŞ>¼,w«ã1múv¯…âô˜´„}çÑuTĞ¸\3:e®¢«ˆf©ÎˆÁ/n9BÖØTvë¬š4-ÌÅ‚¥öMtÒ^Do›?ĞuˆÖ¶û`Ğa;ôµÄIÍq‹ÈzéG~Ú±A‘Ãø´ª¢¶ı‡«”åùTİ­g><è!Âv_é˜F(v	sÕDÙEî™Z?U´n®Ç9.f%JöÉÈ¥?õ¦•tÓr - à©î%å
hÄñ\j‘¡k áF(/ÏÏb1d·ºÈœ.$@6.q¿ïwRÛÛ<ÜpCš3ŒÎ-±¢Âåß‹¸¡CT­†¿,
5:&0‘xLÉğæIšµ,éÉ ŒËö|ê­yèÀ-¯ÌA
³’}u6Nm.åRó8>©b»ô,3q8!B³¿hê2>2MDÈ!=Ñ¨!ğú–ı²­ÄÊO‹!fìø‘ÌæxJæ6ÿv
Çbº‘Ä —†öÍ$lğÆ2äŞÁ1øç*õÖ Nó™œ'‹ô4‡gŠœBïs •àÕÀ9Jrø»Iõf)”Q™—š€2‘¿é-[tË îÛÿB±Ç¶rî})ÊšLşLë-ğÆy“÷ü„LÂİÏ(tøÎä‚[âù+1˜Ü—ß£o‚\
âßïVƒø~ªf?u/ÈôlODË».1cÈ¤•à¶?8òg‰MeğtÔùÓ-Wñø“dÄÓò7   yqÕ
b oƒçõ°Uö®¢nn	€Ç¤-Pº*ˆdÂ£8zßiÅz3«9ë6bA­'W‘MMg’ø$dÍ{\;ûÀ¤ ~
¬~ã”ÇÀZ…[‰ÉH£VÖ.ÒÃ¢æc¼ “bÄ™ï;)÷‡½tŒ	ğO~ÿDÅScÈ¢E×fîEÄ–ï˜Å‡†ZíØ›1Ç10zU&…d]W
‰qdì3¨Z²jyˆ½Oé·òizÔ$¾^î² RÆ¨ÍS°Úˆáñí;0«ùFwBsâ¤ËgN_çh¡Z"-é·3¤¾¼Ä÷ª,”QĞ¥ËlK
ösË›kkÙóŠpyœ-4QÅ¦É'…a™¾J>µçõ¹ìÊú*v¢¸œ¼B
ÍeÜq ¦&DOéÉ©¾Œk¶$çjª³íå
F*g¸p	õµºÍD`Å!9KµGøY«JDÆbjz!cmŸ
w_ÊxçÏËŞ¼ÇM‰çÛ²zÉ”É“ì¶Š$’—.º‘®;û4†ÙæF‹ÿÛIšJ7øX1æ’H¤¨©­7c&yg0‡ãRËN²ô,£ÇÆŒü’µŸ=	°»Üü˜}|Ùœ7†$öQ¦ R´µz…‚7	ôIzzikª	÷5 “Ø±+ Í„¹0¸&"gO˜Ã)z­ÇˆyÂ†©|ŠÅ¹âİğŞ©çç NÁŒ´@–E%¾ˆ}v_¨èÇÊàñÚ»°ûÓñ˜¬7œåÿ…·Î˜#Ò©’©®ÉƒÊ|ô´€—£>r‰öëYû.‘÷s@¹yè6é.@ÎEm|àŒëZ‡ÜµfUªÿŠÊ„›‡²ÙgU|$4ñ"]»Ã°6íèººK'4C¬?²³
kÂJ¿"B£5~{‘1/å½Ëx#ÿéxYQ}Dk]Ùm«ÏÈìˆU—‡H•)zrÈor-›;T%bVO¯.{ùğW'k¦˜{O‹îr?aªWÍİìì|ÍW·ã¸ö7_Á¼eOâ
ÁPåˆ%Y°µm,Æ3gèDœ`‡,‡i{¶½€póÆ
sÍSi“F„ùE±Ëµv{’ºZÀ´#)è°Í;˜Ğ²
ŞÁıM]NëºôMœ	éÚ§æí]¤%‡Aq£Ü${ÖgÜıæ^qùìP:ª—)ÖŸr•7”ûŸ6’È«àiÖÓõHÑ`Oª¸ft&·‰±•*wrag\¡ï¤š¿Úâô*ãT 6Ñ Gw‘Š°2èüR¢Ó|cwíÒ¦œåv²·¥ü+b 95Ÿ€:
„£«	_†ŸÛËø½~Ë}¡sÄØõ–W´‘˜‰/›°ülíDÑİš–aXÂ‹B­„…î™Øîğúã>»¥$ğò×Ñl7Ñ‰œÇéˆœÆñIÍ’TÆP?›ƒéù%uªN2¬fs›MOŠá[÷d5Å_#t¦˜êàXĞí1 Øş—˜éæ:ûµùä2Ïµ.-OŠó|…2·ÄìÁju/Q¼nLü+[Pì®>—ég­{xµÈCNÒŞdO¹=<{bö®F'¡¾áVR÷º«Ç7ZËb•Ì7òÜC‹Í°~ˆnÅbnqŒtÔÎ	A˜ˆŠ 1A»Â«¿õ.Z„­QòG$ªy¨Ÿø/x	[oV„YráëLb\$½ åÆvOÏDšU ªµß¹[QâµïCä2»ş6‘Iøa=O[ı%¥™BÓ:×Jrµ
ÿ©¿+„¡¦OO,AkvLÔÄ¥°Y¶ÇœÁCU­Q¤q%˜5”) šÏ¸ş‹=z2–ñíXoŒëmâ‚ñ[vè}.¨A¶3±ö«å˜\½ò¸¶ÄlÓ‚óhÇú&°r6 Ã,*	5ğÒ•dĞOIH•mö9&óş¡×»fÊÆxö¸‚{ÀX¸y…a *ÆG[¹9$#ÌÑî_Ÿ*êÃdÉ Bšã¹åû+}o³ŞvÂš2®ÍXkIşS÷#úÚİ|±E+¯Vk_ıQƒŠHÉx–]«›Ê5Æ­¡$¤¡p6w»*Ş,k„w ŞhOıÉÑ‹”g¿Å÷wñğû4Ip3‹šõ…2î²ì@‰;‰8{•¯ré‡u^sN5Èeù$ğ:¥ğÀF)À;R5!p‹VÕlqÈ †p3FÄƒâªÉvB|Åõ—XÏq­vïúR¢än’ò(,´ÄF§F,­%R-¯ÕmµuÂê¹MÀeao"º&y)øõ·°ÌoÊ05ºÙ4üÊ·é¥VQ‰v Şö²2gÎ÷Y)	3a,\ë}“½[v|Z4iªâescÏAåefˆi™‚V¢‚“n°73Êï<Ä¶Âo¯F^C9bô!±“ÎähC;J™-øµ!^„- ›Y€Üî›ï9#¸¹loĞ]¯j.’4«~MA»êíöÂ\u‹Ò¡şğìµîğæCÖÏ”†è‚é<°˜U€Ét›F¸5LñƒÅ†˜‚O˜¢wp+‘KJg™¿ö÷é,ãhf'Ë³ò²½˜øC.¬ a.¡ùIiD;BJ›í0†¼!f—<˜,¦é‹ôÃŞç+÷Æ¼‚rar0t!”½Öîc0`fä°\%W‘yé‰OW_·[‚¸ô(o¡³x¥[Ú2ıñO.&ÓÍ¿êöŒòY‚ºTıT½ªÃÑòÍ…-à5­.ïêø}\xô`Ö0ÛÿL€£¢ö|äÍ*%²‡s}zÛÅC¹OV¹3~rÆğ8ñæuÃfÚ«)V§™”H§¨t · °29úp™«ÊKûü°à«eÕÚ÷	ù»F{ákX/öÄW•N1é¡JvDi¶<†¨BØbê  À^IHÉªÕVGÁÒCê¢=^x<R S‰ 2teQ•ëÌ-hÁ9nLA“lÿ½{¦?kZ`7`ŞT§rlº–Hâ`Mç”š÷}Ç+—~É´¿]ğÏâŠsì^+Àhw®£ªŒ‡NıGÌv—Ã «üyÆ·	=‘~ÑS]°9e1Äª¢W:á4™sÃJ’.ù£MÜÃG<˜–`„±zÔÎ$ QTÍR:$rÿpoëFY}«é`_Ş„±zºs“Ø¦~¡îAMÖV®ô®Ø}P¶J6×Wı­Ç9ÙÖŠ©8c
ôêl¢9+Ô³“–¡‹ãŠ…é‚¡J¶]óğ=u°Ï.†`»v¶Ôé7áÛ[’¼ÎšGZ@|UtwG
G~Şcyë¨´ñ`«RªnZş]w¹ºXëT8‡‹Ç
bô‚ù¸w]%#xZ3hr¬\S%6Ë´†İÊí[TV‘*úS4‡Ñ_2¼–ÉZä*GYÜ&Å¡Şò;cìan‡-à¦LÚ0İ,k„Î£4mÈ©Aœ†°×E€möÔËæÎ?ß™ªÇRN¨ĞÇ¢¤…Ğ»ğš‰™I%OÅ+ÆŒĞşÑğGhLU5æÓq*&
¨¢;7Ü‘*3§Hc²aÒhVTÃËÂÖìäóhŠ…êA`–íÔÉÀÁSı·Š496˜EZ+Ec§ÛÚŸ|“‰s’¾ÔA¤µôÇ·KuØÂµ]ÎzbÊ¦3õ¼ó§1ã¾îİ¤ØÛ°ğïä¨NGûBNªœóÕÕ‹‰™'p¿NT‹4Ãß7¹C§Å·Ó8éó'HC—„ÇÂƒ«—x°)á˜;K!¼W4D-h	1{jyO…î~$™‡ñw#ĞœnSÿúˆC„cÇîµ6Šˆ"_1á¥¾Ñ²Ö"×ƒ±¦n]â-–O?„}™€uÂ“á¬ñèîóqë7)blK¬:]É
ç)LÍÆb:‰”´Ôòš«¼m…Ó­¥Š±ÚôĞaİK(F·^Û!Ccì’Ø®¨0¶¹‘÷0¾ÍS ¸ÃÁ6\¾luıeÇ‘.Q‘9«µºÒ×šV:¯¹êóà(´‰…‘\ÈªL\ÔŞSÃ›ëé{—§º%_?‹¹·tˆ¯HKÔ õ uËŠ`í"PÂk´ã¡ì3«}£øÚç0mŞåÁ-õ¢¹;‚‰#?kKº³v·›ßRF—1	b7pÊKtpşóEeôµ³mİÓ=Ú¢K(_)<’ÒÖíP1$×°d‡šÙÓB"41§šÎ‘¡6R¬4gTRŞ¤+½~ærb´rÈ‰Út‡#ĞĞiìéG¾V¤³§Í`õô¤¹ÜóÃ¬šÒ2\;¶Ğ†X¨ó9ùJ˜Ğµ- !ñ¶fg]¹º•ïÛû™lôÌb*fF	ÃØ'a¾.xÊŒd»x3ÌÉÈDUÇV]°<)úÑ_cép¶?²yÙ[¡25ó‹›æ°¯ƒT#-|ô—\äSò#3(šÒ ü¸­Lt&?	M{#Ö£çdÌ %	K²¼™SS4u2‰G’Õè]¡öKˆºX¢õ/6PEıHÅóÑò¬<J;÷„«/?[Yvìm›è)Í²*æâî?s=s)WsâY…Û×A ²F¼¬Ìı§ê†<§øI­ah,k³?£²³ˆTùD•NŠhÁ3n8›U€ÄDª‘wã¯s@ß]•åÒğƒO±6…¯º²ªèÚ8Û…O_Í”ÇPüTÛ6™8ßi¿ÒBÿŸÃ(ŒÔcˆiäb~zP¹ø;L*”6Ç\ŒëöJû±vUÑJı½×ƒg•f»Ï?ÄW¯¸ş
`(Af†ºñc‡0D† s›ŠTr;Á/m¾ÕÜpş±Gù–„ÁHŠÒBÌâMÏ4a€[øşßl/÷z÷ÏÑl¦Å’}¤ƒÀôumbïˆ=Vhä{‹0sX-˜RJ…³Ö ÷Ó”¶H›mµ(P—‹İ—YšçyàøûğíşÁB—Ç‰Ùf³0˜ÈRPtFxÙ½ÀGâ¢{ú# >&öâÊ/„Ü¼½Ğùr ÑD^»şTêÔBÍ IIãJãÄâÃ1øÊâQCÊ,ß„½»©5#ÔÊİÙâ“ÃâÌB’txÏ/9%¦Ä±û½àöÙ›©ĞçÏoôÎ·ş)İWÃ×ª™µÆ»>m1¿{eÚªrûïÒïàºZé‰æØ _øì±`²‘ë&Ã€!´bÆ¹ş¿cÖ…Ú±­«¬Ùt¾“ÑdªËÿå¬ôàW:A)’‘¬œ³ óÇWÍHêsÏ`Mn*ó`¬üA$TÛ9/°î?üò{®šV;B¹²VëãGloï3ïç¯_Æí--ú×÷ûÜÎ2Ê†`Ef9…†5ÃÓršŸE»şàº©ü¹”¡2Éˆ)Ht%»u²38ŸÆ¢ÙŠŒÁ¹T"ß¡ãİ?U‘66+³¨9vL*àÑyÙ~~„±ÈEßë`æ
±Ûj“±¿¸o6tª7ó¾ÔÖ.€.ÎØÌZ½u–Ó4fçí¬– ?OT”şjàH¹
Ó’¯éç‡+§Gr{»\ú¸ü{3ó
Ê– ià!&HZµ=.Šˆ’jhƒfÂ!>  (q»¡©%çëÛÅÙ`n(9p—£1úya`Å­–º´ìó7K§/‚W["á]Na)¹.*`’mÊ^÷cûa›¹Ä­­{kšüù%D¼,şYyƒÛ8ù#VÚ}ºŠ¤2íìcOVì…W½Aa_N[\9óu"ÌÃ§ÀHJ€2uÆIÚı‡¬‡¸?iôèÅmßi*8Àª½wGáz­ˆÿ@öíÇLâÈ<mÇÄ/&0·H‰„bŸ¿îSS•)sÂ:h£]I<¿›Ìz–Y¬İ^QÚtx~¿Röobõô×@[«¿Û¹¬fE_Ì–™ÓØ~ß£uÄ.ñ<L..o;—“ãˆ6>3°RL§{ıí§YzŒLB„G°‰ø>|3ò7ŒF^Û˜Nj‹µÕÃ‘•Ó±é¿KÏ…§ÿˆ]©‰b
·HÜÉğYF`sRB#!m'
{Eš'ÍåJ6Ä•ÊRyÚ\$ı£T²®>òÕnfk\OÿóuÊ$À™bÕxşA’¬3Æ^õTªÕùøƒÌ‚àĞ^‡‹+[\¡RùÁ$á²ú:à°Ÿ˜*y“X¬óè ¥äğX™<å9};=P²1ùH9Ú§ì#-p†Ã€ƒVÕRBRÙ¦ØEŠ“PLh²×Ä±Òh—Ğ‹ëmK¬uú.ğÚà‚/&Ú«b·Ğ%ósï`×R:C- VEéÎhå=¶Æ–Œ>ŞÌ˜Åè&dŸŸÄ¼[‚Ã)mÌÎ«3¥î?ÙÇº‹–Ì™0­“’ã½ƒÓÆæ¢?…lÎ.ngå8|f”*áñÛ3¾Ù°ï•HAm'RT	(n!TS}ãRüdiÓ'ğÅj3èYQnµ#<ÔôÕ&Ã¶Zç'¤À¢Ú0)5»³£äêZv«Ã,œó)™b¯gõAá¿3@À':@BK7ŒPnzÖù]m ë—T;<öÏ„ßŞ N\oB—{mædD”¯­jÖ¹­Úş¿*d\æ…Ì&v‘–üB@"RCó²>¶—@©tÃºÔ)¾áÂ ¡)§Ë… £ßÌß÷¹«Y^2Öí™L'áåâĞ´ 7ÇÒ6¾ÿ6ÆøpáœL¨5ÏH6àš{ŒxI„´aƒš&çÌ@íÄÕşÚhÇ½¦M«XT¾‘V¾aîN]ü˜ñ:ç¬$Õ5ŒúÅÌ¡]±ä>åì0£ÈşL]#OÑÌ7¤+wÂù*9¿4Û&ÃgÓ¦XMÍ’Ğó(ŸCKÕ©…í1GÛšlƒY­£ÅWâKã0Øä+ÜuZkÔƒñ @	è\ş93uªa3O„¾ø¯¦R±WZ%³Ì2ö ùânâÏØÔI 4	¬@…W† é›Î¡àlˆdT©Ûß]efÍ“KAi’NºxİÊİİQûo[ncˆÑ—~i C#
¼ ×8Ó‚Ã]: G8{µ‚ªŒöTk˜7È¯¡¯~#á¤Á6Á,®@¢±|ñªSHÈMÚW Ê(ˆUlt¦uvåq³€Ñd=Zß¯O¨ØŞ’°‚R{«‹d½ÓÏTÛ"ÜÙê“K%`¦âˆš9“ÒpıÙiF–õÒ)- 3sŸ& Ö§à	÷**wŠİ8İ‰g—Õ®‘¼UÆmÀèÀD£?ÎÌAnÆ,c:/¯<xƒø~21³´(p·I’€y,@)C‰- ,HMí³'æ}	Îv_j7Ùí+ ²;ğIğª(ûK“¶¿½k¦Ê
0Ï²éx¾ÅĞ•Q–	™güqBµà}`Úb°)Æµù¢+á‰2ı2Åİ¹ÿFÌz`CWS¨]ZB¸Ô}¡µê®†…@Mr6Ò ¦âü‹4’¼WôYl¡c._ª¶ÌÓsi¢ÕÔ\‡–#P5ex'!HùÄÓ_†ÀBo0£|A¿§9Nc]˜—îms/àKÂâ‡•äç}E1ìÜèBÊ™µË(c |Ÿ¹ O+cuÚ ˆq,'³"½)v¦~osÀÇHÖyOÇÃ’0ÑrÈ°ÙÔ1ëlÈ1›§elƒ¢Z]äX_ÆŒş…ü33Ğ,KÊS¡°»£$(8@,â“éh€çåÓ9î'‡\ğPåt2¦× 8È‡	ä¡!†^M!NèkbpïÑ=ğü£?µ–z&)•vW¼ÍÕZ™íşv~MI~ÍŸËYM9óuÆYªÊÌºÑW8î…^jƒ¾ä8*şY¢Z8U¹Å@ê&_›Lî*Bfôè i´ì€<m˜¯C•Dä;„¶ËëÍL*õiPø•‚vqÒğ‹Œ¢²©< ÒF¢L|§“l6ÃW¯¢ÿm;ÒşzÁå6È!IïIWa²£9ö$=Ş|z]c4™WC^]£‚éÆÍß%Š˜ìªV–¤t€®?ëŸ*ÿ.Œ(a%mk|Ö W÷©Ğt‘K·°ÄíÈ¥2Gwª’Ís~WÙu&Uéád`¾N»VVŞĞr/~»#Ô¿û5 ìEm·ûD÷œ™ş§‘¿´‘Æ¿îv3àê€r£4ı”0J÷n‚Ùğ¼4+5¾Ü7R5ç•Q6„Toè¥iˆÆ]PWØ%¯bÔˆq³4œ+VwÓï“2Tq.k!È8ÉÒŸgSø;‘–¯©	ğŒÇ>ñÁœßöPºm+C	×ãâûèg ñ‚iÛûf7àåMTÜ	8dg·ôÊ‚ù/ÚÉëşæJnÑl†Ò½ät+â˜o¥uˆ€'û|°u@e¾—¨ü¾Ú£]¿~IäI éÇc%•ú8O"X ş>ñèè´aìE
X¢`ÂÈµz8Çßi!“şU ±Ã¯EnR5Ü«ZÚ©Õ°lãE™(Îõzò¨tú‡YS»Ù`¥òª;ï:…'u&¾¼ÙE½}«çĞ>íÿ:Ï”ÿC¡úYôd§E¹ ´İUÓóÛA3¾’ñŠ–úJ¾3…Íš„ùUÂ`FŸOïGŠ¿vÛİy9ş7
j„`õj&4Á%«”õxºa}¿½ßârów¡çùX+¾Jê8UßP}©¿°ãÊ…õPÿ™6bñ]˜
¶»W×°=íÆ‚6½/İÛŸ˜¾NsÏNbj“¬7•pNÚ`6°ä¦p,÷ ¸Ø!âùm/nnAàÓc<ÓüÖ…—òÜ?èèÛ¤SIA.V-Ï¤:…ø"üŒÉŒVØY·ó/nŒ¢=ıÁ@°yq÷,Î¥ÅñZ"],,2nuUˆ|NÃQ»Ú'h#r‰4rÕíÃ“ìá]>]‹ÌbÚ@ryø¥:o~µÜ ›]İ>7‡ŞRÚ» BèRÎ‹ş°]xc£!Ä°}4ë®©$wcè!KúZáüx;kö$£_¥Æ2º¿Ov;¼Òà5ïò†ó>µ'û£²ÂŸ*Å­§h3ÑÃ"w¶N`r›2ÇÎ.áëzî‹½:ãA.˜Ÿi-“ÜùˆÏZBuc)Æk’c(HV‹Óc6#”kF-­1şoqªL7¼Ïs6/ı™ù©.IuÜîAå£›±pùF3vAzGSğDÜ{Æ3”Ü¦“+ğRæZ¼Ò3U{ÛŠx&xÇgV,9mdé¨G\W²<;Ö¯¸IF»³a­6g|£ÁR1V…ïÎ(ˆ RTùÑ‹¸^"D:95¸û!TİÑáÙùÇI|fU™«&¤fpIî-ˆËÀ.Ø ‡®é-{¶}@R‘4\ö†p$(æ&‰êB\uzÈu…êÆœ2#‚5Œ‹ªBõX&Ûªf­®I¼´¢uÚzİËÁ7çFõjÃ‰,¤|ãÙÃÇL}@Å¿BD¡¾Z§™{™GcØK¾%tŒw UÒ8¥©_/´X·UÀ$)²ÃAŸ²ëL×OI+Wiwspf=ñ{ì·MŒ ŠõÛ8ßFq¶"Kú‘ÜNzü+óå7¶AÒÿUëã`/åâ6:SS‚ŒA5·”ÅLÃ†Ió»}é9´á^l„HX(.¤Ÿa/Ÿ&Š±ş…ÄşWZ&—£…uå–GÜtü*â?ˆr” ¬ß•qáÒ¾ÇÉå uı;?•‹(+²•ÃH/Ş6wU
fp‹|Ûeê)j¿y}ä~µP·Æ`YêsbU¹—$şõS`ÿC×ˆ”ğ‡n«ÚÇùèHG<²L›4Bİ0Ü9õ@Zú+ºÁwÄ>%{	®8œ vøö„èk¤7•ï]ÏÆgÁA’Ó¸B: ^² ëğÅjSÄh"’¼÷ùŒ§ë-w“	]9µªİp¬ªUÚL¥)ªû/‡	á ´€j½GÎz=Iå§0GÆıØ+ B»Ôş3ÚÚ~r¯:5AZûŞ$Ì*ä/½¨$¬³éIn½sY!ÍìÊİÈ8Ğ{ÍÙğ,ÅŞ> #\Dïèç=uÆ ¨4)/EZu:ì<”V+?H×D·.F »aäqÑ•Ûâï,b‚5!çÃ‘Ô’…WĞx WÖÏ{°†QSyÕuVX£şFÑEk°™nçm§6Ğ¶£{_õÿËI6@ÒE¸Aë’“Š›…†5J	åÈoUó¡}oo¶§é ƒ<Å*h»hÙD]<’H¾áÆ±¾À
g®Ë3`HoI~Ò¸=ÚÙÇÈQWñ’¡æ´S{¹gHÏ´ü]õ ª)ÊjaøßÀïr”;ó,Fá–›áKÁ0²i;”eá"¼´3Ù¸£ÂÇ~ûãFGÀ5ßv`Ë‚ÃHk7(‘NŞİ	³!ĞÚªÄcâÚªòÅaVúÌbş4c'`[U']ô™FY/0gBL¬8.ËUÃàÒ®ÖG”HÿÒ›Ó~¦\Kç§ùÿSßåô¤Ğ;f®ª«a`Œ#?ù‡®Ô7*¿µ%Â«²óÚOÅûTÀAÂm/FïâZĞ‹¨e_e3§t¡•DeôÇ™ÛrHgİV‰ÈX’}†¹Q
Í—w¶¬ÙL5«}”ó61éÏ£KuvÂ>EÚ#£n%D áZ²O
$tÍ\c=RÜ§àoü,€úØ
nf—]\[Æ30‡‹~Ÿí±Äî²y®Åd•ŠX
Å]9°êôõ¹‡JÔg>YQáe¿Ç©ê2IÇª{9ŠSãm´šTÍ¾êÁír¹ 8x1aoO(Ö¯ü·­)‹…øÎ¦˜#%ÓrûVQ=õÙ·ªln° nöÜ.§ÿ®è·‚„RØâI”9$¾éMıwİfKĞ
øèÏ¶;W¸HŒãÊŒ–¡´š>§Ì¼€dˆ²c!R—yú[x/¯s§ÂÄİ<¤¸‰ğmïø³ˆÄ›şóà3vnàK9s|,wCÅV·²Hû©¦†„’ú­äQPt–cöP·´Ja$0İœ7uƒİ» Nş Ê tnk}Ë$}dY¾b 	Î	TxHäø®GcÚƒ c÷bá\“ÏˆŠƒ0ª¨ÍİLŞ]–›å´#`lw'c9•(Šqì[!xmï¦X
~ü05€Y‘3Á<á<()T¤Y¤K4¥N×G Ç†²¹ ¤¡ib9ßm9epY	¢K©¼4/Í…ıGÁCÛ’P´ùw6j9}Ènø\êª¼Ç/ä®mÚ@ğJo±BMO÷¾tTö"Šâtµ©#®¨¿èïïî/•¦”‘”|Sé-3_öíprY${Ä¼†ò‰üqv» N|–ì«Ênèia0¿)!(ìÔjTõÍ©/à³è•|³ñøê¼¹ Ô•÷[õí\VŒ(*ôß4,0=èKq·|ëÂÍÛçÄÀ.-ê×*@—X.Œg5Y,f9I¨¶Ç›T10XÍYä‡gjŠø!ìRÁuñÙF2!÷À–·Êê ı‰!—äê9›'ì‚g§ÒÑ¼Ôî+e»`â©*7N0±€ë TşI@ *8,*AMsŸcCğşPSÍh›é³ ü/Œôgjúˆi	mÁÁv_“¶ùñ¥—,èd….¦H:.{ªˆ‡ !ãu^á]9àM¼Ş˜¹£û6ÈE1D ˜"qØJ"„yQJöPµ±Œ¡ã¶{C˜WÏ0ƒÏ–ôuÌ¹ŸÿiÌl«¨ÙÊn¢/ˆ¹o¤%ªT;xË¯¡@YöåÍŞ§¯¼ø´b©–·½F]£HèläÂ“˜=ñj1ÕÁHCÁ7¨Çş'R2òæÃıÜÒR§ Ö İ<ÂPØNwŞô“XàÌ‚wğ(Ò¾Xşü3Ü¦lm½Ò°6‚RH«›Æ…Ç~pÛ°ûÅ8âµ;ÊX{;Ë³ßgÉÄ&!iûs7ÅÚÎó\4}Yf4¢
7!‹ä`5-]6 ³
ÿªÕÁ!$YH›ß)5’çê¦‹Z°g°ßRÄ¿E¥ªpÊÒ…23M7éeC†½9ê{êtoj(Î˜è, ^¥¤Œû•|½8ò¦is+"-óğkçÇâš¦çƒ8gÕïzÉL´7X0qzûÃmAçèN¯±nô-W ñ½Ÿ÷ÉÊ¤tPDœÅ¸"*ºê“İHzlìóTÂøì'&!òvë·‰·–µqåLÔ$ƒb“%vÃÄÚÊÉKÛ“…Õ»}Rxrs!Ü©r0»> úÑ5ÒYä‹@œ]ıG¬(Näw9!ÓÆûmVqı…ÉòBzb8`´xNp(Ài`†1dûQâdhÄİäÿÕ==¦ú? >ie…èaa”™2zzüö?uM/Lü5Æ‰ä ª…z„pÂß2•lŸà!T”¨mc©yM"ÑpÔĞyN÷®uTDdÿçÆØ›Ïq»şXx©Ğ±€îêJ–¹“#àûV¦_éJÃK—.r@$1¨éĞ†Æ”VéHnËÄív-üF”Å„Ÿ;	"%«ä[iâ$Åõ¤-€ÅFX	ñ;Î¸üø3Ö|­Y*R»dğõHlÈìíJ¦ƒœ83lå·ÿ!£8*Rq{{K°±©áF³Š”»í›JÈ‰vyb¡‚’y‡ÉØÎMs1ÁCäPà R·«èV7ÌYŒØWˆ«¨„,ÀHSµÊ÷œ¤p5ÔR_KĞêÎ5]Bor Á`çB•jQ°à)ô»¨íG…›µÈ_¶¼nõè~ªFr:Ş&|ùi©B©K§“Šƒà¾İR½A],!=¯?+½gP_LêBóñËóº×Ã [H(×÷M<Â½Ô¢ŸäÆzÿÇ5ôßè´Éôß©ÏŸı!;ÈN·Áíà×o&?š‰³"°Cr¹ãÓÛÔŸÙöyõªoíÈt–çÛšZÒlüÇ¾›÷|ÈèXÏ”%Êæ9š)FÆ¥ïRª‰«°#Ğ]óÌla@hAãc<²\+Ó]êk" o˜³¦±´í©w+_.XF2Âc†ª9wæŒ¼ıl@¨b ¼ı<ˆ’æê+6n:ÅL“?X€lYÁÂ°?X·Ñ“‰ iØLª[BS¶;ë'’¢ı!»aF)@i¹¤:÷‹²øÓ­di#üõÇŒ$äÑfÊ#3·qÀÙ/f ÁÎ¡ì!‘“cì½ ÆcŞ–
jt7w[€Ò˜÷9-P‡|bù¤ö	 ú>bèNŞU¬ÿ7ËšÑ;ê«¯û¬	Şp!4Èƒu!8‡»%Û€2RqŒì	PµxÀ]Óö•aıGBAARãŒò¥Üc9ÉŸnU í‹7óÿG‹è¯)FÒ¾î€25+ëX–¤Kí¡.Yõ¤*úÎRøøt0ûZ7&=B Ö)(jÿy¤Ğ]8İ~ÊŸc…¶’	Ş²6/—´Ğ%±O1ÁE½`¯xµIEPß¯Ú¾"ŠâWK­ëíO™/ÑäéÁ-C¾Wvé8¹–êŒ™‹)w8½V‡fäO¡üvcHÈÒşı!ÇãeFV.‚»é€‰Ÿ‘>¨¯(y@ÎG%o;Mø5?Pôâ!ı1†¹¿ˆıÚ—Åå={TËGEfUÜnˆƒ”^À´ûâ.–[¬H(RcH™¥(ë#m`ŒH,lR¹‡®${ó7ú“…sÖ…±ùü½~9x­Ã‰
XËeŠ<K¹ÿY¯“;ˆ¯¯/­ ”é»Ùµ[‘R™&)ª·[çÒéœiâ[ ‘¥Â¨<Ô{•	YuÁ5Î­D_`ê0ÄAŒ”…Ôø`ãÀdí_[±Áø1ëÓø²`Û@PQåáÜ™ÀF¹Ápkzä‰ ÚxÁØ¹•1	³6‹]qîÅ”Õ ±¹áˆµü©¤*0ÇÊF§=à4¡ò’OaæÅ¹ 'pu²ø{Ij0iĞÒG’¤Êï°z¦<C”]Iˆ‰¯ubr>óvòOİ€S^%q/ÔÎ‚½=}îÇJÃKb~U”®&ı>œ'#r2=šN¬ÑK¾EA'­ënÒEê^ÿÔÙ Í¼ÒªNÖF¡2›mGaKS|Vôé	Í\ˆŸ-Q¼jdq¼He•ècË4â|bS­!•Õ,,k8hÜ "¡;,sm7”î¼~“õkJ¸Z“c‚3kcµ:r¤î.¿0¡Âğ,Ú‚Ò]•À£GácñÍÕì]CO©Å Dl$DDî²ê	„½¿õJ’¥|«#µE¹Æ‡£Ş:öıo2Çˆ,‰òüô¶m±P¢Ş÷ğŒf}ZîlTï@\´±ßI~…/¯ĞïE@K
ê4ÃÙ\ê¾üªÄÅË”pD~EÍeC43ÿ&|v"Bmgb¦]f*$Ü SéSg1÷æé@6­õwÄÿiÓ¬ÔaŒÙ¬b4¬]‰Ò…Ïºã-ûíİä¼8)W¶ùu*·Yı‹+ÜgG¼ËW*±|‡Tş+ê|İ’áşÚGä_ÔŠô]1Ã„cœ¥ƒ<€ú{>X Ó³']•µ62[°ÎÒIÓ×b€3FO†×»AşD+'¹„šûÚQâÛ®'ñÆ¦…•™¦9Cı§8]ˆqíSt½ÏÜÒn´Q{oÏ6uMÜk¶ƒØxÕNS["Ûf¬r¯XÂÃÃÕäåİÙRå%,ŸîÑ^@¡iëêß—oéš^¿D=6ØÂEs)×Y(lâ¸|LÛO1ğš- š¼^]2@[s+de+÷qHó´`İ×;'¸?†´æÖ÷¿pæ€ér%¦È_È^À_„¯øˆ]cbÙ@Eò9
á:ND§ÖVöHNŠ]è½_£‚O1ª @.´Hb¿ÏËûmJ’"•©İ§±ŸR¿•:$ê_|.³`&f‡T5[„µ­Û¤èëõÉtÃ†>)Cª©ıX>ı¡<k’u0A õµJ=ôí1¶$bE*3;…Úq4¿Ljb>-‚fä åJMÿ8ˆ,åù»ì‹§sw5"ÓõµÎ@
`ŸğÕ¿¶+ÃËĞ¹9ğô™ª‰/½š«	’°ÔuèçƒJ©7Z.{fï?„ßG™sÆ°)Uğ™/z‹cœ¸%Öˆëìd±ĞJm%í»’j­Diß]×ÓB¯r«Ä¸šig¹qbÒÂc³>ËAá>u9/}²Câô´lÊ·ZØÁÄ%ökÜÔ¤o´3Ã:µáy”xıpèûÚ(Z$êAÃ…|öÜ±úòqp[a”†ºªëc× äÊlŠ E¸ÏóˆhjÕóèt	ˆR’,§7ÄSà¼ç®_sös?ª¹€«kI\:N?3à-ŠrlüÊu×ñ[$an]¥âˆ€¿æmHzªfÏ„±yµØrsÖ$l’ò‘árş,z® ¦2w¡â8÷_·Ôuƒgõ\|è":}& ÕQ¦³ÂË„Ãœošs+XE„–‹5Ä„¨eC
ä[t¯/L7‹™Qxïı	Ÿ2* ³±Éçl}»ŠMõ.P’	BwÀ b;‚ÛINêsdzéíQ¬º›šO€
	ºWİâFë†8tÓçÕùZ9}æŞd@Ğ ËşoôK§YÜù‹Ÿ£-œg=CÀÎq~À+MGTLù¬ˆ•¨ÇeÆdN¢úÃÜlšE–l²İb5õzûh:¶ Ò M£}šõn±éÑÔ·à^°şÖ¼‹åQe<¦ÿêÑàéJ0D:@rXèŒI­,:(k£uw[|
l¾và q…Gn@´å—­qÜ«â3ä0Á¹àÀÉÃ=ªø'ÉzÛ1ƒ+~µ§~¼Ó©ø¬1ï¢ØÄÓ4Yn
bç[­ *€ññ,_n)ÌÓE:ˆ.N#GNˆ/0Ø·ùëó™g¡6>ÒaäĞıçFÚË‘±tÃaû²©ñûÒdY&Á$×ê‡!t`‰Pkø ±t¿÷6z‚^å‰‘®”e³…ÀøA¬A±ß‡Eæ¬+˜n¹›#¤İš<&Úç°6ÖÑg'7®ñ¹@ Ò­î3WCIÕÃW²Á†"mM›v²8r~Ã›OŠ}¡Ò›.X±ÚÊ[— ¶¥A>60…uøÑŠíŒÜˆÇıTJ‰³JØ`M:>ô§t^;ÎÌCS³`ªˆ¢â¨ÇQ‡¿ğquŸéû[Ÿ±¬…nÕn|ó‘Õ£x[1Í¥[:¡Ü! © ’/¢e4ò$ïÊ,Jm£sáôÂ•(¨có›´Üñœ¡Á‡·şFSZàÿ„RDËÂâvSÅ¸5-ï¤‚:¡Æ.ê‡¶˜ y6ãqô{o:Ñ*Æ×Ä-ÖH:Õ4ÓP^]ó T<„—Ô]õFîLÜ÷ãÖ+şFY0Õö}t,é¹c¶3_Ş|£¢ä¡}6T"ª§9VåM}˜¡› ìøT–3!u“wÁêk,ï&£‰±SbëÔÌ
»hÃ¥]     å…ÙuqÒK½ Í·€À»3ÓÀ±Ägû    YZ