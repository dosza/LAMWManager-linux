#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2768621730"
MD5="3ab9a09c8ce48f0672787ac7fb711f07"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="24952"
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
	echo Uncompressed size: 180 KB
	echo Compression: xz
	echo Date of packaging: Mon Nov 15 13:06:48 -03 2021
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
	echo OLDUSIZE=180
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
	MS_Printf "About to extract 180 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 180; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (180 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáßÿa7] ¼}•À1Dd]‡Á›PætİFÎm4^,Íe¿iÙÔ†ù.°{ ‡½·œk=PÀ Dÿ}ñ!¢-'®w"KZ)!mâîÚÓJ¹="•	«æmèd…¹E‚Ov3v@¢L×®¤sD(Ù@š‰n5|Ş$Õ2¯ùÎ¦àiÛÅ:×~ê¶Ñ0õşo/€Fgò%	 oÂ¹¡‡9÷?2²À#dƒt®rôéÄ¦Â€OgCªèT*Á}‡(®´_^Êÿòİ©¨G-“úqúÅıl­iVìø½âĞgØ5ÏÁ´ß»bPö•A1)–´¯9ÈôÛÿ3í^¾ùB¶=$æ}#’Öy!KÍ@#Ñ9E0sç7I<¹‘ÖÌÆŒtr2µ „x¤	pbÇï	Á*	Xå!<˜ƒÃ²¿`s¦@‰Êr…‚‰;‰D±ûï§Ç˜Ÿ{ù¬kO[ 5ğ_HgÊ!ò>euø`ƒÀ€„x1©m÷}»ßN˜¨\wVZš4üåˆ¡\Ÿ{2<íéö”Y¥/§t|ŸşŒá«:…·Üº@ô)`Ç¹5­4Ì¹²ıôQ‹ÆRçĞ,é÷Eª–³?z7ç¼Á¸ï•d¡*vıTiÈğ	 ÑÜñ!ŒJ«Ú¢ÒH£D§ iV^à¬±Åæ¥­ocQù¥Í|N´Ø/F+* ´¶¾}‡‘w¬Ë§äGbB²†;›M½¥·lj±UlìIÈÕEk¤å›b5--¬/h©=Érıı¡ÖƒïA/ &ñ¸±A#¶Ñ+…Ö}mÔiä†ï|2w^©šá„’`½àğº!›’­Ñ3«ÓP3{‹¥ä8[$.ûá³»Z5íG:$5gñ–ç]Bğx$œÌ,Ôşbq…Vgªû±t}dƒxí«ÖáK¼JxJ¦Üotó°¶a6l%âÕì_õByÓ|h{:VöQm¯ƒ“Ï'øõ@ã‘ŞÌ£3Ñ“Ãõ:P>®ƒP8Fù ¥NU€¨}ºÑX¼×Ü2g†´Ì/Xeëá!©m4ò÷4RÓ®ì!"Q6ÚV¥ˆ¶Ês¦Ø
;ŒøööÇ‹oR#¾/GL8šÅÑÈÎ0ñ!Šşôop¹|·W fŒugc®Ó+ ¬•k.ÒTœ<r4qøL§EoÎÑxåª93xE"IAÀO]Å§–gè°Ã`Àİ™%.—j_±!PÆ••4š¯¬à´aQAMˆÄ£\UÁ$MÇ p,¸ö(Ğáë—7¹ÅivŞdš´»Šß…ÖŒ!ôı‚ §íS&€ÿ+ónUÀ8õÁCiˆîã\Eiñ˜=ÿZÇ=jú	
®ŸÖİ0õêùsğ	qm»œvH¿ÃhĞAĞ#Í$^Óxk€ã­F=vÁ-Ö8I¢j±ŠüÄq-ê‰4À^fšğù'N5o0­#iÕr€Æx[g¼Ìÿ^¹ª©ccğ÷rTS á+”¹vÈŠş:ÓW‰ÀŒ–C¶LaŠe¹ì3k…‘Ó@mH…-k¡ğÀİa®´ïèum"l±~¶µ´%TÓnê!½y’«õÌn=ºÏY4O^!}Æ‚rØ	?Pã<FÉdŸ‡Úô¸[ÑUvúQ"ŒÏÌ÷J¶2¤x»ŠEó gÍ˜|ã8àğMí¦ïŞ–£âåÆ@íœ6É5 ÿÏ»+ |`dÅYæ?‡÷ÀÖAK,”‚´Â[hïL+¯ıíòï—ü_(è@—0Î!$±ğôi©¶hL^¬

