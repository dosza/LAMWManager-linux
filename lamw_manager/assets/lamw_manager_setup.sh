#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="856229328"
MD5="82cf47c74592a799acd0714a828588f4"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23756"
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
	echo Date of packaging: Thu Sep 16 15:41:02 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ\Œ] ¼}•À1Dd]‡Á›PætİDõ@:¤a+zˆ¥xrù¬ì0è=x.av„ôåşøÊ^bò”JOè·»*üüî¤fîBùı©ríı¯û¾nÀ÷PÔ{‰ˆA)9´[õÌ(Ùk¡ú‰¶æŸòÈÁ,bpZ»íİZ)FH17ßÈ±ÈñÃÁÄİUJ†VUNHÍK,“Lhê?ú3£ò+cÌ’•ãp šÁs:|É)eBfïD6LgÄçôõßëÁ¥ ­_WÇ »7½Ÿô^;¥»“,qåm0@Ğ¶?IÖÚ*Cš•¢_Õ*Æì1åhaÙgc€¢ÈÒ#òßmĞó—™sfI÷ÙkyŠ÷Ã-Xô>¤8BôæÈ.!`]Z-¸õùYoC÷c¶Í"‘³æs~qã‰f®Árş¶l…”DR†9·Mhxö–åÁ´çêSdğëƒ'Iİú¡¼,Q'Ïîšˆuqk‡ÒÛç>¼iÜ{ß^ŞJÜ—w÷šÌ†”Dø÷UWj€cTc6±µR0|‰ö  HVG¤ş í­ø•¼ßXkn¶RØ£½¥“còµ&»–Jìş2Ş:Š“é]¸ğj yá±m-ÙõËWûœE‡È…L*²k‹ş]èÛ	øîNI¦Í)Ğ·0Ë«ŒTFå¢?1É)ò4J\ü¤Äk E…Xí³êd¬Ò^¸U‹»ÊÙuíüx<	„™z© N= Ÿ&äY4|&¥v¤TB»ÁU*ßÛêË¹]¼Ù
v.õÚüª–…Í‡ÓÙXF:©crORÏ¶GzRâtëNÿØV¤¦››ıŞ,ViÒ`*,çXsş5O¼ZJ
_æo}ÕâÏÁaÛ¦[#:‹¨ıªÎ¹Às6Ğ¨gU¤#üä€ÎUè|ùŒ·¬VÙ0Ö@4„[£%c®*•úïGSw³ü¡Eú¡„Ö±ŞÆ)ÜG”!®#SOfÏ¯ƒÁ
’ØMõ|–h–FĞçÁÏÀá¶®Æ*?9¦–ÉaÏO–²MmJ\·ñçraïÆlfIU£…ÁòëCmHLµ~Ü!î?Ñ´^º®^È-óm(
µ‡¢Bb^2ä%Ú5§;Ş÷GÒÏ÷	*¼JyXÅê	–÷D~ÍÚDO)y¤Àİ}g4&Ã	KöU°ñßïŒöØë€†Å j¥&á…ó¾†—û|Tİà6^nÿªËñ·z!Ãb‚²»Wı]3êtÕGÒ5‚¨8ÀZaĞ<e‹:%Æ‡|O"¿{K¦8îYÑ—¢‰‹:`¥=’©qŸç¶
Ö^¶º¼`¬fèºïxº÷B	h$F"Q%ÎN¤Rhq¦ü¿ÑÁçyï=KË!>u4ôø&š«• Ç£Îv%a{Æª£Û»@ÿ”DÅ*KÏT&,%ÜšVsu.LDÚ~9ÿ!¬”æ-`Ÿv@qUˆvĞXòs¡ÚÊ½Ëœ•ô‹¥R7„Ô,”!ÁÌı@¬‹0Âe„ëÉË
+4ÇP‡ZÚ¥ı`ş”çœiò„/ô$„]XU}ÉÊ›
w}J“Á<¸eY±
±é|ÓQ4â=Øª7¶ ±-œf–ìüõÕüÖ!‹V±µø;¾»U5 ãŸ–1 ^ƒ‘DÃ‚ÃîğR¼5Ç*Óxı’nuIÍÉÛ}çõ”R7hÿ“=…-ÌğÊˆDÁïÏ¶Ë}Ó=¹Œóçı‚X“Mä#ŸK‡5ó'´5@¿`ü¸r"% ]Ã‰$q´¸½X^p"ÖØ ¤€h^ÒÑé’§¾e‰¶§/õÛP³_*€jÊñ”±†2Ò¿*…‚ZÜ.ÅwjT:Zùî%Š‚~,âÔFôŒ“†·ıÇdT¾ÚÁÖ®ù*Š	—}¬Bà Æ¾¶ se³‚O=1åKá|?³JÈş†éÕ|"u†Dæ§²v«	õÈ§¦ØªŒótµ¥GŸnUF€·&'ÈL0ÚD¦û2¸L¸%–®hcXÙîv¥x#rNãùağk˜Ü
””GéÄ•é¿ÁÔ¨q å9£ìÀñ:œ£ 4!›£§úb+Ú×¡™EĞ®öÌÔhH¦ [ìÎÈBº¶äÉEg6Dşväƒ˜sC
{–E®Rh÷4QÍì/'³MK‚„n‹öúÇÂ'é!˜¬^ÿ<~c‰›VÒê'ágÀ ó‚j _ï0®I4ïá‰XË´ĞKX³ØBzÍsÌtÅ	à¡ÃCW)c¬˜pü˜ˆ˜<1g*é¯cÖ33Ò—ûÔİj‡Íè°baâ®»ßSo˜Ç:)*&Ì ‹–?7Á.Š™¬ŒŠ ıÎÈ¡;<llC;-¹ÏóBQ š(8n};‡!i5÷öjæ#ç¸ï¨¥U2¥t:´ùêŠíø‡)(Ñ1î‘kÌJ_˜»Ÿsa<p»eñÈâ¥|ÃÂ³^nó˜õ'ÇÖ*ÈÒİ¼¿N{¦¼>Sı`Kï6Ô†Â‹Öëı¶/yè0¯.A€¡%CŠ‹ŞG‹ıÑÒà@şxîÏ‚¦Y«U¿@ÉT¯>ƒD¹¤Ú{–¶ìY^<BÊ«ƒÛÄúlİ¦InIVÁZ°$’’¦Öë’»g5…û¢PfÇVĞÆWU$ØIÍ4‡b™IdÏy„ìD³÷Y&6¹¤yÉC[(ŒQ†nnP½˜ÑB»¼,p«è1híjp¢ĞÇtüz;Âêİãq*V“ÈîõÎg	TusáÏo=Úyv1Ñ\˜Ş»»?`KpNûnô…úùDËSİ`{8KáÙ±óµ‡[uÍb~uëèÆZ¡•oÄÙÛÇŠ¨,äüQ›™ñ™¬í—İ£½•Š²×(%¯‘¡”.k±!!èù•ÖJ9¡Ú’ı*µèÎ(Z	©å›Â©èÀcv¬/Ü=aUK—‰ØhRŞ 6\w6EÑ×F™.‘éNãŸ–?—qŞÖÂZŞ¬¨,ú}t¦Îµ#€ŒBş°†/yb¬´½'^^ckx9t„É¥°Ÿ¯é•œ*6V"GtÕVzºõV®jßû‘1÷™ùmjG¥çò1x>GÙ$À›Ë#\u‹	ó“}ütwÌ¶¾Hı µÖØq¶Ä$†^2	¼0Îôü|}ês0¿|Æë9+jÑ©ÓûxB)ğy¤ŸŸã~+Â®Óëÿ^\9%6A“V¯5ÄQ‚Â"ØêŠ/u³¶f·]26¯Çgº„xÙfš&NZ:÷0èşàÄäO
×ÂV9Êœy*:°\ È½Ù80îõmX$õG„+O]İ@ª",~ç;TRæÿä‹õşJï3å4ÑSiZ‹ÇFîÔ˜¤†4F Å<—vçæêÁÒ=FÜ:Y·“®x„ÉõÏ(»¿PÍl|²Sº…#+Ó-D®Á5SÓæãôŸ•‚8="q§]"#%1í4!óbÆÇ¹›‚ú$k^;J|ªó¦3Ç`á@ª²«ÇkÈW	Aşª¸ù—;óÆbnik™Wœó7ºÜVx¢ÚPÅ5ç–7§[…º¢İ•HÆf›³ÇofqŞmß‰í†õ‘Íaª.—+eÄs€~ r‰n‡£»:Ê£Ÿ{ğ28şÁÀWGú¹¦kNÁŸwnN©Ìœw„Û ¯2ĞW˜ºµ‚ø`¦53©Š˜ƒIXèÊrŞ>œ¤}%°š)9u¯P©”0œ‰ÍÕš¹±ÍRÚ,µêjG½6Ô,»ğ²¡qAEæï>eÔ569”vÌz(Û“BË³nòİæ}ö ù#ö\4t©¹Ø37Ş ¨‹@n=·xb]+z	
MP~Ğ›‡¦æfB/¥†ä[¼ö5zòt÷>H.M¢ƒÙ»0²qÉ1rN&0têÓ/ŸšÔ:7*jLÅ`o-øİ¥ËÂ§¹İO›A&Tÿºñ%u3/Ï­C/ìŠ¯YÏPğ4âßrœ 9E!3ÓwJœ–ŸŠë)"fşXÉ·"‹ø#D¼¤7Øy„õ®ã:ş¨®Q°V&–ĞÅ mÄmv]iqümPÛë}°ˆ?WßãyO.Wz'P¸7G8í>6h•FqæĞ}×ÄOn#?Íö?¯¡tTp ™Qyã<Sâ
õİşXo~/	VÃé!ÙÇ
™Í¬mÉ&/
– W;y¦ş]X)ì¡é…~‚ñ¬Zè~ƒMÅ ³}JöŞ#±áèÒíÏZ–«'°„0Ğ4·.Îq›ãÁ1=ß'û5S‰)Íf˜ò§Ê:¥'ÖÌÑw*‘*£…‰ª+›4k-ì!Ï’	oÈscpÍ•Ê" ©áĞx¤ª<öBåLÛnei˜³vœ±ß´•I
ˆó¤‹d¦ ¾%Î‚„/¨"ıê5İõwKÄ-°p…zªŸ‰Ö¸Eˆ¾…R3Iÿû&(‹Œ?äLKYàD¿Ê8†6ğAj†™°˜(g–˜´HŠÒ¦B`aÆÛÍuï^rVû”œòdKº÷|ˆ ]ŞõÎÿ)×Éw¡FÔ3‰øè]öº W7äØ³µOÍèÒY‚7Aİ¼¬Ñ†…†ó˜Õ÷t#Èà—wdumx­‰å.Šˆ¿7ÂR–
e}ÔLÚ¨qÙ$’qÌî¯°gÓùNFŞ?«L'ÀÏTôrÃ—=©Á “pr]àÕ3jóJ™]f[IÀ KÚ¾¯ÙÚcsYq;¾Ş®İŞàË–0p†oÁÚ$³7¿nâtF•ïz<—=á²C Gqùüîõl7‰³#Ûjİú~’(ŞYÑë(Q»¬R3ŠM®èƒ5‹XÄAg~¦Â…Ùïàˆ³cÜø7€V‰¦ë(ŞË‘º¹u|å=k¯±¬üÆ.K½UÂ¡øxëC§MÒê½ÌGF³}İ"É˜‘Tœ"$¯×ü¨;§‘çúµî`9{[Ñ².W™AG¼4ŸFCŸknA-o<‡‰@ä"
	éÈ­À&^İZ·w$sQ?úÙ»ÂÑ’ñ=îx aâÇük‡)³Ì†äJûÃîİŠR
