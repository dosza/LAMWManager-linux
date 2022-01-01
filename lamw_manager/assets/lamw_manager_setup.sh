#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="482780007"
MD5="ef7e38948a454bfc70baeb214aca1164"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26008"
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
	echo Uncompressed size: 192 KB
	echo Compression: xz
	echo Date of packaging: Fri Dec 31 22:51:24 -03 2021
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
	echo OLDUSIZE=192
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
	MS_Printf "About to extract 192 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 192; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (192 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌâÿeX] ¼}•À1Dd]‡Á›PætİDõ#ãìMÆÍgd€1V-Ú'à)îÁP²ÕòİKïšŞ¬*–Á
um$øÄ„½TÄ¥êFiñö¿uX¿…k*èVƒ'³µÚLm5†ëßYÇg–#şeªe`¾H±ézôì«NßB*õÄ¯ú¥½ŸÈ%(}º„ë1†QŸí{üğ½nï¡§^xG–JüèıŠ”ás[Enê0WSÏmĞRÚ 7Gí Ãäş%"Ä­/‚QÎ¿H”âÓ¹G–7´Ø"dG°FIÚzÃIcb¡C,l÷LÑÕ!ÓÚ1Èåg·¶vMJ‚áÓB0>Ë/‹Éãî•±gpƒc•}êÓÏÛG¢½:ãè¨<1Â&F¨bpD4TĞ¦ }ó¹_>=æë€ó°±Û7r=:2ºğ“øÑ¬}wK,Aí8n­`@ÿ". eÂ®ü¬£é(iBFü@ÙÀ4wN¾g’éŸô›ÖfÎÂÌã’-+~tcİUj“ÌNğ-ö-™Cõa6=‚§‚Ü8OC¶µ`p¬@Ÿ74GÁG?¢*°t\{%·K±–€<Ê­H™z6Øa‘i·)Â†Hø¾À]aâü^Jk€Tê»êa‡")3Œ)Íˆ—û^OÂ3E˜fxS7(ÛıóÃÆ¤½z›]åEP¾ÜB:!vœŠÆlº\P4É‹z“'wıo)ó¤§½gİ¡?û~ÜâÅ9šµë  I«jÎé¯“/v_ƒfäµŠ¦*v!d‹Yv«BZPXMJŸˆ¿ Uoî/M—ñš. Ó—šÉÌ0}$Oºw¢½&ïÁÀ—ø‘;Ş½Bòè$àNmöŞ9GûO`œO;†å€É€¿Ê˜MvvUŸ´Á[Ä?ä©¯ó>ü`®ûL:¦úÙN#-àè¬V]0Óp¼ÂcN•™†qbŠA<’í®°uãA¶ìf²9ÿJhÅÿâw òˆ`w¬¢HŸ†î3XÇM›È®}é!VÖI<D
´ÃÒ†uÿíSö7yáÂRW…Wœ‹MïÀÂ\_,¯Ïí{´µ"ğ›Ğwëüªö2ÑºLÇü©¶âQR@ƒÆ"8Ö‹)DëÓ ÷ß#jïÚMÕc-ò&`fn¦ä;7£8CWShº{ó9#º·^ÅxQZÚhÃ9’Zß*CŞòmsÊè¦/L×ræšÕ:¾½ê6µŠ_ùC\‚æD§Ü˜j#\9é³İÙ¨*İH £Vr®ñaéaÕzI{øÙI~ã`d2q‰J@ÊYTòµø3™u_;qÃ¨> †D†qíæêÉ˜œÏ=“Îdd–ütÒˆŠC9ßäº£ÊBÛˆ¶¼‰õüÚErŞ¯@™¡¥ĞĞ:\ön‡èY°L!Åµ¦0úÊÂq‹¬€^Xÿw-~ÉG‚2ï¨íLH}~ 3²àÃ>µëk¼·'‹ì_ÏË®O6ZwØ“ ú ™¥²æ# …åÃ©€Ágİ:gBhüº/œù1•2¦Z‹PşßİjÎ "+Œ8³Ÿ1¯õd=ÅÀÄvSÀ[Ó-&ø¨p¦äØÒ9-Ÿ:ÅÒª™ ¤›pMw($ÿNĞËÖìSÖİ†[s’R9“«kOX •ÑoŒ
D?“ï¬²×³Ócï½^î04±6kwXÖ-Ã?½èáºËóö«\èà)'>ÔWC1t‰…X¸¡@K,Êh/r»‹ê›=$‰¨ìÿ´_~ùÓvãĞ ZŸ‚¹©&!êçÛğ—w=Ş¶Él£-ÌÚµÖrøöb^”Œ˜ÕŒWq±–‚¼"Ñdwá´…š{?ú|æ;€x›¾ƒ±K™"¯_j'â±íGøİ£mëJgÛ¼û‡£Îò8®õ;ƒ«¼^$’·@Õú€¨m>Í‘f¡0¾øl½Š5Z¯ ,æY– Åtrïy¶u>R,EAŠ.MGÏtˆ S€qàî™“ı>jMîà¨¢Ézfaº‰)0æ §9şX%Gı*ZÔ¯Ê*ø4Åb_=ƒÌ^º Š«­)•ú:²íá÷Ñ+ô„Vôµo¢GÛ=ëî<C9ˆÏ{–]k'Áš(4Ô|÷A›Œ
1åûâGe*Ş`‡ñŠ-ÅÔUßOŸ!Ï-7£¾ œ“ÓĞbiÍ0cRÏ÷E…—£_	QÏk;ºM²ÿáµ0u\‚‹½Êï;&ty÷º„5UO3®È¾tîÀÕo‡sÄGıĞKèüWï38œ.Ró½´A0FÕrêeè<úÖÖ ÂÁk®ÂÓm?,§|Bü0O„ü<›+!„®~û¶øå6·ÂrıõAë°9‘Òzó¿*”ñX¨²-S!nš»£|¿íøş6V×«dï–?¾…tÒ34³(|×Yİ<$àg¾aÀB¹ŸÒ2¸O™#JüzÔm<1›D¬Ás-uñóVM\iH¡ô*ÑÚ5¦í”ô+X=üà;ÿ†ù‹¿m¬¬Ä´ÉÅW´î_AÛ'ˆèß`6-F“/°y;¶£ÕÛ¹*Ë^–`È@·1C5.=@H«Ô3‚WG®K‘HÒĞ¤´BY¶5d ½ñbæùk
(}1U‘uªõ¿Ñá½=@ëx„¡†›uuÄÚ“Rö“¬ñ&ò­aô1œ_ÇA¿ˆÀT"Â8Ñ=qOÓ‚Ó8‡‚hóáá¡Ó;¥µLRE=º!dœğ5Ú/“4pOÕ†²š»­²Œö¾9«±ëœ÷Û¢ìv9cb$:Ğ*³°èš®3ïŞvŒ›<GøRåp{ÿÇ_$>"ü¯²|bÄxâµ³ºF2…r!If­°8×¿KûL Ïò¸+“—¸=ÙKbt(ëEg·na0r6Kıh˜¡Ã[¤ê½¨è]™Ièfõ-ÛÒ.L^ƒ­+©°?@íÖëëšåšÎï	œím®oøoéE3(úNÎ¤ã:jŒœÀÍéĞŞÂÑMòåãƒÜè¦‚ˆ™nu’ßa¹67ÛZ™ŞÍ­Iï·;õùî$È„¿¿”¶l‚™µL^m±CpbÓ ö¶;šIgêüğC*sİ{¡ce?œÙ?:€Ôş@Ü—PĞDPYcH’d1úãÙ?LHÎµ]_ßd’à9ÛJ¥Jîu—)‘ıÌãÆ³øĞ·µÍUkl)­Sà×Ñ—«é ìFiZ–Ò˜(·‰Ò7ªa¯Òò·)­KÜûç;ŠÂK0·¸/ó%††xã0n}i—õA­cô­vv'—w„Z>m™NtÁ"~sl÷Uqƒ ‘†ÙTí¡ƒˆõk$bã=? º  °ö"}üÎY°ÿdÁİéJeÊ†øîg¡ùödúİMëàn»7û~§l$2ò?Ôf8¶O+òo¢±h—(\ßAYw^ö·4Ø1"Dég‚55ã(~ßÖÈt²´ıŞaŠ€İ«†¥ÕGŞ÷$	ŠK¾›¨şÃğò&{5IÇı…ø¼œÀW¼óÍpsƒXHúPh+ÑœüÖm
®Èø<úú`ÎÔGA§CÕw4…p~©V=±î4ƒò°NÂÃbø›oE¶OÒ ¤R,åæ=y®øê³FW‚^&7k¢*¤ ˜1—Ñ"U8	İMÆ”ÉábS }ê^a•f8u]’Rp¶§·e<ê°¥ ”mËñznÿ…å¸zZ›Ğå%#!X>+ÒI2ï[ç»û­“À~úQæf?*`§FŠØéKê½ñ¤0Ç£œxÄ…›T‹³>W‰IÜäÅÜ,Ü*B7m"ŠQÖ¹ ™$Up<şŞƒó,°Â,Pã?ÎjFï…ıì0qêDğE=Ü¦Ï®D©*\M#¼ÍşİâŒˆA…æ«m	†‚]MuËux´•°<>+Ì]Mù¬Şy?"/‹Cß‡õYâÉ¢{'#Š¨éW]øl«ïp¬bı<—Ëòm•—×_?·8C©P,0à
ç¹ğì5ñÊøÉcàAÔ€‚l2ø>¶+¹¢‡î¾$‘"[0$”à ­­ˆÎz¾¶°¤$`i@îùĞS:|9À–†~„,Ö…}3¾º¼8¨şb­Té¬ùïÃÄ¬ïÏİ–ÃN~ ¥7jÿ ½66
ş”ásm©·¾ãò+–]£9%WâuwšÔ ‘ëLrÉ’°Æ'NàÙV —gËº¾øµ<Á0 X×Ò\Êö'ËMø¨R¡öõTí'¾İ'7»½ÚõÏçã´£ØÕé@{£?T˜^=İA;Òş Âõác®º×u*TûO¾A6ë¤å¿¾A…Fb›¡¨OaYèÿñgiî¦«MCa®¶lÆæŞ±éò[ùFDÚgm¨Š+é©æ¥½º‰¡mRÉ%dÔGÆ!bœ³¾”ÙÖÛĞı?0¹¢é:º¸ºÎĞzÁíÿk_ªî¡ÜíŸÁƒ Ôçşó1Ùty¥äÁ®ö#ÃTE'}§6İjyw„•dtDèè8ç7Í<ĞÈ	iq%äîPgDøØˆ½63¦ÙÓ*H½ñQdıá•BUyÃ-4c¾òØèªü`ı>„}™ıAÍkîî¶P­>FQ\œÉêIK°¢UĞxo¿ø·7u‹nÂĞÛNéÉÕYCï?Û‚+4Á¸°·’>/2Rút7L4ª» u¹û@·¬ÒÉ‡Èykxº/Gœ]Q¨)"†%«øõJš¨/J†›\xÆ5¯X2ø+vÇÚ´¤T¦†ÔÄZõÛÓÛÉŸ»Ìá÷ß‰X(µÊYÚ£Ñ€µÊÌÆtšìK"ƒq“•-Ü;Î/ÔµM€R—nI<gg¦z
¼ÁRŞ›LÎß£İrÏzW 0>”%uØ…ç¹Ÿ!e¦ÎşD¼&¹„?%`[úµ¾Iuà²4ÉM=ï'ÚsŞCfÃ ]î®.ÈQmöŠæo^vêÊ1Nkî¢#¨hÑVîè»Ğ—Ó%!—±X=FÊÁæÌã­ ÇF$ç)”f¿¦%¿àB¾Á¯¶*À¯l.ê0S¦İ5•zKhO…`¡“…Ä yBuWF67Æ}êä^˜ş—)`$mÆıW›£MãúÒ@ğÍAm@Å’õ‰{Úcßì±ğù‰YZK$û]Çû\7vQ¯‰Lı®.ÉmsÉbŒÛ|îSeı–Ô¤píg¶§LSUó>«ò½~|ÃB B¯Ï\aTCï˜Ôp}pnì+K{œÄŒC÷ì±v^â¡ *h3{—-¼ÉeLbpÓ`sÕˆU+k%c)ù!<	Ã)ù¨ÛÙ¼ì¥{°¶ª
>+˜ÿC_n¼öúàv%M&Nò¢Û™lËó7gN?ùìÔ(	=:§Ş5ø¸[QXQ¢6çc£
ñ¢–8ƒ<V
/h2q-,J–~ÿ„…K }¾¥¾ïÇÌé}Rèü|*çqtßì™±fJÛ}ñÊ”ép›e"Éu@à%MôôıÊâ$¬)‚¼í¬È`ñŒ=Ö}HÛW/WuOsŠ–¢SEg‚èš"‡ÿó‡ñ‹ØG3ˆ`ú<Ù”œ¥¹Ù/âª(*ù†Üå¼A‰ŠÓëAA†¨İmF±,À‚XGL9¯úñZ ?ª¬î9öşüQ\®»Y_H©†eŠP!™,aO[@nGlT!§ıtE¥—ÒgÌ®èØ÷°kˆˆfz¼¢©UòŒFT€V'–ˆK4cŞâç¼‚—¤ÓWßÔ#[7—£gš»–^E$ã«Ÿë¼ÃŒîxŞ£
¨|ÖÃIİ¿¿ ëëJÓÙ³„ÑÙ„(àş³5éÁìß(;GŠ“àÌnÚ¡±ì•İ#kÑìdò÷rø šSğrÙ‹×IÌØá–`2Zt·•`Teª1ø·¦/Í2{.¦,Áò»İ	oj5Ğ¬PG¥T?¯î¶ã>²ë·ÉÆ¤í¨éäM®EVHÅà¼ü«Âà}¦hà*ÍÍ…e]hú›4@Ï z}šòûGygÌ-âËD#°?7wá61Ô÷e¯»œc3òglkÂÚ„­“şoÔ{KA‹éÓ±êE›3Ã¹¥òá½ƒóêú8ÙU
Š3¼ ‹cĞpÑ/ÊŞ=U0Ù*˜1>p_`l»Õ-%ãJ74yu¦fû¸œ‘øoêóds×®Š{î¶b?#4gS\«.Ã¹áMˆUU¼E‹:ö…öV—œ	±h”v#VCsJ›‡#€!a–?…Å‡Yê3
å“UY.×©Ã1İˆúŸCÆì®—Ş^4±ÏŞƒÁSãÊ°ß´bÆöÍx’Øs‡½½Ù3°l*‡8f(Ë¨Ù}.âÍÀ¡€GwÆ\Mh§@ã~,¾ÏÓâ©_<ÀŞ>¥Ï×h…@ ßÂlüø{[ûVç©Ùr—£ÛhDÆW¼;^Æñ5íwd^Z3u?hæ*f~‡<Òbÿ&4K>½Fè7*,1ÓY+è#{—Âõşl¹ú@}²-u4lø­Æ¾+9$›UzUK²	«Œ¦?®'Ú1ı_y9á¼R®·ÆO¦5`YÄ´×†ßNrêİÛ©/[åzC“6ÓWLk']Ë2ÊeJŒ¦¬Øîqìe(k_âAş·Yzë_¢ğŸ%~üg#‚0Mj+&Ì:ù86‰lyúXzÚ,Ê¾e!Çy¯¸®°ˆåôÈ±f	¸tÂ0!9nÆ·-JXÙ·7‚bYkÔí‰†\Y–± ¡üumí¤x=Pmš šNo—[Ò(”dÚ$ı=6#Ého<ú¿ñ€b8YI}ÒÒ|ŸµÈ%¦¥Ü'?¬®ÿI7@ÖMµ„ı%¼âŠEÊ™2`lwÚ¤KÇRV9°¬´×I·!4œ>EÎM]ßŸ<ê¥°W*Äš¢ïHa®sN¿¸Æ“‹¼éd·öYİ_hnutĞGt©T½³TîıOêxª7h!ÁEmİ{½‡ûcJ{öZŒ,T©dÿŸêÙŞ)Ç4¥¡)íuÎÜ“„‰°03'ÛBIÑz½×Ö1PÉ%ÌÛKœqì¢›~¡ <e'Õ›óè””’™°¥ÌÕ)eÂÿZu¼|Œ[–'rifj­f¾˜ë‹ogİ¹pöNté„Y~UÖ¶ÛÓazS{x«Í5³Wùùúç´K;ùPfÆ¬ÿuš=C¬£D€İ)³?)Å3P#ğ¡äŸfß Ê<j‹juğ·ÈN¸î/åMjR2Çƒ[Ä®¤’û1Åy!Í5ı9¡4€!zöØ=<U¶®
†øÏ‰ ´,7we´ö†ĞLwXß!Ş–]ûUAÔZ( k&\u¬17¶ó[H[‘I£2ÿ®|Vï–lPà]‹r&5ÛüÕF
¨ X€¿”Ú¾fÅÂH¯Û!¾*aíÀ¶KÊ7RûÈÕ÷ùl+éX†‡ôkÛÚB–ÎûCÃ=‰a9ª¾]õx#éõ=ÿs¼mBc‹-o!Q8ì‘i’¯„±QC”ò‚r®.Ô³ô†`J‘“#Wl¦Omşí˜H(WÜ-	LàgXÙ¶ì«ÇéªÓÓš4ã>k››ÕW|üÙ/*3M”L;hÚäú¥ÍúWˆïİıçjµÍ]Nñïj=Dº7­êØ‚È‡Ş¶/p-›ñ©7sk :t‡´o ×RX*É.^âıo"T+adõ.¯¯\
%•]@òR¦4m³T­®ç²àgÃí‹rÛC4ÿÏg bˆªåM&é¹Âi.‚¼`k¶›f7eû lPÀïtx1«ÀóeŸ7‡"w¨ˆ¼(Ğtk©U}O83Öû´ÊUÔí,”^ö²ŠÊŠ+i.
)vº]wÛÛ™÷­–ãªÈ FŞÎú(Â£Ã!úU6ÈİıRâ'¶OKé_Ó¡\áÊL5Û’šİÌ¸FYÒ—6ó	p˜ääÈÊò}‘–Şqî…¿q´LÒÈ©{‚\’¹aZ Bœ)IºÍÓFYf¡|Ä†*Ñı·Ó³l‹«™Sğµ[Í+j›jd?™Ä›[SL–I£õ…´Ÿ†eÈ 
¶FÕ®šòrŒn²ğwşRÁÔyâÒPÎWÆ:—|*.iÆ`à…ÖùFŞZ_j.H	Iz¥İF¼	Íb5İÛs„_YW`èÂz6(.}ê‚ª§„CL¼\G´jwéê†ˆË¾ãúÉ{Û?Gÿ×—Ù¬a»©“\FşE7®E+³‘vtX»9HY"œŒwyû=Ğ½Ù…-3¯_ó`l,<_,Tm¨a-îŠ@’|&U.(0C3û¹n"Ã‚§#ştC2çèûĞ'BT+À& †kXQYˆC<n#ºêÕºÖÿšRÂèh«7„5i(–\Q
,lßr›9ZÈŠ!ô›°3ê!'&(ò©rE¶‚knÜØ¼Ü1rh¹`)J¶¨<,ioGzo\?Za²H­œOXMd•¡øó1-|¸ÀšPš§bœ78Ç£ı×N“å¿ıİµ7Ás@|•¥77&‰"øÔ0‹ƒªgRI=ísĞ»Æ«™*ß™åHÒ?zQÈùóUÔÓ°’¡ñ­ÁÖÛfñXÍ(ÿhÁ6^åÑÜˆ³!on™ğpñïÍóÏÔA‰7sÍ¶Ğ»¾üB¡[ë àî–"š“GÒ«|íú4áú
öô os€Z¶—…ûxH,-,
²é}-)º^ùd3ÃP[j¬a[<Ÿè€UA†Y€™ûÚ'ı¨ñ‰_Së=æg¸ÿ:H	ã1æÿ8ä)ó‰ÜÄq{¯v¼¯_ÜJ›$ÁŸş0_ÔGóMÁÆ\t÷~£MpğÁ¤¹&DÜ˜¥ÔMåĞÁJÎZî…:Û•KeH:BxÈÄ1Î$‰›ŒB	äÔ£Ô„Ùt(ÏÉ¶õ’ñß‰ØèÇ5
UØ™ì†“Âò¥¨árÈÏÜø$v+ØugXÑr0[&!4+C%ÈT´º¨´”´¶$Ù{`Cï¡Wl˜³#Éïº-§µP¡Œp%oa¸=WÍt
x´ğSÕ]tŸ˜‚e"è¾g¦=Q®ÅI_$_ò±õ§ŸæÜüŸ€³à¿\¤‡L¯ôóÆØoúP?Zy4O1©H¸ç-KKéGgİ–(Ìì*©@ô´!õ‡O¨Lº›‹U„"4ò¥TonÓÜ†Û {ĞúËÒb&Jzˆê·1úØË~'Ø‘İ7ÑE-¢¸:ô=%•×gŸ4`á¹yÃ÷»Ãîï`.–‘Hõ–Ö;v;PÒn]@6Ìï:é*cj>·é#›"}YhèkÌ¸E±Û%Œ¥W—òWŠq%ÊËJ±…ôU»ñÜÓVwPñûkÜÃjCfÕÕ°(k´8µš‘PxœX„–*Ã_x¢7$`ôE}}X¶gæ6pñ&pO7ÁIZÿ	[•â¸¸qdì¢–ÎÛC(‘ÆÄ¬µ§èa¡™cİãé#©y¶»ƒ€€»M|Š^Bİ»oÈäzM*WW²33ıÚ-ò„Âì`ÿ7ÊMÏËá¦J.°z˜›µqU?Ô=¬å:GİÈ½vˆŒ¯ƒ*­B1è©Û¢'q÷§äÀÌ±&ùÅ=ıBÏÂoÀóÂ†v‘&±üu{cõË-@×ĞN ³‡Ù®ì¯|F¾,ò?ÑÒ0ìÕ ‡(Æ"´›5òSúÛ"Úêß±‰º\‚Âo êÂî0Zó³Ç¢dpD5ş´Ğ–zÆ;$ñ9BPôğØJü7#ô”²›3#ãr¬ëK4h2è9xpcn‘^À·[‰ ‹Ü\ó¡ÿ`T­b÷l»QíWœûš1™Ñw¨K¹w€+wHéKVN&´†udË¶§)ÈìºP+ºQÍàÀ°ré¨°ìüPl{Şo *²=,=‰·S¥Øš(ÒzJS+Ÿp-Zç+Îõ¹„$v¸pCìlóÙùâLºœ^C,7ÕéÖ›¾Í¯€†¶ã©CË« CâGgÚ+ã°T 7-%m˜é`Å NçÅ>(Ğ{˜ˆèR¨±w?Sº®ãËã“J<L%]GQ0ğ&B|”Qó*ˆÆotHfcGârî$«ÌmŒú]êë’&>KÏH84uçyœ„D3¹PrSf©aš(·¡ 230$]€ç<é­ı£wGmÊ0GNF“ÓÇ\ƒ:ÍD'‰råGÄîÖÂšåM÷„DÅò 8u ”~á8fZo[ø®«Ë²­ÃƒMÀª£ßr¡·{æ´Ô*Ep^ø2­Öî¢ u.÷ƒ'F«_‘\ÒêN+Œ	¢›Õ­LÑ'íöëŒÅVÍ<%3³·-VôŠØ7ºÉ¹…Ô´MÆ”äDşãàô‡ôK€SZiç°Õ¨œÏˆÿ"îb%XªÊæÉÛJÓ]ÉÃ¥ƒ¶-¤Å@¡Ìv-V¢Pn"-;R4İ”\Ô×pN¥Å•’ÒÑ%:¥	CJ*c©K£DZµWƒFejQÇË¥ø;Kx#" _+]÷jfŞÜ
¶j¸NP4Óï€ÛE{-F5]xPcúƒ:f
ô­ËyÙOØ´ßc ˆ:!ŞùÏi§ÖI#®şÚõğ>%”s­’x3ôfóœeIÏ~VÖ<Yâä,¨mŞÓ»QkS«¶¾·"lÜæ+cÀ”Æßûß\H;9–ÍÏw7Gÿ½œzdÂ?óÊ{ò;íSqg«’FáÕ‘hB‚Í3`†ë Vâ=Î–Øz -?ºÉİ¦le€mÂÊ?¤†•Ò-ù‘ç“üp{lß:´|~Çñ>>µIh­0’£³ÖùV¹PújA·aHèüd™Ü ±}¡¦G 82ûáÄGƒ¿!âìõÒ…Ş§+6½â£‹…G¼b¤x³™« ¿£µÂÜ¤àq7P„Ì°\næäEÚ„0ªJÖîSV0SMwu/C¬­qÛh+dÿ¬ã>ú0
¨ ^`SÓ¢—bª9ögàâÍ+İ3ï»	gGÊ”ÿœî¿çÕ°ş®Âæs&Î,8NÛÎ)>4ìñ«Yl>1™Ê-Ïï ğş»¢È¾%D|’ĞcËÿ‡¢É¡wü¸â}
¾Ño–dÎöìWŞh*†·¯­Ù©sì a¤¿ˆÆ¶Õ“Aršàs Ïì‚_É.Kù>F¤Œæ9 )!µMÂå;CèûìøòØB×à”ÉºåÈ§¨oåÅ=äli+²N€âs¾j®ãvñkV¾\^öä¡ÑáÉ;#]³!Û´{Ö•Âò’[Jü#*	¦R-NyN®S›2,wETºCÁä<I ÿU2HHQ2÷Ïuù†ó	l}¢Okp¸óÿ¡¼:>#åğÏœÒÙó=

‰&VE*ÈşP¦¶’¿Gåú¥ä$¦TtU	s„}KrÊRW¼òM-WâsêĞ·•1ú,”²ÿçsò¤-‡^vÂï„ˆ·„ÑşÖ"Ëöã}±Uñm£ëLPæysı]fAŸ„Æ òÖ„œØ81„+Ò&¯£.uB¿&¸ÿg µ¥4­šü1ƒnòÈ«n@tQ¸‹¬ìßB¯D/ß
¨^4¿lw§Ì"„/÷x‡d¬1Š5À´‘—<¡ÈI`‰Hˆ”Ù§®çÛV†ºáEp^ÖæYÃ·m—8ğÕ¨™^•¢k o tcÏwÍå†êœ¦½áæÇ7Äˆ1åè¢DYHº&O$pB	]pçáÕĞ&½èUêüŞ4¥sÈ†*PÂ&<¶]KWÉ9Ÿí
=ÓêĞbsŠS4W%K:ÖcƒT¨ó—E6Àm´¦ Q4{oàø ±@üû[K…"5×Ó¹ØnÏU“ÎdŠG„á÷`íÁÜ±‰î-LRcµì{@hA7=Nœå›Ãç?Qğñ×müˆ›uŒ÷ÙÖŒ«â/Ó¥e ?A\JŠ7ä³bnh— “¨É©şt[ãû6ÀŠ’3˜°¸f`—FÈpbïÕÅØ3ÅËY¾[® »™f¤í;ıÃãåıéæÆex²A><™ö‹xôÿH&Ï7üÔ›Jn¯. °r„A—ú‹z¥ÍQŒÇT”xëyÅAbwÑ90ß±Û>µª-À}y¯•ŠÑ‘õfxuS!	^-‘µKİ›ËTÎ°ÆÂñ‰§ß%1ú†T3:-‚¥ÂÜVJML^	´Wêîrõ;_j‰ŞBİø«ÛQÂˆN=|ÖœDïŒÂDŞ9½NØŸç^)nl¦WÒØáÌ.æÖ°³ê®%ÊHkVßç,oNÙ°
”wÍ^ØÙÖRE®ê¿ZuóÊ•Æ[ğìXÜàgv#õùoG:3è§9f1:jCæ"ªÇO¹áHf5Å‹Qú-ÍÅj&*Rh;DEt´ı
¿–‹I2Ú¡á"ÆV>ÍûÈûç[CŠ=VÅ†…ÖÍ;‚3}É>W’«ÂñÔ}e°ª5“wµÑW±ÆéÊê³
M7ÅMÈõâsüB,qÑYú7ü¿õaÌtş$Óà¨eõ‹í³.®Gêµ7Øš¥¡}+~%ÑpÎ»2Wœøn ‹…54®ŸãH†xiÏe‚¤¼”“K:*“ã‚:ù(&ÂIâÄ“W‘dÆÔ9ƒ±Çøù™¼ó2•…¬šç™°‡Šl=Yø<Ånc£72şÉaÎ„"h¡	èÄrãBß6†Ï‚ª7Ş«zfªå'cêÙVôŠ9Øjq.|Dà¤\1ğÒÒBÙwéğˆšCQºÕX< °nÇüŒë¡‚‡4a’º/7şŒGGWQö\ÙbÅª÷e’Ü@“y¶SóldJÌK€W†NÎÄí:“føhGĞwÌ»IîeÒ9MıÀò‹“{:NÓ#-œz²f„Ø*²¨Â»°bÔÉƒøF‚üVÓ“¿Õí_t/È:H4¨Êï8¸Æ¹*`Iê
ìVï·+¿êNÿ8‡z{U?m"Åˆ…8ß…”{' ±şq‚¹À¾‘Ñ!òKvífª)#Uög¼ØŸ6+å^Ò7»Œ)€-ĞY	£åç§b‹Æy0!˜•òM –ÿgãĞñ‰Ìİ!>_t³ø$3³Y)œßXK»íŞTË`ĞD3bÄ ‹^nµ9A¾T[HÛ[
›
;öa³:q`bÍL`Óò/70˜$XÌdº:™ÄÜSi4÷t%ï¿0¼ÍH’ê:ãªaî[Vôëûö¬‚ĞqaaÜâÎorãº…m5@¸ş±‘K³éÎØ[3k“ïÚzà3Á}kÿÖÕ ÉLP²ë84è®’± =‰Ú2"\G’NÄM²tªÛz%{ß®p<‚ü‡a¥Öµa‘²}tú—vébç¡É:L„ÀèAæãï¿óßå²ÅÑêHıš,‹À:¤×–}HlÎö8ô™$—ì¾~4H»ñ1ïmªŠM©„™(-¿uxFÙÅÅŠÄƒ¥S½€çÁ¹VM¦xíPVD Ín¢UNUÆÉNÂ¶”ò‰\5^ü]h¶8¸H…ë{ùÈN$ÿîĞjÁ{Š+ıT³¿Ş@]Á¯ºŠ<Ø#ÁˆıÔ¯N6I£yM53^E^™jPwX¼ïçIE!=1Ÿg7XøZ 3&Ñ@Áÿ6dkì¨Şi7%8é\ÃØ[I‘†äô ©“1[HíÊw–Yª‹[o62¦=•øRVÔÀkœÂ´!³ÀŠŸ›ıŸ?8Áliâ{¶Û“‡Úµ3X_Ôå°„XÇ}‘½ÑÕ©îR(ÈN…TÏ×#ã¨õ£AÎwóğ¢+RŒàşÕ¾ùµ£µ¾˜ı<»V#JK”›ıVº™yûĞ’¾Êd*ÄGŸPºQŠ	D‡P®Ñ®ßäX1‘n&{RO©5Ó²ŞLÏ:Fû69-ëİCä!ô™/)1"¨y|…Ÿ(ñ‰«JÙºÉğN(òzñƒˆØĞ­1ƒ8Xãî[e.†âmª¨7ß<ó±‘İœ3²„éÌ²QèIeÔ\AõŒªl]Ç	¢ídŠi;AídÓ…ÕcÉã+s<Àêt‹s§„¾À§dÈ¹Yô¯©óÍùcÎİÇæ¤È,ÚoıÌrà(ª‚`ÙäT”¶İ{ˆB¢¯‡ë-EâŸäsSCñ‚{«Şºyõ°œ;Ş¡ŞØ+¹*V¥A÷c8ƒñûÔB¾1eqtt˜‡¸­	¿îèóÓÁ…e\ ’\‹AŒTÀ\„çïÌ”eÆ%,ß.Ğúî­n&Ö§_!cº|àíÁ`x$l‰T6J)5£+Ğ¦±èè3Õ¢Ï!ñä@7/.9Çë¢ÔDÕÔàóŠW´7½µYß™¿ÃfÌLk—‚ww—&Ûng”V”ı[:º‰;v6xª2··°kÊ{%Zº%L]®²-¢Ã¶ï‡¿7Kfur¶m“9ø¼'‘pmyˆÁïÏ³øSévUN–¯®çG)`CËâ{Ë‹ÈôuqïÃ2êGöÏ3ÆV¶¾,¢€fÇ‡Ü>‰TÙÎ“âo8éc™YI}\ùÀ'{1^„ÊÜg?8‰6ùîLĞ—ìõÙX{aÚØè:¤´•Ø÷½{0É¯ÖĞ±üMóR‘£)§Q;B
u«\, 
»·ŒsßáfMÊU0ÔÇu’q—9ˆSzÉ‡µç±¥	€@¸#.k>ƒ$Ö!ó˜E¡%¥¬D‘³Ï?j§]S)g=¯=<V+bUÍ‰e]ø³g“}AĞfÈté…YƒD©aFº¼pL71‹4T‘)µMôzø§ê¿gaö÷ÑşpI‚D!jîÙì<Kµ³
€H…ñë•ªêoºƒç%{ÎwUˆâfêB|X†À¸>ÂCÏgŒ˜WÜ	çÒQHŒ;Ù—­ +dÔ¨lMÙjÀºÚĞ%:Î@s9³U©¢ÿZÏZgæÅ×G{yïáÉúp‘´í®+…Â³E¡Ò-Xë‰êÃcŠ”iw‹RÖê‘obÎÑBâUªX¶
õró—µ'W`Üù˜S­‰)€GóûZĞÛŞîÖÅÑ•ì=”j" Iñ{#?x]€å%lc~¶†’]\¡×«%ï(=3ÒêsÛÿfşÃD>+ B‘aÏCo\Á8]y‰XûA¿ëC<Ò[ç«›näñ$=Uh’†²ÂÔ89³ÃBBd58§WHİ©ìNÙ!VíVN€xÒ¸°šà±ÿ™o† …Éé¡‡„ĞÁøUÙû”~:âøÁ¶œ>,ĞGû¾ew»ï;³K†,Wyg³~å2O›ğ\áÁÍÖ÷%Çk\ÂŸ)a–j^ğ€È³¯òc{Ìõ}ŞŠk8BâóŞS*H(ãÚ³¯[)33Å 2G]:ĞÏ‘ƒ/ROİ¿¹ÁÇtÅ/D5³¢1C|ÖîŒXé§'OpÆÏ¹:¬fŒkIŸaú"g#c3¯djv›ÆÉ4¬b0TU\8h«lcØƒy–++9#*®ä.¥$©NUÛ!åP=ŞşHt¸“ŒSÊ¿*†K¢Õ‰è¦aİ>¿A”°Zö©&$2ÒÎtÛ£˜Šä¨—9«},FPÎ0'#ƒ$`ÌVÁ¾"?>bğWbïı€mwóvw.šş³IÚP!jş…îÆÑXˆ zù%µ_åÀ6B±(ÖF¯tUsşøˆlÁBÃpDÖáÚõ)Wé`dÇë^‹ë"ëµ#âŞz‚–vSÎ ¹'`—`¹êÕƒ‹mª)îÉFš»1<ø/Õ¨Ey?½ªFÉ‰'e ¨}é·,œø\f˜),ÏšŒã±ï;2uVå»‚ÇÀóQ¿bfGµ²MÙUbCğkwş@º=+Ëô¦¾¨*¾úO%—ÛºA¼ëâ TÁˆf&5{g /R¹RÂ
¯ˆâ·.Rº€¥zş#¢Å!£aãÒu’vøäá/\ÄE”$¿±âh0ÓF4³áñêŠQFUĞ›©¨oQ%¹‘e´IÒ$:UÏuu¦ÚEÑ{÷¸¼äSoĞ†DÀ{¼Ÿ{ÅtÁLª˜KúO:Sƒ{W—ñªñ=²òõÍÆ½ı-˜Q ÙpIXj™®G] ŒœSV¸Ñf@´º£êUO2Zyá4Ğ¥¼ÅL¿™}dŸ[bÒ•èË/BòãDÏ/ùäHs+>Š=:Ít‚ÁÆş…¯®™ö‚ÈÄşNy/¬©–—¯/¡1RçvyKÒ]‹·$h#„EUp˜‰ôuMÒ™z®¡A/«KÍé­_ÎqşÈ+ÍØ]N¬_ıvšfÒaãIà‚~½ Û+6y O»üñ
êöÕ!ë2‡óŸÔ0I(|oŸW=„¯ğ²/íÜ¹M*§-N–&Ç¨F½ÜÄç*“)I9wĞ4£zyí˜nøáÅüQ	‰#H¦%ñÔ;‰’,>d*Ï;óhÆ(¿X¦¢¿™Í.¸æp®yóöfÆß’é¾O±§yã'ıx§`Åê‡>~¸v\µ`TdMÍí©œÛ	å·¾i+ÿ>µ8¶Fµ=;‘'lXQ?§§LÓbLì-İ6t*Šænñîè™"ÒTü¯cjC„7ÀdJVíÜ"Ta[}FF³¾:Ï²¬|È¯ıçÖ$;†‹ÈY*óÜ	œOê£=x2`Æ1(è]\Ä5h–šİ
9x§BëËs˜ÃC*v*ÎÒ”¦ÒÍìêâÏ=¤$î¢©à”×½è)[í¡®ıeê#Ù“JÔ?~ïºøçaYb¢L‚¦ì¦è=A{kqÎ¤ScğºJ_‰‚µ\nàßgÇMj„íºQû—Û{ÙLŸ_oP”A>•mõ#Ÿ+àåHv¬«k¶İ†*;ªÂ‹c”A¡õ(……o¼­L±hîäRLT:œ|êkh"ß 6†}+ÑÇÍ€¼›3áÏê¤¥nÁ
qğh¤öSÒR2r­¹Öc7Y6Æ7²®+a%ÓXÆxs8,§Ñ‚hÕQÍûIy×„ª+%–á‰P’áµ¶rôñŠG\„u÷\— èòQEÆP«¿«¦ÿÖôâkè¨,ı(Ğ5?tö²º™RYò`Dˆs<–R\r±+‹Øãßš2E?·5näsùdK]Š£Rj¥8BoÒ·¯iæj(âvÏ2Ñúõ†ÓˆPØ$¨‰g¶öªÂè ÈwGW!€—TÉ6âR~ºÛÊM¥Ä:GÆŒô<µ¿@ÓÄˆÆ7¨¥ºÔqß­dº5d8fy­úTÑËş±±çõZäi•¶å`bÓg··äc¨ rB½sÏ_€‰„Ñ6<pø:ãû»çe'…wp—!sj&ÃÒ“}¹fºåŒßÄºŠ\\Û$õ ñûÊÊ,,~YÆxêG!à»o:Oæd~ÈœX¢*eß—ª¾AÒbì- ÙÏÃ;órê€b)Ò"´"ç•¦F:hÖ r‘ÉH©J	{\ÍÄãe7Là 8Ë—¿Mˆ®Í†_éÕì9VõñÑ"áó5¿²švCüu^å°x©Õ}ZâetÖb¸º†r7ø{-ü§Ò;Ë¶9˜ôÄÜ²Â¿ÿ+ Ê åºŞ±#r‰íBİÓhŸ/ïA Ô¸4‚«ÿ‰ºì±åõI’ãDŸL`å{­º^¥Ğzƒ1ó9§ÆGõ‚‘ñv°†ï¹èãb‚›ÿ%®64ê¢¡‹ïÍ³.æ®*&ø;ù4è OÍÖñT‹Îğô*3yJuÔÍ¢_>úRÃ]àFíğË88ËËe.¤MÎI*†öô0]dÊŠF^BHş9ùLœËq-Ëb+=S’èE~æçÒş%k¾^şÏs]„D€#É®›†pÚ¾²aƒ‡Mºolşl`ö®ÌR Ä×‘Ò¿zKuø #¼}Ów+:mt±önNØqn6ôÚ0“¤PêÆoI‘¹@J™§ÛÊ&^™÷L¢šyá”ÈKJÙ;¢‘…¸-7”326ZTÒP-'Lé›5UÕã¿‚M8¯@¯2æ€Ï•²ğWÃ’+É,%õÆód¥{è dY,ò=RÇ@ÕĞiHh§òã”~d‰àmšütôu+ªZH¬ì¡ÜXÇ–Jƒcğ~âô(K`—#µöoÅM)æ†»¨ˆ¶06lº¡™‘Nç¯C;†³aQğTTŒ>Më‰‚ÇM‘ Çó¯
Œ¨­“Ù˜uÙ[Èñu
×Eû<×Y1E ²S7£@Ö¸ŒX5â8¦Ïqé¾GKå1¬*oîfÎ¤\¢¾@pøÂ}nzÓ½z"Bıßfùâ#2$şä„ 5¾1é©FöXæ÷óî	”‰¢cDbjDv
»RHÔüÜf{ÈÙº›OŠpwòÍ{[Î7ó¨X¦0(·õw‰‘v"jœŞ;† DVªûËñá®õÅñö‡ZãƒŞè1×„& éC:ôâË¢ìÊëBÄ ŒçSÂˆl×‘â°ó£0(ßé¿[zH.~?[QÌ+½mîšéN”X™:7 ŒÖ¢PÒÇ‘»m¡£òiˆü€›¤ìümöÔ XYé(ÇÛçñ,Ø+‰X.<÷ñ…`)ùkèOZZÈjú¾,zŠ—ş |UPø.¿Qe9XS0yÍ>*Ôy¢
4øŞßÌÚÖL@@ò0[’úLwULF:Ú+‡wû#LÈèº,jK¡ª£'G¨&,«=ÅhaÙ£¿Ù|V|@åâÅh¯ìim?~V}[p…¡ç:;U"ª³âŞÁÆç6W¯2}Ø” jR\f?zTi­ºÙ£ª·4ú¾`”^„ÉïWÖâå³œc¾ÓÍB¤½“‚„XÖŒ\ş÷‹Ş¸½q†úÊIÌ¾¸3~3CÄ =è€¡H¹,îBf—á[»”ØZ«®Y‹nt¬ı®sÀ¾i<L)uB$ñIƒ7QÛ‹­TÖeBî4¦fS}Ö¥hÄqƒ+psiğ”´~Y›êÅ~2wÑ²m’ıŠIè¾ıÄûu[2
ƒès,.ÿ8hxRÜdøÅ—j±à¼í8fa·ÃNN&\
Ï'²ÕÕ± <x¬dËõ+WNX§¥é»	<	Ôª­Wûi¦|9¹$5
Ğ™¼1×æ²…Hæ¤—Äï’jåZö{ß?“RT¢˜,!§RŞ¸0ƒ»ø¨ü+x]2t$NÔi ÷o0â×C-.ËŸ÷à?ØKY$óJ§k¹l‰¡7cÀñÉ¦å [te¾£ùbM+úóMOz¦3x"‡&Ğ|«m{qrÙ×´xÆ¿¬ä~Duò{`ˆ0BÓëx¶fÓ¼ºÕíw 
ƒÕ»ë½èÇ<•0ƒ<c[TêÖÒ’]Æ‰Â 08áÒ†¥;ôEõqX&·ÒÒ:-„ju
øˆ;bücŒÖÑ¢jïA·Ôa‰9´V°AÌçv.v´H¶i# wD’­Ç=ôÂ*¼áwo\°K–QÑ„+[ºÔeŞŞ
?ô{‚ëÁO£IDe‰W®`âá0‡åæ=F‰úrBl÷®Àtri‘WâtbÒuî-èñrZ›ß‡¨xb;
Ş?>kHœ'6M]q7O„GTï}] ³#Lçz J•'Ä“=Sç	Ô¼Û¨’¥Öf" ’$ÓÍ6h¦øî GQ‘dÏ Àl
bfp±+ËA*Ü!·¤(’ã\œRÀ½y‘N/nm²{ò_Öğ¢”Ğ%Kí¥§á9ËVjps°ñƒ÷Ì¼Ümğt‚©ts˜ONÒ`ºQ(6ØïÆ\·fº£sU—é˜wà{uØ1©ùı`KÆªöš.9ªhfa}“¼I3|s–QÒèe!øzªE².UjöÔ§…°Ós4’ç¼àOé•IxqÒ³R;KW›Ó¶^T°ôëÙW7]Ì±¡„ê¶ßkîJõêkç[èÚâE:ª™à]Y” 9*†µ¨êåâ¥Ò9]ÚÃÕ4¦WQ-ô€  y^¤j¨‰My$nóJL=ÖèÀ¡q8wïpäòo+êY^NjòWwÉ)ŸÚÁ&eƒ_\m WÈ,èéE´~‡´RvíÑÉq¢ş‘ÇF£›«ğlª$$èG+Z=VîÁÔ•—¨ m]Ì×vİ…úf÷´4@G•MŒªravµUº@<¹¼Õ…G«˜Gç„#’å@Ç“$“Âqèç‘¬o"X6}´8
ÓñçS¼@\úBGWgÖYDDğ‰/è—…¤,qšfÆ‚N¡õSšë7ª6ÀNƒ/¬BzLl`şb¦P%øüY–÷7øŒÖK‹UËJt•tp3gó°t\f:â©@aÊ«´£2ò–us›£IÚ`ÔïK™âˆÜNg³ ²-¥¤fvOüËâÙ9ö_.Ôşûµi%Ø64f_nÈÏh®{5Jñ	J†:£ydßöËÚÏ@vg!µV’Ç“ì¾Út®f QÖ•R½ò0¼Ù”â,soh,ÎD=	ÖÄ~3(c€eãç’‰Ø–Í>›8"ÅÁX½†Û+»ı,â?Ã|™)å€ĞtÅÆad"¿^&ô÷¸$ôûø»jÍ)9¤Èğ%‡çq:è#{1/“æ Ñ×–í#¸îq—Q´ÈS/µ„1È×ª¦pŠlˆ5'Ë'ÌëZ6"kİ–# ¹Ié,”ŞıÖ‡¯lÖ›ívºr…ŠôŒÄÙ4Òûşá©‡×}%Üì÷íÁµâ,4qNK¼
ge$Î¸TŸ4[ue€Î–¹Áû¶Éèº•­ûRßÂqmÊÎ«L«q•”äÚÎiX2éj\E÷‚¢ğ‡f¹M[;"¤¯¸G¬]Z0@ñ(?1ùöÃ~¬š.½c¶›d¤gíÙ+Ëÿ^‹µ¾•ÂVêÄ·¼[ÏéIV˜Å7ˆÂQ€3ñzãEĞò‘0€¡bpàïv}Ë,¬çŸ¢ĞôÌÚ_q£JA”Ó—¾ïø†möi1B¢72ŠiÕëL°œ‹zƒB¹s49uÊŞØsÈA>íêOA'·kn=ç–šyüûF¸åŒSZhïV|']|gÁÌŸ©g2ãçc¡Û„b¾¥F¸bwÃó xå^˜ŠÇ¨GOúûù†ŠŸ®Öägİsç¶F<IL(İJª•ı©¾İÍúHÃMŸ6Cm´gÆó“‡x®Ò­ÿNÉápSßĞ¦°.rVM‰ö#†ş‰W/Ò™»é¬ş“2ìL–ÅŸ•ehãËS6üh¯ª7q,VF¥:[;O¤døÅÉSõ6àXƒ]©.eHùê•êcİÛòˆ.r—ÑU °–æ¬±´G–‡#Ézß ÂnPÁÒİL¶åã²|¸^–^VÀÜw$SØ4GYÉa€d”ÓPDÈ‹Î‹£Òe‚5G;õ3}+o~ULËR±â%‹`U…ì ®epÜsº›YÊŞÀ1ßKÖpO•7éHe¸:\¿Ã$¬XÖÄœ=$€‹o¹X^5Êã´Rø gíİW‹Ş[ÊyŠŞÅ¨óWaâújŸ— ºvQïó·a¡*¸:â‹ñƒ/]fBøåC»§ÕàzºC¸y+¶¸ƒ‹ÉaeX~,Û‰Ãœ9çÌ¼(²s‡ß•—]ãPĞ6ôº®ÏÛl	$•~.'ÚWÀ‘2¯ó¬‘²=Š‹ôf˜è\n—PÇĞCvÖJ˜¨qÄ¿½ ø+àFıÌÈPIàÀŠcTM­ë àÜ7çÊï‡GÈ	3PÍÊ’€{Éúa“d<rÙÎì¼P}ŒÈ:É‡ërz‘Ö—†Î–òZÁÅ Ahr?ZÛ³ƒp¢ è,¬ëSŠÁ#kmæ¡¼Á×ÛìjÁ±Ï1*ş¿ÈÙ`ğ£á`@ô¯‡ğj>/nL¢ÿvádÓ4^ŠÆƒS³riòjx¢Æ{eNZ›’WècÚÌÉ(çn7EGƒâ
8ú"k9a¿2WI¶3f—â§Á\ÚFšW5€`á:½0HÅ;w+6Sz€a•@,ÑÈc*æ¨?P¡B™² 5>‹\Â~“#©»JOo4~¸ÿiN Õ3dEzdäËU?ÜTDoV»ŒÜ™b§]É€±$HÅ‹‚¸´	Î!Ï{ÒZËÈn¿ØkIn{‚‡É0ª–—ö^ÓIl…}n€›$v,›;ô2Îv^ŸÃö\^İ_*Á¡p+a“7«<.•?a`Ö5‡9¶b¦ÃÍtãX‚Y	zìê¶PGaá1q’Ò0Çi\/¶Â(çæˆAÏíœL^4;VÚsFÄMîà‚d¤ùV`XÈl¿¼4åHÀpò‰Æ²ìN¼ÔCr'„´ÅqO<¸!‰}&ˆ.&%Ïn‡‘ÀÆa&iÑ ß79¾Ğßè­¦Ç´øH(ö*ÜæÇEì#gîN{øäŠ%ôRÖİÍÕøE†ÜË³B¹MÖ›Ğÿ9B¨wÊOF»^tqÜÃ_¸Ù2˜×ÇÎ/ˆ›ÜG¬³İşLTo¢;ˆ-×ªäDÛndEÕ#Å?s\A²†Ş¾šĞ¬~â$Ø‘>Z»6!_\äõ/S(ÆuÍ4.¼å›T û‚ÿ§ãÿÅä¹ˆ‰½8!$RW}øÇs;Š‹õó0w:âÁ³}OuX'(ª¤nªoPıu^İÄ×Ç²Ğ•ÎÓûB…t‡„¹º–ÛÙÖÆ­Ô¬@VJâ{úNÚªÂ 0$p}×Ru•GµñÀ55N»sî?¨­¯Q¸?cŒ’[‡Ş¢&ĞZ‹d@
ûHÖ¹p6MV+ÛEeƒåyq²é¥½píriVÒ¡j/­
‹YSÊGÕÒbpÑ6ª•êL.…ÜLXàQÕ6a :ï¯Ô‰Päp^ğ±ìáÂUl˜\0pc§³æ(kT¶hÎËqE‰]z`z»T<Æ¢‹6”‹šq"ö?İÉÄ•ù¥árÅœšG$å§¡båUÒÑš°o\G£¿%o|ö;³…÷'¾Fe¡÷$ì’ãÀ}x…[Ğu}æZqÂIÌïÒ}b’uhú’—Ì­ïlpu¼úÑMä¾õ¹Lû¼ñ,5ú‘sÆh3Ç.&^lÃPı>ûükøÑ„?_0ÚØˆoĞ®-SÖÇ‚l…ú›aŞ¨õ¥{Ö¢¯*ÇlÈl+Ïo+®ƒÙx½º~ãu^5úûüP,UĞÉ¯Xõ?WONT$/AXçbc2›é\ùpFe‰ 7€7¼û©”+NÛP;>P¼Ÿxãàˆ4÷Rş°ê_'Ã+ı™<Ï¢,›Š¥îã»ö€=õy¯LeRB}¼UxæasvÂÇb–K…,†=û’>^œëj¶µwıwºKS©¦/Äºax£á‡éai=—¥® W¿ÖDjIÆíe:Òòåi9^á3ş‹üÒ’™ÜèªÛ
/äÄ) vfu“ÒRDb]¢ç’ÍåŞ“uqÚ´ôxŸlÅ³­…Ä„
ûî—ìp‘w>Õä-]wş,“L‘{)%è ã>§õâ¢Zúîùòã”¡ĞÄ«Pƒë?–(Flxpvüƒy‰Ôf"¶S•xášJK3ÅWO)ÅZMä
r=ôßzÑ-
VACá•xK?Ã¾[Ÿ÷Y±Š1˜%®uÍƒ¨²0dÜ15O%L
ÆÉ0f¦„zÚk`6óY—Hgç. ”C‘ÄÇF;wµ»ÒÖÃšIèSÏè‡cšq1døè‚Æ³ë6\Ö4·ê²ü¥nÃĞ{Æ.³‰ä:U-çŸ{q‘vRöïâÊLbı iÄ¼Åâ%e›&  3Ñª­6‰ø:<pqÑì¬£‰f·m¿ó«æi:Äo’ƒ1›Kà3­]›(†Ã=UÀ„mëx IŞOˆ'uèÉì'É¶DÿQëæÖÂ§ë\ãgÇóÀóÆwœEÈ#TÆf}‰h†Ö4]¹!o”Ÿû} ÏT„ıÛ8¢»eŞaØ&ÅCÖ} nZ,Mñ`æCv`»Éo|íŞ³X<Üé·—{š^Ó=á V?ˆÎyešó Ì‹½¯æ	ôùOÂ+
ÕÂQqÔ¢>)†~€® }W/@E„éÑá½åë¬ÄÊ’#c;Ç®¨CÜ2ŒºõVŠ=‘	úfŠÎ‚B]b¾ÈËD$öZ¾Î°¢±¸¨cT“)x24òAƒ×”;yLnÿ¡ŞŸSw?åú’Wİ›ïoê”üÕï¤8pñü\ „7¿Áª‡ïFZz,…Íµ÷(‚°FM„¼Db‡L•k#BÆù³°ƒ†LÔ»ƒ,¨—ñÉºc·»?	¯½CÈ…9µ¢£œï˜˜|y	•S½#æ½|6£;¥Ë™ÔÖAµ;f{úÂ;ÕÁÏlä¥h©zs‡@U#,éÆmB Œ”.çãğêó÷>Svİ% TDŸ¬(wQµ‹0¼O®mm&@úÄIéIÕ8^†ÿã($#ŠË“×Îôz¤X9V~û,»±õÛ©”ˆiÁwzİ«£œ‚®»}µ_òØ°«EÛÁ®ïÑæíÒ ™”8£â^/2!®tá¬óÍŸZAİÔ¦¥ş³x7>0û‹ûjm6c‚5Ón»/ÜÅ¾óg¤Ä¿†ÁJ¤O&tFÀÏ»È6ÃoĞöÍŸ?/ØÉ‹DÁ¶ƒ}.‡ßçÜDn“ÅV¨,bo1³à—×ö ƒh\lvÎ¹5·˜$‰ÎÅûÓ
) ÷=o¯Zä>Û¡Bê•M~¥§[1™À·„jŒ`£³%ÄÚ j´'p´Õ~ƒ±¸Ëg÷‡ß’¼•î…(&+ÂÀT×*sw©X¾‚¯EÙ;8şw‚Ôïƒƒ‘ÜôU)Ö‘Çhcÿ94g‹¯„è­ôy£SJJùo*m•Ê¶ç{æÜLË½T#*ïm4ÿÉÙdòŒøªN¡t-¾ØÁ„ßŠšµYèì¶~sîLU}y<Ø„”¼î.<µenxÏ§ÃÊÅm¶¤¸´Ğøá	±.Ì5Ïµğ6j;;À½É,{;ªD¸0ÃÌF…¨¢cº=/"ÌìyŸ¥‡Ô“>mÊ I"7M’J^˜¿†Ô&5½­}8DwÖP‚VíÄÚ€.?ÁVñš]öWQ:Å «— ¿pÈ¡.ŠAÔ1GY"Ï–Œ1ÆÂ'¯»J9õæÿW«hCf÷¯2m>¢öÔœI^U;Xõ¢’8ÈÌçE6‘fG©xâ-Şj”n"‹ihÓà¨Av*mW+«#N9¶vË$&tâWØÅÛ:üd­¸û„ª*9ëã¥´Ëãë¼‰ÁnÚí’í}ûøP(İz&Îá,y€šyÆu¯\ğªPŞ#N´6’NvV4ƒ‘Ó“àÌ¨ÎñçğP,fj˜ê´“úL¬_9O ş7}A-ôÒÙvgªKBwF)ôX,J%p*üA¸`R8¥«îü«¶¨Ùm1¨¥#aåîi‚“»›v²„Iâéw]Gó…Åœ¨ê]ÖiÇg,T¸ÆëÖ<8Óhõz²~%Ï"?·¿õ¶4×êÌƒ“¨ò3®nk‹¬Øï÷·‡FÕŠ„¸“Ó\eöâ¢ 6)c·|¶™°³®œW\yÁ§k8F(1í(a;¼å_Ì°DÃ±è1;´()âéêÚzØ.º©i$Èßæ’‘©ùduîf†»Î¥à1õG@K6ßÔg4PNÈÅğunÙıÙ¾@;²KÁHÎ¿zy(¤â2ØowPàÙ¿ê{+ T©k²)/r­è;¯ğRÌ«bÄMˆH¨ÀÆ8D<o€@s´5ó#"ßô€X{¥¶İí¥šÖH´·òO‚Ø“´	VÖç`c°ª)™ŞÁº]õÅµàs&,ƒd]îH&8ƒDwFDDz‹…¯šº'b,Ò¦#iR¸Ír996ÛîÎßÑ¨#1ÖÜ]<Z˜Œò¤¥€Yœ=»¸NQ•ØgÔ¬£bky áÓìÄ++Ed¤×"Z¢Ã>oŞ™ì²ı±põÛÄ6ÃÍÀjãa†|æ‡¹!|·Â	nLÆ=¸½JŠ—!.¤šP‚jâÉezãıç˜z“Çw{ÔC&á;SÎ#P2OÚ0ì`ìZ-ø­kW<¾3¥t#£×Ï
}éµ-$ï”Äô`ÄEì_å\ÛäãÊ0‰ötû n[Â|FµĞyåaoù0Ì{î ¤|7­h(ÒÔG¡t>An²˜µş €ô‡7 6&Š2 ˆÈÚô.@¶Sj2;Y%øhÓ­«å¬4˜ØõÅ˜›ãñn~Ì|¥éßPê’¢8lwöŒÌÌİûH>s}Bè¡Ù¨¶­¨M´oGç^µ+gÄıD¨5Êãn½>§…ıTÀR>a¥u×Y\­à~¤Ë\n‹í|Åh“Ú>2·EOqŸ¼ö”šyt<‰Í‹#ô_CÿS¿v}½­›å§×½Óm'#–m6J)†Wa’šôÉsqùÊÆ…˜‰ú‰ )±¼{w7å@b§øûÊŒ†Güª0¼\si_+»]¨Ú$P‘ä±¾ÎêùBf«İuB´Va“!:ÅxMAªœ-Ê%^Ğè>¥ŒÄ~eğz©êì †µº%è£0–¿Hè¯K\J#æ´µËLC²Û_Ûr¿ıq D„`qÅdö\Ì¹¾]$|eŒaá;¹¨Ï-Ë»R|íeP=BŒî`Ï_±€Wo4+ãçe‡Ü¾Z…œ»ìş9ÎJÜ÷,›!\#–ğĞIÏšˆº5AfÜ¾iÎÏZç–qŞ[3îq-×ª|È‡ûØ0¯uU®;ëği>"6$Nn•Ú¬¶£ö4‹¨è=—ˆjàd•ú}7vÔŒÁ`°`Óƒ4ŒŠn•Ea’A[¼ñÁ,f@1JB;;Å¦ï0#’Àf)çi{`%üÚnúpÉŸÆí`_ªì
ŠĞqY/“ya`o™Ú^-¾ìö¿B3´ÉÖÃ€¬_‹B…®({À<w-æOÍ]¬…p'Ô•³¶x×âAú”>$’]ÏtÉxLª/˜Ø”|ÛÅjºæ.qÉ+
?úÔ*³8?OÉuB‹·ğb€C,ïƒL·%ÔDÏêWÚ/Ô5NŸ²‹¿$¾¾’¢24*LÛdUMgb^»|ü†¼Yctc\öŠ«’•*—>áµĞÁÊ9ğ?0œÈ]4BIk±JUÇ¾ ·[Ãf=ÿ,ò°7ZZ(·È½ñÄ%}”{F‹¦²‰ÚŞgVIÑújgÈ€xåCüá]ÁØ4/$›ÿXşzÌ—9AD!XH4è~"Îè.|)§½êLş½“Xš{«d$¹NÚq5¶0õnˆKl$Ÿ˜s÷šõ©+a»­BÏÍXÖ$dô<ºi"²
HH!ËÕ@I=¾äl©Kë f¤ÿíZØÁ‹”kiÕÁ^:‰œø~“Îhæ÷zîÅ»'i4¡ê£m˜šÂ©>3›ÿÆÒ¾ü¤Ü€"í¾:2¥!/³=‘dïZ†f˜‘Ï /u89«##ƒ›wGJ^êÉfP)Û`ÆL@§¬M?8EÂHû=‘¿äRQ&Y¸ÊÛ¶Zg>èÊ-ùğ„ğŞ÷È¼äJÔ6 ıÛ»b.Pgé*´u²ØöÜ'™:”¥pÏy2i±ï‰¿ŒÕË+rDçVR|_3üB—ë¹_	î´à¹÷@P4£Ëã!ëØÓ€Öö«ñÂZÁ83à¸sF¸z`5´Ì]	¦i?èbô~_kŞ$	'Ÿ€Æ0“;³RvDö”:c…ß=LY¯×k["áƒ{Æb¹‚€Á'º»İEAùÖ¼ÈªkO;=ßL¯ÉèlğB¦ñ-.<º€>RwgËwõ™
?Úï…Ks×ú2DªàaË.ÇË÷6Ü}ş‡J¦zà­t‘ª#ˆ:´R4Q\,"ôuWábé=ëõ°ÆQ„_b] ‚ï ùÂkĞ"ó)ğqë&d«ÒË²)‘Ü}Ò¹ˆİ½Üsu…s¥¨Š¢Ê1µêbT½M1²Æ¢B°Lµ›¡*Ç-^,«KÀøÅaëaÔô¼.’$TŸ‘è,¸C6Øàº=ßjLÜrZ/«Â:ø‰«S‚2eÁßN6ÉúDJQõ‡À¶¾òŞåcœ ±sùCLlGØAYõğ+=İ±a6KÅ"ŞÅÚŠ‚)H'äí¬€c<Ÿ^#»Â[›®bèB æ%‹¾@@Qy;/Å—SšİÄÇ¹v‘ï­ä[Æhreƒ÷"¸±+j}œ¶™Sw¯Ñ“1Š£ù»
J4¾kğü-lÈ8”‡s=ºÆ ¯Iş:*"†”<¦ÌşlêTn¨šML†bù{Wˆ´by a5iµššÕ˜¹ÃïËuy˜\—èE/}µ“ğ’ÿXÁ@ÿ)Àaâ[G*ékÜTçïV›zô}n&©caÜ{+ş—w£%Ë ÀeúUX—Š)/êŠ—Ù•-®cÊÌ³"ÒÚs‚äe¨¶”¼­“V²tª»'/G?ŸÁ…~}&Ş˜G<ñ-kD¥‡ñ®¦}ñÏ'ä¢¹ÔÈ€el=¯LĞP¬ù6”/aiå(8‘/—°ç?øñÍ>üb;š¹`İY= œ¬ó¼«S·mt›jğ=½}£ï¦`ÖÌdÒ0^oö|@°¥²‰ .tT Éà®ğ<Òó4LLM¾;9U[«Âx®u=»wöE|¦Ê»Ã[Ÿ'`U´}×wü–i˜0TG*KB.bRûu °ş9k†Ä¦"ÊşilAƒªü)­ª>4ÖDio¹‹n÷Ó´GB^tIÃ¢íÉÚS£}J¸ı$oæ$‡ à‘d¢±¿’¨†ĞaõÁ«WùÊ±*œÎŠkË0	xN Y#N¦¦›F¾´ßZõôÑª°j‚–«áâÒ.¤ÓD17èø®nR±¤jŞ—8BDdWGy2È¸SŠ°§N*;05£käĞ>Èı>DD`Y„I6ÜSŒò¿i¡B5åH¥9ûìãÿŞ’Âvè­NÏ\JÌ¾¾u—ptU,$Î@¶ép×ŒÏÊæO@«KÊ5<;b§¨G#°Qò'ºY†xI$ƒ§¼ó3oâë²@©qŸw‹jßEÁj3¢HÎ5îw	è;Ü CÓÏK™‡†ÖQäµ/^7¼ìbÁ—‚ş7íê]SÕf@ÀIR;	í²ƒËgE©*°©MSš¿X‡‰™å¥†Ñr5m>”±ş»N0DîĞæ¿áåĞ±ò´ûÑt€y#MÖ½!çËGİ[·ˆ‡Ñ4˜GÖÈÈ¯0É°ıÖÓ±ª.“ò‡çm€eÊéjJ"vÆÜ1	=éÂfˆIÏºxä©èlGïš&B º’ĞÈåv(b·ís–…Aü.épûî:3Ú©Î$c[Y÷ eo:tò{fÇ Ãx1öcñâOö§¼7ğùÉSÕ¼ThÚjQ…¤r—s³’á2ËƒÁKSÃy/EşÀ“9ã\pÖú¶s#]GÈ®á’°èafè‹†åëêÒRU)ÌãÙN—ä4
VK¯—±Z­X-Y#
Ú¼~Ò»=ë‚%-c9uôpÒ˜£­ßC‰ ™´!·ü…äÙUvAyÜv;wnü—2ÃüØêÓÒg ‹c€‡·w_BÅ‡5ŞªíhÁˆ‰I[@y‚›uBãu>3Ì©&çC O qİú9óƒ Æ$ÁlëO „ş$f¹ÆÕJiòìdÂgpê†ş+<}Á8Ó4é‡ñJx<_F]ıÇÂN?zE"ŞçÔş~ût<x›Â¨°;×/ğ†9qåUöäo•†~ÿ_“EìgÛŒ_‹ÉX¥	íxß8ÕõM¬C @$ö6WY^dåêaü¿¶F¡š€Q½¥}É˜9o†U•ICZ	ÿÎÙÑ3ª{Fça¿U­Ø4Å¾oF_’¹ëòé{<y*ƒ
>”,|ı®°NŞºÌ¥ÂÒÌ÷Ğu(š°ì|ß[Zí$Ã?b3†_™Ö0í—«5vzw­Ù™½‘U‰4l~–ÉYğ~Ö)Ìê‹‘ç—(åıÇKÎ«øÖ@ß1ªíşNƒÑì#\Q7ŠMªòj•É\×ğŒÏïCÂ˜7€ùöM-Ü,;àÌFğäusÛ9vùó¬<¤ŠÏ~Œ”á—õˆQÕ9pÿnf{ÎqwGÅøéaß?æh ‚ğQæ¤[ï¹^AÕZ/ªÒYU > ‘Y@f²„ú¨H?bQ+Åãyªoó6N$)4•©2¦şá-ôL`®û‹pÎìxMåÊºB‚œıDJUÈm
:ñ«šßr€JWÌ9­}À„ù`Ì³É§ùšèwßG./Ğµ€õÇ<Á7Õf%‡
hÑœ|+`ÿAÃ½E˜Ñ›§FU±Òµµ6¢”¡@=ÉÜØu „Æ 8UE<CªIG2ïú¸f8²n†wÉ ‹¢˜Vœ@ºOÀ1ú@@ûú~uÖ$U;£VejÎÆ<´‰uÜJeñÊo¢7™ı,ˆ§àÔ\Ù]…ì…h½@íY ¢ozğRÑ;!³öJ´¶
ÙQÄq1 •h¤i¿ÌC0¦-¦Îó$Â0‘¢($Ÿ¬"Äã¦Şº†‰¥'ŠŒz0™ê8‹ImÀü2Rü–ùq¸Œ0/SA·˜Â4ë¾³Q)Ãš?ö*ïæNj§Ÿ¹[[êUb.´é£	…n\JZF²³!umÀŠ€’V{ë²}«êÓ•ŠöĞÔT>„?û¸Ë¥ 5ç¥ü®^€AÔ=ñNo—ª9 ¸Ğ}$õEYKæ:¿Äµ¦SÙ#‰2u[¯—ÀnÔU´[]ü¼@Ú‘«cïç.èC.­ çU‡BZxãîßµµ@tÎø¯¸H›D:ZsÙ‘ñUiæÜb”¤Tm€;ê_ç=pµ´ñboG]Ë”mîusXƒk@+•n»P&V¬º¾$7IUe+FºC)8ä˜•½›aj¶«Ï‰I…òFT#1p”Ì9œP¼„¨­fvÊÕ“cpÒo•OŒ	A,
t™¡“„®»¿TˆÈÊ©•—×¢æ·P®&H®å–‹¡ {¾Y‡Œe´†Ö,\Ã`oÛÈ™Õj!ñ«=U‘OÃsÁwÃ9Ë£­J1_¸¾Lé¦O‚º)&¥BÚÂà°ÿÂn‘ìZn#Pü‡òÃúPm»YUÒî§QÄÑSßë}
Ár1 ](`)QŸ)OÕe¯Ã¯ˆ/VşZxh«\âvÄ•Ğl`cÁ´7Rå±ëqìV´íıDíœeœzé0ïªoã¯¼M¡Ë×/İ‰ÚƒœjP ÁğŠoPX÷ˆˆÖj`‡ VÑ¿†	%ÙÍ“Îvı«!µqOº{«}Í¤Åè–NßÙ°úËèØIÙòwªRh?YİéûG¨²›@®ÎüŠóPI_§­ºc¸|]|@ÌƒQIñáÉõ¼`)†õô
n’µH½Èr¾Ğv¢_şV1ÈÉÊtcJ˜ê¾¤ßM#AÅP¶½çÚ­@FËCÔ†€ÛıŒş$>pùég@h€‹)4K4á3ƒnvIi~Ï-Î×Z Í<i¢x©NëhšR` W"©Şä1İiÄGTÖ¹êî}ØUAbÑóìŠ×±^»ı(ÔiödúJ)§TIÄPoò!Ë¤Û—àé‰AÈÛM§Á¢L]‚UÈwú©UfDœÑaµşÛåVo0FòºÌù«İÀßâ-©m£,¬ò sætúgbÂ«Å{WáÎ¤´(zOEšs‹İe‚&A	|rÛK†sõu™D­`c:%c“cóR)u@YzzÖ•…Ò.“¯6+–ŒUr&È!ciX]Ñã5ÆÄ¬±·9Å:”©+©ï4Ã´N“W˜;:çÑÆ\ ˆlVÖ÷Gëà.~g:Êy=3I_{!²úD}¯®ÿ š¹²À¿ fªUX°J(JŞşiêßq8ÏoŸS>ÓbF"²Ôoğ@p#²¸iè‹ñ}’Íøc¨_UŸ	P°Ñ\WV¥°in«Ï•´¤ÿvÔ+©…§Íºµî’ºüşr­aUP¹³ƒb‹Hçd¢è\h¹©l”¢²ï¨~==Û@JûÊ nñN¿é¢WCö‹OÍ[í„äûí–k5|C	F-Tn]ÒšÉíT&¡Z…ºZQÁ‹S{	î·ô`¯€ ’PE¸éş¼N†ñ‰$ŞD‰7².ád;jn®°+÷•ƒ’ÁH;
yœGæ÷‰;°Š{ÉßÖTêxŠ­:¾r¡/Òõ¼F-öíNúE›°²‘Œ&[P@$Z¼­åVÎC-´Îóñ‹ü>¼*Gb×ŠSê¥óEµßzİœ·»™¡1!¹­‹t˜DO˜RY0£Vy©Ú"^Ú§‹¸Yà5ıÉòÒr¼F`G7HiíJ¢Qô5Z¹×OôäRÜTSv¦Å,í»HŒh€„yF†ë$hŠÂ±õ£”Ÿ|gù½>©U4—)ËMúiÃœ<˜Õ€uÔ½”<ä×lİä,ÒÁ¬z„A¾™ûõ2ËnKŒóùn›|°…ÓGê-€ñUÚ•­<Xò	˜Mlç0ƒí{ñce\µf×~Ò	™lÜÉŠßuzÈˆ:ã¾æ^’ {Æ–d†.¿Š‘Sûeƒ&Í¯°yGáwZÍF/UØüğM7¦öœuX_ÏRoµ^R¸îfJx–œ­ì#;Ï!o½&Âü¦Âˆ[»y¾jÍÚ¿ô™>„XÓË²ó
´3³å•ãÇˆTî6N%©ö¼ïÀxäŠrˆ‡'ŞÍ¥:0çµYşºÎ'ÜfzCÕ•wÇÆ¿ĞŒ´ö ó<ü=å[uŠfX†‹r†ø¹Ã²¯ÿiËß·qL9XeYg\äğ·~î‘7ƒ&B$Ğ*ş±	®ÙÖ¬êWÑÇ!<ØRhFpÎ*ŠÓxNr>é¸xİø£ÀÇÂ¯Ê&y»	y‘háÒ×†oEs¡¼Ö\G$ÃmÂ¨hæC§GÁÏëô}ùöo]†.WÔš%oiÏ¿‚}:.r’NôÄs5ÍÇ “²—é>	Å²o¬.yMëÒN4Ê×·ö@«ÂÈåUÒÉGè¦`r3Cïq³‰Ê=ÓpæÑMêÛğÖşµ°ÙÕ1´ÀEÃ¦3Ã½ğ…æSXÈßbOW·2ùkE˜q7¶$ô’5Øg¥çTÃñÛÚŠİ°K|Ÿ8ÉĞ:Ğô‹]e¿°‡ÏuŒÍÃ;÷£¾s=  Ü^ûÜ›–Ó÷^½ø¹3‚CE|úÔ¿g'E¢JıqÈºVè~„…Wn/­^§³€µú)9:÷Å˜wë%XEÎ{‘—Ëù¤^z¼"Ùã%ÏNâ©Æ½ÏzËD‘ÉerP<„ö2ÛŒ,Áz½r(³àéÌäø‡ÍlÓÕ]³¢ÿ\Bİzv“ªµ}YQÓ;ô|ÇP‡\·#ŞajoÖ\S,Şâv4Kc
©‘H}ícQË`Á{6ŒÎæì”¤EÅ¥…Ì¤ÊŒY/êtæ¢: =c¤ifN ¿y\ë=-,7ºÕSˆRE!÷?Ş^ìÚ•âÜ&kåQĞ>ØæÎÕ:¶!Ò%`.¤Wó€©äã±í`Èô¾ig~–
>—'È%ôpİİ­ÛÆ[h½i’H•ü[ÓõO6èh³›Z#ì¾d  +¬Š“W­æ‘ ôÊ€eàÈ±Ägû    YZ