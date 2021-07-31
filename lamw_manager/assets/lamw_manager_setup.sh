#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2250037098"
MD5="3de3d60e619ef07bfd4cafe6ba5f043c"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23412"
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
	echo Uncompressed size: 168 KB
	echo Compression: xz
	echo Date of packaging: Sat Jul 31 19:56:01 -03 2021
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
	echo OLDUSIZE=168
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
	MS_Printf "About to extract 168 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 168; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (168 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ[1] ¼}•À1Dd]‡Á›PætİDö`Û+rco²+–ü—(}òˆP"é/poâ	©é©y:Ïf£ÜMŠ¨¢õVªG7°Vz÷DL"ˆÊµ$5ªû‹úßğjA2¦f›ë’«2â`qËë«)K¡’j—¥Uï\k³?êÀJÆØ4aÛiGŒ!-Yc#+SíD§¯#›Ï“ZA0£<%`qİ\·.ßY‹}ItóªÍ6¢q^¢­<Ã§–©YbKË:iQ×z*¤Ê? Ö°DMí¨ºY¹ê›f?WÁà¿îŸ:gpßVH®ã@¥·t–ùÑÁøb…¸E]Y!”×şfgÄó™g¦§)ç:§Ú_Q³œÆ¼¹S¿'=íÂIèv-¹ŠV´b@káòÔìšñlA <