(fÊ~uOeõ=m’ÚM}Or¤Iv^Vßóh¦‡êM”¨•.ğ#ó‹–M:ÁK‰ECtZ„ª¿#Ø}4Gu-€¬ÔÚô®Òëgø¾ÊSñÛÒ»š`…ºÏ%ÁB__ ›e°±=Hğ¯RåpCÎªsMÇ6a¬²ÂˆóîåFrİ>g°;	NU…¬­Ç øGêòkÛmC´ÿVÔı}¦«7JCÊøÛ8‡Ç‚ízUŒX‘ˆÏj¸D˜àÅqFKv«0ƒ“7PÖ‹q #ŒÙ™ÚùæHœALÒ'¯äMšÜ§åy˜Ìv[pğ	’5Èàs™»Â ŸP—­s¼fı`ô_¬Ô:\¦DÕ¦ ‡™®¬õK—s…0O¹N -“÷yÆ’{ü†‚Ïüf¤Ø#i‡"¤óô€ñÛ£"s•ñ0+¬Ù­mgš;ôÜ¸½öæí{e[M[ï`£Éìğk¾¹%ßâfå{7ÂP;ÿâñgª0ô9Ú›²¸-¦C×+¶ş P¦%òTë©‰Ì¢qİü†ô>Tr—BÒVNjZz6¢¶]yá×v×]›¿x´ğ{ù°"‡06÷ôªòRj`¦O3„0ÙXÒZ
W=¬uµíôH@™5Uk3TÚUrô`'¢!ÿ\¨V•¦6Ëç.-®—è}ûÈDj›ŸßàÀ"
/H;aä7@%;†¶€¼ºû@òWè_œó›ğñI–ò’Ô„åûQ­Õo<ĞÇ@5*ÎKDÛ6$Ø•ßµ´]¿3¸Û[Ûÿ–¾5ƒt]C»«·°wUÉZd—	´Eòù—UTĞJ0Å‘ßÕã®Aw¯Òïeè ¯Cä±‹|‘?Û;<àO–¬g+o5hØ;B_œR›×[©ÜYÔb©eæ¤[´äÄ£ÒÛş¨—ğzÜ$d ÂL>ÅF2‘ğ;O©!>ƒöQ´¹
¨Ó$Ç¸…' „ˆŞÓW‹z@±Ÿeqk¿¸B²lA†1A»0nß2HJi’ê¸Ê`Ÿò²Ô!ıù‚¤yå®fo)ôÀLæAİÚ—¹p.WÂÏnb¡ 8ûï)y¾Âk]V BsÙÚ$?:|Ïş¥fovtÌ˜ÄR9özÀFbÚØÅ4x6kLp˜LÔæ6MÃâÎ;C„ıwhxC×¼Äğ8¿~iÛaÛ|Ó˜ÕäŸx)¢µ›¯­¨å¢PÁøW_lÊÖp®`Åñª¾¹óEKÁ±	ÏIöáT…¶ŒœR¤­¿¡òÚ!G¯KvXFÉü@è…äğP¤´pœ+`Ä¤F‡wRğZŒèHûæ4»¦ù©ú“7üãár[f„c`˜ÍHòÈF¶ê!C ÓºÏ9±ûµIg6!Á‡.¯ú[Îyß#–;»©*†]-¾¦‡‡,õs~ÃÏ—FIªQ‘L>5±ª!¶}ÚnZID1
%"?]ŠŸÈ€@h¶!3óÃ¯~¿Æ½!Štø‘m–‹Áù¡Ám‰OR˜ÇˆìÈº‰&J€òÊrH£«M‡/BÛÆÁ&!8.¸t¾NÅ¨¦úÌÓìƒrXd"Qg*xi$=`Ï?·™;Öì5Ò ä;¸d|"yœ•ÂZÂ ™UêpÃ$,“Ò<+Î¥P^Nõ;OÉz°Ø‡llxkÊ)çò—÷ò+¨»¿äïÍ¢ÿb…n=Nù(¤êh<Z‹®¢X/w fØåå¥1*Ö^8G˜ÖXÃš™"H“˜±*B(ÑWòNÎi½¶\V~	/µ3}(~pj´ŒK»’ XÉ8Ï<4îwìxrxO¬ë¥ôlÓU[ÇÃµ£3äGäw=w`1ĞÅø5N®|Õ©MJ¢}KŞ1‡µ9îøMòŞƒ“½XK8Jâ±ÚK…kwY «ågûa»îÔÊD”ˆª¤_ÖÛöx*.ı²bP>íNø6°ê†–°ÎšŒ—`ç„5o<ÌˆçijÊQ@R×İõWÅÌõaÆî¬ıcÆ¬vë =|<ÂÜöÃùâä‹nJ4%‘²ÿá³0Îa)#É>DËMùåp¸R©ÉŸ*Óã”ïn|4üùœz[ìi§•Ç+qšN”ˆ	…â%LS:,şdGE:®İœ¨ô; Áh>ËÂ“"ãÔ›·m¨p\Ëş4'ÂG‰ÒÌ¦íOàêÕ¼·¿‡ €›x8X4[!34ÑæÇÕ©MÚ0ËÕÁ\{wv ÷Òh¸Ïo4àŸ9ß­•»¦e^l)Ë¬Ñòß¹YÄ*©ò`€]ô‘|\ú^+äÖ•tQ¯´èÄTäN19ÀÁ—UX@bÎÚ´»,mò½V¥
agZ¥ÊÒƒ_5¸/Q£ïr%•ÎBöß°C]ºÉ6Ë}³ÂğNºdÚ|lüâSóf•±Ş×fÕ-­{g×3†Uo(‘ªVß¸ÿ0°KÜÅ[)CI(†,c¦vIŠ“!®wF{ÂZ’@+†³c‡à*÷Ì11OE2PÁ$ï"|¦ZùšûöÓÎòGO™ Ø1rÛ°pËë|uF R-•„ŞL)¯§Š‘—
š¿_8ëw‡RÔe~0-NêİŒfæi€¬æ|å<%Ö5W=0Ø$³wçïäj!  ı£»Ç/UÊHç3Í)+ó’'ô^¦âCô†ÂÖ­šz	©' ¾ùâ‡Úğørˆû5Ï‰ëvš§½¹${ãŒÏ4Ttg’v[­Ø<›âÔ.È8?ş2®†…‘È>ZÏkÕ]ôpöæk„Àˆg3}jï{„´l<"Š\Š[<•AáƒO~wĞüÔÁ0m%6ybÄsùH‹©Ö—^©ËÒ&TìdI‡a>WÌ3vÚc–sJ~úù±~¾oo{fÄ]‚:§œÀèt¥9Œè%)¬€ÊŠ_,F-b•ušÕTYv7ŞQàùËÔ]ºX¨A±G5‰ˆ)±Ø`Ô‘fí[†&j+UO)'VH5®’À~úµdÊæã½Ëyö»×Ü	 •ÕÀÿ²^ZO4ùD3kš!b˜²ã²ú‡|[Í?ÕØ.w5,ˆZ0³@GİÛ˜FÿÔkŠ»nË$ck(‡
š¦Ùt1›—xÂÅlk\yÄìµ'A>^Üñy>Œ¯˜é»İZ[!|kn—Nñ#NùµÏÎúuÿ{> -¥n6°ğ¹jÜw`êÈû¸1HòCíıİU/PÅ´œVY§”î¹6p-h1`6×Á«¬!°ß8ù;]ÊÜ´/A‰}´şæy6µ¥×S _öülm~àøo^ß‹«ï‘ÕÌÏ,\¡—T¦já4©×èE(÷NGksæ&Ôï>èzŠAO®« «'N{àúv[,)…:ûó¯úrF:¢bãRÒFAëªæ±v§Œœ=°5Tí÷\ßMM„}èÓ[é¶˜MŞß…vıÄ|Ï‰¶áÃ–ØhŒ‹ÉÉM«-Ij_IÅFHRçª¹Cm½UEQİâÑŞbOÛ¿éÓ °»x|IÉ¦êDIÜL.Ûƒ{°·i¾vú£ww°ÒÓuûÆÁ¬”ª„~»SmL‡wY^VvaÆ1§¹‘Á ¹·xkUƒğWôïãN½¦"p{OSº¶Ÿ¨^?ÃoANÕ<šÁ¯¥§ ›O^QÁ¯¤
ü%>]7G’L/ÁY8Ø”FLó È›„ßÊYÏ=…rQæbD5¹ÙG(à­ş$u½ûBïâÒÜ¸O7ó]É'P,¸®ELIX“
^!9Ğ…dG,¬ƒ¹æş¶Õ‹…î´Q?ÅÎÓQÿ«n5\Láâîbº;|´`‰cÃú‰u´ÏÅ}½J{)V%QãÌjP	ıeÊšS™{ò¨ Ù‹ xı€µéÍå¹ü>	ÎÜ[' "Øw?0úÚc)û¿´;áD¢<{Mªİ_ˆ¾U'iøàyV€0$vmA˜|ìÅ ò?_–ø6…`Q*û^v3ÌhÎXœæOS™L”3è,á¡Ú·B”›-Q§§±ÿ«†X1ëĞ/OÊŒíğCÓş€4]ôQN2<\Œ\ŠlIò72]1Ô.2I/½ÇèÎDÛòe¬Ç’AÒ™Ïö×T©“¨ãa(X~â7Ñ¥K|¼f©l6”Îèä§ÕÖ?pmO’ßKjµUBæ±ˆK"•ûĞŒVÊQ´È53¿?;¶Ñ)CƒòÒEÒZÁømÄ1göVzíPyñfa“tëô$dv!CÇÁœ-‰5¸ç]ù}øË69´\VJ¶R| @*¤fƒr¿\Ãù°D;fÉ¾ˆ(“ÏîÏ¿lööQÍây‰çw¯Œ­§ÖyÈ^Ş{j•8J­Ï•a¡…çÖÄ!aÌ8‹.¿K%pmt°±Ğ§±m}$ò3x°{<`ĞÙç¨êé1mÑ¦ĞÒ·<‰gİfà ‹c…/éy4âÇVe[‰|C„(Ë’àf˜mÎĞ*&EÏ:àºVâT->¶ƒî8Ğ;“ŸfCgÁBC¨g«tœùÔg
ëùÅiÉŠO™­Ès ?‹èR v…k43{g'–‘ÅNø-˜…ÿô»•Z:¸Ë<‰,ıg«¨>' |	–ü‘x†ÎÌh1Ûn^/8Rƒ{_ùŒéî³â(û5ÖãÀõ/~^‘ôâÍÖ•{ÛÅ:ûB¶X|7ªÚ#O³ÂMWf”bIF† <ş¤·A…9¢«û¬9ÚŒı jmì&B””¼¼v>…­QÑŒbF>&¬“|‹Ë)Yò–F²§¢…ë¹¿#-ºyI¼ìÃÔÑPONFF O¥”1!İ]ÜMqF^i?ôŞsšqb¤Íã°¶ßîÛğàã0Ş:UÀ
¦åV˜Eã‚øÁ!™“>Ä"ªËf..4‡ˆï|„&æ½š÷w
VÂ1…mUí«¿E¼ƒvÎ?üË"Æ©€”ƒJGfß¨êÍÅÕVs;o)“åF*KWc«rAÓšÌŞ b¿ğ2O2ÏÊÌµu;‹Ü¼0Eñd‘À%ıXå	ŞÛF0‹<îâšDeÆiK€À„İ00IÄ	â¡,[©¾íû”Bë<¿mRd÷½$µ¿–7õC_,ÿâK³’ö3n-iİvÛYítÇÑÒäêğC6Î%h
0ğ©Õc§¨VbTR·ÅL$Tì_e$W>Ì\±¼[ĞgíÙÍ 0¬ŞZµÃIàÕ ridÅŒ+y#ê…5ŒÇdğ6`˜¦˜Ò­ŒA\t7÷vøDi©Ğ¡İ`ú“w_2Xm].¯ú×‘†Uo›\¡$–Áíb(¼ªÄw\\¡…8g‰Íxµ±rÍW z]HksòU‘ÔJ}ïÿa)¹_±İØªzC©ú4K4”»0¼«Ÿ¦Á÷ßù£Á}ó+Èıa¿Wˆ|c]#hpfb‰µHøFTâ_…bâm–{°:£ÃÛ³V¸nëj#RÅV˜ĞK?5I¹oRƒTğ™¼4Éıÿ*"—o´SoÜ?ş,ó˜àF#ôâ7›6–»ûFA²ïl Úˆ)¿Ç)¢gÁù!¨®oH•»ZÎ[”¾cY}s±DS&èI‘p¡³q…n&üòš7ğ'C¬¾mº&oµa‘Öiğ„ÄºùÇ<¶7 Á[©h¡JE÷Ô¼X ¢F÷üµa¯OIöÚƒ}à8\£Ç+Ã€°
Œ4ÊqåI$ZDTÙŒºyhåWx§/lÇ´+bÀ®¿Ì¶“¶'İEyã"XPGBt#f˜Åa8°¼ÙÑn2½œİÏ4ÓCNZ í¬ªn‘Áâ(©a_C—sb¶'³F·àáúñ1`Íûj÷
ò,¨·ÌÃ÷rKµ©î¯&´nW“ØŒp`¬ò"ô*’'y!éuÄLèÄ@FTj¯n*Æ Ü†D?q_'olÕº-‘EmàÍÓü0åÅß®\#Wò¢…¬éëÇ´‚]û#¾²@!‰5Òñ3¡O¯V¹€euÃ–hgÌŠ;j÷@·c˜°ºxËAjyÁ¯Sd4Ö7Yß:ÅËØ¢aÀ»æ2gIßœr•$#àw„r¹¹|o“MFÔ¿ş½‘¦
ÛZÙ-ÇC£àÅ$2õbGº¸ i1	zFï‘ceã.DŠùG»;ÄGˆk‚wƒ2:ø‰!ÏXKµ)ƒ÷ç}ì¼_ÓÎî)rpÂïj w„q_$A€Ze&¬©¸÷×Z¯Q9Æp™"ÍåÅ{ (2ÍkRzY÷$xDyX}Mv.¢.‘ƒƒÇCéI¯L± 
÷$wš4vbN²º]uüïœnwÚ¨[F¿,´¾÷ísÑ¹Ä÷Fm4ñé½æ·ó¹ã×‚Ûy8÷4j"³ŠWó¢†-3í¨n¶™ÕØÄ1œŠ‘_AB“ËCH—¶ÏUõÛ^N×ËíŠ*'ï1ù¿m{if"ü¾A½S[Ğ3ô OhghJõšáŸr,²ÒuˆÙÀ2,trjpÆ'¶2~oĞ„ØúFù-5(~±+‚«ÕØØ4øÁ$GÇ;nEËÍş)ß{UTÜtz¼4Éj¹á¸ÌIPJCdV¸k€¬Í.¤^ÌÌÖ„×fÆñ"[oútŠ)ë)Æ0?Û9&}HÙZ~’MÄÕÅÍ>ô{€1ŸÒ±ÅÙß¶ kÖ£| ù\âˆêä9…+)»*úÁ%ËĞRP`í@9ZJš˜ˆHye øı¬©ZÓÇÿçÂ”"¡‰ò­2µ#@D(@?­¸)5ôHhfÒ¯ÄÎ¼ÍŠ$	<µqcÍ¸T!“•êq$Ùxaç"Dü@R=rQ©£}Ã8ö¦t2
¹Ë’ÖÇéí=öš÷’p“óË×ô,9»7É¸'DBİ3E Ö•ª^]Ó¡¸ÎÛäûü†K2£ÙÃĞšGº‚Ryr˜CÎÿÄyŒ"btæI¬LšÿK´¼-¾8ã×ª7qÄñ|Z¨ËökUtU¦84ÿ,5;`zAÿ¶X®Ê€ùgü˜²613K'¥wÃºÑYTÃÆ‹>ó(hê¢&½¤o#&ä¦$Ô*ûÉ Î€<cy. -,rm†J0®=÷£Eˆ².
÷]Æªˆâüá®_{Ò´à¼±£‰UÆ¿ß,çœ¸ÊvôGÒ­>"/È1[	Şş®§BY¨<öJ}2U ô%wü‹ÈüœìhU9‹í;ã4Ô	µEiË‡T–vésŒÎ Î¼‘Š«ÌƒÜ‹z7]D2ĞÚº»è|e\(Aó­IÃ0wµ‹k€74‘(„´²Z»›S{sËHhš1ÜÓj#3G>åŒ=Ü!£a÷;¯ëz¯º…ÎóúòGô¹ò¬YEZ^÷ÓiÂ3~ÃZÔ:7‹µ—£¶Â&‘Ÿ¨¨á…_I¸zÓšBÜéDˆóó¾Ä¯È=…~ [kÖo),ûQ—?9¢I??­› ü³¶	™Éö>í¨9MËXğ§•Î(Mi)ÒÙÄ¯=2zÌRe½§(u«³2ú›¡AÌ™@2lYVÙd±,|1h¼¦
||¬!?ï;>(Ñäª!!¿­Ù]Õ½È8›‚½ışr|‘ì³YŞ¾á~_fOášñÖ<4·9÷É±·[Ö‰îRd´¥ÄîÙa™›æ¥l³æ“VÉ^ß²"ØI—-­O N«\›òTÒ¥Ş–iœß,´›TC »ù	¨¶®A|•oÌÃŒdõşFÆ›Í½h²ÿ‘³c”ô>Ö+š+÷x°ô“éŸ·­ı›ƒifÁm}+4úôÒ“ü€Ù%Î„DúŞÑ³úŸŠ­]G…şÙ˜£X¤ÆœıPàpŠ¸÷¬Şï?SO>‘šÅ¿äÀŸ}ÛêØÜ9Ñù&Ê¼bı?bÑÆı*ıT-IŞF0 ¥ò—"÷Î–,Ó":Ï#–àD3-ë"Y˜¡ò¤GëÃ2Gcä;ùcVFI­”}MÊC:¸ûLàæ”}&ÔWlyş_­édŞ]î¨}zİê+®Ğ¹]ql^€îø&Búİpİ5å&°Ö±Ş/˜&á…oÜ’êäò¿]g\ÚóF¶¾(Å±+é€ÚX^sô6ÔRc±ì—w•ÏOThéc%åf9&{ˆjšîéûÎ÷uÈvÓ±¼õ?« aKq“3aÃ«—¹œ`+;iK„[*ŠÉ»v(ÊQÙ™îA¿õ¼İ¤õíŠz$æñêVÇé§zO¡¥aGà)¡JC®å°·+‰¥÷c¢@Ì˜)÷}aw;-Ï0OIrµë‹ñ4J×’WOíq£ş“Øå¹;FiĞà=ğW¹Ú@,Jå£„¢_‡rÌÓÛÕcÀMzùä)¶>VNcsQXŞœµ
ísÔ÷6ó1ÑKW »qij}ÜçÔ¸İ\Ú”Úb6kÌ'à™‰0N'1"¤~¾Bœ‘ù·@ô3Ë5'J­úé|ÆHDÏõµüq©7—Òê©·5>‡p ù¸¨f&Ó!,¯õ`Ğº)«Tî9€Ì`µpËĞ\^
pP|Š"„b6;’-ÕhtgÕ1r˜vuĞÅÀÎÃ8zŸ}œ™{ó§Û;åî›Ap¬ˆ^OµÆ‰Œ„X

™ãlk	wöpë!¼)İ™ä:¬^î k³½6D`Í¢<t<p®¥‘eâ)¥)•ókkrc–qÊ-°9N:3í—Pb,\lÂlJğhP1›ûìDHXwÓğaíp2B!(³kóÔ=p’{W„Â~Éøò4) Aıìğ T3çx¿YYº€ß™ÿiÅ¡–=çÀíg;QåVr3UhAg Öóo1‹0|RÒæ°Rò¬‘06gc‡²›¬…¤;ª§š¾Ï×ŸÀl5Ï‘›'ªşo*†AÈ22@÷™¢[üÎÎ<)çšØµ õÒ*ÈE¶(ğ~ïšˆ¯(ïè$‹ê¥Œã´€Y%ê³nÚŞsÃ0ñFu°]<Øï­„øuøå+~}ìBºÌê‘qâúùØ®VupLåXsŞ½ª€lÓr—‡_œUíóŞ+t:8éEv'Å[^pG Îx/¹J¸wÒ:DH¢]îì°ˆê®–»´/p±Í`ıûøÇÅÖıºÀ:Au$Ú£Œ ¢S___ù‡u`š‹´fKÁ8Ê£›À\åcEğ“=\]åÁ k¢dşRä1É‚)+6PAß d>7À¢Æéxùô. ûkyöú}üÃ3|1$.Ù-£a‘NõcvÃ™µx`WÇôZÌÃ:ø8+­.ëFˆ´lãIÍ+RÌ ô'F¸ñÛØµøÉĞï{ÉíÑña°ZhŒÏä= ¯OQ×IvŠ2(Œj†IWM4ÇzcÃ)gPÄÃ„m)ã„Ôfû–/å‡+u|`§E> °c›-32Ó$Q¤“sÖ"nªö*½˜‘vR,Ò“ N×`\~×¯Œ>ïŞDØVĞÁ×ƒa¨¾âèzò§e¸í×’ÑÃ™6úŠP¤Ñ©ŞĞkW’ÏqjëËÄ@w¥ùk`KŸ®oé Â^$ È3ş){_35qìûÈAÓŠ!M«”ÜÛùD™ˆ™}ô>
L¾İĞ&Ò˜öëØ	æjDBÌbB¥m9‰ÜüüÇ€öÎ%‡2f?·PÒõ”=‰3Ò´p!ãı©ŞµÇq“¬‘š»³-ÿIGˆQÚÇO­)ø©åg°½ÊÆŸĞ«mê¶ÚTa ÒªÚIú>¾bAÖı’F¥çôI­}á¬w2Ï$ÔD€ãf9¥ç¿k[xViÿ¨Tz8S¸¯¦²â˜=¦kü““x_ßàÔ%ù<I ™GdÔ¨|'ı~pl¨Ô½ÚMnÒ ‚tÙ;"¸Yb³ X{amG¦n5p…OÙz¨l¦938ß}…íäAå‰!ôÃ³V‹½ŒLæ"¨;;§‡¤å@éõ;gÂ¸CË™3D#æå6º)°RùM;ãD+=Z™á<W}†*¶ÿm Ä˜vY«øÄ±ñ»lŸm«¶:3SË«ñ-DÄ7dÀ½ïCË¹ÈÛN1 ëX±«JKÍM[ÂË4ûÌ/¨~¨R‘ÿàÖ‰ívü^øq°«à,`t.	Ëœ™'è¨ÿÅŠ†¤Ï3¢Ñ‡Ç1¿aÀqT3÷¨¹ü \@Ù6NéJÑ.p¸œ¸Ôäóeœƒ{i¨?å¹}Ø¯ë½ÎŞº$"xÏƒ‡V‹E¦éˆÕ;œ»b·Ë:œğÊ¿xC7{ ş[ãì„BÓ§4w˜@) XÅô¦d²ÿ¨‚˜^¡ e=8˜ZjcÕ|9N‚Âë6ıìÏEp¦ïVå{aò`¥LÆåRõàù>¨“á¼<3áH ;ÙÜoŸ\°tfËÅâÏ
¦ßxˆƒsV.v ¡¥ğ«àÑ$0\ÙAª²ğfõV,ƒqUËdfïry±¬lÑÊ[Tdú‰síİº•@o‚ÈÜ3>¯¨Œì\=whjù×‹¢Ëğ8aı,‰¤¬Ç¸Œö¢bh}{yÆ¿&#³œ#„lt•{x¢40¹ÿ ş•»]5£G†)b“Qî¾ÜoD&íh«> Ğ0İÓ€Bİáß}aDØˆ]kÆ?(’ŠnTÇ’u]ĞmæíI¯Ñ’¦`¯Tê“äòe=³ÜÙ?Şêh(ƒœ)’b'‰øÑød:~È\¯ÔíNâÂÂØ	°Ğ½‚q?îö7á@@‹Ãºv±V‘şïˆE@æ‘ hUØÚ¸2ĞÌL—ÓØ²,Åz&&Ô;$Â¸<Æ3¾ú¦v¿¨ôBëd¬/ Í®Üíëz{¡ÏÔD?ÊR+ıãİ µÃWXïXÛ+pp°n?àò0Î©rœ‚æ«ŞÄ¼¥Ô¹3*YÍ|µ0	¦äô ÿ&ñ8õ<$ôİ:Fê¿²+ID$FÈ†H¥-ĞÛ“C[ ˆ¤ÛLÒğcçÉ'hoâàöĞc‚†ÿ‹9¡Ğ·6CKeì§,­*ß8*:ğE‘‹Ï7¹§£òb°Ç…wv—Îİ[":KY­TfoE”–b¾brdR”jÉLƒª_réLÙ<8oƒ³zË'vgKvì#rHOŞıà#¸à=á`×|*sğ¥±ı›Øë!ğÄçaïÁƒ³GYÂE+éûÌÔ£–£Zöí^ıWP ¸U°%Û(×v¡;–Œ¥¶Ã#‘Ÿ©dŞÛ{>XıŞò„µÚıõQOÅv 2Ìg*b4©‘Z²|&ÊpÅ‘=ßïü÷iì7uøSRT¤¡5ÚCcœşÅ^H$!×6ñhP™3QæÀ€z¸wN‰‘h‹öö~3šVjóKå+$P’°/yšxÀXUŠ&¾I¼¢
qjkKc†Cp4š‰D1ö?åbŒ3 ±Ë±Æ!µòÍqÃêáa@Á?<gˆög´–Aer’Ø4µ=©Å(P´—·É$Ó±â7¹'ÈzŸšÛ×2SAxS‘C»áo”¾¦GsSp»Èë=vú0œ’Vİv·H§Ï/(;¯£zÜ2'ş¦ûKb/ÎÊùv¯0èyÅøèLµ’U!aFĞ:7æBÀIİ†bfu«ØÒZ¿1¢}1Ôâ?†Ş›,Ê)¯kŞ*l	êE“"téÈù
¾Xë“^Ú0oº/Aèíá$MNø’y11Y\|ëüL{K^¨ìj	Ğ-:¹ÉyÒ&¼‚û[Ì\Ät‘owoâpÆ—m¾Úœ`G	æoc®]Y„´ˆb(Ñ ¯dDÔFA—O‘¼ı™gŞ›`ôgÅ&8=Pãr²3TÍ-mHªÿ¥GeC&Å¸Ù·È3yö1²«øPĞAXzM¨Ö ‡6Ô\®Ç¸¤E©Hù•uSå®÷PSº¾®àğ=?®ñêWˆJXYÌÅ±"5!dlª¨Äè4şê~
@ºî~[pNOâhM«*ª.Q³ .SäŞAbPoc2QÂáf*aJ"’¥x÷È&Fn—{Â¨PÖÇ‘è©—97âØ/;³6…)¶oŒ†©E
ªíqB¬zZo)¸)1ûî}EL~ÅÊ4Åß&ü9ÑãüwMIàìé…Ş®må«¯XfĞviGur¨Ë†²6ìü.ºÖÙÎ«¤ÈÕ:œU©+Üä2ÁOy‰*ıå$ÖÌÿÅNC³O] ^ç Û…÷ÏŸ–gequgs©‰ÿ#­ô$L\O|Æ0‚±l^T€d-«-5ÒŒ™A² eytµ„Ù¶ÜçUyF÷RD£ë
‰Jªí}SÊ$ÕîÃıŒEÀßùX^Êt«ÿœ	Lí[„KØ‘9C9âÎ ŞG¡ÇW?€V34w¦ØöÂ¼qò @pw/F¯;x/í›xî€†Çã¶_ŠyK1©éjÔqèÙ5·ağ(‚$#qŸ³ï~?¸E±ÃúTº“,yçÈ-]éLP±´Àj.{
vXQv¹¬Â>z“€Ó¹ódKÚŠŠ9²¤ğ€¢¨ØŸ&7«2aKàUœ¹|ÒBîæb-ş6yvŠ†C:—”¹ƒì—ã{àK—Kx?X!.ñ¨ˆêbÊhù¿/;Œ¿Ú)R²rƒzQxK ­UŒ »6&Åq8r2[2šìYê5®eµwîks,·ÚË,Vİc3¯º¯Sb¢DP×ôdı§jÿãÕ’Ü$g#oBLÆÚ±ÙFDpK”IQŸö{-¤5­gLëHMÃê8‚V«?ïl?3Çj8[rHN·‡ ¯+.3òGÈ3Hğn¦º>€¨à:ÇÿÉ3˜CÆ×]Eoñ£²4ŠÛÎ½šA›qŠÛLÓ.v/„w,ü½ŸÍÍ.ŞÚ«—>3­dSÂN’†ÔäÆeË*ğÙäÃ/ÌT™×›®!µåV$	«½ÉK±ğÖÚµÄ¥uRÀ)³]É=v‰Î5BZ„üóeÛ¢_ã(‘Ô¬]¿W%>·¥ñ—>N!ùèdØv7	$"ˆ+Tµo5ÄİJÇ4@°$
¡3œr†Œ‰£O?ÚÖ	Mê>ñJWáü
Ï§ãéÊ5Wƒ|¥LË@œ‰¡âÁ=‚ÃÉ1ÉšüÂkk‡»9Î¶ä´~*$Ès~†1(U»7¯L‹»u­æ-YÎ`ªL‡Ì0ÂİÈTC|évBÎ„×LR,b-ËG¡ÿKW—ñfÚ\ª«4Ë4+RtÆ¹HS„è~ßpïB¾¬’œS‚³±ÿµGQdß(aG×Ô[1ıè^¦<«ìò?a\K@ƒXÿò"ª‘7³fÈÎkSxxS)™½ÿ$öGâF×§û­¤Ÿ·öÃº”î>§Ÿ€œ`÷Òt•ÊyzüÜ¨Ã¯8@Å6ªÖLùçæ!G;^ûEg®YÛ5Ü#¤0óÕ¶ÍZ¹yŒö$à©[!£Î`Ÿ¨›ıÿêœ«gÇğ)´²İ»àjÇIĞÚİ Ò^Î»¯@4mç¼øv×«e$gâßIÄî”À¢HµÊ<øp ¥½7z#c×7ÿÑÊ4%Jñ/—äÄ£h¼ú˜B6İ>7¾zF§°ÓH?¹`àH8d‹Tœ‰–´4ú¼ß‹9õÖıK‡/ß'‰FıW;/q·ÿó|( RxV5%ÉÀ;	|hè6é¡$t32‚€†Áf6¾š…fpYmGä9¹Ñ¼¯?ôµãÖÇ†şÉw]«Û«ç¯ûo]Tär*"uËà`|·9Y~*Ï+‡ûà²ˆÔn%[M[:rXW=•Ë¨Æ*Ëä~»ÖÃŒ%Ş—IÛKû‹””JòXpPSÔ|EøĞ•ÉÅ³ŒVg‘~¸›§.Fñáî€­wO Öm!Ù=­×I15ÓZy„—âí¼¬ üÇS, Âjc[V¶óX‘é¸ú|`ºszäÌH>2İ<SHwAá(.2µER—Œ5?|ª®92s›ä¹?¢–`ZdÂ…!wj-VÀL+e~ë‘’SC<v1$_§¶c¸A€Áv}8¯œôJÕ‡3`¤›•¦VÓ&C–îiƒÏH(7sj%m\lŞ^ƒÉ1íÿÎ©iù¯ÿYó×ı^—1Pd×°w!+öt:_B9æ@x{ç»B(Şªœü5n¯Òõb¾r“*Û[úHIBLaTXEíÿòƒS@íh‰šÏ{XäNCiİ…ÎÆjV6 ğ¾ÙVªÂ6ÒD¸ÎÜ#½*BS!’º°øn·¢Á†yÿ6îÌW±îLwË~T‚?±£ÏK)ˆ.ÓŞØ=,xR®¾#şŸ6f˜ì\…]'éPÛ”ŒñíÑ•Œz	ñ‘¢0*1[òÀAÙAªšÍ³òSûMš+"e¨qÇ¨B=ù•:f‚‹V{pİpq*	!Ø.ØœT­V.•ø*¾Rüß?êãÊà§åá $õ¾{Tì³/Qï~[¬xµ˜8×
8üeP-ëK½,"²áY2T&”c\£nº˜Š»ç¥ÑêÃÍ€g4­ŸÑBù^j¡ñÏ
Î¸ÁP§A´Ş;¨päTCWZä5± c2c…ìZ‹™RN«mÜfjt“Œq0Fİæ†Ó'7?ìº/‹{“¡¥‘XªzÖIHæEı‡wTÑsYìåìûĞµ¥æ¥>¯Á·+†]8%Qõıºk"ƒpÒ—]€ë• ‘•èvQ-õ˜968[ÏO3=Õ=§¿„xÎÁ¬!P‚";f°®ÆĞ'V\±@š¿°šéÂµŞRk¤Ô?¯|jhƒ£[ïs÷?ûD‰½^1àù/â-L*42æ&u'Å1TØ GÃÕ¡¬ÚRÅ)Ú3æ²™	€uWH¦Ó¥ı—]#:ñàşÕÂÆYGÛ'øÔ¢¼f–Nƒ¿fĞÖÎœ!\TD1¿p™YQØŒ}/zŒªÃı‚¡Ê††Lt0²s5F,‡ëˆÄÔJŞ¾í­,Ñ#²ïcçÂR’aq»M°	c~%Ô»,§öµ€Áè¶¡S¦l¬yŸµk‰ÔÅœ®§
&ğıP*6sãğ)ÿ©Gwû%`RAÿÄ9=áC¤é³¯İÛ¡Õ½‹€
>ndúLJRë’ş?¿ÁZBF#ÛÉ°¤ğ@B1³°¾µƒÉoh5ÃÓ¯!<zs {Ğ>ß?2°càóé;QB>Z$Êù÷A#’×½¡ƒÓ„tjWOhkÄº
(tJá©¥ºÙÖTğÃ‚ƒ¸¾L–ö:áĞGqŒE6‰fò¢ ~JøX&nÚß‘Ûbwµj‰6`bØÂ³=˜	\Åê„LÖ'vuŒ@<b^aºÂ ×ÜƒÊDHò¾c„3Å"LÑÄV(T1mÅM
ñU-&±ÕJYX¡"’²DE×¶m½O¾”Æe¡üÏ¨œñ]Æê¼üMËÁÄ|#~) íq‡¡—Õˆzb»n©ÇÇô±˜ñ³¯åÆedz!®Ö× cåé>36{ÔËØœwôŸ¦ÒÕïZ»şÛ©ÍÚgKH«¡ö–¿Uı;ê…€]Z	÷UgŞ®Ÿ†Ë`šÌhê½Ãqÿ„¿"à©ç	NÂ×öäå{ÒîúÇíÔi¨ö¯aÁ^ÿ÷ä©m–/›ŠLî+¯nû¶Ò÷­'«	éò¼Rh¸V“æ/ÜT—eşÍi=@|&«d­±¬9O‚æßıŒØô‰À‹_šøçh¹%Ô{ÿÃŒ‚q†×ıaqîæ>£	Ò—L‘)S—©ßÌ’©!“´úm4]¶"ê“•T:¸!cô¥0÷NêÃºšOd¬y2Ä,kúÁnÃÚ¶n•7²é³˜/ ‡±–¶`ĞnŒôsº\;©ÆPGKé‹°Ô ÆüÖiÌAĞ^'ÎY‰ò»†T¡£õ;ÔùZdşY•0®Ÿ¬S\ŞºÈsõ"€´ƒJ—f¶8ã ‘’çîUÛKvS®SJÈ|Ûäv|X•¢uuµÙ…bÛ”©ºGD7a9m4.Û<†† ¢éƒÓÚAaÂm:GÇA›[Ôìûe´daGhE’ìU@ts³8BFãè—ü©\ªYŸŸjiêN„n|è¦¸ £°TàÂáD
²°+Ã.'ïÍízYBŞSò‡ĞÍØÓ¾Ó ™Y`±¸¨J½@©$ÚqQC…$F‰ùÇ—H³’Dë)¨T[
ƒ¬‹TÛ‚5E¥ÒÕº~ä°…îeªMhÄGÎšN¦BÄI¤àÅŞ¨Jö°ë÷õKÔı”)8ÉeEb·ËR;C€o(¦Ù®õå²Tl:Üa¢.6ıš„óŸ0<„DÃIµ?cqš{£4kø3Ôû¬a±Ğk¶İYY>IPï795…ä5G<rRfş=QÒ0?$?‚¼]ã8G?¿É(Ù ÔóK"kÑ[5#ÛL,›3¤V±¤>T/UÎL	óÌ[uê/„PB’»İN:b^iy§f_ë‰"Yx´ÌÑ“;L×%6N‚‹Íş²Sg¨š˜ù˜8p¶‚ÛQ%Tx³59:¤Æ7o„&8jÜ’4“ Ú:²~]¦hpiõfcqóµ.Z ?8%$Ù›‰3²qúQµUÃ–ZÀnv{1¹ù‘^	¬.«Ç-¶U‚IKÂ“¢€p	«SúÉIš/Õf¤&57…0˜8º’äÈ €¹S•'„êœ/ˆ­Ü¾¨OºãG¸N¨-'ÎˆÒşQïïô®)›L êÎ†{äˆ$„jıèË™«>äÜäIïŸˆ†­Xçò¤ŞÂaó¿¡e“£z¬÷‡2Ïêæ¯X—Å –k¼
ĞCm3¦‡~!|şl=6§›ÈïA€©¼kÏC¦ÎlKÍ½ Éç|™ —8­+«v¹‘=­BL©á,3b˜L²Ç¿uPNïMgÛ Æóóu¨|[Ùü9¯y ĞJ°ãgŠ„R³ë/k¢ãuë=ê$²ã¸á8d¢œ'£óu…™æÍƒ°_šµ4©Suë‚ÚOòèº ó¡nˆäóğ.}Ùå[ú\½úÀu÷½IJ…W ‹Íp\°²J¬†EŸƒB,†Ù k·Bimè'\@!ö€8w}V7ÿ
Yómù{cg*>_×¨ó»„GCe"HÀµñ#'ÁäŒWöØO`Úÿ’BhBjK’[^!ÿ³/,š¦A~4ü½	ê’£C½ò?© 5À¶0q\É
ó/qâ"crÓÚ±}3TÖÖ¥ÖYd°Óuô¦Q ,QÕ¶Tp2mÌ™ŸìÕÇqšüÆæªá Aêàª…g® Â±8W#Y#¯'áX–EÉ`şO•¸cÁ)ï‰B€ëø?%½u’K´ˆF»À÷©C?ø;‘·nógÛí®€Âü];ÃíÆqÙˆÍs†µë2œ`ûxKÄ>å)ıY9±^å=3; UÒE8xÛÈie!í1±#ì *[‹nıY‚ÓëYw·
;Æ°`YºØÎw•2tKY©=ö¢F¦;÷h4À¡3:$@ezÍøckŠ8¯B€Ao~KıìQ©ï9ÍŞUì\Ÿ &‰Ø¥ĞãMëĞ‹¸à,ì0¼ïŠäÊ|ÒÀ’‰VJO¦<âTÒªîjV#
8M_”µb;Ò;^€«í¦–nØ°ılÅâ9$_\­œ}–MŒÙÔ	•õŠİP(¯Ú½CkÏ´PüâôÙñ>›ÓtÈÉE\rÕPö·Nó¨æÕµ<9tƒºš‰Æ}£°·jjL(å˜mÑH£ ñ·Ú½	¡b¼A'Óãûj,Ìï>·c{MÇº"fú 4´^îÇ$â¶ôÀH8>ZPcCŒòÉç™·E>ÊVˆëcûãXX„FKîÄ'hm§¹V+³%®ûğ‰‚è!dà¾øy	2–0¢xIÆöæñÄ=}ŸŞqš€v¡êBFÊAnÉ¯	—L_ÎcÉêaß-*¾·¿+šúæ/¸YL`ˆñû	³<³œ^R‡=„©åØ›æŒ
aOÍ'àt‹
iwÀq‘²óÄ8’Í¨j~Ü’}}Ãµ£
‰È¬
b•3‘UŸ0µØxA-9U8doİÁÜÎrZaó’cGÎóÆ¤†ıì´usS{Ú‰Z%«g+ÃL	Ã+÷ı=|×Øƒ;©0òLùÆìêÿ0®A_¹(ùL_wàÔÜŞ•ôƒÍqÃ;NË+D”êfÌŒr³Á6K=óøĞu¿ãxÚVË(çF¤N—ëSRRPÜ¹EœIœøW}a&™ØS+é2è>j!a™pÈ2ÛÙ“MÀ¦@Â§°©=…ír_ÑAÙï+È€ZM+ä5˜fT#½ka¾şrCK`îRøÆ‹S|0,ÓÓ‹Î¶m¸?mbËÇj
•Ç³Y?å{§Kèç?/Â‡tñFŞ Šª%|hùq@±Oa“½òŸô£ÎVvø‘õFİ Oê%[ê's¡ï	u»nš v“ŒÏHâ ‰¸€YíÃéÃ¿†[¥åRdDÆgÂèÎhùpÇ@ıã-”ÙOŒ2áÅReª¹Tô=tò‡È†ñJ«ôU-¹ RfÖ‘ÎöD³ØÕ360Éb›à‘Vù~'ÃîO|Ú¶*"hv-¨p‹,šiàã‚ãgÕ¶Öjı”¶jr¢MõÅ1­é©aËa—cšweÂ¥ù_¡±Dt@ıU!V[9¢°CEÂJ¡–]“ÔÂrâ’'K§ËÔ=*T Ÿ!Ãa1‰Då™íQlwh¼à«#M¥Ù¡Ø¬\íkMÀvÄ
^‹4ˆ19á›c4Áy’»Ür¡D!pg£Ãª0â¦Æ“ê?”Z5>EÆTræË¡Wp=jÇ\UñŸ!õ9ºoXáå¾$	IÕ, öZƒ²®hÁ#íízzckÂûhÓj,i (á§°¸ÀRn¯-PÒºuqfo‚1H`ï&'wï‚ô¯³Ìš«=¡€^—É£÷â»-ÎSŞpÔÛzÒ=s»¼j™“Ô"}“ì…›Â©.œK—TP¢f-ávÍ—à¨”!ëÕ·Ä{ò±×³|Y¿­]¢ÂéL9`W2¡˜ ¢elŞ%šRÈï‘Æ¥VoJ	å÷­NmF6k}¡“RbA{â#x§á¹Šq†ğFWtÍfó·‹÷ÌÍzª#¯ï“áX9\Ç÷Ï"*âÊ§ÃRab¥Øœğîé0VHŸÓ—/èÈ‘¤éCJ¸iô@µ±x[Œ–^g7ßÇÑJNš\5OY#X(„÷ ûòÚèÍu„«Ò«:È9k©ºO‚uT ¡&ç æ|«•EŞ™5ÁŒÕ›£Äkx€’ªi*;Æ ï H0Üî ÚF;ş—mò9aøy%z&½—ò%·÷Ä’½õL(Ğ¦Aö¹‘¦Ÿ0Öy1°’‡T|Ñé±y¿púJ´îQVá,ª‚Ü‘j©[rÏ Y|f˜MÚztĞ°Š*,‡º|BnÛâË³×6²¦/¤Ş,ŸdÊ¢¥¾GßiNº#¤úÎµ­Û»ºÎTÊ4)=ÉÆ›Bîê¯ó}Jò}†&%ˆ.B·ÍkrÙ‚S‘¾œéÏùŒd1Ærj¤_^Ü˜Õã®¤]e	,ÕOÇO÷açöŒä	ú§vÜ8·³‚íšçWÏ)U@{Ö Ù¿jNróË†]mö£™Zÿ’=8OeQ–RD™2ÅĞ+w0!qæÌ$£s‚†ƒŸ¸‘wàš¶rOaÿ¶§Œ÷ksiÆÇoü‚° -dÙ{Ü¼™)™ÿ[éûY[äSí“ˆ£“v¥¡P±4P1%«‚2&†ğÚ½ÉÍ«]³3Ï‹wdP=ØK÷J¸ìÕUÚ NÆ(½G/Y’aê­
3|:Á²µU»¬NÿEOéº9ğÇ¬‘üWÈ9ˆwÓ ëæCœ§ø„”P¾ˆÜ/eOWŞ„ËŸh{Ãò¶È$Æ%~[>§Ûˆw©î…5š2ÀÒİHNñ†¹ìOy–#nà×É™a¦z¥”Çg-âÏ°ThÛ—"iaç"ÿb¿ Òï\™šT}ÕÓËÑëeÒÂzŠ–YNTîÌÆ{‹…Wn°cğŞâ¯/ÇÛSû'/Iu†G™öNŸ|Š6rÌYï^Êû…÷/\ÁÂ‰u£K­ŠùBöàæknÿ2pòáÏ(ÆqõÆCt”¢
k1M´ª·›øpÑÆî;‰GšRnb~@Eâé98cè•e0Ø
5ÏÆ?®WZ¶GŒ{ ©™N±Úñÿıc»ñay¾z1<€î.Ú‹jpi¤ØÚÈÇgS÷aÖ©BÑúªõ[K­=š6‘HÒM·s‡Õ¿òŒHğ¹#5C}Â™¤Û6¢}b‚æ¯4TäˆÇlO3ú(H_û›¨Ø:ßÁv|˜wİ_ÍK~ÇWı¤ïì"†¯wuûÃqT;ZÓÒË]ÒBxñtUdê…ó6á¾í´û@]Àn¾CÛÉ”Â£~kğ¢îÏÔa6¨-®<HÅ®„³”êU…e¤#³Ÿü¿\6Õ…Ã‹‡Â
p¡åìHB&·xt»æ£:añÔWlK§N´i<	Ò'PQ-Øıc“ßøÂX.Ëé¹&-œÇ@g‡Ûyz<êO]W^„€Û
Ôƒ$œ}qù:ğ½RA&I¯w·ñØM¥Búc•ë“hR¬‘€È;èLñé¿æ±YÏó­ÅfCW¥ğ«§ßÄ+-}7Ó«(ŒN®‹{aì½1Xø’æ‡×ö^“õS€Øˆ‹²/ÖR`~dqÎ*K•R#‹ßDôÆtùTÉrÑx¾ÏVûcP3SÏÑD©Q$5Lş‰¿ÃTÎ`äO"¿RoR$!R¸^DÍsIaÓR©Î!@ó^Ñ­f>,qe˜fC©ÿ.³å)EQI˜fÇ`Dé)DĞ¡€25ÓDÊ·y[&AZI×	™æúÿ§k“äCC7Š%– qéÖ¿T6ÊV±Sö`Z
;æ2™Y%tù(Oo7(m3b×ÓóG‚ã0p¤bòĞªD½s5Í!]|úË—:š¾üR{{ÓÉ–İbC w“ .<‘ÒeĞğ€vô3ªÜŒ§	%¸%][Ï½%ä¶ĞAøû”éÒê÷ÆµìØc¤êÍ
6ïBÔÃÑUN˜hqÚl|®^`÷ç£O¬Õ„û\àø˜u¸A&S·”ù‡r0Ç›N¾ÿ ‰ğN»¾5¿ù©~xÏûÑvƒ«˜íÇÏÒqñ,åf¶	’££ëé«jÃWp†WOx6ÀœN3ça!£„IEJ©ªZà;HÃ
J4áœcüO×ÜgSå ø·îw¼ğUIÜq­—ì¯QY–û¬ôO;÷¡8C€™Ä»½~÷RÃ„¢ù6*„\"†„Ó‡IvÓ9øCÊÃn…Ï­5¡Bç3r(wç4œğwA)#L„¼|¶¹búªL-è2–çtNÆÇ^Kc0“¯¿7rŞYqîBp–xjôÂá–itòì£òµ¼NÀÖÖfcP}İ¨ßm¡JY¨C`½oT}°êëáDÕ=š¥tñ€ø˜É¶…²ùÛëë-@–ÕÊa•S¡üvk°LÅ'¯Xuæ¹â#ÁÎon’âÓ_¹&ôIˆ‰ ™¼škÚo>qn?Vj¿E'DŒÄÑ/¸Ø‡jV‡M¬Ór§ÿ(ì©q×Ç’€DÃü©Ç<û|öŒÀşá¯½ L™V-]•píeOÉ:Üöd]Şª8Úu·F½”šmIT°P S-·Û÷Y0
(|4ã9¦NWó­ ›Ô¿«ÃEŒD÷ÃL3©7ˆa!'²Mc¶À]Z„9ÉOñá[FØ„ÿá¶›‡tNâu}jzä=UV:9gŸ9ïxx±4â1†ß«÷(öÄFÆ×GyÇD~»ÃíYZ°6kşŸS] Hm_*Œ?Q1Î%W§À…OĞ£RuËoØœ“Ëhx´+"íŞÎHLg0®‚ÙlÒÙ™…y<ûêaP$Ha;¾ä$=gû]° Ë,MÙÒb‘«²¤mÊ`ÿ.ô˜ËÍ’sşNçÉµeÜáiñùuœ,
é…û¦Kb®c¤IP]¯QG²T°Z†³àôT7×n}e×µõ*÷&Nã§çJ°Ÿ9&#h06§?«cïß£93xMŒ0ğ‚Kàü]áMÇšTí©ƒtæâ„ºİ[ ÂXÔ<Q'šÕ«í/'¯Îİ°tc–¦ô;o“mNíîüjs©?“ĞFŠ¦nj
8@A¯¸…¶h¹‚ê«ğàN\ÎÒÄGF=y˜¿ÙV~á	'O_/æƒ™¼2Ã{v&ÄÉ)d<[‰Õ2øü7Lw&”¹[Hq úú»iî?®âÒK;òŒı[|t`
`Ãrj‡3á <N…¹ÏŒõ1,‚z`MªA€Qsù6ƒRÃcïîF£î6µ•xqñ'RÊKûI|;Ç	ÙtàåOı ˜e™(æ![¸ãdø`hn´S€Ü‚îFKˆèÿ$a×m_¶Ká•£ÁBôì@Ãe–;kóÆ±ïh«şVrÍ"6H:BÕ‘)½&O»ÛÅ½y/	™ãªYÚ.(ô5ÿ‹Ã¶šâğP€ŒO%ÇÈÙ?DÜHÍÄlî8y‘qèg"«v£
©œ-k½1¹ZI^ÔJ÷šïkñ¡Êúµ[Ÿ(·ñ«Á¯ªú]}4c€o4£ Vç¡09ÃŸ2<ş8%Š:òY|ÃøpæÜ:†_)IN‹®”6èö(zåù‘³ïİøäD4îÕõ<¹nîójéî-G2bÿƒ2Ü°8xÆUªæ–8yI7PG^!ò»‘OÌµÁø¢!?b*ôºi)WÅ¦ƒÇVô¹9ã¹^Pêc°Esbóƒ=N;<l*ºÖ85>f\÷Îzq¦‹İ¸=‰ÿØL“İ©I0%V†H¶ÀaÛŠŠÎàÍ¹¤Hlîf—€&©R.pıÆì†&ÜÕµW¿ğínÀëM»m8ô{u¢âİ¯KÇjaÁÚÆºØÎ¿>ëw…K\?´§m~ ¦¸Û˜0˜GcÓğ=>°`6/•ix}°ÑúÜn)5e_Jú“H ]5‡Ùi	Š[UX]Ì•Aó€.ù£‡¦–ÓÕeàpº„¸ª
¯™q-dÚòÃdUŞ(ËLTI/=«cXBQ+	Ír}¦¡:Z‡­Ö;«ö–J{(øœìÑ§uÀ»¼ÅVÀ®h&uƒ‚Íû×‚±5É§{éÆ¨ªæĞpŞ)cÖ/˜J|ûj£„’_g™îÁ8ıXzw¬~W‹U1<-¥åÆÌ°±²íkœápû…¼”I%}û‡ú=,ÊåÈ¥âZ4›úÔØ“VèR–¿X1jï€ö_ııû#ıd˜[õ»N–:JyÄhM‡1Å{´™r;b°n :¾Ü^·Jk‹4ïÀ®ÓµşaÇ©Gı7Å<TÅ‘wı?
¡á;pM£-<RÇ@	#ú/Š¬hÏ]Õ¯V£ <çêŸ•Í[Ğrßî©ÿ$jXò¤0_½ªY—±„÷°ÚéhîaÅï|JşªGĞBìñÄÊ±,Æ•qÑÀøeµ¯	|+P”…nªuºZmğCã ¦¸ô5¿ëı[Õ0hDøÒq!ÏıqO:o=Jp)pÃ‚ 00í•‹j*ğı­¯¶øîN‡>(}AAyiZ;Êµ=VFV¯”† ûá¢ÜÈñ)GÍmnÉüÎ±¹ı‡Y3ÿêœ«ù$,×JvmäºlÅi—#…¹ø_u¯Ò~ï²Ì€=9úÊ":g":(#(TÀñï2ŒAÃLÔÎ­ğÇÁ
ö‚ ë[ï¬oÆÊ›>@`bÊŞpºÈ‚ßŸ˜ş”š%¸ö²%,4Uã®ºŠã%ˆÀÈ6¾Bµ«s6¦~–ÄÜaj˜¸õdÍZ‚?­Ù‚œ˜A¤ÎYÉÿ1¸•4óâY£vVçğ^şã>ÆOİ+ÿ7LwK‚‰Ä`ú$QV¯­®ØlêL?N7N›¤˜+µÜÏÚC_­eı	Ó¸Ò¬¢s\Şí9kb2ó”J®É\=*ê¨q
@wC• ˜Ê!màÚ;’Î˜F ¬K¢ObÁ(Çry[öi"uZ+TÉ‘mef2ì32q•L*…²y ¬»Ğ7´3å‹±JØ¬Š>JOƒ‚îEÈ?m¨²»¨Á1ØâWø¥;OÎÌ3ØA›Ôoy‹eóş›ƒ·dC@·*¥7ÿ‰ŒZóöœN9¬k,cãƒ¶„7-­‘‹A9¸ŠÇüç¤¢Ó¹]E’ÜRNu ám”Q¸‰)kk«;Ï]¹ìtÈ¬H5^z–n}š´÷¾öŒ:wUËÅK8$ìBÍĞ>ş8¨™‘!‹Wİ‡1*çaS0¬Y/NyÿÁy·± 
„Ñ7>ÒÑLÓSSÁ£Ú &è] ã„ŠeQÇÑšU*Jm¶­<íên»®”ä}T¨ih ÑK§lÍı+İ ë,ôÕ€!j>H·#^ğ™b*sÍ§E¢9Ô:óäş{¿‹7[np]n³‚^6˜)Å/¶ğj£}AlDèİRçäWZé4ÏÄ’ª¢ÖG)ú´>ëEôôµøºE§pE¼s*åİXbãDDYbdRÛàK«iLé±ÌgˆVE`=t€K–CÅ¥ä»"¹D§ºO¦K½ÏI\Û<Ğ«7GğÌ§ì”jhó„F‹Rñcmªq`kÅf¬¢Y„€‘§Ë+„ÛMÌ*z¦“»”T·*­^Mƒ®W8":'¾Â670I‡Şéoã‘}ÆĞÀñ©T±6*¡ò7ÔC"×„	}pÀ§µœ#‹7ñI\`¨ŞùÜ=f™^\)2ªš‘¼¸_Õ=wû†^§Ş@TşxÑšô¼åÀĞ²7·o sÿ€r\–Äß”«Ô¥¨lyàÙÈ[Ö{L¤7öœ·çWIŞı3vú™ËFK€D/{ì,]İ™Ê¾Ps6Êai­³`ïõu0P†’İ¬- Êşe%¤A²ã1ËRâÇ¬Ó©ÃôuJŠdy;V÷e¤(îô)X “`ahû…ÇÖuKÆÌßÛp¶	8¥'Ö]¶õ˜+!Ôc=«Ùñ£õ”ø?¡hi"¤ÇÓ[ÔáÒ	öB!Lˆ
, Ñå|*¼çw'Ü”Œ»şLTÑ/{¿ÙØ¡‰²±œÃú„$oS(İX™¶#6)ÉÖĞÙ”éBÿ}ˆœIùÜigx¬ıøHª%5w˜ÍÕoy„]"Ö²é¶ÆÉ!
Ğ‹
y”¢† Ú¶×v“ÈB8œÑŠk ²-Ò(‚®¡ÙÂ ¤=YŠtÌ•Áœy½N“ò ³t†‹‡ßÄ»Ûâ@ÅÇ)[ÌqC]æ<›‚ŒÎåI’4r]®¥ïİYÏÁ–ù¹ı)®
~ŞîÛÀÆh²R#ÿ>=^Ò©uŸ™ù˜»Ïsª„ƒ»+í¤ÊÁÓ0¤:Ë4˜[Y¢WùE³~.Tİ*]]\º
ÇC¾£Ã|_¯i¢&„×’´±Ó<r›(SÜ%as<î†(ËÆ: Š°/Â	gå³éÒ ¨l~U|?Ğmb;ÅŞvï”¼©ftYæ³æìÎ 6f'×¹2-ä®®Uà:@í3¹ØİI¸ê.cşyA$+o¶¤ÔE•—ÉÄÀ‡í÷/KÜ(ÙEuy[ä¾¼0(Î	şÄÆ¤)\k®]ƒ„£«¯aÙ=3"åÖã!©×nÅõnuF¼qaÏÖW §á†-Û+ÖÀ(¯[	Ë8=zî>÷0°Ö)dGšŒEÊuhK/K¤e¸bÆîál2½ªH¤£N/9wŞ¿ë¹V€
Ú5ùGP{˜6×£Õå5‚^’Ô2q÷€*€ş}ÓÛ1‰ õNúdîj´±:ÿˆ„ª’ªn'xVùcÇ$ØytœÅÑ }&l‹«GÉO*È{«âd5m}ıág®®RY­0ÆQq‡Z–b§û§Âl|×y{¼½ÙâÍ#vA@GäW…ñuÃîìØ„“L˜ã•Jˆó2«&Ó0pãKİ½u{ÆÎe–@ç÷††$£Éª¯ºiú¢¼Ñ,L‘ ØBKØ¢ò/2Ì
ïÖ%"äØœ±s±tş¦–Ğÿ®×Ò…D{e”©‡à‰.ù0¤ÜnŸIªÔáÈ¨yû¯ĞñŞGà° ÷‘Vf'¶ë '¥:¡‰ØOÎ›s×T*9š­·¼şRQ­ËYÀxè)•¸ó§z¦uÔí¨ÿÀí®›¨ˆÚ´ü­œüş„©cÓ~¸:³XiºVÒ–XX kÄ¨~ı‡Ëbô,é#¿j>ÅÊ	q›'¾ 5k°mûé;ú²TMP†ºæGÃçj>v.öâ÷ı·¤Ú…Î&¡‰×65Åı‡ù©üFõıNáÔ+zĞ¨7§V" ç½…æš¶o|VE0’…ğHİeºŞ~h±xñ ÎªÇÚ{-ØW ñ.È?êü·mvNÅy·®P˜}fAãŞF>¥R€ğ+"‚tí
pÜ Å{Òij1ƒ`0›¼:¯r\)ÂÊÆ}Nn¨ì"Ô<éğ^–<ä'.'.ÓÓ7ö1Ùûµ8e¢PK˜JØ7ob$Tôõz¥Ö&„kÀ…j»…DUÙ:, :*°ÍÃmÀ‰©çü@ÍùFA­YÚ®íş½¹{˜»}­Ü×µ‹û"¹ùaÆŸaÁúQ¢s³•(úÖÒq¬<~F˜Ïºcšíâ29§ÌçºöudIl*İõlš`Š"²†£_àm§áµÒlÀ¿½¡U
Ì×~!øVûo:¦‹ÂŞÂ*‹©€ØUë3gİÖ¼Øvh¹s}é<±Q#;i3ëM1ğ8›3ß_|3öç²0€wŞ2/›jİ›:«!g›ÓDÀ„îÀ.§¡:ä]¾ƒŒí›'R¹/5†™±PXD7¯7F¶ib·Cr†>î¥8™8Pğš¯ZÑÇ+p—øéß‘¯à3Ú³À
/º¥WnzY¦3ä¥Ğæ!aNšt¿„¥{2uÒÅyc‚#IówCˆ 	®P›´c‡€ÀşIÎû^ûÚ0?j²YßÑÀÓX^Øœt®Sµsn¼k`~¡í©ú0ÓT£%ê˜â},ÍùpB¦­tR²zïÂf&gE»!Î«ÁùdÙÃ‚ºı¬+ä· ]Wísc’wïqÜGÀN(@Ç¿à8°Û_T½ÛŸ\|Ób"*gá8”AxÀ7œNÒ¯·–ÒË×o^Çó~*Àû¿@ ü,^ÄÙ¤uƒòù£•ï:ìõ•Sç«#]ÑdZÍ*yHk$<Ã!i–ëDsPšÑR”õ(í­Óša-7ÀN±óAÚËdA+=œ‹´&@°"èŞ^ŠÔŒ‹8Ş÷`ˆC	*$ä#-t¬†£Ô`Ôàµæ;lëD¾iö^ Ê{g°jşÂDO“'ø!ë©ì£ÿêÃ6ÖEd/÷7Ñ#ScJ°–Ê¯0^IŠŸ
~™HÜÄ>J¤‰1À€bÓ <#qØWC”‘YÕ…„ÈËÒ‰>‹À)LWˆ˜šµÊÏ.úJd8é×
åDğ1}&FÉì¬‡»ƒG»C¤Z¤.EŞ¨Pæ3ä#6¹ı[><¿ZêÍ¨ İ¥£#øz–˜No³Ò?Lqêz·ıìCÚÈÓüÈÆª{Ò=Fü¸*uŒ!W	AÔ“à T&•Œ¦¢Sû®÷2 IëÀ:KÙ}“½ú­±CÑ¼(¡ŠLŸ1Ø7Úe2)#Ao5µòÔ©x¼sŠşS*¹­‡´€Ç@îy^°âş‡{kcã“ i’¥—-EºşnÈGLŒõ+¢ûí8|]pr]¤³/¼V‰Á[ŒL5˜şÉp™DNÉÖ²ş|×EÆ<~~ñÎÆR©šnYµe;*naÖøì6_Œ\„ÚÀyŒ–k\­Ê¹ï-ƒ´wì~Å› °Dç úÿ‘Ã‡_¡ÁÄ{CÅnªZŠmæÈÄÂfÜ+ú†wã/
iQÌI ‹H( ±ër¼Sâ>ÂÙ¼ñÕºQØrê;ño½´šˆjÛv/vY]Áî²:;è®ªqJêuâD$(¨ªslõşS¥ÏıÛò×šÏ€>6›@^·×Â»­ +¥c
¶«¡‹oÒÃë#Òm;³K”Ğ(0Ûxfç<íª G Ağ|8aG,É	ô¯•é	ßë˜h
d(²‹sHŠ4cÔŠªÏÿ†Í“€A{]Õ[Ÿ>ş¯dÈF‘:p;°ÚœÕ¢)ŒCî1€_ø} 2ŸhL5„-VW§{îá²á¾ó¹z×QÛÅª¼VCq¼ŒRÏqúÒÆùØ½å
â³ÓúJ©Y^âêOKÁ¤ª£IÀXÔ¾UÓÊ[owë’7ö€Õõ»¿í®=.]Šçîx2¨­<jc"\…G_ùÆˆ ŠÃ¶®}LkTÁ;×f÷éY!™hñ>OÛ —2K¡³¶-`RQãºv/ kV£Çkñ Â&-síAD*O«¶E§¶A:É_T0iÅÑgÌ¤¨”}A%§…à*9à}µŠçï‡İ’bÓ"Ò{'t œ4‘~IªÅ©Ù
üà¸dXOm<>"½gX3,|ª&FèÔoĞ…EAÖyÉÌ’8¥Áy€‡ÖKN:À ƒyµáFª³¢Â›xšsä9­`Áj¼7>B:ëxğ\¤ì#±Ú–ËëÑÒ—O‰¼ÄZí
±¾0ç0jûf€|q°!&¢úqï-X|àá•MJ²Ã¡ÔJÊWè?ÜÛı´ÿğ‡ëàfl#sAÿ@Æ€uçïØ4‰Æ%SYEm[n® ÿ@^Uy'¡Šìû¹@]ÇíÅ•Zªäğel \VU¹à¶E¿înFÚ)M²¡–œpÉ=t˜Ç…L-S°­ûüó³¸î'”czº‰7t4¶nñsÄÑ-áéH~m\-E1ÒÑ$è{C\èÑ)]Èx³Ø¡Ãú~-‚ç:›(¸Tëëğòlä–‹–4äY ,ìL8ÒcòbO87×"s? Š-r1?[En~{Æ“’7Ãú7!Ö·m}Y¯²•† ğõFªáŒo\g÷£ÅÆn£ÁSĞ&!¡w’P¯Uğ—»aÈ_)^ÓkDZç†;Èê$Ä	Æ¤º»OÂ¸—·¨ÒZã¤ÓçaEÎè”"N¥³Óƒe”T&6 °©Ê£üKP>ç!Bc^@ªšøÎßP:è¶`¿èÜVW×Y¬Ğg’£¢çÕ%¤±;_w¸ñ9.CæÃsòò¶=™Åè§¥+¶òÙÛ£²Œì,›Mm]8pa;zÇáó`vw‚úÃ?büéD~©kgÍš‹¼C‰j×é[Ü“§Ô+o]w×e’½O”!¹Ûs ;ÀYŠ”µÂ½{Â¯˜¸ó ˜BH$ø¦K¾ .vbh¨;D òNÈj	Ã!Ñ½¢.œÌE¿ãÃBÚèı'[—§/mˆÈ"Ù)'X’‘Ñ8E«ÿàXB‹ãtÔ“í
–LäŞªŸ´ŸC>.Ù'O[¤®š 3'0½µs;ùQãœÀø&•§l_«`àWÓ+ƒì6}{»¾sf˜ËÑ£ƒĞá€/¶ZĞAçˆ‚Ò” éêÚCw*äÑ–ïÎlìà¼Ú¬S|¦"S›&aÿÊŸ8Â5f¢ø`ïjÏPÈ¼ø*Œ‘)ˆ'É da ŠÔæ¼f,œ-ŠD,ãVX1rmp¦«ê6bµHs<Ù¡ñkâı/Ë÷Q{¬ÉÄ‘…j
!íoJFFÑH©æ­©‰+ŞÖ›Q-Ö¾|©wŞ×Ò1¡éÄÇa¢áoÖ¶¦Ÿ¿ÜÎ±‚îš:ÆÓœr%ùhSì§”ıOÒºõ¿ùf&ˆÁò3(ñ»È©Ù¦yMJD5ÓêZø?ù_¸JFî3<fç¬>¦ñ”ºO˜º7Âkú/£_v`Ã¦Û¾U§K@Pˆí×c=à ¸x/%ˆ»ğ”ëc… Ó¨9k`W =·÷ôâò…*È+çÆ´}»îÇÑ²"ª;5ä)³è`3Ñaõ“¨Pô˜{óú#î¹æü÷áÿ—½p+©a*4Äöã5‘o«„¶‰a½^j#ˆ¯ğ¢[xÅıx›åTÕE

`VŸ‰2¡{Ş¢b1
­¿Ì¿ÿ¿Èµş«©¢>ÿÎì“îÖ_y–x¾¶ñËÔ7' ŒùØ/„†m—Xàl¨f®Oî§¯ØïwË\	äÒŞÉÔ¶[s5¬ğiĞŠ¥ ¯KK£Í¿²2å°µÄÔ1ÈC™^3Ñá	H3™wéŸgŠ úÿÍiœDÍ¾Ì«¦­àsŸóÔCğå
m¿¼BåƒlØÑTMî¿¤åwÍ¬ „*¶vÅï¢ë÷ğÅŸ-¤ZÆn»Sõ×çÎÍÇÚ†z,âxùz1ÙŒ<ƒßQµ±f@Ü   "SôõoWÛ* ÓÂ€Àï?=È±Ägû    YZ