#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="8328348"
MD5="6c5d94731c3221ce8c15f965cc13f03c"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26036"
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
	echo Date of packaging: Thu Jan 27 15:37:45 -03 2022
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
ı7zXZ  æÖ´F !   ÏXÌâÿet] ¼}•À1Dd]‡Á›PætİFĞÔ¦	™Ô´Ú¼€Ëöİcî–=É”Ñ¬Ù)š%¬˜íÒµy‡Æ¹—Xş«Û«4ç5ãw¥®—A„çS~Órpïm("ç¬ò‹2	UÚ«w‚ßS<2á#{gøÂZ±ƒTÀ³aRè½ÁÁîÂC¢~|)7Éû@ù¨M¤û.å(Yì#r±ËıKV­f¿²0/H¯ÖyåE¶±¿¬ |íÉÕ$Â‹á€yĞÃ³ ôñ©¨œ±B†7{Ô¤õù&ˆ‡àû”'¦¹ÓœIq’i¢±oÍúódû“İÓ’²Ì-¤L­@Vi
]â—æ–¸i(z~µ0ûs¸Òd…v¾ Un.‹¾E¢{êt}MPl|½J|ûW¼RÃ¨ñ¦gv(³ù9=Şÿ‚šº¿bËg±
d×[ W*É_x°¯PÖ^däğ¢‹5åCıRgµæç¤ğş½_SÈ‹á¢0ÆiùÓíbùC‹•$9[Ëàú²‚}úß³«òƒäÌuùé¶-«˜šùÌÖĞĞvª3	 s´¸]Ÿ[îò¿wD±õ¯…|?a°¸á(E”ÜP0?fñGr‰peüUƒ;,¥ŒàX‡V$¢Â b]£aõY¤´º*ë#ˆ¼ÊûnÌ@µ}ÊóÈ\yøÍz¶F_Æ$r|K¡!ıÂÑ;y/ëñQÚËnn†Xë‘ğ§·g%§ƒŞåéÒiˆb‚ölÕ§²%X÷å<aM7Sã`3üJ“¡îö-:@÷=YmFùüºÃXÌ˜Šín—ìeYSô¼ı-“–_nÈ5|3Ê§®ÊvÆ÷pX*^D:7»¢UŞ˜3’°<
z	Œ[h~zøÚ–HìWUÍƒIFŠlº•LVª¨˜peèbÙ -Ê”ÈÿâŞQÈ”
ƒfOÔULÄBş|a'
{ƒ›©·,9?k½ ›íÕË5/j#	NE >s²!ü<£w0Şã=%K)ÉÈ3ÇZzB(¾µejÈ˜¦¡°:Ô¼ãh±ã*ÌVtŸQ¨aùaX¾g²N23¨•ÕKó¹ß}¹väı£ŒÑb‹İ1åBî±ß3´ì‘aŒ)—µtŒZH#¨¦¦B… Q»iéè­f<ÒÊg«
XàÂÅÉœ$_›OüPÊxC!
/Î”tVùñ16¿{8ÆĞ?V;3MpJšLµ”eé­oã˜Ò—àêò©A®›¿”…@Té‡¥c4-ëváqÏVóØycR,ëÀöj)í5Ù´6“üVÈ™ÆOØª›°weªŠiñøugßSÖÖÅÑÕÎt¼‰‹®|NÑÄÂ:h»zZƒödóëDùñ§{ÚøZ©¥¥!j:K™Û­X5Ëq=NhUÛã°Ûæ>Øláv	0Ñ²5YO.ÿ}…½Èî!<òğ‹xn
o¬&°™U2ÿ±Æj§	ãü¡ß©Ü²D-'ëtP$R+4³ğ…6&“ÚÚïgQp“DiÂùjü4LÚ"j/q¼ˆÊc#ïåÓfûù÷¼Û€k—Ã±ã>»Û+?c'p‹ù¹ê|	sÊ…%gõx›‚|ÙswP§şÄT³0V™®Œ§Ûİ3ï‡¡ã>z°…2E…Ã0³
‡İ©Ğ„¬uÆLUZ°¢Nmd}]–ÛÓ’«4ú©lÓıÌ·VtàÏQ®ùÑÆòe;µéÆ¬/VÒ‹fUÈ	V7¹—¿Û˜åEe8Ë2˜7d‚‘,V¹4](v[ˆö¦'`ÖæFheS7Ó9^t3:µ@ø”Vı‚l,TaF%¡{º37>×ë™ÚuRšmèiC|®‘ŞŠ-óÑ³Îœ¬$¼ ˆh]G“VÌòØµfSÂëˆØ	„/yû~&*‰××Øë(ÏÑ±sİ RV¢ÓëßB„õÙ%ğ!YKú~)×FÊÎÃ‚yZ¢*àİdÛJTh‚,ù÷_ªqó©P•§“íè"ˆ%¡ï; ƒ±/AN¡ä¤->E‘ë&iYg®¹ÇS,¦¡{?$$+#!G”¯É‡kh^õ‘èÇWvy±·Hn+ìôß{'rc ˆâ'îœAûxİä¸µiú2ºâ°Ãºt?Äßy- `Ïã*½rÔ;.]‡nzÖ/¡ÍÆéM `+óD÷·2@ËIL3 ¶Ñz(ùöâºÕXß©Ğa™=¹±ÌñWÌ~§åx\™‘ä6öY.àú½·XO@†.+½7½agx2IĞ7÷K©Mw­õG|‚tØr(¨Á«Õ“Ácpj€Š>)8]?×¯:-Õ9–.â€típÇé=G¯*Ï³¼KÕœ$Ó‹z :OXkÆ¬õ”Â„–Ù!‡5èõ÷ƒüI²±i=E©æò»nŞ`»ù
q’eòØ&]Ó&‘*+ BîT=Z$¡¢§ãS–Ì_VãBì†{Ğ	¿†ß,/–ô½-]t…íf’•ø´3h+¬£]š«£” —§Œ%!'UÖsr¸“g»øO;&3yÿº¼Yº>*U=k¨=‘³&ıÜ.k8§©ûWÚ’J—Œİ•s•¶yAâ7@µM„s*åilv¥–²£ûÁôIµK…¹fæMf7jQo¹[èo‡+†Ö¹f}<|"Søäù7U{“8T—@B¯Ô @0Q5 &´@yÍâG¡ç;­=_õ>æˆK¼i]8«>»-€J¨ïÀv›‘èå©vıTDVÍllKÍª¬ßËş¢Ùœ„Ë \ŞGò‰b"ß‹#a€0!s‹’Øgh-6D‘‘YP¸G¢–:¢÷ ÄMäÊ-g_“åìÌ#%cS…ÄceÄ°q§ºbÇµèôÏ_ùÄlçKÁ5+ç.ñæK^Òõ¿ÖšÛéÆÈ"¶;ÛŠO8gÈ>~ƒqxh¨Lã«·'õ|bP$K_¸fÆ²tÃa*‹.Ñğ¯3€`+)IéæFŠ]õöJÃ.ûê2³#/[[T~øHì3bµ¡z×©²2Rzeä;ÚŒ3ˆg,5NÍ¿° LWXUÄ	«ìPw·°üÀÕO{håÂa”Â0Õå³˜áÍ`?û¡ÈsÔ6DgQhŸQ/¦¾te–õÁ‹†,ŞE%ò|P°ƒæ˜1DÁlÁ’Æ’Ç¢QF²¨íäI‡A¼s¨%êÇüıoûÖ…ZÓFŸ9j'~ñ„W•hT“Ût˜±û¶_%ú¸,"gˆâÂbZÿŒ]_é+·	Ã—@qùN¸á©°ºš%û{æÁİxÍ”æàmáåX•9sõ“–nâÿ!m
p>y¸ø¤›=C&¨çÑ¬ŸHkX«ñ0k˜Øx¡0Kj˜õ åû0–9XÊ‡&»“Eå€‚€?qÈË
Eä9HËÿVêÀÅ…2l–Éùå~a*T&’œÜeqØøÕéi3a[™¬=v‡³?@uµ‰«ï K•¢dÍÜí¬d#à÷á¼`†Ğ¿t"ºXÙLÖ’4»Ô.|Ååòèú$ş¯VÍe0É„EƒXÿ'%ÁâYÙ=ÿ&‚3`ªëZ/1¢³
İ;© â¿]´)èÇw˜ó—Ó‚ç.©[òĞ s±‡Á3äÿoø´€-„N²# ®½"‰>CúP‘x·28_úeD\!Z²A €ßPe3fËcUÅ{bù:æ¼)¡BaÛw†Ö¤L	7¿N®'9p¹£ñŒNïõõ,æFü
BY™•l;ùq}²‚Õ‹¥ŠU^®ôƒ«ÁšµìºĞ­³D½‰ô]¡Š[ò‚ãÑÜ×_“Áè¿#c€¢]˜´âÿXIãˆ¨&Ÿğ õÉ`nTlª;Û6W7‡9œ!—n!¤_
¾¤Ÿ+Î™AcûZ4‰ñ!—lÄ™^I=¸ƒOŸTqçZohQˆ-X"¡$ÕDjúqŞ À¯jû ŒXx£•Q9€§	Ç’wÊLŠæ–qf?îN¾]è“İH‰œØÛÂ‰4jƒÚ.¿±š±@cuÈĞâo¡Ä°õf])ÿIíöx…'ñÙèÏuÙ€'óÏ´ç®}9#¸f”À¤šûG%uãÊËÌÜc2I6èxø†v@€‘­6Inaq;Ü…k³Wİ8ÁÁÌéË2¸(ŸùÆPï|:{$C˜©òÑ—h
Xûh9Ø¯óıè‚ü<¦ähŞ»&Í­§ÎX6€Z:MËïÍ:ä¼=2öú|YEDå*Î2¥¥‰¡öOE”©ëãµˆç¶ÊdnWÇw°qœ´/ÂfÕŞuA=Üû€‹CPº—@Ö0:ïĞŠw—ÓÄ©İ~I:z†Üò2…d?‚1RôQ #u­RHGR:Z;ÊçƒâÁVzÎ¿¼Ïåc¥BOËœş„ÔGg€ŒĞÜëIŸU}9³6$’-`?‡¶ŞêáP$Œ›àN«›––QŒFö'’8<äÉúÓ¿F™wó2¾@>ipú« ¾Œ/ç„@Ú
QméV€ıêÂ°ÙTŞƒ¡O®»+®Y$j,iè^hF›‚¹½ìL‹>¥‡)¶ªFWW‹8öçt!fXsÂôR¸Õ\5sìri-ùhÌé4
ÑVºZŸ°Ó3	Qùv9ı)$Oö¾L™·¸ûWÜ{‹nfÂÒç²cæÁ·/+‹Q&ËÈĞ†ğÂÏò
{ˆÛüuK°Œ½¸§]@X"fN&“ÙjÄ•nÕT»R-¯¥ ñ<zP67‰ÿµë¶jÇa:mvût2°ª@Ûï ~6r2*üIıõC‚!bºĞL4`æ¼ÄòĞ¦ÚX¥Ëü5Çf™NG_‘ã)Çé|^Tdß·’j]Ã‰àõ÷Â¹ş—ša¶Ò¶Xó„´G-›¢bv>kÅ„Å?÷ÅÛv‚^‰rwÆLÆå1Cop·]âË1ç‰Qk¡jY:âæÓUEÄT—é)Ç}U”&!”æÚ&Ù’Á¦J»S'È«‰$¬ÔĞ 7<í9÷K
—Îñ#=«h¼\¦VF9]):-áà¤VÖWw‰ê}î”u.wŒ—¥¨irş÷@)ş:2ë!èvƒİ¶dæFa§“F.ÛÈ¤lıìZ6áÚoy89£ ‘œÚú(5¡ Ãˆ>˜ßK‘KÂœú¨º4¶KÕø‘ôWàÚ¬Æ˜Wöm¶	)
KÜÚêh!X9©üuAµ
9¸.5œ=øıá‚›È¼-0D±„Ş	)…‚àK‰õ¿/EÈvóg.‚«P«îHIÃ‡ciLLªaD¦™ßÕÀ ¯PÈıü˜A3Ìˆæ»“òaü÷IU´ÀÏÈŠÈ×eÕ0rµø´—»ˆ¨í¼(VÀ¡¶¡!ë)NŒ“¬hşâP¿Àîš‚&9ÖL‘%¼Ya}‹Ï1“»4}_hú<N¢¤İ7•¥~Ì(géŸ{ã¥ÿ””:%Şz™¾yÙ”	Å‹åÏè¨Z7{aOE<Ú©vÛ20 a==é\ÒoÕ ¯ÄçşÀ+
ß®ıˆ½éÒß)‘>–ŠEñÈrLÎš0ˆÛS9?Ê=Ä8°¶/f$=Ìƒj$ıìĞ†ûaï3Ğòj5Dtš ÷Ñ´„‘QFÎ— )€¢ÜpWû•¸ŸÆ-¶!²Q€2d‘™÷)Ïí˜2ï“°Ï’‡áÌÙa¹Ä›`?ıM‰E³_›¤AjvğÖ¼³CB3Oßy%~Y0&	tY¦2LÇEÍäWoùÇBeQw0¤£OyÉ—ˆ+f</HAíÎ©w˜³4Vİ›Ô>ôË”‡¸Š£·Du/Æ(›RÎwodÕO;ÌåË6ÒƒíâÎ’`Ã­;!qú2“¼ßèx
jĞÇ¥%’˜ n	íÕæ²¿Ağázr0Z¾ÉÌÄ®.	#÷¸ÚoŸ®z3æ—d…i*¨Øæ•VVtŞ~óåy!¶ı•Úušú}“©ôİˆNò®ş÷3Eâÿøñ _–Ô€ù÷ÁÌq.E/†ü½´¿²f<÷‚p]u®ˆ4îqØ|'ïË’=XÑ­ÙqbãV ÉÈ‘9`üÃ„=öã´ábN{#$1<p	MÓƒê 5µ¹Íî[ğ‹MÉ(p|aVÓN§©°Ô~ú[î^yÏ €±Š@(¦ÀÁ÷è/€vóæ ß9c¶Œc+#°VÓÀ7&NÎñ÷,I¼€€òÄp6ÜeË856qàé>×Û­Û	Ì§=|5ÏÅøW•G¦d\ó#¨XNRêB?V»Bøï!“=ètÍ!üËXìk7Èyk#zıHoq©|s~ 5LÅšøÓ:í7(~Ò Û~»k‹şº2˜VhM6•°y¶×ÂJ¼Cÿí†”Ù‚¯¹D"A/pÄÿ¼åx…¿šîÿIªæ(¹NŒTÆ«*g3az—š¨­¦kä®G™';AîØ¡úèÎ“™|io%2Q“ô1´ç%¶º(1Mbvâß¥* `æºmd¤“ğt:È–¸ú2ñeÜÚ¤bqmœµ×':nålÖš,`lóDÕ; LD¨Ÿ(—g˜é	¾~z4{¿½¡•3Õ‘÷ÁÔÏ¦â¢=UÊ5µ>ëUÉ¨“ö³—Éò%×rµ±âîŒ"Rwüqƒ´pØèí$QtØ k„Ç_/Ğî.-6y='¹ï®—QÙ	ëşùÛ³=fõ>’J2F´{ğğEôœU àš„¦åv.°Øİ´õå‚¼—1˜õvQnî¾°->sdZŸÀßó	«)ˆèşÔ¡ã0‚$æH"&èrƒ(ƒj…h¿9`Ğ=Dü»ı]~–ùö€C†|ÿÂñÆt÷û«ÖâDÊBa„/!Ş­Û»¬s…AÁ8îU™ °w„Â>xXñ×U¹JE™Î<Üİ1ÃF½İ$€¥èBå÷»¢Ÿ²À0:NWˆÈ25MJU»a}	ü—»NªÂM`mÀ«d±VT†”’|“õv†lû†9²çˆÊ	şõia‡B×=dÔr0øJäçÓ‹°G»ƒ5¢ø6Î›âÎ*Ä5ÓeÊõOğiL1T³Ó7¯37¡¥ñjPvBr†úxQüûus¼—ş™ûç¦–‚C@­ †0^Ëˆ	Xs£b‘ÀcYZQÍ2åeEe‰»Ñ1w]ÌÄ„×°šÀ@n’¹v>Y$Œ5!,ŒÎ&ÀøĞÚ”–»ñÏ¯å›>“u	ØÆª÷OÇšĞí]É[Äf‘–ĞËŞP†Öˆ¶eïÇsEI´lÉ)ZÉæ¸P‰]eîÏY,È˜ò.şÌ`»»iÇ}}ºñ¸Nkèã@¡»’;kÃ	kl“ñ’!MØ Ÿ“Ş>*9b˜Ïô! Ù«0µÑ˜¶ãSÍÅ‰ˆ˜K SÙ‰bŠsÄ­y×¾rÙaş„vbôªòø	"¬ÅÌú“ Mcqv^Pû€%Ë9ƒOmzº 2Ğ†´Ì[¶ªû‡ş¿“±Õƒşœ}8P}†=‹6L ¡¢3w‚4 øbŠF)j™zM½«aX(ü>â»<¸ôí'
´\±w›\PlC4+°ó3}×änìbö8¸øïÑN-¹}/o«Ÿ äYŒ/´[ `ñ8•À<ıMŒ›Jäª_Ã³>¢êÂ4}?ì»pqÑa¥„º>û`Yd4â§™Ìu?Şòû8“†9óãˆ±ç'Šíğ,Š!rĞ„=ôxhè>€o‚³¥DÁTMÅ (ò>Üîˆ«sŞëÜ~©¨¯7û/Õ9lÓ¢“	û‡Ä’ôËœƒñ­ê]ÄÍX„G‹ E–4ù›MPAû)ûácíK3EÑ ÄìÅò	Lvê„>o[pÅ0Q,ñåÌ’ç#›şAÃ;O hŞv,«Švª–?Ñå%ÿáb*mü^ÈÍ,
‡>Ùrğ1›ÿ˜Ö<#ê°0’ì¨£¼ĞËK­yT›ºäóˆ”¸ùºì4¸8£‹qõÈ£°¤Q6=ÈjqRƒ˜&à›Î}ÉcµÔC+ñÛùXñ¹ñè¿³(t›m) ‘ÿñl± Ü•ü” á»Ù}äü>SLw­¶æó4ÕÄå¼‹$M¹.1öÑ¦Du=Ÿß!Ï	òuı*Š ²¨ÜJÎ\I”UãĞF—NB™$:6›¤ÄÂˆ×u[^,›²IHİÔô‰dMöÇî”“¤:D«@)Ñ.Íı¬ÁíYúªku|VŸı¢Ù ›ÂÍ?ge£ğZİ<™0uİÈº¼ÚÈ·[¨WÖÇÜ§×Æ8‘†tPš#ÄKüªw%¨A&÷yĞ±kœu\,ÙÓ—w	>guÊüÏÎı`²ĞzóCé=@õÍÚ÷êE€Ÿ,çæ•«¨o‹Ÿ)˜ìüJ]¡Z“c¡ğÑ;²§R®½ø®›z§ãkïÁ–¯ÉÂ-’¨¸ÄŒaX&ìæ Ê²•²G ş¤8"cK\QuBÕ‰¿O
6Ô<s5X+‚™ì;ù,œö‰@tÄŸUŒÔ ûG=°¥|ñŒğF¤mCXŸœ8hÖ8ÔVê{µ€ÿŞÒá›Á¥=0%±÷VøB³èG¾Ã¸íÍ"ØA×jÔş÷j¿ZbÍV¯¸K³ŸÄ5È·h4Ãî–‘T_ÉW]Q4Á¾@(ıœóõI_CæÃf@£ÃÙ
µ÷å?lV6Š9kŠr'”•²j•{¶:È›ê]wi„W_İz/›¼ü^<•İÕ]åæõ+bÁÉÌ!Ä«
ï‹“¦Æ(6›Šåéä›Ä¨÷ó‡ô*'ÿÑ°¬)ÅzNìS 1Ğ5/’ÒÕºœ*.ç:§ƒİ½¶B Íšƒˆ`İ¯a;Æ£Ö®´_-T>Ww;‘«}D_<Ë6	aÂÆ’_Ó&cÆ»İgÃ€Â9
#¯XŸ*ñ—s ^ºƒöLÀÏAØ¸°T€;ìb7‚ÍĞw3[róåö§ã ñ^Ï×Ó<!—gwn¨œ¢d¼pvwöuoälP3¨ôb8¶»šPÚ¸3´‡àA³z|íJBÕ4k‡MÄZ,Úqá¼`hÇ—î²„ğ.^D¹ş/$›‹†	k¸4	{Öy°aÒ¡ÈŸÑ3s©¥<‡Rp]¡n{Ú‚ó¬›İÚ"2Ç;‰jR¼ñÃë¸‹¤y†Êÿµ÷Rè£ÔğÎA©Ôæƒ ıã.ùv™›Æ¤ßFóPÜZğébSl?şÊE€ä:«ËNÖB”$›Öõ­Ü('Î™‡‹ĞzJ´Ioã‘Âû£ÿtê¡ÈPÿ«ÖUõ¨qåõìZH'VI§_ñ‚‘#Qz©]ş9­˜G°K	íÃ2íAäöK,¢½ÓÊW3›ó¯&š‡——¬ğ›à±õµ:ş´jª¢wG¸‚$LS‘Œ±®¹ó9–Eº'ªĞı°ä¾%j1Œş&“*¡C ±¼˜b`ú‹Sê‚ö zvbßœê~æğ#ÙQ–HoL(õ -™®ˆt7õ„RÏ56kId­>‰ªDÆ¿7Á—ÁK¡¯ò’ñH-† ^dÏÔÜ ›ŒÁ•<úvbÌáù	¿ZÀÌŞw+µ¹=úR1÷³oáæ}ßÂq¥µr))	i83ùkH!öqC,;quÍo¦Êy‡®:>20Z.;º1­LËì}bjk¬Ï]ê<i‚3;œS0"<[–S§	–İğ”ñZ1ÅÆ¨;ô<éqØ„œûÔàyæ!W”Ù‡ íõU½ë¢`£óº56(ºĞ`å“»…ŠŒ€ƒ$§œevHÈ—ğ
İÜ¡Fí¾eÁ˜]Ü“j ¨)ORJ>‹JwßQ¿¬!ÍÈ´xM´{ø<™ù¢\–ÍHØH#RŸ¹]òö“ÎÃİ‚ù‰*é&‘PCÉ÷ò'îB5ª¥’ÈtÊ¤ ûî*rŒG•Åbb+¯®IÄ£Ê§,AN{¬«:#‰%c ¯DxÈ÷2Çä”n¨$njé\ŞñÌV™^n†ƒå¾õ”Dµ
c($Ü˜rpäfà* KŸŒ4@Š8’øñ8”Šñ+8:—çÒ[·œ4=¹óËbÃJ8o¥>xşóß	óıYN„Õ Ò§V\Fzë¹’â~•¼øYbH£‚÷ r=ê_ã€• ^!–åÓæ Bä+Fi[ÚNÉënQ;EWÄU+ön`éŸ­ á¡ÏÂŒzÜq,­çøw{Õ_GKæRÕ¤N`ÚÍ/…gÔÊŠÌ”Š
¹åHÄwVeòVSc½
Œ® Ïñ©PøJÕÊUgfÏèM¼/ƒ¥Í\T³Bæ”¾‚#DõDÉ°›‹*¢E¾š ?„Rµı8+²-ş¦Y—Ñ{yCYá?óÆ–¯¤Ÿ¦°'r?aµ›Æ5
·ø‹7øß¹ˆrË‡µ/ÕOj’Yâå	±¯ ĞÍ„A03ZpKû°_ê`Ô~ßB·‹¼pôöKñªì›|ê¹uõ;ô¾&d¾F
ñ¨§šoÆ”–¼6"6o«…Œõ£Ó1HÌMz[S§{ÖgëÎïm¦KoÓ#œ’S±nÎşY(×åDñòîñĞø(½n/&Ÿâ[_‰¯ã"-ùRÌ›Ğûú/jÎÒh0}¤ï…bÖˆã£¿î×B3.£·3™h„µïBÏÉ;Æ ÃÚ¹|±£ Ÿşà\_s§¿’o×¼AÃGRÎßØ°x5EDó™(j»ËÑ„`Ëæ¡cv“òeåd±ëò,âˆx-vvEø[ƒú{ÃôØ‰¦İÅ4Ä+`Ù	ÎJ™çÈè¾´e0]!²¹ÃÕ;3ÀißM¥9‘´êP9ÕeŒ)~G7~•ñ<šÏÔdé¼¡7qŸS<yÁm?UbL;Di¨à°: „İù®ı1XŞIÃÑÜáSÅj1û	‹)†ƒı|Ævlxªñ‹#$Ü—UèR¦îëÎéFs)öwïä÷‚Íü3ì&€İuÂÄêzî›5ó‚Úg¾¯+\Kæ\qŠMF»¯öååJètWg¥ÿ4\%©s¡9è=PıÀß—£Ù­ÉQwéãĞºO0zXÍ–? vƒ#¤!•ƒ“]ÿ­ÀA3
sxÃò~»¬9J2E‰"´lp9˜Ú1ş	üÖ6Ë-‚(0ï
æšR3­4GöT‘ğÖ‰bM¥-¾(?!kO\Ñ™ëe¡rög\œ¢‹s4Ö«Àkö±2½P¤°é——]¦<¢€“Ò¤&ÌQg‡Š>iOW’éŸÄUõğG[	8j%Ü>,,ã‹T®ş+DÂaÓŠœ÷ã§<vJÿÚüGÜ#­ÔBxÎæƒRSîËìÕ\³¾²ÅÙæ©iƒv›ËÙ±ï]åßiÜecŸ)|Yª±²uù1´¶•óÛñ“ø§´RÌ	Úl“[ûşPÈB†¨ğØT¹…()•¬ìôEØŠtY /’fÚU<aN-zdåÂ3Ôšäg·WÛE‘+…ã‰bäâäæ>¿>7İ±ºV¢nG:¼rT;šWHi#,PæZº
yğ8P¥2Ü½ËHíQ«ùºØ§ï”ÏEêêÙë®<·4oŒX;1$“Z»”’Qğy>Ô~v63H˜}Eå£Oâ®æ×¤½\çÛò,Ews‹Xq;)ÉÿÇ±E¿î?k]í)é)Ê•Z(@©G¨ïÏ+áĞe|.ÙK5L©\>†-~ŒÊpk¤†`YqPñ!ìnî‡äpg7ÙCFqfqıà§x|‘ÂßævûWZ;ˆ`r‰[ˆ–‹¬HRDïQ¶<¬¢&­'çéjİïXìÅãMˆOå(QùLX_â&Åü' >“—îE€†'KGµÙ£GÓr¸ZÑZ›Ë’}{…aÑ‘|°ë¥T%mñ>ÃÚì:g´¬ƒ˜ÎcÕ;fÂb‡g8ÓR,¬>Twvqhú“$ZšÆ÷‡Å‚pBS]€
‰áÂºfEéá’Â´:¦û·PÃoïÀdªó¼¸›BOÁ™ßÁ9Ï~8ê&9±ë’¨=¨ÿÎ5œîEb‹zæ,‡¢é&*Hú{s+3Ğ±wç•cæït.©/ gm¥²”¦§tİJÑÌ1½˜I§àt5«ìä_üëWŸ¹ÉZbk?ô.?3_3Í§´ºß÷pJ@;ÊVìgüióJÖ´m“~2«˜İIü’£ ê	¹abø0àq]DG.çqy
f]6P
@éZË)ô/ÇB"yØ8æx‹Ix_†zâÅ‹gC±á(9¤wñ@@™;àg+9·¡¿¿‡(ş__9.xáØC÷Å:Tç$±â˜KnƒEÀíD¦ãS&* *_HªA?fú‚£¡õùçÓ;" Ç¤ÇçÿJÖÎuoÆÜï¿Å@ù¢p—™…:Ç/v·4Îkk%F"¬lØÚ:wŸÃFÒë:ä<)‚²ÈØkCXnHâ©},ÏìT›ÿBâë"ìdã)Õ)îR¯'¹!WÒHÿNa²¨!ÁipõÚ¾ÔBd™—¦ó^Ô|_Çªµ¢;_ÿDyãã·ŞõkÚùİºcj³ì”ÛhŸjjşş$ø¼s‚gî*{jÿUH¥nøµ!~èùï
öóí2W³{ ¢êb¦T¹Éùó¬šìFœ	%q+.Âê$9¾ÍR“:}G`T?Ê¢Ğ‚ÜŠ@’A¨w–©Ôóvl—¶uv)¿o¸©8X®æ„±Ãdåı•Jt\Mmqãí«îT M&WÓ2 SºÄÔh.7±6k«Yô+¹ÉpœvO¦øT@Â”4Î|®Zj•Å…BÂ§%äÛ“â,}gnì6áö'İ-üŞm«‘"Í‘Ç5áj[-	€uSÜHĞÎ@ªlèØO¥ØÜÅC‰1¦wšÂ+OÖ6ÅÀ‘¯G•Šú®ñåß€¯‡Æ²o»E¥£M‹æ·GOÎNe0¨¦™şü_ÎRîCÄlĞÛòs¼?
Û‹€ëaKVÛ@táÏ{Ç@ÿÇ–W4nÜÆSú‘/	KÇÏŒ¿ÄÅj§+Ìğ¹xÜC&IÜÌ–÷¹A÷·ì‚TØ@Rüê¾ÿC­ÕÙáû#úÄyQ7rX×%b<Ñ£íö$‰OúÍ¨0ÿú§.ËFiºw“w°c&«=ªRİy’ù%3;mÑßtéGÚÔÂ–Kj2íº(-‰SÈgúrö/Épöòİf7‚xì®ÒÄûó ·*¥‡X«“/ŠªuÈ,;NÏQÎ@Í’aæöõ³4
i„íî#Á<*_”géQÇ.U¡ßÀs|ñ?Us¤ğìXÀv†tÉ£Æ€F]îäú`‘X+¡ÕÈÛF­á‘?©Ô²§ ˜gÍö¢¬W[Xc³DAˆËåÈ¼JÁ&0°‡ íâÅN…Ó"Ï>ÏM¤­¸¥UÖÓ*ÅÂK*¹Ãe‚k‘Ì†½±¼h²üÑ`dí4ÓÆ$X®LÂÂh¥%I·œÛ'Å¸TÁÇ@¦tÏ%ø¯¡ùX™ãD¨}ÕäÉy>à8({èˆ¤ÇõáuÊfÙšŸöL6’4¦¸Ù$…‘e;¼"Z… dĞb5ï£À¡ƒ˜¯pÈ€­LÍ¢aº:CÖq÷~OÍ>uåĞÉÒæ¼×ôUS’Ù3u–x"{† İv·óÅSÇEt°¼ÌmÂ õ!4í2iï ñ×^n^å²İ×V¾‚)Ë32+ Å­›Ì=Bõk‚GnÕí<¡o››õ°L${pÖZukï„2 EJ·y 3Y®PúÈø>"Áß"Á®ûs Ó¸æX.Ú7+yH«n7Yÿb?œ”yÁµ¿À×ÍaäÍ€J×Å¼”°4&ô@ƒT³ÒĞ#»Ê‡¶/_#&ë'A³*2©ãĞö.UÓ\TÏÖ«å-¬ÖøÉ¼#»KŒ‘ø8"â”•MÅ¦d“ÁÂ]6€«t`+ALœ{«†£9àœ3"·#ÄCXkB³÷,ï p{wks„ÿgB«<Pò¨¬Æ<xÒ¨•½f¯êf’…­N·\A_İÈªšpï8êâÚ¿—¾Eë!j«sÑåPRÕgøú™Iâ‘Ë)q½b#)Â·tvÜYŞÆıŠhQ*ZÓlúV\¯ºÉ¤·sâÉ7êâ	h›sÃ£ïåZğI¯Ğ(±ëÚàt×\=6Îkrô­?l6ïS\†3—SkH]­ÉÈì;ÖXàÓ5¯`/ó¹n™+’o¦ÍoÇ/Ğ[&òŞ¦/[CÂş˜?)±…<tqLcd™lMGY.ZmWö—\ÎïZªÓyãÂ¬"¢¡ŞŠ±[1UdÊAgÊ7RÇ¤/VKna[xaõ`èÅrºÓq‹›ƒ•‹cÜ_4Á´€«RòDÄ9‰ÀÏ±$Ï\;•dñ•Ë8aª3:®oX(4Ü™ôÂ—ù“å"‰Üd&áY§lÈ"˜ÕÈ‚œÒcòUhä>½{SïGGdÛÄ°;nÀIÚ$‘¤ÒXgå®8ˆlûÆ°Ûo’¨‚iÌ‚/•#¶9”~9ëÀ8€æ
‰
œcÅÿÙƒû	ª)ÎèœU&
ÖZÃ]M?NĞ·æÂk•4^¡Zq®ÙW½9ñ‚±‘?;ü¡ëëÁÏ¾|õñ[ÁhKÇÒ{<ÚÈI7
Á…¹WÿrÜÏı¢ù/iÈ!6$ˆÇ5FÔ<q€QµÇh&!ş¦|qˆ=L##™ Å2¿-¬ÎBû3ƒ>FÉîÌ0"kÓ‚0¦6™òÜ`;)¯ªçLî`MµñSQU$•¥9*+*»¨çu-ºüã…ÙHÇ¾°R­`Î„M.~C+ ÛãØÊUğ\[€˜!Ÿ¡ÍhŸuxÜR¦'%Ä@' s™Rg!Ù´›Å¦õŒØ!b×¸€½†	£–wÙÌ½ûß"8ªäå6‚ŠsMÂñŠÜí‚¼ã0Š¸úğ(ˆÕâİ»=[õr6B;T^áÃŒmº)š8Û}Ïeæƒx®…pµ\(¯HĞê×Tiôóÿ±Ø]­ëö„F¾è‚fÍZ³…sÎnÈÓÏ™CKàr}öÒG®8X‘òì)ï1ê¿ÑévÕxêé¢+ïîŒyÖ¹zÒù@äZY„üm6ƒÓÖÂr“ëvo¼ÇÙŞíS?#)\³—9j4Afpÿ¥-'¦wZ&EO'mÏãQ}Aç§bÍ•²$:œ/b*´QŠr0æŒ¯„÷—×!¹{Jï¡KØ±¯Md	
[c!¢ûÇçâ˜&T —°íıeLCïäß®Â?ÚÕSK
9u×w4WşŞG¢¶ªs TÏº æt¨Ü9N[sE¹ï¨,FúâŸâ\ˆê\³´Åëê_?Rœ¢n¹cßóÓ›5M•ƒ6Âği«mï´,aNÉ
ctıYG&ª—gï<¼~i0ÿĞ1!lÚ)İÂv½Jåe÷Û,=²l']œtXxX¦íù´4›…£æcì©Mç‡Å–ªaØEm•ÙÍ)Ø¨º¢7~ìØ‚ZWü…òK#Ñÿ4AşŠ$¬‡Ô‡×‚Ğw¦©â|€(7h*ÖŸ#Eåxø“.;%½Á^ƒ€>êX7¬Î/#§”áÁ¿ÇÆÅõÓâÆ¯È»©²ÑúÄ Ô
:kæŞçÖÅ,©Edñ£oûş,»Â0ëaæw¬JÃÅ(Ñ´ºRì9¥o$ı]¨ZÂ½ ?KÔÕ<F
áiîœAeH8”]y(€š ÈEKE@­5y¤ïÕ	Ğºb ‡µl:?NJD¶¹æKĞ´èßÛ=	Š®–/şx42¢¡7]~¢KûSCÚÏL‚¦„Ê‹öMÑr±À\À~ĞbiY	6OBäŸ=Ó–åIe Ñ{]Ï˜G‘•äºïJSm…<Ízpök[üÔ½2¹Øzv~Õú)LğğéMÀCŒÎšG¹˜ÙdmIÜ)öP…©·SP
7<{u…¬Zµo aäıÛSÕøÏ,¶ªÈÑ=æ¿ì`²|í[€?aï4­äFe×¶ÔbD/sƒ©óÓTŞîÅ:YùÛOMûæ¤
ğ7*]“	-/¸ïÍEÉØ0>;ö…	ªËd‰{¤'•§Çrö)„ùê«©uN;Üf¦á“¼’tâ´ø¶éOëoFØ3ã€ÄÎk0¯©sÛÄ±†œ M–¹nÚÖxB -ŒæebÂ½=¼šiL¤ÀCçRŞ²™q?ÏVÆô^ÚÖJà|NİSŠù‹g¹|¼¸E‡(¶·B7sÛC¯wØ¬‘ÄÅZ˜ ¨IÒó5·TËtk*ÒªL-Ö'î…")h‘¡~‰kıHt‘bÂ*‡DÂ•†«Ö¸+HS†¶0«ñ
Êšlü6ˆû×Ñ ÌÆ‰ Ğâ8rú4°L…¦zlIºó<uºHdn¶U>p2kPXISØÄµ£C3_©ek4İög3µåí)É"JJàú ĞÊÏfZsÊd3‰¯ÏÙñ‚óµŒ€àDÑ.e·ƒç|@(ı\¨w2µX1MšYSSïµº0kúÄ¾?šMú´"”æêÌÍè·b—˜f¾ä“›£Í¾#Fó?ØCx¡7=‹ó¾æù²E1¿Z¹7Ø*%Ú™5Ã‡TÕ‚k"Àæy™PT/áĞ]íP½5Ôûb W®Ö=-ĞffŸQÿ|ŠÊ&ÓÀt?Êùxwa±XvæY0úÎgŒßHƒ'Ñø¢ïEÌ)Só$ë{dŒoqUhÏÌpµÜŒì÷Uñ1÷%àïN›Q¿;¶ºnğRŒ±Ãeó Õ+¥½å^Ú»š€Åü«°ø	{%à|ì™İ½ò£ùr’lôvÌ)t~Ï[³65¾dgşÑ%¡€h>º^ÀóÖÛ±åSàŸ›Ìˆ=ÊF¯iç€Aæ®’¬¤†1¸­Ö9z‹Æ&Tˆ&0D®+åV›.*
ÚXNÔò9Ç/œü}v¿B“‹púY½èzq·­<æ #®aÁ1XG¸Î±9İÌ*‡`A>èÇlB‡}_ßZÖê…0Úr—>`b®õd7×Ì•‡	j¯×X1¹»í¢R[;ªÁ×uŸ¬ÒF2Bª'¼Ô |’±D&ãpiä*ë…&«[¡$“eÿ×{u;¡êß~zøœÒ,W¨Ò,1LÏ¾Iç&¥h³ø¹Jtlæ‰Î›”éuÁsN²sW× ú•êñ©
ƒGUIQW±¡·’8K4wš¼$‚1µàæE„eé?p¤BíU	åÀ¥÷u|ï¿mí¼˜€¡îÌS7~Dİ±äoæQÚç	oÅ–£»q‡Ší°{9Ş¼é#cnºĞ	C«ãºn=í/z„şGàWS<’ÊâÁasµv³ÇÊ‘+Ø"zÏ|†}İe©Í­¯Ûï"Ë[†';ê!åhİàO˜™8@bÌ^v^yÑĞ%œ3²²®LòŠ´ì×-ó+4©gÒl¬ëÌzº”‹!"4’w» ç%Ÿ€§^÷>É;«R]ÜÕqş¾º®át>ÿù>Ò*k¦-´Z<€ö~©TÚzõñHWß0EAYğ¨j¢¼Š¹œ±tƒ­ˆëúİûøÛ9¡ğqvBZ¾‚ÿ¥uá¨¼:ù§DèX°Ÿ=ÕîÌ<» BEª^¤ˆ`é0g²weŒBmƒYveÁÄ‡ş%çTt.X’¶‰mOÍ8âÃç4béc °ùÎ–£ğŒq3oÕ1íšôvJbËI
‰?6*Šı¬ƒ—øœU|×üD—ßÛØ]Ê¸b£J?ˆA³«cxıt!;§Â±êE²Ôâ<^Ğ9‘}úĞ®¨–”?(ÕtµNMmÕzæ™Éìh•èpÏ±Ä.ÕˆùŒŒÛöµ¬J² 	záİ‰¦nôZïıí`GÂfÊ€¢+—šDí”®k«¢x_6”`¦’çÔ¦ır¡L_	¤òA%)L}‘b­“~+/—T­+G_÷–‚<è5æòWØ²±ì0ù—õÃŠÎşã*ë¢ 3„™Å*=»OG™:	ÆvXÜÊu1ğ°Zú«Œ[ÇJÅ“¹û–»üÆŸûˆØ²	÷ø•¯äÄàR”.!ákï «:Ä5²Íës^¿Ã[ÜÈÆĞ‰Ù'lå@¿—û}É'ƒÏÖêğª‡_VPŸÅüîs.Ø¼Õhbá€
Û*ö‰!b)Ÿ‡0HçæcÒfÊyBˆ¥Sµ~ËPƒ¡…‹­È»Z[ÄñÔrˆ>º|Pâï«ış§‘JkW ‚¹Z‰vÿ9c‘	ßE™™{Ø*ËAUËcT£L‹Íd7Ğš=©1«2M½ËK&ËèD{êÇ‡." ¶øÈg¤ÉìØ"÷328­(pD[]GL°ó‰2ô>"ëÏ“¨6Ì<-Tbî„-ö&G•‚9çõ3º$‹¿ÙNÊAı¦Ì;ñ. p6õ½’<s|]ïŒ–¸9Jf¿z.tËñ2†rë–Ürëóº«l‹ˆbôìíí*FÑİÄ4œKó9–Úá›¡¼Ö5X$óİÿiüyópß•“íe÷÷Hú„ÛaLÁ_¨ŠğúĞ"›€úbß	zÉ¤"ˆVŞ°\qÑåï”è…jÍ_#w'±NÔı6†¨YTp^äœKí„w6êÄå¢nûK½]\H,{DŒß(©®_Ö;ì4îµÕ;¨âÓh#¯@°Š]ƒÿÙÙ€è¼åéoGË)ï¯
ççcsªó©r÷T›ku,‚=hÇ¤ñ¦íÈŠ‘‡øñ!Xü/¿>ÍMÌN˜­ñ©¼ğx.¬¿±m.Ÿ³òÃ`.ÊãŠP_<”j^Q´¹j{ë®ë&WüøòO¨^¸NÉ0Tb‘°O4·dtÆÃ&©ìt§Ì0åïd:Õå+î}Î×ÒÇµœ3|óïyº\ùù*ü­Äz› ß8U‹‘Íçá¿4ô+€Ò’àÉ¸¿=dv‹E1D½yÖÙiìbù…P|¢^à”Òt7ïøÀÒè4,"2ö^ÙüšY§Ïµ}šÉçFHRnVĞ£«ÿÿ$X§…IIÍ-ñ|è%XhwvÖ¦õs¦²¯*§6óØãåzˆ€â¢U˜BœŞ° ©W1<€¥s¾UİH©Z†éMÄ¤Ì*µŒX%`N2ïêø7ÑğƒŞû?jyuvƒI=¬Á„Ã)TÍ¸Ã·ÖèAıf‹îŒ`š;`×l™8!µX“¦µÔÿ™èÓË€]àú8©0#:(ĞºM&nce¯Å†ãDL+£jàìáÂ÷kQ¦j”ã˜—ß—Ş‡QÜqÈHÉ3l\äµ+ŠªëtaJ*\áÏŒBFÈlÖz±ç”£¿wù^äï×:İR½b&b_ÿ‡và,7·3)—*Åª¸K4‚q&¼ælÂ†¨Fàe[€%²9ßÁÍ˜ª:—GT‰ÎËæ—è6ùK‘²ı%}ZÌÅÌBü‹Û°Şø‘F‡;ğÑÄëpzMø«µA¯‰azÂ÷•–&Ûøp°‰øK.ı^•°’¥PúYâİÜ„¢ş~Bà*(HÏMóƒÙê›¦Ï+N$Çª‡Â!¤¬æÏõ×‘Ú^§dõ±İ»$Q µwÊŠ÷ò üxÑQ+WÖ®?…Ô¹Û¶ıRâ~FÆ†W4I™ÃBfaC¶`4¼‚4×kŸY†¾Ü©x ôKú¸Ñ¤EÎşÃƒøš/œnCXÄØî¸ÈÔ¡«”—îRáíCîÎ÷ãYÊŒêJ’FR’ïèã€_>œ0²š@Ûmï¨õI»SP¯H»G­[BY)bºÖÏÈé–÷ç*ËÄ‰©°9ó?
ô°Löóòá´nJ`Ï|a8&­˜÷¢ ·Év^ÊnVün¯°EÕŸC9êwÓÛy:'B£¸ä`l™×:?ucá-‡YKGù#Ï5’9U·áKYÒpëåZí—C[‹VIwËˆp‹.Ô>¹èÊ8½x6Lh·Ì€ÆpÀ<5Â@TÂøˆ'ˆtNÚÃ¢¡()ëÏé½ŒámšÁ·n™z`qGÙ©&µ}å‚-5º¦Vv{ğ6«•8Ãén~€,o/ÉùĞÎB¨ç•í¬ıõÇÕâÃb*ï¦;´|5Ã~	ó9n³o0À#^Ua5¨ï£°ôSwù'«ÙËıXáàø›âml6¡±Hd±šŠJÿ6ÊàAÕ	;_3$íB*,¨­¼•árækÏÏƒ½²(<½qØ=³mÃ?	‰£…És:…oG:&n©&#£pz^ôN¸)~½„\#¦fÌÕ2 ¢‘Š?o$Œ+…IÛv¿üR’Â¬O=µß»DÌô¦,n¤­•‘!=…u|9=Õ|9ûsv	Œ]¨Æ¬½ ¼—eZ×?Ô(ïX…Bm7‰8›©ê%¡´®îç­u4b}Ú°g¯Ò–ËvLË«vàM¤Ç¦NŠx:aŞIoé{Gz~€Ÿn9ZMÌTwZ„èÊÁR.
*1”*±µÃ‰:‹ÏöMfT©Q&³0½`…‡Ûà¡v3,9ò9UÊM½0«(ô«%	dÃdt/µü#„&ù¨ÀE{¤ n™¿t¢Yèr‘â)<u˜Ï(ê¸ëU;UipÔEÿg„işJñ˜«Ï"²¯v}xğÚ¢Ä'Å&0ğDÜû¶X!|¹eZİšÃvó2=HÓ²sß¤?ÀáíÏNµU;£ÙSº}[{G
û¢È†(™B)oà7?2ìyêşKÜís'·1I2BC)µ…‹ëåìQêZmz9²ÊæÕÿz“ 2 …¬	æ•<òÊ Ò)öáÈÑEåä­'àğÌŞ.T¬Š?¾õî>DD·ÎòC|:Ò%ƒÂˆÍß”áyÀÄ;°a>ÇÒ¯sñ¯,Yœê¤S¶«Ã÷~ªT/§‡†ƒ+ËÈç'Ğm‰[;4o?áY„–şĞRh]6ºmŞñÌÃ£É]''ïê÷	Ø~æÄ[ºómã
×W|KvEAÏgoTÙÀğF*±2s¯³:@ÜöŞúsàÓW5²•’N5H5Ó”Ö(öøWş'èlS´XT§ân¦ì•Ü@0 ;ùğeå­×öVY‚Xø. ’ÃúsN&¨¿TÂËÿi¡ô`8ÔÌ6ÆáZ¤ãLkRÕ9ëEÎÿè ÎRØÓkE§9|ÇÁ”éªÍ–£2ˆx(>J{@%RM*FN¶âV:3±BË¼ş²dœvë"ÿÿqípŒ[œÎÉpÙï.`/páä¥KÓÜÏ,kA~ÉdÒ¸°o$€®Tó¶)7@äğkØ,Tgµ¹É”‘“Ô½pHš_Zh@š¡ÑÔK¿Jª$Í¢;<:ï7Lv–Ëp„q( {8UÙÆëqÚHòÕrğƒá’ôùoÆŒ|ÚbDë¾MFÑ’İ]Ä3øáÂ¹¿9n¶¥—UªE¸ÔsìñÔ·]5ï )_T,²Çï+‹ô¤ò0‹ÉÔ—+ Ñ”CJ×?…„¿¼ğŸ·wJ¢ü
£Ónå su»’B`x$ÃŸjî÷î½g¹,s¸ÆH})ëjû³uÿ ­ı“Ö‡ĞÊ^ ÁLYÅìb/?ÎiËPRcncé¼%/ºgßJq£áÎÕ¢Ë«B{U;û¡k¤ÃÜÉ	³¯Hnñ|§ä íÑ|Â<Ç„n‰Ié’„‹Ï¹°Yº`ÃêÍ®ÒeuÏ@˜l]“/kô@³šóùÀ“x…íÄêÑR78‚²/a^ÛñIcWv@®)-˜¤Æ9w§„¾è ş´ÉÇŠ§Ã)?´Û$Pf’ÁM”¾kÕx õŞ;LJ;¸×$¶³ÂÒ˜{"™fÉ$: `:¸‘]uj×ÇÆ®°ÕX"°†Ñî—Çd8ˆ²gî˜iMCÎÛèTR0NÒbZKøÃåîş¿®ğ•talXÃ†^®[šrìëŞ“±Ú5Í7I¯.#¾h¯Ñ—³³?ˆx
ÊŞ{²oÀl„ó‡º#k.ı|†šÚQ‰ä€l·¿öÛ#ÕEÒÓâC'±ô…~[-@víNF|èòP±ag½uø¾w„0E-à>ÎhÁ&-:ÒMBaP‡½ª1¡Î:nU?AìIÜ½9gÛ}Ée;kÏ˜²%Éhp€Æ©=,¿(ù§€œIæ²ıÍ“ìn¯”˜ôÅÍùoåw³Mÿ>û6¶rwvSº\Ëû’¦"›@ˆÛö83.8İ¥S‘UşÌLaİÕ=F`—¯ú 2P&¯ğ¼äğòÜ£
ÃÏ ŞÉ»nº¦Œ^è¡N²‘Rë@N¬ôóa|6¹×‡8TëZÎë¿›\ ÇX…2$yÛ¦|Áoh*¸9¨é7òŞzÅåÉ/¦ 2•áåë—2Èf(XÃûôø_%xrÂXÒä 0ob†æ 1ŸÿªĞ"é?x>AB'jÃRÖ%±½<J0:[{òM_oæykãç@~[1g©âp«‹A®_i=¥
—„Ê'Çó»P9›<É©½F`|S!±$É³·0j£ZƒAmWp­ğY°úÌx”èÏ?‰[¼j©/«ô@•;¾lŞu7ØV~ ‡@D+òrAk¹¯§ŸÉ4Kü]—¡­;{-¯L®+µ„pZ£Wı„ÏiÅ®ÏşİlòÁAL.™0¹ËÖ!$
’x—{@Fÿû~¢³³†Qúğc†©"52}ZQ4€âİ©é5iô
Ş÷²Ò,²P3ÃÇ™mRK5pïµÌMuÒOĞ0À+eeãÔø»@*äÂèÍâ²»ÕH@cÑÙv·P%ñ¥Â,¹A»äÿò,-&À/‰T¼¹Ö‹Ç+,] €øŠ¼.¡ÒğÎ°…¾ô·"¹WO#üWª‰C¾ù"6=±›Vø¼qìv?3ÍnµJ ïC'“&İBm#§å]F¯Š•UŞ+‡jßòói®¾¨^‘>ŞşŸCM"†·xò21òr]×ëvVéê¦IGÍğzÜöº9ÑõrËş•HÄŒ¾¡>3m2i@0È[ }ˆ—7x”zÙÏİ¯!?F$°+¸îğÕË£{¦‡º<Hè=íÄšSIoå?Y'Ö[-Wë^ò%¬’kƒ	l»JÎ¼ªbË:¾NáåPÙÊŞ\4ßN{Bâäïd³Ë—j˜@ø†Û_Â±0üÛ
7&C¯Ÿ8Fn–D7~lî³;ù>¬ ´‰hGëÆ˜ûwd«ø„6U[yf±Ğº;;h›xu›3ÖÂÏWB}vR¤ÎÒ©¸hÃ8ÀøÑ‡~JğZ¡Ìumê4µQ“ô‡jARšÓà/%ÿ–¡Œ·ŒÄß<}bµšÂ|F½D=5­íg‡o>Ë™QR$…­¬2§Ç'Qpùôg£d+±ßW…¶-f[Ïİ¤’^müGô6&Êgâ§0®ÍöœîMgõ'E§!ı §úR)û´SVf´*ô£(·F4PÉƒœU{½>îNs–¬PK’íûb±v¤ØTa<£8Z½Œ(x¨Ô"ò»ì\Î#¦^É¡{ZS®IAB˜[èÊO9Wnq@ø¼²>(Ë¯87¡1»³‹ÉÔá‹j&Ö"É™r€­}ÅÿNıúnÄ¦öJ^¢Ú ˆcğÙj ïÚİË¦¨nÀZ-2­×ëu-h<~©Ë¥@n¼Cª_b^+şV>c]>jÚô›ÿü!p¤d½®¸¥®é!¼ûP±UEÊgã	HÛNÛ£ä¤ªLx_À„˜&’Îf±Óşcè€ÈÄÊê`¥‰§a{M^/õÉHMbÁ—’a²¡	c ±îgL5æ¸Ø§™rtôFq´ËÍöÏ3€t¬èìûèÑçÔ…² uË‘İ,©# JùnG×]üŞ¨ÀP}"á£/¶!éšZŠFo´'>€‚N49Õ²„ƒA×~§âˆ…iÖSjnï–UÒ ş½^5Ø™tå'aÓÛu5yËÙ‹‹TÎzbùş³^ë)’2øñêñwù8\ëÆƒ{ÙÈ©zÖ˜rµp×Å¢H¬Ã:´Ö¯¢œçÛ¶•¹¦æ´—^·|áÓR,N×7¬R6eƒ§êjÒÆæN¬nÖ>;vÔ¸‹0¬v6¢Ï©·<ld[3/J
-$‰ÿF >J.#EÅø#‚ŠÒ*L7ğ¿š): ;¦ÅÒµ²İ[ä?¤<ÏNaÏ”¡M|*Îı¦ÁÅe‡Ÿ°»åà|ƒóŞ$nS°m‘ázÕD>#¬[†<½u.œ§ğñB¿#šè·H+0+÷e/x~îªÊKÖ­¹“3T3Şa–ß> ‡¯ıø¾¸‚ö¼7="Mg”‡qàÔ7ÄşÉ3ÅÉıs’|Y/pwòš¦Ä6ì@j	GÏ­åMí„L™¬½>Â‡/F©¯50¦*ôÉw Ou™,{÷BåRŸ0•=*N|P&õz°…îJ_-¼•–ØH´¡H£˜mÖwÿÓ`½íoµA:ü(«=SÙo§œ	tĞÕGø°ƒ€=IlcÕÅN)=·Ø*ë<í5÷Ÿ$<¨&°R3{dô…’™ËáÇ1¾O©ÔY0—@ÀÈ¯ô=6Í„2Š£«¦	r¼yy*äÑf†4¤›m‚£y;ü0½úÜá«¯ÇºNJ>•iÄßç”¬]Y÷Nùqô\\?í;+·l~YG¿9Şké4ò¢c§(¡‡8tÕïÍ4KgŞF5$¥¼å’¾´Ğ Ê»Úb[NéÊ$µ}«ÎµÊAŞŸ‚K®ª²¿d9'­éµD»J™4@¶ş¤hlá=»İ­Ll&½"@PÏAIïh@LU=f>º¦‚‚Ê_,¿¬©Qo'§Æqpœ$ÏoWköØBHp‰2” šI=Q%Á”t–‘i§š}‰+ä~Ñvˆ„Cç½#iãKÃ¸œ,•e>ëÁ”ÿ'NH8Ò¨å÷cMÑÙiÜåÅÌÇ†/}àr›Á
Lêha9ÅWë×ÄL/H˜hÈW÷ÈËş¢“§Í+Š"¿Ïw(ó]_—Ï­ß‚Ó.¤wÄE¿ FX'¸=YoS8Á-jtÈÄÓ²Á[ø í(à8TùÌÛf6‰İ©Ì‡ô}ãa— [m,´Vö°€•¡Eö–İÿZA/p !¶4és—AQì™òëñîlæ¦züŸ÷Eù>ÈX.ÕbWaïêE§^SÌ¬œåû ãò,‰Óôä÷»PŸ»fRn3ü$°NŞy9R€@ğ¢u«yzfk.¡ ¦3´õ¤ë’Íãñ½3úò Å–çQjÓ†ûd–¢	-í¹í¢jNÕà™vÍ¸{Æ±¨Îİp ç_ûÁ2@ÇåÌîÌñ‡H\\”/µ¶ë›zOïƒåå¹¬KÓb—-³|üŒ~Š÷dÜ{÷Şwëó›6©8¨«at®ºûël
òAP;‰A;”ÆãY9úA}æTú«b‰;–ÀÅëF*<èáçB/ĞŸ³t‘°|º¸-ÈoÖÊøBShVÜ=døN×.‘gIœŠÜ—³dòK'óÑÉğ´Dë·.lI›Äó_6bÁ`ˆÕì÷M“û>ÆŞˆİ\ÜÎ^yáxV€V…VªÑÕU­Õ²Û¡˜ñÙx˜¸®‰Ä>ÜıñrmëóómEnÙÏ£t,¥, dF¨3sä°”r‹¶áâí5Î­Uuõ €ìarm|_erY¼+ç’£NjiN& ğ÷»3{áçåîÑcä{ÊÉ®Ğkø¾¡&šşuô4AÎG÷›(?]ø­èõy Ôs˜ª„¬ZÇ8Õ(}.Ç†’^¦š÷“Dq¸†™AÅfóÑ³İT^ÔbzY¼àº@pNöî%k™ç!¬|ÃÙu¶’ìÏ~^‘HJtØQ;OÖ5‘oru¼<öECà`Ğ‘šmZC3
¼¿6Â VğVÁ}óĞÂ´6ü‚µ÷Õ\ˆtoŸÉ–=<}£*†7ÁZT`bE9åó¢ü{°N¥w¡Ÿ/_†,[;MÍ”Ì+FœD¾½0§wB}ŒZL#&—yuhM»Ÿ0ìîæƒäºÉôÔÁÃˆv”`¡&³vCÎ6
œr®¼Ñ§å5Q°04õÉH‰8¹/{à›å¢Ë3ÜÏn·RMÉ™è=ÎÈ¥¨$ª‚‘3ÜEç°yx ši¯1î@#†acM…)@RE†ª¶Şl±'«½„g]jœ±²(ImGÊÁ}&õFäF÷ÜVåAxˆşºnpù­3¸Òº&={hÃGŒ›q:àôs3Ü—lÍ<¸S‡ÅÉ‡CT‡ÿ&G?'k•O‡„¤øÎ„\ÅUÛkÍ?lÌ‡¶‚§ AÓ‹YÚí®+?lŒ¬¿ÄÉårÀ¸-)g5şÑ¦Ş]³ñtŞÇîì•Â¤—ëeP$k•R;/ãëô3T±~Ş¾ i&CUˆTúËÄ 2‚H§ †ò´}e‚™«¹‘öİ¬ÉâŞQ;­Æ3ÍFûßâæs©’ÁTºLó,ÌéQ0Àõ0P
†°¨ŠU>b@(·§Øª”d{°æ
ğªAİıgiæ2«àK‡*%O,’€§—1×En&²uÀ:S)Šá¸³{ï“CpxµG´úØ<æ.—U%á~´şI"Š¸ä™ù»µ=Grš})Ûˆºôğ%Åİ!İ?¹¤2–§Z£í±„kYª+–*d5âyİœ[(ŸF¹‚£¸ë¥ƒ5ÌI«Ôßq5¦5ŞG¨¡WË8-C"ä Àc8ô]¸Òrn4I³<yÇÁ›T`ÙÒRL eÓCMA@–¨ÖÄ}_ÚÜØ™r€öŠKğÓ= q©„ßù¹ –˜Y4a£)&#ãh ;˜XÄ”¬;Ì‚›õKDnG\›ÍÌìDİxƒÅò÷‚êCŸq¹'ò'?¼kÓDuQ\öXã'Y¿?&ÓÆKuP³|”Á|+Ë¬*Ï~,‡r6«°ğ¥m(?QÖ=á—G8-®ÒíÜZÃ.²ª/ï§eÜº}:y¨ÛˆK¸%ãÙØí¹•Ç ââÂŒ-ÿ]E o¬oêTê™Ò.îg¯Ôi	aŞŠ84W=ZO2›İÉõª¡¼çƒ² T5Í˜^5a™”ø¦÷£Ê¨Ìœ³†{ˆ0o=mª•/G9Òádßá™5¥p3„ü„D‡â¶ıEÓ[”¹GŒÜ5yr	°EAÇ]t˜ªÁÉ;6`PÊµ „¢Z•ãÜAbø½™Ï
Ê:q÷ÕÇFĞö“%K€†X5Cîu Âá#óYû-ä«YrAx¹û i€vòÏD†)×±XM¯—¦ö­€ zN…kz¯cÖ5é™„C«÷ö´S˜Kw%¦ª—OŸMw‹™Ôøÿ8‹Y'XR.*7ÓzËGsià%­èvÇ…‰ƒd«,¨N¿¯4É¼rS+ĞZñ¨7‡"Uräf<m¶îšĞËÛ(–oç›å¦ÔF@ÚZšP¤S\¡ëğ‘Ÿü7²Ä¾•—3gÿö2îâñëĞü7=Òã	Bc^˜j”&Ñ±Ç ]<{TycS#õöMŠ]Àk
Ëì¢nPò¡åÔÁ”®xĞLx¿šÅÎ¯º¸òéP=_½W‰´’”‡¹½ŒöŸİPøP›™n«Ëãê İO}+ê{&Ğhÿ5=ãõÊû³ánWJ5‡tûm^c>Ù¤2P$äFO|.,‘ıàp 9©pÓ¼£|ª&'Òı_5Ó$è£^	ìQìQ"€xˆë ¸˜BÑYªAœlÂyV…Í+Û·Š³æb™išmašK9·"‰;§ş½èÍ¹¹­ˆo[#:WEˆ5L«®¢^F›í…†/»
R>‚ºÚ=¡ÇêÁ}›½ŠÅÌê-]é’dç+°f€‡ñ[¯ıäld™	Ç6ù#ÙüíÒ.Q>~ff SYâ“Õ×R©’²X~-ÄP¾Jş¼•ÚˆÿÉ ºIS™ÓGê÷@’§O{Œ,iÃ
•G”ú» ÕÛ	$ûeÓ¤ÔÖ´|â­÷|ş{3ş€¤ªö3~µÉ	¼aàThÉ4æä'2«LØ·$®wëY’DOaã*µ	¬P‚QZ²&{ªi}±©ˆ¿½Ÿ?°ºÒå]¾kÜzƒøb»µ:ó2*ï5µëäì„¸¹nb´;ÿ)zåğ/@ø¢%²èc
÷Ó£@¾<êŠoÒ©%·«°¬ÍÚ2Ë”şpÜºfLFÉ-Ç.Eæ8õv\Ûñ»‹šrns“ËëDğPÿûE\Å³„`ÈÜµ¦çÚçeMYjKNöaI›¹FJ}ùÂÉÛ‘ü®É}’»~y³éEKşQcıÂv&t™z¿¶üªTŸ&	I¼`ÇV¡®°œÂÎòL¥5&X0¾[Q›G l€¼GzpkÌö¾ªÚ‚RfIÊæâ=3`†ª0”¨/O¤Š&jT:]Âé¤¸İ¼t\ØÀ¿J]"±ŠyÏ5NºvÆ1@NZ®€|®kí&$ú4Ãë/êæ…ñõ+ú‹ ^|)£™T™Bƒ5Î«¹}’|«%.ÕÖ5kTêsÈ€6`lÁ@îNlR.¹ˆki9ÇóS˜¨¼U;Ïà[†
²„’^”èúùtR Œ®ø!6åR¾)òëÒÂ­ÌA;¨›å †Qç ŒcP³!§¡ÁšSvâ¥1á@ã•A\·MTÇı.?²cu©â<íYò³ËìyP­Şì\<nêß†±Ó) ó2íõ( îŸˆ£…4)XÁ¶ HXbÄõŸhçwÔÍà.Ï}µ k}-†Ÿ»[÷Ã/u"$˜ñ÷È
ˆxÀõu†½_zÂI¢Ã¸ú “Pp@DE9ÌDœè	ÓÁZIŠõÇ†â‰xd³MC¿—ÈÅ~Ón„NßµÌÌïp]±Š7ş{İºv‘%A~©^î0_îÖ€ŸŒ^«ŠFô„ÛÌŠ”]j"Z FvFtø~Îš‘<blŸà•xy¿A–Ùü€³–™ófGÜcı)íDŠëX'¹ÿÉ“gLA1qÿv#ş¢ÄT·†¡ÿÒt¾%ÕñÑÈSî]{B.ÂÂV40dx'MòL(«ÛjvÆsTmÎ'ÁŞzİšñ=¦İy©©çrÉç=O'Z>¼díá$b ‘ÿP>Q™<ÒêáI.$£ë´í²/`SG—åbƒ£Ocë£×FÌ#_’uÌáÖävŒ¸¡ÇSè4rğ4ˆßqY[íoÂ,6×w}sI"~›BR:V+çTŞÇª’ñ¹K×ï € 1–Ë=è©Ìæ!¨ËlV5œŠS‰S.RÍ`æ°3äË*¡ºhT«¹õof=]"¡&AN·&@/î!¼§,Ô„÷
ÕïSsiq—ÑQ2¯('UŒÓP`Ğ†˜B‘‹<Ö[wIŒÏSÕÛàSĞ-=¶$ş¤„»ÚØµ¹6¦€Ïòéeááø´PÛ´K/º€v¿~»Öª÷h	¾—¤mè Á!P4ƒy^cË£NC:LÕ”Ü‘ØW”èSİTûs{~a£eò·ØÄ„L½¶d"xA#‚Ô˜‚\M™(£ff*İ.ô¥mÏa›T®ıÊ´¬âŠÒ‘Um‘Qù¤¯7æ=ÙZó`Ó±×h—)inp4W· m•İİôì/‹‡ÅİÜ>˜’î ÍÁ¾ùU˜¬paºÜ®è—ïW•ÑÜ8¬‘,J ŸÂ™xÂ*;ïì'½2xYÛbéµêö¶°0ºÑ3Õ].‹Égp<)™ºÿåNŸWàeé¿€¥y,?•8çL¯Ì1¢Wbq*ÀP
ù¤5¨gHèÁBÀeÂ;&úd€¼’ 1Ø/;õb›EºsÕ’´¥jö¢Q¹¼÷…›Í”!G€zÿû4ó[fğã#Ù½¸¤-/øy‹T…“Ø¦œÆÛUFZÆ·€wÕ`É¸«CâW…–im¯¹3÷V°\LäR\hÊêj¡É1F]êˆs“kJ%ˆå·#´d ÚYU!Y‰cUÊ—ì3W©0uÅ"û'1€œ|~c>ÏÉÅÄY›|<‰¯nš™0°ú¯§6/£ê÷KASì€YaŒ+@ŠM!C{Œ£Ld½­s¢f¤F•‡¨=‚ ²TÅú5W‚?ÊÃ-œ¤ÄâÂñÇL|Qe:O·’\’œdhê5è]nX§¥2‹‡R«ĞV)àÒ—ì>®&fµÑÎäI~G„t—< îÎÒÂk&¾°ê–Ì€|Ó„´M&µŠvT ó¬ßúÁåJ©C¢¬@~$ˆ®Ì8Ö$ßÖ¯÷wÙ<Ã&™Ö0[fK¯É("­Ü{)}÷YY‘WiŞL/›n?8šVÅK#ü9èX.!ùÉïÓü2ã@a¾¦tq3òğ´o3¢ü{~#€bK’3ŒüØâ‰ï=$Á5)zJÃw9’gŒ"K–ÚÕêêˆœË‰Â®\‡¼Î›u¾›û÷ˆX@ØÓ(×ì0‘âll¬ÿÉ;ÂlàKTÂFÁŸZãş Š&v¢B­Æ\X¸!YR~Œ*ÏEE¬lFr¥wĞüNek«ÏpÀÓ¶Çø†áÄÂn^Ÿ"EXí4NÛ¾^Ïl›—ıä6÷ã¥R—¹“GBÓœ|ğ…>ÛÂ6Z9(/DÁmü¾$Å!’]è2Í&Å$£%Í¨ì¨Ì½£Y¸e]µq^Ò”ÉÛvîşÇ{ëY¸¹ÃvıˆÚbæZ(K‚-Z[j<¸ªˆŒçùw:ƒìÏO€lÊz"ñöÙÉ|=§C#‹EıßèÆ_cş¹)”ºËK[ß:­§ùØÇ%÷	3®B,Ì5¹ı‚¤û2.Ta@å1.Õuµ¬Ùù
~dgò†oL3òÛh¯„îQò¨"00ZS ¦©òU ßˆz<Ùs íUŠv	ûIä#©À‘“{íáÑ4*;	ğ»bæ¸´pÂ¨¡} 7á¡[Bq;äukuÀÈÙÍ÷Ãòy­dÿ®XW¼¯z¼å†½¹Â§“ëB-g‹Ş5¥…5‚û§ô/X|§ÓHÙÊML£Tn_ÆË“qUMãÒ8 -wz­ùïzGÌ*Ê‰¯iójª¶ÙSÇqoƒN[O4à)Ôìí»'ĞR‡X?îv¥-«k´™–'ê¾>98é–Ée5‘uÑ± m“^.ENõ"l×/‚}Ñ«põŒ×ÚCAO¯WJ=ÖAÄB3ë“çN1)ƒ4{¶Û22r}ç‚º*»³v}z–áJ±}63•Âìä%¢¼Çzç—$ŞÏŠÜßí]¼×ÖÜ‡RåÎ.?9ğ‰ó ”“`Û§Nu£ï¶öi<èq³§Ïõ>Fw‰Zò’$&;KÜ?é£jyf‹ò>
¾}öQ0:¯¯:í¨äÿ¡Ü˜¸¤»‘Å1o‡9˜"7Ïåéæ½É œ QÂGÊpØôËÕUM>…H“™<¨™a¿S¢–®Ôô×zneúíİùWı.á¥¥bâÑEßN`µJ¨ÖÜšbU¶ØºmôšúâJí:%ı°%R}c,2vöí2nTàçç
mŞæØ¨è=^ö‰
Ÿ}ôçòWodyí
"å[?»×Î³,ªì>`ÃXyT4"‹FIïañõH„ñÏêŸ0b|ş‡´² Xz{ú¸6Æ$º°`è¶Nà.1Î÷îi`ÃI!‰ñ3˜Wb #Ñoâ³ìÈp]eu‡S6Å+’dXˆ¹ºÙ;’àè"$Ÿüşù×ÍéÎn™Ä¤YÌ0å5^ìÎè=½r7—³n³åD”7±·"*txœXæ.jqxRU+ê22¬'º.Ëûşi‹ßÓõ€Æov´.åŞèÀB0l%ìX]z+9£oÑ‚JctÏ¥5ƒÙÆ‚‘Õï)
åÖ2š¡×ÂÍGça7tÌgY¨Šï¯ğ³o¢êS¿¸×V$Xms‹Ş gÄ;<k‰?
³Œç¿õ>_—ÜŠ";AÒLÖÛo¢ıéOéG»Mm(]N'8ÒÈë}Âµ¬¢¥N¼÷?Oõî Q¾+|ËñÉlÀş¬“&Â$|IMé€hS}øv*»ºviÿWpÎ¿’Ï«¯qÔÏTÈLêø±EûİÔEÿçëÁ£–RŸçó‡z5™9ë ¢BìJ®»àv¼*ŒØÜ":ŞEXÅ$q÷+…ù•)áW¬¾–E”Ô¢[z|©æ¹¯NQÙ¿‚‘íŠğQ'»m¦jßÌÙœîfİMFföúôtn­êCAÊIà—ìŒ+SöÕoj áºÍ'ë3¥}V¡|[¾•1V%Ñì çP™oD‚8;Jw¯Ãæãa2Ğ¸z£yEW:]H•İwu¶ÕĞOĞéfÀmOJ‰¤*6ş¥âŠ<ªLïï§uŠ¦s‘½´!(¾]ú@°XËÛ³	ÿ*fv T§dS7¾A»M:j“2ò–gó<2×_[ışê Ôğ§½ü9]8E%ØÌØ¾-ë.®çT–vŒÍ¬‘­¾;bavóµ“¿6=ÛöøÎ^RS/yÙwDV9ş;_µ±k¸¦‚ÂF¯°ÖK2[ÃĞ¨Z&s 6\3±‚›ŸĞê+^Ş‹Ì¦İ8ePêûìøƒ	h!év¾hëŞÚpßQ$‡ò©TõåæyÒèÿwÒ—s\™Œ}•“üüÌ•U|†S·‡|Ë½,„c¼’»¾®QOæRKV19Æq¤-È¤Ì‚¬ /*D±3F‘ÕèI„Êí©âYX¥=‘Õ– x“‰&êi**K¸ŞWªz¼ƒÈ„‚D¶ná€º}JmV÷ õçvÎ|÷ ±Ô…;¤¶VÍ»² ÷¬“‰7½>ÔùÏYÅ¯É¼¬»]ÍfÍäQ–!¼ëmÕ}DÂ%¾å]¶1ÀØìÔµÏ	Ø\&eİœåˆÌŸO/*	³ íÎE·ÜÁŸI³…xzY”®m´ÁPäú>v}6şt£6B–_/ñö|£úİT6ûoqíEš®#¡ÃÛvË£ÅÔ„p#?¿°.„oW÷Êoª‘Æ›1ÒmÈ•ğ'Täù#´ÊZĞ”ÍôšŸm€opXİ™Œ%–µz£´ÊïmzCH7ñíİ>ù°İ#¦B¨J•$Gè>GÒ£ĞÊ†za	…şÜwıïzîOE–Ù‡(ækM˜™×ƒt@©hvø^>[‚”-QóS+¤+Oég|;"ê9ø”Jóx<®¬ètÎ•ö|/Ø)Ë¼S‚.ãêOp¤ÀŸµA$LÙŞ×øŸŞZè6ƒ?H®¯»
· Ã‚×íÏİ(Ÿe+„í3½á«xŠ+D<“}GıÿiU–«s"«zõ¥@¨ÁcaVÙ:ŸÍÙ+O¿¤¸n}²y¨}ÛİQ8Ö0îIÀ&‚Q/Û´V˜ŠÁÔ)I©¢g¹†£;–ùüh=5½ò´‚¨a‘“ Øƒİ<–2i*@ñÌÔŸ£’¾õä}V(¼ üYIş€!WŸ9<"¦Y‘2ÂÓÊrÌn”¦ìÎ¯Üj¡_ûÎtp’²:\gÉ«V†[j³4æÔ·ğŞ‘±/é7¨:¶MaXxO!l-ìHòÅ¾4wÔ  D5	ÚPı0 Ë€™eåf±Ägû    YZ