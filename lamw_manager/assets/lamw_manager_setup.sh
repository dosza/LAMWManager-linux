#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1660892552"
MD5="3b088551fa72b69f842c134b1c512daf"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20760"
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
	echo Uncompressed size: 136 KB
	echo Compression: xz
	echo Date of packaging: Mon Mar  9 02:45:12 -03 2020
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
	echo OLDUSIZE=136
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
	MS_Printf "About to extract 136 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 136; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (136 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáÿPÖ] ¼}•ÀJFœÄÿ.»á_j©4×m&&}×tıÎÊÿ¡V7Fè,‰:s×ç„AØáíè%29q¶Álìåwô½ŠÒ¡¾‡è~ª#àkCç§
kQ*¨£øÇ Ãzg¸](ñÄl’;¥Ã˜îÊµB×Ù=zö¼– UQ’oÌÙ×~­ïäºß„|ÃÂWİ½6Ğqc]ÆÜ©ÆC›pn=ÖÎ9,útÀjˆCqÓ-4Nó"jÑŸ—‰• Ê ²{l´LÚeªñ4Ìkí„6¥7ƒ*ÛÖe@€›4àe’@Y;µ®b!Üéï1¢=ıq)>¤´õ›£2Î;JOF\¡ålê¶‹Kg™zv•Y*=õï·‰SâÔTĞ.®¤#çgÍÖDûò/!znZGbüØ»ÕÁÚ‡‰x‚«ôHQ1Á´œ üöpÂYª>ô4TîØñª„ËšE—It,›7-=!Ô>bÙğa:²f½@_-J{ì€Duúw›Hô'y_½¡p“‚Ü=òwù¡¢šâÓĞUòINF,ÉÒ	«-I§Û+¡g×ï_ç_f¡Nç´÷Ïû3é•§¼Cø…e^H¤Ë=¬|ŒK Nòœeã‘{dñ#ÃâÜOyÌÁ!ÚŸúá(ª…ü{ÿ…c†hÇu¨jğ¡$•ÿöÊeWøÎ	ñ4Şó&œ™Û[ì<èy‹wÖÀ­í'.È¤Šÿ™Í2àcÌe^¹7¿ôU.ˆUËŸà=EÄŞ™k{Üõƒñùitã¢»à¦ª¼»Î4N%#‚¯D%g+×ñ÷ËgÊ¦©b²}fV¬5sáÆ‚ğõ‹
øs×Ö"ÁÉó–›N6Ï>ãEË§mjŒ±ğƒE_€—«Qå³ÃŒÜ®ŠPÇ]¿•èÅgvÍßoM_Gh/ÎÚ(Ç”‡ãVÅ¦Ú"ŞÕ0¯ç+’o>H¬L@§N	¢ÓL|-›R2ïH¡’4¢Áâ—„’Rs.)î1e¼L¦ñO gúM¬Ÿ#?`©Ë–ÇÌÙjeĞ‘%É¡jßê’ØÛ¢¾ÆèÙ%$¤P ,œ°É‡q‘ôy„†H#ŞõŒ¯†D¼ÁĞ=6R™£s%‘ ³Â8*Aşávf­¯S‡ª¤A½fç<”:½Ù{„ìåqr¸šVÛ±jŒÇ¥­Ö·úËwA¹ÇSùWİ7Bé7šy«š¦};O,ã 9ŒûÄ,„]Bø±¬6œ˜q°ª?ğrôˆJ\££dµ7æ*vé³ÁXdT‡„Ä„jÔôº¨Dr4K+YlàºP8)%ï“'¬7Î8j½Dæì0¾arUİ‹˜y¸Ğ²ğ>Š;’ô—ôÊÀ7¹ŠÓÃiÂÓ6‘DfÉÚ¹¤£I³Sëlë¶tÈæ 5q)¯qı.íÌ9@ğš*XÂşÛßœ­9;ØCÿÏ»¬%òp¶ha=¡f	gx›ı8=‚zÄt~KúE‡æ¯Ãí>s&y3	±-Ç	Ìº&¢TF0×\ç&)P†=rp|o›4WÉÄPÉÄ§Õ—ßm \Âè	ÛÁp•Æ÷ó{X6uf8¾ä´eÁD”pšÚñ&ç÷ÍíŒÇÎ(ÖÊu9n—xERgüAìØ7SËoŠ7\`¯û¨QÕN’eTnò›Úƒµ%z©ÓeWºYh.oÅ™Œ9ê`	_Æncå÷üäårc•¹­ŞtÛÚ ­â,t6»C%Rl;ú0YïJ¦­€A¿7Êf6ü.×¼}ì¥çëô…Oh«”ã1™;mDzím’M>´ş¥ïF¤êÎBö¼÷C´.2+vî2íòïø3%âúÕS™$Èób9àAÙÈ9vıÁú„‘Œè£S0A¯±ÓAZÈÙØs²º}V©úÂ~œiu“3ö´¤U‹‘;,Àl|'æ`h?g±áhT•)«Î¯®AÅå·\„.6lĞKuÎÔëx<W8ëñÑ.G¾å@+Xá:A•È´ ØÚ6m2§
çHÛğÖƒWøÊÏtmmZå©ŸÁÊHg\3óÑ“§>„Âæ9®Û>ká¤ßi©8áhîNâ¢Ò~|”À^-gµ:İ„ƒ.¯‡ƒæ¹‡Ù¬ZèÅ‰¹f5Ë„Tµfå›ób·Tô\#KŞÿ	’0‡´\ƒTd!tÇ·{­	0jÈ¤ø¼~*Hğ[ô‘ ½ZU	²wˆQL=âØ%AB[¥f.ÛÎz¼>ø=û¾³Ôˆ)#chm HD¢}~İîí±¶zQEØÆ¦¥9;³=aÇÏÓö«ÀTNG[«Æ¹’/âİÇÑ±õ$ØÆû„_·#Ø#Ä„m™líÊºIg[¯rïµRÿXæX^9í®ŠöşËÚ@/øHÍ,[ğ=Îİ$‚M`vÁ†VÉÍlõaz×‘›ïêO¾n /„Nªo‚8»ÿ/‡uÒ/øúıímVSÎâ–yó;¤ğ’t?~&ø°pvK0a–Š9æ”å2ãwª{ìîæ› Mûvª»Å	-““^ğ‘dtÔ1@A!àÎ›Íí•¥¹¥!ß…9^àªğ“|[¦1„ÕH`‚ìIŠLğÔX#ûH¨ºrJ°¦ªÆ!) ŞLö¨œQû¯>(éiIÏQ•Ó
»¦Ú
oëäÒàLuŠH´wC¢÷?3eòÃ ÷µ°¢
ºñÑä3HQ;»v­€[nßWƒ¿şG}r,TÌJ0›â(‚	SpTÊ.­¨ãRŸ[˜m÷Îƒé}7Òç‚¢ÿU"•?cµ4ãàı¢š¡ğZä«Ë[rŞ^Ü¿±“š7O‡Qª11sÄÅ©¼$sJrXÂéØ•r¤Ág°¦Œ	‰Ÿ´ÅMÜÜ+¥“:‘pòşèÙk[kñ¦e@ ìÒµJ`í×	{a™wÎÃã*
1¼Eá—“³g2çCæŸiå¾û¾/tş“1Ì#¹K¿"o•Á5“(Ş^P‚,1]åJºÅ®§UzªÊpÅ'–\Ôøq†›¥‘uÌ§†hP“á·BšJã ÂQŒ{g´EáWvt9ıh–{F~JB¡ãD‰†æ-DŸˆ,³0A:†ÿè.y{†Có«j.ÈµÒå­	ÓEÁ¦p™¿»•§¿ZØÀr"b‘«‹Æi¡ÜëÈ3Ù:Mr0L9pÃÊÃŠ5‰Æv¡ƒ¦kª"1¶³ˆQ×teÎÀéû¿Çp‰öj-ÍZÌ,ÔAÏØğüŠ²4Üºâ}4_°ÍÉXÕµämj4ê”ÍæÕbñtÜ˜é«ï8âXuíƒñœşÉî9¥Uâ4Ê÷oèíÌ¢]'Y<¶Wö³¤ã¿®Cš¨h7òEä—?¸S´†yÒıëâ§?wƒ0¦e¦µ9k¿7),".D¬àôî¬ŞŠ$Ó d¡<ıˆEĞèaF‚Ó$ZÉåiLR×€XS¥íœêµ'õÊßõˆı‚íÖyù§¤¸#ğ–!l6‹HÅPEİS„i=Œa¢×“õIÓTM«1
%mAê”;ÑTr¯UMù„àÃãuª¢KòŸ¡¨îª2=*b¸‰%uòƒY²²0n·-Ù]XÊ&*!k¾–$4ÚéBĞ–-±‡LÌ¯œŒäLÇù¾Ó†teI$K5X<\ïÌü·òAÏËš2¿ı_«Òó ¡'Š¸¼€b£ºR³ÆÈï³„ÁôàÓ5uxDõòHŠ·GMc6^Ì[B8¢¾˜Ã„+Vc×.Ê-{&ìD€‰Ò8
@J­L$ÙˆO€‡íb/i+†·g‘¯oa.¥EcY$øœ ºû	HÈîÎàÏ€Z¤®1µ©ô÷‚tŠ>…Kr!K»W,Â¶g&¨%‚A±F£âè¡)ìÜ„éóŸ§ï—‹#Åóå$éÆ*Ì¿7ØäyÔÇ¤£ñÄ4Ô3î›"ëiÚ|<-²4›gšË%d¡óŒõ&Ö8)z o<ÂˆKùå¡¬KWòD-Wä`®œß-q (Á;“ÌÛ£]úÒ´X[ômöÆ@·®*+÷ú÷DJÉ«T¦sÕ]Ù2ú†™¬1èİÖy°ç²‹á°‰xjÚ°³ziùpšÁÎÎêÌu>îR¾DrU{2kÑfòôÉÅ2I6ÜÍhEì­Gf^×R¨WwÅæ-=ÖŠâãK•6A¡ˆo÷˜‹:y ÅÚh$Ó™¨¼®$Åï˜Q|3İßlJNÂ¤İì8—¨¨eçğèó ¡{'µ–\Øù™Ê¢Sğ'™šX-ÿ>tÜÖ‹ƒ„ÈVp@%2ğD›V¤µ+7fRA;·çXczÛ2‡*X‚Í»ÓêxÇôY@%)ÙÇ¯Ğúl©õuÒ5rŸw†İávØ˜ÿü„»,Öm3ëÃÉ®Š	°Çr:úuò+¨Ée!•›µhrñ¤ËZB–`Ô'Ì§e6š³ÂLt—ú÷#§Êä{Çüíƒw4 ×ü§°n Àšyüc¼ÏÃé´ß/j˜Eîƒ}ÑN\ ²?yô[¯;{­Å9E_œLˆÏÊ°t€ß…æØ˜wº tX5ª’•E	BZOItrh–ş‡é¹è-!q+_·§±yâVGşã^	Şe’ÄÚüÜ×Ô;Ãëw:F¸uU¥„\º$W¥Ô]øƒª¢èğTœ€´S#šU:18(,mûFC9Ëô¤S;·AÔíSÏcùös„t¢#…á]JIÌ•®ªšaà€ *gÑœ@ë”‘0£˜D=>±gn¡·é¡lÊFV—óøQ9{Ë,PF™qf£åSæñ9­¦FòOõ}ãVUã2½—q¨•œèÈËøµİ–\b8C!áÇ½"NCØ¾nŞÄ5Şí’±N¾ğ;›Œ‚Bw¸Ñ	—:¡Ï
‰½©?IíB6Ä  Ál¼¶¬íµìI(\LâR“eÔ)„›÷k¨õƒÆ|Ë;˜‰˜j†Kı3Í»~ìÛÿ;)EÎ
Ár¨r4ø±Æí<¤í“<¸ÀTôaæh#6ãFçXë4ƒYWá•~–Ê"+æÅÜH¶ËçûAíj:¸µ#3;ÊL?HöEWqjëkI•²´7†²¿˜ß="%<€jÚ%şaìœ³Y¸}_+ÉÀDêiQD~Z +Îîª³öaöõ&rÖ‹H"lVŠ	S)s™e»Ä±£Ó£ÎQVîµJÄUXü›=ƒ/Ú–®eÍ¥ŞqÏ6Õ÷9cš;âúNŒà Ï¡ô]rç§‚2®lô’w7Zœ# Êc»Íjfè,¨_z@‡…’í
å`;vç¶ÒmwoPï¯×óQzmØh*[†øô@Hgg Õ¦¬ãÍóşO¬;Â*ñ%>ÑƒDTwâÚ<¸2G4o`4ßhƒ³ÿgPÑ‹İ™+ì{¹‚xÎÀ|qğè  ?8hô"nÒ%»Tª‘y'p¿ûÚ!õìÒ‹:7«%¹ˆ	w“ŸÇ0üeg  [º]•,^$h9´ÙÕdN vFrV$‚`÷ñõ~N /‚¢#‡:î´&úcş›B6˜÷¶w¾”Zï£÷£(y•šy\JôëôÅn	˜‚İ¿¸Ç¿P¢$'×Ø[(Ä$£}½Æßé¬v¶ªap»í÷ƒiñ¥No	ÄÕÑF­Wa¾ê¦_šİãAhg¾$³ü@Ö~Úİ
»™7qhÿ³BÜ
	*'Je06 °ıšyöLÈ÷úfı›ÒĞpÆ¤ì~…bøÖnRaØ–ÚÚ½¦6ìÕg·C½°ºÕkò0¾}N8¢Şæ®*—ı•™›A5ÙnV…^„ƒmç»qİCØ=:MeN©$ig`î¥ØÚYfnêŠîü¡õ/rxí3²Ş’%©êµ÷´y×}ø]vGøÍi|‘ó‰‰
˜/2Ê,¹¢cşÿí>HWc¬èéwxføK§È>'0ó5¸µ_Üˆâ!¹~\Pv6Îµó z7¸Ö¼E…«ªı¥wöb€Tÿ<CÙ« ò­K©RylÆ÷«›â^q)„P”±×wôá?¯Å‹E¥šÖ–Ø6³f×hT¤òäIéVÚ@êG\}¯“O[ØÂ'ÃGV¦“Ğ<àó=
 j%À)Q6½¸DZoìm2ø ›6Š„ä¿¦Ø˜=ƒV¯ÚÅJ‰ºz¤L¸ µ}mß:"Š¹ôBË&äC º/@(ÌT-ê*®eòİøPz»9Œ‚%â7A¼ o¸Vô–õş×án²’Ğ¢™×$6TÍÎEG±K„µA£B,wÕ›áÏL—ˆ Ö!X&Õâ¥øßf¢6yátB"ŞÍ‡D$UèkG,Eİ½³zE¹GAÓÏî6­†¿*j,¾)ô¶ÿ7{u8Aº¶eø4Tè™æ=ZŞm;%úbD®´iEÜæ»?v@ùxGıƒom™ª \ü¤Ú¦‡FıÍ˜ö–o¬”_-®¡şk³ÌÓJ´]f–¸pg;¬•3Í;8¥ÚÔn{5ƒ¢7jˆ›# ½›8À˜gøêˆà79ŸÓÎÎÂûõ´@R¶d•„‹ã£¦¤q_Ôó³QmV£º¡Ò'pCd¹-œMŠïU˜›- LzòMf‚arzJ…ßœŒ_ÒX…ºİX!`Æ[¹Ğ¨P
%f ö„º'&*Ÿ©‚ÉÀ¾!LGv‡wÛÔĞ§ë¶Y i®“´A$‚1ÿ(Ô'$˜–¿ùa¬>ß®,¨)Å@E­P½éZz)µIæ€2Ó¼úèÇ³;,?*éïã¥5é:ğ9´Ç°†š¨Ü~#irùÛûæÏàt"F"ÃÏIg{,mxñŠÙ€ +,’÷°JäAÀòÈ£„Éqë§)Ï»¯®ÙJmîYëæú`'‡©ÚòE‚½fƒ³ÀÈ0ËLİÑ¼/×b‚%_XgqªQÉ#”HÌ&u™-İà2:»æö"Õ–w¼B+D	H	.Ûâ^z‡îÕéí£ùŸBÙÊsKíóÕ¹‡ı‰ÆTÊM£¾aSıĞâß°µ¦¢	³ı5€
 ÚÏ‘ıü°	a[êBäœ«a/¿°mëÂ¬ÎÑš–Êü[ñè¡Ì ¸ÌÜË¦èöWví ã”“—æHK.šÕK¨˜ËWXÅÛGp	Ò3'
Q¨y@SHBxJ‘W#§C/U|%;·¢Òfe<÷ø+I®UE×2M]Õ¡yÂÇ]™ßçŠ=ô0â˜á¤Ó
„l>Wk\@•Œ{Ùº¡åşZ0\?oâ)à“îÍ{pÌ€Eâe4g[Ğš1Èió†Òipï› äó?!±4‡Ã¦ØÓıœëš0ƒ¤Ÿ±SÔ7ìÒû»Y×0©O›:3ß­ñŞ~Êœu‡—è‹"D¹ç\±À®³™z„†ÿ~ôô)¶:_EZ@'¬|ˆÇuC¹òçî±hëøŠ„Ü¸ØQƒ0-íx!Ã_îß=Ò5Š!"hºaÍÊ`+Õ“ëÙùb¥ö~çù%­ê]‚Ôƒ‹™=%§V‹A~E,ï ß^—Iª×R¿æ­eÔ‚ j%,^
 º–Æ‡Üo’Â³_#µğ¦^mÃF”Q3¼SSŸXÂà
:Å¾¯;”€5|Áœ!p=[—ôùÿYÎ~±#ª-¨ dhÃ\r”€*Ÿš0É7êåŠæ^§µK\Iëhw“hşøœ®¬èÀÀRtC¢`.p\TJ/|D/».±†Ueÿ„o0ÇœY‚o÷ª+ºªE§œ«y2ü™|E?>L(Dä±îoôÃnqÉÖâºG Ù¬yÉ>Ér¿yaàø±¬õçUDíÉ%Ÿ›_y‹ÏZ‚,˜%B/¥ñœyïønú„oU´æÑqªQØüL½ß?W.qıYG5ÍxMæÈöDø‘Ú|/ F‚«§%OéíLÜzÒöh¸/Õ ”Ùõ8 ?i:C÷ÂEqHÇ›áÌ"åwöÈ=—W\cs>Ü®…õGòšd¡+Ö<PD»ˆfÄÀnuğ°ÂiAÒ¸¼KĞ#Ê×)u+Ù.®Hæò&G"ĞDŠ'Ï³‚KÀÊ”6]-~:7qlûfÏ©™»õË…(_[R­\ËêF)pø¦¿X´{qÜ´Oã¶=³ÒÓ9òq#½C°«İdÏ¦x½ œ-©V¯X\c™ÚÿÖ«_»†“Ÿ6J#%O[ÅO{2ı-ÙíÌ½†BŞä÷#RÊš9ÑÚ'UÇÍ‡ï.÷à•‘ ®^;pÄ%°%­¹‘ }Ä|Òq D§òoêu˜Ïœy6†ÃŒÆdyZBù—ò°’hˆĞIÿ~¸{‹¯^vˆ<DİNh3–¥ÃûnêfŠ6BqV8êC÷†í[¡ÂD=ª:ÈŠú~.Öüü[bR¡Ô |£à9ğØ×ä‡Iîa‘ØvĞŸÊó"¥Ğá×?+Ö'u{-¥(ØO+P•Æ.ü¬§1G.zîI¿Ğ>’ö‡’x5D™Ûsş‹IÙm‰^“,ĞÅ«—»¸L"dË™ª	÷IÄ³júmIƒÔ:ÂÃg‡Õ<×7,®r–ÇğNñ,ŸË±ÓStö¢€<>vâªq‚äå} ¨«ùtÄˆ½6¹ö”MqùCï¯oXùGÈ®óI˜åŒùU*^e‘•×é¡3ô¿Ò¼\­oV!’Xj1²b·Ï#É=+„•
§ÃÒuæ§,iÓ^ÜRš?Z@i PÚ,Ò´×CÅKİÜõ¯N\óK*	s_Ùcft?‰Ó%[N‹ÜÉüsşRÌœ*H¶öÊÚHáó°Åm3wj™éB3¸nÃ‘Ğ¬õ%yû½¡¥?¦ÃÁ„À³İ"F¬äT´3ĞµùDıúyŸ=Ã¹–~˜¨Ìÿb3øÜxŞ÷f`Yµ?ÙêaO—õ³€Âkµ¤Çõª‚)ÛêÑ™
¾yq•
'	B÷ÎJ-õt$’ÕkÜ`Æ¥ÆÉù k3é†<ö˜ù·;C+Yvşr“!ÿiv=‹NÕÛ[tEEÇÅ¢ı‰Z2oúu§®n+ÖÁË*‚qÌÙZDW›ÓA {°}õ ƒÓ£†»b{İ¹B	tcöç
ïòÔ*Ê<€<“Æ4¹Õ²­Á]’Ë«Æ¹[ÄKÆ¹
¥º4¨fO:Nû¢}äP]Îâp*Â×<ÖÄ&N87¼Ğ;;‹’¤ÙöÂø†ÌêéÕõM\…÷ÎÄ$sp®§¢‘‰Üº<öy3Ç>æ@|,rÕR¦ãá´¡±1Í… h6_¬ÖÑ¼*¹Şa+ıUJssæmpÜ‡ã”Wñ/v‚²—Û¹â²Aâ-zß9‹s˜†v6lfgÛ1h«ùËå¬Š¯»¿§oz>à-İè;êÓŠº*,&¬Õ…°!ª8'“ä3<VzO:jŒP(Š]lÁ>N?K7}­êægÅdB¥Ìó&ùD|ÿ_+ºu\¡sJV•_}ºL)êü3(:ó^XsÚ¸¸OÂÂ F³ŞYt8kŸB¼-`Q‡Õ~ HÃ|«S>áHAµõU¸¥øljK„1O‚”8Š€á‰¸ Z-{†GôÇ#´»BI¾éıéŸÃI¥N"‰2ß\FÅÄjPß
âù¹„ í©qŸ0}¹5›Ö†ğ 4ªÌ›iËÒìå€®ñóçÂ@Rè®A m§š®>œ] Z{(ÙÎ(®s“–_üËmìZè_!Œ=¡G›rSˆ³î'Î)€Øß€ó°Â>a¬•MeªEÙ_³ÖÏcçs””¿ôˆ¯æÿÌíîšíĞ¹ò|z7dË‚¤`	á«&°¡!ÁÈğh&ÍjÕÅIõëX‡A`²H•>ˆË8ìŞ£ª½(³»°>ĞS…mhÂµb·Jè …H ÷,{\3”oPP‡ QÊ¹5NèöÈ}Á¼ÈŠ}O‹Øî}3‘ÂöÎébÓAæÂ€^az¼–7©µnMğÁøŸVXé•£êv41º[/>ï'}CúŸ‹eÕ%-ÏŞı‚9.I¼

¤™A6QS*Şk:×î¿''Z=€¯‚ŞÅÛvû¦%O»Õ‹?8||~óBUÜL{ò»qVäğ¦Ä½üûÔ‚Ù¬/·ÿ…2e¨õ®à™ÀõYy™²n
?¢DB›j6ê€ì©õa-ş±^µ,RP|€USµøVÙZB»îI:‰ZtìÛ.P„fÔP†÷*ï
øOU³Ä>:`@ÊV„ì·—^˜©Š‰Î¢M0Ãk(¿ta‚m#ıB€êË¿’Sr5B[^—ğlú±MºV¹Kj¿öÍ‰âW²ZœäH}RÙ«Ó±+X,Qá151êS1ì;¶¨< <ü½·å0:‰©nZ@ç“îœØõ"Ò]ğ/ŞV{ª÷'Âeß¶f»Ãã0é¾TšECğ5½ÛÁ3Â}ì	£Å#7ë:&:Ò qJp’µPdÅyo­zù®ƒ£« qV}B²<ECÛ¡Ö(.Ú?É6mèÒ`Ì|¦y`¾4‰ny%‚y-ì}…ã¡uiêæ¥±2…Çy¬0 r']xÓGò)4@Õè0±P?Ï×0RÃ-‡÷YßÉÿ#¥Ö:É>Õå^YÕ% •>³¿Ø}êµŠË´¬x|®zS2ìMANµ5¨íÌyš‰QVî§ªvãÊÄ—¨²ìYeòõgì'Ãuâô¬úêyÒ³lÛV‚óVt_†‚è~‡”zk[‚^N^ÕhWBi+h×0¶öñwÍ{ÿÇòìwË`›yŸ5n,3úu0a «O‹Á¡QåH›aÜjß0ô¡¨Ğê~)k»—§Á=:À=|"îÙç÷ÔbMkÓá.€`8êÓ¸- ¢ÈæÎœN‰®r6v’qvõ(ŞB°g(•D#—`;tÍO¹¹.<²ã¡|ş/m§9(7ÀWy  t$;/?§C¹Fï>ûì,õ©äPkõÅ„!Dkb«cóCú…)Áˆ	²õ{ß³‚¬‰4êåÔÅ{¥ıÎ;r”ßaç£¸´ği&¯”(µx€ÑkûJ7Ùl a—‡I<»ˆï[sº“T¥„@A^½¢?=Aûu Eê»i‚z!Pw›‹#"T=ÊÑu¦dMâŠî¶oQeéË¯iQ´Xïj6š|Æœ[=¤ZIC…ß!ğŸ¢À»*|T¦c»¡ÚJz{êÔ]•û0æs>‹Øp.£%è¢¸ËUw6ti	¦·:k¾æVl-Ğl½€ÑBÅmTYÈ¤’˜¸ÿ´¬‘ğa•Û-şÑ{3‚ú·34{Æ”ê³ğP¬Múg¦ÁşJR·:ûé/ ®q£‘èßîÛû£Âgğ²Ôc`Ì€>Ûİ·I<‰KsHŸâ%O@Ì ùW­²‡´ßj	¶¤by]QÓÿ"‰UFYâ¸tÕ’Ó	ÛÎÄ–4HnèÖŒ©# |µ¼(xŒe\€TÒR&¬ ­ÚÚûÓæ/¸Œuú^Š{´'a [UÄcæÖ_fõŠÅË²y1“dÉ—;GZVÏò-Ö~Å´ñÛıJßF	 <"Šª†ùJ‘Æ*·j€ZÈºpNØqçüG,ä×ä"ka9Cõ©/¸Çn\Ç0µ£}ÏZc€et9ù-òAM¨t’¼c,Õt8ôÁ@ÿ¬«ÉMÛ?L;A‚å2:Æ"ò'ÏB
®µ‡ñô…ÿş¨k8)#º#°õ-íäÚ¬‰vÇX>ş~¶$œ¡6˜=hM¥0¡yğ€…!ß¶- ?6±MYéb$€”ö©>Ğ†'t{›ãk@‹Õ(İWÎÛKùøpËTI>Û´Fîö÷æ&òÙš­0öÂi¹.³Ú„åˆî
Ã›FYQ‘5Ô˜Â
XšˆĞv"®ñ%+ªxVWLñ³¶ €#‚]¦·‹.ÿÎ~ü‘¶Ñô0ŒÕÔ…ë=±(=&ğ;Ç¦±‡Ga0IÄ.¹İØÉÎíW®ÓñäFÙÌ‰]¿%.°¡@dÆ³“_À(’ßC+ÌÒFÈÉË#'% ú–Šqí¥Üı³ÙsfjeÍ¼‘Óq_Ã(³í°É³ËF’˜bÒnœN=iŸµ]ì²XÛ?K¤<±f¬!+ éCk©á&ñÂ5Ù/kù
À˜xê"ÜÃ2‹„Ø|)Cá¹°ÌÍíôÒ©ÅOGšªöj²á(xFJÃiJ‘l´÷˜9»SİÌZĞ˜ËªY^¹¶¾uûAE,Â‘Äd£Ÿ«ß Y#"ö-àPŸÍ¨uxöÄ‘'’v$¼…ewÔÔ(\êğ˜©­»O<7NlÙfdŸÛŠ£
†Ä4>Sİ8i°Fòm~Ãš¿zµeKš–-ŠãŸ5|-jÀÜFáó=P-X¾^ºkàG¢ú—G$c¢ÚÿÓK\‚u•éaSFË2Y	uÿñ×BV‚„¢*Ÿğÿ Sºm~dAJÂ;Wy DLÔ&UİáCé×rœöí¡^›ÖùíîˆÓ–jp Ÿï¥¸¥Xì/ÆÇS3ŸÌ¸-#‰]	}Œ9•Ş21u¤ß9à20ê2ù9f(VIuÍ1Xë+“½’@ô¿¥Ëàœmx˜+Y²èËn+ö2†ˆ¾Èë6%"€Â©aîÁ¸ë£ƒŞ¾9@À	±-à°|aš`ÉàÆÑG<ÁNçïı\UhÂÀƒĞÉYõÇ¤÷/şÀœo®R^›®Wø&ş|= Q~üËPµÎ"p}w€B£\dÈvïª …çªTú‘j>*F[KÈê®äÿmæ¤s@ÎÕ0=c’Ë+éœñZ+>‡×ø,¨dßˆgóSZœÇ•¸+´«$áf)˜*fÔØ–å¦ğ™ #üéÉÖ¨¿Oˆ=°]¹ˆ—ø¦O³ËA]Ğ¢y9¾­„C¥Q0ü»hÏ<œ ánöÍôÚğ‰àŸGÖy÷›ıu½Y§¤£¼””·Û=%ù[<êë>¯aÊD„FŠ¬{¼x‚®hÿœsš?øB0#79:´ÉhÂ­M3Ÿ/ƒ¯Ñ+‡£mƒN]Í²âN÷ØæhOsİo0¹û¤ÄúàåR£¤+å7SjmhŠD-o4
íVÄæ¸#ı­yYñaÇe„?çìÂÂ²©jqô-J×™H“„@JåDs?†÷§^²
Êì4r¾šngd•®âU¬Î D™’áe^²«yûª.ò:d›¢¹i5…§·ˆŒFzön‘7ûñy¡ÔY°XKú-@Hb:Ñ¨FÎ²­´U(ùå`¡º“ü¨QFŸM6dã§‰¦„<õ¨^cÁ3¢‘N²«ĞÈ‹œ
ìû¡µcMC€åPZ'´‚’üÅÇnÇŒ!APØM‡ÔªPa¼@ÖÎIÁ?‘€¯˜B”j2”a:¶ÙÖèiÖ‹_æë*ÕTtÿŸ€!ßÎ^i1_‰ö¼Ë÷€ø˜\íì”× *<(ã©³¨aBAøo.^c.ßsÒµ …ÈÃeûï<ó9Ø Á–†êŠ¨·×«c<ã‘äş¿Bc'd´#t:˜§–ªr}&\&÷È¤!|ÇYh‹D~L-Ğeô¶I¼Ñ6£jCF#oÆÈª_ùeÁia­ì4;€´„ÀÂRÊgÛ\´øîÍºe<x‘/Ä{Ñì5ÈÏ–~['L£óPœ,~p›0È8s»“ÚÿİYı‚ñ0´–ï/Ì¸¸4Q‚GZ_ÃºÄx?%ØmÉ	¶‰<|šúò2™âf@¨ˆB} tœk¢®ÏİÙ¯ß_Ì>ín¾î3áSºªyFÈ4CNó’:ğ)`¾âVdıÊèõ:Ëm7¨
1-Db6˜oìñÿ­dIGRÑ|³t”å÷#Rïã¦Ûá˜«GŠJ2>,‰Wtš5wË%ÀpâË6ÃH˜DrS{uÕ#|7xFrîCò4a.ƒu,µÌ=”\Cœ‘êù<] zñk®p0>²VªÑF·©‚ÉV9¯råóò¬¶C[Q¸¼gJÀø¼'*¾K®!âh`ø~|Ç¢´gùpÜršS3S#-Ã®ïÄç=pæœC…efì"û Aèxpb{á3ú«Ú¶„ÊÉm:"lT&xd>?Ğ98Î§Á²bW…æ·s7Û9·vÚğ¥Ë[âÛ®·óv–yÍm§dg7Cú4jËÎ2?Z
&`ÖJÜ?x5¼ez°+ .[7Yæ±€kMÍªËé²¦'ßn^·ÈûK_ìÍ%ˆ n:Xfz¢]‚ùÊk©ò¼ïçÍ8FÛ¤bX6Óoóİ
Œ‹|NC(*‰m¯ºy÷qÕ¡}/¤üŒÛ…4œ5ˆÂ]ç˜O‚ñ”jh3å%kMi±q|rÖQµÈ7d@ÒxPê—>æÍ›QÑÙ`ÖTÉà"QŞB)ÒCR9±Z}¼‹h§Ò‹›öÉ"ÙnD?æã „êµÕ2Ít°årÙ­,§n™U8zù]¦CÕ>¹6#šºY–¨l'ì	GuÁºOnôâ¼²‹õ(ÏmË8?>>%K§›Jœi<>çR[İ(ü~ì«o‘Iô¤ó·¿9säãÜ*C‹Í`o#ÄjÀél‡bwñÈñ/ĞşRámª3­wYG"‹—ES)ãA?éˆNş9$€-@öĞèşh®ÇVia5-í°nZ|h†I)=¿úÖ0Í)4¾7Âo9jÙ¶©­czÊzÒüÆ4ĞS’Aÿš}—,¼È\8õfOí'î´hò29ËÈŠ´T8lè·š„‡fkYÎj¸,oÂ^ıµÃøS‰ç|ğİ±§ô—õwÿ7ªÒ_”<Uôh~Ûà©Ä[e»ş¤˜
Ú°eÂE ‹®0”ëÕ»èğ}­Ğuš¾"ù{¦UŞt}IĞ·Â0³l¤;x²0Y÷(¦©İ¤%¸ÿLÿ£‹Ş ‡›¬t1ìÊAŒÍ®.ô0W	²0îÅ».¶‹qsÑ)4RêLß;á¶Í‚ZPNİ+§ooîóÆı ÈüŞl©&İLŒ(<#cH'o’aì÷»i4ßÖdü!§İÿÔì]Nğ°‹$øm“şö˜ª9ÔbuŠf\'Bœ"½/¢¸'qøñk§º£¯£}RÂ>g(Ì¦e÷ŸØm—ò}L‚5ñ–º’p2Ñ”=sûT ¦"5†Òÿ-ÂçD–;3±­ëä¼İ™ç S›0™ÖÀ{jüV¾—hÃóŸ•zõp`hHÖĞğ>gúêŸ,™§Ne½$ğ`+¼¾ïç`ş•ôÕ*©p‰záÆx÷Ÿi€@í:oÓÄ›êE¦	‡@¾ØÊÁa¯L€g)¦ŒŒYO²^ñl0KÏ(%è—^Y
ûiúøÌ¨K ãV¸˜ú=›tœjİÀñĞŠ9óø`£BÍ€ DÕ{kÓqt¡‚3c‹ê;}8>Á}`³İüø­€×µº!ï	qÓ úŒJğĞÔêÍmÌyâãïí]RÜ›JJù1]Ò@±ƒ°éTç$…šµ_8e«ÍU5›Ğ¯~ae6ş§(N›f2å=7coÀÑ3? ÕJÙxyUeT^‡#©UP9Qí®·OœT.R÷‹“	®@õlôÈ£ä=˜“¹‘Ô*ÓyA÷&Z¾P±Pz‹³`ù`R¿V¸úrù¥İo),ëæø“ZölsI’Úi4Ûşñ™Öy«‚Ğ‰8Æ½N™°Ö	ˆ“'k•Å%7Uî]¦j‘951"ËÆ½;K%LBÅGÆ^YÉÊ!ÓÅQFÊWÆFÇx¬|ÿh[u,U'­ş—£óÂV§˜,7èı–†M¹ñ
®NcmäÛğ„+Y­×©ÕS¦Å»Üôšµ©7)és‘teúz±&±à¤¥ é7ÀB¹P™1^Km©iÌêÔF2TJÈçÎ‹.ğ§r`’)@o^‹NZGAæqcÀvu$
5Lq€¢Ø¯·êØI	1¨ğD>îû8/6p©ÔEë 8xK±Á”Òî©Ø4¸˜jÏ¡Û+ífÖ‘4nì90•ck”OÕïG@Äx=fÑ”BÕÙ>Ë j©µÙ)ƒ6¶ğèB]âJ€bür‹èæZAmş3¼qhgRç6î÷-Òï€˜ŞéÕşlµº~*#FtH6oæèVT¤K«P8ÒåSg˜Ñ?dRD.RYñ£0Ù‘EjÕÂDíB¿÷äe­ò".÷=Hº¶ëïòƒfJ$kÓÏJˆo¿U#Ow,„ÛÑC.³.•’‹hÿ9‘Cùç;€Â&Ã®Ê%y‚›Û‰öoU‰áÂt¤9ĞXÔL´mšOK a¾M]†S"òl@pâ2ëçyâx>iÿ¼	Bkésğ6îÀÚ\ê‹w¢ŞJ¶œxõN¿T¾´q\°Pó—J¾€¯•¡Ş¸}¨x}ü·+¸e}¨Ÿ‹…¦; l'!öæÄû¨€¦€‹²Ï¼¥{ùOô£Êğ±p€bê«Ùôß,ˆó¼k3%]«-ÌÀÆtdˆqÅÊc8Ê5ê8ù˜\ç}öéÀVl|1Ry(òE~Ÿ‹–¥XçC˜ixñŒd-£/pÁ”¼ùOh¬ZeåĞ„o.Éóãc„™ë2£âU.äŠ×E+¿Í:
‡,mÏ7¶üq„PèŞ-=§B&Š¾wùÎËL«
õgJ‚ÓWÖq©$«õ¡Tâp¸‹9S¶edç,ıÂì¢ò?;m¡Ó¥tñÌjçnfNVàdŸ!'k 6ƒòqÅ9^Ú*À$D\Ü—ØóÆû\€5«ã;ÅXG•øéjš¬¬Jfô±jÖ¶¿©‚ÔšÆ.™%“z}Šõ¼úÙ]&Ó%?'æ½£$H›}³[î¦¯;ŸZ^Ìo`üóf-9£43º‘i]ñ^CãÕOP¬’$Ô’Æ+çHJ4»é…ÛZaH%}ÓŞ/û’/P‘pÖfÏ™{‚v`À$‘^&…³±-*ó²ÃÉI–æ5ÜüÿdÊ{,yù8*•2¤ZlµÃS5M¦cyËW^Œ~ä§`ßƒ8Nt/t‰ó÷‹®3ĞfîÒfù›“7÷M‰ÌU&6ãÅo^Q“	ªT÷¾áŞZrmCƒMùÉÒÊ8jm¯0¡õsRûÕ@ºÒÿÄc"¸)AT…Gçì{¥:7"i¡¬qÌâU [ıTd—,İ¾Q½¡@ËĞöKëîSN›“!RL|¾uŸ]Ÿ—9qcp†Îi/Áo
û«}Ú¯«ŸöN\(”˜3Dˆ÷†´xÆ$)]~Ğ/è=vç~Z‡ğE¤HG`BãhûĞ\(ó·YõàÅÃÏàAo• hFl‡ş§q¬·—K)¸tB]pÑ€~Ê+ô(¿’Ön{"é½èÂKÚé®û)Zz4'PÄrãS)QÕ}5ìîl%£Âûğû›‹5åwéÿ‚)òD§ÿäŒèFp²ê×…\Yyç7%ê )4&[8@ß³y’&ƒÅJ½7ıëæªnŠàs<Q›|¤+ø1ˆ&Lºå,N Ä¯"Å2Û-’ÊˆnŒ%¤•{[Ñ
M®yl“sL†yû¹>*­¥ôœV›r:¸„šÚC>ó/X½ƒ¼ö4¨oFMe,ãy»=†Òk›7Ğº1ùUIû3ƒ½ıN±ƒõÃÀJƒT;ds)}pÖa}¹PÀ2—T¥~ÒÌhÛbG;…èw}@@cûƒÚ>•Bj)2ÒåLÚfxİáê¸öp}Uön%ü@¨^¢ˆ$ÕWÖ%v¥§jòÉê6ÍŸµ‡É“yÿW‡·Û|6c€µN…W-üq¢xFŸ'kİ	-ªvAn%²{Õ¥ÚéOãwiœ#†Úßtb€~,EíğÈæ!Ù&Ï=/Ö)¥#¹W¼FvŸi\²^;cåt¨ù^Æ<ÜõmB¼‹î‡x  -ù§–­ş\&"ˆ[/_ãb“·'J{Ã*DŠ? Tb]	ÚÙ`Æ>¾êp•(ûW[+à¼5¶:K½&ã±ĞSzCMöùY]a
x'pÓèØXHZy 5VU_eŸDWh¡wUI»_ˆ8Ó^”Ó´Ç ‰äs8ñzå(Ï¯YWÆîï¶r_´vlCø÷"Àı©øªEïPíêX>;
Êm…œ Ëå=ú’G„=ä×ªby¯>ñ“’èYE.ŞËÉI57Ë8pçj>`É.˜‰œ"ŒÃ†ÊĞŠïÏ¸’¹ˆÙì—Gøş€¸1%~Ñ¦'Ÿ‘¼÷ØrQT+vrå³kñËüÄKİàÏŞu‡]ÄİX]R•hé'M$eF˜®j;ºÛ›w9ÉÕ¢Í³üóyä)|fxÔãÃæÂP§×ktâ¼(ŸİÒB;ZhçTù‚İR/ŒŠdV°32*¸?_>À!W/õ!Ö„ºòÛ‰ä;[ëy¤·)Bá&Ş‘ñî×ú‡ |‰Ù4¾?¶¿§É8‹ÖiR‘Û“;Lš†!¨Ù ¬ŞÛú´ÕtPD²Å`{ßLÒ©ø>€©	íËhqª—~4hÊÏš¡&º°±hp7ÿ³½jŸ–æØbæí”ß9ÈŸx@ºGÑ;¯¼ –é*|0Hx¤ `nyœrcKïU©ï«ç@cjÜ|;k0ğûoGTĞL˜k ÑNÖ~5ISŸG·#íIµ¯sÂ_×ºÏô£îõV{Ç²–Ô<b‘lÀøn§z§ıeA+u £ÿÅs®†	 <ÈÚ±›Ş›{ìŒÕ‰ƒÜÛùÇÃ&ÅZ˜Ş’İ—a|é	¾6rafæïşÈ)YÛ°¨7øMØÒ÷aC»¹ÌÅ;°*M_}ê^e’r!½#,_¾°¿¬¦/íÛ3ógCøğN¬¥;,ÏP\­sª€õ2[3`3Ò]¯÷ÆÙI¸›ií@˜ÿ»nü®;8­Äæñ‰.¼;7°ø¯ ¾2°Ãäó‡÷Iío£™Âh¥æó¦¸n|ùVD¤›´ûgàöRgí7•'Ôi/ˆhĞüÂèî¸pt¦5vËë"ÎG}É.:¦İÏ¡+&¬Ø†&ñ']æ™¬±4óLıÏÂ7N=:>æ±·ÑYÛ¨³	µYdH·lØ2ş¶®.Ô@§Äö6¡®‘q@®ü“ô©­±¸|ñ€E3«)¹–Ïé‚Ñ†tu´zí²²ïüâ7Á+tS¸|:ÉÀåO¡e©ÏêX¼hI¬ ‡“KÃ”­ï ´Ñ·¿gğ}ßÑ(<©)üÇOˆ§“l*šM§[;_>p»=/ßÇuüç2Å']döe˜ù+—oæ3Ô3ìj«Şú|Üº@v×°¸¡ Mó"ş§.°Ş³É8§cRÇäÉ ¨J†jU1¤% ;èñ5Û¾¯Š)Ôz¸¦e•¯ÑŒã„Yoæ0¶êS¶Æ™åŠÎ¤F¬é…¿"/óì©c­D«”=y—g²
µëÙí%¹°4|(ónRnãp›±˜s¯V¼§Dé€?2Ö”PÔQ[Yœ7BLÑ²“¶Ô•E*‰ƒ-ul‡¡ûš˜vÁZö ÂVÔa˜å}Nú#z–eœdîœS¢ûÈ± ;©®Ş¸n~Ø¨ÃŸ{EwW«í-ì›GôÄU•Ë1’¹‚uÑÛÒÆ|½ß¬oà[¿
¢–n»gêêºQ†ÔÊx[ìµ`E1œZq_¢5À7á+f6:”ÌTBU ‚ ¼ÇÑZ qëû†PWßcHŞ²«ñeßÉÔbDwı|t¸Š°RX ı s07JÜwÛ5•å+f<ù–,8¹
£'Bá>)7à°ªïöoŠhW6_–Ğ#,İ‹Ã)/\°F:u0h`OêÆA‚õâ„@˜á#—PWYvTZÛ\”­/´9İZF´µ Ÿ÷Èá-ÊÏf£×‘ïæ¥vy;x†(úÖöí6‰lƒóépİÖbÆ—Àg÷Û’¬"eã{ïAº‡èİg7p€ÌHø™aEñ|“I‰ôå}$»8 -¤-\6"áºJÖ#°	\²µš@÷E[óèxü¾ÇyŞ ®b 68c“ŞÀ¦E„WĞFÜ¾¤ÆğÃ·°¹ÇføEn~Ù[NC»ršÕTà“lı§*¢Ò¹±,›Ï.™Fãºã&‡ÌÈÀT%Ü¯ìU'MêrŸÃUE²Ø´ 4bz•Gi¶_CŠ#Xî²ÿßBRE÷²GöäĞœ¬'­÷”Æ`ˆo¾6„ÄàPÇ_6]-B[!œÁvˆ¾âh÷´§z#¹×UU­+!8¥6'Š¤ÌOOšÜ/&œ%€FĞâ)DÖÙÇeRw²2Œ6Ê¿#%7Í¦É…¢sÇaİzñ¦ ]Ô[ƒÃ×„HƒÎ„=ú»ˆ°’KãDZÍˆ[¬&O	¹,˜”M¸V¬À-’7cÚGZ"éÑp¦'Š½Ánõ‘ë`ey¤9TeOĞQªOÚ<İ¡©–Òp5r”oeo¾š_›Œ¬ƒ÷”Ö»¢‹cM•üaÓßN_Ve‘­N`ÀÔ 	>I¹»ôVe°ĞËˆ*H‘·¹æš¤pê›ê	ƒİlS,RÈŸÑ8bwpËÑ´MŸ4’Í+EÂØĞÕOƒ%?R#b0P„Hz«™–ÆM™6ŞÔaÏè€Úr›Ïxšµüêº0«H§ÛPE9ö7ğ­¥@ÂĞv¼i·ª‚µš*ÏWî­kÜ?»v8ÿñĞö5—ÿe?8ÑFĞftËoJ×·k¢•wiÇ$z‚{,"e€´
“	°Hi3*>]r¶]ï’^ƒ£v]–%$R‘¢8Î*ò`i»xH[=§sÌ– 9Û[o¥â‹PI÷¦²ııçÖB÷B÷öú3¶,¯‰1ÕS´-U«À\±]\yŸäØ[ÙY²½Ï	°!:“ŒhÅ’!ô<:hyà·7ITÈÜ”8İ- P—‚Ã¡.MÑÑ¬ıV¹IU19Å5+“
¹­OıRşÓú`‡¶”ª4)‚2&Ší`Zş™1öÒôJ%q¾	êî×¬äCé»0È´s©#nlÍ»OÏã—PğKN7Ô
ê?>Z.c.ôøIïÆ½­çÓëu±»i c{*Bo&§!2â³0S
¯ƒ2ÎêMTÉ*dw_¿Å}VMpı­ö³­ıÄQ¦à'ÏOqA»Ik8À&èMft%÷ª¼÷j­¨x\‡h²¯™_ô*ÄA×(îhkBÕ.Å‘×ùğÎaåf³ˆ;mz‘“N˜ğ<L6¥µÀ~Î›.R"é¨MÓmÔgll˜j„ªù¡4w=n™iÛïQo#LÈ6»¤ğ	~êÚ}êûêxMfœæXDK{
¹>öCñÖ¦(|İl?ZÚx×Puº7xNßé»{b	½\£x÷ı>`2	@%²ê#É9PFæÇbêwxX¡Á>ÏœİLfõÅQ±gO1•Ff§øY±Éô g4B
yè(ĞSÍ®í\8âƒ²‚£oÔ×~ˆ–eX½’Ç|NiÜANÖU}4¹ˆÖ´òòä%µ¶ îkÚáÙfÒcéÓı°©Ş"SŠØğ:LõŒvh®îø±ŠäU[ -k/^Í'°Ë1z5Š'ä¤è	»Û@x-°  ñz\«¬HúözMl—iÒ•¯-NşŒöWŸ”]ïch2ÔİU~Ğxwóëõ²Ëˆ—>®'[ &S:k»«¯`êZN¯äÍsaaKêÒ›Ößõ{KY)9¡\‡q¿
oW0ó¸dL×ÿOàÛ—~L
*ÄAsŠ¨ …²£‘>Òí(ãI"ò»&ŞËUc×•ôUêØG.Wk–9’ÊFı.¼’*ü–á~Ç¢)Zø“¸ÕSjíòšİúõ€l@\«İš‰â`åÃ~&&‹O/èşÙ·Z+ó¬+b~“|OM³P&é
¨ã¡øƒÏÒ£Ç¦µ­QŸ™è×„ÀÛŠò)õ»õOyªò$Ä·6Ú˜¨š7jWM£<:v	äÆ¹O”‚„şå«ÑU©U#šX¼{H?õzBÄÒıšÖ¬k~¶?É“J0yğW‘Hê]dMY&lÜĞLm¿Î‰ín1®ÁÎt»‘R°ó9#yØÍ%±ÔIHÓö^¹+æ"Åº	WÿR#ªWW¿’·Ø‰j)tıvõí.[1J‰0†”²Q0õÅU+Gè«¤êX'Pİ“s‚	êZVjABòOîjêŒ™J¦W“^G&òIÏş)\g —ÀXÜ¶N×§Æ.œßÖ•Ù„&º4‘ÚŞWL¯ömBH<_î ®<¿´üİ…§¾;ÀRx í½ˆ å:hÆ7=:†û”1Ë
´{Å²Pë\Xï•F8v+w-Ä¹ã°Vsæòs¯ÛáYõĞÎ(‰üÁxßßú#ù™ºóÉïúÜˆ´úmìU¶odÜ£ÊVÿ¼›áGŒb7~V/7Õf&7ÅØ´?ñêÊÄ”ÖMd|5ğ"y×¢Ÿ…ÁÖG;ÍdæQ¸záÁx›äG6-ÌZf€dâ1ï…=C‘ BÑõ™cOÖ ZŒé ¢Z‘	øÅ‰²(½Äc{ºÉ©ˆ]0¶~‘èLÿn!O*„zíò€%±,û(v	‡v¡3¬¤„µEô’‹¶¤P=F} ÆÒì¶´ìè§iM)~ş¡#qÓı«RÀz[1•–Ë0D$-ˆ-›~YÏÌoêP•‹Ô`·vl˜s¿¹Ø–?R©ê+ÎÕigJş¹š7¤dcó%šç¾éZò®3…[şŞU™ešS§Qı™ÈW¢òO4}»á|›õ«$€¦Œfr´3­O›%(Òa¶äˆÏ`‹|—”Æ~ÊŞ§(k¾÷Û}åSmdvuo²l®'ˆêx£ù{Úö—3;É2R¹í¨c½„ÿ ‡Z¸\ıGÀÏáƒg®qúç`†&×ÔS•‘ÿÈ/p ³Lè7
%	æV÷ø‘îÎ‰6‡Ä€²(cª¬P2¥ëÍP`İï¼1S``¿øÎ—á™×oIuÄ2L·a
#’ô&–*D!qıÃ²œzøí@Ô/»Eçæe"Ä[| 3:oÁ«¾ËXe3å‚OZ%FîMKc/RÊ‚M€$¥_Ø6«J©|¢
óLìé µØ£@Î` 3a¹Úªv
cš‘SiÑ¿–4şPÛÿ’kæ‹ö}H ]#”uïÂ¿Y'Ï>'èıÊ)2¸4}álø/+©³ü¼`xqÎ¶’Å²S¾œ$bE>AŸ„P	‡
¶HlA	1©Ğ¹£ä«Ñ~î¶ÉÒ=¢û_ºÖ¾³
Ô¤C’é°Çô…è	”şâ¼»`Ö|2ñ8ãú/Ã/dz<E –.ƒìõ‚¹p–?›Ykaó,8YE¿_bQËnvıÓ++‹şı«şD¬İp?±AµJÓå–dG÷eÛÇú;§»†§Ióy€bëJ5”µÀtpön‰1“(Š¸şÔÉ E,şuT¹¡ã÷òòÙ¼äª¹òJÂæ©e£Ï|yG¯”và†´sœí
Àg­Ôé5–š¨İƒfè¨è“V²}Q®eZò¦‹:«Ç¤,Ò\¡`zºÅ“FO˜ÿÛ÷åÙÇ[ğq*\©êèè_ Ü.¨˜š3şİƒrW¾sa„×¯ƒËÒ3Ô×Fr³A?j>°´OLğÄ;ı±…A¨çğ²uş2lß¨±ú€ª Cÿè{Ğ#ôX’“õ®à±ºG‰”*¦ÎO]y8ç0—u|{Vo2´Ö'»ÍªÖ³§Afføk®M2¯Æ 1ág$Ÿİ¦U~š”A•{Î‹u³Ø›çf°Gò¡±İG80VUş›÷.¦L‰nİäç®c{pœÿnÓ2ßI®‹RA¹G¬ï°öÈyºÀ9TO‰¨p<ÌãK£Ú5;‘ƒ|öœ:…‚M!ÈÒ*gvqDÓHÂö‚Šİ«µacú~ı	'	*ì3Äªİgg||P¨h¹-ş¤Ì¯s8I›"Ä]éiıáÔÅå•“²Ş?IÄ™Û¯ßr×H”N®D $AÅg¢0uT “ÔŸÃİ”ocUPíé¦£B/CË·ZCèğn >NÏø¯Û}¿?kFµßi`ä5ªEMŠòHÕgÈ5Aæ¯ a4fß’°”¢O9ğ€)ïG3v^bS0íe0Ö#äE‡õ…HœŠRùÓv·Ö{q,^)“{#[Õl_ÀkF†)Pì8¯1üSï¶él‰zâ0js³*·NDZí)[ÔË’¯.U•.Ú\_\$ë†l5eÆõ¢ªÕµŠ<¥h½ó+ıí±n›?EeŸ·M—~)êä+şl«¢>³iW4Y›æëøhêÄşµpuÎ0Z8æØDØ ,OİBT™Éê×¥DÓœRĞ¶ªó<¨Ùl‡™•%oÎdéxÁøAå47ñU!6Zˆ¤Ú XIŸçfäúÅ«ş‚{¸1®Ã…Ã^—pqtúïœ/Lˆ]Zæ^ÖÊöß“®>1cœpqÒE?çïKH³F†[BKÑå¶âò>óü¢G†Ä1FcĞ7Ø˜Ú
`€|O0Â‡48bj=gS/‚Ö’Kä:m"ÙÎıƒ0²6ãÛ¢P‡İzí¢´ş¬ËiV‡¿jióTo§¿Â:·¤àfa±æ2QÃŒŸÒ¼`ĞlCYû‘;¢,ËÑ]a$Q?ñØ¶ajÇEÖ^6\¢Æßè¢±1©ŠÈ·	í9¹\0ƒÏŞù`üîí9UİmR"òıua˜#ag«²u‘•Ó˜Ú¯œàÇ&XP36-ÿƒòúïãÿ+oë®K²²(¨(„j¸—:%•Õ×_0X³$ŸşOŒ»úy”¢G0ŠE­Så>ú*;*©C&‰ææjê)wêİÛ„ß{h1Ã óìÔ^ò«ölôõ‡
ÖnZ÷5è&D¤JQZR„WfŞbuzß#ˆ£òÄ«	oq—w” á¶8oÓ£5c0E¼»ã£˜O­Õ\  ­”KÇqé<ÿBHjÆ _@àÁÍod©ë5.FŒbwïï=‡ìĞùıRcâW‘BsŸºD†3]«&yµáØ°kŠ`Zì…½RÃ–7Òïf¹ğU+lyÌ¡ßGMÉ=Zo£^İca~UåjÜ¢Dd“o=6L|4Û¥ÂJ´¢ÆLŸ‚Ò8…¢aùŞ¹Ñ=Ã±RI«iÖ»‹Ù'ÕPƒ}™#ºî)·ÎÿøO 3ä½;8qURAÙI
À»‘u)°Ër\·ä8ò€¬ñÍˆõ,YÃqd¿c<Xª`÷hòŠ;¾_Å<ÓB/µ•gbU»§@»ŠjK³Ó°¯<—»M$«wNËœŠ “Õ4O†÷ú"ŠG×¢ÇÛs8^<ŒX#íeE«¼Òï&ñPpv½Éè¸"QåÖpZ>›Ğ4-3qj)§¸lı|%64!6ª‰VõSĞãµ»­¢«’µú|«=ùw±ôEæR{¼qOZ"÷#Ÿ/š·B) Q²Æg™2>‰˜ìEä”î¬ß?JİÁê’%îÄAáPç­hC•óÇX Xùƒ^‘úêùÓÌ<G©q×B\—açGşOOFYÀaqµpùrB?¼Ÿ>‚jöaòÑÒäµæäëiOÑNóïÈÜc¼­Bˆİ, ŸØÜ‡ânğ™ÁÙ56fÖ1È”A¾ïÀô’È8¢“ôˆvÊPìµ{4Ñ—Îõ‹¿å!ööÁ¸¾ã´Ãz|åoNéèûV^±…~:Èe{³V1~Ôş8O4mßÕPÓtˆGÍşèÃ­P3x¶v’V¸JÌ¯G±qß$ˆ§Ÿê>ƒ­Ì•¿½]Q‘€ö=“¼]£§¿5‘YûóµQ±`¡y]—I¥f’Í±ñgÃõ^¼ôE²ê‹6‚úEœ®šî‡j©Céã¶Ïj†#rb~X"BÏ9ä‰eÇ7ÆbGaÇ]¬Øµz}ûŠ˜½Kòvûü–VÛx3"Ú8À°h´J$QêY	¾Aó)4ğLKÏ0F¿›…
ÜÔ¥|wŞèoàcéIÕÛ8¯x0”[5« ­ö0öp©¶‘³úxöùÔQ º”)­²Ë¨ĞÑÙÀQoa{ª-¬ØÒĞ¤„&#ÍĞb˜!†±Åë‰y(ë
§2ñÀÜŞ¥ëìqÓı6àØ9ÙR„ÿxéÔ®×O„“¤_ÖkşX#æ¤DOR®3<ÈÀ±2=Ûá;NoKiÃ°.S³¦ßëAóóâ $3=cUãoZ&.Æ™¾N?ìA¢NŒb+^¥Mš?eÊX!}¨nÑ`Šçv²ƒØT(Š¥ÉÇÙ*ŸJ®(’°]êÓÌLÈÎOé³ó¹‹üVÕ–[Æ¹…à·Äeæzx¾\ûÕ¼gw"J«0˜KªAJ¬Aí•_oËO—yÚ°?
@g˜y‹’*dµ3ã®¾DB—mRÕ	œªßpvX`PÚÍ}ß‡æ‰µiúF¶dé¢°@Î¹¹tçë PgO·>FÃşVZÈ4§“Ì]ş“üğ½S$ªÌ)÷¤ÀØşQÑ£lü€İ™ZÊ|º„}”H…Xâ¹÷q$UmjTÌ$ïtQL{éE¤OÒ:²;²òd
£µ±À½ÄÃ$éFÜ:2ç×@4µòò€éÁgš¼LÇ]2ò‹©]_G¤
ğ   jµİ.KóY ò¡€ Ğ¿¥È±Ägû    YZ