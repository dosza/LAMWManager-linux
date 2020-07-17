#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="927531632"
MD5="2115ac1421e6b008dabae0d4c4aeb648"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20708"
keep="y"
nooverwrite="n"
quiet="n"

print_cmd_arg=""
if type printf > /dev/null; then
    print_cmd="printf"
elif test -x /usr/ucb/echo; then
    print_cmd="/usr/ucb/echo"
else
    print_cmd="echo"
fi

unset CDPATH

MS_Printf()
{
    $print_cmd $print_cmd_arg "$1"
}

MS_PrintLicense()
{
  if test x"$licensetxt" != x; then
    echo "$licensetxt"
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
}

MS_diskspace()
{
	(
	if test -d /usr/xpg4/bin; then
		PATH=/usr/xpg4/bin:$PATH
	fi
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
${helpheader}Makeself version 2.3.0
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
  --noexec              Do not run embedded script
  --keep                Do not erase target directory after running
			the embedded script
  --noprogress          Do not show the progress during the decompression
  --nox11               Do not spawn an xterm
  --nochown             Do not give the extracted files to the current user
  --target dir          Extract directly to a target directory
                        directory path can be either absolute or relative
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

    if test x"$quiet" = xn; then
		MS_Printf "Verifying archive integrity..."
    fi
    offset=`head -n 526 "$1" | wc -c | tr -d " "`
    verb=$2
    i=1
    for s in $filesizes
    do
		crc=`echo $CRCsum | cut -d" " -f$i`
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
		tar $1vf - 2>&1 || { echo Extraction failed. > /dev/tty; kill -15 $$; }
    else

		tar $1f - 2>&1 || { echo Extraction failed. > /dev/tty; kill -15 $$; }
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
    --info)
	echo Identification: "$label"
	echo Target directory: "$targetdir"
	echo Uncompressed size: 160 KB
	echo Compression: xz
	echo Date of packaging: Fri Jul 17 16:07:54 -03 2020
	echo Built with Makeself version 2.3.0 on 
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
	echo OLDSKIP=527
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
	offset=`head -n 526 "$0" | wc -c | tr -d " "`
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | eval "xz -d" | UnTAR t
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
	--tar)
	offset=`head -n 526 "$0" | wc -c | tr -d " "`
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
	targetdir=${2:-.}
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
    tmpdir=$TMPROOT/makeself.$RANDOM.`date +"%y%m%d%H%M%S"`.$$
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
    mkdir $dashp $tmpdir || {
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
offset=`head -n 526 "$0" | wc -c | tr -d " "`

if test x"$verbose" = xy; then
	MS_Printf "About to extract 160 KB in $tmpdir ... Proceed ? [Y/n] "
	read yn
	if test x"$yn" = xn; then
		eval $finish; exit 1
	fi
fi

if test x"$quiet" = xn; then
	MS_Printf "Uncompressing $label"
fi
res=3
if test x"$keep" = xn; then
    trap 'echo Signal caught, cleaning up >&2; cd $TMPROOT; /bin/rm -rf $tmpdir; eval $finish; exit 15' 1 2 3 15
fi

leftspace=`MS_diskspace $tmpdir`
if test -n "$leftspace"; then
    if test "$leftspace" -lt 160; then
        echo
        echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (160 KB)" >&2
        if test x"$keep" = xn; then
            echo "Consider setting TMPDIR to a directory with more free space."
        fi
        eval $finish; exit 1
    fi
fi

for s in $filesizes
do
    if MS_dd_Progress "$0" $offset $s | eval "xz -d" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
		if test x"$ownership" = xy; then
			(PATH=/usr/xpg4/bin:$PATH; cd "$tmpdir"; chown -R `id -u` .;  chgrp -R `id -g` .)
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
    cd $TMPROOT
    /bin/rm -rf $tmpdir
fi
eval $finish; exit $res
ı7zXZ  æÖ´F !   ÏXÌáÿP£] ¼}•ÀJFœÄÿ.»á_jçÊ}fN¶ÊÖñèËt+¨8,mÖ¬G1›§C_ı ğÍd¤šÏLı­XñdõvB+70Â?ÚHÌ4ÍJØü"?8&Z–9ì²^3ód”"é1¤Á	¸°4ÆÊpGÏan`Ó2 ÊĞÆUZ1Kõ•òŸv	nìuİùUı"Á(ó{zz£yñ&Ìsëœº”™v¸DÒÓ>s‰ì–
²u"ôío_¾>ÒDaâ:Ğİ^ÿ]m,-j‰l-BøIÌÅêßàû¯gÔäÎ°¯KNXuÒâMğ¬§şş¸ñ¨}:ÕTO;UÏêŸ'8ÒK¼³¡¤’'[w@¦™˜«tZ™1­›§ÌXÀßw*D°´™Íâ£yG`Œz1}•e“ƒ¡YÛœÜ×CëÍ_³¬«Ü[#f7êˆPwbÕ¦w9ÜjñàÑòße‰k8·\÷¤¾şò“ëÜ	^È€ò—»Vv0˜[òuğÅ
œ¿0ŒƒÎÅn®0y)¥póˆ™œ[õ®€&ä}èÄÑ-ß‡›Ôg«ÑÊ’¹Ucm½¨íçÇV@M3)Ó%Pæö\ ³8¤Äs Ëøİ
1RÛËÏXòó—Æ_ÿfíDŒşÏ@9—şñKƒŸÈª!Ü§-æ×-o²¿CÅCtYUCVí(Ã>Ÿ„QŸƒ€îUÚş<_Ø*SFÂ7Ô¡Òå¨’Û›»£¤öBùxÖGÖü§,[êÜ#LL’ ÁØÜ ûÇñ¼L³kWdõc¹]ĞbÃÓE*9êGËPxÖ9?ËÎÛ°r;™Ç‰hêå»×üêûÀ&ıÿ»×|SùI×â|¦ı”‰ÎÇïx…f¼«Ù´pO®«FÄÀ;³­¢¢r³h’SD0gsgÔKe”pû_¼LFÂEøN±sv œ\3%øƒÎ±0#-tøÓæ¾­ÂÁÃˆJÈ"–˜ ë>›Û1ÔŞè’›NEJ“y1ÁLGÔÊ+òÙ:›!.2X¶Èµƒä‰Ñ32|l6[—Ï7~Ì²Œö)ï¸¡ ÿ¹°”ph¥sqÁ{Ù¥Y:_Dn«Íş]ôš¿Y€«º•uM‚·óí1n/Yª	w§ß]‡”‰<é5ä0Â¨FFÕ¿mGcz¬¹šŒ(¯Ä-Ú,úF ‚êæ¨|óN<æ mÜ®hpJ€•#«>ÉÊüD,v"ùEŠĞ3…?úş)‚§
ºšNNdd`fŞšİÙ÷	FnPéèR§Ë-10LaÍÈÊ§ÿPZÀìe"Åƒ_ùÀõbé‡LQ×|ñ5²9™¨uŞ¯Dìe=ş2E4Î¤´63@5:ÎîGÊ×şóŸ¬ aU¼~2šNc/k´?vfÑÜ®4áX¶ÉqlÁ]ì!Py£§q†DŒ–R“~BŞ¾/”ˆ'0¹ú–%ÔwP¦ÈÑLªD®mc“±Ğo¸³ùwPQ9~ÿÔ"K,ÈAï+
šãîÒïGw!İ§ê':rd]2;ÒŸÚ2îTï›BE5\·ü÷Ò5uÀ`ÇC†ô	Ô—}†5ÑqHK% Ó_(AæÏTK½}ÂõlÚˆ²Œ £Ø]£†ºö=r°Ğ?¼dz±İ`pÁEbww$‹C¸A©«iOÛ8G‡·ªQZHßñ'íªÂ©¥WÅ…yöŠ>S¥M+‹A„¦qX„ıÁñ˜d¬sú7©á´ûcÄé<«fƒéva#ÚÚ„±‘Ô‡1›|äÂHB4j°$¡¡ÄÙf›ù("Q]Y2[µö#Š«İ—uËO«ÂULÁqÊ¾v±dÏÃºÒcÖzÿóqjh ï¢‰Ï1ğB	›úv-ğï¼Óf\òöG*›òR’ñfá|‚¢ÿ;§¨,ê*:-™õ˜†üq.ñCÙ÷ïËÚ ¯À¼Úà·ûØŒ'„ÛìYN]s' °Ó\ùÔÅµ XQ:vö -öb+n!†z8‹ºVéJ%àÉ¥“OñhÔ”#á#–èlnËÓöØĞ<š¯äM1#;g|Jzíïçßø'ÉT˜Ê1‚÷ªûèRÀQßy‡úøĞ˜ÇBfÜTŸ›0¢F¡ÊàºœM§ëa0 ÇÅs}¼pmgÚçL5œ’«Çµy¨1ÊÔü@‡$Ü× ejP\yºíôĞğ_ÒÓOÀŸõ™ì¤€R³Ó8]>#nƒU¹.™+ÔGˆH
–YÂ]£Ê:ôĞıª—W*?Û„u°Êêêı £²Ü&DsÅï®æDT³mÙÔ€A£6w"Ş0†JU*¡µ%ì¹³÷¢Ò¡áâô’C¦B›ºZ?e{àì=p»2VtFCà4Qwï²b˜…Wûæ”9õæØë¶¦5Ü˜ @„H¥çÉäO*Œ	ƒÊ½{I¶ºzºíZá÷ÙöÏôùR6WÇ¦.ÏM½R}’¬“<$×§~<–JàLeëHø¹$ƒšéäaşÔ¨Zñ«K¢ÎCÚ	º’¦1QÅ™6ºÂÏå9$&.B¤qöãİ½"æ\‘’Ê¿zyÅİexÏzZ¨ı…§¯(ÃvkÀ‚ÿ…í·2ÑK7Ö!PÕF
(†Šø²WhbÓ â‚sØ*ÄÑrYLËËİjÍ¨çõv'pò9$ŸîDT9®A˜f]SÃÜM	ö™w-œÇıN³ÜïE[¤\oÆÃ~ìóÂşÁj¶ë7à|Ëù_-ğ^ğÑÑlb^ú7se„Ú9Ó\	ÁË™ë~äC[Ö³|Àå>ìŸ'B²{‡xÚ±|-¡|zÕ#^íìÑ  ÷·–›d‰ùT(~ÉİÄ”»‡Ñ(Eßd¤ä@ê)’|NUŠî¨&Õ–N¸8S2áfxÛ\Öóø+Hú˜ª¡·´Vâ<Û´õ‹3uCªÂ”+§äp¨Sõ: V©¾å§E‘F¾À¿GØÇ®z8ñ›£Óƒ4‘`R$ñ.;¡şc½t€&Ó²¼í²kwÇ›©	ú–u£õo D@¢u tásïR
ÀKe¥]X´Ø_üª:òJÙ*ÿ-ë»¿iım¼q”+UÄ­Çäë9ìº
”µn¸¯D&æé…û•[êƒ¾£J«U¡•~j»8¹fßîÀ-ÕiƒÖ(|}ğ%-*T1¶ê3¨Lw.AN¦œ?ì};X÷kò£Ép_?ÓÛNvŠ)¦ÓYòHı¯ÏKì7ªıÿoÈRØìåuc²ÔêjöYdlV¬e÷oÖ¬Õ/ôE˜{©¶v™‹‹Pù×!—íq3íbËĞÙaqu=÷F€Õz³ŞÈrjàÎ·ÀYûyi‘˜¤ªTëŠø‚P´üDœe®›1î]ùnG=Ù¸FèúäÎ8jDi¬®4#Xw°kó¥olk÷Ÿ¿¸ü2é¿Óø÷)š’-EL¹eraÓ¬ú½AÙĞÖ´ Ù›û—?,˜0”ö’c:Ô³è˜¿Úê‰Ì­àzõ/¸sıe¡A@ÂÁÂeÜXIğ’*¼¼Ñÿ³ZÈO¸ßŠ[™ñ€	bØ×
wAË²öÜ¬|«E;w\$u|yxıNÖpcFÍ{—ĞÙF “­áiıntç{<‹Ñø)ãûÑÇà_Ì"·ÙŞ|ã‹]_ÆÒê†9øú.0 ñˆ5¯%)@Dâ²>Û2p¸^€g2 5ß–ê^ÀÅ-ƒåéÖ&´áÀR:˜Ü[C¥zMuïO¨2a€WîxÚÑL¦¬ƒèÙ#”HírÍ£LGŸ€BE³ğLúû»šì[ ŸÜg©;!cT„ZÏgE
üĞÀZDáD“ÉR
‚v;tıüY´ ¾Ï3aLz¸Ä2Jñ>tyš6É£]’¿†ùÀâ«æqı«¼ÂÔ]Ö(šSKZ÷ÇZÙ\£ÒÉ
œ‹S‡¿»‰¨îu¯/-ï€šT´Ó¥öãşÖi’ƒ|ê%VµŞ¯bß
®oı£(ër+ŞÅõ*—?‚zÙV³ç“i±ªa¿Şê Æ>óDà¤¿*¸A¸3Û~_eÖœo[¸xL"(àİ€ËvyúĞ€-{ÉKBjÒ¤.ËÖV9ˆ[Íí=«BœÔq“¿4’D-Y‹cì4ëG¶‚Iá_…çõ69=ªl±Ÿ³w7ï‚C‰x4yÅ,Õ»Œ[çåfSéÜÚz®eCééÆ±]ooH¢ È;ÓPSäÈ=jW£sT-dÀ˜yP[S™„æñ¤"£¾¨ŠÒl8{.¿àÅjGÊ1^¬Š(ËÎ¾=fKùê?æÕ<h,íˆ`*İ°ºìï•yKÕtGLPã[Ö¤aT ¼zs)`WeyQ,¢5±R`ˆ­ß¶È_9ñBPvËÀ©N¤î|QÔ—üwî—sgw¥
Ş&¡eBÀ
ïï?S]î½ÜÛ#ş/WJN'P™q5Vw×å¾r:]$ÓÂ&"´<]UWCĞìØ@E“hûöSÜqi1'–Ğ–óÙ	 Ø¤»Ï H ›•(©Fi)$w‹½fF€Ş€8¾ïØ^àI™¶lŸ7y‘/tn–½Ù&XUFbŞ„­NâÑrW= ‰“ãf´Î¨1ÅwÙ#õ‚µ¬øVV‚!"[ÙEáJoÄ7•93vUny×9¡¤¨ Å"_9lÇO×Ø(Ûå
|È–
6½"ixn—”ØÁPÎgµ#AÛ/Z›î¡àöÓò†|şÔcóá–—eÛéC-W§2È¿qJ°ç!gœhyDGß%îDeKùb+4imo~/D›¸ĞZd~Ÿù%\¦ç&n—K¢ïÀØ²Š.bf{í”Y~ˆqõi	,¦æ×$‡l%¨mø[í…„€/­iD¦Jqë¾ÿ³Ì;]¬§+m‰ï'Ím›&Ñ?à‡ÿƒ0±½‡†áÓ2¶“ãñyyŸÀ½Æ?–¸gØ±ˆ³²ºRäj•ì[Hamê@¯æÉKèg˜7|üø|ÌNCÃß"8;lûT)˜±Ó‚´^•¼ìÓ_œgRYù¿_ñŞƒÛ“‡=;Ç×:nÅH&t âëG¬ã•Şä ¼Éƒ./2	£¹µLüÄ•q­á6BâÇo ^ĞëĞŠBõ—ÿ—Üª7ğÄå‡%8ÙV]!¼Ö‰B<Ò#^÷“©TÀZ®Y¡hŠsò¢PIÓ8?æè;ÛKºÃéÜØŒôì¡‰…ÇğŸÄI|²n¯ÜrNP—&Gm%¤»‚ô^ÑÃ"k÷FÁİ¹™®VuÊr˜Y’ÛÀšñˆKÏØe¨ZI|†İxgÉ·tYò^(Ş®FÔö4i‹Xj¥®©5!ŸÊ˜+æ(¦Í—=Va®?rÄKîöwëŸû…âÚ(i0¼}àÓÓ(`è4@åO]ÒÃ³:&u½ÄÉÚ®
øğ5ù!‹éè6O7„¤‹Õ›«—Óm&µ V÷ÑÕ™3@o_v3åêı£Œk¡BYÆ®{B0WŞ˜'¹*g ´eÆû]ù‹ò°Iï3Ğ'ŞËÈTJNQ½CaØ]lÎ1«—9ÜÎŸ[#l÷6ô>w¡˜'£GŞÖ´­‹=STÌX‹n]“ñi›Šı'	¾ğÔb–Y€ş¯ã=T-¸ü€Õ"§¡Âšúµ°ÚE¹iä[5³†ÏÑKªà®¾x$ŞZS½w\­`­Ú#‘…ÛœîW£.f¨w™*F¨MeW‘¡ò	š3²tÌÀÅ¨óùruŸÑ§–”¶ñ5ÖÏT˜ÊEşw®™Ø€-¹Œ]@´á]İ…¬‰òÜˆlËm‹u¯J™Ó\BaÚÖÃµ¾±‘o)»x÷èK.D~Åšáäo$ì8Óïãû'(Gœİşƒ€»9IÑ›•çoÿçÎù•„„:ë[¿É.õòäfep;mB.z©Ÿ°p²×øÏØ›Rw%¯ä·ºôE koÈæ3(¸hä£ß3veâÛ`C”ı!U«Æ0mÆrf%u
 ÌHÛuğ£.ªŸÛ°ˆµí½c[ôÒ°O›·Vy˜jÆÃ -sa¯8,¨ƒÕ„Ï°‰˜%Wè2‹Í!hzfWÎĞæ‡Ñ“ÈÃŸg·‹_º	P%ŞS?Dß€û©F>Sí/èß Y¸ÇÉxN˜Í?˜75ÆÅa×¢ä
³JC m÷ÙÄ @í9aàÙ~âµÅÿfÍúpî>KßÕˆø_ï—Ú=Æ•{‚H¯Ä GñzòNj_B­h›,D^Wˆ[ƒŒNÖ¾° áO©Sé*í:£a¾ãóùı³__fßõ£{ÅÀf®û¡À wv÷™p}Ú éÛÔv!›ı FÆÀöTöÅÏ™1·;GL—Ja—Rvxè·ÄJ;Z¨ü‰±$DëÅå<ë®.¶EĞu÷®[ÿõå¯½ ‘I •Üf`J wO"ŠÚÇåtˆ( è;¿üO_ õşÇòÑìı°Q?:G>æ¯íßï”HMÄ[$,Õ[ÃÏ‘•L\Ü¾™
 ÌûÏMQ­Û.„a÷m»g!¾²ú8göCëÔş7ª‰ojlœÎ­†–äšğÆÆ:]À¡ºãêLãUbî…è=Í¡,*¶nØXîvV©éUŸ3şùÊ`xP¡7÷dQúr>+‘wçèÿYÍR¢âã>Q2’~RÚĞUXçhğ¸¶ëß‰±Cˆäm#›tØØÑŸ“İÆqó¯SŸˆqJ¬sßQ¹ú6§`·=uôS¶{2<p¦­NĞ¯øí£rÕ„wÓíoy©•Òàõ´œbú?6VĞt0ûÏê!HŠ¯Ğ ÒŠ~¿_,bNşÀß+A:òêAt"(`d¢?®”Š"Ì½å=(º7¡ª‰tñ!¡.…emì|¾‹¢(™]_ç;0’KáŸËFÎë·£K{°ÜÂ±V9Äêı÷¥›
#d"Ñ×M’¶íßO5dÑÑ«ñ»ì‡]+šì­Şd„;÷â5‰:Ã[Ÿn}ø~Êâ°ÔœwA¾½| Œ(z;E94ÁÈFf¡ıŠDÊ¤ğïl,yN¤ì2Ş]èòOã¿«mÓ’èÎş/!$g\.É!ç¶0a‘úO!«Ñ®86’%! Ø¬*à5A‡)5)KW$ÅoÑÔ=íı3¤î:G›Cš¨QÊ/qz%z˜ø r:.fÙ5ÏÈTPkÎ0ÁêÎfLõŸHˆpDaAoØ¶°>U‰m†—XÆª¼H’Ö£4}û™¨–n¿j÷)6‰&´»«ŠÏ²E$¨»(…«W*|<£TI{R"êxá¨•Â.8Úúßº8Æz“u,j,Ïşh<¶7,ßª°³iÙìOô˜o÷X`\%Ÿuâò6BîòõxG›¬¸Ó)ÊÏŞW#ß0´uèŠjèÆB2U¨‡±æ{.®ÍŠp‰béî+²ı56ß&¬ê_>èÈ5ĞåÎÛ¿»›nÖG›Gk¦Ö (·MA{Ëœ„u5C‰{î]ïlÁ¹ŠsÂuÈ‘EİÎQGp¦lÀÍi…Š°×ş³‰ö¬Atò`ÿMxbVd×gÉÜLÃH…Y=†Šó•mI°:w^Â,ÕG+¹é‹ËãæTw%!›ŒÙ½µ«Äºç›{¢&ôuÊhÚiC¡æÜ{ùbKv’‡	ªüÍXÀ¯½ û±ˆ;ƒ—[¥…o¥±J ]øÅi_8§ƒ—šBÜwö……ÛRœµ]w Aò`'‚¬•k¯kæ»Ò™ş©Š©GwóV{ê&ğpáºM“nœàOSk)ü´ÒWÆpE©/±šŠFÅH+ÛS›£FîÜ]BÄÜiG$Ú§;Î^UOÏe³KÏs÷a›,R8ôsèÈæ™,‰àËgÜËÂ´üÖv0É‚G?‹Ì·É
¾Øéro¦~MLã5KÙ)ô,%Ûvø0äK>	âºU¶í-¯a’Ø
!/n[L¿]¶SØ3HJS¤ Y8Á×ˆqÂÈCÜt	>F¡¥ã²§.Gê ³RM/hd, Õ»OÍóœÙWÇ²Í¢®OÌØ%–<oËnÃÍÆKÀ†í¨Kêl½Î€Q=NÆ©‘?Yä%)/hiß’ĞÌ‡¡!'BìÈÁsKıÃ Â“›a`½Ö%¡Ö‘ÌA¸x°´ÈÕ6fØ„=DT"ı¬ùÎ°Vc‹gX@ÓĞàUù“ÙÈ \v´}7È©0·ÕH£?ÜÂŠ¿†ÿÚç!:Z”ï!\5
à­İ#êÔÀ¿Ä5ŠÈ=„ªQo¾–ï­%} áR¡&Ö<ç½Ù°++åªT¨«DRãìWÀVcLS—}ğÙPÅ« 7h¿Kà«Äúˆ‰kõñÔÆ„j°OR^ã|ÂZ¹ç’ŸX×~¼3ØˆUk®ëÈâ@ vşz~@~*[µ¶–Õ‹)-SÂ±÷à«Ay5²Q®õ{°-o‰uêÅè£ôù‘Òúíğw½˜Åâ«­a&¶B›½rIá‘GİèŞÑ&QÃÖ´L’$ø"Æ<ë”(SgõEØÌ	V¤xê1<æ?ÿòÚ$Æø*Ö¸æ%æ4ÕJYÎ5ƒüÉöOi5 €:š»ÄEµªùqé÷ƒèE£¤<.,Ú5e:~û.gaˆ[rré¤Vßî¢uŞázÏÚû¡½OÍCr¨;ì~×`M¸½åÛÆRÿ¡;æ?Œ‹•f¨šÆNg[˜Y¢WØ‹ç½G¼ é«œ!·ĞÅ’1t%¸9…CG~¶Sğ-ÛBaN¿‚ı_³vT]ŞÌù8&í¼<Qu„´õ}æÎ.Ño·ÈÜwxë{ÄÉ^Z„r¨×^»9Ç½Ç'ZdvÙXAÓdtZÓ?,Aì±B¥ùvìŞÑ„Í®Qx?æÙÖôœº¨§=o¸œ§ŸKoZÔ&½Ïó6=•·ÄÁ~œ©eCè‘¤ZXâ‹ecl´4¾ŠÕtgÁ¥8(Ë7\Å¼Wˆşnı=4ZŸ2t8\?øäİãéôd:ÕIÏ1 Ã	”úLdbBL¹8#÷ŠkĞüŞÆšXäöEÂp†#;Pı¶Nªi³ıx¡@0fÌ4ô‚Ş}/ÖXg‘6Ü3ySÎŠõğXc¸·<ÍŒçôÂëÜ.*HnİâÒòÉ Á]qÈ0 ¸Y°±’ĞÜÁ¹ ²ŞLÕRİnyv=Ü€òü–<¦EÜ)MëÚ?“2ú†â5ÙJ…£MPÃ²æ+ÜcaV<Rµ€vÂ"½
õú¥÷cˆÔ@³Lİq¬PW,ñ\û¨œèM›¥¸.ÂO\	qÏÒ×L HÄMİD¸RvaĞED€m0ûPËzó÷¨
¨DgltæÁÉ3}ËÅ%@Èı®ÔWû˜xáVàT”hU(Í@£¾'SV™ô$dd½é‚†ÃÿÊG)kÀq&dJ$ìĞÚÏt¶<°ŞXy3ëÚNZ¬	«ˆ&ÒkÖLÄôPCÊkJ&!SaÊÉĞåŸóĞ ò—öµ£ûé,â-d©u™d¯/Æl ¢TûÂKA5÷Ly=àp€ÕåñÓfı~ÔPúƒïf<’Ğ3ã‘fH±¹1Âó7ßoÔ7R¯öz†~}«6ÜHÂşµdÜ©š¼ù·à’¤j³es[ ‘\wy›ãYùB1-”ãÓõ¼Òõñ~6 làO.&¶Î^Şëxø&İ›J’_EY†²àíÙ;JK…¶õÀ âxÍ™qpû'ò Õ¢"İœl›”Z¦¾¦ÎËB{c¹èİGûÈçs€™Õ´À ·õ2.d·Y;4Í…xòÜQJ1„S}Í0±Qn3bˆµ¾¢xlß×Ìg‘¾x‡«;›ÁB­Ÿ?£˜†İÑ¸EGªT‹«)rzïš´Øî]¦Î¼†sİë÷e:&“ç·ë0ÈFGá¨nòu‚Æs¤8ÚØTßoRA¬IÛ3~şúm«‘aºÏÊkÙ6İx“à(²Á«$Á¼ğbbÚ¦6\o0?`°«"–* ë¦kÜJşü	WÔ-.Ğµ±:?&uøå`ÏÄ¤,§Wäª–PyœÏ)àúYº˜$n&â’ÃÈC»¶aD›e.¢”ä„TÀ
èœ{®Ë/”°e^?ï¤bé‹±~'„UÂ,ñ?jr`'ı‘øIDİ™ëâùfO°¹sm¶ìi–ı(Z<;Ë»µ\A+1ÏŒş"Ó¾nP|{.
éÂµŒD&üX‹ƒv)«÷0G…´$~šì§á¤¥¹ñmÏ/Êş…-™ş–úVø=‰BÏ3xp€½[öéœ,	q«š“Oû ½¼ÍmRU4Ú”n%¡º’oeŞªŸÁƒ9ûcù|şx³»ØÓ”v(:Ì0÷­ÚLİkHƒÉjF¼;$»o«b|¼=,áFDå9(	v 
fh§xœxA”íÅñÔ Jå~3¾dšâ­‹ÖÉf05ïÎ•He`‹(\z©FŠšÒ¡C’*[B¨é–Õ˜óXkÇwÂù‚¡éXT]@½!ß)¡vÅá”5ã'z²6Öôwû¢ÙGÈpÈ¦®µ°ò Ú *S¤[]é>˜ÅCxz¼h	æ¶e‹çOPÈ‚v¾6–J‚`$ñ‡U°jşôg¹ùÇ1B¤}YÑÌ<gØ~<6ëÏôÄ’û½‰¡5G–Öp»ÊÀ4üİ$ÚSêÂ³Z^†D¿ç,Ì:àS÷´mxÛ „2{1Ïà‚ÉÄ WùìÅbîNoÉİµ%6^¥›I°´öuæ¿;¸fhğ3›-$(ÿ•Œ¡BhÂŠ²İ=9ê¶*r÷ •j]ik:{	\2u™:™Àj%"š·©cA+€Œİ‰I4ÔoFÎíõÊùd—BË½ëík‚ıV¿Ó²[Z¤b¤´p·
.Ã\šv»'eß­ûÍuäœ¯FvJ«vÒ?ŸinïĞ1™=õ.ØĞa2£Ÿù©XZ£s¡yWFPMYÆxÓ—»Î]7Èğ½!ã$B«Ûœ;İ"?=ÿÒTO&•y¸ÒœèµëüBÎÕòHÁÈ‘,Ÿ¿sñ±„ºOš¶¸]Û`K~ŠšíLK&ˆ$8H²Akï-(2m£gîòù =n#§¢Y9©Ã@n~İ'» ÒE¯íª¥
Y“Oáb_>âãh°Ä)NÙ˜¤)ëó~:Ì Ïˆ ±Î¼Õ+[÷v¸™OåÔEk[*úÜ»º-k¹@S×ó¼Ü ‚GÙÀ´#íGİM¾?çRp
ˆ!öí&Æé‰ˆueóºÁÆÛØ7&7gÒÇµàöj.GÒqGø_Çª!_­§ºWtNf^¹ı– øï6µ™Í Oõ8©w;‰i®8§ÜÔ–pMLÙq¬äiRø~o,+şÓrï4Ë‹GºÁ H>Úë‰ì%gÔàLfUĞk¥Oˆ7æeüÃ›È‡-ÂuËH0¸' üØeéCÚœŒ¡›İü/×Ì0ÍU£üM” /-ØU’Ç€#KŒƒ¯è_®$rõˆŞ”‰üZâÑ²îv‹ŞÆb:¿”Óß›£gÁŒä>0Ò5¹Ş!´ªP‘¤¸ûùÿ‚yQœf)À&‘²ŒDiv6ÀèpúÜµ÷Î8µ3.&o5bÆ…~øŠ4:“1"Ò:/:y„°. 1íjÁo²ş¾fSÅÕ»ä×8.ºıòº…()ÆJ>ÚDĞÿm²{QUÜcÅ€”-ÚÆwïíQ¡ûİ7Ààaxš®¦3]rúWu°fİ>	“R$\—&ğâS7r’ÁçhmÀVi-àÑBíë8sšbĞ/ìß‘b÷Ö^™z‡ WL÷Öå@”ªÈmÕà“&ŞÊ„Ü^ }írı±ó'â[2=ënä`¤ƒ@/g!R¾ğFİ™*†z¯C¯³FFuŞ\_”Ní3Ò–€F;"s§2™×Ğí\†·º0ú@¬iİ{l|_ò»‹dPÕ7oR°ùN‡1å+`…ò$é§¤s¯ƒ8X§]&Õ5e…	eÅz<nh·
U¿šhOJJĞmòoJÌ²¬š“5ù_ñë—U”©¯Ô¥w¹éÇ(^6Q¡ªdÎ‚CÉÿÙYæ§KäšjìÏ•#±|?4í×°<–ğûêG‰Zõ’^çoÿ$–zïÜ¯«7©Á[)¸HX„cÜ¨t9Õ×¨É,	yL°†Ö±ôÍ•b+ñK>Máéõ|E(BÿIÂ¾¡ÎËØ›¨Ü¥»+´˜¿¢è¿7wLœ›d
ZaÒ†Õ£È3{Ğ/T¡+.350o¨ü´œØI.{€Œ)-fsF² ÜÌSõ‘k¶ìÄ«	ŸÙÈ[Ôve·ÜÔæŸ5ÒôÜsQµgì]jL\Ì½«JÍÌÿU@£€Ó‡­—Œ$ÚŸB3¬7óŸqòívµØcò2¶)¤¡wNäu{œŒíÔÛ¬ŞHÎC£_qÚ) åHÙîyË+“–¸}
‘x½û¼€GÚ<åÊÀ™à•n{ÒıfÁñĞ¿*wÁöÅà¾`Y5ë8ï¬¹®é€?¥ŸéÊ/@ :5#µºíV½Ş:G¡Çø¼=XÏyçï£HM÷Áb¡Ø‡`ğoCª,Ûmd×CBUç‹zÅ‡JHEûW`ôó§‹UxTì%¤)d›4#½ú—&º¬`PŸFy¿®6£‚`û/i9d.×´aÔƒ>~™¼ /ğk,°<sF×}D¬TÕ:ÁFw‹D
™&lÊèíÁ8‘.AA?;8ÚİGKÜ\7-:>™e1-0¾¹O¹²|Ùr¹e:X=µÃE6Be¤â¡jD[ûrŞëuÚé|èïvĞ€IöÑĞ6!+\»f. &r!¹¦^ùõL½X;8ŞS2¿°'¤ C#-Úà°´‹qì‘EËM°È‘.†h§Ñ’¬äYm3ºŞ…bbIOm3räæõFúî‚ÅQ“EèVV'/ÇsÛöâEOß×¦Ğ^fídÒt<ı\!Ğ£±à/DA‡7‹ÕkŞcêÔ©"dÑ8à^+ü?"º|ôŒ9Çü±à6îóoS°¡ŠÚm4gmNy“ÙUÚD ÙİGLÕµœ™Êv&¨gŞ.©sw¸Ş@fÙš7ÿß"Ç‡lTŞ '_\™ìn«B¿¶¹šíBmãŒø¥LrıÆG8d›ÈÓ¨£3I)vxı¯D1õN;ÀÄöƒyÛ”áé[(è
•~ÿğÜä²µXëş2xè<{ëâØÏÎ¹œBâî±/Öû !„Íï<ÿÇôĞ±tF@Ø‰²ê‰ñóÓ–~6ÏÌ=8öû¦¢F]Sœ‰F·¦3;wôLG?<mUŠ•Ã&NC~†²f¨}í~å52™tºTB;–¿Ë‹mcí£fÒ,ßßkÒI~">EÊ+XÇî¢·3«WÍû¡27J\©êüÍ™ş_½¶*„Şm3Ÿ`õm=‹<%°˜A/Ñ¶¼½ÓŒ¿ê¨YXÊGŞzgñ0±Ù=^CV¨‘dĞ9\=¿#\ğz¦}A…še5#¸Î€´Çê{§b–éşÚÛd°Ò/?{ÿê2C¦xş¾ú2¿4ŸÔ÷8Ïş£†ğ$dŠĞó2æËz«[:ÂÚ:ya°.ò¬pÍÕ“g‰WäEì4Ã&ª!(Ñel;Şc<éÊ Ôˆï•ÙdlûÕMõ÷@·‘Ş§NÌ,9I[şQ·–Nè€	©FÔ©Å!È?+5ÑÛâ‘Îÿš‹©G†üA‰¿éáŒ8‹á]œ!•{/Ó÷‡‰#Šï ÈøƒÂ I0ì¼F‘ƒEÎ¥}n˜åï}ö8¡ep¯ñ	&|îñÌ·Ş¬>«Ú1”¡3Íè´ÙawZ§Rp¨ÃÁiV<WÌ;y7fvH)İ$z«_Àï©¦·ñÂuéûÛé:5\¾JEqwGÿ~°K’¬9“Är¾ö®4SÇÙ÷ÔF÷Óşséx´&Pèh†Úº!è(k
¨’NÛÀ1øĞùéş‚„Ìp¸ùø.íá¯DD\¢$gÄúüËØW–j5äe)X±*JÓ8( üfiÎ½K#—Îµ¢Ã¾8Xº¿Ñ:’+ºA1S£¸‡×f)ÍtlÆaáİÏ]~İ”ù•?Ÿ{Î‡0‘`0èc¡FŠĞ»^ÜIT [dOy‡ÑëòIù_ÙâLï)Ø.¿—ÅHgš¹À1Ä_zzCï)+~¿g®Œ ÉïÉö+‘ª³£]à(
E&Ä:—Ä¦¦^ş³Ö¡”¾mArÆíbÆcĞQd;ú”Q<*ü£_àL•TŠlâIÉiËYº2'¿~Vü>µGÒ.âè¿?GX"nşiäş(×´´ä
º ™r‘Ã_E©Ç¼ò±“ætñ
ëÓÛo’Ç‡á[E®Ë"zæÔß¨‡Ë­>#„È‹,0m…=¦,¤X]Ğş2I­×<\¬…pA
FòşÉ]¸ø/	‹4õÜ¹okòWÅKÚ^|éØÜq·ä#˜®ks‘æƒ`ãñÄ©]TÈ¡F.yöz!.Sê¼‹IİÏş@ÄOÚ.1—,¯¢îd3Öè×+÷¢’Äl™ıä¦#F¥(w 9Ê#ÙÑşnÛ\ã—Mx–Š CwsËİÓNšIª¢A¥îíğ¤·¯ıÒôQøùò¤ésªg±æBõ÷'½XkôbÛå¢.¥:î¸ˆ.Ï ¿%•ÜŞW=óôñÜÛx&éœ4Ÿ•\O(/K”ëËfdÎ:4ĞÚµ¥mæ»m<X
ÓÜ©1uÍš³éŸà¼r_M±ÇS-uíï*÷ctÃ]C<sê¢Ó‚â"hëK‹•";Ÿ]/«:Éà5s šÅ6tvMŸ÷Q sÑà®;Ü‡¦­ú¬B‚Â!Ïr¨¹V$£¯Uœ!ŞãŸHƒ¢Z"åƒ†ìsH¡²È¶çCªqsAHÁ—gìXÄUä”Ì¹Ajd¨Çñ­Ã³À½3,b—ıánäñ@öŸUˆè¡$îh=ø€ûåÍ•H¾Ün]0Ë•xŸ©:6ûí8±·ÓÒ`Ù[œ~ãÌv¿â»÷`ñ0uĞ ®™,Ì‘?ªãŞ…nŸQrš:¬[QŠV;ä{ìNºá‹nŞÛncİnĞ‰ç#ÀµšQ¶?Üœú,Rüšƒ3¦Ï›åØj?ÎÅ >6dş/âñË:,Rr;Fl:£ê•¿aƒ|Qzî‹ÖµöøYıT3Š‡Iô¹®1«ÊõŠrãË¨6¯ë åÕŠĞ-Ø4V9
Ëxpáh Ó{(”ˆ7PÍšDm„û4êi…ø´rOJ¥¨#m‚£ĞÒÀ´~›Ù€Âûf5‚¥çS	<õßøı(*¼ØĞĞjVİ#Q„¨ïù¡¢Oó'N¦å¯DÎª¿Ì¨’b'%¥jÑ²ä­}(p‚Ñ…3Ì&k×H™ö’Oæ!f:Àˆg‡ö´¥´aŒ¤àÄ e¢‡j¼ãè±Kà ß`?¬ÆÇ’ş?øçsÈJu
ô¦=ãGn˜ûåõô0V\—!{¸ñdö¦ş:%Œé.¥ê;p?TyÃã8\ÆèÏáiw¦¥(:PÂyWjp±ÔÅürVòİ¯ZwJu¬@0Eõµ\ÄµLåp"09É³+Xòœk´
âPéÕÍÒöœ¶ß%\hpáT¹E¤TÒ•¤xìÁæQ7æêùëšï<âwC (_!0CevIn÷¶8òqF®¦»âÄH_ôZ½-Bmk‘ÿ±9ä™¼†Jñöİ½;HäÄ6cN<ü³
0"q¦y@©zRvNo¡Õ¡¼ºÄø«!@Ø–îz‘ï’û·-¬…YJfÙøÕJ$_qk€;d’Ñk-eŒË“#×Ï“3aü2Ê†å›{[‘› SœÈ“N´\eyq%jii[1÷2	ĞIL´³ŒTÉJÉ#÷¸Ø!ÉÀÀ
)#îUA7õÆ®ÉäÒÛİ¨f:HtŸ4§I7<ÙæÓ^•‹iSU‘r">‚òí(g(ÑÔyG¼X<+-äƒÔˆ˜OSsúL¥~dÕ­¸~ß0¿K¢÷yOæNŠ´n–äöÍ÷¶kµÔkÉzÏ-RjR	xü_¬äZcòùõPˆ€Š©‘e‹¢Ş\ZU£Ö¡DkWtÃ,„£Üç¡ ¸vá%áª"ÀÙŒ=ì%Êª,¼n¡äSºÓÂ‘¦ş:İ·@ÕÊ¥¤"¡eHô,<«ìFV®™'Ç¯?Cöo
)µQ@#HımqK³}×oº&TÁ¨äU?©ãC'R£ìåG±:ğ¨<Ö¡‰¾û+øÉ¶¶Œy ã¥Ò™lõÿÌ×ËyøçQ.ÅĞMÊ4ĞTûâ‹bµÑoMÃŠ‚E‚-.ş…AôıH*"Õûh_ñUZ©º5J6u¿ñ¶:	'3o+ş>’qæÛ=ö•Åwİßtúj”JÌL›ïÔF<†”êXê*Øœ—=cÎÆfiL‰	ëœ_sYçvÑ‰ä=mX£„K@¢UÇ¡è¾ÏReeIŒB³¥Qü&¸ÙE0è8{šÉÃr0|"‡f¦©¾E|=È‘à3O“¿7M9®åç½±¦±YxªoŸİ™²tùmãF­i5!#„ç{¿A‘aë
ÀùSAi>*a €©í
)¿*ÕŞ¡üûçşƒmÒ¹}„Mv‹ªz7ªœåÀÃ0}ù"Íx°;¹~.5ÛèEÅ…wø³ï9|¨Š'â¡:¯³ã´màÁÅBüÌO9t1/Öù-M6¯ç§îZPF¥Å<d)¹ T¸©@Z_a‚UÌöåŠ;^6×ëƒ	ÁóOq)v2öù…Ã`Í·WşZ„"hŸÃ±¿ëÀ]^Üø]p:Î|&ùkç{·7=®Ğí$a<q±·¼X;J9j…ı&‹l»üëX›¢‡ %Å@k§ÒöAP”Æñ?R#ûùèÙÙdtš^gĞ-Ş`æ ƒê¸îˆ~§UõŒâ©øøšß2í2RX:v‚/Ê©qiY‡EJÎÌûy»'‹ÜTz™k]ûƒAÑ;û¤ÁväÖŞtº—üSêì	œO;cÂ`äùuyÛ«@{|Ø3_>…º<7TÃ_ºyTpiá|wµßŒ³~ªbHI
¿Lº1.œ€ëÖ9tıç…Ü·Îw¼'«|ú‚¿o+®¬[Œ¶aAh¶5^À?–ØY†=[•É§Âœ8¬Iíw´ïĞÁD<ìœÛÈ/88§2È»Û	9ø³A×•Å	ù@ƒq\ıJ|µÆÃ7y¬A0ë|p#|À`Ãœ±Í%ôqè ÊRRÿãìi>„VŠ°EÃf¶§ÕÄšÊ»´RÇ»p¸§Ğ™ıÇÛñDªPÂlrì„´êĞÏµ•æAÂ4÷å!yéæ—QÓƒÎ!f”d""öıªaæÒÖ…şkk¢0#yEëíøv¡>¥×Ió‚¥d<ûÀvxÚq
ÇxÃôÚóİŸñğ5`îbŒ\Aßï4>-ctÆı…¸3vOöÉÿ[„b¢ğªmc—…M:Ú¬|µÊò–×<{ı¥ëJ>Üô®M~İ3ÿzfşÜ(6üÕ
g‹TTB2 _…@SãâPPXtı&ñ«Òƒ.ñRaííOW!*¯â¼ıÒŸ6–^{²k‹SÚ¥%›£áßÜ(:>óôÒ¦»kÈ_Ş›İX¢YL˜Ÿ3“{u‰ü¹ÅíıÂÓBshT».ƒ0¾wI‚Ó:7[Œ§ÇG‘äF>>î6/jú‘«.;»yaÄœ€²VÓfH}å¬g-ß—™~l³pÒÖú‰VZæ^ÁX¤á15iâãï¬~Œ|×ŠÂ…¢™*€7Ğ;ÎéÀ‰ãŞQqÑÛq<±‹!ş5„s¾#¢
	fF
ûhõìúÓ'b¿EÊ¢{dëˆ²¥tt™Oûº¬){¿Ô#’ôë<ÆÙ#ÉPÏ(Pp””PM$Sè„ª‚yÛñÅP»¬àÇ²İÍ†2ÿ=ã”gÊS¿Á¤F„}†£õp­­éPÃ æb›îú[…8_ï¿¡`'î½Ã>=J\¯O.Xp÷>U»sX­ÁAMŞ2Öœr¬6°ßÜ°SUÍVš*¬ûFÜô=Õx­AV¨ÏÉÛ˜}€¢ëJñş/èE$µD½L/šËtñäPŒS¹¼ûSyá 0ş,ÊÂMÚi™ÔU{Şˆ†;F+º–)špİƒTQ¬×,‡-pÇ–fK=	Ç»DÍ9;@k]¨EZ”gŒLVŠ÷†˜ò`j“Ëtø¤¸z_á6Aùze¶(Ö"İ+2ã’Ë?Í2¯åŞ7Äø‘Ğtë	wë¸Ÿãªøö˜šeŒ‹OÒLòİ(‰e2bZ\¦aeOz‡Ojì>9äyƒõbó—Ñ¹ã/Ş5¿«Ó"Fö;‡¸>wš‡´Èí’Ñ=Š"ÒdÀ…‚º ;µúk¤9ga·8`Jše-Q_,±+ïë¥(F)
Ú¶Æ;f7§Ò²Â:ª‹ÑÊ3l¼:Äd²âbW?­‡cö½ ëm¶`€œ&fûâZ_¿›Ø)\+øW<Éı´nÔ9 á~Û®à÷ŒzBÛ*ıŒ©jØ	²»)£ÈvŒKâ„4Nø`€øÉÂg’kÇê	ÿ^­ñÌ®íÜßÈ6âL#rŞDñœ¿¢µ½N9vfy?Jœ#Ík0¼ñ˜hÙL¶Ğr3é÷ zŒ¾ r«§öaN±ÊSúŠLn%<ùJ²5H šåoÉÃ/ŸC¥š/c§‘X7u"6ü^{&+ŞƒzôÅ©LÑ´˜¢©\ÜHğ²I¹Ê‡†8ê°À!“‘È™‘–Ä 6Q[˜NRúGNÔF@:&$ä«@\ŒÜ ¾â*\¦¢c2²˜­“'å®)ğ¹Y4:9“­€õ7Óù\\ayî¸NÄğÿ‡ßÄÛ—¶n2éñ"í]ä­«k1‡)$“ÍÛ¼¥+=F*Šh¿âc¢åFáU¡®ŠÌ]ğ €:~si{læˆß‘¾—,!eÍóY¥¥MAĞ—Û}Å#?ÄQŞt•5´—ƒÙÁ
ÕóåˆüsÚ¹µçp‰ÍhA³æ’¾QzqIõîI Ó}$™f¢²R‚RÁ^ÀvÎL	4,ÑtC!üõîø¿µ­·|+D,ñRˆ=4·IÇZÓ4³yÛWg{:,Ñäí® î"€«<fÑ6ú0Ç~‹´¶®³«„4ÌšÏçVx€qyí……|S‘CŸƒP$ÜóÈ\BˆêPx,SXk-í”ÆSCF6©ñhÓ÷ø?´°šÛR&ÌDšòĞf±,“m%b™^Ó®â“.#l×#Æuÿ?§Ï¼<Èyìš yÿ@HOt–ååKß·QÿI:_ì>Æ…@Eº™}ÓZ¾‘«7ÄO5…Eş‰ıJŸS}÷úTÕIÁï{õR=ÿlKªßÃ
4Û+FØÒ¼A+ßKEÄĞîÀ Üã¹«v6ÌFumxÃ$x‚,jº½é•ç‚\ë–"&Dÿö$ÿÈ%‡K¸`#'ğS£l«é¶/–u¢ª×AÌÇaAfŸP9~ç)}M]ÒèÊ.8U¡(Â‰½b÷\æÏñÆ|÷œ@OÃæğ¿~O–¢áŸ«ø„<ä½ÚáYDño¶F8Â—lM¡ «˜˜*~iä3lRŞ¯ó,k'ª´¨šc0é²,¡:Œû	Á™şàAxHb%ÔÏk¯”º¡’dLóg~¯|ÌÚÀ¬Éîˆá–ÇZ}Ÿœ8BLÉÔ#—4~ÕyNlJà¶»v`¡¦„°ÌÛn,?VE>§¢,ŠÑL¤yfŸ" cÜ›]+úõSq‹ìºwÈ”ÆìŒ¹„äA1~©vPX: 9•Og"ËcQ\Raëü¢KXOØ-"PàÏ± "ÇÚÌ<îÉ)%¦0
–:ò ÖWzûÎó÷»ÂÂfs»*¦ÎƒÄ¼@ ¼Cíœ¿º»P¨c4íønvB#äfï—!·»ùçÒ‚Šç›òéTwó EÆ%û/ Ş4mEcÿ7X> Ù‘~ÄÃ£Ëòª­0%™pøuÅ>:ii¹œÊdšùÎËÁøÊ€/ğ]¿ÙdÀa‚Y÷DéÁyÉ™¦}Õë…f¨nfõ¡áMd¨„\O‹jRH«}F`ª‰ÍM‚XŸ<²¾=‰ª…ƒ8J^‚x\	gW–:?Ğ)T“ÏÜwèÍıÀSêèá•ßÛ<	s8H¤ön^¿â¸‘‘™,+Û¼§rß™Š¨h>ûaùşØÍÔ‰Xå²ÀşHb'·ÒSÌYş¼ÔŠ•¯8o{ òz8%½[»5ÑbÊ‘‘Gpbd8Y";Z;5i½7t×·³o¤VíÔŠJ}©±Åjí»@®RAi3ğÀ`W9M‚Ø¨ši½‡}ûÛ›ál³VçÃäÅ2M’¢®…¤]ÁÚ›S¿.\&ª-ËğkÖâQ»éÕ®"Ñêb+…Új¾¹®¡¶0*y‚†º`Q	]ÅÂwÙZ	@£/XG+=^
d_bÎRèŠúòß!»óˆC(ÌBìLuwÒ¿I}ÉÙå´îSFI×ØÂŠrãv"p•Sv;ÎÍSY¬®˜”ò'âÆ^HŸV'wÕX	ƒ¿W¶÷q`ê¾»‡â|ÁÌıaŞBTn4Ç@6óì\N¹}ÏbÇŠâ µ¹6÷«Ãä/%ggmº9}	MRœ 8¹PbJG4İ€-áÇ¿k:sWmôà¥ÈUƒî.›D©rñëÎÀpí†z­º“FOÃ×mÏN=Â {*NùÈ˜-†€ıh%=kªÏbÂ—E7£‹?‘~µê"`d'#Š“nf8Z F
ì'3¾o´Ÿ¯J øÔDèfÍBJ\lÚZètEél\@ã÷÷¢k"öG˜×\Õ£µnBêX‹¬à·2bãu@(Ü7ÚmF°àè‰Îæ€ffŸş„Lã:Ÿ"¨A‘ =Å¦£À”ñ©ñÊ”ÊEì[#`ièÌór¶ÓefÍ¡€—ÃK™0%öfâ¦'¬–ÎsmÉjBDˆÙ>IŒ"×rUŸí£zKĞ&«›Õ¯9™+DÚ¶ttp2¥
‰ú3"·üÂàà6·ùy&~úÿ@·ùuf (ÌzÒ9yãècËÎpÓÂ‡0WVwÒØä<#W_Š°ô©¼“Èn 9¬h+d(%ÿZÅ°ÅÕŠ§nÚıóå(ª=rÔ"¡##ÄGó9áLáÒj}Rò{èfâÇvëÖæLÿÊ­Ç\L˜r Ëâ‘ÍÙqİF©*‡ì{íÍHàÛ‚ÀQï¿²‘`Èa5Eè…4ÍâÛYæÀiXÁxX·’TÖ¶¦ì™›\}ç…ÆJARÜ†"Mê£Â04¶†ÿI¼ñ®1S6òLñfÄ÷»±•Rùœğ•–6©Û¾ËAgØ€=œ9gbm*½£–†åß1‰±î©ød ÁÒrjOéŒ<ZsZ|]qî6÷èXp·_“œ#ì„¸|“}c¸Oˆ;jë&.iÎ(€ƒpÂÌ‚ıb¢¶«d•0ƒK’Õ½ÛíÁÀ™è'O¢}µığ&‡(äæB)$£&ÛYNY<h²ª—Ö]Œf¨E¯2*»©Æ–Ÿ¼7œc›ä<
Ú$p…<t9öJòæï·¡Ë LâFÔ‹Cá5TT~‹uÄˆñuEë<húM•’ßCûk¶½Å»ò¿½ô	3Ëü–ƒôµó;{)&xEhµf•ùe}(ğ_nïI„ôIİµà$oER#ø™”P‚¸eë;ê¬×ÒôÑµ–ç‹ZBÓÊñ¾cFfëM>ş¨k€2rØqıà/ËÃ°Y9›'WÇ«˜¢§áù{¾³ö÷*«µâçYİNø”InkŒnàyÑ¾^ÉÒ¥Fq€ÓÙôUœÅ ûmíÊ(°[˜˜ÕÃóœ÷t©|V»—bœJ;îjæÑAâª7\Q‹Îø!Fdfå[É7sw|Î[˜¦ÆàµØ¶›BeY"Ö®W€¾‹qNgá& Ê†2'µŠ3d	ÄçÕ.»Ëíêxşº1ã½,¿¾tƒ6ºé¢ii“ğš9„æ$hÊ6=uòü8¿Ññê­`ô[.Bx=±Aü¿`ê.Hƒfá<D?H_* öfSÔù$%tºCñ­’3ºÕ…ëeŒğ[™ëâm{÷ËnnàĞ¿Ş9æÕW‹üv™’¯Gdk4ÇŞG—½H²rƒl4¾‚Şzg~67WœÈ!ôröƒğò¹Å|UXùB3$Ê_â™h+»ófë/Lç¨2œåÃc^~7Vt„Q‘>mšmAv‰%Şó‚´Oİ(ŠM
$œ«õõº—:×«©.Ñ ÃÆ^~ƒGL•†`˜ c¶]Tœlªâ…éó‘ı¢›°1P‘[-7ÆĞŠ®²ˆoecC^ô7ÿúªszwÓˆ.æˆÏåºQe;Ï™=ô„é&áqîkşËÂ×4ú-•–Sˆ¤¾8Î›·('›Cë†‘ë
bŒÖ¿¼J`ço4-=qªD>çIÅ‡œQñÒŠX¼å_¨£èõV’,á%FJ’Í§gÀå‰ãWVKrU€p‚öÛ°”V¹Gìì¬'Åº'út·ƒO¤!w¿Ä€'…<ÁË~ˆq1ç|Ä…ÜÃ$ïõñï jDpŸj/u¡èœ`í\ñ¡t"XFJt“Lã=Ñ!æñ;¿g_/Í±PíoÌÂv…dU¸’¶ÒÁ½à2
àÛci–k HÈø ?“–º7{öï[(ÀxRËÓ`lƒyœÌ5ÑFW~t—%¡ ‹~E0³¡“Y¼f¦iç£çÑ—¢î™¸h{¶.gŸÌ‡™å_í&58•Š‹Q¸•Â’gği5¦K©°ÚG!EŸ½«ªjOŠò¿dy*šXİzu0ëgCA¡S6±÷ßï“¹"ªqÂ z¯e—aåÖ\ÈÀÉgcKAËŠ(õ#RÈ´¼+/&Ë+%<ÛıQ2ç¥§Àöfe£Éæ"Hö›z/UÀNÅ| W£™V}/ÓRóp8¥ÏG«+c/2Ää‡ÌÌ¹j°<+àônGâtûÏL}ë‡•U'HKŞà3ëQö¨A×•×íß ÅŠJ[ş;ummºuQ>¡¤ioç1„“6ì£k”ƒËğQp^<¿"*Úá$5Ê!RÃšb»_WŸá’è`.íZi²´s<W$€sçK¬P£c-]d…©ŸBüœàfÃ"8QêÀSTs”…ÚÉ¥­
+[ajï·û`ê&¹bå#¾…K1’&»+x`ıXíbiş°nZÎpRğİ1i­ŞŠºï*çƒ,XBñåU<5ïĞ í(ï#–h$a?+ŠoñàY œáh:¼ŸlBa|úNÍÔ<r&(®ç‹¸§¹-U³Ì¶íÁ<ÃH	HØÿéuîß—µ@]/ÜZHiC‹õZŞ’¼û¬’b·@ ŒÌY5	t‰³}Ç.Ğ†µËùk’‚©Ş™}ºg¥¶kƒ…ûˆVÌ.+×€Ïíÿj|ı—c‡/{T“"Ü“&êÆ`^¶+,Š _füü
¼†Gú/«ÀÁ^ëÄƒÔq,`à”‘Xw\náõ°h¿®Ff˜ñH¨zbo
„#€.4€Á×îòë8´Øa*ÁryWÂá_aÙ]E™Õ¹ÉôÏi+‡fp)xÊH	ÁÄ’,ÀìÓˆÎ›r›ù¨ÌÙ÷"iÔ9À»w)ÈÒ-[Ã<Nß‚ÓÎ…2²™ÊÇÜqißçn`ïÒj°BåG¦jºŠC÷‘ÙİÊçÚ Ù²¯z³ŸÇw­î~ßÌ!b'o‰^R¢O•¡ó–«As-gÛ²Lï@{#×²ágy4Tm.=y,XQ‹Š†œú8{ 5Vƒ§ïÛÑúë·ùø ÂNµÊ€Hªy)a‡û9_$ô¼¦Ùt 9jÄd#®e—øBG[t•ñƒ­xu.S©¥=x®ªÿ²#ë‡®‡<£¤<4D&ò<¡•Ö5¢äZxÛ®¦Ò¬‘»„xŸÄ› xş l•¾šÁiƒ4¨+~jÑM=æKŞ	¿4P¬Ø~}ÜàŸ.è§A¹Õ<1¼jH¯ =îŞP’’EéÜŠ¼’l;›­ùrĞÌ=pâ­Î±0]øÊJ‡X¶È¸¦¢Õÿ±ÿ`õqÿQeÉi²‰˜éf¡¸p³Êÿx¾öüá¼C˜5¨foÁ$•¼BS¾ŸMÆ½o	’6ñË£©B%Ğ•æ¾”]ÚüI—‡Î˜*Ä»3¦?1­Eæ|Ÿ•›¤åaø-{§cçmZÿxwfé´Ğ}Æùíæ£8BÉfgo}	ñ¤	4_,‹ÿûã;}K]Ló·O Ä‰+M¸ƒ2”wÛ³±Ãúœœ^qØWDFÛº7;YÉZoAlÿ:m!?Ü2KKñI€$bmL/îìé›İ<A<"ä".»}ª%–™s~v'KŞÉ’uò©[V£GXÎÃèa…[ÿ^4¦gf«ùĞ«ù¨;ßÒwt!Ş}ˆkKZQ“jW£¤ú1 «ĞØ†ı¦ àOX¦§ÿTJÓ˜bfI‹¸­‰3İWlã¢!ûeŞ3”A¿<º5=(ˆlÓÏ··"åi‚xÿ@`1È).	 òÂÌ>¬/)ºËåƒ'”Ì}°Õôbuß7¨Ç£¼Ïç*1–ºI›$gF`U¢=¯"V0ª'*?ÓËóZù­_Ì;BåXÉ[Ÿ/aî\ß¬@Ó^â~{ïàä^ÉçÏ¶CˆAdÜ(ou8B±ôƒ–Â*¿¶/|0ıFŒm¸Øïü“-'÷Ş¿ù”"}Ny÷JO”«ËÓáÃË:r½9xıË™		Úx=ÀZØR]m:ÖyÈ˜A(b,s-#4hwÍŒŸ²g’öô‚¸äèUoGgú<°·F_a@ß`	™:nœ¥bĞ./Úä–›r•­e_>ÈNàÅ°|Fßoáâ©£m´‘g§l€ğ¹*|$˜®«BPÄ¥7TÂóÕÔ¹B®Ì]J¯Ï©–ÃÂ¯K# ä!£6)É¦ÓÿTõöÄ6<´8kAòk3y-çÃ<›Tz×ïÃÖz<šÓ¯˜Æ5‘3§Äü8IÖQíŠ= óAêå›¹’²?éPš¼]L™+a,
¾òÔŞ¿Ä›ü5x7^=‚g±§ë`«·GœÛ•ƒ,Í¦†á´d“ùûÃqKdî•‡óAP*‹„ŒØky™óoÇ$AÑÌ¥^À¨”k> `é3&­îš÷gÎ@Œ›EqÜ0¨™	Š}MêRx‚`^Vú	­ƒìÀ<œdãTF=éoTµ÷3‹úw.3Aiş¬
Ce7
ÌûN|qG0F£$éÇW^

wVŸâ%ÎY†ú!CÚç¼î–ó»¢/XMP2­«9=4@í]x:ÒXT€n«ÏxUŸç±Üv4Á~êİznCXGòöF+!fÌŸGĞ.?ş7=ëƒÄPÚÊú£~ï3óUDømšçXŞ¹ÜÓ©ZéV“´W3ÊÎï	?_eÅƒğº"ÀC½’µğ=™ˆu,¦aè´Å(”}¼h a¤m•¿¤ZZšæ6á‚#U£œKÁ9YU),Ê—›Ë<è½{(ÚEÂ½ŠO¾{-Ì¬êoúáé^ ™w¶Í…	ñ§] óF×p<×S\ñdN¾îîzã&‚æÉq'gõ½A­ÚKÖøõ—İ±òo’ĞcØØ£­7m„‚bvÌS†±GÇX+ ªĞËòæ(ÙWŠÔî?îü¬·!ı©LÖ®<: Ão$ÖŸõÑ‚Úµ¬úÀÅƒb$§úéé|VT‘¯åR}$S ˆ>s0ŞâiX´¡v¸îô–…â™l…œÄS×«>œóDæÒ÷$¹µ ‚®ŸãŠ¶ğŒÇQ…Üš}$·¡i¹º¡Ÿ³)ê©ÄNâCº8h›·Ñ¹’=pTøQg(°Õ‚6b‘…ã^éİºY–O¨F«6–N)²ıˆ£Anª‚¦‰‹3ã³‚çˆ±Ö¼‹ê3ÍÈ÷¯YŞÄoŞÖ"HFÓ/r8¯âÛÎh!F'ÉJPw¿™Ö;®zÍCğ¥ëˆ†Ì:½Á‰É gCi<:¤‚iiş„¬$wÎÒ.©%É‚‰û„¸t».÷¤ğU.ÉÊË¤ç?‹ Š@}yR™|øvzé!İ¬¥TŒî/é
~ô†Ø`;o’‡DßWºpIiq!§Ç1´xÜ Æ :à“´d h“úÁÇè²gRòÏ,]%±ş·GTíÑáªQ¬+É¼\zaaº^QÅÊKcŒ×·Ä…gÛúŸ2uãílD†J&;Î÷˜(ï¡  m¼¥{m?Ò‹Ûãÿé>ô8:p+Öx›û8WzªbFI)0SöI›¶XÇ,š>.‘ÇÂnœF²ÿO&ú¬qŸ‘.§ W÷]0*u^UI{gxÇ±´òú™ËjÚÒ}vo¦c‡¼Ğí½’š”…¢õÔ$Ğ´"`ØNzıa´½o„)¶9Æ_€‰¬	7él·ÏedZºÒî<êŒò eó‚¼áö¹òˆœ@µBÍ™£55z‘Ÿ¸JÙ‹Åôßğ»¨ñıĞ£¼Ìºñrüôƒ.ó.¼÷Îı€ç‡Í”MVV8P³	 ›„A¤);‹g?…ãŒğsbéˆ~Ú  şÜ¶ä$Ôº ¿¡€ b¦c{±Ägû    YZ