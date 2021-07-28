#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1727575877"
MD5="bb971f043ed87d0799611db3bba9092f"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23360"
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
	echo Uncompressed size: 160 KB
	echo Compression: xz
	echo Date of packaging: Tue Jul 27 23:12:06 -03 2021
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
	echo OLDUSIZE=160
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
	MS_Printf "About to extract 160 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 160; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (160 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ[ ] ¼}•À1Dd]‡Á›PætİDöo_~ùöŒf•˜Úá…nìëõq¤ö²ü”NZ¯ËÊ„4œšät«yW²J2šnèb#*÷;õ>xÒ?©qŒ]íÄPH-GÛ¯¼N:§öj©ºr?ç´¸vJ0»)Yƒ)¯|ú‡FOe§óYÒÌmUxíòé]ş;Õ µ°O	<†§RÙJ%6ß=òo!E^ò'>y ™zEû½*f	Òİ9$4®+°ëtE‘×yo^¦¿€sÒ‹TŒ²z7XÇV²+lsiœÕ”¿
÷B¥HiĞÑ¤İ#é·İ«,üı/®­ù[ı!.nøÁŞ¤ñ: 5eCbàsÕÙB¨—<Áp(´½3^Û»uË‚ßãñ¢Fåd˜òÆe®øuôã eO÷#rQW€’«YËNñ´]}2ri…vmÖçŠl»Öb†û‰Æx–_{mQ0Q²)jEßŸç‰Œ²Ğ–ok‘Ò51sc6Ÿ•5„`ÈÆù [F‚ålFãĞDéÌlÄ.2/”u‘N˜•É™p+Ìárê*O6IÂ—9óµÈÁÁ8ßECşk†úƒgä\XŒÈ«©Ë šy°
s}Á•[·üs
zÌ‘‡	ÌÖq6¼2üÈ¡õê²€Eö/Tø¤}'ƒXë‚‹ØùZ„–xù÷MàE+İv¸=âÓ"äcgÕ‰/ú‚¸(îm&½ó‰32CziˆÄ²€?9ë¹âğèìÅ°ªîï€½˜æfh'2seûcªß§u‰ĞmB˜Uh!í-aûj@zàBì8sQ“x’µœ¼=·ÕãÒ`I¼·íú#%ü.€sådpæ¢)u¶DyI@DÇt@HØ‚:î$Î§Mv Ÿ^Ùq¥ŠFiƒĞÜI¸yT†}Â¼ıÒÛ|ªÊ4¸Ç'µt ”Æxìn˜±ùEÀÌûÕ•_„ £>ˆ;¨-¸½˜õ‚øƒ?–+Lš2oWµşøó„‚YJôÃÕ[9©¬´Ñ:v}yI..<LÃü%BD8àOºeôò^ ,iUø3SYõ^5~v….ıÙ•MÖ}Q),•°ôk©EÖÀR\çx¾†Un¢÷¨mª(ÛhƒìD|½,eŠnVqp?6â»AÜºÙ9´,¸=¶TçÌ¿(gmn,ÿF”‘\ØM2ãE\ƒĞZİ,èYYvFê×'?KKÇ{+ØéÖğ^.¬™\£™ÙÍˆ(+š²)xp!ú-ËåYô_UxÑ[ñs­~MÌÛ“ÈWØÖiZ±QDÙ™‚åZ,Ôük:XC³ g¡ÜŒUU‹ZõÖƒ@ "©^=WÀİL6:öÜÛUá‰D›	…“}ƒqß.Pªı 5“Ê—jÕ¿í
¹´Ya‰ÆyÔDİ‡'©›d=j0ÁÕªNÏVOqè6~M•ûSÇ©Îr…È=t ¾–a1šîL½Ç©ÿ‹vş ½íOµ×£é~$¯ÕLD ŒRªFİıˆy]¬hlÜ™(¾¹RôÌ~²Á€IN¸Ó„üŸlxcšî ƒã!ÈÆ§|E«ƒ2à`AmÎ,ú¢s°ï™1y¹‹É”×igóã°£#iİ¥DÀëĞ2y…ÀeníDY‘ÏO’Öã¼Ø·ìuhH›eÚ­ˆ›¾§ay Ò-<–ì•Ì®ê{Yt³ıÈÇìSCelÿˆÆÄa,Í½ÒöC4ñ‡_d8ØW3àù,È8ÍÙÃÑ}?x›¾U$L¬^æuAÊ¹‰k6¨«e!ÛÂmE¦=Ğ»úZ.:"Wµîœ‰Ññ X'şV’Ø¹ÃqQTu~%!pxÑìsªg_i¡¼›ä¦¼´h„aV×¡+5µÃî¨nÅ›6'ŞbÁeÉ”¿KiÉƒsD¢·¼KA™Lf;Çáóiça²Û9"¬ûZCÙ+Â­¼öÅˆ–Ü÷ÃÏ“h:DªF«+)ö›q™˜‹.«÷L*fûY|•í¤Àè÷BÈjô
-^~éM…‚ĞDC2œŠ\8.I«qUTïª\ úzÑ2ŸcEO¿øaÔÓuÆ\òbµF© [>DÎ•&ÂnpŒwk€K*}„Å·èjŞMklKsØ Ğ¤Öw™Ä8õe~?n?ö*ê±,ìÙ·Ÿn¸]¬c.§*sñ²ÔN˜â
° 5($a”§bš ¤ğ9è….~ôâÈ«Sv£®ÄÃqïŠk¹>v™sx@«Öv§ü¯\ÍÄ„ÅÁõcU²æ*şÕUUÏ'–1=åæ4Œ´4Ÿ[Zi›foİmoÎ>]Ãüë$ç-Î¾MuXşê¿ªª!âBëºX8à©\°Æq!31Êşlä6v;Û<_kæñv©>`ìğÎ¯ëhÀ¯-RèäÌóoÎ±Ÿªåßb7f€˜ºOôg1®c…&Gx˜Dıì2ºmç}è_UÍë‰W¹`¡ºÍWĞÁ®T»&A	b„æ|*Ã¦Ğù!¨d$vD‰5:ËåVöIóQ¹½²0C(ˆıßUPÎP	Ú:: ˜_¯0»¾8ó½öÿ¼ö¡Ş£ú&ÛpÒÒ1»ZRæTSk†û%7ffX1™+*Z+ÙÇ¦eÉÜ.Ö—”¢è ™£ÿò‘S˜n¸Y&‘ù#ã¯ˆÀl	FB—c°ñKFàÑpØ›±„M;IG#ús)ÇáqÉµ?0J}ØóXØ÷}_~/]0ã3¡Ì /•6“H¤¨½ş©d]nòQ<ÚtÉöÀ·Ayoo
Ô°õ.q“‘~ÒçÀ,~»ºUš&Wº*"ST·jÉ¸»z¿½¥•!œÜÑš2ç*>tßYtL´_°¹©óTTÍsßé_X%Lzó¤¦vs<½txy0ìÖÉ2I˜Iw+=óB4’]Jl}
ËéÊ-úšĞk~÷Ë«êwÓ¹N }î…lõ7äb† ~±õÏÓÒè@Ş#*‡›67½~0œ%0w^cÖïêŠôî×·Û$¸MXÒt=e‰™Ç3
h'å¨?ôó¶gêj·°Šƒ¿x›ŠíÙîÛ¤Z-œšæïù?´‡òÉ¢%†¢]Ú^ØRhïëCMl‚"±„U‚#ÕJ£¾“óÄ­8º~–PÊ B4Ÿï[1ßrèƒşC_ñÀã£ôÌrå} Pd]T#"ßp~~Èû„M%ˆ¥OJrğ9ÓaÊíTO¼!œ¬KÊëe>”;q<·è“ïÕp8wp®†dGxP_‘‚Ú„ÙN\ZôrÚ,òOfñv*»u–˜Œyn³¨4ÿñš,!Ó$Ç¹RªxfƒFÏJ&:ë©äf¶EzGZwş/_ÅäÖ÷ÀåŠù¾ĞÁ)=şá…\íO#˜±íÀş–…‡g+ª|€†¢³²±ñoŒè¯ï>0?…½p1èÂVİ`Ea¤7ç&êùDÌS‡ƒüÙnvá—PËß;Ì­@/¦­¿:t&ğ£r¬ànè­WÕ¹d´Opè&×ıDY\ê|íÙÛaçUíß.üL¤“+§®{ë‹›={/È²JJÄœzÀMÿıüîAQ*”ìóÀÓ?åC¶ÙIH[w¤©öÆNdíyjS¬t±˜Ş¬ÆV!tøş×³´EÂ oêˆóßáÆµµ>©ôÕB·PâÛp:BW‘œ”;!ráâÎæu†m»_õr¹’èbÜ_‘­Ù–òìB¬0›·İ¶ÎÒgDA§¹MG =!}G›1ö;ÂOß¸½ı§x³ŞwiıJëEÒ±. Õ0¤²ró´‹%‰^^æR¡­D¹,^Õ‰AWT×rb,¸Ch	N[sYp]K¬o<ˆÖ\õm]L¼©±zÕ<ë$`ÀğRß´æI’J…u•T!1²˜ïòÓ ¥Íæ¬j(¼¦Á„@d=1Ïdâ¼­ojşÚ¶MÃù™z2ú­3e›Ba™…‰úğ;»@o{8ÁqXJwµø§$Cè,] ù÷}£Ø¤ØR£<.&Í£³††“N{!’0{7­á6³n8ë´vÄ÷#yí‹^¨P<èLpÙ-g˜'àŠ
çà¤°»`;ã¿v ã?İ(4<l’dÛPâÎ¼ã:yGğ£3Ù 6Èq=¦°øËl³4€*L”éLÍ@k4Òõ˜şq·ˆ¹_ëÇ.üšşw¶V	]_>ï#pAGBŞŠël~Èe#Wã(vç
÷DB
è÷q«z‘
ßõ1ÏRÛ¡‚ïL÷y¢º ¯u.M_6äô™¨3_M6\¤ïá‡ñq‹¹’ûM²>,âİ [\@6õÖä>ŒY´[8Ì¼(§qÙ‹fA7RŞæ­í.Ò9\¬wxØÿ®ÚPgšè›©²Áôãµ¢¿ú1ş¸öÏ¢[‡l$Š‚¦êYêA,˜.0QókcòÈ?¹‘ÁÖ¡-æÜêBåúÙmşÅ…½Y[âÈæ‚‚[ãµ	oz6aØ"<,)v«Ê…6[n6Ñrl]Üñ‡ó¿À¹ı‘í?i!€Á™ÃÛ-ÕÇã9b£Yo§â¬&ÏVgD#¡Ì~Ğænß”‚Šòà¢×b®OÊ$z—–Ğ÷²í¶sQÅÏi¥1C†,nús¾âß-íDMßŞàöYîz?EcÊeæø

Šw¼ÂÙú(“á¯–Şuá!AÎÒ€³V[˜fˆT÷Ë9ö<W¾y(0–È-E_¡9#àÔØ4ŸalÒ×?Ã“U…'I2p
|İkòY‹™ÿ¸RãÑV—9yZÿÚÜ^
µ€0NĞX™Éı‡2gÇ
(û ²ııD¯¥Zˆ˜¹4!È‡úózà­iƒ‚F+°üIİğf)K`pxÓ†Góş^7”Ú¾sÙ²Z0À†®úU•`ò…)GµuÉ('Ú†Íi¼Ä¸>QËÙİğ";ËVCb:¤-a™İi­Ö»lâ2/Øê÷ñ’¯BKêaÕ÷?Tä“b"ánîç‘„g7ô$°µt=Í,4=Z‚r7ÏkıIçîŠ]NŒş{®øM2z’ÙÕÊ0grş‘AGÛ¬jIAƒŠ¡~v"¯rMdêO…TvÄí(@ ê‘¶ÆËSêëò[GI ‹x'Ê&srÑöK!a‘uyìäYk{Û iş‡oªÂ¬M//1òG3e…vôÙ1Ã-½*smJéãXÛ³Ã¸<åÁ[,ONÄ	ü£¤D*}¥ŒlàÄ,h$â>""Á‚È\9²SøÊWkŒ İ¡9´«kıŸ¬'iïe)Òµ„,ü\²ú ‰øyl;ŒS+îeDå´r~ãu{rè”2Wí,˜£²?kÈÉT§ôÍã{Zä5§ˆNœÇ[)„œìHŠ”¼ÉrİAmªha¨¦÷ä‹f{€ÿ‡TæğLf5ğHò¨œ·İ)vN'Wß¥â2°s…,œäo2Ÿ§¢”m{5ã˜&ÈÁ±åŠ’ë,JvY^á'dEoÇ¦gíÂ.´è­İ]6É–u#L‡²oÂ—ET[ŒO~8Q“åìkMR/MÛ[ÏÜ™^o  š­©è0EÒwÏ!j5·©¢ùzÑ]£tÕiî°•3p?½Ã@³e0QjØÏ:’!Aku@òÓØËNÏÛÖŞ*O–'İm“ ñ#¶3JOjPâĞi™›;X>UÊQQÎ¿H/€™áèğ!@‡*}a•·? İÆkÀ3óVqjd,Ææ|íza$v-İÙĞÃ_:÷ğİåèıˆWné†MLªx§çğO­³bIÄ!t[+¯‚pKMûqØE¥Õ|1.s<ª˜M#Ö÷ƒ²U3vĞk¢¥YüJ®ÑƒV—ğ„¿âŒ,?$*‡c{êt¹7-öOĞ‚YaİéÚš6©+²UÜN­¼Ÿgœ³Ò±½ù.ÌWw.\A´1Ó(Xíœ"NK€Ø”z²£ÚÂ"=ò²çñKzî'’Àâìé†pE£®ïUãë_Ÿ5İdãskÇÇÈZ¾]Â<]=0˜æ¨Î*œù‚«ı»Pñ‰tÉ°¥¸óh‘Á\c\Ó4·7¥N‘ìdØQ¹#£ıåh~9Îv¹—@<©ù:©=eš°q"”.àÎPÔßëmp0ı{¾‰ÉY¡„æw€¦¥¸IˆÙÁwD§™¸ÑØóH²‰t[í„BÊ±~À9ÉXJÀzÔ”AÑá1Q¼êáuë^˜™R€#fôÍ‡_iÂ¬„ÄC” %H’G³¤¯èÍ¨<›”/–ŸÛ7#É_»÷È·óºG]’eX^k°—¤ØF…>÷o™„§öÏ›ôÎnevÿI„²åEšA¶Gn)WÚ8Dø°j¿¹Ö¼»ÈŠ7`Ã®8koÁ@S`t`2Ò%i¹qóZ´H}
nÔàÍT¿M*\Mèø³©D/·Ï0…C~/›&cÆnt¤‰mZË"ŞÅkÀfNù%åL§e™îósÏÔ¥E:¥vö'ß•­ÀÛ­…R)Ûõö‘?@æá´¤dÈMå-]ŞÁ*¨ÆŒfXœÌ sG’gvû\\™É3e×µí¹énKÎïò§Ÿ3…ÕèAävTs\O"uÁ$›+M‡q(ÙhKËÕmêW.=Cä<øS<_‡¹gÂlš7İfs“ÎûDœ²85Ç…*;ªõ“m»ñE]– ²Dgsõ3ñJ‹¼Îuwû¨)¦ ÇS¯~áw»$œ@_§k²–GŠ[²qv«ß^íƒÔÇŒ¢0H.KTšcA±­mşÄ·
)%m áXZ«ÊÇ?”h»AOì8l¹<æû´{àä)­Céçëõ)®,‘„òõbœˆ(<µ¬“hG«â.—3DÈ»©FÒä¡¸^¬ŸVh*²ŞYóNT›¨>\¦c·>ùW.Œ`ö#˜ácÕi–[Q™¡}¬[ gwSÖ%jÚ¼	}ÖQ*ZiçdMz~5½Uc§«Şí3]±‹qmêZH“pûi¯¼âñx]ˆ.Qi¸v* ·3ÃşôÛ« YÛµ} ²îGL¾^ãiª5šjuUú*×Û)ù zÙùv=ÖÄ,À›Ø[âÂ)€àI¯h—°¹ :AZŞìYW‹ÙZHÿŒ`üæÉZŸ>¦,QŸ4´E8]@yßÇšN‚=q ²™7±™^¡
g½æåñ™Pm}‰³†F—Cb¶—»Aô#ö’›˜Qá.ğÎ½·„–~ÀÔ^¬éYÔ6GìïŒ“ö@iĞ©ÍnÃ“Xõá`5ú&”˜_£oÃHPhıÁÖlœlù hd%Ì
ê½š
¿5*qãî7ùál5§˜B¹ÁÎ©×åz'+°¹IÏlµ™Å0Q£äÆ”—¾©ØJHfdp4«Õ†¼é†
4 LëšVMûÁ|©ùxòä£5¦Íà{9×îáƒ°Dø{˜|ÊÎÎgs˜%¢WõQ·‚z¯¥.ofJñäÃÇç‹4œö¶Ùğ#ÿ(³²€{íÖöoÿ>¥¤bydLQ8YHÃæ{Ü>ŒHóé‚Şõ´h7eÒ4*ô_#Î/W`¿l¯×-$\ø0ƒ«FØüÕ/™!é’ñÓ6 İöŠ…|£écªp§X¡ñöS,%ƒ&ÜŠaEq£ªöŞ=ÈI×<ç	>Şy$é/›Í¶¹“‹~=i„a©¾·=8qÒ"ÍIŸòêFgÿ@XùEJßåÉ‘;_i|—­àÎ¬dÂ w…Dí…q¤é&;*B†-ã	^ãş¹D~n r¬Øå.ìdı%Û=L~
zît¦4ó­¨j±9d”aZoîT´ê,A_È;]Ä­òígq'ïw5a}FÍ6}ÉÌõ&ĞÖÏ{±b6Ó®(bÆÂXZtä:0çD½‚º}ÛwäMœû7)Î†İ>nò.€ã´OËŸ¹rÑ§Á0,-·6
•ßx@dH<ø?ÍªEù2'–¹º˜ÃÑ4?¾â{?Ò\*X,¬UoÔ&ˆùB²c€×#õ¼ÃA³£¢‰È˜}È3Œº}õHæàš§Rü©~Ô7h“(ªŸÓÿkW
Øø€6ì¶h0©e§½ù@F‡,0Ì—3—“ZC]UT‘"3Ò&k4TÀ¤WYÔ‹å–T…µiâÄ9ÃEÆL÷Ç"2n³„ÜÌG¹ˆî˜­Q¸xßkëoíK÷Ap·Ÿ‘½Ì&şn×Ÿ†e¡C•Š2lë){pİÎ®Œ³Ññ¢ÏVÄKàŞ™c¬Jé@r‰¡MtñP>}¤{*£ÏÏ¾Ê‰…«ÿA?‹0âS”awséc.şµÔ(«y±QUé
är&kY:AÂİÙÔŒ °^F‚&¬oÈéÒ·“¨X£{–ª(FÂ÷ô!¦cğô ]Fİæjæ¨¬}~È7ÿ }%SÏVHØ«’Yƒ½b&éĞüè¾-’rSƒÉZ'¦¼Á<‚l riøşPiµ9WW—9¼«YuûÚ?Óá±d3Vˆ|ŞòĞ 0Ÿıo2Õ+CÔŠ«Ãe›µ²,Ä”TŸd7U’Õ¹?}ênÿâ:—Ÿ«Ù¹µ^¸O]×åµ·[)û¿
GØjA^o†*@MÜ[â[_/Ø´¹ùfÇ(ê|¢2{ÄîKš×m‡[vØo)4C«äXnJ›tÆño¹0sŒ„@…¼0b˜b/qëŒ¹¼“½'ú‚ÜÌXôÃ°„?ûÍ|µ¥]\d¶™&gÀ¶“ÛËOêS%™ïìPi¨(NrH|jq’É½bû%E¦]:ÛÊ‘bÉüà»_ŸW âşÿÑy¨Füò©TI]G0ÅãWèá=Wï¼ûÍ(nÛ²ÜØ-]ª‚HKÁ¯%oæ{íf¢ñì·æquÇ¢×š“Ä&‚Î›åKÂâÆ$äÇÌÎ+â}c:Qâ/¢JM¢óõ†».AµŒì“ìÖA…ZáªòîQtç¾ÎçÊïiYZºh~ë©ˆà£F‡ÄyÁ²µø”Iq©ÅQ=Õƒqö\id@TZ¨I”®N-hjÃÙŸ…Äy|¼´O<9kécF4Œùõ¾DÂUI*¤ñl·–d“ömxqÕãÊ@êV©ov¹‹d‰%àˆAI«ñ÷§læ´QfÍÀä°vkÍù#°yõÁ•ßúít×\±F<Eò÷‡mº	„ƒô¹¢¾>ìÍ	jg…3¤åÈ­sá^2rÉsO8‡n†÷´" #fnÈÇ =è‘G¯rŒÌ«-³†­AõSõİoŸv0ó×sº!8œùÙó«D‚ÓßgY9V§he8Ç6Ç‰;~±*­ó‡™7p¦úc+,C}®İ[_ÅÂ|ıÏ«PXÍî$;´çœzjyY
œ
W€“m‚ÔD)Ùß|^gÇÿÓØ‘ó	)J54åºó!?•,(½ÈuY“wHüˆšù®7$i1y¨{G`D-4ÎÉ=Œ†³~¦Ypv<ê³ê)æï–
Qø-úFxmh5xÊÅéè.K¼È;:vµxË’˜Ø07îô~h~…‡=F_ëj¿K(m-=²([ş9N‰~¢ˆaÑ‚+ ãqY•$–€
€5à9ùSíï7ºí“ùsùÿ\;]–ƒ“Ëdp­º/hñTZ©'phñqII
ã‡‚¢  •?=3±;HÁ×~È¸íLQ®R#E
|Dƒ@À7ğh7ç¼¬€ŠÀ€Vù»úÅJ}gô€VÜƒ¶/	Ü—ÄÑŠ ¥èÚ“µY/¾Ñ!ªˆ’¼KÂËT¾¹i1é úq¥`Bè¸d7Qh{W
VE|È§B3tÏeW-TVßW5İ£Ñq…tïÌÓÈÅö–ç à˜e*İÒÒk7§Tİ‰äy%Ê¨Øš"×ñ«†åJ%>9åO3p¬ÉÔ6gñ§™urÇœià£y<+5YBóhlÏ˜Ş_3“Ú0åS&ã7­a´´ôÛ|ß›ÌKs,şp—½Ä©Æ[à”øÒ*–D¾GK—Zï®°úfşU{'§T&lÑÀ1€u ¥ä¢¿•‰%®JÜ¾"ú^å¸ÌGw?·%‚el›•ßŒ‰Ç;2jb2¼QÕ‘[:º©ù-»ş,ˆ-R’#$ÈÜÓQ=¹6Ób^–z­O³›¾S:OÎd]È:8J!©V<{¨9vJàåöMós†Ñâ#åd¿^5ª×†œü‰qÂÅæd’0ä(n9X©ƒª@4káIqÉÿe–§ÕfY•D¥¥¥iÏóŸ9Ì	%ŒŒp6Ï€P¥–¬eaDòœ‹ÁîÔíûqFR/ÈéQùU’½êeÖ×c
ãƒ¿`%†ÜBj¡QÛ¹äyu…ÅPyZ%ô.ûëá‚¤kâñ””2ƒ‘Ø4h'½Áô›Ã¶®yaµ\Ñmu†Ú|½3œúœøèê¦+©B4¾^Vï ?2}„ ªsÑ7•¡Â¹+hayK=£~óDxE:YÍ¹îdÏú®Œ94Ö*Ş;Ë|¨óóA…ÕctÌw¶?²ù.ë½;Ó™óÄ×>‚Â¿ã€9Å—ƒó#IùEké½²[À|Ã‘Ló‚&+¤:Ç €.u€¢jwo$éY	‰ïİ’@}ßJã*©ÔÒ´ŠQü¬¨1­å¨%°}“ŸÕïÑU¥çÌ»ÅÁX–€¢¹/8¨Ñ(”¤êh¼~j>æìÖ7±£\ñ¦á`F²éÚ 6Tˆ|ŞªDéWİ“ø^E‹ùò‘ñ·§õ÷»ì¤.HÑqÜŞĞÔK¾&"Ì0–gãÛdÈjxfAğw|Cd¤—>^™2SOŸ½ßaZ§Äêp¨ãÚ°‚ã~{œ¡kGñø€«WcÿS–“‘¥˜/A§—²d sI‡Õ!hãe½•ï^¨©£n»%õÀJI×‘Ëu­ÂÁğJ†Á{ëY5{Ã{3j"ÔdÑWÆ¢)ĞÚù¿ãT]s¼³gÈò¤JO3]e¸=j6Éî‹/.#àiZÀù·³Bu0œågXOeøjR£ÂSıA‘ãC¾,ÊÜé‰6%3ß¡¯ÌUjyø¾¶â}.‘³èœ*¡`ì¶Ù~¼¿‰fçWcõÎ–àq¢¸?µ/ìêÃhâß9Á·xı„-¹HjàE‰ˆ]ÂÊ´yJ«ac‰VkNdÚë}úıœ±ó1|Y¹_Œï]ë¨o0é`zVSÑHKm‚×bO•¹Æ¯^‚I¯S†˜@º‡ZìkŸ<êVÊcI¬¿)ô5^´ğ½\JÕ`ÖMh=ìNlUvW©Mkİ÷A˜J	rÆåF°ë±óì¡_¼¹Á«^äDÑVf»n»,‰æZ åxÀªvíÄ•–Ø…E3,6(si^Çi»)‰ò¶¢ˆ‰Ï7K™4È]ÜÅø¡£#ØM·-·¸lb»;ô¯a=)Wß%¯_šdU>zD`.l`pLä0®úkŒ¯€%Ç[FZä~„ÒÚº‡)wL°»óİŞqyÑN"Ål¿¬%ımå4lA,çÛ>X_gTxx^1š]ùM!SÙßîu¯i’XY¿ù˜¬î(ìjçáàÆå!g	3â«B3a›]³¡ÅCnÜ;§É½fÆ'¨ş.mºËœDVÜh«ÙÉj…Hb¤‰Æß"ËóÚÌè,¹¾·ÏÑú#ps2É[q³kxîù1‚VO^^¯Vóòn¦5b>Üô·³ásçbY›Wr·sÖßvzá ÏmO¡]xß®0ò¦d{¨´À®îYéìcCÏç2I¤çŒ©ÓÊ1#ç`Ú~E=t$ÁVd¶Ø+|Ge,B`«ïŒ¡gwïü‰+6„“Bâqº¡ãÈ'¦2?:KW†75h§UÒÅÅjˆ²Ëâ“Ïœ,¶V²ğ{d‡´KMõ‡›÷®èWSQpmîHÍ^H˜wü™£ËÙ€¿¬+jçêå"Y‰ğePÁ¾M·¤(ZR¬üm|U
qñ…YÇKÆwº²T•—†I®~µüüó}x²öÓƒæ«‘738ñé*®ë‡L¼›³ª3‹şC@I"T¾ı]à‰ÁË¢–ËŸûuuÃˆ$@u²Øv8íäöÙèPc4½h‚|·ø€&?:Z„[ifkq—fc˜ÿØŞ@YŠĞÖ	*JŒoó‹œ{ÿV.~b Å×6ƒtÑI-B³ı>à´y¬îÃ<„V¦) ¼ö¶Ë»ø
Y
aüâºEõ¥&Õu¬âky(¶â/&ç°®³^h›U˜¹Û0î‚¸XÂeâìTş=Âù}ÖĞš÷_bĞ{«ySÌ¢™i_a&–ûq>T­‘x£3F·i1=«'—C¾ü^üv4©€§¶øo]Àü‚µ$¥áªÀ=1
UújôšçDÉá7`Fóo­ÿyj¹Adu¹*¤YüÛR •ìbÚñóû?h(æóˆòq·&ÿ›ÿƒÚb{©vEÚ©&›RÆ?ˆ¼Ö3ÇtX*€<^æºc‘} e8vÖW%2ìø?_Šv3¬	J,p›(à¾»/½ÔÉÉ;åI!d.úGãrÄ»rRzaıKÑ¹èëY^ªéßÚlN÷1ÕŒğLÌ]¥vAT3Ùd¢£Üİ)eÿ²G¨Q|ç –g:líÍ¾~Êwö†ÑÄôG­!<F–2šQ|ÉûÛ`¤âñésm§!4ËˆeJj«YÏé2’éøSêÊhLÃÂ‹L6‘}dB´uÈeuãF,§Z*fıÓ¥åÎbïŒÉÌÚ¡	}cTÂwô¤¦Ã÷ôÈÂqÀUæ„`%Yµ_êBİÜ/-û¢àFfT‚©Î&<fŠ >òŸÿ+û·"ûê3P—›¬I®ÅÇ e;…dCÂ~(•ÿ€êk7êÎ³“
#¯]ğ¸Ô[ù¾ƒ½ÁËv×MşW½ˆÊÖt<#M¡—HÆ’Q%Cbâ„â©©„»4®E¡°şÂ›:’`ö
«
èİf?ÓÔAŠjÍ*­Xİ¨‡¥[Ä‰khEtó¥Û«ùŒ/€É.õÊ
|Hùûğı5	Ú˜»éiûıbz}O|aCFnƒE•ÚRd$ı,{o¿iE<6-¿ ­0F_x“ÀƒvÄØUonÉ)@“Ÿ©“Q“q}åq¸C]úÿY® .Ï¿Ú_ÿ	Å—f9Tû\m	§‡ÿh'…üåD¹µµ®½bXuAÔcœªƒ= ¦zGƒ)Ğôzyci ‡BfğÆŠv`.q›_‚¾°‚~j‹Õ@÷¸1'ZÄ‰"ğü±;î©êhOíÈ*6•¡Ò„¨e)öUªÃB­JÆ›¥4tK¬”ny‚l#Œy$İ­n'q>qªÏP[SYê«*³MÇÙn€P>á›¨£Ñµ‘'L4¢[:0t;ÈuÏ^ƒ·	
ÔqUuv7½àuN1]¢‹‡`åqçP#Qı9-‰öãFpğrëA¿{ †ÄÀM]vŸ­˜]Ùs§ç†…ƒFAõ	LUQtøá3s9¶±bÅËÍ]ğ8‰¼x¡?›¶ÒÛK€:º> â6šœLÍµTbÚ×`	f¦AOyóº:	Ærö€~O‰ìkõE8o—%Ğ¯ğİ<¥Xz`KegL<õÉQ-q)2À7}²V×à ÁÏ’–ãˆd_±™Ò%®Ú]×H§h|—»„‡}!«Ù†H¸L#Õtí@ì_¯R¹ş7)³äÆY¿¦‘uy«åİ4E`šEø‘9&öÀhËÚ^ÕàR¦Sù–›6ï‰\³lg½¬‘ajâç$ú3ÀÄbéCÈG4İoL–Œ›cüáó¼UÕ7gu‰'Å‹‚ëßÏRO°Á6¤K%ªH©€në;;ÃíÛC¤Z»:`#âãrtû6Eş!^s«£b±3¹?åÑ^È ãöœÒ1hÜÃ†o*«Wñï’ãéÆ”zİ;HY+¿TÊ\òÓL•-\fLß&5à—ü­ôãµ~@ø¥Ş{DÛ9ŞÂ¢XuÎ2^N<fßx1Ô¿¡¥«=Ëç·&aÁ²a$ü¢pùTÁ”©‡¿,¥ÌëÛ˜¥ƒâ™÷ÃøqüŠø•ºq3‰şƒÛ!­™à=ù:S ½K`{<ÙãS±í–Í¦^°áù¸„1@ÒÌÉJ8ÙS "£Ué/„Æ RFD=Ü¶{ÚÕÈ3û”yM“=Q(½°µä£)xª?÷òõ‚û4°Yƒ”PIğ®ÌäôÈğÊÇÄ-À õ“>Œİ;t
QYDê™Ø#ìèÿÇ&Ï«Âjú,#¨ÀÖÿ.±ià“s?5ÚW@Ë½4RzÉ®vŒ–ŠÛİ1òÅñ­úï¡™ş.rÕ[­133‘şğå®@F˜:(ÙÈ{`JŠ3ÚÀÆtº•ş«	é¹×ãM…‚}KIŠÛÓûŞúÅ¹mgÆÊe›ÑZ*¹tgËÄWe7¨>lŠËĞ)MsQé\J(½ ‰ 03gíıê”¶»‚:!ÖréîbïAñİ]Ùy'.Ğí4âCı•C¥Js@U‘²[ı»ÿx­¸û&@‡è?u¤îãjí.4õ‘v¶€Yq—*Âá@úaØ|#­Ş+Ç ÷ÜEU\êÆÃ¢.è<#äu_×šWÛĞ\÷B#|q”¥©YšàÑ/è«Èy8*fŞ‰Ê`‚Rş˜ØÏêŒ¸ –÷`v©àÅ­v
÷ï­_í’ÉüClDİ'.mt0t%|Oã‘üûÃ&Ç}Â®çË¨Š<»Sq¶<G+r¿ƒx%÷×m’Ë¹››ëNÿ¿¯ ×îŠ¿	H(FN*h=kot¤ø¿=YŒ5^2Z(ıkÖ_J›”Pøš SÍ>¬xhKå¢ùà¯<Àh0ô“´ÑÙÉéeØüdPøc+ƒk’³[ãCaÑï‡!>eÎÏÕºÿçZµ<4lÎ\33SÌ¡Ïßó·Ó¾Ğ† œ†cşİíàÚóé¨òÄÆQF*™,A[ß¨=êwå³5¡®_LøvÚ¸Õ@è–hsr¬n)÷|ÑºàÙ ô¸¶BôsƒÀÄX7Ğò ŒkP%™>-›áqƒ¹ÄL×à›x,2@¨‘˜dXğ9Ä[ğrË9ªu‚Gñ™’e†¸s‡ÎŞ° ‘$6¼Â±åÿ –†MD¹ƒÿ71Õq§Õ¾´Œ1£ş,;³éÏâ°)å—W+Ìz>¦-ù)·Èòøº~l™ãEéC¾	îŞbT8 	¬%ÖzÖÁ Œ6¿^“ZÜ"9¦\3,8Ô ¸fÃi©]µ¤'',ùêQKêOŞ¦IäáÑC$Áô¶2(EÎlŞ8×Ym…‡Ä²)¢ü°âh$7TzÂ=ÔU+:â…½1<—ğµ&ˆ°RÀç9õİ¼’‹•aÑíA­:fÄMÆF"gÁU“ô/¥	dMu´%ğ¬!‚£øA]À/ÅNìÈš½ÈxwŸèÁYê #¬°+âÈ¢›	õnîŸh*éÔnœYYÔóFT*ë”šb9ÚHG6½óûY×;ƒà´[=X<ÜMiÀ)B¹nCñlTÄ±³ìù¾› “ˆÏ1c®öÂ»ÚìeèÏºÑÒ_–„«×fêgö†Øí¹mkœ_wNvÔ©ZA’‰W×–pwxâ}×w¾1‰z~‘ZÀ×³SŒk-™Ï2&IçíÌ\/ö­:*kBúò8î‹Şâ zï†õ>zÃÁğ°j(~Vö8ìüÏÌtSè
	!sexPnÇívQ‚xZ¶GÌ&ŒÏ-É]Cp{­ıññFwàqtŞÑh£){A!L'É838Â¡­XÄ¿Ç ._|QÊXÂEƒ-$½t½yûiI­f’ cEò¦‰€ôNFÜÒmºOGíĞ|ıoš’uÒpÍã:å-[“”ËÂLltC­Û-fÅÅóÖñÆœ¢˜Ôk'›F¾n³ÅZæ¯Är_¥3õäZöĞ`5n@¬SH„N0?×1ÃMjx:Í†_/O 0J•
Şç½¸
©İıù’Ù®$˜cE( tÀı’õ®%âòo†®ôìÚ/“d}<¢‹›wP@Ğµ÷:6Ğ§£o¯Ã=	ĞRÎÃ¸ááë[Q¡C¦ißj¨ƒìlº'ªô|}Ó]]goåsã8s}!vğLäÙzéå·ú(›~·ZGŠEæ€!O	m¦ğıè3¨²uÈ¶ğìíâÓh(±6záî»ì°jHŞÎFTÏ›
3¼Árâ±¸8ícH~X¸ S˜Sy^{M8üšĞ&ÏHÉèïš'ÃÌ_XY"Õ¶…†Œ”‡AşôÉ¬è¹­Za-\‘FLÑõö¯õÆ2İ­%üœÜ¶J@~ÛgÚ(W’­úªçŸpÂ8pEZ“7Ïß?Ø£®º`òì#„dÕºbr8£§!2Küßõ)78-²^Q·X|›=6@jêìfCkÙ}<³uåO6>ÕaKm³«Ã?}D#/™ò†Ayù”U½Qúr[)lü0rf>Ë¬_¢/Ç#ô
fÇ<9uïj²y•™ÌßDÉí¿F®/Å~7Fóà@é±îPLŠ]g²ñà6„ÀtÛVşq×ÃÁœÀØ*!Õ1ıUKébpÑkÏ#D*ªÒU»UŸÄó[·§£ µÄ
x®'.ş·«ëZüŞJ`‰B'¢ ¸#¢Û‡}—Æ×%§›Ô¿lyR¬®12Üq}GC²4´}‡]°ø§%^ä×£Á½§ ‰ÚÜw™Ï‹ı„ZG×o¬3We‹•¾ómü»iúo†ü 7Š±Ù¿Ê“›æ¼·a§=ñ·lìn7eä6»…Í˜9<N¸å´—Ï—:óvüİá[k”ŞP-'A7j¿ş7NÀ*Ê5»ïÇ$
=ÿüêVúˆq&ö|²´ØhêíËª,Š¢ëIÑ0Úùs¦‚ØO¶ß3Gá ¹Y}T Á¤êÉ<qjLLôìMÓ´erÌÜF®“/Èf"à÷£–ru±zVÁÊ}Œ‚ŞÉE±¶
eBJìûæ§‘2PQ.NèfÏL0æÈlÑÉpŞÃy9°üˆË{ĞÒ9$XÉï¡’tªsŞ?ĞUµŸ G/=ú;ï8àŒÌó¸4›;?‰?Y=SÑ¹í½¨hÚ¦¬¸K´óbHÎNö–›æİËgd>¿v‰Œ7&© Ví	² ğEÔšn•F¿An/Ê‡Ïß;Ò¤F4å?ó´KÙ¡·{¥?©„¨6›ã,“cÍğ¤å‚/Î0¬nĞŒ·sÃ5^:k€’ïUÿÊO·«TCX]ÎIHÜ™8Tjï*J¶Ş‰sòÕrG.©2NÒÈå±Aùú6!µ¨û“p OÑtÑª®H¨Ş½ÚûP>#_*
RMÂTIA¢Ğ¬é‡O÷<‡Å¾Wà½ˆ/6¶ŞÀÅ!šÊÓI£*»ßÄ¼©£Öê]Ì‚¥~8Y³9¢àq•Üõ‚g—Eê>*bP•&<\Gà²ş/çJA¨=áE˜S¬ÒŒ”>ÅÚˆª}LÉA£Wh%oAh}I<á&g Ğ¤”Hã®7’m¨T›lÚG¯œıñ`¸Ë4 ÷¡­*Õ”’×@¥iBa„>˜3XĞ¡›Qy­Q¨áÜÉĞ¿àx­Ô±ğĞç¦†Á"-ÒFü¬"›{ B(àù­–+rÇî<6^IÊ&S¹2i =ZÏ¹k€7ê’Eœª™~jN±¦ ƒŸôââÌ¡eØWQ…Ç‡åXƒ™:“ã”æÚ|‘DƒãO#•‡fß­èïê¬Öxé)Çl|Já
;GpÎ¦Â†f6'Sú~Y‡ıµ[ˆU['T	¯;ŸøU÷PQf.1‰şÄÎ©>“×ƒ@2]ñ…Ï’3];Üÿ¯DK=¹ÇÛÇRâ*ïÆ‹Ì|HTÂ+ÃmŞ'¥"S~0y3¢ş TB9GU<pm­¶n´ñ¥àü¬’ÜyFÚsi(ú! ¦î_â“î^î°ğeé$_! Õ¨¾¾Û Ã³Ò‚Xbñ>Æ-Òô¶ÿ²9¹ŞØ\¬óò°Bİ‚tª¹¨ÁßR;¦aÊòk‹G—>ïî˜ĞháThqè ,L#(+u[ô€qqV¯fÂGô@ŸÁÈ“Èà°èĞ„Hl>…ûpªIık…r‡²U£EJÓ÷|4…µóÙÖeŒ›=^jbB~|[[YávÊymŠÃİÒ´“mMXĞ^LvÖ¬T©ˆ¿GÇ]y¡ø1.òâù^øŸPñç?b’˜Ö
\ÂgQ¬Ò ø<ÃµKrkìıxv’1ç’#:!½ö·óŒG<#qÂ*<CİT3 ß]
J-*b 1Ø¥U¿÷óX€è€gÍÎäñ®];:ùu„.CéÆqMˆñH¿“@|šŞ]I×[F¯ıÅÕ”jµ>ÛyrØ‹’X;5Œß#Xù¸—À×&±’È§ŸÁªf‹‚"Ãó±	¸–İ#…Å?ÎŒ÷¦¾“@‚ÅB3l¹©äjcLQ¬BÁ°2zş°ÒÒå/:snÜˆä¥®X9lg1Í'ÉªhRB<QtÊ–"ssÀ0z%òvî$>"­¬·ëRÖæmš¦Ê`…¹`ÎIÿC»¸¿da&v=`Åálmról¶[¢té4^¥NìG?ò½p*1H ¹MÉ92ìÚÅµo8y¥"ÜvÂãÜÉ¶Ìƒ„ór®’rLÉ½rÜús¼%Mí>(²(*g]dšIrÜÑxšû‚­ 1å8	ÏóóÒ¿òsÈ”ò5›”“…f½QÒºĞòÒçJ4¶íz8(à.36:†?}P SƒrÕBMª¦:ò»9W]„Ul§÷¦EÕÛÛnµ»UX8…|ÊÍ D{ûÃ—âr—zr4u©vâ
ÕãÓ(v4È–)‘ÂğÂ(§UÏµRâ©Nû u™’v~É{<¤ryçÈìh´¬úQœ]~@¸Á!90:y~S{›–õhº´¹,õŠó“,İ0°Bôä– ]–üaæÄÕr®†µÈv0èÆ‹‹î·4"VSzzİÜ‡})?mTUéßÅÏ¡>e=+(­ËêOµÏöX/úƒaLfÜ©ğ‡•¬ÏóóÃİÏª„ÂftWˆ„Èz«my›KRW‹Úåî!™8,…`’xn:¨[h÷hıÍr‘‰Ö»„}â…b{z1[ÍŞªLÛäï  4şÄ™àYwnmwşœè¤V³!c¥cbDmsõ^¨‹/LGsdÔKåCÁÁ]½²ñ™´ÛÒÍ ä#“`IÁ‡bJ!`¼ÒºJ~pjô•\:"Jù[}æĞLÛîå ĞÚÌ¢‰ëS½5şÛÙÈ°{Õ*©!i³®}ÿ‘oÔpºzk3
ÈèR#‰áìnsØD)³Ã ´vè3a{Ş´6äÒX9‚ÿ)=ü6N9¸îhe&~ˆÊ°Ê½±V3šØ.xu·}”
o„¡€®„5±óÆ•ö³;Ó`ö¯å&Ôİ®Òé8§E¿ƒÓè‹;•G–u@ßçô|;&ğål!×ŠFC€?
¨ïzhÍ#A]xğr8R‘ô&T­+×Ğ»²B8v$ôÂ,í˜û³lmHb,ŒÊˆ{X8M‡ØƒîLŠØ"X¯ô¥Ùh²‡F›ÿÙ¥*CÆ‡¨«Wyuõ³	`ljR£Låug6&²÷å6•¿×¾‘íÿÀe‘ñ©ƒç´“î»™½^:áÔã!e“ë?ı’&o]ÊIğ­¹ò÷]ÍñÕ'si):Kª0zTjœêá°N¶‡ÇÓ£±4ô)DÓ#–}ùé$È¢IĞHBÉÂ2™Ğ‰=×«#º;Aww÷î °À{ÈıÁ†qD]êI_9ü¢ÌŸå¬Ó×ÅKØ+óQyØdbØòGmPrÿ‰LYËJnw¤Ä™Š¾!QZ –¢ğÿ:ğ¸¡õâcÉÚ0FX¬Q@¿*2(ß|Ÿ}œjwµ[Õ—eâ9pâ#_ùêFªVo÷s†¿@<Éîh]Ú,½}µdPèÕ|õ.sãsnİ9ÂƒË"Ácµnùçş$ĞåøO •÷KOJ¢·{Ÿbòå7Ø÷=XßÚ5÷ŠåwùÊX†±93Ök«¼Õõ,=Õ>í§58øÓıpÕë6×utÛF×] ¡ãVPØÕ@¦¯Dê£1u Œ×Gb°½Z®#q	?ïv;óæk°Íâ·ê=ÖË™^)8öfjù²„·ì¸§ê\øÎ°³¬¶È¼p>‡dŸÒ0e>½¹€ €Æ÷ÍqouŠÅƒFS[€¨m„D÷2Eû8‘ª7
@]®Ñı±¢ØôœÍ5§Å‚°åv QÊ½‹¥Ñi…!C¶i§%£îõ."ÖÈø‘ea®–¡ä³¯ì›¸ÁKİÉšAâæ/äşÅ%ˆt1¼oa£ç¡ëù·äBX½Q0şÊŸ0IèåàATËNË#…Ù"HG"Ä Ûƒ{Ë¾PxÈ³_‰IíÓbÀcg†»†MÚÙWÔÍ`5üõÎ&gKÆtJæ˜œ/½$ë€´mäşÏ’¿Q*·P»Ü€có/Í»šñ¾ŞÅéºGßbÔë‡oÔú¬ª)×WYûjHf÷3µv_{²û¡J¨€µÛ)C{"Ûÿå:µó4Ü¤ñÂYN<áÉğ|©8t;ù²še_µ€7cIÌé¥¿¥Fô«#ªòS¬©dà¤Eûç§^d´'*7¿¸C§érvÑÌ!Ç0¯»\Ô¹£Í.øŸh®wß¢7ßÅ5Ó…­{êâ´öŸ/eÅZƒÛÅ”k
âe>ÕKâ¶É÷fc­í%ÊË®ÖsAëağœÈ³Cˆ«°|MÏÄÕJÃ>fi6ŞŠ²V|äÖ÷y¡dØö×YªìIavØƒL¿ÆøÊ.¥DKZ»­Š€ÙR^Ó'ÛYÀTçÀ[T·KK÷í„1ã²3 ¡©ÏŞ6gx.æ-¡báteà:ÄıWk+­ÜÙÎè;x1ø:İìõ^Ô”ì¹¶¥Sp,K{1“N3½û%à6V)ìƒ÷íÿŒ\Yhü6¯ß[²PHl¼ãê-+õ¦w$³’ñ¢É9rœ]±à‰aN_óœª®\š×_8M¼€7ÒŠ’gWƒû9Û:ËÆ9¦35Õòpœ¡>ÊÖ›|E ˜i#íV_»…Ú8CŞWÃìó,½ğŒ ’UVs€åˆ¥º$èvızhÒÊ"Y°DŒUq§W$£xxKğëÂb-'OG“—şË2øºœ}ÉÖ¥»(ùy€Z/mÔu7pëÖ¹ÆQ·±LÏ%iÁ´£dwS:“â–*è†÷v~aPó×ø&"Î¤C2h{m=²Ò©iôT‡(GØºÚ„AñMg0×ô@ò0Æq2:	Î!%ıll¹®b·Ä‘¦]ø¾ë"àLí&>E[#j«ñWtcŒÁ¬áÒrşÅı<0+µdû=yCÀÇ¼†0´”¬©Æ*˜2AV1'©«$'ÚÑÊìÈ;8ÇnèL¦[şŠÛ„õŸv†¥kØ*¼(©ÆdµàZ!fÄî;mi=ˆ*x$”=ƒKÙÀW0X˜d~ÁËÀÌúÙ~­/6ôg—†¯œ-ğ¸<³œ Y°–‘oÒësï|i?‡ömTF µ½»·L‚;>){²ŞØ†`¾FJoyo
P{Kı}şt{ZsØ¦V0"Îš|èÖV\GMÜa/Åû*qj£–\Ş(Qò'åóÒ®=A`v¡i–9ı@Z>Øø€a¨‡·èS"XcAvô.m:C`Zd×ÍyË¼tG³AÂâ`é¯fy=ÉïX$M:…†|qÉË–[€@·FÊ¬˜pöŠ"7EsDÍ<rÈ/BÇˆ®	$¼*Fárd ¨l¹©ŞÚû8!±Ú-UÕµb	Æbàe%é.³E$†Äï˜J^Œı4ŞUıe6'¾Õµz“©nƒ(éZÙëK.îß€.‘	7­şWÌ©fÅ%Ö	çC1«4oà’Á©2!0äq Óÿmud°åíøgÈs¶cµ„põ6ËÎNv’!^UW«+\#M°‹úıí )ù&–’`g´xÊ×šÏ¤!Şí"¾ğ4Àß}K&3%Ël<+·	`j‡5 äƒI´>a0ï}÷à³k~zh¡hİ¯9†s!~ŸîE(Û:»hÉaïµYÿ+ŠWØÑ{B4ñ¹%„^Ÿ‚¢8¯Æñvù×“”æ|Ã€rëfúŞãüÍnÎñıi€ãtô!·Eaİ'©›ñÀÓBıŒ…áaC\Z#fÙ_Pškôc9Ë`¨L’ìG'îyÔÓ€ãİñ×¥AÑßyÆ²¨YùÎmNêëö?ÎSøñ¼_ÿe«O¨•±¬®5pğ'Šv³j¼½¾a	%xDÅ$ë™[ş.z•„ã’£)#.#=Ó~i©Õì4öÉô¬¢œ3ùîŞ‹´.ùdMÕÿ[2±±ö~# )|¤*à2'OåØß Şı_ç‚¹°éªww"æü½&Ì%<!-!:ÖâÑøò7‰Å	6$÷H
h³HÍu’lÀ~ü“€üŒÒ°ÄqZ±ÇNnj%S‘fÆ¨/&Mğâ£Oºw<!œyÇFöız%ÔÔ##Õ«PİæQ”ßïÔöce“®¸Iï%º¨å£yµ{/Û]
¬×–…i,¥" fTv‰ğ”ÆÂ¤èZP†<d¨İü“äáJˆ‹ÓUéÓ^Øš¥.oŒÛk¢Úù]¿Œ:JÚÿJUù9wğìÜT`7t¨N¶+°F¹­”ªh®Ø}Bş½ÅW×6;Ê·¯†'AŠÊk`¯zÈYE­Ùv69)»CR™Î‹ÈX‹–Kxúˆ1ÉÁeóÖb˜¡ùJcø>ë²^]P@PpO²ŞQ½l°Ñå(8L3˜hpTœ<kI+X[Et\œrB¦z#(OÓ›X
8µ¬+Àò^íSÕ‡ŒØ¹P”®q:¿Ÿ"ä£Á°£Ë˜¸A€Å}9Ê¼ÛÍvWàóğ-RøGS)ƒ­;èA€¢SòÚHÕ¾Vg=Ş˜®
.Ng­IÊ£-ŞlŒÅxPwuVÃHÑªUˆ—­ú6»	ôp;6^“†'+ÅÅ	EÛ•‰¨ŸĞ®aÁˆÊ£è8î;@Rvíq†Ñì!‹ún‹ğµ¶Ïr … ‰˜Êšã/w÷_ğˆ%ˆ¸r)QšùWÄòÒ¸ÃÚ¯ôúút%Ô¸mt†=zš£Î•&°Ø‘ÊÏÅ#LŠ£¹Âù@ÂÚ|Àr{	"‚l,ı,?a@®cbÇ¡¤Y"äc­ÊÃL+Öm¼R4‹lÜ‘šZÈ¼HqÅ“·;ï7FŠæK/	åøgHØÁ××aí³á¸ùÿêË™U¦äî8@
Õ’+TÑÁ _v$­ÛĞûHÙF	k %l8üF‹µsö2V»½6V•hşŠ)ı€Ÿîd¯ÖŞ¡X“!ıHbÕköd™“šÒ²PÓÑ¢ƒ»yK1¡§éY	tZÎ®Ó•*t_ ú½×³È	“ä.ZëøGã	Ôk‹ä×|fõf¡çiXš`ı(€É,‹‚)Ê®ì›É,N+òÅõ÷rvû;û]É†ƒËı¹ ½´é4TO0}†ÖpõHƒø	g©ãÌ¼µ+)®Êón#>NUòå<„UÁU"ŞŸb0ãBƒm%kıÙG™âRæ¯3­„tïKµG5v[,™¨™Øúâ	Áé,ÙŠšô­lğ¬ûò }ho×Ö
öªTì.Æáÿl§Û3^&ÛÆv2&Y½@ô=Œ ¿4#•)qk+Lác­°hrÆbøÌ”bdïªíx–f€.–6Š/I+©¢meÕ¥.5ä¦A&û)uóšM¶§±}-×QµªÔ*tõùßÚ±MLŸ¢É!MÊ›ŞÚG:/ßG gió·PƒgÏÙ÷íØğ,M2„;•¤ŞçáüCú-Jt<´Ñk¼?“(ÑªcZ+C;V•PáÔÅ$bi/–/ÈÛë?ÆË(-Qç3*ÊëD2+ÛıvwØ»bÀk¨Qa×µ\Êâû»¡s;ÄÑç}¸ —]}Ğ;HK¼ ÚRtª‚·»ÿ¦š~iò;åõö¿£»sM©A“BYöúå•qû¸³Cv5!¤Lí…‡ñ¨»zï/-$š#(	ª)ÇDşñÖHó¼e!ó åhCæÏqhlXİìĞ 6~_.ÒLú÷]Üvit3<Œ†,eèuïî±Ö‡4ç¨:Œ®Q¤ğ´UihUüÖv6Ê0ŒĞ«²†ksô%£ÇrßÉRŠûİO¡áîöq—¶7«À!‡8zUp§*‹¯§=Æ¦ÕByæÀ«æÃjHÇƒ\·l¿—)ò‡€În3/,â\³N}©™û5‹SlÃ[ıùş6:„ˆõµ¼/Å†¶± ·QÔù’ÈÓ$C¥kuO~äK ˜Š)>–èjï ˜€)5;>îœ¢Éáø‰½(} üoÁÃ˜9½0	®çºhAVÂÜ*’k"ÂöıDTº÷[¼XjRóùIZŸù#‹ßÌ6Qí¥î1ƒÈS4M—ÑNW2×óŸiçUHwòf´p¸öi ıG.+Í®ÉºM±×`¹¬Ä«ûî3¥/!ëæ>ÂóÜ¨—¯+?µµ²r’`æ:¶†f÷5¡¼zzÉ«(íRŠw›Ú+~Ö=Íúê—€ ‰w8­Jµ*ï*×d·¹)Õ¬ˆI:É67Ñ>•vw síXÍõ¸šG%Îì@á™}”.ŞÆSYy2’>R\)ø•ŠÜ¢•Í2Å¡i}fÖŸ7¸è°ã@ã¥-®Î	õóÄAğ.Ÿ	ù¬³à•=ŒËYªò´àÇ{¹Fîê]4.óhyùÕ×ÏŞâƒ¨¯P±zĞ«&Føù@´‰Ì¥:İ†Ä‹Œ`š%Ï_TÖ\¿ì}LnãÔÒ«½úJ`ñaC#|Úa0ÃNÁöCòr,×+J¯¶|ñôI×À6·ÊlÍ{v»‘$}¿åbÂh%.£`¾[ƒ\WÔW[¢Ëd¬6UÃ¡ûÒXTá©†	$D5J‰ÿo2ü’€n¦øÄúl>%©@ÆUüˆ—RLÍ´hDg‘Ó†ì5PÙ@¹°¶Ñ8B	—ä±Xçµbt7FëFJ­9FU,µß…¦~MÔ¬¶ˆ£sí1µh^°"Øìİú÷4[~×6‰Ç@zäe|Ø%±;Ê)ÀvgåøWsÊ»Wí¤ËğdjŒOË]”ÿsD?ë{®[/5îâÂ<,ß4ğÏîUSÂÄ21ı5v[Ú ¦UvËØ«ôVşíSWê´˜a^ÎX­b”¤fäj¨¿õ|ôŠğ[ïÇ–›½O‡N<æİ-oÑóû‰Ï~-©jxZ4æîPâ=dH
“âæT)'Ëi†›#¥2ÉFëGYS St4ÀèeIş³…)?,Q§/èÅ÷…wÈv­µt„7Ø&8jDGŒ	
GéZôÃÎPûÖƒó{0	ıâ*Œ%ÂÕ£iÉ€%¬[V‰TÌZƒì1º•j^˜³fmõwAQ[üwºf‚Ùz å
y&tOKşG!¸~°ƒ×IäO:²a£õxm¡ÖÉv½t¿OÑ2q•¯I+Iò=ÓÉÀ€w™ò½Hy¸)l	u¡WMb\ûšY›-%|1QÓi€ÍüµvÜNW®á,ù‹œzbÔó’sZtDº$í“Õsß¨»ñ—¥R5ê¥­_×§
ØÊ3¿m¢Ùï®ª ?ª`Ÿ)$³4n›m±¼î#şä;JÊ¨ÕƒÃÎ“îÅ‘7¨©ñ´íî¦úñ®P=@ğÓQ<ÏHlçÓçzAT|¦sœùè½W<Q»/Ê®Ê	ı¨=ÔB^E¼-”&^/xòîàˆQğ±rÿ}´»íqîyMK‡d)aÃ"á~ŠoæğN®!PD¾u}#_@fÖÍ(3ñ5O>÷´ûë©pNœHKzBJö\¢¯™ò™ìGtı+H"Hük¿?ƒí›ñ›ßÇ~:|Îİñş.Ğ‹èÒÃyáîL÷Üãygç–‹'pw3¨× è:Á­‰ÎG4Z6mi"×g2DóŞİj(oèË.ÿ@Ğı¿l‰˜9¢üuXïØ(WÏ;À¹²Šñ…U¤2ÃEù]EÀ„‚¿»m/»ä¯îFZµ¯ı„şú^IÄ 	¨°!09’U\p]Ûb¿ísÊy•çß}[Â€Ì­a8wyÖP6:¬QÎÊè ½\ŞU"5èHg‰60eæÂäYğZÎÕL±ü&Z1?çG+]8ko”QÚ9	—²NUoÙùıDĞ €÷'¥*’Ø‚·m¹0[—rãVõ3>:®]ÂĞ¦´`,°kŞ£™ÿÚ)‰_døê±„¢ÔSã¦•Í=mtÍ-à³ §M
Ik;çÙ¾Á0„ìzUpñBÚF÷öS‚/¹¡q_ß®§3¼ã…í¿6`«!X¦p¿Ş„’ Ö¡zÉ¡YRÆôÃ<d{´‘4ò-ç«ÍÌŸ-_ÚOÅKı|KÌÌÃMôT‘g|beÇÆØj|èÕG/E¶¯?åì£äuVHs`™ºâo©HÌâIRŠŸ¢¼~‰ê¾¦9I×2 ¶±ª+Å"(š ñu3ÚdRCúß•Ç¹æÄMšÏU‚yïc9ï5
nVí‰O‚Ÿ/œ¦w £}¢r:-hSQab×#¦ßìØ{™£¬^ßdÂíxAö|hcÌU›§ÒÚÚòót$ÍùÄ}¨&æmÎö<Tá÷™rèTÓZâ–|¡ó»Ş Şóo¡Ïñ¶Œ-¼ğƒ‡ék¬cëoåƒëRNx°o!ëÇä°ËÆ;üá3ä8;øÚÕ£ˆ€„<Öá&ï”è	`nd’<âÊ€õp|×l-¢?¹œKOSWB«xï«˜5¬Ó[;SÄ6ñ×dÂ¬ÇÀl Ş´ıq˜†ôö&ÙG+\Û="°¤‡í^*¤L”^Ä¼m»Îò;N&.4ïí¨KÒ–İÙó¬¾ÚSªåı
ö–<ÑahÙàÿUKÑ,îMt5Ü~ma?„ÿÎí°ööLşÜõÖaÙÉ¢ÙÏcşvY°¹Åüî<únıúE}½Oc0rä5'˜í¡{‹h<< ãüŸ6ğ.-Îñ3íKß°æ—ÛWa &=%[tZ-c‘Ü–¯“\VÔN½ò•ë€ÎípìÊ‘s÷ÊÜµdqÎ¨ÿŠ¡]Q9ÑH'™ìwoÌÅôˆ¢ÕŸ+Dƒ6¹›do¸¯ë‘ûV	ÖFeìPKÉ”’øÌq	Ç?Şåzƒ{F¸p…8	`Q–7Á7Œ± 0˜¨Bì5a3Í²œY»BVmõ¨üÓæ4:‘Ã¨£YH4‰o›¬y-Xr2òN)íè×´¢—f(¦ĞnÙ}^x·«Ä?ŠãÜ/¢ğ¿>Ñ×¶Şb@Gr™s ×Š;Åj~âÜT«ıYC%RúàV­ÏÉ‚yn1D-úl‹)í¦¥,w¶wOºı„ŒµÑ¯!"ïÄß¸]ÏŒP%Ü´«°nqwr”Bü˜‘	íÕˆt˜AàÅ›/Šhƒ‰1­5vÿ	™¤²qqèJ8ŸëüÃ Z¾
+Zƒı	÷;OíB¤éÓÏô%•¿‰mƒ+Â¾ä®T	çÇÖLá¥o§LpkBwü‰ÿ'Ê#²>Ó–Œ*R—º7¤©º(e,‡ğğeí;>°Ş·í·ÒŸö÷kD8p
Jeœıì©_ç“]¥Àü–Üâ;úù	Ëçã`cõ—&Hx _œB¼$!öyq[ÈJ ÁÖßÿEÙTÇµÏxíBFbê–£ÄşÇ1	İ&”¿8ùå–/—U:¦şÀ¼!Wqjî¹»_‚4¨…÷vÔ2ü®Ó¨A›\,›˜Üİ»XÌÁiz+44=ªÅõéÆY0˜DŞ)®m˜USù7‹$dQêÔ¹ªe+RAÓÄM«ÍU¯ÙØû™-–ÏœçèF“ª½Ÿï¶áŒvFkÅí”½ÔT}X¦ı‰±E_(¼bSMÉIVä¥£bBÂÒQ]u§lÇ‚LT¨cT‘OÈÈÕ­0¥ˆG¨Ây^Şpä×›©:¾ÊU¿¾Ù•a:/ÔğìY—>#&«_¡¼~QŞ`3VváH÷ë ‡X¼ğ,|†¸öca?••âŒ›®'¸á0ËTö½ÈŞüÀåCK§mî¬:TÁÉ}ÓˆÇÏ­ŞvKöğüèGuJ‡M~GkcÎCôµ“‹½MB˜+Uê3@ÊÒ]ôb—ìÉÃ;;2ò.#ö ËMâî:İyÒt—¶­¼¿V¿ãŸ%÷¤?Y‚BÜØíÌZM[µLp1t²Æ•ğúÎª¢¿ˆ j×{zˆPàõØU+\é—¼XíXÙKç ¤ÀÃ&ø¥z´uÑÎFz­bpØ™Î‡™İÏŠ7ÂR¶
’*D‰ƒróš¨¸Ùämy,'9Kk"}½ƒFÛúPŞª< *êíUäy{ËlMÄk›"ÉrU¾ÎÂøã¢ªp¾eÔT–°‘n-ƒVT"<dc]éé“krúOT*3X†ãÍÂuğnÜ¾¾‹–4ÈMŒÇ[ÛŒ\-‰Rº¦Ö&©÷·(¾ëQnØ¹QbŒl‰·ÕŒ’÷>ÛQı•µöíñ™/3/pIZ÷$çÊW^Èî?p}~¤˜¯šß–Ÿ¥ãšÈn%Ó·`üc—è1µ†ĞPèô§ÑŠSo ~PÑ
ÊŠòµ>ˆtüÆfÎÜ±5dñ7±˜rj‹&iw1•¥Ö'À¨lÿ¬eÄs6"?ùp;\çuŒBMO§9«TJ¨:èHÌ*¡Ö
¬úİ&ì;ò-\Dx:B#ù´uNGaN]ÿ5Sª4V˜<Wò[¦ÊyK¡L¦%÷¯}h<¨bü`öï•Ó%¬tè JD›¥dOlŒÍc]Öø?2rÙ¸¥;•´ş$	Ä%ÒŒ¶I{ãùŸY€\6K±º·…* ì<ÅÕ æÅ¢¾×d°õs}×Iy8Ù† )ü†Bÿï(¬í®}¦NìVšÎSa‡n»iãä«%˜¤(òdSÂ‘1 r$_¿1İº¶srŸbJê|,"Ò«OÔ{%–ıf[Ò§ıÓ#ë,©ÀËJ‚·s¨0åçYB~&JêÉ;3>‡[¬Ã)]“Šf90d	DT-T ŞŠ¸øükxd»21¾Ã‚\>¥jB:ıõTqişƒFäİ6—Ê8Í”wQ§½JÂUUoÌYñvFÜ üÀn˜°€—¡oo²J'\(VÉ:|L†‹-ìò½?&IÏEA‚ØÇ UJÀ‹ŒqZrÃòµï@m¯¥ë}9ê,·]íOâ6!Ù8¤Ê’ò
@¼XóÕãßç>m”Äÿ™Mü}®^ƒmP?]ŸŒ”Èm-}q•‹BáV–ÏE¤Ãw°ì…APt[şMCÈ…4‘ìbtĞ„øÎÁ¯ÜáHù7Wø&'E¬ØÍU®…ÑU±èuS^îŸl}öğ˜/³\# ¥ã¾)–l$ûÇÎ|‹lıZ£šê 
íPº;ÖİŸcB™hwêAÑ_¶ltß®fƒ~ò
zCÉt­ÇàÆ@cîFênÅ(cY°±ÅÊ9W»¤S‰¹ğSÅ™@µJ¯¼c_(L9ïëøZ¥OmŒëıxŒíC¸ÇA5ıMŠÖ,Ú,Û…xNX6É;–d:~ê÷V¯	‡¬î0 é›Ók:¥Ó)HPÉÀ›ÜEYÁF0×x’¢h)LU¯våîı²ã
?—úõáîªŒ'É6;3¨¹IÑ¦,î¨ğõw™Íg[ÙËÏ,³ô  çI[À–/ œ¶€ÀYÁa:±Ägû    YZ