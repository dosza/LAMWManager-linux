#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3176199758"
MD5="600969fbe39182543df2fe9705649d17"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23080"
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
	echo Date of packaging: Sat Jul 31 17:06:25 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿYå] ¼}•À1Dd]‡Á›PætİDö`Û'åã5P‘ƒ"‹?øœ«O3·ì—¤iyHp-ü'¤àœÀùîD½Ûß¤¡2¥‡$lì£^6·æ ’7Å‹„‰ˆ-0Vƒ tà;¾à®´K
ÙÌã
Gâ<cÜë†‘¡*1ç¿lƒ‚-«Y~t;>…¶Dä¸1ìFSoäA¸‹]zÈÚKUqä5B*À
…Ë…Å¦4›áY@C÷MºÎ¥oaZš´h+d¡4¹Çxx*^Âô­±âÖ1BÌÜÆ{/HLjhÒ¦Æ§ĞİàÓ¨­PP3Oë-,Ÿ rbÆşd‡åŸœ®­9º>G‰|£¤B1ŒªúÖÒæûÇrms’ÇX%&MŸ½s‚3W†O¥{,ƒÔ¹9eÈ—ı£²æÖ÷£{`—È~OŒ`Õò˜Î`Úô>ß
†ÍDJ„C9JáÛh ¶”Öm£‚êam'Ú?.v;šæÌy×Hw&Ïÿ=‡åß¡L#•jôå6ã¾)tFy…ÈÉgC@Ş7Ñ½§~'nò–¿ù©R ÏÁÜĞ24™l¢]*ù‰#Õå–ë”SAÌHÔñÊàth›+mÓjRİêš¡Ø¿}12õ4¹m–åó·½Õ¨]ÔàcaFX­“éeÇÙŞOZ6ˆTcÏzFçÌi¤b£ºú¤ÛÔ$jˆwÌì#šiçfxµZdx7Œ1²sqC5`Ï£ÃĞ6d§ßBˆøÈïcÈÍ©ìÎ.¡ÆäPæëj7,ÇÚÃî‡I d@e&¥ßrÂãÌ@&|{—¹O6[ÚQ…—GGnÁ5+@ åÑêÀ‰ªFe:Á6·ğ&˜·´)cßGzL8ÍXæNQ„&bÄ¯VbäĞT,ÇV ¬®uãT÷À®û¡b(¿c¸eÂíÿK?5¦•›
Ò–ùƒd›{!l£LnÈ²ÚüD!õÉ;ëÈôş;¢¢=-Š'ÊÅ˜õ°Ï‡×º«4Â#WĞBÍŒÛ™ö›§ş¯kw„W_ÃL½RŞÀƒ,“n˜b/ñ¡~!©pQ Ú‰giá—±9ùßUˆŸñŠì5óµâÙzKìæÄ:ó(U–ªa?ãƒ…xÂXÏ%t1öéDjÆ›ørNß (Ö4CÅeÏPœ _3U³ië@föf¯Å8,®h€õ^s$!ÙUusÒÅmkôàûUá	%7#¨ä~«ÍNÖõ2´ÑÀ’€!ŒƒIƒ%¡>ÍVËñ Œál¸êêã#¦½‰¼6G4™œ±k…h§Ùùı	Z,9Y/“ß(œİXí¸cãª×	ëIƒo›/„äÅc'†øö—)¾ĞÀÏ=G>"„Ò¡³'wZx\ÙuÛò§ÒøĞ›OcCg‚ï
Çb.`(ûÁ*²7<8ŸtôIG0_,z7r”ıjÏ©UşÀçŞØÖ`ò#BõãŠº}Ôûn¥}w·¹/ßš?@Õ4ÛCÚº_
È£ÜÏ¶™µ*C¡€±/¸÷1·V…/›¡¥	‹´œdYÜ	¿‘H¢M†Ö¡íx\À¡`Czœ3ô’Œ1h˜ÖPÿ"A“0–¬]”³æÈW˜^ÅSçT®Ë>¦œ{xa=ªÂÿ”'MĞ|æÀ{Öä8óµ‡´*×©Ûië áÉ	qênt”EFgméQíL4¦ÑŸ“Ûq_fmãÛ¼Ùì¯¾V+ì‰îâÒ¬Ğ&îâ½ùæm•…éHP#Ap_TQD&ññd3r2¢zÆÖud;HÈ<?£ç#û=·^_’îÌ=ä—Oè[¡‚Fwä,:ìl÷ªˆ%¾­+Õßá!¾[l)-»ªhZ8d8±ñ=İ ¿‹VoRIsWÿÏRácû’äç¸SÓ›œN
è‘s„*%"Æ<–@r}g¹IiUôNléÜ½ßØ½Ÿ›ñ†™v0. ¹@VĞu¬VËGªî?·¯²–R¿x±–”eÃ!ÉÓ¨a0Õ$B»ø/4=/ëH²hk;ÚÓí>Øi1§¡|<Ï¶ÔxÌ‚ª„Ç7ú(dNxÀÙt‰á›ÜÙ—-Á±ÿp¸‚DEşÅ.oÔ1·YĞ¼ı(©Ú Ÿ|£S ¼ÀCQ-(|÷ÇÖ‹°_¼F• L|ƒÆs”i†¹Ê—¸2¯U±í,óÕÊ&S÷XZdü£ÿ±£ÕÉŸ@º<Yq·öŠŞ•|…# º×NrÛ!h?vÙXÈ2$ 'JĞuóøÓÊAÖ3¿$ÚŞPÄä€»ÁÃ©¢7ÿ|ò/s-Ce…¯"¬&Ÿ1iéÈ{›´z·–½#’í$Ç>_‘mx4îWâéß—}€U@nÌDHYb"jæ•*ZØ<§öÇ´qFÅh’4zè»r_ÙÁÊäµ¾ˆÆ³°áI-ãä¬f,`©K²´¡öŸ£á™áá³³7ªP4IùÆlc![,Zò«bë"ÉAbU­vŸ¡ñÃWcóÍÉ‡ıÀ' wº;Q§ã·%tÀxîê f¹f,–®lx.Àı.èYœDfš`Æh:]˜vÈ‰èZ‡NÉíc¼ÂùWm¦YŠÙ¼¨EÒ-Ëm?Ûâÿ}¸ğWİ+·u hŞxÌV_Á?hUà_‚Ø¼$›Q6û;šÍ9kB¢Õ—5¢vŞ‚²ÌÔõQ9·C¿wæ†1Ó¸İ/j"-¡QÅıMZÉ†Ú¶à“À½=58«´”§h2¥İtD`O …Ê†Îe¢
ú¹ı£Â ÑŞo$½eBüÏ••¾”¡ß1_SãÓŠ}~~ÁªÑ1ƒ¾N©ıï£);>­cÏdXèòË	Okû\hÚ¹Øy…8èèQfãàP÷ÀÃ^µnöİˆÛº®ú,„‘§Ò EğJï'ËOØ2‰ú‹¼?ú¾ò¥”îF„BÓôÆ?¹“ÑÊA+5­ï^FÜÙ6äE´hAã×†­¤ø D›À!LÊ½ä‰K09	­eNÈ¢UYa€8x|BŠ®ÃÈø1‚5}¶4ˆ]Y˜XƒØH†^‘ïrŞrÅa 7ZÊ¶(süÓ·yòM–+'€.æâ²ëëYtm–aşÃ,U™{§<”¨².‡êXë0wTPLTÉùãÏö¿vı@	aØ¥µ9$%åIu‡qò”I·ù‘ö–&ZL Âˆˆh#“È\•G¡Ğ gµõãœ&\±‰^ÿÂ-ğß¢ä¬X©’flH‹öĞ³ÛÔ<Wõí×äªpMX¥«UcIÂ–§Ñ5_B³r9/ù#÷³7Şfu ³Ñğr¼%^iü§êÆ¼3ÙÆ.’›D{›!¬¶@™%\{$ËU­M™JßÚ? T7/ß¾Î¢6PœaŞlãèßQ34>{¸?7fYWuHKI2;PŸuôÒgÂ&¸É¦.Ó¾©À»ÀôšP~o#µ^A'˜Áqšd™«ÿù®‹QÿKC\®™*€’ß=LúÏ­ÆCš…héQ;'ß¶"\Ú!šìJk9t³Kå™íZ!Ğ³¬•sĞş¹Vùá{²lŠàM[o$û0€7¹ØÕ
¢¿¢V¹M«è™_áŒ°•ÿ´"¹:Ò¸ój!¼923Úõ…8¤—&²Òóßˆäéƒq§¬×jäaó ºû–©>ÒÏ•‰6*ŞŸ8¨:­L°ğŸ¢&@‰ÉÓ7Id· ÏÂ¦LZZô“}d :jfààÎ¼?}ÄCqÒ¸ö»~ı¾ôÈ‡¼,C~¾xÁ£—uéª{^B+&)«Ã}ÈÕnw—QË¢Òa0iâËxFïÆrÇ$Òd[ÜÛ’ı—P×.È”¬ì›/pe,XQ4ÊVåÚ–üı»blTfıISÅŸmŞæmvçëãŠøHi§g“u~öG!ÁS”¢á3º’ë´Oõk*Ñä¥¢£©å(Tı)å£³p"uvwRübˆb«ZnMU8ì‹1¶8·b‡¥ô—™Äo€m‰X![j
{]ì¶')ğĞÔtõIÕ°ríä+qhÇÊ8‡Æ¢@ÆÅúºÍd 7Ç¯0ğ‘¿pA”–ZF\i
ù¾™ÉÑ+2!*T£Dá=µÍñòuQ…-¦à˜rsàÈ£Ò¨ÓáQè±´-À¸nœ4í=Èƒ[Ñ"ğ’a.n5”ìçp™8¬ã"‰©Ê…åR¶,ícÊZñöá‘²·±Œ]0òãy¶º±…ÆnòÏ|G¡SŞM©áÇüJAÊ–ıveér	ñªÁÕt“vÈxdÖ½ü>'JèE¡»SùYÉü+ïËû.*@3™rs¢ $„ØÏìOıcÎ²Âûõë-.~(Nå4äÊG`h3ÎNwÏÍÏ¢Ì v¸mca§•fH¯·0oÙÔ$yC	ZŞ?åı”ê•:À“Íâ™.·½O»)nxşY?VE"ÍÔ	ÜÔÉ¹$~è³KÓPt¯¨Y>¥º³l¸;ä5™¨~(?\›:ÉÜ)Œö¿Íc¾—êÙ@•m~%“)Ò~ãÜ†|Næ£O§£€7úB€„º_T¼®‚µ&Õ;J\ù90$Ìë@/ñ…?ÎM1!µs»Ÿ Ä2üS&CTTæNZ’ OÁFÛÉ1 êàøÅ	ú#á}xØZ† ·¬©«n¹$—ğÚıP¹[.%ÓF2GÌWâõ¸68ö‚ÁÉçY<R_' •Óúì¢lùíUÛ'!…ãèêäi…êÈ-¤ˆ8MıQ“-Ä$‚Å­“&Åü9$}##ïk LßÅRxmÎ(øZ#JIÎÿš=MXhvèÙ3æZÒ¨È;
ÚÌÎ~²ß]8vıúú‚#¼SAÀEŠÉÃ<î©¶*¿Yii#N¼KÓàb¬uûsDĞ¹oò§Š0>`ÔÌá—^ïa0Ú½ªö÷çªëP1XÔP;QšL8ÍÓˆÕÈ(bÄ’	QóÂ‰- Ç&k³³©4]wH¦z¹	¢ZWÊÆ:?Eƒ/×ï ó'ÑÈ…õ‹¼Ÿ-A_
£-3oô¼áDÿÔñŸc jÚ:-³¯Ä=1³r² e N”ûp0úiO‰ôíz2w· {_Ò(#ı9ZÁš|ı´c ªàêfZ3>.Eº“İÏƒ†í,oû6Ã%BgY¥S§%Şq`*·ZeRÃj¯êc–ı‹¸şèëIb%G•T…
¡¶4¿dK>Óÿı‹R)é7v,{ğ›æ‚‰¾´®ŞUÇ==Å‰6°ëHñİŞ¸á¸İFZxNà¢|Ö¥Y›$ñ»¸#&ƒ^ÂfBÈ	 =í¡SBF )W¶·Š_ÂÛØï æGÔø{dH`ø°;B&eê@Ÿ>äCJ‹#-cÄ¹ğ|êãœun$µ^‚¡=ë ×\¾™%:Ÿealìpİš¤!Bæ'¤è­—‰hzã×^’ÚÀ›±œğŸjBW~BÈp“¦wÀìüŸ+¿|ÂÆ;ÜŞÙô`yXØnØîÕª½â°ÄÀÅW¶Œ¨¶A`¤«8ƒ‘(;vñÅô;ÜÕ€®	î?\EãGä¼#ÍGÈ'º·§*c}zî0¶42Æ:w¸àÛà¬ÜP»FØu°Q#_]¤Lç?O¯NÉ5âİÒ8úƒ¨èDPo.ãÄ00e$3”™;F\°Z˜¯âQ‹¥4˜â5*2ÏíIØ¹I]Gp:(^ıƒ°z0‡æƒÕaÓã;áu¹©-ÅûNĞáÀf]’ûÔš9=P\EÒ	À^lAYãÓWúŞ(ç@¯^B={ûbyÓ.6E²P_˜Ûu®Ìg6'®g ÏÉ+íµ	Y-rO¹Äö¥°yİT$˜¬t\yk/)K­X,·6´ÊÓ.Ş2ŒÔ›ÈÖÁ^ «Õ-WğÕ{g•-Œv	«ÅB¦Ù@İöMoüæ<Ë>fdue¨ÀØºÙ˜sJºÈóCmd$"RH=³A˜Ø0nĞ‰-ˆ¨&ê9ğfj_„¼ÌÔ(42#vÔ‚Œë@PYD ª|ÍÀo+[º<&a’‡d5²\9lökûÌà`Ç¼ZXÃøÁÑÓ<ƒ€™—ry¸Ãu›Œdñ w±C4ÎÔ¼?T6]äãµd£IOñ Ì³?.#9NCŸúZÜï`Ó6ÅeÅœì›iiAçö%Wït£İ–•¼T-™ş±ú€)-âÉ¹ÜUæG.ùÌ¬Ç aRé¹9¬‘ó	£³nCUó/Ë£·ZÍúD'Ëmîb¨ÜNnÃEÉË]ñ<“²& ÷ìtì#©edá§2íBú%€aw4¢?ı³ à—× B«Ú”©×Ã= Zí™Äz `g›ÒUÕLÛwŒ<€~Å—Ä™OİpÑ]™GêL:ò\ñïõõ^nôŞz3{ïèE›6ú¬aç50Æq Ò9ÌV±•!’0ğr”Xñ–1#ŠŠ¨¯¢³'guÙheú(€#}¬ÛÛ!8ñë›­À¥@–	9vé‹)§’G]i¬po5µ=Ù­şŸ5Y½–4LÃ¯º­ÿŸ—àâåX‡3¿4nTfÏó–-¼éåàlÿ.@$ÕZ"&by$Fi\øù#¶êó„ƒÓN¦!…Şlš*Zç©_a¼– Ã7ÑûàwÅéÙ€ğípO¡pH[¦N»‡«<Bğ?ì:öBV^[ĞàƒDkëZ£R¨y%R²°P5³Ó9±O {ª¥ú{bM˜°5<MY(ñ)÷DŞ à¢Ï]C7Ò&\X¯¹³#×®™ztq=D ÑÈˆÀ,„<7›OÃ¹n‡0yZÌº¯5§Ê"ªl%¯›åÚ! òÑœA<A
B]úx‚Ñ¹NÇŞ·™ƒû[\À..ƒÓ7pÜ¹üºIÔÑĞY‹ö{&/í%*™K¸„Ë6Æ³»ƒ$´‡w&#\ô(0U¢D=tFíS¶È¹h]sh‘´=òÓ°Ã>8I¢ÿRK´”zT³‘r×³"{~fü{íå~`<‰¹‡Š'D¿óïù‚»#˜£—3ÊÍ‰0å†õ\g§ßa!Iş¼KhÂÓe/Œƒªœ#x²Aˆ2©âÀÄ†ìí~ev0ÌİYFúHHóŞ£Oš<¨qg2“|¶F¸îà¡ëÀ@av;8Fz‹©KhhìÆìÛ¤iÍ!Ì±mr]TwvŒİ¡ne£ÌòxîK^É1*’l}EÍ 0•NÆN¨¼|ìKÑ +‰må7Ë÷­ƒ·Ò1ÎM3^[Î	æÕg]y´ °Tx‘=eÆWß¸ÙFæ„O~.Ë½ôòLKÍ~ûMßjÿ›nÄ²*˜ıÅœ¹íNp'7&-˜z"ŞØ&¼õSÄ<ˆî^[â°œ%™ç^­¾r‚âÙF£.¼b¶ÄŞåíÆË{§«%RÎ—ÉeáhÏ³şX6‚å@__ğæŸøß®P“Şz×¸'ëÓı”r('oU¸¯Ş2Öé&öÔèÁt¹7™™aK8êˆÑ$Äqå›ë
‘Ç…°ô˜‘¨§·&Y(ã¸¡¥ó-onZtOÉ…c5…#wØ±İ¼‹{G4›4†8jš:­sk¹Ó¢_¹’ £ü¢ï“ˆùÜ/§XE*¨ÜY^_+Û–ì„dÚ‰zÎ"İ,©·—4"´½77}+*È`æórhƒ€Pñ
g68[[**rË"SQO@ÉÁtV3bÌs—	ãbIß«ŠTeC^â]=†yĞÒ§!œ~)R!‘ö~3ñÖ@¶áÄj§_égèş½‚mŠÃrŠ}O!4[Ëû½²ğŒQ+7õ»Ík§ DÖ1sYÈ0{ìö:‰ÈkÁs71^ü©êA*œ1¹Ñ9i;ú,¥ŸD6…KÑ=âúù£³œÀµ%ôXñ`9z¶%¶Íç%³ XŒÌ‘9‹/Pcsgª±™zu;Š;Z6”×Ã³:„,WOÜ9qRØM›?ú?¤Tñé-ì¬¡¶\ToùözÏÚÙ²AŒö4<\jn?\FÙ©@Bl£Ü–®…±Íprù½ƒ×Ÿ13KşìğQQD wÂO\]÷Ê«lØ«²¥V5 ¯/Wæ×dJåÁ–ÕR10j¤Ng¾×If7´ú×˜>õ zFÜí±‰ßßaE¼ÑABdx 9*´eöã8¾³ï[H¸qZäL×(ˆ¡áäçsw[§eÛ§´¨Şä” á&»Â!ÿ*”Sç²x:íˆÃÍãT/Ÿ 'šøG…IğÉÄ¯U?½Ş ¹ØoL]¡½|ÌÁ³ˆ•‚Vßò Y%#N‚Î†Î/oyµ²í1+ËÛ-æ2—u¸™…{Ûm]HiY[Æíã'Š~úÅF‘D‰ÂÇşPaH´Ã¨Böùó”á\í¡ÓV¨ƒz²×ùt TƒJ¬éÔW½Á¬;öÃ,ß±«"Åß»Ï`ã¤\b×w³äÚ	¸jÍ~ƒJe›~£ —7úí˜vwA­È²°/öŞ$	f˜YéåêíãÏ^'ã« 783G
–ßÛ	(Ğ—fQhšc¬â8ÚH»Xzb»–ÿÔA
SpUl±ÓJÉ-ÜòŠ±•Ëp¯tvû”¢f-ràİ(×ƒ ²ŞŠeAQÅoŠrËãî’$U~fAk.BïêĞ‰Èš‰È³út§¡•‰Ö38ËqÍ¡,ÉåïŸV%j©?odyzş«gït'sıĞÏ¢h€J†õ¨ä¤ Vñ‹]G9¢ìe“	ÉbûƒC¥õ3H«©ùyè<fÿ¨ÚÛ®I:,íâ¸’>ï9¥Ñ´8Ë ³Îç‘³k½€!‚ÌV—Ôí‘<ùN+t||p­èÄ¯
Š“Úşæræš=NP(6a†˜5±šzõ='ïé
îjÿ|°V©rè[kşMæUÛÉ\(y§ÂæÍdÇÑV$d¤Ñ‘Ó¼2—ƒgVÙâÿ3Ùèu-7¥‰^˜@Ğ2kÃÅİµUÕÑ2'y§;Yîg÷v,/˜ıSgÇ?UÏTL+ğéİMñ]iüÔ6cªH³MBm£ü"‘!÷Ä(›‘)PûjqdC¤o_#F˜Á@ğ†"ÌÙœÿ@§¿Ğ§=Ê$‹M}4PÏL§2
fKHr'ØœËÇyÚ-¥²P»nÃ½%j•ïl	­ÖÇë8˜ƒ‚Ëg—ËĞÅ”şÜë ±Æs3¦no€#d¹¼üJÎi—n.‡FŞØn3İ'u„4"§/•	ê¾ôŞ”.¯ı;òøKĞÒAÉUçŠyÂí ‡±[U¬L;å3p·lÀÖ°ÏÕhjv¤×•—úĞéˆ’Ói‡o'ÙfÒûæYÀ!Bg†9ËËßƒ‡J‹‚«e‡gŒn{òø*Û›H£Àœ8iŠ¹páT9¼šóz¡¶İ×vBÕ‰&‹ûş0ºODk)¼AoVïh5©°TcÀ
ÊBe€
<Ï4ÿğˆt=Oû#[*ş¡,»Çµa­­°H±…8¿Ş¿hœKn6Ú÷-LuÎAVègÔ# µá†–²ÆÃ{(¿êØåèâ.OÖë^Hb(%ı$šC¹5£ÍÕå™ºÌ5ÉPÌk£ö;B€ã#Jš<ˆ§LEƒød3Ã@^ÏWk€2µëø}İ”Â‡JÁúqÎ ƒ_ÌüËV8g_î0dùóNz.[)½ï¤´äY·VéôÀjU€K@é#ôG¯œ^ ñ.ï³×gÕ3^~@K!_¬ş?œ{¹#lD!¯†É}•É:¾ª3?£?&ybBÉ <ƒ¾x`Ï;„YVZ¨USf*×Çşá®ÇB£ğãÉÁ[ÓóF‚1\}M>q§#8õ#gº¯Äñ‹‹vµÀ3P<ø¢'L

~íiºw g«Ë:YØŒH5ÿ67xé×µÅåå¹L“ƒmÅĞ*wÀ¹Œá»M;;©+F?Zê´_?›­I8á®Î	+›ê{h¿jb¼Ú”\¼Ìõ*!¡u‚¿ä¸Ì!˜¿£†ÕüUÀı‹İ*ñ‹[jşğù)W—Sõ<6ÿªñfMûA¶;c)$ƒ™PšÆÖV'äÉ/¥}¼qŠC(HUcF“PSìş,ód•™ºÎMBë@´o¡:#9çğÅ%–ˆu%§RĞb[²…œgğv Ë"cå´ÊŠR=Ô2³šù{t¾Ò~:lænıÅ?B„Q
êF¼DYwùvüf*TÅ¿õŞwònãF °Y2'Sd%·p„´ÜÏ¾?úµLM”ªj…‚Z·¾§8+ÑX µ‘šñö¾qä ı|¼;$»I›‚•˜RaĞÏ—÷q4æø9Ìª‰¬ìE|3äĞ[Àä'áVZéÊˆCëÒ?n)€ı[­@I
êLro]kÿO‰Œ3LÍsË)×nh×ó±šû£Ü@ı'İ»M†'êŸº	« 8BDÂ>ƒùç[ì‘ë~,«.g‰›R“’-…)²&%#–¦ëÃGÙ“ğfWÃ ›E·úüñ,µ•°Ã›ÿ6ÜnáÔ3Èñm^¢/x¸Ø6ü,	Ğ“NŸŠÖº(+Õµ*çYİ¶¼_ìÇ/;uú4% 9Hf+¹6mjP0	6.!—ë’wëª~#7KNú·ÕˆgyDif‚D®³ÈŞM=3"I]ÃŠ€óøâ’vw7,rNrIô ¦¨†D‚Ò€a©î{	NG¾ÁP^æ´\Ãìö¦¡H‘~C¤JÍiõÈ:92ßj"™ö$cÍ/uâ•W©ÌFnğÿ âêÖqCT]ú.¾¡ûÅ©*]€/ıÔ%Óß‡=6ùZtRëËW P‘c<ÍêyM®ùd·^M4çVñ,ô!ØìÄu-­·C¢kğq“×¼u(• rÃ‹ ÇÎSîã«LÍ4FË,X°¥V±U¢™‚YòÁÔ5*]zŸiê‹IÊ¨›Ÿ`Xxµ`á¡	Ê›ÀA÷Å½*”±¡<Lšºõ× ÛÁC‚&	³oÓÒ@Ù™YÌ¤D&{İôÎA“øB`~ĞWŒëøN^—2WMìú€ƒ°±=mú…–JdA®Íd³x^
½ 9¿…ĞÒTH8ğEıñ×±0¶˜xbCuò"mN²x._}&êJu,äf&rl€lÈ7”¿éÕ>uU³xÒŞŸ+Ê{±}±>£ÂLİµeÀîŸ;wô~¶¸AéóqqF¶ßÅ$n¶ûä±ÛÇX
Y0òı5™ä%ì½ƒ¤ItBKU„mµ…¨üiğgS,
X†‚çºÇ“ùˆ1&LÔßKÄ¾©eÅ€ù'ü…f-@Vmõ “I»øs+’0Ÿ.4-p²ù±³ª&ÏÿŒ÷ÇiKÅœÚ^ˆ<¡ ‰}í¼æ«)×yâ!ø!zÚÇ¨lŒ¬‚µÈÄV¬–!4èÚ‘÷k_P½"îú.íÛHpCu”_ÌŠİ¡vÈßá€–eT”í*Ğ ¾“8²€§àYn
v×îôˆ¶y½¹[|“âÈâ ş'4R›Š£S_†õi·©}{q¡Xôxuk÷š‘x¹µFºO…PûÓg+_“Œ­›,3Ägóz¥ÒŸëù”ñƒû^,ótlŒœÄ)	g8İ|´@|u_ğhççn…ŸºURÃ<ÅNÒVÛ £¹©Ú2…«ìÒô…‡m`ºh'â‰ÿõ¢…+‚*L=Ğç‹eóyP†š\@‰Â²GÈó˜TåZC_ú'1ÒI©ÀÃÂTŒØ ¢³kŠáÕ'F[@k!â>cºsæ¶¡òT–ÚëŠÂ™Ùø73 I³hA„2ÊŞ`-q¸Æÿ¶êm3tÜJà>x0ëÙ‘¸ŒØYz)‚Û®bàkÉáøÈşr–Š·mqoĞÁˆNs\‰{`€èb37/'»g¸Å¡«§¦àH1—`ô¿…)lè-P
 YMNZ«í³zFˆ±pYcYÍKX_ÔÏQUãÍÍ_€x¼¼!C_—½TÎÍÉ„hÈ‰“cİ*sI @¯›½¨0>›	.fMàâÉÕÓ +möÇ°ööA‹b½©%>³¯:šÒ7ğ92>	Äñ¤\Ÿ®Ö€j­#w— ğı‰
„ğî&hMçJ	vvÍ,.y-BW;slØ\9”|®ø{ÅÜ‹9ÁZ•Z–€M 9ÕÒüÄá·ëò½Ú´âö^LiR’!ü{«Ş*F£4»ØòE‹fİGx½†f&Íô[{å@›› ÈñÊkü·æú'	àî›hœƒè:±7Y‚Î±’Ñ9SM8ç°=¦tÒúŞê<Pˆ€¨…¨ï¦Ïm´Ğ`'\Ï)|ÙvSÉßví›ğA;rğ¬.U/î–_OĞ—ÏgÍQ¡¥ô¸a„xbŞâ‰S‰â÷d:WmˆFXwA/Š¬F1ÙàIxœšı·ºŞİ˜F·—şøR2È=eéÙôl¹ÔYŸ,ù!KbÂgF¼¯ÊXDûéÍC¨Ó:<{¶9.‚NÆ^,aDæ¡«×'mNë¿é?õ5ÜÎ›×Ÿ×~·´rò;×8!ğ”bÚ:ıOä¡HùÑ4Û$öw†«læ}{ü£F¬2È}ÖgRÀ5»@“ŒÃ§2U¨Ó@µ0ã§zW8ğÕé2^3í‹ÿ°C^¿0ªì¿#gc1îz°ö‡ß˜í¦4Û9]Aø)øŸcŸA«,Ï½+¨™@fF±.#WM,šÑ—ñÆ;,)±_ıÚäõ2â¿>‰ÎÚ%uÖ¼¡{÷P¥R6¹–â`2š-pÒçõ¼ƒ±ÿöº¡"[;’¿^e‘†ïßüĞÓÄE§qcYDÜ%T¿Ûâ·Âk|›–šÔİ«İÁM‰ğVi¡QSâTîúŸ	pËp,òÊêè7Ò¼¯÷A±ô×` _hâ5N)îdædÊ}wúÀng pë¢„Yçî©E;“B3¾ğÇ­ ¡ø'6 M2`ƒÓw{IèŒR¢~ÑÇeeøl6&/<p×§Ğ‚Ö:ÎFÂ2õÊJQ9å~m8ùefjÿ:Ü§E#/g'ëçW,§EõÖ	¬Vaä–ˆek–m˜ÖÒì¾‡+˜ï|¼§P=›qgáõšõsLNCiŞÂl]<T´÷Û“°ù°¸(sé{d61ê’½hÙ{k²[E¤o`ùnØ{[=H¨ä|D‚£¯Ñ$§&R8rÄ³ëâíí?±ÅéÆWä1>F—3$÷"b—„a7Ú„¶®OjO úµ)±³¬ı~ È8õkw)¸®ò‹½fb¹E)kÖş˜t#!Š·—YéìÛZèÄÆæXì¼pÈşŒêQ}Æš8ïd…¸á­ «…Æ6©ÅÍêÄ”‚½ª­ƒ›î
´ln_ƒÉK;/(9ì÷Ó´Ké½Áì:ÉpQ¬ÔjœÕ"í6Pâí÷ä%çõ•[Hd¢2›:ÔJåçbmŞ%•²eŠ˜QRÀ!+:«ş”j7††CH§(Ô¢î÷±”2J+S"±‹OqœFKHõûàI8ánÆhV/•Bpø­Çu¶6Æ
®ejYi9EØÏĞ.ÓæÍ‚èÌ./ó‘¥Á‰1ã·šßÿr?&A:v“BÓ¡ÚXÔö^ÍMZWĞp3é¬"òù(äy<sÈ‰%W½î¿K•ª”L88,š	4p@ˆ^áŒ…a—Ï­_Áœ]Ï1Ø†™¯8ß!‡rwÜf´À­+V SäF;¯,º×£8o’gi>Íµ»Ï®î¾Lhe)ìá|ò8h‰¸¶¬7[YÕæ³šo_¨Pnöp[4û*Ô
õOÕæÏ²š“Åá	`y-ªQæëòË
©÷º‚«KÁK%±X‚+—üQ&Q”î¬ÙíèâºzŞÖ™ôS«H`âıCÖí’TU«_*>JÌ¾¼íÆ6g½zk…x#Ä\cÆx„bÓö˜ò…ÔÁºĞßøµ‘Ò…æ…s/¸"ó¢ØõÆûÎ	E)ÿö†Wö#”¾èÌŞˆ 0p¯+aâ½¨‰ö:•º¾1‘%TX-$*êKGÖZ‘`D:g½¾|.e/a;J¼ìR¯£»rD«F†9q7úÔUkŸ%9›O²óùœá‘°Hºw^aÛã±3^ÎÄt©,ìÃ`Ç0Êphı“ƒ½´½+¢1@˜T8ûF¥3§‰òc,U@^¥‰øîÜşiS’?)œÖ‡P:>Ã¾·I3g±ÜN^;„§+RÕLúöB¤ïüœe™çRªö • ¼âi¹í&œ¯qOµwÄòRÜ`³â8Ò>`ââyKG‹†tD¨bCô6»0ñCÆ¶‚3ÚÜ37½±¬Æ¹‘ôÔöŠ‹~V9VSZP³©Œì~!ï1ğ|>p2y­37åÄ]Š©·›á
J¸µ5 ¯—ù1=4aÌR_PJşyŠŞŞ%pçúè¹3õimë-U^ğ 3Z¡IE-±Œ_„÷(š=û‹Ü¾©f[­º*b&F_ëVHµÖ‚î©Z¹®uÊ/A'Š	AİH3%D¸”C€?Ê”øÂímÂ)ºÁ—ÒŸàöµÕ}M÷`yélûºS\óe^F³öñ<,¨* tˆ”Pú^
Ø"—ÿæFéğÑDÓ†ád ŠŞŸÇÁI…Æ²ÚQşyÕ
:xÀPØåè_rCë€×h†nô?&ÓQ$¿ñ2ëc¡Q>Øïu!’Ğ‹ê´&tÿéKi!‹+‹²Àé"Œøâv__xä§´P20]­İú8«iÔfèÜ	rUm ğ}†JîÖUø›k„@"ùç”'*=(ş~ ÿ=B†ø.Ï¿z+êEGóŒ½.Ç©Kj óIãİæê©4'8}Y çC7(‰»_ôM3œÎk@”Ü˜‚ìD§Tì‚¹IŒîãÅTİ–åu­ Ö¶ê,Ë¢ñï€@÷Œ^xgäöáŞà*g´Ùiæy±ó^a°!9KôÑ¤Ğâ¦r ’²}×E „È­€kç6y~dµ&áĞXïDf@@µõèõ·_Dûç˜çûì_
uïÂHìúU™]¸|V“ü6F2^B ÎÅU¿A*ÁîE¯7åÅO İ/°ó£s&WQq³éHûmìj<€Ì«í{’­”Ksâ¦Y4Õ’iÃ)p{ò—´º\×Å>äwO „:,54v6%eÓ/Ü”xSƒ….%wšceÛZ+œ&ôW_¾ŒÿãÕ‹[{§¦¹9®†õ j{bvló½wI8Õ'QÈg“NÌâN6ÚÕT›'&×„Ó©7/oJn´ú(´ôqIÿGƒ´Mõ,Y¯Õ#hlò-&ÆÖP•]/Ôš&ŞÒ²$ˆîÚğtx6R;ã¤·2CÕk’/NğO˜Y”ø˜Ì*Ú!j03×ÜÒÊ˜ñ4JÄÅ4+…~Ëi¡ÓîÈ„N!)K5è©mziOú}ÕtÇ 6‚ŞKºı½+Ú¦§Câ¢ëÑñ¹¾§:ë¾BË™ı	õ3M‹êIê5©_~L™>Ñ	bâ«¤-Ùâ6Ï·Õ– °õD=¥$Os'ºA’šÔvıÍ>s)¢cãB^kOBR(‰ĞÆÊadÈ/¾öL_eSMâ0d³Èši5­ı	èF‰F´ŸÙs«Å¥g~-¸®9v.áH$ãË€8cÈº2Ğƒ2,WÅÁš`ƒ…z3!Ë»î_K%æıh8Û¹*ÕlÌ[ÜÅŸ)ácàM!ê\Û¹pİìp6‹5NYı·»Öƒ˜QIƒb{f6ÌG8÷‰“m‰í ‘’ÛoAßÿÔz¸`JXí (É¥ÅOëÕÖÔ÷et´«œRÂÓÛ±hú¦`Ğ‰9éË^^|§Ğíş1ò?OVî±K7:±êÑ¨à˜<a1şõº31mä½¨Ñp„Fª‡Šdğ%'J[¯kˆd©yèØ•¢§3@°†ÇˆònÃ\yãæIa½uL1ú±–®;]à‰DšÔ*=.gBc;õNFj%&Ì¹2Xüq|– ×ß[äâÔºª YÊ€EFÖœ Ê×<ØI}»b«ÅÔÏBºÙ'1ätvPÿá§YÕ¶[€N“|XxŒ¥8–OÇÌ.tm·5l@píË%Ö<’cÄt£o»„˜÷àcŸV8KLíwÅÈÂ©o.ÅÚe„·…ˆmìô8PH2µØCÒ¤	îtÑ¤ä‰$iúÖåg2às2w=z˜’4:ì`‹Ëm)XİS¾Æ?1rÔ÷õ{õØãïç%¯²Ì¨R<î§`9N¡ÛxÕ“y:’ˆ4§]Û7Íÿ°´^!¹ƒÂbĞ¬5ŒÄà}j(¢ìÖÙÄävGTĞ,Ìcï˜!İT`jz÷º“¸u#¡âp'pÚİ§=‰Á–7¼ØÊ‰şjÆÕPÄ|Mk¹KûÍTÙ´ÔdÅ¢’ÜĞ-Äõ#§•»Ã—î¿ş&•ä–‘x±@Ë·Å¡•²çùn Ò)@+ ë²œeM\ûìİ@Áî-!n±ã1î^®Ø¢,73ˆ¯U:ÇÀÆ}ÎypM7ô#˜'wµ íÍ›àÿ.Ó¶,Ò)öÃ¾Œ#^ÛŒ÷^8,C»fô˜\‘z€Ól§¯Öš¦«_Ÿœ.m™jÅı%@ÑäjØŸ2z§$‹èhÍ™1ñ€"Y|€
ƒ›¥´êL7ˆó³ª´@Ö"Îa×W$H*eVa?ƒµMlU½è‘ó¬{s3ÿDJß]¬åh½ãæXİ²WV›Ïb´yBEK,ñ`jÜ#~öŸ–ñ¼îCÚ
.LuŞÓİ¤NÌ^H`¿q_î¯ ïvñ¨7XÉa1$à›İ.Ó­˜·Îm"°ÿGy©G%f·Á û7.<	¯&F¢7#Öä[×‚z ’ËÛîhĞp³h°±Zm¿QL&aËXp ï-’wI#0¿¶İ¯ºx3D*Ö¸‰™ÿQ^ësÎéxìÁüw-€"nñŠÈ€²‰Ñ*¹0êÉşÔ®h8Ç)ìnÚLm3xÏr®ƒ~[7º²l°œ/±‰¸“,ŞûÒjí€ˆBr];?e#æk*RRmùÿÁ#¸òy´«h =ª~·'{‘iıî¨ó›Kz¨(o)	ÂâæØ§3«^SÍ¼©»¶O±(”¶!³E¬½Z…Á& ,G³~&"ò;à¡‘ôFÓßX.p`¤ì5-`I•—öá´V¨Ñ'^T§cÉºÚCµ[ÍÉ)P’$èüñèğ	Œ„KËjßµô$êP±døMşLAŒ•Ÿ¹£&ëÔşs·D‚kóù‡›È÷F‡§5Å|ğÛ¢QŒ‹¢ƒZœ*^Àô¾³œ\­'0f@$áô¢®}Ô·„Ãî0ù»ØŒ<À€61/®:Yh±ÕÔªÓ¨İ”_ª¾)©c]©c¨î©ƒÛjáïŒz¬!fgo‘Äƒ…Mä<Ph¼;XSèY£^£vëã¹´lÉÿ±:8ZZ28×JË…Ô2ĞXÎ;ê0¥ùÁ×JW¨J€ ò<SÚ^pø£™I0…ÊjÏüJ©8ª&ıõufµ°J›¬±ÃŞÚÊùLå§âå6y†KŠño®˜\‘š2!“{^ß5É¸´*H—“K‰¼kA«Ğ¶/îyr‘Y©ÒãM’¿ÇIU(„›A/®¿/1²±ÓÈÒJ3Ë>d}–”ª{V¢Æ¹Ãªhm¬ÚÜ‰¤&ôpé¦äÒšÂ;ò9Im‹òuF&“TV69²OAØM@^ócï~™v¦a1RÚÕ„ÍãÊÚã£ù?=ŸÑ<jüá×]Ø X^¹ZE&¿±Ên¬ÃTÀ=¥B…á14’¦"ÔTtNMºÕìÁXècßnF¼×H¿vd*ÛÇÜZnVÃÆ*¦¿›Ï}p©:¦ôÖ“ª‰†u&zÇ¸†9gãP€Î¶|(w€~ˆÖWF‹³­Î­-$e	eíz	¡9_QplnÀLÀDJåÆÎ•ˆéc^«^_¸èvN+NZ—[¼^<?gîàg3€¯§¬Ç5L£"”öYãƒò³š²ãn–bIûß£k×ø‹×Çó`Ò¦Í„‘ü³Ôš'¡)9ÁX2iĞlÛÙŒaìf¼EBvÙh^Ùü{½Íé’w‚±´B;ÂÙµ$wÂ€Ÿiùôìşí6ÜÃßÒ.i;ãßoÛj’Zrİtb´°í¯ÄıĞº@g“Ş¿/ëÂ_íd%Œr¯3s,Í”í°{ïöº³Qÿ:rj¿6w4;ÙwUgxÆŒÔä`åŠj;¸ ³Švøx–ê¬1!·SŠU›ã€c†Ï¬
ÖÆvVÙÜİ r€@mî	S2:üBÔ[ßp°¦Ìhê¿>'kXL¶30pø§û_Z)enŠ4š„%’A1÷äÇgY¼]~›à†îDã±ş`˜È÷¶æ	p+ä¼_nSïÊ"|@CldÂK¨0 e¤Ö»ZY1xTCgZ 5R:5öµôş üäğÎbÙôâà5O1á1ƒ›×F±ä´àSjÚOéŒ>)ÛA’Lo/ìBf¤Æ„£IÒ*Iåá¯İZö/·¬ª ± …8
÷4gJqŸºrÍ²(w«MXBEÈÎvğfYñô½Z¥¸gç€¯»IÚE>Ï,À-«±ÓVR_Ô!TöÈ SÇöŒû¼C‚¹ÔCÌ±-TÙ(½Õæ“h5L×Mˆh7÷/¬Ø&B=çş u²Ä?ÕÇ–®|[$xSrëIê&UÎÜŞd.seYÇ¿İÁC]#²ATŒÁ8m<¡õõcYòL<;Ï]QhG¾?æÊåİ‚5±A…ÈV4lP¿5úö±2lnèú£D'?Ø$ ØB_+ÔqÿÌ}–ÈüRiÁ¦¶İ»è“@™35éH“"J[ÙÊ$Ì¯fmyw—–Õà­·7ªûÊÚnL«Egòª²±RÓÀ”û¾ÍJ›Å4"	ıHï¡¥0T$Şú·˜¾]œ¯¾üõ\•İÚ‚½ğh7GÀaß2ğ®äÆÜ«_Siü~ Ã¥Ì%Z)ôGA©t?‚Ù>­t¨Œ'cNèÿç 3•ÚÀ!Dßç™qà‘L·k˜}3×ïÉU=€ĞGÊãŒ©46œ¥bß½&´çÃLJ”ô§Q¤¹æ®¡Âëé» ¦İ‚oº¨‰m*ÿ`ŞÚâ¹äÃÖ„DöYÊq‡ˆ¤şY[j:92Ppõ-¹¦Sv—ŞÇæ~|Ú¾AÏgå8?çéù\èäLÚ8gş+‰È —E«‹J /:oŠš¬Î0õ6µIP>ŠrñgÈ—rğ¯à¡{­À|cnêŠ•ª˜Õ±”Â»wvÀ±´;giw° XÏe®Ÿ!2X|iI9 •²7ÄiÎ1û¼MB?·şcÉÊêÒ=°$ró,B„H¥ò"¡lNXéU\^dfQhö?FÂËÿ-\&º¹E¼VS!À†ZßïêÔFŒ;Q ¦<„¸À–Ìü"Ë2æGf
|Pù'÷i„†íö¹©Â†^~õQ‰Ê_F¥\‡<cá#[\-“ÅûË\ÉòPÉÊx™êX«%ÏÑæLœd[ÿÂøú6€<§jÉ™†@Ê/œ¢EŒ7ñV%@q<KyOÁVuörÍãµ‘%çê ïÅ¨`Î…©¬Ãsç˜ôi³
ùÿÒ‚&DÈÎ¯ÅåßhÓó4ÀÌ>òştî{ğê]<Şk{ÀÏ#Ò™ÿÓeÎÛùÅ¡Û1Õ˜¶õ€(ÓÄ&	1 èº?ÏœZ$£ø“¯1yj6ÌJşJ¯§:0ØsˆW„drDj[×º ï¨c<( Ğ#£,%‡ŠüªÆğÑuÉ7ˆ;Š{Ë]êFÅ ˜¯VÂ‹WªT{™fUÆ3¼È¬Ë£˜
+Õ_¿±†‹¼	†z^›°0uŠxå|b—+î#[tH@Öı6t…Sês}îkMÍ;àÒ3%Şƒ¥R1®ilÛ±…v?èùÆc!eƒ5 >|S·¬<&Z÷úö)señöƒ9Rƒ[íZ„Úª‹EDÑÎ6yD—>[[ESyƒ<
uh,œ\î,®[hùàGCìoì[„ •bVeíX|¼®ƒ Ôrsí‹ïålGŸ«Q)°q"@6>‹U±éñ·®ÆÄ¾Ï_ˆH7tâ¾ªª2ì8t¾º²¡V\yøÇú(Œgë¬Ú^97qgw[öf¶*dƒC\¥oîA‡qB„®³œ+;;Õ–ñs„Jé¡ôm¶‡ üL Üh{ášF,L«_šSL8.]+Ø0I\ˆeªY£Í4M«è6ÈªµìSôv‹K¨¢WSïÂüdè% °¢ã‡åR6œX‰‰·jÔ³E17„û-‰dæ—GhÂún>ªbzÜü" àÅJréésf¬–RU‰ä‚ßpL4Ë]&òYP_~÷ãD`ªŠ£³t7€V¯ğRí¡}œÅøS˜*ÀµÓ­“×ƒ©‰GËˆ	B¥ÔRc&¾‹¸3Eb{C›«¬ÀEN+åmŸfı¬l—ì0³ûæ
 H[iş[Ø-ÌŸ(ºáˆŠÂ,ê±û?$ØêlTŞwÔ)? C!Œ¸ë×HFà)ŠØ]€çGe@
ÃwÌ³z¼Zğõòä+DÏ‰òd,‹§U©ØŞÊË>"8&À‹¢CÎAC}dOÉ ^¢<Ùh<sx,“NÔ¡Ùé± #3¿«2G9½(8şÏã™‰Öû¦)E>~œÌñ?“PÂ$S¤öÁ"]zğÚ~˜ì³zgˆ¼×ÙÖwüe	;«‚ú
ğ×Fõş°X<üÉy¤šA¼ˆ¾x‘“Ö¼^ïŞåèƒŞâŒ=|±óšA9D'ä¿”ƒn«›îPÈeäªâ)éµó±Ìü‰™R"Ş¥g}-­â€Z^vGÓ…’H¸]qÙ™˜²Põ¹>
…ö5Âp-éŒh
,£Q_ØÉ“µnìlé|®ÂÏu»‘Ÿ5¹
VÜµì]\ïg`œßiÅT]A]OhĞ_Ô Ô$ñÑˆÏk£üğB¢¢üqcul®ÔAVYQ™/óîUÜ¤k½ÄP?ß´Lrj¤t.]™XàÈÀÚK…’9Î.FHCÁıñ“ÑØÊU†Û-²Iİ80Xt§˜Æ™Ä)·}YPPï2 ı
Â?åö¶8t âïÎ'às€ƒiJQS6¾‘˜-çµÔ=L©½¸yÀ„ğJ²2è@İºMBü×üdÎÖl¸¢®%\s2Óş³‘Ù”ıãkSø¯w†ş ¾ƒìµîA@Œ(+CÈü&/Ì.°©=V±]û$†ì„+HßVò-Ñ3d<X±´+BYçıÈ#é?Ø1@mPæ´± ü–Ãáş¤Œ4¼[Îf‰8¡„c2·dMúB·Y÷
Do4Oltæ¶?>Yˆ2€¹G‰`@cL*•)DL0,#hÚ‹*HÈçsB¬TZ4¢óFıÔÑR?Ê'\§u‘ñ^¥üÉû¸;÷ë"²O”PsØ£…wA›z¤åSï#:Èt{ï»ª™gFæSæU‘Íô}%£«LˆgU³—'õ"ôœ'ˆñ$&€´7¹A²Ñ­f_,|pŞIc®!n'q²EryıûŞĞ¾Îe	pnqªKh²„iŠéõ¡€æZYßøŸŒù¦xV %À_¶¥$½ètú€#9¸2ïÂbÍ8D>©šæ+Ã½ıŒA¶ªì´²,‰ß”g‡‡2|è§ô÷([!ÎÀ,ç	Î0åèW¦Ïy ¹N²Çtd×TEÕõ¸Úµ,¬zNâSùS×áÚÒîÎ'­¶„16¦q&}³z4f;oìrWÓ¥€ñ:/‰ØÍÒêW¹uí2H§‹~àÿ1ù(yènÍB¥šJ1·¾INM½Sª‡­Í­0àÀİĞµÌèëyÊx²¹â#²õ,´àØ?g^7UíÁïmOîŞñ6¸¾½ÖşŞ0ÁĞ,½Òõæ¿1‰R× \Øv¢]ª»HyæÈu:Lß›v'S˜µİá“%#mÊRÓ{2&œíÌj1öÈ›PÚoÀ.<…â·ğáóšõ•ìÙ‡şÈóx_ÂêavqÙW³“]Â@28Sf`ˆ,ùA¶>¸5¢î6„êiÑ~vm*:×‚åæ*…—Èeê	/‚Kèêùãßr„=rgÜCß`ëŸeUgÑ
	ã‚¬L2¢&ˆUû5ˆr2âMÉØ#r4+ú”‡äµâºÀ‚H\8¤÷´¤f	>–¾UbC{}ggHİŒ€Â³¬—]xMJü,‹à²ßHŠ²õ… }9¨J¼¬CÔûL™0TöÜÌ+`Ï º‘Z—@3Cµ^»*ZRZ×X‚ü½%İˆy„_ïÏ±Ã„ûgùÑÀÒ
¥„.v¡şn·Í`‰ğ“Ae(Òı›ËÉ±ò˜^$Òo—~Ö¡àê<Ü²eâ''Å$F˜'.3{,ÙNuím†`–Ÿ¤Yã0Y=KN£Š‡‘ù†p\‡ÔuTü:Ì)û~×4ÅaïåIJ>şÁ‹j‡`:¢>á0ã$<6Ğ£¨Ïğ_¿Ş$5^³ñb‚ÚdbaôYŒ¯hŒ3§¨²Aµ´ù™²í‘\¾ ŠiE¼T€xWoŒ=G–.#/×g~"WºŞíı^»L'^b—¡ıã[P@ˆä ñBÆf	˜˜… +×ÕVÊL>`)©˜YØò[Ëá«/ÑÍ<€™ú5Û²í@ú•˜}â^Ö-àŞ÷‰\Ènà4|_(øL¡üXÛg94	í»Ã¬¼ÒâWŞšÎãØ†’hÎ÷(v{gçTƒQdª¡¬¹% öŒºUWÌı•\ø‘Ç4‡NğÎ`ÓÔ]º|ƒ&xãn¡ıÃœf&(°dÂùBDøÖƒ³|‚ÂrDH2Îà·•@ÖÀˆ©µŞöÁ«ğd!~£eÀ™z@>EoÖ ‚~}f?ƒ>.òŞ&ß‚6ÿ˜’ÈA«Z´ÎÏ˜‘•ÛF,‚5nj"àNc0÷c ë,°ÇªÉéé…#M×ª[·Á™£º§!Éoé>Í«o+ŞÕ”ªÜŞø4˜«ÏêZ¡kN%_RI\/÷óàÖWê'ïÂ%NfåèN3å¸ÍæNÔ«ªÛ¦*ÿĞD£!Q³‹?NzxI»H;¢µÍ”üW™3u9ÒŒxa`Qój‘­]#ØŞúü Ø¯_ %²{’V[|Äà¯¨É@H§İŸîşuĞV¾ òı‡t{0°Q³·›?®H`¥´ÕÚŞiÿ(¡z4×ºs‘«Ü@]Üÿ±ç9ËZÊQb³|îÇŞGãÁ‹[
5™ñaÑå,‰.Ïäw0#VµØë´,¸Ÿ¨^¯’˜×;¨kd"Èus7xSpWlì*8É,¶çşz]SmIAAwG¬»²6vw4&½:‰S?‰€|Ë´ñ¬z³<_£)¡v61kZ¶rMPïİ›“K®ö÷Ò$ aJtÚ¤Ş“Fk*íõQkÌT°ËehMuf§ùÛ=GIµ¹jÖÉG¾”„7|³X,˜­˜^ûˆoÙ="sÇåB”!À&>i,ş«n¦@Ô%-Ãµg’ëEß°[s’|ù Æ¬üX£ˆ‘…«ıv{ş¼(j^¾R)ZÈ2
¬`Kê”Ş¦H ‰©í=H±>_Cyn{>åÌ#ë°ñnGÖ›î;5b‡£Qå±’ídÆ‰WYZl‹°Ô“¢ÿûÊ5]uŠÏS;™+æ~+Ù)ÑrN}âS^"ñC=i’ß`fØ’Ì‘oò†£Î\6­ˆœĞIr¼¦Ã/ÊÔºhH|mI<àºUõèE[‰0Òô»%æ,¨ºÂ¤í\ûD&mÚ›¨ôÔ“lµbşŞûdšnó0ædŸAÍ Äud§ÂP³V©vŸ×bqÙè­P={ƒe§>ÙiÅF©^*M “±v™@ÙRş-•6~ô…~aY†Ñ£étØSsKÒ§¤Bİû¨ZÄÙ&ÌU÷<[}°ÂÁŠĞ ¤Ôeÿ—fåÀZ¤J¤ã`–tTÛ]Çƒ‘"*ûCbz¢¬xlo< 0]Îª¬X0=&®ï\ZÈ˜ı\WM¡ùc}ÍS‡ÿ›+N¨2„Nzèczn«7½C×ÆB3M£àE3‡[²"ğã°¬Æú?£–E¬¬ÿï[›MiŞaİ\,~ÑrÖÈáøe¶ÓKÜ¹àèìiÙËÇÕ£v9´D?²N?r9%ú%yƒ<ú	¸§
¢=üÀÛ¨–oã}°±ŠlÉ$@Pd±‹Ïıö¥ñŠò¿m¥2Tk2pİ½Sè
!‘·ú,J/¡QÕ#ÿ­„UçÅLğ—ä¦få¼+ÚÙÊalµCCõqĞƒ€,3Av¼"GWï5qŸ{E› FlLËª\g+$ˆÓÊùT@„˜õ¥ÏtáS•³(¸=˜nÀR`Îa™»ëÙ½4_çkøQñoÿi—Ûo*-Fáº‘éÉ¨ IM^m0mÙ3â
âšâÏ¨sT)AîµmáÊÿU³)3á†gd¬«£B9	Ú?„F‰s‚Ö+J@iµ7| åôr‚¢õ½zĞKwÛé,‰bPæÿ8Áfà+oº°=ódZÉ3½¸ùJ;,›Ÿ$¹f‹©¬V:Ï˜eoñÉâÈcíÀ®?ºW.‘W„§hmûÂ…†f5ØEëô?nÖ·k¥b	”
M,pîo~0•‚6£dä`ô¥7Ò¼J Ñ5—@ôS‘·ÀO¸²@•ód%TDµ—…Sÿ·°-à‰nå‘µüŒ‹oáv¤‹×@ÛçR¬nùÚë`ÄOšîíp~ÖÄ	fŞ)m¹#‹£Ğg>­èŞÃÛŞ¶½aªÕf†w¬’ø;t„ï+wzŞ6CÖzLğ‰µg«T„•à¯¬|İØ²İ>»ªËõ±œJNHÑÉ‹¿ü÷ğ56eYâ7xHFIjy9ßîÿÙiÉDÕ»‡%dÁ¯.ÒµQO‚)Ÿ`&IT¶°×A´ÕÙH3	¥dú(oâ¼rHhP¬ùLá®yYK‹ÃªÌÓÔc7o¤’µ’ÖíÌnÚìÊv$A=KVùØSØËÈÂ‡P¢Q"*Yõ;†ub
ú¯õÓ][Ğ]Tñ T‘ÀË¬£×HñÚPj¯ni’KØ+Q (ÆİŠ5)hF”’»ƒgº¨kS§â•ê½S‰¬Ë¼À&èTöñªö­3ä@0ÔhhmNmêiö
¼“)K`ÇA«	ÂÜò.0­h!Y–™)‘¥î(Fq¸³?YhÄ'úÿĞıvÂí4æŸùÛÌ|’~35âÀª^.$sñ—m®¿ˆqNçæ^K&€Åñš5á"Î·¢Òìra<éÎ°ïïü@Ó9}‹‘Š.ìÜ™ß°n{§ëI0	Ôç„ÿ;\O;DĞÖ‚œÑ0=’)ÅFDšÒÚšøÏâ–ªª{]ë,óœ"wQœ )_ô¨™Ì.ø+gWùy’5À:òÅ_uƒ½ó¯ìö¯QÙ9:QÂaÍ5—“”ã¨W`¼¸£fARAáqr ½–'ñ}­INJ´¬2šÛŒ ~ùËo@8ÖªÍ°Ö éEqxr“ÒØñ¨óîïœipå*îWi«[tafş3gÄàñ[åÍzvA²1–ãìÑ9‡ğğî½ÑÛ¡5-ì\÷1»lf¬´ŞÓ—³X­Ç£-&ÏuÙûZÛò}DÑ‘E%\((·0ÔêzqLØÇ}e•©zf„ï†4œî´*Qx¤C“´^‰‚ÏÚ¼?±Ot¾c:ÅÈh®™?ÛfW¦û–M/q·YÉQ™M1´Tê7QÄ'–şÌ@Ø­ö‡Ç%x@1|uˆp4ßÁX€€ ÁÕõ*cc¸îõ‚z¦(¦m^}ë£QuœëĞ™ÍèÃËNÙò=Ş€T¶£TfÍ·³á¼K[‰eŸšbM¿¿ƒ¥Í¿ær“Úâ$N-¯ÊwÅË"äº†±Õ€dÔÑ–ğêˆ*îşŸZ˜Ñ•¨™Büí®NùY°À@ÁYŸjà¾^›Ó2"¸n{"#;OSÃú˜ĞÌ¸üÛ;kIbLMHxUKV<í>°4u¹³S‡ 2“İ>Ù¢Âçç%áˆ8ÓÙ]Úk“]HZì'ÍgïihL)ìvÖ’w”ËÎ.ãØİ–]Ü±ı•‘FS9W‰ºõ ´i„b*8Æƒ¶—5!l¬%&ŠPüwÄÌ<KâãÈøùÊVÃR×D/ìß»T0”¼ìÂ¬ä­m¬ó¨¨„¾‡øæ1Ä¬a¯àï›ww8kÉIÑkİ_B'E³9öW¾´èo“«˜"—©Ã®è®*º"¯e<Œ=.ÒKØ;ÿìÎ~„_´Şœ~í–q7'a^<ãˆ·|Ô§Ãv±› S±r’ëÌDÆ¹ñ´Œı¿•Éµ£UR÷‚µ
æ>Ï÷ğ­ŞÜ1äFÿÎîö³ˆBòP>n´>pØ/öxJ õ„*-«Ø¾Ÿİ0´?doÿß¯›jfhê›k ñÌ°ÕÁXğ+ŞöÃuƒÖ$üÚ…e¢|
äJÕGbF§…è/ş¬;]«ß‰=Ğó—ê]ÂU±ÓíŒ@„‰UJ¶÷à–iÅôX@ iª\€ŸÓÉ™YÌúp´9	!q ²Ùş|ğL@¡ãor4g:W51²wi7÷ltk6¿BtQ¢Û_Úo”ã)·‘òd½ìeYZê÷jùV=Ä-èdrY4=òE.O°è&õ˜kfâI/>À@¾Ï´³­áH¨eó´áÑ@]ô¦—õË‰š^É,ÑÛ/±•âÅ3°L_q_òÙ¹ÿ½ »d6úE“÷¹>•6¥Êt^`˜<:¯òÒÔJMÃP¦ ğˆ¤Nr%õ¥ĞX—½£ç‰Ì¶b&à ²¶%zw\0à¾ƒPóP©„NDü•˜òê•sHYğ@½>gvÏ½~[î„}Àx,ğUo(7…5¡ù¢Iq_é¯„ƒKå´ş¢d@e²_Qk:ãHa=FûÅP:pVkÒß&V Xós÷ÑRéş÷İŞu$[»yâFo
ÜwhÆ…¦	PÅ7ZÑ*B0ªÌÛ”Ô]Jäàx~P#!2›¬ÅÉ,à;òô·d(u!M-F3ÈWÙ³Óù+UÁænİÀêÀ£Óeúçrî3®ÕyœæìÇÌ²`IJ’m ™†zÄÚ™t¼Š<´Áï] ¡üé5æò7K²Êÿ‚’ñÖÑ[¯‚¹'³ğÔü½¼Í"ËjP`Ôõ—
+–qyRÎrlTLƒ¬m—M0Èøôõh6‡Qwv"Â%Èè­\›Iõ?Â‡u­bm¬¤uyYsjoıïóš]z3,ª.y„¢ùÍBô`ˆj’d€KÇnZìöıláûşg¯XÃÔ¥UVr…éw¬ó'¼kõ3—¦]cÓâšÜı3(4Fù  ¯<F¯h¬HŠ'Û)qÔí“©	/a|Fñº¬’nœä|#Øuñ—Ó™Œ×>k
Y@©Ü	µ”(ÿ]‚ pñµ‡e‚KÕa¨‡ôº×ìPû”ÿ·•pÌnC‰©Í5u«k:Æ]&Ã9f½¬ôp`UQX‹weÍ¼ø¥‰@t ßÇ¸!—®âç¨
K)"£ê§ÎDÃ®{³è„.Ëê¤3õmÛ_À@VºĞO=›¬bŠ˜4bˆ½‡éÂ9["|L;æÆáÃnİª‹]r†ş_­<ëª6PQéH°!´¨qïÚ)@,f´”WÔÉjŠI°=døÔÜèBO9B<øë­Œç1ÂIöÑŞg±Î™ÿÎ:²I Ó\RKJç,pæE=V4j5¢nIJ²Ş--;ÇQş=Ÿ“ÅP}H²©VÄáñ¦?±êÁt~8Ü¼ÕuÚz[ÌÊ> ¾RÿUÒ`‰,íÚ±,g=›µf|`4ß(Œ;#k„·§C%líˆSúï”’æËŸ†QŒÆG}r}n0¬j]$$Á‘Æ’¨˜ñC,º®®É=‘ƒ*aIĞÔ­~¾.NVCâÑìùªu÷OA÷˜Fg²í¨^$Dß¼&+¤ñ_ÜeY‡$TRlãó?³àóv²™õÿ‡xiÈBG¾ªÓµ¶†9 ³şş|s–·©§	íTâ#øu£&p½Iá^.‰™$÷ã+½ˆscÄ“s“™0ÊÖ€shI¡*…4§D‚×Q²ÕR“ı·]¬I¢@8¸T‘Íë®HûœTE{=¢,j^áŸ(:v}Ã(5 ĞlP.ˆ9HšzìÑS«B€e+tÙÉİÜ–•-ò[­y°ÃxMNÄNC=ñHÀ¡Ä‘— Åz³¢Õ®i|½L#”ÅãÓ™şMA¾èºNêÑ%3ü¨¤ÉĞ>äí†« V`9Á,¨&YéÿƒŸÿ·¹z„Vß™şìÕÊÔó{é—“½ ó Uº4O›ì!@> ¡†(¤×1/‹o¿‹_§ÍÊq]_ßsß)][P,¤¶BI5ÿdõ"6IÚ|\SÅÛ¶oogQÕß{ğ¸œ²XI%æçÌ¶yPÑåÆû…¾ç$/]$iã£ı¯íëH]†®4$Ø
Š‹JÏŸ­	Èø¨}{²æ«Á{rE>SïOÛUÒcæÍ®z©¯§úqKß¦ÂTuw:ĞA—LTTaB+÷8F7NÕNˆN'¾bITïRª.
nÁšŸ¥€ü¢—æ§
Ñü€¸­Üª‹cë8E0PâÃÚ´X¾~äÑFî6÷¿}«NËÍ>æ¬9º¡9DìÆŒÇ€•”ÅÍKÎOû&	T ´.6ÛL0&Ì@şnm$‹ÊAÀ¥C$'Ïù€døızÅ‘XnvŠóğ§Ê
9Ï FZ¾ò Î>ü+`të7.J@VUäq¾Àr‰u/§÷xfiñ]Z^«µ¶À¨Ì©bØÄrå/ x™Ã„µ¹Õ$ívû1kŸNû,ö3~S3ŒL=DH™äåØ*Kšù_Á¡éJwşCÕ…í–~ŒÌêOA^­e“íòsM»oä=öımú›Î(İ¯G5õÂg¡ÄşxTh´§_Â¢ËgbôşˆsNÒ´8réçˆ]ùËæñìÙÊ8=‹Qñ™äÆÂÄtŒÕz÷¶dTŒ„|W-ùS¤¶	ï'+µ7&«oğE¶Ğ9)&ÅÍ¼®tœ;²Ë‘ÇpÑÙ4CºOGTÛxÿ;¦Ösrîæñ‚Í´8¯/+Út¡×¯ÜÁS`!¾Áä¯šB*›[Õ øÊÂ˜æ·¢!­†r¶‹ô_´Ä¥:(!R—æ1W'Ùä‚.	èÊ=Ã’iT*Ãæ"C#.61¹úÇ28ÍÉLÀ…Ãe=HÅóñî»“›Q_»‰ü”Ü
nˆ‰?² 
$» H¿².MâjV=`Í	”!3K‚ ¥—µâà-’KYAY“ß‚Y|”‡_ 6$°ĞN
ÓëÁöb#FÑ
Fk‰WN<ñòÜ
áÁR”©şÁ/u•W     ±,å rÒŸ" ´€À|ƒéÿ±Ägû    YZ