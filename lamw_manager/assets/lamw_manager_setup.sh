#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1584554990"
MD5="06f5b4474da9589fce7e1ebf67fdec18"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22968"
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
	echo Date of packaging: Wed Jun 23 00:35:04 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿYw] ¼}•À1Dd]‡Á›PætİDñr„@Mıæw™œ`P+ŸÙ	™d]ZQPÖ¾µsVMHÂwÑ’Õ	fOÀqêˆ½ßûÀqû÷3§ÿëÜU?·ê¾'Ø¬Ç7dG -İşÁª‹\R</CPSf'[ÂNãŠ(ÑĞ†Ù†B—»cUÿº½F3pşƒ§;‹àÖ ºù+ÇP$aB9°‡ƒô"e_{\ê¤Ñ¸á÷ıİ¢1XîåEŞÇ­5~¥ ­÷Şşf=Óõuÿ¢+·T#ï(kWc&{²:–äß‰ejÒ¾-‡¨+iñ8/„ÇÄ¡ã¬LùŞP¼æìgkpßÂ5Ë{­Ô˜Q•‘±‹áëƒSvîœsfñ\ñ}mµ_¡{µ.†D5Î·÷bLÛ×Ç_$CïCÃ§"Föªl¶É‘şŠò§ê~Í9ºAzH·M»0Iù½ı¨¶±%z
6ÙB·ä¡D¹sPDƒa\¤nÒ¶ÆİÇmdÏv\=qµ¡8ãifk\ğU<)H¼¥ßöd¢!õ0ŠGÙGjÌ%,Tr«á¾„“×(1ìAÚ@ÍFO_–§¿’V}$Ö
f8€D»£³å8”%§`±Š)¯›‰š_¾SwÓÇ¢ñ£M»êY*+†tè)¦nWSğÈ1Ã>§`êRëÈË€NwdÌÄ–‚Ô»Ì`¶¥~€4SÀ"º,åÒiŒ|Ÿâ–Xº
°tÉRK
ÏüWñ³talX†P}4¥ñë¾‰æ	#ä/Èÿ6ƒ1pKj±öôèqê¤a”d™yh”MëC-+¤M	­¼$$=½lõ‡Õ¶fÀÚêèFœ“Ò÷kú˜öt¬•sW¸§ñJ¿I—Ókrán<¦fR‰¥Îùª§3°c¬^k×5‘š‹—‰¼ÄC«?u¤´¶&%h°ıÿ®o`'İ4uÌ^ i›Ü\iS£|Ú-¤B¦n,c„H KÍ6Õ±r½éƒæ¦È®pÍš `oÈAj jnÒùµº“Gâ$2Äıı,>ìl«ˆ5Eu|¡¾Æ	ãE6Ğ8´náäÏZo>4D4hj¾g8B,@=c“|t¹²½§éÇ0·äõC9û‹ÿjÆo§99×}ejò_ù°ìÃ¾²k’YÍ*Ãxi]ßƒIVk§Ã±£¯bhÖØr;wÊ/tÃ:º+B’Q;fÆ¨àK"ä¼ ·ñQ*ÂWHK!ô´;}7P¸|¿lê [5eÈ§{ O­e´Pº¿Å€Y&VyÓŒ"X™Ã#®Üê>'¬9Ÿõã	.	€üÜÕ¿h’¤â©.–Çë (¬tš»UBA=4wWsûåèõö\´’»XbÎ©1ÒİCƒ–Ëù",_º¡]·Å§›‹z’lhˆYÎ0Jõ‰†z’‘ú<‘]‚ı×~ë”„0º^˜HwY|GM6öÁƒ¥)1¹‹ M†z[EÍÂv—Îpí-Ã([ÏæƒïöÕñƒf¹~Í% %›¸ûQÇ Äd¨ï"j÷Ø÷87TuÖ>ıH@"·d6¿küf³4æÍ•«77Pİb¹›q©ÊE¦]Ò(FÚMK·ìWj¡UÏL!ğÔÈëV‹Zÿ(åùu°w‹ 4[LU’ÅP¢¤d®ßÕ ínóNİÈºùu'£ry/çÍÒ;x+İqyƒô~~`ÄÖÊ¬»õô¤ÂÏ7Î÷N¨Ö‡ĞõïñÚ×‚ŠQj²Rê)r.ì.A¶écQu˜ÁEËª\(>ú©2†á[{GC*Ì»”NËFÊ·zO‘L–]ßËMéêtkñûmŞCru	? Šjø@¯^L@›[â§²TI0lÂÇáğìÿ&k9ÿ<ÑrKÍ`áB$Jfö›£·4³û˜Ğ#xË‰j2x¤HÚø9 åöH¯KIyÖ¨İ¸ª;‡™2õİœğyú/óümÔjù¾fZyi0—+K¾¡5­¦´KJ†ĞDğãü¥\_®/lü[¦GW¾É«<:U$ÖÍ_Ë î×4Úúá5Y¶Ê9H¦iåNE HŞu˜¶'Z‡S't™ãšÌ²<–súµhGââÆİÚ§Š)p=Ô$Z˜O2èßí0Y‡Ù"7ŠÌªÁ_ Rm%{\õ“It~ƒ›=Z¿@£º,~±KPCaÀl­¢¡6ÄÌUÛ5äl“l^.®ë·KÙÏ‰7…Ó÷C9äÊúi]CÈjm%L2$¸5,´‘Pı~ÉT³»rs­cdÏØ|dfÿJA#Ş‘ç›{Úî»‚ÃÉşAÁ#{t¦€§îãŞJö¯b¨> °”¡?Ù®ï„[Rè7rÑ™dã £¨óµWQZYœ`¥bËáÊÓ€áïä_
%Óï¦“>¡ë ¨Ì£4z]Nî'd¤æ˜0LôœÛÌÊÛès:ƒ¯-{Q9œ{07ÄGüV›¶œ?ùfÒT#¨>m·ÓÁšPUYª9âT“LiŒk»‘-—ÄbeÄšuœÿ}mç¡*§ó#@
šÇgA×s¢´c×6^5(-Âÿ6ÉœTT¡Iê\ ªº<]ááÊğD—t¯‰‘uß
×ëJOÔ¿!pdÁo¡Ï¤o•”ĞØ=­¯5rŞO@)±ÎNWsÃÒa{néİ¬û_¤®WwtR+Kyß3Aœy½ÃZ¨ˆ›7àpa2>ùu{°uÑ~jŸíœ6ÏÂ}E›LDBHHéo%ş&§/¾ä(XÒÇ$È•<ûÂ¶µ­İ}™„k®O¼y_Æ¥£sÁE¶‘[Ãİå÷„1—!>…±í[èın*ïÆ¿c"¢~HÒ¿İîüo— ğ&²ÍğºÖ¢ôÑó©×ŞOÅæŸ}tº¿*[ßD„é~SæÓ~Òßıf‹ÙŞ%€¸§¤Ôt×Óªò%.Ÿ)q¾Õ+_ .$a•é@¹;GÌ›³‘§“\±jS‹KŒìŞ^Ÿ!‹ò• »Ì°ğ¤réEïe&R,ÑQeç¤“ÿş1/Ş6´‘±ôW¦¥',Ü„Ÿ¡´yHiı­æ£šÓrÑ
„/Qšøÿáhİ0oßsFù]Ì}ÒyI/9ƒ— Ÿk$Ê,Ê 2(»»œÓ#r.´fşcQüúH~)PÿßÒõ!03_¥¨ÈSúiŠi¯ôğ}Ô»ø:Üö¼!Œ8Ü4Ê‚J¼oÿçP0~ü+Ä·CÜ0©WÈ®DW¢Ôìcíxïå2NE€YÔ0Y8õ°ØSÒeQ‘½ŠÜ´nEf»¼_³rÂáå‘úx~·ÌYæs˜Îğ8ìµW$Hœ£ _kĞ€µ¹±£ĞN‰ I•z¯<©Bù™l?—ƒäûzÛJÆŞ<Wïè¯Ê0æ<Tî^‹šgŠ µŸQ…ºiÂÈRnñYûY-GÜínA¾Àb’k3wë‡¨·â†¬‰!¸}ßó‹€¯EH
©ÓAÇg³ÈÓ÷mJê½ô¢à<³›~?í\fx²Ïğ4V^´şĞ î	âà!ü
 ù°siº®ºÈ2“½Šì·t;ÇYQåÒ¯à5ÃJ¦ÀpNÊ£†·# ’Ø:™Ó˜€Ñ«4‘)¥¿”Ü­•¨Ş„Rz¹Ä.»ØCÌ"õçÙ&S–À*˜W-~¹FPBÜ!í7mœ+äJqU'j¸‹‘À	€líªRãôÀMi“¡nÓ¶¶¯Ï2ÒÕ¯Î¬»}ËÆµJö4Šå,¹½Fn‚¿N¢A×=şÜaà¨ÑLpófC_½1
¥™`<ğ®Í›ÉwAñ°ª>³€m˜«—˜6/ÊmşıSó®ÎÄ$+Œí² sU±×}M¢Îu-=§àfÿÙR^7*u#£µKCÊl¬öphc‹°„LnóÔÖn­pİ‡¿Å^’cêó‹¢—EcM ßv«ŸG¿²AXŒìÔ!‡›<7Ç”'ÿÎÉ¤lxÇÓj©¨¼KÕÊeÊ*Õ³
b›…À…†¡o7L—Ò¨hvô±%—[oS.3„Q‘„$=ÙØgÉˆÁ5%vs„N^ë@¼4aĞ&jv}ÿ«¸!I»’BeÂÈÌƒ2Afnâm÷WÜÓhiŒ|mÈğçf| zŸòsš¡Ô·­ë…P”)Ñ¸]—Æ%;NQò“äÚ
MoÕ¹;SUjù´² dÀá«cx}½µFõ	bXU’\\tò“S“¹¿‘Œç~Öª,ó¦›‰®€—W³­DÈÒ7`ã,”ju”mŸİıqQÎ–„®s<Sœ\Íªp¹¸¿>!1Á}*Ÿ[g¡vÄËCÚÊù83®òIâ×}Ö ÙlæĞĞ] ±äşLğœÛÊ,Ó„¿Œ¹ö+ey4ÒìÙ–î>SiVİb˜;…aZº05ü"8íjîBÅ!Û«È‡=
w`Ó.}#ŸTíÅ—}¤B‚õFéùÛJîZ³É v76	£Ã˜T<^‰C‚€[Q ÇI/«õ¯é #ûyÀ"ıÙFĞô{`¶åGò¨&8tL«-7ë!b,gìŞª3e	TİŒşÄù]Öqt<Ì‘uë+RÏ)÷[ÂñïóıÙ")©ÙúğÖéX"Ÿµ<RÄßà#´B2V_¥¢QaN„p	È{èşı_=Š>ê±Õ|+	~UE&¡H ã­òñ^0tK™dæû8O(Ã|fÂş®±ÅÃš¹5 ôf¥PÎ—Ú\ˆãö¶ 0ì§ÂšÚl³Éóùü;?€¼ç]Æ ÏÍws ¼±È"‹4PwF¸RTRRB˜–)«D4ˆ8'3-~~v>b0^ÉPGÊòõÔy}'i¡1¡u)V²¶õ^¥hC£ã•|5l
ĞèÒ¿¤™ìãğÉCxíöÏù9Bğ²Êzj‡.õò%š²7¸×iÓ“+GÕ42£I{ÁMï'Å³'”a¯Xx’U2ªÍ¾D…-ÛFØ‚s7DÆt=³¶K}áRŸ¬d&Ú}‰6½×¬­9ùñ,Wn©dÔŞòc®s•K(ïK®‡¸.laìÖÇûëôÜÊæ+Ü'ù5.HaAñš‡!çjı‰T É^—äÉ—Ù5qXkã¯9PüÛ›ü ŞNlh(Î8–\œ°Z ¿ìQ>—¢šßÎqg"…’7½öw4ê¾˜gÚÓégYöøU~Æœç0.âÖ—ha®‰reùET™—~ı°Mª·ù¾äâHaÅ¼é9óº}Ÿ&dÖ!"ÉÊw™}}çpØ	44Ññ˜?ñ!FOä£ßjWÔ×Lé ·Ø¸äÉå®ïIš®Êk}œ ÓfXM"TáB,]Ô¯5Vj!MÑH-7„¦ï¿s˜t/7¿ˆŠ	¼kwf’2ã iwÀ4±ŒËÙ“ /³Ï#ëW_vdä34çYƒ××óáyÔÏËÅ9ùsÖÂM„`\{MÜ»ßİÛGB¯u¼² v'£Ô–ª*ÙÇ:};2x}çš_AÏ6eµ	´Kšõ˜z€o—xÓ3¤3ñD³Åm]è"‰QENIß2]FF­=1ñOg0F\uÿëb@ŸÄY>	¨˜oË•Ã¨¿à|®§ÚŸNu”‘ìê'ìœszä¦Ş‰Õ½¼Ú¢§õ‘Ôn14å»nµ‚ÀHh«S Åë
³cş­³º‡„|ú ½râwHÄïŞÃn'÷b¹TÊš3ñ0Bz*•ßÃ”ä§™™ƒ$­:ç”zÑÒTàà‹¥HXUgô,Ô*¿}XA…ºŞ¯«%¨=NjAf?gã¿§Ëë±]”¹»î¿™Óâí¿|WãLyÕw¹¹jNKo|Òsä49r)7˜vMM¢3Mí›šG¥ µ!{´©VDçúª(Æ·p‰ËÓ®¤Â  N2èx!${#X2î‚wø]©rÂß‰f	‰ÊºDY51F×¼Ê²N…'#›Ì}^hpføş³g?û‘¶ÈPY–V•=¦Sêßw{ Â!Ÿ!Z@ƒ2œ±İ-@­šQ9æ)U<™*:Úx°³×æÒ"2©Ñ¾W
tUáäôAU´B@Û1¢Áî–WŞ5aô(ÂÚáœóÛ(Jêdm·±¨†ÔÇm™?PS,>©wôP.õ±E-‚UÀEÉOyª 	ï¿ÔÅ&Àí\®€Šb«A?¼ƒ,xäššbÕšdzÑLÿH«ıo–	ÂŸiÈVmô¡ğÖcQ¶´ÀùE[â}âağ`‚¯Öfûå Ê1 €İMøğ¨ w{ÍCmÈ½ÔíNÎP|é*>¸ûÜK:“nÄvÅäêª:&Å¸¥/î×èWaœzû¤áÜöK's7‚ÿSÑÙqûŒX}Ğpğ“4Y—ö-²Â$#ÙŸ²5ñN^µü¶Rƒo©^§<Ò"ÖbØnÍ4~GñÄ)¸regtn+»`÷â‰Óı®?ôŞhßuÂLE³“`˜)q¹Q”Ğö­´ÓÒ¾.ğÌV¼¤±™Ì°ŞNA8Á«çB‘Â‘VÉo«)É›ä	?d‡‘g%sK›V²*•(”‹>ÕI³üéPé7"Ëû‹ÏáÖƒw4£_…	‚¹ûU¹×Jm
zØÆ‹z‹4eó-¡(.ƒÑ&†Ğ:(ğ	ˆ—£šäT˜Afåf·»
Â°
I½V,kˆ·)Q*yÕYƒeU'ÓÆ	î¼sÌş0–
{ÏO¹Î»`ÕÈøİùg©<Ì}Ä–?¶¶ùİaŠKğ1ŠW\j.5¨ëX¾9ç¬ïBVßjßšÜÛ[ñË9ŸÍí‚ÏFì¥ËòÁì–˜;du§¹ÖÕ,œãw-C6ßKD_îÌ÷¿Ä0ú ğo¸/@NÈU Z#ÒS¶]šÛ™–KrŒîJ`›Y×å{5–†WLÛH4¶âtØL‘‘k `ÆÜ{›´”ñA õ|g§ã1}
ep» °€®â5çğ’Ñqü°®‡É Qbğ80í#¦L"3‰xº?ôk'ıAÅÓ#Šêî£Ñ@¿ßÅïì³‰–Gªˆá»i„
½±ŸFfÂãiğ{±pj'kÛWf•Pv=”—(£VI{Ğx®PGEåíVÉØgÍ!¼»§á¼gÎ…bDüò˜Ù]° w¼§ö¦Õ*Wó0Óã5„"²Kò³Q·áI÷>qÀ²ß›ÙÃª‹ï:ÿ~õGÒË›-ùÓ$³Ã¸Ãªf^;#›>¾†¥”Ğ™½+K/¾ÆÍ}HQè¹<âö	oï*ØC²<§oT£a€¯’z F¤˜@éöğİP;Èù™Ÿ`&ufÌŒmÕš†7ëràl›Qçm1ÿê1#¾ı1â$¤Qº¿ïJ4’ 
:p+ ì˜¬Nƒõ3dºqşVRf¡@Œ›©˜±O9€@^Fue²’ª<*qH½w3Â¯ª~[ës¼4çŒœiè>úÍWÅì36”]³Ûyƒ”%ïEÅ5Ïê.@¤²j‚ıå¾2
w¤Ğgœk^\E½Mİğ»khŒ›ˆ³OAÉ‘«
—bŒf»ÂşHX`¬°B¯‹¡×Øü¹€»#`9íÒãâ^¦¸fÄÍY#¾½öh¨zåÜ8~Hû‰Pí”›Ãì{Ú›ƒS‚ÓÏ ëL§ÄôY­_FÆà« —ëeí_%êBºSí’Ïšoó¯'è§ÆmÒ·áhŸ~I/Îa=†)oÈ†Ü%îßÍFîØ^Òº¤°şˆ’¾Dó›ÒZœ•R­ÿ6‰•Ræ\Z<–Ošê{a	¢e£©å{’Ogph÷‡ä(—_rL¶{s…²Ì‚êC7z½.r´+ù	Dg‰s±ş®D –ä&ÛG€[cıö,¾Êî8 ¶–ddılıñ7Q­ÛìĞîæ?S]8Èw=Œ­Lq­Y«İ	Åóœ;üT¸kºØÀ#ÚÌ+ßşÓòRÖ¤.­£„Ú}gRyvé”«y¥ıAJ0£ìßØdMëM¿Vˆ
1ôRUh)…¾uÄ{Ép›Z¯~n‹ñÛ3ÆHµ^@$MÈ]Ä‹¡rJóü^¡RË\ğØÙMÛoãÓĞÓ’{ß ›Y­R-wm†±L•hÆ±ÍÁŒxğÅ6ÕmŒÿ„ÕíQ;’)­ŒšÅ\R6ë;um²×9£QVT8Ë.Gb+İÛcD·‰]/¿œè—%‘Ò`Õ~ñqd·¾96L;\›JÈt&,fáiGüÛV‹ÊÅæ'úİüxKİîÌ=–¼çÖ ııÆĞ¸ˆ©íFßÿm\9†œ@¥ßÒËÔâ*ü¿¢ÛæÃ}ÕñÓlvb[#uÁ;·ìë¦vkâKgÔŒÉ%>ŒË‰tiuğ@Û˜ùğuµÈó	wÚ@…
äk:-MyJ5jˆ¢	‹ŒH?³§3±ÄOÜãÉÃ	©0äÔZå¯ĞT‚Í4FÇ÷•±ÆVõ!	âHnx§•ãê»±¸Æ>K’ö}ck+*°ÑÏJ‘EùïŞ»àÈ'ÜOÁ
ÙÖ’¾oª¹·–é‹„2ô–ÈsúÌ&(óÂøöd»1?¶r&-ş;û2¢]a17ıšˆögOxl|¥ÁåÁI¤e ¤²ˆÔè†Ì9q#xeSâ¯nDUí¢ák5ãƒëVXÃ£[k
r™¿/m èj«{få#†l=²¥»Wàkø¤Rqïwì@W®D:R/H–X
UFïDØ«ZºÌ×ëZÕÎ‰ï‡q»$L†ß™Û{1)qş-Éƒv•³ò|^³ÿu‰³aY>•‹÷‡s…ß`öÛ`lûôö÷U³§ø0>ãÈ[%ï„ådôxäG4?` }yc- šœ½KíÆ¬V*£wÛi‹Æğ}¬w'œEÖTeÕC¨(æª)]—pöUÖKPD3–S¸	X®ntŞ­&ÁPD$ûæB7Án¸ˆŸö¢)ŒÎ	Yb;¶ŞŒ$3ñ´£û_’,Øä”hZı{Ó–-õÚ¶ò¡_†•F’CÅyPJ˜ßË}Á~9ÅZ\ÀîOi—<N ½ZYfäd5ÒI¡;¦Š,¤\±5í"(ùõN”n’Q ‰%gÚÛ¸€­ÔÆ¤!°µÜ}ĞA¢ Lúk2µÀ²_Ç°Ÿ5Zı(®Z‚£fQ¸¦€OUêÁ;r¿a\\6Î -À‚E6j–Sêm\+…MÎ	%Ös<Ö¡ &åkŸôã3¤&b3»>š¹óNQ¤¶ZhiÑ‡`·Ä#Òd¯ÇÇçñÂÒ@*Ÿ¸ê1¹•w‹—Nˆëì¢v±ÎˆÊE½BWø\³Ü¡Á~WVsãöÔiˆfÓå °aL–LÊ–0T£`š×ƒ/ît³¶

