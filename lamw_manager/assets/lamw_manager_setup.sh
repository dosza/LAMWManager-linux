#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1849094051"
MD5="658dd468b8b31a2bed626e6be941065c"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22472"
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
	echo Date of packaging: Thu Jul 29 14:23:13 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿWˆ] ¼}•À1Dd]‡Á›PætİD÷¹ÿEèÌO…å0\ÇuX
ÆÙxyùŠŒXAQRl§\ÎPHSårFx¶]“×5ãNaª[÷»à°@z<”—tG*9îb4W=mÊÙóÍ:ä¡xyz«É`…ÄõÂå©ãÂ|Ñ =×7Òò•í"²ÃeÈ¹QëMØ˜U)xÊ‡‡ À¶ĞJó÷ˆN)j‘Çµ´FÁ
–lj„±è}éñì¦ª‚#Œxv¥AôôkXÔî‹V/¸íaFÏíÁà§8dN.ÌœJØ°ÏL²‘zC#¯ß;qM¼ÀèíÛÊ¯nNëS±kGÓîÛg&Õ÷‘ -<ËÃÖØÀıˆÃx“,;cï¡‡w1v¹ò"(n¬æ€„òa¢ø·(‰•õ¿ƒ#ŞÙ,+Ág}Øé=C•‘U…RËÏ)©’~R¦ é÷£…Bø¡á3‰×f6.<€‹UÃ”\0ïô|øÕ	Æ eq¦sOo÷ëåˆØ¤8°$hWn3unOn‰Dï!85¾ÅıXÀêÆr·uÖ-êRˆ
š+OşÀ1L$™EœÅCtnŞñ9ˆùÊ!çâ(Ğ'GmuFà~£¤ÛŞm¯¶TƒAÃ—d»°ˆ0iXÅ16ªt;`j=_½Yš…ãJ§[–Qf™n,ôŞEŸÎL´¨.=Êš ZÔ£ÄğÕkÇ±k3,¡ß¯Ïr{zb$ ä#+a˜ø! ¬6÷c“‚Ô½±œ¦Ÿ8:Á;¢ıbJºÔÁØ;s¶ãOàû˜ÀP›0›ù€¥€rXRŸÑçŞ”ùcl–fO`ûgaÔ{x ãÕ“¾Ÿa ‡<A\åh£)}%{Kùò_a«©‘ÔF‰öªš²ªçv—¨G×Æöâ©:Uf?"òø9ÁÈ.¾Œ›PÄõŠÖv3Õ1şQí+áÁõlÍ¯:Ù28±¹U‚¨šøyh¿œ¤(+š<öb2Ü½ş£$AÑäñŒüÓI”÷±ÙUŞHêß5¡½'TÔ¸Å†8ÊÔjòxä˜ÏÅ:ÊH5¨q÷¯R£JP[ø7è~£¤£´“Œ|W%3”÷q”ˆ]L9Ÿ­/q^PœJŸ9¥£‘ó–ø¸FÖ4s
ôvaZLCšùÉ›Ë4w‘­zÜ"Ù7ù¢+¸éÏç	Õ|›ğş©ÛPòùÍhcÜ½çrç:òˆd6È¢ÿ¦ìáÀ®Ÿ†èZtWáM…Í{³sC
ÌVqÍVrİ©PxÈfğä<§Q¢ğzbE_Nú—W6Qq&8£<ÃğüE§©)ÊÁğ`~l#ó¯_DàLÒ@–Å®ZÆ€mh	º”á-&e·Œ‚MçcMÁCÛ)P·c8é†<Élr¬ËÑÇ±Kªv°–SYgP$˜ìÙ 6sÌ/‚–8Ğ§Íl•˜'.7
}k&¸dwÛï2eÊI†ç¢]'G¼Wß4ğ]m½J‘ÖBº›Ø9³‰Ó)|è¼É`6±ÆÚ’ÆÚc7{*z 'ƒzÖöÓèÒaåËâ:šİ
ez4‹%‚0×jŠ½]NªDºµeí¹¦²È?–fIuvá˜ÎjoÓ±îÅ™~^Q	A¥I½{¼œ/-âÙÃyP” p~I°Q}ƒ±XKÈ`FîÛ¬qŞVe¾)^¦Ï…rQYH0¬#ªƒIí†Š†aÂÁéúËN4’ôÑÅ+³Ê5f_¶Ew¡[ İêÍ°l?ü2§J­£Ù ÜÖH €7”ó:Ó+6çXcù…I†!àˆÃ‹®T<Zq°0ÅœQÊ`}Ö#*Å´…ã&ô«vØÌš¡ÌìCÿZ†ĞyäªbÈ#&‚å+LéŠ«˜ÚK¶®“hõĞ¹jÿcs,mı-°÷ƒÉ­­e	ÃxConªw”qâ
+¶!RÀù)¤~ ßfÍ+ƒ_%ıŠ®ÙüQ¶¸ü­¡à]òkı0¸‰† #ş|)ß‘ÄÜ«“ü½SBNWûdÚ»JƒÎrÕÿŒ$Á›9_/0\ÉĞèæ?„ÉF²­ótn…ø‹/ÚàSn5
Â¶Ó[²if¯kLè2º+„UãõÒ´ÖˆæÛ˜_p×cáøO'²¸abçãÅCb•Ú6eB[WÎf[z‚óøŒ6e®9ğU×6ÅšZ€ÊVD®ı¥LE›B…é£¬"P¼RÑn¶‰.eË×p©ÌG¸E Xà¿ÛA¨Z;­,S=FÕ£ëaå7üØU$=÷ÛFíi§ ’Ô¶´ÿ‡“ÑæŞ´ÇĞô÷İY~j„cáé£¹íóÂ ÷ÚL³sQ´ ÕH_!¼Ì{OÀ»Ö*É+0%hQN„öpóÿ:Á!{
ìgR^†Mšvğ£!w{r„]9LyóM¼cäÎÕ;hÁOdúö‚şKa=B ´z‹û®L!lo%´¸|®±¼
ø+™Q¼‹mà5sĞ`õ¶Z›™ô@eÛ¦?do$gßS|çyV<ˆÍ&YäîÌ'ü`«>QS(zj¡ÚËÜ ğ•¼<.óš.Í*K Á¶‰N8ÚÖÕ×_Ï·æs	%”@…ß³ÆËèp6÷’ÙVË¨yÊÁ½*j‹:*¾˜u“„‰!¡jœ•Ä¤BLÈNÁà­®å…Sf;œazƒÅCg¬³rl£÷òCjq&´W ÓÃ„/Úàö;!„;êÒ{óvİˆÑ¾Û"-±*g2÷ŞxŠï!ãÖëxdÙšÓoZÃUI8¬Vµ C¬I
Æo|
×Ònh‚­àøˆpç–ÒEyÖæRO)¸€
ÚıáØ‚’]ş‹cŸÄ*HuËPEQ"é~Q }ÈÎˆÊç“!m”çLxYÖ°LœÖP£”2½/ZL˜”d
ü’“‹9LƒZ®©üªÒ^“4/X$vsàâóÚ2ÄËU•¿XmÜ,şİºó©’ÖnÃµ›
ò*ßam»Ò¾:4~Ìk7sh„	ú	ÎXA»S§Àr€õÙ§êÔ|#’§%‘mŒ¹!½ƒ”µÉ¹fº«r¼@ŠÙ`ÃidF÷™ó6£Ò½·à¤ß¾Ûw†™ú¦S6qZú½‰¶Tp‘¯‡i6öxëuüÊñîÏ9KğËAiÙ%>wÅ§ÆË¥_¼Æßë•íùgLn%gã°Ôo\Åj1vxûÃTã§ ©.1Z¡kääÖä¢ñ9ìû}•±ÈT†LV	§¯‡¢R±ÕbfEî¿ãyÎü&î4±ì°¿ÄQJWî°¨‰÷õ‰¹'Œ¬ÍŒ*KD³úZJoùD%DÊpñœpÂ‚	¡ ˆP™{ô)Ù`š•Ù¢Ğl…h¾ò2õÛÑ†I¹ÿµÇçı5ÚcÏvª×Æ2X(êü…)[°ù­¨û°fë¤œYB9j¥âƒrª¢.ú€An‘±Í¡âN\™+Ÿ'±2cfØĞWyºW+JÊ…z¹¬KYÂ¤XÎ	XfĞjÌÜÆÈ"¥¹ÿ/Îj˜+ß·ëâ{#”>ôVÁ\¨I0µª§
!G^8³GGÆ‘İĞ¯…ÂïDLu¯a]÷P^ãGW…6ª¶nTÂşó‘”äì â˜\1AèTÁ•èEr¡¬ÈÓ›´ ËñÍ'Ñ‚$~ÕÛÌö°Æ,bqÜ_j^XX£ö”³aŒĞÉ.g×·…Çn§ĞÖ/¢9ùÊRÆ_**ÙiA·ØõUÀ½.Š5½$ÒrÑŞ¤Ãe­3ì¬ò-åE £§—²Õ®
øi¶`óŸèÒ%p»0[USíÏ¦T
’Œ`¦ÔH05Ô€â >2n…4}·}5œom+§h—uBÚ+^MC*u²U‘ŸçH­^mÏıE>}æµ^‰u×æíŠ’ú“$¸q,p3.«ŠMÀÒæ¢ÊÅ‘G“€ªÍX's~^Ì‰)~bQ÷ØP“è›éV}şV‹eP»WÜÃ^¶ÀÎöß†ä’‚°ZF§sûµÍy÷†u#×Æ¬Ô»SÄ…z¸ï$T£(;œ€²ÊæëÜSŒ:µ¿ıÎx:p0ü’~ÄØt(áz¦gY“‚ozmY 0ì²û$m\ÃG`º‡W–ã·+ÊğJ+Ecí¡d1£°f·‰&¯Ùö", @<–k
×8Ñ¡!ÆI ãŒ2êAvâ1RR‹z´êŠ°êÛàõ…<Å‰|D@ï€õÓ·Ôd"«jZ+ş,Î:nÅ&†4Fáš5ÒÉáA"‹ÃK[^­êKı•IÕdV8ã-‡4]æ2N-¦ã†9ÃâW´È¬•Íßtà$s©àÃ"¦{ñgÉ–mã¯w¢å´ÔØ=)YŸ¸R6‰0Ä›aãã5†Jõî¼IjaÕ]yg»BÂ¥À©-áJ05õÓ&ó»çY5®(Ú½@{Syöú†e¤İXÇ°j^Àˆàİè·Ûƒº¼]T ÃÊV{Ô©
†p2»…œ×Ó™¶I'”‚	u¯_cr “ÄtØvrêÀVÃ~íLåÓ¿úOêgƒ;†–»ï¬2óŞ'¥…É@ºÊ¢ÄøU©$ÑÅ¶Ù¿³šT[ÃÄ^P­=_¨âBQä5zÄƒwÎY›ˆ‚úH+ÖïF?óº$ŸmôBşg·rÂI.N/4c@Ê¾†60dIÀ:‡>ÌEuÚsøQ™iXÂEóÏy2Ùê4~¢i®bÆô 6ĞQ²u²±éÀÊc³<e$ ¦õùšÿqŒ.‹ioŞ~P¶×%OLÕk{®l/»ó×^IüCH25ã8ş¿ÆÙà	ûaâu<6G#V -Ğ¦RSÑMÍÛµUUÿ¹§=†^Æ`†zï¾ÊŒ³†F-fğé·¦ç–qt¸İÿ×8Å½£…˜¯Ñ[Ê›±Ï#F3P4R»!3ş%•0¢ğ7)X³§ëp Òè³:A’cdë†ıópò¡z2‹SöFbUÖ1Ø„Ú:Ó Ç‚ßçv »ºlVç‰ƒräÿûå ×<SÇz}Ñk$‚CYHÀtV÷rlÄ˜Ô6Ñ4”òñâ}}EÈ5pCŒAÒˆìì	—M—$°#€Ñ‰…ŒÂ±ƒæ…aw¬fnµİQƒıòtmd‚Üoçµ”ñ“ãE"8ÈhjWj*$KÁëq¯töÆóoŸ‹#©¢|•:ºÚÿ‚©nIkR]ÃÇ¸ÆlÌƒ<ıÍÿ—Ï<3&~şè˜_j<²¥©ôa<Çª¦j²èÎÁ×—d]‚o~h%pøü±9î9ùÖ
›İhdšêQØ¶ƒ¶³ìBHœ3|Ú!B¤$’•kºv¢jÀêéú÷¢bÅÃ£Ë\§G*Î?õHq¿6_e» ¢ç•¥ Ç¥¢"ÏDğ™ôáÄ¯±-|Ÿ†iopÁ@z¸ñ2X×ŸŸH>@q‚YÈçTèÒ` úµ;ÏEìL`KïàoÊ«ı®ÿQãƒ
ºß£!˜…+;/~IÏ´mSª‹³ët#ÀÉ PÜ,È¡?ùri¨'‹†ûY²ÙŒƒÆ±ş°Gd”ÀB¥~íò5Ç‘ó”ùµÎk¸„µ8Š¹ÖŸ“ •7€Ò6¾
²/–HÛD×o—|N0©uF¼·Ç:
³DZâE¤J2µµû4ä$ÀG6F»ÙÙyÿP9ˆ¸§7Ÿç›Ñdşg;m)?PC_¸!Ç¢x%ªÊ# ’qnÃn,‡'Á³Ø@KÔ—w9D£>ÏÀ68{DÂ^8ãÑ“Ù/†Û‡±p°
ƒvÜ ¿)-…İZ0RËIÕÖÓ,ùä([ÁVD¼ãnsjÙ=´Œãït "Xô ûfdêl6¼Q$e{·˜?1q‚î»°åN}*z6â®Ñ6JK}âO—åÓ Üâ¢èÃ¨Ÿk9+ãÊEñ–˜ôÄô8Åõ¸Ä3œÚöP&İŞt@ÀçLôtyq­7Ñ ~]0ŒÎt}¿9WŸŸ±PÏ”ÌĞfŒÒ¼G+5¸Ù‡:J‚j™û+TZvÜ×>GæqÂU>sôĞÜ?Ùa'Ï'ğR1ki³”“Ìı˜»Í§ì, L2Ú_8!:¢î€‰?€¶Ù]á…ÛqëYb‹/”G-‡{ôJlŒ‡ªñ^hO«mÏÃïÒí;²İÅ!´Èóøñ İ:£¨èÍIÆ/Ø$÷îa¸¸—9®­®+U¢+*®BU'£Ñÿä<ÉóäwE„(y¯3¢;£ãâ_†f‰$–„'ÌÉ÷dÚ:gÚR_yÔüƒš ì
#ÖÉ%DLòâÅÒï`<sÀ¯¹ÎĞ ‘€sBëıf”9 7qTŒÈ|$ÍNXÈCğ“sÕë!àUë¶÷:°‹ƒıìW˜®‚§;{+ò0ÑÁò)	b#Ñ±Ç½méìâ·ñl?‚bu”=à¸]¯¦åŸ·{®:-;×e¶»q©™úa¿œƒ1"·¦Ô^ÁÉÚ¢ÉëØvRÔ£ñ×vÉ¶e{u@È€Ä·ö DFËên„¡¬tH4é<ü£ıXK¨iJğGùrëaĞ©Ğ¦å÷ËcN‚	?¸½;?o‘®º±Åów”~ì¸oa¢G¨¦,Œ³·Ìé’ı _ÊdM­ÎŠ´#§	ŞƒIH`NĞ©DCò8¿Í?`Ü¼3à‘¤z'GQ•¤2Qò&cS]¿gE0ùŞÈq<^XşµS6ö¥úãÃt,áÅÏ‡»òJŒŞp\»Ğµ/ Ç%ïUæJØ¹øH¬ 2ËFÂ#Í,·œ›­-ëp9çóaZ6\£z@¨H}°Ø+,²Ï"oy¶ùVÜÍsÑ&õ^YãXê^ÕæúËÌgôKãûË©V~öO6Ç•G ø-ï£9á“;˜1üƒ§Ã2Õ˜iLÉ÷TOùlP¯¼¯=Ğo-ŞÍ?ã^“|¯Ùá¦?<s„ƒˆGNC2cë­U@’è4„bŸ$1Å-ÒşŞ“ÿJ
­÷6pÎJ‚9°n¼Àæ2Ú!¥³ÿ#økôaG(ç%'Î`y’£ûÍĞ•ÍãuICÒ‰'¶ô­#NñÃË.fo`4‹ Ş¿A<! ø¾ºàá3ÿtE•€–&Íğ~hÁ ÈmoÏ<Ûª„u¡!cTú­ ëc`—Ê§jˆI¨àÃ/ÊÔt„$3½İ˜„‚÷\¹#Ğ`´Sqá—4mãÖ„J=³nÜ/h×êàpÁ Ãšzi?ÏY· Ú;ÙßñQrİ…›ÙúFá“ØFêğÁó{q+¿2«Ô+‘17¥†3”mod®k)Ò«½®0ÅÚ_ùÇWKFÆSÑ£N‹ñ±®Nìø˜"Boµ«Ävö+äšåë„»†²Š¤PÌRÙ©t?æV~rƒÁ9»ÄIÙéA I]_€Hè	2²9~¥ç2g|§vD+ÿwc‰t@I;I#ÀEôqÚúŞÌŸÙ,ìó±Ä"]œ¾Ü·óg´†ù ÿP-Tš9²ƒ^ÔÅbÄ¸\Ğ¸·<9Uq÷ª	Â—Ã	„ü1¶ëà{	M¬Â L7£ø~ô(1·Ì‹h*.A¥ó­¹net3wí>ìòëj! c«c(’bC¾¤êıïfáp~€-ª!ò7£ÂÓûÖb$Åá†ÑÑ2IÃ½l;Sû'0ÄïW	—§"\Ÿ«ØpD¹÷Ştä-˜¦à‹›EêŞîºmwMŠ
#Ä7·fOH™«Ü5m'Pg¬¢•¬=}Zc‹±Z¥^¡›ù½›6ĞKõ[¶05İ¦Øøêá0&¯Í0æ8½¢ñ<´(‰r_^ Û À\Æ°kùØÒKµpEœ˜@û^[èĞFjB¹½ ìÙW(ÓD„ôì4üFYkXMPbGìÓ³Ts×ş»'İ²'¥úçŞ¾£€òZ©íJ½-ï¶"dxñ"Îÿú$DÆ™"3ş¶R³$>aŞd¶ØÒãL¹g>J]mm%Z™FH/®KÉªgjh¥©ƒã2
;no|n~¹ıíí„­6ßË®×.l õèsÚä4QâĞú>çÕ­dÅT|FÉqZÿH¿ uİO¸'ıc†ß}_?©EgœÛ:_ĞÔ:îÓBÉDAvîz¡Ak]º¨…"XeÉ2`åÍäÅØ¢\?X2J=ùfª[¹ßk³W_fÁ—ÒÜJ×k¶é¼ÜU‚kì"5Psğ`Ô6u8İëĞaõJ{wú/,{²R£%åf*ÏAù‰p9çhfdÇH¶*5ïŒÜ©Ããª<³‘”=¿	/tı*À›#ùwËHöşmâ^,V#q¢AÛ¯/`¤3¡®ÚVKßÛ…§WT7J‰Íb^¯dyˆÈ|‰«Ç÷AòÇk`OøògS®ƒ©‚Qk÷Øò®n,@ÉB ·ë|0èdEC·A4²AÀà
Äºü	Y	ò5m¨r]Jà4ƒ†éÀÜ.îÊĞµŠCèw:…Í1ˆåúZr ó§&ˆÙ)Cõ:¨*,ydT\i+Û(Ãf9µÑœQ\;ØŞ>´/‰§ñŞ»z1²2üf‚ Mˆ4™)ËşE¿ji'G¨p·€‰u›Hü'Gñıª³IùŒ;\¤Ë>d†PM¨	¯ø’~£L{¼^ÍA#!Ã_`Ys[$”Mu;øE y)ó½|Á?Î|¯ÍJ­‡nGŞ”Àê	›Iâé 2Ew,R~j† qËüI«îÇşU”–÷ŒP¢u‰¤“‡8ZOÉŒùÁkQğ==8k¡#}tZ»úñü¼w6Îîi˜fğ8#üÆ€GÚ&/]ÄE)§ÅcV€$bÑgë(Ÿ|ü3Ô|ü—8µÃ8	7ÎÅj<“0»9V-òb­°êhlMÁ‰Q¼âÍKãª·QöŠé<Á	İtÛ?v*R±¹hœè~›$BîCPäSkğ^`?ùC—$Ì†_®º&éZaO;ìÌCm\‹«ñ“*Ÿ8À&Q7,¹¹nğpp6ö·¦Œy³ö½7ˆwsîïÀ1sİ+¢†ï†4ü÷”9µlb¿=ŠÖºó2o:4
ÕÅ*—`ÿPš+ƒ4µgYÉ4æâççÓr·z{RFßOhŞ@·ø²,\†¬¸Ò¶Q¥éàÜf¤.	ÿÏ%|šØìOç˜ïßEÿı‡³§"¥…ÓI>5¬àÌÖsÂC‘ğÉâ~ç´^“… 5²¥OóßAmr°5Æs^ñ”N'_»H‡«6åçT—¹´®Õö&îüáÆRªşoBÉÄ°c$ˆWŸrp†ÉZ§94cÜõé½Q,‡„03&ÚQûëSí‡z«œX&nv¶FŞ£—öÕtÑâó“½2ë¥I¾À—¸e„]RÎ?°ñÕÍ©YIA&.‹VÀöæ/¶Ç2¬Fq&	›-kRO‹$¥1vC5›Y½!±VEfÂ+a`ÑRƒ3m€å‰ÄèÊGBù…<<üşÔn.ÿ+ÑÆÈäsU)©õPõ™V’¿VcgWõ¡¤Ø¤„YdR8‘˜Doy¸8ŞV°4ê{;ê/bÑ²E–Mô<_Ïƒåœj¸ Fç½éiòKŞ!šş,¯)·ûXßo]n
D<Rn€%,ˆŠõĞ+± _“XÜ»Šè9¯’q‰s÷qt´0ñZzRFöI8àIR«“Mkğ•›6¼E#Ö—H^„OE<´ühÇWz„òŸæ†s8|w›y SaJUÚÀË1«¶Wjo/dsƒ³™L±¯ò/ıMYºHLë>1Z#öá+#ƒ Ö-Eé¼`švøBaP-
Åjm€&éP“¤:.½@~·¾ğËAş)û_]
œôÎøØø£ã3kÿ{+©ŠY|²"ò$?ŞßŸÅÎ<|¯ZHâ©ıñvda £¥V{[)b¡Íå32…r`°ù"ÈK–O<V»ÚC¬X¸—špò‘[#ÚÚÇï <íç‚B›˜_Ê#psde£=ä/Ù‘¹ëÒ*š¸|ˆ!mÄğ ëÀ™-	±ˆ(ı—82ÏsŞ˜·°Bıªâ¢oaj’§¬6@? iÂrã¢-”á 5…r—ù31ÿÇw‰äÌ¾¯gÀÌ½ŠKÍÓ/rmãi%Å^ tçf°¾x™%c€Á_T¦/ --îlª˜ê†Ç{±Dp³üĞÈÁkx6ÖãäVm–Ò½´®Fl¶ÜeÙ‘Æ#æß¸l$Ï_êÌ·‘ò­”:¤yqÎYÌ.}‹ÕC…mH´È*tCJ.È*_-CV•D´*+Eú”ªr–{º4;‚éZF^ĞqH„qs/ŸœNÃœmIà°¢Q|ºş¿m/
ŞØZán&oØÃYMD“šıE½½»z„Æ*ˆxÄü£(ØŸçã¦kÊyÆqÚò…¦lè©Õ›×‚W„gÙeÏï¾fN0Ì|ß(eµ;*21Z½tDšÇËëyÖù7”h ®9®0êÈÓêÂÕŸ’t_†ÒEÕkMuË>«×>‚ëJq!¾^‹¹!¥áAê!úêüßZ.|:Š9A¨S~œûã€˜4ô²[±²­ Äs"g]G'¾µåğÁ¨“\¢o(iå$oWRš‰êNbÌıZ½¹“1P‘}â0Gµecá1Ã¾HNÚ‚Ö<ñ»]ÙóD”ª3®d¥ aÖ“ÊwY|8)LèäYhËKˆx²}¿6øñ}_Æ\çKŞĞıFJ¹‘ÅQ&7	ÿÉR¢NœëV8hòSn|^ª¾àÙ)€¬XæŠUPˆ^t®tE;q/¼ã[Äz*ÎÔº‹¡>
Ÿ1öMšjš´‚Çw¸ĞJeo3Ë±ƒ¿:¯mú„†Jq„½ÚÄ»	#ÉlRŒ!û·Àx:!Œ¥™Y³ôNSŸsïÎ¸,Ï‚2Öµw›ÖDC¼ÿMdß7•|IòŞØ}p¿JeønqUrÅÚèsl¸*z^Æ–‚Ê"ËL§üÄj'!ÕÊŠDïû–ág€'¡$]OVµXVågÖğµ&wlé£ÀH¥YàÌƒtécş#9@wZ²¤”Æf|ÏÆq]ËóÃ)LËæßMÖK‡Z2«¤†£8x-Óñ	à*¼x“*tI‚·èlõrdşN&ÄScj¥İ7İ˜Oåáô{<]V'ºpğtĞkb„XÓvˆà™áçj‹€ós/V•vè7º¶¶¾µyÒF1¯]‚%#¹¦6Mù‰_¢Oò!?îd-¼Ù¬ätÙ{5#*6K÷ØÓ_.ˆ®å°Şoô`××é‡ğr¹2Èe9‹#Iç	~)v1ú
é+X·
Öğ)ûµÆZ`.=ur'Ûi†™m.RŠ¤Î½î&Æü<ÇuæÌRƒYv >?`"“Ç¾U b'Ş˜ä=KYn8Î¶<¿u)-!ô~oİŠE²0GÉÒ9·ÄQU•9>Œs÷ƒ4ü|!9Äd”²,,oÄ‡~pû^\RÉv&ô¢#8;—ò{F,üB(39½\nÏìÊô™ieØ‡ÂŞ?ÛX”ò,òN¨|º.¹Ü,ÛQ2Ÿ_´ƒÈÊ^Ã}%¦š¾\´H´¨8%*˜LEĞVÎÊµ/¬¦1,F,LcÌf6€°©»iÅÍ÷Ãô^óÖw•á!‘í“‚øIöµéÙ!(' êfèNx2_4ÆDÑÊ-ÁŒSÛ*Ñ1q)6B¡w½«û	ìëŠ Cµ­ÑrêÊõP=›ÁK’}¶µ¾-¡(Mín¹§ë;Î¶ÎB§ BˆĞäí2¤Í2ì°—‹t8œ6¨ïª{{
M¸İI%3|ğãÔÛ~í˜¥7hü<Æ3—NzP‚0°xÜ‹J	İvLWD*]^<(q«t…=ÀÀ1=·F|EGÇçûr5‹˜ºøO¦¿¹´>ÇYféù]ğñêoÈ’¸&uC¡duÇMXsÅï¸dÇ”åPŒ7‡wÀìæèGÇè¿)#«6Ş†c/¦¯y\¤d­¡Ô¼'hblÙ^2à4ò´xô*÷Œ…1°[Ñ@¿¦—ôÂtçT£{Ñ4h3«9Ş‚©E:è¦wHÑş˜9Ğ*!‡&;•êıìİ?r{¦oÑ[ìÁ˜üW84“ÿ¢Cê)³Rú~nï";á­İëÉ†=pJŠÒûÆ`27­qwÊ`Æ\€lÌ+ŠÈº9‰-,îõôùöhÄ4g$Ì"ÔÑºe DêÙ¿*ùşØ×gD'ı`Î^šÿÕÊÚïí¢ÙcMó„B)g„¼ërñ`ıíúFÙù­B¸KÜ¤ã4Ÿúr¶½0>ÍÑù#6~ îÙì1È8ù@æËjÀ®Í,ÙÒ–¹eSNk¼^ØÇL!?¹M/G=««\=xñr´ôû†øüT§A4’#&fæEfšâOødãÆêjM¯`3ÉšÙlŒ˜Ä÷	òÚi¾EÊ–Æ¡ZTkø9jÊ†ƒôT„7ØU{RJs“n6±¨İ{‰”UĞÊËf˜±}çÛ!‰Ti~(ë½±Îª¸FV*é
ó·ıïÍjÁ õ‰ær>:İ¯Û[ÉLöböUÿV¨4”J®ÅºKeWÑ¸’•TÀBe*2tÉQJ¥°øxİòÌÜ†EÌ­'FŸA¹›}¾™Ç Í,ÕªÍå®¼
ñ²;(5¨u‹P%ñêºƒÔBÅZ©)¡õh[­¶á&MôrÃ[÷•G²ÖÃâ` Éd°à¢ÅÂÑFïÅ£î%™®0\ßq“Ÿ-‡¥œGÜàè¸ß[œÇÃÂääââ&SğíÜÒìIYî¥‚Õóš^ú2dhÇ	¡Îd7béZ:¢n(ñHÁ¯º0³EÑv ÒÀµÖ`àL)MEõ2#u‚@÷‹F0	OH„]¿¥ÊÍr[‘™²wtM67–}•á]køFnîWˆÓ„„Hß^—Y/× “>Ì¶±–£~@>ëªPZoµş‡šğ~Ö“À2ÅÛóºñdbZÃ«qÔ#ùY²¥–Øı¬„iÁOõdm˜G·›w0pux‰"õÍÑ'íD—õŞÍÀø-¦Ğ$¡ı“Xui;ê< iú‰‚4„"SÕiéo³Ìâ0gÆ˜“3_ä:"ûµK_áa
Ê¥^¹»4wa°1E»Ò$¿‹'ÔÅèO†”}‘¦¸|¿yßØi<ÆÌ<Ü{#*xŞ7Ï!\‘®V¤“í./Câo:÷QÂM$¾Ö+³¸xº_åé2#¨fh#—*ôKï'¤ú|ˆH³ÁÅ±âó1ÇBLí\bÉ?ÉisĞ”µğ´ôÆsë™ŒùÌBMÄ<4ùI·‘éÛf†í¸‚ ½t	7rçÉƒ·<|kğÿÙ¾ô½«&¦ß G´¬Õ©DÁZša×w\éE"{_„÷ı8~4ŒK|e,AàÅ5w¥¾ÅÚBšË´²<«–‰[Œñı7ÄË=èÚ% -m¬¨1•(‚»+˜ı±±]£8÷æ¿‹‡?æ­Økáv”âÜ›çÃ¹ÖùÜÓÆ2]„rHliÆEÁ9kªšš“¸ƒˆ,™pØ„=çı>Ì'°Ñ»ç‡?€ş`¬è‚1¾¿OÊ/?5¹—üı£ìİzc0hörÄ{£*‚Øæ5İÔˆQñ¦ÿøğÀÄnlQlZ„Î1‡U*|¿„Ñòq„	¤t©¿«…ó™&……ñj3åqjˆLŒ,A8‚?Y¢·‘=4\³•‰Î´/7Ş¤YĞš#qVºÊ…>ã}K-Ú/DÖ\-Qı?î¾4Ñ­RYW¦â‚Ft+üñİ*©Oà®õ«[´…[š°	ˆÿ­‘{&êî Zåõ–ÓAòtVrb hETMZ´t& G²~ªCà‚xz<tJÿ[áà©øf_¡ç.³¨Ö´PÜxŒâ“õë—3YùÑ1]<a•›¥Iá¯fœÇõ5:ã7¦2€ŸÆzæ¿w½ wÈåµ	mãÂsócÓìJÍüÃº#æ…ú\p‡6	!üzS;^ WI—Â”·½”×,ë?Z ‰ş-LıÌ“ï‘NE^9d2^Wctvè¦Mow]‰ïçÕ|Ÿê©ğf;¹§$·— a%ÿüÓ÷ì`Q†»¨µz-;‹~xFY®7]¸ö„å&_®Oïí<hU€8±Êqö§–â±]àm©Pa«m³–b2t%ıãùéL””Æ~Äti
³ŸÃ~vM(ğL”ãÒƒÍdê¦\Ywe;ì”!¢ŸÜ¾?Î’û)—ŠÔk5¤0±ªLÂş¸|ÊŒ3ªÌƒÑ¦|7ıŠ¬Æ'A)xïê.¢¶;ñÔzB	ìÁöÎ «ªÁóÏ¹zT¡éÏ²¿nˆ(s‹l‡Õu £;Xû¨<9b+¬.öóµå&[_BYå¸ãá¼Ê\¬ª§Züâ/LEêJEøxy: ¬ÚïFì‰¤+@Õ‰`
=3ºuşÚÆ·0MMD&I<©pöWWk Å¥¼¢ô#w÷Ô°ÈgğnÈúÔŠlìUjóº'‹¼éy"_cYô•µGqÛŸNJÌC»<“Ò¦'©H¾Û¨^ŞW…Cgò_âL÷…—Ş%ûE´¥—sÉíyÌ¤ø6"äP8â™dì—aôPÔĞ·!‹½•¶ÏÒÊp4ïå,DJÿà*.òl¢s2OÛîyFºëG/ß¡™ÂÇ!Ì¹2XfëQ_f#@j¹I´mİ´®JáxqÕ®¤†3<¡Ş#“æRåLÁQ¡Îç**1ÎvÈÛ,5DæìI…Cş¹¦­f÷_iÃhÏ UõdµBm§xvkf†²ÄFüÉD ÔæQH<¯tüò‘|p„hD€®æÈÖŠneAòÑjx5pE¹C…t¥Ò¥`yoùÁ]¹?ÁK_	HïlXã;¸óî/£òa­Âøß¸)‘€BÓÂ3šalOÁX§9‹$xÆ,˜fåÛâóÇRõì<½ù¨¹¨pm¿…ûµ3õ}ÙñpÎÈ©º8'ÈI£Ÿë$1­ryûw<xgÅy¢q`ÏáĞ½…ÿŒïÔ?pĞmÈ›,°`Ó†,fÙ²Ô&v3Òın|	ŒCw¯,ğ%7w,/Ìâo½¹m!24d0a¸(Í ßW‘&°Myö²SËˆÿBµ­$A„!g©4z`¦ ø-2ŒBph°Y–y]ı]‚ÖŞSY@øw$I Ü@pm,íÚÂ[‘åè ÖtL³d@w ±
Ëñ˜EJ´—°"SËÄ¿|õm+F‚¦Ù£¸9¶w›Y7í<ùF¦\- à úÄÃè’\_nã«rkâ_®.@¢~>šDî¨HğĞ&RQûM]‹~~éñó÷^IiW
s ©²¯Äµ·;É)—ÂTp?×’tÀ’Z“z…ŸÁB¤«£§Kn ÌåÒ†Ÿî—×[)¶ïäiŒ÷–—	CZš.,8¿Şg'ÅqhäZ7äA)g&Çó‰5G ææv†YU_ ûk¦]H¦ ¿ü% D‡ªg„„u§+Jîˆ\TÀ+úr/z…S"‡ üÕ›R.§ï¯¡W—Z	€%¯_¼Ù¸`}A×•À+DÍ,{ë‚üŞÅOiŒ¶]ŒÄê{úˆ´u¨ÿ$P8×Q¦€®:(]–s§#sØqEk¶	f?²=ñ–HÌØHÈAˆúÜÈ–îÍÇêz*‹tßHÛ×”÷İ'o'<¬È.¯àUÿJg3P×ä Ü6Áõ\–u-`Í‰A{	`K¢¨ŸóMô¬÷¸ô{x86m·Äw8±€dØıÜàS&ÚVÃØ- /;ıˆ‡™y«¸ 6;˜ş ];ÿ'ufhJº¿cÛuûvÿí
G¡¨æÿEûUíÿºãÓKù9"€rça#BÏ´•–Ñ‘'ÆUôcP<-77Ò‘RO‚)|YÜmŠÚ]Á®h$òıĞ‹‹ÙËÈ|Xâ¨Ï¥ÂzUÛƒè†–l[qî$sH Í¿¬]ü¬8ÿ€xÜÚThOAš>'êèWö$Ò0*rÚæÒ•¨ÚÈº7/@Ìİî\1\êı¤NÄDØ{2¦²µ	şfï9]	ƒO»È´o¯¼!Å¥¾
ÖxŒĞF½—ÏılÀ;ÖáélcµÀrA(qawX·Ì‹› TËÓZ¯Ïø#Ÿ*_u¾€%-a1E^£¨6B1eáÇ¼¡óêMWr+c¤16 °@[Õ:Ø_ıäF…¹È ñÂfs”ÁÄhd6‰±û»rFjJ”ÕüóÊ—f®¥ê¾õ€Ëz²(ô6®#‘&;fËCösÑUòœ,ü<öhMöû¶ıêY²WJ­?k;^nSÕ2»¥ç?×üÎ`sid¹>…Ì6vI³sú¥=ÔŸïÆ§ƒNÃfË…ëÂUÎ<(\Ëu‚ÃõÏ—sñßEç¿–E†špğÆôoñãpìœ¼R§·L!”‚‚,‰Éfm¢CÕKe&îşõnbV7Cğé•´hÅ‹2¶äœMo;t¸%¡drp'ĞCy)‘Ô?\ZrS5·óÎ0ŸvšgÓS
\<…–ÎxÃâš×Û¾q¦n“œbb´¬ô§-îl'Ÿ•ïof[ny³^›€¯İ}6’ü¢*¢©–Í¦‡ƒõ‚)íxË@í§€¾ñ¡é—ú1é‰ë÷ÛQ4U_‡j˜Ëç*iùè±U#$(#”u~D7@×¸XmƒøNT@tŸf¢ı„üÌªxL@) â)Ş8wÖÿK Û¯¡2
æ·&#øc!+>¸š[ÁÃtòÑ3æ–Æ¾fğ1«Ü	´^K2İ`DM€aÅrã÷`¶Ë½¢7mö2µöƒüË‘`‘ÛÀ6†‹.7[ ã—(RÙ–ñëçl–êºm•¦Ü N{3[œ)»)„Ê›®ÌHšGHÖ[¥x=Í[R«©æX&²l¨eøIøÉÖÿÓƒ²'Ó«Xª)ì ù¾úÖ-êA.à; |x¥¡:¸º’Vè±ĞúU<™V]¨i%N~â¦‘‚èmæ»gÃ$àÍnıbPÖ?;˜¦94"Ùq8Õ}ŠÌæq§œl!„Ñÿj´•vµM$€.•†ôo0OŒ›¾ç)@RÌMÌeßkc“$(½ú¸3~‚5ÉºËÛ©ø­{çÃ&w}Ùñ+0d}{Óà2.«z8ş­µ¸¶¡¸
yl7’7¹ŞˆK.ÙZ¯†vK¶XìÖíØwté­Ï‡ÕÔ¦­~s×¤ybê LTX=M7XÇCƒ¸=ñh›mÖ?ƒ³wŞ…£ ˜	°Şı˜òéxöPóùLMà²â¹-ˆqÕyRê‚|êir^î¿şµÜˆã¶o!nâLß%½7/5S8ş¡?d¢®2b/H™ö&Ãä/÷‘)™ó0ÂÅÒÏ&êŸ7¤œğ-Ş—¼_]\Á„ÀbuÄãñ¡æ[‡+(Á“õÂµŒÖ¤Éh 7ÎóU®âlÛ>„C¸À3:•˜Í<IBöC´ˆqÁ¤x´j™6ZÏ5¿Ö©Bı Ñò5œĞ|j”l¸‰N¶y@­0Pj§ÄÖ…se‰f0á¾ÑwÃ]´eïS±¡ğ(§ëÑ›_Ø£ƒÓè-Ü¡é?Î„çZĞ·~”>I–£n“;=–ğü”4ŒU%[ËâøôÕnúøÊèğÎ	 =¼-/
›:“çV\ù„µ
WÛ[Y»öğlõ@ÆrÚØp †\ñ¥T ­ióZjàN9X×ÿ’ºîY=û>DºÜĞÃçµ6EÈŠ¦udÎŞ2zx‘ô2°7‹7xÌK–Ùem—Ïï>ç²[™m¹ç·¬x,6ŒİÀµ[ÑKxædÀ²è@Q#ÊÈ¸':Â.ªÓŒ$m[+àì¼äñ•i<GßÎµö)Ç£€`}0Àº&|;o¯BóT„	È‘fùFõĞ(J¬šˆ‚ÀÉîœnÜ'ØÕ]½èô8Ü#(<¾6
#üìïËpÉ24ßjT[wòù\ğÌFB’æÎí|uÕDUZugUp2 •Íç]$cèWF<›åÖş…IÅØô–=~u*Î£Ü[äAÜõÁi‚tÀe¹!lİm‹3£»”Ñ&£ÉF"ş~oboAº]³™w8í/¢WÅË’N!ĞóRO÷ kV	€;B!˜<H•!Û]dœ¸á‘k
	¨BÚS <Ej•”7‰ÅWvVjÔëCÈªXp”:ÌhğIÿb°c“ÑO³{3A{—Ø²Ü®o}^Aî›evEîãrÕWcx*eÙTì42ø•ÄWésş<´‡ÍNíJîlš–&8À-ËŞôUh ’!ƒ#âdL¥¸ÂÕ
ãšÔ·‰- „r&z§ãZÛjÜŞ]ógœ‘O§tM½Î[:Yú>ZÛ!s2`}¶Ùğx‰—Ï÷¯!É1äGu;¦.B
æmxJDù4ßç+ÿr—0ä£®hkÍ€ßÙè÷Qm?Ğö½H§gªødƒ!LªbRå²iåg·´`;‰gXñ«4˜hw²ÔZyj`‘yïü¡;úkIE’y "hgj²¨37@LTŒZ{[\œq_à†ÿU?mHóÖ^øÜÎ¯¨6Ä/'@À·!Y!€ƒbœ¡—o<t#1Ü¶†M(¸¿gIOtƒÈAºÃ®¹‹ihÁÛÿP¹å’i7´7œ°D¸"I†”óË®5ú ii¶UwÒüµ7Ç( ·A• '<fÈõ‡|Vş4÷,Dÿ—·°S}¬ñÓÕT*£å\G/3Ö\U$@Ø×FÅºßïèÿ­xj~cñİôá•9ˆ¬+8=¦İz³­{‹+6ü+'Ù´¾3DedUÃg*ÓÈ:éÜ)Üšt²!Ê8;*İB¾`X•òY*¡Êÿ(ƒ*I|éIDSÿ.Dš×JNÅÇùy"ep%(ôÑŠıÉÓfV¯1h•Ô®²eá„Û­>Ü4U±áëW´şy)ÀBÑñÑËÒHÚ/qBc§ Ö®ö½ã";XV2êBlgRãúUZßODl BÚ,P&ıŞì;+ÄÓÚ?$?GÁÅNúëø1ç¦_P›³n]Â›½Ro£Ã¾ºÆ7wcåôƒ²yéL/m8ˆñ¦±ÜÕÈ![âYÊú¡3a‹ nzVC{Ÿ&|ò(‘WJğ±‹J¨@Pqs>C‰…Æcøíì—”¸€«(\I!ÿÉuÍ%äbçcHõØmÇé#‘TIÁZ¾ ©¬…ùfeÀûŸCˆ+Oİğ ?—;ÀÊßÚD¡!%Êdç}R¡#Âæ©ÿ¶<«íD¢vU™x(YçW"²;?¤v@w uK™¹j×kFır@ş›ĞœeEªGº5æÌíQß±1©‘¦;H¾Ç{„PoïwjŒ	I„ïc;Û“97xfs\øƒßİjujû¹ab¤MŠÚ'¤øğ‰ÏZ®Kÿó,WÁèxş–ø‰!Ô
‘?€ƒ¥d[âvîO³ˆ>±kViŒFğŞ|¸(–^Œ;…U“~„îX,“ÛÌyËÔ,»Òp•¹gÙH)íf¾/ÒC|š™¨Û
yP(CÎÏ…ƒÊ_¸ã7a›ı¯û+Â¸¦d“¤¥±wË“=|Ÿ1Éª´DH”&&i.%Ç=W‘›ëië˜Ã$~Gü3´™kYœ%¢Dã|,ùmLwƒC²bXlXeÖë©À‚æÛ0İqÁZ'ÙyàÜ“®z|³"ô¯¥Æ©=5dæzîl\ì×£¹à'é´}k$9Gšáœ~?Õ;¯¨£2.çWiñahmÁv!¦ğ¬lµ´+c×gQQÔ>3c¶ô§4¾BÃ]nŞ›©Š_µa	•Ñp º´ğWY¶´ÆW¬šÒúz17Œ{ÅûZv/p¸‡Š²?+æ<€jYë.ÕÓŠjóæ”1°‘dvÅŠ·XSâÈ¦0"¸v>›G?^Ù-íÉ^kaËMáÂäº×fˆ3k®Aá\“ëDîµ\wø H‰GÂjcÎM}x‡»õâÏ”bˆmA_âöå³7»*"§iÒÁÈjƒFĞ4ÛèÜª‘3>•:®„/·k²an¾«şÃ-J„.šgÉWX¬<s)t†è¤Ğ3¡<¯EWßõ :®^œ¦t/şûU9×Š}å7šj2£Th7K;¸ÚäãĞ¬d}†îpâìBÉ' ½t’%Qh]3ÁSëiæH¾¤ë~„r#‹íCCk€ıj`fİt¬Ö¨}õÃ;±H+o{jûıŸ¯l™Ü¼ÊêÏ9?‡ğ.Ï÷FtZ¬jÎ†Y$í%r[`¼w
5FM¼1ø;C=™í…—?¸vdÊÕšÄ{‚_şÿ„~ˆ:ßŸï„Š8@H¾âÈ>˜ô:ç£ÌÙûT½äõprœ†şçº°–Ó^óEf=9ñ}Nà»h[nĞ­İH¨X^ôztMø–¸“‚PÓhıë´E©¼…“¦²‚Öp3ÅK— «3—ÖÕ7ø¦ºcqoå±õGy°?•<›ğ{1ÿ{®¦½Â¿²ÔpÔmmvQÛĞô¶h…p†CøòPÇI9ˆ	àçåñ@ÎD'?3u¿1o§Éõºr>åOÈGà™à„µGß
˜”VÀ:êaa7,´ì CòGÓ*SçÕµîIyL~¦ĞÆÿÉÕ¯ÊUÙä[°R°ıÖ¹?ÔÕPı¹„ŠìZi¿uŒ•L¿üÁPÈısukÒNW2¿©[OĞÌ7¤OŞKgŸä%'=yØ|Aëö-5NBL
a&Jı.3ˆH]s3ÿÍ\AX0+ĞI#>BPWåÏò IX¿Av™›ß•&Y¶ƒÏUä^Û«ò‡9¥Ù±#áÇß¸À9œÃWy‚@¥¦Ö¾pgÃƒ™ºöJ')YüUS|ı ³È¤göáõR·õ³(3¡¿X“X¼fN©¬’µ}ä„$ÓQÏ’©Ss÷#s= "~r»àZ­‘>h(İK¶ u)<<Ç"7Ãó"í‡ê&!²­x¨e½÷Äâ‹ëÍ!qìŞ©Ÿå—é½!6ü4;3¥ÂhÓ³£T#Òİ'50Wß=½İˆ)¥2¹RYÉİóp}‚>é• k§©ï›‰ùN`R]Ğfâ=æïøaSJ>C’*ä[rÄQÂ—R&XèJş
£sikèF3®®ê Ñœmş æ›´Áó Gél/ÇzD†»>XÀŠIOÑW¤°âX~FŞÙg4¯¹½h²ÈExsW,¦q§<ËG#¹f.ƒhi!™—‡¦áóF"™-^xGÒGI	xvúÜ¿¾ÕqŸ”Dz¢èHåp7 VQ=•°`ú	<¬‡‰>àòDÂ˜Yv ™.‘§Dm¶5ôäòNX¦-eMˆ]½„¶Ÿ¢4µ]_GšêoQ›oã$ù/$zlú÷yïöGÎ ¿=ü‘:)ï$‰ˆS¤*ÛI½s’6¨ÃuJ‡áÔr3ıX“æh=µÁ(#BoÏtº45H8]’é²
ş‚O’Ì6P¿ßıÒ¡çTVL*D…ÇáI¯/qÒ$@ğR¤Ebch„’bÑGïEúá]ô&k`ØØ‹ÁˆüÕ¬× |æÍÖğ®{³ó	_zØöVMÁ¿BåéıœÜDEê‰¸qßÙĞ‰oeĞñYPCì€RH‚šÊVVÜÏñ’!.*oBåÂ(i¥b*j@‚0ëî˜Üªú²Z¢õ™„şğZ“jXÖÇÇP²›%Á5rúo·ärx«¡’â–çW€‡ó71]Âò!¥A“=ŠxwÍAèjµĞå_„"ó£°:8;)B³˜,ÿ…çQƒtn+,ÿ¯.úá¿Òœ_œ^÷á&#òèwŞš¢„Trä9pEf€é ªBeõ£™lÙX,CÚ-³í÷n2íØk:Ğ¯EóËff¯Wç{£j¨H¨değWˆjlõg=6>-¡­"Éªa¸-ÓüŸ8µš~·ê37¨•¾[©£ÛdI7@¦wS¼„%ú %Qˆx$qf<ğŒÆLÉàĞ‘s%¹7½[à)+}&ŞŠ[³/Ö’•§>8İTTÛn^äêŠµ¸‰Ô=íÍ™+İ¾¦ñI™”¶*é?j=lŸä—Í7Nr¹5»
Z.Û\º|­ô_}Vİ^Õ)è<GÁÃÛõrs	›FÌµT/›®pŸ0åó¥.PİH‘Ã%VÈ#‡%Üo†­+†ğÊƒRè*NyßWÕW
Çéô
º¨æ”u-µÒü^Ğî‹û~*0î  »ùb(äDĞŒ?ƒVp0Kkî¿U‡ç1˜Dq`Á•y¯Ëp9ÉdinÃ¯#ĞbŞEşèj`—²¥1æµTP›:åšö4‹suÈÛ óUÕ*
AY…É?È±ßü›A-üà‰ÚöØ™M÷ºÍû_áëÈ§×õ<WòËÄá„Èî‰ö ×…u7Öwi ×ñòo‘…n·â%*øX«ÒØ•ãìVW¯æ	²§p)¬Wßî¢Ÿn¯ÒÌêÒÈñÍ[¦|{ÇúŞv™äB‰¡ÖÿxßSr»u+„®L¸øTıå¡_ğl@âç‡É^WÎÑõ¯\Õ×“îYï_—ëŠv¥8æ­c7cIA-Iso@Ãzv·6£¡^Ew–lW¦Rç›©ë‰VEuc$ÌŠï¾ÀE2æ¡`‹ud4 ÿf‘z¢„
8­µT²Şw&ç¬Yì¨ëø°q x ¨ªÚšÃ°šèg.C†æ¢MœBo`Êt—«AÉø,Q}Íõß$4¨8qÃíÒ"ÇaM1n}8Âáš Ù¨¸¨W­ì,‘x
iÚõ?óñ™	‡šŒ	 šŒØFâÔNg-óß´	>+/áK/PEÉ[^Œò™Å&ò9";b^Gı(¸XÎNÛË>a  ª‡[ª…sÕ%ß#F•SÌÔi=gq¼°ÚÎ½pG»!±Mò¿Òlèˆ%åÄ«
&‰ÈZw`UAÓã¯»³½’ÇrX)I·ÉYçëoì^
=$=¶X÷1{H|ï(óV;¾ä^ıF§â53¼Et¶åûÆÓö©º-Û±f?;˜¤¸š•EbX¢ª‘MaØÑ6ëå5ÉÎ»İ÷GxÚ×&y9¨deS|À\/ªäÕ¿)ÈSÀ÷€ıù ™¾¸®J‰Bhàq«ñ}Å»é7^}¨Š?Pf½‘Ò{…Z”	ïÌ–³}«²0†Î 9mšnpJ¹°"'Jk›Ñ>L¡_&3UÖT[^,Nà0	]-§[è°Fê!î$û#84
îµnoÏÌuŒ´¼D÷2D=¶Ñ?![İı8
´¥@ul¬nj#=må(»q2¦‹0"IµË¶5mk F¢bÅK«‰OBAóIl£’\¯îµ°Rßª¿J:$†tFv{mÌElpØÍÑ\uÓÑİA¤Da:v_Ú¥,»DÓ¹Ô3,QÉÊÇ¹ëæ×zcº¾êdû8)«P"à±jˆ„¶¬Û·Æt’w71+û<×½„Êù9Š„WSÒ„Ã¢5¤m†Œ_¬§Ë!÷Ñ@+¡V…(Õ€w0rÛT6²%Âx›#mİÌ££°ìşD =Hä6cÁ;¿u¤ç7 ³ı®Eä'Ò‹ıK‚#îi8kñ“ŞH%BÛ SÅÑ*w…kNEa¨´Ÿ61È8İ6%Šµæî›Õ¸ŒÄ™j6û³+£İ‘Ğ¬BÎBÍ˜èÍ3)%>_Ò"¶ ¬®ŸE97¯/}N¥zâ´]š»É±U«è‘Ó¿—-¤5ÿ÷lR‹‰ÚûÈníóf]4nâìáJhã‚sbû'N„edÚ¹ğ²d¨éúÊÈÅ-ƒŞÅ¢Ø€€Ğ²Ğb»Åkod‘)ÎG‰ĞUIfX’ÖÃŒçê'…•†Ë	´¢À1ø*´ÖoöòÿÎ¥Ş1Çj{·“1h!1kW|ìN^„‡¤R«å,”Ñóîµ;òâvÒC¯{cıÀ%J™scş5oRVwˆ9’bšs½­ óó,‹âñÖåeÒZÜ73gŞE	|â‘U€‹øtòw+øL>ëHÒ¤[C'‚D+O$ çÁW“1ÒÒ” Yèl)JàÜï‘%i¶<OİŸJ@[|uúïU¦¬û° ñ/µ]ö¸B©<äfxg º²WDLW×<—1õ„Ün	¤mœÜ“ïAø§C 2#¨/¨rYböŒÖî%írt["›w‰.xçD\ËXc(Ê*Lş¦ò³ õNñ__m€¢ ši§GC:dÙšÊÌöd0£g¡ö?8Ş_wïŞ4âmÃéıv¯SĞ*âL×<m‚V©eZzÚò›ş—åLúLóğ9\=òèØÀ‰
ÉçS|4:úŸŸˆå:`ĞĞÃª×-dì¬ñ<+ê±Qãr¦<ïöø4Â1ñxy<
i
Æî£Ué©ÓH©Ì¹ı¡#´¹¥¯¹Æ À¢B‹ã:eÛ^z¤â³š?Ê<± á|Ïõ7Ãf¨=vÄ	ñƒrû¢//P£ÄÊ­æN+”ö¤y%A 3çp]ÈP8yãŒLWb åÄ PÔe‚6ÃwÒAö6ëa5Ì\‚Ø2ĞüÀdÉ¼Qf!t…à—6ßÈPDØ¢»‚`n!4¢#úùÃI0Óø˜ÆŠığ·åeMÌ Ì±ÈVb£™lçH%ğùlç8G…ŠÁ¬_õì’ë“ µH”¦ˆ3c"lâó[Ç¢!h~HÆ•mfx·`tÇ8ÎÊ·ş†fªO‰†€Ò¨}ßC¤‚Wq=R§|z»éY'í?LúœœLô]`¼€ıŞŸ‘&nÛQÎÍß@MPñe›¾ÑBjßHÏ[.F(ú;]ò8ã}ÉíèÈ‘ò{Pı|aŒóñFºsó‘“)'·0&Üæ½Û<Ş_—:4ÍF‚J¥Šš¤`‘5_YaC ·Úø³‚eİ0Öi‡Nk4œyW¢*x0¬èdµ1†DuHÄ»ß!…ÙÇ*
¢3ŠU(dŸˆgŞ1‘iè;Ej®¼+•*ù“ñßgÚÆX§ó¯ä'º«ôOÏiCÙ-é‡›¦Ÿxœn¹#&­î	H‰Â¹Có¿kÛ±g­aèUàg¶È²)Å¡Då(àQ|1T7Ï-ÍÎu8ó°J˜Åqösmê{„ í4,»¸jZc‰îûüàÜ*	h”8ô",š}ÖóA·ÔPQAy*Õÿ½ªæ~¥§p-ç_Ú€øOÆ•^eÏ'±’¨¬r¿÷
 Í~ù{{w>\¿ö<œ8ÍZ2³â¹¾²Õ‚T $§ÓD(iJLcÙ]ä¶10ê#åéUÒ¸¤AÄÄ¿ê°QRËôú‹ 
-úÆƒN&U¢“IÒúÇ“K!İ+Yï ¡İNQ#\6Šmñè>¯é&LÒkl}|úBš™nFbí	j?ê¥åèá€" M¯Ş¤È’".yøÌâ¾@L£ğ ß’ÉÎÚü?¬õÜè»?_|ßYŠÂp’9Ê3+k)³éßã•AàbÂï0ãè;$?öqË¬Ç!0Ü¸ÌÑç];W80q¤—âLP­™‰fqç
{Æ{(#?‹şh8¢è \"=J-Éô÷Öİ  N„îˆf»´ëÿÒ~ÿÎÕLø‡dz2c?¨ªÇ“ŸµÑÈQ/­èhØÛêŸkØ{h£dòNÚW·TÊW²H=?å9ob•n£ğñÃòë€¹f‘ºí0ĞæÜ„ SqNÓƒht¯CËˆæû:óã€ÁbC»zé¹½À¬O—ÿ˜»ê(E«ğ7îjŸÖ_ùòí½f…FjÜ-S$‡w¸n¸lŠŒ!Ö•5¢Š?’;ˆÄQ>†ø ÖW§l	25!`‹ÎxqGá1­ê#…¤7ê	ÿ"×²yØx_BA)œb¸¤Gkâ§ éx2ñBÇŞ•¿Ş4-/É¯ŸzU*îëp²&ìÑ`+¼|ÁıköÒh¯¸¡ï€¸ã•}›ÅZ,jÓû_¾KB³Ùuı©(¹œµ«%
©nES2I&=<‚Ç‡”İ|9¢r­9À“AÁ|ÿC,w è´ÂhHÏç—ãåù;€¦¡äª#îC¦yÔ›i“ú–‹Uú›4X5­.ÆƒĞ¯õB¯ù‘(ı€¯Â±‚TiÔG²bßj’iaC&*>>˜w}¥œT<†øn\hyU˜µÍhŠÖ•´u¾	©åJß¥ETq±ß
.Qä@š=òA¿CÀÄúXùJÔõ[„´!ğÊÃf{ˆé‰»}ÅN–ì(—ş92wÁ­®o56ÍÎ¶^0’d`/AëÊÍI€%ƒ?äœ.GğÚŞ1û·oîæ³¡å¤(dÆM¤ÙÏâÉ¾¸¥˜)Z×Øêe¯àe Ü¬¾[²•(`•$¡#L²Ê©ÆãH<>‡½C—J	üÜ)şi¨†£E4Áğ»M7ÑaÍïKÃãŒS”e”xµ£-8N¢Šæ¾%‡\Ï¡ç]Ò÷úÉÆ†]?¼½º– Å$kÓO†{Å×+Ê€3ø¦âªÛÚ6ñƒ¾s`x—áNp0¶š Cq’X!’°=òÁ`†qÁï#wÈãÂé”ûóıÏ©Q-Œ0…"óøvóóŠÁ/¥»àÆ˜ÔŸıiS!sm7%§™qıO®±kY
%(lRÌ1I&ÉíÜe"ª.(rxõ‘*"e"ÚÒ¥ªzÆ2#›ôÀ$/İí”Êš5ÑÚÇpÕRzãŠü¸D¼ş%<¬ÅH)ê¦¾¶’¡²Pè¤Ù"Z½İz>ÂZƒÆå=„Aj2†ÉFåJ`“_6ş
€]$„<Ô4øÃÓãÎñşøú¾êxû%~7ÊDaœ®+5Ö/¼;ğms•B Óã«>ÚÎM«k´Fq—ÈÚ"ß&ê%äó
Œ¨¼Dİ| “JiÅë˜!õ|'mtâWÆÑ«ÎİÌ‘¡‚@ƒ„B‹€•Gİ	‘íŠ1LR¼în4£êÀL¦K€-ë[my‚^Hl>¯^g(•‘£ò~MÌãZnÓü‚Ã¼"ñ; tH aŞ Û7]‰äv2Û$d;“ fF]ÆÜJ:cäœÓKpW=PÚ¥ğ¥ÊŸxğë@Gk2Ëi£Ü+ú÷B¿‘F9áì›!8“¥x†Èá©ß ö`Õ¡Ù7‰¡kĞC;ƒ«ÃF‹Cñ÷Ÿ²hL 79ÌÀmêÏZHÉqwøÁ‡àŞª<”Øö³[G3vlk´ŒëOòº²Šc®d¢ü­³²d¥°ÇvIÀÑ,Œ[ƒ)ì_"êkwxêÈ*E&±‡?’ŒŞğ—¾¨âèÆÈÌQ„wa@RíHÿã)z$´D½`†ÓyyÔø˜y‹>¿ôWsw¾?0¸zoå†ëú’f+À²Ï=šššA§°‹ ËHûi`¬¨‘$Ïó®T…2‘ÿVóãĞä*2ÉÒÙøıxÕ¶_äaÚv–¯¬£şÙé±ÔM‚Àb½@øaîz1ryèO·«t¸?›±@3àWòS]AÅkû’QrË¿³¢`u@cn!Öñ6D–ŸõÕ¯¼_¹.Zâ«½–‘y$|+M+ÈË I4ío<•âërÃWq.â¶ÍùèÀÎæŸsZÕêê	^!B~µ¾Å4jñ®<ù_3KÔÏË[ƒ÷2¥ø@ÂÔ¢ê»î<¯ïã™wh {“¨Ø¤=àĞ.ĞŠj|¦–G°\+²ëéO&™…Oö}£ô·;[1÷‘¯%vÎùnkBw¬_*““T ¤ªÅñójomá7fág,ÛÖ=QPmÜb°è.İƒŒó¨ ã©‹jñ€³éË(nO§|Ş ;’%J•ıÆ´ÀÅT•ÿuøAµ»[œ*hÓz'$_GÙ¥,ğş º’A²¤¿BC·\pŞy{¨Ÿıîœˆá	·èøƒÖôÆ†|üç0ÚÄËjVT2šô¼QÃNÄ¿Z4Ìªä¥Ìçß¤9ª…|•whÕ•H”ò/ÔzË7Ô­½T/óšQ˜¿ò‡Ö[½Ñ-ÂDÀÍ4„_óWù
iªÈnÓ8:À;½'C„ISÜî5­”×›µ78 í/é	A1ñ¡!XÓ^#È §|õêÛHVI#=É1´Jo+İ
µÄF[AŒŸ]|Şâ³ë›Ÿrn˜˜æwÿ!Úçøzî²kA2'–::EÇİKFO¿+ÓÑûY1—®Í¡Ìš%rd-ÇèÉ¦+EÉœ?ƒÆtŸëŒ€ä¾Û¬ÁwP4+%ªDq¦÷0í¡
,x!s%vÈÃt°A)ÓÅö"/ç4“—ëúÇ˜åXL®[Ø$@séÍ0iî±:§C¸ŠåuÁÎèˆü·Š³Å$[µb’>‚ÁIèºÚÒ¥ÛPsSZap«a¬zsÁ7ªZTè`Hª~75wİ¡Yu!o™á>|]3o&ƒ¬)U¡éàá–}”áHyBüÈ!xN9»µ‚rA(”™è÷ÓÅ®½ v!±1Ì"b‘øËÔÜHÏ>âIi?%ÅŠğ ÕÎXò -ZE×²“‹2¾TšSÃ˜Õ£™Œ­Ğx_ıC<ËæK5ü+§—3ùD%‰‡VVÕš½ ÌyEns¸÷®ë½q!rt‹)DâwÔÕŒõ-ËX.m,GgÇÒğuıT¸”¦ÿV0îP(ˆu‘‹c¬½Êd+¤}Cş¸¼å€)ÔNÇ„6¸¨T.käÅs8áµ<ibí]Æ± Ì=GLŠe5wµ±€§¹¦;i¸lˆ×<®PX­HšÓ®Pj É	ÿoac¢$‘{¬*gÕm½  XAÅŸ2 ¤¯€ğ·ù±Ägû    YZ