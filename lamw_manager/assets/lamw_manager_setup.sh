#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="113294718"
MD5="ad1eccaa47584cff0031db8914afa7d8"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="24736"
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
	echo Uncompressed size: 176 KB
	echo Compression: xz
	echo Date of packaging: Sun Nov 14 23:37:38 -03 2021
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
	echo OLDUSIZE=176
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
	MS_Printf "About to extract 176 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 176; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (176 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ`^] ¼}•À1Dd]‡Á›PætİFÎU}ñT©^6_€–ùÛ…Ââò)'›ªhQuBG«5ï{äyZŠ„V7Ô©|XqÄ¨Ñu³û¢‘×S–AŸ•³ÅÕØ4i  `ğÑ-hJô-ã5œŒ¤×kÛÂîhùf×¸Ë<fm¥¸vÂ9.Ûîgüò +™¸D\Å„ì11ñhZ¨›$ğ‹Çí‚¢Å´„Œ²ƒ=Ä†hô:~zå†¸ÀãïgèÑ¦ßõ˜|ÓMLâK¸ä73KïKæ›ÏKÓ­écÛ)‘™º.Ç‡«—¾w7 ]Húb„-Ø3
EŒ8ÓÑÈi"@Ön)¥_ÌÁ4»˜ígršµvÀ£ÂZh—³%/5×ZŞ9pá‘‚8ª;Zì"]º#sî‘:³ªï!¥>eéOMó0ïÂxµ§ƒ¯¿Ôµ\Wıh¬qI%¬3Ê[ƒj³‹Dù6ÇSjá_váâvÅÜ€	æËİÂ­Á.„í˜ıÏ]f‚òğò RdA_àfbƒ_LÅ¤"ÃşIŒ·_+#¾QD #q VÃzƒŸí‹$ÁÊÜ¼„Ìp1"ÉCõlÄ¬ à¼£ ]^º.VĞ§)ªYÂ<ÅÙĞs\ŠÀ«.ç…w š X6÷®ŠûwâL#ĞûŞæ=´h8¸±³”·ñ>¢pçïè@SUN¹<ì“}€×U””óCïp`ç(@èŞÎ4Åô5;W‹œ¾£
p®"¡J2ÆÙE;rì ,ÌLå	@yˆF’­‡Aòßs¶Å3M›)+Sv(jÉé˜;L
/U`Å ¤|ù‚fFô.z#)°eËÑ<€¨ËC"hS?O\aÖTäCì1lk`1[óôT’•h¨˜rû¼UÌĞ4€¥Şe“ ØÉÖK¹êåêx–ë`
£<Å^X"oö/nÕ9EÏÖ§ìmã`ÅéÖuÄ:åã©KŒ ¤ŠÂè˜{&“É8t•Y.äå@wª¢2*î®°xyt)Ô†EU&âÊ%Ú\Ü¦¢ú—£ü.QÎvßëZáÕ¯VÎ,Ì¥#FÄœMl)¥t¤nØ°lx;QôÎ*!^}¾æEW'nxdi#×ºfi½¯ï]_ÖNá”t‡˜6òº1 ¢×â€^p¿Fï¸âæ¿Ÿ‹íå€7Úªö¸ˆÙ´fb¸ôÒª f#¼”E³^UH¸ÄˆÜkÌ$Oìç@r»úµ*z„·¢åI´(*CĞÁâpËµOÉ’ƒÇ¨‡÷£?ÁÔ_æÜqgX¹lLµìîÜa­£Œ¼'U·¢ãì!ÙcqaˆÄ*ŸŠ‚•eî{²Ë±4ñQ ¼3'g4? §	 Ä
U©EŠXU~‡((ø‰‡i3GÆIyZ]CBÂçeW@ÑbË¼h‡;ô=­“ä#5p.ñıà_òÿ	M¤-×L¬|ıàü¹›KÛWíã˜nH(#nÂ¥Ïä*æã!z¦áCVÀu¯^Êô‚Ò/.Í»!ñÀ¡DÕ|RºçHê/”DZmÊ¹
|–B™f…[£!š—÷öPCÓhÖÃˆ©/à ;˜`Ù“)qºÅ¨£¼‘$<#´+ğH°„m5šB˜Ì’G…Í¸K4áñíÇ)
®Ëì´s(Óœù3À«ÿ±¦ªÂÿ¥å¤ÆlUY‚<~Ò²­rĞ®˜ğñ—ÃöÍ¼Tã$’¿MQ·ºB!IØcA+÷8*á« YBÉ ³\m3ÀF\J’Lu…ÑÆ¢mù¸€K~ÕN."¸¥ÀWß( øï½:·b§ šø©Ã®4(ã«¢q*FÔ/†Â{P¶w)q{?7xz‚@«ş†¾Ø´ÏİÄ„©~5ˆZÛ¢WÎª
ØS^í[É~ÜŞÇ è˜—$Æ'‰‡*Š"K$FEÿŠçŞÚìù€$GåÊÔ¿sJP™_¥¤„gŠæÇW:4P«å7PZ¬ÑXu©*í|Š¿Òeù¯À·G³é2‚é# J ñ°îš·
jĞú¾«Åá<åÜ?iã Àd‘|ºˆ*ÂŠº/.rp8Í$|o§Êãõ+Ò®Ê!9¼A,zœ‘›ø¹’ªŒ”Útfdİ7YŸ‹ıüwºË@İc´Ûš˜ÇŠX¡Õ½{œçtÄ›škä!úü/4Õ ,GCïÁ©šI+†ÄUí/ØOîÑÓEU¼¿¤¹î×ŸÖ6åãÂŞ>·†ÉAˆ,õSŒÀ‹çKêºÎ1O±4l0œ>oÀ<oÔnÂE¬Óß¬°°º_1å=U˜uÓÄ}]÷b_]+Kßø^×PâÁòí#‹óñeˆî‚tšmj÷Ó şmüW˜Ü¼?00~Fì>ŸF£Ï@0'gdì<öãkÿêAN¾p—ì‰a­tMİ'•yïƒ*§N#ì¶	w_Ddy	™}ë+dàÙœw†¦²½"ã¬v…èj1˜	>JëPR\ps¶øLã}^+Å´$ÆCş,=•e¿À÷FÏkFÔ}(F¼Á×äº¢N—(E4ŸZrœahp2iCÏxCMæ” ÓÚE[>sn$Ù«÷[4’ÛÙ½áP?İ‹ËÓí£1VZ~ªaÈRR¿ WY‹w›é^A¬!ÃíiğãV¡¡©+¼™AÖ³ƒ¨æïGÂœü¦Ã¹Fë–bË4Ã7¨e¹ø˜Šh$ç>áMã+«x=@7=µ1ùÈr]7JÑcùyñ"6._ğ$üp
•__œJW¯ïÿŒ¨ú”âÏ¼ÌğujÇRÿ¿Tòcè¨,GëK!Q…0‹ô˜ï¸FEÓ)gôš©jƒDQ´Jâ£V³UœÙÕD´ã0pÏÎÄo¾”a”òóüÿ&0¹Y\Bğıèı‰>ø´8ù>%®B>Ê§»s2¥.Òs9%¾"ãáf©éû˜XHz¾äÈ6_­Ú}:yÆÃÆMÅ4Ñ(
N±=µ™šË¼€)?”âüÒ¯îš¨NØğPª•H=Ûq¶f€ÔÖo·®-¦{»¢c­ß:e‰ºkaáDHw–JÀò³ƒáğ¶óEXÄx¹·8q‚B7­ãVÕ¸GºĞ!æ½9pTxş˜,²óW­¦“*(½!×ËSwĞ»¦6‡ıçYB·ìßƒÉ`öó‘D“m±»Ç(3‡*«¼zºƒd\ócHõ<¨±; Ğ‹¢¹óYÓÿÅ{¿¸{ÏUÇrºB]Ü&ÔWCô‚s¯Àûî@³òæq T¿°ó=-Z7¹Ü¼‹}Vä§¶^e3€¯U… `7¬¤hóÀŸ~é›ƒÿ …‘ÉÎaùY±òÖ™j"x<Ûì!ÛRõ«W±ÊÁX`94P+0yEğ£âpèZìüpŸälğ@ä¡Âƒ¼šSŸÌ!z@Ñ{vÂz41§¬¼©G?÷|Ù4ştùêE^‘œ	gŒšôë¨–B«„]Ïùpre)Ç™Kn ° ¸®YfAHh,ñÂÒÿÕE!uØtlIê/5Ø2Qó9ŒÛŞ¤¬aÚ@7|×3_Ëx‹¾FHFŠòˆæd€Ñ;4ê6Gê¥ËÄV-»™m/(O§ºcüSù` óİö{£íB“ğ} Jş]jßR:şÖ¥ ¨|ÓaJY¢rŒˆ¬¥‹.?–©IçßC½<P:rP8Ü Œ™&“µSÂYLšé¶¹ˆ{ŒH¹
DÇÍ"SMêşÉ¢aöÂp•çn”Ù¨­uİ¿Öz¢‹·p”–oA„Yl3dÁˆmÛ®§Hß9ıUP“uËU¼2n”¹(<âQAS¤"Hä,@¯½¢ò^{ºX?¢•"P2äd4ÈˆŞ«2­0y¤¨¼ÌlĞnŒÖzÈ0$öšğßtÿGw‰noC‰…ïê§ğ6cB&*{`¨Ò\–˜”©K'.“6gÀÉÇzxÒ¸G;€.}Ì
ù”;ÜÂ¬Ï?«Â“-›ör»›ë:Ú·°³êdéIqÿ?õ½$ìkä`‹-¸ÇG·¡^'Ãk°2pÉ5SQØì”ªñÈılËF3šÍ]ÉéJ<¿gzãÙJà‰^«.°6)?znÍYJ)±[Z’¨n|ÇüÚREÛ×³Åux3ÙG)x5ğ3óµÒÙõy¬ìĞ9§Æp~0¯ş)kÊ	Ğ×õ<˜*Ÿšá«N?»yú!³ - ˜œú¦÷ú/q*a.7Ç±ĞÚ« Š¾<Ïœ,£6Ú öÜW‘Pã“¿%Å¨~´Q‡³ÙˆR¢…«ßb?Œ¦PÑ¯C¡°ëÛqNFü5Lç …T´M0Ö&°õtÇl‚Ùf£Zv7Œâ o†w Ş>A†b8"œÏX°CÕ‚É®8d^à#µƒŸ%ÎÁc£Èûwn\º…Üğ#?ÀÛä¥¤¥Ì5T:ÿúg«¦"§nrB%Ÿç7(yiK.7É=\l¿RTy^wÄFƒ<Q”oµ°ë±£nÁ>Ğ¢rÅá„sZa%õë˜¿LPn72I·
r1†óîÜ òìÑKòåm}û:b®æ+èœß‡¤ÜÀi‘Šğw ‹ˆ¨¥™ĞÉâ:—ÙsÔ¦â™É¿S­Éqz¨ÆHL+æåä´‰Í¹(
VÇô½ğÄ6„ÈÈĞKßvg8mI>ºaU.¨ˆ©øÍ¤™»N %\]¥MÄ¹à‡„û¸9Ë¢äv”veõ;N–Rq5¢TC­ú–hï#Í^ãÇö­ÍáñU‚^›´x³½K•´q#èÄ£¯¯GÔÄÁO¢Yˆ¸Œ°få&ºö“¶¶zğ³d·º¢ıB*Q–l™§qø/JY}»5•—VÁfZ:éJòäŒN­9á´Ğ] œCp% ïLK(”·/ÊU?¥MœàŒ$Í§÷¶jJT(wT¡ÆÀÜkoD@î§óğÂ,"+*ğjàs- Ó|ºéÑKù8mZDÿ'*¾’IUgWt;ıÀìQ¿+¸gİzŠÏ¤`ˆ’›Ã«iGlkº*9İµáaŸú<,ÛÏÔÔG< †ÚØ'i™şğ Şh¹çr%ªõûóæãZC§mŸÃ}ªj7éèèÿéR$É’dº)Skª|º„¾¢cbk¶~ˆ‰bË„ ÉM–'%ÖŠóQÙ×ˆïqW°†F;‰½Áz„k/›†ÚU)d×ßƒÉ7÷CÃZ]E8#}c÷^Ç‹•5‚Ã(Ô²÷
C“	÷2)qC/ª]¿'¢ñ8çƒ
Ğ‘ü4ê‹şKÒ_mï\Îzô½”Qšw²ßºHİ}Ö2XŒ [³RY	ñ7Õz+4´4mÕˆ·àÈ•ÒßCÃ7èvMË-ãÅ)—NĞšH?3²LA?¹Ne¸·CJP7»=wÜ©ò xlÕ€2}—àuË%Í@Y¶Uz/“9a%wQ—?I”4«ãç‚´„+OÕÌ€Nã¸y¨n¤í¬‰Ó«Ã…©sÓcQ§V{—½X5ßB•šCõ½ „ªÌÆÌ,§Ñ$C ¿!©†Z‚ÄH”Í8xÉ
=˜ÿNw¹°¹dæC‘Òï_òŞ	báŞêI(¯ £`pv¼u˜œ.Â½„ÔB)È _¥XÍJËüLäJ“ŞµÅ©7¾š¢MîéfFê ‰@kâ‚QXÜÇ{¸yşz—àáï>„Ü&^°_=üè7
¶óëØ—pğÿe¬]™v-¨…3³…=5ú"óx<MĞˆˆÑåÁ*ÑÎlä9¦ôĞReé„×¡—kÄ¥ªÊªÙèg(rŠÆODØñfÊçáa¨ë¦D˜ùÿöo3ôF¸¯ÛziFEvEŒ”pÚ£Ê>ıîÆíƒBÆ&qc)±@]¸µÃ 6”U˜²'Îré´Â?ï'«´Êr^44¼©Ş5¬u-d‚ò•uË±\ÆÃ]DZ@B¡h²5Ì5tv3ñx2 kÉåHOuÚƒ,'ıt6šï®Ñ
êVAÚ
bQl=¾7¿£ì
äáè3À™‡ş@ÿH'”•TÂ^öF¢YbÂëãéK¥×Å|¾r ÿvY¾®½\šfë­ØÓ.N|!şò¤âs5ó“iN—›iqæÉ0Vf>=>æ,&?sË".AJaJŠ$L v|¸w§¯Y"4…¿~ÍÊ¨–érSJLSw
º(Éß¸M*şùRø2‡µî7²£:mÄxØq£Ï±—‡†=ä ğNyŞ1v¢şÇÏn¦‡§:|Ë=I£š‚§±D¥ƒv`!OøõTZ:LA~aÁ†]#ÙKQpŠ­|=ç‰·;T*@ñ73“ÙQ»¡ (Ş\¹ŸŞöv5-¯…¬ÿh×z!ú¹_{4p³¶£¼Td$oÚŒRİI”´ÈúVø½R6-û+Tñ‡ÉtÅHøY®j¯!O“¨Ğ’Bä·¡ôä‚´õ{¬Î‚÷2×ÆˆöÖ™¨¢Ñ”ô9ÕB¾Ìß]Š•5+š^åî¥>ËÔ/Ò¿ƒÂã^iıäJûN¤RƒM}ı3ºÊÓšíæH e”|›9xğ÷rØ‰©#ÄHbù1ÏÅóH¢
a)ö.Øœì2ë“(åˆ}¢Ÿw[Öø ¹ò¯éÎ4ß%ı$²fŠşn¦ƒìqü§”ó¾vÂ>ºYmNĞÀ`n›L‹ôÊS¯+³gœ¢
ßLt–¡§ßÕ¦¬‹p,MíÖtlP[Ûü1° °j›_¦­#Ö¼…ŸÌ¢†O:À(÷İ«.‰Œw °íãC§ûs£³´ƒBí4$j¿+£–Çñq<>±z¸Â%
Q¨<½àšËÃC{¿‹Vô„â€©kMDã R«™aºÛN:f·ìµr¢k6rà})ãvŠô*ÅÙ;²˜øÇa÷:è–)²êŸæ tºİ"i–ÛÖâ×:şÑÎ®¤‘ç[S‡gî¤5®XdID%Cc85šèChqÀ_+È¶÷œúğÄ‚ıfÄF34× $±~F›R…^­"zĞ×èx3@á;Iúœb¤’†>¨ò§{óÆşİb¦_Zç/7E¾1 °³<ÙNK×)i[|)k+P•½µˆb8êü i¨÷ŞdãJÆn”¥è\öaë«A¾½S´.‚ •åÅ¢Š™Ò~Lè$l]¯	³ïÕòÎáéa¦¥Ø_Š)§§4¨9îí2×›ÃdIÂÄ£¥O„d“‹§dZR•Ğ*Wk|ì°8HNêSí^sÁÛxH†pP ‘Ä˜³(¬ˆÄÈq YõœÂ&jì‹€Êµªqª>Ã]b™|d‚kÅeğ\hòr´œQ“f·RxÏ=Šë|i!ËÄØÛ Ã«3–pë~`}ïoØù›qb5—K9›æö–öL·´`ÅÍõÉ…·Dvã&ÓÄszÃŸú¥ÊÖïa,JêC‘JšÀí'±Ğ‚3b†Æk¨üŠJ:‰å •‰¯ÍZ£nCœóæúµgÏoê+æ?tÅSû¹bÃøOígœğÿÃÙù|J	§ÕhøĞÒénç¢4oò+%Æ¸sl},çx[Ü_›3û,$Èİ/ÊŸ`}t?mRÊ‘ë›Åò–¨l£$ÙÀÃzgÁè ÛGV&àİ!Î)Ğ‰òº±mfd²òÑ£!”/ßºŒÊKz{È›Ö±hHA
bÇ€÷{Úßü]¹„~{cyK’•=¨Ğo¡( { à©ê-kPŸ‰túl!`ŠK¡hxñ! 1Nî8À˜“¯'·$ym:¥6İQœñ#!FüE½rµ©ä#ÙaN“1´ŒyCÈMÔï¤©Ş¥6ÎA‰Î°ÎÃ©®¯ºœ¶+&,S,Óùluv¬—à¿ÎÄ5nÌh6?ZĞ; uyƒšx£²˜Ìè¼”³ôØÚ	5No¥&;^åÖ¾€ÿ0©uÃªF¢_Ö~ò÷Òßô×9	ÒUd~Îı'
ÓŸşwJ:M	’¸l/Øq2égC€Šåd8®u	ÜïrÑãfMèÊúJáO£ùÛ%Á÷0+Ú”3¨²^GÂÁxıà|ñ çû4Sh´l%4	†‰
Wü>¨¼¤Ögÿnê·ÜB#_7ğÓŒLCèíJ­æ@ë¼IN'‚‘Ş¹È0…m%Õ„#A£ÖWí·JàÓºuÃò¥×=âV%
1¦]&®JO>˜'‡¡•>F;$¾#oÔ ºº^ i/Ñ‘v¢%Mb@„$İvÚ°†G[Â9ïmiî¾fOşåPÀÚ¬²^C]ĞØW.mM:}È›F">ë# ­úÕAÉDš/o¥>mÏ)¯]éwğõIùzËp4Ò»É7Ìn¿¶TgıÏ¨eZ"=§ñ+XŒ¿TmÄ>¨^…>ßP¸™ÿşÙŒµ 2SA/+ü‚!Î0Øñ¢`[¸-M=ë«ˆ9éI.Ä„090ºeØÓOuì„mÿ©Û$™[­0Uõ(Ğ˜7ô”V&1[å¦E"Dn“kí rİ¾#¾8ÜşÙ{[$XëIû5Ü.OÆ©êĞn4XcnÂXàÅŞ« –»¿Ú]“–Vš/Pïè 3¨õÅ`Êjjz@„ş¨±¦„v6ÕØÜÛÓõfàğì™@Kó²]@R7!êêõšôì2¹ÿA9|*iÕ' (Ø7ÄÑô;ì§gî{¨“í³ÜÒ0&†Íò3ó\™H¼›ælò\‹9 À±]ÍA";<€ıšFonûŒ¡d_B§^¼Òõ¶õÊ„µX,çQ±€–7×¿ íšo7X+¿TñÍøqŒ‡jUÊ÷èloä´åŠ¢Ù´³Y[ª†½%p0™ÃCüÁúúÙïo·ZóçÅ¹ºÎİÉ–g¼ ×Z¤Eí+k'ÿŠN´ßGüÂiÛ™Tâop8^ÒFÎÃ»ğI6d¶mg\‰Âş->šf0?+iWëßRÚš¼>T¼â÷Ô€ªhæ„PáB—¡ÌwU +T÷íçô0»ƒK:ÈJÁïH¬UÌù¦ÔÇ¶²øXÄÚH=/¢5,™œ·ylüŸÒkn&æ¾ö‚3ÀµZú«;çQ;1wK–dŸvá|é&Á®cğD®n‘{³ÎÂè5ÃûN¿˜÷=Í  ğ†ëE¨=À½i‘Ü™Sşà± \×Å×g°’'Lß§‡ŸÎYøüÒÚ›Öş¸†‰C-Ö’k¹bç^ŠxÉˆõ×ş¤¤,Ã3×ş­Mß8ˆ2×A´4O-¶œÑ{CTÊ©&†ÊƒÚNlé!:Ñ„gë·ÂNGÄˆ¸õù~V-¼Ÿ7š§v{„PdÌ”ÔAe{Ì'†/ºÃ4-gtëbp>½|1T·ôå‘L¹0Ò&×Ï1íÇs‰¼åÃ°—'˜ÂÎ(ğ9Ó4™L„•‰½ˆŒHìÙøá5BÊ`µİáÎ’ÉveŠOv.({¼†kCÕÊï·Z(äŒpI#AEc‡Å$ÏìÄ–Ş¯¶u…[áç–~˜[É69¾$®VÆğ[i—İb´äğ×ÂÄuÒ¨	÷?sÇzA}`²ôqÙö¶O´¨*;€áD”á¬â¼w/~LxÜ7ÄjDƒ™Ü7i_ÆÚC®»š7°)nM¨ˆÏl”s:'B¡eá¿,·œ fÔÜ^#ÖFóæßâ_VÍ\BÓÓåÎ¦ÿ¿ÉÛøK•½ÿPB¯{º,³‰%oNR¥ôLoW+cM3ù€ö«®oa!‡ü#j‡“aÓFÉ§¯ŒÖDLÚónM\‡:ûÿ>­Rchşğ&5•<-Hğs(ˆ¢aÒu™¬Ãğ&d'×vJ¥;ŸÚym´c™ò(ß4ŠJ
şÓ×)¥ÖØÉHFhl–Ç”¼´Ìİ»
Öğ,ÿˆCø„‡©.éd!İ]­ÈĞñæ´À}6Å)Àrh¤~Ğ¶$g6§í5aĞî“Œ_CÚcwĞw¢“<’¿®Lwœ.¾­\.ƒZêfNBTÜÉ0j™Ì” ËË7T¶±²üW9™Z7œ&'Zè€€¦k}ÈäK5ñnÆƒU¥u|ÂfŞòe ùA¯¿€v:¶9Ö`CxâµiØ&‘³*\ô’_Èiò•ì»€˜9N½Ì™£0İ–İÇd®lR ôìsÃß¯“uU¼ÜòPÎ*=W¡äÙ‚tD‚ªRI“’EåIqµ‰ä®Irf2cfíØpG…:UÆí²~©SYÁœÌ#/Šü,!Dü_I³^ĞhŞ_úÜï:ãTØ¦ö¡åš†…£´TîkWZ¥ÏìW˜ÈŞI]“E„T_÷NÒ÷]±8.‰åıDª+¬P,šëÈJ	ƒã²‡‚ÙT÷~|+â/¡Y:8GïàôŒ1i“Tê[EsLê¥_û Ö#UašœÈWæBbj}#ò¤€ßm`f–7|Ö]¸+ïQÆ@yˆHÙ£í(ñŸÈÇ›Ì½×”‘8.~ÁùmşƒbRÈ¸pyûË˜ûSãâ+oÈ×Å¨Ê@©ú‰`-À‚[W|ôP>íĞ(6k„%—
ßçÁô“{_D½¡AÚÁ…˜€B*ì_±RşšŠòúÅB"îÿ{½‹f³`u)rU;Ëhµ“‘­ö Õ!Æô
òØ\.„…~Rõ•-VhB»wu
„°áv²`s™Õ‚Y$|go‡Õtìóëñ¤/(3ŒîìíüMìZ^\hğ¹ˆjUû¸ó9 Ä{Œl
AšÄáû%êõò±ÉƒI?å4ÎG¢Ğ£à‹©Ì/üç‘4pyá|Éñ›©P[B)f¢'
û¨ÀÁU’åÔêÓU,xÏ•^™´t‚šnÏlûVäQï—iÅÊä-“è}OAµ ¯€‚FÈW£”'ãê‡ÔX‘äï1~¤0OÿE¥ú"©d§lgCZh´í%ºÜØRÌ”„œbx¸¡pp}Äà®øÏ¼t´—7ÎÇ2v¬Ş³SG¼SĞ<,ºøŸœ¢H&ğÍ&g¿Û>­%ˆˆ=6ŒÄhÿ £Já+‚m8ÍPÆÖ»õôÒn;•ìyş+Íc‰öÄy®IòÃqFŸá™ä*¿svGùÑŠç)Z¢S˜Ô=·Z®ùë·µpVú¦„ã\Æ³}Ö©vıcpûÑÕs9O‘e¤¹s;Vkt@ZÛLœòİnç³
Má¼ÀnF«|:Äz‰.<Ïøç Syeuü¯ø§ùu‚^ø ÷ºµÒñ[w­ïè(8¸±ÉğÕO;mAÅ";æOnÛIF¸BA&Pô&rdtªCLĞB˜j	M| BFÆkÄ´"Š¸6¦€gØ´Fo?n0V¡%É[Ü©-*EIo¼Úä¨:æîm§ë Pö¡ä’@yé·µ­K,l3¹³š‘Îj³(Çº_»uîX®:-ı1SDj1)„È·;X]W\qMcÕd)AØÆÈÀešıbµÎ„¦MšÓŸzpÀ×î#d=áßÁÖ,Oæİ§‡éş	î¶qŠ6µ‡:T
héPàö™ÉĞ%=Ú4X¡¢Â3Èü™ª®ãB20·ØPˆ]2?›^ğ{£êyŒCgM?³;îËãMå‰?KÙœîíÎ0L‹Ÿ×2ë;b¼İ„7#©¤\š9úŠş8´å–MÇé«k.»±ÉÇm¶eeU»"QÄ”î«"bÔ¾˜ÙÏ)ëy_âşÿN‚³Y`S"Ë4L,@’á| …™Fb[Û˜ot‡”ãa¯u‡W©#ğ„L
Ñíb£—“sM¯ù{ËÉI—mtpx3•äÀÃÏóÀçƒj•Û©«2†ht¨	¢s)X9ß3¯†d!±tÖçæÌ-ª°‹íábPUçÆ@ŠÑ6ˆ»™Rç8v?Àál<×­8ŠD†¸_ÃäË§‚p²w¡™@R³•€èS&Xÿ##É‹}ÄPêr*’u‡ÙÔ@ºï›ÍšX¾ãwe™·© ü:v•®?úªè¤FMskËòaIGœëHz¬9aşŞ¥Ä~L$ÎÒ¼oH¤CÊğ¥EkO…O;³Ş±·«…nT¹àbÉËLÃ IÃBW
ôÔJ”†Ğ4‡jÏ9rR,ÒyÉ¿ò.Ô÷ØC¬Ğ­ëLôæÀ5ÆÆ`|BcFãô>®Iá—h¥ÁóºÛr¹ã‘Á)ˆÁ%ú5:¾~ò‘İ„f…ÿ ñJ4au¹g)#š¶w»äª>Ö«µsÓq¦ÔWWK.é²[©c¨²Ü&í*_ƒÍnœR÷Ñ_8ç„ıìkĞ+}Âb &Å“à_eë-?Òƒ²é3"1_¦Ï¯Ü‰&E&U#¬<Ã³”k\&ºal80Ê’ôs'f™¿Š6ô»ó•äfç³ù;C'¼l„0âÎläÔÛ›4¼É[À¦z¤ˆ××3ş,RG¾œQm]«†Hİ>®úÔ1øò‘¤®­é!VaƒrbI³ËÉo‹d|\í&_Ò‰T÷qPFÊ 	ÃŠ®Ï`gl†Ãñ²œÅÄŠ<×:FÛ3T¢U…2ÃÂÆ #Iœ Ys·|\7±6x¯_Üâ!¦*×vVeà§DŸMØ–*i+qšoH¬ïñÏÈ!E£_!ĞŒ¸ŠÜÂa½—’M?Ò±‰«Åö¾I>{ÇpµÑN¹2_E—¼‘qŸMı¾,)îL	Ã¢2¥çĞ/Å®¢÷|I„ì3Gm.Ô½C	ú9È2‚®Û|Aİï¯· Å´˜Eğ<²¦X~ZM"“¾;¼ü'üğµ“@½ìíá-1ï°tr/·)›ã½ß'
O§"â)ºÁÊt¼|ÛåVNĞ·¢úÚ©dëèBt·yÁIK¿g³<ŒÄÀ@äş\Ìjb1on˜°~Ê7'Ø=?¥Ó 9µ—Iù0DÎş½áÔ\#è]
r»–e,%41ãˆÌŸ°ÍùkšàÈıtı—€™–à¯a£s;>jÒ›ò~.MÕs/†NTa½ŞÌk…¨åı?‘{ïta‰LĞ˜V7õ~dU$Ï„GÕÚ“±Ç55s*Ï¥BÎ«şç÷ƒ&#Ÿ·t]Ï‡U^q¦K™óİ¥Ê’ ÄÄu vÛ¤âøÖœ‰Ç#•ÜÖ9 «bİü#¸Õ&îÎg4“d¡¹w9i£+“{8ûû¤¢K'“óèd9{ÌØ¢šº²Q±²¦s}3Jl[èÅÙëê[¶©…sô^bíá·BC¥æ}ªŸ%§=ì°»ÿK8&œ€Ÿ¥~À?BiÖ´ûÈé€Èáy·xãI¼Jçfò$È!£äŞÇ[_D8P“`kvZ†ä’`&„ÜÁ^ûàbÉŞ :¦l+!˜;8†‡ı[n
vèÍæƒòBÉI¼;ÌÖà¤Ñv™8 ñ‹<^,q¾ŸF,xJ·>‚VÜxPõ’ìÜMÁq¨dNµgÈ=7:R23’›…È^ÅŞ`ŞÑRËÀ³ÅvBTßÃ¬˜—´éUÄâíp˜6'QRã®)Ò-…é°¢Ğ÷©H}À1O²¡mÈñÄáÁ´u%üÕU ¿æœãŒPkİ{håu³	z•îí]=!À&ùîRZ‰* ¤‡S'`HÚí+Şkû!XQFMĞàõ¿‡ø¿H°{a©0.¢Ë'†Mªß×•ÃN¾İ¾ûvœãT¼ÖûV²ğ 6½r2ãîÊÿ‹;-îäÛm˜wPsÍÚ½˜Ï¿“Âû4¼!rµ*+ä gğ›o&¤¨ü·Ä*E‰ãœÅêäOS ê<ŸŒLeÃ	œú&SàDANWã§Ôm#C3nÎ—Âo•üİ¥l÷€†uÕ¾™Ê&Í^ÎÎx®‰q†¡Ö÷*Ö?}&vÕpÇô¾Æ—ñO7–=‚ÌÎ(-Ù£­6ÙéíH]ç§i[¿t » œ`öN%ıLÄPÜ›€¬ ’q u n?j Çª¸9©Œ2Ñ}j>7L_Z«Ö"Æq™Ëğå %p¦ú7Z©ì{5Mˆ“6­TäÙWåj~v[O!Q8L©çqìN°`¥’{sWù0Ôße†63®Õ"<©ÕulH/RWlˆ4ŠÀô:@C3I$Ká$y%³u.)ŞÑÁ0z•k!½Gæj´p2º”:•Æ«W9<dKg¥»Bà­|Êï‘Ö®ØINİzEvÇ™²ø÷|¬x|4¬8‚©¼˜Îj87Éä•Í|[¯] \¢¥ËšqN êÂba-[!XÚ~¤×¤ ¨®,O6/Gg´›”ÙĞ~‰†B]ø½ÁtIFU;Ğ*Pí@‡ÄCÆ›¥ ¡†Ş[ÉÒCÿrÜ~‡ÌÌ.‹ÃZ.°ªOLkŸ¡Ø·òşbRr^ïhõPqìKyÛO«K
Knq&Ğh|û*0’Ÿ~­µ¨-8+ó>÷jÃ÷ÍY*›Ø1Ê\ï×³ËÌè{_@@n¼³ÙÚ‰ysÇ¡dêÁh™B&Ñ€pÎÎò†ŒÂ£ÄŞs00ƒó¥Ûxï=ü[Œ‹h›YĞ×YFg:ù%İÆ*²£ËsšBä/.jC¦Ù¹¼ÜnzyåÀ;=A7ñ&#wÿf€·0ÖF†3 . 3—ß†¹^Å+ÊKl/Zà.iÚ#ÁëãîKb¸gì}ÙàU
r¼g0rü·ÃYFQÀ…ì¡ÿˆJ+é<pŞ>©—2í×…bàùZÇSÂíë¨.‰V³Kò¦¡«väÕ’”Ä<|Ø³lïNuÜc2Hÿk7~ Ü©Xé£Bµé8ãyf0*?:ˆìL£Ã18%°J„kóo“dY<¿åÙ©SyÙMC}õ¹œp­Ç€YÄB±¨‚&yá~ëæFÅ¾³óİ¶Y×Ù§Jßš"Şi†¯Ş#Tuûy¾ß.2ŒÓ‹ùe"ìë}¯NÕvÍµ™/%O•Ç’´'kFó!©Á¼½Ê§æ!mD©îíÖ÷SÔû—Òí .Z¶ı®FÑµ½ìjCÁeéŞ{Æ×à/lpˆm ş>æ^¾bVˆ‡À"©› 1şœ!¯J…ÙŞAz )ëJçèÀ‰=tqÔæbd©Â-ÆE5kVMjVÑ^•àgIŠ5N€YW/C©gé½:Í¢$LP~¼‰Ê)]3(Éng'÷œ/‹³"éß‹É(Óã=0åQ‹Ù¢ ÅJ(K¹nòĞ†ÜÇ‘ üå,ÕI=t˜©˜"O§l[³]İhÎ*l«Õù¯  «C>®=m­ã"$uóÕ¡{²›X;ßİ¹s	AùJ…§À‹?d 9ûİĞ™RxæS¿˜ªr”„oíêÁR{7Ê£×A”y‹2ØÔ—•ëë’œùRº¨ù„´´„úmø•<§9¥äVõqSäŒ x¢|m˜s³&œ‰“ÖBI×ƒœ†>F/½½ÌCù>UlÚ2uä–¦ÔŸÏœ/Ù…RyÌğ„‚À@—Şè±¿ƒ¥î›1Òë­qÕ&¸*Q± :æŞÀ$ysÂå„En`¬ àzÂ×•êÿ¬pç³N±FÔYà$WÁ¯ï¿6Ti_Rl4}ü"œÅ¦ıÛ¦Òğ?0€Xæ…ò
um:òægì½BÍ\ñyÆ5–NÂäŞÃ‚ı
—2Yß){Q*^E³üÑÊ°VÈ÷U0Œ€¥¤¢{ıé›U5¸(-¹?ç÷úËq±E®ôSn®1-ñ†_fÍiJš¯w­¥4Ë›AÀ]•Pe_áI½
Š$´`§²÷äÙ‘ó¢¯¸¯Å««Q1èÜ ÂÓbG‹¢`€:•3g vÄĞI+.DÍ}ø‰vDÂÀ²“ÏİA<V¨ü•:Ml3î¯Ãà†`3°°•Ğ%¤	xá9Ó¶_Õ×Ëeö€Œxë¹f«B	A$a­:¾DìÊe)¹Ä“Ï”¬âCÓŞ G¥—>b½+ÜK'¿TS!gt2xÕÁ²›¿lPfï w	»3È×ììƒñ#HQ‹k,Æm{Öññõ„_r¦[6ÁêÚåÂ8A óY9£hGl—UÖiô.fx§›P˜èŒzêé«@`JÕ17úo3’®|G_şs‘.gŸ0=Jº¼;oĞÕŞ¦ëÁˆOã)Ùehue«VhÙ6â² «üšæ%”7lA;¯‡”Ø‡²Qá¼çwË¥Ú—£²ş€´Mã†Ì)HmÍ†X«ÜSàù%İ†ÚóÇnŠÆs¼×É|ˆĞfslK¿{Åíá}pa[`£åï
é’Cçë+Í¿1°Èmç¨wÙ@‡ÎTYEo`bšzú•)UN1.ÔÊ)vc9+1qêDí%_¡¡|bˆ]ßqİi9a0êƒó ´VµŸbşËDãvšS°GéŸÇ–;xhÒ euv4}9¬­˜§RL ‹¤¤j5¢ÏÉhPpâ«¥0@şLªPg=åC°æ6â«ıMY:ÿ»›…˜ÈÔûi6Áıæá×•ıĞ¦\ÑM­wLg[Ék<ˆÛäU6Ny-§2<øj°Š–-pŒcÀFKRf(mÜŸR›€<Ëşf·ö¸5Åîú“,®‚¡£pƒ8V²¨<­Q^èö6,;<İ+lWŞ0†„jªºƒ#4eÙ®0ˆ;¹¹øµ=&”â.KlâAzÙŞı5ÇÛ·ÅQ/}¨? üüÔfğçd£ıÑÃ¹ŞTàÈùL%•ßÊĞ)Ç¥í+¼æE>ıú}’¡iæv’5PLö2.¥L¬I£óê‘ª»GnPân¾2Æ3g­æ.¤r-º7Wªİ­ªp©é“!X”z½F+'Ç ÒöØIb‡Yó›m›æ×µ‰o|í¾1¨±c®u–A?úrƒ'?Yä7©Zv1‚72Ò@ˆ!]È,Q‘˜ºEáÎëíuù6Uä2¦Eˆ,LC	ãI»ªÎ'Éş<|-âsó/Š¼—n·ÜÅ×«ğXÚ¿ ÿ"[ªúãé¼ìu.°®óvÀ,¸?ÕårşÚsÄW¸	ódØ»«c@9\/ä3ş¿SÿL™–]²|Ôœı5u-' Înc…Õ'Ú¥yğ‰ù
šŸ«§H–YÛ
Ñòà‹A¯ß­İ'Ş¯XÃÈ÷		1å¢v¨Ø“Y}İ_°çG™Ôğù¨Û™râA+ ü¦Uebp’ñŸíUl­¼°À«€™C±ÿ×w6,\t'ÃxôB+>§‚×:‡}gz¸C™Ïœõn#?uÔ4ÊCN¨
½Æ[_xÀ„BXÓó¯A]y1Ü`uñãqyÂ‰)R÷~ñùíÛÔKÜ¿¨­Í¬J¸ıV"rFïÇoïkK¹qğ:LL_…Ğ¹¿ĞèïµJø;/ø¶]ÆÕ0•x]Òs»nd`à‚û`Ró¢¯¾4V9x0ÄÃ¶D3ì‘Í¿ı¨g:b‘[iø<Yüy-Çú`ßhyfÓ=vìÓJš:'6ø=q‘õÂv˜†äÖwqd†Î/èM?}ÖÁ˜^·Ã ’º>štŒI–å€±‰—mlx¿(tqA«ªñÑT¢¸ÒoM¬é›ÖRğ ' ùšív8¢ÁOŒş•ÂhÈjeğ¬lìDéÀıJºÌàÖQçòÔpa¹Bıh5(Ÿ¯QìÈ£? …˜~ó/ÍZ¤Æ§÷§ÇÕi{¸{Qÿ<ËUG¡ÛÓÁ	ÚR¼…8¶u"T.e™Œ^¢÷$^i<;Ô²):ßaí"—û‹pÄ4şNÙ[CyxİZh’
â ¤ïÅw,•4û	ìè+jL%ÕÀëêÓÈõœK¨wx#á[cS¨«N×¯C5y¹ÍAâõÄOí¿ïğæ`®p•[ãÕ…*Í¼\ıf70;Ó|qƒ¹qKÍ³[Å.rÈ¨Q‡öâİTêqQQ5C»ŸöÛìõ5²g†Xeùë/QãSî­bİ‡˜·*vı®!pºİºÚjª›½cr†âS |w¸.î
mêÅâUuQO!Bmbg<#€eÎõ[wÚŠ”åÍ¡poğÙ€5Ü=gÀj@ãvf?ûblE}…­Ú@ÎOÇ9’ä¬FßWÒ)‚Š·œ·±–íÙg„¦‹î§ïÒ¦è˜úş¸é”OÂ`oŸTaM¸ÿÁíhŸ=ÉµDÔEÎ¢+”ÖÙGÒã?ÃJŠÀİØp[³½z˜ÊqIÂn¢ZÄ]‡¡ğŠ$™ßËô‘g¼	;İ¡ŞóËÆ6¾\YÇ¬4ü¦Ìïî–äZÃ&;”†¸0ô+#!3OÒX­QšµbN~<
ÀçôGt£cN£v†í„ĞÕj~‹,k¦M]éòp´4äôÑgõ%œ–Š’¡ãœHÖï}İ¥h'$·z‘Ònç¥x_BE”›QÂÔ2dD¹¡†.íé6¬)–?O@HBÆ!¼\ìØ^ÇkÎ‘?|MW?ü´¤Èv¸Ñø_9öF’0hZ’s¶ß¯8lÂ"ªš-]§ë‡hmİ€‡­éè·±Oò·Tì:®‰\Â|) nâz¥Ãâ9òO­Ê]{BÃíóíDcÚ=DH½"zl+	¶»N\ cWg©¤"&ñìYz€ ƒğ"ëÏÀ;gK;C˜Î\ÆêñD9ƒ“6&!3æ%eX¾²fU9C‚¦eªáA,N9€T4ëûßâ›`|Í8•Š]óÒD‘Rªâ&Š!IH®šŠ9Â Z’«Ñ@…kvq+ÖªC\°5Zv±'‘Íÿƒ°[Ç0¨Š›œ@Ö‹ÒHhï$§óAbzŠhNs¥OªôW8ê‚rGöœBÈ*À6o»üé¯º „˜ƒ`ÎÉÓ¾Ù]fˆ<íy'Ş×`æfİ¢/ä€Áfı‡R¸	ÊÈ¼~€Úd8T?àJÌsV8eÅÍ
§Úı$€”ñ¶Ş&G¬MCÖ"ÒqÙô²€k…[Tô]ì)º_DQ±QÅ¹ÃD§U†«†ÿBhFSC‹8áx¶L $®
Ï\ƒ©©¸^Jê?¯µ $ÄP‚JŒ~vtD}ÿõÁ§CËÙ.ÎÍîå¬!—f[B×‘nTéüaÖ2p©Õı’B}¦–™’®L‹R(XªØvhÓ1á,³µ=öÖ·ÄWdÿT9ÁÄJ£Ãõ†3{ÈY“¿Sg­4š7$P¨%½CÇXÂ›±v0Sp­zahôŸÛD}—”·I¶ãMLŸÁ:º$`X6AŞrû‚å½É±yÒ¶g0“m¤•:†¥`N‹¨`CàbÿS®î›bş/è#Ïå˜<¾'~?MÁõœÎŸó1pÓäïTAèıú<Q@é’½@€ll†Ü¡'î·Cì¶™4ÿ ‡ÓÌGV†Ğ¯Bšì9„­û’g_ˆ†Áê"ŞiIıË[‰,Û??É¡,ßA9ë—9a§N¾	„·ç™ÙÄ\ÖÿØ¼Ô{şÁÙó¿v‡‘FvÏ:ƒ—Rªªrÿ
2®µÚ
å5º7.hqP¤Ö	2pŞÚAT/‰TLö±!z¨Q¦š/âºŞ˜#zoÔ
YzÁ(oB6®ÉVúÌKR4áÅúŒœ}GHkm(õ„BB°¿–ºÃñÅAû)¶8K˜^îc²áW«ïÙà×¬r{l
eJñ&Qä+øg]·ò»jq?5íŞ»àmŞê¥L~c7¸oV#“ÌºÍÚØÎ„Q‚j ,jqÔOrØ¾uçæJUé©Í×TÜ^#]MZ…	, *ÿàÛ¼ô/ì„ñ¯¾%Épä!NfØX‚ÉLÖÎ-L™ıœº"çèÑF*ñ¬¤ÓÇ7báZ™ü«~ßMR°ÆGçóxsv¦
ƒ‰H|œ#4¾İÚï×<fö¥¿ÒÌ ŞŞÁu"è±¦×‹/¸Å‚«æ•K¿(¬0 ¹6ıÁZ*
ò‹<Û!Æ>ªÁºcá¶½ÃæXËòuüyw›Çƒ$æãg$Œ¼§Ğş|êèŸGÃãe4ğº`TÔ>ˆaíAÉ$¼=„U$ëa	ÂÍºoş¬ÅéáEìr«ÆIëŒ4–c¬Ô1‰’2¬Ë1£üCİ_Õ”[@Ë~âá úá,=ŠkÈL5Å‰ú¯ëè¼Ê9a‘
G&çÏã 6	ı‹ßNÒ|…¶¤åiµRáv¬"xşd—æ+XGG”ÚäÓ:…`°Ş}ÜZüJdP6ˆûYÍ‰öÚÚzwßs|È±É€zªn”±Ú’¨ÏAzOÜ}Í·¤ß÷RïeâI¢Rª[7Ä=IË ¿c'RpG1bâ8O÷\}ìX”ó¶ãíÄ¤¤…€k9û$u…\
œ”ƒé«Ù6™™QMàÍŸm[¬£­ÉKØ'ÍIîbq_ôòI?òÏ¢å7³¨ÇOË¯#…jYTM¤_‰|è‰ÆË¯¾ÒvìQ1jƒ'½ç¬ı’ß†›ƒ±QU½7ı¤NÑ0dÔˆŸu5êKé%Q(4&“=ôH¥RLPB×ø7é¬›Åæ9yÏ\;™Ç[êÀ‹º+=û¢OJ@ÈDûÍµÑi”úÓÃìÉUÔkğÃÿ\GhoÂÓhà&Ü8Ñ`s‚D‘»ñ³U\Ùë‰^w~_y9ét+R9Bıi¤ç¾¦BS¡ñ‰ 8_¢’ïœY¾{‰¦îÔ\´EŒ'2DüÎGàbz[÷€\((0¿.?—MÖoÂ…— UêrnœğµG5­\ã.úı½k4rg‹‡ü+,9ü0üXêóŒ2r™­£Î_¼c/?ñuÏnF3ê›Bâğ~_Z…ùÏSâcÚ˜:iÌwÚhâ•™4-¯‘³Õ*`x\ à'œªÜißM}÷Ë¯&TÃ¡ÍH²MNãŞÊM'uIcşÕNÃY@ª
aâŒÜÌêOíLW ,!wPV,LWªi{îêŸ–İ9ª`ÓvRãÈ2&ü «?‘z98.ëBŒî¶AÎï0 Ofƒ5Ó¯Å£r´©k}K›Kİ:«d”Ÿ½ò@ÿ_ÆƒÒx|•¸x®vˆáÇø©ÀöQ¢’ı)ZˆØ™y¦ƒˆïaıúø"¤ÿB¤0×;ëÕyóFß$E –/†-…3` zÎZúV½N­nÁ
zyó Â"÷0Õû}j3™­¹¾CÆ1Â§ÑCÕğÂÂ…@ŞrDSö¼™ÂFòİğu!˜
iïsf	Où™S7PıÏ»û%“‹t'Y­d{a’ »&®Aûå°TÌÇŸÈÅ¬;ÆÛÂÒç¤¾:ÜÑl‰6¶UênútşuàºfÛç‡IÈ(‚k”ëØ¢¶kş\İš:7KÏÅ;;—å)Ù¿RíIEnu\YŞı‡V|?Ø x®ÚHL†X`r—ıtw¸œÔ›tÅ[Üµæ2†'™$“PÜƒÏ-o% éÃçYÆƒÙ¾•ôR•ù·q¸C:ÄkÖp±2wBÄ‰9Ù²ää:	ÇPnyWÃ¦&õ¯Ò*¨*-÷®-l„Ò1Ìè¶±ŠpÔ9-Á=2Xf™ºê1ª=0LÛÉ.9@K9u½:ÌÈ‘l:»&ğÈÚ,Ğ$Ñ,.· ‘­Ğà«Ù9”İE êæÕ‚£[Q%ês»²k[¨)Õl´Lu!÷ğÌ×w©åpªŒè/T üüíÈ*Ó31A½/íw†ØgüæT¯TÌ"şUYË Â–Ax3­€â¤•ÙLx)ó"NQE_JŸ«ê€š\4#°Šk°‡?D®¦Oµ¥}^÷³àåj¢Rî%ÈŞ’e•/d‚ÇOÿV÷È¿	¿Ğu€3úF„…´L&bÌ	£ÓÒk]â1â:¥ÆÓF‚»T?¡°OşÔª§z¡G%äö0¡»ğ=ßr¥0¥İcd²*.‡ÚşûFõşÊ„M83^šêóÓ·+æå8B™Ø·¶Îû:Í+·DâSE›èÍ.ZŸŠZë¼W)3H˜¢­>_‡zğ6ˆü´¶^A í*\×ßE%,&iÇù?Äñ’fXÜâ+ÔïEU2{·¬…|¶±E„yš•°J?ƒd[©aÆœt¾ÄúE¯şaHl­5ğr-GíÀ®È.ºEĞf\</é¶ñÙz&Øù\mÆ;¥Æ¹dÚd0«7ÔvIã*Gğ
¥}ÇŸ°‰%
Á;|$¨zÁ»ü38çÑ–‡†ÖÚ›:u†_2@¸8Ü¼˜Åµ1è;³°ı¸['ÇÂ\İçJ…CCÂ"O:=áÍ‚~•\ÉšáóM­îÉdë§`*‘™³éA8Å-ó¡²0¸Ûá?"»&àÈR 7zÎñ£UYHN¤JÑLcµØh×Òğ _ÉâÌüßtòäûÄiŞš"Hn%ŸŸ¨¯ãÿxöˆIŞkØÃˆã6+³|w¾I„³ ˜ˆ­Æ,w»»?ŸêI¶XÇãğ@mõÜO@ñYšœo‚W”%ËŠ«j´0Îeá1»E‰¹V&ÒÀ÷á—D:i)¿ÃlS~E,V\MeÊÀ–kÆ‡¥•|b²!!ÊTİÆAÛ™Ÿ}}Ãİ×qø-*xGü#ÿÌÊqê+¾~§Ï0%§Ï|D² ¦3…‡Ù4/:öCÇÅªQ-O"5¦I"è&·8Ô.KUæËmºq_0™/1ï~Ä.ƒ“š;¿Òò½äRÖ&>ôÜ´ÅœŠçˆ’·AÍi<©¼ãˆO­à`Šãàpgb°*uÖìt&lZEçò65,€¶8İ8ìpq¤;ÁrY!¹Q¼Ë…Ærë­1‹½ô&.£Š<ú§…dMê¦D…[8©‘csÚ â3ğªWøƒ+Ãİ¹ÿµÇC;ë#ƒ`Æš ³Ğ7Ë^ü_cœDè`³²,Í+ÄD®È\ú3¡·ÓÙ]ZL¢â6óJÓ ˆ£”VŞœnãfÄM<UîåOdc±À•jä÷Ê<²¬Âç†xıµÛ·2GÉ	#	ãˆOoŸ©^&T¬œ zá§–GFQ0_ò©ª¬D^×÷ü…]vã´uı°léÊ(,ŒcH©îsˆ/.|„7Ú©lÓÇ=•‘/m ô„Ct–*0ÏÄt*şIÇhjWÏ¦Ê(Fö-i ÍQcşßÆ‘…Õˆß{İÕŸr®É¶e@¬vÇ–¢%±(!ñeGV–Î4GPW p÷¡.c/†«SÁëZRÖN\&+¼;º÷»­ªúñD–®ì¦îÑú‰fvô$e‡[ŠMòÜo3êi'%1t5| uåÍ"ì¥›IQËbÀ‚ñÔ•1ˆxöì)qéŞàk¬GËš>o7ÅŞ´ƒ"?ô)ÿıãşŒÁásL¦İñvD4#(øş40K4h°Ï&İ/7Ãr{<ZP^tŠ„ÕP“£{™ÂAQè	^XÌ)6ç]7Aõïá^á¯«¦ğ>'4x;ÕEòğ|Œ2š“¯è’‡ÁÀï–[pf–ù“wgÆIù‚RôşH­.ºƒèù‹”Òh.©U/ÆÈÛ”á:˜Mfd©ÏuÛX÷ˆtFãJTë•*j	YÉÏ4UI€`%Ø'ÙÇË³CoşäI$ÔÔÅÁğ%Ñ@¥ÇğdeÎ!-Ì•~Ã;bAAu'ûŠŒ¶yÖ9ò0-D»àVµ£ı9ÕÍ„½\m”B-®PåD“am9\,Ó‚ãO0£“ÏÓø,5ÏĞƒR«ŸıÓO!/ú8ëíŸûÙó¯ûì¿ÆŒ€huyvB‚âöh|!æq†Ÿˆ¡×>üİµE;Û0Œ‘7@~_â¤pUÜ‚tESPSÌù²œr~œù8°kUşn©*>+wò–p)–×+M]S{räŒ)—…C3SëÔ4¯²Ş¹iocº[Ş©„Ø·Å§–Ñ$»©æüEŒû L½«ÈQ#D…â? õ•ï¹>à!_U¾i#1ÌuHæ5¶bûİVjõ5º7™ñ›ÈÄØ3 s7¼‘èÕb—ú4æ‹bßÚÀÿy„DŞ¸Ë¼½w•×BÖf¢Ä‹£¦©ûq¨dÁ%éüİTñ—‘ó2pçš{‹Ô÷é`útâséûN"“¥š+71‚šÒî¨vEË½GÌU³1‡+]t³A¡‚3 q~¦l„½V¶ù™C4Ì?å?Şv%9’Ííá×úÚœ‘2ó“3@Æı`ŞÅñáE(7?Ì	=Ä…ïóRÈQ¨E²6–ö9±Ï3™ä‘A/¹`	Ù‡´óºc«Ê&ÀZ_ìÁá?Lªn02Û<hIOŞŸåP¿z™cèª/Bfìò»ªÒ¯l0:†Z-Aµ4?İÛŞãæÑlJ² …¢¬1|=tåÒjÎ¿Ş´¯{5m¿»Rş(Lbe×#àVº¹ç÷yÃÚJ|ÂPÓuƒAI•}Jè”lu«Œ4)™Â–{{™PáD}5Çc²ú¶x<¨#şPáğy–†ìö¿ĞI
&ˆp¨9væÇV%gTúxe”~¢-k1„`ˆ×Màß`ït
€*0gàVn]_X¸¤P²©»=—4A tÈX¶uIù¦_‚¤ ;í?É£HŸ™¨x˜«~ÉÊ¨üìñ+‘©¶Ù²©°F!›0¯ºH²±ÏP¡)ìLê´Åa‡‡‚»öÇPF4wsœ#h?¾ÀŸÊh¤êƒ¨¾uA9lòÆ…ÙÃY‚›§}>×Z…"SV(Û—ÁƒFT¢ÒæOğ?›O^¥Ø»»mkØïstğ×¼¤m±Ï'|zºñ—É„˜†>äïònQë’¸Ş"ÜRU‡Ê¤¯Ó@PÑÒ§eú°C¼TD×›oW„¦P=İÊt±È6z^yÿ·Ù¤wJ¾;T‘eB…q#W»ulºÁÏxfÁ"Ú!ò(:’¹a^ªm¤ÂªÌßq”X·Ø‹Õ¡g#";ÒQßb˜¢{ùh ¬œéÚòG¡ÕkG°&ëgxÙtî”„ç§„¢]‘üVòdô–Ñ‡.¢B.ó7"ÓIò»`
‹Içê|”¡Âo\Œcå¯ú›Pá>Æ|¹‘Ç½Ø„…'\¦]íŠg¯0Fùh¸Ñ†÷ò¿‰ÙOå:(9¯¿tÕÚóMÂ~;Í¹é3ßßşØ 7Ì«z§|µçÛtÈôSdõ	,ø`µ¸ïÊû[]~áĞ™ÃRm½dÀàÍÎq.:– ¯àp3æŸJCT‰½DØ·¶_duÖÆó#‡op<³ûŠP´*sŒÂÚø¬KRöÅ¾ïËê˜%zÇ&å$¢ËMÍ®#Yø3”íöJ‰üitŸ¢§#>°;x…;¸m¾ˆEs
°ĞñÔÄÅ~Øš«¿S8¤j>ÔåÄÔOC—qAi­óYidæÅõÊ¬ŸuTW:8Á¿OAïI{}:|4"Ëì)y0ÏZÕ—ìWfòe
2€”ïâ«æv«72Zı§ÈrÏ;ÑÏ¿cløjÖ˜rA1ÄÏãE@²YâL•—’ô—¯¿¬~Ö@x*m„oğõÒûìrÁĞÀ:g¦•ÔBÁëk >‡Z°ª¶Š×™q,=8Å}xñ†,¢Ş½²Cl†ïÿ¾€y•cÃÛ9a¶L>MŞöz?˜6½×•ß·ƒHÖ}'k¿ŞšT2Bç¸t|dïÅ·ÕoC£} Ëƒ•§äD´,wjµm@qc"¶ERzØ·VşÕa"ø—é&á¢^Ùğï} àù%;›ò¯n¿ŞRËSTŞ¤ ?9 Ib:z` £ºƒÎø)‹É«¨ïÄTkÑ¤Š÷Èlô³>
¶è›~’û3ï;#>45D“Æ
ôñP„ƒøÙ`½Òn¢ÙˆìÄlb|„uŠè¥eİÕÆ»È¨-ï'2„“²­g÷h?¨e	îæhj7îlDôúHo%—Vl)ÖŸ9RµÁ.=3B¯——}‡ËŠ0, »óüÉ-à´˜m§ó»/Ìæå¥NŸL"[ÈR,0tÅ=G\ÍiŞ76MÂ.6Áàó‚.ÙùSLİkb$Oçš|:rÊµ,HŸ–4•ùóZÑ=
)İ—$€80M–òaì)%º”'¼öÅÒlãPµfˆB!x‡}‚«Â54—æá10âÚÅy8AßYn•4ÿô·®™Øbšşjl¾p/#1—C¢hËª­{d˜¡P6@¿O/)kq—ªÌ!R%_ùÜš÷ÔvÚ-&Kµ×Á"uA¾9EAl<È’{üÓ½ÇØŸÕ‹ğïŠ2+–çÄ'áøo1Úµ§3·§Dî­ÁzÇß,ˆû³ÙqñF{ÑK+7ĞÆp„Ê`0ÂºT“DõiÆO1Ütı~p÷-Á¶’Y¦‡Ğ
­ÅR÷ÊK<æñy¡¦6¤û¢
ıÔ*r¶˜õÛñ˜%ÿ«ÁùÔÿ<S„„!P·WØƒ6˜É‚!²åšëN‘ªàY.““	à{©Ğ‰õÕz9~´Åf”'È”Óqı}åwÅ¿BÓ;ì1¨=U9`|FáH"]€®½]k¨îÚ…ºÙ„§?¯ªÊ—0¸ezGeİÖù„Òû‘5Â³‘äË³«RÔ¹òÑSb£]ù/Z4ûÉ²0ÛŒ ›Hx÷ıkµ³> âÃpW+Ø÷h¤…B5Ş•¬.ë/©wı§É=A„ÃÛŒO·Ò…²µ:WŠEòÍì@3»Èæ&NA]½©81@ïUc
o€ás]D.3*U5Z»?£Â“f„—{ûU¨9÷ÜÂo¨É>¢&É:UÀ"‚Z‰Â ÑL+Æœ–…Şz™ â¬<õã¾øÏaW:QPã.r¸UÌqG[)|áÿX‘˜ÚŞe^/U( Ğ7—<V#ÓB4Ék~4ßè÷©IÙß?8ş>ş˜8ÂxÕñBØŒ:ÅÍìË`i&Lâñ>Ã&Îp¡Ql úËÁìtmihØ$nü£İÀX‚tÁÏ~Ë;ÏU»¸ëo¯¯‹3*<Bu3¡ }B[	Àl­Z&eh¦
=ú”HêgšÛjoŸ²
OØ¸Ÿ\¤>cÅû˜Ä•ésC8Û;ZN:x1ôÑÊ3Õpj \xæ©Ùjğ7µ§U®P’*‘5ñR¸Ä¶/qû{•íØ4åb“˜u!/N¦=-¦d:Å		Ì™;±ı@‚¿=ÃÔO²ôÎC*ÕÕÏ§Òê'´Ëuë2ĞÅ÷	H†Âlúÿ®![™|:G.·ã{i­*af½ÇĞò3è¼Y¦>Ğ©``$€!Ü.şT0ÁãT™½¬Ö0fzŞ¡e2èc½QdğªÅÛ^ã¡L³ı›ráI!T·éì»¨f ¹˜ÅñO=H)—®d²ê]ÕË	XÉr,UBQV»°¥ê-#ªÑ¾*„xĞf¬Ê­¬ÖaÛOº_ønP!‘O»è9	cœCÛ8Ä£Ué-qtŸ2õc¬‹oÑ“öbÆ±'ó“0¥Â'O4##"\Œ˜Ç@}3@öq¹˜’ƒ£kw²oSÚóhà´EÛĞ÷l÷¦põ—Ù±ù›'LµuÃŞŒÿ¹ŒÇW³x£hò£‹À¹—WiûBÂêĞŸÙÚ		@,.şïéƒv7Ìz÷fßEtUüÅ‰Ö 2êo"-íşóÒR›¾“^Ï·5s'AaƒyêqmxÓBíÒ]Ş²T­ƒ«·\Vá[çõ‚?Óí¨ws½¢Êå‘8:ËÉ*'=ÇlÇ‚¢<„„e'"¶±\ãíó`gYş·%TSvn2{®Vƒt;Pâ±[‹õƒšÂ½?¨³	.æÅ
–”Y÷¬dJ"ØqQöøûÄĞ€¢¶))/"@Å% +8Á-êó8^.©ÑÓ§¸y= \GOÛ¾õ/ŠçÎûpïù\uÚ¨ol‡2!jtp§Šë3†*x¹A*©•Kš‰• Ü&…»T¾Çëşš~ò•‡ğGı®EÑFˆ+×éğı[ 5êÉS=Ûéûæö‡Ô˜÷¬aUÅ†Ò–X¤g÷M³lÌºCv2F+®çm‘öÛ5((-]‹71TSS a‘+Á;,]°³OMã×ÚKW}Ü{ÙÂ‰¾ØGáœ‚H-Vï)Z}•ì™²
êõÏğ?aïøq‹ø=?	¶ê'zÔ­|ú^9!UÒÉmİ=™œ'§_ ÌW×p÷Ÿ–5ËFí …X=f	ÊM±¶ÒŒK”:>ùÚû×ƒ¬j^fCùhfØ+fáã¡Q¬8ÔıĞª©P+QŸ‹Y±Ø=*šV#š!H€ÜON|şrÀWzu(ùùr_NÙˆK(|·f‚æVíŠu",MU*:>ÎØÉ{WI½ï|„IÕ"9²ot‹„D’Ÿ±¯’éæ6hçëjs Wëâ‚SÀ¦Ä;i£¶€½é•É‰‰„´üy½$ Ó*1$ÂÀR=öšÏPÂ‘L¯F¢-ÊXKÃÌÏ¤Uı@XûPÌÜ/ŠĞ~0YÕ˜rÀĞU€uJ´º(róoåvŒ6ö†Ò-ƒÁ3a,ÊÍ çuğnïC—Gšı·s®}ºù{Ô0…:(/ˆãC³P%×­·Ò¶ÈÓ$ê‰/{ÄÌP»ÿ!”j.Q¤iääc@kùMgñ­r’®…¬‘jD§	°?*ä‹ú—~45ÚqØXÁàNÊdaüöà÷|•:÷›æ¢˜¦z­µ›BÔi?I	Axhøş/½:!aHØ`.ù7sÁã†‹É.@‘qÊ+Ä—_I	`?““ş	‹¼Çù'\(ÊbAà«ö·\ËùªÄIÙ£ªñìr®´À‡,‘êTÑÅ¸U–º]Pc"X>ÌŒQ—ä@ıàk
ë2w¿R£Çáêã%ªRÛ.;Ò‰ˆ¥êš8xwZTÍí1Ä»~7b=¯Ø™¹‚ı˜¥»şù46,­µz¢z<Àî€›¨…áB¥&“OÇÑÂ	{v+,DC×ó±Sìbºğ®±£°5Õ~ÖúA°ëÕíµ-Öî±[I[ö˜(eé	Xplàøf¬rƒş7yŞ_•9h&€,–0Ş*O.>Æ“ênğİÇò:Œ°†r“™=ön4arhŒJ#£»½‰po»À™(æP”¢AÒÛ›8(_Ç¯_º¡Ÿ©D	^(Ôƒ¸u×¶ß>ß'…øœp¿ø 2"mAh WJ›úÏrEj”Ùª.0>Á3Ç÷TWëjU[ÿVqTVÁ'èHyq]	o}y: é+­ÄÆ™Ür‚òˆü/íÈIš=C¡gíÜ² s~,éiÀ*‘Ò:°Rî=ÉPÂZ<´~#!DkûJøi;¿!Pp‰ì.²ÿ=©M+/o‰W‰óÂüp ßF#6¸§	Ab¥.¾ËuËh(^Ä)OÆpœd$¸÷á©iºÒ`ƒo+æoÍFœrå™n<~ÁÀ	,ez†dHI-UŞˆJc¨]ä¬øŞ{Ñí=„ÎUrËˆh.!È4ĞOFÛ²‘eeÑ>,q–R~_Ï,]EìÿÄ€tß±‘s·(´Ø5É`±*lódãh2eè™üÂ©‚KÒ§•`Là·"¦ZÙ/ M^ÍXP3¥j*‡Auüoê»ö†øAz1{j)j˜Ïóç­Ş4'±úƒvpyÓ„·ìx“U+ïğzl4=cã•îÈĞØş0°Á
¶µnWL1sáüêš†9ÙĞÆ°ˆI,™/¤÷ï§²!ô œĞä¼Ò»=Â”‘ùıh0“›‡uÜ9S>ì°Ş!Rm½	´Ãù©JtO}ÉN-¾Åëfn)WùBğ‹‚&®+èl”d•ê#®„½ÕBÿ£„%üô:;Ô<]°’¿~Ü´ù¹z*gKcÅN±å1
&#+PAV120ƒª$ÂÓ”8T.ùÉº1LõÙò‘6Îê‘òÉÏ±7’Å#ï	ô®İ2ˆËc9[ëâzümDĞË™[A%ïYÏ	BŞ]Ö¥‰xú†>Ì¿4sÊïy-¤êŞ/©0ãÎFÍªŠ9]B!Â
#Ã(Câ-/ü†*ñm8ıéÖyÔ/ècÿNÈ:9nê%XfrĞP?è×ùµ¿U¢ä‡4ç*¿ «DáWİê\Q]«İf( FQ‘O
Ö}r\¡ û×
û³uiùÿó¯ñ—äóZˆ(â¾O¶£xZ7PÉ#È¦İg?2OZ•(.iÃÑ¶‡kçI IH4²X_¥¡½ÁãŠvN¶ÛpRˆ÷¸8[ÅÃ	3½ş5ç:Bß2ÁšÇ*ÌeÃĞßÆ¨¤â¯œGù¶ÂY4=Éƒ6)6W”l‘ÆnÔS¥¯Ä÷ëŞsšK…*F²”ÕZvi©ı…‘•‘öÇÂ°µ!øPYY×D‰¢–’‘YaãóXuê¦Ó¥6Qy)ŞKPàe1¤RI†<Ã®ÌÁÕ†VF[ÖU·‹K”U)}-åƒª	ÔÚq#Jü,;D¹M–Õ×ÃºÖÃ×~ôiİT2ùg4Q}<!Ş«–Ù$m¿3ãÓ{ö»Œma=ñqp{~8/4šâÏÛ! ÁQiMxÆºíJñw¾ŞòK€wŒJ|À~ åğßó’©Îé‘@EÍSSnÙİxª?îŸŞ”î?Aq:o÷Ë¼‡pëÖUD*8F%ú5 _€2%¸T/ÓÒxb2¼ü)(ßı2Şû£íLËSUÅ·ÃzŒùµl¦P­/’¨ò­jCÃ7YÀÕöj¤îCeO‚ìŞÏæû+ï1(5Øé9¾†£2ÏL|éôB{’?ı´¬Z˜Ïß)ÏåE8ò—áğø3÷+èÚƒşÉÖçø`¤â1DÀÑôÜ§£8JÜQ*ó¡Ö]u¶RMøÍºXwyÎû™uÈ”òÓŸ?[Œµ+o4Á/…ØTqÆ‘³ıXÇhÑAp}¾JÛ­ˆ™Bìø¯‘×*Yò(ZŠ~áH_>½oÀ}VG¤²&<	¬r`;‰V=E‡À¯½\	î†Å3cqû	=ü¦b}2Ê¾Õ•öÄVÁš¨`ÂÌŒ5Âşw±øR'L™ö+6³H#ıúy™wJ.=D/Oï™Ó!±A¶×{ÓÁ,¤óK¸A^&ñVÎş°mÆæ¸¨&â4b0I&ÊC«CÁÅ7™“?yÇ5Ğ… ”‰®ôÂèèlá¿ûwÄfù·0q³‹ôÀÆ²{9ê†ìÚØ.š^¦QÜàg¿¨ö†yæŞSäÅn‚)Æ½5œ¿<^…1ğüäxé>+-.	Ü}óã579+Æ×)Îˆkóç°‡§¡Õs½Q™4jAü§yG#Š%ƒC¥¤N‡MÍbñvûh‘VJXeb»7ài>J/şö=Ï¤õm»’­ÅH»µzÅ#u’'ì–óãû=‡.ğ;’aôtÔd³ûıÎÔ=¿·µ‰óH‘Ã«y}~=SeÌB–.¥üI‹µ_HÏ ’U;Ö3i¼¢ˆ[@zO¾#™ö ”Å›–+'×zÛw£,µ%íÆºµ^ÒTù
UÙÁ'-ÒöÜXXÁªĞ×Š´ß˜×¾· [Ù¨•SsODV·9³éĞá<X¡ü–òDóF¼:e¯ËYQØfRĞ«Ò¯ ºóq:ÚUPë„zLƒÊ°Eÿ¸•¤Wƒ"Ûù‡{6¡nL¬îM¶Âuuz	<£‹7†<“'å“í(Âÿ·Ú?ÍÅ†f5¶„úD$±]»¿&BölŠSêÜJÒ¸ˆ#h@¨³ÌıˆÊ)à»M!İ‹Í·¥o‡Ó1è¹v†@‚YDL‹!„Ímêò^ĞÚ:g[>|É½zsÔMÖÔ`mòbûU±°Ä;(×p)ÿª©,vdË@Ï®´&ÅQK¿Á¼›	sDî¨1Q`†œ·"ŒÃ/Ë‰›ÊÒ"Ş©Ş'V!Û¤˜ó¦{)ÊL™2üjşøKğÚPk’‹OoÙ¡Ì~Íò6âZŸŸšù6¸÷Å    XV„öâ§ úÀ€Àq8^’±Ägû    YZ