<*1}?
v–|­È‰ìGôÇ™tı/ÛÇØò%4ú­´­–—`çÙˆ ÊÓ.°É¸(ƒô)³ì^tËOˆ)âÚòÔG,Å”l4üQSwàJª£Ÿêİrµ¨§ÉdÙ¤+¶»Û‚¿å±Hï•†Nƒ6ôêQ?ÊFAk>ŠıèùÅ)‘KÚ_ô)»öİ]¼ä|«¤‰=.4×Ï‘Û}Á¾C&6–åÑ”b‘–CZxAü%ù€F”¹oç˜9DKÔÛîÎŒæç÷0ìˆ5•ÂÌâ¡qÊ,ÅˆH™zìw§?Ú®·ñ³á$HX[&a–î%äÇ5v„V'ÆÂ@&õ”0‚£ÃT.-¯RçAŒá&¹Ú•êØ½Š<H¼HùNš¾ËŞÈ,hò1¨&¢÷í¦J˜>!§VÊºï„æZìˆõœ‡lËFNòoSw´õH¨…´âÆ:¼‹HÆ3şiv{—P& ‘pÎ*òy%HÍ­ÚœÿTXİÔ˜4@‡ES2}‚¬äÄÃñŠoÎk«'9éİ{˜FzÚ Jäô­±TÙF‰šà¹Å¹E"ms,ZH!»æ·É‘À—ôD9¥´;‡ÆDÊQå-<7ïUğ\í©ÁÄÀü2,?7®sk$ëlû%œî´ú@ÒŞë9t6f…ş=ş£'ŸN¦oJ³9íä‚|±RaÕÅU5¨ì9½Úğ÷¯‚uZŸ›Î‚³é]
B½aO_ìU˜Ò9ID}w¥©'qŠV—–£¶“µ†Ä…ÒíåC§Š×°ñò´!ø¤^ÕG®äyv§TV˜Æ5Ãİ5OGàßí×ûï©'=¸\TôGù’"¾ª¡1Ö4Ëá1w}äÊ_\ÍáO0Lí˜¾›_§å\‘ågÕÿc±€ôMk&êqš‹ú#±@LheTph)I`8Šª¥à_Á,y—Û9ó¨O¸!®Œ+¼ d
İ%Ü…dæ*­¥PñÄ‚±ƒ`?ìšTŞ\æªÆ|ÆU*Š	ÃU^ÆJşÃ~Ód<’™®
Ù.Ë ñŞXó \×4šÑüÏ’Yn¿# uC® —•Xßs³&-¥Î=	„#Ü,èùˆËùìNÂÃ3ğ5õA‚û2y›Ç2ĞëÃäOFy.rd±lâ ìÅ³çZ%;i·O°(FMÇ©=?‹Œ¿‚TeÄüñ@ÉxG>°—‘EzZuª¹ ¢h°õ&ö§í0ç¨äğöX²¿{u+`îœMÌÁÔl"ªóıÈC¡Øq}KÆV„{A1*Ü`ü¡™TLÑ
¼´Q#Vê¾ØÒbğ%çÖO‹ifÿLªöàµgİÆ¨ÿËU±J"Âáƒ³z].Z.cÕMõÕPlínjOE×°êyŞ*ğ†¦àõxûh-ÖĞÀå÷şô»±º@ævb˜‰ŸO×cë*ìôÕpJbÅ\=1-mZ°cÏ›5Óó,Z=R]bUÊHœX †Œ÷/ıN¿o^ÄuL@æA°ŠtİŸ®›qw^I»ùµ—;pZY[ÙÃÃs¡ßX>&Š_š%Y“N¿Fœ—¼ıÑÛÍtwe’Hî=H'Æíu`!%TqÁ_å…)ÊŸ<·ª¢Â²Å´Ä,B|Ã5XP5=— ¡@¶Ñ2UT×à¿PÈ<$°´gSø/+ÕÎ; @UÔ›¥h’B!±¤¿½,:G‹ÑÂ©j¿ìVI^…(5Iszcs°ª Õ>*}PÑV*øĞzyAØ˜ãºUöê­+w×´¸C#™ôœÂ|t^AÀŠ)©¨á1ê>æÁ‰)j8¯-™Dut2´„IÕ†ü¹€»Ÿuh[³kzËÅa2Ìğè,îNÙºâ#éc«Ï(­Êù› )iãÚiæÅ­ô•LM@	˜—SJ›¶
+9FqÑuHäâ´NPÌµ!S'ºP-^¯AFCÜ^iù]Utüpæ¯ˆß~ÄÓ	«mkµA•ZÏD…ú¤)«G¹{ÆªC8øWaG³
F‡'e$üqêFw–àßuæ&çÁ$Æh•ÿ„í¢0ôEİ”Õ
²xó‹TÃï_ÉeşëìúáŒ¼WÌäş
}Ğÿhˆ¡ºŞÎŸë%ÀDn|Öš‹ÿ¨Îµí:/N9L½ƒ.FQ³d!ïkWN^ávD^¼ÉÇ xk0Ä™]<@~;³ÏŸ€ŸİŠkÒ-gˆ6ì(wôVm¹ÕE¼ú8€m5ë­tà©a$›Ç£9f„!~U¹Œ™ôH(İ;’¶2ËİcGLU”ÔtI@9ïÛ–œç£ÙØ]Uµë´$ÃôŒäÓc‰a¼@Æ“º>§i*:5zŞ(>sråÈÿÏŒŞ”ñÿF—€Ê8xP¦ cò¸MÄË{“^ZZŒ@gÀJ×J/†3ÏS›>v›y“İ‹3±ãÒ1¼Û!V#b%WÈ²ùÈ`QÅÅˆ*°ÊŠ›LvV%„©>±_üMÔ¿XàS—]x›¶ŒUŸIÅ¨9ÈR¬Ç/cßd^"îa;¢íeıOe…8‰s›G-7ôŞ^+Ç]ÊGÿšŒ)YemúìæÑv¥ÉEÅ¸*±0Y¯ïëøkÀùÎ³M’‹°\¤¡øêD‡&7Ê¥á¤‘ÛŒ÷@¸7Ü™3ëÏ? µFM[a˜â¼×ÌÒm¶¨¾ÂoÈ¤	ÃöÏcXÆE[˜Œœõš ½º€yÀ‘nìg¨R­71¾¨Ü	¶¢Nc¥¹òÒsK•‡?‡¹E*pZÕ@ÇËD ôÑ–Á)E#â˜ëtmóWTéKf¥˜À`\‰‰ıJ†´>¶ò¦Íƒà­¥ãK²^/ñ#ñ}»¼S™Z®1“f=ÇÁ¿ChÒjì#¹z‘†Eø	¥MnÁ™7AA\ç
#›Æ·¾ºvöSïÚË`¹P]à‰Oo¤Î«åHÓUÉ0?˜¿Ã«€áuüªJ,¡ßÜô];cÒ{4ª‹Wàí>ºà¿:,á4Kt3¶—éê¯ÿÈÆqõOÎ3`úM£r#äq–NsÌ”]åŒ:²”² 9=¤q¯s:oE|që„ğõÍ‘\lâÌ,ÈÇˆ­%$]™ógØ6ÇçĞã#'«Sù­iWRì$€Üâ¸‡â5øÇ¤Û:›Ì´B|®WêEæUFÖ !QüCET"$F»êİ¸ÁÙâREb¸¯1¡¶†·v´¿•ÀîãÖ '¢¿/HdÑSpíOÂ1n	r7¸. á#Ö?#ø]6 ñ$İQw§ã6u‰´³˜µ‰Ojº'Òôx±•Ë[P€£iİ Í|¹U´Â#ü=ÅŞÚ¨»dB}6I[I·¤Í;Ñâ2!~ †rß-öÇ6Ğ%{&sC=V‘Ü*ì¾5’x6õò@@Zh]÷ÓÄ¯aıE¥CL€0Ïü)²—.ı²•g†iÃü~e£E²±ZS==øAM±5¦nA‹¡Yæª^ëí°ìóˆ~GÄQ(DË¬(©a?½A`ı]»hH·®„é\–\íÚ(=ÓD®Ô{à)¸›S ÙÈ³½æV%o¬É®bHw«Wû%ôÕ©‚®ÃNyzL§/0S‡»5èt_¬¶4!ıvéî9ª%pP-‘ÌĞ­ˆ	Äıl[™ñ y¡E\={?Ïl¬ñïPÊ‚Fg¨¤Z¾¿¤lb’\»›ƒŸUìõxg'>él¶ŸŞW"õEúH@ë²¶ˆ‹qt¼ Ç9ªG¸óÀKY»´‰3÷	½HgóG¢Õê‹|P]—£ñQF^rä×Ê;­á¥â{b0´F¯Îc'yN¼{ÖL¹}ğò vÌJİt8-sêmÌ‚ æœä!æ•=äïŒŞw—Õ<2}¢C0W²g!6¤%]ë‹I „…ôïÇ†”©GYQgµ^°‹–Z^Ç&H‘ö¢Xo{CGké¯PˆxÄD>0ÑñnÎ6ã²+VZâI<¯ˆdÄ¬\[ “µD¸X§%&:¥½ôôÛ¤4§Ş2¬^¶ÏBÁğ÷;P§T:_g`õ¤…,BÚ¸ïN‰ü6‘±]gÌ6bé $³!¦:ÑäUÕÉÌtw„KÏíËGêq™E;ToÇ§—˜^¹ù’ï¤OQ¥Èª"¼¤+u!^˜1ğÑ|G@‹Ş w&‰İKP-ÿÖëp¯äÀxÅÇPÂ( ¯R.qÖ™ªÁ@>Êª«…7¨O•
¤|ù<!ãâÕô¢î½} òÍ2|&Js°Yƒ¯<0Lÿm«æè¨‹÷bQ'Ğâõ_M4ÌL ^äe¸7#Î/¹ÜXnİ$£–\ÓÚûŸ7vÌ)C¡-!Ç¸ğ¡nm,µvVÁ;ÂHjú?MBxŞ;ã3{(ß¢+.œŸ`+-×·#À“öƒY¡²i—‡Ø©%oÊ¥¸†÷Õ"¾àßãş'µ,y¼1U›µì£Ã±DOäœÀzÿZ]ÆÀè”²¼OàûÀulÌ9Æ,ùĞ„z|^œÆ¶?X²íƒüQáaÊ¸î«.úßÂzs™V)ŒÈ„%d›¢•5v\Š”?–ƒù–õp¢ú'ı‹…A"ğ~¨”©ê¢(ºEÔ
wTÓ<%á…ØËIb°t‘Ï¨Cô«ëgSIº	2î]'¡2[î½H8‰¶mal‘¥ş•&¼Sb$õÑ}?ø/ˆj°M.²¼%°ƒıE>‚ôâ+¸ìŞÓÙ¶åa3½[#­ä¹…‚|9ÎZj ÍnÄëU@^O
ïRåÚÕ\©º| ¸¨Ä²ärë	C1ËMpÿ²Ş×æc*¢>µçöD¡¨ÆG6ğ8ºbÀ½µ·Ûä[÷³#P)›Uü/‡‡±M/òØğ¡V«©¿Å3 3‡+ı"«
wzÑ4ßìDDÜ†û_N’ÔÑ˜¹¢û"8°Tî-–ö3ÂcFÍ°“m':`@ç¸ÚÊ_êtÎÏ¢ßÂd*1nF:Ú_’ÉRˆ_*OÇÉ_Æ HE5ËŞKœM7.Ó¢A (3P£øÕo2póxÕ2Ã»ÜØ>ê×fv¡=¿÷d9mŸcH]ïlQdJ¦“q³Õ ÁK!zus–£¿öŞˆ¼Â"Mézóêƒy¥[©öÉ£J×
¹m&§×á×˜n¿G	zòK£¢’g?×áÉ„âßb™s…|%OÛÏÑB*ÓÏtT];MÙ„VRãéôª:À$oF0 6”SYbµŠ*å2_=è¼¿wYR—àûéåàìçĞ5şƒßû#M 
	6p¡*Ìæ“	åû:Rí˜\0qõ²ÊTò!WZí´–$Š1ÀÍ†¡§£ƒçè4üİÂXgüT8©½“~aŞ°ï)'¾á@{q`Â·æÚŠñˆÙQdD4àå&aÏ9°Š&_C¬ª<oÔÄ
