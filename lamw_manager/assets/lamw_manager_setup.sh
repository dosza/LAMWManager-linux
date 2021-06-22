#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2960554833"
MD5="38aaa78501ab3f41c826cf0ad01d0312"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23016"
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
	echo Date of packaging: Tue Jun 22 19:51:20 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿY¥] ¼}•À1Dd]‡Á›PætİDñr	%P%
 Ş¶UnG_ÕqÇ–5&¡\¬tMäÛŸ Ç+†É3\•« Q®ÍŸ²«4ª—£Ã¾¹ÑšXå›ËKüL®ÊÛ Bñ„‡lSåæb@ÏyU”¡||¹!¤%òÓ¹{}ó4Ë?°8ØÂA•ÏäëS‰ŞÆtšŞÊc@W2åÎjdË+‹`™Š0%·6²9f	ûg8h*µy 8ÙY‡]5İühŠSBnŒÃAº}mØœu«ó:Íà<iX­$ËüŒÓíh‚1é}Q³O»'Ç?Ù=­åFŠ#b­Çœğ…>š=ÎÇé:¯6(%:ÂyDótœOR `¸_‡Wâ(*×‘ìU4İİĞQH­ècœè^Xb\A-P­Ş´[áŒUBÉsY+ÇÑkÎìˆp3y¹8ñQ¶§ºq«i‚¼Ln;b½·hÍs¡ŒY˜A·“´/.éBhı2Ó ÚKÇµôuW½±ÇÀø/ "áõƒ>ñ?'Yf°J‰á§ÏÇH~Êy$t½XŒÒ„®o)ŠBy§rVÉÿÊ`oS>“OØ¢ÀõõÚš­¹J±A°ëcAö©à"6ŞÖµcµ¤4÷_;öÁ“‰­µ$úñ¹íÑ?‹FE…h,iRÛÈr*mUøäW&ªxH24á³WªxUÙ<¢YÙ­v™Zjc«ËÙôÌ¾˜~½‹ıÃFùš 5	1fÑº)•J‹¶ß”?¾®ÑxøĞ4üq¶×\f}&"†4Ö´¢ş¨ñµÌ“Á²3$]Î®ƒ†~Ôğú[iQUúÅË‰#‹J±–ß>|¾ Ìé¹mÇU©(ªw«úwˆæ|V¦OZJÀ°ëØ¦D{8È¹‡®)ÍÍ†e®³Ëíê^3WÜeÚ-•Gî9€M1£³9L á¾m–šOC@õsÙÅÃzábã"ˆ±´ÿ!›ä•EÌ˜?™ÌÆft+"C1È…{+mö?üğjàĞ¹“¹¢9Ï8E½·32jI§`3ÛØ6{BÛÕbÈ„”1¤’ŸNò\x»è}/Ç9°u)é,&àÅ÷œ«p°'ã~Àü=êß7H=ÿd€IGa½Õ°ÜèÄl›D`S÷E;î)ØpT¦×4H½U\šÚiyş[q:Ç˜èİôai—Ô-Óğæ…6JÁä„áîÕÄ°×¯]é"Øôàî|”€Û`ÁşNmOWYA¯›<)ç¼O/¯qÀ‡u ÂˆŞÌÿ­ƒpJı¿²±Ø0ã=!ÊSÓ!6µâH¯Úú zúeeô ­òrB=¦¿í™HÂ’¯Fn«øP‡Î“IµÖúœ³âáIé#wNqbà§l(ÛG2:¤ \À™PŸFêVì¥‡Gbˆë:;®(\uüàFõ7ºÀãCı‚ÈéSdšAÏ¤0¬-WSÏÉ3‡ÂØYÃA|ôø}"ºŠ Î¤`:Áğ¯Ë&Àr8¦;Oq¸>¯9¼-A{õbouj.`ı&u7'’QWsäÜÄ vÏH®ìİîœÈ èÊê0*	ÏZ²ûç—¨\Â„¦ÕÖèj=ú\¯FMTò€ «Ë¶³ï·Ò_!‹8Pt‰,Ï<fÆù§nP]`±£Mª²pœ“ÌO«}œ‘ıot`Wş¬º&S¥(g„î5æ±ÆÆ½ê±“ˆ&O‘MuÍÕÚ±Ú3'U½¹(Oš†¦-ô˜&—¹Íâ»jú¦Ğ ‰G‹“HZ†T‘oGæã‡)É2 u¾¸ê–òj3ş†kÒ#Y‹t‘¼î=÷aÚPW5Ë	¼	Jåƒ€‡˜Kı^¥s´o½&Ó²Ü»KßütÿÖNq\ÜÈ¶Ï-dQ¢
óĞƒ(Cbcô7jøS\ïxó5(§+n6ï,†òq³u^h,ÀÆHdYñï`}¸1‹¤nwo	ÄÓœ@¯¿lLÒÊ¦=/@±Â˜‹:=Ó³Ğe†>\Î’§›{ï
#X¹=ê(ø€L”™MŸ\Jhg«9$™Ñ[¢“ş€Äªİx.×Ş~.CvU!e”÷Åiÿºr‰¢K¯ûUÄ^w ÿJ0ïHgXK|ˆBbEvjva–ªœ0İ¬e7¯‘HÕî“¤'ÅujËH‡ÛAšÏ`mwÅ”'¼··âQôßÓèÈëm	› Ş4:bUËÑL¶Ñ’@ôjf›×xËášä’Ï!ÍÔ0Z4¿7ú5l§…SB˜%?>¹ğêS•q!eÆLÛ`™û àÓ™Æa¿"ëE+a‰L¸)ú~%qŒk´mÑ…£™óácX¿r'‘¿@~	hx1£E´iSİò¼EŞëÂ&Ş¢½^©yÆ©‰*öÕ20úmÓJ¸Ÿ˜ùÉ5
ch›«Ô~7aê›]é<qÀÑQOyˆÁ‡–ş§^¥?6ªY4ä²á9ü9·ŞF=÷¸¬Øa`.Æk=qlèºä‹úÌëMp0;CÂú°šÌš¿ÈŒ® Î2bâî2ç{“Ní2j^ŠH³<}|½+E]XÔˆóæO}ÏáÔ…YÛã35Ş‚ø)ğRVï„fÊ5Ü«v	¼î#}ÓjTªaÿúô°tåÊwµ©)7”|mîvc5@ÍøŠ®£Ülİ,£Aİ6Ó¡ÉI½Üç
.'Ü¾(åèíA‡ŞTm>ØdÄß|54mc»dJ0s3]ƒd³åFÕsTtm–zìEh/¡L v]-ëxø—bãw/oLÎÔPä®WÆÉû`Ÿ?¦Õ4ä:y…ˆ”E¢!³PòÊˆ„>»´ŠTŞİ·]Å0uNİ7ğ/<ó 2IMhi”®˜IËÂAR¸
h|xİ”xù5jÚ+mYBö¶W¿ytèie}‰î:+}“1*†ÿñ³#«Ä‹	ÍZÉÈêO€ÎOádª1‹*³€JS}/_•ãMá­·ú ñÖKõA¢—u©w-x Ê<î66á>«æ‹lY_à=ürù¨uC¶”7H®E-¯\ëŸ|ø³	väyüiQ
ÛbÁÃ&-½Ã†*ñ°5,ÿk!²gúr+Z}?tç ºå‰'u”†¯)‡Ğ6¦	`»®ÜÀş“
ÌU—‘>a§[ÎN:ÛûQ\Ä¸ĞÃL ~°¢Ò¢#k$H@•šWZrÑ×†X©å£õµoë=·®µì‹§PÓ{
²ú:Âô9ÅåM 9sh)ÊÊÿ×^0Q˜åQ›BQ«ïXú,šúï[ ´PşğDY ¾b½öbp¼PÉìú{m^Z é;¾Ñ \„VCX)…€â'7È¡‰ß¡·Ègù›ùónË`{èÄ'y¸	§÷åIÙÜ~¨Åád ¦¹Uë6‰—¾å§aÂ[QPÿä©;·†¿N‰š_|k
ÿ²®Â*ãı|£ÂPt³X¿$%@rÚõóášëøDl ¤;ØŞ”¸¾Dÿ@EÑ!(ÃoşL´¨1•Öf±eŒ9¿3ùNI›AÑŒƒ;oÕ9&‹üVòŞæ_„!$-%*õœ—Ö¥ãÏ2ò Êo\ô½½ÿ)û¾·6ißEL]¥š^ú¦rOÈ6c8áIø[Ù{¬^ğ7ÁVéçngàcŠ¯)R.CüäİÏ>nL—ÿy× €îó‡Fò™4gõ÷S*Môa½5ê¬cŸ@×9õxš‹ôsV£øŠÔ]âP·wuy	É÷AJ80},d‘/Rˆ7}7B‹7Ğ‘éÒÓ°[ÑÏ( §_7›Å°°şÄÄòYG¬‘fàÉîv´·Í­˜İ]{×9ïh—â—5ü˜L´*_É¨"˜W¶Lßû;g·P,¿	Ğ	ÈËÿ”§KÄ0ş
ƒÀ‹_¶QßÜRˆ¡ê×Ô1©àôVt,­Â½±úÆ¦v›`EBÅèUª6l¨¾/°ıi¯×>çP[¿Êc½œFÑz—‡d†Dé´SIüçU°¿V¨Ñ+ŠB{ô”ibAú3” ¢kT:¶EmÔò²…H<ñÒæ8Iièûíc/-ç¡vPV¦#Å`DAA>ÓëG¸ærfIC„#€ÃñË°Éú.Ñ¼¨zZï#ljÀµıõhlj»3‘ÿ®M[iHˆàô0ezL×IÓ×ÃÑ€ä§ŒÃÛS´‰4¥§zdğmÛë¯ÚÅ¼pÕÁ`/ôÆ6c«8:44)Õ‡grÜr$N±°l>‘Dü5ÑŠX¹£`¯í·ûD˜4ª‚èÖ0A`9ÔŸÏ½„b§øV”©xÂ4Í¥É{¡.Î°¯©;J4:xÛÆË^zØÍÜc“²šS	<z™ÏÊ‹ÈÂ™ı"#Œ´'¤Òõ¨òZÕ¢1Í¬€r&+—Ş<AtÎ;ÀÅ¸´ì¬@ó¨ú²ùûbF_+¬àÒó™ÊÿÖ?0Œš¡Høõì¯!+4ĞÜ¼äg±ñjí>0d”v›ö‘r²£V*ú‡¼Û³–´ğ}P¨g@Ù¬41¤SåŸYŒù•Àİ ‘ˆhá6y€·“Jñú@XFğ;¶h9lß¢`/KŠ¢4MúRôı°7 ^±yèáº¡ÖHD±€òi×lm˜•¬¤ç‘OM¡/ÓÄ!ır‰Šmz„FØ½`CéÈ*¶œ7è·ÅÌZ9ãB°ÏÿÆÌ0¬±øŞë!êY6q˜ÓîùkUş—zf]b¢ÉGîŞ¿òÂ5:ÍU…–\d„ÓĞ×ƒÃ,Úï¤À”a>•`ÆnÀ4NÖ;1XÀu~w™Ä:›f(îÆúİk[	G0à×Ìõ´[¬‡+È˜4R,*&-©?B›Z†õÇ8S×s9Ñ'¢¹“ñ÷Ø-DRº!R˜JL|äµ1årøƒi²í…R²úàFqUšƒ°Zò„JšJ&âSœ:Ïúr‰òí¼J]Bu8Í£å2wü‡¡ÿL.ûöôt{°Ş'mg˜˜B˜Âö £7ä (sõi71{L.#™#®(»ŒÆ¡AüJŒhs7M+ ñé‰°­ÄCÓu]ñ=T3X(Ã¥Ñ=÷²µ±5yæšhYU“İ9ÚÒ½y2¦ÇÓº¯ j=ğ]´¬Ïìüj-‰a…aZ8¯<Â<ø{ê0D_ùiµƒQ™Ş×?+›Ó.L‚øœZ"ş"ÀĞU6¶–ıü}¡–ir-¹ÖG+yæ¹óÕtMM+rõ·Z6 Àş&Ò`dzî7óäô#¹~|^JÍ·zW½º‘u«Š%¢ªÌ‹}ÔlSfÚçr¾<]Sá–%½Bş–•¬ÇŸºÆğ¯­ÔjÊA>}¼5ªDf†Ÿ;C4xØ¾èlmw]:C®bÀ$OÆ|İ ¥¢¼ÎÍãÍøU|›CoÒidßê~¬æ:úf*'˜ßU%[“EËÛéın»3MYh«ÍÓñ$aBFNõ&yĞº§72âÓà‹î/ÒB
üæÎ?ZbÏ¿ÃyMö×©ˆ3&†a|Ô½“¨:@%øñx¾ƒãçV` |ò1Hãšƒl$eiLO3¯ÂñÈ†:Á‹ca?éŠOé··¯£3eºjëş{€Ljá«ÑÓV;Büš8­O>cÎ˜×çWXrÅöÁ8zà,©ô¾´q«sgöãşĞ];K¶U
ÿOı¼€¢!vÑS‰ªX®(DNÚğ¤¾"toñ§okR­N¯0 üÕ	¹Øæ%‚VÖ¬é¢|ß˜ºlä'$Š.ø©gîTğûW­ËWWFĞµ63Ü:‡«Ãï‚|˜¾½ˆ@Ÿ‹kbkxÆùlrdÜÈèÅ3 Kp(¦ğï*ÏÉOÚë}„îƒÅƒ*,‰[ú—D:ÎMÈÃ	‡CZy2HÄ£]2}Îf.ÍĞá÷ã(¿eÊÿ ó¸ñ–c|ìVx )Bp,«¿0ĞQ|I¨ÅûC€Üµ½Îä½#¶Û›cÏ!KVºGbšV:gVë\R·¤.r\wú¤Ã(úxràÉ}ì>eöÔHƒËnâ#\Ü§OZèW°¤`’}ÁÃIĞUĞ#?ò\ŠllçïûGe‰J$ËÕÌÉB±„]Ÿ¹ÑÂ/@úÊs‘Ê|Fh^RE-c¥¹ü¼:Oå1Lñg˜'1¾öIñŸÏ¢’î‰&Ò-‰1MŞ3rÂ˜‘^"İ¥İÓ°ÜØ·qRÔì›/Ái—ò›Úõ”Î¡A@È‰ÿ7/¨‹eóH6Xø¸?x5VĞàğÅpq”š4<ÀKÉî€²ÜÀäGö;ïT¨D@'[42yml±:ÏÁ]¨˜j]5ê¿,“¡yäèÏ~¸»”µ³·õÖÂîTKGˆ–üTÎzÊ?#ãİ­>Ù{ï1Ã)¤G]p`¹ÿ ¯.tNÄş2‘ÛÂÉÃ(f oû‹iQH6L¢;â«D‚à“® çGqÖMì+[ÿîÅFÒ×$ŒÃ'NŞc¥‘jâÕmÖKé6ç¯ÄR/Í´Ú¦Ú;ÓUÓQp~Äºoq–6X\céš¡(il¡Ü¶å&Ó9½–Hõ•é¶ûšîê«×Å qŞá¸y9p 7ßüÙÌtgÓØEü¶Tâ\[·º¨nÇ,©ÒVÁÒûd*jŸt{â‘ØŠH,[+>	S=L¦5_¿õ œlÊÀÈ{ZzİËÊIĞ¦›ÅY»ÒØwlül	v2¢§Q€8(nI”SŠ`h˜­ãrPTªe\)µòs*áŸÈ§23_
òô:eõ;Ğ.ÂP]xï¸Ä6¨»zÔ¦›|LjÖÃ³c®á2E›ã¤vN –ïØ…ªÂ7äÚ|UÔä	BJkçJ¥T‹CŸ¥t¤Ğe³•¦‹¦=á“öXhÊŸ¬ˆ&‰äqf\Eè-j fêâğáú^:W¶³•à!ùĞş9‚2˜n½ÉËíèÊŒ‰¢Aúš#jûCx0>ëÈgèN¦¾óJ{‹ºøA¤[{0)üÆ90H<ˆÏñsß2·dœ80U„~Õ±’LQáŒl‰ÄÚŒÈõBš@ïEe[,õQRæ­~‹"\†e,½åõŞo®t$ê½ûü7ªŒ8qm€_úeA#ÏàgiÕÔô®h À"}¼çÇ·dnA€évµÄ„Ğn¿Ë}¬É¨nª× ¡¼Ó8 %^ nˆ€»÷)1.hÖ3ÂR,]i÷z|¦İË)…“i!(
E%”üêíò|CÂ'Å¹KFv¨ö¶jJkÔ¨Åı® ¥A3wÜ¸ëŒ©ömèø$–Ö0+‡y€A°ÂÇ@‹4ğXJ³G?qØtl/«mf
ºÚ¦ôb‚è«ÆÔhµµÓùcştÊÓ÷Š]
ãzƒF^7rI	^Òtdäd›•SPÁ¯ÿÇÑP(ìà©‚¾#­~$;µfe|•\y³Ê¸êCbNöQCŠE¥Sñ6®Bş×Š¶Gò§¯û×Afæâ¥Øi¸O©ºUƒA-åòÙùï@m`=J¾òC3Ş£á! +í[x½8àËü3ĞÊ“ü.LôŸê¯s~½bSk«dù^[úÙî²p4ÀT(Û ª¿¤)P5—e1˜…'¥¤€m 3ïgÜˆ2­’ò¨`4ñoŞ;XÊluºa ]¡0«˜m"ËÒ•ÑH§»@ÎBÌ Q‘}àÚÊóxÍÚNxs;DÀwpË)3eÛZ§Ê|©7´ŠÊ#l8v¹\ñTİÀz\{N‡D ¦Y¸J5ÌßxÚJŞïµ¢îJ™"sË¾y¥ìO­¯zşˆZü½”CoK2|WÇb¬š&/Z4×â´ä6ç‡RQÙË`Îù]®æ
Õï9ûÎ’\vs”ŞÿeTİª¸² ¾Şşà”iİ­÷Î[•HÁLíªPØ‡{QëYÑHñ^[óÓøû¼F%•¾—ŞL†då–8ÁÔ6ÎòÆVÀ6ÁÚzÁNM==Àîn+ 
ˆK¶„=8³õ\œù¨_æ¦Å,Ç«>ÒÙ Qëâ İ¼Ÿ@ì-a‚•;ÎHDfÊæ»¿”êõ²ªëA>÷/Ú‚x'>ÊÏQÊ‘„c5&»\*€Ï¹=¾¬Š‚Wƒh²SÚ`éè°ÅõĞ9V¬ûÿ£<àè³ı¤¨Y•Ï‚î	Â·’N­¢„ò±+÷çÁ‘·Z*äFÜwBïÛÙZ˜ÖhS„Ln~-šME“³÷›óƒrÊÈàb¹óµx‰É"ˆWöÜ|5^8¨U  –”ú³S†ÇÀñŠ£Iú¿ÖaÎw¤ÔÉ«õä£dgÑ(Xğ­Cœ `
ÒpÙsé^à [	+%ua¬ÑŠ´+‘>jÆe˜gÍWëåÏ9{4I7Vx%×KU¤÷ÿí¢ä ÷ÏDWñıO¿¨ ¼…b òômÒômî8!!Y[²·“™ÙÆ4Øì(%éMGµJØæXã·è.bq’éWFødè¸Ô9—˜vªV-Kó/tüª¨÷{1Š+¯Œ
NX‚mšÁw?\+úæsˆÂ[ŸÊÎƒSiº»Ä2ÙMÏ@¼GÆf>
CŸ@ÉÆ‚Uvã:OjXr©¨Şø~b=–æñÛîœq®•ˆÌidÇ“í6´ŒÒ^LÄÜã…­¬U‡çâ¹?Ì /—ÔÄ¦^Tí‘‘ËÑêKL=bÖØ;şˆşã ;i½gm+Qı5†7ÍÍkr•ÏSÌeáU‹¶šàæ­[³7b!ÖnsZx?]pâ
	Ğßfxñ¤[mD|Îv]Ë|^ìó­“kş"†ÛÖü2û5§«c(ãNUµ¶H&1Aë¾½âVuŒé2¿ÁzÕœSš™¨Ğ0µ÷à°u/óÌØœ?ô«ì˜æ[ö|…L×/­¬*[lQLÎ	Ic¶'œE@‹Gøª;eZä‘†I¿­²74Tú³5Šÿ<  7Õ¦­0œåêÏ¬[œŒgE£—@!*¶)«ckR09³(5ÈDÇ­Ì…Ï oiñn´5w”Ÿ¡º|¯U®§™6Ø(8CsS+3ºu ¿QUI×]Õôè™93+•'‘Ã› FS™‡ˆféÃ‰|ĞÀ­ï¥xbp_N±ğı”7Şí¼õ¾¾u¦à!™mÜI©ñ³ne¯ÒÔ€yğGdşŞ`¤„ëØÉådLÃM»>Óo`ã1<»Ó¤KYF(Œ.ö/š®@yéZ"Q=WTx1Wµ-;–qYJZÑ¸¨ÿJç\s |¼ñóëpÒEÉŸÔ˜*1úÂJ8¯ó¢¡şuÇ§ı§LÀq\g’5üÛvkíßÎüOœV½’‰Ûtò?£Ì×aI”¦¤uqç¼Ö?›Cˆ›ÀÕ´ÌÅ2lD8ÃES6·Äƒºş…¬.¬\»W±ºt¦BzËœw"=ºĞ7\dà=Å ×ªªSãN™+ñ×–Qû
 T¡RZîCa.lj`;¡±^…~½y]K”Ú/BÁXpÂ½Kñ³©5&#*=»>)OwêŠÏu†&æ…ğÑwÄxrRË¤W•EóŠ9:få"s#
ïkì¦Ó¹5¸i#z>ÈgéGò_ğ]Ìgóe>ëÍğÒ%‚‰q/Š]šfî_q0©·±q“8âÉ]ÿ
üèë>KC`*3»½äNeŞ^ÊSÌÃ¬­¡k,šârpÏÍ=Çoq€ĞŸ;ÚgÄfcK‡ì{ò'ìF¿\÷üĞü-ô¿ŒÏ°¨d’J¢¯,fÊªn¢ã_;Øõ€¢æôdÏ|Ædc•te×•Tr:Ñ¦l%(ş½ÉnVïÔHr‹¼¼–âJÀÂÏËØPÜ¬„ŞŞÃÁŠYßDŒv®„C¾¼¦)¿ĞÌ¨r¨Åğ ÜÕ’¢|¯ğÿœîÂ“[ŸÀÛ³@ã\)sÌ­m$àPòÖDb®‘Hya UáZQñı#ŠÌlé—ÖÚşFI#ùôBƒÛX•5=ŒÒ Â^ŞGB¨Š¨T
¥†'Ã$€Ìs\v9êºõ­RVLSØ‰>¦…»s¨[7Ñ*0n™f³§£¹çş‹¢‚Ò~A»À#à"QYıî•¹Şd§n§Ûïb‹ël¥Ë5'¹ ,ŞJ‘'<d¨}}Éò;­—ëKB9 Iz´ÍNQÅÍJGÚ1}0ávš£HÉBuËÿ’µ•¯‚9îíºd‚C†mK)™5çšÜ×‹åò,ÃğFøĞïƒgV.,F=¤¿L&ÍY†Û»îÀFÌwİ–·ÊEyßÌ÷ÿï3æH#)(øÆŞ°ËšHµ#ñŒ@íÈ\;†¶·ïÁû‚À«(å6š¬˜Ñx0(Bœè‚Ğv5ĞÔP$b?FóâuÇ§Ó¥À$ ¿ËÒœ½®R¿M2ƒÛ–.uæÙØ\r|­°° ÅŞE± üppäáY+ãkwŞ±&ÌÖV®V>ò6éx/!ŸÚYÙ-2ái q¡`±˜Íe-‰1¯&·^ö´R;&yª‰ı.òò£ñÒ—ÚÁço_\7q—¦µ¿ÖŸ
Æ÷¶ÏŠEâó^Ğ÷îÕ<…ÒÒİ“öÏkáN¹8½şäøTú—zîÅ9¡Ë…+4ÙX—“ı¤»Ôõˆ!ÎF#İ(­µ3ş¹:Èq÷aõó¿˜j"ÀßZT„MjúdgRµ(§ÀñMŠ7[€±ªé‡ş‚?µmÀ‘¯Ğ.1©­À>
UÎù¬,ºCÚ¿Ûë84¡+sv$WÃæï&o6åWÁBK”æ+gİ§Çáy3„T´"©]%p€=¢¬şecé‰\ÄÁ9·Ø"³Øù<z¶Ñ8îÑÆ™ıMU3ì=}
M|WP:¤=öu¸&ƒÃ 7Éœ6>Q;BCIe¸¹ •÷9ñ^—¦ÿ_	jy—NFãÊa##2¼åï†{}IlJNXWhHm|£ı0`%!?ği¯ãe'èõºÍ“ŠäövO7–_9dNWÆèÓ
mˆû¦®Àx*äa‰u_•´“úŸb÷Óº¨é7V€õ™Ş‚h©K½~TömRKk¥­9˜v´ {Ö%,	$Í$ƒ²ŞÃÖ>…¡h¾cêl[sÁ&Ä
ûGA`ÜŸ Öóã­Y×‘…Gÿ
‘ù,8ği.>&×™ğÚ§	GòÛ[ˆ@ËTÑp¥–2Äaœ>ı¡ú~ÚòE‡€Ê¦ˆ:F%[Âæ¾	KÍ¸^úŠ?ÙÍP¶ıo8¾4DŠ-áy «øàVp[)77|¿UÃÖ9&¯•¶nk²â6;/©}
Hcßy,ùJà:$DÃĞ›’“İb½:…ÿk2a.S‹#–¼D±€–Å®µ´#
šé¬N*tarVìh$kSJêg¢Z~D¿fm´\âÀ¶D“Ÿ`îA‹®tuKì|ˆé,ÑJÅŞgk}ğÒê*şŞ	æGeÇÆ2î.Î—Ğ,ÈÄ	@z†ï—ZÛyÓ5v<d>laşn®iÑûõ)pv;	±Àô]¨PÙ\J,Ñv4cßæ 1@¢€5%)Ñ<TJ	ÚË.IzÚió^nñWœùÌINı+N­Â£`ô9dû@"ÅÈ­EÆJVY]î*ô%¸£º×†%‰FÀ¢€·ËîñŞkÿCğèëOeÕY˜á lM™’mQB)'aùr„º<ôe¡OBØ‡èæ’!™)€ú1àŠş×‹£ÌY.—¨ˆ‚ªÒO±âğDAgZ’èâØÕìwÍìZãˆ²)aD 0äØ¨ŒÓ³AU@eÉË…F`ó ¨t´€×Yº (”ÃÅ%Îh ²[º"‘œÀÂø¯“ÎËF—v98Ñ©5P%(ÁÑû*õI¥àm3¤ÿK©X:û5÷ƒs srİ›Úß}·—uQ„®æí2E<†R|¼2ÇôTşŠŠ‹X[.ym`FF‹Õ+ŞHBÀå¦]ğPd¤îâ·FHöl•‡¤±<¦E_dF|ø±jÿ”%È(OvÏhâIÇ¬zç˜Œªş±vb%CN‚ºíÎ<ı3©ÔĞºu…3#Å—‰;÷&áSê¹^8G?¹˜Ú˜l(=€ì¯=04Æ1'û\Aéxb"XÎ¸Nši¹`Xï¤À¼6”¡>ƒ¾x•pZZ¾ßYhÙĞöÕCúoö_YeG¯‘úê2Èî%÷ï±É-.Y2Iº °\eãÀ{Kş‡¨.(—‰.
[Aâ )ÍHfÅ@€pãfº ¼>js¢“¼ŞÉáÃÅhcŸFÆy†Š¨Ï_9‹zı’ç^i{u*Ì2aóçZŠ=x-Clá/A›¥#sø6D$–êï2«¦ü9¡¥]Sİ'eHúé£Ö5Q:
x"ôVIN•Y¸¿{bÇàÁiİ{—­JŸè‹j°x9b»|¥Ä5Û>qñ|ÃÂ‹n]l°“¯ÒV…ôƒW\ÄFÓ‰ÃùtÈÏî–dâ‚É?"vLA¬ª•hØV©¬~®Z³W"ãÎ±ÍÉŒÖ‡Û¨%	oÑèYì£,;^Á¶Ğ[&{Ôz™êò2¢É#5r¾ìW«ëÉ¨3ö¤¬ypbª‡ïuğµf,}“üßW.çc5(|±_.)›+u8÷z	?òáX™•Ë £¼”ÓO.3Ã]Ô”ã!Ùb¦ÍÍÆ+xäç­Ü#Ô+Z²±¬âT¦ã;'.?Q¹ésñÚ9Ö©.^N€R­}¡HVTZ}FåAÂGÉòmJ`r´ÂK¶ÚÛ'çL)Ú
øÊ¬Ö0¾ãEZKßæÇr/šİ	_ñÒ‘¹¥Äõì}ƒc&z±	¶÷ºÙ¡yA?g¦-m,YŸ\ÿ4bHùUÅÔ]íù@²ºÄT÷H‡,ÛËÙ+Œêõë<›&¦"÷cğÀ]Vô2÷"²MJ?šC¸~û‰7zp¤MY³Õ´„;9¦8ËP§¨o-¡\0Îâ­°øåäÃ5>tcÎ˜‚kIÌ")òû^d,(wh'Òò™¦ºıä¢uÚ<Håû¹8úÌz´š­œ6/Êšo2rÉ@/Õ0ãi­K¾'©)ô(ùÏ£Õñó…µ:iÊûªú¨Hf¸clŒ'Ò¯$ùÀe»Àœ±XÒWcrxüùçÇQ»(F ÿoŠÇiœ°>Èİãdz®ŞSYUUèœ_G÷2ùvcµ=Ô¶É]#”Ş¢qƒ!Úİç«N ô©WP¤¾ÏÏJÍ¦Ä‰•ñ°=$°|Élq•ŒCÊó<€TÂ±okgK·µJNåEJÚ‘¤‹¸É®o­)¹½'½4ñ¸B»YüÃÍ	â[¦àP½´İ´P†2ìƒ‰ˆĞšÎ…Fˆ¬cÔ`•—ü ¢¦$AÊDïŠº”mˆå7ÛÔmÀ.Ìï:Ëfä¾s6püœš!Š„€->î Hí÷b³¯J“Å!N€“YıF´wkyô÷ô ™-Éï)ª<±˜¨pHÍ´-l‹êëÕáp/<6pîD]ò| ÈMKÿl-³×ô=E‰“‘°öEEïÛ1•} Eb=F—w§•zİp‘M«ÉÜÓ­«'ıoÛ¾-íÀÒJëO:ÕÆÎ»–ÍøßgB•ëâ`ı4°j: ”E¿IÅÈ)b“¿® B$Fü]æã{%«ï%xÊV	"ÅUíŠˆ\ Í»ç)úÅ]°L:ŸoF…c*[«Ìp\T  ¢erWrö‰ùÈÓÚÏÏs‹‚©ÃJ³Å-íıëĞ(¥Âyj¡ôâ®bè9ºy%Øg§rPñşˆ€E4”s^à,€`Yİßf“8Ë¿ıíUKz»Ø\½m›€øfä#¿§!
_È¢äËW2N˜ÚP¨%Éİ¸°»™û}Ã<„ÿ‘ğejĞØUŞ '¡ÜİğÀ O”À´Óœ²¨Ş`ó8‘Ç¥Î4^›ü3hU«šësQXPªdUR4Ã5·½.ÕHª6¢tŠÀõı]ë† WB½>`¦
§\ò‡‡’ òíù—ê]µmÃÜş…Kk×Äií#2r¢¤Ê="6µ½Êi`O$Å±%ÇY¢­©İATÉQ:KâqT6…ŸŞS¹ÔâLğêíø”3FØéR°
Ø’ÖGC
ÂjİGÑñ£ä#–;ÆZßÑyéÙ…gæTš˜cÔ8Ùƒ‘H!”Çx#µùàGú‚2ğá‡T˜6fL•df¤Ö0Èõ#ĞÂ‹	-H`¼ó\Ï‘	ØõwäÃ¶¢ªŞÔÿu˜ÆÍ¶³ïè×“ØàZÈÓnH!±+)†fÛI¦õ²¾¹¥~İ‡§À¨„«ì&7”óR…/*—w‚Îø{ñåÛGáÅÖçÒ ^Ô¢3ÀtœöıÕµ~Z—?Xºw‰q30ËnÈ´#şşpğÙáµ[8®1’GPAwĞøTÉŸ×ÑtãP5Íjç£$yˆ:¯ÔíC…OŞ„UÒf4Ê=mªHº€ÏÁ;%Èf¿-Å`L*OëõÌk)¨&ö‡^b˜ÚßIBÅJû¸ÅdL¶2û	›AfÕìi	tÑLv¬	GÛà~†Qn0Ğèn_ò'Ãñ
w$ ˆİöÃ³¤Nrl¤%D\ÿp%Ò€›d€Œ£>‚°´}ÅÔ}ˆ¯‡L šiy,åë:4÷7"w
\n’ºdk¤ ¦İö (ÀmÔ¶Şàã7´¤^gn\è·¾4DF¦ùïk9ˆZÕ1·ókÙü0
 zzĞ{{x™Ó´×›´Sç\´Ó%İ\+û#ÂRş@7„ŠŠé´éÆ™”È]TPã–Ğ¡ğü•jPĞ	‘a5¦–zHş‚¿%g³­Ô:÷‘‚
t8{´}µ`?	Ûsm7W–Ê–
™"ôÔ”ê¨ú}cbó½Uhï×:Ë1£b½?i¡Ş¹>/˜c³³No=yzP´AËå„Ë0iÖ’TÙÿ$L8Ø3Õ–Ø÷{2ÿ]œ#İÇı…Ú“¼|;o y#ˆ?¨BßC9»ğsËTy:Ì(‚”´Ã²HRşˆB*^)‹M•Hüã=´ÍW•ÅlÀK%s‡•Ÿ¿ïÒLÌ¼)Ğ2¿Xs¶‡~9Õ»k`*3‚UÉŒ„p,áV¾¹]ÄÂ€cÂÃ¬2–
ƒì†Te]EÎ,%q¾o‡ê*~SŞ€QÛâÉrŒA,
*W/r©÷¨«ƒFZıò—e•khøV%rú$@¨ç@ºİ&ñ¬qŠŒ?{²%’õºómû%`™KZ<Tˆ>`´ªçšm:‘À`]Nø¶Òyq#>‰ŠGşJ¹vÁsßÿº×ê„^oñJbi<Bpş¦1¹=b~@¹y§¦ÁpÕŞ
"k•]C¹:l«A1¦tSÔa^p/ÒÃ½LËTq¦+v&œ€Ù®9¿ãŸ)„Ñ'Lı¦tuó€>'k¯e™“Úi>‘…J#;½cŞç2xbãßTzå½fOÚåÖ0fÆŠÉø”ÄáÆ;H²¸œá–ĞĞöN÷½=<©™J…ëWİP5Óß*V—ÎĞ G.82¹GÒó‘HC¼Zˆ£¢½°§0;—ò—µ2)a·[ú¨&….€
Éz¦ÙáªF`FÔİŒ>9íœ‘"zyG Üª%Sü>5›ûJ7ë+—@²}gÿÆ\7Á”×mš°ùDØãÑ8Š¸«9Eúûµ¿KÖ«ÙÄ¹Ö»EBöSËfR+à"|´N2*AnÊ¬ìÌ®ôw
4öø›P|ú*Ä#rÍ±À
×úÔOõÆˆşêíşGmX˜H9.ä”–y/B²ê/FÓënkXbbJı«\½IPìãô	…	šı!-­¡Çê˜š2Ş¶qGQÔ±Çìº|ĞU{sÂB—XıVÄPŞè°6‹­#so­Ç Ÿ¥ÀŠ$·SèßÃ‚2škšÜ$ÒÚy|"ûY/ÀôeCÃÎ°Wë\&úÈöØ™êâÏx©¦ƒ:ï A°‰»Ñ9¨Ù€Hß&ĞU-,àø¡ıg…‘—e+,Üö±c×wyX{ïÁÕòŞ¯=Š<¶>‰ë=ÿw¾¯ õcÌà"J²¼JF +*ö8xûüæCGØ†	„yÛŞ.]rÍí¾°SwiZ9Wæv¸xZU°«ÒiÀik ö–ğæsû4ÿ¸–ë6‘‚ù5Ê®vÕÊ„*" †Ù¤Ú"ù=Úl¸×ygÌğY¾SMqø…ëfóíÊ«>Msåš»Ö¡Zhœ˜ ù¤™+ék]v…ÅÉ÷ç©‘]©h2MÆ
6®Öìq]¥¼Ïğ'ê­Ù“5[0­éH“ÉÚ ‘W3Nw¸öø•iÇi½“štßŞ†ã\w/Gœ"Y6Ôs£œ7Ò	õŸtkvšÍœÂÜ-‘7\é™ÖB¤ n¢K CQÆ‡¡R«*VuÇt¬iM¼íšÒ@Q b l,:*mg,}OÆaiÆkwï8äÖƒGÊ #7—¡g·Æ…Œù¿uŒï=»ŸÏMõ±Y8ªTC×k7rAÃ²·+²A}gû]æ)í3®i)9;jÜÀ‚X„H©‹ˆÃ ƒÅ3î£pjz/kÁš¦Á¨w~MÏxÇ>˜Î¯¼ˆ"hgyöÖÍ2Œ¥Çª<}3§ºi r$†šXiŞvCÄìÈ$ü4€¸Mb•µ>\òÁ"æ4¼4/ÅÛâR#h[ˆßëµ¨¡BÿpeÇˆ-ØzQ
ËÈÜ?Äg‰ÃğmwåqS3ò¶!÷#bùk"&§B]]F_s_V€qİxQàÿ%ëßªê’C¡ÕX>oÚ2¹
xÈUÏß(dÒG7†&2 q¦k—[k¢O ™ÂV~Òbsï­ì¿ÍH»Ø°ÿN™ä›İ+ÍŠBLs8Ío‹–$g"Ä\fv‡¡qÔ-òKn3‰°›˜˜è¡Ø‘aóĞk‹ Ø¶ß.pü—$‚öÑÿ“#nàäH»ht©c”xù•[±fûèİN*‘7l^³õ5i½u­ ­´XÑ;6…\l=WàdıòzÍìê5ÉG­Ë#Vá«éiÑM)l$tˆŒ–èx@Óg8‹§Â»Í@ø(s%¿(]%¦~éœÉf¨ë$ì”Æ°bBñ£+À€vdÔoEçÍÌz®5CÀ©i&ÒİW»œC©áln9C
ÑE*x˜R›¶úmP™£Ïo5
É˜ W“KsAüÀã>Ÿ¾Ôòæ ºx±l‘S¾UÊ‚ÍOØp>æ•×ß\ë7O3ø€W•A.’µe,n¡ªuØñFy¸ë›–ÀıÔvv[E<½ÂŠñæVZW¨(Ào&š¡	Obµä?ÖıÏö°7Ê½DéªÍ†2WìÚ\ıE‚3lÖnìÀ]’¹×µyÍAm«ŞL­Pü2¤àşó’«¯×§pË‡ÓR„a~ˆœi›

c‚îøé	6+YÀ1pƒ]˜ì4\üÕ¢éÉ |ˆ)ü Ÿ¥ëF>â}©fµ‹©¸{gr èqX$&YĞ¯ö†yÚ!±Ã)®oÚ)­—Ğ“(	½o¡ĞUdwÌ$‡K´y‰Øo3z£@|š©j~jÈhMÜj¬òtqJ¤xª|Øões/çdS¿`­·xÎç
Œ)v´şùfÃ4ÂBÊ¡È»…9¢‹	ÚÃÒA“XjÄ'èa+Ë0@âoÎØ´x7 Úfëíˆ›D%Öğ 4@$M‹Szz
WJƒ%!×ÔH`YØÕÅb…US÷hÀş Ä6Qnô³¾ÚüX}@¼•‘{Ğ6Ih±¨•OXf¶*‚„(§A·gDè¹‚bü’\°ğàÒ%bşöé28ÅÛ=dğÛÌ2)¦÷ödX)Ou¸ÕII¶wÕ<Ó….¼)^şn®o:p&—CÿI2ØM°.ó;~8u´³' ËIk¿ùøÔ~Û³>§{íÀì$?aB|(ÊX•å"L™q¹³Ô ;´ßB(C@!ì-ë»ÇÚ*@,I"ÑzÍğ£Ç¡½^±Ä±Â˜*á¼â–ôRëçŠ|@eˆ?ÂsºTĞŠ÷ğ‚õ¢ä“–Ç;k$![€tŠ ¢i½S™‰åT¼f¶§G)™î¤¸~9/öúÏÈ˜d
(„I {I˜J³×¬Œ¸NW#{øÜu=(E£/ÅÃŞ½µIj¥1ÛLg°ËxƒFş¾j¦™¤ËĞr†éqà›õVŠgUpÜ)Ü4ø§ë-ÑâõîG¼$¤½ÖŒÊ§{Í’¬£ikD’£`Ğ p¦¨$ˆà!*7oq|Yf}™ğ¾™Ùğô¡«ûÖÇëæü£›æF˜Fÿ‘Xé‹ÊÑ»A`Ì&E¾•úÊĞ0ˆ¬‘&z*HÏ‰^×Àğ£n³¸}?ªİÈ‡¬îÙ¡xfi‹”óh>w2± à­u%âr-Ï¶ú‚R…(Z®i5³)Ôš–\ÙY°˜+¾ÖUv¯}­­ŠÂ %ñÑÚWğ?”móÕ
.M†IJ©¯öÍ+`äJƒ Ûm¢{!Ø¼Ìt}½YyzNÓƒì­]×XÂ¡IX~gÔ^v±¸‰ÀÁ:Ø?ki{ƒßUéAeŒ°*½†îM_¤ 2Põ$¯³º$Ç~êg$Úôr0'KtÀ(áÉJq®”®sq|–¹e`‘¾Ú9íŞ\$äÇÂmkÑo»Q¯¤îh(öè\ÙÆ—Ğ	ˆKıëâ„İôÈxÆ«â¨r’C ÙVı;ï²ÚdP9tëe°E–=ˆøŸÌ£k=£'ğÕŞ9„ß*8ÒĞ”VãÕŠ…ì§	Z¸.ÊÒZlŠµr;˜Ç“)´º¸KÌN¯±{L3È¶köV¸Î÷²9YÓgV¤kA
õbHF3Wõ¶…öÙ[Aá]v{W	ãZU{:M½lJÙWB¦, iS]Ÿ³İQÜ’o\…*ˆnmi[Å
ôÛÓo}÷õºÏ¡ä×(*…Ğ±UÎÀHä÷Ê­"Óöm‚”– ( Ağ‚$İræEÃª\˜ùÌ’|n·ıufI°'ÚTÄ}ÉíÈÂŞ9|_Ú·x<Ó•àÀ‚}ÜÑÉÁŒO=ÄÈÓöíx¨¢k¥ku9]Â)#KâaZÍræŠÛEù¤m&q^]†‘S’ŸÚ¨lŒm²C,E.RW¬d£løj
Ö1\Æ‹„‘Xş*=¥¾ lÔ¬	/s¾¸¬lºb%#İÕãß°éÏ$·C!÷§°¡ÃblŞcÊ‚œ‰F!6ã¨œ*HIaN9,;ÅFË§û?Ø¯f…Q¬ìì¥»›#ƒß_ÚÌÄ:¨Òæ‰äZ«‡|¯×…5ûä(‰§`óVÂØø#ëåæ\VØR‡Ÿ2'ÆÔıÕ8±h	W©¸×"‚•qá‹±:^-²œG¿Zz™ +b™ŞähBë$é2…ß™ºbæ!7‚KR}M…‰á«ÉÂ‹Ø›%7a0hê+ÛLC>JfUjÎ® øok¶>å¬\ª¿5x"664;l„/´“Y<Ï¦<-ß|nrjÂ0c]”8{³Ô©yg¬7¯l0Ï¿ş2‰pòNfC“oQ3ªWÙ&¼9Ó¼ÌRsüÔÀë’y³ô€8^U â#T‹¢†ÄÀëòZ€(?{iT6Sk¦A71+p³6ï 9èc'¯Ëm0¬ˆªI:(üYiU^¤Šó¬t·ò¨Å]ÙŞ:È11éh›ä“µy~#:’ÙŠ«
ÇÙTœìÕ›¾›–t_“‡8‘î=çE¼bW_ºIÃ)%Œ 0õİyGaRhå¹Eòo*¦)“g‡,ø˜»wöÈÉ(IlvAÓ1—iÌÁBÜºZö/9Ğeûâ^ùSÓÊàqÕë9/õO¸ÅÒ|Á gIÒ(áCêæÏ&B°©ÒÓ²‹öY`C¡\áû@Ÿg¯™z¾tÿÁøo¬ĞÆ•CÔÇÑEnºâ6Hv»R.Ü:Ğ3ïÔ!8ğ¾ƒÄ‚ª»v„â»¤Sd]ip’R•Ïx,…añ—DjÊ#¤uâÏØøúÍ²Èxn7@_åInz·T‹ŒË-8Ì€"º{qº ï'åäpqÌå«aşÇ“]ˆ¨Ò9kóŠ:1Û‡¦¿ÎÉË²ø†»X øîSÃaºC¦øœï­‡Z‹p¢• 
•xÒg	?Ôëe­á¸å™=ÿØâÀ×ğm'uıa*òŞâ;»ÜíÏã@@JÏ{vu‹ÏMÍHUÜ+cl)ògfzÓâ|ì'wİ´ÀÀj7Ã<|£H2µ©’É$ú3ÛÂì@Œ+wÛ—ófSú#ÔA¦§ÿÆò&a7DĞáã|ªBW¬Í!ùgê¡9Ò°å|û
A8­~Îoc×³yŸ‚H ”JMPYÁ €yTdæ+¿âT¼Ù3ŠÆçLvnş5n©‰İ äë¸¤)»aÈóM‘FTHšwƒ€@étÆDK›?ˆ,]’g¡dT{ g a‚¾wÛEI0¾Uº1y<Œ–G9ˆ	UÓÛÂgwÙÆsÜ±§à¨º†4€æÏÿÄrô?½^ãç½Ó8ÚG­_,çõğ4¸é˜›~°­:\Í>ÔŞ:SæâÑ5‹aÑ§¼ã/>Ö4èüü~¾…¼£zaÑÜx8@œÈÌ~{gèZv3]JíŸãÁMÌ •â€mè|óP^
|ñŒÄ‡òôäø$ÚqîcBRm:ÛíqÌºn¾üïîe\È„xã<t@AÒ+–b§B½ª÷k¿À³LÀb#[Öé3¢ÏÎef/•°bîS‡õñ«$¡…&oúì‹h”Ê+ÛzıéÂ·ˆë»ˆŸê‘k<é,Do`X¼øíH?Wü',-êF„:ğ[;üz18~ü4¡tè².)ÊI_ñ¹»«„«#ãhĞ½èˆ©SSäÍ^ñK·ñúı=V3~£Ë^HÅVÜZ¿Ø±Cô ¿˜+(»§E< ;ßF½“ÑÓÚğÕkÏ]¼À¿ºûZN€ÿ<XÂÌŞ¼ Æ¼ü¯ŞÄeqÔv<\D]gî“0hç°À~_yáIA¤2;g/²‹)Ş—“øßÔê†€íBµ‰ÿ}µ4ÿ’„"ü¨"ÀOÒÙpÇ5¤¹î§Šáêw@ûĞ}=ŸCó–€I!^š'°ë¢á¨ÓNûÙğˆ ×ßE¬"#æ_ªî¦yqäÙ(ì7EÉ+e\±Î°õqúå•îÕš<IåİŠ¨)X0	ó© 1Ş$mFªŠé>hÎüo3Ù¤ÁZfæòÔXIxgä¥B¯³Ê	o'¶¨'ÂB]yM‘ˆù¤áÄğ¦¯'1ùàŒ¬ç&ï%Õ3$móOV\±ur_æ0`4Ûq&rÕpş‰ÙWyÜel 5u×˜ÄQœàAE˜›'M
¦ Ÿ ô üç[Út|„UÚc3×Œ‘å5ÎêaÎBVÚ€A‡İáGgn1%ÜĞuwĞ½:M÷ˆÇ;gQÙ‹g¿Áì»c9ØF«›î}&‚F}Â‘çœ%–ş”]“†·6íaK?û¸9ÒI]Ã( ÂF»Cebñˆ¯
ÙÛ¶ùLAóæ£XbŞŸ$â DµkKåìŒÈ3óÎ¾Ïµº/6çñ"Ã¸XÖväˆË›ß="z™‡é–ÊÀÏåıó=Ë•É|õ©‘¼áy
¾Ù•èZ+ûgÇq5â·Ó‘sb_>Üÿ‚"<œlá˜CÅ±[R£}Ü¿6Yƒ/¨î)šâ¬‘^ä˜A“ŞÆÍÖHöÍòŸü’Å µ°ª>Êv®"ÿª§jJ—;ç: ²"Wm÷şºê¶~@†¤>SÙbhzâÔlFh@m-=¾€b¬Zfˆó%Ëlg‰ñ=®ÃSD_|Fp ³°ƒS@_š	Ùuç|èÈüEl)HÉ[&^’‰®o vŞSƒOÈ9<œ°„ˆBì3>=H¸o-<);/“ÀYLgL\]ŠõıC÷Hfü>Ñr¬…1 }ë€~K—zĞ|¢®‘ ft†ÿ&•7Æ(£³¢Ê ìw††¡æˆ¥KóòvãNÇ¢FŞşˆÁ¶_€£“è¦‚ÄçéHrRŠÉTìT9¶Ö#÷4eºB¡ºM mÅEÖ“ë©'%]¸õb÷¸D=ê/:şöÕlÛÏÛìÓ%Å<fƒ•Û~Ñ40e<Ü´(•P2ã§°#«¤å\Ql³Èì<%«¥	<&tÙHI…!~"¥ BESxNÇ¨œ>“´ßùÿÂû$Ëé"'PÔúòl^ı;ƒ{Ûú¡—
]
×xÄ0hàGÎ!Æ½yÆ¸æ’ ë•M¶ğ7±SWß§ÔğŒó£6XL rócbÉûVõ_ÏæÂí	€ôÄEÖkH]SØŸs\PH?}¬8­eI1*\CîÁiıö³€xÑjqvImAéŒÁxc¬×§–¾¯ta_¥5P¿,ö>nó•|tõäí¡ß•;I¹~L_Â¼y:o–QhoR¬Ğ!PÙT†D¼2¢ûÑ8L	{QÄ¢›;/ĞĞŸp•ö+¾‰T…rx1Sj,×ãY ƒ?p{Ee/ªH<× ÁjÎ½LŠ³ĞUûèİI[ ŞğŸü±1°ßTæ}`˜7•ÆÏ€Í<QŸÄÎIVc[&7-		E¤¢³ÉÁ+³¶o6á{.WöÈ[Á¦ëºØ˜ê`84ÜÒÅyØ¢áÊ8S›™%q1-Å’-T›¶¢"l€{à+ĞnBvØŸ.ı×|£"5Ç–ÈP¦Õ±÷îò:Î!‹v4UOœsçg´™1Á¸QNC±ÁG~xÏˆ~tjwrµ½úÃ¾läqg30Ş0ñÓ,åµP©õ78rÔJó	æv"õÌGŞ{¬CäïJsø˜ÆCÆº§J>…;Ãlù;˜H¥÷…7‚÷:3Bf$·^¶WŸ×T&¬dğêºµ÷pEB ÃI±ôb2T;Q^§ìÓà{li±Èİ1ÅÍúJŠªÍ)«‡>tş’ªY,"D5¦·ÔÊ_M»ğ&†‚Ë„œˆşÿî„&(Pi¹ÑíN¹Í7œ‡•H  kW’jY¯kü[80ËP	ˆfÛ“'îy:¨ñ°(ôİ> bÂÄÛõ†ë!6O»VØªªTYÊ%õª›‚p©(D¨{ı;“†S±ƒu‰ğ{ÆnıŒÙ
Õ­"+?_û‡¡LÛ2Eíæ²‘UÜm±£ì”“( RÔ­.zúÿ!^Ée~¿âj¦9ÛX[íšit,km›!„ƒ#ÿPË™èC¨TƒçP©L¦{g0PxMz®¯Ù%B3O–õ,-(hzj;Ş'oÊdpYğ^º-cœL‰9i¸—ßî÷a–äõTı%i$k­‘@±&å<|–	şîîêğğº4XúX<0òC4—D°R=Íf¬… ¯ã0V”®Obór\7µıÆÄ\‹’,&xÄB>¿/Ê½?š·}Şe¬2öİÕ¿ƒ FÅ{lÜÎÔ9Ûwû„\÷;ÆÑ!À¿ñad2 Øœ/eõ„t-C3†¹°Ñ€ğÉÆ±_
Yı«Á(’ı…q§ğ‚A˜äfìô¥hk¶J.ÛfÒ]á|ÍdÖş8½å'ü}=1¦§².p(¿Å¯şÇGZßpç¨'˜î._YıMªã Ñp5óAÁ®´vu#çct4è¥T~D“Ï÷|¾³)*Øe¡û/`ÕÚ­û¹%àhg‚4æ£î‚Õ†–õ²Ä¦EÿG¯²`zÇ<˜t´&ı¡2˜T!š“„øúR©Ğ<
°İ„íq
VD-in	äşí¨2A™3k‚Š ic¹^ÏÊÊ®ÉfsÓ	d-_¢PùUõeBû®£§¼/æ»ÚëÆÑ·êœ b%Hs÷©T{FXùP…cµ_décï§§“İöáP…ÉÛ°XÍR.ÖWÄBN|­ÁÖèo(/ö‚&±øå ‹¯w’ÒI–Ø”®
Grşn‹Rr:›ÂŠ¢&3šÈÄ¦±ù°ĞGLb::><ûj(¬5"ÜèÑ"]¨‚/İ‡®2ÏWPğOO,if
Co±¡wN
c˜ÄËğ ¼%É\>ro“ß[¢ùEÔMë,QWi{g+êm[93(šªœ´‰é–S´¤ÖÏCœÍ¶ÜåEó_ü%ÿºøÃ¶ÃY¡‡ÁQÌ}ŒUåN_µß×Íæ¨=hÿö;Ñ€Ì(©ÚNwcÜUR3¢tĞl»àoÏBQ­¾¤UÉ,ÔünûµÀ¹EM&V’h½x£°,Ã$“uKÛ"&~?•\â(Y×Ê%ÄÜacav„ƒ•ÜXtRH‰«`ğãÉËmÈÙêBSÇ@ĞÜQÃªÆ¶7ÃBŠA¥†vAY¦Õr¯ãR+cnºå³éûèéˆ?yUşà>Øöô»&Âßk ­.i¤yˆy¾F›¹¥YÖ"¤¬—S„š3oyk"ÖbÀé
è`¢ùÍ(Ê.©”è‘B©9ÎÏ¯õ²ñÕÁÖ’¦•-`Á÷Â& tV†±G“‘ áİğx;éeÉ—® ï†C›ü“òpÃ}'.®*² {ãã8–: ƒĞÌ§*õT³Ë,1_½×(mñOif´p»êA$µb¼TÊÏïŠ·ø±ö‹Ô·Á‚eCš®Õ¥ÈÚ;şãÍ¡fİôr)ÎÒC¤Ó(¼J¿KˆG¡YİæpáH^|åæR@¾Ê”;ƒ«>Ñˆ(sù8¹äßÜT‰’™@…¡Ê·'¼•Ğ{Ö(M¿€rXÊıóÏ3»NbÖb¤Áì±¬Ån‰i¶2¯rúLnÇ kv©§Ëõ±˜û±©J¹ĞÃ¿+²`yúÉ¤G"[Íåæ DõÏ(7vCeóÄÕü‹È]±s«ç×€XâÖMzRŠPëü`Fì*şmGÔJ^ô˜ãrZ?xÑáZÆ2ÆMÏvŒ¿ÚaØ$6f¸ú`U—Ôj@)ñ.›Œç0seTCd@®¿§>¥´F%ú·`ò=¤6¡73å ‹Ğ6G‚ÕëMKEd·oQªú{)[0;f¥ÿ­HO¹PrW³_È®æÑÈ”¹ï#Ëş&ÂÔæ&“­%£^­Ík>©X*OÇÃ´ÊóæÔŞÕHØ¬šSÛ8¥”ÆºîšŒ&ß¦öMÚQ¹ÃÂW÷$²§Tô7=äö/úmã@d-yØ¤m…èÀ>T,7>ÄwrŠ@ñ[»h¼ù3±È^Ú}A3™¶tTl"„GYêß24vi¤Dyû3€D%¹Q‚ÄƒKTŒí½ø¤,Ôèùû¹ 0qÜØÍÀU[GÂ#¾$8×*X—0›¹;:>ºnXÁXåŞóÿ»ÖøÅ§K“âÕ*¶)@•jV™LØ‹^Î™šš=Nìß°"¡n6Ûx¢Åk˜GŞçƒ‚PçÎéJ§Ài„0U¶+P`_şOf²Ó šP3‚Jy´Â
Ãş4÷£é!2.*Æ€°yN“‡êWBí'æ>{¢^7Ùçsˆ21üºï´÷-å¨9&?7W‚èEFOÓ#‚	váèññOrn®šÂšáA	‚X@j˜ì8±aë‹û(°Ê¤äÈœ„:aí£@¿é=lÓfmk¾Ñ`ËPKš* dÒàMïMkr¬W¬ºuÇ¹çŒ@ÃğÆj:˜·ì >ˆè€6y—‘Œ¸Ñ½öÇßJ}0—7–ş´cúv“Õ ¦˜€±<pÙk¨l·àú–%vKø‘õS«¬êQ7¡šoú“¨£ÚúN4?µ÷VÓÑ“‘‚z;.$©Lı/h(Ş¶rã²Su;ÆRyIÃ¹Á¹ZşÔ|`Ôr‡>ÕÛqŠzÛ;w*>€o< Ñs/¡¶[‚…>R•`9Û¾òxh!1ÔşœRpÅ<àqC¢iC0}38srLô‚sC@LeÏg«gO‹	üowÁRƒBg>(÷7¨^´•üoZ(î¦kZpá,¥3K®­ ­ÍY'×²â±t´o
V72:j^%“NÇ¹2Í¤Zí‹ËL‚‚zkm¶Ûn’ô+æ&WßdBÜaûújÙt´2šâOÂ­r¬Œ—jªØ‡íi¥$?yƒ§Aq3¹“=g|Kh_€U#³üXŠ#‚GÅİ³H~–QE™˜BxÇé¡NÃÿH³êéšÓÏm¢ÍrY[ÎzØ”úLfn }‹GhŠãRÕ ¸89î¹wX`Û?8·Ö7#ØvSÄªÉKLã$@8ë\O}Cúü|¢kBš·:¹ƒt¸ô*×Fq+yfsÎA›hêsq>f©Ü{‰¢¢­|„ç-×_•ƒ… ØÄÙÃÖa3»‰«i·Šr–r5Æ›ó]´/¨×}±–œ^ÀM·ÿ.¾CÜQµË°"¦ŠáE\²ßš±¿¦‹†Mˆèc²fäêÌ©ëë ºY Ï©Ï"úXX¾4<õ÷²³%•­êEJ7YFì7ö¤E|AËûÌBÔ0wAß—è‘`9/çâ[Ìa†}–’Û%—w‚rƒ®óöåœ\õ€Œñ‹¨bÒÌÚë)¼ P¬)şµ?ØõAFâ$.·%ùÑœÕõÚŞ ,¾äé°â‡¼ÍDı‹Í€ôtŸÄ„ØúL¶!ˆC‡ø’Ÿ)ãJøÒäÏä•iÏ]ò2'±æ"d}ıÄÌĞ$\S±_n£E‘73“_VÙø"Ó"™
¢0à£kş},¢Ñù¨è¼—É<-â
òw²…j³»1œ`çƒ×OØöXH¾2étĞ‘à‘á¥\wiP1Î¢Ó9pâ¼Š˜Q
]ŠÂàâÚ<÷V-¢‚
?üĞŒF44y}ë¯ H™5=q¦NúU7'úÜø¼Ç"ğ]K>ñù•Éù1#›	¬gŸÎ{jÓ_fÃÅ †VìJF.F.m@UÁ¥‘@¬vPZ§ÁÀjlëEæ®(@™¹ce!˜Ò«Yew³Ll„¸W½'¸»÷ß|½ş;Q”©.º6tòénÍ™‰˜yÀÒÿdİòERê¿Ş0¨÷yåÅ#üx¹¶Jï
t+z[¥p´–±ÒÍHÄ(9Õù¢ù%d„üo_Vüy’oª(LÇÅ÷º%2(ôXav$æû÷¯®o´¿4m—s¹($7ái¨¼dù6sÄ¾M!h8µ×Ã¡¯ÆÛ«Iy!”&îøB±¨5m ®‰¨KkåÖk1‹Ô«q¢‚îvª$Î-‹=j:q;TC:m¯—XÛ÷~7{÷Ña3g¹K,¤|–/Z°ä€…yáo–6Xœ¼Z„şİ°]úkrfş³¬mûÂÃ5CPs£]Ë0™Ÿ*8ºÆUFaNìá"‚³°®{}¨ññ4®:
…ûü/±cÄ?{W6_'y5i)YU§qö^'!Ø–UÚÒ›é(£úz¥YzÄÕë‰ÀB]0»Í¿fJW^Š%¦p>ûàü‰<^Ş?q&$ ¿@"?o“Ïv÷I¯àòCAgÏ(ElıËãó»î“¬)®÷QÍ^¹YzÎyÿ±:…”ğµ°¡½ÀÁ·oŠK˜®Ä˜ª0¶ğ²òš»-É,¢ÑX:íÖaZÈ`‚5~P³3ÌŸ™ÿë&”Jä÷‘ôàä N¿9ş…ä€|tS_ÆÔ@à…uå?BäŸ¤·ÜÃÛïl›öéxSœ©\³„Ì>mM¼~%å˜'Ğï9ô/³#í~P¡éúUßáµu…»VÕZêa¢¢‹÷Áô¼p`#¹¼Ûo•]ãV•ÈzŠbÔFø¾¾Ö…{FÅÜêıPÓ8£¤®ßn‰›±‘ĞGTO‡#AK\“¯Û5ï‹¬Æu¿‡ImNQ©–ú‚TRS4¶‚nŸö­'où‚²ä-QÜJşÎ	^]E3$kui9ñ½H<_j–é>>ÅDîÑ ‡–¥¦ÉÅ©Dj‹7×ñççS­DŠQâÌÁÈgÿ¤Ôº#,PQ
xN_×œ@ÏİOyİ*µqK™õÊ¿ûÇ¹sç\e*'ßßò)	¿V÷ ;3a©¥÷Ãi‚‘ïI™é¢VÛòcM0sA_Úòì!‚U×é„‡«²(9ÊHp4/sK«Kf©eáx‘"	ÅAdp™Ücø÷Ë+Á=xˆ<fĞ#Ki“1eS¾\*g sµ+”%TØ¡ÿñ=+T¸¹X~V@«7í
€b&:i}„¦™´ı"ã¨$&êp5à’ÑË*ºR¤î“fxJ!ğH$>(Òb#ª¿¢í;Eúä_3bT÷7‘åã•éæm²1wá°KúüÖÛÀM˜=›°æ‹JôğÂÜWYDĞÖc,î—³U	{İ´y‘Z¯ ¬‘ìñi`3‡gÊ—ª#“ğ¿ˆ¼…P­nüPÈ</¢ï;ì2ìßxcVvîA\èêĞ‚‚+†¹²ŒÏŸz…Ö”m„ôÿE¥|-£ÃÚz˜ ·s£çV¾§ùeªM‰ÎHÊ¸OäQá\üö¾¼º…q¨s¿ˆL€*~¹ˆù–¦vö1og‚í;õ	gòRx˜÷˜ßˆ×vŒ2	®Ù‹Bg.WôG»­Pï²„]{¥ŸtH.ó#|hæÚZÆKUÔØş^ap–ë¡4XÓšÍ¯7¨˜†â½*mÓ…Ã'û]O«Q$¦;GwĞD”@·S—òmñÒ#£ı[›…×İPèİ¥6ó/#™Ê
#×©éë_æ¦ÌÍ28{¨21šç1ó&i¹ š?ûºÉYˆt™ŒyŒOù_‘> „9˜3M'–ïÿˆ{å:;³â‡{röMÀªõMeûfùé<şk¶S³·œI|¿×äEóF•ÇQÜ ”Š#Wz«™v¸Òº„–ïth]üØ³ŸÆÂ}kô_ùÌcoŸ°Z"÷ärg`’õ¿hÔÙX1>Ëğ›òºiS¬™g~ÁegY,İ•RÂ¦•Ÿ,‘_ıæ7‡JÇÜØ0‚S†@õØ_'?§«½<>÷|+Iö´g‘¾H†b´‹ä´’A[Æ=æ{¥ƒíO«’!| hİQ‰ş\°ÉÄëğ+;Ïõš˜µ¬w]ÂË’ˆÑÊ=bÅê|>F&„Ç£ßŸ¦É¸ÇÍæaı`•tYïpÃòY¯¦)¢Kxºº% _®-èGb°V½_†›@˜7ò €‰á	f@[^Kß[n…M®‡z”'"
-Œ,.<«'nty&\ÑƒşÁíªf_ÖØÍo¸Vİ@*¸àÔ mJC«-¶¯fq^Fø%w¬èNUrdeüa.(°$Nd¨½§±_ª¯Hèô5H.‚:
_:ß í1
Ó./tùõS˜y4œî1am—¸ H ]’(ßfIysP}êÁ¤¥¾î¹PKÖÏìcò–„]ÎğòÓBQ«yÛ“wÅá5ç.ƒöñÚ`6çIcÊ§Ú¡Zèí«}C³MkšÜtÃcç.¥Aëï—ÚF¼š Yå¹İØ,AŒÇ;Ù†Ñ(-ğ#z%ü|bH¼Oºç»\5Iÿ‘/ääN¡·GÉLmAMØ£7ô²x.“€>"s0òG¥lUætašo2œµ²wçJIs¡\2¦ñÊÕª”Ò6¼^*¨Ú¶‹´Üq:0-]–åRŒ›fss    mJr~§ÿ Á³€À U‘B±Ägû    YZ