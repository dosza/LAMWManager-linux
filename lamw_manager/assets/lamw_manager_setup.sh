#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1851771452"
MD5="68d42faa3bda77a5f86cddc7aaaa727b"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23224"
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
	echo Date of packaging: Wed Aug  4 02:35:42 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿZx] ¼}•À1Dd]‡Á›PætİDõåíúkØÌ°&Ÿó\ƒ—jÖi8¿´ôìÎ€¶
“ÖÇ<ïà‰÷^Ï@ËİÃHü­­–æ©¦¨º·{3b–*ÒfgÚô‘!É‡D²}áæ,Ub2B=¸Qª+¹cØ¼”ruĞİdòy$ 5}ìŒ7‹)ĞW;é|V›•REc|=§ ®êŸŒ=¼«µ\§ó8‰níå•¬z}jşvÃÑÚûüGH1Ş€ú‡ÍFô•¦ŸĞšo›m”Ø¶ ÿš4üã¦OÀ„Ï-ÙÚYv÷qÜrûÊ-¡ÒtÛÊRÙí÷¨rOBª)ê«Ù‰ÖA…/ÄÙYËüIb*ëä-B3œ•P\pú,dÓNâB¼RF?ş‰$ ËG ³édM•£«pÛõÌ|ãÛ»››;2ˆ¾ÃZíÁï4™³Ø¬-,g¿7X?M«âGCÈ£ƒı]|t`ÉÂE-F—e ÏA¾öV†K‹ÀÅXb{&îàõ¬ŠóùÄ—ŒŒqöÃ´y&¸îO_)­]Û»{[o¸xÇÒN.ô»¶_Î–íIÄ.m¼Î³İaØÎ¾öÏEìRTyıBÍ_˜Ãsı\Ó¹Fê~ Õ¸R(yàénîùÁ×¨°öQùXaQ"yKÒ÷§µh9_`
ÑWº—ä(åÎğ[™Ì÷F:×<®;ÿ®2=—`P~i­–¾Ãëjz'ˆkÀ­ÔíˆÃoÇp¨qÙQnŒUšÓ‚qÚ„'ÉcuÄ”
Çr¨e¿áa6‹\+‡Åô …XºµnåDÈo”0•xún€ãVôãTöU—ÎÑÆhëBnÌ¡¯jo\íÊR´¸?şÃ¿<€À”.Åˆë.a/U‹5h:X'X°bïÎõ!{¥0{ã$¢’ÿ~¾1E„£@ ï·4ß‰†Æ._°n›K˜‘q“]½ºMè³£ŸYLÖ}ÀNÃ‡nzAø¿-Ÿ¿í5œ[¨,å”ÆşŠRØ${ğºÀKŒ= ÍØ4ú†àLL[›”û¬v`È£Xû¿¹GÂ/İQ5|.¡¾îÙ{ r420ŸÖyÁ	Ğ(*}}OÃ|v%ë“íDûşõS} ”zS u][Ö½îhøMô	±†qEQ	s+÷§KÆ¾pıgyì¦I„3b~d{BµŠ0–Å£²Ş¾"c YïoöY¶R%kñ63$·‘€¢4+DAÛ‰¹èÎæôFoÁ(ã`nH6@”A€~I~‚Oí' $i›†çlæ*tê~Òl§EB‘íûl{»? ƒ3ğ‡Ä6Á×'®Y…+uAú“o'[È5ø2âZpŸòŠ¯Å_tëÉs¡OwcHš[,û¬HµÌp?ƒ¨d³:Dfq.2k»@ŞMåOóÖÑr´¿sú1Kh$¡…nnòİQ›ÃÓ>Xo¶õÔqÒØÒx©®yYõ÷)QíƒvïYÄ™òÖ¤­Îş•ânÀ8ĞTôó¾6¨ğTè>‡ø"Ì`Ô}õyÂÈ©ŠH2F²W×Í:šÙ1’Æ!šÔN½È ;¹\¶:›D8%–SÈHÏïD‡[(Æ9cÚ)ƒÔÎ êƒdB•;vú€‘¶ë’!yÑ•®<‹ŞÄÎ³E…ÃÊ…Á|ëˆ­şgyO™ï‹°L ?GçëÃ0g_¶ß€;µ/õpçfzÿösì»å5(lÎ‡`›7¹èOµMàş½õ¡˜Dk…K€:¯$İ}ÃX­?_0SRØH!ÖYv+0>«’hƒ—B¡%ôUìÓZı+˜^TT
m<@İP>¶ÑÆŒš@Ät`ÑTŞ´umÑú¯âóíx?‹Õr>6V™Â.6†ı½y®yÑ
mËc&ıtHI ÜkBM…+ÜÑöä¶éÁUÒÏï!y¤¨QöãJ‹[zĞ¨©^²©ˆÇˆ'ŒUVåEAşGF,@%\FßMâ©PvØBÂ¿,üõ+ıÁ.V¶Ø”yà¬¥B°AÜN	XIúš3ÇÄÍÏ¼¡µr~Ä¶û.ÏènBàù±Órmÿ•«êW8iÑ~ ¾”æ–0œ¯¹z
I¸×)'ëĞÔ™É±ö¹â‰,¬æı;Ú:ìl=MâË>íÿ¿ÍëNê5«î%º*ÃÌ¢ç|2ÙıI®H¡û.ú’ã]r#…{{İ¹*kGsXÓP0róáçşõ]Ïvœ”XÅPŒ‡ZÄHV……À¯œàKåğ±Û^Ï?Äå“¢¾wd‰çQ£Ç#dÊMTŞ †t1ˆ±¬¢Wc¥0-tC³Ç77^#IÒ¯cùp¸OT™Ë™GÂX«·æãÜ@³§·ŸºP€çÄ”xà(62ı^õ\ÔéÖ—q<@xÂ>?!·¡›2á¿„ApÚG³ÍqÊæ·ÙAß×‹ğ¢…Šù¥égãÁÔ*B9ìEËÒÏéŠßAàCgÎÅT56š3M©Jªû¸Nü×.Z×–Îé¹úî^~dÿlCš³S§I7ÇPæLx3~p’fáo£D+‚©9X·Á¸[~Cş8pê:;„ÅYPÇl®Ëü@:öòÔ†cAÃä0=v(õc¦³h¹f)î8ÜGê@'³‚6ôHÏJÓN+uE%+·%Á2¤ .FW’R§¯NÙi·É|MàÔ´ÑHüÀ ƒqãË¤¡7Vù–H‡ÁÓÜÕU7o9úV-8Âı0Ü¡—sĞ›·\ş[-Ò@v¡pÜ®¨6~bYÙVã/r©‘İ#«ÛOY€m=Æ[Ô¼3¶“8 „ó] Ğ¦ø€²±ô=.T@*Ú·}ÕØÄ3#;å§6œw™™{)JKµ[ÛZœ#Ş‘’íº)2¸!·ÒPf«šCr›;g"»ú\Ü˜Ãxz…>(¤ænÅÁšÉ„œĞ;…7<=ïB-Æ2&³Û}ŞÜª’¢şÓ—‡îe€,$nşĞJü§¼]7,dA}÷œ£ó¥tLsBLëOÂí—xº,ÃoîÌhæUİÆòòëD§Ó{P{G=˜{ê÷•«&È!—î%»Ï•3àNÃİeÃRTä-'ª&0ï8€ã•jnÒ¨ÓzCĞ1Fë^A&Ù.@šv‚`õòİ’rq&ç
-€Òå± ì;ÉÎn<LİÖŞa¼(…ÂÂe¸|^¹)cÇšÊ_Ç6w„€ô§Ó•g–"œ9Vá •Hh›æ˜à8;8ÍÕ»A¦ÖNeg’+å 4·a³^(B[Ï–7>J}h™á;HÈs‡[CtÕ˜deábE'Ÿ·(êMN¥Í9ï°KğmmØ|ÿ'Õß£Qr¬}^pòMã—Ey]z<’ûË!­øß1YÌT”L¨Oä•ªnxyb"‚&nèGÜ$D’J¦»ä¶6æ$ùt0p–PÌ‹&•\J²ŸİgG¤}¤15'üşşF‚ŸÚi¯%Ç&:ŞL/÷½$­ÿ„ãD9€ö¡´a*sÚì-”ñY§¹×§i¼Œ¯)ï¢Ï³á¿!9!+È¥½¤ ÛnÄ69·Ql=ÚP[Î]b³]†¦VgËlU†×ùçª¼IkÙ%İO—Å•«‹ù’¯Ûq§NÂ¡÷O,¹–ˆåàÙ4ğám35ÄVdñEõé°Dºôl	“¯ŠpÌz¶/g=R˜ŒôQã—ÆÑ~¡Ä«÷¶ÛÚYšŸé2½©€ôQ´sqSµ4”º¡(Ÿm»–	6Şò¨¸oò“÷ósğ74C^áG¯M‘½yq
Ø:*mŞæÜAL/Pœ^Ï÷§íWNŠQà	ÈØcO¾@GeÌ3IÁU£¦euM¯¹”÷:TeA~ÛNn5 ¶l£Š„ƒ2ˆš‹åùÕ(Föàü®XÛê£Uj›bÆ/g ?¹hQÍÇ­šÕZ)ÃÅ&áS'0ë7*ƒ	‡‡_è%@YÒ›²o»Ô…q6šÜx˜İ£àPhß·Â®îáÔÓ¡Ò	sºø7	4–°¢ëœ¡ğí"î¼øÖœè†¸Î€MäÒ•'¿ØRo‘FØLV‹nf#oìºË¥/Î˜×¹”ªM9mŸ˜öìùq6t¼·FtÊziz$@ã‡5}‚Ø6&æ“3!}lSÑÀ^.èŸBÉ^û¼äÑ#FûÕ'Ê­É*’zªñ„¢˜~ˆRë:şùA0–Öz>cí9¥(ÿ¨ü›‰şó½pÑÔ¨0Í/ú.HÇıÎ‰ ç¢ÿ­§µ3;)Uêõ\~m,°'ÒA)­î{Ñoî_\aÓ,]¥JqR9ù3ğë<UŠ¸îyÅõìÛ—Ò4Ewš|ÓÃ4^So\ñÊ?Nü/9¸][KÓN‹äÃ¯±†˜£Q›ûìXnë±&µöiE7aÛ'÷>k®÷`ãª[eÃC½‹Åözt®€¹®ËÇ‘«êÊ‘d9° ‡>f¥a’ÅMÀŸ´uMykÕÌPF,ù;”Òa.¥!¤ÿl‹î¦sŒâ¯Çcf¦ğŸûøUEåi7`\LIüy.x<ö,î`bH*¤4bÎ¢1“+N2PÍrš0ãd½Û˜=Ê‰? r
î’î÷K#Ìé9€Bé#£e8æ8/8nğéG”äßÒ_Q¶ŸîÌrı}| 8Pd‚Ú<ºÖû.{ÂHƒ¦Œ•Ñ-ÛÑ® vM]51’
l¾NÒgğN-…õ‹²$Ÿ½IïÇæÉ¢–BÔJáa³‚à’ÆáZ/}le·
 ®Çø…‰eõ Ø¡ÈÒLì@7Êº_L¸!Ró>5rioqÁ?‘©ÉÓ |ø¤å]!F»·£¦‹K¡ø‘* ›&äœj¶k/®›˜ZvxyÃ&~ey,o¾¦ùbEˆÌyJö¦l=§«Àöˆûä6^œ+š^()‘oäîù»»k„»£}•i%™óÚ(§Å»jé‹­i9XùPj±*æáE«••jaÅÌ¤kA]L3÷2züÂÂªz²ÚP¸z“ºÌ–Š%×nI'¼Ûc²ËNÂ5U²ÀnkDU«ÌŸg’dœ&Tâ85â“i‰6·Ê}±v”!ã—öÚÑ3ìy;ä.£g´> ÷!À-lêú™”V%]ì¿¾Ğ»Ùa• ó¼Æ‡¹$E£¦Ÿ3ò¨İ{$8„¦â†ÙÙo’LŠ
 š5çÑ¯&-œÅ¿_G§8‚ %ı-L{Â²y!uÔ¦§cJ‡HÀ‹>é°‘Ò8×e+ŞC“|²:	låÉF¢e_´oîÜyœbºî›;8ïYíÔe*ŸäWĞ2ù<)hÂˆ0İçŠµ76„¶J3nÍÉZ"AìtkµÀÎìUYÇÃ‘`œLTÉ$Dá\#ĞJUÜäÒ©C¹Á/°'¼_+íÄ9‹Û7IY@EÔjW‰3‡Z°ˆâ'íEV;Y€¾:hƒÍ“ºu¨9%Z,q3ÏµKe%Šô›Í…¾ù,EçÒ† ü'·…´”*æŒõ˜rK\æîáw–4)<#hßE ,Àµ_2ï¹êeI	©g4ı_}À±˜ØÙ˜IÕ&FëV½±U01ÇÇ…06fLâÛçƒ0o{GŞ?>OQBzĞaÜŠÖ»³t§7üÄŠ_4ÅÄPo¸Ü&mwî³¼ÂE)6÷ş%ÇOˆ¿–Ì>t›S_;–í¿ÅµOçF·uRûÍ½cü?‡›ÿù²)ûs² Z<NÃ¾®7­Å8ù¦¶,G@8€—Úï§¬› ›ÀræÊC¼üÓæÀ×>¶l,˜—‘“Ú´å:è³OZÕùcÍ†ÿPñÜÖ­Û,evF'Ynşª×€›¤7"×]´ÍMö?HŞ:å@AÆGÛéáoœIïbÕCX.ºök”m"™Ÿ“tË—v¤¢¬^â®4çú+4ëRÃzÍ´ËTwæİKÿ®ºŒ¸Lr¬®Ä¢>òàíF@ëCX Ô­ïKÕf‡¼ZSjOôš,©Î¶Ôwºô/"Åjí\¤¤ÑŞó'P‚´HÙÅñ¹|,/}*şÓû”T©[Rz¸ç™¨Èjó*$£«µz|Ê×°¬Ş¦´şj+Êy[ŠèæõİãèşV'ñóó¶—~.ŸãgQËñUoÔ–Ÿ¸U.äTôL‹RÚà¼<]&ÁæŞ~M'xÉ¼„ƒşµ³.Šş(n}ñ¾G¢#$DÑ€Œ€¾+ßt><M–èú¡'1àNU æk1­:
2¿(Š„<Ü9Ğ#Æå©¥e%ˆÛIy„… ’§¦Xu8#£ß©Í CàKš?ãFı»02Ludp_÷³Q[¶ (2E15ødrÃ)hèĞƒ!+ÿK—¶öàYLoˆrnÁµ{0 ¬¸mï°Å¨£ô&‚’_ rºjüß/—"0¯ÔÎN9ôÉÑ¹ĞLi¾a/fÇèd
_À‰Ì£¬@(6v¢/ûBş„Ä–£§•†şE©„e1iwK‹bÂWğ„8]Äú&Äƒ ƒÑï°Åß£Y½L8Ò¦½ø[ËnÁCÇiöÃÄğæ¶ĞÄqÈ8$6‡¶ÿÎîj{eªÙ>JüšÈ„2kï€Ï§tË2£Rd¥ésõ`ñßëîÈrİ²»«ÙÓ‰ôŒƒçjÑlóÉe10Ü·˜Bæ/vÚXŞ%àèú¬kqLÀ}áoŒ?öe?F‚fõPxäáä[\Q]ÒÛ#ó,ÍA¶·JDğßyü¥6D²R•}3yÌˆWïœ3nûËÈE{AŒ[ƒ©
ÈtÃ¦Ò¨×†nîoªæ?Á76@x †èóğ\¦)´ ¤^	EîY‡íÛƒÕÄ?ğ	µ´m’a4‘rk3È1ç‹ì"+{/İ4%@‘qhÃo’õB<Şy“x2Ùt{d;Ú&@ø Ù
K,™’¦š^'ÁÆ'pò´T¨İ'İÍ} X$K ÎÀ[Pv†{Obzé']¬Ş3‹™¦xH.Ò@‘P¡ü­a—Ñ…°¸Ó³Îá.xÜIˆ°ù?Ã±9øî`½9ådZ*Yş_%i‚<ÆL]ÀĞyœ•ÈUgŸƒ/Ì‹wZGö©å”–÷VØv³B³”âìò:30·¦¢ìàW•ÿâº»5FÄFaHŠ3ïæ~Hù,<Šv¬†1‹°rªÖ„hÏ]ešÖ)£gJwÛvÃº²S<wZúé&[3–íõ*§P+¡ö¨£È4'Ê­Eî¿=´P¡©bMpÚ‰šŞüíÄ6%D™d„•¡„lñ.t&G]qÁaépè¨A/îš‡7W^ƒ‹aİçÙ@â¤¬–µklj=øé
;d h²¯M&e›×7°Õ‰uä1’;ú ñĞ'8Vİº0Ûr¬5
ê30sëWÈ›óæƒ½ùJó´)Q‰{¿Ê°tçßóÀF·±ÁÜRO‘OİGÄp5Ìz_‡µ[0È7^Yá*ÈÁ[ÛæÊP*m¼’À÷»%	]P5K	•_1@AÛßğ€¢w+è•u¦E™|¼_Y8½TnH(ıÃ˜Ò8PvKşİf¸?+ö…Ooœ#¯1! g=Ù–Ò¬nxüõHP6{/¤T#0Al¬w•ÎŞı-m
æŞ1Œkõ!‡ê³hOŸ$‘æÅcİÊ32‚ËŒ‚½¾—¬æ=©ÿÉìIÆ»èôZ|ÉKµ´áf–fı—"¯š…~b~<;[Y›g†d «º*9ŸµÃÏ,pˆSÖI¤T³5(I—p´+$½^¯ô€áüSœpğ›ä		¦üzKFó<€Íá´)¯Æëƒ‹å™¨³ÕıCmò]W2¬÷9j,Ø{ÿ
Ÿûş¦y	L’ fá“«¹TgKR…HIÕ>ªuÆ…áà@’Ù×ê Ğz¿a•‚€ç\A¾ñÁû¯6ì|ä |®ô®*,Ç?Uz´"¯+-ÿ?¨}JaXA§(mŸ~U(Œ¹.Ì¢q8ö‹gšfÅıá‘T>Z5Óö'öTO•ış'&¼[ °4„¥ëØÓg€?VĞQV»–Cõ‚AË¼†VF#ºRà;sy0—âÜ[å;qØ¼‡.1«ßy~ é05æÖq–7Ô£™ <©ÉnñqØ)RÎÑ®]<©Yú§N&“Ôú”Àª¿â¶‹Duî§ÛØHp†®½Ó1¸eOyHÏÌ×Ÿ<å÷h–ëQK_È$Ö‘ÄïŠyÃ¶…·Ínı‘:"°“ÎWÿá|`J«È_Ş/¯ÃÅlaÁ„G13ôk,Q.‰Ç8vfÔÓ¥¾)ªñŞ+P¼ö„¢ôâuíWØV~®°=zm8°’Å„\v~Nõ2®„Ô.›_ûhJ…a‘…wuUÈÉ†óBŞşCÇRÂ¾Brû¥dZv·İ\î”˜[ÒƒñâXÇÛ¾22¥lÍïá¢k`„oKVÉH’Ñzj~îœÂ'>–|Jyfã|‰ıÚQŞOÃ]MYx“¥E8RÍã°şo$iV»¢õÇõ’RFÎ$•%ƒ¡iU»®ª‚N¬óŸ¤>"ÌçìüN·¢^Àé¶ãßæŠ¥!‹Â!”$¾´î2õ+>·PFîS$-²6Õ‹wûK%ŒéJJrH¸ª#ê¹ìOiÓj«D0	'²*­™Ô(ùúMª¹Ì—#Á˜xO+Ñ:ôìu‰+¬O³¦D®I™Y&˜¢ûWF€PãåeHhn“Té|²„Éã÷„€ôx×EåÀfâÀ>]ˆHùi¤°D:ì#–=OÈç7¥§¥aÉı~A0q»E· ø_3º­ÃÑ;[5&üğHT
‰ˆBQÖY­>¥Ğ2&$1°Êg$ÃÇQ{Å`W—j°H.‚ÿÄ`b 6æï^\ÒğŒøñ	 2qA"nÿ›LâØºÛzÃ²»óõùù&Êá×„¾¢<$=Ê§ãkõOøé´„À+]>yı!,â
#Se$Ô ÚÔ”±HUäh¼Z?bği‡à´4ÆCü´÷ÎË •$'¬v‰QÉi àê¢uëçr/c“Æ”º\ée&Ó(áGT'LÅæşZ¥4š=°İk‡'­Å¬=An±b¨şØ4áì	%çîÇ(ç÷£	ìÌw­}+²MĞT®­uµ¤½‹¨ƒáwŠ©{ˆ~¯VÑ_2×‹CVÌÊQ}Õƒ«‘äO"óÈ´Á;^U;‹I±ä;_­Æ»î—Éù¦§=XÑ$ZN°¤›ñPl :áR;]cì¾zfÕ>ÛtÖø/;ôY0ÙO›aÎƒÔŞVq)MK!k!^\ùÔ—œùkr/gĞ<£µĞ´óï„İ–+rÿŸÎX@ÜV·äoÄì˜Èzu?]¬ó†\t,ı£³á¡¾©Û¿v¦,óŒôêxè#q°|4§rxgŒ5KÈqö«’ÃùF ùqTxßOÓl{$~Hİõº„ºµ£[Õ24@\u–^‰Û† Œ]%v	Ğ«±ÆÍ¼–.¸ş³4sƒ|ÓÌ@…ôßÿHÎéa{UªQ k·L÷)Œ'Él^+
QL óÒÃÑ&lgv„íw"5á±8.ğ;ù ;uôHµö`ü|ÖÆĞ/R’ÌñwÏj,{h]ÏT¨HXê,0§p˜6§¤}×½‹9º7‰<ÇñsF¥TšÁ·_5°[‹„¯ı–+]ëƒl0€"¬dá7àÎD²}°øc)½ s=2JÄgé=-×ò	/¼ñM¿Û6İx”>ïZ+Tıç
Şw$×é°?ã2	¶Î*=õFÎ+³(
µ>˜.ºå_«° bà´öƒh>9R¢µ¹ĞoÙîM¹ÕBÁÄB¬ŸY¸%•„dyÀ©½¶¨n8{»íì*+Q³lºGriÒ¥æXbwYİY80zGœ¬·N±]¾tsÑƒôzÁ™ââ$q&;Ù>1=€”âXW`§ÒZHmÕåX™Ø”’@ÇÉöutªo4yÌ}¸%ƒƒ
Z…>P-èyÖ±²‰K@¥6íI}ÑF£ÜZŞ>a‰ŒêÈÄ	¨˜²‰â`,$¬Ñé"Á•Ã¥/»ï½€0qv+}pEÄ(7*aàƒÁ¤ë‹ÙjtÊü—ø&.ØEç·ƒíåkàÍyJu¢Ó†Yßv;A~y²çÔe‘~W•OÆRuŠyKM¢t,.ºÌOÔ^gé•JÁéQXè:C_§R¦+LÎµ¬ZyLéÑh”ü¥~o4szÙÙÓ“ŠçSâRÀÁ¬µhœ¾’ÜŒâÉS[Ä^Ê;eFA›ûò‹¯àŒ„x°xĞ•¾g$º&0š>m™<Aù–…ßN-XÁVfO'zğ­ÀX—W_Œ¹Wö³*47F‡W
÷™Á´×c¶Ü’ÅWm5ó­Â àwÙ¸ÇÄ²©MÄÌ:W€ñÇ<¹S~$ºòt¯#OXÜ£xÕ¿µÉÊ}&Èœ¶ùWÿÈ o  wëS•%„’çíÖÉ÷Ö>—¼¨™¥!ÇW–·[å¥#¿›Ù¿´<ÕëÏ÷7z°ohÿX«?Ãƒ$œ*EÏ¨/#
rR6vÃÏh­ùy£®ú5dÄt½ø%VáBhÍ3¦XİØ.Q(Ì!fyKºi‡é‡oÀœ¼(Î1Êâ?İcŠµõj¶yÓ›Û%Jrù%‰N…¯5hMîê‰P©ĞÉöÚ&Ó^¡+EDeJv€L2»a5Z')Ì|I‰]Í sëO´šSjŠ_ë°aOŒ8¹ÿÕ;­•aƒlNÆÜÅ&Dw«Wy”²Ğ½…Œ¬·Š·ÒO¬Iî4¯ÜóQİk#ÿúÎ3Æc°&ÒYƒØ)(^ñ%HûõOXñnÖˆ|™­LÂ¬pU|±ƒ÷âbå‹É‘şï•!Ü‘¯¡Å1ãOG_&p¹gù‡¸;æ\ø¿À®¼ü@o#šÖŸÌ%¹šİôákkİR¹2ÌSÓ¨L_!òÔ¼Ê¾‘»1+	ƒ§¡v)Q¯ÅÉêü©á	
Šj4¦!<û÷§ÂPt%šâáçÜŞ2xÏ†]¥|«!‚ê^§’o¡Éæf*¼’©GÏ˜î¾ş Èur1OèrzQª][c»¡Şî-5ØÍ”ìJ3ÃÙHâ"FLî(¾òøë'¡¨$ïŞ•(ÿ·
øÛö²ÆÕÀ|ù¤I÷¤òôamÍ’p´†;åİ%®6úş5æıÓ7ëLÈ9ÒâáÈÆ®ºş§"ïC¡uZÃFŒ@Ø€»ìÓ@WÕ+`¾âüB0Ù³äc!^új-–Ë.ã­-çõFºõ<ñih¡á½·Îa2õ–,r»ZÇMœZ´êOÇ™fY2mÎY“~ƒg¯lÑï ÏF¬kÁt<±™	"eìbe×Á`D'Ë2sl-û–x$;¨³æ§!!{‘%'²œ)âòBO†¶PJ,ıRPv‘¨ã	Ë‡:ÎT!uö¤|f^{x‰Sı2Ó±nï©ìÜ{gò¹RÄüÙ;<üãÁM­”êY*´AzfÈ^¯WyQ‘åê:Æ-‘t¼Ä“%@tÃu
ïÌC¡¥c¯qşÕmæ§
ÂBV/ŠÒ§»©µ È3 ›éÊñ\Ôü“—x‚dÎ
/×6$(qŞª„¼gûU æ×
P°nµ	ª%€;µmPÔ3Ùù×´l'*]5ÆrZåév_Ï=gˆú Ñ§u«nÓy§lá®­Ç‘æß4ı?ô@ã§wP'ëX9”jí6ÅS³~HÈBÙ89Ú:n-®lö)h&&ºšiş¶'¢ë¢! ÔÈ\LÛ8w«Ù"9ªìk+s!•¿=l0úšêö@©Å.‰]Hë=c«fÔ®òç}“98†¼àôÊ©Sêªšé¶VÄúùM:Iÿ½`Å›¹ğRœõİÎúàönÙMò@ÊUø_ÖÿÕ„€nveş˜1ÌcLéin³$ı’¿r>oˆO$ˆx,Oeœ¡!gñÍ~)e?ñß ­ÏZïÔáTá¸ÍÈù·_Zw£èSézËx!ªÉáÆdT9‚µ(FRæO­W¹>Ç2É[,Î.÷êÇ„µäê[Ü—ƒr:éıØCÊôÍ^ÓM½ÜJa¶–}^>¯Œv„ˆbÆrúÖR‘IOä Lå¸€iZ%LSÁKô”M_¸Ğ#¢’V½n§Óîñc¥µºN¼î”9£~””²°gäbqbn‚CÚ¯¥Öıp12‹¿DO?yš2°Ç‚×u
/mA¸0WÅÚçŸjİn«1!Ei4S !PñÚáÂÇ÷Gkùtï_TfĞæ<ÀåÒÈñÍ‰Ã—´Z(‰û`vä9µw>QNÃ íXS¥o˜e;„ZÁáøêmïÓ€ğ[ˆî{eéSšÒYüûwãcÂ_Z‚4^ìş=õ¶§'QBi˜ñ>ôÎU“İ"f­r˜£šûPlŠS±Ë÷Üc4—TjªuümG|”dŞ’åûÁF»ã¯t¸Ûv<ÿ*~¶k¡å©\ä7Õ‚0{‡<_ôzú“ßÍfÌÎNS*f’™±ö«fÇE(¢ ÉTÿäeFÄ²YC´SŒ&ZåVkód#vQëŒG7„ÄIZ²&„ò]î3#TŒ–µ)$lwb[öÍjÚ™ìtÑÁºŞè©	a÷plo£v‹-2†¢j¶E’Ó|'|Wä„d’,c,-Äº
1(oA&Fb@>­>!d›RÔî÷¨fuÉ"ÅßçTÁr6Û3ÊÌ-iåqYOÂ¨0ÓT|õ§U$EÊë•Rê&¾c~×A¬xNÎNj‰qËuÜX¯İ¾¼ú­3Õ¯I_Ís·8¦F‘£^›P‘Qk£Ãóó%XíØòså˜CTnïƒt-9˜D¥X`œx†KTúÔxÀò9Ï7œ¡Ş:¾¦¸–$²eõrDßCâÅ’üŒ{hˆÕªâ}²f½4DÖ’ş^«ëï76Oò…¦•P¤ƒ_ób”ò÷}Å43‚de÷ı²ÇO–¨~¢•:™²ñÓÍ·õŒ8®}ûû—HiÓgÏy¯Ô-›LØí„ÊF—ÿ½…Ã«^ü¨û$£·qhO²õGÈDf¹¿¹fÖŸvü¾~tHmPpÑ¾ÕÂ<–IQ¸Y­dĞäZb#=M<	C³…¥+Qå¼a]ª©¶ ŞæãÃkÊ
Èoå0÷êº$¹ÖÚføÛŠº/FUnŒÌK…L!–½Ëàn¯DŸ¹é„/RÕˆ¯2Ëº­~í/u€)FâÊ[‹yÅ›¶ãr¯Ûè_ô"/†]™
¹h¾Z¬®QS‚eMo‹³v	±RQóxú-AODxX¾Òo…¦‚]qGJjı…{‚KıŞ«şı(QbÜÉè´`ú¬=ãrîô»7çx–À4ûùOÁàö“œà5{E£ÀÂIHVDÑİ„y£ÕíçW“Ş·" ñU|…‡ZY,ä¤tëG°ÒÌ’‰3İ¸.Š<=”cëòŒ<BOg¾¸ñÄà®—„‘¢¤‹@A53ïGEØãÉJÃä‚õ7‡cD’”çA{·½¡Î¿ë:|ºH ‹`cĞO.²‰’Ç&sÏE³€T^dÚ”¿)P€õ”èú—¹¨ÑÊ5¯f@$Ã2>9=û\Õ’bÙŸ G¦×âY“­ı“ŸÅQeÿgs@¿˜†–lêÓ+ôÿ½Dqüèáá{&|©ÒXÆ*ÜÓ!¾_/M’Áµş‘“X×1PP–ÛåéikáĞ/-"G¡ëY½ÅØ§Iİ¶y?Z&mi¸h‰*!kÖ_¡Q‰Éú0Ü×#E#Ğ‹î¯Ü3˜ª–Q!İ}ÆØ2ôpùÇ^Ê7EÓÍU­hß¹DøáúÿAŞêâå Œ¨Z#êuÜT­.ÌÈ˜Öëè»3ÒŠ'‹ÁJÉÒF‰Îj´{‡·Ñúñ‘zi|yõPsˆ¶ğeø,gj~øF®„Z½ÿVö%%y°·Â w|¢që}œVVí
­F¹ Ãõıi÷ïƒd	Ğ†qïÆpÛ§ÅJŠŞ¥†ñ¡
âP±$oÄõÒ­I\{†æã%i¨İWIµ`1·—¶¿¡°Hâ—ìî§ñã…ZEK+ãQ0|iÎ5ŒşÂa‘øÚ.·p7 ‚²i½XwßÌó‡¡§»ŠË'¬3.éê?tTl¤ºñYƒè3vzf)†{L­ÂYĞ¦ª·GSñûç¤ñ#ÇîövÅnj†,EQëÄóH­ÅËFt½èÓE~Ã¥<%6ÉğbTuùÕù@YM‡‡ˆ"„p8-V 	¸êÖ¿×»Ãr†/À‡+u›<|q3á#À˜Å:8ßoZ&riº¸€¥ñZV¸ÃüÇ:¦ö»v‚ÒÏ©ÃúRÆd¿Ên{µ7‘ÍsGÛ9æ0T	ø&z ¢ŠœŸg7‹A}ÚH_æë×æxºdM'±[¶?3*Œ©}¯wªxµÕ7bóªÉ[İ6]`ĞäöÎªÙB2~ˆÎLÒO`ã¦n£oÕh¨Ğ?T~rlĞÆ'Ö3ÈŠØ"¦\†·µ2Ø5Ú'æ¬r‹gäÒÛlù»Ÿh“©%pòìØUŸÉÌU:L£c)yYLëHşvƒ‘l¸}$ƒlîÊMşvEĞ¤×BS|¢ÆúïWVç†UMÆ!HÀg5W­Ô³Pîş'Qüî\±ÉÅ×Òü6’é\œÒİ’æXë:‹{ÄœGÍ áwë©.¤Ô˜ëDî:…ü9çë·»çØgòW‘õP.ì•>8Ä4¡
Ù®IÆøccSĞ}$[rÍÓ°&’IqÒ¤GjcV„#ÿèÿ
åk3p©‰Ñ¸É,>ûI4; fÜ£ %¬dƒlÎÎø,”Ì(sºá$Œè½ß†ìR¥PDEãÒC’ïVf«±ÌÈç©g[HÍ»¿s‘jàÿÿ’x+Áz£š'Í(ÀÈ‰>ÇjfÀıQ§+ıĞ&¥Îö£ö‰)dGÀûëÖÂ5	æî%ÈZ¼åî«Qëf[šË3ç‚íö>ŞãRÚâx&(%½ó·Bõ™[°ò$^åaê:! >ù*…ìÆI€RàHôEİ+	2T2î*=šqĞŠ7ŞX2gıäYà ¹	 +¿Ã…¦–L3³³°¡€3›K'ßz×eNÚ-€ˆ0zU&\ÕWÆüÎM»†(çcûòâv›JZğö+®hÉ’ærÉÖà¶ì|.5³ô°,œı–ä­²³'§=<—OÈÚó¸k1ñu+ĞF‘İâòĞı§¤[EÈXŸxuÔ2 Ö¼mí~m3x§sï<+èùRn,\C½t¼ßå	Æñ&_hK(¥úÕvàïu.ˆwTŞPhiú1ãQŞQMiáW”ŒZˆºôo:Oá¼·I¥–BtºÒ‡ìh^ÿç·¶šEHæ]®ç[=¾5òú_pÎQÎíşúóãxÄ«ª¿Èüç*›ğã®ØÑåĞ,úò—~ŸÛˆS~ßÓâ1"º´uìNÛX¤¯¼uƒK>öô3T”„ºãn¾öÎÇËÿªy7Q7
t|â¿!C©z0!í¾3ı“‘çv
†»ÅYEú[ı!ªğ8‹ŞÛ¸ôÅfÏŞ›ãÆQGE©N™Ú bµàÉ
³ 3ı5†¦
2Ô…çŠçt™püî=üÃÇï)™hÓÊ:psSİˆÓ¹J,×ÄTqãÀPD‚¼âPux%Ò`³Ğ6GVEYóPÑ€&¯ihq¼×ğË#ã–46Ëc€’‡µ¨û{Zéèõ&ë‚s›S–'\~_êÄùp#j„Ÿ	bæcV‘àRN7 yaÃ;©};E§‡~™Éecâo¼9÷†Q¦<ŸœlÀÿMØjEûÌ1“X…}s'Î¢L…Êì\"< ?rÚF’•JËEW0ùõ¼È½ÏÙkb¤GŠ£"lq4¿UQÖ/Ãê<ÀnB=ÕüW>J3úfÁláòQJ EÑöÄÊİuxót>Ü‡÷Kö ’K:5V5“|0‹?ÔLßò„ /¡ÌÚUèh…aUA=½§ú>*Õ§CIÕŞÉĞEËE5çÔB§&ÓĞûF“ÿ+ÿ¹ï¨Ú„_^šıl*y4 Ó¦æreÑ.µ¥[v;aºË!Ğ4œÄº¶Çâğ‹v	éõà=D@¥7÷WÁšÂ‹›a15ü¦,Ø:;E-ÓkB1äÚ­½TÌ[åÕXÖ-.M!ÕÌ„qk ò ›ìFº	ˆëÙ‚Ô"K8Û/W­\ÒúÊ÷°utG9Ö¦Ô˜=åç_&®YPP±¥,­9d’jĞÎMŞ)·âU€4©:hÓ~
O|¿)ãfğIÌ²¸6Ïƒ/©ğÇó~J`c•j¹¤mt`%?1§	R‹àş¾ÿQh“×úÛ@LR…4:«úå3ëı/h‰Ÿà(+p.¤¥9«íÎrÈè=‹1´)[(†,Ç„<p%§˜J…Äç±ØÊ
<0ö¼4kÚ‚¯´ÄaÀbİy )'ËÖd<-¥ A_^a/ºÁ7Ó6ÃÜÁ¥2“$g¡ıÉPlù‘ùn;ÇÎÿ>¹æX¤âÔôZĞCÍ¥­“MË?¤<Ç°ÈP…„>%ƒ0É^=4LíÅ[Ëš…V\
lî1oø œh+ö­^9ö ³ŸJfƒòÙ¬Ğ&“.ÿ¸ñ’
'€ØgòÛŸ×?šùºãª>ïe‰åÑ9–±ë_	Ñé!@¦İÂ‘	ÿÿÉõÚ¤	3§”ø6ÊÆá#œAşªÕŸ##;7@¤ª¥Á‘úª„é‚kÑ0p±²K8‰h³ “ŒÊc’±™¼±óÁìê¼™ ·@ëş7“ö|Ö «.¹¨ÔÔVRR.…Ú‘r0Õ¹é+íf0µ¼ïë¬°¥A•x~ÒÎ»eOeÁĞ0ÅtÊ8ïz¦’ Õ+é$Íkô>82s›ñ××ísÄÊ!9Åø”ZôæÍªzWÿü€Ÿ¢b&ãÖØe*½o_Cßdótåw{-¹
ša9i–^.%È×y ¬ªB¢s¿”S‘UF4¢ø~Å"·ôf–°«¾÷}vD/•i!Ù¥ù6ni¹‹‡’Sêé= à·IŒù‚üıi“ÎPxË4p$9b®T”^!ßÀáBl¾=Qğca3ş/OÒØJr2¥><Šqz-+O/z†7Tic%Îø¤b—‰;ãÎ'!â°½ç£6 Î±`¶‹8ˆnâc™ó „×]jêš	f3Š	şÌJ/™Ü¿…^ÅÈ7†ag=4-›?Pø…gÚŸçÚØlÌjó•çª*šÃëåúúúë\Ö,¸ü#Fd“ñË8}­Ôs*ç¾õkkÕj\@GEW¶	U–ª)8ÂfªtØğúå|ÆÓ°#‡<éYp *­œ­ºpÛ“=½Œl@XÅSÆôh-FzÍNs«¤©ÆP~XP³Á½@µ»ôñ&MT 7%‰±'÷!Tò÷3x{u$$¼œ¿rJŸ¾
'søˆ; Ï¡@Ò.·ÃßÁ‰…¹‘B#aôgÇµ–Y;kÃà›8…¸,T!Ğù°ÿÂh	4nAº™#?ŒqLØcE@Ù[ì“§½='Vaù®òkû=ÚUıïeÃ•Ø×è¸2šÚİÑ+@ÿ \­¬] KŒ\¬9*j °N•]7"ş jÁ¸£ÏŠ¿ÌnŸ l;@Ÿ.c>N£1ó5jÅÄ•êÈÄ‹<@ÓäVt¿ƒÁåYÇã_×Ò>š[}×íÉ3wİ¤Á;İ@"Şè
|•§kéfîš…]W+­Oùª|Nß¤Ğ…]ßô¥p â×ÑgÍ˜»bx§y¼io?3<vúÖ¿G$BÑ@ _ÌÔ£ÿd4å²ÆBd.“•™÷=ßmò!ªŠîxYmò¶8¤c.OíÓ¹`¹Y 5=PÅeGhÉşŸB!*™1‡Dª!´fÜÿSúU…±,×ÅÖ½?ØÉYJm¥bã˜u0hxCsõ¢btòU¡dBã‡_õaŠÚÌä$g[åÏ”WËø£¼„€®gçxz™ÆS¯ÛÚ—¯©ŠTÏ`|–áe‰jİ‰¼·yQ|ƒ1Êay#YŞD
 ¯ûÀ”,+¦™iM¼kRHeÃF‚¬=µªl„Ïmsèáäu1ËƒPŸÎÜ¿À_oéş£»àeì‡«üMé÷ôú”!©q¥wA<ÿÃ8éÆ&ÎÅ¯@&Ë_Mºã‚?Óà8Äİ,‹ıæK•Œ4?øü¬ğa+!`'W~Ï5ôskú¦!Ú×/6@Ô©Ú]O¤6g¤6¼5ğb<öÌL]_IÚÚêüìXaûÄJdéì{S˜(›Ñr?U.}ÚXâ‡ÿĞ(àç[Û*O?Sv‘‹…Ë¯H·Ş—æ(mÅ… ¨h‘Ë9Š¦Şdı ô~eÁš">&›)}Ã7mÃß’eÉìŞb<]Ù÷n;£ô\í¤9)Q-60Z§vGOßÿ+`°Dñzá¥$jUáb®Ê3¹âBÏçFÍc±>¯»İ(xƒ\İƒ@Şıšösa}xëÍ›#‡Şn4.xmÃ“;
ó	xã…Â(£²Ñ‡—±_2^¨ĞÀKÜıAwG4Î:¤]—?tÛS9®ÀôpšpšÄ¦¿ªmEÑÙ¹EVİ.ôõCª^6 `ÔÖ9€"îÔB·üßÂqÂ¦Ë¥U¼ò
nT©—k…É<xÓˆâÖ„ÑFé)£™ª«,ê¥¤» Ç	f— Ÿ	óAÆµ˜éDn–¨ŒèòÉ²„½iAñ××z9[‘&ª€O3c	ò~ÉY@ˆ÷ƒ_9Æ3ÿÃ?ïÈ—À¦›?ıy,»U“éq@J1?~BÿóÖM”j°¤•Ï£é#QçMòUú¤O<±.%.íR[B3–$ãTétF$ÎƒÃr½Ì1<Ú*n2©uÔóZ8Œ%X@´°†—‹]td‚µ'O'9pô½Áí=+5×2"”&®OvJn¦ìKuQÖâOú1Ú’¦ÿ¿ê­x0ò¤	ó££a¿ƒ°¹ ,ˆÌ…- ŠHtœs}Ş>iÅJÃ4,CÕgÀûÿ«dâ”şYÎB	ˆ‚³.Sòp·tŸ9ÖÜ`Âr{×
Drì\í}}èêÂœ“b7›Ùx°¹9å}Èäy1H1ÕN(¹®iéxZ²=4ˆú]5ùƒq5e÷¼ŠÎ?Ñ`÷4Òø„u¯#Ôt@š¢t{êgfï¼:µô„ÂF¼vé=éõ™ŞÒ™]OÊv¼Ä	!¸›øH"e…BÄõš\O¯„Éú¥ÉA,dtƒæàÊk
gZT *]e
/4w=Ñ¶ÁF­hÄzJÃÌ…¡ZK"ŞğV`ŠC<¢¼½Áü¾]Ã‹õLÈ–`ìe¹ÊN3™ßw¡ºaE}DCŒ*ly¥8?2Ï&é%“`Ó½%#<eî€ªTWˆt²îø$:Ö\BÆ×ké_Gm!#¥ª—3z7ydÕùè?3ÚN”íú.1²¶ÒıöŞ5læyŠ,Ë/¼»Tjv2q}‰
Fy(Áîïíµü¦Î»Øx›0çôûùk?œ¥ŠÍ)	¸®†+0ƒ(`\÷‘­œ:^mç4:g7P‰(yˆXÑIêàÕQĞ¨²bU&®gÆØ!Cå{¾a7ûT•‚½iØYO5õ\p'yÇÔ,Ì¥RQbjLHIúPX5¿^¥y5Ñ[(¦@Ñm·1
™û’ñÕĞÇ¬‘yçÛK±”Ò7¶YCûdó1Ş‘k³ÚHêt¦»ãÿ²ì·Ñ~.<L1D»á¨@‰Ì„o1†ç‚şiÎ«›â>ŸÍSdÙEG£Öm3®ûÚ£—°é’ÙÙËĞp<9¯ gSbœ[M¿½º?¸ Œ‘^rU8öæXKuK2,ùPß:˜àŸ}`ÉMÅ—rõÎï«²PöÅ¤Ã.¶Ü¾¦¸%‡zŸl*w')[¹ç/7”ÜÜiòÇ"äs4"<èb•­œzuİlBµ6éÀ£”$ÎlÇ®‰õÔÓjàŸ‡8°®÷&P]=¼¯EŠŠ3‚x¦qWÃrºÏtMÌ2 ¡ü	LğÊˆ®?­ôšä¸ñ¼ŸUµ[±D¦fèµù=n=LiÖÌ›£T«µ=C°‚Ìt>?»†ï6¾á—‚eKÉË’Í@*‹+Â„í{•±®klíŸÇ%»ÁÀc7>úåØÜ•±…÷ßVˆ÷LWÌÁ¯˜çËº	‚â%«­_~q…–{òsg|‰WM"¨Ä´LÒåãŸ¦C“¿äeUe£«T+½å`ƒÖ(šç“ÂOİëVS£‡Gˆ3´K?d¤0e„•Û¢ï	|½BÑô2í`/MÒEf¶×¯Œ7#‘}ö
˜`åŒsßãÑ­>¤¦äü
fÉñlíoù@^(ù½ğ…ºà8F¯† •÷¸Æ¸1pDÊMèí3Ù”úË² «€
$¦5y½7'©kÉSÌ6VÊhÎÌgÉ¤Á#M6­\[_ ,›Â†#å	 ¬EOüÄcl¬•W#ØÎØÅ•9¯&
¬6ª©Xƒ+9ÈCè—6Á›P`È½¦ÇØ5-yáé[#‡isµ¦kîSÄ˜*DC†üiâFS
¸TŞÄLWi6aV ıØÑoıµº”ÏÉ‡¾^»× zúºl ¥HòŠ#ÉáO<ÃïSÇ¡4¤§uŒ_Œû¾¿€DëT+Ñë ƒEK(o®ø0"-®É¬ÎÓ=CAú9ÛÔ¤¤è¤óBsi%qTõˆ¾{äı`Éªéwì¸È­e€QÍ—¯¦CË>õJàl0,HæîG—k„M]{Ó®İCM"ÅIˆ°‡^P p}Oé¹¾‘ªë¬¿ÙğT´Ã…fˆ!±íbN°.í—1á…©SÖOg2š)¬Tv‡ j8–bÆ	d¿à¿q2ã½6A¡ù—©z’ÿ0Â¿®aS1¨ä5¢p®nÔã¯èiZÍ9çì‹YÂ¢©÷aâj©–KŸá±øxx¢<‘ô&Ò4¯¼íĞ(¹NH‘n€ò‚\z]ÇÆşÊ¹lù´œ‘ÔB	nY‰öSŸıŒfÂ8Tñuwö()¢v@È<R×¤éÑıØÜa–Â3)FÏø/K¤=Kƒ$È,‘Y¶œä,'f¬ûõ2R»X¯Ôyø=ÒÉG¨Vù`½|*5Ç:§‰f2ı­€pd÷©?ƒg ßz°ºõ°cTøS¬ê|IßLmU<"ø=‚y(PoúÃàûr³íÌ:À9„ÓåD’¯?Eú!¥b7'âİûŠÓ Ì˜¹µş¾ßş`Íj$i13¢(åHŒbsAök÷bĞ¿è“XLhèà0…?rMcŒÏİK­£>Ü·–«ìÿT({@¾Etaf†Zé/8¤bdæÇœ2/9Û$³ö$R}›NC9Ø÷º èáZwÅjAügz*5IQ&ñ62
ßiCáÏÃ Ê$9?¿ÊH§qfÂ÷HÌk<çà•œ3Üı)Tdï½-m‡<•,õ®?`¾Ú4‰LÅûLÒ ;+ì›(€c¯åš¨Ï2·}sV0d±3HoÚiŸıb‹ˆœ­X‘mV5ÌK’FîÌÇJMG/J/•rIË¶ıˆşÆÇC›$ Ek[oAİ:³­%}‘‚QiCéJh,÷öFi¬õØŞôsC£ÔQCŒíX¸ëÍÈ£$$Ü®˜J»l»½•ædc=
Ö|3Î;^±+°$Ê¼_Êî¤nAáJòR²ÁÛ©ZŒdÌb¶’%«e+Â÷i,¸‘È$VS°nºÑe¨øî_Ú©&Å:™µ|àUÃĞÿšâÊà‹_µ:5’Ë@–öúëƒ‹ß[Ö)0Ö·WAB20W]àë‘h¢™’'a4©¤=XË-ú"ÃÀjÅ%D&¹¾åeÅn:Ø#·ªƒ3y•êsæ’Ø¾Šl!´ØĞWÅ w¼ì»ï5$í2e(Á¨B¯‘LêÙ7FÙ*OË!â·ª¥:T‰OD–‰ÄdıéÏ
ØXìÂyÖ]¿T²sík\Ö÷ÜYÎ(ıÀãÜwñ!tJ 7CdmÅAÅ<ÚİâgØúÆ»Ğm‡I	{AŒ¡ÇûòÊY÷‘I ÛLOMÏb|/¿>xßuŒ#mÜ°j.ÃÛ;ò,¡õÃLq%ƒÃÓïõËaûìsğóVô>gšÏ
€,~wæ~Ş•&2ÌÛw€Èa¡Ñ´ş÷³ªø|V-¢6a§ØOµHøÙ(1òâ›ëWjJº7Ó‚±bô[-Â›ÓâÎêo&+p·Zj6•¿»©fƒn»ËâŠRiµ|ßw5-,|H]Ê™·»§¿¹¤€Şu9>úÌ TëbÅ»NL^JnÎv*1Ã>N5³­¬?ˆˆá~àL­¼g|iË˜ÍÄ
{ÇlBSD^§]@0‡™v  kí1[McÓŠxäú.<9ç1‡bhòqWmçÔ+…C[ä‰$„tæşû‘I‹×’€XşaO‡,ıRQ}O7ZUº£yFì³äGÙ\Ó('G±µ¥.Q#Oğ~&>ü>Sì$¤ m/ÁeÑ¹Æ3â]ÎĞÍP€H5Úô'ÁÍfiÂXHå ´ÕÀåç²4²|¹8B¡zZíCp¶š”#ùa0ís İ8jé™}äÊ¯:{7ˆu¯Ø`ñGc )¥-‰/úE|ï¯»¿ñù’¥æÙ²ú	$”x}(³½O‚Ö<×ø®ˆ„aŸr±rSœ¡cš¤¶pÚ²åØ¸œhŸBÁp÷âÄ¹ÉfMÕ 	íX0««ÚMYby-s‚ë¿İ!˜¿|+&ïíZE=ÇıÖïy³¶!z¢Õ48zYÔ÷th†‹¥¤n´&Y‚GŠ?Ãß9Ç¶g¨iXdZšIÅëXÙE‡:Mr8…YÏx
nE+GæùŸ}%¶D‘Ê¶òpm ±9`v`A?E9èf &Ï<ÒÜİöî¸q	6:\'§Øé¦q`“Ş¿w§ƒ†˜K@0jæthŸ µŒáåœàİ'­ì£çÉ5Ó’²c„ÒŒ$Ad_3‡Ù“ÇJ¸!e—÷ ©i†À*ª+ÚQbˆı»˜ÌÚm?Çf$‘Û}~tpØn=ÊIy3ú80rT½Î—>ñ»¢Ù^tgİÜ$Ì‘œ£rœ†á(ÿQÁ¿U¿î`-ı‘ÏA÷~ü¶\Ï;ı}Ás%³QñA¬yÇê¢ËS:¯äPÓ'<¶Ã'LÜî«õı«·S{ñööl:!ªğƒ­ŸD­Ğ¡/š6ç‹®,ÀbxMú‹jğ‰Ì—…Œäå«’¨¾Şïª«D-‘Ksä~+åÜÃôruÙÜ@Œ‡Z1JÜƒÌ0ÂQZKla@¡¡«-o>Ê?í;ìÅ¨EÑH†ê
FØ!t³òñˆl@k^f®şö­AŸÛ¯Yÿ@Ê¿uÊ`p¸B¸!	÷sïäN¿‚~Ò,U4mÕ÷Í80‡ZO3i-p‘­ş†°yEÅVLõ ’$™çÜL£âËÁVfõ½rãéc?LŒ< ù¦wÖ Î¸Zí4§,‹ßµüŸ)r£A÷v'V®Å‡†Vfz0a•N£ÙzI\á h>F¬/ÙüQhŒbºTaÄQÌoJ{5"7O;#Çù/Òº0aíüN·ıëêLÇeIÎÄŞ[d™Å¢ 47¶şó\-VxuëºM"LlÃÚíM¡Å(3"¦3(~u\ˆ&]N¿§DÀœVñ6ŸhW²©°)YZ¼}*Ñ¬^ˆ©$ÏÂ÷ûÂÊÛëÖSCî\ØP<[|÷Å–Ï£F#!¦1–
‹9RDÆŒÄ˜éHÜÙ´_‘åÒ
	0W·0§+ù ‰ûƒ>²*Xº»aHŠWÕ-Ì“ŞUÔPİ.<wT$W„æl¥…ªÑ=…¹\+®®*fpG.â‰ù|eAøÿeJ‚7-Ñ‹§_k·~E¦KÎ~ÈêØROf¯XR}¢|Êîí±P	Ühu‚‘æˆ|Ÿ5¾Iå³¢ùw¬ï¼-~×2™Š‘°Œ‹;R1—FŞÌügŠ¹`â¿ÔÅòĞ@ujX@P8|	r0×İ¶(+hŠ —1_Ä¦ºc\OãOh½›µC³pè7’ çï$gE“..ƒXr –SEj %SÒËÑn°½„èŞ6éeq|9÷a†ØÂ'êã¿aHhË’[b¿²k‚,„¤Œb²j—[nhà\©ÿò÷’óêB%#F!Ïãs®²Ùã´¿Ğr“›8s“ x›”‚ÑZ|¬|€¯°+HR€£¨¬”ˆ*xvœª­Ó2u¹oV?"ÌéR‡D¸°ÎÂšß•¤P‰Ñ)EÆX…zÚi¢,ø$±ĞGi@]f›—{jdªßÔÄÊ>Bş
Š7GŸ¯–¬ªC:¨÷ª™ÓªOBÔÒ¬®c±ÿ6ìÏ¸¦ËÄ5ócá<WÙ©¯”7Úü«üâKsÿtÂ8°“]ÿ‰§@¤r5t¼FÈ®İšÀ8p‹b÷t9@[ÅJ`‚m5l5<\o2€LUMÉÊÂ-ÂtÎïj+m½3µ5_–´è¯wj¶Eh0¯Ì±<s^´:6$ø’Ï1O¬ÌeÕ›¿*Fƒ¥‡‘.*»qÈD¼T˜pÿu9Q2˜yLykYLÇDfùeÄÉ#Œ?‹A+±B³iÕhbµ›[¶¶´sû†t~< Ns'ØB¨4O¦Ë•¸ô\ÑäİÎ„)eöqDŞ©hÅÄÃÑğ*ÃŸu[ ¤°Òu¨%?Æ}ºEõp“ÃK¢“&{3Ğ¦6Ë„ÎŠ…Ñ@šH{ülSçñ'T`³¼ŸGÛD¯¨Ùó³TÂtæ_ıÕFí- KOœ˜dp5%¨—y¡È;ÚWw€øln¤ a5+Ï}­ßÛ9,«Š§à£\NÆ›â;R\Ü`O2ÜË§õÃ¿Ü¬åUCıçıhŸı÷@õÉ 8LÂÉSÉêQÇ²&»¶¼‰‡İÒøÒ9=·Fªºä~¯š…ï†ÎÇ+çU¦–Æõ¢:c™ÑJ‘ëRn0´äÑß½ºœ$BŒSgr8·¶„ä]ó.¿5Í2Ò€N¿n+òÇ#Ş´šrÙ-{ŒĞ	¿uÀ#8ƒŸØPâGÆN:8|+g„ãd39Ò\˜Å¿N:¼ĞÆR½R”Ÿ ¶S]Î`å•0Íf/c¥qp‚ßĞ¸tS}e™+cf©İsÑ<÷˜Æ
³ûÉ¬¹|0“écçM:;¡Ÿ’uJH3XsÈ3¹¹Ù­F¹HF¶-qÌRØ£êUÙšƒxä)Ç¥Œ§j¢Æ,n21í—_i’°˜G6K°aXD¯(‘»#o°¥Ø¨âêUØı=”’¨Äş²#¦3€¤a©vÆ?`›“€uÂÅ¡¤şı?²¯>¼Å‡!Ô17½ÏòPLùİ‚öúñßB„¹ñ¶ÌÀm¹)æ¹ÃüÙØºÃM.Ô*;¬âŒÚ˜!ÄE´*’¹IeM—I™f˜t?Îel»V˜,«P©‘:rÂe½õ’±—”A)ÄåĞ¡ıÓ fëÏk;ªíÄùa°g9¹™]ÿÅIh 0]3ÙÕ÷İˆZñ©foFAá„Ñq³«[(½ñ9
œ›¥{Ã`„åƒHj¨ëà¡"¯¼ÖGpz˜è‡Fé»mØurOjfT
²ç<ÇÒ½jáñ;Y®5šá'^›ŒSE÷· =§ª¼j(±O¬EœÍ3®#„÷˜_•ŸûaËhgT\‘EÊHB÷Ø™ßë9ìõö+ù¹²û½¹ˆÒÇœk®\<û:HÉÈ«‰oMÓ¾+XúĞtª9•#PPÙm´9PËÙbás/z¼%¾j9r=Îº")·
5Ù\OfªüZœâÍ;şÑETÄM9ú9Ÿ39Ÿ¹CÂœ3¬–ÙÃ[ÚıDsÄpDà0¾ÄØ•µ;T’'p./dVâSPÊÑ~çÛÆ'i`#f;âŒ®Ãšàš™©İ²I¿¬¶ïgÏ€	 î’\¬Êÿ|1!Fš’TıµÏö_fk2øÉjÿ0oy^òË‚`¨»sµ"‹¢AÌ¿PcÙe±sİOë“wcØ°à=Ûš|ŞÜäVãño®x¾’å¡B¬ËŠ£˜œêÀ„ûÓ•¾M=ê÷µ
ÔŒ„ª‰Ğ=øHÌ0Ÿ`ª5¸¯a[)P( ”€#f6@àæKáÊ¯pLúƒZìŸÊ˜»ùµ(0M”Õ¤±w[¨4a ÷¤“€z2bÕÃP	v‚Âà¹†šğ`´€olF±¸1qÍòşw«ôE^¥ÖéïÕ“N·v†Çñ,idòı·Ìãâ
©Î$ÑòÉ»×3,­*Y&”›ã-î=	;«ÿ!Ñ9ÔÒÓl¤L[úõ|êBÃ}ŸÊS8)ycäúÁ±®š!-Pr™EëSòB¤?gÓ…iÊYd"°ÇÓïàân=öÑº°¦1“¬Çq@”w¶œ`¨û7s;p˜¿R²Üu€çi¥
Ùş£bmªÔHR[€nIßª]6Mâ=á”?š¸@6SÇÙo´*ÌÇÒ–hœàŒaOwS®E÷Ös¿!•gPrdùÅ¿’\Kv‹q[4ÕÛß*‰ğ øNB¤ÚßGOíS`N›¾€ÑsÖa?@ïĞ+ëÈhCĞã\øüØ;÷Ë„ˆ#ñ1P©$òö¿*†ÀÚÖ’"$|h†DN×‡÷ÅPÿ#3=xİ­…Ûú1ü"ä`×º·ÏI‰j¸¬b+Ñğu8œ28ß^üëjnt«ıqI)«8—¯vÕ1 +[y5˜ûX_Šù^1Ô7ÓÌòà}£zHöï.Rc!ù¥é‘jÅWëIaF¤U`²î`1XW—'üÚ‘èèJw~Önc‹tNr="ƒ\Q-¤0æºÙ…şür'e_$ÕñCÇa u¼¢Yß[
¹¨óGk¦¸$®ºÜ•qÀRzÆãó‡9“õğ/İg(yç£½øÏfàQØ0Ö¾–D+¼ûù³Ö†	—ZK ,yßG€HøÕ8nùJ\ñ.K×Šc·g`Ñ-ü‘n^dï#{)L‘"õ•Ë”vzMğp®U",¸[çüÊ§â¾vöŠTè Èğí>p’8Uü¹°*!ÅOşl/Qı0Ce®Šb+­¬Æöam5i‡Ûjû+¸âõ^!uê·f<)æúúû¶eVçêmªîS8*Y¬G¬Bø-	€ËÂÃåyìÜNeè%
Ş‚#cKÔXò4¨	­J+zÉì=l;ÉQIÉv%Ë
–µ}]Ã£ßÏIW"N´R$š#Üµˆƒm°{/–Àö²%¢åâ‹ç39Ÿ°~
®¦Œ4¨`æOÅïT)J}±“/{Á¨róægòG½Üœ§¾ßßi§80¥İ—p”+Jy]
8…;šVá'«;qâx´SÒ+2sêÜ*h2Ñ®bQp1÷3şÜ8Ó\º–ŒïFªhİ*ŠÉ›µÎ†«Ön÷ÙÄuİlè8]“³%ÜŒ_·“dƒè¶-3
ZØ¦ÅÜ¿š{ĞP›ÔW¸vgXX&¡ˆ¾¦#´4œEG8E.Ÿ#¤Ì‘V#Ûuûk¾„uƒ<Š«l¯EÈ—ªiEüéÎ¾¿4úËÅ{“›‰œ-”ëßŒû*S"HM=iP8Fšöo±e–ú¡èÈµ­xáJ¼Ï—Ñ9l,N	s²1ıÔ'¼3Ò'^Ã‹g²R¯¼F8õ ‚ ’·‰IÄë¾ÚºŒ_<ÃE8CF70üï$œ_¥FN Ü!SA|ğS§•ıĞğKÂWØNµ+j¾“õ.ÇM}³³5ák°nQ&>küï–˜¿4‘b– ­ÎãG•:§×!÷{Ã|@ºÁe*Qş9êQÃŠSPŒO(u’`+ğÃ±9Ö†º+ÏÀ“ùœ[R,ğ.CJ8£YAÄâæÏà±_£Îm[f­!8';E&2¯¡áLy¯å=ä/Œ–áÃİ>á’^çÙÛéœ}
wÉâ!©ûÁã÷iz$±„ıÖéJLè:¡\G)fE(Ì‘Ù»âï´é©ö½’†m/Ÿq3““Û8ÿ/ı´aD…é›“X1Üºxí]3PçXĞ$‚.ğf‘ÓÔœı„İ¢<w½fú=‰’ˆ£8¶"«Ÿ½¿2zrÏÔ2O¤ÒÿFmIås­¥<kƒLaJÂı âÑòÅŸ®…İš´‡*«I3¡WšŸ#Ú²SÊÒ\,³»9Ö}4¥Q¾PfëLòñ„oó'¨Hs«Èª¾¦á|Xß¤!Ö™X„…ÃGd
®=ZG‚í¿«ã=p·ªb'n=½Ïld(Lÿ>B*”’BgÿOèƒ×Û5dàCñK ‘í²³›ÒfäÂ¾b{§ıX3$!¨ª‹‚£…3Ğq“D‘ÓCÅÉãP®ËÑú>-=ÍÊñŞÔ¦j¿Ã`î‘´®úª¡kèºr$
ì™`7^Á–y¼T:6¼
¥ŸîA‚ì¾Íq2æˆÍõ6ŒC~ßŞ=‚¼Èè†j…_;7jK#–¦€Î—KORşùûH¿ º¨…§µÕ¸ÊAô{*Q"+ÈW<AíP?Â—Äöì]"8NîÇ¸·UZğé ¯V„ÈlÂ`¬Å—¦Ê¥j¾·5t,Ê1¾]ˆ«í×ˆÚä¢×Ù²3ÌÓØq…\t/úùÉ¸“{Õ@¶ùy¾İÀÔÑù%{ô7JÅÁÿöø>z¾EğJ<T(îóŸ5WYOïW°ƒÇvØĞ8Fv= ŸÒ²ó¦XNÆ2Äª$ıóVÏ‘&TóÔeú$¹¦„BnŒ*¿µEµæ™YÎ$MÌñeró1ÏÓ¨Å®0˜¥ÔÜ©çLxĞW|$tÍ…hG{ê4.FùÒÂÔ–]-.YQÖWD¨¬ÙgN–zµ,ŸE¤qğ§Ñƒ£šûÎ~‚Ûò#Ùƒi<kşÊ€İÉ…3Hª™ÌŸùS$Hxøpƒ g¤¹ú‹P1ò‡Gš›÷‰ÿôT*“•N\ú·OMs%™ ó$Óµ|,¾h}%ÁSê´Ô±²0q³D?ù1ÿ|&1ƒ±îÂæbJòŠ4¢u¸Ó¹†fE“<+ N“2dÂˆ²¤—¥+zc.HlÕ»ê¸åvÆıPP˜¸ ¿Kù¹]üx&RUoà‹Ä'kñ?X³uÓBQ¸WÖÚ[®G 4»…
õ¯mqĞ(º&(ÿV¿‰ÚuÄåPA¤öYŸa»ŠÆhÌ´jÅ¿°¶Á±g¡UYü¾˜‹¿˜O"šhUüeâ¾ ÌîLUâWÎ»«v†²Z’$A}ÂŒ¹`Å4›p@×û\uEòÓï M¤½Ò2\4ÉqÂ!’Hsî_=æSöçŸV”ñfñ¢„ÃÙ7Ï¦o÷CF#~=À0D6ÅÈö½Îì6äy•Å3hxàR©Ù%<†ZGf¹#eâÒØşºjAªkf†µÏ¦?!n;Sü Ïñ7¬»ÎÏÌd§}*ärŒ'ÍğFãşğp“Í9ü’hR”¿ Ş2œLAUç,pöa/5ôí¶’pöY0Œ=mô›>ZˆS+ÕØ.$ljr¹îó i1ÀjïqÍØ’nv÷?çu¬ç­ùkk-•OÓ|Æèg’#yBŠC²İ€ËX?Í‚øFUéz&/¢™ÃÕµ
¶JU–ZË#İ6»)äÍÍ^,Ñ–¸=†FZ@Şmm˜óŸæxÃ¨cI;.³‚õIù®ª/Á`N³ä  _"äÊFQ(È ”µ€Àä9’‘±Ägû    YZ