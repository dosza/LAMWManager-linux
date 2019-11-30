#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2844880163"
MD5="4fd3abc6679805aef477dc12bbcd02c0"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21509"
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
	echo Uncompressed size: 132 KB
	echo Compression: gzip
	echo Date of packaging: Fri Nov 29 21:40:25 -03 2019
	echo Built with Makeself version 2.4.0 on 
	echo Build command was: "/usr/bin/makeself \\
    \"--quiet\" \\
    \"--gzip\" \\
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
	echo COMPRESS=gzip
	echo filesizes=\"$filesizes\"
	echo CRCsum=\"$CRCsum\"
	echo MD5sum=\"$MD5\"
	echo OLDUSIZE=132
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | UnTAR t
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | tar "$arg1" - "$@"
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
	MS_Printf "About to extract 132 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 132; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (132 KB)" >&2
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
    if MS_dd_Progress "$0" $offset $s | eval "gzip -cd" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
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
‹ yºá]ì<ÛvÛ8’y¿M©OâtS”|K·=ìYE–ulK+ÉIz’J„dÆÉ!HÙn÷_öìÃ|À|B~l« ^@Š²twfv6z°D P(êĞuıÑşiÀçÙÎ~7Ÿí4äïäó¨¹µó¬±µµÓ|Ö|Ôh667·‘G_à±Ğyd™®{}Ü}ıÿG?uİ1—ã…éšsüSö{k{§°ÿ›»ÍÍG¤ñuÿÿğOõ}b»úÄdçJUû£?U¥zæÚK0Û2-JfÔ¢éøyb†9
<Æ<ò¤å,Ll¡Á†Rm{QÀèNmêN)i{?‚.¥ú
yîiÔ·ê[Jõ Fì‘fCoîè›æĞBÙ4°ı¡Fç”¨²´«ÄfÄ7ƒx3BïÔ(ş>n¼†é9PŒÎL Á&¹Lß§™yQq×!ÍvA”œ:;W¿'zå{@ûAçùÙ‘ÑH[ƒ£¡¡ÖªI.f|r4wO‡£Öñ±±B² ¹Şî:†š¶Ÿ;ãşËÎ›N;›«s:êÆ£Ş¸ó¦;ÊšÛ0ËøykøÂPQ®R5FgC VªG¨·:½àºÈwØæ€*öŒ¼%ì[­ÿú@¯×¢’÷û¸s®R)'‡Áü£k ju7¹çosvòé-Qf¶²ÅµÜàÂRÂ\ ä[3õÏÕØ9å[£ ;„o˜ºØe
4èÂ?´ÊlÜ¥’ğJ¾‡®O=w¼BV‘`±dVu¶Ïéô‚ Æìû@ˆ=‹,,èb›£p€3Fƒ.B;P T¦fHtNõyàE>ù™ÔÃâßÛOD·èRw#Ç‰©®ı™|cF²›°˜ÊªØ5•Š Ï}è˜sÆ§uée?H@gã4ó›*€ÂÏCÛµŒÚ&ìğôÜBİPZÔZ¢–STNP:M3kã:W»Á/]OÑê·¤
à`1	=Ë2âÁ`ÆløVO(oº²Œï¼ƒ *d>MQæ4|êÔ>9àËd
8ƒ43M¨¬ªa-ıM´+5m¹y¢øv=±èÌŒœpCV¶Ã¼S³‰„O-QÊÚÓT©d¯ıyí¬}Ï±A^Ú¡˜/ìÏé_Ğ+:%Ô]’ƒî°ÜúÅ¨Å?È›ÖÙèEoĞA[ö›|>}‚«¤–³lEöraòÊPv—Ğ+;$õz]İ¨i¥~¸ŠÈ¢BĞâúqÅ|¥±”¢p‘\£¤J%“„D25)+qS,››ÂJº­¼1&vaÚnJ©‚Oœ¬.C=x^XpŸJ%ÓÄX`ÕX ó}uj¢Ìyˆ<¿Uş˜ÁdvFAÊ	Wd¥"›@X '–Ã·¢&m,yôõ³>ş/Úîœ!©U¯Â? şßİŞ^›ÿmn>+Äÿ[Ïvv¿Æÿ_âóÂ»D›1š³I{J¥Iz>x> Íy„&+¿¢TF‰ãG>ô{nØ0v1]ÆWò©¥ùÄè ÿú$/…şª˜_Lÿë¨ áøäş=ù‹=yıßn<ûªÿÿùµJF/ºCrØ=îø†¨­wÒu1bû…´{§‡İ£³Aç€L®óQŒô"²0¯¹À‹xQaÍ£°àú{2gÓ…LbŸ€,<ËÙ“@0Ãø¸	%ÇÂz¾,°šßûfÀDT'+Å‚ğÈ¯‘«Tå!q„O4MŒ¶¨c/lL&w®ó‚2êÌˆÌ#$‘Yà-À€ k:12Ñ1í‘ó0ôÙ®'Ãê¶§™¢‚’Õä¬æöNƒ|†ˆ•#Ë¯|Óe<¢=7&0^E™ÙƒÍ™N#éPàL¼ÓÃ~à½éó:‹¦ä­~Ø}µÊ_Òşó’Ã¿Xı¿ÙÜùZÿÿ’û?ÅÂ«6‰lÇ¢AÁø6{{Åÿoî~õÿ_ëÿŸYÿoê›[ëêÿEAà@.H˜znhBêC82ˆF|ÛÁü; sêÒ€‡$€ÅvÁ/âQAkp²|FtÒjÚ/v·5Òr­À³­/äØ•ªEC:MˆQp>şG,ÌüiœÆ™–I\ôÛë&–å–ÿ;°Í¥My±Ò\Ll,x)<@:ì·±î\Q*7Å=´Y8ŒÚ“´l3ÑºKÃ,3,ä§pÀz^X}ªM"7ŒHó‡ºú Ó
&–?Ç.½G`ì„Œ—]÷÷ù°cÛ®È	ÄP¤ùãÃGRfN•”œfFÆV½QoäñœÇ°PCM"2¶të³€BdQŒS÷‚96éÀE=4çL¨CñxkÜ7T	`wŸû­ÑCÕ#è=Áª*µ0ä!€hœ´út6/¢t;­aÇPïœøUg0ìöNx‰"K¯I#ÕŒëˆbûwäÒöƒ–´}ç’ »ÓdW?ìAÓmîF+ëJüU. 1¥™+/j†•O!ş¸:œ›¡2,ğC€‹.%¯cßoØs3üøĞ(Ì 
8,ºä)C@¢‚/³“ÿpì©Çç®<¹Ñ‚Ü0Ş3³ùq\¢±»¿:øÓå ©!—ğ{{Å>cªxmü¯¤»¦“—¨.70;—çöô¹½¸ UÑdlq¥\­å©Ä ªºzvR¹ÈQmİT›ëaË@t¸~Q¤Wª<ãMÏ¸'ã¢
ù.­òÓeOğœ,N7œ¾$©!á(,öçXËdEÛ¬7´	¸5¯ÂÕnVÚ¾}§=½Í¡bb°¿tûñ‘éöq÷ôìÍøEï¤Ãƒ›ÂòX Ò!a¾:µn¹q,™ñ¶.ïUô±>ÿU-Y]*ˆ¥Ó§ry³ºĞÛlx´Ëu)>µ€ˆª8è)aİJSäÌ1ÔVW€„Æ"ÒÇ!¼ ²~@s±yñba ®(Ï±©qN+XˆSŞsÓÓìÜ~e¡b·H	¤dİ•
Ö6È,<z_ñ€Ó`9™ÿHjË¤İ?Zƒ£ÎÈ0Áöú#CÕ,Ä$vUÒ¦ı"¢"íAo8€m ^=k­={uØµ¥’DøúƒÎa÷;S\¨òåÆàJ¡Lâ–TE*ÙI{gƒvGpTÒğ"ÖÑkEÁFã'1ùğ«í',Qû}!+éŞûşôj—ûÈ²ótnkÄáâ0íEïöĞ\¤^°G-“ö_“Õ§vsÚœ´oU"¬–Wl•J–X"øjzlZ+Õ~CtšÚ¯WËÙZ¨J²¾Œı«@ò™}äe\Î¬V¥ZÁ®ƒD%»¬­`z¾»]ª1d%Û-íöôÀäó—H~^;^®H{uw	ÔÚû§¢II2=æh&XJ&V¸)÷2ã¶	ŸÊ¥ê§m’|ÏÖá"r$'{.h^n?ˆæø6Âï¶‰Ü1$›ˆ
²vÛ0s˜ÆÏ=/†éseK.Ğ2¼Ğ`Ï£ !•¸½-µIW][GãÃÍÖéÁ ×=ÇrT¸ó ãF<	Ys³%ª/Qƒ8»„šÄ%ğöÏ!'çAàyÅŒ”¾œ·%1…UùòHB¬Ä®~–+•!E1é›ÓsN…Ç=è¶ÎGğRÛ~™$ì¶kÑ+~é%	Ií†ok¼ïıí'¯5P&şZeÿ—¯ÿòkFLÜaµlpe¿[øîúïöîjıgçÙ×ûßÿë¿,ıj¦³0Çú/I/€kñyc‰Ä?°< Ì÷\fOÊk»!ôæ.6êâ1ñ:qY	¯«Õë_†Û%Å†ßm<sƒhJ5®d™ü®%]RÇóùAû7
ôz£1ögNğÄk‰K¼”ƒ‹Å`&šŸà>N‡óû™xéQD-õ$Ê¼ŠÀ´0dğÖä:(= ¾Çp—m¼G9›g” !œ’»çÇ•ä!*ù™ïŸ ;¤®	bÓ:xzg]rnâ¶ÎÈãáÙóá/ÃQçÄ0ÔˆMÔïIk4ÜØÖ+êZ^pÍzÕ9=è~‚¾“ŞAÇP»»»ğp4èõÕw¢9àUß¹	ù„l”Šb|„wœƒÅÏÒwšZLi7!ŒK¼†‹€$àeÌ(ã±*×Š¥M3økd/=ÔàTÌ?ş]®{>0&Y	JîŠJª²øÉ•9ãÍWßˆf°rÔ7Ãsc}ÁRóòQ•ËIEè’X${ÈXùÈUãt5ğ0†­ƒ¦O&µÚ=„µ“X#T¹©ESš¢$q"ŞXÉˆıq=2ŞMjNl-î>tj©Òê®u¡û‚¹Z0=†Öj “ÉâuÜ&0&ìIĞÃoË©37ÄÜ¡ç9C¾£—µ]ÿQ÷ŠF(ÔE·¨2Äe±Jå±vå·ş,…‘×#0AŒ·€XÎiøø“GèO?cL:Å.ÒuÕÂïEÉêàQ$±-$UĞ,¼!F$9Ñ¡Ra\7m—Ú.^d.àÀäL¢·÷<ÑJÄO¹ânÔ™ô¤&÷`Ö×Ì(ÈÔ+46ÏıPcAáé3ÓcK<´ Ép-$ÎqãjJBŸJT‰:•´XW«[–Öc¡×<t~Ü„ˆø¢%>6,ZnJ‚©"/6€ZÌŒFH•è3'5P^ÛÅ¿{µ£Aëà¸#ƒÈ=~u]°y!Ä$èsÇt/p'’w$Râ	Ô‡ÄÃ ^@†Êên«5™ªôœ.%~—¥°t¾ÛÒ^çzÅ«+¤˜ç'o«ÄŞé4jòx±ŸY»y47™µÉ=8ÊvG&Š–”ÇŸ‰±¸ßw¢áF¾IÎÈe4•Â&äÕ…xQ™ k„­&¾ä1‚ÒåS<Ç”
Á€	£÷¯ñ™»Ì 8À÷0ø1£W\ŒRíE`i>˜IÄ"3°=¢
®iéM½ˆä/5’'ÀÇ°2³¡ˆJfïÒ¥AËqÒHOz®s_ßÖC"}ÕB VVrÇ°1—nìøDuj,ÊSÈ.4"ÂšJ<vÌ_c—±ğ,K.í_Í övbµİƒ˜Áğø—Öàlˆ/y<?îcœRÖR‘NãÌY3išRİ/ëMõ¼¬3^Ëš^N¤¨«÷ò¨0Âs^ß@ŒWè&ä%qB"’DõxwßK(ÈS<±Æ¾ı§ÚMUbÎÛ§ïo÷íï¾Û r£Ÿ84½d0ûı­`ñFI÷²ŸD¬+î öËZ—âÜ9—Èô]…·#¦coŞ’Ë@;kCÜ>¹Tµ‚(wğ¦ÄALÊU(M9õH\òz™.¤ye­üôDíº3o÷TåZŒƒöŠ¥Û´Ÿ\zÁóÍ)™ûº7x9„p¸“ÁÅõXV6WÌº3&ı§ù~0gïÜ#ğòÍY.³w|0–²6£VhŸ²K¼3Æ˜öçŸ9†£^ïx˜A­4qÀÓéŒTzàòeš´©1…6F69D±˜Œ‡gı~o02î%Uì$—MMâ^í	~m@F„¯Q„ƒ4d*æsï^ƒX©ñ‹u±„©é]…ÓŞ¨{øËxá¦¸AğMá
A‚ÀGˆØ;÷ù™p‘=R&^ïÜõ²•õ=P®`ÎŞÑŞı¼Hmxœÿ–åäì¥¸jı3÷Îå/ß‚Íæ±DÇ$[f“êF£fl=şNŞ	´K.w¸İô}'}ï!«S~ ƒ/(Èõaß`#QÊ9¾Ç÷]ˆ2 ca!Ë—r:±pJ¤xa/¨î‹ú +­»<x´˜7g·-Ê.BÏçvfÀßˆfÒÁ—GŞ‹ÜE=5ÔÈ¶DMM½=-v>¢Ú¹¢ÓÜÑh¡Èİ4$xa×šÈ¨4˜”ûx>y†*‹rx—±í¤u§è²òp0¬^·¡‹ñ(*ˆØØ0 «C#7¢ÁÂvMÇ˜™ a¢éÚ§F+Û·˜m”9©¸³í¯BHÃ9„<âhôrÿè¬¼¶çÀÅ}a÷qM‘ÿú¤í˜ŒÙ}ÛÉÉ
éU¨_iâá>ŠŒõ>€kâŸ(”÷Ù.V:Y9 lÎ·´‘©ÒF,o\ä{¦EaRÇ¼«|I¯ÁÖXÌµåı¾Xrè0 4~‡µ/¸³ŸgÒ[È–}È4¯÷öŞh/:Ú),eI;W!åïİ¼Ïöï?‡!†|¼á•éDÔ¨ÓøãMÜ­Õğ-_ V;ğğ5i#Ñ‰|[iÂÖ»­ñIçôlÜuN’„¿T§0Ï=‡|wEÊÆA·_ÚÓ ÏáB<>è_z}~R@@:¼©mŠê}@gé{QçÔñës×[P~·Ô´@®uvÍBºĞøƒ6l‹¢öLa!´X»A€¼Ğ"HâëçáÂ©£¡IiËÔIØìtsCıjá|’%Š³%>;ü2±üHÈP¤Cc6g£?Áş&³ƒ÷`ÜÛğú%¤¢â, uİÓ.O”²ÓxÂï‰J0ÊÂ²&ÑgØ@t DÉ”¶ï±PœØKQºçXã¼»5Ôû]²ºâ1Š†2õgùS"˜\ÛGT«äÈ^fY
P•{µ<Ì*‰©+A–0ìƒ¹4“È•O²k±–;µÚM¯ß9ı¢ß¸x~«p?Xš¹° &%Ÿ6ÈŞúaWİÈÍÏ”ª&m¡¹0 QÌ‘öö? ¬Bèã”N(ñÌtÏyÁIÁÒ‘d¼é†%OÒªH%k¿I~~«Ã¯§€9IS‰E¬}øúN ,…ü”ll*96?şİ%0üÿ©$›;—ÀÖnòÔ2ØlÕ%€0-¹Ø—W¼%Èß ¡rÏñ‡(“^ğıÇS4)9¥—}á¬„1Ç2éÈ{jÌÚŒO şãÿ¿p@™qo%)ùãG¡IhÅ>‡KK÷Ï˜÷¥’:ãØøûs¡ñ*Ì0Ã
0ásğEµD¤.b+yi_œX½á/CC>C¡¸¶˜·¥^cX"òÃÈqb6ó.Íİa	‡446ãD:Œ©8 x–:n¡œd÷ã£‘ŒàWvNÀ÷ƒODó$_5v¤Õ‘Õ‰{ÿ;Å]u¢`Ñ§Ç?¹ú‘UWÊ˜âßÅ3ÂÏTxK÷ğxD]så¸VhàL©Å“‹‡ß:“wø®òÚ¬» ­ccô¬eN%ÕòègmNÔÖ¨’Ï!w#È]ÎNëF$V;5¹N¾J˜dŞÄ!÷/e-²ì¬RYMJ1ªàêFA¿®®ÅˆZÂœÆg+ÿTå³YÃ„[ÿ¥×Yô¿í}[wG’æ¼¢~Eº€1I­  uiQP%R2ÛÉCvw‹>8E H• 0UR´­ı/û4göeúìÃì£ıÇ6"òR™YY HÓ²g8G"P•÷ŒŒŒŒŒøâ\^Âá=4|ÕwR$ØNm5¢!«·Üé×ÿTeªQŒšmq~ùÃè	ıjŞúµµº1#¢TúusÛ”L8x‡g—ôËÿfWÁQ@÷d()!8ÖJ-8[)éQ5D}x°©*$ˆAşi­R—hÒS€kJ'8Èì:ÊŞ3e?7êF©¸Noëï¡Ç°èÿŠ:¡ãoIê…»1ÎpC‡Ç'å¿Œ2)4Öë—ÃøxZÌ4ào¯hÌéñ>«RE ¾×¾:ì<£Zø·«L{»bøWádÀ\øÍÂà`¦æÀ/í“+g>*Û³²ººQ¯OÇè|cŒÊœ´F×ÍUOE. R±6ªèn©¿ó*ª+Í³wXõÙwÍÁJ!Ñ¼œØgNe9ÿ
o7…Ñê+n›:7”µTå¦B7¢ttL¹$T0ª&êdDD©­<}ÀƒÙhW-"ŒdÆÆF£%ö	ØÀµ{­5ù=ÈËÅH.GêÉ4)RzÔ“‹b"CnÌÓš‡L-F
÷g“~/Mä ù®Ÿ¼v‹şhÀ¿Sü;$±ğà$‰¿¯Ò~ÜÈüû º¸ÈM'â;/ÛÑ¸_sã­ş Íõ.tÃOÿ5‚qÊïûùÿß'¡øZœ>œ@3ëg#I¿çĞ:^|C—6íkFK+Í´¯*É æUO>ğ’¾hOp9Â‚¹lL2şM9Ä$8ï]õÓ€¾‡²Ûï±òïË¢cÿ8ã}ü>Ç"á°|‡ÚWQéèCğx3¢‘¯¨_ã_áo0ĞWPùS(«4+¾}OB}“/§™ú"ŠŸCÜ 'À¹®7Úøm2'ôw:˜Ä7¢şaXğÖy÷'Y<d±7A»˜Œˆ(R’W÷UşM$Í&ÚˆÁâÖN¤…Ã‹ô¤}Yò¿Ï£Á‘Ü…gĞxaéå"nÇ·7‰É³FÂ(Fú‚\¾"§Yz°ÅhO¥ÅÈ•Ä ¾T</·ÏàŒdÿ.k‰ÈıËmì¼º‰e—s¥9Ç0âLÎLsdÑe¥³êY“@D%ìNóNõ]Ò‘¬¾ÙhÑ,@Ÿ¹;â"ş7k½(¿r›
…Ù…ê–#³
ùd›ô
ô©x8Ò^êäÇ–ïĞ¹®d_"2l aôíY„’Ã¶O¨›H9˜)a·Äñ]F€ã¹!èiíçnD»v-Uú«¤ò*C£RÙqİõTÊD,ã·ş^jÃb•f¥¨†oæMiE´Vî"*ğ‚úÜßL´o2¹½–UÒÜí’¢™‚5bE‰¯Hç¥0~íGGjÜp'°EÓ‹—Œzñ$K;>H~~êƒkVA5‘M—.ÅAît¬#rŠke8ø 2aı÷¾ªĞL$	›_M ;b` 44!b¤/ºâù>>Öîàı°ÇÙDgÖ±BÀ</¦.Ëí¹‹Å[>øZ%C¿{šB¡}t/N¢Kqò1t£´›œOÇnm†€åoUÃÈ,¦äñlÖ³pzÁşpå—ÒB6ç÷V„6ù®Àgœ“öˆvó-õåe¦3_7®Rå~µàFzÇ	E“ôñf84‹¹İb¥%ÌÌ©´Ì%Ø½gˆMÃEæ6Ã”'&O¤É½($¦vP±³Š©ğM‚¡ÑÑ¯3Éùº»''{oºå)=¯àb}¿ ¼x,â.=n\tæñt+R‚ÊéAá8se÷*ÅT«´ÏÖìì'†Ò½Ÿ6Ïšµ"TL³y‰çßê0-fİr—Hû[ĞŞ[¹¹½NGEŸ#ÓåÈğ8’G³ıîÇİÈö6‚ßSqŞ×FçSÓ_™çt·œÜGèy…¯÷ùG)·#k5›T}¦\G°_9SĞ–Ùs5«ÓÎöÌïô>ğ±üëšn’rkW±»yŠ9\ÄîİClq1Z˜™èui^Ü´ªæ²½Üı¤‰¶%<:)‹·‹å@)åNu‹ÖAòÒİû1[±òk{0§t³í?wÊOºÆ†9Ô8wÍYN$.LùéÏıêÖVsÉQÆğóv4BM^±üÈ+Ãáˆ{¶DrÓµõD˜cÕğr64Ï©¼¸Ê-4ªXmŠµr@o¶&ájCpŸó®…ñú1yÕ×¢í|Ó™‚W©š>{2Ï3R‰êF%.´>·NH¹¿ƒÏ·ÿ–,·®gµü-VS¥¨VÃºÜ\Ñê%üÕÚƒµëE1ò ³bğöÅ œ 7*p‘,pHĞ³˜‡Å|ùø­\DèãZYá?˜ì[~Š¡Dƒ˜ç¨HxÜUB:fD¢¸C¢,è¯Éß×Ø`
•€léä¯­-Y•ÄùÎ¼ÒÄH»K£oˆ*:2éKMÁ´¾üËwŸVœ6C%«PlcÆ*ÓMË3"³@# Âk®+ØÊJkıp|eˆí+ÏÿŒÇÒGÍo5Ö}8ôã0™zòºşÔÿóêås¾ùÊóİñU”Äc4Á?$ğ“”ŞÀşû|Ÿ×–ãÕq‹ñ3¿ù>…M‚¹i
ã4©şÕ¿BÂ¾(K¨iøÆÁ(Te•ñ¬<óó¦£ôêySôE·t³ÇH°F§‰W˜ó‚¹êyãâÅl‹M¢Éwµ,åëÛª@6édÅ¸‡jmUzvñº.…}BÛŸ‘í”îşÓYŸÉ€<«­Â¼|&k~eQ9•jkv†™‚/k†|íÒ|%—´:|¦
Ø(/ dÓ &älŞ¶üX«>â¾Ã(œ¢AŒs>eØÈ•R¢?ÃvÒíâ§õÓBã”7Åi³|ı¨Šó°xL¼I‰ÑHÂMšf`PºäşRä	f±-*váäæ·‚#ˆşê!'"ı­F¾ıùßdäQ”m8CÎ~Îø­öfËÿÑZ_ÆÿXâ¿ÍÃ»ÊñßÖ-ÿÍşf„ùsÌÆvû‚íñ0`c~Á¹àĞ°Ú(Ôœù†!á¥Â{ğåƒzYZA¢šÏƒñæUßì¾ÜŞgßlï¡S{—Wû*Æ	º|Ê(Õßìïìvj+gá»ÖÖF{´¢B†¿İ>Şİ?ä¯ÖáİFş®{ú6â¯¶wğõ¦z|°ûæxïDdiåÉ%¬ªÆñ®g”IÉ6„Û?İWlæÏ9Ò¬h&<Ş>:éí¾úº‹¢“ß¼
¸åÆ`òá·¼^ËŸÔ/¦Yj¾êı÷!½Ä#fZÌª
¬_$èø3øŞš—¾é’¡=ÅBô‚ag¦Ô£¿ŒG¥î¬Âşd0V‡“Sµ? ºØ˜œ9e´Ì‡"À690öñúÜî(¬pØˆ×Î6B ÂhLoyòtî#NQMLSvÃ¦Ş8Æcf«È\»ÛJëÌgƒ8L5ğ/|öåóv\€Û¡şÒÔS®’æàÁÅä!C«Pö q¬ëZ»MªLt“m>Ü•V•ÅŠFOÙ4Ã¾.Õ/âéxÀâ„µ>¢Ÿ^¡8<¹a£àqgåàğ`wÅ1fæùµvñ]F8<Úf§(4+Ï	k‘oFÂPÄåAV‹uÁí9ä]}%}-Å§ŸW¸ïã€Wƒä2e|(a\åoIŠDò ÕĞŒ¡J´e%°0à¦ÕÚj¥”Ÿk8A5Çph]¼â’è6ÔB…Ò7x‚²GguÍE€_~i¢LEeqÚS­¥ˆí*Z|*ÃôÀºä­*­ı_›Í³f“}ZÓ¡îE
<í“àEl*<rM¥ÊåCq¡‡=Òæ» şÃvıïëõ?m}·f"iÁøC.Lóp~dÁpkp:B| >›v«òÈÖ•·e;)Ò	×6N84Â;“,¶ÈÊ¦{´¿wr²»ÓÛ>>Şş–*f†²ÑDå“c3ı¶J–Û‚œ©’îI^G§VxÂ8ô©´9ÜëMç&6MÂ•ú$IpƒD*)‘÷iaBĞX¨”¼ós:¥M-ÿÎ»‘—¤7HÎœ–:¿Ê¨Z‹ZŠÄ‚¼ÃøÇ¨T¯ŠIé+Š¡I'AŠLÿü=İCŠœ	¥Ò¢dhËC×¦sk#Ÿ=áö„uuj­-õ[­`XQùS¾1áºïÔ6ÔSÑ3S±hÁ>\2©ã`ÅÔKQ)±Œ%ñ%°e¤Œ9çáD!²ÁéI$¯Wa£a¼>¢+]Ëãi²;úMÅ &&ˆ˜ô“,ˆqï¹'9Úw Ş0‡„íİ¼ÄošÀÇgNÎWbR½\¤ÁÂãÜ´u˜)QdsbøyœÕ™šYşF·.ôÊË˜…áŸåüó¹/Ø
@úÚ¨š-0c7ÍÊTÈeZÎÃĞê°?JçÏÆwê¾+Ûü¨òKO$²À¸ÒQ)iå‹ºšBÕÁÇ¦ÑIF2›.(aÖµÛ‘e~ûëfFÙ315ÆĞÏ9)İÖ$«µEQ™È%‘·Êúuô}€ÖÆ»Á-éíW‚¦ôV']L³¼oéıÊÛ–Zt;çZm¬ÒS¬ã8Îä á´ûˆ-FÑIKhlsÏM$¢Ñ$„5c©T äM<M³ ê›„Ã˜£ujXf"²Š8Y]#Æ'÷ëPh•d:&_ŒlÎ>“è
¦ü2LÏÆ»pÜ‚õİh4„^|Ù†áÂÿéÌD\h ô13¡;Í!ÖiFgA~fÚêháÉa*ØÏÃAJ¢]n‡záW×Tš³÷Y½âş¾±X	ø–ÕT¨Ğ+UåJZÁF´s‚‘vĞ4nfPCvğçO7_°“ä†!JFò…ï8·;ÿF£»éˆQ¤ùHeM34€I„Nç"¶N`œ'IÜÓ4N2bı@£â–—áˆÈ(ë—ÿ…kô<B+Œ9AX˜F <äR/§éÅ§Ö‘'1[†É9éêÚ«p·b|ğnı;ù~”ÒQøú=’Î""`Ni€é’k?ÿ²Åªáø_§¨¤‹ÍaAub¡ô§•öLYÄb "æ¶oƒ(£ø	µ÷P¨T°U­-*QtÓ@†©Õçgôag©;‰G,€EÜ?ÓACÕ`Lq®Öo€8áu|]Ÿƒ)¶(CW„p°f'îÁÒõ‹èc}a,§KeÃU2Oyõ°ãÃ %aª&*µ6©ØöÚJ£…SàUàaw±ÈK'Úœ1ÑXE°×?sæº®¯è¹¹µŸØs^`Å)îßÏÂSM"ü'ÌJÌ}Zú,ñMÜì÷âÿ<zÒ¶ãÿÀßGËûŸeü÷;ÇäŠÿãëT¾` ŸW2Ö»Ê]¤ş´`9šùÉgŠì^$!(Ã>nÎ!ó	$+Ñ‘[Ç­cÜÂBó‹aÍ„:nLãÜo5ÏG÷ÒIß‘ƒ[¥øgœ<
u™w–Ÿ#Î ;˜0kbRŒ ÏWYõäBBÅX§7	>¤Ú¡‡Ğ„ß¬Óx:WûÑQœ •³;›—c^h}Ğ“ğè*‰JqÅ°ûsÆîPÄuävÆğ!¢‰Y–·¼ª‚¿­^µßá‘[(Å	+â@Ay@4Kiù·ğÈƒ_Ú:üß<@fã,ÈØ9¤Q
Uº’ë¦Š’ÖCWL\óJHxIø\#º"_İCGš{v—éÏÈFKfãØä@6V"“ŞÜUoœÌ­ÓÌ®T¤(êÜ@Ñ°›Ù4å6yçŒí¶ó­›*K¤~øÿä´K7sJŸLJ–g°¡ñ[ù«ƒÃŞ›Ó=¾âÅ©¾Ş’'M#–fÊ_Õ!O•#Yâá1HFÁá>¤æûåß~ù¿°JÓø<Aõê‡¹[?¹4<¹Š‡"iuVYmoµY­5¶¦s{q™Âcnı‹< ‰#§~!Fš!ëThu­šQ•N¾è“q¤OUm	!ù2©Í:¦¢Šˆ	ˆ’2âÚ7ù[jã*F´ Y˜+–#®Y¯øT7µŒ¼¢¥Ä8Ç¯Ş‡ı»¤–ƒú`k¢y¦‹û¶~®æã’2nş½½²{|°}²÷Í®Š‹¦¸'ügr˜WX^Ïaì¦QÛ×:¥U´¯uoÑ¾°ch†6`ÉºTá¨ZSŞ±¼•¼|Å¤0Fx0NßÇ×DXr4”à·ÑXo¬›ƒÁæŒÆÁîîNïô¹Û.îLV<úÈvÂó(€¾¯7'áø/;_3ÑYÆ{/>Õ‡`F«™„Û}Z‡ÿóé¤ıöYşvÅ=Ÿ¶ºKê¿ØÆ/Ÿi¡›esŸJë¦”·0<dÓ”6{¢ÕúBEm¦€Š³™PÁš|°Ò•cÄ=PO¹ )ãÒÎIîjhHÃ±ÔÓZÛä·‰?r
y¹·}Ğ{	€`z]4)õK–™µ³‚Æ åÈú9ğSìè3ßU›¼¬D©£r§Z¼†G·ÈÇÓ3‡iÒ <oˆ ×¼Ç¿öø¯F¡†÷yY½2@ôtqæ‹h½æÜ{ò"úÕsî¯qÒå ›q0Kƒˆ(bÕ/ÿÄrn,ÒÀ•­‡N¡‚[èÜÜ×¯w§Fßf©G+vgT¯O¦Ée¨–ÇŸê`Saó¶Zh÷:³¿ï>e¤g¿¦ÃÌÃG0Oƒt‡?ùL#!ÕÙûÎ^{sö¿¯³ˆ$\SZH2cÊ1¹ùa%GÅ†½R•F¨Ü"[ ¨]G°Áå)j\ªf5×ÚÓ9Œ•úÂ(FIk×©ˆ1µ*9µö£N-ÂägãnO&Èf„Ñ¿§öNyW ­°‚áLç/ÛßlsŸ.¿–'Sµ‹ÈPã¶s)Ì=*µ©‰5UŠfSµ¥IÍšIÒ)K‰eNROüØ	ñîÕ©sŠÇ²ÊF“ÎJşÇeç2ÚÌº9ş2«÷·¿}»)dJûP]f¨X-b‡*0Eò\ÈÒU¦Öšà	Ô”°Ï™$€)r8"ácæçñ¿ûCWëœ@€<ÛG]ÈÛ—¤tÛÄwŠ<•<ˆ£®¥4¯ó,–âÜ0Ï“¨ªek—?|ï_ˆ‘•¬Y‹¶´š=VŞî÷2Ôì¿Z‚–â¤¶ğb±Q{wöĞ9[]H ¤YaAIÖŞËrÉ;‹€µ:jû{/»ò|D¨½o¸ÿq.	9b ã-‰,–jÔ‡p#êÿ(Ì’8%¯º#ş¤AëmÃ¸¾6ÌŞêü£GĞºæ]¾`H§İİsMém©A*sã õ&ÇJFƒ*;Ëéñ~G·ŸÕx_ÉE­bÏÆfiœÊÛÙAÕBkö±aïÕîAw·£w¼ıvo<‚ÕëÃ¨Sâšã¸GqTeF¡ƒ¿ä^AZ½*`CÓak}»}°ıf÷¸÷êíVñ;Xñ%mÂeú]Ç/iŒÿ«‹-ëË}•ì€Éöfİ4µÊ#«~¯p›Öúün#£âêŠ>v+¹/› C|Êé½“£h›¯SÇ{.Z¾	3]Aˆ:å†Ä]'ZAI­ (EpI®„ˆ.ßGşƒ5hf¸UÉù¡JØ¯ÈVw÷w·»»ÍÁÓ£1“œX{¶¦î
ÊÍJÊ¹'³c´sœ¥|D-Igv7ODP2ªJQi;Súöøùf‰ş¬qœYê½Ü5›PR”P%Po|iR9Ãÿ–¿¶¨ı–€ÒÌŸÖGñ Á] Ô¯‡@²”a·¹<5½8éÊÚx%—(6^^hËT<š»Tµu&‚a2»Ç ‘|]¢—`<BğE1Š`šI¿öeP 
¢‰œ€¬:$ñÌ¨|.õ‹¼/ó 7»'ü¦ï5
¢‡†¼–1±´óÂe„màEgÕïAzôeÑô`˜%KV¹(OU‚¬z=Æ š‘u8,O»Y˜Laû9gñ¬~aŒ/¶`´æ…SSûô8#²}%±q0½¡Ñ¶Çq±êS4™‡8#\ÆÂòk?ª÷šYMy‹“=ß"‹ÙgŒ*‡œxòä	«_•Œ‘~6o,œËh^&é¹íªòUz·Fİ¦UâÄzÛ,ûíqv’D—æõ¹uıcïo«$Ò–£V*á¦![fá®Êº^4nÈFŞdÍ¬´±p­ÒjZµ¼øHm1Îh³…¡9Æúf“†#&.½ĞHJ1^¦Sh9(™~©0ƒCøLGñU :ıröíö›=”I¶z{;»í¬³*C“‹0Á#)‹ñîWš‘qcìf¿ü#‰b´Ú!ƒt35Áa€ü‚	Ú–$ñğcxäÊlÀÉö±ÑU·ÈÙ	d¿W¢¹˜],}‹2ã­)À¯4a“‡]sË
ÒGLĞ6kĞÚ¬Ú%Tn
¾Ğ¨^F· ƒhø>àAÿ`Ú£Ëq0l³Uøçè0I¦“lM¡hÒß÷„ÜPhÓ§ã¢‰‘X†>ˆÖ{k]¹ùPì|½E[šbµšq×Í c‹\v3	²±¨m5W‹³nŞM•ª+%£ÖùAÓ[Øã‰€ò÷ú=naÂ;)¤ÍÔœckaÍT\™Ÿä³É`²\©ğêbbš=X‚’P;˜(Çî¾V¾ÜG¨ÕuÖİ{³wpÜ‹+i‘oßïjŠ8zóIîƒH6'È]Ã”ñé'µq”i«tÆ
^d3«ÒiRPÍ«íú&=†W\#‘şG@ÏIÑ§®×ı¤ı¨Ñn<ò]‰”ZÃù†Ë8¾† $i(1NHï†ï*=QG'lÀ|:K†áïøåˆş
C£‚NTŒpú(çÜ…ùÛTditØ•ôQN›F±Ÿå"‰Æj ‘ 7ç.îÏçJ¯”.ïUnàèûk ÀöˆÛ‚x7C!V~O}û’ÊÔ÷"Ì™†~3€6¦7¯üh¢¤DÙCuÃ«®3_t«¤¸x„M]™céP•—IèÂ²1”ˆhÆÂ£÷S,‹éÖiqü.5ç·„™ºÓ\i³•›¸1Í÷íví›İã?b_-WXÏ‡ÃAÎŞ5µ´½'ßÃï¡[ÄĞ×¸ÌY{rß›İ¿4ÅH‹ï)ğ.ÙT/^îí„ÙÒ‚ÃÀ8Ó&gñâOj»éaœ:œSŸàğ¹än0jçûÁ¼*Œ´l^â ùf=~A‹zÑÁäC_ĞiÎh	1ñíŞ>`6$´ëÅÕƒ†$7—½+fcÚ#2'c=/b2§v ¹2«-<)R£~¤\”Å¶î±¼-o8€.ºGş8«b«ÊV¹RåXùø­2L­iíGç²!BÎ«–¹8ÑÌÈ‹ªÍ7ˆ˜À€‹ÊñÉ‡‡û™Ñ[}1ô#Cû6·s³Sğ›$yÑ=‹Eıaš8«wc¤+•ÌTı½ˆ*òâŠÜãpD	0XKf*2XRëqæªø©¯ÿÒØ¤¶Ö}[Œü‚ã—J{Re§—›î	<¶=Ô.öVº hÃ#tï—Ö[á ;ÎË:oÈcE˜4a”gI(½\(‹e€QèaAâ!Z§	Ş+òï@´UõÉZV¼(²Dñ3»Ë¬ŸÎŠv#¨•½şq»s=Ö®>Ÿå_Yı¸´›só•„J“1e9ğÌö`0 ÅœÅLÆ|Ä£
˜ˆxt™eVOGı.Ê²ÒkL7Ÿâæá —Ğ+R Õ éu$hŒã²îW¶¼+}ó°ÊÒ_ş!ïYˆŞÂ¨gHE<;#Oe)7kÄAÍ~.di§Y}A‰Äˆúïñ÷«ê „¼€å‹Š¯Â¡TQAb£ Œ&âÀØtx–)¢*ŸPÆì¡#†W4V“Ax”lV ëK°‚£Zv’mS£Êb¦FF”7X$ëÕº0átå¡)Ìø74æ8¤¨æ½ÈsÁ0ú!$&ë­iøscÂ X9h?èRÆì^!¼f¹?7l0)& < „ş¾ÚBBG	rŒDBá
’"a)ÍßJª•ê>ÍvñÀT•Qû³‘Ş|£ÿÊ…*À7·a5‚ˆB&`vô‘ş/ÿ(öşh‘‰ÚGAk
G@ïùCcÇ!‚4D°(.‚€	àŒİH@zMÎöØÚIHº€ŞFo½·n¹på]]07«BsòÆpIX"İ®-›V[nÙ˜My>UµkÕÏÄó¶„9­ÚYÙÊÄ6ú#Ã}˜«ÊŒïlìÀÌp¡S¯s¬Å"G¢ı«`âáò³Sl7ú‹“ûC*IÂßOr€ıùY/>qX±"I‘nIÎôjÉiøöÎ„ºm”&İétl¡,õ·˜\Ó–JÉèò4Ciiìÿ•‡&­T^¢xM/¶¥AÈ)ânU%ö.{;d÷QFÚÈnï¼ÌâÓAxåÁEYˆ³¸_
CÖÜÚ÷ğz& ¢K+ßê"2›aTÃÇC¹Ñ•E»cóI3–]Å¦Ä¥®Ö­Å.-­`„Òİ˜pR-^êÄ=‡Ğä÷şËK‚(}²àãÍµÊA´„2lgŞŠÙÍà¹?‡(i[%»oPQ»_éÊ0§’«Äw^Šê›’»g%·Jºo/İÚîƒY—lÎ³øwu.…R:xKI½™"_a]°êÍtª/Íî	ÑÀ´ÌM‹[ÍÌèd÷°ãü»‡‡Oô@;¸ßÒÌµ*vøšI/ñåu“UÄÑú¹ã8Ş|ìÑ³È@ğº“sÿ¢æÂ;Õöé_÷ç›<h…ìºb|l@şdñ¦J0h¸@L]OèÓ›ÊËx{´¿÷jï¤·ıêÊè½=ÜÙ…#x5 ¤¶g~¸[j¬òop²B6"Wì–’vx“7µsj\Ÿ5„¬Ÿ‡À‰9_0H?ÇˆÎBê0-«™¡RDÉS":r÷ZK+åËmDcƒÂM»×nH6õGè£Á%#ÏŞ;7ª£¿ÜˆD<2ÌFèÙêîª%~ÂKX¨ZA—v‘Uaˆ Œ ‰4v§`hôò/BßœÜ[–ƒÛf×PTçÃ˜·ØN=fñ‘P•ÎØÈ¬mÌ+ÙµœdaÛ˜e^—/’£8Í^‰°„…]Äµ‡|º#ş[ƒ`’PŸ6“ø?O=*ÁÃï›vüŸõ'O–øoKü·Ûâ¿•Åûé;QÜ8¹g
ÅMì9^gÃÁæâ™4S»¾¾n\EWAÌíÉ {ã<ià,ÑìbØŸ:¯­Nğ•¢ìx\‡öÆu5(H>*G>“WZy{V×˜Rô§ˆ`^1ÄüŞwøöèx÷hÿoÉ^¢Š
ö¾=<Şé¾£¯¯ğ;IÊ˜³4EC{@à:ŒÏ}×5û›:JÑ¼Wü­Á$B?PaŠ@b…æ¬KşşÉe¤íUFtYæGhë'Öé°úöfGªuã´À\‚¬Sÿ/d±ep\¨×EvM¤Ànd\1p!«¿feCÊôç‹ç¨ß*G£yûZxYÏşO¼aM&égÆÿl·l>.àBò%ÿ_òÿ»ân¸ğ?OŞ‡”5§ô1@;‰±c\¡”ÒYúyB¾åº ‚"¡5.£œ¤<ä‡T‰4 Y ¼ĞõT@ÑßÈsbÏë|„]DIš}ÁL¬(auÌñàğdï5z©ì`_¥ÑÇYtqSG¤ô5O©:<LVY{µ”t †äáê“é,ù?s5†¿æ)IY¨£5ûîÒS=ŞŞû;Û9dÛo_îíœìòÉòä)WàÈêéç<İÌâ~£™•Ñíşºó¦·³}²¾İ¾÷™ˆ—?(˜…h/}Ï©ği‰X/¿İİ…cáó`šyL¿O&e;5
&MTı³ì,;Š¯Ã„<Tw‚qÙáVz”è”üC@)½5·€«:ºGGT÷Yö@À®ı‰’áƒS‚Šb­ÇõM¶Ò-¼xj¿àwÂoÜá¥ó)•MC. Â^‘ìtüË1"¬Ê×Âıo4$=5¢ÆSqY§=u€^uÖõ,*˜ı"å¿ıUw¸ÎÌç\¿•‹IEOáBß£T aı°¢Æ¢ˆ\­Aîk"1ÈÙıúäğÖåÇÁ%
eI1Äã5ŠÅxxt¢µÎ€6ñÉ<}fş4hL/FˆÎyRôd£Õ~ê9 Sôâ ^¸E³.¥’İÕx 7ñãî$õÍ'zÌİJ¤Æ'÷™B÷—õsõÆò¨ê$­§çz®ÛµEÚu	NG+÷“hÜÇ§{7m#ß˜»fV>Q³Š ¡Üé	ô¸Ñj´|ÏrÓ™9¦]}0ÛO}EªEcöĞŒõ²h˜…4Ö‘	Š¤n«ìÎJû	&[á=™ç²æ•¢îh ;k³Ê"¨lL·fÙì3Ïaª›ŸnÍ2ÌÇÜ<~ËÛè'·Y•µoYæöfeæì3»Ù¦~ÎöH˜İ¹ú¼ÎQê|éÔ~*‘l‡İO£ˆÙ/m¿’¶Ÿ€Ù£C©#ä¼á2ÊŞOÏ‰1|?š`è™`&²)Å~‹œ¯€Š‚SC‡o·.#:&¢‚™®··³+SÍ€„Gi¼¤|¨§B‹04/·›.ìOF‰Z+wÂ+’Ó’øû°Ÿ¡ÛHU‹¢+*„ÓIĞõ>À¦)ûòv÷à´·w²ûÖHï–³šÁïªÈ8!ÕŠj€Hû!‹‰©U,l³Ñ"îc>—şzÅÓª‘¿$->°[g~`¼èÓ­*kaiOŒ‡ª&şnÅÓ|ÍsúaÁ###iñGÑ¥OŠpĞ	Ó&	‹(«£!µ]Å§:¤lÀ¹ºññßÓ}Íaë¸mÖÂ@Ì+A0JLnBjğÁô½ãİí}*Uğ~½FCU˜ğ&ÏJòQ–©$:Ÿr¢˜3cÔSÚé,/rCÍ‰˜V‰Ø ÎÉ7OØÏÛ¯;¾+àç·áfÎfó¬Ñì}bUÎ¿ğQÉÎdc¸§•Æ
]„õ²ø~ÁïsŒlÊ¢1ñ2Œzb°Ô “znlmT¯Æ‹$'äÒ Â£¦hj3.Ó¦İ\˜q;Ê€cÊAâmô/.éùÉ­Â¦)jP´' ıNq[YÚúƒVï)¦Xs”¤fKÄÉ¤’ğ•Ğj<mPÎŠç™¶ 	S+»İŞöñ[u\Ğ¥
µÄ-ªñ"¾È[yöêèTÊOha}¨¤)éLDR}@Gã·_½ö1f<Z	ÀZOFWOŸÉÓãÑñîë½¿vğ<»²æUµ¦azgãnĞZ¨}%íqç[°%šÕë|Ç†}ªƒşRƒA}Â¯çcÒHI½wDƒKàœÙÅD<âOzXTc8ù@ ˆÈ7u~³[çp¹®ıé‚làÖ1·5ÿ¾š,~æ©øƒ;5ø·l/w.Š"ÔıúCµñ¢?T$ }ïİÿ`‚àX=Ş}³ûWöÍöñr®ç}{Ü3Ä
Ÿê0xT“c™O”!Ö‹ÑÀqïÑp_ak‰Î?¶ZõAxòŞùeö˜•úIôñ|z¡=ìQ·å/X#—q+û1K3ù=È>ho.ß÷ë²&Ü7.‡Ól#ÿFÏ}/‡¡íø£p<E„6–NÏ¯¸™‚!ãÓ5†A84Ãtœ	“G.¹ƒsv	ÿ(Z%ÔÀƒ]¬y.àyb#UÆáÜ™‚Ş%¯g2¡ä0áß›"}²CI²Çã:ö×…ÕÑ³ã
&ıîİwWjÃä¶tQúWpë¥ÛèçdHìÛí=8Ù{.x”²Xë¹’ v;ÙÖ¢l—>hĞ4äáÜz}GB!æ;Î£úfãOÍI"‰ V®%A™¸D5Ì¤­\÷ôÉ€}µÍ<îŞ‹¶X”}·.ò½Òìæ¼.êRÓœ={å3nÚR:C‘¬†ÿ?«9‡Fµ¿Ô¤1§æÜ(½¨Õ5MçŠ­ˆ¸}c8¯ ß>Çß@©¯P˜[éËß•è‰ùK8Ü¾*«Ûwœ‘¥ÄYVZñ «ü_l»,dåéŠıj8_«ep¾ñ‡ÂÑv³±‰:Â5“İœØ©µódÑ¦§+Ö%v<åTSDd05acf@ë\‰ Î„ÇŞFZÿÜ^§›øŒ7á/puímÙ™‰¼pƒîalšÍz«Gù‘ƒ±ò»´mÄykÚykV»×H(d_ÛQ®}5Ïg,½gÁÇgü
Ç4{8Ëbøg?Ëï®Ş„-˜~—{×ÓÅçÎî§wñÄzÅ+È3ŸbÔfõö™¼BÊ˜õæUÌüHd|ºVC·ì4ìŒÂôçÿµûÄ›­›Ì”ÖX¨ãx:VhŒ)®ó~ş÷ùÕiæ7eõÄìûiš)Ó^ªöBZd²UÂ	Ãût„l€tRÌ
®‚hˆ÷ä˜D°µù­!Ó Ù#­áv\ÁP£,Ÿ›•ÕrLVJ:@CŠ
G¾P^…¤š©¸8«Ğ	•ç³Õù­Çe4‡»…
ÓaĞxûƒÅ[‹€ŒŒÙ!_+Ï¬µb·…V¶ğÜÆ[j9~uØ=ÑR£.õúàôíËİc{±¦Ú6ÁÒ,´d»1Ø+Ö­Ç–¬ïEÇÆgã¼/q†u¨ºy×şöòFn y‹ùâj×E¥ÁçÓ”¬H&*:ÅC	£’(e
Ÿf·#FHs‰Â3øBöÏÿÎö.0†¢¢æ!Úm`¥úr'ãnÙ3ØçÚÿşŸ×ş-¿
ö¿­ÖÒşkiÿ5ÇşëÎ`©ßÍŒ›ö§†Çü™LŒÉªè³Øûò,qó
§èÓ}ºÆcÑú¬—?–¾ûg›+<øäy\n•¸å®lMDAÇõM¢q€ÉcXå-’Áå½h0Í½Óz8ÀKİEóÒ–«ÿD…^µgõ»9®uæy:F¨…/Å‘Iˆ&tTxø”5û‰ôöçE‚Ë¨ßC`R¨AB³ê:SOI?X©T[ôÄºs‚¤mı9Çsf¬ºAO–CÚMï=¢gÂÌ~?V¿•å<}B¨X*Hm¡w³¶ŞÒı8…ï4ˆzƒmhu÷ü]ˆ	Üä×ô¬ˆØôÈ¢Ñh03­pàeõäÊ|£a‹’Ed›C1‘›Öëè)÷áÑ=½„;}r™vVksÏDÍÃ«ªÃ‚Ä$JËØŒX2N®|/b^]`£|‡ï¢Ãî‹¼ãd°[›Òã.PLœQñæŞ³<›¨›9q~{ä°ª€w*-‡ÑÑñ”Oº®r6WT§<++äYMâ+hí'¿`ÿè¨£cÈ¢>5'“şÇÇDÅ„
ê”<”jMƒÃ6ÕM}¾á 9³zzQôµâ0³V%›i$±IaäsØ_‚gÌÑ
Ë~Âğk×›¢[TpÂpe^BÍàíàéZÂù0”#á&%+ĞC¼Ğ®¤À§@T2"{sÇQEü´q„Şƒ×|eJÏºJ•X;¢pŒk:CäZcbàMÇU!†à4Ö-O~à“v¦!š	{¼`vµ<µ ¶IgêÛ¬'wx3ŠqCÑúú œ€ø?Ey¶ªæ'n¤Ëıo¶ûµÁ”-åX«?•6¨'\DX÷Ì‰™-H¨.gå²õÌU^KB"Ø­ŒDüò;d°Á'äÖ›sâk3	-PC *(“èÛq¾ø"À{ì‹/Û
á‹ÂÓc~¬;?(«S%.$z§\èÑó£¨`dlŒÑÙxö*„MUuÎÜî>\Í§Ë›¿èäo»8®ƒì0Ş6$·ÀÍ·I9t²"óœ.E{<÷‘ï	U÷M,A¼¤Œ‘4`î­*j#ˆş)¿/‹‡ÿƒŒØH
P!oÓaˆ¸jªTâPÊéÛs=lå~çvÙüæ±©ˆaI€×Ù]4z¨Ú~çN²|Ï–h¿õ-Õ¿Sl¢t½ô·8 ¤áÙÏ,é‚ù-JZ>ñ#¨V*Üq¯\cµ pç’û9¡D>?./Ü‡üß Zo‘ÈÃ9­$Å¥vƒd¡§?K§´@çZ7ÆÂĞaMC™E°ÆÇ<N½E>¾B^¾m?†ıá§Ÿä¯'y…àÚvie[V$×‘ˆ+ö©O¤x$R S%p9#n,«µYm“ÕÛáŠxwÌÄØæIn?˜„i7KĞîªª$¤¼˜I0ã©6Æ2@èbŒ„üÈ¹[< ·/¦B-DP*÷tQÈ¨¿4}mD†­-|¥m¦šê‰Dî%&sê7˜Ù×µ5®KLÈ¤qhÜ±ä=Å2Mæz÷"I®PG±ŸšF™FÉÕS%Â¹zjãÅ˜ít5@ÃQ±y©“™–rS';<»µå€2bîI–‹Ë‚†E'›Ø6åÀ+óvÂœÎèrÆX	Ö®È7"“xÅªäoQšE°²h;"Øø¿i/T'øÓİÇìÖ”g¡v9pÏ5J3û"gºÊ#!Ç¿Ç¶W+tÄÂÓ\~Q¡eõ”š6k‰$a†.D«_ÔşŒ€ôçˆ¡7/Bè*£¦)ª½|å	€÷äCIå;äJm½ª=£$©J‰bş+òX¼„&>É>0±’ò÷ÆĞhà(,âMV,”ÅÅm‰Xå†iĞ÷şúÿFs÷ÓæoZÇüüX÷?­Ö£Íb–÷?Ÿkş 	àWÓIc4ø<øë0ßÖü?ÚØÜXŞÿ}–û?È ‹SïyÏ'/¼
Ş–=G/´‘¾Ş„7t-Íà<9¼¨“ë[Ÿd´ÃÈ5{lU¹gÉ»ú5Ræ³>s±ç{Ÿ„¹1ªî°ÌFû/ŞŠÏ›Á‹cŞœı~8ÉR–‚Ô“’¦Ï3v&ö!;Ÿfüày
§Üñå‹zıyS|E-X„ÛW0lxÏ›0"ŞîG2?À•ÂEØg«xNG¨¬ä$fÑ,£ gªg’„/*x=ËJz	/»`Ä@ÔĞM„TİÏADzÑ‚ŸÓÉí%¬àèë‡}GÃË¬xn13š!^àÄ¡¬¬3l›òÒ° Å¨ª{h>ï€<™î³RÑA$‘èÙ}¢öd®:UP‘ÇqsŒ”Ñµ³’gDQ×¤4Ç¹Ãœhüı¦§â‘Á5L÷0:ùe¿ÂNˆ3·Z~ş;~„ü”şÛî ÿ?i?YÊÿŸyşu–÷9çc}Ã–ÿ77Ö—øoŸgşÏ|”ü&èÆˆÊjc°qò•)¸?e>šÕ±íé%k=õ¡Jµá/íÈ2Õˆn.Cßkt¿bÛow=ÓT÷L%Íbk3§,İ½ƒÃ£î^×3[sx
"fwvñ’ß]G?ğgcæYÀ‰®DÎ4¼\JceAÜ¨Ó7ViV¥[W­:«Ÿq™³ø„«ç¹¨l<ÖÔÑÆs²î¦®ÀØíìv_ïQc=ãhGg5´ÍC{ytë‡ÃèÈG'q.¹t„g2Ûºù¡2zä',CJc˜6Æ¨ÎººA’ÒÆ[ò†eß’;,5TŒ¯gú\&¤ÿkJ,Fß³†’±ŠJ-Òİ hrœãòXe¶M¿W.£ªÈ˜ì$ğ±Ì˜2L[â¡çáóy&'rı¥ å*õı,avéÂ,7ÇÃfR¨ùï~úéHğ“M’b*¶GvÄU|ÀmöåsQé©0Õ§®	}×buXè×±ĞdÍ—;M9ÅA#Ä3l…µ¡ ¡8
Áø†n¸ï·–è*‚#cõãé8cAªT¹k¼õPïTğÌ¹Ö%‚­ÑgJ³µ"uv½=nz¬…6SôLòfâeP@İÃ¤tµÏĞ—ù!K\øÍü¡ğ@HXŠ1Ïâ1_m§'_{64ßê€ôâ^ë_ŞÇÙÎE-´æ-Ïÿ­äÿş0 Zé+cïûSş. ÿ}Ô²ñ7áÇRşû<ú_¹iÂV˜ˆ³@v€¼H6T¸·Ë@HH 6LÃñPnqŞË h‰ˆt¤%¨ŒïMúRnwŸ>ó*Ïã!¼¬<F/^1d3í°9ôWğÑå¦$=*EÇ¡y¸¶¥ JÖĞÒ8ë“œ0I›9Ã­ç›öâW€Új®§Á;ÆÃ„íÄ×ãaXŞü{h«Dë‚ó[
{aB½¸ßò°'\ÜC(ŒïÔó&Ì•˜²71‚[Ã~£Ç„úp‘†Âd„áY¹¶w:fÆ¬š›§¦ô%=o"Å, “W4¦Hğö:x—ÜnàoªƒoÏªÛôç¼wMû¼Ê~oUú¬öİ§®|f=¢)ÎrUî=ªy%øâ[W[©|¦k|¿˜«õ.£½œ#İ]q^äFÿiå?az¿Òß\ùoóÑÆFAÿ·±¼ÿÿ=îÿ90ô€O]â_4Fx^¡:éşüš]„AFş°¸¥œOAÂC¼˜†ç]‘c.«CWáèjh?~ÈÈ5@Œ-ù`÷Û®Áy§j™Ë¥w Kaµõõ»Mp0°:3ÆMá„eÇVÕ_HıAcì íİÓ>2Pç”tÄÍ±‡0š5°Õ,	Æé$HP© LQÍŠ[ét³` r×S=÷A|mNÆÚÁDêîqûè¤‰¾09[ÆıŒÜWô’¸Ó	—àŠZ Ó Ìüù
}0"kŸG:K¬.¤ì/0ä­ëjOo0üiJ[R $yªç;æø Ó1»€Oh6Bà@pĞñ¥î=˜ö‘€ôR^Oi›â;—¶‘úR‹jÃËnèYåq¾4¢¼Ê÷0Æ°H|)Ğù;—¾$'B”I^ïıuw§„N)¦mRÑÊI}ô¡qÉ¥bÚ‘Åcœ‹í¼>ÕIohe7îL4œ&OŸ¼Dù T„ÀLK²Kò¸ÿuÃIÆæÓ²u9«ÃÚâ;=Ş×¬PİöôwÓÖŸî°ş‘B¡”ÆzÙŞ4èÖPëJHqÖ~êJÄ=Zi?g^Oõ7Z9†Åã¹EâNóÃÅk´aR{§KZ8M—G©‘Õ©GÉdòPK“Hê»IZ'‹[Ğ TK¬x`P&V‹nü“_0R}¾ìñ.ÎhK›Ñ;O(³J­XÓÛÇgäµBSƒš()ptû|pfd HŒuÁÒ	ğêISÌ÷íòAm|:áµõü&âÕş{‹|ï2LíÎÚ}At“ŸÍÕÙÌ èÛ“6³>Ñ®yÖØ7œJ§9ÿ‰ş|á¢…u˜¡·Ák­k”°0)œr—jcÌ¦l]~Ùd°è`šFŒ{p·§[º“odô1Åbï0^ÀOÇjßĞÁG¼Eˆhx‰áÛ	å0µüç9ä÷ÿ÷-õ/,ÿ?ZßxdÉÿíö£åıÿgù<xğåø<léÿëâÖjk?¤•b<ì’¬˜§ø¿!¾J“€E22«ş<ïÁ4#€oÈU¤‚´¦bÂ¼›af Ëà*ÎÌ<†ó+²¢1Îz)¾S’;]¿*Îó]şFÜÆæ¯nUî¯Ë­îà]SZ¾ÒWr7S	<6ÿ£¢ë,]•º&W¼/vİš_Í8©J›cñ¹O‹	Ëd‚¶ô_c4!;!®ï­¸ˆ´|nUÃÖâ[k¸EÍ_et¢§)1Ó˜YEU‹à1–hH"1·ê(+ÀA¢!²ÄÖ£¬$1ó43@˜ÀÕœ¿°¶¤¶·ÔL„­•¬Ãrä¶Œ¹­K\öâZÏµ1¶TÅÂâ¤D=l5E¢¸Ç]˜¦”å‰'y×ö—X´0sèYÎŸÈFdş¨K+Y³È˜W|Wƒ«û'ÙÉ¶to9ÎÜ†¦¬'³s—ö_šØ¸inàŸ-v{Ãa™ã6Íñ´ª›è4¬ŠÛìoñ”õƒ±¨No€ººŞ g)f×õ+SØBÈF@¤qFìdK ÿ6ö?1P$FôÄå“ÖQÉÿ9ı?7íûŸGm8.ÏŸåşç0#nFS²Õ¿NÃ$ÑUCU*qÎ¼}F\*C>V\l„RË(¹íáE<Æ×¨I ´H”ûC—·,»™„ÏWF!L¬‹ÔØ*É‹
™f¥Y8@^{/æ3çÃø\Øº4w·wŞîÙûêş€?ÒîĞ†Ğa/¢~EÜäp+ÆÄ«¢êV˜«“ÏTF52×qíW“‰ É/ƒúÏw‚­Yˆ2²ÁK¶­ßñŠV£ŠLZV­’n•Ûß>ÔŸÖáÿì'N˜(©Õúù?¬´­–‘Ø¨UªG\¥Úå>À6äbÒW%şüïìçÅ’ÊM4‰‘‰îƒhW3 ³WPº9L‚>Ô‰Œìb/ç·Wºù/mÑ4IİkE£ˆ/Š"47«ìe+©!n¥ñ1Ò	ÌŸ˜å\ô8Âêğ•ê¡v×‚‰vTÒÚ&Õ}XQmâêOWèVñ®¨¨«4™ŠZj‰Ñ$æ–w‘ÚıM—€‰Ò/Œ«‚\7®h6¤ßp\J„›ŒM‘Qj8(+ä„”Ğe©uÅcŞWx*ËMQƒûæà´)Dk=¿x8&KB1¤C;Ã1ÑÌnÚrcº‰•X°*Sö§	Ì¬AIÆNjòÃAiä¤Ÿ•™…!kBú&Ì´ù‘6‡5MX=ô•:/M[ìFA¾:˜âÕmÏÌU[¿)šæi%£â6±[
IËÏò³ü,?ËÏò³ü,?ËÏò³ü,?ËÏò³ü,?ËÏò³ü,?ËÏò³ü,?ËÏò³ü,?ËÏòóÿü¼ÎÁD  