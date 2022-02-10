#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="128861844"
MD5="b60a50d8a005ad77417f256538241dc7"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25908"
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
	echo Uncompressed size: 160 KB
	echo Compression: xz
	echo Date of packaging: Thu Feb 10 16:34:35 -03 2022
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
	echo OLDUSIZE=160
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
	MS_Printf "About to extract 160 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 160; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (160 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌâÿdò] ¼}•À1Dd]‡Á›PætİDùÓf*úNŞÔıd¶ÂŸ7û’F)dˆ‚}ä>Œ´ÎŞÇ(›¼èà«%8”% ròà<xo|z Ì­N.Ğbu	¶ÿ—¤K&°Z¿J*0Š2À·:Œ_ênÅÊmÄ”@ 1ç>§ÿ¶Ek<l8
×bS¾ûóÛ`ÅúzÕ	º ¹†/> fê&°†–°'{–Cq±Æ _£Ä[g:&+¯*+P*ÛüÌO4H™'$Æô1¢Ì×à-~óOûyôÅµZ˜y–
3"Ï”´ñ	sµç}f¸]“GÈN@˜ãÜysƒ¤8*§t¢á±§¢Ù±6ƒ¤€»I¥ŠÜ¡Ú¼V¿QÂ|\ªY3‰|ød™ÔµÎ. ±tDŞ¨]q˜+•Ä•“‚‹¡ÉfT#AÑÊg
ãœgEÿo©±«–ÇEŞå5pCÒ–kR‹Uÿ í2|NSÒå5MíL'éÅ€áT#¸nGÿÈrÀ¨a-ŠEçNk[VYXÉo¹î›v¬9¢(®G[ùÌÌùháÃácA×mŸïñÒ±-†¸rçñ4—kpDi2,öå¢–c–B¯¿˜…;/.DİÕÍé7Ÿuy˜ ç¤-ù©T´È’ö•0z0‡&?éÜÛğûb“Ã_©„(g:„_ì³ú†1HÍ)øÀ¦Tã~C‚D6ÊUWW@ö‚®ş-Çà‘¦¬ ÁÂšÀNÊñïêM¾òğ’lRs²Ã¢›ñŸAüº—¼‘izÓ~îL,ØÁ“YâìRìÜ%û³/¶£a^Pytèµx©xX•ŒÑ6O¢Sn¤ÊÄÍàé£kœ‹6Íñ*Ï„ñ³ÿ'òğ—ğ-®ğ´\	¹eòÖ¹ƒA“ĞL[am	;¶1ƒQˆ·—;_€¸¡¡İ¤™£ÎÔíZRIÍ£—ŞN5ÆwÆ†±?éş¢ghĞÚ”èÍÂÚÃ>ÿ4…º	`ä<ıî‹ÔŞfi>IÓçše[Ä]‘šAº¥q">¨eQÈLe`¨0X /½„èz:êŠD@c,cÖ]ãÃ¹24½+ä%BÙNüÅøœtHØh¯ÃÔ ^ôĞÈÌ€©ı·FY> ñ‡“F£ìÆR'íXš›Q7ıŸ@ÕúEVâ¥
µS'çmÂØ¥%ıïÆp8°[/ëXË·™æudkÿl¬FEÒÓ£Áúr¹Ãˆd€ÇD¹Aš…ı7CÁÚÊó'@ à {#æ‘màÂ–ë£Có{Óí‡I'7©mRêÈÈŒA‚&^›`zÀÿô
dŠ_|û‹ùb3•–qŸ‘()K…íec•›d¨$k§àÛ¾éì”¹«˜?J&n2Îy8b-Öp÷~Á‚°Sâ[ˆÚFk&
ÙBÍŒ ÇæïÁşñæ?ÕË¡ á©Yª¶Áî Ò£UŠk+mğ 6z?„Ò>2<ÀĞbÃSo?CTÅÙ¤äÔ¯iÄÃ¡ö×q/‚!in¹·Câ¦¸/=,İ³¢vÀØ¼gœúlr"m“ª©Ñ	.Œ™$oøÿÇóÙ!©I¹,TZ¢UòE§—sR&µèŒcÎSÉH~ò-òXÓzcõu0Ãäd˜1Ä±ÅËNSsw˜ NnÒ9+÷Å'yÖIjé^¤‘_eìîrï1­¨ylqX‡ËL]qYÛuVÃi O2=ÄĞƒÙC~tØ°ä]jxø-Y;îy¶Óù¸Û1x~Qæ¸@?#°¿ÆÚ#iÛÛ>ÌÂ¨!,ETv´JŒõƒ
b)ş3¿W¸bâœ¦ãÄ I1zü˜ïc”PÚª$h-ù?î×-úÌeGZÔˆî¼Çn½Ï¢­¯fºûş
ÄuXı‹£Vñs°ãûÂß£Ñ>¡.¦FbæßWOğW?*®+h.oãë„×SĞ†åj± t#Ê‹¶b³1! ¬]á##£Èš6I–éšÿÁ¨V«¸mÓã©ÄÜª5Â­¿rÉ•Ók‰º{ÌÊkOnİ•®¦	ˆí&¡!š»¥=—0w…‹”Èävy?¦˜Ü	8fŒ‡õ²$E$Ì/ZÔbß›jWãPíñÁâÙùIØ³ :Ü¶,ª&?y¨è»ç¬YRZ¬3™˜«ìÉv3¼¡"¨VùÈÀg˜Jÿêng¼lËìçc)„r$J*ÂÓ¨ÂkRÅ—?ã­]@r†`½M¶f! Fò~[çºO9—£Ÿa7Åöb¬öÌ¯äìoÈ§ù¿_ˆ£ı,çy B)ìI†/w[ê,FêËuİ+8NÂ0] ¡ÃÁs“åĞ)Ğ¥¯õÀGg^F:àé æ& ¾-"å`¡^âí ¿x¸ß‚v,úr?Œ|Å¹‘óÜ¿É,‹Ú(îâ‰ûQYÒÒß
sH$2¡©—yjù¿Id;½¤A“ßÛ2¡]\¯“kÂ‘™cê^ä¥ÂOıÔæFz›ÄÔÎÔZMØe_ûRëjuåh„– M§Ñ —aêY1DÇU¶g•^Ïs%äQ9L•õù[ßD¤$_üs”1qíÍ¿ÍõèÿLß­„òÙİ‚È¥8„*$T+D¾…*O#1v|<DFB–-9#hc÷4v|şªX·+J%Ò¶D“¶üğ¶ÈöŞ'-\¾Ì#aI,Û"_ é»r´±Í×däXC'ÄŠaØ“]í¼Xp{79/²+oÃÜî(IÌ±¸@©	YS³mÅš5U,²Â£îºK ©sjÚZO1UìËVÆøÓL¹·Ë	Å÷ÈÎÌpêxVUš•£H’ŞãC#W×Å&¾aßì¤í‹áD=—õ;Qì¸/îÕÊv¬õ ’6ûŞØx-ì•ğ­Ğ4ÚB‘i”µšlÜæƒ*GİÀ3¢µİî;ğ!,|x>:”@dó³w2¨œp[ Ò29»Jf/Q:üÑ‘Å€e‡ñT~ÿôpŠ0"ŒÍk–Èºz.^ôÍ}]®ÆbÖ‘6Yõš…«a•^Šr`z8ş2×™ÆÛ¶ìÄÎ’l¡¼S5‰ûeo‡§gÎ0F½…XY¦)6­â~ô!Ÿ€ğL—±¹Õ¤¯Î˜FœüDw9Ü$;ÃÅOÃ·kd ï¤Yõ±ÚjPLƒÊ¬ïJ–”qâäúOsIsº1öjC	¤Eµ¹?Œâ˜‚ª‚0Ï²ñ:™ÚJÎlù Ê?!ÿø>]ãÕ<¼Şb¹Í¥ô íxû]>¯Ë¸-[!^^;%Z†€º.Ã„Ë1’ Š{ÍØÀAÉí„ì¬Cé	—\› €ƒı”ÇÌş(‰ÜšH†…ÒÑ† ³º^¨ÖC–Úh†ãÿ÷©œXbtO8ÌÿrNÏ§koãA8½¦‹AAÖ‰b§qúï¨ÍZ½yú¾<ËÒ
˜¦„‰Öüt2*l÷/.<ª;Ò*úªF)	¢ğÑñBv…ÑzÓË²èù¾_Q5ÜŒ¹íûÙP+Y–UÓÄ.@(ÏÊ"+’:6–H‘ÜÉfgrg¹ºr?¡)A‘•myßİù7ñÓ$q†Íñ¾ávWnıâï¢ÿåfL&hDş;C³À¥Óş¢R¼øa—V‰”u<£4Y­¬‘,bjsè$.^’…mğ(:J-¾sä•ó™-&¼İ’ó€Šúá8ö½9¨[…™5/wêxşğCFcW‹
£ Rr“Õ;WO4‡^[¡—d—0 çKFú×xF²»«z@—2yI!¨Ë°ä—íÓñ*’#®Üäa}Êw[	–7™(_äÚ–·ß_y\ë±C„COIDËĞ·¸Ä¬7š#€D‚hsI¡RuÒ´uâ¾EÍrª¦tÈğê~õK<k¸ü˜ §œ|XM?ü‡/R¹kLä_ÿ¢§ğçq!pÚÏ¡É¹XDÒrK®y‚“±-Içwõ‰?+¦¨ß©lBêÍ=thÀ¿ØVºÇÚyF´ƒwÿÓ‹¢ ÚO·C¥RDşO×kƒ}+Éë×yíû¢š/ö53úú*±·t]ZúvPÉ?å»…höuÍñ!6%FMÁ¨2†ô°+7áÂA² Ç*Í
nt•[ÍG-IÛRşBšßƒZKšĞ¢€R‹©Æ.e&ğ›‡ØDâĞb[£#£ØO¥=òZà dRí¹¡Ô
…QGSÿÃá·£lí/%ÊÊWhïõƒÙsNö±
uºaYL*å÷±ÿßôÓ~¡÷ï3!®_A*C»P§ &0xS#ôüy¹ì
àyd’¢ÙèŒÈ]øZÕ9ö€èW¸œi«nÉM2<QğÒ\[Ã×¿°¸^ó×ÎäÌñçúr€°QŠ†;Ss]Ê1?Ö°lï,ÕCwÃ$¹ØûÄt±°îÙªğiô‚_ŠàƒŒ˜şÚ^A;5òfc¡hÛŞ-éØzğØÃ:ŞQ*5«ú¦Rç5,vğ>ÿ_h=¤+ «ñxîZD‘¥uÇmp…]_T½À‘%F¢æ\W3şŠĞñŒXæ]íEØK’¡OßŠTvAbPú3ÌEÓ	Éd¼Ÿ^ÈINuº­&EŠÖJ©2û>;}Dé~Ú’UsªcdcÇ?°¡G$K³ÇÑò=uOIy±HŠîÒ|Â¼pvÙ–"ÁøH¿2ıQŠå¿³¸¦Ö„ ğèFåZÿıºšë&¶”°™@zÃ”¸+ü=°»~óË×#[}!Œ-²!® keÅNÓìMJê2ˆ2Yèr™6L’´¢ô~uß?É©æ%è¸up¼7›ÉèÚ¹“§_}«Ú_rX+Up2B~Xèö	Åá¥¤0şæDã§ìC%«ZdJÖ#M.98mFêÄ0¿« É=‘2 ÈÂl²K­7‘»Ï!ÿ£³¾Ô‡}6° ³wñÅà(½¡Úƒíu©2ÊddháwYß¿u6µ³PçŠKÉ«æl •ôk™ÙõLRÓ„ ¦jTÆ"¹‰«\b³ë"ã]‚è6¹6zÿŒ Lñ.âFø_@
>™k¤:!uvåÑ`±×/.< 3Î‚êJÙÛx@^ß™h”ª>">)mªì8Fö;ù¤®’Fëá¦Ú>)cls?İÁÃ_áwã¼ÆlkoïêœË­nªéÁh3€yúÙß½@ùõ¡·tYÇéó2}óÎì)ŠL¸”·ØkDy6o#6>ñ®ÅfÖ2¤ß)ŒÙcø©
4t_£ÌÁŞº¢T{åv×=‚PÏ¥4F%ø6¯ñŸ£Ÿ²ò¨€(u€“ıœÙ°Í9Ûå<6æ€ñ7E¿#€¬mÑ_˜¶	ı¶ø	lÆS¬3fãÇµO&<Ù+gÅqøˆô…Ó~$ÕÍB™ú›ß˜#1Åã‘'çYVY¢T÷ò‡A`Çş¾Şq?ı¡€‹p8ôÄ´‘iv•`I¸ŠúP±!sÖ39YõIŒpµÙ¸m¦äÒH¦ˆ Py!“€ëìÒÿz˜0¨;{\GGÙëşw`ıü‹;ÊŸÙw4‘¯~:ÿ…0 ÑLE}|	RïûkÄzsÓ e±áĞ*¤†eríæÚK»/÷cwš
Ç¥‹Ê$¯6§¦ş.Ùv'}¨Áì­S62V?i²ÃºÕêYár£”Ê“á4$A`{²ÿ“7òŞ,_ÔİK¬Ì¥™ôÇ2¯®Ü¢êçØˆ
.ˆ¶tÿ}B]+“¯À*ÑİŒ*òTiÔ¨ä48ƒ>.î˜¬À%'¹9­‚F„tøkcòì¯_WÜ5‰ğ^®ó×{E·PZ¯kN¾7ç2Cİ^Ï¹›y²rİJJZ«ÖYgİŠåUÚ1÷³“#ª†Tx‹­ĞÎŒ	gSØÜÎÓfcæİa†sÄ`,â½³}çAøâ73ª–:ó)çşñS
ÿË,B~@ÿ=^Œ2ee4=öx¬n<¯½nÚ#Ç‘xƒ@¡Q­ÂÏëgyèİúˆY{-[Nmx¼v¨Ø½3Óiuf’àˆ›|s|dÔXš©[IñWŠ<êƒÒĞÒÀGÂcp^Ûslzpìë>Ì¬Åßk	±{¡¯ş´%òÚÍ•\•zg,eß§0œ®TlıÓ¥Må"ğÛÑn>Ğåø¡Ø2wR‹1Wƒså$ß…ÖÙƒz±«æ:=†sï'ësP’±
È®˜¦Lÿ€„­/6ÍçsBÒöFn'}ØWëÔÁF©¸üFBA})G¥Ì­«²K^O±ûÓ’PÛdÓ¼w<ùù®š†óŠ‹ôÏmüçˆÆªQµ†4‡®ˆGO_¡•tßá˜C"Ö][QXNm
[_?c2Qlñ*-Éêã	>W1ŞZ)=œ{:…:ZtWµ.õUVÕÚVp¿ïN&Ê°*?t3ütÏÙÛ·GOäùÖOæã‹~B=%ãJ§Åÿà¹5Nœ‚i»½å LÒvâSUÎ®Úê;h­B¶ÿ²]ŠO¯×W­ É¨ùÓ1ÆÙ‘ÿ(FÊ¤°™+¬}}]ãï©9Ì>xòú…Ë(^©‘›hDA¬îcN‘`óÈÕ	+I(f ç$T˜dºÜuù€=>$Á–Ãlbq—CqğÅ$0ÏŸÈÉxC¤˜¹¼’Ú^Iğ-"ÅB[½GsŞA­ïv)¢.eOZN&ßÅGPñ9F’ ¿™26>8_VS×7­´aË±›ábqõ¯½úñ×@
&J¡;;qV­PzYhQ¹±ŠTê¢P×ò=´Ç?İŞÆÄË¡HÊ›n@›2‚ğ4(KU²³±€‚SƒÄÊ7Õi¬¡òî,ĞF	ec‡èĞTÜ¡ÅË®ŸâdwLM\¬SF”³ÈŠŒ¡e¯(_¤:…¶Xš2¤4C²—ÉÎAõÊ› öMJá‘y"ZµgÅÑªhÈGËl*–eà(Ø(M	ŠD ¡#š†…ô
42ª^P+¬š'F?4;­õP¤ñÃº¬©˜ÑÜª‘C{R¤7!ebŸJüoÕ¤48D³3¬,½µMfHx•Á=£VMÙı¼Õ-$7=Ær|Õ5˜Æ½­=Ñ„Ò…LÙILÛÆ1„W»3¾‹GU_…˜|¡U0,hÌØé!™‡ú¢vp	•²¥S-ÎV»c’Ø°B!PYdDtOŠ$»zÎW©ÉEáàÌP<	ÌØûqQ^Ëè5Kö8J©Hç;¾ö,x´ÙÏsÑÙ;iŞcl„æ
 çy– …§ûš©®obOİ…\	=º˜_ŸxYœD	’ª™”®A—n}ä<	=|8¡Ü>IîM İª€h…ÿë¶{À«OVÅ¸ö	#ów‹É’GP@;øAæIûØÆ×İªe	Šúr„T×Š=úİúñtkìF#?é²«£ÜH`&úæDÈK>Íÿ¡¼©ì­ñ“×TÎ³ş?<RwÉ5í'óO¾Óêìé£~k¶d•³Å«äŞ˜ F ò/è?5<¸o¡}E)ÑÔÊü ğÉç çQ2jÌOé¸`Œòšèª­{8¸9¥·Äûofôª=JÁ<’YŠ¬%•Œd
î«¼HvÔtWn…İ§PñŠ:6=T,ÈcSÊhüzàÉ¹:¦—C{b,?ı¯Q h,ÖóÏ´ˆ^è¡ˆT‚!¦¯+º§ htØPSˆp&%õ&ôÒoG¤àÛ2Qq¾3Û°IÕEˆYSÕÖÜÏ;iLÛcÈ½Ë–¦l­şõ±”Xğe×“áï°Ú+%†!stu:ˆR&Âÿh´ÂCã¨1šú§W s½€¦î¸dÜad•|f#º)´æqü3N.î|">7c³Äh„!t‘ÔÛ†¢G¾ï‰†£¥zx&èß™‘Óá^ùBªÃ­	a–rŞ×¾ÜÉ3æ<™—2 ½PW¿mŸYÊ÷»L‰-o¨Ï—¹¨FùÆÛë?< :ßW*de¾¡mÕ‰Øj:¶Ñ=xÂ†¹ßN0ÖÇ¶mIº{–…¶#g[F€K0R«'Ô¥3q7™yÔ‡ÔÄmï:›R´Ğb=æ‰ƒ)V‹ÑvH{Ld G#ÿásÖI/`ÿlWã%ñó‰RÔŞ«]6mØF 4·ÎyÒe;©bmÖ–Ì)$-Ìo=ø8ıÄ uüÄá%÷i·ÛùÅ÷cã<<¥‰°x·”ÀaWÈñ¿Oıè õY‡+V]•'ê"1ÔûÄc‘“ ¼4\Ä ÉØT!¡]­î÷6ÎV^şEò=ÖF–û¯dÿ3ÅÿÎºö"ËYø!.0XpìÚ›æWQfiPfôSÃk@{c'ôõéÁsµ¹Åİ]¦2]í×š»E˜Ÿº·”€¡Œ±W–YMë'Ïc¤Ï–#Ì8ü˜ı†º›–ÍÎ"vvÔßû}49|\‹Ã!6UóV'ÀàÁğ#ÎÖ¿¢\Î¾ô”¼ò¿BØ&í*ÂOÊúæÈğ7òğ’‚k€Ó½÷Æ¢$‚Cãu¹1e£`ĞA“HØtÈÇ²ò‰Ç×'ÔÊàa¾]jc‘Ñ?Ç% 6? >½K…q¾£ölıØY€Ré|4(j©¹3ôq8
]•±[˜ÃĞ³1ÖıÂ·Š*Y3Œı¬TÊNæ2è1ÎÜGÀC1Ç ğÌå¹ZüÆÖ¶™ @sDx½jdş'–2;ËUÂ_«¨È_¯ˆ<ÌËBJ`d
u¨ï!ªçÂ1IÌN×ıè×;ÚC>^OµD-m&ûR)×R32%ÄUÿí«Ø€åLÖcÚr¯·ü£r²;zæ®x’=Öøqk™dL¦ø¸¢7U—~õëæ˜’¾‚÷
FùŸx2'‡e"MxJğOŞ8Ğ-ÊşAıéhNa1Ømg	¦ÙÁ‡¢~{÷:³şD†Y}„©Š½ E
‹%Q"%õ¯»æÌõe›O:'À}CìèÒ˜¤!>-oÄÚ¢_P<>+¸Š”y½/L^å„]!Ià4CrDÃPksW¾ ¨ºÎC¥-şÆ!‚ûÆ³æ @ª”,i/×^¤ß¢ù)ñ\´w”’ÜS»Yn¥UÑ  ı*cÍ‘aåÊ€±ÓiíÊ‰2şEş‘–šL|tÊ¼à)ı2±"qx)=®ãê¸FÀÉ‰ª5-Á—†×¤Är¢İáFbH—€$`'ÿ¤×;xXe&ÁŸÊbÏr~W)¢-º!ª>A +î„l–Á5°––Ùôà­QsÒÜùi-D‘‡¥m2 ¢™jP]×U`™gĞc´|úÈ"ÿq±7”æ§çuv.–ÄÄñG›}#C1&ÅäÒÙ§X¸£Û¹ ¦\`|å•Z`pï[‹³EÍiãË'ó¼q,^áñÉŞ¥ŠÒ†¯´Ø’‘”‹2§ÿ÷·í™ô¡šİpRf:-õ¦QŞÅQò5²@’cH©7È»N±m¹«şD¹5Hääî¸¬Üùµ‚`¤ÈÜá±Üá¬Í%>QfìÍEPÜwjÍıaGs‰®g›ÈËŞEbj¡´r7i·AN¸G¹ÊxìvÁºS¶ŞÓ/€Ì€ó-ÎÈ¤âºT`S¥Ë™âqd¦şŸKµ°•¿¥²Ûöuu …{leT9'ÕaàÃ%$Ä‘³¶³ëZ‰ë†Í§¾Şë»MÃ ú-Å:b²ÖUŒÔhøf…Ò|H?ãô!(a…|ŸRµ¤YH6'ŠØ±bLFÏ§dõ)›Ú›cö;¬İcı—éyD{©: s§Ña ÎdiÆA9(bìAıo‡3°)(ÖÈß¥Ü†ïÎR	u=”(/h-½*¹Øî!ÜÛ´…_·ÉÄñ0¸¡²Ù†Q¬]RB“UóÄrjKJŞœÄ²çzé#÷mt‘İ^‡Ê²÷ëar—7~âIäèÈsEô+×ğ˜(|M)MËï”¤ìñQB–ûD@ÑŠèÂjè7K á6tê}o’ÇG.d”İà_İ7³mõ34µÒêšãzÛh±ï§ÌÁãtw|cÊ¡ÁÂ#k†q®VÛÉešrŸ
K0şP€Ô%º«5^~Üğd’œ"¤à…İ§n79á·~¸ìğä5 ÌêıHXËæïés¿4exî,*D›á²ûgÄ¹]!âtĞMÔ"å”eƒT{X?lÎ_ô£o"|ß·£Uæsù¢ŒCRñC(ø>æÎ5y8éós£º_5êo“E½å Ø%¯–Ôİoá“ßOaŒù­ƒ‚;ifÜhªæ
 Ô]ªª{}}phÅ8÷^•ESÊâÔ@==ê x¯?zH^ı1D.8VÓt·é·›(F‰bÔ¾2µ—Fc#<µ™øÚ&—[Å[ı´uÄ­
‡[†jÕÜ¡Æ”™ì8ûÍbíñÏ‰Èş‰¸áiÑÌùš=æ$=_93³ù\…H²dø|6i«zÈ”‹@‰E†cH&¸£Âô—Á/à ş$OfAÛaq>¾Vô s2Ø1íûµdcw;dAÄˆØşÊ¶›@Œ¸j­€à¨1|Ù¤Rêù,ZFºAxÅ,Åmüé½yÕ"0ËõØr\êöí|hŠ¾ÂóÓù¼ìTr2µb!+™5+8Q•’n;u»Şs¬›•ÖÌ˜=Ç¦İ\×Q€æÙ—Z”;æóXyS¯\Ä²S8ØÂIÅ¼X³ğÂÃ˜ôi›í¸3GÖüÁc¿Ê+mdbBï•#n4rÂ&IÆ‹Ÿ` Y
@ÿ’g;"øÏÿLvûø'ÉRÑ‹e|#(<kÜ©Ñ+ŒN™ñÙÖ[U—çÀÃÈ¼	PSß•7É=p¿&²ö.Œ-äsÃ.‚rwFú èf2-r¾RkÚ?şİgú™rº~•ñŸk§î0d\¦ìC\Øø'ÀhÚ2¥PˆZêãş
‡,9^yùKM:›y	Ÿ¿lÊÎ&©*1õë –Ğ›°­àa9©—Ï š~¡ã?ßGH*lÇ5'CŞ-õ†gÁÍpRÙÇo‹Ğr,|Kñ÷ˆîæˆ¨ìDøSY—õÊ¥"»o×NN³¥Vòu~Âó¹&&UéxıV¨0Ëcıp	ºë–búsÉ#ß™¨++JÚ²®M“¾ŸhR‰ËuwµlÍSÉwm?ƒÅíç—¿ÈéïÁ…ÛœêÏ¸ë¸šgBÌ€zÿÕñ©O3"mqïú¦û=¹mŠ<–2—ÁœšgqyNû`“ûèm'Ñ<C±Ò,‘Ø¦gB€œ«|„¦]À< œ…İMİ†œİÒyãœ'm‰†×ÜÛxR!ÕœÔ-Õ	õ°J*Ÿ)7­Ó}îˆ¯˜Ê'õCŞˆ,ÍÚi}ÌMæ-Ş|Ü.År–%y5n:°¤sPQzDaœf”"f—¢’?ı¿Ì“|i´ªt÷®‚÷R§>m·\B×.¼±P]#,ËMşàß–yî	§mV'¡+ß¹jw_O P6T“É£ÏèÎİ–ìï|?Œ}Ÿõµ”–šÆ,

