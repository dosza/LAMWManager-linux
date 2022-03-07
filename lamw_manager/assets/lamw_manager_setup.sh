#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="222478080"
MD5="0ccd7855e07af618980f15ec4f0be0b5"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26608"
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
	echo Date of packaging: Mon Mar  7 19:25:19 -03 2022
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
ı7zXZ  æÖ´F !   ÏXÌâÿg­] ¼}•À1Dd]‡Á›PætİDø”/«,N½‚+Şçñç£Nhô .Ã…àÈçişç®W­vèÚ9nŞ‰y˜||± aIJ°€·û!©™Ád,¿hqÊÎê[öË*ƒÛ$ƒ#_éí,áM†¾“¬!\Kïø¬.Á´=XK¡em5¬yùõ9½Yı¦¢H&Có&÷ó­«â<"!G>ŸÕ2ş?sëÆµüEdx£.ÓH^DšºQ©p.ÂJcÄôošã*ãêüN“—]úøy±’CZ†)E$w¢¦jß÷PUŞÆ±³-;}ïæ.˜Dg|»­åEŸĞìAÍø´G^¶êì¦æÿjÏ!}±t$ŒSºHi2ï˜°Gà‡Şˆ|¯hÇï]ÊwĞÚ¯¶˜Û\ôÒåkqÓPa- 0pV7ã‰ÍE¬?¯AÆï…¢$ÁáD“1i™ŞÒ™JÔ"ãª»H@&7½bÇRøéxìo<îîšò|‘&/Û77ÉF¨T=ù²R6-mÇ²¬”Şjf¶f yÇ6À”7€ÚKÎË²ï ¦¯Ã±ì)ÊÑ¶OÃsâè¶‡•ÂûˆS˜¾,»Şçp}œPù¾ü	ªXËcHQˆO¼ÿ-/-êÄã&­t&O¾¸ûEÇS Œß"r`ò'¦xÊ#JÉ¾³°„ò[¿Ä‹Ê¦Ÿ	Æªö%¢œî·O\¹éÉœşn—l2Ùƒ¥ÂTÊ“8šŒˆüOPq›@ÕÅÚumÓ¡÷Ñ;¥ÒzÏ§ ™Ô'ªñl CKf©ƒÑšô\²\,µpéñxºĞR°ş±V‘ëÛÈãŸ	fw(•º³«B•#"dĞÒáw¯÷·Êµ¿¢ë(ÏñŞ<ó[ğW"üô,¢ñú¡*³%gBz) ß«û-Òù"k ˆ;¿éÅ_Näì›…u]‰<àE,LõÙ›8¦®Æ’s&¶ä§µs¢¦å#ŞãJ2Aäñè½e~¡2²ñY•‡›¡¸ŸÂËã#V¶xÜò%÷şá¤ `ÿæv„"b9Y#FË}:\ÍEgc^Óê˜[÷Dñ×Æ˜çf§ênîçr¾ÑpxŒÁrÓÖÈ6áç¯Õ,+†ZDõ9:‹õæì/šôz[-­÷c›úÿ‚&ò6ú2=$BáŞ!\æÆN!t$°ï/“Y>œ¶l9P5Dó6™S-í_å™Mów°’ĞÄ¥¦ŠQ,\-…w,iÑ`HIS$ğ4;¤]CZÍ|´nÕùy¤ãññJw°”L7P?Cƒ¬ëDÈ¦R^…`¬°Í•dæ›î·ã9P¿È«ñ¤™l­Ukoœş+ °S¾• ¹h¸xÁÃ¦pW%Læ†Ìw¡³Ìæp Kö.¯F®÷Ò{
 Óõ•¬e.Y&ÒüDv>-ÿ½Õ=k¦ë«{¦vìN¨´±üôB„¶ì¯ˆÀ°¸fúuÔ„›z‡0‚ö“»iõŒ¦¡ôÕÚ„ÆıØ8”©ör<»Ö›ùW´¾½˜€Ø~­Mmì“¦¿xPŸ›Ñ€u‘tºbòa3'æ™Ïâÿ<¥R›x#ç"X°šDùó‚ëïğä>)•E…SêÏ½ş=¹(=A9r,»ÁlÓôGğ†´{Lxºà}_i¿h´¢‰[ãZ+× U‘’&Ñ ‚º?•&1[ÎÅ¥¿²öBü6Ÿÿ¸I´¢&ıß:ò|=`®,æ8×ªz)“²÷6å÷]8{	ë]Ÿ¤GYzKœ¤x8\÷–.Íôõ‹Ù‰èŠhPÄF!ûŒ':Ì’B"(ééq¶ÿæŞ5T›	íi4åß Ã´ô©ğ^2K‡À€‰BÑf·Rì>y
b7,øÉ.R†
w}ÄğÕ+öŒóàA1¯+lew ²AšWdq=	Zr_ÎÊ°İ©ROÈ-í ‚ğÊğ}bÍë'£ĞÖ9×oÔæ¹jtëGOò=§·H’mUÔå¥ìcürØĞ†ÍA_l­¨¨œsrËˆ,üÈX<\mi®4æşBJ¬cœO™NºùpÄñ¸²ÿ Ú¨~ÍĞÆ:ÔÎX?Sheçzkyïª¡JkH?Í2£–Ò‘#sø©_~	*í¶‚Ê0#ªàïÑÀ’$“¢»9Ş¤€„$»kù>åQW×(»òTC é3‡ûk^ówx‡¤Ë½oé $w¾!c"Ö¥4`__äÀ9Wj®–/“|I:ÖrlÈŠÂF
/AŠÜYËÈVô;,NöÊ¬–*.…¸ğ ·î€juIB¾=’S0ÕßÁÙáù‘¥.N=µª¾N-qıuIœœ7^{×L˜¬>æÑÿ~BscÚR‰K2‘UmåëØâmÅÁôûU¬¿T+ØÎ—EÑ»"ğe³²iØ¤ÖmÂ·SâÕ_éÑön“YÄ}>ó®„@sïHó7”ß…h#@Ş,|‹°ûÙJ ®œOˆ4ŸÒDpƒ†Ç”ÎHËğX˜ZØ¿u®Ç¢%R XÏcoÈö¦Õ]ÇÅ¸4TÁñSò–Q£Û$Ùy#tEïÿşHÙaªÙîG›y¬uÊ—^7UŒWßZö$9:®Om@\<ş|³¾íØ×*\ÀÕÜzä+øÈLhº¯aV—)ùÑ%ùÒ‹æ€râÌmÁä‰}¨ª¹ªyc‰`÷¿×`:İàÄE~F±Qp õâD$ïö§W¾íh4¶ÚL?zîØÁÙ¸‰ …B)1Z®•şDÊIKş;`SD¾£jI€ö¯] á³Smø--ö}P¯3ôg¨sAqÕjGU~v£x7g?ïÙ1ŞGãóé ÌèÅyO»¿i8/Ÿ\0hV°b_Ôœ p„úÓ»Àâã`YmC³«T)¥\˜V›ÔÏè>sMÛ›)Ø†TŠ¤OêĞ÷>öòáG·Un¸f¸2w  š…à…`½£êh€8/òüä‘dœ€2p;°ıÊR~£Ê+âÃıù Yt Àèõ3	âh‘“àµ‚"øŠÚÌ·¸î‰#z¤Q2ÉÑ¼ºƒ[É÷•‘+¯rahÙÆîqY‘ÄÜ½<Ò,ÃdT\\Ü¬’í–ªªôå$ÀÜu·YøŞœ±´v8Ñ2ı|B~]æÉùk/±¦K²G öéU§­/ˆÕŠÀ’4{ªwºO†¼t8<'
İ
ÇŸ(sœñêÕ)HÄØa0ä¸ˆ€)u]P4ñftÙš®<µÎDúÃ¥—/2à8‡¦Kê§õöEZ»@:^íáZ“>^½4ï‘+ÙÜˆñP^ÿµ†3›_SÑÚ¾Ÿ—ëkª…{qIê&èPŸÊÖ¼II=B6häR–¬á_&Z™dÕáï¶KïH²%!““*+¬Gí*òÁ»á~(th—O!â®À1Ş·ÅB€¹óàüÙßé‹–~æ7µ)\]<õh;‚pš±r­«£öé—«Øµ5D‹(*U•ÕC¨•ºŸı^ª±¦•¶X|ÕL;MÇŸÌ%“˜£,-yd	_¹aöŸ F†\q˜ª($è5£È”?è[f] hzÔû€õ®Fß™™(ş]c$r(å+Í¤8ƒšcÒf5ÑÕÎÓìÊ<V'³>R5­d;Qæ«jªØ$_ß«UW	`U×`Ãİ³qé•/cÈ®C¥>ÇÜx4é“icÁ+>©DÒ‹».qŠ+½èj¨bËâ&á–±,\j»Å…ßĞ
@6H³DÂ–‚ˆ^6´ª¾­º_’øÒ`a¼Ô~Cİ¸¯Ïõ[`#—ø_ó^¶c9©1ZM¬‡H¤¼°¼›	ö`^Í¯QRäJjÄBµ8$·«ëİ+×Ö×.b6¤èÕpG	¯¬tÑ˜¸ßó†=Bmë>r\Ã÷c·‰ö¿Ÿ3²Ôsèåƒ<b|N±&3õ¶ğ¡	Ò…À])’Q:^š#½63×ZĞh¢Ï–µMN/&s³ş™¥^ò‚ïh¦ãl`z²ù#Ç*.Y¢j¡'goˆ1ƒGåOº¯£ø`NbËov&½;m}#\Nó$ZÕß2kò.MÉ^¢ÕÖ2±¡.-,o°ÄTû”Š¤Ş
­ÌJ=´‘3ÇU‡Î…ı[|U0Ï±Ø¿
 éSjÈ;¤çúÔXQ%d£$Ñ– `42i‘óÂÀ=[´7RÓµî£¾ºñeuŒ ìai}vY¹–™@lÁ‡ó—ø†óigóPí1¬Ìöo¬RÛ}ÉÖsà?R\0ë»“Ô¶‚³"r†sP€mDÓ>£Á‡èÚÕ-LCAµá1áœ 	·W÷I»‡-:Ö_ü,É`ÃŒCÄ»Âô´=Å™EOo¥ÊW+†'GÙõJ)‚æä	Ï³°ü2íèÉúîT+|ñúçAÔí É°~#\OùÕi²°5é_€ƒ	âãâ¸ø6º‰Myÿà»ú+Ø›t&B4˜„ô—½€ğ§¾™JÂy>/*7·˜Ç™ä‘yÓw‹cæğnÜa»ºüUõ¿yY%7Ìa„Ì÷R³çI*§½f\Ò
k˜Ö(1+È^!á…v<ÏhzÀğrĞiîKÅ[î÷Zdî½ıq#ÕÔtÓ">½W3 •VV´&9?x°‰Ø:5‰åŠd< ;)rq\ VŸ%p”áÁÄ8Üû|¥à‹¦EBgatšìÔñZfö8ì)³8(2ÇÏ,­!D11êí×•µpoâğ#‹Šû»sEL>µ/WOFùqE¶\ƒ .Ä°FŸ•Uï)7çS[úW~fÂs$O7Mş6"!vÉU·vKñ÷ò1ÎWÕ®,ÕL
—r}èÚŸ÷<GóÖXÒ´¹+gñŞ­¯!aH5Ö˜×P¥ò”|¨¥²Ø£ØYx)Œ{¥£œKèêË \Dp²'Õé¬±,Ny't¼aÊÎÒ½/ü‚øf&ˆÛ)4.ÎÅ?©áÇÿ*×ÇmÉ ¢;9¸“Ee/ª6‡•~§c-™öÛj¹oâ´ÚmvnCïŞmÇØêv‡Õ 2VB)· ¨„®òzŠ&ÍwHFx‘XÅ;¢›@
°Äls””öÆ–Ù8	Œ+­y]’ø‰iˆ[ĞÔ@ßA]Ñqù@ÇcÍò6Ïğ†øò€aÙZ§ı]/^æã+åĞ§>3EôxdDÏMCs´¶(wuuÒ_ŸxÔ@Ös—€G¼ı’¾›+O''Ñ’°ê±WŸ¥lÕ½æõiÊâ¯kD¹{72¿goµP¨0ì{Œ'U•]fnùxS×¯†ÁQúÇóø¥UØZšæèÎÊŠ<Cr+½×i²ä…Pì™SîšõñK5#•¦åÚsÙ|¹ ŞÃ¼¢å{¤SCüå8ı7æûoÑ¼ösók&Â"ªàv"Õå‘¤²#c×â ‡a¼Â<m"Tô“4:8’ó?{.Ö§3XÑ^ü=*^“Ù:!xÜM,{¦gi`O2İ‰,kÙZ
}d9¢Âğ‰*˜Ò.HÔk6"´]7+Š€şûŞÜh ]Ñp€’KÀ%|\lˆ™\•FjÚ+@+T_gÿ¾Räg;!ø:™x—4 }µ¾8ÿ6ådtÈÖwıGC`4ª'rÑÎ²˜^­¹7eu7IÄ•‚G	õr˜Òø¥ªX?eİ˜í¥Q“¼>ÆÍã'Î)9–ñe’vùš2vá’­jI*Ë«7:æpÆˆ&„ı"•ëv•H‡–Jíˆ'Qü‰FK¹ù÷ş1:•üUòµ9ŸGŒïGØ»ıÜ5ÆZİšñY×œ5%„ıÑ‰èÃÎV*4iÇ@¿x1<İøíÈ ëêMÖJËšöi²iÙBObÑ-¤VFÀ§—8±¿ä1Z¹Óšñ!cÖ¢·ŸÙÙåtˆØS×íDöğq¦c,À¤4ur]¤ŠnåÃ}|ÑåBŒ§‹Õ¹şâñMÀt‚cG6Œ9Œƒ²÷"=_ÏØSt~™7–Š3ÊJ‡–uhzUÖ##<Gô)„19Üè/RØoı}ÚÌ4’X%U¶xÄ-›‚P§¯F9D%`}ät®ø®ÜùŒQ÷NîÌßMÊÜÙĞ²&ùvzßb(©QgV­Â/³HÙÁ!`,'e~;/h±ïÛ
4ÜÄG#?c»ÕGY÷%¬[/­ÆJ«‚#Ğ_kì[ÈG¦Š€œ`ÓmÑ—0‚õUíurKM<ısUÜ‡uT§¾©eRàÏ
|›F²#¯Gy”úáÄ­éLó~•-¤4œx¹J‚±óıîoRîn¼Í8¶3­
â¾úàš·ÔÀGßÏôË¹zšdÍ·j­9p™ä6‰eü|RlBa¢¨OçjÔ*Ve,!Š]›®ÀV¹¬cŒP±) l´Ä5â6Ş¤‰X+yV£Ğ¯
OÜDYQ™‰oeÏ!oŒ¤
î4usIBš-3¨Bù‰Öósk?ÆO’ı`Eç ˆi÷-È;@X.(‹bw¶¥x¯IĞUrZ<*Œæ÷I/vtÚ˜k¦áû M°?VßW±=Æv-Ï[¢|âuq,õFDÍô¡wŞœ¦Ìşw÷6ßèMZ‡Ç_u}lŞUãú¸nX§àÍ¥ÔşhT½7…Vr¿ï¸ï<ÑbÉ§ÿ_œãXQ©ŒÕ¼¥NœJ-2±¨¿Ó¶ d%õ>@é‡u•öÓ+8KFñ÷= ¿í_r@ÀÈ•&ˆâÊ>/kúá½>ñ¾¤'ÛUâ:‡âˆq“[sA«ÃİcRaÜœÌ3é|ïÀr¶·Kaæ¤ô… B?Yò†¾8­)¸oªD|Êò·şLÃ‚*qíãÏÜÔrÚà¯RÁdÁàŒ.•³¸)‘n=~Wˆ7øŠm3—£nX†#ìÖ1_ÈXç¨Nå`° û"º½-½…³Ãthşª‰;ZãdößæıP7ï³“9j··•[q*Aƒò…æï(bÉ{X®~;`B/\¨²ä)A›{Ñw$çÛv¡WÖ1;ÁéñVÀß€!úA¢ØQ²€jö#!uÀæV&–h"_ešG–¾¿ÔZ¥¬RéÛZ8+	;]Úîsm‰ÃA‡Yİ¦Ê£r7'´ÿ¤VÔÃ®X]37‰*E ÅI¥ÀŒb¹Š&W+÷m/«´%.y×¥Í¡´c›&”A/Z2ÌV	(‰P§†–Nü(4œ!,éx›n‡ï”˜ãÏÜñäU^Š-ïuİÎÊ,3Š€"Ş%ñò€Œ_j„' õY>Úğ>¬^[ÁÎ“3$.»8ŞDİç$¤âÈFtvEe&“Ğ'ße*vI8äïßÃ[od ô”ÜH,Y/ĞhãÙ‰.ˆ+
Wšÿ]Fƒ7²ÈêıúÖŞ?şŸ²¹Ş¶˜3Öôñ€fG«‡”æ9`ª³QÔÖÂÇ98ş¥ñRøâd¥5VƒAƒ²1üO‡àU úÖ–Ê}>A×ù†®ˆ± —PY¯¹ÇÍĞò`´<šS;‡ŒÏ3=H!®’½ì¿(2üwÒ6qñÿOÚw0£ñCâœí¬ö
¿uMi˜VÄRû]?*ŠÂ¬upC[³î§ ·4F·§”Ğè 8ÓĞ©‚5)×1ã/Àğı(—5&ğyIFBØ”Şå\í’4$É|‚Ú°è„vìt$ÄjMì¬lµIäÍ3`ó—›Ì1 ä}§ÁV¬EFœ~:\N‡8>‘#ì®Îc±©{ƒm5”¼	G¥7¹¸T©è»÷«êŠ2KzK,maÿ{øCD¾²È•´ÔşÏ^Ia TœeSqß>d5ñ³İ"C½]¿]ÅÏJ
¸äs'×T7|Pcëúî âEñ.Ù“w-Dè´<z„€Ç€bÑ‰AA÷O‘Â–§`†J’­ËƒGö~è9­?»ëğ×Rö2ŠëÂ ¡'1½÷-©3ÿ ÓXé¼ª"õX\ÔşÇĞK¬õ%j¯Ã}ãİ‚ÖgûkñXé³wÅŸ=»7²tkİdk¯»¡ªş¯7o„©Àn"á:%¨7Ş5?
Âl"‘¨G£Ñ(öFş<Œ\ïÚÍ†±Íe÷µåSŠ("	¦^Ëø%X\«Šœä©Œ¤B²mŸÇµû ¨ƒŠ¯j'â³Tô†óVºşQ£aWïc&Òï{ÀHÆr]·Y>yÃ°z¯)¥¾@å9EÔA€B¶F€ë±ÓÑšŞfç›v'Â=…³± Eù«G7q²Ğó(`I:öŸr¢n>>pï²î(ËHTª Kâ‘îq¶ä1BÀ=ïq™öÂ?«Ë.¸Eüí‰ôĞ%T[Ò/2°º†>W{&ö ª1İ2úNa~c€­È³¹Ô‘§~)àæ›Zí‡§Ê9Å_~NĞsC•áŸ»7ùzæğ&ûKˆïÌÒF¶¢¬•¦:ë4$û©K+8R?elâÌ££äbpøÛíMXwµ{?Ïíª›÷<³f™@öã|–ªÎN¢›§LS4Ï’ë
ÛI§™WF§nOè\’*‚á•k
7Ğ8Ieéjûepå«ûñıÈÔ:*²ØÊTy¯\©ÄÃİ¶“‘–>0äÙ§>Ø³?u·Ø¢û¸Ã§À=¯Ğ+2À/u¿³çIÃ Ã»õ‰hq³ŸG»¾ük,¤~Oÿa› ~C®é¾,0Ì‡¼Ñù@Å‚ÁM¥³`{½q¤fíÌ1•JÉüt!ˆƒßÀÙ‡k¤×´×pH¢éú
v×Æ.´ñ¥yô™¦œ×e`pDş\A·”}¸ÓÒø¿_v‘_F0‰Ešˆ`¬pLªùÅ:/7x
úh¬hÑW¿_5 ô!F÷€i°ø
|Í1¶ùmˆ÷óŠ¦’òÇ™îó¯Ó½ÓfkÎb±èµDé«X"7°•t86"…ÔUÅ¡klÏ„ÅüÆ¾xm|§J{ŞCŠFr‹ÒQöp÷‘Õ1Ãu³€À0¶Í
¿aÚÅšãÀe¸€)
­foq’Ç¥ïÚkW» VxNt.Q®Ï§¨3ïŸ
Æ¨›9œ_6‰ëRÇ½\5N “6›=50î–·$ŠûçŸš‘H¼ÌÛtà›6`òt›İÏëÆÄŞÒœÎ2ë‘é · ¡(AˆºR:Ú| š |ˆ¾D±'ÁTé8y@I¿±Z¯Îƒó¨ktDÌª8ôï€'v¶!0½6Û+ÆŞ8 XØßíaj„×Ì‡ş"»GÕçÎ@äZ9s3İñUF¶ç=´Ç»5,ÄúÀ¶g.EÚ3ü]/Ìnš´­Èë1Ï*½ü$TâÓ×¥™èÜ%ªSO…˜ômR)•^R¾@ÁwËÂññšjx’Ã¼oú¾º‡È*DE“9Gg-gÌ¶byÿŠ·¶°Jî¯:Ü0e<â’yªïä•{ËÁVóR%}¥êèè¢Bïæ¯¼Ä"æÅ°šë'V:Øé#‘ìïàùßiCÍİ#Ç»ÒıJºe9Îs|ìş¡-%QĞ3$ã™ Gı°djâoÒã-3Ğç!€ıv@—LŞÿÎáéEã'`
gÙ¢(ŠÒìÁÒ×Í~ ½A¨åĞpüEEz×]³Şó"ËÜÛXÖ¦#âsÁa@ËØÉ"ò>„,.	n@`VÓ PMDo™ôH8MÒ¶ö}œÜ‹Ğ±Ú²€v´noĞi¾á£_áîŒÿkNÙî+æ½§NÍƒØŸ8š\.æ?ÚïÕ›*!ÜiZ¥ç]ÆœµÒöî½‚0'—×bæ§w’ŒèŠ0ìyÇËOÌÃ¼´ ıK¹$!#BÏ›İlrâfJo8ò+÷ÓjÉQT­ó~†Ç‘íº°æ›:>™¹GŒ®ĞrW [&DìMìÖk¤·ÑˆòûU¶€	5>(uÎßP/w>Ú¯k·Ê®ú­g¦À
:9:˜ÀÑâÕáY_ãÖy>Ñ“¬¯Ô)¨¡Åt1UjôtÄ²¡·¹Y¬3ÌßàEs;!ˆÒÜ¶‘©E´Ñ|Ÿ´qÁ{¬X_Ò2wvœçvsù‹1Z’_†ü Ì9ï"=$ñè«ª“ÀœzÕùˆ³1º\+Övôacv¦E¹zYÜã»1·İ-P)ªB7hkúC2;†Àİça+K¸ÓBkí¢£$bÛ@I(x×ÑCâùcˆ{»š¥×Üµºÿ—ñóŞ1Ü+låY°—qŒØâ±Ì®Æoº ¥JÑDâ$ëéy†oÆ®5ı:‘+;5t•[lIğå‚5	=3°iz€AÂb]|«×@¾‘’iúÇ)Ï/…Ã²Œ7¨ÇÚ¹§¯Ï|W¥O	ÉUé1Í"ÌŒ`Ä!ûzSÚ4$ß)6Oz›ÊÑ+J|AtEY—jï£×¾ÈæEíå=\×{ôÕ-ØNººË•Y­§8TåôâÒåiÖÈò‚¡€‰!! a‘Uéq9æˆ;¯%j¼Èx½ú.ó±O÷Ë0s‹«Ê˜Ú\Ã¤BäïÈôˆGş¬dÔ¹íÊ-I5ìp5,UFn§è‡Ìv+—º9rïÿıœè½Uáe;z$es—›f›”™Â¬Ø6ÊãQæ7)+kM5U¤ıŸÊ÷îÈêÓ—ÂEÊ¢Rî×U´F
}ã_¬}§cxWØ'W´šÍ÷éXÛÀN…‹˜9n¿¹ÍĞÎÑ?4Õ«2òì®öC<“`GHúd+œØû‡¶DhK(=ĞØ[³7Y9ÚoÕ,—“Çø]ç€MË²¢˜Ğk÷P“W*ò©“Q}Ï_¨Dr™ûöoğÍ4A­ªèÇÈîVcúÄúYÿ(²c:¤¼VOr‡ƒXWHŒ^Ú€[õ¼DĞ>ÈÁÑ›·j‰ù]ùbÍ‹Ê•.Ó=G?:ùe‡ş°†-û^8•?U6#wâ+c²4§%Ô¢œ²28OÆIÿñvô“3ß˜[Í,»¥%Ñ!©§·Üš7P¤¥¦~¡Ø h¯$šúuÀÇŠµˆÛğ/Ñ÷EµJ[j¥²Ïµş[ oúÛÛær˜ J±€÷œ„†’Æ>z½=kêm¼|çßFÛé§İ¤àU-X¿%<TKŞ®ÛX¶5+8TöÓ@	¢ş¤jsŸhÏİÅn¦Çàßb²VdœuÁCãÇu˜m«ÔÕ¹½™‚Åõä&·T9¸p¾ÏĞ[¢G9Ÿç‘'•$ÀqÓ¸KòÜ=?¢•¦ÕÏvµP"ÉşKîÄÇÃÍp!öú‘ƒx’ÛVåÓóŠ8ñKs¬“ÊÉJĞ	À›EÃ;jZ»¶_&Ê6½x[ûó9vÏÄ?]n1)á3ÂFédüàªş†¥-9¯€ÔoÛ—µÎ»2ÁĞæjGi6îÖIÏ;ÛS,–Dïçb»ñxâ¹`MYÖÁnÌHGqûŞÃä²¥'ÏãAÂgrÿ)8’Ã}€Ì«äóà…™~dğn‰rı_îw!k†™¯Â¾ÛKÄäX8[òÖL3+èÌ~ÎÒ'uÅè)ÍÌ±£«İ½¥c„Ï¿ÁoÏW6Ø_Ÿ˜ş—‰¤‡¼ásàÊzmy¿ü–<ÔÄ½¨úOÂï©¿Ü/\yûèY.²¾äï¦²ÈQššÜ¢âŒ*øe†0Óc<€1èĞ„ôœ¯UR’ÙœŒr:;Ø›iÚ&$ğê´–Óm$½7üŠräö%óçÓrµÂ1N´\şP˜g^?$)jE½)¿w%	aù3ã!^iZK²€Y;ÛQZÙ ´´`w»Yy˜ ¢Æ­±V½rÃi–‰Áœ†ŸUœƒåéW˜VÀü¯¬x3’Š¨®¡ÙaAşàs@˜Äl8İ‡mCºb„|œpï*ª[ß¤/ª†JYÓœå!ô‡á¸Ã|Œïg˜g[À&<^eRâ3<[˜üRŒ÷­ŸGù  '’®d"€âæKÅõsflÕòÉõÿÇ9O&¦mÖ—!®ÅWwá°ĞfÊãDËiAÄçî9UÚ¶2IÈYëÊ_$[ ûpŠ søÇ¤r§”Û#GÉ)ÂHìzSÒ@+xß›Á†
ÓÍÑR sÉdš)X™ñ@’ƒ™<b< qBFí k·Õˆ>yhæ#|	Âî»RĞ¢¡¦Ù¡U5ÖQDR—àR´‹îBÁÈğ’ry­Vv;‹³^ÚöÕ‡`	Ï¼_ û¦ûgÓÓ,g‘õ<##£ƒœ7«nR¸ÑîL»61Íâù¥ P[U]o	{4y`åã›}ìê¡W•‡rmÊÎ£ıJ¡ ßq-¦YÀM‰ñr™Ë¿†¡i‰…d÷ş3ğ8à'sô¾íßˆÃ†¬ŸÓ?”é’{œ×ïü?)Q»‡½ëãW3ı‚Áÿìf¯ÎèˆßÅõlDçÍÓKtß8µL„'*è¡"h{VñÎC.×2ãtZïÙW3kœ_èVª/lk{‘/Ê¶WŸ1Ó\UöZœ+<ˆÚŒIqxwUş.h0ãOçcƒ:j‹˜FÍ¦,:âhé>“ Ö”‹ù{›LJşãĞÂ[¥”õ¡Y[W†.:\WLëêtÒcîéûË€£ZC†&Ìú#·ŒC}‹–o‡ïªfpÂBèĞü˜b<¼iô¢Éq\3j–ßƒÉ­ß ÍÊ>‚|“¡¦¯¾ìA˜ØÔ“ªğ\zNfykr8~iå•¢{Î×<rl$ÁCNæN˜+ú=’aÙ9İheælX,~¾PÓÍ_Œ¤ƒÿ¥ÏÚ+Ğ KĞd³À @Âí¿0>:¨˜Ê™& Ø~VQD‡ÏƒŠÏîT—5©Ï7­ğƒ—#Kuª,Á•WpÙç`“$'¦r§sªÔ<A%c)úsYM÷7ò¿<»ôgÌ)yó¹Õ½°5˜_m¿yäöíL[KâTQ±O˜Ú<0Ãc·¤Ã_fİ–Æ°D¡í"*eµrPYÚVI;ÌÖÑ4>& È ˆ¤¼‹¥xŞ•V’WQ½Æüâäà13MÔ&!qìLg££±Ÿ–Œh°”î ÈìÇ’¸ÇƒÑs•p$x™SĞ(;0"ÍßUf­5b¬îdÉêŸ	¥l!/2ØşÆ—zùÿ
àé—‚€ÿ©OÕÚşáµcï{¸¤•­»ÏA`Ò¦áÀµk«“w½İ¦¹ÄßŞzl=×Øg[ÍTÛi½ 	|0-Ò8Lál];T&v/Ã8Ü!¾”áxöÆ°ÅâGl{Âƒ÷/&ö¾µjP"İ<ÌŒ4İUõP¨au9ï¤áëìYo©}›²òyÊÃ_ÏÀÎ¨¦pÇŠÎÌñÚ9KYC@Yá¨ï#­lzplvÎ.U¦Ú/®|’&¬E½%J·jù~99~8¼rC	Ò­´ 1/ßÕƒÑUkéL ZS£Ê1ú9gœV’mïÑQüc¸"sµ™!
¼tXG`3#Ç)mîM–¿)¶bjäù¯}qÈœÉğbË†JZ'¦eB2™„Î3ß4•u¶=]ˆæƒKQ•p™ƒLî3ÈŒ™À_I³O²R$´~Š>:A	¢…”7|î5óar!ı °›¿¿ÎƒÖ"ku›ë~|ò…[Nß’SÁ@¸ñ¿¥éôè—®mM^;³âjDW.Bt’J]ü<>±:OJ;x—Ö{èÙÒœS‘ocR¾ÜdÃkàh€ïê4K…xÙd’ş¢¹ÁùT`±–¥êf¹“i{ŸŠ/ïu8ú±:áQö³»¿4"î]ÁGË‚B0¬,²t"5k§c½Æ’Eƒ(i^}¤ç·naŞç¬×TxG¡8ezËŞÿáü€OFÂ¸Â‰ä…íè˜ÓeÒÍcêQ>;ôŞÅÊ¦¦AÓ`iå¤1ö¨PÄ)Ø„ÖFî„D!©’•ËN'µ„¿hÓ,XS!È°ÊÂâMW
	G»§dÿ™<êg©tØÎŒ¦¯2N+Îk(éÑ‰Ÿíùï\ÙÁ&9–½=u={Š÷údÚõ×az¬&öüØù'-ÿóSó˜Ä„!xã¶š½-ÖqQ¨ò1{›¢»Çşs´­^ÂlÿË3Pà¢±„êòÃf/ja!¯P80ßşÒ7€µ7äe’*³îòß½ê„dn½=Cœ]?¼ÚdZÇŸ±úFj	P`7C~U2‘ŒÛ"’°}#D²Qe’.*ÛD–>â0Z‹2å‰œıeXì"şÃ­™"ò.MDr£¦_¼2Á‘®AfôwãÊ„ËQQO‘…ÚWäB“ZŠ8˜?utwUêU€C…ˆ‚/îE2d€¼	B¥uÃa¾n§_„mŒzº}…ÌfÇ•(MÖ½Éô#®Åá—\“ZgQ&÷íâ›òXò³9—™à•c¥q4.uJé)‡Ëµúhp¨ñ:0í“ò >õ×¼—ó1?,Bª!ú0bì•ûow–Y°fB[ÅÉcw¥[’;Î×š8\c
]”]¯Rû¢{‰YÀ´Æ*á8i~=¤ÁD[uPÜÖš„«ğ¤Nj‰ğõ@ïjö_K{pŞ§öQœ•)/ NÛgÑZ^ùä7™´ûKçó¤£¿7¤6ûLşı°jxJœ²b•LÙ6ÍîvªX$àç¥¢;×Iú#49©·†»Wîâó*k…pÙµe}éÍgGæ,³ Ü«#'£û0¾à ³‘#ÒZuÄ8óö=ñ§í£Ïn*Éñƒ.§ç_J(ëi‡5âƒĞ@³Y¢+Åac½À‘ajêÎ¶i
™‡²F9p¡èMq³m5¹œQtn\%|[HÁ	ïS¨M™Ñ}¾ói…Ìtî?8Z%CÎƒ´5´49`øqh‹Ü- 	3T„î,‡Ò²Yd|_c‰ì9_Ê²*\B`İ‰`!&Û¢"åDÒˆßy"|Ï+.4kğåÇ“€ÙJ‡¼åwG|²ªÁ&hâ?Æm3·Æ„<œœ˜yÒ„#¯8¦]¸“núQ¢ø  ¥cœû/v»\ÃşåšÙ.>½b[Ğ!Ïo¢)ş§æ_ò09_7 ¤)úØ(Ï¼áî<EcüœBí‚Ç	 
,À#­	tË`©&‰¶ÜÄd­Ì¡İîZÁ=4£³šJu2pFbÅ¼âx[Ó¸ógÕÄh©ÊûwPhju_âë„f¼[´èæ´«ÅÓØtĞªœ–æ˜§n†€·ÇmB¾•U[û/¸¬äÆ=p£$l¸.ô‰şD¦îË#Ü\Î3krñ»;mÉÍqXøÑÅFÌV5îíi¾u6$ãš–ºúGs&µ:§¦o‡ÓÖd³òA‚%Ø·RãMF?Ê$ô‡-+$‡-)KWD¹úp¡ÔM±+YÉ‡L?ÃAå›uò»Ğ(C §Ä?&X%¢²J/ıÉcÏ<i*9ï”‡Õ
ûôÖ.”Eü+ftHûEJÊødT-ĞºE¨VßbcŠ—×÷×'Ğ+§ûIYûJóºE†±­GåâëUµë¿ºN‡ÂÌ(½$a¥®Yøœ¥Ybj¿2
ò0¡ÓŠai¡temQñapU’¥]Oßa3<â‚ñÁË
äÑaŠk£v	(8J¯ZÏ\Š,€UUI2ŞÓIp¢ehæ
×ÊÛ%ïò"¡“şjòi6f˜}-øÛr0LÈ®hRa¸¿+êÎé„(ş+X¼
ŞOÇ¹ÏÛì0tá{æõ‘w†ˆ˜«ß,Kg³†X®¤œ;vó8Nˆ¨ÁÅÚ%qÉ¾gdw‰9&×AX&pQ“{)úÉPî>Şæ.-QŞï0AG'»c„—ê’·¢¯*"C)2¶î|c²û–ÁîL@v6„<rT¹ye1¾®Dù„Şön‰ûŒí3yVı~i8æÑ;Av–ìu’«–Lt‘)tL. ‰làFÔô‹¦ãb÷»#£ûQæµÓ_–!!Ä0|^QSjl•_•6†XRQéí_«æaœn O
Œü²@Û€93`¬'oõ{K WôİÕ®ŞÁğX¦7ìJ'rXº&¶Å^‡¨n,ğBŠÓGNVÛ=÷Ô '™²}`t¦ú²_nÀ«ïı[¥us¬L®K' § "à3[-x-Æ‘x§úÍa³ú%7Ÿˆ:,>I"%ì®vŒ›&Ëƒ‡‡VwßÆ/:Ò†T1ûôç]D¶ÂcÈŒ\ü»àæ¦Ù´tœŠsE<ÂŞ$KPg,ñUÙ6è“Oû6©dR?„¶púxFëƒ¹é¶HÚ¦à08›Šö™`7˜jÆÙú™P2•è8(-Ï¸î>Gbøã#ØÀï'ßåf¦±9Á™Â¯c¬[ºbç÷%§[QıXk–"W&çÃ»¨ª»„{]…ê=|œ
\¡µ1İƒ¾êİ«•‹ª #¿Ê@­­bR9‘g‰[ ZÀ†…j0;ğú`ËˆO¥lÉMãö¤šJ:f›ä²§î ¾,ÛßSÉ, ÿ3 Ó¼1˜ŞdJpƒ’F¬|3š¡¿İ¤ü7…µ‚9ºkÄú¡í–VSLÜö3 SÔ]F¨[âST3¡>ìinÃ!¢sü Td±}&÷"Äqï„Š…0 £èÆìŞ§Kqë¢.¼»Å½Ksè1Ú÷3NJ˜­zfeS¤,ÄóµÖHğÖ!Hµ¢Ç`;öÆô
ğÀ•§öxAÔóodâ‡‰ğ™„¯VrÛ!eu¡Ç¤ùÌp]­iEjÌpòB•å" `ÊºddK›ê›.-8~ÚÂo¸7Õ>?Ã.‹‰%¢¿£ìw¥ÓĞŠ3…CÿŒ{*‹Â}Ù­3`Œn°İôç€ß×îâ<…uŒÊÖ5õï]áû†Ğ²k«ˆ–ÂFúïc×$'º¨Ä¹xîã|$\ö»[ô6ez?‘ñIĞ<ˆ©6÷ÍT’Ú¡ÅKœ¹ï<o;Ÿ,˜¹¡W/™ªkj$0ÏRıôôñ×å÷Ù-FÉ‹Q8æûöO-fİºVÄÎ…Tpé¾jdïºü¶M;{ˆ÷Å¤Ğ]é5ìÛ9MOº|)»k’Àº:#À GHó½Dæ5Zê3OQcrèÌZèı=†ÆcĞRM³¬|k¥~F¤M>ûÜßÙäú“r¼aY½ôÈMVaPïÂ_d7ó	Ö€×İ:»»OäÆ œPÖMõZM£ñµà	™ø¼"qnƒ-Ó	êr?"ÀNÒ|SrŸOG&ËôwjnÖ…ºØzF‹eû¿Õëàƒ<ÿQdt‡g*ì+™JM× N°xèwd¹±i;„Aâ‘“;ƒ8œ|Ê¯kh8'ŸÉ˜-[_[¢¦u¶É¡rÖ°¹íD÷€J@v;pp–¥Õ£wé•…šAF3CXD½æÓ v‡t?e%m`Ùt_ƒD¨º!êêN	}Ü57h\Ôg9I•“M8ôõ6‚£UÊkVí€÷Öh¾È¥¡l@¿£·~C1XR»¿}
p .…¸àîC‰ÖëNöT8ÈÓ8*Iu\Ùv
ˆ¡vvç†rR–/KÇÑF V$ñ%q30 @b«•k/Î·†)ÇñœûEjM'dÇ]ı'"ÊoÊš‹~ªNÏ$})pàŸÜŸ.QÌ1zfÙÃ¿è˜'O)•ëoïJ,+ÒçõsÁPUºı¥1°À†ueww/‚ÊE×
e&K¹{" 3Ê5>84H’ØcSŒG<S|@u¢Ÿ¨„ü\…ƒÖ+#*²ã$66*ËâÁËÍ òÏ„y‹cê&¨t¿’Ê*>#š˜M½››(rB„¥,*@ÁîËMùpî8tuw›?0¾)¹¹¹‡Úln}:guæ­úÍŞt+.Ì-MóÚa~?³LÈ6×6ÎÓ¶l75ÄÎOË÷ÕóÏ7Ş³)Ï=b $üîî$ˆV#Ë¨ö#r>‚?m¼««‘	´\\ÊÓ]mş&tozÛ$ËNŒšYëÖ@V3aQ¯İ‡"§ÛX8*½G’á–]ÔpÿÜG!…R,İô”Qƒ"ÂU•ò!½æ¬VØÕFìÂ¯FIOÖS—˜l˜E÷Z	ÿÀ0ÔŸU‹t	ÌüÓçÒ3&^&€CÄ~@oR«ö‘e¨Ñ¶s2˜§²+ZkØÈé±OçáQ<™ŒÑÒùe2Õß‘Bô“_ĞH›UØæ"Q¾n[úšZ1
õÂ\ùXÒBŠôšïN÷jöê‡(^`néıeëUıòëXú½ ²æ‚ßàu¾â¨¶EÉ();¶ézËÂln1{äy²™Y¼‚dğæ¯ã¼ä	o/9AÖ€‹³9zØ$HL]%íšB¯36±É‰>ü­—›èaúÿdñ™!mg‚¾äĞï±·™íÇ@×¿««£üÍ(ki*íû™‚½ŒT×w¿ôë?*ÂßUrù^Í%i¯Ğñü)@BKÅe‘VÄw ¸EÁxÓ" j‹áÉ8gáõ#¶ëHì¤rz •¬{¼„Áz×0qÀñd1á=‰=—8ÁO×üq‹³4Uj:l[Í
U4˜èˆÙ)€,“€h,56()«+ú9,¥ŞÔb»ŠH¸!ã<[‰0!ä˜äé«6àu˜0¦X½	ú~ù_%ßŸıüüİÿM‰_Ñ–öélá¥ºV<ÎyõÇéª'‘„c›ÂRÛİw:ååÊHÒ«,É3áW5ÌÿdÚ„f£·CŒIºßø‘Ü¢æW ¾ç]=XÜS­{çH^#AÀSê¯¨ıvdiJ³ÔC-ÒµåHÎ†¤
 ~,UÚm>:Q-ÓyõÒ†pŒ_F.ÕìÙ©Auîä3ƒ“¯ÏxÈ°aŸ­É¥A{½çCÕvÓï˜~ÆÃÑîE¼v 2B{&k1³|Şfá)Ì¬xº›é%„*:×q=W0Pˆ“Cb×—#z¬Ër–PlÄ]mÖ¯Õ]0à„:ÀHâ¡œÌË\j×PDŞ•´k€¾*ÁbæFbe££°38ªù"«}ã°Ç`>*b¼Ğ”SE³]|{¯ÌàI<àÕmòc<
r¾¹ëLÖ¦-˜ü´L™¤PÓÁôZËÛ}]]¤ö¤;t")eö#W²C±	&änRºÖ·Ñ¢Æø€*Jîôuè&-ªÊĞ½úé&ÁÛ¦=ÊZºg0­<¤t7âSCZVÂ:d i£˜I¸‚zKúxÛ†åÙÜg¡=X›ïÌØ¹°rØ+T.„+å“Ê_ıÙb5+g/Â†,Såo„n?È10	ò6ÌjÂ&"ãihœÀl
~‚IÏ–¹%Í,›!p¶½¢Ó*ˆ(d—üÔ1¼cş†ü‰*?ˆ( õáhÏ~;ˆ_„`“¨÷HÑñ¶¬tT=Ï¨ZjQïEÊwb7 Àä§·I^Éó4g8›j€c]İìüû]j*4v+¡± Ì¼q,Ù¶ƒÂ¨Í¿«Ÿ>‘	°ñs½”½©Úñü>/u»›ß±°ãP}¸L*kA«Q†f??S[íôm+¦®Û’·¤‚V™z(V@y´™ºDçİÊïE·­"ŸÑ”Å8%W5ş™À²Hï[F§¹²`QÆÉIÚŸØêëFZ,V÷²Ie/Î0J#[Æº½ğ¢ \øEÊ‰B\MÎ¤Oh†Š°Š%ÕMßØ}ÜR1™(?Òv^’éúÌ(·{~>hoéY€ô‰#€ ¢íUNÙÚ»‡~8wï èwÿRb,.7™ô¹·ø;øfÈ^Ù61³ŒI¸cèúÇŠ'¼ï(ëgîïÎU¿¼¢·®ÀæDQFD¬?¹äø¹\R‡!çw]bçM±jlm—¼ñ$ÏÌ€ì©Ò ø;J'lÙ ´ª gÜÇ©
Ïó‰ğukóq#Ã«A¥ù¥–á=Z#— €ó æ(ø1¡’»¥¹uç’#r+(—şÀT2ò\[‰5´ÓqÂ¤Bó8eV-9²äÖ×dØÚ=@K1FcñÂ;ËB'˜“¿“eÀNjaYÈqQ­ª™Á¥.â¯g¬GIÓ˜ùâ®›À0Äµ9
µøÉ.£}²×Ëöô¿„®íT#ö>Otı¹Ğ/ˆ[Û9×Ù«§b—'Yš8Êj)Æ½DIıÊW•Ş—^{±ĞVÍ¸ú¿N¨ªÀÀùUj‡‡k·:ÒH(ûUs6şµ~ˆ`®N,'1šÁèqwµÜÏ˜2©ÖfÜ[ĞC&í)Ô9qõ¯]SÔDKAıY~¨AÚÑ
 íØÈäÕå?9[z¡ŒÙó)Œ¢*;Äro%8á‘¼_¡©BoCº>4÷¯Ù<mv‰PkX)Ë3¿s¤…Ê×WÄŞZ˜ü!£¦|íA>¦ÜS¦ÚFÜ²OœWñR7@CÜ†JÍqÿöˆ)‘Á˜TûŞ–ŒŒ¡î{ªºÇQRG4O[N[ö‹åËO5sÇRgAZ]É ´èŸt ·†?WJÒ‹¾k	;&ĞÁ–u$E!ÀşŞ·ï©«iYÌÜ´‡˜Å;TvGmS‚ÆZˆ_íóÕy·£*M'elAõkÇ\çí½'gõß,ZÕK»C©*5ÀÿlTâH¦DºÃ'Í­ü½O-çæá.ÁïÄjúÇ{\aaåWêrw{fÛd3B.ã&09070»á!Çóÿ›/m×D-İ¾€Š,õG9Ò2vÑaR@~„_úvŒ´nÍTÀĞoùLİk)Rôïv!Ù@ÒîÔ'Àw¶¥Ó¹V²`YdÈˆğZf¦O8šĞ÷ 9Àí[ EÛ&UËšÔÉ¦e%ÕuæÓÛŒtiÙÜW>;–şf–I‚½Q¡išF_úíc‡ mY¦šuÚ-¤/kç3ÖXa=>NsîÁ_ hK²ÀaºˆÇU:¨øq›¸ªx“\É‡v:Ü òé`ÔıÈIÅ3’=köW®Ò¸M$ßÈŒÜ‹ßa³hÚZBM{0Ç)Eíû§1€°½¿œ«D—(¿<Î\'o‚òŠxû0¡"-»HÇ¹Pæ¡Û`aÊ›(s#»!cş×À'İ2E3Kò—ÌÆ_4kê	õm¦V1— ±B´l¤–šƒ§¿m‚8Q'¡%X¨wwŞ
jÆc™Îøtş~~xêÏD¤=®ylÂ0éc.ûûT²Ì¿Mc@îd%X×¢'õ‡BmNl!äJÉï¼¥,¿Û¾½C«0OÉ¶ËÅ§Ê_hº/TXqzİÜæ`6­«DÕîââ £gPí@ ÛÆ-l¿ hî¬m7®GwşHys59'k¦K­¡I½GÈÙCRñ0²şƒ«ºñwğ˜­B‡£¿ØMØnV¼r'”æ×'|qú¼DÎ€™ºá±Ó•ˆ÷Â°ë
¾öîc3[·Şg´±‹ PC7î°úÃª8O#§†ÜÒã‡cĞ9Ò%MÂ]óË`¦lÂÖ)ßbw6m]ÿ‹ÌúÏÒÒòĞóIÅ?öçl2P÷ì)„
ràî
ïFÆWR™+¼ä9<8Â×¡“èãîRGhtšŸ¾Ï‡ÿ4ê‚}‡ïit=Oæ‹äÂVAà^Ñ¾'ÆËPl@ÀxÅ:èÅä’..wğŠœøõ‡Ää*şï0¡ĞÛºBôJOËÜVí™tG–*w{X"‚õ•Õä,™FZr˜•Zª8>áÂã°ÁÒ[»¥ŞÎ¢Ê9é‰NWÀSÌô¹–uŸBY,ÏÜÔ	Xg*T3Z(ıäÄI¬OKµ‡ÆA#t¯àÁÛéÒ] «U?òO=S—xj°”?ïÂ9—{¤›¼gÆX‹O7–ïtÜmßäE³¡¹ÀÔçÅ©ÜĞ4ÊçóÅù¦ÇÓ JdÀpƒp|+d—ı+¥Ytfd•>Yge©FF®ÕGZ"¾¤¿9ZJmEú$'¼)öòë)´Æ¬©ÀHÁmŞ8îlgv²şCşÅ!ÙpÎ#ÒI‡9yİ8zfz¿’]Ôvç7Êd	©Îñ$KÖ´Bnòu‹^`a‘ÁìšK?‘ı¿3J	ùsª±áîñ$…`§©­æw&U€Ò¨ Ÿ ÉS×–uEdüø:à/ÖWq¯]B’Ç–æú`}ÔıñÑ½§*—oÒ2çW6MeLIŠò(H~.	äş¨…²]²5ã?‘rÎ«Úè¿ONò\MßR XÒ—\Ğ0çüÍ;àÔªP«ì&|aJ¹i{O;qú@ô-’°í’ì\›>¼Ø~f;ù’€øJu¿@<Ï¹m·Ú5«4‰;ÏPRÓ˜ØòH§ş>£_IÈÇ›¨ØîZ}rí÷®ŸíÈÿ’ñiJòÕ’f·’¬íÈ3?ïûYLä‚¯ésÑÈƒ&«Æî˜×ÑÇ´ZSïw«È9õ°¾Øù—«:]Ğ·Øx°U«@#ä#8…†¦Kñ”|%¼9äÚæxÛF*¿\~7§jc+xâÎÇ-J¿ß¼;*Ö%ER@oË%ö§ŒÊÒuöT¤Pã¥0JJôi(ÊÔ“æqüººª±ÃÕöõyÄ¢J§IıùŸZØ}ïlÌ1hºJ6C8hKáæ¹ÈÈvs–Œ?ßÒ&õ¥ ­›>ĞÊ°§RQ•FgÑ	X­öt@Ù¼Ö¢™-›cõ|ŞËåøÆDø®±¯B¼2¢§,í~÷İï‹¦:r‰É0¬‡2¿vîx¶mHûL»­øŸå,…µW?qû¦°©šıŞyP´b³®æ·Œ{IË9öá›¶ù¢;ÑçŒL ÷ß¬M&i§N1Ï&B¯¼T2¥İ¬
‰û‚vDrØ°ÙúŸÕ–“ÔíÿoOŸÒW¥GÛ;:ò'GG†øŸZOİ•sÑ"09P&ö…MD<'-Jp×6¾†oC|`˜¡SÔ¥i­dP‰•cv/İË³A<fc‰lú8ã>îÙ=byğnüÙ²ä…7pÛÛ
“¡l^V“˜‘œ|‘càZIoõÇ¨0ˆíKY’/-ˆ‘vÔç«fÓ‰DÁáÊ4wcÎe…ø‹=Ã%"ıå	Â0{üÓP+,ŸqF­Mò<ÌÉ='Ø©HĞ)"ÊÉş¶\êƒ^.æ Y(1T
šèHb7a~Œ—Â%OíÏ»Ø>‡nZ¶›ûª„ˆæ¹‘&‹×;z—h¶bï¨ùÁµ
3¢>YêˆÚ	ú(¨giÁ«¦ü ¦­ˆ,n%[ò‘F÷;g´–ÄÅ¼qUõ'íPr‘úÛ%Un\«°lTô”S¡è§n3Qì|ñızââµÿ¬t;™0²Nşa©öãÙ]‰ú£V4m³?åw[%~"3F)‡ïFBX{Æ®İˆ»	;HÃÍáûd…QîS99Àlş;ƒ¢¹ÑW:&¡®úã¾¾’3ğ%T'q¾W‹àyåb§Axßå³ÚGšãEb¥„ô™÷DiËÇUqœçÙU&ó}JĞÀû(’?Lºeì<Qõ(¹Ş¬øÀ//•Òa2sJM)n-RÕoM>…t‰øW¨úÑ—ß²n%ÌD§ Œ¯-v+ççªIa~•ÑP6ôî“%}kúÖH½;pbJÂñ– Œ4BW^N Ü©ÄVOéEAPÆ1Qnù$…'¿Ô¸­u9Ò.I¤ÓŒÿ}®‰¢‚jõÏ5ésKÇ€ùM>	‘õ1¥D5(°ÒÚ+
]j¢^Oì šñì«;Æ&»ånàñ…€l’™®tNt’QåÖ\Qœ3³I®¢d¹ü|Ö](yÀáàO/;¢1$ØÖ¾¶;®![«JzÆ v¸õ”ëá¬Tg±gÌ0=Å9¢×`t%‰ÇƒÓ¡-ˆÎÌşé i3(U¤èót°½¬|?\¯Ñ!ıeË)M¯_íS¨B‹˜È–VÊ+zut€hSÑ\Ëâ…´µè9&OÚÍBÀ8*¿EiAGşÙšöÏg~zI½><-š®vj‡O†¦hLÓ™Ğê‹à’0Ä \±`(òÍ’¨ìˆúŠ,q§~í¥uw9?èpÌvÑ^°r›§úşÑóinç·ÿTÆ¬’ÉÓõ¥˜\~²»00ÕOh5ûIŒ‰«GmúĞı
T:Êˆ'ÙlêÎA'KÃòhó*×¾¯±‚0ÍœøóútA°L,údÕW’•¼W^`Ìúb$õ)t,¾'ãT|UõáXÚDÙ°¯= ºP‡èúÅ„ŠKK‘iN wZ;Hs£EcXA=å¹1ôJS­U[ÏìAŒZŞ|xvÃºÿz¥ë‘ÿoüÀ“ëĞlK·×i&KP'¡Ùˆ*™+;Ü HÏëß3|Á‰‚+ŠÙ‡lƒ^<×ßl *À,r9œ”èı`ß4µŞïG$»…ü©„ß»†+°ú¨GåvĞ:ÔjÏ¢cRB'ÒÙ|Ñbç1ş~¨6šfuké€å\ÿ'Ú§µ"y¯60/Y©¸ƒ¬yñM½&šSönyèÀ‡¼­]=ëBŞxoéhM|ğÛÀ „±æ¿üğ÷ò7‚µg–†™aÿÛ8š`ËÙÄ>_ú¤ä4`õ¦~äbîOí
2±’7ı¹™Á‰ ‹ƒæ]u/[­øPòêV„YÉ©Zhædo[QZõe#·ÈkâÓ%Õx{fêeÙ/¶,ª*£ç?LÎæıÙ²;c{ølÍû·ÛÍÔ¤Š¥ÈÈæQ82kR™{y°ö6C:¹
**f¦^;M¬ïD ;4š:¿E5sÌe€2íÛÜ¡°_JîÓ¶€‘‘²å×¾Ä„ŒÎ­¬Æxòª+:ê4*ö{½w±Ãê]ä‚ÂÍc/İØ^ÔèÁZ®§tˆ1ëíLfuA£>AqœçñÔaÅÔİY|µ¿Ù¡ÆŸöTÔ¢Q‘yé®Ú§şU¿1ÑlœĞwÎèŒ3Ğ-•ªÃmzÎ‹G­M1ò–fÛt¬g3ƒWÇD·x±¤C/pÅc^rg8Œf“?Ve7mD±¨tv‘/Ô·*`):‘—€æzÜ\ËKï<`à;-£,,””üS€÷Px9Òü%ÙAC¥mü9*N´Q÷‚9%İzÄ"R»çç8pª¨É«¡¦„EXgúıÍÇÄ~?¥w·g¡i–ÈÃ2Íf¨Â¼Tğ¢§Ÿ_fZLî`J­|ø.ë–Ñ§âtÀ«åß3t‡‡]Ei©÷À:7)^Kõ)q(ïç¥õ¿<ïÃ$öÎBØ\3rµ}sPYSyİaRH’îJêÇ‰—®­ÕcÙŠ|îı¶í‰Xõ÷>bê¢¾5.c\1|Ø×øú“ñı¥ÑveJ›EWzd ¡ôÂ²qß<-äåÑÓÁÓQ˜s! R-¿“¼•Òòö—·2;™mW´ÄüEıö¤‡>p‚¹…G¢á¿êPj5ÏÕ‚$šB;n«¨rî–ÅØœRß²
*ı‘ŸãxH“e¶B=™SË€o"gô@F?œ°”abÙo5M‘œZb‘aú´Ï~­ß~kï/ôç>5&{	•;İj/¼ĞR¶íµjRL'ä–nSŠ7¤ö\¾²¥ôÃíƒeS&~(,Û)vg­ú AÿTÍ¾Ÿ—~œıÍƒQÏEŞŒÎOü[Y·ŞóŒÜãåÜ`é2Ğ2‚=ßU¶~>]‡Ñä”ÕIk÷ò˜ë›EP7dRwZ3Š‘«sFšk·~£1œ(8é*>·Q£yo~h"çßŸÑ@ğ15.ğ‚ÒgbâªÓkEÙãÆø/“>2úÀG³;eLóQBlZ¾äÖ.2=šœ??¢öL–ô
*ƒMN9„¢G¤ŒÃ°Óæš5£)oª©!Z¨@/|À²ßç«l¹ó=Ñû±ª~µû?ğNÙ3
Ú‰¶8¡D}Œ»÷czìıKDVúæ,™/=2D8
Ï†™Ø®Åáå)tÇ|Ä
â`¶¬ÎŠ'›Ç“çõ•º²èš­;vZ.ãèëæœÊ’
NÂvXsÍ Hãù§¹—1
Ê¾£şˆÎUzùI\é¾w~óÓ©Ğ4/I"@WÏŸ|ùç;¹Ükí®ÂSˆ b=°èƒy[^dx­×ıÚjE­ƒQY‹t!kl½‡"k*
/á¿;Ÿzóîû(ğ\gĞ÷«3P‚¹2›»ô:ÃFùbO|›÷ÉfdQË“{	–¬åOï2¡¾€¦Bë)ø j°+ÉGJI„	ñÒ÷}ğcûš’²Æ¹çlÓ·¿6G”Dvîôpe÷·g–vg	 ¼V¬Ú7aÊŞ8¨úÁ©£×8S3`Sİ÷ÑYÃÒm
`>Fòq@”1¡¤%íttîòØ¦ß£=k¦4vâ7-mFe»¬3½mlş^›sÆjºêG´©<†Åh»fµU9æ¨!k„êx*=~-ÍZrjd¹ó~‘©¾eyY
‡~Ñ;·Ü}f20 Ë¢mÕõ6†µ¥V¹¯÷»²OúèßM›…``Èæ5B!"ŒEdİşzZO"ªi6¦wC ö˜À!ÕÙA¯ l¸ÂÜ§Ÿİ•A…œÁXşãgeÍ”0ZF¿p§MÊ†ç/kÚêñ¹÷¡HÕÕ:P‡¿|Ç$ÏS¥úÒèÃ#†Ê`]Š¡PG+?œ1ÌÄğ[m*ÍÀ½¼Öùä’ÑK4âBã£¸’… –•R;i†½¿ª•!¥R¹·’²´ÏuoiEœ‚ç§Èå{ßÄ
p9Dì¸|&¯äi}ò3;àsbqUf/İj†³VGvX¢&>±  iİ`ÙØÿ:ÌDN{sVÁcäP=Ùó?„¦¡dêR\n±dçÆÕ 8È¤Ÿd†q˜PïÙK9ƒq<}z„ Õ÷0~!¬ÆubË·XÄ³¬¬@_ÏBšÈwU¢<T0
6s2âCÆ%¡kßÖë
1g' Úsk6…~aùªzÌV×­Òùoà7‹¯ö
ÇêîÊ±Nğ)§â(¤­Šäu«"ÉÔ£ùGµYBp¯6·¨ƒF†·Ú£èEï?7SµtCF]®û­b¢#L|²¯'_ò=b”ê(³²—ÕfÏP„;ğ¦zv¡¹„BøWÆUU·F}÷Ñ9»ªøJZQÆ—kˆ6H½Nà6×ı»Æ	ÙiÜº1#é|ÜkÆ¢nÍÄH>åôEf(§Ešl&:÷0iD•OÜ?¡ÖªcCÚ‹?«G°‚2r„¬æ6†¤™x¡Ë©u<Æ]ú-ÁBùŸ¦Ğ‘7åmêÖÛÒ>â¶p‡é°14GßåFĞÈw¹Ïf¨ƒ?+d¶µÙmûù“[M	k¡êá¯>¸ª@^´I0µá7½áÿ:Êë$/Há™"F:`·dX€h$k|#5½€$«‰XpUEÏm"Ë¹e•5 ‚¬c÷t¡ysİï,!NÖvÓ¸‘Ñ…dAİ¢…ºHİ´N(•ˆ;
ÁÜÄgJòA”a»QMÅ¯o,“Û¼{$%ıbXDGêpŸê24Ù±ğ°J"HOF°=‡wÕ‹ Í~@+èµÀçÀŞ¨Ó·|ŞDJvì
G İpÜÆø7Šµ?ê	’0d]@Q,r‰PX Km*‘Ÿÿ›Åh\O›ş´«|‚É]Ä· oâWb+‰[¥ÛNºúzÚjLŞvX6Fd4Q®‡[EøÇG/g%)[‰¼–÷À!#R®[¢æó¯0“"r¥…î@X"ç4jı"zóKÍ‡Ê#`ºpîöÛ±,‡O6ß<°~‹(5g%^,·”7>ú])‚|ƒæñiLaÃst7{‰‘¤O@õ]*¾`±M[ğû“¥–.r¡)¦eÌnÀYèmAâ:ŠïÈDÛ6ìçlü¤Ú˜&x-~>2ºáGzÄ$³}O“\“?!˜<åWµ°ï*ş}“ 8•Æ*Ix×´—J>³÷>–Œ‰Eñ“²¹æïsàêƒ>zE:ø <GäßShàì çlÏıB739øx8ã›ÓDğàƒ¿pÿ­7»ÇştìÌqˆ¹A®‘Û7û¨`6’(¾ª¢@î&ĞÂ8QfüGãÙxQ2Ö9i*šìŞBzÕTZÚ)|cûåIoFo
Î·ä­c—ĞKÛR¸éqŸÖÙ4ÿ+Ù¯İå¥¥F8ÍÉ½îl÷±i·ÛÑƒU/	&q}±¸è"Ü¡­?ù…ÛbÏçMÍUÏ´Eü5)´ã¶wïBò™ÿŒ¬j¦¨oFAqf–lÀmä“ÉodÉ³Õ°Ü²ı§Uæ-ÏJ¶ùmvª’ŒÙ4ÿrxÜÃø"¼—ˆ!&ãvò¿Y°!ûÙfGß/Æml¦E"`ĞÎÍÒƒ½µ8¡»&£vzuŸ˜ğtõŠÀÍJ¿0ü6ĞL„Yœ´B¦ùÓÄ×èÜqö•¥ÙàÃìóå\oDá‰c#ŸLîP1"ø ?¯Ug6>·ù.(|(/ğ’n¯àøwmSöF†„Ò0-ğßq~WÇF¡Ÿ6íÈˆA¤-‰.ßT4\-åü¢~†#c€WR~X6•:ı˜ò|#çwõ¤ºÀP"ùÁçf€İ’{ ¦Ñy ¦rÊv ªj+—	[{øá0çÁñ|\‚›`„-ÊËNxy÷%Æ]®/Ä¨c·¯gö  f·!³oŞ5åL‚Ü[ÒÓÓÕI!<£s7íªL“ô™ˆ”Ì:’óÈkO’/™¶°áÂL³‰£¡	¨ª!ûy5ƒâ*õV"¼28¹
?M¡ºXÀ¬£ÏDP=(üèêè0+òö¹.½.Bü1í©›Põfv›Iü°È˜ÍÁ‰IıbWØ¸e ïHÕT·yË>ıéÙß®9Õ5¤”@Q]Ì®ÅAéŸ¸Jó«VdÄ^îXçk–pöçvN·CƒÑK…ä„Õ?µË4¬®<<eë›.äÖüğrâ":¨mRŸÔX<™àã×ôŒº4n3÷:æç¸M¾3	æyÎ›á¢ª±©a.Zr½-y ¶ù^8YZú©­ È1=7¼=SÂŸàç‘•å™âœ¯ ôO¬cx´£på¯[÷–PÂˆù×Ñ(Q fbò4;·ô«£)íùeœ…¨$"Ô1øfO °çÙ)¹‹‹ñõ¡J‡°”4poR](hÀ iJ$ìG¤*äP»ª1¸u"ğöÙ‘ešùÉl.ñ]âÅÙæ¾Œ·bø"ØéSzD*&‰ƒœ“…OBÔfsõ<2*üÚTÄ2É•<²vÓ¯sİçêƒ1 Dú@ª9Æ	 ÛÉöS¸}Ÿ.¨DrêÅUDÃÁT‘w+Æö)Û'Aœ<ñ‘“—oõØ\[ÛĞ–~Z>ÒÔs†§tùÀ‘’8\†óåóléòpÁaŒL[Û!6 iÿ¸&'×"Í‹Ä üÀæUOû ¯1Ãİs¤áiË/Ä8or¢,RF0Xà­âãÈLPÊFİ(Ô1i¨%³m€EĞæ"ûô«òGÁÀ {¥#‰ÄâaÉGjôÖŠ÷|vNÍaOÃc,–V‹¡˜ÿôG„-¨%³ÑÛ†Î_öxèdZ9µöàú?É›‰‰rU¸¥(~¡Ê(5H¯ñ¹ñbœZ£ÿß&ÄyUTB›…ß“@ãÒ¡
ûjâ¸ÊÍÀO[£ iÔ4IÛá—’AcD´QĞ§&–p=Mùh'R@¼èÀ}—Ş$
ÔÎÛ.Cmˆ=–øË7Ìµ¶Ö;ôp¤îª}éxz§½ÁCÑ/¦—Ó_°>4Ú	%2ÃÒT‚ÔòJÆ¥x¿ˆG“:ğmÿöånãÂKy
Ø6î[û›(êò:eè¬÷]Vİ±5¯NcÏR|‘ñ• ä~yk{Ø7ï<ãñ&Ú‘6Húõp>xÔÍé’ê´‹Æµ›û*ĞĞà”wÎ3ÙÕ6v{e¾Õ8í#<å3‹0âÙ•úêŸŠˆ£s‹_}Ï'¡G~-¹œ+EFû¥Ï:ÑÿÆşØ<«¶âeE€gY½ r3³½\ïXÂ®‘Y—UcÒÿ!–§š°Ç'áaµş&‹'à®«z¢A­ÒÜ ³ıSå§²ˆáØ§ö¿Õ¨Ù³cÒKoïŞ‚d}Å*¾¼÷']ÏÄšş çş¥oìi@l®µjÂXciïÿÌÅé’ûKN`”X…#û2Şˆ	üÁî–LÉ‡ïªªüZüa(®I- [çø–6ÌÅö†Mp^@XÙ,´óBú×ÀÂ‹l?uQ»ï§Ùs…Æ¶ Z»LTè¹éÕ·ø?õâwöøÙ_·:üH¸Ù|»®†YJG>Ü$r6	°wÍ9WVxx<—{Ñ‰ÇádQÓñV„vT¬wr’<Ó²7uæí÷·aÄ€»Ú0–Ü©Ï˜dû±gGE™MW»ª+çİ¡ug©ò(ãŸåÒõ€s½"ÑCgqÁü*àåvÃÁ›j‡ÊMíŸg…ej§JNŸX(‹”Ÿƒ¬şc”¶>ÇÃ€F'÷Kşc‰ŞÈdR… 
©á Aş°¾dçŸÂ6µ)ÿ7(óD °Ë*-6}
ˆh´íz
Àëô…›¹ŸlÄ­´ÖÒ÷£˜ãŞÕæ®Ë!ìcoGû„oÛ{©õÙÇ0g<uğ:Wb“•ãŠwVKô±âšmÜjvüj‚U=âg}$ûâMú×¸»éy$«mƒ°»§äî*\9CDˆ4ÌD#>	^(ìøù3Õ¹½•fºl=Gò±“™Ãá•6*ÎØ¨Ö÷mŠ¾¤B,ın#Tk—m‹UÎ÷wÿ&\°^`ˆÅnlñ/ø/ë/)îé‡¼,G2¦öh×š[Ô—ãìV_³Ïâ³—ƒqF»#/ê7EöwUœ½±|Fä¶¸øÿ &€D7miËÓ×¥÷"¹‚yC‚CaEF·ŒÒ Õi…pw†F/|¹øÉ{ ñ³|”µÏtÂ¡U	Kƒ
_Xk¨önÕ÷ªÏ¾ÁÛvı*í"²¥”:Fo†_2å¡í~mw‰èP?ÏÊ-zcá‹¬=NKÿş43=i?ğÂ&ğmÛœ¡˜M°“k}Ÿ)Ãş¥°*`¥$–Ûİ²ŠÉïs°®¿ïÎöŠ;<øW1© ï	N8¬T×z¦xÖ8²Ú”±Üœ'%J7†O•³is2wDı‹À§Ò ûSÜˆ•Â•¡ÿ~ÓXZÕÍà;Ãf³v«gÿº2^;2‚Á@d³Õ¢Ñ¿WyõKÙLp Ê!XöB¢q§ V<zwÒ8sPsº?é³r{EàÌ>c¦qÕ“‰µü•fBB:ÉD¹³İœ_ƒ&ßY3VmR)½wu*¦ùå>½Àş°Lü)ìkÈYÀÚµËy‹˜¯IÆRèF_«<Ú´4¯›ˆ{B/¾|Kö Œ¬ƒì‡t¤<Í0ÜÀFR&cJ/CìBBäŒg[Ç›×á ü-mêËhßW/PĞYŠøJhç¨}íÑÁ°na¹¬ £-Ä]ÂÔ9°‘IÙY9‰Ó2)"l&öGÔ{h•Ì[‡œ0¬‡·ñ¼/—“yÊ fÿ
	äWI8†ÉB‡{Í½`á™Ö^‰Õği˜¸»	›Ëñ4¦Jq2Ã¨jVWkL×ÿDt À°×â„°RÌ¾gkÀZlöy-oÊÃùõàF²‰¬O$`#ÎQÍ]…‰H	ªw=â¾»*ëÖÍÿÚ/P-`#Ä²ƒØê4ÿ¢o  S´KiÿÄ±«E©`/ºâhÏ0QšŒ{î¿9O,bq¶·+ò
(¢²É–Øˆ¿cnrQ4Z,ØÆ¼G6Åò±°âœ;¸ä…†_„¢Lîz—{¥GÑæ›‚39¢NÁ<œ6óv%»	d5İ<zîáô›{à<	;²ÃêâCnœpÜ†3™şw/4»?)9åãM#ùgáÈ2R7ozºIp»€ôäRCË Y©4ÏmÂ4o(SÂ1’ÍÅ#BÒ VHºø Úm,ä¥éì½ìjã‹Æ>ï•ÔîŠVè¬¨4>ˆ¯ßf»İ³ĞÕQ{DÅg…üÏ½ìü¯Z=P™DŞŸ«·Ê¦[y+=$çwo'Şïa¹!„¦2O¶.çìkuÓ‚â‰Z‡¦ÜÿØ^/îË;^ÿ—×ê‰^t	ë3PHœ=n™ìZf¿¥ -›ÜXãë,ãÉ‘œHöªÜt7[í‰Y *Š¶à±ôÛßAlŒJ$±pÃÂ÷	d9¤¬É¾D!i¸å[=`T«‰´Ğ>¢ÿg¶¬¬í0qC/%!èn–Ùà„ÇæèÈTŒÄ¬#fœ	iL,~°¨%À(r}X^é‘#ÎˆqŒp	S6]ˆtŠfwú“€ò„4<BbğÖÚ–lßu²¡QTw¸‹İ=Ş¹YQ¤pzöM8‹Ñ>…Q¦'Œ‰0CÔ´÷¥ÚÄBäehû™=üá¿‹™™,šDc*š§ëwœ{7Œu(}Oß
­¦?«ñÉš41–ºâ(OéÅ¢É…ô•eü ğ£¢‹ÄµÄ²hnsôÒA6eíòm¿«2Ø†J%]¸_,„Ä]'j'¿µB¼åçšq¿9)"ò-€!È#0P}H]‹`í,L^h=ëQèìoŠ8º¶¦&³Ô=øqçì”§ / ö»À`ÃJäh3ø]éÛôXÉyœ(éĞ5æñëŒ}„ûn¹Éù£ŸõPı‘­-]´ËC&mãàn})ˆû&ª•Ô,³;÷Ù¦Á>
B&ÂÙ›ÿªŸ„ET€Uµúu<'Û†»h®¨#kds™²ˆï}éĞb@ª×!2/Ow<?½ÉŞ~<Ç­áE’>L&¢sÌØ¦)T´+Ì’HŞf0‹—ÿxñrTgì‡Ô€@ÅX;ü_ŠiéŒ Ì§Ğ…IÈQ|,ü8¹ÎHÄ¶³ş÷‹ÿ#‘ö“ò®%‹=”ã¥Ş¬	…çŞ÷zJ‡Â%í&a -Íí’-ÒŞè/¿¿"0~ŠÎ•¯¼µŸSµ…©b:*Ù£‹1
şÑ"Mˆ»®‹øv˜áYúv ‹‹^ärÿ1]áIH<¬»°n†­¶>Jz¹˜Çbfy7.oYÇˆ#Ÿgu‡œbaÖ¶é®œÁ]1Á¯Ñ‰MéÓ¡jÕ¤+zTÙ¤Wx'†[\uäº›çæßB.,z+ks¹i|%¬À)¶j,Õ–¦FùÀÊOíö‹;à"["Cy]û?‹íÉ‹œW”²7ËÌ×¬ÔôA+3—°õ³ñÙZfíŠŠˆdz‚‡yºgÇÙ=Å÷[sÅ‰%Ù åEÁ­0æ</@dPAÕ‰õwiHFëÑø	¸Gñ•„j­tõ‚ {¼ŸSEV—#`-½Uİ­L£óˆop˜¯p té+H Pş÷ô*§ïáĞzÄ÷¿V%ŞùsJh‹lq+U¹l—ĞÇ!9âUˆÄr
KÖĞªLÊˆ
¯¸àârh
ùÔ~CˆÙºÕ^wKÔœaÎg·’\[-ŸvYKYÉAìòğæc–·s´šåêe4Wã aÎjµ»*¢Xş;ÚpŞ ,jĞ¸®UK8ÄhRT?<$%Ûãhè½œåBq"rn^™_îu{@kf…-©äSºıLTÍÁ8Vµ'QOµ1]ÖEoÕœö¤ÆH6¨.34)áU*€ùê)
€…#ïeË¢±‚6=;ç8“Ú<î˜<‹‹¢Úk&<4‚ºìÒÖ‘}Áëh€l¯œÂZV '…¢Å7p_D+\şoS¤V%6L¶È”› 5§Ê”4ÈD¸[*øZj®¼5ÀÛŒålïØËD5ëë²/Bãh;^"b®q§›‘•hÏ¡ /õõzª"=fªÅ#æäCüiúÓ‰®_=Ğü|Œ£‘>tö6÷ôòıä`as¸mšğèu]~ÇÉeİS²ØùšÉñ¤ïş¶’ŒQõeÁÇÄ¦}¢ıDâ\-ÃÕÇmÅáVÅvŠK?çm¼C Š2Y½ÙëJƒî©d:p¯Ùñf×gq8sKëüßËJGŞ99ïù°İ6–Õ¸ÈÃó!PsJ×i†ÌAó5ĞĞ!‚ÕQ¶"¢Ä-S;£šÈã-İx_í}—¡…1Ú§HïÀÕHÑC&ï«ªZ”šr§8¬3„%CQ\¿´µ%P’¾İ«W›¬gW«%İ¼¾Ôún÷^c¸øv÷œM³í= 7N¾çÓ>KôXÙcŸŸ‹©d8 1Ÿáš£^@ìó@şKFfìX­V1®|†uã*#ßí›MŒÓzU¤mçz#Q»î¦m¶?}9Yíht¿Zt ¬†èR$,*æNŠ.ië4oß÷4YDqQ± †#˜°ûGøñ²Ş*Í‘Ş˜wÿÔxm”¢Åj¼L"ãi)¯XÙsQGšÁ1yÏ9”Kâñäd{tÉàà%Š^Pæœşà£Ô     ;ù$j¶"ì ÉÏ€fšä¸±Ägû    YZ