#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2534626875"
MD5="71f1a67007288e706de672cc3e9a9c3d"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20728"
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
	echo Date of packaging: Wed Nov  4 03:03:19 -03 2020
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
ı7zXZ  æÖ´F !   ÏXÌáÿP¶] ¼}•À1Dd]‡Á›PætİAê|š6 Kxå˜C¥CR½<&Ú À¼üÏ£(«ä´5ĞS»Z­m
f-Ğ¿TÁÇ9d*P'„JÜÀ%°ÏDÀÒ×0ğ¤`¥Q¯œ4gyÆ•5ÓÅ;«[
îÙ°C|ãcw3P,§‡J£RìoG§K©~ì…õK½Ô|Wšå
×ûçuÿ‹L!vC­üU†Dóo"€UİJü±'¼¦)Œæß•†®Ebq8²ãuˆÓß½ıi§_ò§‹qsìÍ	$üâÖ%#ÙÁÁA(¬#»ÇÃŞ9Œz–!m%oº›–—Ø¯hÊ>¦ã"'WX¹»¦jÛ^jâ£
¤2¹¡/î0êlTd®_ñÅ&î´pyÄ.¤Ì¿:!,îëYÿ\§:à°J#I±C¬q`çÃ÷ÔÑÓ„ö;Úb|gªıí¬ÿí-ñXÆ	Rò1É-
EK‚ĞÁg¾wÆ>™[½g×Çj-.L´ø¢†é÷†w#êfdĞÕ¤Vkkp†ëLĞa^*OX†‡Â$˜DHaÙ›ğÅRuÛF	±NŞÿeu¾D\3âA•ä)!U… ´Ã©  ¡’º|ò¢†«›â–bıñÿÂ.x(£çÛœ±Øı½•nñYwÛ.ïëm1PïØº[%.ã¿ ¼ë‚{ô 6h§Ÿ&ˆF7vÁÎ6ç¤€¦JT¸ó ´‚DÈùÈÜ8…Zğ_Œî}(moMŒÑ2Ä½ÉÒİÌàíŸGÁ}¾ÏZ™âˆ1VŠSÎŞ®81İ…›"•ôfµÓğ/*„uÑb‚õ»LäÛÖóºVÙL÷B•¹e0@`f±^=©©ëVú	H%‡T×y©ôÊ=ã„ğC8eı‰¡ÜÁ¶I_®vÓQ·mjû8}ÉágR¶j“‚=x$ôPş©‘¸OHİñ÷;K”¥7yëQ8š•Ş¡+İZ™r‚u+0Ò$é^ë©rİ–bÎSuÓõz±í£‡$QJƒ8¨: S¹Â
wÛ?pòB¯œc«ê£tŠ~Ë‡Å˜è™Ÿ`«›*?/#¸O,—óp$šâFÒÃÜëENF¤aß‚ÌK'ˆĞ¡×–›Ik†‰vÀÕ#¥a¯ÿ¶åõÑ ¾Ñ×€Ó*6Sé9¢¾AgJ‰¸ä”IbÜ<Å'ÊOİ¢:4šO	?Šäô]œj©uŒŠø_VRñœØú#½@	p ÖÒ8ù -1`èä„Fšjô7ÏS¥#Yá¥HC Á¡ÇM4‡l³]Y„%¿û‡†‡æ_ô{¢~Y²¸ñõ—÷É‡óò2Yã|l)“1/)¬ ¶¡µ}ßIG)[YåhRˆğú=q1’‘KH²U¯-N}Ù;–ªùİ	’Ê]|÷üêİOÃŠ¸_LíF<¬¤eèTE0Vd^¯z;Bl\½Qìîş²²ˆ?±=q¬^·ÁO(q¡µ+ªE&öÃÊ´R&p§Zq¬©*¤·	µWíÀCïŒ]ü>ˆ–”>;t4
ƒ×N±m5e±]vÿ÷Z‚¢[Ëñ]®ä·Ô—m…±µŸªhdT÷­ı¦´¹˜À¶§,ÖBü^£¤ÙNà{Ú`dD*³N»x‡-µ&s>c&CÒÎ`º€¨İéÈDøÃÔZ0f£ VÕ1ê2A‰¨‚ë
š´yñ«tJ;ıR\]õÍ2ãÍ}ıHÜêİUäsm!8¼ÛŸê—\> \èbÖµZ¦h°¼ÜC)+İî&¨jşG’:ªx’Ø¦qlÜßĞ›–8Òu?”î÷Î£¶Á	lîdùãò
# Aª‘ƒ”Älh¡†µì!±.ÈùMÄËtb1á²7»KÙ	MâŞUL¶Ãø éLEQíıPåù,Y.yº?ğ/$®ı(dOœˆgqjC'èû;ÂeªŞL§ )¾°Zİê’d>‘¹s¾ËîJÆ‘Ÿå9J4´*¨öpİ&ZU!ùUxwØ2rÔlŞ|ñ77ƒ ÆI¾‚•åÏ«“(Â’$éÂëÈ˜d¶S'–¹Îõy©-i¤½÷H&Íûb!<}hòÉªxo£)ªšX eıÕ]°&Š‚FVİØ	iKó±5·å',öüR€ÎÂ°Ë,vá¤G®Á'¢šyÊ+H‘¯\t‹\—#us$]Û:rÜôKE şØ+kƒ‹šnºæA¬³»§¢»sH¶ÜáK‹åÇ½˜
Y?k°Äß®y¼¼Ät2· pA‘ƒ “öio¯t^Ø¼/LeÖ©(ümeÀ8-O{Òš;éäÎx¹5Š„œÑ¦v"ŠšWQBM ×¸ P²:ïdûóññqµ¬æÿ#@Á²:„Óm$ÓÖú™v©%BBãñ’ÄH«-šq‹ğŸcmkBåWNÓÙh®İ§EÀÿ°4õŞ"c•qXÙú‘èà\)Ññfk@‰"—S§˜w˜°èÂ_OLO­Ú‘âf°çÔü(y>Ğ–#·
— U†.X¯ÌÉ^XÖƒ#°Ã‡¡+Æ 'P1óXb¢šOiC(øRÀş¥G1 G˜QÒ©°}C½†Eft%Íœ%º‘ÚÇ‘dŠ}İo[…mMV©F3ÜStıó¸	EjFÂ£’•<IÖ‘?Ğ9S+îîÀN(³¼WWeİª¶§µ3c•¡fl1ûpõ‘¨LCÀ¯¼D|w³õ¥q.¸šÜ4zßå‚	£S ¶IÄs'Ä	_¹Ğ½-qU˜GîöVh  ‡VtJ‘¥£.¡mş/VfIÓ©¢mgØ°ÓñÃn£èí‹‡Ycq“…"²öæğqVÂ8aq(E@W_›cÉ›l'T/ø
•?À}OÆ,Dİøõ2L}ÚWiÉ5XòßËò
4eê@¦CÓG‚JĞPj{Èû	†1{lÍãÓÙàïª¶LF8BVN@	‰¦»?%9ˆ½
J‰úR·hÅŒ©?[Ÿ€²ÛÕŸöP?ä¾ëœkOÕ¡Û2*3Ë#<?³“×ZLÜø”¬öì[¹ìºæ–;ßKÀy¸K=?%üpcr4ïNa1Hÿ€.QçUÅhº¸M…fµîŠ§á¶U®8¯d1!€6Ö,Ñûì†d­éÕ^Y5©åR/íƒğL<è/0“ËöM¿¿ìÍÔÚÜÛğ@¥R'iÃËJ|DXp1mä†İZz…ŞdÕáüÉ~Dší¸÷‰¢<İZ¡<˜CÅõ0ÈÓ˜©‹ xP:µ:„‘/î±6ğ—æçP/ŒüMáËm
„gfÜÈ¤˜|R.DÔşÈò/ßˆUü\£84	Y¥r'f–ïáÒ&S“„H,:BÕ»örúÍ/éIm öÛ
-T

)–¹m™½ºÒíÃªa÷â)9×ìVi-½”˜ş¢’–GnïêÀû'ÎæÚşi-©(dB<ı¥CëÌPÅÊhÔ2„i4QGÅğ‡öÙszŒÌ|HÆ¤‡ƒ¥.´Yõ\ßZï/ş¤‰¤½ËU¡´6
®l‘®"pUº*t±nq0¬ŒŸÍûª|øx4 -ß?­_•|ˆÕ/·î¹½{’ô‘–ÔdŒş'c„wÒ†­%;@úÖ9
ê\9ğš²ÌºÅhÛ‚oÜ •ƒÇ}1lINFê¬ŠÏ…ÂfOŞ]¾Ë³Â“õC5n£{Ç¶PwG%?Ûw]–ÕhZ³Å±{I”ô<xïrˆçüÑÀ¾¼®iªi·’š’Š½²¨Ç.XúcvdêLæî\óbˆ0xøg¢ßš²¡2¡ÂıVçêg”äßà†ù@×}Bf½gŞ„\š¯¨W!Ğ˜ û4›Ñuæ€8†²Êp/ßhÎö"¤ùltg¨«TvÖ5yåª®½­ë¸A9Ğx„ìZî%‘É;SÄ]IÎ?ãŠkO6—Ù©ewã<PˆgYYbã¿leÆÛÄ¨¸úÇ”Õ' Y»ñi‚ë‚ ßEx7}8«D‹³İcaºoÔTÂH¤C7@áˆ%~/QÏ¬Ìg‡ykÏQZª#øM7Zé"5$¥Q6G@´•êo­=òV³UÕß¾èMx…Š»3gr«Â~ÓBt	{3‰Äæø7‘l4‰d<~€|ğã(“¨É¬k€"õ5Æ£
#­zìyÊ´Æ%OğHÓ’ö×ö+7 jˆÄtÙÓ*Ä‘ıø›Û[ÊÔ0^²#W´¾À>$–İZ°˜¬DQ;7nÍ9ã37Aòhà•J›ÉíbÙû¾ØPä–4AäåipñšÂèQº9Æ“o ç¤ÿÉæ¶ÆÅ9„öu>ğ°lsüy4Î~oI¯T‡"à•zr/ÜLŠ•íLiÕ™|¨… 'cÀ²Œ•¡d¾n³Ò÷ïS-6íüh‹–…ıJö*ÒÜ—k'd¦ò6J¯8e8¿Q°ñcsaåĞÓ»
œN?N„óùÉûp¹,¼–ÿ‰X‘rFV´FR"A¥WrFÖûëª>)<b÷Ôó±#ûMÍÀ Ê'½ğ&ã:•»Ê_ë#p~¸,Lô6."¢¦äÔO=±DÉß0¾PK¬‚øÑb¨IÔ\qU€š]fy/×c¹äµxtä~s'fUm_„IB[Të?%ˆ^6©ÕwéİÜ +L‹³]<méG”ÿ<áÆÉ>Ã}³‡ä¢"Åö8ìŸäf¶³30—oã†.ò×şÄjRµ!ú>]-ynMœŞf@pœîWÖ€[V‰šN2œŞ()’(	¼Q
EÑnŸ<(©ìú‘¤®gÊËR+D_QtœOtF*´d ,ÖüÍGÅ#ÛåØyè ›_næ^V6Í©Ñc[İë_aîéúÊXzµáK¾‹¼³¤@h—è‚™3€‡åSÀ¨ouÊÌàí{¿÷ºõ‚—œğÍ´Îùø @”n\üXèD;ÓªC 6qV!œàÔË˜„2lfX ?>²#Øs5‚X»Œ”ïä^iø9ó‹8Ãq»® ª:f+ÔZV7Ù‡a¿=¸@qıë¡¶íQ$a±-ˆ+ü‰‹xé£*¨W¸o%î^ ùz¿í„M½ŸjbËtÏx\êÌú¸åí—’çmo{‰Ü)ŠŞ8ìİã"`´([ÎO<ûµÃÛsôï0ÒU<~ó[ t8Ëñ%:7  å€‚ï¼ı3qz0qŒNuªóF‚Š“W‚“‡—5mC;°_Ü‘8e¸;”¬c¶£nÙxä#uÓš"<IÈ¥ÉÃDğï¡ØÜ0Dœˆ€ÏôæÈ·5|%f.‡šL>#œ¹,ö­`ê•¤@[)è´ÊGh’ˆw¦ü¼;{eu¸nŞÆÓ…/@§e49TêçLíĞˆ´™½÷BG³¬”¸Ô¶u~nÑÎ@ó	+!ÓbP=Úõğ)ÒäÆ¦fDÑ&HïÄÏªŸwŸ?•ì¥ôAÅ«H}_›üİ
J®_ğ
ªÆ®mŸã r=<—âR«¬ÙÄ:OöÜŞ¡%óOw¶Ì,üÉTÔÂ³¡mı¯2¡ı‡õwç—Ì5RÒ?h÷qHp”Ì+i—iÈJ3¿s©u0¬db&}áj®½ .Q÷]¼wøÌCîrONğ(\¨ëğ*…iÜşŠTYÊ³öœó”-ƒÎM2¢ƒ©òuƒ¯bqQŞ¡±”P¹ëãz@D£|®÷91àœàévdy²t@ùòè…4Öõ4›å-9K_d­L¦ÙÇ(ÎÆ(?#ìNÚ5,¡¿ûô?/—y-BÛt|Ö‹¿ÄÑ‡ò±Äİç×€€³c"ü¶_)•§ËÔ5ú—¯Í	H~E%€’ÜŸ‡J?9níÀŠeK$V5œû€lõ´¯¹™şÜ,†¦şÙà±?‡¯Îiô“)Ş?Ú—Dá…+7aö/=¹\D×uÛlé‘Åy‚Œµví.<6Œş‘ÿ¹ä”×ğOqÍzO»L6±`«éW“ØÈK§[`ŞßgÓXŸ’EØİká1¨_Fı<Gíã-W-Û$à(ƒ!•É*¿mÉXIèÎSmgÛnÑÏf¾âºKN˜å}Àûá+?ºi1#=´³]¨G3ŸMİa,”MíùÈ×Ã
ù`6ö(áD”ñX³¹Dj„épJëŠp4E(×Lõq¶èÉ‰şdXt:¡M™ÒÎ,™ÒÀ“½q6VOƒ{oÈÏl'÷­­,U.úÂ‡¥¢$«eAüÈ]AZXÈ±Ó<ˆ„êıAP›s2…\€²[!·©ë@ğêÕo\îÁíó°^sHæ;'Ò¸?Œê¼v4ö„jÇèP9ìOˆˆN‡İÓÖMj›ò?!¶Å@ôÑÆd$SÃa¯Y(ä„Ññ EogÓÇ:ÆÆÉi GMcİ';N‘&ñ	°ìV‹d:ï¶gGN½A ûÍtˆ'×)€­R?®ÿªê6yHQ‚k¦Å^(üÈÒwïKÿ~{ûÂüç¡_§",>Ô/?Jõ¿‘—-Z;{Pz—7|cïè)ñ ;İ¼°¯]­Su÷^e½:HYÿl7p—|¤€øşT-É.uä·W¹Á;ÕÜx´áf´5)¿/ÎÕ˜îØJ›Kò’×4ÂQ½Öx!÷a|²ø¸ o·R÷\lk.Ëœ8’´2cÖ]ßğ`ì1òg‰;6Oé£¤­§ª^=*Ù‚\b:¡
C»ÁÅ¯{!ı©Ô†Ó…My«P_÷š+Ù¦úlz'é--¹2;\8œª—ãŠ\]&§Á

óêi÷L
Ö‹®-ı+ÅQßÍŠcuåÂzı÷Ï˜î¨³Idáåš*FO˜Ñï“/{Ì¬ã —g’>uûŒtí©B”òğå!@‹;y²Íî-Ó=«^)’–qiZV}¥áx}q’-İô^Ö>Æ?ä“jA§xÍn&BşÿK¯|¿)Ed²t
V°¬cîîÛ ªn†ì1c[+Y9»ªÌ^m)ŠÕš’M2†3\ír—[TÈ›´A7¿ÎŞöXÃv™AéDUFW‘eàäàp°»é#§·Ë»œLü€P~Ê—	Q5ØT&íF·2[…RbÇß¨Õtût€ÃöFÖYn½òR“ĞI
Û¢Ã¨&÷ÂHø$±êèêŞl\s¼¡]Vvas3hxzº´îWPEêI¥Ğ•dyôEü6§Ö8Oš:1¡mïï°T;é@"Ğü¼û¬¾<ş¤# ¹Në¾cx’—x+.ğ´³PÇ`‚ß´»„º·¼ÙÊ’~Ô‘pƒ‚TCKRİÃ÷ÈßÕçñ]'x·ûçŒT<›Şè¥É%Ş7d–¼H)ë°Àª#cœ’Öd‡‡<"%~5±+º|©îK`GD£hÆŞ^\Ñ8Fmø‘(¥c^ÈïaÊ¬ÌL”8Ê`rE~o\]¾`Û¥ÛŞÅ¤MÊfh5ş|6½›æa±1 üõÍ'p(Ã¿MIà¼&€šnUô¨]%FÃ¾E´Å–HNê»½òæ5‡ŒÕD}¹ )1Føw¾ãêÕÖÄƒÉ?şŞlMf‘˜• rÀ&€é=UÊäÍ”"ŞzëœxYÜË—ÍRLv&T™2l¯¦ù(vK1õ²Ø2Ñ’6*ùœ9†Ş™$ñ\Ûª¶²ÆÁø@
Ùùœ‘j‡Ÿä‰˜ô ÃûW-‚¾7ÇáV¼â—{ZÛ ¨mU7Îê%¿Ê»É=˜ÎõK	ñVbp›~F‰âª§;+È!z™D’£ûŒïªT×"}ZwƒœR
EGWGAÙâÑ+ „é
ÛfSñj±ÕNš˜hŞ[3;¯9zĞW´¤„|ò³ÿòVeÁ­5SB	Á;@UºU*¼—
$8¯„dGNëzµ(ùT4ü(4áôÉ¡GhJ¤fÊ¹Ÿ:Â‰½bVåq°ÚÉ5Ù†kÖ&#Z¡Ÿ¾%ÅŠ…èÌ=M&èY±”gõ›Ì•¢«£¼|¿cÊSÊ!{íË†8¼¬P-lß­Nñ¡æ,ğ//:/ÎÁ+ô´bM™İGê`ÂfÑÀÇ®‘Œ2&íöÒ³'M6€;Eñæg¥¦ùx|,C
§ÓóA«‘˜3Ó¾ßuGÕ„@º‚;j#N¥‡rcŸW‘C ºÑ¡IK…‚œ¸ ukuŠãqerõY.a­ÿ¼<+©+Q¦ÈëÛØ-EÍµ„Ï<Rù‚eO¶áTvºôVâ²áxaf E¾w„bôo„kà™^ 0;È¿âèp¿	ÇU~•!^5ü²lUåòœ§do|®ş€–XzFJfŠ-ı²ƒ#A¨˜heÍ ’M.g|jR„âû…1}×_Àğì»E€9üÉv·I é-ÍœÎNÍ_êê ‹phàVlhæªôs†º[&/øS6©£Û¾é=·?‰'ï1>W[ş!8i7ÕI‚wê'JÙ’ƒæì/¢¡G¥é­ëîƒÜ¸ô¸
¢lÈAÆHåW®µœoÉLÅZçô7Z)Òƒ¾„rÑn û÷»S/Dµ‰Í‘f)K+)tğÈt…ÎÇ…²TÌ”í›U†µÌ_
V…–Æi7S~<•Æ4Ã+•”å:pNïu°ÛzMˆ6Òˆ-·éPjíçeû®ÖqŞJExAGÖØl­iÓ•‹&nĞ&éfòï5Ãˆb-¸l7ÔÔ}eÑ½\G³f‡¬Ø\ğ«YˆÚm©Eø™EñÜ£Ç§óÈã½Ç†"îÅõÿ#&Q´·*œ§äS¿Á3’ÇŒŠÇ‰?£Q·¤Öƒ*“+æÔsĞñı$ÿ¾nNÂê0}ç©´åÍÖP²î­ãIÊ˜µJÓëÇœLßÆ÷èÒt›ÂÈâ‡i®œÄAs¨¦	b}Ó5
¥ÿ6ø¾äúªL–²S’Ïõ1‰HüâÛB/–3ñÕXÇCÔïÔ¢0\ú•4%¡QŒ«Ã8¼cu¾¥UMx
üü$ºUsšë%+!ô¿ÖúÉŸ<^‡O<uº—}€Ô'2I: Å0Ë´ÏÍ²:1j¿ÁIúzsèiµ‚wE†û	¦»cÈ¹Dè#*¦A7¹Wg$¸÷uªÇ†dıÙ­x8SŠcÁˆLR²ucÄAş cë¾Ø<ŞtÀ€”x@,Óò0AÏWÁåL,Ro—sŸ-[)ù¤nHù—”ŒûUÀw¡9­XMbry@÷Oo“Æ8ÔïÜSR¾Œ$uÑ=‘é	UE4eEå´òÌâRœåBë×5yâ×¼×[«ä`§½ÖÎ; e<[¤»g€é–~nTßNøÚa:_ÊaøÑ {;Æ¹BûØ=Ú—Jˆ$²Zm¼PÆà„¸¾›Æ?î|A+–%¥ô½.•%Ìï·Ü£qj`„rRÎŠ%^¥ÍÉ¶Å3œúÖI0¾ P©7‚yBŞ‰=´Y–/‡Œ •—6Ac—R{óÔ~{ÑM;š¿Xá€4uq8_yÉ4° •ßÁ)ûƒfÿ³¿p€R…ÿuQşâ¡ ?>J*w"[O¬ÒÂ-‰i®G*”•K®rÆ¿eŒüpö|q"DJN>ƒ.Ô7¿™]7
×h´)è!x¶9sU*ìèäÔ—ŸÛÛÖŞ	KÒ$DÑŠşŸhƒ5İé.½{KŞ§®š)…/\•ıëªzN[ßCü¥ Å_µ“¥S{ƒíÚu¸©ø	†
l\p"’k"<<Kıu}%ñ¦·bó'D'3
ı8
~¿®Ù³mÅ4	™Ñ:›Ì'3‰Ÿ ê’õk-$Xá­DåEz»BµhÜ %ë–ğÑ
3ßmF‹†iVzÉ”åvGo‹Ãó;xHià} ©}Ú@®Ê[(Û×Æ./IUDù7ª·ÚÀ‹1ƒó…OoZ;tØ%LêA¡¸´\å~=5úgúÑÓåŒ¤4‰Öî7AÊÿZ¬L`ÏW(pÄ%R3¥¼[ä¡<aL•’	Qqñ“£ÑÏ³ô»Å(ª™ÛDéÃI¸¨oĞÖÊ­šcGq²‚*’ ö¤a¸÷ 
Ø;r+ğ4Qú”tn¦©ïomú_÷±ĞÈU„cV—g™õÄ|OÆæÕXÈÓümË>Ãq96Ú°%[=”jàQıjÓÔò0Î?òÅ9à+É7`ºÉNUœ$™Eì8’ñ“ÉÀb7û‹PxŞë:Ñ¿Šnˆ{¨äß˜Â{E w(§…ÔavúS¬I¡¤7n¨+’»ÅÒF¤yø¸´“2wşHB1&Í;˜ &õs(Ô!T
øÛ£æ.‹İÑ+Ä”·•„ü*˜HD•7vuö¸~®ÌùÛ‹áçé8{Ãh˜‰¯âÉˆCŠoF×àõ–lGi>4#¶AçÃ_{¯Nb¤¸Ø±ãèijßšğw‰B;ù{¥—#ïŞj	+¸Ç¥Ó!NYkˆŸ’×íÒ*f|$ëÌSZüş‹êŞÙ!Š1ªğ»ÍêÕıCçJÅĞÇqñÁß¡„WÿI±VS@ §¤±ÿn}hqæ™C£ï)œáúT= Ÿ™L¤õ[>úO=…jkømı×ié0|W‡K€÷ãGím¦p—šÑWçïéÚ?¶x{ÃIvş;D¤¬'mÛ1o=´ËŠv à,ÄğE&œ5(pÃY¼±¯O›ÎDmBrÓñÂRß)ªÒçVDÆñuH`cùHX„‡;¶¨~æ"?Ÿ)w—°ë€Ô„|Å„~|:6’é†æ´®¬Ğb§t&»"˜G§~õáCõW¹êm'__œevKŞ=Hnİ…iƒræfkÌ*íJÑâ…"/(£ŞÊQLÓíÃu,ù­€W§©ÕıoÁ•rÄƒZÑT¤ üïzGqú1¹Uw ºù$ ßMïmUSZYóì.ó‹>_:XµaS`á
 sÁŸ‚íÌ¿ñÖTF‹æàÂ#§Ÿğ)ËnÂl>”j}3ÀÙxÙ`u7)vFêîÕÌUJ'Ó´¢¼Âƒ“™`„Ë­3–@" -	-¹lÄ”5 ›Áìè³ÜmÎ`3¢²këÁÛ5‚øA‡Ú¼o,``7¸…)o.Ã\‰ŸÃY]é&!Çi+uñCÉèc$v+(Ñ¸eËé»µÔ¥ôÂ›»“©„]Î9}vƒ‹Ÿ®×ï”wõşg‚¼×%äÕ·j@gã¤°”!n´æ£NÇ¡
İßqÓœ—ˆ‚Kˆ…ğî`=)2cù.`ñNº[S§ºWD(Î%ò<šÔ°ğVJÇ(ê›;»Á™±UíÑOÚ§½<g_B‰-Lù¢ÅyŸBXæìéwßçSóıñŞ»?Èw-· `ğÛÙ<ÙŒpEÕ\à¹+úv¥KEËüm«Ç6kõÙI•í’GàGÈ€VÊ2O—•åd]Û§tüÂ!µt‡"Ğ½ı4Hc¨–[Ø>’4­M*2(…ÌlpìNĞ»äAÓê—é|~öÄ¨c©qm^~ê5Ğ¬Ë-YéÄ}§Ó«åoñbtêà_ReaÏÄ@{‡Øüÿàî²guÓ²/¡:oÌwoƒÕ'ÃÊ»Ù…øÂ·z…jµÏ‘‰4)n=ÖRñ)-•lwdûë»>MŸ« p€øõÉí³ÖÜ„ArX+¥B6—âl.5Óö¦ÕãüŠ€%óŞe–#ÁYåôÒZqí0çŒ|ğp•ª0ÎàƒË&ZÅğ$ÿÛÿl+4İ,½`M¸[tëÕFïİ•ƒJ~Ã(»Ä¼­<¹{ç¶›Zİ"Š9c#X-L iéÙñÔ97ÿuå2“›ü…'UŞ@ÆoMÏcæÀ>Ô’©åæ¿W<	 ^l}OKÍ(aìó°­´œàtğÒÏVÍÓóëè}i´	0B™›l7M¹ÌD,%ÌENªwg†	›¦Í[¬Ê/3Â¼mJÈÇ¯yä}ø"K› ™à?5™ÿT¼K?Ku÷9¥	ªæL)¸_×)Gxã­xìÛÂóì?ö-aáİßŞ_7pQ1?Nğ&ÙŒÿuüT|ğ4iĞÃûíàÌÏA™)½ÆœV9ÜÍO.F+¢ §ªäßÑ÷ÇICÕ%QÃïJø$¡/X;)•Q½ ivgè6ÊBÎÎ›*ıº|„ü$%Fîı½Ç—5Ò¹HÈ[#¼ƒÆÌ~¿¦èßjŞ¹•Ó>ĞfõêA‡Ræ/ğ°™5—ù#x( »k¯k´­tâ ]ät3Ú•ôväs¾a¨ÖÊ^E0¾,¹æè&2ÀÖÜ€‹÷-™ƒ¾êO®ó!×H®•›]J[<7bÃUÓYÅí©Ñi(Î›oÚ1zõªq¬9ì‹7k©dåüÕ rPÕÚ°n¬2ïÑ#Dås@ >8æœÔÃóàÓ¸wmf’œÛ¡`>ò98r†çT@ R8!§e{ìûbû¯.·u ³‘ÃD/~Øè:0<ø?„P²‚?¸½’Qæ½ğYš€ÖGLz•×ò@ŸSk´W~ç‚p0$¼=ÂB×]@Ú2ö¿FVÉ#)†µR—İõVÔMö¤cÆ®éa37¬|&¬{ŒŞûmvõÆãÄÂi‡nŒ§w•	–ñìXŞ1>Â¸ïÙô¾Ö}Kúxm½›Ú¢¿½–f«ÌfJZG
@‡¾¥„¹KŒ+˜øØùjH7Òq½Iæ&ÁaUO†–â¾^‚>°A”‹P©ù,®VÚ‡*„)I¨ñoL°W²`'½Æ©)øô‘®æÖ®k„X”^.k
Ho¹¦ıæºĞCiCur¤pÊù3~`jN“›¢[(¿¹Ã&²¿L§iZÂçÛ¢%‚l`jÔ;å¨s¡#_ÄåNĞ‘Ğ·}Øh†Ó…*¼ÒĞŠœ¶*L]ª‡HLt:‡eIZ²4)°9OÊ±5e™¡ÙÆú’ÿMYúx=†ğ—Åo5zv‡us{%Õ |/âÒŸÚèbŠÌ&’ı),oâ= ]©ƒ,&Ş³ì×Kí·’šÙQeké’ãd o¶H¼3dÓ…€yi’CËqoÈ˜u|CA‹2î¿°iÕÕtL7¾ÅS5ÈÕH±Ê‹có$¸L „~ñç;}sšÅG†,«“æQI¸ÕLâ†‰àÿ!+lûì	.2¤
yR{›§œI“û¯‚"‡¯îJ‹UU·rÿiùÈÅkˆ!D<>ÅÒÑÛö¥qÒíõnRûøÜ WëÈFZóçÁ#§Õµ'Ì°¾ÄBP6ú"½¹Âš•:›ª÷Ãº7ÁªszSúÜJÜ¦ûÚİn§uTU’¢ ”Õ\sÿ]©F¼8zY-÷ZLe§LœnÔ¼÷K»×+PıVNĞ‚°ÄUŠåj/Y«¦™ÖF P[aÅlïõ0#'•Óòrö÷˜×¦4ªNÿ‘åÆï_ôc g¥@™¼ëw‡
õ®ÉBçør«ÖvûÓaçW}5é‡Á¹`¸Öt("û'ûû>a´½T1Tš;ìƒî`â0–Û„çû	µQìO©|´M^]{¡§UokêáA¿a-¡»ğ! v²ä%°QĞÆ±µÏIV'=±&L‹r‚#[m¨¦èá_tÀÕ˜û¯_oÇz ©»iÿ;iT ²§A›×3TvG°×'!Õ)4ÿYB³„áœî*)¸jTcæT­%Yy¹Ãy£œeãEz}†@b­bÈ1j!]VáB1¼°¹W’,xÃ‡ùlèe	â-–ó¢øb?:ìóxîĞ¸ÜØÓ[%ø({Å´v8*>x‹m 8ürz3ÈbF±)’ÏP{·0%¤ s"!äèNKL¼R	ó%R	Ò<[Ù9?ˆ´adƒ¡AµP¡Ò\Ìm«ìİ×¿åêb–Ÿ’Š"çíSĞçÏ‹—r¨êÔş•	ÿd±P+@úœ³ŒW™ÆĞNüÌæ¿P`÷¹`#LğI£«*‘wÊ°ó;K¼)¯½Æ¢õÚ§…“Í˜!÷9W¯¾„s×µ³ŠÇÜ¹Öc²†q‰ÀKyy¹Áş"öQŠ;êØo‡¯Ê­mÈv!ª¢p¿ŸY8É«z›¦µ'– ÎnyÑ¢¦Û:a*GS‚/=ÊO#k¶‹÷±W	©
´¾nƒ	h-–ÁoQ~‹ßÿ‡%ñhŞÑRZGêÛ9úWŸ›h‹¡"Î7:ä‰«’j”o‰ò8ÔÖôûÛ(ıO(E©—ù±|ôGÃYÊ”á \å-±\(M„ÛÜoj•¹tÓõR\ ¶ÉJœ2(mñõˆÍs*•üv±g)Îpìi€7PÈ+²~Ã ¨V)¶şNqRÖ#ñâÒ§¨’®.a¡äÇˆ‘g4Ä¨Öx™•(e¢®Qb¢êÆÕ½A<÷v½ƒôœ†€Bv5ÆN@ktæİ
İ­fS5î‚As[ïHÂ7t…Eò^dCæYÅ‚İŒp‹ò"üËn£Úì£ÀÙ¸¨~Ê„ı+½F=¤#Ï¦·m^4çõ]‡nÁÓ Dyô4Ù#Ï×Å|Î³ áÜÏínL?ËÜÒœûø.ª‹œ!#2Zgçmùuá¬Åy®PŸÊj¤øöõÙh×¥V9ÜÑ	G¯ÅÑ3.U¡Ä}×‚j[­–Qe„M³d†@a(ªË‚çu$ıŒjO\ãøÔ”SÎûç¬˜$¨Ùiq^”LL*YPw¾§¦\&*á¦àÍ°4§Ş`®99Æ|L[şÖª’Z7’ßf)øw.HlŸ‘¶‚ğ\ÍobúcÇ¶ò,w’Ï„âMŸ&:Ş\©]ôYämq-"kX*¹Óîn=Sm£e}!ú€çpÿv,5u×}2ñjú_NsR/…ï‰ó{ÖÜdğ/;’Ã.ØæÜµàÊ––¢İx…Trª;Ÿ\æÈ"6mí÷ì-ª‹åìÒ—OåÀZëBÃ¿ìK÷3Ö¡Qzpì-˜Ãòóh”Ø~WiB¯ËØ%ªf‡#ÀÖ@µ±õî·KŠT\s±O×sÉô’7ğÚî«€Àı`ë"‚õ,h¶ÚêÀÖ÷Öî‹£¶:Å 9ò¤L>­Øª"®”Ê¬ØÙ5IúŞv?X·‚Ìcûœ0ƒÓŒÙgôÒKÅtï[Á7Î¹ŸßİH¨DÜÆ]Ï‡åÕ½:£IR!s|¡ô´.ø^Œ—QÍ„dHÙ†a7©b 0dêiŒa(µkdt‹““æå‚!Ö ĞÙŒz”&«ö§®ç¨¼¢˜ñ×§NX&Bï%tôg®yê›Ô=Ì$«ÕålO¸LÇ‹#X+¤çÇëÑëÖıöÆå ¥D‘ºrè98|N.Ò ÇÀ/§£ƒIŸ³=#tA7Ğò˜½˜g
ebºõñ,Üa°ˆ}ÁM>ÁÄÉûE@¢<tÈ%50e0Öc¤¸¥§¡—FºÿÄ„U¿T)¢œò$GF†éu  &EÓ¯pe·+çÅ‡ñ}#AvÈş÷Ofwû¹KgFÒ„™í|…qx7*Dõ¶Ø
961Q	ŞíÅ!f§…+ÛJ­Ê’²î©vŒ	}_…ò]¿.€:íÒ«ƒÔAFyGwÈ•ĞˆOë– òôŞa»=?ëz›ldqøŒşÍH“@É<ƒZõfV˜š_´ù§Sê²¿¯W,©_38Š.®uµÔ±nl)vU 8»@)ì®>¶ªvcÍ?U†^Îæ½ ˆƒÇfÛÓ;Vw%a%½¸á¨õ²ü´…X/ªÜ¤è0»![¯ãbŠ×° iojHm¤fÊÆZ…òe\àÅ{":CÄ¸2H<ÇTé?ta·@Pù“Y!ïÒ+IÒ1úI×ø>)„§·áköˆ½D”üÜT?=ıÆ¼5¬äË"¶’Ğ]¥ùåc-ÈR%˜¯‰ªÖ»?YPŒ–÷ˆ3Ï©æ¶³aÊ¨CcßË¬@z²§k‡¾dÄá¡eÀ¼ÚÄÃ7ƒÍ²&>ÚNpd.1n¡‚¥cúˆÑ’¯v<SÇÜßOÍ=½´ÎéïÑ–Ğ%“õ~ò@o|©—vñ)»9¡=çÏÒ@ËÑ¸érz\!€	’éz±H,^§Ï°[ÒêÂPVu<³ıYİ“h¾ÆX*“Õt†ˆ!u¿À’ƒ;4ûd¨—¦‘1
‹sğ­¿¤t°F?*ú‚]+Ü«¿Ôë˜ãZÇm¼6=èŠû­\y«1&âõ nÈ	ƒ­ñ¤œÍ§\â.û.ŠU$ôQÔ0Èö€ç~^t˜Şûvwë	ic+êB}˜Ì1`6 Æ"É(E–-%-ÌkÅ”q4ÕtIè ¡!áô‚e *2µ‚!×‘·`EÁYSc'0Å4ûöº\0ZPZi€úõ`@«¾‡QRzµúg‰H’£•í—ia‘vl°ıHlÂ“„S^dw“û ù&i|à¦Qâhğ{í`!1–ô££‚NğoåkGwß¼à¿,$à-ÔÎ‹ÀÕ+~¡C{>Æ]ßò„Ú©0ì½–xôÙµÊ(Ô&ãH¾ĞÔ±ûô*úÏ©›i‹ˆa»ye2^ÜÅéZ‚µ\&q7tâ±ÇÏÄœü?v‡–ÍÍ}‹²cyh ]#şËšÉ48Î%åÚXB‰Úù›§3¤—?fá™4ÓÀ‚ÑÓ@'²%ˆ¡n}¦U¢•§İ>æ@¢Î×éøğ|?	pé¡Ÿî‡ş8†œIoqp†‚ÿœÛ…bÈŸàŠG’Çîš‘Õ˜{ĞılŒqu¸ j¿­xĞ—û†yªÖF_¨&)k½2@)ÑöÛ±â7¼‹ô–ÕôFüŞUÏt¡ûFóõ[O¨„B§^ÊÛ›VìæùÛe¥]tcìƒË>Á FÎ‘Æ¬O*¥Z/ş«µÑÕ97×¡ÂS]ùÇ’yfş%^w©DìÇÄ¦ø_uË¡'}EkÕM_v*c¤°°ƒ±Yâ7£<šn*ÕßNaÈ@p˜ç=5[N…öëèB]!	ùD\7Ë¯g"¡aÏÙüòµ½) &#òv2Òooƒ¢ì~ÍõİÜ‹"ÜÙV’KÃö& õ}»0pDƒ	ü–Ú¥Egç©ôëuç!Z`r‹îU<ñôIµĞ³Î‚ÿòó·£ˆâw¿úã\˜óô©ÉjIğqy|šX7˜”ãXT? M¦›' ï_yÙ¦ay©JcôæãË¶}egíŒÙ4P)ìu¿ğ.‡nU-a•åò"Ò3Êl|(õ3>8áX”òiå\ùÎRşzë½8¬ºíßû{œïÙË48ş‡%8*Ö›œo¥n…À9È3ÚHhcüæÇ\/,ë.y5İbFLÂ¯Ø3ı3Ére†'çèÁ¡q—fG<Àû=ZSOºRKİå}TÙ¼­oU~™)ÿ0ôá©A³~€å0XÕ_ÙB÷JCü;½"š‰w,kàÆ¢>GøµĞaâ¾I'S¥Õšè`[S+He)#¡W'÷:èDëaOXv*†İw_üî,YZ)ãY´@:`KúÉ:­€3¨ô3Ğ.…oÑ€Uúí.ãº€÷¶©¹£B‰ßÜå“‡ ‚TÈå Ãİ¥O›$ÉOˆóP¯BØ‚ÈåÜ*fS;É¦-|p"JåsA)	‘ô±«€4AMj‰,¦7?TyÊÚ8ğæ½fÈ˜J…oÀÉS@Í4Ôuç/ /®õiÂ4É¹•³‹–¥495’Š3c;Ò¾ã:¡€ˆÉàæa''²¹,>ò…:ı¸÷;N‰³Üîu‰£½ÿÖ*Ã(&í'É‚Ez‘"†	VMÀ¼\r­""^¿U¾g£1lÎ}“i­˜ê/ºt:.—©ãº~>ÅwÙ÷(pR9ÿQ°c‚n0İMıõœ.™ûP¾¬ÕV#é…Ş:‹Ca€Ã“rä\0.Êº†Í«#è­ŠnS(Ãã-m‚‚àd	ô=äÄ¸	ŞÉb¤y!¼:ÀÎ¶ÉÉùàå:MµüV†Ä<ÕÕ%˜Ç÷9öK;6r.‹%VÅuÃËbU¿èC=9¤1Oîÿl7L¿åIñè¢µ»G<)İŞ·ÅÏÿĞùÌÉXƒwÂJx°³JI!±ÀÀ¶-ÚüfJ”ÿØc.h§ü¥uAfÔ‡9%3jş™³éå…øÕÉUŠ?0‚›µ‡ü+¾¡C ï¢@ìa"ˆ¹Ş0+@“ïbyô0\ö?o×ZqÏ¤1$¬Ç	ŒŒ	¾dƒ¼¤üÊ¤¡YÛ9u¶£*¢‹Bğ³ QÙ°Øœ;Zm|tºª8F#- øÇOLï% Ó’*øØI|Ìš»‰»qÅCĞeİ6u P2xS”!<ÔÀÚ½N5¡ç1ñÔÇÄ€Ylésòà!o2Ú=Şê\½1ã´¨k¢Ä '©cpNgà2‡7—ée:ş#	'süz˜xÇ¬íUqe4ã¿Ÿ¸W±ÌÙ9JçB)nı×k~w[ó÷LøÂÓ|ë+ëTh¶º:<x“”-C¼h³'§$Šw†zÂ]ÔÆ§iƒÇ/¬^x7_ñ´#B:>bEMoH¸¢ßx:DCP(—»ºªóxàÎ‚ö^×+>—ù@şÍ:èógPâ&Ü¼öF”FK´¸aD’¡o° ãã¦)N1jáŒzfïeJê ?¦ò˜|ÌÁÏ"Š%(?´fÆ&ëD¼¹(hQÃåëÉ³ò-ñùÏ¦}t3óÄ¨¨ÚÊaº\Ô8\‡
ÈJîÚÉùfıŒV©\ÆœásdŸÀ)ìÿÁÜ¾eIBâéøŒ¬á{÷lZ
ŸïP~ÿğ§R>ØPíTqãĞe†´ó-‡»ò˜QDªoıÆJ“„‹Ù‚8ÃuÇ(ˆ*ÎáÎHñtƒêY¿'³İ¢Ù£EÏğœaûŸ‘¾P¿ºö$“"²Í%B’Õ™?\¦	Ùí%P.Œµ\ı“‚Ådz2½>Í¬½İàÔŸöê³<	Ë}›n²’#aµW¹º:bÓ_ÙNşp¹˜æML§ıd¯<İöCƒÜi0]_ºE”8¸À;+ƒf«ûBÛ yğëf¼t\÷uËÌ.á[D®B¬$çıÉFç'iBÒ78/™—©¦v’èO§já*ßİö%lø¡v!sB.ª…Sù¸#<´ÊQâ9ÉÎPYS#¥Nû©4Å? Æ$ëeE¯¤y¾z1ª¹œÅ<êò¼SŸƒ‡¶î\¹ìwÒşmH+jEŸgâ/ê!_av~­myØÌ-k WĞZÌî-…Éwk†‡6åĞ”c¨z=ó†Lw»Ì^¾fuq†Zä*rMêã+íÓ«yàçäaÉh©/*X¿5”Qe7¢áG=†!í£éÊCÂƒéŠ¤¯¸Tûß-Ãµ€9f"øÇF!¦ÔÑ69Öú‡îN¤51õ(ÀıU£bÍ»ğuª¬²+±‘¦Yô½Ó»~1©'&tCfîèZ‡êüú0Ò•Vb)tÚŠOıöÛ ”,ÿ‰,§£N7ë„ÍÇ'YØúl6ŸÍ€.¢‰ÊñSäïQùM”3Q‹=–Fšh${)Îôêg`a‡gŒÙœ¨ˆìjV,ªşñd¸û­æáX6ƒX–¬œó>ÌQQø›eÀ÷|,ü4—Ü'Å¡ˆÊòªÅ ~éª÷m[ {t¡ÂG'EĞ|dğ˜~ûğÚç*ÊJE¢?™mK‘9,ZÒõhœ0!fA±â§zfJpÜgA7Ò?ıßZŠª.c:mX°m¬4¯Ñ,7©õŠ–yM_•›oôp){Ô(Ú³ÆÂîíø~GY@±_‡röºgç>é)gk?ŒEŒŠ{êÍ9€;Û!;¾ë¡¯8ö}‚—u; bòæ.¹ø|(Ã:B‰Å+ªXßP{üÆ³ÕqC´›+‰“o’Ò­å]wËu7¢¬%¨t¨6<jzÖ8‡úqß³-qpnıd‘Áx,›”!] ñ@ìÒ©b­¤3üÆõ²Á‚±FuRºIö_›§å2ì(Oí¡´ GSÂÌQ)dÔ/• ³ØÓÀ¨	Š‡4G¶(‘¼Ö	•Òjµ3®¸"Õ:}Ÿ,f¶4Ÿ?œ;V·’»q>$zÑu:p~àH"z21ü¡ÿ{.íùø¡ EçšW ğ$›4á§Ø
u=pˆ9L'L~±ÔR‰âîrêó>ùÏø¹EÔÇ†¡ÜxH4i(ieã¢çæ§&±^'ÿÚBÇöR@d1“Å5ˆÆµ‹”÷SZû —¿ÓlWRdJÄ©‡æN[++IdÄ†xÅø+¼4
‡"Àù^ÒéÏ.Íè•W3üè&ÏÔ\L“øû·hqÒ à<ã@E~¶ŠÑŠÃºJŠDà^z9p	(ÎÔ³$›ñlèàîİ±l¹ÍR^Æ¸³¿ì‹gb¼u
òK3nÑÊ—ØkE'uöñ‹‚ıcú™‡éop¶°ó`¤I-£ß%ª M<QøZÒEö›¥‰‡<QJÙŒ*ŠF°â/ªKä@ê“é˜T+$¢ßú?ƒ„æãn9æ©½J¼RZëÀq§P	ÙpÜ{éİ{¨eİ$wXÁ–‡È¤0Å˜N¹
æcí-;K¼”šÕ+ëë‚otc<.ß`
?·çãclr¼3BÆı®ŸZPÊTXÙÃ>7·PÛİ\ÔÿgøG’ôíp_ è™&ß–(-:…«u—cvÖòB÷ÅÓ³›d!ß–TZœ;¹AÈŒ2.lŞRrÀvíkb»`H"9Éa"¾wsaĞIíA|{VŠ‡rífÓøE!M¤}¡å©_æTq{•äC‹ˆã,`Ù1„ô8úmß¢ÑÁ‰åÓV\Ø&1w@­+FŸ²qBó7yJM[#Ğ¢ø³z‚©ÈÌp.ÛœNÛÒÜõœ27 ¾‰v9T,“ÑÑÿ‡K†¡Ç}çªİ2›šôåu$Ò¦>hTÄè¹Gy½^ÜV¹(÷ß5d°­óşş¿9ÂÅ»D7Ä¡2?Z§ÉünëÅj;Iõ¸¿à5Ò]ÇÏ£¶FSƒ@QÜ®:„è¼Ö7V¢ÒšoVorÂ&98½Š÷«ÍçTøxØGÛ×Fo­æö‡
LJœA™Ääs!z¸I7zº{³¨É÷=4Æ/–ó}(âÍŸİ à,h^¿œ=¼ş «7œ^Ò­®Î[wBDRºı;é`]Ô¨Öf¢£¹7’×1ÃN‡óöéV˜LÅeÃ˜Fti:ıÏÒõ±vXY6ÇŒ/¬fÙ¨ÃàvÇb5e¹:yì³«Ñ4BÛeT³–H'x†=+/÷¾=`Xnû$Å õwoÿà07£©7¼ğ‚Hª<¹9a‚ÁÆ¸š}‚”Ú™Rğo;lËî)h´şß³Ì—‰ì4“YówpîÔ %JÙBór{x†×}­-+C’~GG#›à?*Ñ·¼ÚàWIu‰›®"Dfˆ€ 0ÅØıa
ºˆ4ÕÍn«&ÿ<´©ıáá=eÇ¼Ö\¢ÙİnâÁŸ(ãÍKÊï{«tAº‚|HÈql?Rµ>—ÀË"òÒÁŞ«Û¯Ÿ‘Ü'F4NLƒØDls¿Ê—ø|©*™½É©Ù·§?ñ|¢PüÉ=ú'+GÚ±»
u
Şÿ¯@IA¥ íÜ%%;ÅÒ´Ó­aÒFcAY‰³´Å?_õ‰z–âHÆ«@:îÚ6è·³1‘íE%ıB¸EhÓüHºbÚó¸?HO9´ëpT‚5Of/“ÍÿU5x‘w´ ,‚Í¯jJ¢ˆ@"K$e=H÷ÑnÕÿ´¶„sY¬,Ê	_Gk3·Y¥ıM6c&ı	¸¤á¡ÒÏ¿©·öÎĞt¢$¸ŞØGä[`gô’}#VÃow}´X’Gá Xç¾ü?@ğº‡³£úGjÃ°KNß™ÆK–
2*ªxf0.'»W`Ô…mŞ¯Ô®«Bİ¶N™«É/AÜÏmSóÍ_Y†ŒÆø&šœéÅ¨º¹˜şi‹,Ñó9+HµÒ
IÅ¹Ihn&Á¬û®œ'.æï[=ª¿ šîóg»´€òpnÇZŒÊìzü>Ïbßœ\†cZPéïÑüï‡AUéi²…ÛPÙ‘ï5Ó´Šœ;y%mÈl+(Rh‡Ÿ“>Jx:ıB
”Ô25«ÆTSŠÒ3€I_ÀÎª`î%åüwa*)¸‹È€?X[Œ8”—{ß‡ÛG²"¡ö*FÄ.1z]aÓ*}pù–ScE¡äğIîÕ–L[~Mın-ïódç{+2—Z~Æ8}v¸>ÃÂì3Á©ñ·9>kñ|1²cl9Í¨ÕÓ×/ŸüƒÌFJ47pN
#‚çÁIE]» ®Øy]û­ÿœ´ù½@êg:!÷Ô;ÌÛ7j’oî§ãm ––ğè$EœÇrkv¥—ìD±‹ƒk7±·ª=uÈœóëy½¬TÜsR¯ÿ«NUv,ÃÛjÍpM›vñFMÁÜÇ9°ñŸ‰G°©5€¸ğ1´ıèÖîàÑf‰'ù³¿.ß1TL°_˜¢äBD{Ä'ÔŒ¹jT¸Ã	pO\Î„®{Åh¬ËŒMòmZ§=®×!…táˆÅÓRµOÿiÅ¨mÊ÷3áb‰Nàw ™£9¨éé m´NGH˜°¯ ©E÷œeù¤Ñ„ä{½f”Ğ¢­”öÍ™^©Ş•Eèû d¿j-;²á4Ûÿ<îât!ODÑG°4á%›|¦$ÙÕ%“şÑ~Ønç ÕÖD,>‚¼÷Ğh!ö4‹õ”i'ÑÑIÏRûë˜pÀYbÜ·ı¬z;¼-À§#n˜¸{@ÃÆí^yºƒ?;íËü›B©Ô¦aVÀèºŸ@~„Å?~@8èåC´eÆ-¢‰Z¦ÛH½º°¸X¹P‚€ËR¨İ…Táy_.í7y8ÁÜîİø–¦LÙÎ)ÃQá“ÄŸ¢“£yMÕ•£¡Âs¸¨mšT?Ø0Š^¾[z}ŞB)æA]Ü^´bÛÙœ‚6uå²	ìWCa	uåYì¿/;­·Y†ßö™køD¼<¨İlw*óàÕ+Yâ§F©%_<Ñ†™Jv),µa6Ğl,æİX""O”ÉĞl-®œ•	£fÎmWˆKò‹šİÎÉnÏê65ïßd2T¸^dpÄ,€S+şàjVB±*r_Q„ê	yP‡ƒbÇÃd@r¤üGˆü£QdÚD|ªnåŒƒ$ÎÖ—’æDù'¥ä…	Öœ¸IÆ€®);á©­YÅ=ğ’•Ôæ>Rjÿïfi/F,ØßÉ]Ì$Q*L2ã,İâ­åO4L%×;3«”4¨åá¹°Y(Ç‹i‰t¼ì"¿w¥h2¸k
;DaÉ~·¨…%J‘’9°Î“eú‹“º^Ey×3%·Ì„zz±3õ£	ÒS'µ%Ÿ= ƒK2’÷o×fÑ“8-øÑI³`†•²÷ÙÜÉzn4Ë’•Rà­g†ìº•}}+páÏÚ³bmj¼Øä¦õG†V-$."–£É¤ÆM¥ïÀË?˜Kùu4
¨GŠ°i”/0íJØ1XÚÜCmuìû²¤âÉ3BXGŠŠeÂX†¶#¥¾º÷&K˜ßO{[ÃÛzmOğw§ß¬öbwLC ¡}}G ¡LÅtEeÅ ˆ]É jæ;êÃ3*·ØN"<t‰Ÿ&\)šb:–ìæ.¾)UCD?9M3zƒáş"•Õ
`ó¹¨Nd¥(?ïÕƒs‰ÿÕ3lñi\›â	ÑèßÙÏ>V¼ÌXŠ–M+ocDÏ˜ÇS?¬E-êç¤û|‚~_(t„`HƒÃ4ràôaz {¤ş™‰ OÌáà•KÑ‹ÕLHÁD6·§7ÛfŞ³âEÚeˆ_U—fèX™ÄŠ]Ağÿhˆ«ï¶Œ13vßëFì®²(±ò4
ÉÏ‹EUóƒ¼–@¨­1ãÉïêF=0Ì.‘)ZÌôäÈç;æ­¿À½uÆCE†7÷½e™Ú­4?ë‘[›†ÒÿfÂğc7ñˆÁgbkPö|Ìú,ˆ„”¸åÀ\PB›U5ğ}I¶!JÖ´%2KR©¦­K4DÈS9OåTÓ½«¿:ŒÁZ;üãH¨Fü8¨tAæ{öøÍ¹ÔÏ‹!Ác4°náÈÜqóqùê¼;gu.Rïìé‰Öá…ê¶9´®õE£ôl:±×‰lèÑ$í3¤N~ªE Ï»"(>{³^yÌL^È£<µŠY‡ût\²à–ZİD7Ç1ÀZ÷„UpÑBÜ¢2=­ÈjÂ+ó‘IÁ…µ ÍØÌ×õEƒd²qÊòàÈ®Bs×dvEptÖ¨¨¥È€bœ¶#$jß¥id«ˆ<qŠ1Gí˜*v~É%×æ¬Hıû;©‚½›LR*ZAÔz&«Æ] ·†'ª ŠcŠ<á¼~õòRÇ}‹l/ÁáøğbÍ‚ØÛ!Üx.ìrŸ,»Ÿğ«ˆÊvØêÿ¯8€[)ˆgŸØ¬ÎA•¹bx_¡ı;Ë	qQ°ß¼¹äÆiBítn§µ¾j†¥6ºÏXl_XNµÌÌiSX$…®åDvê›>å¸ŞCÈYËÀôáê¯; A„M4»…}Ë0üÂè§Àt;rkì-ÕŸ8iYeÎúÀ¤ø%W„;Ğ’}Â4*¥ëâ~ôkÀÄĞ'~G ÍÓx~¯¹ò›¨2„ú?Š{ünªdE›"ûŠ\qd«ƒ	/ØÇ6î?˜]³ä³}	Íx¿=Š½Õ5;}ÿ.eûK—WFz‹³’¾F(Fİ·Ãû±æB[Hd¹{4—Ê£;)=…®àôš„ñwÎ•­<’•v‰Z;(/£4±ˆô{º¼*ù›´Àî|r129åLqÅ–šßû(Ş£Gãjp8Iô`G¥äà/z>_üÒ€ZoÏÌ9 +ÀŸŸZ¯ªÌ]'XÓ”ÿÇXt¾»‰ydœ]”ôğ_B3
åòù¯zØ	t,&¢+ou‚½\‚H<Ÿğ&AÖ–ø¾ÕVoš¼íŒš4´h®hÒ¬Ü¶©Hr[®¸›XÚbÒ©jx`J2:¹t¾,·—ù¦§áì»¹óû—\lãr² owƒ‘`
öç@Öq5î¬eè¤ŞB]­‰àäÿôÂ"Å,H„eû6Ù¯Î&`
èYs‰ÂÓ°ú9?Øƒk8q ›9g|èE÷d\=	üàYªM5NÇÄtïÏ<ë`¦]²@îéG§q¼¸&²”–ÙæKeá¥Zd‹sÊ-ÉïëğzêbMÀ?/[špÚ¹3™?ä&©®%Ø›ĞÏ*²FÍ|ÓB@É/YÕ¡á¦~ÎÑÿEQfL¹*\{\ï¬'xù¨œi¼AÜªÀ5ã¾É5_îìê#•ÿYá¦Mgêêƒmk`.çÉö$åP+pRpoAî!ìS¸R‚†ë)–]}OQO+t¦ù\=€ @rlùŒÛlYq¯ƒ¯ACĞUÕ I_©R{©Ÿ`Wt©õh/®ô©/Pa«É3mJªĞìµå£CDÉÌ±ÿ?T¹"ü·KÓë°Q¤©EŞéb^¾%´¾³;x`÷hº_¹²Ä¸ÑÎdxfZÿ™â	ÏúÁ¢‚ßÛ=3[N¨åJ|·—Rk!±-ÓlR=5{@kĞúê—Ø‰°+d]ËÛÁrø÷GÜe¦Œ‹É{ÉÓkâH0W¢‹‹<a¥yÔÓ¯bn8‚&o‰ZN†\’–)ŸeÛ”µ)ØxvBqõi=´İTUEóÛÁ-ŸÅsùïië…9Zó4‡Lñúzˆ'ª^/c;¥]‚z<´¨‚ybv"SğY	`¬hìèiÍ¾{¯Ê:ˆmå/İ(;vè®Sv)³†‹¿aO³­µ
°—ò’øë-Q]’jùQ¸=owYk¹Thùòı¶*µ g¶s¦åèƒ	Şq<;äÜYù¾zõWĞeÄ¯Ñ<s° .dµ}åC ïØjó6v©ûõç»×¾Á¤S”¡µ;¹N°< oG/¢ë\íc\²¯tL\IâŠş$<ã …ò¼rç½±(úøZt'Ú‚Ëg/3£Cùˆ'vÿ#­*[l¼jJ®º¤‰f‹ÆªoKn¹¬×,0tr2á™â'í°?IÑ'Q}ŞùghÙë.•íºÊĞ#ÅÊøèŞ|#pL¾šı¼!ÌÚ+Lœ&b ×ÇtSL&ÌÊÚïuü‡Ye‚¬2ù¬F¨ÇjZÚª×édF$H`ÇX©'š¿¸ÃÊÙ…?¥|È9iÑšğ Şˆ_Z‡÷GÈôKm¤j=ìğ©é¶gzM˜/FLKÂ»T&·Lƒs#–ô³Ä)>Ò3»¶)%9‚AD÷Zw6›SÇç¸~ÃnÀ")MI¾.â‹ûvCŒ–)®áÊä’]¯O*©>Z¡úäP´0¥Ô:ìØòb‹©ş­W©TÎ±‘LFQ&>tƒù¡ƒT-ï¬i[M@¸.ÃÜæeåù+‘‘¬ODØxÛ½ª†Ô~	›£·PıÜZpÂŒ„êêûÈ±ôV#9yNôC
J¹îNğ&?‚=ºˆ› jå|ZÇè³¥äa-»’ŠùCÚ[\í'x»â+Æ~‡ş©ıf,§s>%yÀ÷UK¼IÅ” 2Á“mXks<àä3è*bê¹É dÓÌh(j5ûö®!_ØéVÆ2a~½•è¥‚¸Æ	s q,§œg> »HlØ€PØ{ ®"D™ôfåWŒšSA &Çgñ²+ÕÉU°ˆ·/&KŸ˜âĞçpš›üáë+B$NKxÚ€   !€(’eğ Ò¡€ æº	Ï±Ägû    YZ