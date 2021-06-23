#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="574397869"
MD5="3ed8ba212a0cbf0c471287cb7b696a9a"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22988"
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
	echo Date of packaging: Tue Jun 22 21:41:53 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿYŒ] ¼}•À1Dd]‡Á›PætİDñr…8gûƒ]Wqíİè£ß»T¶™ZÊ×‘ˆH©·R•¬²É‹ÈWö<S‡bi•=¬[Uâ©²’×)ºS8O“"ä×œ?+#R7¿@ÖJÒØÏ¡`†­îmW•“P‰ÎÃ4VÜ	=û½Zc¦)ÿĞånˆ ÆÊşKÿ#xdÚĞ¾:=­[şQw4HİªF™\úz¥d›Qì<µÔ®¥ı›EÏ]r?Ó_½E#Õæ]hÌÕ?L2µkp³®¥”Û°;¡^ÀªãRX»!MËî]%ííÿ%§S¼±l„âOq5Z;ªåÔCûIßúZmŠYDí¯ÏŸb|ó¬VÿAãZ&S›Á}Ö·É’6¬ª‘‡eybU.çV¦Œ½(oÀ”ÕCÓ¶ĞÍùì+HnãkD <¾lù|e¢\ôäÖ·®¬¸µ‘-³iâ¿úÙœ/x‰åÀÁºK€Ô9¢XÌ…,{«İ®X[÷î<¾·~Ñí‘Æ"õ‘Ôz’yw™pÂ`rÊ¯Å}‘ü~ôûÊÅ-J¶xÌÛÀÁşÌ&$‹ÖÉì-œë­?Şƒ,¤G­äÕ®Z
‡¢¦ÖpFş›×¤ãôpçêJ–{:ÉÙ¢²z÷²$ô®÷à_IÌøru^CÙşş€“.)H«GÛÎ&$.¾Ğ•¹_Dbêğ-J(&Š»œ|'’{µßPS¿UZäŸ·€´KÅÖ‚xß§Ó©áu˜17cíü7V»¢ÀTÑsé¡Æ¸DiÕ[Î~M9¶#áMî±İíÎğ&ìŒ;“”€ÌGnUJ.FÆ4æ'ğÏxŠH¸iZ=.À^ö†‰£!°]ıªk–übÄ€… …%t;,˜$üçAA±K}ÇC­u•´:@DàcÛ|#r>ıƒXHtQìá3ÿÕãòÃqªQ²n;1¡ö¢ä_·8i„ú»?òP=üÏ#	Ç{yJåt|Š´°±´¦ö@Zv¸/pÄWp!ôàÕ,\¾q”×YJï\nGÖ
ˆ¾^ş_•–Ş3¨Í
bİğQ½æ8‡©(A«Ü}"¥ÄÜÉ½ºn–§â7¥\ÌB*.é} à½yU—iµÂ|ï¶_ñÉHÀQfğ$¹¼±ÂÊùY.ú)ÊK•8gÖf#+ÑJ£EÚtS}wÕÔ_
ÆbQÉBÚáw½8ÔX/ê•Œ”«	»Ë?¯7d0CƒpmÙè_×ÜÚïµd"-V1›ÎzŒ‹¯Y£XâbWŞÚ"8Ê5†ŞçíÁFö\eñ¸¢]dú9,`¯¤GWY7pÎ	°SÍÛ·Õõk«R?s+·Àh<˜†…nÅ“Zp  Çúäy²LAY÷º"ŒƒŞ&1›•M”zÏˆLiÔÔpÆ4EZC "”á‰’WáßdúSU2L`ğª&¦©rù•[êHõĞ9ÖÅÎÒî;cÜëEwæx­aÿæ`ò}Ş¤ùÒ¤ (å¡+ËUM¬xeçZØşˆ®è}á•y—é÷GîÓ˜W‹Éšú¯ä.Jk÷·Ğ‚ü“Ñ:’£Øc6é’c‚;WíÇ·ûù’S"˜ì_ØªV]Z­ b¶e’qQ-+1«éèÊE½ÆVBlÖfHKùƒ™ı¸ŒšŞW©nK2(d—Raø§)ÀpnaXÍ~ƒyÌ”uCÃóc–•œÿCkÙ‚ê€“NBÅ¿Â¿D’#Â"	 àvW†ËA¬£ã$)\ĞÃÅÏˆe´…W"ğËj4^Ü=®HË—Ÿİ|4¾W®ã °¥¦‚YÒéUƒ2µ„ÌŸB*ÃóıíéhGPµl™æ£e_iC²II(¸åÜ©4Œ_¼n£Gº^]´EQ‹}÷
bqA±‹øgqŒ¡âï:^îÇO4ÎXG³ÿ‡Ad	‡äW>%â gš[9p©™&¡y¦qæhGoôCàLş%[î¹“ñqÆ¢aÿEM Òw¥¥Šª$ıfhuwdw_:kƒ»§n^}áü|G|‘yæFëÅë™¡‰%e“Ç%ì¤Š®f4J9@{{&¸˜¿ ½u!·9ÔÌZœ­å€²ç°õ	ÎéÀú¶Mşp°áR«›×|‚¤…XUaË–•‹0n#ì¶^/Åok+w"/Qrâ\ ”ÏóŒ0†¬ò/H:ÿ4\‘3€õ»Y§³´<¾Á’1ß½i>­0ga:—}he	EÊÂÄ@•zşo¯f¿Ş˜Eˆ^éÙTœæ ¬àÚChæZÔ‰ÔÖÁ“@µáÉ>ØmRüÇöGA‚Áˆß‹Î,îztÕb¾î,Åc(×Ğİcı"V£U{-«‹ò$ƒùï 9LÓïØ¾äû[³N0Yñ€%O¸£¥ÉI·Ó¿İ‘Î0¨´H‹‰ŸG,Ïµyì{=—qˆÏ^ç–ävb^„¨xÉÔ€AU°.Œ¡¿™B1ğ
$Øz-WeÜ,ú:lı©öy¦°VsÄàB\¶iã³	qŸ¢#)3¿ë6Œz—Kğ¯¥˜~\ÈûØ–ĞZ· ùä?úş‡Éı÷zX9¥¼¼ÀQ[j¤>oI uXÀlZ+L•›`˜å{¶4Í’!ªuS.B&‘~Z
ÿB#ádÌbAƒ^&€ˆuĞã2ôVvùÔ]{b‚¤lrQ¯+£€·ÆÏ;øÊÂªËØ³#ÖÕ À<ßA{i5ïáÅ—„‚…÷éóGŠó:{áŠ°1"äËÛ•¬Å¾?„ÃûYaÃ!À:ò¨¡3ÇPhSp´—
Ç•ìC°ù!Âş¨<4ÜoCÊ­™¤¸âï
ŠÆ£.|nwÚ `Áà§QD&-×Nv‘Ó,¨ÓBÒ	Å0?Aræøuÿ›şxTûô¡$c €–iš{ª<ç£-ø¾,¯ÙáW02JÆ½óÅFâ¼WÂöLTT0Î}¾º³‚ÿG76Œ6´Ûş‘Ó‚Dm`½1KPé›ì^örê]åÑ³P9IÛùåÄ—k¢ÈèÌÒy.¥èpŠ<àÏ~Ç"¦ÈãeáŠ—v—Œ3UÒ¹ƒ‚™ƒRÏ?‹e.ÍX‰oo´ñcÙwEG²‹§|¦¡õ5™MÆwJó7¢¬”Ğ¯„ÌAeµÎU]~#TéWo‰Ü]¸¡YŞø·‹Ğ@0ƒ~3
ºko'­ŒrÖU¼"9ïÄ0c«‹ìÙéˆ¡Hu“\ì#<S¶—­ôwgß~("·ßa7û­j÷ŠSŒû½øÁÁØ›S~
à[TûYü	².†ú)ã«Ó%[,&·ŒNÃàpÅ7ÊW'@pÁBOÈÊçñ²¯C©@uÂ Y,¸My§Àg	ĞùÄƒ\ÈqIAÈ×Qš:K*n#”qÅò?<ñ $Á®-é€­ÎØ)rÔÑh6ošS™ŒYƒáıl]bş	m}ìHB{à&Â‹¡«G—x„Îc¶
m1bÇ#Y)ùC¾!µ#l9æ^»’E:Ô|²ìıd´ "’ºc•ÊZĞ1?Ü
¾?|üĞ¼J–Xk›¿]˜…YBÇÄ(9ÂOƒ®äç.Ñ«1«q$h{ôh¾ª¹ŒíEk³‘­4[/É‰Ê4ÛœÊK—ß´+³µ•G—ß:®Ïu~1™'¨¨„-·X³éiãÛ—A1>,ãÍtºßöÁWÕÊ›%#àÙì3Et¸Ğ}“>™ÿ³­w}xÉ\P,Áú½¿\hp¯4âb¾hšŒéŠ*ÊXÛài+íÀûËĞu¾''ƒ@¥jbİªÔ@z¹‹ç=éÚÑı¹ c=; <ì¥N"X×‘±4Z=ÅÀúûÉ¾[İÏ:«_ŸÎMŞ§¸Á‹_ÙùÌD;ƒ¨¡ù
îêeñ99^¡$é¿w>†%t^/W`i%==±åµBœ0EÖòä›0í•yŞìv ö¨eÎ"á(ş‡cqL‹^G¬&õC…’¼O[äıv@—|kıc¤ÖŒnî1 hX-‰‘¬Ê?M‰êêÑiggDá-{ù.(ÉŒÙ·@UWÜ/D“úrl}‚µ':ó¨—ù®Ë¯ªRŞìÇÜ†ã0³×œÊ
:ÖÅÔ¤½„ñ{,šzc¹×òÔ1ıvp¾qÆ:âÓ³HFåZ ×#óm-|Ézhšë»íeÙ±ôA•p.TjZµ#'£$[™EK³~“Là
\?ì/¦>haGŸ·?!$mçˆÿdu©K Lãíı‹i¢So"Ô©ËG«|Ë¯Ô¥Auêz}<¡&¸èŒV(h5Cv0¿ZÖÍs';	1e,8‘_+ŠÀ§äMßÅdc“ç“›ÉâºOŠeHÀü:! o4YÉNŒ=Š9l^Ö)³ÿ*(ÊÓ†‡ng`!…QøZş¶ˆWã¦'6WàÍà¾ü†§ñˆjÈ?K2eŸ›ˆÙs·dPÄmŠ)B
"ş÷çó°åÜë=Òİp[Å€ÁÄ7‘ä	‘00O÷¥€ì”ÂÙ»°×O§ëëŒÿÊz¾c†»'*ûúfeÚkÛğN°ù2óÊ{Œ‹öFhôÉŒÀNJRŸ<„¢–Ø²8êÄ‘=€ûÊ‰x¹õøXø«]¨øó•
Ôö–©¤…hê³™7=æ¹Áge)ßç\¶Á ¼aÈW$¸qÁ¤NÑ¿u@Éƒ©†×cŒç‚Óh4J‰ÜñûPôM‰IE½Vµ"kK›lö{Ùòò'•ÖàN`	gÒÍÇ
VÏwõ@¯V%’äw^É ä#(‰š€1}.¶°…Y»+4n›ÉóÍÁ€­7ÆhŞ¾?lT1ÂÜR.ñr­zøœXW¼KlXÕŸ¢‡Ñuïû$õ¥Ğ.¶ÂÜ¦}É>µúÙ³Ÿá‰WM+«ôRæ¤¨(î¾jú):2.R’~;cQ€Ï·øa×<m/$)®—M™]]Ú­˜ #Ñ6%é‹8úßN*¸^¯Kôkk¶U2ùFƒÁˆ Şø‡×Ê´
C°Øqö†7 9w"ãM7µrçÌ8Ñğä•s©mŒºŠ‡¤æVX—Ìl²€”J—ÂªFj eù˜3Åªñ+>YÅDIaû ”*ùjù—1i?‚]8PƒàµH[C•\ÑE­5Ô‹ •Ç_'Î*”®æËAW¸›¡Û˜Õê£­6¯]ÍmƒĞÕYØJ/ÇHVEÍê¤çéJ1ÅóK¹©\âÀ½+sú/»‹­Ë¯‰;Õµüë!w Ù=ÊÅ½Ødu¾ğFs¢Â”Ãn„Ñ~¶~uT©~EÕMŸèBEº(âÇĞ~ê`6à}8"+Zğ:’}wz©F½"R¥)Ka¤Ë¥Jê÷à{´€Íw5H:Üi‚€ŒFh==³&²P<¯…î¤‰<xÇ½Š<dÕÊl¤æ-¬¢f]à,»1DjÆùl¶Á~~—aÇ.`¬ƒ· x-Á·Í^˜®nåÈ|ô³¼;'hÍëâ3~«k):[õo«F»Ôä2ˆ«äFgªï0–Ÿ?œ´@ú°5Ü½Á7ì@‹›€«K±Úˆø$5T¬æÅx)I ¸ŒÉÎ=¾Àû_è şsf]ë½69.:4¥s¨¡}³_Y±ódk”¿ì¬m-\«°zt®È®ŒùÜï»N‰ƒ
—+¼/¥–àÖ…+lÀéÌÔÉdIÑÈÀŸÚdég-2v¹ÜÔˆÔS4avDêƒ¾úšW% ¹ÀïoMš±9{ì„8r¶Ò>*ˆË¨‡H bf3[Û]Â®Ôó…¢ºbİ2IBçZHÉ¼ÀCKMçh©åõ¯]	ğVúÛáE.G/ğf£WÂ‘‘Ùé@túğ´"Dhh¢ªŒCMx3#ûÎb‚^bÌÃ"ÓS¯P÷? Ã#6[/v’µ‹1é–Íòõ¦mÕ†ºÎ3ÆN|SÏ=–w”ü"âíZª_¦œuä×´É*şmmñ©‚ŞßÛÂéôT¥Rı4|QR|>U.´#ôÒbyÃ²D5…ÉÖSôjW’ÆJæå”„‰çmcYú;ï]²ÈöÔıñ²d9])ò@dˆ·á¤vÏDªiîËhó%¹·ƒ‹†·ÛŒR»îêgv8x:mv2Ù½,ônW~Ø
»âï”ŒûK¾ÒHbCe'AûU`†¼?p"êPÆxàÜ—	¹K•¥˜6{j:=oiÊfmJˆ–¼íX}mMWàL›ÊÀc»C´ËŞ(x‰£`P¦ãà…ŠLÔÃÌîC¶ªÃœÕàZÎ^q±ëcÖ´ÏR€‡AS¤±dâ•zãgM²’+5a¦ûÉœ\E#&\p:y*
6œf@µæÕ0†áÈä‰à½5mÌ¯ä_r¨S'«kuÖ	é;ìbíÄ!DB•gÖwì7	ÿ©¼…b4xU±±k*è¿*+¬Ü^>†'ß®6ßšB§Ö?îº©XD¯rbzæqiş‹Ç"0ÄÄ"!›æp¯ïñœ	B¥—Š—(zò­@bË¹¢“ä¤¿ó$x“M’ÆÁp4Ş3šf„É—6ÿ1ßÚPÛwè§f_<ı!#·h¿¿·²+íiğãDÀøXÂö«’ÏøF¸Ü®©=õ ŠÌ¶™fÍ^ÊßÍöÖÑ='èæ€© Ñš\BfÔÏ2ı’ìCõ…Ø¼"qòÒ0:–Äßr§‘«òFPãH	Uösğï¶];i&P!áö^y„º_¼AgW0{æÒøs˜Õé‚W0‡œÿ¸FŞ¶û)”Bşë‹»ÌÿŸØ1Ö€î¹vác/è`î‰½@5‹ÑQ‚ík„ŒXvyb&OÚµ†m‹ş­ç¤k)\B-mn:išª[A_BäSôdj÷ş×ÚgZÒR ú68vŸS ±¥*Qó¯JİiM½tÎ û‘.J+§Ñ¡¸I¯^jËşw‘S§˜Ù^Ro4ÏšM²ÉàV°øŒTPlW İ)?šä=6Ñ9"4ûJ½3’xİ~¡Ñ¤¦ê1³§üôt@#¶9lœ~¹Î‹ )Ø¤§,,ĞÄJßuev¤1RèçBB÷#i7\q~¯ gæ…\×éN*¦ öáÎeK×Â¦™LYBCğ®»‘•Ú½ÚT‹ğVò%ôú¡e[’aòÊ“ri7Ü%ç;_r”¯^£›-xû'l~«k¤Ö!6h¢á„2L‚ßUvP¡é~åó(™‹¢¸t)SB=jô™—		Ñ„ğCäŠÀ~ˆ_ˆoÌ‹KØ0şÌÒG®¯y·³7?¸ƒÄ?©¶?Ëöhk¾:‡¼¹å6<ì˜oß€,ÕÚØ¿Ş`´ÌÖâ¹"E¢Âù‰­]f<FÆÚU²fJ5!•XçÇîÍ9Ø¡)üzÁ’VA«İéÜ…c½@>]7q$òOë„¥-É’:ÖYøDƒşò˜I}!¯ìÀ>û?ì#)¡RJ=ğs§ÈX,Ò|ÖgˆÎœÚ…!E#üåë‡¦ÓŞg“İÎ FyZ¤ì©I©øR00%¡Æ.O¬™mÅ`<,i÷B6f­B*E†Ôá£øHèÂè*¯¡zí•ÚøoG3‘MØÕÌhw¸y®d ï·Ø'İNÎxºRFK¥±ÅL¬—övšÃk_ÁdKôÙĞÜ©…xc¡‘g¶$F:Àú”¥é!ZˆÓ(Ğï€¾ë
Ûî¿—R¥SHØ>´ÄÕš|šsÏœÔ*$ñöll)òH`İæD'.8^xlc•ş&S«§°P‹ãñEˆ†²„ÕÌ—º€'¬RØ5èÑwb(×°hYM½!Æ]ƒ$´Ûê0äŞ9RƒäÅµ@=f´‰µEv®áãqÈ¥ñ÷8ÒÚs¹x`À”zCŸ§ìÁÉ½ã.Tª-Dˆ	î»‘7»Ù•|XoØÌÃ†Ş´½YÿˆrOÈßPœw}‹¨!N6KùŠJøŠoÛñ·‰qçÒ˜=¯ö)Øœ5k8³hô«•EtëÒWÖGFoç°Ã¬ñ´¯²!v…s{gd¹¨Š”+ÿ¼¢1ÍÈÌ«i~MtÖuœ“Ğ¯ÊˆE¿[ºlÛ¯ˆ­E²rÃ‹,À2byA‹â,³‡+¥8+éÌ½ä›¥ÊÃ*BäÀ2>ä©$üLÁéGÅ'ƒeE/—Û	u ¢gZovæâl ;àT)Õ©ÕJU&i¶€n ×—zg¸²VÑvªÙİ•+¤èGuj²–b›|ÒôL ¡_—á¹°î€÷jQ¹½Ç{ÒwXéo
?÷S¢Áäˆ ¢W@w:Ç*Kû°¨QÂ¢EğgA×Üp³-îÛ<Ä$û‹¢ˆG¦8¤—CU9êºGÛÈ)#¹#úãêC;×ëÇ3¨¿şïæ:%píÃn@Ò$åã¡¦!€ô-Srå€å4èì[úñ¬¬£­T2]\­³tšşs'%t'Ôí¶ „p	6/	£}ñA¼º¬e‚êSì›[êˆ¹¡ˆ°õÅ¡ş—@ìp¿[”%ŸĞ¦3ÁqMö\3şĞ•8m°ˆuQ@[ôë°Ë˜K”Ç14×6ywÛ•ğ‰UÇ¡ò†Oõ>#ş³€M=	gTGSItåøn¢Çğ¹u÷£+ÛKJU^‚]E­°1ç–¹´šş#×Dxz=«,Óüiúˆ¸³„vå"e;ïİùFø0 GZ£Øÿ¾åk±…âu q\jË÷ãˆ©‚ü£ôtš‡ïş«Ç­‚ŞìâsÀûr’Ù•MÈ¿958O¾ÚøÿL6!#Y,6“ü z]^M«€j‰O­=uÌH/ŒvË8÷ÎùºW/íñUˆ@í~Xd¸0{ó>úJ—4£
9oºÏğ-¥¡8%…·w‘äÆGß¤L¥ '†Ğùï&_†ˆüV&[ÅÔÆU{oY®Ÿ¢yÁm/¡Å÷=8+dŞYàá9ï!Kp[tj¼mÚV1úIaÖö[œÁâŠ_+­ƒ¨·Pß)\Ù¯`ÏU!yäêáU‡GŒ:[2ÙÓTc÷í ÏAJt‹ÇZ¥e–®ŸZôÑ,şl´ZÑ ÷­y£’)	ËO?ËË6œ*ó:ßYxó
rØ*üßß´vòƒ“^÷ñ¹‘şôùç|AÈv2o6´~Ñc«ƒ3…DŒû7ßhÓ¹å66y´”ìfûÜBôÜßŠÿ.tBúõÉñ³‹pR:8øô1æì‡Šzß}ÑÒóş’ë{/|<;hø¦„`,/$ mOÓÖŞ ­}N?ßÖE;fæÃNØÍè§cB4ÇÑêuµ”…«eÚK–Ìâ¾üÈM“+ƒŒ¦ãxKØHõp5£ıWï ù˜Q²Õ……î±
ñO©èÍráÁ‘—ÒŠÁİ»Ğúé¾¥wu7_l‘ß*gñÔ[Qˆì÷—‘â“i¶Ñ/åÏïîn²ôÃ;ÖNo×lo³‡S[®bH•Yï cº‡	ÅÛa•™#jŒ¦ì¯ÖÙëëkK³# <¾%Ë¶N„ßŠs¼J±C#9˜¥˜[ã3j)}ÒÜ$[>ërtš±"³µÖ­LÔƒõ!ÿv‚‰«Ûà²ó4Éå©KŸ!?lËÀéFŸf™¾ö‡¯³.Ç´×öáL†‰×Za1‹İ¿Êû–>Z¸‘â6(–È[U6­áJØãó´ë5¦åÎ~p&€ûê¤+2.x<T3Ó Næ¹Ìßs0yƒ(¥İ&~z€Íär(Pİ·GÊİ€lÖurˆ)É6LÇ*‹>ï*rq­s ´Ct›Iº£·D~‡(YƒWŞN@>¥Ñv8?RX ÓßßÛ4ÈQÖB*ãä‘@xuòÂš#˜;L^~O$#FéxÜÂf”‚X¦5NøñÓU)°ô#²Ìzo:ˆ¨ó4	Î¬åVQû–ú=ûïòˆC’ó£“-}`¢eTƒï»±­}Öf	›!Ml¢Ô5ì°µ,¢=]:
8*3À-BÆ‚'Ş°OÎİ=Z™«ÃØÏÉœ,É¾¤OÄ¸“q^İZ1Ãügœò¨ì*)°å(×²¦NC|Ş©Êf]aŞq:½ô!–Fcä6ßf2¾á&JºÊ²=9æ`Ÿÿç$ÀnL¤ù?ŸÿÙC~Á`Ä˜ ”/M-5[ìãuR”¦á¬¾É
€ JÜ5A —”ˆ^	m0à9º~ÅËG–&@Óñ;³
V«©”î÷êjÇa‚õB÷1
Cóp.œ‰#ÕVX€WEá+aƒT(¤g¯õ%è‰^LGÙãÍÍR3^)voıê5Éˆ¥WUìÛ´bÙ¸_ÆÉ$Ó™ĞŞS´3(/†®Ï|eM­“fÄ›úö7ÏñO—§óóŞSÂ^¦JÈ7	Jíƒ€×gªUêâì÷+ ]İšb»d*'â—­¹†Î«µÃÙëq•ÎsAˆ¤¡jd¥ œælÔ¢½09èÎÍ0»œ¬6Ÿu^.U¦_±IçÆã,n\<£¯ö1~Ìó]ß• 68Ñù=rwc•DÜ)©QIÛ‘Ì Óõşgü ?—1x"·î‡’´=»Ì›Æ ¬Ÿì½«›¦5¿ÕH±+bŒ-í?”İGSõK3®]XœşßQ,±g¢?ıB½3Ú”qéÚ™¸ Iç`˜t´xı36™ä…­U>X(KKn/´Ón¥éâ¼0m¿_s?cã/C-~¥§óëŞ”ö¢åı‚r}ÛÑ¤šMU¿€[’#«$1L¢Ğ„|7ºdÒ}aV &tÚ`Ë’¼Ü„X‘¶<ÑïVH4³_'ÿß¶#É€Ó_ça,e0ˆH ÓşÍ—-0_zŸ.1ZÑÓ¾	´AŒwğû~€©vDİ2ôÎÄÀÜ‡ZñWx †ñåí!}ëòA'´9Øgo¬ËbÓéx[>'e>A_ÃŒû/X‹1„)ã„8ª¡Œ
}–ÆĞz «g” l"Õ%ÃØ9mtÉøxê"˜ê]Ñ8(dÑƒyê;$wÆeùÅİ‡¹™Ü¬ÁÓÎbª+
sÅ};woA.«§D¬Æ{‰Ö¹¿-5Ğ.4‚z¦|/QnïLÀ:6P$¶Æ¡sEgX¡ç(¸€›¾–r¡d'Ùºj?68ªY…?r3ÉA.)WğÎQÒé»×Dq­A¾â(%Ïs'”Í%ë÷RÓçñÇIïDR„hò<»Äg”[öWûñ^Kk„ é³KZô&Îöä²²˜ìM ™*ÍDS÷åYíäáØ²Ğb£jÏñŒİ¤Û­è65?Ù–ğ©@ƒ”©’¢ûğ[õá„	ò`œ¿—õÌQÉ©UáŞàÃäÜŸæºX¡¯ì<é>í4ğ'}Ps³óp•Ïº:ÇiÚ»"Øâ:xşû™mª©+fLI¬‚µ©_™O#¶ùæZ½DvÅè€‹$8õµI˜jÎÌXÖÅ%‹q¾	Æ #|$VB›`¥Éòê–p"p¹^èx_Ñôı·ÕKÍmEïM5µ^Ï9Ù7tŒõåo÷&R?7üuĞbºfLıù‘ª9Ò˜~4Ç¯ÿàrGã¦lîÇêPÅ3ÆÏ0‡&YÄ6Ìrı}şÏ÷óÔÒƒø¢QÏ"u`nnb™ş§Öó€D½@?Ûwrj,Ğ$ú4æYÁSkÀ±`ğq :{R¦~™ü^J€¨ÅîêÒ7–è`ë¤ÿ ?¹8b+Iéc¥r_Ü œ,¿“|)H§o%¶qdja¯´ªÇÂ€ÖÜ3'µom³Ü¾Ş
V½°<§^ç‰§Ôÿb.üdç|¶C1ˆ¬E+öO´D±KåØ$6ÿ¨³àb†ò~˜Rp`_¿¯è(bÖº1Ó79ÄŸ½‡Ù9–ê¥ân¢º+v:"/CšDÎPæEFWrer¿@/¯!ø	r•œıˆÏ3HíèØ}âÄìlş‰4²PAYŞ·0ÿÛø++¼ğ&-§³pÏÃÒÔ¤Ò{?;ñ¿ašex7~{Gè<Îî—E·Jxÿ•©ú¼Ô) ZºüN¯[ƒRã|—½J·(YÏ…«‹jõ}U”tcÁÀŠ³Â&
}·Š	42—%O43É}HXQÙŞÒzb—LĞ=Ô…´D±EÌ¬kÇ»Ğ#Ìq ø6Ê>¸Õs'Qå¶Lø6³ŒaY  qÉM±ÆËú’ä¬… 	/¥{ÉDùºæš$7–’’ï$›Òoâ½hÛß¢
D>ZÅàpa¾¯|y{³Úè,İùêYº°?ÂŸ×?¶¸#ÍI§3õá¨ ¯™	ébf¸rTÀwx…É|: çûÖ£ü%›·şÁåLäÒ˜ÇìŞß4©}>pLLtîĞT¾Ği×zXsn³üHÍù
£&.U9Æå¡;ÎÍ&ÿXX‘â™ØŠ[€ğ#ø×‚Mcjœ7O3ÁêÅE½f;Çbò80¨í®ˆãšB_qFãµ¹Ù4çÆ»~¬gœüRŒ…·ösZ#\_˜ƒ8^w¶ºmóZ’¦:0’¯#Uù.§~Œ ®È¿ƒ¾Ìº¾ã±fô´}ÜOSªTr3æïñ—ıJ‘?,ù8Ø½F³„¹ú|¦®0oİ±¶´×™íÛZíÀzÿ•¤šy?3]k ¾M£ßòÅZ»2Xuò'¨àwuÄºu9“><œ0?ÌE»nßyêPZÄ¹6›¶Šä×®ã_bß˜3|+G&7™·¦2`c‰¹ 5æ1¶5émlV0­*Ÿ²Îé¤ÑnÛ±§î(¦7¹jxRpîEï@YÅ›½˜1S3låÃDFqÄ¹ ÀÆ®ŒíïKp]Çí¤5ûCğ	º?3œÑ{(ï¾«}=í¤ÄÊø“eş.™«o¶‹—Æ½=•-Ñ{}V¯G¦³
4‚gTv÷òÅ;ü[{‘ù¯Fº—€>ÙÀïWMÙ>'n·¢I“S<àËÏßÚ“ƒ½ƒ{i÷;üÉ¦ºÒCVräL¡ÿb9VT¹SØİYjMZß×œòY¯ş ¡+{J‰LX\¨ó‘swp¢K–}èZOb·¿–Ë%âòmÛÊzxú@A‚pnĞ¶
¤·˜Äªm¤§ªÙ­SP„³` „ÆıòÊªË MÙK1j´‹ùqa¹<ç±€v—Èpâ@¼˜²Í]µ°Øf‡uÂ¾_íÂ£±/HÈÁº­%Ûô}XEç	2$’ÿ%Ö!ÖŸ‰úŠ3Š">Ï›ä½»áOXÉúª["Òåèˆs»jóƒÄÀ;êJ÷<ï^KÉGA"D0Çuœšf';«…›¢ı•y~Êœ§Ê.şQ\….ØûÚ 1šÛ™lë ÙØÈ0í ]ÕMÖïNüëå°ÂnxÜƒ“¶ä#°=9…È¥„x”ë*Ùğ¾É¬‹B)#¯¸¥Ïfyƒ¤}¼UÏúèCpâ»üö@<è­!!ÒIö\¬…şQº’Ø¿c“rœo!uRR®¦=å•Î€	nøœBf\š^AõÍ¶1È"UÚñ¸˜¼ËÕë¢©Û#§‘ÅG5GÍŒÅŒÔAk‘ô³I¼Ğ•›µ$™è €¥D$ˆ(F- €†YÈşF^/Jg¯×•ÃÌ;?Íà!q”×8·zw4TôÎgíÖ^l¯GJm#*uÃšÙ#*eJĞÀ>« êí§èùf¿76
şVÈ«rb©ƒO.Ü`É¡¢„İbägà.VJ>oêŒTFkJà¿»üH˜ĞEl=:zÈEİ‚¾mùæišñ`—Õ¾KÑ¡9cx¤w»ãÉöEÑ¼6ŠƒŸRùÈùá÷Wâ'"“ßUàym?ÚØÄ‘±|SâïDrw~ ‚#œ„ÊÎÃï£°à«ñ”èŸ>W/½¼¬ÄöàïL‹luær‘T0~i×1``˜w#5†°w›ç×Qñ	iıg˜µ³#şŞ yzcf‹*‰¹“‹,€Ö|?¸·œíˆUb”KO[G¿´D‰ 8©(DAÙ¨òQ|~nŞÛ‹ŠÌx·Ï4ûWhF=ŞSmûÒ”)€¯±œ&H›×Ãù¢ÛG£m}°ºyãvÉİÓ¥wè^‚y[øjN½Í=µAVU¸4C6ìkÊ:ÉCK¼Xîtç1,ù9Åv
Õv¾åq´4R^kH¨“Ö)×zfğÃø¸Œ¸ ¤ƒpd-Üî§ó0tQÍÙy{•½ç·
¼©ÊÂ©Ş™¬Ê“öå¿£\Ñµ¬r¹"ü„i®oÚ´øü>À.!GÖGtËÙ`¬5®ÿâYvP60J©¥r?‚i€CVs+éÒC>wÛ#!Q_Ñªƒ£®~=¹&»Y¼€°¼v¯(ş&'v©qûfW£(<¥º£ù¬vÖ¢ÎòiGzÀ
˜év«À®ÍµTê/’¾Ú¿%43mA¤ğ”Èçä	ùPN£Oğvº±~NlCñ`¤»Z×-^Î&„ T>´ñiTÕWù¯ëf0Á¡[ø¢Ò1Íİe”l\NfİkD@ò¯¡‡šN6¬Óı•ıè•±„í.¾‹m€¦qİ:æ^@ğå’n}|°^Tøl$IÍÖ <Ÿ‰,ÇPÜsÌÆI0Â”“LÑç§¡CØ}vÜ1i]«öå÷_6Ğ½ôÕ=¥(/‡azI©ÎhÔİ€ßtÀ—†n6Ğ0·NÜk£Ì=˜–x7[ŒÀÓ	\ó¼´SZš•²æéùÊX8È‚ŠF ™O¢+ö¢½¹çåGêzëÿ^°¨àjÿ’¶gÓM2ç øDH\›y	(¨™lÅ‡şõÊo¦Ü‹Ş—}ˆÀ·1„xMú±Jö…6—ø¶fãXsk/'nÙb[ÿªú_h½úH5÷Œ¨Ô›*®CSOIÃ½Î®¸ZÑ.œA]îI…ëu“ü„V6Óâ\iX°:`ˆ3ëJh;åu“Ê¦µ5Êõ·zªEíëîu¡¸ÇW„àö¶6Dè!ŞÔæ¦‘¢–Å‰–«I½yDËò”éœrÙMğ\I¹–÷âÎì7ª`­U¼‰!a&Ì!»Z½ù£s…Ò%×ŠëÄlwÖÒqo=(«‚mé¨`µkx§s–?7«¾™€j§} · wn®ûYÈœXŒæ<És>¥íÅĞ3ßKèîèì¥¥÷N‚N<ŸEş^ªl*NÜ`ÀgòY!BqD„Àè4ÄPâ¿'P)sÑ}‹A_²X=áé	—NR°—±àø6mB›2~Ím´½ÿ1ä©ÛæÏ›ÏÆuòW•4$ñƒná,sş¹&#oµÖ;bà#…€ÙğÛ«¸÷O½´8Ô‹>—kpŸF`&n4lFò¾<m šzpNæ_§eÍ_V 8“Qê€‰µ6+C8öW}Lİt[-ñKIs#á5"¨ÿ$"ü
°B§…º}¬Ù:(XæmàRö…a| ½àqo%3Kî¡èv¿Ö9…îsšs¥:îÿè‘¯¬ç½(ÚŒù˜d£^×_„…šĞ3_„dqQğp2…œÌlŞÉâŸma®Ş¬-02ZÙ'ßP&“Ü²r•'_şØã‡øhB÷=İ¯Î­ïˆBÇF:…ÁaŒ¤ô3L`ˆU™i:Â…ÎN¥êB‰¦şc©»ùLÙÃxxªÕuÁ²y£:jT|ò"rÇ.Øm;éŸÂÔÍJúÙ‚"ù© 5µ Ôy£ysxLtø«­ÇİNpÜ’EwOàoŠ•xœ4ÅXÂ çùÊ¯uê´ã{û_ÊıßOssHß
È¢Y:;F•[”öçYèæÇ€bö'ˆ•×#	¢LYø9ğœ”“™÷G¼*È'Ì.Ÿo(æ‚Áz|Şe—_ÕU'å:šòŒM.û_
y‚øôà=_£[_GİWÂ|È´k^b³GzÏ@"XÜ0uı¼¤ÌXcTÉkÄ‘õOğS' ¹È¿%µ,r£.äİàf#a“àL]B;~6Æ%4¨'Ë_ÀP¿QvotkêZp¥[¨[Ì;Â»g¶X#M¿œN–_½QŸ Ò„ÍZûà©‚ô3©bi>E<úVú;;Mùb¹]ğÈ"¤Ê×³v…¥!Éz*:èB°z
Ïo&è³ğŠM¥[èöãÿö‘¸ÚÇ¦²‰¢‘Õ®5qS)|³áj'3ä˜[„OE-s~¼)Ø°<ùZá<2`Å\Ä}ybÒÀK3Êkå)ÕÀX\à|bgêÕÚİnKq9Ih¢¿ˆáj,|ë|{*4&c°yOÄ$sÎå#íÉ]Lê"ˆˆ(ŸšÔnºaØnHKÌŠÛgwb;Ä›õÑÉ?ªÉ±÷:d­×d±	Y“^[äğ¿îé¸OÜ
{<†hj/¥›[H&Æ4ÊğHª§C}@j"ÉNŸüÑ¼‹8»EbòÀ½¶±Ğ»ß6Ç™xlÀáM²kÜ`äü7SCTë™W¼¹*Í|ìÀĞĞÖWB+?`àÎc´R»ÔL•Öcyâ;$_<zv]¼P’ON…9(U^AÆ4H«iå`Ö&A!ÖC>Â×}7F}ÿ>õÛ¡T%©S»{ÍÊ<˜ğç¸_¼t÷suWG‰ô@Ü'KÉzŒ¬f±uRHöqúØ!Ñ!ºs%Ów·ÅİçˆAÌ	y¼e>“¢©¼O°ûZÖlŠ·®w~Î^îˆùRÓìb9¦>’ŒòšïÕo;eû$šøŸr;SÒŸâeylš|eáY™øÑ°Ôıù.&ÄhW³±õZy1kmHş¢¾wC}Xß=$†´a,‹îH£şwaÍ¬édÕö<UÇ(*Wz¼”Ô
ÓŠ'¨>ÉôŒİ®?á•”—óUNÌ2¢r³oQHµ#Í'‡"3»D(
g%¡˜cx_"øM6ÆbÍ;xõPÒ&™+‹¦2Û¨‚tª£ï¡Q¼ñ#úÕ}¸
"Õ&Ø³‹ÿ“Ì‘x¢…ó4Ü˜¯%	öôõé$EµiÓ•èÍ½	D9ô£Ê#òÁH;ªmQúy‘\'ß<½äµ—<BØã.ã–ƒçíƒ\úê#Èo)ÌdjWÏ™5·}¹(iü_Èw²¡5ğDÍåv™/@]GÓÅ‚/Ô.S¨)÷éşŒÛŠ(Nç«nr)ÃLÓãŒŠV9³2‡5ZÖ~nVéå£šİ] ŠåûÏ-¡hÍŠxèò:X¤2-¡Ùqr:KıªÔ“jB«J!	Ó'­ÇÊuŞœ"K¾ZÙì½8ƒ­ù!¶ÚF‚‘$•Y¢79éåâcÈ‚9‹c~T·9Lbš{üÚ|Æ@`Î^	¸{¾ˆ©fÓ±ÒñaœóC‚ŠºÑ15ÓPyÌ[ë˜<˜r³0ÒítK	#õËõîúXEaêö½ş•Ö¸KÒ£µõ*$«W(IB${rCÜïa…ı!4,È·‰¸qÂÿ$ÜtRµzò%#ÑB˜^%	€áÛÖBö2}¨¾|r¨a¿™†doŞ³n/NŸãHÒzj1° 7ˆËŒg…á¦,¦ƒ°€\gpü&Ø`IXÒ[·òSÕ–ƒDªËPh¹ÇôšYìÛròFÇâ‰¶ôò­‰ríÓ„ZÅôhş\ã7çWÔ¨+×Ä\¨¥·Í¸+>p v`.M½Ê-æq§€Çµ•î³ğ¶ğşëŞzûTÙÁâ:!ì„—®¾[Ë>Fe3–Ë‹õ¯&†À³ïï’-˜%?ÓÎ#i,¨ÈÊU'éŞÆkŒ£¶ÇEÓWÔ´u™Ü`cÙ*K]ªV³W¾Z¹iùæ>ÏØİR{?Éz@¤ˆL¾·¢5kj@v'õ€9§›óªcÄ¯¥‘3
VDL9ëÅĞÎÆ¢`ŒSÔºCC4(£’¡}éo^/LpßchxmJ%3tiˆ¯ùÇÂRŠó¯@{³\Œ#·=¼ú#oöyì’ÑˆBú± >}À`êD[ƒÍDç fÆu¶·ëcNN«ÂÖ* “0İ/™’uÿ$€§v%(×ñ˜çw×zf[ñP~F+©ôD‡XduŒ¿„nÚr/ğgé;±å6¤ÄM()iÃ!jxùµÉ³¹hÈö8ÿ¡³åú;®o}Gwâ·ıéÅÓº‹>ƒ_ùÇ•á¸Iˆxïí½DéK×Y*L«›™ßf]œ¸*…Ë0™Özw~Jb¤L6â‹Íû"ytv$rı­<yUR›SMj6”pˆı[B‡^E§cŸt;ö¸pc#ìE7ß8gb=ŠÚHå"<‰Z:M}"qXú?§†L¡6÷ W›Ş…Ç+^ı@yFáš'o±ûú6—/rk9hçà"ı7óá¿ŞÌğ>/[@&SFè^–şNØA¸•~gxgœi–¸«×!¿ŠÉ¿Ëå9œFaa$_âd‘Ñ?ªÆv1äiBîİC'÷¶Yj­)äÑMÿÍ¾,ºÉ\j»[­gm†Ï_IWğ÷›Œ6_›ApBÇ_ƒ`|—WQF4ùvı—ckÚÈ Â÷VuÉp'¢²Ù:Y)wP¼‡DåÓâm+,¼-­pØ‰˜¿i Æ·qN’ê¹vĞ„¤™³IAsğàß*„ı •s5£e‡"Ç$SUşÈ4U÷½sà'€¿­ClüéK@\íØèb®aª2İ¤NnâBøp©%GÁ~ÍF-´u> ƒÀXv¢ªàr&°Â#ôLôPXRfÖUâSØ/´UÛ:ƒïØ0l#?-â£Ÿõ¡+6ÈĞÃRH›@UŞQ‚æô¸/Ô›a£»ŞÌõ3SĞ"MbáQ€OÊÕ™D$˜&ºÈÉl-Ú“Ú#ÈMæ’YÃlß‰2ÅÛ¢¤êwV5ª]ÖŞ‹X=’c)OºÄ­â¯xCc:är}ÁçPî3·Yô98TãŠÓ§*À‚ÆâYa×T.õN(WTÆãË¿ñ»œ€7{KfÇ©Tq0"œ'j RÃLaU?ˆEN¢¶Â¡zšıE¿¡ij¿q¼¦ãÆø§‘DÉURñC³ÇD,^6I ›¬kæ£Cëv'Ü˜ùRç¯Åï(LÎ%´¼@%ıBƒÍ.`±ÜZÙhgœm+Hy_óôY%oĞ¬ôrFÔgÀPy_jÈ·3®ºòòˆ=@¹wQö@S,ªvã¢0dÍtZÖ5«)ŒÊ ÷rßÕA5S©Ãc²ıV•P³’£\³xÿé³Am[„Æ¿Ì’¬³Í ¸ŞÏ C©Ì×ßœ¸¶û´ÂÎ‹;}Ç·Ç3pAN-~öÄ©è—ÂÆ‡ÂRp\
ÀBèóëeY\™T‰tûK 5M\Æ¢Ş8­ vÚ¥;F§CÒRb¡²š¢à+ym#pù…¹
QÊ®T@¬ßá†à¢(!L‹±ÒUò=¢ğ'„:cÓÖ–Ã¤çg÷mQ9;gÁvJ£Y]ñ_Dåx§æ¥9Q/ğ¬\ñgÜ¬ùß_Wš*Q× /2‡¼¯éüSµõw<lÏeG>O7ßÃÛŸĞ„
³é³6¹fæC~$ÂÙ¤ò2bé•jZe;á¡ÔßˆÀz†ß¯ Y¥Â‘éëIVvF{>ı*ëA_ıÙ¾%UKWÚkEü¶§—¶$]47 \¨qT³ånAÛp9ÙX3æàòV¬!sÆ›‚P(£æØºCOFjHîaYè¬
˜ÃJajzhdì1p¡Òa¾5•l£ëĞ¸G£½äî 2=:/;µıÒÛéøÂb6[¦¶ˆıä~,‘f\qÈqCb÷¥NÄÎpä.¢&á}Ş6Ñ6¿æ—;·s°FœW÷,oµÛî¾5N¯½^ÒtJÅ
0Â0r’'ö²…fïÏuùBrß{§PMk#Ôƒ;Eáš·®ñLU Äkæ…¡q`Øƒæwd¯7#¡Ö*îÓ\B'ôÍz¡Ëâ;øÆ`õÉ
ÒıXZĞbŒ.<g•L¥nsâºè¨Ck"7Ú©7P†@íBè Œ^ÇZS»JU¹·dJÇ¤È˜ÕŠ°«Ìßè)¥¦¼É$a—aréŸu¹qU‡ğ —÷°™WÓ@<®\'”7Ç[©™+!RÉ5bXïã úPQ(`Æí¹ü‚¹S^@iHÄé\É“G²*©k\píŒÌopfUŠ÷:Ó”’{t?*VHeçø¢ iÉ÷[Z*µâ‹]_öMKl“[˜¯}p¹Ÿi@Ë¡Â‹pÏzZ´Ê.V÷Y4	 kÅÏ^ïË+‰ã´A’,+™ˆez–(¿™¼Åğ3¢eZMÃÂóÅ·J¨@ú—å‰<ÂUJüùÃ7
¡Æ&ê\Îr–;ïA¥¬tS—ívYy}=*ºô9u¥µÁpA!ò‡Ú‰L¥f¹K‹8aPu«™Ÿµ ôƒB!ô•æ®×ÉúnÓ¿ÉîJƒ•	õÄ°.¿6Tõ-¬ ğHÙßı„,ÕÙÇïL¡Á4„8Gù }¸j—xìV6ÛU—«t‹Zœ>Qh<X±€ÈùšGÎ6€˜~ŸÒ=›QĞsoz²ŸÂ½]À7ş×!nO¨4»äfbáÂ¬ObiDrÕq÷w»ı×?‡ñY‚ k Ö}D#TÛM®¬ä­?ôL¹ª­)m=»0àKWZöÛJ'å¤|…c¨eêÓ«
3#ó•]ëø(ÛÄ7_`È0eÕà‡±X’x†MN¤‰ÅP\Ûa6É·(@ş) HYëı8×gıã ) MK„eŸ¼°%µ*Õ»ˆšÕÒÊáåšÈÚÒª-~oÈ’ÛŞÛ\î…Ô?lÆ1‰V2f.Eİç‡Ec=xĞ;
1Ëâ0)˜UïbæYä/:WŒj#ÃQìÿ¯ç©
¼ì>ñ]ó¾şÔ¾]c8(¸ùİmƒ7(%–ÂÉnœ¾@±!»;a‘Jõ+H*È¢¨‚‘†@-çç(ÙäZ,}©OèÒ~jş°õ£á©Ã¥ˆ­n›•ß
U¡™ĞGAÃoT«CÏû4Ö	t™c"Ã\µƒ8 qÈ­^×%‰ŸD½,‡
ñ~McÄë6|:´åãzµFÛvÅXciue1)A?aÕë;2_I ZqHa#[ƒq,!ò·8¤ü«Q&9ÆÚvqÅ4Üi¶rÂğV	İ'³7n¦wï¢ó3}P>f¾ZúÅûÑ¤u|óš`Ï®@)â¿ÇŠoãQ¢ÕøÆ SÄ0Ê¨yÌ†~:ú°é™WEÀòfi£³Oxtã9.©e]VòØâ‰A8Ä¤…5•+ŞXÓûŒXeÏÏyÑŞf]G–¶¼P¼Ì‚´"l0š†w8`¿ „·³,ˆ¿Ğ‘KÆ1¯+İ%üc¤é§sd öF¡©šïÿ[A…%­óå)Éé&Eîh¡.˜¼1<±ûl=‰êëD31Å½yÅĞ!]„.å!¯‰'_ŒÀ¸˜>Op0q7áç°)2ÇA‘°°Â[	¸cÙà-ÈòÉ7 À'>Iì Åÿ‹7Œ¢	ËHes¼Ì³w÷Î³Â†3ØØAø4<—êàbA{ÉùàU²ø@øâÆUŞ¯şVPñ™IÇX=D%ÇÂÑVË:Á„Ì?âH½%›£ˆŠö=¥­ù´Ÿ£®”ú5”\W§=6kkI¸´¹«ÒÖ—Iğ=¬BÍäØ;~ÑÓøİâ-^ç®¡³}LlB¸DWv69NÙ9éT®$í€=Uı¡’.ÛÒ–îı)ì³N‰l œh%
x2hÎÂÀ,òóû¾éÅ‡1]`'®¬ZåÀ?ÈÇ»÷ıåjT1ÙqngÉsÇª¡ì@b 4'¨`Bë¶Ho™ÄòªËwİi¬Q6OFú– ‡·cô0Ğ2¤=Ô0v­i¶#ãŠÿdKÄÖd ¼—¬
µD2òÅîOÊ¯i hY·ƒQ}Oc‰Håi?û’œUÓf\âMâ&BFÇŠ¸Ÿ…Õ¨?>Xb/~²p¬qº‘)ØR[$üëAyHéQ:<A)ŞóËn·~Ãb-kØ¥çÆ  zGşÈÈD|khšD‚°•PRH§eR±l+RJh4bü…¼w§¹Zv|8yˆ+'@¦!¿ ZİúÇ¢IÿYÆ`'
Í©gB7Ò~Pëã]­	ı é† \aKœºàùôq¼ÒƒzÍ³\ç‰4“ğCÎ˜=º6I<yP…ºjëá|.}ƒUŸbze¼ÑıÙÇİëÚ1Å¤yBŞÏbhşŒ°c¢ó^Ğ=ìp7Ëd(ùOF†ññ¢‚ª!>‰¾†:´+—âiö’óÅx7Dñ?,1ìç¥Ùnä°F«kÑ\¡?³ED-mBÚ1°„ÈÒqe.iâk´€²û&pÂÛß`F8 Ã¼N^¥yì°3›mĞ»Ê³¦Û5!êª,Ò¶‰«e49j^ó”†ãµÌrqYÇ}‚@PSgDp³¸*ÉêyûÍ8Ğœ!?çısbû°Ô6Õ97ü·ê¦Eµ›§q–™‹<:Á	‰+D¥D/§ÿ¹ø$B¾Vz˜rf—ò]›ş…ÑrÇ|©7[ıÛêAÄ#RëDèË‚äå¸ÊjG´¾´­ƒØ¬\M¯bÏ—İEz-t¿‹ºI×®$ƒ	~Òñá 3dÓB´/¨³Š¨ê=-\İiÈÌe™55¤Äâæï¨e&³‚=ÎÚ3oët÷Ç8½5XyqzN;í­éç +*ÜÇ¢‡îêö¾™A_vUë!Úü=lı#óKr[ˆúw_4õ¾¸ªN­g6Ã=|l†*×ÿ^¾ígĞKŒ&V#ÖßŒâ™œ6.ãWA¤şSìÉÔGzãÛ!*-Ó :Y´Dw¢Ôút›ˆó±9o‡ÂéZ¦W5faVCMZ‘2]¿9 I[ë&²wÁµPIsÁSaşbfGFEÚ¤•ó›‘q6U‡ Ø9¹×Ñ|KÌ¼I/ÅD§Ü	Í'1:²í5DXCspJ¶º›œLÛ„übDV7M f‡ı)Ï#ø| ÂÕ:bº7İşzÂ¨ƒÃèĞÄ}ğ‘CÚêŞ-Î% «˜gú–BISu¹Ió6æ³µZåœ\´ò)Óoè2nŒ
~2(¶ Lç…qB§v6QîQ¥³©	}ÅŸàŒ†€±Ì3ø 9»c‚Ü$&o	q»{04Ñ!Ì¼wÜù£°ê´ëÜnJ2Æ%;õôŸÊkğ^Í±a6¼©–ÌÉ«–Ú32Õf+×"Õß%ÂŠ §¨Íà&h°~v*±£¨œ&oĞRóQ²*»Z0¿Ê5³è‚+T,; „&Òp’<GŞ‘¿W™¿A,ÓQGOôöC\im
0/Âe‘70¯ÿiØó¼8£Çbys0Cl+8J»2½å!BÓRö [WX´®ÿ¼ƒÖí—ÍšÎişÿĞYÓ¥ğÏB	ÿa]—„¶#ú_cJJè†_‰«Ï(OSğTRÀîV¡†É²çûÖÙí]íXVgë¹v|‰Áñïæeu‚ıŞÄ+Iüû‚©<ç3fgñáJ5:8ú!zóŒé´—)=]ÉèTIŠd>±ö–:âîÖXóœ‡×ƒ®ÕÛ!ìW÷˜°ürZšÑÆŒöx/-MÅC‚-Áû^=<rßA¾<Ş¨ïªˆ8‹5!²µ¾âpJóœ›ü+¤%…¡ï74:˜(u—íä¿f¹İÄÛì:Û¦‚¶ÏZ,öê¹Fv´å(Z¦{?ƒøQıË\fõ>@³aµÓ g'Uv"bØŒ/Üj”R?i™ëü/±Õ|à‰ÅdìÎˆLB«fcãpÊöM\K{Yª	¹o D° û‘îÜ–®WŸE[v~¸s&L4ÀL|°¬q`;IoÌé'i‡ËÌTPŞå$,qôlLøÔ@â0c!¬vUA-ù6 ¤´]Ú¿Œn¦¹çˆX¨vÎ“MÊ‰ƒ¿/ù·‰ûŒvWµõüG¾ÑKtñ…Ä'r¾=ÏeÅò@J0£ÜÃô0y˜z0Õ…±Ÿ,-¡IQÅvô}âîÖˆF§`©—bA•ïZ¦6B…>§Ê÷ğıœK_=í>g»Z˜,ÛfÃçã®‚tÚôgïÿágtªƒ[©tŞIe¶Ò†Ö @¼
U&Ş>>ÑYüÃÓ‰À#E|Àr½ÂÆª±šåY’^y'ó%˜c‚ËZÈØÎ#3ì¬nÎãƒï¬V Ç›]BB ˆÅ¡´Ê)\xˆd”Çõf	(¤Òü¸4†‚HëíYÁÓı‡Òğ*[øyÏé•$l>BUçÑ°i£Ä=Lªà
òÌSÎ
JP_¢˜>\pÇgìšr*Ñ§6B !¾°G=o1+7±&
Ê±3ö9ÚÕJ™š×Ç‰óõj®y‘;§fÜ÷·IÍéºåH 7	•WÉ€Ï÷éƒ¹ÓÎˆÁ`zc½ll€ä®-IÚ"÷]sÁ¬•—ÏÑ×>©UˆÌbô§ÊåÆ¯³÷Å÷53€qìC¬5áÔjÜzÉÀá'ÆÕ|LÃäû³OÕ³øÿÍËU¼RÚ¹Øğ¼Î\¶™ZNf€¾ÿ©{Ü›„ÎwhıéÒ·ÒØ)&†£?D#}Rbÿ'Ïšêo¥-{àş_£ëºU=£äÿy…ÑíÖ°TKs¥İêµü‚Ìã†ÜÊ¬*väÄİ[şO´ÙCu?Eùr¥j;’Í-è‹ÿ„Û•7NG­DIZëJ<8‘Ù±åÛ,¤)rk¥æTï†ñ*!³*šußgˆxİÏD‹qw3NyÖ+ŠÀ½CR‘M% gx§á¢VvR”¨øzÉÀ³‘h×.­küCeùo”Û& Qv–Ğ†ê6I¦ó8’-#äÿ@BWN¿Ôg8Å÷”Á>İkÜCö°œ_ÛO‘p‚£Æ\Ãÿo€mzc/!#ÂÕ.Îém”ã!¼¤¹x†ş‡d{ê1¥Ñ µÉ[-2Ã”@¥ Óø†^1Ì[¬ÂèÏº²ouÃØ=ÁBøv‰°³Îç=-‡>‘ğ'NHWâ)ÅÍÇKŒLÍgÉ¥©`n¦Ü‹˜ğiåfÆååW¸Lÿbñ)Ü[!‹,1†M@Ñ,i©Z©'<üFÓB*WC<y>˜¥(n¸/M\×ñUñİÁ/ã"¶ä¢xõİx`º’ıj*©F¬è‚–J)T¶v™H·‰"ôûˆ(…]ÓpºÌ ¤oøÆ)Ø<"¡ WMg¯óyÖUH¦€o9Á*|B·V3<;{àÍ‰ˆŸ"„n-ñZÜ¦8Á$|LXkq«k®­vØKÏš*•´ô7)H}Ç7¯é|b°·¢ lGf±Ğ,ÑÙ"”k¹'t}=Á£_†¿ø÷¦şœíó%4x'&Eí„æii«âR3ØK‡şö"n†Ë„`b&á%Pj@(3aûüXóŒ¨ï‰DzŠ¹`;b¨7Ê•xË”
Ò‚á< yößJwö,«ª„•>òÁÛşôVÁõÍ‹<5™¢¬¶øwXåäñÛ€İkÊÙØcƒ^M!×ç¿Ì¿V0Åó¼„¥ª›®¢^>@D P=Ší¼õĞ&}2U¦E%éÅöQ];kçº¯<ü,Ö¼.¡Ói½Ëğ½e(óˆs÷„;Ò~!h™á’¨ h2Ä3ÒÕÔ§º„ô¿ekò+ï€Åd`é‹Õø³Áv¼	‰+«N˜‡™9Ïvîè0·¬,/AÂYó“7=2ƒºı7gÜÇØo:ßš=Nm×üÆ†š_©"º¾aNcS›)r¹a©’Ë_ºñ£ŸYcrY
‘¢0ˆ¼Íÿ±f‚üb'cM‚íá Õ1Ì{®¡¾rGU¶=iƒ¿ü;O'pC—®[¨Œ¸–¶‹‘ˆÛ¼eqÃå-ÎAcçäûo­³¨ìÑ:¥\ #Ì bB~úlZhûz:IX üK/nKpĞ´rK—ÅåÛÿl/]!uXö ;3—ÙA%æ“YÇH-çIôTq‡J5”cœh1C÷çÇ%’d8ÊÅÃvÕ¬¼›ğÕ³î ÙÎrØ·ëÆ½´ˆñ°Å_ .CBı9Oğ,>º:MêÔÑ¶Ğú#ZW6õ¬şLEùñP¬ô8TŸÃÆÙşvªíxmç×óôw¥gö›òÏĞ}öJwf7½ õ˜q¨mv¥uåü/j7¹:dÑË>,nÈY“Î”bAñû¸ñ© &dTúïêÉåPÙwÚ±Ê“ŞnR +ºcl÷Õ°­Ø(|õ3$çš)g©áË`¸cšy›j“7ÉÀ.zÿcuË#™|ûªŠ`éOŞ SÁĞU*N2|ID—¤ÍiÛ1õá¶6×ü:¥µ·g{N)–tˆs½ÌiA¿ÁröO©†l Æò)‹¡
t¹Eª)Ó‚"âoEéˆŒ«ÀØÙ”¼—A\ç'
·‹ÓÎmˆ%à¤„ûè\›°¼“æ>ë–qĞÅoÌ'ÃÊK3É96‡ÅéÒˆÅn¬¼O@tÜèİÇP¤ä›FmÎ‚ZlİÙÅdc	ñ 9²/õS#…+ù© Ğ6d4Ò±¬’èKşÂ¿¢ÊšìÒGJÂDİKM§R}a›„šæœxÂ¬-üøüS“tÂLKdù¤b6¯°Z…9ÙOû7”-øx.şÔšßø©^Ôà"ïÆ>6#6©a/m‡j[UÙ×°¬~\›’2”›ƒĞ8ÂlyÖ»~ÔµÙJgG¡­a:sÇœdƒŸ£ä{ñ°ºÊÙ«çÌX÷´DP‚E‹Š$çßò5ñÙq¤PPß6zSv¯B^qó¤%Ë¢²¿1?‰Ibr¸GœöÖ	{G¡İÊÃ­ñôÇĞı!É¿»À|:úeopçbÇ‘†ò¨Fbûªº¢á§¤¬-+³C³)[½Ãeé‡³§	Eê8Ç1¥zğĞqÅaH–M¨‘²ùªÊ½Fù
è³ÕéŠ7¬x¹£Dœ²€3LÇwğqT7PXËïW:1OQ…äb@Õî«(«XTIñ³Œ5¡Üï‡òknEìOŸÀ*[ŒP²Å'â­œ8ŸP9ÑõåÕìåJ]-ŠË{Ç©é²:{YŸÍˆğs‰5S YH°ßÚâİ^Pj@àÓ3.‡Èp® y¤ÌX+oiİP‚¼³U’TÊ#8Û]	:À"q½‡Â³”÷w5©•ŞÕŞR´‘ËÇ İFA:¢o¿GV©ÚÅÆ‹én‡¢BWÇTÅ4 JÄä÷ßTBdó"£#×ÑŒ§ÕT¡«M¬\£æ’*ájL›Tb­X*  õa0÷97$'”DÍñ)CÜ/m?N‰ÌL--î„ºQT^ÌŸ[4€zİş!íqBÿÚOìUptÄ5ê¨j7ùí–·r¯k‚u=Y€ Æ%µr°zøi˜pcÊ¬d®˜»‚ä´­<ráîK.h'(ş7ÕÌkA,`8¸à1lzœµ§2’=—L*iJ¶±)øÔ&‰
H%ÿÅkvĞİ`ëØiªuÇO*»Å
s—1áx°²§‹œrHê,|ûz üœStxq4ò[²”Dïpz«fß§Ÿº™JL«g»vÈíÅJm’óÀ™À*Øn½8ÿiœ]ü!¹slÄ†bå5ÓèPX²ÙïP}Ë3öX¶­&ß½ì`ıÕò¶áéâ|;R¹ÁûÇ†7±Ûóé#ÿ_Xº]ñÓÕ1ÿÉq¬IKBTAŞÓóÚY¼-Û)€$÷VáKìUƒ†ÙVç¨;şP7ÒmÁS¾~·Ì•œÌE¸V‚55ãu;’râKA}ƒÿ)¶©ÂU´P6AÈÛÃPÍ/+XVû!h6{¢¶İÕMg3ˆÓf5ÿ<	£'V»ô;Ÿû‚‚¾Ò`.½@*T…Êì&LÄ8Z &Wà®”¿”Ü”ŠC';WRgÈXz¡§võ¶ck¤èµö…¯ÜçòºW©–"wF+Âô†j5uÂ‘üR†½§â™-š›×¦)z1–Ãt4å!¹•#³ ®!q(ia­#?QÌäéÔ4Á‡í¶Ñ…åßLr¬—3ÑÆ[¹ºĞ˜Qó^ò7±W~S
ïÊ>	/Ù†mØÌKÅÂŸ\±û{J@¾RÌÎóšÔLtdYº!M}ì-ƒ«° B&Ä;-VÂ´ŸòxşœpØé§.ü³<Õ`x!´—ØÕÍâñ~¸D.2ÙØì	ĞáónrÍx•ûËşU”á¥€‹ÁLOTìqÙÉ5j·zÇæ+¨½Æ|şÉZÂ­ÀÜkÆÔ¨[Rú”HS+/Ú¡4ì$š(¬Tà]÷Ù„a•¿L 0¾ŠŞÒuT1¦Á‡Ğù« »ƒå &2Ğ+:¡o bñÑZ6£Úœ¡l$cÀßÚ·FS1y’õëVm|qñ0±~]CßË½µ©`ôd‘’ícÔ¸˜ni{AVñ¿„;mï«Ã+g¢#®,}î`‡H³GUmŠ©-­)şG%#oŸóYùdû&,8W÷Ô¿aOÛ
kˆÎ;ºÆ·gõµp¸Ñ 	"¢úàï®y÷ÖVäk²œêcÕ`ãŞ»Ö7%ç“É~ñğ…]g`€ìJ)#Ñ%„´CŸÊ-¡X´m!¾«t8"dÆÇÀÎÎ$¸Gğı(Å’%ˆÜh´ÄÂnÕ“à+Ğ1Ó ©W¿‡S@¸ğ”oà•ß«±@	C2=? |!É÷¥wñ+˜pñæÔ¿GıRÚZÒÊ4WO°ë%èÅ4¿úş0¾QÍ4ÔÛ÷"†;ÖO²İŒi´&‚ˆ9§¯Ïø[ê+Ÿ¦«¡Ì{¤(]ßùIªÉ‹;Õ	ØÙTAn)8k¶Tƒå/Ö{	!ViÂ#ÙÊâá`+ŞBsUÄ`ëæ­¼•ßÀÉwƒ¦½f˜å?V«CìI-Ö
“Fš!™€µèì¡¬)ş‹«‘S”ª8l9İ{V¯Gœ³"·.kêé@:'¤ÂØT^¯û5^1öSƒ¶h¦´p drXP»!TTÁ¥eåôOç<¯Ÿ:˜$™z6Ö{M¾¿UTÛr™È†ÙìùÇµ
k ğÅ•ñ2ø\]YI?2!¼×°,Îó4êÄ@!Ç€oe¢ÈU=O8ÈvÑ‡a¦æX9}HAN+
P¤/‰µ~y¦¸ô9åiÓy83·—Èœæ˜zlM^ZM+®ê2WoÌÅæ¦7DÇßKRîŸ`ñxşŠÇ(lºeúÿî±¶—KóITW~ulBáFcGšªó$ ½ä)_¡BÒ»Ó…%| šı"Á¤ˆŒÂ˜!_ÙšËÜo1ùª¨C@TÂP8şü¤½@ÀÖ $1®‰>¦½ ½‘§›-°UÔ%‹Ì=Ú|q¡ÓÚ	+±’Y±*™ëBîD–÷K$dåª2UŞñ7t'	‹šÛ¡ÃcŒı;’ÒòJ¡è8ÿŒ™,ĞŞ \X]@|e¦/ûºäõ˜C›ªv‡•Š?Ôª	»i… BŠƒ×·Ë‡’ñÄÍ¿Q¢FÿçşÀò  Ê{#2è¸ ¨³€À’jm±Ägû    YZ