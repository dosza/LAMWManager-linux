#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2248067410"
MD5="6a47f9d19fdc2c4c70162149cbda456a"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22616"
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
	echo Date of packaging: Mon Jul 26 00:01:24 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿX] ¼}•À1Dd]‡Á›PætİFâÉ>>	E}ƒğÎ_ÿGDıùºŒ‘’pfÏu®™ÆÈÓ§t×"÷zi¼a®B™‡Qc4‘Şõózq}:ÁÊ$6•»¦æCÆ‡¾şŞ™9¼~fŒÂKƒ¿‘«Şfrf<gèDıTp."ìQÿŠ²tÄ4
^€ı{£mÆ…£{öZË@òI€;ù©Yf÷Ë´¢Úš4¯aæákW9ã)äœµà½zOïj:^uçÚ»‡û	Üc°Ñ?¾•Ğ…	¶Ö5	oú›l¼>¾?7§Å>¦Ò)é÷vKÁ°@úauU¼lÆ!XœÊQ-¥•ûÆÚo¡åJ;·•N4ÂvŸ–o‚÷Ïî‰mäJÇŒ
¹?¶1:/oÂ‚é-óèF€à?”*ÛÑöLaD›Àa±¹)_•y…½ga0¼UŒ]óæ!Lt™P›‚šSÃ<a2¹<ø$E’T[‚g{K&°ùñDZç3îfïÛ…­Û¶·¦OU›è0¼èİ½Ü¶röl£"Ëjæ'EÊ‰nVĞøEK·-²@Û#RbÿÖ¤Ÿ Ğk™c2H¾™Ì}^	>/
J ¬å2ï­‹â÷(¬‚¬;ì¹ªš­ÅRWÊH)tM‰úKéGé¹Ø7-œ§m¥êŠIø®İa>v41ğ.^3Àæˆ±eô¼Õ¿·õƒÿ15ÏhkQ7ıÈúÆ£8	ú0°²:¯¼ğ%ºZQïù—&Ì`#Pß†PyÄ”fó4>W¶øÎÙ…È#=Xö•nG//÷²5W/Xz˜üUl%)Ÿ]øø½BÊ<³ÍäÜ¡µd(Àc‹£?ÎD_? áÈŞW²LıÃR¹´·q’š4¼+lLö¾
”®/.I£UÖNOÙsB¨r}R•Çí…ò£wƒÉœöw®¸‘İ·Ö`eVú/¢æâ‡7aÅy©*¯[^^%ù’c¶š¯W¤v}}ÈÎÕèZí*üÌ#w” …øûÕx H‘o›NŞïÓ!f6Sy´R¶Æ]?´Û˜Hÿ»_çß:…‚‘kê¿š;qv^ºúo" ÓÿøiEØw¡-:õFæ.œ.¼Mp’^÷üL
ß–0zs§L‚RŠğÚ¡RŒÿ+Ğñ×èG’â>Ã-„È¦÷ /œ^z'o’ÕÏ·ä­%ª‚^¾Ñ‡ÎÖ*BûS³|n8MÎx%µ­ËÌiéV]æo©š"‚Ò¼—¡&Ş~Ûé0C=…~XNÑàz \‡LwIıQŞÖ‘Ù¿Ê4pÜao£¬q#‘JLøƒbgïh¥1‰‰„W+Ü¸|ò‘•UøWºÔ=ÀEÿh]Î¦…·ŸÓ˜¹÷ë.?¾F2Í`Nì/;±4<¹MLS"îÂ¹…R°[}60N¢)	Â*1a°i‘Y_‚Ã1#	~È»­ \ZYÖC«w²N:~áŠ[‹ÎB¿|Áû–.ëHğçR™P+©.3–°k#èë:ŸÂõø}ÿq÷TŞè;%÷Jßb“É*“•ùÂÊºE±^¬sÍ7	êE¢5üÕöëúIËE‡Ÿñş	"åõ¶)Qoä­Ü>i½ªÈâ{K#±¾†œòÈq¦5ĞñBês<|”ÌÔ Š]éx¿#}³t‰s>®–éu”‡ïV«PÁIİe€&÷!£ıÍïÀI´K¬'Q~j€å tÏå˜®ëP‹İ~×N -4Úİ|„j}lûjÛ)9óÈ#£8oøËw° ~Å‘ÖwqWräÙi­L(ÃÕ6šÍ)e¡U$åÁ.Şi,Õ™´Í'¼ï—&Ñ’É+KC'ØZAeş àá-¹ÛÈ±ÁàAèu¯P,v›‰·¬½OFz¤¸H5å?ğ{Ğ;ôÏ½ËrïÚ’)§ 
oæB¹Eİa$p›äœcKCfl/µ
ÊŞæ(tËÚ™Ô~(múĞÑ—­².Ş8ÇFƒœ9:}-aÜ.´÷8±÷øY¶˜õ•gB´¤ñç­R22‚ê¡·¤EÌ2Ø×“¨î6$b`
Ë¢/^D&™Ğ±²M9–j¶‚S¯¤HÚbà¨â{>  Ùr,XäÈşßÆlï¸©‘?öAWÉqğ¢¤l¶½ñ'¸Z>%+I­“‘³ÈEKm4ÀZÅ1QÃywpé±@€í Ú1g˜u+Òfõ!r÷%y€ğ~mÅT
M£#Å‰Ü	·¤J"†ÜáÜBñ8Nh?nR"®êŒ8n1‘•æÏ-Ş¾ãl‘ÌÜlÄ+K›¼ÆÑl;ÄÃs{xkå¨~ã>ğjOX±VW1¥TÂ‚¿˜Ÿ†Íà.ø›døÿMcCı2i~ÏAEëëç524ß¨ì4<8Ï‰VœV®Ïr¡d:ÈüçÒ…*I-ÚÀì	Æ^W•ìÛ)°mn"Øj1JAË…Œç)™œÛ‰]àëô5@xDOY$¡u"/vŒ®Mñ¸6€µÕeA’›’åÅ½Q4EA'ÚÃÌZê±áW³ĞQıÈ«—gjP¦X3¬ı}QuŠ’ó4>¯ú’Ä»,Ò7ZÎè òô0ß/¸"Åe„›@Å,‹´¸zxâ.0ıÿ/@æqHÿÒŸÚ{ïÑˆ‚SD“Ì~efìş²»~öQå4&7Â„<"6\?/‡!‚»­®Ì'>#“g[¡Î$öˆÈõ‰1Pª©&Xµ³;GqcşäÁ™ƒN²ğÏmÌ!. *TT½Ã°(ÑÃG0”—àñ JuòÀÑdõç¹ğmñkåÎ{²Çõa%¬¡dçÎo¶8ÏÆ	@‡˜¢@÷ñÁ¬4wûškùÈ{Ö:zL/JŸ÷’"·6“C!‚{©+{˜Ù½U·öUÀz4zÈ…^jê&4M·OíŸ¹U:Í-»ÛÂ¯3ùÈr¬â}L+ÊÓCe=O-Uø¿Hôå¸õLFV•áD?>Ø¨õ<Ò–¼í7·z‡pìI Â:oX|ÆŞ-?'×­&^Ô›„¦Ê\M¹ÛËçáì•¤ö¯r‡s™*”Ô‚®µÿi=”ÕX#Âkl
ŞŠŠöğ2BOC¡D@K–Úp‘w´Êd8²ØğÖ­9ëeßK=YV`¡
Yéa—{¬˜k|¥J,Öÿ[ÔxŒ¾7 ñöƒÉ®Iä.Î´!	gyö	8î'{ô¤×/Eb±Sê°Y©;‡U	öï$æS/!3ÊØ£Q{ôIôÎópéG6@s;ƒrõ¡QÄ›ä·«ÊpŠ³Z%E²ã$8°ˆm\j/zÑYÛÁœtKUøø/MˆUë«é¸8/ÕÉ–ùİ™83u=Ëğ0ˆ$–wU²¦Ó0}{Äm­å	KKúK¾nìÚÁ‚#‘j‚ğVXvÆÍá•o8W–£Á¹Ï¨\ŒGE…‚#?4ş[A€øÙ°õ‘ßf)jQ˜”g“µ•ŸîıQ¨ÕÃŒ H+¤:~ªğ‘,À)¹²BúÇ=˜TÃ(Bm10ÿ÷/­Æ5ûÕËŸv“Óp„i”LŠÅn”'š˜Ò«ñœ OÙ—éæù•‰¸ø&Dè]x¨«±Kóú•øW…ñSßc×€–Li”Näh±=áÙäÃ§Ë•dÈòĞ5º,aù´­È¹ÜüAB?nŒè^/oE6KmÃŸD©ÁK‚^Äå:Ş#’3Ixáxé2,"½.ß ‹Š„öb#Ñî/{ËÊrni¢: Œt¨Í«!V±h;q/í5Àu3q¶#Ş‡İƒ8]VÇSÁÊÉàµ­A÷z)zl©0yÀP¾Ëî¥ùtò}ØÓ’\J½…[Ÿ<¡rçş‘GÈ#à:Ä—‹æG}/gå–¨æ{İĞ3¢#Ú«¦ÆSVóÏ)…;¨$›„·IİËÃƒ1ê6¢!=4Š£ĞàÃü†ŠmA•÷a9×ìâq‘;?•Øo1
¼X±"·ÔÊ ˜Ê°Ç	ˆ½§ì„Î^0â?iaRzŸº~]+5–â3[ÚŒq@ª×í¦ÓüDÓ´f:äƒÎkC*æ’ ‘e«ÓÄ”56õrã_²(?_
2<ò›£[á€T7óÖ‘íâ“ÇøÈc
f#(wp]Ú„´k';VòjDWéˆo÷Ê›ŒØxyÈ±¹¡
2ÿ.Ö”t]4Œë#>Œxz¿/¿@—'£>ò”ĞÌó^ØB\ù«„@ÕHXŒ#jı!¬üŞÂVèú'²j‰4o³A¥h0"«¥§?…ë%É¥3GÎ~ZdC™íÉœBîn“wobêt«ŸDÙ—_»µ»"-—ü)×Q¾ì‰®o¡h¥˜®uƒ¸¯è«<| që•%ÊŸÂ8ñ¬•¸2~¿Ïè¤È¶ç‚¤SÁUŸµ9_3WwaVª™öŞ¼.dYˆ¹r69VÌ8ùÜãı!q~ÆÍ
œ1h•:†LúÃ¢ğ„‡!•¢QZ®-n¤8[*Öj—Ú§?ğtúÈ.²™¼ ÅÉÍ)?–d¹Ûâ@òc"@E1a D{\æ‘nIÕ°WVÒäoó‘œUrFx	ªmF:ÈEu\íqÜY?Ëäv²“ºì1Ü? i‚á´2"sÊŸáéN«p8Œá€iLhèöï[Ê?Œ//w˜NMNùUã	åëSfoÙCé°2@Ãñ" ÖÂî$Éë¡RÇ9·Ş{¨f†vérJ§±cœŸ€A…œ*½ÉQºRÇÄ¯‘f#Úº(×-ÈXŒ´“ñÑ—À3<Huu““)ËªapOÈ	ÜeC\·ÎÒUQ€hú 4lßş¦Ë§…#ÂsÃÀ××…İ´œª·*ø•ÜI¶)ÍÆÓŸ é¹¼e˜’¯ß\ƒç:SéøìlE¸³$
jÌuk"$;=ddxHvÛ¯>Ñ¥ŞùšÊ»j‰Qˆ×åà”zZ{ã¾ß”÷«û«Êä©¥o]}Ç`)Ë ’î6Q9sŸ°$éÈ4¤R©Ãt€9úÑ	M!¥P;= |éÎj¦A–Ÿ
.èÊùlÇ¤=øğ´µ9ÆÜt3—‘.M_äÖ/¦i”ˆ§çãï{Çjsö%¾j¥,©uyÄ•È.æi•#ÚBUovpªé=¦6ªZfOº¼£Ñ1³Ø»›DOŒÏ6Áï#Û¸D y¶êP«…8ÂğÆˆqTŒÀØ=ö[=ûKhå×ÂdÛ'ˆ`Ö, mRğ’ïåg]—…ßØéŞ99ÅÉá?Wˆò”Ã{‰}—åÄÀ…€4‘o‹†•ª9iÚÚ	5;ªÌÚƒhnˆ';EHÙ)P.Så¤é‚¢Ğ ìÏ G:Œ2‡Ñ£z£çƒ	ÀY-´ò
uÒB¬ÆÈ¾<ìu”Ê&RãÃ<’BI ûå'S€ˆ™”ï
Mşg|ĞOX,fæ$Ö.f x,…#I”»iÇ'@Å<Æè–
{$»ã¾-Á&ÏûwÔğV<6»xÓ‡`œàj¾üúh±ËpmŸò¬æ]¶ñı®ÅŠI*Nˆ½×‘ÎÜ<ÊxƒÈàtP|¥€¥Sşgg‹–jÇ$/xÒFÏi6sL×¦"4w`_Ñ´mCó®]‚&S{b•÷ôÒæ¦'SlGwÍÖÑ0C´¦Áº{ác:ÿ¼¤ŠËáp¸ùjåu}ödv,H~¥`³„é8Ğ~©ãyvœkG†XÎÒ–±9Ï6g/!MÒaŞ$“FÂï÷-E7æI¥xRi¾÷†õ>Vó’q‹
ÈÃÑ=aÍí/+šXMõ¯ìiíl—aõ“"AAZ¡~Ÿ ã}351ìŞÔäP33•ÖKŸ™u'ûÚ	…¥ÂšèøpopuzK¤½±P7Ñ>E¡’èŞóüøÇqŠFÜé.c]ñ«7/g‹ è+„}´çç‘è°N?G¹.ûJ\öè‚ã²Ø¿<#Ø0)ËšÜ¹uÊtº­RSóœÂã1ëÁvÕ!İp›! |&Å¢3<n+®n‘’ôÕ†~”¯?7sY~üê_‚æo‘["Å!í°ˆÊ<Fğºnœ×¦ g™_Àî\¦“Ã_XEü¾&ï©ÚÛíyöß’aRéÑÉêMÖ$Ì&ÈãËàpĞ“kMß™_o0ÁëF›Hùš­†½¦×i‡o’!gİˆ%aÄTûDÔ{R IÉ÷šuM6=
õ4ØÄlû”îfßÈ L„fü¨^™s—ÙèÑg¥4W'1fš2˜6#³Ou¥YNÇl·AëâÔZlIg´‚úX sÉ˜ÖJãÿ/%k(àÁE§Ób¤ÈÌqfó/CJ\¯¸>2å ¬/æcp]y	 GêçLŸBë0k•”êà7¹¬•ÚÈîÁóc«;òÁøQa{ôáˆÕ!ñĞşbHk¼¦i)Še5ù–/Øs-uõ¹øä‘ƒ:ãğ™cŞ¾ 8Rütñ{¡æ^­Ô¦£ĞWÙ
û¹á+¥>zuÀ4ÎH/Ñû@ÄËxú«XPé¡Ş*·Rhëá0{WMÁAÄşÎYªµ«HÆª¶Á±@&Ú«²$„ğtª¸,N!RVtÙá	¾¹´¢…šÑı"ô°ÈÛõwfµjª'ÜWàÖä›Ô1æŒ¢ÏÈ8…6ƒªnÄI,(Ğ#¢F¤šWaÜèİ-!<3N,â(5ïä«fÍmm·úOL}IÇBiPîÌ?9*ØâŞĞĞ­`×DòÆú“Ù|Q`®¦ÓA­!÷Ånè®aÇ{Qx?\A)‚¶Ô¼rıt/ŒæÂˆIÔÓ“Q¢öíïØç©—>Òo3+®ŒI_2ÖG÷†cüŸğÌÍâ›ÍÅPHQD“üÏwF¿ÕwÇdí(3p(_¶,G@
ïKéæç®T(Ô,‰îRÆÉ7~¡§.$E-$²ÿI¼"<yG^ ªôïæĞÿ„Q"iÊ­reQñAÃ†ÏÆüâA´dï*¬ÌDQªRª®‰;©c²D±étSÎ¥&e!f°%6Kxë~Ù4j×]½+¥ÚsøÓğ
;­|ÕÅ+áîÊñ@bæÁÊŸ&?úÍ[…UÂîğ‚ù~A¼TDÓÑIw71¬?äp‘¨¯T;ò6‚n‹%b)bÊRfšTGNòÚâ)bíC©*©v‡›çÊjè0­`:1·jx
œÛŸî'æôRÅo;Ù€ºñYÎ½ßÖ„T¸0ZmÂ#ƒ%…Eÿ¢Œ Oé‹‹S›ŸsAÅÓ\€XI¥¡ãâ`ÿ¥^{œè¤Â`pR?K×Œ$zt¸ß„iÂ6¥©v;4TÛFÅ³I•¸¤4(y{	…QQ˜N³áÂöİOôm4Üåø’=yÀìóiG„cf;à§W#Ñù\ÄáZVáª»»
T¶¤òç6ˆG¸F—9@Òl-—]¥ÈBæºE”§R™!‰9%H‚Úé*Î|I=@Ì
í#‡eÅvJ‰V‡¯ïxZCdÓBB)ëh'VÚ»?ü±­Á?ÊoÇRTc,É±Øİ®ÁÒ@Hœ4,•³)U2‹‡Oôô@6ïÏP“Š!âMè„îÇPá³dà£jÜY*riGİ)qÉ&ÆÍY€ò6k’`Á>t€JÇ$Ä¡HPƒà¶qËâ¸=l0Ttáxˆ@rÛ‚=Bg¼ AåGÛ(n½«ƒÌÛº]P6!qu¼áqoƒëÒAñ«¬ºD#ÆÒ"IòhÇóéaS©’$+¡şoªÒªkS9>‚bˆxrRoc’]Ä‚A‰}­ƒå@›íÀÛxs3­GE“„‘GI2öˆ!iĞ[±’
‘ì	¢‚'áûÎèåWZ-¥@ÄÅõåHımopn³›â.ò©ùËŸ%ù¹¼x/G“QÓ†«ğìa“NBË‰d'˜Yxv–—ùÃØ+ÚœŠ;5ŒŸ_UÀŒÙãP=Ñ³tìR°^~ßjÛ}Œ‘©A¢r•Eù¨~Wò®û`¢S–ŞØÔ­ô>¹k¼–9İ6ä§xzœp‘tšl‚ŞÛzˆ-s
^4ĞUgİÊábQË*(šrPä)£ä´VQñ¼ú	J`!ãr2‚ªÑ©+´<íé?_›° Fâ0Ÿ°,Ãã…5D¹Ç%Ò×k	QKÉhU Bß6sİìLcïÕüE_=Aìó.PñNêøë?ù©} 3 ƒİÈÔ6mØœl€kÌõ__oİKË$K•ç‹®ÜÚ¢1Îl,xeÿ=Ú´y¡—.ßQ—b'%İÌKSmû ø>@•KÂt®@ÓÍ#†¯TÈùÓ¸Ls	…KØ%ıYÚš®T®™6Å&Ğ§«Ü¯Y¥B¼tl×•·ñ¤ûu¯èu…q'wMË)v¬t:SP¦ù——ÖÇ2Êã?†ú=‹j=Ÿû”ñG†ü¥X7R	„L¡ø7zÒwØ¥Çt½£T#şX@qòM;QuÚÓıGc±ÒÀqQAÀ°&vQÊ67×Ê#N´kÚa$zuU²¾LVxÎ5ä+±FÎ¨Òö‘Ëm°ãuÂH©j­0F-áµXÆ›â¢b¶gŸ6ğ·{İ¶åcÔßáœÆÉèéri;,ş)‹ÀÒÁâ{Ä¶€Ğ•!¿(J×İC®5–SøÊê[djÜ"!äûWäQæC¥O³RAÌˆbKË4ÍgS ùşî¢ùŞ6%Fî|@É¸âÃ@JŠs¤½.ø¹}OLq	ÀR‹¾‹öünŸt-ÂK­µmf,‡¹MAf6mX@É†gÄSÔl}IVze=Ñî•>é#3„áö=±J»ÖSªl_/wñ¿üñ+5e}.‰Şİ‹LŞ$ğ)’Õ‘a¥3„îİ“á¦%Çnğë­~çß¢ó_-s¸2Ìæ&í>D›@¨MŸÛÕãÄ·Há£	Öøl¤ÛlI:{ğ¿„¶zì³ÎšĞOæÆc[wN¬Áp°vX<G%o?™O«µªş¤rBr-¥­ÇŸø‘ìlã}uy Ÿ‹³…¶+^ÜøÛKŠ*Ìê 2ûò)‚Ú$¾¥âc¤IR<²{ Z?ËòFMUó?â‘2uƒ€42k)âİì’ƒ/ÜT§¯«¿êàfŸ¹¯¤âğ4YÓ5#÷ïpûUTİÍ‚Îä_>,ÜÔÊTí7Ê GJ®ãqj'X É˜¨Ñå©?™ÓÀ³Çb˜¹Š–tÕCÒ!Á¼/æí	BBTß]Uµi®ÕcQàÇ~½€ßØ@µ*'.rËr—«^^…9:³®´¦Qšjœ(ÂgBr2¸Ô	¡rù‰§¤öpPNx¯ÑÍ»²jâ‚Õy«Sw´.Ï15æÖÛ=ÛÙ7­Šùß³`7İ[ìŠ°7†	Á€‘n§Ñ¥ó¿?*axy)}ŸØ÷Î`/ãÅ)ä†à$¹/pªk¢Î­®£Dİâ±¾İÅ;hüzË}ín·n`ü.KwF×¸(èijÆ}7A~èÛÃç°øf•Z«×iÙ@o™p.½ºı3â—à·eû3Ëçû"7‰ğM?#&ƒ¢'7ïÂœßÙ´e»nâÔËV;5JÅˆÈøkÈª—‡ş¡ãİœÛ0 Ön¨ãrµ¹l$Œ+hÛ
SN~çC±ñÀ]¦_)=yd âst\ÃQ¸'=Òo™|OP°m¿¯K¯p€ê)˜Î,ÒA&‹¾.Å^ûÃoD¿Ğå™ø§4Æ'‰Å
¸>á?}˜’H•×ñ¡×8ÛM.Zİ°nœ·°†7M[²Ó„JÇş‰EğÓörYË”áà—lnq<jf©/„Fë@øİÙ1Ã§r(µøùÙX›¾o	=ÍÈ!‚¥ßàÄT³ûÛÏó9”T¿òL‡ÒPJMWæ˜[Ë”?ÕÁ&©IB,Ïr
ÍĞò¶{÷ª;¯.,‚–(Zu(‡ù²‡Ä_Ö;Ğ˜ÖøhF»¾õøf
	²On&öÎF
s¦Öi¿†Ë¾÷äCÓÇğ¹E+4’n×'…óJ_Ú“/Öw÷Ÿ=8mò°hÆ
_SsÍ8wı:(~oóqÙ%ÓÏWø.fû4"ÿbm¾;MVşWàAü›í{9\Z$«ækè ¥gI§s“ø‡Û¾eV¦ï93ƒ`A¡nkÛh7şÊßÌË×êhD3‡¾š—çï º[ÜY‡Bh¬S“Ë`Ú¢:¨ü“ø^›Ã6°°?f÷õRúœÚ%ıT3öƒÚ §³!ã“íóÉhsp¯©¤÷ÃVm®Ö„ŸûŞC}BWÄ	JÈ7àåóõûJ¾Òª6efÍRÔœĞ€Z·v	Nª*Ø¼ËHêÛ:ò™>õ‡¦»íÀ_Ë\Ì05Òm¦õøvëÁé3]UssK[zÛI@ş É¾¦ì
Ru]ñu¶œjcª~r qæF'	´¯İ+ölš2i8X÷—¢ı0û©ËcL$ IùSW%=—şrÃ[ú[şÔşé0Ï™	]·øpÎÖõa¬aq¢Y,Ğúµ§e¹•¿™nªhqÆ½70=ı©ß›±!3Q†åHëÄ%]ˆz‡ÊkuŸÑÕÏÎ¢ş6;Â¡YAB]ˆÓW‚^@<ÖšÙ7‹.‡ZÏ‚™º¦Ñ¹dØ9/F@ıÉ!V~Ûtà%ˆÕw~±ŞBµœ=ôI¤+WÜ³—ˆ&Š§G¾|*¯PÚ!\W;Â™œ×¸«L¿èŸá¿Sï•ÿ¡´‘Ê'BmväOk„Z0ÜœÁè”òˆõ½\ŒY„f{f®`Ññv!D¨|ŒÅ“Al‚Á´íÿéØB,ë×ûO?``
$‰>Ì&!IªËëc+¦oÃ&³<ÙÉ5n R/'ÿóhÖì-Ã÷Ee´ˆíÚ¬(Ì¨‰Êw ³ş”:S-6ÃjÑş®\&IZ›õ‹5%zÿÛÊygozÔ\mÂ‰=Íz:uZ¢ İeùŸ|ĞaY@w0{ÇU§¥$1nJN.Ó‚±q[…³~m5(Ã#‰ŸxØK	ËY6ªû¦ÅéŒÁ1<W"+í£2©%©ç9æï1e™¤‹OöÜSdíÚÚèÇr˜+IŸ­Á½¯F'EhÌİ˜Ëe±9Uÿ0+,nâi*ûÄìêĞ,Ğ²¹GÃ,C•*G×+„päº®«²ƒjm(ì5”ö¶»9Ñ¸ÙÂÚk9È±æqµ =öùŞîªŒ!äÒ0Åw+•»0.zËÌÕ•JùB²È³¿Iÿ¥2ËĞ7e»áåã~{±¹6×¨j‹-G4¥»²JVF…ÛDÈñîº¼²ÇÚ&;§N?7Ã)¡¨Ş8¥h,ñHnÌ/PH÷h½PZİ„tûd«e©ÇE©™¥CâRÎìy•
##\ Ì÷"·Ä•vf>£·	ûÕf]K²M¶Ï¨ZŸ„¯¾MšåTšıÎ“<«i‡Û€ìäŸT½ûus›oì»v!DL ˆ,Ú­«‘´qå³{ïK‡°épÖ¼IkÚë*„ê#*H^ÌøHƒ[€/&A©¨ÌÁ±[É #!³
ã >ºâê`®.ĞÓØYÀ_YeTåÁñâc WßÅ_à]IîøK,QT©úºo\#•…—ô"Õ¨ŒQ¹ ,G²Ù:w…erËä›IîÄw­iùs@É`Q†…­ÿÅ?Wç¶)ÚÅ	D‚ '`'ı^äúË`{O˜­h× ¡¿E—ÄS~jß!œm›ÜqwXö7ßÒ8¸	s½ÍÃFjR›^R– ÚxlœØ%në!¶g|ó¼ËÕ	ÆbA(ßcf†¨ÃäÍ19Aûÿ¶¶‘”³*Ÿ0q²®P‰*Ù¸ä¬<Uy„Yb¾uöŠ½²Œ²ˆŠSĞ#D	áËPkZùıìZ¦\Ö‰¹I¬æª8X2L8Ø±åÁ§™ár¿‹±sÆé”šìs˜ó_·€i]ªyPÙğãç8bş1¸1¹^)E,ú€_u[m&¨oì#¹ùE>ê2ğ·ˆZ{Põæÿr–»•Â¹1[>:6ÏfÚ#ş m·@Äh¿ŠX³b_JTÔeèÃU˜ˆô¦SöY
2¤¨ônögÓt@•¸ŞÚ~ÔºÒu?†?şczDèSsÊŠÉ§U¨ğêõó&DB
°Ãğ÷ÏDø´Y¼#•—f•V(Ü™IŒÙpí´¦¹¿ +~çOé‹,7&ÄæDFjv‡)ôĞ´¦S–FDÿ¤lÇ‘;ÑŸ\˜„ºÎUÊ7Õ"øñéÙºïBTM'©Åè¢ˆ±µ˜¨¡¯OÌıÎ»OŞ—äû‰ ”Æv¹Ü“s¢‡pUNÈ†+­[K­0×„’·Ï¾D/ºßı-Ÿâ$ı»%ÁZOòUbXR+b_© ¢âæƒ5=óâÎØı“òg®5I¶…Í÷­†;Ù"tÅ³t=¶é¢•§}-ã6Ó-~İ{l€L¹>ç°q@ÿ	1æ(•Å°´,šäaÜÛ•¾ô“e‡ù…ó„ÎÚÁË1 >§èZi…;åğG´zí
áQe
ÊûDo¸ßëÁzÀ#YL¹§¹éÂº,ÎzÏƒôĞ³»2B6>7[%£âZ3¡!ô6 \KòSQ5šr&ããìH<ë½)i Fd?êÖ\‹yrìmøHïKOØy5z™”rUB‡r+¤ÃKÃ¥Úmíî?åÉho7¯ŠV ¢¸ÿIuw”º5‘‹C~‚æ±¦ 0ìi¸Ç‰JÎbGÑiIR§§rBÂ<â»l3°LSğ6òÍòl8«á*B¢Ñ¤äŞÉF!·‹±¥^»“Ÿå„8é3‚r'¿Ğ~„5Wºõ.X4WùÉÜâW™$}–P‘‚{­lfÏ!2£ËO@U¯àÀÔùTÎ[o0)Ë±“;ëbÇÊq¶Z'Ü9ñV†jÅÃ •[t5MÊT
¨Ûs¾ F=×i¦Úk«ò+P”Ãùok$­½ólj¥ÛßºÊL,ì®Hg…ZÒQÏ•p±2å¥¹ßbüˆ
ÀDJé:ºûWxÙÑÂÂ´ŒØlÛŠJ:Ó…µ/ÓÀYWöq°´`±ÑÑ;ªQ^ê¼‚*0v“ãj“L0Á8z~ ²üNFŠ§/&ÜŸ®“û¶`Æü…'+8ß½^¢Š+Ì}q9‰Q;µ¤ØøIßèŞ#Ë:ÓœİiZŒ>\NFî°å¤Üƒ—ÙR!Én2\~ER³lzHÃLåKR„Ä”DÔÃÿ‹Én˜¥ÒAÄòŒÑ‡¹	ìa ôL!HLĞÚr lN÷ùÀ cYK|ŒĞæôuøÒì%ÇE¨)·k÷FÓ|öıvø*P„6è«P:ç* èxŠ›iWš¿2°Æ6=€Ä€ZïşR›Ÿ
æ‹%;ìû«,ªfsS3^ã*®Æ Ò,bäuºXóSÉ{ıêÕ1¢È†x"?e0-LOĞÒ˜%+µDC|?â4+‚ŒËê-¯Á.cC÷­l5JäBø*ï3êÎ²cßˆ8`Vc`DDTÚ2{‘¦ùy&Ì¿GT÷hŠÒKâ–
Î_h™8ŠŞ´'ªd« 4õD¥*W¼‡W¼],ËWF ·M—)¥ÅÈá­A‹áàÊ–ĞGŒ=‘ï¡ )è±ŸË:H%X…hwZMA>üu…1j[\ş„»¯§X~RQFÃşV2‰¤†Õl8©Z€f¹yûLCjp'Êxw_ËeF c‹MRßĞ(é!(Ò¸yzå6¾å×WŠp}ÆúrÕx †$ĞƒÁ8=d	$G±5š	Ô›‡¿RDH±UŸ¦{×w¶Gm˜\‚ÿeŒM´ôÌ¿$:¾	_õ×MWô„6¢ˆ“g@±lÚ“sûƒ?8·ª³`8=k>QP9Ù¤F1qË0Ÿ£MÙ­[Rt=7Çã‘lº±KÆ»»4ğ÷7î¿P¹"Ò-ÒçÙ…©šËOşV‰¡—¾úk£Ø#Ùe„ätv7Ïü©Ê™(ÛÀŒâ;f"$‘bN÷Ú]«Ø›Ğo#a}MsîGiê¦×áê¾{²==ğ…ÒNvK¸Õ\ôt€‚œ:›BSJ%;fM|mÕag2è¼eæîØ¿k cU¶Ş¬è‹“Cò^ĞHÙ4 ù”LfÍö‰“’Cë’`Ò·´¸›GJbiF3©n¨7Îí¦Ãİ µëIöädÅG¡%ñÃgc^Å=lÜæ)It«¯¨œ bC}UÍi¶,m³°»„Sh£È)òŒ¬M c7§Ñe¨<ş}áKúƒQ¿®JäJïÖ‘ZÊQ‚İËÎU¨s:¸zÃÖXoÇH<˜èx%+YÎp”ö“Ÿ;nZ«³jPÜƒHFa¬z«æ‹â¶Øñ¦¦V^leh°pãÓ†óåĞ5.™z¶ÚŠ‰¢3ú†\,×Ì*>¿`Gà•~!yĞ°2ºÜOË”9Y¶€	½,\#„{µU<Îg»¾­>cğX±EÏıû¦=Å(Ÿ¨:ùIÕÁhæõ ˆb,ÁèÌã9¬µ/`eÚô;»­x.Z÷RV¤¼L–QvVâ¹lÔÌo` ô±ƒ5Ş-õüE
34ÂVITÍFµ6«¥Zcñ£eCøš0õûß°~ÍW¬Æ<&·0®À‹BM•GT1x¡Ó€³ü£R\qüxö$¥¥„òÓ/;™mWTt0ènTiz±EüvŸ$¬Æ–Qpéş{qHı–A.$!ã^VB<Ia@ó4v†©ÓLóèX2TÚBá!ÇKX8k’‹™Xgâ¨Ôfœ}Š¹…¿eBB8òÚì“jı£\N]ßó«;FÍÍ–óHöá%XhÄõ?Ö2±™C¿½z÷¾d	i<æ[1·8šÕ9_›\tøS.ZıŒz0Â”) ÚzïU:_»³1à¥KS‰úù¿ÿˆ$‹^0ùÇ\Ôİ[tõÒ~—> a>ø_ï:Ÿq£Ê>7©ş¶¹»½,1íä'@‘Ñ|§$pç%ÒçlÅ,n½S=+zrŠäûÙÄ
%àt}ãf„ğzbâò4+şÏˆ@ÉÓ3Ãtå,dòúÖ¥XP²mŠ!ôÛ¢+Æ¥E½‰Öœ£Š/‡.óe–Ÿ»ôâÀ¾5©î¬ú8§eIèhL´RYº”Ô÷H‚Å|–([uìµ~u
æNÙºKåV%>ƒCå–òÁ­ıá˜úšÙ>aâ;¶îŒ¨*è¢—4%L;à‹Ç½_é—\².×ğùr?Ğ¯ç2¡–àì1?ö'ÂDÍĞOğUÚ~à/×xÁÀyÄ]9[÷åDSk±o9Zï4ÑíÆä½!’(jÓK8Î”…¿•¿%L‘yÎ¶ÛÓ¿‰î¢Ô˜Vnó>êHĞ|h¢ÿƒO™[0fø[Êø°jîJE>»‹gıÜåáDr/G<k&8¶ ¾áGì“Sê´ÒÚò]âB–>&ÅîªCÊ‡¢’Hã¨!	m(;@,J:|Úö'˜Aløe<àÊ|ĞÒâ<;4Ö M?Èëx§úùbßÒh´ƒ¨ç=knÃX‘I<z:ÓOÑ×{+ÉO@q(\>Y‘Ÿñ¸÷‘DjêèÇ•/à
hé‹“L¼æn¥d'äP°¹¬ÓÃx!²¤ô¯no²r¸ÛõT½¤¯±e7qÅì/¯ˆw:k»dd˜Vóµı2…^Smædé‰x~Â–…­j™C»ğ,“¹°³][Ï}¢Æ`çú¦´»†;µŸİæ€¸­XEæœjşoñ%7”Ï»h¤¹pÒzGYiAÅVõÕ•ƒBO f§éñ¬~‹Ÿ¡a^ñ/â-yó€ÒV÷Áæ1&aœĞƒÌÛêDï^“ôDŠûwƒJ'¿#TY³J4:÷iø—q—öô—£ˆY?±íò`ÎİkP¸1)cw¾Måê^}ñh0ÈEDg!$ÚºP¼'VÔz-§ı-ØM¡ñÑ.^ùCûqÕ‡.h0ª˜8|G¡Â )àKYëRU¡L¹Kİb”»"™°0ğípPïø(Ê¸â‰gµP÷F/Ò¾Ü¦H7ZLxMË 5re‰‡ÓIÙ\’.ó`­EtŞªLo$0q”¯¨â®L6{•ÈãJb¶uÿgàœ2†Nz´ïz«Æÿ}ø«{/FHş©FŠÓ¿rä·LØ/c_ë›tSı€èwı©p±qÿñÛaªoxœ˜h™²f½¥W¯61Ø…ÚqGï4ııÀ+0ö;’Û Db;ù5
ÍÕó
ïÏ‡!ùiGÆq¾İ\<»a÷]o·¹œT:Nm.ÂìÿB{íİøÂ7€œW$ËfföÄ3Ò€ŸIò/©Öw­óøwâ,hjdEqC¶F†@<	íVó·ÏÚ$±ÚeÎûA“Û_ÚÂÅ´NÜ«…CüÁ¦sîvc¨H‚*PŞe•Œxõ’‚[ãS÷m|8ö¾Ï¢”ä´†ÏÀØ3šDÆÌïk0%¹Z™Ñ´şº’Õë[Øù8MxyÎ€#:eB‰IûÃj¨¦L=C3.Y¿ğAòº}Yù›p0!ô?ÛR{u—jÈ1&>g=g+ŞŸåˆi¯_—´ŒÁÁó”Í9|òR<‘#áA%WhÅ,–œf]P5º´½ö¶ƒ™^s"ÒBÏD³h¶ÁÏî7¶ÊYJ–2ã•à«q%j·/¾à5ÒÊØp©Ğs)4³øM>hlb<ÏsÉŠÓ·Ÿ$&óô	ÃlÚ»åy.À¸,ic•ßvçnĞo3u¦ŠÔ’)¿'5iùB<«Ë ó¬p3)(Nİ5º”å‘šŞÏë®¬%è8Æ!Ğ°È,ÓÏíYäeã@´½0¤?Í–½ÚsÒ²- Çj)@Ï“‚±qiÓ ÏÁq¹ïÊ¬^oäÓ@óaÁ÷ïfçlhWªÙéÉş æŒŸ'—6Á"UÊ´»*0Õ+òET:€lVâ.q~Û•u¸°<PÌñ¤£bÚ§0+<õ3a«lS%Â¿h¦“8a,lˆÙ`Gi8ni‹F@yaÆ‡…ù P“'¾Ï‚Ñ‚AçÆx&mN†	.ü®^û“‘ôf‹›‰æß[ìÇ´D+àÆÆ&‹cÕdª+Î<µ Ö„ÀU»ŠüîFA¼&Bi‡·3PO¨xÃZxîİák‘|«·î&ŒŠèî-¾•©¬\Hÿhó‚d™_$œdHK¾šnkx©hç-Å
LY¢)€|šÀ¡¯»@ø(Òk‚õ•T©šÌ´úu“”SŸL|¥f 4ÿwÙk“Ùq«Æ÷fSh)]‹¯ƒFÚ FrŞ¤Çâ)1Â°™ˆåc‹©zçŠa¯íbÅ¶¥µ3»¢,à5ÇN{ô˜ÿÉ<ÒUZéhU®ƒŸÆ‚vÑ¦êâp-àÊDi!ùÀ)ŠãöçT´j©+Á”fpÎ%êñÄÉZG}t•Jö5Ñ$/Jº¿E|û)e0FpOZöG£‚ÁbÖ¸°JÑÁH@ã ¼¿	¶}ôÓß|á¥¾2¡-û÷#ÌÇËtã9·EÍD.»=ƒ„°ÍaÛA²CiGXp:A Àƒ«fİŸş	2)¬ôŠı|‹ıái…âºÈ£Ÿ“˜Pƒ
èèÚ5)Ñ¾µQé®	rhÕM0ïŞvP@ÊÒMÕG'á’Š&!§\úÇHÚúˆ,tÑHsQ}€ÚıY±J;ä"<~zVdfòhUşÿuğ··¤Ä¬õeÊäÒí[n!;dvƒò~–+ú	!¯Ëùãğ6Ld*ªıR
I+€Ô¸?ôÍŸ£ÖÌV<{eÒ¨œí	ßÅÄqŞ#^ëˆ¸ºãEk²P§
¸OcáZÂ¨_Ğ>z†¾ÉëeƒªÚ¾ŒÈAŠÖAª´»Ùm.ÍFjåÕ±SCİsW|ñwŸXBN!oÙ/O£ÅieÓÖ ³H¢5—¯E=;†368HÉŸ°ã?­êÅºüäŠ§½×ŞüZÿ{ÎÔø}èoGã¬éê®°ÏúŞ®ÿÂó+1J¬€¯JøqŒ0/¥Û/²~Æi._c¡¤åX_ğeòƒÍ}à—ì9aÁ¬3ì¤’}®aG¢Âä1k²"GõÎU?,`á~¡-îüåå¡å‹®I_Æˆ[>8f ƒÛX2 Y ÙBÂ/OİóëtO•1 q”µWû0q‚ä‘U¾v†Y 8Å­e"ş‚ËAõÄ‹’,¥ry>}ş$«°'Pö&Á®nW£T¤a ®mß³•é€ù¿ìªáƒ·{Şõ÷`Á†ëŞl§Rƒ×h´{ZXJ3¨ûUM'ùc=l/I¼iëª¿ò!^‰Ç™¬\­n-®ÁÙŒ£ Â\ñe… ïƒïèµÎÜ¸WW’}~½ƒ5%sêälëÎ\¦|«€9áÀçFºşğ÷ÍOŠ`=¾wãëºf€pÙ—'r²eæ¨[YöµfZi“Kÿ}0«uğÜ áâC ÿN‰C{ŒŠ»ë¨şª[‹¯4[£¤„İ_ÓÂÔÎ­Í\2¥Ë•˜ØI>áü.µ¨|.nr˜ÅY^Ñz}(r(Mf¼œ±³6:¼üĞKP{ksàAÔÁû¤O:5ÿ ß6A­‰O©¢Óâ3À”îu/ÁSö:ü4[ó_¬gØ:ß#6”p¹şBŸÜÑÜÓ£#d¼jYUµ.cƒ-kt¢x²~Ú—_Ór_¦×ò˜déóE˜/ğÍM‚Yä×*éÿ¬Ê$é‡»ä-3Êï‰WöäßÚÚIÃç›6½f9&•Ñùf|¶ó‚eëG/²ÌüK=¼™'æfœÕ`µé”Êå#;¯1Ì¢îî»@•˜ÌŒRw›í†ÙÙvJƒmÊ*Ú‰3FÕŸY* ™Ô‡ùıµÎ)Aœ–¢Î«äJÖ“«SQ4a†nITìÈKæŠıq‰5 93ëj	‘Ö-µøÇ£f DÕskLÓ]d–¥¬>^ÈéH•Âtëjo3dµ –€;VØx­–	e·ò/Ç¿‡k¶!?’ƒü±t¢5ß>¯=¾
ôL~ië°·)o`6XFä² uÁ’—”`T^~‚Wg[ôËJ²ı’—3M]‰\ş½kKôWòPœºv%gÌk]Döš1ÔèÁõÅ™Õêê
^tÄIê./1q–¶
#g@½¿ŒšğÕâªıµ…Õ}÷_Û'Q| úÁûT×Å›eX³–S»’lò?Şµ¹DÌš×Ÿúà;kBvOÈ-fBYÎÙ\á·<ëå´šæCØ†zãÒ{ÎÚˆ1Ğå‰µ¡™¤EKw‹`cşû¡š)°R(4+U2Wh¯j¿{’É˜ Cı'í˜ºà:óÿJú	#È+YmĞq=?ı¯Ä3—~Ç·Xô¤û-í–›Å"ŠÄ?xD„àsêd¶Ï>k/ ‰%9uğQT¿÷/L­Sı¹€·IÅEÒì&üUQB%5µÌİŒ›Í¹°5—½GüäÑ¦\Í-UÛ
äâ×ASğ  l¹³‚À	l-Ñ¤„q¶MF¿„!5‡g8µÒãE\XJË+/%äÑÀé¦Ê^³
ğ;<4•1ÿÒ"¬#¨rï>¦ZÃ‡.™-Fn@0BÏ‚ ´ö¦‘-ÑƒàXÇfÅ‘G³^ä±÷{dß8ôªÂjPĞµù^xK;ö›i:Û-Ü†«ı.8tH¦ô+Ax¢sÖı'*+:¥%¨©Ipi’Ø,?uÄa¶ä_ï dálÖ_ª¦Ãccrt³–ù„ô¡nÜŠyŠıèıühg®y
·;KëˆöeBÎî%%â$v4³²TÍ³H ™§·şË“_ıQR
½š§#JÏU®93ì÷WÉÆŒIÙ¾UßB‹¿¡ˆñsB\a“pdRxÒQê9n$Pœ€f#Ü<$Óşd³5Ëî5¦Ò0å)Œt@¯¿‘ÇŒ™·3ÇÉOf½ƒº½ ‘*)Nşªó¥1tÑ•#?#Ë O±Ğ×Á	Íñ+<úCfCşSf³ª£t¿'iê¦7–-ØcÆë¼¬"  &êr…Qp_ô,WnY¼Â9	Ğ:ôQRD¨¢Z«Uª§OßY@ıÊãÎ8İå	?^<º±iQVwA»ÏÅbëº:ß‹¿Óóé-š÷YÃ^gtTª£¯EôûŞ¢ËGğCßÁH+–4Û³¢SO¡z€òQ•Õ}…íuÆÁ?H×ÊÜÉ¨Ç¦%å‰ç?¸sv¥ÇÖmR¿ğÆNE’É÷‡|[|º,‡VÅ]C^•½‡µèqáÓ%§g2ÂÆƒò"lwN0÷Xn ô:Œ$e+pEr{}³_Ô{+W,úU.?ŞHy˜8FuAl[iµà†–Î)3I”YiÚgqğô
jñûé^_ÚUµş
V^|±*@ŸË¯5«8gÉRV¿²ê@™©´îÁu	5r©ÉÎr­mòÍÀHÏyD=1Ô1ûmC0WÊ,	ş‹ìLêÜj% Ã%”ÚéÜL‡Úº†Ü–Ä3RX[Ë¸s(:|A>Íqœøöˆ¬h	 gFÕa·±Zuk,@(ÚUÃü.ƒ-R€4ûªX¾‚QåŠÕâRÉ ¤cÇÿÒYnø†N­’ÃŒˆàl	ô~ô)2ëZª²¿‘‘°Çñb\Ì?ùhšÌgÁyq+èzÙÌÍÉGñ4à@<B-#×c¤b›j:W›tœ'XÎ4º¯6Êdüæ0 $Ğğm€}bÅ} ?vk‰ã%Ë)úTv¼\CØV£a–mŠÚ66]Â=y%óñiZoáÒ †–¸¶)j	Àï·—g	5?³Á©®¥©Àö
]óÅÛhj…W&ZtŠÓrÅA	z‚XÙ.J×K–DN£h…EXÖb^A½ºÌSäùè­Ğ÷ëDÂn»i÷Š”»‡îtUÇ=)€áWÌL®XŒêŸ56(çŠÇÑ½Ğµ)lj4ê‘m<¦påuG¸Yd.2tÂæ7âÂ¼mLè–¸ï¶¸‹G1õz²­nşüôªöN‹;‰	 ø\#Æm7¯¹ûÄxJ3+Ø_Œ‰p;%ÙşdJ5íY•&Ö\É!h§ÏC¶'!Ã½xIòªIã›6jÙ{y.—Ñ¿ÔPäö—ug¯Xn,ãJ´§4ñºı´şÙÊ¬{9jF¤Z0(ë8Ğ%9â7œ1j}ª!@lªX¿.DOÔßıl	Jş±c?QÄGaZÚvÉâó¦~M=Çr
S³Lòºâ À„ÄşˆÃtB£4ËÚj[DŸ³ TC•BMN5§¯:…jwz7-r¥Vb…Œ[ÜˆPÔ£‚}27ºk¤„;+lìà"–ùìePúâNL á> ‹úíğæëï®1İwğ7Æœ7.íÅXX«RìÈŞøÎPÀòò)_cš¤tN¾á§Æ¾c®WZfsÅú:º¤„}!BÜ¢òÌ§›·rÆèaI×¡˜^‡cTÓ[‡Y•Òç}\ë=[ôÍƒ?réŞ[*#(¢ºkñïã1u€g­U8mô;.8b	b2nşo—»\rqT¤
jÁ…ŞêàpA'0Z|‘s†vø~Wà¬Ü©`©~˜_Äò0{u€«m²É¤]-BÁ¢à¾’´ËÑ¡ù—hßN¡eÏ¥öê~"Å	ÕéY¹v¹]\ıµë™ešÙ?ÌŞ"ù¤ÿn¦Áøu¾¡…Õ>S/®ï.ˆ7KQ×Òßdãöc ÇlëR ğ˜ƒ2…¥ÈÚ0KKßAˆ¬g‰§–s¦»Yvl¤^~>5h¯ğòm‡ün‘ÃÀÜ·k®È-‹¬ËbRÁlÊ¬CxºÒ‰¯ââ	sü*?j‡!-”q,ó›xp_ÄŠ
™¾É›	6=¤ N¤öÍ(²m~š@=P¾›B…Ì:Ç´=”¦FR¦‹&gclk4¸'º]0ªÙO·Uwaë¥€Ş>Ó¾Fi™•ªù;2¢x|ŠÁÂˆsC
[RñKe*µ‡+¿ü
^8•~|mªšîÉº¬l|€~ÁÆg¥ô³‰C“¹˜Oæ³—[º#{(<×2MŠŒVòÓ$¦e˜1v1ª-âk^VûMŠ©äí¥kÌú 9¿%‡¾WTJ5ğ1%zMÀ)MõK+´½3 máî;ÑºÓ4z÷ó“EQ$
*9?½Qó¡ÆèRtüä¯¥˜u5S¾š§º®¹‹ĞcŞ˜Â9ûZOW_KªjIî¦õ:Üj—Ì÷¤„/} œÿTl&±O+/y#Z'*¢PÓèõ«…q^	¬šnÅÃá†«ÏLÅhµ9±p4MbçÀè9šI,)]£!Ä9 ì.bb¯J;X¡(RæÚ5§“®X[nH’/Ï*üf%{"H‰A-•óhGÌTÊ6ÎàİBŸyRIAìjû×4töl#¨V{7ã×S k0(NTIXƒİÔ”<7	ñ¢á w9òz*{äÅ{?¾›%?JQßàoÒz4›/S;DtVP¨…ÈjEğ3ƒşsu¼ø§J>¿ÂQ8 RÏwÌğ •ùë)g¼–BSGØ·ƒ˜ŒÚX­¿C–®‰z„ƒûÓÚ cíX´€ÏhÈÛ¨›½e¦´”LöÚê¿×(D)æ†Æ_Çˆ3WàäµKjŒÒFÃ£½‹§uÕ|GákMu¯áDY"³h™…ätœí©ÄSyR8€Jf!FA9ÂÚÄ™ã|™´yNb'/dYØ[ÀF¾%ªàĞõ~å„(b®däÓz±:¹ïÚ©}µE‰%õ–óØ¹å-7gÀõù‰ğ±ıã§d‘7Uğ?‹%©Ã	œÆŒ£3O?¬ÿÒ»1„áÃî¿—¤Z·áveÓ±u_ÈlF2!/x9üåy§x¯–×aÈÛC=äã™Sb×+`…ı5Æ»è˜U%8?¢©‰’Á³i
 €^©Kk‘%™kdm•¶3éz¦ä<®·˜DrşgÙ
ÁÿB³lÛ`}¦Ãá#ëcL Ì$ÌQ“'Ö`™<aJxº²i!nuÊ%j=/äÅ‚š¯5Biw»§éóDk¢jÑ‰[m!?R·È¾FAµÍÏrİš+±¹·ÈJ®,„ví^?0äò0@„ÎùbÛÃR{îq~$‘2E˜¿º³æ·¢OHŒ¦h­?ŒO¤MK®±ïõıÃE¡éŒçN{‚¾
6.à)"ÆÕHÌ0»ù´Kºfã©ÍDÏü­VÙ®¢äkÅÑÁò_0KºÊ<¹D½<^£š+6™<×X¿sM™9r$óHË˜5•iqŸ9ÌAÏâœ¯Â×)ÊµW¤Ñ]¾CÒ/r¹ïàósg¦šâŠ±¹mİ|“·{<PÏ‘´aÚS=·ò7š&Öå®õ†·YÚ.$ÁFB 2áñÿÁİŞ&t&@Ü¤fì\µÜ¨°¨ğÌe¬ ·”?Mn\Î”;"QîËŠ)/yş“K3¹Êš.O‘jj>‡,­è†?öœd|ã5JlÊQ9¼­çİ6,}pÜúCyXB8ë´ïÑ„¯¹Ãc nN_®Ş¹Ãökh\İOî:ºD‘ØÎ«³YÍ™Axš-áHHŞ§P%u¤ş†k1ZfÒÔG¦:EÕZF#;Å ÌNz_C×‚Ût­‹´Tß(i+€,º/Aµ:í‡ÜsgL{À@cÑÔ)´¹0phI9øûïšzd—DÅÃd±³ 7gãÀ%Ş9VóibœĞÿ2Û÷òuM¡Xv#J]å.Ò·’çAÆİˆÛË×mµ“Òo›][›2"ƒÃdÉˆ«û(;|°ïHı§4üü£ÿã~ªib×(ãŒHÓÕ£ 6ˆ´ñÙÍm:çœèíÕÜ{™‘É4ãÓ¥c¸0ê'Rõ9=3µŞ®ûn¨/§Şô|)utÏsF:®R¾¿vB$Nã†è%†{%
X„¶ì¼„>`µ¤™†R¹Š"=ÀºL¨¾œ¡ÑKSµ}i\ÖVÉöb '¨PçŸ*ÅÄr8Ò€¶=Ç{½Å?ô¢³5”’†
°F/¡ÌÔæbíÊ£†`_‚¶ö‚îÒ”.´ñÒú’hÊ¬›±,ş½áÛšéÿÁ‚AçmŒ@yA'£D]à:9â>Di…¸À>/[Ú!¼sÅMï×’„CQ&ÿ	š
g~TC—»åş ´H…|?Œ>ÍüOŸÊ‰á+%ÕêLSÀ³>´ÈÜó!ŒR˜£*³”\´,Q–v×$Â…ÚëS6ë>=•×Lgõ9™›ô½Ñ·’Ôºõi}9«–¦Ÿ2D‘`„½Ö Ğ«~¹L.­ É€w˜ğÇ¨ğ”ø×_Ô˜Ì|íõouÍ å.¸ü<ÿÂƒ‘ğ¼å;"áµòÚº’ÿÊ*î™0Mt*ÛNh…³S?ü¿ª.5)rÔÔ
!v“U“6xØ~ÇfŞ˜H*Â½ 2Ä± Öcmjå%bæ 4½n‡ˆ:½µÁwÜTàè®3Ó¬¾ş¦ [å¹Ë—ß”6¦Î.İ8âJä§Ñeˆ“0EF›h&–å¨ı;¾)g£¦òSägjQ9ŸhÈ¶¾äi¼Ë/Ÿ$‰Z>ç¯l<ş¡vz]—ê¬‚º˜ê=ÁK=EÏä,—½Q@OÊ³ÆÍ¿û§‚ÏÃBü»ËèQÜ#á[L~^¿ÄNšëJlOpKÂhÌ•ZçºmÄÑj„‰7gE°tr¶Šæë6âk< ¿BEz³ß£¤éÑ÷(šÕËåŸ/˜‚Ùä J‘·ÿŸŒtûècİùº–ã¶‘ÅÃ#ëÕwb¸÷£8QFUŒµt£DES¶cAgc#†vÙ•/ÑeÄú0j¼7¬ĞAL‚ïjî?lçß\ ¬º[ÏŸŒÎZ€T`ñìø¼ÊÔ/£FûÓM”Ê¹"i*Ú¨õ®`-'
ï8ë¿gªœ´{}k'M‰½:€>GÁúb–‚…³°]¨Ìu¤»¹¼ÕÒ,ğ’Ü Ç_‡(o\$äHßMÑ.¼r«)œï¦}ı’Øæ³ŠŠÓœlW•F´¡O%[ Tı1–ãÊß§tï%¥"Çi)®¸î[3.D,áFŸËñzé‹—_yÛßÖ>–Š›r­cñ`A|¦¸nÇ¾'Ÿ›N¹óOÈ£sËòuMS„ã w«%İQà½ÉãÉ†áèoÏ®Ÿ¢Íj\„_ü	®FF¦E1m…B‰(˜5ÕDwÖ]"øg_c-eæ5ÈŸkz¼fe^§/¦—£3ıèI˜™Ñ@ş«™´2z¸sU¼ª´ùóû_u!JYÂ%L0rjÅ^uyDƒ…y Ÿ®&é(ì‡9g¨,Z§V‘fKsq–ÈU€e¤Çæ2Mœ31¾¹;ï^sø5ò4nî^éÙ¼¹Ä¯“g2j­ğÜ}yh¼}À‹;m”K–ü»{ÆŒÏ»Fq&¿w"}&Ù¹KH†İhq‘I‹»#Ù…ÿ±È*®Ÿoš+ÀéAEÚf?¨wg1¨>|ı¯%çrÄ=Øàƒ{ñ’Û½ß	ŞBîq}&µr¹X°ÍlÜ¿ÑW[©"œô¿›w¤§Ñp‡~M6’u7®s’å•äØ³ƒ®®0 ¿tw¡‡h)™GC²YX=»Ü®ús¡³Nr"`/sıòBœ7S<®æ¡ÏGé CWê[›¶rtbú'pìxx‡äU}zÒãç|ó!…Áã„U›öÄgÉÀ_I.hÒØ(åÌ*7éµ%(Eu¦ëXµŸëu¸Âİ„DM¬a²ı_ú/ë¾7¾Ö!!ËÚf•»ĞKƒú1´¡ª{˜	2ñªœCÓïß }‰ş¶gö¹wÑ¶Ê?ÕÀ»nc²‘Qrèş½æ”[ÊÊ]?/â°†—œc|>X¦×2®æOj7™6×-#Z,Çîî) òµòâÉås]¡mÃ/åõHòbs£oe×ğÂŸ‡Í÷wÿ†ñûeUœ›‘É.½g÷iî³ï À÷:şÍàÌeÅàõÿî 0;\d[Úo÷‘¸æYÕåïêr9ÓtÑ ‡xkcÿšPk¶ËÌr¨p”z
ìÊÁ2à	«)»mòÅNS‡o1Ç!Uím^xb6áíB°`“iµ‹[‹F¡á`\Õ³z©`úæ³¦ÍË¾ä 'WpøĞÁ©µIıæK£‡Ó Ïî£1Î|ë–õÂãD¿[ğÎèĞ4lMèë…[?»?>>Lú
	wõw3­_e~Sû%?ÒÓĞw;AaS=ÎÉ(ôÍÈ–Vèp«üìíåfö¥Ÿğw!‡¦{±êp„Ü0T¸QGÊƒ±Y¥rƒĞl×r|ñ8ìÈg5¢°£pDö¤Ã¨‚§şxúq¬\íèëÄzEü²K (œ-¦w¼ñĞÒíHdş½"y#_²>Ê$xyM.¬¶oÂùû>åÆHëA†`æù‚­¥ıväMŞìÛcÃêï!ÁáçÄ:ù.BÏ–'„¤xÃÙsÜ“#õ3H¶õB©—t=î³bD+_—¥ƒDÏ`\q;:Ñ(Ò.å÷ßUŒPœhÃW0Š÷}]õ­|/´zÔ_çáĞŒ­ä<äÈzlL)ÂÎ¶¦ÜajçÅK' åÛ£$Ô¤/7ÖNB<‰ÓÑ;Øñt¨›*5ç)Íh*ÌÖ™R®'úÇİøˆxG6?ø*ÇüĞ«‡@R¡–f¨¢dC–.Æ÷øÌH¦ºl­~ç°"`0QC¸$ÙÏÈ‚<¡ NË¡Ê,¨.CÃ^¶%Œï×g…q\3¾„¹ÎaR²öcQ¿${V»%HµE3Cä7Ò{Á°ÖiÆ¤½ÄÙÈb^˜F¶e]¢Ğª—ˆq5EvÕg&ËÛÇ‹ŒzÖè,t¢G•
