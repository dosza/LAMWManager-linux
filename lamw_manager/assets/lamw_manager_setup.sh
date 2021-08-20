#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1450613071"
MD5="b53777396b2796c8a985c19ff756dfdb"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23564"
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
	echo Date of packaging: Fri Aug 20 12:37:06 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ[Ë] ¼}•À1Dd]‡Á›PætİDöoÙ~‡µ»¤–®ÃZ&wE•5tLqƒ
½l®¡{‡vgÊWÍ…,ÄİQÖZ­÷{Dğßvî3wq?Ü_ñ?–İšÉp–=«¦”'ŠuƒëH½M­Ë²òŸê*kÔÙŒ÷O¦HÑâ:´evş€¹Ğ¸7e‹8˜×¶BÑíÓÇ¬›^Àöl®Vv=ÎPO‘Œ±‹–Ò!,DiÈø
.â¿bEäV›PŠıÌaÎ‡!;>ª†ˆTI7=£$–şz*ä Ab{ˆ£ĞóTŠv“Xy2ü'ÑÏQïj›ŸÒ*¥¥\LBí®ˆKieººg§–€å^ëŠ¨™ªDËê	†µ‚âĞ³EÀ›ª¤Ïî·›Ğf¬KÍ)Şvr%­ú9ñ©ašNëé*»€|SÙÉÄõ¡¢1ÅQâš$P(V;$5’~±Qş(9=ZVñ`xO¬Zé˜´öw€Ê¨h:Ö‰ùj½YÊÇ3¢ÎœAôi"¡¯zx)¾ŒFŒ;"T4¶³™wÔû[ZÎÉufv?º)+.² “?¿i6`¹æƒ…
¯³Tá°lög_Â‹ûQf«^í}Ñ”‰c­AğÀ«WµS46ö¿aîNg¢¯ r”(šB`é¶u3A=s[>ò…U•ÍRrY}(oá”áÍimH°â—ÙlÇ–ŸB€°Ãª“Ãàšzx<[áĞ[ êÍ×yT÷YµÄ$ê…0M©ä&§U}ñïáOxÎ“ö®s•ÜÅ²å/7ät}×=+–ØóŞ#c«ŸAtµU<².
Õ‚ªE:Ğ&.ÿ}¾V„Éè,½Tï„Å…!~’R†Òx¼Õzu"…Â]ÒğRt•+ÀKã½ş†Oì`ôˆ`‰¢ê¤\z¯¨3•Í×şÆk*BR<ş8O:ûÚSğÄM\Öìíê-‚ªË—;Ò)5¾.øóöé…úéıSõÎ8!6ße …Ï•éFzƒ“éy&¢ÏdŸÜŒDºlkwã^1Ö”Ìô¨l7S}*
-*p%ŒÑ¥ì¼//09
CiMW½5$U;h®Y°1ÁÈ7§.ƒ4ıÄÔÜ‡%ü€ü82ølê4ÿÔšªâ¿Ä0ZÒ˜¶ Ú¦.ÂrôdRÁĞıfïÕK)­“xÓvĞ;Ö±Ğ»b´] ı›¶ÒP@z¹#"ÚãŸ0¬î¬sĞ‹YöL·Ûê8é Èñ‡L2ÕDÃvœÇÉƒ%
&9/npû,oËÇ8R$ÇÿÊz)Ô?ÇPÊ®/`§8´;R“›ÏJ©âLSü1GğbêF{i¨É¬mÆ/å¡¿¼9¯¨Àüb¡½{¢!­@'CVE›ñv"…£ `ÅÇY°Ó Ÿ‘#¨[k»îOjßòå
i³È[)`z¹Ôõ2g“²Şÿ8 ŞÄ[µ8½/©ö4Q}0©vªñOéO?Œ¥G;;İÓQdƒLÍQIÌdp|¨¹šèy:/J²6,Ky×v˜‹"È3Ÿ‹'eŠ‹­aàôWğ|‡ğâ(SÛù»±ÇfAà÷/‡1U«[ÀÁÇ=/†$Iku¨k§Ä¨›LõT–T$<$,ï˜!JJšèBllr‡8QÆD,­e2èÇÉTš_Df·0œÕR¢«Ò]·v%xddÔwË7Õ‹øF“¤ÔÀa%—@2‚B¡»Ø^ˆRë~Òk™a5°şŞi€a¢„ÃÖ5éµûhKv€5êzİSlÓ<6ùÄ!}0(¯Œ&°=‡òQ€ÊÔYÆŒûÌÛ¸éA"ı8nštWÑ=S)I3îú'-ÁÕ­‚y ƒCIËüeÁ&‘Ò É`ÑUŞ.çÉÔ‘{á^14ª‡è§‹K)ÑNæ¬a¯ õåC¦kEóÙÉÙºÎ÷—ğçÊ[˜á¿ö ×ğËxƒ|¡N­WÁé.£'@}1:Èj+»i)ææm/ïÖìxöj”pÕ—¡‡a±BÙÎ°”ÈW7pwWDºCsŸnó\`u÷7D#§­ñ8¢réãt÷õoË€¡kwHƒr¾ÛUäg‰£¨G?v¸§O§ìov¨Œgö ¹X“«lv£}v¾*nÑ!Ó²´7tÿ€jS¢áÈ’m­‘LÂ…ÆºJÄèãX°”Kr2?’]t«Ê\ŒD‹ºİiî…#‚ìŸš`›Vô!¬¨æ>í‰ÉY›îOätNÎW*ú°h7Ä}séK.­FşBªö|ë 60O”¦>aH•×Ã`è„ìù"’k4ï!%Ğ˜íº“zI#ñî„‚u
”Ó¯È¤7zŸ‚ñ<úßa£å³ŸzÔh;bĞ6w]ŸúN,m³«={©3³"nœ„â ¡	' '	ˆ%@"GU×“ŠïSR›­€7eá;<êºÊÆ!ÔrvÏ{Jv\¾	õ#rs	BÑ,Ïx¬m+ü¿4Ÿve«i²7ŠÉ³%ez:2­­¢ˆQë_ÈQÙ.FkßºöHÚñJkß×iŠğíVª“ÖmîçÌ,[µQÒÏXCnb9GõDª2Å[n›¸A;şø”f mÁœ>Ê–i%Ù9¼|ïm ¶¶~54…§šwËøÏ¯”ßÒäÄš`Ñ"	tHJ+¶~Ù˜ÔªP’½JãXGWâ^UÀh‰ö$91³UíóÆ„2:ë9©!s¶ßW~w®aã=dHå;'+_\wªÉ¯+DĞu—ĞN¡ÚÕ<jd—É¶+šµ ×²p‘a!£Â‡õ«C2Ö¾l‰EØ˜Ãşd9:ÛŠ+Ò3&8ÇuÄÑ8¹,Õœ¢]çkñA¢jY4úm{A,áã• °ë0¦£C®³ñ~¨MÙ»aà'ŠÁïà5dæğ†‹YzõŠ"}³ÔºYç&ŒàNçÁ´Èì[áIQT4°ƒ<Zox²ÊR´ôk&ò•!-(bİ3Ùì*AÔ_¸	sßîª¬ƒŸ%:´$vFOµP{Å›g·“—ÿóÍ•‘b®Ô¤W€ì’¼ËJŠäŠK©’A)k?Ò~ò•F>g	Í”ğeÂMæKwnÊõMv:ËºY@eà‘u1¥òè€¡ê¸`xÊÙŒîwihEi*?†¸â oi%l´÷fhbóQb“RÃ; 9FGi}Õî§mm‘;‹¯å.,¡}š‰„jŒ?r‹,sëşÀ˜#]šCôÌ
´£ˆöN|€Ğ'fU0*´å!•†Ù¿€ŞUá„íóZ×•<‚<Èy\‰›€G®ÓŸ\7KŞut[g˜®˜'ÒDÕÁù¬©Qö|g/İHÍ4‚˜´ Ê	¸]ÀÁ-¥øjZ/ê’ÛqÕxö„˜õGXÌbØ»U³‘œ_Ö¢øîg—§)ÙXO9PSíFßa5Xâ-²ç%qf½Ù­×à$ç
Mâ¥¼Ú€vJ}ó„#,ÿ¾…Õ0i`èÌ\+‘‡“¡õİ1U™óVwc(lŒı6lÉ’Ó-?Šºn?®æLZÚİ'=‰ËmJB¦ÉÄ>ŒüÎHù™(Pi "­öZÚ‡¼«V¼GÚ`ì—:üUØABdÒõLCOuÄµ‚ÃĞäH¦$j·2ÀÆ¸ªË(/['ZÊ›ñFòÓÈ·NQòèOĞ¡Æw[¾êIÎÅP$º\r¾óp’Jœ$Îhö{ÉäùÃ{¿*/O ç(xñé"0š!9
Í4ûm»_°ºŒE¡`¦|‹í_ñK{ñ#Ú¸ÜG1ÃœN¼†¡F–%6-rÈ7t¶OË¼r1±%‘‚?G]ÁŠgìé÷”˜Z·ùâ=Â3Síá•	D™bÖµX5#Æ¡^şé«ËÆÄ0q®_†yAz[£&Ş°ÿCvÖ8i 	_ÿòô†Ï%ĞÕòµºí‚Œ•òQEíM‚‘e«e˜8¼ü¯R-Ü.¡è zgÁ»ï¬w¾~v‘2bÌ1lB*dD±zToWı;î¹z
Wy£’Ğ66è]?#ˆàÈ˜×\e'’%¾´uïÀÛvÖ€ZLNµ`_(êØ¿gBÆ-0aô¨÷µ,m»Yœpâõ_-Qø ˜Ş8Uxrù<JKÒ·?áŸ•<ò„åºÂÊÌV-ôäÄ&ÂùÁ‚‹Ø‘Ù£Û†/fpc³ˆw£zI­Œ¿÷‹lDmä[úÕ´[¬ü¤Z«ÆZv9ØÓèÏ£í{?§;iŠÓÂŸÚÚêf:ĞÒe¾‰±/,]%¥ÁÚ“'¶Ô±gê§©u»ëÜ `Èpr)½‹ü#’ö6)Æ¸¸FE‘¡(Ù*è¤˜8ŒŒR„È\†Fïğ,à«?dĞd!aåšQÓÛˆÂš÷&RÂÕ}%Ã­:¼¶¢·‘K“
RÃÒî™¯1·§¢ÙSrßÉPM{55Mğ\ËÏÓ›R“£¶ôtR"•z%”a‹c E,¹²…f]7"–ÍêR8”ñÍRaÇº50Q„û´z^=§á…"3m`SwÉjzsºoƒ_Ñp=Œ­”¤¼"XÅVï£ßŒÜN^4:œ¨ZZyÔA·l©
=^ÿ•ËP©ÂÒfrN¬af”8şZcÊ÷äìUT(şêU©\0ÎÊnŒÆ`4•Š40ÅÓY€ c.æ³İ÷ÕíQº!®_C˜Ÿ Á`†:mÑßM—A$Ïª€l*G™Ğş¸È)ÛF#qÁô_Reú´ÏbT¾`[4S¤ÃSÔ×»°ŸˆQQ’*òö0tâùŸøV~êm”:š0ÍÎHÔZí8¢é*±]üßã»ÃÂ0|±Û–£6xÓùíP7+”¨!ã”m©Å¤3˜”€‘:™W®-4]·Ğö©JÃÓaÿ´W‹™üÃŸÏW^q½Œ:ù/Še÷€X'»VÙŠ."Ó¬gÇUvŠS¦Ö¨\ È7·W:iéRå[2dôBrÙˆ6¦PlM»Z|"´3¿¤MDì%qáÅğ@ĞÚk]ÀÊ0"Ä‰XH¹C=ç7mR;..ƒM5‡i12˜¦æù^Ë3)Éªà¬ö³éÆkŒóu„©86çÕ³jãië­ÃiêhÕ,Ö×Éã-*ùÀòWĞ‰uøAÇ#½È¢{Ó½\šúã:û•Œ1[kC†§œÉüŒ`£ì›Ë»Bù’	
˜±FÈ¼ßäG˜)±+—ã6²˜ĞÅĞ¿–û§1Ñ¦S÷¶gŞ†K¤…G“3ùè¦…ŠÉ´Ğéá7Pü´Q!¬nÚ†ã€@ ÿÙœM/ı:lºy¯ñÚ€Ÿ©º‚mË—º26ç´~xiŸã–¡ôÙ©•ò1Öé½gE•tdŸmï8&Ã‡ÊYóŞf5ô¿ãaq¢h×ê1‚%«ñëiXçÆ¸A‘7Fqjğ” jô¤0…NwÈ[–'1ÛÓÚ÷p´\wÆ1|æ[w«ò³ˆYªzD£iÖ¤F”9˜ÍÄÂïâEÃ°å‰º•­Êœtë@cA'„T1ä–ƒ˜0¶U (Ø—3àåşEXgà×šÏ¡u±lÁX®·%"•Z.I¡ÑKÒ­´ÙÏÍw }y|À_­“™OàzğşçjĞ|÷"vøÏâö å†µÔeë„!4F¡F¥×/XqI,zÆ Ùæ¿¥šLOäEsÊå±´)ûÇH„\LA+©~
æEÚõ-HG=;£ÏF\´’r=òß¥I!!:ıìÇàA÷õepìÈ†ïÙß	2GWã“÷Á¾ÔG>¯;ìÌ¡ª£ê›Aä‚<'@ÏU8P˜8=ŞÒµg"4¤`Dzõ¯,>ê-¦÷y	}#Ò³5«şnHA=Îm.˜›Õ ƒ¶`Qyî/M¸Ë5¯‡U€Xù€¸	VI@h¿Ö n¥)
«BV\w wª$¦)è>Bèx(Î"Oó30òI9mrYÃğùm»uŸNx	²†è#È)œËÄ&<¢FMòve(ª êGK€¹øæĞ“Ë^	²¹¥M‚e@|2X«º*ËÃ;öU„Şµ•·$¬gÛ¾äÙ6™ÜHXıˆİöÔ5‚GM;ÁÚ½…ÿwqîÁrÍJpdÍ|i‚±ŸØº¶h´:ì¼Ë(é9	9>Ü’Ó÷‚>Q/?°$~Ñ\^y’ &Ù@ rÆıWÙÆÄ^Ä>ÃĞúÇw•İèíª$ËLÁ×ºyòi£½ğpæ‘êuLÿ/X•¶=4Î¥HzpG=Ûw&*Çf"¤Êi28ôKLÂü½ìO*AXM™Ë>OİüQ˜CsØèñ#—Ã»zM`İb€2œx!™çhÙö«óñ÷.FùÚ8de—³NÕ9Õ¤¦I‘±kk\p ZôÛl­É,j-û*T‡;{ ¬;ƒs’ôÛê"V”cğ1Éa”QZ0¿ÜZ)G¢–h‚™ed#%¶°ú*sBh>IŠ§¶	áb;àé‚^;FR¦ê„Q•»[°T†¢ú“\V¨„‡ørÇ/fÀ?}K/Â´[J7Â'./pÉˆew#$5â!]ƒùVÍô_Íİ¥5'›?c86@vax]ïšpÔ…?ƒŒÈÅ·“P±<9#ÂÇİÌä¦·èKï:Ğ?«ËÁGb…¥nDWëğˆµÿzcô 8ª;ŸŸwÙÎÄã±m_øòOú^÷>D'¿Övı&œU}pÕ W´ˆ]ÆB$ĞvH<QümLÆ©	›0 £h;²ö¬Û}40Ú¯`:…cH—îØâ•”Kæú»)MáäQ †5‰QİĞû^îc×fŠÿ¦òò+ Õ%swHÃèû‘?ü“jô&¸{a"½şû/,õÆªy7U()¿ÌZ»Bù*Z
I+# Uô(>Á”§È¦ÿ²´ô·ä¼Åô?“Ç<±–ã³‹ßEÂn¼ZSF—<Ğª Ä®Í?2ô>˜ÑãÎ#thï‘ÌÇ­mEæRÊ¶~mÇÂ,^“Q‹J‹^ËF$™­:t8«t×¢=‡å7d}œ"xİ÷ø’ZÈº|ìµV‡tpe‹K!Zøğ¯½«ê!§Ëq†ÊŒ¥¢ù÷W‘¦ÃƒDò›ø%ûœG® fÉsu.ı½}MôØóQKÆÃÛ€Ší ‘¥èÚ4ØR­j‡åöE³š©m‚=êĞ¬ğµÿ›\µ6?|vi^ã©T skùQBLCZM\M˜ri¢OC½íâñÖd‰.[áİØ ‰¦…5PËØÖš×t}Äét¶\$õ5Ëİò´ %æ¤#¹ï	Åïîô ½†“LO9ê36+óëÒ’]ë-ğz ®—zúAé\LêH¡g”@&D`Êûª«ì&b¶–væä³›T”.J˜r×ÁÌR/h×/ôC:´Ç-×B»€-&këÎ,¸qš/ÕS–³ì)ÖW(MËaó|9dĞ‹ÄTBË×(‚“Sš«ØîÃô¬œNuÏŞˆæt‰Ñ÷ë2C1<¼Õ¢TzhCÆŒª¤f,aÌ}f8K®1Ê ‚/¹>p·ÔÈ2Päd‰ŒÌû¶hÏMñ­-¦>,b¯IÉh3à‚”¤wÈq¦µ‡£gœ9qo´Ãø´k1ÃÇÓ÷V«È:+Ê‚¾|ë®–j¡ÁN‚CRô¼§•÷J—7…W	ôÍS'@¯Ñ¶ºPğ4†»»¿â¿"¹a±)€ƒ˜ÈL{&üAÌÁQ¦ñOslöÿŒÂ^	«qr²V,D?HÎLÁ_œ4º$Piª@gWk´İvMCFæÀZsß‹”.Sw¶E+Ë)Èu”õ¶Æ²È·ø0ÀU×İù4‡ú©¤‹†}¨úóSZßıkÓb ·‘»š®-ÅUyr›`˜?=£+òMÔiÀhÉøáê}ã‹
şô
W`Ãù,ƒŒ°¨­9¯4­xÿ“¦-Â.Qà––¹7æ“+“ÄÍş˜\búz€ßá%}4åÖ'°BœÒZ¶ì~1Ü¥íI˜²edãÄ«Éœ`aÔ¹F>lÍ¸£?8íı‹@Úpşf<‘ü {Í{<ÚÉGeaûŸ›5ã™‰í-'ó@yvyº¢ÓâÚ°åò	o}:\QŞ›±öµ£1ŠX i«=/'F|eW¶¼ì9i‹µÖvøÊ,ÿ–éWâ—L:[$7»â{	y‘ø™¨«Ã/~[Àµ÷36ÊVâé›G¼â4kÍô7EšS«‚öe-%!ñâgSg$Í7{Q¡œ·û{—1¾N¢fê‰ßRC=œ$qÀ¶2ÜaÈ$+^?¿ÎÄAàıƒ}¨Ü5hSìƒgõ¾İiY'ıóE¦X)*±71ø4C%ÂxkßØ|ße­„Ùr7­#ì¹@æ<|·xF­i¸záó”LE†GzqUâ–äLºô®İø4Mc¥([şª€Ã=SõÑ#~öZĞs¥„.Õz›¾®_/ßAÁºqƒtÅ½|Èå¢NÎy€—ª.3É 8û]"K4yå¸Ç²m+y¹D/cò$n_r<ŒY¶M&Âm~ 9P6§¥*Ùı<˜’úÑÅB©h&U¾ÊYåLpõ´­r5¤¶ ÔÍË¤³ñ{I™š¯Mƒªo!UH™­¢Š÷w³D\Eİl‚¯¿¿U'¬4Wò÷k^9<C5…L\Ôl¹HKÂä·ßE>½éh-Jr3×Ñ Ådp{ğ4ÿ€†RUÓúãQ× 0éËŞô%­Î«æÔaœ:˜B:÷­)d‰BN£Ö?\¼‘ˆ54"†ş/dPãXVºtkô¸c	†'aÆèéö¾ª¥ôØ£¹:;ãê(½AûÀÎ†ü–kÏ3?ÊÃf<è»ìßêir+Oƒ’× 7Wƒ›­bå”ÀåË:àB0ÖfÇZ#O]Äïse °"PÈÎD³_¹Mºƒ´Y!?¢¿ÂØYnŸ LœCbä+½í‹Œğ*ßÙÁOZ%ÜÍ]¢†ÆØe˜FÀ·…f‚%3HÚ/kVã=İ@­3hhñ“ö½’öÎŞÍl>ŒØƒVå4ÏÛ€=A…K**ş&ıò½>ƒ'(ª7Šõ¥É…‘e´mğè»¬9&i	ƒï8İ%ÏÖ€ÎöÉ2xœe_Š¿üËA8Ìè­®ş,î÷ç¥TêKİÏ^ã¿Ø L­RJ3Ã«ƒ£wHv-5ŠNØröº_Ä„¨ßdœ6Å%…x²¯54”~u“ª”ú“^WµÍ½55\Rj †e5÷kwšAÍç/³¸ë¯†^q¾‡„5ü2$´¡½ÂIí­Óµi!ƒ€ˆ/©şıÁù4Ê¼©Ê[q–§Ñ=¡Ïn“v-¸ÊØ¥šbFÏ)–†¶†,sª=Ã…î¬ßEÒa1‚t¢ÇÂšÄÚQ²MÀ3S ´şç!ÖZD!ÜZ.S—äÔ]…:‰Z
ÿºÿµm…»_òçü=Ïï)ÅoÄSè¤˜fj™İ°úùôMÕ/Q˜ç×\²p¢ó%½"[­`4:ÂQÖ=—1ElWY…›®…F°/ºğTrLè½sÎ–•Óş^qÌ—Ñ[Dìy	TYÃ×?åœ	Wu ı,³]	Ú±éEHk‰øÎÚxe…Ùj(jûmi?ı×W%O6„y_káh`Ñ«êÖ´+ÚújÔ7ır­â|ôƒûi2Gj`ª»¢Åvleß öèT Gf×{"dqÄïëvã¹&ù›Ì•S}iò¬ü«!ÿ6ü¥ê¨("*†¬.ü›Ò›·é†íŠ!\0Wz¨	ÙO<Q^SC2ÍôÏ¶5ŠK‡!²rBÛ³_kiˆv¤ğ¡ÕGÒƒwò”,½SÅ†20A©î¢˜Tq³T÷,^Õ½$d'z±ëé¢‡RGãS›LáÏ$òV]);ÓÜ6çÑR›Â†¥ëùø·Øq×»pééíh®@KËğ`<BïÌ;×ÆÿrŠR)˜Ì1æğFÍµEo„QĞBXfPœPJEñ¿òzAş2–ù=¬>£h=o*é$,¾Iz€üî+	w§ş´møğ+’„ÌŒK˜—qˆŞº@ãÆŸå×¨“ú`¹ä.ËÙŠ^'’½ŒlÒjûu¦Û6Ö4ØÇVì¦şbˆq],ê@ìŸiUtšv+4mİfAÎ¤†… l¶iºŒ[$ûÏÖËHh[ÓgÒİ)€‡¢ª\Š¯éCòT”ş| zş¹ì_©H}î„¶^%ˆÿp	îVeËîq÷ÒF‹M‹ŸÓ9øSæ‚â™{ä
Ûy4	È„ºˆÌ—ËK¡¯VDv@Ê|@üòÀŞMŸ´]¢xZü8‘:¿„!\ww È$b|@v«âSÔyâ“ŒDùzM"’ãZDíÔ	CEëÌ¯)ûqÈ“Æ¿)°û ~êË—¶DÔy÷Ã²Øà×øSOl|»ˆí5 ~uàbîáv€-?#›Óìı…ìdLŞ±¼HJÔ[<“Ö#S7«£ÍBÊôœÀ³Eš(0i@¢ò¢&»X€"Zü½ŒL¡£KÉOOG;©k= æ¯À2—Ö†í‰n1yá*²OÅi¤ºÖ?8Kp#[s«½º»bb£şóuRëÊŸu¬ŠQ©É–XCfkùS‰õ,ãjF˜Ç¼r^ÍR¡Äì‹CvM!qœ1VJ"AüŠ‹wX?
§›HsB—éÓ5*5 ğÈI—ß,ö\b_µ!„³Ü4]@¶¼,(qègf°'±÷z%.ºeç'k¼Æ(S÷èŞW{5!Q9hÉÁÚ©H˜ÃÍÕş—)Ya)¬ôWKzàëB×÷hY&õXñÍ1P¢)\QÃƒO‡hëœõ™ÚáHŒ\Há#L-Ö.æ×'FãM²dØùEƒŒüj£¸NÜU‰_ü¬Eñ1€_çî‰tfEbÛiÓ²ë¯Cª—7áÏ6‰X¬²õkÛMÊ”ñ9Vø|d­É’ó’—”Xz}º±à2éĞÒ¾Aœˆ²±XÅãº%»Mn•m?Q#*ô4µÚ÷1E&¦YØ}¸Ÿ1z¢ŠW¾2€tĞãA	¿qÄ†²¦èB‹4²s³nğ"+¡<}Hñ5Ñ—/'å<hYÇ;ÈSb#TgHd)ş·XJH¨Ùoù‹>ĞªËßà™{K÷‰J"L‰*nÇÍÏB
¬R†SéÛ?Q¶Ú3$ñ QğvõYÉ“t9aı„öj€æ[ì²Ríó“<¥@¬*‹ğÕe@¬GïILy?®o“‰¼¿F9#üï÷í2Á	òbó˜ÛNÚ¿Rî”¨	s
|³¡HVÌóàB&§øæfäˆ¡µa	§Â‚‘å$x6mã\ÙÑ‰rİªõ(©8P¨_«í+'x­%óŞŠ%“5½
üíK )ßuªˆgÔ’fi‚<ş½€¬¡52ÀÊ>'L8	2Â&»i7Öã§¡Õæ¶¥`AÓŠHßéÆIÈİ“ Z±Óv^IÎx!ÜÓ7©•mc¡JÛ¥‹@øåfÁ½Ôœ&Ù°Ìßñú°ÌÔ'éR¬ÙHÖÿª°+_(|(×0Ò<²wGp­îšX_³Š8-“Oº‡7¾Do%º{Şf`µÅ©’ÔÓôéœôæ¸S©€£"y$¿Úk‚ó¿øYQŠ~†(y¾>ªÂ1Ô£Z<¶,¢Lr›pş&ûíuM†uuˆ\%;2¼§¼4ñfßêqút_œÏ:‡Ç{$bJC£˜W“G`_b¦¤!¾³¬Øœ¿*hÕhSq\ùóği~?’ÍÅ	äÔÀÒ+™tI0BÉq¿ø»˜£F#L"Y!"¼İÎZbø¾ÎBf'±aT¬$PÏªà†m.k#Ï¯~BÁÉ•b'Šm	WÅ“ìiuùøNjùôÏ¥Efş¶Øˆ#/BÎISÚÕ‹™¯S:píÜ?Ï…m§8–±Ü#ªîÅÙ-–±=E/Çn‰7!ˆQ©Ok{OßBBà‹“9ŒYÚKt?Ïbîe	Q{Ğ˜Š#rš*Ü#­_.3ï¡—â c‰ùÿ¼<bèF¤âºİnN©‘mïJ{7’,Å»dŒ`MÚğC£×äãÅ$Ù,­¸´~;]ˆ:C/O‡ƒŸ}Ö3¬Õk	¦¾N¸¯Éì"}'wövçIÌîƒvzŞ²—1â>:"Ø vÂäÛ=GÍãNX¶h·¼İzÉ³‰Â¥°CÑ­5.È²ë©ÚÊI×[,»‡‘úÄ†D\¦|Â3NiéWÂyÎ•l,FGû
ÂÏ³©3é”&ÅÖ²U¦êYÕœ!©©¬ê+ú7ˆNnôÉ]eZû¹ÔíóëÜÓDªø*Lyñt$2r5¥²“ÿ"ÈûÛG¢Áe
ñC@¤Juô\åByfû=‰êŸn:õ=Ìii˜0&8[s2@¬ ?±Z×’bbÉô˜]ŒQ)ZÉ…6k‰JUË­§xüøşæàK˜}È¤;TÔtE©»À?É¨W÷jÛ¢²"ìšÁÄé5ÿí":‚ŠßSÏïQ[Ïìbzÿt]›¦Ú¬—µY/êúgQd&bLÍSG2ó¨©ş²™şÎlNü å\BÊ‚5"C&Nİá·ˆ£™ä|r’1F}§ªˆsx¸ ÖÓ@Qú$ôFÒé
©°Ä$¦›~ÎĞ¬-Í—-R$Ç!¨¿K2dóµúEîÏ{ğÅğñè’e-Tè\¦´Øÿü˜<ÉÀ…$ö\ö¬éGõó±zËj!,¸¡Ó"È½Xv³*¿Ì2Ú'çEK+8†ğWø#õ'.+l@(^ªm¹O_oárük4t›è]û…9ÇC€Ÿ2G\.vúNş¡©Ò—+•ŞDZo(€İ3;Xß‹’uŒÛ‹&º;¨õw;'QRW™„Û«ºìò—uû±´oMÏÛÈQ‚<›’Öáğ9„2¦w®ÏBs«Àmá/``éª/u_"Ù5v ¼ìsR›æ8¥LÃ½ç¥=İƒßñô÷àP>ŸFVZÕËË†öŒiÏêrğƒi”ïçµÜ´L–%û|–ÍYhÈ7]XŠÜi—4hW¤ìñ€Å“«M¿ğBİŸÚ5È¢Nj˜Sä¨‹I´G.H zIVÌÈøuZˆS¦Fd=”¶jRxÆH%ıW”Óµ$9Qó_}šü8Q©ñK‰ûƒ&Œ:ïÊ±«'BØ,ãY¬}2zxÁ
zléšUh‰ã5êá5Å^3fı­ö'Şâ:^Ü3{dÎT%zŒzh°Ë«3”måÄ‚ÂÜNÑ"q¥”ëW,É÷_CîX¸³oÁ6`2U‡7ÈMİ’o£CA qíĞÌ¹ş—!4C¶f¶\IZÎŸPÄØ”ƒ»ï=/«ÒJ{ºªÎ,7í=7¥¨4uÎhS•ûŒ¹<ÊÃÏ‰G$¹şhéK¼_B¸äaˆ×S*ÌÕY¼ÿÇg¤…'©O0Óç íô$œÁJ¡Bb–_Šr(&Üd¼Èë7ynßfŸÚyø
üà.~ˆÇhßóÊ‹lbÊ7Â‹`ÇuØ)¹ ˆm=t/ßpÜ…D1eKíê/iÚOZÙº0©’»|S_ê¯o	Âô`Ù|íÖ7n²AÎ.hdPÌE
ş»ı‰ÆXïìŞÌ:îF[•ÿä X%ˆğN"Ÿºå?TÔIùÍCg‡ñ|=´6‰Ü>fq§ºßÁÅÇxè ~xñĞ–éBÀéR(´9Ja6S‡$ˆÂùâ%•QÊrîÎw#ZêWq÷iZQ€Í¹­—^™9gû83­ã^²‚Ô½Bw=S5äTé\ş·°¿“”æ·ø"òD«	àP§z,Yi’©ôm¤^Ù ç#~@vÓ%9ÇäœÏ®”Ú{{dr¤h`jHİäÑöİ…H«>ïoòÀ&Ü—7ÅC®h’Ğÿdûğà…!„&1@ğ5D;_4û~µ <ç¿‰^ø zECùºe!¯v\ñ‰>©æÀ×“ôCUíG‘Ÿ>D™¼wnœ|Ş°l÷y•<ğ:&È§ÎÑy=qVÕD°sÓR«9©¿ ü_¹,ï.x—`!;TQ§O&2 j
]mÀ¨šì+Ë1´TÌÂy¬Hà¡2÷”<¨æ+`Òâ¥qƒ‘ÇãYIdËuÀeŠSOBYbô¢Åü^Úİ~ı4Ïy=%ä©.O~wWmï»­T«nSª¸{Êê](Ì‚Ë¡„$RİÙ]’Ğˆ­‚isİ’¹3íß4.@È×ùïÆaXû4EÖ_P£°'a¹GSÍJQ®\ˆ›Yk’Î•rë€»¹ÁÃ,Ø–P$¼8ÊIÇòK=Y£ï°¶ßë—··Q¸•Â6[ĞÕº*}”²QL¾ìƒõ{5Ÿï‹5¦~’ˆx7'$yÎaxÖ>¢Í²ÏÜÓ?ï€b2P/A{|Õ„j†¿uÙóX×ÀüH"‹‘ /a˜‹åwoÓÇÔè’
ƒ‡~ùYÌ/e­ €ÈÌT¾°g§‰PbÁ[.ø¡‹tïP;;¯ÏG£xè7bøìïÔï@'$¤ø}§lIf6ÿ€•I‚3Àü|»qºK#yùå!_WûçIÓNRüùi’‘ø cKzò}.¾ÃØjœÁOT%ë\PÔí3Êhn-«xcMjÛnkì´´Ô\å¿l)…ûšŒÉı¨n WyÏ~€ÈöæàôÌ`L$Zdh=$ D§;…ìØò©hêìãoĞ˜/lÁ‘=† yĞ.‘ÄÌÏ'LèSãy/6_È? µ'«ôeÀG*“ËzØ.I=â)Ö¦<óC[ÿRûN;ëÅ¢şpÄ&0©ö|>Ç_p±vÜ‡[¶Bˆ  “r§ş{0ßû‰¦ZÒG¼}úÛÔz‰ğSèi€¢Ô£”?fJÕ<)±L]ÕÌ@pÃ¸uÊúWªˆ–ZAè¤É cwS¸•Ñ-Q<9Á©«¢êa½!‡Ã»ó à…f…
®ÔÀÆöpÉ¬Zñ÷üä:1ÆˆŠ÷JúæÏEãd„ĞQaázˆÛ¿¾ĞÊÇş¾~t0·İ®ÁùüşØ)Vêé mH5ïLìç;_¦ü²÷MÊÒVJSğw‹É5(XK1ÓİéìNMiœQ»M@À7:şÔÂ#ÛX›ìz1N+¦	GŠÙZNèé:äà-Ñõg(ğÅºzšĞ†Ö¦œÛ•™H-•¬2NaÔdÛHu€ËğµêaÇÇ9äûªiÃÎÛ-Y¬-×ı/quoõ4eB,%ò—&ı:5Q€t•Zı¼è/2È2wŒÒàúœñ-Gã€…UÔ0ñH=Q1"ƒÑzd^:ògæÎ©{êxqR_ÚAPÇ­ël&Ëá!+…ä¿ï§æ€W±Q‘Ç¡.ñØ¡Ş‰¦Î+‡.‚Jğ·ee"K<Åk^·SL«peB€aÅr~óÀUj4÷ŒÍ\í+Vó@QPÄ€”Ì½Âfè$1B‚˜¢Öí@â@°a³ùşÒo  må»ãqÄ¢=gÁz;d¼¯ì´œ5±_:°œÊë!‡ÏXsÑùûZoü+{i’†ÃlY•»ŸÚø”3/P-Æ„kºm—éùs·èì§Î£1öÚ.o­( è¸<ÁÍ2 +Ã\Èt®Ô6Uu^İŠa+‚qGâÏ4à&Ù–å—GäüWèx$¶œ*òzÑVìµî®Œtöé–¿ÜÊ:Á[#
ß±ÎêƒÁ…ïFAp·”²bŒVg‡/_úœóÎ*nóYÛÎŞYÁ*Ş·?]i˜í=«$X]Ñ9WºšOÖ~à=|ûé0uV18c–t1˜cšFæFH²eÈJöoÍ9Lß˜¥3³Ÿ{3q¯e„–z©ÊB¢äq‚Ş}J'57ÕpõÉq 8¬Ş~ŸT›z¡Ye~÷uÙ„!˜ğ´7íÏüÂñôv*®¬Z¯Á)ÈüVı¾õZmî+‹ı®(mÒBp8ëÿÎ³ÇdöÜ«Ïšwâ:Ãr:íYUöö„óÜŸUù7á54¬çş¼£ä/:|~€“ÿFó@,òõsŸR¯(.Qª£•¬ûPDwèòBşä`¨Ût±‚„‡¾\ñ¹£OpA<ÆJ<DìÇ“Otí5úÌ™øÀ&Ø¢7×”ıè>>˜œèòV,ê±£U‡ùÀ6ó6a¥é%j×»ì	LT^È`à|±æÄV{U oÓ#¹?¡7-t¿Å}³RàÓT¾ÿ·8I©Ohçnä——–ZeLˆ¤Úp^–\qa§—ÔÍ˜¾ı^3¤­a=ÍkŞæWŸ[N5‘…µRæñı×îÒÿnnİ§Sì xkšy#Æ•™H¤—mŞ¦‘zCË³ï]6«cFLíé²~Y#}:Så‚èÇù1f,N6¬“Ö• îÒ,5pNĞ¸Ï‚6Ù)-÷5´éØní¶jjÙ3Ğù…Ï‡ªPB´ÂK*š+ÍKö_-Yiñ@D”A{‚rM$“°+¨0;BòŠ'EÊGB<»vUUR¬AÈf„ Ï‡{Kê‹®Ã1!Q}WL=÷¢êdÈ³²>Çö­i7Å‚VºÊ@%ò´úWB”ëóÔ”«”x—¢>>„riŠ>0H R…Õ)ü6×T¨üñIß‚ÒÎuï€9ş›–(2vT-Ëşt˜lÁò§ƒå›ŞÈE|ƒ¤3F|lFß@û”ô´âıöçÚÄüĞÃî›6: 1`ü~[ïdÜ°?kqgN%5º¼ÑD–>BA€wwY?ÑR×7Ro‹WfS¶\‘ÈI¸
æ1ìáÄš´pãÕQ Nq= ¿€w}}xM"êå}6ctn¥-~!ocV89 ¼	Î;_ë3¡yUp6oÖæ•q$Ú]há¾§»1.&)\VÀ„‡İÅV§ÔˆµÇñ¨;¢—WÍ&j×¹[“ñFE½tıU7!:¶)ã3å¥J˜ª†.‰˜üŞLK;ıßÜŞWã²ÃšMİ§ «¯"ƒÈ?à¼6DV¸§KÖÔ®ÿ«…§…£€¡÷]ğ…ó!QYèíîaçQÜz°f÷€°Öx%ñûNUj ˜ô*¾<•Æ•³ùuË°ÇdöÜŠ¿‹ –ÜÔs×š5mP:¹á“”C~h†¡%"ÌíùÅhÑA4E¤¸©¢AÖ?ZXJĞÑ¶*Cqe@dUÚó‹õ'öû¯AáR30jÂî¯D‹jPUŸq¨V2uØm´dë-{ú+ ø“¯½òÁäÄ~ZÄ* ƒÙ]³÷­­ä§	kÅ=[&Ö…²l¥CŠz¿£ Y‰<Lt/÷–Y–îÇç÷=–(1[IgK…d*]­ÑÇMÉ©a6€Œ«qm.3¶şĞ\&/0îÂí®">“¾Òu@l½ñ
êşKwØJ|1¢¯1_Ò(·Ìu·|Ûi^j4©£ÏĞ¸¯±ßP£U­^˜€[nô+e×Ì|—-­•F"ØŞÏáptåiŞ¡š9JH®¯+D¯\n2)°şƒş˜«Vâ¤„jÒ­‡9Êo%ÉGzf –;L4ÀÒ/5 ·9<E Öù…"±.Í’i¨5VLUer5ÒÊâ¸.(·ßÉ)óï›K•–ÆÊßÿŞş×!&¿À>QA Gwª+jÅ;dÇÌ˜şQĞƒ7G›ùúĞõÎc¯?½ícû¨œã‰ÜÁ–>È`.¢xxOÜrÁ'AÛ”ÛoÉ*’[î×c£òÑ£q%¬Aµl8^+PHÒçLQ´îìRL•¡kp6’DŒü‰ãúÄ–˜¾	îˆäM$yK„îzÃ®zıU®&EşìÒ©è\‘„§sŸY?ñ}è<oC
º&æš‚2õÜşTÈ7íì½ˆD£Q5Êaó>Y9¸|íèlê»%L ºfª33jxB\"o­Z–Š–›¤H\‰ï¦2º˜«§%1P"|úµpìN'}~Üğ±¨.†İu¶}ğøÕ‚\2—QÒn­oÏÛÂV»êæb¤ójºji¦å½;|gô™¨¦ê ÃŞ£1	”6—’O“„D›T–İ2R0Ÿÿ›è>_Q0Ğ¯ %6–UåJ¼Ñ¢$²ça€±/jÉ}¼VøªíÌ–J<ï#éJ¶ş¹Euû¦x’½ïâ#î­ŸÍOtÇŞ2kè`S–ëœzUîÓ3T¼ZÇPıb.Ú¿ºòÕòn~£xúTğNmuúğ%dû"ÈúIÀ7Æå[í'ğ†u ÓÒ¯‡‘z.şö²É¥hĞ5y¥ëÄ0%ÌòÚ“EfQsàÕò“©¯I¡aÇûÅu[7Q£qŒ:W´ğ#k¦ÜH¡ÿ#°ÍU,¼
ùğ;-ù!X;!Ú	‡nœÊÙY‰Ñ×^OÆh ô±ÎâT;Œ¼‰ ‘ïÊ¶€EFÛû1:ZÒ=y¬B˜G5ngÛH}Î€Pºõ¼}.v¢¯í¦ç!ôÂĞ¦Ğ¾%İ6T›^A¶¹Æ~Iİ}å‡á3çÑ´ì¸@,@IÜó~³ÛP—X	TÏ=	ÉËÎ}U¦kÄ0ğ#İe:òëˆÂO“2qş2¯)2[ìÃ¬1âg‘–×Ag*\—˜ckQ±bMÍeN³î¯¥)ÉËY
D«VéÖÉÜM’GÉøi³ïW³~ÖvâÜÎäps:eÂÙJ}/É(íËùmJ"_l_ÃiL”ü½Dà³Å¥‘k/„9+V%Wê~.@<~hfÃî×Gï,‚Tê^ÅÎ\ÁqÚìÅ·¯UmğâGœÉlá:b€‡Zp¿ÕD—E@ÒÿÖ”Š°exÒ£ëM,ÙkZÈ‘kæB×N³ÅçS5kÕ=­íB’?çıè	BY±sœ0%ñV>»?ËxMKHp?îªK™'RB&Ös*)t§&=€ÄVò7˜µĞOÂÑ8-
Åìäé½rÑ=€"¹)‹e´pW{ËM4ºĞ¦G\jbÕO”Jjï˜×cëAz’òP
h?Ù*p¦Wâ‘tAñ
õ÷]Ô§(]¤û™œÀ.lg?½ÔĞ^’èpB›	*ï+¯çÓ³™ãsã@ë…Ht}Ÿáu\!lteC›,õëu,ØV†“·}Pd,¿&®¸ÈOÌÔ4ƒÔ›•K“­Ê»,<Ö,ù3¿zŞ—ÒöéNªbÚ@¥>&¢ŠÃ$*ÜÅƒÈ…Lëüeç0¹Ã&HY0ú}¥Ô	«ªĞ÷$F2ƒlg¬coP)cqŒaZÛ¹T»0/Qİ1Š™ûoÕnã÷?¥%CMÄ°<‚“Bt*evñÁÎáD1²4Âµ5&Æ§y÷;!7ÊãİÂ\“È<á„hş»µ™7”P°²ŸÁdØà¿bÛ·b†§b²ü1h|tXÆ0ØC[2WŸœ¹ÆM£ıÿBÃ;(Aæ¦G–Ï&ro'™À+8¢å7m1gjvÜşó·Æ¤òœ7Cé¶º?ĞäëÔ)‰á—•1_›à¿ÆÔi´³‹~~Šş|ì%¾–ƒ›QÚîèqr5sô•Bz+sïmH·ÌœÉT@öÁûöƒ7ü¦ÑšÌZóDĞ¥j'Æğ´0éhNçK•
º\ ¬ñgÒ(Çrt·G5a·±FõVõ<+úJıól;§Ù!ÒçuµÈC;Jç–A]®h×øcÖ¥›ÅÛ{'RÀ§İÕµBWœÀÆ-Õ†è¦x3®Ş,&Üòì1í¨,fT—´!…É›”$‡x+JS^Úó­U“Éœ¹äÒEQ˜‚XZÓRLsáú5Sîı ]×KzÚbfİí©æa/ÎúoÎ
"hÙÿ|Åš‚»ñè}
„#ì™ÈÌ…Å¡··Øï©« –‰>‘óz"èc–ÂÍ¹K•œnM¨Ëò»åõÏ	áÇ,BY¶*l¦«RœÁp™–‹cR!J§åÖµ€ƒ[`…¬ q`Â$©jÔt­4*—}ƒ&GãÍÿqŒ®^Ji:Ÿ¥ÊÃ2$C×ªÎô4ËRX¿µ¸¬½ ».üª g}âÅ„à}búæømY=  ùƒ 0í£òy‹ëZv¢EÅ&AÆ­ÀI8“ÊæĞ“}ËÄ¾ â>•<İù…ºävúlnUQ¾ªĞUÙš¾#.8IvñïVáÃ4¢ wXËgçøV¥KZxz®uTÒĞèİMŒ~&ç+=0œR!Á–	õ,í<åz¥B•X†t"Ò/4êEm È†E£ğd!èN‚U$|±äIu¿FÊ0_WúˆF²h  %µßEë`x‡¹Ñs-a˜,æ7Çpâ`ü{ Z$F¾¤=S7¿CÊ;¯….€FÊa:¾IËk
0% qğùä@òÙ0{ÓÁôíÛÑt_ˆ)àïU›ÊT0¿¢×¦ºä6R€t?ÃËŞ8åIîCÿ<sÇ§¦~rpäfXÈÄuıÄOnß÷ş¼ÇìH:Éyœğú¹Ù"}³i»Pƒ÷ßCC<ìcçĞbd#Úr
Îj].`[Ö‰Uú‡xw„â½:ÀóîcÊæe®t‚¶[÷c‹Ô¶VÚâQ™ õìQ—Ğº3ì}¡ñ^­¨ñ+z°›y¶„¦ş´%üİÈÎ«dËyx&¹£‘ò˜ÑËå–ŞxÓÊ£ÊcYLBÕIwgRæow¡?>Š
é~÷xI_<]¼äíØ<FîªÀ>IÌş3$MıÜJ]bJ±æ)ru$rA{—[£jï,åp#˜GHÈ`!F±ûÁòw×Ê*ó	AßTí]58üıË=3,şgg2‘‹¦èlô×÷àĞı>ó¨ç1@³ïD€u…k5¯ìĞTÈÂØ^„İûWÛïÒí?YXË	›épåKË¾`€úçÆ7çé/Ûm,¢ĞÕâÌzÔÓc;=úp™Ag
Oõ§*‹¿nµÆï,wKàt„ÛJ!«¤m€çøÄë9C5ÌÈÿKb¹ 'A	z|Ï™äPı]Ô[ª—Y:§Eæ82`‡¦à›€g×7<şİP~¯Ã„k6…¾Q~şß~Å0uæ+-]v»…'ĞšD™•|¬}Îü¿#ÎâÚiKÿ‘ô©kVİ)6†Uy«—c¸ W/8µVèÓ~ÓòN‡§#FICŒÖ35kn±$Š@e­æmeá•Ì	g£„ñ&Èz¿Ü9F¶8¦‡KÄÖzo!~UÊa“×(©Ù¤ç»rÖY†¥/Zg³´Ì2×ÍšlS7}«iÄ>ÇûØ8R,³ó•xõÈ°×Sy“©Ëß‰§ŒE×¿˜^ëd2åCEÇ¸Wm3“4²DEÈvş<«TßæsV™[	ñ¡™ĞFŠ€¦û™å ,>W@şw™ÖVÃ/¨2„T%ï$ÚO\YÁş¯}`[Ÿ]WÇöCù%5Ü IûnçÏ/Ö˜éušst)‰¯ã÷hçº½^¬'åMkËº	Ò¸éÕY†Ä•c)zÁÊu!æÅÔÅR \¥Y+É|ùÆÎûa\ÁªÃîGI«9ı„<ÅvZ…¥l†]PB²m&8‚v$•¡¿OØ8µ}€½¸ò‚t§ƒ±g3H$×øy–¶BÁ/l’¸¾ˆjaÌäyd[‚ïñõÊÏÊ~×Óë×qµçÂ^{¤ê^’aÅæÔbŒ=0ÅŠáıù15có/B¬y:?È¢ÓßŒc/ClŸÃ°.tå¿e¹Æá_q¶<leáq|Ú‡˜î•¨ı+¼zçúãzC×êè1°¤ †¶Ï—Âïâ¸şß€	&_×-n­Àâgfƒ ©£ıKˆÈìÍ\ÙÑs lä´ò›[ª©FĞé,ØnüW!cmÌÃ¾·®äÊkÅßàvÆÙ¹)ÏTcMÔãŞƒ’êP=ä¶Z—d™W|g]Ææaéãœ[¸z-(Œ£ùõ÷âZ hj¶Jce+`³v¬ÍÒi;|£rÍ×¸ñ‹aM‹×EH9`8ÃŸg‹rõ2ˆ(c	qŒ®ˆêRPp*¢÷ËèşÏS£õS4’”¼ƒµ/Ö >-<4sÅ1ÜáÚ:-Ï‡ëúG(Œ°uü´ÛëmÅÏ¢m$áiÍÓİEO!››jÙ?ÅôçŞ°’ß¡Ë‡2¸Ro}>€h8É	R1¨¼¾âò”Ú‹î´­•t’EIß×­¶ñU{#ËfÃxç]VÆ%:XÔbªÃÊMV†5mw·ô{¨é^Äz 86/é½,Wº[‹àî´½	h¨Dwà]Yaj™à’Q'áQ7«Â’HAOK˜bgHá]Áx?¥4>²îµ–œ[N[kêA7XKåè[Šª–ç&M¨°™ÆgÄ!€É„ô.|Ø›nX9ÏİĞËr¦¨{¶4Czõ,ø«!+%xRv;r‡[¾Sıâ'ø×"+tŒ–uXø/¸[Ô]ª+œ*ô ü¬ñïi¬Ø›ŠxâööYG&r÷±0ä&:1ˆ¾7ñÄlE‹¯‚tV±J`ÊÄ{ÌT’06èlêt”qÔ[Ê;CöÊ!i·vÀÏœVù¥ÌÓ€¼QØ¶hw^SoGÎ>,úCöB˜ÿ31£'Å¦º_âÌ˜rª#Ú‹iæ!½	jãŞôü¿d7Í]®7YŸ9#¸¤òB¤ªI»|õJu„­¦&]šnÀtÚgY/0w‡Ç"&“éhÕã¤0·Èøpš¢£™QÏ6«),N”½ıIS
uÀHS,s²µ_ÆĞ§ˆ”pö™ÔSÑÑ-š"'²°IRòß?÷…çóƒ:*ã¼Ò	( #•Ê1èRÿd?o.J"*1ĞÃ‰óî”¹Ñ)ÅT8q	”Eäù™«÷¼)°¾Ô³<ràMôh¡Â¾óÆ•7x%šOô…R=¶"Ï9‘˜#ÀÌ^a­Å‚RDêY dk¾yN4bøæ¦?äæòDòœÇŠ¬¡ÄRød"PiC^:Â¾w=<ˆ«5•yï´uà	…ËN’àvlà¤cy\+=]à,ª2-zñ<†ÿ]„Ù³vYM!–ˆ3‚«Ä]×CvâÁ(ÆÛÂÂÈJÒl‚ˆÙ_!B×¸iå]ê¾RM•pW„iÂ¾Ñ†ıöã(‚à1¿ÕÛM­.SKì<®“ÜÅÙjl®‘®‹µz-oÙ¦(è’eÅ	”^ÃnEÛÙ}
p×,7<9¡œ²»q³føÄ±½¾ó¬p4f¥9Ç!›"jÇFqOË¥‚$ŒÛ×Å#î#ñl×÷²zœ…o6—RŒğw•	ª•°[4gW‡ŞuÈfk¨ş¥û*k,[½VóÉàhÌP@É®½;¦ãñ£\5®EY»ó–«kåd:ñ½èE‚i„ˆwAæxsm›UoÇÒÔ²9‘Ñp×ìÀ?ò—É…JYl“ıÂjp¢îuoºµtïÑç8­äì1âó_Ç]ÌkJWÁ’ºØ“F’‰]d
ËòPŞ¤†…t{^ONêæ+x·ED,ı6–á8Øô€ÕW¬hxÁ‘9êcV®±Z¹Fe†Sñ+‚‡Œ¦³£“Èê8¡W#NOÈ(JâéMgç£§$ôµ™âº‹*teló;G¦Bˆ¨'ş(Ëä›´‰ÿ?©‡åfºä=… •³Y×³6èYo6Ã-KİôN¿Šd®Ôû%[‰ä$¼ æaâ¼õşÓÿ,Gk 
KÄÏÕ¯Ÿlq”ÇÔä–xÉ½À¥÷á#ß³àîğÉY9Ou3¹%¨Ö[Âä[frhÖ—šuŠÅ—›KÓÚ tp	ÅòÚÛ\4v	º]—¹øûTÆyİ¼Ù¤[YaŒoÑ°J"^0šs¢zÙ:–Ù»eËQƒ9`¶(wL®,?6±Á'ÅÔ6İò„¨¾‚_˜X‡İŸ°–-•^Ü‹„’`,Ku:¦¬KĞ¿u…oa Ä•`4>Dªd×˜2à÷ºÎ>	¢×¯ŠÉWŞœ\Ñïz‘µ¼kLËky
rœ<QòãG÷¹ÎLR†¬òÖ4x	Úèßàü©F÷şMã‹™ìû×¾CiàHUzrT&r[z^xKqùzÏq|CÒW„ÆC»ßôµÎôõaOÄ;@|êà1´¬b®îj?ğ¨ªçÎºÚ"È16£hÒúØbış[şVÄ®®iK®Bï|ŠİYGıÚîß9ÕÏ¶,!(ûwÌòµtP²İFüËèÓ…¬ÑÒe_ìİG°·|’0ö^íõ8"‡Îşê¸‚Œ“ ¦ï‰›XŞ+×ÀcœĞúPÄÒ–[²èÅËıh IùóÁ>ˆ3‘©<“xîJCâ‹»ªîlwÖ¼´ü‘e±@¤¿Á«Ì‚Á¸•<eà†T\Œ
’‰‰ú^7³İˆQAmèı¬÷˜c¡]H”¦CÚ.ˆFpÍIÍú™šä˜\´‡c¿/7£¥Ó~é£ïãyÉİø´l?í0Ú™¹ËœŸ~ë~¹’êó¬ãçE`ì¿cl+·^wnPôWhŠB-ã¢~‘C~Ñ€ÿˆá*æx¨ƒ“A/é.&K.ş×‡îÎÃãâNG´°ˆ`ŒEA¶Êh›1¼ÃZ%ñLİOyè€ÿSOí¿Ñª¹à–ìŞNğã;×—-EdE©õŠ¦C!›^õ2ş™¿ø¿y–.Q.<æxÓNhJ\2"|_é“±—o™ƒ©å&=Åè”È+¶İÙ•ÏO­Ø±„ğ¬_¿Üí°†ê‹˜ÍDzx€?Ó§û<›Eµœd†ÂA_'’ÀåwÏØ×ß=ZğØ¦Z8)åÏs^böÌhîÑ½9X<PßÑ'«ø“I¬ƒ„WÜiƒ¤×ĞáTÉKØ¯=b­Q/ÖãªkHõ°½6Ğ\Ùu¸i*T‰l`çˆ{t©İc°>J÷g!¯…7Ò
ŒË‰ö¶;~3*‹ñ–_†—j´ª 2<kß$t./u<ˆ.Í#|Adàlá½ğ¸²·djÓø¢ÙÂüÊ“µ^#‹†ÎDó3ÑS[Ùû‹ü	bÇ!LÄÎkåDí›§{dÃ€1ÂNc$ëÈŠc6½Î¥)kTh'¦³áy3•…Ø§r3‹`I|9ÜOq`›’ºı¡RÚ"Çüõ×,ÄÈDÿÁÿè…E6D ›·7`TŸİñ!Ú@7””›éTm·\œ?|”" ÀüÓj“AH÷@;gb˜å…2šŠß«îû¬åVÌDïQC¾‚‹<VH®=;×“€¤NzÊüUæ¾—ßÓvZ‹)fûwD}°$B×Ï´}ŠKß•—zÒ¨îşXkpßƒÏTòû¸oÌe†°AÄæ4€Äøeëş„ö©6DVOî%‘z]¼i
(Bİ8õÙäÜÉhr¾J¾òa)'äÃ30^.¡ûZ?Q+ÕZ—ê(ByÈd/:â¶T]¿ë_oáH¤0
~?ašŒ£IWÅc˜”…‹ıç nÒ1iåP;ºéPM6¦”É—6PîºQÔİ/!yÙ;6Û‹¦Õ÷un†éè‡ ØÊM÷6qR³nNŒÿ8ìµûˆ¹^ÔƒlŸ°6#j¥»1ÇŸB³÷…° Áb~¨–˜Ì²HuSé˜qìØ×h=Ú4Ü<=2zÌæ³õUºÕ¿ÑaÄ%Úl3}cQöJñ¶ÛeÍ¹gŠ©Ø°ië¿€ùGµÎc>wä5I¶4NŠG¶Ô°Ş¦¹tV:Òlj©n˜1$÷	šô¢ië<>š+€{’Êêáh±
îÍÊ,ğ<¸9u|K?
ÚÕ±èšz97kºÿ^{íÈóƒV¼Ğ}÷çÖ“1éF’ 8ßrKaKbHÕŒÛòjÂÁ¿›y„ ¸Ñšÿ^?î²ÍŞ9x\5îÊWCÍÏÇ«Õ <=h6€°ô¤•Î»03_lå©Ì5è=‹eı‹M¹]h€3ƒ?àô“ÙMÏ¦?’Yä‰ÁÅ<Ñ±ÓşqİIŸB7kl¯ÅP-9Y«|™vgË  :iëuª4 Û™ÌŞ6%¥¤
ó8SÑ«ö¦€Ûîs’.úógñõÿc÷¤€§ÿ:¨‚˜ø¦Ùòœ6*B³3ƒĞ£ÚÉ“«7ƒØ…ÿ™¹’ªùCADju¿é!+ädyÏŞ;ïË|'ÉƒLøäºK´@—õVìÏÑÈ/ _â
ÑBs±şëÕŠ
w>WER4u¸¥n03‡%›oûíHv•ìÓe:,Àå8¾7¦‹å`˜êª`s]Iì;©uMÑ¹ö¹@.zkß¹:5Ğ
’ÙY%¦ŒÑu^÷š÷”@æ¦µ<´ğ0_+co©\-Ìùd«±µr²ß´|GÑÖ¼®ÃÕ82U6Ë›=gã˜7”š2Ù JœŞ¶nAi	Ñ tH6GıŒ+û0uè³¥¸ÚÖl;ã¿ySı+.Ö3µµTb8“*²§íâësÓ‘Î³/ÆyÉ$ã†4œª¡zæÊ7¼çk•¥Â›iaQµëoæpbÙ¢“øá€ÏÒ÷2Õ E5ÿIs«µ†V-ğ"ñËXç‡_Üd`®ù“°ÚLè’ Š?dÀäMãi=ê^ªêŠ±ƒNîB ğ­ŠL2‰ÿë3±.Pläñ°bÛË"~WÏòüÈ¯qaç&·YÚºŠ²ÔNöÚ=¾rtú¸YØZk§ÔÉ6dPp|ß³şÇ®Ş6ÆJ c»e€µâºIò¸ûÑ; x9œ»‡aD7Üæ G¤õ¹ø’e/%	FO8ïÈ¯í–™-«‚Ÿ½`œµÛ ß ğs¡qN£´ıî¼D]1…*ÇR¢öŸâÁæƒ±’URóúV‹µÛˆJàµÔSe—*Ã§½€ç"á7«İ!™ÓÓÂm§ä?!c÷~»™Ï?D[ $ÈÎDë$Bh³2§±lT ¥Æœ«No†ã–l–@ÓÔ½—ŞI~!
Ï_-ì¾y¦ ‚0¶‚-àCÿ7v%)ÔAÈ=úœşRF!‡íÛåtĞî\A#ıPáM)ú‹«o±ÜÌ²&É}!È8|ÛEz¯ ¦À¬p‰ß;UIFâŒttY·–î)™­eúK!áe§}”,a~Î}DyJ‚ÖŸ'ÿ¤æd/ãÌÚûLéy?Z”V!Ç…7D;•D$èG›,uŞrË$åxx4„´bJå¸åñd˜`+7Ò†2Š0ªŒmÎóúIĞÂ{ÙìRàea Á:XöØë†i^tİK]Ù‰(Ú$"ÕŸ³HNĞiZÚıiZÉô.+±¥»VÎXB3ö2sƒœŸÂgo÷7[şÈcë”»)Ñöà¨hÕİ¦¯êĞ? e%í>á”5¤Ùmk–¶wp³Ô¿ ¯XÎYÒTÑuÍˆóäKS<×Dò‘Dä¡Å›Ö¶-]û°ÓP¦oÕ= òè9…â+4@ê¨ièÄze7˜aÑüT–§b1Bÿ2ÿ&­z©/à›ñœÖ7¨TPzrœG§ÿ,=Àœé²>3ÄEB‘æ˜¿#ÊøY1we„À˜GË#`ìºAQh"“â”üš‘ûƒDgÿ]”è	*BûSeç©‡R´Õ…i·ßdÈÌ«ãò+îÛŸÔb…ë}âÊpUÚXÛu¿äSnìN¬”ÚØŠ õB¢´\"q¥mú¼?»%È¡é%CgA”o½.“qnQÑäŒÂÉ~û” §è»$f¬”[Á<¤Ó7Ğ^*Ò)‡­1×wÊ(k¨2Ïñßwö'qcvBkE_›gÕjtmœRN^¯@2?éì[q¼m’J=Vºé€9¦7ˆh£sÚ:ßñ
¦WXUE¼¨æñ>q±.éToÓSùÆºãÙĞQå›»Y2ô¿@ÿìÇ%D=ğ»oüª¡ã
ßcGºä8••šâ÷û ñqô×»!+ÍQˆ,8¯ÖŸmu}°IOŒa±ôÚFÑ&u®ç3Fò¡õïÑÃÎÂ¤xÛ+m}„|Ø¾¯ÁÛÈÔ;@ê¡EÊòz^·956géV<“„PáÑ‡¨ÏpPŒç,aÔ#…6o	&Qt; ß‚€¿cÏªC¥ë’ê¼jÜ/îG¦›ˆØû¡P|–%òºô³)YÏv2|
b×ğ47MôyÕ±}û%®¹GşçÛ‘F–èş¤ß8ĞHo½ÆNj–ßßİ"«W@y€.8`»ø•º0zâŸ“(®E•ÔSzMh·tós5³cEw/6Œ×­¥Àğ‰V™4,L'¿b8k÷÷Zâ¦‰­%İ®ï@–`HÉêÔ‘°˜¬
º¿A?ö	§ aõaubDQ2)=%Üß84ã}•`Ë^=‰Šz|ÑÊy…{‚@¼’ÔÈ÷MÜ{¢ ;j‰"*'ÏÕTJ@ˆ8æh] ),	šfTÕÇxâRàŸ	#×´¯ã4[óÛ Índ?`İ9*ìQĞğîmá°vsE3¶fëµaÉ÷ãíîZ‰a¸€ÛºoSjlYPößŒ¢·öÅgÕ
™æ”Ü9.üæÎÍö^ÍÍ¤óş&Ğéı{Àz4]Ô×#cŸ—°»ºQäÒíB"N¾	ñÅZXü×2æÂ,“#º,ÓÚ¶?ZĞÂ¹éqš^Ó´ÜÓ›¼jâ«,—®4ò¦àÁ\ëßÔ·Zv ñQa„l1£Õr6áBŠÏò4*Ìé¾»ÿÅçŞ†ê ÈwÄ`ËÖĞBp¦—pE]õÿ×Ãá‰³¤a[Ê§€±e–TÅ^P	CUÏåD¼eQ¦Éc
øro¥CÆJĞ"›F/·¥2>›'C65-ÏğæeÕr¨HÁ•ŒrÓ±ábşmDã¹zOóJ!î65¬¬ÛoÄ#hî÷&°DÁGµ°m½ÎåêŠô×Ó«¤¨°4¢Xw¨P€‡>Öºñ>§4“½t4ï\Wñ­4dÒõ&ry³‰}IÂŸ¢7r»G«›EóäŒ¡kyäº‹nî&1HŞ:§Awßòş_º~ßßº\¨[æŞÆ/Q0D&§æc¹¦ëN…ı;²8w‘»AŒ=-gÆm§)HëëMÒy¹¯ôìN¥bû›Z³9ÜÃ­ïBüâ'¦ÎÛM¥%áFİE©ËL‚Úùª½k·êÌÿÖĞØxy‰U±à`m;‘e“¿±ÌJ.ì>y.ºD²™d4‡*•JÔ;ñ(ˆs¢HïYòn·Pd€5ùà£åy|•4Ò<j#Ãš4kÅÒ³jëØ7&ìPŠı2¾Ùh‰Û³ÍìÓıUFd«#èâ-{àyùàüsîû\ş3ù|¢sÑQs¡Şs(»å]–…G¥lï//ÿ<hñ9í¨Ó½ÃeYı®4@ú«¾T]EÜ´ñh×PYõp€hM\eFoÏĞ³ÃN <ŸM®5Â*7»Ü
~iŒW,Õ[¥Që±½2»¨úäS“lÑ¶hz×šr7$z¿çû·ı3¯‰W…#Kºn‡Ş¡ï5Yg§%,T4.a£r)4ƒ;9NJÖ¾qí]ì{+?WURƒïßlÉ½®Œ¿Ï„ãöÜs‡&‘2Ú¡Ş€‡U.ñˆnYºÒâ0Œš@îcŸnÁ·}8*/æÏ_î0l{0ã…òD1¸4 L’ª•èÆ'V-IúòåkHŸ´K÷R¸ŸhhHeà6‘N,4‹ƒ(S2t/m¿twk˜Ì‡PXÄÜ#¤ĞD>>À‹0œº;'ÿ*lP§s
Ì€›—°jÿbN‹{7®›
ÎOäkYŒîwÈWâÑfÃ7_F3$P•†²C2«8Û?rïÎÅÌ	Rÿ°®5«6W·ÔSğòõË£úƒ·g_Bê˜{‚3U„Oì—ùJÀ‘ÊàÄb/ Ë@æB­zu94j¢Y8ÄÌ+ó¦X›'ŞcŠpÙó0R*[B˜§GéºãŒıû7›4%Éf2ÈœÍK®Ò*h‰&î©ºGú
×úÉ÷ô ‰æ|“ìDg+‹§[}yjüK NY½¤)<hš+fõµìŒ) ïÏD7|1¤mĞõ1ŒÜEj^ÛÆæµWCTZòŞE"_šãaævO*ÌøÙšÌ+ªy(õöºş ÷ıï÷Xê£Ö¹Ë(†Ë÷LH)xÖXƒVòVå31cNÑ?–jªÎ¥ ôqD®Í-¿;Ş5!E.SÙ«ˆ¤Ü]¬4l^L19˜?£òO¿RÈÈrÌ@šiÛh   Ša5rïnT[ ç·€Àëäf±Ägû    YZ