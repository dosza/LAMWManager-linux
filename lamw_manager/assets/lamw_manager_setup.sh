#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3138486767"
MD5="07923084b2085b024760dbba5d74e518"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23324"
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
	echo Date of packaging: Wed Jul 28 13:50:52 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿZÚ] ¼}•À1Dd]‡Á›PætİD÷¹û¦ß0Ë2-ñƒ=-“öÆÆ3ïBø­z·á ‡f…ŠGyµ&Œ«ëåà”Qˆ‚Áê›°–v]6)¿Ú‰Ã†Gt«Š›°\Br²[…”PÇfJ€qê€©°Ù|1ğšE3hzmı –"ºÈ]†9™Ô~^_İ”ãó¨Õq>ÓîrçSØÛ¦”£_¼k•éDq¶	İ,gU¹' …[ bÂ@?¦´÷“Ù¦Ş‰{bj9u?¬_OÛƒ6§gßl5î1D'¦àNê´¯míÃÀÈ
Ì=åb2ÀCU`"ÈD©Ğ¿Öi¿W¸şãZ‚©âsšÀ>jR›¨.qb—JşKh`—+êé`UÇš&Äé•;2{$sÊUĞd@7À>	­ØÂ‰DW/Nu:Ót•”’£üHôò»NÌù”ÌU[ÒĞ¡”Ì+ZÄ‹GTÅ(*ğ—bò8½oâJ[z¢ò<¸´z=b‚¡r!ôîÔ×’n(:éL}/W†ÅÃ„4¶×c`1>RÍÜMzÛWÇÇ²,5MÜOm*1»É©}Pšl×u]Á}›†¾,şJuKZ}Ï$‹ÓÌäÎO5€Rº&‡{>£û8ïŞé :ÉÈ¶Ÿ]æ=víM¶9³î‹òxõnf‹	aW´¿ÊÏbq¨RşØlõ^©lœ˜òô³¤Ğ°Ñr„–ÿƒ!‹FAÜP¢WÑé…íUÉ}ÇÜë¿HÊ¨kXd˜Uv ñâ1…ÕÙÕËĞ<]J ç™ì+9‹ÏYò”ÄtñDrj£
Ü¹zún)Ü¢x‡¤Œ§ËV/•ıxı‹w„"âïÀYîœuÌ_*xo	…¯·*ô¯hV€!Ìáõ |ëµtkÎ˜ƒAj±é‹ÿÅş)ş®~îW=+>\YWµpb´÷$à1L¡îE°5…ù wåœa:Ä>e)ÄO´lÖR!Î¶'8Üı<‹&¬‚ ı³RŞÌÃ§à*$bƒâ'İ“\Z•@íü±l	ÙF_/‰~ª¶Àƒ2Ñ8äó69n–;äİÔÓ¹-ÎÅ˜×s5È'É…ÍÛ6è(©îo@†Îc.ÿŸ:xŸ–f =Í	fÒı¸PŸã7GN¾ª<Æ	ñ¬¬éW‰M*AàºòªÎépU²‹­i3™ƒ`aÓ#RŞ }Âmbb‚rf	ç\“÷	ú7¢¸l¾ Á„Kqè†\òC£U¼Ğw1®\ğT+æš^ûÚDÃ06.nËD€ÆÙ«"H–1£U3ÿÉ§°Ï+:–÷}»àO®tæÇ]²Qò—U'"U[%mØ•á¶°a›¯+}iı¤yéÕ»§—d©w˜‘6è3‰W¥Šs'DSÖ 3x£¡¦¯*'©Ş‰šû6İ¦0Ï˜¸ÚJ`*Qm”N#’Ùô¨í8.†k¡3€Ç¨oHG†šğ™zNQŒZıæÔN·k˜äuÔAÍµ4ÑåyÅßÕ.“›|kÊÔÀÛˆ–d¸­„.¾´Ñ7ƒåICFşÆ÷Ã|Ü«è¶Lyò'‰¯\^P£× ®±œ{:ôÌIHK÷#n
ÙwW[âŠ`±dİ‡kîâòSkõšX\n,Ii÷GPâõEQç9r+Õ~oo¾ğ³§£q|_ÍM7e­Äæ¹°]îÉ—[Ú÷¤´Ylğ³ŸI¯×Á2{à¥[“Ú­ã‘üù"R¹&Cäús"ñyå7‡0(ô}3ºÏÊ¯óNÇªèIìéÅ•Ägh”(¥wèø%îe„ç¯‹j¨¥yH[æ	7ÍsÅ¸¥Â›;»@ÉXi`®Ç%—ú0ícËsë"²ìmìµTöÒ,ØçyºûˆÑ3®dØêàK6Æû¨¹QÇ,l*N…mø 	Yê‘w®Ùïéåiøs˜Újà¸8İ) 4lrãÙƒê’d‘T@
¶°:ø•×ìÉÊ ó²{*#X¨‘ïBl=„XxS¡\şù®R6¿ì3ıÇ´‰‰""¶óQÒŠ1lˆÛEÀ˜	»¾ãm;.)Á û°ıÔeÎÔ€`SĞ:k˜ãşÈXPtğ¯”m€–XÙXˆª†˜ø# A2ã/¡à÷¿/e¡éªyd†ÀÀ¤“(¼"‰°>È¡ÔÌğÚk·/©FzÈ¹ş$–ÿÂëqï¿•
’)lí=Äœ¡|#c£¼YÄ½mŞ:
[nı¢$}Îõ“‡Ì‚G´¾üx4÷—ËœO—Ú‰îgŠâø^œ	ø”º‘£ÜÑÈèfö§6W1)+°öà	§üFF²ÍRR¯({Ü·ç”Âÿ«ooöæä&–cd´ßş€d8Ë¸jªG›’V‹ıÌ]<m,gÒÕSìˆ¤Ôrô
Jö+I©øyêhé&Y%íZ›Å²ÉĞÆîcûŞX=¯8¦­€"–29\»O/ğ¹ÆÓ™“uDBC&’>SWE¶¡ºIqï
‚ïTØ›ÊœU›äSÌßGmÃ>18áZ»ô«ÎØoÜAÜœyKˆäbŒC÷é±«ê]F©Gß?øß«™J­y§º{GÿfÚÊˆ4~y“'·)hß`¶%q—S^^QÄ‹]’ä³–Ë‹ue–šÏ°¥"eOÑÕÂ-EDAùÊm)½#™Û'ãdìØAQà¦6Ãñ“öˆ¯,n^•„Y8z[“>T\¤Ÿ.°ãÉ¬mK]–æDªCª´Á*å% @vl–y“¾Öî–Bà»¹uo|4?c:Ö#ûÔŸ@E+&%×]Gş<GÏ	¼ş°¡z»uyı*[¼åÑe \2¼¤IÏ³Ô¡ĞàBKÎ~àìrÌ$=mÊ"Í¸u2*Ló—Um`Ù»NÓ<Ô‘ı8··®!8åÅ9pb©Dó‰7ßOµêÔCı;&L³·0hÒ?>å/#Gı³O‚ñ¯®hLì;ğZ>^ñğqk¾}s½tVÎ¡¦än˜ö†}5:¢ğ•ĞÑ¹f‡Q$æG¥ ÓO­LÇÙâš=·ğLõ>ğºíaµG6$…Ş	v{·ˆL†'C¢£Ã¨ñ9ØxAA¶}¼/Ä5ùñá`™›ô!oïı|)t¤š˜Z˜‡ÖºÙÙÂfş·0õ*’ü¶÷:”ÊD¬TAßnøÙï~—UıÇ©?- EÀ(RÃû4¿¿j=K9
¨Ô”ûV½ëb\™‹MuC¦.1Y#y³@¯±	Út®ƒˆËŠ^a±®ø	’Ö¹=Z¶8r@Xë¡…F0¶)nH¸M…e‰­9Ôg³'Œ…šüàggìşö¢w3®YÇ÷e¶Üq¯;à¹¶zi(0„½ùó´ó,gœ±’[na¢­OİQÕ•çŠ•@–k{ÁÃO6Ü-c­‘¹‚BÎ	S…µbÀ?]ä"ÑÍpÿ¤#‰8ùV4dâ“ø­Èaê.¤qğj#<ŒbÔ%o+„åOÎtf»áÈ"µºĞÅŞæsÕ·P…ŸÔ´ßŞÜ¹p­ÎóşÆÁdYsÖn”„bîâ¡í…*®êëêÙgQf
"š’ëßì%^>Á±}Ocšsä`wÖ`¡f¢†‘‰ùFPP|·Œ®ã]÷Š­<è½r‘Ûh˜˜ƒŠ¿ÉüøSE5òkÔ·¯áw›ù%QÅÎlAN‚v;¤7MTì¢g Q"ÓPtæäÃ­çbìàŞ+zĞ5-pµ2hø¼Êf.…/š†ªÃŒæöJâ²A7™ñÉ—nzmuW^ç@ÃçB†|5ôziLÊæX&QaªåÄÛt¢-,5¡U¼‡^@££‚i*#¬ÿÿ[.4±pIh!7ÜĞıÉ2“M'kß*İÎÔ‡ëú;»°áQQ’ğ_õiÍŞ¶£ÈâˆD8É,óA´ÿÀv×‹L»\ügùFu¨ÑiçRè
,Ì`¾f‹H–:qË]ô®(UÁõg3DU2vï/ç–D/ªl*(uC£ı›ĞrÖ¿óiR%IËS¬!{ª/¿üî–él){ØLÉo‘¡¥E	­Æ+Í‰İdó*>`ÙF”!Å…[úĞãæB÷JDÂ½¾¼ƒƒ,³ÙD$÷²^Â€=`ÆÈ0°A(ÔàÈãØ§® ¸®”Æ¿:v‰K|œvU`Ô·Xzh0q>ÕåŸ¸Ñ#z€èè0 mF|úµZÿñ£Ïk¦	ovı)òá;_xG` ßı@³³Yö›po–'Öâ¤Ò¾î‹MêBT”ë|ÔÖîFö*Gñ£~JàÊÓŞá‹Y¶WVåĞ©Êç²xA4¾c±RX©€ÛQT]DbøKl9ò§J³ËDig®$¶5pëëè”©"iI"{UÈÅe8ûº·šŸ¢ÜëæJò¥”Wär*•s*Ùà>ÃƒqîÚ±pùOä]ó†xôn>ÆëG‘§š)9>•õ^ñoŠî¸Ën…\¸åï¨4ß·°9ı¬¦±a9Ÿ·!U%Ù­ §èL®ÇŞG1„øâçC÷Õ`?aSvırú)>f|òıyîëœØï€hşÚàOàÍ°w#"¢ ßÎñã
SÁçL£–0Êõ
w»_5Ç9=×ƒÔÉ$Od™E_kœ-—õÔ‘ZhÖ¾Ÿ7b>`®¦¶ÌzTKu¹,¡][U`%…‘|¿<Ñ¯¤ëŒ8fš¬%¡lä\1L–GĞ3¦ÖÏ	êÊ¯2‰j Tê\²’æ›ó„–]©d"ÖõªÚìÙùÌøìõ(İöZæ|7X*I%/{r©¦ã ôx†èøøaÿ
ès†P)ávpSGœû'áı)ë19ã¢œ©S‚©ƒófä>Ç\0}ŞÑXÉÅ=@	mH8€d/Ô #©az§0§Í>ó"Lš}„8‘ƒ0ä—+nÀî}*Ğ ûª°T^6!LkÓHa÷½Ù­¶ÆÊDjı¤„i¬‰C#3Ñ´ã-R¯µ,Ê¯Î‹ãÍ­‘/¨/»Ïf5šÅ’6<µ'[ÌixSŸ¢~Ñ[œç6$ó˜€¤b§•0MÂ'Åe;‰QÍšáôxJ{Y3³|gÄrˆ²­ŠÿT£ù‘AÚ§Ç`Ş[Ú°ÆÆ¾›!êR+êŠ|<lÇÅäİ$Q{½ÖØ·/r@À÷CÂÂÃX‹.	^ÿ@îÃĞº|D/VtYöuãÔ›$zÌP6DU¥;¨ã²PŸ_İo^–Øù¯ şŸA°°uÎs‡ {şà¹Uº¿‡;«èü›®%fg>W~éä[\sèrJJáñÜk‚] Uc;ÈŞÏà8úÃ hèJÁã¢ÖÅÄ¯ó	N‡†áP¬7ş×ÒÔÛ8ñ½W¹ë¯“®Ã‚?şDÖ*dæ6ÈÁë”–»peïÖõuM¹éĞõ}ÙùßÒ¦˜pÛ½/.­;Eo£/”ı`p¿ÛÉ{]ãŒÿ|0uñ·&ğ¶EPí%Q^[é×Y:g”UŸZËôo[è5©¾*Úd8º†n®gòX.8²’¶ÂÈ¹M‡,”KåúRğ¨f¨“v
sqTÉ—ç½µ:¦ âŸJ$i´ ´Ü²'|´Æƒ±ªL†”Ïdü&7&¦õŞ€Ñj,¿·Lø‡àÖÜKƒ³Ù_fÌ%÷,`Ç-´¶—ÆÑ4W•êÅ‹|8”Ñ¿w.ŞÅ°0¶8¸ZObdÅ)'³r†Üß‚ªTÆÕÛQ¡p±„OëĞ/
^=q5¢Vç¤;šDFM†Î«X›X—Â»6€‘QÚyÂSOøZ©Ÿ´³ 7ü‰‡KoI™ñÍE†J»-”
>M~YF—uİSë`…ÒÅI Ü·lt^ª?Ñ?,{¢&´3É·+±	÷’_:yëFUm‡>áÏÒ“¨r¨
öÑäe{¯FYY1æÒÍ‡2¬ˆ—¾-w6jSi<?¶b‘M¯òÖ#Û>ÑjO˜¾ÒbuØ§Ï€xÇ
‘]aN\.Ñ®b7&¹p¦e©ëĞy6ë_îÖº‰ö”Æ!&&»^rÏàƒhÖ_
Í¡`ëú—†k~<L¦XÑ0¤B{ø Ó÷Çô„7±Ô½å
4Æ3?ømËºº7D_Ù«÷÷iàÜ8C^Œms§«Šª„ıTº%|şf»ƒØ€@ÌøŒCÌ_|€¬rFßYÕ/ØšúoLtù&4·<à«_^8JøÚ¥œQğ¶x|,°fs;g]9Yêû®åÎè¨Ö&’7*$…Ÿ¨
ùd,yáÔÆ)›t"$îÃçÕd©š§f¦‡wX-ÚW#fW¢Ó`ÖÔDõ`òš@ÍÂ…õt]8©,c*— ½a~‹ğ¼N
]ŞÜıuU}Ã¯·z,}Û¢cteªK±¸ª§;gR¶º†nÊ#jôOD‘£‘¥k'ìáj¶ä‰  ¼«'É¯ûwñ íï©Üÿ‡æ"Ò^CW#Mn‚¸ÑxÉ,ê#g£›ÇÑìğåERôn5ysVÙv$^´mÃØ€¡Ï*¶¦sP¤¹ì¾'„aCÊ’‰Ì&&âà	ş²öê»ûˆ¡©ßoîĞ`SÒ`µ|>S×&ºBt%¦×q *ºŒ¢`¿°õ
îmàÃ™ãgû±÷ù8V8´É«\FuãÃåhİ
uK·Kä5ÊìŞCô.÷2×Ê§NÏşcUÄ„M-;¥i~¶˜n]ÆaÇşÔ·Ç*õšç-¾P9T•módÓãw¹İ~¹1˜ {û³±ÂTƒií!Y=ã(»ñ´!`s# ÍfäcÍ÷«ÑÈÑä+Şëüa(Ü|ú{îéç8¯û¾ş?Üºn:¨tt>æ¯ÓàA—Öî<FlÆQ^î”çÑˆ.Íâ*Y;p2İØ(Ctş­VQá2ıÉD¯˜ã2q	gÎÈE
5ê!¡±«,÷æÆ
=`:k:Ê©°Ïşúƒåß¬Š²ñüÉ|O†ËÓ#Ô(É9Ğ0%o*Òt¼¥´EÙGX“„ŞsrH€¼[ÄÊ‰‹Ê5…Em˜6#V´äfÓ¸¸“ºFšŠ,e}š¦ğÒåp&ª8QXáÔÆÓ-²ŸÈÚ¬î³Ôç€ˆûÔ…ÅvúñÂ°‡m[kü~Ûx³XxBí¬b¥ĞHkrt™)£ÕÌŸº@øõ÷ÁÌÜp±q»¿úÍzüáœms|f=ÏèrÊÙbQaºW~vcÉŸ×páSZ„a+:¼ÓgîÏmAÃ	TĞ¾©?İvÓRk˜`Ş¯kº¶«FP‚œ`5ocÂEuEÌ|ö–I”†u¼¸­ïGÑ“ìpãP• ŒhĞKĞ}ˆwô€X;Jä<°VƒaÚŠ¨ÛåÎ·-p³î<×¾^7—‡TæßÃåğD;›îÈqa?şU¢¢VµÖcˆEæ)TÀÒ{™ßİLLs}?5)’¦’D%0šo¢0 H15Wè‹ßœ¢˜AUW^är“Eîz­õİ…B:x½7aU®|;ÓIŞûÜÙøxÃ>"HÉ5¼jİ|S¾…X£qĞiF“—ñˆlƒ£Û†1)Y¡›«‰Şlğ¦aØõïk»“f•]>L›+Ä>^€ Ö.T?©ş­Ô‰{‚L2^ ¹İ}N¤yÀclŠGî†âSú4¯œ®|N«$ìNıçƒÜ£°7ˆÓéÃJäú½Bç	$ÖxóVÃ?N[ î7ïÏåˆ{§ÿ\¶J,ªğˆÚq³åøŸ2ñªE>å‹†âÔğÎÉŞ|{f>^8ÎGˆ¹lŒ}°¹¿gx.vŒQ)ËØêŸõ‚öŸye&‹³„é©ÛÊ¥$*†:wÒRœ¼¯{m<åYLEçnátıR«ÆÇÃĞµ!C¨ŒÑ½ã?—¢8líô&ëf_Tû	«~FùÉüU·—-,Bv‹¡–Ÿş(õ8yp®!¿ÔàTßÉıx°`8#ä%Ìó RÂ<|ê´üè*1«	{¶íÕ­ ”»[Údà>twÕ¯»¯œ¨‘0-Y²:ù^“¹·]Üí‡©Úâ†½Ûù†ñÁ{[r²Ã+éı¡œyg2Ç/3;†*‹U‹+Ä^~-ˆJ¹ğç…œáó;Q:\¿¿"{#û‰wú_‹„¯šã[·)ñè‰Ç>¼¼]Ñ¬…²…sñÊÄ†,;™I‡ÄĞ ÊHD]këĞNàï¡xu—ZİkYˆ–ªK¸AŸ*vıÍRõ¹;›ÌUïÒ<]ncù±.Q.ì›Yìâ§›aÁÀ€ñÆÓsı„da>
máĞá
v–üÇ[“ìŞóV°Š‹ë{#ı¡pM{ë.»xÆà[8Ù	’6eXDyryoåjû&NğA&(/‡›pùxˆ¾ÔáqŸàí¹Ào“Pd[‚gÖyéÎè!—4J5«ªy&¸“©I¡;G(RÊUŞæ^EiKô‰7G}<ÓbmH·XÓÈ3p£EÕ„‘><³õeŠÛI·¡ÊÜ(Óná}rïdôİ0w$©(ZVÑ—]ñ¨á9*œ >ox)k_AÄÊ-ªcöJ™TLÇU±§7gbJ;şÕéŞÚGó NWâ‘#Ó–£”˜(¿5.B}œonÑ­‚‡d(„ùô±L µâ¿kÆE±Ñ™ÍŸÔÈıjÿÏÊQO6+F:,µ©Â›¡–j®Û‘a^“ošÙ:BcE ‹®™Ø9w ÂxË×¯a+=ğ§¯?3€ƒË(@'Ç|5ÒÃ‰çÇñÓ
"©H™ÎçLÁ©ÌËsê(NI­Å”+8—+C€NF×(Q~E³@nê›ßé. ?Š
"Óò%²Ş8Œ!I™Ô@Õ=÷’ƒ V¸´Àí*òëŠ]îp Ç)ígAShUzĞÓY:º'5%Aù—Ppbç‰ÙXoGM¾RyşøÄüók\æìö¡.% b›Šë%8ªÍdşc‚ŒÑŒ
äºİõjä‹Ñ›nÿ¾òF1<Éš˜º6µd×–xMù¯}(Ç´‰¢Â¡4ªG%f¤<…1ôà=Û?|9°‹ŞT?[œaŒ‡­¯ty‡ ö-«ÍA•Í†tİñšª?¿d°©ÏèP¦n‚â_ö«*h›eécÂpÅW&pv±:á/âT:Åûa€y“ëT¤1¿îAªä”æŠÅ’í²çÔ7ä9Ó ²µ6ÃÜAşˆÑ1^t„1DÍ§‚¦WÍÇ7¯U—ZğïÜXy Ì}Ãr­ã%\Ë[úˆ½Å7Î‹ˆA ŠÂ&¯<åÑHtşï?0»úÙQ©møÜØdzİX¢˜nS
‚E
ZKéûœå<¾ÿøÏØÊû9Aşş*Hå¤ZFêÁ,xÀîA6µ rÉ(”í_N.MNçPJY)îl37jÜ^òáÏt!Ô£›µ2f
ú˜‘9´×Ã•J¸ùÑñ3È#zıôİĞÆ„XXŒÈ¨éxåÓó|ÿ¢Èyµaoh‹py<¸«¬-RÛìŸy@P³—ÎtouSÂ
¯÷èoåö`§LŠñ0: +æZ·`æ§-ş¥ÿ¡zW~µÖSwÎö6bª¢N©$Hj¢ß£©ânIÉ–şµ¶Ú‰„V¦h\Ù¦çŞœu¶`M3µ¢¿LÊl,ëò¥y[ä3âˆ¥¾juhağµFŸ©ÈWq_uyu%€’V9Ò:ÌX–sy§_^ãø	óGUàl.ê¬†®©Tæ²®kş)|¬B³˜Ú3!÷C a´ÂÁ1*Œbfš®ÇR¡<@}ÖÒğØË`„éİe•"O=¿{ĞÏ˜!Òëƒ}mÆ¶Ù<&ÜÅwB´ÿşı6BÚ_†Ï’ı¦Ä9z"_â/ù¹oN”Äğè÷åR¼V(ä-„ø×ğ©€â¹§*“ÏıQàätü{ØM»ö¼›ö/ÁÏòqÏÂ00XüÚìB=ä?pø©Ş®£ş)ŸU?›˜Ngwb8»1+¹W;„9zÄ;ëTW$ó\ºQ÷D«Ü$x+®ôz2Ø×Lµüê ÿ~?/•8ı‰o-úı5r»Óˆ¤õ³ Ókyìx¢PƒVQgç‘©óü)j”Â¬ÅâOà
Zß?zEP!S2G•òš%ÓM±à¿:Îàr7™Èwä&Ùô}åÓü¤hÛzZ§xÙ7“3.(Í>½‚:C ß[”U>”Ší]Èl‘åõqË¦5¬agUÀ¶ıî3[ƒ]áB9â¦$Ôøµ\¼ë;É£#-Et%)æéƒmâÃšƒÒ¥n$¢»yØ ˜m#U«Ø×Ö£Ôòõu¡ßÃÆ Ø/—­Ùİ;S«®åÊü”BÑuŒ5ôÜÿ¨@‹ƒ­Ìâğ{Ùıbìø<Ş’-FXö>aˆ”àa”fı	7½¸²ï-æƒ8*ñÚyy úÀ6©5d°=Ÿ|ÑR rO+¢ü']Í³æü*‹7ƒğkùbj-9_&ÖÍ~¾©4#”ï*·İúA}wÇ\eZ9}Æ­ñtšMà¨_Î¼„înm››˜r*mm&Ç/:‘€òàLóÕ.R*¡î§C°¡’e(‡»
SŒH„Å¦ü;IŠÀ×YUS©Xg%Õ2ª"·f8#¼¦#1ÈâwÆÖ‚8xßİ(S‘‡lÜ´JË'Ãâ~Â<O”XÓ|è…$Üpôa;3]0¸5A Å(Ì5¹ ÉŠ} œŸğæ`ÌfRNnîšx!£HPm!ô…JÄ/Bk–Å¤ÎÕ§˜ ıëé 9«fE$Î*=qR‡à³ĞuŒu†Ãû¾GEy´P¯ìU/­cÓ+3 ²ş.VÀó;]ªÉÈlA[İ¿¥`m9òc*†óÈŸ´ÒKµçZ‹í³øQ.P;Ô“k™jË
øˆkã-ıu|_ŠOµAau-ıŞ¹°QT0i$óm7•»Fµ™lgv+·Mx3é)ãyÊÑwÕ0%Ø$C ñxƒ…ï&ã+ö¸‚ãb+ÿò‚O°»ÅaMÚT2åY‰á&q%8ÒÚ‘Ğ]¯3„+UM0øç(¤ãv!­[ŞàîO@Pó3+O	×–±×„İÁ{;”Vl"‡bœpŸà{İIİe€
‘ò›2Ô™W…â¶ŸºñÑ˜5cÒ·÷8±c9‘z†›X i±ÄÂä¼sßrÜ±º«GNc£øt„v g” Ò|fÍ(Ù *éÄ›Ü!æ¬‡îıœAG‘õ?òIZAªF“rªU7¤îV.ø‰Zçr±\Ïé[ò…óUu’EÉİSz§Sù°ìJ®åÎæíl¤Ò³Ê¢¦Z'g\‚’}úLí9‘ÊÁsÆºÿZˆ÷%.—_2i¡j­
İÚ8ºZÙ*ñÿDâÛwö‹3·Ó%`¤O¨ĞºŸWÓ,>JœUT¯>³õUW¯±¹Ÿ…îè2-ƒÎ°ìœ:éq8
#ñÓzº.§i—c¾«O`š+h&CŒY±òÉ%şÉ&znVõÌË"Òe(-&KòAÏâ²ÂÕuİˆwğ H¯ôÅÙ:RœÑ¤øûá&(©„CÄHÈ«_&.²6{ã!jÍËf/”‹§ÿzú…Ç=Rr2©EbïëTBe6¨c’3û³ôc…èŸÃÈšïİsÆpDîlgŸ¼Ù·ïƒµ=W? ¿ ëb¨Q˜gÛãvçzsi	¼¿ÓXÙÔtK™g
 }'ˆG¥¾MëG3/)CW,„æè+Ü+ıÔk˜©zvÂªˆ¿ÃÆõœ|iéw¬*\Ëw€Ä;£÷åêy“"ØRw¬AÔêêrT
9¤lAËÑœ ›~¼·ë¬ˆ£´ËAêÙ	e‚»…j¯±¾&YÂŠ“=­	7WÿHCjõvii	ö\}"¶OàvOãG5>r©%ÛÀ¦'7EeÖàšL_{i=8·ë¸±,›*>Ñx•+®9-. ğ¨\ğ`‰¡.)ÚõI†T·™&qùñ» Ñ¿êè6Ò¼ä _í"Ş4»u”h,Ì±:ÉBƒuƒ"}óÂùêÉ/IàŒÛØµùÍÎ€­‘¯i§›{/âó˜P;ª«o_ir\—:kDóÒÁSûˆÔl)ûğ´ÙB]¾L]¸?ä‚øÈ®-'
¥1LšoV”œlÜax˜–Z;Y².ş"5*³ªøn{ZX¯ó
_}j:†Á±ÃÀt5Xá4Ïç”âêºK?Kt[W5ğz8Gñİb2k¤à~;·šC£Ğ#ê¹Ì,È 4Ê¶¡ë:ì9*Âk²+1{²ü5E ønØ\xÿY„Av`5D¢Eç¾b³Å+fBuøÆ%|¢çä¥xÂ(M®–­Y¯UÂE.D¬å‰	X—Pï:s³ûF^x,ÎAKc}‚jI§õ˜÷ª›•àƒ6HU/U;€Ú)š»pÍ¼nm8]F‘z¡ÛjÜ§ÉøFª‘ ôn2G²ÙµsÅ7æĞn‘àî
Ğ·Îö‹°ûN/MOÖ4Ñ°±•‹¡;ÖÒŞ‰gse•ÅàÿkÄ#-ØÙ†¸Ö—Àúy{çwé?•şÜòÇ¥ä³"ú¸Qş/Éö2€ñdğ0.ë”f»Ó<.j>729†`€ÒUì™K´¢à[»'Á?¸4]€3G<¿%ÃoSÕü'Ø7°>n°Æ&ïGî[Z9Dr[<»3î•m<X8Ñ,5† l‡¯„ Ì6ò5K•S¾œ„•¹PÆ»À@ãXÊØ8bå_Ú,TKY^ÔÄÈˆË´”dª£U†([N<’'ë3Mz©Ò(”ß®óï»}æ¿K„ªıº*ñ+¼×0ØP“[<5–ï‡	pàÕÊ–Ød¡ï]?÷W=;~6\ôÓğrút›/Ÿ¡0·ëh	Òp–+oÂÑy7aÖ(54A×Ü[G2Œ2¼ğù‡î†_ü^
ıºnsÔÅaÊeBo‹é9 Ñ„¦ƒnOúdX;òa1c(KÖ_3rèH{‹“¤r-ß¢ºMD¦9ÏZgÜØïMhÃ^s¶;q
-D4ÅÙÃÛ¥µN·Œ@¦
ğ²0•4Ú¾}¬4'p<ßôıª):Tøa˜–mB8Ì¹S­÷Hİ’yfB(
5ã} ~SR%ˆåäşÏ~L®òxJdº‰?ÒZgo£|Í0a€cŞ&êPcı”‡
—ú^•)Wu$Õ­y¡pškˆé–—´s®/Şú&ú¾kcÿ’§z3!½¯ûŒ»q…‚f²i	‘bµ³*­Ñ%WÙkÇf)ÙF3´P9Š7‰­PÁ!•äXPçg26E›n£f>©XÅC7|J7ÔÒ\—.’¯*¡?‘e:Ëay…ÇT(› „ğDúÆØFhÿÕê-˜lÇÜ÷ş¼±hîå¹Wc/27›LÍDÊ– .×9|òfùÈÒmóÁ»¯çaò#½µ±Rãqû“[ÉNR^Ğâu=÷¹k¦PùLşa|{Í-V_‚Do‡½~ÙŞ²¬JæzÅ/£>Aµî„TŒ
v«›Ô ×Ùt>Û©Ñ“@“Í{Ã~bœ'cöê«gÕÔ2¤ÙşKÙS|-gìSÉ3Ù¸%£‡ÊD¢=µ–Hd)Ÿ{x&Vljj\Á/ÄäÌ['££<«2­HËî
LŸ{B¢c£ë0C?JDGßeÎ8Íetzï®,+;ºùlV^ú›q‚À¥0âãìÈ‘tu{ÀnÛ{r#4s×/;.KÕ,Ïß×}ôÔkåL5–)ŞŸ]”o,(¨v_B=€œ˜íG&løMC¤&h$Zê„(U#å.«¯ç>Ç–z>ó°!ù<½X£âÎáEQvÖÜLy*æŠôh@ç±(n%òPkhjtÎÒƒ¦s®uUÏ=[T˜2,(q|û‘8¥ï/ÊX(;LÚ¦( Fbfû.EéJ¼²¶€3ïm(,Q“™«ÄJc·Æóñş}ûÊ<ÉğÛZ°>C’+"o,¶÷ï‡Pu¯†OÃ¸³(©'CôGZœB>#e-Ôñâ˜ĞSÂ:£uŞú88eZqı;ÜOXtÁ@á°¼at@*ù‘#OR!|í±?–'Lqğ¥X@ıB{‘ˆÉ·1I3=§&ê³'ÛE`ÃŒ°Æ‰$ƒ¯VRäRT(Ã“ã'®AóÆ>wJÁüšFƒ]-Ç#©¨„ñDß‡ÏºóôÀ‹sîSâ1³èá"c¢F3. y@Böçö;»KShJÅq0ø…€…¡³ÛD1×SäîŠD€è7¹ˆˆ¬ GtÕ‹+g$øZø/V5:,ÏuænÊ“(ÓQ«ê¶ª˜¸,´j¥Ulİ ³=$aˆ’ ğ°bêtï:šEB”Ë‘p¬•åÔvwaC»áÉ¬˜PH¤;†Pw»Jîr¼rqï
]¢«U¦OZşL§yòŒB oîH…vz¦ğ <o½QCûJ{íls.°‹'5Ui—cî6·=¥Ú>â-dQBµtíøxÎbåÏ­LOË¶yÁ [@PY†h¯a±\8<ó¹öİ#ò‘¢ğ%úƒó‘?¢™¾SğÛUmğ\qÉ-¼H—âµ í™ö¨î&À?¦Í3ägÄœ
v-‡äP0ğìg!óÒKUŒ«ÚKÒ§ğÚWË4°Ø\pL©Ö!j6/yÆü-‚éwNù¬ {Å…n"iŞ¦àÇxí¼ó$«¦6wéƒsÄ›y¥wÀ¹IêÆêöK"9Pğ?{	4±+Å1Áß5Íó<–_®ßëã{­@áÙ·©Éò–VÖóñ·¦ŠÊ2Î¿ìøüâFç^!s'‰ıKÊ&ÊAê¸…],G3œ¸U« è½½‘×8å¯Óp\÷1½¦«e(vÕ5Š,Cl¬õ åaÙÑ85E5¾Z@`c/Îœ?0§`œÕ„Œ@§áÈ˜-ÿ¢•U½4Ùª:}‡9£Šæ¶ÇÚ°bPu­–©ßOµdFÃ~Ü©l"{ê*XÚfÒWsô¯Ûqvâ~ãëÊ>ÕÂFóÙ>u@Ãc·¾kÈå§ŞoÁXPîæE×õöó^o²z^½Ë[‹˜¯®Ş%¡êÎÍ3dıcùÒòV…õÛ ¸q|¹®Ñ,|[”67KÊ£²a~ ©H]Àyœ­¬!nÙV™B1\Ì}›ÊJ]û¶¸E“7?¯±~y-$°+‰£"„ô`úÚÑŠpåWÕ:®ç ^#¹¨#‘Tj2¥ee_C7€ÚDÇ9ÎÕ‘ÌN^ã(1­İŞ/xzØv+Ò{ùzLdqÒŸó×ğdÏxÿ)úÆv¶çalì¸²dZ,w6ùsKÚr¡X¸LÚÈğ°´*„©/ãÁûé0›íM(µ(	CW1 ÉÈ¼×H­6f^Ç¯Å³º06e!&†¨*i.Áx¥m*Åè—Mkø"³/¤¦ÃsG/ö_ÎÂ®5Ë¦˜ Æç¼xlıÛo–ïg¦w4 7ªü7oxxçš˜|ùå7¦.*òMd®úV1›‘dm©Šî©áÎ@?-=Ïñ…	9ŸöVE¸UÚÏÑø3İg~¥–£¥vjAnº@±Â3•"¨õ7ˆ¹;µ'¢>¡õ‹Rútï‘çÍ¢Ğ*”ƒ>}*S^ÛÎš›üÇÃF±¶íÈµÀ
Å?-¤ ½øÃ•uÕQ½­L'†§7¼S¤¢Âùà´7,çî#WK¢—]
ÕéŒgL3Sã/gn]åÖäe£š'O˜ëh¿9ğˆ±;zş3ÎmÔ®|.«ëê6õÿLı ˆ*½bö¾–ıeÜÂ@¥^ğ×-^†&ä¾½@ÎŞ|!õäİäËºÉÌ¬LŠ*şKIHÆ7:›´ëÒ6õ{9ñ¬ë–€mHÅ¿É:*Ÿ°ØÜsŠ&0·ùÉ•—%¥=úƒÒ Q÷8ûå¶hTšâšM*gÎIGşñ_‹¤ÓÍßn¼l|©ã÷li}dOè˜
'Gós‚qÁ%å$tòé6ğM,›^ÀJ0%ÚÀDSJª-Cè‚Ônóz–1É.Â¸¯J L Á{Góıøù0C­6,¾Íƒ'Äël*>dÿ“úoqzeò_¹ÒzCd‹ô…Õğs“8Kzñ›\HHGBìùngrş&æùêÙ‹:$½‘R‡ìi[^v‰›4“Àå š²8½<¿€’0†óöG1+İ£òÕ39ÂµpÛÉuF•¹ÆEÜÆ(_„À©°t—o(o£edo±ôJË¦ú1kâCs„ù›õ}âYÙ ÇÂ[]Î.5r|İìİÓôµ§¢#ÿrn+ñÀ‘ÖêA6
$¥§Dx$uÿô„#™E®ñÖÜÙñ¸_õŸ—o·Ær‹0màŠÇVŒÍL	7ÒS¥60O*~û÷GÈ+Hÿ¨H’foîi¿'æuTÛnÁvu¤ŞÓóî’‘3_öˆ	×¿ÛbºïB—wõ˜U$G€Õäçƒú2>ê;ºĞvÁ/¤ëÒT¹ø²f¸B$Œ“b=êjÂ®«hÑ±”»æí“f¥×Œİğô,ˆò[™ytG‰ÚßõÉK-Ïã‘Ê*	Ò£-AºÃ£È
3¥VÇ‰jŸıUdºï¤¯û-öJ`ÖŸ[Ê® ©çÍŠÜfOrLX9nF=še¶lÎˆ®WI¢£6Å+4 Œ§”§èÈwé—wÜÎîIåÊ‡ÕoÊî#ØÔÛÀh¹uí-‡ 8¹Ÿú+“[±Òˆ\?
#&¿]§S£!#–˜0=·ÄÑSöì!èŞ0/!!F4:´©QÒ*]o¾J±_éf[²b0&F½UîœôŸçx &–g(‘a“ğœEMÇ'?*ğsZ´mY†*ü5A,±˜22hIQ°ÂğS¯µA[qİÊŸ×À©EÏ·$Õ37àMÎ¿iÛSlÏ¿_&BVw†Í;ö´KW#,’›UÒõ« H]•£¹ÛAîĞ†=.B®NVòb×Ÿú}‘NúÅM}2Í_ñBI	ê§ûÓW"C®Ş5”ûF˜SØ;î¢)¾`;=ÒóX2\ « ZJ”ùIŒº,é›O½i È5¦­ßgˆ9||61.Z&¨¿’ûÖ(ğM|n$éÌ¶
i—Kü]ÆÎ
œ%¿¹›÷üÏtÑûµKê“*\ƒı8\~VÎêÏÌjÎfŒñR–ôòù»@f±r¿Æô€aª¶sHˆ*™[ıtb06öQ‹l6._ Y;¸ã8]Ájl0½İÃ¯D'ÁT›«táïCÎ˜Ë9¢ËSI×É.›:ñÚ¸äWqVSL®·G:¯!£ÚóoA¤Ü¹õ;DÔ¸1æHıq!nL|®~îóÉêP‡Mmî”ç)ßåà[(mn‹tµ«Ù¸Nv"ê%ÍF~ìîí…~¤ mMÉ)®G#b]P^Ä-;ZÎ²¤(Øø2Ì~I\ÙH;í>±ŠŠMNÃR(¤ù¼Çøm}ÚÑ˜šïß-—Ä³ÀáêÜUSRWç,?„ ),Ê~‚bù§!0?’¨ğ.ÑrH©µ,¯$|MŠ·òV¦s¾@ëÇÀ€>Ö‰KP˜ÔXc7…¬ŒAé>=“Õ¶E7?'œöÒ?öA:êï¼ïIËt|şg«¦F×©Ì{È$¸±0Ñï€(¥L¼"–%\°IZyA×_6³˜%k÷]õ?M®JÂç+~EQ¿B!>¿€€ØĞıq‰°ßß İ‰A?È‚€“Ã9	#ª½pŠ®nQg–DÅ: ÚdKa
nqíÓ:ß±3ÛÌéÒÃZ3i•’ø÷Rø£w3ıedWä şw:_5ZÎ^×uéãƒ5}ègP 7¾šuPÿàÓ\cmgÂªÎÚ­àÉGi™ZçßÍÿid ºæ‡N²‰	®ò¤²vK ıL*bT°vdz±Ã}Š÷G{k6Ÿ^/ØÍ&l£â¼Ñ HßrxóÄ­ªEwµíÃ:ÈzÄüA˜gPWêÙnÒÉ#÷WşÒH,øR£„£^õ¢6	Oøæ¼RS§üHÌ!‹àÛçŒêî”0´€¼dÁ´ıãõX_Îê®Rÿ¢m¦ mİ¾Ìwu).#"µüIò s2qZi¨‰ü¬´€œn°sr ¸.Ù[ ÙJ¤\ÃÂ“$h„X­*Şh¦)@§¥Z)õ¶}d¯V¢‚˜1ÂàÍn²á«ÀÛ÷ú`áJzüà2°™³i³©­®™p4xÇr>©À=¸1õ.U¾	¦¬Ô†(öc¸¯¥`®­…–%|C*ëPJéÓr9#~ñë?{OÀÙ¤9e,‡ŸÄ)´agEôMĞ)±EóÀSçÀ»“¸}-¡·.<KÎÿøİx•]ZöY€˜ï7qç¸’ —	“x=âØÍœ÷ğŒ6•ã;JEœÍ²z¨.ùé1­mˆ»¼S§¹÷ßö‡Td!2^2«‘âYP·ÜŒÂñFò~H¥ÚtõN{±}Eø<ºÛg4Hµ‚fØ‡Õ`Î°èªùÆzûÚ¾s¶`,6º)÷‘^³²3®tCßV¨  B|¤ä²$`ÌO$'‘'ö*ˆß§¯ÍÅÕhùÁZşô.¯¼]îqÊ‘ÀN+DĞ×Mö,Æ$É-p”ŠÈËŒîîÉ×xlhßê–İ€9YÜLå¸èŞïvuõ>ú„©´lx×ÈB¾rC8İÃ3_´Ö&#7Úuİİ«€›W­Îƒ‚¬Ş:rcˆÃWjŸ»Yã¡%OrÒÒÂú8Öe¶Ícta›~.˜Iıü*®Ğx3ë¨–¯şuÂ¿í%¯"
4ôâlÔ¦dRÏuŒ9²æ¶$¼:™Ä?‚ˆSö™Jö˜TKƒÂS«–èÎàBÀ”×SGÚÜå_Qwô*ô¨£ô¤ÔÊã_£ïz9í†Â@u"¢# 0¦GÕŞ\˜÷¯ëİ‚€@»’%£kşp(¡('4ƒ8CçĞ r,FŒ ò¶#{¬Ç²µ¯_gAÍ‘Àıı¥Ş¦!V!9&1œdogåN’JúUO"?„O¾F¨,¥‘…ªïoêÍš‡¥2ÁN¹}±Q’—7•[WÀ—/—b‘ˆ¬má^CvĞ@ÜQ0¤„Ær<ÄtÒXškÑÙ„­”0OÔ"¬˜Ë—Æ¢"gh¡
§§2)÷Ä«+eÌáõ:•”Xî@¶]Â<º|N{ğÑ´ß+b²ü	È¥u:W2Ø ÿu½ğûŸ`å2“¹v¸ä‰¨€sqøÕlºk^| 8Ö«É-Ô!ñÍÏ¨<À¯tò¼/eW«ûK0û1˜äãëhô%ãÌàãÂà¹.ı&j$Ô3®+È*äöô}ï¤]¢wúìÛP]œÂgúÇòÂaÜséşF¹â”ø.Á·ÚÂ|Ù¦ğDæ3úˆ›µ²ó*Q½9fNíëìlŞ+Æ"x£|XiìÿÚíãƒ„4~äç˜v2†¼nû‡½Êl¸+_[íÛÔ¦ıÌğ™y“Rm¡ÆAÖ fbv­ßŒ4 ÷§×	—ÓlŠÀE‡)Ò«_gÉC	é¿‡Q—wÒ8}T+--•Ëò>‚’ªnĞ~÷~4®Lä<¹µ…´–O:$(lÏ“Ebƒ ®yu%«ÌÜ8 Ø04TœÂVNb«¯6àT2Cè£ªæèàÊ¤&ø5( (vÑk~ yÊà
üQ&í¸ÿã„våê*³÷C÷|¿„‡e*wüõáš¾ıç›kägÏ®ûm¡z5HXZ‘¡aå¢Ñx[°êÛöû÷
%à£d^³^¹¨„Y:üPT‚	A™%0?`eƒ4iÍ¥(e¹àœNpbÙ€.ñÙéÆfÚ¢ãŸ,«~àKİ|Ï·{"œ€\^‚ÇÀí9}Á’ïò7ıÎúJ‹ãõ8İÁI8ö©.šÀ1÷Ÿ¦/o…3éò\¥šfÔ©lKW,6ÆóTáŠíøş®‰b‚Öf¹[/¥—9ËmuÒÂïYˆC%ò§ûäoI°ãg(×!‚¸8É5SÄíi£c€¢êö&‹öÌòÆ…¥x¿<Òïœ[FÂõ¶,-1Ä«/İÙ"¸*«dƒñvÊCNÏ#Iz­Bc0•!ª“ÔànÕA§d–°Ïs“#òŞÛ´²*¹\6{z†»Ò—„Á›Ød1LØ=Â–âÙ´xó7wäŒˆğêO@CÀŞ;íÂ”r[?ß›o)‹ TmÇÇsKöèE‚Sù6ı‰lmY<:j¥¶Ñ6ÈmÖE4ÎäÀ3ÅY|J¥²ü»+ò˜Ü/àhôäSlÛ^ ÊnV©ÌƒâQ×‘üwaË\÷Ó ]µı £ekäµÛ™™{¼h¡ªíõşmš•Î2uı|¢÷<.FÁ‰£Àœ’şRØÖJm„h,êAëöá«êN±†V41ÑnwH#ãƒlùh´õ¹©Ãïô	Õ›”×?lÒ#ŞSÀºİØü-½B4ı¶…L€=f‰Nœ)_-Œ8í•¡’)ƒ!Ş(°~=9ÅX#Ù{2[¨Q7$‹Å²eúéü%ìJ9!J>Û‡ü:pêñsÃÄbÊ\{¤‹ê„µ63×?(8k™>éöÕSW%ÏU0\†M‰!2$‰‚ÜÒÑÑá³} ~¦"ÍU=ÒµItoü½í}(Ù\mÓ*İ3ŒDÁÁ”·E7ğgƒB”G(Äfg=â%äQ<öf—[¼D	%õÚvGE±ãÀPéú,âÂr›CèÈÁù
ÓÙš¬¬İ<…•Å¿*ÙXªÙHr¾ƒï\¯ôè™!¶ï‡¸WAì­•ï(÷gJûMôî´!â¿µB¼jâülEê'iz~Uxõò~T t‹açlAWÀ%¿j…|/‰˜©Z«k4üâ4Uı¼ÔÙÆ½w®ÂÂ›nûç*t #²—¹ŒCô(Ÿ$ß*§zŒ©˜Ëø«HY GŒ‚mÃ(·CÛ±u&ì´k!€iÃ¾,L]Îœ¿Ëò)öÚœ
'Wü*½`HƒyícÒ–$Ì+³˜‚^ÙRY‡ÆgqvÅ¼âûi¥ôULÃ´uc}x—9Ú_›bB¹¿;Ğ
¡šŞ#•Íª~#º-¸†½cy	¾‚6ÚK7TDş_R››“<Æ›FøÀÏ0ÅQ
×èÇ¯¡¸	Ç<‰hÙÑAŸ\¯øt0-úÊ“‘§Eê—İA‹¥ä(?R–ø¡ÁmR!«³“- ®<ìæëSµ3KÖNw•«—C‚Où‹mÓPÁ©Àşµ€óöñ¾~Î„ü'5a–9òV’nº1
0…àm1úÛØ¬BJ Ö\ÑÓU#ı¥+š$–àà.d<Tğ´`|È’O6†}àpÜw/œ+±ZXã¹7È4ôvÛYò³µX(Â2ˆ7—äß;é›#éÙì‘¿„–Qì³8gÖ°cØ$Óšİy0În¼øúV•*S\Ô˜%º|MÂ=ó åz-m¹Å‰}?ş¿:~Ó@ËÒ;k7f.|êc-İuÿ‚Â’å¹Oz¥ç*Â_ â^¸H¸Š€‰ON;š;‹@{£ŒÍ`(Ş™°,:ÈT`®"îuÏ@m:Y¸*½ˆëŸğå¥†ÔqÔá:jIÀcLˆ3M »läßOÉšv‹râÛgBà¡c{5ëùu3“ztüòµ[üîn}^‹t9˜ÁUÀ?Ì–+‹±´;á˜Æ¢•üãŠ>[F‡x†‡ö•î¯'eĞÔª®+·E«Îòï• å‰]Àh’rMØ›%¨íà¯F€ùÂáš“8°+4³có'–!#9ÅƒÃÕV]Pêµ9ãFD‡§GÁU:"~eQ÷A¡ƒİtq6®üÛE«ÕAHç‘&­,¢ß\í…6lC„Naš´
IJ¦5·Ì2ôç4ÊkÁtÈ °°õM$Äğáp”}Ú²~æaï'"âLrW(ûÇĞ‚U,Æ•ùiI¥&èõ;ÙUuØmÁQïiPïØ/®ºõmd™Œt`ÛŸ}”iL¾j¨‹Æ½IXèw&Ô›²¡–~—MKğäñ,Ò5Ç¹É/[ÆR¹Íiôøø»Ê’ÈÔ: ®Æ[’5´ZÄômğÁ>Û“¨ô`,”H@ÓwLé·ß^‡ãœ«"£¡2yu¤-†{İ ğ5V¾.{RT‚ƒ­ÊbõœÏã9$IÓ«™>º’û‘ö¤pV¶@ãîF&®ƒşnßïTÒA¡liˆ0 ¾ŸàvÅ3°®çÅüÔb½7Êì˜{?–Puà;YÈ¥sX[‹üÃ,1"yàë¸¸àwj©ÎÒ–Àm*ÜèÜ††¤ÙÅäë[_FÓó!ÎdÇòj¢8Ìß?ªpÚı­…Ğ4»ıEÎ.z(*b—Tav\Ãî„.†¨ö“kúĞR€Eÿ]H‡€ÿZò ö>Z÷›ÀÀdŸóLÄbÜ¸³€7æ%*Üø“ í=FåŸ<¿ºïïNS ŠÖ($ai¸‚œú`ÉœZâäÀ#
22SÛ29g`åLæ!1_•.°!?T–yÀªv‚„Ğt0%À5ÚhŠ˜SÎ-U[5GÚæD¯E“Îƒà+G»Û$,–¹,AÈ«˜Ó·ÕÜeê²–—È æiÍ‡YàĞeÅ”5RáìkniÔ¹L· ¹i­sÙ l¸‰ä1Xˆn.wëûâƒÓı]ÓD¼òç9!ç©5¿Œz\ÅıgN¢®°‡@ÿ8Ó“İÅ.J°?ˆD*‚Êuà$.Åÿ®·&#ä¨cY	«^²¶/BÁ ¡ëÕEH¨‰u¦ÖRz >Šƒ†s…ònœëÑÛMNô¸£ğÄzÙ˜§j¢u¹xá)çòKAÜÿHî¿‹Ó÷S3%Ñ¯pòrÑ¿Í,<Ş²2ë×¥´my©W%Ş’ˆmWWµ8¹,6İï¨ŞŸ¢³>`1:#\P&N#cõqN³ˆW­@	rk)5‘…”7‘O 7ìY¥Æ"‰S•¥¢i6F²›êxkÈEìG©Ü+)ünuÂû‹¯U~Õ\<Ş¸Ìgğ1]›ë#ı¯>Èè`>m€$0Ş54{V&®0&IÒHÏêü»Pgb<-{}M[¸Ç¥À›329vğ8Ğ#xŸDè«…óÈø1÷İnsÍÕráù±ë?g“tÍˆlr%z0Wz`Y¸1dQ¼ivSº·H&K:9ª·)e€Ñ	%Šæ\|L^×Š|¨–êÚ²Œğk¤]lK¨rÅ†›!êTGìú±ÜP†_cU¿58õo¢÷D:SuÏW÷w
1tÌf	¬W—:§ ó²ºDQùèf+eDÇİ¯Srúc#>nUäòÈ>ê}Œ€‚ÍIˆ³¶ìÜ`"Ù>0¸]ksêhkÛ#MO·àĞyÔ7Y*![7¶åÕ0ë¯%†Àš’Û¤É³“´æAÌ,üUb¸é‘¸£luAQ/Ğ“(	ÒĞ»t¿õx—BÍd’ÂwJ÷&×~Cä3’è™vñ„T‡8hEİ¹ë†µú&_™¨½úO­$ˆ8›ö¡Æ˜xÂÅ*Ã™ÄÔ8“l$'¡ÍúB<û 3u¢JüFß=Ì&Òªt‘x´Uè?…z<¿	h1M,å!ØğRØ#‚-‡Ï¹ì¢âXøDØ”©§ô!ğ.¶‡e¥ÑöÒhÈ"÷2K«„rÁ¨rŞŒB­TĞ°Ê›¥ä:›?2¸°®H:âMÚìJ½—İzÏ*õËö~_~â@B?@Ş£î%oAL(9Ì(÷¾L8äk>ieyÃeÍ»n± ÔÅŸ7–«ï¸6:õE°2ãşZ^èŞM–q4ÜÊÄ±Öl=çÊ³O³83±qßß(0{&eô·‘SMåÌë“—WñÏü7â%†°ì«ˆî¬ÑÍmzrÈXèEÅòE›‡Õ(üĞQèã^V¼BBõ±&Z¶h‹‡>»êÖè˜-w'ö¹7—E ”s³(loÔf÷EO|ô‡#§¯S\@7qğâÍ?™oÜ ÎìZ{•#1c u`M–rÔ²•ÛkéHãmØ,Œ§<kKmËÓ´ª×YıÕç’×GËyş¸šâÁı ¡#µnøWŠÇZ“ÇR„SúÃÊ{*|^Àµ•“cêÖc:zµÀq_A´Å^YT–H–õ_s3Tğ6²náH8ZxÇ²ÒìDõôÖşôï‹â ÑœÁl=.Ì’Ùmq·º‹P€ì@£FË*ç2wu=A|GÀ-YkğP¬kè‡É-9±’–ˆyÁ°ïBüµ—eí^;?|·$†×©$$ıPQ ç9‰”æ³!ÒuÊ(ÏôÖeG|7g/hk÷›¥ù¯Ä™L˜İRÿfxD®dûYhL†¨îÜòG+úÊ($¤‰84Pm—_;ò7&ƒ@”&^_)Eª(@eÎò]Î²±­.d©ÿ5Â±ÆëÊı{4¯WŒ¦K”ÙoŸç*)%ª§æh^0[¤ÃOIø×T¢é%CA»õwäDKÓ6ˆ6Š¬~#ÕMpéˆ	£‘ÛE6gHS	.ÕÌZ¼ ÖuÜNáºh2ğOÍ9 ¸S;A_—Úc"ÅIğ‰†õVœÒ~Ï]´gY«¢TE®@ë+üºòƒ“Ó“çÆÑ°îçK¦¨\Ú)/Sºñ˜ªô«ï¿T·î<¥kµ‰ÓIŸ(3Ö¢| –ïo]]¸ä«m±‚ò÷£s!û¶xâ´Fc<Æ.pj“´iìGä¿šcÕ:NÂ=D³¼'éåO9(Á~½PCù5ÑIIl*Óx-Fm <&õ¼¤²©
) ÁFp±ÖÙ>øéæÛg2j{xáË¾^VõZ;Öõ¬X„÷/,¶‡—Ø}*+ÂºÑÅlE`	®¸1ÈA¢Š¼€ WÊÛU!ÕÏ5=¤2è)¥Ñ×h pÂzãC¿ÄtÀl}sš…|;Å  Œ'4\¼:+<ÌŞ¨gKÓ²¤Ÿêp0Üµ§ƒ7©÷Ëê6‚zèJÆÏ”)ÒÆ§/á(îo£2µÇÀ+M}ü¿Ã/ş©"ºÔ|¶ìRé-¬Ëû?>cÜ¿D“QfkÕ}òLø|Şµ$U=„‚¬+LjftíĞ|…•n¯é=*P®ÅZsÏz-XGü"ºÆdØªÑ5uš—ùa¤FËËIÑS1Z“b¢:œd:<›‰™mt?7ŒKVÌ:İ-üŠÛñ‘4‚Ş'ÖÌè‹¯\6ÂGWœ·–@u4³$â‰Aæ?Ñ’DÂf³˜.qUä_K´ù¿ çv^È÷`cI vs8	TÎá) MhC]Š3	W¤"œçŒ9€ñú	©Ùº òÈ5ÉY}ÊP
0‹e¿sO§7B”ox5kƒ zîo6ªÂ6ê4‘Hìu-ÂìAFS¢û8x•?“¡Ş¥>›cä8Â!~†ÒíQ±Œ#¢'{%ù
íµ*Ø¡mô1Üb®Ø¡Ö@/Ğ´ {xÍÏ.”uË¥4¡«¨
0şïO\j î´æøçY¥znq7j²‰š:ô<Wnvü†W²ò	!Åänšy:uÕïã¹–!İ3F¥ÿÃĞ1(Óêkú^)œ¥ƒĞ!0'ş¥Ÿ+¤ê:™<&”[ˆeßø²ÕEÓïbßdA|ô‹)¼j°®5ïÍ*û/ )6	á!gM¢‰…[JÚAó#Ä[7ã—Ù-êÃĞÜ• Éªø[ÕK&nÅ@YÇ}H/” h
Ğ
h8âºŸÉù‰E×—İzÙc4¿P&¬“5b¤ÚîU
3“T49×a¯Ö şõ(åßÎ8£éZ&ğIÔ±×ÍvQ¦£UÚ…Øx=+¨û'İ¹‰0D`eægaÏv¸§É¦¿1„÷PJ?k5’C3êÁğ~rÄ¨#¸8vÄ¥neÚ¹éŞ¿mDìy@¼É; ¢ß#‘·Õmjøï>qWHSa¶Æ-L\FÙ<q•¼pÓl½ˆbØIP¼0bG»îs[úæÚã—’$ÜªB¤¼9òÜ”ıÅª¨9>m"4p*8¯d%^±¾ªFvKß¤Gñ6so·®0ºŠ„:W(ı¾º©hTaîdjkşZo»Ü?£!ó¦¸pÒq`µ¥Íî†sq~õšnÆZØR¢³øè7İ#ûßèYK7éáÅ‰€Æ‚=pËP3fÊĞŠ¦U3¤–÷¯ü¤Ü$¨ÕgõÙ•óAf˜p‚‡H§Cû-‰M.¿_YË¸îï1«/âeØ¢L RÚVf½ÙÁ=÷ıÌ ÓOŒÄuækíÎpc
³õ*M‘è›‡“ˆèú†èLJC3*8Éå}ì•½×cºnæ—z¿PNİÏ©8–ıÅßë®œ8?v¼j9àî‡ÜôŒO+›áŞÀÈaE¾aÏ¾Áï¹÷Cà‹F¿ HÛx!©ñ¯–ÍF÷¸€5òô;ÿà'‘©Äëa¯½ŸBÓó7¤m`ûS²ercJ±ÀekúAP ;Ÿ½ó”­Œ”¸c0ÙÉû/R2·j#-q2t¶æÓ#ı‰76IjŞ Q23ı¸|ZF@ [œ”şà n–ˆ0Ù^Vñ}ÀäõU”3:Ğ¦,ù´b_¿÷#rşí‡h~PİX«´Ä 	ö‘üzç‡šfÄ­ÕW¨ğ=÷cµPÏqêÀ?ÎÑ^Bì-ì:©Óš–øä©éÌûö]¸A…ı+ü²¶ÖºÛüwü_ÍÏ•KD{9T‰tvRGŠ…‹Ó¿ÙåÄ…ƒ…Hà¬ïÛz@ƒpŠ0ÁFà]îå¦pU$„)ç(‰ikæëPê"î€%Va® ßÙ(ç*IºE‰Ë&ÂÁ@.ärIr&äåQj¨‡Bø‡EÔOğşã(1 gB8ÍñøŒ¤Ì­¼”ŠoáV;×vı…l”ïå±J6#J%jh+nîjÅ
‹³cÉ‡½cüa8%õgkt~ r+D¾W’‘8ùê»MMU­KëÜøõEŞÿ]½D=òö
‰ÁûT¥TF§=jLìÎwñnñFv“	ğKW0TSt¿«á­bñTó V`ièw›õe'™¶ŸJ’tLpYNïHR¸å„
]å¿†‚1Î|ÔIeThšt›‹È
ï"ôËóv=­Vê"=t2}P¬3^ç¬›³Ùë–{¶©+7š–’«‚(':P88—RFzƒ_¡1'×E¾QâIÂnã¯vH”‹tğ»ŸÓ‰Ì<Lı_¥x£ Õâ•6Ìe “¶ht…W´áŒW…¶QÜX&sx‡>Ô¼,D	•ÌÄä*ˆÿúCiâ…ZàÊ·CÉä¬t%3«¥Í/Ã1L—9‡ŞÔÂc¿îp™î§#­ÒŠ"dJz£2Âu®/O%¬Ç:oïY„r€ŒıvÔÒ ù¤ùo¢á]¡­ß±ã•ÚBw¦ä0G%8C¢aa¿:RN£´›¬¼çÚBrs–,`uäûµœõÁ¡BC„-ÙüÒÿI (-|m Ët¼/æ8&¡L­¼W?útOÚd1CŠı½vj¬‘çfñUA=š$«ÏÁ«b nXªâFĞ8”_‹áE‚‘³5/SRŒfÑJæ°şµ¥˜aL-Hl£?wtS=!Ší×j%éê®«õá•áÜ"ZZm0·[‹Ÿ÷•¡Z¾/¹9hÕ_¬¢GŞæQµÉ1”êø?ÿ(tıIWKÚ){Itèï6³L†RïN9	L¡ÍMrãÓ,Ô¶–2yÂ"@k¯n\óĞ«ø<\ÑâaSšÄ?'»Ûø÷hC”âH„¸Êp¥"®°%m°cÉ)ü‹ˆ[H:/%=è5^[MÑñ—Æqlµéi|ı¾zrÅ4:êP`¶ë8¸C½ü­Ç¢Ä¨;3uË){(Zq1g|·mCoaòjƒÊ×ì'•)‚;aØ”géÍÃÔ¼#a»sµğ‚·]¡nê;A¦0™BB›úó U.»`Ã¡¤¸×ÇÔ.{nµA·kĞ Üÿ–Y„†òÄßÅU˜“M"/¾NÀİÂæT°oæn¡`"Áú÷¸`â9ÂÕªO½®’²UÿâT‰à#ªÇ˜Fì4Ö–åQ‰#R—#€B¾«[İ1²˜Îj,+ 7Õ)7jçËÀ&œˆabqßVM²5a#Z?àçÜ¹(pgíae°
 UÔ‡õ[êÜñ6ˆs‹±â-²ò+ôï¹§ŸßR?ÁıÁ_¬n»ƒ­ÔæA–ÛÒ…?¡ÏL=;wNõû,Gš!¤àOö*ñĞZ®Èñ¤Aº—âì¨v³h˜E»Òì?º|Äû0½é¨‚üJğ`Ì&§¾yò‡ûéé œè·f‚k¹ŒR¤G”Õ×°œ;Èà-7AJ0Ê	õ.[dåx<bİUÂÇë“y?ÿ—BF¸¤ÕZ<¯ª7MûÜ¿s	Ï	É¯{Î°e—::ÓòBíæ*æÔÙf%w:q:›{EsĞÄ!'tQw²Xèİ½70§Óê~¾	®>ñVBN/åÕ¹î†ŠíÒ‡‹a;ªbë§X «é7@}Ÿµ€jËdiË‚*JICGûƒóoĞá»?3[:ÅĞÄúßÍd$ü)U|;ısŠ‹wÿë">‡Õş^N[Õ ¡A.Á_bi¿÷5 ÁPZRŸxh‹fï¤9Ò^j×ÄKl'µNãõ×İŠADR¸!ZßsÛ7[ÍÇLê#Dvá°fcC,ğÈTëÎâ"0u€Âş5éĞğRúô¿g…Gm/‰â|ÆZŒ‚voâcƒ5[)ä©FSÚ1†xÎYnëŠ…¬¨,›[¬ "#G„Î–¬¶—±Òr
‡*e½u¡•{?_?ænºÃ
õ:‡Ç†i¼Óaİ9Äê;K‚„İ§Ää·Q°t&ñó…àr|àL?DfŠ[![Uª§Œ– 1˜ğQzŒĞğ)ˆlj² ãxŒ7ã¹dğ„J±ŠŸxÙŞÅ¥Påi òöÏe·N‘v¡n¼'Æw¡^ï6Y@Àu†„{ÿ;J…¯;¶o“Ã|TûñğMuİ3sAlúúbÑ¨´ô‚õ‹èIo
½"¹Z¬'cQàkYæµ#‘ü§=eÁ‡t¯Aaï÷7kÌ·Âa8Â×M{á²ø x‡F!°•Ã ùºY“wš-ÙHåßAø‹#Ë[i½ş>Ã‹˜g»§x”RºççÖœ‡Îí©ôÕ!Ú LûMZñw>ÆxÕ-®d9îj”yx¥~|sAòİùun§QIüÉµ=!¬ò8pE³?(zÉ¹ÿæ.L„•İ:Ã+7–¤¾ú££r9ıX§”X/‰:.N¯Xc&:È_½š“j~öo•’Vt#½“¬
Á¬e¢+Ü™ù+ŒdŠ ô8ù¨ª½ÄFvÃì­¸íŠØ#¾¦;g{ê…o-ìÓêÅGz[æBŠ%Àé vEB81îX?s³-ÿ'J»âíÛåÚ½\,Ya[Âıì‹!^¤ÖeÑâóåBæ8ÀÕ±¯A`ëéÙ…G¯¸ÁìzPbñ®÷‡æFÔRwßgÃ8òª1g%ß˜*	êO¥LkW&N”ÓùÖtB?Óò[¦ş|“%²T0Ù¸ˆ´ÎÛím.ıÓŸG„o/dh¢Ğà´ÒÒâ=äoäéfîÖìJ‹WÅ'¬;Æ2×ü˜ ÄMµUÇ]†Ş«…Ùti ÀWõÂ{¤%äé·çÔqlOô‘tgö‡Vz$ªH«WB'‰D>ØÿÕ ÖÕ‹@–Jè¸P4¡•U³»æõ_ ­\ ç”®çG¦EÙp@P÷ÁŠb"äYıœAFHÄGtyw„üšúV)Äî‡ãcVX(îIP²€²+ïW
^âî¹Jc™H–	;:‘0§6µ°~üÛàäzDx—j¡Hˆ÷\
»‰D\Äû7®µT¾{/¥ÅøŞ 3'Œ")İ\‡«ıÕ;.)oÃo*T~÷"²íaa.ûêpà—·å\UoÄy™ŠOÌm‰ûW‘½Ë*óÌB$>MÎV5>æ°ÜîBé‘0ÔòBH)    ¬‚n3ÿ öµ€Àµ—®Ô±Ägû    YZ