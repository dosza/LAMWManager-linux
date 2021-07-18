#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2075171539"
MD5="8c852099a70708348ca17c521b51f7ac"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22788"
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
	echo Date of packaging: Sun Jul 18 02:42:18 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿXÂ] ¼}•À1Dd]‡Á›PætİFĞ¯RQÚz¶éÂÚ‘ò©£_Ö×Şğêò€rG<O¿zº¹‰iØP¼Z©ÎÙâò‘üwı§¨/›=Ë;c‰–÷ÅJa­ªêæ<5’^:ÿn÷\ôËP‘ ÊK—1Úu¼|ü¶s	'„õÔ±*ìÁ
9­{œ3FWÔ¸ˆ3¾Şvè¸M2ÊÁ/i°ÊãªGŞÓ³·xÂÃ1š¤Nò3Âœ÷¸ĞPgŞù®5”õnŒúF©³è"›ËìlÿÏyñÓ°ìs–?i‹¶<ãUCúÕÚ4vYòîúB¨=Ø½ıí <c?•õæÑ6îñœëßã²øç ù©	I#´·L^Æ€ò”@¯-’KÖÕ€ß“D{ùØÓF$`ÒñÒö¦ªUĞšXSö˜D7oøTsš…†‡•Pr$wê¹âÄ´¯zÇ6I÷­õY+ĞRù04ç‚“!o)•0ìï`†u¹pŒáFSÄeQ0÷9vq\Ô
Üj‚<`ììîßøRÉgœ;ğû8;wèÄ®îÕ‡\Ü³óIL.¸\KùvÆ yQ ÅÒQ%S²É78c‡iÿ¸»$Úwè¬L\]tõjájÄk¢×gÂûÆ±T?÷Ö¡LÖšÄÀÈıÒK.÷Ÿ7ü=OKÇU<õ7!­J\ä×Ş}Ó|DÇÕTÃîG…~•«¤Zóüœ0ˆ¥´Ş ²~ÿ9†<'°jHæf÷O#Ä¬/Àbè´ÛŸ²ªLYª–¹=ÁõÊ¸
ep”îp„u“j…ÄŸ"#Ü!ECÆ?F=ò ¶'—x•¢+BWsĞ¿¢x¤Úî0ÃnKPø×]\õH	w<wapúMY•,ŒSG¶lâ¡É±ÿHà7™ÂM7u±á†W6°aÈ$0iÃ»?€¯êô h¾u_ d{¼a€-=šå¤bû +®d«…ã%IÅAHŠ–VÓ¹ •ATX¹p·r")"ë+ª]=Ä£´Ñ¯ŸJÈpJ Æ±>Ó™Ïdfãu|]ÑJf#¿†ÃRSÈÉƒÏE†˜¯=ßøÜoK€9ò¸•1$‡<%ÆğXÙ£R ø]Ÿ¢(Sš!º\o»Y+ä1’J¶©—çÕíÊ7‡È÷ÕH­›Şm+Æ|»êÍı<ú¥Ø’}˜¢*/äùÁŸˆĞ²ÅãA4åÛÜ`Kˆ_Ä´+}\Â3N.m‰Ú ÃÜŸXßo«_	>ø¾wK~ºÓ¹¡v¿A§DĞlW'Î§-/´š.gg0HYoˆ”®ºÊ+T“ÔôÌøSÜEÊGÈOú¸ûe®dîâ½^›ÜMn™yS–~Ï„V¶N‚íLj8åf¼”­’ªÛ·G‰İ(˜fGUä¶p-N-:¿Ğ¨Û/±»¯TI U2Ï,¹äÈ˜fOa
	ËûO¤”Hå~ÂUåáVÁ‚ëFFé’=7¸Ì'©£ØÌdå½ç‚Qt«˜OeÕK(â”"nWºİ™ú(|pély…Í¸ÿƒ8¬c%S§R}¯1¢±¡öíòÊ-aõá´IË Õ}	ÂCòàru6‹,“