/f:÷p â¹Fhõ°Ê°A¥·ğ«ÿ«®SPS+!"ş¶o.å¢ì×áN:wî
Ã	PïÎ>».‚Ml]m`¼ífñîÔıáõQLå^ujà Ÿ%±¥oq	,ÂÜÕ[Œ˜3P¾„*zô·(kşÔKŸ]xÜ@½ÿ«BÄU¿Y)-³k¨§¨V¯Æ€\’Y1.E°p,7éu÷±–¥ğ”ßŞ(Tã¢°ïô^­ä‘¾OƒxŒö­+|‚åãú5¶“G|”D€lÏìÃl»#/P¹@§i/ŒJ?Èn&«ß­ÊÓV!ŞÇ¥å–{û»¤=sWÁ(Å{
ÌW&Ÿ÷"«\ÏªşYğøXZåÛÇ¢¡©
õ<bÌƒ…0ÃjI‰V{èY˜×l:ı8}á†À ^uy9“»¿SÔğºİA2ñ^zÁAfı5µxL]ö¯"å°pİ‚M~y€pç÷˜	ÕÛ8 Á6Ô†!ÅAf°¦B=bbmš„PÚ3àéî8Ò”ÑEæáîzbV¨<‚ŒâÛ¤7$òÌañSŸg TXÀX=ı\äÙ‘	?¨1„â:Çûñ|µãĞ%7ôC-ûPqE°¦6€»Õ–ó8uÆö¸D©Wçàr ê‘äÆ¹§G2>ĞŸMärá‘vPQSÄ§º“V
†1·aˆãÜr°Îß]d´•#w7MfĞÔ
h1J‹ Gâ’Æ0d¢#º„æS\l:~ñìı€'-u0¤“$!anİz± H‡šŞ½xÕ’ğtŒ)\ /ü034ƒÕ2kd]Â¦Gf?Äªzyw’†:z ©”åköƒø/?[&Mc*€ÍÕ<½%î$Ê0Ü”º&ê L{³|eŞ~QZùÈÆB66ÇšQ¬<:\V_§ÀômTÑØød`åÏÒBp†ãèÀ-šÜÃ÷ò€›cÌ“[		
(™ƒáPRª´'ØõAÕ¨›5a>ËVÏ¾5}áº!è‚ Ø¬o.)BUÓÃ=){®1 >{Rwœw?“³¶‘8>Ğlí*>}4‘t€Fj`¯Ì&/‰	À rd„år§ÊBköşÌ•°–‡”=fá•:—4!sK€!3ô,ÕZ·co2¹ø·à>5ÑGk˜­ùÊ~Ÿ5âÊdzÅ7à•]è<£Úà˜ˆ­Låpmü¹ïØ‹Ù»w™=Â¤<~^ÂV\›.äÿS×µêÍšQ¯¬HlnÚ¯L™ñÖ?^Åšt˜„9»…"x‹c±ˆù¶û)š¨'ª$Âk“üÇ,?î=ÖXK]M­ì¶ı7>ä;%ß+y4ø_˜€c}øòz[°>q¯k!é²sn¨_±èíïPê`T¢÷MCÁÊ¡§PX,!×ª¢Kûõ÷eÎLø´1Æ3Ì{³@!“ÌâZz6	/Ë¦xíÇlŠ=´°ˆZ	³ƒ`‘Ëš÷mxÎLàÅ±Í×ÙŞ)Ş„¾fñÔ3p‰2{°t¹)`vôØ×G™@BPÉéã‘°.¯ÁI‘¾ÅZî›1Ë=´Êİ'6 ²Iù.²Ï›Xà>¾i|…‰fñ(·ë;“
Œ.'—´M=¥Ş[ºglZ£ğ¬–$©
S|QGC#€J¤­eË¾×b%²Jüdã‘Ş4ª>M„ÏÙ«§ûşb¥¬®Ô÷!ÿ¸«–¨åbÙWÙAÿÄ‚5 m.äÏ™cS>ê „éÿB¨ßS˜¾ğT½3…°>^a8<q¯³óD¶7˜äñANâ¾|†¯ØÜŞÜ¤º8_¯ç4òTKÎ"Ãëƒ^,¿±Gà‹­h3!äD7ï¿ Ğ{Vş6CVcfÆ¼™©2üu A¹Hsô8AàµPa (Â7@Vˆß¨^¥jkÅ¬¨Á@¢¡~Æ ©§uÿWĞØT¬ióĞÚ	şB ‡³Ÿ"å•ä¸iwQSàİ*D@lU¡~)ÑÊj¼åQ9!W/UU]Ö`§Ñù®ÕïmÀÚt;–˜®‘úŒYqùV*ó¦æéLD	±Lˆc¾1Jö¿/ø¡º¬3^\1ûwÔæ`éëGß¨Ví!Óğ¹'T1o7‡K—iÿô÷Z†K-ñ{%w{ıv¼ˆHH—»².^WĞ8‘AGbš# ™[XV)¶'…3”ŸO¬ºuî¶Ã/Ä|İQûˆ¬Úö<»1¼wGõ_d‚ê.<‡b±9P#ı¥TœÒÇvƒ<Ç7ı0nM³l&>p™uÆŸtêÈ¸PcvÇšyt‰3¨PœÍÜt¸Jµ|¤×´ÿpê¼‹Ì0Ò1DÄ´6­sƒ¬XxQçó¾»\"vÜ;H°´¨¸Ş[ïãò\¶¼Ë”Y}‹EKÖQaI=İoûÕM7~t_¹G “£uÀ—J¿ÍE–¶‰¬ğ »Ëorq¡yP„÷3LP`XbŞ|—Å¶_!X€ùMcŒhVí“o¬V«Âª”F
ËÕs’ÑÍ@—6_0›-Ò‡âãLÎ1ÛÂ1ÁĞê×u2V¢§ 4İCú7­Ia{»!”ö1ŒşH†üc,Æ‰•w&×áäSú¿£MøçâTä4!¡ Cæõ8*SÖ,…PfÌÛU}Š…“BÓJ÷Ñ®Èı¡êòŞ]U›B†3âĞí•ø>2*r ×|£ë²°!G”Œ‰HTù­ú# ÓÃ¸„s¾{àRº'.XäúÄà‚²pu|ˆ¯ï™Õ«5YÈ*“½DM·¢]Ür›;kÒÈª:;ôF&¡+Åˆø°…K˜vr$ÜDv‰Ú$X,ÁÁ9‹ÿøß%Ë»²—l.“?'j£ˆú¦¸Ôg6Õ ¦óÂ3¦ÜàUœQúkS£¬àFÍ5ö)—¨=cäå ¹#àNdâÎö"ªDñ˜¼kç®)ÎîirÌâ)féìğ«o¯’cÕ°tI>_İUq"†ßÃIÃu‰ò§—²16†:±ìdâOÎ“ÊOcõÊv"kO°KâôcH¶È:bÛTaö`·¸<¤n¸®xÂ> éõK–¬…sHB½a’l«ºN‚NÖîG>wŸÑº”ªÈ‰‡|peûU=?ò ¼/¿Opwg›x­6°½oÎR/ŞP0fbíÉ¥…ÉmÉ²¥ú,¼ş(Ğê?^”dÁL^8BŞ>eB[Ï3K3J¾åNïú6I´ZÔ´"÷p§›P›Ğq—ÄaÑÊ.¤úğ«"º¿ây²s¹=Éb:ÏÖ%0…^áU?(#ê¦Æ*¾ôvÉùÓ”ü±Ò”E‚/ 5ÉéZ*¼EgÁÈ·‡÷Gh2º€¸½&g t¶ÑºĞnÇË#1•»õ-vš°‹Ù4s5‘FîQN¸’Û()¥n%é>Xò0æ¼n¢Ä 9{ï«ƒ
Ùè§v#F\˜t¿çñhpÿÓ…tR›ÂEÀ²Ó`æg„tQD/}¤ŞïgmË¢jä1õ0Ô‘OOç@8óğHÆŸnG‡×&¤¯:ÌŠ±ÑU\l“O;ê¹ât"G{Xîª&¢û1¨p/£¬C†N°7	¤´à†˜”…œÅeÃ™z•¶­¿ÑG¨`É5âÎ³A Ÿ½vW:½"#qÇ˜ÀÏ³!r!R2q¿%ap5'¶ÅO	5eÄ2ÿvÇ
ÓÉOemŠ·²m‘ÇMkx¿.Ÿ‰È1v’\vÍKêdÖ±*¼B·,é9JêkôGı QêÊsµ°Ü˜òz„ jÆ44‡ë–×Û¶À#ÿtüR'÷µ¯s^Ù{|Î8Õ¨×[¤_‰‰¤õP“ş&‰ëpc@Ô£Çüú_´ÿ8²úŞp]HÔGá[–<\"™9ûR±nÚ×4İ;Jméº xĞx>¢nÆ p»gÉ²ÖŠÄt}A¤œè™˜Ã!àpç*¹‚!obóùØO<lˆEıŞYq3¸G	/™s1ƒ¢W+Ó&¶Ã$àã9| •ÿB
Y*‚Ê’áUïÙ:Ğîr/ÒÓñ:•ñšœâ bHd€]£ĞÌğØ£H&H4ue›,çåÒ2í ¤	Üé	ñ9´Jq Ø»œ°bQfa£LÀD'¦óX¾)qÙbZ×ü¸şŸµEbwä­î2l­µœ£c6¨4ÿd[MŸEÀD•ÔÅ†÷ß_*§}FsÅ¹P’i÷¹-ÄP6ô—î¤j†~Ü½Ñ@Û›ÿ ²!˜Ä[°ãwpJ8í¢r6Ò±÷œ±N€HÁ|¤…™É÷«/tñ:<ƒíıÙÅsĞƒ±¿é&‘h+s®×Â4!ş7ÇûÂ2Ã8¾ú[çæÊ 
Äv tP^9B%/k¬%@\än5ôã`*0æ«:½¦ŸB‹B¿òÀnÂ;‘$?…x…,Zjú½š«Ê]b¨Ï.éâsi2óvX´XÇQ™äñ°o80hK )µ`’ğvYq×.¦ŸÕÔWVŞ¤äÎÏVCn^2òÆ1U)yA
©«ŠÂ±æúñÑ§¡ÚD¬ú—	µ3;0|NçéË~®ß€Z(½aÿM»U¦ßŠe½BrÅÔ„±/\ëqÂ%y;EÄº¤Á*#³`¿H·ò î"ÀhMÆ½I¤ñÊŸ‰ù.Ãka˜w-H=—ğMUAu[<‡×ÍhÊyI„$
¥û8ı»U^”N È~›DäpÕÖ	zkĞÓÃµÌ\«š˜¯B¾z*m`O#E=ïÕáK$^D$o<˜åi¯‡ìÌLù<PRq”Aá¤n¥¼ô+})-Fd5T®Ï¥l:	=ˆº¡›D.32¾c¸Álï®I)‘Ò|BC*¡1»²îo?bôjìÜı%¤ÏˆG5
œ¼½AhÃÃ„¢‘l˜ Yér+b€Õ7#–Zv&\mÊä|WÿšêPfâ…«•á]„ Ğ1Ö¾İ²8!_³Á¢34E)N¢ t¶³¦y«“.\wQícÔ–&Ğ#ŸI‚ûçeÑG%È Æ'ÔJâ±fT4{¸¾¡sÎÅ‡?ÎZ|Ü¬…ù¬Õ@•A“2×éàü:<=ËA¿¨?4ê}ì»l]“ê]òƒØ .TD<uX†#fMàú›Â?Å±pÃ¹®Æm¯c=ŸêT° _È†MiF!ŸÏîTa\­¢©jƒÏµôŒÊ¿Ä£¡)JÎıxkÛ™¹ßöTÕg1¢¥û}°1ä½›yŞ¦î6BôÖ¬Gª_£{6é‚Ø©x¾5R…YÆ‹Ké‹à^WÚV*–®‹àã–iV>*k1KckÈ¿/á]®‰‹BÌ•P®{¬‰o€m®åÔ¿BğsvÔf’E’øbgsÒ¬¿1ET¥£g•ßX“(ê,v–	‘LÒ8v­ÖJ…¾ãGmÂSÉ¤sˆŒÙÅ—\«hxÙá{ß±ßY‚’ºVˆ;·ÜÚ»SÎ­¨’Ú®»çD3NkÚ ^Rt\çHMë“P×$b/ìeoºö‘WærçO>S’ØÃTËåwğê‹ÁÔ÷×ÀI!}Ñ¨Î‘/U9s—æ.8`è‚„~A:›®.Ï)5¬|+òóÀ[/ATğĞ‰36XWû›g¬Ù„Ùzg"½SÛÆ>ï¹ »kÆg°L‹-SnšŠiÔ˜ 9"í€û…EÁ3õÒBTë:Û“$ğê`ÖßÔœŸWV°QÛ93º¸h’HCîe=t“b£§î˜6{£½hO1¿ÅnØÚ¢Ö£Ë·®^£øb]R©OŠ!„â~}ìªhœ£œ– Ğê2g,×p(ä§oÜA´şI%{
]ØfşÌ‹m´·œTªë6Ğx¿yò¸PS&d;QÕŞêŞå’Üu£!Fcû &L]´¹HHQ].v`ä¸›¼°ÆÏiÜ‘3…D€%ü‚é‹šî¸:¯»’A³Ğ.ˆ~Úö7¦YT±Â(,Z”õté¹qÎà{}m(9¡qYDág|PÍ`ö"w.RÌÈúd_J¿TŸçe4XÏZ´‘ta=R“eıL‹¯µ²ò×$àëç1nÕE¦5Q…“@Ó³×/OÆD0YŠÊETô«ÓñËïÂ‚Æ“õç£ ¢gÑ„Ø,æ¸xwş©Ù>vÒ³6½$•®t2Œ÷‡7Ó[›nAcKÈwÛOÕ9ZóEÿ¢¯¤¿‹d¸AÁ¹B•äƒƒ”ç÷F5ù÷Ã+Ü^ÙK‘yDxÙJÿÊ5rÓÁöË5Bq»ÕK	ş–©òãß2‹+¦ı:ç+%™˜,8¶î¢Uø‘éol›*1Ñï±êb9_n¸•s"àéqªÿÑK`&Áz7-€øË”3“<nR±‹ßĞ§9>.‘0¸+=Q8-Ê4•80‚ÚÀô'V Ğ”i½'òÓã+°O‘kc–qcÂÿ¼ÈYPi¹uâ¥P»X¹<Œ¨b÷meCcÿë‰½®IzÓ©F,ÎoŸ'½×IöÏT.3‘Û1·ö©C U	3¨!‘j6€ È%Ïw§ò¨Ln‘¸R7N%“¬Ïâº£íb.±£d÷»Ï§nzdİs‚ïèò2NÕa'°;RÍ>¤ùŞ^\,™Ñl–J­ïÂ¯T”wo²ÛX§Ìì@z‘ü3 ³<{iŞÕdÄ®¤ÂÊt$ŸÆ@"ŠâeÃg«=Ü	½¥“Î³[RK–°‡ïŠûZÛ£ğ¢ºë³Y£¦áÂùqŒãŒÃşºqFAëÂ LYš ÌÛÈ{­>Év†;¤hÃÅ¹²Ø<s©Ú¨úÌ‘ßS†ß*4ØÕæÑ*„ñÓo[×Æ ÛŠEèïâ–à–µE%~|Ï‡45$p°é¡¼¢·æ{»Ùó¬pÏòœécEğ¾ÏTŠ’ó‡0‚¾Õ¬½íeÍÖÀérvM‘ëE4BÁ¾Vq…½O7*lÛË\-áˆY€„dÙ3Ã…gRøjÿ»æœù‘ğl}j¥äúÄ^ZgŒˆ=[¤ü2Uå†}bH³IÄ‹ô6cïf{0ÌêY¯¯R|„ˆÔŸŞY~sÈ¢€qÁíD*ğt›üãùŠì‹I—YÚ¨¸oßnà+{D¤9•môğîb:Wk0Dç/l´€Kf÷è$´[‰©‹éÉ¤D•š»ş¹¦HqÑôJy¿ºò~+ÖÁWV¯Ù×)VT¼È„e=ı]YAÍ@WÍù˜gØq³Ëåº2Ñ")61¡‡V›÷z¿úQ*´*¤"A—YİI2N8LnÈ›l³Ä/6ÊN*«¼¯´=‡2;:¥0ø=¬o;(í¥Òkû–a˜©…$«i¬Ø×R Öx ³ùïş¯/ÓJÀøwO†óG#®“…ÌRV¿_ ­¹-?lV¢p=oÁ”\”ÕWR#”µjqÀ&äøHká­hòÀåÇ;s£¹Îi9„PQé¼ˆ»Á`ÛÍ˜ 0jÛ˜Åm7ú|ƒèáÎÅhKÄ•Â¬Œ'¿n©’ä£N
@Uús”Zäö!±c•×Ÿ<Ï4ŠªC>Ñß£8§1ñ¹XàÔóş>h@çş¯&¨Ó‘!šïí_vÅè÷äª¼Sî©D†õµˆ2ØÛü’sy·5qû?¡¼Y¿·ÛjÈŠáÚaÜŠéëP–{G$ßv¯Ms@÷'‘áÉ»Ğ‚á¹´CÀJÅ†jóÄ†6[Òéà­û7?ÇoÃì‘ö ÷~Øb¬¸ÁìşL¯<ı#0â&=J—äpÈ7I;ÃTuyÇµW§‘Õ„S6ô•ïT1‰È½iJKeõHø¶´œ_d5^:¡4ÆxU¬qÚ+ aIR8ÖÜ$ºàTĞY@³Å /U-·Á/Ÿ¼úÈŸ3µĞ(m‘˜›ká¦S1cF­ÜKç=Ù‘§„¾[í‚õéğ9èı÷kª‡‚mq§ŞM7¯Â%mYî¤ÂºËÉ–r/¢ô‡;Õ}Ç«5š/ àçş\Dÿà(ÉàÔæªªQÅ¹ô[Ó‚¯ÆC5½«ñÂš³ËÏgf?1ğUÅ‹3Ä&ë]Õ›Òœu\wõËµ¯vúzŠreˆj6òÁÜÍÛSÒ­3ü¾W>ŒJƒ’ş½Y*v:&‚!ÊÊ·-v®89½Ìò]î¯õ$0E… 553ñ.³ Ìf.™‹×;Å>ÂP)îSãõ¢fJi<#m Ôy|ü1‡+¸­áDä¬5‡•èÅúØº­Ó¦·`Àœ²^â§Záù â ºòµøÄ™pRª©Õ¤Å`Z×!mkÑ ƒšÅ@ÈáE}È9ec,5(¶¤Z†Å¥'˜¾	ÔÙ£­¯'dŞ5œ Dùù}Vó+XÏ¦š5 ÆĞ»úkö.Ü[‡5äúîµªùŸ	³Ü(æ§~·`ª'/ÄÍùŒâgg8KpÆv“\¯½3m¢ÔºËI!²ê†à`çÑ’Ÿ9Û„”çØàº61¾¼»H¿"Í¢üîöšaÁC[— ôAõø ú‹Œãúİ4Êk#”+¯µÑâÈˆk¬ÑÎCp':Nó|²-ò8²U<÷=·¨j(ó‚ JÀ‡ôµúÙmÄï.Y¤Mq&@—€ÿxÿe21ÛzxÈ}ÔÇ/°AÈÊOX‰!	{O<_…«Øö–g¨çÚ$º¹#b‡Nô"*Æë‹óUCñp5úÉê{i‚KJÍ7ÌÊmÈtş—9r„Q—NLÆ¹)¸€i¦$ù¨‹Aw4İ±ä?1Uo5‡b‹0ñm A.%P‡Nóéõ3;µŸÙ0Xçú:—0öÆÇDcƒõKü¼‚v¸Q:uê#{º8­a'ô"x0¢4UM¾KY»GZi À}øQŠÖ=ºdïsNø bhXÂTØd»EÃÎ‹†ÖıÑşwïÆÛ¼¢ ¶ï©¼$Á‹ªg2ÌÙğƒØ=fƒÎŞ¨æ¹õóOÖ}{‚8gCI5äLKˆ60ú¹¶?¸ãşK£1ØÈ•”“Yî™ÂËˆLıõr
ê¥§ã]î¢<Š4´æ–üàk·à›y‰F xÂ$”É8ÍfÔÆF¥g€S‹n,Ü£Ì7úQ@¾n?ÓQhüòX´«t¬ó£Eâı}Ê‚…‰ıûéÛ+IX°`C\ftŒP•Æ‹ê(°ÈÑ°ÖŸ¨¾r•Dí»¨«]ïTQFó„¨½üGÅÖó·_`ö'.Óí‹&ä(ê{5w>Ûÿê‚FÇ!g:eÉæ|Q¿öõ¾äZs¸p„¸ãø9“+ÃÜ¶¸£¶NäE¦ûl…¢+Ò@vièm†z‡¬X£@˜yÛa/ßÏ¤Ê5·;‰“Ãß)¹Zdqß&‘„*Àiwş |haÁ®ÛÃÄcólAkÃy4‹ÒX$ßghD‰ã‚| %z¸—â÷×÷Wâ×ÍZ‡–U,–Dı+1cCl.,%™T\vuEÉ]¬<B<‡á”P½Nò¦æ×e;ıUŒşİ¤Âï>¡ˆ­3Û¹”º’¤Ç»‚“"(÷`ä©Ùi“Òfu¸¿¿B‰Õ+ª²<„éòƒs!B¹­MYç­ò«áüTád4ã4ŒßçˆVş¡:æĞ6§Ûîè#¾™!79ªø74’†,T°øè-ŸîªûõŒ$zšŸZåmUgÈ#6P¥b³Ù{k2o¢híÿ¾
³0qS™Â	§o°©\¦Ø'JI«@ÿZR°9ç R8”Z§õöòÈbi?iö‡ğ¿Õ?Ìá«—E¡Ñø´ó2¢m×¡
R^,¤!ÈŒÿ­‚#xzY?;wÈºW	«&‘4¦l]3)F]Ÿ°ÅûŞj»ï>É/¹X8„luGzƒüC–J:™ü­l_¸Ó°vÊ!(PsÉ„'ı7-½ÎÊnL{%yx'%15	y¶¼É·<·<ÎOš‘€'w‡dñeè~<‹ü(ÕE|LDKãk.¢T¢«T­ú¡}Ş Ù”ı™¨ÕV‡Å¡İ`yşd6;¸8&˜BQapXÜ’¹Ryñ?şø+EÎÏƒòqYfYKä Fµ-¸—•¼'Ùf>Á° @N ;C*„ëms¹(hm9iR:§ÿ¾ ÎLû70b•§áƒ¶kf+ø¥‚yËŠØvK›zé£;ô¡¶+Lmàëc.ûĞWF†'S(t§å.ß>wæãĞÀAñªw[“ÕElrô³Qµs˜¦zO›;×*ÿ,ÎªÎ¤¼•K5ß FŞä”·‰‘t…ØİoN î÷şÓWğJÿ	ÒÖÒ¯ÌüÖa¡0U…^éôDºás‹Ng"âriĞztWŒvrDœ=8(8×õ¯»ÊJİ™f¡ûn]ïKTëSVÕ[Qí‰ĞäÆ×8ğÔÄ‰xæ~µÙ¸& ¬šYğôÈ¢Õ7)¯^VÎú'#ç„ŞFô¾$wm[
±ıy›ëäYs/Ûƒ7+µ‰Êa/z&œ#}¬Û >æÕQcÂ%­e [{KçÃ N®kÏ—mÜ>ä˜‡ ¯üç£Ş¹GùŸ*Û!_ìŸ:vÁc®·óv<ügù\îR4Sáæj3°œe½7àÄh¼3En>ğMªU‚ó×œú’‹BŸ fMŸC‡¬àÅ(ğ€²Õw(zŠÇ¥ò$%}Ò`”4Û(°áR¢ë]åëd›øËìæ¿#d	?Íi˜®ŸèD"³k
*?µGüÄIıLícÚÀ«™s8
c—ˆ-Š“"ë­ú¼\~-o›¦Øe€yğÉ2%7¶¯ÒQI?(R8$`ÎÄÎŠş&äOX{}¤¦ÜÔ2n_ûdSºÕuÓÙ -“èíÆ‡ÉIO…€(µ³{Ug¯ÕÚœÍ#Ö;´íäU³0DÕç²K´NÚËl

«Äı/‘~¶oã><ğšÅXâ=­%’93|^H÷7iÚ§±ı+ópsúqáş„ÎìÊ˜ôÔÌQÀäXrEŸ&•0Ş>f3½2<Æk‡¤©ğ#+r‹ƒ…ë™P]‰mK®"æG±ûNSNó,“Óê÷¾Ùu©L&ğæ1ÇdÄºLb‡³SW»cÊL§Õ)®Œ)C6yŞôAæ Pé³5î¢ö¶Ju#×ÑP®´R§°(ÂTÕqÊ‚_š\Ç M•v€óäêfX)AU»–ÖAhfz´ƒåY4wÆUYCöšoz& ¢¿çL­.9F”¢ìXáòWËì´¯öq¶‚YÓ­§Ğ“•à&ª5
R:+&ûÀÛ6&ŒÊÜœ[•Co¥¸ªÌĞ áV,qYI=¾[ÄKT¼o,Y·¶­ã›Ş„¥¤Ê¹eŞ_^ ¥™´ ›D	\Nµbç |¼Í2Ú,½Æ*Ğœá"7§²„àÄevz¡…ÕĞI'Û²Õê $mI…›GMÊº‹L„A¤h”éÜ÷ì=e–œ¨Æ« £••vâèß_U"…BoËİıLò6!‹sA¶ßå}Ix$…Æúøv=)áŠWò9ÍHÖ¬\Ôî8º:”¼èRyŠ1V¥É“v(FCÅîS“‡šy›
xør¸çöw Øf	eËÉŞ´`«ôºöhÁfA>MV¶—­G(·á­’l7ú·QåÁğb\×ô5]…ÓvQ#X7=m=0å¶éúsİyŸñôJ`¡nóˆ!kü‘JeÌ¤_iÀ¥n|¯;ÿ¢ \­‚ºÛh‘È„a43B$Áı0ê3q»¡m› ‚aŞh—T—i±áö²š°|„@x•	
bÈ1Š -d´7¯ y'5÷¯à#Ï¨NÖ{ËÄí2ÿóšŞÅâPqËƒÄ>Û8’ˆ±¨wM‡mŒB§ÿëá°xF(4J•¨Şñ¾B#ğ0#Şznò”ëÂ;µY)\Š’³ ÒÄñ|E$®½%Ê^íÌŞğÙÖ}ß.=f›y]å>OŸ'óyn¼ZRæÍ]3Ÿz”Lí€ j;4[%;	Íç0.ãŸÚ2
øC)Úc¶¶BÃ1ÿÒä"Údºõ|#h”³¢}Iç …%È>àÙ	Ù}	2. ™9MÕ”ãª
øzüLtùñ¥š„ô
®½—Ù§Ó2ü*Ç’S¹(sòŠ–ûC#ÛÅtæOVÔ²ÚËy¿ÇÏm6³1b‡†SD aÒ–¼.’i [i¥½nÿJRŒQÂ{Á4q¶Êı°ÕùüìZ™ÜÒX-_Èğô6czÓÊ¦ZÓ8(c”GëáYdYÜÄ‹ qÉtDKşœæBºdGÓkJDƒ‚ŸkW%k0Á”*’ÛC3G\ñ!ä9Á±}ÇWÇ,¨ècóÅ¦è®Ï æ¼8@JÆ±»±Ú>¯–zü‹«JñşòşL5nªù-M1¯@«tÃÕúì=~ğ­ë6Òè‘Éô¢—³7L‡¼G“õ­L&JD:fæFı~±½¦F9G fpØ))—©‡#øB#N&ˆ¢¨,PK. C(Í¥“0g$fĞ`ĞOÎ=>–èÂã4Õ'¦‚²~±%ê¬[Ğ  ©ú”Çó—œĞOcûÊ†²¾×Â›­ùq
	qÖ¬Ô%$R‘ğ’õS8ÊP’:Pö/*|UÕ±,w»b² (8¢Ù‰ßx?Y«iVe©Ü‰3m|ıxà‚)TÅ†€#ZÇ$Èz_w¥#™u`b‘ñ,+û:h#ê<nnÎìŠújXsO?’6-›e`q«áWŒuJÄcÕºïÃÀ¹ÿä9M„F*°`Îïwb
ù£Z­è>Y´&¤O;==BÒ®Ù–{ÑóF”üœğ8XÓŞú<‚nØ‹b?‚=3Šœ£ûudîpóÅN®’%éé&ÎFÎÙ~„ÜĞ ×{=‰’Î¾¶8v¢R¢8é£Ëô:hÔé\ÕóÏş+L€ŸÈÃ%Ñ¡R>Æ·º“ŠŸĞ'¹¸-q™ÖR÷x¦6”—#„i©‹­‰O‡+}ë?”°-ëû.B~Áæ·R§ô\Ù{SÙÍQ õrs1²¬²®ëå,+gr¨ñ-¢Ìß®¡b;GCËõ“xkœôN¢h*ø¾(K¢4à’È†}/Ú¼ŸÁ„lñò—õûÛNEÿ²1}uÃáqFÓA¼¶Ù¬iFöx(«\ç­À}ŒŠm,…:‰^¨#Õƒì'wY¥¿O(¿KLp¾có¿:Õ½õSÏEdNéBvi5Ğ“sKDÍÉÈÇkáÇõ»ujy
gò~X0-Àaeàçê®&îw	µZæhán¶çü‘ĞŒ®/=Í‹ˆ;K¶ş%*¦óWgŠ\êÙÃêñôŸNO3Fş5"Kft—pW¼Ê4ïŠ€ã4Àà…Ğ7fö¯—»ÒìSwpíğÌóÃ³ÈÑ|OM2Øp÷æ+CÈ(á>‘mÌSëè³WèP¡œ~ÃêŞv=‡	Á3®ÆJÆ:iõ±óœ(#¦„Q7½ÌézCGEÇÁµÅÿ|3¸şÈuÓh û~Ušï"Ò”{’ã,AI®Ü~	C»Æk;GÅpD0D‘Â®¥»[ÉÏ˜=æœw#–ÒZåZ§şh¡Y¡½“\’Nÿ/ÅšÙiş>1‚Ä‹5åÇÃ¸÷k0Š6,n#?/V®œò–^-€$­³½´o¸|¬šj“d~‘ƒ¼8ídÕ,ôkÿg/PÆî«%ˆQå}‹®ˆä[iélÄÍàgÆñºœïsÅ—oŠ¨¹Õsè_	ócş¤-ˆ2¿
›8ì.ck êBqåĞoë|MFiY,Ó9JÜEÎÙŠræ4ODœNtØ·€®ùUâ¾ÿñØÉYEÃë%9Ã¿‘>´Ç—Jm1}'Y=<íÈ{úÄ„ôFäŞÒ·lYì-ócŞ£šp„H³_4¯Ë¯Öá,Q-ímìÀ¨jÜ× R‰çWÄG¥™– Û_äÆ×f÷ärÊ±Û5RW§Q"@úĞ9·{`ıµ/ AŸŞj¥ëÛb”a”ÎÔCE5Gc@–£—€¢?Ï„îÁlÂH”tBÄ¾1ıÃx3hSV‘Ö±&MÍîoŞ¸_ææ›/Ùb`Üî46˜M“ƒm‚rÈF#¯óM¤“#­Ö¨¯Y¨ğ© ­ií, fG²X×Q†Í‹o{3‰rå-©¹ès>dà_pV <0n.Jäx³µ"vnØÜü!¯ZT^¢_ÎfNIN$KÅıÄÁÄñĞ'Á~Â÷ÙßdB¾şÿùy¤ÙòşG5)øŒÔÂEÖ7í‡oİ3*±ˆÇüƒ¥I]dö0Ëpm‹èÙ\H…M*Q"Ú‘€BÿUÔUT¼Ìxd#f[0N_³(!WƒQ%¬ÅÅ£¿K0QÙ{„êzn\ aÑTı™½šÛ€kFiĞ2ŒZPpş€úÊ1_OÿÈªt…ğDú!’0ÂiÏûá¸ñN™#,6j_Lóf^*¦
'a´íbzÅæÇcÑá]GÚ•Ë7AZ¡#—Uvl“ÃÚÓìá€Ç˜.‹úo \ãÉ¿ŸÓzn|™§I¸óïŞöa?86¤n¬uÌ­3 üªVlÙ§|Õ«%Mtµk'o{Vİga
–)ƒ‘G˜b–,ìO­»¦zù[ >=úÉò3£ÇéÉåU
N  ¦Ãµn%ãÓÖ¡xƒ”q":Y•ö”¶´&¸•zùğˆ’33“R¿uÕ{‡ÀAœp»·—…Ôqo[€[Æ†Ìë`3JğU÷¼¨Š¥}|¼‘~O4N¦©£.&Êİ“®fvkZË¶jGâŠ×|çëQMœRAÜ }rˆÃ$ÿÛ…O»Zh¤´ª6î÷O©u‘GÑ0ëÚ‰u…T†•ÊÑÁGJ-rÛõx¯2Ÿ¬Û[‡aÓğ‚{Ox6ø§øä¯’»œWpl0³æX¾b–®‡·
)9väDm»àSîk¼FëtÿÎ¥O“j[—ÈÉÕ½úG£M£diC6Ğ…Î¤¸ş«ĞOH°d.t`µT?0şN+ö‡ñX®é) Éj°êƒêH¨%QŞe¬ÙæÊÓ>†Êñ®íkóƒ6/ò¤âRFÔÎš<ÎÅÁşÕÕÉ@Ñ·zñõ/…âŒÉ>—ş{°Í	¡„„²ìÂèÍ)˜<^-å
ß EKµávW¸u–	ƒ£‚äÑZ\Ó"#üÔòšë¼›)|S|7h’jÄS!9ï~kÿw1!Æ<„—zİù¾êR…484şœèå¯Š1â”]gÑ:@|ßw‰ä‹mŞµÜz¦p¥vB©âÙI¢ñ×y‹æP±aïî´Şà«¨L×±BÕoÜPÈº}Yyôa’ÛâŒ	ìgÆ´ šcKù¼ÓŒa$±’`xá@|Ç¡¡ÎÊsĞÏ´•4F«üt9Æ©ÿ§ ¤é‡Å£!şi¤üvÈp`¿Z²CÏÿ²æ¸ú™¯~38<ÅèrövoŒ<Ia¾{–8¼mFDÀ—ïş¡/ñpBÿa<AE`½–ÜÓ;j¾ºí	Ç†¯
±eZÖ¨vêí¶C.8AbÿWæo3‚Â2«ÌZŸºû›N‹î7™á&Lxm/N[îÂ*M(ç–aí
g¶£‚›å¡'¼å<cÒ"†zcCešÃÿ€F´…UÆN²M@w  ƒÓÀ©—lBÛïÓ¡9ÒnS„¬UÒÏœÜ¸J[åßc‘Ğ«Ä‰º+pIêÅ…¡Ö…ŞTwû°Ëó1X³8\Ieñ ½ı–Ã~Àšãcn+ÜâGX–®ÿ×Ãy-`iÉYÇˆsà©æ)†ùB:kÃ
ú}_&çO˜6¥èÖ¼¯Ğ=ÍwİvY¼µyW}6Xr_Ä9sÏ!E¿"K‰òŞ‘M}Üåû^z‰kÑÆ¯D›äş‡Ó½w?TV0¹Ï@´1èéäŸ1ù'(vĞ4·F¡­e%B™H–0´\Æõ!› ›'^!Bƒ¤f7cÏ>ãF×ÕNc¡±Â3,š'¢RJS<S&=ß<B+‚*Q	24Ç°'R´¬2’Ò^*¡–F>®˜äêø åD’ê?ŸÓqNhaDnc*tÆË	<<'ù©1FUå‰ŠVh$<ödQ k¨îÿRlsI‹¶T&~;¸\å1å¬øµQqáeĞ;üÀ>VŞ¥a‘N®nš}ó×ÑkŠ©ãÇ¸W!ÕÇš³ÕS—¸Ä„J§%k?põGÌF¢AëĞ5Êê|íş•&œ¢'”œ ?íËA`Ë-½+’Ü
Ï’¡ä³½ü×j­)mRUÃ*é}Q	À˜Ï@)„ßáz,·†ï»ÑCš{5:†Îzó ÖšÖÊ)¤,óœßöÄX'î7éè¡<éûà;%e¤Ûç”ÍwğX¹£Û9ráÀ¥Øş<!B‡ND¦C\61!ÆøÏj"8«¸ÌRX·¸=„õKûÊ³ÒSŠ–5r{õCÍ\½ÂÚu©+„‰­
q-ìš/&SSKğY*Ãç9Së¦PÒì®ovg<q¥ŠÌÊjbÈPcMæîºæ„‰*ÉÔ ó¾ºšuGÈ„ß+àLŸ…D4nƒ¥¨‰|xLAy¥È)ºÌ±Ou…[–x+÷²Ì°êùÊQÖöÆâgÙ3_ÕMÆ[54d¾ôüã¯°<ÅÂ	ÍğçŞ´&ôchg›äö%âRÜ|LĞuš(&¯&-';G`yÓpEõI‚n™jã
C;&ÿYĞ¾Ld–ÕşÉ‚'oÁN†>ë·xÇ2­%d_öÚÌÜ(Ùé|øuöX¸³Í~ñ2LÊo´ØŞÜáƒ¯úëy6—ÕjZêü#÷©®î-^*Ÿ¹«ßÇµº‹4ôŠ¸¹¼PT
iÄ2i•‚Çk¨(tìŞ%Åv1 ’ >½kào}w¾P(Æ/İ#5/	b¿QßğpìHôW|cäQŠéa>…Àğ,M´£Ç´¯ Éà–Ì¶{"æm˜²\¹›Kt ¸èâU¬IØw)YÕëåÜ=é°3:Úı1Òïæ—¹‹ †ùß·0ƒàV'tB¢7ğ^İÀw†å8TMß¤r( §ö;Öù˜ÃW yÕy “—RàTôŸB;9M@•iq	Ñê_¯‰ë2ùF¼!ãŞ(l‡0Y_m	6³ÉºQşk>±ÙûcŞè…[˜ê`ôû—-€ïËÄ"šàBH#9à8ÆT¿è.ëÀI|)å&	‚®„Ê~{º&:¡YQÿ‡~iÂ¿rvšÏ¨¬âûËˆ°çó¨ºi:DoÑ¯9• «¡ìvê;
!CûıXÔPgî­		\ËîÍNÜ¯K²#02ÉÊŸ)ÈQ›€?P¯ízÀ •±ŞßEMÌEùs8ÑÿF!ã²{Ù¯F¿(Ë®ü‰UTV¯‡ÍM+ì½×h?r“k/´cËü´ÕV×§"zx¿ê’Vë¼”ıkšk®c›1¢dZ
$l—i&€hw-¦ÔKfätò	Y$I›
6v	I¤KÜ=.§¾$@Í%Ààö†0ã‘´Â÷Øs†Ï</C¸Å:©ÜzçA`˜İß‘ïß›.Õ¶œBF®í¥?óPÎnc@ËĞım¹§¾zf®%kdcE—e¬Wµ/è­ £´geÉ*j‰±‹UËQ·@$l—fØR=7~4Fä¥ÆäÑjg;: fÍ¦Î{Nnõ‰ÇZl—W%ølnÛ¼Jì÷B(”EÖÖ¸üş±Û¾ZOŸ‰Ó2g/!$ÓÿI²ãÌFÔ¯ğby„§W“.Ç¡1çå9EÖG³Í“93ª7ÊÄî^`á'~ŸGÕc½-«Ô
°ìNÅ@d—}¸Lr…óKòoÏïk>ıı@‚q)¡ïÉñªŠ-ZıpÁ€æúü÷¨–âµÅnù_|º¤-«IËá0Ü›á™Èe$êÓBª}[ÂÈ-T…»WŞ2;Ÿ.ÂDh@¿Õ¿fár3	ç“OÖVS“cØ¹şfŒ„1d$™™-şX×¬”?å˜È˜JÄˆüQóTÊ3eQ´Œ-î )Ur+9úĞõ·..E:ÈÎ˜C]GqÍ£‘káË*Sjo›Æ÷0ó±†‡ÏõN6Ò’¨¹Ÿåpİzä4YóI`ù©ï–©<_°œ—ŒÑ‹ó´(Ş¬ŒÔD$À–2rÇ'ªäÈ$Ö&PFg%å,Á{İOU›p§l˜-æ,Ê¥Ìiº)`Õ{=Lx‚=³[ğè€ˆ÷‡©XB—æhÂĞå„z¦”*gÆ\CókiÚÙHU}<}ú@hş£ııë^=ïy½…ÿ×¼uús½}égvoÙP8±•¬!ğš&3,Ã¸í$ˆI^‹4]<hR\ZáGm‹T€+ÌÓä¹°fîı¤¼ÔRäÈVHê.ë×ğßM‚êjW)s©œi‹ú÷ç®«òx{Ç1<Ğ]–ºï§º|CmLôİÈ%S>™ÿË(
:OÌÆÉˆ¶ó_~ù7¿,¥è~˜<Ìèµ:)SR'#ÂH¾$ã<;…¾sé.ÃLì±)ö;ò±©µ”p.Q!HµíQ…,ØŸI0‚˜ÿşqw­^“çoÇÎäæ~É™ejDUJz˜¨úŸmšñ€I,—0âİqºèJ‹ò¥ ˆq°G‰PI(Şje˜?’ ›Æ5XU}~² •zV¿;<›Nö:c‚K!çÖøÄ8\Û¢òƒ±L±÷æ¼ÚpBİ¡keéWWzYvF‹Ïe¾Õ§†ÂX“Ey£é[ÈÿŠÈ¢XhW<¤³pÍ~SZAÔÑŒ»—*`QL¿¶=¯å•ùï1%}ßï;cœÑÂ‰sy]IÜVO°\R¶gƒ{&{VÕ‘:â+Ämi¤İâé¨G£`yĞSúEp\ÕÚ!Å‹L(ƒs”é¼ëˆjÊàhk4-›á(i´°ñÂö…ì˜9ƒ†Är]Ó2ŸÉı&&2{˜ëJ;Şİ9]Õ.Ê˜zv¿Ã;|B(+÷\Mºa0ª+_â©êªñZb¯fã„Àéíum¼Õ*™×å_"*İvz‘øq„a'"n“í‘ê¿Ğ²51^ÓK”¸ìuğTÀ.•6o^®·ëVÕ©¦—ûíŠÈ=¯#*!Úë_À¡AÃ$ŒÒ´ÛÁ&Äæe|ÁYé¶¸›iò­}wûÏa÷V¡—õ‰—ô‹}I€¿Ø¼aö€5Q®îµ9$64İ5úô½»D÷:Ät$ÀÌ²äÏP‘Û{š^(0[UoHÖëZDîsÂaÉpÊûMğ)4 Ç¸2¡Š/ÂÁ=FĞ„pÖkFE+ó(’îÍFLÕbö¡Lb#íU8au¨Ù'PŞŸÂË‰gšëH ¬]²iì6†m9tJÄí³uR0C\p±2GØ`AÕ´Ô&¡f‹û¥E-à›L4Çÿs³]F{»mş§¿£‡…,Ÿ'Âó‹•v4OLÒc%,d{;Ngæ'wÊÇ´®wy„»†9+ú.Z2 ß¶7ãâdaßLˆÒÚù–zX—–)H…Kf¦ v|HY-ã§c¾î~ˆéˆÈ¥ÅY^šı‡tÂuÌ¾ƒY¼ÂŒ	¤¯0ËH¼®’>àx0À4]Äõ¬µKŒd›RxwŒK®ØÆş:šT$z{¢YªËH³NeúNè©­óşßÖ†°eQ«—…b13BÂ:¿™jã§şG¾ì·zt_ØA QÑvÒÛ–»¸ÚûÊ•wVşİ@ÀKë*ÏÇÛ˜¦€6…6Ù“$<™>r ÿE•­¶3øVqWšïğ²ÛdÍRìm<˜)€6áIøÔ†Ôéå|ƒ‰q°‚PA/ùØŸ›z4ÔŸpQm4üç¡Ê$!rZ ß2†fÑ˜a`¢’~
ğG˜ç+]´,+)£`¶4Ê³ÉiúŒßLù^k÷­§Ü¾3)b?dxÎÑT	´mN Úßú»;ÿVgEÓ…!!Ñvìotâß|zú‚‘v×Š¼îÉı!/s‘ÊÄ$²)Ş:8­™"1–g§6Ìƒò.Ox<©5	*˜yîÙõG²g×*	gcêÒkñİ¸•˜†ÇV0şØÅõ}®áf0:m¼ì7İ€‘İáÄ<É®!¼šñì\?ë_»å8“äípîg5_6p’…£~¶}’Œâ½° çEˆ=-&Ùß{	8hã3È0f¿¬ºTé&MÎ®ñDû øGjâÄ­‹g.ælİL€2ú”xÊn1’bõBÛ
Üòı¾tğñ''€WDõ·‰Êú•Óe5ºİÑc !+¯ŒY©Evv²Y¥&³†ÏõIô¨—¶œœÜ®’‹öaKÂxö;‰µ·gGjjL®}ôâ¥z|ŠÌ9]WŸ™9ùÉŒdMÈ1­„úôo÷ÖÄŠ=N'à0¶[ò”ƒÆwÛ—£¸"ØÔ)îb©OÏw›0œŠ˜1ÛZ6¶ ì¯ß«úí$%"*‡¿Õs™ôñÉ9ßˆ•«ë}H¹åOS~!µ¤êYIˆlC/¡Ÿ'âãĞıLà¡n™@Xé'sa|İ\Š4:¼ês·Rs™Öê?½D.]wf«²~1,	G+`øõ~ûÚL ­I:‹;:_Z[åòšMNä4ÍrõÌú£ÂÌÔ)Ö+0‰şÇ."Æ¢røÅ«„ÑÖ‰•gPuõ‚eº´w`)aØ^«ÅÅÊ¥·ÜãUŠ™±Šr©Ÿm8›ö›Ôt¸¼""õ%Ï¥EPÉEK©ó}½Û|}!JŠÅU-+e[òµQÊH<·Æ»µµuÄş»äë;k$[u-è»ŠÚë"EZÌ§†4_ùÌ{C6ûƒ¨¸)|ùÑNÃu|{ŸÂ=ë¯[‘Êè›¤îuM@Iuáó"Ãõ³50ÇtIUã¿´;¨Æg	Ş¿[öÃ+5²œ²×Y„ïX{ù·û!%ÒaxŸĞi(apîÕ!+i8€”]Á"ssTël¶ÍÖCô­;å=À«‡áøâµ’GiÈ°jƒ‚wnet±¯øêUóë22AÛã‘çk-$ûMïÅ¨®WŒ	hÌÑÎ´ŞÍ>úqí*º\¥ ¼|Ñ›÷•£@qs*¤vá¹t›ÛÆ»Ä!ø\œt_|8whá$AÁàK¦±TKMç€:ÁÓ=nÉæ¬tSÌ©:ÂŒq<"˜
{yİëSjs.à°æ©$8l8Õ°çóq“ÏÂW÷Fm<µÿª{håL£§DÚŒ°…yŸ*ô%Ì’v1ñ|äğ#‹¤«í©Şù¾*àš¨åÀµ’ä¶_-è5íu¦\„ğËGcµî‡i#à2ê )²Ğc3¶_¨ó’Ø^ÖòŒ÷ŸJâ6Ğ-Ç’ƒŒ*ŠšZ3È‡wX}ŠÃ…î‚ŸÑÇ%¶á«VÃØ4Sl)ºÙ=ÖˆŠòêWÄ¶WKÕİ4SM(£ÊÄ}Ÿ•ì¼~–åôı¥ yÜ—Ú,:³aÆúñÌxQsñµªÃË—G¿Š
¨OØ¹ê.X»ªà>èa{¢–€şÁGK£×Ü‹p&-½g~$a¹Jİ ²6Má+o%S*[JC‰AË&fá!=ı@zSMÇv,@‰“7m·¡çs^£à=ªÆ!ğr»šlø§ä>ÈDŸíè<¶ı¼Ä^IıVÚ¾9/¯ÜÆbR	ğ»šâ¿ã–ÔVt›ş†çìàÍ¨0ımµ‚nc¸‹½…½±KeÍjãV@ú¯rxè¢
Aş­!b~ªkİNÀí¹èÊXÑYéÍLä­2À• ŸáP6q<BsÅâ®ä­2[óÎ‡®qšƒ#Ìãìb~¸iĞš—â?öb­Ô!jôáê¨-“6põ2Y4L$Ğ1WMHë€Ï~ÀÉ4vq§QÓ:™ñzæ|xg1¶7À@Ìğ¢amå¡PĞ×Ë¥’¹tß°}Ä£?2…c•œDp%yx.ƒİ“õK`Ğ.bçUàDìÕÌ®UÔ½á}jö’#È‘Æ¸>ÒóÅ‡ê‡›E‘c¡rª8ZASÆf\ñŸßqìÔãQOAOãu~ÉRy·uÕã€û1¦b×Á´¤ÇÔİó 8Xş¾=ùy¿ı²›ŞßDz©]ë€‡šAfŞìŞ•Î×¶R¡Œh¾…wFÏÉ–±ĞY˜â×~A@®#=P€Õ³ô¥tNSë…â(KáEñTËõ†ªv|OÁ8ö“•é
Xs™©Ršx‚îägWæk§î¯:l.½q³º8<O-*ûæ~<û„ÌÑô\”%_ó-.€@WØ5Ñçex¢D4ŞN9<§
—}•›OBø_®.úŠUäµİ®;6êië“¯Óº`6Ù SÖ´OfBË¡î¿ÆYegÍsk³~8rLñ@EGCÌ4šÿDØ¥eg¶nõj÷ä!
qPë…f™¶M¨vb#ÛFÃAï`´Mİ	+DÕN™@öÑ»İsª„¬èúf­ÏòêóPûÏ/zÁg²X*>ŸÏÁµñ–´pûĞ¾=—C¹Cl]½7¼øì‰ƒ!æìE’½Y¾ã†+>ß§ùbíä‚iæ-©ë‡ˆº„2ÙÏÏHØOév`ÔÌZ{V‹ŠŞd_›Æ­Yuµl„µ+Šz£8£m|\5€cëf‰Í¹öÌ%¥‹†eC¥ÆŸê(-]áA,&Ã@ÅÊ’ğ’Ér#ÊÇë·„
Iµ½Qóÿ€QâCYïSQ¥î‹vÇôœÌrõéuÎT¸­}25“Jğo¶†1¯X‰Ü€edß,kÅiYõÍ§aªJb´íM–0›By8¿ÀüÅ”;<–«OÕ“c¹ c1€ß…D0¶¸X¤„½Ü.~ó…ÄxQL˜şv·\iÃšåÉCl „¬xäI”=Á".Î÷|Ÿx®$ÕÛ†æ—¸‡‘¥»óÆD“ıPõ3oô˜ã5P2du)ÔØEÊ’îÄ¡úÃ'M³ÚC’ÙñDUÚçù`5JH©4¢æ¢‰‹+c‡F¼¢>3"ò
?+nø”­@ÙÜŠÂº²©±(îzAjq¦2 Îå!mOï|ºn„s„ºânR›’8ÍKdù%o©5QèÀ)úZĞ§öÎâ¢Œ ÕÆõ;1	îj:½sÍ<–ÓRR•ˆ‰•k¯­•ü¾1­¨éö­ÌVÙÚ9-Hãj8S“ê‹À‡€­ûÌêåVË*Ğ¶W|*úïíÙ¹â¢æ›E˜dÛÆ§l³²öıõ|’T”³Òn.Cœ#‡C™½@5‘Ìİ£Ìˆ^h‰Ñ'ŸÙ÷–bÓİ&2¥øˆçÓÆbtz4ïíbâJóqYæ
ø`cä§¤^&kŠ‹~÷uK„§g\ŒÂörÖ¡TÔB›ºYc´h=¬aDŒë·§Ï×°äXŠ_õ®µ*°÷¿,œ*©Òà*ÜÈ´œ­“"|./Hô+¸ÉzW2ADƒpiDm Fª>[üÇVa½q[ÍØ	tZuÓNPé}‰¹®@y‰WÑ¿–j›'¶J.“jD9½˜TIœ9bœGÚ^Bg'¥¦»ªx7’y¶™k²¹f¥|†_éî1Òˆ¥ z<=mş!Ôª®ºäcÍ›îA§<ª™<6Iú4©2göa}oPg=¦· ÷JSS<‡ûÎåPèpüyiS<·háiÇ†f-œz“° èòŸ¹£±ºÀlâØÎZt(†ê…"¬­-{!ªs(æ
aL,¿ÌB÷^˜d8æ0
Ä™KÉH‚¶˜lËn=Æ,¬]Sd¬¦²“9¬è^×t˜š¨P(qg0*-«C|@(èŒ³3gA N–Òü0²¶4YÌ(Ëº›Y_¼É˜“T…œ:4««ÆóO1‰[€×´³Ü¶W“}úE@´~p×<Ó¿V}ÕŸ–LÓ¾H¼º¯Ôš\|Õq’´'Bú=w7³a6 B5œ¼.p‚]Óß‡İèÂÊqàÌé:› Ó7“4±1ïl)ÖD®hÖ¯ÕÁœz1øè›|+ƒ5aİ@¨#[ª¦fj€Gñºê©^‰—áªÈKŞä)<‚¡šÀş§j¨'â^¨ızT»“]î•Å	»¨Di¸ÉO{n  ¢‹1‹]¶Q
AÑ2ëÇÜ£Å¾ĞfWë"Üğ¥ ›lÀ ÁSõmù³È1]Î:1úìª­OÉzçÜ•YÀOY»÷·©ôã6–ÙïŒX»'B€äe;^W™…~)¨öFVõS×*R±­<;ì´q}[è¢¢Ñ „ãÀìõõÄ¤ÄÔ¦¹-½TBä•vòeõ¶åà¶m›Q‰ŸTŠË´"ùì˜Æîï¥µ¸`E®'w%à+à¡²üËr<¬.µ÷î?€ º­Æ*`Ê¥ãs›ÚñŸ–ïTgŸ1§øR£(¡®ÔÄhXøÓÑ<j‹É]ÁÇÌ6‡yu¬.*Né¹ BÈ_Õ¤M_ìá]ƒ%k‡8TLÂám§|¯½9Ì¶¾·ºh¹k_'¦øåGö£åˆ~ÊÌ]wĞDñ°Df©©ÄÎ±oÒÒ³å œñœ“—,Ïğúô/ŞtÁÀ"©(4pÍb·ü<çGÍŸ‚œh”%lr>´,7ÎÊ¸b5nÔr…š”åxŸÆâ¼…“Ç¼–aş_¢ã aÌEeÎ††Y¼ºBSUEnrZ—ø²îXªÅ¥ÅL—¡³ÕI¼iÍ££I	»QÜèæè|„ ;OÙ"xÂ¦Ÿª•mùŞËêÂ¯àŞŒÙeà‘ê&{k%µPÈ&®°x– !Ü4	iY*[DV"ØL¨R|ïYº8„'ÙÙúœ,`5ÊÜaèJæ§şú\9Ö«<ˆcÙ`€…Ö€ëÌ›¶r¯b4ê‘¸Ã8Æûo9	sÂzµqAqoˆh×oÅ½1ÁÄQ ¹ÿ½‹“P_µu¡ªH•æMíÖ3œº1£hÕDœs:”·@Ìø$ñó†5_eCâ’äèâöGa±Kñ¯18µ¾ŒNÏT $Z0ròÍF ¯10$b‚y€ ƒ6Ø&.’œGN>™ÁıÒÄ:¹?ş·+·"bågò§[	·ÅZ^mè]~Åğì¬}u^™½#o¯:hˆ'±f ;—Ô„Ö¡s|&^ù€ÙäûÏ‹•Û%û˜*ï—#Š_Á¢y…Fv\ßî}Îèšİ"áeLÜEoM£ñâœ«ünèFA§Uôİiô+:4;Í®3vù½´«-¡nì^„%Z|¶²^L9…@;I@5zÿ×A©Š·Ãˆ8–ç7“²¼ÛL|×5"1«Ş'Ü¯c*(qJTğ©J`·ó›åÃÃJ]Ï/‚Çm+ZÛ‹	aÕNÖ5Jõ‚ÄÉé–:±v#fêäNWÑ9×î6‰×ª3$†êıuJğ%/ô’bcÒĞªn~,úéÅ5ï‹·ôÕ×®fìûtÏ"zL:A+Ÿ#µrNç:é@¡+¶;€ª)ŒÛrg);hñr^/¼Ï'zváî¦–kX¦J;Í?ˆáV$š‚§«Õ›Ó ;í—sÑÜ'ƒºmá#½Õ®ãˆˆ#œ½SP‡%œGz†¿s0.Tj_j'PëüÈÔ'üP§k`°+Aº•èr” E!Cï};’ŠÜ²vçXJÆ®Œ6£`™ü8îEğŠ¹<˜àÒqÎñÆ‰\i¶g`‡\4kÉ˜fKğ±sÌbÜãNÇù +¥zGòh{ÛˆMá©ûiœ™ŠWC(É¡ÀÈJTxæ>ş±”F÷ÊÖ$‡za¡ÏT æ
ä6XqĞwá‚İÒæ§.><û²À²c€‚ëy’¦)ºeè¤¹Š-GŸŒ[?cz‡Zo<½LFH(êšì'ùçò ×¶\(@Ê3‘¥.İ›ÿ–€¿»4â°æM\?eCN¤dë,ŠÃ[¬"bPœéìõ^¼q°qKGØøW‰Å$•¸ÇÊ>´Ş6n D”St[ÓÛ~n¹Ô}ÆÛeiW¾XÊ„W¨Ç8$"şjsé§ûÁ>«m;;ù‹üü /©ze¨(.xš†#?:{‹d‹ÓM0Q“%Şa]!–|,£Ù÷Şªh¡>µK/eì—Ñœ+Î¿.Şôû‡fÜbÁdG÷$Şg¡ ³\ºŞãüÛ™!>¦euü¡„T;9R»–/r'ÀŒy­b®F^3f›û%îÑJ9{I`0FWµĞæîš|}ovğ°=¥Q™{O¥ë~šv<Ô?D¦@–ˆ²oáÜ6¹ØCôÙ,½R…İ¢§èÿá°<"xœ§p|ƒF=èmkìR:t‡A(kn6—eùF°ÆÎÙöµh´àsœñ¤\3ès©‘'ù¥9·[K©øoÚ}+-ÈøØrFÉxOFBO9Ze…;;`]i°®Z³fÃ]E­ÊƒòşF»|u¥'%§ËLgH¾r×æ:Ğ¸6³Ë°=”$%ˆÎ4[ÔÃr¿tñÄ¶÷/ğù"›1]Ê¤œ¹”SÉÄìà"ë·4@€?†M›ıB©Æ3••hÁ…„µÅÆ3‹oÄnšŠ\•\ĞâPöøÆ[(K?®æi*¶*GUvk¦æXLÒÎ¡ş™
‘í¶ğ<w<‘YŠ3ßæ,šjhæKfXïR›ë-.ˆÔ¬aáüïTÜşƒT&†xÅÖ×âÚ½Ö¿)~·Š"^ÚjÆª/a_Å½eXÔKñ0ş{|B‘]B´»Ìó ‡50ô·ígî*Äo-P!|ıUÍ(W˜‰â‘wğÈşîÁSí¹ø«ºæ|z
*»¸qAfÎq£¢ƒ‹¬>²Êès~İêÕƒù+k‰Ù;=écş›?ù;l´ n·¯ˆßj»§}.Còİ"qÍ»‘;)Jº¡L\ß‰pv¾W¶…ƒÚf»8Ó(İ;Ò{Å„ƒ†òÌo›‡ÿNŠæ·Xõy³&A²YâõhöÏ5¥ã…¹oÀğög›lM"ñz¦YÕı÷]JÙV.Ê	óRVpÊCí™ß¹Œ]â¼|oª]Ğ§U‘”apŠå·gWB#ÙS€X5äK^u	¦2€R¤ğ§µÕ %½|w†~­C£ubâÆ­ëš•™¸Ü¼òãóî¬~|ğ¡Œ]›;\†#9v[•:/ÚP:œg°»b?"åõnù3Ÿ‚ è¥Wş ·»]ë¼™"f´¢ª%ïü<è)úıLNjáÍ={H%S2Ë€!42#ñxh5óø£C­Ïï¼.0ÉM¢È.¥°ŞÓJ~n¤g~eÃ˜/Ú4Ÿåï°Àß„@]·ú<ÔâG†äöÂÂo”s^Q¢lÍå’Ş
k|{Ÿ{éDq´¸&[2Á§ø–a0±/èq'îvq9)¬
b¿ÿ¹æ,ş'‚¢ÂÚmĞÖn°N—TµiUA²n.ØŠÉRİİ…ö¨h
Í„nÜ0o4o¡»|	³@À*¿“¼¹0ØàÚuDuHªÊ¿ˆ¼s¦Š°©-2Œ°àhñÏ}‘½­l¦=è9®˜7Œ°\réŒ¬¥¤`‡WVŞ"Ñ¶Ã™`ğÈ‘	¼–eO$ä¸ö_ªô”‘ÈË?¬šf‘Û¼Ä‚>p+^"¸ï¤Xƒn¶ââÏ+DlcVósıFÒ6Feãû,ªĞÂ·>A¹ç«rš²`µ\×XÜ’E	L¬rÍ¶H.Î¯¼¾@“ˆd²¦™şó')–;ó‡ÔU;áxî¡4g™İ]¢£~ìC.Vr&#ë;¥Í³h^õ N•¸Ê”ãëÏ2·s( šÙ'Çş¤$KJÄM&C£ËŠo’+†¢-çCj$ÒòŸÔõˆî†ælÂt‡­ß¹9mmøìÄÔŸ†ç’‘Ê^³Ø@Âw:=ı  òcAYÑIlú&ÚÖ@É=høƒ6È²î=w›2,Ùz’`äc/öæéÎ¡;öÜ¶xaI‹´›¹¸Z%OŸŒ¾ØhdµûıŞ›F·}.Ëˆ½ïLM—pmøÇÔ(NÅÁû$ğıJí'G~eÅmŒsa2”‡åX¥Œ!·aw²øĞÊ¿³f¤ÁÆz˜skËËBÒ•Oø
½WÕŒ.¶+W^èÒ /M5Tk3ª†È]ˆ¯•ä³»S»Ùú£¿uJxRÊ
Hl¤’úºu¬WËÄhXjóÅXtÌ¬+ô0Øüw­‘ıæªÁt¥ LÊrnÆf‘ƒ:±¤eSbd±H¼EAÎ-FG…ó]ÕBY beì0ô¹õ¶YÚuéB)àã«£‚†f{˜†!Û´·7}Š–úªâ9ÙråZ‰çöT‘}!_”X— hKÖë»Û¾ÏÔ¹e†_éu¬ûß+®<o‡¿³€“T¶¯wL²È’çÅ²WämŒ2ç8ùš@º/¼™Z¨Üs!ak´×AœĞÄc®Cívâ®³Ùºbô:­BëÄíS‹ŠK²)KeÛ;MF««31,ôÚf¼ú¹šj®ú‡>¿+k˜º´ğüRõr¸ÇiùÙxµ{_´æ®±„s!—;¥Í†B”yKiíÌÂêvïè_j)§N/ªv÷KNäa¤@â­“Ö‹ÃçO¿õğÀÅêàâDÔßEÈ£&˜›ƒÃÃCGyi9&kßNf0v'
šx…Akg¤¬;{©i)ÆõQj¡)Šî6eŸ‘ÂË+ûîê-È¦³…ä´ŠHi}íÒpLÄhASxß`0BóU…Y˜‘n
j¿Yphˆ+Åd—x¶½ä|ŠHË·,Û«à¤—€ ¿¿WŒçª-64\b+ä\™5Ô•îòPçF¯vú!tœ¥ë]¯KLĞ˜®`TLg£¬‹‚:ë~şÓPãÚt–%ÒwÏÁW‡çŠü«Íãíôİ6œ(qPFéµÅÿò‚UG4THõ[Èõ„Æ¯³äLş’ˆÆ¶+	JÑè¼íl„U$=“õ^È`Ãş,_VN#tçê³œ:wf'ï¿kŞØı½,YãpÄiÜh¿œã=1RÿÔé»33"ZŒhÀõÍb¥¡Öã}ç•”ªm¿µáp…½nG{Ãç™³§û‚«W	¡a‚¬3Õ%Ÿõ±{EıÂV9§Yœ¤G[:'gx):.Ë‘jÓ²¬Fä™(=YPo‹ÆôËôq6Ÿpl wÙ“d+;¿^pØ©«+DPÊ_Œ7Jœ¼s¼Ñ¿°S“0ön	u´‘&¶´sé'éµB2s´uûÜ(­a`’Š“÷€>›QF‘m²j ˆ@-š†ş[,ïaª9©È³0Ò•E¸¿R
ØglZ&Âï,ëƒ:ÄØ$¾Ë 9ÁbP)WQ`Úğì¢¸{jşMáñ>RNZ’@4¯Z~pºSš×µñèWñ—Ü$¾ºßÔÀı²Od
)+Q¦>r¸.¬ú¼NSøÒyÇà×Ù™[ï1áVßMÊÔÀyƒWÏÎö%q»K£Ş”Rl3U]æ7‰Ä
I8Ç?zÓZ8ß;ğâLÔM§4™M¹*ázs×H,AZSõS¬¶ëEë=KE$ÆM{hg°´!>bm·DlôKJu^(¡S§Ä¬AÂ4(ó SrÄ$õ>ã€"Í=¦øç¬‘ûXbK"_jõ
P t(ÏÀz«FM•øB±•Ì3Ãí¹Ø¸=>„ÿN‡Î     zm±'ñç Í¶€À³ı±Ägû    YZ