#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3293518868"
MD5="ac1d6ac9cb0d6ed82731d64343989bd5"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25484"
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
	echo Uncompressed size: 188 KB
	echo Compression: xz
	echo Date of packaging: Tue Dec 28 21:48:41 -03 2021
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
	echo OLDUSIZE=188
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
	MS_Printf "About to extract 188 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 188; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (188 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌâÿcJ] ¼}•À1Dd]‡Á›PætİDõ#á‡EÓ>º™pÒ•£‘DnÎv‘½2WI}Ôâˆor––ˆ‚¾Ÿ'YÜ™uéÆ¿n¿š+« ªÕ¡¨¼5UL‘ÚäcèÑz¬¸9;…á“å‡‹ÌuÙŞ$lx¿1@£0| ãµ–&:~vk"ş–l'ó¨ÑæQ‰ï¹†!ÆË÷ïø&›fÕëM©WEŒ×cy·.¨7æ¸RúÖ»¨Pè…&¼Ü©›j$¡mdÎD‚F‡†Ì-²z©}şàv¾ƒÁ9´3+EÂFÍÛËæ‘Bí6¥ÖÂ¸v?´Nê+¥iWæø~FğN,,‚†]1ˆ;2V{krÖÉŒOx`"eì¸¦lõ½is¬Äí¨‹*löP¢—¥¨=ø1iCg>Uò)Ñ4-Uq°"³Ö×E2ö‘†Yiğ²TÍƒ(	õ,ÅW’ªÀz×öF‰jÈ83¾a ÀğĞ)¥ä,?Œ6OµÖÜÔÆÿYºÔ«öş]ü