TÔp„.Æ¥â›X‘ÊWşÚ_£ƒkŸïoX,C¬êt	?-½ğ:ß·Zû(×½]iK}Á€°	#°HùäòÅl'ÃÍ¦?——)Şœİ#ü{Cƒ¨:7Yá'‚ı‹E´OgT±s¬ÏİØƒx¯ª°€rëãÕåîˆ.'¡L3‘†Ä.ÔdÉ´tED]+á`!€çÆ’5}ğÖEp²&D<&şJ<(Ë©àïg(œz5¶Š4Şb ?^¢„¿‚—qÆ%‡«Õ½ï¯îaQ EgÆup×a¢0 
şÕ,1Îµª2¿ãÍÀ»V±Ş¡÷¢–¨ªßğÎ~°ÂåmªÂ£úÛ-‰Ûã®¤áê»½¿4ˆšã ªcÅx¾©® ?k‰/ø2ã_Ï„ÖÔßzÒ2š1‘Ş¤hÜ
M·umÖœ 1èøÊ æÀ¥å©õÙ²ó «<u¸B<¨k‹05Å~?õ¸t\|º\¡‰ßßßĞ3)ıú£X2ÈşÍÄ=€g148—¤&r«"‚ûH»AbE×IëZšÃÆæ'£Õxi–U‰ëkÚvlUĞëu~×P°›şŠ[ÒSv™CÓ[´³šü- cù:æ'Ÿ¾~ÄÊ¸nÂè–­<=¤÷ú­Mš<ª…ØF]œqö¸ÏFª…îvíüƒöœr‘Î	â>•­q›îÌ“ÖìN …UFÇ°QÁÉ#«ÁVøKãnSèßÂ®‰bÿ™x Gtcãƒ{
gôYMS,çé-ÂJû‰<gq€”›_+)*l§g¦TÇÃûnë;÷‚:äº-×=£à¸Ëk,¯»ŠªfXöÁ·µZ˜õï Ñ+ºmzİ¸‚|ª'Vh¥½º80T˜·¾?£#(PËïŒp(@µ\=üÁA·>Ğ·µÖW‹6³«D(¹0¬­·–ël…oX,HğK¶Û6œŞ†„&¿yT@?p¦ÒO¬ıæ5–hQ³ºXóöÙºaŠIÊF»(ãêlâD½€GEÚ‹¼ŸQ|©æïÌµËÄ)—¾ácÒıÍë»+¼P:8A&Û,öšÿ–zeŸX’(ŠÀ¢”¦¬û¨kf±ıíhpƒ1İAÒÙD¢¹’ê/¯ÚQ7…šüØº(ÀHR]%¢ÂøŠ®•n²(qsÇF$G	ĞäÕJeP†%Kn#SªdĞWV¼1W¸÷(/2Hp§å²5€!Ï¯›¶Dr1Pà}qfÇvâ]ú¤Ç-úÁ”Óˆ¬:íw’–V)rêÑÑß°ßîS:Ù`›µ º-Òß%ˆ„ók.r£gaµ…“†Y‹[ğÊÎêµ¤´¾tcNÒ­5Õ$´ï}YL•´å&‹3±ˆw8úD’	±Í‹ÏldFòxı~vT¯ÿ¦¥_æÔœ[²p¡»—ã»,šØ¹^5Àmwê7Y"0¬‹Ş³Gd\¬cÍe3ºlLğn¥½¦ö’;IwoÇÛ)¤n§ô¡!k"sğ[‚ãfcÇ4N‘Âarãÿ}ˆàrUõZ£Sğ+m#{¯ÚñòH"iJ˜…æ=hìø¥ÄQ»	pâ4;ï¡NsÑbnáN0àĞƒã‘Z-`ùìB™ÁÇ×ô'VW¹c€Z ÕÕpVÒÄ F„ •È¢‹¦ì­åî
œ®–î4Jo³ÅD·ÛLêû*°±ıß$Š8gÒ>-ÔLp/Ş«_ói¯{k}Ÿ=F¡¹Ş2Ú½êgJœ¿‘«»=­jÜ¸8Åû¿Ñ¦acv>Û?j}R’?Ö••ÁæÔCx“	è"0Š]Ô2FÈhF3Ñ7ù`?R*
³?ĞHh¼"1–Çäœ60óaôHK1»’Øra -2Œ‘R· mbæN’²Æ<‡á˜¶•Xš_îš£È.¥ë­İJÈ5ÏvĞšPymâ…¬°«ÙÈÿ°”5+b*AnxY
ŒÒN#Í¼ÌÉ¥@-âI¨jƒ¯¯Ê¦˜öìû…<ı‡B!œS«­O¢6
@iÉ'åøŸ@ğAX‘åé{`…ØD+ÑjÂK¬agGŞØ¬§Ê+vŸ^zëÁ­¡`9I¬/ö_rÚ+(.µJÃ¶5CV9¶vÕD^­$O`í<Í+¡hNÏü9`0^¤°u~óÁz¸ÚÒ±Ñğg9xÄé[®©¿µ“w{#t°bÀÚKìÆxZN´ğ<9ŞúH4óº´bmÇ%Ú‚lcÆ3 áQ¥•¯HV)Vƒé ‡Dßs>Âû7Å€ÉS®ƒ/İ„EK†åóâ®zn-B_AÅmöGZK—‚Ğ	.<71`Ç/´4)÷ĞíÑ‚«ßÖ3³vÆ{Œ=¢/€D<6øM®l¬ş“}\|K\K2é?Øä!„‹Ïu“lÃæôc+]˜­udSvaWÓ·Á¤<9ÔÕ0Š2Õ©¦Pv¯Üàøƒ¥}ã÷ø—ï‚¶IÛ=ké·ÅÃ.`*µ¥‡Í«ãcHğ,‚À»{ˆ‘ÛM}kè¦7óßaP{Å8äê~Í ¼4ÒÓ›y½eaÎ†€µZ+Ñ¾ú>*øSœæÌ1!%(% Gú³ôümÇ×"x1É©hTåEí$ó\~G†/´ÓY±-şqa‘\­j Ÿ}á¥±¥QòŸ›³&½pö•ï¼ö_µë×‰FbdO£båÉ‰õ)ˆÅ¥TX#Uå4Í¿½ëŞAúwÆ'aú’Òaa–G(¹'¢s5PùKoŠ	”w¡ÖÓ@‘Ôz‹cN)QlŸn°â›?,úm†d’èq“xü ¼EEñ#â\#Æ¨òG)k½ªü öq‡`Ğs´/%QQNÌ8ÈÑ›¹Â¡ÑİWÔØŒğ¦¿(Xªä± Œœ-?+Â_Féã†+te"İ¢üäÜtûÃÒsúE—†¢»P³uôt7‹8øİÒ§)ß½A©OØ@‘iW¥©ú€KX|)c;}›ôı®‹1êpY9~P~–ÏW¿¨òAõ´ÙôıÌQ	Ãwİ©På‡ûSàõ a­Š¥Tğ¼
À0R¹–×ìış©`4«¿H.–“æ{¡Â¨*EŠQ…9J´*€VÜáÙ×IØâ"WÈ5­§B*ßÆï¦£OeëF *<X)Kü7Ò›Ó£]RãC¾ôª&¡ÂäË€ïáå\Ñ× *Ÿ6ásL½Ë™Ä€2äæã<8~G3ı3æwı3ƒ;œ¡D {ıVt¦OÍq‡…$YõªÊT_òòÀ0†!?3O˜ÓHRG}<œ£Š®şê9û^dÑOÁÜ¥œÃÌyé.­{Ó(#°4€Ïšÿ¡ˆy—lªÓK¿?Òğ"ló¢MÔ£#*Dô¸t iÔ0h<Jé}mD½‘â:ĞÉE8¥w_¼!ô[¹T;àx›{ÆùÑœX	ÃYö°r.’‡‘31üé^#N;jK¿¦¯-6Ç¯¶˜ ÉêŒ¦²ÅÓDñ@'1Vçl)†7Ô¿ÀêG ©#pƒóô9âõÓé¼3·U‰=3$fµ^C2ÏâÿŠ\ÔrT0’¦¨Q0Og½JS‚V„MÖZ¨Çº5×ùk×ßjS¾P9ÍÜ¨9+0!JZ0¥œâ²’‘jK±»itLæJœğxîµáE4j_ oy{áªb#Ï=G«)®™ù2Ó,Öu±ğõñTëKt”ı1í}}W(Z¼©F#ñ0`‚ÁB×Ğ¯İ{ğMšªY6æ–9;F
|êÑSjUCĞ#à¢j*Ãc{§&Ïòomœ±J³‹t¢Â\ÙÙE¢T	Èh•/ú¶p£$M’’İÈ”ˆ:À¿¼¦4µ}jµ™¸0É#‹â<ÚQuB¿½6şïá ²ÒL¥f‚r/ÿY;ş{˜8yı"/Hv×öRØ·6±@9ÖO¿½2|°—® xGÏü¢1ãù:§„
«ÍC İï·hf3p)iG¥&kÈªîËŸ„:¾âvÉ1r>OĞ¹–:;¡k‚©û½¯ B³Î€Ç6#Ë—D%Ó×%Ğ"ÊÖVÕÓ–:6âÄ÷ì^µ·²°†‘Ö”00„}Œ½ä_gÜpÂÄmøséèÕ ‚Y´ùrké$ıfØ¢^FŸeÿÚÿóÂä™£ãºå”zÎFG!"hM•ûÛ*D†q~EB‚…y½ÍŠ‚yµÿ‚µÉ/Œ	ÈŞÒÓJXŒA×ÅQ¢:œOÕÆÚ1\4ØLùŠ8Oü}lşì¨6àö}N£GoöÓå)ßE/…8+ô{^ºD Qªß%>Î®HYŠÕ
Wo2 4ÛŞ åÑf"|ÏlÖûôX‘Ü”ù…mØĞÖq2NT±2¡ç†¶ttFˆ›n]”<¼k„×kŒâ ÔTa”ÙõÛù\‘só®*§…KÛw¤Çw¸òCÿ‘2³R¡·^Ëì’×/H>Éö¯ôà—âÑ'×7ÁönHMCüÒ—´-GZeÑ{ŒbQŒÚÙŸ-(«±ön WH[I99Ş†–ÌspBqk—±_°ë#¼ÈL…¥ó­Œ†ºÀŠ&_.«3¥îxøjŒQÇœW(…xÌ ‘T¦
sÃ`†Íšcé` ßˆçs‘’”óaŸJ¤ï´~‘bEè	Ü âúÄá¹8˜I¢&8¿Õ‹?è†$h'ú'/Õd“&'Îµ:±ÆáÀÂbŞn9u€uĞpÏonÓğÙÕjğ£•µŞDuXï£ßq"_çÊóé°‚œ÷¥AK3”Å@¹1Eñ`k'géÊeæğt/c‡Å*àí£î=âŞ9•’¸h´4“n45â[Ö*wÅ(µ
dFõ½ovP”%	ØOPçÓ’m_åL\İÏ\HÕ#Y]´ÍÀÄ¿/1XgvÑÌ`Íï`-»{eÅn÷rLWh‡@é^À‹Dv]-@GË£ÎæâŞ	X²ÑşÅø¹‚¨é<†qsÈ¿æNÈ@nŞÉë´Ãçğ—İ¾-xªL¬‘¾²Ü%>‡Šc8 åîzâÅg?Ú„¢)zJ¤¾iÎl—±$|°Ú-=@ŒŠ›«Š÷ïƒ™Ïh;Ğcğ`—ü¦¢ú0ãzÜcÀµ>©jÇûW¥ds²ÅÜ2ÅHTóÓª3zY_[1ip$=½ğ8»šÚACğ"“i²ÜïL÷…ãZè+¹Â.³¦ug¾¹y¡ö*‡i™W‰JèkÙqL*-·.ô û”ôoVÂ,#úIÖÂNLÎ;fÏÆZ+¸{g¿{ÓZï½kÏ6ÅÊs™»’2Ó:à…ø×e¤ä}Ğá:††§z{“ĞÅÿy V“¹“G¦Úf¥&‹_H¢¸Ô-vÑÿ˜î0%>I2ßu`B‹2Q)ê·Å1f3TG:¾SÍ¾A^¬D¤5A<û¨ëÑ×.w2:ÈùÒ!ËÑªZ*êJLE;´õ¤°ÛÉ¹·V(”¨=5í€—~°ˆs†ïOÈíuåû=JNæNu¦ İ°æu‘gloãøÖ#¹”ÆŒpˆHDı='´Ù™Qdi˜,ó.Ö±ë£C@ŒßxD™ıín=	_7¢'|Ë(8d,ø"ì—ÒŸ0·Ê]h»2òøÇ¤ê±üiãÿÛ»3ªaøÅwáàTå?²½GøîønŒ"îìë5¿z|Ae	Õ7WÁ‡êºPH§O®£y(¤eÙÜ"ñÑµ™lˆÜ³ÆèWæ|T¶ÇÜ‰5Â;¥8wSÍ*¶MxtCòBÊâmÔ1²j)J$mà Z[`wÇ«Š|”pÈ_b²\éÕ# )UôÿöÔ”lº>²UŒñ…O¦ğ²ac¯v^*¯Ê’Õ:Cİ]™Ğ´ TM÷*®x·ÉH(MfIS·ïíf²ÆY×Ì.	Yu1|Jßğ³K®Ù?8bÔÙD!c€…D°àª:Šâ¾XæEœXD¨ÿø„èØ<ÍŒ¬mÒí[|mÁ†èRsÊØr´Ã†_L‹N^µWÇ³æÑ=w£¸îqÇAQóÖæáXDÚHUã\–á<-k|ÍN¥›V$æf¸2çÉ¢Õêc~Å+›ı
¤[„úu6?¿»!.PÔ)„IÙ~€àËûS4»¿?á‚ƒ’Å‘ ×"üjÇæTg -ƒ‡Ö4‘ô×JçªñŒC¡{wÔ·ŞVÿÁçjjµóO™b\ÿ—Ì±ü<@#‚|‡úL$@oÖ­f8÷ì¹]ìä{„¹ÈÿX¢Q&¥”iód™ş@,Íİ=l£C[–öx3÷ä İÂÌ›Eãè¢ĞıH%ı½`ÅñHY4R¥û4Ås™ôw‘È“)T9ˆvHË¥Ó×gFñ{Ô-¬††ªäCˆ›#¤A<H	#FT…¹#¼NÇÊnì/Yó=Ê;æ(w]",ÚÍD «¢XB#+Ê9 0„F4¶±İÛŸz5å—ÏÌÕà¢—¯Øğ„¸amî9H18É~2`=4E”µºT(èie È¶[€7Î}0˜eñ)b©ÀûÚŠB—abÁé©`‹- gúß*\5ÎÍ
Ìp9a@åg±m)Œğ³ÒÌ‚¦;Âj‘»nQ0^zŞoŒš?Å *{7>Ávì.ætÆ˜‰X¢7]³"öN¨p2mç_3dV¢ušip'³%8¯Ã´Ê‹ÊBßš4­³5g•ãO7&ñ'<vãê1ÍPÒÃt«n$æÙßõc†×{l°•ˆ
ëû‚‘Ä{wX:Èm‡l‡œá­sÕAúÌÔøg «ÚéRÇnÚƒ\ƒéÒl	7®B?Æz\U­c!W­^w‰¶‹ğbq 7Õ4’B‹ª8¢•Ğ--ù­6ÅW'%AKøØFkÏ<–—ÆC´…Yí]øŞ€ÍŞ‡Ádyxßq~ĞÍlš¬Q‹\NMŠÁ ±ë4!Ã²vU¼«
²Ïi¾y”Ã`eX€i?A‚G@eÜ ¦Æ„)SÕ]‘ 1üŞ-f YÚáz»^Ë1âiD¸ƒÍ«ZsÅÆ38|ÂéÀÜ}äÂ¾ñ®ïqŞdb3ß·6ÍÌ{·uëPìË2¾á±¦NçŸ›ˆGÑ9‡»ÄÛ¤ğf(Iÿû¢ñÃMßú^¸d7£ïÖñX5~}üŞ§ŸwØ@Ña^Õ±~ß£ÜëaÅUx˜‘ÁGß•P±ùèâTõ¨È°†óá”ÑªEÖûM	^É×jHŸ+‘ â}ÉèÌôu8<…tâÔÚ{eß+
ı°Ú\§0š¦‡¨“ù3P4C”ƒQ<Üà1¢CDòÑ>jÂnz`’8ZjiÓAÛş+‡Ké0aÛ¾d•³Ì—ˆÆëÆ¦§b¨]K{èh‡q×ÙI…ÍÆß4<o
!°j0é`Şuœm·=§ü¨mQ™Û+fÌKŒn-ËÊzèÉ…Kpp€sî=å}¯àºí66ª».)Å €Ç¡w
pæè0•¢ÇñAiÛkÍ±n9Ê‰N	åáj‘©˜ƒ’c˜ä é›¢kWêZm=MÈ¦ÀÀXŠª†`:Zqé‘—:·ndÏü°ÓÈÂü`˜îúG(IÚ:‰ÌİøÆû‚`Ñ Ãõ ßoøÙnº®…¤ù#6k xÏÀ7ó¸dÛCn9:‰³Ø%Ä[¸ÍšÙjÑÂôm2[–¨©äK-–Ù/tÕ§~¢~>ÿBÆ½£|û«Ô¸ûg“*f‘ƒÈÓÅŠŸµS­ÿÕğ#Ç²ıYõüITk¶Pƒ®—EitDµ´é$D¯1h©Å{nJÛô¾DêG¬‹Â®
Å\ğ”öæ’À£é*ÎÑü•ºKN¤£ñYó»O’¥n|/ 8…¡~† c}àyZ‰™à™Ô—À6ø$óL5q]gú²İÄvãÎz])'M°OH¥[€ÑƒI¢+‘¢#p5Ìİdè6òá‰#˜œ‹hvØ.ÊÏå"G×®'œ<flÉÔƒ|ˆË:ê5tÍqÏˆĞ™¤‚OGtt¿f¤°Ğ&ùÃ¿z1d­]²”}§û#Ã«åtµyw|ßVçĞÈpj<TÅİüRh{éz>«©³*«8ÿr³–(ÍüáÌä¤Y#ºˆr>RhôAÆßLĞ¨eUæ_ÚÔÙV6ÁÑa`©¡~µêìÍî=ó¹VèlÈ\!-™‰×:Àìº>‰™o½ƒ°I3µ’Êy–¦ã.i“Şò–|Ü¾®HÚ§hìenøäR|šçºóh0jP!w&»¢‹g%Ö²2W·ÓJË½|ªßì€UòåİÅƒ}ÉK>³r=d‰ô’¦wßÿ8ÖªŒ¨ÂA6òpÈëÅñ¿?F3sC“Nšœó°r£Š+«®ñÈd`Sû×ŸUÂœ)"©7.ÆÀßé÷‹ÅÙ5ìVÚäÚ$>Ô*1ıÌC­L?‹ê¿ÓÑ¸ùÑ³¦hõ g¸dŸ;ÈÊ¯@Oó¢7n>'<ÙêzÏu#‹xÑ“K¶Zó°1ÕoŞƒM£ù7U'–eËv»R•Ó×á	
H?ÉŞX3l úŸñŠ~ò5“õlŸ
‘¼ãQíËÆz;Æ|>èÀÇ“.úDdÜhcŠ1]¯C»ßğ+dşŸó(¼ÚŠà‹¿5ìv&¤Í^ùÔŞG¦²|«e¥ëğ¼“ì¦4ğÛ1QVH¡ërH°×"5ç°×8îÖ	(u©~MG†ç–hş¡nÀí}T_{ê&òÎ”8¾¡ÈÃ¹s6TnÈøG«ş«1±ùØD_% öÖb´G5;±ôwû®.D’Äq—Oÿ0>…qı^\'ûİÕ]és°zõ[›šİNm²Ãósó±ûãòQ‘Ú·4ª¼¨–e{OêOUQÑØ¢c«ËKŠ“£^Vğ½²Ç3P¶”ˆzlªØšÕŠxÕ¸‘lW¿ïl‰ro‹oÿ¤¦îŒfZMş¡A$}÷!1š{y	¸Q(ú,†í½>÷t«\ğşªã¿x±á´:Ë´O­4òŒ#‹RÍ†©Çk§’iŞí"ÿFÜVpî (Àä‹[Vö’ÜÌ^æ9Glíü]úŒ]¦_4ğ;…XÏèX_f„7;ëuQı:eçË$¨^kt¸EcrĞ¸¡í4tm.¤M_ºpğ'«Kj•(+ïÃšŒƒr”É«À/FºğÚÊl•u.‚:¥ÏvªĞı÷<&g]W&#N–a€H›äC„Ï_QCf`¬ÓOèùòå³Oœ’šíÒéb¹6Â¡^ÿœÂ¾êk_ä¤ÜPp…7¥4]%¨ÍwTvx¤ÏPôlÄ˜µ0¦Jj!xól5m\ùšîYÁu×ˆªcha¸<éDp’D¥†rÛzJ	4ÄõÌäup!„AèÂ„ˆ¸ô)MEÊ“A|`¤Ş3bœi^ôA4¬“ûUíó´cmœ{Šr$xÅùb@²YøÚÉ´ÔWv5lèƒÌûÓÌ¯ h)ø˜’lŒ¨EeC¦~ÈãûU£Väõm2Hó+ÁDò$!‹q.¨êo´İV~‚¾”÷.ğV:pË
&Ğdo`Ğ§j2ÙùNó©=8$`A¯±È_wNÈUõ]÷ÓfŒn7Å¹ÏR¨Ê›ÇÊó‘@4ßèmz•ÂÄı°İF›?+Ô ~1(Á_~À ¾±(˜àquf€iªqS0Îwò%A©\¯9H<½!¯$úa3†iş0Sšàt3ÃC|‹eÍ—è4Jª·3òIkÂ§S2]Ù{)ÃÏºdÕRè²åŸá‰Æ·%Wü#W§‰p l÷ÍLèÚ†Û€rs2É—â&"¥(1ÑH=‚'‚³üVõ°?ÅI©¬š-w5àsõe¼*¨'¤s·ĞWçŒ{Ä#Š¨Ñ ”rñ%ÓË¹ÛÊ´ŞucóÄuÄo´ ²+P[!·wíŒµUÄ®óÆUÊ…¢Û9›ü£ZéWI©¨âRóyKˆG%t-?'¸,äl{ƒy²hÜ†ÖÌ"¿˜dáPb+‹U™]«ğSÒÔX“˜@$?Wtà0¬nÌöì¢fHl„_ªA§–d(kŒhTµ,âÖ»·VÜd¹6KşJ·°\æàt¢ÓûAyÿâRH1üïûºÊ²û}	8³Ÿpı¥„z©û»•®êÄ§„µ–Ú×3Úu0h½ı4ÍÌòaT
]Ó CÏÃ8–ÚMšöÔè¶ hèUò†Ãú[áef¨‹´®îjD[$ŠÂƒ¼“øVÁ‡­µòç'%
Á•h	Sò‹šdR* ÁÈâñ)Œw°€“îF‘JÁ‚#µ}¤ûÜ=_äJ‰©ªåÓC³y‘ã‰ô§3QæUBÏçÜZİn:'Ğø XĞ¦~õnğ4ÑçÑ%äE#nM‚G zå·í¹şº¸ƒÓhÏ¡J:üÔA,ŞÖÜÑ§Î5úl
}P$¾l9ü´PÂõctÀ¬ëlNzÂh=ÁWìòÇÙAv1ŞóÇkFRV-y
È zÉ4¦C‘¾­ÈÕıÌ)/'J7·{ õ	aúKjò3.\lãco˜=øŒ¸'¤Š`p-WúÛ^L0ÏJkâ†Áõª80º²]´R×Y¬Œ?B;‚èÖP¬æyÙÚ¹‹tYØé*ø»ì×àXÀ(èg"lÎ¢A<£&Á“ÕK{Pÿ’y3?V¥çŸ¿|— #Ìu0ñ`Å˜!N¬WB	pèæ›kşHAYìïU¸‚£&ö$‘©{)Tù²oÎâHáÓ'9kğèD½Ì¤¤üºöÜé8°½¸€½À:0ïÓ+ıt²1‡ 5š­ìW…¬ŠÄŸA1H
$Œï•Ïôë>ßD×“¹yT‰™ròv»àõxl-‚Mç!vªşæ^¯-]&b¿}=š°@hô=øne¼M²r×S-FÆZÿÜ}Úƒ¯·t?\GbˆAf*3¾

