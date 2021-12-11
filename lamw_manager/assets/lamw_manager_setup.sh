#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="705389589"
MD5="f4edd6b0710fc81a9d1014bdc17495a0"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25516"
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
	echo Date of packaging: Sat Dec 11 15:34:29 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌâÿci] ¼}•À1Dd]‡Á›PætİDõ"Ú’¬ƒu}ç~Ü{ õÒÕLá¾êÓÌ!Œ'Beÿ²t£¶ æåïy<Nÿ'µÛĞB-Ë(f`ì:ş€Ù®é`iMûëd¶uG<ÊVîC#uÊV0¸X p	Œƒz»ÈïÁe{ Nìœ	‰&Ö­\]ß\ê‘w 3ÖNÉø(ĞL¿ş}Ô©»şbÏëœœKÏ:ÁàWùeU–¹¸mlÕ	á)6,Z¾€a¤¥E‚Ÿ¯üØº•âBß±bX›£›B´üB¨lè]©¬òLıh³tšËèhŞ˜Y³oõİøªÏÂ‹k÷¢ÄÜ¯zaçqyı?°†XÆŞ–:¡»HqåˆA­*˜'¿È¦E±²Õõ¡?ÒRÙê:›¾gI€^fö¶‚ãÈá\ÂW‹° ìÛà‡·Ä%bÖÎş	š<ÃŠÊ,½/5z@†øV-–{Ò¹D[ú{â‡öíbôyµ{ôïÿ,L%'³ÛÌNÏŞD¸|)ZT’ÏÉ