§X^µ×=^j[cc¿y E˜¡‰ñKğØİO§¶&ãá…îÑè:>®]ÊKnÄÕb¨¢úÒÕiaÜ_X=’P—îq{ãCŒ–`ù‡•0e£~Z¡ÄğÓ—/)¶àá giÉé?Á.!±”îó`ö(yÈ^ù™ËÄ'‚ñk™`6ëÏ«8¯5è:G´Kkº'&Â›ğÚqgÍZü",uk„›yò!Öwè°¤$w¢Ï#^(ó~@ÑOÕ(dÍf*Á‚XM}Ä´¦ı»–ü1Æ¼¼ıõqÅ‘§šDxnºà% Õ‚är1ßøëÌ§›¯g¤bŸöeà1n€³Ûr8R½¯³åñÙ‚wHñ:™Uƒù3³ÑŠ*÷É?…º/jZ}i|AÃ$>øĞ\ê}™ ³"BÚ“/C/Œ›ÖvC¦0c&Û&«`”«³RWGm6ÿIßd) ^“Bpû±	åwoÌ1Eb©•ûc_PJ:÷¹´×M¹¦VÎî´ö82Í¿¶–¼„f¡5cÅüº{/ˆØ¯òDÁ²šá“°¸MˆÏjM-©¨Ø3šhÈf"ÕG×ÅCIóÈ²>šqçÄú.tùô‹°¢IJJ/Àö-QoÙ«ïtâtÇ©°šãÄ€v‹T*½fM”­´@eX†¨¹'Ñ2axë¯–1nıv’ÖÄ…~3Ç®”S©<íò@Ïp1ÛÎı£µ‡1^+úƒõ±	íËSYùi0€ÍsŠ¢µ¸±¦&ÚÊò:gıy•,·úÌ.â¸Œ‚4ÙE¼M67™vX`‰W½ü¼Lnô½yVu/—ímªº¡¥KĞ¶!L9·šñ"çb å
¸_éòÚa'ÁËNIö¥„ÂÕMgv€*
¼—™¥¤ÛšõŞ4’¥ë›ö'-–$hÔU®b°öBŸw¢ñåéNNáB›¢q€ˆqiâµ-s!g,ôœXkÚ˜Š-?Á}GÜq|îœchàûj†Çrv2™¯È6 “ØõœÁ7·9é²ïSîòè¦3<l>L}<©¨ÃIşl8ñUcÖÇ&iÆN¥¢O€ÖårpCÃÛ6.%Å³ŸÊü?÷àoß:BQ¦#H³‹ÚıBuŞKì”)|ñÔîFêŒEVı2Ydì‰a¬õÉscæ™3ù@B;[­"®R7ô©Ù¡Ã'œ”Õ·ìPbfÄyøCØê`}¢» ¡kòÜH Ú,bBÆ5Àöî¸6låW†(0ÚÍ!á£‹Ê¾ñ¯
CSêêdmS\µNÅz^vŸ„ÀÆÊuVåc#Ïc™Ád%PtÄ¶¡ïsŠêÇ‡/7g÷Dñ(n™™òØKr×ªÓéÅµõ›€Iû÷#XWo-ÀZf›?«˜R`1f¸Dm?dh˜L'êAøœ½ÆŠj‰´3è³|½j%Ş@„†sÙ(Šœíµ$E6¹HÇN1>æU&”‹ÌdÔ"
IƒYñ‰[ÒDîCÕPc*&*[i©‹‹×ÄæzË"êa=
o	ógˆÒşvsc6åŠár·'¸·ßr»åQ]i9Â3|p—D²ùñúvrOX”ª"Äı,ù¡ßâ«P²C(¤ó!£Ù˜¥©šÃ`<—ù´vá’ÍHâó‹ùÖÓ#i*,+è±#båa(Ÿ<¾6¤¢²\p¢¥’Xñv$a€i¿·!Îô¼à†áHyˆa•WK`„ÓT”¤eltW‰#ĞÁŸqı*1«æ‘séX¨Û¢ÔƒB59¼RT;ºíèhÊ²NUa„øi»=8}ºhÅ$Z…p×Üo¤l€€z™xE1gò´tëÈC}²Ìšìø/šĞÀ‡mıG5¢Å„Æ¥ó)Õ±«I}ˆ>!8U$÷²HŠüûƒD’´@w~’œe}.¥‹yéÀâ·ƒ–scáÑyy‡p"±¨íAKÓ“¢ÂX¤xS?#KTM0/³˜.Û4ğÍÉ²¬##ç2D¯½šSRˆƒ¨±¯^‹>,!ºE‹f9·©œÉV6˜ “?Šó¥²'·ÍúC}ÕãOõ±‹coc­'é-ï^g\åC[â_SqÜ‚ùQn¶Õ‹¨+3áš.YpÆ¥ÄJÎ¤‘¦=jŞV²€™¡ğáNø˜»İ‡5Çß–-‡¤…çk0TRçL_:- T 
¬Y–T$ {À*´ºÏÕt*Eyb¦¨ ‘öq¹„úìêLh)·ts¥}ÇÆ»¤;|^«”`ôŸf‹
³óˆô?KØ½Q?¬IÚPŒŒÎC!ßz²ªDá67‰è©íëuÒ0zèøC4ËG!$H
Û(ØUª—ˆ ^÷É¶­+.‡RjÕ&9ü¬L`Mâ±«b®à#`VóTWÈòş(°c`wmE9+Ï˜ÖD|²IÁL-PêÔŒí¬u¾J{o¼:Êì”@‰@š’o& 3D½ˆ¼¿ª–$‹˜$å§wéº§qgzc§>Û]ÖaI{¢5)«d2s#ëğ³¾ß·§ğı`’âşù‰)/ëˆp2¶–ÚoC¨Ë‘°0`Ô– ÌBpúßTKDÙÁ¢ ­š8[GÉKç<vß·F'2–LêT¢Î!ºÉeíŠOwN(8Õ¯­o‰@ˆI*Š„Î"À£šbcgšØ8ˆÆÁm)‰o	|“Ïl¬iry—~wšÖáùQ{º#àcÚ¢y~æ¿8–ÒœXpBş,Ûeâ<ì€7è«¹	•îw,ßÆ·â—aXŞ¦1¤™ĞûCÙ^K-çªL«)jãócoÊ=ªüİdY½³(Ñ÷ P'ø½o—e5í­^^{˜k¸ŠÅ}|ãò³™É¦æ	ÁÂ¼ù&ñ˜q{¶=Ghƒ³ì­ÿ
H~8È~ŸşşcïeslÅÂ†ŠºZús=Ë&’ßázk2gZƒPàxÄ„D½c¥şLr¢µxûPTß~b¹ãGoü^€jgAÛA•-Ğ6ìÄ	Ãf2%øš¯ à4­dú×„µ³à1€çŒP¶|(«Ûñ×R“8‹‹³ëCÕä¶()8õx65-–N1¨ñJ?¦r?Û,DƒcÓÿÃjs<ÇÊÊ7ÿ¬ ]4ûo?–†ˆ\éSğÏä;5pùzŠS
#T'üV<)zMàÌûZØºÿ
s9(ts³óø‚FM.S·«®#hÎü1ô¢âNlRÉÇÌl&bh—£DÈRÎÕÇ))6B¤B_ Ì¶ÕÉÕËsÈ¯Ú¬h!Z–ÏËHjäª
üšf‹;×Ñ•b”£ªÆàn·}bÚwıâp‰"•ĞSl¼ş^Ñ‹±ü…Há>=©ÔÄ†Œ«Â«Òœ#ßqÈÌÀğ½>–’Àà+"V6†lâ‡L–Xt¸Q1Ec…IÎÉUÃ°Á§ÑvŒ¨>òÕ¶Ÿ2~!˜2¶—6ƒ\ı×š|L„ñ¬>)ê‰Sk«‡9õ;u¨$M®ÅLïˆheÉÇ–ÕƒsŸ—²VÅ	`1æü öEhÊEåğÕŸ¤áPi8Şmâ¹ï+¶xß‰İÙr£.‘jLúªÚø«ş²é"©jnCV4ı'õ¥ü§Í=‹Å.+š£±õñ‹ñ1MJu¢¡P8ÆË%Ëú¡î~(¡úJ"”œK¹Y(ÄÍDùœ]öÃòN©ˆ#†4©
Ş¥£ƒ„zG)N½ëŸéõÄFBöÆ
ÍKô,p
@“NŞšñtD–ÏW8¹—îW²K¥Ü¼ªğqğ]m)$­`–!ÛLÓsñì@{cú"e`qğì=–FÚñŠ"~ùk~iƒ€q˜v›o"ÇÒ™…0=å=½/ã	nĞd>şÉù\æE™àŒÁVUyÖUR×="•,…³>y‹Ğº%_å\b+µã{ÂùÙ#¬ĞìÈÅW‘“­h‹ôã¢i¨B¯"+ñ›–Z¢‚\(Ÿ~ÎDºŞ0s«ï±1…ƒh=l~¨'N:Û½®E9½S5|hjq&Ãå²éU†ò.Q1µ«Şg¤Ë
9u>—ÛĞ4†øz}<Õq¯t²@êL[åŸ†„tWPÑ%3%h+FüfÖÄ¤–ÒQ¶©ƒcµ½}Q­­Ÿyk§]¸°4…)¢Ë¬ƒİ0$(Yà2O—KBÊŞ;0¬Ph"Òå+Õ
²7 XVT(èFAE+QZA>b—ƒ8›utE‹IzÑ¢€ÔµÂNê!Î'—™ä,èıaV<z	`@`<#!Ğ0­Bµ~ù®4ø©¤£bÆ£(vúÀj½Ø¶w¥µÌ®M"p|RdË#}Í]®…©ŞÒ±‰CÔ³êg]¯9j¼åø¢5ÄRM2HÉ…-+[Uï¯™c¢Pá'ğ mN`$c3Ø”,Rjá84}óL Ó{KHõ³mÕ ‡;ÁNÁ’v\JËTÊ¬8‚ŠıM-%£¦§4ê"n±7¢õKÂÄÆ¡{]¤Âb†4‘ÿDà§·3cß÷?û|¢¢úR¾¢ªÅ¦ØoõêvyÉâŸÓ B#hÍØşó^ÍöWÕÅv”_ÔÂ±š±€ÍU~j„˜ÇÄáÉ¼¥#ÈQdñ/•]OvXo?Jé¹U­Æu)r!-4!,ùm®™ÿi¥\¥ĞšæbÑœl³¦0/¼•kò(ç©½íÂ|»Ío(l¤\\¾V>äópİf÷šl“™ãìtÓ_ò _~·f¡nùT¶j5`mceØ´.È-£iŒd‘«RĞn´®F–ñÀjd›çn™#&îeÓ	^ÍÖÅ;õC3í’Šef_"J÷Ä–ëuJ®ŒÛ,¥š¼‚fs2ÇNĞÿé2[H¢œ¥ŸRÒ£÷C?ü ÒDédÉßöpr-Láİé°m—œˆÌßŞ+Zç•h¢Zîä4Øq”ºfTb{%<Š¨Î'Ü0&?c  ƒ'õıÌ4Ëic‘<_İF*8mV'¥¬ÚÙÃ°˜[u´¼ÕÊúås02ÙÀ˜ê‹Lµ‘ùÒâåøÄ G~±öXp¥,Â´ˆ^ÁdÂ¿8*şî¿_‚ó¤Ã¨dñ ‡ÚHP÷ÔK‰˜»ÁØ?9°u^·!²]Ò=à¯}ÒRX¬$,0wJ+[A¥ÂÜQde£MİÃïŞÜ Ü;)ç$îû€åâ®ŒH€Úî7“šÆº©ã9×…ÛE¦ãÍXTçšÏ³Õ{ğ€5¦7¶²¹'DOõ8FjkøÑ¹Î„ÕUÏ½ÒË—,&Õ[ç„ª h\'Ÿ™Mô
zg.r]ºb¾`^¤9kÎÔ®RÎÍÑ±C4_a,Î¤JÉS³_†Ñ–½±*\(ëüevSØCó :—c‹˜©,n7”ØùÄ2¶;‹j7aıHòêòÍa°àŒÍÚ”ÛË´I
§FCOÖõš ¢D°<­HÌ6ˆ-’ØK¸/r³pÈêNçç´Şnï‡ì»î$Qã ßS¶‡s‡3iÈšD¯×Èš¢OH”¤(BŠqhVŠ8x,¿ÉĞm_º’	Œ)§yh¢fltG
É¨.¥NÆ»™ñÕiÊoÜ,èÕ˜Àˆ[K¯Ã™ôÕni#`½ãii’»&‘ç©´#[s¯È:–Ì?ÚDJkWH6a:`ÅlÏl±Œ›#úÅg’`~•dÌù¼G3òWã‡BÂôbÎú%qIƒ&CaRÔŞˆîIæg	ªMõjĞqÚW(¹ËÉ¹ßIçFš‡„¦&svàâ‹õº­T–‡Ê@ç„P¨ô¿Y@c·[(á]Æ¢òÙ+®^1Mí	~~ çßc¶é® BÒ-€%í(
Í§UœÂ3ÔWº“ĞŸe’…ÏõÜáÉÊAt5h\T®n/%6¬/ 5EN¾èóï¤¿KZœj¸ yA^:yO·“ø"TèßÂX‰|€nòYµ™ÿ†>âTıOW½“›²Aa<,“ë ¤£íÜ{Å'x€5¿T×x'ÃíåÔítõ£‚hØÿ")Í«èİœ¼Ú#=s çêˆŠ»˜sKñ°‘SªL££JE1µ']1›şª•<÷6³Ş®8ZÄë¿ekÙÄMÊ·Ÿæ ^¨cGòÀl}ïR›«ùàU?±Erf2U$—‡®İò7	ß|¦•¤ë(q§4«ÑŒŸç“I	½¶'x
RkŒŒïY
ÀĞéAñ¯ÌOI£‰äğ l0»Ô›|umB6ZïwJ3‘úkNé¼}ZUşfÁ'd“Ş¢îl­ÿ«6\*vÿ„¹®«ïÈêÔnâœJnprD‚öˆ¿¹-„êq9£¿«œ:ÄÔr€‡v¹Êê¶Ó‰³/q¸bƒì$á“x^şQ?:°2¤½%zsp®»dİĞ€]îŸüã‚Ü·£«1üÔ(Q”7­sA¬€ÔóÊ¬U•íV
±ñûqy‹-#Ú§JECã²%ÂO ôŒ[Ñõ¨sÀÎPË®‘ÔÈYƒ©òŞø ÛäÓ­h+Ì¹/~A6ô@ÊÙ5°ÏiA¿áÙ"gªNñèmÆç8©Íì„¸W÷s=W‚¸8«)~ñ‹Öÿú0ÖZÚENÜs>ÖÌ&µ™(¤èW¬&Ïëb‰è¢€z‹:£pc)uï:‰ ş&ØL­vâÊ‘?—r]Ü² ™ï^k
%C³< a4âÃ„ß‡9;›&ŒêòZînyÊ¶ñÈF¦ÃTD—¬ÖøLH”í;"‘×°+ìëª/â½!´ï¨Sçïùÿ«ôYÂˆË†‹¡‰fk¾rcS»)pÜò3d}>mö¥­4ÆU¥ ´`Êgù¸	ËÔáf[‘æôI !=Z,/J«fC(Y^ÃÄLÛf/¾Õ³l3œ<GÊ_z};	y˜ä<µ@ûC6Iı©n×^™ï;íááLîz»²èèXì…Å”“dvlÅYÅU‘½¾p†‘\fœ.ëœPÇÛ‰lİe´€İP]"C‹tkçÎÉsî·E¤ïã½«Ëô•½ÅMñ^7¯ÏMøÂqß5}2$8÷EÔ<ªßöƒYæu÷]åø¨ÃŞÏ’èÎ´DpÍUYæ”ªj©n‘º»
XDhş±/RCí7û»â/9¥sÕè+zcÍÈ [K¢`8e¯”ía`"ybfÊÇªª5²©ù |«Bn>øf#UqRödx#”(2Ô‡ôA4“Ò¬	.ô‹çD%Î@µ¯q¡$Sp,løpP¹¸¥JëÄ'‡ı^ÿ|ÓÏØX&v*K"y¸oÜË¡¹tñáş{¸PjúåTeò#W#w*ä±6•è£‚pW·Ñ¶(‹	.Õù¼”Í©ëï½hZxö ¢(÷ƒÂƒãŠ»ÄhgQY:~tëND»x$È×uÌÊõõX2XŸÏ%m¥&§Å¿‹Ôoo–SÔ*s¼gÿ„ª)¯î¬¨F~ğq×$¡[û,Ç¬§ÕÍTrñÈ;Q²1†p	#,¨ı†J9è2BUó
¢®1“"j¢Š9×²G­zÓç¯‰êÖƒDµlLÀkñ»şOé-ÎÕØGnÇÿ8„¶ioÑ—P"+3¢´v›vÀ¸RDå,QöI(¢y´…_¿–cØ¾ÌvÛK)ŠÒ¶VÁW¶|ÎÇÊ­C½—ç‡ä4ò6æ}m’Üı`ôÔŞ$KÂO©Œ3Š×–ü2öÊ•Î
É ç’Ó¸š@†]Aé_Ä¢@bLCP pWi¤~Ìt£êµWç |Yüİf—Ü…)‰”PRf\$¬].çjª^¬F$ÖâV\y ¶kW*¥mğHuZş+$~rœŸÀß»¨¤}³:á+öïâ–p¢ë²‰á¸·q'úb‘-ˆ†uóõ‚3¨÷¡~‰prXKëÚm£U’³Ö¦á…^»E+3¦ı¶ÆÕ6=|r4N¹§1j@eòåG5]Oé‘Ğ[0!¡‡Ò5’r£ñçÂí‹ßÚ[tTıÖ¶ÇfÓœ,;JˆŒW[tÆĞkl9’Úo`ûÇgHßJZå"h=»æ•¯u™–î‘64ç@^LÌ¶ÿï…ù†o™Ê"ó­X¸N'Ä)’À®Ä`õN®jŠéÀ#°İXR¢Ï³ó<‡%|‰˜İò#UA¦h>~1Ó/–bQAâJô|LğKâ¸J÷ieuÉ:Ş	¹3Ã;Ù€ºX.}âÕÚ‹]8ık@Q¢'ƒÄ‡¿Xß³ô]Í{¯‰¤ÖüjsÖcÎD@ØŠ%?¥÷¦9ö$Èµ	GÑà§ÉJ·¡YS2ÜŞ‘élW©Ïò6
ä}õbm~†á‡õVz|‹µ ŠÒì‚¹±Üá oQ>x{%îŒàµ)ÑÙæ#›C4ãÂ‡\D="Š>Ã˜?õ‹µÇ{ò¿Aeï€ş…Y„‘•·©‰_&1Ø÷D_s´“ş&Dê|¥Ç–\ŠŞ+Ñ×.4`ŒE¯‰Ìü,à;fğ)`V³	vÄ—I…Äø˜ß¸E6ñ,~#è®ı ú%¯oN¶ºSîº°x8ÍƒÛiCñ÷X‹é§ë¸"ıàÌ¶5ÖªS")8•÷¨ØH”Ô™cb<a{’ÖG›OÏiˆİAÁ 
ãÈ¨VDÃZş©V¯µ¹å”‘¼šØLwlşñø$ î-Ü¥¯´Œ/ëh¨dßšœİ'²\ı.º¿Dw€M4oèµ KËã²WÀŸE­ÔV¸F«¬îKÊ‡ç@‚×ísGmÿ\ß÷bz¦]¬”l-' ÆâÇDöéïóš9.ÿšÕz}wl-d¤Pq½a1Ó°5ÄTqâßÔ¶$Ôz)áx'àâ­!#;b{DıLÈufßğˆ¼~š£‡F lPÄ„ñ‹j³Ò~WLX™ÓN®­O•kÆï;4¹!.ô¦Ô]4:öh¿à}ï¾ßñ·Áª¥âEYF¥
¦Š2Lp/3…hÛcĞ›¬/ Oõô€…is—†ûKŸ1Bxá«­OÆ¸”M‡/f(Ãø^n¿aêîŞÉ¯6b±H½9l¹©‰k›üğç¨Yª÷ùÌĞVƒ7R]FywGt‚M0ûúX®çî™±p¤Ğg8ßù‡ğqú¾é|ï‹‡Z¯Y·ÎFj—/œGrµš·–ny}å`I6E;3	¢zÆñ¯‹±QÍÆ¸”\»"÷6ÖK¼ˆ•g—:ît˜:EĞ0…*_ID>³xñZr8äã}Ô$\‡6¼Áa*ÕMıãíe€ºóÖoj÷›êk´	3µùÏëıUwêLëÆ` fV­õóùò®ä´ıº_Bÿ0MÎ*a»wWœÔk¿Î<GOr/ŸrÿÑ:êqjÙb0êÕÍ‡»Ç€Ôø›–ŠjÔ§ÜgÆ&+:²ßSQ5qM}ÛÚi@¡á½¼™Ÿa*0r ıå	ùJÊCŒL¢I¥ËêJ¼ÓÏôDÃÒ¿Ë»%qè(»	é›î^"~¢ÇX>í9Ğ?åªÓ<-òíX [!@É+À_›~ïS·õ½íµí‹˜"¦~¹ş@ôll¯S°Jê¶ÒláPbvJ<Nâ†y«nÆtú0O+ËÓ±Ù.ıÕÓ÷ ™%hyYÛÕ ÔßöCyÕsÑ'£$QÙ1Fé÷Zgÿ×ZàßÚH™&çò¶HÏ…”l76@45ï-óî=«…ËûYÓ­¸¨Çû>àlüú<ü“æFöêô‡(–±…Á£P5F–¹şüÑNP3R"ã‹4ıä€!Cº=”Ù}£c³”ÜBKÔ¾Á›øój3õ8	+Têuúè"^:Ø_UËï:c¯ÛšÃ_Ü”³m·±¼9ñ´6P®)XU5RCŸ[’ßŠX%!ô:42]óZÜ#Ò¹ı	w[&ğõš{Ø€yÛzËÉœTîäZS‡GÃù&‡×#»¥mŠYDª^nx<š¦¹Õ)ïdÏH^¸ålC}§µãˆw+†4À¢hW©°ò3´jzºÔ~|µ:Êç Ş5ş¾dË¬¡‘èÀGÖ„I‡çlê}’Tw>à§|Şñv9(@™ú èñæiqp:Ådoü$¦¾ÁI+îa™ÿ¹}ä>_­VÜ‘h@ısF&nqibÀÈØ˜NÎF‚ò¥¿”õI”ú>Şıaö¸@ÃK ¶%‘ñ9Ärô>ÿpºä|'`š}äµ ë´tm&?ô£:È¶0«[·¡Æz
j¤AzÀELaxX¢s1èH‘À
3cd¨¦äChçŸJ³bÏıEœé¬±¦®(èØH8|ç³?åŒfÀô»3ŒØ4„JÒ”’x¼ô¬‘´úQ*7ÍœÉÏÒŸÅ˜–‡fâ×¯¢îx‚B±ã™
£¿Ô›±R~/ß•yx|ß A. åÆşv‰@ğm_©Áˆ¼¿£íkœwKhAk™h@K­ÈÇ?|VÎ+Ì¯‡¯Ô®n›kûŞû^Ğë,˜0*ÕTöÚa!ÿÍ(>ş%P//†r4¢àjk·ØßŸ’j™Ê%é‰–<æ³Å’ºdhéÄu9¹¶MÍ¿Ú8š”çS6—(İœ)ô*°¬*YfÙ@±ÜÌÆÌ´şX ¼ıœá¬¯¸†Ã-éUœ:nd©[‰ÁÅ”bÔş–¾4#­ÂËZ²Tµq4¤jØÎá$Ÿ€hÇ2›DãY&ô’øÿq¥¡~ÿÓ6ZäşM?64šæ€Åo¶Óã¿¬ª5ß?‹ùg}NÎ¯„’#$#VÌ’¥|Ïgß«&Ï÷ì¯ÌÉa¬…SµÙ²îJA,„E¾i‰­tÍš»šŠó'È„<±ŸİÈàk4DÉ¤Æ¬»›î"“õšÜƒaÚ>gƒ£k{{jéç2É,ƒÛi36†«hr¶[‰K0’ëÓÁÿÖÿ˜:A}çã q (İ1˜Ô?•€2i™oş3ÖÊó
1˜_vü™"K´%›…›Ë¤âÛÌÀØ/îs Ãc´%ĞUÓƒzAÀ|±¢-Ë¸h/ô`$…Gå‘;ˆ|–ö6¢sØ«Q%2˜IÖ0UguäŞbkNïÿ›½<Š6Æ7:4!*§¾®-ÏÚušÖçîLñÊW§tØ2šÙOMÀ°(pBœÿ˜ğ­Œ¥@èÿ¦¹÷uùb~Ù_®é›WzÛö»æhE†[,JaOÎøyœÂòö°jUJDqÈoÒ>-Ù²µzØ¾Q ¤IŞqxwÓJâ‘½eºêoòjt!=µ;gÈ‘;û ÅZ†´Æ!äh":EnÜF½Ş½7üAà_¥PjAÖ%HhÈ[ìlL8vxäYÚÎë/—Æ9¸E5ÔaZëÑFm£kê¶0y$YìœË£1`ZZãùèñæø*˜jyw—-Ö«={–€†ˆŸãœv|aüÛÁãÌò"ÜÕE/±AÇûsÏ‚h[çğÊüW¡‡„§¬€"ßošGkZvú»§D{öA´Oéó±«ÔÃ£Ãƒë-îw&7QSÀ°»°êVä»,‚T<ï)H
„´"®Y‘j«ëk‘€ØXvêb‘âwu¿?eøq{§^ßÍíZ]"€#_õ?æBá^Tdàxˆ˜å!Ğ¥¶ŒìøI'%dÇÅeS[Th›äkŠAİ*W¡ğ„²r<–«*R°›»­‚ÍŸp7Pä¨81‰ÚÉ§ò,S)8èòçbòÂ*­}}1®‚ÌA6·cÑÇúùwÊÚQ‚,á
ÅFÑ!™È–LZñÉ½Ÿ•™‚‰|1Ä>I~p qé[}íÌƒşŒOŒMÜ;…¢¡lÖ êš@ûg…Quºq$9J{‰³wJSŸXM#ñ{ôeèøˆÔÕoæ~¹ÛİñI¨Ö[Ì÷?fØí$LÌoIgµæVsq/ÑøRˆyÀQíÆ) îQ æ¯è´É•“WÆñœÌE©•ôîÁV|vb2ˆæ<»Dp±1ú±KmÛ€ô=WÜÛ ”'F9NX*hÃ9³`!nA¯%DğRO>ñú^İp³»ÔğA”Õ6’>V’67h*‰êòü÷`B	7¤5kêØÎ}÷İväîùbPˆ|Ä‚£"˜!Õ(d_19Òƒ		ÅŒ
\INP—°Â6¶á³®N­ŠKÚXK<¶D½äßO•‰$	÷W(À=m6Xê¹ ıÎmo0É”Ò°Äï–”$ñ^¤qfä— ¯eà¬İ¾jøÏÛçïjà€œ#²è(‰]¥s`¨4„5AƒˆyÇÜ&TÜ`[Ş]+q˜ƒ0w³4%9–G“åŒöïØàØúÉ-Ó{c{–AĞC»ÄX‰[‡e»Ìà‹H,õ‚á’H·O²M€82bçÖı,I%ßT¦Ñ°æ”Àä7h†çöˆxö!®é[GøïÒ(7ù5Éõ|íá8	ğæ¼_ÓTŸ](AÓz	Lt,»
§àhdåÿ
ÊBUO~R´¼àã
eNË]9Wa-7ã{zÇ!r(ÜÒñÀúyFpË˜Şk0Ì;~]héé›°eûòSøº¬Í™^ odW5‚läÜ#Øİ/
2ĞŸ4^z)!m•É/PÜíåœXÛÜĞøgb¿°j×ŸêMÛêçíp€åŒºÇx@¹ÃtäxWJGø-£éšï~>‚‚!MñıW´*¦hºÙ„ìEËÄ¯H”•‚½ƒù >L,Ì²ÖìvƒGè?’è2E×%¥!ß~ÍÖ~QémAĞNÇ›;Œ4dÿn5ANÜ$µÊ€É¼®sŞ‹¼¤h²İÀ¤
÷©F€a\æ]ê,"¤0ªæ××í~Ì°•ÛÓy…ş? 5\°AÑÀ>\«œø”¼Vt4€KK¯0Sèø¿}GkĞ°çÏÑ1wnRªLƒ’É»ĞyX]¯jµ…¤gX4ı	‡mDÑˆ»SöÍF¹`ª|Û¥ÔFúåu Pµ[Ó¢&$¬hQ{šŒ¹-ÍÆ+²Š³| ÖöB½Ê\i ŸQkhÜ††(r¤7")G…ÊùÊ{[—ŞÁy'Şı†¥ÅXùïPF:°•şƒYE²ËÜ°æïûÀ®&¸½ë ï¦cÍFçßC˜ù	\aeÍ÷±9ï‰zgdVhûZ*ßkÕy"›í¸“õ ËŞZåj\fğ×fZp`D"îøÆÏY—¤#»³ŞA’RûSñGš‰øœÚ¯ÄÆZE7å€ÎmF'‹õ6e`ë&Hã9tÒiö©`öĞ’ÏI¤%ö–Ø¥VØ•¯Í„*.ò³=„SËƒkã~Exù©-Ü&µ³<„ùn ó	çå?uá ëÄÔ¨íÚ´ˆİÇÖ®¬8.ŞmÀ_ğ#bæÀÍÌTZ)`%7uwNB õ†åußEöÔ…É¯k aüLi‰ -AÂ³Ÿé¶yÖøÙ 
Œ‘u•©Y2YcdÌ±œ&f8N&#)ªq$¶Â%yşÇôdáeÆ¯˜³KÔõ€¨M‚•‰ƒ›P`•§ázUÀÏNF8³]HCÏ)×=Ñ;ríà2|Ş©+ªHİM^•Û2} îÈŞ,½EˆôÎş>_>ïB>ÌyaÇ£ö²BèJlŸ4å
“ì‡E—O¦ “;Â[`ÈæÚz‰‘<EüÈUÛ‰×©*gÖc¹[ğI(º`ê®İMÉ“ë9Œ´Ûu|³øı!½’4€“q]¹ÍbåÂƒõkß$}Æbñ"ùÓBúzS‹Ñ/:¶œ©¯ÎøN¸Ğ=/C"$'°íÈ´Î¿ß ø_o¼nÅ´&úCI­o.Á“å ûÛ&¸©­ê¶ÔÑÈ»ş=ªì&ıÎÉ“3³"Ó³ò1SDŸ°Ş¸ÀØeáh¢’˜(ËD§LüzxT•…t[bbJÙ-â×ßX¦}*ÄºNVB¥’"‘Æb.˜”ßƒ1G†©yÅö€v%ì°g¿aÃ4Dñx¨¢ZQê¾z\r-râ'`F5kDn±»9´:ºB›îuî1l×"AUÀ Œ¡oR~•şÀ¯]$ r~1F]éàP·¤éZØEØZ€"ˆULv…OUÑÃc¼Í¯T m
¼’z·‘ƒQYCš+w{5K˜¼‰«`q¸Ü€qY0@ÈˆV8ÿ'4€¼2M'RÒo€¡ôV¬Cı\ÈÙeU ƒá„·¼ŞŞRé¦*“ ¸qgÔ-9y£%E£ë&£ïC;7í-ĞÎUÅà}Ì
xo÷$½Û'ÁÁçÀ·şî£üx•«ºc+§Ê™¦ŞÁOSNzà©ÉÌt,Êí6<â#'Ái«“¡—ıwúÙ'9İ2®İm±1ÄeGá-·N­ÀfºnÔ±êm¡ÁÎŞ'_Ô38%Cş–7c{ı(öeÙÖ Âíã¦“#;?œª,°ÄÆ3M@xté†';^ ¥'ê4v‘5„nº´‹â‰ËÊ—G(É›Î 'pz<½•èoHê®ªÜıá¯J`™Z~
zñkƒĞ½ı,ìP!	İ¹°Ñzšİà%é_ÃÎY‚É¤F<C`¾ï”wÍîĞsà-CiÜ¢š=­aÖQ‚œîN¢,šwÊBûÑ ñm‚½©Œ(;Ÿ”õ©éÎl$÷UcÃ¼½¥½
d±ƒ(Új.¿£~L´[?7¨û$>Ybt
İÙòzS‘¼<êÏÅ©3‹U_„Yó½+Ÿ+S²l;ÁIbO<Oq-Í5—ä¼wyl­JŠ´+VÔ«‡Ãèİ{ ş¥°šë¸¯è¥,úéèË² Wiv1\>çĞa\ŒÈ|ï¬¡›<Ú¦’ÿ‚Ù”Y¤­[8éãsUÌ?W*Lœ€¬7ì¹X”´A	€¾(lu˜|"]zŠp‹îeñe9\[Fb:¤:€rÑÂT${K#›¶^ˆ{ñ›DšÆşĞg›ÄzÁPVpÿP‚$wø¶ú	š×›ÃtáKåqc%¾ó¸¤*#|İPa»vªÖŒòvièH(0¯áoÈ:Ğ+V¯—EôœWª¿íÜÀïUp”Òd,N‡Eù§õ‚Áøä–á„K”ˆßÓ
]ÈûCn.•™RÆ)ZÑ‡ †„ğÛ½{ûg}8Ÿøn&ÛM`ÇÄ$™BœÀ–Œìµ-dhıá27†ùB.n[—ÔÇ/ã_ŸÖñk\Ù«O¼O>+#:v){A¡ÁÿLÂò,ÜHÃ]r«<Ì˜LJáİµ8jã¼§c¹äE0 ñ§Ñ0JßÅz÷EVšõÜ¶‰¸
/òÑDá0é òšh´}ß"Fç>úÁ mg€[ÁWµµb£ßCXZÄ„‚‹zï°íbœË‰{Œ÷UâRùä=6GûœrNî0™§1ª+²aÀ<ë ªÓ(GöæwjJ"%}ğš€ÉœR®‰Eô‘f™DÆÇßÜ+ûl‰”İAFÖ%î÷A7æâuòhÛ,
‹1‘jÀ²¯{D_Šÿw³“½Ë_AªÛMNÊu50ÀW©­„Æ —ºIYoQŞM=Ç´q|pfeö°Ç÷ˆp3æ®Êk³¼oÃJê
7¹ğx] ³sÈ„GçIÅ¡0L´—3ÿ](Íàˆp·Fÿy˜O?ş‘;,Xw*šÁ?ZiP¢Ês­Jë3÷÷dšëÉëÆYq<ŸÃq¡‰–6>4
up ½,yÍqW\H|}¯/	Dó‰7È?*Ò
S¤†‚ŒKp¬˜9¬}£ï^}‘òİÉ[ «âeS;ü¥,[ÜËÌáüÿ	3VAñŸN†‚±uc]%#)½`GšN¼a,6¼p´2¯â/ËP®Œ›ñ@Í…6Àì«-¹4¢cÔ¡‚ísë¥la©¬¼ĞGL„·—Íƒ‰6‚‰Ş£ÄŞA„¯,æy} aä³Côxµª9vş Ï¤l(­ÁfûÅËV;¾¨˜b¼u#am´ÖÔFÒú_G^:.²µZ¯	BĞŒÒê`eÕ^ópÀêˆ_¥+L¡õ·ÒFõ…ÄüÙo‘™”¥w„°V‘p'r‰¾·Ü@¹HWE#°iÛÓ:-ş‚Vı×æî>K/ËM›B·H?°2¨T«bî…BK«Ökwén¢7ï¦¼ÎÌ¿ÅĞ“,Òpœ*ëÚ®t/a—Ía½¼Æ¹°M|Ã•{ó‡pç}öeGÑzŒ–}%Ü$”t³ˆWªS3Û%ÉÙiˆÔ}œÄ)_¡ci;5Qœ’İ(RßÙ*µŸD±d3Ï£öIWó÷XÆWÙæØÌd74¹Èu„Az‡¾S7êÏ#'%|ÂOÇ0¦å{§„ƒûL/Ö¯æ2ì‘¾`TYP‘°çáóà ² —Ôæ"Ó>à’¿VäÍ„¬Z²çXğœQó·®#9|Äy¼áwà·Ï‰oİM[W5+I…#R3 ŒwòÂB^Q
3ß…Æ˜„šO œ’H•w3¤Y‡[%Zæÿ|ÕùğóôêŒŸdïó”»˜¾0{˜—-n!œMßÒ¢@ı—+ZåûÕg,7ØQŒ`·ÄôoÀd:¡ş I­KoUB¿ïó&ÆJú-óåª¿]9T«ó7¿çNÜ %"&iS¶§şç^†êä[â©Ü|à¹ü“fÕÑK¨F›ÜD{~ì.mçİGÃŠš+şP-`<¯ì=°M‰u¥Rƒ3Êm£ÙDˆsúmª
)Vù¼"NÃ×=Ô«¢Æ­D&®:1ï·oÂI`ĞõŠĞ<jŠsE©»£/áQ6k -cİDF)?ŞË’µ´!…òuk)³`øk@KÇ/°¤*áÕ7ÎfP×’dYzÿ¹±2ˆ
»Œ©3ıÜÜ8îÕ‹?]RÛ ËhQORS{{BŞ¯¾â >tˆÇ~áCœĞ‹?Eçë Š&›Ãúı%½	!  »E÷{6#ƒË$}©Ï\›-¢^Ô¥ëÈL‰;ìD;7’îıw¹êßFz‰Ì‘ êaÔªü3Ş¶‰P/ $¥Ï¹	xe=™„Ã^©¸‹fÕ‚ğÖ`Âî`m#’Ó!íLE²Ç¨Eq"nô’Á×ÍYGØ«—zÍ|Fæíµqe‰|GJŒ&³ék¾~ÚVÆ›;ûDØ“1ÌpÃ]×Æ¿ëkX
N*4eÖ©EåœÎ¡ºª C¶j„O+}¬t JÆ0RïæÖ¿µâ%c@5´É„¨â‡µÒM*L‚.¦´ë†ÿa]±ş§i™¥“ñ*¦O=ÎŒ£Ûeé‚şØXGñÛ><2}e‘ùhJ·.e®vô>Â¬|‘ˆ ¨Ìöà'äÌ¤oİ¾µâüÕ»ø}Ú`ŒèñÙæp­\Öøß§ñ¬ô0O*ØişÏòIwçòŸvŞµ»"¤(›c£bóáÄÉY–²Mÿ¤Ë¾µá«>~,Ñ†é¦œ…UyØ—7Ùa„]/A^³~æo±@“-Àìô|ƒÇéT*:"(A ¹O„R Æm ZØİiÔ^çÕ¬"Ğ2ß¥œ@ãI‚ír]­öQÎ‹.Tÿ\ZK¯-p¤¯V.uÑá3Ô­ŞÍ¬—Æí±’åm/‹ïíà®ıÈy½_°€šÈk¡¯„›Ã^±d^cÏìd?F¼šûÈ.;[Ï­ú…¶ĞÁ?åídwOÂ§s0onm?¬Zë»“Øü©IRG[WŸV}j{]±+s§_“Lşú5ëßC¥Õ£ãÜ¥U6æ³¬ôú´Åœ—…ì|Î‘zf‡Œ(×ChO<2O9ñ±X½$÷¼y{ÔáMszäMéî›ñ™Å–SÜ‚|Â,h4XQå«¼ ,ú
f±ªB.œæÃºğŠ¬Ô.aå÷)ìÓ“¼}@Ç?^¹M…j½¥¶CXX…ìĞTsõ5¥ş"ßËEI%Šk•Õì0 Ç5‘Ø°û—‚-4·_g¯øc^å¬	Š÷;EHùöAŒ§8“f`ÎÊKÔsç ¹~–´†äŠ÷T2F]2í‰Ï2â	úÇùİÀ÷aÎÍc¬ÆGkä*ÍwUt+YíÔ?“Ÿm4‹L½â%Éwµê‡7óNÁ¿×ñç¬M¨Ò	ƒ1¥OÆ½Vsˆ«#e¦ÉV
õÇ¬0UæòŞzpÿ\Ø˜¯d[KëKû®•Æ©Æ¿>DH=úX<é$}t¹v(œÌĞÒÒZ\*‰‰Agï‚ÔE*`ÌÔq³Í‹çİAées”¤
æ­ ñEØÂ¯€Oı•*»õmñÜÆÍË¸1­iüƒa4{Ó!Hê~Ìÿpµ¼ï<“±Kjı¶Š·âlÿNc ïÁ#á¨êCÎ‚ûSÏÓjWé’K2WıVÂµcªòT¼3™Õ	'œê½ÌG’C
r?ñ·x+B±ŒÚg¤ÜZ‘VB™~Æ½rò¢9ˆg`ïMW9Ûâu×h~İ¨ïîrƒ‰×c:Ï¦-,·2y;A·²ï/7IŸÃ|qÒâ…[Öƒ.$£ G×ßyïVƒıBé“U’wO¸÷0Q…À˜ËáO(FÉ„,Ë§91¾¹õh°kü¹^3x,v¨zÅÍù¶ĞÕÍSZÏŸœy?¸Õ?¨1¿Á£Í÷Å¶yáîêf)!KìÚw`İtZƒÄÓßÍHø# élx?'‚¨]Zú[Wh¥!Üı<ÅùVkŒ½TºÍÔ~¨¢ødKÔ·ü>w^÷°ˆ˜Ÿ~k²p„†ôN¶*²(Y^ğ–ÌŒ}s™zEî:¯{Xãï@ı?¥ b;¨s2ÈÚ”V˜ô,Ü ÀŒQP$±£m©­EräŒ¡l%1>ıyX öÚ¶ëÖQ£\ÆÒLÚnï&Æ!¤¯„zñ
n-+@Ãvk}(š*2½çÏJ.¼Ñ¥sƒLgrßŞç0‹îÛ¹ßùø¢ÿÎíFÉ·5®Ğ^ÖKò%.•_ÏZk¥î1²q×­}†ã„;İ¢naC­ö\Æœ—zÓ+”‘àÏ‘‘ Ü=Éjì.ä  üÇŒÌB¼ÔlÖr½qša¨şĞ¹DĞ7Xã'Ä^MõƒC:ÜŒ)__J,2Çé‹.ˆvf!Q`=nZ”gsæ-Ï3UôV¼­¦¬¥´š²ËBÇh=ñi]*µ`Æ<…Ñê-Tæöş¢‚<CÒ27¶İ"ò4ÜÍ i˜vGÔÕ1`Ÿ?Ì,›%à'¯Ö¿ix/ã¬-ğÏ¬ä¤Ğ÷7zfxMÿÓZõu8XÎÍ‰7:ä8Góİ	Äµ®\¢Wlœ˜4§ÍN!¦8È*ÜĞíƒ7švb´jã@‡û|@’aª$~‡¥9e_Ì¥8¬¸³Ú¸[ş†a¯oİŸĞÎ¼fèW|Õì\g+‡KU-^¼Õ$íª›Ş pÚõsés€ÆË¢2H‰ŠÔ‰ûÎ;tÉÊ»S•y—}âOgíàı×SòX+Ç¦QN“4Öx"S\üĞ½—Š6ˆ#HÙ4GÌ“ØŠõ0¨aK£úp4ƒ ã”FÕêLË‘¾ı/ÎÆ•H}“dmÕY(ãwÑU–&ŸìŠÃĞÓï>»˜°€•YDRàC½úµd.Ù<şŠM)[5B£„İ3°,…Ú¡…¸@Ufi*¡XÙgN¯À× É¸# ÁÌ"”vKï¿bÂ_,1Åó«^Æi¼s“¿JÑiú›\1˜¼.0…äÎ;¼À¬ÒGkD¬p*NÖ‚`‹GQŞîÍÓI9¶mÎá‚T|À&‰#i…²äe¡„0@?Z\ókÓ*³âqqH$jö.ùŠ<»ÓÑtg@h@®Ù¶E'©ü_h.5½ÄñyË±#şÜéÁ<X3öİË˜Å¤=aÃ…ÜƒWTÄøã¼õn:HÅUQüi®1«ÉéŞêf>=®ømé·ğõá¨›h22óy”<qÀB'nóéC1#A„ÛœâèP”™§7G­2óYÇºÃÕÄËİ:¿ Æ±£ñBä¯gºQ¶-Ú™İ@ì%%tL¼öËv1P”!˜%¢ÕœP‡[Ü34ï±!uvìäŠ¶-Îv0¯‚\ò‚]òJkÎSª=ªh²·*ÏäNø;÷J^ºØÏ¤ Çù2lÇú«²£74ÓA—T‚¨RÍŒVI9´ãä©Y¸83ºVAT4	‰ŒÊàÀÊòÇ)÷›_î-<ÍZò"øâM÷HCwÉÑ±½õ}.¶àoµ±öâÔÈK<Ù$@K·‘Œí#‚ÄBÌ%z°Uİ3&Di VÆãâ%ÂÓÑ¼AŠ	œ‚''k§Ñ'[Ü+óUŸà:ÏFù¨ŸòzQ6ÜòÇ««œ\?A²¶${8Õ·¨Ú4=6êSì+…ş)Q¡¸k²µ4e(Êğ©bó¢:O!?y fÛîëúé×·8N%A˜
˜Üºıë«İH[Š^:[šP$…òóªqE
0N İçbË—Q#Kò¹j$Øè–x›îïÏÄ$ıª÷ÀÇ^û—GêÊlÀùçy‰Ìlóu!y·Å¹NC(4„3UƒFiqCüÖŠ×mÒ´#["§0+˜Ü%EÕ¸¯¡'$>hşÒ#a.O8D‰'9¹H@	Xßz·»ÍT0+4LZ&>ü~'^tNI9XùKøÎÇU¦‡ILöŸóbĞS‚õ¿s~•§…ÓGc³µ)"ê|”ß|†~Ò´c÷áĞ•bõy¿äí”YPË*;¨hyqWi3ÂM{P~fUõÕ‡rSAÿ {¸=«6³a‹‡oS)iËù
‡£˜ËøPø	y”@5B>Úê·ñO:±ÿ}·¯â´yó=Y*ı+-=$•2ö7ûN¯Im«(·[á‡GñèÚå°bëºÂ’“Àp$ôá«Só_Õv•ÉZ %‡bôğq¸¢¸¸j'J)6íf@ÏDĞDı°1‰Â3´´Æ‰‡â»V>)|øY·ßêaò%P³V³4.¯ÿniÂ¥÷‚œ/Ñ!@Óï4ôöuŸ€:º,İ¡®.Ñ+û”ª’×¢Ì+Şê\6ü·Ëš^ùpzÆL×fâ!]'´ÿ« ~ğíNyÍ
Ö/&Ş€R\C©CEúÑšÈB•d­îq’(âƒ©‰=4:gq5àûÇ¶ï>+p"Ú)Êöe¯’ÆëSq¼)›üø\6rq‹À½:"u¼¨V1L@Ã%^F³~@~˜­I65bzm¾8H°¬#3Gz`’ó°Q®w1Ş«}Â‰Æ˜Zû`Ïç“†S‘L*Õ{wèòÇ/Ö×ÊL¹Ñu’÷Û<¥y;Ï„éëŸ™ş­Ò¬¥¤ÕAë­,Tôê*< m®ĞUØ£¤Í¡_·r¾®À¤€™9G·®èhçY 3¼E T¢Ï_>í`õYæĞ Œ¡œ aÀ?=È†”úå.è« 1( FÌœı%c·òê£Âcö×ælû·zèB|&ˆ[¡e¶z§ ·d±‘€VŒö«3ÕÀ£P¾ƒ‡HS¢¼Û>/{œ|î´`¶Ö<ä'–Ü‹4Ñâé3×î|ïº­Ù”ß£V†01®Ğ¿.×Ï¾/tzıù ¹Oô¼rÏ~§Z;ê@’g6¡ïM‹¢ñdÏÔ¯bÚ; 'èŞ„¯]Ñˆ$£@Hæƒ|6ì)á ëÙŒCnÇYüµ&ÙhÈPğÎ¹?UÃaİ³(¾/’Æ!l
¾ÅùëNÌ‚à¥G‰cê”øo0¶%©I­u¯L£¶$Î¶ï˜‹İ<Ÿ;¦Ó†KöÜæNÏcì|ÃF¾1÷ümx1p¶U‹š:áÀ.È?Snù^@Täª\„lt¾ƒ÷ÀjB•ïŸ5‘uûò£^úcĞÍ~c·„7emI„¼3œdéô{.e\yP\œùÿDÇ*Û¸C$¨MùIÃO<>¨çj²•Z    -Y`+õ-@ Ê€Â/Yb±Ägû    YZ