C­TÁ¹’-úA”"â’ÀÁ„™~FTvtŸÙí^^\:B§Ü¾Ó	IP&…ü.*0ÎÄÛIna•AÔŠ?[–ndcæ(@^­¢†ô«êŸ.cÈá¾µğxFÖ©ZÒÌ2¥Ğ4tVäA/©ÏØù~N>ô˜ÖØjYXzcÑx1‘ÂâçŸ#<¶”)àè
Fáj_Z!ê"6)L¡U®ö®À0¤v­‹C›™Hp¾›ÊjFwhˆ¤µŒ`}Ã]I Æ|,êÕ8â¾˜&ÔEj¦?ıR¥š®JÉ¨¢ı3ÿˆÂ>9äˆ’GWÀİbä2;{LVË²L&ëü¦&qºVkÊŸJ2ÖÕ[f¾¿=îôö—ÍUû¼q6°)ÖùwÁ?œ¬ş®Ñ/­à;ßq ­ØıY3N,ƒü®Ñc¸.§şRËpõá°$ù!EK¡ùwrmĞ’dÃ²ë^ãxçŒ"Pƒ¬C6í‡‹ÛÍ€5™æ¤	Cùu·Çú@5-%ä¥vk=_ãÜÇJùh{ÈmJÿ \Ñ ¦oµc·tŒRdrÔ»³gƒVÆw‘í]+×KàRªY{xµ×±hR<feóRaßxoÑyìåoÃÕ§Ôl3}wÿöÇ3zİÚŠØÍùüeõDüñİ‚IıKó2$ãğ%†6?¼D	Dée’$
˜­ĞHJÇß×g3||•‡v éÉ¬;usã:6sDã$¦:)qÅ÷ 3‰Vê/@HİÉşÊ`/ÇòÀÑb9aİ˜SdŠÙšŸA9nç; À’ÊoÔ® mç~Â¼¶[Ä–Ì–—†Ã¡,¾ö |ÁÌ]ˆÚR‰>öpøşç"–¶(¯¯‰°¨-ŠKï1ùğû‹hª“~š_©Ïİ5ÒÂ‘î(ôŸPë#°3Æ2÷Fu!™|UéLÈ ¾-Ú¨cˆ®5`$œªá)Å^	fô±¥kÒã9«òfG2óÈÉ2ù:Ô€¼yïƒ?çÉñ{yŞüËbºïZ&’a/ãœ@ÃM}¾X¤÷;!yƒÀŠé÷CCÚßƒÑ©V)O|Z±iÆ&l’Áé¾"²úšWsäõ´CâafÔ›Švr/+ê-2Ñ'ô¦E5}Şõ¯æÔ5	ÄL‰åøø’oä’«½“t2±®ójV*ÇiğÃO;šÀÒ‘C°Q¼¶>¨—×ãÔÚùÔN³ÔC‘ìØ^µjvŞµ;¸MçİI5}ÚÎŠ€ùò*ÛQÎrÊ.şØFıèVf)6J{Báğsxª8Îæ,ÒŞëltfµnƒ½b¼¶›:§ò`F6eå]èĞI°âsş±}\$p
B»–ÃáÚñ	-
ĞL†2-Œ­z¶ŠlüŞ>îè¥B«ß%&¹NÈ¤]¸4Ûû±öõÖæ=‹›ˆƒèàVŠNáD’)‘(µ;¾Œ>,kï%(P!™FæŸ‰÷+÷>^H®:x+Æç™”7Z‘OùæÂBQv
"¹¨Y9†Hø¶k·ò_‰7œ^ğJx^L:Nµ¸)dÒÆ%ö\yHÒÛ>WZ4ÒkÜ!£"FÄÒj	ÍÔ>ÖÒËÈ¢™°“¸85;å¥Íƒ<j~ö&›8T ı‡vgfŒ¼åimşúÅ36»…1=Š]<ĞwCÍÓÀıh´%.dAêJÿr]²éü{¤*r9:€ykU¬<L²ŞyPFŒZå:Ú>ÚØNPó³Š‡=›Ğ„ÿ&i‚¢]É“U›Jræg(G6ƒÂÑü½••ÿ‹^ëe”øÅÀ‡á!D±£(£š…†ë:wö¢m •ğRŞ•³2Môeä€Ç·Nñ!C³é{ò_´+qkºImBôT±Ä‡ÌíÀsá$8¬=È‰Ã[…DÃòzoyçÄKâ¥]êï€~â.NPXÙÕ’–BÓšoƒ–00N‚µC
½ÚƒRFÿëBGÎé‰d}ûH4æºğRãÌO±~ÊYÑï½|íÀ(F½ ¬Æ–Ú‰15'µ£•²`%À~pö
Ò;ü,ïÈ€a@­“å¾Î/®wÕ‹v‰>jtKXE£ u×·ãX–h¦¬ØûïO«r¿p'çˆAL³NŞakldãò3ÿØ"dpÇš£„GC™aWÛ£ÅB#ù#¶…ìÜš2‡4Ïl::RºÃŞ“]ÌšÀë3–Lšä“ÔÒnÚjŒWœ’¦J5*ÀĞÈª|f<+{zïv$Ån©ÌË±OO%¯”@1jóu°1‹œ)÷ÉœæªßÓ+Ìb½Z›g¢-Ğz§¦œ„¨!T·N}íp3RñÖ¯ÚX†dV”D§d9ÖNMş½d
Ñ¨Ä…|OûİX»¾=£`ıû[òÙÆ	Ñp¢¥§/¬héÿÙ	{Ó~b¸öw×~[d¦i|cj-·}ö_Fá×}+'læÑb¬5/V¦İ§wï9ì…:|Ngú^“×|±**Ôé=ÍÇÇ½íúWS€Oß©Ê„A:t{„Ú³«F¦Å¥}Xšä$]J¤ü•8¨ÎŸa|,jq¾ŸÊ2şêèœ¹rÊàT{-ÜºfÊMåå)ÈæVoç[á€†…º8‚yÕ/^…HS›ã¤şÀAÁ…ÿùµÉï–¤¸{éÂĞ*cùdıHïŸ™ã?–1å›ÆÍc,Éœ£"	OŞAáÖPFfıŒü¤Å—ÚĞ x]‘ãî¦+,{Äëú‘XËÔ£hë¦âùÜOŞXØ¼=ÿPªD`¹òæo¿ıR—Ò‚¨š’ĞË&°Á¬ôb¦It°à^*>“pl°"jÎ¦<Ğ ­‘éäX¾Ä\‡üQ÷½¬ø*p~Î=ãğïŠ>:û¾“¦Cß<î	æJVÉß¸oáá¯¤,ğ¬rÆ|WÊ·^Âyuî0Ÿ-Ö%LeØÊã‘òe¬|L9ÇŠCO=ZÛn¤£Àhx™E3®:Sæc›ƒ+Jº),äJ¬¼Ìï÷9Û‘eÑ•›ö~é ıºyQsìòÔ¯TüüIZCS;
õ~çÍLú²Ú%AlpYHâœo˜ŠË
½—¯©5PkOî‹ß„­uTV½èë†©¤A+«üQ;vbÚPO¢tæÜßÀ«æ[ÎÙl-Ú™JØå‡×=®n‚zÉgŠ×ï€á¼k’NPwÎwˆËìZmŸDJ$œ¦\´ÏÚJúàás;ï–ˆHñ´^ÄXÈiéñGh¨0ı;çÙï%3Î!¸º§
1ªõ†P8}ç+ÿÃ²ù¸0£¶q6¸¦Ğ¯k7/Ö+›e¢%‹}¶¬„ÚéMù3Ê‹÷£©œ2qn§`,¹×÷!óÆÉûö kZ€9$îkáBYíO¼ojeO)?5 *6‰N1;ÙÙŸ¨få$–@VF} ª5iyæ¼ñë>s’˜;Ï§ªÂ•»Byr³FŠc“Z€Ïçá—³E†zü{÷R:ršswòñB8š·)bköøumËmÊö€ÙŞá
+²ü.Ó€Ñ-Ğöpg¶gA«B;’Z_lª¡nËÙõ€8.Ô¿Ç£	gÜs:ÂåúşWŞUª_ˆõ¦ü§!Ënrbx©ÉL¯^ŞZ£¼2Ğ©
Ázb]±mUÕÜŞÎ1a áÛÜ-÷õ#d¯Hä+½×çÃÆ©Í3<1)%h/‘j«'şÓøTÃ‡„’Æ„<@FBë™‚³5 æ=¨v;ÿëŸÚDÁ†İÔb<÷|ø•¢
 Oµ{Apı£öè%0œbP”MîÜ3ÁØäıôèaÊš)À«8«å™%Ì1L¶KÿÁ›²Á÷j2ä4ta0?¦lºû×‚ÔOäNàğ¿#…ºİH¼¨±£áéh$CŒ·&%`$Ja”kWæî#\Çû<“¾)®²#m2 7à‰Ù4¥leÙ˜-]óÉ?oAºç<™ÃKJK—Ì4œÆõc­µVÑ»LT x/T/3õÕ±å‡H,¹TÃ†¿ôU*á™¥‚ú2¶	’éç¿ã0:€ÈÉ¢
T#	ãÇ{	énv&ÕØÓÙâM«×¯*§Ë±™4±ôÃ…şı.Çò‚Tgª o•ÉÜŸdú8ƒ‹0àj)>‘E˜¸8*ñC‰Ò©1[æÔihöñ½UÖÚet Ü×€L}Ñ’L‚¢ˆò½SS#•2YlG)Ø&F Ú3Ú‘&®.l·‘…¸{>8ôFJh2Ó	~ŒÌûs–ªüvî—hâD\ıd…wŒÍQÊœ—Ó|…útHˆäĞö¼Î›ñ”·lòá¦Çêi§	¬î=Üo+˜~È–9!Í«/0y“ñ‡æ
I]‰ @ „±L*L[G®„ñ0*&E³l¾HÑ&¦vÛ¥úmÏcYÒÆšŒ:ìK™üeÄÇNS’€!Ôu nF"zÓãoU”j8s¦
C0ï²Œæø™Æ®\WøÏ]6Úu§ÔâB/MÉ–íqšÒ/Æ[ç‡M²3QÏÌKºâ†Ëd–zÅÏ „*¼U_œØĞûjO$ëì
qİ^IÍäÔs3˜0¥`ª— 5
Ò¿<™ò y¿|§'’çà¿ä+aUFù„;Å®•n)Àââ†=pó  xúö–é+©0Ç1Ê±ˆ#V;GYNåuÌ‚tª€D	ƒ©E%MyÌŠˆßFÛƒ‘ÂdÙõ<±TGAd'Í×CßS³^ğ¶3ø½¥	j˜bcA‚ßQõ¶VË¡MWLßX¿ziöddÊg6½ÛÑ6ÙgMnálô^¾*YÜâ
ÄoˆÂ¬˜‚é„¤ùT²è­æ?qAkæı
Ög:\«Q¨–®ºn–Ãaÿ~W¢‚r‡Ş‚ÇI÷[Òó“À…õ­æ ¬xá¹7c‹úÈÌ‚p/îPî”c8¿Lï¶fñ±¬ªS ~ƒ·5Ç‚Õé4)¨ƒYG´ÍKµ8œv÷)µ}¯¹òŒ€aŸdƒ¶ÿ;ôÆ>‘ yõ}…ßäÏûGGo¶C%D+•A -ÂœK)k×İŠG¸	j5ò+è+b—”¯ĞW]¿İ\,?ÿeÅ}$6±Æ‡´_S+(Î‰‘Ü òÜî²D·yàS³£äÖˆZ¥4>mM{eÏ-ë&ãõ[ãp-èË¿kõ$o]³uaŒ.…d¡\EŠpkPm›)5
Â~N¾¥T#Ó(ñ3Ökj1[Ñàd›“<ÂŒj¢7ÿá
·›ûOlz+®~ù¾ĞìtçPh.åôìœ­Şğ«|P
÷5L-ÒiN(K­CÇC¹Ú…›}“ÖÊ@;«—#§kü)ÁûÓj±¢£Ól%11‡Ç’2ª#“‘Ş³Ú£D‡:Û&µwù¯ìªµ· 8šc§pBòC¸?ş×j¼¶g>Æº¯R|÷^úˆ>¤™ERŸ£ù‚7A—49Ñ‡¤Ø­¨ìëÒó¡ÿòÙ×}ĞË;dİ+†­w·KÃşFs“x:ˆ'[¡ËETÀÑÔáùò:ÇìÎHç9¿RÔ,ºƒ’x‘²uº/¿<yöçºœÎKê¨jNôn×øA}ÈÄ²ãùÃ{Ñ DÑÛÊÂĞKÏ"İìäe"s%ì3ZË)‡´Lão¼ÏÛlû7ª«tlJPeĞ6ø®IÄşñÊ–/9ã¾´S%Í‡äÁÂ™u™¤Ğ-Ó :M6ë‹™Mó•²”+2Ú¡cù°òi×U3ÕÓ:…e¨øıEaÜ„–@Ÿ¦6ÏÁ®¦çK¿øº¯NÆ:Èa,o¥êêÊMüùLÖ­—v<öŞnW@lé^,É†àÌßÔ/¹~=3k”İ§wåO†î#§2=ÑÉM¦?•ü¾ˆa¿ ÔëCA#]İ …_Çš¬*±‘3ªÃªC‰jqìÑöåT.ñÁC¡’¯öÙòiÀ2;KW—/oóQ*µğ;]³‡Pğ™™Q€@¸-Ol=«ézÙÜoÃû„ößà?Ü¯Æ2vrQ*a‚5"oÍ‚n~€¥êpø9^nk-úWíĞ‚C&/EK[­†OÎ”lŸ2Î(Ónk¢!ÎŠçÃ@gwWiO£¿Ê"9*ü%ÀN ¯€	ôÕ”8,ù-²Ürè…ÃÓå°_MÎ"úşô†¸áa¬¥b¥\òdŞyyÙÊªB˜ªl>¼…¦~ê]'û$TÚÃ²9V³ÍTÉA¤&ÈÅ²`û¨Ö:bXôõ¡{À+_Ë²äúı²¿éÅwšéõæ¢=C]7Ÿ±«o·ñë‚òq*jFüå¦÷˜õ»š]ŞNNäf‚ƒúBIA“ãU3ÂÄeÌ·'|låH@–P´ÅXÂ+GWDÜ*àw@N²U µ²TK8gŸ—T¾gX1öu×§¿0ÑM¹Cº‰‡@ü±FO A½álU·´ ñµt=—,ÛhKÍ§T¡LÖ‘cğAdrşH%üêÌj ÂR¨d¥2Å4™8Ğøi¬rê]Òî„|j
[8İH÷]ZŸì²"òHJ<'$	éÇŞhÅñ¬*‰7Ò°ÆÓJ:K_U6}úC!ZÍ‡£Ÿr[-•ó¬4GTÎt)Qäw[;u|±ÿ‰çW©¯gòF›¯úË¥ûÉàİYµ¼®voúÅÑrxÎf%´Øp—²†¸²ñT ›édfĞ8}M_z¼IL=7|(FÙæ´/Ğâ[_ôMß†­«C•~XOÃÏÁ¯0:ÿİÈ÷_è´4÷eÅ¯Ázÿúûn¬Š÷ÿe#Œ€ŠUé(| ÌŠ6DI¯3âßú$¹/šB.î×À .§Všä0€¥3iEäªµÛÿ•s%Tæù†˜ı.rÑ—|/Õ€g¹¸Ó,Øl••·D»û¼‘=‹¯Tocüå\wüšIZän„Á‚¯)–qÈ…8x˜‚a›İÿçĞKgN>ìã$Ğj&gy¦<ºÆíùZÿ½…w)²òQŞÕhÖ_İÛ ê¤N•JÂáĞIÇNëöm¶!#&xª jÓ|«(ö³Ca¨j"S0á¨O¿@3sL¤&Ãä )n\È$>8wg)R«Ş=„Æ@´&Iœ×2öÓyõG)Uë`q1„|Ù†Q'ãPÃ­‹Uidæğ/ğÉQÛ0yaÍòq¡=#zÑ`åTği@¥]Í	“6øÑü‡§P…XK;œ•H÷˜±w	ûrGW¡h6>´ş”¡
Åï·:º;LËœŠİÄ{±ZÕIhÔ	#%¥ã;¨ã¦–%äƒß<­rU–Ê*f¬¥‹XÈsè‰‘_1¼P¥®d zØ!Qgâ×e™<¬ı$PDyÚxlNGîiùpeM$3»ûyÑ›Œ¼§Ôp|Í3¢!ÁÀ¼IPÛ ‘Lg_³¬,rˆÎ~J×èÃË•GôÜ›x®ä¸i¥ Å†nÍı!0å¶‡ ù%êÑ—»Û(+Éšqô{&~ŒúÂdõğµ-ßà´Ê’Ñ¡ÃËkÎù½şÑŒòTŠÉ!9®e¤ó~u!,u±t–*Uşø9FÒåOÏ»uáÊ9†?zodf1¯?TõsV!-+¿ÊB©ÇÑ??ïñÒ›D±QK*yôèmvæJ•Kì™÷ŞÃœÌÇ²Ö7ê—(ÇÄ®Ñş&á şg;˜ŸqØ1ºbÖŸTr•ÍS«®ÏÏñáípv¬ïâ5áEãÌÂ¤ylq†_öVq»a17WŒ2,¢¹ÁOSÆ‡ÜH­´2¼¬£÷êp³WA¸+ê¸æzÕØ—ìœÍf¼ûYÕ'PiZl„ùì6‘ÀÑ
¸®p‚0â*×ß
_kX5»©Z'Û2ƒ½óŞÔ–9?OTùH0OnnÊ¨I·?{bPüI-M|ã]ØÛŸ¤|Ò£‚{s­st}5Õ™o»ƒŸK ›˜X4Óî°#F™FÈFh¹îjËt®½SÂ—e—‚¤ƒŠ ø±Ä¯¿Ù)£¢Í·‰JŸ'A›ÄÀ9ACuâ7x}.D"ŠeO
f»=`½ŸJéÒR† e\Æï=Åg	ğÇ`SÎï­#)¤b@£°Êˆ]D¸ùË i¤”ş´çÎ\×Eg…ƒ™?Ñ¦QíæùF:êó½p¿€%ÏqÏë{Qàú?3Û‘ —J¦„š¦Î—jó0(áÉ@İ/lbƒ¤Ã³p—ñg¨ãGTşgBÜêYÛßÒN€êçvÂVÖ/\ÛŒ(4ó¶e·À|»ËKåĞÂ¶ÈGn¾ÓêD˜+9T±EPu	4½Jã!RŞ´i|èaíÀò‚’ˆ-Ç0àŠ+måïbÑ
ˆõÑfãê£€&Ãá;‡‹ş‘a¡VÓNxàĞ;°’à7
ö¢\ˆ¿zK‘2È/½òDÔˆdßÑS¬ó}°Š³BÙ,æq4|TyŠÙ¢ó\æ® œ™È‰‡Ço ÿááÄ½kÅŸU[Fet†…ÉâÓiEìB!‚4`
ˆssJæQÙUh©0–+âmäãnLjçW 1<ı§×~1Ç4÷ï)wÅƒãö aãº[d©·ÑzA¯^Ë|\ê¶×Ôôw)æ‰>bìÏ×$Ukc9ü¢ô¢E2ùÌçSÅ ÏAùmïº/€nS* :r†_Z/~WR6AãßÕ+Å¡¥™‡(ş/›“ƒ‡¦†w(2K’âÔ@›õ•´ÿ.{»¼`ÇP#ösrJIKjD›“¨‡†ªÓ”çÔ}ÅÿH™¿hşø×IÉİ?×}á²tN¹„Ê;Ù(À¡¨\ªA]OˆõˆL]ràM¼¨˜îÇ27«>,a}q=@€€–ÜY˜qCÁv‰ŸDÈ\œCğ#ç¿kG1y7Œ’ Û6‹âÎ(ø½ÉdÑqFxEl×¸¾ˆw¤¸Ù©%Çá'òµ³ÿÅ\ª›¡óuÇ£G=~¿ì*Œ×’M|îÌú”oV6
ª\»LëPòE:NŠóü]ÈÏªôÕ1úPŠ@æ\gAËÈ–éÃÏÜf÷NĞ”"õZğ)U3W…²Ó%%"ğ.^R;q[™SA'& İÁÔúéîj]ú‡Ñàyò.0p/ìA¦n4jÒWÿuÂ~9OU”<t¤4K”ãñKoıãóägÔ×:20&eiJÃöeÔsÀ®Ÿ72îí7š?[7Óç ±Z²«ÂÒf–cèJ/İF
¡ÎúÜ¡ÄíZ•G†ñóUù`šW|¶‡¯¨rRg¸Y¾.¹3I¥•e£1rİÍæsùgå i€}Ñ½°)ª¯ß2rxûÇ‡š¢İ*üöa:`¾˜„İğÚpwr»u½Ï†;ƒ’ãl¤âìØD<Réã]FØA y	G‚t8ô=gT¾¨c]ÌQEp\Òî5gEÆ•8‰˜À¨¶Æ¢ ğ‡ŞÅD8YŸÇÄ5i+PÓÉxøÑŞÔôöev¥®”"›ı?FÍçªfkªQ:×µŒT¸O#êì¡óğ/¼«^f=–¹àÂ×	5:¦şZ/ÿéüê.è%«¹±ú"íİCN†Ó8vœ{›Ÿ"JwxWœJ¡6è»*c*½/Ëœˆµ
@¦1¡Ç’Ì24u5±9D>¦õ"¨ï|ø!?lŸTó¡óe¯BcĞ×4 w»i;Ê‰u• Bó«Pcè—ÄgÍYQq¿Ä}èíİ’şá9x4ô8ü+¶h•ñîfwˆ4¢"y>§˜‰vşŒmà½BÌŸÁœ“|‘yr•Êtşı‹)·“ßör:Rİ¢–;£çÀŸ]ÍØÓã	öÍ*4Ó< ;ÆæıûÌˆS:W lè]·‰xèWSÂÔ»Dv_o—¾7ÏÀ:Q^ØV»¹Ü›Ò5ïƒ=¶Ğ‘KŠˆ‡òà‰Ò‹ÿ„¬cĞK8Òı`?„
î¸ŞG¼”"spgoe£ËáĞ±ÇqĞY;6”ÜináÜ¤((·2ä,Unò£ P¾Ğ›Ê?\‘”ch'ÊC‚»?u¾J Ãé~†¦œMEèFñ¨z1ÇçZ‚]™îûÃbx¡ßı7RM¯ç- ®ìÏãìcQĞ ôpç ŒZ3õçEàf“0NûÀN‡€.$iáÒëúg E+•2ñaïç"öÒòÃãÈñ-µªb0<-;ñ]Iîn—ñ6šG;Ä­M:tWÖ»O?À(<ÜÁÖ ŠÖGòÂäI<Ú¦¥%rqÕEa¥GHöEPŞo5|ñ‹ˆ`ÔíPŒÊ!º†o£çÙ“¸¼l¦B¿GÔHRİ¡ıc›6¨xµÄ¿cË~'ærÇÎ)SSU
DÏfÓ8û‡>z±©¥ÕîşîîD†Õ•ƒ“Ø[†]üjşÑNØ]$H¢nûq}ü¥¶á´¸Ï{7Ç™àé+İâf¸¨Œ§0ã`•=İÓ{è5nŸ[SáßÎVT¡`>O¾†Mô:Î‡ğÆ‰î~’êJMzÕtN¯{¾„ÿ÷eYcE·+¯ğpÍ -X2æ§A$½Ÿ–] ™@ÿ¨»SK#zÀÑhïÍ‹DşdÑ‰¬#;°o¯àHB…¸M*i¦|ÛI ï¿ÓÇ, z¾EÄÏÎ}aKó4á1ó“WØmÇğÑßÉSƒE!k-iğÔ(À7$¯°ÜŠÚ˜çÔãô™Ö"š½ÖÕÄ.ê>[ŞÎƒsı`ßM°3VµøƒI®¼$sØÈ÷ãaĞoiCƒâ nM:ƒAÑå,ùëWoVvJA#Sæ•ç@Jy'­ÂêÊ‘ÅFy»yz´C)h%¨¥\~@Ş/`³×ĞªoOı±ir
Ò#NBZ©cÂ
‰\m,ZVã ­3BŸğàïÇ~xˆèŒnŸè`°à6°9¶#ô¯y“ÒŸï&¼İõ'¿ø^`ÓÇ¤C`ÁD¦P·R2WlÙ:/pØ¿VŸ…•ë]•œ9–yŞ ;]5n½ÖvºŠŠÚStò0K^Mı¾‚¦,¾!ó'Ù‚Ä»¨ªÅèÁ4Ü‘9ˆåv^Ôí^»Ê¿Y8Û„à˜‘Ú`„\ŸD¨ªûÆïªLw-ê7v\æŒK¸)ü6MâÊòÀ”B:¹ ­­ŒwbÖñ´ ıÆES¹i÷Q?Eî¤Ş°×û‚rF÷{ßãèéÅÜ¦ÈI‚—mÖŞÍÊ`MV=À“>1™áHİ3C¦©?h#%üã,¨)*à~Çx0t>¥ûî¤As—Š™ÚH#:ÀPÊ>rÊ™A¹fÁÖZ+K¨C€ÜÎ¹SÜuy³e§¼°‹vÕÉˆÅ®\óŸ‡ó‚êíŞ€Sr6§äKáAäYTÑ{—]-‘²œ_U®È˜Ök¸ØÔ…6
“šÀ©”d&5Äİh%UÃüfÂ'Gæ£iİÜÑ7¤A´*ËÂÕiO~M¶H"íèuEe/Ë)f³uµ±aS5pı9ã÷nÊ «Ğ ş–k'0éã’Ä¨+këkWx|ıfBSäôÀ0 ¢P 6áı)Ô/õ‡iÍdÊİÅu$jÅ(B´œj]8ÚIüws(D¢.²½)q&˜ø¶îã˜%§O*k˜“iÀ§”h	ç»F=‘«é†Ô®ƒ«ô°ÏïIÉòOnÈ2ã—£µ×¿µ„Oš$Ø_‘İz¥R÷ËW—êi½.:€î½YT“†}Õã–4¦,ÆÂù,Sºƒ£¿¤«WŞwªˆ·ğs tHûËGÜŸŞ…û{{¿D5ìÿa=—|$¡Xó•] êôPËN7Pºv••+] Ñ×›ìÅq¾	18Ì9­7¢¬U	ä­ƒçZ!æÇrE#¿âÎãã^ù~uDáU5K,Ş‘gX2ÒıÕvÍàpÉ•…]VÓø3Ì—¬°Œ8ø®¸'Eò>7¥óSV³ï‰1ªÊŒ@àñ•E›·
»•’añËåSc3õŒAŸšq÷ÈO8}¶ Š	Ç	Ùâ¥d®9ë,ÄnA¸İRğ”ñ"V$FIˆEÚFÇ›_[í‹ÃîÂñs‰r|îmG)]Ü¤U<¨	cIUXïÙ?@µ8¼ÂF™ÉVÈ®Â #_™½c¤Òtä¹-B\+$–¿–•înÁd8_
Ûˆ}]’a’ò#/SÀÅ&52(”ƒ7æ8 •±¤Ãm8w0¾"o6RŒá-mÃ“U!Ğ$ç/]O³àÆïN´qÿó47w]–}A1¼ö¹ÄÓDcT/ÜR¾Eéÿ;ŞŞµ.İš~ws¥“á+§ÑßÙj“Ãë{G¡z[Ãfs\Q’9Ş@(ıŸYùš««ô†…ƒ|‡V±'Š§7Çå¡}¶şQ#ú“ÑàaZ%8»)w œ(—}ùÃÆ¡"2ÇfDÛÜC/)‡ÆşP¯¼Wº¨Ò“òˆøOrşWƒ(("Aê@CaŞyÖü­g¥BOïz]oˆŒòAE ŸÔ½šAÿ][F1]m£Àzv®¾¨ ºèà_…sAgbTkBHş½À×¿5›©·ìLZ¿7[Úò¯Â¨\¸ƒîÚC•'"Neè¶®ÄéÕ­``1eÆlXòC=™§_kêÁvŸÅi'ÉÈ1Q/J:¡ş8Oì92´X)üÍkß{]W*ÔBPï™`8Ñîbm¡y'«äÆS‰õ4é^á©ÅÚHeÀ4°ö\À–.úøÑ²Ñ3õÖ½éW–ÉQ±J»2ƒQ[iO¶Í/6ö	%ª‰"d#ºHÏj¤ õüeßàz¢“w,Š%´
=‚áù%+ú)/Æ6ÒYğk.lÅ*z‡œ¾
¡vydlèo•0¥@|¼Ûâ]n»9Çs‘½Ñ¦nLbÅ4ÍÂùÏŞˆ&Ğñoô5ÄšqCtÊú˜ Ä,´¿Jõ——õ¡<º™»í]Sgä«ñëIäù€Ú¡úõkøõ§HÄ€Şå¨ªÍû¢Æ2€'b;›ôSÇCºÆ“8ïÈÚ' ªTIöÆ”GMa'óÓØt7ĞR¥¢È5¸Z¹4rD^™jÆSµ+«Àş¨,œ”ñî^~itÿåTQˆLŸ*ú¼Ñv3÷»¶Eû¬Š‡Ê‰ˆà²šD7D‚¸¬ê‰C:_#şÛ˜ìüÿ÷µJ€àŸ)*Xä¾ğ=…÷`Z ·€UÁ‚4d±9Â*óM‹d3±_¡Ü²™XÔ’îñª:c CÄúT«ú­)ô…§ZÀ´êú¬ˆwÁŸ'Âîÿñò2¿©È))«CÅ’GĞã¨‹”G$XÜBÕ|—C‡ƒ«ò1A©Twº¥qB`õ”ß\ìİV™+IrT²ÌLVÃqÿ _ø¥¡&ø»Mû‡GÃT.‚‹D«£›/:Î‘ûá¾O½t"ÔQ]¾­yİÑW,ö¼’D’‘ìyÍÁìKÙ>JTŞlÒïìTD Ü3Dêş¥)•‡‹¹¦(™Ó;àï½¢øt´Ñ“¤ˆj—våõÔªr("°ú¨¬†@gê_@Èæ®ŸQ¨@¶r|=pš÷wC‘j£èSMÿÃe]˜ùMÀY:šìF00ƒ)Ú…HÕT\Cj‰š¤|Dâ|‡ˆ \©¿—DÍO:bf‰º
<‘™è*L÷°[£ê§"Ua_úø?r}XØ`ÕÆåohéä>,rW-%A ˜+·‹¶ZÏ¸”iTsrUaæx}ŒÕ8yôÔÿäæk{‹+›Uƒï)Ş.»è|~ÔÑºÉ[OlRæ´Aø0+6ùô÷áGÕG|Jì¼_§¤­ÁWoŞølR
e ş”Ç×¯¬Û-<$›P“çæ$o'^ğ%*¹ØÀUºÀ×Æ‰EÅŒH%‰DçÑi˜>’Jv$”+ÆAkU·L&”6($R±©‚cõ>Y4x}<ñlÏ'ãÅWö/9#ûÈâÚIœEÅ®q3¢¶fÇM¿a:âÈêqÈù3o±”YO24ª·­TÙL¢ë\VÙ¹ØÇR±¾Úl±°ÙtâöĞî\»™çÑ6tµËrv¥Ä43 šÊ	JÕŸèåK}€	¹Ç{µˆúªâ'ø¨,
s‚…~ùK´¹=8ãûp zé«/òĞ‘­õÜTô'ËN^z€nËI@ J<öwkˆ˜ÈFMùÂŠ(Ã(4$;'şèğæQˆšùæğ”_ƒš‹«Ço~·ÿâ¸0zé¿‡P7€ê2ÃUUƒ«^íÚPˆš*ÁÁjíù*šL•Æş8Iªf…X £JÕ¹9ãuèÛ‚7ü’p¬ÿ§†ÑqâsY©•®MwUÔw%5.]q§çâ…ò˜&ÿ* ¬ÔF $sÇªÓÅºƒ{=,¶¹µ0g~Á{$Z…‹8l˜F5À"ë°„—×Í™E}'D^=ùZ@SuµÛS±µ“ë¹	Á (€Ÿ|4ÊhcRqV‡Á>:sãìUöV×ûrå“¤‡Ö’G…véDJ`Kg%Î]í…«ÒÜgägr¬Œ¼NU[ø_¿ˆÌÉÔRN– øÕÀ“Îê[áO¨î–ŸÏS~±äè˜ÚèòHÆõ]³ãgªfîÑšY¾ HõåF3¥~ÅX•Œ,Yï€ş!ÄP;öûíDÖdjîDrŠ¶¯ˆ™¯Ã!}dìYœŞ
†U‰°âÃoSy†˜ÊŞñ”^Ì«„ÖıqdÁ·İîİ¬Âv“å³‡	´ÕÀñ=ü´á£\=ú$Qp¸+
U­¯¢\Bc\Î;_7~™¡Øe…FíJÑ™5t„8Ô+‚î§±ËÎ}û´Òõî%7½;"U ®À¶â-QÙ< wı²ËŸë3”™À†}I–®Â°Kû¤Ş
V:ĞÂazŒnë6"†Ï:*ÑæÔCxÔ¸HŸZmR|Ù¢<™èşe5FãõØ•î¨"¥şKä¶º.Ô30Ø7´»MÇÛ{ÊÂB»<s‰2âd¢âCÆ•ğûÄ&î)ğÏO/×Õq´Ì[Æ+ÌÁĞœE&ª¥L‡J¨ìl±7Íæôâ¦•ñøI—,U¶àYO;FĞ¿+¿Ş~Šœüå}ªè’¹¢{½è×q@µ³×´/Qİ£é`e¡~`‚<¦o‰Ä÷‰9ûê¢ù{¬zş/Ï%²:/„ç½,/$o†æôèÑ®1(v»x%…sJÖA•h÷-¤[¦%ô¹#ŒâéÀéİPÌ»-M…Ò¦‹šö¦fT]l¹%ˆzò®S×4â1DM•¨ÖC<TUmY¼J­9¿µ_°Şñ†NKõ3™ä±3Ú›ZÍûÿ±~E±ïRr5<B³—,Ø~••æÕj”>“Qé=ÇÇ$‘_—xSşºoze…ìiÕ5_4Siâè3jMèybÓªBuúòO>¿œøüN(CÏŠŠE–àÆÇìÖfõ\êÉóêº^=E>0¹údYOÿ×Gàç µ7©¬‚)xÂ˜7­g&ÅƒHhß‘5îä:¢!ıU®ì\z-~Q4#œš)Æ¦ Ö‹İ/u—qk5BèKfL|9E˜›ğA”ŠguÌ²ÄnkĞGqZ<özH&wÚ%ùó†²Áy$ózDT©ìGVèÉ&òß¥]ªÈrl–¢5¯ÇRü52—„@PÕçÉ]eùÏô%ü¢§ªırÿÄæ–l,	Ns5İ¸À>|?±‚‘ªCÛv×&ñq»Å«c¶ÅÄá¿o½€ÚEw¶:ßåã@“w]L2Èœ÷[vRó9ÊÍöÏsÙP‘ì(Â¡Ü^âå¥¡óg±ÂbÙ1P›ÑÙz-ƒÕ
û6ã/L…_îHÎ“ò`¨Óó¢Á±½ãæ¹=JÃ¶PGR&îëá~ÿI?³­O=°h‡&Ü”áG#Y‰Á±(ë¢è£¸0XöİÜéLÿèkRX„fÄĞ$a(ûºÑ®Ä•)Œ^Áq£~—[ªû‰VãµÌü…Ô¾7bOklCÃ S~¥~Í*mmz”OÇ\Îkß­—öúSÙÒo’@¹U“´HOÚ—ÑšNÕı8'x)B7(üÆãc©yk.Õ¡t§C¼jÜ»£´’Ÿ]©* îö{ÅC‡ç$(CÊı^=½6ÎüJ‹¨ilLâ£{DDs8oŒÓòÅù¸°wä5$›Şp3Lcx€;".Gf®«w!¦¢«-—T8Q9Q·_
;ŞÈ?…U˜%Š¿²wèOgÌ;ì| êwûzúêºjœùÅ÷noyY¹SCÚŠËª9š	à‚„®ó§HêòÇTg3å(âcJDÚ½Ms¯ğ€ìØ§D«“@27ì)Î¾6*oÿvªÀZvDí»g·¢£O¡Ô-·¥¦z°BìÑ´‰ÒÁòçøë_À ‹€Ô³¾–_¾fæ¼	ıw°ì!nÌ§‘&8<Û&ÿş‹ó‚†vô ]‘¹u0°¡î¼‘ºàÿn²P0szFçÃGÇ¹ª£åâ…[ï¯Üçƒ"pF«X–ÖmÈ„r­wjx!uHÀµ6ó¸—Ş†îD4=«>tĞ¸ëÕƒ¸«™¼¬ò¦Wı ”~šîƒ¼<{*‹`‹ÒgyqkµîºQ‚«ˆ1ââ¬p8f¶¨%y;‹˜sÖ´¢%UÊ“»(urI‚ÔÉÓ(Ò?uã¯CDA¿Áˆ?0Ti&@3 x&“VuïNèŠ”¾"…Šh¡a¨¢üjZÿ/Õª"y|5ùN‰H+Í=J{ª¯í9û†dÀƒNö(¡õp‘œ,
Oñ0+³û¨¢RS­²s+_Ø„Î±8J/4µÇä?Z©‹£ÕD}LDM‡le¼ñÕ
¨AE Ám”˜Âé§ƒ"M‡à~J›4İòç’Ñ8=æIŸŞH¹ÉÓÿ†¼j*Û5ÿ3ø¥•)ScÈÔ°N_{ˆíõ2;âåiı¤p²ğıÉ`Ï´ù{Å=Å|…µ´Ï¶+bŒÆœá0€6 °Ù€US«h½ıiÚrÁ
gàİIV0úî—¾#İƒ¶a	Õ„?º©œCQ#¼“bK©<7Å$bMâ…§+Ê³zû3«ŠBdh¿¼E:Ìšxfó‰7šIâ¦¹Ú*IfoëˆÜ˜¦‰N$ÚË„—‰{kòé¸(5îÚÚ/¿“ çMù¨_5§omÕlÿ¸I2pE®ß[DnCø-Ï›—QÙ;h¹«k(ÂfuÕ¸?ÜÌˆŠkÍ3\«êD`.äá}kˆœòÇ.÷_ã°~’8Ù½ØµFÃ­%?îö¢4Wu}øø©ckúü„f×:Ê$Á‰ÔÀ“Ä2.„G“ÃæM]¨t|Ç	d£‡b£¢oT\/Æø_øÉújëø÷†
+|t|í+‘y5ˆ~—á¡m„ÍøUŸtáÃgë	%º7*Ü‹g}h<lµ®Ópf3Éìú‘]@0e”ÓmÌSn|»ÎÉ¦8Så<v\‘»(sÂÎÛ~Ğ°ºÒï|PYtx’Àå-Aòâ™	–^X´›­§¯~Îå²!é”H7¹-°ßB˜,r:+`9ıÃ³ÒatkO©á“øŸ˜òÓ!Fğ	ŠæOŒBÂá¬ª~g¾Õ
ƒ«>)'0ô;é5 ÙŒx‘&±¬z]Ù±U>$ŸBf/ˆlÕaÕ$ú#3(¿äKğtvJ[·~äRtRÅZkwÇEîñÌ]‰˜İ)eMÙè	7#=jkÔñ¹3Su”?Ö\ ¿q<¬1ô·5KMºa°KjWÛÜ˜áMœ‡ò]÷C‰´Mc2ÙÒš¤úZoe£1õHJÃ¨İ`LrtíGlróÔ1µ\Éw¬õ39lÈíË= ¶'‹Oïb56‹ï©?ª»!w©Ÿºà+Ù¶HØeM?St³(ª&£o!BqqÊ½ÿƒ*Oh
’>:±óçg¤ëˆkt]şµŞÜ¢Ó(”·Ó…š©^û™Q#ñ.Å(/‚ D
,W»ñ¼x&úB¶eõÑÉ{¶äí}ûÿY_uw´í>8•³© ¤÷ÖO%sŒğFWš]'õø”-Öz€ğhûbhQ^—IØ+é` ëDy´·ôn:Æ±1‘ûØG[¨|ÒDæøIMJÄ†[TóQw®9øO»½¯¹§±üûá¸Bp<àMQC±ë³ğã†¿é˜M"E2ÑŞ#‹Õ£›'T8[GÕ±ÏI ]Qw :°]'Éµ]­û`B1Ë‰håMÕnv[•´=À×ˆ¦5ƒÅL§ú©XÙ÷I¼ÔĞ²`—ÊH±@qËzåÖ‚›Ì:„‚R(ˆ®²~ l{øiãNÁqŞ¦üØnY‚ }Á”ãÜ`ê²FÂŸÓg³y©m×‡ôsjŸŞÚÏ'¥$=Õ-KPÖ`Ø¥—vJI´Só%h"Š?û´üËs·–²Ë¥<æHà’„ÚÔgX3ÛÂ“cÚGPDExõ=m½\ª{“ôú’QúŸædÜ’‚Ê?óÛèÿ×¬ú»ZüŒL’À~ö.‹'GEó45%¤¹ÌKê1XÎŒ(íØÄ>Ğ¸ÜÑ ÊùQ„Â°`/İR,“Şa(›ßÜtÑ–û_¥ĞŠœĞ¬Ã.EÍ-7÷ıl0ñê²§­<TúQ1®¸Ÿë
\B	§:‘"—Ë¡¸uÜÆ ø,— Ô•¶^‘¢1Ê0w¹™ñ‹½1¬{ç§‰ì¼¿]\(@Îìğ3€x¥½íG(bF¶A%¸–× AŠÖÖ‹õÅôQİœİŠ"^ò_ÅŒnWázJiWçÖÿgîÛşp±5"…Bô$œñRiuñ&{¢P‡Ò¹1Ù 4üƒÉ²&®ÄMj’õèFœzAÍëÕ¦Ñ=kEÎm“³m5oê!{,ôçÁz“{B}ª]?ëóá˜š`³S2º–t>°\ıYÙyF*Ñ=óÁ~}u`È­«ÀÙnº[f_ˆÑB¢ŸzŸa_È¸æWƒ;bIL£$‡hYâDnïi2pÁöˆ;YˆhİC>ƒká“¼0ø®¯Æ’.víU5Z¬,5ÇãÈkGıeô ßåtÑ@Fü€w´oßÃ¿åÁz¾ıö@æâHA'ÍƒjL°pvÈ†İÖÉf”IØ‡«²r˜Ã	Ï6æw¯›«<Ddg™b­¦æa¹o‹¨º‚Cé²-˜Mªµ;ÔÀ¶-!ÔÂxóÕ# ç¨ğ`RêÑÿä2
Ëfh4BÜ?á	¬v¶æÜğ·O¹7ƒ+aSi—şy#İUÙ¡	3<½ ÚP´~Û0põ×ÍæÂ”KvRŠdbEšÃµD*qXûƒ’I­†í¡]3ŒŠL‰øğƒ<uÇ¬%f9½º©áŠ#—”&Ğ•½Xói1ÅÇÀ9ğy‘DÚÿ ƒ©Cc´Ó¨¨[uÏ V˜zí –˜›ìOûƒS.£ék“Ş-á¹Öğ•Gç… ¡(#†ñîŒ$†¬˜	/ŸœS ÂK<Ğ’ÀŒïĞ$vEPéÂ)H­ˆlq+˜*ğ|1÷œŒéã«‡ñšè‰ĞÁ[“øÖdò©Øò =Æ *ôiÍ±Û¯)ØöÉÁÆ Ñ!)=$ @Ï-±ííU‹²ğŒÏÀª¸²q¨ºvïã[úY¥”ÜÏÏm'8ÂÛÒ{ç*ÂÿEXÄ=ÅŞJ5\mû/2öcXIŠ$¿1;†É‘WÚkUÚ9’L5aÓ9fÔºÅfÀöéDò»k¿ l€Õ{üù8ØO]8
¹ÑP¬ïyÍNTœñÁ¾ŠK)rbƒ4ëŒ;HVò³ªwú³ãÚí6KÙ­¿«Ì)à£ ï^4‡›#=Ã–`Oaì ÉR¤ü]c‡‚8Ò»Úù'ZËÏ.û¬òíÊı5ÁÅM|7ÿÑzÌ5dÅÜáŸ!´Ú~Ÿ¡©Ÿì–3 ñlE
ˆ²ÇÓà<ÖåıÃaïº‡XO=øQ†FÔˆ ¥Ó´ó‰ßÌîf.[ß=T&’‘¸kğ]‰˜ö‡éœº³º€›·ı|1ÊZO»–ÎGb§1ùn5ù}u[;…¥¨µ>oÍzôÈ–Æ±l¶¯7t®	y³ÈÕÈ6É²8¹RªRß“Á¹ÔÑ< Û>}ÅÎØÿ „–¼Ûà^†´PxÏDÊ‘Ÿ	'•(­©¨ÃÕûF»,©â¼pEg®‘°äê$@ÿH}Ì#q.ÀS0y÷+,ÛÏ•M{ıë™î{¬‘ªÔM.
¾Ğ©ØwP­§+ïŸù  lMYï'úJ ¨¹€À3Ú'±Ägû    YZ