ş´&ğs^Ko(I’¢+q…d‰…Z‘d×¹duª’Ô}>T%M÷ı8İŒİ¤€Å?±÷q¤Q˜è	Ñ¶[!Ø_Ã‹&ïÑ_y²÷Ü†s¦™Ì~c,¨št‚¼	£œIUl\†ìêèO.ÅMhöŞùÿ9³Xpğ¦À:j£_ØPÎy.¸Gs¸&@S	•MŸ¸Æ¸ƒ£û%fÌQgjá6¬ˆ¬Ê)ª+O,|Fùxáˆ¯(2@&<8îAn–ˆš>Â³rÛ-hå™‘4##œA¯æ2 ,Û¾õÆ6i^l[9éúÖÍ1/VÈWH±›û…‘¨v™J¾Ÿk:ĞõıŞm–á‘A!ÀÌvı+‹½óä2›ç&p'9e3•Sq@ëF`JqÛ©C£²ïµbĞ­äy‚Äfêµ
y»!f…¢†·U:v+Ñ>­ê²±k8Fõ4{B‹ºŞZßºEêqøLÿóõmĞuj¤¯H„´ÍÅ“"<Ç³¹åˆÔ˜<8¡"Çê@j­*Í9cûNk«îÁê_ÆŸÀæHd[ô†Òºáñ«Ãc"½Æç¡æÉo	’åã!,éV-3ÿú„d§¯mÎ,ì{WÏ+÷1ùcî¹„ß8g)_*M	“ë`®NÊ§™m£j.7ÛeÚ6Bª}|êub”fí¶Eô)—Lì½ô³$=‡±:–®gìjÚMÒP	ùÒ¹h> ²2!Öcx9ãv”& äÓj¡ÛƒOK?¥²äSÁÄ„Q4ë>Èî—7kHß:¡îñ›¥‡o|/¬„[Z,–tµuÚÇïÒ;BSˆiÍ›âV¦[å™ô¦oZŞà–ÿM¢ƒIğwlrqª)BÊÌd["<ï»áï7¹ SÖk]âÕ†ŠM{q9y‘åÍ}Şà‰vºñî}%ì‹ïg°R3Qµ”ìF6Ä<¨Ó¡MC£Õ$æÇóëO1ã….”|’kµ©0 $"–·Mÿîv4‘;m©œ‰·Œ–ÇÒ¨Ö…œ¬ã™¸k9ï½¦¤=–"™£œ¼ïÒğ€d˜?ÄÀéƒl‡…YÎM‘Ô~¹ô¨ß¸d˜ØZ¤C§mı„®è–âAÃUNŒ$/Ë>\qÖŸÎ£æ°qÙô¿‘±…1@÷0ÄuXUĞ€İQ,µÜ.v*GUMy˜¯öXÔ/Á'Âb°üÂ@Dµu
uABn‰ğëXjzmd˜†‚âìJ¥nóm[í¬aÆ§Vqx‘w,å‰mmá.£'R3‡¯L$:z£$o?Q$vº62$’©…Hì¾˜âJ)(AŠ\W§[soqö=¶×è~İ!ËJÕRÀ8ş}˜a?âúÛ)×`==ı©LúÚo‚r¨"@£#Ñ.	Ëõ^`^ö-¹u8µé½\İ4§[’\è¸`ÚyM
ï ®…R¯¢¢¥Ô”%)Ñ$ø¤±¶ qßf‚ƒ;SĞ„ïæ’¾Ös"](àKĞ¦7uNæ¤ÏD£èì8å|¤m’ç‹¿%×ğÓg¬&” CbÜ©Œ4¦[õ•CûÃãÛ…Ï?È¤Æ¿‚—}À5U¨üNÔº¬H•Z)0>öR*™ü ³í'×@8.åW(Ú0‚DYµLâªÔao¯ÚÜºGQŸªó¯B
y ÉàÈ‹¶i´I×CÎÙ›ˆ¥§ZË“ïÃ¤õYËˆ•tÌBS^$“?ïªu¥­Û"¥vœ·Pia:LİóÆV‡Ã,wAøî²½ÖòÛ¶İ$Øbr^–5¨7ÃeR6šàt¹Ü÷½@-¹ÿáUù ] Æupáµixºm¢1#'¯.ªf»_ØÊßM¡kÂ”º+ÕÖyM°–ÈÌ.;VÒÎdé€ñT…ãB~/TÅ"ñ`ïŸÊE€p˜Áyÿ/b]¹pïr=_Ù¡‚>ı´Kœë`½³¶1q° ´\åd»í£ÙW†>%Ô¦çõÌÄ…dÌ±¶Pß^\¨% õ°¸P©;u$à	ç±Nİ|Íâø·µèÌ0ù÷D»Œ…ú€°`Uµ<DôfqŒ“ıRŠ.Dw‰; &é1•8[Ìı&zéj‡vàákòxûš 33¬l"™½C¯½Út˜O3³OO-LÿàPXçœïEÚáŞ•Îv‹µÛ¼ÿ¿,İ!%Ü[x„pUüt+…év1µéLõ#vÛd¸®sCáœO:®SuVì‘ş;.6 qaĞÏË pX(_©{¨YœÂn‹6‰„b¥L]y8ÛK™d ÒsÂõŠI@ñ6o‘S‹»™#ß±ÿ¹1#»*;î]ñÄ»©=Ó·,GÅ?@ìF‡Dıòë•­+Â<°RIx·"ç½b*„Cbë1Ïq[ØÙ‚=k¥ı°%<KI¢Pı5ÀR'Œ¥İÄÅ–UlÕ$€êi«ìU¿~`uØ36CYÏ–q¬Iˆœ¹*ïC5Ù¥ÙâóJÄ‰;q½"¾XWSFŞ ©Lt‚énİb×]ã©Eö.z\°4ÿ­úZ¬@X]…;}¤°Íu¤5P:Òhì1ÕßÑKT0,>âË/ÌµM!Ë£$DÍ+2Ô~Xˆ¨‚S+Dƒ,GÛ$ÄWê§òeBWzÄÔ¯I“*¾÷ôĞ*QqŒJ^!¥>Eu™Ø6ãèøÖSzzÊh?×p/åµ7œ
¼1˜ß©‚Y»¡v¯$Y/ªqİ?=€íÛ×íÅ”Ì½^Ã?o“ù‘œö%Ÿ?f°aoM¢.ÛFİÜAœÔ J¢¶ş9]îÊù·~õâÎ9vşÑn F®À‚¼:³rt#K&)†eú`(&Åçl³e•æÑh(>=FEoÃÉ„9éåQĞÅÄı£*nƒƒÿze.gÖ‰CllÔ\¼XÄgáu
5J]äÃ'\{ÎåãsgÚvQ„ˆá~?iYÁ&srœ~q}jü~ñ*r N½ÒŸ‰-ßíÌ!NKyÑ¦€UW5ÔQSj”ÈÁ…
y“‹rv+	TYÇ’©Mü*lu?{Qgù‘°«!? ¼âHèˆ\ 0ŸØß¬ªÁe™ØÃßš÷4)yG ØÙN%IhŠÛÖ®Œö² á8„0°±cœ˜¾±Ö@I_çìJË+£¿@åC»#ôİ±PU`e­ ğZÆduTÁgş^0Gß}¾ˆdöå†YÑ¬2±ôÆïŸ§\"l?cc°UDv¶4¥Í©!FX¢‹à…e\©sÆü*ÂGÓSøªÁy¾V’QÛÅÂ£9Ùóê=}ÓI×Rhæà _¶íë+\2Ö_d%R¾µ k–!à¿«©Ø&ƒ=¶DèE¤ nÿ>exkÅárFb¥«~Ë4™yíìo?]=‚†…°›%ÉNËè¿#}C¹wØÂ|)±øZ^Ú‘ÿ/Š±Ö?@à	I[1tV­È.…Æˆnq/¢DB–Ü+^L·T'i‘°«u~É&îÄ &“3eKK-“ %¸jœ1©ş.³ Â*&'(N£Á®á{ŠÿËb“Î-°hÊ’Òdû~)ê¯¶n½5Ls¢"ÏÄ+I=G|¥\¤tİç“ïš¿E£ÃüVÉÿDÃÿê¹¢£6oOLQÈáeŞçœ¢âQãe[uŒkHª
®§DhÉ'UÎlq¤ı­¶ï—S#òu½±n•¿ô——cšf÷¦˜_šÅ±iïÌÎÊ‹÷ŠÒoW¿[ÃÈÎ§J¾€Û¬(ğ˜On€jø‚¢º½kØ8Ÿ¦†‹^ŠªCÔ¡@M‹‡2œÂXp„ù(m6®Ì—ÓoÖãb4œiR÷P›©rE`ô/ûàœÖ ÕiåUq~€ ªòc{´“áãıP¸¹÷k·yT®’&2Ât¢©òı1B3¨¸-`"¼1/«Kí‘ƒ°Ş»Fl^¾ymŠ?¢R”DY­¦nÊñ¹ş1€<Õİ†zîáÀm¿Æ¼‰RÜ`7ëÁ•ı¦Ñ†ÍJ”’ˆ‘È³Df—_åŠ±M¹9)b²MÆĞf€ÂL­_DR4­_.¤œùùîrÍŠü·ZR7¼‚4İYi=¿ÄÉ_ëÎé„9WånL}ƒ“T‘û’¥'<â!*í&¨cµiB&Tsê××ª¯ePíJ›Fßdÿ«FSõäŒTÑWÏ>'¢3½Krÿˆ>×Ö8¡k_á)è³6{#€2(HEG’Å$2Ë%,±lÓ¹åd£€Ş9,ä$á­“àˆ6Ø”š‚õÿ²š-ê·Íñ´gûˆÃÙp¨g:÷E~P,;À©vo¯K„3
,[)–ÖĞtštúó^M0¡Å¢‘Ú¼òù'GNõŠ(”BA‡‡|UÛ1ø»»k;i“·+ÇÜÛù<z=œÙ•‡„1‚£œx²æ¡_¯ª¡ò>E´jr=Jì<õÜpL]]^:h
™Ä>-%n^<¨p9Ë[âK3ƒ0„#PY×Q×H‰÷—¶VáªFÜq ä1£Ì¿·éŸ %µWÁ„^f¦ú³Z/ ^{,vzcÕr¼ia3È›VÛn8™ ôM5g	Æ Ë‰aO%~|³ıÅŠ]È|Æ¥!ÉÃG6?m@•zr_e	$Î.˜â,û¢XRªõ¼2ƒü”B—TÈ»Ê™ÂÌ³NˆìV’Š¶(óÊ^v7ÌÛ/J^ô<ö`uÙç¿àøWeärâ‡d˜•ïî‹ô:[½¶±‹1"¢ëKN—r``Œ¶nQ1’,ı¨A,9Šálqv“¹‡9Ëå¬7š]»úHÚ·¨áÌdÇ
ÕäT”<Ñ å/ñÿJ|D¶ößGèbªUys{u"¨ÌÅ‡àTì¹b´éñÍuÓŸù .bopòLÛ‡7¥8¼‹¾cèTÉGı"Fst§tsÎ’oLŞ9üŒ˜+/Y·4¬‘qÃ(Xg%löE4ÀºÈÎ£¨!bïE32»†YR–	Û$Šxâ%ïëÜ$É'úh’ÌÖ^pºi[ÌÄBg¥A8îº.m††4\y†Ü0¾H+ªñµ÷¯Ú‡®5¼‹Š“/WÈny»€Ë‹ÃÓ€½{zÔ¹=JúÄèà„œ]Ky5Œˆ¤?¢EÔWŸ6 ‹Ä.;ğ6V¶ç­œ^C„rJÚj“&D8n!8áìŞí¡¶r¼tÔÔ^"¸w1Ëu¬«Oh Ìøö	lÿPêè‚qÏû‰NPÉ|Ğ÷ıËCïóôÚ¨Ç¯mé¯BŸèòĞ.d·ŒÑYÁq›rmáşºçËª$KDoæËFøM|GHÉ@ÙÚä!yM _l°ğ³%:ˆd“VŠÓıe)ˆë+LV–§ÈÃM]!Úİ€¯¬tuÅª!+P¶%°ËAğa&Asääå\'Á&¬GïpŞbêÉ>Ÿ“ î£ Âr,“~ZA’y°U  ÚØÕZ¨ôvÈlçŠµ;ù4¯E¹Ú™/¡eé¥Cí UNÕœA¿ô†à‚\õ—^bd(šqz}æ’«øÃ×Ôi!*ÓØ¦Qô´&yä4¯|ıÁs[¨d@Äõµ†Û,.B Ê…?ªMÑ±î˜hé°‰$S&‰ğªŠÕL¶&tÔÏxÊá’©ƒ^Ï¾79·c°=ÚŞf/ÎÜÕÖÕR¯ş->`,%Q-ıR5"uÕH8Fßs
L³ä(ôÀÚQø'W°3BÛÿT®>ìqëR!áçsšV2h±“}/=¸šÍ’¤×o¢©ob¼»*ÒHwû¶¼³‹©>÷¤æ˜)Çdº&ĞRÏŞ*öGM¹I¥EÏŠlêÇÛEh¢WF	Ç‡ÿ¨ QnxiÓ?Ó«°ïíã¿O¯î/pS…©á±(FıáÏ…à_´œ?©¦T‡
ŸªBrøz@$L§?öç1§òz@‰îààbf›©TÊ¥?m™lù†¸ØV‚UÉ£~>[g^\ç+ïkwfÔE\Æç?ÊæDQ…êïàO¸·À%J9nËòøˆ_*İŞà_Ø<tÙ¨Úèj•q¡‰Ç·°F0©~Rh­]´Yp=>süü$ ÉğçœFÍO $”¿½—³Lšõ0Åç_"›.¯Ù7Gñô$X_°íÏ *p—X‚-p¦Ú ±Ï_¦ÖqO]fÄ´Ğ´r	dñ’áFpÎî üæ r
£|sŠ×æRYÀro;b> l:âÈÓWO
?ÇGá7fAãe“Î‡uç­ôÁ(ÇNy†7_&µª–˜ßJŠ%ÌÃßcÇznIfËDgÒNµåw÷¯S¿	¤§J®¿\ªYVà•c½ó'
õÂ$ ì
n§Ó'ÀÍàAİP}=#Õ—ÍU=˜Àg«ˆ¼W	˜£69$siÆ+0pç—êÎJ¢ßèy4®{ûBH_œÛÛWá”œ#™Qì_®ğò…Fù¾c$·7> …uqÁ²f­LÃÇ”Cˆˆ—‘îÚÆÕ2X‹27t¶ÜÄÿ¤°¥|ìZu“~:k¾àuO‰msdø¹Íd%Şc¸±aDÍ,ïĞ P½!×Bğ#LHÓ2"g$¾»îÂf’b*ì|Àê›O]vœS`~Ú8K~Ò”¹!lØlÒ½|òh%öëËPá¹¼Bî4UJ:Ÿ%ã’€›(8á]sØøôAé4]4<v5I¥ƒLx³qâ+Ò¥7–Ziæ­Ñ]SåÕ9î*Û³Õö ÔWHîÇ;gvÏ›MêABª˜ÁtÇ ¤&,D±—¿9İ2ı–^rp¯ã"âë	çÂc0—ßÿQŒ“áA3xc?-ú†ˆ¹Gh‰Pœ¯›—§‘û†iöäù½²BÄèsÏû¶rÀéCJb×¹.f %8‚b-ì˜TjcµVo¯M¢ÇFz ’™D³² lî›kP±N²¯Æ~FÏ‘İ©Ó¾ä®NlØ¬õ}–Ù#ÙºÏ¸×‰î•b˜‹éxÏ‡­g=“ AÚ`Ø6ä÷¡¼±i¸ÊJ7sæ^ŞÃŞt”:O¤NIç­İñh~î#ëv‡XGñÊ‹İzÄ_$6ÓÊú‹;?}?H}îˆPtëº:†şÁ¨â…<Bpªºœfš{Şnt4*ÈZ|lúè #¾‡¢¬ìÓ"m®dP™/”KÛc¶Ñ™îR`7.ş€T³%Ã¥¬v^5úçÿ‰4ïğŸ™N:Ç_İß"ù.v‹ÕË~µOÛ.5Kæs?ômµ{ŞtŠÜJá¿KVM™®ßQZn9àõùLW¼%'I¯ª3C±Œÿ’R¾}„¾Ñş|·Óû:ö=Ò`<Ù‰³ØŠé-‹m9ÿä¾'QU(shJ$të-iNÉEY_9Vü¶Œ©ßïlZ†aGÓçä¸eÕ–+üºû1( ¡²‚©b	Kï­^ QºÃAş6zhË_ô–
Ö7Ğ·Ã"%ˆİTï{Ã™RÜû\ë¿|Ij©ø^Ïô¯AôÃ[™‹…?«áRoùhó"ì0—ÙÇsu7ˆV$Ä,p­şl·\pşOÈ°B½NËv-ä¥çd}~øuƒkè°ĞrŠš)Fs)÷O/ÛİÌPŒ„È }ë9D0éÄ¬¬ë–X¶†à&yÒÉ³GüóÛ–7Èù·Ù#PNÄø«£ê§H ãÊ3õa›ÓP>@™Ò.X”K~.¦XÖvJ‚!*Ô4¦‹Şò•øRtpàOŠš¶d~  ›éó=ôa_õë4(–ÅĞ‰™á* +ùrªˆ	qŠ”8YIk+bs›¨CË½öà?ñ@‘ :\¤ît€Äfn:€ùßÏdÕuôÅ²½?’İæŠŒ<á!0á$äÛO¿ËIÈÖ‘rykÆÚM«CrïÂÎäâñX@kP#Eİõw4Ê‘¼Ç9¬ºxO hÂ£LÍª4éLè©®äì#9s/`œ6m>µ	Cx:ÍŒí•<ÿOXÕQ•İ.~#>Ev€rÌkÏl<D\“÷s'Û¨B¨¸¸=db÷"i‘¼â¾‘£wóÅ`†µoÔ€:Ú•;ÕØ²áË]ãñ±fŞ²àmnÉºYpPbOœ$ªè¸Â#ë{—å~bjŒrÓ_`ËĞŒ6?ªhh4T©HOÑ³~ß.…ØRªUæqÔqÑ7Z½Ü H2€Pûqcæ]¨ÅKÍ6şo{Aí¶cÁ¦LÔ§`afë(ÈÎ öÜR>÷ML<ÃÂ¨Ò·h£Zf°U’J“lø¤>˜’é•£J¥fÂÄ78Ş¶==Pw4ÇüòàC€±ÅÅî:Æú¢X:³å|ê®6ÙÃÈæöÒ3«À™ğ RFx”B=×=3úQ%scuMD—úŞ ¾_ş%½ZHÑ–ÎïQ¸ı!µµ‘²Š;'I@¾Jœ"[¡öF>£™¹ğ«#šh#Q^QÊÓÖ×î£Z!  ‘]“¶'ÌO,õ`^V„EÆ·¦Gjº1øïYÓ‰2vÚKšJŸR€RëìxîVôÇÔ0é±À9<í¤¸šø¡Õ¹ÍÍ§¬ø)Aãáût0òx'H/èIŞ5(ÅP·ù]í	®Dª}İë¥Ó·¿
ÙßyäxJü/¤2¯P`æ_õ~	¨äFø[D7öOÿ‰{%Ój‡4”ùX EZaá€>r\ğ5! $•üÂ ¼6gµé´îD>ùşS½ÆHq	®İõg;CÎè³ÉÍp­ÜÑÙG†SÛhÂœÅ·ùn¯s5c§@tˆŞT{«ÔY’†{Î8åˆ'Õ:Ÿ¢°¼s²-îËïA”ÎÛ¡²N¼d^sBêÜ4ßiÕ¢kğ©ÓFJ<óÃĞ¡:=fîºÿyÂïÁï=5Ä55’®°Ûâ]Ö_ÿê°öjëÈİ¸#yj'NùGï°-rST¿AD[x2Ú1Iè*ÜPvåÈ(-—(kXé0¢ˆÍ§õÿ´À¾ü¬~VeX{7şÄ³„VC±pwØÍ×^J*pÀcòØ¿ŠoÌi×NuØ¶€Â ¯SN:š§Nà-¾ÈgÌ¥”¨ÛXúüáwâW\&nát˜ 3Ø½Ì‚D„í_¿-ØªÜ I°qüg´zá)æ“çç…Ôi«ƒWVÌ›jõ!¬$x#êz€ PY><óân¬ªû{ŞòÁU?Uízâ/Ÿ›–_®.¦C½ïòÅBéë}lº˜‘êÅğp²>!”Á´ñaug-Lb—düæÜRâb¡„?{|U(úä¯LÏ™ùgÕà3«‹ß¨  2J9²¶{õ “³€Àüü×±Ägû    YZ