#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2775160203"
MD5="510a8698d2d5b1f6a5edc6b485ab2b91"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20564"
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
	echo Date of packaging: Sat Feb 29 17:14:48 -03 2020
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
ı7zXZ  æÖ´F !   ÏXÌáÿP] ¼}•ÀJFœÄÿ.»á_j¨Ùõ¥
@-3~f“úöğyË·NJ©pÓN€CÉ è¾ş š&6Óİı›e›•’´’¯´ìú­Ğ4ï%'¾Úh1ş%Í¿x$ûH£‚¾MñÂm†íÇX|³æâ¶÷¡?zÀyÖ 4˜–d94wuên4ˆÏS§Öã°$ªLdú~ßÀ‘p›6Æ?¦"ü^ü¨ï}õT©î}öT?mşˆ}àSR×ßÍPvYÏgaÄóD’uª$)u.~Š³IÒØ†û ˜ä d‘ëòğbRol5µ´×€âğèØÊ4iJ¥úU»Ù78ìÈQ»ÒQ$umÃøƒ1~½¡ıû w›@Zo»øs*
Œ@ßlë>Ûû®h·k2ıÇÃh¢œ/†ÆôA3³].`ÙÍ ²GÒz#Æ´³‘Ó¨5»4Ç+¦îXºşˆrb€ætlî%
ZBÉ,I|/1øAÕ¿—@ˆüBjCı¶‘•$3™Ã Œï)y[|> ·µĞQ…å1Ô9Ú}‡8^^èŒ¶…µŞ›Ü©ø#G®ìúE@-5ÆS$É!†ásò/¨q‰Ò‰0<_cŞŞ #ÂMn°ª: JÃ#¨rˆçåŞ=}56údtÊzĞîv#D•ˆşRø±w¢×+£KËòab'Ô‘¼"ªú’ëÁ$k 	Ø	dIÎx¾ÑábûËşÑ&Ï¥¡©Òß2tu¨…0A°5µóx¦‡S;	w—1ÑîLZí!¹"Û+å˜µ5ˆÕô³ØR •¦iq¿NGJ»³i£A@V&ÆWÜ°Û»KPVyq£Å•Ñ³V·.*Í‹1»“¢üšêH#5.‘v7½ë£¹ëBÉÍ´ˆj’o£\Éqºû?€ån·(²í<îrb&AyÌı UkŒÛ½æÕëÃÃ‰Û²¬äso[¬–MŸ×Û«ÚÔ­T rTÃ¡sŒJ%»Y^Wäx_¼èyˆ¼¨µUßV¿´*{;+§¤7ºZqi÷+nQæ\ šë¨*‹f>'Qm•ÿœèç‡/I ç³Œs@|‚x®]8û6Ë`Fßfâ'¡Ö(÷òw»táª:½Q¿=µ}/Eö{Ãïr)Ö=qoD\ROÔ·ØŸ°ö›Îé¡\’¼9 õ*.qöœÜ
c?ÀqcÔúí®í •aµÎ„×AEw©xRÌ’@jêşÌ?½àm†¶˜ïqáJNo L„ÛTMA]¥Ô‹±É‰×§¿ÒÏYcµô“êÒÒÊ+Ò}Ø,F´<è†d¥ùÂÏ“½
Ò~ „Y¿Ùg_Ï*G(³¦‘ûË™÷mhşD }éÒ·á±©eÃİ¼º<¯Å3ªÜ–áä¾õÿÇC†+BñN÷Qk‡tÇÒôVíMøLÕK(%ŠŠø¥¼(€²¼íŞ7†¾—‚Óò¿-!Eÿq¦d!"û'.”šnUN0ÎÎ­aÔ•ï`u0-ñR;4ßßM7²rSç-’i^½è¥Ş 1¨b³cH’À]µ#ä@ªß$Ë¯4ç¥¢¸†@	(ÑƒcÎ¬îuËğÑŞşÑÔó}B\ÏnEÂµ=bîAİC«€ÉTv×m¬,hÅ¿@†õ.YëK#…ûùÊ¬³c2ğùZZ”n96¡l²™Ø%ââ0må¦ª;ÑÂ¼µºÎ€f¯,jè [¶P˜Ği¢l`ËÙí;,Ê1ú%µÙ±Xp96í•)®à%ÖØœ4›,U±<2Ò›+³U‡Y†ö„ 6"ö5L•Fzş¬2ç 0ÿˆÛşÛV*ˆä¹.…‡á!o¨áÃmUéÌÅh ¶»ö»!TmÔê×?IhÜå3q­æ2ô)Œ‘‹„!à´l.’(f«›yS‡òpçD¸ËéŸ`*ñîÄ+¬@ÀÎëô‰ yy%Ì®çQÆN.eO›°JT»îPÆÏÊ9z.®mÇ‡{¢W&ÅkF[D<ùxürï¥WÄ»üu=ÕÖÙ7ü3–™U:©^—z²Â‹ëë"UhNŞÙ1nĞËåÆwy	aèm°ƒµEøå~Sêx¾£Æ†ÚÒ›Ö šº8 şÄ‹p‡"Bš¾ q4cœR‹bÖ/õ|‹Åj¨e6gãéÀ]$(ÂŞ‹®Z+úlºÑÀê)şè;’š*%¾_,9xƒ<˜æi¥%±cñÎsF/€‘ü­æXÙ\“óÊ.+’Ûl‹Úƒ
VH›´ìAbÔ²:Ùd{;¬ÿ?,rÇ–"dƒ<l´Q¬½9š}Æ@Ã½¡rX![ïËÿ»0¾SËğüÏéŒŞWä”ì)?†€fiòÊ—¶ğ!ç¾îrM¢GÓ«ãûÿ<‘‘ÏŠßsÈh\…n&– p9ÅL[ı\VtXb“^‡æÆ-LæF3”+«0}BEC4~|Ğæ1?j`Ğj±w 6G³7©"&ƒjN7>˜ 8©[ğ*R½GÅØ¸3¥—oî±:'´#ïƒ‹dˆ¶cgƒæÿìçÄü	±Æ_¨´L$à¤µ^×§‰hñ7“PÔÈ ã4\¦„ŒÁİÙß‘ÖI4kæ“tÚO‰@*Ä¡Àš£³gjrğÏí¡[	tçKµÕÛ,¿m6Z¥êê05fDZ¹e§3m×Tã™b‹©Ql¥œ543øiBİÿÔt[³Êíï™9ƒi¦‡M$†ákÍ >Ğ:åäğœ/JrÀ[z$_Ôì½VtM¢SØ|`{u6ã¿(ÂÊ òiô	AÚdÙÎ8}:Y0!FæitÿR4Àe½'/Oó.°€pù9‘åXL]Æ{¦"ãG¬=¨3 À©-ÂS­ñr‡—ÓÕ6Œ)tÃû`ÑÅ¨Ôëš»éO“qÖŞ’,•]„D³jöşL#¦¶KëNŸ èiQT—»œAP–	¤ü<x^j#^«Õ’sŞì½"¾«9vAÆ=ºäXå—YÆZcûÕ…Œ?Z8ûƒ`n3‘üÉ…é  fva2HóVUºÌ¼æ6¾í&´¦Y®hKf¼bq#vëgÜ€€îgDyˆW#Û1š¾xùÑTKæ½:ÕÏ·$ªâ
I¼Ú®)^"G §ådÅù·›)//Ä.Nğ]Ş?±Ÿş”3oŒ)5¾ü<šH›YQnåLÆ<ÍPÊÌ8À£‰äbÃMa°UpÈÒ[xUwKEãkÙhŞ1Ò—ÿ¹Àz¸İÄ’Y·{ç¦:âïÜHg>˜àbï9š¾ä£MÈÿ†Æİ$ßNU?ï³€EÔİk¿Ç“&ĞKfçŒ‡Vñdi»œ{/ÇåjâeKC-£&…‹A/7,šEI¸±¿Œ‘qS|z`ç)‹çÕÚô
~Õt-ÔUv+ıcÛ½ünñå©Wí×/]Hh¼§´{¤¢Àô¹“‚!ÁÕrï·úu¥ ¸GºÆü¬ªï:¡5-şñ7Í¶û6šÑr”zj‡¼Ğq^vÉq=J™»ı2sR6Ñ¿îw·4ÜéWŞ^z¼¤ Ák'x×{C,)Àğ€İÕ'[ÿ~&G¡G¶»Éû¦ÜKç9«Üã(¿‚”;/+¢eªGññŸ>÷E/xß©…Û»Á‘n¡eZôÃ@¿	ÄR…ÎB»úîå$ˆ“è2.#qtº_%°ÒlÂ
fçµf•å¬@ËV{?ô,şV8_jãR„:Ì“[§YÔ`·ôŸıOéú°rĞ‰:R çP¸,Æ8IÂÑ0çŠ%ÕøÏ¢“ôú(IW¶nEOÉ
O€qçˆş¹u	•~.D–ØCS6›Tx¼ŒïIâ¶v4}êŞœœä]ısÊ‰#ò°å)Ÿ	UÆ*@®•¹ÂÊ³ô@—ªØ;:Ñ¥}\İØlƒì9×›³BÇ¥ÊnÙ•±«+"j#NÓÔ­Ü ‘ÉX$¿è"æÁ#~oñã2Çü U<×bMg¾c>æüÇ“!>°–j~¿€Ù"ÙEã_ÉjÎ]£bD}s…ó õ´ÌÇZDùÛ7uv&’Q/‚ @Ó¸‘Û’H9@W‡h©i‡ˆulÌ!e«'<³S<Ú›’<14Ú3”L7p¢Ù´€ªeıŒT·V~İ”R/¹{G-šëó¼'Óü× ¯):3G{â+on”ÓŞQ¡Æ	†øš—{q$›k‡°kÎ¹À±Àå‹*Z‰‹ÃÿğÌu¤ºgø\[+-®rTÔ»h£à2tÏş²E€“,»IÁ‹$ì‘£»äYy½jú11àÍ€LÁœàT´Øé‚x—Æ'ßÆÇl™£Ğ„…ˆ+çob!·JI\Â¨&"'i c“?ÕÃGq%MPS‚³¸0»kº$ÁT;2/İÿ#C¡ lÛVš*ˆ]ÈY¬F‘nt|…Bfh&DšäpØÇÕÁıİiªçR5ô™ãRË‚óÒàÆpÌÿ¬Ä„±Tv|Q5F%*7İF3‘?ËyóidãUŒZ
;CsVv*I(××+M—¡©-0Ş$O)Ô˜hšÛS>T0 Ğªÿ¨€“Õ3P®Í®azßÄt0¨y­n@¾Kà¿5ÀI¥²“Š‘SLM¼%(É0bŸJÏÓİf!šÛŠ8ig=&†zßÛ°Ù}‚ñÍ]{lcd¤ëAZñ#VUïS"“‚ßÕ,0úÖúìÿ]’ñ«)³äp«üæ"Qndz§ë\Ví\cÛcÆ[¨A ‚Şß¥bÔ\[Æ a¾vg-µäm…ûƒ3Ÿá	gyw<¤(‡'³,î¡êOqÄÓ.› Ü=ò`%ôAL'_§é¨áçşïô=}å»ĞÓĞBÑÚ‰ÉÍ.â›šÆ%ËáúĞsP¶|s¬EW®Ùe•9‚1Ôßqu#ç¢op Ü‡ÄİR ğ@Òyæ&ü\8S~âMÓ²[Å\"$b ¼ëG_
2¶\R7²=üÑØˆ‘ëâÌSq7~Ö‹ÅNFq¦¼$mVÜ@0l5aÁdF˜i˜0Õã=Òjñg#@Ï%´–ršá¸Šç™‹ÜÙ‡x1[e¼iPNW»mj$ÎbÍW£ı¢è€ÅF²Ô–z•ª[½~ÂÖ"XSI’§?m@’ûã^!¦ÕdÛFÇ·~C8P½k•£0qcí: m—:YJ‘ı9®Ô[1‰õ*øïB&fkæu
AÆßd>ûÌZ?Ó›|‘’,—–`&@x À4¡I¬WŒ´&ü*jéü	4‚´ş–ôŞ¥F!f;*è²Dâ2¹ÙŒzŸ/—‡÷7Ä¸ĞŸÓuD¾ß\\(z7÷ß¥ ÖüëÜ³?Ù»,¢™®*`äã> ô²#İÁİëï0:ó«§Fá
,¸_u—u?œ}ú-¶ˆ¼ùÀ`ùíÉyO§ŸHmôÛ°ë¡—F!½›+¤‰püç“„yáXô@°fãLÚ’¯_s·Iã/õhÉ)¾MĞm$EšÑ©Ç‡ĞÎšŞmî$8mS513Êb'kÁN|ü›[Ÿ§§-Ï3¬úìüõìæNşúš¾R ‘Ş1Ş³ÈXI.õ92}ö«=¶^Ú-“™ŠY2"4—Ö6(ï“y¹ÈÓË<"ê¾ìxoTCq¢@01ó÷¦ùh?3¼"á
IæÏöøp*Íõ*­t„)œè_s„èİ×•=øˆ|·é ¡UTi–œm«–ÖHÕ·°òÖñÿŞ¾²Õ1„{nTäù(;VuJîâÇò‰¬¸=hä­e}QÌDŞî!=ëà…KæÜ¤§¦EÅªXgµDôÅõ9i\P2ŒaÎ¦´CkÜêä¥¶ÑNşİ½²ªwX²r§ó=gëà‘æû	x6’b„§«ËÏilë“‹ì†íen_L>U»¾B¢ğ¶³™L(3}B!&œKSCÀ½ËIì¿ª)ö½À_™	Q¡ËkğÚiíò7Ö3Ÿ(ÖN°œ#x+ìğt×ÄõŠğqŠ:@ÌÒVYüØ’¯²›)Ì:ø¥©ù³…@Å"»øMGö½º5†×VİÁøDsËpYnÿÈá"KHº_GÊ²ñv ÆË½ÂfÏ¦«UÙÿ&EÛäš(Ü’·H|ª“¹bX'}y$»æÏ¡¨¡Á¥[ÿYE4JgR²İ{„ï‰—©s Õ@J:DÉ’èÛP;IcÙ]½<ïÊ‰sğX´*A÷ÚÁ?FA
ZëŠ,Y>ÏeÆ£å+Át}èÖİ»iÊL?.‡ñt±”åµ•ÍYRªúk;>F]şŒÅ‰q@ÌXéƒÏ„âÙ¨lcÒA9„V7c	‡=¢òß4Ê)/‘“åxxÆõïe¯Õ[}JDÂF¼püá	AÇ¼;¹K¬8![G¨÷gÄÅ(Î&çÈbÂ˜“¦o=È£$|Vè …}’(ØQv_Ø{<í&b×8îr‚%—äÔ¯‹ÊĞJÇjgıÌ,5i:Ä›é}O³ï•ç?)¡ß˜t?Ü¸ï£¸_Ö÷3ÇTtÄ¿£ª İñ8ËXÑ
'¸z¦Go’ˆï—Tâi7óJX“B®.ê¬½¦`Ì¨˜‚ÕTx„”İ¦8ª¦x‡n]½‘c16ÈÂzîô•Ä½.©´şu;Şèğ§:æĞn%|¢bë\WqÙ%´Lß ˜pf''ehQ¹»P0 j’%™¿HåËõsëÌ6:‚í2(Ã·,OÀ[†ÓØ]bÛ%à@’·V3rá•^e­MÂÏdJD2µí=´/aH™—îÿÊ½s‘§ç›O,¥×ÉgªŞziPŠ[‹^±vä¡0í*'¬ÈÒGÀå]‹Î¯ÎÍxm£H©è£›\:ß‰—*Ái$k¼ï®–µŒ 9oÜXW¯Õá>&š€ÿX]n¾3ä#	7)a6À7Œ­Ûó_\|h›j ]+õ™'	Ç<iÎôóôÄFäHè5%t|¾$ï®½t78ˆI›R‡,
–mÚÉïvöCoî`;µ¼Œ¡VòÇÁ®K:´Fñ{‡ë+K»‰ÕÃŠßQ•Çş
j7Õª;ëJ¾ù²ıQ¬Dàá¤1R‹•3eÃÄÃO¨^%I¦“ï\ÌF éø|™2•ç£ŞÁ2{}â¸2ë<ÖD"ÒºF³¿*ú­’oúSnŒÜó>Fø,3pâ…¾Æ³îğæ "BO F~P×‘HEh™ƒ=:­9†¡ÿ¾pXHô×¯_ÈÌíbº6o>şeJ@j¬]¼¸üîY7ã‘F‹?'(«¬‡Ù2Ï´…ADÅSÃ!§îÙÂ¤İM~êyÊ\í,U?Ê›
Z6V½B>d•
“;ÙYl ˆÈB‰fŒÒ@¡bİÆê*pˆ=×
&•j¸N+gÓQú·ÀFÊÆÌ÷Rî¥h¶sŸt“2ÀÀHêÎgÎ¯Ï¦îÁzÔs©Xl±íË“±·Âü8À,Tm}¯‚AÃ±jñ¿üˆÿ2Hgyª»‘o+æzïB5ñì¶p&İõÕÍØÚ8¸’9|èŸvZïÍ	Lè½•,w¾m­¾?êDå&\e¡Ô=94Ej®p½ë4é`(Ëààcî)³k¤ dËH%aÎYt{
­|òe·púeÎ?|Ü [‰TW9•øÃç¨€‹ÆYóR“ASÁòºëï+‡ú<¯#²Gğir•¤øŞL3½!m•™+|ÛŠÏÅd¬]#ş:¸eÓ@"‡˜ÊÍ(ìâ‰të©„=5û«ÒG¡/YŸ)olñÿ¯·C’µğÈŸ}äjG¦¶Œà ó´¼
–‡s%Ë9û5ç›Ü@k¡‡ÄÜõtx#FK§&fÖaz€;23DO!şÏhJ4W&]®7àí^`ìé]åç³h–ëı˜+L²Â†¸ë7@¬°3„LĞVAıV4·„³4IŒo¿¹ì)l­‡¼fàg6¼g!€ã°’É7{=˜bT°vF¾+à0ìz‡3/H¨d•â™§ÙR?…'vˆÿ×‘ÖZ³yK&Ãò¶KÄËÁ¢j2wê¾N+Êœr‡ÂÃŞªˆ²d]Ô>Àö{eÏ”¯Âõ\“ÀŠÔßeÜ0$d½T-®½'?Ö´ÚÚ[04ôŠ>ÇõV¸Ó§jÀ3ŠÒ’ÅİÏÕKeƒ\¦W£0ÛG˜¹Z¨–.	‚W8{´ÜQzØ¬UÚı²ä©±>U$éCæ+nd‡ı46¹ JL„Lìóï³'ËÇítÜ<„w˜ÎÌƒ8Äãb“¢·­-µˆ/{¦kl.æ2d¿ğ×‡zÒDø¥À	îĞÅö}À_ãC6x,àY
‚:Vs6é?®±µßèkñ0yFdÀ!K[‰‰äÁÃ*iˆı¶%¨<²r¢ÀÒUi6§X}Ï®27hI¯Ô Ğ )6ÓŸ‚îÍ,#Gœ2( ¾Š<kß”|ºcünZ‚ş{9PwùâZS~âù¿­‰&âZˆÂug™ô¡*í¸8måÑ©T?„Öú¡½&'M¥Š3“HÓ«ãÍ%BY’kâ®’¨Ÿâ²¯=‘dC…9˜XJrœs¸j*†–ş÷¯Iòµû€Š]Jyh;áõùcÑ÷s15¬‹Ún¥œ}\*,p™Ûbr§ë)>²k¤ o„ Ø¬dñ‡^İ­‡·v•!Y„‚§[ºŞ¥°rù»ØÂ„:,à*Ôk$ûq%®út|Où€]F	l«.­+‚‘7¹w¥N6×Jî©ÿ=Ã£K~^yÀl§1M[KâÖU,Í<™’Ş€P¼RÛÕa‘ÿoÉ!®à\˜Æ´< nÖ¹W3_Òçr)g©‰´$5qHÊ—‰p¿‰7—|İSYjaĞGåŒ¿ş>ŞÖå‘ëHæ£éø[nÎ¿7ŒŞ¸aÎT¦O÷NfU«‰–`O[¤ï69‹Rxu7ñ!]Ud¦D%‰NeË.Z;ç\­AKlä¨õ²«-2Ó§9è[b=¼]¨òÛví¶Ìª:’¥×åW„ÑÄ\q˜XºrªZHo !~ƒ,ÛÁ|á¼l®+Œ}÷ò*ÕÊ„wïÈ;2e\ÅRÛ	tÕC#qïË¼—7¦"y[vgÂîŞ›ªÌQıTûhTìu~Y<ä†!’ä"–­¹¨×s&4dO†ÀdV.¶0R¤R†íáˆ¢N˜è¨ªÇZQÑR²Æ;-Y_%¹Ûu¼ˆ]d2†ˆ·
®ó%ÿ;bËŸ›ÄâA€øe³³5V!_Â÷æ6€ª›cc&I}ôí.ßÉ‘n¯]ÓštÙxĞê{¦WÙšÚCOH‘èA€7AëùaË9¡K|‚p+¼õ äÔÌÃó‰2Qˆ<eÍCpÅÒøîRäÆŠÑ8±ŸğÃsÎTi(ÃŠşù³Å°"Á?]@SÅ}_I¿–Ú&!é²{_8`«°èã‡˜ËJ•¥ÖœÀÒ#0ğRÔÖYá‘*l¬İ{<½£ØwşÒ*tûªø+bÜEğMMË³yÁıÆ§¥ÅçIV¦ÔGø#½…Å×b…e Öüäº†˜UQLØdëfàÙÆÒÈ£sïÄÌL[®o8+ò°ó	WN«¬8u»pĞ?3LCe9 s#ÉHæb¯”K1•„JºÏÇaÖ§—vÇäú9Ëö})¤-¹ˆÍ/.Ÿ:¾È…7j&˜>k#yrMâ`µjÃ‚ÕÚë#âü‡Z¾ì$_$e|Üß\¦ZW.Ì³å­ù˜ôŠê=6‘.E¹Ä3IÌm´<…­$½,xôÇÃL„àp#-˜fñ’R™ƒÄuÎ´-øyª^–FJ"Ï£s›Í¿O¦³ÑÔO39øïM¿µ¾Û…-'Â¥¥“»©.´~m‘SbŠw–†J¬HÚmÙ ñà†R¡‰'n·®Ãÿ¥E±$Ó©tãñ;íÈ<§e2’Ö¶ @TÁµ$gNqğ ´ún(ë 8ûx		S>ñIChğ‹ONÒODºBLëE^å>¾o6ğoúÊe”]‡¶›ĞÂöÎ£ü=â«èôVÜÓ²úË~Ò¼,Öem<!‡˜joÑE#zÇ"Ò,M1qÀä¯™£	÷á2x¨Ø]Yø'ynÿèyfmÅr#÷”ek÷×‘úÈ²œÁ_Â¥c/Ct`»IæK®kWĞ&ì ¼5qŠjr}ö?!:i&³ÎšÔv{,Ü$Zk]õL'³è¿û>FzJ‘BÖ<rm;z
çŠî;ø'ƒ“D]§IóP{=™Rî#C VÈ‘éRÂ-Èc¬K±€Ï]
šâ9¬…“ˆ1 ¬ékì<‚p³Âˆåê±%¦OÚS®*&ÍÀOPŠôÁ?Ú¯G”œñŠÆt°1xV oc~‹ KÔ“Š3ó1ª­ªaÍ74LEø÷ãş°I*¢‘êMÊñå¬' >ÃyGˆ7íPoÊÏÂV-£?i~‘Ïú½ÕĞ“ıí†G›ƒÆvZîxG§ÃE,Bé ‹ÛüèIÓ²èÏZ÷»¤â¶&`)X|ßƒh˜íD¨‘ãvŸ§eµ…É‡”GËbš·v¨¾0§*u•´¯A¨Ë|ù;¥‘"Kç%ş'½e¹ŒqL (¤ qÎoLtÈ¦,ï·@0ÙFC.ë)¹êÎm©ä>±f¿,°ñÿMD1XZú‡¶}D«ÿ!zŸw6aç-µäË}©ÑÎ;ëÓxÂC‡ì@«üöş½?¶ñelJR÷÷+PÜ«çÕ"d²‚´ğwı°–"è…·\êéù›^Ÿ¼œ©c "KV"^¿¢';qgPàßIN>\˜¶8O9Ã]n}#€ÙË ¶0‰Š=6Õ¼
KL“†¢ş)íi¬¬ÏÕ¹½…Şu;`ÃÚq"ëõ…ëµ*_¯RÚ°g+ÂFLNìØfÔ=
ñ«[^LMsÜnı•ëª”£J @şôyÉGÉÿÜ-DÖz˜ê
`aïbF¹{æ”oàS§§IÚ‰ÅğkfâÖÛ»*íu›,•+º~ˆ†¨¨3=P$œ;‚ÍBßhÓ˜ğ‚‚ÄÄIãt*MÂó2!¨Å5›pÿ´¤08ë"şW#ÊSóçµášÇU&ş<ÈÎ`Úë°Ğ¹¥Â:çá®4ÚÕ.¯ñÿKIĞåöõœÏô¶›ãEzÏg¬³Bİan¥jd=£éó%wSÔx'r:ãßd'p²ª½Ş¯­¥4	Dö•Å Ğ4ØÖ"1ûpÏ(¢ÕRè]À,G_ä7+kò½áB„Ù&pPÔÀ¬õ¸><ÅIı«¡Yñ|óÅêÜëğœÉù¿ºáş÷ŒK®¹¶pùÃQ©JCdá#Š¹f
áë‡NCñ; Îİz?jS,C m€'š'QË²¦rÕœ<fP¤Öû´»b¸	íAh	–£á¨çZ£( ³&Ès,B#¾ìÎWç¶*pSßÈŠ–h™^2Ş/™‚Ûö¢eE8V1¥ìC2³”n©8 µñı%
g”¬¨Iæ^jw%ùúwcµÖÁ«¢
[c{ÃPK8>3K`Q—›zkşÏÒ {\ ExÂW¬ØÀ^fã×‡â2³­$+X»WÃÛ:ƒ˜¶óöÜŒµyâëk¦Ï¸A­cç¨fğC4½ëw.ºÓGØ7ãºÃr“ PUB5V7JÌà!FHoY ‘)ĞÚÏğÔ@o™t½²lpQî~šƒ¬PŒzi…òŞuşæhvæ¦Eä¼5³/±öÃe·¶õê¨	¶T€a˜µò<¨ºŠı¼/Œ™PºÉ½‹Ú-`×JÜËq; UªD†…øŸ‘ôp&úImì&V‰[tı÷»ä~‘%„‡Å%vFj9ğu¨8<+ı?³Có=îD–Øëô –ş/×:Àí zÏúpÇò8C×¯B<"ê¸Peæ†k¶}@^ŸÁ"×ÁğÂ¸†àÊòêŒtÑ[·j§Ø³g–‡PÍíÍâÙC‘`¶/ÃÌ°K´@âBöIÂÑ§¾
²ß2lÔAúdCÙQºÏßóÄ‘ËÊJ1êDòÔAâıÓ³¯)g-(òöY·˜ø¡$“ú,#Ïı-›Ë.C  ZCİ-W²—¢›¡Ô¥={Ç½Å>…U“¥ıäü‹7 œtìdèöào"·®ÕÍ‰8ú¬›ûCJ%E¡‚tÇñö	)føBíšàfõÒ8Tw©|ÒBIŸ%LYDœJÆY¡uŒ~Óer&40b;Z($‚ Ø&Ë! ¤YìÙÇÎqâx*ß|,¥«â¨d›¨?%GÉGaów%F‹lõ‘²ğßÚsğ´t’ÈÃ çL½4»fëuddtÍªëœÏÛò|GgÓÁ‘FªÈÀwßéês¥D
á±PÆb²ÌÔXX7²Êr•­q#lF†¡àc–FÄ,ö‰³ÄÅm={,ÎTõ°Ÿ¦£7yÀ+:†S­aÅ¶0¬â]®±ÆûŠ%a&±Î·Ã|gÊa? ÉD‚£&gÌ—³/¿¡¯™…#îÖşë`öK}ŸC‘†dFÌûˆœå£ğ×²/~ôõ öTêòº ë~N¯óLwãÁ
ŒK)Iğ®¦ªÛñ°“¿":)M9|9V`¥~mBJP«1Ø‘SzİDº©m0£xW2Nøµ–•ÉqòòådÊé 
ıt°ˆ"İ'­Í
$İnz´ ­bdÎsíàĞ6:„’#Á¼@9Jã	²dáš›RÚ-à˜íœFŒª²–¬ÿ(iW…mÂçŒ8äHnÑë’eæöM¶¹	—óÁF$2oŠÂíE@3WÖ+Ã1Şì¼j9]²gS·Àw" é-w7ğ¡8Š«cqUb€°I–,Ã\,‘5©å?ñ·ÊÀ*ñRJwk¤İùï 'KÄi“$<O ?2øßŒ|âÖ0²¼Ü‚;‘É%ô¥¸¥1)6­ª4œ÷ŠkØd¿o#¢äı{K¯ÁOp3âè¹!ÎrŒF4\VUˆ6YÅúŒ‰k«è0ĞMø$¶gÖJÖ·@LM-ZŒì0MwoÜN\„”ä•¶|ì_‡SáqV€ÎXµ«x@2iÈÛHU'ˆCË£‰Ñ¼Tµ±f§âøõËM†>5]d€XŠ¤{[ÎÍ^—¯yU¤¥™İ?En`X ‰Ü³{“iÖÿW`k–5§Ú6AÆ¾U¸}ïvÔê¬â¶°‰9‹FkZSëğ¡>l^GÌ.¿„á‡ÆöÍ¸…C^X¾içIå nÛOÿdryf™TˆôŠ…-Ó½zÀªV©ß³J”Ñ;‡Ø ¦švQ9jšX;¿4ù9?oïıÚçä2áµÑıãÛ!tà3@¹R*u)µ£ûz¦táËª:ÛÕ¨±qoYV5íìT÷ò-îC§ê¨?Nó`FLXã2S¹Væå¬
&g·U°a„VÇONN<ŒH4P¯EåÃròLS&Ó9Ë,Zx´«åJ—ğ…­\
“ØDüó¥Uˆ^Ñ6=êÈÜ	u{!9X9‘Lÿo¶¥“?RúÑ›'ÿsşFaëôÙªüû$d•K”fG¿ÄõcäLKyõIE\æŠ‰D6t“'ÄÎõ[eÈQ‹ï™Hç4#Š¿¶cá‹°h¿„pY‹&À^¹İf˜¼FCDjĞŒ©Á/·ïs¹Û–Ë'–•Zø¦4…úß
pÖ“c“àäãñhôğ"°à1C€w=u:rÂÉFO[|"€U¦æÀ1Æ"õSùµ9’®Cd³ ˜´«Û1ÿ‹¯Eò7—áÉÕ¼åÒ
ÍA|ÁÕJ¹Sò`ÿ¦Ì™g¹mÖ~÷ÓkÿòÙLö
¶ÖzQ°„…œ]M`p™)œAG¼y×µ;!…?’f	S¯¾‰úUny6|“òİµ~9û9øS‚èUD¥EÄCÎt‡¥·ªX
¥AG¤¨*á@bÔèLHÀ7ui¿G½T—êï+Ä‰Ätóı¬œ5Ù)w‹ ıJ£ÁTí¬:w>G.R¢µ;rƒ¢™	ÜÖ.ïŸ‚XéEÖÁüımşùO¡Şïá¸•.÷[ ?¶‚'5È×¾EsŞš¾¡†áH#—¤Tà©}4ÜÄEÏ[r*¶ß	’Ó“P!»”[«,»uËƒv;:1ìDØ¨Úÿ)J ±§.ã*è\kÃpçæOˆ\Õ‘® V‘È}F°É1™µ_¬Ú›«\’ŒÙÙ Òáşõk4ÿ0‡Ya„gƒş´¨½X)ï’Ô†:°ÈUÍ¢l=3o¾§BqÌõ4“¸ƒ›6İ5@ªD‘KdÊmâˆs¤ö¿ÜŸU«Ş¼8@õ™Z !ûUr6£Œé</(ãv"ĞğA’'”O˜şŸGÜN&xÒ¶ø`üŞÎ±÷ébÀIJwpx~ƒZT9¯vÕÒÀ7î³ïm­wGœX"x	,º™“± ïéì˜AnyN[bÓZv%Å„G©£=(`3YßßééFÌ*Û§–0™OÑÍ¥ZN“¥ß!a 8ãröÛw ù-w*+“œî¡f¹ÙZeSÁT¡ÿ·œ+öFï\`“ôyRVËXÖù÷Àyò?#
y9™–ÚuFb‚œÚY(šKéÑW¶Ï–Ø´£k†ì¬ÎäJ³8ürçmKˆ¾€C~ch&Q9ş–£HÖš]’šKœåÓš¥/Ö>ñ›ˆÇñ9æ»u^
êë=caÙ‚ô½nLZûF¹;P}9ˆ~0käÿ3iÍÛÓùÇ2?Qäß­›ÜŞl± p~Yşçs{üñ<Pà™gíõêmÅ±t0pé€GÂS·ÌMK_ë(Üi=›S5(!{j-§‡šQ ^U‡0(X@ûØ•şBù³nÚ«zM‹Ea?®¯jàKñYır#ÊìîĞcŠ(ş E U3-8–ØS$o.KâÑœ~Y¨b,}LşX4áAGDe~¤$* `gšYîFRÂ`½mbiìân.Gş'Ÿ²Ï{M4ßxÌY$lp–™-…9¥Zdèèæ£t—ˆ7õT~ß6+;vo9J~aîŸvb‘†.+ä%»#Âú÷çp†/ª<”>,øk7Ì¾m‹Èò'b6àw€Òú‹]©>‘ â ó„.ÒàïH4L[´/”;üŠÄüí…taª ™¦i…´·IÂfpôÀ½âÓ=p;Mü
§^?ëƒëIş÷½‹^S•+‚…H©:Ngà'
&w÷1\j.ï‰"b´ŞíÏhåWåõôÍZ±7ëjCšWgcŞıáÎÇnì"Ø'NÎ›88y>ò0Y2!¶=¢ş‡«ÈğO£U·ÚæzCctâJó¯Jì	æ	úÊÁÃÊ³‚ |ƒ9a®æõîj€d!¨¿öÔ$¢Éc ©%¶¸‘g©i›v—$16B6Šæ5½ƒlŸO±ğ•¼2 ğ‰Èp@şÑ[˜Ú¾ÒÒÖáìù_÷GCO<q	é•ïÀğÜ•}–øªxÓ:‰?ÆÅSîVÔ*B+üôô.¶^ÀH$¦!hé´¾ù¿âRz³åšpGÒº­âàAÍ¢K&É}+N0‰ã‚´½X®h¨…ˆ*è |iš]Dw‰Ôƒl@Y!)˜D—O\ˆ
ˆñA+Ğ[ŠeX°÷FlCe¬£ãÔ˜š-K_â{wq8¯:#e:v|'£|”ùéÔŸ±;,—ÒsnÏkÁ×†$k¼ó}Ì´B±ŒèÁT ›PöÚe~Ş…Mª’O ú –°Oğ"×B’39'#[W³cÌnD™šg–ç×(bc±`üÈ¢M_}¤Í9T­Ñ1é¾×H9ßtÃóL¼¤V7µ§°G’^‰Št!’ßP¯Ùô%-aÊGåWEp‚6ÌåÏâ\İû#§’—Çƒ›/¼¿Qù$É‹@ÆŠ¬”¹1)ÜÁ.¾2ŸŠ¦ë¨ç{+’õû@y¸C¯¼€ğÄ­ø!Ø<â
šÂhEû–“):qô¢óxàè%S²7¸)ù°Œ'Kô,×C¶ı¥”W¯åÁ†íWN&ìB¬TóÙ)±-Í™D°Û‹oS’B°m%q$-4ª%É%cw%™‹˜ÜoDètvx¶‡Î;¸;¤“‡şÉ¦KŸÀÀ~DgOfú±)ìÿ%§ºÃóÏX‘°‚lñ|IŒ?Ç¬]©µ®ƒw„I›Ï“o»5$jÓÄOŞÄdmïËÑ€ºõ\,°,üı†£7‹¾=
ö˜ŞÍœ%²y(¾±¥vír.Œ7é:/GU Úxöào­úç——;;^Cbå¤m<+ÊfŠ¢kíæGê¿&—îBhysjâ'Pz¼ÄX†İÊ$ß+y½¸Ş½T
N1ÜVÈÓíÅí9*#^1Ån“Ö}uªg«s„˜Û*áf¼eÖSíÏe2u¿1Õß0¦#À~´!ó¨¢æöÒâ÷†½İç!3°B·¾$l)b˜¤y÷­šª••òõ×³,·³ç/Oÿ>)Ë³EĞœ˜ŠËLf*]oU<Íéğ2i‚>‡év'eÎMSBÆ°ó¿ø ¼Õ!ËªÿK42ÎŸÕf šõàÌŠúd>F„Ÿü¶?†ABµ±½„í£ »kQrºÆXŒ¹öû v{ê¡	è5¹B=iµ;&¹’‰š1Æ’BñDnÛË­×0J«W¶nóèÎ~±‰0/ï”™eï_Í“2KqvŠ­t¿ë #eQÍXvÛ3 z„aGÄ'¬im¢ÈˆÜ“Ëç³û¯EÏtó>¤İúiu–­İlç¸O]VÜÅ½®1~ïÁ^\qTk™n¡õª½ĞxÊF½xş‚ÅÚá©í‚|¨äèõf)åš¼Ë‡æcK…Ô·yËf)	ùJı)¢É7âÁ)R½p…pKdûò†TÃ?äï\NU#8­rç•{¼µ¢6@C&¨Û£ZR)Üç -9¾[Î~	¾ãı*fA›§y
v­,1õëi×gPFSµ¨iJÉÆúÑı˜Á©sªZ¸P¶Ô‘˜|ı7dİì¯RÏ™U¶>Å¨õäm›DE(Ê\š<ZyK÷æîÔh—¢£”L(hPiˆ´K÷¦ÇXá{he„ÃÈôB‚8àÁòéU4Ls K(%¦¢¥u
ø©`«¤‹n²ÄC Ó1WYª¦5¾q½ÂˆúGo-Œ@Z]óÁä+ÅŒ‹iÕØ±§Ç…ƒ™CZÒ®Øt¾¤AmÆ¦-˜˜…=ÏkU¸Õ©gltú«o—qÍÒÿ«V ïô]9)×%¢N/÷ÙÇ&š8[ĞœÇjáî–î‰‡Le³7Š*Í5
"TaŸÇ€›Ğ<VÍó¹ÉÚ[dlãø Yz¶şÓ¯İnGGÖIş·»ÜÁE¬›’È–l';Eôâµ7Ò	LÇ\ÿP¨½!ä*ãe»¼PÑ\„‚ö…ì}'óß¦D@q¨ªÃ	phºÎÎoDüÃe4ËT1@ÍDÇoî	iØÓdãáÌ£Š¿O«B“°Gµ±xê8»EaÆŸÌ¸ÿ+%#,\É1‹|çm+ßH"×óooß¿?½øb,Ğò¡­x:×Áã£åƒÊÙ°âPH¸Üjù{[åZ6­À6‹`ø­w.yæ%vé¦ˆ
ªÊ[ƒ=0ƒX•(~%†ã¬µ-r*å37¿ïi…&€~¼ÆéÑYªä³•ğr88x?£M³{:Yt7÷hœ¤2Ê¶º0EŸíE”2Ù¨Ô*8·ÆfoÅ®¡©[wŸÖ8úÿÂoæJV÷ÚËõsµ¡ù¦òxw60°óœ˜{ªç´›âàå3û”×r:¯BÑt[`öòàûÜtä¦KWAæ‡\Ù¼ugTa>‘R›¿¶S¿ã¨˜DzIsmhñ‰KX|ªêgãğ´ğ˜^º–@úy…‰¦^"$ q¸-ÌZÖEà`ôv™~¤ï»ÄßáÎÄŠZ›3Òú‰•	¥ÿS¶a3 ã¦
òĞõe^èódj¤[›C|f„¾48ï¹Rù|Å0Â)µòÑúuÎ¼Ô›ây×]ÁIbï•\dØíí¥,ÀÒô™»{ÑúI<àØ¨Š6}™<dâ"aÆ5¼Uºp`of”;Œ"öi!'U°WËnn_ïöa¶cÑJsÑ/ŞËHÎ£]Ña~4çM‚ÄhH¶mQÿ¤W Ë	á+b3h	ŞxÈîEƒBBXó9vEìçİÀ?:xèÈÜæE¡ò\+dß—}*ŠeŞkq|ùË¼Ãñš±şmÔìdòÓü¥+7$na´),bTĞ¼-Åø¹*ix˜İ‡®@ ®¦g	NiÒ&šMzû¨V'øİÉbˆ×¬Ç…V£ï’&€ÃUÿ#™ c»Ú¦êV¬Ü±Wùçynçê¥±=³z·b–›·Eª5x,˜Äh­Ùr‚A3QhÔjã
€alƒRñ\ TM{rà¬=„sG´£$ì³/…ğöFxÙØQ‡;h›½î³†FŠT{VÂ®v^A<ÔØ½Ÿ@„(ò~d:<X¾qgÏpÚ‘Z×¬:g8Am»U^´\BO±DÚë‘3iíSÇ­EÃy¶ºQIé•„…ËFì/.ÊŠ#ş¤Ã(jG-5ÂÀl2ô}*ã­ZqAöëÔyÿ¸H²V‚'tàw}†üĞíÌ_;Ë9<H0Š)Ş‘…~tEQ+‰@X]ë0†í“ğ—MæI:nÁô[åì?¿uÀ¸¼H2³®CUçŒåƒÎ£³Ñ+‡\Ã·^‡ÉÏËÜrU¤Î@¿ A1$+ÀßĞ\™¡{(YÉÒäüú_È.ŸÍUóÑ¿ƒ”^²ë™@-–d§F‚Â*Õev*±(Ñ¿;«´d¡}–é™Ãzå9Òƒ‡°g³šqZt D7Ùü\1—0U$ª6H¢A´x.8‰^êU^+´¯wïgÓÊœ³¶Y×Iûÿ™şˆîúÙÜrÁÎCkLl7ä1{S&‡=á¯]Q0¡R4úŠúÿ¥Ë›“OÅâ‰VxÀdOŸìÊ­Ã CÛxd7`É¿(ÙĞ³/3¦µ¨T>T[QKŠq×ÎV89+'¡Å,é¿0×d}¹ó©0||£]½‡ÁNxìôï¢ÚÉs`ÇøcÔøªzQŸà1/,êŸJ{İ°B»zIf¤¯Ÿšø-]gÂãšt?ÏÍªåÅµzgö»T9“ÔŠv£e:IäQ`œMÿ“¨ê].çQm\^v¿Êª+
‰zb°òù5°Ò¬Ÿş7ĞJ[İM°Õ‘£œ÷Æï%¼'£y['0u¿„;Åt"$¿#`wNŒXÔß7•<³nª´Çİàá”º§L1OJ²vŞ
 ‚Â­ŞÜwjh°±2;ê½ÇÆ!]ÛV—FY L(9}8òŠöØÓŒ›òÇÂI0Å’æÀ[A~¥ËEIg„yì¨OôEÇQ¢%ÃM=%ş<É9fÉZóÖÚ¯|;DÿÄˆ°ÏX"o¯dñ!ÂI´HNJ•K-¶Å’¼Ó›	‡1ôL­4Äp4}p…Q:ìg/“JÓ!ÏKõ YXìNf86éÿÂ×»“,˜í!mE£ÄïDà¿G”™åñ±‹	åi#\·š€VlühÓ/ïë',¬,½¬ÿa
†¿÷¬Pµ¦\­'X³—:5`w;‹Û4kú!mP(K€QËøa÷«½~ ˆÆÍ	ãª<Hò|ŞÁ}€ø›G3cÆ‘Tğ!épr2>(-<—fãc¶!ò¬‘X5WH¡(ûrî"b•c°´dFè…-âö×gZ°%øæ`àû!Ñ=í›Ö·ÅEÚËÕM£öO•ĞË$©sÀ7jÑí·{W°Úœ°¨ä_ëªÎ9ÁŸ”Kœû‘:t¬ş¿ò7:C ”®™òJhuˆäªîr˜5v†<&,Úp UŒÇ¥X°µ°E}>‘31ŸƒSKn%Ì(,/ÈQµé2@-1{ÁÒ)£rqÛú#tIä£­¼Š‰“I„îUZ´ˆbJ‘VGÑ.I¶¥p¡py×ÈZmşd4¨4Änì´˜¡n,
H%î(Òê%_ê]´ÈvCNQ!ÉkŒ²+{£íï¼:%ˆ*rìNãkHõ#ºÙïƒÏzi‡ÕN& Ïßµİ{gÑDä„£Áq^àåJ5ÓíUöò¹êòR_§#cş'Dbì¹?rb sqŞğÙXÂ_İ…‰5p›ÆyTiê%²Ò.#Úm’ÌL-‘ÏcñÏy•/²™ü÷Õr•’l§=«¤ša¤ÌbµÒş–—°şJçÚ]%ú¡ñæ}€Æ™<Q,€³L N`L¬Û!ÎYo€ßø(\rœíR05Gx,iãŒAüîŠÇX$¨½
'¿.csÄõXI´oíÖhFJåec¬ àFgY³a}%è—(©ò4ã5ÀŠØŸÔ¦™'ş~§1´>=ŒSè ¬ZÙgH+øŒíOÙCËe‡l1Ñüa„Ä¼0÷oScİ-k lšš-œÑ÷ºÓêvwĞ6Ò¹á\€)ù<ÍkÀÊı3T!¼Ñ³ÃØÚ;^! &ÍĞ6O?—h¾çV¤62øO@ŒMA—²°¹±Ûšù`‹3‘¨)§Ò(&¡¾ÊwKg[
/½¸ğ°Ê ´–øAND«ƒØ*€‰°dÙë°ßİ²¥a©hì½æsqÓqî¤J\§°ârz#NjõÅæÅ‡hÿN ¶€û„^†"Q®tÕ€VÌ#æ>æ{²ÒXÅ%Ó¬qêe^#ı¹¸¹ë­õP >r¢NDÖÚöàäœk
03M·Q9|õÀx‰»53i‹°DvÕŞ‡šJúô%Yİ½ÁÒ¢ûˆª<½­HµßÛCìÙÉ}¹ğø4D%JÌdØO›Ql‘9ß7I{×}®@(şK„Kö¥ëÆv”ÜÌ^(¥*?ŞA‹À³P‰oF™Uş¿şÜŠ½Œ“‹%p¤à¦ÇyHhË·öû9²æã†82‚9í§%©Qq¡¨ŸçË)A›&€×-kæ}0Jk]Q}àsGVZ¹ÿ)‘EíPzù`WDÔn.ŒÒyğéµ7ìbúËi1®YÀ|¬ 2<å Yä6Áî´	Öø¥&ßœRÊxÍ_	ÌºwIÖ-IŞô£yæÑÁ—¡m+Šåä¢ô8uÜBúÔ›ÍmËó€ˆD…R,
Èxå²Mò«Ò^ ŸÀgĞ±LÂË² ±¼S‘ƒp	I?mÂÁt€)ğ—ëpTÑ0‹G§fº¹_”¥Oâ…·ÁµÅ/äê8Ì·cÿ·È6mg²‘Ü Ä¢µ—Ç6Ø‰–†aŠ9Å–n‘Xyëôª˜ó¿Zd~å¡€™ åx†’®Ñˆ™ïwL6™aÃ©Eº¬L\¨3è“J¡©Í
^42Wºï,"ZA‰`æå¡ôv|pA&k›t§íÀEkW6/ºªI0PºßÌYëŠº”Ù¦mØRxN‚9êò™¹Ä3b#=JÔ#8f‹b$3&2œÊÖ…‘º„6‚ˆ»ég1bGYZ2­ìÙYÓA°FJ†ö¯,+1j¢Ö,İéÎØ8*,8Óû3
ÄRvtpõıÚ°Å¦ïÃ¯›şÙ‡.÷¼aD!·´¯£‡9KØ)D®&ÑWöÛ`úÄÔW$x+ŠâZ"üeU/àçÂ
úh‘ıåÛƒwuÍ‰CÊtƒ~€³)Š	I ~ùp<ÍMÒÀúHrAj´¦I@Ç¹]è–*Òû°¯¸ŒQiE„Mkß~bÂ"üLÈi0ÒÛdä!¹b¶ßGß"`U[	<AŸJaADœ³›íF%¸@¼~Q^gıèlXÄâ¶Sª?jĞ“(ÌÕœVkFç_Ê•äN şB.®4ì© b,³XŠŒø küÜœ˜<ÄÑ-ï†sÊÒœeŒğÎœOù lHÛõ8.ÀHŒMc¨à¥‹j$­ÙıGMÁ)<«ÏâyyŠ>"îßÏ«Áo„Âİÿ6¶³¥,3êÀƒ9]N#øsÃbH?èhE¡h=Ÿ¥ÈÈïö¾\ê8“±¤%òëî*>ÌÁãE)Å‘?±“™ÚL›JB{çÇº¯‚ÀÍQ*ÓŠwĞfp ¯QuûH|¡fRùªMŸ}qø¹¾ÅÙ"£±¢ ZşjâCX8×ŠcK‚™‰µà¢¶(îğıWU«”¼dÎxHÿ3ü´OèÙî‘9|ÖH’æºTõÕJF±Oÿ®¾7±vÇV4Ìc_)ù¡ºât¦q ”ø›*—ÃcvŠ8Š¼®‰ç¦F…ªÁ™RßîGYy°áj¶¯"‹ÀÌ¢w1gDX	õÁGÖ@‘,¾£ù7ĞÎ,…À0Màiî,; \m¦Î¸®/C0Üeí®L…ƒˆDO•…çyKHÒYBxù‘;}ê£ ¦`G¹gßäFfX¯—'lÖûñ¼¸vÅÓæ<"Â$3‘t^F­Ó‹1îœ©şCø?
p¨¢ç,%êÌq/…1çë»Vt<w)¡bƒ¡uÉy0fíkb}©€Ë”&¦èOØÅı]q.{ Â:İ-<ûË/bÈ5#9-lòôÏÊÔDï+Â¿@mä…>­RE_T€¸’KH†‚–íÊC;fëoÂ>i»„mêUÖ\ñÂøÓ÷’¦Ğª=’&=÷E“¡÷ú9r5‰üÍ‹¢kKõO&æğ¢Í{Ê„â^:ş µÚ£ØßÃD`-x¦’+íşÂ‘—d9O¡ëasÙÁ¨qB€r¤‹PrNñ}Y[^{;Gr ãÿÄ­ø¸×%¡i˜ôcgU
öéåp|OÕã»Ég•˜0—/Üt„CíZ¬EÇÄJr¿¦E²Ëë*3ùîØ$6E~ÇegŒ—ÀÕ!˜àcüóÏ]µ¢d¡,aÆ@0Æ,ê¶›Ö>0÷äÿ÷›—İWwÊ¨¹­Àcm ]Ï<S
Ù¸Ñf÷j™ºûŒ\Sªå‹¾Û³‹‡ŸgqOtºşÅ¶…P¦DõÆ	äÁbvæ*ô—qµ3Š^\÷5ŞvW¬2âBSÎxëË)r(Ìæu¾s€Ë“8#'
Õ|NÂ^¸=MÛ©ï£|ÃÚ"Œvû^‡ëˆí‡Š«˜ıÜc¾ ËUÛ8X3Üğ:L*ÃUÿùDKo„„Ò÷eù'¿pÅ²£ÆzÁU×ÌZ¢—bû‰÷ë«ˆÊ×`!^‰@ín&ÜÍOu²kÔ¼“¦×wakµV?F¹¾×	Õ$©9ør'='‰EähAÇí>¨GP¾Nò0xzü®üojú¹0ÆTg%“.S/®–—Â²÷1w”¼Í²Õza”9úÿ¶X!äÜ+XbAĞÂ/®‡nê­áò#›jšº;İùV±˜¥ÏíNèÑY¼S%¿Ú¶“¸dÏTÙñdy–ñİoRûî‘Ä+„( °'ÊDÎ!ÜŠ¡½hğOnò9÷Ğ,¨—“> `iÚIÙØ7‡[3Å(ãA KÜó§¯¶Hä~ÈÊ€Ò,äÏ[Ë®…·5 ÑfB’œMMå½c·—ó[…MeÒÉÛ)ˆ,}h¬œƒ¥í”‡ñ½&'ªı™›|jXÛÉ’¤æ1]î\JTDæ›xÀ®tÇ"JI~eoˆ30ÂÕM5ésÔ&ó¤°^Ú²¸1bVÄ–?]&ˆ–e3¬¿ .?ºæÈ÷Ù¼4éÂiújcŒùª	™aqhÜ4z¾I¦’aş‡<áéÃ¬GM¦¸¸›²:E¯ÀmºH0Ií¯8ŒÖ´Î¾½Ô‚¤üç²#8FÍ€R¿FB·ğ€ÄUPî¼Ç]’MZ€Í×Í2ón‘7—ã"9(;@éƒaß–ŞšY¢â$ä`ú#Ü?›ƒ›(P)•§ŠW×ş=¸°Ã| ÊoNêK‹Wâ­!,qĞ»°»$«İ5FèÚ~)ßqÅ1»Û- •CÌ6\:$æ®aáû—&à÷Å˜ ¥(õäºÍÛìB%‚-èqà&`±Ûş³Ê÷Ùİ"ÎPÑ`š‘AÑ&LaTD?ÂZ›…Œ?@ƒØ{Ö'éUú·‘€‹Âä™ x _ÒAòSışîÆşìÀ‡fT\mÀ8
$ÒÓóDà]ÀÖĞö‹ë&Ö“ñ4éGanWúvÀ©’ø(Å¤·™=]x.‰”\º)€Gã0ä…<eø›­Õ9íúG¾…ÿ¢\WÏ)]ÃH}ğK£ó›ÃûPmxÁpfá LãuíKò¼	í"›±0A/¢oW'˜—LG›äŠ¨û´œ—ô@ª9#Úµ	sìP}üë„ìÄvŠĞ]Ñ•ÚáÕf¢¤«¦w0¥ßi!;9¡JPnô$>¶f+8,ÜÂRcù.)ğÎmÁ»Ù«Zÿj–MïÍ ¬úHİn?¾ä½R6¹„Ë—´Ã¾VDrL‰/´òáiYóÈÔV¥#3Àè V0¥»h…šqÑ½IˆòdZ6 ¨DE$0ƒPTğRÚxÔÎ W‚ğ“ÓÈ‰«¾'Uæo‚uaów¶ CRWµ¬iš8ûœón§ı]é=Rë‘¢`H7ùÈH,¯¢ïÍ	Éi'JªÂ£æ+´ãçnY%Z»Æ¨uq%ä^gŠ`$_6®¾%‚ËH[22Işø=Í«öAùTõ‚Ç{Z7­ZaÜúNT:Ëìú¬x-|¦dnªÏL Ü.AîFKÅÈGZÇªfh`–wöÖ<Ïåş	Ò;_p‹§J6Ş¡icÜmöµñQpAáL…”ş›Á%÷Ù_K0zÂşD´:¤xÀã×êx!ğ`ÇĞŠ"D²eåa+µ;Û'ãÂ;™†§KµáÁËCÒmÅgyd©)8g~
Œ—HPvĞoã¨¿ï¦¨Xhj6J2Îì‰¢ˆ)Ú„T"så2’*èÙ54gw•/ÂÉ>}Yò‰õbÑR©AŞ2¥¶‰ºFÉ†i|¬q{/µ<	=òà±F°…r™G!¹ã˜vEÍö™2à‰–b#Ôı67TÅÖ fmVÖ¦óå«¥ÄC9pIÀ+'^Ù|*¢3'hL>b}Å`L\ ¸:]CĞÚªh~;P¥(LéöT‰‹ "n
`®˜µ@õÅ‘>˜>îÿY¢L%­u‡È¸pY‹)¤/Ÿ¢Ÿ®@bEZÔHÒd†-ë¡Ğ}gŒ5BFkÕ†Ò*ç0Ñ5øUVÀP-6u9º£gx!á¦Seµ¨ B¦/îôKt	!7WÏŞÇoŸô,k.]@P%Ã;gp££#xº'á«>"¢‘ú=ª“núR_^Ø¬xØ]Ş‘ÿçİ½èÜ™åÔÒ^s¥ 
‡bıŠß h|Ğß7ö*Ñ²jCğFön—ĞøÑW|Ç3[\ã¶{œ-õİßŸ×Eà9g3ğØ[LıïÏ²fÿT’m“‘,ßC“O²ú0Ñ¤‰ì—ÃC‹‚ ›¶´+§AÁC;2ÊFs‡A§ÕvçûêïPeGô£¢DK¾»ï?óŒŠ`ñÌ#>< ¼6òw–>hóUŠŞJ)ä?’ÜrÍ‘•‹S†n$ÖüfŞ¶Ù½9y½<âéyñµüQ»§…‹V6x=v	Ù`¸…íõ_‹4ĞYB€ıV˜Aï‹%û#(JzÚWçRúL,‹ßİ:t-ÜıwŸàf±‚D¦6 ªì6ŸÌt2€°ä:˜™±#·ÿiXs0Å½8S›yî
7ó’×j|†¡Ú‰Åö|)d•°4(öUïR^Ú1ƒ©J÷Ó4¤ª¹â);‘E6‰B6 ÷øm7İÜv#mã]7WÉkÃŒXH‹‰EÎàùşô•)FMÌÔï³@Ù9_åÑœ­•LvJİÊÑòÓU$T
äíbqI;Š¹¢§ä!^uÂáøÍu1¹€ÿmy'HT¬4Œº—@ÀyÀ9w—ywœkãßÕx‘1Ò…ÎˆaôâkY«™÷hÛÒ ¾‘¼,0‹ô!?˜óŒÉ^Xb4†tf#?½`A@1s~Ñê˜yÁ ªYıê3\€ğ‰ ¨æW½—v«TŒ/övÙO" ‡î5“.èj4­¿ûù¸XN2Ê’¡E8UFAĞt²^$éÏ ²ÃğÃÈÃc{aĞ
ˆTgôˆ/“ÈxJb×OkˆœìzŸ&ğÏ©ÓmÓÎ`×“9›±ğ4§/õªlÑÖ±rõQ49Ü!<”ƒe'ßåÚrÅsİÉ«vFŠ.Å¹¥ÁµšØ´jä®ãÑƒy–T¸d­:‹ÁBf©L]îƒ8c|…GHd´Hõ¥èã©0=Qÿ‹3’ ÂÿS/{-Èß ° € =U·±Ägû    YZ