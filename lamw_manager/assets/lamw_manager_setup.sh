#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2723982784"
MD5="13fd90deaa900a2cf049327451b0fa52"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23004"
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
	echo Date of packaging: Tue Jun 22 19:44:40 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿYœ] ¼}•À1Dd]‡Á›PætİDñr	iŞ/½ú˜44»[‘Nµğ}0²XÆ{òã’p°üsÏ¼–m"ÌéA®êhKğ§1Š‹Váe¾=šÀu}v5íâëç*äõÁ—§ÛÕ=Ì"&G^z†+56Ì-TáfĞhx´§0ò"_ex¹E²!€}¢ —ª?¯¤¥å9¦Ãb¥”>'„zúÿ¤¦îì#vî‘‹ˆãx²1Üf6İ
ÀÄ} <W£ Éš€‚*ŠËYmÌJT	í¼‰¨òĞø3J8ØÔi%2ÂõKnÅf2¬ı‡ç×ÆsœJœj¢ş³ bÄÒ>ŸS$>£órĞzH’Å³ğ"fºÔ5ò
XÑ$ß ÿv–K2à£±ğYª#÷½ÿú´g£²À¸½Èy¸Obİlíc 3L?C€b°'1ƒešãLÊÎq‘lõb?<“¨ÉšÌÏÑW¨SÚjr>'ç3Ë °Aæd£5Ê3u}VÔOö¿g¬ñ%†ÜíX~Â]©_ã£ òHÂJíNµÇ*­ù’8døFëşæàb¬À‰wË?Ñ?-EpÄS‚Ü1Æƒh†ÕG“·[¤Ê˜ß×YVkéëŞ)K÷Ú"‘ãEÃúöP%Jñ(€™7«-Yµw˜ãˆÁ²€"t|Ê·M>šušfŒ	ÈzË8]È¢/C8u´¯3PŠR}4)ùë’w°ı÷©İÚ(D“#?wÛÒQ>x<oR×£ÊµÆ XD(V_VË›;: 8âÈ¯>ÉFøÇş„×A¨şÓ¦¸&ü‘«Æ ­«Å_DÖRûßµ8< _:ÀáS:/ÆÎ=‘dºàßDüØv.¦Â¨;6û5n´wÄİºEªVBêé,]›@Ûë\c½=Ğ#p{¹û2çdÉ'{²ÿ^İï³ış¿‘Ø»]I²ô|gØ£zÀ öF‹+7˜ÙÊ&·•ÌP™j{¿÷2æ§6õ¤&yâg×4uüëJòHa§ú ´¼˜!ƒ&¶ª3àªGÅ|ê÷Â…î”[¶•Ë•ç.Í#Â…©Ssë“AdWXšdk?ş­oĞs…½¸œ šøt)ÜDUšùcBÌõ˜O*&9¬¡÷} »†r·¢”¥KÈd0?MTi«­ñE$W6’'¼++»KŸ’\ğ©,ºˆz¦:ÉíáQK¹8“ÂÆD
Ëj|ÌÀkŒÆ×ëÛZ0•à¾£ {õ!ç	ï˜so49èä(‘—ƒzJCq€UÁI÷Ù3Ô'±G¢my›Oš¶¢6v‡Š£)ˆÿE¿Æ£RÂ½ÿŒ;ŠVHmI'
£ˆfƒ=ü÷–{yj­Ÿë-HÆ\Ã%¨¤X†&/¸E£÷šcíİàØÚ2IC±ñş‘ ¸kG“B,|êûn±÷qPÇñuv/e¦4fE2QP2I±9ŠŠ §Aa—GKëgb˜‰´	cdŞ æ¿r‰cT#®ÅÒgF”æ	.Œê9ÆèÆü>Ö ,’üíé†ëëÍ“ÒÁÀœágL#ğõ¤€¯½¢8¡%úOeyˆ\Y5Ü¬(!Ãx4,ï•¤mç”Œ#cï]
ø“Ç,#EM0kÕlXcMöZfØºSÛEOiM\ÿ«Qzo¤~2¢¶a6(ô<y¶Ÿ¦®“2ÅS¾ÁSmMFíì\ÉBûÒ+Éâı5` 5±Zİ8áüwâ¦	şsHt'pÙCL›mG_uikÏtewèìk¾éJS¢>…G8±i×;Dİºbï~I§·ÀÌQ=Óv<=­jûîàN¿øcÆÛ	^`ÇJĞ.~i¾‡ŠO“ïå¯ƒgIr"f»œÔ‡p¬cF_¿¥pxe`ëZ* /=â]…öÜÛ´”å
;(Nnª¨…§ÛõZ}Ã4ÖAú±¯Ü”©ôÛï® Ù´(-»Šn—âŸ0ğDĞ‰‚Ôıö åøƒK¸8”Ş$ë1Ü—Lw^—•œO=Ä¿²ÆÊPòxÎ‹¹z>‚+pw‚sÜ$İ2ôhn
à¤",´ƒÍ¿n»çÚf‡ÅçT|èÏxx6IÕËÀÇ}#yŒ×™QÙú k0±…RG€Ya²~¢Şê§K=ãKÜ»V£şİí$ê)˜’¥}w°­ƒ ¿Mú55_ìsª2'2RLE(îñ¤å°]êíJ4a~«¼ğ¶rÕÀşµ®é«	GqÇ¶×um	E·èo„¼êL°[§/íè:›~D˜OóÕ°İı¨µ]„N¤4‰¢5ò¡–•”fgåxaGaB>(Ø6ÇmU	;bFr¦‰³İYN¢eÿl‘¡V´dqÙ‘«ygˆÊùLÍxÄ´‘a!Õ‚»eËdvRV˜ÕBVY˜"^tA¨õ{¬,§/3¾åhSŸõù}5ÂñäĞO÷ìwi{_ÆÛûMeÆ92”isk3˜_vñ ±
˜÷oDù×ØŞš¥ORã:T>ìóË"Îı‡=V xB™Õª%/VÅOä¹ÒQÆzK ,áÁÉ1oÏ±1"»=]hj—‹ësºŞ·ÀgÉë¡œ2¤VßÁÈŒ êéØÀáÇ¸P¹Œäi(yVs\ núíMc¢äùºZ—8FóSÕ¹Õ„ÅF%±ë‚pEB¼:šŒÈjHx"dçR¤‰/Ñ‡´‘MÅSÓİ¼³çŞ®÷9Ñˆ—ïŒ/HÔÓv ¥ñ"öM>™¿˜¡ÉÛ)é{\ Ñ¼Òæ¨Çâ_ªt¦úÔP™ıV $%\iÍnÓu+hLğ!»ğ[;jø,.ŠªUSß½–qƒÀ$›ášğqâºCû3A~I©yR½P•_Ó~AªoÉšÊ=EÀoYÛÆ°d"Lwı¸=ä DÜd‚ìl°›¿Põ‚\¼¡Íæ¦ks‘ØÁ};-|‹ÜÇy‘ÁM|à¢)›Ó{it6%ÙpAÌÍÅtÍï
ì ç¨£ô¬lª'/Ïè©Ğ¥åO‚êd…ÔOLşLùä”áî¿G[Èİr0=Ù2ÌtrØk·ÃQ®o[Jûø¥°r"ÃĞ`íZ„ÇC''âÔ^¨ßÍMV8õ|mË™-ó=R4¼q‹E~%‰äEôL`©ê[Xı)ÅQxÍ­rH}]ûÙM'a<eoYû_ÛWç‘ĞN	Ó*Pq)onP­_R8ÍÖ:'ç?¨Ò‘Û•IñÛ·ª e¡Ö™@›ŞNûvß¼×üF|`¶	å×QÃÃ¥8·¼EØà[Û¶í!¼•Ú-ıá1Sš½á¤ÿY¼~³^OM€f>>”Ş™¾Ìe]Âıhñøûj>WjF"¢÷ØùQ‰DeÔ"é´niÖÕÆp¯3oUÒ²s:If1¨g#n;¶Öş¤ù?%jbúŞì^×£Â$zÿ`XëÌÍ7ê¹ö\
­÷8—Z*ƒş‘Dr·ÖĞ|m?³HËÎŒúmz>?EŞ.pĞåÆ-RÖä÷Ç6ó@‡²½ØÇœ3‹:N˜€ïµdj¶Å}†ëc{@d®ÏæÆ—›<3Ÿ’ËìqåŒó¹fğæ03x†–aÔ­*¥ï£1É]vOméµC¸ƒ£šØª[K[ç4'y»t§ËqÀü©Zëc	clà×;5[õ8çO±yı²…d_Qø?®hkv¸#oÛí“°<¥«$SÍá"ÿÁ¯~AÂ‡8IWÎ\~DİNª&½æââÈ°\¤ø‚éğE­¯õİÍ{^(h¸Ûï8ÍûŠÎ^yÏ V÷• ÆW?ˆh‹ô>ˆÉ±iªbİ~C!^,›ºêA.'­¨½t2§j-¢íæ¯Œ¡(d`N„ÔÆĞ´x~z?"I4½Ï`-§pÊÑgß¤ã!2Ò¾L¹˜L¤êBm	l®¦ü'†âéÿ›„Ù¦ˆÄë‰ƒ,(¾™4$êüâ®BÈ·VêunKNbSêÈª4%˜õODJ(†®ÅZA Ô
“jÜïE>s+,zR}Yé‰MgfôC£èšsİ‡ƒ÷¿Âº…¿‰MN>n\Şè–eĞ¤bÌ™µdj#°¾à@$ğwÁNät;ëÃR¦¼&Wû³c;óhZ3ô-„¡Àš®¥3–ù9',
äügVnJt$
”±lå´è&Ô9÷©»åİ`®‰ø­h4ĞïşS/é°_÷’«”ğÖ’¸±	IÑP}urRÌSN0p#d`oí±ÜI—H ÇlhÅ<®±Ã|[wò`ä +7İ§jOZ&n<·NSá0©EØ°·cÛ­Ù¾_ˆ7Õäxİ¤>?’_íÙcÿKŸ:	ºiŠ<hè-¿èY¦JİH,~¿›eÁ[û§pÇ‹È"ÈæQwr-İ)­™÷>ïpW²;â)¨Åo‰“æÖnwX§$3ù¶´ªÀƒ3±×b€ì±°õ/~Ş.me¤„´›Ò~¼-Õ›æ£$Oİ„¾Ş^±ŞØ‰£€ÍşşÚ+Ñ[äO=ëv„^ı Úæ½T‰œr/rš¡à.ë°MïËpÏÒŒRÃC‚_Á/yrµŸvğ:õ[ıXôãY:~YóÊ"ÃÈ³§âTí˜åµİF•µnç¨Vp‰¼'‹I.¤ôä‘dÔØ³é“J#a	ÅvÖt~Œ÷˜…
XÑ“<3béÜùÿ†÷–„sğŒ NñØK'[]&8ıĞø>Ä²÷ÌâÀ¸d”ï€…àÃÊÒğÅŠª <B¡ƒš|5&ˆÑI"”€ßuEáùoîÉ~rL×tØ“t|IâW«wŒ=Ãöû%¶Óîüù·‰xx¨ºlÊğfä©Ş&—d\Ğëô‹k%ÚÆ¦o†Ókù¿UÕ¼X=À’éÕµ7ºœ=“(”É×ÔTÃ¹ÙâNÖ§¦¼Cèà„4ã¦àI` HŠ»!ôbsç€®ÈF•†Ü_>ùbe]— £l`\FÄ—Â§ç#‰8´Ö b_^ã%´ ÓråÚ›…ÓnF âoìÂ¶ÕcâFû=mza­¬mzàKº°o«‚l=LÓ?‹ZÆeêßVı•Z^ŸvSâ¯ÂªûÈ—ëù¢üÒÄöÁSÕ7*ôŸÈ£ô’ÍÔtªêæúo Ì_ªÇ–Yxõ’©çË	m?<û¦ FxşÌ)Db)9ŞşïœÃâ·ÃAú-Y]ÒF‰$ø{ôùã½Û [ä€V
·j
ü'PezWfü<¹0?UòU°ÄŠ%z§t8&É‡ê/Ä^
?ÛwRm‰¸Rª$ŸÑã¥¯~`öî SŒÁºn»àÎYŒÔ…@âÊòÀÖ%ª~Lª×÷™>á1œhÔ.K.r»²\Õ0/Ûô³:‹9ÜçM	‰Ç8ah°3¦„fI-ÙëùÕê¤?Ztgúâßd\ê¼ë0-¡öMnBSÏ!i›É:ú›¬%¥ÿ´ãì`¤Ç÷VÑèôöÉ’ê7¹1Û°NQÂ=š¸%ÕE‚²0‡,[«´chwàWÈÊ.xÃ£G(Yu«İn‹®kdğ[NÁLsà2ã+E3‘3¢l„}¿À7RO;Ïµ¯Qöãlã–V3½õò“‚¢³ ø€7ñŸœêBj:Í´qç×àŒê×Ü(é¾›â“0™E@‰Šóò÷ò’²®¸m ‡ñ«­à¹vâ“¢²…ÔÔÏÑ¥{Á1›@4<3¨ƒGÈï­!}àÓ»3£B“²ŒÓ~–!ra¤yB”“"NÅ€äµ3rÎRâ¹ù¸Öí.õAªä§)ÀªîÛ!ã:—éu^åñAIDîÁyÛ¼œµƒLé¿ÔpÖ.eë*õ.\OÈ¢´³ÉÄ½Óq*—5™à¤eÅØ{³§G±DéôûfÊHíhA$«úX;pëqÙ<Hòr(”ÈˆÊ°0"*â¨=ã]âğõ·9à9Yk5òÿG{ú$,“-‚€÷ŒZ¡!#Ö­PÉÒZZƒk’WçÃiß$àèú‡lv¼®£awé8•*XÙæ& CL_d,cUÆØ65Ş^’»#¶Š¢Û¢-Õ‰åØ°éG~0ÀÅ q!ÿô}æ¸ÕU‹¬Û®Çƒ³kSç-1Û@Eåf;jÄ š¬[-Yb§•˜_¡…@c÷@q´5èH!Ÿ¾tÈüë±#×İ·ó×Ÿ]eJn>S^ymíæ,B]bŒEÑ
dŠÎ«„Š“ß¸¼üf]eKEÅ0º9ÏZ‚·ic‰×k7»9Kı’}”ãÎ„SR1ÆXT¬N‚ĞNò;¢*M¡8¢ÀvùİÖG¤èIÓÑUê/”Ä;@ƒˆ‚²›ŸÕ/Ø9A‚4e½øšRºù*y&„åJòï%ãòkdó¦ !†#yÍ}³E—¯WéùÂÛzrÔr6ãq¥"nïˆÏœ«0ú,np\;›‡^¶¥£Ò=øÍÑŠø‚“æšy8ù~Ãà7%Å¦[ØNÙ›Ä
ÊC__åA—Õvè¼Ëé}Ô„3ÏRP]!
ÄW›oÔÈ÷@º—2¢2W®šX6®ñÄD‘æL¬¢“ÌXv{È8lÜ˜½ÎíôAYZ®i‰ã{óBxE˜›´ü¾WW³ÙÏ[À½7£]ˆö•\Ñ‹ëÚLnŸá¼ef½ê4ÿ®m)ãÈ§Ê×EÅ>×H9i _"o3e$-Êôa]–3íàaXK,LØ»ıäûT÷6{i˜ÖìCQæQ+wÀ-Eúîö5œ¿´2§£z§Ğ²¸HœàÓõ_×œ ,ESµÈGÑŞ°»æ ñ
Öa<ŒŠ2„Ñ†1€'C¸Ú!ác’2ğÅ½2B§ ³fÀıëPŸú4é·GKÜX1üƒCÙ©Øçs`¸Çeh]a›?Ñ?"QdáÆÒOzá£¾å1×Â=&»¢!`F²
kÜ½r¥Öƒ>fQ#M
0Ğ½ÀÙ„Âí¼ÅyÓ`8'²1¬9²~„V–8<Äñ­«kÇä]vÊ“ Ï×riúîø“@rZš‹İä4~Ä	¯úP~j¿v‚”İûõ•|ˆÑ½Uõ±tp­X­÷^ú'Waò’­gÅéÔ=±ì	{·Q©—Ô»ªF H‘R vàå ár_1@Tãáœgí=ëmµIøRqÓ¥Ä›¶ù-28”©±Ç~Ào $+ÖEiêM¹1¶§º–
‹\ÚıÆZB´…•ŸıºœÍ€À2T4Ö§ÉœÃÙ÷÷ğ¡\g,ı3â¼ÆeÌ¼Ó,‹Ûğƒ!4ƒIÑƒC©êî¬^›İ¦1”vL·@mÖÎwk`&±µY€ÑI™ûØ‚„O5£ªó~YşòOˆk	·|V¯Øğ™ª‡¯Óº„¾çÍm&4á®Ê>ßĞ+ó¨ÏŒ.NÒ×ıÓˆ3R‰ŞÕ<$º+4!Í©¦÷ÃàBŞbf§¸²¿cùWİÜ%¸'°-z\Ï$=}¾Ê[ Î7±±¹ÊÜ«c1_ÿå¼7+†ÈûYZwy~í}KDÉw¾.5Vİ@–È>ÂŸ”'ÏãÉ…İóŞ€ù ’¼)[ ÀÙ¡©i¿»çĞû s×"jiD¤¥W½'1xwW-”’;ß’ßÎÆ–S»Ÿ5ŒãŒU…ùÅNÖğò]­[[ÀØ;~ÛÌníª}ciˆmzTÛ^·O_§Ãˆ”#A½qß,ƒë°"É¯æÿeŸE+Ve^¬S+‚ò@š@vŒâ}•ì•­#dÍ€Ù	vóa,ñçÈ;ƒÕRBÀIjh×èÅ¥-³;2CÖï*[Hx©6®¹‚+µ´lÀdØáàxE ™»¡ÀŞªøÓİA‹½u%«9ı&’Øçñ\{¹¸08ùö _.Ò7,;,×H:Ó€Ñhpíé<Èf°’ÜõÖ˜8än\Ğïy[{æl4óå;s³KUÒ°Y–ê%–û	2‡,­ªú
ë÷ûjT}˜ÛÇë»œKF÷/FÅ £|TF&t~5¹)*BD³¼X´Îuq¿ÁßjœYp{‡snXVf•;½-ì_ø¤k·ƒåõ^M/e_fu‡;^zRËCŞÊ³‘S7Ö–d\”Ö&ú¨ÊG[¿Ï Lß_Õ(t€Æt…âFhóÈ¦ç0J•ÅAD´%‡èoFîº+Y(a<%ß^ÙˆÕÄNü×æª;óÿv­i€m‘ö<ŞA”4¢²°„«eŞWGĞæ—ÀB‘"lâ_Šq¬òe¾y#-Š“ÛÕw(…ØQ“ÙR¨w„b‰/OA>¥¥‰s¢p¢;À±NBp±²ûP UÒv;G|„‘Ğ‰+ÿpH³~Õ§?›ùyÃroóçğ=°¯‹ŠvÖÙNùYÉå·ÀÍö¨•.­·JĞ­:F`bA3´¤À)À-²Ó‚ïû¡îTŒ¬ûíş†÷%)cØ4-ÚU?”kãu¯Ëe%ú×Ë^0¢*ìÓö¸&sl^aHíg$4Æ×¬âk—Ru˜á²ÕèKÆ†c6Õ,vOÏŞ®u¯æÜbßcŒ22Ëä–KÛ†şƒŠÅè!aËªş)4'¦-ÔgÖX«za;?Í“6%âùCD1ŒRy¼à–=…Õ,&„Èä_*nñÚ
Ê;Œƒ¿›S„ìŸ
i
ıpgU»Di@sRğ‹¾)tƒâcSû†m&VKG ÖşnrÈ;ˆÓ»v ›êâÜ¥E–C„µoÅú>FELôÈbºéşûMÂí…ı(zğ[ç•NXq³BáŠnÍGVìÕÜ^kø¾V µ€GİÈ„}#ø¬Hf1µsş ªåz!)é&Ä¹ïèüÑí>üJúø=%$³Ë×ëg!@§ÄNœ?ï¥xËp
Søì•öóÙ¼cŠæ7ë_‚ê·—¾$oÖtmì¹Gı¬ûÃ—WÂ¦‚ÛİZˆÆ/3gÎ°çœ¬Ô3I/6¨ÀÆxæ®/Qš3\#ò¶6ŒN¾
ºÂ:Ò?2\¦ÍQéÜ:½Ç"8`j ¤Œ²Ä¸µVO®`»LÆFzÓÅÉ†Lï¯éÕGÙ—údÆà%VßÌ¼È“á31”Y¯j›ØCŠ ôµ÷ëÚ Ÿ&%6HÇüÊÈ—rÚ‰}¯ş“‡‰>š:EO€7!úëV-»ıDï!EEX§°mq¨È‡.7¬°QÜÒ+tÉD#‚ıŒ£è=‰]Ñª~÷ Ôyû4°¡µQÙ^×„ø+Â–H4EÒtX?–BO´f¤kG¾,9T ¤¤iØØß>gP,–L3U›ÒLhåœ…¶3KLqAğ®…ü˜›n%¿ÆOö¼Õ•bÒë˜*ÂØ”rÚÑ²´QÕY¬b œ>ëË+6ƒ¢æ§<vªšVJĞ¾Wšºö»ÏVÍ‹›îº\•Ä³”¤Ë×j5tw$ƒ¯iBİ/#=‰m^8YéÛŠÃ;°“Y"@ÂtŞS#ªßğ[Îò1Î¤fáçÚøßô­›¼ÀJ1rTò+2Ş íÏMgúj~™äÌª°«!5Sbd`›ã±ïšèŒœ+Ç¼“Ü§3Sò…‹¯¦‰AØúGv¤ò¥<C™CóZkùÁ=„äÀ iœs~2s	İJh£œ‡|Lœì¬—&Ë'¨|#4,ŒOèõ¥c¬Y=]³s„ÅHvÑÂıïnRÀ	“ÄS$›êìu“Ø° =¡•áû^wÒ–Qºiöx*'>‡Ï8öó$X…qº!Ã»ëùÍJs®ñû
gïí%0*Ê« ÌglÛ6¯›™½¿”#±$ğF¬›j…'ûyöi}›…Ï:q»Æ?=
x§«.gÂ¿š
lÂğ×¢Û‰äæÙ‰5ãê†> V? şa5e©Ø`.¶	İy@BßK«cH´¹¬*.q‘TO›¸Ç9bT¼Éğd¬tUjÚÒN;õ‡&YT|mÔu„M”ı¿
õ‚ŞheÂ>æ+øŞî°qn–…Èô,]öÅ™Ğ;ŞÉªõ+^ÚÚ¹D+fw"ã
ÔëE9!{·1ç8bef'å>ßÛ­e©^]÷İÂB¨åg ù×Ç{w(L×ø{ËÎÏé!{°bUÃFù>¼œ!» gF{úş­÷¥ìŞÓS‹%*—@é	/µuzî»XÁòŞÁÄ&‘Íz yĞÛäş@
Œ¾Š9Õ¡Õn´ò/ƒúïÎSŒ“=Ÿùû¸5wµùæ?f n„Füš¨›<œKŞw¨³ˆ²¥³šwj@«Kd¥€Ñ€k‚ä³—H«ƒK~ı%nä i¼åçsÒH¢ĞV`Š €`ôT4@Æ=ŠêáIëH°R×Ôøÿ0¶“	zÓö6îSÛàK,í%`_ØÚ°¨øäóun£Ç6"n­¸kÇPòûÏµöø±Ò4‰1çâEçO£²Yú½í¹ğígÔ¦Ü¶’”$C—$…™µ9Éu“öÉpÈ˜<…‘¸Wş-üz×üMam.Û 6P®LŸÕKOŒ¦ÀqË{nu#:†z×Ê‡Nf÷ÆKqÈË—Ü3™Mçkâr1©ZÓ°‚Jè±ä+¾_V /@½NÉÈW~Ë¥İé´òºÙ>áˆŞ%ÏÊœ>yÆ_3E.Ñ©-bŠß†V)=vxvÌ!œ5Ôt¶ĞÚåU±ÜUğÓp;êf³£	˜  ûe|JÉŸÛÆ©`@>¯Ñ1‡µS°O1“Ü µßNçWæÖ¾Fœ0ïÏœ	ÌŒçj¼`h„ †¨-—¸÷•I”ƒËW*¿½yigIÆIáIÜYÈùUü(Fl$kÆÉ†ÅÔ¤TÇ67ŠT…Ã@.“—VF={¦5;«ï#â—CQuÍİ°Ï×Ş®8˜¶Ü"¯HÇ2* æà c“(µWèK£ÛMD_—Z¯ØOsß‚NÙÃÅÖ+;g)=ø&eÍ@É¡‘‚:¦k$îŸaCÃîş%R^8gP×$Üdİç$°ö¼G”öHÖËš¾¡—Æ'ıÁèÀ•å4‡¦ÇãŠÕr\è°vŸUº—±ˆôz9Uz€@8²Gê auöîZ ­
â´]Õo~ s Fá}@Ï÷Èl;11×t†oåVö'–	!&¼5µ÷,¥Â½º€†³ŸûÒ{‚m@6s^ì4=Kôİ¿c)ä”¼tTY‰é§ÅŒÁĞ¡İç›O_\ÛÚmzAyyŸZÓüìÑ.êd?ÓÄPÜìàÍsŒ;«ûW¥5yÑKØÈ?03]›c“5¯G¦ÁZ€?Mù›oI$Šr[íıërˆdXQ§±(/\.[á‰RñÇİÂuÑÊnÊf‰_¡/ÔX¶Ñ;ªÅAá,r@'ù¦Ú±”§F[â'›TÔ÷«8A¶âDŠ`i;Ÿ¦êr=tQ9
P¦H_éP%7T…Ì?vV¿]7ì*İ$á’°5ë’†@-îk? òRÅGV¦šùÆ¹'X.)O-±øZÅCTëpqÌ'#RUâû¿yPÈ±C÷cİ# ¦:«î	új¿Îöex”Ë½ÊxeWŒù¬«5äëZÎÀe,Šx*×DÊk‹Eßß=~~	-A[ßh.ü˜K%:Njò5˜5É>ÔÙ§µõ¬f­	SÊÙ]`¤"™µVc —-–”rĞ<\­0ûäSÿí‰%¼qS˜ùgë³òˆ†°ÅÂ‡Û®Œ}şÖ•mÆYcçujı «¥ëxA.b0ğsFáfI“ƒóØò¤Ò·["§›Yc¬…EiîtC7…tNh;\÷/Š†4!#¥]jÒ_UÍ1ßög‰©G)ğÜ¸ç\K—ºõ	»å¦	8¬$ïSDŸßFtö€Ç¤2IÚÒÊàcÅb¿,Ñç‰ ::‡§5¿kY^Ôk¾‡‰™m­+E‰â^2ùÚ¥ß”v	sôÂOÁsà	YôgvùíüUÚ¿fò8«ˆî.mÈ–œ‚Ğ“—Øİ)“)$we¢Ò©EãBE•°•™5£«,X­½O0]‹B¼ÛQì£Å-GzKƒUüdÙ‹¼¯ĞR&İ3å…:Æ§×ù2Ëÿ­¨>˜ï4ÃÏh,L=ƒ6Šşİ´fœÿÜ..æ&¢*åFš¤¶ò†Äz­ufc¨‘¡ZÿŸ4hÈ”½(¡ß§9 âM¾¼š,g!‘<‰ùDøÇŒÅkÚÂùŒ¡"eÖ1Š4¸&»ë–}HUÏ ß9w>LZ¥Wêµ¥7¦³ëoú_ÿS·¢ ÁÃE¢ˆb9ŒƒkôwF¬cğ\Ò<;“É…‚ü1õ™Z6°¡-%ƒ£ë¿Ù
™²·àd¶´ø(SÑT$æR	:Eñ}è0NÙ…h}a#Ï^4­T•0¢dJÛú–œ¸£œHÕÌAÌµX,ÛƒÎ§¬L+[»E‰-Ê¹Îvøµ3Š[ÙËmşäC‚¾Ú¬"£ã´¸cÈ7›Ú`œ(ß€9µLäÔ>¤ĞßµRğÚ‡fMpGŸµ;KFîxœ4WòÀRuäŞy½pu•¸:›ï­¡Uğ’Ÿä£+!IMKmÛÏàÙÃú(tàPşŞ®„[y#"F•WDRïgù1è¹îö”_híšëºÍ©ûœBD´‘Œ˜{'ír‰6©Áîf¦ÔX	IZß[UK¶$ú#¨Æ7:ë 6 auÍ“êÏrhí–sP²¨NztItô±lW7¡FˆSìhõ”‰ÉÈ”Òfä²§ÿ€£*ÔÆs•dÿØÆ÷/òÂ™?èHÄunÁÊ‹*\Œœ—ƒÏ9ÄR2—şOobi¦Eh¬½\Í—£ÍŠÈ<„1ÙÌ¡z§€Â7éëGBZ{ªµjYâ7*Ç°/8­®‚ÿ/åİi]$„g¥™úü0J¼ò»´)¸aæƒ¿ĞzÔHÈ§µCƒ•ÌÙ«(ÅwPTxiã™uµ|½¾¸H¬ø?9q‚5XÆa®Yw„]m–¥U}÷{¶dúí66­Üé9a‰±gŒQŞÔä-`îÆ:G)«BÕjqN±¾³ˆóŸJ˜(!Ë“¥’"¸Ñ4CDÌe·‚}”¬ó+¹r¶EÎø&ópÅx{HÂ}×…K¢F®¡WÓgÚ›¢“–âø2|…Ò—&¼WìêCP—úåep@ÙN¦}ŞrÇÚ ¾4 ‘VÃ§^i©àª7“nÒw©ögcT?ÿ°RÛ(¢¡Lj“ÙÂßıÓHÑl9ë•Ø…$Üáö¹ı ¯’£µ:á>=
Ãø¥ôwI[jîú°xğ‰Ô÷xOÂæA8õ$İnı–$-SÌÄzj/dFÕ ¾ßÅ˜Ç¦…WÂ62vgÄ€X‚Ñ¯é<’?/wª×+
wT9’:¨å<_k}Òpµ¶ıä]±fùâ?MïI–(Š"`ÚåK‚a^"ÿ8oñFë…:iÄ	¶ÔÉ/¬§–bÿ_ëNU.VkØï2­íA(¦C`EşZó#yb¸fúv!«=Aª>·-ÖÒ)¦y%p$>ğ³Ô€këKì SÖtâ#†ü5šZæ`µæxŞ[ë87,Ua3‡š{›(i+ jşU¦dtÖ_š=©N¯Öˆ‚>,.±ı_¸g._I‡‡¦ëk¨«½Ì‡rqü<º®¶eÒBşcòt¬˜#Õ©ìM]™rQùäŞl°›’¦œ F\FòDRõ¢õŞ^Ö»„ßW§Ì³8ª2¦ß-è~‰ÜÕ[¹ßÍ§¦!ë¸Õ {Jû&¯zíK!tMúKaöçôx/D¶]¯L`’À«jq™­ ügY{üª¾T~UpiĞ¶/âv1©eŒÕrøüèÀ´ƒ¢ö–s	ËöàìÇ
)ga™0wf¼Sk”öµº’]ŸkˆÉ·9%Y%}EıWfV6 /Ê;ô#Ûóª–x(ÇL‹y İÂü>œÜÄCÒn ¡)3ÃFëJY¹»wŒvêh÷±$Åƒ…G^ÿw¶«‰¤!µÆ­Â¿R^^{ÍD?µƒ8‹ã©¶¥ı—!×\pí½Ô`EJ:N† ÌåvÅÚé¡ç¹•¥´¯£e£_Çé¬$ôkÇuØ;-Îµ…zmgq¹æTÆ§ßgD/.qì¢œ†ãÂTÒÁC9e“,hÏ¦ûä{ÛvCb¹¨=äè¶AÅÔE.6a‚:²·{”?yŠºĞT0PŞªö4lê:r¡®ØKœ—µı™#‹îê:u}¤ªQÖ"Ôˆ®«À/ÌC‰şm´ûs€PA{âø>K5Jøí9%[§ÈHHYê= ù”º<ÑÑÖ¥‚Ú¾\ö±¹úÁô6(=zQıîRøä<,Ç5SÖlVÁØ"OVÃl÷-V—£âœI­]CV¥qÛDÂÂ$"úªŒÿEß½œKEØ€Ã”ücZ„ò"QÕ-T2Q¯ë¶%²HZ±Ü»¿¹›¸üZ']¶hIÉñîŒä©ü‡c"
İÏœ‰Vä€£XƒFU$Ó5ö2àëÅ•±Fİänå”ÕÕAXç—¶Ïéç•<c›DùIª*g{ÂZD”±>gºîcçSšvÀÄÉ_‘ğ3rÉ,”ŒØÃò$¬îú‚ŒÊi_ås%~E(_ r¿X.‚pjÄPİàˆÿuMf»|kòşƒÅ¿qTtÉG‘Mæ–§pa}­°4,š,»¬³9ğ‚öÀÂğŸFgî2Ø¸Ñ¯êP‡PãİÅÃÕ. ĞO‚l&†¶“ÿ¶4sëÓ Õ¿b72µ§æ8ä–\¡Öş‹ß\& co6Q Òa‡È™ıyéàâDS0@ÏYz_hh1Â]çßVİ>·üv©S¶kÿ5F¼ Ö‹¸¤lhñW¨%üS>’Ê<§¢B	¥å¨mì¶=ÕoYÓÌú2†ìón®Ù¥I"®L>á„BÓ.AÍ[&Š†xm¥¦D“Ä©e–PåÇ}rH1ïAû8çœTvdd1á¨Vû9SPXÆhÀg	èXL!÷äˆòû„È»¬â±p³P¨ÇâÑ{ü;şsrPO³`v
<D­¡¢Å÷ı¡8™“ê‡»ğLğ0Ñç–G™å5M£‰?tò9ùÓDõEôıfæn]ÇÏ‹<4o½SrŞEb"Êšµ&æàÙ @GXişÉïğ¢PU/(ó(«E'k»#³nB	ÜÊ†K|›ü_—šS?Ot8ë–ë=H÷v{ä÷Á7Nïºs>’oé/„Ü@ñuJ¤á¤N7óÉ\ãÓ?œ&X rO1}µR!oùË°É½ƒWræ~° ğøj–`TZ…CİçÚcl
ª‚j¨çZÁ1˜ßâö69›jvÎIèÂA·’Ú®(ØŞp!‚A"!«¬H ;²\Y±ŒÿŸp>¸–Ë8ªH|é£|#æ§ å1Iw¿0&dÃíe‹ œŞfyÚ¸ÿZŠG;„ßİĞ{¹òÄ,tpï—é(‰šaL% ®“(®‘ƒ0oÏ2*ö$Ãx ËA7€÷ãW{%—ÔÖ³}İáAİ:ú„jÄ“yjäx…aÂ8w;ÛùI^ƒÍÍ˜Z.ÚXzRR1¹È×!­…ÚVœâÃ÷ó­¶ùn\E×İ FêT»¬«Eéò­V›Œ‡$g¶ÍŞşÊ ä«°.°©Ô:ÊºRhÏºa9†›Ş±V[ÆÁ&Ù‘¢LºÕë+Ltñšp,ñ•}¬1@Â`’–6Ci†6¦ë3°F>™VIÑÕêcCu×ÍöÄğ;õÇ„‹	¿9›çèâR"&Ï¤I™Øõşµ—Ã¥¥ãPú>ö^èUDIÈ@4y½&–¯9\S¯Ê©2]íï”7–.‰«fRùÎÄøCç¾$Şdğ—z´$,ÆÏˆóL2”&s&#ŠYèÊ~ŞŞm‹+•i»/Á*¦ êÏº ³bL	¼%Ôó@FÊ¥GÆ
œRçãï.İşö±LÚ)ÃÁy7¤,&ßæ€¼òš¤$1ÃÄnélPöLşÛÅWÌI‹ğ.ät-ã§Ñ.£Öú/jÊòKM³C*®gV@#{uwG²JXKQj%X‰X*ïR—<
6Š«÷ô§¦†º1eÜéä{ŠtÌ¾© ×¨ Í(™âu,Bï…‰áA›2'bZmº{Kj³İç	7Ó;˜¡™Z£B¿òiæ/ï?Šğ!–ï¼?o¾CÛÆD\&,Ú±XL_U&Äí`±zòtV‰Ø›?·eO<o>ÁóÜú--qgÛÆÙşœ‘T%6ˆàéÑn{ísê8|şq'¿„µ~£Bñ^[‰û6DXÙ'›/=Ì˜½«ûÍh-KÜÎ²O°7CmOoGdá~ÉV†šîøÛzQˆ‘—BrıÎÒ“¸¶M6²z€ ³X
3[—%åG!ÁÛªãÊ%v™sªF€’©6îu*¿˜».ß0À¨cãæV¾*9GÛôMåYq%£¬^ôb±Ï9½2`ŠÀy8b¨­-d·ÓÅüÒvJüŠ¦Ô[íL„JTğĞ~è"<†±ª³á0Àn©j‰	Ym•£Ø<ËŠšp¯»oû_÷×rÁÍô-~¿rêm¨1üºÉæ¤%›³ÕËAuäFÊ¨LõS
4ÏÅ;6{D&ól ºw›2±À“†ôÅ"¡l5gŒœ…*@QÃrdÔÓ°Õ$Ğ¢á`0M	4;³±²‚\¡!¶L ;£6H&ÅŸi.2¨ªZ:ùÿIa‚¡2Ã÷¡¥?R¯»Ì¤RC^/îZt£+V¤Š]*¦àŒŒÖEÎ^E[@ıK+cámcwÈ‡‡’ïÉTm0'…+•D¹“µ…ÏzÖC’mOõæE74£“éF'u-a×Ò“vñ UÊÙJÇœÏªC|³ïó})¾l–‚7^$Å±şQºÛåä«—ıMÍ‡ûo×+U{‘F†ùC½O‡ÖÿÊÓ¯°ä¸CÕj‡.óR/.ÉËÛ¶¸k˜LAFlÄİğ¤h³LbPTèE*<×Êòr¡„Ğw»SâÂ½³T7y³İ‰Loii£¬şÃy¥!=BúĞs6G>¼+bzepÚŒñ,­sÓ¤ëa¨ÜJ²Jşu!–íw²ˆré—fØÙ>XëPº‡ßE@ñíÅŒbòzvu¡±2³•™Ğÿş9€¶º¢úVR;Ÿ\²“¯äÒŞ¦_ã„øî^D|±Œu­fzŸÔyÇë”&ø¢ñTÕ"õÙNp»¬¬&=·ài1è)™„h“ÕÔP›¶ˆ0¬Hª£×†W¤$¢Ây=ñ[P~áÀÙ£~°ôõßß˜'mÉ%úüRy T`~H¥¼´_<Èf@F‰‡0,WKkV 0kà‡”.«Ml‹ó¾NÖ>Jáí$ «LŸ{Y¾m^†7™à»öwß1÷`=S­õoş=2eòÂÜvÇÆ†È<è£yëàû+Ó‘	gK—“ÎÆWBe¼˜åS»0_ª§`ñŠM'ğÕä}.q°Óù&ã1{¢è<¹dR¢ÉdÂ§L0¯q„¨(ü5QÁ‡OÜ¥µzæŠOöox^]cTøé.{÷ú1‹À³Œ{ƒ´BŒøıÃÚ…¶JköuL´PõïWÀ2ÄV\©‘)ZN™Ê¶†7M`Ãúá¤²›;7„õCš‰àº‘½wC±Ú1´LJÛº9Û²³¢èß²ÏS u9š3:¸f‡Ô¨À‘İÖ,#ß:«ïH©ı¬Q@ë:yÍ}E 3ql?Ù(d6’F±iÓÉÈ¶…MôØıKÎfÖŠFwàJgq6Æğè>tÄ4ÆWÃP¼x$Åœ_íÁÕÒvÏ ƒİèØp‘’ïáúeœ"*{kRtrLÔ§Q°Sè2°èl¤Ë¶~5”{™€¶,£]†pN×08)¬šç
µ@|pxï`l0hé–H+à&èçâ?ø İKM˜äLó©NÜ7€ª&šØ°m²İ•8e† —'ã¨âî•»Ö(Ë’¡ô‡Xíd€öÓ÷««”’ä‰¥xµlüªñzÅ¶}tA–ÁÒ,ÿ0±|Ôª.¬ •ú„JG¡ÌÏyË¬½(ä¯ç4ï9½ÚX[yÙ*ƒE<Ú~¼Öò 2”Ñ¸¸w[q\e÷/˜€×/" = Ñú‹yõè5–I…XCÃ_ì/Í„ì\#°Îz¶Qª_Ìè)²ä±3V<ÛO®flùÖ[f7|¦3¨s#‹­™Syb8Ã ş6¶ÿë_¡™áuıïá…ºÎVü½¾ù¯àÓn’'J€¥³ù—\
ø¢Dz’æÍ“„æi,Æ,Ü0Öü:Ó_Ö8õ_V¶ü/Fo×Oõ(×©w@,·|¼¡æ]F»P7 U“¿ç:ü¥”È cVCÌy“Qaª²¾8£Œ‡[ï	¢!Ôµmukü9ˆ)/EùWUhÖ.—Â(²Ş_é’%¸M!¼ìúF*ìı½¸WdPöã›òœëjÒx¾®rŒÂ®ã%äï’)s‹ÆsÅ]fÇ1Ì·LBbÚ!Û‘6pßïÀ¢Xnß‰$d_ô Gğa¨ ÂídUªşÙ›]¹,9V	=É‘dšgÆûçç;’ŒFïD2?¥m»Ößø±|QYˆ•d=TF	’ƒá+9}bUË¼ÑÛ²PĞgö42Â)Báb™¦À¹a®C2g×…¨¦}¯[D½	‹áùa ÁÀbÿJ¾I	åÚnnSí<q4pªVãœ*ÃÁ£õ[ÒX)®6…²RT* n”g—ĞfËU›[L¯ó$¿î•5Œekàês`5PÊ…˜¬÷,€ğ˜·×ğÁÔfU4Mptãª‘/™-–Æè_{Ê”o?óBË ›E>ÅÑŠµ¯­Ã°ÉoÖ£şJ9bü«"Ã¿·NAX1 üó3OÖSÜT	•?ˆZ,L…@¦¬Šäî¤_±	È{s¡o; ?^-×‹şé»hÂ­`áÍB	JãıSŠÏÜÎ_É$Ç#ä¶c§âÚÛÕ¤ayóEuˆr&H­Òrcà8B€İÚÇ”)ç†›=³ÖÔƒÖ ¸dv”o˜pûOG«ïW!´ûÍ¿´Şğ¨ydÅs¥%gGìˆ”2âYÓH~+vê£ú4©>%?ƒEº¬âì¸÷ İNêü:šn;ÖÿØÇÀÿâH¶.xù“'ä+‡ÇHàqÙÑ*N…GÙpŠ4?ˆ˜~­¼ãRq7‰Š'*+ÿyïéËû2àîÓ|R©*µÅQ8äkt}ŸØnË67ÔäÕÕØ‹Öœ»·¹ˆ„kÔxQÂB×´K‰]XaÿÿKû=Õ§÷üå´HÌ3İğelçyßg‰›ÍÁf‡àWçƒÙ!&Oô»…± e½öy:@è4«æp£“œ=$fØyö2úfı~ÕU—w˜sMB“'8\åÀ×G^#raA0})ö¦»úíïjÀjl"„_5…¼´ïŠRpÙ]NÏÓÓ=?kWRpx´E‰ (Ä$À±E+×üœªÊUÁQ®÷/Õ
6
§3ówõâ¥®‹úìeŠğY<ı23ÂâÔ5ÏK½ãõÉ*-xñ¿Éß¹ĞŠE·SëØŒy1•GÜø6O‘N¦Ëî€à®”ö<”±í^ïİ*fÉG“1ÿˆllî•1“4S^°¡t9†İ¦C[Ëj~¬O]óáo´5İ*[°ZÊù{_şÉ´ã*+C’å‘c)şzt´7òúxÚÇ¥n'=âÜ¤?é8·:WK;ñ›'Ğ°Ø-l{°Dï·İVƒ<PÄú¯vYhµŞÇ+ I ’¤Vğœ‡í§2óÓIÃŸt>ål §ó±bµÌ0¤nG03"Œş™¡®VÛí‡µ*ÛÑ½ÃÊû<~ƒ*×šÌ7öêƒî™<öùI"©ğšÑg´ØôDÒ’9—:ËZÂğ’Œúª‘°ğ¶«MÀˆÂ«qÓdï(Ú!Ó'¼ÖÏQ}håé·ƒûo0Ã%ñõŞšg’ºË‰ZL·LŠ¯vlzµÈœ²Î,§jËº)ú§²s­S?;Ñ{¥×(Mu½ùÃK]$“y˜x‚åQ¬D—Ø&?X_{§Üè»H€¢Û¢Ä€ÖÔ~ûK„˜’ŠÇÇQw.‡sÛÜÎ»·O­— ÜÔ‚`¬)÷!eHo:¯ §û.mgœâ`yŠ‡<ËøÔ²ŠÈMQÕ—Ê;Y¸B«Üh{ÀGH!ı=ÇPî@¤¯Û‚	Cæ DÑš‰RQ9r’˜ó)åJ§şc¶sO’ël¯´æº¶iÁŸºŠW"®B‘_úŒ<·ì4£ù­w ä&ü‚ê­K!Q`çj@â;¥«šOÛZ¼´a¨d‚V†AQRË;ø’ˆ	¤PDÜ·OåFÁ7û–Æ¾ò¨e&×xS ãz²¢t´óãˆ OÛ²0ÔÔud“w
Øı¼.^*­j‰sÓ2³a#=ÇOuDô­V‹ÅX’·:Jy¯lœ3D0´ÆqßÎ3fòƒãBÅÇ£cƒèawÕ·H{~ºs1ÑÆÚ{3Uj@iãOó¦ML®ÁÄĞˆ¼–Q´áÏº“”Ù—ÿÏ’¾ºT#ˆ×RÅ$uĞ¸z¬?ˆ ¹UWZO_-%éŸÍÔ[¥$M¸s/HâÿTĞş¡!.jpÌ>ÏÿÆŒª) ¦¿ËDë¾G>ùÁWYí;9’+dSÍÌkô—{¡N«µ—&:}•n¯Ø]d£+¾É	g²š=¡Ö,•ˆícit@4a¥›‡ˆ©/úÊÉj;/7H¼EàXd|¬çh±¨X.œHº8Êóº»È4²cä;&°éB·:B¨AwuÊë´ ÃÊ¤é¹Zœ¯
ğ)½yŒ¾Ù"ªµ:»0ÑÕYü|¾lr‰)Tü¡ÁÕ=cMH¶íào[ĞµŒÉ4Uİ8‰ØÈıÈøŞ¤)ñã\•O,Õñƒï¨vLŸP
zÕ±BMèà…±HKç«-µ+xã¯‘ƒyaÚ‚Š&Áã–¼ø>ij›iG£¦gšÖÀ²¥Ö8D}¶´Æpå§®Erc%hŒdŠÈT’+‘72_«*kë]Š×ÃêN›	ÀÎŸTºş/¹ ­ü‹ÜHíBSÕI¹øSöšÙt¸P»=S¬ÙÀO„Ö†	· İÑá‰’æ\¿Ö§!“¶0qÅ³ÄrÕ5¡<ìÎñFhÍ~ÒAÃŠ¶g£²İ_Ó‘°äld XğÅØ|€å†`—ÁuFÆ¹-vá«âxEçS|R3®¬š¥(¾	Û$şnïR[	ù¹K›@“Iÿ*¨RiK§f­¡Lö•˜×d.€î@áë0Êµ95ÜMÙ2«I¾Vı#Ó2ëÉnÅ=Ë÷¹QIş¹pO{S¯&nD9p.Šß|Õlß/àİÖ÷H¼oH§Øl¦„P@7Ek"d‰_&…«¯¶Ä±ÿwôËGâxqY—x¸U”Ú“€!¢ï•1(ÈÔü>Ï_#ö¦ãwàùt3Åó&­>Ê±ïèÈg¡˜m”… ¶0ĞS¼fÀxijÖS,Q¬ËŠ¦E`³zR2wPo¡m+zŸèúÆ×Jº¼ã@D1¿(=G¶õĞX;ï}¿>$0ö°á¨ô‘‹\zTyl›D6-İˆu±¡{eh#¯&èR.5vbêJ¬¡¬êşÏ® ÀòÃ7QPP%u»xòÑ+¢Æp÷¯T—ö¯GÁùWN=%ªÅ½-ÑòéîWOØÒî–îS`ù©¹zÁ:k
æ|ş¢§ûNjpÂÒóÄWípØT»Æà%æDCÕ­ŸÑ¨CèµRãÁà]®BôXÌàÌCh©z¯­EwXì05ê(Ïàúe7woHµGªÇ£×ºë¾w#ÓØ¶ÆO:/ĞËÍ=3$6ykò•t7:Tœ(·mÀUxp¤åY(Úü #–wo"¢ûòÇıÃ
VÎä?aßÑâd«›£©Iš'ê:‡-#wTNDõÎ‘‚’îŸl_»açåˆƒînáÆ:8‡ÙHÊàÖ9fs+3Ôº°hyÜ{¿Ú¾eOpfµï¥¾[Û:††Né“8Io¡Õ2#‹ó†İ~^¦« Æ¨T#L	nõíå{•Û^øæ·[°g-mí*Ñ¼Mßö†ÍÒcÑ·g­,ßÛNÉ)¸]äy5JB²^:¢zje‚)ï¢Y
¶Œ¹:Ñ§”¹Mğ|8yİ VCŞƒU	†¹W÷Ï{ïxg  O:7Ô(Xğù6Ä$İ©Œl*‚Ò+êlğ?¤$¹K¦ÍQËeÀë=ƒ«?sŒúQwİYÓu¦=£­’ÑQ5}í¤³ƒ‚R8Ø°!@=\¿’3à×;áµx¡OÔò ¨X¢9”ó&s\omê?®éb)|ëÄëfgÉà	aïñ;°GJ]¶C‚|ùÚ!¥Cùi×›¨+êÊÒGÇçñÎR÷åk°‡Ï­ˆiµóp3e8r¢rùÄ*bˆÛ@H"ÁŒ„=C¾¾3·HrjÍQõ†ùX›ò›¥á·Mé”ŸA:šÔ;¡Öš[âzP{@øê®‘™İ+s#™ÓÆ‡†}=Ñ6U5Ó¹ÚG&³DJJ6gˆ•­¡g`²ız›BglêÅ¼<úò7ÑäË*ñ¢#µk`EŠÁƒW‡ê)wÑM²Ñ»BÀ´ğŸSm *Väo	ş*%"Å¦»m-xÜ3ö‡ï¬|=ÅG’„£Ê?SÌzÀ}‘R÷W)!\5S&-){W®/Öd¸ıüXôÛ"fYˆ´ê}^|KîºòİÛÀZË³X9ó¼_Ãh³;dÌëë+uĞŠËN¤Jğ\u+ˆMc~©‰ow•˜“z|·.•›p(‹Şh1^+Š;Š(Öâlî€’àr¨ŸÊƒSaÁìŠ¸ËåØ+7jö+Ç¯V3Àúñ¹ü	ç·ÃˆXY…Ò0R=£§~Kh=iÕ£İö$F^e²u_çç³û&oë_ÒĞÖŒP/Ïi¤ÅgC˜èuX’Şúï}U&}smZ;K]¾¶õJ?OXãoşGşÄàÂÑ^Õ "&2æ¦ËË-tÇjÙjt“ç<MpZŠ#7£U‡ã}Iµó*Á—g3zÀÖô€&7!äÙîW‡¬sVÓàHÃiğÀª®”0áÿ‰l{´ã@,heø©–ÁAj8>?öï‚z/ÖîÁ™¹ D?Ë[_ƒè¦UwŞ¹n,¢¹ÇK.42IäÜÜ<¼xB¿Yéu
ˆğ?Nü$Îª€©]‡«`h¿çÿ+OO­r.9T]mó¢`Ê½.œğè,zfW³³)Îêµ…í`‡H0Hô³7eHqˆs•/)Š( ë¿7Ï»†<Ş
“ å/’‰>ÎT²$+WG>¼‚ŒHC„KäøHu>¯lJ“µQ†ùş{5uÛS_çamP/Ö)×#ïJH‰GÃ©ÁÁĞgªû¤¨©k©ov7zrö‹ºt§2/Ã"Ï:†,Áí=–%™c£Ô‰éı¾Á»ò"=Šä
ø´µ	uºZø1ıÚD2§¦“ ²¦+1şô‚ÜQi+–¡"8~;Fcş6OVĞ¤3Oğ' §!‰âW9LeNs¿#÷µg°GÁ!üxİ:UW« $À	âlË–GÿÎ…•ÂŒ˜Æ#³á4Ã	~±gˆ=Âgü;ÏèC:PwÖê+<ş¸[napi&³zÔ¼áa>±æ8ÇªîCÉtˆ‹0·MàT÷>„‡´C;UU,˜·„K™Õà¹A"Š6™~dê–d€Ù.Ü'¥>üoX„KlÇ(+£SÁÂ{Ê½x=Ê:7„äæ—µõXÙä-O£¼€¤N¯½¯ÇÊº
8À¥¼È¥§ó ‡ƒ‡ôÌiùÃÄ³³<½éĞŠó	¡wI¹Òó½ÛËôR.{uv½?N¸"C/Y¶ó§J§¿«PÛ[ÑI-úl—«:*Hq«œ›IëcíGÂ[j­dJîª›¤‹_V/“Q˜õ¿ô†[…U*Q¡–ğ£)Öõö‰w(µÑ²È7¼õ®îíÓ;Â|áuDLé5¸vÕmC­¸J  5æ)›V³R’Š±·ÌÈ÷Q8~à;…¬ıö	¤Y©aµĞÔv³dkT–#&ı¦‰š?«Cf92SNH$m¥o÷Z+Aô_¨„…6£ù”À®~KsÃ)§IˆW2^[Cµ•;sÓäÚNó¼ò^Œ¢©=°.LåQé†‚Ñ/úi	¯ÀvW<ôÀYOº‡Ø4ÃŸ*Ë*öXá¹óVÓş¬Ø3•:-6ÕÔ9mÓ„*:îÛş Y`K¿¾U(<Ù®Òø2İ^ƒ$È\ÑÕˆ‡¿—ŒPŞ
|…m|4Â¶4ú×ÆÎ¸-üñ×B„u×B6à…æiÇƒ+_’R#h¥‡R>ùı'n‡“=a°ejJ›xZ.éT—8Ä3‡<_ƒH"Q®±áP
¤ÂÒ~¶D ¢
VŒ:œÍ~~¤ÈĞÊ>
„M­ŸdİOkÖë:ñ8îÁ%¢_ı ˆ^ù¢ˆzô|j®üÌÒF(¨`(ƒX|ç+PL=KY?n„MuFKxü2P]¯dÃ'˜ô	½ş„CyY2s_!É!/ài´Ó¦}ƒÀAä,«5ËNÅUíqÕJğ‡O€V€}¨?À°§ÂâéŠĞ8Ê³@ÎM5ú·;#˜m	]Ï²;AÜ—Ğ’â¦ã<#:f8™¢?n7Ç³~³î‹Êš}hõJÅ†ûŞûGæ[©Fe¢Z8y–v	4EÚ j•l¥lÆıñ> 
b ÑŠŸïì¯?ÛÒŒ<µº˜¾r*,¨Ã9k?·ÏQõÅÚıü¹X(^%ÍZ1uàİàÆfVe0ŸjÖ6©B·bYkr®ü×œ–I« ÀH…7ÑÔÇ M­
¢¹QÖôú¾„N­¥"ã[;!)(v•bHPb[y/E«Á;Qj¢éÎ·•ºâWu¬ñÏ}v«Æ€hI¬öR–DeµØ¶{©I›øÚ?Xûí6€“ò+­¤cLHåÖ>:Ùìém$ø1•ØI`ãğní9)YÈ€Ğx&ÆùÑ£oÁS¦±†õ;:Ó¼gßÖ:ê/M¹°	-ûA«RG†ÎgäSp@
¿ÿ¸¢Ù1?Q!“fN€”™ã7©ø8’´á+®ÿh®äS4£aÃˆê/Ñš³ÙÀ,5ã,G9këæBGŞ£ÊÆyíY¸eŞ	ãÁ£?½£*cÒç»GÆ¬¥/5U°¸2Áq´{}æÏÙ1‹ı0Æjìî[Ç97‘	MŠÍæRÒGêè)ÁªzXÛÅ‡iózyµû+:amà(dÿl•¯ä_MäúX7‘ÕŠ—–$éêí¬ÕÑP[²³Ş(çæË8×„³ä{#²a´ü î'_gßpvc.OUÛn€¡Ö Šd€j›_§˜ª¯¡&azIâvXÄ „Û1ÓZşl“²ù_M`—¢y	1ÜRq~ïŸkŠïIJ{oªÜr¾9•±q5:ªƒ±Ã¸?r‘IL"zíôxVï„EytÊŞÆ1ÈC£]êñDİ§ ­Ìğİ»E®‹üº¾_±íÆ_÷¯Ì{ÀmJqqG²* 'ïÇ?¸=`¢uÅ8/=ôh	ãPæéy/ÉÊ-2ÙËBÿ¬…˜M‹<¼¬{’Â4Òo¢o‰5ÙLªc¬õpŠLF65U%
Ò_éÌƒM9¶Í;ôO÷†@=,•Gm¬3§¾é˜bw	“^l÷?È Ôgª­ş¸5êc$}ô†Å»,–ÅÎ‰DÄ	†>Æ¿ÛÄ:À÷ öI¦Å´ÛÚºì1£=w=-*;9J!8Õq®£Pµ}àt´çÂıibJ‰%È½d§Ôoí‘ÖNÅnÎ®CG

ôRkQ„Œ=˜®z$Sï‚93Å~âûQ*-ÕÅ3'ú£·“3˜Î—YYâşÒÄÆğvÔO×%-ß *&`Ò¡øVù¶MWÜ*nMÄ>øq,ªªüu8˜hWÛP™€ÛPàÜÄÏz¼ıæĞÂzcêZ ÙĞ|ÄãîgìÑ*ê ‡` ,%ôq¶|í˜§•%›ùjı“:4ô;AƒãËÿ·,˜OÕ|™{ù ŒdH ºÅIƒ;§ÿàT‹h‡×=ökÖ‘eğkİ„:á¸ßÿ÷ˆ¯	ìÈÕy
›&= ¤ˆå£È¾ÿ#ñ@]ÇQŠøŸGâ
–&¿ŞuVæ§¾¾½DQ¡q*éÌ{Å†°R&c«íÂ‹È<MA†b«xöR6Vˆz'0èucƒ›Ï†5C8(İ““•d}ÒŸÚ‹%‰Ò¢°ßØésØ˜£àÜÇ£„Sx!’ÄØ4„ #„Ç†D!k»Ó©{™Z|^èO%‰iË«`à{ªlŞß«Õ/^d´àŒrÚwy©¿ßp]ŠÍĞ»,J-àRœÃ›‹ù¹ÀPCz(»:¼	lÜ²»3ªçÂ^ÿÓ>ÕıVÊ¡şò©±ôÉà¼şgNtş†—Áu\ÛGN“ëxÖ'±d\³§š¡\@ß¥µIá¼×¶O6ê#q?ƒÔ[1nsî><;ƒÿ¯æV¤Kü÷+ÙNÒ!÷£(¶s†Õå<-³›'Xí/+ş7Ép˜°P.c“¢–J[Û¯‹»÷jâ1,°äû ÓÁêÕãÜÉ|Ùb&â¿FœsZíFKÿŸQ„Ùı³½ì­dSÃùô‘?<tÚ‡>Y4×éÈ<Mk»y—•^ùAô %âMíÅÜv/´*åÇÓ³Ö•G¶ŸT•z­[yç8µ ˆSD>³K*İV4Óu}R8ëÊâ¯â_Îİ.æ›]Z{qÑ}Úğ9‹øS³?à]U@&ÆŸİÉ]Eù@âÓ]³rÕécv:àÌ^‚®<èRÇÉñy@ê*£l¦P)<K;Ÿ¿uì4HsÉıÇ²³x[™Ûòå®…I®Ğóš9ÚWJ¿æ¡ïj|‚M7n”õ8SwSy¾‡rÙW±N\P”wiÂ?ú€Spp†&È¹÷VèãlÔ8æÍÌ{H"í}¥È%zT”4c÷Áa·HğîÚ§F‘l`ï{‡ÊO^§Ğ×$ExôoĞeZJú Î?3Ğû#^sâÓ†áf=ı(!“jáAÏe+ÆíA P|ÂØnÆ;”+Ğ$Pñ+p]s·@ÅZ*ÓğWÅªP=O†kì™¦¬eÏ@.—-ûÕh]ü˜™„Vx#-ÜY&¢0+"u>MİÃ`îª~šŠ”ş“’w—„AbzG¿V[7İÇ_ßô½ö8°ğ†R¶»ÕçkXrÕÕ>b²„±8ˆW«îër• ‚ß>©Vqı»%‚‰º¡ê'•¨ÌÔ6,©,¸d¨µH"¿ŠÁDxĞÿ8>·Ë2Ø54yDùÎé½Ù±éd–={Y´üBÀŸ$Qó«¼çuÃàşïŞ[‚Æ*l‚‹ÊBÍ;¥N$ó‘¦7è¶4´Zi{zƒúÀ©¶‰ê²{RôSOH ´ tâj­H2X¤•©Se!r{<ò\õrÈš€L:Eˆ”R@y‡›¸Ñ)K°w˜J¥×‡X,]9“’zr ÁÑ×–°k†ô55æ(b×ã1´Xbw±Ï²†ûe¼c`Mx˜9şY0Éz™'"u_ÌR†ëºhç)ö0Ñ3ñNÜÕUªqH	ªõ!íúñ:¬.©s­Ñz.t¢µVª@·®ÄGSq’WMœ¹0ìc’‹ ²;„	C hëKˆvvªPùPUCâ¤F¢SÅf¹™”owUĞU±*Làº^'{ĞÎ?|á…BøzfúíXğ^¦Ğ‡èµÎ«Y	\? å>¸°ÿôœØÕğ–Fú©”û’!·ıñU¯û<IÈ§ú¯šMU+q3xŠê,!|Ìø·Ü5;Je±i³ì„Æx¸}äX)WLÎ¼ûÑ	‹jnÑÈJ‚iªgG‡fEz4· sJ'­€Bã)†5Fmñ‚ŸÉ£x½ÔßdSª&×yhp$0ÕM™O™yïèiç¿İc±¥”šrnQ™î40Mü@UâA½O!s÷•‡~ÜÊ#©)M¥ øP
©ıerƒe›P,Å5ººe"¤«Q÷XI.ŠİõÇ~HóE«	—;_~ña7Qe¬yg†ó”Ñ<7„”@‘¯øì­-Râº6.€MZ˜×–ÁİUëC²òÑD\îßßˆU­"Nƒë{KŞ‡1Í¶Š‘Ù`n%]ÀƒìÙ?#øôŒ/5tÿçëÂä[ß
àsn²*D]¥‚¦Iä‰"àëKh/ÆG"WÙH¸HW&nrK è¥Gí®­"°(ÀIoI´âÛ"„c-"gÅaLÚXhµ8]j´Ç—Ò—„ƒî§Ãğqh\<D3T¢Sİ/YLkÒ,Î¶ÒùYEYµUdŠ£®•ë÷YÂœ‘G'Â:rr
O1ûÕÁRKå"æP°JR9ëlJpby•¤\G|&)EğÍ1£{sp[Ïƒêë1ZªQk©(Md;à}cµ€±±¾6ÜŞv\*®ãœj'†ûH:k‹Ä<Â'`³qiş×4ENJ@Îßy:b—N”|×À¡<Vø2İOjbÒà<œÁ¨&À--£‘–Á¶…'ıö;4×ÕsÖ‰zŒÿ´”áÉÙ Âv1fˆ|ö7HƒªåVMÂ*BHV˜ÊµxV\<c:šÄc=ZÊ˜GEáQ"€„)	/á," ±Í&Ä8Ûümù¨õ õ/v…×îÒ2²Š"F@«òT³ZöDÚÒ8ea
‘°[B
v>»Ş?">Válch°°V—q'Eg&Ú¤‹»Ùà¨_õZ‰"mW
¼ÏM¬çòçã”PÃ¦p*ß]ÁU˜[wğÒ/ ì¹T½n´í¢jyòÙ½„Oá-± ³ÆcOìA>›!Qj;™-/öItÁ‚å€S§Oåš£jW™î„vÑ÷L,kç››X>Iårjä|Ìo»Ñ	ÍsÜŞ·”:çš\öUÇÀºÖ);8¹˜bUõ‰, /K1æl29îœd“H%ñSØî¯òqÈjuÔdÑ±]Fêâ—)|ªxâ´•¢qó¹ÚÜÃÜ^¸Ş:ğk3N<?¦=Ô×A±Iæ„çÓ
ÕÖù¼Èjıà
$n4í´¢æT´Qe
ş¯ŞÈÿº1C¿^qmÏ(m$Æ)½³®­n/gÚ¦äSí6.Jbúeğ±y~w¯Òş&§8*€Ä‡ùã9xw€õ¼Ê Õäñ¨ËK¸Ğ,çú²Şˆ,©´Yáªªë˜í0«:–~yMá‚&–Xçˆ¿ùö3D¼ş†‚p±»B`t…ğ ñºˆ+áÑÔDÒ'Ò{A¨31ø‘˜5â;`K™|ğ%OæìÛ›õT|³@†íJùd„¿@'™%™z;´¯†ííü’´ÃÆû«‘Ã @9ıb ©,I»q±f ¸³€À		¼n±Ägû    YZ