OPBÉ.å¯öM4ğÊaF³ª<ÔÕzç«È`héà0Ÿ¤KodUwÍêHĞd2\Z±ÛNªg¬Ú¨è{œÄºik˜~5'G¨¬p8Núª=AOÂ}†8E\ùÏ3ëWt}©T I¬§æ­Øõ`»IÁ	´w³JQ€&câm8û½1Î=¼›Áe”I3GµğEš1u‹.nÖí—ˆ×Ôr37ø¬‹/½?!ıØVÈFÔ@¿¦L+mp9Ë;aÌì±[É[t>'_Cøä×µ¾–êŸ½^„|¸Ã¢yÎ•õ8ŒùO–œÑ¯ĞCY}Š1Èu7 9n²5
Dœ>üq1iËòÆ‡s2ŸÕç»„‘/2úõ’Y”®jİŞ7Ú‚c7E|	İÿ²Ye—÷•<w,YëB.OÅdàû0}1ò«5öÓáÙéH‘}{óBaûI#©5—·Š¦OY>vÊ7‹<ïØ«ÔJ­æa™9ã’ÂM
“ü<§ˆ‘s+[-Ã‡túÅ¿*¯¾ÔãL‹S ¯ÉÏªÎû&£?w¾_º2Aç£ò¼Lzqc{µ™ÿ§¨b®FIËáªdFÙúnzf´ÙÂ'ìÉ’«zFùÄ°¾RÀnä3[©™ã1&V€q³9¡,×$gJ8Oî÷Z¬*ì&Éá ş!MôC4o²¼÷rãQ4(L§²»JaórúEw×ÚódmÌ·Ô)‚Zzt»²
~“`¤³›’YÛ“¦@hİ+z‚àégé_0€eÛûmÒÅ\¯¾¯˜×ğEâ›ùàúeg	»…÷†l6k0şKp. µè”µàj³$ãl5”^(İ
†5;%úC˜-M;IÒÉ¸1WøÌMqR®ß¬3]şì“¾İŞ»t|§ÀãÔf•|ŒÁAÏä8õL"¢a_D@œ{ş®}Èï”ÁºN$o{1èÆAÂØŸTîXi4ü^<Z˜DİôbÏÖS3A0S¼è$‰[>gHcí¤s9­ºe=bC7{£„¯\ä*ûJ-´‰|› gq<ÏSŸ,Şàlõ*?FÎüì—²c•z:“9ÙqF…²¾¯¢—È~ñ=œj©Œ³é$Aúº¶Cqç~ºIO0İ}÷¥‡xqf’ô)zˆŠı/ês2µ
§vüW^yQö}ˆĞDarù±4îåüÿXª»0€ÕY0›Ù\ğ£6‘›Wÿ‚àºßrÔ‘”1‰Q'8tÕ´2ÁºËãìNµõ> Ô##né|ÚíÅ){.ÁPëç¢|ºí¡é¿<G>¾ |ç tÙ/€ÑÒ­-ºéUù¡Şx¸$Gø”ˆ´·=äó—Lâ1‘è, «9ßD­¨Ô5lU.ËˆQ“)ôä0±&Q£…‰;Ôl¼Ö¸ôŒ S2§ä<›u“D?tzYò‰ƒ”ªtÁ¾hãzîİY¾Ò`ÓcÅP9|Îˆ³öØÉË€Z9´«‹Òp ½ X1%f?k¿>HÉÍF–@aâ
@îY°f˜bSøk#5®«9§³’eá?‘ÄÚÌ"79éy(üKÈ¹F¾–£ûÕöÓ}Xÿ®`<(ò=NáàfÓ§T“87-X5±ÍÕa@îNÁ]**uDV…Ÿt6ûZÓ0ÓÏ°5~LBÍ‹“	°Ûh 1wÀ×.ÒÇºbxIç¤yøVD¥®ÄÉê^wEûyQS[$$ÚêÍ”ªv´aŸæQ« )˜‘Ù¿ùvEÒõä’>7q–øQ›ßü¦¤}¿ŸŒ†Ğy2¢£o,H¿¬İù9¾SÀW¨P^#ÖÑQzßÄ
ô• çØÚ¯˜:“¢UµÁãô		é`BÕwJöÉÏ«­ÁSı;©ÅÎiuÓ'çDráÔX½ÜÙ{ÎhÉ\ òszVÕø^ëYGÿƒ£ƒ$Ú&>|DÃN!¿øH1åÅªéæ[[ÀÏÀRdâ>\¬!^dDcÃèëØµM¦qÁwÙüldŒ¼Y8LßÚ_CÀb>fK“Œ8ÒøÄ¤§%\ü™ÍtÇÅ—²õp¡_MË`¥ØÿuŞïü—FÃf
ykçl±½õ@~›)‹éší	w¨Ş ójJ…O#¤z$¨á´Ax2@
c<«5¹%RFNS-
¼6ı”YÀQººÎ)ÀÛş¿˜ØíŸµez^˜zmC÷z»´Å;äûW4Ì]VÊßÿ$”[<b€¹
,éÚö°Ú»^T WzMZ+à`½öÂ¤<:%z²‹ûôàjíMGq±³—òÉÆJÊ‡Yçì 9Ì¢[Ÿ:_y î–şäÍ\Yö[r;Q¦TDDnìx*©l@ÖäÂMÔó€A€Z°œ¿?o+JÈ„7—ŞÙI’AÓ¤Ğ½/·òÓ‚÷„®ßQÿôÖùï´2œo·C“Ëëi3(ÉÙ
ı›6ì›&†>™òÀ™[)×Ğ&BÙ’_6Y¢$™Åß6—Šéa¯7útƒ$×;|ÆµÆ²=Òp•½„P™UU„ş¢eDÊ³'±ø)ĞsÇµ)ë@İçøF>‹J‡?¦’Ñ°ÊwÁÚøîSS#§p#4×d  Â’P9®um…±¹	ŠêUğ„êhó¾ì7ø{{DJ/;éT=ÁwŞi}Ú³XäUğ/ìfxTEÙXÍı%İºJ’:£Škyàp =  º2Õ¬ª îİûù¯)÷$-]gÀG*]Gã'´Õ˜ênôø±3ÖÚj–Û¢/\ªZõÖ<¶lüÖÿ)!´wzšg4×ƒÁ{<n@¸¼%O¢ä*m ïNj+wiI /°˜7ÉC:ua‡Xdƒ×WÔÈôLíÎWó8ˆÆÃ8ˆ¯- 5=ÕZ·^ü¾&é:ßäP¥Ñ†>¢@“Ğ11/!ª Í¢äàõTLò‹Jœ `*ÚÕCØ–Y3ÙÆÄKz¸R’1åOª0²z¥Vaı­ö=û?ejÚmT?İN,ñ""¨2z³LØb‹oîKyçl_o+-f•|7µåÄEÇß.Í¢lØVî³Üøo”S[
»÷²Òåå¶²üğ.HAšÆ$K3kÊk* &uÀÉ›V^Qæö#ì=˜y¡ı+–×İH$mKm6É_PX°'£CÏgä»—Ì6š’ú[+§°¢9M Ô  @oF³gJÚêÀÂ! Ø%Û]#>‡xêÔv´89îA’ŞÕ\/#û¦´šMYX,§
å6}èÂ]¬À3”§¾öÙCd9hªˆB¥RÍğEg'”£V6MíV°™Ì-u=z¡‰ß`xL½Uƒ¡!ÍM‘jÕïB•šnX –ªIXc¬ÙÉÍ#¬‘£ìvyGÇV=Eì*Êr×´,ıRÁlDG.Ú>•$» ¶ Á¶Ãÿò^r;FC<ÚXQÄ\Şö¬nG­­ü¬¦•²Ñ ¼Ld%;e÷y%ÀÄtÎØvXBy12 —ê=Ç€Ê€¡Æ9|Ù¼IZRF!Ë—Ë”Ôs¬Õë#PË8eòrÛÈ›µÑF]›“_TØm1×ó-•tå­oV-Nå‹(¾ÍdñÌ$ø>Ätäå0‘ÓáfÙù7¹(ÿ¼Í˜µRÉİâí_‡‰"&"_Hù×›§õÚe•ì!XAZ^¬f'›ÕJÍE4LÈPøØ0ûÁ¸¼ï¥NLÜj&ÂIT‹‚Ãòøı_% Çé+&÷@\~Ï‡åV;­®ô’L]Âš8C>°—dp"¶ëÇP³<YÒœfî†\l  şNsÀaD)0—	 ?½@êª:¦¢_3Ğ&ˆÙƒá©ˆ¢ØJz CŠÔàLü
œŒrÖ”gáşØ×fÃ¨¨±»P!şZüÖšõú\níP×k"fåÈöd‘9kóVçËUpÇŞ†…xqbOQ5éf>qó¸§8ã	ÔN/*yÛZâ&™?s•î«ş&7Y3ª×VÚ—†=€œ=„êç:4àTåYe•qöuû]B]1F°ê…l.œıA:JÎOÙ=…Œ2) @õ¯¢´³óæÕÛş„n‹â Ñ´®ËUaY‹³¨A‚Rlw/¡;'F‘ú³'¥ZÜK¾¿Ê†]Šb#æ°|æÉ3³röú÷ÜƒiÖ”ğUÓãmR5ğÕ„íãªz—ôªµæéE±€>©»€ƒ58¦P[±Ãx”®d’:Â*å†ü”Š:¿zBİönttøòb$Ù¿ÔîZcBv:!şXÜDºã1³Àu<Àp§E¶8•näê 6î)ĞHc…-.Ú&G¤B®gäªWşn˜ê<J2;¦VV,ôôá—çQj«PÃ=we÷’ñ{t€÷ápWäÆÌkÕ(İ,kR¬` €C¿¤Í£¼¬şÔ²©•QğõÎQ048Œ2´=åw”K‹¨ÄŸ]Ò…Tk6‡\ÉpTß9<ipeë4—°ï$¥èÒİ`CL İ9x+Œ»¿ÊcĞ9XÁ nÖŠŒÛH¹->éyçxT°è{áÏäo[5&JI«Hh>/»ƒH¸ú/7½Âuj÷íôÆË,&e¼Şˆl	%ÂÔîæ„C%á±5yØq –ƒD‘WEhëi*ÎÎ8›Ó$}×Ø¥t_C§f¹_#—êøpëÀù-r¢]"T®*ªYjÄjW‘RìÔø»îV,ƒ Ã{Û.~DÑyƒLûˆçšô{$7“¯¿ÜÕN¦µ¢ˆuï2Ü ¯œ«ÏíÓY<g;­=ª¹¢Æ"èóhOnR‡Å`–ŸbÙİy=¯ÜôÓˆ^fœñ¬pc*ûä§ÃÙsÒ ,+~Ù1¾É6»#‹AŸgÓüÑH¶ØÒ4	Ç4muŞûÑŒÒ¦?Ëi€Ÿ,Ò£èKì
–NÇ˜)„’\ó¢éóm9Xíşƒ/-²u%Mı—tæÛ¸:tA¿qèØ“,p’_†J½³†€»!.ÇÛy}¹ˆœVqœ{â°eìU»A=ÿ€EÂïÚ·{,Øu€9æ´vÍBÉø¿Í?¿Nøƒ>8<ß5G E¼¡<*»v­Ÿtİ¢lf§íRİ¬&M%.)\PæK1ËCis}±êa#½ÃVuJ2ÀÆ+H1Îø…·¢0è" rƒø-gÚ3)ï)n7êV¡¡]ÈÓ×Ã¦JÊæ·ÍİİWÕKF††+É
«·ŒŒÚ9^¹ı4»æ¢³7möw
ºn­p/«­Æ¬éM	@H¶ër%çW!*˜’HÃ©Ù%$[í¾/5(ë”dıÄ†.ò"•¨‹ÁhşSßüŒu	å½Æµ#§s \š&"uvy¤—ÊâŒìŞŒ½ˆc/“?vrx5´bi’ä,E2ºNˆ®ŠÛæœHÿ#OŞw»9Zèğ¤j/d(cjê5ÙW¯»üÔ˜0şÃ²¼Â$š+Ç#€ÿ¼PÙï17Äv„ÄÃÅÛS•‡?(MCšCHœ­‰nV0f»Á¶yÎÚjq=‡p‘G8[İ%Åí5ß÷E×H!Ãx
lfÍŠ]Z{ºñæÑ'ŠUÈ
ÿã CV5½ú—ƒµBˆ01°wNäÆıhÉû$ğŸî6|½ûáSJ’øüñ™äÉÔŞå‹üoHKCUØËÃE ½p+Î•‚jÏíxö«"K¬~–fXæh”mé‹;Â+ß(¼ØÌyØ á¾jh’s„Ø'S’Û,¾!èIVÑó]æ¤[ˆêÔòï,wŸ¸æY‘ò8"Íêåç
5ûÅúæ:ğÕ§ÌøDÜx	YÁğ\QÃC`xîE†5ÖRÄ Ó©.U±=?„±YÊu²Şí
EÀÉTŒ´)Üğf:aïà@OÜ~öz™C„l'œ$?(Éê¦ W»XÜ§% ù'†™ì,ç¬önÜ&=`]F–s†$Ğ/¿ş<·qî^‹ÓN„Sp¡Øq¹ú„*ÅäÕEiëYyPRÌÔÑÁtúÀ0yy¸è¡)”Gè.…âaÁÿrt6ƒ1í2!Ó%L‚ïì&¡ıEUi‹aÈØEÛ¨;õÑ#…OçºÇ½ğz‘¼;Y–<Ôî.SÆ†cåj
’mH‹¡´öEqVÀÒ˜®/Œ:mÎµû­+´÷ë‰<øí\r"IÊÙgkÔ6Ø©&Rè¯BúØ¡¢ŠğD1‚ìb>±Zñm‘ëŠ¢ouâ.šÍfÔvÃÀ"æl˜¯ˆÊtH¥(WÚ<0:£¬lmñsO—PŞ ®¦Ãpİ(Y.Ğ*YÌn’êäXBhdDÛcõãÕJ…‘¥é‚×¢°M:í†¶ppùİÙ5z„®‹ç¤×¶…T4¾aÒ:Ès\ØáËñâƒ¨¤¹¹`‰+ÿÄ§N€Z%)åYJ3Öô¸Xª$”_ş{xCgIF­z	ºËzŞJŞmjë)ÅD½6+D¼5xŸE§™WWù~ äŸO\Ú›&7s»"‰|àA¤ Å¼¬L˜{şO0×«­W%‚ƒe¸ˆö¡K>)£Úlc–T3Ü-¡ƒb5	xMà0G89Ğôi2é‘û‹¾å1iˆ¢'CAj®B×üïD©â¶/sÄÎrsí0|­qãÅi#şº¦¹½º(…àöE¹ÖÂÅ/³«3ÇûŸê³ì3|rq;Ê?dqÄ1¦ò‰î=ï‹…Có/ÛxVi—?u¯joé‘:Ó—èRôGÎäêœ7¦çûæh~ÕÅ+!ˆs šS>éc°ßç|Çßå`Ùº+Á"U3”Ãd£¾t™ZtÊvlğ½ì,p.ïÚ•.Ù%¸5—Ñv”›ØÉ—uã"Ò*6ûwúƒíwİçŠë‚í“¡5xÜG‘€ıX˜²Ú—)9Ùº%£ÂşKóì`û `}+'€V:gaè¬Ü48$Ä~kI ­7K*‚š›hÁîºù&Õ¨Ñ"ìâ—š1ÃçXˆİ-ˆèîgìÑæ÷6¢µÈÏB¢VF\$FBŸ!§-…âˆNØVQ&ê"Ú’D˜‡İBºÍÛù‰Ç3`äÀ˜t<ÎÈ<Ï²b°#(èo`,õcN8íK‡Æz<ï–xõÚ}ÅÙÒwj|ÿ3^©fÏGXÅúœrÙ‘3"b:‡Ö….³yàâÖê®½>ŞÍÒ×}E=/xq_µFA?EóE`.'€ºÖËGûº¸ïúäá6ww4‘½™COıß(`îáø8Zªi]û©)ZşÅËÿ¤ÉO=,;ãaÇô³të
pÕ%9EvZ¬ö¥"™ÈB-¹á’Pjc5N€PºÎáµ§¦^Ö”hİ=Z ”º@Å^iöf7ŠÙõUÛ¬Ç	löÇ™ìïÕñb¤šïámŒ7(dÆå”¡Pû>ÊÇô¬„^¥,Vš¥Dc#ÿ4H®–!;…$’Ú¶åŞJôÒb
tBïşûn_'@Tã*uDˆòP<2_ûŒù„ı¤õ.aÉ–Ãè‚îñå¥=8ÀªUgÏgÍ÷àÇU5ç<_ W‡2Ñ¼ŸÉÇd0x¹æ¹>1æˆo›>öÓÆµ‘·ûeKf|*ÕVêWü¼ß“ª®NmßÒ7=Ùó 	LY-‰L4Ã}óû¦ü&¯bÃÎŒû¼á]˜ò.àxZşÊ M—xWå …)JÌ‚äŞ80/æĞï2X^c¦´”åú`‡F¼È:EJí
Ïl[ÁøÕÔ*áN eÅpÚÎcàw«c¡¢9¹ùÊ
¼×ïJÑEĞ¢”ƒ:…ü kVÍº£gåµ&¤OòJ µ:Åq:q#šÂÖN'[%s^ıqR5sÄ½vqÈÄíÜÕoÇ‡ct±1q××!'`Ö]û4¹÷Îc.øB=çÿUXdÜâl¡S"‡ÎÍLf,EÁÊÄ£ê“h}5Áß*£"ACÅ¤‚ã#×EZ4ß‰ıN~D’ô{À©GIƒy²ÕP<GÔz
l'³ïÖ á¥ëW¹7%vbş‡bC²¬Ú^¯Ú–€³¬ºsì‹Ë>“VbPåÔ÷yÙ)„ØBëI>Cvl°	‰mnpğUâ•0'fše[ò¶8	¢4Ò>‚eG<wæN±iJ"4	¬Gi¢MÚ;&İú“_ìóÀÑÿº'á¨)¼³è¸PCm-D#ÒMR.ş¼ÚC)Gû`”*µjxøá¢áÆh±L¹¡ä®æ,ÍS('Šâ›İl(=ãÿç`˜Oƒ8Vö-2L±¯9€Å³¹õò„&°µäsoîP¥…ˆ‡)ë…¦"‰fïåâà5ÿ.TOË ğ‡9´%>§åÃnÑæÅD³”NäĞNrdúÔ”!<GÚ(×‹Ính°¿İ‹ÌN£‹<VQLÇ–qõ¬†Úg39’vÑëÃ,EÀ#‡»±5Ø¢ù$ˆ\®µ%J×€wïÎœQ×$ätmOÇñ~Ø?ûÍ1ë”B<x‘V‹dY¬€ìèoõ—¡”™ Ïo+¶¸wòAnÈ6ÔæÖs!yF8Hãöò<mÃ^xbPH±(%|â.d8iŒßÀ@âÒ’Ã¬ÂnmlÔërP!ı¦+zOc&q±h(Ä¤šçªò…–MÕŠ³…ˆ§X‰MøøSÈc¿:]œî/nNŞwû«Úvÿî™DÖwiíşİ®O6ÌR¢B7•ÒVU®ñd‰Ø¡ÏoæÄ¬íÍ¿ïQbøºu‹õÅb:È0ÂL!{ÍÉ]ˆ«ñQAŒf­ÛLñ¤*Ó°UäÁN¦Q£á¼‚Q…ØUüÄ$^=ë¾%Í4³—ÑÏ…®Ÿ2§«¿/Áà` _Ùò9Pa<ÚeØ@0¨ulQeN*®Hè4†&¦4Óíæº<Á¸Ã™.Åx}Ö¦/±Ä|äo<TBUì*ãTò34^ws¶qÃ2p”“úĞÛ§â¸Ş5!¾ÏºšĞŠÜÖAşÏ-Ôª†MxÊlA+âœæm8(`‹J”€4‹ÙR¥ğïâ,¿@£Õ5—õ'¢
&hóíÈ§T@gO·€_¼ğŠÚ’+ˆ‘ŞÅÇğÂş-Å|‹<œÙ‰¼Â1Ì•àN*-ñ DBÅ-š[½Ş­ÌĞÑñ²C˜°O¾q•µ^šs7ó
ÊSüëî”3èqÓbº¨ñ`aÔEú™¬óXıhÇL6ñDCòĞ“È ,vjVgáG™@HÔäÆç;…íÆç¡\Ë§šø1‘É_aL7‡.èb1ÍÈBåï'7Xè€*ª8ÆeF³â3bvHÛ»\šBà%cIÁÉ¸š)PP©yëøæúï³¿é¾FFjØ¨öú¢¢7êEân-Œ	e€"P“ZıÌ',/o='“~7ù[:½H´€ıŠ™vº*æ½†[‘3†Ù’¦!W81Ê64‚Á¤ùtÎ]†JáEdÏ7Òf°•Ğâ}Uäµ; ÔÓÔ©®4ë%uy"ŸÚ^ş~Œ¾Q”ïL7>¯ñsô¸×šú•'½ªß¤©™^ÏÇìnÄÊa_?îlAƒ&?Â,‘-µ$‰Q`1l(*¾/]èôTÊ+ÌÁYÌBvb
ÅWÅe{âÒôj§û™n»¤¯éØr@Æ«Ó6Š4§Xé»?Ô%~ÈÈº°Ñ8óU„ç;R6tÙßJA`õÁ½šà± w‰R€k´CüiFôÕÀX ÇêíG´âUÚ¬‡B·«¿H`1×bçÑ#‚ÓRg8?’ÿi×=4<CI—ò?‹Â'¶}ì,Ó÷vu§3b“H/¿èvgéI³)õ
Fî¼%…7ºY¥Í¡ÓuYê1ÛÃ­$“Nê”ä¼‰”rÍ“*„^rC^a#TlQ¡Ö]%†á5§E|)m6yñã%¶Ğ\ˆ6®”ŸëøĞıaØı¬ªB(¹(Ö/†Oc'•)ú¸q8ñOã˜<ÅÉôº÷HsS7,ç¸f¤î¶•Æ7ó5
9™~yº$ÿß­
êà¿Ä‘NÍƒÚª¤4hˆüá%úbï+ŞäV,¹Ø¹‚€AoĞ”á¢6}æÚ©±ã˜–aı=Âë©:Hµ}°]‰~Èc_îS©îƒ¶Ğ¯´Şã€—.z/êÖıÓ«½4öòñŞë‘“Ç
¶ò£Äÿi¢\¡æ?½‹kæ‡:TT± éHÚs$ôí8T|ç×¶V›T#¿?"OÅGİŒhÀ/6µyÍmE?d‚å[¿´¦÷n<IäÈÙà§_`Co˜èLoûïfãpÏá
şSôF<tìÆòaZÍd,·×(©ÛŞÛdœ/HË[3ùŒµÉ?aBõÛ’³CÆ¾øã‡’§ÙTç©Á®s°z·)Ôi ÉIœ³Y¬õâ‡ÛT [¥Ş²åÔ8uÂGæ7¯à‡æ‡xízñ—*î“;

¯‰×¥¢ƒ°°±p¿â3tÛË§Ç"VBÎ=G£/ Ÿ=w”?‘ü§ƒôì¿¹î(í^Vep>î¢ªAY+{bÇr!ó¤o›Ë±ı„ü—‡£Óí¡™yì\Õ³ıµDldÌ»‰´&Õ¶ZìDÈÄš}) ëº5Ú¼
İzùì{R×tñ#b*£vò4å;

€umEY¢åişæf5t¶Ö§ÿlmÜB‹Ä—@üô©ş‰ñ¡¯QÆÆš§×§İ¶0T/ôœo¥FLí¥4œáî°¼]Oh¿&=‹mi7Ï¡7öâ(ƒ°¼°Óz¸û	Íš8‡ß‡a¾0šq2B¢tW½ •0½óæ\LÙ“^O†yZÑ”dBhw&YvŞ<"“6°w«Mbec²+ò3]7ø^P&WVßJaQ³bš–èãŠÔªdI{]äaäØ0·Hm)™¼QŞrì”zÜË'‘@LA3hc|k0™Õ¤‡ôO°Ë›î²©J!.C
3¹çÇû¬›7Ä>×“z6À<¯‚ªÙP†1İé"+&1V hQ¤ùAªc ïß²qÕîÌRò¸ àóÈŸÉÌ”îüóòßz!IñE~OmÜçAƒ„À¥.ƒË~-Ò·±7Ûµª¡#˜	<³‰r9ú„òWÅ_çèÎà©Cğ;¬òƒ>œc†‚É«2®#£ôçÇÒD$·e`†}3±0›/¥ïE“cı8²Ø¦Dgl;å§	g'8:)“MÓ~CØF²º£™©åm	áô\€P/jLî¡úC€°G³H¦OĞaeÃ¼ÂªH–ë;ãÁoşšs­”W~1mÄê§"Ğ´œ¡wV8¿°†­(VØ‹ñT,«Vºi•74ï —oüÙö@|e~›ÂƒúSE®‚s~ml á0(šÜ­†1Ó¸@©=¢µèáö?Q=´½ï7¾D\‡ (‰6TîÚ7]´å«;äœñØ÷ˆµ¦Ëò,1ùã%©ËuD4F—¡‘ğP¶šux¦÷9ã’g¼
f•§÷#E¬‡S¹˜ânmË@É"=´ı9´A~ÄíX¿VítÏ+ımd‹¡O{»SyÑÎùWØ»±›ÌU}ïÊAÒíyo¡!+ë³˜r,
Á„²º’g•CÏYÖóf-íªCÃriSÿ'5&0 …ŒÛ¢TªÕ‘ÔÔ/QNöaƒQá•İ+¶™K¯¾gH;µ À-†5Ë¦‰°ıêCÀL»b»ÆEËóóş«±S„5äÙ6ŠîYFª­Ã°%m¯¬{‘±ö/ŠtX9¾Z]€Í"Ğ·›?ß´§ßÜï2d?raús8Lù{,Â¨@ñ])['ä
ì ¯ì`~5GT)‚Àå´ZJr-¹&Õ5zùşz,>Ã1b3ÃªŸÇ¨R”Ü±ç)t2ıØ­ ÅÛò‹¢¦5×Ë!kØ¼âciÛqnK11í«·öãØíÇ#ÙzÎX=4Çg½Ò,%÷ßt8"×…&ó,Ûƒaz{'*AsÎ6h/ Å”¹éÉ9H IÁ7`„Â¿¥}S MZŞô¥•Âë’VÁG¤Wäú»ŠÂ!ñèÈ–-ö‰¥…‰ Ùş0ìŒë®?Ïnª†¶÷H›_AšË1!ğ{vAøØ™¡|Ã­Š"Øh¤{$|:Uïè4}”XñóÙ±,ø,ÖZãpzSbÈ:Œ&``[´ÇcÛ²“é¾œßëó;üEPßúÀ]Ã>;ŸaÆúØ^àˆ+Š­ÁüA¯e}“ BÍ¸gİî®ÛUr•±rŒª5‡8q—ÉZ´æ‹ŒÒTE
@Îÿy6e;^Z.PÙÄ/ª˜cªĞÅ¢€¾ñV‰R“Õ×>^1„ö!äßíÚµ~¾šüd<<Ïæ‚u+›ŞÑeB±ĞˆsäC-P¥Ì±ÄÆ'Æ)Ï?vãöeS`dX´á½&ØuøûW¾ÖƒwRvüÎ†9£5²gŸ¼3šAòdCæä’|(ü"™ê3ÿlĞÕÎ…½>•ÁÔ£>YM 9wİJĞñRÆÛRw¤r?ºŒÌ³úa·pÕ¹ER1«½™ïÎõ	¯Aıh4Ú?–U¨…]LºJz%£Xéo·A	ËĞrğBİÃ.x6’$¡72yR´×©½M¿Ğ¡JÎ –|†K1ÃÁ äşóÚ±ĞsÔ¬Öìš…U,!‰œágI	ç²ÄÕrq5±ÎÕOG`ÿ…@?°PÖDs„´ñÚ¬Ø2)´[Á’^à}’ç–@ÔÙ(ó—#ÿjT1)”"1¶ Lú.C¼m­0.Âïß‰êKj 7Xë™şs–¸‹÷[‡ø§íæÂªzÉ«&Ç	¤0jÈnm¨\Sü¼¼÷D#ßYwÂ¤<7bàµM|¡{l^ãËÚ³µ} ) Åxí³Økœ@LÓ„5¯”©“ˆX‰ÄwŸÆ®>ÌŠŞb‰§¡İ~fİ<_HÖºm`—Ï”W‡»Ò}î¿UwFV¶¥¤&)İ:€/-cLŞàô>yvo‡Ì«†îÚ7ôù7¹u¼ƒäÇ4_õ_şU6É’®vûfPõ¾ÈíŒäE(•”Ü|»Wád#¿×²û­~Z‡Ö€l
iğ¸k¡tyã‡ÿ>/4õØú`V3ì—¤Ê%gcAÏD´)uÎOKÆEaÖÒ}6SˆğÊúÚ)~f”…¤ÃUÎRp!]ë4/Á;;áÓkPp§3iQÍ0'N–ä”&yD>}‹“åfİªı‡.®VSáÍ(Ë{AÌˆ†Æ†Š ›óïa–æEt¡l}Ş¸ ©-[ûny:êT]wX-Z…3•+%&œ1×GMøš?hïSİ?@£Gå¢ÿI’àıS¢QÌƒ¨VAş'³{`ŸÃå Ü•şÃ«­*¶{'Œ«eE\—½7©â¥àÚØ©}ó r|cÒíóQÉNqyHÊ™†øšŞTº(Ï	>ÖnP¬&¥u-r#•£ô_]Z±”!l”ŞmŞö;é’Úa6œ“é‰µs¹$ÒëÇæÀÛ©igM²ÎK?ŒŞ—³š1ÙÓ«ãFk®éq"§²Üê§<•ENºd›íÚ›üù6¦r Ùaœ‚ZN^½­ÀÑ­ŸÉçk²(3qEÆa(dìƒ÷½JiDÏcª!ÿÚ<xcxIM8ëK|(Â÷çŸ¯7b{SUN]á2á€ÈØ‹š%d}Pw|>‡fÔ³Nùäé+ s/ïíÓ'ºÆæ-óLŒ	³ÖU¹…ËŸg¬X‰!e5¨”/Mƒœ­•{Œ²"î!µŠ1,T[OJ­M¤â8kV—
…×dĞ™Rr§]ÏY«½’)P4&s2ÖUŞ}ÈMè€Wğo±V¬Oƒ‰EİÍe³)E×§®~õ¨ÈÚáæK„½ÙomºêûÁß¸€UyI.îŠ…®Ï*Yp/Ğg))‰xjö~œÍîrA!Æ¢ÛXê´ãzä¼}[l¥³h»'ä'Ò]Ü'H4TåëJ	Ò(—¢=KJ¡äaM:FşØÏèÃ¨—KœfB\i6¹_Y %ÂÁ¿Ö/éÏeÇ_úLöÕ;Ì^Ğwr‘>÷ õÚ‘œªÕX™Â„0c+×æl\%Tœáòğli‚_s^êq-a¨Z• WB>¦Z¸ŠJ¡h}pf]'N@E'n]Öõ*eˆêœ‚ ·{˜]y‹å	¥iö,ƒ¡Ã!¸QCv{Ğ’ü 'i¢djU::˜› ‘ò÷;âa¨Í\†ª:(n§-g-ø\C±éç¤ˆ^]~ˆOiÈR+ò)î
êÄD=íÃ"î)š©„í\ĞRô…	Úİc¯c·Ç¼Åı±ÕM»°~Ø¸))\3Dıwò¬Ğ„’èEñû[½yŞ(Z(’]Û°¹D²ÂøÁ7õ	ãaõø‡µKì„0ğ»J¦"ò@ÜÌƒ&keÍOÔUè[5Â.C}'57~ŒÆKæ&Mûg2éSZûLå¢M˜ò±@R×¼ÜdhåöoEAÍ±³‰y áÁÃlÕët0.ÛÉ~L¾¿bMªu?jô¼mUèM¬ôì9Ø"#¸ÈŸ”òXŸ­$ö,Nú¹Ñ¾îÃWøD(OóLÇ\ù\Á¸íV ÊĞe”C›+7ßx.µ[>6ígô+ºGK@jİœ´Ó?_1M¥‡Bá•Ş}¨%©ÅÊwï§¢_÷³	¬CÖÔŠAkZ@wğñ·Áı4µŞüšrLRùZak	¡qPø×5d5ªûÜøu02…ı}@†<³nY-»@M/‰¿gÒêl—#)©À¨*±?±ËfåT¢'•Ñ «È×‘½¸&lpšù, äudÖQ¨OJìcK£ éØ²R×;1QX¶òÒ«z!1ø¹Xú˜ó¯dH]£ĞXÔD2 C©_¦Á˜ùNÙúÚ22ÂW7Œâ‡ë“¯’G.U$gA"AË‘©ìéĞueßÛ¹™àßÌ³‹õxÇ ¹²şşE Ûnª}×Ql‚ëÕï1mó‹‰Çåªñšêş„¡¢_7ÛªB^º_bVĞ
±;ƒŠÓæêjÀÅäd7­’íÛ“ÑX³x^Bƒ¦°^…MÉC
ÖXz©ÇÊ¼Ááîl~^¤*È[³ÄñH£®Ÿ—P\EüéÛ	Ú¢—¼Ïl b>a0fC/·›;rj¼ J[;w%Ô’Je#DÕúäÿWvZ4Ch!ıùµóœòÅò˜Ií=fJ9£ÆO‰¸V“º’»ÏÇe[ŸÊ ¾¢ªÂ SòûE‹Ê›¦İÙ¦Ï(H˜GZ7H4çœ·ì”—–Ï·n~âF£±ü	‡¾Ñ2ª™ŒÅvÒÆ
œ:¸<NX«àiõlnöğR3‰†ŒG‘
E×ANäôífÑï®Êõ\ªpXÖa%ën^…Çùq•½k³ÿ4ÒoóRÔÁ>5r‘Î	Ù¾
¯Qì"Ç¡Ç(%3j=¢ëM#Ğo×§€äÇ^ŒÇÔ:ä¿¥¤ku¼_”º!Î…ïÕ/Uè›Ü"kÆPš)äøúğ/Ó–ñ¼,øŠ‹å
‡1“õÛ ®I§ÒwaÛÉË9=4ÊãøıŸà²åÙÆ‘íà“Fã ø.S-·I²+±¡@¨îâß­®óDÙbC¿Dz´@L¼äÒâ¡cô4¯é˜ÍÊÔ³rË†—+òz©Y‘Sròª‡"ã>0y1à!-Šó«Y4ûtZñù œcœmÑ— ‘­RÀ´¤Ğ2ÑÑI„ÖÔcÉ7l=¿úñìL±™pE2qö÷4ËK`f(´ÁOjÌ	Ÿ¹åëÁë\wÉ;_ä’aLò¦“o=@Q!ËÈ³PÇút¤¾`—©-9w’~‹ï%kz¬°‘úuV½ÊS|Fp~|zä`É'AxQÈÑíòÔˆÜÕåùŒyÆ|&æéo˜Ò5£sî.ØÊÿ]OŸIÌOs#@ƒÏ-ëÅ É°'˜ÕÊèT“Ú«ØûËì){¶ÂÛaı½ç%n_¬¡Ç%(ĞÃT^FàŠVdñİšfsÅâk·4)±ıhv(û^¸ÊQö)éd£‹bxô°aAİ„êihš3×pÍ¨îE†èx±«nk7Mµ—“eÜ¹CÃğ¹“‘©hæ»ÎŞ¬}Ğ|¢”‚:±ƒ=¢sÿCs¾€¦BüÃÕÈF—F3eËM´A}Ï-­D#›ßEz¤]b¶ì»oK\¢Bÿ‚Öªİ}Ü
) ']ÿ?è@oXOöß‚>;ÙÊÊZ(×ÍenÚs?Ø][Wù&Õrp™‡ñŸ
œ¢2jOıÃ-³ùøDìĞz;˜1Ê­¤`ıCVm¤;ØMÎh¬6â£DJ†ÒïaŸut….k­¸BÎ£F”9+ $ˆµé?êºGüwİİÍ¾¥—,ÃEğ„83Â”WÖ7ĞaÒøvS
qºvã®ÕBY=d(mƒfS2®ŒŞŠy<:]`¿Àd[hk²Û„;W+½	Ê_¢'–ŠpIZ’>”5½±v2ü½ û³ü>CbFh“œ†˜ÎÅ¸NP¹Xm½«pevtÏuáVÌù¿pÖš³Û1]˜’zŠÌMj/A“Æ/~5çÿ;ôã‰œÖ|‚'Ÿ.æó4-;J(úåq~Ï•8Ûìöì½Ìˆ¿2˜ş\k†iØò{Ç1g,.ÍôÙMşŞÖÅr>tëUím¥šT„Z¿r>_yo?-Ô%·/d¯Û¤Ç¨¥¯UxG$g»ÔĞieÑ%ßÉ·Â3z %;Ñ‡° >&‹:R±`ˆÇùä{9?ç›iV«&7ºLÃ$ú‡ÛÂäIEÍ¼²¿<Ò yYÊşèµšÁ"â°NÜø\d«İ“‘i1ı{ãP]´ö¸§ÖØ¨¯¯_ÒÑã3­+m!€„<È0Î¯¡sqàıè;‰÷I•eq¥g1úõYĞN†˜´2¥AkçûyØ3?h@³Ò¾$œzí“¬­µÔø7½MG;cU¡åU¶ç–ãı‘ñi÷ü$­¿¼l"šÆ)d{·|(»q£İ
aºiÕıø‹elµ)
“×Q¥Xù4u¾¿9¢KLc
ÄæNõªêÒ§Ğ"4´úåş@È}KÇÂ¼Än™)Ê»é›#5v#¿SqO6F ˜y÷£Œ“~Ø‡Öù‡8¬.Ïğßs~k0èdÄª¢WîÆ{‘‹`Eqn	Ü*¹øĞ|²Î¥ÍÍ¡}fÊ¡—¹.íğÁï‚4KUÍénYõÛ1çoİšÁjì~
¨uv ›0š™1Ò£+\hÖ	‚G[€ã®d5•vıt¾bW–r'+f€»è4_#ÉiÆÂeé]‚7ŠĞ(Ÿ*ã+`²z¬ÂËøõ°	Âœ:¾d"5#t —Nı|LY
úNÇkömz%ZÓ¦4²t·Ø1#¯©"gOtX?åclª†–ùëñØl0Nµu„LÎdOÓ8LDE”ß{»ª,õ;‰®OpäÁ‘ÂSÓÈõæhğ=Á‹s|Dş“(t9=ÆátF0¢¢vÓ\(Ã¨O€ò\Ş6|QRÓV=oY!BdUæYÎ¨²M{™ö4mr<Šü‡ İ2=Ï	æC1¥FìœÃšÚ¯ÂAë­YÎÁˆ‰ËúmÿÄm"cûpˆ¡–ôæHÒ™¹¤›éÃ-ùwMc“şä‰Ìèé–Í¢)“ÙJ¹‘Ğ±ëè6ç‚)·÷„šI0Œ·^G|IQııw¾{wÂK’Bˆ U¥*ï¦VWÛ¡‘·•Æ”;ØsÉ¸}$‘j¤ç2ÎºÉlgl;Á}ZïšéBÎÅh‹;FÅ"„\¥F¯ÖË…!2ÂÇ_”>Á {¼§Õö¾úQİ:Rlu¡Òù-9ï/Í(÷ÈÕàû9Ô3ıæXp˜lÃ>r{OÇ)ša>+3ŞaÖd·‹jıdš§Õ]4ZS25°†Ì¬
´åd Ë§rfô]ÔdÙÉH2OÅ×Yÿèÿ 0	‘g£WÍŸ•±ª«>-),WŒ½‚°“a¤KîN.æt-ÕNQvŒƒ¹"=éq…<·¤Ò@€‹Ê#Š¶8sÒjĞ”€¯ u´–OŒH­=Y÷HÖ».'ŒşÔvGºÀÅÙ ™„””lÆC´ŒJ³ÑJNâQ«€$	ğôÏó÷¨¼8+Ÿ'áíÁ,BåRˆÑ5d(´‡Š÷‚T7Üİ(@ø‹]#Rø#²x›Sï{zêd’m¤©oK¦‹Ì¡,;{©&8,0ı
ÁŠşş&ßæàÔæª&«:‚ªÊaÔho!iÓUÚ@V"sø—úÎŸ.]IX²£1¿šP¯Ö€b²Ïzöâæ4ÃÒ]Ò~jH¯Ã|äáÉÌO9Ÿ<µg×$T˜¥n¼ÖQ––ÉĞ9 õVC°†S&†sò¶"0€±(´v9÷âÆ€íYÖe_m	éBD!q=…A]	²«Ûå3îz]'k`F¶„(¤O‡“Ï6Ì¶tV´îgŒˆpöï” ãü¥Œô™¢ZAc@”seÀ¾†7™«¬2RG‰]İ´#’qUÊC/4‘Ås#¨°ƒ4ˆâ6EÁm‚ÅÇà¯ä¥NŒfNİPÎ<ÖK1oĞk‚\\Å„ªÊ”çÑ[:aOá AÕÔà736:Kúuq±ô£¼¸	UÆîåÿ8à;:.ÙP'r"&‹ÕÈÔ9<(&%Ü›U?óõ‚ØÜÚìiüÎÕ²7V’¾Ã1‹}ÑºŒëmUİ' ¨±pşùÌ3B#¹kD_®MoA¸€­öDâ%<æZ—N[Ó–ĞÀğÜ~5˜œèOX;%³$ÄšÃ¸|ÏWÿg~ÖrıcjŠ,(RqÍõÜ×vV¯¦IÌ›p°5d+Wª„Ú®‰ş»WÍr:yãv)=–Üv1êøq§Şæ]ÍWŒ³”(Î¨&4Ë—¬Éq·Ö’ cÆÄå	ë˜˜({Ğ‘k^ã²×ÆˆypÃiµaÓ$ì,ˆ€~€¸ÌâäG‡ùhŒ:Ï–‹P¿º4ÑÊWT6å½+ÎÒ3Ÿ\|ëş¸cA“´£¾xÅ 0Ì‘“« K añÕ`uØŸZg÷×>†ÿe@Ly ¡ıª_ºL ëèõîÏäL¬ôôë–š–»àŸ‹½)KŒÿ}/ñõè;ºô¯‹:¦ÃfjcaÒ~cÑ]Ò‚lëmõ+Q¾`G‡öMÌ£ü ØºnÈù‡a2a¥L])ª_.­Æ˜2‡ø NÄxU¥!r¼ÆØQnH“Y\BZœYªˆŒYS\™nv#ä-ò…Ù!¢ã!¢ıı½ˆß,L†hİßcá‚±€‚%m»ú§ælrlDŞtóõt„ğ¬‰zÉtT×’ÒZÕAÿƒ¶7ÃÀæ1÷ÊÂ|Ö`ğE	PåB8Ç@‡ø`AH•¬6têi¿4pF³Ã?®é¢ALı&½çz	_ÖGÇ,HÒ=|áÜÆş—LŠÏb[d=:dôl)ö/n%ÿGtµŸÔ,`ŞŸ_Ölüwü.ûòíš³XÌ¦£ãxÓ4ÒÌ{Z´Ê”ó%²›ÿÜm“	+ir7Û7^´4¼Æ8¸f£™‡€rbáHBSò"zHÃİP°2?
0,‚‘íˆyÙßb°Ëw^Óö!ª’ÃU°éÏÈÑZ­´;‚r• è©&5nĞ?)&ëĞ)ãÄ†uîXRP“§zÏ*cÖàƒ7²áÆ“72¶˜«®tA›éİŞ2ø¯Ràõ¤iñÌC‹‚ûæG>½±æğÅ.·aoÈ6!ye\çÂğ+6J¼×†YVım«&BwñêË²a4?šœ\»Ï†&à,çÚYl>ÂéÖ`•?!Õ€ğ«Ñ²Ú˜7«ïSQà=	‰øèç4ï“ƒ9Ut	©g¥¿˜Y;!¼û§ïê }ËUš5¾¸Oq7½A0ê§^y aT¥iL7*Å+ø¤[3hÁBe]¡®¡vºìª'6)N Ş£ÏN}û0áG:g ƒíGa“A£Ÿ¯
bÃ ŒjÏVñÒÓ;Ä!ò¬J§øÿ¨ıŠ±}[1V00E¯'Ø¸uSK2Lúè‹½8¡úÄÕèâ´®1f#)#nbÊ”òÑ0‰ ğ„£Ó	a×³Ôí“ ‚Òàı@dD“mnxP~}~Îkšz4MRº% Ã½“Ã_üB‰)+i¦
pãkjGq{é]‚sk,êÕ%åğ%ü°ÏÔË´OÈWí<ty…)U%ø3AÕh:{KÊÙDÕ%Ôı¹ì‡:f^c—9½˜¹[íól ÷8•Âå^D1¥Û$©Õ‘˜³ùüøŸÒ,Y»%¦O%C+]-Ì²(°ï ïÎ…)7d`•Ë››ÊµsNÕÊ‚Rïõ²úÙ³óu¬GŒªÁíZ9İì}ŸÿƒÓ‡H¦çXK±JÕQÈ“~#Î†¶Q³ ïÚ˜êk¥ø<A•õB'ÿ»†æ>Á•‘÷	ñ
¨éqY'_
ìÁ±5{ĞÈPROaR?ÜãQN0ÜÇjëteŞ\Ú—BKÁq÷¾§„¸³§ñJy´zÿAïHúüFœ§Ï3‚`Sµ<šj&¦fÉ¹Œj[ LÁH§ƒ¶]…IÔ…Ç{Ùv›…öÎ0s;ªºè |„í}0§èDÎ
xÄª1Iø’¹Œ³¬ß•Ğˆ[_Ÿâ”+/¤SÍ‰»kÉY‹"Õ§ÂŸEë¿EÏCÁS8£ÿàåD6ÇÕAI=ê€å¢ÖvNÍbèh¹a|ĞÌ@FºPÆ òÖFYÜSŞ‘yìH­ìLr×ç[««-†Hı¼^½6h—¯êæà%?jxÚF‹ü[¾€vOé”n¹ñVeà‘XhEª&Ú7‚ŞEtÀ£ïğº{Ó}ƒv³[À.n•Òÿ@,y÷ôñ”J½ç´¨6dõæıˆ^€?'¹Õøöšê¬è#åUë-ÍÇ¦\ğ.[]YI+¼«HeÏÆ\ş1Õec*ŒèB6éèJJÙ²=Ù¶rsóŒ\9i¤j—{@åxš¤0d-ep3:<hÃÑâZXVñëÃÉJHLbÄ¥šÓ¥ü˜GT´Ùd3ƒ>…OĞ^pˆwN•WLÙO3|Lüœİ]pa‡Œú¨µ9tSêk(ÔñÚ:ñDÓ$%[ÌÈC¢£å3Ğ0˜ºj¼I÷‡Ó‚Y* ĞlEÉâwŸ²Ğ ø.8Ğ©„¢QF²¶°g§ÂÆÕpÏ¦9·
$È˜ğ`¼÷î÷ökÇ;)c‹NÇj1møÔ‚©Fa÷CcN•Ëª©Ì0¬-H» šLùùòÜ™õFÖN½E¸0è&ıJMdú°Ëd9÷-3`X–YÁ#„´éôRL¶\
3|O“bse—®ŸÁ?E@]u}çø@­_d<­¢ŒG÷Ì˜"\ åøàöõæ2”ÁBb[²1Oi-Ò©y¥LQæHmÀñ^eÁt£˜…GŞq"Ğï*Ñt& ±<~–¨d˜	ˆbˆìüÂséKÍÏŞËN/;ª…Ñás›0ù´e@×UKıÍ„<|¤C4¥ï—òûæÀ„l¾€é‰¶.m±ÊÅg*áœğî¯B•fA®€E­}ïyËgğ¨Ü¤ÌlûÍ5	Öd8	¨KônÒ‹s>idAİDûñ•mU¨CzãÒÑÜœ‘…Û^n‡8Hxv)GXOçyÑè33ğ•P%{QÍÊª#’ì‡âùïèíÁ‡çEŞZ¢»b¬•ŠøjŸ˜ŸEuuÿæå!z¹ZªÔÌMN”tñC»Ísá’Ë'	ªıóÇÓê›	Xl~"±;Ã—¡<Õ¢‰^¯‚´AJùµgö€ÿÂ Nå­8–$í©›î¥yoÜãõN
(œíra<Bo¶Â00§—²Iö5h­ñ+‰ï½mª\Ã²”¸˜äX[êãã%¡\äUÀøj_/$±¼Æà-üÈQPEoŠ–jqRgá˜KÇŠò:HT ZàÉY]?gwºcÏ‰*ç  ˆÉ‡ğvÃBR?„8=üº¯İql8 åÎIÎ;şÅş©³3BµøQÄµ\’»µü<Pà¶¤Mî3§ˆNô“cø‰N
Ê@ft@Ä²ê€¸4zEˆÆO®‡lFI¹Qöİş"ô}xâ4IE»ÿBlıAµãÆÄXò†” ^Şõ1túL0tÿ¢Õ•;lĞ—[ğù^é( ¿wÔä¦VÖÌäáæBRŠTğÕÏ²ğ0İ¿Q^ş¬ºRÀøïòİ/•ªÃléú›7Ÿ mŸ*€¾™†p>P&«0n Zu¥ÈÒqÌÙ?qd	£æ;züÚÁ›1Öˆ€ˆêÑÛOã½…›ÿ&Ì€vã€–˜³}&Ô×~¾Mç(*š{U¬j/’„ê‘ ÿA¤d~©œÀZC_TÈ%³ÖUEÛ˜ÀE>öor;Œ#£3”3ç©iÏNÅñ-TÀîä[ş:Eà†	1ußSJ©©&ïĞN":LóeÒ°—yİQEI{2âÎP¿éãäoÄ(ß^‡#Ï¤¢!G1á aÄLtâ¹ŠíÚ×“ùœÜéÖE•ÚqˆÜĞÄ±©{óm75øéø#•ß©Œ?>¨˜]~û³µù[…©;´SÕŠE$v›}Î/Çä°ÆMàV¾Ú# ‰bÚ¯×*X’½”á$ÒßÇ/0g¥' î¡ZeÌAÇ1azÄ*•pJdá$á
<+ô}{'ÔxéüáR›lBÌ9ùá2÷M"8ïË;Å¡¹°\9Ñèà’Æ±~¹”æ`83
ŠŞf¨_°–KÑT™Ì;8jõ¢e=Ë¥Åšİ“½Yßf‘”v6GÂå^Ş³å·+2…sö,?z0àD"gÈ}m
Ï£^)ò—ÒGiƒÄÏVyQÏ:s{j}ÏÍ¢M³À\.·Éÿ¼›Íªi²7I/Ïè0On&ã)Ù³X½
\ƒš$
‘uà“a&úâÜNš´Ì¿fƒnô‡ó}c]²‹‹·ŠƒuDKcßŠ­óWÑıæù'4µ”J7Ğ„@$'»9£Xİkİñ¯)»êOÌ¢ãİ\‹e©|²áÌB"JáŒª½YD…**ÂTñ°aIÎ«wœ&fõy`ª¬'µõL¢!l†"¿ …¼ÄlÇïbØ½Ùƒ^AF÷¥ò.E#uÒeÎtI#G ùç6ü;1 / a+ÈË=Lsz©»q	¡üß­”Æù„‡ë>AiÀ­¯®Ğòm¾;ÿ,ÍŸˆI±øeàö@×èiVÙR„Ş&=_ ËïaûÇ^z¼.s­Vätq`õ„r¤’Ïò©£…É“„lşw²Œ{¬p¿È:ZX]«±*ø‹}Ğ$ÖMP,ÁœxÏ<ëÓV,”U­‘èRãHĞ *ùº¦Ê‘èÏ×_4“Õ
æ."‡ıÍÓ‰• ŒuÒ*ÃÛ±Älõÿô¬»O~$ÍŞ%„×|“ZÔQWx#ªôÌCŸ3Š[u"Z û'f›¶ü¬dRYV¾Pîh3Wi±0“<Åv4åÖû·Ñ|Ñ™Ñ,x3ï,¢Óåzq3áö {×…HñçeR¸³½¤2LfÙ4œ¿'­®1rõ Ã%lû+O¨q£Nµ,‚{z©Ø|Gy!şê²&8N ¹ú±”?o9mºImïÛ]XôMŞ¥“ñr%¼qŸ#Gø«Â`hoÔ%åSC…A?±ã…îw{ØÚœÃ×1Ä!ƒpÛÙgY^ÍX5jømoÚebÁfc[9T½+fw0E,™~úŠ»ÑF@Ë¤=„Wi¤u$d¥Ñ’––avd“ÚÍ…æQURWõ…ËÌ0B ¾0”Êl5s{7²9â°‡ÍHÇp¶L2çJÔ?Ì[©%¿xùËe¿‡×Gè¤ˆ›”é~ L*ra“’Õ®=¤
Áß•-(ê©«Ò~(<}Mx@^~-*iFy5jèÊ @ù
[ÍZsÎIdQĞò^a©zBÎ /¯œğ¸ŠpN’!š:·yøôúÿ¦ÏªäZ”¾ÒMÎs]3ôqÕõ©¼ÈĞs0Ù37º¥c°˜Ö7Å{ƒ(|ƒ:äƒı^p®b†Îßzbâ?K+Êq7Æ³ÄÜİHÉ‘9r0ÛÕ·n~~ÏdW”Âãé‘6Q=c²Öº˜C(»I«)­N4)«õß“ç„ÜÌ*ÇÄuww½ëÆùµƒõG›%Äe¿§*75é2
’3§Å|€;<³ÑÈµXùöMşF”Ÿs ÕÁÓeÀÎl/
ËOÑîy€yÚJß~¸ÿø|ŸF.ğ Z	ñÆ‚ŸŞ˜æ]ãÔÜ˜Ñœ5ƒ¡ş^ùØĞ•WGÜÎCà4Ş-KN¢io ËBèÖz>¿ËJÒÎ­Eê±KÁÀ )÷&ÈºŞ5ÅW²âX4<¼ä‹Ó:Wee}·a‰¿ì;õAã¾Ò!‚L}äö1RêäDõ~›¾1"“µvŞM¶!¢×¥rŸµ.>÷ ï5”¨£y«¿.Åq ö?ß-\“^Â‡bE4´]7\5!‹x¥ÚÓj/†nÌç¾||_uMï`~„œÈ‹kŸë}¸İ':„µ	Cc·®ow GmP³‚¦Zå„¼_Sô«1Vì¦—6“ÜŠµò®ğ¬kï·M÷*w}aô¡QGŠmœ¶œ~1Ü#½}‘BÙ‰Ï+…ÕNv‘v='J½ô€0š‘ŞB ØâO`¦:4oâËî­ëõğcsí,j/ıÔ•Ç
 OÏC·şbXaW	#ÍFØÑêâXn”n HóKÊ zExÄ–UŠÎÄzıâ¿¨Ïg1ù"Ğ8d‹òAŠ2h§snÔï\m¼ ¸&ñÜå¬Ì¹›6´ûÊmÜé£”JàÉ±Æ…Ù	š“rßºl…Ô¸fYû0ÚĞwö¸È&ë¨>-
