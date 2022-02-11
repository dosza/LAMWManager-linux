#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="124370347"
MD5="95195f2923e437bfd5cf3b6959bdc860"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26388"
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
	echo Date of packaging: Thu Feb 10 22:33:22 -03 2022
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
ı7zXZ  æÖ´F !   ÏXÌâÿfÒ] ¼}•À1Dd]‡Á›PætİDùÓf0ê>Ä9–®°H¿Ïµ ¥×¬%$…b{ãoÇÕöÛOãDü@ÁB¢BĞ÷L•8´VQ!¼ıÙ™vàƒ—Ğáª5It GV»oÕ$cÛ—v›fÚ|\ı/<J%ô£«t…-Ñw‰çnN;äHÑê7B„İóñuµê}…‹ñlÖ× Vñµ¨Ğôÿî!JŸ*/!eyÀm¤VTÜ¯ç›cqµTF`ù 0¾É¯g›/Ş9Ôv¸¢’å3©8,ÀºK¤3}ûÉé$~×Š•—‚!`ˆ6Úbó¤]Ëí½¸\Çl#vß1 «x¥˜ŸŸl]š*—ÿ4Òş_ò­”râ=ÒK´>· &œ‡¶mÿÖ$Û)S¿Ş¼˜Ô™ ‚‰PItB?A’Ã¡‘}êN‰¡WÛÏWTµ„³o#xø0)Vdğ®e‚Ï÷Rf¤%PÍÂÍVP}˜‰ûÈÅ˜Y6Fß„WÔ
P•ñğ	ÎŒÕ¶ã	”¢ŸE{e¤2©åíÒ¬Ë©!œıOn+ıªX	åXwu¯‰sò÷E!Äİ‘V*WÎÌm^L¢õFÍiªoù¬–q_Ü/m¡–SK€Õ`ÊÜ &@”¡÷Àê„Í³?HqKÀÎ^ûKkÓ=Ñ9¿Iø"^¦Ôl‡yÎm¦&„“d5ó8í<UÇ7‘kå¥#´Û†(/+WëÆÕµ³™“{Ôu‘€î¥nAIĞØLKÕ¾”[IVIõr% QRCê`^q.c³=€»ÙÆ@İ7!rÑå¡#}wJş—ïõì_®Gp*d!v\ˆñˆqhÌ)CÙ=OâxL&%ÒPĞ3N‘¼¼;ïçné2Cã?“<©DÔXëd5ìER¬‰‹--üşg…ìdÖüNïö†JäË½Ñ#<ÔYß¦2Rº^"æ¼™ˆ
xO[€Ï¯Mnï™?:¾<“´‘£ÔbƒMTUk”¸‡éˆ9­Ò64éfXW³`°Càãj"pÆ/_”ËUóü)Û}à„bCŸŒ·yÒß¸›Â°(WZÓÜÃwçT<Œât¾YŸ‡Ÿ¢i*W€é\yšò·™Í*ò£,÷¤!µÇS˜Î”-€5_ZjO2N¼3pôi¸R	FzğÙıªHr¥fii52FªÈĞ?ù¾Æ]IË1€"Y±€	))êáş£<åå:ÇµA7Ç®—|‚U+-@FwÙtbä6ƒÖòªúoVÖÛ,Ëè&ÛÜ8•%À°)3>´üÔêNÏ\Ó÷ë‰“Ãß<zƒ¹f:4PKt¢K¦AF‘ä
´¹…XğU¸V¼é¶R|¬oÚˆğúËî†½iì<e˜÷]¡‹©×µÓñğlÆÒÜyºÔ´O|5`>»?heCÖë—è¸oZÇPf]¿l¡‡Œ£ãsTİ*íHŸÁ¬’úØ‰¢B}^áñŸ8Í¼JøL?³Bøuœ”§—G¿î‚ Æ7äB!@¤Î¿©Ég¯‹FËw9@ç?+­U®4çm-8(”ëf[àÈ“}à—qA´ÛU_
¥ X$<:µœ£-~?eCƒ¸7¿ê0«cï¨g¬Y$Ìù÷S‰8µø¬fpç	2ñºåw–¦sq­]‘¡@½¤iß'Ò€;íURsÑkxñwBœTSL{Ì‘LB +éĞ®p^ô7•¶Il@#9\†œşG³óã^’váœóøÅÎë¨?ß“Ş¥,I]ZÌaN`Å×Kyo‚„3ÃËU|£kxYpÀ4)|­>õÍ¹i.ø0“•§ÖğÈ1¢¡ãš²-kê!*ûñİ†å7?íÍ—#¸)_‚ ˜#šxv14Ä• 
ÿ±#6„ö0#’N=Ş°ÄºH‘z€ÉË¿ĞûØ½æ‘a+şF¥…ä8ø±'ÀB†	*¡‘ şıÉéXó¿#/;hRL!R™0ûHü¸ÇV"Mğì5b@!¤üÇœ0;vâ‹˜€éŠ©NkeÑÏjİ¯{Æë–S©”Ê7¬/ ŞfuwJ*˜÷F!³]î3K5_Ö0Å•ÂÃØdr~ÕSª,ÆÂR>Ã±)UC	˜Y±à`#Ë
nŸ ±} ğflqÇ
'7Èø"U°ÄÛ$ÕíP i11è•Ù€×®÷Ğû$î)Ã]n]uŞjõ$Oêäíj¸¨Èˆb5?‰¿´Thê›jıAöí*o"³)ª…ñd•”ÆS¬-DXnAú–vÀ!&-i0¬cí	Š:Ìø¬ô¡–'KÕ–bcˆŞÎÔTUğïfùw8Šlé@Éº¶
2Ê‰ŠcB°¬iøœîh‘BUã­î:Ÿg8È6¹ö¤[Ìª­Cúã‘:2€‡g’MƒßB©7kMôMô©R9úšã?œ]mÓ4‘?,•‰Ç¬|î~P\ã2ïiz•oN6JRzÊë A]}M®Š¨ñ-heÉ#‚î&LİÁ9ÕÅù¾£„ğú¥WfîõÄVûPu²)Ïğ˜dİÊÇ:òI=é·\ÃµZ)’\#—©èÙ4ï…†aïâ§ïaçùK<o¤‹I¼“¿¸}ä·iZ4Fz;aÄN
Ÿ–’±EM5¿¹Ë
Á¬åO^/L°WL½¼ÃŸ:(,é±îEbËÍ›­nO;B¡ç©`¿][ÃØ‘v.šb³Ğ¢O*XN>öÕ9ïkßuƒ@•ü¼I$q=!âıÏÉ	Û6û@¦Iµª¿¶¬2#Ç=ÂHb¼ÎJôç ¶•à,³¥çùK!ƒjàv·8âØ2 ¼óèÂTïÚ¡ûñSe«¿ĞwØ.„q8µ?‰É)ÃhB#p’øÉ¥7ÓñÍ w2+ÊîguÚ¹œÿËY˜i%¼¼òzoDG@#æ7`mX¹5jüØ4‰@ÁÚL\,Œ'V–$:óõÀ{¥
İÄØKåk8ÖÜgÏì?®Û~Ô{QˆäîÄ_Çi`L–q^c!Û=/á–Œ2Wåf,¾¤ú4e`\¿h|áN×YôâÏ>sÏ[»¢Õşâ¹TKp¨±A4Avƒ\j,ªü6pó1ƒ´¼êOğ|r[baÚ=QÁ”ïB°ø/?q2Zœ†Ìv»`ğáDü˜œë 5÷&Ïf>¢”Ô¯9`”iÛ ‘bP®»Œ¤m]Y#áüœ°4Y1ôŞ÷WÇöKl5½©-ö)›n gEÍk/Fàç`´?GøÁJ»zmøU¥ÔÓŠ0;ÿ1¦ªá¡JÄ4Ít¹O©ÅX«Ü¿~OcTÖ '…†;ìcÁ<øŞj°üØ¿Ó1Yšdä%rØÈy'[fC7|Ág(j!¨o·KùÖÍ·M¿2»¨gù$3{xnĞFkQ†ºÔÚíáà¾<D|v­_úŞ˜mô2"7™Û‘Å“”åáaîìwW^»»gœ­Œ±ÿ®®-·s  u# Ñ)V8Fÿ·©MoVZ¯¨I.e^¹½ì«[Ùy?»m½ZÏ-ÌƒB/XçU.ô£hÅYÊı_6§>>w nÁ¬î%,ÆI‡PØ.=EºèÓ„–…ƒ¬ädTK9×ÙŞDï!qğt([C%h#tÂfX~á1íHkï{Wi¤=p›ğ8eH1¦O±0]‰b"àeëÙ“Ëƒß±á
½Ş©ôa¤ó†J>ê^š·8g<4ÃÍ¸“Ÿ[Ï•1ŞpWµ¨Íl¶'Å=Üß,'
¥Ä3&Î	·›ñÀá¨i*Çò­šÄìó¾Û‡ƒY;Æ“~±¯{e¸]Ò°#€!»i­À¥Kß”+¢éüÇ±»{çPŸßähjøÈÒMœ?Dah  ş°Ó[úÚî×¯|í£<ãIe\/—bª…’mË?,ºa&lŠJ ‡Ù“¯ë†	h¤¶ ü7K„{t&|Œİ|WzàÛş 8ñEõ
D±T¶ß1{%ÎQÀ»-Â¡qIvå!p}æË.£+vïóÕ»é™wá)Š§bXY¯¶ƒMĞºyÓl…şVã
 CQh%20…@äºWPv ˜é/ìawÁh©‰2xûó¬9”‹,óŸ¶ñıP˜5«Z«z£¸vĞ¸>µƒƒ7•ĞôLèÍ "Ã-yğI›B5²ó|"<°¡ŞØĞ7Q ÷'7Õ¥9&;èy¦Æè;‡ô=ÏWV*¾©Ë­ËŒ&*:€ı…ƒ:?xqoğ¹0Šˆ„L‹F}FÌñÎƒ¿LPKİç¸Q}Ú£2±H€±‹…yIÏ	y|ùâ¸BÃ´d3I9 G'º1ÅZF{”¸­õdpTŠ5Ã{å‰å³QAú2Õ÷¥è	xŞúãŠëp·A×ÛSy7+Ù&=t,Q ’hd2ˆ¯í÷åàæ¬n€×¤!CuW|ÀÂ(6¢’„ q9×ôT!zNˆh„ä.šPä¢pş²bZnmŠµEø}yLæ[S¶Hî.çà;øbòG(ş!øäœS¨~§!'ÓåEù]ª~«òĞKı¶¨ı3©şzß ÈÍ ´Â¾ùj¼|½CQ-ë45N÷ÁÇß¦N¬Évz[è¨ĞWH³èœTÑµG^üœş¥¡fğo^¼_PÄŸrBíU r^Ìz”~İÉûûÂ2:!Øn¯şùV1€´WÔÁf0\C¿ Á;ÖY=Xvr?ÇßùßpĞõÅƒV©í’Ú.˜ísãF.Â&üˆiÉ1ÛDˆ}ŸFGxnKÙhr'¶ Ù©‚Wƒ1Ÿ¢WV˜ùŒº'‚„^ì=Îg²m^3#¥².z'?ò…µO¯íyûã4»}^1ÃR’œƒƒ¥ĞÑÆÏéd­*˜*NÛV	´aä´M'şŸOi5'ŠVŞfÎmº¯Ğ×íJÖd~løíÓµ‡\ğ‘é±WŠéõí ş‹¯*Kÿ—ª~h2$K<‹…¡k†d«õ¼(÷pÂoúx¿ş¼ZoL(»,Ü”…İıÖ
E‰öÄmÇğPœ¼aô s<©7·Ï‘ô˜ábÍ<Æ•á{×”UR/_ÛÃö‡ŞR1X”=w”4·döv¦‹Ø§à×jZG²B¢Ç¸jz/û S:Œ
<ÂcëjC÷ê	¤ÔèFşµ
éGø‚]õg³£úÀÈåp*íÂU÷`Y?ºµ§+á»d-8ÇF±jÉj¥ã1ŞzÅçºX¦®ˆŒò$;T£.ºzÔ©q9såÉıã^€«ÿ"Ì C»¹[#DéÜHÄøD–ğ¶()'æD/£•;—Ú¢’‡0Ğï{R¬pë/H“¶ojÉk­ğƒ"«8Êê¿¶¸ÚKàóño#A±¤cÌÌ\ªÂ 8a(‘Õ±0*ÂF¬~Æ±;ÿ¢qMgAræ,¢všA‚±ã!Ñõ'g»:¬»4£ÚìVÔh¶‰.£Ñ+l¡ˆn÷ç*ˆé™i:Í¦+iÑi7”#£xÜİ%h¦K=Ñå)»¢¶±¼Úû”cÆĞw	&Zò:TfjÿÜ¦æKLúï¼ºpFS[İ£ÚŸ·ŒL.†Ï$Dúáe‚;#S+x°İkgÈÏ”LˆoQ†MIKtíJß[õGÔš-oĞMÅşvÓÅôşÒÕ!¼€îvŸ3ê@îƒ°‚\r;/»D’Ÿè}©:-ébÉ+9jaN7Ãµp‚G4‘4iöBF&P/ùÃj<³õ’upèÜ"±¹\zuj/¹åCDöâÈ1ï¡£š/\Ç¸ñ‡k<IQGŒWıúBÁüe`{ìÎ[3ïIÁ.Mì"²°;<§³A§<‰n¢z‹q:ã“÷¹—î¯_&2]¦²Ë Ÿ²çrôÔÁnãìGm5¤}Ï×å	•èxşÊjñ53 1æn¹ê5ÄèdàÆ£°ZÔ5Øm|Èº¶¸ç”¢Ñqô]p™{¦jÛ$Şv`êß”† [ø¯b¥òt8;AO_ˆÕ’ ÈÁ-Ötö¸Dì«u°ªxy	6}–ÕHˆç$-WP€Ãf¥²D¿Ù i5ŸhÈ´·÷§H ñSKîeƒŞl™ó”ÿKß‰ú¯l«,áV¯ß¢öwW1Õ>_IUD6Ï@É\ÀCÓ¸ÀúS€ßHÇR„X¼IG<RîÖw-Ğ&f­‚1¨ƒÜuÈZ	ÿó±Ns±÷I –õLŒ»•9~Uñ°J!q‚k0”±Ÿ†zSuÊ”ÿÜ1ÛE7µRTUöƒØ;ÀXê{öK,IÎê“¬˜êqc2Wiø ¹zÑ¦¹ ß“¼ªsØH-QÀª³O¨áOJìÆËqšômM@nÈ€»ù7}åpw¸Š6Ï7½#ÂA<·=¿®/âSóğ…6:eœí¦¾ÒBz¿Â©nsfäà¼·):ÒåDWô×<§ÛÌ¼¤·BY|ê„ q£İ¸™Õ?»ÈáT°i¬F˜PÜæ”d¶&5xrø¬X¥Å¦Üö•%Ô¿ÓÓ–h+¶<ÃT/w^Sa¶ÔÒªu4ŠV˜;</>·Bí‰¦0#w"‡¨öp”m4ª¸’mÇv¡*+x_¢yãç-äŠAì’^sã*owï+¥/»*N1yïæg+×*€/D†ë+‘¡Ú8§˜OÛÊ}ÏG·É<)~Ò®³+ øÇ EjF›(6¹Ä(©GxmØM:3ÊÖ-&Ã1æF˜İŸù´:£ï#cAƒ)¬íÖ®Èj™täîÖS­©®X¤Q6älG™n§à1âRlÜúOFgb¡EfmJIİ`å,Š§Å»4›‡g,
­KZvèü†W‰Ó×ÄE‹Õâj¹9|ärÔ AÚC‡RüÿÄ†Îc¾æ®&ö,ÀôîOĞò}a[¸ŞÎ°:æ<Z²×‚èÿ95H(”Z=TXÖÜ¼îJ ¿°U€m“÷ä¯Ôï7"•GÏÈ?~Hã3{¢†òÙÚÉA Ç(³?2d \z8×û•³—A™âğâ[)†LTm“¤¬>L~¾÷•’’DŞb+{O£×1Gf7§¨$é$zfŒV:<ä‘ğ‚`õù(,ŠÓºŸ2"3ğ»““lûräÉîåt:¿À‹hÅ¬	r“fmÀu5f‡é}’ş_ş›&ŠKÕ_Ç¯,ÍûKäJ›ş7(VÕBªãu±`Eë>ËëìôoæğœâY÷±!]øÈçNÜhûf»œÕë¹ï€­¨ô@KW€aèŸ“2š;Aš`9BĞ~ÖS‹2Vè®×70{F\Ê8Ô”õèÕNs”ó–ƒv%Å&5V=\""–øÇbÒ‚wÈáFj´)€âlİ[˜·L?/r³j7–Šİ›¥m½1•¦›uúxJyûèùˆmäu–ÚöŠsã¶÷n¸['…ç ‹î‚¶{!yz‡2p™ÆÕ q>`qH¨=3•Å•Á66T/wşÃ&—«4ºÿáH^çÇŞÓJù±ÑE€wĞD¢”¾Y½B§¼ıY6WY(ı@ÏEàe:)©_¶²eÛ[7Ğ¬’¼¢H¢¡¹ZºàğªZÓ˜—;P´[ìås¼¹¡ôüHFÏÔŠìGÔSø]VüÊbø,<JüÒòFÙØçTLBW€GEz,©¡©DKjçÅ¹’­ZŠğ§p¨˜Tm:­Èzkà$õtÂŠ®Zim£±‹kkuÎ@sŠdc˜3Kcş¨ò‰x¬8T…"8hB8Y”øj]²1˜Ä5Ò©`O:>õNà
LÔì÷V‰+H¤ÕUÙÌ­¡‰ÆFÓÂ¦ıJ„f6ŒYL­^?¦L¼ŸN7BíuL¸<=(;¨S¾8@lsÄİP(ñ9Oœ.=/„í¦"Ém $oöo˜èAûbU_Ğ^›(vË
ì?W,ƒ«¸ãn%„˜şÌ|™BçOa³-b=nŸàâ-‘Ä_6òuşÙ†Ñ39¿¯Ø ­Aœeÿ#
ßÍE˜{
“+#¤,P—·äËÃ.é—oCŒ½ÜñC6u4Í³Äñj¢7 øÑŠó,Æ[ÈEŠgÈZ9yjü‰á©È,i	SÍ†»É“ŠU”¾ëI˜N„Oà¼»ë-«©¾Zkh•dÛÇÏH[§Àm´Ñ$§‘­@%ä²6ZŸ,ï<ó•åµ|w\d3/€Úå1‰¤ÈES²#´Íª/‘­“„#•¼­Ú¦[áJ¥U{T\ºÉÈØûáÙ‡1›[¬úVAÏ‘¿M‰~Õ¢¡¦“ü ½_Ô
ÆDOö`»^;ñ^¹ 	{-;Aqo9Ì´ 	ôÊé{@¬ğ€:õ±¦<Û§¥J+	™<‰m™C÷Mí± Bs¯r}E§½Ô”ª+Mì·«Ei»©Èéñ‡Ø"×ÂgLuIjÌKÿÿëÓÔ8e
w˜b-î%’7Cf?â¶ub±C}iñ~/æ¯…Š.‚ú0ÀÚƒ}ßo£&Íº—‚<á—VéöHÑcËg"\Dl¬Îğ˜C3H`:z®`Ğ„Ö—røÎÖ<=ğ´·š*¶±Øµù4¡¼wañl€L‚%Ò×Ôì2wk²4],f@z9£¶ø³èz¦Içì,/”æ­4WqÃã™PpòØm‘0p5Éc4E¾_}@E81ÅªyaõÔÄü³£p.¼¶™¿6:Üì¨Å9Š%¶W ş–bÚ¨µmúâR¶D£ä Êií´{şâêsØ¯qüÁ_Ââ_}Êæ,*ÙÍ!?p%‹(ÛÊàÈ;í‡xX"¤€MŸ+¿£?ÒõÒrøbN.)Œ¡Ë1á~Mâ Æ=»'ØÎ	1fé1>š³I{>Ì¾~eë¦Ò-¯lÅŸ4¤$!?§%zmÑ“¸øÔn¥æzšhßUˆ%BCíÀÊ‡üÏËFNˆHßbK/QÙğ£ùbÙwÑÅ ñÄ¿Ó‘Ãâ’Ïm*°*G ïy¿Î}¨â´{åÂØ	4ò·u—3ÜÌTXÅ—*Ä.÷{Åš¤ÚŞBÖµÄ}·„şE[6™HPü’Òºˆ/CZ1ää7ø§§a[BĞœ0ÑÑÎAW(Í©Û6‡/€¹µ

ô¤‘Œ½÷ùéÚxÈGzC
9Î¯“tÁ©8ˆÊ§[Dİ‰#ê¿ĞGFxºÓ;Ÿwæ·0~Ñ”İ¨^}@EßÊ˜&–¯>#ÒRÒ0ôºš|Bî¾äÖdOZf¢ĞQs×³ öÀµ
e!J3×cëòÇ!ú1B-Ùa­˜.³mà"~åí·éTšÂÉÀK
çÍ_b[%ècğygkŠ÷fP«ùòÖ]ø’Cî|
\eß‚¢ÕÕTË#ÿ€]r‚™Rˆàóàc]×Â.D.şÆç7-ºnP¶II:,ÿbU‘c‰2±o}¶!4ÍÏâo¹¢òÖÄmÏO×vmxÒBGf&¥‡ÃJ
Ÿ„ó¯oÓ¾‡)GÈ”<”,È]kÊj°–³‘&†@ùŠœÏ%5`‰ öÆ&v²^èQ\¹)KIsÚÊAÓø¢{7q7•°Û…çJig-GŸ¤³ß&@ñğ÷®©=aÖ§âS‚êQ)m3k\-ûÚ‚-½è4—.í*Æúm}²GÒ.ÄÚ@)hB­¯M
%¿DKÃÙ…À™e¢ÎÙ@”`íœÈ€ûcÏÓ|R“j	ë$ˆ?[ƒlyf…¬x.?ô8ójŸÂ`ˆdû‹(¤Ã‘TÊK,Ìøà0ô™ëA9m¶t×Æ›•ºÛ< ‘Šlë’Q{FĞì>)æª#Ä9âe RUE\J9æeóo$£ÄôÎô'åÀa"ï‡Ÿ¯÷Ta»‡˜Ë†Úp­ şpsiªÃB¢ªk´˜Ã÷ã0¾^í‰?n	é)lŸÊÖ!œa¡ÿ·W/^_,=™±ß >ÚØ{¸´nß;„‡¯pc¸••U9=(é–^[×Ã®c÷7¹¸]=ĞTÑÚ‹¥:£%¼ZQ,†'e¾p0¾ÙKª“‡„Pè@”Eë•˜I;€€I™ü…çr$1{¤Ö"µ@¬ê:*Ó)PÊ
õ#9°¾fQÿr‚‚öKƒ ÌÙµƒôö¼Öxy²UyYÿ¤Øu¢Ù|ŒOvãr Vk’İªßòÅ·lKO26ÜÍºv ­M‚Ñxÿ‚˜<Â„‚/]q%uğ³ õØ1‰–xèFT	‡ÏåËVøäêşªâ	ØSGQØšœ6rĞ)NÄîuV[ùhˆ#áï­oZL½ğÂfæNyñ»ê%:	RšËRaëÃò½)á
yÓ—xG6‘Î›1ŠJ™¥•¤€H†ïšoåfÚ‹ì‘NÆõÚfZQ¯í+ªnÁVä#Ä€¤háÒ'.·C±]^Èn”óÚãU¾6'óï›Nïò¦Äo}eî•2¬×÷íÁq)c¸Í˜ç®¨^;öv—)ƒöÆsH+¡YmdgK™¶‹™âäÓ'‚CæŸ„\¦nV¡¡»oéÔ“¦ı^9j¬úå#–®Ö²U‡[ÏW„ØEJfÀ3.A@[Q¾t<5É#ÈüĞò„‰VÁtØÄFv9Ëİñ¸ŠÄÄaLÆvAF/Í	“²êĞ{z›¼Hó’·fBüq)+Y%iè–x»ñœáò‹AÛùß
€ÿôI)qÁÈ”cUTôp”ì*äåìœhàš	6S<‰«d7Ì3œÎ)Íí.e$,ÄÔ¤
Ş¾Ñš‹+¼»–ŸÍNƒZÆ³Øc¶¾Â¾ÔĞjµ)Àr ø0ÿPMJ©øİH6Â-’”Ùº:ëç•ÚzÚ™Ùca¾áp«0~øÌ¡vû´G‘Z	Üî{}³“àAôP£²r«AÈÈ¯Z±6ãv'İ4Åpûrá\	îKE2åá·*Ã¤ÊÑú¨(DûQwiø¬ˆ‘	F‰›r¶Ğî÷@ËIb~×t„'åßñmŠe‹€r œQ±9Üe­­áaãé5«4p;Ao fÑl¤f^ ­×ÏìILÇÌAşc©º²íQÖ2¹´¶“­øı@=t„«]%”÷İ¶µ=¤d¨_›/ª¬İuqrX#õø%‰v“K‚;Ù]¯3¯Æ$6•FZ…F²D¤÷:VûyÅ×šõ^	@nİùº“7fŸ¯iÊã³ZY`'ÙQ¢¿a¼oGÄ…”ZZHÂTï@–×Mî•º(i¿B´ä‹dq.ÉLrŞ†¦D^I¾AL”k]5úaD¬¼©?²A‚b9R(	Wºz\§ÊGÌ`HR~˜$ık´¯ò‹v@GŒÅ§úBŠ}²Âwe¢ÚŞ®hKªC¶¾€ğ8â!zËŸÃT°øT1İò„¸q= SUê’?ÚC]¨.riÎ@w&¹|2şCäuÈ®Ë€:$å`S|ùoI2­™Iú~ËØ9Ôû×d}iûgrvÏÜsƒp|ô³€3Ii'ğNz ¤†¿»ºOÖ¾ºD(Lœî:¾ÿ¨¹j>ºÀ+
8ú²]/ªFBGí~ıî¸ÿßvÍ ÿH‚’/@_Å¤ª:r\d»]èãşß3†8¹ˆ1æi©—VJùƒÿd7Ñš)ZäxÖ?¸Ş“¶³S¶u]²ÁÍ“Ğlêd¿T8|Ì‡”~P1û¯`f€ÎVæA¾‘z®ì*ÑÒ®&ëaøIy3t‘LÉpoE
cM^ –Ò_|ç¥k‡xL<1ñ-onûÍ¼5BşÎÌ³Í% .ïu–¨L‡‚{8ó‘9"AL¦â:W¤‰¯W×S¦}·“ñRªÊbó–}ì-0Ô¿·5ÛJ÷çë"°¨~-Ê@8£-ã'¿m3}™U'„2¨†¿y[“Î‹‡l¦Jû ÇÅ%Nt"²ñ¯†äø@Ï7™7gŒpı›rvé\Š’w²HÅa‰‡Ê|w‡ğXíºxæ­ÉJ »É û0™âQûÈéü åµ“‚¨²OO†éáÆøÃ'äêüÑ“îïYeî¥.OÃ/s$ø kny±„<ş(
øï¢®UŸªÕ+ü¶ïY]$şÎÎ¨¶i²¿RrÜº¼ª´G"Olfù5şu
hh‡ºÅ]/3gÀ³ãâ˜YQ—Ï9Ú&†™áVŒ’†²:p|Ãô3ò»ŒğyK=ñĞY^O¢ÂëËƒ‹¾ob·¯Cj4é
Š½o·J59
Qş\[Úë…P9"LÃ= ]q¦cZ²¥dGÛÕˆ5j«ôKKeŞ++™´ıàáÌÅ6 sb+í§´Á´ı‹xO`— @÷IÚü%bÎ î*ıåçvN”^á@o>JkâŠEŒ»œÃâKM€w=©–‘¶ùkf2	e(îr´¢¾ÅuÉyE‰âç
ˆı˜ìAÕ¦Ç!‹?©éOÂ!BÇrÂI#]¨`«Ïpá/»›ÕÉŠ,öôø¯AÏKG.ãÉvÇÌİ
UW——åIÄ“oBòE‡ö£±Q4¥J›ó¤ÎêòçÅÄáIèyV# V! rÛtæºS›‰éşk!Ò¥,~Øw>ôÒÄî‰mÛ'­÷Óm'î4„¸îÃ\²]…ff8 æÃ˜#6ŒÄô´1m ò¦z3Ş’Äo$âOI»B‚'rÒ’êû§£]ıì€Ëš­!Dƒ›¦ei.„ÿW¯H{+nÁ‡6?ÒÚÃ0ç`f
¡æ.*KeZ(¸¾}İ¬`÷:®^
$J&rZı­oTïéªĞóÜgµ~‡_FÎK":Ll ÿ@&œLÄ1R|“¶ o)ì.™3V@RFÁìX‹)†,ÈO×zş"mÿ"Ç—^’½rªù¶Å0ª°oÚ2q$-€éM•	²Kíg°û×–¬‹u…Í NÁrÀ›.îecÏéÜ+?k
ê‡‡è8ß“]mgWÌúÑ{A¹#%B“œï)çWşb)÷"‰QPfSÃœd¹ë@÷c@USàÌu‹W’×,¬#‹€ÏÉÛû;Û®›ˆıá§	ÿìFGìCWªxÄ|ê84÷«-Öv–ûîÊêbæU/(-½$·¶qÖÀÉñ‰ÈWÁÂo@óÒG(ßĞ6’–:3Ír|×\¤JÆ*³Ù)ÈÀ¶!âé‹©'÷Ô7šêQ,2‡×­ªêb­ÂÏĞò fÌ<­!g65ıåvôë‡Äø«õº9Ç_AxÃ1AËÖQØÙõ {x ßÍİÆQéà¸ÜR‚’Á‹€s%åÀ·LíT½<ähŠŞ>;ß¬K$5W,n Y]oÓ:t‹˜ò—-Çö˜,•‹²¤ºllt7¤/I—™gá'–i+‹_é7u‰iSËpqúS×®±sÅnÅ²^ÜŒ{¢÷åkTãŠ³h°gvP†!SØ†dìŠpÕ¤kÊê-Ÿië¤N_„ŠU*—¡*A¥ÌËô In<Ã€ŸÿéOÔU¡#ÌÂFÅ*Øf"¢¦ÈQ!âÓ©e±ğ:ğûã5b\g1{â[îÆ¢¹^rØÆú´Fµ¯›9¤§ÿ_À)A1Bå);ó³ ˆ[É“¿‡û¼ îE@ô¢ı#ÓëKpº^\%‡ş[ğBIj™Ú¬ÑÚÀ’	ôÃ„ÀS]e´nD:ª)Æ+0mŠ}±ÏÈ	ƒrQÜƒ[ãj­cQPßMüLÄìPq]9e0ZC¾=:eÃ6ÖØ–¸ÈYf»£—'ià\W‡»T…¦Îvî~m‰£?+Âà¶RÛ½-ŒW1!8%ãÍS¢hXsV—B2RÙ”hµÈŒå¨é›¼.²KæGªÔÖ:7òøñD•"!¬nS0ÜHÂ!‘±dAªW¸²6v3.…¶í–\Şg\C šÏnT¬“]÷¦Ç3­lâæ“ÀAû7±—ÊcÔY»®ògâ@r ¾,Ş¬ïÓ½ÚB”Ÿ q…eÄ7¼õ‘^«3Yc[å7+‚ 	0¤–Ÿì¶¶¬öòƒßMòÖ¡m¶g¢½t®›?¸ºİ1ÉNèïääQù)Á²¿hˆ{	õÈßw½Sæh`d>¢,¬ÎSŸË	 İ†K gj`¬p:µ»/%<à”‡u¯¾Ù˜¤­7Õ¨7=U)åºv(ˆ‡q-«LÙ/ë>±¬ªQ€xßs?t*şÈ£ó^Ñ¶>ó§»(µ²5Uñ¢½?î$»@÷ˆ
WF×›ÕqTnB*Mr½NÑtÍÅ;N˜& _,çyn¿*8i¹W	ÿ7S’¬HššØ˜•èÇÃ(°“S»iI¢eªœ µ6¢¤…²ˆâ] Cÿ{Á1¦„AÛ8êXT±Ìq’'Í®,á!Ia*³>¯Œ—c5%xN­KñÙ<eÑYQÏ/OŸ–I‡â†·mÃ¸ÉN«?Å"7“‹»3’ğ³RE¾Œâh8Öu¯“N‹Ûÿ¨—äÈiJŞ²vİäpüŸÉ«HŒ„Ğ' 6„@$ÉîÃ[& .ªp»­Õ. 3õ”³:¬ÛzoE¶Ñ_£ìc4\M²íú¬¼¸¾Ï”£À)‡u6¹4Ô„]Ê¿D¹ã©®yËë-8‘m$V…CªT3Õ†Ç²¯+è¥¶d÷S6÷%+²±0­Û‹kaëûÛqNäì\£Ÿu8¸•\V´Ğ8cO¬[<?’‹xÏùö&Ô7ñäÕµşÂÚE]äu»2ó¥ˆĞAVÀŸGn5ü›çĞ{R.›æº©š<»;‹Í²FÆºÿş©VŞ¥%‰×P×Ãr\µ/ñr‹¥jLß_ÁµAèË…‹'Ä±q/wæõ6sœ"ìç³Áêj;ü°”74Ü»µ{%ù•„U"¼±U]pó±¢oæ^rŸÒM¾cˆF†ú¹Àø=Fñ8—(Ÿ&1 8¸uû'ßÔÎ[›šİQ‡6s÷KĞÎÌ°»fğÂ«æ[(Í£mø5Eé5×’Nq@4×R‚J r~›3)´ßğ¹• lÌLÎÊ'—HŠZ›_n0'*L¼¿Œí–’V®mKGŠŒ©{˜¬:V€ÂÄo¥QØ"N‰wí<^Kø¬ÁkËDŞyŠ4û&ÔtâVØßj¬¸“T}%²®.ã3~aíûÎ|>—§ù†Wfå€w!ËµjYC}#Y$ø©)]ÏÕªÖÆ·½{ÑFX¥Ø‹ç„‡ÍXû£âNˆ™ÉÕ(¶òFdô³ªí‹±%†ßcÉİbã¿fÆ1%Ÿ›o@ªŞ?8‡İOjK3{% J,†óIkş9¨Ù]G¸==­yÈÖkÇÿSûÊ‡ŠÒ®üÊ–lÏ”BKáu½hùÖt ’…åK&2aÇ½›øæ±>›ÿOÑ#qvÃ‡L©JR‚ÕÎKM_^0¿X{wÎê/ÈUr
"úğŒx—AëX´ÿ?¢~òc\ï «¹dù§Û_Ò’éıı/bÇ˜;8Ğ½x!ÔHè.¤’É‚’
m ›{¬­*4¢×Å†CwÈĞ¿¤c“¯ª0Â^ÒÓ«‹éÅ=† ‰Qªùî4àïL‰5—â•wsÆ"Qdq¸cåªİ]ÖãŞğ<c|½E8×Ÿ¨Ğ^9™&˜åsv¦¤»Ö³GªÊÀ•
Ğ'µ-—µşÀÉ
á»¡ùÑÇğ[ŠúäÈ"‹cVŒX.“r ìÊ„dâ³´+;<dóÆFæøíîÅ¼wïSC:¡‡Qv»°¯gÒÑcJ8m†›¦ZefŒ~5H•MíĞİòµçs•æçÚAw·ÊŠëù†Ú„cÿè‡øU{f±Ú×ã¢™;Öù	¯ãi‘ïË j»w±rùü1ÁÎÈŒ?ôJëâ‚ûM†µŒŠrân’ó³Süû®Ú4±@Ğ©µÉVù¢È;DtãÂ$ñï|éï¼t]h ²é}náİaáş:;œ>jÅõ…<`‘Ó¦rZ5?×	¨üüÄÿ£ÿöv—Vş”_ö„A­„şˆõ¼ ÿ h~Úô«0ò}~¯]St˜õ|FMI÷µsU½,s"·{/î]KtuZ®â³QGûH\AŠwõ¨‹MR!_õXØCw}ˆ«	+}çòÆ8Ô¨í(Œs®š¸†?‹aú*dÆÑIö£-$ã„2H¡Ğ[½µ×ÏI\BE«ˆ}‹¯\Ü=*c¸ıÒ¼?•ÛÀ»%¤¢I$UNÌCjZ_¼=UJèå„ÄšIÔC&32†Ü+Ú;¹O#¢DÍÚfàh1µÛ¿Êmw@·vÜÿiI.‰²7ÛÌŸ,ÈzE©ïóg{E¬:¢íFİ´5=uÃfü.–‡´Ë¦ú?)ÿKHòÒú®¦«Èã¿·é½©e~Wr­±ûWcmàÎæöo¨Ûãó)ğ(â|°ÆLp7I‰¦ŒS®]òÆà|´…ù.½©KñHIŸ@¬ñFØVà<ÙP[·„âF²ÏC!­­ gÛøŞÓgäVÛA@€ı"w0ïË“%)"NyR&ŠhK¼?¼Êî-ñ®Ÿ·‡@ÔŠÎ´peÕğ|{RÓ^‰cÎcdşíIŒúOÅNÄÍÜ×r+Y«$B¾œ¸K²gˆ5Û‘·¬M¥Bf%tÑuÏ	3©ÇT”Ï6 †’ãŒ‰œ†"Ğû51ÍO5Uˆo ÷5›©}T
‹Ó‡Ÿ{µHĞR”N0•"KzyMô '|ÒS)¦&€Ä?ìĞ×	‡r/TôRÆÀÁ´Y€iG0[ÛMíœ“r‚¥-6õ¬“‚×ià è~‹8Ô¶Ómnö¯÷]…ïrH^Ô]Úó]w¾Nk@pşu~„He›ªc¿ê0Mvê× äŒ“F^Ï87K„ÅîHd9€— Àğ¤°YÚ…ÅÍcÛzù3ÔŠ¦ˆÂ8<h×zğ2jF·†Yn‘KH¬7üîòn˜@ûl|L¦¬T­åêw¯B	ã?ZöšÍTH)Í)ã¾¹ŞëÄû–»+nlÀÿus®8‹sVÎR’«½>‹Ny4Zİp*”-ë¹Îº¹Ã®!£P¦ —æ<êŞ¼~Ê“°a‘#ßõ)B¤ç'{¸¹Úºº˜Ö`›MvO«6º#¶"í!ÛÜA²±ôcí®äXÍ/cG©fşáy(Y§½X±”w{#WƒÙrì­ĞŒ³Ä²ìaKÄ4Â!CnB´üÎéN•âëê²ê˜[e²ªï¥¼"Ù XÎß¸æl-Œß9Ñ÷Ø• ßşP„éà–ÂÑŠ°¿ø`QÜ°ù“.ÙÜzzxºÛ&h~éØZf›…©âÂš—·Wæä(*<	ßÛçğ hÛ1¨ò›ÅBF)[\q ƒZß;>×c”)TjÒ+<NŸÈ¾öàåF¶!VŸt”G¦&C-ıšü‘»TJ+.^ 0õx£Ex|äœå°ZWO‡gâ?„¼ŞSúâôŸœãj¬ £«ËÏ70KI‹Ø;vÔE¬ØNÎ aıMÁ‹{FÊYÈ„B»N{j²¿ĞpšïÇû®@âô—µXŞiÑ§F_ªµñ¹ú@Ü©C<'_ß<”ÙjhW¶?äX¤ò}•ëH®>µËQ)›½8,2ö>¹a7BoU$'»ù©Œ2ŒE€×’|^8—ÏI^¸mÆÏ+#a èÆÿ*âóZÂnÓ¸BGéã›Ğö¤*£®ÂX}ÑÖ…Qº—˜F‚êh˜„ú;–ş²?S€¤ÈMt¥Üd-ÃƒOŸùC@üú‰mÙ¥m	ÍiÓNCœ 3øêº}ì·E|¨FqÚÚ—½AşŸĞ§2ÚóV+„ø³|ş4–°êcÆëÁ‹(¡—lö¡õË±´˜­åóB›ib®»¬nÉSë¼âßI¹šs0÷ëOœåS¡t]qÑRE„‚Ñû¯¬@k¥á¢=tƒPP×òİgÛj£§Ìø.z¾Ì :ÏHŸU¶Ê[ªÀ¼(u»9ê•Áßx:“GwÚ™}Œš{(`Zèa”É@ÚÃ°Š½O7â0…4Ø¿Š¦]î\
Àİ¿H¤½›‡ç}¼®àçïŞëĞ*ú»²^ÚùìÎÉ®ÕŸ¯šêwiçìCË]Ã(-Ğ<Úª’ë˜ì »–»H_H‡ÑgUáÕ÷³ÚË^ØµÕĞb¤òÖ”Åñ«ºÈì9Ô(WéDÊ’ü(U„‚9nß‹¾ÿµBÇcPpp´ŠÆÍ¢1ë˜“î#x˜Ÿá;NÜªÍ{í1¬…Z”î÷€šÉkUÀÜ	±)Îë¯F "/
ş{ıx”†Ñ:Ô™JKÁ ?´é¿w¯:oêyÿÉRÁµ†Š˜ç¡ßEÍÆŒƒÚØ—8z¦÷<»iÔo>¼¤b‚eı_ŞD\ÅVÑçüJ_â.w7»pÈTEj)óM1ÒyY¢ØõÕWlM€™‰Zíúeëß×2ğÎ+“6vşwjp8ğcøñE	Æ
²ƒ=Øf£0íø¸z#àÀNÜî ñÉô{T2áÂ&ÜJ~I¶ÑrbS3‡6Ÿ”ÿ‰ÄÛ7½5c-­&|TÒÃŠ(Å\{çêeêCŸ&Ù 4½ó£¯9—ö­ùßÿfwèY¬:¢£¶õj3ùjĞÆY+İ6a}åUHã%ît¸¦/ÚmâGø¬­|~™YhØÓmZº’:{¹O{§Aëö¼c/€V%zÌ(àŞ_IÉ­]{„Ï(Ã“¬ßK8ñüàó€:‹|×îC½®¿õ¦½í¿YKÉ9Şâ´Õ»ãğÌäş&CˆGS*lùÇyÎ„ÀÄúŠƒã+÷ªÈŠ uI¼„#«•şô^+g6#šZÎr­ŒŞA6%DIt>6Yf:_ºp@ĞB?€£æÖ"[Üô)RŞœm£Ê±C¬gO¤mmìKoîÂô¤İ	¿ şƒ‘·«Åd÷Ø-j¤ïƒğ=Ê h
á¨¼œ©~à
Èf~IÁwğ?ç‰J‚ÅèZ4m	(¦Ú™mŠëõI;ÿLQôrPVO“Xûá|jÛ›Ï êæ6•—§pÛÄé ˆ…¼êdÛs[â"Ë%w*2Ém)û”„ì;)õfBı(h…ßÕCó/‡F~ïm¥€ù(F æ›'P‡7è:÷ë°¯òÍi¨İÄ*hà±åŒcTƒÄfü!€}wW¹öR
¤êâÿ”\¨¦KYO+ò¯¢	AU?ET?‹:Ûáój/³æüS–‰<b*uw€x+ğâ÷Q2¢B©ìÉ–˜¦Œ÷Íótfˆ¯ÛA˜Ö3z¾³y¤@=R
@:\=9Õ¼Ÿ,XtàtˆÄıO(å›?m¦W{ĞdNÅùÉ 3Zı»Õfr@6Ğf£À¶Tzp`‰ÕUÄØù•y¸}O…±ØO–f¦˜ço µÓÔù0]‡˜â×ŸPVxÉ\º\xb%”7â<ŠÁo ª6XP]©[x¨§”Î¨¥À‘ou‰J@_–O$8½ÈèÕXDûÅC%ÍX Fµì2ÇuYl&~Ÿl¶6HV)]y„2±sÁa'Xp¢“ş:½N†^)ïe6H{^)ÍÏdÆG×¤-.:oKUæ7ÀŞ)¬)lLM™Õ¶=p²Âj ¹é…h½	2UÓÛämÑzƒ¼k÷n]ÃÖ¥Z©XÑ‘Šº¢YšY·Z>îTCBÔèÃ½4¾—o2!»U“uÚÇGö¤XŸ®S‡êÏıU‘ƒ M¡}öÿ”ğ2^+—ù^Yz2ãó_T
ª‘Ë©m“Xè„WU¾StLqolÂÉ|“íG¡‡boRp÷VvËl“bãfœúl@½}tªûïÇËÕÆğ…Î„NØ ÷›3¼ôO?ŒvSˆúê²
×öŠïGä½»^Uh½Êù;UM®GyØóF]³•0S£ıE¾bÿ{âXß‘£ÇlÛ¿{2‹1ƒO­Ó>Ç2ÀºZZRy~ A2OšÇÀMIÔOyÓl#H"½‡Øƒ|¸•D’åvq£šn¹l_¢xMÄøû5½Iê>ò&Œİs/†ïi­áÏõ¿Ì@ûúß„µÉ.+RÃèÂ’ËIùûFrÈƒ.ïPcÖy«˜æK5ÉP®5ßı$¼b¿/_î™°¹›Ğ‚ûˆ½oj&lÁ½ìR)AVl¨ÙÌåd0Ï|#édÓÀ°€%zzı6ŠÃ’Şİ<I¨£¬cëÍ7—†7²–ˆÖR´$‡û™€ğÄ|F
»x7B.°¡¤Â´í 8#[?uÓÍéÌª¸FªzĞ5”¬Ã®††ü¯ó/>PVpmÌeÌ§ÍÕ`/¼T$ü2t&¾’
9k#b†Ø3;€¶MõBKÔFN4Ä6u,¦Ô¸¡ğäß…ë$·3¦–H¯m›IqQD±1‚J	ğIˆ]^¨2ıv§Ş«5¯	 zN;Ìz#ëô¯ŸË‚Ã_ø?àÍ	ZªZÔ·KQÔo%°l(Sygˆ‘™ÙßËËkÙá>vy›—¿:ÏãiŒª™s¯‰ËX]Ö#.CıKmø´âÏéÑöé¤¡Ñ×Z}5pú½'¥â©¿jƒ=ÔµùR{Ìs$Âoc>äŠ´á_1‚.ÀÙú 6a”ô»l#Í!S•‡ù¶‘À
Aó}yÁóF:¤ÂQ·a^‡¨Š@‘mİB×Ü›HD®¹ø=½b‰Hçgš;RfJ‡ÄšÇ3Š^çZFÊî³»¼ïºIÍœP7ºA†@RG÷à
…=éö>1üëÜR÷Z­&ü§¢‚Nğ%ü1›F•U#H1*ÌÉ
Ç<ú6’ˆGbÉİ	üf ObRS¶:¶6üĞ<K§Bèm¤·¸¨jéİ’‚§F>È½ø+0VgPQ’ë‰2—»±oû	·Å§eMpò×_P1=ƒ ¼ßø'Ö‡Göé{Îk	Ÿ÷d	ÙçÁÄ‚PÙKÇ‘[os  ¡Ç*E'R¨ZÑRd5< ›öhÕ#ì‹¸ˆğSpµ’àRØàg±V…qÃp{0²Ê³$½PéI”ú mÖ#¥Q9Ã^Ã…èµaZ¬ièz¬‘¥*~ÍC¶ùjg!ª ™¿j…¤õ
F• şE¼ËZÁå/"2¢²CìW “"Ï/,şÅK¥èƒ¥™8Mo8+·ã/²´í"{ÊuÁ÷H7…’ı¼‰,Á…À,LJÇœzÎ ó<K~mUT?–™}«És÷Œ´5HQqtI:Şêµ>ºCdÅÉ7¬!¹!üå¤GÇñÌ`üV!íY<¦²`ÿ6üYy	a.gøƒ{E¾ŠèhÍ†üºjJÍßt5ÇÛ‡>/h>L7Ëú‰\2;Š^G	ò
Ö®Å©ÕT­¥ÔŒS‹»_à¡<©J:ËüÌRMÃvijÙ•[?Ÿ¦Ğ“®g“ä_•ÚÔô=’Jûõ+§'{Rë4ÇÇŸ»$ÌŸÚ9¾ûå?``û+‰ãRİP‡ğ8íU	,òô`A£®7H…÷:3íé­(?ä•êøÊU(±‘ÿ|:^ì‚ÖT,Zt`ÿ3–/X¶t~Ù)æ*Vi7q´EcÆ§™è3`6ä1&£XµÀvdà-óŠúÙxşØ@øOS§# ¨5&4·1ñ"±Z¶·1°¨ÜÅ2KÙ/!(9®÷xc>	2’0Ñ‹j|;­¤{ÈÁ	Ï †¯?A¤•]x3¨2‹¶#D;­öãÚŸŞå ìĞúo|‚yÕ¹Ö}ë[Æd¸à~»AHobGìs®+Ïw‘Å$.Æà¹X‚äÁ7—Ç z.ø™fÖÈµº5cö%ÖZµrE,Eøhu¨M;ò»í²>*Â{t‰í'…È˜+¤€GâµÍÉÑNçß÷¼ƒV²#|g»®Ìƒæ-¹ş¶/*:Ùğ·õ™‚tØ‹BıDò¸&—)ãfy%ôÂÒIœ±&1C"æüº²×c@%×<#»EEêâï”ÜÜİk'™%çË6¦¸:¼Dkl6Ğeâ‡ÈÛhEM3˜ø»8ØËpÂ^î¸µ±ƒí 6Ì]¥ü˜•i)+“²‘çGqÂ'lZîµğœ¥™§`‡cü™6_j¤¿èŒ”•æè¸ËÓÜ4Ñ!–õ6´ôåºW6Çú™ÓWOŞÕ3¦a©ÓN¾¹èp½9¿àÌƒèæÇ·Á×d ]ëE¯wx°‘‘Ò«dášeş< “³öumz‡çt¬,¿Ÿã{ «¶™İ²¿EçG)âqHµZÃ*¶¹/qÈ•-®àw˜vNÄ™y§È
õ]XV¶>ÿHïzcN¦Ö1ÌJçDaCw7€V‚v‰ÚÚçw`ç±7”òüdãBÌüåûİ–ßïÊö8»¢ˆsB×›Yú~,gñ£¢Ì
I±ü£ë'Â–gÎ•LîAŞ’—Dß„ıâ×b•¦èÎóªÏñÖW‹DŠªû!Í4zü^úl¶ù  #9ô³àdiÆ¾õƒ5[O‡´¸Â»ÓPI¦D{ôföiÒK§´á/%|Ê!„[J;jó!šcª
÷	ºG/s¹EèRÓako8 ¢¡æä®¸ä™9\¦]Şö=)qûŞà)÷75‹õd9—@Ÿ§¥¢§ëİÌ?‹¥%½x¤s¢á`\(§ü&}Fğ„¯Çó¢˜î™6«ïSÆ„l-Nç¬£Î†Ó'YO‡hÃQ¢"è²'ıÌ4}ÿŸ$yHÙÅz„YÏ1Ôü#æI«Ì"İ?ÒÌ“y±“{UÊ>–ôš ÜÍ†yÇ0••Úsì5èÙAüš5†VÚ¦(¸ıÕ×_z_Ö§	C_;ä¸=Yí<ÿál›>ÀD¢Ÿ¹h&0Ue:"«6MìŸ¸€ÕAÚæp²EàXÔÕãe9Õø€Â˜íù ºh£Ôö×<­`nÒK4ƒ˜ç$£aàã”RŞ.¿ãË<úI±LD~¶hGĞ¥x½ˆ6„Â”Šçâ“ØÄ+4ùéR¨VJ¾>ãX‘6nòP× =äò•ÂlaîNX'ï‘µoû»dÛuL’" 6a¢›aæ9`“MílÎ„ĞéaI»Ãöû¬òÔÂ,ödNe‰ÚQ‰+Ñ	Ä&Kï¤æ¾œ@Šƒ¸ıÁ;Í6ÆM-.ÏB£“ÛG"e¬ğ]`æ64âJ6§í]¹ê;ìÉ4,¼?y1ÚN¢MŞEÅ’„M°‰Ñ6»ÿø=]^˜®î¯®¾WˆëI­û’×DÁõüS“ÒÕ¦Pß™·¯
t`ñ©zr»åà^|/˜Û…MtaTzF×}İ”Xj‰fùéi(£±pŸ:^`Z‰7±<•ä¨RL+İ¯í:&¹TÇ66|Ğw/g0„;™Qb¤g±ûä`Š´± Ìu&µ™€—æ.b¹l!Nc,ó»¨nÊß@^ü3Ób>Bë™¢ üñyÖÿp#¹eJ÷òØOÃq­À‰2¶çbªŠ©û–«Â©8mB[O`’÷«oÛO:—Ù_è1üo§v-È|¦V­BÒ2-ÜYO‚R	ƒ{/A›0$Œ„AõçÂù	¤äÂ½Áü¶a‡š2Õ ¸‘ô•ˆ¥c¨õHÃwÈ¾cU”ê_-í›IãË¯oùàizY-Àé¦Y!OU¶ÅxU.z‚Ú1ú ÑÇãÈ¶ØL¢—ëŠÕîóêÎˆ»@txZ§EmwÍCÇÒâAš[Û~Rñ|î²Ğ½üğ¨\ï!†µO~:
8®…ñ›mõ¬r×œ¶HH@^ü3Ûà‚¬›Ï¶UDKıgZ°ıTø+­a%œÎÑ¥´àI¶qË UkFÜ©º*áO	i;ó5@¥mãeõÊ%NI>@^uË½×¼œÆDr»ñ•VÓ&õÃ#+tÆ©w7ëß2ÜúÚ$v9i¸ ßßK?Z£5Âï¸`Ím&æÆÆ¼L,ç7BÎôÊ±Â?±¶’\Y.²IÍÁ|ªO"z¶şÓ‚½CSb¡°2KÉ2bIJ¹Azø_®†»‚ö¾*í{T ex¸c_é<¸İ;EÒŒİNVó?örà3»Á=7•Xx”ûLaÔÀÑq¯x¿dˆSÛªÌñ¿zİuV®€Ç¿òw¯^OúƒÆâŒ)	Hëä.ö•ºŞÁx(è$:zÃÚê,L“‡¥õìzŞ^2‡ZÄk(TIÅM» à¡Q+6’Ö>‡²q•=,™Ù½—ïÁLVÿ*Ø‡ÿ¡‡àğÁÇHíJ.)á8F¨‰=y¡€€m¿pàôP „%Ä`Ï–µcz„æö_ˆ¸ßÓÍ¢—´NñÑ¾ßµœqvk³Ø¾l¼ã‡Š[jdëà§À×k×YÃJQâì8Ê²áCè’€,#ÈD³ Àì¹'½°õ!Â'pàİ-³_Ï©}hŸ)`ğV„¸“cÑïdyµ×NC?P·˜z¡U*Y}û‚Ïoíâ ÕêÊ×XâŸ
‹‚Z¥‹|4ór’ş—n½–h?8óö}FQq¹Ã×?-Š÷o9ƒJi6Î5Õ¿fBÖWŞ­WàEïZXß8ÕM^‹G+d]Åú”ãPnşZ Õ%aRbÙëƒïÖcíŞæ_w“7½‘Z‰ßàæ#xâYÿb;®ª8ñú«áË¡x,òÎèsøÃ•…Ë©r%E²AÜ­îMnŸ"=Ç9øÙ˜Qó@ä|r—*¾†![¦ÖëÚ}éäQ×Ñª?”Öy*Ÿôk0Ge"ø[ïpñjÜ<ˆµ‚"{¬ö†|@W_ãD³RãN8Kò“è™ñq†Şÿ3zw]ü4ıoı7 Æ!İ‘QUlş…Ác€‚sÙ¥RìÒTğ:¿3äâEMg†ÀÍú*ÙAç©ÜS!ÁÖ²>ú>‚&^n3UMdLïØœØ¶­O¦³±İSñìXŠºˆV¾­åEø|û¤•eæxõÊêœ2˜DÄo>3j­V›èÿ—=Û»é<ŸßÛ–Ñ¯Áı»„>GÖ(n
‹]Á¯;R$ütD›¼lm¸…İìËqi†t¶@^Ç†$c„t”"ZÙú @Ò8ƒ6ı¼O2ãˆ(›ñj’b–ä°ıMÌ5gï¨ô³\{B„ œuN­v›Ëå÷@¡c”à#ìò±ÔRşˆh¡N›²­‰AO6z.0W[ËqJ?6ò’L¼€>LXg}:dP!!K¬‘…~ÃTNaÚ˜/¸D¹¾¯zví'­!™ïO×6Z@OíÊQk¢U$8õĞkñö= oå×ŸŠ­úÂ/ØúöïY£•ß‚_<»ìH˜ğŞ{	œè"#Pƒl,Ğ>%–Ø% ]9â`¤2›Ök&ßŸèŞ_ìrØp«XºãğP_ñ¬*4.sØÛı0B‚©l <éì¦13‚›²pß‹´â®³-F»fóÒÿñzñ1º\D‚?Ukú4˜9]ZşÉ™ëk£Ê|º»Â¸£ëlKÀäa’K–rXıwy„²vJŠ½è-r­e© š£0b
Ú/ÃŞûù{©&‹nÙ;ò¼oZ¼wN´Eü”¶ LÅ
%	Ìê„Ç×Xí7F<ùuSz€o?à‘ËLÕTİ_ÕBEî#C1^A¬ÏõR„ Çî›”±{ a^—º´K1»@4÷B!xa„ËÏ…ÙŸÈÊÃ—äsÔ'ŠÄWüÃ|Ş@¥R€yì*ÌkiÆú¥à±?®˜èùyzöß¦Ï˜ÊÑWë‘wgGª;n.äL¬â;|Â„@'«ô’6ì	î©˜»xë2bÂOÈ‡ËİÀY©hØ	nªÄh3v°i{çÁp=æ¾KœO¹óp–×qİ\@—‡”ŞSˆÁéÃÏ×“÷¹Un5``ªé`bs"yã÷PğÃöø‚¬Ty!²3ìSY.ï=Fè•ÏX…{v2dÈhu"ğ«ê6é²`É»Xù·s?yÙ¥dÀºt-0x+£½y"Ü]Øx(UÙÔ°,œ4$ıÆoĞt"3ÕYï,HæøÏ›!ƒóË½·Zïç¢AËAÚÊïZKpRõ­ãk”M=cVèÒ¦0§¹I„AÖ›ÖOì¤ùK§µ‘Œ¥âz‡@¼ğ'şâ2®ë§½ã:ËN^ŠE7	FĞ‰q¾›ó¤dNeğê®6Sî1ECË·ÃM‘µ^ Ìxì¤À­°ÒIPøm¨Y¼ÚÇ]¢!©Ø¾ÜO¢·U£F‚5,}edñ„j¶ˆ	ºD¦3èy=m©uçœä²;ô§i®Æ?‚­ÒªÊùD³¢+àVšAkÊ†g„’41A¦,óŞHÕ>x-¯ÂGÔö?=.ÑR¿Ôoš7ÍÇ|÷
>İL&Æi”hs®µİo?êÛ›½,BWÉŒ2êo?¼2)2Ï}4ê&CÄ¬nú…WÔ¨ŒàzÚ‡-›CÎáRÔDõ×2,”ÍÂ†ğN ^… ×€¡('ÑB	1¨RÚ~°Ş¿¶oRc‹rX3Ü™™[¢„¦§ÔUA}@§¡ÎoN;ºÔÎD±ı
„¼c¸¯É‡^lÒ
^ã;æ9~Æeüİø{ob™¾6)¾#ÒV—ÅÜÙ£§6ª#éïıPË¥…©ª´»#ã\ª™kå ¿:ÿÌ¼ò±0fÑªD¤v‹QİÌ(/?œºK}Ù0÷ 0Œ‰2$à†Å$vn(C51êÎ¥&‡¬jtœÂßi«ânò|bŒB:y6ò q<ã7H'Ya/3R*P¹ù]=Ú¯|!Ã4\=Xêès’Û‡Iº†æ²ŠMË”¤¾‘—b¾ƒİ*(Îé& ß|HĞuç×qã»LcíHQjq£ıï0‘{,²Ëöø^{»pH÷O`,°ı¥ÀÿÚpú²^›L$ZK±üøby½eÒÃßm1—A6¶}rËš³g~mìw¸¹ûÚi.›Ì–£í=è¾)òL7ÜçX%ÚË#¯U'çœnWFÿ,>_Sğ ÑÅì~Dácl½È7øa)œ‡‹œª™ä’‰õ²÷…‰Ï"‚Ÿ±xCƒ‘øšlbFz_²M>kADcQ&¶4Âñ}=¿NİK|—a¢ÒXÑÔ2/Å)EYLtSŠD‹|fKE9†ÛOcƒÈ¤œ`”$w®Ï k`ŒŒĞÇãM48Dµ`’A¹ù©É—N–.¶{hĞà•V¼iÖÅ¥{Wöèº¶˜RË˜°ƒDœ®E<ömh'ñY˜>áw‡îªuËHä4}R}Kvµ‹‘`îs1J6CC-Ó€£%]‘Š›ïAóäVÃi¤‡ 1Æz3Cè…v‡ıöïá<wÕH	D[…H"8£bHÀÍOıCòL‰Ã‹'çŞ˜CHD¿LËbDÔ;Jëäîöû,‹œîñ}¤üîWç§p>~BÈERÙ:pôçŞ¤LÉŒ¤%wüµ	f*Š«Í&s@åîe˜éÉr5&†¡ÿÜa;#…!r9	¦ı¨é\!ªF Ä³vˆÇ°3Wf^~Ä 9˜ê Œ¦ìî¥a<%öº:…#œÔ9¿L›WLÂ,ôgd­…	fÅİTÛ«k9ÇUÍ6À£=âÃ£ÀËÜÀŸÈÖÿ299rñ{QyY¡ôX™¶a×_W¬}wk?/.6Mè(^‚ae’o’Ûêl:Ö‰ˆ¨½ëº&pô“7Ã„@Ïü‘–Ïš*í15asi tÉIÇ(¸(óxx·…Iø†-ºrÆ°u#ıfˆ}:©ôI×éfÎ,]Á~“ÀULÛ-ö”ã+Æ8¤EuÄ¨p*hÍ6”A[}½œàD‚Íçí¯?¼åŒTö*;ãxŒ}`ª.Èc¥õ`²µeZ’Eo$Ÿ$RÉ|tôê\ƒat3#VC7lêB
lÓEôgúàøa7xüa()à¹6X‘®ÏªŒ?í¡'å>¤?fÕƒª'Œ^-Je³9Ôàÿ¹ƒ^(ã7/›œäæPÕnBÃû­Ïö¹5P„Y:Á‡ğE3TÓª…C´¤°ÅßJü.·%ø»7ºYãúf`äPÁÕ<û2!ÿŠO­œ‡»~_ú4Ãq]ÿÙUâJ˜-ùn"*Ò|&Û³ÂÙÌ…ƒûkD|lıÇQ€‹‚¬!:¨z^Xéúfõ7êıbö@ÅWl«èbÓMÕÈæØ2ndş ™†¶—”@Îñy«Òn^èá‘…« )^® ¶_ßèßŞÉsrÒãCV)üÊoû`ê•â!µ)cı"Öh-˜!5ğÜ&&ÓA…±ìk.?¨ÙÛÚÙİã®—¦Ø~²*^{à§Ø˜ ¹àH}íFšx
[Yæ&’Ù¼DÒªYc<qÇ+µwØ¾ò{3FÒ
2·åå~KÈOÆ4¬•z¨&‹-ŞÑ¦¦b2	éù¯»ïoHƒ¬2Öì F}Ú‹o¯®àª_Œ‡¼Ø]ÛÆ¨0ü9ÎçŠ4¡w<UáQ‘jxå­ÉÏ†9£™óDÊ8"FuGûb"º¦ Üü~Ng) ÀIœº•“E0c«f®‘8d4V‹®Ä_»òç©î,ŸcûÑ”çh)nçS]½SœÁhÒWõÂÆœğø#/c¸pFSfv8”ÖµöŠíH¾µ3XõzÊ»İfJ EœfiöúK›u„±iÈ'P)ò£Ôz‹&×t-İÊ¬ÖŠ›ö*‰–Š0C0¸Ôwİ3òÍš%ÌßØA¯îy+O»ÅËo1÷ôV~ájkI;o²Í|¬‘%Ó"5ë)ƒeˆ¹«†Áx¦áglİ¯ëÛ¯£Fâ1‘® ”¥„B‰#†Õ£3ËYérO×Ÿª3©™’G.?kø Ÿ¾N2k©Ïîœ¢.w©æïİm©hLImî©¢zé’È¾jãüÆbóúCÃ&4ñĞ‘ó°ÏôŞEğ@<ˆê1—8Şôˆ‹Â|z¤¥~“ºl*[ôi#ê09vÊ>?ÒV/L q]+KdüWÒ§ãyyŞIh(õUæ€Şèì÷
±æ­	”¼ªb¼âx=3™Æv,†
¥’ê­ù¼’“]M¢UÚ¢ı±¸0¾ZÇê5Şš€¹ù"=HøÁÚ4Şd”7¦Ç,á×AQn³‡B‘[9ÓÈœÑ'Ùïoñ^j£¥Ù!ßÆ.¿µOGD@—R¦I&ßøT)§¹:ïÃØÏ³eÿÅ/ÿâ\Qê/ <ûÜé?îãèx¸"èôõŠ¶%ÉåëBÀQ3²%rãG‡?¤Ÿ}4Ê`Ğı9Häíz¾Vìú¡(d,ºÁÌœ]µê%t#¦OúøŸ±ıRcWßÏĞ¾#Šğ\0]XĞh7O©âT½×ışÓğBH„<<T9ßŸÌ¢ÏÅª®—÷´şBvX÷ã:{gkcÀf™ëø fĞM„ÀU©\Sà;úøŒÇİ7t•1\BìÑ†Ùü¶ªØ­†¤5ıØ¢²ùıc£ Òñğ dİ¢âüY|è+4nŠˆ(ü:§a¸œò“"ß]’W‹‰GáçùÈR}k£»~UIiòbfÃGù'®~*ø‚ä%^b~% 1¢væáÌO°Œ¡©¾„Û0iÃ9ôbç£˜ËğeZ¤-°}Lt/RŸè1ºƒ¼>a%˜ÕN³7tË¶™”®f2k©8Ë›à¦ëLwKÚ”0ePmíúÄş²"Cƒ„¢}‡÷pÇ©ÿÈZ>üÛ‹ˆÇT"ß³[b­ıÆ•Yöwøú¼=Bégü$ÜÈ€õ}rß[¸¿İ!!
µøœçóÔ8}¸"7~BAZ‚bYeëpœõrØÚA6÷°2#‘çØ/¡T>êëÔ‹¯Š¸½(Ğ-ËÛøõ>}Vƒâ%ºÇ'Âõéæ½{u†A2ºŠ¬Jk7µC’hd¬´^”¾‹?Åîqf¤³¤ÑÌa5£4‰|Y•_™@ ’
4zGÉ‘YvT+)t`SXÑ.¥€#RÙÕ-W§ÿÎ“¹öGUß§|İÉ×}Äˆ–x­ûÖÕ¼h@-Øm( <)”<n¥eŸarìü¸ŠÇã-ª¸ WTæñQ”»ã¥œr¢š%¶Gu^™)çĞÎm™Ë[U¤‚RœTìE=ª~;ç$üª‚ïÈ«'"œà¡¡óøBìïvÆ|¹ÿşÌGà¬ôD\f(öÒöÖu\¼Â ÂÄéÎmÍ¨õ˜ï±dãÚØrÈ.”ÆìT†÷Ï@dujÑMq€7ˆB>òÔ_^§oóŞÄí>ÑµÆC¨‡ 
Ë†«û3Áõ¸v³‰t¶~¢&]Ü3P¥®¡;ö^ğ·Lş@šsë÷=ƒC{ÑÍbGœê€1Œãı¡Êa)é”†Kgü;P×”oïÀÕëÓ7ÕFU·T/â˜Õ·-)™°ùêÈÊxh¯ÑV¨~ßôX R<é*„îKI@¶éÕsçf08‚1—¦ÌãçÇ_–w²"€
éĞ—ÆßYÊê^Á™Oø´Hñ’‘À8<¼éoùD›Œ·:C[&¤ãN‰½/nw¯Ø^¾Îó%íBP5,Âd¨ïÈ!ÖÑûûÓ0íõ&¥å´iœûJ¤]ã?ız3[\¸Jª^èÂ@{YNY]ÃcJñ
<2?>x
®³Œû²¯:A¾ÉñJ#Å‹mXúpK…ê3ŠU6gÓ)IªÓškÚR#ËŞ'<kj'¤íRmôº1÷‡Şl¤;Š¡ïÉ”N8Îz5÷³ÃÜá¨	/$R¢P2›¯\BRl[ÕRÈ ÁY x°
Î’õò0qŠ±nÇ]-Ó¿¨‹W»f‹‘>ë‚¹ÿ:¾÷(ßrâ<ó{Æ­`g-4¾™µjxEÙ“İïîÏ!]â^¤É]ç”hg¿}Á·TÌhíÇ±ôH±~>À­ÚèØ!·M4ë4`êbÃ|Æ,÷‘)úÆİiBªÙq#§ŒÈšxÊâ¸-{ñYx1°ãœ::'i¾X˜Ó°Üj:KO?CXÒÒ;×Y
çéİß!ÑÚq^äJ4ğ×QhYÀ½¶SıÀi/°ÇëÆœGr5+«‡¡c™á¡;}ˆI—Pp£şéÂ,Vì –9Sa\~PºÑ·Â8ã0Z!*İ¢ê©ë°,ãÏø„g‹ù‚jY+ÙêGjŸ2Qj j³=)f™Ó0}IXS§ˆ\ŒRä]&šÃ
Uh©á­Zı·ÑÎhC6„'¹~{Ñ°¬nö4Xæ®R'-üäÈã±v\ªpŠ}À52ÒÅ¹P,®ÅŸ‘Ä“¹4¡Ñ¨Q» BÄ'N°‘Éí„‚µ=e}Bno¼YŞK¯]uÏ®-pÄs)UÕ'©B_^},yoí 	s=<Y/¯ºVOXå_ĞÃXS•Œò
dA3ZocYòÔ—õZjƒBø³+ešš4pÆ…¦Yü«9ĞÃ¨Ï­çØIØÀÕ‘d}Eï‚Z-HF;4+ùî3—ôXO‰N£œıl*8!(ô4eçjÑ×íÚùnš)*É Ü¤¶Œ–áLÇfØ3ÍQ“11Œ]üŠüãìô ÷pûãgËùC_¶GğY“D˜â?HNäPuà>ûÜ‹" 3÷ÊzäÀ¤X[	Ùt·Ò·8.*Ô²zô¿r‰LÏnW(JÑò<i*œs¨Ş¨¶ÓŞù©F5M.±õêf£Ì35mŞëÉÖ…CÚ
¤EêÅ–ÿ™4õ¨#}~‰~`S#:%í0íO|?ú‹Ä•}l­^ló“†sC4-ïw"§cŒ?5Ëc•lJ„‚"Îà’dÑQa@áİ£º	LÂ]Q€À+‡½¢!ã¦{i8 ˆ‹Ô³w`L’nŞ€F}-´NĞ‚!Î%/ı1ãÅÇvä…¤¥¥w„’ÚXÑTGÌ­ç µH#ôßiŞÌÆ.ÆŠ|;ì¬tÀrİÉ^ıx¶vt?iŞ~¢ıˆ¼,&ìúçN¦¯ŠÒM–¡5µ¤MO'Ûı{¤
Oò³@e³=ĞÃ½¶0Lˆ¨±aEIıId,cVÅ}vDE›mWàV®gv+1Èf>—n»Š7¤:D)¡O‡ç—–òÍetË®Ã¡‹ĞÎ$5—ÓXt—èØ–BÅ?;Ø™jtI?şòLHl×ÕnÆÒ‚ó.,¦œZºJÀ…ê3óÓOò¾ºr!]Y{a¤–Íywø8%i´^Î$œ˜¹kÛWšfÁuïÛÖO+`²(ÙXù¥ˆ"f™§ÊNR}8­*”8Ğ
A…²kKN'Â«—<“7¸^¬ˆµeÆäš,Dòö{ŠªçKîéü±¦9KüNßK€Äßn±_æáÃ¾Ïm¯,˜fA'æz /yx1…Îİî;äv‡ÅHò˜Óxéf–Ø+z:lq†—‹<ñ©@RŠÀ‡dRš¢a¼Û²}Û'.ª*cf/Ï’ÇHro„o&4&RT!ö_[Õ"µVKaúöÄ,‘t Sõn·zòì;şyšØéŒÆ±L59paÀ¹’ùeÜŞYô½XñG	(ÿf-Ë„-Ş×ÃÕ¦ä.<[ğÁK&mz$¿€şª`è—û;Ê:(õÌ6ÊÎwí+ê ;XZ¹rãæĞdW:W¬KÄlÀ8+ñr\¹Oa_!Ñ¬Ïİü{gT,1kêfïv’AİÛ^©I0„ öé,Qª<ÿï<<÷~ß˜ÜSëb4ôC2"œ!«?áğ"õ´Ë!¥¼4wÑ0(Ñ38¦†<o˜ùOó9>’"8ÂQ¤Ğ(JX¦¢%ë$öRşâ6¼Û*ç98f?›ÛrÖr¢¦¾ÕÌ«í’Ÿ¶fÁÏÇš]«HÆ>,‹ÅÿÂ•<4·^ïPáÂ…GË64õé—ŠGÜ=ÚèÊñé7¡u[/ø™7Áv8DP†²¿=ñ…Ô{„Ş=C]Á£oÕd»×i´¸`--d§ËÊ([®$K·Ş» ´`šáD?£İĞj ¥l ÑV$!‚9ƒ0Õ)¶Ñ]ı¨Ø´U z¥g8âàyê@ÒCñ¾ùÌ™^,îåö&E@t§Öt¢R8pşsœB(•¼¢—İu:Ev¤«|Ò¹Dp–ò!‡ÖA˜U´ÛMæ›Š—Ÿ`ßà^Z¹8¡ó·:»tZ…‘p§«l¬z3
¿Â?¹Lë±ïí|BÊb%V€-©ZPór7»[}.àkŠ’~î
ajLaĞ	-ùe”Ğ0\a¹ÓE"‚K†â¾ÿ¬êÇ|HıÕi‹ËøÙqvIk®,ôàoMfd‹¾2E}¢ïm‡<Ê“ ’æjún:™×7‰Ë1şã”bô¸+±?Y*Ê7¬~NõN¼ù‚È hH°4O›½ºPÿ0Ìˆˆ*SâR?ÑÈ|âûî}³¼.ÑXJÏ^@^eçwûPİcÉ}ye#FŒh— t¡—8ˆíù±¤)V.B1h?@­óxé?ôïß®.°ùA‚*Í¤İÂìŸ>ÙdL”G)‚ğÌ˜ÖœèşÍÁˆ È`óH¶åq¿ÉóšQ"rM¸³Ñò‹·+è£o=ZRùòu<ÿdOy€\ÛSŠÄmäè›Ø€÷$ûØ*5KÑüg]pp¤§÷²ú•>’XuEÛ½ƒÜ„Ñoå	ß¡ AaÎCü®à(sb6ÄòNV+”ç<„ä#Ò¥Ä\Oİ>•ı½p8æUš) 9†Ílğ&»:Mšº!_”gpOa¯ÓQôŠ|èaó‚ŞBÌy\6KåõI¶Üñ~·P|Û¹fÎÙ¤&c¸3ŞÍjaµ€8ŞÏ±íP-dWI	¢Ò|vjºÊÈ=ÈÉ>a×ƒzÓ v¶À]=_+;€´CTeşùôÃ6&+o·v‘Ø®jx#»°¤#?yärdà(jOºøcX¶Q@P²ã23'3Ø_Âscñf   sbäù™°iš îÍ€ˆüØ±Ägû    YZ