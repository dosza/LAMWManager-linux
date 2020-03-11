#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1726317309"
MD5="df919110b72f0898e61dc7f8fbac2273"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20812"
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
	echo Uncompressed size: 136 KB
	echo Compression: xz
	echo Date of packaging: Wed Mar 11 13:59:39 -03 2020
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
	echo OLDUSIZE=136
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
	MS_Printf "About to extract 136 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 136; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (136 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáÿQ] ¼}•ÀJFœÄÿ.»á_j©×úççIŸOåö"Pu’Â—¸Òš^ø2Vr‘‚ó8JÈ³UòÜy’íÅØ¬Ûè˜É:cB9Ğ¹Ît‚›o§c›H¢bĞ®¬¦î§LMêÇÙ>RP‚Aá>u0,›¶„7C}Ê¡0=<&&É¾Šj/¸ôów^,mDAué€Ú+ûßı÷W‰ùyÊòi€È×½_D¼Ã"M_!zxP$$dïwêæb†![ÛDì‘s ? Cã2oS?\ÇÈê(ßóÍ_ŸQ=Ëì€Ï$—k) ]…ôˆ=y¡ËÕú~*w I=¤íØkŞ¯áØŠl
Kğô›Š¿„à˜Ş¢z“ÜÚùßc"9—‰vSœ>}ñ¢Û±·.ôc¿…;¸§‘¯š[µ¯CE65ˆùÎVÂ•’" j¸•’Æì
 K¬¶ÈÕh’²ıİ
