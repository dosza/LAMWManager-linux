#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3710175462"
MD5="5f2e090a1e5945f41959b02d770e30fe"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25548"
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
	echo Uncompressed size: 188 KB
	echo Compression: xz
	echo Date of packaging: Mon Dec 13 19:29:59 -03 2021
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
	echo OLDUSIZE=188
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
	MS_Printf "About to extract 188 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 188; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (188 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌâÿc‰] ¼}•À1Dd]‡Á›PætİDõ"Û’P›-æÿ¿4Ì3q-[_=úñ™•ÕÓ–*ä•é&‚ó:”¸ºd°YóšÅO1•:¡õì/Ï4ÈdşÍ3Úƒè7ø_ÈurÚ¦Äî +–Î{òWÌ6Ûgû».Eğµê#“]ŠYN×5ŠÑÎ=8¼sXÌjBg³¨ô'\–}Ú\:2Ë}Övú~cÉëéxåøÌ^H‚Æs‡z•mØ
àéTæš‰à(
p\?×Wˆá%p™Â· ¾On3NÖ4WğşXH¹â¹Ü¸HësóšO´$îuÖ¼Ñ—›Çaûº\3'©e‰iÇ°0•»ã?5D! 4Ø‚ç¦<¾ÕQ°ÿ}6xKó…^°‹OL¤PÕO“¬Ş,AÅ´U7—?Qô·õ&º(_ø™‰á²lTµ R×€¼ÔÑ¸s„q>"JFB	ò?Ç.±.Æİ<qKšêùô‹<^ı±-;Æ&írBºL!Ùdúçl—Ê½0¦ç¡dHĞxÆ³×rıÍ°q õfûú¬×â§œşØãvÛ’•%uÅPØâo³İĞ&c&æ:‹_x¿‚Çö£C/wû1u‘¬b¥s`9 İuÁ
ò$âêfj ı3ª3ÃÈºÌ#NÿûQ”éı$9öAÇ6~%ÊN/  uh†Áw,…­pRÏb0¶ºf«ªšA6raU¹·çg ,¬3‹3¤N‰Î‹¾Ò†Yjy¡šØr³T-,¯ĞæsŠdğˆ`îT¿2â$ú>İõvf±Şò?AbkĞÀK5¯6ÛÎ 6óß÷ŒğƒÎN¯ÒHÖÊ…-ls;E¼‚VçƒOËáWGj¨™şşZËÀ½ì‹ìÕ£òuËgæ×eÜ­2HÇ«ø•€¡ª¢LèU7İÿB¯İ=ÚCUîç=}Ü']qşÃ¢UUv‚ÈN¡„ĞÔtÛğ«§ĞÆ‘-!h~—KT-h¬œQ†rh0¤ÂÂaÄ|~ÂæõÁmf¹t¡Î‡aW{)OíCjkö§Û…ÍËÌo’ 7F›]”Ù¹	Í‡>Õß„G2<Ğ+SõDô:Ò3ugb’9ì/p²ø“ˆÀ¥w¨’:	şp| AfåhÒÖ'ÕÕÂûŸš)ÖuÎ0,éÎî—GÈö©

¼>·—~cÂøŞ-wÔeè«|à°X•¦ÖK~dÓ
œ,—ìR™à$²5DĞàâ/2/Yùy&Ôí^ŸÀ6+¿1¦ÄSäN“‚ƒOwóË¶CÓeLÛĞXí6¶+,ğõ„Up¶JïŞ´PìE{ü‹şX²zF6ôá‹„Cçâ	4:hIhÏ\cc÷7vf2.fíÊkçëô·[ë5ªÒo°Şêú]	¸Ó-"qU/xá:$WƒeÊâ$?@±Ï…ıVôRï[v oG«0½efú¿0-wÙ¤=tF²&ù…‚)ÊÊ]5é,5ª¬Ô†Åø7¹—@÷f>UtÆûo/™†¥*–½	Ë0 ÷8=´ÌÄú÷ëíùÕu†Œ-w]iOQàFî{Wd˜ØÁÎû'M!A²PO…‹¼ù ø¥O/©‘'õ$«%yzÅk@®WJïÙ¢%~:\ú‘Ív[?ËÒ 5IGP¦+ÃÅÍì8nU6ô2¹åE¯ª²­6K†ÑVï€ğj|{Zà	b%@wËëÉ¡‡ÏêÕ,ZCw=³‘›Z4®ƒü4)PÛh!áfòc¸¸?#áy> °^gìûXfÈ¼L’ÆS6I-XÜíªÍåZö  ¤i®~-É§íïî¿d+6À}è6¾!‡ú $gkXK2¼àš(}á¡†A²+WâHÔ]H óş ?š5ò*ó¡í›/9˜Qt™=ë\{Œ”¼°='t×EàL¼IR<ÌÔÏ<Ş‘¹ŸTór;7ÆÚç(ãLW«{:€da¿×+Ø¨¡Äg/¹ÕD>èö=Ş0xª¬"ö—Ü-Nà×¦Ó½8Ÿ¡m+©}¢pÆn¿‘ÜGµpuÄf·0"]¶ªU=Õ¹À'É´0ÑSÍ.‚ÕÖF³ä=£n¨-%ïhoQÓ­YqÔ¦˜Áq¦§·ğtrË_$İy·šØ_‡$:Éİ:
'3IÙpJ¹V	E
*Ô]Û4ËXÖm.I%³Şš@U„¿—úi#¯Øe¦–7îƒ½Î!LÆ—ªé+ŒÌäù{ô¦Ÿ
6ŞöØ*f¯½h4,·ñçdm/Ë]ycv³‡VÁI»fı¾û D´,;î®YmÛã=<áy®’¼TøOA×A”¡C_l{¦”ÏwËÁv×íÛõÚú„{ŞÛÉ¾ö®Ìf-µE†ßCˆÍ%Ğ/>¸ ®˜¨š\àÖ1éÀ´§n–Ößl¡$ï’ú ’•µÔ¸Ï÷[dAyé½†™‹_ußÇz=q—iMŸ&ç[òÜ)™B)+ø#f[ÎoË]R)fÎ¢ö{ú‡`9âyPÜ}Èhúf™4·†kc¦‹øñóÉ(¶f“×)0‚ıd0	H±D[s»©k¡ó•’?_„-Ûı|¥!ŠG
Ê~Úã—"˜eä‚¸ß…$3Y»)´Âi£ú·:	¿\}­±“#ù©#ŒDJğU˜¾­+yÎ³ìó6B^q"duúÏH—ª÷9ÿ4íÙûÜ	ó…ª>Y4ô!¸Š-4ÛñN@2z¨ƒE†IªwÕ×B61Æ\YDµŒp7fè'|{~—¼”À®ÖR¥ı§dÅ…’À6€¼!NI:æĞ‰LÀËı$ËáÈZ]2føs‡®ŞXLÏ~¾µ{@ÆÎz§÷˜.oŸÚOä:MZïÂ‹ãôÃ¯é¨n²ç */6(§qæBë
4á¿xşRóLÙ3ŠÔ @ xNK[Ï ÷ *|út¨İÑW2Fé9lÂ=¿İ|kRïò3ÓkÆv’xiËè¦Nùò7¶ÙdŒİ•íµ§ÓM8‚uë8ŸÉ¬¢I’ƒËoÜÕ†Ã…§jd@ú‰ñúNUmlßÆ{ì{ËìëÙÆóšò¹f€G‚~Õ¿?‡ÛKo,­;ú´ 9~n§M¡$ köZ'©V‹‰£|)R-‚Ò2HÖ4A¦,šÈp˜Á³ŒÒvÛşú¦¿¡b/,Ó·Eº¦£e»OÑpê=lcİÍtf^]š™$Öûg?€;Í‡) ìräĞ ù¢,|¤Ë¶ù,Æ°™¤ôf¼/æêMŠ„ÇP‰ô½	Syå²ó§3ƒ•¢şdEğB0ô>–Û.Ú^Ú‡p˜°SÄÚÎGÑÌMQx˜GÚÿÆôá‹Ò–óÄÜW`Y'£/«Àİ¬€CÆ¤“206¨ æÊyC˜Ì‹d –Ç¾—Rué•–‚ûö„ "]ä™"4Ö–	§n’\Á¢Q®±iÛUŸa»ÛÃÈ×¦d}4É`şşÀa]–‘ãaïñCq9§#]œsy¸É¥sV ªHÄI5]Îº“æ—Zg¡ºQÚù5ğQçß[Y$ìóô†°†øi™l»üvAÜ=¦³ÄšGÎG/‹/"hâI©ˆ'=Iİºİû„sn¥(´Go]Ã|´®æ˜¾‹µö’ørŠêÍ:µ­2‚¶î²¸O6”v Àã<EÈ­šjº!\d!KPH¯ãŞ>^ë;èĞEhéf²5–uÿ€³™Q7ŸÚp:¸tå¸2aV°;pI9Ÿ
íãpOÌİ@«ªJ“zbJ*y¸Ã÷Èº®i‹HÏb¼‹æağ‚ËùlzBàAâ‰¨s¡ë8µ;¶«»­–j'·ò`¸ÀxwƒÜ}ó™Ñ"õ¬÷Ó*k™sš_usÔû·ÂZxtl'nÍ_Ë_›'£OÍ T‘[~W¦ñTŒ3gg§F‚Sw”­Îwxûº¥Ú=>eZ^÷¯èÃ²ÄëÑJû|gg@&Ìİ¥;Œ;~“¾¡_”;s½Ê§qÆ-×R¡àÑ*ö‚òu^€ÈsÌ†Ñ%DŒoU°Œkk.É#_ÈÇDZI*!şFÖQ®›w¥&;^€ÀZ‰ğÌºÁußGÀ]o‚“^nU”t¡£4¬];Bw†•uĞè†óMµéÀ)Ä\Í=jÒÛƒ‘ÅbHF7¦eCº½£Š[ĞnÁ.eeM×ÙÄÜ¿"KMtÅêU–©1·¢![-Ì„2Õ]›ˆ­3öÜ¥ûwó;öx™ê@)‘ÖzF4×+¦«¤àúQºu †ğ¼JÉlÃ°ø<öãâ8²Ñ'îd<°ı8ğ“İl7?lØ	™™ÑúŒçf\ı§-wª2‘aA. /š#üÄíJŠ_Ş_°·É'a/zuñ­Ğfîqïh?[*÷í:lû¬ÅsS×ÃløR[ZÚ×tÉ†LÆòÌJ‡áí1Îü÷\ô4{ì•ÂrVü~’ù¤aj”)‘NA‹ÂyÚÛ¥õ	é”Fö/¡@&ÜxœK}T‘èÿ$I‘·!“¤;Ã¶1$UøÒö×@¾t ÂĞ Ó7¡„Cˆ\ûÖ‚»à$A”Â ›*aHrù!{ƒÙíØÿì°úåá&úÎ´gÅú=3b6äqh„+RÊj˜2	’ªyEá$ğdåÿ6±¶G¬ÙÊ‚}9ÉEe\¢gšsëèn¯Ø3;r“M˜ß¨O%.qËşp¡/q”ÊêíèıæSù…€İ­{MÚ1ËİÛT€Ğx! ùw•‹MØøe!¬@KÓÜZı¿WîöåM‹ãbh ¿I+uB -H@ö"û¾>YÃÌÎæ>÷Ùê/<Âábg×\S9ÿr×ĞÁ¨r‚’qtÕBÊJ¢İ«DÈÿ¦hzDÔ<‡.OÙíW‘#ß¸øİ|;´¿ÕK{9kp8¹ÆI˜É«›İù#J¤Ÿ JG¹^vş>|›ßu1ÎæQóâºZuü%sş.Kw‰ãàæ¨@G0Ëyh£¼ëÆ×-Í—¹NÙÓ}*£³àv ò´uÜŠIîƒê¾T9Ù•5Ÿñ1ÇM¾KÂÎsØ•tm¹Ü:ğDŞ·¨E6~ešôáØ[HÍ¦×ÒZ'à,8`é”ÂœÁ N
èëiFÀ>Qg”“IØ×Ú?›5uš1Ôí»ÄÔŸ
„ÂÓÁÍj—g*GªX7ÀÄÂĞçşåö+Ûå„¢µi¡èë¼öĞà.ß‘ÀÈXÿq‹5Â$aÕ~Îİ¦ÁÈÌp+÷‰X"½`K/Í¤ÛA"&ÈÔó0ôi>y“¤î¥À€5£º«üI»%5hYpâÖ€|}â>¸ãCÒ°<c³ì^åd™°ôÔË÷ÆøĞÜ¤ö¼ŞOE›ÿ¹ |‰$Ê’EÍbuk7¦¬şí&ÂW¹´@OLØÄÁ&<‡®ÈG¶Ügk½Y‰6Ì¢	RøoÌ§`–/;8:¨D7Å1„G¢Ún±¹¶Äœ¯î»ºk§~œZXğ™ÙÛåœ¶ñ,°Öaê?{~_Å3_¢•Í£e–Cü˜öæSnò‘eßãäí±Şådq)om‰}ç‡’Wc-ê X%C<Â[Gx"”/!¹F£Œ(bÑ0Æ>-Šç"^½ZævØù0Q/:’ ‰µÊ\sšËŠåÔw2Õ”šğ4-¯IG”" %í¶£f¿6V¥Ï~a@AĞøÄ7ÏÓöò.—@Å’ü4ÄräI—Gz	ª®`Ss`A8©YX[‰¸”G‚NU›õ‚IV×zsÓ•)–T&´ØcÍ].1‰®ï¡	.¿·ª…Ó6¡¤«­‘‰h³ÌFÖˆ™.'Ê»øÏƒt»íKt¶Ì#h"7¢Ú l¶_˜Æ.ZÚ'à”oñE•Â‰áÙWpÉÅ®ı§Ììâİ‘ ø¢ZªWÂ%|åQ­ğ-Æ|S6¸«ñ£¨ÂX.£×PyL ©¯÷\PµÂ±#/ræ9úeú%íokúµ—İ€‡À¤ºfM?à^<XÚ¤œ°~S(ƒÍÍğO w#nh6˜%k~j-¨ª¢¿Zºôz m40ñ×P,—‹û7Nx©ê~@xx™ RŠú½ï>¿„Ÿù"­#Ñ\şTÀ_Î;/¬ãğOÂ‡:·c}šãfZ;bÏˆ,êyú¨bQ:=[Œİç¤xR{–uòÕ†±ï£ëE®~?'ô]xeŠ0J7¸êOÁµfí™[IDKb€&¤ÑaV”çoØ° Kô<Ü´ìĞ·I•/ìízI"½]ÛãÜÈs/J+»÷ï
®LšUy˜XÖSÎ›«ß¡•6Ê'äöA:%‡ØÂeö9Œ[.YœãViô¯3$æ×àib@]í+¿t. 8	òŒ5ifs¥ß`0ÌM;mtŞL²N`ô;G²iŒÒ~æK±\Œ¥.b<¿	‘aBsÇ)?’-PGSáöB•#›"D6Ë÷Q7pxØ= —»Â4)à@æ|1Gk¾è-"Ğ
”ÒÌìº İ¶<Ï÷6Ó2tã)RK~åu§Å¥<€LÍºŠp@eäµÎ‘ÖÀ2nå£eÒJ <>nsÛr›’€‰ÿ–WgÔF,t ô_û3¾n„§SÌvîÄk¦ıHg€Ò[¯\a›og"cÓ"»Ø›XY4S«ĞVÛÿƒÓ7ı.s}âõnzF5@®ß{ØåöRS#+å}I¦eò¹^ˆ$Z_‹şI`”¨—…áT;ÊU¡èûµŠ¹ ¡mVò®‡q|Sß‰Â|,‘——¿e¢h™iš3ÿõÚ»<íÉu›¤ÓqÆ?&ªt~bWâ2Q$LPzœ™¼pÊ§*
"¤Á©Cß½ğªÕrf ò="ò°[ëDşñ\ÍÊÏPÚ€¡/:DÆN_üg0+ı¦İŞŞ€#å¯9S_Îˆ*˜Q®§wÉN9¿èoZÓBÅäÉòŞÑÈÿ&XÇ0p[˜dDü®‹Û"Ê')‹ 
ÆdÁûZŞ°ü#Äo‡yï	øš¿dpEÆ(ô¾8gµáÊc™GÄŠò‡ğıÂêÖdû EÙêÈÊÕÁç˜~HHj_} LÍÌæ¬Ôn¬NrÔ1ãìş•[dÀ'ıo’&``Ÿ!ù¬%ÍZå%@è²%ËŞ×±r}vI$êè  şp½¥¼Ÿúš”"˜‚st^6n4°óV/fo¸£S	¸™»mñìË1'õ’,#=3#}ol¤Ô.Œk¯·zÁhtV·OûBGk©şèsí´šÀl	fêzš/°JmŞ©cA÷}äU„v´oş{k»ÒÀö÷ı Kƒë¿ä:ÂP›O{–ÕFêsW¤´àÛØòÏ'u—UÑ|-ÂÛ¿¿”I¬çV€ÚvÜG!õRìS{¥¦¯zdy])u¸Ô”6py”õ4cFeóÑ§íeµjÎ4µÀ+&rû®qLHÕØAZ­œ\Ö\÷}ËZÚªÊ@Õª¿Â§Ñ˜Š¶BÌ8œJh3Ğ{”pà~Ê`´ÍL®Û¥­W3Ôí´‹\b³‘96ÄÍô8×P›æ?"Ëé¤ß<OPôËÑ˜óÏŠ¡æ 5ú…
ú>/<{ È@HL©-Ÿ¤çğ•L¸cs_ï
·Ù^µãÏ…/2«µ3®ò‹ÒPSò­  uÔË"¢>ôXË6Ázã´¡n¼\Á>LzfIÌ4¶ì•Sëë®ùş®]Dräï”é·ŞoÃî½ØM)á¸7ÒŒ@6{—óK\'ªˆåşa~¾3 #E*¦Êä\f­ÜğoMöˆëFıH©|àú ¿–æI¨ cİù“?•àn@¶–¢¹˜î’²SJ“¯Ê„×±|×'ñGNá‘ÌÊ'‘İ:$ aÖ«sŸ±­îÇ”š˜@Tò~+Sa‰(XÁ¨ÓvV~ ¶¹öâ·ô ïÛÓ~ğuªM}®„GµÖ½è)è#JoÌÁ¶„ê5¹ºxœËHhÛ)*yâ8cw7íN«õ™•gqG©‡uÈ0ƒúğY…b‘RïÒ–•ñò`]Šİø ü=i{œìÈ¡²«¶(Ï»ûƒ‹{‹ÒQ!¤‡_áœu!ƒo‘+qAİ  î†Nîó¿k•ê'{UúÅ:\R82
Õ½~Š¹¡ó?üijãÅÄÃ1ñÆĞ(Ua¬J3ï:^[ß¸x2CO»NYA<)ÉVş+ièı5¢}´}¦|AÉå×Â¢,RL…­A3{ª†7úlÔ,#rId“õ†*ˆÑË@Çº•°]cµFÒ~Ğ›¢B”õÄ$¯ç.
ƒ=BIu“é¹CÃ…œÊ4Â6ÓìÄFÉd¥–s‚%õ³/Ù‡Ål\½Š0ÁŞ-	ÅÔ{NX“mÈx=QÙ‡*ÃZè%œ{>Øé›n•×ú8Ş3Ê›í\…¼(dH5ÄG]!zNøÓÂ^‚Xè¨hÃ	éYü4dÿvgó#MıÉ©•¤–ı ‰‰L@OP†¥­ÊU.BÒÅû4ñğ€Nüíw¾‚ê+Ó8]	<[„G®¼Zuí¨ê(“ûDGw$_	Æ}?V£«QKW†î‚å^"É:²mx’Lr{±kt|,&^üq~¤¼[z­7¢ÆĞO‹€&ê,*&N²ãëÕ¥ÈŠaN(ñíØ]˜—o·‹´šæäuÆ+DøÔøË~¶¨æ‚=	dÓÔ'2»/ş I–O€×¶NˆPÑt£ıÜÔà2;Ó,ùÔ´Ï’ıŞsŒ­.zz¢õÍÉ®Ih…:-Kîˆí2‰iAO~ÄZ¬y]5:•Ë=ŞFhª³óµªš¤´'³W;^šeæ„ğƒ³İ°BfSL"p1,E¡ìÒYÊªÚ&‡øPá'4ÛÆ0'ÆœAkˆ¸à®Š”ƒÀ2~Ò¥‡”)Äé,÷ğß8Fªx Dt¦Ät°ÉÍf^±RëÇ¾fMĞàMp­ıı§ÁälÏYšÅD¡şSzVe4cà"RÆWúö\îJµ#FÇñû•loüì,_.»©ƒ<²¸÷1ÛÅDn\½ú&\Íñ“iyçb=’“‰ÚH÷:æCü—
´Ymõqí}Á›ëÂåE»»!k÷ ‰ÿÊ‘^VÅßmPt~È9`C
Ò¾Ïÿÿ¡“â[ÏO7•2%2|»­© ÖvcÅ5³88ä]òg¼Ÿ6âÃãCÔHŒê<…Õù:¤óO¹wÃ§P©DL9¯¹iğ$Îtlj×ÂW‰”'[0°‰¥³Ã’¿e\rl“6Dôr"êZ\ûÅwŠ7@öx(¦O(#¨öméÛ&rÎJ´~'L&&§ŠLr®İ€‘R£f÷mUK‚Arxªë3$«Ÿ
ìÊ¼aø™#Wa /°Ô%ŞÕŠëC±ç§!ÈYĞ-tÚ<utô|öŒ¥¢Ê^'k{Ö¿ò(í¯gN“îHíÿØ7ïb>[À‚`épE›û¯ *ùUT>pVĞ\ƒWÖÉ@íc¾÷ê â¿:XIx,ÕëU™q$yàwµı¥¬åÓ/ÆÚ;pıyê‹÷»õ$qâ\x6"OŒ	ßŞ`É´ON=ºUX”c™‰ISó1ŠÓ-úhş_æƒv<ÀªÇ16Y¦K%ş0p“ÃÑ'2~|"HÊû++ïûôU‹¬Íj©ö{é+ÿÄ1q°Áÿ<2pC´/Î×ôØ­J 47—ì%ô`«Œ6	µ¹šmZÉa»x\ëp84e—oAÓ~gÃåÕV13O0‚	Er-»Ş‘¢ëjØ¾à6¸÷^ÓN;…vOÑ'ĞT€uv/kûÏ-„Uv'´IùaK¿ª™?|…^ıPÊy¹Ã¼Z¶‹ícJ”i¥””åÀKkÚm/€)C:ò5¹©‹ ÆO†¢YMnorNá¡wòë_øæağ«û0Ö‚×˜ë£Mû û‡Æ©knOt‚RhÑ¨nÏ¾tì4	GYÈğGV0½^²j7Le(Ñ+…f(ÿˆh©;AtRª^°¨Ë©‘%U`Óc¾Ñ±9,z‹Fhò¤>nV
ğyZŞeÃB½Ûí!ÁØ°a”xkÁƒCnÖŒ—]Dæ¤Õûˆ+aTÎº–MÌçkRõm–XGñ¶æå 4Ì˜3m)¬ÿaícI™ñ—†‰.¼8~Ö z4ÀıæŠp±@Çµ¸Å°¡ğ¹2ÜO–êı0|µWÄëügÛ±N£³ ”Y«¤Ê3™–Ú¼xŠJm¿-uz¹¶G:%¸Ù#¦"ª$h¥ÁÏ_luwŒÁ‰Š;Ä; å?w*ªA]/³ü§;¼ŒÓÀ¹dÇ6‘×¬ïµ6ç1A9¥Uœ&ùÊŞ/÷…ªgÊÆP¼Áïy¼à»ˆpÒ-aàÏñºÜì	¡ÂËóÉHf·H[Ïñe]Ø_
=«qU#”W~¥‹ßœß§D¦œòo‰â#ù8°Òök%etñÊÌù;õ™÷ÔÙ«b—=Í³àğİÊ¼ RL„Æ!Š4 VT“^dı‘§ˆhØV*Êb*¼üÏ>’z¼’âY¡e¤Fê”ñO0XI,¡F‹õ±3.ª°aM¹.ëÌêOÜ«ŸE ŸÖşSÀ‡ó„u¼ü¼4éü&«ÏËMSÂLÆ±—zîªWr£ëTO†·†R„ŠÀ^¡yö>VwP0‰óDŞÒÈ›Eybj9ˆ3[& —Ò¨wf_MCgh„eÎªã±R¦úY9o™!£©\brc	"sjâÏš$tÒUƒK°˜y+/kÃ’<ÈÜÀWƒ9*¯t‡Rç§Aè˜8ÆĞW'.İK|°òİ}o4'^ş}ƒL]>Ğ1#µN¥0C	‡Uy¿]½Ül‡;³î$Î—•üPÂDqı%œŠ|Ë;§“¾†‡<ƒ¨AØ’|ñr3/EvOö>ÖÛU!–F°FŠ¯òz šßvã_÷oêŸZ^ŞwØªÆÁG«¢[j5#FbvtüÌ(zÛ†"È ÎKL gP
Iz‚Äx¹µ’ÿUœ´Ô¨‹c*‘Š|ê&;“ºº°‚ÚfA[´‰_ú;¶ñÓå,^~8æÖs@a$N¢zGz=cé_”öœÆ²GâS>æa=öœÆıŸª²ÊÉòÔPD3wˆvíPZl÷õ¤¨“Gå Q‹ºU(¼WvÂrÛµ§ğåé–Ï(4Ü)?¨áäF
!?6$B§ÿä›oí'Î&8OÒIô…(âti¿|ù©¬iÓ×ôKõDv‘3²Gñ`ü¡*‰Àã¦‰I<á¢U1Ò%7CÓİlgø	¿É*£ğMöK	‚Œ›ì£Ep­RTÙF€ÕÌ9Ò¤$¸Í>KÚI†Ä)á°‘Ÿ[	×ÚîÛ^ı^"$‘³_K‚Ôğ†Ë7ƒZ‡.t|®›œ…Å8]»òÊÃÏ"Æ ]•ÿMQİ¼÷*¢ş³Şj‰Ó¤—ñx-µn›µsÙâÕä‹ìvæÕ½[øLŒÏUÁm–1•(.n7UøD„Ün*o†'Æ.ø²f|wj-ãr‰ªæmuœ¼! ú@U¥}˜|×Ü?Fn˜—j!Ş×\€Ç®½:ëdÅQ°OÍõ'¿RĞY5Ş0uaQq`nÌ‚Ù‰ĞVu,·Gµƒa.[ÇY†^ ¡kßÔœò—jôTˆ W±:`%„¸ŸÙ8Œ„[	ĞÅÿs÷hÃö™€ìò,=eª—mê–«;ÃŞGYUPÏ„µhV•»¢…¥Ì
?A‚Ë´Ï?ªs§àëÂ%¤_zÇqE=ÿT›y#¹xMìrt¢Æz‘Ğ9ÆNh£¦#DzkæHòF¥g·Æ/¹SÅ%¹5·Ğiñ©¹ÈÖ¨OúÖ˜¹HXåxÛî{iüe./'­–.ÿ™?bN‹QB/¢û‡4È“3¶Ÿ;*fóL<Æë•âÜ~ùñßœ[….ÙÙ¨UÕiyÀˆÊ®»jt*4“×¶ïå¦)¬âËŒÔN+í™gı—ƒW€H¿27Ó«Míól`-³]¤+®¶àaï±zÒ]+éˆMQëáÜZÜŞ—Ï‰’ó¯ÏnLNq¿ «ñôå ½Hğ5óíç™pT3÷'â;øğpÄİbİBß?×\t
 Ö¡ğCÀP1MM«‘ìqxÛZĞì-™‘PÉ.ÎÇBebd,.3…Õ˜rqóNÌÉ§´ÈÅêóÍ¦¼ìàO«ÅçLc­…|}ŸàşfE×Ö9q½¨CO[^«ã»”ÜN3–s9‰ª«o¦Ïôšîšƒ	v	ÒíWäÅ¯d­Ô™ã˜ßxìÜ?~ĞqÓ»ô$À¼Â}Ği¥œ™wÑßš—Ìk°kyJíCÏƒµ{î+?x%óîµŠPš”†•=lÃFÆ=JæË–8^F×Cò•aX}¦á™I&‘…èáY¯¨˜Éö±SS=?äHÏ;‡:ğœ]Bh0KšÈ®
!e¿úÁR'oş>Ö¦¬Úz Ò+’a+ÂmJÏ•ùÌ¯dNÈ¾1ğcaÎ×q—»ãîÿì7	{ˆSy!Ş€;RXjq5ßËÇİÄ|?ìõeOZpÙÏ)‹î•W”ÄÚ¬p´‰+2Ê)Aè”îV£øuæ›q–»ŞYR†í€‚éš½Gƒ:^• U¢Ss!1_W¢ŠÜ:ú¢F¬sqM¢kÂ—¤G	Kn~cÕAE˜¤şËb­~Úıàÿäõ!…µXªĞàÆ*uïåÓÓÁé¯
Ö8L6HãI•¾ª“-L¹‚»¯1²›‡y±±—m–ì§’&vˆ±ëNsÁäŠŸª‹bõS¯M9¨Ú»$x/:îıŸÃ³d¬0@Œwòpõ—v» 
èàß•²PEHoÿû×_lÊã °!ê(IßÜX¦íh™{¿‡Ër•{¨dü®ÈöääÏCWÃ=:Zo1eb•+~Ï½(ä'¨Ùáóø…ğ<¶³³‚ÆâµŠiBøc“ıŞÏÁR!Şè!L‡.*~Ú*Æ;B“ XÁyƒŒ{ìÍ›ÉJ­Ù¯ÛõYıj â^É²Áq‚ôİç¿‰ìÎÿú}aµ<æÛÉ€¹và
A?«7Ó [¹YÚ2—]»ş^MööV­î 2¸süæ‘K$2	âä_²íKøA›è_°è7Pî©Ót³­+ˆàà,ˆ[–bC¢½O>3 Mô—‡RÄºƒC—'ˆÑ»Û¦j³Ø'ÓÎÈ%_Êƒı­\Z›å×=$œæ‹•¥õï‰ãı¼«İ 7´í6y®|ÏQJèèè¨ÎÀV²˜%§-ü@Ä!À¸Vh¿Î O7}T¢¦'Â?]
œ¶d7†è{—´FS8¤|¯è^2ìbcLL®"HLªòw	 Êïw¶|`Tv	–óÜ°êîÉ†p›\C3#8ç¢-XQ¾ûSOEîúÍ’RğÚ^2T]+»ñ·`÷…%Öüˆ8T”,A WoéQÉwj"¡ íæ4CUäì„Èˆœ
ñbø ˆIo)£ ^_s¥Ù®ŠM%a3Â@/v‹DûÓzYíÙÀ¢3n/½”Øô®`gü=Ÿ³R›x(ÃbÍµ¶†ÊÎ¼È*ô™.æ…‡×§cØÁÍû?Ö•«‚ıAÚn‹éí|»Tí£iiûö•Jâô>­tLÀ·šY!Ëï"e ë<[í¹WWá£K@‰ƒs]a©ñGÔù/02ÑãÊ3{X£@+MÈÿÁkÑ¥ŸêşjÇwxÿÔ)(6=ŞğÃœ×¢\ğ„Ú†×½ïWßÑLQ|'Qj‡ªë°`†“Ò—líVÅ@EìŸ2¯ë·sh¾Í‰Ğnœº%ÀuÙpYõ‘7O6ŸÆWÈæ¯Gç	Q/zÏœ:÷~Í/a¡Ë[ÇÆLª9‡jcî(@Q†ê‡ø£ Ì6].hÃcÌ¢ûp‘;ò1ƒßêÜLIşd6§4€ åN~ÆtÊ€ä¾çPr mön8“ô°T’cåÕß§9bÚÄ*w"¼§çVbZnƒéÍ‚ç­Çj8OÀqÎ²ÁÚüËĞŸZ.
§Aò>éÃ1Š"¸1@¢P¨Û>£ƒ÷aqûuKôPÔmµôjXùVñX{N†ˆu’¾-wÎ÷¹Â±EÇ<ªa ‚O¹uC3q?¹ß¤7»¤Djë¶ÔE²Y`¦õv ™Yı'¯nüÉ§	.Ø^%h f—™„ÚÆ@ò·Z„¼ÀiÚµhæ%lDy(Ïù­×/GĞÚ•¥/º{,cmpCç(h.&€]ÒËº³ÿ ëÔxÂ®È/'"ÿF¤¾¼e¸¢Pò&dõõ”±©Ët_&Ó¶¼É@nNg µv®CHÔñ‡)éI»ZÈzØÆÜ®ùâ+¦S…Ğ¬À0•!ŸƒVÖÜ?ßü ÷ZF¸(Jó‘ÅD_"m6‘Gn)%éÂöà¶ l.¹b¡õô !½^›59™Èé`Ü¾ÛıJf¾İ®x'E0¢U}6ñòn,^Úåï¾•:C" ñU-íP¤Ô2fz3)¢µ­ pÈÿÉn:¥ê‚Öÿ¢/õ¼¤CÀØø9™9¼†ëôÁÍø{„E&öN ò²çÍØ.&æ´í· ³„¬ë«Uoe}2cªvÚ Æˆó«[lá]ä0ê¬)=Jñ’‹IË^¬Ê$‹ÃŸÖCº6ÅÙ
ÆÖd9„u
’‘9‘Í‰»œÁ¦ÈL~´eğE]­u‚«îÈÚ&ù1¾\eÎG:VÊòìëQ¾» 2÷L1èr=ÈV–€p»ì‘>÷İ{äCëŞQ?–İaİM’…X*†¨œ‚{B/ÔbkKxö
wtEmÏ~—?ƒˆ¨Ók6fĞ~÷l«¾ì®'E"m6À.á;ÂôÖ´ƒ	úD…Ú!à<=d4‘Qñ÷ë£MnÏ\	sşy]ë}‹Â>lz·‡ÔÕ3 ŠÜğŒnùQˆÈjs«­	”	O4È	‘|˜ş~¢A‰ë.T…k¸nhîª´1»»~9geaïQ¤çO0³yıé Ïı¦îÊ¼MY2U<„¡”(É_÷n#É¤Ï—+‰bÂÏÏvÓ×¡²™|İ9œ†3:Ş-^d;Uu³©ş`DáÇ(;Û{¢ú˜òŸ ¦EK‹°UôTY6˜¥¸±ÉvXv§!õ ’ƒø±›…f¦3&¿w­×õHèüº©mß3é‘•9•7ê0q<{–ÁÿK‡è8é?vÓµœÖT“QU1[`üeÀ|Œ†{‚˜Ğ6á/Åƒ©‹	„¶S·!¼TìŠÄÉ©Œœió:ˆmnÓÆ„%EG\"îä0ĞN+MNs	¢æôaBU[w§@Œ”bZV<n&•/gıšR&ÎîQŸ"ÿGó]å¢ggoâv;%`à_ŸŠQË\Äd¨&ĞÄ¾ÏûX"êÀÓ éoÂ…Ë‹£Vİñ”Á¢¿jÕ)”©É¾šZ…öß½§&²{PïÂÿ¦÷XÌ"×3B,	¶v7Ü_HU¼Ãä½b_¢jdéşNÃ3S×°Pİˆ³Ù¿Páœÿe¡øÂ-L¨?¶û÷+¦ZR6Á›ïÆX]ŸäÄK;Æ¤^&3×æiº*[ŸÅ¸tÈ¾°áOÑ*/2‚ CÓK?®>¹RzÅ»Ã™>F¯å¯iB"nÉ•ß`v¸Qí-ŸÕáÕGÎzDôµ/u•”œiØ‘VV lZÒÉ÷?xxí’™‚Ö`;=™… h£	½U&ˆ1&£á zŠgórêüËzÃ³Ì÷İ/fY¸øÚ3*;P»5üÃ=b1ç©w¡j/3‰ynœ²Û”¯5ø21/hŠ®’'$m
ßÙ9¨v8ëéC¡ïE?i 	øZŒÒ³ÆóM»'¸AP^(­‚„ƒyYû…óå >
'Lóï<><Ä
‡z>:r7s%x\› »Û]õvÔCÉù€{kjà/é´0¶û!üçu!Q†rƒJ0û¥+ÍGA_C\ÛéÃ5¤-ª7«Ü.áë\ìÃRÖÆ>ª‰ÿJëçæh-Íb^^RŒ„§i…¥ƒ3'¸€LæÌpZµº©5N±Â+#|6*ÍCõfDáš¼Ä'„,$ëz˜<&õ¿£VÎi¤œ„–¸, ËŞ¼!â¶Qkş}GíğyN6¡dÌô­•˜ï$ÅWDäv>áŞö!×ÃÃşü‘z¯†qıİÆxŠÍ:5v\R"O!Šqpj\of•òLôITëş„øÈB1´Ä’i}¡©Æ·÷_‚ÊS>Kæ»uv7(,¦›0zêëD0øa&”·E#ĞlµuJF‚9—bh î5øèõ	0™•QWšıŸ€†; Ê*#yğ¢Ğ€P™Š‘r©ArÛ·+êªGÆ©YNŞN»nÂQ«åÖÎË
pŞæšXæö‡îè|iàÌ2€î«ôi$’›¨ÂÍQÇ göDº*C¹&úêhƒ}MÛKÿlÄè³W!ºÌ–›“Lœ‡õó½SÃ§wŸöR6\ä¿Ô8sÄ6ÏuZ¨CF((Ñ9Œg	>Š¶Ó÷¡}ÈIñ¡÷nÖôE½ &}¹U!SøÙn×¾¥œ‚Äv\‡ÜËQ£´·Üæ¦Ó÷¡¸æ­Y´;ÿ©CGÈ”«õ•|©<Ân¨â'$6@Ş“h2ÿ•r/^5Í‡Ë)6"ÌyßtåzS¬»äãA½ )2œşØ´aà«O•·rçÀª½~vŠ&lª˜ŠQbÄæKğgÈÔâ  l± •¸Å¯X$	×ÑXpusœIcäÊÕCr«Åƒ¦LÄxË—Çõc(LÉ'’Î…L¡•CóE•H1VZµ<äçøßTÉ.ÑŠ %&²‘˜Pej[LƒiI?\B)È‡”"rò†Å<5ÑËƒs!ë+Ë9h‘ š«4¹¶z}@Ác³±.Üœ-Ô³Ç˜lI‘éb!§'Z¼º °øü9»°Õck'§:é˜V2d#AiŞsÏ¡Œ @Ì[ÀÆm’¢@ÙÜËİluö­ôîğàn'Ø¡„œ¦æ™€“na‚ØÁñ’^¶ªXÇ=®Ñ­8j¾h:Tª¿,“Á¯U°¬H³S—a´ö^@	„sPl%/8Â°¢æ¯ÿGÒÍÂŞj‚8Àâ†¡F³Q»”77FÇ,¬şQŸÊü­[U¿;£{°˜<‘4Üåˆúl>’ryw)¾ÄÿY4?õ²=ÕªN2W¤©ãä	ˆµ4–µ}nüàóû×…Ôji+£œ=N²PÃàŠ,gz·PiëÙfw®TX®¼ñîC"ñEÛô–Án/ƒ4.«Ä¯fE¸§xc¶ –Oäº„=ªfĞŸ†²ñÖpİï~©ËÉ*»…`d2íç¸mıšŒ
oØ-¼aÍÄ†Jû	É`îIƒQK@üPÙ¨íxÀóÒ[+œü^ªD-SøRØ]N’%1¨&<|#şRÎ ü0ãÆÑ–îhc¿DÜ5ş²_CzùM9ÍVÀ“ùª‹’×’©hœÎQpÜ\·š(gAbˆ¦õ!–Çî¸9lÖÌ§ ^lRŒ•Ú<2.ÒtÙÙZ=	×~±Oh¼pÌ‰r"í5ys±OK:İğ3íµ«z1Êçê¼¥Ê®Üé,½B$
^lÌÕB+/£Y`FìúwsÛJÜÎŞ´-•àÅ1÷	óãâSÂ··~ IŸ÷”^<d9¶Ëüjı˜–`V!ùÜçtŒıˆ5åTjˆ>U(¾U"®1ª•:ñ);˜EÍ3lÉëD{tæ}£»Æ–ĞV˜ôBQÉ¾†¨ŒŠÎåñÑ3¤aV5'$ m±Ñ|/i¤ÓtçÉ›tÃÉµš”û¢¬t@6°4´g;WßkĞtÃI¬ˆ/ÓÔû¾“ÿE.¼v§Áçh^ÎL?ß,ğ!3«Û'û‘±Ä‰#]B|£rbo"ó‰²z¨B]Ä¡näÓœ7ë«[R¶8™;Í[ŞÛ¹=u¾…T´ÎZiG:é†§3Râ(î¥L$a“–H&€ÌBäŒ«÷yäÔ@¯VEc›Ê&[ÄÌÕ>æìÛ=JB0û7tÒÄ&âş»9I€™*Í‡vQª8÷9 û5§¤30Nœ½%•2Ää(•¤	÷â]ıq>jtğMÉ
ÆÆ  ¿Ë'¶×dW&A—wE7ÇÜ¨÷{üêÁÃ‰„JÎ¯ş =ñ*>e}Péoât2Á_>Õ¼]Å¬³ï¸‚Ç6hÆHÿz½'!ùO`¹;ˆF5 E®õH“ˆ5}tKŒû*!ĞÜ(ø’F/NÄJÕñrñp%šˆïŠy„·ıï%lÿÓŠçşRUIŸñ¾©“Í Ic?I«ª±Š!É!³	V!UäÍèÏiÌ0%2i4Š˜»÷)‰Kì‡ØÙèú$>­wWQøÅRe1İğ“÷>ĞrÆó°…‰¸,
N9“DEÜ‚	>ªó·¾=¯rÏûLôxïu+rÖ3Ëç¬8Ÿ`ú*¥áqÙ‚uS—T\v«‹Râ‚ŠšE’Kñì5Ò”L¡mlVhj	pa/¬ï g°Ó¶}ìŒV#µ»`r™ZéüˆZA¼r¦+(\œ(lÊŠ]ıS^¾iÆİ	å(\·'	Ê‡I;€÷]ÆŠE]4kš_nÆ«$Ê'İ9ÉŞ)w4¯×wBCÄÏèªtôb–ZNÙå—Ó=j#M`=öûTvgØB‚2?=–Ã£‹'Äbƒû…nŠ[˜eµ–l6Cì‰ÍT¦J,82tW3˜‘¦Û)•f†öüİB(g¾L/{‘İŒâ¤¡•À.G`ÂğMT¥nMæ‹œøW:‡ë àÄÊ.>T]¿‡¤üæ[Ø£…§NP*&f5_U§=j s ªæGM­ĞÃ"İJ¾å.‚‡©}m"@¶Å1¤Z‘ß
lĞnßdµFçZ6{èù*ô²„ô(6£kIñEÏ7Hd‡]¤\jôÌm¸YDê1»6Î‹-ˆÃI®Ğ¨DmòîÉß¢<·nHğ¶„˜FË¦h÷r`bo1Ó•ä´PîPEÄ¼ZèË+ıç˜¼0,„ÁÏ`HÈrH¢À Ï¬r ˆ}$˜	v¥fÆ'+Ú¾Ş[ĞËÙ•ªô¿ ¯hŸQó:“¥vö‡Û¹ÉõR¤y:ÂB÷Ù­gÖU¨`Z¹¨Aí:<È2ÿLù3[$îL'ø9.ÕÇãÉ¥—¾¨½)à ;¿°ƒælõ¢y6i&‘ïA
R;±–:³à ¨—“°µĞ=h)IÿØKŸ3\™Bkªi~ÒêR›%‰><Éíiä"lğı©ÅÄø]¯»
jêçr›„96r<igÔ%‚™óç?9ü¿²éWÌDğëŠzè‹ÿp|Åy¡FéŒ'–Mê^,ÉÚI3«.Ó+Í0”dë‹İ‰â¸–Y—¦ÔÕuVòÛìPn¿R~ÆÂôºfyKOd˜–‡Ó»3‹¯¡bö½¿ÿ¿ÉÉÒaèH_¿œvŠBĞ¶šR kİØ£Ô¥rL%€Z[½ğT” °V„D›Ï2b³|®tûŠ3º·~á<Z°‘”¹¯>÷ÿÚ¹öÑãyŠºk»a¨ÀúİÇMWßS£³.WÈº4ìWp—ôñÄİGİŠR¯2QñTTÔw)#D·hk‚ŠvG"
N[&­Ú˜óøşÙğcêô6Ÿ:+R‹úÕ™4( ^4ÇMm2Ù–‘|¡P;¦M³Ibûø8õl÷_±t…ÕqVmó£UgKÄ$9ÀˆÓü‹Éiá‰‚ı°°VwMå€–Té.²ÿ¡XÙùa¬´Ç­Tºß'Ì‘€õø7u?Î0„b"ÑkßT÷M£öd¬³|)o&mË¤wøn ¬l3bŞËùİ§™Æ•àOM*ÒÿAF¬¦
ß€¡“‡º²F(Å¸©¦¬.[#/‹(Ç©qûûæ0–)BMvìåzÖ¶£ğå"ˆ¯Óe<Ô@~·ş%1oß õ›şÌ*µä¥gàìFà;>\=aK›¦FA¸R`º$~H ŸÂäOI =EwQíÓp‚Õ5¶=ËÒB‡ßcp£Tl¬ <,ö%„SAÏ±‘Ücş EÆ GmU<¤"l<’ e©ÂÚd¼Ø¹˜Óño Şsv·<¯’—¦«(ZWk²)·Iİâæ—ªĞ	­sÎ
ám–‘Öy^CŸ	j•BåõSÀ¯¶üøCJe¼Ö{ş0&7ÃàBWs¾üõÊ<.•Ğœ’Qjõ®ÜõjØ¿ç¿°6r”Qè6vø|Q¿`¦ÉÈE¿U¶kÜNÛ~)Ç RvuŸ°‘˜kÑDÁk|š°È
£ƒAŸØTƒJƒí
§ERşÑ£>ø7“ê(•Rß~«ù0G68BpY;Í%VgĞbªTÎÆVÑ™º”Íç
uNúÑÖ7‘+a–«t|ÿg'–Ñ°)»ÌNìı/=Ä~ñí< 5³7-ú5¦°Æ¥¤;Àd…„“Hà¾i}ÛiÚëß×@‚^Ü‰‰Çu‘‹† I¬ºïİĞêm,é4kv \ÅØ¸ÆZoÓi‘º7æ¾Ê!ü–ü}tÔIÎ@5*f·t˜8ÏãwZÙ EMšüÇPÊ[@¢óñ>F,°èá~å3º¥vKòÃ6O‰ƒIkSvŸËïjÄçz¥J&ÍzÚç 'eü²ï0ì+¹®1V´µ¬Z}jRøkG_Ô (j;3m…É+„k›Ú¡ÖOÁ Æ.sø¦`¦9HQ 5‰U.9bµÛUA{á—<ˆíœoş?"¯FhYc†ÿ=ŸnL¬Ò¤‚s{ªÎ”
x1~q9BåÚ½'¬‡ò‘™bOŒO¹;^U¥j–u` ÏÑï/o|¸ÊŞ‚-¹ÅÇ*ë?³áÛvˆşƒõ¹t)¤„“wpjê	¹êAˆFŒÀK‡Ä« ¡“f Ë6>tNY]A^aÏòYèã’ğq‹¾·1~”3¿G¹mi„P2èW¦7—ŒµOeW¬w­îœ-ğÏÊUÄxµ3BAí²«38¬hØ»6Cs0ñŠf'ÛuîG)€¾kµFäGÊ¥Ç:+ÖÙŠ8¾‰8›DöÿÂÃøtÄ¶‘'Y¤Ñ÷Šš¨œ0+/-KÉ)
?7ƒHgW!­8dİaıjƒM×½)Ï'@"«7í\íêo!D1éh`›Ÿ†¸h¤çÔ-3¬AôÌˆQD…/¤z1ƒ›¸ÛnìD"±b4¯œ¼3³s›j]¿ÔÉc¤u/ÓhoÒœwˆÍ£–0æ*/€§9á²i²ˆk+÷¿EwÉ˜ÉË
•ì*eM±5ˆçek]’.‡“{(#hY\‚a{W¢n·Åİƒ]ü^P()Ÿ/;è?d•˜R@6*–
WVE'„6Q‹SD\ÿØW|½h4†0ˆ’~±±X‰(ø”àq’Á41â¹GV>»ÏZ±xd†ÿÎ>BŞ`KI3n./ƒ
d®H	‡8)ld˜·oüğ>(Qºbz—-Ø¼´D1Ó		€åÂZqD£N·r¯m«ÙŞ#àQ	èÓ°	·Àª êõó„os%°‡lùuF¯6‘oÏ²Æ ‘µ12³¶œdüyR-%ğ¦«L£Êò©®‘Òt-˜²ˆ°¹Í¶VÔ#à)ôGöm“ÀDföô·ieQVji“€@ıĞÒÉ9ú!:Y#!ş0Rè<6±<7êíÇï¤Zg~´,”,1tÑÙIÊÜ]à§®Ğ –|­çÜ*Py¥Áy½¢|”¥^é¬.€£ĞÌ¦YoyÄq…ÙD€ïx>ÉD©õ§õWÌÒ:©!àõ×âêŠŞlØ»ˆh‡!p,J¢mÒ>¹EfC ¾òª]˜2@‹İ'6hw©=P[ä4 w¿c¶óyx¢Õì4OUª™:jÉÏg ¯I·>ŒGâOT bíHÀD)öÓ‚çš:XÄş—Õ°i<cÕš]m_õ³qÁÖÅXkü¹`­<¬\°:ñKŸ+§U;œ<Úğ_³˜x0Ù+1 œ×jë¹Ü®Öoö†Õv­§ûÕÃöòş?
€'Do¦”›#¤UA‰Ë%ş•­ô¾Ù'æª°œ\ù£&Kö'.uL§ügV¶=íãT°„¸
½ƒƒ®ƒÉE_'tS‡ş&ÒA×9UcÕ»F¨¥ÚÓî ¶nw;»)™ÿ¥­UDC©RRY·¸i¶ÕœŞ·a¨²å¾Ê*YsE"šf€Rˆcez8¬ãº˜Å!±Ëºà“O›†½ñeˆèç@üÈ‹YÍÔ ×ö‚ó:Ği£X.Éz¹I‚’äÿò66/İÃ,¶Û/yVa2>²í[)Gb¤ÀğŞñ»€ûõçn¢¬äã˜ÚõÎ[Ú6¼S¥ Ì~ïlbÏå±ï«oaè(Ä“ªÛoæ,`©s…ÿe¼ãıèMŠûÉ•,°Q	ö#ÿ<[ÙûóÆWãhmNk¢^NÇ©@–·j@‹Ã++÷ô­{²Su_Û;A Zô?¹L‹v
	!ãÇ+]N1ÆL¡]åœ-ge!Õ¼êìşx 5Aã‰À§0’!Z2s½fÍ¡“ıd=FnjNû’@svÚà3}aærD=©ËçÙvwn>±SEîCy‚õ?+›2BxšúZnıßè‚ÉdÍV| ‹4ô|ƒSVæjtÿ£Ë?Sà ¢/C·™åùTU¦IïŠpÃªö’îÏ®t@Æä)QHİwÚ‘0¿Ñï
¹S„oSd“üeDwŞ[®“‘bÒ.¡Ù´¡Ğ“?§Y¿cÿ½¤¾¾Î“õ¸ğhßçz kjÍÎ55'VEˆ^R¨0„‰Ÿûè¼ 'LÉ-
½¬â{Ğ÷üa‹ƒ	‰$PCÌTéÆGìêË›ëÎôX¹n+,HQÓ$Lı^(Áõ°û’©÷™ÀrmbÂk™˜ª¥¬gš©’oÍ%BCT¦ÄDßûÑö+dëdø_¢­%‰Ó÷sõïÁ(¬[Ùğï˜;êËA€Q–j¥A FeÆãÔ `¹	‡ùÑ(÷º=•OóÏØß!¶ÁU5+ÒûTáİ€j¨é§BÇù—aPı•#Ô<¯Â^}D}ÒÃß~ƒk÷â}çÔı°dè.÷cé-tnÏ«éñáŒdHuÇBşZ¼!qvÓ9JÍ°<˜–H~UawÃrS”¢;¼m(Íf¯5.ÂçñoŠ6ö‰ÉøC7ûÃÓ®À6fÀé¥Ü0YS™¾„~/ê>iAş]Ï§Í`|ÌÁTPx@·“¾ÃÒ2fòùî'¹bw¯£«!¨]=„.½µÑk[ŞßP9ÚZ×‹+ó› úA.å¹ë‘\”®q‹i>yWÁœjöÿ¥À¤rÍ8(®¼Z»ÉîÓ£_şCA<—#\†ài¤B^¬ÉSMsÃ8ˆ/®¿M4šmƒ²ˆKùªît,T Šc‡} "Ó‹ş£-,…9ËóiYNŞåæzş%ÒpÃñÍoûÇBûC9:°è@â‘‹/PÿkŞ›ønºÍÁ.WäŒ­nOàüÇŠC¨M[Ó…í¨š#ãÂ3¤2¤öŞ³MZ÷‡Çómã$v-j!½EÉflP#k·K®}q:Gá¹×K¤î%*¨.	äÏX¬£­á/ú·†$ }Ì„íã¹³XÒ«¦6ŞÏ3n­[Ï©›L:‰Ã"ÌÒù]©©\¡7/Õƒ<Æ®–ÜÁ˜ÚYUaí;¨„ŸûâJ+»œÃÕÿG.Š/‘o‹*¯ÍŞ ¾‰„ñÜS r!óHutÕ=h…˜0ó1¶µR…Í‘$N¦èc™
¤Ší¸QÃîQ51e­>ağ=Q!&z¾…À\)ÆT:=W}“÷¤Oâ+¢ô´`ÿĞÀ†ÇÛ!ıöD¸ñÄ>ş‡u¨ Aˆ ­›ÿ"ny4.¢
f{öz‹´¿µ4«¯ôµœÙ³öÉYø§ŒÆEÖJ÷b·…v ï¹Z¶?ücn¨,´³?RIyV¾fßBÈ¦8¥ĞÊ‡ É‚<ÜP€ÈMpîb;Á³;×›pîP»Ş›UŒ›ôàIï9·À…Ku	5åCÅzT wì¢j—?Ûu¼»:WÌÎ3c‡¡µüš–$Gµ±¿½É¤µõNÖ’Çe*Ïc†ı@l¤çïQ‹eŒÄcvÔ‚WO™‡<:¹7U^ÛçÄš¯Õ]¿ÔÓìÒo¸ZÖhö è;wºbïO£\-ëàx\^ç\EJôÊĞ?h¸H´õ¦ÌËL~ªìıPOÃ¬$YŸŠÔõgãß¤CßoGf1 DËhLa>P‡©¥Kƒà†\¢5@ÔÑDQ ½~„\v‚j.DÎÒ.«"ø@Í9›[kû?-{¢¬ÿ…¦'Í*ékõÎÛı½Cg\ù†Ut²»S¹0ˆ+:'Äu'Ö×nµjhÌè)à—¡Xö’Ú³:†ahëvm»	]:ÂB÷P£.éÂe2ÜúyĞAæÔ
GÑ+9`C_¿’_‹ó¤÷£–s²ªåÇÓ/ÌFéÒ#!Ã£İ¢wüã!jõÒ×¹{„!«+ùÎ|„eÕ¶›P…VRcÀ—¨™8©}AşñàêO&»¡bs?jÂÉ«qÒîŒY¹şÑ!ùºû…f!Ùµ9»¤,ÊÔŠRÃïMñ`§/uÑ¹ôy#VÌÏ›áP¸ã¶‚0ªÄÉ®PëRÇ	J­0\‡/È~¬2)—	ØYE È<ßñ&
Z£6Á=â3]»ïĞØäG$7ì9š÷š÷µ,-2³bQıµ£¾Ô9±ÁKôsŠ†Å A¶L4<N¥Š>>3J§#3ÍWÕ$S]E³Çôğ™•—û¢II¨ æå¼ÁĞ.¾¢@X0K:ãô‹”.2+Jè”’H%Ù ¦Ô= Ä§3Ì£îtó‡¼8<_L%	”ùuúfá¢´´$-<N	É¬­
Ú ‡-œØğ;VÕ#¡á¼#@>©_ÇŠ© 4j›ÏÅßX™l¼:×g5ëŠÔ€ÌtÆïNh<wnvÉU*_ +föÚ\Ãİà§}fƒÁ?6jÅâ”3çõè	*¢ƒ*wóÚÒv¤ô"(—ëšşªÿªß3€m|SoÇ‹SI{½p|‘¸è,@Å|2ğ- ’¦w&mÇ©& ~0‹
\ÍÀë¥–4®_•¨L2\ŠğÏ”ÒQšq¬(‚
\{eıPU>"ıÖUgL ¢ıÁË„A9zë,¨MÀ8½–yµ¼ÜQ´Ö6¡èÉÎÅMzÍ¡=‹…z+s?@n	Ú/c¹ìtŒ†òAÙÁ¹6$¥dtç	Œ	bzÀwı@.ŒApàÑ"‰ó<"”µì‹^¦ŠÑSù#V4ş§>‘¿|°:z¡°ÌæõÖp›&¾É`æMm¶&|ß‰|>÷„º±ûo{íÌy¼İñÈ*ùHÊK’»ô|ADµÄ…1€…Wnøi.\<|^†õñ—´Ê×ßÅ/Æü†;õ7Ã©árëÍµ¥İ}ÀÆnº+B`é°†0´M5 †t^ÈqQÍÈw÷P0ú7'óÎõyğá½ó¨VpÙÓ¢~ûé-Òk:QÆùÀmĞp«èJí"Ú”÷×¢Û/!İö;^È×†ÀDg_K5\ví	w…§"c\v x—&@é)R.ô[Évğª‹èÌIF(*ajÖÃ(ŸG &ó;3ÜŸØ•ôîåxë"õˆÚ0âv´£Rì
V	ï0®øñqÈ:Ñ0´¿Rß!ˆDx	F¼Ï:J7«³èÛâÂß§ù„¨!2&,š±3(øü(#–ºıó=CŞB“ŸÉP’JÓB½ÔÇôohÓ­Ñ‡yî°åuj(­¥·ßé*BÒkÃŞ`_€ûıƒh®7Ñ»P;=ƒï.,Ü¤,úš³cì¨Ó_>À&÷;.¹¨Âw×ûÜRQÀF}´‚Ù˜L¾ïç©aPY‘+ª!À$QÂ“ĞÍU|;œf{l´Š¡µ
Ï7\¾é0Ñ@ß´sÕ‚\Øú-Mlæ45Îëè_µ];I|²ëğhÍ!ù‘„@ûû¡ŞvÛà÷qôIñ:ûxQ€§]Ñ¬Q€Ø‚9ê0‡µ0â)b/šÅZtˆä÷k!»{‘‹›0”a‘²á–$ÜãóíÄ?DéOgsT7üåöma 6áÕ€WT%Ş]s–yf»]p}Ÿj±ÄL¶údxÅÕ^š¥ÏB”Ğ—(ğúˆ:r¹¢>,@-YÜr-9šA¸•:z÷ø~/OKS{u0®Ú1öáíĞ¥·CöáÕÉ¾ ®lhçag¾ÀR‡V	Á Úc;îr†$‡0IóğŞôFø˜v“>Îá1ö`“ØbH>lsk½æøçë«Bå”L`%×R)i£]à–ÖFc2°¨k¡íß¢÷$&ì¥u%Ql~$µs#*ÏÙ!ÃûÜ,ŒñEúEûSw‡ïºsÈ$HÃt)Ò„ïÙ{BúTl¢ğ.A±Ëéu‹î*÷’!>—;AUÛ¨õùxEkTØ‚âZ]Ô­Å2‘kS‹ÌXH‘lY0'¿V±Dõo¬û7	1ô®¬š
ïÁ¯@õê¸à\áèÈ`‰VR†• Èí€:rò”éóq1éš`N×Ë‡{›QYê»‰hÏ`3›tÍƒG*;êxJ÷ZÔÊ²Šv¡£Ò¤¶©–;©—7úÏ.IŠU½A´WŸìtã3Aï´¿¾ğĞª¨ÿ¹Å-5ÅtQ@¦ïÉXd…ë¯Ò¤BÃìÇ™/²÷£Õ²9ér^~›ì§áR³¯šnä§FàÁ5PxË[\Sşõo¬ç­ËµU¼üS0…Şİy?[¬ö…S~t d²HV2ƒÏ%`ôïé|úD7ò\ãÈ„fW½±»$+/E=Û—ÍÄ~‡
©^Á9
ËKŒÌ}PôT?züº|Û#9®¾1.ë€Ä±ç5{øU?©›…­t^X¸{™L3ÒV¤Œç)]r®Á‘tY•Æ xL±›•ø Mr%Ô¼Øó(5´>¸À´‰~}üÁ—æµ¹ÖvLà9µé“Hıw5óWn.
ñûĞTÕšº¿$¼¢Û„A¯21ÂÛõW.¶x¶€¶b@Gr*×ƒêM=EúıC‘{E‹°ÎòŒàâğê5[+ŸıÄ/‰}›RA•6±å¤6ó4ô´¶Z¼}=2wÔ½„­¬–ÀîAPÄ§§'«Îß)¬ğ¹~ç¥k:6Ic+²ü®énª OE>ø4Súj	zÃ‚yZIşÅ˜sMÇ¢Ü’ÚådšŠGîjF_¼ñú·P¬'l<«‰&¹•yÏ"Ãr¨äú¨™R®Q5Ù*îuDştLÿÏÑ¿fêOÓ¾îóÄOFdÌ\«¥9x‚º|¥¢ËÁpèúyÀöşäSrë3â²Æ=œS¯æ¤v†V2-™˜],æ'0œÛ‡²r‹³[JO	Ğ¨ÀƒIïo›ø–á;Ù†Åƒˆñ4iK|œ;("£½\Jô«~^ „üµ3­ßÅºö™ÃK‰*?!vÒm~¢›à§kWî®üÇzÔ¯s¿–js”á3hĞ'ÎWÎ¿¡]hÂFØ.o¡×<u¥¢Õ¹A°MŞ—z«R ´»Èiäf—)s˜?¹Â9"ú— *Òu"Òî ’õÇZÈ$ÖÇã»Q:İÜ²?-U‹€ƒÆ	ØLô±ÄöĞ&mq:|rª³äè¤“ïM¯‰{;Ùİ(zĞÖŒ¹‰b#l²ZKä+(¯¬ğ‰²c]¸	!±æÄ8H¢uœCEİ™‘ÍßQËçôüÒŸyë×/à7míipÌæ¬Ê¥ÂÃu/¬C„·ÀY¸M@{_7«9wŒfÄÀUEÄ§ÖÊ±m%A tZ¦Vw×‡»ğâÂt,ğ °|Ä¢ôĞgÛÆ§œrFÔÅÍšVhR (µjcİĞpš(cœQÑBLïSm !O_£Õ±—‡ıŒıîŠü'ƒ€¥æWÆ¨³ÁxX’ıÄü,ß?EyÇààGD!²ıå/¢¥EUóRèvÔ ·G1o¿1·ì÷ó]¤j¿(Øœ«^ŸíN¦·Æµíˆ¼XŒŒz¸øÀ‡÷'ÊíÑŠLƒR Ò¶Øûïz£ ë;®vBwkÈ˜\Şâ;1—©›¬_•Nk–VY(H7M±r@Èåcç)suzÃ_…¢y0ñZ	Íª8ùlG¼ëm4ÊxQ?ß—a‹_=ôKEVr°ìNtª³ÿO ~mõ+ÿJ.8
[&"p½{ÿà˜Ú_4%o
fCföW¡S·	Óî•0¦ê¦¢ò²~İÃ·?®Eİ'¶Ì‹ù9=ÉpV°Ó<òİ2ñ4ãÖ>y-#kÒ»'©•ñ¼½-¿ÚLå6d¤Q,Ğeb§±ñ”N–®âjÉÙ÷˜K¹³å«ÿa÷Üç>;¸+ ¨`Ä–rZ÷ç{„©\ÍajÛ4è=Zqğz™TQŠR—Ê_¢Ó‚µíYHE*òplÛµa£ŞçvIĞCqœ¡”Zµ œÂ¢ˆ"yæ
WŠ¹ÌZì]ş@;¦»pØ‘f3É\]5MÉ5‹ÊR¤#TïƒDûò `ÁæÔb
U®ìaµæ¯Õ(Kæ;hAà·fÆw‚É%ùPÿqÆP¤zí¡ÏĞåæšnm¼4õægÀ³MßaáıNc—g+g×Å±"å±ı>gOğÃ©ğ¥X(ÒÙAÌ©Ë‹Ø¡şÙÎÆHk¥©I·PâÌæuóƒ‰@Âh…àu£Ë€Lìu€¢m•Û¢¡hv…Ì=iAóJó†¹³êg¼N#Z@CB¶P|kıxî%Ä¢L0ŞÅVµº&ÛœŠ!™ıÙ‡OãÉxHªÊgİ"ğ~Ë‰Ó¤k]è$s±¬*2Ãcİì·PWbÔØ'çµÖ;»­ÖÄKuğÖ.¡ºäÂÆBÉh:àkRƒ€áªñ‰hæ¡çî9}‡Ì	åuéTö˜SÇr0Õ»ëÒ¢Få}› &rìf†Éı~Torı{]	Œ .RŒÂM+KäÍòDE
´!›Xnûy­T5ÁÛXöÆGÔà¬DÛãWE¹~6¾R£'œğÀ-Al>JÂ!LõÃÏ¡¨¦“ÁËŞ ­ĞµÌ±tÁ™©nÆYd¸ãÖÖâëpïFñ®”øcjsp\0ÿ» ä*ºÎ|(ò“nÌ€bJ%Ó——¬rò&µ˜±Óª‘b`ƒ­“2hdCwô"¦E#İ@°D#)öN¶üÙeº)oà¤X£3Q{|LáÊÄPí×\«iUÛÖšÄIëeoõpPš7£× T†9 s/ô·²óûØâÇÎ%#Õ"®åÙ„$ÁV[<;npœ…#ˆz +v–URæj±(Í€‘Çd4İO%>ueG*şC˜Ş»{áÕ-*õpÀ '”“˜­†Öšä5ÚÁØnù]Tyµİß‡•ƒ{YI-^ş´SßŞ‡öüe8
‹j0ëù]´¤<¦Í KòT·7¬Öª¾ğ8‘t#\¨YæZ	^ìpgsÈu
¹q­8N?4d•ñîd’ùÛWÓBešá§´×yûh‹2ºKXaß°Ãj-lÎñPøÇÖĞ1«‰z¢7o?7_Ld:ä©¸YØd!Èú<ÊI!^ºWŠÖãÚ5d‰mõ!¯æ%jA*šÿHUŞù'ÎÓrï1ÚÏ…&Ï@Jİ€JÉáAßç×Ğ§Ã §ğ!Œ˜+[Ü€CLˆ›À¸ºcšÀuÊHOB¢a‡úk`t$lj~ĞĞ’(K1’è‡ N!êı•˜â_3‹’J˜&7ùĞ›„‘¥7<çÔø¿U7S²<D<»Ÿæ;m¹¾Ó‡ ü©²7¥¥j$Õ "M~%1ägjÈéÏ’áV>a ¥4AZƒÅ3ùÆUöû‰Un¯]ÏF ¸°Í÷ÁÎÁî6˜…Š9š”w“ºî/éoÇñ¼æ½ô<–„øÍ‰!{E%÷y_¦ÊJÚVÆÑÎ’úI6³®eNê·;üšƒªåyG(ÌÍÀY/Ã¤+„sX4Ğ'P„àjHuK¥#>&ˆH)ZØ:\ßEº“³¶(H°M`_‹½Â:ã²NE1]ÿ”¸¿ÊWMê¡õ¸f:ƒ]¢Ò´zŒöµ-sÌÏmHQËÙ,4óËHØu‰»‚;•ŠåŠİ^ÆTs¢qD“o»‚PËìV³“‰ĞK[wZ¼ÚGL£Bô¬ƒØ1n 7fş‘?µ'• W×JŞıV” ‹z@£ÍÆ[¶xT6^àóÒ¨¦Ãæ€UèR%|¬XÌæ
"˜¢—¡0)¥v"™Œ*I¨=íÚºhWU¦H½gÁˆ…ÈF?qKr#°?€ş³ë­ï¸QÛJ¦†õ9M9£yN..S>á`'Œ@5ˆja¡˜—‚Ù¢ô!5üu°eŒİù¦QI~œU(8TË4ÀØVÖ¢¿2ziUJP?@v¯SV‚™k{‚a×.­w~ó¬U¢3 [/ ã’aİÂ1-4ôÛğ»¦’ıh~¢ÂÏïIÇ—´p´Ãaå¯Ñ‚[·ÔP¸ù1¬Ìçµ„ë_ZˆU¶Âˆ
Í+¼pßfÒdÈ,ìŠh y¶sÃüq«ˆ˜©¤ÌÀq|LkÚ:©q·»óš)¥?wœá†Ü//­}¹Í"¡
¡ü`:ÔmRï–!²‰®C×ò…‡7Ş˜eÃ”§”ÃÕ¡×%aË'q™:†ÿÒÍæ „ó.ŞCˆò	(lv<0Pª¼›–Ê$ÿ+©‰2¶ÅÈĞyasYa­Õ¢jIê‘ Wx~)ôûP<%2FM&É–˜¬{@(Å>ÀÙN#Â9Ëi Œ&Cß
W=³N%µD~Æ¶–@ÉÃ2R9{2BgAsKO—•øºÊ\J`@lŞìD»’ö;Ê@Y±áÉ§_9€DfÃÉ54õÂH[Á0S±ljÃmŞüéñ·ÕÍk›8ømÉÃûî¿J-gzÀ<T~XÛî()ò`~õõ—4fŸäZm?…ÜÁ®îH‡Ä wÑRĞÉ=¾gd¢UjP	L’„';ºHkf¥kR¶àAÕ~ğ°*òWkßgçãÃÊe(sÌÆ!5Öß¾AÊò IIòcà¾ˆyOI\w‚â8ºí,ñßÕsD?¤¸ş²ÿœr ì¤è)¼@Çì—;¢¤71ºc|üÉZwGHû âMkiıAŠÔMÌFg—9¿ÒêèRîb@Sİÿ_Û@éš³ÒÔ@„Jš0Êé+é¨¼k¦É5iü/ã&œQ(õxq‡£»
šöXı—f¶¹­™2œ¬:‡Ç™¿†;ğc%˜»ØeïÛ»ÑÜ ƒÊü»<9}”•gŞÛ3fÌnAvô_;£R.,,æ&„•OôŸ¼:ã7”ê Ma'©Qßrb¸j+v$ïxûÌuˆq;CçÂrw=ÿÛ:›ø+•|Uvµ’Œ‰$<@‚ñ½! ¡¯TTÂT
i‚¿>K^|C§2¤‘,>œí¿¹Õ	ĞR¤ÎL·†`Šå—èXÿßVì’lo-ˆŠ“ÇlÍQ5oZ”}„nüH>Õªj‘“½ò²¢Á>ù½é%©@Â)~W‚Ú¹·éæeSê–¤âÆn Äe­°«[4]ƒD©
—}#‡4n:3ü'ªÖjşMèæÔëêŸWl®F‘8cfµî…gœ('ëCĞôã„H¾Ä¼ğù­ªJ^®U¯X’¶p¬ëV›öÊFãìlÕ·Ñãêƒ(õjê‰I\£ÑHP
ÈÖ
*~^şë¯QÑ–h´ß¨¥†ü\wŞJxİp9í!M{Ã¢JCæ;L:ÌY:÷”í[çDDËè(Â‰•ËªCö}uÕás¢†ğ,·xIİ“×ıb‡Å¼UÔ¼¢§“ˆKeğ¢•»8ªt/ì5ĞÑ ¨Q Ó/˜ß‰EÀ}•£Èj,%11ªşÏ3»;ßàÇ–ñUq`õŒ_ÑÂq¤•Ğˆ}[3Ò™û=’10âÓm6«Â–}kğ…S‘ $· z½I¾µók|†}ª¾uÑyß¨ı	9“2ã½¼vÊ<|SÆsÇUë'X…ù”?™UŸKû|oÏA: ::Ş†Wm'—‹İ;í+z%gù‰ß&¶ÉG‹fo·1»Š¶DÙ$Õ*ZCG"û„s¯7‰Y›c\`€Ûÿv@-T÷Ò`š©×İÕ¢¸–êÖI„núÙ+4¥@±Y³™@6\9'7h­ü¢§ÑO’ÛïN;Ü@U=nd“ìÕ;¹SÈ?l4};‡Öz^¬|F‡Y¯‹qwtÚ,òñÏµiŠ	˜/§‹.ˆb,õ|nVƒ"şy·ØæéÓ{§ ¯CÒØUm‡gt?ŸÀ^®µÄ»{ò¥·ıÀíb¿¤šÆ€Ø¤{IO‘İâwÂŠÜ¹p¡xóB@\-£K#õ/O/¥‰Ò|"õ’“–gÏGäYiç`¡©×\—6ïR&)rÇ-É¼Á®q¿6íöœW¼üÂç AÌ*ó¼ÛìŠæ”H û¦Egri?     vlÎ­%bè ¥Ç€†¢÷±Ägû    YZ