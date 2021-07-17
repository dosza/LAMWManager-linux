#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3443862606"
MD5="fe5a973bd56648beea9838d60f2d1e5d"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22564"
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
	echo Date of packaging: Sat Jul 17 17:30:26 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿWã] ¼}•À1Dd]‡Á›PætİFĞ¯RN¶b¬;ÃŸ Æ^Ôe‘=Š·Ñ Qc¶¶i˜¶F®3÷‘R-ú®0›6h†hu^AOüït^p3„=ó*¹âUtÏ¨â_.Î×Ğ5û½ƒk‹­9âãÒè½wT1ºuAíğŞp:£0;ÃÁÕºTŸ™½]F‡ÿmt‰,Ú€¨æ	‚Âf'#1{Ğ_@{ n(ëyå.;ö¬Š‚õ«K‘ÑŒ6|¤²ÇÄÁNM”¡‡ŒÌLÄôÃ4Ü¢qÓ:¦¡ïÍMzÿ]RÖwìZXø!g‡Õ	ÿAŸ‚ı®üÖkö<Í¸²å`C~&rü–8¨–êpP)(ôK‹ª«ÛŒyLR8 PÛ…P÷ç$·ˆâKRÔóÕœÇ@ØßÜŒã¼ÉÅ‘‰6Ç°<õ¨|Ed^&è¿–`U”é…X/ì”.Bè#œJéE’ßÖPJ4ããR•„¶İwßèi$ß7<+qÇ)€˜l¡„˜9¸´®»¿í„±›_2R,Ö„¿#hZ10ı~2L6RM›¾'=”‘»ƒn±ñå>Ëa;¨»åø^#[Ñï.e†¡wÑ#×~û µjıü”S	ø±DCp8©bxÆ*ksxìÎ¢‡uW·MÂ>!¿Qk¯ÍÖ£Ëëà_
