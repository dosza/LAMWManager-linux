#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="985143234"
MD5="c836ae27a924a86d4f5c6668bcdd054c"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23568"
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
	echo Date of packaging: Wed Jul 28 00:34:06 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ[Í] ¼}•À1Dd]‡Á›PætİDöo_¡¸L=®ä¬E_)h$fJ“
F§.µMóç\F¢’×t|Íµ³ç&„—Ó=¡^jGó‚²T¨vnê×±çÊ¢¼l.dífüi¼IôÎF¼%‘ç†gQ
¶NlqÈU?¿=”bSc?GßKÍ°gõÖ¶‹­w@¼æ…£|ş±¯x”b¡ØC§¼Ûı‹ñF-^¸S“|GÒ`ïÇ3â6Gk_ÜK~1¯S[?ä¿úÂáã@µa"}¡Á‹îÊ.Ä_$S”ªö+Ë²»ø'"½Î-î¾¤aÔkdÖBr—v` “tÛc,Uu(c.¬<rŠ f7¿ÿúÆløR¨©¼OÏŸ€¨K¥Á¢¹ÇKXîÖRA ÉŞœ, Šœ68wÊ¾İ'¬^{¬†;ÆWrú˜IÜÄu°±wŸìX8şDTÁ.ÜxıÂCâWÑ•­ôãşFrvşeİu±wF}g–"ÿ”:)û c¹Dİe¹Y[(ÌİY‘'³u™½„GŸçÛ!ş…¥ÇŒ€ÿšÃÉâdš¬ïNH:ºW<X±şğEj¥ÀËYù¿ó
ËòG«j;”xÄc®ğ›GfK·Ê4óözßá¿#¼²Tu¹ ¶Fu·2•ãì‘÷V¶t×4÷§Ğê/ÒK+éÖš;¨]Âmÿàøwó‚AËç–©ÁSgëÜÈ\m»O@†y\øC ¼`±”~ï"„n;H3ûœñ\qß±¦MgÀC“r$9’ ¤ı
t$›n˜ù¼(Té
¼$9NÁSÂ£¥=	¥MÖƒ—%qÏŞ¢$Uõæ>×FMZp¨AŒ¦í¦#V·vƒc˜F-½§W{«³Gà<?ÂùbVº¥å<:ı¥ş¼áôÈ±ôÂp*+Pæ#Ÿ
‹SYJ^<>uYsÅ$‰8§U4ŸúÎl¨¤PÚ˜V?aäÿ ë¸‡º0QAà¤uOV—U¡˜KmE`mr-d4´ÌR…${éÇÄw·i>ix…‘qÎMö¯ÒP‡l~5åyâ¡#><¬(œòº+}JÉÅéÈË¦ÆC²uÖ0o¶OîÎâl÷ÑtãU/ˆ+Ö\ñ£Ë2—O`3*Ük¾…1ÎT="§ßÅ¦cD&óvïoyÌHöóŠ+uÁ[ì!&Ó*7€íâšU9Šì:÷›;êeı(/O]ÊUf­€A}{ËeÕ$ÒV1Zx¿0bM§ü?Bk®"	R'°ÊÅ¤8ä÷>³ªéPäY_/¥oFÌ,á§ƒÅÅò{·XşY†Ãî3%ÉÉ=b•sıéè¾˜Ì?¸\*¤ïs£Ëìíã.œ/ˆ€÷jçVêØÜ9M\\Ö¡pË—•=Ï8ı"»Øòª„R¼õ>qÀî!¢¯É¤zÉ|Jä«ë€‚Õ( EkãMDU2ÉZì†‘ÉÚáÑ%~<é-9“vİ)ÖGr„O  ¡“½$9OiÅûxtÍåñU[³5ùÃpñC(­ndĞ_Ş£ÄuÃ"©”~—C9gA+àWw¦1]Ì£tëNx¥É‡Ø^Àñ=æøU/}:ÒQàÒ¯™|»Ş×–ÛG ùßàrrç…B'_&øµÅâÔÔÎvğÓÀâÆ{T•ˆ*l+YH<èÂƒàjGUZª“˜şÑÒŸ0€Ì›Ò/ÏâZú3Ø„ó9Í¬ã¶‹k¤ÊäÛÎüé¶ï ¬jmI Ÿİ<;e"Š™*.6ŸÕû[PübX;a|yö·ñ‘Ghæ'í$Á9J×øı¸“ÅøñG¾Â6à´n’ãyóğê¼NƒÊ‘ƒ—rİß>Ÿ—ı¡sPˆ“¹óä*§pµÈ…âÑ¡ßùÜ¸u©moQÒüéß+ùUêr¢ÛJdÄxrèÁú»Ø0NÙ=TØˆ5}ŠìOw6ŸÃ/|7‰º&ø?	ä±SGn‰š0/—xDÙ´Ô§ªÔmşŞËc÷å˜ş×¿½VÉFRh"¸»_ZÀ\J	e³WsáŠIö5òÙÚ^×ÌG6¨õš†vzeTÄ„Oî*`ƒŒ£U”z)]¼¥lë”£…õ½s?æßŸ:¯Ï[3ÄÊPµøG­Û7†eUlp›˜œQŸZ†ğ¬ØˆöÒÁiu3ö¼ç%İÃT†ô?c—}Æ@…Æ3#÷ÿÉCµuvW"í£”İœI˜]ªÍ,E!6>ë«Ã€7b¤€Á	étÑeê›*y0FL)¿­*¥,¨) œpÎÊ¾:ßë_epÍfØC¡‹¤{Å>àqTPŸô¨¦>ùùT£~n5’Ò‚Šjé¦^¶Û»À‹¼ˆ`Òhùjól&Ë»Ñµ†–kiYÇgãÁû«ÙÇwØ¦ûŒÁÙÿâïîÏ©®6v|® !•³ÜFV&™ó–¡^‡r…êÎŒZÏŠàœıã`(‰TI{u†<ÌÛ3ÓeEÿ»ZªmgEpÍUï¶¡jÅyío„h¥Iu=C{(É“»©«à˜Ÿ(®&i …üŒx÷MÄÔ†rç&ôù8›B‹’,¼VŒbkSÇUİÚŠ¼0!po¿d—ó²µÖ°tú>îûdø­ŠÙö 1EYno½[×9Çé-î4Àd¬¶‡î+µÿ'vµşÊòÍÿßr æH$ÈĞ`¸¾Ûpî\w9>Èf"ø×ú‹ÎCNå×–˜¨x:»Nxp5ßÅJÀFIƒ7Ò:ß‰Š["eŒ*V3 \Ÿ°J8¹@liWér·á¯569î+:å¶ëb/ ÇZ²€}'ÑiÂû„ ‘ûJ4ô¾˜\”!‹oú¶Å¸˜Š³G¼w¾¯èöfø ãÏä>¸GÂ.ê¬§uü0ú¼¡ƒ@$‘NëŠW,R6E;£Üğ}Í$uƒ§ì èÀ‡~®×ÏÓº|SO„8l·¦ryò>Ø\t®÷mÁç*P„Ğ>ìvËñ["Ì3¸rT;é/TÈÉòşš|@ï}È oø¾‹…ö½PŒ£Hkjú¸Îz
×Â2ó¤€ßJK²ƒïvÛq.EEƒ[ Ş¯ŒÕLZ´€sa	Ï}Bf-_‚l5ì]˜İ÷Ü÷¡H¿EÅA÷4
}‘-Æı%åã€Š½;ê[+@5,½FÜ‰“ùC;9…B èá E«eã “—Kd–=ÀEÜ~PA­>\˜¤/z#iÆ÷ìæÇe„èñ}ÒÖ‘Ãp‡d2®¾\“m<\s¢HhTNê?>ŠnéÏšdKrş0;F>ßë;æŸÿxßé5Ú8y-ê¬Æï¹¨¡Ó…í7a
án­$RrÀw‰¨Ğlß	ãF©(|ô q˜+TN¸ãùÌÓ¬tR÷oóóé;''¬…]Øj<0Yc‹[ö0%ÍÜ•¼µBğ½m*H†ñ'µ«Ğà7ÿ×w3ÜrîS­ºqçwğ«ŒíNâ¸iˆ¦¢˜ÛÌteyÍ4KİWˆYÜ®7@íp^l•‡³&+´ä€Ğ©R¬*²³ßÊ¥5°«ã¤Ù£Ä§®l”+ÂïÉ?ÒQÅ3X$hOxÉ¤æ%’«œCw0¾LÑhc‚‹ÿ_À¤£tÆ¨ªùoåGê¢Iµ |=ç ,¸éÃ•ù}U½Åuğö’Š±lšM÷†›ÿ±²ÇúéÆL] ­şq=£‰ƒ\‘6Å{ƒÁ°Ñš/q¢js4OŸ}Üšqğ²D²>»<%øT[Õ:™ÜÒdàp8%Š°ëLñ{TW´·µˆ«a£6†cXÕGrıfå9ôCzóZ
`Âº~`½ïš,àaR1«À´ù$®ÒĞ õrYÙB²ŠWIuİ3	Î¨}Jy:+kù¥zJóÅzeèr€aºY Ÿ6<¸‡Ì²:×ŞÆ®ó Œÿ¸®W LÓ·q	@‚»^ÄÏvjøËh‡.’.‡6øtíltÖ6Š/x?#)c%k‡­ „ÓƒÈzú&¨€JT'ºxxm£š™8§õŠÛ»xšn°R®’8ïŞN w¸
'}[^€ŞÈd±œA	Áİ3èLw&	X7€³î¦#Ğ+# Ì1eÿK>ZŒÄÕñ°µê.L­³“Gk¾Ê ên2|*Eõiu¥Ç¹*Áä11ò1³²m pPØ¡œf~ÙÈL1½Ïc‘‹ci
ó|ù¤AEà n&/'!_ã.‰MijÊ?=d*æÜ* E Ï:ŠDÖÓx­±XŸü¿ÃÈWœÚbH(0Íïj˜YóèİÔÆÂe…öLÊrüïáHü/4ø¼±õ?	Â^õãäj
i}Àı¾²HKQÒeJ9;“Ÿ¡N<„iTúù'_áŠ×‘q2×Æş%aĞ#RdSÙÿ²¸Ã¯‘AF YXUŠˆs[_)K}-‹¡NÔâk]IOgİhgÑ¸’˜hD™Ã-.;yéÙP@>Ù3†~¼”®üâ	”M_"Å¬t|%ıŸ>Øòª•·Ôî ‚r´T-¦«uïwP¦éàï08d“"P{´iÛˆ[ëõw­¹$?ïP Î÷÷N¨Â¡dÁÁQHêcA.Kø—GşÂ&#ÇÜ)Ïhğ{ ñ“ŒS'§Ğÿ¹ûÌ³où;•Ë[>=äSã#ôI¡A*,ÏkŠ‰|<!]AO_ù­ïY“#Yõ”Øs>`¼ì4xK^®w@eØ>Í`Ê¢>ò¤v–y¾ËY¥$vŒáe&/˜:Hñùš ˜Ãn„³Ù¸Ûm˜Œ¶®jVÕùAÀĞzP‚¸<x=i >%zµ£²š±–Ä«ÕG¾J§¡Í5ÙtwöÛìmúAÍùJÿa¯ã˜ùHÊ,ÊÎóœ!ËÎ6u$Ù*î<ïw&;me«;]ÃÊ˜ÿxÓÕ€æ-Ê-Lƒ–Sƒ»”X:#©ÓTÍkÕ«Nï(TœÒùƒ¿İ¡¥‡ »„ÉşÉøN2gø„OxÚ0“2`€½¬Ë¶¹ÂIBW;¨ù¹¥“/ÛÒ[ÔùÌğxÃ•’Ëf•İ(GÂn£ª38TÔÿøç‚é¸ìL»’İ‚ÿ#7	…ø;‹¬õD•$‡mD×$7KQíU‹•âzSLİ5Ù³d¦¡$¢,D¬Ä³†•Z*˜`ÓÊ¯¤K£;Uœ&_›SG`s:#r“’Ñ§M^»¤‰ŸcXçyç®ùÓç#QÚìiö8Åı¾2UP½=–‹ª¯â|û6,úç¢ŒùÙK)ÑñŒ¤û4w»¡{ÔíŠ ¯Ğj,ÏbàG BËÜ‘‘B¦q)IN–«i$ì£ã»`–kÇÇ³3nÂrÂ#ÜyÉ<H§Ğ#Wª_.‡ÃXÓ¡ÃÀºe†û™pzôÂ5¥Ÿdv"  Qåu®îmïêş±z?ã'‡< y(¸²Ÿ@—´=Á#Aªî]©©G>fk­¼?áq”ŸìÜÅ22êÅuV)lA±­S+•ıÏÁU²7ï^?S³å¸ÍKU{â¬X->æ¤ÈKeç…_ôAA îÉ´“«f_ÅµfÃIR[âA¡K»‡¡úxQÂ$Ä–‚à^ïAT+¡½í¾‹ï4°30FM d¦W¸ƒ‹¡ññ–ô’|îµ±´	Ì;.lñ’{Qq2<1•Zîi“İdT"@tºƒŒ±"Ìm“BVĞ.mÕ=‰ÜÇ«ôun:t«³ %¤ ÅÜá½‚ìxæªœÛc#±I\Kl#íå+(¨~0˜èld>ş%†qİURR²ş3İvqê—êqjÀÊğû@ WÛu>‚>ÿ]dåê­,˜º(M‡Ó1Öp;×‚=Ğ_$LOXw¼«±§\Wk®‘ |EÉº~L›XÛ¼‘Ÿ9àÈÆ>oƒBQ¥ªÂööKï¼2¶~GÎ3˜tE¡mİØ´ËËµ …t†¸µëÎº»Ìd\È6ösKk‰~¨O+dNø0Œô¥Rm"Âß¶ÙNzVîë
Ä)_a²£a°”­çGı®zíÙI“Šv‚ÄĞ±on–íba–Næ¬Ï™ŸY³{ÌŸl'#8”Œ‡í™ê=æéHš7oÛæÑgXt@-vÙ„'röYôH-ûN®İ~ÛĞi¢ãPèÎ]ê^“üY§D¾_|Fli”#{´‰„"™{:ÿ¹;J+—píÀ×Â[RPø4E„è¼ûf}"ğ–×O_›¹×/¬’o´îŠzåüèßkâ>CW—¿k°…k²äA®¼ôŸ+.=ı)t‚WÑÍŸ¼/ÔšÄh›×MûGßsM‹ƒhúŠ?²†<JrÜë#èÌKª%fNfÓ@5í¸ş;Èz_ƒ/Êo²"|ÚòÁºírgIöAZù½ZD’U#›pp6’_W‘ìêÛ%a*pM¸›zÿWåT™Ìİ_¥ˆ0µV&	µÔÖÆCÿ¯ı|‰À&õ[ı ÌØ *cşË0}Ja˜ì]zn®Ò†“9²\‘t&®§·ûëƒãğ¸†hönSÎ/õ—¶—FS|£üÛT
í&tB¡|pÀ÷fw%È¬Çne¿(e"Cœ…l'MéD°†ËÌAj6O ÷qmØ¸CàoÃûtb‘{æ±SÒßvnZ½yGÈjO˜Ğô‹öZãùëÕŠp3Îå—ô|1äÈ˜Z" ıŠ¼/En£áµ’–ÒgÙù·ÀÁ™™ˆ£x†s{¿òpZ49æÎ~M`Ò·o|äGşZÜFùø HìgÂä‡Êp.(âpH8‚@–*ûïj¿Ÿ*,e@*’Ä¦# äS5Óß©·Yy‹»0ï`ë|\HÌE+å!Ó×ş63}ÇªJ¡˜ó›3WÜsÀQ˜7[ß³éŒ¾:ÿM$~¡ñ>¶Î­	ĞĞ|ÏìhT0*"´Â‚å¸ÁtAVL" ”ÛšpöëÖé\d×`3+û{³©Æf0ORÚ,)Â)¤PïËõP¥˜éieK!•xkœ'*½8•óèVÖ(ošys©šƒRCÕVcÊHş¸¿°üäQ€¼¢TŒ(<Øj²ÓW¹õÃ©Ô‹‰ïY‹.#ç¯ÃÁ3 ñ‹ŒRHà<4à×îú!©¾Ú.Ä÷Ë€ìØÆ¦tÿöó
ı¶1[b¸Á·ùËÇÛLáõ9²ĞB;ÆÜºÇlƒğ;Q|'\ÇÒO‰Nñ	¬(ƒ,–ùÕM<±Ïs‚ ’ÍUÁ¢€ÿ«ZõÙ¿ÜO8gøº¶Œü²^çÎHY‘eæïrOp>’Å%÷¬R¥f³¨ĞŒ€3ºˆ¾ô§¿¶Ûv–2o•íÍ
Eº&QœaNWXNÍÚìŒ•‚;ßUfºbÜŸŸşCİß?†:F¡ñ’Ë—”€YÀ1fQà“!.X
DŸ¤8Xss÷‚iWĞı4ú8z/bşéî´€“Ñ·ÅåurvWNJrCÃP“Ø®_Ô~´Ó Ú ~®¯ùâ‰‡n%
D`õ›•¼ó†Å›mıàqúíßÑs›ë*’ºË°şô'ÅŠw8Ç¯-(ù
ú+CVS*8z(€x°ú¼à:¬¿şØ4Eçû£#ŠXš€Ípãsg©ßZå©7Á6˜¨ºB,oÜ°Z§?0òÊe™¯Äù©$¢m
>kÉ-Ei Á=i EšSï î¶ØãÄ¥sEV¦;koIEÉ¯=£ÀÙQ¾L‘y·ƒ¦YĞÀßƒşÀ,EèóˆÕñI"Ä2dÂ“vhØFÏA‘*aqÜèÏÙ2ŸK	Æ¹¾(…Á	aĞ#•íòÁ@ÈÓLó´5á!ª'áø—Ç@"?&Ûa[Tx¦ïÜQ0 Iyñß2U|¸¹š‡ ®Kµ0¬˜ü¥T¿ó™h ¥fHÑ[æ—¢B]çrJ<âsŸ´£Iˆƒã•wE)z/†,T¤´WxÊZÑö~1Á&ìú±ÙêóÎJìÊû’„§ôÃsp	ØríÌN Õ¯fáá¡.ı¯Ä²¦cå(Æ›zEh€	³Œ­åçî¤
¤bWŞ8 Ê&J-€ÏsÇ#ÃÛŒ®iÿmwv˜ÚÊ›‚ec¡„zÿ`eWT——3¼}ó£•0ôç¾†asû'ñ^ŠÅ¦càƒivå-Ô`G%N”ıØİ¢°ã£qÿåÙä“xéZì€]öôPPNeX¥/^%~m×è>Ø£û®¤+$•ÀM¾s¦±µ††Â*(qƒÇl[
"}‹]>z¡6íñ1™@œé„~±­¯½Ã-ß‰]6öÒ”SŞO«é~æüÍ8œàš`³@ZŠ-I]ºx$F!ØÖàÜªaO~&OcŠŸS@ÛXÍà™²óÙ±gÍk•ŸÃt{'5¨%ÅSÎ?´÷ù£b	-o@÷Uênø³ÌÅN¯½™2{„(§¶1 Ú„C£a"Œq¢°5~æêsÎí½A¡.¦îaºswË‹MƒºÄV¥Ö Í»²ãmÂ™ ®kŠ;ô¤Æ¾3K[}¯bd#£†wŞA…ê’5x$»Îl¸	'!åëßš¢¿’™=y½åó’ÚQiaÜÃõ+`šôÄBÿ#Ã¾‘¸ı"‹‘sf…!À±L-Ém÷Í4ß‘rra SêC-µÏ‰7»@R–8‹"Y­ä-¿X·o9Ù×ã
öú)I¸Ú©%ë•ÕîyPjÄ°—f*Ó(xÔï0·Ñ·ÜrN£zÆEtœx|`éº8Õ¬FŞ ¦Ì5}!¢†T¬ñÛsµzª®ptÔJÚÇpü‘ÚÛmÂhºêU_âS"ğ¬ö–O¤QøA–P˜X9õñØµK&}1È²tŸ¥úCIt.±ãµ;È´Íš´Û·ØÌX-)í½¢häÌ;´†ƒİxØ%,çu½ŠÏ;€¹`ºît)ÂdS„#}j¨f,YwŒ-ïz=,‰¥µ>ick£ùiÖ_–ô¨>6·¨ß?F83RŸè½³TØş€&Gæ4,~ÎZãÓÊ»î· r`´Æ\
kµ.ØÃT_õ¯'Ûd‚÷íoÔÕ,ÙšLH?Z”IÕ|¾L!}B'••üİ?VÕdÌWq"\ Á­W(Ç’yg¹„ª•)V22FÁ"ë±ˆÈ©bê&ì'îPªáºe‚üVlZ¶ I8[I#°¡{ìŠ)Öb¼`Ş5ü¹²Ëw‡˜Âèôsä§û>8/Qd}kT@´şŒî	ğEÈ¨	üjû‡»åSÖİYo
ŒN6îGÇlD2«öj¹•Šaò’5u™ôc‰ìQ/lS+@‘9İÏZoÅÊ†šÏüØº»µ”ÔœØu®í·Î¦×Rj7´{å>Z7Œ—íã\ï©&Yö?+·³?¼=¥úÅñr‚dºˆ´¹•SËWÕıv·py–Mßú˜å¶’¶7ñûOi9;–S4J{[j€ÜÆ fnÿ·•ö&„ÿ5‘ú!O9¨váåËÑÆæÛÍ°É–íH -ÈEßw“~ *Ğxè>»DÄá¾Ër/±¡™
Ÿ0£“¯º İšìFÌ­ºÅ›ñA?hº‰ŠÎ¹$O™d”Y;ÉádXŸ^‘\ÕÑHlÊ9Ô1íx¼Ív•¤¯êAÄ]t(UJ‰_‚[ºv/OßzS–tíØØZÇ‘ı{eü¯'Õjæ“:Œçx.Çşı…%#6šœÄQ5ß…%ÊML)ÿKR0è•<e“+ˆà÷ı€Ss•¬âŒ»y··_˜ß¾râm°†3h‰÷?ôR¥³Ôëˆ75æAø:-ÜA%¬öïmQjÅ9au™-ñ˜»‡òƒA‡Ë‘sh£rrV.ÅèV™t2~Îƒ{™'aÁ 	o—Ğš`t÷jµæ‚ŠWr¼c¸mƒşßúÁ+´Ü9•S5ò¦Ò}ˆü&ÉğJ!œÈ¬
äaúùÙ3½¸s'ùr–H@è£›QéÇWÁ
"L*4ğkW$97qn‰øb/t'ÎÛ„ººè-o{åŸ¤ç
‚_x{Àd~¸ Ì%ùmwÉæl
Y4A×½Mv q:¤H Ÿï-?İÉÁïáR"Ë WÄÂøJKòı¶®Vsp–qâ$¨©SoŒä“%}o± ;Qq¾,øVÏTÓÙr¦ñO! ÃÑHØv&2qÎ°¿ïÈòÄ+¸LôÊ7œ â_g?¢•pR•Bª5LÌ?§V%OÖ½¡öÅšàŒ4-1˜–(¹/Â²N¶ñä‹“‹;¯–!LZ ÑÍõò—eBØyÓ1o¹Ç'Øu5xÉÂÕ!k8ŸWŸz;Ã¸oÄß‹‘"1:¿õÂ'·š…—|ËÓ’•=]-8i;ÕÏlƒ¥2•M—¾æ³ÔuÖÃñœFy«Ã.áS'cÎ<ËĞÙì_çšĞP_,èÇ2/H]ğóSÏ*{ïP˜3êD?Âé¯Øí©wk<ä×ìœ°ZŞ(X=“Ü´™ãNmŞ ˆÇ¼©ÙÓ,+û]/†ÇSºñü¤¤ Ğ×XTU-}|“KÉ;š¥*££ñ»´ft…ò—*ŠydŸÊŒ×’<¸1ù­'T€$bîìDÄ‡ ñ¥ó¿ı47"|ës­7¬o™Éd5]w­*¼Ñrä{ûŠC˜·o+ã.Ì[NôŠ?-ÄÙÈ‘â–	e3%ŠXøŒÑAªÃëõ0*8sàZ"¶sÖ{{·ó&¬!Ó;¦1#FìJ*zVO¹ËÀİ'ßzoôÄÚ÷(;›ÄKíşihT	ê]ÖAÎsx—‘|Ø5“‹…¼±ë¿Õc]O?>ªÀÀ”a¢Gdı|M– g:CÉ¾!‹a	öËó+²›‚¤Ì+$j© ˆ!ÿ¡­åyŠ´0.û!ÌÒ'¤æ{ŸüäpDYE%#ø)ş¾Ò+tšó%b0!f™s{BFZã`¬±Êr¨GòÈÈ<”Xó@á7>]Pu…Ùa`isĞi¸YhNRÎsÀ©²Ñ[æˆ&şmQ¨Ó˜}‚ÑÆT(® Úp%xyma¡h¤“‹*éÃQÆ ¶1¯ÂmÍFú"ül3
D¶îú•ïÓ„öÙv ¸Nù~/K©òd2Ú¸œË­é_ºM	záĞª ,.E#€ù)Öì3îıî3¤K¥Ï3’Y+1ú£òN‰~òßpâÌ8°Ç:éú£íK¦W˜YÀN°0jªUfNHdwø²4j2õî¨bUNpÄ¸T¦ïä0‡»‰é{)ÂÇµå.¢PŒ…Ñ%ŒPØèMĞ³m&`ÇÀô•%f=Î~N–ÕÑVÖáÉ›ˆãÉò¿Ôz»æ 1(‚hÌ>gËAÉêæ|\[f¡AtN˜‹—Xl8A‚,^£QypÀ'««Ó[ı£÷S³äÚ¦XüMm¯0Så†¶|.Ë˜©È™&A^§£P^Ñz<'1‡QH…dÙêk,»xYNSÂ ËÅ®99“WëÙ¤±k¹¯hŠ£¾İ€Åá“†]=ÂZUÁm¼¨¦ºÖPv´ÒÂ›2ã-Ø†v?.47Ø¢8%õíÓ´ö2
iwÈ.ØÊáé’÷¤\†õSwrïÇâ8CÂânÜô9ª×C Ö5Á»îCf c(º#.°Q¡æ_;ÒYúâì7pÑ¿Ëú¢o7!H“ĞkÛÕFí’›DlËM§S”† B¡‚Jp¸÷ì5;c ",Ï±}¾¸œ$¯‹šâyî¢]âá_OS£Á¾d3ËÜÃÉ\½–¢ı9‹“¬ã’¦„Y}SoEa÷t–i«âã0>{F™7*úwPzzI"0}ÄƒİkÜ:NÚFµö“œô—+CZyÓ®¬‚ù¦©`O“‘Q’÷í1Qòœ#é¿N¾ïš­1b§¦HğÒß.CÔpdX?³ÛøJrõ™1ï7NßÉ4HR”*Xö¦IÏSQ“_”z%*íÖ¦%…[7Ye»·EòrTã¬Ô¸{3›ôø«´ÄEûT	¯+Œå4ÌÉî1éN¢5$ÆØğ	ÿº—\IŠ‡…±\§™åïû:™_/eLUÚza}x&÷hœ¥M~òHÖ-ËÒÌÉúkÜ`æÇİÚ¹i¿Ÿ¾ÕĞŸ‘“4K»n jŠ¾ºMˆ{!îÅ/¬G=4)/¬=Ñ‡¤üæâ±
|"¬‡#ù ‹(c½näş;‘Añ>›¡NŸJI)îxKi¿*ì~ Ç»hóí¦Sº}ìê4õ¹|BN&vB·LİEÅÊe¼ œõñÀKŠõx2sÛÏüV¸öÎ.,UÓœ»úÂ"%«¿Zz&˜õƒ¬|UûÚ8İÌÚwvHúc	ù‹âá¶‹¦/%¶({x—tÛ(@ùzm?~â`”8p3h_*Ôt2nmIk9ÅO’6X_÷–V¬PgN‰ù*#åUË.I–¶?ÚR¹È{¥Uf &À^7:»Íı\(ª/;¿íúzïğB•F1kkºod…—UŸ¬“t‚ÍšşA–Q!A£kkxhè'üƒ.ø‰/ş…¾88R†NÜ£'	z²|L$Z)Zc ¥wÛ$F-9¡/:µ*íMP•ËrŒOf¥w½…ñâÀ-¼Ô=Ñ—?‰çÎ«eyÀ6w}!ŠÓ”¼"}Ï>tP·Ú uÓn•r°L²ütªbĞÙ—jqÖóvk½á¦CdLU§¹Z@îë)ï¬w
İõ&°ÿG#¨<5¸5.óbóîú`°Y\·şNd®Â]Hw‘4kyÁŠÛ<Ù,…œÆ»ÙÇsfÙ/[}°ÈÈ[Nuà Ç¬$Â·–»xbÙmHö‰³-úûúB«ªw¾æ5=z‹éPÛVZrK“˜µÚHWÿÅÎ/Úµ¹êgšÌn]ËX7
»KÒ¼ÿÎ 
yÈ)”®ıËwÕw}íiÃ%×«j‰ª+E%¡^=ñ¥S÷d8V	¶+İÍšsZøY”éy¹Hø¦š8lHƒ¨”âf*Ì}Ù:á0&Š‡`±=OVêmØ˜QWæmú½3æÂNORğŞ	 ‚«ÈÃK«‘'šI2î«}H´ U~ÊŒWQc¾“İ>‹ Û7‰¼Ã&èé}Ûoƒóz^NZñ2ƒ˜Œ¹`òû°ë?G±ÎŠÑ‡ÄÉk)'JPÏiR5“i†{¾WÁkÔ‚™ÈY:I¤†:Ø)êò›}å3ÍPRØü°7”+0ZÄ(GPÏab`É®h¾4·G©
køÇ±íš•iŒç!Ù§OCåáImB|¦âh§°÷äümğvõÅ†ZZ¸Ô:‰VØæ£%7hÎ¹VŸTñÀ³âø²®Šê~
Ù™fQàqè%²E3XtŞCû²M5>P×ÅfíûgëÊ¡­€¹9ëeÒ®êd”’èzIÑ®ñV3‘Ò‡J
O”£ ·6ğE`ì1æÈ®`yş(ş?×b@[Ì—U)ï‚û¼hx}š
'­Ä+ø#YÑ¼:ÀPqHÁgCÌU‘;FçTBTèüdÉ¬i8ïÖ¢”Ù
ZR®éÅ¥—‚^T¦œñ‰·?²XÆ]ÚîrsbEò|$êŸ(O ü¼ŸzXTOSÑ!•=_†c(¤‚ğ—èS?èãí´ë@äÂvÇâ…·
¥x˜\õ‹.Næ‹,÷ûWÃ€z<tDˆ5ÿâPÙå m¨™aûN|	 xŒ;±F@ÍŞêÊ€¬ bUKÜõEl€Ìkí·p‡\t¡Öú÷zõ×íMeªò#^ú÷å÷l6¢£«úp£øA®TTe¤½ Fßõëtƒ5^ßªzc-ˆú0XæECçB‘ñõîÌÏORZÖÓslhOV*¹û*®lÄğ¿óûÍ§‘^Çi·¤MWßbÂ.rÕ‹!Ë”Ğ;0¢H¤>Iaêê–¯¾>3ügjı*gø<A°WécÛ}ûÅ\LÓŠ¯N×_ŞºerH›<…ËB†ÇbZ"tR,}µPïšm\¡¢±âÕqùğ#pqÙƒl¿½9O¦×€›lğ0ó™z0)­!ÊòÊŒU+,ag…AV^µÊó(ôÜ=¯oî¨œèXŠOc?‚['¹pz‘ïİÃ¦îáæ#©X7[s±Ğ1§©YR¨	#7Iåi~¼ôö3:9/ËşÅ.|ÚxªÏ•¡/âgü]ï³-÷wŸ5%²Aøíúu3ÄM1H–ÎXµ˜
s®¸¥¨†‰'!Áìj¨\È·L£ø,±'Ş{×Á:‘şCF—Y˜Ì9ıH(š‘@aŞ§*1CöáK>TiÔéœV‚ìİëĞSŸà®µØ€_ú¹”—íD¹‘m¹Ê):¢ƒHYÍ‘Ç
é£cŠ¥wƒ³•¢ñuáª!·»Í nF¦‚éa‚Ü¥ôÜ¯KO–ğuÙûÜz(ëç4¸<Ìqq¢w<£S×›İÊ	ƒù'W£®§X?İ.lóL™¬SE=¤Q[Û{ Ò/ö^8ó}åc‹SÎm…â`oªëùØ\Í8os@ÖÚ¬rÎ°ô¶"ŸI‹H€9F"”¸¡9×¡, à}Ç(ªËJ,Mo™ÿrIè[Õõı#éƒ”Ú{Ã–ürú_:NÉù¼»ævrÃ1¦<u
È‡´mòßÅ8 ˆ÷y¼)«µ©‚]Ô«SÔ?ï…Åºx)2+ò;[lîûk^ \×Îp–ãŠiÆV¡ƒ[4Mˆ‚j`tÒ1H‘üivKBØ%ÙybµN¬Óä£>Æ‘%òˆ;27éJì"díñ×jp"Œ¡ÒLà ‹Æ´õwôå¹iÓÏ¾vÊ"Ğš-(]¶ªÌ¹Úc&½J¸z!¿{õ$/bYBJVÆP t€İÅLì¸ßo i|¨tç®7*ûÏ7;\*uKÎÄ%# Ÿ½±ĞCh!ª(ãPŞ¾²ı\¡è«±´¬XêÏä^ît{½ÏR©<"/-®ñÔ|[“úı33¥887jë6xŸ½çiUp€^‰OÁ"û£Š‹X¹õ/j4åçAvG<uï3Á$Ìc+Ó¢£Â{s#¢¯jj¢š;¸~ı'Ş[xâô7^_x™‚¢ÇØ¨‡7Êeaß»%¥ãv9Ÿ©|TA›úº–C8UıItè·Wnìô•gêzmóÕôÙQ†«Àıü4Ê~İx=ºo3ECç›íøµŠoÙ	—#ìÁìÔÑÕ|5ÎëíˆZ¹ÑHË•w@tª¨”s¥ lN|•-ÊûVb´fÏ¹@˜iÃÈC“Ôæµáæ±æ™äP˜	L§MÈy–°¶_,+zz£JøîSilHB¤hšŒW°j™P‚†ˆcÌ‡HàAHÉ¦ÿßé\#¿6tpˆ§Íä’Í0^íÈ¯G@:,"ÂYFÀHdÕE‰Xk¥½ ^{	ôå±kˆ¬“Æïy$Zö·Á¹¼O^-sºğ*òg{“JÁ¾Am5ÄÛd0;ÈÆËG·™÷©ÎˆíöÑH	m†ü}XÉçK3ì†KÎx
‚³¶ÚÓ¢Æ)”óHÁd`å7j9Ú6%NÕCnå
Ûø³¼/èHõµ©¿œbğŒnK”¤xÃ¦˜ó“¦bI›ó}L['ŞûJhnùêzø™êä5 6Chªùåäó°1¼­æá:yHq¢b~É•†]r÷Í@§ç!¦+Ú¥‘Ô´y/7Ö‚°N?V—L;¿%ZJpÍJ¶^º:±6¿ÅwpÓ±é`]åËµıNOëİc.AEm_g˜Ã¤2:¨ˆ#‚	Œ¬ŠÍo$}CHH‰c¼ôŞÎ»šÄ:q²¿xƒƒ­åM_1Œ"LÚ(–ÀúÊÔÎ¬Î¥eÚ¬—*”­§i‡nå,ì‘mCÂØşÙ>R•:ŞLÃOGôù©Pl0)”±£$¹êÓªzfš:ZÆë?èƒTÓ¯UãÉõï)Îıÿµ6½eŞµ¶ç®ö‡oîÅ0†Œ$f3††PzªÀ/×ù~íE6÷^p?‡ÿr'Y<ß),˜R‰q7¸Ô…ÍNU}æ‰aÑ³»œ]J´ßsIoÖXç-æ
ŠË¦šƒ§ëÉµŠ~åÅDÁ!Ø‚Ÿî´„0l1²JÒ¿(İf-ñŞ"İ«Tb2ÖÇ©õu×'ĞY&&Şörˆ@B´òüëºAĞ8”E•c'^Ïç¹ôÑ‚d|×¬?et¦ıœeÛwÆ—ş2¤ÜiPÀÑ<¦n	Â‚Ãn×'lë“¯£¼‡©ª_Ñ“q‰„üĞÓ¿éX9&HÉ¿bïKúÅ”(…<ÇT;²³°ä#}¡Bì„<Œfıwê©«•4m&›Ï³z}ú^·âÎ$^Ëí$ï¥÷”
Ä³î+r"'NaÏz…òd—aÈá¬bKíº*¹!”~£rØXIºœëxnH'º’ã\G)%‡©‘ÅX´õ…ÔßVlí´êÙB;ß.Ü¡Ó¶98w¯VwSpr­5h¨…eğgRFÓ¶Rthjkm$Ì2©>YıÛqQgŒ:‚@jlhÌĞ\¹ñYó~p	Lp»Ä¢»ÈlË®IwÖueæ³0¯F±âêY¼pl ¹>ªÒùä²¿f£`h{³¿›2Ø—àçFjËÏe/ıµ=d¹¬cÿ¯ˆ"ç€‹F/é²EkÛ®îr Æn½“ñÌJ
t~KÓ6¥#BÀ86Oi¡äØN¾h·ÁmØÈj±(!>P‚È2Š¢'?ép «›‚.ñ#‰¦6D®Ãº›°É,&ìÖ®+/3§¦pß–mPÒÂç¢mù?ŸÕI,ª>ïüO'êJˆ(@ÊZBOW÷'ï8ÿ¢	’…biÁ¥Şµ…¡ñ>c T_Iüëf@óÆ¹2J¦¾]$r[›hô½ŒÖ–.*e &€a ° ÕÙ£T
VŠXk$Ôæú…> o*ÓkÂ‹4j«A|7fB}Ax ~ëÃÍ¬h¡%Šµ;òªY\µ¿Š¹¾–tË~BËEaF(UWõİL´ï[øQFíj¦¢^Kåw{9¾çb)jVó›Q`x§À›Up°¿ @+º•5·ÚŠj4¢¡SR—T`”£S÷n´ò”x)u°Ñ_à„9öF1«1<Ét}v¤^PÙsR×‘Ö‰ ÓİA}oæçnÈM, \ }I²³÷¸Ô/›{¢•ïšP´¨`X–Zğ–…ç]ônÛ;G$6x½íçò3wx2Û¢šøÑ¨œ‡]‰ñï-˜$zÀ`Å‡}²~vç‘(IÆõ)ŒJAÕTÍÉ¨åØ#š‹}j
ğ„™ÌÉÕj ßğ‚IŞ»ƒÅC\—Pê†-vsz)S .æ¦Õu¨X^6t¾Ûşñò+¸ÑÃ¥Y.¶—˜œ[®´ÏºDsI¥\h‡‰
î¶RgÀ Ükg—P«Š{fÏ{ù[î'ŒÖÖ´xµø‘sC KrWÏŞ™_eä°Üo		ÁÂ+ç÷ÆMöÓ§'	:»3ıÊáâ1Yş1F¸~•Ğ®‹ıU%kß––6d¨ êDy¸„
6‘‡wÚæÒ÷È;rí^÷ã]U!ÿèY;"Yf¤ì2¬,Wø|Âua‡>n£4›7Ÿ<:»9*Ìs’ØŒã—I&C\¿)¡ü¸¡äƒmKÍÀÊ¢|7;Ä<L{Šrq Ö·„ÄüiOjk|*®Íâ;½*ƒW¢
q¨]²	À=¥	`–™4…˜|Àû \(£÷ş#Âe'aŞg!óÀex¯ì‰ÏO#c@·1Ï¯2pLjËøª	Âf”\XIÚFdx+Ší‘DNÊ.ï»~İ‘(Õ®
µÔ 4Æ^¾“-M¼~Ã\¼8ZÎ96ÕæÔ!¡Ğ"óÜ„õ~‘»e¶âH!ş2Iµ¤Z!I›RÌÚéÄ=rãŸ‘åÖ&ßh•´@:©ë‡‰ìjNÅíò#X‰LCQ,üĞ`iRÖqòéU~<¾r•/c/6e¬øJ6’µ’§Ò‡ªÈl‰š2-¯Q€«&)S×?ÔNç¦&|9«ÑÂùJâÿuè†·I°óƒ²û,¸ï$R×}4Êü%ûŒĞ¤`ØE¦1²Üÿ…ôúf¬ókLÜ±×[é•ö½[m¼òÌ.ÏF¨ÒDúİ
¤ZWï¬n!aº‹ÏnVâ‹wù6°W­Ikîáù/UE¹]UÅhCÜø{ËÔY•“:S…¨vÚS©FÃírZ‘>joVJºµĞ9O3 @‰D+ğñ•>‡´O7ÍK¯L°¸YSÓü¿ğÿ•†øN$øş]43Şä()œwz{½MãíÍ¥õ˜Ø¶CSàXx·fßCœhÌ-œFjû{	‹Í-¤<Âß?Z‚¢)+Bû^­UxŞÏZÚP(}êÌäH1(VŠbùÊç #5×ÉÕ‰w97ƒ/b`U0]Èú‰•aQë‚fá¿³àI­Ø†o İ9«´4A6ãÊ—“.9GÀ}¥‡?uâ	aµ­€âad€u<xúóÎ1‰”î ¦$K~ĞX“iÃ¦v2¢?9Ì?ı½Zxä°ŠGÛB×¬–Ë•Ìw…‰ë÷¥N§ş3t$%¹¡f›5‘§®ºo5—«âFo´InaÕ[yÍ]æ0…“æ›{cÖùŒä¡ÒÛ7›Î‡fK[=5„&Æm˜Ş­_à*½9ÿ1½³¿Õ<!_°µ‡0‡´ºød~Y½Qûš¥„ïlÏ¶#˜¾şğ÷ÇšÊPÃü—f¦LœÄöÿ™×m×Œåùz)î#¬v¨e:ğŸ„tGÁ.>[d*Òî3M¿¶Qï÷ú8DèïÚø–‡§c[»Á9,ËÆÕšyÑ€×½Fp¨XiÏ‚òZˆ§ïÙ­E¶Ñ³m­–
ÍåæèaSˆvp²«órÚó'T<sÍôÖzÆj¨ˆ#D„Áºú¶ˆŞî™µÉ–ÖU[-9|C*§:4*ÈVs5Ğ»<³2áÖ¹O$…)aİˆ:\İğå/x³ó{©\sHí©üÁ‹fşjÑvnë4Pë5RF4ÿÇÙ$bƒ‡å$‚E±D¢”#CÉŸT›¤"bÈéí"y&éŸìP‘ŸË™psÿ&
AÒS$xÔ´d™;¶-×VoiNv\ñT¹¾¦?oÁC’ºö™´;ÅŞµÑƒä÷q¤/åÙFèfcH5Ö{kÌ9?lØ¶î^íj÷ãµ¢u@áƒğÌôàÈ»PîÒ\“{0N¡µ†r*úcjVÅTTÔ)ÔğuáÜª°¬tÙFÃ^×ÔÒçàºQÖ¥«`1çîÃYMb»›^ÈùV—×Àßúš…ö˜¤½ö!]´Ş@ÿ?ÚŸè³îM.ª¥¡ÑğàÑÜ{ad˜¨ÏeCÜZHŠbéİ”Š ªŸ§B‰.†[h¹Êiç¸1g2i½|=%õ¬69ÄÂA¡Lğ9ÏU¹Ñï]L
¸q
inì„wÜ4W«ö@{Íyàº#úD®¾®/9×‚ãÁ>‰a¥º>ú$uXş*ãÇz6ny*uq­TRULTï6ØvF“ìC¿1;åûDlíì;•Š1óòxS™‘u	®Ãc©•Öíj3éÒ·V{|¬èXŠĞ$Âk¥¸&î–öïÅÜæfBˆ¹›Ë,W‡¥nH¾†M	KÃûH¥­(R‰pÑ“šÆó‚‹ßî|hÆC¹ÆÓÆUáo@¿û™J4dİÎ·lc´¯(Í8»ööæ í„ª¢FÃŞ˜/¯uyV;‡Í*Â„â4ĞY¯Gs¾ğeù ñÍLfJÚqb	‚Çåf&+âqÌ™ªUU¯ıîöÆ=w8b†QÈë‰Üodú(—G¦—CC¢Dÿ!Äåq&.24<”JHÙR³Ë”Ù00€.¥¦z¹÷ ‚†ë…®ôÖ?õšC1G¾¡Râ?Y‹m©é¬Ú§œ©ş]©0íŒÌÖp	˜·XæyÅ³‹cÄ¶L6õ£­F7#ÈUÂR£ÄaÅ:]ÁÈ$ÌhQ­¯÷ØmÍ. ƒ»†hú+˜Æ×ÂÎ ]ÚË¸9\ô¹ š:ÉTÕ¹$Qwû ÓX¯BB±©µòúöşœËÁ=™ ›j¸M-O.veÒ·nÑ›p|(qZ¥h+ƒD^TÃ
å^ZÎoöçlÆZvàc7AÛSÍ„9•Ó©ÌÕai§ğîÔèú¸»µ€oó1öóG%º¥Ü^˜¶43q‹«Pôø	è«]ß
ù¡g
Ù‰…zèÄ~iã&IP•êcŒ ~ŸºúÀç.7p>Êo¶Æ9Å¹2l­¡WÆôÍÆ2<¡¯¯MÒÖ{]ÀoÏ–™Nƒ'+÷ù	²deŸĞÚÛXÊx*û +±©”dÜªòÉ¨®ÏßºD0hgHÃú·gÒŞ;ÏÛwou¦{joO”â*éò@]¶Ì[&»~àk'æÎJÓÃÁ£ßtŒñ›ÜGGëú¦x›Ê° +Ò~£b‹Ú0Æ•u9½0V{ŒHßU>‘†•³OrÉm*øWšŒÔ4]Œê¼û%’¼ÚÎÄ³ó¿Ç7ü.§ÔaD§ç†ç¶óó¤Ûéçà¶¹ÔVÈá¸8kÖÃWTÆŒ.©úcyÂŞºœùöX¦{®ïe“ØÒİ.Åìºë^¨I ú!ş¶Í×€ÿe#Ö“Å—>‡QXQ{ò}Eq/jM4~á4ÔÆ·^\ÅÄ™)?E’Qß\5`î’²Ù?}²ùö ¢ójÄ³–ÙÃçpT1½(ŞøRÛ7a¶m;c¼e,×¬ …ç2¨g1–À88[ãa¡G€/vBvÒ‡`Ş0cN›¦ğ"^o Aj©ÿ^Êir"yPj47~Š®ìÅ¥³GI›¨R	hu^’X©á“›áY0‚÷9kS©©a]bÎäÖ*Óq U^‡[Êç$1?Ÿ2!\ ğ¡À´^*œÍ¤^fFWÀl®rÂŒÉÃ’U]µ%nÅ\Õa<ºÒ_Rr˜«RUH"Á÷óÜ7MqwŸ/ÅÕø•M¹´–Ô%+ŞP™±uM(T¤1²¥ìÀîˆS§y%©<(Û‹ã}³ëjkYõD|._GJOëïõŠ L)’¸¨ïClãÏ¡DØOüü&¶«ÑVh‹N<yŞ3Éå _˜)ô2ßÏÔŠ	|;éâË¾¾VÚ,´½Ñù
>¶4«bÆzOÓôÓ³u5—åŠG°>3wˆ~ª¶¢Yhë·™Jê4=Û-c!	³Z4yR7HZG½%4£NBR…4Zh·À™´û§ŠUa9¬~R­8°Qñ4ñˆàÌ¥ì€Ê
`¯k½HL~ú)˜*2ş/Íg¢N¤ğ°[Ê şŠİå9RAæ’,{ˆ§2Z°	óö2Ü‚¨¬~É«J'ôñg®’‘÷å¾ÀÄÀÀVqËªhÔ-D¸”2R€ÌÑ`±‚¿û‡®ØK¬%ÊC„Ú«N¥µp>I¥š¸g—XaW‡q‡+Î_ÁMèò•tèMğÔ—” ‰ÑÓ°0Ÿüy¥~™å8İÊ™·À*ş:
ı¢ˆ]v2“E)h‡bº‘÷w~KP`¾ß2œ24İò*mWcà­pŸEØIËŠH¥ dá™¹ËÛ$ÅƒĞru²Ú>~ZæçÄÛåÒò7øĞ79 NÂ[nj„À–ãêt°ªîÎ<	„´Ã·Hï÷— Àƒİi•"Â€R¥U.,kÍ“¿ö€ÌØ(İ~ªÃ	…%(y=å¬ræëaI,œßôÀïi´°7ğPG±u ÅG‚À—’È8ù'–İØ1õïØV=É:ŸLy› ®çÆ‡3¥%İšü*ÑÿXÿ.W¿ĞRîÂ	¤ƒãD•âÅìú:ƒÃ.Š÷}~7šÁ‚2›mwÓº­s^íÁ­âEåCeàk;P¯³€†n‚çêÔ~ùëü/¯ÇÅô¥¶Ñø›rŸM•k äeiZÈËñ6Bî¯N÷ß%Ÿı‰A[¾ï
!{ú÷îÒû±æÚÙ"faušš5@Ò. áŞÍÚm×÷Éìõ|¶æES?GMÜ%m/Q*¯$Òœ´Çª}’¸É)è¿$';u·³Ÿî2¸ç\ğÎ¬¾‘Ei­şÅ:®4t`—èQ68TG!ò†
ê†_’™/	u$]{ƒ€ĞÀûr3Öäq*$\şNnãº†Ø…+z3­I*Œ÷Lq§+—¤\¥âNÑ÷"ØãL-Û)ä38=UÃîšë-pI´ å¥‹õLÜMg_´qö6Ù<É¿×XJğ”¿íòúq5¿¶QŒÂŒ¤Ô0yÁeZ¬("¡áÕ¦"›M}ù.ë¼–÷Ê]N ºWËj"TlHlÕÄï!àRTs,sH=$Ï¦®MÎä
Ú'ğŸÀùŞuZ:éµ`O±Êô›õ¶>}Y­k0Ã<ÖâLÆ0~ )ô‡ÉgÆ§µ§	|ó¥~®ùµÆŞÔ¿p3Š¹7»( 
5@Ğ?;_Ğ´U=ÂÀ	Bş ÅKÚq1¹x¦y½)¢¼Îê²@“—…ÚÇáù9]¬”Ä"«I‘ğn»_ü,œùM·ê¥0ò/¡Ê%>T“_ƒ:rµüDVCÉz
ªsêŞµ°Ep|øMp
‚Ïh§ÈŠqf³¯0eoS{/ô'‹ñ•sÄó·«Ò~,SbyiMƒqa¦çkµÍØ
ÚÈ±Œ—^=äÍÖXÕ9˜e×Ø8Ûı9Ì˜¢~Èv@±°‘&HÙó“ kÀ u7iÃè^Rş‘,P(ˆ_,°$†lO4_g‘µSˆ·s¹ó3ìĞi]ñˆ2•İøŒ|5.ˆİ|;X®°×Ñ{ù2Ğz\Cû‚~C¨ñïC}“­‘É(úwRG¯<R<ğ‚ZÿH>ùò´¡Ë«B$}m[¡ƒ¸­…`ãéOñp|a$[€)À ©`UX/ÑÜ(m|ömù»¹j‡Ş)6Nô™xİUëbÜéä¼ïÃz›È¶¿{~a5¤ürò…WFİ¾C$ñÃo]ÛÑƒ"ôÿhFlBb‰"s;ì[‚+•bfoI\ßÅOÔ°£-ñïVd…UŞ?YœqRV€´óÈÙ5«‡ !áHƒã7‚g…±¬jùÚNù«bÁ«¦h€°š²$íÄ#
«Aí¿Œ'b‘|õÁŠqï¼$ERX7”n@,0uÄæàé®çë›¨vÔ§÷ı÷Qmûi§ëIMæ‘ä&	
şc¸³ÅÂFÿ
5©+O€K^PR’Ï¥2ó‚ÃúX‚Tö1’i (I‡ŒÎBû’œ13ààŞİ=¦<Ò9Ò[Qmø—<9¾¾›Y“ö‰G4 ß‹F-â®@–v«'Böá…iÌÏä55êmqª0{Œ„#ş…»boŠGÒÙt wçO?&âê[z¶SoU?¯/jåó˜ztÜpò¶÷ëµ(óéÃÏÈzËc´Ì¶·…lRI4°?TÎØL ˜´hWC@[‰^+ù’'¨Ò-¢6_°\œÈû´åá5Ÿˆ®ÑÂìrÜ^´òb“ü¨é;1	yƒ6Pg,Fy<`¿‘ófyÍ–àAv¸˜“ë¥m“•gv¥8Æƒßm·Dj3÷mÒåãd_mÚ©Ê({é:éŸNnnÕa!µš£)Œ÷Ì¬K¯`¬ø–&¥ièûrT0[äZCh…_ä}œÂ?SÈ:#ç2[d«÷ÛcrGßl³ªt»N’¨K‡ğ3>¤Ãvª#¿6Õªã+'½Tİ;]—F1›³ÛáïìMyÂ£Gz!.ø›Ò ªá£Ww&ØK#pï¾û;w)„áp®·\"Ğbw…ïßhæQXù´ây{à|3¹ÈŠç¯•:|Açf´ºpˆË“+(%Öõ]¬ğŸ)¾Yêæ\Ã‡Éz7‰|ìõ@×Ïş<reµ¥1‰ñcÖ@ºD]Êx°–0³¡iÿâæÌBFd¯mŠ)zU·ëš }} lI
İEşâ’¨üƒùõ»©Ê‘`3£,÷,¼]Ğcx¬™œ|jM¨òJËòk¹Á¹_€f<×ØHCG.ZÊ+4TJ< DoÜe
‡ àÁ†ßR;*-=m€ŠâŒ½®€Ü q×÷XxT w/rŒÓÔ$8:H .Kë) kıÒÒ¸‡{²ruxùİãÏ—…sF‰sÚ³ÿ@†Œ	8M³ºÇì§Ç[˜q+ î4‘1^âdåå•ÈåÜ‘jèY„ˆÀCÁ¸zÈÏÅº¾ÓñÒ“4t‹­Å=ŠÑÙd˜7MTÚ›\^$êdtRıX;Go@™Å°á‚ã‰…Ş7d8ù¹ÆáœKt}ªİ¥¯ú²Ñg”É^h£• U„]œ)jJ…+†¨cú§¾¬qO†2‡¦hpGÅw?‰H¼Ù[n6"`Å¥<¾i¿Şú»°"8¸(à’ÍcÓ
SlZ¾øEQówÜõŸ¤bğı¤CO«Í€—y­ıË$#ãV«"+›‚P’õi¡W{#3«'
¾h]ÿMzñ×'ä(w˜.**‰”Ê«˜ƒeN³z ­>İgYAh£û pÁÒ§_Ú7äl`æQØgoªâ­ä´ ³oÒ1]—Ùä28!¡»Ošİ›*uçaº Ad´ÅMrâ·±šŒJOZÖ€–0³€¯Ÿ;dœ4ÈšLÎÍõœ¿§º^ÕQİ^²¯½pÏÙŞé\enÈÀ¼ycÔG^)­H]YTæ¼H1È§·¼FzQ<m¹Ë¹Z‹áŒ\B×4°İùb»H.Aï¬T¹zÇÉ§­HÄ›½<~I©ÅÏªIç¶rt‰lö›¹Gk¿gŠ°­'ÿíy&ÉÀ“9 øTsƒÈ{zu f^‡w¸`ÏF³V¶ë–° –t¶!$háj5ÇF^mBCN®ŞÊë®sN¯e‹Æ÷u»b]òµ^ 62ÉŸ!V°×7ÂÏß$—º]–ovŒrúÑM›uîÍŒR¾' B¸}¼Ïìì,VA„H¿%]³T½¯Ì ’ªI? ˜+ŒÓv¼–g[òjnàx°gî––CCsı0â¥N]¤ÇxrDÊÑ¶N§­L­){`¿ÅªHg”ÚuÛ.Ã¡Ğ‚	øˆ‘#bÑ27¬
å—°õâöğ>¡³Ò™¯¯ Å P1h•W^íSfêK7(H*ÛïÚcßS"
¹û_nÔ×É.Ï$
EŠL¡/a_xµ"Bl2&ıìè5ìS !²,ĞÈ™ZˆüÈ¼‡®›%€üä¾9ÈM‡^!İXøug\VûG%Ğş ¯Ï3ø?´›¯¦±Ç¤…Ñ…ùaîÕó$LKg› zl8®å„S#§¥$Gˆ¯›l£·ÁE{èÀøşæ•*Œì(ö5ì‡=;İ°bÍÜq1MÛù½U®CÀÊ?=4]C}„«Àı¯ŞlM¯cèg,1ğK”}ú†±@İ!,z šË­6,—Zê‡¼©‡ª“Ò	Ü4J%Œ ßCÇØÍ¶“è*ëãy7#›ÔìÅß4àoª
ö8TB2À	®3•¤•‡=pÊö?ÿhOñ¯U71Ùî³çÆÃ)†h˜ı	t’/IÉãlæ¥lª,0ì.vM9ÙTæã.äWĞ«Uæ¯ŸXjİÎŸÓéöe¶”ÂI…´Ëå&şÆÀ;;¬-üT¾kk°ÈÜ+_Áª„öáåv>m@MÄÏœ+*»C*PïHM¢ÙnŒ‡v6@­ı%Œc~)b³„Ìæ’Îk‘ˆ¬0FÍzÈA^­ã«ƒÆH”ÂC°(³"£¨1 2Cş=€.ÜïˆEWhŞğ¤-aqs+ ½Çù|Ú†jöigjVĞ¶±À#›ÆÕa<N…®<’íûGÈ\LëjÒI6ë¬u{$mk­j	“ğêyûØÇ¯7°oZØê@Ÿ$?5¡±«dá.	œ?=P§Üõ ¿ÙVŞ¤OQSø˜bERøOš0nï(°m]ÿÊq4Å—ë Àù…¼õª¿Œvîç]Mx’Cà5ê@ñhÈcAåœ ò§İw÷}ãÉHÎ¤fQO®×XvJ³-ä\šîÊÉ'2²°Ûgİ”NÛã^`=¥3´ÌuùùPŞ˜f=¬ßÜ†s´ş*§¨Ï¦@2yÉqË?RÏc­7>o;ƒ¦Tºå/Áò°1üo,‰!o¬G'`EÔe½±wªŸ 4r$ˆrv#’nÜ¦Ç•-MæK°ªE¤V'M|C×N–§‚ù†{sŸÚ´-Éyˆå†²f“ªBE .hù†Év‘&%É´fİv€1~@Z:[½»Vi½Íİr;‰¾?šÔÇëİÂ•Î÷#[‡?İ&·QóÁ Eûƒ\æ •ráF-~=ñmÆ—Gok–Gƒã¡qÚÕàòĞbi&Â{¤Üüıñ#a`§y"¹Ğµ„ÆKNs9éJ<¢‚†f»Ø•éús>ÿoÑıPÚ¯UùîéÂÕ4ø‚x2ƒÊ+ı†Nq @ˆ^¶!äN\(3¯úƒr.öWªÖ#ï…O+?æ·î¹‰D5ÍôLj­Õ%Àt÷ßÌÈ¯Šèâ­\´ƒE:µbl r5§³—S·Á¹Šlï]»gÖÛÊæ;ÄG8fÊ`˜÷#×´Úr§¶pëF± /djbh2Åí‚E<M¤ÀPÏ g´ˆ©l”7RÄÀ›Á¯àéı„­~£k,ÛÅã—|!+PZq®ì9§ÓZkhñö¨§—%û½	!ğŠ´¿°±ÅTƒZ.„:l›—vÜØèÔ§£—ĞÚnwço¥z„h©'µ0d²}r:‡e÷¨V]T‰yû>µ÷JËèï‚*ÿBf¶‚–6âî$‡~pÒBª_f©NeÜÄ*É¶ øO¡T»™Á„é5¸ï…™í”£€Rıím®·$>TÆùåœï½ ˜’Åjßù;¸ŠßèW&IJvß®°£ëƒ(‹œ'çiœß¤kjƒÄ| È_á
æ!rºqƒÅïx8g)•c³`Üu.¡mÂSZ^wÆÁ*¾OÂÉo:íØò>Jé;áĞøßQÂ-Y¥:î•Ú•ØOÎ9¶+¨yÏ?¨ò$!?¦¯vF=·¡Ìÿ–üfTz(X© 	dÆôÁÛãÕÛÛÒ%KòœX„Î™å&,jÜ€!s!š^Ç¿ó–ÿ¡x»3KíÛ0mQÀ×ÇA‚ğ><÷02.æ®İÚWe-#©Æ¨–7,U™­åS±\W¡~$W{Õ.Y.‚tÑMÆçëS`Şqgzì0ÆJø6·¬T y,ã¾pn´äuË‰ô3å´oß¿­ï6#C7z*Ñ-ó+j±dÆ)áüSRş­ÿÄÖ\“‹‹†Såğ½,Äzh}¥?Ëê®zs_¶¯)ÏÆ«ï^%ãl–KU¯SPë³Ç4üÕæ!)‡SÎEßp¹cä¿Iƒ0ÕïÆ¤€P•üëÌurïuæ8ßİî[>€’{ßwiÛ`!š8n_Ÿh­.ˆ“d$şàë œ¶VyéïÑ+õ‘IcŞ‰Úğ§?ˆ¢’|ŒK;â~°‚::ò•‰£ı€æÂğáv,ÍOœäˆÛ'ÊH¬Õƒşçå1³ß6evtZ¹½J_;ÉAÛhœOGx2kr´{õ¼ÿ4ë‰k¹ÕŒfEÇ†ÿÁj@}”Œûds¹È¸¤ Úk"ùon×3ÆüTòf˜‚'¡s‹Ø"Ùl/’æ'Ç"¶&‚}Úá¸91“¼dêÆz0@ˆZ÷÷J&-UovÎ_¤Š4ì¥QÍ‘öJƒC}qÑ…â[¿]Š¡Q¨Ä/Fš¤«™Škrä>¥Á\Ñ²$CF+´ºÔƒ¼bÉFp¶ßHõÑ 6ëDãâİrªH%òüÆÊÒi­ûïË—Á¹†FdH8+Eµ‹•¦rVˆÃ¸‹b€‚3.»× âeŒ$i;ÎJBoû\ÃÊáßã9Š<ˆÎÄøª[>{ßd`÷…ÁÄ©"€L”ïzHAwüCmàl®e_8Oû÷ÈÕ|sâ£÷÷…VŞn˜óÀöçQ‚Ì-ÿ•›\G“…?	Ü¬âİÜjºsxS¹°R´W‘*·ª8xvÏ*¦ñxù-±ôà‡úùµ•j¾–Ñ+Já¹vi8–j%(VØzœö“ÄË\NO}²şxt÷ChSè:Ñ·{û(.É„4÷«È´äÆ?ˆ[8rD™*àıŒa}\D)ÔAÖdÙÆ%!ÔnÑñÁÛ9‚ 	z#¢éşo`*Ïõ*GWJ_ğw7R¢›2}¿SdìÜt°ìhcO»—”s€ˆ»ü{_~‡ÆıW’~R)—21ÊÏêß|ûJOá$Â°Ò•[ƒ°‘¦Ş1•H7'Q„5…PeÃ(›æÉ 
÷‹nuìg{(ËÊ€I=IæNèÛJ€&îÿj]¦{=–·{u†Ğ
ü É;+¤EX_Ö~ÛÕ‰@Ôxç‡Ó?ÓA&êè‡i¥<­?éInTû¹¦/Şà¶›ê§Âğ¬ÊDy
µà¸ğ=aKû1€ÕŸ(7´ioóÊ©ê< uÀ-÷©ÉªĞÆ‚©2Á?·i“¬ÏÓ57ãjIÉ	0%ëÖcóLëóùÖÏyÚù9T¶Ê3ôQÆnt)‚³â+  šš>X•ü"V¤&)k~ØµŒŠ#)‰K)˜Æê50b HŞ/Q@ÛŞ$±•[Âõİwq}9ş!/+Ø·–’½Æƒ±“cÓÚE,dÇñô( õ 	›j¼ƒĞ°n¾®Eã×c÷-øÃlHW”UQ#}sÚ3×té:ºë~8glë?V½¿};çñ±ËuÔ ¸Rxs¦8KÀ@ñÀ)0?^‡gÂ•{®=ân×İRGÂœ¥P¸0;?8½“¦&5_Ë¶@.©³à?™à{HÊ†Ğ¼8;.•O¹ß+×:šÓ›ƒG§$ğ_ ÈHÜZo}/˜ù±Ü˜ŸÂ/øN™Œ+ë|µæ™Ñ’tQ%ÜvUªA§—5ÂS
ğ'SXíb-†Š®¼Œ @ÿM ËötùqAj#òaCúVLZ&^ÄE‰‹–ePLËBMrÒìY0Wì‹ôGûÉšÙ³s²Ç	”ùzšeÑ×¹ÿ<Ø[è·_½ú¢æWÙéOÃ¡jWŞ=$íÔ¦.?¢J&¯VÏQ)†BoñH¹)<º*Óá´«¥ŠÎæ/ƒf¹wû­ÓcBÍ:‹çÁÙ”uø½ğmmkê]HZ«¦•Asÿ5RF¥¬HuÛ°é[P5z6ªrú2ëGd)9çÌ­l¬o5öÈi¨ J}	{u†LŞ”ù7·TÄeôœ&±Ÿ‡i)*„.·;»›>–ÖjĞÕŞäÛƒ˜j7îÆg­dvÙŸñ“ÔpöLV$?S4›WC•ò¯ªZQÕÑÈ¡éR©ÍU®áA=_­AòÀÊMâZÊÿqƒlS÷ßb<«6iµ0<aWåÖæWeeWÿ…Ø¹}W:z	‰/ÍA3±k•7n
÷Ôœ`ví¥8€2˜>o"éÓ‰½µlıñ”6Ä‡-„'†²z€zøyb¢kÒó6°IÍÍ?T†³Õû…Vëıšu¢?ÖBœ©ˆÕ®z_ñàéM«üYc{l—
ÙÕ¢nÔT1n5r¯¿± ë’Û‹âš9ø¨1±˜ç÷¬í	İúÅpRcb©à§ Ãèi?æ ÆŞ¹ø}ª³Ó$I˜A¦;1Ít)
ßd+@[è›¡.~ª°.ÕTÊ\é•åi†oò}’}ƒh~L{/,9c'8n[•úmê$›{‰K2zRà{K~˜v#û†ç9ô¼ÖoyÔÃgíz
ÕÈ3÷×œ,$³ãØÃ°¤n-VXH¼²²®ÏpÉ(è6uñ]c™PV{™™PÑ~Q>·±•µ¦“Îq7­úÀÇXU°ùÊµŠ»[q­üGaüVàÿñ‡ã“L-¿¼Ã¬#x=á”'}û,Îèò×ú9‚şU5oan1ÔUë	=cóH%î¶×Oğ, ê°Ù§ûójïWu)À€£o7yÒTmt—`ækN¹¦:§egğ‹Û¡Ğ	Z3²j…¬~î@á=^D²/?+€u±´Ãärï”å2^Oş+·o)/ÄkR‡ïY* 5Œò„VF4•­ÕAfBâ,!Q6hôÕ—YG¥Ññ!kl<#Æ—ûkN(     ¨’ƒ¦Íp0… é·€À›tî\±Ägû    YZ