mU¥ñÉzm¯cËï®[„+U£³bGìiÉNb¬¯8›d·@6§C× ö“LP‰0¦à È:KA‹ÿ<–G_³ñ–jÂØëX¿3•¹³+ú?uy âsÇàem%Ğ”œ5o?GÇ©Ó_ĞåH±³(×)œı×‰ãÁ[I_lüøÜT¡›®kdEB´9ØsLm¨e¾$q¦ä9ÆĞ½Íõ ¼—·Õy6»àØ’ìH¶éP‡pæQkòF;J»µ.x“.]U(pH%¡|!Ë^5CUÂU3L)¤A¹`4{4}uÆŠV.ˆ‚|¸eÌ•æK¦‰cÔ=Lg=;$àmötUÇÓÀ/¼rkU¤³°Çá×õí»Î¤YL]ÜIñHÏV0K‰y xx8Ê¿6ë‚Ş×ş?ÓÛt¤è0Wm%/#Oˆ`ùNÂó\|ã™Œ*
ëÙşß|Ã0lı¤¥ÊòJÇg=#òbŞêÎoÆ¥üù,¿NØ£M_)Ş­Ö‰Å+›ÅtÌÍ¶w9:ûŞ¡«¶y«xgLÈHÏ‘µÅKU“ÖOu®Æî°ö„Î¾rØá¾ıC.èÒ¨EUvI´‘nkÈ¦_ë+q6œŞÉ<Ê¦­	MÉúˆ	:@	mCp%§ŞœDw°-w|î†.Ägd§°¨nTo¿"ƒ ¸pÃÃÖ:î5Ò—Ü4°VŒÁ×ÛŞòÒEN×ƒã_à'nŒ…Sğà½Y(µ¾%Ûªç'KM®ÀşÀ5&,<4›¤YiJ¾0RCYåÛ.Ì§cÊÚ­ÔQsxI'´Íü² ›%Ì–7*Èïaö3é½6ñ|UÕíƒÍœoEÊæ¢Ô}¸ê.ƒÉZÙY!:m·|aøG_|š`;øĞãE„vFÂ4Å6 |Â8óê~¦Â®Ï0'¶!xÆòì)üæ(E·ªë ÇzÕ4S6W]–ª,è Oœs‘:;:r4pÚÌ¯øñ¿!‹ÔÌù£«£“ş†ÆËm¢Â¸1½¥–GòçÒ›áõâ(¥HÂë·»F?XR­™f°»…*8H[âuÂİK3Ã®ü•Å§ÜŒ!O$H”ßHmUj¤Ó‚ŞïL•z¤"ìV¤ÇN …<=–fß¼2ÇyL|q¬ğ‚Ì–|*iÖrşLão°ÿ8ëük°ŸoÅª`²Øñæ R;oâ‹¤úªAÅ¡UYıv.¨ÌvW!²q#»úÑhE¸Yz.0ˆ•Pb
Ğéé¼­[‹Ç)5Üö·ñçbUXáÇ&»‹æDk‘°<µ~àz&‚n#‡}ªh|í¸‚v>´bhïåqâ;ü™ú™:“Û¿T€õB~~ó§šRaŞÜR2(²‰Zt'ŸˆÍ‹ŒŞ¦+·IÀ<v{@A´©”¯—”VÇVÏ`Ä£õ¥T­ÇäÈÌ$©@ØâpvÈ3ƒİË<ä¶‡]-â%o×´näÏHØ8ciDZBÕE\¡G8°PàLÓåxÍé÷£6Aä]Šş}äè©gX»ø2¢îlŠ«€Œ<M·gÁt~p5£¦ŠÖr%ZDÌ|ùJtšäØ øpbş#N<AÆîæ:|n!d:©¾6Éxø×B´£Ã¹`2ƒvl¼.otÕÎ+
;Ì6úWuÅd ğàSX‹â?mÙij‰³¶Õàt)àˆšé.ê?ui¶^¥ã6ÄOŠ”	„ŠY‘Ìğ7˜ŞBÎ….èu"Zá5¾íJf‹<‚Vû•b•Å&—¡ŒÙÜ(³İ®Öú9»çY:Úâ‡íw+%±¥NºebåÕ¶›hªÓ¸½2Q&ÃÜNŸdaîëÍ^š°%UiÛšæ‡|+FÑ¬ëŸ½ŞŠ­ùÚë…íOÃ‹Â›^G§˜<œ¼FT>!İÊg»ÿlˆ|{dÕo%Ú]2H¨ô„%C9 ½eä dÉS‘{oJDEÇ6½ÂèÜJfÈxD†æ¹§0ìU‹’ÉãgŞ6Í­—+Âù– á½A˜İëx%İ<>Z—±ş‰9+œ²É¾´ª,b¯YÆKü{èHÑÍí·K»ÌN¥V4b¢²‚ï 5û_™QvÒTã.Î’m`4gUş‘ÿ£%ó5ª4=Ä?µGWyí Ù¯*M6ÂÍlÓ‚ë²ïàŸ(]~)= Xwr³@*6;‡XÃ³tìáÃZšo—¼ŸÂp†`‹è7çoFŠ0k´L;V=êáfÚmuFµî½Ô'¼5•g™ÎÁ:TU»„AË	.¯·Lù¹d$ù†Æ
s¬s#ú$âcd¯ øGõS›:»æÍ?%¤´k5?±À‚öuæ6`2ààã)ğk^–ËîAW_\½C¦ße+a¸gÉı!ÖÇ¶ejº†ŒÏdÑKà¸¸(×‰Y¦ •ÁHêu^æër—,= _R·<j¶Es!³qB¾G7)»Á*Nšzr9‹B–1¿Ëú/ßÜéŒ™øbp¥ƒíHşÁW[£C€JÿÑğá¡^Ü7tWŞ‘úÓk?í$|½ÀÖÖÈñËûã¸²)¿/ó¨Bb>†ï (µCøy-°¸õcràZÊ"CãçKú-}€_R¸›|xKÚI^©Íß
½İlØŞªtıÎ“4%ÆâT¶×:+·n&jš$Œ´†Ÿ *ğ!¶ }r}GÙä|®ÂØ6Ÿ.=äİ£(zø£¦œ^SUƒ·¥x¸ËØ^ƒÈ#­·;S£s—º?6´¦VQŠ,=3q=IıIÉû3d›ÿß‘ò³Â›Ü§Ú‹Ø4©¶   èl”jŠì{T Ş±€ğK°b±Ägû    YZ