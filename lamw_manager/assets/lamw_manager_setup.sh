#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2920302773"
MD5="10c960b29957bda95949bc57ebe8452f"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20892"
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
	echo Date of packaging: Thu Feb  4 19:26:11 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿQY] ¼}•À1Dd]‡Á›PætİFâï!–<æ§ŠµI£~ ¶°ø†¹¯¸<)=cY$Æßÿã4½n€ãßÅ%¡È8Q_^3 ŞZL
´zOp)f—%î;ªS.óv’“L™mqF½5Qˆ¾½‘“ àúp¶¨íDºSw›ıè1•œmMäÒ ßÑÌ§y/ßèî62/œVUV³œI:²—;Vt©×&Ä1;Ôª¿ªaj¾Š£öŠÂ2Í¶±âÊKxÙ|ÜlìjhÀÊˆvä?£;!3Ğ‘ùÖß—ÛÜ	&T—"6²³n9i€î|_§Š{@±éÚÿ!¨+V³N×Ç¼š!QÂW‰¤}kÑ1ó’'*‚AÈÖ!ï´µwh³SjÔÁŸªò!ğ–5íp)˜aŸ8Ò[¦öé¡[	MáğÆíN¹¿€éë<F\cvf¹²`X½¶¾ÍnŠñ’—‡UE,¤Ø&_=bĞÂËÇø×6¾Æd‘ 	cmSøm…’¨ïÂ¦ÚUY3µ2¿_ì\sÇ y$u¡Kø(“\î#²3•‹Îò.ĞÒ„œú(ç‹u: |îYôşJèL#`}Yv'/ü,ªê=©Œy´Vä÷g©£jåK‡>…È¬{Î¾_=%è{bçön_´‚¬WD´­áÉš{zšÁmÁGxˆ BØ¦$ qË]Eœw‘‚CA	–/ü­ÄQ@ß	±osÊædöºüÜÔ×T5…=ÙËY"K5;ggŠ¤K2­7]‘İËKRSÇ67#aFb„kW;Ö'åE×‡(^7g#Š&’Ÿ+ŠÁEŸğã¼“DÈ6ñ2.&hûó’¤°€1ûÑ,üv><Ô¯åá¦swIŠyÄEAÂÔ.» ²}ù¼$Ÿ5(è¾­ûêi79ò…¯EŸşŠå>ùÈ¿^p	ÎOÉàş$Hq¤š9PgòŠH´ *=:¶ş Ò÷â"€è(~FÚ>
-òb5oÈ9n_ásm}Œ™6’=jî-ºìã\ÆF}çÜ …š{ICÂƒÓMúìI÷»
2.uX+TÍH•Œ‚WòOCŠŒ¹$qì<ëÚ†œ°b‡Qpg›lßEZrk ıxKÇ‰G³–5U·<£M ×™ÏØ”g1é)½3ŞÄÜk„H²G­Ğ•}#Ó»„ÆÜ:
E|n0ZaœÂ±›`òácJ:¤3ÿ:h^ÖÂ…ÚË½”µXò¨Àó@í!t½¹_¿œş¾r×vÿ7£Qoìv$­øíœ—Vbş¾JªaT)9y­:´<Êƒ¿"Í%Y€Á¼+ípùÄ¯»ØoæVk~ŠyWpûK9Ã+6AÅú£\6Rt00fû5­	n¹p×eüƒ­ m0óœ±Lêä##»€Şó_–ã=Z ¤‚Óx U„ıÎ €FÏµòşŒ(zÂòú$Ù.OO·¢©0”Ó‚Ñ|›¸|Fl_•îó@UØ—Ññ†>Ôƒ×'-«ÀYã¾»t)Å­á‰¼%Â;ôÅL¡‰p-­Á¢ Ùåk‹Z_›ŠË*(p?d÷¸ÎXùÿ!
Ö…|d15p_×ıÿz;û–k®]æ^rÕÔå=²æD¥:Ïÿl–vl}­š¸?ÛV¹M¤^ş#7‹K{$±d‡¡^Cúf—.?fBÕ¯ …%±f¢OHBz6'2¸ªÊN ‡Ÿ¼W‡İ‹ªÉ‹#Ü½ p	•+æê¢P‡Åİ(gµ¡'u&fPÛ»iRâé‡ã
¤ÜÖy~09w–‚®ufû?g±°Ü²3Ï‹8'¡¼&ÄĞÿ„ÌpÓ["ÆtÂh„µUoüÅØÃ8ÏKÊ&8gVº¶øc tıma¼=´ßr¸«í?áU­3lñŠl½%ÑY8å•ŸÈÊ/åZÃw/NËÄsDD‚„ño8Ç8ÛÃÑßYU“:”Ş8˜(öéªî€™}UÂŸÒíÍ‰¹v¡0¤äŒ’ãßßùßğÎš¥Ë¦ˆ§ïÕ3o]‹Ú!1f¢» &rz†bÙÜ|À“tŒİ¶`¿½ö©ç†/.m^Ø0ù(±+½ø_‹¡f-¬Äwİ°O;ÎæIÁ–÷™®zÉ£ĞéD…¦¦l ÄşáBæI
Zt„Ü±A,
d¿`y’Èr‘\¡2Î4õÔ¾a%#
P!^7±óÔÎ™•UïŠÚ¹ ádNofiÅ¬2}ˆ§YœÀpyŸNÁWÿwyÙñH/ ¼º²GË"y°[J§ƒ.		üf:ü j7Ïe%@·¦ñ–oÌËVØ³otœƒD¤‡x[1>ö7©a'*ãÁŠ…C)ÍL5qñ;¨,¸ ŸUo=| >Öá«q°óÂ7Ûf0•¾ìÛÀ—µ‹›×Õ:½Ï0ï³ )SK&0PyŒIj°i';xøö:l˜ÊÓïõüóõûUÒÙ~qyÆvÒkooŠa‡zşæèà— ‹˜ïmì°–©šIï,¾óÓ“ö”sékƒM·jÇ¨9ß*ÎÒyz}Jáâ¹"å.ıÓy¬Õ3Şİt‹nû,ë±B¹[·lù°¹…¶eğ <0Ê@©âàx¬½ô—TpÑ¿íú–7©¹1O¿rÑOâ+L]‡5ÚqIïS¿ü?ÌLÆ!ÏuÍNmÚ?âıX4¢;¬|õ·ò ‚MW¥¶P(èU<*ªÀ©ëU-×4Å'í½khâwç*ïR‹17t˜ÜTë5	·¾ÀĞdÉúõÀê¡½]ûÆ=:­şÅ!&*÷…;µ+In;¸1ZãA9‚ ¯6äÁ&7Êõì%ÒÛˆ1î˜ˆIÔF~Ø˜µÓMÇgÚg72S¡Ğßœ³|‹dø¨sÛUtıè¢º®œ ¾Ç°„$Óé”cSWl18ïgØºÅÏ+e\»êËh·«¹°ŠÑèf¹Ê%Ê¡8@™5ÓlaÔ¡Ë×MäBf|_Íåüò* 2«wùõ{MXs“õâ.œÌ5A‹VİÒX£¬ÑË9UO5ÁÖ_hš.Z(é˜šôöQ ©Zµ·mWQP¾ñÄØÌ>Ù9y‘eUbB2¥Íöóé§¶$‚ÿêiılÀAUÕhMõûâ_Q>ì½Ú0š¦:¹‡Tñ>éû€›ö8'{î{çpÔÄº^¢l…wÿ}Uœâ4ı"¤J‘k±XBÇÑ'sYÜHÃE’õ:öÖWaLoÄÕBÊ?m·F‰‰wÂ†Ë6c´ŸÂMµ/¡à#qV=<–”ÄÔ•Û@p~Õ~›K…^9şo‹ƒ±ŸM­”ùiZ_v*ùVSyö¥„§À p{Íˆ–w‡2ˆ=§9Õş°'#„•İä¡˜³éû*cİîöïXâËÑ¶µÓ‰ú5ü|l*İÚ:¦Šÿdxw€hW¢á¨ÏxxÆ£·œQ‚b,­0B‚zü’K[‰ØĞ#ñ;ÈŠ1"f]ÄÆŸäìvú|N…2şÄ­“¬ºËıËÎŠrÓ|ƒ%b´D…2ĞÂ¡å³ø\½}ß‘tÌÂiŠS<\ÍQB1-İ£;}\	ÄÏ^Á…2´±ˆÍVaìÂ–°h}Ş@j ßÈgXèÙ$–¬0Âh÷åm+è(|—tNú!Š¯)•øYrû×ì¹¯ÆLÜ,¤ÅIm«/”}Z5ğhÊÕì	Oø/Öò*k=0(½—ÅÃ§<Ÿ×
t@Cì),q>Êê';zbrIş¸VMå„gmƒ_Ö4‘ğ$·Õs€UÛ\Ü†ÕÚ”£{v“»ŸÂÜ-tİÈÄ±gÜİ™–¬0³?²ãXşº>
¯Ö5÷ÖÉŞS±ŞKµ¦‘Å™Ì-:ösèwgC«cŞi×vdŸÑÂ<o¾Wá¥Hn•…AÒjıh|S‰#ª)Á¯ºh° ®`‰Æè#ææ¡‡µRØğ€dé~E“>×œPš3ÉMi&yePóóÂê;âÉiı\î¼|Ìf}	³cYjå8°uVÙİa`ÉÍ§£^Çw2k>Ò·
ğ¥öó8RYD’ŞÂú.ÆT,Â]ÈGGºêˆğN\^ÿè­»Iüœm½"ú’†ıùë±”q¼û¿Úd9©±ÎW+èºİÎDc¼+¾âËl4&”ÖR›şhöW°¨®ş+U*èö“ã‡³«ìÕNr‡¿pù€ÉWtøŸlú,ˆ.À‹M¿’f@y¤ÁÆË<O(ÒN#§;“‹P¤ZüÓ‡·õèÀbò>_÷ÂÔå¯å«=ªƒxAŒ“/2ŠİÒ5?ó¾ù§o¢„²Â­SP£~]gÊkz,“N;œÅ9šmsï°àtNü@Ç)Áğ`Ló‘…Ë“ìgÃñõTb£=¨·êM»¥‰G¿úkÃ„³jHæ8É_ídª›s¨F;‹M¬ƒ©E¬zHı€Ôèk,57\‹Diòä¸Xxô^o{-zzWäÈ\‘NÒ?|± İyuläŒ³İèu}
vƒ3´Àö—H¥Ø ;"Q¢¨zK1šìşòÁzj1Ë˜ÂøPâÑ‹KÇäa½¯Jl±Å¥Çì·bòl‹»ºĞnîv[İ­p¸–Ù<•´|C1ÿÄC<Òîòiù¬éŸäIòmô)›Ó8K¡­†6Ö˜}Âúh@Ä¬ÃÔd$¥¼šdè®°N›ş~#	YÜd3šö&YÔäQ‹ß¸ÖgÔë^­’#€uÿf¢
ya¯–Í@z:Pdí.J"ô±Q"ÊÖ˜/Êi”ä÷zR,äjÇŒCíÊâ«òt‰e€$‚‹ğ®u˜ñbfsñşØ”™#5Õ•ÖÂÃ#mÌ0 F_ìb'û@OÃÑÀş“ßYöŞ$;dgjHûºN¥kCJ0îwG±VˆnÃI…oêY,¦ˆ¨®Ÿw#íĞ#°¤‰ÔHeMÅWŞk.)¨ˆµ\ˆ­…ÊñÖ”{”ßegœôXæÜÏş“ÈTìOLÀ/è¯ŸLóùj”‰tx)hEà{œ*¼Øùö<?™¹£ã¨¿Ï+.X<W
àÆôd†>ªuHúZí‚®í«?ÆSJÛ_ÉR[Ói8œÛá™W®Ö_Ã’¥Egu:-… İ&–én#¬ÙÉ32ÁÂÚfq;¼lá?ÀÆğæÆ™•ƒ,»pÒŠÕğ‰Æ¢àr×å99U«8d®/uÃ «m¨Î˜!FY›y“$g*¸ì/«J‡(t­c³Í¥®$'µjI\|Î±¤ñ
æ8âRØ|1öOi”éWœå7M“kYƒ?¿ğˆ`=wt^2s˜†˜ª|ôlÚ
‡…¿<,ï'd&7¨”oö›0«(·
”Õ‡î.ŸzÚ¤dCgã`²Â°2ds[ãËZû‹ÓisZ‘¶S–5&™Ôvå¯p?h¤µüWCì3ÄçC[·•‡F¶QƒÆ0>/Z;ºzóƒç
>O,0¸ òGğİÍ¨»“s¶ci§!ÁÔùÄb«»=­KøÊ`àO8sßÇU;7ñáÑ~±D¡-ÎÎy9$î½à€5Ÿƒ½]·¯ÚšC}'Å¡”ˆbo {á““œ~÷uøUkı‡ŠÌ¸½,bÃÌõ>Ë@$Å§À×:2¸ƒ^Øã¿¶=¡øÍLœ;tIc\Ğ½ĞÊoS‹—_œüºt
Ö„>\‰AU+n§
ô¾Nc‘mi^€9.şVäÑ«o+Ï¹Š¾lpÊ˜‚÷ÃPü]…ÓÕE®Ş|kº™ÏgSq¼ÔÄíLÄ@D<Äø˜V½oYóne¹–xÊI²>±V04şv_Ÿ…Bğ8öë´aßzğSr(öñ¾r¢ˆ°ò(™RÏ B%Õ×</)zÿKÿmñ™ılê–EœûûHAçBj¥w‰è,v’­ÃP°şÎ‹zAB«™·ú5ïC»˜‚£ê‚ˆ%á›Ìƒ´C œmMq'QÄºú{d{u]¥ddı¦ˆÙß…!Ioõí`õe3îß%y6œƒÕ…çf¹ZÄw…µ¬ÈŞ‰µoÔ±4x-Ú‚/İÑ
â#1-vÂ·Şm3W'Y§Ã0ÛœîÖ’Ú·}ÄóH´â\"$â&Ûn:MJÂ# ¢şÖ/ñ"Î‰²aÊuîÇ°	RğkØøpÙOqA!ì¾İŞË}Èé—úeİEny«8°¨d™ó`†|Ô;¥®‹*7¾’¡Ú7"àÿP•I·İİÂ1 p¯Ê:£#UãÖzN`¿ë¦ô7¢1sLŞX$ğ˜âÏ<t§óßŠÔ¯­$i‚²Êò—­«;hP‘º?ŸFÊó¹8••îÑ»Ì]_¥çáıI0n{	FÍv8Ç/ŸIûÜÊ×ûŠoï).ÁíC;,Š2^¹ı2Ø\*ÈÈÉïÆŠ;XŞ#ñÒ§çÙ‚Ší´f$ØJw¶şv›î€Û«¨ÁçÚ&¸h»T¶üP€¨^“h­§ÛS«å†/]Ê#q ¹u»ku»é½\Å¸—~«ÕİH_Q>Cê‡³E‚J…F>Š¼×qI”­"v%Ïôß·H%†Œ–ÔV/ô=‘Û—˜KŠ §Ğ¨¯9 ÖHÚÒ¯û”Çô“5%¦ĞÍX%•ù0éõS¤ˆkÔòğ0VÌ…z¶ŒÕÈ
aıYë—¼Å\õóaönm¢‰/"¬çbœy¡_$R—gE¨1…_d¸Áâ’îÑ©°6Û"Ë{z¡LBêÛgø/Œ6YD–‚¢cöóâÍ¥o"QËƒ½ŒÑ#±`:_èŞWÚ~H„!	/Úy¨0å0;ë Şw8ñX»æbpº¦éåºav¥È¿7¦%…ıWŒòì\¢ÊÚñA¿s×ÂÙ~8É¨(DëŸ¨®†™è,ò(P|/~Oy^„rñïßÛÆ]#ºÓ±Oq*‡¦ª6Œ–ª†ÍŒÈ>bR@ûê‰¾…s0‡%Vl÷ìFô[jvÆª|üR@Ñ†"éuü(v¼(ñrõÄn­zÇ,Y·©Ş´ÀG˜Ê"leK~G}-Sÿd‰ìëÀ%:\Ghìî»yáMWZşö,6­ıèƒÄ6ë‰êåïFbÁR³ğ€™ àÿ!Ü•·½Ë{îí§|z<ù4<[KĞ¸~:Òfy°oñU°EÌô2ÖÀÌŞlìNÊ(³4…Ø|LÅLú‘ÍCƒÛ&Ü´¦QXz†ÿ<+ò´õ,Ûßò@oèÍ3$q·,£~^Zó±x˜dQ`N`âåp”‰ğµ×ONoU Ä*t§ú¹€Ì uZĞœ–J‰¡¹ÂN:—îäÛodP#Ó®Añ<Ö³Ì—–ÙĞêƒûÆ(.BT)G~$™¹ã2/JÜ=É1,–N³àö\ıä\êÛÿyå€ÀŞß#¦æ'”;›şè{|kê^dA˜¿ß¹¬[éx2;Äd]¥ûH{.yò­š¦ìêI–×°wuİ=å]ó¬°„b†öuVA:5r·Z‰–…„Í´<SûiÄŒ<ˆ^ú55Cè-"¨¶üÚ2Ø¶NZq:oYø ²Ñß5Nù´lbáNò<Q¸Q»J–f‡¦â©½O±À›“>œ½ä˜‚õ‘ùc7µ`““z’sº¿W¸
ëÉÃP®Æ8CóE¹T¼s´‘Å'¬¤p”‚T{&æw=ç¸Y†jËÚêzÉxÇV¥AxšuixvÈÊä[«g¼[Ñ„Õ¸F%ä”N‘l¶NÌÄ
?˜ÌÔu PƒÃ»Jkû(ÙŒİF­tA`#ÒR]mH’_å‚åŠ‘mp4[4£yèö¨ã=Š5SŞı{c_‘#j­°øƒT¢$nb+ƒí×9ëÅ*2Bu?:Àïøèi
mChc!¶j°ölg9QS¦ô%e‚Œÿ€'ºø‰ö	,èÏdÖåÁ ¥J³¾Šòœ½ä’şZ/’’ë%â£Õí¯D\Y6¼õ¯\¸õR!r½é‚
8¬¬	7&NÙÉù/:ÛbK_5f]Yô™¨ oŸ¼öyï‡Í$ûãmÔáé»„>şK åóLŠğ:ÚíÈ/\½–°×±ø†'¬ñm,rL­Ü=ÿÎBG¦GÃ`!²êÍiÃNÆ@cä #ıh"Q–_t¡JT'—RE\ğC
…©ã›£ÀWƒVoI÷¿ÜlM³cFïß¶‡›(ì DæëªÌR oÇüé¯±dXCÿDrS±¹iMMÏHÖë+šg™Ò4Šâª_nÕd˜HÊ ‚Ë I%ò`âÉ‘dïlÀ±™8
åHØŸ9<AÚÿ®92Ş±˜NtÊù®şÜûZ8!zÆµÖı¦;ØÀ„6¯T5pšÎ²Ö°U×2¯,8ÂÒ9ÒT7'AˆÔÁÆé0åÔAI¥ºE#°õCf´&ıP^æ:Xª]iáİNñş]sŒ‡M[+4ÁÜèízd¤‘ıá¨Ùds˜·E-ãÛİñÍÙM®`ãå
‹tÉ…§®?'Û j£ğº¡J…4 i" ‹yÙS@#^ Z{~l&5
G¬aP¢—DÊ“%¸”²×Aİ¿)ì;ÿ~éTÎ×ş€N4\Ä‘Şwšv/Œ–ƒæPaĞÂiü:QeeOmÜÜ("Î`¡´`,‹š² Ù„yÄ«=øÊuë¢®Æ4ìòøÕ['*ß:W'D†+N ‹v-~ {¡à­<ó+ö	15}3?RÜ $QÓwìRPdĞÑì?Ø1vy9Ò'o><ÔìBC–Ì´¦—doO¤B× S™Qå™Û2ªÁ•Ï4-lïN  xÀ¹Ô¡,Y/cnsíYÏúÖÜ¤cè ï”,êâc9¶o»Kÿ×
Só}
.„Ë“Å6PÁƒÍ|fm\€Š;’W0#ÜqB^IÛ¹B­2Ìè“&bnhhG4O\>%~ªÁ1]‘"“k:ÆÛT²@T¬™ÕUPKL`¶c”æMùf	(Ì_h'ä*nE5+Rù™ÌÜúå\¬>QJ2\Å!qH¼¯
/¤ °Èë:÷™ q¬¬İ‚$à¸4[}÷œs%ØBÕË¨>F¿‰LÆDĞûr¯5L×xÿÕMq»»4~WˆN(ŞÏSÎ­ªsaÑdÙâ†Z˜lÛ,<Š;ø†N¶b¨û1“ñ@{5ŒcEáÅ.™3õµU=¢åäqO«
àÜÄí‘0g²iÏ«e@ŒMœ¨ò'aùX¹Ôõÿ’Ö3†å—îÏJwü^Šv|ŞÃp«Ou“Êæêëk¿Q€r9&l5«|Óä”ç.¼_l
5{û*ÒÔ]süEœ0°æŒX"`.Álh
•×¯XVJrİ(ì;?E¿›w*ˆî¹æä9ºñ~ƒ&ôĞ?@a·d€^´4
9­\}VQbîz£/‘ İ–ìh¦oÍ7>ø\MâFüø«Hø…È:Ù“‹áWkj¢Úp›^˜7œ¼ñó.§Øç²ßØ¶-5«!W©Á¶Å_¬CÑñE7‰ÛŒ*‰åÀ€ÒZó‰>u`Ø$–™ ‹#•â€A9õ
˜J`²%Bì¿à!ÏäöºÑ³1ö²eÂ—&£ï¨²ÛR¨¬¼F†o“ı9&³Ó
Æ•àf`×YNsÃiúS»a)Î{%Ó"¸´d„›Ğ_¢-	˜QR½­õ×¼ÄPdëÂk‡„ƒsÊ%­ÙÄËrÔù.İ£oà}x¬áÙ
°–án“mê¤¶m–],H—R1ø7¼Á×’TŠçrN’È‘Ïµ«o=ğŠŸùK¼4r$!iˆ¦Ù¤­­T<T65Èµ‹8ºÕşı,½ıB6Êci÷©Üæ#6Ûs/ß*¿ğÜUç4/co Z¹Ú¥B=.c4ŞıSQÕh¦³“P†ûÒ#-í¿1›©H¦,†lª0g`ôË—H·S(;·×…^ûöî'ÿ>Z™µüa)É¬f÷
),Sƒ#Êmj®tGöËDñå]%ÊøÁfsWÉ&+Š‹Û½ ¡F;Ëi—ÿôÓÜ¢Á¡ê³,ñ˜nuEb›tÕ/{Ûö<:Ù×èSpÉ;Øù1d2°Â­H[û‚ÈğÀ÷o•S]ìPNz lx‚%˜(bè©‹¢@‹F•ß<ê¼–‹“u–VéÏìÀ¢í™=¹v]l­Ù!r6ÑHŸD..Íg*®sæÿ¬|6úÂ¥¹jh÷ÌwB¿ÙüÀaú,Û£yPyiáqùƒEJSé”LæQÙBpÁ;JXfŸjº¢«ËÇXh‰]4,$KãSi‹7§Uî2}OµJK×ÀÏiâ…{–}öb·ºF3Î¥Dw§–Nèõh.^ÔtäFõ×·˜Ê±ğ|x$«È4_ÂËÌ¹D¿õó}»YX¹Æ>ÆG…@‹@Iès&ÙÖBKì§fî‡ïB¶Fêƒo÷Òøå†¿ÚEc‘¢$Jà«êÁS—*ÜäouñAYË_"0@ºqœæ-'5RÎñß€AìídMi‚şšl…*$»%[ƒv[bnÓ$96cÕ”HgÀª˜?]aæ?P‘WÅ-:Š}¶Iˆşmf¡bæ9Ös<³‰‰½`C{52ŒKu¹ùÂ3ª^¥%â.Ê~ÒG"ÚÙkq..Á¼;ØGi T/¥à0¢tÓD¹¾!³ÆãüœYÏ3š<CòĞÊ¢KÊeƒd–Ò\Ÿf¶²”—Î>.RE;P^Âûú†İ”&cÇËè£ pösæ£ßÒPâğå¡| K|~8ÍÓÖ 9h§ù¸€á&‰‘Z)¿<îä/öùÄw‰¹/±DË²èÌ|ªÈ;K¯äè¥ìêü\ŠÓ¤ÓéTâ<ìKğãşCçBm®aÖ*qBŞt1º@½ìvXĞpÓg—¨â7g0&| š]»÷u¦ÿŠFu>¤Ğ5Ao8€
¸ñÇK¡A‘"} ;Ò~a*™¡].©QØv_2³iç%‰ÊXŠÓ+w vJî©¡û˜|S'á!D¿}Hq¿43Š­EÙëÉøÜíPIñO
Fè‚k6…”Ôß½‹Î"w'‚±qwùk(€²¶Xü@şÖg&£t“gíV˜E€ªOœÊüæ‘q{ü’$3N¶Os`OfS˜túÂ­	^•f/I	£\øvÕltnùC°eÊ¤Í¡÷Vãğ8©ûí µâ°qÑx˜l}/…×%	;éàÑ]4vo[ÎĞ²Ì•Ã€¯È±I³$\€8A'dğÓ+º² ]v(zŒ¸±9ÆnmÏÍ‚?	A/i¸Khîªwöb$aŠNuêàH…Ÿ¦íím4C	¹Ïã…ZÕâ—šˆÚñ¶Ù=Ÿ À²'SAú–z¢›*­$ê½Ø{HÄNâ„ \‡d}Œ]·İ:Óëˆ·À©’$ïxı½È«Ug¦±ä‚ª‘.%¢ÎT”¯µ–0¾@®ÿÿÛÏ=?Ÿ\u©!×u‘/ñU"%áÎ¿yv¤3ö˜`ô­k÷Štããõ°Ã´ÕCû‚9`Ç9ëñ½ \Ğ¼{},ãT’lA£,ñÈ |Mi"–ëu¯¦ÒÒ~ì¤j
p/+ù·sû
]ÒbZr*àfŸ¯rH„WáÊè\P•ô§3wÏòU×·ˆŞxf4X›…×Åz‚SŒPñãvîPK“¨ág …ú#N­ù°Uë‚uŠA3‘ Oé´R·lßDÜ5]Ç\a"Ù—]¿Q9?S™˜öº7'4šjQõòj—½Ğyu¹:jî¦cğqÊÖ©×¬ãKäîGşîd4Íu„à_NÏè7‰ÛÅsãe!³Ç ÔÖTc^Sáqé/F¬ì¹W‰)¸KHÂ#*#t)·½uòä¦y¢“/ltï¼õ”–AİV|D]ùzÚ{ó¬Ë	Ç^E+AİÔÃ¦Oqzwƒ_pr²+'-JßBŸåz"×š½#F™ƒÑˆª9³¥ÒîÈµWRn`ëix•„6YL±x0¢ûD€x¹>©Â‡Š’2š>‰ÅM	šÙ+FØõ»%ÜfÃ3ÅE¿îVˆ{›¾İâÍĞÏ
ôĞù}ß‚ò„îÑF,ÿ¦sİœ0à«¸»V‚º¿¢¹ò½øo(cÑãÚ3Ô¬ŸÅV5ğ†¹4,Ëô’uäUÔ°_?¦ä–3ŒB¬pZ>Ü{\Ü<¢]ïàÀŠfË‹-S“Í°|ã’X‡€åNÇfâÜ”÷âÅû*nô|úbÛ4¦fÆUD]NóvA©Ï‰´½z)lN¶{McŒxsfÎMø…ëò­-¶ÅÑ5Œ­Yzôóï§z°i2ñŞ¤J%FıúSŒÍš¸Êùé˜æodxØ¡ü„+gcàú,^Ã´®^ÄÉòîåÜDºV\ï@|vbJ‰ÈÁ×yçÿu“1ë&xIY»ú¬è©‹ó¹nMÍië»àdjœ›w&¶N`—u³ÃC­2²PşpUÕeF]›Z"‡˜
ñ]©¦c¹@õ<{İ–ËÙtbÇ×ßÈùÃ4] æR£Ô!2O‹d¬
ÛÊ=P›pˆïIHAı”@k…³e‹ÑŒ€«ß¾ÓîŞô‹ıyÁ3¯Nm‡æ£÷Ã®ì„²ğpB÷-Pè1tœ{gÂÊu·ªúyy&Q¡Ë~€Ëäš1ğ
öY~úo)„/ÜÅ+6x‚,¯#ÚŸ;«~$¶Û'¹4q¢EÃ¼†Íø]«pe4ÿ±ªQãòqÂHÓ?ÎGĞˆ^ˆònÛó3ğVu~?Éö‘¾(°rÅÍô"fÕ¬<@oãI³1ëı­;=ÙÑ uıcM‰‡0”Î–‚5‡tôŸèûsÈ;°Ed:;Ñ$ï®ÉÁÃ8‹ÍÙÓŠù"€s'>¡çOğS>°ÑfûµóÃ·6ı0Ñ–¤Â¥<`#ª.uGs
‚5’!ÅTPZ!îuwF[,Zœª™%Ÿåº¨”`çvõaÎõ™¨w
Æ®ãŠ©pxÖüËFy3«:Â¬ìJÄe‘i2ÆE3š¶ŠÂ˜¥ ÏócCÛ´¹oj²Ïq=¸ïM ›Mµ‡¼ƒ¿ŸôêuÍzJû»+ş®6æ`vÀáŞĞî„¤õK³u6_Ñ¢ó‰Ü»Šè§(Pæ×á§o¿“ô­?_%ÆMÚ”ğısÆŠæWùÆšr°ïËÕöcÿ½5ÈÖå7~¯ìó²¹YËvnÑÈ+9ÿP^i=“KÆE§©=}g³Äóÿ™Ã(ì$J ·KÊAèp$¿ŠÖ>‡FñdXW6Z²]hh=CZfukÿ¶NflÜ³ô¸ÑâÑ¤ÉñFJoïX1‘ÆÅP¿_°©ôó!¾ÉU4¨>µ÷J^„a®§M˜©ì_ÕöO’•%’³/æ–óz˜ŠHÖM‹2õ6Šb†q8°­xkìI?Ÿ†Ñ3¬$à%©6¨˜¸iPµŠ_u^çzTÔXS9î3uF ¥àö²˜À÷Âáñµûä…¸§±_oMÍ`ÿo9]o;šAõd4ë'Ù´yª‡¡\Â½|ØFÇš )\ĞMƒ"Ê](€ôxüæèm”ƒí$¶ã3ttnÎ'Œ³<Ëì¯€çÀ’®Iz¼¤8•"a-én/âËM"¦i¬Ça·ËšÇ?<!¾ù¬™ušZ4Àùc%aöÏ¥_ˆÉ!ßBÒ.®kÑ¯›»ª7‚¿ş¨øs¤-âØjräp”Täğ“ÒPdøpD—.`ß\x&jàxmDùcV1¬3%¤_raóÔÑNbEeCj"Å¿2):µYQêhıuÇ@øLºÅå¶ÃPúùƒŒ›¨Õ ¨üÀ‹34 L—bœ^UÄÏıhº÷±PHløÃú5¤MÛæ-VBš}æ¸ÛDD3›9Rûv¥h,î“¦7£E±rĞJx€mÅ‚p†ƒ¸3#ÉÂÚ¬ÍÔ}°qìV^AWmPAFEßCrdè¢ò]>yğdç:‚šÑ)İ±ğÎsn­A½wtå­µh>ÄÍèOÎs%¬õÀ³´…ƒU~MÍ?>ÿMo¶MAüíÛ½“A“õÿæYûïŸÕlZ]¦(ÕòE±M:ş¬pà’]³1v¦ıĞÿ0}N–O´•Ò£:f†T tŸìm-ûG½[Nš6¬iÔ(£¬óóm?V§Ãíê9ïõyöÀ¼Spc$]jÿe‘k€‹+’F,?HïMàs)~:Fa/Œª7Eèš\M¡Å9f¹(Óc†y«‹,·#}*	.úÂÉêØ¯QO¾-;²?¨~Š¼]¥ÌŒX:`Ú½‹‘HJß¾Õˆ•HƒˆĞÅ€	ºğGS„26‰¤3Õ÷IhéCCßÁĞÌlÈávÅ£´G«äj x‰–ã›´œÉŒ©@Õ†Ò÷'÷¾™Z9Öşµğ çïÑrŒŠ!=6ácjL%¸NE>D)³EÎö0	Âïß;‹AìÍE.øk’f¨’Ô–—ü¾«zE²1¿Hï½òltÜ¡ dy–÷ù—İñŸ´„—m[~"*•]?j‚Ûº{¦uÙ‘é®{ÙÛN ¢)ï0F?9ÜÊ#£9ƒÒ±$îNÔG5LQ!¹RONÓ÷æ<Ú|œß¥ÃèU‘şReıyˆ^›9¦ôª^õAŞ<‰+üë1=q>Ü¼ı‰»ú]yÛ#/
÷¤ÅBÆ„òØ%¹‘‚tÙº 5“ğ2ù7hofåS/_öÛÑ,#³ûÕMHrZzRX0/›ŒöK,Ê2ÃlaÀÄc©Ào¿ÅÂ³šÆ©naªI´l°ïùÛ"uÃÒéB#ö­ä¢–ÒİYdB‡AÔ)ß>ıß‘ªæNö')ìmJ¡ı™UğVÏ¹ÚÉ²2ü»S(Ÿ=Ü)z9œ&Àú›ªäbÄ£¿Õã(ly¢Ã‹„ˆµ$Í w2ÇGhÂ½#›“»ñİïEXÎ}PĞ¤ó¥Ü)PÑ-QhDûhƒ8‘º>l‚÷IrµÚÊKXkğ‚=”û¾Ï=4ßé"ÆHa†ÌÂĞõæpùÛkŒ[L2wğ'cûóØ;ü‡øäÃ ‡Ï‡F_#|¸G\Ü¦^£ÿÿÛ“TòRVÇü&…ñzƒ#™’y,ìä•‚?·5$HòcZ¦Á9j®˜n_º¹dúíİ
EÂ½ùùæYÎ¬èê*§*âgMmz¼ÆªÜâïdÍ7º‰\X roJ[³˜·ãp'@¿^mka›ä°ƒ2
_‹µÚ±¾šU<€™m	K+Ëh0Ú|eD&TÓõW–ıØ@èGÀ.¿/€QzøµúKÎ†8$ØœÄ?¬€ôŞ	Ù/¹ÏØ¬\kaLÓÀíBâ”`’,=àuoøu.*Al6h0ç¿2àñøfD,\|&))Ğ=#ˆo®»qbYüÎ }µoŠÙEj­¡§¯ã$3ye|™…™ÅNÉõ²Hâ\<}1gË&¼3µ&W‰ÁFÎW§âƒ>àËÎÅ`æØ”9QBşŞüò2?¾´ü…ä4,b>ì•^[øÍ8RÜ5¢&¹¢ÎÔ'°,/š½Å8ÃBVÉ<”¾3K±÷ŸqK§/Ug_°>cò‰M^²|¤ÏÓQsP=[ÕÍ¬×';ZŒT;É&rµ$ö4+k}Ãñ(\š_RnÌ³\¾ è÷ß«<J
å ÜDjyVéËüšÇÏYL7ï©üĞv,$²ëy
¾1~ó}DJLâÆ‰·6©tâN=ÍÏ‚Ród™4ÔQÔnÄ+‰Şe¾{:-Íâ®°µN.TÌÜÂØï'ÔÊÈ~‹É»XÁ(»
/Rc‰†˜•şù)h`Ç¹=SDvX‰2‡öºë¢b¦htrØöË&t½C#'Qy¤» ßİ¨ÙDÄ:Ş ÉªåĞ²¡–Ñ-pü-•ªÔ	Ú¢’¡	|ÄÔİá0qÑ(FÙ6ı¡}
²3°Ô½fœÎÿúõ«v_şÛ!#e±¦ºÔŞ>8oêÃ>²vøëRİ½’Å ¥ÃßúJ~F¶%„'Ãaô…ù•jÔ¦ÊHü¬ëÙTIsâK9é±º	¬ªğA.Ô__¬“¤uR´ÆíT ï#‚•@FËgòÃ9Â-:¥Œ¬"F,<TDY±‰‡,}k„²i\	ƒ5}Ax,Ú7q9F~ŒhÍ84M7„cİ±Ÿ»×‹òÔ›ÍÚQm ãí¦:,Uµ+moãß$M^¢U+{Å&6­ĞìóP©äøÃ}dêwd‘å\–Ô6â*ZæÓıÎª¢=”ƒ’ÂDpÏ”dKb…¯‚BIlA/“@Oúi„$İ9L­àÊƒåã˜,HV™8%?Û ü~"íNÔ„jÀÊG,İê<ßA	Äş:hÏÌlêT7Eû©uVEŞqÜ:5*.'üQÀì«¦Y‚m—:aœÇ¥èÄ+Gm¿8MËô,k‡ïh'?Š!Ù^ÑûÊ³)°xÉjÍÌr.Æ›y‡öŠ6£·©,egp¤r3Îà]a”qšı„PŸ ;¯

»"ãW·q’ëaUêT¢ó?4ÌÀÁÓQƒBÎ_$O“o2ƒëf<½#ÚåkLW	÷„B691X§3k uÉ„ñ!“•^»È"¨¨€Ç¤ªXíJ&uVmÎ’ÔÒO£ç-·—ÜÿH¿NAt;şé.ywf–[3-‡Ô-{\ÙĞK»†#‘Fó„¿TÅ¨/ÿ÷tB”ô!à\™Tc›ş–"-ƒƒÖ¯ŸÊps1&¥ŞŒAÂQù~8œlêyLÚ bD¥h‡f/j:„½çc[òcf¼Jú¼ËåÄ–‚VXï‰Î…µÏÎ‹šõÿË“.‚Ï Ù%–ôÒ%îFÛöÄÇ
ÊÈ.ìˆü_”ë&ûñÌ/TFæj¨qHâ¹ê¶&I½@ÜÖ2òÔdcDÿÛ/ˆßuÒw2|ü†‡´/Ò„úJl~g$áXĞìßWÏÂf)gÂùÏa}¨·İ2Ö	e/µı$N…ùÛ¦˜¨vè5Í†uO ›%EnÿcĞc
x“.^‚3Õ_¡†’æd9­‡Ä¸ ¾”¼ÏŒÎÚfû¿†ûó6R$ÇÔ´}üzØ²÷íÙiùÃšúH…6Ya]v“hí7?\í¹.„jÆóÎı%Éuw$ø‰Be‚"ë†¢&Ìinìˆ‚…6ùÓ`¸¯Œ*Øpfú·›ì—?–ä÷Z¥Jª}†`‰@P{§jÊ-»ñ¿bÉ`-’Ai(Ånğ'ºEêœ¦¹Ëâ¥ÂûiÅMÅ59µ>b|°Ä_ğ¼ñÂÀÏY‡±5J=2ÿu¨ç˜íåÒ®ä1bE’ ¨¦}G]¢dFğ¿˜m'FÎ¢VÉ{àMÚLO»²mÒ)°
'|ıãu	¿®Eğo9“ªµ¤>~Š6ÀÿÈuš}Hz¯J‚ğ†¥ÊĞ[KŒ'§£–2sØãâÓÍãw<*­.ƒğÈ@âÉ?1Ur> 5©×1¥$f±3	E¼úPıªtruGxıÌı¹ ƒBô2Q%òÜ”ß±€”¾mà6¹ûx DÜPd¼ïõ“?ƒÌĞ3'¹Å?”E–A–zM:{ÍÅ¥{èºùüü¶¸P5ev<ë»¶ØeJxQ=[ÜV(.H!ı›¾ş7¿)Àˆ÷V;u¶¢”ó·œÉ.”‡³¸}…ÛŠ8j¸ºgÖ¡½9› 3ƒã?1HXÃNCÈç“¹×Ò¨—MÀÊhõTÅg¢Ã³Bbğ1fô5ÜegkÙP\«D¼îMksrÑ)|Á8dı>küXÊ±!,vôìüI.7ï´M¦ğ:Ã•Š&g9–m[¥|°’ ˆ,†úŞ…ìFOõ«ò%ÆXøiçÏì,C]|c]ñÿR&Şb‹…9$ÎêpßF¬±-j3ÖÈm%Ü|–)rë¯æ~#\¸Ã%NÇqaèe×¡‘â›»é›ö© ²à.Pı8§õMFD¬'Ë Å<Â\T€Ì _!R¨ÙÀ…î"ø7 LF%c±†ó7Cú¿œb†¤´‰åÓr6•¯–âfŠpÊ8t{ºo—ìßYÔxp~qlÊp°›&z&X{IÇÄ¬$…—1ÔŒOZ¹:/ & Ç–Àí,Eä›ç^„…ĞøJ_HÊäÑkáˆ¬Sî/`GB«Y?ëz8®%abŠU#{ü(ŒÆïJá:‚¢xğvÚ"ôî}Ì¡Ùş#b÷ÔqÉÔ†ßIìš…ÛºöûÄ]M^8 klSÃX°Èlğ0¶Tv™>»tÎ¾p«Ô /|€QğëC"Pºª¡:4&BÙfOOÄû)iO_Å£SA[ÖéÍb¹3È«´S?vÅßxúŒŞS¸tqÙãTÉö¾¾lxC+«00{wT—?sm5Ç2K(DãO6Õ}å»Ñ=D âON/!Ğ•Ÿ@#ê5æ¦¥R1&Ï—yC,H!ùÔ×Z°˜n^È¶û±À°R¸²uÂ]–ß_»j;Ië0¯‚Ê/@“ç·ñËªÓÈ]ÁŠó,V)m=ËêW%Q¡LÆ8Éã8èÙƒ³—Ÿ7¼@§"×Ù›O9msS]Dš@ñ©Âï7’Éyšğ±¾¶= ·¦-	ÈXV™´|áN`¼@–ÂÃ†É¬úEéI|´2Œ%Èö<ô—Ÿ”sƒ‡ùE>’h}éfDöo{ñËKi›•y5ôÀÿŸTV–A‹&s^¼¡$YbtäÿWº4ê„_ÒñóçH1®‚1*©a·Ü“An°Áqæ¿|É±EÍš"3óÎ·Zá²hú(ôo"ŸU«CñÚéãÚòªŸ÷çºh÷ 8ÑhgÚLçóßî¹³³)’qzvŒ²%¢´}•_Y¥ÿ\e)c¾ÿ‹‘\BTğoSdÓ7EÆêtÂ,\×’›‰˜gxâø²·-&¯æáEÑçy¼¯/J»I“«D—ù&oI)óíÔ˜VŸ© J÷ïf“â´	|*I<3©zÏMš¾ƒÈcì[ª*ÆI=<m¥şà‘=v5Yâcî²Ş®æÁ#ö1à5´øİé†ú§é&¼U&«îüç0ãƒ’åcaìÅáè5Š—"³ÕêŸg½Í2ù"¾b1Ÿ€½m¹Á~pÃˆáÓ•İ©-öE`KW¢İS‹Ir˜ì<‹3İ^Ü§1³ÄU?«ºÛÎ]\MâÊ^‘UA“ƒçEÊ.Ÿ|ó/¤â¦'ã#±Æ×Ôõ·Å÷ÆÄÁİH$“û_úI9T4”c{˜œ7 (°	¦¨Úâ²‹¾â`˜UÆÚ’”%#Ê+ÑŞEèº’„íê56ı²£^Ì IşØXÈ±©Mj<¹.-5¯ø²ĞR³Š‹ª¥(G18HâëÔ8À $Õ¿£}9\Ìë´Èé»‘ó"ğÜø}‹tÿE-äî[ÜĞÉŞÕL ñPóU¢WGÒîL7íP¥¢8…T,ğb(_1'£î0+™É³c…íkò"Â‹$AJT)WJ½~’¥v)Å“4´Ë4+F.{é¸â[	×‹{­Ï×ˆ*+WÂ?Ì;;lK‹L°Eúİlx­ªÈ!Ğ´ÎaúÚ¶EÆQûÊ|y…G´V%¹¡åm•Á ĞˆW4/JßK&"ß­y4Ñ•’•'t(/õÑ)+öï¨÷ê‡e„i_Ÿ÷—E(Ñ3ÍÈ”éVˆüÁ¼1Ç"rZœõöu1z†2æ]Là'û±ÍØ#[>ÈS¯&ì·$Z.™‹
w"êÂşmR%ì}e²ís%­«-ùaæ4bó«·Ù¹_3ìÖ*¶X[Z6ôKB‡d÷”ÚK9»KŸ\Hù³#¸ğ“#
sëœ»º «=›	ØÙK„#5‰Şü½L{`jÖ:Rs+è‘2%ºı—ôÀY´=bÙ(²8“ÿ¿VlÊÓƒÙÂa”®jŒÙŠÒ&f,HÙM0°Køú´òTP<Ó-Æç±›@¸X' ÈîuÖõf(‡„oÛÖøs¹ˆ°Zó&Ë=Òğ3·*Ù<Ïé0sœSÍVSP5úd§Í©ü®úğÑOAˆ%/ÙTV\…’Ã {ÚM¢©[ù¹[ ¥tÇÁÕ¼Ÿ9_^ŞÅ•Ò3l¶†KpVvÈö±e;1áN§–#7æÕœµp.¢:ıkE­O×Ÿ}¹†Fù_³=’—SæH¾6Ú¯‰=$©jîíâ¸Râ!rC­óI,ó¥(”JñhXı	é°İ•Yª‰Ÿ$+«üß’äŒ®³	"7Ó;ÖK¨ÏVØ7»ƒJ´\½f£…RUÒïæGZ¡9 S};Õïá^÷~U}ëXˆ}êÿğqºÖ|
¦C|xVÒU|¼0GŠ'¾ÍÌµ5‹Ø<ŠO¶N.İÈy.9í†r„•¶ô&†Ã·„"EKŠàÕoôQös´WjˆOŞZ
ÓT‰UÒ-‚dÿR^öIXùÅh>o^ÕŠ÷ÁW
m ıl^&rW—¤““†c‘’Ç±ÇˆÙ;8ÄêÿOõ1ã£bRb¼ç½ÿ‰\ŞŸø¦I
yEcX?Öydñ“;2ÛS~6úÈ<mŒ†-°-€ËğÜ@ 1ï h”J®Aúd™}·²Å	ïpî†îÊŞ‰İ›•¾MQEß3Â¡2‹ ÅäíÑŠ@<@j-^g¤Ô"ÃûG.¸Œ2AE½üW¡Ë”·— ÆzÚĞËàÀ›Ü–’D\½öîÀes¯OG£Î¿èe$MĞÎ.9ú§sePsÌ|q	ø>Bvú8ZÕû}«ãY¤î/vªÅ_c_‰¯9YõK¨X½Í¨ˆQ}HXÄ¼ŞŸY{eÆ¤ÒÇ‘è&c«š«¡ªOÍœC‰“5)3‹GÇøIÂp#Á:Æùµu$†Vo‚™;Z!…*r«ÉWsaÁ %3N½ÜóÔlÜ¸ÈÕ×Ş£öy}‰ÅX§ÙsoÔ¿ù}	R”ªİtÛ)Z t”€$-1œ€ïoa7¯Ñ<‘]“À"”nãË‰Ñ>i1ª#ËÁ¬ûus6Ÿé_¦°aÎ °wS’Ò(—yä3Ï&$0|{´^fÙ¸#‘4– ñ}Í:1€•Rß’BA[a!m-&ù	ßÜ¤ÒŞ6/üŞÆ›åYz ø×=oÆÔoÑœ°<Ó ¨­oœãÅÛ¯D_Í—{S•[§ïÓ|—ªI.óÓõåF\	-l­òÆƒîãİdH,í6ÖØò~Ó©® w%Hnc*ªø;I¿Ôîáp&"ÍzkÄ]b*2‚{MƒòSt”‘ ¼]j)õUŠÖÛ…XÚg!&{N…‚PêKAéì½ìO®Î‘ö/"K¬~°ÈækÚxHÛ—8ú§À1¸	¼ÕYz<^Ä Ğx®Ÿ‰€¬2ÙÒ~í~eíÂ¼?”(•/É×ÒôÄYÓâ‘ä`Ëó¯şÍ„–DOG4ï‘òèa}¨ıV¸`³ıUc'%¢şLÕÍ‡¨Öcrã.çZ¸`şäÄ¸¯”/µè
ÀÉ!0jÿŞŠ>ÕÉ¢ªÈ½ú¢+š$/ü'g’WYdJ§º¹·™Ì*ƒ<ö8b]ån|¡P®¤a¦òVÎüñöüshdŸE©ùéw%NèRNOÚU¢N¤-ÜyË¨Z­,PºÌl9w’šÚ5tŒíâWã¹ö	5NŸK¾û]Zoœø1]YV«q+ØbÈœ§²·¡¶¼
hæÿ!=-®«¦r‡á8êì’4ù°•:yˆù“ğ,‘f$NÆ1u«ÿŒ\3fK×w ¡*@Œ?îŸée•3JNEX¤tÏºuÛ/Ó«uõ¶ôòá¹r³B¤G‚ëÕ×º@?FS*·ÏbÁ3É—}‹ùMk ş^_®ŒœtOi­»•Š<®Îÿ;Çbïæ:ÒÄVùnÛLØ'§ïšxY´"¿´„È]öMv&övM=·æ
‡òI­h9B\Ô'¤'Ü?‚«Øs™ó™*’ª©#ì€[-¸v§ *0{÷iÛ±í +À;pqµ—¡t“¼õÚ·ô^HÖµ1~Û{Tãå/S[EljÙ?ÕÒ[»‘7Á*)Qã§óSC9´pP ãÇx¢¹MM¼¾ê:€*¥°ÆGE‹‰³[ìbhréÖ9Z“ehA¢EfÚNJ ÃPMÌËIb'“ÇáöAÛ™¡(£bïÛ;ß 	¹£!rï¶•IÿÆ1ïŠ lŠ|¾ÀAóªÚ ®:¡_¶²Şzy„ÒŞÔÑ«Ê®kì‚á¥#Ñ¦ßÎWÙõÇm”£úÜb[D4›„ó½8Ê\§P*ØØ6—8K××úºúÄ—‹n0Ë õQ–v·‰ Ä›¥>âBn´7?ô|+shşSí.ÊjÊ§Œ|tîM.ÒÍ`·İ8Z¨qÕ‹'ê	Õò„örfª+t-Î‰Wƒ±CsÑë@ş	(&S!Š¨rÜT—{EÜÆ”ï’î±ièn®ßŞ¬GQÏ0iô¨æÓÖÏ1WõL
HÍ§ÓLp	™bÍY6ãô´ªáv`9‰ÅÂRj58XMó4¥šrj¡Yí(ÿâ·c¶ÍÛ\^tãØ¼©#®s×kNwE¸lh« "‘Gku/O¿ÈLe0(Ù·ey¹r 5İÿ4zòµ†` îùqpTX¸¼àf6Åêv
DB­­¹æâ‰.‘”°œşù†ï£;* F›ÀäÃúÿÎÂV2¹†N¯Ã!Ä\ëÕ™oBÊæø¦2ïB‚{)Õ¨şÔ’;&­XÛÍı%ñ¿h¸ø™‚¸G;Î$ %Ò]Sãn—Œ²r'#ªM®vCøÿâØıFDı—·°7ùÎ*Ñb}$Ø#Îmx`•>ıˆ¤çfk"£[‘3‡ÂÄ ¹Ñœ^*Ã€¶„´»¨¬TlÚ#f¯NÃÊ0ÇêU†s3 ßÇ3Şº¶åb^€Ø—ŞéÎ"ñZ¦#3ÅÙ„í.¿gáQ£•·åZóû`Tuje’w˜`Æ€™ŠŒwÍYº®ßàåÎaº
!—&Šğ²éÊÃ]ë=Éì ìv‹gº¥
²)ï%MQôÇº(&“X­÷œäwÑA;Ù±{‡×cBÊºNnyvRzÏD¿ŒiDCÅşöM`ÄéÁ¾›©¬jP£ì¯úí */_±sh@®€wÔJ¿ÌW“ö úé¹ş{œÓğµğü“´!Êg¸Bc(¥Áíá1yEË@CÔäfz>³Äü¬¹VËf„sEosÒôp3…µVßuöİ™0çL‡!2vH?Hî]4²j`’aua¿ß&‡+%B	²3ĞCuV
“gçÁ}&zrá-Çº<Nè'3EìS9ëÓJ¨si¿É*âh€‹A‚fàZé=¤$ÈÅLœJ1O8y-¡Ú‡]™§^ëíŸö$«´êP°DEK@vş	ğmL'DÈ§hÚ“fÕIÔsƒ<¿„éŒ°È¢w wÌ¹­Õ#¦Íô,°}Î¶ç|¸vEÄÿIäz‘ÖÅ©£ê×ÎÀÇ98=ûiÌÏ>Ò‰	la1¥#áĞÑ¹Úº_.öé‘@(Ußs=şnÅ'yÓm‹‡ùs
õ§Œ]’x~‚6JÙ”^OxÀÔáÅMjÛ±=?h÷¶¼§ˆ– ÎN@'›\Á Zš¹f›Ó$ç°˜h}<ûÈÛ«b.bÛ…Ù xPÉÌû@W¡·ÿ¼|‘Jìc,Yìµ	¹0tåäPy9~Ÿ¸U¢*Y8wÅÙJs²£\îÂ™²•UzõåÅØ“Njó–	‰~¦¨J©,HlË¤—ÉJ‘òd†¤q#æˆèË_ÕÆrĞ6M,fLúî<&¥¶Ë²•³šØZqyË‘ÿÒ¬w¦€ß3ŒdAø·‹q»‘B-ZÊ«Ë;…*åivb²øA6¿µO²hûrq.xÉ£}ó™È·lHúpkº»¹4ÖkrLâàc¥èÈÛŞ„q’ôkµæ¤r…Z[^7¹B¥ö˜hÇv1¹ŒÚ¬ÎŞ^Ù™¨T?`éÈ>n}M_H!‚¹ï§^ªò[÷D•Óš”ûù˜¸ò¿IÎ-([)´[dB¼]sÅä"7TÙ‘ÉOÕ¶ˆuÿg_DÎµ¦Ó £/‰%Ãrû9–)a‰–àÛïä:+|óıcğÄ|‘T~4”®¯…yˆ Û.èWyåv½ÛBQ
-zÜ¼Ğ£[ód*•ÒÏVŸ–QcFëJïˆ€ªµ‰döÅ] lİ®	å6bş×­ôóH5İ°¼¥^|ca1aáæHWè=OÓ-—‡šazQ$($òáº9<4/ùÌˆ`JËÂ>¬f¥àº(#N¶­Lh[“õ‚Ï¬~Å@ya•ùY¸Ï„.Ë	¨õZ¥î¸i2c°$/] s`•‘XÇsÍ¦qW/0…ôögR–eº¾H« 
‚·´=ãÈf¿ «¬èŞl=ÏjRšĞE=²äMâøÍi“]`Òá²êú°{XD<>HÊ¥øÈ't“+ÇCBZ|Ú9’»N‹vÌµhÙ¨F¿j¼Êr¡l#•KaõáC³g6Q)˜üë‘²|9¦I w'Ú{5M¬zbé¢®€ôšùú5Qº@3€¥'â¹ÍaÈ™ÆG‰›âB@y¾<Ù[zæS¸U1¤æVØfMÍ`à4¤”ÆAY*¸é½äö®u–2ãËñM¡1P|e^NiÓ£pöU¤NÌCH¦6³`mD˜Â÷xB5¨4¿
Î\÷c2ıî·Ä©øï½7MªxæT_~Ëš‰4K¤&Mt¾;p¤KÊ§éºç¨á¹c9g:Ì^Á:ªşìêe&m"Å«M¥s0p¾I9ªÜÕâ¿55$ÄÉƒDVFµCi Vöª¶Àõ’i|ƒ¥n)c‘»ñv‚ÉG²fÛC"Í}ëI«^­T>†ë™auš¢öã€ˆïqÄƒã¢A#Ùk{ k[¤Ez[)ãsÍ£g]4Èº…FßÈÈ·ò6g‘ĞŒ
İ”½¹½hIƒÔƒìÖGÒ¼7HE·Ki§Fõd ’Ø8R­,jüA„äÀLögEJYT$Â=j
7Ñ& à¢SOô×O%ÕÊØfpïwSyÁØ€¦ÇN+õËá«üˆu
TyÁi®Ñ}Í …«ÖŒæâÀt¬÷1~´Ú™tÈŸE ]Ã4B%ÜŠ¿°ñ}¢®ç¸¥süALÇòg¹ µ»‚a™7&Ü¬Í\Hş6ƒt İÎ:›ƒÛ).Ã‚Öìï5GR"Àg4ù:FS]æ®e›pƒ>æõ€yhz¶G˜pô‡@ÊÒû|!ËŠ°ü¨&}¡"Ú^{jĞªöz#^½¯NÒùn.ZonÀn+ı:Û"66˜ûd•ÁÉƒ]7¥¤
°CŸbÚ:­z§?Ñuh.ğGÓÕb%/2’Pävuº$c9H‘œ¯É3¦¶„µª%ÌÀ|8ÖQÁå>DÕ,œå5oŠÆâÊ¨Î«9£”ÛYk´i[A3ZLÓI7]õE¹^˜)¾gºRo‡€4ú	âÀH“øLóS
ÎŞ8NÜ§Ó‡¤Û~‰.!ÀÎ‚Ğm]~P¿µT£5^ò şì’±Q}ÑR²Y2Tä8îDöIŸ©
Å…A¨xæ^¯û şÀEbZ™ÎÊğÒ_¼I‡1ñ)@•2Ïwµ¦°ªŠ0ØĞYÜA°À·!Kssæ%´Á©—ß«E\a®ğëÙlÓÃN–Ã`Ò‚­«®>öê·Ôlgßêà‰q•Zvå'r£a `R“2àGîÓĞĞ3íÀ"êäŸRæâT² eJ´'ÇIõ§m}eCß	hO|Va÷y¸ø(°¤µô[Rİ£WRõf)a«ÊÎáõõ%(ÔbbK¥×•/3ñL&êŠƒœsí†ô¦÷Ğ	b3é·NƒmñN§t‡Äı†ÓPîKØ>‡úhPË¡™­c7SáRÁ6 ñéÿÂ÷†6'3ÒF
cªmİ¾vsVœ½A• 9xÀ\ez\qKêØsW~&¼!¥ìJÓ´¯ş¦ÍJü¾œ£c \ùR‰»d=©ÒSÉ:ÿŠŠ&‹äcå‘¶¡æ6‚nÉì[Ş˜¿àmæSMâÚŞWŞQÏúLSPutp<PË
Z…ş”¿m¥;&5ùÆ|ÿ•-4ªÃrî<£.êX<¶íY§²¹)qâ]Ãp8ÖnN-›Òã)pye£;æÀˆ\óËXâÀÕ>np*ıs*s”}êô“ÇÕ´K pÈdz)\úL~özdÈäâ!ˆl™êİÓ½2¯Ö@wáéÆÓø|Ü½Ônº±_ñÚrTCzçòÁ7À`‹3Ğeô¤¤A`ÈC€ğ}á*G${·™NÜs	Â*†ÂtünC_œk ¥Ó0wÍUÍ”8ûd)^‚¤ôàj`w+v\³Q°4‹dVKÎ<âoª—wäúmÈÔÀf&,o½{†››œ…tå‚à`#j%wè–ê·i±šp#×Q&F'¥ª%EW~cDŒé+6CÕü°ØéıDŞ’:.cŠXºn¾~£c«4h#-@ÊnĞ|Ì½øf¨"[áÇ³8¢ÙtFË"m²WÂo/;ï›ö_İd—ÙÜ]5IÄO7¹-¢ƒpI åIÏ	¦5,ªF¸õøYõ­ëv‰^æ]âmÚ|¶^‡ÚIE×†v†ñ23@LÏêŠZ1=¦£ÛÆìT-ï‰;I¬EKp:}Àµ–vz¶â —c˜×Ş›ÆOç!d•4“<Ç:>*hÒG‰6ÛZ'xí*	J„1ój':ûXìÒ$_°N·MÁB¸C×5¸\yÍÉúw"T{/ŞĞ›¶t[{¥aRï‡Ü‰üîyãÅ]ZÔø»P‚sgw•åtİq÷oÚİ?LWøÍäÅ²„±N¦/út}5í©½Ï:%^gıãpö›Kû‘Ê³¿§ ëjúˆ¥Ş‡QFyÅÔuä¿Õ™7õo”ÔjS]§èrC/ÕXv‘ÖV‰¿‚·ª     ë2]°ßG‡ õ¢€ğì¨»(±Ägû    YZ