S.,ë°c(±Nv³"jou<æì·€‚Á9ˆÚ”O¬’š]ajGSCû%^ŒÕn3mÖ`ÜRù4Â2Çm¼¤ÌãHuÛ²-”æG¨f¼Ó—ƒ¹Ç—µê]æ`³@¹Ç§µ¸wVv™ÄºtOIgØfd”xè—FT‚†ãú<"ô¶ºöéc\5£€;Î„¾?H¸Z>¼ŸõÂzã³ÙACŞBğñ IÓŞóDi=¦]¼ ‰[˜‡ıÿl|Ñzµ_¦p“–ù®Cr‰P“ÖÛ¬³ÖÎ\2!˜8&Â¢ö^ËïÖ®Şı	¼5­JGS¸j`ZvS­&?–¿uM¶˜Ï¶u‡§\¶qIËWbˆRq;ĞÕ³qáü£÷Ø´Ò6à–š(¿a/Á}˜¼†ÊÌòhJ$·›%„+ÜÂ¶§¹£ÈS2Ë´u–}ÀŒÒävĞ:ñÚÑ”˜®gŸ:Á=#šá"^oöuËÎ2¹ ¨’˜¼ÚO‰BîÂHOpÏ»€ÛQ}ô5lı;sÛğap-9l:¤ˆDõÈ?Ç«]¬6t­«doL<#3Şª×ôV5·»Ş4G‹Z?{}E;W·YÍÚ‚­Iõš®6â°ZˆëÊGl}Ù‘8:¥æ=>J»Ş”ÊQè`Ï]W EE4jsWÈg;ŞÆĞB‡=Ûü¹²rù¹+Òo‰Ÿ=;“Ø­§_’áf>Øæ_„“ª;ş³HíÏI^³ÌšG§¨eXS)Ã®,ÿ7FÅI9ô’ßSyZ×7,ä¯píú¼³
$\)ş¶ç¿¨Å¹;*>èB.¢4¶l…(R¨"éD„w»”œ]0×_µÖ]Ôú/¸ëp@pBZ]ğÖ~şG4€¬Óíl€E‘)©–püLŸ’=“İ˜’-æ2À»ÉÈ`Ğ‹KÅ‚ÊñÌ×plNª—NPN$•ÇW˜k»<¼˜Ş€˜(Ğ=w»¤³
½oB@×™/dìY©“j¸y£œA$†R"’ÙGe!;C“BÅù¦“İ—×@T}°ç7¤jÆwwšøšWÄ$Ø.E‘; ÓğLHú	7­–K4ÈP–5m«°D WÉZ( ø_ûÂ,®%÷áÉH„9+zMˆByãzår ¨ -Mäózû¬5åÌÂÕ,¤•ºH°¿ØĞU!î˜¼‰$İ,(ƒtz™Éi™©Ÿ|~D‹]CÛEOğj”j‹`n+½gtëlÑ¬‚8Ãqœ „_´Îæ>?·M¨B†ÿ™¼êö¤nx.Mâuk1²Ø}×[bØçÂï)¢ó!¯EŒ=Ş¨©ìÎ6âDFºò¿ÚÒÚá])ñ‹Şú8ÌÑâHûéÓ]yi<ü‘Ü'|ÛeC-L e«ãZ¼d11Œ¸·@ßUçQÊ(îÀ8÷y7Ü½Q£Àzº%¬åûbÜˆı~ šæ«`Ì%&0¢^Pµ<œ¾ÎO ÿYM‹€ûmáÂlĞ¸ìÓÈœïú[ö)ñøAªcAXHı_Š[NÂüAf(¤Ôíe)"ø•½‡¢–€OMË·‚×’hJ°RË€bB×yEÏÎùş¬-¾[=]ˆnUl(Ì¦·ÅƒíşÀíô*Cîšª¹™g=§0”xê#¼MóJi²uhïtß®Ôÿu\üèé?u’Y¶«0_¨Em½“T@ƒœößÊuŒ×LÃòÌŞ›ô/òóH0Êé%ûL1½^)å œ×ú¢L"õö*ı‰NèØÚéÛ*7^Ğ-ps?í‹oóSŸPT/{°`Œ»‘ë·¹æŸ(§PWãLe'¢Ú¤KŞ ‹G2}¹T’q—C÷|N€½r ßœgßÏÉSeŞÖXÃ`lôB(¥\èÙL×³å«úÏHä#Öà5Ş~rªt%A6E¹¸c­Xå('€OßÃ¦ïÑü_¢˜G©¨BåÕW·A
aZ½Ù•„rÓ^Ï¸J$gzÙb½AßŞÃ¹Ó¥·BrxÃ}U€,©Ü‰fÁ8Q°í^ù9ÿ YÉòÌ¿ÎŠ,T8
”ö)"Ç@JE:ÿ‰Í3i]7Y~sm­Y
ª+ù/!Ğc½ô¬<·©:h¸â[_ˆ*esûÚÇË/±(ïL’0m§‚yısÃ5~"XıìîÉş¥½ü'ˆ»ŸsM€7:–oÚºÍRlcø½ÂU<ÏAxÛÆû¥'^¨0P-×,i7luäÄPZ¤°o¹?¶h–¡ÑÈç Èİó‹Œ2ªy‹Üã–‹*Ìş¸I^ã¬±T,ëŸ#dÊ±²îh ¾ºûj’ZÿÍvkµ_2›•!v	¸^A°èß¥kÆŠf­û>©‡â…À$‰µ¦¼Úo…m£_1l7[—Véª)ÓŒ›"ó¨öıV@•Ø{ü1 ÎÑW˜Ö”ÙÍuv§ÆÉ‰ã€.²'”Yn
¦É’h{3Û>NR¥ÄwÁÁdŞHÜÄ‘<Û„¬di$Öı@	*›:wı­GÉ^Íöhøò º31†‰¸ZFôŒÃ$fc›.Œºúi±MáÒø¶RÖ˜˜	1sí¸âOë©e·»³õgñÖŠ—ÍÂ4€VöÅ5‘L
n,úf S3äü±bRï|$=é	’ ÇÑ~Ve:0%™6™ÿÇË­Ñb°ƒ¿NJ9ö‘¹Y—”ŠöZ‘n…¹q-O-3ö<Ò:0{BŠ]˜C-gKjÈ¨p¬vXÉgscjë­è"d¥I~¶3[u¸ ~½ïM¸0ù§ı`Yø¿héŒÿ.Âú"õ¬
úáp.{®EqÎm_‡QòY:™·T4ºÅ‰chÌxA¸ŒŞ”vO¢’q3¢2>J`Ä[eó*|3É>Öªt³Ô›fğáÛ/ex±ûs…“†ÇRÖyÙÊƒz,¥0	İP× İ0ğÑMMü‡ÌÛÁ˜Úôu|²¦“¢ªÑİ©01¥7Ü-)lİî8åJO³Úçª"•¢HoBgÂ}?€ŒùÇ4Vˆáå‘¿˜•ZßõÄ`­±ö;A¬aªkÚæ•¨³ ÙJÏ­ô.Ñã\*“÷%æ_8ÎôRèØ3Y¤2”æ]¾zÎÄâ	ĞH¸îïÑNi-„r?L™^¸¾jœ„>rIÇvkWÊ/yïÈ±’L@	O½Ëº²ëq	Ÿ)©ò¦w3”d*GCæ²ã:Ì›œU:)1óÜ?j0¿ÍŸœÖy<§oÏÀÍ©[/@ ˜nMæ¥)œ’°ÓU,Pî—Ú¾SåÇÿş»„»
Œ‚»$ÕEæ7h’;ğà™‚»hó2äÀÿÁ~ºŸé´®VÓë¬çï†™¯0F€WŒkĞgzºÎÜ½ªş"ò%ùƒb!]í¾VHRå$¾ø+;­D*šò|Ùoš°•1ıBô¶ıxLÙr?çn­Üú#€‚ÊgTOüJ›V8iHºQ²$z<§¤Ne:ƒüÿ]‘ëç:dæ½ŒzlÁêì9I/îæŸré2 AÜV9©ì3şòÌÎI¾ÌªÇ¾úÉúÉnÂá¢Cˆä{^ÙğîS–¿ÏAsÌ‰š/ &:T”õ¸®w|£Èd©~éàGÄÑ©â8©ÍùàW>P±,¹œãí<U‘ªšjÃg~€{¨Jæ¶™eÈ@Ó=üÄĞdASŸT}’OùmÖ.@p%âçl‡B³i,¾ãpìñÊv´D$@	¾†-5¸<g-İtæHX}Í;W½˜şj[vóëÓB=¤_îKæŒÍ¿$ÚmoJßÊÊ1ÅLG€šĞ‰›Á¿
ü5hµˆvÅÛËÃ8áÕ‰“·Åcrééi÷M1PÜ;•
‘¾ˆg¬µ¤9D\ª}„C‡ÿGfÄs”NgĞù¦Äá>”'ûp¡á†81oø2ñv £oö|c¨±¿á§&"ÜÆ- N0ğ˜•aà@9iÈaÌJNOVÍÉ»¢™NÖA»&¼ğb´p-'èYXFv‡>ú¬èãùM
Ã1cr9‘ªK†~¥87Á«eMÒåEıÖÚû“ gó?Ö0eI§(ZYB|iÂ¢±Š€¦¢qßî@Ü±kØH~¸è1¹ŞĞĞØÓi3*¦á:`û€ßÓËæ—j›5m÷Ø"¼½a8bt+)Á2¦H€dp­@sˆ¼Òx~Ù ¨ç¸ä$çR´~`8{Zæ$oĞ§nuœÂÀ°eöƒÓ3`Ö3¸o€”,·y^E-(¢Ò†£‘8Bƒv‡°öÑò»dÀ6ªy~ePm˜¾ë»C&W«+X;±—£n÷rÁ$¥©>f]ê®Ø6\’[ jùÍ²)†	RU‚Åp^éÇM"Éa _á	aìÁâ±ÁÏÓP™×-ÿN°ÒÎ÷ùìÕ—p3	e½ß^(Îë©İ¼ŒÒÁ‹CWàeş<,ø_gÙ¸ohŞƒÀàJĞã¡}¢ËjuRyäÑ‘ˆ‰1›jÛñ‰G»¸ç%kÛn­¯š‚w/QÑÈ`¡©±$›çv]*¨Íß¸×c¢ù“ÆcÛŸšáÏÿdÂ¿µk¨Íã¦íÆT¨3ÙÁiGQğCë	›:«¤÷ÃÌ_ÆÖÓû®X!‰Û(B£$÷¨…˜Ì4Ô_\^$|-İhj¦	kĞ¬Ôƒÿ=¼´×4Ë^¡H¼‚Ï‚×•ÿ-(Ë$ĞkpéÒ–{Ô
b%×¬‡ã0ú0.Bt&l*ÊçŸmÇÈæs"®ïÛÂ¸Ó‹GB_;‰¬p|õâÆı¥g4IÁ…º™ «Òş-ĞIxS_Š€%å©™Ü’Ï*ı†ÏÑ”¢2â$¼ñóM«2æ.)ÛwVâŒ¸-êX8ò¤âM¢Æ÷û9ê´¡&Å|½ÑÑàF$d?9 A]ìF€ĞF9ôºND‹ˆy?O¡¬>Ñ ^–¹61²ÖX=»y%Í+s§IeûÆTmhÓøÍxM‡0át©>8¢Éìx™àó"XF{X¸‰©(RschšC;ª“%JK‡ -Ó5¾Q{ÜrŒçÃwèìñO´•a&´,.æbS»}Ü¸Z¢O½}É<KNØ‘GšóÑÔ*8m©qŠrÌa¾‰Tn[UMHO©RÔÕéº›T}$pªÕ§P»R_•(Lõõ,É(™fEM‚&×í£IÖM6Îcˆş–î
¥z®ÚĞQÕ†İ=u›<EÿU—Œ3AØN	Áßí¡‡@08İ ¹.F¨¾¢7ÃÅı§çü’ø&„"æ|Qma/8oW]‡kMõ‹×µrÿºÎg’F±êÑÎ{·ZºÏcÿÅçÚİèÎŒ9hã;u1µ÷ß.B…8î²ğIÂÿÜŞï*Y—¼ë§œnDê\ÿ¼Äìzö[p/%§qàZ’—Š÷€3—O‘]êÈ‡DiG§ËèÏ»p’WiO$ë…È<÷ÿ†fíÒÔÇÖyªæúâkÅÕ;d=î Oıj“Ä:Şú	Ó9­Ô
ŠeSµ@¶˜-rõŒWòî]+»0Õ¼UïÏ¦4ÙßUõûYu]]#q"ï3>\t‰ù”r£€ƒßU4£Œê¦ª¶CWuwÆ¿Æ_ÈzâN¢ıÄPt&.‚8¼x½tbàtÛDor´aT"uÜª¢coV—÷Õ«‹ï-±Û¹©ÒYê–š}1ûUÜ+x›+İ°nZ+viÿ	ƒò½Öê>“q“	Ö$×"g´²@‹ºCA¯ÖçÁ%uÀÒ{Ú›;ø{¨u#*M¡®¤‘›Œ†â’%#/ª<¸ İÎ×h~Í‡•1Ú¿>İKJ|^³°ª³ò9Œ üÇä±ø"$„ÑÑ""GÆbæİUöÁ‚68Û™JmëF 1œwü$ˆ]½ˆ9³]zBü“y”Ó2©	™5xI²r£¥FqM&î€®+Üt©­¥³!”µzîûé»9t¾§-/aãR2=ãıĞÎ˜ ŸÈ4³UW¯Ñ‚6n.ÜI©¨Wı($…`J£zÆMš@D+Ö½+IÀíÕ¿†”PãtéĞ”Q;/ñcoÿ_@¸tB&)@PYK¡§ã-&¿‡¥eQ*hTP™Ì?zIÛ4Ù[±²7Ô;ºV©R¡´"„€1ÈxG+3vwä'{¯Åê‚Íğ0Ñß1îˆì¶®l1ñÊŞèâ³bş+u%)VjèŒÙÇ…Ã`À¤ -¼€Ğ#©vøUãâFš=PFÈ›¹ ~@d¥ô T¦É¶õ=7ôzFÂBVŠ† üHÀ¾#ÍT“7³Â<i¥„É4Îë51,ıç5àÔóã%éVq¼;·­t>šÙ~ÖÂÌ0ŒñÂîN™é\Ès*eñìèÄåBŠåÄùÛÿÛSl/HíZ1Ã¦u·ÓıNç@z"ÀW§ßí¨–3 »İ\?•`Jg8òr_µrwõŠ˜Ä¢:]7¹Ç`ÛRÏu;|`Í Ô«¶qPğ—…œV™åx\¸”D‹Y=æÃ¸ê¼è,½Wa`³Íœ)gîÿ›¼ÒÕ~ÿ¶®"¢*ççÇ
”#¨[×À”hŒÑı,€â“\3vÄ0¼´µ&Ñ#Ÿ«$_‹z'^Ü‡›‡ ±Q–öªà/~6’O$ñÎ~›è»nIE”©YµSF5´G†ëV/ô¨„0í)ô^»åÑÖUa©[/€gisgQògœ\">ƒ D­ƒŒHßtÎRÎX#‘|¥Ô¥@){4°LÔ8ô¸.N…SÆ}?ª>orYüšèôÑFè&J”“+ØMg:nHZŒA¶d/¿>¦·1<2B\áfjÚ»¯oâ*º:CX6“ls·1Ç& ¿ÌPßeC\“C8À@<7+ûÎ6à/ï´ ›[“ZlLÍÍfhwğœ:É·‰àkA7Š²Ü¾İ0vŞòm…¢\…R£N¦€bS^¤»Úcû‘0üÏM…?|Wào°ğm&:¤k91éKZP)»N	¬áˆ®‘4ôîq\´˜Ê’=ºÖ%èöqÔy/ºÖ¢]X#±qi?àåİßÓn‹êp×f2ÚÆ£´$(ı¡s½±=[fõö 
Y‹€c°1Ÿ™vùóÜ ¬ o´ğò?9ÏçÔm
TC±²*ÅtŞ¹í6ş:°@lDøÿjüE-hKïã»°¤g&”R¸ş uqæJ~µÎTğ‰¶°Mí»	·|ñºq)L¥_³?Uw«SË'ëŸ„;\siùx«`íÏ™‚ÚÖ§qz~UĞíåI€Ùt9ë˜ í½|ô–ÊŞÁ§NÀ3¤^˜<*ÓÏº ;»$Ç7~è×é,CÑ{Yúª-â#F®ìÃ¾xdv‰VÆ±®’Ô¸¥(riÏpc¸§¶ÑR1ú«ZT–¨>J/Ÿtïu×fd­­”MÔlÊÊ)¯‰f´SğòØ ×˜€Kœ•˜\(¾ÂİıUªªç‰êÇ$0>èzLˆ™š“~°->Œü;}áİevãh,¬0b8ŸP{ü²şj}ë¬*„=Ÿzû}j\Ù#$f%Ÿ¢ÚOeF -‚p…’ºŒQ-µM‚x¨ÒK¦QR.02^Ö6¦¨€… ‚ÉÖ›¿q´ì{İ±éàbdNsÃ"+$Û²œş¿íós $ñW›Å¾€q¬ñ,™OàO½ğcÖäîk×9´×Ş‘´AÍ
Ÿö¯†Ø¼{5’pö‰;¿$Ü·†ïqø4&WÂ>nàîÏ·yûĞ?X9.w‚v®Îj™,q6ÄsÿıiğÙ…ÁGwPk2K_YD®ïŞ÷b.%™¡âÔõV˜‘#’YòyA ÍrY!4ñ¬û¥z½¶‡c«rë˜œ’°%<.Îi|Ğ†‹:¾‡şÏér<ª/Bº~0¦E]±($¬]Z¸=¥§ŸN5Æ0ú´a®s^fäUğ`ŸÎ÷}%õ¿…xQHñÅb£×Ú¹º†€»s.GÛLÜÛ¾vÜd–wÉPpÍ³Enläoµ~¸§Ë°Ó	¼õ~»›¨šPõ8–fÃ…-›bg^U‹%In1_ŠÜª ²2É&Ñã•e;ly J¡…šaOt˜®.V÷]ÕÓVñ†rj¶ØıãÀş#Â_«5…J“pkëëõ¬+«
ƒ–£8h:s#,%®ó(¶ÇC@Ìÿe?ŒóeGKïF†ÎäHÇCãÑÚaXÚXı‰!6ç?\ÀŸT¤lïŸşX0v ²/C”ê )í+CÀŸ­aº>Fy1º¿@J÷ui,¨#qˆèEA{
36{ìà“ëx@X‡:e[±P®ÆäÒÃc¬"O»* h*Õ1>ß¥t½ Ä{Ä¼g´DÎoF°›ŠzÌ_Ê÷.–gÜ2d#™ÿTKf/ÏÎ_¿oÎioR€iš¯>su·ñ*útæÖ6CÁ)›tF½!oâïàCÚ”¿Y¨`Üv-9ëŸ‚;­–%™‡ºVPØöi¿Ö¥í|T­Fùùq¦‚[ıb¬ÙW
v—¹d¢æ6„ÛÙJY8´ÙİM ¨J\à:ŞÉÓ¨\xâbàînÑg©™êwğv¨ÙáÑráìW8\±ÃjÑö{…pĞŠËó•ÈÂÍµ¶¼).9(d?Õ×? äüìß_ök˜Ë7ÇW Ñ_n$1U¦zËäsÌO8[#ª“ò\Š «£ÔíİÉe
ïşgàY/5î`V$úÎ»¬‚¤N;Ğr¸Ñú/"4­ñi®<R†Ñ™UN‡¼Bˆ˜ï 1¡­Á[vEÊ·° }”Õ”Q¾g-·¿óçË@šs±Ğæ3›ZQ2 o›‡z†,Ñ¤“A“ûiÜG’ÇÚE¹]~>«dËXv	ò(#dÔö;´ÜÄòõÓq¶Â0tÚê#Ë÷…Ö­ä-bÕØ ú*Aé¿ıuC@±w‚³9Œ¦UyŸ)ãã"–’÷#IÇpº¡A…‡Ñ’± <ÿS¸ÕÖ¾á÷îP‡¥rrwbó{Tº5Yç¦¨‚DºaÎ±Çì2\‰·¬’…¢öæ„eŠDj+ÄnWæD2ëdÖúÈL–9rÌl3¨;\Ñ*Zı{‹a“Ê©âdÑs™ïUÚ/iîb2Wş¹Ö‡sQä´n‹;]VhÒ×^¼TsNj¹“ƒsíÆEË×P¯ÚŸÍ$à’ãïƒúFõiÀJ¦×“ëµq¬Ÿ2‘rB6,¿ø’§¨aÔYğ3ëkØÁÃç³³ûéì×ÏıËá_Ø¶zlö=S…níK™•ÁäuB
¼ëP<¹©İCK{^,7,A†â'Ni?âFkTˆ+—D =‡í×¬ìÅxÌ+çËPñ]”‹Ùöê¾­ò	íbO˜Ü™33Çƒş>Şa~ş³r¾ì¿qh‡öc‹ÍRA\ÍKáÚ‡g!œ‚)è{
iáª®÷óà[lÁË©Páƒ‰ó+Ñ~:yD7³¦¯^á,lC~#¶Ç=hÖ’½Yå©ôCå áßtÙX-öí¡$ÿd¢O]TÈÇßšó Û‰¦¥Õø»W´×ù±òŞ#Å!ğWöĞ·åPƒwÄnÊ&o‹‡jÍ»Ô8Û#ö}Xû)*eÓµ™—?™Î"CÉN°¦Ò&8³´e¯šˆ‰û—ıì@í!à®Ì²Î†ñˆÒ-VfƒXz¤ª¯²·_!ı$¬‰YwÈEø]ı7hâ€¡’b>ºÍ4OâÖsiûeÄ³c@%ø-zú&}TéÍ]zG°Çğ²±JdŸ0ıÉjˆ2"-íáÏW?¯É¢ctÁÌJ0¯İºÿ¾q&zIV¾›Ü”dÊÎ,¼¦Àb¦4Ê¥¤Eø£ÍÄ„µéœ) ÒRBê³gB³f, ³eõµXg`±ÃÜÊ9ğèD•.5í528æœ2@Ï¾¿‘9°:Ş¼Ù£¯Úh_ÂuÜ&ˆô1„3·zfß¢¡=i}eKªÚ‹¤gŠÛWM¾Ë]D¶_œ‘TG7Ø×œe ™Ağ¸¶:½™ºWEÙRVÛè»[Ôç.»×âw¡×cAş‡EÍÕa¿~w „ÒÏq‡±CÚ0bÃEÑz òi±–’V
A½»™4Eş¢SM¬wdx,¹$f6ÎÎÛ ñVyZK*MßŸE›š(îxš¹h‰O¶/!9l°òa,ê–M÷Â¦áÈÓ‰É§¶g2a:¯!”–kŠAyth‹5yä»ñ•ÇeK/¯j;êUÿôéĞ˜ª\Õ`hÎA¯ğ2zÏ•.³Î…RB5Rî}¬Qí‰‘è¨+>€5z¢›7—3ü–õÎCg~ÂÌŠàjù
ZåæUª·xÛE '9¢ö!6ÄChÃ<ãzÛ·˜øNáLšßhà™^9ãK{—ÆıF•£å6}\©,Ç^rÖÄ8ÂÅ«{ˆ.“ÊT¹ŞäôÉ;9¢3À8³‚ˆ }Cgü¤¡#f[ô ¡ö¯êV!Î[«Eßä£ ˆ#œ(Ÿ×ö•‡ãÀ·=ıÃ«ŒC¾¸ET@‰¿MŸ¾qÏ0Œ¤®”†Ÿ²ÄUL4ªxËáÔQ%è-¼åĞ•P“)—M/Ø¹Y†;#“qÉ úük3ÿ³v?ÏÔ€È×c°oÏYy<…&ğ¯7Sf¶âƒ’t;,8×M¨=°´ÙS¨İ¯kºÆ*¡"Ó4ÛØye¾EÇ/jˆ¯-2p‘XH×¸Ê4a“mJÀ»|/Õ{çYlJÇÓçÿó¨>p¶®sñ¼Ğ!™ŞUÄ­z·Jv’Ğ3‘éşÃ‘á"¶F¡uM%D1C=ËçÀCEÍ*uì¿½*"7HÅ*´Bé]Ä:èNš­òzy"ô–JqNõ½‹ì‰1OøïÀ–¯Èü(ÌTªQÇK kº6„šim‰!¤ÆsÈnÕÍ oHl—Ä q`jï”¨ÕñŞ]_1#¿fÈ‘‘ŸJi•í%WCBMJ^ßˆr~jbÔ Rğ˜mbCp**b²ò8=Äz¿şˆ8¤¦­Ò ¥e	ğµ}qP¶
È¾£5ÜH·'I>éÚË[å*B"Öo—&Ãgz³£`–4ñÊ 
ó'G¶c¦Ì}ıüx0õ …8G‹òÎ*ôòNré7î€N~¦íä0ÍySÌ5|%(ôšöZ:í¦s‘©	Tê Ã…$ñá/6j‡´¶Æİ¬$Wjˆ§LcdØB]™Ámc¢àšãœ¬òÃ‡g¶éòº÷M2!ıô,"D0[;²ï_ß­ñV”iT²Œ'ígq²xà½¼iqğ›nÙ!`kKÒm_íÕ~a1YÃxGê…UÓ¶İšr§§¡Î´ô¬Jw´ìú–Ãë9À‹¸İŠÜx¤,%ñÄ™ëÓ¡é†öí©‘Ò’M
¢_'ù¥r¤6vLêVQãå„ñ…c3ÀhÎk­š$êĞ¨­Öh­à–¸Ó¤.Ø´T|ÃŸ÷…¹Ët•ôeÚø¢s£Å1Rõä„"åu?ªó\T-;î÷i¨–^“†Å:]ØàäyvõÜ{İN
&bÆimj·<t€q¸K+%{cä©K„5:¬®”~*ïÌŞ»ì‚?ÄœN$/2R¶†hÒa¿MëÒ.é[3 ‘¡¦àÙõl¸Õ¦ûƒİşióê±BXÃÿ4Ë„(Št¼Äpz<%üçËltıÅø¥ğöëÌÀÚî!ò˜U¹ß]Ëú·í¾TnIØÒ«É3r‰©U˜]#7"ÌænvÛû9 ¬Ãıãí1½Pbœ5Ëgÿ‹P™âVEU'IŠ;4Í–ˆéSR5ÜÔ‘ü–Ş¿…º§VÛUslÅ÷±.•†íûŠñÉÕ€=­šÈb Zï¾ËËı½VuÇ3Ãª9‚Ä<8VVmw¼7ÊEDñëp·?70Zs_]=C’¾>ØşÁ8®C#¾£n§ì>r<Êğd!9Æã&5\cåÓã,U—`¾›ü[vlÌ°´¨×tE‡ÿŞşJ&ªı|Ş¥i!»;'ÓkB
\w
Ş4+`©¶ï :ä!í'fîŞXóJ%»@óï}²&H£:†~)6-K³EcÒxo,ÙÔCRßÑ&&qºçiXm¦,½Æ9W“§äû¶œî4$C=Üüíù;R¤dµS$$~Kj±qİ–+¨T!Ö¼O)ÖÆVÀŒW¡8”ONK\h W&vƒ/h—dÌrùœw.öZ 0$ñÄüÍ¼!€çŠ%«¶¸{{L/½a^CQyI{¢ô¶±¹v¨¥v_b–YC¶P°jepÈÁ…Ô˜I;X©*ªš, 8@Oİ.Qôº +3â¶—òø*R½ÿÕ uG”µ¼¬00:û„—1Y$\-ÜÑ§éÖÑ˜:”[Î¥¿¤ÌÏ…Ÿ0}ARàİ	;ÇÃ¾Ú†Pu«•6öox£ê.„QŞˆL¸£é¨¯{ë&Ë·côXsƒ!N)¢V3ŒâW–´Ÿñ^mæî³æïˆ™Û^¶U ĞyP¶R¾£FHCºœÍ»]DÃ»“f:
‚;Fy Ïùˆ·ıV‰÷RA¬èÓC‰ô+€Káß`˜èA2Ìœ1#@5tÑaiÙháw-u¶1¶y;!Ö`ÅU+3nrØ…fe²ëºuÿíeø:¢Ø§åÒg[ĞærÆùhaÈmä³'3[ëE<c¢Ï™¶e8ªº§=ÿ!5¢u”	:ıHKH™ÿ¬·^—x•½¹YÛWçU·ZÑA~¨fPö ¬²ş/¾›]Ÿ¦†p™¯ôÂc¸ğ®D7„(·ÀbUxÁz^t Hh¸Ğ ÿvÖX<ØáÿR2ìvÀ– TÇš˜WÈédºEè‘zf¥Ó|´ø–ˆUÅ8Á§hßÕùÊ!mÛí'd/Âpô%ÕºZ¹BÉØeŠ(˜ãhÈRÈ±1Ù©Ü×ÖBÌhÏŒ•Ñq;·f’ÖC	cgÚ¿DáöG¦öiHpÒM!I†ßÙ|ØÔşÕå²‡W*Œ¤‚XˆkRĞ¤Ş¹xWV@à²æN±¡›eåóHxÈŒ •×HYÏ]ô°Õ²zU…CJ’¯ÌE¾!¾G8ËQo„;)™Û½û~¼ÑØNk5"\ncê2ÅÖÃVo(î)bGBá0²e¼?¹´±>÷N¢{S½~øgß·]PÅ£ìÒ£œõí'¡z:õòµş¯	÷wô†œ"ƒİ:·‰/ s¹ÕğGÍQ¢«\Í©Ö®¨ş˜æùtKßí
VĞ°_ì^5•Ë~,†J¥Şş=Æ ÙŒ/"ÚınøMi»!v¥_õ=!ömGºbÓÚé  £cö­41Sr¿Ç#Ae"ÏÂÎ(9€rá!{.º†„vùGsbep¸EıvFTAÔL÷cÓ—™2!Vk(¯Øš²EÛ¨òÒkçY;¿}ë]¦,=^²jÄ(ü¡Ø«_Ê…ÌU•öŠƒö½ı&^eÿ" §$ù;µM\asÀŒiGÓÚND6¼.¦Ô+Dë¤'rİñè5¯&4%]|Ğ¼(l]»Ğ`kNu0Vh ´à5üù_Àc"¯¡"1­èÈYá%áòä‡Ÿ=—ñÊ<$t¼ÙÜÒìN·L‡KŠ1ƒ&ˆÃ4b{}¡¨–™Úª~ii{yK/ğaÃÂ _õ1ı L@nÆ"QŞHl–x¦xˆg‚W&Ã«:Ââª3:qïô°U:3Àµ“iV/‰pV×œ€S›öÂTÁÛu3@O ®b¬6bº}©ãæÔm_¤¦¬ÃÉù¶+P¼àİq<Å4ØŠU€™(îÔdÊÂñ„waõj]Î'Öq]NÉ{5-ş@’°Æõy3 <*Š+Ğû#EA©LrW©l"iúŸÄáKâ‰Øñ¹{Ü^¬³¼É¤·ffNÒ}­¶W»Û]Åó¾bá'ïªû”kÃÚêCø?ä†g"×MÖ7è;œİŞàãûŠ®÷³29“Y5sXsóÌŒ'Î–`C¸ùĞjçÍÅPk“3±ZAGMè’1Üı·¥fsÈ”Ä EŸJ`øœ±ËŠ
â2¶ØW4ü9íÚhÈ¾–á„aƒÔkaD"Jñ‰ŒlYwØä3:÷Ô_®Æ´‚H¦/0+ìÔ…Ÿ‰‹Œœ„toµÓ6H‹¦+°¼#%@ğÉ5ÛB„²3…R‘ÑúgRŸ+Åò{‚p[Ü[à¹wV§A/T“yÈÏQÉ9× ø¶¦fw0½ú98µ[afc±ÁÂ3}$ùo,vÚ§øïÖ7¤¨¶ˆyrõ-^:ã‚Eÿ¤å^¢^¢Æş‹´‰ƒÇõÃ>õ
š¯§TÿiÒ‰7Ãˆ~fÃ:²Æ)6ŸÓÂà¼yì~èÜ¶H6K3Ãş‚Á-KÉıê'_²ä@­ÖÈÌ­u0Âü:£¹IÆ~Œ;3ÀSçõıôOk>Y»ïZŠuü9á¹YRnÜ:¢F{òèñşÆÛ1ï>œyöd“£Ñ¾ĞÀ**˜—4ŸAÕóÑQò[u…´Ş$·Â“£Q#Û@Šû®uµ‡"Á°=NÜ”ì‘Bß=E jI_d¸Øç·Âm‘ç˜K²3ñ;“;]¯ÜöÆ(v[&U¿êòìx²ävq­,Ö+wQŸ”Ó%ëh°›ğç)}yÏ(óòØ„ÄA×RÆAäÁ^…_ÏznÛ—Ë…>Ñ®ŞZš‘œM"›¡å’[«»º8<¨)»0c$“»¿iåĞÛ§ÍÕcKü@~y¼ò¾İš=ÿ_S%6gó³òõ¥¤§T¢^(Ç„•õ­t%hZúÉ~ğzüÓçÅm qöÜ¡›Æµ£¿æ~ú-sÒ¨|™ƒÏ73|³jõGàAaJ™º-{J©ojÙŞ”½Ñª@lÿÜğ•ëˆğ%ï?µØ ”Ês“T/´hVÄ)ÕÊk0şœ¶¹%1Bˆ9«Ÿğ¹%¾Î'ÏLf»\k†-0/Ü/6¬ŠÄl@Ş¾‚Xm›ãF“¯nù ø¢ÈÃº¼½ßâ†•#g2ÿÊ~+”™¨¯Ù‰ğ	Çá5q¦¡$zİC>Ş	b¢¤©šk¿ÆO[8¯ş{}d~	pë”­K)a²ÈØ!ŒİæXÀ¡-abäĞ¸möĞòG8B<zY-Ùö]a,]ì(İ?Ên©N B3êã`£„¨õZ¤?_÷—–‰yleÏÚÕ'-²‰* 9@Ñ×ê³(se›+PâûEm©ÎµŠ¯((ùŠš³ÙÈº, -ydOj[Att'¹'th;ñ²’ZcÂF³&ü\Sj“~…NZd"Ú½è¦X6+bZbnl\Fiò¼ÒÕtj<=¶y;Ï.ïûóéĞqË÷;x­¨ÉÏû”H"wAv­ñß¼¥Ò8T&$e‚·E„ ‡iÌF×ÃKiRD¤šëFëÏÉ–)ƒÍÙóh‚áF’Ø93Ô„åš{³Ucİ¬Aë)şŒJbøpíºë48[±Àñ§³Ï›Åë§gÏÚ©×ß¢‘ü@~ö¦™hªşï¼¨J$Ô`˜8oNÑX
L$\0ıxqæÅfX"Â9 ËÈÁOÇÑÄŒå;¼7~ÄO~{²>¯-Z tvc\$©%-c¯ğ†³¿:ÖBÓŞ;Á$íÇs¸'U›	mN$nzWÔ¹ÄİqÚÏÌI1Ìß%U6µhBŒIâög²¾6“´%
öU]ó
$û{¦?ıh×•&¾¥ÿx"”}²E°‰¿ùüÚÑ«O‚Mô@Ÿpæ†3yrÛdÿ†KÚB†pRNÕYAM” *f®àÎÌC5øÈFÛ	™¡<x`¸9-™ğ‡»í…›b#df"£F ‘dİ71ÀÂ>œ„ˆ§æSúA_i/ æãz-â:À:“¶éõE£’k·U}û‘í‘}3èÍ¯2Hm®®MĞg\‚dy_Ü?‹¯¤ï"–7,ëŞaØçŒ¢9?º#FÊ@‘Uˆƒ*†0Ÿí”"aGn4ÙÌø+Ô1 ŞşØì')
dÁ²äo:$ƒ/ !¦†WDB#ò¹vYşûD°éFXÁqóh?²âC‚áÙP “£æˆÚ¹ Z>ÊvÚ*ÙuâùAˆ´µvnpÁªQ[-m¢kéàF'ƒ1ìP7Ö7ßúoëÛµ(årƒ
­¡ˆmÔìxÅÈ\ã5Â1w±Şì&²–Æ-®=zwÖÀÖ/jºrí—]óIN®æÔ~¹¸¥C4©Ú°@™À‘–…ÅãTÈ?ÃäúKq{ùyÉH¥Ÿ–‘ÿÙAs/bÃ­Ú®eüŠ^Ãv&P¹.ZE õbdÉEÆîë HŠÏ³?ÈMDŠXãŠY-&ª& têLÊç÷M»ê¨täÂÍ¨À¹ã;è´Wï/“WÊ¢W›¢Øüù-„Z	LÒ.}¯ÜHÖâÜÛ=T®ò%şsx ¢bÕÇ‡nÛÆWˆÁşH zíA](¾WŸ¥Â³âL·¤J"¥X¬ˆŒ>9ç¢µŠ†µ	x+ı™iwp‹âÓ¦€éD9é/™-á?âŒNÏ¸‰X¾Ã I%‚QéigÄ2Sx	‡4'´ˆ@è„—¶©5åŠ7îÏª93t‚áÆC&„ûÙxËİv£œ/“š^‘2%O“ /d<nÂ[İG‹Ü…D±ÿÿ?şS‚TI]_½®³»‚Tß;1@R^Q€„S?›z‚!9½F[4Cåÿ¶å9cÄ?¦§DøHOÀÌ1øm“ƒ¯ùÜŸÛpØ•hGÚº!`gµ%Ø|9·¸V¥úÊmUt“õ¬[°¨¹Û®f¤€‚ëÅì¯Šö½ú_{¥ÑŸÄ:L#¯Ö#¢AË~Aíøöèúö5×Ğ`¨^9ÁÕIwà°m'¾Zä%ô]|Î>AÎÔØqİÀkƒYNH}º>Í[0£{±Æ¨FŸô5lÆ8G‚iÚ”DêÒcÖ»Ñ³IùV``®ÅÓUhé™f•"ØgûgJOúJuò\J«DÜ{ë^Ûï)¿gjÈ‹ÔR‰i`.ü&“œãp½ƒ+Y!	´&•\Cœ!ôĞp¡^EæÊüihªN“G·Œı÷ã­ıÁè,ÀŞ o$uøy+“×ß½Ïó el£«!m^>¿úA}ÏÑµ,‡²¯Ïæ AK+š;¾ƒÓ§"”ÿ®[K³îÄ£½ÅĞr`YÊ*ÍÇsŒ·IŒkU#Xé=ôLĞ8£›×­©¾ËÒ7;ãIÁyxüYjqü“uÒª°×+dwˆ¼–ÿÙê¡Dgê^!z É529OÖò+ÜÊp-/cÊÈùùçğ`«1!ác˜»}Cg]¼Q\ôÁ*øOGH¬M1=¤>Ó&›B/FœApŸ>œ¦oIàH²¾Iw)^Lİ½ô3#t¢¶øFÏñŞ…ÚXÊÈ‹qÅR».ç«<CFvÎË:•ÆR§øQªêì¦€Ô†Ğ€µfˆÈ³)Ïbòìü¢Š—e@‡ò®Œ/H‹=û` ÍÙB•yª¼
“¨@WûŞÉA<*0‘*I\›	ĞHAÍ°	\B•![…Çÿ
&?HX‰G/¹´LèVŞN|ğƒ¡ê	é¼N/¾UPg|gæï–VDƒUÍÌ¦ÒĞÿI ï’®ç¹¸Ñí –,ÜÀ‘K^ÅèRTû½n–‚aª„ªîĞø"àş¹êíªŒûJw‰äá@m›"î“¦Fdù
¢[)(à[u=?›Ğ1e)ı¥án”Ë7Tíëç£ó7YßLp¹
DmQQ[˜#}®Ê8SåB˜ü=a™Hl¡§L0£¹­£°—ø&É(ææ¢$³C¸Âsş›d€ZÑ^RöCÛRf:â˜{üië–ÉF®pèÏûŞ´R2¿4ü"¬­ë×CÃ‹|ÃCbÆ`Âï8qµØÂMÓ–>cÍ]i/»Ê«¸×}L`:ãzÜÕ:TØ$#ÚşµõÄš4¡ ü¿ƒê4¹×·ŒÖ½î”Qò{_jgP¸ûŸĞA/ÌqH–“9ú›µjÿW}ˆŞ¬ßwKà
±õğ6“5±«ÈğXşö4Dİ‘a¢O43Yím¦S¹n•¶¸,2p2Ów	:†u°0Út…›ĞP=ÿÑ\Píªü©÷…Ã·×ƒu.ùÂ¼Ç±\n±l|aª?ŠÁgíA,üĞuÑ®Á«–ü+3¥{ı«H\­vœ0}5mÕı¬í¶ƒ¢Õk úm¿²ùTÎ;*!JôñU¼×ƒÖCÆT&!Êàd8wõØvBŞmØ:€âÜVíÛš¥2zØlı/›&·Tj„Y	7J¤Hï-KbJùF’¡“éõ›•ÿÎVÒ '7Æğ|4@q§OSM¿/ÉW=Çèëi80Ù·§ÙÔ?· ·dAr#Dêrî·Ğ²,²2•Ö§?¤b—ºùÏ’õ]@/5;{úÔÜ›ş`+%GŞÚRò‚Ğ*ÅIaò©¯@µ¡ß³N¿E9\Â÷å@RZÔZg-_ĞB\ÇèŸsšE‘¥˜: S3ö_ñóùT/èXL`FFeº¨GâuÛ­, ¹&Î¢dOå3õX.‚]gÜ‡É“¬ŞäSEè²c‹dõMÏ_$ÒÕë¿®’1õ…ÿÃaÏ•K
f1ÛK"’4nùXBu¿°}œclq#x·†Šœ{Ã¦³?a)O@oøËÀúí³ÓâêœŒ‚PÁDeøw¢5âæWº=©QêïBäÉ=KŞ2|¡'K*•õD ‚ş;ÁÌ¸!3L"8ş/*'_[lœ¤vaXf%1ÔÊon •PD¦£9m˜š•n»}tèÖ”è}ºÂÏİ¬9¼$Ÿb¬Òš¿˜cåsM®Ò)øï
*Wm¢$<0bºQwì¡œqw³¦”xöKªš"J}ûÚÂvÌÔ¤ÕŒîğDÙ Ä—¥3Ôv%oÄobËúUò¢ŸWÉçíØË§«z¯ğæO}¬8$x DÈEP‰„a€a†WHğ¤ú†-Kãìcıø/.ëŸåbÓoCq¦È ös[Ä—‰ÎªÌÅ‰9‡•M{P IØ’ÂM1F‰ƒğÑà–@Æ*ï;©UÈÇS÷­ÕŸ)A&ßˆ]ø·–÷ÜíÏµém=ë›SP½RXFùœW§Î'S¹Às2b]×©š²‚à,.¿hs÷J<Om·CÄsäFÀ–m…ÑFµø~xœìñÑRæ>÷Å9rı“~‚{‘Å])˜¬EºfÅ‹IĞüã†˜B‰ãi.1“ÓÕZj¢|"ÍCcÏ"QT1×áfFÖıñ»Å½ù­ZVëknÁûßœ–DS?+HjfhZyÛƒĞ¿KuhM°{¿­åæ«kEƒ«<ñ”(åö"0“o²Be0oÍ äKˆêåS¾å^H£ô3Iü~,ë„ú“J±HúØa’‰#Öko£oŸñ"'·‘½-Œñ¬]¡gãñ·ÒƒDıÑ
åßÖ+Ésİ¾UÜ=¹æt¡¿šÉ g¸L,·B¤[:·ôK„4.ŒêÀ…¸w.PL¡ Ù¸ÜM]qök/uYßi¶%è+øŒáÊG{õp¦ãLÑ`Vö¯5›VÊ¡x 4E,Åğ?ÿV£ÍÙSëO‘ZXµm5HF¶átğg¤|,ÔkÕ1ä+ş·¤S¾~¿Ó“õ‰¬T7¾œĞ€iŸ*—çõğøÁË•Q÷\Ş¦óó¡ƒ$µA3'»Ø-T@æ"ªÑsJ›QÜb(hEªª&d}}dX’ä::™‰*ïÆ^  ~ ÀZ"@(¢§59`+—;‚8tCn+ÿUan7}_ã’”kî»/Z.­éêãŸ†J¦y4öËÿ?N$KšRû­ïeJ%FRË+a–AÁN/F#7‰öÖIºü ¿‚wb˜»›³2D¦ş‡m9Ã¼y®ka¬WBôÎº£\éEğAs®¶!âbÉ8ËÇ¥Äï±œ s_æC3Š¯.&¶Óàz²h÷³Ò›J«Kï]8ƒÿqIPÅl(}	±v–R¥		|h’w8¾ºa_¦@:ŞÚVÇ¬ª¼Fè5¡ÚÄÂ3“Ê…@áİ(võU2ÆOSe˜ç¶-ï²£ËÕLæ—×ÕÎF6ç Ì—ŞàŠÂJík^°ËF§ÃìëÉ¨ğùPüàÙ’]ó¡²´…K*ª„àHÇPüvYê£·°m”…&Psğß" émŠè×“Ü•`t"2‹¬Û²È¤Ï2y%°ZYÕ½_Şy@Ö2µkl¥Œ4›X.TÚr¶?æöı<mh¼¢É|9‡H£´7«µïzPmŒÙğºğSñÇÑÒ|¨±ìf{ÔêËÓäLˆı:v$ó¤ ø}.€¤©Á#dË9Ñ–õ5e?9&(»ÃM«ÿ9vÃ­¯óÇ¨üs¼•låªïj5Š­jáÎ¢ªK¶¬Ãıx0k·HĞ âÅ§3­”òÅˆCê
$"©±‰f¤Ô¤ò}tU¾ºS‰|GÃÜZsĞœÀ Ñ¼ßÂpÙ™éÏÁğ)@º¹Ÿÿ/×Çµ›{Ÿë‚Aÿ¹ŸCB»ÅNTJ«ìîÈº|‰D±xŸ#xZW?|®r'Äy7°8øşñ/CğåÄÈK"ˆU;/mıùlMÙÿÜ¢ö7ã*êµLµ;˜¼Äé³FGRùßŞ™áš_´¸ÏåÔ7_Q×mGôß†)õĞ×/÷¤êtàó)Üê²ô|‘/¬jFL™	Q%­1…HªJ/ªFfåã Ü^·=ÍòWVÓì½ŸÙ­<¯Üí}Û2œİŠ:Âh†«Z¡ˆ<’-X'‚c×ú”üR.pûX(Ø³BA	dà|úË«YEA)fóE„âƒ½¨ä´t¸JÏÁršAO	d•ÈèåŸïØ<~TåË–qqĞìyí¾Ó€2«¦ãk+V÷vér(¦YÄŠÎor‹áLÓ£#Àº)†ı”çæ©†çF®r«´‡:Y€JÆKágË[PŠü:å_Lú»Í4|°¹¶ãÉt‚l²´%_ÄmıÓÛ¤‡­&Ì®sà ñ^šÈ¯ê@rÙ¼ÊØú»%õb±!ê{ õ¯×ºëà+b†”ı<‘ÁbZ59Y\TkÆgTöãm¬°Õm6UäXk#aD$ó;]ìµCOëëaö¯éóB~çC§Òä\…s9¶]©…[ŠWóB§H6'ŒÃ ˜8Åu`+»öÉ)¬ùBÀNÇß©^6Ù¡@tàÓ5‰í‚T6#WôüŒ\gáÔIßX€¹”ù¡¸¤ÙâáæÃN*ô#„ÃŞğTÇô.ë¸Ç™§o¹¼˜¹‚®'z/Y,¾Ñœ§‰˜£(%€'Ö¥™wÛÍ·÷e,è‡Å7`/ë.‚è f ª#Û{†_0‚Lx…T³–üÂ%¸À°î¾Ê~ßiI.z“/¤ìßºÆ¶t©Ö óNm…òÉ EöZdw»²¢€s×{2hægglm·[FèøQFÊÌL!zùy*é~š‹¯L.Î•;N•¨÷¨yhWŠ9”5Å^0Á	ÖªÄ<_9ïŞz-¤Z“âÅGØ¿ÿdvë¿?æŒÒ:’%«–ä£—'œV÷ªIAÀ¯på\Æ@?~¥<Í¨ƒ7ëöE‰°é†Ğó[ON@ì€”á¬`Ş³ÃD€&®#ó ğ­‡†kcÄrG)A±iúl ‰P6Oå8I²´"ÑÏ½W´c~dO¤™³S ™çÃÛ‚eŒÏ‰ÍÁÕ1)”ù«Ìá7J"9Ì~oÕsà	…ö\Ìàw5¶a¯M¤gLíl[˜o¾ô‘LËu¨£"ğŒ.m5|¾ú£éàï"í¬%ƒT(„×x÷úß€[]	ÔÕo¤÷kˆÛ˜I¡ûÑü3û`µ%ßØ¹ÿØ:oJ´Å¿F¶ÅòÎ±ÃU¥¶áHi—ë²/Ì70+IÀå`që0ÓxX\ „.–
ı°Kg‰Å¢~±¼İ«Ê¿e0™@­‚ıo<
ÏƒqªÆùèh™·+]Iá,½ùø`7÷¡!É¦ÎuÇ¦€¨ë4B2¢TÏtBøÏ¡w1J‚úßÖŞtcëJI!Bx±ğø!‹k9Ğ¹îFÜ¥€ˆ6qÇbê·áIãCÂ?uÑ¶5~5µynã+zl$‚IpèßÀÓ‰÷ôLKIL²6§|<¥X£ã›‡°Q¥ÎÙ›¶÷:İg€>ÚµÑ&mûWÏrdá¤¥&Ñk¿¨Ÿ™”úÙÔ=×Ö_³ØIKãG‡’‹//YLCİr®HN¥MöÜçêåûñ@Iğ5IŞÎrL4/ù"0¶-ú²hŒVK¾ÉÛšRlJ·€WAÓX)FQƒP›ª©Åv«)>ÎÆy¹ó7·äğÉa²='œ²>3è5ú¬8êô¶n+QËS
&§.~ØQ!7Ùôò0Ä(d¹l7Úà¸âƒBŸ¹¼SÓq²HŒ°KU—Î²ùtRè÷ŞãÛ÷Šqiš·»ŒÕ§–\“=G¬H7ÂB”ô¤§Õvù*\7ıÏ–Y5®uV¬™îÈ,é ±,zÕÎét'Ãç±í}}9çåıü÷OZ3å'cg\Kå$Î@_rÖù§ÌÉ×'fI”TR†»Cí%rA~ÚµŒO“mómÄ:~„–Y×8pšhÇĞQPÌ6Aø´í}*•Ñ°íX2ùÏØM¹ú¡‰rÑsvQÁóH' TğôL÷Ó½¶4â¬]jÍ€ãóJÓcáğ"íĞDªK=£GFÛë¿–§ÆJƒñ4õ´.‡PkôÒÍ<nLŞ Du¡¯zXÖQHğì+¿ı)ßfZw<§Ôl²¡4º¨„ˆ<ù!<}Â60u‰³…Ü4šì×•­Œ›Cæ'Ó•ò?¦Ç±°Q­gAæe'óƒÙÀíär6iäØè‡ç‰Ø~ó%í}ş ÊóÎU®–zJì`%SáÈF5§|?Ø±;p®G,x–Î~'*Ãi Û5°¿4: àµ² Ú×İ²ÏàÖ4fV÷¿ŠÏ/Ë«xëŒÍ{qßÔ#÷p9³¡Wf•Zt•WÊ; ¶5ÅÈ9¹P§$ïÃúAR&Y#‡hL›w~àbŒ%écÿÌ“—ğùc wÖ¸Qæ³ùöµÖ«Ë/5æûäFx á±1ı†l¹ÃòWÈd(â-äïR-W{m{úşUËæØ±„î<³È/4(àÁ™Ô¬)ttÜV ¥ŠÿG©\;SÆ Ì´»ÚÇ€ÜpæõòÖ—Q|Ü£0ïèî>`¹ıÊçz0™š×ÇA}ãŠ"Fm¬"ôàïKP$Õ•/)ä…„™§ø ¾!ıÉğ«ï¡]„6U
7(‚ğ›N^ï”;Ü·÷H„J{K©D‰†•‹¢R7’ÔuN«µŞˆí‹£^‚éOXxnF¾\L:˜í'ú>ƒß!0ˆÀ
yc›
nl‚5Jêk	#lÕéàqbaéÔ*ÔeşÅƒç÷Ù^ë`ÁÜ48r;*&îC‡4´")%n%.äŸx¿s! ÙBRoƒ<€Ç©¯èlÑº•”bˆòeáó"ì¦êÇY;„"W¨"AÈqè€?ú‘úôûØä[0$0SŠ+ëF™…JX ;
½;m¡ ø™§„|8Íh±y[Ü„ÖÅ#­‰e'´Iù¶o-#fuôƒ76÷N¼ì²
z	Èo3­‡çû–óı¨ñ{ÊÅ…
ì‚U[ÄŞ³Ü©—D4Š~·ùÿ‘fv¯ğ´°!LôİWGdÅÒ=êí¶@É]1®N]b•‚üúYL)5ykÅâPbXôñ ÀÉ>ÄD½şÌB•bRc©Ç~ üOõÍyR¿9>ê'î ó8ÉI‹ò­Nı¬o·r.»;òhƒåºrß\Ó#:/­ÍZ¤=ÚA·a‰Ë¸1wåè¬_!ÆÒò¼o«á*fÎ™÷Oÿ®¨êKvG”UxJï.™÷ø¦GMàüéj7ÜHÆŠ !¦?œT–VØõË¤ÿÂš¨!T±tR™gÜğqK‡Ë)­]}/×˜´ü­=hàcbÄÛÕ„4¬iÌbÓœR= ö^0 æÑ¬ÿÃ²…WŠXÂgù™7ÿĞé|yï^óÆ‹9qÖˆÃüÉf¨	^¥hNûMFØçO½Cå˜ëL“¦t¼’Ùú7vŞ1µàÇ×5G¿|’4Ûs50Q+\{7$FÌRÎ¯),Ma¿oWj²°²­ :ôJ]d«¶¤=ßïh_‚ˆn>«¹^;îÜÃó²”¾¤…âp<Œ7Üüah±"Úc¸Tm„oHQ’µÊã—ºÌ%FÚî»Û÷³¸ŞKq±.CÑ^aö ";*qkz²ó	BÄ07=¤cg™Îr¼íwßG™{ÉØìÇ“&É!\0]"Û”`ÿ¢v¸Oğs–±ğAaîÛáÀ|R7Q‡ÇµÜ2	¢A~çÕ\rœŒ¨K—‰-·3”ãliaò½©?Z¶YTnˆ%‚s(ğüªì(òo‰…Øôb‡†&_}aÌevë )mVº÷ĞÁÔGÈ¼%C.mÿÔºeÎÇç:¢Áa`Fˆø/{Ò)L²,rò‚•‘Õ•ØÜ0|
tÁŞ°yeVe"l®¬³½…áùcól9¾…üRÜ!’>\2$­höÇÍëÌLç¡wÕ6Xz9„>UıOË^m†ÇI†•s¬N3éÏvùøC1M¥)o*´?’ÆÏgRöÜû( À—‡©n‚ğ'Òõ®h¼FgŠ9ùÃº×š³x[nÛ‡±¨n!ÏYu©mŞª–Oz„ısÈµÖHûı·å¼Z¤?.ğbëÊT0w‹>íÆìŠl@2ißÚ»çÒËÍ†AÃXÆtßs×­èß¥\¹ Ud,o†$f/Èé¢—YšOkÆÛf¡„èWÇïBBiµFÆå‡Yî¶UF$õoEÛ0V¢;ä§–Ü/ŠäRD«S\x,9Å»Â uá§û^¡ºÎÈV¸j™_ä°tF±êgp<@ûvø7lÈËRº’4Ki½'"v¼2Z:B7|s-8.ç+ğ•êÙ»7yà‡èR‡ºIMcÿõBßn]^oiGê4*³+İúçX½ºoĞ¹ßrQ—[—-úâĞŞ$X#1zi}´êˆ ?ôc“Zÿ|Z¹îU5UÏ%}4º7	8<ç‹'$ÙZdBIÓÆ( (Ìô£ËÜˆóÓy³ÙüF”/¿§]TÆNqD|Êkz‡³å®cÉùìôÅƒ Ğu.cÓ!*÷äÁ3Ä*xÎ‰JTÇ ÆIÙUÌS:)ü‘îqèîè—kh³;¨¦W‰Y«†eÒl§Í“ï„P	¶;Á~¯Ì†{ã¬îh°ìPŸ¼‚f?Ó!·^Ú×Äzˆ‘Ğ¥º‘¥Ë6›|³÷1ªºñ@]³ÕïFƒ;[ İªâ>£Ú)nö*U©ás4e.ûÖ|?åøã;šmvÕµ!ûà¿"›IÎ$Pj¤u-
õzÀOÖTò¶§U[<ÌA¬ÉëşË¬A¡Zw<|‘;ú¡¤m‘®ÛI4(”b ­­ç}¨›ÏÁ“dVôK@±jÁ¢è—šñ{¬;A'XÆ)Òá(~¶({ŒrŞ4vöØ‡”êİw"ti™äÍ>¯lğ…Ğ»uP›I–öÿÉ7¹ú&SaãJÀKqt%ggÏÌ{õ²r>€"'µ1:£âŸŸ¨NÇ¸Æê9étC–3€Í#æÿ5Áæs2ÄŸ>·f¢@¢äëá‘³£7›É”îqƒ÷Ínºq½QXZOç¦ª c$v.-8DkªëØ¶IsKø¤Ó¾°ÖAÅĞ%š¢ª$>Z£JF%Z”qõ`‚¾7Š8G&_ŸÇ€¨ë¢;p7õ›@Ny3÷Òù4p{¤ê[<w'…ÑàíãGfÄîşŠÊ[:‚…¾Øıéc‚$š\~z²oÇşò ^‚µÍƒëø¿Äš¤iïÀˆëZ]l—ÙQR¸Fˆ9{'kHòqû’ş'/şÃ›iÕ<šÍHÃ3âßÂg	·OD 2¦U~­ÏnW.ÎÉoº_®ÿôöÿyt[;Pg}H1¦°åñ1¢aM`6ØF ”SwÎºÄ<¼ß-ÒeÍ ³‹Ó±8KİcÊĞx*èºo|]'°šÖÚK«ÑĞOƒ®|æŞGÅË¿X·áyIx˜wŠv?Í}“§ìå,ßrµ¿ê¸gä²²–â¹«ï¬l5@=–Òo:)Îê£?q5ì¦ÍIÄ‘¥äË¦BŒ¦¦3/b•‹Cßbg§¼âÀu¼“ayÉ¨}d`R/0:5—umzqğßzê….AÙÎ‹´ÛMSAÎb ÌnŠPm¦ı‡çšØCÕÑ'dÿœ/çÜµ¿!.%ïåÉpjåòN>49_{aƒŒXOšI6Ş†a÷¥Ì‡_¾À2J&F¾buşé)rÆ¦‰õ\5²Œ™µ¶ET4ì«¡Ô¤Óœ„²hı¢exÖ¨{¶[ğpûì~gË¬±ù>8rE(ªk†ºV›÷÷õpÓî”A`­æfø÷,!3ª &\,y‰«3z6àÑ ûãu|uÖ³aRc?Y]c”‘­¹¸µ{|Ç(’¬»Ş­º9;¦Är©§@ª±—|ú–õªå&B]T|‡#Š·muÑ
5Õ+ÓS.H…ÑÀ{>š½ºSô—e)Ö¬/4ç£mÎ†^¿àÀ
+Íƒ	hS‚}z¤Vîí6=Âßt—¦R.ŠûuíÚ¡3”ş‰Š×pq¥Âuè÷^I÷&°å®—×{á›§%Y—wÊ+K¥õ{ÉãÎe´.twNÉ:Úé
Cy.­~ÚrÊxó{CÈ%ñœ¨·ªVe£‡X- «§nÜt‚:mÀğğ>&Ò¿±»„‚3òò¢›^sTñî1Á4¤›oÚW—oY‚Õÿ¯­òºÇå	Æi;µcHm¦Ô×ç	½”¾e˜ı¥I¥ÒÊ‰[~vAñ®«iù»U1fC ³ªsÂ^–BF«÷r#˜?o€:{½NVü~U`X"¬ÀÁòÏ1è^0´f }àòû3‡ò	İñ$¸PŸ?Ï~o•òşµ>0Hïg©iˆtÛÒ"ÑdãX{Eœg
‡—ĞèXæ×«Mn‰ô_[«õªRQ<À:¡\¦2qŒÑOá¶èºW'pŠ`ş¿™õ9§	wÃ’™WğK:*¯WŸŞ_ˆc;UCÿCûÜWİr¯æÍ>RËƒixT„†3äÎq¶½Z¢ÙF ~ØüAu#ÔÔ°š<G&7Åñ&÷3©·ÒZ˜¬T³gØN‚»ı'µzĞ'5Ü·Ğ¦ç¹‹ªŸïš£’ÆæqI\+¬É™0¤l7±)OXSw‘úâ(ú]Æçe))'ì›]®kó,YĞ¾³mŠí¶§3Tú1¬¬(ïç¾ÄF]ÎÕ.€—ÉÖ	™—ûW*òÄ‘~‰(,¸Ö¥	qš¶b#Ú¥Š€Òm°Ô ‡À›ÎVúv£N7veÉ}®õ}8<¼¿GğúUÑ üB¿¤¼ší&õşœ(¶3^ºáõ³ø;>xjCIŞWÜWò‰„@©v€W¶&˜Òä]?ÅWFQx<Có_fúL(¸|K.ÖÌ¦™¢ÌC#du]£$ÅëÁ½$ÜFşİĞ%Œ	E³*oÿâ	#Ç)ô[5¡ÂŸÁe-5'äq9nÇ×nŸ™”ıÃU3İ"]¿pNÕ²ù³Šg¢©N aPÍº=ÇñİrÕ)ı4‹—¼FÒXQÒƒÒz.]Êºht‘ë¾±ÍŞÑ v‡¿wÁØ}SËmñ‘FˆuÊ\˜áDRæĞ|^À®L¡´W×+õ.L¥2(HA¬)ë¹×FûìJí…õ¨Ò0ëĞi 8¶¢ªîÊïÚwæ¿í7rŸOPáSØ”]å´öÃş­_;ÍÌ…
Tuµ	kñ"táíWüaÉMİ¼-Ø¢ùY5&¶­ ˜ÿĞJ$hö8ÈòŒ8O®¹BB{¾ì/Æ¦g_jX	ó´ş<:>Sv"D§±÷æú¥>UPº‹ÀŒ="Á‹È¤A¼¿‚vx(Ã*êiÁó–;*ïò2:1$~şê"¾ÉèFxÖÙıäuh@¢ÃùÓâØŞëgby«mvkS?ü‰#½Î
Â…Œ`:†Èı´."÷z^Ók=’=âÛıcƒ0Û²R®"²S•~ÅØ¯6Üö©³ù°O|Ëz£Õgw·oícñâ8·¿ó§—k3ĞÙôTU£ôÍqå#
P¹pp ß{$¶)£ç¬¹ã¨ÉH¦ãû«;%xn*û“Í_#‡^‡€*| ¤‡gôÛ!«aBÖÕ›•ÊİÊ²˜§XE¾>ÎtT¡¹éúüPZlS9új~<ÑËñ›ÂğGÃËæÿì³‡œ{õ¯C‘²ú<†‘Y«ûÁÚBiX"‚…Á%+Õı³ŸğáCı%ñDì(®¢¾ÎöğC@ãce²JxwƒÅ‚ÙMğĞİ¬W™ò³ÏF³.ØÃî9q@Rîé£yvF›&ô8èvOÀìgèÓÛ	G•ûõ×«î²5;ÉÌmİR°î*ÀPDFü}d¨èrê2~I1Ù…÷É¿²JSh¬¢‡/7¼­U²Ø˜Ğ}á£¬Êr,–ëó’È¤ËôÕÕn|ã-¡i6L‹0Ê óî,*V!ìapl›aU’myêw¥öG›ÒÕ†¯÷/Ì¶'ZéTÊ·,Òo;(—Ë”\V i:ıÎz¸Í3g·O·ˆ<ÇŠÑÑù’ƒÁ±Ê{¾àh¡ıíHpæßjO¤XÒ¥éøß–†áÔ¤HYiN?	CC%l	e]Ôñ´dbÀn¼o´sşß¥
¢ ğWT/sü;×Ôá‹à›ÛÎ0hPÔ:?¼ZBîÒO<óªp ìÅªØÉ =L¹Í˜ËZ&°ùÍË™ô9Û‚œz¯Ö™>ø˜UÕaÓ}zÀhÇÕqŠ…N1ez–+¼àò
ş¸}¨¢ÕçC@ÁmÕ‘AU¹R‹ÆÈ;œ
l-„õ2µ¹{,ÇÔâgPˆ~è Ş¡¤pÓ¿¹ëqˆ"°”wÚÏq÷…]¦Œ:ÕıÜãÉ¨¶7TEAÕ>Ãzlzˆ¶oİiÎæqˆ¹ >Ì
äÒ®ï *:ôH‰Ê)Îˆ/é>M<,œæÆJ†69l¹ógø(aô/Â¹¸¿Î~
ÿ¢Fœ:ä†î)„`Êdş’Ätàmq?„tè†=Ê‹J…[!ÿ"§€€”*üŞóˆ‰SYï`$ë"&)fUR^8¾†¤GæÎsÓ’¹Õ~f^8¥­šüO£[¾§P¤Ö}æĞeÃöm¯r]a¬¥¹ùhÊsà\ÓnR)Š†="ÈôüÌ]¨'€LÌMjšä{V÷ˆñ¦yP+~;@Ç½(>¡é^Ò Mä¾Qƒ„m]‰*dµeÎ:¦œí’! *Xüƒç{eôåÌ„Í;l=#rÎ)'5P`,2İó(hôãI¨²#ÒØE4'rŸäĞ©ÖÃ¨' Q‹mß3M?ß\?dp_ùã&$Ñ@?éNíª –ó..m<4LÇc”¹µƒ?¨ø¶èI~;Ï^ÌáÖ>W/F„¦Sé¢ˆÊ‚»k`Ã)Q‡ğ Õ“oõ»k4ºğıé€Ó‰§PïpÛtéÄ¡ì–âøv”ÑkdÈ o+Ü™{)åpÌñ'Ÿ•åş„–›Ç(ı´´ûØe!d´*jxKşÓÇ4M2~v‘0Ã#¡”›)|¯¢DRÛãìµ‘Éøó¨[nÏ¦“Cs>OÇ–
.Û7yû²A–®v[;×B””é‡±9¸ ×píó­ï‹™=kéÈÃ€YgÍŒÊ0£º±Ï´¿tLOÕÙ3Cÿ"I|Ÿ¾ÿrFˆëá>aG/*¬ÈËVºIu54bëKr3™œÀ÷šù¿»€ËM¸(ÂrjištÈB¸tÕ¯@?Å„í;hë;ñcQ×ït)_‡]~ëóó]_m†omXåuû‡¹r•ç3´~­IÒA	áÈi8àmÇK7é±u…wf#ÂÓ6¶âì6Æ“Ædßûb¶¼ÛÜúu±îãñ6LIË!nÅbÚÚ¥±‹0l
cÎ–9ªx“¤ã¨«w[(âúºj \Tô$©×n9„²b *¹<ˆª†¸‰'C¸Mñ9];¿ÛÔ/€@É<°+£¬Lå3¦NØĞ';ÒXµ¿ˆİ€œ©UÅF¥s¥¨Ó×æåÈnƒ Ó¡ùÜÈ™nóâÅÒ­¿£ı06›oÔªŞ(0zL æ³C’]¥9mkû Ñp•
ãé_Dl…ÙG›Lˆâûš0Øİıç¡ö­¥hª<v^Îz—‡ÅQöĞÇ¨Ÿãe‘î}néFOIè"nÊæ‹xõ©ÈZ¹Ğ7`éÎMVô-ÁpHô©tá,- ÄĞ?İJñh/ÔŒhRÅØ*B:/­¦Á‡\°ê6¾4š—]_ƒ÷İ•Ïwöã0_µÄ›1S©y{OÏ%*Tz#TßüÄU?†ŞE$ÁÖü¿ÿ&*/ØİSùK§ÆºA;%‡ä¹E÷ ıúKÍ[m¶•eŒ¤Ÿ&NMê	ŸfúN>dŒ­!G”óÁÈÃ<î’·å¥ÑB´G#e0(qÙô|ÍÀT*m]\,ÚË¡-{è¢/F{º–˜¢×’ëˆë´€ãÙq•r¤+2¡4¨¥GÿÍiÊwÄ`äĞÆ±.*âJ[ò¼êwMÒOííˆ3™.ÈñJe5«Ó‰CÅÙ…ßaÖkÉA:•Tawn0ã”M
Û`²+÷vÍù6˜2Ç8Nãªæ…‚G¦…~~!Â­Áú¸èçz&ıçT"·GÏrÔRè˜.5šÄsÂÚ”Š¤¨×é¸*ª†•À¿‚eğûĞúï*F-Å·<E Ò¥À“à¼ÖMÉ~sñ|câ«ğÛˆã/w T½ò(NÕËqLmI×´ædNòZÑ
^È J9§á p¥»O0g„X®hµˆ¹ì‘§@íÎŞ÷×ã&æ¸üAÈTZ7É}ãë êKÏİtÔàQF¾âáØİÎRÍiãòÿt­áÖ÷rLóÁÂÕfB6@~e¼œ=“Ub¯P}~'½ÏŞø¯}¶‘5§o9ëcêzÜ)“êÔyH°!Ó/kÂâÂ[ï’¬ŞÈsÅ·@6÷‘ÈFRëÖ²TáküRÕRÛ	éµq‹.”OÇjÊü¼j“$vKóBaîtæµ¢3_šn»; „‘èFá"¼)Ë gŞcNGLe‹×Ry9"è<€©ÔCc;ví‚dx´Èlß\2îéôŸïØ3K­Ñò9Q7ĞTø ÍiŠĞ¢~Vi}¤ nĞâ~GèË šICƒÑSûJ*»ï»Ÿs¥³éF/mÄOÚ«UÅd*Çá×Í^jró.NGÚŠøkÈP2İKvOjÂƒY†e(kG8ıyÄ´+«µ„a9y,qõÂ”‘BÀŞ”‰v¦’œ¯óÅãkZÍ¿H˜HoĞ>J¿xØÿ °ïÖ)í£ˆPáë%SäÜ=è*v{Iè‘[¾–!Ò¶h/-™S,ùu0çÉ'™È@$£›7–·Ÿï1 ¨¶ĞÆ5´şkšşåb^ß‰f99•UÃ'(®ÖØ™Ä+ñ#WD7P.£R=g¼ãT=¥œ¨¯8:İ°¿×°s¦’¹:8¥`0'É‹ôÿqÎ$Xa±rs¦§RáOªŞ#Ïn\f‹§_ˆ¡©›*L=>Å©eOåápKÀ¦¾:³ÍŠ©=\ÉÃ¬´ú¢¹3–IÿôQ¸›¡kŞ‚91í‘EP4L6mìl'8v…ëGööfúXÕÏÇ 9©¥íÃ‚Pv–‚©ÎüÖhW¢o5c³Ş÷n¹åFc €ö¿$¯2³ª“b0Å¶_ôôüÜ1I	ŞXü"ªzóa" ITÕšø5Ğ›´=	Hˆèİ>`’7T­j_ë;BévÁ·ÏÓ3hMÅGE•®º]%îøc^D]€¿‹©2X´‰ŞÇÊ"–àí¾wñê†ß Q,›-ûW®R=O£«Yà}HÁÃWÿåİn‰C ğ¸£Í?½ã”‘ß“1€8¢>ş?M¿Tõr5w³    N£_‰å…“ æÆ€ôOC±Ägû    YZ