£‘//
æÉ°Q5Šu ŠOıìÇ×ÉÒÇ„Ï¼ë"ŒÅÙi2ê´ï~¸äÕ=jw›eñÈmC[Kçô’ki%}ù¹ëcKŒ¯ío©™ı5½ÂDÔÍ”«Ï˜Ù“5PÎP‰SÆ¡+%‚åuMš€“ÑÙfíØÔ—*)ºà›–›3€Bw'’ÜÖÇìDI¶hnğ†”ôÔA·Ds±ş®ÌñM0WRı‘ÚÌÃÙTÈ¹¢Â,b	M½Ï9¶F¬p	¤
XOŠY!®_æ*¿ñ‘Z–ÆôY´fqZqI²¡üLş¨³˜gÌ\£¬oxÉv†Ãœo:‘ûê1(Äx¯jıÙˆÊŞ@Á´•Rıã”ÂÄ‹İÅ/& 0pœ;ÑñÍ¯,?M»Øy6¤š¿Ë¨ÀGŞ\ÄMHtş(J¼]<?>ñyP:™WCg¾tÎŠe r’£ûûK‚HÇ(¾ÜÇAR« ¾¤ıÇêçç¶fX±ôÍeS÷+&àõáy"¥Q	¤.ü$¶_€¿æ´|`,ò¡‡GRĞİàkÃ›bÕƒ'aÛwÎ`7³ËG64„#é½€e´Š©>´3Á~qÆÜµ³`Ì8®Kgq°Šš@Ú8<GpÎù‹ı³˜³dû<†²l÷©·½mhPS˜VQm69Ô¨ùën«ìdÌŠF‰ÎŞ‘˜?eª2äô'îN;ºÜ²32ù„knv±kj¨”ÿ§”,0I!¯IMAÉna
ï/OAºÛ8F?Ä`ğÔÎù
 3Ê¡&‘#œ:y c!¶Ô³+]Òe¡b¾èûŞcâŒBÍÔƒ‰(È	<V<cêj Jy!;È½ı»Ä%ğ8Ğ·–<âjj›3ïÑ1…æhlzäğO|ü7ÅMıx#uÓÇC=â6hk¦ºœxš®¹Y 
L»Ú ğÙ\ìS"’*p×DÑø™Zb;Ï‡>ÎEå0G`Å³½,_ƒdS¾ÏÚª½¼`(«.p [û•c=Tƒ]àÛÒTw»¥ÔÅ‰’ĞJ4Ù‚¶>ÅAÑ´M¨âC¾¡ãÍx	JµY^¯²Œ|@T„rÜ/‡&¹p–9$oÎx×š@ù¿ÆÃ"vhK* ıãªWT‰\¢¸T énÒX¦ëccÍº.W›GQ†{&—–ä—yŠù^ˆ	&[UfÇŸlÑ×Ÿ)…èã?\{¬¢"f?À~.v EC¥Æìxè¨ëUÄ¥vh?ò'¿ãçòÊUÇ;šDëJ‚áİi•¨»™7jT½é%¸™&¹f‹°ä}B¦‘úg‰QO…,´æ%UÁows¦ôîa8Ñ3ÓºùnáïsŸ6¥ÛZğIé¦JhP~¬Sı¯‘ÊåÄ]õ·ÏŞxòdbËkŞ_ÔRÁàá¥•“F‹mÂ™]÷¤qüÍUÇ,Û“‚ÙÃB¶V´÷vç3Cs+e,.cÜ)k4fònò¶©’«`ZëŞ½¯D¤^ÀÃ-rÚ×÷­dëú=£_±k°-R±Š¶<ŠmíÔqg®'¹ÄŸ’˜EÔÈÎğzV;c†ĞD¥9vİŞÕx8€=’ãz"%h!$T*è†bìÛr{ÌQªˆ n¦gŒ®Ç3ªaù‡›2¢üg†õ%¦‰ì-8ˆš“˜‘&tÅ_«.¼îs°µºt;f¢‘SÇ¦¹QqEõÃ‹nhü…Éÿ
’@Ñ_¸%ë†§”ªf;n}
Zj»Ì¬»~ù»ãiW±ÚÍÿ,Ã¶@ãÆÍ§É# lO~ìµøÒ‡á˜_½RWt0æƒ6[÷ÕÓßNe®èkÁ~>°Ñ‘äÚC–éŞfWÖW¯feávÕ¨–º¶ô»úÈ,áÆ¨¹ò`êhx‰»•§R$[;®MÖq6xß ôcUtfSíúU†5ñ˜¨B+ ‹ FàL:³ES¦"J$—iv»ÑÀ¦æ»Ş#+Mh¥pL•B—Içòñ=ZAd<6GC±ïNø{İãŒÆè'ºYÇ"—‘k0ç¿·P*Gleò}:iÀÆ†n‘{”%Àº–İ?*qQ®¸áf•ÎªÂ‘hÊCÀoÍŒYÊ¶Ş=tÎD\j(KÛuú»;]Ù²Ë&ìw§y%«ÊÅ¡²Ç1dÙÖ¦Qæ
ŒSëÉĞ§œ¿s‘^ø*Âûxjp©çS"áĞ‚üÚ÷BC T¯kºá¯ƒlò†¯©–Ş!øû*nòTŸ“&T¾ş÷v«Y¦-3}ÿ§ÅCå˜çŸ ²b`Jv~jJš†™!Àõ/„ÈÊ‚Ì20±)‘ú~pTµtRÍüMJ±ÖıÓ1ı±\íî/á¼ê« c×¶a¿.çR’< ÒŒ&~øZ9ü³K4«Wñ©Í!¿Õ’Ø Êƒtû{Ã¬±'¦*üG^¶î¯/õˆnÓ©0öä}_İèçè[XnÖRª¹×gK2¾ô7zä"¡4êN=¢LÂV#»œ^²şôQ/Df†ƒ÷©'«lÁF¶¡éØSoıx%îÜ)C»û2æÕæ†¯¿ÅÏÎ¦ûà†‚u-SÙ‰Sç(0n%`ÀH%êLş`—ªL®ÕÚÏëè5÷ZØƒuŸ$æ2ê,b¬†Sı°“ğíølÃ”Zò|¾ë_1T™¸Ö4æÕ?Ói”ãmR(WK6ÎCıÂ–ù0i‰üX aÜ©óã””..x>{7Ê¢hiO¹D÷íıAm<‚0vˆwÖ›¾h?èßèqõ¬#|ã%Pj	€™…¨”eÃ‰ˆ~*[½Å…2¹ÍÊüöwaÙtÂ`êC›ªrşiéó»À]B{ÂîÜ>¨¹d*<‘ç¨Eÿ~V?¤»ÊÈ­Q¯¨«3/*í7eÙõöOñz‘sü|@†0ÕÃ™ÕX“dß¶f¤d%RvR ú/Tš+' ú7ÅæÜjt(Í²Ú;„Q}›İß»EäĞİõ}5Ğ™ñÖí€Öä7ÜJˆ\~!¾ø÷œ°K`Hñ® 5³P+A’^‡2Cò"¬­:@ª^$ğ	D=g‹>ù–=Cº9—éú63‚ÚæÒu»¸‰úÛ¥ŞË¦çD-Pû¿¨¨nš^wì†£uQ‰¿Q´ÛÙÿn-øs—
Ä%x²Ğ5Ş›‰Qí;²BáÓ¸Ê÷nŸÍ+é¿·í9çjÃÑŸî]¼Á;ñ±X´ğ1)-0ÊœX”Ó}=;pƒÿ‰»m¥hOmÇJ=·}Ÿ‚4‡©£I¡$A³Óç§®ˆ?e{€÷çÍcw¡ıÚÁ>è«uëX›¸iJ$+ªì"V[å¸ã»ï‘†4Œ¼<)Öa«2¶^M¨Õoº	ı+¹ö‚p—â¿jì<·ì+ İ´Kê¡_9SmÉ¡ùjIœÌıŒg[(Fª/L-""£Á
$QWäÔ0¢X£1Ãñu´Ÿ0ºÒlsJãü$mÉ¿8"-l¸£âK6–\ vMgºö‹¯…µĞb¤Š FœŞR´í½èp”q;¸fú$ÃgŠªŒ¹Çz`«¶Tm(ÂÈ0‹³”xeŞ¶Ÿt€=©ÿŠZ&Š:Ëšª(Î}Òàî÷,—xœÁ şÎÂj"9H^ÿßuÉåÌ;RxØWŒ¯–{°(m6»(­xqÓ}mscé(a&å5§?ôÎËÇÒ±iˆôN/Ïy;Z›JÒsõ[E%Z1R%T=Şqu/×í%÷âÅQëç¹wÿÎl£W¢¿ñ‚sQ:Ìä€›S,è?–ú¦Ò9¼ì{*)•¶J?J+Xo8ï°ˆB4Pø²8Ó±ûÛ´íÿrÀ¨b×jÈİ–ri¢(ïH”x	Î¾.À†âQçŠ¤4Æ+l^È‹ø°%S¯í‘«pïÛûRÃv ®d¸\Èì™æ3tvI5’®õ5ûXµ/øÁÇãİ9êcd„§éÄ'NFQ5ˆu3pÒæånŞ³2‰ñ-D6/»†,P>ùuA–¡Ş(2G?Ô"ş`XÀ¹sD†¼q˜åî+ljb¦î3ëÏµs¨}ø´j@¢\Nm=È¡íy‰éon¦5=§ÆÖCQí´Ñ‚P}¨Ùê7²«¬Úq>1ÖˆJÑc:( Îº"P(,ö–~šlÍepyÑsáF‚ßØ-,W(Ç\5ªşGX ANÜã¶îÀ·<øâqí­ms{
ğ†ÏF,à7ôâg‚ïY”V">H‚‚T»$)½n² ±?Ş~šóŞ?©KEÓs$öşAé·‚Ê9İ$W]†8İäv¬ìÆg¦5–âLíp¸±•¡Í.))h‚èÉœè8Fl	¨Ëû¼‘1¼-€ãX4)¡§y^û°ùÚ«D˜…–òİ&ÀçÚÿ’ù—b…l{ĞşÙàWH»YAl·›Äà!Záú|ğûj½è“ò°°€u„à˜¸Äô G(À·>¤ØáÍŒàRŞ?úè™}LD.ŒZxØPxô†¢í>)œnOÏÊïË… E”$rDXÇ¹2!şôcÜ½êÒúŞĞUi7½Õ€¶¡;°CÇí')uôìeâÏ²ªä´ÍZÓ4×W¼âÔ‰/xÔMªşyüS‰¢m¢Y –HT[ıı™ûC<
5­‹
7Ò‘úÁ~;®FËæü?Ïó“Ï°2”Ü²@ıöñ<EÑ4ŞS0
Zµ%
›vmëâT-—jew1p¤á	ë›AYäó¦°1‹IÚ³‚&ˆMfImJÖY|5İˆ·âÅU¢Îëe‘Ğˆ¡óæ½ù[ã§'š[úZÇggèóéğ×.ÉK":	7:¢Í×Õ—YóWe0†Hde­Z!RsÎhøs^Î9¶Zk	”%IªÙÖià%Ô½‹ .ÖûHôÏtì‰B7£æW		^ÜÜIÔ]ôĞí¶œò×U@ˆ$Êô—ãşÉB¸îY:8D§”37[n7´ôC#ª­³¢âk
Pk¨Y°ÊŒ‘ë<)‚ ÎlÕ«¯9-õõ¹ÍRæµÓ3ÍÕK¿ 'WñÙ‚25é>’8²jš/k÷¶MÙÂ©Ç'VFôx *l×.hJ~Ó†Œl¶[øtÁä:ËP$¹Ä[@ *2-ÁfùM›Ä›ÇXCğlË‚ßÂ´bè."±Œ¯iÚœàCÂNaIGúØ{¿°şëÚ¤ø0?	épgÔàcímæ¼F‚Ä¨ÖÙ¹^÷îÑˆ6»‡m¶³øĞÄ¬ïF¡]µ¬ûÕª¹ ºEW}ä×Vÿ»óĞ„ )f,Iv=ØmâN„d¿¸	b+F?èâ5 uÓÊ%ÚÄ%kKs‰Èg™ã>”Ğç«U^}ß"ïiˆ16ï£„ìC ÷&Èí¤n&DTÓ´ö)eÏsáœ%6`2Q~	.3¬«Âí…^%Ñq‘æàxÙß¬ÊM@NÕVšîÍá’’˜Uú7¦H,Ş@±­ZdMrÙä1>›ä;…öl“4aÄÑjãkP·îXT¬8NŒq§Yb%	*Azå½:iœˆxüc@Ç$ª t‹¤Şµ°f—÷ë%f¼ü÷Õ[¬sÑÄ5W<Ú’;çˆÁÃº(<ÿ2 Õ,­Úİho€,…;0y’œË9¡,+1tÂ§ÑÃtÍş,ÅÒÑåN#$„ÏâAûRÜFÅØ*&‰±Å¿')Ï’§8@ój­şáô&Ræ8c²F\)*—ù›lD#6b}{g$	ˆåÿaÍ°‹á×ó•`ìS®†íÕ ”Ş¼‘Éº?Ëâåd9Ïì´±ğ?‚ƒ~Ó?sOè´ğè’öm|äÃÂl´(;© m'|2Wßj£•u”5=¦(²ÓDüÆr¶Ëfa‰W‚ÀÔìº9Ê…Bê¸ŠÄÉt”Ç?W_y”çTú9}cÙ@·vkÓJî6Àšó¿—áÒœ>F, íòy‹ãu—Éöï€÷~ßCó±¨’)Îÿc\puş‹ó’}WÂ6ä8-ï°ÒZqP{xiö`ñê`ÚùI¶æ$h½Ÿ¡ ¼Õ‚^UĞ¿ØÌ>¬QåX©áùE©"úxØ8gÈzÌÄ™Cö¬J×áèÃÀt¨Ö‹_¢B\'(êşÁèDmPvä Î¼½IûášÆ:ª™UÍşQÕæˆë‡ ÒÆŠ–£áÕ%ªğ'E¼î<<²ÃrçÜÀå°É{í#"ˆ¢•Ú·Béãu5¢"ìSí©®¬d­eíVË£|ùúnP$¨ïğúã¸D^yô"·ğ[T	Åó$T•øp®Äèï¡¡~—’ú¬×³h6å/@§t	Tg ›²#æ7	EşT,ÍŠ0ÿãÌmèìœ°"Œ’X6Û P%¾4®Ñì!Ä{u”°4&Ï˜»Ó_%lÈÊ‰P6‹d‡ÒO”LúùşqÇ";£:“rLç‡µú\QAAk½óŞ[‹Å¼¹>ãÀÎ¥Ï7Ñ4ÁÇêš‰ŞFxWİŸ¢(4-,VKêˆê¾Á8z}…‰’æiéKJÃ Dr$Aİwzoû©j;ŸKí‰¨a¿¨áj#\·©BZš½TG"w›]EÕ¹	eaAÕÛ}¸9sÒ…«ÃywÁxÏ6®	2°Îş­k€hÛµP¾@–‹B&Q*•?ßú~òI¥$èS¶U¿Î'°¾&5Ïö§ÏÍãbÂÀ¬-à"MãiÑŒp¶Ğšij=šë‘s´IvVÆ4Oh;ƒñ(©“Æ{´)"=Ë°ÊU$¶Cß,«¡õRìÔaêáX2o¤ø·Ğf2Û{7ÿÿ0KP”íèõæÃŠl4ø†Bÿ«Óc:¹S G!£—EŒWwqb=â¢§(0â¢­Mu‹–V5	;ú˜xowœ ÎÛô½b&PäÎú¥ÕÎİX0­ŒˆCU­ °IÃn%2	 ©êœ-¤5§}$
¸e†ÕÖúÅÿ½9˜š±Tg¬àû¢Û–›”QŠ|F‚G‘¯€ü¨§èÈE³:ÀË1ú:LUÙ¢oY'ónÿHÇ•MÀ0+9ÇŞñ®‹fè“jXÁbµ˜–áNõ“Ş†½Ø9Á¿N,Íşq¹-Ë86ê-C°H3GKı$˜ğÉ¿¬©›¸?ÙÑ¨Şv‚6™±%\^[®Ì›é*bÅ/Qg?kkĞÃ…¯Ri(`şéfŞr_ßëÏ¥÷O+‚áL’!>i»ƒ™VÈ±‘ÇGŠn0AI9GÙ­ò%›Èì¸‘EIWFjÜù@‡O÷¥ ¹“Õ®C!¬Ğ¢'OPŠAÆº¡……“ê6:Œœ¤³‡˜ÇCÙÆ0â\ãaº<NÛÔÖºiæ,V
:Uk'Œš¤°Øqa Iå®Ú–ÂiÊ¬')¥ü—“á¤Ë´(é–=ÁèúÕıTŠÔÄ ñ ¤¼ƒbAƒûÄGM%Ô•}ÀÚ¹k¼RƒqsØ°L‘çI™ÁæógAn=2Òî¸—´’»¯¤9mË|k¸¦<|ĞÉİ}•´PSñ“z4t'kÖ•TşĞ#A+lÏA åÁœWïmœÅµ&•ñ:H’6ë,"õ‰Â?
»|¶2X9˜Q9^7Ú¥3µ1ÎáGı:m¢|eÇe÷ƒ*‚Ir½‘¿çn]¯$âª‡kg'fÿìÑO÷Ú
|‰t¢›¹dÉW¤PõË-3˜KR€f‹·ĞÎƒT}#Æõ/Ñ46µ/š:©DÛÕ$
éEı¼
Î”ĞÁ|7^¹y`M¥¯5ğˆ«ï[+B©>£şsÙ+Ø¶àuU‰Á}y»:c²,¸Z °‰8ˆÉQ÷'¦ÖH‡ÄmuOaÊœ9“˜e9”®›È{G¸‘½¨„Óté¥7H ,ù‰H/…&Ò>TfB^J’ç
‡qÖøë	¶w~Y^Àìk˜mIc¦ß{Ã(Ön®@†*6¡UJ.<65Æ£:zÚŠG!´#é¶K¶™8- à÷Aå¡•¦€vßæÔğ‡™añ×Õ¬ÌRøsé1Öı÷h<Ş˜&b•()œÃFIíşb”í}>r‡Êl0ë°·;6œWìÍÔÀä9'?öŸ<úDöğ2p¼ îÿ™¸Z³.ã0™¦)d4ı˜íZ(à¤¬†ûÅ;øs÷üRØŞóõ— eê×C¿úÎZÉwŠ\ÙùÈ´µ8šÒE‹^ŞqõÙ^ˆXTS=•fÃw‘h!ÃéfÛiE¬(ÃğˆÃ*’šÑ‚ªç®4åÎtĞaAñPäØJİŒ‡0Ln#jË5ôE&‘ö^ÄˆN×-Uî¢–ÕS)İÍË¢öĞæ`‡KíNDÁ–7í9z´÷ª×Âk«A½{€e’r÷ÎÎRC0­õµIÛ%6Æ3æ½LÿìhN>àHßg<Ôıøkƒ-*°^åE'éw	Em ÏpUè‹ÜipæpsáÒI•ÿæ
Ò.­ ÍÏÒ,@Ñ¦‘•÷»]¡zƒğ87[·€ÑØÊu[}OÙºr76|8Ãî¦ªû¦‚ôuHÂ$IvLìmq7’{†—¤ëçTWßÔ·»$Tª£àr¦Zd|  óãçØ‹8¼Š¦;v¦"M	±.êšyç(ÒeÆF~GbÚ“Ì_Z(osÇ¯ÿ>©½!MÛÿ£¼^BÒåÀôŞ9®üb>[¥ÁÒ“¢äX{*İc*KUCğh‡76@t@Æi2¢¢y¦‡G6„ƒt´6´iPO¡cxïÙÜù]Ä†R®~_­è,Ç¾›a»·34aÎ¥/ĞŸ$?kgC´.ºR¤¾r÷r\,8GF0â‡«Ñ#ø7S ÄJ»‡óëg‘ <¦wÃ^îØ¯Ò_+GÏx¬¹wgs*Íxl¾®b…¤˜?LÒPU.·SõÜu‹#£éÙ6Û|}¼“—£ï¯­ÊAZfL‡ÃÍB¬ 3oÑ¯«|‚ò%*e\^;È®#8Tåù…d÷…"¢EÔ‡sfob`,`©çØŠ™£h¿cß‚ô¿„OdÖ$†ÕsœÏ¶ºÇ=X2ÇVÒ”U±•g"n‘ Ğ2ÒÚÖK*
êhA|6–W«ãô	Øøø#î¦¼äe¹±bœŠ•  ‡.J;öü‹¯$Ç8ÿ¿ä•HÛ}.DÔcåa¸Èºq—EÕ<”£#‡bjµ-SJ€D¥èøS±s§"a/œ<Gş¼y<ØØT§>UH2J”ú °…¶‚˜yã ~ ø¯€´k‘ØÅÈ°ø”Ö	ÜÌd_†8öÑ$¢,kì²¿
sí´œiz†1zÉ	>í«‚í-RhCnBÕ€ÑºFY–”PÙ­åN¿ÚşÀå®6û3Õë”­Â’ºËE&0àî-w4ç’‰“Û<^ÛÖÍZô÷Ò&úº²¦¾ÛöâA~gmß¢>Œvz’´R³EtĞVgó±#0+±èŸ¡Çš%ˆ½Êy'’g¸‡ƒ+Ìür½nPÔ²£GØ*¹ÓiXşÓGŸèô˜¦Õ«ZŒdÒÖÀªy'×p]À?ØØÿÜñİ,Ÿ{»¢EçGÒ8~;s
–TM·ÀZ<'¾e.´†hcŠCÉ.©ÌÈ€ êÒº47ä¯›ss‘a¯òØs­Ij}Åc‹P«ÿó²?œŒÈ\ù6'Ê¹pÔ ¬³şòşO|‡uÉ1lår#ö9ë™ÉE>dF‚ZNì‹ÉK]J™H+º:–ıƒí4Jjk$k+eŠCVÉ¤y§˜ÈşäıpÓì!ŸÙ±'n~O9·X³¥r4Î°³è	6ò£3Æ„*½uò±WÁÅQè0”r›¬øñ+%ŒIg'BÓ6¥,Ş\ _#îeKŠ<€û4¡ÃR¸P:Ç,•SyşÁc—Aí-ğ³¾j“Åîi§Rš/Ro‹w’”U«±ãq¹9¼™anaaXkCÚ^Ši1:6T÷HËÖ¬Y”ÎÜ§˜‚„ü»¢ç?ºW'›²ÅºPfÇInÜóıñÇ?c55Èñ@äK¥ÊROºÓv|v•üv¦N u¶XÏDÀZu-Yq)âŠáº»/š³Níhõêwl4gús)Ï.i‰jäöFjÏ†ö@¨ª[Ci]ï½^\>êØÒà }(ÂÖf¦–»‘ö› è©foŠˆÉ3Íùš* ô“xõ8»ÿÁØ¤/šïœ­¹ë¸å·Ÿ—0ü°¼ëÜYZ˜î<\bÉ…yÖáj=©¸å³‡’Ï®ÚÚ%„…‡%}bNìA
^ÿ´Ø0»±V&²öM¦QBÚ“œìUS.É¬çËŸÆŸÌq¥¢;b§mq°N+ZÊ‰X‹µ¦£»Î‡H/Ë€oœ¦
d¦ˆ7DŞ3ˆÇe_±mt‘âX%Í™ıÑGÖQÁ³ò)ÆÍrE}»yRŞ51>à[SÕœ{‡¶&Eİ›Ò¿¸~ay¯
ó6îL	ª±•\UŞx¶^kbN˜•†êc’n‘Dà—–,âZšS)–j¨?™D>ˆ+²’÷Ä[c»ıíã‚—PÄØ6·2õ‡„Ìqíœ9TÏ¹&€˜²"]Ğ—Êdøïx³ğÀÑ;?ÏUİ“ô€Å-}_Q×5p`³¦,™MÈş˜œ­ı,oâV:
şö\  ›g#İYjãßàºiåƒ¬2­6Çbj<©Ä¶’7š0oí6¬Ïvæj‚¨zk4ºñĞÍıUEš0à•¹æ®¥8`–Yd×w=Ââ3Æƒ‚Û$õŸî´­zÀKœl¦r-UA’ó²VĞ!;RâÃ€Öóêr[[÷Ç{ãÍhví/R'Ã”3Æåè‚súäÑ…
«sßè0Zñ}CêYØzëV³1JÕzğãy%ëGáŠŞà»É(…²cªRXÿ-1€M×o}Á¯Ôµ÷4¼¾J
¤¸èôá8Öø®Šàl› ˆIVkXïÎcµ„0¬İœOT
RtÕóZóšf£ˆó3hv_X;¥ëœ îĞ&Æs`§f¥Ëx—>Ú}0N‡zùj4JÔ¾É½d)ÚnÎ#ıP2Xµ\‚„Ğ‰lïk/c˜qš]=(ÙkScğ/x‹ŠIÉcÅñoï‹ !÷dÄÚİİYTxİ°mPœôGÂÙXAp%=GÀ 0 ´êš6Ê[/:ÙÍT-¡b×¥òt°ßcÏIğŒ¨{ªú½î'â¶û'Í•Vx'÷·8±æH!Ïæ#	Ù@/bOÖÈAÆeyîIÄlèÑª 
˜ÚDF9ÜJˆĞ³úÚ{J™+EEÈ<w0CWzEÃsÄ«Øj¯b’û§F-Gä …ÿ®ø¹g·!×öÓiw–¨®à{Nv#m¿ï§®î™„ˆ±¹½±"íıÒ®½ªšäÜv'_[UÊãŸnt,ùÆÙçC4T‹äÛ0FEº>;	gø	Ì9?ÓÒæÆçã—Rh“ßÚ‰˜Ø0o©Ù¤RW'€ŞWy…¬–ûà@äK4	£Œ†Ü¹Ÿ`=@÷-^Y…û–®·›ªĞÄíûı°ÉÛÊ½tv"ĞV¤™\\h½;®­M>j“Î…üÌF[ùµÖ¡Ü·XÖä¾)0Ğ|ùá“<q‰`x^_>–—Ec­úqCÌµç®Z+FéÜ…œäMÅ·>pŸUF¿aC°n²ŠZVıãòå®@R˜‡İ£öÜà»LÓÀ &Ï¦“jğı¨	wwÄtH¤‚$|Š2ªµgşå‡¦­gu“| j÷(Ü:g&¯Q¾œ¿‚—Ş¾¸ØÁ¨PQ*¾ÀœMO¥YŒ$›Ôo1Ç…€Øgı)ù—õİBlJÿ4SY àŠŒ¯¬Ì¨î‰æÄs/œ[ºÆ?0Û™Z?‘â<?zOW¬_%/Ô@ÉÍßb>ï7Ö*ãÇ-D5t”¹ïğNŸE/»zîCÚ©‡°FÎ Ìu=6WT«ë-èÕPkƒJQ 'Œ%´8§¹ªêhWbû Qüøú
¤w;Ã§·Óİ°¦S«¦S••Å¶ˆƒøŠG­–Ï$Ë7³Ûğ‚Jí14ù)ßy#ÕoıCÂÙÔy‡‰)<<#°§€C+	ù)Q¾~`¸:bX£ÖŞ^'ª”=Oä NAô z±°æñ%†¬‰(·ÕˆÆøÛÅEã«®l©ÇÒæŠÄØ±³¬	'×ßuP:ß0ğÒjÈLÑ÷e¦våiÓ#ôïXèaÌ¼NÁ× eeG²-WGÎm]˜D6Fb¤rÄD¼ ş¢LäíÖ´ñÂPú£
3ÒUø}$jC€08ÖÍeù›Årı´=è"Pëp·ÿ›)o ä~¯V¸Übçoİ úµè'ÔåRw±ïAÚ\`Ú!ÂÄb‡&ZÜ¼z2Õªw]V!âÌjXãâNœÉî²ÏÏßérÛÌaRG÷';n×(¼ÈÊuÇ+Ñ¾HQˆ7\Ù:p‘)”6î®uFÂÕ‚ê÷¯z1<[VSã{í"ŞH‘úıƒRà¶]|e[˜³\m”Oğ™ª"°„k lsĞæŠ¥·|¡åÀWÿõDWFœ‚\HlîÃßĞEÆOß=Ôg&C–?©÷²óFMøÎˆ`€Î|s,ÚöW¼yA)LæòB_Pü™gm×”2ğy3.Öì:8rZnçF=]şœÃR–& ông¹ê.~±1öÑìDıêàáŒ_]~ëQ(QI¨ê¹ZšÚ§­ºõ¦¿ùÊ¡ŸËµ¸Dpü	¶AbÈâÇ©8¬Ô§¶»?±;×¿.T†‹Ç´É¯ã<têú\õÃı&JT²Fğ7~XQf6œÕ˜DÀ>ºÏ3ÈP„:¥ËJv±¯Wu:<fqÅ[áU¤Øò]üÀ9¥LŠÉUCÍäá˜n*rTS)*LânÏò°BUYF¬€ƒä¸{Õô#Ékf¶OuÇïİÍl¹6“dCÛ…,¾>vyV6TWİ¥éì£8KQ´ÿ# "B¸+ãkåº¬N®]}È»{BÍ¶}u‚mT®ò¥[xáp¸<ñ(^öç|§W+]ù&—W"Y0š1Qûæ©uÂM	Ó~¢lD<c7L³Šşú†(wsQµ‹Õü:#Æ°–ëpPP¸·ø×Ä,pi&LñMVœŸ#AMå^3€ƒ,}µ5U¦ÄöÊ­¾µ0À“±¨
—‚ÂÕÊĞµˆ$ñÊ±zùÔ¹Oø9g÷¡Ái–> Ö§‹ÌBAªF¢à…~éÈnC2ºñï÷;.ƒ¾wì: NögìK„6fÕw.4É3«§m¸¶Ø[7­"v’í9n§k*l4ÒÒªwZŒã 
Ó½—5µ@¶5±û’l•~¾ŞEş}iDî²–¤[/‡gşoTè êp VÆsÕG3˜¢d·àÔåë
.­ñ8€Õ;­úáÚÇB4®wHa”ïPy8bCÌ÷5OÒ*j¾”c-ò±ò‚IrªÈº½W†±À‘+&˜ÆZåT•dG‚¤#Y %!‚˜Vò/ØQoø½fùıòÀ¿ğ"4È=W%ùÆû›mÓßqJf.´ê/CØîÔ)ÙÇUæQô¦3i&èözqvÿ 5RIè”I¾^Bvœİi6zòtµ
Á‚™.1ŞÃ×ó|†ßìœìiÙr½Ã8H¢F{Ğâ‡2FÒPl¡ZØ6ÊXõë°<:æÂ—Ô7PeÉ6[ß¨†Q³nÜª3<^»‹ëã!ñŠQn„4bVLpô:“×C¡V¦†¤§ÜÁU°g
ıl•†¥Gô·éQˆk`áÒşm!ˆá	¬´ŠµÁ§À7_¿wÌ¤+,+Ş½âdf©j­
íri $êDúvŠkqGiyã/æ 8L¥úQ‰i‰-Ç<EÀ>`yœ‹ºø`M¤äìzŒ°á¶ 7Ãrãèr$l€òpãz§0-BsÑ{ÄøÊ†æ€¬DAƒ½Æ@àFJÍgIÿ.Ş‰ÙìR†.ÄçU(@†+×.s¾/™ÇìÙßŠ¸”¬)õn4ôÉçt“3SßÂl:×,ïNO‰9»è3wËù0iá“í·a~¦iÄX¦Éql¥Œ	 oÂ°+Dƒ²ï8uL0Lùşs§ö¦’J“¢Ç¦4- ¶ı0İ«ç$4¶VÖ¦™¾?L-d	’Vf’‡àïBtsV«êEe“MÛX«GZã?Ò­ª¡Cb„w†æğŸY>¾UT¨bZKùÂ9º×|dÈŒ¥x†,6
½§i¡S&ÂÈzÿ*çºéşÚ±AÖ*‹£UñùWB€q‰Qá—Û
}ôE½Õ‚@@ar¦×¼$Ìw ‡(C/Ğ$cZYXºoíX^:SÿÇ\“ÃHj0ï³°JlKŞÄêß?8Z£_Äşß¶eÃyùò¡ıÑâ|ÚÓIè=¿rv3D¿X%m„¦á¾Çòy:LgÏèÂ1Z´-ö½"ùy÷)Ê²Ø:Ø
Tˆ¹h*d%kŠ¶Òî"›å¦³½–¨Uİa“Ã4R‰EA‰‡î	†ˆ?utó?IR²nüìØ0ËfßÇc)rEYašHµ`’Ñ ¿`pKÁÊ¶”?J‘…öY¹t!Ñƒ`ïU"<"ınRs¶Ç.h_$ÑßD.UO_èÙ’C‹š‡ ?N´O=bväˆ)Æ…|B1¸ ¸Èˆ_	›»ıÚ8%"=ığ*Ş	¡^‰G¯êä®–*N`+ü¦g¡KŞxaô›é/cq%©¬a'C{íŞ"Š¼™"€‹³í={²Å“5Š‹)@‡…©+o/×Í–eQLµ!È†ïŒ®Ü±4¨ÒŠ°æY¦Æ Ï^Ré1g¦Ş€û5èUõÍCk_fÑÙ&Jaqj@F‹İÕeh•Ï%ÍàÜÀÌ Y‰ej=f6Qºtlîf@•c“xÕ¯x K}ËøÀş2ncèÆµ×Ö[~¸…Æ%l”vÏ¿X_$]X——ãnh%6"ªàâéèuú]
4ş¦bÚÙŒ›?aWPÆ±£Ëu½ø~“¶ÂVï g‹¦ *4&6L[¬“aVeQ\R›-älÌ²jg›/ÛJK|x-†.õÕê70ÆˆÔMhº’ò<ûŠ¿ùg}plF;¶¬ï”iÜ!¸eÿeqÛø,SâêIØñuÑ'"²5ç6±²›V³á»{Yõ:/ò8Ëä}§Î}µSzUHªHİ–ähÒ@ŞdÄsßßl’ÂCdx“µâõó<ağ±-ìpÀœ°{®n?ÀW¯u Ö×êÂı±âÎSàÓÎ½•¨oşÍ¥ÀÀÇèŞ?&•èîøÎ¹ïû@²ÌpØ%ß+„ä)HŠ¡ÈÇQfì[ÕevI¦9«¶›iâ1S•õ.šöz$çâÚ©–¥"ÄI¨iHî°`7üCßÑŒà£çRìßö@( œĞ‘•^!¹L"ÉÅ…v^È¡«nD^JúÉqqGzYÀ|5Òâ‚9(ó#_c}Ç™?4_ä&¨š…Å­çıÕÂx“D¨óñ×.Ÿæ·œÍ6E>MC‡ÍC
ä“ÆŒ5ß?û=/ó¸ÒûÊcUs—¶ú[{AJ_=¦£©´Ğy™dYs†Š¢BÈwQ`<Ö¦×‰$"L„5w›½[%pÏÏ˜æ`ídËôÄ†1…”œ‘Ş·ç5ÏeØÊ&¦2ƒìÒ+l$H‡ Òó ûÓBX'ëÀõ<(´ªBêÈî¯y˜ø©ƒYfáÜCÑä0éçî,€rv`¨`ñı,UÀ57È‰± N´ó©wã>]„Štæ25—³eIòåûv­ÑÊ*%‘cMÊ˜rÅ¼÷£w?Ğ8LÊÓ(;€±bi«ï|ú83Û²ûÏ3}ÿ¢&A
pÁ©›&§’O™Klp…oÌ§Fx@…~]’TÙxºrqCmûoö‡êı™Œ&³v/æ=°¨¥¸ojE:.ñ‚c»x¬Â‹‡¬­èÁ0Äù8µ1ìŞ¶ã¥¼ê`òB&j˜…‘#ÄÀR´gÆ"sv|Ó}ódá";2¬I•á^ÂD¾IIz›Õej˜Ğ±Ik¨9VµÑæØ•pd6,£s³g·Ôícwş`Ü­{ %j‘Å†mO(¡‡Ö¬tm×²v+˜Gkºeƒyúˆm¥”›¿PÎL¸±ætl­*NKÁ(‰ÕMZã‘ED'¤êjÌê’ÖãycFšû?ÔºS2×c `Y9Ò~=dWZKXOùûÚè1Â«‚Cìîísd¿‡Ø—Ñ¿è„ÔMåk™(~İ$*šU-À'=âSJÆµ;ŠX†~1•7TŒkÅ-
L%Ô&	Û…HšS¨#&<ÃõÙğÆå;c8Á^%¾¯ÉàÄÈ æú¹;Œ}Ì=´V6?^mkˆl'¾]ìC^èºíw±Ğ[3}D—Ôn‹é¯êò¸ƒÄ´7—¦ªÌcÑ&ü½×˜?%	lA¦—'] KÚÖ÷[]xGigÓk¬ÃeSî¿(¡Ğ·'¬ŸùH²z0„"MäêÈqgAnó4˜oß1°3G	HAy»ÿp»´“´óeJhòÍ"›F'=“›z_Iœ^Ë5‡Ì‚ĞÍ$F«`/üXÿh
W¿0ÙËÏj…n{”á¢½ûoÂ¨	Vp4b2í¿`ü +#f]OÃ5!²=	ß·˜hvòåvûb9Ö¤ªeª7KÙ©&0QË œ<¶%B5‚ÃÏ§€Wé ºnı¬w„…xN×ªåfî–ÌqmB¿*8Â2‡Å½¹„;­Ğ )q®üáPmU±r>áz³ƒÉÀDër4d…Œ‡‰ÌLyÄî’İ™ £<Ïq³ÑÖ8¢ÁÆ…¾}pNëÇbsæÒ,à•‡˜µ°
uÔñXêª^Á½a%YŒì¸à{hS\İÖà†|`
ü=g¹YÔÅ©»”j×u}«4ñ¡›Èõ·<ğ[IûldA7ÿãş{¾ˆº‹2vê­„2}é.wÀœr Âô&Ç•ôñpõ"éå ô¼â·Ñw7÷D3…œ­P1RØ>T0ÁØç_²nF3ñ6²a4À7|i`Öu¸+N*VPNÁAºŸŞ¶H$›¬‰œã‘Ÿf{RÃÅwÜà³ˆ_iu
*‰êçU´t -(ıšC€,u8°ıîŒ	¸'„İN FVäº”üsofÍºm"Vòf‘6©ºÁ!Í$}=­³`˜ÁÍ¤ôûü‡”¯ù †PIÜ9íèô6Œ(yxé{ÒÇJÆÃc¢V‚yã#q™™İ{|ç”BìÀ8°h,Bcû²¦ŒÁ2P#!æŸ¿õ–5˜:d"²??T®}æ8ŠÒ²ÏÇ;‰ÀQÜİT¯3pğUp’ŸâN%U_š¿³ÚLÑ	j±‚„+™L}Z3¢a,7Æ”HÍa?["ùfFuÔ pøEXÂóhşkÙf¡¶Š««a€¸€t)õİËVš6Â3Òàá"›¡a§Ò+PùGyƒFıãÁ×‰ûS‹Š Fiâ±O£ˆÚ{xšX"‡ÄhXîih¸ êˆ“ëåÅşFH'²‚Î‘ô 7sù}"/Ä,‹;Ì7ö~3Ï&(¯.=Cîc56R±‹ïÌë…œıÍ€2è$2·ÔÊ-ıÊPg{Æ³²&§'•ì…µ©Ôßı6äö+9T³Ëv;¶P5™Å¥¼GÀˆ{Œ“ó‘qĞ™Ê¥@›ñ±ı7ê±âYÜ+Wï’^]Õ_µºß!:Ä]ÁTüW}øYZÆ‘?ON6ôÈ°Š§öŠ±
M”V ŞÖR‚Má^ºâEœ:ì „‰]×Ğ+ÒàÑ=ŠwÈÔUÎLPNgë„Í¨¤“±[h%Î”m'39©„şÛSÄğéuÂˆ«Iš»Å#ú€ùFú­Hó9»¿¶"ÎrCk½…‡“ÜH/¤;$/šÿ©ıŸeFh™7¬º‡XâYÉ€Ê±›á„¿á7ôÏ¦0H¬šÙû	i1p¦èJcã0y7ùgÖ<“¼ÿ†·fHæqÆÀ	˜J$ÿ™ø—òÔÙãŒØM>W®_L+³ôÿİ ëTº@L¶-:³ÑjTÿÙ¤²k±‰Í¢…Üõ\ÓT6ó»ô5ÌJyH;Yl¿Xc~“®´Ô¨+ı4•² Œ5/¦‚ó ;J ükÂ%»Îˆ:ê©ôÙ•÷ïğåZ¿v`¿*—\~\ş:}ôe§u—k|Ùngz´Ô˜ùe¨ºRïã´¶b™L›$t	¦ß-îy™›â“°J¸ÃZ\"R&DÏ^;oAæj5í—?+E¸Á7-°óöŞc#Q˜|U¿óiZã›Y[˜{?İí”Û<¤š³;¾ÀqO±ZŠ%bëv›ŒN?Ñãé [€×uıÙ±5“1wsoƒ°c–wáàó¸)¼¦òëA«Í"ÊK"¬ésşÊÏ´b:†¯!ë"*–Tq_F#+¿IÍ…¥
õ„PİµŒ‹'À~ÍŠ´â¤ºÖö»½µÆ¡ÚZj@’Ğ¬É¤\fçéæ~”EV„å®Czšú¶1_Y ¼¥{}úÃl¢¯EÂpç,	¾ìá8vÔõüÁQ®¿%V—åÖn|¶1z“	õÙ‚HÓ~*^Ø$û•!Êè©Ç{BÙª«óœXÖ¤¯³U"Š_LK¯vÌğbY•Šªwm^n´:ÄOÙmÊuà(Ôš‚­ï­lÅõ/Y8ÜuF.Uÿã^r÷5„Ğ$İ1aUkôşe™Ó óå¢%\|P‹vçs4U.« ¯q“ÀÈ`¦XO]Ùç:ˆÎx¿Æå9ş‹IÖe0Eø´æ4)g]Şãj3XE_Ÿ=(Í¨\fÀ>°0_ï÷ş‚V
rŒw£®ãöóŸ{¬'cüİ¨…M’ü£Ôh™{SÛŠÃP#Bø>§¬Ò 1óô>¯°\7f H¢å‰cH4	‡#Uí.“p—›l³Ÿ4»¹·W¢iQŞØq¡´éRµ&åÉ¡ò<ÿÿ±
‰mş<
~)TìI®™*Æh€—íG0NEVN(ûˆÙ¥ü­>UÔÄ€*è!§º \(ãƒºw¢6¨è‘¢NÃè‰ô´i’E¼óD
ÅÒŞ2ˆFÕ–KÛĞPØãH V$Hå¬Ÿf¤pT›z‚F;©Œó‚‡EFç¥zú^¼P€ÃvÇÇ2¼Ÿè"‰&=›bb]“Ôwğ–ì0¯Ù‚¢hú½ÖÓ^¥!0­²}ï³Î4Šb¡áÖ‡F¤—[åwhŸÒF¸
›šB9Ü©Õ/5ßG2›²°¤W’"^¢T¥„)âS°oÄCœ¨
NÊCoºªÚ¯Œ/UUÁ¢¬‘øml…aœF-Ş^kÉcJ¤'t ²8¿Şæ:8ÇÙÛÖY’ã ösÂxfb)HÊõèˆŸ†t#„–ZÃ¯hÿñöŒºÉ '¦Ü»ï¸Ä Öï"vWºş gÉºp1îjıW
àL¹EO†‘ØeuÅ®ûü¿Mj½k~ÍÃG[*lÑÍ1í³„ş!håî}‰µ`:ÃLû:ö}Sá¾~(øİòZØ8èSé®]C\1—iÛÿNZ¸µ¦`aÒX;×ß~œnn ­€±yØğñMÚ+ŞÄenGîz:^	‰&…],õá¸À²e:R©Ì×·nd‹Ó·fİnÎ;²úIêõZ&µ%f&CÚ–«œÇÇ"Gh	;ŠÃA“ÒpŠ´±²Q[kkº†™µF,œV²˜¤ÁçnúKø{§í.¹À•Seb01‰¬òMtºFc=ÌACÑcÂN†~*I½š†íÉqÅÈ·´~'dÜˆª´Êî'2¡êmóÍ[SXDyA[ç7/ôõiØ#™¶nLˆÄÇÉÂ ™‚gqãHÜÕú¿@(yí ¸,îu¶¿~üãéBo+V½+K_¿ÿD¾O4ÔÂU–XÌuÏõTVÉñ5u9sZ%A	£á?£‘i3{=ÏÃ“Åõf”³¬Óºp‘I@4ÈªÇ÷€?Z“?S‹Ò…üT6Ñ¿3NâøÍôW–
n?ğ½Nå›å¡l•Sá[•4 Ã63¹£‘SbPF8|µ¿ıà­Z}²Ëí{Ô†VCA,§öF0¹Ì¦f›éspiÉVì*M&NêQ&a@]'^ç}!%ôe£Ñª4%/oæY~Š;°Ò¯2Ã“[…SC&JîÌ‘6õ|…xß9é0VøIÂ×(£b’IfÎNh^3Á²ğˆ¬D´€¯4À¼N"Aª¨%ËÌ…‚`é©ä	ÿå¸Ÿ§¬ì/âÄ$é,Sóá‚UÎˆeÜ.ß(İ,ü?¾õÉZ¬”½R’Oš"g¨½0}à;%¦ÆŠ½H„y–œô2ú[Ì2ÈI¹gë*"AólÚRï	&´"uÊŠr	ËËM†Í+v¥VÜ4.ø?fú¥c—ÒHæ¾Î /w!Ì/v¦Ù«QwZPKs·\"NÅ÷é…¡Ò})…ğÿ~bÇÍşwjNt6ÅšÂ.Z~‘EĞû¿ZšTĞ5q@±¯Ğée¬ç¶qŸZÒiw¿…Öše)TfÕ¢.i”‡¶ş¼~úKûÎ°’¢öŞÃCVS2a®¬ÇÜõ¬¹ı§
­™jÏ¾ÜOaê#õ«'î¯Åd£ù¹CkÑÕ, sÕí]¶ÓûL5æZ,ñp!¾ò?wª[ÃHÇîûº ÛQ	NV/B› äa³Ğ_l8;`ğ¹¯«vb×¿ù’Òòê—ò[Hc²…ZøÌ½ß*&ˆË¦‰ê å^9‡ÈD,`\aÿÆåƒö8!-S ÚÏÚ´zu™¾ >ufİwŞÑ‚
Ğæ‹Ğv!_íæš-æxV4ƒ,GœÆĞ!€¶ûóˆÆ^ˆûö$Ej¤ÛÚÙY~­T>ª¾-¡vw1$×WõÀDn0Cı–—E…#¼¸¿¥‹ó9›1FÑHUHş9'º6b+ú§‡4OwÆò­"¼'¦¹æ8÷»Ìs3õS¢ßDÁíš¶ê-
xáÃ:ƒØ<Bòo”sàÜ.0˜\¹“C¬Ë1ßj…Zn,˜&ÀœM˜óznÒÄ×>\xÄ	*/”|mX)„¯‹z[VqY‹ÇË?AÀ»ãùoëñìWoÁq8ô`ç°^ÉÇˆÄ‰çw1ÜIóŒe…bù%L<J4’ÕœJù×Ûy-b.b8f
ºPÀ1Éw9úz÷¸à÷ôÔæí¡1ÌØP¹™¹/^y6yWõ³wµ«§±¬3ûi	!Ÿ¹d!køMe)³ûÀ3.J£ôP©ç"—Éºb6[]Ü!»ıDY$2yì®¸æìRV5øgz=ÔfDíÀ­pr„wê¤çÒıˆ»`áYN‰]”ó3Ø,È‰æ n0OÄù÷j•‹Ùİ‡å*O*³EË-2(-Èê„júŞ˜‹÷H´}Nˆêşw$õºå™$©GLÌV³‚ÒRü˜z„4C†ó8˜FaÉË%Ó·	6¾Ô ˆWY›x^~ETŠ/ş¡Ş“¬~×Á|ªÈüb¤ÓÚéÃš±<rµ£ ›ùƒçT/ÙO.»•şñ‚2íò.š€D&–¦ ÀÜŞ*ÔO4´“3íÊ<\$áƒB4d7JsèQtç¬­½6R
?^nøâ<n`1ÇÛf×<Ô2Fe`®m,<7+8!Z)±Oş”,°6ÄËû“Òæ¸1Ì¼şb˜^$µ7†vÍÀuİfÕ`NÖ”
*®´`o£Q]ëqì ùk{Èü7¾Üx`ØVÂ"²éZ{×aˆä·ZÒ6BèsĞ¤®
Øà„¸¥¿ø7ÏL\;ƒÂ½hßcŸ×ÜS“5âû‘R$Ú[×çx¬gÃÚ P‘Ô%ağy%¥ñ˜Ï-‰›¹oŞ!R*9ÛFnZ‘Œ¯PÓ“!ëâHË–“µkG6~‰t¸®Zñ°Æ0¨{êŞz$eB‰®¤KH—‘UÔrn’è9µğ°«Jµ8²ŠI·Ç-r—-šª;©‹úú	&¡Ú zfBÃÙxò^‡¸WéH;ôl­@X•ó7Ü(t„„ÁßÏ-×Š>ê˜AQĞTÀÎÂ² (ZÊ$äèL@¿V±oeY
áDåÄeøáÿnùÙ®*ÁƒhÂıĞGõ	‹‚·n|™­jLs
#t¿xjÎ	~UGAÌ+õ›§»jï7<r	ºy‰|fgø§£S³¢êxcˆdô	»¯`7¼zˆVXæUómE¨'ìİ•!¾æ˜Â©×ê µ¹=æ1³>t©eNHùÖ-TœK`FrMyqÄ±1ë²uJæÿqöÀ8Ì¦÷]Èêaîñy~×O&xï	¤o›àb‚µpÚT$Ö=Ò ÔYo4´]8LcÀçqŸ1Á‡şï¾*b»QÛŠd;cÓı£‡$r¾ïG°òTøùª
:VŞú‹æ”Ó¯QgDJRÜ³/äE]~¡^Sea”I$ªGüæòa sÜät‚Ó6rÂo—1´»'"Z'…(ü–?C7İ®˜Õ¯,ÑÔ^¢	;”ŞcPƒL#ûÑ=äÛt„»9ëqpwÑ¯*nŒPv$0Öc]˜âÃJ,a
[µØà×÷gÀ¶0îfúÇÓæ¢†Go©;Ÿ&kÎPá\´†ı`qÌ?X;mhtv[9``§ô·QV¥ì™U2æmmDpû£å²iˆ½:à¬üˆ]3ZË^’ë5ß¬ëĞÓIØ!ø£DÀ°…ÁtËM’H:È l>6×ôQ;'@ÿaÈ‡%¿ÄµôŸ‡l#f•:e7bÉŒİĞÀr3”ØªĞ}R¸µ‡Œ`MŸ“áC²'­EÄ”4im„‡BJ®İÌñ­Å§DK„46dbè}GÇ5!Œo?{,Ï1|êpHöšø>³$‰G¶üv¼;r•ò„UğqV‹¦²»¶ªIşL¬Bò?±v0¾©¦É™@>¦¯|‘Ç÷Ó…—ò€”ŠúåT)(Ğ5“À)ÙéÙ×UŸT›ükrØ’¹¡¬£>z²¹ı¿”CÀw‡Vóÿ‚Õ†İ#ªÛmô’¯Únpá;ˆë;šR:w‹pæö=Zœüÿ.=‘übğ ƒİ0”‰†,ØcüÜ:áŸcµ`¯ıù…øJUÃÃ1ê$ÌW6Ş¢ŞÖQ6™ÀPvı|d?SaÏK^?N‰MgˆOJ\ÂJVêkÕ-˜¥„öÖeô!f4Nâõm3Í_} «‡T­ù—¦Íâ%ÛeßkğÜä ;³m®)wN•êH59ˆo²ë-u6–—Is^V®ıöËal÷*	’®³Šİ0BL5Ê7Cÿº(âX_İtg”h€Öe”;ã×\Ö€­¼”3Q5lŸ‰İßoƒÑ%˜_½^SÛ~u¾Ÿ\ı.€×Xëƒ‰¹ªÑ¦¿mxQÂû~Ôñè”Ç”^şj\h:éÖ€FbªÆw8ä£ †M½R[7Òiß¬7ôÕÕŠxxY­7Õâ6ÕØ¿gøö(5R—ÿ­ct®"+ñI3lÕ
b#Éà˜Š4âQ;›ŞĞ‡ÉSuUEbŠ—ßÓ	ßïq ¨¢nòÊ'ğ[ß^Dut&Š–Ñ¬M·R¬ÏûCHİçÛs‡«t»z{C´1Î–£’˜¬Z°(ÁÿZ!#U{„ÛoD"—}º6rm5òs¥õàİovÑ•ŞpÔù»®t$rC©˜IÇì	YîCÙcãZoö5$ANgkˆÓ‚9võ*4ÃÇŞ}É$æ/jşN]QÌÈuøaî/Í~8¸ã`c¬ÂxzzÁ0ƒz¶º··òV¦TeûÌnüb~ãÏœ‘ÄÙ4oS.YtæËêæŒÈ*Àe\\!ã±œ?}Å4m0¬µHuŸá¨şØÌ2Ú¸8íÍJtÅNNğÜb¬½mq, ĞWõ	ET#Òÿ˜±&dŸÀßï|r5c@õ~a*:_î‡ú±BV’«@Ë#¸ŒODç*£5ş¿°x€#‘ÇZ9©gB)pÿÙªxÓÈàœ%¡e&©šŒ«“Õt&É$«@ÙöÄı$UğozŠº5ÛõS½*µóÎÔ¸†Š­¡\Å¬.á:û°.,ô¢CdëßøCDE<¡êL^š°bjÄ¸§ûÔãÈ‘‰7;ùN®Ï ,š3^/ƒ¦ãûQäÂ«|z>4Ğ…vúBÚ>¿?J“¾câ[PVîuG(†ŒµNw8BiˆÑ”áê˜/½åÄ˜Ê	ºşX:Ãb€Ô—MªÍ^	àÏ¯"ÃÒß4w÷{a8À`-i;ÿJ°‘{ÛîÙÃaö]¢a„ëD ¦Xœk%´\lìÎJ‘EÕWÿÛadÍÚÏÚÔµé~ ÿ‹i,eŞx|¢şJlp´4Æ$87§y&•GQ²‚’ø“CŸÕàDtäê3ï.Òdnäg%Œ[¼/#ô¶f¡oÛ—Yê œÙ)×|ŞL“ş4Ot#²"ÅÿkŒv4¼ñÕW~YAi®jl…Ì9L¼B4{ óÎÂ¤)Å3›æs¥¸N2÷ˆWé<ùUSÂ¸{›rk¬2	´ûğ¯ÌàH–ºŞ*èù÷#w·¬…Îƒ&Yß
Q´#—XÀbÌÇ*cQZ@
È G,^]€7±úbŞíòàôv]÷ PÀtìô÷®¥tM~nÌ±rzÄ„íØŒ¤1èìò=öö@¨Wse|/ŸÇlvAî«ş	üFşV0SØ»ók¦uà]5šiv~êJC¢SQ%õëXG$N
%×Ø×øñ|‹ñğz‘ƒªÎ Öú§_¤Õ‰©uÓ$cµrK=ïÌb	(‰B0å'7@]í[ûŸ‰[5HTC-œ>†óV®°"_+ÅÑ_ûÉNø$ôoŒ|?8Ño
ù\uæ9íFıkú´Ù­Ş¤©¤[óï®¿­–°]¥Ä›ÿ³šeÜ%/k•¡¾Ã#BáÃqm÷T3ß”hÿ—r‡’ë$ºÚaîr?¨†¡uÓ•-¾ó¦rşGìhLë#WBinôå%Â6z9íÄ†"‰?â‚ğòóêK•£=ˆˆ5êíé€—{<ê}¢52nò5°Q[+ã0TşnN.üšöÆpîİ5 õ{rƒå3ŠOOŸö€ÊÀ`f°mTèñmë·9»ç¿#gRêÍùÖ½7ÈQ	ãd‡08M.$º)ÂCèÊ_¤n¹d’¢y‹ĞDQŸÊÆZ ˜/Ê*Qgâ>§óiÊ5UÔŒ£Å÷<uZ,ï•ÎG}´¸BïØò.s½×÷jñ‘7´1}Öœ‡“©ìù2¹ÃìVÔÀÃ§6$­E@ÂµO‡‰ 	n†Š˜nµSäÜéí¨ø-™8p´™Ì_ÿ*2Îİ‰‘l‹¢¿•(<ôGráp8CSÙAªñqO„ë°ö­x›‰º'Ÿ#ø.ü3Lå£Ú¹1··‘5#	¹¤€Bz^ño7ê<MĞ\ÂeÏ+ãƒg" BÍXXMÍ›¬³‚™a»iŠÏ£yTÔ*=ƒ"î:¯S"-®„Šö@Ù¿ÌHßå¿ÄYÿ1³”bÌ ¦TÁ‹y¦2Åt®íUäË— ƒÔnÊÌ8	Rò;½â¼s"Ãë¯åäÂ,$âLÿ¯Â@¢’aÇM=¤:®ª‡Âÿ-ç}:íã÷ôA1_&Ô~v„1;2CµşkÜYº‘d—t”i:âjÎ/)Q<˜+A¹QVbòcHÜädcBnÜt;>Ã˜¦:Ê İ’™]{a}BËXÆ	€‰ó@NÀ®Ÿ*@ó¤mw†½Àğ7?Údio
´\ÉÏƒu7}çãXu•qàÇ¾ƒáküàvû;´O`‹L³ØhÒO#iÈ¶B,îŠà+Èœ²{R=ÌPÄrÆA¸î–Ùìÿ¯VÄ`r3läÄyæ|a¡#´æ`E!aDS¹‹Ø–[q\<z+âfZÒÏ™×ìÎµ¿å«½tuæÊ*„/eXÎ5…–À7ìJñÌh×qğ÷ImKíT¦Gî£ÕEîîD¸6q91Ö>–jb¸2Ñ<PE°dƒî#CK-.î9˜.£Zfüá¦U£ú%€#¿òä+ÎÄÑWSßÚIÉj€—%I™ÁeYH=ï)S<Ñ¾&İûßnü€|:L«"ÎXàc™ƒµí[4¶-9€Ò&ç‚.ÀÄq–@v r‡à‡^ll{zŞÓäw‰`®ä ÛsÛr	[óFüF*[£auË‘'f1å)Ë@Ãß¯ªûÃv)~µ­ˆ!FÄ_ÚhŸ#)€>²æ ²Za_?S­$ ¨¢€ ‘î"±Ägû    YZ