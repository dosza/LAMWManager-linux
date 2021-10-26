#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3299787177"
MD5="c30f2f8b91916e86f56111ec2606ba00"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="24176"
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
	echo Date of packaging: Tue Oct 26 00:04:08 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ^0] ¼}•À1Dd]‡Á›PætİDõ¿R^ƒê‰Î:!9G´4ÇHP˜wEe~­,-jå¼Â2ä¼YÒµÃaäæÕÆ#í³³-ÃÁÔ l	ÙÍï]âÈGô¶œ+ıdb<#~{9kÛGaøDµoÏó$M™¼t>qá2 ágÉ<†9j³r‘ö¾t|¡K<@wµ¶¤˜î?uÇ™¾’g±»å¸|QƒÉ£èD”®¶ı•ºØQLæ%Î]ÿ\B”3w±îÆ‚zU¬õ¿ÊReŠÎ³=Nå=›¬°uÁ¾ù$—„²~obdĞïèÜbnÒ£ÃÌÆg|lTÌÙÂ-‡”qùÑLøî€,¹Zµ‚4 éÅì¾¼}wåY¸M%PY¤‚‰îä(mí[ÙE`y¶„æ Ä8b­ŒG»¼ÿâ!Õ¸€çİ‰pÜGŒ’ª‰–ô©ap…ïN)Y<ğ«Ë&‰¯¹ò²k>÷¾®áß?“O.ÈëT‚œoÙqŸË€#®ÁƒˆZsÌÜS³+¹1â(vªåC,&B—4’ –WšgO[à£¡=-˜ö-µzV‹>˜eŸÑù­ş/Œ­	g6éKwo"”-¯`óâÜüjÍªB<ÉuWŸe=Ch—ÅQ
