#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3049676573"
MD5="dbe69b8e64fe171441d9108965c5a85f"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="19848"
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
	echo Compression: xz
	echo Date of packaging: Mon Dec  2 22:30:50 -03 2019
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
ı7zXZ  æÖ´F !   ÏXÌáÿMF] ¼}•ÀJFœÄÿ.»á_jgqÂıiù:¨æø*). ]l/ıM°Ø	 ŸAcr¼´n>\ª€UE¬æ7 ÅíÒ™-‡H€¥_ÂûyÜ~3]„Ê›G€õ2dù§9Bå¿§3É°%Ï5ªûX¨8TÂşÜÿgg¨üXäÛªù‹àTÄ<YçÓîØÚ&[ª{#f/Ô€Ô&Ê£®ˆ¹¬aı#ïËì¡ì‡¼¡ñ{¶µıŸXëšÉTwqpB©$Ñßü«ÕWĞv.'4êò¯IvĞµ*ëJAˆ•Í{_Ö(x€iÍïÁùÏœïl71xH<6ˆƒ¬<Ì8¡Ó8àôFSd
®2„T²,>bg9éVCœ:'%Ö‹üD£Û^íëP»ísKk€óbı·NºPãöÃ´9ÁüR²zP‚´g^ˆze;¥Šup7“A¢?3ğ ÅµŠjŠÏaáğLÎƒôÃÊåYK	G!Äñw3E4^ÄU¸ë¯ä)Ì3¤ÏVucÕŒ
e¤ÜÒ*&?ä4Òøváá
SèØ%.dp¿¢WP­T² Gr…>Ê<9ûR‘&t„>ºo{°BÏÇC±!¾®ZÔñ3p_
š„Ú¾Àÿ‘˜ÕÓ^ô#Ïàü’­-[ze}Fd=; M§Ğ¾;Õúµ:·û‘¸Ç$ÓÑ„g"¨#7%…ÀáÅX†WxO¤_Š	›\ç^5J7;ZºşĞ¬õsÔƒYx¿NWDĞ®{}h©óÄ—®»::"ÙÍêópÃó'c_>ÚP¸Oûšƒà Òãš­õ~ØÆ§ÅÅLE¾ëkÃÔ§@¡²»U9yjUÑ _B_@´êua%_Á1üğÈFk?‡fW„úÙ]à?-º-ï5#¬šlÓY­LuÎÌ¬'öjDç¾(ê#ÿCç%xËHK&1g’'¾Äæ®Å¼ê±J›²KçâÌ'ƒœCÄüauÿKc¹{NR[Ñ„lì0j3MfkôÉo…[Æm~}h=üÅöİ+õÖ¼&ùiÛşÔ¹‚÷’ƒÎö~¼Ş±„x-„(êµŠ¢¯ƒá^ş‰•$ ¤Ô4›æÉVòÔl±á‰ø³Aı0şlV)UÜ”=V›¥prFÌËŸTl¶®•„ª ¨îğK]„¡çplZ—LÚ~\ÜTö$…ûmM~MM$57†¶[¤yWÃTºwøŞ|®òŞ1”r+…`ö8™İõår¿ß·E°Ì?¬âËÿÚw¤'z6¢v³{P0aqÈÏ¿ºiÆ!¯ÍspQ‰Ñ
9Ä½S¬åÔ~tnøÒmw“{Ô*s.·lIˆÔ §¬Ò¬Îwõ ¥ö°4ÔÒ‘Tô	ÛBš õÈó}ªBëNwg”Ûñ/'²_Vr×:@]}ª€Ïïxp¾t¥fDheãCLGíbyhˆ4u²ƒ=~ıÏòE°%C5G½¶­7ôÕ¶";2˜¹ÉØ°ƒúÄ±üuZˆo›\ˆp}·èºàQ
=ÖhFÛwáÈxÍ¢¾«Î|IøÏá¶aê×~òV’u8şŒ).»nc›2ÇbùØÖT6B‚@»ğ¡úrŞ×©˜g­€Ş¦,Ğ¤5ç.nsÖ˜
¾¾›%ÕÈ—¹Ü¹ÕpÎ>‚ç¦í<UHÖKÌM™Øy÷â¨õĞ	»QqøÀ…6%W{Hÿ •„ôO8¯ı«XßJLc€å+ÍSX'Ehì˜ø‚mšìšT€},k¤möú—Ò0.¬”SšHÔmÚÒÃ3‚ªcüÃñzxŸ¶‚–ûó¬·î&3Şj¶ñîSÍµy)Ì>ƒS½K…Ğ×/Ø¥fôS^HX¹N÷®íLd‡¢H”rÚái¥	ŞIõ\ÉF±áO±P±j¨\´¯˜^àLi82PÁ_öÁ-Èâ}t¯_2\•ªuzØ‰ô‚QÈX€óÃ\4Ô\‹Şéõó±]ñ’6ù?ğ)?¾|«êerºÚeBØTøşìÛHú£™‘¦kÇ§t~¸æßüX
  ûô,BîĞ:ëtò¤ˆ 2•ß6ØY+¾‘üëP
i]cnõ9Ü{û9`ÏµmäÆeõ§{Ôğ&1MÊjì4¨¤Í‰FİèğÉrğ[Áù!Tˆ¹R¦ò4ĞÌAıYø€šCˆ™‰—~$\Ñwv §	p"B‹«7³µg‚…±Í,L-×;·»Ë³~Ïó×™=š~ë"·óÊ¹È’K;OÆı	,²—ï¼×æˆv-°ö²‚5’ïÜISı§“»ÑóUlwd		|È¶½D êø*Nª%óHµÒã43£9GQlÒËœgş¹Ÿ5Aé&gfîî¹€êÌc;¦m7xbÓ†îgéŞ§
’cqåçcnÕŒÍöéÙ¢<„Ü/Ceæp6v4ungN´5C·8olĞÅy˜?êImü~xå¥B+¶éèg„”ÆÚñHtáÄkÚ@[^ššÈY¨>{ª”bÖšÓÌn¶–	@ıZÌHÓë‡J–Éyc¢ş µ“ßw:2/ÀÈQyAÂ4d:Ø3™ì†¾OşX5¿èÿö`qT fßN’ûÌûB»e ƒGÓ–IENò•çb€¬ÕPBÙÖÌ’$ÖXy”}ŞºÆîìÃJv'x¬Ó8Z­'J¢7+w÷qGjñrÑ‘Ûm¡	eX2ƒ½2ú±¦:¹ß&8~¬=ÇßN„ õ¶#Ôw<˜,qa(Ú¢Gx.ÓÑ3ö%à
mH?ÇÊMaE\›z]µ¼4X€ŒÙóu‰°S,µ®^[ƒ¼IšDÌ¶Òr4ÈqƒXJè@¸‰İ—'¤)ßËvu÷¯K{®Üß\ıø¼Ç™âºªgEë×‹Ì<Ù¡’§i &9K³stÁ;Æë­wîª³wÇ@aˆq³'-†(—²ñ›„¹[½ƒ‚tÎI<ê	K°r¹CÅˆSFÓ<2~äÏMmòHåÿÇ~EÎ=Û]±ş6ÑŸ¬0Q'uSø9äj³ämsÆ÷>6ßÖÇEq7:lY8	•è?+‹.bKsx‡ë±í"†™º^—}lid™É¬LïgïOÎ†K¬ê¬¸7‡³÷ïì2>ìÁø%BXåáG<«.”jÛGÔNÔUûzÜ˜&ˆ­MIüj›¶"$€µ?ö¹sºÊSä	ã÷Òş>™QH‘íò]Ééq•k«¬ñ§.+w€½è:œß:séÚ<¯À³2î~¡„ ¬9¸—[ÒÄ÷#~‡ÌRàŞqvEiŒÙ»×šÁ`mT˜=`fW€2´QûdÛ­ÄÕ@wÙÌƒ¶üJ«BÕ‹Î½˜wˆ9Ò ñ\y}£{QTfÍ+wQ®¨
ûó÷éÙ Qğ×‹H’%«!ùÉ¯eQ8^}Nq4×.Ü!N¯Mõ`q?ìˆ¸¢ñP‡MIeC6^[&èŸ˜>@0y¥Sëb™®‰´ÿp!­'SlkJ`{;T§--’7¾F¿0@Äº±P¥<§€ù>ìk¼À,~òõ¿İôPû ªÇb¢•[`µŞ Â¤*‘mÏ
†ıÂd>1q\Sâf0j’\±Ÿ@	WDëÂ7Ñ† @;ÿˆùÿÈyÙò4ãµÊTÀ3SAN9JH=yHÛE	ÎÀ¥®ùF1]œR²Û™`¤ÑÜåyÊ$Æ+ñ¶úf“xWM÷‚$±•eéVÀ’……».¹lõdÕëF×›Ãpï.GhÎˆ·wÛ)IûQâ&½Ñ®mL%†zä;s/"4ó—€ÌÛÑBÌú“HË› ~Q\“óÅß7I,·¤&ZbiÀğ-T‰ ÎüÄ¸ãeXA†şHæÔ£¬;»Ø[÷p‡0ÇdAçÂeQå€Èü=+sQ%œÛ!é¶w2;8‰+·FİºØ$B¨Æ3H™_û‹éÆÒù1yBºy®‚ßO}N?…Œı361J9¸ØMfEc{Àª‘~±‘_Êd¡¿s½2«{H¾;ˆ$Æ^|ôØŸFCXš‹ôFÍZO¤èğtvÚLL‘R×-dÏ ’Îî^åvÊÆµåÆß`¿£ĞŒ€)wf2 T‚âaÑiÂ
'™—;]ìÁ1X“hhòïùµxHÈHª©‘ß´EªÄ7C‘<·HO–AÌ¤D­èŸ‚Ä²÷tÜ; !“Hq(şæës'X+Ç(°ı€ŠKÃÂ4‚‰œìÑñ~cr‰Cm¨T.°N+ÄŸò-hçÎN/ÎÓæxWP‚“ˆà-œ{„%ygÊ)×¶DÇWCÅ¿Àk*;ŸtK*ç:Ğÿ@ËR+5wik½.£º	|°À#w¶ğ5HÙ1 g£‚ÓzÇß¿Ôİ‚(•¹2Fë´ƒ„Ù:ÛËã3
0…Ø:ä5?zÄ³u–õbÿÖ?[ò˜ŞµÛÜ!œN¶“W„ª®še,!³¼,…z6Ş\7Zúeë~92ÌåYQØ†ù•İ,z:·<irM’v)Õ|×A¶à&ùò¾õ¹ëh•£`ö_z5†C¸2Â¾Õp™ò628£Ä–ÖŒ‰*ß;"O °:2šFUn˜·Ë‘û¦(V×›n3ŞÌ?Pù§/Ík¬^7fu qÒh±kq®—ÀŒª¤eÁo±ÙÂ¢†*8¿¥Syt2–ÓR¿Z’¹ôTè*jôBj^µÈ42ÀNä²ÆºBçˆ‰Æ(A_¾…äk¶û#)İÏ¢™«·Ì¢@5¦=aèµœVK4ı€µ3MD`æµF°³~ıÁ×8Ûjİ5â?ÿ““µ4ê•ÛeÈåÇ†ûç¦HYSOM$`{+$.±ƒåã”ø{Ó‚Ò’²õoÇBÂ3÷ÏEßÅˆDOÏE™oÅºß
5WÀ<rªÊ“[oø×Ñi´M“EœvRöåş{@e&b™bNÔÁ4ö@©¢|£Ïp›¸0.Á*6”^Í¨VÏB7…B¡¶ß/à0P™nvî—«õùÂTÿ÷ì/yá]w»Õ2ò?õbªºP«¼‚f•æ×lî±N
“Â>ÿİ%©qÇÆ^—©£¡ÎhZb7 Iëk™ş66› ”XªÁZÚŒYµÂ˜º‡îû¸R×±ğHo|&pjr³Wš>
~õyW îõ9Ş‡#œîpß¢£3
°Õ•ÈLpë±½¶ùDŠæë³Má”pp@Sá>éÀ„Hé†=áÊÖïãHqnôµ0ıkàT¹»†VôøŸFÈ«€_Èä8ö»Ì§’#bõı<å•íÛ¥İãÓ'43?¡›Yb)²å'm#¢¶¾*~TyÄ6T\>üÈy0»íçÕÌ,>ó^=|¹ËFXnÁtgÛ)şÈ>KtÀ3Bâ«}õñ1R·%ÚÈ¬
Yó	|­ ñd¹~×Y&mcâÎ_×,&²ÌŒİ¬j©“ÉšgAïÅ¼Ùæ…2?ÖµK„ ‹\Sª@ùX‘Ş8e½¿Å ½¨Ÿ²>ÏH‘à‚w§{ù‘š/QUs	Dáµ2l"1Ã_Îˆ^$aù>™‚\Ë>Ì6ıĞ{°x¡¼oÜO¢"×.‹ı ğès¾«ïaÏ*W†ÀÙd–ŠÜ»iÒü_CHØ'q÷[<E@QÁàHu†	ºôó6ØAS³„ä5ø ¤.y±İï©	ù4.`*Ô{¯]é_%ÃyLNâ+NóáFåğbbÓgïmxgüË]è	¸³G{_"6ë5›cª–oı"âÌRñÀ²{%¡4YãÂ;¨ù:z=¸T¤b1D¦á)»yÚ@İ¦‘VšCğ°iTe2Ş¨ÔqF .’ö-mÆ¥¦Ë+Ã¿ÅS¾ª¦öª˜°P!Ç>àÕñ«°$Šıùl|½¿B¦aÊòI¤-`,ğİ¥2áƒë–Ã¬µ¢bHyÿë$½^«ß¾sK úÑ[äPopÇ)uêF\ûæTd^7°™©ùz®ëGTîÂ1"„‘í¸ş)ª·ÏÖ¹sŞÂyºkÎÕ&­
î³ˆr<Ä¨é |“çNúJ­{…Ôe½2fŞb£m#Ø
W¥¹˜W:ıHÉ†FÜ‚4Y Èy_‹Ù~R²'-·¸¥™<ÁÓİ‰$fµzNÇÉ?»÷QéLJ[%‰h `®öìºÔJ1äÑK.«¯\)˜p…¡æi9X{hQ~ãfµŞ˜ˆ+²‹à¥k• ¯y(Á2aæüùÊ·Ó‡Â†~o{ÉÑ¤•É[<Á-©Ú³¥ÕÙ6nbX²•ÄÌôw˜¨}·_Éo7¡…MÇJ’ÿ(çAÑÕª¢ëÒŸ²Ö`Ö¨¬)ªã …·õW™c”Ç>°©'½6ÀÑØ6dmÃğš•«å³ı3{r°aòIkˆX&µ;<6OãÉh¦vù‹Òµú*ÑÜ©,€¬…NÊÖ
õ(¸%ºñ5‹7¾&ü9œ~ç¯Ÿq«eŞ½NÍF§YùÚÎJµ‰sø’úÂĞbı#—YC"~¿áL(I¢™éètÿÔk0r?äÒv…†ç¥c^E)C>ÓÚÓíş¢#‹¨J«œ)½®å”'XÁ·w›Š]¯)ÎeA¹JÆ}K£/áò)~ùİÕR` ¿Ì³éwKCİÎçÔQ R3ë$²Â¸’ÂjYX²:VÒŞ
@|µ ª´&ñaUjpÃµ1sôŒa»v¸Ï€Âš^](·º›(Zn 	<‚¸/Ú°–F&±©>ò™Šş{–ATáŒdŠc—óŒ á}õ{\N’óˆ½ÊV…°Ä¥%¦D»ûÍ¿ğ÷0H¹0nøJö«ñf$üˆdéğgúGŸf¾)Îêï=púÀÖÁ«™ÂWùÕìÛÈ«È_ïGşÿİÍƒ¡.Ë¥_CmÕ¾½P…céK§ÂºJÕ½¹,ŠsÁgÿ¹íŞQ·½\q˜vçB×30—©\rO6ñ·ßaOF¹—HïÁwæŠoZˆÆruŸ#Şhu°´èòÊ¥´U)‘íÊ{$áQË˜é•´-yç÷ã
ÖÎû&â¡ªRº"Œ9I€ğĞa·‡î2¡=
ıÆœ”wìÔ£E1]ËEÏè2DªB\0õÙ_ó§akJ!¥)è”´:œ×·Ğ°-ªf©í^1·Ù9ÍÁ>Û,2RÉÛì¥³Ê1î‡ÊúàÅ`¯mÄÏ†š|”¹ã~L©X›xäVµºõ$Û'zå25’ÔêäïÑŒôu“ôÏí:Âpã„=‰ó…e_!‡ğ¸!ÖÃ<)Ä &ş¾bß{jî/<òñÛc_‚'€4¢Êåv …á6‚õ¬j×+1ìœ¦ˆoºŞ²M—j°ºÏ  @Pøoùººa~ëÑ…»P®!Îk¨ë˜‘ğC_ëdˆ•Ê<J¤Èê'ét“Ö·¯Q}òV¯¿uÅ(—lpTıÿ Ú­¯z)õß»¨‹{ i†®¸\8v&“ßBêoB$/Ã–…ÌI¥/COÏšöHrä¾L/.F™Lö¬`PeÍ¾`l;øqCrNá*,9¯ /‰ğ“Dr×K"ÛFÇt†Ÿ1QÔ¼·E'ôY:vjJ¾9H˜ÃÀ+!Ô_øÁ+Xr,6²Š:ûô¤ÒTeZ\'§·+'Ê„š ã(2iÇhıTBk¾äÑu¼ŞÖ:(Oü—¦§»h†ÂP¿¾e€S=²1{›ƒRx³¨…w½Ê$Wfi¥Ltu¶+[Ãäï÷½´ˆŒïRë£„×š?¦‚©ÿb>û«ıÉÁ¾…ÓÀ6Œq”§C™ÌrÀ¼­Ğe‰I&LçQ^¿¬ˆ¸ûmÜ¸Pø$4{u =(ú6…­
§xú 0Ã,•õ!Ñ)şâ.U©·kˆ.µVô.©>Ç¤•ì#ƒaxv„·œk3+xdsú­”&=@²A_9àç»ñD˜+‹/S-ª%µ†4áø±ÏÎ¿v-éMñ²÷…saè^‡C—ç«¾°¦Cá¹íC…'RËÓœ—^}ß$8A59ãÕ§ä14¹¬Ğo¿“€OÑ¢€+8W²6ëD¹'„ÆcvTwŸ‚s¢eê².Õˆåô·¢¼¦øƒ¨óx€Ví"îqĞ’WãF“GlÎü+¦i$!´ßQÕœ7ÒäM‚½n¶§A„Ş©éU_±r­€g3Àu¢•ò¬²¿uEÔ›İ¹±t£©)yöĞµ7ô×ÿX \Y Êe¨3!oüY3O.#{|sD4‰©á—‰±Ó>klW˜±G¹)]í-Qbdî
$8¬Ê9W³'ò:Ú#}çr¹Æ5õG†ıGğéaÈmØQ‚é|ÇòW±y{9FA/À‡…ÌUE¬W÷W±-Ã3Â›&ÕÙº¢Tor†ÀéS­î­k‰Ë‹Öµ…·-¤Ó¢|‰w.;_¦M5’®@çXşDi5eÃ ”ó‰»&ë\ÈóGàCFãôb[‚ÖnÃğD­EšO¦DŒÍtÌcT†Dç?µmÚ(ğÎVÙìq‘/.J6³ˆ?¢óR- Úkœ¶kb˜Ws¨s !ÅÛ—ŒÆNeHBşp’F¯›Ùì*SÂøğ'Û’~<İ?b<ÚY)¼5;ãZ” ğ|üWV¿ÖÍØ¯Kæ½æÂ‚·7µÛÇ¡czAš¦S··©OÖTP{lJntWİÙd¼‚ÂP}²Òüm¡ÀÒ1—ooOÇn·ë˜óùBşQ
<ãæş9r#¡±òe´nj\•6ƒ×„3fÎ“8õ­QÕ'ápò"»Œ†wı™¯èösÂ2;§*ºØ>Ï ÿlğyùkHü•¼—Ø±æ&o$Ü+åEñ¸¹i°úbL5lªÓÍ„ÊÁ˜øy¦uCÇÙm¸’¢\vcTQà~e¤Ú®Ù´1Då]JğŒŞ7­41DÇhÑQ«‚ »DUsº,8ü44îdu|‡}«Š;à&Ÿeq@(Zñ«!±‘$¤~:AÄÛŸœö}óÊÕt5´+d¤Ö¢¬xÑ_ô0wı	:7Âş¼p‡xJ¼€7áúX`§‚G1ÇsR[äUOqöÊŸ>òî¯©¥íyé"8*Ò¼œô;ÙC±EéE<„›E¾ñórpzC—¸E.§ö:÷ŠÂï„Â¢ 4€£¬¹ßB4ëa¸GîÒDX½ü :>6şcÚˆËåE*“6î†ìšiÃÚ¨|a,®çliÂÒaœƒEÓLßi-9®kS”‡ŞëØî†Ë¨[ÿÛ¡8ÏêhğL2R¶ä0xøsæ¤lı§ÁLÒÌDÃ3lÄŒ×Ã~¶¼µË0³{¶ø—í/äò}`³¯Aep$ZB·BuéFYU/ØÀ®ÚTÚºşŞò
×Ó­5 xm'¤ìÔ·™°F«Îq›C#wJ@ƒ
gÀ“æãZû¼Òf"¬C;(½ÜâIŸñ¬òÕ0„ô¨÷E«S,¯í »ãÊ%Ütr_ ¼I4sƒ¿X¿g „A&#Ÿ¥l– Úi(­§XüşrAeË16&Ê?!:\%y¿IÈ/Û<ö—Éò©îÎ_Ğù;:^ó8üŒs¼3†ä*Ä“ÂÜl³·r–(-ÒWš•ËJ‘`zlb3ïú’Â¸ÊUz™[7mgÕíMÚî‹Ÿmmğ¼.ı‘ápNH «	í{å*ƒ¨K~d·W7şUzÉB²ìšŠöòAôDz`)æò]2´é£© *ÙÉøfs1bığ-'•5
æew/˜ ~|˜O³Ä†ŞØfó9NĞ¤ÆuMi’ƒºÍbŸhIÅÔ!S„¿@¢Ù–¤íÜ¤j(ûÆ% 9Q…±ún°‘1/´Í«Í²?ÑUÉT–ÙNo“±8ráâ¤ŸÙüs$‰gÃşüR	Sº{”\ÿĞtğ†OÙ.à(=EjÛì1B€ƒê¥Ãç¯ÀÁË[`S%*· éFÔŞ†øÕ=NŒğW=„äÈÒ9WÖNk•¿~>&Ó¨;"0Bw¸^¹¬¦ÜçÏ'¬_áÿoŞnâõüïmFí9’å8ş„d…ö}ş–!íay|d$\†¾¡ìÑÙ‘æ0H©×my*„~QdlÀyœóÎâBßC¸çÂ¬pÆXöZ|¸D€ƒ¹ÀÍ
M×‚M›Ğ>}>î²~âYÒh’…äŸo´ÕRWûÉ²Ô`Ç³Ñt{]Ï™1„w*Í•$T™–hpØÆÑ5…Ãyˆó(÷„H+zugg{›yºs×b[¸íLQÿod2D¸Ù=Æ|5¦\°5:‰Ì¬…¿¯İµ4%·ø	1€¾ÌÈÇw¥<y«á‘ßa÷|S’¨Åjh¯E{®¡ø½ç­ø*/ª\_üÑjhmã5|Äöòˆfez±Û—2²É•5ª?Ì….{Z{³²ƒšé£|;‰€`ú—ÿìÒ@Y'PÂ¤T>Ó\0Uò)‹¸r>ôX\ c8N©†=p³^÷’…Ñ‚LÀÏp§øO)j,7Ê'fæùe=¹éŞà!†Ùz\»?:Ìƒ³‹ÅÅ1"yO‚PïN:üÜ‚$Lh¾CÑ²işrŒ²ø#2¾‘k¬Gb‘¤ßYÂ;;¤¹LÙåÓ_¶ŸcFÀ»=æÀ ÍDÚÓˆ²ßôĞ©nã>É×ù¬™6¬ÚÉ^Ò–8p-É|÷(<Ôe¼–ø¿ô §y3h´Cu"ùiú¸Tñ]`tAÀúb÷—WÅ6hº6ŞßiÕo®ØrÔê:…^ıİÚQg1Sõ± ŞÑgş1Ş}´” nº?TqØqCa9],~Rõ•Û+æÓ`r.Ş³£Yäì–n£):ë+Aî#O6²]§»s¾WGÇ|cØ! üÁ¨sÓàU·ÃZd;³yŒO†`…b~°Áø}iEz3äm
Lä¶9òËó	
¨÷~•Û¡×Ç˜Ÿ³1š‘Hw­'ı%•kR"i´n#i5·X±3á÷%‡—ÆË)/m:<Ü^³Èöá¨æe¼›dÛWØWÉ[“µeuå¤­Åşv&CvY­øG+z9/;~hq0ğŞIíjÌt¡yÆJ4*~2$ëİ(ŠùV#L<±4Gr–¯
ìû]ˆUhù¬°Æ'áŠğ1’Šqë±ëÒéZÎÑ;Ø†Ü!eîàvJàÜKcH¿€”ı¬ŸìAMvÊwnLİâ	÷!ÌCä¹«ÙèÃ”uqõ _Q™§KÖ¥(åÄë‡‘<pMè}ÍÃû”ú3ÚO%ˆÃÁbÇcİÍb6ôÄ
…5=ïZŠÒsk¢º Æ¤W…¬-ßMšÄ°şr¡U«ŞkB¥ã|¨öíÏ7c„¤˜ÊPBhKC¦#¿ êÃòÇ˜%ì€á‚èwóñA;¡¢~ß²/#äL®ÌG3ÌàëšDTC0ı|«ğrıç/
Ìñ
ø’™jzW3C®)=Ò6öñ%U‡ı>:«®I\uÒkÁëÔ¯\üG¡Ğ–à˜ØAa<ší^R‰UGã& [¶ûŒ<„8‹lè&.~Äõ.Ó
ìï-$aŸë0ô×Pf¨DØµ [ˆö<Í•½f"|‡ÄU¿H ‘1T+ÿ“Ï\=ŒLT­p·ÇªÃ¹e~Ú¦ÙŞ1¸ˆd`)İø»cö 	î{ìéép4lB°ò±{´–Â%ü®ŠÎŸFw¦Z¿?ªşÈH7´fØ^^.Gà9,h^t¦ŠĞZÜ]ÎY<ù^;Ö¼aášo¡­I!İßâ]1{ù2B­ñâkÜƒ á€0¡Êo9¸bÄTtBĞj¶o9ƒ$÷ÉÎ¡PQb€Æt3¤. "–•RúTğ›lí·0ª
ÿ\ªd._Haµ³HÉ…/,tÅÄğ!Œ˜Ğ‡øª‹`îßåbÎ(İó›T´’Lñ
J'•1ÎøÖå<î0˜â]™µ…Â·ª£;Û˜idqš¸lfvù7]**§ôîCL?±…ãä€Ç¼â®•¶{Ø2c@^¹	V4Âğ3åú(Rà`”äÊò'[™kgIíöÏ„ o—È-5Î¡Q0	¥³§×°e–ŠLF’A¹¡öf{[¸1õ9~Æ­f×Ô‡Aµ›|aŸà+e¶ƒ=SÅiIÄ='—‡leô¥8Æ^™/bÜØF	?e‘ÍÜc	’‰<‘mmŒi’çœ_¤»r?æ[®Nß9ıÈÈr_<¡Š
‹Ñb`_ÛùÀfdÈ‹•<³‡¾·ãœwl0gÖs×^…(=/C¹-ğCˆ¥,z.ë†¶ÀS›¬¹ĞÄ=H´PÑš sô¿†æŒ¾a"mCtîü×8b[¤?¸iß‚-&¹"HqMãFÃ1š'©:ß1õDÈRqùü„<;÷ëË¹™eó¨°zïº6ËbšÎ¦©ûL~/Ï?7¢Ğ´¸ñ’½ùZ,PL¢?$‚3#»ßm’é}÷÷¥ Å´¦ÚrNu±øµ›TÑ1·æ°ZĞGöèg¢nJ×G F6›ağ».æ¦Iüx›²•55 PPnÊëÁkÿçWşùF†¤¾™Sp
Z¢®sø‘Xlö½’oúQ¯*øU‡½ææ1÷æs[µ`¼p%"=~/¬ô:¬¯@m]oÙ×X‹ $õ9°Õà¥ë+‹1¯è’DÄ+@“Øxc½ş³B°jÂqWa“º#¿†ß¾^}_«lš­÷ÎºI+è»•4ŸƒUBƒ>üãsÁ«¥m¦)dÊ©Hrå¼Õ†‹ºùº¯°–qøJúgW‚‘ÀÑë/ëê$¹˜42}•ï€ï€Å1äÕ~š€RŒ¨ß|…ñ¶İà1I×Â¶`ÄbtVpúYDëé_g°S¢K5Ó¸Tà˜U,\Cq?¢g¸ÖÏ"S½sËåLí{:wøˆ´u™ÒÙq<®œ„Ì,!ñ 0”ñ-.éT2ézAX51âş½œ 
Ì2Áê„ô<òİÙô0Â-PÇ
sD'Ô›e*8º“˜…¬›Û>–’HIµ¸rp,3ı4#¦¬õ©XÅ‰¬À´b–Ô,=†~†VÂ!şÓ[VX¹£ô	²¡',¢ÃÅr{U\b¤®®ÖCYÛ”#*nqÛ4…cgY³à}ğCÓ–Vÿ?]>qÔœÂ©KÑ¶Ô1l’o	aŒe°—qrŞ4˜İ>m'Å[–…`jPÕ_é4#’Ç“|a"m/26¥p »3#<ãÀkŒÄQ vN¶¡‹vK11`–ñÚ²Vx%3Pãğ™ë’æS9DK©Sş<ç€o”àºål3fÿ”Û¡*%95³`ŒÎÙ³ÖÈF3BáÍv´?„ÜŸ‰ŒŞã`7ÂìòÇØõğl6Î!¿&MíG+&üİ…}|r½ÏXU-}¦vÑ+,3&ÒOÔ‰Ë	-bHÌ»ã8ivğÂ–lç.¹"N"Ã˜;ê7äŞú 1äs¨ST0šØÜaØİ8ÎlÑ‡àDT¨ümˆ2'ØÀ®ëIoo2iè‘–|?è|lÑMÿÕQŸs¸79fÊvD±É†fïY+ü„ÁlNÛ;zÿÇf›f¿q5©ù2qú-å?9ô¬!ÚL~|²dXTı‡xÀì›+¥¤yLtÖ“ĞIEîœğ!ïk®gèŞJó}Ã(Ú?vPçh
Æ‰r¾¶şÜ*Rıâ`d3	Ø„h¬ŸÏ}Şòx¿\‚|Ü0¾àsƒÒñŞôÜ^‘¸¡Ò6iWZ.k;£eQÄñ}S1¢ıˆªî=éóÛ*~œp)º¤Ì-$O¯;üıµàI£EáQ”Q9ßÕ;ó×ÏõÛdÖRñd…¼‘5EˆzŞÊVû.\O’”ÇE™fÍ»5ÅDÒv³i¢û›•°4ø³¦œ}#oé‹¾G…¡zT?¿Fíòj-ë{BvÍ{BvA‡kÂX‹ùá~±RWdn0]3Õ‡ºô~Är—uÆ!"ee°aÉÒÚM|Ïù'kbF(É„¢]DšqLC‰á‚u2ËÓ…¬ ªò…¶±Lè'™T2¼mÈYF„çn§OHp‡	ø'äAĞÑä k—ò÷Àiø•Šâ¿Ïä7ÖYLq0GÊÂÛµ{N§²åEmL3TgÍë¿ïcIÂÊôã!-<¯ë=„7¡Aµ+Œ„ø¨d«;¦0Kf`ğõ=òcz ~ë	‘=—mŒÕS”Æş©&ÌÕVĞ`Af¤ŞMJæâ©ğ‡§Î)®GI¨He!~…‡6^Ü®f½;¶@^ú~š£ğw	
èâf Ò:´–BÇ˜<ÍVP¡é	Wr‹!ãNÁÒOh©_àn2ş³èFÛä$Ke“eó}s\rò®Dk¼im;ŒNÇBajŞŒ¯`ÅIìrÃˆMˆÄÂD3)øeõíƒÜ¯¦4ÿ½ıµ8åCd±ü,­„hÈP:D„I\„ı£ í{3‹
—.,ˆZ¯•çZš?1ªu/E›µ°ÓçX5òZªŸŸlCp®«Í«tû¼’¨‚C†‰NÊŒş<k ã¶„}±Íı.ıêÓvõHë~BF³.6A“}%ßõó>†­SÕ9ş—;ZÒúîy?dj;¿Içå«×®–ÌäDt\« y˜iïÄh“¥P#Ğ”WóG°(,ÛÇânK®¯™„ó~°[lóFåÁç—6ÁÒÕDm°çˆVóMpˆ+D.2ÒsÈ€ùZkJ·ã—:Õ’=gµİê`İÆ“Xˆ´µºİRĞ™öÆ%ä~¯A@`ˆºLìÔ”²eì­Ğ>³T^6š¨Ha¥Q	¹:%·€ä );Š”MÈlŸü°fyªã^{”åñˆZ£úòr‹é¼CúA	ò7Ÿf£§$)H€Pë	ë¬qš¨Íº½òv®¯¶?vº°‘G4YÎã…*ás49ÿ«–%¬rw—›Q3Ş<~‰ÁËZ¶7h$“[xÿñCõZègÇÖ 6'~–¬é/­LF½[™Æ˜Õov>yGZ·ï—-ãŒ:—;\­s òB¸
˜¼ô©i)TŠ‰Fj Ò»€oÑıÌ§—“¢ëØRù$/­°ç~1¤TgMËé×éÂ™î.\+ÊÓBÖa%Êw)Ø·8ŸNÉPÓ© Î7 «˜HÿŒr3Ã^-wSxøBK3¿ÚÌ‰±v[
wZ?Ni|Íøì$séÀb|ô®œó@0ÁÖì8‡—XÌÂà'¯®ôpıÜÒ®*R¬×øşHÃ&·4Æ}¢&D¼”+Ç/-â•VÊR$3L»`ıÜaû>É|—O ª gÏÀe Ïm+RÃÀQ“W¶<ÌÔo&Á0¥'ñE%R-±\8§û\v˜XÚxlĞüÁÉ>£]ÊŞ‡ aÎj­döö?Îä=ˆğ]D­Bw0ÏçlË”Õa–‚=h³5jxÁà …ö[Ù  ùøêA¹§m­ÀF—¥\ÑÅa2‡SÏ“ F];E¥-ÿD™«îy§ö5|)M©Å•é³İƒDùRSÜ²í–I1Šn«¢Ÿlá`pRåÀ©âÁM|¥·ğäôÎG¯Jp,AŒ´â ï¹›6¾ÁºU#ûË³æÀÄïVÿ äb“]‡ó†Éåy$?Æƒñ\‘nÒrİÑ²’ã‹V~(gá¤u<	s÷&‚:3Oš»qs‰~ MÆCÛìÜ˜(ÃîJ»e%Gí™°ãà¢6(-“Lö88*g;¿á€­½%;Ï?ó©øEäº
.sïŒ³œÇ4ã’I‘)lã¾a¯Ì,>T…€‚"·!|¤‰<ÖOR¾ujmê 5AzílÂ¶É¿~«¯®IRËÉbÕª©y,ÍùAxyW­Å|œ¦Ç¾P–ŞFÚ?`¾#úÎƒÓóLüú+#Lî~Ãû·1	{Ü}3ëÁHT"ş:è4™2ÒıÜBAşú·¯u£6ÿî¦o:á„ÅgÜã,‰
øß·œŞHK"ËG£¥˜²ùÃ¿÷El¶aƒ}œbì!˜hµÆ²;P½òBj2!·ÆJ¨Ç"=æ	´Ôğ{.×a`ğêÚüÏÄ0ˆC-€r¤6ulØ± éÍñXë¿qT;e"ªÍÉùÉıÄ8Nı•U‰SQp^@a1Jiçxc°ÚAk M¢¯øóxŞ8uK.º½Ó<ÌÂ—‰h˜EËxÜMç{ğ]_-òy_Ó[ßQëocˆoğ•U·}ê7ÎÒ‡¨gåëÈSÙAÚtÑñ´ZË†º¶JÙ"AÈ—İiĞÀ  84”fáL‰¡EeÀuö \8Œ0©<ßÒÙ·ÖíJGO†}!íjÅ(îúXüºø§ÖÀÏ´WIö21¶®Ó„£aL­¾=ç¿ÒP-¬Ë ê®f==Q\@ÅÜ,S=8Ó-—.¾«ü¨¸ˆü
™‡Lr¶’GHš)·»ds-¡Ì8 ƒ´¼˜à÷nª°‚§¯Z™™ctğH‹ŒœUçßİ½àešè3ı®2©°k_Š†ú kñóS'$øÃC€jˆ=):Â­aÜWÓHœû8_‡=–+@­
‘^2µø‡¹-.7‰±zt|è>XŞx#™%ä?TÔp©k¹,S"¸0*ì‡Ñ[1ĞÍL~%“n¦k¥¢ÿ%îTš…YÖ<lòÜkc&İŒÒd7¬v*ˆÛ ı”››Ì"æn@Gßë‹
PÂb6¿s^bá…Reâ>	ímæº ·„ÒôšÅ‰GíB¯*(òŸ>˜ÅrQ'Š=7»É‰Q[™8ÁÅä
Z4šî˜âÎrìYï•*Ã=œèº.d 6ë* *ÂŒ[’·çõ¨•hÈøŸô¥Q°M´"“üÃ	ìâ§šuÓ]	G”¤ğÆg®‰X;şáøku=9ëL/&û½l¥xÍ¾§íÁ¹^ĞQ¦ÍIxßX'vo0Ş¡š‹ b¹m$¹(ÜD™0>cä	wÊKf•Q¿­…Í+Fà™Ó]	‹Ğ3ƒ*Tú(×M"l²òm¼æ|(sĞWÊ¢àÅg_Ì$ÛıÌ1˜%:DÆ2/æÎ³ß;ŞâÚ—bâDª:éëèVBZb±‚¹šÆ6œõoò”¢„Xƒß}æı›Á¥J¥ûLy¸-xfiyS`f0UeL#“èÊŒúÌwŸÓ<QˆÛÀ•ƒ´—‰Ü‹SµÂW©ŞØ–g¢ø÷Ïãİ£SÙu»XÂİœì°±ÌtSf)›¼)¬ˆ§xİÍ¹p“6&á9%e£S­àoè üÉ–J’öl¤npJ¶,gJãïC. &¤Ğ0ÓÏz·Í›À©åÌm*/"áê+Hœ=cRK¡7YSÚàøáÁœóÁÉÎJ˜ØÜ*hÏ ¿S4dS€A³ÅTùµâÃÅ/È¶]»‘ï6~í*\&“)O[çrÈ˜|Š½–ËbU5°q;¯¸¶¯•¬î‚D6%–ñìÏıì]ao¸å¾ëe6üÍ›W80Å€è5üíJnV©4ĞzÕaMx¥5¶Ò¶àg—U©“u~†æP‡÷ïÆ3³ıòşŞîCÀÍUô ·ì)“ª˜ì9$ö"õ˜ËÈ/ ÿ!³3ş>º–ş¡]œğ®û†ĞğÍ1İÃ ¶í—î3¡Õ
Â*)T<Å“v¿ûöÓ{(WZ(
“âºÈ|aPo:ªd[˜N©4ª¢»Ú÷Üæà¦ƒ¸`)õ4iK´è"v|®¤¤ŸÊ2óÚÌÑïZê·›+aÊÆğí°ãå¦¿“ÖLzµƒPÿ ¯øÃè´lAåBîF‰ëÒ¡àÖ¡Ñj¦úË§Ü=œ"^ĞHjû
†sË›wvuX©„³ÈõÊê•$~·PG¡3C¥”©ÈÙ£ØÍ„Á—;f
 (ƒôêòÊA³_ë Å»
4y·è´âa—wrßÃqçgÓŸó®QÏJøˆ!>9ğà/[]ŸîGQ™Ã®y³¡oG6ÁKó’KæÜCùç±öe\5¼‚âºfñ†Â'_A%q—¶ŒËâ{õ[å›
0Jc^é‡Q´«È§S"ÌÊà-ÜpòlŸêÂÀûÃÎ~úÒ›w0ƒ,j›%2)­<öÍ#ïäEuÆÉø>oİ ÌÖæcFw‚F`Z®4š¢/ï™0ÑKÔFÍ³ÂÒ·“Nõé©-•‰©EÈç¦àánÑ1og0¾2¹lo­“™Çt^¯X¹„ãGù•Nr ƒ®Ùˆ¡·¾(Zu#õºõ¤›9†¢ ò«Q>Ôí†øÅ¹*pH€üárçNWí9ÑÁË¿gEo]wŞ€õŒ¢‡}	?zqÑ€—3¤œ?ğû™:·k5ÉúBS/—¬yà†™…œ¶4±«Ü_Î„Ü»LÙ²@ÇMd•i¦¨n#˜ %¸~¾$îÔaÖÄŠm=ºn½3ïx	¤^¢Òå¨Åv&=y?yGˆ†`:ìr¢….¢™l«>†a™v¬`/©-·ûÄd	–ÓÅ.ŸÙˆ7$rE!p¡Óë^2-87ú[ka,Y-ôç`×¯#¥ªd¡ÓP(ÜÌi¹f'ˆ"1ØÊò1äÙxÏİA	õmš¯dU»%„cw›
S¡×òQôÌ”şÃÇ•í–ø\Ø¶.Ë5fÆ—1Àè«¿Iõ<:r•ƒ‘êMN+­ÊYWÛşB¾ä¸èeöö›×ğvğ³İGÍg¶Ô‚wòâ->èDTULˆÚˆœ®LV‰ór¡NY‘PòÚ–T°‘<#í±j-Z¯rùåÇ­änSÚÎ”ÍÂãk£wnæ‹…ôáˆV¹zô\`@Uhhß¿Cd)É‘NuNò9Ub¨€Ñ¶äeN<jÚÍóHó‘€³c1q=X?×ï¤^Ş*åÉi¢›w$t˜ù Ã7w‡@&EÉ%t›ÔğĞ‚˜ÕmÁë® ›m¾l	ØAeÂq£q³ãÚê²Èa­¾*VÔ ¿C
s¥"
Ÿhù¾7Â¡BAOÚ´?é¯(¸k(=ÏëÀ3¢qò»Œ”²H>eZ¹Wæ3uĞ9·­fxÍ/ °p‹â€šlş+`ÁëDß8È©Ó„Q¿%PÒ€ùS‚´-’¤Ì¼‘îÀ"¼ûä†8Ç ¨ûúp Ë@ å&¹­®_¼‡"²Á
( ˆ%H7]b×ÎØe›Énş‚˜°ê³¹éº:¾ö†¹|è0NDok°r#ä[ë}¯8‘ë6Şî±¦ÛmÉ0Zeò›Í|òÅ{ı[‘wXĞN§®vèĞñG­“»ëE8D§Ÿ(U‘Ú¹kvqİ‹ZaÍñklEëö““ÿ ±]İºD .|WÑÓ•½wüã)PÏó¼àFs\®G4?IÜÄë†x#«œaæS×ÏÕHÎ
]p\º…ñyÀè˜™Â5S†Ï©í¢Æ	Ro†^|_»Õæ¸´œS‘B*6ä™¼ìª‡òğìyEœ(éÏgß<¬ÍîHåLv„¿³ëÿĞË˜Dé6ı§bê@H2‡	l™‹¼+<ç‚×¹ŞMßñâä'–ªR…œi4ˆ@5'|ºÿiÎQÓ-ÕßşÃìÕ’3£›p*)]¸Ê‡è LRmª(PÅê¥ª=—¬¤ÓÔÅ¬CşùÃkXNæáXzºjÄ6ĞF¬l@Íôç‡±«ËßÆ¶æ‘RöñÀP(›Üs o‰|¡¿K$íÆP*†<ŞÑívåAÚ[.Nä/ºGºĞ!0^?ey¢ğoÒR-Øò}]ÿQÁe÷fÉ/è8Ú~@•>+ljÑù„Ph£×è.H‰—øxÉBãDÓ†x-q0WqÁ¿¿×ZÁ—øst]K¸üìÛEùW´¼9_—ìY­ÙrT_ÔÍ‹wÎ'ÿÍ¸Bíuòé{LÕc5ïfüù¿¹É·}§«ÎlâšÖ¢l$ÓğÌ4q«}Ë @9â®…×Îuš8¼ÚæÏİ¬Ñ0˜¼ ÿ&fáù3U•ë|³ğú_q,¸ÆzlãĞ±’Zï¿K÷eh&ïuÛÚDd”è
¥˜[õ'ÿŒx6ÜÌGŸˆtn¸<¥‚k^OÀ(a¼Wİ±ËF¯÷ù§.WNYL¸İkû3, –Ï*b=ä@”*õ©g~ö»+¼C$+ÜªîÂ(;ˆ}ºHKšfªõŸ ‡“Ä®èà{H?<ÊJ˜·8gT™]`uîîº_’çßwÔ©¥æç‡ÕYİF›†S­Ï×­íùuµ2¿Ú\8Ä‰C›“±şB¦Š¹™ÍÖ]ªLöùQĞâêéÀ{©á%²ş½å´†ï^úªa’<y =JÇ´m6œÄósª[ÙÛÜÌúË£g¬InÈÔ‚Å×å‘½şÅ	"G–ŒÈñÌ´j8¬+à×/È"\ÒõÜ‘éôvRÎÎx¯TşÍİ9¤ `¾£­Æ4çãlvøñÂ|ÿç#ëæª)Î.|Ë
¾|16n”2ÀÑHıDÓŞ>´Æ$üÅPífáµW—§4'¾Ò-`;šJíOAì^OÅùíâ#l/µÏLÂã'vààâÕ>ÚĞ´U?‹Ì%s@·Ñ÷p¹ÙßmLO\Îhº—ù×ÉĞÊdÂÑ	˜Äğ§ ¢İF¡YÜ	]plV6@±N÷ƒ+EQı½,†Ö±p vl#ûÒ°ãf	Ô
G)5©<(ÊdüèH8kUgIªM¨ª“İ%°»{ÍÔØ/ë¢’Eµt²ë%ˆõeqåşòfc]Ş\™îC©È5@–æ¤*IBZ"êK>÷&¡™¨1ÃÀÕ/,2óPJØ™d±ã+GBÿ4´(Š,Ø Åp·]N&VkRú1AÃÙ©ì±'a¨ğZN\_Qáa½¤³B©vd9OCòğÌë¾ÉíxvÜöâh~Ò0@Ö…úæ†1‚üö¦%Jï^­FÎ(¤TV×°¸eøÀ«[óÄŒ1'Â}oõfÅ;ox(±ôƒÂ£ÅK|ªŠ°Êè¸µî–˜òãº‹ÌºüÖLE¡¶­$ë Ï`¶ìƒk÷WÙ{
ƒ>ßLÇTdó> –‰*Ş_`×ôD]oK?›™œîä·ôtÌ%B\7A’²Õ®¿¢µd©•1²ËPÅY™b
ñÒC4’¯|sF	Ñ¸%1w±[Z÷(FİL c4õÆS„pm?Wa«F£ˆpšşç§„50Ğ©ˆz=±¤Šë_€Â>Åhƒßg½ƒÜ-ß³¢ãtcœ#óÊ^«\Ä±5Ê«‘˜³
1áùÊMÕÏ÷Œl}øJ‚|‘ß¹z6j2-C¹“bÿ4“Ö`;7(O_ …´S>)à¶'‹•8HTU¼Œ­œ'Öòô(ë6Jf8#K	r¶Œ«Äh¾µrIT2wX¬¾Íï*é”¬	Ş€˜J´d²‹.œÆTÜO¶%nŒUs‹H„gbN$”öİ}èÔÈ(Ä’õf‘\J¨%LgãµÇ”Ôœ=×S"ó3§`¢©g“ÚÄø…ÒÍSó@pK5xAy:TNIqsš=‹rd™\á"OÅ¶HW’;šUéŸ£S—¿ƒú´É>®*€'½)²¹éÔÃÕy'Jl}Œº-c×:²N-ÉÈËû>§t÷´x1Ãÿ*¼p‡Ø#”¶„9€(E“Mú y r°¬ÏEßG–ñ„Şùà¹«Éx*l –?|lİ³ªHµÙ÷íònYu qÉÜù=`½Ä¤ô}Y€5¢Ê	_L×·mõğ-Eå|;À_X_£Åy¶_Oh±Êµ°o’Õ!$.Ê|“eß¼­o¼öãÚBÌÌ$Ó’frk¢+—¬‚ÑÊax‡h ÙÌujëä«†db¹ãò5S¿k›g®¹Ñ“H>IQ—35`ü•¦ê‘nK¡íD8Ò±õÎà½ÏYˆ¿¨ÀbŸOF-ŸR¨;éÄ¾[¬²PE«4²lg;ÚvFeYV¢ã±ÌøıåŞ0xz:/'È_PŠ Ï¬sÌİEÂáÎÜ`ôàs¾_æ‰äj×]cN N`~Úq‚M8`3y'wõˆ
ˆ}şaÔôZÁ‘¤³›uréqÏãéäLãZ©É
·åÕÀ–}®än¾¹h‰˜=½5”å=b À"8MÂ©dÌ€2ÿ5H'=<$Í¢rå?Èƒ@&ê$AÓŸôAq“X. ØÎ:ôIt°½@sü{‘~è×ÿó’;SaaW™sa'P{Xí^M|Ñ•F7%¼>¥]ÈùP2ö„ü´O2A‘Ó9¹¥¹£yÃh4g¡ğ´bó“(51Çòd	üW`óˆ³‹Ny2¿çJ¨nEÊF9Ÿ8Af×bÕçtùt–“]ïûÁşf*VÇÎoÂ 4›Î«{½Öd &ÜÓÂœ(õç+ àfE zomH/²@MeİC"íá´,¢=v(µÈ%)3m0oÌ‚.L%»<ÃÇ€ñİ$J„=²V€ãÁìRL*ÅTzR^j Û¹ ÏOUnùí¯ùz=Ÿv à\|ÜÌ1-k&HôA…UÜDø¡êoÅ°e‹#şE&`W†‚œ¬#›ºz;Aà[(8Ô…ãçU9`üª¿U\KÁ*BR˜±k2²ÀXó[Å±Óà4rSÚÜ-mÖ&ßEwå°öF¥s“rQ~XYk:Î%ø&…òõ^!¶ix}$|Õ¿ŒHËM„›ÆPé3‹” Ü$/WfÍÏ¡‚tâÄ~Ïi[æjå›‹—ÉxØ›õºŒ53¤îLñEåÉÍËÂùÔcÖç`ÌàT×¢mú)ÄU2‚ÖìÙiİnÁl¤º©¬Ëìk7†’î—÷”x] %a[ƒU9´Tt„ì4Q¢‰|T4O*×¥ÙxåÓoûäĞòî›œûCp™ê…¯Š@~‚äVRùä€ü+-XØUD-Ô¯%7eR O‘«¸ÌErçM!åØ¦ÅœÇÏs(0b€‚ÚéÎ5ûZ^d¦N¾º+×Ü»Ú}î1D¾÷LåİD•~Œé°ú´Ev3m ËyÍrØÄg$&ƒAˆÔbšLJÈ…ê«£³…·7–‰İ5IĞt<ÖúM¤~áè×2G²‹Y›wšL–ëË´ğ)¨Œ¾úˆï	DÄW=¸:&)"Ey…·5Z“{1xÓ	Ò7ıiW;R/¨!D-KA_ÆE>6Â4•´ñ,ßwº· ²…E°}b.$oªæ\·Jèá"K²0aNN1$ar\à’vqn¹­ |Ş¡Ù?Ùt)=ùT¹€ı«n‚$ÈJôÓcnÊ,¿açşîZÒ]Šu×>œ“ƒşßØU;`ËGM®31{”·‰IpÛÏ6GO×?İ4“n5[/¦JäÕjöšg`ÎğÛ1:Ô_ex²õ-=ä¾Ì»½õ‚^ñ¹‘=¬½WJî×lh½7«W="ûC+³*—^È¡”[U­íùÉ+Ÿw:-¥ÀÆ—z³£¶l£ƒî_ a?×[OŞáÜ±¿Ş—¦c"Øÿã0õ²“^awøŞÙç†½ªÄÓPEh{=¤âĞD¾ÜÙğğº»
"ËùÂÑš–](ğrwHì‡2 ’Ó…­õ•Âƒı?Ãc½&¬ÿÔWí5Ñ¿L™S„bı±z. ZÇü?UÆÀ€m%xD\çCzó¸CÂ~¤„\XÃ=»+N—á³k"1,š\¨´bWÉb	ó#fNşÕ±’	?@,FTZé*‚^²:ç AÎíƒ£bÍ$ä¬³üáKß«Ëê¬º
/Ê¤ü `ïå[¤?_^ÈÙ° ¥æHtêŞ¦~u0t,GÑÙŸì¶ûÁÜ->½ÇG?€¥½½ûY/ğ{ÅĞ#rU’ âÌ(ƒ[ñ<¬¸ï}†êÚZf˜ÓLR¤¬Ô'ìóRÀ*îm#}q:ÛÃ…ïö£—DÔ,ç3Él-NäI@$D/0ÙL. °.(ùvêXªè[xÉ?@ñÆ]2Ë/ª éÈ„{áùV™P§-Ş#!¦Ğª‹µÄ·÷;ìÙS“±N_³h‘d¿ØK¡ø©(ò/<T•È4¬¥‹«J–·j¾}–n-k¯›	‘ßÓ”İc¸e¾ìIò ôØ„3ä¢­$y°›ù}Í3C‰lèõ'8qÍêkõlàiüÌU€qÅ5ö§MŒ1Ïµ*MüØî0Ú,ag˜Ê¶h_­Ö§Ò›0]†8×&2½¶nqa°ëc¶WC‘Š–âÿ†=œ1œ05ş¥}§2«£§1™vJ‚ÿ5öHÎ;ç4µ;Ô‚^#…ò\\¤]ƒ{¾·ŞkÂ{n3Kæ!AĞ(ì Õ…„Hÿm&HO@xËşl¿ú £?˜yı×Zxñ²Ë=ªkàÆÈAJ4J+Õğ?7äÇ¦1`æ®á±Æ,aXş¡@bzDa·w×•äMen°u£oE*†«—¦Ïå‚€¸taèNp·s×ù(ä6«âÁá\>F§’åC’@œâx)×Á=áİy
DÌãˆ@Ãê©ÄûÜò‰ï¿ä+hp#Y&<òÜæÛÒP×éRaÀÏàÛë‡bˆC`Ûâ"ö’üï€"«®ühÑR˜l¼šZî†2³‚ÈAmÂvmEş/ğtÕ"ûùÚ÷¡Ê¶ Šn?•â™eL?/.uRhâHƒıtªÙ›†FßÍ^£!Ø Y*íuÀKxU6ëÆ=Æş¼oNYÂÂêpN›«r/İ-¹ß‹ag'åÛñÏYUp–ˆ˜ÜÁhÒ?Qgh~/$;#†úœ³Ø5‡#îIu›,(¥šğ®ş½y2Õğ‘ÿÓ6HsÎÃN¦gœ1kßÆmüîÙ`bÜ’·„½‰"4à|K{ˆdx‡LwPûglGµ?"9Æ$/0XSX‹íTOôù/Ø‚ ¶Á Rú_üÈ®³xaºèš†N£|D…º˜˜ÚrÔëçDVŠP\/O0<}åSx‡â‹cûŒ÷¹‹d=Ïş÷góæ¡V“#aôÓ‘ó#TÇÁûaÜzwîÁRe<€Ùñi÷v@Èd&‰™ğF¢Fso†Îå­L‰àæg6!½¶5úÅT¤D9M”ft½5ì_’‰h‘ùW_åºVˆJÀ¹ÎGvN&÷½«&\YíYåæìÓò¥b´¹ñäês¿â ¹ÿúF8†°êºR:rû­­Š–å¥RƒQWö'Yšr¾šIï)@´!Ë±	ˆJ“¬Ê$vô³Î±WH¬Âóæ|s{Hwü4¼_°rèÒèyŒ%·ÃÆÇ9äQSoä5ÉğAÓ(rê[(ó~“»ÕG&„TÇ(ÙµD¾S‰kÌÖÀ…İS2‘¯Íyœ\,pÈâMŞmƒÿ«½¬ÆZc%K7™q!hÊ |;c*×‡ñ¦âš×,pn   h™‡‡ÙÍå âš€ Ü4‚±Ägû    YZ