#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1623713086"
MD5="7c2018572c2ef3a49cbf64ffa99a219a"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26376"
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
	echo Date of packaging: Thu Feb 10 22:14:30 -03 2022
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
ı7zXZ  æÖ´F !   ÏXÌâÿfÇ] ¼}•À1Dd]‡Á›PætİDùÓf0ê5à„Ã›ºF¬I­f5I~HşƒœPN£8‹Ú¡L'/6ØŠãP°U›GË
9÷ğ´©Ñ³ù}ÓWq‡qw£~	y§ÃùTåš£~<‡XÉul¬FtqÆèë¸w¯ı5"_§İ½¡A‰,6¢Ô<ó+»};@ïİ„ªM½3ô%ÒT[™Õå-{~WXáş§¤†Şx¬Šó¾=[åÖ|Ñ9kEZĞİˆ5–Ö8}!"zË ¾Ñ%Ö!IÙÖ*¢ZâSàuı=Õ<íYkœæ>èV÷èõäg>ƒ×xØâ[¸0–wâ5x4aÂxs o|tK7‡ºì‡ãÛá^$ì¼“<¶°¡ë®|ƒqµ‰xÂ¨Rãúí<ñ5…XØœšĞcK‘æV¶Ú	†îXm ÁCwıÿ,©	îBï,.x%Æc]İäşéÛêï2iV )9¹9ÔÏ&^„×„óS¦2ÊEó¯Ãıé–5	­È˜³Fg™Ê_ªÇø/Æ* ·	›å†èpŸğg*L»O®[š³7Ä·W;‹„EWÓW‡:}s8Z>”¨a^á*2[orH»”©1b0Ë8¸ÌºemŒÓ
AÈB{µØ¥Œˆ¶$$Øš§éÉzu¸ñ.wHåYÛ¾×ëÊqj•—ØfWå#ä²gº×¨;ñ“³¢!ó¢S®å,ı¢Tø=BAA×F9O«tW*ã2v¶!ÈÿÓ¼€Ï¦¢Ï¤<YÆÌöÒßuÛĞîÊíààcU/Ì×h½íËùÿæEË—iTä¥ÙS#ÃIÁZVŒy„ÿ;H`µHóh”WÈÑl0ì–ø¼ÒÔØ#HïŞ@}wıK\b0¥ÓmÛšõ¦c]R†Ş xŞ- #Ûtkxg1W‘†i‡Q¶oµ!HTX¯9ÀÉsb e><”¼«ËX@O¾¥ÙxBe¨£gz,šcËáXS¢í4.ĞÖµY¨;<—ØMÿ—¶3Æª½¬‡Zî¬¶Á^Ê§CÍÙ<@èM:©Õ›`5p_Õ8&¬õ´<+Nÿè>Œ^o T´o¯-Bå¼˜>‚P·éõ¼¨¡Ö3àÒ^€¿MÖx‰W¼µÍŞïZ4¿H°–"E¦éZÂÑ{€îz†÷Ò¿Ş®ôÁAú*¨ˆïšÔ8s…ÏXc¥Ä[nª§˜Ø4p6…uÌYÃMÀø5w¦?×ûñÉ+uûW÷|ı¼›_ÚEĞT *7¤MÃÉåhÿ·f©Æ¡õŸ@Ø<,šfS«KN}‹é°ÇÓñÉWKÿ0¢&ÙşÕnš¯8“fŸÎOC0¶kéu;ÊzêKÆS•/Œş3=ùqô‡Ú¬3^9<ÿÅ¤qß>7¨æI©Ú·'´Z¿Ôÿï.LtÊaŞsÍW]ª[ÛQ´Qõÿ«"nû—Ç’jœ½ÇèOì†|UŸ®Å)ªc«,½Œº}åœãpïdtSöUaˆ­ ğ»%/q–àBx]?ùbÂã&¦SBŸÖuúàÌè,‡)š@ûĞ}®‹»>ÍÂ£±|ëÎ½^TdìäİäßĞíNzÀC²n9tò”½-.lõ¼BR¼«ÇÄ_^ß¿ ÄÇÙœ«Õ"©­ÚGš,iÌ
ÚÇ¬ñî’ŠºŸÈ&Ğµ™vâÓçš«JâĞã¸ÀÍAÄÊõáYVx$Ï˜›Áï¤f_*êS‰RQ€Ğ¸s‚X·¨˜.e0æëŞ›7LŞÌ½Dµ/‹}*ÆMp¸ÅëšlŒ¨üÿr%¶Âñ¡—¯µ±rYNgdfŠQ¦$d2àœùÖı~©¼¿&bÁ\µˆ©P†5ÜV
W¬J¾Ó%bzÁyT”?ô½ŸŒFEWß>ÿÀj£,æ¹Z‡Ì¨ÿQ©‚Zâ•qrx'•Òµ_Ÿ®“2u°ùŸVWËy†¤±VhU„Ö­9NŸÆUWÇ·èåD/ÛôÇ´Ë3ïlLr¿6Š›“‹x©ó@¶ ì%GbdĞãCûn$âÿ#e¥˜/©ƒQWò&¼"­o{ÍğúBˆ:ü29ï¿Ã¿ŞÑ¶$$XEf•ìµå«dÆ­Êz¸\Üo"!
¾ø[Pe½_j‰¬D‚HÃùZ7PDu¡ö1ös¿@@ÂùÉ<¼R´o<X3¥ÁÓõ&{Tá>Å4‘q,;|+ÂayÛŒ™¤H\öŠÒa]‡p¢âªivSÚ§Ê?%Â.¾}TB‡Aı'QÓ*lÙq¡-ì°›¾ù{Òc­ÆÍpnôo”{ÿ:J%-çôí(ääâ'»]Ïí`÷¢ö”Ø"|¢!1èşÀPË•ßÜ‡Áº³º¶ÜiŒÕx~6œ,Pu”Ö…	¨˜äo@€»{Ø.İß-M²¨û! î]JT\½6ïîN5¸“uÎªÈ‘¹HyJÊdœ…e­E:ïx´tRi9³(¥p¿:sÈ¬·ü³G±¹Î3¶SÄW~;s©jò{e|­ŒH¯ç5mZãNØ3¯„°Mï½&W!é¹¬İÎİß™[õ–!¥ùÖh¥ÊÇÁXCÆv¯X±Ñ3_lèr˜Z[¡­x“/À‰7?2ÄGe…d­àÇ=«ºÃ÷Pì‚g³»©ü;"ê•eä0–õÃvOo0Q*¨¿…k£].Iu)„úÉW¶1HZ0• ª_Y¶{®TñpdğÜbM"ÊCÑ¼4Ú¤GŒ¹!ä!³kÄÎÚb›KM–ÇóLı„)l4
Š½:¬æ5!±1Bv„ \­Wt<•3DV€}§tXHœ¦ò8¯_c¶¼”î‹Àp/Tô‡‘D8ƒK)ˆ>¦kê³CAúà7 •×¼.‘@	íp¬&Ç÷0œ€»ÑµešJ¼ÃMĞ]s–ÉÕ%åÖiNP1®Íi*!ÿ]¤šæå¥ìZoP/†bè?¦ØÏç˜±¦r÷˜µI‡°LÛ~¥e’¹@Ìig–éôÃ×³n¨­ÉjĞz½‹¢ë1·ƒ>7t][ úQÀ DqÎÖRÃkNê2+™)ÏYz†’×€°ñ“<D–¨¨ÂG}ŸÔ=÷­Æémì“Ú}ÓòlEzDà§ªò£DPê'Èœñ;Hƒİ)ÛšxÃÒÕå®*p’Ÿ³÷7`‰¤,z:g;ÿG{—T ÕÛ˜KòPİ“;€¹§N‡B÷H ğ*.CÉÄ#&U?R4ñh*Ödl||áößÁG-í¯*¢ºÏªıÄkÓÖlt‚)#jÚ
©R)ì¿1¯Ìö© ¶¤Pæf{\‹¦­îõf²Ù¼B¿CÍVµ;¤‰~Ù¦ä~(~<)©Ùo8ºİø (-bèsSë8réìéc8´ã´—Ş¡|{S•ß½­¦·åiˆ¥
ÆwOœxs±a“Õ_Û°=G.•A‘ı”Ë¹&@¹aìÒ"èO‡|$~†Clo½ÎäÀŞ¯„8°å!\‚óDş&—D—°DJ˜m3ƒx†¿³®§ï4>:Çº±³”— Nº,ñ¶'[äŸ)X?‰´±Éğ=T…Wöß-»ëô%¥ğnÀVmmœ‰fÑ£­±«ÒÉ/‰ù³iíANªy#p&÷^yÌê2èç“†ıó©öÑG2ÍVsvû­NÂjµ°©Fí# 
/ÔQõ$ÀôjŞ®äè*Fdå¼@Ê:Gjé:ò9ö" †ÈÜ“mV¢²*Ü5¬bë˜[õˆèDQ¨uemîı&Lù—ö‡[:´É÷H¸ÔCõ«áõY<Lñ®[ğ²%ÅéÑí+i†A6Ik¡ÂªYd2wEÎ '0Òr2èíÜ}¶ £l‹Ú6òøßˆ±$Õ–¥?¯ïúş_Ğë‹G1'ákÜc…”bNœ©`¹Ç‡}Ûeå;1´*Í“@`‹Eš:Æ8s‡Öw;¹¯*	Sÿi¡S‚,Š¦(N‹qú^À¡=¦Í“uŠT†^·`®·ğÉQ=¿ôåûXŸW¥aŒÖ5 ¡‚~ØyÃC¸ÕoæÛ,7T¯© v§{„\\|ƒ–¥V§ TØÁebïñÜçqè–å·c[WFb²ÉàÒ–´€G¡uÍ7øk`xJ>ŞÛê£‚)ŞĞ%*¤÷ ı‹ü<+4nÌ¯”ÿ‹5È>ÔiÌ§º™È’Ç†xvN£3÷Ï› a•]ÏÌ²˜vBáTé éQN3º	3UŞğJ%ÖÊ\U¡ùÒÕUµ7ø^Ú&êt?Æîm|\nŸ°Ô›™¹GI¢Nj÷,Pªpö(!!ß¨Â:üN ›”²7úÀ¬¤Í±·I1èB?èxf¸ÎUt‰`¯÷Yw£6jíkùØTÎ¬ëPäç=‚Ò·7º#¼x»å%9Ka™¯¦)7q9``ÛÅJ‡ØÇ Ş‘7RÄ@±æ„¸¶¦$óÂ²pÁŠÓ'ãÿ©³÷ÍÆ¶ïï«ÔYÃc2€2ËˆùÊ—Œ¾ 	Ï’|å>l,ÛÃƒbNF_É°&ì8’„Æù¨5b&<œ"ezXÁ4áéï|d«ã¥J%¾=p`W*<f§ˆåÚ×•{¾i3#g÷v-ï§Š'}H—HUÙ>Œ¤·€ï¤‘º0™F4ü…b·¾URõ»JhzŒ®Ô¦F9sl&›A¯ß%)ÅKƒua<t/‹cú«ÀÑşŸµyÓïˆ¨4¶ø,·+Ñt’ı²ë²82¿  è„üyv}¤„PÚêÈáÍ£wæù°ûwŠûŸß½m´¿~ç{LJI8×‡Ö¦`Lô3ÄN;™…Ø ø¡9Í ²›êò„–Ù\zË@ÀƒÍ¢•ƒ;Ğ¦<?—5Ï¿‘N®f%£<–†‚¹á3I7‹PÎŞW¬*#ŠºV İI'·±ÔfÍ¿+Ü}½‘Ô]©'‘™«€gkDjzµ¿’©ïEL¦§äAYï_Åíó?‹¶gGŞºÛw˜#v½¯ï şŠæÅÄğÚê¦`P9¬³Ï+©+z7/PIŠ’</XX§ûsnâ´š¾˜Œ¨Mè$îeªöÜj#1æDñ.ãæGªKõ­JÖ'¶™lm`<ÔV¶¢ŞAÉºØ“éqm?)lØ£ /à7gÇ,ÈšíCÕ/ª‰Tiézst:ü=\æå {ı¨wi‹}Ù*½ƒ¬ıíâIT`>n½.Ÿ5VüGfx‡¦ÑR“;E~|y;Gâ)fÆq`¯µğß}+}K«Ş0ÜÖztI>¶SÖ¨LıfÏTäCÍ8°ZûZ H0éÓª×Šo5ìVñ§§kBAºT>ûìd¯­ÅÌ£Æ.Ù(2RêîèÌÆß`²¼ª']rğ(#ñŸ1¬~”?êX™É¢9>ƒ,fÇå:6pú’µÍEÑ¿;øEÏŠZè›¤«Á{ìWdsÌ8üÕH4ÍĞW!Öô¸ŠÈF¿H)&RÆĞYÁEK)5ME'1ü³È…Ca:.JÆÔ3‚¡«!= dğéGD}ÁßV	?aşõ5_ÑË.£¡öP#'”ït}¾aôÄÊ™ºQ/Ø‚ŸÚK½O=d³9¯®*Íù	î¾nœz ÔgVëø¡cıÚ˜”àÕg°´	´ |İVF|?QÃdƒN&RtºHÉ’¾/ÛØ3‡5\Œ%gŸ"qKÁ:¼j
Ø,¨•.ÌªŒÃÜÍì|¤3T¶±%7ıî]Ù3Ôš¨Î2Ü³sÏ ´Ë\V%föGlz¥EY6Ÿ»éßWt«s9^±tbŸj°áñ“Ø‚³g%îhñiG£…ş]óOÔ‰æT¯3?æŞmv¨g¶6¨îbb|ÄÕìïº‡2@•âfduÖV`u,¦Í•ŸL–ŞÅ @š¬ A.o>J&”F99êî¹ñ²S)¿Ê;ı¾ê	øÀ(Kœ`ÆõXı*ªN.tsQ¯<W©¾$MuÄÃ1T11óÄ›êÃà¢z=@ŠiÏ¦™óuàÔÏËùÑÏGÄ}»…Ó=Á’Ô7¨×I;™Koaï,W÷æ¨*a`“c´¶AaM‹Î¸UAÆm˜ Š¾^Æï4{µÁ+
È,Yß…ü.&åL8Ù‰Ïàòfÿ·¡şèT'+õşSK*<–nua©­K¤ÖPñdnÚz9u#Ú.Í”„|“ÑÕY"²2-1Eíq“ª¤½ÀË`ƒà¬ÜŸı=®ËÎÄfÄ¡iÏ¬®hã1¦@8_‹³ÃHÒ^¨ÖìLÄÆSÑG¾òÿÀ»Ö<ì”ƒƒÉ»RÚ”t›w±ì€^.ˆ†Ñ¯"ŸßRA%ïû¥üÁÆ†şÂ…æB«hi™l:Şÿk²Ä`sÄñò¦§XÜ¶”A1ä~%)NëøZ¿zUæ LĞŠòùŒó²	°f¿%(§O¤Ù0ÛŸÓnÔ£Ù–š.£á&Ô×zş;1ºÙğ–ÍÇ‰î'_¬¼BŒ8£#óáá+X7eª´8TZ³H&ë vcuÓROÂMÈƒ¾¦úÖ´ù°t¿qJ,Yí"
7kh ³N‘dvşì<>~4Sè	q(päÉòy3Ş¢®;ñüó÷İd7ºŠNI`°æ ù>®Ë9ĞµàˆvÇ¦­½!Ìn@UP8^0 = å§¾½@;‹¢Èmáow/i’‡øœí
Vçñ´ù¬Upİğ˜îü± 	©Ô¯Tû¦Íª;Iº–â´Ôöµ8#…ç`’~ó#õ'?İÂòÄ›À×·›jõevù4î\|äúj‹(:Bá¤_ÌÆ°h°¦Ü³>š?	UıtGYV<7NYqWJ2í„ñ‚É™\Æ³Ä~UÛ‰^eåO0[–§cçùNÎÃNş²ÕÂîµ—IÁJ  pQ=Â±¢‡…Ï`ë ªÇTWØ»#ös ¢ÜZ¹I¾tH)ØN]öàŠÁ&íÁ•¸nä¹ŠÒ×¬TMâ•&›*ŠyŞí¼)´Ø5äºs¸ÚrÀ¦‘XŸ{>ô¯M¹T§F¸%Ñß9Í’9‡Ğ{‡ŠÕ3'şPÿˆêZ}¤¬·§ğ1kLõ9£
 ÿ›""Ñå4²ûºkc,¤	§>(ÎÕgbñÛIÚŞ&à{ÔŸ®9İ¾4,iÿ‰Œø€6¿ÓÒwÖ'R5/Àå“Œ	$­bœug+çCu|7MÖ”´Ü\0èëùìÛæq;4_ v»‡Ë’‹äD­°>«TMÃ’8Y¡ÚW%«rdëèò3eŸh+À‡˜¤…æÖ"§şÁRÿYÊêq·“JBÈC_7[‹ã|f7Ø4Fı¿FtøÅ£x!¤DåÛóã·]+uµ2=×²šæÕ*Ó]ƒüüÑ¼}RŞ·N—ë‹ú…º¿eôB'¢¬Ùğ%!U_ÿ‡¬²x$-Ú1[F—-@”úz¸¬·ş`2šîR-Í®Ô:†3æ/ø>Ü«îc… ­ÄR¯±â–Çë»a@s÷H‹=çò©Ï§ÔTLgèI¡*şi·åÌUm^€` +* ª˜ÌCìÊ`_şz:ˆñµÅ9Ş¹˜«­x»ºœó 
=j”e%ø£7).e@Â·’J§¡¿À®ã×õ¢WÛÈøX@ÅJÀØ·L¼QF8„—ÃßÌˆvZ¯hSª#öe€ÒNf»¥§=‰jFğbğ%ÔnOøSTFô-ƒÄK +¢œZ
Â2q[=(İw}ñâJ Zé	[kÅ­nİ.dVü@üO$Åñ„š».™¼™Ú}/í—±Lx˜aôgÕsCíˆÅLgûâõŞø™±¡.DvÂæ4€`¿f_L+\‡§v€ ß‘çò¦XâOXNIâ›Jumğ¶¿Ğµ§ÈÀL:SıÛ›ĞI½±ºÚjLõ:fÇÁ'#›ëı­®F²½ö9ği½çxë/gˆM§ºğñs’Hò˜ósÈîìd‚Ğ,ĞMªtZĞ¼'ó-/_V©1 05ŞÙ´’¹$5[æ§R£äÑ(T0—1b^XŒ!04åŒwÊu`OOãïz E-7ğ­”›]Û9×*«¿%RËBX3€qöàÄµ0Ã¼ô²}äGó±NJ÷ë“j²²Ùîj¹‰@ƒ~¸Š’º¹§KBŸ×±É}‚D „#Š²¦š8Ã4KŞ³b¾SíEª|r›h€Ó¥ÜÊuó–Ûù€ÌõXµµİ|E¢ÙPoŒÁRwVçâ¬o‡éèjI]t³•¾´D›¨DÀ‹^2+^¿×;°¯E5‘-ÿ—0eØhÌ™°g?éé¾RÊiwy|$PÔ’xB¿`¶(`ı¡ Åşïœ£–„­=‹o¤æ¡­’v°ƒ}ìÒNRæÕ•ö?\èP>Ó2nKH9?ïø¿ô]/bX÷ñ7]oê™ Wt[†TË9XÏfûÔ—YÀË|+µv­˜øXL;¢•PÅëé»NC|_•µŞ¬ÊøòEğO"È¼‡«ŸãlÇˆuËzwMv¿m[š·G³ôÚ"XÂüæ*½Ï½CãV«Ñõ6®¡UtŸ.n§¶®™+¶DO¸MS…VÄ!±¶®“7,ğ‚ÌfI*5CÂ˜Eçä€m­ãÈµãúİ­éñ›\ÀÃL¿ÂÖ:ˆ¢Ú,‹è¶OVŠœã*“_5°¬Ìä¤Î?0¥køI£kácyö¨ô÷âÄA%:fD…ÏÑ)væboá5/`“RwİĞk£¹$P‡çÿå:İ¯¾lü]û4ÔÓ*;Çm?àE>ıYÒ%²Ï±’ô à
ª÷°Z~¬bki:Ÿ“Cö”Ÿg»ÒEÍQF£Ù§÷
Ó€ìVæòƒ¼XıSÕT)Órù>OK×&C[VrûÛ•i8ïÁ©9‡õN2S¯0&â#5HDÜ?Ô«WK6®]¤$—É„£”£:ç’•·9‰¬<L“ŒbØÅÏQ#4ÿÔ˜t æŠV2àômo§´.W;õvp8²U±¿‡miéL3á§^C¼ ,THÅö8£Yùh—[	ı½	¿Ô¨i¯å£>ŸÛæC®{üŸY±f†Ó@rôPc«ìü[¶ u`û•›êgÑF¸ÖšW¾\†&Bès.C×¤FÏH¶Ì“ãí’$¨V´t-R{È—`¿Æ„›10¨¾XùA@0vÄ
ıw–ÒÒÃŸ†ÛÚ­®T$í‡¦<¸ u–rÆVÓ¶Ï:$Ík]öDÂ¯Úl%WYwò'T),m ÇÕÇo
WÈE‰Îıİ‹¢©§åªËz‡ÌÚVµK¢¤ÜpwüF ıßtÃVo/(§“–Éöûš»CSÈCùv1Û„VA÷¢	lûíYÀ&{I¾EcfUˆñqbb,X[¿ıŞm?òrŸ:´LúM¤éÚ¦2Î÷œY&ıÅz8²­Ğ]S®’÷¾î9æé5ıËš¹DYÜ÷z°&ówhYÖ¬1ª\B ƒCÉƒ}7F8ÁLª'€˜dS báÛâÕã²Ñ•Rd>ÇÁğƒ¦Eë>½(öîòùÜ~–Ñğ¥1f¤VR×æùœØ«{ ğÃC ½­q-•%DÍÖıB%•|Ì¸Ø´NoU4á ªìí€¢VQ:>õë,ÚÚÇeŸğ»~ÖÏPK©NÔ|L‰ŞC>hT$¶f3ˆxÍ±*ÉwÓò±÷ry¡/A'4ÄÕ’…TØdnqf5úÕJ¤#Ë©oó¾î:Â…_úá nN”EÜ—ñOòl…¯&ù§âxbdĞ+ğÁßêeŞ¥v˜gã›ß”Q£Ù¯ˆä‰ñØ 2Øôl“»øFlv*&0vr’#§hÄSêÒQ`á:ÎĞŸÀyÇÏ÷GŸòP,tlS%ÌZşpÑ`Ø|"¡zZ(}G¡Sgm³‹§Y‡Ç—(6~RLìwÖôÌPà¦h:Œô´‡4œÔqZÓÉ1c]ëØCeÒ ò“½'Òµ&Â,);/ˆo–üĞ†K‚Ğ1Jİ«ø†Ñ>háaF*`Ü¥ q!&¸),4ÒÃ”ôñ»¥ÊÒ#ûa@]âëÌ›‘{ãÇOM9d <Áæ}—´'
?,{<ê¨{Aì=6@ë«Ö+"ş˜œÃg¤ÌÒa¨ïfô^ıb6©#yùEcS€Ö±|‚‰rğmw8"&^)Ùˆ·Ñ¿	 ¡KÄ±¯†ŞğxQÆHÑ?RUñjù¬Ìö=Í°¢^²ÚGGd“Y+Í{@,¿§&qvŞ”†ğêœ`ÁNeşq¹7­Ø.vBîS‰£ÕŠuhM¾è"	_*®&¿ª~°€&ÃÒÄƒ£üd?Ê‡İêT«KrÍlIt`1¤ÓJøï|zÎ\,Ñ¹Èò³á~øìb*Ş”Å«˜ÕÀ:S`u¾[+ıI18Y`àæóÄ™;?²ƒAÚj“ìlå=«™}-£Ovòp=¥ÎÃn»e2lü?½yKS•S'Q]Ö9„ğµØÜf‹ÙöAù7ÚÈÙ–ßXMwq×»Üm2àW‹S'<ùÈ')»yAŒ(Á;w¯Ä8U¾ÑË]hÔâS·6]ó6™—™¦Gö9ŸA˜:Œm®cİã_<H8QáY?'«i‚çÜ¦_“p“®/£é˜®Gœ™ğSµŠ'è·“‚óJÑP;ôş-Üø2H,¡ô»Š6m&¶¼gRà[åM¸•¦më*³¦lFlBûİhÜ¨†V—o0RV	²,” ú:ŸÑó¼½àTBSoªáâ–+ª\+CzœsÎ‡¬×Ë¤ÃÂüŸÃ¿*=†t=ìúGRj§Àğë.¦ò €|ß"±Ê½M#“1½e!Ou¡¶À™vØ4S-&è×¯pËLã~ZIëöíråR©P´à>„iégŒ½×…šÑeª({–·ïĞ·¥ı4±üè7¼m¦ãÒ±î¯¼(idsƒíê2Ö¨¾AX÷ÁjkÊ…\Î…â¶4"–S²/ÂôÛË‚…(s´óåM:ü‰îwIÅÿ2¤1‡Õüìí\è„ÉFï7Jhââ,áV”@lÀKìÓ–ë¬i˜B¶uşdÕO=If"oëä'í2^#8F-ÇğM"1Ù×CŠŒ¿£%@ã9àiZ5º¸L¾ÑÔSş;1Í‘Ø€,ˆÊK—tõ‰…ˆ•¹—qÏî ¼àÙ0ó"R1µS­ix§¦§s- ì2¸9:°<ƒÏ’Çî§ï]ŒÍ5Á!Ò^Mià=*UÖ?_vçù!kqæ1ò\à±İŠd2¥’È~Ÿ¢dÎìXÑ :íCËï©øQîËÔf=C¤¶„6ƒ(“Å/ğ…Wâ2êü86“ÄnE½JUeàC£õ^"ûB*kè,Â0&u´úµz¿ã‚MsÁB<e@÷ÉÖ>ıdÌÉ€1Ó}œ†
%¸ñÖ‡0–HXö\Ì×)„G1Êqf>e"t’H²ğ(L?rõ”ùÌ|r™Ó4Ç2	ïcØ©HÔ3‡
º¯¥Ó_4JÚ€½Íß!nfœk)E¥^_õÊ6¾‘4ĞİÅ¥÷ğX•È. qÅ)wù©˜_ò³§P¡<…5°Ú¬›ş,Ù­ÏšyÌ–ã_njyC¯‰ ş-Gk0œ-×º ¢e0İ_‚Î?d‹jøÆ5…°	ôØzh†¡şŸ·wŠõ>Oc›eq-Rç[{óÊ!¹{Û1XÏtœÒ"ó›»™UœîcˆĞ¤ëQßl$x¬)T¢Óf»suGí…h‹Ó@‘×¤­97ÙÌ(ı_Å“ú^«Ü‹hÇ’{¶¿Ê ­åja0˜Æ^w<Á)ô{V@æ.ËM ıLhd”¢ÒÎÖ~a¾À>QzÀUòqÑD¿‘7_*Ü(ã1°À`V›Ú°¤*ì"†yRh˜Çj‘9F™"wmğe^˜`˜8~¼OÕ+±À$'©‚\•ˆf^6ªé‡*¼ÀÛÈ›FfZ¨÷ÿa¬çQ3í<Š¯`QNÚB?:pdpdSMÿŠgª&Z^ñÙµ	-yX/ˆJhÒÄC°ó1± ìÛY£hÖ-çQE@¤~\¬Ñ÷Q¥ÔˆÑj”ÑKDÌ>NzôugHÜ.²Å†x|ÈjPe~Jáõ6qâ|5¤Ö=>­…\ºs.³E)e¥ı{¸Ğo}UŠß­ŞÙ…U=aÅk¢“[-Ë®^À"ŒëmhÅšW?/bìU˜ÎÿÙ±l0sìäFõsD¬›­\¶TÂşWháÏîãùæÅr¯Xö¬.Ê4J€QçØK]÷xn ä cydkµÉìX ‰ùÈ¬Dmáyöšâ®{K0ä|¹ïe¢8u¦ ¦óeïI^İU¬|”†]²ÆHš8¸…ÿ††|G5ÏÎz;…C[®|®·_4ş>* ‡rµéZ.<ë„·¿ÜÛ¾çp½A1/ÑI§Œ7ætı™—vlïëÃ°;Å~âÕŸ–!]V¯2ÑˆØÜó¶TÏ¼¹^¸aøì¤í­ÆÚr“Ğn³Ç¿ª7ÉhÔE„õÁ.ÕôÔĞ¡(I¶>‹³‚mÉlÔŞë®¹0ÑİŠ#…Ô\ãÆ¤åc²Íµ²EŸ'üö¸Œp3Š»øÀÛÈëbI”ÿ‡ä7)©¼
Él*€;
=%şç³Êè[ñöÎîRıï²âU¡	Üã4ÂØï´ëA¿Ú°êúÑ¨waôv}q•!myş~ëBT^çû÷ìÏ¶rˆ½ï$!W
ÓU!NÜÇó:>/‚É­áåºXC(t£­u‚šlMì›Só–¸TÂ¥X~ˆ½ÉmL.êÀÑ9,ÈHÃWú?Úgs1+V†kC—¨Tûd‰t–>n¨9¤OÀ}"e>
®#g¦¼x´À­é@GÏHu°“ĞqãÃFâFÏ&¦½³¦’¼;¿ù‹$ïi}ó­À®_»FiU•â>JŒé=òÙı]Qä[{';¬6B¤LÖ¦y{Fî3ß]FĞ«Ø¯ÍaÛQ¦f¬Ì®«Ì²gjRÉıXvÓ‚yUÊõ…fsëêsO¨Éœ„QSÇ‚8Óe€åh4>7Ë[®wqõ
&T//µ8¼ùÄbú!±%ğO3|7)ÆÖ¿Øt;ınˆ¶DWm#öv¢ˆPãõØ„Ù÷£r6gp–S*	«I|½7¸Éßb×šİ—{ı¾t€ò}]'6¹=RöÜu˜´{w7èB?»|ö±—*Mî}Ãf\İòÓ×†½)©b/›b‰û
¨“
(Ü¹	%Ìx¼ÜdÆ˜1§êoêD[AêàgÁ”q‘M˜ñX´ÿë¤K«n¼…#IÈFé²QĞ®‰ê—İİãlÍò;o‡—~Î8NÓŒçè4.ºµôİi^¢Ù%
oe´à)‡Qü	Nô–Öxíƒ¹Š Ùñn™ñ¿–LşãÀh?Yn	7¼=ğ¥yJ‡]‰K‘¶;=Z~hN©È—”ûkM)¼¤<Ã÷²D3&+4ƒ¤Sv{„±`¼hXšÊ”rkÃĞ :¦k-Kıf¤à¶†UOÚn©{§MøBBg!ÑAX¸Í|rôN)û$b½ãÊª6|¤T‡<‘ÒrNLÓÔŸ\ò®H‚½8ªâc9›õ¨p¦­GÈë’öE	!²H½‘½Ÿ]cÙñD	{Dú‘õtKÊeF™
- K‘x’¤º•éVæeÀªÂŞ‹ôÇä1Ÿ&G^=Hõ´ôè)QÔÚïhdD”md¶<'i€:·vÍŸRˆÀ\#T~†,@hv„Ú›½9-ÍŒ‹aïM]qâp¸Ğl÷kÂöeô3Aiãğ®+ªOåTOpïªNp6[ÓÕi :]4fQÑT÷ûêĞ€ç
(Oá±yÔ¾¡”‡T_ÂUV¨‘*‡?K®ómháMéÑZgâH·ÑIÔ°rXá«\‰uœ’ƒÃÎ>åèÄQn£æI·Nì©ë“ÁŒRëÆşŞWHì2a±œTé=ôÅşkrF¹0/§¡¥ÚñÌ™‡¸KÍ"` ìû[&ô½\‘a0¬%àZj¼	'ğ“©Lt+p3¦[ëWHJĞÙ9ºŞ×;‚`|]ÛŸFAF¿3~
»5ş¡
êéÊër³£1{‘éM÷8!O"XÎÈCÔ.\3»©6¼¾:Š şK÷Lş0:•fõI9Æş%¨zOÀFIyò£ÓÔf%ô1HfõÊ»‚ql-<@o—¬\{·ØF·ÕÃˆû0¹b¯Â-ÉSİ.?çO‘*ô}®+ÒâÆ–'ÿ°=¦Ó
TƒÖk˜Ø5‡—”'DøÌ’PrS ©X°Îkôd‡\5óıNE±¦ ë`qIØÔİ6 r³L=|u1Zì¯“dø•G*IÍÚL‡G:/^z¥‘ÖÒMÛpĞ,Ìè	÷	Ê‘côìJ«2Ö© 6µ€H‘PÉ³úÅšwrVø.“Í6ømK^D‡©LÍù³ğĞ…ø
ßyÍT“J•Š.¦™¦;_Wm§”!q9ú/„[4
˜ìAòï†6éKZĞ²õfÉŸ3P€Ø‘Äö±yª\÷H
¼LyÑ³ª[L¦l=¬¨›üÂ¦.yÊÉç91¸Ô¶S(í‚¾'<nr‡Ø-lşÔÑDâ yªt¨½10¸fÓ“†mMƒHùƒF§)æâGİf(céœdİç~EpSÌê×4#YCz,˜â=ÄH)œI[IÚÛY›Çªt†ÌÖ¼AUïšm:k¹ôôj!ğÂ _=»ğ*ÅK-<&Y‘S0Ú<´1\µÎ¬	~IäJ3epÀİ©b›;~øá*vLp©z;zù*ráòñrÖ_Z‡î‚K¹Ì?„@”ˆ¿Şæ~À®Nf„ã¦HÛûóªÂÆÀSWV)„*`¹Ê2™z;(.ÛBtôa¸ğ)=ùĞá0›Øö£g€*yŸØüPÄ^ï”NV›‹ù÷sX…OBh{W³}6z¡Ë2­Ÿ*Ú U«›f€^tûûèâ"â³1ÏÒ½™‚ò÷s}qqw0­¨m–ÀÁ[(eÄ< ùe…ìÙ
/<4EYëÆ%ı‹-Ü%®åĞ«‡Ô5‹#¼Ó\‹ÇâÉ+ÖæXqëIŞ¯ÅPïS/E‚×fÄ@È~c‰®{ñ)"»TQ©Ëëñ-î
«©úûôRÅ9g $n€7Ğ]Yl9H€KÂÀvU<H¼……-¿û¸)†§Š.åo"nW98E@úØ‰ò[`G¥#İøöL@ø\¶S>	œOğ€I#h}1xi©Ç…°À‹íğS‹è#L6ÈVL¹diÑƒWw§îÂã‚†e2wµR ZùÍÂx­Y(H"n9S€Å6ÿÛæ0ôòšoL–f5ğ¯«}•êá‘'ŠåbJêÉ—0ÀÍ°¬£¬bÚP(n5ÙáØãşÏ‘<$‡Á›ÅU›gkS˜Ú±R$øã·à˜é[q+"hËï¯Ü­øÎ’}ë§nSrt€Ò–œÆÙ»ÿ(lËò©zFF•héhx¬N£ê2¹„!©êc¤k½j¥Ã5zì¢¢¼–ŠãôÑrFBpV†¼ÃÓñd' &éY¬}²î‹y h Ñœ	ûq½ÑßM …Èƒg ÙÓñí¹Ä0$¾ ğÛ@&
Úz6Şõzç4(L0úİúÊ	¯èØ­ˆ42r1²Y4dÙu‚¡ÂiŒ(_ïdH<ü^r6¬¯ºäosZ¨²û@¬ª$X_î™T mšbæF¢#ei¥-’rA‡+,Õuw7pß~Ï`ÁBÜàc¾?’ŞôÒËéÓ^Ô.˜š…ZÖ8}—Á’wÒ`âBëiG2íQ\BP°T •¡b{ ú³·ô.w×‰µd:-ò÷»Ê‚ÖÂˆ1%Ô¾¼Ù„ë c‡I"<~
·zdXNã>Kpä\â@è|Pîõ8)Í¹æÅËÔÅkàç SÇÉMÊ<çĞ¾Ìhv—°àÛk¬FØ) ë,®.'8ƒ…£E‡ß¬ğ~!8`wª]>Jpé~ìMŠòvĞÒºñğ`™é¬6SÀ	T­ĞšCÓ‡Wÿ­º$,üQ·˜-"è÷CÇ–ªa^¬~<üY)”êª¬G¾¿îB›Y™Ï-ŞyUÈvûŞãö½XKãŞaÙEÓ4Øé¾óÖ	µa=g¬ãl*Şë§.ª£…ohBˆ9w)8ˆ¥×á‘Vê	§7é‡TY@S“Ù6ÛÅ¹Œó—~/ö›h Œ²ŞŸ‰ZÔÏ ØhÕTAçw¾§f—hùŸëïJöçX¨‡+"ÇÁŞ2+ÚfeÂ³‚‹	è$ÄËÇ‡×„Ñóz™ëÙÇ¦èD¿Qbädx²&Û³+EC8‡»ø¼$+1r‰-éüÛôëÅ{·54ƒŞ«áÊlÆb¢nôHnWÈé‡Æ›¬ÓqŸûâªoûne4¹zç-ü—µ¸™tH†4Ñ‡]È9VR·ò6ê•N0BâæÊ¯,ÔÙ†¢Ï¿&… š#<í.Z›G@èA®ÑŠXôÆ
	I,w¢PGü<¿ƒ‘dähjÛT+÷‰õ§}0P-ş¬åá,µºÑéÍ?nÛÏıex¿Ü.•Ÿ&O‡½’H„´7ê\ —2û±¦ó	&=}YJr‹ÙÉX–f°²šLyŞp§¬4GfÜ•}¢"°UP»Ç _5&Y"îËä7Ÿ–ı*äZ(/•S'*M{êkçñ0Óé>wN”Rä=·?Ù4üUÌ´ÈbE’‡Å0ëBgóÆ/ZÑ-IË©®[?9ºiÜÊ2JC¿·óKÅşã¸ÿÌğİè‹¼Ï{&³«¹+² ®LÜ{¶/ş‹@V\òJ¦ÿØŒ |jÆË»tÂp$Àà3R8›4Ìâœ•Ó¼Îû¥áÛNódæÅ2Àvª‹ÛP¢th²—dØvéÁà½Fø˜˜’ò‹lŒú–ª„Ÿ®_k˜Š­êç|!VµKI™¶Ğø’×*„÷@”Q^‰îH?ßò°öZ|WhHÔ ?Óÿ`0¼vw•zU«àt9p³(Ğ ¾0·¬P<·Væ‘}àÖ°ğD€=Š¯Öhş5¥˜*øeÂp¥<¸÷g%98ßøsœP(µ5Ù+·BÃl°ÈIöâû¥ üy@4
Ï)qHj,ÕuÍ½1ğ³ÆŸV]—uÀ^&ÛG”<Z|f¤+£C%7¦?Àœßï}¦n½x$=‘VtVd¿A>á†²…lØTõaåóâŒ„ƒã ASv’ç×ÓËmğÁb\ú×ôÎTÔİĞ
~ûIŞ‘/Ç/–•r•µà£ul@>æ	m$¹S°VÈ…)— ıT¯şQÙr‹’|ÂY) ~ Ø$»½:¾U’ Úè®åi"Äaï¦¹óLóÀ§j(ãç¶;<!æS!qøÄ)óÊÍ„ñµ:96;ì8ybw±ö¢ğßíÇ.¬úft
?‡Ë[ğ˜çDç:‚Lóô¶ŞdëëmY£¨êÉÛ”b
2¡’æ[Ø¨ı3øpv%f+Â¤““æ%
e—-B6§ßÉzé½XÁ.˜;‡2I°$Lˆ55¸ÚÖ,X\z.ãÁ„ÎÿüBÊkK?BQ#~ÂEŠ9¥«€7éšuHRdé0wçJmÉ«Ş_öI?êËp QÉˆ4¤oÆ1ül¬VÏw"$gŸ4Ã»_)2‹("w+!VáåÛÆ€;ïËo[œP5%%Yrôï¦™-i©f`B+ váÚ™©z‚ïäş7ü&Şÿ*ı(µ‡6{èo[ŒG)ãû'ª•‘ÛN[G
|ÉfŸ®ôÌÔEÎçÛŞ÷Ç¨æŠÆ%?ˆ´g›Î2J<Œòï‘…ÙíÛç5úM€E¤Â;uGv\é|XòbiB?¯P$‡ewLƒ f°æJİ¼á(3‚4œNÎÇcÇĞö!ÕÃ›doÛiËuÌ¼ŞL“¬WÄŸÃ$X¡Ñıÿ—èwziºvöİÚĞ´5a5İ8ªJÁW¸4QéL`XReªş‡Ê~!…¿®pè¸!Óiz EÕMÊĞ‹&®GÛKM*r=hóFøÃõ¶PšÉœ9L+0}œ¬hsOÚï¿ê‘üK+ı‘Úys.Î„)+,%¾ÉUu!7GğèÃ¯Ë¡k8;]ÈœÁ"	$¶õÕí;8w¿å­ò€µ9Î «i¸êy½‹ -Ç_gÉ¶ÂJÿ¦3HÙçDç’uK(„DHMÅ!¬2”Ê\-ÓÒk‘»7X>(˜í	è£ß7,q 7røÆEÆœÿÂÎN±!Å ÛÖ‡ŠÈM•JS(múÅª§<dúŞ–;­?¸I5®ŸÀ*@Ø^A®+%ãVJ³ÉÆµÄ¹yx:‰œ´ºûy\]ÿtBi¾ÔÜ¥§ÙäÒERİ/oî ò+aÎißh ²¬ˆéiùÒML²ÓA[fşğå¯å’_ô'Pí²OúK½5JWÕˆIeN„eøn´±Õh”D‹¥éé#ÛU?Ô¦[ˆfiëîÔÄ£H_1åOI !ÜÏÍİçP¦$Ïà£| “4‰7àmÃU`ÿjÿ‘ço{¯®PõYT	tb¹¼Zö„Uä‚~;/•’ÆŒ$Qõ–»íØÇI,¸Ãáo•Çñ˜»Q/æø
¾Ôt¾	\øâ†rT8I×´Sq’-‚eAM–Êˆ40Ëb&kÜ,3ƒ+fÛ]v
²Í`Á¹3ë1†gJvr@VÊ†úÌÌôYòÁ?^ Ó'>İO²ÄQ&r:_ıÇÜ"¢ûø¶j”†åOv/ÿÑvf¤&K$ Qó„Ñ7‘ıè™Odãª« rŸ"3¯-…É[pîÔ„?ˆb› HÌ}
¥ Nó£\:—-.ú3û8— -Õ‚úD¢¾?¶pŠ@9Ìşï2ÿ
5F@ÜfØ4Uÿ9éÚ$ô9g56k}ÙÏÃ¦Q»¼÷¬‡V¸£Iˆ´\ö4€é~¤6ó¡”SĞ~M“îí|ô8Î@zv=R7D¥œì»¶ë›Ëç(|¾íkvƒ®c¬æhwm—œÛBé1šËË»M©<Ò‘bhí»µî¤éÉp²! ¶ë‹0Å:Z4í´
bô¤®ë[Ë¸4
!ÚŞª¹”Wñ7—şã¶s
%…c‹6Æebùà_A³¬rkn²ú=p>U¨õšÖØ“eL‘?îåÑwêPúÅÊ®cG'ÓáµÕ<ğ\Nuğ×P‰,qà.©…'Åhyï™A)!ğj€Œ†Ç¿P¥üÄã>§“øSkéE6AÆÉ¹FäeªÍœmØém^ğÔî“Ô§æ–Ê¯ Ïçƒ÷îÔ¥4É5×Ço~r
y2Ö¨pOÄ57
„4NLŒ¨
/-ÎŠ1ğŞ^’kAær«F"zœJÒ?¤äe§ûD‹W(½İİ™¥€)'t}{¦³Å‚Î‹9ñ}¨FmaD¸ÉÉ¬Wf|á¶i!¶F¹qÓå½¨mIÖš‘‘[Gääƒ*zÍ a:Y4zËO4›ìñĞ¸ùÁeT5‹Yâ:{§†Y©W#ÍXÏ§ÄßL1   — $ûø7û.7h<Eû½˜<¿ÄûüæÈ—b"óaQŒÜ‘óGY"¶"è‹*Ÿúa31Gh5´zÜı“@(ç¡p QEk®ï
}A¬®Ø‚³&µ@2œğ%k!û­îşrPÑ¶@„V¦5½U “°Ù¡°0ôxjACÉÓYƒEVÆÌdô
¥°jQßy!Õíşşjô?!è O¦ñG6AÜPªA$#Kš¬>õ;òU›H<T,«ÄÄFr,gËêg{ù¢€P–Áä¡š„NOùD”lMØ½'¨p3İ«“ˆUâÄ~½¤Ú¦-“?ı÷£ ôì£ËØÿ,a¦Ï½’,/×Dº‘8Äë:y
¶[.ÁÎbBw„y]•„v ¨/¯We¶7‘Q¥öÇîen²º ÎÁiÙ!ğì”FÇ¸ÄöŸy¾~j+÷Ô	$u³E>™·İ™·uİÉså¼’şÊ€ˆ; 'jı«FX
I”7Ÿó(B`Ñ´"ôH’#Jƒ*§cÔëÖJ¬BÎ[²¸á]cê~È±CS4ÎäfE¥öüÅê¡!u·–Qk#/ê¤”‰Ë‹ß½s:Ü pvq9àLj^5·ÄĞ™Á¨¿…ŠçèlÑÀcm-öS°?Y|òèî.ô*6Õc‰Çk…¼qÒD$ê;ÃgFô.ËmàùiâÛ¸»•åæPès„)¦;}Ë„·´hâÖ³õ·äW÷´œJiäCMşé5‰‚*fCtA»“75İªı$:îƒ<y ÊôvÃ.éÌbCÁ‡xı0Ç¸ñ Ø¥ÑøÅW_ø%˜ˆ“˜û·9=ì?>˜;é,óKm¤±P_b>Ø>Zi…S”iŠAùæTD±)ˆ
ã0ˆ1JBv¥:XqŒM^¾øÏUXZ˜İ°Xîñ32Kå)JƒŞûîßVèC+Áb®y3£¦´Tºàñ›ÙÇƒ¾Œ‡¶V¾•…7İ.±úªYV·ºïã¥õ"4d{tRÖOå^põñw@ÀX]×¸À½¬×”B|}l3Şn`R	M¹€jI‚f*#g*cğ‹ô¡€ì1·àlZÂo¥gÛ&B|Ë3’yÿBG¨äˆ
ÍˆrÁŞÆ›·´CY–
;}¤¨Lßñ$ù4ñ¡'YĞ¾Ò¹}ÆoŞ—ñhË;JšBg¸Qi4ÆÎ¤ã1N†Û&ã)ïÿI•Î¯`E ¼ÆD_k… åKna‰çœ†”……q«NSõCÏ€‰C”ÿ°úüu£ÒÄe±pTMÈ£~}(=à+>9x¢ÔÜ¨-Énp­-Ş”Bêåv6?ÈMê±0aHé¸Íüi9 °9a³“×kš=¡Ÿ$@ £@ï“ˆMÔv1º\e™M'“ø¸ÎmwGH×¦<™PJS™!Ø%Äµ»
(ş¦UOÔKxÉCîyl”Y‹ …‘¶6:ì}¿ëL5;ƒ€XÆ®åœÔü@¡Övò’ÂuDA~Z{Wp;.¤äêİ·„x¬œÙLF Â±ñ5·à>siÒE“œ¬ïZeÉN›èqÚøY¿¾Hñ–Ğƒşö‰½Ú¶ãP\Èe¢\>¦cè+¥c”êƒ—X¢õôA¯F%fCx!A¤—Ş¸M`úMtyp²§ËË¦nûjµMºĞ\q¥2’?°„Ş7º A÷C©û³K‡±UÍ-ì9U(Ù×ªş¡¬ëa´«µDí`¸¾¢ì…,;º_,LÃ˜]æ“%–û¡O@Šïß[uÃOË‘Ò%7&7Ò ôNéÿ-Ñ,ÁÓ2Z–ØKJ-‘ËOn~ãÉj4òÚ~??Kn ı>	ÀÑ?È–~õÙòŠã/?06-ë;~|ÉÈï‘ïBÜ	b‰	æ¬e‰aÛ4‘¬³£ÙÏ,7€ìdçÒ_Ã‘@˜w°ÖTğx3¦È¶êdò'ìıjk}ë½’nPP³‰ÙØ‘x«!9Ëu¡ŠPÕ½š–¤hÑıú~²·tÅ7ÁÈõk°ô C¶RÇÙ¡eQüİÓÜI<€uCà‘mÿ”P×è&` rØ`=û,p“}ôù¸;D)İòKø28òfªÃ€3Â‹|³k¥)IÕÖA1n	€LeÂºl€¾2Ğc+a‹¦
ŞàÁ^ma¾¨<â1*)ÒYå%_‡—_ëº.PÕ2V•Ršo”+‡¯u•¾ßO2ÒRÀ½>ñ\$;ƒêà“Â^hÔ+;O\1`€FmÄØ™SìÉßÃ“jh“â=\ŒoƒŒëşŸÌ¤„ÿ…O»LmÙVßs81A8slF¿"³"O@ò»‚r© İ0Oñ$6ğ ÓË,Qˆu!·e:Ô(œiŞPzPİE¡‡y#©óÏ)dµ`A
Wl¥öŸ«pOÇî1¨m‘¨dXtæcJ²~À;ØúïÿÌ#Ÿ5@êómyû
4uºÒû-#òVk¸Ãš »ùV¼hö\½jæ<cE[Ñß‚ ¤Æ' ŒuCëa)"Ú2¯.¦í²Wmy*è˜ôàü©ÜHõİ;ôU2R; ê#â°ât
:Wd/pù)PYİh·;Ix"Cmc>™&‡t™røk‚cNDèUBĞ4_ß¶:µ&?[k•µìß0í{tÖ+núÁ`Ó±AİQŞs“6B²ÖZ%£|{T‰ê
šœßõHfT¢$ÿš8§›9.2˜µ¬$Í‰ê`Ì‚É!#` 1Tin£…ŸÖõßDğlm	ªÓÔ—õ{¹OÄû?•ĞljÒKÍ‡§üˆ.¿Œ·½—oêLn¿›^Wì4>Íé½C¸kb8¥m#‚N†Úıœ¼ilÍ4#µš•ÔÑ™é*Ì:Ø"(íá`n&ÓvîÁ#‹ñ,œîjP0*ØZî˜åE\Ø3j”+ …'iş ±Ï;ÊdÇ\ğï×2k’ ¡Ñı‘¬Çäd÷>ˆŠsãî’ÏĞ’ƒ\%‘qÒì'g Uç¨Wò·.~7é°>")T,(pGL¿ƒ¤Šv±=a¾÷Âm7“±á©'›Hmh2#cÉwâo³¦çDÃLv»ÿ>™(§şÊìÅ!6iZÁĞR{£îö¤/4m‰ØáQıĞ]V2}¡ëù×_´jğo Eüœ?¤²Ÿ•¢RËÖzÑ!j—ø!—¼D={Ş1Ì!şÑk;Ú¡äœÙ¼(»w°[â¥Q“½£ìúá¡?•øa®´è½Q9t9§íÜ™Uîwvc3ï¡}ˆş—uëDËŞËOÒtOHÌÉXËïØzíÆ¼ËÂİÂà5õvDÜç*§çÄé6’ŸUÿP_ë+¢*Èç—_?éˆ¨õ^q¨İ8»w4KÓ±eb’å¦c	N·¿n„İÖ^&m@Fu;Y§“û9ì9L%–‘Qö¦ëûzùËğöª`È™PQ£H’12˜A.‹™¤¨1š»Èòï;X^’¹ÓÒGvdq[O!{æz)ˆãµ‰r¹æWFygğd9Zü#g9G²Q¿[7™¯‘À»ùi|²&va?ªÅˆP¢ËaC“lej9–œ§OÌ~«ôŠ…;7Îhü¿Pm%#Ë¨¶nZÎ+WzúñùIŸP$“4ğX4Ïw%Ï¹‰%[À1«²KDvûTú³éÕàk/r”Y¿º¶J—…lhYˆµŠ†dÉè!“:Sì¼šÜÓö…®s'DO$Ç¬Fşç!¢‘6¶÷™õ­§‘Šëª
„rØğÇÇEöIs(¬áÏõ»Ón‹p&è$vû¢zT	Ú½ß¶lÆ·Ö3Šå»|”ëJˆ@§¸úÁ.`F=¼	/jT#åÇÒ"6d¥á¥ÚR+I—e7_Şm½Îr¬¨x dWX5ªW6¥`	WVuyÜi9‹“ÜDÙÅ!Íı*0CÕ]#@\oAöä…ßò~ÈR€‰=@Y=_O¸ÛwÛAU§HÕVŞZ#ğ—ö`^@óˆÅ´HMÌaj™yÔ]
ôHñbÿH]\,õı½h™Ä+_¢ŒÅ?9²6Î…”ÌİiaNõ»µàoj'aû’|bØÖàaÖ8P›}ì=yoÀëºPˆ¶Ïe–0¿…½e‰mÅŞÖJeX›èˆ¿X&[=[·-‚çv“¬kGõŞ’¸AïqDœC:jp¢Ê$KòQ}÷&èÜ˜~Åm„İ*2íáÈËßßğ¢wå¬‡AC³z¸¤½´ iË¬.Ñ©©K>¥‡§şuòZ_@8rÓYM°Ÿ±R$t_ß—­~™åüQÑl’`³ü{·ş¤`ÏÒñä÷r%S·`zòö„ø§İ	¯R.BĞ}¸CÙ }æªü‡Ñ†ô€ı$Ü!­İ®ˆ#edReÌä#_JÉâÖ™´€ÙaÕd@›0¯fĞó_¾İÖ'Ú4otg‹ŒjÚ”è–ÅXœ÷VƒûiÀ£b‹;ˆkciçƒË¸×`jm¸VJ>EßM)¦Døp€pUwÂº¶®>qæoÆüê¿9§…iú0<c4`¡–›¢0e¯U‚‘ÕÎxşösh×ÍÏ.Û#äÖ 0­†h„s§`ˆ‹¾é[±„I„‚VUá¹P[Î4u¼…~¼½¦äï·ÎDŠ ¨’Ñxªk.H5òVÄIˆiŠ_8ˆ'Vm±ŠŞÂ[÷nU•}í•¢¿Äş)ˆì4Ğo³5Læbfu÷Ñ‹]× UÖJAé™ã7“=Õ â¼&)ğ•ïÄ¤<Vœ¦¾+¨¯¶.âøÇ? ıÉ×ñkÉ%½Ã¨ª
ÖX'f¶xL	îmo„3•È$Jşó|š» FáèÃ¨Ñ½½Û"Ó´d¸ì60âÀ^õÄ7¯wúeŸ²04?EÁ^ğ’íŒâD§óÄ“)òœÿ(6 °ãê»è_ò.
=¯
$ßñIìa›ÊÒ¦¢¿¹Íøó–õÎ­Úö{Zrµ¾b°râa‚ÒsÈ-q£¢«Ÿ@b¬ò„¬ºKGˆŠîÅã7aCG¶T(!­T‡ü ¤?ó°6ÊB³Á€
)¼×©QUı†HH_üÕƒÉ4’ûëÕÛaEn6@å¥PúÏqŸµ`À¼è™%‹øu*Ëíò·]ÿ“¯ûx³9oyªG‡SğwôòsÁ·Ã)#@Pš´ÙÃş´ïbU¿\—§Ôe)ŠÅçG„¬á÷4q%5™ÍÃyËŞ>ù1à•’ù­ºmv÷´İÅxm!nÆÆÉµ!‘kÚÙ\O/Iw¬my~E‰†V	-Ú-º¯!]	eP'šœ¼M³»ô"õGß±Š=…%ÓoQy<¨m½î{Øã¸ÅÒIç5ö²Q¡}n“¡­óÁwŠ‚®çU»üŒZÓ­Šä•Ü]p*NŞ:,¡u‡ÕüF¸yØ;c‰
bà.µ¡ÂSÂ[UìæIù*B~$Úœsõ*îín¨¸­Ó÷V‹™¬bóâÌ?í§ÉpJıÙjÎuI¥qÊ«[1’¸!·Sx·‘~g«£oû@¢ÃÙÃ‰¢Œ¤³OaüÇ¢ïô‘q6UÈmá,¶#o©.}S„ĞËş%P¦å×Bğ¦¬¢NĞ²yş­á‹OiÇ«ÚTşC]s;z3÷?v0BŠÕÚŠÉu0÷Cí7¡&:î‹qsÓº«|ßS:³ÎúeºéŒ°]ª [ÏçéÖƒQŠÊùn‡× {ÄÓów’ qI*PèE Ëâ×{´+Y oÔ?¼Ş„›³XLœBSª9`Ÿ¹h8Çp¨h/ÍLÂ‘ïøÍ$êšØ»Î¢^ì>md´'³“Ce‡Õt%6Ã;ƒoÍìI™“ÀpöÓ,¿>Ò|dK£.¥ò Ù`pÏMz Ey}E¦M™G*z}Ó}Ïõ6¥IQ¦ °…âkkàïz¹è8S•§ì…VEƒlVî+\±Z¹ƒÇæA;è›¢F`W<ûZL¹ìz\Àæj%şèÍcï‚ƒho³šıWµ+ 5',Âò`o)V]©Ö‰Î¼{œn¤ÓMÌƒH§Ô}Õ$¿ƒÅÚÏˆ:‚z ë=ÓDQäv¸6$PÿïÊM 1¯5É«±Êõò˜òÿñ÷ÄkßÚ§>>",EöfÉÔ¿ÂÂ‚Ú\R2
®Òvã°°ƒ+
fÁ£‘{OøRjµÑSÓó ¦à«ªİªìÛ\›è*å×XmD˜vü2—²f&^¸¶ÄC	çª=éı?s”˜Ôç1J?2¥-œv3^NúWÕ@¿”@ tïAS‡Ã:ÇÎÆ+îÏyäêBu.˜|ğOÕƒßZl$ô–;T0"®F{…8è)š#™şŠè´X{œÂÇ²vaS+ù¡İOó«.´qG|2PhœÕ¹;@°›-O?²ı¡u*¡ë9[Æ&mÒØ{ Ã¥AV§S£y•á·ä\ñİ{êê=v&§»ÿe±ÌIZg,Íàd\ŞC*Ø­@nÂ†‚·¬.8µ,ëÄˆ8Ş6M˜;¤—)lQU«jõÂßZø;«i¯GnOû„0#E`IÂ²t8àÉÑ»ƒğ
ÀR3—:O‘*şYP/œnh:¾)ı-p‹J1qğ0ÁÊt8 Ñã‰0¿—ÄnZ'Ò›‡£é²Ö˜Z©‘€Üád%±y+÷Àœú~ÑşÉgåÚ0ÂvˆTÈ¼@‰S:‘¤
â~oXyœ‹YJÜXbgÂ†sŸÔË)êÎª¥É3f'~q÷1”?L²Öİd ìÙ,Up«Ewù«<QäÊ@q`TŠ‹+¡«%QæÁˆ§÷°¼"/äBO(¡ch!Ó
HĞa`°50Ì^²ziÃf·©û–m$N'šø8² q‡_ü™lh%©ú^´A@Ôü¸fmÇ%•5Äôzïªy$:n—²¯ÃBİ:O‡¾ğPÆj^%N hºÂœè‹•p·zÎq'Å6Êwf	àî†˜7@™kl¢
¥!î—Ğ]s©3e»Ù€2£S1"}¨QşÇ@‚c÷v.µß¬v^T@1d¹]¾³‘'Œn´€ùC"‰"•ìuzĞãÈÛÆZ³­ ”|¸9ªázÉ$˜;oš3ûh‚u,¨ÄUÿËõ]­–>R ˜Cæù²:˜!ê´î¡&›Ñ·…QÙ×t¾‡}ˆæ#ÅbØö”´ŒÖ'B•âXŠhÄŠ	<—%'—gÛÒOüf)HqZg¸ª¢è›»<¼ùÙPzséYbéË•pš–£Ú=:#<DfVªÿãÏ5ıû,ÛÈl•„@‚_Oe÷‘gö4Xç#Úí›?KÉ¸‰ózëäİØ²pZ©5e…w‚Ÿ¦˜¸k‚6Ä{
©ÜEL‚GÉ´(>Gºu´Ö]OCœE¸oôXÏÊß¾-ïHìŞ©UâĞ!&L×³3	â£+_-WBĞ„Æ• ¶7a~	€kë=Ã‰°@;Ób@$„«?#áÒ“Îë %^RÊ3ì<©ò£Ñ–¿Šmº.Ìã·![™½€FöÃÙ8lßtåôêĞÎ2í¸ë¤QGO[¶µŸWß…yh%†öó[±'ë0ÂOÏæQDôÕæßÊg«Ì.c®±Ğ¦¡F³ÁG”[mN…È §MM&„ü¢2nQÄ‹T–Ğ£ü5¬Æ(m·UNLeöYîÔıoˆÄfôkŠ0~£ÜÄp=gŸ•ÊÚôÌ˜®•+r€‰PŸY1—^+¤ëİÓi ~İ0S™vlZhƒÃ"U™%EncÍ’İÃØ^E“„t0‰_ƒçGè“Î×N‡¯*=°½H°È>“¶w"¿wüîZd7““b÷®WXèJ×VäS´©•Ã¯ïÆÉŸJÑc¸Şàã!+î?NçğQpƒã'„"¹jMqüÊsÜÇùÒtkáä)6®_‡Ø?¸nS¨tÒ%½2…}ºRË&íÉÄ%}xã%)‡Ï*k¦ó‚Û)kb3›†i$[èo¥—_ê6è(»g¥ĞbBÆİœ)¸t'Kd“ª(Å8¡ŠèjúÓÔôÿÇS=½H.äjÒ+¦ëµ=ÊõÛ‹“ı“İî¿»ËÌX)ÌøŠ[%S¶¹ı©İÙ×•?[‚Ç\‚\õ1h![X¹«¤„¹Ğ4Ÿ½l¸D Ãh½ûSs‰¾ıÌÌ‚äœ«,Wwı¸±=—V›/ÄÌ¿<ŠX5PnS\¥‚O9*wúÈ—BıµÙa¦>oäo…«İË6q7Áö/ŞúÙ‡ÛD€>WKEÜ,>G¥V „¶°"Oƒ„—ºÖ³)®–.9º–ÍCÃĞœj7¯ânßªtš|ÆÆÄ4u+ıÕÅ˜àÍjÊ­¹áÅÿY:a Ï)¿7Í¬a‚Åùı-Ñ½”išwå,(>`®qHéi›†˜©·ôMn Äš’¥V‚·£¡@¨NŞ-N’Cs[cã²Z³–šY¢º±ŞÃaJ#XP¹¤¢'ÖÖxêƒ¢Î“yä”c,óÆuÓäwC!²)‡ÜZÚ
lNu2n¾C’ê?ÀMæğ²LœÌ'ºÖøÅ¤ºÊblqiï?f¾ærm˜¨x_›ö•´”òvÕão£Î=ŒàÒ¥xGë¹x?fÔè—~üJ{8 ga?©	í¸A@oƒà]ø—¿g;$8öá§¡#S(G#zÔwÜ*¸¼j4ëª¢Ppå
‹ˆ¬^§ùª`‚€¸5iTUuú+>¸±T¢¦M\°%Ğ)#©úV~– ÜÖU¢È¬m[iç“‹—ÜµÔÕái;p®^•7d¦5•L¨B³è‚±#¦’ĞöeqŠ;”ü†¹ËÚh1%^>è~–ıi\)«_M</2æ–Bñ_­å§JN|\æÃİLf,}~ÂÜ+`™sÀ6¥ş»ŞR¼óñ¯¢zNH’ÒbLbÄ³)ÕŸ¤µ ETÿí.väèÏÜÁe>FwÌát¢A&`i¿ş’àk®ÀˆTõzxU/aÆŸÚD:“Tş´º˜ØÏkı{ó¡•êï‚ß½ûÀ:£LZá×¦å¸8E ie»ŠŸzàmt‹!¿½_ÍV%–ÿ~›BŸSL€Ìós(P°MŸœe<¥YPÅ^hª|É‰‹Ï§
&¨mê£Ò¢wÀ*Y5W&rÙ-jxpŠQy§kB¹I^ª)è¦?*²ïå•”bN~ ar5MèK2ud‰×©ØÍ9û¶æé5Á‘–Úg÷)·Hƒ’›,ƒë¤â8ö€ ™*KzIí¦YÈà}8Í¤÷±Êd;/rM87¨æ— ©¼^ğ˜ ¯¸Ï@“äqX«àäÚİí˜ûwLfû…œ^gâ0w£¸¸ĞòX¶ü\¡ßàáÏÑF8v”¼$›;	d[´çHV;±wc™A‰ÃÓ\(ÆÊùÜäCrò]şº‹µ`TH*ù,«/dWÁ ko[ÆLD¥B½l×Ğ7¡¶ßPP&u²qi¼c70©B
øóËA!rÇ®ú™h$„SÑ¼ª–M)Éæ9\³A˜¢úV!l)`£Zô[98¥³’…>=†NŞùzŒœ¬4ø¾â!¨—¿?lÿñß@âc†DÖ}é(¶B*·ôòU &|¤Ñ¯6ıx&«‰ï¼¹.jœÇ`˜ÔBºLßåsçÆRæÁ½‰ze&5øõ’Ã‚2çÂ,·Á§Æ’ã°gsßÛ‘ƒ¬¿v–8¤¼³Ë´–Å(ëÁiîì³-/Öô3?wıê€Æ)ôêŸ¬Vğ(Š—×æAü…ß*ßN7‰Eµ‹ñ8Y®!a€H¤‡İJQ‰¾6lÓGøR1°P—ïK^¼Ü7¹²0W¯Óì”W»Şí)šÛJ‚¯^`C"~Şi…–ŠCSîŞy>¤¨nÚ‚¥%wlİóQ2MÿàlHË1-9÷Ú‰q‘  ÛyœCF¦óB'Dà­Ë0¸7Ìğ£‚K»GGái@·ˆ’İèûÑvaâlç©©ŞQs¼oÊ4š\€¤¢æ×*²ÙŒ\}Ù$£ ®Yl¨¥yDÕõ¯Î8:Ğú1Ã•
©S¡^ ŒÖw§[ƒûÖO®RÜvÅˆîàOq<VB]\öµPˆbPpR«Îáe«|¾+
„Ùÿ”P&y"X¤{ÈEØÅ3×]GÊş,ğÔ5%»û£²œQò¹Ù),ô‚Iô«ÇÉØL³MÓÇ¶9Vã•BIÍOx"•ø= ø$Õ'5B@†¨ˆİ(¡ÿ~ic,#`§{ÃÑ÷O5Œã=FŠ&¤T4÷B*¹K˜Xh vò|ÚjÖ	ÔÉĞmkÍu9¿¶§ˆËÍ $XÁàexKEÆĞ!6
wÌ‹õnæEòq™ÓÌ½ÉÀøjqÈ²Û÷dF1éŒµ>ñ«î´Ë0ıIÀçM£ûÛÔ¡âFcr¸-ÚÃ"l%@VdŸÛ˜âÅ¶Ä`²`ƒ€ğ™ !nW.Àâ*Í|ÛaéíUü¼uÄjø¬˜¼Ğh¹w–tztÛ@æ®}‰ÙBõwz7yœ¥ÚaSJ+”ú?‹$ÿÁ4üWig½&&
R*BƒkƒîÔœkŒÀ]­ÁÍ{"pÓ59ƒ8P ”îŒ9ç°À[§•ãN1[ÚAúúyù´eÒ{Ü³<ÖšCñ6µi?ûè«*B'Å‚´aˆí½âÎîˆ®´ó´—å&Š:zãš±’ KàÁÕSºGÉûP@k³åµüí-î Õ±wpŸÒ1–øsÂ†ƒ`Q~e÷ÔQM£½DòQˆ6¿Õ·k¦|Î°‚ ¸şøëè¹¢pÌ1¯D”;çs1s„¿™J2tÉ|ÿÕf ½»D‚ï+o	²Ş"-a$q×­¿“ V»Â–Û,G†²Òëèögz?{—ûL•á³¾;L!ÊÕ9:²¤ø/+f—Üæ#ÜM5VD°C¹TSbøóû¡ej^ŒAyËM½LèKtÏÀº€eÜzSÄ	[O%Ò6ğ¢´ûØ"İ±ŞA|oìá’0ºs  ‡1O»`®!ÛÏÊŠzkmÓ¥wg&ùŒMP‰¤¬’¾²I²C§°¡(|6Ù50ÍWnÆÒ‡#ô™¡¥g9•»N™ÿÖÿ*Š<O@ b'H†”0èKjÚççNöz)5:'^´“¡YŸh"FN9Tµˆ¼ 
wÉ¦©Q[—ÓŠ£H Ã7ªXãü17£¯Ê®ÑÓ{Šù­.£Ä:e‡®!Á«XUÛ"¬º1Xšé[ñÃòÚ…uzFC5xŒÑĞÆ4Fã{'   :ŞëòÜ˜/’Ù¸ì~¾Ş&ˆçTí;°Z¯’BËLÔå£}öÚ@½cd8Ï°cÒ›?r×¨~¶šæùm6l*tb€¿`É$vŒëÿb™"¬^÷!&ô€ø›Äğ·Ÿ:ÕòÁ­¡GZÊe•k„Â3/á•	–V6çğ©p¥]¼W5öå4î×v”[ô‡È-¹»:æ™ {qÔyC>õ‰Ÿ¢Ÿ³ß´#†J/,¬d6RÿºÑøøß‘m]€K@Z—÷4Û²™MÎ`f{ÍÄ· Æo¸ÊO5oüÍ6
,§Lww~Ê›B,_‘ôöÁ¦J\¹äÁ1½“¸Õw†·Ù[X5±‚Œø5¨4ªê°u¦&¥dºÓ [¡İoÚ©na»¦ÆK¹BK|f/	grM¿œ\‡³Î¬Hè‹ja‰F¤¢)¡ı[<Y³™Á(Ñsë'‚³àı“@e–uñáÚğQOs…M}ùnè'»ô1‘ÛRù>JØh
Îi~åİŒBêÿ™}a9uñ£!“Nb B¿Wía­™ûwáe	d•J3¨‚yÛˆ˜L8fY(©ú»ùÍkÇç­+ÔàŒ4 |&r|³…êA…³³‘Ä²ÁÔº]¬½÷­C«_ZöW4lËûƒäáÜ ğhò§l×4@àeo´¸½~ÜYq‹Ûg<Ñ•ëEŠaV¬ˆ¼…r^şı'U»ÃáÑòû¿…ñÍt£§ñmAƒD/Å¹9Üyâ¯§>ÁbÖ?R[TóÙcÃ€ÖvŠ %¥rşÊc6¨NIn»ìúÓıS±¨)²~1ñïOÁd³w-zÎŸçğ­[q"–U…Øj1Á¦¢%•Dƒ¨Ï+Í	ÿ%gÙ¡›F	2`’z½¸rçL
ŠbBÛ’s”ÊèFill÷õ¢H®»Òü¦Bƒ$Èó ?TFQyÄ35Ù4fO}±ŞàÁr°ÂK×~´é=D^× áúrÏ4õ%Ü°ş‘N€ìR+á(ÆFz Z‚‰êËUJõÜI¿×<ZÃm•ÕYP¡aUS?Æ,‹pÕ‹½D
ú‘µ%×ØÜ9¹AÀåuLj§îÃ’ÿ8¸g;ú¨7·ÓÕ7(cÆ¸#ëƒ!¡«ÌY ë!ñ!)={ÙÛèá;5ÕÔ£nK@¬ûà4p½4y ­(Æ×´©9>¡zŒ‚¤çÂŸ®åLnÜá½İím¯u…1¥iÃ_“šŞc9/Ÿš§ÆËŠf-% ÒJ¾¾gZ$İ`ğ°Lq[ïÈ>…¬™mÏƒ­w0Uãæï¸íy—JYş-`[ë!c="’”r6Éƒx“Ì‹~ŞÿbEcSö ¸äŠ„ÄW0EsÖb{cËµâØJFÕÍ6«UóÁûÃÙ¹wˆÀná)`u+Íä~–n:â—Iåf¯zÕ‰™‡ìu•¸¯T‰ßÒÙ\YÂúÓ5mx¿m#º˜®=Èİf!Å„Åq2Ã¢Í¤ä¢q@—›s—İ<Ú's` T,3)b2)|Ñ:âjü²g`&8PÃ¼xXÖ34Âùì‹Íbº®Ïî¾`]é*×}¤ñBTÌ´LÃZ~úA©Øú€àró- +ˆs&Æl&[(Dæ@­ÎŸsÜ¿k]¦-mÌÿ¥ˆkÂ]¥<G/ó³—<<ü8¦pà,bö ²Â Jú…ÜlJ{â0Á‡ŸÜf[C4¬¯ØZÑ5co©€Û³WĞúôNôCò(· ¬˜ê”© ‰¯jÅ·&ZlÜêMBKğu´¸©¹€OÓÿÅŒïîaØ¦ãiE£‹&úØfb˜1 _–Ü(m`²üÍX –Ê(Ñ	Wîãã*¨:9”|2¤Cá/÷ñÓºÕ2ÊMÓgE|7
ĞEäêã.E'mT<è¥ƒ4°Q™I«ıR ÷–l-†_÷±o~ı%İM¯V÷6˜!àÇç%YuÔ’ı6ì&™–ÂÔÅ¶3o†M-Kº´£¢#ºcYÜlßÑË$š¥®lFëSœ,:®u‰«ğ©ö˜S|¢ b¢Ğı“cğÓ˜#Á p9p|@ÖMç99š½ç
öPL­ïæÊ®3c+ƒ•?Ìûë')@E›HO_DMO•†¿0`[´ÛîY7H.VÅwqi#ÎÃÁ.¤.?ÆºK^Õb9œEwïdßíxb—-Iî;šÓ+ıºßbk ~‘DõÂıÊÊÍ§¼Û’7‡(CG¿§D8«M]ª°›Ó½Fº|Ÿ9èºEtµ°+L&½#WÈüvšlØŞX² ;óìOom<ï€ÈJ÷cHM‹,ËğêÊGÚÍ²b)Qì£1)Åròj
òçwR™$ÏLƒyÕ-äœ/)D`ôšXí°'_áÏ.\Íi„¹%OÂˆğgA”•g²oØ®•š•ˆ 6xM³¯Ú¹[†a'¢å^¯{
>´[÷êI‡g_­dW,Š&-K€³^ŸÄµ(éº´ø',¦_YKE’õî8PA<îaÙ4 ³ƒ†!û´ª®¬¸›Ùö½Üaÿ‡°É`Y D1™£AìŒ¬*è“ò÷9°ä=´£û8à+‘—½‹ÚvDv¿LÿRé­¼;ÒÓõ‡„ÍKÏ`’–¢WÅÂ^hcQÉå*‹%y.Jh\7S'9“ŸŸ*ÜĞ÷Îƒ\Ÿ1]ÁDl&/ív¹O…ÕÅt›äØ{haÊ-_RçQnÀ{qOC_DÚÀ×
 çÙ s$•hĞüks1Ø€[çÜ­…g:ØdÕ|ÔXF{IÙk;Ì¤ñG©ã—Xûj/–ß‚‹›Ì?åê'!sÄ—Hj”æU@¥;X5ÿ°<üä¨dÆ[ÜâùúWış¤—Oü.†ÛN rAØ·7æ#R½ƒóBaTë‡F3×»¹!rï9±tx[Uş¾WR……Î»X5)&jÕ ¾— -ağV ˆöA[4tÏÇ÷,Î´x×—	ÏµV\'}ì³z%Î‡nac@95İÑU"rŠØUr´îåàjÚ37ã!áØ®2â²ì$¨JtrŒdŒmTê
¤qĞ‹ĞıÌŒ~\ô˜f   òÿ‚`ª# ãÍ€Vïd±Ägû    YZ