ò/ÈyEP'é5v¥ÌÊ›Í–¦+aÏLQ}Øb›! ŸóÒ¬Âà’!ÚF?b(«æ	@I
27\2=™1:&-§¬ÕæË3è=h?½L¼®PšôD ®1ö¢~ ÷$ÊŒÌ11Œó» 4§õr¥ÖOˆùãïS&í†#=ò»–aµ]Ñ*%a½8Ñ+ÌzR<¢74>ÌG&«›
†«PZL]éì¹E:·	§"“r¯¹U×Ziò‰8SUŸFÂ³·¤ÑQ!À‚vôÔ¤ÎÑ ¡WEp…KÉ‡€uĞŸË¥"E¢`¤%“Q	7»•×$îVpÇ·•
î¢fnÊ)ím–´
ùùx/Š{0NíÏDeïÿ*$#WàlRøÄmóO¬şÂËí›b´š©›ùÕ¹/Z1¢ùs|#˜uCÿA%vfüi„±òçæöx¹…™i3.3ÎÑ—äÆ¿Iû™Ô<ÌècÁŸ¦‹NØ2±6TƒµÎˆm¹}("Áä#ŒóH SÚ“¤¥ƒÄĞ5\øsi²1ªe\Íw ÷^W6´ñüzŒù{Œ¸´á$C·Ü6=1hf·qKAÅH£¤ÜÙ"¦s¯ÔXìY4ñ}*(RÙğ¤¿Xh)dıp w@î§ï„$-™>[šºg>HÖlu‡ZÃòït.B¼‰^2HÏ˜ŞdÍõ!¼YÆ¹šà@øàìóU´Ã©d·†M1+$B#‘YÅQ;j‹É8}ˆ‹/–@–iº™ ¥¶ÑÎ¼±‰ÙjÑ„¦’ÿW…IàŞq°ÚÄü±Y2¹qqDa¼¼fû­§dS‹‚s§¼<ÅıĞ¯-ÚNH,{jL· w}íí +>c ½1Z{ìª’¯óF¾¾ˆ<¸:_»=÷ $r²È)6HÍîZÙ^Kš²Ã8[Â´Àr%ÿ³S#¡Pˆ7eO0?Ø[ŒIS* æŸHµ¹5Ü«;Ÿ¾`,ö§4¹[S<)º­kŒ¨z®pà`8/—zx"«gõCÉz0¯8?>nm˜tÁÉ«ß@_oe|<ZTyıÓ+$Öúç×^Sº Q/ÃSv«E†˜ìT¿á²£ˆª†…s¢ÌÛæ²¤Ïz¨ÕCH@Œß~W¬T&y9ıÈöì‘£Õ«ªhmJĞŞBåìZ^öAÁ‹‚ÅÒ™]¸_–Bu×zÄ|øn9»“ŞÍcò×ü‚Ù$GyŞ~ÑwÛEWùg/+¥‡°Aç3Æ¶Ã¡=}KŠÀüCñ^^iÈ#øNGh^úïI‹ØcfW¨ää*¶(ºÃEz^¸ûŞad¿©vXÂh`ì¡ıF*ÍHšÏ7ğš0föÄî+	G3«»C¢OÏÒ¦ÈwtŠ$plùıÙÜ§>t¸\ª\±‹ü/Ğ¡[(ËrÜåÂ§,šÕ™Ğä×ïÍ÷5ú{[ß$¥çöÔÙ1	ãórÔ2ß&©TY¿Ô&nšnké%£òıÜ·öËrõÍêàHµœ¤ÙCÛùÊ7õÎÖ‘ÈĞËov²7çPWugoAKUXy
ñŞä¥9“ÈÚëæò¼¦&OãU{”úÙÿ`Ë‚eD‰±-İà¤Ä‚~ƒqîuqÓ5Õ¤9q#4…~¢ÆÿËu¡–Š¸‡)ª*gä¨$ûy+
ì˜àó53Ë/ğëp£å{8¶²y!…ğrWãb×xF#x &2åoC'EH­?o†=ö¢ÌÕIÑ]·<ÛkLÕ´†®ÿÙtRÆ£ë]ò8"ˆ`œ=Å!í„m«ÃÃcùÈVJÃ2§vH°ZRñëµş(—]ÚÜhå²8ë„çJ!Š94P†ÉlÊ«-<o„€t.í?¯bàKˆÒm”‚ò¡ïÜpwšÈáhı€ù'F	=à½Ñ¬’K.Û§Ñp¡GkÛb”ákæÀ
ûÙÓ€
~çùÌšw†”ÿA½
Š³šfÇ8¢úÚœ*TRş™ xÎ0"`›ßôô§Ÿ ª^:Û4ÖÇ“‘.ÿıá“:UßÖ2¿p‘K.ü¸NºĞ~¦—š–{La 82%ŠZ¾ßa2zt˜"–D`†Õ%œP+,ˆiÖ¤é¥¥8®òa8bğRRè­·¬ÃI¹{O»¾Ÿ“¤ç¯
H´²ë€½šwBıT‡ˆş)Î'ğ#ÕÿíÕ±¬Fçávª¥ª#•‰yÓºY?ğ{9¿¤‰-±1’wîßg€)g9·—Ü)x lPÈÜKfñrø#¾Íü™ÇÉ”~ÿÚÂ÷*H0ØÓqORF»¦Ù+…¶û!K   C’à±°— ²°€ğÚVÆ ±Ägû    YZ