ÖB°ò£7É-•*İ•‡y®n5gF=xõîz†Šµ'8rSÚ{æp¹Í½¿DçÜÜ‡y¾;)‚KßK4P^’œÍÉcV°6@ãáZÇf¼è‰f…'Îu¡ –q^lLv½,s–¦A5İX’¨fxvÜ¸ÇWCx™Í8è`;hv|}Ì,œÍıĞpe/h¬œKK"“¦]T´Ê(¤Òp%í¹ÈS‰±x-ò s+‹ë¥.Q¡É‡<ïUûSXì ú¹1úHé…}‚à*ËßcüNï¥èÖvwÕ•¾L°%Wdõy`’\Wh<Jæ³ª™Ë‚=¼l²‰ëï­—´ç~_jšè“!aG!{Œë-ôÌ:Ÿå@ıdoØ?T9Q[J;sÔTNÙ$]Ù=rèM-É&xŒÈ%—·¢ç˜5Q»ùÔ¡hëY°ºlô\9YiMVÓŠáû¥³vôÕ³ÉL´šÎğDĞ!AJçly×“0îßöb’Ì¾|øBû·©œ\)ÇêIĞUÆ„Îßyˆ»¶‚t«ğêƒ>†à+‘ V±.Mœ–ĞQ
]á?–”‰®vHeZØ.´À'-(y#_‚Ë;ŒÖ ó¡J[ÿšÓÌs BËÀ~ù0ø'å½Œh–£©•xóø·mõÛÛêKûJóãŸ8ÈÃ°­£oÀxh-cQÌ˜6?¾î½S7á&ÊÛÁaàítCà48/a¤Z:qŒ!ÿ¿u…OöÂÎ`EùCÆHƒö8@<3ëTy8¨‹1*íŒ$] Ñ=0a`ààÇ6E¤×4’ÉÊîm„;ZÄıµÀ$ó]üŒ÷Î sÀBRœ-±C@ukbÊÂØOXª³Ø#S+_!üÕ_TI.øaà‘À/ëIÏZGáà—ùà]1ÍïVØ[L‡ûÎl”ÉÃ¸r`ğ«Ì@¨³vÈ}ÔËÃ¦OekÏÜ©Ö¸ñˆNğ¾¼Ò¨ø:G§ mÎ{š¦â>ævğ™ŸMMòF¹¥¡:ìa?\ƒÉ®x‰!İm‹òİ‹Vh1×™OR™Ä /ÑjÛôæ»xGŒLbœ¡ Íê˜†„¤qß”*{÷6áû°y§ÄH7¤ãJÉ?Ïí$G*¸ï‹ÔÛOCs‚vdÍm[ZÛÕºf¹p3\)”_
¶†-­;H»FDb³s6
+{I,ªÂ0€IËÒ«œCÎ‘\wF1ëØ0œ2ÿXJeò$º®8øó»œ÷9 *Ûàù£Á3ì3œ[í“Âªñ§.Î(ÇôµrBZ60sü£ˆÇvñ‰NÉ“ ”2W ò]óTsí1]Ô¸sÑ*ãÌ+ò„Í‰*ÕI Æ®xe`Ó5–ÙL‰£µ<¼slİ—F“,k¨íæß3?3ø4ªı©•û«dƒŞT%¥8O•pi´ù¤koÌ^A…*`1l™\¡æºÆ4[çsÎóÉêÌ±™@’ê™ğVÂ²Ç6H[ğMø·ì*ÀêÕ†Í®÷ÑßÜFgxÃóğˆ¡®]šf»÷Ìüég+
ü8Pİƒ-eÅL®Ù<í´ÓÊALCôAU†ºrôïe\%Â;ÅşÆ,oƒ@™ä«É"qõ®w8›Xõ£²k:ŸóWÎ‹Æİ//P£Hş‰méŞ¸Cÿi*Gg¨¨ª&şh0€íğ|ªÏÇOßN…îf¼ì®Nq¯g)[¾7®™>•&Z»Ùçko²:Û{5¦Yæš÷ğµXü‘3V¸,.2Ì‹rÜFGõ)Ñ.Ñs’Vªî™¸i—k…ìHø\Áp›¡ Š†–'Ìë[Ä×N |Ğï„Ì'øaÁ|í „\Iï"ù`3¥«(íøªbü('–”ë¤¡PXİ5ëJ›Ñ1F¹UVC‹˜~|ámùÂïÂô ‘]‹#pÊN¢Æ¼ÖÇ‰U¨“˜ù]>ç|éRüá‘Qƒè7úF‘KĞ’Ş’|Tá¶uæWöYÊÍƒŒõÆğø{ÍğBR¦Ğp%>Ë›åSrÆ”b§“ƒf¯#Ã‰…Y¬)pıvà
t‹‰0ş²„Õ‚Màbfµ›q%?ÕÅÔ+/Ñå7öÅÅ`nÌ4UtºbuZ˜R'”˜±2ãt@®W|Öpzô9Í¯|§Fgóø'OÀd}ğ]Ù3¿ƒ½…¹PYš§­ê+Ğ·sócöPì¹¸š4Q(¸®JŠQuIr!¬´êJ[&ê®I±¢1Ë×3Ì”ü8?ÓmVÄçŠ!Êà¥1œ€ÎÒ†W²>ßz1IÚ§	Úh½ÌB'²Û…—Ê_3Ñ@ÄpÓE\}âS~“{Jø9ŒŸ,…]z§“Û@ b¸½,Yİÿ.è¡ößÊÓ±jûbUÎßÁe­ıt
e0×ZS@ëº÷1\óÖÿ3LnÀ” ˜ñØûÁÔ4Ú “ÔVH©tD[V‹·Ö ğğÍ½¯–áò”Mïš”æØ‹û"+.ÔÆ ñ‡n#Æ‹ş}l‰J-HÜbé7
zµ6ÅT§×âæùF£l'Æ€O(ıüc^ãŠoÛ±ø&fQÆWV)š†­õŸ©eŒ¬ây³WéèÃkUì£³„ã³¶ò¦Ôe N‡ë±	ß0ÚñêÑ+‘Xş;=hğGÆ8÷Ë!I¨ñ÷{¬ˆÑk@üı=?~±.ç&¨s†t4ÀîD/şTT90|¢´ÉCÃĞæÔ™™>†µ™7}ƒ}ˆˆ–KĞSƒy¯ÚÇ‰Á#A"sïáõJ¥"Õ†ò*LK¡ùÛ´äÚäò[¡â_ï¹;J"];‰ò]’jıw£ğ.XòYLŒŸú½)Ã@Ï…bP€u¡".©B	iŒS» v4Ï…òN9‰.q.ÛÃ"¡@„t‹I?ÛéL ÿ8ËÎÜZ†ó_³h ƒïú÷¿Ğ ½uTı¼IJÖIjvš¾šç Z¹‰éEmsø²#D(+‡.·;ğĞQí£v±Ç‹;6Km&ˆÍŸ/Ú7qĞ×›eßxçÀoÚ†ç..@şÎôûiF&Êş½ì$¾»²FsÃæ#¬Xû{,n„ñä±vµ?M”„Ö~)µ¶ø„öò&ÿÖD
D¶Î;Ù¤¾äzÔÙßïÁ»ÑúÖúìÙÖ£E'åÎÇ'KĞG™>Àq¤­Ã½’[â¢z6FoåDOãA(¿¸¬#ğé°ˆŸ—A2x—œói‡'¼QK¯^€¤k×B»°®ÒÚ—gÜ(Lğk"|Ï‹s€®œœ‹½}bpıY¡ÊßªºÅovB-uåRsùG¹Ğ‡	x7fï?®ˆX?† :¦ÁYŞL¿ä£ßéÅqea1Ğ?(ù	TŒ~ÿ‘|ËK'Ÿ·ĞElGN.ô vÑ¥1<ŞÔŞË¥êİ8ud—ê–\ƒìì˜¦şŠ´+ZÕë Åü‰ñÎÔ@ÂrĞJü§?s¯ájÚÛı>Ñ‘‰š†£*(nn1ŸÙjè»¤dR{gè“Ÿ˜N¹ŠE9ùùöl}+û{
äí‹&äú ®ÎÛ…g ïD3#‹f2gcL·3)³+%_l©V­OG>„…ªÁúR;Úşºâ€!
°ª¸ Eçà©òW	Î¹Ç‰¿ˆdŞ/¨“ä´<;%Çq¼
M3®v,à˜ÉÑn :'‡ŞÊÿ@_ÚÑëıj Í ÷ír	UÀó°\ª^B«?"ş¿Şê7ÂëT-‡$ÙÈÊâ=Ğéª£‰í>ìáQ(nC¬ÛOOM‘I*T/·*øXÊ	“c†jÄ0°îªâÑÅàuJåO±gwñª[J÷ƒ8Fˆ×]_2¬şÃN ?ö¹B÷±÷Ø¶®¤ÕøÖJù{ÔÖ:’†Pwe0O–™şAîÒOb
úùÖ×šA;–=n,˜óYmÆx3ßaÓ%aï’Ùå£SÂœRp²A.2»İdŞó!§©İyIİØÛ‹»DHñûÁxÎ€ºäšŸ“áÇÁò“bwÊş±¼ÆwBAzúÕæğûô(ü³íäújâ(Ç»B\&jÅØ)J¸ˆ³Ï1”ÈÜÇ¡Q ×è]÷Ób«1ÿœ6:k×ÏCôÙıCz}	øæïbòÀ8¯¥ìsïÿå
õ÷Wtÿ°¼ çñ«!GµPˆ-{ç¬€è!IîuÔ`Ñ>‘(Ñ éFì8 2X,w¶ñR W¾y1#ßŠ†+Â±±±²-c‹nÖÕˆZ½¡°j
Jòõõ¡‚yi
pÙçù©¢;-vÃäÊ=Tz`bPÏ@„šfÿQ'sVCÖe¾kFÛ-·è‡ …ÙÂ“NL·¸¢IyQ|†á¬iqå‚ô.VKI@B“yª³Øb¶…VíĞ¾„$§vO˜|P{/ï<xìÇ-‹æRŞPımŸ1'jòƒ9ä<‘ŞÃñ=‘şœ:¡.HWÄ1Õö ø#Ö2 „
n2`øŒcSÎÑ™ªwóër¦Ó?ÙÅáÖ“¾°	Õìx®ÔA¸âëh4hEäD'œã„²ÍŸ¸¨îzı	ŠİÇ%µqDÂ5¶›cÖéÎZ?êœ"›Lo¯ -	ešğâ+2ñwÁdétcÉ5'ª°97†pz Ú>uÆR¦Ö¯?ıÕŞ~ÏŠ¿³¶áîàUÆÅˆ.¶8–¸Eêmë›³‹d%	]Æy’ÑlTI`øIÎÅÉówî°úú2@ï 
qõÇö8WŒ_rdªt|2…¶ñ¦Å	’°rCB/rû ó*º	·Œ` š,oğ¿®ğıön˜Ì}¿u WjY:v”›
”ğlÊA‹"µ•31ÛšáŠÃ\/‰À“8pZ^D¥	¢¹Mk-O²†oñA›qù1ˆP|©¿C¹!ìŸ¬H}/}
™pe>¬ä:c!ìÏ±·Ë½õRM2ª†½ĞìjŞRlåô,S`îR|ı_=íŞÊjñW})ª9à1'OeMPÔ² ºKV9?¦BÚ®¾ŒÌË8ã$•ÆÎ£¿~¿³ú:	9&ælT©SùûrÎ¦µøtPÌÄå‹YÌÄí§²¼ f‚Tˆ*r¨<Èd“(é5³ğºH‰Q@tL‹ãº©ÚuQ‡•o;°WxQ t‰üğ•ìW¸ËdÀ#j[Lšr­çí]“ß…0¸Z:T¢ÃTŒF Dò–ey–¬ÈŸÀ%v%K ¿C•İsòV2S‰«Å¢1ÇµÍğ]R¢Vg‚¼	„«–™xŠ½½Ô0z{Å/^ë8„×Ì¦…h-;pÊ®@Ù­©|ì€i–îªØå}¶~~RÈCë—ıQf[­C“Z@Î,4bÍŸd?ÄN*œËô1İÏ¨¶t’×ª!İz2¨Í@¹_qIbLZª¿òã>n/ìj}£0^—§UòõÔõû‘‰­P5mDT“¾¾–!ÕÇx—k±„º Å7qŞñu£Ù„¨ağTÁ²L°›J0QAëú©>:­òZí5qÌrİº§<¶ T&D«ItrJ1¼+”L¿O,ê.§¦Ç»0ê#»‹á Nêei·!11ß©«¯·³as¹m	Uu¯>Ş¬«¾øbÓöQ*Fÿ5òy_¶®<İw$°YN˜1nş[Ï°µNWÖkÂ­—Õæ5Ì˜Íj,Ü ¹ù,”w60Gï·YEĞ.¾jívüS·ˆ ï—TFç‘!!é-CLùXñGP
æüåË¾æ>Ş<ş‰E/÷[TJ˜·ßH2Ù’Ğòœ5Óúô`í7>¡Ã{¥@ü>ò»¾Oçé2døD®à…QRl5¥¢Ûık®ÀÆ±»¢k
gó“!ê‹l\+«Rh8ïCßıtJ…Û 	„ìÏÕqQôCb+ú8ÛE[à«¾o[çiŠÆrò6`…†‡V*Ïzè!ôh48ŸJçŠ°ŞùNŒ£à¡ÃX>“&­û¬*íòÜ¦G²Êì+pjD5úÖGQİù§ï%}I;,Iäëœ²Ë†„Ü6•ÒÛ­=cøfşoiZØ1ƒ"tÕçI„¼äVšÛô¦6¾&áQ~4­MãH‰å‘Fµ$0ix¶Å@kkDEêÈŒm®”l§º×ƒL·W?2.=4¾ÌşÙlU,ÑLº÷ÆIM!Ú|u{p½ƒ1{ˆ,È\dâBË¢=&Rá‡uwgìûH
ÆûnõxÂ…à¡Lt®ì¬P<»½í5ŸqBšÃƒP™Á6ıé
î6Rã dÿøï<»RJÙy¼™†¸p=ï°³XÌHcàÂÄI$Qe¶8”u}Ø|aóYC"!5™z-x q›	x…¾óÁm`4Ã2N¶!›t¬xªİ-û{	Ç<¿c“%c)ÊïU¡*ÕM!M$ÔéH€“œÔ«	ù–ô|lZñ±ÓWÛ_ƒŒ‘„)ŒÉgÍ‰ï^Hé¥n®ÃƒóøIš«Qc-Y¸gI”Ö3‚õîÿáóèÈ>ßÅ¹EĞDœÖ%VVùÔQLv?£Èı—4áoÆ°ü hó‰UtËKèÙ$Ê¢AÔ³ß=´bh`Qy²ªd/êWèxBÃq¡±981¥}àwĞ‚	¾C~§L^Ôâ®ì4Út¾¥¼º{äkvÿÈô1¹’¹ RJslï/Q¥¢òĞòcïƒù”‘Üí@UÊIZbİô’¨ûõƒ2Œû‡¿w$`“¬8„++syWëñëCµw•R-¯Aª‘ú«®_L@¤Sn\Òhly{®“¼ÍIÇ1õOšèà°o÷ró•ÒKx3 À¥ã ^Gÿ§¢¬’ŞêÃ~÷¤Ë¨^â\zrNM‚uH~ 	ÔzNî©TÖ–«ú8[‘¹fvò4´ ÅolxöºZ 2¹sz+ ^(òmÃìÿÿä76°	áïÿŞ’´SN2qT4Ä¨$ó+ioaƒÎü˜x›µ§6¾.#J~|¤/é¿NqÚÖüMD_×µlYñÚX2W÷e}ÅO°9N "øIâoöaŸæê×»¨ˆŠªª³ÔTÄ¸¨ŒÔò*ö×Ò w®_²ÆóşX'Iˆ°X­>âÖ=Sü!ıuØ¿µ0íÕ®f‘ìÜ—]“ÉRa73ôâÕ=ä£Uº{³ç_xÙâéaÇœ¶’fqå.=÷Š´¾8…ÀÙãûéô#™Ÿ2ÛoÅ–b0R˜¡³UeÉèsÏ¼ÌJf%”[Ş2å¨ıêÖiL)”‡Ì¾ËB˜ïKG§[’ÊfF 7ëM§EWÇ°¿C½äF¸:C”&Îûh-»s¸SÑ·
´÷?”ØNÊb<Ï|ªËA ®½òjÑe¥Ÿ™&#CJ:Ÿ$µ©0¤c¡¥<+P®ïšØLåèùK³+´rL¤Yhuœm$óëxÄ:iñrˆÆ>l¾?/¥æ^^õS ¬­QÈƒ®¨“u<gÏÕ¨šˆ¡á$g>+æ›
2®»î”ËŒ76SáÃj™¶Á­„&WÕÕWºÀ´0øÅår’<cøzÏ½èâ{¿hñ‘uÎ›$§JG:NBIİ{“[2ÿ üeè¿ëäİ³Í©‡„ópU®ÿã1/99ÅSiIÉuÑ¼KIÂ‘m{85RæbciğğóBÚBüzB…Àè¹LJ\,Om˜@PƒøŸØ5²Ë„\²r×»\Ó.+¥=[À#"[#ÚÓæ˜wZ#üÊKßS¹¼[r™ĞG*~3Â÷Ç?s²[l¹"IñÑÇ-èñ/¬ ²<;>ÈúŸİöAi„ö÷Óó¨hgœ3©-ØêßVz´Rÿq7åm½¤Hj„T÷,Â³$ÄÁKcLäß¢½jr¥˜«…Mğ?¶BÏ^¶ç2%FwŒÈoñC†—¿÷šüâİ»^VS©Ní0DÚQÆ^¶~N8åp¾»Œ>Íìñj3C8Z°­æLØíü‘:AŠhå”*­¥_ÕÒK4÷WeÃ»T?yƒäo!)´ôRğí9pÆ6Äæÿ·‰n~Ş0ÔòYÌq‹8{9,ƒV8³hö‰e·<Pcn‰áŞñƒè~¿¨>"»Ê)¬ /•=×@w~R•æÉö¤ü-H¥d}X’¸¼œ¥ÉCŠ«ƒ>OÍùú?¹â~éáĞoJ	³æëÄ é;¥`mz:tÒ'Æ¿óëhâK0ıâË4°€`^~ièä­»0¯ ÈyáiäÉHÑ=°Ö³VÚ/È;Ç'™vB”ĞüŞU	ó^:òèÕ¹ÆíÏÖ=QÓG¢ÜâaÖ_æÚÒë;.‡ç$7•aîfËÄ¢p¿†€O´ŒtbG#RBİ¬uİ¶:¸óAò~ššNÚ‡j’ÙÄ%½;è7B®ªÈË¤ÙÛ¯ÔpŞ<Î®»2ß¯é/ï×9›RcÿÔ†Ü=¯e)öZÍí¨3«p ˆO8Î»šÙïêl–ƒù§	¡ÀT¯D®Yß×WÑ‹Û¥.­uès°¢Œ?°1I™”ĞˆJA¡äÆ¨°ÊÍ7¿¯ŞˆC h ÏAK?'ÄL|¡†ƒ-Ï¡¸R|™Ø îîåJ=Ö,w‚üQD’Ğ&7oœY¡a¦A“‰–Gw¹±
âŸyû•İà*°!şKa¤.]kïnZ\6E)İv0½¨RÁ)<;.P–üà;Éø°uáªêp$ùÎcà€²Áß.LÂ"`£KÒµ‹
zôšYòır„g2Aî®uéF=’äñoy´ûÄkçYüŒ€£éí2ĞìE}8—ı4ş&mİî@÷‰ãÕtzû4­¢c«¬ÀŠ"uÉğI;KbŞáÿ_‰Q½ş¸‘6÷©rÎyãX4±Û;',Âp…@/J»¨ªğŠZáÍ¶®B¤ñfzÓPñùehsF¥LÖ4WÃùé¸‹`¦¾™„£Jû_ ;ùÜRÀÎô¾ç¯¸X_+åˆ’µ_êÀû’é”H&g]õ¸—
x§Œú¿¨İÎiƒŸW ¬ğD©ˆ)æ1†Ê”İ0~5ÛdÊ:bYdö¹3­¼İ¢8/ÏLT€)†B—ºoÂ?j*Æ°ö³‡ Ğ8¨tÊ£!äƒ×7Š.¤c±1ñ²¸\â/™;êÇ\TÒœEŒéˆªİ0BÓÖ¸¼ö\™‰*ƒötÁkç…î±’“{h¨™zyäemk©–áhKãT&ıuÕğP³Ôß‘íZÎ‰Û³3iÀT²$ãëØWˆ‡§/z´‚–˜¤n*yàtèîVÏÑ|x ¡°iZc­UØ4¶0¨;wŞ?(¢DA¬bæ"!SµÎ#—ë5@|vF.è/Åğ}ëtnÔèYœÓ˜³ä?Óx&Ò%í¹CèÚ/£(‚„ k»Gq¯MŞñå£€¸P„PÔx¯‡Ğ8ï¢ètÆ†‡ O±OÚ¡èÏ”•Ö7ğ^¤³Î&¯u›ÈG¨	ô|"HFÏ2jTY0ØxÛÆş^—ÊYœº8İñÂf”ËàİkQèG#ÒPZ¥dÎÁÛbãIñ‚ŸéÈì^pd›Ê;)®­ÜÍö “_GáHió_¡óS‹Föò1ßõãƒĞù!¬­èÔÕO †&?¼O…ÅYä„â$–Ï:£Mı–ª¹àÃÇ%N*ÁüÜçf•¨ªs-	*U;ek	!Ù%Jïñb7m²¯VbrØ†s:òÖey‰õğÆ ê—”€3wß‹`'7¤Arò¹Y“‘ü
qÚb%È†P­ò$‹òú–)Š'ûª!]…KÛËK5*küë-l771`ôU¨;ø—–ú
dÑ}†İ»®	mËù½.É_ŒìÌvw°+]“oQºî¶±Şó~«Â„Wµxß#`ó&^.C\	X’ÍÎßL†as4švÖh`3€	®2k\K¶wğ[Èù›:ˆıón£³|‘˜Ió/j½ÂJ­«òŠ¦FëNV–›o?D/=g¨àê5&óÊ”·ƒÆ9'Ò'ÕÁ[‘!qõ‹B	{ ¹¾|vgŸä Ygğ—ÒÃHmüÊÅÖ£Wbc—Ã7½x8ã£’%x2ó›—êrJVx6×9¬±Ù;Öš$…ôàM"Â‰îÍTUÄ\Z@‘Ü¹‹yO¨®ıv}z	dÌQTR½ó'ÄkJ
† ÎZO@ü¥) k hhÊ×ä8¸¤°şõ_+Ùmè”~ +ğp¶aÓõ îB%ºn‰†“òe¾àÒáıƒtvGüÙqUl÷xw”m›Q7K§#Ÿ„ñ>ñ«v“á¡§oÑî8Š© &óâŞáéç”ïJeIÕH¹Ü0zŠÎ ­e¨À²8@
TwÚZgî$.´ÆÔ}$A¹ğåóÔçĞ‘u{Ü¬íÅ§çI
…"xtğèLğBN[»…ÿšOÀøµP¬IoÅöğ(EX];³ˆ‹w
CŞ€è€9WM¾Œd9üBè\C—í
°›¾ÖåF¯´?ñÒ20àûÒ«—÷‚S®²“æXEÉZ
b³Ì4Í¹Jkt2³Cİ­ñSqUšŞ1Yé'”ÆšñŒwÇr–“èŠ¶~+OLÒäWúâB÷­b#mö½ğó.5—'‡BšÚıÉ.Jæ„ÁÉ¢l¨i %ÁiØÛ½ß=ô6 >L…+±Æ*¬KĞ{û	ÿÔ<¬æÀÅk7‡?Ñ…Ñ‡¥–~ñ}‘ó"æ¼H¿¾ãÌ”İš„¤Àñ*xƒ¼LoğÍ™şpFæ`êê¤Õî»ŞÉ:@ís'um2«{»T”ØÛSì“w-¦f’aØöÇlªQ¬`Šùì—=ª Š]üƒà6Ùÿ·–OÙ¥×„H€¹n-6˜-XVViŸ9—fİÒ×•°ÃÒ±–_‡Ú<Š¼A¯uİl&áÌ{fï–‰–˜a¾(‰ÑIaå[ø]å@ÑAYÑ
î4ëx6w'ğ·ûî¢”—ĞÔ®ıYC“9‚¨\Ç ó2ìY¦«v±ßÈVxÁ›¤qE›2Í°!kó@¤kÑ$%2×¦[àw¼Û¯a”‰¾%òŞÚËĞ5°˜¸L©µ«±=Rv°ÙKxu@3+ärğ¿‚™çdÛs)ññ9=üZWüÄ¼^sm³¶ç¾ÿŠøÜ¿ÆYUwK8lgÑ))Éµ¸KåXéáp™§©Şï¦aÏ®~ëøˆ½ı–ÃvAB‰Ìx6K¬r´¨&L:µ¹¸•Â	9,<Ê–KŸD
G]¡Ö;[s°”9G©şâ‹6.ˆQzä¨®Õ¹KîöÀ”%Ê‹±OÕ>Ş ú¢‘«t'´Rñ•AÁé|#¯]ÈBf(Ü÷¦+ŠücwÌ°û(lòÎ²dÅjüG¦šJÇ¶µƒBÖt’Šñ~í »Úeöé`è8Z´/ønˆñ©UëÅ(4‡À’/Ä"´V|/åÛì‰âäyİå-Ğï‘ÌøØĞE ”zöUzÈ¯ïÓ•£M•«‹G¶'éÑµô,$¥†%U$ô=ñjPGúšµø.úKªólW•xy„~äéCÏæ7bSNÍ1ÌÁc,aZ9Fòyƒ<ú3öpŸ“bVço¹©İæ©*®ák¸ŞÏCÄUç1ş
7g‹®qÆ@$úÛ‘. É€^ïuoEUhâèKÚ}SX­“\siqÌõõD§DÃ2ÒÙq¼Q!O	ÕºşâÊµÂÜ#Fk¿Cv÷Í¯T˜.AZ8Ä,}?ÎˆÂÂ¡´ U¾¦xË™!«¿Eª£ÙG $mjG2§–ÁU¼z›éõTI‡_ì½‚˜ŠŸœÄN
Î~ªˆ)Z„´¥33/°×ò¶“ƒ'…FigşÆl„EÙùm˜ÜvÑ=ı^«Û°4©
f¯ÂùÔ„ %%£‘TìtxÙ‹Y!ò¡ü€ôƒïv0¤º€g¦Ä¶‰ãôµë¶û‘ ù+ŒÕ1 6Ø*ßy¿‹Å‚Ô&áÂÿ½0¸ı¹D*Œ±&ì/ÀfYÚ¡—9Æ‘(C×hj¹ß¸ğ®m@ée_õ,2Ø§Ì9 ½l*IgÁ•’ÎáÁ¾€ÄõuáÖ,{ÈĞco—¦Ÿy=”Kå?ø©~Ël\Z¼Ó˜d}0›[ÃÇŠè9N¥ºÂ;ÉŠÔê¬s€‚Ç¬‹ŸzàXéÄœŞò¦x8µÌFéO#İ¢v+ÎÔe&ãŸsşÂcm¶Ãi´¡qşÔ@¬.{İkÒã¶„,Owë´â¨ş!ÕÄy^¬>t‡WzX°ïtHpQÌîdã¡q§Ÿ[•İãnÕ9§·\ŠJ*Ûji.åááqe¶âËÅBt¯{>f\¼BZÄåf»æ-‹ü§íå§én$¦â¥ ’¶Ùë}™	È5œÅu,$›§*scSìâK?°'OD¬¹şTgÊ~¸éŠ>ıÏWÉı°fß ¢´ı[æXoíÙB…ƒ6,ÙÊÀ§tÕ õgjmÿe¯¡Ê˜A¹:±şÁ|­@am€hß.âÊ5ÓnH0í»]ä³;íB4IEŒ/:¨”·t”|`,Znìº÷æ]VY¦ú'ùšUU±IƒGƒù(t®BÉ¾Ø¤Ï2¨N Ú˜Ö‹|™S¨€-YÛé<ü ”·_ˆ==Ëé¤«ç­ G‹v¡Ù€øş¦q{,X“úÎ“Øé–MöbZäa'IŞ¯ãÓ °Ës(ÚX´Í•ªuØQš2Ï˜´6İH.tœ>4µ~0‹—Ä£18‘Ä‡Êó¨ZB9K¦d‘­ÚüsÎğz'RB”Ëê*<ÃÁr8²ç
|5ç4`' »ºa<¿ö ’œÅt¾C9ÏØn]×ÓğPÀ²¬S 'z–›ï²7îÔÔés
‹$iN%Ü…ŞøâOÈ³EÂÁœ€@à´ÓÇh&¿£vòÓµ.Ñ/ğ…^ş›ÍêpU…šõ¼“s¢’^DœúĞİù9õˆÌ•Vî•û]×ğk:P³AäcÆ”[}Æ©Á÷î(lGlŠf¦øÒ«­ŞbgQsªÖ\a¤Q%¬ËßÏğ€óäÂv¦5~„µbşæ€ €Zò¤Zs5¹È¸~c™îÅ7³¬·ë“FMıíš”¥¹Æ—ÇÙ´Â“?Y9ïx½´a+|BC4ú‡ Óûsø¡©PòÚGOT—Hz­B½–•$dúöpµï°W*Ğ$ß‡gQB~65|Î‚Ï®=í“RóüËüëÏì[7ÕW›·ğ¯*¢‘V-då¦wÒdV/¿C5ÑL¶ ×@2ls"æ\Ê²ôêôĞp[¼ëïäªÄíÓ”}Àà\™ãXsIá[Ü¾¢™²zú@G¯ô¼??™8|¿Ø*q“ÙN-ÄÂ6Q³1_÷3tCQÀ8Kr{Ö;D§9—±Ü½™[Óò»®40¢¥ØxHMALqO×£^ŞÕmƒ’EMjê°}ñ@]ÓÂv¾ :Ú^²˜{ªÂÿr˜yN08p¼xDëµ^üÓİ0nú¡ÅŠâ3éÅÊ;áÄÖ¡—+Ç…
Ÿzl¯*"‡	zœ¶¸[C!’ş™-¦ ¦øÖş¯ü|¹İœ•!–®ïË“j=¢gL2?bŞ òß#(Í¹éµõßn NÄ4U.Úå"ÑQğÓdÍ»ÙSƒ‘q¶OBâ@®zŞ˜øÀ&¤»"#ÈT”×5á÷4Ôç£ÂOû'±–TÛÈ ÁÕ]ñ™¨á@©"NFT URÛî.5>©×ï’‡Ï5Ã£z„ WÌK×mÂI*qƒU|âlK¾Ng‹ë8íjç¥º÷óùjğ)`»ë>¢âˆñŠJ$Q¨$ßRÌ»Ò(Weµ9j1¦@C# Iâä›nKèB™áï¯mLÃà:Gh•É„{ÌşŠøsgÎÏ&Nc Pé..&Gxˆx¿Q–~íÎz[‘›ğwdRõúy+*ôÀ|jFR¢…{{¹Õª96«ënú>@y)İÍìÂğñC©Şë{’oTÆ|}=s5kÄ¡uˆõ¨ÎS™òQp¡åÕëŸ¼—jÚ’]÷GÅĞ|NÖ••Kzé	…tšD}NìÓáœ€ãI±'¤Kå‚…©=Ğè}w÷éûùŞx*ä\.W-Jà’rY,çï‡æÂ|øQëÙ)®åu ¬f!b’ò¡×BL·(Ğ%Ë*jè¹W­œag/Õ2Ö'/ÃÁåcÄ±8³2©šÚ“'ÙÕÖ¤\ENêÂ|¶…äÅû[¿¾
‹È@Ù}–ıÄd†‹haÉi3ØÚö@EÇïÅ?Ü*&w<[>µ=-ÃVğ_ -ô·T¬Å·¥n€xtšAª‚‚Î ê#i–»
ïì$ [{,µçºáp¢NÕãéh S'µ<˜ní–å¢ Û ë;¡™qçİ{a9ò‚”Às†	©¥Ò9öâÉ­Uj,wTé´ÁÃZµ ,.¢únŒgZ¨ÿ­qUJıßYµ(·ß¼ºiI­›¹Ì;¢é]1ÛÍÙZ°˜R¯Ö[Vè®¸)t{†é5&¤”¶Á¨t?jYÿxä€q´ç	Sz2$Ï¾æyèî8FŠT¥Âp†; Vä÷Îèt@u©ÙÿO5©vx–­}Ş„E€zØO®ÍÊ2änî«öJdŒ`ÖF)G™fQÂâVùê”µ5~wócíöÈ°¶x0áçà_ªŠî¡mèÔ\4G9»â•$no“¡¸Úh¨KÌŸBµšIs˜.^–\
º,l™M„‚ç)èE¶º±­biwp®Èy~Tmß7yñØØëÏPÂ’û×_6mãò°	åV%D–SG%ÎÉ×ºø-X$#Ÿœ€P}®Okäé†±õ&IW>¢+Äú(>›ÌÁÃU¶ÙñYsôØ÷Â<ı4×>Kxğ< ó‡{uw‹ešñ†@Ï¬l1|iA(,ÓI¥okç>
¡Ó`£ù–šxóô¯Ñàì¯®FpÀy¿xvN[f×}H‰‹±ËÏAZ
±ŸˆCY#–‚¥×ÿÂHf:çÖV†ŞğOj¥Im\¿ñH|Ã¤Ğzß§]6¾ĞbÎ\«‚Ou€è ?©Ñaòõg¢Òf&é­F¯[¸…éË¶;äŸme2ˆÊa2zDÊÔ-Oç¯uçÚ¢XÜ¬êš¥JÙ»@œşÄD¢†ç¸Gï,#c£i(=–_şfMfázZÃÎ,£Ø¸ñª£ÊC¬J?M©jmA¹ÑœuAØ<„Şã{4´ğyõbå3<¡!ÓVx£D-MÛ6Ø¼Pƒ€Fs04¹Ì	o•
“pf¢Ìïjß+I²úQº¹ªpã<@Uí)ì·£N]¯¯)Xaë<´ğ³WU›Çë
¥9ğÆªåtÚN“òn~³3T¶ÍèÛ}×R«w#øõŞB2:²?¡¾™s§•ÉYKú¬K‘ËåL,«uÿŠ_Œv2Z—'Š4‡\:0FR­º
¦…îYÍå÷#›õ„bZ`O – Gÿì\Õ>aˆ
\RĞo6XÎó—óœÑ µ:[£<œS5M qúgC4vş„RÉ~Š}/ûïrj†&¨ûÅî:<½¾Éég–hàj¾¿Ù&h.öê±¦~qXjßù·‹n´ïQe×¢&›…KWaŒCíœ4•)ÕiÂÈF+[á§;+b“o“ dŞ¡t€Vì´Î¸øóC¸ûÓ‚Ìå™<¯Î±£àO²4¨^ÁIsv²üM~&u3K|şSKœY!0q¹P.ô§– ä§-s‰´Ç 6wmÕ¢»ÏË^T!#9À2ı Œ€T}½yÇ†cH&ˆk=^LÇöNpyTºáf}`{¸IÃQ}Ÿÿ#î²Nèín—éİJ()EGãFX€k”è®Y˜8å~‚GLËöŸ1dzo^FÎ'ËÌOJöJ)IÀãs¨~ ÏIod^ôÖÓÀL­ãbšw)¬‚ÈöO‰C8¾µ¤3º2†lC‡è¶Ê¯r«&ĞGÊ„V¹gÏzÚÿ¼ú3"–Îó)»T=wMT’íqı|GJÚÉû³W›Ã¦PŸ>K{Á+©hñ¢´$ÙAÄ1¢}Ğ9wÕ ú/Úb@¼–8®e]ÿ²úJã(Ÿãøş/s†¡y;ÖpY¸­3Ôpª8?#¤r¨#ï1»¥òK†•5V–çš³£çdíPˆ=Gÿ[yu-…«û]Gç[Õe”›1e¯1ÏkÕLRûk¹q¢Å•ĞñÚíRJØ çSh=ÜÖÄõG´•,6…æ Ÿ‡>ó&e¿¹6±Š°è×İZDnŸ÷µüóÁ‰ ö‹3öU¼Æ9ƒC¶%\LÊ GP÷v#„ö}:»­÷Áë¨)æœk„í›k‹şg/äg(J‚BêF‹¤ fx’0ñWüŸ¡ŠK‚VÔHD‚A/È…nQÖ
m±$sp%<a sC|cŒëÜ€sè^#€É§¸]ÆÎ/™£×jPTûãšÊ›=ù?KWÿA?}8<PÙ˜şvïŞ–6Ÿı×ÔHÂ]—ğşAÕ{­_Ágl˜EÄA™@a.Lø÷¼?€
7pÕçÄ a`¯÷„Î™ÿ§.B¬Ç‘g¸hÃWÄ#lÕÎJŠ \‚™¿”Ì¿É¼¢zÚ¨-$CSëTÇ¶ç¨hàp¾™‚ë¸,“ş¬Ë¿¢Rí»X¦k¯_c:±ãZá`¯¡ÇğÍAhŞà$ÅÖfÏÅ;\'XËôL¦7?Bq!åáíMÿLŞC¥nÊ7T¹J/Ş²“|¼êTtÿßù qÍ˜Qó¬¥Î5T—si´>³ƒú<—iy&°jóff%ªœ¤tSJà¯ÆøóÙG=Ä0.­Ú×ÍÂMŞ„„{¨¤İ‘ æ“X•kÙSœu¶Ë{’â©lhäŞğzî¨K¤‰]P€M,ÖoÒ_VóëEA#5åf$ÃĞ²±^áî«m£;3MDìwmÅgÚ’Éš™gA·¼ªãÇ`È$ÙJıŞ:‘i¼ÕŸ
R\5ûf¡'Mºä±ƒüczN?y$ÇÊ;S\aA˜Ôqä!h,¿ùDS)”mj«a‚ÿwè·2•b ¶KÙ:X2ğ¥ñ{FY4¦sªÀ÷¿Œ$@ê?Ôæ¡B^ÿeŠq§S²“—&’ü×së¹XAíÓ®Šèl ¡ÍÒfâš+´3¢ˆÅ"1-Ê)*J¬äu¸5ºÍ×<ïcÔÍ-ü¶33\ù—¸v‰¹rÃ"´‡†ïïthKQÌÊËãéYPn²º’½¸9>s;|‚!Üƒû^MÍ-Ç»Êb}L'ò€w/y!H‚Ä:‹­ÕZÙcƒx¶dıÔ±¹È'íï»«³ºÂOl
¹¦‡ãó*”nKõ¾X,jë{éCè‚‘Ÿ«³¦Üh¾3/›zRíb;½JØö &uCâPìÌõ¢³v¥0¦ú¯¢ºª|f¿C£¬Ïû
F,Ë>å÷¯ÛpækĞª¡Mó¯3Aˆ?z(h¶O•ë2Î=ÃtqÆ_tÔeºû¨>$‚p»*Óã,!Y]Ìá˜Z(˜„¢˜ö²¾M³±‘ÃŞ„0–j‘Ã[ßDşÕ¤_&3¶=èªo©Ğ:ˆ**Üa{¿Ã›ÍU%¤Æœtú/R–:´´¨à$_=Hòßï;ı—’ØÃùÒí¾ªGÙ¤ıÁí…€åéPÍUÖ=jğ|±á’fA•şX­)€ïCöJGAdB¢Êtš¸/i—a¶H«€›Ş”»ÙDÏùDù6lvÃ@ğRƒ=»7î©«ğSj'‘·Ws9P¢¸-å|3R'6Ë3Ö–JOD8 ’í-ÛM¼ºdöyw{åºL€–E<ûİ«p »ª_VÂN¾çrØ‚qW!Æ–o‡(Z¶RÒIìÖî‡™w–x1ÃıŸƒ

d¬:Ül³°ˆØol¢†xŒbı}
`¹áÑ?Opaè—á}şB4%Ú€0¾©7z¹»*Y\©°,fMÌ¿,lĞCËûh Ùrø™¤—Cg¦Ù«ïÂ«o^2°`#°RÅ`Õø­ÁxVãË•"^{EÊ7µ4–=IJ¨2‡ØkÛ:¬y‰´òº“Ìß•ş}Î¼Êµò9$pº@Ì¸j{0Õ—âÖr¢ğúùkZ®‰.|¢•×BeÍùuîê…PÓotI”2ñGv+ğephRâ|–Âız ÄD¾Ún,;tÅOB=u1]ZÿÚbü¹'‘ôKÔâêd¹~ş·ì•~áØLÙjë'7c‡¸Û_¶Ú:‘/u’ñò²4“!L#©J²­à¤~ÅÙÄœYcÖuˆ! x¯ÁÜîOÖçÊö’¢Ê-nîrÉ“ô×C»¾…‰†?µŠ¿Â­[]=ù°Q§²U=‹‘˜˜A!×<Ãÿ)˜s˜&”,>¿éDáP‰IIÒ,bÂf1‹OaE,ÚõŠLE
”œ’u¢óÑì»Sœ.<·çZÖMœ¾pg­¢&v&.‹¬n|ëL5)>GT'¬ûÊ¬°æŒ´²ÁğÕÙkaúf¹'–Ïü‡•‡şU‘I›&,W×õ·§ú)M¯¹4-û|òçˆf$Ûši_O7‰ãÎÎÏ-Õepl(ã+È~/¡E²
È!Ô°Ú$“CNÛ£W]KålŞïŸ£Q “Gû‹·´fUc’|¤û1nH—¼[n‚nk`×ğÆB»W~ãY}ôFÑQ³(0äß‚æƒPIÃÄZ*Ä€’ú=VMJHı'ÊK(èïHW»Í#£ó&¢ñM8dR]t…ü›08¸¤	[ol”fC—êªÈÖã©-´úú²±j"/ûR-Ñl}ëø¸üY iÙ&%ıÂª²Ç\ş†¿ƒ0[ÿãÇ1T?7jy8€˜([´•g¡:m²µ•Uy×¯sß ì×gÒÌ,ı"„8@ã	âÏÿ¡>>—szé˜4´\<…oŞs¡äÇˆ§‡÷x"wW0­æNâ+ak>czŞº×Ö|L“%6"îœ>µİpÈK.îğ'áÌD*É¿Cm$.k;b1U»¡©.˜_u	y‡³Ú¾ÿÚÃ`5)ú`¤ãÉÄ¿Ê[Y¢eT¥?ÁM ôµd”³É;l?È—
PÑK`õ†
d³qyæüÒÈìd  ‰<°`çaÓö_ìâ7Ö!*äpæZY$ .Î.Ô“iŠÀ¥¼À9eØğWnqàØ@•w”Df~J$ykÜ?C3¢2 ñ
Œq)_ìü¿Şw[4Ú¢(Ü¢[ïTªU¾Øû¦\)º8¯<’kˆIéÊ¬V€À8&ºÉ9èy`À>lId?œTvÎzùøƒP¾#á$Ò—ÊÙùù”ãmÔøU¡º_L|(kÁ]ÁÿÄTh4nÚEş†©=Ô>#P•Ü»Ê©±x¹ÛÆu^¤£bÈ…XÒÄİu2’{OOÁX‘H¼Ü`˜@Õ¯ê!W­5ò\ÓÅßJO©ï´ç•Üïşéå×-¶QŞ¨®I=|¬IUscµªpX‡¸n	ıÛ¤ÈY-†İà¼Æ¯QNº˜ß"ÚŠ®"’9Z§ê¥rKÉ8Q”Çòi²XaNqÊ°' BÂ8ŞN6_átä"l‡»B»Â33r´vÒš–4=*Cş¨UÀ6ƒ“ˆg§ãòrÑob¡´«sQ¼U^²ˆÎŠ¹\póB„=dËÖÑÅ¶@ääCÙ!bìótÚ«ÑeÑ4dğĞ†£‹µ©,ñ·N§T#ÅÉ¨©,vpz*İ­xÕèYccñDgDıLõ _	ó3õYhL	óˆ} 9Œ
K»a°¸>«>äú:C ‰ĞgüºZ+?âéX»FÒ{9&í ™2eœUø±«HÏëVb;†j¹€Sl|[ùİX¦§Ã‡µËŒ`úÚQâê3YÈÔ´j„;¹ñ¾è[j_mCWüÇ8t #”éß.ìÛ¸YDâºÈ„q3UĞmm´Ã—N¯Rçã¡ª8ó§Â°@ÆUDß;E½Ğjñ„œŒ©0\+ŒÊN„èšê"€c[ï­QÕñåŞ¹ÜÎÚgá.¸Ûù0—¬o&õYÈT²—º]x¸#õ:Ÿ)U³X™!C¢²^æÎ’ê“ÇxŸ¿d•Ì‰!İ¦mËáSb}¬Mò#¶´v¤òŸ$%36ŒR¼ xºĞ¡k"İŞ²â8chhå¦ú’>ZB>ÀÓ‰{¢Zğ£êö?4_Xô8i“Gµ\èæ!=Ë†ÕÚ••D`÷Y^*†T/63Ö¼µ4¾&~ˆ—ÖµÙxŞÏçà±ëîêP9zûË‰'Ş>q"‹MøÕ/¤u˜à¸HiØæ£DÁ'÷èš½£†ohJR†,v6{‹ú†°²ÿ!yÜjQ.ê·b‚ğ@ kü²ğ(‡—ÔNÿğà
	µö€-Öë‡Dú,ÂeÛõX¼Â–7”3]•bõG#c®ıŠ ¢¯cªÖ
éğ¶ßû[›ˆŠtQÕz~7Ã™+^­…6pÃ1,3¤¾è0ŸØF[°f—â÷û¢C÷®©‰Ş¾aŞÓ
š’jìH[kfp²\Cá?¤šAºD	­úš¼»&ˆ¨¡ãC}BÈO1~š½‚½±ÜˆÊ,¶ZîAÅ¢Ïi(d}ù•¹5G…íj¦z>x¼£\íõÇ…a&õÑk
èv“ï×=AóA¶+0^QQüíK¥çOã¡­IıÉg%ã­d26!§É„;
2)@Õ	êÔæZp…³±ø;S)
)¯¹÷·?„Kp­?”…®w ¶:ã zíLtšØÍjPJƒcoã¾yPè$…±vôt9˜š{5Amä#Å¾`cšÕËtc4Ÿ"Û©cw¸.{·P
àƒFvbK¯%Bäæ.î¶Ø¦ûˆMn‹ş×½ïp]Afçtû¸gâ«W™°»5]ÌèŒ5Ájÿ¶Ÿà¿ôèQífQ8Oã×+5ƒ3#Ï£—db¥¼_½x¨S’‚š±OÜµ‘°w<>0+Å{œ™]8Ñwİ’Ö®õbÇòò¯' º—»gdŞ#=WÔmùå'ÕĞHo`ZqÀŸa¼ıÛ6a)¿l$®HÂn`µ"YÁíp¯ÄÑıíîŸm½rˆèY%zK÷eëôŸ÷rAÂmUû@ààŒ[D¡~,.ÄİŠi‰H*	gBo.A9ë¡Pu±xË_MGFíİ(¾ÛC‚cqP½hT¿2âyB2KNjps´-D:ùqİÒÛ7ğF§FÖ½À¹
Y¹¶eÕ‹„Wº”éŞHŒ´."^½¦ »uÒ~Æ;j\B¡—XÀù_,¤Š:ËÃMn5æ’¾^y”8ÂOß;šÈ®²H§¹·Ó8›ÿ	ì°Ù¢S­7Ñ[@?Ó£Ñ ]-PxBï£s6æCW¤u©ùÜÇ;ù¶†Š~¼*xÑáÊ28j…ÅÙ7”vŒ lQ`&2W,ñß9+š¢,®	!½·“şJ¿§/|½BÑ(€%rë/NÔ¦rÆœô„/Øèä>/¢Ñq§îKiÈÌuàö;«èx_( ªåqx¹"Á•»ÇZ)}QcŞ|j€Í‰Z~– ŸìÄdŞ2Œ]À¨‚a<æâ#ü-ÅÏuÎ; Šó$êÓ*}6y‡¬IÚn·‚÷×Bo“”);ºï.4oÄ¦£Z¼5õğÛŸö«¶ÁEÓuz+ú‹É}“b$ÖéaÖòZ­ŞD(ãó}ºúFŒ)ãQj¼JV
ñOuÊMŒeÒd¸TXÁ;€ËJÔ’5{Ñüèa„¤ó('?Åpâ©R­Ä‹¡{GjäÏ¥„…ã‹¿¾À¶sóùÊÙ`:àFş?T]9Ï8dmÒÕ½UÖl­ÇŠëÀ¤R#ÈØƒK”•Ò6 ø¿8£òh±Eå,PŸ¢ï²OÍ<æ(Yw‹Ä9£lã½Â…©8v7¥ó~¹gğ‹ÆDÃ>©@é ¢mğØ‹Õb¤óšpò’}Î-(‡öõ ¶‡7Úa"åÊóæ«Ş3/ÏšÖ„lœKŸ§ ‡ƒQ«¸‚w<O©wÖwdK\ù(N†Ñ™2/l2,Ìß~ï1Ük†xîh0UQßãåÆ+jT=,EI+èŒ”¤xç¦®u±ÍãÕ×5	è\•şòu?rÿLjÁ¸ñ)eĞ2yâĞbénc«WÑäßş|©ÓàE:ïü½:÷}òV•~(‚¢·“æ`š+hşPŸaÁÕƒ–8Õ/ŒøJĞB‘›G˜fÈ¦ƒ¶oº‡.<&33.FiRİ¨tâ!QŠ˜”l»^‰£tQ°LÈÍ¦à>d,Ó"Ë­?riå|`üú}ÃÒ€ÊÄào[£……c·áéÔe²³$÷Å<:^Cb
ÏsW¶2ôcj×”SÍÎ.ÿ§qXhHì4ê>>âÜõÂ”‰£Ü×¾J. ‡Å.)6Ôk¯iK¼‰¾æ¢Ä\@¸‹óâºòO;RÖš=ì“pñ9I¶T&Yñ/õN€]:n°Æ¹	æŒi8›?ïˆÜœld4ï˜‡ôr”Ò5Í©Ït’z›L‘éâ¸ŞSçEˆQZéê¸~„5™.Œ4WÛ%ÒcF8Xn8çæKšÖSTN¦ìK{áí®~i!óH¯²8#cÂ§ÇÍ«Ü:Š©â2³xY]ì<ÁÌ™|/Áif	vÌÇş&Æ/à>ëMë—s—1[¦cŠsÃÚÚa/Ñd¡OWpN˜•k…ŞÂ×bó‘”^œŒIÏC'¡=Ğ<Y¹° ä<C-:~éwÏª…xGZĞ‚¢¤"MşOş˜ÒÂkó$³Cã‹)‹»Òµ§4.û€ş¢8ok¿;°€á6Æî³X%•Q Q«Ï[s{pOp²‚ô T4ˆºu{üäJŞùÏ³¡#Ï±£öqH¾á`sÍ'AÜ(ëJìÎôt§ÿE¾ö¿Mw!V‹Ğš³´&¾¢prÛO™ö¼€”ƒFßÆ8Š×+€–ã•Tçg÷Õ…=q:şÎ|,ÖÒTÜ-@˜L>:]‡ƒxƒî{¦84šOäWbe°Ô¹r2ó~ƒdüpï[ MøNç°`µ}ÏÊú×²*É–¿N©»“–? ørW­wZ vÜOc÷ÑˆÛÊµHK!‡›¾¦¸ÿäONZ·‘Ÿ™µ}‰¸‹U1³w;±ãX(hÓ±+#¶#Z€±€¤ûİlã>@z)iSğ	~ãœ¸9ß<êädrs.ODSFD:àÓ®ÉšÅ·§n ¼:î6D¸¹–>
š,5ÕöÌhAÂfãÎ,~U”Z¼]g÷L“!.<˜Ï¡`9Je–›^c¹€^†íÛ¢rî.¤D *OH|j¡úÂiçÙ‘qµ¿5aøı]!†­‘ß‘â$a™ñ{"5—ÿÚë,‚Ü?“'Ÿ5¼„6à®Æ"êŞÇøîé`<æ-IèÇ½€ÊAŞ—šŸh[xÊ¼>²‘ßlí§mü<>fäyY°‡ŸjRÿ?T¦¸ü«éê8TJ”J®İ|­“é‘Eª	©¦\i¿OÍ}_¶F;›Ğ+·ü¦üuLŸÏ9 YõŸÆ»R¼AĞ´¢íéñRÏ‘r¨áPØ]}¼Ûd)µıw¬Û£Ùç?7&‰¡:)il³ÈÚy	¡×;«äbÑU~ /¼ê‰LpöÕRcÇqK²/Œ8ıı–ÛæÌ+\½[Õ¼^—¬ß5‰¼Á»öÏ`eŒÉ]…øsdg÷·™ªUA°Lü[\†Y…3µş•@gù¡šÙIÃ¢qzõ¸D…2•´ï!<QŒX¥Œ{‘à8I–f¹İËÃ2&¡ËòbO}/2f(W/[aM9OTÇ”8öJÊSsğ
7o<jŞ¬Su2‚‹È€AÍå˜àm#£«~aºeØ½W‘Ÿù {q,¤x«éÈ%#GÎL ¯õ?mîd% L”lâåäÓSø”ÑwØoĞ&È·1Õ[>Ä7÷í]ÕÜËÒ@æÛ`ÙNsÉ2Qô‚ÍØ1A†òÜÇ'bR”ûdÄ»øÚwŒÛRÿQ!¦ü¦ì¼å°x÷„šŸ1:;&’ %zÿËR(ië_Cb×â«Ó’Qün­t]}„R£§I^F¼Ş‘Öë­­ó°zv##Y
jF
R|îŸÙ²ô)çV]äa.láW½ü`Õ¶âÁ„Ë‚ßïLãPû4†¦İ	¿¼pßA3»\ıÔLë‘Ñìlg<ğÊ{Õ®\0å/‚NÇîv‹³Ç}š[¾XùÈ‰TÍùäù?ù¨@å|<Jßƒ’…Ršháì~½%ÓuŒ…ü3öwÜ‡>êtÓ9Û¯R/«ƒ5Ïóä=G£&~üÒ„ò^Y7æf3i—$W‘ö+Ö£ö¶Ôg¿š®Å«³ûA Mô¾¦}sHğëÓ!¡IN/æc%ÌìÀjôú+YÊ«4FáØSƒ
«7˜¹Cª¿\Ræ\h^Oü'‰±/ÙºíÊ~OQìºÕœÒwÔ {!ø¯»'pß].7˜…/óƒÜL„ÛÀë¦_ÕÒ7˜Ê®áÛ~ÁšëVÀ•Ô'ºa1kó"hwp™æ¼skÒÿBï°}]…,h¦Š®ÎÕÛˆdRŸ¹#˜w™®!²oH?û˜@K,™äÀµˆæbPxˆ~°Mé½‰nné_uƒÅ,3Jé¦ç29²êlÿzù5kì0-ª¹.Šz8˜ê.ú±ƒZ)PÕCš(ìİµ=Á/òÇ §'²Kİ¸´jíÈÿ\‘'1›÷ÿó×YÆŒ—E¡-ò då>iC_Æ1¥©¯onÕÙŞÁ¼òõ¼j·íÙ¼m€zÈŠ8ÕÂï(=¾‡Ü¡šØåìuh.ÈÍŒ7õôv'PĞ¦·bÑ»|—7Yâƒ²¸~YV4Yk~›tŸ÷qjp
„Õ<…h¬¾ñbW‹Ô¤À+¥«5Vdpz½è,R´?ÛÍ²âuª…ñµÊ*AÖcèxz»ÚÙ­c”'œÅTf.åCA¾+ù©g×Ê´á“•÷
W8™)ıı˜çâhµ/ªx¢8ìˆ±‘cÄâ¼ñ‰L^«€1½ø
V¡Åº¸Æ½æŠæ lV†£[	Ö„&r-ß>µŠ ÕÑn|÷W.š
bD²^}Qâ<BËğ½\Ó…¡¬ÆÎš0çHkùQXúwkí·ŒŒç¿äÈ"ıáTÕiZStÉ¢%€)šy’nó¹CAH²O<†@Yº	ÇSÙ• Ód±†rŒ‹âFÜ<ùvs¤kÃ”†*uç¾áúÈs²Ö \la§F1”v¸<èÚ|^)oö'!Ùı¼Í]ON·x¬Vj(ã¿ÖÎÅö¨Û~ÂÊıÊK(O6#R ¿·™PÅ™ÉÊªöe¶’…Pt^–æÿ"T|Söoeÿ¼óäü5ÀfiğçÂä•Y^~z÷¸íàºVOIŸÔÛ;nÅrô%„®×Oƒ€P÷9¹®–İ‡™N->¯:Ş¹Šİ5©ñ–˜GÆË(HÙ1a65s ®3¢qvŞ÷ªqòñ˜HSÚ²ô»J`:ãß°¦›·b¸m!‡ÿ|‡Q%÷ÁwEËÚ¡^Í|'j¼wMÙTì*·[l9³£'bŒ.ô^]Rk˜Má†¨Qú	­§%Ÿfè:t”Ñ†5R€æy9qNIÎ2£îA!iˆÕü‘¾Å)a;«‚&ë`¿åg_ë«]–²(´¶ËT³´–rgİfsG­ÒıúXReõĞ{_ÜŠÚDÏ`›é¡Q'™5Ì±C0FBÒXø0;oIšÁç…´“1´ t–a¬—Hå€ÿ”icáÈ~ÌILC»ô
4ñ€öÕ~‘µãû•gşƒÑJ7@ÄuqÕ]>s—¿k‡’ÌÄÇØDTÿ=ó™±sà?`¤†‘>¼)t­‰:ãg>ÙK´TiT\¾º´¿ {2–SÃp°2²şzÃÁyŒ
tÀ
v#l“xri—ÃÃO‘É„— é¶zêæ?ìáš¦¬Ç½F+o†PâJQZŠM8
\*qQÃ8_ï¾¬‚ÿÉG}ô¶¬ì–^±e1ßIwç{Z<‘™{õÄD¤$œ.n8³©4"'±µ…Í%·#Æ¸­òbXˆ œ³[ƒŒdŠ/+Oü¤‡›ëw‹S†
ƒva|	YN‰¤M{è¯àÃÄ[.H/u;&[°Ïí«ÑQA Ç	gï:¶‘A5[—¿¨Æ]b•ƒuøt\lÎˆº……Êø"€!¬ ¢ÑoUÃ'S'DÜ[›|m¾c2tæè´¬‘q¾@-àìsX]õ¯¨+™
 7p¾ãôÜÙmX}IiEœ“ãâåUA¥BĞğ¹‘Xì,òb¯ÀnM•¨£¹ƒÙú=7:iqÆš.S¶D›-jNmíg»âÕ{¦”ÅsaëÎØ–w
,EMãû[2¾uÕ4Ì#ø«ãQ1†jåx!(ˆÆiêaı.{·eZ_£ÆÓ´ıPtÆ¿šÿÏf¶šv1ÿˆºv)“¼:·l‘<)ÕFš
¡V‡Úp×ˆÂX §ÿÿ-”/Ç)v’æº#sÙÈdõ™js£¢ç@mp…Å(ç¡dcğ*`Hş¥8Çßâ“tôĞ«äaÓ£B@Ä>”Ş¯ œ=ÿï[ÂıÜPê•AMÍNvòŸ`ÿ6¶‹ZÇÿ²,%Î9cK|!BŒ&om°ÕUÄWh†Õ(E²:aWLfñQxkÔô'yŞl„è€ôvè5QÒ]‚[ŠËÂ[-DÕıORş?ëcÕ¸fAÅÉ]‰2D˜Ê—Mö{X}¤­xä½¥ÎÊ÷ya¬+‘Eø1Ô`á|}D~ ,~yË[ÙÔVE.¥¥ºQé©ª¯Øˆ_7nŞ!`!íAÕŸ÷¬ ÉºW&x‘lI&..ê™¨Ñ3å‰¼ˆ9B]-)%«KÎ×íòË¸oÒ!û²ã¡‚ù¡2}‚6@9İcxÔŒ”8DUh((‡ß‚õ˜’*w3™ôÂÑd B*«‚Y*%,…+å.¡›IaH"³‡*Â‡Ô¨×İ åë$Òjf÷ı">]$œÅ‚~Mî
`[D;œëË‘
Ç\øÇŸ)†t­óÔ{¥œ%õÙèYˆ×±Eêp!K‚°¿ø# Ól2YíyHèÀe´g¥w¸"mé‚¡Z!ÑåíÚ:âø¼NÈĞºYwåö';¸Ê,©ÿè¾–ŞØGOñsüŒÇ~œ”¨Ä¶ş‰AzdÁp‹ÙE~È©+^õŠ¬g>afö["·Œw€Sv}£|¯Swêã«ôW‡û e1»‡çìÏ#­Ió)^›G]Ô^~9n?Ä,n9tºBïîõñ9ò?Ù3êBÛ˜^!‚.İ,›î¾(^dIüù¼À^Âe«4©“t<ßŞQ÷õJ„5FÒoÖÃ×FI²Íñóê!¢„Z.Ğ°°RC+ëxå„Ï!à)
\+öÒx”tÄÕqÅÉÃè<¾=èzª°Š¡‡â”ZLÔ¶\45ë„›$iŞsß§1Ò`&è»9”A,İò´¶úì™ÿ„úÃQiv:…£¶k—ÑdjØ‚=†WI®¨T÷Áiá¾B$Ş¢>²ßï©šWZ»©üŠŒZ\%$‡ŒïAÿ-E¸ùÖ#é×%6dò(HêÕŒ’¬¾ç^Î}–ÿ˜¢ë÷6EætT,Ç¡@ıæ€Êõ0GßØĞŠ"r·çÕí‡Ä9°
‚Ô7\w¨Óth¤²JW	Ã¸uq)Bu[?‚Ç™qºeœâüüV30Òy`V!‘Ci„êŠ–6Š;Ì-ğfŠ&ßxp›ãªŸÂÈ?“à«`ZŠúÒN8‡d®‹Ïy»‚qÌ³j§ş—§MÃ9…Ø›Şp‹	Œÿ·¡ÜÍÚS:[íÿÅWVµyÍ ñCúŞŸwv2!£rBZñg\à6Í<Á¡ÆdÉ”ß2òZzhxûïğò¸)Ê+’ÏÎ—öà'RØİ8Xvp(İîï.«Ë€SÙ!ZÂ¸Ä$¾œ<$ƒìTtÙ’¬ÕÖl— ¦a4¢Lö¤h
1Èÿîc1˜rV—?)Êe#<}08GwÏäï^”«óÈ¥âÁOˆJ!–fª^ªwAW{’3b¬f ìÂ+:6[×Íg|M½¨†8—p*:9v•ñßhgMx$˜éĞà© ê~±wmª$×·érJiÛß0ÎªÃùÄŞFuo‹…=ã+oDĞã½Ä~áµBS°•¬ÕD*ƒïpàjN…yó·I]$P™ñ[¹´µ<v7ÄÌı°Ë¥Ô-ËeÏoy‘€Êğ‘›|<"pó¹a]æ’ÊreşòÁqí Şt5é=Èèd—)O§Öõ˜¸ãÕ¬ôä-MÉ?Ağkå|3fÖ_TiÙë5K‰ØÇæ8_o1K 2İ×hÑšYóØ_±8YÅ¹}ÛG _JGucÉX+tXÏz*r úiİ°,S:wÓü1„6‰œ–l¯[íĞºŒrc­Gl^ÛIEß(zhŒ•Ù3SÆ¢S¦[älœñÎ—4ÓzÜê¶$¹…sóóœô3H8äuxÉŸ‡a
uHLp¼C İ‘¸[¥¡D–pßbÇ©©¿% dÈOOö~Ù²b= ¿æ!aåÓÀßìóú”¸ûG¸rB"ôì	ÔÌí–Ñ–Bı´ğ¾`Ê3¢dûp.4:Œ@™Jö O=uZú¨ûaîÅâ
=;àZ!AE‹¡`Ñ½^EÆcÂÀ!¦¥lif3}L¦øT&JDó;|¤^	¿6— S#êHã”‡ôTÆëFÓµ™1Fìôš€m½:À‘F»ãQ«æHÑ¬²rWò@ü_ŒAH„qådÌ!‰¦tvÌ<
¢²­,HMŒYÈ:ÇßÓÕAÀapú™y*üx¥c„ˆ¦çd^Od‡ŠÍĞC@Dì_è'ï@(TSe(S²	áßº¤Ò´÷a
aŸš‚ÇÕ«6ˆÍdXĞv|Äë üõZˆ P—C1éw2‰İúÕÈGb/ïT±Yœ¶….ràùL-/í"†'(¾=¤hÂJçš·Ù	¸¾TŸ(Ö&È„Öã
 >\úÚôÌ#ã³Ê¥ó£&7Ë‡_aÛáúÚ(åhq}@àT‚«j®îİƒä}I"%‹K>áµŞÛ
xCĞéc|×{pP°¾-ÇO¬Ç~’–*t	#„dêîçU½SÜ^«ÙG˜<ËšQ¨×Ál˜›‘«}ˆÀ«;ÓÙ(äşÒE¿L¯´JL˜]´{	m1A+R¯Ô‹R©Wî£
Ï¦etÍ È	_­qÄª–Éö“~oe<È³:‘iWIÌşØ¸ŸYOKÓÿâ¡kRr³„,²Ìaèüªè¿²	¨@« û3x}â¯ƒ»är’ˆÒ²½¶&d‡˜‘ãNLCİsÔ,€Â'FkáÃ´ëÈ«¶öf	¢YJ†íüézrÿ†ğ0ïQæßáÆkıï%7\@Ÿ‡åb¨ºíÑ?¬nSuàÂòÍ÷Ü×,åü¡«+²8¼R:Vó`ı³ï_eìmÅî-ZJ|ÓÜô,ÍPüaåwµh·>ÁÇ#wwÄ}ÇˆÄ:¬›VÊ¦Ü¶wÜHJÏ€ Pƒ‰Ê}s“Áoôâ“Â6­…ˆü˜<É£Àœ‡¸?«uŸn?s³Š¿ª°B{˜*âF\5¢ÖGğnÈòWêû7“T¢pëºÉ1}Ø(ó,!hf?Í÷~éõ°ñŸ €ÎO§	–m©)"óôti'Qbl>÷m š‡r<‰ö–’İ>=Òp«ê-æä>68e‡[0›õ/*‰+#ÇôÊZ8.ùï£¯cÁ•©Vï«&èd oõø"<ã7û_À|^Y£–åƒIîƒp¿)·ŸmÆ%’\	¥ ZbÅ{E1¿kÑ›¼øh¿XùN&áâyUçÒğJGãƒo¤±®}&Óêú]¸›6x„öŒ³ˆsv¨ú¶!‹ÉAuvëwZv³¿iæ7»ù¶ ·G|k±ê6!TZ¼hÜ\tµ~¢‘änòlÏÛ³Á~]¢GJ-1™™·œ‰’öÉÊÌå"‰cY_’ ¯Ì(Ü™%[L[¨í­L§b4ëŸ5œvâ`ÈàĞŞ†„Œîæh,ãd!C­ÈÄ©Sá]íyÈÿÕGĞT±ğæWÍëa§+› go.oŠ!w»É[<fÆ)5IwâÏŞ;e{Õ§–š€-ËÅüöky–"k$/HQ ÎÆ#~©ÇéÒ×N&cú?O'Z‰jé«ñÜ´›¸1f?/~WËÖä’puòî½*Bºs· mî§PseÎ«Ò!S(6H²(é³rD í¼±9è9äm_\Ê-ÂkÅÎD7>^Ç²Ï…1“\pÿ±bê‚Ñ ëòş  ª<qW*3N Ì¼€ÀÑ_|±Ägû    YZ