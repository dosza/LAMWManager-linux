#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1419513837"
MD5="af6a6943221fe8c60d07f861333c2444"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="24540"
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
	echo Uncompressed size: 176 KB
	echo Compression: xz
	echo Date of packaging: Sun Nov 14 18:36:22 -03 2021
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
	echo OLDUSIZE=176
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
	MS_Printf "About to extract 176 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 176; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (176 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ_™] ¼}•À1Dd]‡Á›PætİFÎUp3>„¼‹U’Eá!gåó¡çC¤Ùƒßg±yà"cÀ($ÒğaÃ^üï•†ûw¤Ì¤³ñNM°GyC‡‚°&²Çzº÷µ:ÓVá…& Óö^P8›°­åhÜIÿªêëÛ%¾wñ°¦®zˆÆÜ¦ôQ 7Æ†/¡šà!™¶×;‡Y·š-¿(İAı•N02ÓS1¾ü¶4Ud±Ò“ÆT:Ë¢×ò{zÏÒsäÒ5İ@¢w?éyËáÂdBÊdÉÅ.=oCÏn¨Ûl&‰=¶¸2Ïü kÉÜèx‰µÓŞ™7„½Œœ¿92ŸÂ‚sn@O•ÜÇ™ÓRÙ¢ó<¥X»vö·_~@XqRººòg5Òtàw÷)1E£[ûUv95+åoöxwÿİ_üÓMŠî{ĞçÔNÿ}çŞºXÙe“ìù2–#ITUÎä*²ÖÈ±øTC[ŞJ°OØ#“xéÅ«Â¥”ªÁÎÙñÄO»“Ö_åWz÷| ÑOñp*`ÔU©snŒ5µÍu5§IHAfÖëøöx×ânF^498RSuLİ=Æ"cy¹–ÿŒ¥“n£¦)H¬ßÈø
uêÇxƒ²\É§´ìu!
²¼O™¥Gh&^™½:‘¢aWœœ9o…b#>Xœ[;ã1gRb¥¥2“”¤ö@éyW‘â‡22‚BÖ	ŠBşÙ§MëFéíãD´fO4w;s<@C2‹Ué€á‚‹æ'-¨ÎÁˆi”hÔ÷äâê¥í®§qCÊ3KÌ $ ]a<úö$(‡R¡‹Ö™q›$¹IÓïp:¼GQ	Û§eRÛìá&l„€@8j,çyS7«ˆÊ®èš„¨ÅÍeÂx[çòˆR «{ìg%è0oÓ'«âÿUK\µÖgoö9å_¹ñ¶ô`yâÒrxı›¾°‚“b§#Hš¨üì@çs-<:êüéµZ¯=Ìñ8	6{XooL£k€–‘½®ºiã~§Gªf£3f?B+%MLvk³ÿZGŠ|î‡òzÃ.çèÀ‘c(2ùÿÊi¦¢•îÌÏıS3èêéAºÑ†®’E©ïÒË•W´¦I£R\_f‰–™×^W4F“lX†ä‰aşc×K©Q@Â»IÚÌ(_}cNÖÂác÷›$úó»¾ØÄ“[Úà¿§´aƒ»6—©÷¡€9²j¨Œ::d¯ãáır’ˆ¢~Ÿ2ôW…¥‰P+aÅÙ²VwUâïúYz˜?^™\NrÑìò¾^00×AŞP“(¼5—ìÕAÀµÍl«P8:{É_“v%ğzçÙI"•ÈcÉ™ñWş Œíószî¥ú‡$·¿·º‡fŠ½ùßƒÃ¾ÿâƒ»Ü_rvûÈñ.óÎh_¬ƒ˜»=çÜ."¯-N€D0­ÊLŸÙdìÿÛF.k×¾g?‘Ê÷|Ê§¦²—§#°DvæLMW
4AÖµ,f¶G Ñ~U…oSÇmõ¿5€ÛcV!¶Yú¤vÄÿO÷a)É<x—–¸z$ì¨LŸ‰¡õV™å»>-6`Œ @mSı7H**@$ÂHõŞWÚş~Ş\‚ëˆ~òwG‘g6,¥ÿ>¡‹gå<œwºY[ŠMC@Šs†@3‹]ËÍ9ŞDëÀ¦€›P³L\ı¯&QóJÔS­6<?¡Vè<yI
Âjş÷›€#hPÊÊ=Cv\*€“¾LğE¾´>´Â¸é_î=<øûû·‚-KG ùR"¼ïlÙ1A+DÖşêşæÓµ“7»oM®NÓ²ª­©Æg`l-\Z¸	Ú`ãI‡‡¸µfUcd¦Òë®Õ!£xqÆ;Œ!šÀXOü?‰cÕMÿ.´‘İÑqó,W‰ğ>`5a;†*8d[LØÜ”¹¢2ÿÀ¶£?ìé³cĞd9ÃoİİL&¢íV¯ÓvÆ1£§û»ëm-±Ò¨Ñ«ææ¤¯fq C…«Í@°ËqíSªâöWÊÙù«K»r}ïÎğ¼ßpKÉ»¸ÉqhN2çÜıø‘¡?º>ús(Ïdİy6Gƒ¢i}İÙpn.e!ÍßÎWL·0Ÿ¶ØTL2&µu~êV’½XWk¿öİº8}GU2Ş¼ù,[ÆçıÑîØÛWĞ¤èU©÷l dŞôwWF$º<¨%0R
‹ßCöÁ6	Œé»_2nìÄ¼k}ö(`e•Àq÷böÉz¢ƒHôIÊâ³
^ŞéŠèexù” K«äh7‚2Ô(×€{€aoùP#¶ øD~ 
Á5UÿğÏ„=/®"Ê(w¸]PÈ±‘Ah8Î|ëJf!Iãœ2¿¨u ™î7€ˆó¼Q$GæCíšç­—rÜ_AşâWÄï»ÍŞùÏîü…$‹
Ê¢^A»‰0q¾ËÕ¬¬PæhBõH"¸†á•O^,Vvl ½–}g!½ÕÁŸ_8LÓ¸2½™”±úXagÙ(ğÓÙÀ<kìcb3†ÅÓ‰ë5ò&OËó×#·<q)p˜oóxq¡´ò²Œˆ˜éİæAşÕóÎ¢ùf»dEÄYF}²„½¢€ı°¥©v½ş™%iüwjÀãmò<`½z§ ¹Ò@ĞC&’Ói°‚ò)ÍŸ¼Ú]—»»%Ø(O5O¹D6Â¤-t0Ÿ›ló…	İ9«ˆÿğ\>øöêjj Zk?nT¾±
|`úŞ«Ğ"“nïÕ%Hû{á‘ÿòvhåò 	v:Î”Ùí¢% ¼Ÿ Ÿ¬ç˜Ãf¥mG1dÒúWš˜(“’ƒèºÓ^Ê2i3ë.„}åŠS_q-¥.ïïSû6‘n‹Š¯%¿%¦Ì³r×¾SÊ×áıóe²ª8v%Mû{7D!?íğı¦–'¾ ñ ‚˜&°]u¸ ÂË#ğÊú¾nŸÿ!Ñ¢$.®¹¢1ŸúZ	I|b ?nÆ¼6k3`¬ég~‚CY«ÕA"e‚ò(#¥Ìu¯uÈ#‘Ñé*fÑópƒ;’äñÇ™åâ7Û9*\=AC$aëò¨<2-¾¾ø«pŸz¢ñQ€{ÊÌWıô«F\|Z’Œ’­bĞbædg§lK$©6xµã*MÊ«ˆÓ²J¬³¡½ã…Ë‚§ì3iµ‰}Îuì'äq0?éL”È{oE}ìšÊ2
º±mlÀ‚f4¿Ãr5àË¸î9)ÃÈWñÚõA0N®`mbª„gKû´ÿ)é€¥uÍŒìîN¦ô
FCŞµŸÿ$"87ê§{Ím?]ì·™ÏpmÙıYyéÒ«L1ÏHqŸÂ{Ô«Í®Pø¢HÊø’³«Å­´uzãübÌÛ¾v'”ÔesÈÈÆ±+4–äf;vêÇØÖFzJÊ'	Kñ›Ä„%ÀÓ>Çımz¦úªH…`ÍØq°M×è©Ãñ‰®há·‰Ö…¶;™Œ·ğªÓÉ!á­b?A÷ÜÔ¸Ùèz­iõÉ\å˜tcÅ{ÒÌèmøhn²UŒ3_Ü3ºTê¯ï Îş+	†Ge¿ˆBòLÈ;çÔ=`'ñ¹`ŸáY]q.Ï‹¤¡¸pø>Cd_#ëO‘mßÀVO6w]rÌÓ0i;‰75©Å]œ¨W‚˜¼VLÊÓ&5x¢Ä«Q1glÜZÃ)·ğÀy³n`Ê•ZE¶ñ+C•KOù‚­;­–fuÇVhñ{sÉ¤¶&¿ 5üÍ?+<é‘€æà­fçŠ¢b*ŞáÂn{-³ƒ¿ûÆëåã¦ù“„n$nv7ÜèÂèCâÌ»}Šó¼ß³#õS
—?ûã|ñ†·»V –ËÏQö tëÆ‰\Ú Š\½ª]2Á§K¾GÀ¦¶€Ñ’ŞYÚÎ'ƒeÿIä)ø7OH”¦œAñÒ‚î;ÄòûÀkr¬ËW†
ş*÷Îãï®®8Šc-¸¡i÷‡_äÚÜİˆQ/n?D4™€(¶yë¢Nó<ğ•k/]8O{æËÛl"bJÑÏÛMöŒüæİ5.=tòï”ß²µGÿÊOõ)àäÀS˜¾ı±ñ•ë¸¡†*I#„ú¥7hú§Id‹g]kxnGË³Lb¦¨Zp4cOû%îİÍ\]ø§>¬ÁëÿPl±ái#vIäÂÕ}K<æSµ­fw¨Êğ„¡ÀfA8ÎNƒ+0ªıâêÈ¶\²ogˆœC×_šJ*µ½4@·~†ÚoÜŞ]Ïw¬E`[a{iøù1á©°¾F½mZœÃO¿PªÂÓV·Å OÉG,3pô°[™ŸX	±­*°éUXø-¥OÔÿcÂ@ÚÂŞ±†!Xåò0iş~×ßR8&Èş"©.´ùÊÍQ	àœûš¯¥îÈkëÆ¶LÃ#k†ÈÕÇEãI­8í¦]š7mï Æ·Çm„ öÓX_ÃàSDà»TjÁ,*[²‡T¿èŸUÙš_·d¯ØAVa ’=fa1DOÎ¨iiè¸y{F?3N<İÊ‚i¶SU%Ê½øO»2 Tø¯Lbu&õUK}™d©Ş(Ş5
Ï…ØÆ;ºSfÏİ~EÃ›Ïj‚ºZÒ•!âO9
Ÿ%$íã;Gæ££R+Fb%İ¦ÑÄ‚Qbêvšá]€Şá6ÿÙ)÷×À>ï•:¼JK˜T÷3¾ßø…å±.‚÷¶¬ôœDö=˜3šŞİZ/g@Ø|%6ñç‹3½ğXì¿ S—³µ!”¡µòİŸ­·zóó6û|÷Ã`Ğ»S‘'…RÔs,Àø'¦Qñ6ÙÏ4,
wd`°sáJvª)Ä‘_Œ³Eä€ÿõÙi©‹É¯ï7®=ÌQ‰õ×cÿ>ò’*]«×ÔAì,j>5‰H0ŸJf¡ªÖ”ÍŠ'PÂCSb‘8SÖ{V†¶68ëªMŠ8L|Ñãëè*ÁNqú©êHì:ç!H„ÒqcWÌAÙ3Ğ–À$6Ä@=£áÂk+fìb›8Ê˜¹£ç…†²û¦…²/UÚh³~tXù	¬12bÙØ-kÿ GöiÑ• Î;÷–Ş°!€¿şâĞá	8ór=º~5Ğ§BõùBd@Ø"¨ù0P•şøŒØùQZ˜X@€5v"cœ¥-Y€š'{•·'IÏÎËÏp˜îœ­AæÂ‘NE=´SØÚ D<¥íB€Ù·=dÃ³)û%Jƒcñ˜.ØÑm€g£’ÑvåĞÇQ±dš›&Ï$´µCNT!ÅuNGÏõ|˜â+ÑÃ@+GÀ—p È‚¼ !©«¤,.à­£¼+²ÅXë:cUÖè²Åß}W“¡¡sdN¢­ @\ß~~0¨s¢C§oª‡ÃE—–SÏ¨¬¦Ÿç£ıÙ˜2È…!ÿÖÄ'ràSh¨¡]EMKh5î=EÚ<ùap,EY|ğâU·oFÁ©/«lÂÜ”ûK!åY£ÔM‘ùäê;¤0şÍ0È²Ô‹ùx÷ªrDÄŠ*K†°q8Ç´-¾*_£ïE¨
şı¤ßªé&å†£=Ñ.MEÍf )õØ—Â6±ßÿó
CáV
ş_ıf­Á”cR]ı=Hvlº|9PÕy!œ„ã>Oô‡![A7 ÍãAÀ ó…	N|L‘†õ@Œ×|q§åÌ–ØW¬€iè¸Ş}úEÃ—Q’“ÙşÏQÑLÏĞ;+Zµ&»È?HÒ“¼‘‚¬aV`àZ½ñ[~¬ãKfØ÷.·ø…,#2T½>@˜Pl™Gı*F§#ïÃìeÜiLı7KÔgıÔß…E—ug[ÑèlúKY²ÊÄy¼Èï‡°]‹Q°M`ŞÚô”ŠÊøIèé-"ÙÃš)¾oôÄzßNå"ªÿÆq“ºÔ~Ò	1Cù>k+ÆÉ>½ˆ5–z,uòŸ¹ûšÙ —ö¨LÄuGûÊÉ:·¥CL]ÈDDy‹U±ÓµUhåe°v6€b›'ÜßøÀ2 €QĞ˜ÿ¶İÂm`Šiuí=»s&Ê¯¹÷„|‹rêÎ¿2£§Cj:’IÑyGGÛÃò5'ÛÇ¼C;ñ¬I²rZÿ¼PëÜö‰Å•Æ«†…Ñ†GàsÕ‚
‚(¦¨û
jÍØ¾°`%Í×İÃ³‹!mL[¼h
ñĞ,T<Ø±GõEoÊg `À4ÇmŒz|Šÿ/—Œ¡­ <°–|Î]N¬ËôÙìiâPZ|Ïş¹DXX+ëCäÓÁƒ†ôš¸{’65#º(ç0wèn
L›Ê‘»¢&(ÖYsqÈ{hğ
"€êNşğ–¾²ÎÙ÷í‰Lá!Pœ=’ÏÓä”BŒeŠàÃšpÕ¢ma–SĞúòß¦ÓÃ}¤X8©¨Šm9®+ĞœÆÏ:÷apoÜ˜.Ãßø~Ú¦/à8ôĞº	ÛÊÖ7-ã&ÉïÂo˜C‡>.c»İ|·5#•­Ç.¤Ô²¬9×ãÕı—%iJ
iãÑyÄÖGNÃ•_åƒóa±g^_R~Œ¯D.N!pmš©DyEE±ªÜ4QÒıAÅ‚“Íª¦søEïí`­ßrİ¨ó}F@™µ„{üıóêÒÄåuC®ÀËıl<©ÜÈt{sİ-†~  9Ö%ôÆ™÷ƒg¯íq’>¿yM0p	tÍÃD®}TÜ3,2½Ùi*õŠñ3òñf‘éŞH$i?û„¬O`„—ôûâøsµSm%f
jn\HiâÃ‘Ñ¥©ç7õ•~şG6ú@¾qxªªSà¨Ç¾t­¡•Ìåÿ%—!vy¼fıƒ†W2‰m¢Çé'7ªlYG”µzbM·¶x‡Á ˆI¼ñJv	”…>a70]…[<Œp›¾·V“*éiEúëÉ™W«Ş9ß…"êhÎw;5Ùâa‡ªõLğNoŠ+s~õ“Œ_>Ú„¼­dˆ§±+k¬RŸä°¢‹PÊ>*2¼û¬ğG	¡óX´æ¨Ä†æBÄC~h´éçÿVÑ]k­è=(mÍGÙ»ûh:jûJ§)kn-›Hó4¹\$´OûÚ.¸(ÓÎÌÛ\X.e[qñMl–Æv¾Ÿy~ÓµÊBj§YTê%ı+0yZ§x^ƒo¥ Rr<;nIbHÜöŸÅ•ŠÜLdlÍw‘ïÃ–âõŒ½*˜¬&¶M­ÏFl—Pô“’UU•7W‰wLì[r¯¡§*ŠÏ
HÃ®š'T4ÿ«R…×ÖôHè  Z“Íñ·İÈNìh«ŞâBM=éÊ¾Mƒ òô‚|/‹¸e£>³”f„?‘
I1°µÉÅW¸¼’xJ˜àŠÍV×±<4%{}¥½)ÍnázN‘/5<hl¢fÌß«Äé­Î¢ó®Bºv…âkš·raw”çİ„MA/¸òA^»là\ã¯œ0¬Z¾jCØnÌOï®;k>È$BˆÎØ†e‰;òı rJ„+ ;8ê·	S]A@+®ÖXÉ‹pÎG¾ˆ¯¡'¨_*f18C™ÂÎé5PWäa·ÿUÀ‹M™KnéQØC,±¤¬ë3“=™|¨ÈÑW¯tv¢mêFHpÄèÃ|Ñt½ìøw½Ï»İğ=´"u°•íQx°Íw¶#	¡Âà&§ô8g£àEydÒ-µA30´ÑGk%”;æ‡êşY¸ĞşÿkµX’ØYd3;_ìP÷sË+‡¨dÌJıİ	¥D«`¢AõÓİqÜşå6¸|Ò²Š-W(hVŞZåg¶W-²ú”~1AC.pp~ª+;/iÎ±¾
ÉÌ ¥ÈNqÿEZêRG_®öõùÔé0¿GrëLÙ¥êÁó¿Zœ¦ª³?IyO6Ê’”Ò€Ÿ©YÔ_‹SŠVÛñ(òÑTrâHšë²x]ı÷¬£ëM½/;İ‘¢pÍ¹›+‘Œ”º¯˜ ašûf)b÷ä¯¾‹;6\ÎJG÷l{ nŞ9»¼kª[ÀËùw 8áêáe4RR­ }?–¿s 6YûH.Q$ ÁwTİÎD¼¦ê6ñ#V»cKmT÷´„<lè0«­J½¿[lÕf><. ø˜öì&K*_6‘˜ÁjXZœ‡=|lèÓ£UÄ"è]k5Ó@Ç‚¦á«Õş(WëKPm$ÖÜz^şâD<Àój"ÙÕdú¸	P|Íë¯G~×V¢Úzg<oX¹¯†.ªŒë#Ê¯Iv¸õ/¨3Òşìµ—±/7’DØô:JâJP<ëm%9GÀ@¡¯¡²mNĞœı®sgrÌ)L¿Ä7C•zäÄ¿ö^F/¯xz&èÿğÑº
j“¨ä?S¹+%M5wdº¯”Jˆ+iR¢Ï @¡	jæ¬ı,Ø>ü—¡«®ÿƒ4ò¼€Ò;VÜ09f‚ÃDQµã÷Ûiı“œŒôuˆ\9ú•ƒ¼â)ü;…IîX¥>AøpVLòk¸[™Û6ëÂ!—#ÿÆˆ[™9A2ØUØsrän½k˜2”ø)ÏÈªôï>¶¨ŒkÇ4‰‹xf.,wá€äú/ãcQıfƒ³îtK©?Š¨0ÅDèº¾|1­æèÛúÿ;OÎ5Áß+Áx@i™•xûÔhA1«¢*¥›)£–`*—‚‰8¸h¹a¦ZÑ–¼óF5×9o·¦°W]˜un
çÉ;4VÿMìl1P)ßú#^İ¨E?à‡ÉœÙN«\{tÁØù½];ÿ[öø•È ´5fĞ‹7K¹o¨ßJÙ5ƒkjı@ô¸| ÷å2ítÙñÜEÍ¼¼Déf:K+P¬çÃb(jò`Ôiî˜MŞô6Äƒ­}ì¹œQ›‹¡š+ÖÂMÿ™ a¸¯=2¬u­-¬&Ï<K¨\_?TTœÂ9–™¸ÌJ±À‰á»óÚ©œK3ºçBJŞ.!ü°Lì"™d~Ãê¨jhƒ„ù·†€®Ÿ¾lGÙûüÒİQüâ§Ëõ^:Tv·æ¾V+:@™XÊlâºëÀ<¿×†š°w®à=L\5˜ÏaŒàTŒXuêâ_6€nO"‚htôp%!ømí}Ä°+rŸpK¤£Ÿ´Xrìá!å	k“7OeLqğ
qòÎ©îD	]âÉ$9Iß™.˜(Ğ¨ÖÓj7-ÓtŒ"×ò7DÙß”¾›á2Iª›°ª4Z{^âRX1ãüS‚§¼£Ü>v×ë§'Îî¡Šú·½}Å¼›JŸì¥iÁÀœ‡9Ğdáñò+¢{R#®gÎ–èX¸˜Õú3“Qza8CˆÒ2=aé%´ˆ)çU$–øöÄ_XÛ}0z1
«N–C$By!
X8¥Ì±Ût	FGäE"àg;mgd4Ô«¥¾ˆjÜõNõ?>4|æ²Ñ®‹\Äm)võgñ¸¯¡BcÓŠiU?½(” xæ(œ§T‰UïÔNóşvéh…ÖcËú§“£”­„ÔG)¢•~-ßÉFU(©:éí(fÅYšC’za¼k–‰„ô—a¤hÁ4-Ğƒ`%‰ŸéZÖ^O†ùš¾S:"¡¡àˆ4o‚ÏB¤ØÕ­ZÌÇ	TİÜxõ"‹Q¿ó’Ò.¸‡ô¶Û?mşØñ¸¹GòYÎfÊŞ/vŸ¸MVZ©ŸUJkKCó¨ãå.í‹J…Ş™Dãó×}¶fÄ©µ
íRUß>¬Æq«]b“* ´Ñİ­3Oí8ŞKŒáÆdT4“»“'ö‡Éá•»1£¾Œ÷ê	ïêOÇ2œs˜›4Ô±šÃ&_å°E@4r×ç—)»§kg‘±úw‘(.6?—ğÂçå&aC#:v¬ÔõlmÏ‹ŞE‚´Alí¿{’¦[
ë©p1³3E·>J‡gfÒc(¯ÚF^[+v21x9QFßgv{§öäMä¹¨3F54§¬#Æ;i¢‘¨:}•uz„n]ô¶efs}ªÓ*¶Ìôì•7I(;v¿Ó°‘ÉÔcqí|±øDådæ—YQŞ6#£Şÿvxd×CêË)"¨"”m8}¹ùê/jÒ<ÄŸŸ.}#ƒ9[wØ?2~Ö0ú%(TxÙZÖu1=P•SçËœ‹X51SÈ0¤¢é†„A6ZÖmpíhFbÎ’\æÄö‰EşÇà‡ÒÊ8äÇ³¤4`J’‰FÀ¶,‰kİÒT"ëêã÷»‰`Ü©ØWe6°nÎ4s¤nËyrÑ9êvù[UMWvşĞZFÅìtÌÿ7ª…Şú'ï5æ¶ıšœ$cí-·EI¥ÈuŞgİz~¹bÇ ·?.½‰š]ïÚp‡­;?•&}íğ¤â€£M÷ßĞŸb¸)ÆÛ"ĞüšÎ»›W1KÍ Äù*)¡˜ö}PZL’pPcOšÀiš¨ZF‰!¹Í“ÔpÃŞÍ—ˆãh[©Ş\…˜­3õ·Upˆÿc!fKÿáFá67:vƒi-0N<Ë}¥>†&Şè8Õ¥šaÂßà´ƒúù§"T1mXêvØ/b§9œ¸ÕZÊüì2Ë5qv©Â»Ñ£ÆŒ{éû2R68ÜÛ‹4ß¶Å#-¨ ¹“‰{|Âú(=G1#Ù«ÌL4â^ÿÏ¦}‚›yD÷á3UõZŒ©|w¤ç˜0T	ÈèdEÊATÇ5œQbÓSá‘KH	shùâ“‡D ü	O€È”€NV+ùyß"»ö]ª	ü¶È´ş´ïĞa—!hÂIk¶Ä˜„®Ë[d¬<ô h-‘†~Ç`8²­xúVù¢}S>!ä³eÎyÃ/8ADötZ~”BéîH‹³oaJÏ!A­·C‰µxî¨JOMµ1‹é,¡Ãÿ>?aêq‰ğ)¯cµ|l‰Ì‘´ª	”¹-Ğü{äæPù:$Ñ~#_"+	7b\§†a9R…›L8æßX­¾™M–-Ğ:Q¼bSu¥cË´Ç˜èi•»L¯w³ÆğMO6>éİ ã•LÒâJîÁ\ò\¡étæš,Mç¬ø—Àê™ØÔÑµ;P9÷ÉPc”øn¾3”/Û}"•Ïo•46,İcÑDw>’û0ÓPı‹?Uş.íãÍ6»ú¼Kh³Y¦ÖÚ< ÌF3À`ã­a†£ØÒl}_tá†a2¿ñÂjy¥J\]I»ïóüKF>3ÎÈzW¾2Â+ÿÏæ ŒºÒÉ%ö¡î9ß =+ŞWe%ïAzÄ”³È´MáÚ¥™âÀ-R[•ÙG9`¦fzÆÅLuÇ‰m>=ª–l@?+ò®üğõXJf!ğˆ'Ó”R!ëP
o?ìÙö /H\Ò~ugÍ…çç¹,Ó]yÆôTZpŞä%7?ŸĞ·¬÷ŒË³¨ÒŠ2¶cµ÷bvJ÷?å£> Ìp3GİŞ‘Lş¬œÊs…‰V®³EÙú5Ï˜F÷t™Ç­Ú*ğNü˜ùÄé(‹Qmg›eÂO{²©´)¬WÜñàlG:Ò²"¸3½-Ã·_9…˜CÿC"#èşw*bvô9èJ+@E–,³É0rœÇ×Fÿç²¨›TĞœà“¼¶¼«çÃyªI¥ğ^#aŠ$Ã˜ä~N2)š)gD/«<X@Qìï{;09ÇjŒÄ5îJ=·PiÚÃ#êÊÚ+Ò ÂšD“JS×3ÅëeP§i;GyQ¼ùØ¢T¬K'ìQe=x­ìà£	Å‚EÅÕ9‘_g(¯åvëj–kç‘'îÕ-pÙı—€ÑZe¾ü}òQDn»égæÈkåœo£ìhåÍ¬¼
\ö¹~Ş‰YÙ™áŒò‡óšš½©éUÆ<µµ¶üvsøÌoÙ¦GaÍ“ÊŸÏRHdÉß.‚â÷ Êz’½£aRôqí:vÙvéîöQ”#MÎâA¸²Ş &±1ÄP±^~Çìt†’ëì”ƒÈë¯†ş>¤ ÙøQnËğ`G±U}K=eÁ$<›[Í¯‰KmP[¶Ñ=Í‘x
Ôù6jya8>N
ÊâgjÀÅó1éz7±\o;%%kc1”§r;9©ğ ßÙÏ×ËUF$YnR»–„é±ÿyìÇëúnv§¶(Ç©cr2‘s×ôŒ	[ßù«ä½Ó„íZQà/D±&ñÊ« ´cYê4½Z†ß.ÉªöÑçÒÒp†Ş"øÅ‹vÍ’WØ’z03Œ{Í†ªñ•Û“®Ów_É7›rú’{©¨B*Ú¼Yàˆ`D¤’9ÜÍ5Ú¿9½Óån)
ßµ’Ù‚dWë*&y'ŒÃ ÚÚô£¸ceÂªwñ(Õ¢ğ”3¦ùªˆv®$N[´é¹§™?r%yD÷?©ol•é¼Ö%,a06D_¬]™90¤>ˆ¯­ôqHIÏ}wª óW8†¯ëÌtòKàô!YË¼9ƒ8»Î}»ĞSÆ™¬é	¢mëoÙØj(6OAá~¸daU>»í¿¹[ö›^_ôøoá´ÃUI‚ñHoE
b” zN}¸Àó½à;Ë•ˆõ*(¦Åo=®BıL~>…H‡¥¦ÓÖ”Ç` m¼»ÀRÑ+¬ÎƒUP1ÓWqäq¢uv¯ºSôèc9øÉÇ,{_GÓ&øŒo hóğn™Àêò’!l…ûõÊsW“‡”q«Ë-…¢½W—jpê;¬ÅÍH‚ŠĞÇ£FÙÊÓÂFòÏ’MK½¦»b‹ÆWŒUaê_JyßàóHÏÈ*RÍË=À>péà,í‹‹f¥ıZñÀéÏMó8¼Ô•&Ëd†ø2Q
7>
!h}@êô·­ER®á1Pü9á+Òn£YDãĞ/¹îï®WgX{‹mbù$wû4ñüÎêJc}ÂŞ`sÅ‘3ÑäfHğlêO¼3†©êŸ÷1Ø–Gs€ÜDC{v­Ø#JÑ¢^Îu¼ÀAcg-ŸV5&6poœñjB¡u†?(?´<qØ³È€«»îîÔ	 Í¡ßâ¬KİVØxbw‘ƒe!ŠI$î™ÇÇFªï³ªˆñw›¾½álhÆ8ÄuûëéÎƒ	‚ÊÔª/ÃWn¦|83c9—ô¾.˜:¶³sïBÀD‘^Â@ÏxsDjË¼|’™ª·ˆSù‚÷v'”sH2ş¶ĞÿZg³B¢#q£PnMTfnœm¡¤o,W³¯‡Ğ9D{KøÇ8½Şñ‚"~pÉşûÏtdË'-¼Ê…W=‰äT¹FØ›G	1?öèmI7Ô±9a9jõVÁZt€ºŸ¦-7(‘*Ei/W¿™G8¦ò¬O#}3˜;‹¬Æh†ÃVF(›¢¹ñ_l‘dëî@QO¤›Z¼ˆ,µ@91çœìGæÎÒM û}ìô,*Ü¶17yÏh}ğsüÆ¶r¥{ŒUMMïa|®™•šĞôgüÑ)“Õ++a± è@$8ªë;‹û^EFj¦Ò%/H¶Ö»øXØŸİ–TÇ'Àøå±µÅ’l2Ìvtúúßé…\OâÏÀœ®Œ²B}¯®„C'é®°agØ1¾ÌŠvy5šÖ½Bà^6à1o;?ñ;"ˆ»UnPYŠ`ÛÕåı¼¾Ü±@À÷+!8±\h˜([øŠzÖŠ	ÍhBãÖ+m¦>SMQ8ƒóÊ—¾›A¸ƒm0†J’Ğ¿õ!«ÎÀFN«ÔÓsP”‚€"bEÑr‹WçDwñ”Ëè4&¯:Ö…q×%E#?&¹©a¨¡ Ãjöñsru9¥VîÛeˆ–üv0pØ–$jS¯DoıöC­syÍ­øó.HÖ(œ¨ªŒ2Å\ö×{· Ó¿Z¡%8tZ9õŞbµsã ÓD+Ïñ…ğæısQÃÂË‹q–¸„$Š¶0Ş•Uö€Ô¢¶ z¹c¨¸€!9h€¼ŞİvåïÙ‡&ìî#5¢Ôê»ö	Ë
&”tÛœ4“¢zî2¥ü¿WóÛz+z°æÓ¨öI0ş½[qÆ)€ùĞ‚»l8¯’8[jº¯2¥ÀtV¢÷äÏAÔg%€5pë“ÒÚvº]Ä÷c^ëòaYé–/ì° ŞÌ´¹çÑËzpå	‚‘(™ŞM
#¹eËAÙ½ÌıbéçS	ô˜
á¶•‚Íödê<LÚC‹C*Ø`ë¸GW •¨¥.e|J› dwC¦ûÔ0ùğ#(ßåıîş›]z¸ƒÏÌÃù]6ÖıÛğÿÒs)Ñ$n*LÄóŠæ=WÈ î'P]¸d=¯:÷¦ª? ]æï‹^È.£–>dI¥ª«R‹H˜_·Æ‘rw\ Fbs9> .Ö¹Éôµ3q¤çP¤®«©…Dc…Bìil(Ñ·ê’p¸^Öˆ·¡Â8Yü:­ÀİÊNªrÍP¼WwBÜã!âãŒË€™Ìì^_ì ! P[p's¿Q%IéfGXÏ±¶à>ºıôPî7 ø«qÈBÀQãn’GZËèÒ™FçË2<sC¨xl'ˆdPXPÖ}öK\ùuğ‚w[r`9ò°€Uì'DÍYŒ6Ò^1`õò÷ş¦?eZß¶\IÂÃ“—şÚµ§¨‰ßÿdş5«½z#Snx÷«HCoSşñôÆĞ–¡rãŒáö¢ôÆ*8¼œGKŞIUE 2ãPOòxß"¦»5ÇcSUPÔApcë†&%Ä5€ÁÀF<?kı­ğŸ{da+Ù{ÿÂìØAğë°K ¿¶¾(ÇÆ!sÃ‘-'ß7€M¾Ï@ÛÄiÆÊyòÆ‡|ßËî;€[hğ{èR´’³­ô$EF3­!¢?òAª`ršFÃ”lwµõñG‰3$eÜı<‰-“º*>T’Œä;µƒ‚ø,hJ8}mtßÍåNkßsÅc“^ã±¼7dûUo·=“àêø`EÌH~õ¡BŒƒ÷´Â½ÊG³±ò%á/0TÉì]¸˜™ŠÿÊxB.Ç&è:A
m«UöMÀ˜äXRaıGë¹#6Jÿ7;ÀÚİKN·Ï(ì0X‹4ĞË°Ôş…xíŠ*6ğ£cœİ„ür‰Me™&¼G9˜"ÀÏÏ„^	'+#OsTArÎ¤½º³1Û3ĞÆì.]ÛÇ“”# ‹s‰Jè£A6F: l­d¹0¦]¾'w¯7òí¼.ÓÁ~F`vœíõXÉ¤î…úK|‰¥Ë"ÕÍâş}!¢%ÃÀ±Ù|ßGÆÏı•^…ÎCïŸÌ±‘PÖ5ÉÕÔXW»YY±›å>}ææ$sü¬¾¶ò=Ë;øğ1÷ìfebq»˜$|¾s¥o36ÇüÓsß—KÄÛù»²ËŠß¹ç¡+p4O—Ô/`-…¹'šVXËÀ	 FíÄf_¢Ïş¼$(ıGT£”ØÜWì¤ÛVÈŠ·¡@æ!ƒÅq3à¯J±+9N&7ÍjjDtÀÅÊà†ŸÛVĞ göátÙ`ìFäÍõT-œ'ÚpÏ7s"š€XX	¼{—À}¦¶â*şTÖXåfÕ Kwo‘0Ì|h'Ë#®ás.ú­[ù8ıëÚ¹¾"†À¿Y›â|œÉ½|¸1x7’‘•?K[/•z}U‰’œ!ærÉ…õÿ 44‘><@yß]æëâ&É’‘,€‡Az/Ö8¿‡e/8DŠé_å†Æ½;÷àí©ÍãHM¬Ñ†¶Pl¢]N2vHæÚ€jt#Ó|šÄ¢ø¨:RóŸ'dB²>]t¤(ªùÉ¿@Ñ?%[
zdÕƒ,·¨¡kgš»oOá))àŸ5„/ëvÕï]®Ç²„G}°qÑX,8[›DÛâª6d!†¶-3¦ÁƒcE"jŒÑ‡_J¹ õ.Ã:è¾lÜŸ¡£W‹LGµıê”Aªüù‹Bæ4KbLs¶4–Ì¸¢—‚ÕÅlâøÙ ¬e“Rß2:V—o‡µÊL­X|k‰Ğ/¾nÖ°sË¾g(ëe³ôh%N…én;féU—#¦Ÿ>ÓEÒïÌyD* Y,y}yvc2E4ÄkÛMõ§Èì·Úÿ²ˆU¹^æ=oI$\/´T¦KOHÎÛa?fütD-Õë€fö* äåÚùÁ†áîeñc£ëü ^v‹læIÈº¼&÷€h§²v4­H¥“8RlÌ(ÜlÊ}çN½@şˆ…Š‡“}nv;Gê[¶¤•âo§L!T}A’ìàˆÑ>ã&Éçö3İã¢Ì‹po:ä‘
3ì2)í£â,~
Üì¾$Ÿ’‚(äT õT2 {wI3ÔÁTpû†6Ç¢Içèìgeµivp=Í¿ZP|^[óØ¼_¥ˆ°ö?‚Å/È;É€½t#73<êVşÈG%„åÌüY}>Ş¯7v9.™Ñù°±ç.ôQÚ¬rNKÏ¤ÈvıæÈ¤2ğpm•–ÖæT;¢XÜì[hëÎà’»½WsoÉ‡Ş—v”}­*÷KcxéâÇ"#eÕ ,İ¡ƒ;ˆ†,ifÑ»Ó4¸8¯B¯JÓÈ£wë„6Ìxğ!d_ÀìÑUŒCÌây5¡x‹€½©7·é¹<Øhâ‡`OæT¦vU£€Q˜Ó$ÚŒ5¤N ÷!„İGáÇë›gíÎ[‹”·bR8g/usx­¾’Àß:Ï:_‚7ò’€Í}òÆ Ø±÷¯-Ê@Ñ®3ÙF;ÉlÃ"w—ÄíÎ—ß{Ù}àóòÜ~ÓH#máÔR×ª	œ‹¬$æ69àÌÇ¸ÖªğµwBjz©:Lë|1zbB†˜÷îÈdv(Kaf•Š(Zğ+†ß¼Â:h2æÙ.şŞó:7[×U€÷ğ\&÷-)G¸¤«¡önÎûÎ¨¹|Uñš5K±x¾7#fÃ8˜û#£"?ß×ğâ°¿é½ü{È¸Éá½‘=(bx!é÷
	Ø'|OoFYf¿äBmh+M‹£Û±ò×§Pu™R*„Ş0IßÂB‹ñ°»™2½^ÁHi<ù¹ÒJ€•İj0&²úün!2îÚ‘WÖFòÛ;¹˜F6…	w(¸;¦ãpN³8º,Î²Õ§	×I>íu¸Ô|y¨oEÖ®¬Y›X*]v†àBYşİ¿CÌçÄTz…4³ví¡èU‘=Îûây0£f]¥Ğ…ªÙ`=ƒ!ßì\&D"¶?CÓÁS²I¶¿‹lŞª’wŒöº¬±à[z0>1Şç8¶6®p	£$8m\â¿Œë'¼:#\éY„ï%oÌ¶_È-Jç/·¬s„³I®´zqãƒ†âŞç|‹UÍPQF1„RıûI„~µú…‰uI/ú9¿*µ=·ÕGÛÒƒôÍ$æ€æ
Í9°UCÚÀQ|”“Í£‹S¢.¬ñ×Û³r«ÃÙybì‰{bÿÕGîãÜ9ÈŠsó~+ò–pòÎZB„3@C51ª¯Æ¥T^µàÊ¹Ÿ¾oîXL%·Œ
ªZÜûKjÖv¿Ü™ÌK§Z¬nLE¶Ò™œçµ-|)vY»İ>ÍM/Ğm¹²×a8•Ó[İÔnä‘¤Ë@^@­«¿º~U1·èm½Ûœ…L™‰}•ªf«Æ3* çN]DêSÕb xèÃÚ©Ï=ñ¸$ÃéVŞæCèªu.<§ûz-ù^,õ?İ¬ÁÓ-}üGL]qBîiØ|à'yÔÙV#}Ÿ{ö†î ÷¨«w¿/èR!$<”Á-er*®f´ëÔ–UUxïdÎò491dÔàæ¢C¼Ş]‹k!VÔT ¬âŸº»‚XP`’ƒ&LX":Èå}V©K)®œêÓ™¥““„ÀYÓÌ$b<ãÀÑ3,1™Íoƒ}|°À›¶p/FÅ:»kELœH4[~fg%Lá<×ˆšñG\Î|•ó
áwÑùwİX… Ç—Fa¬‚Ç“Uõ4ÔÅ:ğ×ß#&óÑ¶­>V‹”vaE•	Î†pü]JHÅüòÏ¾Q£ü*qSp	y¬(Í¿»·d‰u®{¤h^eäæ3I÷T©Éàˆûª%Y¿
ho¸C:¨ÜÍ†’k†ô¡˜VøñeUæ#u¿ YŞp_•@•ÍO xvùrŞ3Ó·¹h¨ÈçêppJ¨Ùf3y‰‰ç³ŠÄr¾§Rx¹Z‰7ƒù ë ½–Ã³q»øÓ©-ylòßuNsÑ§«—“]8¸şF1^Ğ_ÄnØqcãùÎyÖÜD9İÍ™/¬ù²q2Ô²púk½#ø~W,·sO„-ª8„§{Ô$î%ƒ“H‹5yiÉÛ(şÃ¹½%Aıõ·âÎL÷D[ı’ìú7’Ÿ!J¦ƒ´üÇ8«jd¬¼nùb\µ—¸®€ LÔ‰ÿîñh,¹Zqş?<ı°˜mîÆsÇ(²µ.ÔİI@˜ù /€ÍşÏ;¬<M[•”†CÈÈ­Ky]8ô7"Ì‚õ÷ãú¥Ê>/²ÜÓGÏ¥ıš›áèØÎvÆ»ü•.RĞI–Â/”³Ù`i†¼ˆÑQÅíQK@›íôtB²Àq”A„Á€µé;Ñ#İf›„f¡şSi!ÕŞÓ_š†vrU}Cjx ¿‰äÏÖ°46ı ¬9¾)E¹Ëtğ}
}v’/XÊ«ÙSªİTL»û‹ÍÑŸ8æú"É{“Ù5~Õhc)­ÉĞÈp]¢ã€JÜÀ¼-Jğ‰®A¼Ü†J¦\›øÈ ğ¥ß1%Ï6	@gd¸ƒ‚Å”yĞö^Ô=	˜!Ïª×ÒÔr®ìUöˆdPmé6 ñ<h‹)?jIéâ|“}ŸÓB©E…^ëz#`ÚÓc»èë%êî™«š9–HôÀìÿË][ïËî #ÙÌalÅŠ…Ê9IÜ8:q+ ÑœƒŒ‘ÕqÒù/ş’o^ƒÔ˜Òˆ©Ÿ»Ä+ò»»ĞG‹…£‘ß}xt.sÄÍ–âb¸Õ¤Vùî¨);ëp‰ˆhvı‚×|÷B5‰¼Âãê¤…_RÈobÌ›óåxW‰ÅŸß}{ÿ

Ş¼ıFHÿâ8!Ğ“Sow^6£ÔybpA2#97¿a^Z¦ÿ¬„ßöôûil5˜@”émåBtƒ„£Ø³@cÂœZ¡Ìvp¸¾µ„C‘"ëa©øËV4[®Au…Èdg˜àç„lCÒ3ª4õşÒS¬„XæÙ†Ã7ñåù®AF%æ­Û„z©YLN¢ãr¢ù8Pÿ_«F4'Dgå”Ğ,gŞƒW­:ÆŸñH7sæ'`=ºÆ¥ùFª{ÑÏl_±*¬Ğ°Á¿ÛèOè\h‘Â¢°¥l>øÏ$‚ ×ŠŒ+5Ş9
Rƒ°¸¶o€òø2İ.˜nİ½¨^Úò=;;İ«/avš-ó¿Ëïç‹‰ß*7õ\¨
j%øËÜx´MfãñÌµñUZûpO…Xi°åÿ©ç'H>$ ìŒ,˜3'÷p#¹Î5Y•'Âë6©>ü(¿³,­Qw9}S$‡éÙ¯Ù…:AÌëÓ¨¸ÕØÎÁo{.Yÿ¦À#yòêƒcï8yòÏYàÏh,à~î)dØµZò–aì7äiI®•Â†ıù½*1†
ğ§{vrÙLf–Â¼„x¬µ 1×$õŸè_ŞôwW­Bş«Õg‡ÚçqøEÁÖÏP5i—Ïf¯(xöÁ\<8u²)96®w±J¾'ØT$./t•öo÷$§­Z8ì™»ŞÑâL½Ãæ‚Æâ¡ğÙò¾ç,Ãò1·²ìİDñ)÷qâb•ÉbHpVM¾ô,ª‹ıÏë‡ä²Ÿ­Eà?Õî¼4ví ]Ö­%ûÇçÀ\ÖT²¾‘™›O†4
ÉxÉ­âQÕ0ÉNs²„nS`«Íğğ!µùAXèl$ô/U,Ù…CÉpïÕqw+S%öæÅs£Ô‡q!;¼®=
nnépcIáÖ½ã ¥§«@0/¸İã^¡CŒ†Óß£Éû•½½D7]†xbÉu-lêZ_	ıQ»IµøiYhØæZêuÍÏ l<?kˆAEµ²üëùènJ—ŠM¿9g“ıÊ
:…gp)rÖG~~*›°µZb¶CÓ*Ã‹Ã´ìÃG!uƒ“ïf,)¹‹‚_ÙA£wë|ò‰^yİ±¢FHûõö=aÄsøµw›]@ÌT-n?êØ‚KZÈ)ÓÌû/-¦pŒ¸[jN‰Ša8åù¤#:B%Aÿ‚ÓÛ¯PæS=-NMÿ*­Cü‡iÍùP²++%g9}½Re.I¥ZíÍ›­£¡œ¹ó–LSÔ\ˆnØ†±{ÂRãE0ŠAÔí|ÌövnEêÑÁÿ%xN<gfï§®5WŸ»…ømWÕ=úµ&U±£zkKG=úŞp.³c*ñ£4şBBİïÚPğ’Ñ¢§FpjÈ:@ŸTö	(h6Ç“¨œËcÕ\çªÆN—õ|,ià'.%¤‹¾d#ô.ªSg.‚D²bÁ ‚Zzµ®”BfD~Ï£j±á>6‚&\›#m§WÿõSÃ²H–æ|/¸şhÿq«É»>WQ@Nˆÿ2Î(äe)éïş…÷7="`M3—ŞR‰IæÁ›]ésÒ3¦7º`›C5Ï6¸‰_i#™·(“½’;ÑoÆçc\GÊ(õÑ%¢Ë<T@`4Cş£ó À|¯¹÷?‘ÓI’ÿD²Î;˜í2‡Öşd¤Ï‹"úI°ÖÇµÖ¡ç·õy,Ş¡jÑ;ãz¼í{
†SèVİö–õì$ƒfØïÖ«p§¾¡ˆ’ª{jBùšO5óÔƒª¼Qü³7Ÿä¨à>yh?µÎmwÌëä3_ÏfB´Ÿ²£OéõØˆ^7°9½u¯«Ì¤uhº9)+"î¯5ìƒÛSÃ¾Á“Oi›Æa÷ˆ„p¼TCgÍÜ r Ö
Ê	1ÙÓtOó6ÉKdáí«ô‚V¸ŸošQñ§X+Ês»âJÌ¡®Ø¨^pºŠ]b4GÎE™»hDŸ|›×ùBAÙa·~wO5oèå5š"”'¶	z¨w×c‚ÊÛ.ìCåPÓ}kÉdpgtGQİÔşs%§¾¶`«ÌÏó×€YªÙXB×½c=T?úìüñ 'Ûí=eaºoÁû ¬Ÿ¾—F9ŠİäÌ¢ ëTùÓ?ÃªûÌÂ2¢ïşããüÙØ.)µÅ#˜¼´Ë±"š8áGÚWXfˆiëãÛ7Ö†™*åVÖïÈb;M™È$Z2Nòµê¯:7±Î[ã©“&Ñù‚Jº>(fw^|{_êËñ\Ê?ò5¨›Qÿ¥ä&^J¶ëêU‘<‰ÚgèLw S¥í²j‹°ßt8iÄ“ïÏªËYœÿK)6KsÑ¾ØEß\Ã3¿SŒ#X†à¨±çı !Û“QÎrÄtéNwp~´z¶ÿM±r@*”&*‘uÍÂ-İÓBÓ¡h‚’3³É.I?¼PVĞÖòjĞaQŸœô-‡ü,»ñ°qD*‚ ÆïíØQˆ¶DøÏ ğW•Ï*pCNÁn°€o²ô—÷£ŞËÿEØQ½w¶G~QüÓŒE;gP(½W¦wc¸µá%®©¤=©«rà»Y9ÖsvhƒŞ¹ı½†ä6‡_ ƒ’-ÊUÍ‰¦Åà,‘%!ñêŒÿ£~Ö:™a2Iú^-Ùø•¢¥ø«hÚBsâ*Éz‰e¢ş:dËÿèç´<æÆİp×ñ~»40à¼Cüùo¿
:^ÑY£6Æ$uõÊÍÉÑY¦ëêD•½2Á¯¯Ïû5£š—A¾¯÷\G€N¯ e¾Á€ ô»„ë0*‚k¾ĞA°¨3a°Ê($iònW·_ın<t^2¿Õù>}ªCÉÀ)¸÷U6´³mS;+åzd1lw³V<Ñ”ãôµd—ç?½ÿ+º²šMØÕ@ı×ûñhYŸO[ãÌNõê_°äZäYlæQó ¨	Ie‚¦%¸ÜÀÏÆ8¢mÕLšFoí6‡_Í8IÅZ	"'P=üp`öÎ[©§&‡ínÓ@#‹µ|Q8vãI
¯Ê£e×gãÓQÂ„ÛMÍoÅù´Ä$X -û6å´È¼pˆ5Í§§ÿ(¦à+›†'‘¹5c›Nå÷ÕX>f¯¢C~‰~±•Lüˆõ)ëoŸ6:ì[ÑB×Ü¬ëAE»-	SB±£Í_“F0‚Ö”D§‰V ·›‹öı`ªe&[‡|Eùãgä/NUâ¦+¼e§İ÷Ø‹~!3ñÍü¼*Š{§,ËæF0’A„½å$lC#ŞO¸-"³ƒızãÚ–£È03¿ŠËó<ùp=”/ÏÌ©ıT&!ÑˆXè,¨w}™ß)ùß-7DÉš6Á#âœ§x2³÷bŠÖß#~‰æpD#ÓµÄs|ü<–÷è²ˆ€šë¥û`-r!L5³]ás@X¬_ØÎ:ÏnoMÂÕFÆ™ÿ@ {å„w¨HËÍ÷x'¯/Ëéèìx¤C×ÎüüyFÓì¸ÿ<C¸Œ[ë€ÖÉÚJ4ûYïÍsÚa|]é·”i¦uÌ›Z6!î„µ-ÑÆßs»qç—p‹MûU¹”ŒŠ*â†zë326ó´E/Ã£µ•ÊĞÀ2ªS7uÌÕL=G{£„=~ÒhéüåÀqR) ™°È³êME½áQé/kº2*rqP¿×sS‡öŸKètïº‡³i¨¸EòT¼RÌ­ÅKã
wÈ(‡]fƒÇ}óSû3MbÃ¼ŞÉ‚î¼ùÖ«@¬	ş”u¶R8Qß-Í´ˆ³{üœÈE™¿^°°ü\£Àèt½—] xÙÉB]VÖ ã¾,è}ƒÉK«°Ù|Ë­Pss 77P7]7,è>Ñ±ß’—y·>QXéØø‡úå‹i‚ÃI:·ÉA\kpÒ2D»äù®œ·'#G`…F¸o¹'ioÒup>|ÒiØíi'5”º=%FàqZñÌi@6Ô~•vpB;³Å¦ïp;èş\? q7ê#R]W‰`!c©C¦¤2ŠŸ—+Å7mÂ‡ÌŞ’ÆÌşnÿöƒµÄ¿K$^æ#ÃØa¦·hş+—|3æ÷ë3ÛÈİéÆ°ğÄ‰ ö6Äİ²ÆdİèÄ=–Hîd>ÎèÆzĞğp÷šsÿ—$ÿòˆÖT¯º|oÓQü9/àß]{ñÃÏ¬òFpŒòkƒDäÅÚ?˜ÓUnDl¤%éÅşEo’tğk¤0w„Df9<‚Š“Ê‡Ï¯Ug"Œm¦¬QAï¾,A†Äôk¦­CÎn²QæªaØ»·;Mø˜X{Ôà6ü±rËŸeªÕ-åàUÂD0ù8ÖÇ:)"Jüú>dİa¾Ù]e`­Š{ewÙræ—©šT‡”PêúZÇ¹)ıœ^Ş·ª5i96ßÅ®ØM/ú?åúıä'bI³·QÃİ~ŞF ãÎp÷B ,˜÷ÆüÒ(•bÑ÷ŸiWZ‘Æu˜9,s¤yBi}Å„l3¸DMØ˜ÆÎÓïúú?xud¿Ëœ™ükY«}³;.Ò°yVK/•æŒV%¡C¶¬5¦É„ã1ãõµôë
LhÀ£Ï7eÏrD#&¸ “Šê–ô5ÙGHRfÂÁ11t)ÊM{§óH›˜F¿ª³‚WË˜aê¾É¹Ö‘Ê5&Ân@z[¯jÎQäÄÈ`f_ù4Šƒ¹nĞŸÓıŠœ÷×™ïrğÜ:2S#ó ÒŸZ¦ÁşvCSìƒ9½ŸØÄ1¿N|¹K·˜œi@§¥B¯ô:§ÏåZdûˆÄ{õ{O“]¯Ne”!õS>Qyrí«š¢ôÕZf…îÎöà^µ{Ÿã"ŞJbG:†<~¾;7¼±"œ¥dM;jĞ›ÌÀKÉâmèÿšï:š,¹‰IKaŞŸsşU¦'ŞCâŸZáé»é#×§ì}‹–cê´™ËMhÑŠ Ãà—ÉOw–^Ş¼sG•†2Uş˜ÉhßRÉn˜+ñŠ¦”ü	Ô¡*Ù@"Üƒ ÙÕ§„Ì.‚\ñ'·´‚bã5^°7ÕRª®PÊ¹Z8ƒå»ÛMïÜ€o“€`$±ÙÊÏhø¸»E9#¹ÅõØ\q§î4¹l5U¹ ­<Êx o!Ï(g]Uô¨Ğï xëÍÅ¥2h• îr“Å@±KY(¬-ìKÖ”pÌ5õúCÊı;JÚ5ÅS<p=¤ª0°6˜¬CÔ/‘˜¾ÁxÃÜãUl† „ÃRÛ]ã¿åš>ñk«­„Ç“Óê¢Œª‘V}™ ì¨êª&ºJ.{6›ùó[Ç]5`ÏîpÁİOÄQj“m¥ ×N}M=ø‚ÎÃÜHè?Î«EŠÎ{s˜xCÉMªøzÅ4ÀSù<SÃ~4ädmF	·×¾#î(A9…NgmRñ—¥Ÿ"W'¢Å>>Áú1%CKºS—øÿbüm–ıX“­ˆÎ@óô·Ìp.k²œçgEœŸ/ÍÇ3Á¬U(›[möù¶ÌxÛhG»ëãğÄcƒ>ËØepŒİ ˆC…üô¬ä…¨0úÕXı< ùÇ¹/Djù§W¡µAtÜ»V“×Ì4†Íß8Ğ1ÏÇhÉÖë~ªë`™>ø=[3äÜÜ–¯)]g™Oİ”.±=Ş¨¼'¢ôÔZËêHElx$#.5Zº `İ„@ñpää	õÚ—#Vº*‰
Ôr‹¡ÍµRŞn¯Ø¹§_ŠŠ"(\e/)ÑÀíâ%	,wü:uê»åa(QW‘óÃô0šAê¨¼á‰˜Yÿ„ÇS™STxÿŸf.öxæˆØÙgüÛ¶é”Ô>ô“ß~ˆÌÑCäL}€¼´©½Õ×Yûs|…‘(PüÏá nqë/¿:¾„ß`ÑCÍÉÇ:Â(§·2²f*|vÄ8…\R:LåA×şQËU¸s	QŸ'wqy²éŞÛe¥øÏc©È;àñ.N³Âç[ÿ<e¯;y='¨ÅóÑ‚)Hİ‚`†æ}åà*}‰Jl‹A=\™õnsºbB}ô —S’ä§-<CÉÛ†!3§ Er;Ô_¼ş‡‡wl·=ô»ÚŞ|ÌD³n½äÓšş£G&Iœ‘±ºğR¬Š'UÊÃCs.!î! !T™µ-ÄÕòNıx8[[|{á"ed€-—eñßù‚;aÜ\&š«ÒXˆÄCK„W 4ñ’ˆ.çÆÿÈ¢Ÿ(l°”ÑZÁL„=¿jÎ*57¬PÇaeE	 i–ˆ:mZ[[XÁ9r‡ÁzSáËd7ê×L†j‡‘«iP3u½£%J2Ù1Mıh÷¤õÜ+æi†¦€Z,è¡qc(æŠˆÑj#å¸h€yùÚChJÆqÒ—³‘Œ¢;×#_çK
ˆÏ²€í­ ö1pWâİöAû¨tŸJÇˆÎ™–®ÁYå@õ^X™›zaÃ©×Xˆ˜UÄ„øèœ òéw Ä9.Ië,’.*ŞMCûúgÎôub%œ¢DÔ¼¿Aê¬7÷’|…º¨°;­…í 
4vÂÚZCõ‹6†¤é2µµSO›g"'+öşÑÇ¾#şdlüò)±ÔÉ%Ì¤¥~î-“æTŞù75U[šü³\s	ÔŸËÍğg_'`EìR7;U5˜hû
P?Â‚¤‡Àü˜O–‘¯Ösfm¨â~™ÚU«ÙGÁPò!‘ÀîvÎÓ5µòucñ—ŒÔÀ´ªø“]fD÷ŒÔ^I •£t@e=ğùÓRúM<Ã†y”ôv'~Üm?NÙû4 ,#TÄ G*‚ùÀ£]ìÓóÑÊ)pÛ`İx.’A¦Ó×C`5BÂœç‘¿Í,U4×}fß™í&Æ®a¡LN:Ø9ö¸ìª±Fç„íˆOğÒ“Ñ‡Òn‚².2}Rz}Óıt8DT>½Wµ¼k*œ-lÛ4MîŠ‰ÜY@óL˜ÃHQj†Ïco$¨¹R†vIYvÚìÍ‚*Ù&¿â
ÙŸI¸†‰/İ_Á ¢*!¦z…ÊjË¨6ZÌÕğ­Íø«˜å‚7ù¿®u½°´÷L&ˆíâ?)£kTµwDÓô¬¨v#/¼ì*¸ßĞ®_åı»-]Æi¸üÂµ«{GÜãTm=ÿKMÑŞÍéŞUE„	}ft˜ }MqÉ¸fş¥l‰vìƒ¦[©Áƒ:FËÓİ&Å!SÛ%%§QSvÜé7vg<?-$­îy“˜@l€Gz§Âê‡3Æ\ò.[öò¾mÅ2³ÅàY`Èª|W[Âz–‹égT[]í8¨È	Ü¹Æ›<dÂ¬ˆ§ JQ[‹í«ÒlôgoªÉµ{|ò¦MÊ^´ãÂuÜx0¬>AèÖP©©tˆeyCÊSü3‘¨‚vxgŠ(4²5çl£°!µFÆ/¤AC<Á™8+owÇnîòóI¸RU÷j²QñÆ(½®Fåç_=D
¡jÁ¶ª1f·Ù{roÄ¯A‹dæÂJÒªÔïÖ69!‰ï?ÓÍŒHÍN~ÊõÑòZNå*ù'·+²EÅ«	
ªÌ%+µhóI¾Ukhšå’XÔ?]ıÎíáY2 ñ}bµ‡-æ¶Nÿ•ÔR0_‰5FuâraÖ>Şñ ·[s	İ0'áoa¡Ÿ@Q¢?|”ÎğH‡:%­)HI“+âÈšzF(œÃn¡÷h ƒLæ
¦RC¼œK`a”[@£ÉXj5#ÛóÒÚá>mËãf¶-/»¬ÚßR?ø@¤?=-ĞîÛ¬PA+FÂZ¬Ï‡Ò¡«âåª{±§'!‡êK˜h™lËè¥F´8zì²øŠöe!«Şd[¨¸)¹°Bb-â§âO°Üà Bñ"ı=\Æ§¬B^ğßê-¶¸·ğé::`ûÿrØJãë(ël1#Û†Hû‰b¤Ê¶²¦uYî5ö’€ƒñéüîÓzÈŸ-ÕØ€°½\*P:±\jOŞ%I¿–ÕSÊçà‘Ê\0ßŒÃ¢@)ÿÎ3;€X„HÚ·ç3F<Ğb†sÖbĞÍ28ÕÄ<_]ÆŒ¬Ïµ¢3Qz
Y6Œ®\Ã–lhşÊ†ÒKÆXoÊˆØ;DJ ¨f Î<çIÑŠ*1ÃÏ;’äy!Ğ©«ÃğgRX‚|p™öäMÚÒRš€¦‹¶®Pû®`9rÒjŞ£²«DO\:~˜7²tÓ<w¨ÌqF®-ËœÑõ‹•.˜îì¨[*Tg¹ïÊ©;ÿ]x/T÷çl«ºXÈÕ¬³|Ó“¸Â×7Ñûä‡]×ƒú7f€É¸4oEáYèc]æœtƒHòò) ·SŒd2”Å±Y¸/¾eÏJYQV)÷`åmìF¦¿ÒÕÅÈkJBó³Îñ¶Ÿs	Ãàs\\¾4Ã;X¾vKô$$6jc¨o£.{
‡¤iÈÛM]~ÛøT"Ö Jà8jÈüæ{µ\#3•hØJú5ïrÛJ*xzæk Péi±“²H¬aZÕh°Ÿİæaìüùâç¹=ÿe9|ç.âüBX°’)juEf.°‚{–{…†YQÕÏ¹¾ŒØS.² i9ÿDâe ¹)Y=«y$U3$üæÈÎÔ	 ñ@¥èmálœ~<%d¥Ş‰æ •*Ú€•2å#Nò"lëf;Ü’òş†F€–àÄƒpR±b—üzf"8€ên±c¡³Âh+qãàÉ­5Æ0’g7êŸ]r¶4Q‘Šƒ^‰øäŞøm€ôz2×õzzŸı
Iù3d[w¹ 
ëÙ½µÈA.™aBšõá¾]­rØW½ã}¼4—Î~5T[N ‡zíŞA*õKàP˜6ì(írßÆŞí e'«R‹€0ò.öÈ¿¥©¾|I3<™kT`–ù‰›Mí2êc‡şg3£
©hŠq¸2 æVŒ½±Ô5¹ß†¢(ü.`‡!Á¨†ÉÑ¸:öP­!ŒŒ9æÀêÕHà§Ê_^¶4e
=ÇVë'$ŸÏø­ÿqÇõì> kİìÆKgªjáo©9Z('å@©6˜"4›ÚXU1
«…_R}ÉZ0 óÑt§Ãf»ÜQûÅ¸UPËñT‚ˆ:ìÚivé=ù’ª›!ÇQppê)î—ÓägïŠ¨“lq7vúæ5Ò¸“ÔviÛ‰^{Ové»vº–èG=	C_¹äÜ2¶÷Á¼P¾™;Ùps@¦7ß²ºfÀP6%¼¹~$£€Ú><±f{Q^lËm:œi x«¥IV>>l%3¼TIG4_æÿøš
|ë	t*º;x+ú(—òUZGDr5ÏÏ"ö&‹å?·‚S!¸ç…èU&9d¢wÃw`ÿ·r|˜„®
1Lº1¶–#ÿšÃÅP*M·¢ıèRÛùá¸ì/ûuƒ±8Õ°A%™x¥¤G˜\ö? Mp	³“¥qöˆ¾È#¢{¯ÏLLóäæÉRIX•}~nV-ÿBOŒu¶À¹S‹	K§i‹)iÃÃ.)mæ¤ˆ"ÌeTæ‡ªË •µ×C‡ã9GohsHa¿Må‚¥IŠìëêÃ¸>¿|¹èæıçyzÛ‘ZÈnxÀ£ÅŸ“j°Åw1ÿJä¾ Ôq'fª´Œ½±~M_BÛ„i;7nIyJ_ƒº];¾ŸŒÍùüµ&7Fùo–,¾¤Ó ğ‘A¸á¼aÁA	Ôß|¯`ñ
µ›£~ê¼ÉßjâéŞ?¹.
Î?Nm¾r^)SâÑşåÓ¡ºhÇsûˆşÜş˜tÓå¾$5lXpi5l·C§¢I{ùÂkÁÃ!|álÆÀ\(&txó’`¿ïDÚ Ø?ŸVâQ
òVY ØˆƒñZ£Éå‰xtƒ­–ót§‚¢¤Àè^
Ïw¬®!ÎúùzùóOpš>må8¶(0°å¼æº:=BÃ¶ ªá§ş?$³â²PÆ&É˜[’'çHU@«é5’Î;rú¥,»Hp d'¢õ•ÕòËèRsFœƒ2Å¿êYÖD¼GŞ†C´F›èÂ‰¾ºu¼œƒ­Á<5Ó›VQ„Ù‚ö7ZLMIÖŒ¡›³›ê5^‰VRLlj‹#o7—É$MUSüT¿äK©…Ş±}ì Ø]J^’’¶,¦1‚¥ÖOÀ2œ-Asa‡!`Ê‚éXy¼°vVƒåàíçÆ.ˆ¦,’ä¾İ¶[Œô¾ÎO¹Ì´/`¸™Ş3Q’]±:Æ.àˆüh±Kn~NúR¯‹¡¶#²‹éš«.Å}Æk˜ÿÀnî<9ÀÇ¡%†zhË-šò KxĞŠµ€&ê…ı$|É‰Ã²ß2qZ›=óTì[h“·¥¤Æìx°óµbÙÎ$½îIó-•(B¯·äÿˆ£
£ÿ/áí‹VÈq‚ñ7`g3uÃ®¨ÌNskúñ<ëC¬iìùÓç¨ı±ş°õ×á'»ö€Z…šik±~¨^tÓ¦qKBÆ‚Zù%bÎsŞ‡¥áX‚ÕèaòYoDLY¢;§÷Â_GÏ?nÈZ¿Å%‡ğqn¯ö`0I]İ#é“Fx·;©8–Írq‡6ê,îî¢—µW‚ùØyÉd6ğ÷/:HÆR©Ç×!F71mJÜ¨
^9~i„~è¦7œc¥NÁ¢fÜš?Ü©ÑTT×M§övÄ­Aàİù|ªçosçÕ{b¥åÀ7È†)Ó£&#îAÕG*Ìßæó`B*{¡ê”}œU˜5-c¥3s
è19.ìSğ9`¤%*ÑÁò<L×çË› ¸Z ›#~s¤\y	}‡5™ü*¥s·}¢+è±áà/šrÈÎ~'šëd)ò°.
TFjw	d›şlnUËÏ¤+Í€	ïÙ'v~¥§Tüİ,if±Ù,aÕ&ÕÂJøHf¯Œ/ à˜U.¾Àİ@è/àp½È’âYäš×£¥ºfáÁ9†î26ˆÍ±¥6É2À¡Röè‡ÍyiRÎŠõ‚f]ã`Öİ€•~×8ÖÅ‘¾r2³ObÉ%·¾»Ğ›#M-¥ĞÌú`'ä‰Ì¨92”áÆE¿³a»­%ÑşÛ¶ëÜ‡ëòŠiŸÄ¢»•Ön·p€ó=tn0wuÊ/bÑß‚aHòbË3ÔÌ&h¿Ë;Û$‰ô˜[{­ıhİ§ôñy¡¬Ôá9óÓÌ_§£Å4XYú½[Zp]´«ågZ!aãWo´ÔR’Í+vg¤5ı¢ø`a»§=·@ıZË2ìmêN¿Ú—êşÁ,jˆ§mlSÔË-ò$3u€iaWØDŸ©ši8IÁ`!ù–›WVP Ÿ Mn 	Ş¥TJ‰­¾×x¯³í E"dÒtlÿÙœÜ«õ/+y€~£ºG¥ÆáïmÙF!Šˆ†xØ”r®QÎ[¥…å`Ş^š-Æ1c“L¼ÆL#'™¤Àx$ƒ9OnTiİ `ã9Ú^í1¹ÂªM‡®Ü±^÷zP$¸« U*Tkx(;FÄ)ÈÇ¿Ë8…Œ ìãÏ5;VÖß±x?H	ìºb¸”‹€ƒú²öõA—œùµ“ã—‹ ²vÚÒ*w"Aañ´<œ˜¿âäéTûîé]çºnäõmg9}ïvOù%ÙoğyÀÑı <v¤VFôb­Õ‹@‘9ÁåEĞ7(¼îÊ‹óíœ\ÉC%Ç!w}Ô…'Öì} ¥1¾%ÔÅ\F¤]n¿M/iæ4µü^±®yA9xÆÃ^©²U#·'­úvCğ-›TàÅ¥òÛÑÀêR]@Âäy$¸¶×$¦ız/â'†©Éá» `Öü‡äõ/
ÜÖbc^BI–1søÊ¤·ÂÓ­ò[Ø)cñùğÅ•aqÏÚT;+pëßë¤¨j>Ú‰F9$Í·¶ëê¾„™‘A¤MÕhöö«è¸pÆpèLìI)¢¥_LzzH‹jã9ÓŞÁ:7…Û±÷ü*¢èôÊ©ÿı» sMùW'`éUl3³´·!rÛxà0úZSŠÃ MÜÛ0xL
ûÁFİZ8z6-G`)«† (/Y5‹şîjõ¦°pTÅh|õï€9„»‡}lj‡)®¥á%®*N}Õ«t+í®QJŸ|ÈŸ1‡úú8•=ˆñ‘ÆEŞo’<×+s·¯õ=K#ÕiÍ©õwÈãsÅk_%èâyÉ”(@â—^ÌÅˆOŠ)›ÇEXÿ‰Ê¡@R=
Äãıô=eíµvÛÓ1sŞÇÓp0ûëá´~Yí~sƒˆÙQu¼ôğ£ÇtÊ•—Ç0Ifá]³i¿çc#ÓaÓ[	™Xìì·ÉeàkV¾&ìt©2¾rï„`o ÿÛq²ÚôÛ+æmû‚Şó/àw$Ù^=±AÓ}tl•H:ı#ÜÀLß\î†ÈZVvÛ/TV¶ ÿ¤ÅH€*°Î/ÿd¶VöãœÌxBÜVóÀ‘«şNBpE½½Q5ÎÍÂlÊô½­¥Ÿc¿A‰–ïòj˜s—îYâB"ßñŠû[9ÏúŞã     wúF[ª)£& µ¿€ÀÖ÷Ò±Ägû    YZ