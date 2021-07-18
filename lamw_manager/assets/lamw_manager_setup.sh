#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2500752553"
MD5="4de8ddcc164a00322e68826ae11a0792"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22780"
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
	echo Date of packaging: Sun Jul 18 02:36:08 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿXº] ¼}•À1Dd]‡Á›PætİFĞ¯RQÙ‰š“"h†tÁ§M¥±šÊvf©¡b»Ön`Ö*~‰\ğ
áİUWÏCMc¯étV\gLy*¬´#”\½[Á:q¡D4«V`ä7š£G ş´óÌ…†qJ|«F9åÏÿBèª×µšnpdMá&…’H_P‹¤V˜E9eÈ’ıÂ%0¨ˆ 
ó+ZFIk÷”)cÜ«EÈNÀä×Ø?P®‚D©E”ç¸sù(Â•ğ%Ÿ’§¿Dn:8’1×D…êƒiµ%÷Ö¨0°oÃ†æìªàğŒ¹Xë'º3	”R-tøŒ„ ÆY!×0P‰ bµÂ¢Ç‚ª 7'›ïO|¶m‡İ>gÎãË—Ûÿ º2Ò½4 ïêÖ;^È-RÏÁ%b¦¹wæ¼{gˆ~‹Iııîé)X£PR¡Î„]‹KGÁàfØÆRÃ%œoŸ<C˜ª´è»½ní;ÀœæåâNa3XÀ´/÷Oß§98HÖr¹…V6{(üæ9éMYİ º²’·szŠŒ¥Ûfğeuáá”G³P6¡sñğû¾Ü‰$%	CŸÈ5»Tr<uÚGŒ'9Ï£$úêùuÛ9Ë*İI­İTõML'b‚©fë(<™Ó>{¢ŠáFzoÂõy7}¾#±Yù4YGIÇ|,¡‡³ˆäÈ¢*9§ÿQAú¼ùÌBb7Ü<˜^Z:E‡ĞğuÂ«ÇlåO³zŒ¨{ÅNG^¿#ùÇ\õ_¢û„Ñ{P#‘{ò¦ìd~=ì	Q˜vÛ6°ç¿ ²üeÌá¿‘ÎÎD±¥ÕcÎß-ygV€0_¦rÀoÄŸ7²Y¼Æß·ø¯(..+[b) Ç)™ÇÛŒ­İu®±6½6XÏ… ëé}»^\cJ*K8BDÏŠ^0¾Œ·ÑKuÎ0ffMÇŞ®şzzU	Â¥J3›ôµ>…Hçã?øŒ]}Sšl*°šÃUœ§¹3Ìe
*—áLÁ_kƒõÛNTº2pÙPîÊêœ–Ò,V·ª1DÉb¦á•5Få
Š/m8¤Xµ4ÿçSüûÂnôEXét~—ÖÒ†õù‹•@Âç{Šì’Ó%
¾˜æ ÊÁ¢T*åò._:şEÊdö=_HidÕÀÑ…[¨!ù‰…æÃy?*ÛEŸy6(ºJŞéöİ¤ú˜‹ÁIÜFfîQ²©‹KaáPŠ$e9NìRo0°H&iš×7®2|sÇü]ë¯,Ô
AaÍıšÙÍKüéFè0tíM… M@`Ä!jÅ¡€¦P¿°q—TKçp$¤$hEwê`âIq1›;ÈĞàoõI)VÔPšDÙµxën[‡×ÌMâtF3HÍû 	³)Î·´œ±’ó|Ş|8¸VŞB¯'ìG¸ÃL=ßK7²ıá'!„ÚÊ'³¤¶nŠ\Á¨Ş=ókÉãY_dL³Œ“(çÉ,‰\óÃ:6yF]†eœŸ‚á8·ç³NrÒ"I™WŸc¶‚¼4æ­›İ°³“0!HNÛíµE¿·ïe8Í;ÑE9Á}º	Õïlr_$ß‡h¤ìP¿‚(ÙféŸ%ñ$ Ja
îQå(êÓ…Ëtİ5BŞŠb¡¢p™wAM%ñejMI·FL”µ-ù/öcs‰Ñâ(|+½f×çëo{µã»Œh¾š°f¶hbÓçYsGìò3Ç(oƒ‡– dˆšA üZ”*nìÙQôyœ÷‹Ò§yo3S+‹…•Æ…_äœ´UÓŠ
cXŸpü°#Aê.&¾D¹âbˆ`ôÇñ÷!X{gäó¼ Ö>Ñ0!…©‹˜éBÊç¼=ò
ÅgÓçó‚§BK|®6Ñi°	ìÖFÊ…ìœÕ4ï2ó{òĞ®‘E*Õvà—P¥@¿,2è§÷Iä”³#-†@*&-$ağäy«¯Íd¹¾ah6àÖ³íq<¾ıãeFunj<	Ùô?"ñ‘yRïW2öwªBJ/ÄjZî¯Ï)6XSïÆD"zz¤^r@X¥e6'Í(Ë7*9k¯	ÛqÄyD>&Zˆ0/ £ş(N0²é£#²L­1J<ÒêJÍt&¢(Ã*Šä½v-¸8ï¦Äæ_KœO\£sBï¸xTÑ‚ìËa ?˜Äò°fŸíöèMÁí™ÖxŞ-cw†	È(qN³Ù¶Ô¬O%Àêx+tH "©ÍsŸu\Ç6†Àh>U¯Í9Å^Ìúkk^ÖRDrvB´8¿‚œ± ‚à&°Ê›¿yÀŠo}Èµ÷ß¢ÈU²p_¹AUÇ\}êõ§3\}¬v°#ßl(5J.[i &‘sá9B‰üÉ‚àíeñÅfæ¯ ^ã \ZŸc~Ûâg"²ë8’É'FÎÚ}ëÇX¦¯¦N¨VÓj(\Ò§V<a: ÄúF±Ö.ÔOjšã*6Át±ÚL{9“ÈåíM± 2/ìq‘A¨'óæ©
$†QwÉmŞ¤$a¥¥õKöˆ’ã|Äº©ù®…WÂ§22úz…MıJä²¹yª£iğgg‹8xâ‰VÈ[JŞè9_'†½±·§lcîDœùb'§>¥oÚqƒ’*+X¥ş0n'É¢ >Æ«s8÷}‰àK‚Õì½@Dk	ÄÚÔÖÁ‡6£\½5²+ ¡;>7h™xBÊLÊ¾‚Ø”‚hL‹£Ä¦“ùÙñU³í“ÎšœSåà
+ÏÖö„·÷Ş ]«iß…­üåÍ¡”f7)ü÷=ÒÂ¬¨ÁµÕñuydÈó‚«œ·XÖÇXÎwª]ñ›1ï™UzÛoÔ¹ ›‡aÖ¥X¦.k™ÚµW¯¡œœ›V8n“óèğÔàììÀEH:ºßj,p-VD÷Ğåœó%‚¨-Ú#oª{ÏùÒ
ªåÎêL ô	õ4UõñÍKv gŠ¸é›<»c@Í:åp9æ½Ñ•*§Ta87;2WqM‹Æâæ-–ÁÙÊ“qšQî­4áØ¨Ù©—–\USn€Ô"f*í®V=!8Üß‚™Ha!^¾{“Æ6›—Ï×C÷‰
&şåç‡ƒ÷
Ì£ŒDLf›‡}˜ˆî³xu*gIÒ*Ó2¾¥Éz¶Êí¯ÈM§¡­lp–•›g‚˜‘Ú‘c¥¥§ó®T¨ì=ädjÆÇ§ùU1}JJä7ÜÙ%7İ¤«e&¬;Õ\¿ëèáaXØ13ğ}çºvÔõdøÊfœÄ?>Z(—İø—znjh]}B€£Â Nˆ§êk“æz@p8ÎµŒT Q«³ÊC)R¨¡GÅÃA?gûçÁyÆ µvÜÊc}`wTr÷´ÖU]'c†l,øS‘dl³uË~±É×?Ç#oÔĞğfÒÉ?2º9W4ÿ§]‘0ECM«Fç‰¸ =N<ÜÊØ±­÷Ö çJ÷°÷¦jÒ»-Ü±×c)Ä¾~Ì·/vŠ^¬'(¨¢5êöè¥Oä03‰¥/	
rˆD®Å¡³ı˜¾’ÜÓ)°ãNªÄyí:#hôé_¨~!i­&^"å·ßtZ ˜V¶*p/•Ü?ÿ+¦Yé~á(Öyûg:+?â=1¥¼¶wT[î%Œ³7ƒ‰×H`MØUG)µƒê)³çnsÙ’Š8D9´PXWÀ3Bg}•Š0O£{!mƒ‡ŞyŸŸÊm?Ú5ûfTî‰Ê)‹.ìCWÀô'ÉŠÌsC{Êğãşhì´°`§İ,ûDdR²'X/ğÛópùÔYÛ|·¾ô/mí–È‘ÂÆîĞ}G›h	Z3:[›6a	~ùÌaÌY]í‡,DíDO
’°Ï,Şæ…XGe[ê0BÄÌÆç°zÚ½­i=dDFoÕ2ÕŠ;ª	p\yŞ{ïşûÅk¼9é´$"Di²ÏL¤ÖÉ“×ë W¶Œó¿/F·ãms3ñáSïËä‹ëHzÍI-½UÌÌéaõkšòˆüğLkzR¹‚4âANl]S::yÈa1ßºKÊA#²G=øZ-v*¦C/Ø‰ì YoˆxÉo<dqup8¥•zAuíám­İ³ìŸn£ÊÈããeZ:[5‡ã…¼sŞÕºùôøS\Şs‡—;a0=$Š	:¸aî¦s€2«ĞéTaGœÂ5	åßÅÆ³…á7(^;-†oáe5`¬ëáPå3Â2ãz^¼wG®ë˜¶PîĞ±+ŸöäÜ§Õ[o†ö?8O$$´ÀfT8£ğ_4å•r^ôdÁ‹‡›Í£RşÔõç´i¼øà,<Mp…Ñ÷ç½jâ¯Sà¿'HßùS#¾¿›ÀH<apıéhkßXØá€×Œ•úùë-_È‡´O)enmººl“\À\pşÙ\ğ:Æ>H‡UQ1#<çü$qˆ¼Wô¼tèåÒbzÆbÚØ,]9,ˆ[şÊúX”•8\îúàÒkšâa‹§b º„Iº:1,)–”öğ5²^¿Ã¬Ş‰lŞxT·%Ö6`À,Ó¹ÒègL4«ø^ÿ¯|£^ëäµğ§+&Z™¦û±›‚¡ÿ‘Ì†j·aMs'·©Á1AM·şîªÖe#üÉHÊ‹õf¸°õ!ï/
ca_0yD1…Uâ&¨×º/ÕÉOxƒ¬+>‚ù²ëmdÄoO,*üxy–N(³e–9ÇG;ƒ_‡ştğ+cXÉÅÔúmõvg&e†IÄx›“qf oM«W…j¬qëšs×·9^ËOVZÙ()_¨¦~ıÜ57våe).ëÏ¸™;J=œVveëJƒà­ê£¶än64ÏQoíUëf¥ÛÙ5(ÖÃû8`.µMÅBV¨@J­î;®Gåsi—é~ÕB·A­»‹”ŞšT¯J¸¹›4}me›ŠóÖ“{.s¨dĞšE¢÷D0F¬?›uˆ÷ Êş›|úxd9±ÏºøÁí4å
¾†KÍŠG¢É bñB`–~pË*zèê‚,˜ñYRàcäDÉVÙnµwğpı/£®³]°ûH»_&³#‘jŸ4™yN…½ı0©cRH$ğ¿”½»Ç«zQB½¿oºÚüîŒ¿F0iYi^}ÿ6dûñÿ­#¥ö_šdÈÄ¢	Lø³Ü³&Rª3Û…eñ†{õT9bAiˆÅÈl	‚f-¡ÔÑÙ9xÔ¸F'=´Ô zReI‡SÑc¡—JÇä+(ÂR.	€PJ¼¥‰ã‚}Œ9q] rK=yËgEøûx/°ùSG™&•:_*\÷I«ºVÜ‹,ôÿ~‚‡'HQó¾$!^Gx›½u¸¹w¥,Z_ÚıƒÊİ—ƒö9±
ÂQ¶Nvf™®qP¡g~œ›÷Í/ìÊ“¿7EYï»4z'[œ\B2ãÜ‡G×‹µåu‘÷¨&€]—:›¢sßV`5'î ÷fü·¬¦Ël#ÇÆíÑs"ª{^p‚V€òˆ2È‹(;æ÷Ñ˜pñayaZ¢|Şÿ&á¬:ğ;_|ª§UÅĞÏÉ˜Ç"BØ<Ğ;½ìC}©7İÿMÊW|w*ü›o¬4CX¸øÈI8|¤\‹’ÂZA)†Jã
u‘c²°¹õšÕæÉ!ë;–øÊ÷úiìº-éFÆHªgªvßÂ(ŞVÂÕ8‹°p,ì¨PÃşwvˆ5å>>aâ.•]²§šQùŸbš¶
Áårº¦Ü¢·õè°sî6z¹Y;•)ÿô³”¸Ê¬ş`Ö„£1¡Ò­ğëÔwOUvq`{jW±ÁŞ—‹k×ç6_–é²÷go*†	µôÜ;Bßjú(_™{†õ®‡}8oÖ œ6ÃGN¬Î™0ƒú{°Èö¬UMtæZ¾¦º&ß
œõgxB
V^úçÀ€jp«õ“ ­î"`ÙwõWIÎÍˆÁãN~¨JÅÊ¥t?F7B¨q´rKgòóãâıÅE¾Èí1¼9Án	HˆÍWyE4ÌŒecşx66/'O…=–oyGYÏQ„{Õh 4¤ší”±wÍm˜™GEˆx=5Ê#ëcñ½$ÃıÏUÜM/n€õ_º°¯`)å}ß ¹ı…?wğJ‡Ì-*ú„zX&éOÂ(à[š@J†tˆf	VjšGÂÂJ6Ë¯^?÷IõØ.goÕ9Š|4ã.ı0Kè“ÌEˆêFbšò#Ò4ËÈ¿‹OaÏ1F¯'
Ş$ê×…œ´ƒàÂç'"F¡°Ğ—ş±ÓìãşÕM4ÛQŠ.ú1Æí€MÎÕ^[ÿ0ïJÊ³ g6CšcĞà [q•îs|ÀÎÇ©_ÎZäoë½#¤‡Œ°‰¥Mwêè/½¹PÀ{şg“½ªØ •Š=Í‰rZ£ùŒÑèãÜÈQr0[•@c™ ”ïó30Á?%a"Äı+‡Ñe3ÎÎÕê³æœ4}<gJ‰ œ:ÿâ„Ú¤¯"pÆN^›V§á[©/^3g¦úÃG_yöç½fQñ¬SÎøcu›sÄˆ½X•ğ‹¡êƒ‘Øö·DWÍ·atÖÈ¾ {Şë—]¹’‰8ˆïÑÀÁÙ¾ä©ú­ oNé¿+™ş‚’CˆÚ¢@øÒ+RÂú|7×6âúmQ:+Uö‘2_FêÈ2ækSŸ~lLåh}áĞm ïEd[­qœø)DpÇRZÛB2ŒY›mµ<glÌŸÙBÅæB]á¤ûxıÒÃ3@‹t3491CÇì
	uÖ¹ …ñÌ;:9vœœ¤	®
Õ}2èš³ÔJI*àªŠ@0óé°–;/ã&øÿ£Aş:¨ÏßôÆ10<ƒìæõpŞóÒİˆR'bD1rí²KéT¨JbÎ‚ôÑ6 `³úyàã ¼{¼Ï¸›®–R©ËĞĞën™ÈÅmY¨´²vrxH¥/T~Å½;Z±•‹(½}¬Î,\!mi£¯–U{NúF™K8—à0Ò²^LD½udËî¹zÖÜLÂ1s|»éùÙIÉÑ¦‰î~õÜ=}Ï’´ûvPË]¤ûğ,Ì?ZÅÓ™œIOe!‰=Äáı )Â:r¸¦èw*[ÈÔ-Z=x(Ór:¦¡*:WÄŠ#U—Â0öq)½ÌösÍx=ä¥«Ğ?w“m°\R\ºÚ¸†Æ8ƒÑJvD–•S¡œïÇX jÊ6E·`åŒùÖğFg4KGÆB(ê°™•D£¥ïw€&;QuÇm·ĞD°^S~ŞHãŒ/skÙIöğ:e~ˆWÆo1x~ÓCŒb´A+Í#ù-=5œ ½¸¦³MOøçs–¦³šôÈIdGUÿ²¬CğØPSÉ90âÅÏµ×Ã·­GûÈ0/¦DßaŠ#ä³´QÉ…RâIêJ—ŞûÍé›õKº'k§9\€Ïíuwl?ª­[ûm¢ßJ_E‹[S|ûñËŒ´em‘âzYv'äZø¾Ã‡)sëæ\—k¨g#öª¸ÄI~^›LÆfd'£†jbk–V~µxÍ‰d:èç}â´•¯w>´~‚5ù‘ÖğºÅK±>¼0Â‹û¾Ç•ìóáy!>…+ÇY7´êšÑ€÷aWşîÛôn¹êÀ&ğQYÚ¡‰µì{~kÔ)ÓK½{jY‡óFÔªõäM¿kÿŒËj1÷òJÂg¹š»i«ÖTìv:BÊÊ^ğ öl™`T
º¯ÆàÁ¦1kS¯äs}¯QÄ¡i_‹ßmÙ	fÕ2\jù"ÌojÜ«£MU)Á’&wÙ4ìdßÚ»M˜“ï¹Ÿå~4K<’øe…vûPBÏ¯’"±sIŒ…ˆáhR»a¢>ûs½bßú¢z4éúX"‘¦ÈeE¸PäğÑN¬Šıò°~=£=8“ˆ4àC>Õ›U‘w( ó’c:Ò  ú¯LËGœUè‹LÙí–ü"x¾öQ†¡$†¾v´ã„ï ¹Q‚ºiÌèà¹ğ¥¥(¼QXØq.å8]‘Ş¬ÉîÚª,æÀ£¥ıW-¨Ï¿¤„-‹H&3'e+Â¨»­€D‡´EÙ>Î§	.Ø.O7ƒ“JdßfUó›¨ÚÄB İCŸ†‡sä‰E.:OH«—Íeã£Öey]ŸÎiG– ÷’ğr©¬åûÔQ”P.o­\ÑtF›éúK’«{M…xËªïÕïÉ•¯ÈÌø%É}ã©êDƒ;å!ßİ!£a[ËÄi×Ê@¹èÙKôŒtˆ1gu[vdCÃ/O‚h”äÔş«Õ’×;ZZT-è»¥RjhŠ=åe®,e”SØ‘oæh;ñP}o¬Ca^:I´Òn§Ï~©-§ÌQ
¤¬÷ÎˆÌå÷¨[ñ­eáÅ¾ù“¥`NÃq‡Âµwóú¯FÿM£Ìì85³÷f{²@L:î_Œîv¼] Bk’%îğjá/‡»^gi0oÚŞÑY€®,®‚Õ¥W­À:–˜c[Ş˜4€X_ÊmîÀÃ/rÕÇÇVcÄ,İ™£ÙŸfbK!Ì>‘¸gA‚–õÎDöSãwXKûÁ­ZÈ¨¿õG6Í>áïøfF®¯1àÓ7¼y#WÙ:â]UÂ?úÄÏÖEykçÚ¡AUb¹™(êŞ?Ö.Ä4õ´Èl°˜„”ä4F?)l ñˆ„xX‘€ß?[!»SÌ/c¦ôE|Z»vU¾îo\-ò3JÛ|pØJ?ÀÓæ¬ÑúT¼©İÒ*–nÇ^&(‡¶Ç¸²ÕÊ¿:IDºûoñ¬ıkO¾6ŞúNÆÓñÂü‡Ï˜PKHßzÜÑCHÇ§Ô§¦oc¹´9h›2*ı³e^x²3—J©³+İ>Ã›“¤’ÄåÒ·©£jø\´;ä)¹ôú™†šê?ºcª:\(ëMß7¡Äkñ.~ïÁ,\s“x‹tU”¤©Sø»Ú)/Dªxş_è÷‚OV›669ÒÊ¿Ë×Ììw“Ô‡‡“ù–O»ŞF/Ø û0“×}åÓø>Áø‡‡xğŒ£â3 JuÕ/'ğ	½ı
şNqCğÅ#gYFk•“Jy6‡KÄñ;ÍÄ3Ö[Šµ‡´ºôCªr7Æ¸©òâ^Î¡Ü»'¥ûK=¾' ˆ÷Æ-"‘-fÂKüÔ¸JÕÜ'cVr‡.Š›Š`*0Ğ¥•S™µ÷I5ÙÍ“w´‰5wÎS+ -[+ş¯±+5gÇ¤ÈbË¯ç#uÁT.vGË	)—Â•ií·cäÂã¼u÷Ê8^ë8Mn[ø5T"4«İİ3ªW–©‚ä§-hSº¬×Ò–¾ºKj£×>¯qKû:Ù)°:Ÿ²ĞCØ·LWnÁ¹R
.–Gç£5KØ›ÇZ!|üµšé;ó÷×w;şF/&M‘Ğ!P.\.ùŒı6teÊò¸tRçs’*i8bÆ·œt¤¦Œ1=•¸üëk»<Öô;;3Ø´ºb¢èÓŠ^`	jñÜ¬©mƒ ş¿vYZ,wş™ñE%ĞA,5¾m¶3¿céÿäÕÂ®vyÛ.ñŒŒ ºy¥Ğ€`¤`IzÇ’ªPxø´ê³8¤ÑQËÔføºŞp³«…® ¦)G³oîOéîUáDÖ1ğj á7Èö°w¼¿p#¯
.çPĞ¡ÇntHjí&—>u·Ô;ôùè‰ã¸uu=¥º‡~º‘)ÀbËıohÀ,ïW’êàĞìf)ÉÎhÔ5y‡v´µ´â =ãb]NÒQª¿Cq²´üé:§MÑeK:.·‰© †ëqËİÃÌ4¨>L”èÑÍqğó7yÛ¦n¿ÿ÷„‹ÂÕ_?­¡ÙGbêÛÇz*Ü†Á¿'Ü ¼ï–1%·JeQX	+}Iâè²JÙØòy	øÙwƒñ¤ÚŸÏpš“#¼Ó{áUßØÚ´?°ˆ§×€ÍEôd§©«M˜îxßÎ~Nè—¸©‹ÈüÕbOôP4O5)db½!hKŒÃZãì$¹V8ÆçëÀ z/ÖØ~×b¤²¨±490õÕü§İ†ô‹–ô‰9ßˆzT¾˜f;7¹~şvÖe'—WãhXäGfû!dôEv#b!™B~rÌ¦Bo@KÌ÷;e›IEÜÅR2 jeMùføI0Kí(Êê}ê¥ W+hÔt8ˆù‘9&³Š¾®áˆwYsüƒO–Eƒ‰4—ø²d“‰Õ4°UªçƒY¡ïg·¾¹>æšáštë_Óç:^Å­3¢wîÏ’¯¹}ÒnÀÄA3£±’ÜmÂ™½œÁ_9S¨Æ­®²;¶S‚.vh*xË+ORJ%ª0ÌâÔ‚)›·°Ïs|9Ä@GP}Ù.øÂ¿ƒ¥}V?Fb£-ëCUkİ¹v9êc’&–YIíônvŸÙt¦²ÊWwH	C9Õ~«RBËÓñ"±"møi¯—>à@OÙvå¡"øP<8i°œNóeX²;}ñ ¬0åî@ûØQ huT ²™’ÖÎÊ1bê_£`ÈZrZo™ƒKè0¼¨Ÿ+îVáúÖÖx´à+ş2zKh˜-<%§#†Ú‚WAüOóDÃï´Tu²vr6³G¹„dÄx>8Á]ÇÉzdeÆå~PHwš‹K2¨¢ü-:øî¨„l!Ô½,‹l/6¶‡x`6Ö®Õ´9ct¿Læz5¡ù4 …‰ÉæÜâc½1Ñ´ğ¥Eä’%ÓrŞ~ôÑ3¥F¢ïwC1¨×!÷Å~?":jûšhCEÚK9ˆÑcçä	7ûGSñæ± }û9.]ñ;<ÎB	EİÉR`Ğ±ØwL‹Â'¡2¼Vº "0øÑì•*7÷"º ÅAËùç‹-…—×*.ÙH©*;Ê]|quóUKüàCÃà`å¼÷&}Ùõ}— ıÃÔ½3Å%“_h¸şxçT<CyHr“t]¢Ó@•\ç}w‘z³ó ÇèyÁ¨	×âjxÛyrû¨Æ9#‡Xxu‡»Š Æ¶ƒß/¨áÀÓ-å€OmMÁ@Lpø”¿—6tâ`³ütIà£¾¾¬ìVV)uÑ»¯VÍèÏ·¤µ|Q ^=%8´‹CÕé¯öd»5è®~UtuÚNC jÌÄœĞ!^²©
ïcêåèmÎv¯âæıÑğÂO@#8›ĞNìùCp†£¤¹ÀeÓ9DÜ!Õ'¯%•hûĞ¿‚ÌD¢(¨òÊ±°¸Åg×f]¸ñE[UZ’¸…€¿5zk£NÏúş1¤ä°[e 2DíŞi_ìuŠ/%$Å(^]Ë ×Ó2ãÄš<vıPú{F#=Ã<ğûûl{Xb’°È7ëÁh$u—icåœár(¥àò7½L|~ôfÉ“¢ô`¥°÷¦ğ1q‚/¶†dbÿ±¸[­y—§A‰1ÖÔdîNñëõû´ŞQq=Bó}ª72—¨[>L/3\=60SÆÚ^Ú?q®,¬Âæ‰ØD?Qì®°ûĞW¾6Nti7a›ñ ˜×êÛü¬|€z!@‘»÷‘ív¶mHÛ£"‰j <|1 ’àn°½:Iû&İ^%­dt4+ŠpèPŠs’&)‰Š„Y=óÜöÜ›ìAM„ùùÚŒ/Ã£Œ×¡ûz^\µ¨Š¾%”t@«oÓ)½İ–LóÛF?÷ğ
«#$ådÖ).!Ufsu÷ö+Lèz°‡û¡. teI¦×ÕàVîyÁ°íg†úÜDî±‰ËèÒ‡Ğ(ê–0ik¸u»ƒ¿ı"º—ÅVë¯n$apºİ9ƒYÈAØÚ§ê­¸7›œ$¡ojQf	ü5nFè¡HMlßÄ]>¸î`—óRÕGœJ¿¢€AB†õ	d?"æÉËi\^"ß!NAÚö˜×ó]ÖL»™ÚZÁoç1‘I=ŸŸà-İ<†dXö15­Ù‰iEÂğšdæáQúe0Ú?ßmYŞYß˜ªÍA/68O¤ÿŒ!¼
\ißğ¨ ¥¾XVŞF~ô[Êü(VhjœƒãÍÌ+J>s–-®h{Õ«Yù³®¡:Ì*5#S¾I”Û•|	v+;/~W‘g•ÿÿÆ6¸ÜZÏè%‹û€ş0z/ì`Y­7ñécs¥,@­R•~İC:¸˜ YÖ#§Bü3Í\yİ;Ñ[ß†
>(bPgÆë‚ ®Wşğ±¦òÇê&µB2*CqB³—‡éPøƒËÚîË˜ªË}´} Ô\b×Éè'ºdèjS¥SÊI´ËK§J‹şŸÃŒ´×ÇI´ ¹u÷©+)¤Jò—â}[Eÿ­TŞBw/j+É›¦Ò™ÚÔØ.¦Œoè.lpuxWØ°K]9M-âYG(‹¡;!÷©ŞËE<‚|&L¶â™£-‡Ô™s6O6¤ñ<9ÆV[0mÌÊ³ıK;l¾Ş_b¶xH,[…±±£ãwãÌ°Ù¼H=7/Š Hß9¢>“Ş–¨¸í÷5ç÷A²ÌËï½iY¦7ö1¥q »÷ù„£å¡’!÷Míz.wlg¿µ‚Xí6ÿä?wìÂ×²£È$?<l”Ö;ëx*ûø_¿s»/q‰yğ¯§0.Ÿ¬óŸ¯(ƒM¨À‚gM8ş8¹(N©ŸtèÃOz†NjĞ|,ê”dõUÜ#ÿTƒ5]@ê¬ÜVlòÆ x™™§‡©	¤DgªJkgŞGÓ¥¯–É(oÌæ§Ì¶ *ÄH$üh•SfÇ\CŠ\ÉÔÅÆw¾LÃIÅ«rŸæ8/ìô¬¾ù‘ÂÇ^÷åÂ6äË	÷|ÄòìËeÁïDv F‡ hHÔŞ)G¦¸+§8¬:ˆ¦D.-± ç/ûØºk²ÓúN{’¾¯E­øœœÄ@ÁÏe€òMVİ<ífr|r’mM÷mò„*Ÿˆ^¾uÍZù•bµóî=–-)·¬pY--3ƒCVİ“Àwp¸%äuĞ ^‡7³:1_û#7·õ7óA|wˆ
cÄ›¥ûšUçà¤HUÔ€Õ[îÄGõ,Z$ûcÚ ¾à/Î,‹3rfQ›rä‚†…‰xKĞ äKú§ælÍ}."§˜³y³’¦R¾’õJ]¹Ì]¼"gn2ğC¶m˜s9¹{à3¿—HÒ	)X]kÇvÛ2IšB9rÚ¥úAv=½‹ĞÈL`Dºøet(®ô9€£sïÉ=j²Ğä=l±à‚ z/…×hL³†P4cN¥¥ñ@23àD
ÑÜn]çÌÛ'ÖXnìXë'h	ÑL&Ÿ÷±låL„o]õzøÆŸWz™Ğûœ‡!•¹&-	@›õ2s™ô­SŞR¾@ ¦İ©+İ7ñÇEÃf:gL”Ü(ÁZùÖóq¼:[ø®(îqµ¾aÎÄêÉ–ú=S„bwUk\`ªFÓŠ’--ÓÖ¯Ããı2Z±«©çÖc†tdUK÷şÈ˜‰á‹Œ§€¥s<Î¦ß[¹º†ĞÚÃrÑ
†jÔÀû«<lsì6éXóÿHîiæĞ†^z=T™LkÎoH¾Mƒ?³©gí×ò09óŸÅ#4º3Ö]O-ikw¿üÎÄQSş¿!ôÚî¶Dáäe¶×¤"ìCß"Ô‰ò¡BƒéLÏGfª¸‘<Å#/rCøÔí}JJ6{Ïnhì‰ÆWt‹YDÅ8#¯çÄ YÑg8€^}íño1Şˆë}3¼¾ÌuÌJÓ'
üÜÂR:£éa¬ì!%Àú³íTD ´^…/‚ƒúêD­]¾ìşb•À[öÂe$Õ·ıXò‡ÈÌmŸ;ßŞ’­;!Ú1Òázºg Ÿ\º	h»Q¼ÁÌ«Yí>Ãxt›ßü*è‹5óá8ââoo«÷‰¶áŒ\“øÍÆ´737BqlÖ7×¤T¹4.
pÚYu|Ä¤D‘àDÁX³V&&ù6xÑøB>ü1:cQÇlõ`ai÷Òõò]•²ïtRL¼¹7Ë4«
0}Ix6»ê¨~	ÎYN5]ÙßñD)b\° §³á•»¨?ÜÅ©ĞiÖ»QÉ#‘C)Â	).‚ê:é¾RgŞóÿ´·©ô¢ƒãŞ69X!Ğş,.}¤yLGyúÇ§Àk"¼Qà±××fì7­À3"òËÿo`f˜•í9!{hYõ¼­ó/]êÒk»X”ş£pJ$³šlÕ°üÿ(ÔÇR¬ØOX‡}„Ğe¾Ò–Ï€´İZ‚ûk´Y\ø|·µ(;@ã›z¾ áú1YÿõlG×¹…"äÈé	‡>‘PŞÀ]ÅGY€CQ<â'x;#e¡!ÉïôAhÈF«º`¶öv<$ŞŠ³Sz€*d%ĞgØÕ€xqÓ@¯wNØ÷\–Rˆ|½Y‚…È@Ey+5—]áÃ?3İKÛ˜oû©!ÉÙ2//áz\‹{Õ‡ÇÃ[îú"ğzÉwMikĞÃİÔk&*‡§”ÌB¯(ó©èM¨×sdfëƒ*š)Ùj]cÈYàá$Ş-`âOè åÜºUÓAV,d­@¹ş†ñ|ãÑë%¦›k¶%‰ÇÏjo·§'#,ÇıúÚOĞ‰YØL©hâ±¬Ã QÅjÊ§"|Ñ]8k–pa”~  	T\WÁÕZÖ‡‹¯öî†¹5w7Dòñ»–S»şÅîşôuØ<¾‹™Åyº¡~wä×)å“<³Ù€çÚÆô“¸‡™®”¶ÛƒFv¤JÍô®±*ºËZ,iXş‹‹±[GãØ™°EÍ güóàüeÅlaÜÇJÆ«òä„‹Å,õ«>yy‡hmQHrV”’/Óÿ9‚uúÁ$cö·HbüÉËƒöHdI¨U|T›Hørµ6E#,¤À.a¥H}3ùEjÒÉUÎzgªé>ÑWŒ)àC#éCó"¢ ¨&H'?EùG-wÈ…¾q)pÓôüÃ†ßµgf"’üûwÈ¦µ}¦á= ~ûù8–hõŒŸØê¹Üœåıamñ­S›tC”˜ŸL`ìó¾@KHOjFwNJ‘?ÀÏh!Ñkµù|Ä+ª±:| 5ÎŒ,‡b"ShŸPQ Lœj'r~50Í'ò–*4Ã·Ç:TiEõMÇW„Árc‡^n5p/d~Ú#é-‡šrSüPhQ;õÌ˜ıœe>nIÛà½ óq^ï™Trp3%¥8ßZ`À—©‚4cåX®ÃüZn4¥Æ§³Ãğ›°W}’©À$1ÿ}3Ç£®³â	]‰ª²â*Ï¢.¢ üğ–)Uı‰ÖEI©­œ<ÚÅı‰ëù¬bq>-½¼w«æM¼P/8¦‹MÎÿÖÉ«“Á×¼9:¾Ú ¥ÆïC6˜s.î¬ƒe3·ÛÄòoâU‡˜óàÈÊ€âšJG^ä¹¯]‹ƒ _ö—3¾>ÒÆä ÇsäıÇ33¹F±ÕHÏ+½±U—ÛŞ‰2‘—~­W‡ñÁ2î&œkhÿ4Läœ ¥3´¤×I+ÿĞËyÍK©gç(?4g„ëĞS²IÀB•à‚#¦ÿ<%«Ö­CœŞ;!	"Öğ¼¨W6`ÆUbVoµ·³tÁåAŞ°}{ÉúÓ´%Š#ôMeJ/'Ğ@î{aôf^»aL\*ç;á­Çe=>Á¨Ù3ˆ¤=¶i˜ŠÛT”Zşºş©wûÎ‚®¤<…¨UµdÇ1$“²¯E,|$Ã¤¿p t$oã€!:ş–1×L3š0˜ò5½CÁá_BĞÜNÑÕãSÖ`÷`£Ã!O€YŠßø4¼ Â¦»†££şãsòhôâ=³Êˆ	y¾Ğ|oMüXïÓ˜£w’„)Úª©Ñ²eÖA—¥è‘9–	}‘[À)w×¡U^I»j€‚AÛëêhüvYéş Ôï7–8Ôì•ì÷¹ÀPÆ¤‘j:O))Ñ«,!õµe%Ú®ÊïVg¶•—áÍ¼¸Réì&,š)¬q>PÛ»~‹÷‡ÒÛÄ¹1]]¬‹@•”ûY[çÆ¿xVÙİ ÿ —æÜA]åğ¹‡ÔÚZyA›	¯¤îEï	\|kedŒ#ñKzÃ&Z.‡I¯2<|»*¶ÀÍ_3ÓŒ>¼3 `j(»úaM›üumeÑåDbÂíl_Ñ[9à™}tôÌ+êmöù—?&áîÃ³n-Q”¤/dÌú+Éö[ˆô%É}?ÿ&D„¬ÆùS^°™  NÚOí[nˆ|OÄ`6µŸø\çßüçquÕ¨óe~l\#aGÆ‡“º&­âlmëä|fòÂ²5‹ äÙS„ØßµI!’Ái7vVèaå®*ÛøÒ¦ˆâÊÏÒÊ>äUa•ÃoŸ _Şg›³Iµ¡ÕWù1ñ ^3Íş[: pZnšG¶:Â.×%*ÚñPó}ßX×°¸Ÿöv´ÌıM¿ºæ c©GÍ%L† òqùdE—ÇQ˜š¬RT}·–_2I=tç¬ L{ƒÅ9X„›v¡çıÍåª€†¹wˆ+ )*Ğ1‚ DNHp¬ÒYÕ	rƒ-İµ¿¿ıª ú(~j>3İù¨Ÿ[|lj×’[9
AFÑÕí>„z‹¼F!«ç/#ğëÈ›:ö[¦(´š}»éAbq•àUFµÀ¶8±`[ãÈ (£0¸ªÊı§h«@#óE„'ÆjgÕÊ÷LRÏV­#C‰Æªæt ßüI‰Şù•ûÇñ6Ó¼ ‰ YünZV<»‡g‚—÷,«Êt)Ã™JzõR!1ê÷‡èø¨ †,»	$Bn ºI%ÌvCgI+%¬-G„ş èØˆ¿Onğ9	CNôKB›ÃeTÎå÷3­À3Ğ‡Ö°®ÃtEŸE”±Xô4½á¸AÏH ‡Tºo1OK½ˆ&ÙrÿÑ+J,¯83®ù‘$¯² p,Í¬¿ŒãĞîÈ0JÿŠÀ	‘@“Jı¸ FÖ×,YÎ·½CcA8ù\tŒ¡ï ^}Ë'}%Ûû@¸'ã
¤‰?Ğõ¼'ºl
ı‹€Ô.õŞ•„3Øoäÿèd­–Q4d%±MZ³»yÜÎ†ÒÚÉ/—ÆùBG;²»ÄÊˆãïL@İ³[ƒÖ{¢›ÙìjûJBã‘! ›(Çu Î‰GF•Tkrm¦¬_ßš“„²WßËF2«±İ²
Ñ<È™È?ƒWœVS‡w&—ù„çP{ÚUŒ—Èæ4ÁÅ<ÅŠ» '½,ŞL„­İg ­IüâØ+ìÆNœ}ADw0ÜT95lSbÇç¢ÿñTBm¸g‰œê/v³ƒw¢_›·Ip3Å‹(òğĞÅÚa.zît–˜¾ºËG{ä	Ÿ+.Œ?Ã¹8Mœ>°ê›=ˆœ™¶×m©pg–üÏ½Ó& L;}EnÃÏyò+yT’£Ó¿R]“m¢Ë¤²Àrì–‰Ä{[`ùËO­‚V,ÃS}g¿ÈóëŞz>E¾räŞÌm³â°6ÇCå´ËäÿvPşYÚfRÉ¶ûawI—®şóIY·w’bŞù¶
 —XÿñÏÙ¥|åP ºV/=ö~%¨ÇŒ‰ÈÃUºŠjİ;u;E
óşuØ3³dÀp(ZFÅÊ5Ãa"~ ¾²‰nÆX1¸3rÙèÖúÕÿˆBG'c’0%ò8o™K-çMøµÈª-œmÌU#]ÓA	¬œÛzQb˜Ä€â˜+´%I|«Õ\œ<Y^ğëÓç¾úóV?~—çj,ãÃ*K›­Q¶é“ıG)(y‡	Û ù­E&/
Â¢il&‹ì÷u\‚–®òok©ÜÍyjİÊBò%•|à~?ê•Â°~ı“pÀ]fH|(‘,ãxÿ4r…£ØÇ:ÜÓ8¶ÅjRB‹ê3Ôôı~(Q‹ÄÃh²eÈù¾˜l4K›T‘¡-U¢éFG‚÷pvmm#˜"ÜÒCÏÇ;eÊ¬™dozê’|¿L´*…şf¿½²ôœ‹XşOë>‡((Beâjì¿Ô2Oæ¾²¼Zë¥¤ôœ.½Q§Uâ&! )‹ûx»Ùİ›ã7‡•ğïT5Ÿk¬e€9vİÁ:caaˆÂÌgÇ¢^è>*LG—“‚úWàhk™£'B(Z”Ğƒ€£Í ¡¨°Ù|Wë†Zœ_‡Í«k|âë²¯ë²¡Ê˜)L@x>»áÓuûİ— İ5#ÑYÎ-ÈÁºçò_É¤h%W÷ pM
Mj}†P¯¦=<a\fNˆ>ÖI@+¾š#º-)ô½j0µt•¿Û‹éò¿q@1?ÃÃ’$w;óÄğ7M ³pfNFHŸÇˆÌm/ùUŞÜ·Ğ½`ç¸ÆØ›¸`“"ŒyÎz5“ó‘&¥"÷v«K—Üs—§0×G?ãœ'^	îÅÅXe[N†…QeA¤'—‹ïã{JXõŠª_E‚³à^é
•lZuÎÍhĞÖáhÉ™½g[îÉ¾<¶›q)yb¤ß°Ç²­²2×Š¯*+ù=üL¢—EyĞş@ˆÙ6€8ç(ƒìcô¡¹ß9µ¾àMÀ®¥Í½b'^`bd»n-ßnõ0£D:ÅI)+Æeò8-N#ıXİ’Áª-0¯²ÁJ|ˆ>Fä-êªµSq€5jvåğÀ5ÄŞƒ@…FæÀâá³*“?oŸ4Ús¢ÿÑ;U)¨æk	z›ûÔ	©Vêúr]¶Şäqò£»¯#?ña;AmO˜Â]Ş®cEì§üf5–ÑÉõ=”›_Ş5V#²ácÒq!‚¤<Ó“³LŒbâ]‹çˆøK[ŠºI31#ø‡$‰ 
3£œå
üüM¤õn!õ?ÅıƒlT´>3Àó›pSå·CÑÂãN}÷ààÛo™bí´:ıì¹T„ç(çZö*œEE;»e—cöœï7•Ôå·h{	Ù]¥®zu°Œ©æµnVJlN©³×†o0î¥Àáæ¸Q…ä‹êÆ†äOüôQ4Dÿê Êi:îÃ/åÉë;ıdß›—6ªÌ24î¦ùÂo§¹0¹‹ÍÀ#[‡{O+Oİ'mgÈ,Ñ ¸³BƒflM‘ÌÉíñ$ÕÚ,ï&ìxÁwfk`ZÂ”oòÂ’sóà˜G
£sH€_ªwÀ˜r¬üñ&Wµ5¢¹¯ùÁ'îÉ/µ€D­á¿Mø/apÓş -Êì˜Ó“…¬°¼¾V@¿ŠÎØó³L’”jœ½#!İ|‹§)ÜßrÍN¹³Ñp'üî¯+x9$#õfßßÁİœÍşäÄßuİîZ6NA5 ?”"W³«Š6¹µmÊäs!şd1'ú4vı
‘JÅwïR†ğİ§ªJÖ`	¾†”D*Š åLçÉ{?8?kxùËyV†7òÔ¾E‰e(ÍƒÜTdß|ƒLİSb–Ü„T Ûİ®Lh"˜Kè%ã†Êt†¤³<©X·p^¹%åûö}«µPÑClIQíOÏ·*•SËÑ9[|6ÓÌV¸ÒêÌ?\lrÜ)œèí6ù×m/‹ÙC»¢˜2[/©1Zn«à{Ocˆ¸$Ó){°z"·Ñ…·,Üsıı}ªÈ—rÔ5´uòtÙK-c°êur"Š‰qºÚGŠÙS†¸˜‘Ÿïœs}Ôá*²“gÍ“©3[¬í¶^â”öü~Ğ!ÄˆÉ‚^Öº”ãú­šO<7KŸİJì²şZIü£éõÖ2X;G”1`‰êÆQÑ´ÿQ+Ä-,®„Š'ïFÚ³¤Èù|t}¸å6ó {©ÁMË‡…÷·
3%¡kx#1V¦®ÙÈ±éØF$™„„Î\ğ.éPğÖÂ(ÇJ1Àƒu'Që'6BD)´úRÏ9ÀÌ¡xÛiâíôÇç¨÷«Å‹Ôú<EµÑôeÚ’Â:N˜ì×ÄXv1RS6hZÖµÊ×Òú›Ë!dŞ2Òó,_1Ÿ²Trs€E7·tˆ—0¬ú®§®ä¬Ø1YIt7ÕÙ%–(]Ö­»’µnÛ»›ënkCÒÀË"½Ö¤È¦ÊÜG/	‘+K@Ï€L,_‘OÈÇO$ ¾Ó»Âï‰°jëš¿B€’ùLN$©ëè’SKP.ÕaÅˆ˜˜®é4óy<õÆÔÙ•:çb÷°€Úßã;$0¾mGT¥·Æ %!¡h 	¾|”çóíX¿M©ªú~|¹ö‰á¨Àå5½ËäËUÕ¢]qRİä¶„üVh'ş(ŞğB¥åæ?ô5ÇÑH¼!01û§.¥‡ø şhSêI­÷&ÇúO”ÊÆP•Ğ)F:Ñ9«Ş—E2»HRàrëak+L*c%ÁÁT×rfX+kGÉAÍèœÅY)¶|LœÆñ³Ø£€}9q ƒ"ÎéRÀÊ¿!Ûª˜øè'¦_	•¾"pÎÃ¥8zñ\´4ü&`YÎ„ù²V@Š~»˜W@÷99õ]õ—Õ±ƒ„~p!ı7=ë‘›ÉEˆë«74±DaµCõ©éÈ ÷ëªÑ#Ì$Ü¸°ñó§§jw®u+ò«íÏ±ÊEâcşüóÎÄZ'ÜYe×•h{—û´¢aÇ"gÛò=Ô1;oè	z\aª%(4‡pYŞ¾ûöï¥K…¸*Se_ãfPm·!iw(ÜŒ¤5åÄı–ÇdTÌ¿¼ŸAäÚAÔ8$“eÀš<x2Z©BP¨u+ÔİÃ¿ÔB1Y&|òã µ ç3$”Öœ}(}ÑÏ5q€@­hš±Ñ£”øĞÙ§HÂÄ”îi®IY7‘Ş :+.ä{åâÃ|x­aÃ†™?¢ßÍ5‡¯$:ä^{ë¤S‹¿†O7%:÷E˜P«Cy"
áâûNuë}1åñ}Á·º~O ynĞ*è¨z=Yy&RÊŸ3G_Ş¦ZÏ“toK%*Xiäo@Ï+ŠËù¯åúbNò0éï8%ŒM4iVĞ”Õ]¾3ş€íÊÖH İ1_z¯§ûh¾w¨AÉ} †¦Oî>ÇÁ)pu]S€ğÛÜ!´Û€»åì}íî¹D²Èo[	oM¯+a”ğAöÎ‹ï„¨ÉY7hïğ	ÿ.÷—Åf ,J0LÉøEï j¯Qr¼ƒÓ1¿Hú1ç5YOHôµw‘G˜nY‚;ØØ…ÿqg°anñèÌ]ÓtEöóâf-Óõ-Wëø	Ô&ÌÀF§íÊ1
İõ’K65BFÂûGÏüÃê¿ ³øV¥M‹Í”õ¿FM£'€ÃR†<Ö¬½Ò$ÕKÓ¢ÿŸ/Á#È—ùÂi}‹Ó*Ph_G‘ÃQ*Q‡Ut°ªIßélp¬ë¾;”±ƒ«dº¿·]µc*ÿ`Ì€X}ï®5zñÂŠs;HY–T[$Êv£9Óøû5bõiİBMYÚ}›%™­¼•<G:¼\fÃ”K w½F0îÍÍ!0XçOËU£Çÿ‚šİ8]#!Ò‘Q{[¢JäV£Íƒ·«Yåh¯àScX65ÌNĞÅ8Şc'ñÁ¹.;I‡ÈTÎ±äk›ç&¹Æú¶¿3§°ìæ0ŸPòrr‚"óû'3ôcEWí#ùH…D9Õ*ÁjÎÜxÃ?â$3YÆ,/sÇ~>:¢¶|c·Şİ,Òk…áÍªe–æÃôê@æC9¸(wÙ5bräöÌ#OöŒ£jôğaŒ]ÉpÎW’ÑÓ‚V>°¬w×¬={vŒ¿a6_f[©P¬ó“ëF›|EL§V}›ÔW ïñ€pÔ65¿ÅrO»›
ya<TkgØ—#1Š§¼	Ùp¦şWš¤E—ÂAeÌ“p§8[ S°QHcøº-æ°'¨ö0l.]	´ï>ç­ã|=±éøÚpHWõ>«Èù?swºúæ®¬?ˆáªC¬z>ÜBR)Ÿ,”ZÏëıéQ>aˆy(BÿìXdŸ&áùÈ?›y{âë8œø;ı±C×Û»j«–YĞ~«?´ÅsÏöE®²uk\£‰İnÍô¢fe¯‹àëÁæ“àĞ¢˜Ê'§€W„Œµë!3’H¾ÅÃ|¨ÆX5äà™´ÓşîÌ¯ÓÉà}·]¹ÎËİ,V•±¬ÂÑÌ¤ƒŞÌpJRsE¯÷9¯[jLBß?¬0~!‚;ZÖa÷Æù¦ /:"G|&BĞ~k¢À‘ÒÕhØ‚¿G+E³&"-Úm˜Ê'Ô–ïMäl©º#ä|Yãüö~ñÔ+i@Vä&ôdQÓ¼·a¬ıÁÛ·¡6ÚïÈ&¡üVãËÂÌøÀ´¸4¦ïŸü5½îÏ#= æ•†±€Sô‹ËÜÄGY-#]j{¦ƒ'ôóû ÜŸwH>¬.@z´iqc`U'ìtvÒ˜¬[ƒ¢ÍWfH?]‡¯à´o'šÜ«Ööì´îH|,ƒ¿£ìúŞ„¬ş>=[¥²‚f”Äy´YS×îã^â›Ææ4ÀN9ğW"!—.>êİ³2ÔÉËÂ ;°ÇD¸ˆTÎ÷§ïXœzëĞÎ³Øo?İö¢Ã…égÑäêÂ™®hÄÈ€Ô¾´^Cg<:øâôVù+aÊÿ~I³ó!d5<{
¾ë“H—Ô£Ş<ç¼|]Èí§hŞIQ1š+U+<[¹vaZ{¶Xã·µ¡À>›o”ˆõLJe¹ÓÑñ¦ëa_ßâq`|ı¿'&’iõ¦|Éø2]ZìÓÛ¨|læ_!Jı!ßŠèt‹ÃĞ««(zÒ;!rö3ÎHÙz@vB6Â*rŒ	1ÆÈ*åŠ›{¿!4cDfˆÊä‹FÈ+¦âzX³æ÷Ìîâ%õ^›rXÛ%nyDe
O<AÜ–»‹_¢ÃFx{ßy_ö–§& Ä"Kô8µ˜ßÙXæ^×©jk‚DÁMHÁz³œ×‡Îkìòs
Î­H0eöÛTWu$†Û4K8r—‚È€ÚõdĞª¡oíkqLKM¡°á3'çM}ùèš½XÕÑ6!•Íí“T»0ƒ¼ÉzY
ÌQP]ùs½‘Šú¢9Ã\ËÌp:Ûà$óÿm¢¢@Œ[b‘ wCoî¥8æ”˜vœŠi­=]HcÚ-ğï¨ê^FÆ†ÄSGiœ?êÎ%yObZ.V„ë¦ËÀ:$í4¾ Ä€N˜bôR]æÄl¸0j¥µØÙç‰†’£Jq¬îó¬à›QQ­}7I#Wô(|aíZhæç,Ê‹T'ÜÀ4ü'V·&wJ°ªUñ¥òıïßÉé±BI§ z¤¢Ú_ª‚_šoàq®¾&Ê4ÉÎxöpšrÏ3R•š÷¶r—»M“ÂfÊl1´CæûMõèö7eÏm;´,ïºé©-×‘cR=E{¨êó?f5šG¢·ÓhıDxtÁ^bëßoŸ•bã1üŠö`Ä5ê:0+%u
jxœBWš9ZËeIºãÔgåK`%ÑãÏÇ×óÏnlqÆKÛxçf¼šËL—.²ß¤aV‰e­”YëÑ8‹ÏuÆïÜ/\[neùoÃ’à£›vÚSLÒë¤¨Ï!†T(Æ™RÓÎ@mÜæÈŸNî‰Y¡¼ùpÛ¨ÉÿéÇ$G6bÚ’K¹×ÉÚ¬¢Ïê YğÂoW§İu¦DÀ€9ı ßÍóâ÷£ºs«AÒ÷Šj¬tÍåÓRßÊÈÎ¯IŞÔ5'ó‹¨‚´d.Ëxğs7¿øF¶A/5ãe^Èâ€4kq82İĞ¢×ó`,ñ„TwCX…‡¯ŸÙ0ÍªC£ÆÎq7E3ûÅÕ.œv>-¦‘Ÿ6íâ0(Q×±ŞTkW'(‚BÛ«¿’ğA±ÄƒŒımÂì9ÊµïÚÇ8o«¶_ÒËzQXuÁ³@¦VmùÓÊ AÊÇÂ™_K† É<t6™Byªü¡H~]–ˆƒ;x´8.©kŸ¢‹(©b›’´ô¢¶°.É_KvÏvƒnïVø«ÿñ”@™cÓ[~7šÄÍz,,º×àfxô%6åŒ"xÿ®İµe”ú¡{—	HoâÁ¬Ì;]ÚØV^[ñË²QÛ·şÑ’âşı®T<†´åû£¯ëÑn#ÂÉâü\U&ÎÖYËsŸ`ZİŒ å¿‡ïÁ›İı¡#™5?Ü.gæÇ|âË}fÇ,]R«vó§£µá)Ì°ÀÛÉßh[o+*RÎjü |¿ùî¹Î4ÏGXŸbÁúÑ±FërQ!8„W$µêr˜^ºJäbw:¿bxÆ—uÉ~§™WÊ˜|®°kw€rióãB’‹|Ó}ş{²ÁÕÈÿşÇ@{/¦[4ÕÒS°5O¯ş–=®ùŠì¼fTÇ¹]ÜÚH5,‡±JZxø¢uPjÁüÌÍ$­7MÇyy¿†}XÁ"Áö9ö®¥­ı÷yæleÁ5 :OW±Reû÷¿5QXQA‡ãn^}ˆ™äÙÜL”E”Á9½»|•ÚiÈÂnŸ¿æVòç›[5<ªf•Ø®jg·@]¤10$ÃoHR\ÑEL™|™¦«Ktş‡šë^#¢ÜÁÅŸë
ÂWİùJ*fÜX7e'É(f»ıfœº]Ÿ0şútü0§?)¿íUà›ª…7ÂÜ¢4™^}×Ã•¶¾Y[ƒ–­G‘K³|Rü°§jzİ$=LĞ­…Fc¯£ß°š9WÙJ›-ñv{ÅyşlYXä!Hà3É²ãÑÙCòB¶léÅ²3ëI¾Owğ*è5YZÿ®øIXŞ5ËöÕ2zÀññrvİ´7Ê¿¬cß×g13ë»±»fZÉ|ƒP3É_Dè^hµ[×È›¢<İ­Wí3“_u«¡’H/F»rBvy4,§¬å|$¬ ‚RÓß§ô"Œ‰'8}hÉ¡Ñ‚Í’Ë1Ğ=æø°©uş´˜‹†CA¥Êó?Æh>XrßÔ\Yà¥¥öB¦‘¨ån×Ÿ›g«ï?F‰×.°Ñ1¹BÓ3b¦qg’÷ô‹)æ_{ ê}B½ÁZ»‚ ŸQ3ta\.à¢˜d/­XAü^'ˆ~õ*T3lÒ¥¨ÚÄÄ²æåÜ°co[Ä!æÕHC9Í•NOáÕ!Óv`cíHI?“ÏÊ÷ñÍ˜ÚÊÏB{»S½¦”£†Ÿ¦¡o«ÚÅ™y­Duƒ²ÄîO­‹ÄXòbcÓço@Çvò¬ô½–®šÎ†X&ï½Ç­ d÷+	µ*Ğ´4.è^OÇ}b»«ù¢Fñå²¾İÿÅéŸ	Ë«s9æí³¢‚[\OàvıB+6SãÜûÑ8Ó‚À¾Ô}ZH2·\õAJ›7kî­ı?„qSÍ+¦ŞS§iÜôèk&_ˆMø¦4}V¦>™V3•øMØïGOûõ£¥/Bn±e•U´1 ZÅ6h…Lëk»iíÀm·;¸í†>W8ı*RGu¿EhúH¡Y$dü¼œu¼¢©u[¸èïaŠ%qìÕv}¥—Ôó°èdb„•I*à¸Òbs²>ˆŠšoÓw”^«š8#ïU`ûj5¦}ÎiÉ›sqÈy*¦]OLúÄDÕJº[€kÈ‹#4ù¾^)¯’WKĞüK7¡ßü¤oü¢Ãîña_«ÏğøX¸ËJcĞ|õã ©Á"Ï€c³0”;.õ´¼8…7Km¶¨XİW¸B‡“/ªbUD­Y!bƒÅùg¼ÙM,Òs¼°0ƒßY/¥=‘&fsJ~z‰yÑmÒšóúN±Ëynu"Î–_QEş†Û+ÿ)±Ûõ¯°ÄîòJÇ5•–™z£÷"íÚÔ_ìÚ»á§#'‡ë˜¢eR€Lúó¸í¥›Fıb2šnôÑ.‚Eè|×å¦Ô™ üi¿+·¢°M‚lÕIm	/±-5K„Ó(£p³\‹ğ¨‰A1 t\Œ’JK1rA»¤§ìPµ01`“U&İ¨ E•GOZÕÿØB‹"”6±¶ß¼èdO‡¦ö\xj'ˆT‘óUVÜ¤îl|ƒÉÚñCk Ó¦%uJœ# öÍTı´@ú~Æ—Ø?gºıG?–yx9ß`ª¨™ „Fı*'fk“âAã·’«å­-0o¬µ÷meÄ¹—âaã¸gV™z‹é¶°$îc«FÚ>ğ´šëe¥v(X¶WÖ¢Œ†ÿ–‘6U›÷9f«¨«t¨-œRø,ã…”…ÀI¹¦”V‚Z¥‘RvhOôk†-^ñF<”ÙêIè#¼Óq*Çèı™G[ÉòÔ	ÎÕ«Î®IöJÈ5-`ËNæ…¦¿54«U/6Å¯üb[Şÿ6ì@Gª-¢êÀB¹v)#¦Æ6Í'—qbf6É¿¼·;‘æ.8YÕ8<¡5~i"óåD:e~ßùòêwod·†:ŸàGÎ?‘YN¼$¾.t}¯+Á_0ÎEı:é¹"·ÚÑÚ<2Ì#HÆVbØ·Ù}ƒ	&,•²Ptèi(1Ã´zœ™y¾a¶%ÑKÅ5–7á†¸_hÙ¡ìœ»£¨f»r#²Ìd˜´¦ÌoâıuºsZÍäHœå‚Ók-İgŸîçÀ+LøbS è_ßéËL^ˆ ]"áœé³‹Ğ! İ{`7½¯ 7†·ñ#­WÕ®çŠAëP©²—Ú'¨&xcÑ
]óVÜ*ÒÎü
YÛ	*ğßÛ¢ ³Pã~õ=Ã€Û&šlÁu´ò¼ŒV0ë+¼xóƒÌvtû7‹çŞWÀ 1jøÃEğúĞW_Í$0œ£ŒpÁåûÚrıò¿G—lœ××œÃäãƒf"ûGòí^ÖŠÜ¢ÍçYLcVçÀ2Öã'ö3ƒ¥&DÊ?¨é{\¢ÍvÙÁ<0¶¼JôĞ óğÂo¿Ô~zìÚòUn„WìŠK¯(ô&f{ğH¬bÕK>ËD&èçÊ*Ù€Ş t;±ÚğøwW¶ÿHwj&OÜQ)Å$f§¼E/¨ı!¢X.³ÃØİw½ùô+|`Ç{mãdÿN¥n¹/h#¸oœ`å¿j«Ró¨m#°úÎ_¼nlï?tOÆwÔ,{~cöøüz3ÍRÆ­$™,Ëx„5tÆGcWçFÃÈíJ†q]¢'ãøÊlMáS1@Ú†‚Ã³Xe =VÕM9y×©wgÿ‚‚d°Ci íOÍÆÁ_ùqvÀ‰Á4‹0“ Úd·Ãd^?g$ı{-Oûw½qBly[cô8Ë6Ô"uµcã÷àäTÙ8ÀğRƒc—ÙŸ³¢Iïs³¾0æ	s6'í¯èâ¨ßÁmÜÈP6“•õ*0"ÕìÌñ-!”´‚–îñ¢°c‡.L«°½.…Lû±B#g´…GrP©~öœ6ÂÆ ôº&s×ŞO:ÏbêæĞÏzÎT•“½1Æ ôÑ«nÙ¶ãFáw•×­·º$¹é³?ªàî’‹-‡›î9XwÔØ£öq[*!T>cÃú0ÿ=F‰zˆÇ¸6zºòXnf÷Ö
8°sA­!@ùõº;Âô­Ôm$p%ïCéÊŞÚev“Z@$5j¥UÙÂY@È©ğÉ¢>—ì:¨ºüº2¦½%føËÏ®£ÛRm^ÏxÍ/¨;Î0r…Ë%2yë‚8I\”0ÊüTíHé‘ƒï´µAEÛ:
d|ÊÓ.-µ¸øÊ8?;Pg³eAğ”[rôïxj/Ş#>3«à<¡ºÂn
_ªªá¤ciÔ²{ÊCŠy!½lŸçf*¦úıDŠ#´1¬ÿ´H¶Ä®èğlC~M¶#}»³áÙË‘X©ÍÂ©1z‘#jÇğkää/êùuà­Uˆ—é‰DvW/Õõ-´¦Ó¾ïŠJŒ>ï}Y;?™ik“Ã…ßx@?,¹\˜“^åğ–—
iº¹¤1Ú‹a©„âl—k²µÛ 6V=G1„»2Ûp¾Cîüf<a,ÑxV‚¹?ì‡¼Bóa•^N1ì>Ú¢7˜yOÀŞôih¹aUÔ‹ÎÎ@¥¤¤¿iL{µ¼²òÈ‹]M9"|ëÄ6>ÆøvG¢›]S7dåİ?«‡ß`(°™r0"×ê*„¤Ï"ì–EK=¿8!Û'BA+úŸjÏXo *ú>S¤PéL-›šÈ,¤ãÄ°¿«O÷sÊŸPÿ!°÷DìÜt Î¨C•Š‹æ`Æ`è€%~õÄÄ¬ hˆÓ›KN¿‚KMj•BàÈqS‹±Š¥|€o/á«ßxò {³	Ğ'Ubõ·¤û!cı›wÚ¶BŠí¦Ù·l¨Ä¢íÉW¯q¾Âl®"Ê\‹­ZÎ»W0:ù£…¬I ‘ÅbúÑ ëì—@3}±D­¶Æ‘yÄ»\ÂûIª
tM/v$ëPû
;IuÑJ h»3\VÓ97Vk„pÔ*¼T#æ…šœ,œoTfƒÖêS© •Ñn|ˆÃ›Ow:;÷‹„%4i2øâHª>‡±šâf.}W8:â)Hmö}:–:.NÏ{ÿ¡êB ¥v\?wÆø¼îfE¡s©=JÙ±ÒUÂÁĞúÈˆ[ó4 N›QéÖ0_
M¿N†Q4FYú!oÃR…¤?jOîr,%¨+OÆ„ÂØÆaZT  ¬4¬tëˆñt=ØÜ8Y0óz—æ÷<Ê[#å•Í3,Ã[»áì¶
XïKÕlğÎı/	@:³B•ŸÂEô¦Á+?‚®&0¯	"$ƒLZğÑqàU€ã8ñ=şæñ
n.ï%*	J—*ß=9|õÒhƒd@–%4eÔAbR¾aİÓÆÁÍû“DEß7ëC‡#VBİLxïei€0‹%ùšåB+5f+%íµ÷Éø2oß2aŒâu3[j-‘›ÑcWƒCúïCë¿†rÛ…¤E¸*­tÔÛZ±°VWÈvEsÂš'tŒR£Ä89G²~ßÒ­×Mú´2N½0€tÅRªşLlàÑ¿Ş˜C™È¨mû7’B…´À¡_@÷ß"'š”>sO¯ÃHÅŸvïñ¬s®lˆ4)rœÄ[>4Å·áZ+‚@t¤MÜ°^ SÉÍĞ2BÏºÎA³'Ff’	\Aô8&{^ö–¯¸Á¼óßÖ0d‡R‡‡­[ˆ€Jé½ªkÊ&'I…«¶lˆ‡öa\ùpËİTóæÀ“jÀÌŒŸKÇvÄû&dú·.xİ1şz|„ÆãlEí¦¬úWì”êw)õB4Ğ-5¬šÕ   Ø"•~e r Ö±€ğ&2Ã±Ägû    YZ