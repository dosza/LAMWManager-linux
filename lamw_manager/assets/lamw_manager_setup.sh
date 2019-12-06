#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3684676218"
MD5="027d70647aec465c569585093666cb4e"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20216"
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
	echo Uncompressed size: 136 KB
	echo Compression: xz
	echo Date of packaging: Fri Dec  6 18:06:46 -03 2019
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
	echo OLDUSIZE=136
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
	MS_Printf "About to extract 136 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 136; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (136 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáÿNµ] ¼}•ÀJFœÄÿ.»á_jg\`&¾äÍ¡ÙêjÛ†Û
7_0ji(‡Uõ/ûÉİë êÚ:ºÜz©,Ïê+§ô"j¨$’!j¶¿ùÇ$Å\Wˆ®²ng÷îåò.Vô¬Ùä Ş‰Ó.U
–¦SybG°>·‘ôı±¸´efU•õAÎÄVz®d§	Ôì©Ë.8øQ?Ø`åÙZ?v^‘§µT –,ÃóI$A	Jİ²3ÙPËKÿß˜äúÊb–Òu~7úş±Y’ÜPXô$2,=»@(*Ù•2±4ãW¥¦¸“G_ì`.-L -§1<wÃZó[ÿ² ªºÖÅ’î-FÅÈEÎrÓ£5êßÈgCóª|›Bblò…Ò†éaÍ$KXŸ%"q–‹TÁorÇWÙÃÙ9ÿåÌµ fsé>EÊ±×w¥áxøB+÷Ù Zkg¨ŸæñE™äh²‹¹ÍŸiærw
N·‚|qf–dØ=Å|Æf[["â]›”v ª™F-ĞÌ ½‚úòçw[ÖxaJcWÜvæ‰ı¨ô!¹*“»ğİ8vƒ[X?P>V#ËS~/ÚpTşª*Ğı"¡®·€2ç¼#¢Óà3‚2óc»Ë]İ¾NtkFI®’Š^áQä}á"j4Ìhê­Ú@]º–ågf:Ü¿—¼‡J7¿µ{gLåàsı-0ª¶kÿëdÀ1÷øZÂ>>ƒÚ¥’¶GCØîËÇ‚°×X¡U6¶Mv„ùHµø›^¸ÍÍıö,¯‡şÓ~ó$c„º£p;€‹:\öSCşÉ8];
Ht3iš1gYªØ°„H”8K«r™±h³L˜¢o„‰Í´¢fÏı ‡}âTi»­–ĞXO¹
>u¹/ü¡ÄÕ îˆ#êBƒ(şˆ•+Ü² í5M”Ø"_öô+ZæßÍAËzÃ^ˆ:FL)“Ş-Öğx²¤›3i‡—ÇŸ#áŠ—‘3uê(Í7}ø¥i>Õğ‰¡.º´—¤G*@´Íã°æ/š,ò`éÊ™)ÍPomà/Ì‚ğÒ¨“?‰Ÿrö—)¯œÊ}“[àÀ“;Ã5Tæí¨e^ŒˆtÜyÈG;Æ\§2é!ÎY›³rx´~:ş6£-G¶Vå?StF\³L”Ü;qÜ¿ŠPBêj¹ª:CZùŠ Jœ@»" Õ¨œUE¤˜+UÜÖÀ»üÔCéé–ß®TkZÍŸ%,x‡MŠ@ÂæøGèAâ¤;N/óø;lxˆ+D¥¡§<c“‰¢XYŸX|zÌêÄÈ0ËÆ+úpö´yBj—.¹ô£ºuÿ4	´”ô£kËı¾HüÒf]r Pâ‘IÚ’è„­oZ³ògŞÇæq1B–²ÁúI²S"ï™¬Ï?c¥ÅaÆhZ=†Qó©5™øSÆ_Tîñˆ…BÚÊ[x) YŒšQ)xÌtjYâWÊ‘“æ#ï•ƒÙŞÜyRv¢BQºm±·=#JkúØ ­Â=Ñ–_ç•¾ÙHÃÎÎşï\ï©(ú&°ğRÅM:Ù;ªYû^ÁvŠô˜{-E«@Eöm‘h¢)±ömxüsµîİiÃ×£¦˜ğ¯æ:üô?«80‘–^:·\n›[EŠ/ˆè8îÄ,…1¤ğwc¢ƒûÍxËKo¿—KÖÑâieåqiŠ;ËºÌkxC®ŒŸ¯ÓÍì'04#®ÊW’·‚R™Æ% a*˜Šf3(»Ïesò
‘}´%7l~Šf¾˜f5X9nTø È›Q)¸ûàñÈK—Í“à¼÷¨Şjçå±é6F‡§ÕffäÑE<ä¨½§'sÙÓÇ_OHm§2k9À2

Ó8yi’0’$C!§™'Şn]%†AãKÎıqÿ;vœe¯”q»[.ARJa¯yãpÎ{.”™L€FÇuÔ^ÆŠHí/üP85(8¥åì¯»”
 ì.«ü—3.µÜÉ­ÀÎ{L(A|„Ñ†Ä“^<9U –Ù“u®@œ­š®®9½â˜k‰Ò”˜û£½°3‘¸Å~N|_W[,5?ğòL  q½ƒĞx6M¢ğˆÈäY\S»À&lSyWHgRæ:ù0ºğû q}•Šeİá0Û ¥‡ÕÊ¦	
oV£$é,(ºŒĞÛú€ó’s`2Ü‘á8Ê‰Ï$õ‘)Á´Ø"î®÷×`îg, Å²Y>_¾‹UÒqô˜2ÑV5•4y
C5~õ’Ï+$/òùæ_pF¬ƒJ¥k:Ötmğ2>…fÏîT^Q~f¶=”qÖ–¸GË¸J›>€‡nV¸š#•ŒÌ¡R1u®ñß×VŠ0÷ÑHŸäº¿./î÷¤kØ‰‹w?Èl1,õËÿ€´Öı³:Ù òÀ6˜WäÛ.#!a_n¡ğZºÜÅÜ·9^:¨! Ã•Î|e-ØŸhC0¯:ìA÷Ã9Jm®9	e=2+ÑtjaÑ¢aŒòBdD¢Q3?mßQšƒÚ¶ÇF\\¾ ó|€o…&]ö„ş VwÇx$Ïkeş=/ŸñåE˜Fü°µã¼öCÖQy
qÉ‚ÉÛ~#I¬ë	É³³Kù"¹½àV7k „<• ÀPáÑÌ_ qc›~İŠÍyôN
>íú%›è2ğ0k†¾m÷ZáF«a!Ù0	!hvĞØ´0Ä£Ú#‹)ıS:Ş©“Aï‚0o§,(2>ÕÕ|û¸ßô¬æò­ÔbÑQ-Áª(ó9Fš²€ƒIÂïs£}Dì	ø4¥7ìÒi©À…û340*Á=Y:ã$î0)í$œäyÒãÉ²@Ã
 h;İÄ?Ñ‹¥4±î\ ¦wÅ[İ²H¾î¡ş(†ü˜aN<ˆgoMcnšáA´e{İh¢„|ì+‚s!s?«V¾¬ÆC&÷Ÿ’+<ô¿Ø×u™“E—ÕjÎ‘q=oL¾×6ƒiVÂÎ—x[&ò:ü…e<íÃ>Dğ¯|1[DµFáš¨ÙnÂ`À	;põë¬)ªmH]L•Ú"—ø"¦.¨ğŠîËŞÒ
&ñë~Ò_G™šÄ’id£Â­UÿäËL»–ónÏiæTÆZ:e¾†y-Næ–4P¦Òã¹XF¿‡÷Mí€ÃAa Şx [®ÑW'jºÕ³Éºœ‰ñÔä\è¡ÃeWğT†¨«-x±TÜˆør¸ëEqjÏa	ó‡Ü³Èõ†¯4É‡!ÒşÑõRcJG(á† ı¾¢Ÿ‹Mˆÿ6CxØÇ·‹@—_;'ò\0Ø§;¹Ë¸z8ÂÑ2G¡¶9Í·’¸N­p!—5¬å&ùû‹`X½Šnõï¼š#¸A©"¸/0G¬8ÀåÊ–rîü>¿(T µí×—“5§–ªcÖ³šåĞÇc-Ûßëb9œÚ†$Şq~>©}‚ İÄ¤İ.~ï²Ò´« äáµÙƒµ›àE{±(s'½ñe‹%¦'«­d¢¾lêñÙFn\ÍróìÅ&÷Òt÷Îl¢¸Ğ|*ÊZµqƒš~*hU¸vÌP´¨¨J+íü ¼%0«¬¸G>£ÉNÖRã1?C-’¯s!Ÿ´¿kkwõô«E‰¦Ã!E ùÎHL¼6Êì1÷YjĞ»ÂŒé÷÷W˜{ù `€(+Å×Q0ƒÍiÛRÔÍŞeyˆ KXgŒ†îÿõ‚ÚOï!éÈ…ÉÂ5« MÖéÑÀaê¸œSwêj¶†°]v§ïÉº_yß®íÉ×=0\Õ¿»i·
l~;§Æ vrñşã›ìVt‘‘!·¾§¨½‘1™úíğHHúQn»‘G¾%|{fÔ/	tÅ**S’«mfò·œÿìÇa3Ø¼pNÑi×†fyŞûrV@ÚÿÑ$ÚéÕg¿şš‚gzZÌ•ª,…€`>ñ«ó24÷!ÓY¤1à=ÃvŠc Fš6ÑH9cª—ÁÛ!E¯JÌB´ŠAåÎò +*y<.ôé‰C
y++|1–hrë¯¶ô€ş.)|Ô$ğÁ×ôÑƒÈİd^§5Mo¿!»3ü'Ø9±Ëz?}¸D;gífxJò¥¬¨Ç™ND_ç0AûÜ-ÈÍ™Gl"íjjgƒh‚YŸ—´Vrt´ÑÎØÙ„#‡x›ÒT¦5F@+zíÜlZ\O¤şCfS|üyY®‘ü[‹Y=À(Îà–ï3Í‰ì½ıoÖŒìş¯¬?·&}X\sívA#c9ì4Òâ{L<÷Ğñ‰ó/O[c4ŠÆ²¨yà08T™Îû¢uSù^`ÕİÒ-µ<¨Qø†#OÎpÑ3>Y;T`Z×n:—BcïÃ„ì6ª”S.h_JUuŸMïÙÿ„FX\‹¹ÀÀeñş\^ÿrm! TbW!ûQ´8OÙoŸÇ¾0kÒ›c	4ºe±I“Aä¹ó+]”$l_ŞcÃVË>Tášx|5—üãêµüµÕi|æehš–(y±ÇŠËÄJZä÷N´æ³µ¢‰¼q¥dLbLÏ[Ãb_"r3Z¬‰¦ÇV“›#ÄËrr´™wIpW7ŒŒà·gœør¼N?Ñ®j¡†ƒ%÷J]z–±%äÏ
1I©á”_ÍßÔÔ²Ï.¼:ÈğÃ¹?ÜÛëïõaY­aş{şj—Iò¾§©´-³HEû˜#“n»IÔW7™P»<ôœCD ²ÏNB3ßƒ¦ S~w—¢Ù-Dà«ŠnÖ$AËå*ü¼‹Şò˜³Êl
İ®ğ‚ÑHròbûG“Æÿ¶›WŒÖÁÀú\Aïr“’‡±ß¢}º­ETKÅäYXA®èEp=X0`YµÇ£½wi{$ge¹!Gş@¾pz£bÚs 9+lá‡Onœ|¼¹´şŒK²¬³ğØ·bpßæjéHínõjE‹¼D­Ïw<LúÀ‹Ş±Zkš£üá‘½+ŠAB †Hè´âE1&ñaèÊÛBûÅÊ†şß˜‘ªDîI"T}ê×€™Å<¡ì¸ÁOézdHÏ¸ğg^ÍÈ›Ã¥æ¶	yaúÆ%òò—ÄÑ¡O1uYˆ›–£=¹ ñ×øöó¬d›–4¼F¼¥}ş˜“ç²Ê/Ã2×+,]¸õL76Û3@øEÈ|bëa¤\M½5
ÕÃ÷q˜^¦4$,l7fX-ÖøT‚¤„!İ;/Ö-Æ&x—–4Á§¹õ×/xÀ/Q©¶†r®Ú=':üënæáT£Îq´rcxK{°lfƒ\ßpy6½²'šìJı7@uv‚.Í+|+u$F¶ÿJ™[R<áÃ%ÎÕ$QÙé£Ëcı½pº×£MÆ|ôQõe'ÑŠeú0Ä~ v¯6]Yhˆq7È°‹èâ—&ú‡q2 õ  ¢•TÍtéf+×..ÑwÑ¬HPd	 ©Ì“ê¼­«'ÆÎÎ®Ü\‡°è›ÈğŒ¥Ê2ìèt±¹",5`HXRmñZß=ÓÈ^ €ˆŞ£9øÔ	¶ŞD…dİx"›ØÒP£€eµ?Ğ/–#Í¢ªe…àO´TPÂ¥ÙQ6n
:ñ	]Êxû#1µÈÿRìvøY¸‹w\?º(éäÉÓ›¼ØÖ¾L«ı:Œ¼quÈ›1ú¼uıXø­ÿ¢Ò¨‚şÙr}¢UòƒÅfysİlqCI¬II-FáĞYB–wÙõelÍóñû=÷2;û×‚wözñÌbÿ’hü·U›7\o b…Eò´H{½`ØÙ®õ={ìy7“À¾ºˆº$|@/Ñªi»pÜ=ú2¹ïô`Y¥À³YR¿6æzım©öîµpÛ3@k¸UË¾îPÉNF±4ıı#Ğ..6³÷õñÑ“vo¨“Cí¸ÿ
ùËØÈ.~ V8®Iœ¤}$¤—2Da#’Ë2ù`ºCF+K*æ{ÕzÜ8]m­‚3M³ pº«Õfˆ²ê÷G¨sj¹İÆQ86•Ÿ¼aØÉˆäÍÀ„z÷N8¸(­Gï¤cò#©Qñ¦ì‰¥Ë+@Hù–ŞÖö0èÜ¹Æ%øÅwnõÚ‰lÁ Õè{ĞqˆÜ~·d+X7Í¯o4ÚV¤ÆWöeÂG¿;ğÒZq¹y¤•³ğ»à3zµ-'’‰Üdm2„º:•C˜‚IBIí6k‰¹ãÊÔÜØ‡€K™b wgàæ«?P!0+MÉ¤]ŞbóûQ*(•Æ«¯À­ó!×­>ßÚQØ@úé€‹¿Àç¯Å}Rg¾¼ûy$R¦A¥¯³sz©¡¿,¶Ï¼?B²1µ?$´èVÛ:Èæù)®z«Ğ]T„TJ6ö†´0æfı^=‡Ñô6åû(.¹{V¥âÿ	´œíY²™ïòõ—ogNÓæbå#@!xôŠä£‚JVêUÔÃ{Êï+õ°l¨¼ŸDB»óãpáÔÚò»ÜªDÂ}Æu ¬÷ÒğÔ'4Ñ®Ã[ºê•K«ˆıªèÊ÷kû8[I²òçM^„Í@ÒÔ[ùqÊÂaÃX»pƒª%Ìº¡À…N?Qyx>Æo¦·½„õçyr¢ÆJs­Íi\Ø.æ­’‹ùİ±ş8‡zgÙ~ùFÄ“ËõŞCÀwT$6Ò½¬îÇß­üJäWÙˆ(SoMNPÛ´kPGoãké×f-õÈ¬m±ÿrXûUN“òÁ¯O!ƒ`ºñ–~x¼Ãq‹Õå-¶Ty[g¨¹z¬˜j ,Õ=ì
vk¯¯Hş+¦ji ãÈT*4¤­S r‚¾ÊKçB[§ì,8ÕBš•Í˜_dÈ4Û·óÁï©r,×Bv‹ëËÇßs]™àŸÌ.Q°W§Ïwc›Aôô3Q¯+-UµVwˆ<)ùF¤<…šùç¿EšÜ®Ä…Ê…qEC¤»­_Ñ¡6	ãÔ ©ãm.JtY80Ó€”qÙ¯œH9**ÒeŸ.…å¥¶¿‡mê—Ô½…^"êİÏêWG…ÛgÆWÂHq:µ“ §äÃ®øÏÙxÏµ¾Şí¸IgrqÄeóôÜD5z,ÀÑ%
djóDÚÃÌC‘¢¡òBë
•‚È7–~uZõï“í-•û‘	êP‹äó¥-¤ƒÇ§ÉŠöƒ]`a¨|ĞÃƒaH´Êá{«»o|c	V¥ª»ã˜äú9È¼.¾2iñÙ û¬¼ú€ZÍµ´ìÒ.!ãêJà–=|•/1xƒÀPVã<I‰1ëƒ‡âä\â““SnìK'úCÍ2?Q¾™ÔÍ¢®íÑ\7ôÏÄ€³.°ù“WKæ³KşÓ¦ä>ÄÎ»TÄH]Š‰N5D#{Tª`ÈM¹l0–bl»?ÜŸp1q!dq¤Yåt$ï£(ï+$˜¢ˆæ>L+@ÜÚÆ/ó@ Äµc³Ÿ—½æ7PÁ'‹SlsÌè¹*}ävº#$y³­SyéÅó2l>ÚµM¤Áà}IM*úäJJP®XÀWÕ&*›Á4+Á'ŸÆ…ëÊô®9
}‘^êÿÃ¾¼+û?®÷c¸ûEKP_qY^œc›¢ƒ#Üw†PƒÇqI0Ë¢X«PÇÖg=2ï‚7nªJ.à (ïŸòßÔ%Ÿ-¢Rç:˜o*>~Ï\ú-l{ï•±z*SHh/ TêNbáä.QùXŞÖş÷ZÓ;– ^:Ù_H€b)+ƒşW\ƒ#u»åâÆ_aÙÕò›E‹-l]€Ç9°V,.L¾ë§N;Ë(dºEŞ/|,s·şc¯9“˜``pBuq`%¾ö,ê
Â™Íş1¹Òı9½ª³,‘­¹ÎqSf¿c*°-Ã«ğ~Ò†_šƒ¤ôç¼A$¬­Â:ë½gdRÙm;ópïy"êŸí£<r¬@U6ïË³‡g#Zmydş@…y½ì‚­ïŠÂÉg`ùÂ Fp~OÎYgñJ®ÿ‰ŸkYùYÔF3È´Ş‹‰jòpŠ“Ë1jzNXqs"cÁñ^œaHg+[“™ Óoîã:.cKnUVÂãAåÃA¾!­š‹-¶a×+©æa±™ªè{]rPS…ÙhWvÉnRl6~4"ı>rtÃù¦¢¯âwêÚ§?#W²–V‚÷sËäÊ‰f3ŞZ¶å¹Ï¶!è¡ú¦àérŠ9@È~ú¼HEîK‹gfSÿRp@p½EkeÜŞŸòFrlªèºà?ïÏó|uJ–¨)µaõ$0Q| °_vj°ºêYûLf$Ô
&TÓéÌ7,VÓ–4”ÚüÃåŠ’P€H´ÚUù½2Òïv9e»ı{âG.ê«é91”Õf$yğ'2d,¶›ènyäRÍ¶¿ÈcM¾QÃEí™ˆ¿ÚôŠ-{5?.2Ôvûq?îögô<éŸ“-¨{ö…ñ<:1ò±9¦,‡Dn"c©38&crªèiÎÈˆ¬Ë7Åp†Ù&“¶^’ò…(æ ‡	Ã…ÛŞo¿Ÿ,MæıI¶Üq(ÿd¶…VU}é¤§ . ü³ƒ<«ò6ñÊM£ÌKóÉ× ÜğæëÍ®YšX¸•Ãö¿ìàAÑ±¶ò¨„à7ánÁ~ Z¬u	Úë­v´–Õ*D©È¸ö ÄÕtv~ ûˆƒ—È
İ‚ú¸¦œ H·«£&Ö€„WáÖğ_íZÿ}7‘GlTÂÀâêåéŠStò«ˆŠ#é«ŞæfT¿‡»øÚW¬p[î$·ËU;ñÄİ ]ÕzÈá™ á½¥rÇ.IJè´`NhËNöÖJœw@¬ì4š§Ï™=Ò¥9XÎĞ> Êº‘àHHÕc,äÇÕ`_ÁCUÈ?;.•±Ùÿ kùë™ï4¹?
CPÓ{Ñ™"©êvá=…?ˆ˜‹ ¶§{‘I‰Osè»mXEqK’&ZmhŸù–I°Ä§éµyG7™ş¿)o.–ŠGšüÓc²;Î\ô§M=såYï†7¦ù3VŞ'˜=–Ò¨Ãn!B×>ò]¹dkOhöÕúÿó×g`äßµ¼Q<"tÄˆZRâ2‹©„i¶µÿ/°‹ÑÜ·Öäéô$GÉ Å¥§j¨àò"è{ôNj-rÕN$dw"ÚÊåÓ‡uÖ€o|	HPdÜçL!^ïm°`xDÏ‹ÃŒ†VÃv*7ózVß<S °ø\cŸ}á#Œå4w"ˆ‹²D¸€5k¶p5Ç9²ozğ¬£=NFvP :üày†PÔP|¾h|L$Í	d»ŞÈ)ã½~K5Ïz¥—á3?/çO£+7Òr8#¢öä#3p	Zv÷ğıúì,%µ¡eÌ ”x<œåëÎ$ñ
 ]ÚXn(»ÇğñŸéXk¤æ ÄR‡~*SE¬8­°.dy¦^yâXì­¡z¯Xïç-‚ûüà·7¼e°{_©>İû Ü³Ë|öB`çâ›±¶|Š{3Ğ¾¤ûCòFcÆ¥â¡lÁh¼ê‚ÉÌX*6ú¥kÛèær9dPWO…áõADZÀK¬G>KÃôIœtÆÃ²¢¬>ªĞ„´]¢Ù/õÍo¢Dq2œ˜Ê·ö®6‘ùqãrsÆlœ¦,N„?»5µtÇ‰"Óì[OÀE}ˆî’¬*Neî}¾Ù`@ˆyØ‘×NõKÚy™£Eht’zû)\X%‚/Z~8µ;Ä„–ıí–7ûŠå"e.—…-P¼ì†õw»ƒ7“oãÆìpŒğïgÛ=HQË¦ğNƒÑ/İ:boUşÀE.ñ°WR/xåä™/ğxmX¢16î\Cjkdü·vq™>à–ƒ*–z‘©õ<ùªØë²k]'½ÿÁCÌŞA[.²ZDƒìˆ¬Ğó?£’£[íüĞÕiãuuğˆTÓ´şª³Õ)ºÉƒĞŒ6{Hy(}PÄˆôl>4fÃë¿(Óıy,Bj@$•ÓG‚BÁÏ|ëo£Œ~ÆrL÷>Î¨Øa9é‡&¼srfUáÓ®X¡ó§s"ö¬EÉ—IN}jh6œéòÏ4Îóıİ’P#-–'ÈjH!ªTt_'ŠË)HÖÊ[…t'ÌìÉ[5Hçõ˜`X’ß1µ§êÖ@6âi/
yœÑ›ìôr_¯‰I‡iğüß`Í™~’*ÔŠ¦	\o&¢)Ëæ²­S<„ÄÇu ş[epÁˆlTƒ¢ÎJQ[mÂ¹9õë.Ye|ë¸m/$·¦ÆNJ¹’y{ ‹ùv“²¶wL­Şn5ˆêĞeWéX[Ê¼bG˜…ìÏZV)5D0ÏÙË{£ûÔfÅßÔ5qXxĞdÕè5Šëñz)‰ø.TVšödLÅ“ĞÚ“ü~˜Á§¶Ïî¹ÿËtªıIOÉÚyÏÏI^†2X1nÃ6:'©8<a™‚\@&}/%EÆn.g>¤êV×å “¬ƒ‹÷G'4¥GÒ	 =‹xşˆ)h¥nİ=Äxç¼g¥”÷&Z”k3U6“Ø¾±ò$”@ëwı§ŒN·,{QÁ9ÁñW„´™˜p2kAÁt€Şhî(0r\W™y€|Ô‚†z”Ë%øÿµP¼U=KNoá‘™«Wiéd¼S’k?ÏóÓ
bÁjÍ’±%ó®†,tÇP úïæ1	'V"Üp­ï€7Ír¦éIşòe‚Ê®şõ4¿
ø,{«ó¤+”…yQrÅhñ´«ú2Ù‚R"¿NeİÏ›<©÷£ÅzÂqìèÉiÛÑ<ÃûG'ê|-Í¤«7‡LòFBşS‹êVÂ7¯¢¦oAÆFÄ>rÒdÉp#wRbë1"–J¡K1Æ›.Ù -¢ø—§Ä‰%b>»gW”ƒ
-úéuü ›³‹×rÎI
)ÈÎÕÏ„»œhRH g-›«k‘[W‰—„_Ôµ²45jDo0°ñÇC%œo3<â¬ı'´…„İª“âË^‹À7V)* ¥‰°Bı	ÌÅtªÈ Œ½5§è´=nÓ7%Æ‹×
d*–Ñ§õZ°ğºthí[-õ”–Í(÷0OSÁÇ% 	¦)¹ÁJ~Š9Ë†%
˜-É™Ó=„Ñ&ëéYKû›v¶¿xƒ„ª mgbÆ¼Ù»*{&m}m«/'A³ä	Ãƒô¦Fø,çŸ–Ùú6:ú»©åYoŠBLìt»=`i©®şOÄXJ_5àt•ÁDQùs¾½WôŞ6V„U‹˜„óF/zÖ{?<î.É®ã,$ç}å•3bC®Áy‰ù/S¸Ïµcøkreé@ª£<ÍdİrH®Æ¼h/Í>çüÔÄÍÉ;·Ú–šRú‹¸*¶¼¼…Œ›õ#M dÉy2«K÷¤èãÆ»×ï&GqYÓ,P×5+æhûƒÊ<ì}Á6H,´8$´
z}5;(¾èœ4|Å¶˜‚å—#ù‹ÿ¶SÍSâ;	æ¹Ç©S?ı€Dà¾x:å<é©ß>iª“ËS	ÅmIàµ–@ßÖ³‡gh\Õèˆ‚	œsşr™\<Úö”éZ«¶pc/öğÀ^ù«Õi‹2ëPÙä9F‘Ñ—±-‘#$8½İ#©	y5ö16ß¸ÌÍ™pqŒc&»‰1[çÅ¢h…ö•Äo§És“Ô…²°—Èû×’59zOƒOGzÓyyÒÔpœ—±öiÍ®Şz`º
¥æ–oôü’Y~ƒÆ­óz××|ñ«n5@£]9Ñ«“”hØ_@KÕ vh£Mrö_ïæ¿Çº:ğ„§ #Ò§¾‡äˆ¿9½¼	äÄT;zƒŒƒ,áı½}3¤=èŠyJ]¦Åª¸ÉÉ'`ãÜ +Øä±Ç>¿a.èz‘«Ú¡ºë±`É¬¨öle
J/zõb$2Nà‚tÍd^:P6Ágæ¥É•?ƒş¢·Ãn±ú…“NtósI»PÃkqĞùíÕBdw_Ë&©xW±·20¡Y…²gì`MÙtŒ­ìİ£ 8°.¯¼÷édÛô]’÷&ã_Å&ZÆ™sı
¯=×cûw*İD¥Î©¡—¿	D“ÕeüPÊ±vû®ë³áV*>ß.¯Øæz(5š©¹q·Qá w˜‰Ò¡Ûj“Å@½¹éRÁvÎĞ¬^Ì´<ó…Å$‚5Ë|Ùdíöà@UfĞ2‹‹Xƒ/"¥5®Ğ§DDœ#S¿É[÷l<,°TÛ{öçFGñAÁ°Í½õÑÔ©~#Vë?j7•<âË½ˆ}:
m â¨¯¸Âİ…*UÆı¢|ß“9_1&È«ÃŒÑ`ãÉıá5ÊÒK„9á§˜Yâ¾KËòÃZ7§Ê`æ_>ÁÑtB[‡¸X€ŸŸ;ëìô wAÒ*,Ôœ¦.€şŞ¬»bÅàVô#&)Ãôæ˜¤}PgMÉ¨™òZnƒ·Õ[nkšïšsCU£Ñ€µY1J’QR¼”V;­OÃ€q½ef³Æs·i(„ï•‡ãÿoÏ7 ú¢'¼¦ûÆñZ­L`2¯t~¡»µ¾“­°á'²§¸_ë­j¿Æıp [{A’ã S&/dB¨æÏû0ØŠ…ÀÁv£·9¦æBëX¼ø1vÎşÏz¿Fm¬ãæâdoIY†[LÚ~e$	àËÈß8ş72v’Fİ«¬7 ;Ë/§E0ûâHºlaŞÆ²cIíŸëè!yúJ°wØ_EfMÛT¶Ÿa{ü£¥Ö¼OEå$P“ı¼œ6àÓÜwäWN•¼BÔæ“”»IÖ~?ØêÈêI&·Èœ·AkÅıÚŒqï>¹ïq¬—åGÚ2=m²YĞLé„äœå%¨”R?éU;íóáDiÕK‚GFÒ&µÃ{Ü ‹lëëì‹?³8éo¶m­(†ÇM÷…çøy¡¢§¾nˆ•üX''Î­´…¹‰3pÎNË8†õ-…Â' á}ÂTõüu5
Osh~ô©$«ª%EËî	96g°DÉ‚ï@Tğ7D:G ˜uI\ó_l÷F^ğ†üÒREÔÍF»1j`´˜ïÆÄ…Ú ü^_¦n5é1Øc@²ZÿòÎÇI
kFÓS­rSã®:pÿI»R3¼^~°§=ÉY>Òy®)»bET¡ÔæIFş|‘Á–@TÓ£‰Úás¸µÎÛ_ŠÊ>Ğ5ãÏ-­™Ø5ô¶¡$¹5e¡OÿlßÑwWìœxN"A0øÂW–»yöcİ’¬UVï-‰‹ÒŠE=pÄFõ2ÿšÈäo+ªµY¬È´Ÿ£Y*0ëÏVnNİ¸q
'´ª1°‚W3DÙ»r¼èËÃv bq´ù†ü[ììt^{<ú««­¢ã ŞÛiVÎç•ØÃ»{FQ™~Fñº+T“ë	š¨q«S#`õÁá¶ë2½©/ª¤¬¥¡ïíFS7£@ƒ=oD×Ü´„q&3ğ5lü˜­62-ŸIÜ. G…±k[¯¶L‘+j'¯­ËµÒ5Y†A‰Ì²]¤Yâ‹ÌBÕ"~Èoú$^©»n,TäÓ\-…Šã}­¦¾®;äQXë©ÆYÇLïkzÂ@7÷`¶š‘$’Í=)Ó…{X]'ã K¥Şiå#+G£´ëe¥ÁË—5váaã¥+8ƒ¬¯×{(ùzÑÛÿUÀTíÇl×‘ˆ8?”Ş9õäw„=%İ”eô4d­ºÜü[ãE¨ÉŠ`Ûv±:1]øcÔTM–ø¡€üôşUŒ>ÊÊO³/À¼bœ½œ™4÷\ñ¬¢ô:d$¤·µ™¸MÆøBèˆp©‰%ÄhS|­ZŞ€{é à{¯§Öp7"ô£ûÿ—ÜLÿ_£‚Ör±"aüû2-aÙÊŒ/Å ÀÓ}%^I‘% qª)ÆQÕ+i³Nö©Cyƒü¢íÁQí—±ÂiıC}Ró/:ÅÌoË¶WÕõ÷|ZaÇØÅ{ÕF|1¼F!Mà¦¥áÀaeè§=Üê?ÒİÉ/m 8.ô˜>ú„¸×¤ÜµJ¢x	ğúiÔHgIa7OçqÔt•HSê#PıÑÜu>zq§~°é­E•¥
eEW—ñó¿à^6¦¸ÜöÇ6ØVomôÚ‹º„c+©˜L¹© 	Š;&½ı w”ÎáGåHİ0£ÏQ”¾^Ü„ëat²ıD¦.f>e´ÑınÏğ¶˜@Ã8{ Å“‘{ T„ãj%ª|
¤÷¨…ÓğäĞs‰§gB“œ°ÛƒÕßõŠ¨İ¬Ÿ·í¸}ù•eÂPƒªm¡3hñÚ³·ìŸv½  `ø(¨·¥O^Ò‹šìÍûÒr!Å{ıÏ†úOeAŸÖøŞ”D…t91YCÓlgñµáÑÏJƒŞ"$ÀıpÅI"Á—Há#<ÂğjÇ-õÆ!ÿO€¥ÈñÎ
Ifã‡yÍ\ŞI;á‘7%‚w)ÑYÉÓÈ}i»ïü‚r? sLÒ›ÅÜµÅ°•¢rôÔ¯H°ÕCA(ƒ'bN¶şÜc”ô?¶FŞ¢7¡WoíM1F¼Ìkm»iİi>tí'„šœ\¶Êq%Èç‹éóè5Z¨T#G]'¿´²`Dê7ÛÖ5¤l9¬#€İ¼Òú;g¿Qæ×;ïğ¯{ÌË»Ê‹š2@)°ÙB%L1ÁOFáÍåkÃAfôÊîÙ¸¹”œN@<ÊÑİGAøpòAj2µôåûY$Q“ de=)&ĞRHÕJt	ŠuŞ*¶A½CÖÔMà+·5¤Ù€P•Ø…×ÉÍ©<Ä3£¨°$;eşÜÙGeS†:”âJäªL•¸ÅûĞS€-^)é¿ªkF*lõsñçlÙèt«ÛâÖÉªMó…×E—/ùB® ík¾\Ãw##çB%¸¡ÅEÌi¯ø-Û÷·m°¿4›ÊJêÔ@ß fÑ—¶ÅL25N#+UØ©œÈ9iÁÏŠÉèDËFF’ämİdWğLµí{˜®jşŸË#ü¶¡¿È¾çïùa‰ö·“r"½ch7 ob…ÚÆxX¢ƒq—Ãõ9¨+š0è:îWº:WV0™]›nšc!îm8$g ×’,=M‹gĞ«”@J$º	c]AF7¾´óŞ™IŞ'ZÑ@À²W>põçm5.Âwö +ûó)æfĞéEPªô½]ÁBÔ aaGÚ¬TJ:2ñ	Ç€]¤WĞ/Àb±ˆ˜*ÈgúUHævV£1”[»'_–š	Ü«WÉo~65 îØ…ÿÑr`äG>y\›Ú¦Á}>cY Pow“ÄB»£ó°Ğ,lpüfùğZ¡ô&bşı
—Æw`JH+ŠšT1/ø$Q„B=µ¼!=*ûN[³!9˜ÒjHğ¿
ï'wnŸa³jıÒ!„bzıQC~µ³^oP=¯@>¦ËL8aˆh!ïÏW}Ô&Î2ğ	ŒÇ§Mîe5°^."cgıë¢¼²c§Gl>q²–+H½87	ÿˆÏwa¨„šéC–oÕ;Şó‚­ãæ^ßÚ~ŒÉµâ”·ĞÈPİÎY	Æ0åy¹Ó ›ùænX.G¾Ú>Ã6rİé“²ĞµãYTX$`ş;ËV‹ôğü‚å(™jJõÚ†(Ø°Œ²$X,d– ØìÎ-m·j|ø"Íëı"¦“V¢ó*Çhp·¬†,éøfbülÈã„TúúM]E†>èÌCEŞ^Tb’ó˜ÂT…ö“ˆ LĞó¨ÓÇÒÕ[K<?”ÚxäÇ`ãÖ,´•B–Äˆ4[T›ŠSÜA*De5æĞ:_`f–,ígmš»²-L+ùP”m±ÈA'¯|ÿa×]Â\µ¤™¬NŞêÙÃ„øeõ;CHË.eË@ÊÔıcÙïïÓ+#7›ˆP»9›l7Å÷‚&Ü3ÌòSKW)IŞÿ³xÂİ!Z,:o¢
>¦ê/\æ`²æ9£a‰r"?s{Î İ¾<©ì9f@–ÿ©Æb)ØĞ
@BÂ)|w«•øz?òİ|`†Z(â-z_ææÖ|ToYI}«?€f6”æFX¼‚ï4'0Òºú(o•éb0…L–Ê¹s%m_x:ó1×F¤#µ¡Pøn=Ú#“t¸ÑÀâ3ËÂP7	¢ël·ŠdnÛíÅÂÍ,:#fÛÉ"	¨%È_Õhò
ğwF/õ^É?/]bºwùµÒ){@\7K¥C‘±9‚¡‘Ãjx½ÂŸõÌ×­$V5»l‚¸X$ß°c=ƒqcè7İ!kï*ççö[›Ç©AˆrD¸3÷%æn/uõWxáHi´“±Á²l(£ïYÁ›†y,¥eN¾Œ¦ĞB³B•ãß	WÂÜ-Y°†ğvu§üú…ñá]Ô]>8>q8&÷”âÔÈ¶±BõôO¹¬c¶4Ñšïè® D"Š_÷î`‰g¯O2TÚ¶%VÕoıBûÜ3.ôµd«3XŞ S8˜/3œæñØ·JÃŸo•iªš	˜Pë‚î¾Ò}›õmÇî
Öİv}Ã†	å‹Î‹î½Xë­šåõç™pÉ/s"r?üÕÛ…*s@“r¹ÑloHqFÀY&yä‘‡í‚FØ1¦ää'ˆ¡öÂ^‡p7ãi¾vû‘¦åÓ¡X"ŠDV½ª¬­Cr .bÿq¯—y!«RˆJ›Rİïõ€õf
¬œ«{½ ~Ş¾øÖÅ[ÖËJKÛÂZÿ]…I‰„kg{»òùÚk üÈÎ‹›®Õåé~VÕä=6ÓJF+oET×ç,[5 öÿ>÷¦¦»‹×iÓÇ-	ô…@BF”Óv'jûˆÌ³Vˆš‡Pú—-İç†ø±J ¯s¸òµÃ!«í›î¥"[İ„öaN”ˆL´Vc•`E&?‰E /Š¾DkÍ,ş~HØ››şÆ:<œƒÛëÄ¡½ş‡#0îës8ãÊ3'½MîmM¢TBP±¼ù‹ŠèyäÄıÌéA¢Á\IÏ½¼ô'šÒPùİXıaáê[¬£W‘ù¼F¥ñÆ ééjÕ—'”êÊ1ï4Õ1H–üA@°—%RãAIŞiqReÿã8²šLù€î-­¢ÎøØ{ ûiJ+|™7Î\ókşƒˆa×—,µ;iA›>TåZÀ?„¶—†É@P‘
'¼uTİsÅµÖ^>0ËO§}oÎ’)ƒù[‰8œ–ø‘"äÄdJ½›T˜5ôÒ6á¡ò‰%ø¾M=§;˜›è/‘,rWHÏ”gı•äUd¼	]B#@ybôŒØÅp…cÏú\=BA†n	äÛ+wÀÀ Å>1X¢şŸR(›o/fe°>v´ªÇ2økdÓ©îTx•¡¬!<!)[„Xb&P'w0nÛzD÷­¨ÏÀ­ÆÃ’®¦qgƒô@gmB»·aGÚã•I·"(I¢Fù¨,	)oyÚ7„%bJæ„ìóó;pÈøğ–ùVûXÖ¾J(u"ù²éÉ&Èg$úÔœğb†[ú‰” ¼\VÆ¹¨õ}8İÈİœG>ôj£í ”™'¦ØšâUÍ™u¯ÜÄŠÃØ©'‰Ï|ÿañı:*mJÃ²úEØë£dßµ¯H¦pR…ÆTa–Óbv¦ğs>2ô¦•ˆˆjiI¨A5-á‹/éĞK`•mÈ’óñ„ÿu‚vô„^Yúf¨ÅÍªé*7Õ¢•İ@èN‘İŒl†Ã@SDEûA±üøâÂÂByíMN ŒÜø{ofæÚİ/T¿ÔÓœA	SbmóswKy„",><|pÏ7|B%æ_Ğ_`ƒóÙ/© ê¥J+¶	êô&ÛR‡å POJ$dmb
†Ãöy™±0b‘pòûS³µ+š›V²§òB.áÄ´şü—§(¥8ST&ÇŸœ ·Ë$'öÄÎaÏû‘[§¼Ïğ@í*5)ÄvK¥!È<›á(äÙbò'_j?!f³¥JFPÌ1pÇ¯C6§v£0<5ˆš2hÜ¡/¨zHIXÎ¬ëõa1Ïox¦ËÉ'kZ_³­’t§”lBßkmSÁƒêcUjRM'o<&*y-ŞuFP¯ŞœëYIr&•¾´ÔÍ–D=~MY»9ÆhÉ»éL+ûÄ$)	°¹)>ˆ÷»Óts‘1ìÔÎ6¢Õ¹këñ›)nşSOÇ(:uı2+Öş’’3Ÿ¡9îí’ŒéÄWÕ¹šAaº_;ßínV'ÃA×ØB–’Ì?GÎ4WX¬šÄU{ÓÔß²
;©?|‘ïğ$ô“·±¡£&Xr£â_¼óˆ¶—\¤Š?0"V…ix²I>?9
H4³ÍæväÔókËşL!ÑĞ9®¸`I‡Ë#7á% òDË	¨p^ŠîÚR\|6ŒÑÏ[œ!{)ˆîöÊAp}§¹`mñYs¹^e	˜P_ÄĞ*Şˆg§®wn£¾É'Êì“‘[ö0Jİş‰úOf²£NO²’ƒCğZD
[X)¡m‘µ0‹ßX:®t¦“ÌØĞ|”äßp¨cÙ ïF‚Y<aàWoê¼|§ÎÜ#.…)X$;‰²yr~ÉíÍ¥ B“J ³Bhİ‘aˆÈeşd²M°d{ó²Æzññ¯OŠ~JRÈ"{Ø#E)Ğ~àÅd™[¢o²AM™H,*d4“f˜&LÅ]œ“ü“WY/M;±è°P6©SooK½jf©§…I’vî°½SŸ˜*üeØ-d“y:–Şş!.kQ‘=E1ñg¾tîÀıw ¾:J]‘èq×h_.„%rb†ó)ÃB¾%À~à÷ ¶ŠJÈ­QV«1DVl‰Xòê”µİ“IÕ¨Róöô¯qü®ˆÕGÇè~‚EJ]¼Ô&i"#YQ°„ZÉºœ;šFş­!ÕÌ U‘`ÜÅhvÛ¾¢‹Kèö wË¬—¼<‡a°¥‚ÖKœyÅ·Ê&zEIÏì—‘q	:4:ò2oñäÆzĞ¤ßÂóT¿ß¯Õ„İ -®éÁ,Êï#/³]8şnHpËã(G”Œ“=h$@·o„µà0¡N"Ò´˜º)µGÎz[Lš¤£—¾Ô2â‚½üçÈË9îæ3[ƒy¿haĞY'\aÿ¼å@‘æ!N>)1«°à$¤ é€±4˜ö7À¬#˜ï}´étAÆ-CÉ¸F©ŠU™@æi>Ö¯™îz•à·ğnÔ*î4}µrŠ®mCG±ÉÔWP1’ú}jÆS>&–D…G¸»½ÆmÎ°/¯H¡¯Ïo¼Y]K´Ÿ’i‚´6¤6	ÿ«Cş1ïñ¸'
ãG–±æ5mmB¾cË›EÛ;¿1¾ŸIû‹Ù€:«Úô‹ßë¡Ì¿6Ø.Hæ1‹Şï^¨š†¸ÑÕHÇ¬ã<KêŸ‰,]ø18…ŸDCMŒÙøµ(
ÔvºÙ½Ú]ÿráOæ/vL€a	
[œ«0ù3‹ÁY¼jØôG®Á?÷ãğQ>fâÉƒ<‡ÙT˜~¿ÁV"s‹ÛVçJyj"×š»34›ûÙu”c
]v¦Ã$	@IéEò,ıéƒÍ?'|æ¡]ø60‡YÜ‰~Hµ–KÓi8a.–˜ÜOg»ÔBa-ÊPV˜ ÃÒB¦2	ä6ï#úÍpà´HC–&{†?ÈšÍBÕ¶÷—:V~47Ühw©á>ÌğBe‚ Yº”f(Bî&áAsV(Æ6˜®¦ºnÇrwÖLù’V2tMA”şeiß~Øazä bÔ‹ â°HŞ#kÊ²æA„¥G) Ø=ëª!gQ°gZïå›ª\Oü+¹_ŠE_;kÌÃÖBÕí›hë¿‚9WN¡G}8—£aF–-!{zLfòÜò¹¿ÉÃr¤˜8€HõHµıÊƒ5a•:Å6JP« ¦hõÈp$T´’JŠúL¨3È¯HLeˆŠªïµ‘˜Ğß1ÁšÕD“a[«,Û«V¢ær›iÜ@jZ~…Ù³ ‚¨ØÇ/¹„»“Q„LİmŒµÅ;”#´ØNDYT™œ< 8µ[Á	¼Ç#íNQ‰ÈLñüvNÃØßìšŒ,ÿ—ô†ÆQf*ó NµAyœÍÅA„°˜êÈ‰WB´ë.bqdÛß®:`%…@¼+§py4—a*.›	EöOë	@0¤ÓU OÊ°»–ZÈ‹nÀÒF²V}ù*÷›úT¶/ÉÔ:¼a”Ÿ}'À^hµ=|Y.–×J	TøêŸ+#ºUH•Ú­‰SøX¥B³L¯ÁhS³öÑçeT±õLŞ…=X ¨ ]0ˆÎ+Aa@¬[ØÂ’’>¨ˆ£¯«‹Ö­3ô6)€©ÿN3ŠsA¸HBÑ$C°S[š¦Í>¦ØÂ>>çç‰x'ŒG¡ğÔ@	úEÚ¡{åUSqĞÁom“ñaµ©£TÊ"îJ  ­.®âoP¯€óçKm„³’öR·!²éNÂÕn‚zÈßLp›Vı¼	m.mk«ºG~½„œz ãN^\2*cµããÑ&.CëŸ(öëÏá‹x¡·‰ûÉ¥nd3µtĞ#¹K©eÎTÎ#ûg»¥…&	—«QøtÖDÑ/Õê“ú&&ûz^‚Àº°/¬¸l¸PS?İª¥ ˜7·%€§rÏŸPd¹-SÆ‚nM‡!Î˜á¸hlìÂc2º|ÓfŠAM¥DÏ6Íh´İŠ >6½ƒ–­Œr¯›r¡B!¢±§¡ñ‡2)	íÈƒÏ‹¿ÈP?£'—½¡’FïQqØ‰j(i¢'«?¼bX¢
GÊÃ„31kH@Ë­[”(~ó·Ú;	=ôâ·-²¿¥²´r7‰YÖÁqßmÜªÉd*ÓœL~™l 7æÂe2?7N³8-~üiÑ+²4ŞXÀ£àcåídWN‹®½¯Ğ~¸D33Æõ8)ÆKß9€Tu‚²¥"/À)¾Á
ë<[z pº‚H%šDí<Õl«¥Xv\ã·¡ÛpÛW2éî\ÂLì¼œH=$¸ÆWßŸŒ¾#µØ I,M/;j3¥a…ÛÆìàqnÌ|I:—ÀI#XİÅÎµ—şMæN©ä}E-g¶è›İ;dÍd®^·V–~Ã§
Õô²eŸ¦ã¬_\«Òd•şï§k…0!ú“bâ“öİ@î™<ÚWğôÖG»×l§Ô”‘UÿëÃb*ÅAĞõ²#ónb®i$l3Ã4æİĞ²fó˜Áã¶ê3µ´‘nv»<Åuoá.ØÍK~æZhü'mÑÿ:~€/uçNhŒèìi|}ÓZpaÁÖd²ôb
Ë˜XÒ~û1bı*Äÿ[ànÊtßaŸGß	¾ kU]tŒ¢ùlÜ¿5vîàúÏ]x¬ıÃ‡5N<Yô~sÜçO £´§³}î,EV?Î‰ª×ÏÛ7¥Iñf½òjáÃßûl	cSÈO_ä.~ªPÅ‚¸¬¼ğoƒJJA>cB›@Ø#r!€Ñ¾(½–w9{	Œ^ì.ûqê¬¸íBª¹üœt;¯§˜çÈJÈ·Ÿi±ú¢óü‰[v»Ñ`\¥ÿÕò{ş§CÄ‘_-Y0åøæ“¦ùÕàù><İÏÒ©Q¨`ÙÀj©*mÙO†Õ
2,4»·×}¿ì"DöxeÖæ<X)çƒ5îzgïå’À0vRŒ˜lÇuKšÅÜè'5}Õ¸.ü®ÚˆÙH)_±KjO>©[LŸ89S˜ô$Ö^ØÅ°„Ê¨Ëb@T8õ¯,ëÆŸÿ"Î{Ä‰j}*»N¿ÅÙ4>\×“›A¨T.3°‚¦iÚvçZ9¡‹á1Íg<‚åŸlË}QyÔ)Öå‹:›Œ,r¨Ñ83Z¼é³‘ñšQ‡¨V©ïjÙ3:Vóş7­ù§Z|åTÅXí2eãìGİ,æ©4&fÌ†a#°ª>ôûš¨=…ïH(L¨ıÎCşŞšæÀÿ,¯#ŞÃŞ³&ù4Åš¾ sFû»6õàÙthç?I³á)ÿÔ2-Ğ/0¯s’Z;Ÿ÷B±lû;wlS1ˆ]›rª	ÆYó€L±V£D›¤d¦°.Ñ¹·”¨¨a/œ¢¶:Q»!è>d °-«†È,&êğ‹W60Oçg’vŸóéÛ|Mfxo³ÔÓÆiÀü¬ 	/wÆhíš9!‘
ËZ,¾Îş¤@ê–5©y£¸ö©<ğ]{¡óbÔúì¦±ÄvŠiKiaa®©º¼­:F¦‘å>ŒÀ°ATNq÷mˆ¢ ˆ½:òÇ*ˆk—!³“k®‹Å»9§|(ƒö”ZoŠöG¦fÓš²võºõ'xÚ|=ÕXa“Ï+ü¢XÔÕÚEx¯¬PnqƒñÒ&’Õê k°¥Òao­æ¤êã gÙÆ!7€êFZÓ[”
›ÏâX„ Æ§u,:¥fÛğt3Æ4¹Ñ3YSÖwtÜ´Tq|°õ¦äAoçiÌÉuX€vDˆĞ.>TS!goEO°¤È,è\Zú=f\®ĞgÌ½8¶IÛ¿†ï®U¢ìceízˆ¸ß¦D~üö•ø×WCƒ}Âİİ&.³[·{ØmI#ÓĞIì‚£ËéÕ8çT/ÿÈÑ¡õµ=~ÁŠ!A³R$ÙÃ¹9çÃO´Ó¨ç’p3wÚ¸,XÂ´$îÈp}²VƒvÄ51á¸¼-´‰*Ôî“ïo*1ÏM{=Ş©\¶'ÊÚIO	ºøˆxçÙ·>Öµp¸kwAßÎøÎ#½ÊİJ«×Ri–¤A Û~flËo(;â¦dÅ°VùiÃ²:¢Û¥õŞ`s¥lßÀa?ò¹í½¯Ú‹LŒ4éAßH@UäBI%Å€/÷§AÚ(‘ø”Lù&Á êËu#ê·;Š+Ÿ¥D	¶{+ˆååIáñ«„ˆA€’¸iv|YhÃ“.øN?ÒBÈ²HÆq ¾yûÜRhá×¼êôˆ?¬‹æ	Éœ\Ÿ¡ÊìĞ§	Èg8 pü¦ğ÷q5n¡9Yr>-ÑŞÉ^]QÁ
à¼jÇÂø(º¹›Œ¹
?®“oS·,¦&ãvÇå¦›ÚµÀa OGÄd~û¼¨{ò['—Ÿ©sµ/ŞÑMºó*¶½¶æÂó¾Võ/$âî;åLpü>¿r¥=.i?mÕ‘YHQu«ú
ş·k#	$-b)ıb½J'Wh¿[-Ç¨E/’aagŒ`ñûéZg³¾âà®€	Â2íö:Û›ePÙèJNà,)®„ğÀ©eWƒ¥q`bá+$ÜÅËÂ¤ááµÌ3Ìt0DÑ ÆJ:Jœ¦àûæFOB6,ü®(h
[¶ënˆúBƒ—;?ú›„ìZ§ÕÙÈS.YoqÑÃ#];Ë¯Ë‡Ú)j~sIšl1%ıQ®[[8RráHÛsüî®½v¡§ä•£dÛûÚÑ=pŠÎûµ«İ (ICåıá3ÂË\&­¥²d+Í‘¯˜o=2™H-™@TOkê«ÉŸ4×¾èïıƒ’k)r<plÄ÷Z´še3Y SdÂœ<÷»²>!SÆù9ÄzšF7Èø`)¶‚d„tÇZQ¡ûŞ@UÄ|cºÓn™S¿Òõ~¤Óh—ş·T}.läK¡o÷œŒmw(vö3cè¬Á„í&/İ:š™² Iç±$=ş¼­2ˆ`65Ùƒ|’±[ßH-ºYâÃ8 ßm†l<d‡è¨©Opg€yñ[-Q—V
53	 £OıN¹_iÙ¨õôWÔGôè>Ö\ôé¿k@'ğ’ñÆã’Yi•“mİXR"“”Ç7v†Í2|<IÈL½·˜é0‹„=¢ ˜ìı]í1›@˜Şu?4i¹Zé°·÷IïÖĞóÁ)ËÙÈkºš©Õš(c~(°ğŒ$Û,<©d¶|Ã÷¯‰·ñØ?~%RÂç¡^ØĞe5wùµ˜K«Â@“‹½üz|bà·{wDy6ı%W½äÌÿÇp÷tš—\¨‰V½êıÇ9¤¢BA(”<ŞĞlALrÚxàä+}ih×ofÄI¦¶.btç¢*F¾&D"A’Á}iYa¦s9³W¯YÎÜİ×·ÔG°i¶]›|FÂ´©ÒWW­çrÈ®Eç)Á†pâQW•#-jıU$e°ÈW±š‚ÅEñ2Jq´ë¬5¥Jñ@ît"FEÿ£Œİ±¾Õx´=gé(Ã[õŞëÍ¦ä*8rl±‘{7lªL¯ºøîû_ÿÑ^ö†ø7))æÎHg¸½İ½#ê°ÄŒO*§¨Q=°É˜}÷;S[<jWÛái ó"Á"x*pG¼6˜li F•¦’¡f«WÉæËïº¥îM²f­êègqÜæ$E¢şıjW/©Hy$hüŠ‰|3Ä)¥7¿à<¢j¡¥ñ’9íN|‹ù7¹b%°G*güè¶1ÌÊh0pôÏ ½:¨Bå¶ö„ci¾UBW0îSå¯0'#™=”Ûâ6’Šï!E®ğkL~$6Ì9Wt|3Ì“?5>ûí2}	ÊsTBÔ;â@f1³ûl­ğ¾ñÙK”ñÏóÌËÃçRÒˆÇº}ª —sûñs^ÒX&eÕ<ÇşÀó§.ò¤<¸™Ö£ì¿½Ë›-]c'ñŒ­ØÙù€ô“3¡ŒzšCpfÆ¶3ßº©9rR¥n(Mú>Ío¨9T]2RhlE×_*©t@.•ZK#‹‹i˜ÎÀd#q§Z(YA(<ìÿ.>‰f¾^ø|=H	¬—-‹ı–²Di‘‡™Ñuçfé—»š0:¤½ç¥ë^é”'Yˆ1dsÄA|cR²½R*÷´qº®’5y	™,>÷bœzŸr¸V‚ª+¬TÂË[AZ’-€_†È%zÀfâ ö‚ßäh€pRê`âUfÄ–IG»®È¼&küŒ‡CòjrÚœ·çI4¢%‹ÚP^çãÀ\İªP–¬¥€÷™?ØÌ(c¬Jqaÿ™i“"T®~3¢——ü³Ê1£ï­°ğySÙÍèÒ[Ğ!`¼Øcã@hš2,¬²”ĞG?ûöŠñÀøÉ“Â3ŠYG·Âø†e!Ï®²—IS¸™{43—Vº¥\B%~B8ÏÑ'B¹VBˆlPœÎ_î½…„}Ä²l`æ?‚j¶ôÿá™~ rçà[u¹¸6d)?%XŞğ«ÜÆ'şÅjÕ*ÕsËÊ¶gß¤)¹±×o&*7Ja¦EeÕö†"B¬IZH¦RàÎ-0»÷%kM%ôØå»¡Ö€²ôÂo§Œ–¿]Ó{˜lL•j	ìëA 9ìçnË³Ö§ôŠÂ!wRs{"¡|Û„ÀHp|9$²a¨H¾Ñv. G ±ÆešdØÛöuîÖq?7¦…ÈV+±³$‡Ô‚r&–›­€—ªâ=7Øü&00·üæbS‚ñ–6‹#íq’¿^6SŒ0N£Ú£/ÖÍjœa%v [-³Üãâ‡;[$pé:œË
c3®ÉMeèí£¦ª=Æ=m“ĞmI<_¹ÆXDlù¾™Wj|¹ü¬ÖÃ<ÍÏÖkèyri¡NCMêPåÏš¡=Õ(ø‚Û­¤&ãªór4İe/s%qÖö‹ÀV‡%ŞQd¨È=o5Â›Cš¾Àc'4ºÓx¾Z)Ó&S‡2®àá‰¯åîà¯P>&ÚF[ÃÎT6	_sÂ\·.Æşƒ>7ò"ßäœ'B"*dÏZ£<@—	¹uzfOÏıÅáH@jí§CÉ®_€%ÛR{QnÊE¸ŸØ†dYÒTTÄ@¸§­Jó!e¸—Eµ®43 5N’½ßiYîtháÚ‡¨ëº¦¦œ¿C¢H;ôÉÉ×¿Z&}f›Ç ®äß‹o5˜ÿeÓ±¸ËCé-àõ%€ª­cetíré‰Ü ',,=KÒÿµ4,œN“Ve     •tfv|é± Ñ€ ÏL-±Ägû    YZ