M'¤‘+¾tğÒ¡NÆ!ÛL†@W×iyÒzÚ9	¨šC¿©*éœšFˆÔdYo¶–ªèÇTÂ0ã6/îÀ Ê›^ƒ
TªADg†Üx¤‹•3^(|.í˜J·
G[Ûõµ2D£|÷‰¤0ÿ@+‰öúåoFº
Å'¥¾BI§ÿ›DU¡Ù«
Z¹4’¿·®Šù8	¥ÂÚ6<1M5±\^°?6Ÿ1	
ÍÃÍ.ï/jşŒn@¼eam>âäâõ0Ššæ¤Œ::3OjÜqõdq((®dv`>ôO¨¯‰Á1sÿ`sRrÚ Jm\=ƒg’hƒ)ÓjnÃsl¦Ç9 ¾Á¹N. -ªyÖ,‚¡VÕ>±ûá{ÅJ§Å}™ˆ,Š4¶gµoşV³Ê&;z¬[ài’9ßÈÚi¥Æê²³LiNDƒsÍm’>cæ>¤32ÖpîÃÅ®Nİ)r¡@ÏÖ»åcyaùqîö¡±İI 
´‚3K“å;R7b›%‹·úİØÛWS­Ú«0àKt–ò±!øÃx- 5Ò£hÈ¸É^êÎM[¬áı|İö–Üäçô?ì®6¦#mk·$ÀeÆ>
!K\ùöSF-ÆŸŠÛ»4KÄšêrŒjäpTŸò¾ÈgqeVS8—Û†ÆıÒIZ[õÉ×-æUUƒ±Æ&öØ$Æd~"Ê›İ÷íáQj)Wa!‹lİƒ}ï?W¨á5ó>‚Î=]	µò.Aæ™x‚%!÷mùõd·ò±€íx”`Ç­½PûBgt@êEVt…'³'áÁ]¶so¦Wd"	å”—nZ»q2á»"ä(şõ¢$‘ü¶ôú¢2bQ.ä_xOı§T‰wt‰§¤»G…­mÃâ†%©D­]øŠÍ¦!¨%5bÀÙ`}Å£ÛKy‡oÁvÚ­Ëˆ¢¦˜ãåiŠ÷QCbŒ|•ñWG+uV¶I¨ 6]Xõ¼áÀ÷$y…s½b9úÍk:â•9	Zôá2í5ƒ‰Š³ïç™ƒµ'Â¬Á)œÉ¸ÍÅ£MQ_êM.e±t„Q™BYÖ–Z”µÙš‰(6¦¹Q„C„áÃÜŸ÷XMÓ°!FjÜ>áèºÓQÚaØqN¡FÓ<Å/¹yPÿrw*/ë‰Å ¦cÛr¥æ1DiŠTÆõ Rú]#Š¯Ë_"¯®wY] ¡¨Å}Ôì£ğø¸âša e«ôp,J

Àx„œÆáªSdÖÔñÓVˆİ\€~áÂÚÑ£È*
 m<fÂ>6ÿ×&^JØPiÙ/ éÿ®û6¥ëvr `Z‹>:õ*¦³æK^‚v¥uØ[Ã0 gú, L–Qªkr9f“OÔI‡ÕÛ½6*w)(\õC%æ$*jïºËÉòÛ:ƒ/äb“)œÉÉ±EºüCÁ1xX¹QşN£I9½«‰
×şŞê<T¨ÉÌ©+GŞÿI ú	(pÿÜWR9é;VVòáŠ@(f.¹1‰-wÎ<VÂí/
TâmÃh±vVŞ¿3¹}>¶Û.8¬¹,Š#ñ/ä]é yÈŒCÖÚ*-gV‡ŞÇ¢¥+4+¼{;)Š÷–îv¢]2Ç~ª‹ú‰,õÂ~,Œò8dq~ŸlÎ><°|	”?R=åÉmĞ$ÔÑŠ“Ô[ašŸŞ<Œí¡‡íöÕÛtĞÎL² ¬GQõ†¼fã>ó2/¬®Á¨­kxşi¢f}»µôfÖV·<xÚŸW.X#ml·xÖõáÈ³rÓB“å™²»E¤2°²ç¦ò9N@Ñ§Ğ¡ÿş Õæ ùS†Ş¥.H8ícÑÂœ…ÂbÍD•ÀPwb ®(W³~„‚£¸×ÒÇ3]jãêFÿmK¯;ı€@‰Äh†~A¯~§Bè¦…M,&ĞköŞsÁI]rÁ{BêEHÖN<MHÀı+ÆĞÓ’
``°`ÂŒi:cîo³ì–¨„ñÄg·‚çæAqõã—5#¶6÷[I‚±Ô„	[Â5\-lÏ”×¢ÜÕ/CÔôñ­nKÎ!›?øĞ›e)Şõvz1Q ùÁøÑ€#‡´†w€«âñH>ı@OqC ·=yXiglˆ§ŒzÂlªş§k<a=xyŠä‚_C1d!3 ê"-4·Ò«®,ø1¶ÇÆúïSAı‰f~=VwÌh-nŸ·‰¦¡ËËf*š‚œåB4NkÍ°¡×«òÈò•+M£7˜¸OÌÃzŠK@+˜B^Ê`:Î•øûë2yÖìDş“ªÌ%\™mznqbˆÌ¡ò¦lVR#o€
›b#§ÿB™¤¤îÁ÷û{?†£å×{©BÜù*©Œ·‰™òFà ŠÚ’åşeîøÃWoÈë® şö& –Iåµä‡úÕOé®89Ì•ã»º¼Ç¸~ïºiÛ&¢7RĞ^‚İĞjÑ	¶¿¼™…†ÍìaÚ?‡~É±±âÀ®0ºà<[œF`»dƒ[ëJÆ‰÷­í¿d÷1ÿÛL0Ìo±ü¶ ;7]&Ì‘¬ş?
(ÔÙµføØ\—Ü/%%l-™ÙLı·ã•jdZ·†æìæ÷Iò<¤×:İÎ!¹Z¿ˆœˆ÷ô¼ `ö,x,İ´é ‡şÊİ¦(j)z6½´zìÁjkY5Z-Çº&pQxdsà6?½¯®’’ëá×¾šœD{„êaÎ*vH7¬ÁK¯”Õê˜Ü.-¦ ™ç‹!³·ñô) “ì*!^Qø€‡æµ(fşÚ)™Z4¦Løµ}m»µ}'Ç~N”‹¥Eõ*Ü9ÔT°ÏBšhò]BJm¢Ïß]†²£—Òî ç·B¾ï{$T’´5BÙm“fÉ€İğÛ{h(ô¦«Hİòõÿ&Ó±o3˜DLvœ šWÙıNS¶›Ç8ç•ùókf5¦ı4®¾#ƒğåîL§‡îÖiD®l×­‡÷5Ö¦“bV=†ê’n=«â†/ß­•Ëµ;l€¯bÈL#»¢L]§¿€O_Å847¤IÆièŠ%[\—U\J,[Lè¥øÌ%Œ±+°Áï™fğ ‹ĞIøj×½ Y€ì&ˆÁæ-
+Ø»²¿(< aç¤Œ¸çÉ‰-`ûõ¤o#WÀE­,i?Ãµ5ŞÕXz—×Ê„;¯sGy7Z:ı±Ç,Yö0&ÅùÁ¢à‹çAö8+JéáÚ3}üzMë¸f¢·®s¶AÕ?rb$ÖM/8b­šÌ‚pßª(‹Áò¶µ²X5Y«îd°_—«}ky¬‡f¿9&üâHGe
éÜËßşqUx’L~.ï$‚aj`Ybı:9ê-–qÏÅ¼Æ+Ğ`<N„	ºÑR='©åšHÀâJ²¬¬ »=ÈÀ¡ë™$<‰¢v»Ä%\Q®œ‚;ÀCôk,ƒä[ø˜å-[¤V0Ğ`)’|AñoÎ=ş¿³Z„‘€Út4Ÿc.°>”ˆØ.E&]DAéØéêÚ†:I¨f¤BnØùÒJ®bÂœ`›à:ÇâQèûlæàŞ.wôÏ?¶
¥Ş›´‡Â$!®¬;°Mëv³ép±rn»F©‡ÿ5Ğ°Š±µÓ¼ı[y®‚FVŒÂ”5)TŸh¬D€‹6 œ©9v×Wh–¶¨€‚tdäÇM»’¿M
8rDhÍÔívC˜³fÛ„šÎ®!Ÿãi®ò"X>:¬)®”cµw£é?70çÉ«úÃ´ œ7Ü+›lg
-n¿nàLğ–ÿ”}_Ñ,¬İŸs•˜C6n£s†Á-ª:•‹ÀYm20øŸ7ÅÁe]f‚ ÂÄöˆMPÈeš‡…;æŞg¤„ŞĞ£¸Ì0'õï&™Û¯X]Rn<aTTÏs¦WÍ¡Äu±oŒÓ‰·ë»Ùjóå
™ºùàöº§³r@$¹j‡Ó–@¬;œ…N££¢´Qî°½Ş¸ÊÿKZş6Êåz<{¯!Zm¨–~˜Ö“Î îc§#ÍßR§³Uvû&Î­ÜA%®«A¯/|ÜpòGªv\5îvø^Ãû©v†—%÷TZ
ë4D/˜”½ÍQ®¾ŒNo˜¢€9gC‹Ù­¹>[$A°Ò/»u3uÊ¢áQ•È±ÀL†Ùª(êòÍˆ1¨’Vhpp¨¬¹Ã’]œõ	7ÑIŞ§¦í7u}
r.ßÂH€ÔÔÚÁ…½+6¢ş"ŸWtÅ8ƒ6>Í”{›à˜gz ~ì4óˆÇ~‹ê-Gİy0lde\p‰ŠZ›BtÓ¼Ò…Y6Ç¬u~põOÅi¡´%§hñ—-}î>G‹z9ùÓşèêm÷ö“z›"b·„³êyŞÛX
2j¸ÍÕÜjI	š	!»‡ŞàÙ½Õ(¤éÕJzŸÈ.¨*wÜô{AE)¬‡)gåo›şËèÇ_Üİ «¼]M‰N+=hğøN­š@¦ôi–G[õM”ˆ“Ëµ«€–˜ŒÈ‹i‚›2rZÒ8Âê	sÙr‘²Ø.SNæÍjÂvá­ä"@’<d£€^ä_b«[‰¿ûÁÔ7Bá\;d :o814g7©œœĞ$YæE¢s·®g–õ	5V•¥Ş¹Ã£%©µíÖnØğÇ$~†¯ª•°Ã‚˜wìq9™¢+ûëo>Û Ä(‚+@’®1ºi·ÓñÈòĞ}/YGw?¤lĞw¿d¯$Íç Bg;v i²Ï}jµ=[zoˆNE6Z£L¯¯¬uizRBQ«Rqí»Š¤vÓRò°]nÊ«8yÑ–‹¥tşŒÌœ’9‹Ãó¦WmŞªšäRÌVIcÅb^™À*k
I:×J6™E>)¦uõ#†¢İÊšt9õaÆ„1^±­s¯ÇEfÉY=â-ª`Ôc“Ã¥šºÕ ^ş´›{Ô^šÈ’Œ“ì¸ê¦ZÓ5} òše>àUx§Kß:	¸4åƒhæ±öuY©îZÊlPÁM#÷Æ4Ó£"‰*söjÑ;o9³wGĞÔ¦ÙÏØ’Ùëû]Ü$Ü„¦’ÊCMCv#Ä±cµSv\¼÷Ò^ĞfšœÔÜ¿CşÕ/Îfùçƒ(’§ÆˆX×Œİ¬ª(ÖÙ$Áÿ²i(S®~´Ä)ŒîP$&vêtQ!}Ğ°®™àH#>ÈÏ¤åŒ=;ï§ãÜç'1¾Àv?ÔpƒÍ˜{$yû«lia’¥£fRÑ}lñï!/ZìWæB±‚ä½’ï0¼TøXë¸Ä'´<Ar8Ú"„e§Ac e÷aÇâ£à„$ñãZñÇÓÄœ@ƒ(ÔËá4Fb¶A•³Ä"„ä\)”"ò„ë^A^ôÓûÀoz€Ç„Sû’&<n@óár¾î•“G"XÇ\<tÕËš{“·½‘yÕ0÷ø'İé” N(Îîç×W\^˜Ñ£mÇG1ú/²4ÂbRöäß›ˆ®uTŒş('¾NTHZeÖ¯²Xñ7ÉÊª2°Z$¹ë`7ó=vû–pˆàÆË‡oyhà&Å·ƒL—DÅÓ–0T›|Lt‡;´ë¨Á–oÈÚË¬F%)¼QµK'¿ş7!L1iwo İlùS\„µï ÇHŒ>ã
¹ÌÄ·J·i‰‰ÌöòNÕ'…¡¡´§èù ò”	_ó@H¼Àí¥àiEå	·kJdA”lÖ¾©(7°xÀxP¸˜ƒò·ÛP'à!j.åwB!UhEÔ¼¬Ñ|åƒÌ!ìYxôûI¥ª`øê™ö’u™üP±QXç>ç¹ÙuÌÕ¸úÂÈÛIòéyçñêºÑy´YË\ÏUY¡v¾÷]¹¹›şsÉ"S÷“Jäƒ>[ÉŞaà6}xL$C˜sYÁ‰£*)áï¦$İuI2û¥l&¿o³±yV›C
†Ê½Í0
@ˆ–gÜ©‹"@©9U‡y6s´hÑÓhÿ_{p’[zğ À…[„»HêP”«¨‡36É{Ğ´tLœÕëç£·/a©¤b®S ²áU¯ŠÆDğŒê@AŠ"MúÑB]ÚÖù&å¼S-6“<$b?^)7GnTS°ÃSĞÃc ¸Ê?öê?
—éZÈ¦	ny0'9)™Q//ó`¬H£[eÆİD3”Y(÷ã»ß¬DH=4)	¬Ì´„¶«ÀbåMÁ…·ô‰ '—hMˆEÚú;‡±.²Í™¢ıÌ]SúÙÙr‘QÀ\Z„¬°¯1KuÎõp—ÉÔùÏ2—á%«Şš/_,\% ©±Ç/¸a…ê*-Æ:÷¬^´·–nîÊfƒÆ™@­gªª¸ÿ…'ô$Å„É·Ã½ÏQ¥ó†÷kG¨}8nà;¼o6F‘Ï˜ 3¿C\É|•+k<ƒ2éC…ŸÉa¡u\ª4%ÌÑz¤iØšWBF$ ehè8!PWœ>@Æ]¹õ„CWñ²¢˜ ö|1^q(ÓšñmÉ¨a4İyfé³×òÚFÍ8Kúï™Q]•­ú
İÓúÍL‡{/£tñ¶¬â#LÖÎëöa‹ká„9ÚßL4eäÜ4ÅMÙğO‚·7Û¤›ææ«¡´Çn©±õ >l6ŞiĞ‘¨€Zı2ÑÔéŠàaøğ3ß$Y•İ¯(Ø‘@‹ÆæErÄh+ü­ qN¬q¯xÅ¹KrW‰åóª—‹U¯Ée…iÅ[æöLgÎ¡®[_j½ÆãRGÊŸñ-.öÇŸ÷As½TSFxáôæûv >´¬æ3Ä”?tjËÊ–8¶ –Ñ½¼Xb“Ú|‡]ÿ›ÀyÚTÆ’] ¢TŞ¹’=Ô9Y»¡:Ô’„;†g«|s™±FuthÙÀRÍ®¶ÓU8Q™Ë‚´õıÉ¢3âlsÔ©*€€xŒ¤¼-œŞ¦küÔf8â{py$›ô%ÖYÀÙçÙªÃ'@ëFŞpd-éÒĞç~ÜHÊ—ıpèÌÃÏN}bÈmWÛLïã“ÀÂ{¤Wzô*“^¯“i59„a[Ä‡mwÈú‚Â»4ôì¢Üƒ?ŠÂº‘f/Ás’Mˆ-İ0W–¥/–&î’úå
]l(yosï?Cô1BŒ;“ˆqÍJéõU "­cÎ(×%ŒŠÕ›åªçE3µa°¢rYhÆ´5N|Éú¶ÎV®„_…q6ïDéUÉŸÅZ°Ü¢ÇY¥ÖÍTç¸F+ø_LÎ´€–z
:nk2ó`ß¨ÌÃ2÷ŞÒ XÙşe0\-AÀcâ$}˜Å"GåBı–~ÏÚW¨@Ö¦ÒáCöSE:­9è"¡óÜ+Jïôxè}§7'â%ˆ1zú³?ïÏû_û%“VÄGâm9ñ*xí!7Æt¦.İMó”íØFÊ¸‚EÀÉ5…s¦•ø­Şí‡ÂççµzÀ_´ãÈs4‚&Í
Li#ŒÍsr‰4=‰‡"¶¸vt³‰0€ƒ‡Ûúˆ©‰™VœF77¹û]¡uÑÙüúI¥8LÃõ:µÓ8f¹æÓÍü}ÃYÒr~^)È;°« jÅ8nyq¼¨ã™h9`»ÀLIP}£ÈòÉs	»Òš!F+	ˆ^bNŞˆİ(7qÀ&@ÕˆæÁÓÄéG_áü‡[k+‚ÕÈDg®»AF•¬é|puÓºqù¡Î„Úõó1ÔêFeò{ß©L›^˜ìÚÎer”mU³(õX~}ÓÉ\Rõ!½
3¿õ†i¥sUÚYgÓÊOrÅ‰^=¯™ä<{¹"¹ÔôaáhÆÛŞ¨HÑŞKÒë+Ø²°W>Às‡‡7ñˆR£¶qŸ³’‡:`×ü¯¥éé£ÆF#åìv!0ä"ÊYÑ”y|*€@9'u‚éZ”º¸Z—hm‡%âeCáDÛ‚S†N»Å8®sÊj¡j¹½âËk:ÄÇª¯Ÿ½Z§¿aâ Á0U§¢VÃÌ™v»‹;9Ø`Vq\ºIšŠSh³bYdGËg­Ïg™<­fçeBëÏ>Æ>dgBøE +¢3T3i#^í6DOßmòA«‰/+QŠÃDñ¦ˆ]Raß»Å?goŞAPq`¶ÏM$ÿË2†uMj“sN}Ñ™!Ú›‹».’İ<Ô3ÉÚ¶ë'GÎD§¯›Ew“†ósáŠ¾y€ a‚à‘NèTgîøŸB½A€]´Ğ7¿€gc\;İ“¾·g‹Ï<·ìağ˜#'¤®K7A†	~»&Ÿ½f÷Éµ°VœúËßcdÏJx®¤qìÕx<Òt%ê¥)òÎÑ¸ğ ²ƒ'Lˆ\mîÔ!¡~;eeE"ÕùãùŒ»jqŠÊƒ”Š‰•jÂ1Æk—Ğ`-hƒî#·¤-¯K£§1Yù¿Å)F$‡Å&6éÈGœ9ëıeÏïr1q	¾| }¯©VÕïÆ[7ÂmÈz>¼°%„Šåd|ãjLU…–œe¶5pÕ×ïÑ„aéšŠ-çv ğ’Ìí•@‡éÇVà7“ÁR8s=be·è ‰v4‰õ½	´]zÃ/ô¿Šmô=ÉËL%¦2tWÚ~ÖŸ<?l×gV®·™½€¾OAœw6[!¿ËnÂ/ ‰2.#¢·Â¶M9Ë'Éi#«L´p!Pkß´ıJ‡?-~£ÄN¿@t8ë×_ˆ=œœNÑw)µ©¨’Gé4¡µáD÷oØÿA»E~2kc ;Û'f—ˆz<ÔU(Y}ºB<Ó¬õ6HÏcvÆKÕå…š,²ãiÂ…£½äŒÎÌ±“&m}n\J£CÉ>z$ÙÎW¢[ô*6O	öÌ´Âñé2ñ^Î&lõf'"í½ùÂ‚Qò Š"Ò•ÌÇõ?”êfd!ûş¸¬÷>ëFvçÉmªïƒ\óGvç^N„ùIez¢<…ÊùC"j%féZz‹†Ëœ¶Äò> _„s\ÈVhÿXydI+G~ *Tãã™9Á,jŒ¿w~³é$µ&7—ºü“ÂÁBTÀ[ƒC¿½_ÚüS™96ß´;”1jZ\õ?£³úá…‡œ¶1Éø$Ç†{25Q˜=»T1ø¨üâ08Ë\È˜,E„œúÈ¼Aë^Ñı„Œ‚Ûo¿NıY3	ƒ˜¯s„ê}V&àZÿQ€”äÄ áúÇ_iè˜PıÍ$Tì£‚|Có©QˆözŒ-M1™Tèçúø2SM¤ZÖª}İ²%¡#ßûWÊ²Y‚‰L¨‚%É×’fk“-à’R[©¢®?ú¥07Å:%Ùh²æH‡òÇïŒ.Eï@H®cîDÏ_Ç4w’¦ì¬ú"<4‰¨BûŒ6 Ì²†M _«m|(å´ë]dY'Ê^‚%{ÁøÿEÙ±a­JJmÚNB/¹?Œ¿aBÌ(}ƒO¥§mûKÊ’â•
‡Ë˜TP®4x[~¹7”½>C×7°¹×:ĞC±ÈÃ†eÌD±Õ®E~x×h5%
àSÂwAÙTïÓIÁKõ3ÜÕ8ƒÒªK[šíPçpğÎÃ8Âsò-•”ü³×G)‹ßºÉùV·AYseS%ˆÕRÿğ¤-!“öë²ÉfàJÔ(X|‡V:J*~M>SÍî˜ÄØ`õVpÆ‹´ê5%İˆÓNåùÏ“[KlSiM®)X$Ìtf¤ÿ/ŠÊ¡bBH^¸O´3u˜Ql,.î¢´FÔ˜†@âûU*F.›v³ŒåòÈ÷‚âXd÷ï'ë[õšï‰`q™r#—Sàå+ş7ò7’
œ¢-$^¯ˆ»B¥ÉË”Z»0Û•]ÖâuV8hæJ`FxÑêÔó]4Ó¹³†’€–İ+ÎéËG%{µ¯‡”9‹¸üú zwq±úµÿY}oD8SŠW¨:–œ›ipÓ‡ƒrÌO¹¨ÄÁ½ß¯7Å‹ÑæÇä&Fú£äF+_:ğcsÄ8%¢Ğ^iå~y¢ä"{A/<D4Îì®¾Ñ+øKyûóX0‰0·ÙM¾¬}oê)àœvèñY|¿/¹wHZâÜ
å_Í "ö´o‚-S,ÕüÖòÀ
1Ó©ĞÑÉÑÌhk•YËôjI(œ’ÿË¦ÎÉ‰gš}/ë'/XTjDß"Ö¢UTÒÜUå°²Bt<í2œçô"ºhïE²ÏqÔöëTÌßò¼"íz.½p¡|â3ºûĞüßõ@…iç
¯>
`¢N¡Õ}+ƒ}@Ì—×çàk—™Ä©jBËak-‹C7Áâ¯Ò„a~Sg÷ô'†İ7à¨´6è¾Í¨}+ì2A¬‹ ²e¤M–º´6ïüWîæİ,n0öÙ•xÅ'ÙpgËDò¡ê"».^5ÒQÔÇDpå“¯	zç¸€ÓÖ ]Ğ²G_QAŒzı2†²*·c<’&+ÙÊÓ¿nq•ØZ gYùcå°Jòm«“5$OŒ{¥÷JLÄÇ“JÚ®êü{ã!kFr%_K–ı$H:ò÷™é$%©ø×|z†q«!";UR—Y?sô&=.M¸e¸·«½ë„Ìôw(úöFİ¾jßğŞÃÚ&ƒoëpØ…ŠÎ›¡øùí¯È`¬¯P23âŒ¤S"«72/Õ2f×Xiü=ÒPøl";z÷+ìk)ëª”âkÂ=Dâ0j¤íºÒNò/iˆ‚sès9„ï®OÏëÃ–³.º "ôATTÌÌğ Œ—"r¥Ïy}6<“îc¾ç¤)U÷¡I #gÁÀIPÖÔÆlä@PŒkÏxİ3Û	² -Ük>üñ×vğŒp|UWç\ K»T(l|¯DÅûè„Aq­óõd'ıéïP$X,^®Ôµv–Ñ^ã=d¯×ÛÆ ®U*õHş‰Ù€ÚQ×‰|Ç ææ{¬d~XŒ|iÜEIÉ+v+´
`C›mÊs½i^ÂÑŒÔšå"`ùˆÕ6¥Æ9Æ¶µ~ÙY¦lÕm`ØZóQŸ?·ªÉ]Ïw‰cX9ğ¢‰„=¤©!ñ%/•e®™Û\äñŞœr¨îX:àÉ®Ó]á2a¹kQø¸”bñœšsÍ4H¥òü_‚q[àûgŒª%:©•á ;£|ˆ	Å)S‹ê &Ee²]w>dbşªN–cÁde“:S
M·ß½€Mjc˜ık=ÌF @m½IUR¹£Bdnãq¥n©õÌñ4ìıÂ=âşĞ”ùÍl«¸£ÑüCa’Ø‡o„a YÇò/[Gşx?.:€¦ƒEc<YS¼iÜÔ¹àûÈx9¢ÔP:Ñ¿í+œ+ÛøôÕáº# ówâHü%4Äş›·6)ûã½ùuâ€vÿ€~&·è#t"eU¿ZcdÅ‚@Î>ô€bs)±jfİ3²ä¨cvtÀÜIİ‚›ÖQšd:½‚#Cñx“dÇMÄÕ0_õ&‰.6ÑAşå`0Ü„ª<~#ÒÜÛ÷I­ûv¹ª‘âJ¦.‚ ÊÙ>O(.àÚ\5Jv&UÉW|Të ½F.ÄYŒGĞ½£õm]¯L•«@*Í ­R­ÚpşÕyyD_vîñ½DªÉQĞÀĞîØ	İN†·pÿ"ê
öéÔ*5rà•g–Øg ì¯Ò9sU¬~F.£:Âe‹ÇMM"·P«9¸°6°Ò®\G(òÍ;oHvL'¹k‘îÀ‚„ôT©H‡šõŒó›M"«yãÛì |Rl À~Šó~ĞJë‹eü“¤ıŸÛ˜ıfP¦K±|-±“¼j‚VwhQ%,;êè è¢¡ŠÅ~N²¥joqáA©nacÁ_w§”Qn¥U;Ñ/ªóêAjî‹LŞ¬}¤ŞŠlü«Uà0‘îj‹"ÖB­aê¦^ò÷ä—UyûĞŸ©•âÀÎh×Võ ˆ¿ş]µXø>®2ï=ß}¤ëÈú}•ÉL$)9\yØıÕdßŒ"¨g(h_c-¤ë‰QÒ‹íu—ªû™’Î1b•C)ĞZJJA’Âõíë¾JÚ()øt×Å™³Ï½â´‚ç…ó+;ãGôù9ì3	Œ@•»Ÿ§íã…8ÑMş%¬şóH:i¥²j&Ú¡¾Œ=$ƒuÁcÁhu
óv+WÜ»é*Nõù-–gÆàÆ%Aè™éü…ù€k'°«H_>îŒflíUÅm„3Ê¬dexÅ8Y°Tğ&H5Üvk°cvd10	ÿİôÊ¼p_É(ª”Á‰üæ	/Ã™»N•?CŞÖël7#¸†3sµ¦…ãX…$¼×y}ğ4ZHNÃ%b”zÌÄ…th…Gi¢üÿ[-H¢kï£ßxìPæ·Z9oòbP¬¡z]u±\åéjÙ•?‹0YmS0­IĞ‹ıE—kéÈíÚú3Ws5tVM[³˜‘–ß[:!áµ¿*™wèzlÂ
ƒ\ÀàRZTKRD0VÄ!Ç»§f0ga.•áÛ`©Û/¥
V!ÅP¶@¡ñÃáQ²‘qà#[EÏ°‡\Nd)Ïí÷Ùİ	‘#!ÕíÕG~ó7åP®½.Ÿí¶g#–µ}¥ØM~1çib-pÛ;äI1V¯´Pk-Î)ß¶ìæ RD–6	~í6—H}İÿ?—)Çıl\"!®,ÅşVÿ#ñ„R`~S÷C¾ÿø£¡U”àñYB(‰!EİT6Õ)[mñ§K›ª Ç€Õı4*Ôfp°`¾¦Ï—Ï;y·XQ÷X"U=®ú}§6pé}=ÜAé¾Ì?vr½1eñÚÎÊƒ¬‹¦° ÿZÚùvô˜!/12©ô,¾œZ&`»\˜ğœ=ş¬ÀÀ±×ÛfC•âš×áÍ¢ÆÂs=‡Á'/>Êö³„ÍŒë«˜›ÛÔŸgª.NÂHÕÀj¦ˆwA¸L#Zù•4I«ˆÄ¹!nwLÌÓî_àú< ]U87É¼e(6ô&åm7•À›¦UFFÄâ8Ÿ‹x1‡=dİËï%/;RÂ“¼›`L³Ûœ“V]¿{Öq)Ë×{Ñ¤8k*çS ^‡äµ’MüWèQiïiÜA_ÂÈ;A#İûÀù6³ôK,y&ÉTNª,öDØà¦#ü“øI%FVbŠşÒsà$;Æ´¬?Î¬Ü¸|TP¤FÂ_Ê²ã$Òj%Üìå„…­{I¸uŞøıw¯è Œmºÿª-1| ık@BŸíT°x>n„Ú6¬ôbO3³ıÙz¢‹ÎÚ íG	vwïåõm ¬Vk>H´#Šé'}AmSˆg§[ÏbF	T:Ö«ñ=Æ¿6F2	 °üùª‹ùUÂJò¼^*Ïïè*µFÅ@Œ7xç’ı•ûàÈÉıi%şªƒ'Š}ÓªG¹Y‘ù$/û©£§‹İ•Ü0-ıêJüÿ\²rúÒ†P9¬¹aÚ3K©ÒŞPÿ'DÊ	w²‰0ŞxcŞC¡Çnö]Ñ±îÙ˜FCT¦]ìŒ{À‡óÇVivçÍÈ€0xƒbœôÙœÙéîÀ’‹R“AªÃhä³ÃaÔXÁoÑ\7¨€’ª
øéÿl¥¦ëèbåXÈT‚5Ô(r Ã rI"XˆÛ[ùœm_ZñŞéŞ¢¢L÷YGŒP	N½nm(lKã»|ı‹Â—a¯0Zñ5}Z€¦<Ö°;†©oä¡u…ø åe'UÀàºÃ%õØ^œÒv5ë- ;Zå»Ê¥Ø/2m„$nA&‚ ˜£Ô+
…DŞ´Ícún¶ÛØà•Ñş)ªhB\´¬\d™µºø6„|FÖ‘ )qícÎ4ì@¶_·Ş³½ápÉe#NCK#s{¦;!åõ@|Ht‡;×õFO<?uß`É™‰æ7Q'5g7fflÕ×eGhœšöş=êµã„¶Ø’VJ¸T–ì¡
Dô8úÉôÁ4J’<™^3ˆÿ­~ HylÆ¶Î—p ØmüXk?Ø‚;r½‹_'›hÍ{1õIÚëú¶HÛKÀJò=ñ'#lc¬ü?˜˜ +ìœrßõß±Åv´jŒXB¸»‹˜+®SKGİiI¹CnöÂ`TÂC¿ÊŞo1&VÈë'?ŠóG ~2ë?ÊJ¿£Z+šz›d#˜Ñ+‹`113 %NŸ­üã™l§Æ´Œ—µ"ÓCceà±-b…bjús¦æªJæx›zé§iA„-İ,Jl9¨fdP^I5Ã¢‚ô»ug§/Ô .eG¶€¡ÌàLt©6!FÀCˆÄã~›V½<3æ¾ hTdåùê	UsŞ°¯«ñIä3ñèÈİ®Å¾j`ëİ“µÌe-»2¦:'Ü©ıD¯JÏ5÷gƒ;—“­e‰PgO’Ÿ¬ûö o‹¡ÕÃoÆˆ@åVLeQ3«NÍŠyÛµõGh¯¦~Ë.øûQÀœIè³€u£÷“aÅRIÖªË ³<Ô†Ieh†MlR£.Ip·zR[¹Ø3r%>äÍEdÅ4{Æ*‚˜¨"‚^“]…s Í :5–5¶Åƒäc¡i€Ğ#k	€.ºBXà¦¶ô"¨âK·f¿©Y¶Æ]ôŠrWëVÍ”P…îKğÏgàÀ¯ïë	Äáõ?aZ©ÕûÑoXDú)ìøM¶#Êy>ˆ¥Faû
YÀ@5+û¬dH¾²ÚùÎ
J£%àİ¢9}¸85DŠã\ñ2ÕóÕNdœı½÷·ğï9N_öÔìÄ…¯?b|Îá/ØüpÎx2ÓÀ23 j72õAãÈÀ1Ùß¤P„;ß$ØGSD‰K·QÒˆù¿à3•şB–™ª`ñ—J)lªô†?²¶´Â”ŸCoÎr2”ä?8ÙOşl,Ü2òqK×œ$áè¢İúq}£ëÒúOÍçšf|­D˜ŒÖ­m8¿ƒDËåìµ8Â¬o>˜†'‹N
}€¥è+¯Èf’]<ª³F)/ûìøsŞ\‘ïìújï?®È±iH®l(˜~1s¡˜v>µF$R¤Ğ‘qÔ´Óc„Ï¤–0âóò•¯(R09TÔüú,l3ÎO´Èél+Z‹Ò³óeSòA˜†ˆbŞXŸ$/ƒ%	îJÅ[l”Á–Š_#O‚ÀG™.£áÑ¯¨_`æª£+]_’F‡^O\bĞi©ãË28›FfÑœÎ«„} ƒ¡®çö0|É tùÀ±qóÂÁÇ©øÑORds™ù;ŞåÚ‹86Jl•±Öò…±ã÷6€­ˆsxóòª=}Æ<'õÓ&ğâ‡”5+| =Yİ—AÍùŞ¤ê-ç<Q.¶|Ëh×{´7éeG‰¶uP~4Å»pö€ïæ¦ŠVwºÀMÏøUÊÚ7‡•¢Y0t|K*(R‚›g¬ĞIÑ&^Æİ)³Æâ„6²nQÜ‹Äº(nsœí<biË1Uj
#BÔg‹É ı¥Ñà§[Eì.¦Š¸vQ°µ4ßÙØœá»p0ŞmÊ›M€åœçE#„ôÅ­7ãğ[bHîÅÔŒn»†¹µ]»˜™m+\—‰ùªTêşÎ
IrÇ|ojãŠèİşÈË'w-âX¾ùïI¯Ñ6ºxKƒ,V^oÌšc¨®!;p7J¿‰5ë›BçV¤áfÄ`4Èkø.‹R”‹T›z­>ê5ˆº‰Şp›¶Oa[¸gô½LSÀÎeiv˜kvŞ½Ã¸7ºº¬˜¿dæÎÅ3ÈÁøo¼ë79[¶DÂ\r]DÍÉ¸c?ûQÙ¾ë“=+y;ÉCãİ+4ôd>wêU¼Ô7Ïà¦¾„l‡‘É¬	ë¾HÄ-·ÜçBÌˆ-‚\snÊPÎ:Íã˜³!Yh8Öedpƒ¢–z‰ñò7u ÷ë—³:¨R¿][ÈşZ¦½d.ÙÂxœôk™Mï*åß°Ò¿Ğ_ê‰ïŸŞY/ÆÎ«3JäY(Q®æLÏ´05ıñD8$Ğ¼‹Èx½"U×Òk„ÄEÅqÌ²X“üøô&+ÔN|(´íºŒÕ Ó¥™õÑ8ÖRÕâ¶€ ³X•äM~0nï8ÚôEŞPıÑ	¿<X6ëÖ·5œ÷›Ô^İ$Ø¸Ì;=¢Q‘6šÿû•là+5†‚@o–ï¤à&¸SíÃ“£›<‹K”~õºôĞ•ašD1Ì¬xÊé¬´ºá)+ø †w,JHª/ÿ:Øì²»äš†ı©íÕ1®¤€Ô„*Ú>ü^N3µ+Õj™Ø»ög}õ°I
-‘]2G×J0“§F‘‘ÇØşM5\JÍáëñûYLPD¬>E—Êù|Ì¼$Yk@&h0úÉ½eåIñØ­
¿ßfx’v½ªıiiö~Àƒï<¡çú¾®çIììGKÚ÷´B{ T
¤»:fêa›è1l[~ô…Ú2°¦g¥éO—YÔ)Œ Ÿ%êğòŸÃ™X(_åîùTç‰»ó7è—	ûJ®¿P.$¿]r‚÷ÁÖcK4qm<c¶Ú*/; öö…§=û¹0¨C?Úe°Öu1pˆÍ
.øêØÿ£g*FÀ\6ŠÁ—ÏÜGfÛ,N¶@ëtÑ²é4Ï³â”
ÑÚPÇ6Ö1ºeeÕ¦$õó¸7¡
ê+Ï¦jÛ çš/OaKß+ITª‘ÛÏ»X„wIÔÌ†ş¼õL„_‰—'Ş¬œEĞ9ù0ŞdU†åêÕç­×â tÿN—ä1°ƒ„€ÊhPKıöÅÍ=V?9…³¶¶ù'r|ñUØ_ÕËF¥Gn1TEQ^½$cÇ›æÀwÊÔÁè…±ó=P#Dÿ°åA_ÈrïwjpŠ¶†š,f¦%vüñ³.è|¶î°Ÿ#Q„ÃÓ+‰ƒY¥â…„
¯“G¿*%ÄÄGì¹†›sÒÎÍîá…#–°ıY…ñØr©juM£Ò1#GõTg
C{aG¶½Ü	¬¢¶Ï5€´§ Î´ó×õ?9)I¡“^; É-%¾$„Q\xäî‹RŒL×€Tô}¡îo‡ÍŠ^p~çÇfÇïcÛ"äÜJ×ˆî=a‘‘ÓŒÌ -ÅóÃ[D|.gŞ*§¦ÿ²óã·x0X»’GÍİı=7RÙ …1ğ°^"4-Z£³+¥Ç©X6&bê¿•Ææ ÊÅÍÕ£9hS¯68lÛkG>%áP¹B¦[‚swLÀ^¹{øëÂ@‚bÓGÅ¤K.O’f`o­8¼ƒôÂNöv»¨Ò,ÀrAöxâE3kFFÀÌC‰çfEèéƒ|!o/İÁJæ£óZ4òô%…‡VeM9º€V[Ø^§!2=ÓßGõLÅû9&ÉöĞüTYE¢e#Ch=h HŞOíFWvÙ!x€DÖRºQú‡TÖgÖTy(À4GáÉ·ôıÙà‡º·;æ¹]†¤9M
¸ÛµóxÕğ¸0AqÙ7]Š©É¹v$øÕ®b§<¬Fİë>üDWL·4L ù¢ÎI®;‡·Çf¹`¡£÷™ø"n<ş#–½˜´Ò´¸§HŒ7ƒ\»¦‚–…n8\ï]Ë’Ã÷ßÜÖ~’Ç|‡U“"y}(UÄêó¶şgÄb8õ¬¸öˆØü„ÌÆ˜O(q
ŸT&À³6ÙMû}b¦üüôĞ¦°,
QÚéğÚÌ¿%,\ÍÌ0ØŸ7õ–@`föÖãgÃ~‘—F2’Œ|-ïù^ŠšrƒqÊ³TìiHa±ó§iÈòCKˆ8Í&¤5	Âs1+×…=¸’»qœ&µ3g=™†‡l4N½ª–°níCo.Œ‡7)~4Ğ~I´
Ÿ´4¥î¡ÄÑä’ËÌíjõÆ®W·Iˆ`YÈ¹	UGW:Çœ1ÍŞ‡‚QŒŸĞÿ@|¥É*ûM£	D|¾Í¹UÓÓºÕ;(dÈ3š6'Ng†ÚúØpu@a®5¹uX·ì˜×ö}ÎÍ¤Ë­®„œo'İ+ë°s5H£ép—İ;ÏLÂ1ŞÑ5£_Ê)™}rØ-”qNk@/>L©2Ì·æv_î¸E*û¶òß?‰¥$ ½¡\8ºã\ò|SyËgI¤™eåCIİ9ğu¼¦âÂHË±ú8ÆZ†×K¥ØWà}c¿¸*RwT ß(¸şB9[‘`3q<§@S
9Âw…â4–9®/îğa%hDc¢m³½êu
‰xV–§!@Ônœèk¢Ôn?™³H†ØIñŞ0ğz´´1Lvè½–YÀ'#[íğ“ã/tB+yÙy™÷Øù$íÄô¹*{ÏƒD×›,~åb£ÃÒdCÚ=F$Ôq^µ “áÉVJ´Ì¹0ƒo	›ŒõpmWêc.ËÛÀ|;ËjPÿ8LXÉö
\{ò±Ø~BßsoæÙ»Ò£®T3·¿Hº­º³TÕ¨wµm†“7F'´sç4É‘qpşö<j+ÕQ‹%¹×eÛĞ´hä³÷]ªÉ€àm»/43ÿ¶µÌµÉ¤öNÅ¸ğŸpfÊÓ»àEî},Z;v8Í›$g¡ÙOfÕ/8Î¯?ôLL©Á¬ŠòN4Œ{ñ®ĞÜS‹ÎÍ¾#q©{Çgü,uªıxœŒT¡e6ÄîLLHSJSî{	R…§¨
Éÿn‘ÙÛÏQ`º'£äbP<—ÀVÉZJEœs»Òèl	~y³ôÙÙÕ$óy°ö§›·²™­r;F><s13İÍ˜ …/×í®}ÔÎişøl”}&±_:µ%uçåñÃ¯UpïM•uÎ"*œ¹3¿ªÆM˜Êqj"MÂ¶„Ú[œÔ¬î$ï{ iTuCBÑê¾QS´F;&£Ô^ÙÓß%Ù>CÏNƒ×ól‹A†HÂTf?‚œñ@®ãoÄ?Ùl·"@æh¼<µ¯¤)µ°®l{ª¯Àp”Ù’=~Mn·?ÑS«Í_U	‹UZ‡§3ÖGÒÖ#¼B¸‡è4÷\o˜E†U±‹´|•L"rÄX¸—M¶Ü¯8D¬,ÑRHÏzeƒâÃcßG·§”Ò@J1ølì°5å=&Ißïãè í¯O8©:bè2«¤w±]ÎçHF#—]	p˜Ò	„ß+‘_CšaL4	 ™&MÊüaÀáŠfL\ş6¸
ğ ñX}©·@fY²ÿHfÄC7f’ÕÀÃi—;{Gyre]Qx>ŸüúÕSúéÙdçÓŸÄ B¾Øó£Úí·Ö]2/§™»³:À–ĞH‘
Ì@õA<±Ğ¹ÜêãÔ”ˆ‹·¤H½Ï¸Ëœ4$ìM6Ë˜´~?¢H*‘›ø{·–Æ&dG-_2öëÉWÉ^,¡+¡ê¤1_Ôa7¬í¨ŞÒÅ>²6·cÚ³…¿­ÚªXi¿áÒn‚â‚‰‹8’¦ı@_øöÒÜv5p9£ºpûM®•ç×ÕìËÌ®Ï=ªæú%‚A´›W¦GXÁşİêAàçä¼n+îÿ3q=—‘ş¼À`¯Ch•ƒ¤ ÖPI(˜yˆP¯¤(À÷Kÿ÷î×]ÿªï÷d£\·İ)=ÿóØ+° 9ØyÎ'ß&\O'¨2—<`(l<ôÉ¶°Ë’9cn>ÿuL¹+p°‚–µ;¾V?›ŸÈöS3Ê0;˜ú~äB`*´~®:3–(àµ¥“¹ÀÒãˆVñ;¸D«ÔYPM‡éC€e¡uŞko¶ IéywÖ9óKÚ9°yéî%õº 
 Ò(ØuÓm/8{¢ÕhÔBé_È².ïÒ9s/Ë®Ãğu1¹@a´…†¡œô›(‰DŠ•|Ì€2šnM=¬±ïX9÷±¹ AÂ)Q'›ºv.x3Ô—5h2»/Ò)¯½£-3¸¾ïã ¨£şû}÷TZpÂ‡xàaöR¥3Òğwü‡ÿbZ{ÂÃÊ ¾!~–ùbÍG .?ã\Cœâ–éHÆ¡ÿ[&$ˆFí¬3–ºÚ¶¨7»ïÓòD4v=ŸB@ &¢æ	/HĞ[ğ5¤J`OìÇ`‚>|«¥#`´hºÕH¯@KkŠa@@Kc0×S-[0^>N2$!r¶Û¦]‰@âXôƒAwIy™Åà†ÏUŒñÇŸƒmÍÓD¯s×9ÇQ‚YA§ò`[ƒ‹ü´æX˜UT†¼âÈhÅ€CáASsğıfÍ¼Ñ³~I3ª¥I‹€ËÿšÇ¬é÷…l€î¦uagØíàº©}Zƒ©Ü/û^`˜S*h/d!şûgƒø(¹Ë=¬FDdîLEÜ¾ê‘¿	¼54Û‚´JR{ÿDU JœúÉ2¬7Òîy´é’Ì™|]´•f=CÍŠ»›Iu†û	Ái ÄÊ×£ÉIgÇÍ+í‰[ÀˆgVfaÄT¥ï'c«Dnµ 0Z”,Fs×CÇZæÎ­¹-K–¡}…5Ä@TMúÈèñÆ—wyƒw·Rq¡¨zÏq†Da•æÏœ<ïöá,šÇø\çºí©ùÑ<G²aD'PÃ2•ˆA$¹_( z]¢ÇV‹íSg;U)š1}šÕ(Äİ;Å´´†ÿ:¢€|s@¢s¿‘sï1ZšÉ½S$,ZYˆÜ²^Íç’CÕò9ÿk®î{ vE½Ÿ¤t™çråÉ}šo!Ò36×¸ÂŸYkËµÿ¹¾À}íZt¿®ëºñÎ™zHCÂı½¶N–Ò>ÜòâÔ›B6»;¥×E@ÖŒ;´«Í……†¯å‘3MüÏìä²û¶;*±A`ÂûD5s›à£OAåõ¼µÓ,B b¿ï#ááˆ£ <½¹¡ì¢¿Í«Ã‘ÒÍ¡ 'n½u‰A&DÁ)*:gÑ.êŒ‘Å>9ÛÒÆC‹‡ÁÔ\[gÈâ6µ¦‚#şŠ¯ ¤Èª¥•.i ØåÓWt4UÇ×²P5µ#ixgøw“=ªK‰$ÿ°À+¿a°ó¢øMÂª\ütT}óOğ:jˆÓÈ¬.Ê[Øº
Ä&®ø—x²&Ò1Qı¹¢Ùœ€Ñ™a«@ŞÁQ.P<æ´bšz‹ek"I5+w`Ìn«|)Ï›ã3µh×2ÉHŒ%öˆÂIäênÃ¦şåS *6‚¼Ù‰ÇVc¬y.4ËÔ¬p€šâĞ!-¾¨ï¶cIÕ
I?¡\n+ãúÓÑÙêñ+•ÃîÕ‡¤ì÷…ü? mvß>ƒ§“ÜÛk+ÒH¯ıÍÎšbüuúy¶Ã>ë9I;€‡m¾ûğg™[f¼â¹¸Ù`Š Ì6±cN€¢õ¤ÿ~Ôôœ$ñj¹.œU5woÅvà„^l¶ÍSâŞîÙü;·nòáˆGøÅ|Ç+¤P.É&yğZ]ó€¤Vötö4ê¬'J¼1vLKcäiiŸø5ĞÁÀ£':Å…™¶¤šƒ1š?¾­\èÚ÷„¾ş^N½£Ô»7Æı	'PÇ€JGŸma×[¹³7%ô/)¿CF‰tÅ~UgÒ<LG7¼f±óŒÙ©
å¿fàB4/ù»î¡E6Iwt¡Zt®.Ş‚ müï¥õÁ¶®Ã×5§É7æşŠ–›Ø¸Ø
@ìHbÍM” x<¾Òa?Rj*®ÍNf]ûÍ¥9[İÇ|Â$Ûñ¨®fñ>äæŒS¦š$×¢—¥XVH°;¿(Tï³J½ÉÈéQ…Õ‡mŞë=_JÑ"æŒ«ƒé)XFü¹ÒsXó`GP~~ù6›«ıv“ËK¦¾Ÿ}É–ac¬»Ä[«ÑhÂNÏXƒxû¸®n‚ö6 F½]€ë(¯ùmQéæç¤!$ÍAt3@l/g|rı¦?Ñ¶½àÏ©ª1öµn¢ûàz¼7ùı!İ\èÍŒ£¢»¢ÈNêY*}uFÓ¾å<É.½½õ‚O2ä¹X2‡"îú%1u;#>iCéEl¢~eí’’ Q;^À:]Ôúg•9zÃêeõpúÍı“®VÜ–šg2ë¨¥ê+ş‰üÖ“£{ùèé9- _B8øÄuılÒqÆYíK€#‘NåÃÑ`>ŠæfKäw\òAÓßaô\ëîóGós"ÕŒûR…9äè<8._ø)ÛÀã¯¿“/‘(ª2’õu[J¤(/*¨¨M¿
Aî©Ëm˜7i$‰ÜfF	S²úH!o&Øá˜âU)UĞˆËn4;¤?)u‹¬¬«Á[ïaóiÛ—dr4‘Ä¬‘×~ÕIÏ¥  vøvIWE—ª÷®òğWúÜN]Ààkä6*¸A“ı½@îŸJÚ`$£8 ¬é>”™®ÂD°Oÿjo®QÚ çQ¤A9ñeóòä™ó„şMÏlô„p|=ÂD¯ù½º>Gg—çÓM=m o(Â6oà¾lª-‘)‹Ş9×Ùã½fÀ…Ìõ­¬ød-'ÔY³Èê["oÇèÜoØ(•3÷>M~Ö¶l“¨Áı}¥yoÒó¤ó€–x¾S¾<®İ\§ÙÖ¶Éë9Lóä£9¥¼–Í2İW¨¶ö¥¬õï	İÒË1Ÿ–8ˆã&VÎE©û=İëÒŸòV¥ŒŠ–•9.®§gM4ù×Ğ ç¯ÆÉÀîîD`¼ †·™¾€1ƒ¬Ñø–ÏW…aù¢´ÌºÕÚş_¢•8—;‹{CliÒè5Ù*öo¸cxµ|SVßßÅS€+HWJºcn†#Í	ì¤İ0¯ pm•†MÆ½ƒÒÇ‡{nŒi¯àÖÃÎÂ	xƒ]ÒªE© ±‡"–ô[¤ôq%S°pB™_%iÖğ÷ğø,m¡#±ªè§£pÒÄÃÚJòEKÌ÷X´¥ä-š4Û=)=iDÍZ²ĞäKBÂpH~‰[è®	j›ÒÙJñÓ8Í”©(Ü†¹,5&øg%WÙU'9Èz¼ëçqåvKG÷ñokåp¸koÒÜ¿ŒãåÙ±Ò±·÷1~²ƒiÍ¬^îÜúÇ˜è>¥B³:>ğÂ¥Fy‹ˆ7üÈä–f4ª¿àÊqğğİ<véàFR( ¦×wsÓ¿[†Ó³FËZ”óãÕÛÿô~Î­>2gaø¾íÜÉæU‰gİº§´vÒ‚¸+,Ã3ü¼x½È39U¡Gõ²©BıN‚ğjXL®u¸zƒƒÓŞØVÚƒ.¡rõêX—íˆPBÌÕ|Ã—%âİäzäbDK>hÏH‚J09¸ôX{@·c¨ŸB;Wİd™0¸³şê¯ÇsøgŠ_I¿Ş(¾ï†È§7-7†Í:Öúìkç2òûwÎ×2‘_÷_»Ep(à›Úç‰œßşï©´Û#JxHm‰‘ £rM¹ÆL¨	-«µa‰Ï«K$1+û“d…È\ ÃèNãĞ¡pØ‹o<²tæìàµbvŞ\Êdë~¿P ñ,®ä‰Şc¸SFpûÏQáŒoÅÄ\jh=‚^5Á4;£òªÜö3f÷	t:µõŸXÕVaôPÀdcÄ?z˜«Á:BCçfas5Ãô"~F8’4Q«Ø†Ÿ@O††©‚Ç†œ`¬d÷,|¾üÜà>j6d{d*NRM.tİÄ<"hTœ[Òİ£~?• ø¾j(u _Këu§cÜäô(¿æø[[E]ëoÅÈ6xfõ¢í¤Ì<ÚHl·îX‡Üè)°£°b?¸Í-Õ%¸O¢ñÅo5: [»Õ´Õ–#²Ì#ô®Ê–‡¿ŞMçøjQdBÍp	+¥%5äw&•ıŸ=ğ}>L0dó^œ¢tEzÔ²ú÷~YW•Ío:â>UÂ	ÏÊ¨Ô/›äSéáRñ|¦'ö$ÈõrD?ÁI:ûµñ «S„è¿l–JH­
Ë*Ô–rô}Z^ö‚ìt3ME'c÷Aw“d[KfË*Û®ßwâŠ˜/HUıD[2òûñ_ö|ÑôvÜ-gËJè5µÑëı–6Ê±rr`Cñ]A *¨Ç•¸àçX@I?"ÀêŞl×6¹Äî±å¡•*(Ä‰ä{L„¹×€cjÍäc¡7¿c­¾ğ3rç–Ì¨ÁÉşÄ’Zú#\/{¢Ã˜îÍ|%¯ığ¡£o®œË5ÎÜÒt}{fQ°,r'ä±®\G¯Ô‰ÆÕµÉ!#cCôL"?Üa2pöºæÚzM±„ùı•í£üSœbG+LışkMĞ´0cµ…|³qA} ª$×È£Qæ+™Y)§‡Vù^:6å©ïKj+è'’NX#IR.P%·ú•Øeõ>¹´D7T¯Ö™z}>ñ<7Æ[Rpÿ)Ú÷í—;+µêwÔmÅ‰YğÜ&j¢æVÏ3çÒ {ÿ¾«uB²İu-©•×´p1†Qéu<ß{ø=>½h¸·œjğx¤^W²¿]J`)
¡™…´¿Í:½/WÅ`ß=^º˜]<»µû:mW3×y“,C¸83n\LëWçöK§‹ U0O‹®Îwuu)RåG„‰Ã{d¥ÉqšDûø$«¬É˜.˜‡Œ¼#mg%e¬¢…ƒÍ³OkÒ»IÇÚ®ùãpªş5Ì”É
²œ³Vd‘T¯;¥ß¢“º;‰¦J»åN“‰aáY˜YfyJÒ4dè3:®n%×“¿xq-Ìïµ«ˆ{µš7½ü˜oÁtûã¯ÜòC›h[¹Ú‡ÚÈ„[¬Ş}TEæşX¾ù´œ¤~\rÙ£h¦YŸ5İb¬ÌjÒšğ«áïóRÛ·›nœ)s–Õ3çíŠÎjgé"ùxë©‘8)t±bˆ8òvª”4ÜIoËÑ¦›œ×‚*?RÕÅ£s¥8ÿX²ë2Tì)´‹@œl6‡P)'û*—(G=Úi{V%¬ŒyÓ–åË)’N/7À»sÿW9™ÏúÃ2İ_áI’‚ğ*(›¸RõÕr>'‰:Û(“¥¼NÌÀŠıõÎ>³î"Té„å¶O•@‰
…Š	µ(yà<FuNÊW&,Éö†|îñQñÓìûœê7z²òb“2ûf¾[pT‡÷÷ÙÕ–KbÌ×³“¶/<àFoânB6š9Ê¯¦É÷å_x•w6n¶ôEï®D…Âø»~]İ®YA»:Lu+Rr×Ôñ^Za(€ze ÒŒL}á[Œ~'»ÜÀƒàÓé=Ák’›¬Mß`8ŠİÓ_—éy_÷Ã3MMpÃNÒ{o°:qìruTº]ğ{Üû~_p ;ÔÅâodè$@ÕP`s¸”ÂĞ3qËeÁ“3Å=†Iè$àèMëv–3r=¶®»eÕ:å Mís—0º×Â×­w—!ısöT)W9–×¦AÇûM½ll`­„c{cqJ ÔY¢O3SaÕÿ‰9®Štiı³g›ØZ‹ZpÙŒs-ŸÕİ+^9ƒl“|Õ—¥yµ¬Œ6Tù>WxPD9ô¶õTşûè\Í4‡‹5û§|ºùı•°NoËLTãã¾°É™ÃÂ$Éw¦ ƒåX/ÆšTş;äš¨”G—B™€MÆ*¿ZèÓV¶f<ã#Ş˜°ß©1Ú&k	%ÄBóë„&„{¼æû-p4ÉvÒ— ÛEŠKµ	`u9óš»0¤k;I=uZ7v‹µ$6Áš>âçK”²´·İ·ähÌ`|‚pS•ïHÜOÙ|ØÖée«ü#‰©À{´5u°Õòì´ê&	Dº†/)X†PsõD€­,®pÈô¥›¬Œ(hI”1“|Y§§wDòu3pœÄ[Öô¡ t}óSÕOZ´½Í7%ñ³­b·lükä»şA‡Â+ü#;Ø]c¡Ä	ª»SZî×7¶æ`’+¥æ%û°=f9qÄ%, ‚š´CaÂ[ÀŞ!ûË±ïHÓFŸ×Ğèy¦u’‚¹1^,äy>#¶ˆĞhÔ¥ÉrüÔFeúù] uS.i¸éEŸ5©g‹;lGOa‹¦úƒu?Vc4Ö÷¹–®Jâg¤Q£[Ş”¤Û·E7¹éO÷»44ûöØĞ×±cãs¨Ñ¤Ù˜h,÷D&ç§@ËxlÀM=^ÂT-™Ş*[ÌµMÛ›ÏˆÕÌ•b=¾É…Nİ´^¤C~±¾1ùGõ²Ph\w²Æ’54ü*c?W*»
ÉZ°o+8Ü"¸»œ¥|ÈF…âÙ“h©Y÷§zù"5AxĞ¨Å`FñïKÖ7Æ@às^Åa±Gš›Ùctÿjbúl’ÑÌ!íw.|>{«üö3Ÿ;#-©ÌÜ½Û‡j¾û°Á+®©uÿ5’÷õ£g÷\şdØ.îrÉBÏì®¡2è¡M-}È'Å ¬lÍ¤ºË³ó)L(ËFxƒö~Š¢%kI”úc$÷HÒÄAÊVˆt”“Ğ¸òB{ÜUÀÑZ²´#C&°ı¾tšğëlÉ .; ~%$+ï’¯Ÿï2g7[GÙUäÛÂşèæÿ(—ÍöşŞQ·ËL$»€Í6ºù(–†æı®Æ K1Y!Ì‚Nï•GÉvV»y®»ÍÙ7‹H}jäÛş•FÉ)Òã¼œ¹#Äô$«Ú0Å­¿­÷›Í	dl z3¨ÄÏ¡`L›F›3şmê¤îÄceƒ¬Ë2Ü¶c„¡¸©Òx“®º—<,rìODÂ,,Çè›ï8kØKğÍ{ÊCM¬N?)5s®Ş×ôÉ¤9díL[ÌªôÏT=0FvÁA©uûÄR'újÜ;fìoAd…K3®,¿^À"G¿Äû8I¯“ÖŠ%°é+Ó´¸N>=ì_„ö–¥Ñ»ñH$ù2Û€õù;ÓB6ü‰.Eºí4z»tÑ—ò†³õ¿ÿıxË8#·óbİ•åtZ`hÍ³+¨C&›±òuß¾`VjÀ®ı#©Ì†„ıqÆ¾¢s
ZÑl1H(ìÁò*a“;ş©$ıˆ`ˆ‡–UéÕàXÎZø‘]îT“À[¢èe´)òÛDñf³v›¨™Á¡]Fúğšm<O-iCA~[ZplâÄ‹\¾fÉ8ålÇ÷¦j°©<§^“¥ÅúäˆµÃoûè’Àh0kÑs€É8ğÌ4…FuıYU+Ñğ² Ñvä6@°xCä“†_ÉC3bè ˆ‰dÜ@XÇ-3ØÀoC3b%Šú+8¡öQ•0ÖóàÈ]#H¿ğ£¾Ò÷»Fû¥óéãYUf<È»ÅÀ/‡Â%^ÛS4¯jÇ[ã;‰ ákÄƒ¢Höãá§­«¦òE°OLÉ¸½9ƒÛQà ¦Ä]ç·í|÷Õ±'1iP½áxİSO"B‘,ŞŞÚ# í*T„y^êµğ”33~L¿ó¬O ”ĞŞø§û'Íõ˜Ìü5êqºİòPö$F’[©Éñõ÷Ñ
œ.+›íT!èR›Sr•4°<p÷FyS#XÚRğ<‡µ¢*ã”úÏÉ&z:"»áÕã¸w>‰ hJ<ó6ÇtKX}`êT•z_é½@¦2œUä”ğ\„»‚ş@E'MYİşšâKyj_Ã0/Ô¢‡–@ƒ¼OjZùÜ	÷d5“M³g«G[¦Ğn
bîìƒÕ5'¬;Íœ’måú$;±[ª‡\¤@­X(Ã'û™6Õ“„Óìƒ3¹´ Ğ	®Gğ\ø¿Êîã”*uøŸ–‘ÚUë–èšt¡ä©Lm>8ÃÇP‚gÆ©†ï#%SjW2jQqukÇWï”ãñNáÊ2Ï¶å(*çGAæÁÑvn4"p›£C‰ e±ËaĞ	úÏœê8“}
ıÇL°YÄCÔ5Î ÿSãEgÙˆª÷ª•Í>Æ2P‰Ô+ƒm–ˆÒ#…TY/ÚOúpZól/İØˆZ­!ÛÁ3/”üÅĞê4Na4AÖ—$I¶òè 7›FyG…¢ÄuuÇœ9Eë‚o¢æ3«-aÄrØÄ»ÈçÜZÓ)‘6`ßÈFô™ævyä2¿æìaÒÉºş·3."äAú±»½NŞ´²?)‰c{BpíÍÚ³ƒJô).Ó2b5UÌşK\3lŒ@RäD|¢Tf%ñXââ‡•aIÄøR
1\WC?uˆD®¹3ÊöÔ€Q¥Oÿ‚k"R'3¯Á}Ÿ/DYïÂX€(­7¥­1ßs3mŞß¯]ºİ¡p96”AyUgEE·;Ï°ª\KWcï;Š[Ûlò0ƒúÎ£Àh›ù7"1ÈÍ÷"n­†^ER|‰İF6‰²„lÓaá-;‰b…úÄw`~A	CEdQŠßî³ñ"­k«üæcdåÊ!Ç«Mëak¥d›ÿf¬Ğƒú¤N°ÚÁt/GT¬1oÎ #¯	ºJè=	Z)F @.tI¯Ö†Şà2æÍIwˆFrª¡Yç€šõNÔËpİràø›Î</%(ı¸©Ãp2¬UI¹,¬İ6!!Ôhoe«Å®àiÏ{ù"—C}|KÊ;‚Ëó3DâÿËh{úOâ|ÑFM‘Aç$õü%Š".6î¬È'°àıÑÍ]Ã¨3m[½CÛ|‰Î¦šßn~«öbrƒu$eÎıÒ_ğ:…á°ëq‡»sgàÑ‰^¼[^/,è4z¸}¥=ïc!UÖÇº'nTú‰&¾«2Yó?#‹î¼Là…ô–ëÿ˜bŒ£¤s…İFàÉmºw¡s%sMèH²ÏÕvU¼:´:uï{½M¼ßIP%N]„Õï<FñfÎÜ¦/uß0ßõP<;·28Aâÿ]›XÃdâ{ZX.±„Õl›?ÆÑ“§¤²'ß“4å‘C°¤;/]‹¡šLè"SºNzúÿÀ‰éö'VNÍ¶
øæ¦E|ƒGÀÒ\_ˆa‹.÷x§ôúlÜ:$T~!±¤6-™“Õ¿õo‚vƒ(ê]î™HÌV€,”ÓuèœJn˜Óñ˜$ª‚¸ù:óğŒeF!¦tÕğ¶O+æûéC"u‰ëôUŠÀ5\cdHQælAùÁ°ÇÏŒËù[@ÙíÓ@Èöo~åğ4Tv)GØdhX€Uî8¹–àø"ê¶ÄTÌÓvÍz›%øÚhÒ ^0ü°ıéñÚ€‡×M›{%mG	Ó³Ôíz¥_$­…/ğ’ìÂ¬Z 5İá9ÑsdÆÀ®2—®nÊĞ¼±ig"„å»h`ÚŸş:uu×†‚òcàÔPĞóéH/Ÿ{6Á2j"!¦¦zÃìºü
@w!~ù—š|#¬º{ p¾²ÑFÉ*bñÓS°Ì»3„K‘Enû2e‰bép£|Ã/ïsÂËfŞb€K"×»ö(£M±(Şo†œß¸±·0/gJ_·Ù_pŞˆ“|˜)=¯›øJ‹‹(aKÓVtêî+\ıq3®,|ã{éµİşõ»œÊ¨”'¦¶ØúÃÉâ5VÿzP ÁÃI_Ï|yF×µşw¼oä¯ÆU
Û¾V¾ı!bŠ—PÎ‚è‘[í¾YíJ…•N[NîgQ0®£…[¶l…É«ÔE4ØCâ-¢yëËÎ‹¡ç@°ÏĞ
öR.æÿŠÙÍcOXİñ›=n7ğüjäœ tJÇ7.¼\BÚY_¥îaº€¤óüu –x@@>éÏ „ƒ®Üf=¨*Ã÷ÎQ…Ø‡&€]î5‰ı\’HäJë°š°,Ã{§¤\Ì‰‰nÍ¡èuˆ|¯)¯’+T®ğlÜR•Ij’Ã#V<÷d+6ìÑå™ÿfµs3ë®ÈôÃ©ƒ¨øWNÜnğl€|AãgC	_®¯ÓVòB15w+¼ÒİE–hÁ[iŠ0âÓ
DåŠ¶u—¿ñ|@­…Sè6­L¦¶(›8DE•¤UíÇ¹ö;"|3Õ)¢-ï?í3†1w†ä7"'»ªÃ_L¦`˜`:Ğ¼¡´ÈY<–œ«âWğ5İÌÊŒ¡‹WÌó§N¦Î·óıLÇ²nÏZCä¾•üêYL=öÌ¼Üa ‡|ùRßO»3ìd}+Ù‡ÁÁl OìÍà|F²OÒÕÖ“İ7»Üd5„Ô!‚Ø”ÉİÜÑùug\¨4mÁô@ôxGlëVÊ—î#~t‡Ì_¶˜+VöÍ1090˜RÚæ6ÔâÛÒpiRõ•UÉ»â7å_ÏlJ†ÙÏïjË‹TQd¨m‡¤|8õ‡¨kXùŸRÌéç~ï;ö\qnÙñº›¾zJjŞ.ït}FAxSIrŸ4J>!œóq"Œ¹ 6¾k7|´Zæµá”Cm^™¨ÕÉK¤b°oy{i|IR›@úñ;¤=R!Ó³P€?6Aa{s^µ€€´Wôk*äh­§ğuÓ×p÷Ö	³Ì=Ù½x`àTü_æzk¹>õà/i"F%ÕÏvÜjÿİŠTøh¸ÃaFenÓ|ÔuZ9§Åë./W.º*y®3K`ŸÑ‘ˆZíájèw¾DaQ•ûÈÊû!üjéÛ‹’¨Û-;çØÉ¨Ä“Ê{ÿˆ‡UØq¦Ù/Õ¨q{|T,S|ëáÅŒt¹G:/aÛe•;Ã+°Ï:9ò}p_‘$ –e‡*=/yõâ?Ü“h¬ƒ6ioÊÒ(¶‡Ã^^vR²—mğ’*sù‹Hzt„ØÈ—¹%p u¶¡dw:š‚h3«‰vDÉ2™qŸ±åvZŒ'E×ÒuœIúO¯/¤“!RÈ·Šã vAxay<ÉÓ·E†ĞX¡±ëŸTß“®èá½&Çu–+İ¸.ÄZp6»¹˜aÍ§á;Ş}îÂ“¶H¬Mxñ¦µwšrãR “œêuıqUÈáæo·Oê¿Ns¯–(Æ«Ã™<äÕ8ï¡e$~*´„F…
õ£ 	L€Š~3täò²(0”„&æÖü)Ûó^6‡ïã@~c›lD’ÌìÅÿƒü#{ÃÑsÏ6Ê+iB:Ò#a¯)‡»V./ãìn5%ETZ‘†ù`¡Ô[×N¾2»ßsxUé¤öÂVşDÖ§Ü÷æ<zq–Yne]ùNßé¼>grSá“§P­€ãŸ;»ïëìGí+´	[áv’ã‡ÉÈB´A˜’1#–vMõddF~Ğ¹+t­¿Ö@‡í”SÏ ×‡÷wèÛS›{ÄX†ÚôÉ?o‡÷„T6üßdci‘,LHrt­Ş6×¦R7ŞÆÂµÂÓ®k~¹3*:©Kj‚"G¸¬ûr.(%=ÒÅoˆ{ìrœüÈ·C¹+P¬¹A8"i©®œp)Òp^EÂ2(6R3½üíhø$“q¡ÔOJT"ü«ÚCÕ¥ Ğˆ2H`­Oño¬fáŸº=9‘®®¶ı¤ƒ°½t†/Ì—7Åh%1n~ä›`ïø±(`uD$=Ä%WŸÊv·dõTsÍ˜-¡LÄ©0,X22:b»ˆÌOÔygä
fÂMôñjöRë9Èq£òiÕ_o®d_Ò »Ğç ÚÃÕQŸ‚õé”&ÓY•€ú+¦"ÔSÓFï¾¥MbºêxëZä÷‚ u`­Ùƒ’Î±ø­ãäœôÆøİ¯—CíƒEšî7l†igà#3ï·x‡¦îÿµÀò&@ª|c)Ét`®áÉ<Éÿ¼?yÄ}“1ÕKvÏ	ä—<mw$˜™
nG¬N>÷´íñ»Vê¥G-¶P&& {šx,®‘È×ã‰÷3ÔÃ5Âq\zµáò‡å–@OO«·…^<å.ÓÊJÕ&ëózİ…Š{¤&w;İK”È•áòYâä>˜·µÔ–lï&f³i¼'\àGM¿ìå˜›úP
LRşš)­”Ë%’PËâÙ1¹«È— ıå†z¹p$ÀÖaó´´œNyî¤öä£—ôÊ–¨,kİ±[d¡0ãnåmsØ5¢Tàª'T¥ãøµÍ±r¡ûqµà2‡NèİÀ¨CLØî`Àú¸ê°€dfGç‡ÄiÛ¼ù-?@,Â“cÙ´f|±fÙÀ(Ê€H4Qè·»P#¿_ôô½'æú;y® Ôi«ÌeJN[ƒÅm@™¿ÓíF…•êPº¥S‚^Ïµ†C¾Â»XªM¶Ò}nç*±^îƒcEx=s<£şz	T#Ğı+n‹¸%Ê;Ue@!_ëÎNëÕ)ÎîE®Š»¼½bh1‘µˆ&fé
şl«Î¸É“§^iÍi>qÔëÉ4ærPšƒ\K¥ê"s‡‰j7!§Ùf«À,3,ÑEƒÂáªÑçBø€WıAOšù=§¥q•ÒĞ¯]ˆ„0!¼ì—¯¥	ŸrOH|]CMRíy£ÒAà»3
2Yi¶&GÄbè¶#È-;”Ï›ä*ÄÛ~Şô_y¶Eû”ß_$e,#b¿dEîŸ¬>±àÊñš…Çh…:|QD~úÆ]ùUšÂ*ß
wfÛ?À€Të¾ã%*Œ‰›gnè¥2?ÿwæ3\œ $/8ÔÄÎîY	«Ï¢\X‚-G&4AÛ¼6:&OW‘‘ŒU‡ü¸%ÓtÉ[üØQÌ=¡Qª{Ä&$Á›kÒÈ²     ü/½%¢!e$ …Ç€°ğ±Ägû    YZ