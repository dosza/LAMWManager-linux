#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="4281140487"
MD5="a68eca65bdda7135ae40d9122f9eb881"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21275"
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
	echo Date of packaging: Tue Nov 26 22:40:35 -03 2019
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
‹ Ôİ]ì<ívÛ6²ù+>J©'qZŠògZ»ì^E–5¶¥+ÉIºI%B2cŠä¤l×ë}—=÷Ç>À>B^ìÎ ü )ÊvÒ&»w¯õÃÁ`0˜o€®ë¾ø§ŸgÛÛø½şl»!'ŸGë›Û;Ï6·7›ëíGdûÑWøD,4BY¦ë^İwWÿÿÑO]wÌùÅhnºæŒÿ’ıßÚÜÚ.ìÿÆÎúæ#ÒxØÿ/ş©~£mW›ìL©j_úSUª§®½ ³-Ó¢dJ-˜ŸÇfè‘ÃÀcÌ#OšÎÜÄ¬)Õ–Œî’ÁÄ¦î„’–7÷#èRª¯‘çî’F}³¾©T÷aÄ.YoèëÛúFcıGh¡lØ~ˆPÃ3JTYÚUb3â›AH¼)	¡wâ5_Ãô¨N†g &Ğà “\¦ïÓ€L½€¨8†ëf» JN©_…“
½ô= }¿ıüôĞh$ÍşáÀPkOÕ¤3:>ì:'ƒaóèÈX"YĞ\ouûmCMÛOíQïeûM»•ÍÕ>¶û£awÔ~ÓfÍ-˜eô¼9xa¨(W)
„ÃÓ +ÕC
ÔÛ„^pUä;ls@{JŞö­Ö{½¯×ŠkQÉû=Ü9W©”“Ã`~‡ÑµÆªëÜó·9;ùô†(S[YÍâZnp	á
©a. ò­™xó¹çjìŒò­QPŒÂ7Ìİ	l‹2š†tîØeOÖ®‰RIx¥‡s_ÏC×';^!«H0_²«º	[gtrN cö½/ÄE–Gæt>†ÍQ8À)£A‡ (P*3$:'ú,ğ"Ÿü•Ìê‹añoíg¢[t¡»‘ãÄT×şD¾1H#ÙMXLeYìÖ•Š Ï}à˜3Æ§uéE/H@§£)4ó×U …Ÿ¶kµØáÉ™2„º¡&´¨µD-§¨œ tšõ¬ë\í¿t=E«ß*€ÏÅ$ô,xÈˆ;€³á7X=¡¼éÊ2¾ó‚¨ù4E™Ñğ9¨SëxŸ/[)à²iBeYkéo¢]ªélıÈÍëÅ·ë‰E§fä„k
€4³æšM$|j‰RÖ¦J%ë|íO+gíyÚğÒÅŒğ|n‡|Nÿœ^Ò	¡î‚ìw½£æ¯F-şAŞ4O‡/ºıÎÚ²ßäóé\%µœe+²—“PÆ€*pD°»„^Ú!©×ëê^@M+åğëÄUDî‚×+æ+¥u„‹ä
%U*™$$b©IX‰›bÙÜVÒmå1±sÓvSJ|âduêyßóÂ‚ûT*™&Æ«Æï“¨SeÎCäù­òÇ&³3
RN¸"+ÙÂ8ù°¾5icÉ£‡Ïêø¼ph»32€88¤V=¼¿@ü¿³µµ2ÿÛØxVˆÿ7Ÿm?{ˆÿ¿Æç…w6)b4g“v•Ê:éúàùx€6ãš¬üŠRz$ùĞï¹aÃØÅt-_É§–b@ä[£üëã¼úA1¿šş×QÂÑäşùÿúÆÆVAÿ·Ïôÿ?3ÿ¯VÉğEg@:Gmßµu›ÃFl¿’V÷ä sxÚoï“ñU>J‚‘^Dææ·1x/
!Ì±y\}OÆğlºIBì¹gÙSrf7¦ÄñXXÏ—–ó{ß˜ˆêd¥Aùõ r•ª<$ğ‰¦‰Ñuì¹a!£€ÉäÎunSF)1ƒY„Ä32¼9P tM'FÆ :¦Ó]r†>ÛÕõdXİöô¯STP²úœÕ¼ÓŞiÏ±rdù¥oºŒG´gfÂÆ«(S;`°9“IÄ3
œ©“wÁaØ¼7}^gÑ”¼Õ»«ü5í?/9ü›Õÿ××·êÿ_sÿ'XxÕÆ‘íX4¨³³¯ÿÃfo-ùÿÿÿPÿÿÌúÿº¾±¹ªş_ô{ä‚„‰ç†&¤>„#ƒhÄ·È¿2£.xØAQlü"4ûÇ‹gD'Íf¿õbgK#M×
<ÛúJ]©Z4¤“Ğ„wàãÿxÄòÈÔŸÄiœi™ÄõH¯E°ŞhbYnññïm.lÊ‹•æ|lcÁKáÒA¯…uçŠRq¼	î¡ÍÂÑ8`Ô¤•`›±ˆÖ]®ay˜a!?…ÖóÂêSõt¹aDÖ¨«O0­`bùsäÒ‹QÄFNÈxÙuo;²İè’CEÖ¼ÿHÊÌ‰’’³‘±YoÔy<§ı£,ÔP“ˆŒ-Üú4 ÙAãÔ½`†M:pQÍÓêP@<Ú5FUÂXFGç£^søÂPõˆºcq ‡ªJ`­ƒÃy '­>™ÎŠ(ûí£vsĞ6Ô['~Õî:İ#^â½ÈÒkÒH5ã:¢Øú¹´u¯%mİº$èÅîô$YÆå;#Ğ4E›¹ÑÒºÒ•‹HAiæÊ‹ša¥ÇSˆ?®ç¦@¨üà¢KÉëØ÷ÄöÌ?ş4
3€‹.xÊhN€àsÂìùøã?{âñ¹+On´ 7Œ÷LmşE—hìöÅ/şt9HjÈ%ü^Å^±€Ï˜*^ÿ+é®„éø%ªKûMÌÎÅ™=9CnÏÏAU4ÛZ\)Wk¹A*1ˆª.Ÿ”c.rT[5Õıæºß2®_é•*ÏxÓóîÉ¸¨B¾K+$„üô\Y†Ã$<B'‹Óû§'/IjÈ‡8
‹ı9Ör YÑ6êm®AMÁFËpµë¥¶oßiOor¨ã£˜ìÏ^|dºuÔ99}3zÑ=nsÁ`g&D§°<€tH˜¯N†ÍÃnKf¼©Ë{U}¬Ï~SKV—
béô©\^//ô¦mÄr]ŠB- ¢*zJX·Ô”'9sµå ¡±‡ˆ‡ôp/¨¬Ğ\¬@^¼X˜ Å„‡+ÊsljaœÓæâ”÷Ìtg4;·_Z¨Ø-R)Yw¥‚µ2ŞW<à4XNæ?’Ú2iõNGÃfÿ°=4L°€İŞĞP5q‰í#•ti¿ˆ¨H«ß`Ë¨WÏšDkM_ô^mª$¾^¿}ĞycàÎTª|¹1¸R(ã¸%U‘Jv'AÇîi¿Õ•4¼ÈCôZQ°ÑøIB>üfû	KÔ^OÈJº÷¾?¹Üá>²ì<Ûq¸x‚L{Ñ½90iì’@Ë¤ı×dõ©]ŸtûÇÍ£•«eCÀ[¥’%–¾š›ÖJµ_ÅĞ¦öÛåbºª’¬/cÿ2|f_yY—3«Õé€V°A„ë QIÀ.ëB3˜œíl•êÃ}YÉvK»}=0ùü%’Ÿ×KÒ^Fİmµò~Æ=ä©hR’ŒG9š	–’‰nÊÌøÒ6áS¹Tı´íC’ïØ:\DädÏÍ‹­{ÑßFøÃ6‘;†dQAVnafÓØâ¹ç…ƒ00}®lÉ:@†ìY ¤··¤6éªËÁQóptĞE£Ù<Ùïw;û£X
wdœÂˆ'!kn¶Dõ%jPÃg—P“¸Şş9ää<</™’Ò—ó¶$¦°*_Iˆ•ØÕË²q¥2 (&=srnÎ¨ğ¸ûíƒæéÑ¾Qj[/“„İv-zÉ/½$a ©]#Ààm÷½¿ùäµæÊ„ÃUöûú/¿fÄÄM¦QËWö‡•o¯ÿní,×ÿ··Ÿ=Üÿş\ÿcéW3¹ùÖIz\‹ÏK$şõà>e¾ç2{ìP^Ûåñ 7w±Q‰×‰ËJx]­^ÿ:Ü.)00üvhã™sD“Pªq%Ëäw-é‚:ÏÚ¿QpH¿Û°?s‚ß` ^K\Â`ÿ¥\ÌÏ3Ñü ÷	|t:œßÏÄK"j©'ñPæU¦•€i ƒ·&WAéõ=†»lã=Êé,£	á”Ü>?®$QÉÏ|÷|İ!uM›æşóĞ;µè‚s“?°İpJNŸ~ÛÇ†¡Fl¬~OšÃaÿÚ¶^Q×ò‚hşéUûd¿Ûÿú»ûmCmìììÀÃa¿{Ú3Tß‰f€W}ç>&ä¯²Q*ŠñŞq"?Kß^×bJë¼	i`4Xà5\$/c†@ñ¤U¹†P,mšÁ_"{á¡§bşñrİó1ÉRPr[TR•ÅO®ŒÈo¾úF4‹€•£¾«–š—Gˆª\N*B—Ä"‰ØCÀÊg@¶¨§«‡lı4Íx‚4©ÕÎ¬Ä¡Êm @H-šÒ%yŒóñôÆJ~@ì7ë‘ñnRslkq÷SK•Vw­sİwÌÌÕœé1´VL¯ã6i€1aO‚æ~[Ny¼!nÜ/à=Ï\ò½œ¨­úºP4B¡.ºE•!.‹U*µƒ(¿5ğg!Œ¼	b¼ÄrFÃÇŸ<Búc‚Ğy,v	”®s ~¯)JV/ˆ"‰m!©‚fáq0"É‰°•
ãºqd»Ôvñ"s&g’½m¼ç‰V"^xÊw£Î¤g 5¹³¾õìˆ‚LLp±BsAqaÃğÜ5~03=¶ÄÁC’×Bâ7®¦$ô©D•¨S	I‹õqµºiY `=Ğ9z½ÀCçÇMˆX€/ZâcÃ¢åÆ $˜(òb“¨ÅÌhñ€T‰>ãqRåµ]ü»[;ì7÷Ú9ˆÜcàWÇ›BLò—ˆ>wL÷w"yg@"%@½ÿA<àE$` ,ï¶Z“Y JÏéRâwY
Kç»-íu®W¼ºBŠy~ò¶Jì‘N£&?û™•ûG#qÓYË‘Ü£lwdBĞ h©Ayü™‹û}+näKäŒ\FS)laB^]hƒå˜	ºæ@ØjâË@#è!]î8ÅsìI¡˜0ŠqÿŸ¹‹À€|ƒ3zÅÅ(Õn–æƒ™ôG,2Û# ªàšŞÄ‹HşR#y2|+3kŠ¨dv/\4'ôÄÑ¨ç:Wñõm1$ÒW-T beÅ wsáÆOT§F¢<…ìB#"¬©ÄcÇü-vsÏ‚°äÂşÍbo'VÛÙnöOø’Çó£¶0ÆI!e%éT1Îœ5“¦)Õı²ŞTÏË:ãµ¬èåDŠÊ°z'
ƒ!<çåğ5ôÇhq…nB^‚'$"ITw7ğ½$€‚<åÉÛhìÙ?Õ®«sŞ>}³g÷İ0ıÄ¡Aè%ƒÙïoä ‹7JB¸›ı$Zyl\q±§XÖºìoäÎ¸D¦ï(¼1y³h”\ú›ØYräöÉ¥ª%D¹ƒ7%¶bR®2@iÈ©‡â’ĞËôt!=È+kå§'jÇz»¸§ª(×b´[,İ¦ıäÂÎ™oNhÌÜ×İşË„Ãí.®Çp´²¹bÖ¹˜1é?É÷ƒ9{ç‚—whÎrqœİ£ı‘”µµBƒ˜ød˜­Xzà1Æ´?ÿÌA0ôv»Gƒj©‰ìKg¤Òï”/ƒÔ¤My(l„´1²ÑÈ!ŠÅd48íõºı¡q‹(©b'¹ljhwkOğk:0"|"¤!S±0Ÿ{÷ÄJ_¬‹%LMï*œt‡ƒ_G7Å‚o
WŠ>BÄŞ¹·È—èÌ„‹ì’2ñzç®–­¬ïrsvwïæEjÃãŒø÷,'g/ÅUóè_±¸w.ùl6 :&Ù²0›œS7"5csèñwò¡­Xr¹Å•è¦ï;é{iXğ|AA®÷ûC9ˆRÎhğ=¾ìB”Y¾”sß‰…Sº'Ås{Nu_ÔXiİåŞ£Å¼9»mQvz>°3şv_4“6¾<ò^ä.ê‰9§F¶%jjêíI±‹ğÕö%äŞ@Eî¦i Ás3¸ÒDF¥ñÄ¤ÜÇóÉ3TY”Ãk0¸Œ-'%¨3A—•‡ƒ‰`õº]ŒGQAÄF^€]ù¸!æ¶k:ÆÔMW>5šÙ¾Ålh¤Ìxì`HuÀ=˜moBÎ!ä‡Ã—{‡§àµ=.î	»kŠü×Ç-Çd¬ÈîcØNNVH/CıRw÷øS¼0`¬÷dXÿD¡¼Ïv±Ò!ÈÊ`s¾% ¥ˆ„H•6byã<ß3ñ,
“:æ•XåKz¶Æb†¨-ïõÄ:C¥ñ#8¬=Á½<“ŞB¶ìC¦yµ»ûF{¹ßÖN`)Ú¾)ïæ}¶ÿ=1äã¯L'¢F˜Æßhân­†oùµÚ¾‡¯I‰NœãÛJc¶ÚmÛ'§£Î°}œ$ü¥:…yî„ìä»KR6ºıÒ˜}âÑ~{ğrØíñótÒáMlSTï:Mß‹:£_Ÿ¹Şœò»¥¦r­³+Ò¹Æ´Yd[µgì¡…À*Ø¥ä¹A_?çNMJ[¦NÂf§›‹ê—sç“,Qœ-ñÙá—‰åGBî"³9ı	ö7™¼ãŞ†×/!g©;èœtx¢”Æ~ßHT€Q–5yˆ>À¢%J¦´=…âÄ^ŠÒ=Çåİ­¡Şí’Õ%Q4”©?ËŸ
ÁäÚ>¢Z&Gö2‹R€²€¨Ü«åa–ILX	²„aÌ…™D®Ìx’]‹ı°˜ëØ©Õ®»½öÉ/ıÆÅó„ûÁ:×Ì¹1)ù´Aöæ;êZn~î T5iÍ¹‰b´·ÿ9`z@'tL‰‡`¦{Æş
–$ãM7(yrVE*Yûuòó[~=ÌIšJl,bíÁ×O8°òS²¶FªäÈüøO”8À@òÿ§lî\[»ÎS_È`³U— "À´ä|ON\ñ– „ÎÉÇ¢L"xÁ÷OÑ¤ä„^ô„³ÆË¤Cïuª1+3>øŒÿÿÂ=fÆE”¤ä?Š„&¡û.-Ü¿`Ş—rHêŒcãìÏ…ÆË0ƒ<+À„ÏÁÕ!ºDˆm,å¥=q~`u¿ùA„àÚš`Şvx…a‰È#Ç‰ÙÌC¸4w„%ĞĞØˆé0>¤â€àYê¸…r’İ‹PŒF2‚_Ù9ß>uÍ’|ÕØ–V3@V'îıwîwÕ‰‚E—\œ?şäêG2T]*cŠÏP?Sá},İÀãuÅ•ãZ¡3¥O.~gèLŞá»Ê+³î´uĞC°–9•TË£Ÿ•q8QKX£J>‡Ü wI88­‘X5îxÔä:ù2a’y/„Ü½”•È²;²Je9)Å¨‚«ıº¼ÿ!jsjŸ-ıS-”Ïõ‚&Üú›^ÿßö¾­»m#[s^‰_QÙ‘ä1I‘’/-™î–-ÚQ¢Û"¥$İVDB2b’à@ÉŠãù/ótÖ<ÌK÷š‡3É›½w]PHJ‘İ9gÈµl‘@]wİvíË·ãé¹TÂ¡¾ê')NØVe5ñ‚!«6ìé×ÿ”eªQˆ’màq~û¿ÃæúÕ¼ótµµÒ˜Ñ¤Tò¥¹ƒãJ&ÔáeKúí±+ïçÀ#=rJµRñÎV
zTöAxlª
ñBà¿FZ«”Mz
pIé‰Ì®ƒä*»©Q7rÅUz[}=†E×9úeBïIê…½1ÖpCG“…ò_‰d«ÕËax{ZÌÔào¯hÌigŸ•©"`ß+_uO¶¨®à¶ƒioWWápáŒ…[Ï3ÕnaŸl9SªìÌÊjëFµ:£óA•9i®›«Š\0IÅÚ(£»¥şÎ)©n¬ÔÏŞbÕg?Ö+¹DórbC¬9•åü+Ôn	£ÕWÜun(›1P•‡
iDéêsN(gTMÔÑˆˆB[x0z5²7ĞT-"İŒdÆÚF­!Î	8À5=ˆÖšT²ÍR6’ó‘z2‹”^Õè"ŸÈàÓÂ´æá¦‹#9ıÙ¤ßKFI$Ò5ÃóŸ`¯†Ó¢?ğ/ÃÿG,Á|ø”ÄßWq?¬%ƒş}\\¤¿¦ñ¯—Í`ÜÇ¯°s£VĞärÒğÓ5os}?ÿÿ§È¿QŠÓ‡h’ùY‹âŸø#´ßĞ¥Mûš¦QÅÁÒŠí«J2yÕ“÷¼„¨/ZÆ\N†°`.k“„ÿ@Sñ#òÎ{WıØ£ï¾ìö;ì£ü;Á²èÚ?NxŠÃ±HA8,ïı¡öUT:zï=Ùˆ2ğåkü+üõú
*
e5aÎŠo?BßäËi¢¾ˆâ'Cè	ì\×Mü6øú;LGâÍşaXğ.ë¼û“$œˆ?²Ø¯]ŒF4)p¦D1®î«ô›HšL4ŠIñh§©…äÅù¤}YRÂ_ûçÁ`HD$7Fcás<·ôR·åf7‰I³Â(F]ú¼”¿"§Yz°ÍèL¥ÅÈ…ÄÀ¾”'µÏàŒÜşmÖq÷/¶!ÈæÕM$(ë¼œ+õ9†gònpfš#à]T:+ŸÕ	DTÂîÔïTß%]Éª›µÆÔø…»#ñŸ­õ¢üÒm*Xxfª[Ì*äSÖ¤W O…Ãä&P©“^3XzB§2º‚syˆÈp ø‰?Ğgu=.HÛ>!n^ åp`¦„ÓŞ×wıq –çW §Í>·Û fk×RÅ¿‹Û(®2G•*Û›®'g Rl$’1n±Ëïé…˜mX¬’¬äÅğõ´)5!ˆÖÊ]DŸÛóÄDû&ó‘İkY%Mİ!)š)d(–çøòó¼Ğ Æ­|´¤ÆÇ` yò[4½XpÑ¨N’¸å÷è¦·>8±fTÙtîR\äNÇ:"§P+ÃÅ_X 1ëÿjU…f"I Ø\5îˆĞĞ„ˆ;ü¼èŠçûøXÓ;Àûao­Y×
ó¼˜¸,µçÎŸñÁ×*)ò}<#Ğ
í£{a\Š›!¥Óä|:pk3,?P#³˜‚Ç³·…Ó‹éW~‘²9¿·"´Á·=€}Æ:Øqænn¼¥¼¼ÈÂtæËüÁµ@Êáï<¯<Hï8€£`?Ùô‡f1·A,£°„¹,ƒ9”sÉÜ¶ŸâĞ°Í óHá	ŠÓO$É½È%¦vP±³Š)ñC‚¡ÑÑ¯3¹óuÛ''{‡oºÅ)'çb}¿ ¼x2şÄ3\z,»qŞ™ÇÑ­H	*§5øãÄ–İ)åS­Ò9[É¾`¿0äîİ¸~V¯ä¡bêõK¼ÿ–‡q>ë¶½DrÜß†öŞÊíÈîudq:Êû™.G†Ç‘t8šíot?îFYo#ø=÷}:ŸêîÊ<ß »åä>BwÌ+|…œÏä¥Ü2¨Ù¤ê#e»‚ıÎ‘‚¶Ì«Y¶¶g~§ÿóM ÇğK¿®é&)·v»›§˜ÅEìŞ=Äw£µ¡™I†^çæ…¦]ÌjÎÛËÓOšhg˜GëÌ"Áíb9K¹SÃÁ¢u¿t÷~Ì¬üŞÌ)İlûÇüIùI—Ø0‹ç®Ù1+Ì‰S|û³¿ºµUÄÜé¨@cø};¡$ÏX~†ˆä€ápÄ½,Gr’Úz"Ì±*x9šæT^\Åe¬6ÆZ9 Ç7[“pµ~pŸï]ãõcò²«Dk~×š‚W*›>{2Ï‰Du£ZŸ]&¤ŠÜßÅçÎßÒ‚åÑµUIßb5eŠj5(åæŠV/à¯V®­d^P#W @Q1+ÆŞ^ €)'¦¸H¸$èYLÇÃ|¾”~+ú¸–VøC&û–Şb(Ñ ä9J÷£JH×Œ@´OHäİ5ù»d£¦P	È–NşÚŞ–QI|ß™Wš ´½4ú†ø ¢#cŸ¾TdLëË_ü´bµ*X…â3V™nò\œ7´1‚IxÍåq9[Yi­ï¯¶}åù_ĞâXú¨¹Úº7€~8€M¦å¼®>sÿò‚zùœ/Dş£ô¼=¾
¢pŒ&øG~Ó8ŸïóÚR¼:n1~æÖß…#¿N07uaœ&Å¿úWHøÂe	"‘oì|UVÑ•f~^·´‘^=¯‹¾è–nY‰­Ñjâå§‡¼`.z^À¸x1ÛbsÒÀàÛZG–ò¹u³ª0mâÉŠpÕÊªô,ì¢º.†sB;ŸqÛ'(İ5ü…Mg}v&vğ¬²
ãò­¹¥5Få”ÊÙf
®¬ò5ó`\Òêp™*`£¸€‚Cƒš°yÛXğc],¬ü˜û#sŠ1Öñ”a#W
'ı¶“´‹g|®¯hpœ4N©)ëÅkè£69‡Å³`âMJŒFö©i¶ ˆÒ%÷—ü`Û bNşx~+8‚èï&9MÒÏEùæ€òŸ…òÈÊÖ¬!g¿dü¿ÆFs³‘ÿÑX_ÆÿXâ¿ÍÃ»JñßÖkÿÍ‚şf„ùs$‹íö€íñ0`cæÁ¹àÒy°Ú(ÔÜù†>á¥Â{ğåƒrYZA¢š/ƒñæ”ßì½ÜÙgßítöĞ©½Ë«}Ã]>e”êïÚİv«²ræ¿mlo4G+*døÁN§½Ä_­Ã»ô]÷ô%Ä_ïìâëMõø°ı¦³w"²4ÒäHVUcy×3Ê¤d›FÂ¿Ÿî«6ÓçiV4ïŸôö^}ÛEÖÉ­_yÜrc0y‰Gª×Ò§Şå‹q›¯ú^ÿO/ñ
S3ÎgUV/"tü\gÍ‰ßwÉĞÀb¡zŞ0€;SìĞ_Æ£R·V~<«ÂÍ©ÜĞ¼óØ˜œ9e´ÌG"À690öQ}OnwVØï?Bµó€ˆ0Ó#ÄdNy:õ§¨&¦)»aÓ oã1³Ud.İ€c¥qæ²AèÇš?ø—}õ¼™àv(¿4å”«$9xx1yÄĞ*”=DÜAëºÒÀn“(İdàA“Ó»³Òj¢²XŞè)™Fc8×…£úE8X±ÃGôÓÉµÉC‘»6
·VÛ+š™$s+ÍüR8<Úf§(4+Í	+kFÂPÄåEV‹uÁí9ä]}%y-Å§ŸWxî#ÁË^t3NJ «üM”¤H„>PıÍÊ4·LZÂ»ikµ²ÚEîùç
PEÅ1\ƒ¹.^qIt‚ÙB…Ò7x‚¼GkuÍ6¿ú*CD˜ŠÊâsOµ–"¶«hAò©Óë’ZUZù_ëõ³z}ZÓ¡îE
¼íãElJ<rM©ÌùC¡ĞÃnó­Wıy§ú÷õêŸ·\3‘´€şÓÂ8\ú˜7œÀœ€f¶UidëŠÛGHƒ²é„Ks7áI[deÓ=Şß;9iïöv:¿a©bd(T:8ÙÍA×vCÉR±-¦3UÒ=IëhUr€‡>6‡›Ãs¹éÜdÂ¦I¸r@¼(ònp’Ê™È{saB-TJŞù9ÒhSI¿ón¤%é’#§¥NUåÌÂ¢–âdÁ½ÃxøÇ¨T§ŒIé+Š¡I'^Œ›şùzºû9J¥EÉ0Ğ–ƒ®M)æÖF:zÂí	ëjUÛê·ZÁ°¢Ò§ü`Âußªl¨§¢g@S±hÁ>\2©åbÅÔKQ	±Œ%ğ%°m¤ùÎÃ'…È#¤'‘{½zãõÑüÈ¤k8<@vG¿©ØÄ( “~’1=â&GçÔë{#Ø!á8A7/ñ›Æğñ‡“€û•T'i°ğ86MfJT#·9A~^ßêLÉ,£[—ˆùÊËXÃ?ÊùÓ¹+¶,€äµ/P4)Z`Ænš•)—Ë´œÒê°?JçÏÆwê¾-Û|”¹Ò§Y`\î¨pj¥‹ºCÕŞ‡¦ÍâŒd6QÂ¬k·›–©:ö÷Œ²gbŠéçœä…n7×äV›eEe"Gjh•uuô}Q@kãİhpËùö»‰`…)½ÕAgÓ2Ş·ôşåmK-ºs­F«øˆÕ	ÃD‡İÅ@l¡7
Öˆ[Bcs{n"Œ&>œ(¬J¡!oâílšxPßÄ†­SÃ2‘UÄÍê1>¹_ÿ€B«DÓ19øbdsôW0ä—~|6nÃuÖw­VÃ)ôâ«&ÿ§;íB!ï)˜	Üq2ğ±N3:îà—~¢­F.M9Lç¹?ˆ‰uá±Ë³¡^¸*ã’Jsö>«Vaà|<ß7Ö+ß²ŠJ:E¡ªlI#ØˆvN0ÒšÆı„ jÈş< æéæ;‰n¢dD\Ë½•¶óï´y71Š4è ¬q‚01‚°ÃíÜCÄÖ	Ğy…}?Ãø£­æ(‚¸ÅŞ¥?¢é3ë·ÿ‰kô<@+Œ9AXF˜x¸K½œÆ7™}j=7iÒÃ±m˜œãMT×N‰»ãƒ·ë?Ê÷£˜®Â×ïpê\ "0æ”60ócÍç_5XÙÿÛ…t¡Iç!J:!ªÔ°gÊ"{1û°}ï	ÅO¨4¸‡B©„­jl›P¡ˆ¢{2L­>>¯'#pİQ8b,BØı4Tc"&çjõ&'¼¯«Ó±7Å%èŠàÖ²‰{°t Cõ"øPËéRÙpŒSZ=œø@¤ÈÕ@ÅÙ…£*¶½òQI´pœ<¬âbà.éoéäQyˆ#&Ë³ˆíõ/|s]×WôÜÜÚOì9/°de÷ïgá©&‘HúF%ä>-ƒ}‘ø?bNÜì÷âÿ<~ÚÌÆÿÙxÜx²Ôÿ,ã¿ß9şûc[üWŸåúy%c½¡ÜEA*àÏ@–£™Ÿ|¡ÈîåIä£2œèæì8Ÿ@²¹uÜ:ÆÍ!2h~ÁÀï¡™PËiœú­¦ùH/õ-9¸UŠë8ÆÍ#W—©«Èø9â°£á€	³&&Ùò¬±•U.$TLæö&¡¡Ñ‡”ÃC[ä:A¸fè‘ë\å£¥8*—ílZ©&Ğú 'á=ĞE¥<	Ùİ9´;q¹]A>D41ËRtK«ÊùÛêõQû-¹¹R² a¹B,(b"(°f1-ÿ^yğKS‡ÿ›Èl¨Á¼„-C¥P¥+©l*Ï!i=´ÅÄ5UBŠâásPèjúêjHiîÙ]$?# -YÇ&²É$2ç›½êÃ“¹õbšÙ•Šy™°‚Àv/™ÆœÃ&ïátc»íxë¦Ê©ş?9í’fNÉ“IÃÒYhüFúêğ¨÷æt¯xñFŠ¯·åMÓ†¥YòÀWUÈSæH–xyô¢‘÷³?Æ«‰ù~û÷ßş¬Ò8<P<‚rÄaêVÇ/C6	O*â¡HZ­UVYE­6«Â5 ±ÆÖôİ^(SxÌ­¿Ê; NqâÔb$ÊÜ*Ğ­Š U3ªÒ§/údéSU[0‘\
ŒÄf-SPE“	&%2àÒ7ù[JãJF´ Y˜+–"®e^ñ¨4µ ©¢¥Ä8Æ¯Şùı÷mËA}p4Ñ8“â¾©ß«9]bÆÍ¿wöOÚÃ“½ïÚ*.šÚmøÄß’d^a9x=‹±›fD¸Ö*¬Ò˜ûZ÷Öí;†fhÓ	–¬s–: 5ÅK[ÉËQLr4Â‹qü.¼¦‰%©¡¿Úzmİ$›CÃv{·wzŒ»[O¦V#|`»şyàAß×ëGüÍî·Lt–ñŞ‹§ÏtÌh5“p»Ïªğ:œtŞn¥oWìã™wI9â÷^Çøå–ºY6÷™´nŠyıÁ#6é°ç)*j3$P;›	ÜªÈû']I#îzÊMNNrWCC¥×ĞÚ&Õ&~ä3äåŞÎaï%L Óë¢I©[(Ì˜Y[+¨¬Ã~Š}à]æÚj“ÊÚA[:!OªÅ«Ñçğèùxzf1MøçµM@Ä5ïñ¯½¾CÕ(Ôğ.-«÷Pˆ¾ù"Z¯9ö|‡ˆ¾§cõœûkc\'†óòL›±7ğ‹½€(bÕoÿî…rl2SW¶69ô*v›û¢zwJ`ô½agáhÅ)"àŒªÕÉ4ºôÕòøsõ!*l~ÂFã!>bAÇ~òM§ıŒ‘œıÂ›)yñ.ò…(!ÕyÉ»ª½ùö¿¯o‘¿¦¤dÆ”bróËJŠŠg¥*P¹%D¶ P»à€KST8W%Ìj®´§!s*u…QŒâÖ®Ğ|2ØÔ²Ü¨upµ*&?w“p2ÁmFmq=…°wJ»i…ßt¾Ùùn‡ût¹•4™ª] @f(€·‹aìQ¨MM¬¨R4›ªmkÖLj”LYr,;âÇ®ºC3Ä™˜S<–U2š´Vêğ?.k¼—ÑaÖMñ—é^½¿óıÁ¦à)³—êo0CÄš™ìPåC¦¦<g²t‘ifMğjHNdï™Ä€)R8"ácæçñ¿ûC[’Ì= yvş5:“·-”¤¤mâ'EšJŞ?ÄU7#4¯ò,Á¹a'QTËÖ.~ù ß?¾ƒL²z%ØÖj¶öXy»ß©9Ø~Í0Zj'Í2/™m4{:;èœ­i–;E“Í‡bË²ñ;mkuTö÷^våıˆP{ßpÿã”²Ä$À· .°XªANÂAˆ¨ÿ#?‰Â˜¼êùOà3
´C}m˜½U1øG uM]¾ØN»ísMém©A*sã õ&ÅJFƒªl–ÓÎ~K7·*<†¯ÜE3ÅÍÒø*µ%²ƒª…™ÑGÄ†ı½WíÃn»Ôëì´ñÆ+Xµ:úş8¦]sö(
¡¬ZøKşèå¤Õ«64]æ°ÖƒÃ7íNïÕÁ®Vñ[XñmÂeúcË-hŒû»‹-êË}•lÉvfİsj•G Vı^á6­ÕøİFKÅåv+©/›˜‡ø”Ï÷VŠ¢m¾-ï9kùÆOt!Ê`”_t¹=1”4%/.(Â–Ñåû¸ÿ DšÙ£İªàşP&ìWÜV:íıöN·]¯<=C0¹k¯ÑÖÔ^A±ùAA9÷d–`P;ÅYJ)jut´´ Ùİ4M€ª*AeÖ™ÒÍÒÏ5KtgÑqf©÷¢k6¡¤(ş(¡J ÜøÒœå	ÿ=™í·”fü¶>
î¥¨ÎR†ÜáğÔôü +Shã•\¢Øx©şĞ–©x4w©jëLL
,l„Éìv€#;ü¶@.Áx„à/bÁ8‘~-ìK 1)hN¤(S‡œ<3*Ÿ;{òEŞ—yĞ›ö	×ô½F†Cô‰áÉkK»/\Ğ^´Vİş¸GWá}A†Y¼d¹ÃYyªxÕëñ0ÖŒ¬ÃaY8šfa^0„í7øœÅ³º9_DlÁhÍ§¦öéqFdû
bã`zC¢¥ãbÔ‡h2qD8…åW>ª÷šYMvæ->íùy¼Ğ´˜}Ç(sÈ‰§OŸ²jçª€Fºl-¬Ëh^&é¹m%Uñ*½[£nÓ*qc½ã–ıÎ89‰‚KS}Qÿd¯÷·iËQ+•pÓ‹-Éà®ŠÚ^Ô<nÈ	#5Y3+­-\k­°Z£Vµf¼øHl1Nè°RÏ¤±~ØÄşˆ	¥	C	c/DÃËxŠ-%Ó•
3v—é¨ ®
T§+gvŞì!O²sÜÛ;ÜmÿĞZge†&~„WR¢î®Wš‘qcì&¿ı3
B´Ú&ƒd35Áa`úy´-‰Âá+Æğ>É…Ø€“`ÑsU7ÈÙ	x¿W¢¹˜],İÌşÉŒ·&g¼Ò˜MvÍÎ+hÛN1=BÛ,¢5Y¹K6¨Ü|!ª^BZĞA0|çñ 0ìÁåØ6Ù*|{´EÓI²¦h(šô÷½cÁ7äƒ×ôéøç`b$VÄĞ‰˜yŸ¡£-7'åáî·‹ÍèŒ¤Ø2[Í¸ëf€±E”İL‚l,jÛ@ÍÕâ¬›º©Bq¥Ü¨õı ÅéÍñ4Ò÷º77`O¬3¤ÉÔ˜ckaÍ”l™Ÿ¦£É`°l©PõN±@1Íî,ÁCHÉŒ¨L”“í¾V¾<G¨ÕUÖİ{³wx»Òâ¾á1|l¼­)âêÍ$¹â´9ÁİUl˜2¾"=ãSm$Ú*±‚9ÌÊt[Tój³ºÉcá†+ÔH$ÿ‘@Ğsô)õº5×šµÇ®-‘‹a8ßÁ°v†—C¿”D ­ÃLcÒ»á§JO”ÇÑ	k0Ö’ü-·8Í¿i4"è³“ŠNÅ;wnü6Õ´4:lKú8›FÄş’}–²$ÚV‰Ät°ïÜùóù<@î•Ò¥áàÒ\}a5Øq»A`ïfÄŠõÔ·/©HÜp/Ìœiè7C ˜Åôæ•}äô¯½ y¤nc¨ê:sE·
ŠˆGØÔy0’ª¸LrDÎ!GDç l,œ1z7Å²˜n–cÇïRsª%´ŒÔÆJ­ÔÄi¾o·kßìÿûšquõ|4¤Û»&V€¶÷Dã{ø"t‹¸ú·€9k¯‘ï{Ó>q³Qì€8ÿïò—uõâåéŞ¾@˜-,Øÿ g\ç[¼øÓƒÚnz§8çØ%8|k.yŒšéy0¯
#-›—Ø‹ŞûI+H`Q/šÁ›¼ïòZ"Í¡–`öu‚e!¡m÷(.48¹¹Û»ÚlL{DfİXÏı‹LÇIÁ.4—fµ…'ÅÙ¨_)İb›V÷XŞ–7@İ#?Î*¶Ue«\*s¬|üVÆ™iå£uÙ!GçUË\ÜhfdHYÕæDL`°‹Jú¤äá~f¤q«N†~dh¿Àævnv
®I’ŠîY[Ô¦‰³Úx·ÔØJåfªş^%©¸g† ·ãO¼ ‚6Ã3å7XëñÍUí§®şKÛ&µµîrÜbÜ/8~©´'Uvz©é°Ác;CMp¼·ÒF¡{¿´ŞòØq^ÖÑxxC+Â¤	óÄ<äˆ|éåBY2¹æ8¢u!à½šş-è¶ª>e–/J„,QûY¶ŒY?İ³iŒ VÙ³ğÛ˜ë±¦úÜJ¿²j§°›só„J“1e9ğÌÎ`0 Åœ„LÆ|Ä£
˜ˆx¤Ì2.‹'Œ+†®‹ÊYé‹5¦›Oqó?Ğ‹è	ĞÏj€óuâEhŒc³îW¶¼+}ó²Êâßş)ï™ŞÂ(gôHD<;#OeÉ7k“ƒš'ü\ÈÒN³ú‚[ˆôßáï5VÖ
yË_ùC)¢‚ÄFA1LÄ±éò,,SDU.Ë¡ŒeIG^ŞXMmàQ°Y¬/±øu4c÷(§`ÖÔ¨´˜©‘¥ÅÖÃÉzµ®#Lø]gih
3şÑIŠ‚`ŞûGŒ3çƒŸ=1Åd½å\ w®`L+Çí)eÌîåÂkû#qÃã’bb`0 À=rğ@èïK˜[B(â(!A0 ÇH$® 1NÌ!e ù[AµRÜ§Ù.0˜Ê²2*Ñ"Ò›oô_)S¥ø¦6¬Fğ‘Ağ,}¤ÿÛ?ó½…?ZdCší#/5…Ğ{şÈ âØG† Å…÷3lx‡'c7^“³=¶†vä“, ·Ñ[ï­g\¸Ò®.˜›•¡9ic8',Šn×–ÍL[nÙ˜My?UµkÕÏÄóÎ0sZµ³²±môG†û0W•ßÙ8™áB§^§X‹ù‰Î¯œ‰‡ÍÏNmãh¸Ñ§XœÜRqú~’vçgµ¾øÄM`ÅŠ$&Dº%YÓ«%§áÛ[ê¶Q‚™´§Ó±…’ØİfrMgP
¨Ë)h†ÒÒdOüWš´Tz‰ì5½Ø‘]À§İªJ ì]övÉî£( Œ´‘İÙ}™„§ÿÊ¡	$>â~x)YSkß£ë±‹.­|Ë‹ğl†Q§‡r£+ŠvÇæ1’f,»’L‰s][³]ZZ±JwcÂIÍìá…NÜs&úâ€üÎyN¹ƒ|²¹Vú#ğ‚¦Û™¶bv3xî/ÁJf™­‚Ó‚7(Ï‰İ/we˜SÉUâZ•¢ú¡dïYÁÄ­’n³·m÷±YÎ³öïòÜ\Jéà-%uf²@V|…u-Àª3Ó©¾0»#XÓz25-²53£“İÃ‰ó9N3Ÿèvq¿¥™kYœ>ğ5ıœ^
âËë&«ˆ£ôSÇqÔ|ìÑ³À@ğº“sÿ¢æÂ;5ëÓ¿îÎ7yĞ<=rÙuÁøØ€4üÉâM•`Ğ&pº™Ú.Ğ¦7•—qp¼¿÷jï¤·óêÊèí¶á
^ö`öbÇ3¿\‹#5Vù7¸Yá6"¯Wì–’vy“šÚ95®Ï"!+‡ç>ìÄ‰ÏD¸?‡ˆÎBâ0-«™¡”GÉC":r÷Z+åËmäcc†›v¶ÓlêÑGƒsFNöÌtÜ¨şr#ñÈ0¡g‡(»+ø	;6f¡œ‘Ú¤‹¬$‚2¼(ğĞØ‚ Ñ;ò[¼ıp²Y–8kvEí¼s6æ¶CÄIx,D¥3²Ì1æœZÖ2wlÌ2¯KÉq'¯DXÂÜ)b;C>İÿ­F0I(OúŸ%şÏÓÇğßğûf>şÏúÿm‰ÿv[ü·¢x?}+ŠŸî‰Bq§@Š×Ys€±¹Ø’fj×××µ«àÊ¹=d¯GõÜ%ê]ûSåµU	¾R”«ĞŞ°ª¢yÑB…ãÈgR¥•¶gu)AŠ¶şCÌOØû;íãı¿Q$x‰"*|Øûş¨³Û}K__áwâ”1gaŠ*‡ö€ÀU Ï}×5û›*\JÑ¼Wü­zŞ$@?PaŠ@l…æ¬KşşÑe¤ãUFt^æ#´õkµXõ!ûQ³#Õ:„qZ€—ÀëT¿G…,¶®ÕªÈÎ¡‰ØŒë ç³êkVDR¦?_<GõV9jõÛ×ÂóÈzfìÿTÀ;ÖdaüÏfãéæ“şçæãåş¿ÜÿïŒÿ¹aÃÿ<yçcPÖt¦/ˆj=IŒã
¹\àÎâ/ò-•	­qå$®áÅ ½¤J¤Íåµ‡®§ŠşFŞÓ{^ßGØEÅÉfbE	«ØNö^£—úá.ùUÍq˜7UDJ_s”ø¡ÅÃdµWKI`Hî_¡<™î’ÿ#c¸kâ”…8Z³à.=åÎÎŞßÙîÛ9x¹×><ióÁrä-W`Éêè÷<İÌâ>ÓÈÊèv?ì¾éíîœì ïA·¥…ïİÒñò9³í¥ëX.-‘ÌËïÛû¯>†™ÇôûdÎl«DÁœe÷,9KÃk?"Õ]oøCv4„•D:%ÿìQJgÍá-à¢îñ1Õ}–<°k¦døà” ¢XãIm}“íŸts/e_pğLwxi}J¥C$É@ØëÎL’Ãİ–{9F„UùZ¸ÿ£&@CÒS5
eöÔzÕZ×³¨`ö‹”ğ-Šîp™Ïs¸~+“şŠÂ†¾G©€ÃúyEÑ"\­Fî[šb³ûíÉÑ1¬ËƒKdÊ¢*bˆÇk‹ñèøDkmâ’yúØOjı©W›^Œ`Ó¤èÉF£ùÌ±@§èÅm N¸E‘Y—RÉîêƒ{ 7ñãî$ÕÍ§~ÂİJ¤Ä'õ™B÷—õsõ&ãQÕŠÏÎõ\·k‹´ëœVî'Ñ¸ÏôlæÚF¾1wÍ¬|¢fL¹ÕèI­Qk¸NÆMg&M»:1›Ï\5UóÆì-˜3™—yÃt,¤¶› Hj·Ên­4Ÿb²Ş“9p.kN!êº³6«,Ú•éö,›}æXìOuóÓíY†ù˜›gÂo©cıä6«²öíŒ¹½YG‘9ûÌn6©Ÿ³=fw®:¯sÔ‡*_:U«ŸJ$Û‘í§QÄì—Y¿‚Y?³G3H©#¤{Ãe¼›ÓÆğÓh‚¡g¼™È
$Lç-î„¨Ê3N5¾=£Œh™ˆ
fºŞŞn[¦š	Ó¨¤¼¯ÆB‹04/›.œOF‰Z+wı+âÓ£ğ'¿Ÿ ÛHY‹¬+
„ã‰×÷õ>À¡)çûrĞ><íí´Œôv>«îMPWEÆ	±VTXÚ÷Iû—Zµ…mÖ´û˜Ï…ò±µÂ_¯8šCµAùK’âÃvkÍ/út«ÊXÚSã¡ª‰¿[q4_ót~‰0È5o‚‘‘†´ø£èÒ7E¸èøq¿„E”TÑ:[Å§*¤¬Á½ºöág×Ñ}Íáè¸mÖ!æ• (Œ“}"Õ81]§ÓŞÙ§RÅŞ¯×S‹|o¨
Şä)¡ä"ÊR”Š‚ó)ŸsFŒzJ']Æ‹øĞEs"ƒ'†ÕÅIl ç¤‡'œgO²¯[®+à¦Úp3g½~V«÷>±2ß¿PÏ…¨äg2	1ÜÓJm…a½G,<‡Ÿgğû#›²`W¼£^ù,ÕÃ¤ÛG£êÕ¸vùşÄƒ<C"*<ª‹¦Öï2®g›#2`ràxkı‹Kƒ{¾EòLaÓ”F5ÈÛĞy'iÜF–Æƒ¦ş Ñ{†)Ö,%©‘Äq0©$üB%4jÏj”³ä8¦mpÂÔÊÎQ·ÛÛé¨ë‚Î}¬P¨%nQŠxú"µòìÕñ©äŸĞÂúHqSÒ™ˆ¸şê€®ƒ¯_»3­`­G£«§Ëäíñ¸Ó~½÷Cï³+kNYk¦·6ná¶q ­…ÚWĞ ;?‚3¬YµÊOl8§Zè/5T'\m<“Frê½ó(\ÂÎ™\LÄ#ş¤‡EÕ†“÷€ ÏpSåšİ*‡Ëµß(HÓ.a-óXsï«ÉâgšŠ?¸Sƒ?g{1¸‹pQ¡^è×ªı¡šÚ÷ŞıÇr§ı¦ıûn§³‡»G×q¾ïô¶ÂÅ'†8ÅäÆXæ´'Êëùhàxöh¸¯p´çêÀ¿~ïü2y›•úIğá|z¡=ì{A6å/X#—a#}û!‰ùİKŞko.ßõ«²&<7.‡Ód#ıFÏ]'…¡m¹#<E„6OÏ¯¸ ™¼÷>ãÃ5ô†A84Ãty“WÎ¹{ƒsv	ÿ(Z%ÔÀƒ]¬96àyÚFÊŒÃ¹3½K^Ï.<eBÈaÂ¿×Eúd/†>“$x6ÇUì¯+
«¢gÇ=›ôÛ·?:N¡“İÒEÉ_lÁU2/íF?'{0Å¾ßÙƒ›½cƒG)Šå°
	à´“mÍóvñà½MCÎıw(×şw$„b¼}ï<¨nÖş\ŸD>NÄêO¥$Èˆ†™´•ëã4`_·¡™î½H‹EÙwë"?+ÍnÎë¢Î5Í9³W¾à¡-¹3dÉ*øÿVÅJÕşB“Æt6§Féy©®h:—mEÄíóÈÃ}öıàìøÈõå
³}ù»91	—ÛWÅo5cû–5²”¸ËJ+ş|d•ßrómÏYy¶’}µ;_£aìüâ
‡ÜÕv³¶‰2Â5s»9É¦Öît“}L‡.X—Øñ”SY]ÀĞøµ±ŸÀ\çBu· <öº0ÒúSs4ğ×lÂ_ØÕµ·Ew&òşÁº‡±i6«åÇm¸ˆ•IkĞFœ·¦™¶fw÷ê¿â
™ƒ„Âv”K_`Íó‹oÆ‰÷a‹«pL³‡³$„Ùg©îê­GØ‚ñ©w=)>wÛŸŞ†“Ì+^Ašù£6«·[R…”&0ëM«˜ù‘Èø¤VC·ì4ìüø×ÿµäûÄ›­›ÌÖ˜«£3+H4Æê¼_ÿ1¿:Íü¦¨¾“ı4eÚKÕ^H‹L¶J8a¨OGÈH'Ù,ïÊ†¨'ÇÀÀ‚­Ío™Í¦4´†8Øq@Z°|nzTTK‡¬”t€†}¡¸
9k¦2àâ¬n@'T:NÏ­Õù­Çe4gv1
¦Ã ñÙŸYddÌøZÙÊ¬•l[XnåiÏn¼¥–ã×Gİ-µ0êR¯O^¶;ÙÅ{hÛK3×’ìÆà¬X¯5Ô²2Ô5ŠÏÆi_ÃëPuó®ÿúìåİÀé-Æ‹;¨]{•ŸOc²"™¨èX ŒJ‚˜)|xšpÜ!=Î%
Ïà¤ö¯ÿ`{˜
CÑÑ	óFÏN‹í6°R}¹“q·ìsíƒ/kÿÛØxü4oÿ»Ñ\Ú-í¿æØİÙ L›êw³ã¦ı±€á±&c²*ú"ö¾\%4¯p‹>İ'u4^‹Ög½üXøîOÙ]áá'Çá|«Ä-·e3lIİE2 lz8®ÆhC#²H#”÷¢­Â€ahîWı*uÍKX.ş:åqÕ?ê¦¸Ö‰ãè¡|)Lús0i™ £ÂÃ?'ì¨dŸHo^äÈ»ú=&U@€$4+¯3õ”äƒ¥R¹AO2:'HÚÔŸs<gÆÊôÔh9¤İÌâİÁ³ÇôL˜™Àï'ê·²§O	K©ÍõbÖVº§ğ†Qoà£Íó ­ÎÓ¿Íb7¹=«%"6½iQ«Õ˜™V8ğ²jte¾Ñ°EÉ"²É¡˜ÈMëuó)õáÑ=½„;}t·V+sÏDÍÃ9«²Å‚Ø$JËØŒX2N®|/b^]`£\‹ï¢Åî‹¼ãd°[›Òá.PLÜQQsïd<›¨›éä|ï÷È`U.îTZ££ã	(ŞtmäÛ\^œ²UTÈVEâ+hí'¿`÷ø¸¥cÈ¢>Õ'“ş‡'DÅ„
êå„<”jMƒÃ6ÕMy¾á 9³j|‘÷ÍÄ=af¬L6ÒHb“ÂÈ§°¿;Î˜¥û	Ã¯]oŠnQÁ'†-;ì%ÔŞN %œ}I	{4)YâÍ€v%¾¸¢·1v…PÄOè=xÍW¦ô¬+•ik'CqMwˆôBk¬S¼iQbNcİâıäg^0Igr‚™°ÇfWËS`…a¢Ø&`=¹Ã›	TŒŠÎĞGĞoñäÄ·Çø-ÊÉº j~â™€t©ÿÍN¡6ø•²¡kõ§ÒÑåbÖ=sbf‹)T‚³â@Ùzæ2/E>M8­=ŒDàıö¿;$pÀGäÖysâk3	-PCs *(“èÛ…“q<H0Ãûâ«¦BøÁ¢ğö˜ŞEÅÖ^”Õ­½S.ôèù—Q°ˆilĞèlÜ†³
aSU3Ï€;†WãióæÏ;ù›À.uP6Œw’[àÀ¦Ç¤$¬È¼§KÖï}äû‡AB•¾‰Å>°÷ƒ˜1âÌ³UEmÖ?æú²pøßÉˆ¸ ò6úˆ«¦J¥J9};6 ‡íÔï<ÛA6¿‡il*Ú°$Àëì.=Tm¿s'YzfK´‡œßú¶êß)6Qº^ºÛPÒğìÆgî‚¹Jš'ŸxƒTK%î¸WÌ‹±ÊC`¸…sÉıÜÀĞ"›—Cîg¨ÖY$òpŠC+§Ú¥Ú^4ĞÓƒß¥cZ bçZcaè°¦¡Ì¢	Ø@ÛÇ>{óû8ú
9é±ıÎ‡_~‘¿¦ŒkÓ¤•mg"¹nˆD\°gp}"Åc‘w0UG‘3âÆ²J“U6YåI6\ï™»Â‰ÀÑí{?î&Ú]•µ"½ˆD€Ó!É ¦c¼	'Ş˜BBˆÑƒp?rDDîÈíŠa P`M(•Š{º(ä”_š¾6"Ãö60®’6SM
õ€X"û“9uf¶ÁumÏ‡ë2iÜ ·,yGm™ææz÷"‰.QG±ŸšD™¨dë©bál=ÍâÅ˜í´5@ÃQÉî¥ÖÍ´p7µn§bÏnl[ Œ˜½ErËÅeAdÑ§Íl›bà•y'a:ÏH9c¬„Ì©È"sòÂ«’ 7‹`'dÑ´D°q?k/T'¸†éî4»õÌË vYpÏµ™föEt™F|m/—èŠ…·¹.ü¢BËª15mÖ‰ü]:i®>¨üéÏCoì_"„Ğ•7„6MPíå+G ¼W § %•oá+µõªÎŒ‚¤*%*ÄÜ5–ßcQ	Mû$Óğ¡¹+.o†E‚E<ĞxÅ\Yœİ–ˆõP®{}ç ÿ¯Õa?®Ö:æà¿à'£ÿi4 9{¼Ôÿ|©ñ7 $`¿šNj£Á—Á€o>ÍŒÿãÇKü‡/£ÿ3º8ôó|òÂ)¡¶ì¹?za™ñ»çuxCji÷ÉáE•\ßúÄƒ F*Ùc«Ê=Kêê×H˜ÏúÌÅÏd:÷¹ÇŞEşEjY‡r<¬ „îùãyİ{QcÌ™Ó<¯ß÷'IÌb`b»ãå&›‰§}ÄÎ§	GBxÃ•w|ù¢Z}^_Q$àYækÎó:Çi [,Ñ/\Dáˆ=´¶ê¡Ójµ€¸‘ÿ‚9'!f™m9%ÙÔÎ²‚~Š$ø<z1¯Le$K–FİPH•û¥ø	×¡Š­J©%>B–úú‚¨ïˆÆVE2·i]”V‚%-njDõÌëA®3º¢^Qø]xÒ.Iyµ’8“­…› ‹¯VÕàoªTJI^}Mj(jA)m3²•æ éŸø’öE6TŸfØ 	û$ˆ¥M3ö;l^pmÂêrşÛòs«óÆòóñ€wàÿn¬/ù¿/<şú¢ş’ã¿±¾ÑÈÚm¬/ù¿/3şg.ùtcCa¥1W;ùÚdÜ1ÍªØÎô’5¹ŒP…šğ—Îh™jDãKßujİ¯ÙáÎAÛ1M5ÏTÒ$ÌS–îŞáÑqw¯ë˜­9³¿=»xÉ5Egé'\ºágcæd€ól‰¬ix¹”&“qƒNß´…Y•lUµê¬zÆ»ü.2§Ü‘ñXGÏÉº—º´Ûmw_uö¨±ÁÚ¯.Ùìa0æÑƒ÷pŸ<Â±@äÊòäYëÖGÊè3¹X†äÓ0mª+§:«Jƒ Oèò†dß“;$5TĞ×ÉĞ‹	yüÇ5%Ôw2¤d¬¤’C‹t3x+)Í¶éÖó
â2ªŠŒ©IOõdÆaÚ|=Ï39 ë›œU½ßÎât‡ÎéÁ¸:^’Íœ¡‚ò?şòË[‘àG&›$9Llìqšø€ÛlËçÈTÒSaªM]Ú¶Åj±Ğ®.b¡-¦5_rì4æ3!a(¬	ˆD*xãF¸-Bß›Y¢«<ŠŒqÓ§ã„y±å­ñÖC¼7PÁ–u­KS£-Ö”fkE>ê<ì:{ÜôTm5ô¦è5¥ÍDe€GİÃ¤¤ÚeèËúˆÅ.{l;(,Ğ#¸—Ç8Cøj;=ùú¨ãd¡ÙVô ö}&#¸4!´Ìš³ä ÿ¿âÿûCæJ_ûŞŸğoùßfÿ{üdsÉÿ}ùß+>ôŞPŸp|¿F!–ÀÜ'›°šCğÄ'*T%À0Dè,‡§á„&;ç¥…³‘ÀÂ!
†Á‹œ´OC·â[•Ü©C²nUe .‹àÃşO¸8/Ønx=†Ş %…œ[!O~DıbT`:ÄSt/fH!·€'¼&×‹ßY öäyˆÆI÷&Ì‰U/B´O×ÒMü1’0&îL³PÒ<Ãó:Êl©&7•·î(ÆÌVû¯]´Ä”èı1d”5õÂÇ“ò‡’3.Ôï¥ñÎM?¾ßÓîù¿¹ÃGĞåùÿ/Ğÿuø<`èÛü`ŒğœBp’Êìš]ø^Bşp¸¬Ï§—Œğ"jsEyÀPìú}tîGùå!
 )år?lßİÒ„)òtŠÉ%zK1uÅÇß¬â„qTCı%{Ä8°¢şB
'O±‡Æ®ƒiŸ´˜Ô3u³­9ÊP£Yš=JÕR'Bæà$¦ÛY¬§=¥ŸÚL¢-‚éMãšU g7Öq·‡×¬+ Ù*®æ-Úş‘øf÷ÛFcíäêDaIÿ×{?´w€âiÇ”üÑÅ¤?zÎT8ÒE€^ä(ñ:ø 4”†éÁ0Hnì™¨¯œÂ†ÑzZ"ù«S³KBK³«	³«Ó€ÿºş$¡9ÆÍ²Y½Ô¦Òig_§R®ºé%!?ßa6cøK(¥¶^4!7‰dH¨$:.Ã35Ÿˆ;gÑ)Æ8Ô±êo'Hˆ\¡„PåŒ…A?ĞÙA§KM,A©qš*R17ŠwÆA$ID
ŠªO‹[L¼æ"í*cv1±:
*Í§Ñ;øú¡×‡ r–Şùmh#zç…bV©kzûøˆ¼VÀ@P%eYiŸgF
*V•îw:WOëb¼o—j³äÓ'^SÁ…ª¯ö÷ØÆĞ½ôãìş¦q`\´Êé/¦‰“SV¯£X=cFß~J µ‰Îú@ÛÆ™Rw¸™:ƒÛE€÷à¦7ıy`›ë0BŞl§ÚLXx*œrëbjcÈqg]~Ùd°¿ë1êF¸‚,qwà¾Ì¸Ñ&¹ùb,öô‚ı÷t¬N1Q qĞâí(@p®KŒDL€]ÑÈ¨…ˆ³”“ı××ÿß7×¿8ÿ¿ñ4kÿ×l>Yê¿ÈçáÃ¯Æçñd[ÿ_gAWkü!Ó¿,Ÿ'ÿ¿q¯*áE2²Lı:ÎÃ‡¨F†o¸K İÓM@#S=3CÍ,Ëà—}~<|(Ïó+ÊDc+zIú6%±"½›Ú§Lß5\újfmwÎÇÒœJåª5G{­D+éËì;yèç{cŠÎ¬%hš@{	¨_Íw+3\š®Û1ñ¹OıwFN\ÍïQË>eìüW<rŒóï3T“dñ²ƒ¯§)P¶Ï,(3SAU+,Ğ˜y ³T7_T€ejJœ·}QI¶9ÌÓÌPã3GSF
„uùl­`æêıÛîVÌn wM
€µi$Ìˆ„…Y@8Óe-`>–v³6Ò;0“ˆ,İ?H%?Ÿ~Òè@vQdLIpÏöö)×å4*¢ì<&E=™»°ÿÒ¢Á>[ÑÆùö†ÂÒA˜:Ì³uà5â¶JöP©h‘5&[^lÿ!1¢g\E!ï—óÿ%º‘õÿin,ùÿ/$ÿ?JhõÑĞÃ©üoS?¢@Õ1+KÉWÜ!.‰ÁQ©Å7Âónäû|=^„Ãax"…JDiJ÷Yr3ñ[î+…GI‚BfDĞa«Äi(d‚5H£dö†{18†çÂn Şiïì´aÚ»/ä6Ç¥
e²% tÀ‹ @7©»½!”•—wÓ
³urKeT”ñˆ2\¤ÄEFu&äü/½úÏ·Î]­YˆÒû³ûí3¶£k˜D«Q®$ÍVI ‹áŸï«Ïªğ
öF©Şà×ÿÈ¤m4ŒÄFı(‡<ærÈ.÷[°!“¾*ñ×°_ÿi{Jr*Ñ$FöÈÏ£‰À€¸ußàq{y}¨	ÙÅÙß@Â‘~üÒ‰BƒÀ›˜‚€&^[˜{/Y‰ó?‡ˆO`üÄ(§g¡À‘Tüz¬óJÀâÊŞÀ›hL¶Ö6y]•è“j†Ô¹åŒøÓIÔÕÁ,ê*ñŸšHµÄhÓNKå”¦ôè0EüÀ¯§e5g}Šñ
Œv4 ÜL´ÍŒRıAQ!'$¹-JÍû%pæ|ü|jV¤&5ğToOëJñ•Jë;¤Ô'+ºæÑÂÓ¼“Ù·ˆ>²m¤”#·tµŸhñ8b¿?`lõ2zFó¢E±3^ÜS9´çüÂ¨‰ï³:ä©Ã¼ òqwÄÚ k‘¾ê„çÇIRÅ%¼šmã™¹î«7¹ÌÑhÑ
µ±[
U—ŸågùY~–ŸågùY~–ŸågùY~–ŸågùY~–ŸågùY~–ŸågùY~–ŸågùY~–ŸågùY~–ŸågùY~¾Àçÿ Ïh“  