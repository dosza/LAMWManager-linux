#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2004484781"
MD5="043fc97d8451b19cd4a45002449f212d"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22956"
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
	echo Date of packaging: Sun Jun 20 14:48:31 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿYj] ¼}•À1Dd]‡Á›PætİDñrû:úå!~oH°¶ÄŠølwŞ¤;B}ŞûÆİ÷ÓAÚÊ¥õÀX'wõ‹sW œ
çX‘:s‚í™Aı#şØñÃûtáWyl@xı3|ÍéßÉ*·İ!‘Cñ<Í6BêÛªT:}O b×€¿ƒã( u¸åëñ¦¥–ü,¤ˆæ¢=GšëÀ™g@ıLx }ÈèáyñÿÆÌ»áÅ9Ô?V7¯äS4×CëEPƒq^¿ØqQÃ¸»@æ¹/fËyÃ3ËqúH$|#Ø
ê£”z*
¿L,#ÔHzãÊ0Rá?ˆ¡şFr7]‚«tØ®=C5¶…1™·ŞªİBâbñ¹Üæ0˜`§v©ğ1Bsı®8ª¿ ä¯r³==T†iî[
ƒP ğ2´À%0Ù .7vÌ½ãìµôÇøê³¾®EÈ4‹ädË»JÅ \HßÊÈEK•Âª
E Ëâ4øN°-fÓ9x×S Z<$ÊÎØK)Ô±}ºNs{%6¯}íIÜ²ÑV7"ÿPw)TÈ ıWàPVUAˆí“Zü–¿t†Ú‘ÃWnú,Í¯ôic³'ÔÌ¯HêûÇ‘WŠ!…èŠĞIŸètÇvi:.±Œ»Ó6ÈÂF[)Ì>>¥íè‚]ÇÖ¢o7)ì¼Ö~İ>C&K#^f5¢‘"à@ÑÜ+_ñÍuÃAÊßsÂ%º0Â±ïP“å{‘´\G…V*=Db´?øD†Q§ú£íŞÈçÔ	ryJæoDµs4$½·YNŒçåÅ¼Z’Á£aÒF~Õî3åˆ“p¶‹+ü¸R¼óAÙ±ı=Ñ¦×Ä	M{Ü £m ª¸ışônÄ•ñqƒ£‹Ì£Åí+}&ót6ğşVßh&"]üşéÿ
Ö†3Ş÷®ñ°“ëQ…AŠ©çĞ"S¾Øá6ÓY4®"‡WÓpCt_˜uz€1‹™tµ>Ş*¶h¬2åŞÉl›ûÉIˆYğ2LèëÚ€¹dLe§¼˜Á'ù«|#¿íHì²xËöŒìøÅãÙ$¾©æ€`ænå¡ñ#àQâáµı€)':#åä9F¶–Iüd"Ûf¾°wĞ¢^µÇcÍâz–Â¶ĞD)»mc[€‚NñÀİG}ÊR‰´LiÅ 7‚w5âç8½ü»iÌÿlpkæ»µı•€…†›ÛÀ;Ëê©…Tm´z§ˆ«”jË¡a·hõ„ÇÕ`İ˜ˆ˜Ij;’î7Ÿ2A¾kLğC4·XîÖ& šÒ2€É=œ0_…W§¸Enïí,ËTR'­¬‡÷Ä‘a¨ûÆ¥åÿ$âºòüo„D¿|=ì´b¶kÀ…ŸmYD9Õb]éDÆ<Ü5Š½¯i[ëFÌ8*øË3
§t§|¾·˜Ş"¹hR>e}â=-¼óßFÒ½ÛXŠAü°¥ãRŞÆñ‰ö Aw’kCÀÛıTCç-^
(·åğkÚÏ‘9÷¾íÓ
úO¿:&@ˆĞ8‰mÄÚKD[7Là5¿¸¤èøŠ1AéeL­«#‹‚\“	£&îj*¾,gÒJîÿ×ôô”'jSâv–uÏnZäÂŒ©WÁòÇe/z ¢Ê{×—I ¦Ğ4$¿cDn&hùşÄSüÉu•fú»(jûS›ûlì½U"b9û'Œ%¾ò§á@vÔ¯öOu’®0‹ÎÅ°½T&ºÕğpÎùo‚´*¹PÒöıÛĞ<|ÍèÌiiİ×pô	÷µ<ŞÈ+Ë¹d{ãÜR; ]Ô±”öMŞÃdDzÊâH´m÷é¨¦ÙP›&^OCÄ¹ÌtØdcÿ(á,Q
¬Äˆ¹òöwXÚÍºY;“÷+=ÉOUÊ©§ÁÕ™X–„Šµÿ­hB­º$UøÖeÖE=ÿ	ÁÚ·ÚÄ…ë‰kÍ>7Q<£jÿüMH±Î>¢>œL ‹ åMÎ²„ßN'òy>›¹±‰	ãÆ¾J…æ—»^„9jAŒ©–d³‡®ĞWG ‹ÎÅc“WOeØŞ£U,ª†Œ¿@÷Íñæ4{Su®YDoÆ8úO›ÊŒİÌm¡ûß5Š.201óå†MaIY¸ˆº§uŞzŸ%wÔcı´Lq¬¨nÍOLüğş"Òıñ¿¹_¼İÌ‰¼¿ïßĞ§åˆsÿ§&ãÔªnĞLB¸¥'ûóÇ·ıÇûm+Èúó·]ïPÕ×õ,¬ñÑÜ`Ó
ı:Å‹@ö‘Ñ-ÀJşC†èÚZ{õLò
Ş%ÊÓ/“³¸#s<%9!Á,†qöFqÒÓí¿³ö1*×WøıSşŞkëYb‚!Ù¦Í1ˆØb§ö…’$3e+&—ÚŞnÔÑ©ßGÍ(î_¼—„õëÅşÑT“#á÷k‘£	¡ô‚±t÷êÁ
t¸.›¿öá¤cÃ>w÷İf²¸l.dœó…÷ê-À£AmZ³ñba	oìGÚoì…Ï«eRá‰™%k/|¿Ş¢‚ı“ó"Yï©k>á\š®aô¿nÕUŞ¢\—‹Ô9ù¿#NéÃ¬²1°FâÄç2¡©»¬	â‡¤4
¤ÇuÓÌ[N1úeI •”u›=,ôa¤äAù'0Ç’’ó™1 aÕ¢Ñã‹ºÆ©ç— Õûy5wiB÷„ h"ê’DtV /±8b…Š$cæãŒ$ãÓÄëÌ|ä%{ÁKĞÒMqë`İõZèğaC)©$,yFB/.µûİèõ¿ÍpÈ×‡õÚÍzÌßyñŒa)K(Q×²:%Ø]
Hç¾·ÔşYÎMˆ•šª×~¶¨`ÕÌ]@ˆ¥!(®©-å%b£#nêõ/6[ü¾ÙœB— ê÷ó3$Ç²V`Æè½Àr=|ßø{ l’s{w/¾#¾¿Ædc)\x2ÇŒŞ+ô¼V«Å(¶ø|ôç_mv—¶R;f‰Œz¿ˆ>@ê¬én~üZ<¥Ë–·-Œ#z€(ªKıîÚYê§jÒ|²ÂœÎt%HrˆÍhóöÊAÛbcıZªN¡êkÒğ­_›ë—Øß•İÌÊùeD_z½ée	_IïãrÕçBkhí ‡±-£®4`÷è-#qeI\†•÷èMÀî,î°B²gF’1P•-9lµ+¨lÅ•T:	mòïçËÿMv…/È+â†f§í×ÔĞT¾xøp$ ¢:$Izˆw·ÿWŠ$ÏÂŞRıNsn‹Ç¨H¯´Ó@ñH"¯½„_±_–N`	ƒŸ¥5u)ÖB–?›ÒÄ@{î¤3æ¬–Ğ¡Ô‹²åÜ_} ‹—€mäPÌpíeÍÍƒò‡Ó´Ô£öNÜi|»Œl¥  ²îÙj1ô*_ˆj6Ç‘tCøáúb ‚·¸5ğv|¶5ck_,4ÕÑ©sÇnvŸyÏšãå¶(zRwQ’
2ÙÏL ú‹c×]Rï³ş^ŸøºHT4=d•$KÍ‹Mip'[PØu½9jù&,œÊ^’«àT2#}öÛ†C"1~'äÛ¦=F¨+‹“NVJuDÅÖ\Ñó
s!İ€†$tñRèòëq=óì¾ÖõA†¾è>–ò{A:y.N% M¸ùã9Œ.WŒW\®Ofeûp¾SWØÑ³ÃWIÿ’Áä¾g‘	‚t[F“¤ÎwòBu(køÏ0ñ¢wY»1ŒVú`Y¯|A”AªI3‚H/ÃEÏ¬FïÓšêï"ş„Qà(àkäíÄpÑ°æ5a²„×}ÜØ¿˜‚®5ÙPÈGÿ°êQ´ğUvÃc ñ[ú*=°Ñ+j&x…ğ:àe´{”mg_Í€$[kp¡ú@›ø_Õg¤üÍ
ÜFv%¦‡O—³ğ…±p,-‘[ÈèÖãı\]p'?Ä	Jmé`/.Ÿ/Y!fá‡ø.%Ì²,èfÑ^=~Ë¦§‡‘T•¹lÒğôqK»Lé@m”!œ¢~ãº5¯si Á<·Ş¾Z>Üv¿(¹°^¶,~HtÑà¹]˜<rœÿufPÜWŸhÓZÊ«N|"•ÿ°™ õqmêçKÇËº—µßrÖZJ‘>†PZ‡Ë’„MºŠPœVHR65ô~br„‹-ñ—§Ÿ2V£°ĞkÄnvCpja¼@:ÃÂ¦õ»KóàıCİÍK†8Ä/ŸğÒAmúRáê[B†b U›NÛ–#ËJó>¤¡îéšæ¨pç˜î6ÎáEQÎ\õ^'¿Ì¹èt°9îl[ª—º£Œ
‹¢”‚“«òÉ9ÄIRS!%­P¸û¨%¾!–™/,‹óÊ³¾“^M¹†Ç7Fcô°dÆ[ïá¾ŸÅ*)¬Dc/òÙ³)Ş¿{áhÊÉp¡/°´.ƒıĞ—xóÕ^4f4¿vâmñÇ(«„\P6EDÇ¢(2‡PxC<ˆÉæS)«ÔÖ¸ì(óµ¿Ñ-ÈFªT_-èİ¼·sÃÄÛ=¶ëşĞŸ·dU£NBò7òÂd›>©[+j;¾Z±O)	'ø–;îÚ§?&¢†¡ûåŸÇEÂú»œ:çş†ºO}C}½9ß` u¸§üOh¸5NQ0,K‡‡ V«Ët²ú¬ ú-á£ ùF¹ÅÚ¤-^FØJéE\m,ÎPë´opp=%3OÖ*“‹<46›‹eµ‡7ß¢õÉï%4ZØúÄ5JM»Ì7‘H{‰ıàUŠNâˆ'óÔÙÿÍæå[À½Ğøæ.¶
7§ş={zÚ…Á8†‹îjO“8è¿QDã‚(¡ÒmœZûz8Æo2Nƒ5¡ÒÇøÿÅÿptçüËús:ÄX{5¡ÓÁoKÁc§ˆWA&k#€¹ù†!_eE0YúŠ¨áofüMÈ„“åóùcPĞŒ-ë&éÇ-Æf‰­¬ÍBpky#Šew»?œºî6òB·³ƒ5‡!«´¼o”8³(î£Øq¹mE·ûË€®ùô(™JFísË¼Èb\uÔ¸è’>áe'*ÍsH~ˆhŸ]ÉpXMø8j(ÍÂÌ©2¬eo9ï ñùD’\ÇÅ5ÁúU°şÃä àÏœü@ˆã+Á¹¼Í´$ŠY½‹@áyİó)0K².Új qáÁáèVïnSS=^öüãÌÊŠ•É]nüAÓù I
N’2fAô?Úß¥§L†i9Ï\¯"~Ü@÷rÅ˜ï—†_ÔV3]h	Fä‘!|$Ù!Ğóî`H(£õ‡\T— ß¼Áà ğxq%#òD#QËxT°¹AÛü"HA…B´DFÊ†9==Li¬a•Â@·0ò,çÒòõæH.š# ¬iì¶WûôÀbjXâ9ZØ§Ÿn‚4@•ÓÉ™ÓİÄ¨T;ÿË«W%µøeó©t»œ²³yÚJV$ÀlM–nY!¼´ø÷†Ş@Çê|qõ|æ««RÕøL¿«.XÌqôï@Ä¢äQ¶mzìz2ß”EÓl:ÑKíšY®'P¬(xÏlûƒk,İ“F™ş65DŞqOËj7¾æÔV´İúw€.u‰E³ƒ5’“±z%zf5İxeg \’ğê”+|‘È”™~’	ŒÙ1&K€&ŒÜ.–f;€‹J€’ğme»hp’‡^,.ÅÓÊ×ºÓÂåøÏÊœÔsç²^}ÉäÒ<(P­‹£s‘h3ds¯9€ú;_ï'wm^ƒ]›Â‰}LG”€Ğö0Ò7mObïzáÃ	ÆQ`nÀdô±åÃd-—*´zzlCñ8ïı/TËØÇ²:[—äác¢à^È?Û¶¹÷”X Œ8ÜŞuVD~}ESL!şÚTPà´­:F/Ì…ù3,À«J÷Şó5,$d
ÕZ aá€õçOÂT†gİò†Á÷Æek™œ8¿AŞßnW€TlB5<·<Ÿüıa†­u)ïğv´Ô3B¯!©çíc§©lÖ‹¾™öüèø¢Õ¢è5•äßc3SØsÌ6Ìïc9{4/Ø×ë.ªŸ0„wğESí7ú,–-cf.
*´Ç¼\yË>¿o8Ä³.ã+DËnÏW‰8æÌå#ÚÁ:Tµtz¾¼Vú‚Ç«:ÅÄy ÷1R4w®1ŒíWÆæ&ğ:)år`øï³ßšêßîí™ÕÃ…(§xØnìı@N_æ8r u¶šVÙ…úÍX
ymã .fîQù‡‡‰mÍgl‰×÷˜”²¯‘Ë73–¨C»—¨ˆ¦¡d”nW-VJœ<¨×å¦Ÿ]³bEño&ôšÎz‹­™ìÙ^/´§Á¹T’#÷B™-¦â†úKÀ“®nÌÊO˜”WÇhr	¡ï'ûq,NÜV'6Íc¥µ¿œq°7ÿòS¥˜rx³•;»G h9|úQ¤Qÿ$õú˜?Ì`5#Î]À«
á“‡‚ã”¨G€ÇtÏbg±vÆXÌaÅû6¤†û/²D –‚î¡4cÛá~º‰úƒOÏïTQÙ)Ì/1œ2ë½|e¾?ƒ‘Át•'òD®oí%õñK½uï+/¿í8['qæ¯)?óõoÉ1‹|ƒbÅYËµî”©•O’4Ä.eÈãƒ2SM×;&jÈy7Ô]e/0öæxü‹»´ÀÙ ‡>y@÷1ú§Æ¡+Ãì¡[ç·# ÁoİB—L1¤/½ïuşİä‹ªØ»W¡zµf†©¯÷Ä‡€ö”ª6·…¦ ¸¥Kø¦ä,XRÓ­•îp‰&—Ğ)@{#>˜±6çs«%ä6ò+¿[Å‹½ËN"´1ÃDCäéôô²UêÕIŠ–Ü_&ê7£_tÜñºÉoªV¼#`5Éı„‹¥g¬!Gìò;ŠyôOAdÒú ï§o7ƒ”X, a%JkÌ4/L$æá^‚&f„+–.´Ë†öÚZ›…½ ›°&‘°3/Çvp&¹œEöj:)MßwÆMÌdMâjY‹	Ò¸Q±ºiN‘%*¥Â+Y¶FÜ´£ãÑ1k~ Î¸’®ÏKçLå!©€lå l‹“ì^Äuï±è9¤Mªú))Æ•;Ÿ±èo ­xÕš?ÃXquæÇNÆY`cSQMÏ ÙyŞK¥uÌÍÊWhúğ÷ü!ŒòC9¦B	œ2]íöÎ´¿%ÄÅE±rŠv`\'eîìàã./¿òŒ¯æO12Êï›ìfÅ<ªSyL“qjÍ= ¯³`ò÷yÿğÁõû‘^‹Í»ŒÂQámì¬sº[Ÿ¸½7¡¦3©ğ|bÁêæíšÍò7É·#MçÕ<’Õ–¤n9G!s¸ıPK¡ñš#j@2ŞâªCkVé¾ŒN«p›Üvÿ†×R)Ú¹fü36ûIÚ~&‡^3Âmk(·A×ÛôiX4\Æ)gY€`<ƒ±äòïÂÙq(÷TY°ésŸqøô²Ğ¤GIGOtËG;ÊÁ-J ğÖfÄc9M3{ÆsjƒcÍçK@
îD¿gR.á¨ŠXJç…ş¸œ‚×ügÁ.:¨jè0YRÈÏÏ’~Úş<ĞpÃâ#ˆÄŸ×å/®ÓRäˆ,,j«|Gú0c”B½ó¤’ak-İéñ×ğ€¥<äŸ¢8*ózVê`¿€Ñ ]'Ù‰ôæ{È’öö™'çß –Oô·fïÊ»ı\ÍÇ;'ñO'Çk „w³ÖØÑ­6ŠO&ûöòe…éª;y‚–¹ÈÙfÕA)¥P”‚¹3°Eü5¦Í½ô?(H.ÃˆöÓ‘z¡×¡9ƒÌÌy³7áÒˆœ÷$ßu{MDu’ËŸm3Ó
`¤Rë4Q_'Ÿ4í¯Âsš“47ĞÕµHƒ*Œ'“YHfHÿ¡=°zìeŒ‹“>ĞúÕ£’£ïùc`/³O~@x·ø`'ÆîÙG'+ŸİûX\ùûÒR{ÈL›Œ;Œ/–ly#]³(p÷Ü_s¹rÈ€Çu"ôjêAˆºI’wøˆ>?g€@ŞmùÔ ˜Dn¡%=ø{VroÀ¦û³y@ºãƒª™§â{ğv_Q"¶ËG2ØŠ™¸ùnÙ¿«`•­™7IW¬%‡2´C†>L]svî!Sø°}G/€JÔ f·#ìúd™@
N8Ô¡LÔzåø)|;3Ö'qs!‡àG™+pD*.i„;q ‹á".º^ãçô<fÂT¶Ö3’¡š™c¤xÍÃà]Æ»Q¿d­íIm&‡¶Œˆ¤_²ª¯=„;ßıïÿÏRFŒì¿1ëùƒ!|††şü"gîhÖì€;ÁâNŒhY½Î\¨Ç‰ã¦ËòãœË×â¯şí²Z4ñk7ÛÑ@:w1·<¾øŠÆe±†ö7PiÏ÷¬ _‘¯í» HI§šÙ?ñÇÀ•U_sƒÖs¼ªAßÅöÈ
@JqtÉZél÷òfÜ6pÄôlÑŞäï
\ş™Â”t(£²ÒË¤ÓàD5Pöi¥óÀJ\²e#{fpœv.ù°ÛÙ ,NPÍ;âÀhjÉív©ãnÅÚa¹•[æ;j¢g?É9ÊhI¾i"}3ïŸ_ÔqYôÙ\½î‰°9ş: ÅDs}^:Íö5¼”Æ4{)’3Ä®‚‘Êö»_l®¸hgf¥å²åF÷ã)v@½<,Mù_’¯7$ş£±Ñ´Øšš‡ä)ŞD[Äë§š_4J%MReJ¢Bğ–qØ‹„vXº6è¢N#'kœ‘îœ3‘×†\ÏÊêp3——~fËá"¨˜PbŞ¥gÔ˜Uåd–m«{/?dWåÊ²±oÑÆ—¹b´#«»ÜU\}¼yû)¶ ?ŞÙIh3„­H;¿ûeÕ!~¡ûš“dcføR¹GOI\‘ı'¥v‚
’×ÁXĞÕŒ$‰_++*•8¹ÇÍ†*GÏ›Ó0Bn y¡ÃÙİÆ¦°Él^ÛÌØÅ¾Š¨¡µÒ¸ˆìÉ¿Àç‚½şÒ5©ßçÉ1-T´?şf‘CŸ(q`±}”úIíG¶r+îèCöíäÎ»¡#™`7\K[®Äå˜‡!g“âøì'¯ˆBv¦ù–á(”Ç
î¡ñÂiÑcë‹¸%¯ŠO’l>”p¥|`åãÙø‡'\háiö{.¤Gg|ÏÕdô©zŸšŸì=ØOéƒ_Ò™«ïfûØëK[¼N•úÖ¾v0±Zùäö÷EëejÇùo|µÛ9*<tİ…šµTA²‡oŒ,‰¿ó{ÑS\è”‚`Ï¬¾‹‘‘ãz{í”PGjÏï½càÿ„æP¯°÷}È±ÿfåac]©DËäé0¨±u?ôõ{Ó|\şÕû<æÅu6)ï dş[W¹ˆ8…3Di;Z4Fv_à•‡ŠtöJıç#à>OV¡f"Ì,>Ûî-bSº×w&ttz¨ŒÏoœ¯Ïå+9idÛo‡Òy3á»İ$›‚Á©Ñœ(ü!gãÅ\Ì}£:V–Ï_X²YÛÆÓz°l-1Ÿyzé%¥Ã’£Z’˜ŞVLqĞ[yêµB¿”ŸUV¼`®‹JZà'XYXİ1Á†%Ş÷“®?_ZÙï¿%è;î+ÁÇ¡'„ÚDlÿ$¬B{ø÷ù<ÏÃì–\ªIŠ½¾`©× Ÿ³”ú~8KX¼‡©Ëˆy*6şÄ&OæÎè41ø"u‰6Ép”T§­È5Î¬ëøóğ()·öóîvËÅhM?ÔÍŠûâ·£fÛqİ÷8	X`#VÍ£šâ«¡R“‡Áoqn¿W
‰P +¿¤]xÖG*—”=€™º^üœ¼'` p"§Q’Z5ˆo®sİèÛJÓˆ¹¾sÆ½ÍI¨ å0¥¶ÌçªÈ}?*\š™µĞğİÛ"«Ø†ıD]Ü]…ë*¸÷Šõİ‚¸hô]®ª±m^LÍ±¯oİëŞ½ğöÂÖ‹²uwMøZµN±çƒ0¥ÙIjÆo…íîœ7Éé‚ğJ"põƒÏö[ĞW´›“
á%Zaıíˆkãz´†ºo×š¹€hFî/‡tŸ{(K²7¥rV¥‡šT¶İ·³úB?/…
ít¸F9bóKOôOŸDĞá7ìäÄP0©¥†`)êàşœ™oØı+ÄàäzJx4zúÌÿ$d–Á·4·¼'QØH¹é'WZ~h*KDÏ6vÂßÁP3¸ıĞHxË'<TÔ.>™xO·CÙîM0XI[ÉïE|NmüŸ0‡9ƒ^§å­}–˜)ºP§·ÊÚ)QLŒZºLó-7j0$6sºã-ÛÜL8)°>9²Y¶zš6{¬RIm²Éãã•Hh·÷ÃÅ!½ÃGš:ë	K˜ÇBî¿>…/C™+<<µu{¨/€ô0Á)êÃlÀ@Í4ÔTèªãÙ|»[›vl¶ÃÀ¢U\uó9Msåe|,ûÔïªıB1ar;Ñ¢]Um¡\UTgìâœJÃ†·˜ª™¸‡F/KqzIM|à§î "’şoïÄGá‹f<£ãCU
V¸ÔqC¿obÚÁÚ}ñÚ”ù¹A(bµA,ã2h»·‹ß6ôàdãÔ¬i³N0zõ¸¥Ë­ã‰}™. Ä…ù*DÆDƒ2ˆEš4BMĞ” öRßWï_İès¡Ş=ß»±¸Æv&l_O‡lÎ5Íe. `QtÀ½¤¹è=š½¦Qwœ^R#/ß›YeêœD¤‰úôF©`;Z¿ÙŒ‘¢ñ»ØU )@æ-dpb!	£¡Y—uÅÙObîXí|‚Ü=&½¼T´?+ºÏ†8åVâ?…®»rÈ/÷u9úV²Ğ!îªõÈ-á#ü…èênf,Ö‹ìE 	ÄÇÏçÌ«¨Hoú>ÖÔ{ÓÁGX¾MqöÓW®
`OUúÔ!æí)Cø|LróS‘®pÆW‹½nìPbXÒ@·LJPdâ°"ˆà¥h€Ìâ¢G=’¦9ş^v@'pÔÁä+ì{hw]Af"Ûz=xFxr£êáõtk¢/e€$(~©å‡·¿ñ%`2Î¾=º·|¶Y"|Mú}H±ãáQŸ~Ù1Òıî8Oô‹ŠÛ1
B}{D¨iÇûñ¹;YÄŸ+ ï¤>­z@ûåm5ÓjŠ-\][ ;aõ>²¥Íù7Ó]°n¯ìºÀ:Ü öŒÇäTyešMVä¬pHäZŒãm¦£¡Ş›·½Ëºİª>Ö¿6ë‹J¿_a“èE¶€P’ü$/#>˜¤+q¸|Øm1Ä?mvhËn‹é¥cüøĞqCIP¿·wD9Æ ãÂ:9ÿ~\g¥	™OÖW¤ö(Îâ´±¦”v¤QÇ«·‚v[—È{j!I¼4äX·$ÜFSm.Ÿ?´YĞ$9¾^L†Ğ6lhÛ§ˆ$JX5‘ÎŸ¿ÃÏ¯“Gõ¨¥®ÉC¾]©¿\íºY—×9rm%ßS €ÊæPÏO›BC6SL\g·OrQ¾Ñb Q¼[N«G/Ğ.ÒîáƒŠ	¤‹cj&#JÉ•äfYƒ5ıkw·®/;aÈ!1˜û9µ<t&´]™…ôœwé=‘ Ù<s;¶2€Éàg,ìÌõ»—5”¡-ß-LìÊá&eºO«´R5Äs}ÆÕ{ÀŒm+XƒLkW¡óQ‹ÄÜó˜®zBö¦I­µÍs³ÒAn¿qğ „y¦×IF>L×…üÓ;R5D ksò›²‹€8/ÙhõÊUlå³m0¾Ï“¢eám–§ıHñH†ªohºŞ”9ç~Î”R©‰sëæúŠÑÒyŸ7~V¿ÅSmÁ³ÎåR	¯sêd†©BF\<d¬qİéµ–]ƒ§K’[›ŸÛ‘Ç#ı3)Mp·Æg¬‹ñã8¦Ñ*7„ª¶@Ø¦ÇGÈ¤AŠÚ­®“tB$Ï:Ğ£óä²Ù Â(Y…‘w DıÕ˜ntwê¹¯\YvFÅß `•¿~{S¾İ˜*‰D¨L¨¾^ME¬Ä|²ÁPÓñ—zßn¹<õ­eDüzèAF'Uµ¯bÑÀ74ş‘(64r îğçtWtƒßìHä;•ØD +Vê@ÌÿLƒ íàúr÷OZH}ğq~I.’Sõày9ëxƒ®Sµ	
yÂìŸõ^ô`Ğ(’éÀ5PxŞÅÁ.ÂĞá³øzÆàş\Ô	ÑÚeÔVJ†M_m’8nYÙş!vàbı‡(,Ü×Ùı›
t–o;Ãg¶`+PObÒ™sãË!K&¶ö™&VÀû>k
ê$ºB+È	ß¸äãâjô‹ÏıºÔaZ¡NšŞC •Â÷_×õø™šq:Bø;vÌÆÇ@Y}j×B¡CñÖí_Ï¬éu+õ`×ŒËÁÈ=\²·	kO{ßr’ŒÊmöJsşŞ$Ó®S†&Ò;)ÁŒ÷7s³[ÆXœNIUox¦ÀMµÿN˜ÁOƒ€ˆ! –Ğ¬³OÑ®>Î'~Õ‘Sœ_À­~&W3TÉ%PÃ÷ÿñE³ò‡–v9¯F`YiI¦-ÚÒ-SóÎóp*êËF3ĞÀilàW-lö½ƒ{hè2¶Ìo±u/ò/dÎ©™³öõq{M¶R°i‡Ä¸î8y¼:€–‹¸ìıåŠÇõ¾„.Œ)ÙğátO Â-•‰®¥0p–«òê^k+â™O­JL}åƒÿ‹ã2¤ùŸÀÃp!¶œ’†ç/ R32q¥Bå²—#&˜‘JÙ:a¹ç 2ğãMú¨y/Ï»]ı€U®0—,è¡ÓÌ Î¿“ÉYÔ¼û'Ëj¥9b+$÷IŒ 'Õ;G	Iƒgâ¦Òxq²ìªš¿»ô¥ÆîIè¯“p°KKgÚó‡M~Ô1‡l×V$5v•}¬¶ÌÓ/Š‡ã°ŠÏˆÜŠ? +)æá!ã¥Zªàãñ‡×AÉ°vd=åıìx¢³÷,
F<”Ûbú’P¨·"ŠÃmü‚Jl Ö·vòô6è³Ï_wú°>Ík2ñóÉ{Ÿ­ïÍN H¨l¼àL„œ“ì—„¦$æÕ£%Êö@0sãÄmµ¿SÄµ}ÙÇ!2.bËsÁjôÁ-rÏ­ƒÿ^ê4)~¶£êÙÔ9¿,’J—G©ÃìRñ6+&>õ
eê(H
LN‘”ç°´¡“·Ïì[Xş^Ç†K'é«·“Z0§-îÓ]ÆáqµK·¾@Õ„Ë@Ôâjt @ÅÕã˜†û ½…ªhñxŞñ”êB–>#`Tû"·4ÙÖH>fZm¸ã^¬?À"º9Hãn{ÌUÄJÍùv@Š›ÊSKõB$rğÒ?ˆ5Ş„çÉ{²Ne"¤˜(—Çÿéù"Àn„¡óæ´»şÇnÆ |¢ƒ÷	ê8¿Á½,XäP
×…ú5UÏÌŞUY@P¶Ğ_Ì}	OlƒpPŒ‹“Òuçxpø¥~j¯È_ŸÒO²„O \ºşpØØ’÷ŞµæFÙXtW—æ%tûëµ?…§Ú›V3…¿	17xPáÒ±i dÂ-JAÌ'2ŠÉ\gx`Ø´nK,íãG¢oæ¸	gè“tVúJ¾zúô=Ì×øˆEŠ­îG´UÙÍZÄ¯è´wäÄÌ	íÊ$'ìmâş¤m˜î@³Ğ-½¡Zù«
 VŞœòdä}qê.å8|gUv©ß³Ø¼¡Ğ‡.¸^»öH;"p2ˆÓô«‡Øø3bxv¸(÷#é›âÌ0d*Xë— ¼ç“Ä1?³T+ıX~‚›…Ue>?Yé)ğïn™µº	ÑÇİŒNâ ›ÏTç=¤y’bOhOGÀT:ñ‘W›î:Aˆ$Áj³Âtq…:YÀôÁèM£S;µvP“£Ú¥¶¬i³Ò…qÍàØUg‘:õ¬O{Ê^C9Ti…äıU^Ëc8Zã†Á%O"·B}Æ=„$Û;JLcÁÁàµå/Û1ıúÜÈFªb„Ô—9#q²ÑˆEOÍ›¼MÚ,,¯şbè½;¶ÛÎWT€æÚº,ï²!„„	Ş^îkÛ{¬Òï
QNğ¢é£‘\üÀ\5eæ·ğG^­éÎaŠı«Ÿà:ßòÑôí·ÿé|4ôÚ8’.zõkÕËC3Ë*<n,|‘ÇŒÇ%CR¢^#q¥ÛÊO–O1°ûÙ¨¤B¥‘q¤šÿÂeMã’zP	¤®}Ğ<‰†éà8Â55‡Œ¸û#Õ/H±†‘¥‘Ú"`äÕ¡ Ö? †X¿WÚ©,Ëâ›w@XŸ¡í]ŞŒzŠ…c“@BÁ±Æ”Æt’vq§h+‹òÚb›ÌğİïÍãÜ0^Q‰_¼‡!©œ?¶ó•¥;»¼çAWJ™>uNÙpr¨îË^J\1„2¥fJ™]xøe²aêAÛ5çœ&útßi¦ÑK&7W¾1e7 Ò©ªôÄD½D<€¾ÖíĞÁçˆM8Å¢¹'üÂqv¦0´Ù,YKïÄ}÷D…ÊÏÎ+ò‡iFj[sØfC­°ş5™GQ!¬IŒÎYø?¢`Uiÿ•M]¨¦ğÂ«CnuÆ1VCH7jzs¹íN­@c³İÖs’=ŠA­61@Éü1Â‘îtî]÷CšŸ§÷‡q;h‡‹)Ä _-fÏ>âXK¢²}j¼šyÑ…I>ûeµÄó£4¦#|×7gR5Ø·÷óJ}&Ş¯æä<¹Ì©Õ-®¾P&éy@ìı†³™æªmŸa\­~Y»ß¢ÆbŞÒ¹
“…•d}ß§¢…¨LG(N¶÷ÌáêQ6mŠPšÓÃEĞŒNâ++.ì ”ª¬’\–¶Üg‚ŠÊœ?Ï¸øø'Y@&øëh½ÌO×Ñ=r5È¥=ÜbLq²ûŠì~Š…oµzÊ~‘pøwålÛ…d;¸‡ù1uKMFâ—KóDoÆ×iÑ¶J5@G—´­uÃLÁÿ!ß´ãû1!«"˜Åi JİDR>²³Â:bm±¤øŒ½Í5§…»|{|‰?õUEypÅ›<b¿yGò££O×F@°¿&š4ªBÔpİáå%!OHr& È6Ì2–í–Öpíşë®QçEîÌUÅ´WMş²íOîï%t"]^y=YÄ.nh<<Æ<„#ßrm>¥•V7Hı^«şQ¥Æ0¼7î™Û'P¶ˆc ÏÙì7½½	¼+×åDğáÕ:#g}Àñ6èHq}Ù¼ğXBóKNÓ!»&öæÍØTğÇÒ³Ù…6:'&náÍhÕÑÄ(Vn¹õ×ó®„}3¨vŒ‡Â‘3Æ°*‰Ø¶ßr¶t‚ßªôiBÊñ.Ö1jğäcóIø[n­VMqªsjÂIgS2.¢¶Œfì*
}
$ûŒŒÍo3û±r^.á¸‘â£^¨»b Y ½Š
'§6ÃQ2Í #ô5hyp¥z
¼Í— årË:ºJ.VBş
Èû¬V€39-beoRù9Df-¯Œxhõõ	!Ätaé‚ı—ÓËê§Ô¸ã›¿5Åé1#öËëÎ2™C>î­‡5®Âaâ¸D¬.ÿ”pRÓÃJµì†Jpeıh÷@„Rÿ{¬•LO'2¨¶%ôÅØñß}á¸·ÆOS@•CÙ¡~iùVôjÓqçPÿª MHÁ¡æp})wïŒ¸qØSÉ”%eìë©ŞÚ:ç°@{i¯›ÄÕ),¼-×4g”®Ë/aÂ¸œ2İèqş¿Î(ôgDÂme|kYÿ?.XÍ6İ1Ë)G£êˆšm.ÓVŠ ®gŞ"â;ô¡ğW¥pQH”ñTZUgàÛQÓ³#²‰Ş¶³Ñˆ§XJçĞÀ;°òŸ»!¶d¸,Ò›n;Ê÷¡½k¢¯Bf‹]30¤a2ª"æ?³*Õnq ›èÁYÛäpË2D³LY›³Ïe1ÂQoN%Ša°à•‚DY¨\bS ’Y/"fk*e†å‹³f!x]—®ÌøƒMEšÏR`µ#¡­vÆƒ€÷È?ûiş„ú.lZµ[ä¥qâ³ê1Ÿ"Xt‰g*ˆÏçĞ!Â½‹)KÓ¢ìÉDN_ÈÊ*Z}x‹ˆí'íp
¡Øf“¸3öpˆ¼I}î~ÚÈEóªNæ}Áë°£¿}ß›±¡Â2´Ö¹<ÖGYlœùt]DGÂ¹˜	oñ[~BêÆ©©5nï¢<9ııÅ‹^Dé&T‰X·Ñcq>·§)dC MÂĞb~úùr]´à) ^Ë5Ãèù(z-pFÄ^2kL88ëä¯yG?VÏØ{ù˜ÀD!çE_Ò6|J<ŠÃĞcÛf&š$ábÚj¹Å"Q.¶S=¹ÁÖòVŞ›êïcÏ‘&¯CŠ[Ş‹®L«iÈ×†p*å÷¦àky<XmŒhíºrävtgÑîe¾#Oçr¡m|Ï%ÄåÆ,¬Ú[u!oÚhœè6õáÏØJ{Ç‘cQÅßB‚ŞA68.¤ãQæe”Z©È¶²Ş·íf@_®• Š}4+êĞva…Y[Ñ\Ğ•~£}{Bçs
)ZHC­1NÁ!’M"ÉM•‚AyÌ¨#ŞïŸ\£‰ ¡Ã«aÍşò²>,ËˆQŒğ¹ÏBÊ_™³¯šöÒX‡X;ŠšXcÜ§
<Ã=)’m°¶7
QUZŸNhoÆøˆ&\>ÑdbÕ†ı¨G„9Ÿü?4ıñ÷÷ÿ#ÂGEƒÆW‹MU…	Œ§n¾¹_R’iÊ#T­›Ù;PN ¬¶µˆ¡T«›¦jæø3>­ı”;ißñ*”XE×W[§>šc}ëº5)Å”HşÛI½gúR¯Š„kÏ’y7*8Ç¹¡<‘¢¦Ömı>ÓX¨+<	ÂÁÓ8ÚÇ	î|ED¹­.ÑĞÍ®&M‚!àfNF Ñ7MI±Şpx@r’oì
ªéÂí(áÒ·Ã»É±›ü¡C&Õæ÷h€<ò’—O¹P-p2+U¶+™D=«IŒ®)|Ù
KĞ ³®ç«œÇ[Z“HEş©`¾·NèÔ½;¼ş®šqø5ê*ZZšNïEU”ˆJˆL“¯æIò®}KQ}e¹ËjÊ•‹€î2Û‡×Ÿ¡pW¾ŸeW
`
Ê4 %óîáÃR¤Ò.SS#2LqO‰İVKJÕ¾¡ÿ!©&¼ú ¼ÚvûZD
úXïÕ'K±ôgKÁÛÖĞû–ŠÀ£ãbœÖWKš«hiúOK~©áWœæÿ­ùj„ÿÁÂÃoš²øşQÔN„4şœ›¶°8¡ıgx§–¹›èñ—º!¿"ÕJëÂ³é\ÆC­6‰Ík\#‰ÂF|‹¯åî Œã¼\¥€i4={¥%¬‘”V#ˆè1!ÓÃ×ñf®´5ö‘XÕ*)û_mß]y±.m/İ'p;­äÛêôiK"Àò
ºŠZÿFñÒ.å¬‹tÔ¹¤<HnC	fƒx+—×b(ùö>Pê	Ú{ød«¯ê›éÜyšĞ$æá&rŒ†â»ËŞ°°a!$pÔ1Š½í³ODGÑöUpáE]ht?¶¥ ò¦_,é2½÷U´ü>?	Ø†q©HpuJFPñ<±ş¦Óxø¢4p÷ç)[Ø€z¡G? J)Ñhÿ½Ùeõ~Æ+ÛêÊb¹¢Ç }\¨Î»è˜Ûµİ™c±„%İôm;N[³`ôï)´?˜néâ]„#‰}¹º<{a¯ÛäI>ä8æ¿göĞ£Õ`iŠæ›5Z_nÂµLÏZ«Ôaë¼Ö¢™pÉz’öÍéiÙ"?†jdJáT+ %&‰w¶ £éhï¹¿ÄiÚL8R–Ã? ­¤!¿x‘‚ti’ áuˆ_¡¦vˆ¤I¶ä02¤Fä»ŸÒ4ÁGÌÙ@°ö3„(‘x?Ê±P•CiÓ³Å%kı/ˆ˜!ìÉQ^@±EF
¦óù¡ òdª|öWÁ#æ©œ'H–×¶"‚´!şÑ._ëŸ%ª*R §Îõ­xôÇÚW,]R“ü«¤O‰ò¡ëo!üBH·äíŠWá0sïÛğ}Šd…ëû0ğÿ«@qîĞø9­@Y½…2v©º„„÷Œ«×Tm?¡<"”Ã$ÜpK"y¿Ïİşªwù*ú¶‹í°üg]4Q3¼<+SÚXú¯4á'´«æv½é|ÕñÍìtGYÇ@²ĞQ>H“`ÅŒÜÈTv¶â5ÄŞbUU¼ø¤XŠI”M2S¤•X	š¸'¾LÇZéÚtZ”ı¯+§Kfi ¤çÏy'(œÚŒŸ»w¾ulÌTØÙÆ›ÖBBîŠfC¨.QäVØ©|}¸¸4ı¥ûW“òü“¬²”1ù„ÁÆhâæóÂA¸Ò¥‰8U ôªQÕÁÖÌAù<y.1¥ïci	!8¡¯5«àE”.§e'E«*ÂIÙ®ù'büï“ı´G´Ûfç½|Ey2>wÄy[Ä¬>‘ék[9÷¬–üj=ÓÕKWÇJœöÁE€*çPOÓéIWÙ5zdñpâÃ%[¯¤ƒ·bz8“”¼_¸_øÙ+WU làšÅITtP1b÷ó¼P?×½f su²5&,‚ëõ:ÇÁDá]Ë!°¸Ë¦Ù25¹•Ã‡“mV¦ã¢}e­pÉM†¡lË™ª*›«50éV~Ç:T™¸ì7soS¶d4yN G5¾nwÙ;<ÊîV`ÖîâÕü¯sÓÎ!a¸¿€bBPDf×â‹#ó¬ÕC«X©ü{Ïßw#¯FÒŠõËz+ôZûZh^zØ>,¯9§—wo-p_QAz2ÓHÃ/0^£“|¥Nô2Cñ…˜E›xmØ¦ sğı!ëÕRØÚ´Æ,Z¥'N(aÃB:‚ Ñõº—ü$×AÙlA…„×]ÏÛÅySZ¶5ğ.æ‡¬×³¨††KyÃŒÛÆõ[*Åkö‚8×ö=MoÆz#E¸•"Ä+ÀñcEN²äî¡£§i®ÇÆTÈèM&Šª”ÊùãEP¥¢€¥-Ö^šª¤³Yâ¸ÿ4bà‰òg›ñŸ’ü|»[‰<5+^¤f£–‰c7sXÚŞª^•x	¼R"ÕD•º–á£GÁQİë¹îNŸëËöGå/EÚ`N°Æ8ä>ÔÈâ}Ñ<…jÆşŸl%*ƒ	çµ:yøJP!T%Á×›Âœí¹áWÛÜ÷²?KEP†_´G_<UÃtí·9âä7xØš¬-J‘X¾K¯#@enÅ­Yyç&g
B½ÈèbáA¤£ú%Áe±©óçÀ­eÂ T9**~®:]\£æîßÎìE³^‰Ê²‚=ÊN5(<Ñ©UÊ ãÓb¿ú5wÁé®Yï#œ\š½STŠqi£å¯{4ç•…¹i-h¯Ä›ÓÙ.¯jf˜Tãİ÷şÑw(©MYŠÇì©ÆŞ/íQN×òìÂÀµ¹à<Oìí_9Ç!Ó“Á­Ï…¹ŒrÅ•·û³ë`Q†Y˜™Ç®Ú”,t®s3’ıi{WlPú¶7LBçjqÆ­K"cÂ´>XË[ä™ä›JùåäÛÂnÌrÛ $	ºô¢=ú³œÍğŞ?TŠF¨kğ1„…8lf0—ÑPá³JiÂÅ½ìnÜÉ÷1y*Üƒ××åË¸dè9"} °5Ñ9Ô%ê *€La#"Ş»rğ™
ÒBïÌŸîåœ@
£š,	µ%Z¶Hö^½ğ±5åm!Ìq˜€ÿ¸+¸jíæ÷p£õÉ,Ù;}U±ı´ğ8›´ù'<Ú¯ğ?”·øT!jCÚådñÎÌ~'i”¯ëŒL¸sŸ!U¬yÄZ½2>“µ[Â!K
˜çY¾aÁ_í«š¥Í)+k¾ïYôîw¨ô!VÔ¸Ò¤[kú†¢i˜ÜÁ©¶H9B9~ÔÅ&£¨ç%,¸²pdîí¢ÉhÃíßÂ–	Cš0[AƒA––pd¡¬ùÅ¡ 5†í_,éYÆ‹@.ê%¦RD««-Œ½|Àgªà&Ğä!/æ§ÁBáìí¢ÄŒÙhÑŒ.+QÄq.¾©¥åWWø~”pÇäÕÊ×ë¹:‰ìboş¨1SHÜ·pš™áê?§l"ZŒfÅKUú:ı:)ïiè]â@¼ñc€Ô·f­qÎÅîâa?; CÀ7åÄ{¢®%Íî]M¾˜i	4ßY*R/dŞ¥š®MŸ»‰ë MgŸ°ópò™wå2á’ÊøZ£šË Ù,˜ÇVÈ‡/cY »‰?Uñ0£vl(ˆä9Á.\‹‡®{²Ïã4utÚä»ìt?	{RTñ÷LhR—«“Åâ›ZY‹üŞººó<GÈì¢½÷Top=ĞxÕllò±©Ñá¨aÉ™	¹áĞ”ÄOÊ¥Ù°É©TrJ/„Ô©¶”$¿à»E˜ªpH1¤³¡[:Ü->àsàòLuªİÓˆ(©Î¼ÇweÛU,8àì„fÖâ%¸Z‰GÏşb‚Ôšğ&m¨	ƒ„#t¾ä¬^o¶eÍSPÄ<=½¿bÂÒ¬.Í4‚ÂŞRÕ]ÿ`‹Es~²ê{·
Û"xQû°.O€Å‘k$3‹	ä¶9áëcYTöuÇŠGŞ l:ß¨@üÊ¹ÃY$X?I²@Ü¸0Q§åaÒ¦ÜxD¥NË“…›[o˜ÏIç&¸ÍL²Ë­~ÆoYH–ïV­ù+âæÌ£Ò€HBUµ'ei40ÅüùñN½M–¸µü·İ µQ>šnG‡5æv>hïû9céXv¿´nåZíÍ¸äRñ«
^Fó4(’°Œ±öMÃ®šó¹N¢2¥¯dHÖ=¯M1-•G©Oé·ñE]—‚ë_šÖÈ¢ªrK—¥ì [2§K›§ÃñîÄwK³µë<ùim[‰}…u
ŒuÚãüò›-à| -¹ŸÂI}¦®]"=oÖMÔÑ$"|£ôFZñäÃìÚëH,’ı—YèvµVåßøv/È±±úWÖH_l¯ûÃÿ€®Gœ¯¡M ôeÂg9¾›zíc‚ÅöŞH?4:ñ¥z;½®Ğ“\KÉ1wØ+(n d²ìÉd71i1Ex{µø»Ü·K0gîd™i­ªCÏ†{vÃIˆcVºw'›ÓW»ÌüæYedÄ­VÔ”>ïàäøÒbéûU8j›Ø[.¹‘şJ²¸¹±|‚üIÿn÷T}U:Ëîn"ßè+Ö&;s:ÅIEŸYTÉvbßì—?g*æ÷ Rù—`…ég!²¡Ó‚Ù#×Ê,%—-ÙöíëOöa‰¨­¾ï·k˜W%ùÇ½’èğ>K5LU^L’ª·† ü‚#”O7GfµŸG.®Bº¥&é×+ÿ‡ÃÜG')yèÈ(ÀæF†%LOÅp ›şªSÒ…ä^á˜¸?0°Ã-]öõ¢·²âW	ÖÖ­ÜÍ}¼ Œ2œfåçÖ,šçÇh ’ ”Ê³q,o¡¨Ê±½Â3Ã —# cn)/Jq
£ Ìæ›cÈ›.ÿÑT ³= Ä4¸ºv-gEe<Ñ^NxªæäÏ-ÇHò¿1´)yœ×@É±‰x˜§äííwú¤~bI>›)¾FR*ŠGãYÕ8S£_FO]t9®¡½xĞ[Û"cMÛ_‡{¦)râ®Ç)ÉöëªC®i¸c¥Ã6¯1,@Ì¶$ã9ßw“®BnÉ[Ÿ²n“D‡ívR
ÁÈT¿ÏÓ˜Š iM{b´p!L:«]"[2³<õhçªaƒvçŒm§ğ\@ù¢ÜìO»‹›ÎA()I'ù«®Ù=T¹ËÄ¼zğÀ^|D†èÈ•‚éLYrô€³qÑê¸œÒrÁ‰–]£çsQcÜK§[óŠ%ÌnÆ*cApj¸zêÏ¤ÄA(1–d•*7AŒmZŸbd•xİ;üÏ'ñ,"Š¼$9şë|ù2Ú…Õog0rGm‹Ó+v|`ÁˆDÎcøg¸%ÿ9–k{š;€@ŒT"¸‚õ}Ô&€ 4o´ìÑ«&í@€Jî¯½nrW>æ/¦R O£ğÏI&*5Pß]~y~Ô–5™Ü °;0êB<Kàö6¹wÓ
Ë(]ß,¿'Z#5Ÿo6ØÍ¼@«ëÃ•kN­à°®OåâÄìgpæ[„ƒÕÒÒü&ÏI‘ïO€¶ÊÛ[ÔÇYc_Ùs`C–Å')jß?ÂŒÓÂqs%ÀOƒJwÆfåä¥Jyˆâ!Çeèb&h«æo?áä`Œv×ÚÙ@uˆ@Š £«m¬ìsåÃÂ8ï€S§0D‡ĞÖsŸ¬ÊX%“±6ìY½ìaÁ€tBhoÇì$à~ÛX/à¶«õ3¯äğÚV¼íØQé’U_… ÎÄúißÛmåÿÀÈû5ıtìz±Ä á®pjÙrë]×+*$ømlWË2æjÎğH /qIsœT|×uºN?Î‘juš”e†tT¹(9Zcì¡ÊÅb®÷ıW´„zjÒ+pÑÂ·h¿%M–í;s¼ª K£ıW”À<År9–O ÊZõÑ9‚)?Y9oPzŸ ˜¶€1³áî_ñUî(`µÊ_j(ùï^º«rã°ã6.°ª ŒålrŠt1zVD¢qè¦òkQkÃ¿i†ƒ³Õ3¥JŞ
‹ŞTÓÚËØ(”àß\[+[Ã‰åS”ßúqğ:¡ñêcşàGÀC!°æZsà,¬wWWRÂËªpõ‚“àE_t*¡A0ÖU+¶†ßv_-ÃlE-XIŠ† èëYˆ›N«ä ãíñâ³KçÍTœ#Úâ;§ñyü=Mmåƒ5÷ß¾k$r¯²b~úb„æ\{ß‡'aP‰¢ï‰qÏ<¾5ÖÉ
3ñuç]û™êx"ãh°•]i:¢}«M›:Ë)P©»Á©éG«Zƒ•”/í=-‡²9(y"YS_£Ë™DkfèÑõ­JU'g`±çöê·y­º³ÎYEÜ:F=Õ¶»¨‹¼»aåÒ8j+©±AhÁ@íÃUÉèİj	ÈGÌhÒI‡úÚ©¥‹lè"h¥$šõCl¶bu‹	¿E¸6kô—Ë¦!êÌØ(Aùˆ:S+gx÷-"M±;eoxğş{´Jıç3ìØRPHˆİHó¦CßõäKğüª{Dm´ff)åƒóxÆ[qÛ…¯—n&/5:jX¾ÿ‹İÏXK¨s†ß&µ­ÚœºÀŸR4ĞKOÙñ¾KÄÊ©®_ÿq/óü™fr œ	A±û¼¡ =¢XsCDB•*EQqÑşq}ZÚÆÚ $¤ìÙé™"¬ª%¯xq¶ÿj®'
‰'™¶­Á¹i(ãŒ’pg¥k„T|²<;tûbqocüÕ—H|Ô™¾îı<"ÖÔ	Ë>Ğç™öè©¡zlçÇ§mÏÁŞd [<¶E'Z0!¾'àDÖYı¬çé4µWåè®êf%Uô{R…lIòk,Ã¦¶6îIwiVWÔ²Q¿›Lbæîˆ£äøWº^´›$‘j‹”Ï›ë/ÃUUZ86ô÷…é>æ©‘\’Õ´)íl BmáØh =!(­ˆ!RÄnKM/Ôê`º6~$¶°t¡GşóO€YUm/®á8Fyã>˜«š€J+x&º)'®ÿ¿ÓfşA6ˆ½œr‹‘†éÑG¾vÅ3Î<WªdïÃcHzÙò¼Ìª¡Ïüâ’ÁÚ/vy)ÖÌŒ ù›(­ßµNŒ˜«{t]ÿ®ş½i¾¿dk?å	.—î7,™ßÌãÌá«‚ª…i ìºÌFÿôPpVÒéÌXxc¨É!&F¸Ô0£æª	ÆüZû:ŞĞ9§@†Î|1ÆÃ AÒJ¸*g]œ.ÄÇ÷`F}¼ÌqJ^9yI_/;°Â3áYz‚ÅÇy§w´×ïAz(®ÌìQrœ¾”[8Â‰¸ú§{õ[Ô2ñ…‹N±Ÿ£m¡©–tBÅ y^ñøVÓU’®Úâ{
iMMO œ2kè›³ñ÷”-Ğ ›^|!æŸçUiïÃŠÙÍúuˆcX`­­Âšˆ«‘â|×ÂDÅ·S†8[éÊ ˆpw*´ç3‘ÛOåGJÜùë WZşªâ½Ä%1 8rï“5yòeàHFi@°†£X>t·ŸúÑˆW_%¥Ù²¥'¢Ô8@~?ÑœæMå†ZØÏ”7KSù#À«öŒ£”ë%=ù™áİWb­r>{äÈŒöîno×DÄòŠµuLsÙ>qkbk™ØŠ¨¡†AËºî•À;F ú·¢—@ 'µË ñšÏ"$Éo ÜeV0“æ—‰"†•oD}LŒvÍCõÏB1úğÈ‚"á­ãï`Õ«T d–©²˜íŸiTü¾ŸÕ'Y>zİíò~_ª‰7ã6#î»0_ÓzéV=BcëqşØÈñô3­3,HNxÀU3õ ¦Ò{‘"fñÚÆîH[ëü6÷Û«k\±(‡ûÆÀØä-ë/^HNçıÃèíµÎ8Ï÷³w(Ì\Æ/íÔ‡¾ZÃÅÆ€ˆÆªùW½íÉ8‚|kaĞåÓC :>S7^‚ÀïÍ&QÏ$ÏÚ=¿A¬G›Ÿ¶ø)
U5 C®õSB™në>µ—ïdHn·{,G‘øŒ§A¯b„«áæ·²o?°¨3Ç˜ÒO“ş“£T4Õ:ÉëÛËÌçV°AŠ“âb,•
•6j¾|z¼.1nqÅ}ó*·#Í¶ÓÈ¹¼¯#¯¨º?ÉêOßÁ—ë'½Ï@Xr¸—8³ÇpK³ê«J½y9ôŸdªÊéˆ;İe½3õ½]ÕŒ{Ğ}yâŒÙ­ï¸óx´'AØ¨ğí}uÌÔãİĞÚ÷²Õô.”öøU
ÏZÊ=Iõ„xîÜ"¯:FŸ@zÚûºŒÿg»q\j”N‰—ók-²|£¼ğÙ5°4ùpÎ&“æG…UNÄ/í7¯€'Î
3RşØõ¼f®¿:¿y.…‘„ş–‘kc‡5ë‹ŸÎŞö€Öå1 Ï×ÔÄ@õ?j©©-‹%¶;%6V´\ıõŠ¯»SÆ–öÿşÂåñ¢ş`äÉ*§F²üNş{ìz_ GàÉ”«ƒñ_ùwßçu*u‚¤¡økL<ÍÜö!ü—ì±rg<òİŠÅ"/Ï©¤Ç™SØOì–sİ‰Z	²ÛÅàI»U©ˆıÚâK3ræ™³¬»Cb>µ¾ú¶#<õDÑĞY±q¬«ùOw¢2äı´ËCbù#ú“±®8ıšM¯İD&¬À+_L§b°L»£g$äá©»Ş¢¤Ç§eyï¦¬¼(M—V÷|«t[³YVÈ<p÷R¨gåP§´Y‹MƒH] SA§<Äº*Áƒ},¤XöĞç=Š#-eöM(‚R¾ù¤èîHà)2ÌhĞ°iiô²şº^ÖÏÍEfk@ú^øÚk°ˆÿa!*2åwü^ÛÃÀ£”Zv£ªàu0Û(eøßÅô/+Šœ‹˜D~T[´&˜ì$_€‡TªQDz‘·‘¸Æ—¯©°cV>| ’OdöŒ È~ğÓÃõrxŠ0ÁÿÓ‰éßŒà'R§rÉ #±Åşë%Ø£Æu]({ç« „u^Gkè`¿àÍ]kğFî;ÉïnJÏvĞ?„¥İ›NëÔ}r‹Öd¨¯QÖåÑæÏŞÂ"«y]i·"…EÙÁ?ÔÙgÖoã«EpB4bFx	ıœ›š;v$3¬£#ãb27«@åWOV&÷n}1SBí(T#3l.¡ªR†vX÷Ä|/Úâ5»&Ö:w€Ø¥¯wñS¨Æ^ëºèÅo–1‰è zrnİ°™ *MÂTÑ¹9¸„á:Ç/1hhüê`ÓD!<Ø_d^‘ú³Ê®{ĞX!R}U¼•÷¾º2èx©¬u—š.'¦
/Ï=¾óÀ²iF˜nƒq(Ğø—Ø‹v vËË¥©U8'*9ïã Z3u¥ëPX7]'á)dÎ É£`Ãö+_îÂ!î£Ÿ[ÒÕR™ĞkàF!Ù‡›~*Oø VğW‰öëfÈİ·Ï&&$ƒkë"D—™8ö÷»²‘ÜìgL¾ŞéÿLuK”¸Ùû££ì¾‡ŠÔmD*‡ß‰‡‘Ÿì>8ûh¦‡ÿ½Æ¥¢œK¦Ö2ŠFÇİ1ñ@Œ´È¬+^/ÕÎL}2OOY'ukChŠ28^]M‘J­ má[¿şşJÒRááVQŠ‘ØL”–K8è ¸nmÎLĞê@¿åµ¾ÈmÔf!•|èºÏ+Y®?Ï´ö×CÌ‡ºg´ÏÉL´ÛWYß¤ŠÿRtt‰ŸÃ¶Ü•Óum1.”ax°‰ø•{Ğ…Ğ=şÎ«éBæooÛÙ2`*ÿ–Ñ–›D§TjL„xÔÁ¡Aıp#Ö ïÓ,ÿì!ôÄ‰_Z‹6‡Èí»(ÏÚÂSˆ ÍĞ“ı¡ÌX¸àm’p£§¡ÿø=Ò!ËX_ãÄî! øD‚Ş‚èä@k­5OŠÂOLa]°®šš]r<Û².ñ¬øO#ù8KO\©wÊò¨`c8ê=gaµnéxU$lÁ:`€/~°^Ík(tĞ°hùàÄ æ·ø¨æ/ˆ/<6¦5µ§ŞSjBÅ~JìO3m¾Ño¼Ù$7Ş?âƒ™¼+4e¹Ç_Z ‚`á¼Æ6®™‡gÛ¤DUv@ıç[vÀ#(‹¾ÑUFÈí_,ç1cÚ³ÅOÛ³‰_¬I¢š(°¶S’äõ
~¶Ú¼Uœ øÇfPª‹rjBš=„ƒ^EÛÔAÑª_-Ò{’êkÔ2l’º0©9œoÂ4âhâ)â×KÌ† ÍŠw	€ŸãËzÊÊ.+U4Øn+ıƒµ ¢)İ¡;ğj#©èFTuW%×…¯b«Ò³í£*úZ[À’ j>ôÚ7Åß-ÑÆ½U1sİ‡zÆd³àCÏõ ÿÃèe>9Œõ­ñªër[£B=.ìír×
µ45dËn1ö`-à—Š5·¿	DùÎêø:øR‹”gûî+E\!‘ÿ)æÓM#¨6³¡ÑÀë leéTäË"-Ó#¸ÀZJ‘¦¡kÆÿæÒ€éÎ‚h°´¹;(Z1I/ç2Qê’YW%›¹2€éû…ÄûÀöªçÑãvÚØš‚ohüis?rN1´Dı,1¸¶şªÃÎ`AşôåëNTÊ“({lµÑ±œì.Qµ<cGV«›õv mıÆÖuİ¦SV&?bhzÚÁ0Ü÷¶Ö_"ü›§åƒãZs]>ÇŒ±
¶-DJ¨úˆá@JŸâç¿O<B±+tí”›‰Û£@ô·¡IêÑ¦F—Q¿ô3û_EA./Çııu$'@z™y¦:ûƒ¬ 8©¨òFP-x'¡Í¡&ú‚‡¸o¿Övt…:"n,ş<¥MĞæeiX*XÙvÎR&%_›º-©w‘BHˆ@ K' k<’/ëã[áŠMáÂ$İığ”ÊD¸' Â£ŒîAÈB]Î]Cy’ú
»>!HåëáÛD–3åªéÖo	ó9J
‡JqJR›­Pq8\k
ÁŸŒìMAA)ıÕp²şêZ^Pı£¤ –/[¯m}îÔÿñ'Ê‡‚Ò®¶İM¶ò&8m(¶>p×q8àßğï¦V!¬¬h­×Ã~	pÚ#c4N‘{¨>‡€äø¢NC:Nˆm“ÑşÆƒşÙ: @“%4O¿kc%/ÖX™ÓS€cs;áœÏÒˆ­İ³xYpÍîÜí€EÁ”Vßy³zØ_ æç”Ûs€ğTu±ıÿ"R±˜ïÕé¹²;]l›h•BGş&NV£î)¹ŸDt®şÆä zºì‚ğ¯ •Xª8€ß2Ä 'äv;V÷!
.¨âí­^#5Jw¸à7£Z¦Dvg9Åæ¦¶Zì&á«±Š±0Ô3›óË; [ª@æ%RN= ˜øƒÅú‰1âÙºÎÛî)õñÖ'Mæµ*kè#5ÓšÆş.9Ùºíâ&%¿c/›TzH¨XC¯?hœ0…¦á\¿€€¤*’Çöà³›TDÊKîÁmt½{ŞŒößâÕN:Ã¬\nR_jNz úg÷0ßªD Ü-Š{Dc·z}:U—YSé™`´‡#µÀÆT˜Àã³™šF4‘şøH‚ëôúyt¢²º¨[	÷’Ô(‹	&%¥ôû©Ç½Öáİs©ÕÖ5Ëƒ*ŸÅù>SÊ) æ`³²4 E[Ø*ö9ñ‰¬‡O
?	¬ù"—®-€å`©¤]kW‰O¿Š]òÔ! uŸ€ÒT•!w#¥Ó§î¤¥8ï‡Ñ9gbØL3{>¹ŠÁ]ú³Óàö´8ö‡EÂ 
T¿ìbÙ-¦³¹òVÏf(7Ş4OÉH³ª½ÁSÓ’0E*O‡H4Š6Vo!qjø™£…ö^†=Ë3ŸÀµ¥¢£lĞ~¯“5›¡Ö¥¢„Ì,˜`¿z]Ì,<·î•şÇ¥ Â`-•3 )$\µ$¶Çˆkï„”C<×$ÏÑ‡Ô
ÎÄaıñÓ7§m•!îíè»Ê7=·ÄÏ‰úgD˜jG%pÎäÜÏ§"+P9—å Mİ^‰nßø	uÏì	¤±â2oQ­dB¦C’S"¥ÙT)-ÙYZšGM.d'‚I1”¦/€Ğ›ıİ¨>F´ïu9£
N®¸ñclœê¾âÁ®2Å~ùI»\NÓfóIOŸÍ’Ædşú“.šüˆ× ¾òÚÔ,ùÑDÕİHzìD‹d}=e†,@»x"ÉE‰ÇÂw¿.dí%\/ÜQÅ÷ÜhÆ–@·çw›Ø%ÂIµ”o  )À5÷³êâÕj«­:ún0;â‚æsÚJ¬ÉÄ¨4n!hoAò&VÅìs}„{c1ò"¨`?˜ šPŠb q{Z‹æJwˆõ¸õ_ò€Û Vp‡Í/kg\ëhØà{p'6ï_  ·Ã¨óÿ—æ6XôÛˆLŸPRWİÕæ$·ÇÂö=ƒ(N ÙË°Háš<òåT“B­¬+³|
	şo˜› ¹àåUÍœá(U”´W4­óÍ&Òp‚ó8À’‘òíPg¹bµ­†óUäàzAyäQ›ÙÍ’k…ÿµ½Æ°òR RÙ‡>]M/+%Ê©…‰ ã9G¼¼¢=‚SŠ—’Aún@€r†¶óûe÷$†Q­7±Æ§4Æ1¦!lâúĞ#şÃ´!©_¾ï0Z¿¯ì-qÑ,¦öWğNy˜)µôvc5Ñd¨öƒÛâpIï3/³QjÒËöRh.ùt    -áïUB® †³€ÀÔoÌP±Ägû    YZ