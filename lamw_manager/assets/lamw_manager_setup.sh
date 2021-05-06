#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2705274015"
MD5="ecffd5d39b296465620768c55468a476"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21196"
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
	echo Date of packaging: Thu May  6 20:59:23 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿR‰] ¼}•À1Dd]‡Á›PætİDñl;§&TÙ&3±•¢ÇámŸÇN°!á§¨ª?¾†½»8õºíû0Asq±ÖŠ¦•GOû£àÂŞ4üQÏ¢ğbÕE¾e´é"Û×íIm+€ğ\yüÅ|¬BıyÓl¾KñgA0ÙÓÕsøåÎ ¸EÇÏ'Æ6 ¯ˆK3%%¹‚µEWÁKØ8ê>	4”Ë[&Â©Ëÿ0»ÔÌ28¨O‹ıŒ+æv¨Ø*Éâtv¥ÎÎ ª$GO
-Îôÿ<Š¥‰Z@.‰{,éÛVQ{D1„)¬îp@›’{{Ÿ°ç¼ö1İê\¤NÙ$ûG[K“ïPpàQLR;ùÉbæéÌçëCªz’­Ÿ¹~û…4Õcµ°F–A&–0\#û~(‡çtu¿‚üÂ×{.%À>QLêF£“W'¤s¹3ö¬6Ş iüu r#Ñx®Ğª¤š„ÈuêÓ¢ _` åª¿ä.{±;V«|ü•²Æ¡³_N§’¬-;öê¸Ÿ7qÓsQNİ[&ÿˆÑ¹Ï¯àÁ™Óõ˜äRH<€ÙÌb Œô¨¼Ú¥½ªáş®Ò%İ,p‹ìe)/²@‹+óçµ S(oŒz€8Ÿj¸•ëtK8™Àm(˜Qj!{n“×/µû8¼»ö—[%CÇ³Öñ‡4ÔõÉë™mR£s_*iGYßlâ Jfõ¨px¬ÂOPI›Õ‘oçzt‚1º/î7³’Ú‘;ºÖKewÚşVÍZ¢8ÚAÓĞí0ÇT+åÚœM²[fx”{#«‚(MíÌâs¶‘×¤)3R[ÛeÂª~˜=eXH§	äN¼£2opq"=•háô“Ğ&—|Úä­}×î]CĞjÌÍò­§áT"4°º¸¡Pü~F4¨¨±Ñˆ]`ø|ÙëEşÊeÂæ9¬D¬äèDîe—*De|û‘!t)ç¶òK{%VusV<-|;·ÔBı`ƒçkz"N´†ÓN±DË¢^¢¢”Ï‰·(kÈß¸×§ï½'ã¸x¹¼T_ ¤æj «Ñ;¬ÿ?nHg7a ÷ºXšâĞz`j¡“#ÀRç±cÈuîñ‘gª7ğÚ²q?rÅkî§¹Bo6G½‹ù²ç´î´|ßÛAÅ:¹À#BêUw"VúÊyR«-D7jå>¬Œ©TsWÄ‡[æÛà|}ü0USµ¸šì;]54Káï5ßúX[Ûä¦=Ó'°1ÃîÉwŠšSù¥¾&á"a]Trßğ÷GÁßy-ç[CösœŞŞt2ğÍ…¥Lû"ÌŒRŠU–),Ù¶"Ğ¥™yò-ıvE¨ÉÅ)É½Ã'Î‚vu;Œ”Á“§t9Ñ»”¯È&ÙÈŞà	6ZÌ_‹õ¤b8*ÛÏ<¾3cÑW•Ì–8úôK±q
²“2}SPü@º	‘Ë©kuíŒyôSĞUİuiå\&720I¼dbh†V.éDäj‡
‰çÃÈ"%®¤ ëó$ÃÇ0Ÿ?íyŸñ½=&Ğd×ªAšÒ8{ØQËÀ{º¬ŒhL¿ì’ñ†ğ:èÑQ×4n\Õ$ttßxâ‹‹(.‰ÿ=GãwœiG'"ïÜVhÏjŞ‚»¦‹O‚‰ë½-3J.tÂ÷ò¢>Å™Òµ<Èa
~åUğù¬Ëé¼Ü8·‹èZNl–_ı:2•GâÖ ¢¨	
VsR)¡™{ƒÿ^§õŞÍõ€cN®ÈÊtCğƒPñyû¿á¶°—paâöÁ =U=„Â^4.5¼•×Š—J`Jf\6c‘wãá’¶$şQîMPêr1¬¼&&Ç¯\!œÊéw´V([[Zgm™¿ÊĞšÀcÌe}â‘	b*¬\iE./ë²íßA]=Bé ää'S_eÉç!Ü8ı¨CD%P “6Kp¹‡°«©ã‚—£ºQğ…“…k/Åi…§Ny€“‘S¦JîÆJğ< IçÊµÜÉµOı~§şè³2Û³$%3,4ìì	óËJFÛbKE-=¥ØğFKíçé¸Îôˆ3úövœCönDXö3úĞV£<5ı0~›}qÏï¹Òån‡GL;™M€KÖÖ1š¼æßk;ó„sõ™—qPÀÜ%5a&öæ=Ù@­CN¬ÑËş&ò¤È:n;Ç­‡_1c@°H[/Š¡¨Yõf‘|Ñ•¸AØç|·ràğ·rŸ­C½Ú6Ò¼ó£CƒüqwªénKÀ4%®İS4V¡úğ9¼·vÀ«
ûùò5E”(‚èÙ¶ÈĞaÊŸÿ}1ıYíFÂÈNKZ|[—H¥„¾ùìj	E?V¶6ª&TÅçb—„¾q »d§È”¨ø¢)(êï&1 O$éÈãêÿn®?ríÔ R=_‰Â=ÿ®bVØe4şï!7‰S$¥k;'û¹¡-Ã°eø¶n˜
êÚ8œ`qLúÖ˜±ià6âkÇ£¹…',K” ÊJîƒ™0voM‹Üæ°f‰÷#ù×ºÄp]=øÕz²Ç÷i¿?ù—ÒÕSı¬Iõ4Á¸&–fğ^¦îøĞpÿ­»ÃWÇ†Ùq—&T+8î?Ò¼­Õ¦ŒVó¢’¦kÚÂ]8~)F¨ß¾îüâÿ†9Z:µºY¢Â¾†©à?‘ÕNktÜĞv‹¶ ¥…÷y?hn¼2¾ÑÏQyL"åq–‚Eé.`q÷1hsAP¡*-¨0ó9-®Æ)²–W÷Yãjª‡öÿÏÌüVbšÃGJoIŞD¯#yh¹;u¶ ¦§6Ö~ºa³»"®êêC=çÑĞ¬JX÷ŠAd§!ÎGÍzà3ë²8v|gàÈC?r]|G#E<¥)_LOó%Œ êıbµN¼dú°´ÇŠ×QI%8?AÏ¡ÃOìÚÑÆ“&4-­l)·Æú„İ®¶Âğe“^LÏ]ÿ%`³c ;ud¾†f×1Ç=5âÁñ<ªµ¼Î6 x#T—çŒ4zÉ·ÑÎû­ªEĞïÀîqÙY7;…J±p±…
™ï€S{L¢ÆKŸódl’£¥ĞdT]cÿ¿K?âfOå^BnT’y•“ØkşmØ~ù®Ÿ~„°AÎKT½FyMÆ´a‹-ÊßÈ!Ê/«MuÂæ‚Ğ:3¸}}sxÆp¾à°Îuî6J†À×§±Şn~Uº:D_”›’ô†Û¦g}±(¼Bbß_cÀçK™¹«…åÎ Fáê±- ú"p,ş_B"*©Ë£’MµE±Z,í|Aˆ4ÂEü4ÉÏíÌÍ¯ÓÊ´SşFÒTví³=aOÈÍÖtN¹Ñ÷7#Ápû©ro¯V!fuF.PGVxâ†óğ¿^ŞMR!Âû†ç¨Àßk9ßµ–àÏØtƒ2ÿhÍ÷÷³]<•WÔ³–øOİ¶×ãrZ$QõÖ8çŞä3—Xkè’4N°pnñL½Ô3¼ªˆÃ5ç1ÔbÁ3si`CGOò¶»õFw—IJíÍ2Ä@5ö‡'Ï»â
íî¸1­Ÿ]9ú×|])ÊóèÍV©@%m‡çŒIs4˜æ0ª¤É¡	ğ»JIL?œ¨¬8j7t~.şïÀq5¼¦Ês5{mló:¡Hˆ¹æèzà¨j˜A_`ç5Œo6}~k!Älİkª4Ñ~¦ÉÆ¹Ãşú2ûÃ<®mRhµüÎóæEí¯(Ô%°»ªH°ƒk©X.åVa$ŠïXCåhPŸÚD/işD¦9š‚be&Œ€Àe2¢Õİ§q´ıÀs_p6ÍmNB¸(o,©Ù‚#š÷CrÒtî	é·ùAÕyøßi~:/]0¸¹ÎÚÁKøp(JÁÓªB®jÀà	¾7²º_J½ç„å„†ËÃ!6srääVBÀr’É½x˜º)uxğÄ'?'X ğ¡"ŠÊÃÇËSÏ7‘<¨G°/”;¡º®êbXÃúåãª'—çg5z´dØì V.Vã±K9CòuW£Æ:µWBá&ÁZÃUªĞ?rÑœ> bá‰ˆø5ya²˜ëxğT0Ï°lKr*:+¿p}AÕúzË¯¹Zğõçš²ÿXâ1«Ÿ€òe³Üøò†Ÿã'
–¡ÎöÈ-‘Ì¼¦ªõKƒ¦¢Ó^7!útº@t¤sDqôq7¯\¹Ë&FÖ)Üc¯ıç±a.-®W@.Fl²:™ìğXZm*ÈÜ)rÛèø¸z¥¬Ù£gæ|«"* +eÙŒZç‘Nïß™“…3jß6?áòÑy>!‘›™.ÀKËS@‚]¨¡1Ûöêùn·‘Ñ¦R®±ı*İ;QO¼
©¿ší"…©ªF‰Sf}²ÿ¶É¼«)eÈ³’à»yG+/Ö{#açÆÉ‚Iÿûúê¿Z©-RÔ«–ü¼a›í®ç¡ÜuK>?Rš¼Î³cv@ÿåşd4ÃËªåñâ•‡ÉøîRa±*ë=òÙÄ€“,“µ	L¬Ÿó_°íÌWÔnGğ¾Pj&C¿˜ÀLj"÷ ãåÇÉ §¬º]=]á}8Ğjè3,¤*éCJ˜‡€ÀWB¯ï¤Ò÷¦=Sxs‹tx3JRĞQ©Uàƒ‰KVL¼b»û¥™@è×ŠşáŠCV$z}@G vŞô‰c¶í4eeÿ¥œ²ì:,AÉ4Êæ@õw¸jŞSkaFø©	öe~T}h¦–l½QÂş4Şşu›)¿à¶ìk3[	‡{eĞz-1r²ì ç­Œ¸ß9K­
”Ì!¶L>ïL]g3}ÅPĞ a§Î¦ÙÁ™/8%(V@œRÆ/,“¯Œ³Ùÿz…NÁ¬;²ëóëÅ´š—ĞÒ¹è “»àˆ'4¯n½œ*Şiò`‡NZŸw-Ü¯q·¾+K(ik†½5OÍ”d+j“pÑ 6Æã¤åhuQŞM5Ä841Ú})^ «1)àd´™›có Hû.Ò‡İZîZ:S°oÓlK§‰Óµ9G9ÊWgÅ:øàtäú!4"b­Î2@5ßŒP°/ôn¾æç2?.^ı8ë•Ş¢7¸eON‘€Ñ€Ö=‘
@û]ƒ‚‚5Şûêã˜ oÏM†9ÉA;ó½ú
]ÄÛ¡`ÃìnÉdöQÊC]j£½kÈ’Ú®d8àfØ1İ=êÑTmqğq'JÔ8XìÍ5ND	Mğ®^Á’À(OySµ/W~OÚrİbßX½]Æ¿ğğàä(/µ²¾*4—
±FÜÁ9_®(ÓšÌÿ 3Öb l~«øwå!KfYkŞ$ŞœQZ:P,=Ãh¼ƒr3Z¡YhÇÂ¯Ig²jïNn£ªp	6Áx’NDwít  õ‚Š¨	*=V5f¼A˜D»~^ÿ·áv¢º?Öàçí6ó4…¡%bğ%R»İ¬ü¨k’öùo¸#_£ïN^zDµ6W¦ta¯O²ŞÖğ±›'6{^#á¤;šÀ1îòg±X#æ@ "éÃ
 6EZ§Ä˜ı·™×à{,mµnF‰ÓûZi+ÂÓ$rÏ’ÜÜOÖrªÎ”ƒUi’|V¢åZ†åıs xŸX*=_]>Ûà|óg†äR&"¨
ö··±©Æ&É{`½QıVüàÄêDS"JÅÎ¶™ŒX[:òÕÃşº-…—é0Ø|Ëù!†–Ñ{#µ	¼ü” Õ
	`ï?‹+W_İŞ(Ár×QrŞß0¬İ?PDÔøÈàşQÙUå‘e<äô«„ù\Ê¬\.ÿÊ0¨hÆß’ãÚ bSøë‹QÔÑ.ú	çïLOÙò 2°¢Qn÷¦ÇÏïØ$Û·(èVÖ4“ø1—¹DÓZ^™ŒkÁĞ¿÷% dŞU!1!yptaëî¡¹ºëİ†NUÚK“CûºŒ†¦õè!æÉ—ú&qx>p-ˆ¨‹9‚q.x™¨«ZS¡YÉ(VŒÿ¯—RS¶\µÕ
ãeÊ—&¯£ ;¯zh¯±~D*şù‹Xµš&Î­'Awà@x1,Ÿö_mª?'ş™åšG„±±_H{C"q/KÍÙh5+E &»Á|²Ğé nt$¦
Bh0şıc€Gz›êÎ7Àò6ùÂ†î±…Qlo†Ìş 7¦ë0ÍqHú¡`3ë #òŒ±´£³wşwÎ%ÕÖ¢fğ®·ê–4Bt×.Ïœˆqo­›Í ¢îŠï´Eå^I,÷–¤~'|ß×P4ƒV2Ç~ÓkËš°4C5C«úÿëz…ÈT²ySİ@üV|!NÚƒzİ,6ÌÌ]ãVyë+wÄ²æ»mVäOœI­z¯]ˆİç"kROuRà»Vjİ n' H]`¾€æ`úü]k;®¼ªª×S‘Û}^Ü˜±ø³©ïı|ó·*«–V7`V"Jé•èØ÷¹Û=iæúDˆ}ìÄTî†fİê2[H!{\¡š«O"¾7s_`Õ|×8»ÁüµÍ"s±õU¡‘Ûe¥Ek°1DÙ¹Œj(úêF¤Â;wvĞğMúe_q°”Â4Ê~ë)Ÿ™0H|nP3¶¿CaÎƒòÿFK‡µBAŸê–šÌh¡‘zy•ˆ#ì&E‘mÄ(ŒØL[í®Gşô(n¦ïLREg×Ñ½ÚëR¨Ü­Öí?Xø\UÛÒüÚÀ«<@òÏFÇî¼Ùi`üSÈ[¨;üyRQÒKRÊîbÒâ«°äòÏl±ó=ôd±dÈÙ(P°
¿¸Ã°”ïa'ô˜ò²ïq_·YnN`:£ë©>f¥Êpsíöœ”zäãĞ¡¯J›‚jø1àEØ/ ¥ĞåÚ#û5‚,ó[Ö Ø©&¹!’¡¿´Ë¬{cÚ±b“Hc§&äˆ¤,ü¸e^K
fÃ›jL•"€qN®=_Í5ë¸[«í×¬Ô´şñÓ¾eÄ¹D¼b=êŠß–-—éõƒpq§.ìÿ
ñ3•ÉUU¨ÚÂ™Qœ3àiVµÁNÓM&|ÿ¸ˆ<ê‰Z§gã4±ñUÚ§&.'÷
Oøj´†4C“l¹FWLQ 7Æi}í©ïĞS£ã–ß·p"¢‘œªÊH¬–Ó3`ÈôÈ# @Í§HO¦¾t
[ g°ğFëu‹PÑN(˜pS”=ÕµĞO)LŒ,)\'ğÀUÒãÈàĞOƒ-_‚'¢põx²ÎQ·aª‚4îAÁ/|& ûÃˆ=Ö€«ÙÌ³ÿJR$[Ÿæ¼Ê²^+lùE!c.®‹=é±Mzw]IO™0ïÃ/Ñre—í’ÿô7¶ĞÕŸù¦`%„²n>qMCE¡Wß¥n5CĞ{æ1µ›Â I±ìÜAo:n†:Şs·Ç*Ë«!„Oûa2Æ:Ö*¥šgW9WNçÌsy®P"–»n¸º##Ğà:2±I:«®€=¯Ac6·Üø<Ã2e«­{}{>›`‘ÆŸ:À	xâÕ‘ÃH Œ>U)îyĞŞk36î ‘o2Q:×«tø¿ĞÖZºj0[Áâ)SŸ6ØCÓõá·b tí’¢	?_¯`2/´ùo®úA­Êãsp‚&»¼&/‰yøªÿKÒ“GcÃ@Bœı·‡§rõèÇÖ1.ş`â{®!%–Œ“—ì< 4÷ü?”ˆxšô:çÂŠ”Xƒ¦†nßñíÛa Â“Å–ÃdîXÉ$"—ñ)³íÁ-ñq”1—Ó÷˜cCºSİ.™|Šˆ÷‘«§RGY£pš‰”?uïoDµLj‰¾¿€©	>.A•ÆÙW¸r¦JØ”¸Hõ9å-²/’ âÑ–NÎ>Œ”=FpôØtMÚQ5¯2âÏCkceÌ,cØœë&Şİ:ü]ª1s`˜Ÿ#'na$³Ôoq-Ú¢í%~÷ˆ
ÑŸ+Ó_¬{;éSHØ°ÿX¨Í´}Ä³”=L8F£ÕY•ˆ:_pJ‡™093B4?¢Û"%Z.,T[¬÷3áÙœ,'	hTlFÙ)Ir#k-Ú¾0;*ˆ~!M_‘T¨Şõvw’e^uòÆuûÂ1äeG-c£uál<ÀÜ`ïüçÙëÎ¿o¡Âó‹0Æã/ Ş…8Ş»ÄìÅà²I¡Ü6×é,|ÏB„a‚4Ãç}çÃ0”vK/OÁÓö«p©Å‘øm2ò8›7­ _Ì‡Nä}LG¶åEûXš@×İ:/VQ‚c´ËX,ñ®ïp€)Î3?10ÇUÿ_›äEÎUµáÇŒÕbÒğL õJg4„¶:ÒdV]9â,æÇÆêû4°MI µ„Ö½šéİÅ¶Í~³DÄ™˜3­l²òÂ²ŠÚº<¸—ñdzŠ§;„"‡×j€E.Mæ¤şqˆ°V Såç=à8ˆ ·Úb¾é¢]Éaş¼.L®sµ¨äáóÔYBK Qˆ'ÔŞFßÿ`ê¡¤Å^ÊµTáä¶Ø( Ç«JÏ¥ôÂ×¤Wê³­7¶Ü¾ÑÍóg”õ$”zcQhZÎ¡nóy±ñC/]Š11rb”ğÜc¹+·épd•ÙÜ%OFÇZ¿^PL¨A °sIqî5x&ïùaáJVCD€$&Ä^¤‘óë68ğDW1«n–·–íÊVÊ¬¹¡7>ÂàŞæãÖéºfïã¡;Âû¤OıËYÓØFùsÓØšÒìÁ™è¤t4F"¾*'°z]ğùşš”eâıá¹Í'æ† €…ô^öyÚí^AúîÖJV¿¦#õ…#É#ş
_H¿Á–û‰9<	İØ5Ã«QcÁfÔ;b¾	#4-Ëğ­L´<gUĞ*%ºÄ2¾&@Õq_š¦¶Ø­€i6,.;½›3,QJc—hZ»Ñø´{Òá™V/y=:¿Œ²sÍ¶Ô‡è"]¨½· İkÀ£ŠònÔÖSöÄí‘Úz‚@`Ho*°_.¿ÈøSõòÂŸ½ã¦gı eÛZ+æÂßöy­”fÚÅ.wbb#<PÙ›fZ÷ìN%'öeÓEVwÀıiÎ`Ğø¶çkD'X4e©F–„Ã”‘Y[Jù+‚qf’{£¿ı0"ÿÚøê@ÆVÅáŒèHÔ/’­OT`°„*Úó Óº6‰ SôãÈ1Ø-mDTçöèøZ¤µ•Ÿü3¾•{‡Anº…—Éãñj•dÈhG`YË"’@	P8Ø?Õ±¼GgHNM8ãÎóp–ÄŸ¿ëXU—Àªçï\İ@#¹Y–u1Ú KjÃ[Ô‚|Ë’Œb3<Í7¤%IIµ´i	ãéËé»+ÛI4Jjps
7XÒ'•sğYÉ·µ6UµæSË]ê)³Çu—#OIE ©õ„.vÚ•X³®+Hà®$÷©tÏcR¸SK—ë|¾åş*Ğ$¾ø%R†œˆMéÖ	kLGÌL®—mç <ÚMc¢ı}ÓÏè×Â’Jy¾$­êà«²À¿Å4tù©_£íÅúºtz©@8tª™ÛŒTˆàWõBe
ú§E(bïÆxé­N±§/Á¬>#T™å¿Œ›RçO£JÊ u[Ô6\ßáÄXÇhp"h–a¶h¨%d !tZÀ|´x9¦Áş˜™\3s•÷÷¬³ÍÖ4ˆ^•Ñl) 5d3_Ë¡Š£NFé	ô›ƒÚçÚ>Éıóİ-êa†š%pJÎ"Nµ„R5òâ²)]C¸/àS
bJLsâ½†İ¥8=Eõ MëÇh—¬¯º8Ûcm+|]Í\±{ë+­„ĞÉâæ>ÔÌ\ÊNùˆÔÀÉ6Ø €µÎBQõÌíš5@D²†x£‡„—$æÇ"ÀìĞN+/‹ã€¢•ZÄ¬slM2dDO‡Xìÿ³ i\>¥,é½ ‰bŒàÿq¯V:d%v‹h]»¶Ãê\•ë¹ÓCgœË¢¼D;MüúnÉIé’óë¨´¢ÁÔs€·±AÂQ=?•jòµa)Ôúáïı&t^šî¹ªıO„
¹ıL˜ /¾'[Rh¢Ôé¿ÎÀ¢&
–HÛ4u;ŒçØä[ú{™8súnÑ|’(ç~ñ(,xú¨[ìw	À}¿éãÏB’Xg|è»$p®íw¶•©ø½|ıg~eçM!EOpA~î>—İî'¨wğœTñ¦ç¦ÿéDëEàuÔ "Û ê³zwŠŠ@ØÄ" 4Y3;“ó–/Àrî¹ÑSŞmYõU‚ìzôÓši MÍ¨_5”¹­^lïŒJk½hÓ&°.²†Š«Hå‰‡»É¦{¦BÚ¤ÊgI~¼İ
ÃÛ'ˆ=Á5§po"è±.¸wjÂào'_Â×&§`Úš±‰ÿ|]”«&ğ©Yô‡IÜ›i¥XêÆC›<Â«š—æÛ•Ä‹-dÆdÔ±lÕtûs§ğ’2¶¢ÚhoäbÅÖZ`#¸W‚7»4ö®IÊ]ËåŸ+±<²ÄÀM?+˜Xğ|)ŒŞ”™¥o]s cü‡"AÄOïZ²Ï€*ƒ¢5ekŞıèLªÖ{*›t Åóå>öv0æ€oÑË-š¬›ÁT¼ó…^§KX âÙæhšÙ:ÙknØª&ÎO&>"`$;%Òı7Há÷]%±Ú %X=¶Ëé| Õ”í©ÄIs'fÉöŒÊÔr¿öWâùå*²êM<Ú…É°Éd‰Y!)Öõ"MffÏ‰5ûêÓ+s–ì˜“ñ¡5–˜'lÃ›F÷0y¾îè!#¯HXˆDÍÚ(2uRãI*<Wš`çW¥D€VÁfSÓäé¯†bîçœ%+Ø^œHAq^Sñ…¯ŒŠ,Nz°¾¤¾TÜ%‘*ìÖùÆ^¯oš|¼tt¨—tZ¦ßŸ^©‡|&]œÇL<Qañ’ùt‹w¥œ{ÊcuJIëœ'ìùdØ3W—p78€»_~{âR÷­ZçÚ†ëËÑÄ\¾d37Ms‹Ayˆt„ˆôqù–·0¼Àøè_=›>4™kÓ§NÏıM2÷ş½~Ñ9‘Ö`Ç c=°¢õ‹×‡ƒQcÒœŒVz/ñÌú„€w©È½ñ…?½q»¸vË"Õ×†ÖÍO«[  	€ÔLxK²™[I´âÉëüo’®öbKnz9’· şDÇ7BåäÔ£8î’”ÈÅŠw§†õÎÙ”‚ñ!g¬ğ%ÔÙ·KZEiæ>­
>DÀ›ÔhÑJ'ûs5WGÔŞÎ¸Nñ&fã8?EØå`ğC?0Äi4¿´ƒ|¹³èÿĞÒªT– €;·¯
S;‰û¦âú3¿´ ïÍæà¼v´0sõ‡ËúÒJ-˜İ•ííNèsİ¥é-ç¼ËIx¸mW‚ª=øêi’u¨bšdìøC°YÇVÆ`LÉó4;yñh†Xk‡Wv¸Ó<SĞó.,<úFXšIûÿÒ€­cßÀãú¶„¶^ÆLë]ˆ43¤fXÁ©’ŞF0ú?İMHİ%eùHEceıÃïasò†‹7Ğ`­“í µ,ò^[ÙªîY`Uğ>ó{ú<fó›)*!kõ®Ÿ¢sOìÆÖ»£ğoåÓÇWêQS¨Q<Î†nãòGˆŒ%ãqf[Š×?ÿ»á)êçœ±œØ'_b^OGKz˜ÆÀ:¯„SÚ„gÿ†}FkÇ‚"ãÌŠlbÉ#êm7¡ò²ğ£[%Í@Ÿr®šsŸkG©À6Ë	/^Î®°@	«g°­DôæD´3\I-â±‚‚›ˆIX?öÌPTŞ3çÇæ±e‹Ôã¿ÊyuŒEêİ«ÖkÓLùß7&Œ\œ²9=Ÿ¦1¤]rû\y·" “¯ÕšüqùÉ’R'/	~]g\WÁ?Ü¦Ï)¯¬/ƒ[è—U‰2{Ük¾zƒJoÔ‰¯Ø#MV=Øõ½S(ƒœ7ô’K; ›ê\ˆ|4?g”‘Ã©—Ñe{©üîÚ°'Òê™kq{7¢vï[Ã‹½÷\â"(¤xBˆêuşÄìJ~v©m+Qô€âÁ´÷Ïbe‘ĞHÄÁSëO4	Kú´Ëri’£3G’è€T ´©ÂºoÔUåHš„¼Õ¢@ÚÈ{ø‘¨ÙoXSòQĞOğè”µFÕ–æ(1fëşmÊóİY©Ü rs…
ë#÷-<ãŸ¯X<Ñ ïÀaİKl~³+L]¥Š´e`¼)$WÚ*ÎdãOjû× XşqğÌ:ÑòaÕ$jMµİÉ‡ê*îá 8Ü²6{k\.•<øogD±&Ãú/ dÍA@QÆ$”ªİ´>#YSixL¼$"Ş;ãl¯ƒ¨]´ûŠgß0ñ‡>¹ùt½xÇ;›%Î©‡7ÇG»Ì ğmÁÓ +ÑÕ-$_VUƒx‚§¾m—èĞ?RBíğex»{ZHšÑ—¬/_ÖÄGÈ1O7×Êä¶E‹5-¶Ã²õ ˆâsúºLÜLÅ
j…Àî§´æn†Áˆg÷S¢ì[Š U€º[íÖ
-ƒ7,ãä–;
İ?rG¡™Še`’ÎedÄ¬M#²ÓÛÿE
M%v¤<hD• 5°¨jÅƒ:óÈoĞ¨ƒQàĞ†koH<3–(‹%¹ÁÆm‚ePEk[êÌPóšîölœ£I"c[-W<¥aîëjÍ]RpA§•w§•M”M«íQùF…ö;Vö	Ëk{Ÿ”Êë™6EºÙ¸ÇĞnu9RŞÍä«rÄ
ä¶#8áşĞ-ùøIcÕÇ!]ºMsŸ¶8Z³­â½-Í÷´„I0²şÖĞ3B“ü©,hÑ÷qpT~i;‰öó"IÙ7²œµYaÉ)ƒ¦íÊ§…ü\‰¸ó[ĞØ×‰­N®B_¾rºµºï@X@Å­'+¹»ıÌUZ;…>‘21:¦O‚´=e²‚[ºê¥Ã¼J|rÄ¥ğØDtv¹¿zôvN@c§™ô!Œ*œ=z1¨oìŞÛ:Â.èôFiâ†wŞDCŒ¹ô üßNiŞÊw#tŒôÅ­DzqqdH‘:yÛğÃ¢ÁÔ©ƒZ0˜yı?9è{…uRê8îCÈÄ¢zƒûàb’Fİc>âKİ}=O¶9d¡Œ2d»†[F3n0ñ!Õ+f†¿‰ÇnÖO€WñöéÏ¾ƒL²MÈ¡¬,Y®¢â?u}-ëjpƒËÉ'HùKzdçø3*a$¸xÖ ²É 2³“åÿ7Ÿˆ1 -Å…Ø3ùŞÍrQÃ³»ÄØo.rM˜¶‚«sôépB@@8˜Ï?ut·ûêƒ~óú:…&P‚É§#î`^|şZğÜMSsÓS}ãÉT~{ßÌÙåò¾zªğ®ÔQÅ\±j´xıÙK¸tvPÄ-òÕ=åÌÑşw×Î¼µÇßßİß˜jŞUPó|"¬şvTöÖ T¡?¨"†M›‰“Ä;oAt å@’!-lÙ´!Ñ‡ıùƒu|Æ·jïÅÓ.â±&ÀµÓÍ«eª•áX-Êäğy«]e÷²åUÁ'Öè)ã\T¨2NÊì­AJ¦Éïûj‡x_Æ¿*!?ŒÜ<ÑÏĞ‘” e¿!ıx=3w‚¨³•ÿF%(B³ş—èm$^Bz°`ıUª?ò2Ië‚¥QÔho5§	•:Eˆãâæpµ[~¤p) E[§¯Úú ¦ıÈªá=æ½ô§jÂ	„ñ!dŒdvXşÆ<Äÿ¡&”†ô3AL¡…K¨
İ’å¬iìaf1	`î.½^!pÑ¯ao	5#jájp#öÑ‹èÅšyQ“¤¶)w
Ë¦v°e7#Qõè¼mŞ2ªÇ‡/éëklnªnw`E¼V¨ÊüÕˆ4˜=ùmšHs‚ 7&h„ÿà"¸(ÍœÅÉîİzˆåş;}ÃâMùê"4L·Y ?«ã_ I)Ãºeâ•OÿO˜ˆ°ò=Ìƒ>!µQÉñîLHwÿbõï/î¥BÄ	Bªí¶^ª7¶5 Xgûœ™ ,½“ßÍ;\§—£¨­Søu5EØiÁ”î0´½œOh/[`æO˜¾½¿è>>³Òã ¨Qè³°.S$µºtf"¸$‡gÅAÀŠ:Å}§CĞ³ÿ¦FñôÄ.’t™Ôˆ"«taèß&ášDÄ²oQ6ò/¤CõÏáı/Z‡VÈ®ß°Ò|r…nŒ©Qï´v<» BÒ\V<Mˆ´©yÕ:i}%QÿJêÈÖ†¯Ëu"ø‡oK„|÷ŠGÒË°h‘­çÇ}!DC;„Q€âGXVôE,Y¦ÇXŠjkZæ–æSæõâ42˜·âP1Ş§Éøl²ÕFÿ5WÌX|·€8êˆf±´¦g˜Y
%lf6-8mªÊ<%ı|Øò-“µJÜt;†¥•/µ)/²’?Á®+Xlˆ òªà~+÷…	?MëôWößsi”ø.N4qT=vî%—©Ô=_ãüÛ7şÑ$ @[ü[îx÷‘•§£Ï§cpß÷İc±3?¥Û(Äu´ç¬dOü®ºé·î8¯Şê6.±I?÷‘&CØ…üÏğ$Ÿ'„<ıb=+×]fßÈ†×àªú¯|íWËP-o}³‘Tÿ{Xo 5À
=Ï±)ı(8ne(°³½H»V]1†ØT42—o§ÀÔ=€ãÃæğjá±-ô³. Xû'Ñ)‘IôÇlqÈ%Ÿ[íÓÒ©\ñ2Æ.™-y'†¾.¯VÂvñhREÔÓ6 À«z/m·¼Í˜¹n¥nZ»'3KcIš>abÛ=’dµí*u;‘U™>Xöz.eÂY³šÃ¦rxªç[ã´-(mç'`Ï*)F]şh3jú‹~ïİLNs);=ÇK´âµìFÜ°í›ë¨M1­€ÛT¶!@áXˆ}ùà7ÏùFÄ4ÍÓÑİÙ0â¬ğæ)ÀA[¤-Ûf¤ÚzÃşNmç$/óÂÑ…œÆ;›=ÖãLpWùjÖšûŒ·­
A¼ÜTq•åÓ¬h7²²EªNÈ¨ËL4HĞ"@LTÌ\ğ¨Ê.Ã~HZµõ¢uU7ıKPŸõª@/¨”Œÿ5àÆ¾¨°#(we @×EP¾Cu>6¥îÜó¨]*‰.{rÃéTLYÆ•ÒB)‰KKîWk
ıÉzØ­óçûï<,»Ôr©ß¶ü¶‰˜@’¸À´ºşPXªæZée~ş‘3IşÕÙ`Æúë¦Ûp¬:§i€ŒµL·×l+&‰8y`ù¨/¡ºçcÃkÎ‹rm+o•oítbÖK‰lgöÉe· /	<Å=QªÙóı©Íú™Cí/pc,.°i;Ç¹÷Øøš¼ÖòÜ.Ñ&Ÿ™÷¸ÚªhÔ¼Wl_˜ıŸ–?%±0jÜau.#c½n½º2çVğßàÿÖğrtr÷‚>''Š-Gpî/Ü¢yg3î*ãëĞ¥Üo/ÿ8å¸FKõ4Ş”x®Y|Jû^#ÅÎÖ°vGŒt«²1`k=QVD@ê˜Ú©K*‹:‹]i°½‹Xb†0|ÜÓé¾®-§xÃÇÑ4À@uˆ>x,œ­öa¬õ»Û«/½iRjy9Õpæ?ı¹SSáRÔ>|±‘Sî¸Œ¿ÏhÑY%&¨†À½‚äYv4†ù\™µÜºÒ6oB/ÎÅ(n¢|ìK4*ñ¥çX‚D%8}z0	&ÓğSE:Ğ…#]
^ı£é¿&‚"N[™C¢W•Øz—–jU-/~û|Z¢·¢ø]mTÅ‘5ZCcú©¢À~±ï÷&/|„‹¬]AÀª'İ{dÎİ[ñ$»èB=·ùİBït5>!?JÛ˜œ
=ÌÍ†š]u^y üvÿŞ9@”fë8âPk‹ªcŸÙ¤ç[}%8aR¾ßxİ¨<, 4«mÏìÀ8m ˜PXÀò&
ãÇ®åp"Íû!kìk÷Y¸>WK@§L7òãau·"oxç˜_& ö•—¾Äê8ˆNU°Õ‘øu5IH6&ıÕÙ÷ûFÕ³CòËÑ†“ª¨PpşÂÊ£—Ì˜*%ëÙ’„ÖQ÷MpNÁ¶tÛ¤Àå¯Ø-ˆ2Â¬†Ì+ñn{Œ‰[#Öš7µk3aĞ†À†q[i‘gÁB.ù£oô³ÔjHÕ²ŞÁë^h&ı„³é ú@'W‰£ñ»Ç›;‡ÑLæà,İÀ²QñC†ãˆğÕCh‰flJ%2¿Õ™*ıy$|ãÜö$N‰>º=ÍOà´Ob ;	æKÎ~˜vdæÂÉHJşnİ›Ñ½7½‚ë­Pİø³]ù_kbpì°)şg5úƒ Ù*µ_É5§^)æ<#|3×şx7²IŸˆh,TcşõØñÔtm8‘=xHC—yS'ÌnûÔŸq“r,Z@ÁG› (C©W„aÕÑQãÓÅD9}‘0,ƒ)v´té6{©Tƒã¥ws9›åá Ä•c›k`ÄqÚ¹ÖpægÓ2Â±÷üöy$Äà¤şÓè5s2á ·­ŸX»q62BPf¬½åÕœ¦>q¢W´F‹É¬:4¿x^‘¿eÑÉ5Tô:6Â×–~©¸²Yßv[¬3ºc«’Kª¨`ÕGœ!»öÍìÊ´WĞd’yüá¬w3 wú&º2ul¼å&Çî¸ìG²¬ÊC{]EbC2 Ö›&ÿöµw~¼CØÏĞ÷ZÚ¸—OAnV5Ò~Ís,®’7_4=™s|";¬ŠP‰Q‰	U…€Ã²f»Vr~¥D8­İşÕq-÷„'ƒK¬œaßNáE¼ÒøjŒ‡5¼#'ÈowTwÎ=¿¬:¿dœ$†œQ*	1w@‰w,wW§Ü€,èSÓ,¦5±X"*ª"ˆo’WyWK.ÒüŞ¬e}$'›—Í{(édĞĞ´¿ªŒ@¸ş‰‡AÏü\|EÅ:£	pà™zŒ”úå)Á©ŞÉ)JX96lÍ >kRf£x˜]´l«»	QoõÍ2Ãöm¶tv~ŞR/T	WÂtÁFçc¦€@–‹M&¨CR«…U@M­‰˜ºx+a£ı26ˆ¹_I¼å–ÏÈ-Í·Ø9êî8U¿¼¨š­äY„Iz‡¯t…œ‚ñ$÷ ?@U.4AJÙd­:›oŒ®YÕ""0úŞë»Ä¤Dxİùª“Ú‰r,Bˆg™¾Ë½.8Xø[®dõş³S‡.ACp+Jøİ^$ÖlÖÊõÂ½MŠ¸˜[6^&—ÜÜìK&zô;ÿjÖöbi&ª/<­)5{5ŞCØtW0Ö³À‰¥û¤Ã$€¬5ıZ
E
±
Î{ë“¸aóŒÔğÌÌ
†&SX;ÃÎ`¬Î¬Kc¶dJB.PIêŒŞt şä‰Ìj¥)Ò,Ì£0*˜û‹b~ç1Aq¶kZ¢_èC-Î¸Å5ä+&Õãš~ŸGøCdn¿Y1?)ÕpÈÇK—İ~o‚¸JJ‹ØIÏ-û‰>„Á#¼™¬Â‡2µÿ¦'Jÿµ¶‰qrò–LSš;bñ[‡rÎ}¨›İu£¬ÁU*Ï4_óìÕ‹1UôN´f%y¿\§ç¨UY±Ehïõy7·¦¼²y Lôw ÈĞ®±¡Ëg_>pZF¹Q¼ÓÖêíS³dâ§ñ+hO )ŒN’ôJ±	«sœŸKÁ7ò²¬”ŒÜƒ%Å½/jõh±Ì˜u´Z$üDIzs°œ@vÚºZ‘‹G<Æà3Ä»ë"‘ñMÊ¼6ÙqS­,AëxQÁFx³Mdöp–Û¡Ş
1­Èu¼UQkÃŠIKX2Ûo6nÕMlÂ%å÷cí 2q; ~¥:JPRu#ŒÏe‘+¿€£CNB\ÎÏÜôÈĞíáv¶%Ò_H#´f_ª n~õmªUÎŞ®xå³)àkÂş»ó¨ıƒ™ë<©7Õ¿Û“ÿøS^®ÓIeãµ×~“”#Õ¢2ÿåDM¥î¡Q|'ÆpéÛ†Ä‘?HXºcZj‡êjÃÔ3ëZƒI­Dø0n5q”B|L!µù¬|şöBE§	ŞuËÇ,:ÜÿË¹`³µa*´rãR8ÆpøÇ¶D¶T¾´owËÙT›eáFwZ_şèo]û¢]À&?Wùx<×JnRÌZ­B«<SœËÁRwÄÔè(NH„ÔùW„2{$İGòH:Şùc_5™L)~í:Z:Z1HT	>§u˜›÷Vgí1D¼ä[bsp®|ì$¥´:¬“ì[´w&ã3.§¼ÕúÛ›B”ğ¡çÏfÖ³®Ê( 3±½½O™D¹šÜ­1˜±|‰@y‘>²ı+2„3W”Pó¿4~FÜøêcëÛXh³¡ÚÏ÷ê[úJg Q"h¸\:a*£ÔíÓá(„¦ê)(@2^±yâH¸­O½m·£m:'? Q¾.æ'³†Ëº¹
u™B7Ó›{[ùÃh—‹ßwêÛ|¾^Jp°	65­IïAF+ş ûrä·¹“v,¡RdªGÁ6À)¦p”úäÜ	ƒ$šàLœ¢ÜvHM£ñ„AŞ³¿Tµqn'ö f`F²îœÅË¾GrD=eV¶k4„gØÍ¾¯/ğørg~¡5¶ú'qE€IÄ¶RŸs°ÆÜ¦Vp¢ZZóƒû–øÈ]Ÿ#ûšÜØÈªÔC±¨ÀV1°×,_¶©F¡Ñ$'¢Ó¸pà)šD07A¬SFêLÑ7‡¤áYü²xi€NM8ş÷ZP¨´hÛéº‡ûn‚—†èâ0s~Î€s!Àëc‡JÇ= P¯ş¶Åä"îËwND8©w«IèşuÁXŒ}³¡¶+z»PU5yS²En¡!q-YÖ×}q'¤ıµŸÓ¯Mïè¹ğäÎMÃTR¯‚…µjÇ`)-º<$Ş9
ã™áµäal	ãO_úÆ —±JBË%&-vººhH¬ÖñC"ùßÜtÃİb330hÏ3Ü Üdh—,€¬œ¡‹IDGÆ¸H°.ÆfÁ®nÍ%ƒ*Gi5„½%ßW®ûìu*@Ër¯ƒ,ƒáÏF qSæªÆŞB¼`€ŸÕ¿ƒÍi@ÃïgşÚªê•˜Kš{VT(e‡-4{8Ã6™ıÉFz)ˆxcşSL?/Tk{/Èü€¦Î¡€Æ“ÑZ™5ÿü$Ø°X/Ç™Ò_Á
¯Å6C [&&²“ÁÄš§šj4ä“& 'd}ÉœëÙEM0ÕĞÙÌÂ½ç T+˜X¯\š‹¥¼qaØ²šx¦Ë‹ä&ØšåÈ+_º9¯|Ãª'ä¯=ñ$ÕHˆ:9cò4x°ÄE»Œ*)MäÅ()^Ænƒ_‹Å¨às¿PQ´lb”İiOÃ›uğÜ¾Ê•’.ß‘:o¢ú¢D›œ¸à±Lr?áFıŸ˜¢	 ØçºPvÈg°=ìûœT{ıïÆÓÀƒL:¼GsŠ,‰H$¡,j-Ú©q¼fsÚ¼ÑIH&°'nå¸ùƒYÜ8ä ìEuâ9r§ä¢1gõ/Ñı[¦úêëê†0+â	s³æ¹µs6¥¸9¸ºÈ£(=ˆQUégÙ+0É}&äßœû¯XÌèCVéÒ~`ÖàílTµGHóûÍ£2.XÛ‘Y´Ñ‘Gù‘Òö–ZµÙçNµ9últ.>)g‡Sîó"\K†’
B³¢6—üÜ¨â2¸=µü'³ò'î?z“¨¿©£Bñ;Ì¯`«¢Ö¼lOµSvÌ=ƒSÄİİwh°ºWv×ämÂ§8?ş5OÌÁ‹8ÏÛ†ı—Í°¸+»QcÉ–·•WÄ˜·¹Ü×à|â«ì[I¸šB×?ûá%I¦:¹ßàW^¥¬E”Ítm Üö'd«ğÛA½cñÉ7”Œßd-*´4ïj|)7IE$(Âç *ı—<äš]÷xÜìXtOä†¨$1N8xÒ°¢*LU”F%¦ ã¶ÉÖrá-Å·‚s‚P"ì6Ø¨ù—;|·«âî®öxÒoÄçéÌàÛmísVË:ó·á¸¦ŠÄõOJ$mù‹	æ”Äé6Ó•³«¦v«sRw!‰Ô›O Å¬aKy4kë_cş²É‹¹èËZâQšÀ
)Fâ
ßÚÁøK*cÑö<	©uİP5{ğÏkÀîÜ†s¨í“½íc{'y»‡Èh¾’Á~Dwvü(u+`ÎVÙÒ;ï
{¿Üò<^XÕØşSÙÇ!
‰Ÿ•Œr1•©ÎãXä5¬ŸóŞıÁĞK
¨EWX¼Eç£!^ˆGÈi‡`2šÉ§BiîÔÊğc‚iÏzZ„Fé$1%ºXUX 70»2ÁÕAT½ûY\ò€Ã{
7’hŞ‡Ù«Ù»û¨ÏÛJ1róÅ›"ŸƒÅaP%Ë¾áéxæ4$%ş 
¾!E¤n†¯oa´±zÊùâU^‡7ßÍgi€¤SÔ‹Â|DLÀ0Em|bm8>±QÍ‹e·Êš>ß`9,«¿wˆ¯zç€!g´§æÁöVÑ8<)Åµ•ÖßšTÚÀÌ÷r¤Ÿ1ëNy¤bnşöÏ7Ğ5”¿³…|M¢ósMG‡ñ†¬¹ëÌ:‘lÔ0Šo'ß·-µ„)(J5
B£V'u¦™IÖ7Æä=ÒmäÓzWop¼lÍå†—98AIõİ²æWİf³}çªª9ÄBOwS.—‡IZ›ÕaÖ½N?,bíY5*~î¶ÁqzóšìÍjLVÔF‹¶ŸM¹GcuP—¿#?”&^;rŒëh¸ƒhïë÷cvÀ9§×Ó
‹#Ô/òT•ò5ŒûÒ™HDËüTD`ƒHô:w«94Ì’Áô¹»€F-U_Êº¥V¼uJ\mÂŠ€ÿn†?ÙÓth­‚Y@Å¬œÊ›WI¶š§[·ïÉµ§ƒÙ>N]¶y]
zmß³ ‚M¡5¢ò>ş(ÿQQá`ó(,JÔ BÌöõN©ºâ}F€¨GaA-nÁ4tÜ[¥èë:Ÿœ§‡ïğx§¢~Ï§w—FYË®è¼ßNÒ›F„ü]…Ü‡°Mö>™w UãÑ×DqøŸåëXA7Şç?â±ÒîÖûïüsIÍ¤òù¾ÓL®Wÿ€ÆÊ”ı™õ¨ò6lr,y9lùÉØ¯˜ôNàVå­Mõã{	qÓù»„@Xrâcéî²­xÎ[r¿Vc…¬àÉä-Im§¿¬aC–q
nªÂû€ıAĞRB£*Ò™È6aH‹®ÈFîò	oKTKVëÚÃh—AZ¬ë—[ûˆÜ2iµÁMÃùõêqĞåókTŠİ-kş`]×Tîı}…`0	…Aí4T{t'h°]"eÌ,ÕaaQä‹–Z˜œ,%Pâb(ÆT»¯´*z<{9Ô4ç¾®[¼)¨}•í@ C¼»0’ËV"=×CŠÂ‰#L$nÓ"ˆŒShŠAÀÈòÕ7ÇÑ°™ û¡h¸x£qYß(RĞ1÷Ô}‚'ÀRà» xãÊ¼¥k|¤ß9¬s—r2b'ò w•|Í-3ÀñŸDÙĞ·ó‚aÔiİÚMh†^DTb†•LrE¨çúZ‡îŞ¶M=÷Æ3›…SãRGÁ¼alRÃU,Ê	oİö|WÁõN¥‰®–*œFàøKÈeng)`õe‚gwÎ—Ñ‡ù²ŞP¦–HA”Jª#¬E%qÄ7–ûArD2±+ŞäûÉù	óµù L,ø-'¢¾ ËòeÉ- %IˆB>ğ¹”Æ³Ê£SÑFışffƒÊ`Ò¾Æk‚1hÒO»è›2ÇƒŒ÷¯A%@Á~ËáôÂÆĞöÿ4„)"'ùççx–¹½fsØ*åïìSV³EC¢D_h–æõ¿uvßÌcº,û¾!ßeq‘ß ŸlÜ[l#S®ª »Ü1±²ƒ1öãŞlhK’—ÍäKN•òâÄfPÈ5îÇö1ÄÊ„»(h“KD%œIu4YùŸeÅÕÕ–L<üİ´àGò)X\Çj'²y×}ÿ™<a‰‡ş˜rrşÅîTWÁÈ Æ£¾szÓ»ï—‘`ÂpV¹•µûE•zÓ¶~æ¤5XA9Ì„Ìû7©Á?´á°X?‘€Q]k+ÓŞˆrÈ¼—ğÛ«´È^ÿæ¨I{íà·ñ©¨c¤î–Œ©Bƒ%fáÍìÿØğÃtìƒÁŸÒ{ƒíI«@˜U~;C~2p¹ñe±KæÍ%ÖƒY!¤à€MÅ51Cß€'=ŒØ‘ÂTù½³“ŠÁ”œy%ÔQgz5Û,ŸF)U¬ê^=&l$m«ù9–ô÷Üû;
ye­‡4#D½¥k¤”îÕÚ"Kv;<zuıÓ‘iöAğjÚé¤æíèÌŒ¹;DÈN8Ü"M¿Ù%#§ì;ÌˆŠèª:İÚÈ=]Š,Ac(ZK¡F·sò²STñ¬Ñ=’éB‘ÂìF–)1+°°PÚãµö¢"]{3½ÅĞPüÆØ*½f{<ÅÅbVÁ¼]/í0ïIzàæ¨v0½”ZÁ8µåhïPÇğ­^ìO Ìƒq¡gô˜¦°÷	¤­ll7­íh"ƒûÌúf!!›ÇÊsÁŞ">#Aıü¬g~Ø¯”‡±Gjú—³^´-ì»á<BD¡I9¼ó¼¾»´sşÙÄ9.2¥§hÑYKıÑ¶Î¨‹ÅÓäÇ¿÷éæŠ5æ\¶Ğ’qp]oP? $5úDö3ÑÇÜ¼GÙ/:òˆFÕñA‚À^Y®`·/TóîJßùë Â_Áv« +µ9'…ì-?`oı’ŠÙO3p_ji½¤E¿ß¬NZê Û‚Ò›¸Ú1=½n‡ë#óüµİÂ8òÒ""´î±|x>%<cÙìÿì¹Âób"ç˜Ëi´’gRÄsFÄWOs1­††‡]á#¬êP@:¥G·x‰–X›âÓçx¬Òµ-2$¥ËÉJ¯’6)eÁ.¹øÑ‹ƒÅ?çÆ)dOğHs€Èl 'j™¥‰¡Â°Æ_°åé ÙÖSŒc™F_—Cı£{PuÙùtpU)ÄğË´¦Ke
/ú/Ké_©°êËÑï+ğ(Å_‘u@)¡QîQ<ŞæŠ¯ƒàùbWŞÂ’ZMKÙÈ¦™£Ov—EZ7J÷ê(­‹ÿãÛ ìi»VÌÑÂ ŸbnE;“¤¬Âíù•Ö†UNXšl^å¹Ë !1P9Å	lDë°¾›(‰Rhğ<È-b1wèôøœ_;‚9VÏˆø˜¦W…Dû­pÜÃå ØÜ4O?Ö¿‰ŒeöyXá_È‡­õæÜŞœö@ßdÒwîñõ¦÷4ä'9ïÓv0G€Ô;}ìVü¢À™ı}µ4é%â@jñÒ¼°ä†Õ¢ÿœ˜ú°W§U'È³%aéââşÀ½nAÊˆw¯¤±6ŒÙ‚Xò,xŞMu;K6'ğ¦Cü’ŸYVß²Â§r©È¹R‚ãÃÒxG’M¹Æ> k3ŞrtñEQ—!lı‰=ã,K¿<»È øHÍşa’g§aG‹z>$J7<b¶v?ÒÛüáÙ>Œ¤Şm1¾jE!ôÊˆÛÿpRÒ­x¼®/5óß/¼n´îş5iéÆ½E"š £?_4É:§	1cvîº¶·ú³Å†7Š†ä¢jœê+ ò‚­ù6ˆş#ç,˜ıì©¯§fo€b'×	h w–·9~µEÜ&¶€&•¶›bæİë©ÂûP’Êé#¿S»ßÖÀÃc|ÇYõ´f· ÀÒS_Z”bTGÃ§Ws?Š
˜1 û™]lı è@ŸĞÏÓMÆ¬ÏÕTøMå/Ÿ õnæ:²ÿÌ—ì×qd½é›y $=)ÎÙÛ”ÛÙG^×\—éÂo(<bD*WuÑÛë™×îw¢zÍe¦?JÏ{q‰e»˜™aç‚}ÎZˆ(rU±£ë3€³^¯AAbâO:X­hŸ$Q á¦8g­U'†Çû«Å¸E*-ùIkœ®éò8q­’4y0‹åôSk%“ì”h¶ãœ ÔR¸IúLïÿ‹îEÁ¯Ïì„ÚàÂS}Gàaîªp
h<0Îeš`ã¨¾FĞ6dUÏ\>­wVaØçŠh7ôã
¿#Åıèä}ïDb±«µœNQR<dfoËbh	zßÒZ”Á)‹ v0ğÉ\\OTõe)áÕ‹ÂÅûügM³EúcØRoë™y 1‹PÄ‰ZkëVi<£aı ”Z	pãîäçĞ¾Æ§@d¦v_Nc¦‚r›K57l”‹hÚô"€“3l<vğ¨–ÜİŞfBE4˜.;¢LmVÎ­yà6ŒÂkİì*»K³A\{,İnQP˜¨pÁµªï*- ršÊkÉ•«[V´¡ñ`*ÊÚQœñ9©·İ÷Ü˜—aØº+Oê¹fñ‡:ã™ÁjvSÈïtÊ‹‘ÇÍîÆL@?u«ÚœøöÔlc›‘³·–©ØBÿç>)-gkóiMAT€‡¤Šy(ÜÓ09tˆi}Å¦]œ²7k*>•„mü@]ûPLà=	×ïä¬¸w¡w¶ü ¤uÙYB‰ã&&ûVI$?×´Çä«CÍ4­’¸áªÓoG¢Ìü¥8|4w^r´£O5Ï6_T‰¿v`­ºLpÕTnTpàŠ.Ë¬&N ”ì×²»¬•åø”´u…³ßñØYÏ_zÖÎ`nª	EüYb×A»2ƒâñP/hf¯˜Q„€l¿éŞ§x@+L2¡İÁñ`™²¶1u¶«»0gë­KÃ}±>2é£Ğ ä­K©«¹m¢ıw°ÑˆzEx6ÿåùìcª ·¯$YÏkiëXÏù¯àÃŞ.á½÷¿­aóiŠ0•8É$€ÿ(ÁÙK©$Jh™‚£*‹±Å”á8õıy‚‚µjí	Ò×ŠÉëÊT<bo	÷±D”èN‚ó Jıi…BæP«’pù?ÇN8¸n(Ş)âí{btK~f¡yM
HC×ÇH£ÿËuõMˆ-Ÿî÷Ëş^òHpàG"zğÀnÈ1<‹l´Hê´û‘.ñÈ¥E£¦b‘•¥*5Q	[7j›è%"Z,½C	ÏÿïOwx/ÙÓ_—®ÂÏ•ôÖAÏ+—nÙ~mDá=ºê­G-G¿ÈŒL^LãC†ìâğhÎ(ÂB3%#ëí£ŒĞy’xû©¬øÄp6{_ú†êìnXr§4¾6Æ¦xãyGiùÒƒï¡İ,&ÊéÙÿ§¸>şé3'¾4cş[æ&â1éé—²\}.”†Îs-hXö2ou´j‡ÃñéÇPÊ Ö(7#+üduP§ÉÅ'ßæ 5ê"8ŠvşÆàñ÷·æö7Mï™û/Å¬ïAt¤“ğoÁ¤\Y9|/œB LHu	Ë@¾ÖéL´˜PÓùò¯0µ¡;ŠÚñ _HR4ùTxQÃô/ÃR¼ãºË«ÑEå;šptn(nĞt¦*ÇªÌ9GwÓV¤¼Û(ªdáw5÷P²¢¢€)İöJêÔÇ~J9òX†E6‰¬ÏNµD^å»ÊÊğğu6£àonè‘ªsy=©èåOˆrÍ:"ûÑÚÁ±ŞÕº¡êrjRS¬¸İµa¸ú=©,QÌ¬x÷©£±Ä@?;µçÃåZkŠÈ}q*ffÓ¿Î9çKZMÂ©ÅÇ Ke£"ü«Æ&3æĞLA¦†ÙÈ¤¡J$F6,«d6ş«ËÈœ
ØÚŞÍ¥*ªkpÉˆN½ÄŞÒ#Äj0ùI Y»KÙ	'}·ÔYO7‰ğ.B}Mßê[f]Ku.iíxpÙÃÔû^NãÓ«ÌªÆOŒŒ?»Ó79\Ò‘¤É3PÒ¤Á@LÎ°¤ÌÇ	DxrØ—A¤¹mëA’ ©¡Áˆ†tÆkøä˜ÖÔ9`¤ÎÃíĞ¿õK`ª2[«Š’…JAá,Åèş»—cıï/Lrğ;ñw;í@ZòêôaĞ=z J*$G/u“Ãò¨—C`|˜`,m¾C¥8í“{ûÆº1AœY\SQŠc´ö…ÕÒ€Ca5zÆõ³AÈèÌ©H÷‡(|ÂşŞ2)RH#ŒƒÆn<CE~¦ëK •·qK<ë —ó¤ œ¢“Ğ@^šÌ+Í[€4ÑÎ!.5›JìÔ<şöKÁb|ãäÉ2Àæ>7ÀbcL™ÍRµlj~¹—ÇŠ–6B{çœ°›ç[À’VÆÉ¼â±C
lV'ÕÔ«YjØ»
ªÆ=²`-à›{˜ôhN°†óñİš\´RÛú—óüGeß2¬sşÊ›IÆıµ=Èv¼ßÑßğÄmfXÈ¤Ü£w¼@Pûx™¡‰pµxÍK4~‘gƒ3Nr¦Üò’¨æ±šE=ÖlŒ©$X¾›/æ¼Ñ?Œ¹iÆ”<ğá/¨‘àÓïJ•¹â)A*éxË‰«>CJÒ¦³EÕÉ×¼f)3Å	e%ÉLğ5ëÆ/±[¼â{ØÈ©eéi¸w©\5s;–l—ºXE|ÄeŒ¬~y\C‚Uê ÿÉ±~I„#eÇvA ƒzÎÓ»sp?“(ã} .“ ×˜‡n”¹Äœµ)†.Øz)•VÒ&šœ×j‰Û,ú¹ol8å«]!•Ü‹>*$7²#u|a(iôÅö3”È3„÷ˆœ+jí©²VÁ¦Ä€éÀõ²ScB÷¼ŠÔ SaÔ#ZC¨Jwdg¬`ˆÙ~æ‰+÷÷~’.ã³`~’ñÁóª¨>|œFÛ˜„­Ih»ÇAÎ-1•Ê''ZìàP*ÇBoP‰ãha"³äéÕVœÌï26°s+-M‰Ñ ÷sIåX¿ršª›ö°îÆ{Ğ—ëû• ]7ÜŠˆ =2’Xc|Çœ¤p×¶l¢Ó²}^ïÔx^[ßá)•a‹šùùh.´%Î>îÄ%K£·  -uUS f¦`
NüV\NõÏõ~»èË•Á>zş?3Å–éÙó›¢7lìÍî{®ğ-Wû&˜HÎ€à´65Ò¸>¢cÃˆiD mŠõjäLEÀBó¶uvs°¶ ›/ÿÚ„*8<Q¸á,gÜàĞMaØÒ.d®­Ş¼ŒÍJğ›€| , j!}ñçÇ‡Tw¦º½D     R	8`¾KªØ ¥¥€ğ|–±Ägû    YZ