¹ç~k§¬ş¢Mì¤Qô/x†UxÖ¶:-=>‡²w%ı7Ğ÷"³áıË×#ºÖÄ¹Ò2±×0ªùô	ƒ¯‰è‹½±åØ œ |oÃëÒ|±ª‚…èÜäÄÒÍºP×¸½¬‰ÂA=U¸†’,Ç	•î¦ŞØá?!20¤7¦*1äayc6şgÜXT¦M„¿¬ö!Q¥õ¨4l[yĞLPVhdíğ¯UKª|(?ùÄÈõğŞÎ^ƒïŞŠ`šgà‚¯Üà+OC!¦mÊ
êõó%NÕ64Ü»ÖóS™µÀÓF¢Ç?[å—R¹ø ¨!N—cCö÷´åÄ0nßVö¤½F&¥SÌNŒ©2Õ‚ yX!9_ƒOã÷Ÿ5¼>f·Ûh $gYäùcâ`˜Y--•^ùáN§ßş…è«¸xo‚2å…úç©ùÊWoìazoi–skj_ ¿*†aã¹*I¬>´k!!{N‡9^Š¬$«Î·wF€ĞæL9B<ı)µØ¢{Š™qĞÙçSTkiÀèÿkŸv^¯,n×¥õ|,ÛošÁ12Ãb@k'¤˜ò&¾çZ°Ûœ£Ï2áyG ™I›­şú¢8kG÷x'–s£øÍ>ynæXşáºaœŞxŸŒ£°—	Ü'*‹ÎŒÀrPÒä¬`)Eš‚¨õ¥#tlIÄ$¦¸¬ ÁĞĞmıx‹ÜrA#Ïó¶I8G²§“~Xi‹m*E|ĞnE¾=g’~>mÒBÉv.²ßBÑ¼ˆ¡Š?m?ß6CJpsåçş¶Óu·ëóY>‡ÿòúÄÑb#ªæƒN+Œ¼ELÿñCŒ.ÖNße6ï
¥km—Ïµ2©,}*;@r
ñï1ÚËâ[iş¤ÎfhÚªØnòÁßOÉU•hæeŒÓwª uòpPÛÑˆ
6²Û]ºŸñHé/WïNc—Æt…–eÉ‚“8“Â!R*dëy½T7¾¬Fä{–’:ug[å)ÀËçoè´·Ê F!Qá±µ%Ô~ª“Ø×­Y› ™.wÁÂÎ‘€ÏÔµÂòŸ82Bg0ç>†İÒööÖÔ§üÇ\§)?²r¸)Î_qt'ßÄÎ}ú/+}q‘çè3±*|
LåBĞT_n/…¯r ‹»õW¦/ĞV‰xa*Şãv¸‹£²‹“@¶x')q\²í˜øYªhOI %Tš@õc¦ÏªNûñìÙòMŞ¹ú€+ë´Á«ÿ’*:9(€ƒş}hœì¯—ôÕÍ#²”9¾ Œ,·”‹–_• ZZá‚‘wõæ1±Wñ”3Òéëƒ¿›7,º²5]ÀgVïÇ“šLNğHå©	;¯ùOr!nÑ7ûØ 7±Üó ÄÉwóõÎY±úƒxµ|±?d¯®XkIşÿ¡™zÅ~´Ú€OZ·Â&(ß”Á2&HÈåH@8¿{ ø|í 7³ä;§:1¬®p#x5 .ïŠÈ\5º°ïîa†&
Ó`èŸã3´ˆ½çµ6ƒfúÀÌ@6dx¶$‹Òu>¦YÄª!VŸİïØÑ&«ñ'ºmíDÕÓ•÷‘ãâÉş`‡Ûoš"3xAÓÂZó¡ëĞ¹Wú_%ö¡^·£Ícíb™Êaj8ÌWËîê§6) i*nœ—\<¢ÌÆÈ	VçxÇW¥&âÜVÎõïıN%u©Ò¸ªEÉ|›¬YêŠÆj &M‡H³Î¦çÏWDó3ÏU0VJ|qJ>ùÙ¦Ü””DŸ_-â…øü'Lş°.ˆ¥Nêó§}úò@ß!r>_q€¨ Úx4l«6^u-ØNy aP?Ö¦‰HªqèNö†z;Óhl¾õoçÁ¡P$·.j^¾¦8q
ÒO± êÜß­ÖŞñ.T	Œ­-›Tá¡YÍ
>] (v#e.ˆÊÅzŠØŞEZ(ø‡kÅDñÅKË½l¦ß¾Ò': *à8û@wA47İÊ%#{ŸsÈÆ+¨ƒª2ØV³vôj‚t{WÀämX„dî‘Ô±qÔ¿at¦wAË¯Eë*£„‡ï\'êhylK®Önq	E°5]UŒkPK"Şÿ€ƒ\GqC„4PÒ‚;˜€¾ãñ}$ÃÖÄS¼ƒFª6ıÓ¾{·<äîŒ<ÚĞqô?Y†ÜS„GìwKı>‘ÜúŸ9E Û#ƒY~BƒË?b=p­
U¼<6ÆBb$SToÈ•Ğ>;ùo€•È³µO½zD‹ÁhÊCÜQĞâcëx…Ëq?&ÖºŠfº[ÁÂFsô—h$3çTå@+9é6bí¶ª|z2i¡}gëBD3&L¹Â¸ú»7‡­y"62\[^áKºóC0û	Ö/í‚ñd]CàÄ\kŠé×aÚSàv—èÎír­…vSû.¯E0íut	I"±“yş§[Å=?ÃåêJËP˜œG‘ZKİœ(&^Ò¸ëYVNôxåªùIæçX×8¿|\Ç5‡w€bt_Áô}çáAlOe<@@i/nÅXè*†`ë-¹°İ„Ù]9˜dM³cSü4^â2[Í^VgœYk¾hn„yÔ%‰­.j‡u2éBç|Æõ­”âÂ öTÃÏl;ıB$¶7
„´}çË½$ûBFÅğ;ò½âfõıüQ•Gˆ:=Â.U¯ßô¶.¶gëÜ‡&>mÉ$Å„}œÔ D?¤Æz€SVåË9ŒÏ::¢®¢ë?M†îè‡\yÒŠu+cœ/ZÎ“.|=L*FÇ¯p¿mä#ï®¯ò MóˆzÉZ—´ŞˆàèS`ÎÔ„S›|ßãó`§°Êõ…A!/j¤`xBÍÙ=<DŠD|=T„¹2‹®v}	àqÏs3ˆ7Ol‚¸İúE¶÷@3ß.A¬qJS¢¯äñ	¶ï>ş¢ä_æØ=¸¿ê«8#ôÏ" ¡ÇÍY2d>ş÷½‚²áHwÑQ˜†¶\Y<S«²e‡?Ú®uS¹¤ÓıKAçQy‹kï¦™~$?R”7‡7ÄŒ=>xgğ­Cœ|è7ÎÛŸƒéÂÁ¢í
ÏpçuĞö©ÜËO=Ôüuy¥êU<g÷}n“~8âÔ†p¸ØYcŸ'ñSq¶õ×ÇEj,+I]c¸P|°êEü®O¶±3£^D·Àòìc=-¾"LÑ‘Ö«ã­ˆ\KĞ„»¸±²ÖÆ¦yW@›‹Ü÷@÷íu3uIŒ<£­L:y;c¼ãˆ= zÑq«¾'ÿ¦EÂUFÅeä&S©ÙÑ­^õf¶*@(ŸªK…;ïhÁšwòñùÅÍO-t·#³®X}'ÛŸäÊ4›zR	%/¿t‘‡»{_Är²[³êQ°oE”K—4KË÷¥Òe°­/ş#¤Ô0ı€ZçÛ³ßõ¿çÒ:×t?sàKğˆ^»î2RXmÂ—nÅ>D$¯á	{Qeœó´hĞW=Å ñ !íğ{BwŸ¡=ë±l&ü¨e¹ò?L?)|™èn:±‰S`jnéjt«lıK¼µ³¡GÜĞ7íKÎ*˜ì4
”îó#iò>+U…û>ÔùVôCqÌJb¿It½µ-pí”ªÌtKÇçÈDRo‚H£ºŞ¢)«¤x·êa»ëâlg¥6-@ŞÕsñA$ì@ñ¶‰ü[D>´œƒ«8‡Xü²›lH±o[!%IP4èı“êåõ‰kÃÄKÇ…SiÜj:°™xäe¿ªüjS¤¸~öv¶-æÛ	 S5õ2\«.ç2£_6aVë	Çåó[Ÿ¿:öÏƒÁ™«ë-M›×êÇ)mÇë0ú‡K'3hfèø A+ÂO®HÑÿ¬±ì2²Ñák(÷ÖÕğŸ0J«(åsacğè-Q»¾f‚"÷hèÙÍXW»ÎÄDh8Ëêqr¿³VÕÖ+†#€–½ä‹Rx1lsHQ­ğÅ%"‚¦³ªˆH¬-Õ>´Í¨àAÇí[0[™’®ï—úÜ*şpêÿìÈAfW¡Ø”ÔsP!%O‹¬B¸]'ÑocÀi¾$Fÿ¤ f}»¤v“*ò ‚Ğ4b–Cß‡fM+M,bâÍ)¼/Ãƒ¶ÜÈP(üè^ské3nÂår2rËPğ½-rùô¸Õõ÷†w‘{B@aô‘D‡{LªDÿ1à±Š‘uáØ@-şÑH´ˆÉĞFÔF·!í×¶ÃèùOãohhJúSš–=àd}MNª
‘æ„½Üô÷f]ªó‡Ã?±|iÿ%Á-G ìÎ@`ó7iYh:]8ÛBÑSa:$‰g=T`«‘ÚÎ†ÒeoÁ-—£·cR,éí'QÏpª¤V­ôpddÌÎ¦Gu|FbÊÉïI«ùğ©ïf-èš	æ;m„±}ï|½ŸÃ„EÍOt›,“õ.û
Cª¥Ü%FÓÙ›x§Ş(<ûbù8‹ÚşÑ"â*%¿ë¾´J8@·_ó¡ $\É!O]Z7×l|µúIÔÍuåçù„vî»û¹Î›x½Tœ/  éE3”×÷5­¤Î{ú]û/%™›˜¤©mF‚ƒqû%¬Œ:Ñ$Ï±ÏPO‡\p;“ú—™`iDÆø8ÿ—Œ:Y¡
EUÆ.nüÂè*$!RdßSò†Ü.™3z—èkzSŒˆ,ÃÎ!ùóffŞUlİÕü3dâş[K@ñßìDIÖ»Ø¸³j1Óx’t®aÈMÄ.7İCÖcŠú£ázv|šÙÜ4w¾'_	3PİêŒ8áfXkD-X¸â-$%¬õ¸˜1„ëÑD4_9¬54Îî5çøÀ¦Qî/¨ F	¬zV»93È˜h^3Ñ-Ú‡w½}D·¸]â“¡äÿä8É±Æ6å†yÌÿiÍj„•›.Ë÷>u¬¼6?‚ºÌWä/§)Á×ı´M~ŸYRVJÂdUPfƒI l\úp'3ƒµéÑĞæÊ»?òGj×¢;PËhMÈ›*y3{_VK]Ê¯`Ïå	éˆ3J4NùÈ:@X'EcÊ?DQÇúo.\ò¹eÓ%j ®¼äQEü"Øßì^½‘k0ÑÙ}ı,ğ«zõ¡ÌKrûXml±¡Q=ßı˜î íSF|ŸG$ß•ø-d¢‹sù.×Úy¢>xÇrôùKM[BBC=n{ñÕ¿Ùo¬Ñ/ûÇeó!5F	‚™Õ¥k2é–òF!ûÃçgÁ‡4TÍÚ#ûõ¹sÛFRu3¸¾D‰izË­·°–§'TÁ¯‚ƒ7İêšD3vÊ[VİÃØøÚ›1ª‘4ráZõULŒâÍøs†_¬Go|ÿú¹:¾Zg9ü}˜ zN}¢øh³Q¡Ñ ¹}Yüîñ9›"S_W’%;‡¨»7›ÏHµ×Š·lRA†½êd<!åBZU™ívéº˜riş™ªå5¦õÏÿüb2Ÿg“+Š786A9<ë²à†™å[ÍÁŠœrV„õ†(¹üHYúY·½-ÒZœvüS§x(Ğù|ÌÈàk:‹O¶É€šiyèµ¤»Zn'º@Ûè.²‚±5¢ÂceŠ£.4	Fô	têgññT:¢^–KZÓ*}ò9Tz½'îE#ÀßI+fŞD…*Z¦eO0¦9qòğ–^:™îç¹ñ	bàTÅSvj!Rjmáø¤!¹ËtçkPØ$¹;æÀI‘q¤ñç¯kŠ>Ğô“xŸá7•›9İïÇÀ¡nr4
KîßÚA‹`‚§ãıìpKæÑı¢!ÆñìînOP?É{ş¾ªå3‹éËµİ—ä­cì
j3˜Vé¬ˆì°àOOen°¥åÛáP˜²ğŸyÒ =MJPí´ZÖÛÏ·ÖXÄx—^'>"p¢UÕÚi;®5ôÆ%›w’3¾}{sÒ"Kûe¢OhOôšĞ
[‹—µô1¸ÀbÎØÄ€½ #x2óOÖ—ğ.ÀÎÆv]u³ôÇÃƒù6ÚôÑ^åééù%AB}‡4>IjkI@ã÷É$ôç5ÈÁ0+èí³TRE½'=ALÅÂ—ˆ¯1=ãvÌ/Ù±İ9OÆØv’ãúnl2Ù…ÉØ½ˆş›‰8¥…n=ìæÃÿâÉM	*$ŠMy¯A§t®©ˆû²s5×/PqåQ‚¤‘AŞL½Ù˜ùÓşÒªäí°½r¥û0ÙK¥	^’ŞxY’-‰·&½>ïˆ“>á£ÁÚÉÀš^"èòûÓ7¢i!z
 ÷°9†Ú$Âÿ$¤o5£e‘TMd™Ü£ø| 2ĞÂƒûÏcÅÆ
‚$vR¸x!% -‘aº’dÚëÉÍâ`’¿ìo¯æ}EIèÖïuàĞ7¿¢İ˜õuF0¯°Ç¹ÚJgbÀô8¯úÜDœ+ğZÂİĞtJ¯=œG»Õ§Ü*	AÄ4k,|ôYÊŸO‡¶P8@¢ºÓÙM™ X*/sœk÷ù§s¿RötŠ]_Mî±t®7_|if­ï]pÌzYœåVKéÍêİB¿($[Nüu6 øöw«8šGq¸U4'jì#vşGá8nêoëk@¤^ëîÎv»QE=\|ÉÓµ¿÷¾3ƒŸÔ¶ÿâ2Åàäœ+â>3íšà–xPUi›QğÛÛ¼\vdu²×-÷÷OÆDG`jGeVU=•²ÀÇ]]Éş„1ŸåK¹ qî¼üôJ1`i#ÀWÛ„ÇHª¦§Cš(Úzk”İ©­Ä”$òtDæ"3†ÏPùôRrbª¾w4.,ğŸı£ˆ*;ÜmúX¶?êPÈPÑÇâHR ÔçŠ{VØÓG“IæãÛ¾T]°¿^âC„œƒ-+ áa¹–Ç¹ƒÆHıõ©P¯ÍJ®ß¸0Ã€I	[õñ‡ˆÚgªª ]T•Ãˆo”>šÌ{#¨û8¸:´®}.(â™rÃĞ’2†ËtadªÉJŒ»`¬Jàÿ['+M¦ØOÈ)@›?m#ld°íµ4²«„~òÊ=â’TĞş6ÊmñfvÙiäQ´ "ƒU~?pNH½5šˆÍ¥¨G\İ¿5±ZŞGÑg¤$¿¹-£187:oóB¨QæB-•3Nb_hèá	‡éôkŞºvm uX2O—dO)tÂÈÌãaõ½Àü‹I˜Œøİcvd†üá>šÆQ½¼Ö
Œ@«ßÈŸQdˆ“r†§Ç<Â"¦Ğ.®¬†]›LœV;˜WÒz¢v±GpGÉå»hå(Úr#Pà£úR hœÉîãómÓ¨…ápÉ­y®-aî×,{¯_=5­æyİ$!gV£5#€N4_mk6YûPTP.g}HƒÀ€«—4|»!ëÄ|ZzD6n°1À$²Vü1Ñòæ]ZNá Yµ0:ëŠ¸ ­k–»š ÍåÉÄşäp	Õ³Ä-é×:‚ØæìÉ]Ğk´OQÈ¸êV"ı[‚ıKƒªæQcîå¶¹‹Š$ğ	õ7î±ŠQ÷-§Æúåº.sÂ)Gí×Næf³'…nD¸¹¹·Q•óQçš¤j×¼–ªË:ÏôM2'–	3ƒˆéõ ±ihSßs²™p …IëmŸ(0K,&ÿ“²lûCÓfĞQ¯Cq~HÅÄlƒS»ÀÍÂã†(§\Ä%MFË='U(cøí©®_t1â(3\=j?&tk¢a˜ÿ„Gâ	‡‘£çaOš½
Úp«€„ÇÕC“å‘“Åø¥aË98ë`ò,óCÆö|ÚPé¦ã:Œš/‚» Şd0u|KÅ÷û+š}@-g?$çOÇI+Oæì¼9Œéh„y„`ªÃ”ê1®÷Å›P®U s#F…¡&÷ü˜<aiEÚ2O¨İĞ±ÓéKYnR‰&vch,ò!¯ÙBC”j
ÿ.ywˆûø¡Î]·ßşê0L±ÊA¡®OhãÈA¦T¤9Påã±µÊÃËû1tP]mÙNÙ¢Ïİ‹Š©šn˜ÇJ’·-¿Ù1œ
¸–{Ÿ[¼zt×ğJĞfŸ¯7PÛîÌ@6Ægâª
ğvÖVÑ¹:úø‹ZÊÎ!“y¢ÅZ˜j*ÎAØJ°¿âŸ†¤"g·{pÓ¸$De@›-:ÍĞl9Í\{N5*z‡À¥øÚ`ıOºÆÍõmwì†=ß)¼Ç¹íM_ùö±ìÎİÉp}Å‡ı$İ¯ÈúST~IŠ‚uZÏT\¡ÂL˜Ø#ßKußM,î1_m#¹0|B¥¶ h‚!í5q4cBÆÿ+ SÃju4ßŒ ¹åªB­—ëŸÒÃÛøL”,†¨npŞÌ—õË§ÎşT Ç(ù1œÖ@¼/Ë~A\ B¡ª "Ãõ/c‡@› 2n:ş·xIÓc©‚R­ğ›Ñ3˜Qö@Õıqıáº+a§¡Ocf…ÃŠ÷`)«¦÷¬3ë$t 5¿¿ørØË•ñâZıÒ&š|«Èm'kÇÑ6Ò¥¬4œ^i Á B’¬ÉûÌö;ƒfw2úYËeÒ4Ÿ©Ë.¯¸H¸Ù¶êñ™Õ¿P'>—´0œI\˜w²Ş÷Hƒnò>ÛÅò'84…ÊÅ®#ÚÆ·•0ÏÒ‡j|Ùò—µÜ–%òä<¢­²ÉOÎÃ[òÙ«-©9†T$éĞ5Ë-urÀÁ³i(Ô?¸¶öSÄ½T¥”ê%È¡¥3Í2h‹CØk”4656{*­5Ê¬Ë­òíµ?‘ñáß!7(QÜ$~c[ÕÅCşjGj~".ÊÜÆ²wÀâ%µ•‚zø¼G¼HÎº·±F³âÖDXÒÓ‘šÆ±&ŸÇÜá2W]4ƒşæP¹šøxÕ½D¶õhÖJŞàÄ2!IP^îØûÅ2ñò‰|{9ç½ñŒ–Æ²@Hòú®TÍ½ìÃëgÅq}\cU^OõF9«År”Ã6Ø-‰véM«Tm7ñ9°•×ß»#bš)¸Ã=187f£%BiÌ§™inUº!Ø » ‚]jN>ÿbœêËÿü®¯Ô[:5—¹¶¬È¹•‹] -íıß{æ‚¿†ï¸Ä\|?*&i1¼8hhÄz„VU:2Ê}‡³—ÍOttã”å¾Š1Äˆò©lıóhõNÍÍ»;…5W­öÇh`=h°êu{¾YŞt$9v{÷jŞ#jãexOÖ<æ\u(U%]j\côNCØÒ2Q]bN‰”¬Ïf}ÂŞ¸5Æ¡²áÜÒ$İzîPy]{ˆŠ¶—øõ˜L’M"ß’4ÜÇBwîvEÌ… ùx¨Æ³ ±/Ê f2f€(]e×‹ë-šKê³}Î•5‹}ÆX…G$‡ùòët<ÿì†,ûÇpÑ)(L®øY@r+%´n74¼òmÔã$šÃÔ_ó N&­ ‘óªxH‚”×°T3~Æßlø8)Äs×MU/¿‰—H‘Â€éæô±Ïz'·|ë²M6<6ÕÕÌ›¸@ÆÇh×ZÁïv—¸ŒñO&f÷Û«LYš»Íº´o½5ÊoptºRfÌ¬2;sÆîpu¨œ›|S§s†Ïxåïj'Ò¸Ù£†¤ÿ±û$ş3H„´’*hî:lú‹TZw£×jÇM]ÉDoy´fzù©Ã8N(&Ô/Ç–Å7k1‡»˜Ğ_W…g²ÍV½±ìø
ÜG”.C„LÅ·m÷¢§¬8ò3ğÈƒùô1ü¥¾I„“¼pÛæUì2 zHŸŠŒ£¢fğ;û½eon/¾İzMK$Sá;=azµ¹êBT5U‡Æfœ´%‚æIÙ.ğQùwù†éË3•êLq¯/»hï&Å©V©Oøœ±»E¯gûòK™—‹´ş¨›hAæÄ~ÏJh‘WìVû}¼iÁv3”<yOÍ¿e€²ë{ò|}9„š:¢bª#R âÉ9P±là@,3Ivğ¬Ğ‘”˜ŒG°ç¢ì4d%¡^ƒ2¦šgA~o“?ÿ^Z$’fX…&ÜıDfÕ¿Û!:ÛZ’‰Â¦¬²€_b/jŸ/;ÊMP}ôáE”?’a¿õ‘ö€ıÁš®´É®^°èá³[zÛÈs§¢HVÓ8œ+¦kTL„›¥wBææiìÄï·4Wáş›³<XşÑ¿àıÔÖåW9¨D'·7RÊ
Àw®Hª ÖĞZn]v? FŸ‘‘Üt±!¡=wÙ–9”
Ñ}˜7øŒíXĞfƒI¶ÀÒá-ö“*¤¦j½Jâ]
Tˆ“¥Ñs¼•eõÃ¬Æ×xT88Úµˆó•ú;~ßÎ5BZN‹l)ÓtÌ’Æ)ƒîßĞ`Uj†ïÚwBgŸô–ƒ'£ï@
Nœ¤ oÍIs:Ú°ŸçjùŞúS(.wcÛVˆ
W·äPDT €Àµñ’¶~‘ääì7”`–î¤Û¡CsjáG£™·²Ã
saa‹x,\±"ÛL4Áâ?()¯We²hw6ÉÁÔåÕWÎÍ~Ÿ2º
œB«º„]J.Z‹Uå`-bT¢ÌÌUn¶öy´,h¦
*ÓL˜;bÑl.\è­\¨^* ylÛ’æ†½T3W®\°'s‚?±
¶*mµ¨gà„ŞüßÛÂ¥½©)3”ú¨áº¥P~½SK.¯ßØnñéE„ìşÒ¯Ö&÷ó±P0œ“IÛ+m0s[l†À P§›Èæ‡«ë‡Âs½tó¾¨8™µ’6}&Ì1JŠ„uöR‹é½uvønŠ³Z[—Ø	îM,f=ıÊŠd÷cµÿ·N˜óŞIÇ«× !€XıQ™–õX7Õ¹/İÕ+´‹ÍX­1š`#Á5ß)4îoçd
xîŞFNÆd[jP<n³Ci£ x|¹>á”m¼†4P°ò ÷)è:=/y
UŒİ‹j4Xf@
14µ>¯ZŒÖUÅ&\[<ú<í–Ö1_¼íy/8 `û[Ÿ­ÛÉ1Øø¶ÜÆr~üE@b—uìÖDmš’ç	]ø¦q¹­-ÔƒÑ‰Õ&Ô£;›½w°É=ì,Ú«H·c+L—ñ)«pí$pÕQ};s•Îİ¨@õKeÏ¬¼ÿ…Äwq
dv_—Mòİ½YÆ-£ÚQj)}w6©$ŒÙ€%ºèV-eoµÌ;<;	3C›}üÕ&B¤»aûüÛ—P0ÇŒú5!œ‚°CœÒ1;sHÚ}xEhö©©jüÏÅÕ`TQed‡èôšÁ*\©ò·ë£yÒ¹»Qá>I—\d[ajíE#†ÅÑ­y~3t;œ# SËQC{5vÆt\pQ³]Üëó4ÕM<®~f»®KÓÊŠ27ğ´+¶
Gİd[eàï!ç
F¥GŒøª\Ğøs)®šœujş­ŞZÜÈeÖwvx³•¦û¬Ø9î¶A‰ùû¹(Å$cj?¬€kƒ:CvSeÂ:¢¦öÃÌÎÏ‰!Œ÷WË.†g§#‚Ñ¼cò¯aÂÖîŠEıF°è:GÂO“w5ÀªõtN÷kUíÿ	¥%kˆŞF÷ÈT+U#¯(çà’‰^°ß¸0 Ş¯Ó\–²S”ª¾k È­j^¹¶­7às–ÚRŞVõ0m¯³ŒÁa„÷svöğÆ÷€ÕhĞ“‘ÕvğL[|$½3$Ï¯¸S,BHñÊÏ—6ÚUÍ°^vûÎ%äƒ¸'Ì&€¿§Ò‘–æFd‡pDWúá#Óq?§¶ü }?€ÀÜ‘–Pçdá[{ÉéAÈìvæå¡ÑÚ2üx·¨Òœ±¼Ç-=×é•pk<¥Öçt…nÉÍäÍ÷b”ğ½¹|æ9»ÁÇåëšİ4ÇÅ,£‡
MRÆ2¢ô	Áá0 ÷ë1'îÅîæ¤B]{}‡/s„úÄ?õSbIT°2ôÓ¹­/^`=,xWR`„VU5|W‚ÙÈiÁ¾Ÿ†»{S¥È>~òÓ»mZmÆVÏåœ­¼op™“) Çåˆ7s0¼ıV‘0Ao»@ºŠàïşİ<k$/Ê‰“¡~ùCıi^=+‘d¡n‹ˆ‡V2Œà+0*ö	ó²ãµ4•z÷5Ì²øn^Zû.ŞSƒUƒÖŸ8A`-%Ø°ÃlÂ8„g+M©'ËÀÔ¶Úu»p"²×ijaÌúP ‚©â÷à ÆDm l3"KäÜƒáÿOï$t`Á÷¾SÆ¦’P–¤zVrì\EÓÏĞuUô¹ÓıvÀ¹[ÔW{Øï^×ôS$µõïåÜ™§Ó±¬{ŒşİêéNì¾?]*œ ]×,j§,ğíÑI.æôÍÙR’ñ®{˜ûƒ+øÎËzï|ôP^~+e/ıÑÔ«í	i¡w¿ç_§D…·*¹³—ÑÛ&ï¶ûFó•|:Éœ]ëàñÁ	)uìd/Í©_`œ4ĞUQæYj¨,¼Şw>ò†«¾
—õÒY\On„äY¢·-$Ó½Óí…V±;ê0”®+ëõğãaiö«»#İŞ;á9P1 öÔpÛ€UmŒa#Ï|i]šËQ`™’à<ÅÙY-`šây…]3xoñÜ$]ĞqÁ§,Ì~:c=OW9ì²à ©îDàõQJ!fÿö6Iÿ}¶r;;i¤àO®x¬e×¸’?¥ËwæRŸBHe0]q`§ªuß	Èøë§–§ÈØ´
ÎÆ‘Ø˜*X<Æ‹§7ÑøDÖ°iòï€ú²‘©zxı Ë!sêº°ëÈÚªK+2ã†´À^–ÇŠø §äDXeÿAŠeß@É±ô|®üåÍKÈCİ!İÂZÖqs³q0İ.şR?A¡
èßÆæ±Éÿa´¶ù)3ñ€[ÕOr÷	,je‘Æf‚ğtKú¤«&* ³šYÿTvŒ8‹ÔPŒê•®4¢NbÆ¸Óç$À´ÍeöôïRÊmÂŒ^İÙiô!Y€ï÷¶UjkîdVî³n¨hĞr.:[ˆ5(KòP…¾â¼õüšÂ #4—¦Rårq <‘>qµWéˆ.é!ÄfRt}TŞÅIrl œâ'd,&M¦o­ÖhB TÉÔ²Å}Kò·mÅJ^,€ÚÖ7íŸøj:­¨s'µ??Ğàv÷`XP—¬ À¬Ä²<ºÏµ`ıMë¼ùÌ€c;H8Òà%d}Z8ù›ïï*˜‚EPÙ4‚‡@wœ`ãÏ*NË!÷ñ'©V“Ğuâ_j;šç3¨Ç"1±ş•€âœ‡M¹ni\&õä-ä|A‰`ĞTû7F!%›Ä,´˜¯@¦PŠü;7pÂfŠHz>?ÃÖ*¹<…”?Ks}¼Ä±Ùn›\B3ŠdX%Ó¨}•Mtëi{Ûcn³Úu7Ò¡æ?|‘H©EPŠŸëWù¸qSœùÈ•^%	^Cùv4$B“×á·w¢¦!¢äğƒKş§"tSˆ ±üÖY‰‹7‹G®şœ˜°8¹ò©Ë:Œk‘SÍlj ÊÄÓ[¢ˆ¦&r<›Ï™óOø†µÜ*.S ¶]VÜ»&¤¯R—wíF_,®ı”°à; Hû¶d€m8´-	ùZ×k·LGÔî–ÊÁ“æÓ‘.r(ÚŞ!ç‡şŒ1Çÿ¬¨Ğ=É±'ö)€˜a,ö¨\Øÿ«óØŸtØä=€äi0(Ûñ4'Ÿ…Q.„õ/	ËYö}¨$ø¾ÈŸÂîñ€N¹¨8{•¨IÆ,[ó¦
¨Â+ŒSä>ëœÖUPîİ‚_v
},¾wp«§K‘›æë^9#]œ«"ÏX@“FUù-d-·ÙÖ	µdYX¶¬ßÄR=9«rr‹tùlİö<Œ=ÚÛrÑL^¸àp¿}·²>¾Ë:çÄïÅƒ÷s<`6<Aå5áBí²)¿faHÊJ`ó¡0iØ¢ÒÀñ,Ofğûzˆ°·Z\i
åz[J°³.­îÕí¨!Ê£Ñ±Ü5âÛwin¼Ğ–¦ì±/
d¥3ª–«Q ‡zkärškà^;ğWS¦Ùu•55n°Ğ!øğì7iÒO×ë¤)0ì{æC‡“¾s,1AÙl€§¹WfP, ;*0,ø?dÇæ0>p¬ëéÒ^¡ßì!MPA»Ãıí¢Ÿçä€C«ÕÎ–î1½pñy&õ9©†O1¥º©$^ĞÚxçÿí“¼Lÿ{Øå»)dü_YŞŒ^ : š2¤=ÜÒå"„RùP}3µŠ£Ê¢ iêæèâB¬Õ­s0—>Ç‡l[½&Å×.’NĞ@1	¡ÃM
Ş0ÌÉì\i‰ìÃ½kJŞcEš\v“0YM#±lh-‘î‘-—ÜÖÒ‹³2Mpº;ÆS²CX2ñîR,ÚÉíÈ½xÿá8<.R™,.µr:rë4Ú¬À $Ş.QŠIa/5§M4¼)†YtVëúòû7½ÍÚ4ìñ—`Åt«¸?nè¸ÛÁ}Gı– ¹³A‡ÌœåÄŸÙ³ãGØ”|íI:ä:ø|ŒLc©3G>e´x,óµÓ0iÆÍM¥'jEòÖÔ¸iõ“hÑRvX(­±íZ_£À?Ÿø®u“5yÚO/º»ó§á ª9Çst³¶ú$n“b©Ñ¹8Ï€ƒ¾×WSàÙÙi{He"Ë7}¬ğ.ï+=I	Â¤7d,«$üå¢İı/¨s
N'óìhüAcIû¶N ‡ÂÖ1å½ËÄ	Ÿ1‘‡Ÿ—ğ2}u¤ßgëİòw! Ó}œÏBb’š8ÎFy6Ç*¸¨Näˆ	{	plm -ĞbµÚ¤ec»	ÀÜ_ôç‘ö”	52ÉÀzè|Ôj¿wsÇ¸¢JnjÏ]“ázä.¹Å˜M–DÂ'HÄ¤~!”hûëX)Ğ7Déı5ßh\=¢ÍHäÌ ‰ò.%YØLB½ïÀYô÷¿ÏÓôº:1uçû–ïSgİ~Y1‰eÿCFmª¡x{²G”S‚Ëætâ‚ƒB–¡ÕÆãÅÌ¸ÿ.¬+^Íû,Óy]ÏR‚«Ü·!œ#Íğµvßü€
š-ìD$7©h–`F1-ò*F¥dáU›×¸@ÆÿXÌ:+ºó?F /Æ":A¤EÃ2åm¯MğìUÈÜF€ÇâÔf'|ê¿VZÉ€ü9É&wD}Z•J÷zÒIã¸å—œ?ß,6CŒˆ5*C:sk˜UÖU1î8æXü±úÀ	JM¦lúâÿGæ–”úËô_vÍÒE±tt:cï
Yº‹Ó^Fg0i›ÿöÆcs`ç"Œ€H²"!ÈÁ„áì‚€~RİQ›íL<O‰g°‡pqdñ"ºBå—lˆÛ½âƒÒv™vÙkX„ğ¶¹ïR‡vÕraŸğÕ*ñ»ø2™Î0Èe‘®e®½ÌşşëÇ_ş3((:šWBÙï·bA<éì¦,p@g ¶‚†?-9z›•fÈ†‹äæDQ»Äp3Eµ÷ÿ*Æ9’îéyÈFŒ¿Ï”Wá90Hû@†³üO“ \ı‰G2,‰„‘6­®·§º_`µ¼¾QÉ$U£.ÖO³§<l	+%§ß€/øFÁÍÖ³eÜaÇíà&Ô¤‹òõ„x¯V*õw’h~E€µª:ßzIXæ’Òob0«ŸY]›ş)ØzïÜñ4Ê~ù-Qs:>e,ú’Ô#™ X&50éÈ(†ù•µÈw$²å¢%aEÉ>¬Ù@9×Ô¿fB_ğ ­Â3ş.áÔ¡4Ç¢UÀ…ÉLVêN\Zé˜îÒÅ×ª¦ŠëFÔÁŒ¤mJ¼ÕàK”ï‰É,Àÿâƒœ‘˜×LÜ»pœô3òVéâ_]0+ùZôyH¬íÉHèWÌÀÖ[²Õ^!ÅR !‹ş¡£)‹uĞ§èËÚN^$ğ¤¢{oF³VNzP+&øå–ôø&$|¸è£¥‡ÛX&ÏĞÁNpûĞÂÅâ­6¶ÖÛFq9ÜÓ ^Sù…aóôâÁÓz”µÃ´x_–æ°‚Í¦r3>¨?æä5õUûü’TY‚iâ_M˜ğx¨o7ls°¶Ò¾ç	½¨v	':¢åS2ë]±³çK=œyS2Ş¸K!k¤aèö²Ô\“eÃaÉiÂ0Ó¤4Ì>×æªA1‰,V#Õ¾†¦C.5F•‡HâhoÌÄsJqÕ÷Gc½Ÿ½õVV§äeø‚5˜¼ˆ ­y­Á`.éPÎ—,lµØë¬x“ föœSÑ¦Áä@51+¼Àá!Š-ÍÜ—j7Ç™h¬<HI`›¶œ Ò $Ÿ—©ˆ)åî:-o˜ğİ™t•´ìê=E·—Ë
¹vì[djN­íáWcuq¶M¤µdX” ¬+ô¹Ø[”Ÿ.ù;ÓQº¡¹±ıÏ²{ˆÈ´–Œ£‘1ËüºÛl9Œï‚›\’³ø’É:»œm.‡åŠ÷ÕÓññ‡7ò“I ppôÎë¢Êx4p|Ÿ’~à[VèSıÃX¦W8Ô…±&3†vß?D8•Ôä†ˆ¥r©Ìw‘¦SRŸbaóƒ—Z¾o2êäi{×t±“\ó³¼Şµ¬¯F(İ·<j:{>G’}TæºüÛÎğ|Î™‚¹×—õ“‹Dq…UÍRÑ¶=â‘J¨±ßô3*Ê¥)8µN´ÆÛ¼M$ÅéNKwNLªY™ªa6››|s´µ}wl”¶ÓÖ¸Œ|Dú í:±šîo†nĞ_®}=(KCv¢µ«ÌçèêMi#|KkºC&‰*>>ÁCÆø0o¼.MüÑÂ¨£€]!{ZèÜÄg¤íò.Vb`7’ÎL¢îí<+äã5®ú£ôCeˆšL5	CY1­P ÈT½ÚSÍ¡É˜‡$”ôŒoí@S´79ÊÖ«I–¯»ºBÕ6˜>'Ÿ®|èYm)jæâ5u}znk½7¢3ØTÿ^~]ÛØÖı#‡ö*›Rr÷ˆÔğqØÓó¿HÈ€ş	Ä%7œÖ»¾‡ëMu	 w<Ş—>.³ˆa‚®Æ¹Ø tF'šş~ÒvNÈ\,&k
F[ìø‰÷i”gÒÜç‰ÔHÒ}t½!TF¨7$£À™˜NPî·ªÔilÎ320Úº¿±[ÕØÜ÷cŠ‚ÕC£Ş$Úäg¦	KM*Á?ä ğŸŠÈu5êënõWHçÃ—³(Q5˜YÇ‰1rª ´•Ÿú¬s’°´fw	“dX¬şwuGÎ[‘Å°9Û'¤.6-tADö	R¡EJèºîÖÓ"bÚ‡M$"Ø¹ÑÈ·¸'˜v
9ş•q1Rr2½PúËN<±a§¹¯ZGß“R¢*õİ"d‡\5×çâ.Ğ*é\ô¹§Ãnş\’M¥o>ƒåÀ¨xbe’‘Œø„İõå,!¯#ƒq‘ù¢K²=â·qŞ|Ï€ÕP0ó¥m¿ìJö'òüyî,$õ©¢ª0®òoy09¹I{=©I39µÚ}y­lw"á¢í©ÍdñÜrhvIrµ3L(90”¢äÄgaíV½c¸,i<ãAOo³âµWh¸†YmºÒœ`°îœŞ¦z„Şòn1I $ú¼šy·üGTQ<¾†Â#Ü>,IĞ}xÕàT¥uA»- §ÉUDİ¿«¹'$C2§°¥LÏ=?TÁ¹º¸­…|ã¢ğ;¹ÅBPDjH&bfë2Û5>?Ñ’5ĞÎİ¬–n€Û‰( 8s4cÎÀW¹û Ù•±N–´eÿsÜ­’géjŠO”pÿşì¨Tw=5©ÙÓ‡Á]ÍSmŠ·,¾iÿ¯
	õÒéê~´†’qraÏ-}û÷„Â°O[>l£¦³O‚}ÜÇS«ŞYô'ıG~W¿s‘áŞ_¼M°†!¥uJ7œØ¾.ÃCxÓ& ¨LÄş˜ –‰¦5}±ÌzO;İ“y	Íà„mêkù£îyÆ3¼áG!ø“ ú“íÅ>„2Â&tUZ~©sìµsOÇÜ”¹<¨Ô="Ühu& ş\ob,¿¤_³“á›ÜTÑ+¥Y	+ ôàj§]Ô
odº9t.2¯T:„î¨”¤8ì..*3·tÄaõ/“d2OØÕø(JhqSË]Ó·ë:œ4Aº:qŒŞ7‘À‰nO£¤¯¤ÍŸqO­ZöÇôùêÅ¸dô˜²Äàó–æîgûÜ>=|ôÏ~ı%…~¹fïï\Ë¯)Üb…h&?–”‚_Hî°[ûÕDàX…‘Š}Èfú¯»iHÛ‰òü¦åq@Òn€ÍÏ›IWPéEho>ûË{Ë1Áx†ìCƒ,½ª€DÉlñ§Ã‰ÑS©Ü/{ñøıV¶é©4L58¤Bzmõ½mèˆkÆ£Ü}ÒêzWJî½ßEõ˜°œË¯ãlW$&>RO‡-òq¯NŠáºHv¬¼E›Î{ OÅßdÙ¿"@SÛ­Í‡®ĞÎpPu' !®ÍIÛ­
µÙgêåŸ›â$UE›–L¹§yÎkn±fãip÷©ÙßWi¼€^4
ÁmËYæ£ÊÅM=Ì·8—/F0ïa%Í)}
°43z=@÷ÄwZòEöA½ƒ­ò[§Ì—¬qœ¢‘("ÁëNNR¸ª764Ìâ™I™¼HF|’SéÌæ(ÏDOâ4ñ¿1»–Š9½Ìø|T´8u±1œñBÆZô ZÿX-´ªFğ;3œ• M>DqRæÒ2¶Mnbâ3Z…Bmp±½NÈû1Båb¥ÈÓ*j;W¥üêÖßû‚'†ƒñ(\i»Ÿ}›¿¼?«—ÙíäÇš_ÇĞÁ cªî*.‘QRÒ(v°rö/?¾‘ı®m»%úó(Æ£VÂ¹…éÿr¼Ñ·¢¥ ~Ñ
ÿğ^ô\M3©È\ù.
ÑU|¡2Ğ1H+¨gÙYÓ:¤ü` ÔòhŸ¢Ø^àœã&V="ıjV1è	ÌàEª3êtğ²Üû`oøÂ|H¡ç8bêöí­>öäNÁmƒÁ,-Ñ90 Ñ~M†¡Î%MÎïpß0r#:[½|\×W?jM³	 Ş×½sXªrYÌœ7Î¼¹ •puäRu5×ù¶ß	M§£À+ôbe-Dé…ÚØìÀÁÿWæÆG0¨Ò69'hVÌÛŞùí*:Ç2|œ¾F7è®¿y‡ÕÙCß©dŸ~¨P2·”h;Ù>şƒT9@ñ8^Ó
~'‡P©1Ge2}ÁÌöáøgäÃäÙj•Øæ^­š‹ÄS9»oÅ—®ÂrB3ôS1Z‰#Ğ{ñ¡h‹JV6öwV5œ.!›Á©K ¸§úÿåïÒÖI¯Aj*ÅÈZ@H¿ó½Euc¾"=B¸¶_Uv‹5 ¨ø·ÚôD”¾&RóÓ>Rµ:Cmê3ğq%‘å†2rÂB,qyG(ç$"ú¸W?Y%¯ ¸¥-òïÓ5ğç>Óøñİ›YöìgD^¹›yĞ QÛk!V!Î¯$®ËÃ¬ÀÉ¾6M¾™oó_,òÖ:˜ÎMÎÙÒùz˜ıyZMĞã5.š²¬­’0O­eQUTc	³š9‹Îjwe_/B¦l3»œ'Ä°â\‰‰şàJÕºt—°ÌGDbS-©é“¸e¶½•2ğÙp¡ÌoÒC–)%éapnş$ˆ¾ÙÈz‹ö—ëvOT	Î ÷%$ Q•·Y”äo?4›ı³2Wãçpš]ÄüÅ
_ÓŞØ
Vı˜-2ïÉräÄuTÊemI×³å:I'‘š+«{”/Ë%~4XVÅò¢ê•@AÎ›x('U§X(ç?Nr\nÄ7“Ô•¦_&1cOêjÅ8CdBeVÅĞÏAn"Ô(éYà‰ÿÈ§q¾&ñæ¬ã¦ŠœÙ’ljµì$çxa‘K:{;4{Ë´«ôp©à›»á%·®å9õf"×ŠùÜF.¬#ü²¶]>È§.çˆjSáã4ÀË¾”@¬'L_6ìûÌ»
A¹û@„ûnˆ‹ Ù9
7Š‚ƒëåúWïªÒ×Ç™µÙY¯añg]pÀ=Û&³Wöìß1Ô´Oı*ƒb=Æ]f§ü6°K¢™†0 ß&CşHØ$6fò÷)«u4+Á*G-ÂÕJë>¢ûíBl¬¹‡àex&¥zãßç¹ğ)sì¡=Q’ö‚aŠœ¦ÔL-A*æÁ¤}s÷ÓlÍì–ä†¤JZ„˜<
8“„+¤ú)²h:zÅÅÉéôíNŸDA=öª@;*ÇQ¬7Dfñ&í™ÌEHÚà|”‰0—ÎÁï0)×ó:®#ğâşò#€¡„Çè³|yd;®SıyjF«×Î/Â¼hda‚£œ÷^]ùğŸŒ×Äİøl~LİNAr¿·–©TÒÙıgcD'pÊ-¼h2¥l?@ÅÊ-3$'¹¾­íÒ&~Ë¾ŸSgÌ¯Š^dÿ)E™«‘ŞšÄL7O%Õˆ :R+³ÓsáW‰V­VpÌëO×!\±r'N¦ÂëLÍ{%áÆ½?µÖ¾š¤§ô,+—Mš0ÔkzšĞ|…Ü‰¸[<Ê'Ùhv@ŸóÚø;“EK@³6íZ`ØÒm)r•’F/Ûö&ÕàÖßlúÁâãı¬á)”š9úÈ9r)Ù8nŠŠŒ‡#ØŒáxà6ÍÓôËåÕî•M'ëÓ,¡ Æç·»k"Ëæ\‘—Jòà”L³½Z=_Z,+ÓR#òãwú9ÿï¨½s2OÉ·CİR‹Ç}ê{ZÖEó§2FĞZqŒJme;ƒÂïîóíEÖY!ü—ÅÑúdå­ñÓYó	4 çæëÜ‘mç¹ì[ÓRË¦
iN2S•ğü}ø_,mm¿`-XãâM½×D$“¸gq+ÜkÜSo«#|yúÌå\]Pwâ LÜQ¬Õ/1,Š}
ñ4wmla‡V£ä#udl[†Œ[å´‰ßâ…Ñò/?Óã$­n3ÒjwŒÓô×J(¨yë¹ĞQ(³Je)ÃWEKƒ±®šÕŒÁ‚ ‚Le/ší«Ïp€2% zÕÖùLj¸I¿b	.Î<ç2”˜ù-[6­ìÜl\wd[ËHsï#PåB0Æm¿	ÚDµEúAy»0Ô)ÙØÙ´ûÓ_TrİéVÔ:¬ÖQYĞ†z‚<!·ÈóÜnPÑü¥]Æİ•äFÀó~Ëœ3e› Õ¤adç0ŞMØ¤è—|š¿á&ÓIpIº±¬šôóiÛLgAk¬0Qd¥ŠÍ¾b?'Õ¥ş=HC®m~*Äæ%Ãİè¿õ¢d³FA@ÚN˜	s½6<qwóMô\m(Qõ°¿12è‰Çy:èíÅ8Ù'I*¹ÜÙ‹ÂNXÛ!òé; p>MUÎ~êëó<r~¨¬’‹›àµ¸ñ`ÔŞlÈFBÕBpß3¤ü†hXº°¨o¨×—°¬¿ÃöR*}di_º3§HGÖWâÀ€)©¯Ó¿İ{×üyTRï*€áÎ›œ?&Tõ%ÓÆ^Hw ı”}ê›„ ¯†Šº¢2¬òBLú–U†#d*Lsª‹EÏT.pU&·é'mlWï3pbHØ“ÈÌr@Ò!Êä}\fÉ|¾§)ç’OÆÖ;qTV¦+âk Ê0ZŞgµÔFŞV¸é|6Jù›hÓ{âJÙ¡!ÓåœDš€»¡T>u R¾ '`Øï£ #ªÃ;½
HÛ=ô®¾Î+³¡­6qÔ€Şg'bVËwì˜ÙYÜÿÕÛ½/&ÎQb&ÛŒË±åò¦‡êêı#Ãka»ıÌ4ùï®$®eìI¶¢İPËBxï'…nÛZ®cal„Bğñ{°êË0Uğ¬å®ŒNÜSGˆê¡¥,£ipŞïªóúÈø(¿³¢ùÄébñšG0ı½Ş‚“ºR´WŸe=g¡×•´†ÈZ„ÖÏ9~q=õâ,ê¿}ÄùPÏ2Sp"Ôœ7v•ì>üû®!¹Ã
s&U%%.ÍÚşÎ‘Z×Ôr™&­’¡WñæöZ,LX24sqŞY¹BÎñ‚Ê=•øô•eeŠhşn®÷ç{™²Ã·‘8æ½8½øé©YaÑnô¹›æ:õfŞÀŒº%à…¾ÖU?AÉ¾FKõºcÂùzŸ«¾WÜAYØ=œp©ƒjsp|5»…}Gİø‹‹`ô©f³‡ëñÿ~vL'¿gº¨Ç‚t+vÛt¸ó«0‰)Æé3+õ¡È^ë¯Ñ:>éqMø›hÉêR(Z.C&`›JJx}H²G’'ÙÃ±0Cáœ€™®ç]k]%vØİ÷¿¢åHRÉjm
ŸòÚ™3'O‡a—’\aĞ©âŸ¾à+Æö4Ó}-gQ|Êâx&„Î‡`ÃtFR¯juÓ]Í£KT‡”m]:Ñƒ5@áº&˜V³‚q½®ApòöYÃˆ Z:ùØ›]çÆ…»İ%DgÏ_0ÿÜ›™²#¨YéÃb3ˆ+Sä<ù:˜Šl[k–bÁ×‹3ÇƒÈ8–övQVÜ¨¸Š™ôIØ¸ŒĞûöÇÓËŞz§µ÷äğ¶wìrğëuäÕÎˆ÷>YsÍS¸V¿w£?’T\Ö¯´+ÌbQmc•‘b—¾àbóLY	|o!˜¶/÷m -»pÎ—ikËÙéË×}¼+Jãr
¾e†¥/æ‹àš©³›@yÔ}æBH£/}—Å‘ï:eÏ÷ßÓV4*I ŸŠ3Â{‰YÕ€ÊÌb¬Ø§O’˜ÂËé‰›$êöÑÂĞhÜöäòzâ%Îüü[¾òíãŞ0äeô @-s²†+ê\¨©Ë¿Ncµy¯ #QtY®.±áqò8mûÒÛàB—>1ğ"îÓ£î‚º_ˆ°Ù}åø®¬ÊC7­X­ùÇ¾œ‚¸Ì[80,™3¯ì¥ìÉØÃIsÌ0Ñ,ö	©)p¤ïlö†PV3¾ê%mü±íÛ½™Î m¶¾³mBòO0ÛJ¢GaRÚüš¾GËm©œ#u#L,t’õiŒG2‰µ&fŒÁtc6x+'y*ÚÎÜÆ…µ¾İÒ8¯òÆ³]_ñõ¿ˆ	"™3¯:¤±W>‚9ïË+3~¨íMi }³3óƒ±çÜG¡üÂ"S]qÙqmÃ_C“ 2© %çòç.~‘>Û/(áYåäÎ‚\M'ÙV\]äã5(å_%k…¯Ö¥óóŞW§³ávKì)¼‰M‚èYÓÄÉÙYÕd¾LP@TD©ü[ ÍunÓ[Rtê´çxp–ê¨{5c¿³á×—ƒúÈŠ§m [/ú@İF­ª©r}ÑgÕ‚™(é°Á&ıfØqø’­AKU­q{:	Y2œ¿dN‡Š²‘‚¦z«:yÌGYôİuë3ø»û‡ÄI9©É•­€¿q/<Ñ˜q_óY)$Â¦öğŒL`Û•
×k­O ÒK¶…qW”µ,æâüÃ\aX‰!ˆÁûİ„ö#ÀûŠµyğ$P†u©3ÊO^® qÎËu2-ªnq -í.¦–up	•y€µó9?î
Tƒ$'Í¥©’æYíZİÆ pŞòJµÚOŒI²Ëì@¾;M?±oBfÕ‰¯ÕC,k÷åÚŠ”ŞH ™ÿ{Æ7[:ØTU2i†É ‡, ÍÄ¢cZçS×ì¨}ËN­W¸y1ˆÚ4[.EC²Î n QÁem5$°­b9ò³]ã&{ÿBÊÕk–‰=µ”8¸·åšA³‘¥\Ö í‹,”Àµ,†PquÈr¦)…÷lFhã²Ò¨uTÛ¦“îš«ÕO¡`úâ^”‹6#ú+º-®Â¤ì`à•%Ö‹/xö#™cápeç°tË#½5p'¯¶¡şÛiÔY™(Q{"0›yM‘–†B>óäş¿PÚÑÏî(œVL@ÊşCãnÆ3ğ™.§_Ô&uË10Ù‚^“ŠK©iZ
ZSì¤÷ÀAÏş—
‰š}ÌÙ$‚_"w!»WÚ]ô.ÌÈp\º4Ç;Ê:éE›Nu"M”®º¾vdä2éØÆÆõ@
u‡ZÕ“ŠïsĞ\¬Æ‡Ÿ8r~ÖViŞ¬W” |„şìVí±ëÔ1“–hCxğ¥»šaâpŠ%Ù¬ĞHŠsVn†AÍ”dÆâÀ]š-“êßïä ¬Á))ê
½™µ!O†‚ÔL¶ßòB[Jv}¤n¿Gìtÿ ‚<+»lZA&İ\óHõI˜‹¸%ê·ˆãOYÃ?f©Êi‹ú´¿Ñ5ğåƒ‘É`ç’Ñçfƒ|aÃZfºÜ¦¼uÒê‹${›“ÅRi
‰DT¶É±*È´|ƒ¸Œ‡	pW³kB‰'}V¡œƒbğ:÷ÛX»FNÛùSß¤h— [õ1yKÇûhír¡‹~É+hÌæÀC¶èsB?ùOë’ıÖgHü@&Rá 4­Ò/Ø~Ç´Ãº%¨mñÕÒc…¸Å{>}2r÷^nâV’¢¥‚x<¥Š€óiÙr#=‡¥!ëÔ©Q>:ÂjY_÷Ô;^, ‡Oü&<u!¸ ‡Åèòñƒ~tÈ™ë¨!—¾+ËøW©Áß?:ğ}k%µ}‰ËêDÊĞ±­`«,¸KÃv®±†=…”Z€ªãW|Ğ¥jEŒ‘İêÚ¸öC–ë@w êİêZ\ˆpôÖ³°e@}À)//È0e_‡¢Ğ4zn˜Ù¦•Xô¨=ÇØpü§_Z£‘ó\Jx5!0Ã¿Uõ¶çûTZOZ¼äRö@)—¦¦or»Q¥ÜXÁ]ÀÆC­Ìq"ì¶ú…èÌhr§GJ"o|ÔÀU	§_aíe.2›ù5´aæ|ŠC’‘Ø•ÉıÒ-˜Evšõ0¦3H[¡}hjšÒSNÛIât'‰Uc`ôª—†´[9;÷Úî©å°n'¢üÛÂAùgn¡2ÌöNP/|ß>ÎyÍQZ‡e©î²·[M6CSãÀÊY©iÆ5¨ßÕÜµ”kÿ+lŸ"ÑK70 Ë¤ù'Ÿüú²^Ï±CÇ·u›[úˆ~“ùÃn¹š‹c¯Â”¸€I¾çà'ß*Û6¨êTúb0åü[9Lı«şñ„ S€ w©ä®¡	¦œğ8ìYÑ\Wokpõµáı‹°=3Ù™iÍ ]*èèõY]Nˆ	GvxNü»7D´ 5o{ok¤¥ÊE£%X´È_äP¿§]„ƒ{€éš	§{Sµ[¨ Œø{Í!
C¢ãtŸnkæVO YG3ş¸QW.,S;]W¥Óˆ£pçT4ÅİÒ’Õ¼'­=ı ^ƒqÓ@ù‘‚MÛv{qÕm¥:<šœ¯²gƒj¥ÈË¨Ú‘Ğ“p-pï}eF«;„Y´4bC>€ª¼ßg›1LN²+okEÿ*Ï*	ü5?c˜ÄP¹Ì¬Ÿê%Gg4 3I‹	s4ô\Š¸r·äÃO†
@›y~ænò>r‡Â"ŸÙ~l=İVb„wÔLÆŸ2—ö‰àb-9eíQ{¬P}sQÛC•.š)˜
{QKœ<´)Õ3Ø‹P½øå6Öê\Z¡FÜ÷¢Îjã1$˜Ä”x§wœ+'Ô„$ØmjÀ”Š0yç†>aÙ]iŸ”ã–ÚzÎô˜^pğÌòÅ{ïqXrï…Sgó€/=¨x\®ÃŸ©634·³–:,½%Ì4„[ÿ|«§>È'ntŠj2l…»‚f±…zJØ•§;İĞÉyè:êvÓ6X³şb§ŒZÚ²ÛxÕWúÁ²quË%^*ÍÙ$YBŞÊtÆ“=Œ¸ÏÕ¥ÀÔÔ×5¸m½Øˆ*«““Y£[É9Oê½}~²Ú)ON7ıVÆ4&¶Ü»´Nëä’íÂ`w‡(
¥óëã«Ì ~ø÷£Ÿ¶Õ¾z İ<P[ÊL¥MŞİÂD–mó&KwDML=iÑ›×‹km$§T.Úå ‹™Y¦gÿxÈ7}•ï0·D|ãınĞ†ûĞ~£awç~êÒKœn7K[€oa3×°X\ƒ?©7#‰HÇ°sôû‚¿NME¹Æ-÷$Fÿ[ÇêÕ“Ğ_[QmQ57’ÁnóõF]˜›XN´­au/y‰Ïò<Èùü¤„ñ#qàV“]ùÖ4z^,¬I†e§¥.Ájj[88¢_5™R‘LgÃ˜ØW(úÅEULÔÃ’ÌN~]
ÍVıÑ¡Ğ óê‰!B™Lç+:ÑëòkKû>Xy ôk¼.ù>œ­…o–~ËÏl@QÆ:g°P»\:TçgÁ3…ĞñÑÂõØ˜ÍFq4?ªõ@+ Q(¡ëâñ<®}Uo1J«¹0¯¹7yœ]òıçw¸¦ú‹éG0 ©İ©-={„­é®ÑŞ=}ˆ2C3¤¹!öÏt–ˆ’À ÙÊ÷Guˆï¬NÉG÷St….k—€=lÀ¢x„mo –W€Şø?ìühLA³1_™iËä¦UÜ?‡×?˜;@´÷s6ÇJ§&Ğ?ìğ‹|CçÙ˜6rBÀƒÈ!p'ùu¯¦~)¢Ò½›¨„uÕ¼—¾jZ ²Kä´È;³Ï™•À•Â%=ˆç¸1Øàu;Í•ûˆâŞ>ïíí¬ÈK3’Õ(ÚfÌdá°-¨€q14e–1.ã…ÌûHÍK FLäò’ˆaVŒÔr*š¼E´êŠsó?Ív”¾-ïü7’ÉPíI˜IÒà7˜\'L{Öæ’"±Z–ûïgX¡%ë^¬«Ñ±Û4ÆÚ4w(<zHÓùÚ|©Ñrˆ6î>{ˆtŒ,bÚÊŠï4:ıŠd¥øj¨zz½–ó3‹İ$ÖËÇ’³/³“¶`+œcÊa>X°${DrDI.Õ€ÂQĞª´¶¾w5|öBYI4=¡N¤_@’»L"^<ØËø5dÈÃğíøTñ›a¦¥Dr¿©Ğ7Ø„ø˜àbÓ‡Có0¡œ¡¥]±EXãÅLóßR
Óëİ4z¡›¥ô—éû×éprô¹§äNÔ$©’×	…>§Õb‘2„Ö×pDülA©Ú=€â¢Î‹NğI¦º®µaPÙöª(
˜°‰‡7Vx¯ÓãÉ>DRHZR1®ÜHÓî }¯rÍÒ°sÕ…ç¤æ¡#[+Dš­–PÛ_&Æ	™\@{QÏmŸdÍEU›«A#N‘/²ƒKš‘Z_·¡Ağ§†Bi±Íxï]x|ª§×c§êq¢[™õØ¥Šñ 	Zª-ÇîPZÌ¶ÕüßC)t\³µ/ ^dàÒ’fÎè2»§˜q·<y° —ÓáøjL€úÕw£O÷¹otCÁÊˆ4»$$.MË0â®Ï:Õv¦mP¾öovîÅöõ&Ù–FÂ¿Ïvßh–ëG‰“Y}ì¬£7f€ĞR; K¤2ØN76qúä9gkwÙƒ9Ë—µsP)Ş²d¹ß´dz÷ ô×ç¾êa!Hú;T\I¦‹Á‡ŞğfnÁªŒJ6GXZFµÚ%õ5´Ô8f
”AËØš<¿©Šs'·áÀ·—‡,:–¨%«Ü¿ngŒdnxÑ2¯)¼ëŞ¨aXBŒİ‘ë’”®mÅA55SÙäŠ/!/Ó¾ÅkÏˆpœ‰¾º,[÷Òè™Í¯¥«uÑş4/ìf‚²°Ç¾+?F•_CUşWQ<ï½VœmyCèb áMÄıš&æò:¥‹l½À@É÷ÜMÍ±—å§qâú§¦bcpdÍïà|‡Ê5VMqM½×÷öç£B.š‚œÅt³ş©¥
Vw‡§‚•”,z>=Ñì4š3J–•G™Ñt^§IÑ8wu³…aû“i…zİ†)Iç†'v®âm–¢İŸ'Cñ|ø/%ø¶ä4b“šàæ|.9¦½]3…›oß˜vJ²*8ÿR*§¶È‹@F~6­Åoša4Øğ¹I·Ã®·Yøä˜J´¶3èox"TäÃìø‡:[±¨4Ñe­–'ß~ş%µæÜô·ÇçÄ¸ÇŞç3 5/+ã@Ÿ;‘>´{ Ü?úaú×€uº­)J­Cg˜ÑøTß÷lá~ŞŞh½6ğ^œ ‰‡Bp¬‘¼J+«HQÙ‹ÌèŒ>%²6™ƒ5êq‡øW´€‘WÖ"ŠlÊ•şë
Mqt®D‘Ô9Şô€.şıçAœÓ:9û7‰/+4‰ç.]Âó¶¯{*%u4DÏg×‰e«³Bå¡ŸQèıW¸¶¢7«q†„
—í—‘órªïŠ8X9šÿ˜î†ËUùš€„‚*
¿  z’lû1™† ÿ¯€ğ;O°q±Ägû    YZ