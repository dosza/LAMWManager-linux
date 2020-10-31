#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="4135602739"
MD5="048eade4221b351dc022a162486d0f68"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20308"
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
	echo Date of packaging: Sat Oct 31 14:08:11 -03 2020
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
ı7zXZ  æÖ´F !   ÏXÌáÿO] ¼}•À1Dd]‡Á›Pætİ?ÒB—	5•C5.Å•Eµšø.7H6$$RÉó•·_#l­Ñ²mßÑÎuy/>§Y6ïİZVO­c>4"F]²{ôî¿œ_K›`.zM’®¦8&Í¢Ù5<oÛ¼ÓRJ§]ËCõ¥‹X‚³n5²IÎp“-ïğìÁŒ‡œŞ¦Æ,Åg¢‹œ¥ŞæaÃ4>€ÖNqÖ¨‘Ä£ÒÜ>À'Ukz`y¢Õ¢à7Æ}•ªQ÷q9\$	‹ıN‹4®ÅdÂ¢X±[o(á:ú¼àqd@¬/ŞÃ×‰%Õ¶\mYï‡ }šä)zDÛÂ°y$+„êûœ(’Úû\™ê«*glúÃ–.ëõüT¯ZC×2LÛàèÁ_išÕê³r/‡äâ“Jræ”İ+ˆ{ğp¸˜Éó%Üwh>7é0iœjÂJû¡äN:Ù}PAfë—y-¹¬¹·êãñ&°tá¸·R	\í­	+Æ‡@Š½(L×Ï¾RĞÕ“Z„˜Í³˜dG¤šV¼9oOÃàeÓüBN×Ûã~&…Æ
ú&¬Cv@´Š¬2qríö×f¶ëÃ¶ÚŠõWbİ¾‹Í2_õ™4 "ı09šü rïİ¦™QB‘•G»9NícFìàŸÉÊÁÔl*aqá}uUr<j°€|¡KÉdÁÁÌ‘â§–§ŸÌo*4gp½<‚áG••‰Kû“†›XT€TËÉŒıe
J €«Ôo# ^!¢EÀV‚ûbM²¤û_ÌÿÆØ;ßHP~NÒÖ>"=¦ıåZxS”«M Hç¯±8N`ìàÌAõMìÂàıHûUÛë
\8ßåa;×ó ‰’”o8lİ ”D?v˜Ìõw²ÈW2º uËàoä»:ø²]G7(gvÏ?ğB)é¯4ş2¡	ÎL‚Wb·Â”:‡
d˜‘ÙˆHZƒqvÈêä)}S54¸fş<!Y1p¿uF±cøvsµˆ¸s‹ë¨^-C¼ÕÍİ´ç	ö²äJºB³’¸MìvbÑÇ‡ ~[
!å<Ï>ooô%#CK‡öÙhd÷åæÙDÁ÷|pÂælĞúy8½£¥v&ÓC×‰ç@?“
ë°z>$s"4õ··qGøom|
²-¤f™óÈ Ôc'¯ÌŒk%EíSÆÆV„—Œ>+{;Ñ–İ¢×ràŒğr˜yİé7-ú8Ç¿¨qæ½ü^6€vá>9V3K…r† 1óÃù§Šz>Æ¯ádk«°kC—m»+¼¶^Ä>VÈâe\Mi-wïH¹[¿Â¢éóÓŠrç0­/®8üíÈUéÈß¸éİ÷tÅßD>á¼=´_Çoµ”Ö1ût×­†?õ4FİÜğ« úÛ×¡Í–OD]-Ü¯9·5·nivÇòS3:ŸGµéêŠ´%'Ì{ÿÍr°tM9Êò<ĞÍ,Büë-.[Ñ¬
İvNNÙÆ<ïgä&Ì’‚Z˜àÉâ|+™ßmÜû+M!w"b4Œå·I?ÁÜL‰k#.Ã»îĞŒ*è,§ğÈSÆöà%Š‘½|1l«g$yóii4Î¯Fş:lš>(½µn£ĞzåÇÅ­ªå_Í“ƒduf©¨5 k83¯³†ôÖ'lÉØC¢1ŞÚh'÷ !Y¬˜C±}ŸK>Œóg7Ê/»ÜêÖ_\Xjõ#ıË°aš	ÆédY8s8şİ{vÉ„&—ş¹C{&³À‹ı)´Å?òQ[Œº*™6Œ‹\ğ·Q!Òj$¸äîD…¶x¨R÷MÁzw¸]ÏMº$]½™Œ {íôo—JÃ37Çx´˜èZC‚F'™â[!õÚ·Pç¶î³+Æ´!-9®òæÆn€g‰Œü¨dHÌXª>Gï5ş©bŒÍ1ºJïíZğDÃSTItÊ¬e·¦cÍgX$ÁÊTOïT…ö
®%kEW¸AÌo '­å
³pşò>õ1©“'÷Y†"ºÑY¾Ëbÿ>v;I1g9lëz×ß¯æ’eZ¼´ç¼µ*Ú‹¾WşJHÈ÷aÚ4Ö­-ÖPDá¯Ä>M6äíEæéjÄç:üûùo™š!gİáJÀ÷K&ÌD8÷)WñÆÜùĞw_Ê-ÌzïŒª:7s91ÙÓãšT©=ù¦S–K•El¾4á|âü*4o£ÛeÅ>©'ÙUÌÛhAZq{ŸÏjÄ+\´0HtæakætZ) Ø¶b>`qywD#¤ÿÆ(àÿCG&ÄW•¡ùí„ú‘­—ÿúj\ï@()¯âp2'zìbê$”§Só!Öù¾é¸ªüÀf,œ1é¦Ìf«/‚™Pô°Óú…Q©ÓØ¡ıàR£ _f=E­eJ=¶Ùc˜Âé¶
İ’Ïf>š“œ½Tô¼Â‚†1Öó YÏ´Ó‰ôÓßzßl¦â!Wq[ÿ:N!‚^Åt”oSêè¬‘Q†.¯Oˆ2²ŸÎÊŠÔw´kÅÙ-™ÊÔ}Ìqã À'±®ßä“jşÅ¥yb8TbäÓQDDf!…Ò>6šÄ
©˜×5Yi#êè}Şƒ†4÷YçŞ&·Sae°‹6_
(õš°_÷¨‰Ÿ	(C’Ï*”“>#“Dwk²N&AK„ïŞŠÃÔÅ¾ş/x^§e>]İÛTe’(ñ =aaV]ù>òº± Œá°Ú©1™Í>o•PK]²Llè‡ÖìB­&ñQ”ˆ/¸Ä–2cp‰ª­J%t!¾í„‹ÿ4ú-J\8¾#æ±–…]ns	j†HšòÖm§L.VÍ( ûA(mà‘6Ò¾¾ºg\½ñiÄŒk-`Ã"\}4ŠÄ¤"ªP¼\Ù=ÛJ“ª‘GÔ­YË,Xl‡hO>¤¼>oï6A&<é<vö,d³+ñÁ)‡5MÌÜ ¹­ÙL
ÕJ\íàÔmì­»8WRO=.=pã'ã×{Ü&"|ÇãErl<,[kÈ– ¬É&Î¹‚XÎ…]ÛBu…
Ú8Ò¸{,LÒHàŠïéÿv£éÒ¤+ø´îUßØ ùÅSäö°hÇrƒ×Ø1R9D´ı8t‰Ö¯R[åxr¦ŸÑ`ÕÙŠ˜²ĞƒT$¬‰›E˜Ş»Ã2ÄûêY
Ù°#ô0\&SD*kÀQÿW ¾Ô¨ ë51ÙpÚcPçî}T8:j:şØÍ	ÂYo†ƒKE¬P<Áh¾ÿ0Zq:²ÓƒàÀ©d²ëÒÒøh;!‹.0Ó[µğ$~‹Qµë¬]_clIN>@=
?`#»Ô!ªÔ®>¦•h»K "ZŞš\^?›]]`ûŠÕéÏo¹Şp¸9v!ß%fŒÒŠÜàä¹ëjk+ú½+ÿ|Õï¶g DÔöB‡²›eí?ÙîÒOõG• ‚Z¿y9!ŒÂÙs“ãáÜ1c­I s	ÎØ§@&2¸^ƒ\%@A­ÛåfYe¼šg”ØÙR:”8½»”ëª*®i˜­}5'ôŞ•¦ªÒñªŞÓbi4Êk%!CèŠÄ†Ë7çÁ•}"ÏØôP”nXÛõ.ïòd¯5Ãì Íø ÎeÁ4`dù¾Ñ¥ÄÙEŠ„hŒeï:S™e÷5R™û"Æİ¤ÏˆÔ@µa%)K«a¬8ÌQx IÛjÀo¢4Û¶g€w­Ÿ+:,f qò™8Ñ—~2Şù³B	~óÍŸ6‚«´Îèº\(’|æ©frxTŸ7xèQİş=+F(¾Ø6ÙèäKàçÑÆb¢õ6Û’ ÈRh»à?àb?Up•QÌ™ÇQü¿æ5¾ü/#ƒ]EÂdJğ ÕjCjµBh½Sw¨=C»çe‰»YæÎŠï–uÄñ_}øŞ[ıÜXxÊKìı¹î`OsGWl+Î/¶d Ğúª£n¸è®`œêåxì]ÀT1Ë7óú8ÑÁÿÆ–‚ôÆ¨œ¼Zi]Y.+hUBÏŸ8|ÀÕ‡¤
P¾Ş¢Ê^!ñ,6¬uo~­TVî4öğâ³|¡—Ò”I¢"Äøx(6õQ…OâËÉëzKCõË¦ôŞ+±ø5ZJK·ñöì7Yx€ÜÑ i:ƒšöG3ˆÚWäY:Ô$4@áübËDÎÑÔÛÓÓ›Èüğ{ÅdÓ^úiqĞÀ×Üá›ØÂou^ï„ÎÆ÷MÓHPf¢F+ŸÑ¼§€9ó"+e½5%aYo‡v§SC{-WËU¿4ßšKô®r³+¿ô«$/üÎ¸ÕĞ®~İ¾Ãq)hBŠœºJ¡ş%†Ašà»¹Q²ª‰|tgjwš®dB§´ûNg„’TÖmc*‡$Am©”J]J¹Öù¬Kÿ’õtÎ;Ù+@S3WâÍì—ñ­ÒZMÇEË s¹¬!šfùé)¿-ŸËÆˆb\w´ä}p4ç¸Wo­Ëü¶RõìûŸ5'J'$aÃõßôH"€¾­kG¥]FÍ
SÄªYiÜ¨ë¡²Ï”Ó¸µj-G8Q<@<Ñ§D­?nÑ3’"Çå;«N€‘·â†":¾Upi¯åD¿}€w ¿£ºÄM,äD•QJœwÚÿkg+İ»áş8ù9É5O9şöÉ°ß-¿“4Ë…¿ˆeŸj·ı¡ıv³!a¹ğÂ©ú“lœÀ¸Ş@øÜmµÍşüÙêşFÕKùuv;À‘§°“7ç&¬ÜG/˜œÿ,L3µvşh´:ŠuÛ+SÌ”Ï±ş?w
İ”—¡ÚW¦?é/'â"iÇI|TLFM•MoOîR"$:ƒÕ=•gŠ½™{m>bâkF'âyuÉ¥~ŒÂ$²®K¼ùŞÁ¶ø¼€â¾FÀ4¸u&?Ë¯„ß°gn¶*¨âÓû‰sSº"g;Äˆ’–9%¥2÷;Õ7“0›º,ùĞ¦@pmKŞŸÇRî¦?!sR¡1Y±ª—M‘'Š¨QÛ¤T¥{‚ ÛùEƒ—¸r£u×móA]Iâ
X“`=¶Û9"Uqûø‹±i¥¸ şÖ³2\và,5Ê‚¤ğ·Â8JºhuİïjÛõ·Ç,[·÷g@ä¨cÈVN¿ ¹ï\{«ªg“n*iª·­fŠ]µ÷½z}a<şlèô©«ğ¦>ˆçxæTƒğÆu)©Rãà]1¯ûylT¢NE’ÍT+)¹m¬;$æWMü×Ş9¾ç­Ñ¢nGUÊ5]£% Íş‰¦QßÿĞ4˜jS•*€„¶³ôC8¢Ëbâ˜\ÅKÁè„Ş©-7@»}÷]:†ÿ×¸jkİäîîîœ6ö÷zK0)%†"¤ñÓ<Uµ6¶ğdtÆÉéüCß^$Õˆ€œüÛ‚g?+vt¼r+"¹›¤˜ğ¡—m™<•k ò4xcK¤_‘}çrŸnbşi`X•¾óò»({¼a~äU;ÍÁ O†q¨
´•ºÚ»,šÊ»šRÀ…%ª¾ÚÅ³°r(0ÿ_x,E³‹Wİ“]Ûª oé;Uu‡`# ‡_œ)šüc®!³²\ƒt:î£-‰úş’½ç†l‚{Y›¯œİxB¾YØõwÒf›ò¶|ÕÖgÇ”ÕÂ‘MSäÖu&'l6É>RËÊÎíSôÌv3ñ¡‚nÃf…ŠtA/¹‹ãE+räË#<Ué“äÕëûğ•ZKğë Å&Lr±²¡İÌ”û@
Ûfó€\fX–,_õŠ§À«PÀâ"€·™ªqÓP•¸{3áı±QE¼÷‡şjÃåi³hµ±íYÈ‰~``1 [9Ü¦:õÚÏ—Y¿~£°ïº‚æÕ’!7UÎ(.,ñŠjŠ8TÉ˜wòx=m¦¿ØÊr‘<r?÷×¥F‚Jş2†5ä$_ñÜl&õØ„|[+V¹Èæ†šÀ]ÎÕÿ(ïæ~®àwan ‘¢%›WøÃ^¬2{î_¤8ŒÉ5Ë?£,¢õÉ[x&±†z€ğš·†åòÏ®zÊ¢L~³[Å¾äZÃ•Ì-!<Ä…PÇf´ó\ä(òñRVñt§,ªfÒ!D	Ó¨éÊ˜ót¯g–Ôó“î¶ˆL®B2(”Ç!!è¼µyo^ğß7D´'9L]æ—7ÔÀ*>Ğreí’c}LøÍÌÙO5[F]áäÕQ‹İÃàg†æ|´ËH*ÄËz)Ÿÿ»¡@IÂ1ÇZ"Ä5'¶¸´ç›bâüEòj‚)û³aPõW7ÌÁgÀnhÙÚÍ{ƒªº”ãúícÂîø[µpîUğRì%´KûÍì˜o'zî$-…kO6ã{$ù¡¬êç ÁßU=7ıŠô”üpYú +–dµ¸ª’Ü“úã•= $ñT÷ Z.˜•7ëŞ¢í7… ğnöUI5§¬ÿ¢1‡Î¬O Ê¼sÕR|aúğŠ—3d%½1ø•R.%Ä—Nè•å®º¥rcànè‘qm3Oš6F´¢øXx=·!§`»Ç„–ÙáTÉe±7ÊùRAŒzZÕçßı8òSzÖfÁ'¸|¼øVÅàÁg+¶ø‡³o|½öı\H¹q8ìyaú³÷ºlãJãŸ[8™*’à%à¹­ÿ#í§ïÑ>n³oú‚°7aâÈzÑs+œ¡[æ&š R’Ê~¹ÏIóã‚\Vàİ˜à–' Èwƒ“æèì	¨¹€7Ê$CllFÊÒ]s™’n§ö½éÜ5nìG)rëg]í à`™‘^;øÛd„t¨‹;N±Å­ŸgÊ\ÆËZm˜R•ª»‘-FOŸŠx(›8õcåúéMj½iñ£×XöñeÁÀ¢#Ú‘sİŒ´’úı!fÌ.xG=¿qx¾ÔÛ¢*d-C’%ésŒoN6ºQÿ$»©NJ³´äêÃ^ª±‚ØÒp›]ïv%i&¦üì‹'¾W;€ÊÇ´Ûƒ~ÔÀAjJB³	^”f´èÉ_u¥:7dóXQ€-6ÁM8“KˆÕp\°¼¯z+Y1N}ACŸ•í‡ùxQËí¯q—2>»ŠCicœ PJŞ6}$‘h2¿=YHZÁROwë]œôT;ZƒIv©ÎW”ÙÂ'=›ÿ.E$˜Éiöƒq)É„ï)ñ °“¢ LÒß½Ü4¡6
‰–¾Eªó’wş+"_Àß¡DÇ^ï¬ô/k³İ€  ½#0«‰¶+ä)ıÀQk¿D´Br°±k&ú§ó	Ÿ
%Lîß{½?Ñš´%¼‚*5[K¡K:Ãêç¦={u€ôp”V8(Ä²7!Š{¢ğÄùˆ­^Û7}g'¼!<¼â|ñ¨+pgÀ’1WVŸıõmÆÆ.rã´¡k˜ôô5Z&‚°¾P-)Ú:U‰½ğ\lìó]†G N!`Én¶ª…[9„4ó[$Kö™]8> %`›Æp1ñå¥èTê‚ô).ÂfôÓÎ´kv¡›óHKIÕÁËSI¨ë±&G†g-‚!ÿ´ûèªèŸ¶ä1Zî)´d_±ıú¼dÄä’Ô9èZ I#o‘ƒŸ0ùDÒöÿ¦àj‡íÜõ˜€o¦Sªo§¬Q±ûtW/ô‘6óoBŒîU¡‰µ] D-™Œ²î ºWİ€´iÛüRX³FÊä‹fJO¿šŒßÀı7Ùf“ñÌ}²à
.-Í4I¿óÓ­,Ë¶ ô–0ùsaÆ#ZÆù!ë[VzApî	í?k uÇÒ™0-SŞÀ”tÕGI;ıëW”Ë¹,9ÚÊí|Ê¬¥°Áàì¶†xGƒQÙJ`
¶5R$À‰|}îpN(¯ŞxÜlÔ*ˆíîtÖ1È)©ıå0ãyÏ>Ú^	H×úƒŒG§>3Ê€š™¸r¸4Ç^*½»~xXñbÄò£¡]\s‹’0}aPáÔ ¶¬ÖZûr;Agpô‘ãAõ İkHF¢*‚¨öøT±Š/›1G®½¡Rw|(ó4Ã‘â\yèÔ'¡Wp„93õ™O£t¥zô1(2*[MËur9 ³rC!L’=Õïë^ œ{ƒkò¡Ñ–{Ú6Ğ–Î"h±~ô4ÓÌAãã;TÛeoÃş|_É&P'VÓ‰’)˜0ZÂ!l#ğyj¨×ŠN´,İ¶É›@¸ZQ#MS½ùÈ­øU¢İ¦?æ…_–Á÷/Óe
a—R¦RïÑT ±/3İÛ>MÒÚeA£]\÷âõƒç¨éçJÇ~‚Ä1àÊæÕëãƒ¯˜9‰¹ña¤Ûï˜ÂÖmÂµê`“®ºjĞFh	xéUí»oêG¯ŒZmúV	ÎjS>m÷0Šºü4äU£ioB8ŞŸO¾_©VUğŒ£G&ª•ã¸“T	™ÂçÁ—Ş?Äó¼t“>F4ÒgÍñÔwØò­ÈèéõÑØÀ–/	 ĞçjWBâá )]ü½¬ Ú;Ì@ºşazî€²¬ĞğŒÚ<ÆM8Åû}RãgkŞÄ™éıù"İï´BŠc€3AI"XÎØƒÚüõn3¥`ØåƒŸ—ğb…G^1Ğ\©™7ZçÄ2´b -ÎõhªZ †X1LÚ˜è¬µ,»ÂAü•À…¶T®úO:ÆMQaŒ#ÀÛÍèğóh§ù2¿	Ï·ØAl98<i	+\=ÇOÅCÀ5]Æ¿m¤Bªª ï¥8P›}ààa$|4N·ÊÑXpKUŸüÒ9\²hZ¥*M²úSyïh›"ãÑ˜%5·3Ã¾¢¦ô¤¸¥7nÆ94Ô÷ ÁqtŒ•>ÿ;ÁÕï.-ÍßÒ»mÀæLÅÖ<ÔÀÌ9ÎNx€ËvÛ‘¿ç4=×šÛd3Îdæ>Ç'EzK(G×K=l(wğ‰|ÉHL~öÿÎ(‚†é!ewü˜fŸ˜Š¡mÈ›CDÆÎUAS
"İf'ÄÊÆ.›¯C‘wŞ{Šµ½˜‚5 Ã3Ï1óÂ®yhÍtÁ·ŞG’ NÓÇ:Ã²İ¤xÈ[™m¬­‚w{)YÈ=ŸP¦¶39#ÅÀ‡(5‚·³¬>TÎ•nC/ µùiüy»ÛÏ–ëiöÜ×*ókNÖà”]®b5d,Hûs÷¢²Ğæ+úYR›  `SrÙ‘R‚øVëe9Ô÷Ùıg!è¬W«Ò¯	)!|OIØ¢¹+ñ´üW«óÃª(€” Ï!¾Ÿhâxj®.~ÎPÈR%g<”¢Â€Ùã•MZ¸İc}ßôJäCÅ8˜ÎG‰½cÎE~iöŸCV›ø«3ò}ñâNœzÈ~ï›ó IŠÚRBSxƒ‹
	7¬á¡jìšĞ«bHg÷%~ ¹8ì!\F­å;IDHß¼k‚¤¤ÅBKu¾â·çhÁÈ(&DœÚì¶º¡Åbó’BmX™d…ø@êB[[¡Ã-R‚i8M"¸Z°xÔ¾±3«'LoAVA
Kàl¸¤ß¹÷1Å#æÏO‘xö‚
T,b„:< !Msí³./Áh9R…İl}Œ]´ºÍ5öO¬óv²^ŞÕJYwÙ„ÉÊõ¥QZ 
áÊkK2±6Ÿ÷ĞpœvÎMSdcDéi!´­º¦bèšpš‚×WATö^G†5DOÁ­ãûèf.›Š‘¾™İØ¦8û]ú|á„¼ß³3 #¡Î¥füoõüx9µÜ’§…üz <bä_Ü¿òËlÈïÖ™YVºqÑU¢Éå÷úN.º}.i˜\o!SgÃKÄ`ÊIÿ¯Íï"YñØh‹$Ùş!àLör*áFV €;¥ùJÌf†xıxËo ·±j*ûò*®2ïpLm›ñ#4zÉavÊ†0jÓl1O'>‡!ˆ¢âÔ;õŒm0eÎL²|% rîÑ®*7{Å-MåØ³ícH‡í¥DO5÷äPXÈ¹µRv2i(|ªÍ’\åÃ+à}ÖI#S†”äo›sı+pmäîô|¡·Z]3ÙaÙg
«Bº?jÿ~ä'c>ğHxV4•ŠX5ú{^@Ó'»G94È°œôÃg™ƒ¥ë1æ;\V)ÚãÔ_.º¾V—Àf $ÖûİŞzœo1^zúpu×>Íºç¤éA6z“Y[Ó"` €õßô	#€~j“Ñ~R\©U„„Oœƒ0Z±hæ|˜/…i„¬4ÿõx|a*«šæĞìÅFd	¬3¦scC-æ»p¦²F„t€Û¢àiEv…Nå¬…²^£3ÙØ·8§¬—Ÿ¬ŒÛt.÷Å´öİö‚µÇÉµ'Éâ˜±dïë&´úáJĞÔí±ª [¿,%V¢‘‚»³Ş"²tµæ¼â1“×¬a$FiÖİâ‡Áñz0Nfs‡Ü0’4’î¶	´‡ø'}µA‡9ÉÄúŒmÚVk&6«o"±qÊÌ dÄòs@ ^)x!¦;'\7ÜgrL§ó:èÎ2+yå¿¬º¤>Õã®”ÁN şİö‘c—.)†dŞ}§rçèµ òÆƒ¥Õôayjl¸A‡÷ı N½¾¦šŞ}Ó»5˜Ó»e§ÓwÙ>¯±@Ï%‘¢–‚íw>E•ø•e›™Ûú-£Bõ– WÃ &ˆ–ô[‘Òjª’¥ÓÄÈŠ»ÑÖXeUÔ¯îmDİiR'ò–"iRŒèMbÁWâ"]  ±v ¼§¤oCDhls¡ı1Å}Ñ.ê$=¾gçD®+[í­fĞÊ½<;zNtt©¶pR±ùwräü¦gòN&­üum~÷‰%Òèè?ÇABß¹:Ñ˜3ÕİƒC8X£ïèÛ¿ĞfzF†djûŞ ªÚ°Ñ$*YoÇ•¬Ù‹´ÚC[æB MO¨ qj”+óÌWù5qÜç€xAâ“<­ë¶ò±…ØîWµ¦Ú_éÒ×©Ó–áâ0I+ó”üE®kY&MükÙÀOO@‚!KwüH¹âå—mk·«¯<èX¡ÅúßÛ°UÂM‰â3ú¡¥Ä }ìÖŞ¯|ÃØeOÎ±FÖ)‰GÄ­Ÿ§\Ø*h)˜`oŸûß‡Ya¢şİØ8èş3„U¹"=yÿ¬ÑŸmÆ58ğ„xT_k½=ÌÕFú´½®6°lP	`Ó*I¿‚Ätrì½í¼…=ãM³[ætb“Aµü‘·#¶ñ¿ eİ§ÊTŞ8·e„9PŠ¿_&‰@˜âÉ±ôÖöƒÀ>§¨ºÎâ—8ê•2Ãg[£n¯îª:9—°{¶YR_xÚ®ª™°ÙŠ³Aî_+İdRªêôÄĞ- ±îfa¤¤ÓKgÉ²)Á.³ôÂËæC ¹rQÂİ]V¡÷«ZàÛ	ŒÎªY8ŠÎY¹]ØpŠÛw‹ƒ3j²Wë3„ È{ÏôO“ğŸà|"1µ¢ÖğıvëÎ]¤õ’Â—Ì(ñßĞyÌÍûP­º±7»‹•¥=}\¯ÚíU˜öAgÌ[EGÈrHüÍ,©ãFßXŞìÿ‹$:?¤˜;O¶#ÔÀÑK:°½~ìÖÑ%!x÷Z®^ÁO2·i8f¦Õ|T ·GÙ[9UÇ‘ğû©éó`ße•ù9çm"ÏöqFói  %%!2Ä]äQe=šTïİVt£ƒğÙÒIk:aRô3Reè·šÛå*g
…iş&Øpòs­KWÎ|K]4
º{ÄÀI™Êè_ì’µé<æ €›cóÖ€dô)-ŞßP?#İhéàO[W`C>»‚ÇoÊ‹~ßô-ë 1]04cX4Â¼§g£[T¿(ÉÙ}FÁ·xÛúu8‡"ˆ^ÆR§=X	{—´^™Ë±‘¸|V¶Sño¡óËVêıg­ ½÷Ó¦bÈğJæâĞh=!
ö=²–tfÛ‘²Ã¦æò&@ÏT¿K‘.²Œ¦ ®ƒeYvOÈÄÀ8Òº ™«Äí†ÓÅé¨uÆ§39æW€H¡uD3µŞ³%'Ùÿ¢rËÊ5‹Âh×«~Ïa„Ğ´Í…˜¿{‘›!„¦k…a‹gPÆSº(°L¨¥)´ƒ.‹¾Äs_;{¦ÓALjñ¡¥$Ÿ‹‰Ì®–—OõíÙÒ¸îcŠçíH²{AhíZ¡!ºuÄÒÆeXZÜ8ıW7n¡Õ¬éJêâm›2êYØ«É‘m~ªËe†j5ÓoqK¡–"ê"éÄv>ĞÍŸNWÈ]¶š
øuÍ.NiúÌg¯ “	Â²x£‡›2oá6» |dQPÕ×³ïµ…UrhŸtT°ÃMİ†ÎRL™½üpŒú:Uÿ×ûÚ£(˜àÂÚš¡ùÿæF	i‘úÁhıì9”gçÛ\u=9ÿîËwG"§¸Ø‹Ün3©½²µ<ûGôOÈxä‚±)Š>x8Ìïœ$;S¬X››ivœcPKK²°úĞo_YÅsò¡fÜ¶!z¤Ç'5ÿ2¼;e¸.ºÆæerCx©×Û~‡ÿZ©èÛ’ Š¹!Qú9ûY=G†Æ¨l©Ğ›¬¯´TN®vEWL9ıé×¨ Ş9ÿ«» ùíÌ-iã0ª#ß*’>}H$›N®5¹BÚùµWõ€6­ªŠ¥Æ ‡&Ou9^zéœ¥ÃÍ)%Á{Ï£h,Ñ¹7uêR ÛK¡Ó°˜bªÄmÚh÷ÈÏ^iºh³·¦=Î?ovgøN˜Ö8"3óÇıõõ%¦8~¯ò<‘gå/Yè?5}0`´¹¿ß1wØtãæ,"2# ›E@ÕF"¦èã¥LËß×ßÆ¹˜‚(°OÚm|lÉ~;%ÔÔ†wÃA–ÙIİd=Ç˜vÅ€e<“´K²ƒ-0·<‹HµdDèãÃ.Ôb¥9£Â«ÙÿHõq¾~Æ¨M­ÁJSWœJ1t°v÷3RH[ó;lMîrm9âm›;ÊÍ¼jSâ‘	GJF0´n¤øûä¼•^c#A8Nßc­« nïÙ#úÇ(ò{¢ÙoK>N¼ Z~ê:¨ÿîÓb¯’ÌS‰'Á=ı®OTDÕ H5&…ogÂêæ#âq¶Ÿts5GCÁ ®·¥ —*‹¬L’B2e‚:¯N™˜Cj"äUqâç‚j6ÒFP_’×¹f ïgu–òM¯?âL±AndkÖ²)‹E\Æ·Í“8õãg1gpi—‰İªé7ƒ e48O×'Sá"Ä0r­ŞÂ-	ºÙWu\SµŒ•Xä´IıÈt³A‘Ò‘£>×[®Õ$,D®Ç÷ş}øzb_‰ÌKö&éºm{ÆÃ9:w)æ–Ø¦$GælKc—q«OÌíD£mõÔÁ.6Õ#¾u±rV¬|LO›„°›zØ-U%ïı¦n+İÑsY¤Ò@¡³ZxÇŠTâlp?ğæp:T=ÿe´&(SÇMcÏƒ›Ü'ÒmQ÷©TËô›=ovös6[M¾ÔÂÛ5Fõ=×š~M©çY.9¥6F ÍY6uN¦ÿ.Õş©¹ìÎ´fƒ·a,jdy˜l?ÄZ$ÓæÄ®n=ŸÜ:Z#›Áì¶ìŸ¾kİ.´ÃèˆKÀ‰i ı›fqÂ?\ñ¨Ú´@gZF{¸Ï{^ftz¿¥y¢ìdµäş˜«/23å  q/p×6mi¾é¯jñ:¿]¾9ğÇ€<ã™ÿŞú\HBoÙlk.W¡ô°|ØŠOÎO}R–Å³Š´«²#3|Åœ˜
â¸ÂÕTN$¾Aº—ÇÕæùL*â7Eİ§Ï¶ôFÿc…Cç;›S´
ÊÉ6^cØ ºÊ\E~Axàmye_¦±º ”Ã­ˆ*-‹-©j;0˜x.¾¢¤÷9¢Úô9pŞ[úX¨6i-ŞW.·zŞÏç‹}ñÓˆ¦ï×\vW.¥5%´ˆ\êwj±´gXè®	»)rUkâ_"ğ¨{j˜kğc¨+8¼Pàáy¹ğû7€cóºtC®*mKHk–±xLk0-ğs~­S©QÇch2ÃÉ£ ØûÎbj|aœgÍƒî…p¼ÛLì™HÖérVrì¥ÄŞ9Ùû ¡§kÃ·n‚\­`l]ÎP{Î.èã4†Ş?±=)ü­Ë>‰-­¨¿Cü>„¦;¤v€XF´Ø˜fé…ræ¸zy¯ğcüq’8×ÍFl™•_-•¯G{ª0ucä—ºô™ÉÅ}úì
şr2D»Ù„—Üî¬™)¬ĞTöt¼âõL^õ’1%ÔómkFÄ{dŞ–`§ù¹×ü>|ty(ş®8¯`3Œ=XµSMA.B¥Ãäêêì„º¾ „Ô%î”?ÉÎ(Ş½{Á%ùST´VOIH‰¼“;–2îe¼>%—ÀÖ)Øã»«´—c<²;»&ëü¦åÑ)tm¢¹Ÿ#`FKÙ†f!+aŒCKO:ÒG¦	©:Ì¸”Ï€_æ‘„¨Éâ-]ÙpZƒ?¸®ñÌÜSq¯}ÿS¾u(8šËOôâµÒm‰†Êƒ*5ík_÷İ7Ïtà&µQË"NómXòçCÙúüé]Á¾Ù#É×$IÛbe"Ê[Ó¡J'ËËÚu8g†/N“+÷ú¶äÅ9ıuÌfWÔĞş£¬ğuÁ©.uÿröÏ1^UÒ3ú9²çSæUæ9õªÄvèWÂÁ”H†å K’Ü»á]KÍÃïR91|#Àˆ{Ô?‰–y˜PX|Á[FpMÏ˜aË\ÛO„wyDÒO:‚ëK|u-f#í' ÿ› ÕÛ0ÿwè´Ÿ³ 3:Œk%#œ/òÍ¿
x§Ì¿TX¡5%½)‹çÁÖ/ë×«¯â<,¯àÜ*foëæ“éÿÍÖ÷‚…xï:ôà¡o—æ•:÷ùµrqqÀÁ¢‡—HŞû=Z‚<eåu¿ùÔí*¦¥Ôï„?&iƒªœ*²!fÿ1ª!‘ÖÉ¿Oã¥Q^Şˆ\;íæúR~ï›I¥úş{ctÜ¯?z-’½·tVVÊåBÀ³I:E¼bµü³€§KğóqËe1>púşj”Î—Ø$;ÄĞ=\®İT%ï·ã)eA¨°æpùC)J»?$ÏæsÚy	_„ ÍzÉ^[ıCHİpÌF<@\~[gkvïŠÊæ86Üó„c³“±Šï×K®V<Äˆ‚œ1ÃñP³šmÒY&=×Ç÷
™J¤Z_.?• i~e±˜¸^ØhÃê\I 3¤µÍ
·ÖêŠ€s±E³/D7j®¼^(B`CİõlÖº*}¹ëÅÎÛsµ¹›V¾ò&>Õ75İMb¨ŞƒƒšË‰W¥·ZÏ·Úà>°Õ‘ÏºÉ|	³(õÅç¼Ô8Doª:HÖ¸ô³Êò©İîAÃÁÌe'tiV!âËŠ¤FjÓK” BİC¤\%83t|ª÷2jvjC#·¨z«mD'¥"Ïk«Q cHÄ¾!ÿ+:£Ç×RÃì\c:Q´-ûĞqÁ®:0ç?@ŸÅš‰pÆ-n¸áôº°)¨ƒ[Vñ¯»•;_¡;¢ÕÇúNàr‡ó&ı4³iäP–*^<mg´ï=R6D<Z©"ÑEµ›¤1ÅI»3˜Ÿ:¬“0¬­…®a¹5Ê¿1ä¥úXH—‘nBò(·ÄÒ—–·‘Äs]—Óå¬8İ¸ë%;3îÉ@Ç(&ö¥©,Qğ)/vœô$ÑµB
„ /î9¥o¢{·œÏºvpu^,VV6¹‘ÖM6qUOıÙ„¹5ı¿Î"±™VshË(´‹€„Ñ`47ÂwÅ
Sığ”n^³:ŒoKgd¤õÒà8ˆ¥W5|¹÷S’u2Ä¦¼QîÂ‘‰Ó’„ˆ4=”§€È[ËùÈa[í	Ä˜ÏŞşâùô7™¢¹¡–°DG«ñ’MŠÓªËè.9l+ÍO§úk™cà¶qŠÇx°ÈóÂÖØBr	ü&jO}[1Hg5íoÁL¨‚°ğ ŞqÆo>¥¬¿•Ô:´maá)+ËL:š§î*„6Jçë»Aqo²•i½q2ø«ë	1½Óò?¬ÅÕ¥Æ;HS)±¢kĞ»¸ªWĞƒB=‡™=öó-v$Š[ºR¡Œƒgm&k}¢”CA,Ò.¯{¦ëx¾uæ ï‚2®«Ê€©45z´‰Lø%ÜÒ¨5  L‚K›¨’&Ób×êœ¦Ò¥)ØØ*_.L¶é!”Kx’”†z‘ñµ•`Xsı|ÉÕÉfŞ²4T3»0ŞŠd”ûSA”€Ô#$ÍI®4»èÑ°÷I¨ËæRt‡ıl(r…VË¦Œ™P‘‚â@~W]ãÅøè-æõ¡,9REÔUiï·—ÖÁˆË(ÔÃo$ÄøĞÕ¹Ü½ÖV1o	¿÷ã–¬‰Õª†¶P`M]êèhqùWS×½İ×Bğê¸”²¥¼!“¹¦ãè7|XZß—¬¬¼ä#,İ]ÑyÀX’èw_'Á²–æÌ”X+ ñˆ„É“ªŞ5	¼CwrÖ°gú®ª®İ"4¹(ÿÀâPpêÅÈÕÍĞRS²‚æÈh¦1=!X¸2†ñc!k
Š;YÓ=qbí63§ûtÓĞ6ŸÍ^îúÊêeGÏí²„öf4ƒIÌ½ô/]ÙÊ‹¼ö7;gÏç›ˆXôX™xyÁäH«t[¢chlyÈ„‚Ww»6F¼8a›ÈÓËÄIçÕMÙ:E»Z›ËæJ³­=-kN_…l—Ÿé·ıôßGl…şà~İßÊÊow	™ñµ  où¬Fô?¤Ë1T*öºñrõ}U™’°Êáø}Z+qñ'ºaHœ}…9œÂå(»Õ‰ØT-Dqi²í_'vw€çËKŸ“½a{ğÌùZº·ì³õMáEù,!šY¯“ræûbÂJC‡.4rËãÔu#ºÍeè%öQ<Á¦mì1c
X'Y²«s‹<É^û¤´ú%E?)xbFöÕâáöJm‰Í6]o‹¯†Wq‹
æV¢¾ô 1Ûº~ı2tl3U˜7ÚÎ&x†LïKåÚœSšr(4P(3R ÌïU‹ 1ŠŠş¿Ó6O÷L¼Ù}¬Ì¶­È;õ#Ö]ôÉv@Ä™İJ¹€ÕPVlü×Î{ÄEOÊ=¡–3eZ÷³H¢'üíGUôÕ¿”¿+W4¼ª—Rªào=åÍSÎ›^‘É*.²¨ÔmÃØ`(üPµæÈ-†?¸L¤†´»-@•–’-€#±e–É“`ŠÂDëp€!BæÃO:j¯šùCâùÛ+ ¯×0fòZp	ìi©Â„ù	hãoùª,<ÎÁõ×äAÚŸïdOæke$p":¥\6Í-´§Ïıı§I£Ğø€'Í±Ü;–9©ÆVOÇCsAïzÏ¢p+É?ÕÜmàÔU™î’ö$OÀ¦òk, )İ-¹ÎóîU
·$Ò_¦ºö˜Ë­Ùîœ4ÊÃÖ´±k:Æ¯)Jï<\föñmåu„3+ç– £™²ÓÒšàbÁB¼Ï˜¢”U¾/ø6~‹Ği/šFá«Œ›‚ÿôí-Wòè$[z"¾ÙuQPİv0(¨ÕÁ(r±ĞmfÉÓæt°»QB½…œRZ¡û*¢Iñ‚P-Sú„ËıV‰È3q!àÍ·‰mç+ÆU˜IMÀ¹EúK3úšµMúä÷|TùL»µ€÷nÔjinïàš9ˆÚ‚Å1SOÙ‡n¶¹Ú¹¸‘&ÛĞ!5‘„e¤•GÒtÉÛÒEb‹J´~ÎÚpA¢øı½Ú«x´kîÃUMaLÑîtÊ­\~&‰2šâï~V›—E’&;d)
^ˆÈ,¦¬5-Q S»Z¯Q“ÆÛç4‡÷’²¸R“÷hpNK)‡#Ù”zKÚøî;¿'&.Péã“|Ìà Ã•oæ‹»mÖİ„öŠA5‹á ‘Î¼©Ñá2ĞK´ì^mEp©r¯_Í.’*ØÔêi‚J¹z÷¯½ş¶¤\AÓ#“ºŒ‚=–¹úüDñŞ•µne·yhïåj†CDu”^Ï©ä>SïÕÅİ¡]$•=ºG2èY!^ª°1ÿMéëï“óÚÚ§PªÕbjuşz¢˜+€ ¯}$ğŸ(ç„Wî“…©~vx
ı“Á¬Pí$÷°|ôxHf~ó›°7Üé«·nn¢i×â0Ô™Dmµ"¸+iÕáœ z}Ù‡c¯ş¸Zn"4‰+^¦åæs¨Ñ`¼F+oÜ€‚pãÀnC7^].6j[ùø™ƒË2œyT^Õåí2|‹^¶0<±eñè¢‰Å>«qïš5¼¤l½*õÀ®Síc}w*E¼½xöê‘òúèh‚³ñog±ï “Ä×x‰7è7‰ËBS¤0 Ì[“I<js­÷s|lHVÙÏûW%Üsæèyà@ü®Ó(%¶ÿË$3HYîÒyBK·D®I1|ş‰ƒöù§‚i.]¸õó k7ÎÍ•Ê£6PsBeVm#pÀ?)C|f;—ÃU°í^ï ØQ.=ÛåV5Wğ;,K(}˜He((h©½è¬QBbÁÌ¨zÃB¾ã”l§·¿Ê¾y,ØêÃµáoS
é¸³±{øŸg²à’-Ó*Öv¦MBF=¥“aİ'cG%µ	¬ór-Ëp}ÁH´ûaƒ1¿¾<p§ÿ
<oÑKµ¶á
ÁéÀ8P|çÉ‚’+ôbåß0g?¾²‚F^.º$¡¶(%X&f‡e¿ÿz_*´-æì3*¸şÊAŸ¼—à7¹1ğêCpûñÃ×O7_oVÅ´Á/'úOé—I±qËTŒgó×
6ŸE†m‰¨õS¸4[®F=*yE[	@dA”bıòÌòM ®Şˆıœpa~	ù ~;Áğµ-¨Gg¥5<“•äe÷”©ĞÇº‚G(9&À{7´W¯°¤«^sÄ/h0İªI™~$Äå„—Õ—ŠÅZ¤Oßr©â†­>³nj¤†áŠ2®ØïÂÇùº³Må,)/v‹Ò×ÿMzŸ±v­£`¾ÌÔšÇ_É½¥/“[]‹ˆ°$
0Ï>%¸‰³C8ĞZà:mÒ@‚4}¤\ßyçĞäVPÚì"¸Ü|À•GÕ]s¦;­r"VguxÏĞ=h|‘ì«UFøâ(|yëª4=Uû£¸¬5»™1Ú1ÄèM’Zu‡·‘¹fÊ}qÒT$Ü;£Ëpæ›N¥Óë¯}›;BÇÁ¤¤Cq@MÓ‹Îˆu=uÎ ®!z‡–A0Ë£UKÂ:2™J|:ÔÅG7ùË—âKÈ)7ªç ©ÌMjüZˆ?Ôr‹~¢ ‰éJ <„†5¿§ßª*Úœr…uô”o´
ÍLYì ›<7"ÒQ+—¤ß9eî¨ñ<x7rIàÄuõ––Xàv^¸C‚‘³ÿ¸{³ûíS}çøhìêt£¥åÌÖL“şÀÛó+¤Õ¯Ù“Uÿ-6&{ƒ©Jz’I–û¦Ç·Ü q·GmFÕùş¯wX÷èßµmÎŒ€°á&‰ş,rsÑ\~5Sğ­O¼á³ˆ‹²c-çˆÜÈ™Â÷}Ë¯ñÁû'•[S‘*°Ìñ*QË¶
b…YˆÕˆ–©ú—2 `Iğ¹¶İ·€¾¶6Pª€N'òPÍT½¯±ÇÃ'rå
Ë˜¸p#}ğl{¿•Ùñ¨§mÿ7æşUVü:±~cµ¥™-\õi°r<TZõÙ5ãáÆWÇ:û7á	#ÁÃÿr5es‰jxä{°É€N¶ª ûå%jƒmo×ùsáÙ.ÜC£¨ÕÒR.ƒZfCSg»Gsä¯5¬š¶Ô§^9~|Ç–ï)I4…?4€‰ˆ\¹ÙqTùÏ1;FßæÑq˜z¦„[Y”—jdÊÍWM$y¨÷Á/´«•€vB)İS*30¿€H=H×$IÃ9»H¤êúÄª:Ö¢Ø%p•=Ã§İ7Ñ²²™›=èv»#W†‰\z+ñI!äsÈ€ Ö×˜l£»)BÀÂçlÖˆÒÀ‡öÊ	»ÆÓwš_ğOü§?bRĞ¢d‚šÎØ¦¢øË—Øƒ©RÒ¡¿^(g2O¤^sZı,ñ´_B.”·Äú0€Xn^±‹ºæœK²ùàês‘,6¶ùÙP'6o%‚¦×Ó±¿™ıVM7¦2‰SkĞå ¼gŠë³!²â×PÅ›ø:`‡Ëá]8;‹§işPpôHÔ÷™H¨ÎËÃÃºıPÎ¤mâÉ®sAfÓ÷ƒ3:ÒÄµ‘î«ËŸµLÍcLSO9¼
Z¯„§ˆÂ7÷ëBeë%şğšÂŸr„èá v1Jål@h“WŒ`Ñ;%¥È‰ã5>gxËü–}'q>%OK‹ŞçœogK3£ghjê$ 0fD8ñ¡±’ìP<3§¥1ùq"ëï¡Y–>\ÆÛÙHZâˆ—Œw4÷xªì>2ÂwWH} pó"Ä{‰ßµ›ê•!fFÛÉı¨T‘™¿–ƒÏûÀ³"½3î¸ËğÌ…’¿%>ª¢3Ğ‚‚š’•ÄKƒ
-cª,ŞÚÃw3÷WSw­bÃ«Ã©|U•åå^srğõ­ÀaFn­-¨0C=»©¡¤¼í½ç"¼«úã®,’’•ï¿!îWïz1ŠÇ]
|Ü‰ŠËÄ“n‡‚G,0t,§Úb?à
Ôİp\i Çû™y¢è"vÀ×ÂØq!¡`k*:)47ênùQ…ò¿„§øê~Î‹­ y'ÍìWÅˆÂ]ÛˆNv¨É$Á”#pğ%ëû0WØYx`ğ»ÂRk WÔˆÅµ´0ğÈÖ}Å¼?B“Ü§—E›YƒÉÒaÜóÃšìDŠ×¹a-EÕ/Â˜ˆ<}­SŞQ‡vÄbq²zü?Ú÷,ºA¬ñ²½Kåb„c~EFêIÃšoGaß2ıéM‰*Š9QRÍ¹ …e_ªfÖTeo¶êvœ†äå!;'RA`zeEGGV3Rbnİİ )ºsä!øªöŒ°š=â·„>yÈ¶Ôx¤J¹’±Å·&&ıÈÛK3²q;¶j|w3•·×Z:õ@ìä±ï‰Ï„aÍí£¦î©©?…œv…×ZYõk:6˜šUÜ·l[rÛ\Ÿ¨¢8ë{İ’}‘¶4øt:ÀYpëJÆ§ô!}¥
š•IÖI:§í¥4—Rd9gy_Ñ—ÌÎXª™\ZrŠpó•ÃŸ’šKĞ¤x7Áa‰Á°`ÀÅí¦½g‘üĞ®*ô]|læŸâ¬ÿzÚòµÈâ=Øã™hÊåÄ%`ê„‚‡k``¹äÙ%¥zzàõSâ'¿€>/ş”!$œYwí´´I!Mn« O™®„!óù»Q VËCkWB‹à ÿÎK$†ƒ–ÿ—N¼ğ‚È¬]B´;šÓ÷ÉóˆuZe¯U+*¥àåDa¶,;Ú=`ÒbÄ¼îP¾./:Ú1Ì[å®JV&D‡£ı©å/«;–#Öòå
…V¡æ0 gÁ¯qŠ•r&/rëcûŠ¸šc¥}Ô[#ÚÓ†Qqåñÿh]ë}»°ÕŒ"†±èÚ3eÏèJnxeMâaµÁv¶’mËkc{ŸùßütV]Od¹o	2ºqs'hœÌŒ6K‹†¤ã0‚C÷QÇ‰Mi‚·FîM6çó	2h;‹Jò?õB_şo\‹qß ÿMdn¬@o„K+o•Òz7£ú/şÖY8mĞæé¶RZèS1Ç?o0¡ñwà¦ÿ4<±1Œ>õo[‰"@RUß‰áTÀÂS÷~œ¾îˆ¿EkX Y»­Ì˜ü#ç¨¡õ£µıf•\z†Ğ™s
¨ôwWOd˜è!±ØEä…î‡õòºf<İ²DiÀëûÖ‘ëúiåÛ>×«²k
9UÉì|‹ZŒ¢®$PÅhö†Ğ¹ß="d;xqõ4É9P}àHË(f'zO[—ÂLŞ²œf~ÁDDH}*4¼,:ü³sÍŸ ®éL„ñ›é4™›6F|ÓÌi´/=e¸iÙVCÂwû³kn¾ßòÄŠ;º†k#²Êöâ'†°J½)t‹ƒ®ÛğøÈ¶:†2ßlÍfÜ•D‚?<œT"ÿY°¬€¯æ,ÜcSPI|&ËÿaOË/­¶wŞƒR_>
\Î ™Ğ0û:škcCJ+•û8öWÿ#g}+×õgiÄOÜ,vDXğu¾ƒjw¬Ój¤´iüéá«¶T=Vl=×,ÃOy©šAŞ¡Ü||ã+^iƒ!JïÁƒ‚ßú­GáÌãb“Ö°ìÊl‡¦Wy?›4‚ğl 0xâèºîa¬o@
›K#Ø¥~á¢5\Æ3€Iü)‰ĞâäÛ±4P²lû¿V%¾P©A¢¥ı×îŞMÒp‘ÿ+ƒöÛËÂéûßØ‡d)N_n(`µhNnî[ìØ¥Ux3G¥›AqFÕqßÇòAí{S™¸•Àkt9$–W£t·Ö'Ş=N§) ÔŒ“eo@hx­'µ‚ríê0òètÁ±x—JAH»Ğæ¬_‡åÃAMÇ£ä§wm)0æ9I@ÈİXlùJ\á^äl“›B•?5/¢gñ¶èÕ8,A0v»Lñvò™“
óµ®øéB „æ•zÎ	â…Ö•…¸íP¤bvÿE¡¸¢ÉI­zÇ_&¥a0
§ıhfó–IU`œÄd¢š¥itCE‹ªZ+şäÁ	Ó–å"¼ Ã¨?ì±VÑ\M×enƒÑĞ¨ïÙiQÓ\àv3ï!ô~òåÿj==êƒ©©§í†]ÅØ		MÂ  Pqì‚5ÃÖF“šÂ1-öD0§ò/xÅ…²`UN+vÊı(4ë+"»õâ;—L&M¹<ÅaXu`Ø_J¼ÂUçcvW·ÛñŸç]sŒOÀ_€[#<éÖG8~;ó¦‹·Ç§äF´zóÈ»E{YN¨ôŠæµúı³EUnÓ@°5ĞRÌĞâ(tÁãC­ô¤ßï_ü¡DçqÓŞ×…ªA@@9ÓMÀHyó4$6Ë>÷šÌQS[– M4Š_I)èïI|ÃÿBõS"×èAÈ/l~Ö©R SìYSğI”{@ÑµOÔÀ®Ã@õó®Î1»¨Z|ZrQ=B$ïø¯ƒÂ«œîMw/AãRĞCı$XİjÅ7¥ÖğzÂDˆ!*›…ÛLâs:1²”ÜÙrûÂø,„Ä8s…ŒGQOšĞyççOT’Xj(eU ±««ªé€u.É1ñŸi¸²ì7Ò¯aæl~âB²¢tÛWJ»ÌøìÉú+ºhÀ‚P;“·MO”Êh'ÎÉa	¦şV‹ÈÕ¢ıd@øùı¤JÉçô5úGò1¨>È .ØM…y'ã¶ên;ëêÁäq5`y·ùHËß6Çõìuªÿ°‰j³/)kq½v—R!Ì_ósº0ïYú×iªt ñÙU(wìQ¥ù, TŞ“¸ìÀy¬
SrPå×g5Ãó‘—!l7Tâ¥t‚z²2ÅA	d$³{¥…Å åÑpÅæÒ;]O
® éu‘šù}!At|.qX}WJ›#Hy$FµAGmwÉXC	Ë›û¬BäÊ}»h¨n°:_+®M1‹‘S-Ğt)E#Ó’èØiô …ü‰"‚nhsN0©7í>fÓo©y±[“½	ÿü0:2ƒŸ‹C×‰YÉ'Ã#Óg¾+5j;fÏ9F>/\•‘Î«óÀQpæâD š1‹ê’ğW¯lZ½*äëk€•<¿(j“ÕÀ#øÉÎä˜fk/qÛvÌÔ
ÇšÕ×dTı¢´]”ˆRMŠbµê£Sšjô§×ôš&«ßÀ`Òsx€3”ö‘şÅ‹—²ÁÜ˜¹üKß”„ÓwÓ·!Înôc00ˆWÄ¼æ;6ôo‰1uÁS`L¡ºı„¾‰ÑÉ¹Œ£îEæ
y©Dúƒâ@¨š§}’OØ¤¾9ºàĞüd!3º\:˜Å{$Ê`)¯êÂç¾¹õ:Ù¾È[Mÿ×–øÜ35:^`ùG°ù*`\¬Ôæ“^3²+®wEö¥Õ`,õ
©¡Îy[Kˆv¸D@À'`3(î|8Ò†bï‡šÄ1Û*¼ãğëoÂ8zlÒSßÖp*®cè°…3tÜ'‘ì¨-\+ÿ¯x½¢ŞGãöÎ~ç
³eÕÌ|¥­ÇNèÆGÅ/sÙÿ[:3ÒÏl¬ÕûëAMÒ¦ 9J$|àáÉñ”©æÜ_Oô,ÌŞ ¿Ñ“Kj²og0ÿÄnŞ‡4îÎ	Ñ»T½Ä¡YzÃ¹™‚òS•¡ı™Ï¯ùİ‘dEgqˆ(Bã‰İcrÙRÒ'Y†eO`xğóşP\'svÅÄ7ÿ,İ+rĞºw-ÇvEén ô²[òiÅ-%Vr'İ5JCÊâCÿKÙûÜÙL€eçïä×Åüu¤õfjõ¬Sy7ıÃ’{¡<Év&UTc£øÄâùŞ²‡©6<@u´xª¹}XÄ©Ö€[8%‰“ÿµê'rKò•S¥³ŒË”½‰°û@GÍØ¨COş¸káİ?WAn„µ!a–ã1fC¸á$fSİQ¦ÃèVXëár´`@n™ıg9ğ±™gåh¥oş6°[0S¥°Ú¶ò©¶“vÅœ8ñNAÁ —ì´=–µàªx\HB~$ì(‚||ä§£l€7ÄHß#jA7£„æ2;b‹Á¢º‡Y–vWCJ:Y3k¡lF9ÇF{8¹´‚P¯qHAYÚ„ÿÓ8fÙ~°<Ì¤ërÓ×¾b}62V„Z¤ÔÅE©ñÉ”;.õ1ãÉ;X”´Õ¦W|†%ùÇp·Ğğ‡³Qvaí,Èùîd’A…ËHÿœ7%e¿OøÁuÒ«‡ğñàs‘¤ûÑÏ.Ë¶iµá­°D„=•&?äÌÑÿ¿J>Eybß,¸HÄ ¾´$~rê˜ëığCÜÃuıuğÂ¦Pwì*Ÿb¶€²V@?¸¥Œ¯ÜM/fø&5ŸA†©m7”ı¯»µÇÇ«µÇåˆ“Šù\Â³S²æ¾Öô±üÜ€²v×—|M	ëP‰Š™UÜI\.Tıl«Xã,¤²„ÌÜĞõÛÁÂ>Sà-rÙ©ÆïNĞ¸-`ıx–Ş Ü®;Eh[^pY§v~²r‘áÙFá·ÀœÁ=5”ï‚#Ğ	#æµ³ÖæK]±S‚Üâ–›îÎß'õ6î[q§«D>ëÄõ»N'T“v¸\š•ÅW˜UüóİªĞ7
·8õÍl40É•„¦Eiï³Àô_pöç§˜Uö§çĞ¸Eÿ2`` Dy®¡¶YÅpè*Í¨Ç•ÖuØa¸^¾9<Û•+Øå{\{Á9úÑ!À†Zg}ñi÷+ÔıyŒÓE¿øünÙŠa:)us}9áSÛ=y Cøq¿Å5ó
 Œ§æñÏßÙ—„E¬~4ÎHÆúç\x+Ş(’èŸ³¡vèóÉ†@’Öy%^Òğ-`çÃÍb„RZÍ­š=RB½jÓ§šà[&¢ì~|Z´/O‚dÈ¸Aªú«Ósô©şK’â"+üï)ZYÄVÕ»ú¸ *<@'4T¬€qÃB<cÀŒs3±·lTQüÔKã&«q£ŠªçâpñØG
…Öâşf.7HäæË“ãÊg¯óËÕR¶W	pNQTI?aÈõYãAÃ£¿P1ùOKH”41ËÓ0µ?kTà`kÊƒzxvmÛ–âVÕÃµ+0ç!½D(2Ã_³ŠÄ…¼%øÇ›Œêaæ ´¢Ş¯¯³%¢l…@ç¥
Ï
öå<5.fÛWï³A1×ÚFªÙàZ!Üøm„à$ÙÁãà*)€‚‘ŒêW®Dô û¸aeBV‘ÌèCÄ^a>»+b‰IÌL¬,§asõ×nU%^š”ñrk½Ê4Ê>	›µ$`2q\rj šÂ"‡_î¯¨ãúÂâaCÄæğÀöõkúøıf°¿V(ìÄñ§`—iüš¯×1RÛIïtäğ0&XtYÖŒY[ßf¡ÆÀú¿‹œèur_i…Ú;…"Ã—{¤h	˜    ^ï0nélØ‡ ®€ X˜±Ägû    YZ