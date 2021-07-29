#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3869161366"
MD5="1ab163e61673f21e8b73fb50d7ddf8bf"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22484"
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
	echo Date of packaging: Thu Jul 29 14:07:22 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿW’] ¼}•À1Dd]‡Á›PætİD÷¹ÿEä¤ãq¸]vˆ2/*”÷óŞâÏ¥øİ‘g%G«GlŞæºØËÔ¿…'8ùÉ½ü2³š#WiwÒ8á$x7ßÔh¾Hóíp@-_ Ø©Ç¾ÔX´A-pÉÏ­ó\İcÈ=½ã»_u+
yærXWb¹ü¼Œ¸¾ñ‡I†ß	¬•t]Kıü/mr×PO<(*nã£ò%ùEk–/g&”†8™D'e|ÈzF‚u·À*]\Ë~K«Æ„à¨|E7Jan’¾ôzWJ•úQ/ÇÙÊ¶hÎS€»½M¶Ö$,2isº·|àø?l×SyÅW'Ö¥ÉÛÙ¡ÇNB=£Ù7¶"3;¬üå‰&+X5‹{×¿Pá{/ĞíŸ™¹=öIàm€†…î§½…](Z§ÓrÄ+óTCšV4 7™ªìı¿äˆ¡0iGÄ3ÍïGß¨¤Ã]§
ëµûµ¥S³ññ7Õ1e¦GÖY¶‹ø<q Ã¦¦¼Œ[ÙÏ3t¸IUá3Ÿç;ã=”P¶ãDÂ##	ä‘Ã+ŞÂˆâİ,gzõšî€*ã Ú£IŞŠBÇX2]^µŒè†ï¼fƒ[î&‘ÉX‰y~pg,DQ){¸>IÊ¸’X:w‰Å)ªÁ´üHÎÒU*ìÇ|1ŞJƒA8ßÍÇĞŸ-Vb(˜>£.¨âó)¿#>×—wÄÖ“Rß§c(¥ÃøªXÉsHÿò%!ĞÄ¨úeÔ½Õ£}ï‹mÉv1{éã¬jÕ‘d}pÕæşâiÄtä¿\QªÇKSÉ¼yÔ¸=¼æàp8Ö	ÅõúØ5­ÄlŒ3ßğÜ¶ë4@aS¾|í?,B‘aX$lØFm+Ğíuõ…„ô‹\OHc*î°¶–µÚOî®ÛÀn)¯âC…vMj‚|>ÍF‹š0€“|ÿnÇÎL‚ó\˜¾`Ñå1QËfoCÒJûÙôïÏ KQMY$ï:q¼y•P?MÑKŒÚÆc]Ã|ºÙq9ğ‚'ÿe5gOX¹R+*‚ªÇ¯LôCHøW¤Ä1Lÿ&Ã8ÈõVjıüŞš²Îïì³|-õ:öDq›O©’òYzË"zBÁøoT;Üv§Ü)f›ÃhÔÓÄÜñ†Æ¢İ}Q;Ãå9N-ÕÌUTP‹AŒœh	æ¨°ó>*æ·ñ_Äyµ\b'ñ­ÏúNkÆcT6‘°§G°d7,P<Ÿ¯I5Õ¡1„µá#ÑW¥v¹,k:Œ˜²„®|Œ¯Ş'…µÀÂ¥NšÓiGªîk¼°uiCYrdœÔX»ŠgN›B¥¡1ıdœõ…&¤tóãÏVf}t"îpî—šyã‰´ÖÄwå~[ºãlÈæ´¢Q¤5±µsFm§ÓG}EM%¸h¿"™–¯Ò––(°,Ó2¾J›8w÷ü(cù5µayn¢M§kÉJ¼ßgÒB•ŠW{1‚UÌ,
Ëçv¹y˜ÅÏ@úÊ÷µ„æ×yµ¾@Ê®÷›p%Ô5«–‘} ‡¹	ÚNbês/˜¸ÿ±&€#ê‡RˆîÿJ*uÙ>:Ú)¶±L¶ru
¼ı¥Ôâía®Êÿ‰sšŸ…
ÃêO«
Y™‡zÉáá«q¥Xb‡£	è‘ğÇ%e‰ã24Ïµb4Ex¼Z¦Ahš!{€ˆØzR¨xô”GÉe:\P N#Ş,¸döènG×‰†wÍÇB¨/“a½É>% '„j¬¬ğƒ/Âáğ÷®ŒƒĞ*r8sbïx¢ç9öú7Ìn™¬_ö}ÜuG‡:N«Æ%.˜[¡‡Ô7g†ô6¯ÚÑ+åÙdˆa5¾•'Wj’`¹*”0Îh>òtH&Ñ·fË‘d.ØrK¾¤€M¢ÎŞ£Oìÿ­dÚ$İ¿™¹ ¹¿Péàõ.fEa)‘ê“: øß¹Z°^W]eÑí"YE}Í¼Ô]ÿíh­ıÂ£ÄÌbØïZa.@o]óZDmøÙBæzËªeNŸÚ‡f¯wãö¶ÙV_¶ä‹,¥“––·G	]aĞğ×È<‡3ün”¿”£“=Û!X§ÕËvYì3Pi‰|l“ÆîB×˜>#9AˆéÒR„¥s~í³“ñİìE,1g–YË´Áï/#»4¹ægTá¢11Æa MT¹bÙAk*Q»-©Í7m!>"¸iª÷Û4ši­Õ“Ê€á½N ¡·K%c=‹J\1;bÜ¿­2AÏÏÅP–İ@Şµ£üÄ¬¸ÅSŠI¡x©Ãa{†ø6ñÿVê“uÚË¤<$W‘RYì<¸ÚÙ÷ñ‘6ï©'¥wÈümÀ	©À&$ç°÷P¹ ’ŸË¶Iiz~#ç ‚7sE'’ãB	¹K¸LJÓâ‡û?=%d)ÉšhÓ"Øú¦e»s ³û*ãíÇ~Ç×òpİÂ®'ÍĞY ¬ìPp§ü"eªçxéÁõ¡´:„,<ÆåD ï½Ëÿc¡½hÁí­kT¡.Î]µ3û=ÇùA¹Óq¹¨™)ùøâß‚8Kw‚/Û™êI„¹¡·j ?WKºZYµ›×ç„ş®:¿—tQ%¡bõã¼ù2çÆÒ|‚îF:ñ¯ÔÛ™x©X]IãXcl×Ç¨³Å§ü$òß·àŒ·•Í¸U‹ğ¾	¤KmAB\á’l,|ˆCë²QP.—WĞ7õ…ç"õÓ±$ÿ«zœòg›†‘ş9³bH<Ã)GŸÒÙ9JO ‘š(Eu¹ÜfÌVZËÅÈÉ	„æ¸3qAT½™JÒ¹g§‹¢µe°6h:ßÛ¡ŞÀ²»ÜG" z«`%àQ£^ß;m:ô jˆ
ÜJ+#H€Ì<ğ]o$°ƒıÍQíV{½À `í]7'¾‘Ê,P+eí¨ƒ–BKy
µúO†JìZ¦ÿ–å‡´µ¾qïúOÉ1%ïüÙÕ<…Ó®wÚ\ØWÈâ×Ş‚ã]cQV%·ü¾ÏYÄÎÕJïã–€D¸ÎÍ›‚JéGÕ@]&¸!Àİ"›Œº†Û9ÂÇİ 5Ì®ÖI£v›ïŸa$sŠ\Zs(pØÚZ´ßò—Ø1yÉ¹™•c+tdô±(İ~<W5åûå³™Yª¼ã»2€ßà0êš;î­¾Màé{bÂ³Î§®½É<aß‰”=-¥›< Â…EÕÎ1Lvë'‹Åï6‚*ƒ_ÜHúZódé±J´ÑWÔ“Ä°ëÁ¡¾hÊŒiÂeœgø&E«5ù?İ~–“V×ˆZB#g¾ÈÄ¨ê Ñ ¾	@$¾Ğ ¼ªíÒåwÓã´Íµ'Ã‹n=4ŞUáAQc³;­–ô€Ó?DŸ¯n€øÓ×Ørå9§mLTe`Ì‰¹cxKÛaÂpBÂLÎ…`EÌÄ ïQtCb¶¦\¹W·Ç5ª3õãÃ»Ï=ÍÏ»_ÈèÌ·Évá/®2~["5¼óYúXhxËë†‡:“#¹Gz^µúÓÂ"ùŠúsvßÔ¦ÑôıZé\BF˜JÔ_,TÅMæëòCŠv\…\o¯ğd\S]›|æUVíıì_Ñ(s®—Q3oáA‚aµÓwVì*É˜0•wÏÉ3ùş?_Ú›ˆ€,¹Õ	« ¹)â¯KK1º¦¸_£Èú¹f,Å_Àøî7Å×²œK Eÿ½ëıô¾İQ¥Ø»2’öÁVGö¨ò§ípkşŞş›PÀyÖRÁ[×­Z§ğ:zX­¸Ä]h1®ö?Åa}¯n:i	ïÈÿ(ä6.w˜ÖÀ¤]k†ö~jŠ†Ã=×'ª8o²DR£‡äùoäç1N(lö_´Šèp<öİtvXÑ.÷X—­:dU.¤¬_VsqCô¿ŸÁ½Ÿt£¯Ã”/ÈbLÎenVf›¾åµZv?Å\Ÿ$úìe\w'.—„kW?<¢J1O›Œ+„½ZmÌ°—i
¤0¶8%.B¬Vù3†+XÈjÑÈÒM‚tã;@;Ø×jáõIÄ‚&¦M¾˜7«ZĞ<¯/×Â2Â×Jßd*·ù6ŞYâì° M«8hŞ§0æ”“ŸkØª6Xı´Âa44.QáHú´”–²  íÀ¼zÉº‚«ˆ‘D“ —ùÑ~Q<i-Ÿ„Z–ú6[o~>³s!Î×Õ©<æŠà¡‹P4à-ÇZ?ıæĞ“F¤U%‹qFMLÉÀŒ˜¿lG$ÎFd$ƒò£Ì¦´”B÷uˆ%„Z™«¼·t)45¾¶é/>Øğ}ıNjF‰}Œ2òJ2«uX2äuQILĞb9\|Á*åCú¾êTÎuÈÁÕ‹¦³Aé2FÃ:/{‡$·tÀ¾*à;öQ&~±³ùü]æê)ìhƒóMŒş3Àü0+ĞM¦´3ÖpÖÍ¦™IÄ'·Äõgo¦=†š™ë~ªKJ;¼Âd¸šÿ2ßCE8AJc¤#*È‚y[è}l†/_LŸ±`Ô#²Ód,O>w©ÿ5z¦·	ã “Ë¶h©@ê³
 ãŸ#µ0n2õß^},yQÿû(bs8³¸7Œ¾á U¤z§b˜UÂ¼­÷ƒ{è«{¼R3Lù¥ÚÁÁ±S—eÆHC\¯Üwú¿§m¸7¬™i­HDÉËI§ô‹p|8Ü>¸öğ°^eYJĞ´6äï4©y0Ù¥æÚÒÁSšË¨Ôz“à]h$@ÖŸG¬|˜!ú¾‚p	VÓQÄüŸ8«uÑ	ZÔAÃ-†ˆşvCÈ ­ßöG®¹Éğ#t¼+äÇIáİçc»HMC«³{=og ujZ¯¶Ù­Àƒİ2h‹¦d¤/B#ëséˆPŞ'Ù­¡Şóıš¨m ¼Á„ÒÆîexê®œÔ3r€L¼Îx¢zÈĞØº0•©rG=Æ™Üñ’ßø…kG–üçù7+LQ&m†ZE_¦ËĞB›`uNûG¨¥^ñıúÒOC‰vAXÍ:çøõÁØ
3·®
¾1MT}ËŞ|¾xZ3^‚Út¿Ä‚¦˜Z¾š—íë¬ƒóÃ-fåoõ)Ö²™Û{¦—D”èâÖB(«ÒUœj˜¬]+ù†QgzÄZ§æR‘T¿ÌKòğç ®Éü!D‘	Ñ¦CÒ:"Á/Ü]×“’o}X¼²LçéP5Ï¸>¥r©×"˜¾îß\ıx¡/öŒ–T+I·Ğ8 R#x«|ˆD¢&lw0Óãxtr÷s{Üh6âÄÂw2Dü9.Ã½[=àlËÊŸòDÒÆu}KÙí@¦î á&IKÂ[üPÊ8ÒÛë8V½œ{âè»!e28N.ª%ÌòBUŠmºDt\cZDÉb ‚ú§Q¬wLßZÓ›9Ÿ"ì6j¡A6ï%îß6¨DÖğˆÜÃà·t ¼Şò>U¢=¿,ñ{ù»L—•p%ë¡ySèAÍU@àîªûo/Ğ0ğh-Ÿásß:AqWÙÈ1v5«®0“({cïıë,MÆFk uˆß¿|Là„ıU)6üåõ Ê…ZçwİwäQÃZÉË5Ù@Õ³¬˜\í2Ú[&Ër+|W×Õ­[Iw»¾—‘Ôh"b(SIEôğÒ¹%xº€$it¼÷ì,üæ“ßa«›4ŞìëŠmºÇ-ää~’gø˜ßŠÌ{/õ¹gÒä¥ô˜šŒ¿cúe:ÒÂ}ùé©bO©æµÁvø^Ç_¹ìµu°±˜š›ô:–24Ì ©`j³pÙ^[ëäk3ĞØ£×&<€P„Ï/´Ãjy×şïõéëÈ{eâ ŒŞÊ‚LŒq¦]œş# ;v»I3IàQ}¤¡ıŸlEô™$Ë[0™ï6ÛW–j€	ù…ÆçÛ8»ëm“ÏA™á¹š¹’ïê+ÀÚ›€ò¸Tƒw»5IŞíÑXÔVÓTg)€>®àj(¾A=NIÓË„à|Z%Ÿ¥’.,êK¶ ªnĞøçô¬VsX™Ô”Ót;ä$PòMÖáaÚIİõqš’¢¿»çŒã¦? •h¯–ô0àìíVÍBFJ‹‹Á†’ ÖÑş¢“ÎÅ¯®x ôymï„b$*[’« òfƒíµ1aÀá¯)
ö©ö[¬h¬€ª22ä \:L3İÍºÄ½ˆÊÓ·ß·\f}§*ÃW..FÿŸİ- á/…5ŠeÜ1x÷cHÚ;T8ƒ:¶3Ñ4Ÿê4¨ú`˜ø(gI-^|pØ hA’˜×š‚í¼p¾êÌš2É’„Vm0è2µUÿB¬³Ë äà9Ã³Kû—ë"#L:òZüª	ˆ¶Xóg”†¼¿7¥BßE¥„Œçq‡Š0¦æµ2÷—û7Ö2óù@¦`Œ°¥_ñ_¤Çe¯ 'ÑÿƒHaàÛŞÅ{Ûÿ1°‰– óóNÍİ!æÙ¸şË3#?I¾Ä^•O¶ûôMŠ{Ë`Øï<†E§a¾~¾2Ì§S9_gÒS±Ã­Ò³!.¹¹½ó3#E;ò®€µj›ë	İáG{Í¨?ø(¾ßÌ‘Yw¥&"B¬°‰îÎÛŒÛ¼ó¡ÌÜpá_ø¾Z‘±ÒÒtñr)·'P‡y†æXS¼dÄÜª÷ñE£iBèò–Şœ‘I¾ÇTÿ®´œëqÅe³îd^psyÄ“ì*'”Q«Dös‰IØfBõÎÂ7#§‰e›=¾Á eâ
€»GùX&jÇ˜açW–èH>Íü_ÄÅXlXMƒUŸ¹•oĞõÊJmÇºÖÙÓf‰zhw<ÑÎ)á%íúPMá­½ÿ`Çå$¸@›HÎ(á@‘¼·Š7EÔì¹pìƒ°QÂØôã¿’-^üc~‹EñÏÑr-›gL´w_‘ë¦¡iµ›Ç.Û•Å'zí|ÍÊÓ°Â*|«¼ªMq^ä£À<İçIÚ­øï !mTê${†5ßß“S "¥4Š“»Åó…lîù`½OmğÙpwA?‘zÌ¬éo¿ØÔÆbÜmô¥÷Á\ùèË2‘%3oçI-ÿ5í·=dÍÀ‡hŠ1‡©÷9öˆÁfc¨26ëãêÈYõµ¬Ş‰Ëçö©ZwllÑqÚRïøåëûÅR;^TçÆ#h6ƒ›KíµjJÅtƒPH%7”ÌbYÙü¸áš/³¢›ıOÎ]€7“œ¿Êñ\ÆÊ3ª8ŒıáÊ…xU:èœ^¯xtÙTŠqäñsºLÙ½7©C´=VÄQX?Á İãléÃU)SJÚ\¨ o3À3B/QÂ¶šİø×a’ıgn&z‹ºš¢ImÛêÍ‡²xŒôsËomqèªøÃeø‘Ä$šÿáÄT´Wl(t×úP¨ ¨åkÖ'
nxîÈ8(ùRå Îå``Û&Gº‹Á•V+óÄò°O\˜‡hB¤¨7íÔDË“Gs8ù9X9ê)á{´;ÆÖõ§ÆæİCşD/}œÔğ!G"™½ÖÏºuX÷†5/Ñ ~%XEÂ~÷ÎN;‰ÄR	ñÜe»vT‹[ ÚS¥›¸pĞ3õMdÕo-~]éìmn4zœÜF¬t7±sötbNL(4&@Ù©‡¾#müñ‘RD
ağÄ€¨+äéÃã!Öx£Éé=6Î7Ù­+½êÅ]D±¢k|7¤UlïT…šzf;â'`|ã9åcc¿-šW)c:„¶Šyã(íŒÍsÖ`£ÜÛQ­âØ(Zb=ORcİÀIÿh]YêÙF1àï+?DŒ9ÙËiC,Áêå /µÖ«A¿æ‡¨G ŸÃ26m©&UÕ°
ÉİûVıÇhx"¬I(ˆ!|„¹uÛÜ!ªm
œæ”JnµÛqğ€H(mŒ‡‚uYkŸ’Ğ[£Óï&ã	p”Ñ¤’•façPÜYÂ`š»ä¨ (NHcÙU£“28N3{ô½2+«Oİ›ŞB¿S˜íâ¾”Û¨¹0›i1œà|‡Bnz€EOªŒKÆqßÄ‹á(ŒZ÷¤øn¯Z…B¿e¹¸”Ó?ä%ØÏ©–òıcû†Û/ºëmšˆöÉoß1òÇyyô:ã)Âè9êƒ4êè|nı2—GH .şX¢É1ö;	1e~ªŞìg„“]ÿØM«RÙ›'qÎÀ{Èô¹  z"66 oF†Ô›HÛ;28u|ÎÅÒÕ_‰TìàNßİ˜²r È~`Ï²j7yÌoØ§Ã—•“;yvü³^#ë‡{›üÍ-˜—Íç·îCÄôÒ ±š·”Ò;P¹vSõÉQŠfå»¤úÉÏ_FÎŸ€¥@ÎøK<ºÆ…/İÌ‹îctqÂFßl¨ßĞ:ä•“joåtSlÇ¢º% †Ëƒ k	P^<ô¦—Eû)=>b3 Ië%x{V	H–ì†{$}]êñ—êÊÑ©†tawJ¹¥6Hà
RàÚ?ŞX¼ğÓ¹,u‡)VÛšæ$øÑQ4Ñûë!yU'_š±JÔSÉDùûWs<8wfÆU*j_kf1–ÊĞÎ¢Ï`Üd“‚ŞË|œ—ûÜ™R3÷Ö[ÂÖtHĞ\¼ÈÍ?¯¢*‹C„´ñ¦^Ğˆ¤
‰œÉÁ`l›Óª–Z'“s>qÿ•›	å]!(øÑĞBÒ¨­Uˆ"–Â/øõ| Û¸&_Û
ŸêL““GŸ[‰)Gfñş!Æ³TµŒè0Vßñƒ¾Ì¼&ßg–s\èÿıºz~ÉLeƒÉDCÍû]nÜOáÀÂñ[ºì>ıÁŠÎú ØàNôCÿ´$«y"^ƒÙ“Ñ¬Éş˜ôÿ+ûÇ+µ6µÀV'ézğûÏğG›Şº™b{¦t±‰"_eµ©ÙÌ¡´2A?“®Ú»]sõ½oáëŠüÚ8õøÕˆ*e™@¸„Öj*Ài}]^µ²qo_‘Ól ÑCù¦]°—Àii£l	~ç†[æÚæ]Ç&h	a¤©”şOd¢ZÇwÀ‘ù	Ë¢9nÖÈ¯#K!H9µ* {‹¾nö«’@§>mj¯ò„°^¬)4 ÕxUĞÂ §Ñ8iwö¾‹/œ0ù"¢3Çb‰¤Z´ˆc9¢Q‡¸H1ƒÂ_	øÇñcm8†­m*L—D•_ámqÌ™Õ¸f”ÇûÙãµW˜«T¼§éËÂJbĞ ‘­EkNç&csõ2‡·qÚ¸+qwÖ™ÊÀÊ9XH
ëQZ*~»ÌÀ+p¬Bğ4åÍ”ÆMBpJÙáSÙç6ûRtS€
o…Mè>xtÉ	ŒûÆğ¼!	(çgwâÌJ+,úçbâV™3†=©ĞA¿©ó]úĞİL]®Ññ©ÆW“oåÅ–©'ªæG Š°© ¦Áş¦-à^ÃEôñ}06@:ÂyŞ°dó¥õt±-ÊDûQÊÁœ:gÇ¶Ú¬_GY¹BLŒ±ñ™•IÏ&?Ït¥Ã=“ËˆÃ@9‘:
ålİe®ÙÔEšú3VøôÆ,ğóÃÃXÆ­`¦V”«ê±=¥-ÎËošµƒ°¦¬ıbÑ†Qµ‡‡ªøÛÒÍ#kS:!(¯8Á;Ô6´T?²Y<s8I+X× ´ps‘ï¥Ù§9eåØqPÿ€Ó§tJ:†ŞŒÇ›ÔíZâ›€&0İÿÜçÀ-í‹òğàOäpçìÚy.¶@ìßOì9©ÎP ‡£\¦µ÷ˆşâ†dö_“¥ °}ä¤?Xè¯§[kQ»õ«“mÑœÁş—_Ôºnşç‘J6:Ç‹Ö¿ËÒ«Ë«XOŠ6òÿyJôÏÑñ}ûuâ¤º\	îÄ1{v7””ZŸ`§ÂwaTo!ŸCŠ!{dG;æ„U˜¥)£0R ÖY2ó$2§O­K{Gm´VÈdİ@86L¹ÈÎk.rh¤ñØ	Ïm)çÕJèê³¯¥ñ:Q•!·#•Œı[ÃÚ~]Ú²êäÌ!Ê<Dª„ŠƒB%½._+i¸°xíÉRŠ¶÷Xf¡‚ˆtâS†™7'É[g@Âº,º!oñ$:N-_mJßAİ¶GŸİC‚Ô—¼oâñ <½Üê,†&±ş!Ùû)®—Ñ?«Ów4—*AîàÛ=@ÛÜ{uj#_º!xşß­o\âÀ€5š
àšÇÃ!Œ¥œ=4s°×vsÇ×¸h;äé€ä‡çzá£º¢9L|B“5JAW{¡År {;€t¤¨¤
B*!%õ$ı;O5àkÒ_½”ÎmHJÜ=©¼î ÉÑ1ò\k°˜a®Ñwdï\UÿuŸEw<^·ŞÅMá€â•ö<èÛ¤öÏâÕë%jgôTRıÎ²¯^hÅÉğBÖº¡´\«
œ\Ì‚6²—q ¤ŞT·Üp_êà/å¸’<.Äû>±Á¾VÆÃºGu¦¶W¯nÁUÈqP„ÑOBêê
SÚ›*d^¸’eÎS…À{Xö£!Åá¿'Hzx%€ÀÔ`EŠäŠ„{“’¢¬y‹*4“dƒéM_íò}X;’Fôl·Ô÷,urI—‘A“¬ôç*ò»{p1™ìÔÇ¬ñ$AP´§)¾]úÁÓb[š»±qUUˆ6„6d'Ü—,W%Çê,ëFf‹„tÂÌI!r¨éP’P"ò'õ&¥ÑA—hÜ7È¾T(İçÜ¯û¢|¤@Bº²?DñE@.³æót›ïd 3Y¾?æÿzI€™1~j*SF,VîD>O«ÆYHË¬§Ho˜›¬Ğ˜U¾ûeÿáT×Ql0Ğø@ü¼‹vëv× ˜\™ Û¸}v÷XŞœ£|$_µ7B…›'Š†KÕpãü;[ÖîÁdP&*ö‡{h‰³ôz”)ÇÕêÇßğ¦¨Â¿åo"T0@Ê²î"ıçõ'Má±FÜjYÃu°ng/´4¸X8Ó”» 5PE™ª„î
ïN¨S£)uXİíõDxõá)ÆH‡µ°©Z¿uE&õ‹MœÉ›sÂ;ø¿C];9i=#Çˆâñ¦àÅ‘ğı\øÈHñLã]lé#µDß½õ¥›¿?‚\RK\jR¡/FàÃˆ^F€ˆ8­Ùi²-z¡£™¢şĞï&Æ)Å3|DÖç¼Îâé«ÿSµB¼‚7g ÉJ>2‚tç¶.œ û+ÎŠ›Îµ\@†ÓÆÛ?Z"oÕ~©h5ÜìÎîàOø:şÆó#»‹FŸ©Xo;.ä8 qD­M¦„´ˆéó¶Ûmá ¾@MÖÚ8piêwèàb€Ï­¢h3¡3¬LÍÍÍª€Êè	£ñïÍ:Òóïİİ3nÍwÀ@k©D¶~§J‘¨"¶)l½3ğòv°şgzØpx–ñ5‡\2WşÂ¦ïP=ìç@5/Àgèö–O0-g1;pí¶`WC¨^<å;iÉ–0Õ´^ˆ¤tŞ!ş‰…œUŠ‰¢{ô€T¦¢ÓÏÊâ!¥‹-«;›ˆšûÆUO¹Uõ¨î2ÚŸ¯¬¬¥ğœƒ¾èŒ»MvZÄn†ö°y!“n†Ÿ¿Œêå¨eG‹/à©Á×]¹á(ÛS~ôlŞ5	mº¦5Ô½çNN^»Ô2–-Ôà;ŒøçÙõ+˜ØĞÍQØÔ™Æ‡é¹½R]kÑ™µâ“„NSÃã"tå™²±âÆ³Ğo×s:&ëd<f	7›qK‡±&£tlW`ºƒf•Ã—¿ª/<Ö=5IXu"ÅÜ¾ìÇDÀ¹ùC¹cV¾á(BêV¡_»~<w ºaô í¡8ŞÉûÚ„0ËgùÆ—_×ìŠaŞ$ÔIšz“}æ	i¢¥‡Ô!lâwùö²³†§ìÓÍC,ŠjÅˆ×qd?µfFNçC2ˆaáÃÒÃ™şˆcR9­ŞØØÙÍ‹íè¶ªÑs¨zgµn‚T` +–öı¦0–öHÀÌUÃH¿îaİÊ%¦0S}Pşñq2k?aS _ÒyÍ‹µL4×RFC.ØcşyY¨™ş<uşEÆ¼¨=”¨]ç<U‰S¿ry;Ô6D“¢Ö3P0jE„oªŒ!ûRÂ ²âkÔ€ss²±âÊñu¯èù-õŞAYÒû¿¹WÏĞÆJ0ÿ=]4!àâ²†î6œ!ŞŠ.ÇñG­­YTˆsú¹ºÎ0¿BÿÖ½«úšu&WSZÚ˜¯:%ÚuRÜ°>é Äc`	8ıü0ğ¶™Û›¿#pì]ÜíÓ‚nø\F§†)‚Zûô³›˜ğ›7 =ùW=é{üQçV´%ı,=›ß;=%öÕ«rH¸YÿPGA;EÄ¨²ü?M¿z‹òÅAq2v+’Éï>ƒYrÍ¾sıO--»ß£&†o Zô~Ñwğ-d7¶ül¨9I#bÙ19	:b5„Û-mä3Q'Ø—Ié|°¡B™ãÂÓÔHí@ÅèDŠËh †¶M³Ix0{\|1Ö´2¹/fò”XÆ˜yÕá¥BÆ?`ï£³M÷ê —ÿíù6÷~ì}·ğwÔ/ºß§-õzg‰Î¬Q…>(Ÿ”xá Ù<Yd~¨®ôÀ™Ísº!|Òã_ò „Ö£ê->÷Ü%<Í‰=µşú‹ı™R8_:´Êª²wë“áa~w•ı>eT”Å`Ğƒá6Òüe¦æ±ıkg“i|˜‰ÕP?_¯¥`Õá¥ÆáSøÂTTÜÃ¦æõ kLD§˜]±nWÏ… ÇóZK6¥"U#³Ä	W±Ô±GFjçäÿu®'äµ”5eı®£`®ÔøÈB»B:µ­ÜŸvlêˆÖ>¸Ç¥„~)¯÷yÊ¸íÔ¼÷lzS‚ñ‚¶‰€M|EI¯Y™Zuf\]‡“[¢îyµ#ÉÑ/ş)Îf}œ#šş4[¨cÕjÎá¬@ó“ÄX$D%3`ÎøOĞk•¾Ñµ¸	˜$UÆ¾û–›o&%)	DQ±Ä…€\!KYA—9 zn°Ïÿ^ô/†rGã²ˆyŠ~A…ELóåº«ÃôL¬Q:Ç›³øš×‡ çKDO4‘‚Ó3qTÖ/ÎD75‘}³†§ß—˜ø…HŒŠµï2‡ÁMh@ÙGP¨)Àæ„àÅ4K›åöéç€•0³¹
BKóª_0È¹UX)\Ë6	ÃV¸uRÂÂnÆñ4€ÃKD}İ‚^'°;aòOAÆóVÄD&­ÇuÀå“hf&VP“4J™§ªÛ¯<úºmR@ãaP–ë1‰åMá[ÓR]*Bê¼Ä?+ù„8Gs±Ü´ín¾io8y¶´²2pà2T›(wÈ×/×˜ÕQ¯‚sƒXçUİ“<×Îeäv/†ÁL;ÈmLÖ‹Ã[ÅÈ»^0{¿=™Ô¶WGŠ%íí‰<<»h92¬èGƒ¾û½&`mî½ » Š&™´Ì¬4[(çÖÃ«ó†¨C¬›³õ·ÃÎğ-#•-tÑ1Óß£ú)XzµSnÇ¤–iGçhn“—©º?=O)[€yxÏ,c2Š?­ v#"cÏº¬ªï/½›Ê­¿ß’80æóQ»oŸÿŠ¨–ú´k´¸-ŸÄ	àgWå[Gß™ãÄ>TlxŸÓ( ¥ßç‚ëZyÛû¦ĞaN©’ı&”0]¥fIï?ó%Ï¹•<@ÈI¼ÎÌpæZ_šš‚«d¢¾Áƒ±°J9ês.ÙJZ¡äö"£ÖëëivÖ‹!fy4PØYÌ‹7U×şĞ"zúpÇîoce#Ğñ÷›€iÂ:¶3°çÉ(¦m™U‰Î:”Ù,‚HÂÑ:(ÚKûùÂ=Ê`~êm“à¼	Şõ/Å@ßš§9ŸNsÃy‡ÎŞÇ¤µµ$r‹yg–»ù&—ÔhîìÏ{´·±—fHíruúáˆ&TœE½X¡McøKêd(‰îv?Õ'ÙÏsİ ÁZÇ7Àwb%ùW¹iš˜ôÖU¸™ûoø­™Éu|Yäı’q·Agï»ÛSULxlB!¦z ¶}»ÏyƒmÎƒƒ” Ì¢)AQ™‚mâ ˆJ/€ÚüÄZ½Œ¸ğA"Qà¯`¡‡(^«¥fAv–ö„ĞTÌì½É µÚûÄ«Şş|‘t²u‰ìÏ	—œíoß!¡u¤':ÖŠ%ãd¼Îû€ÒåÚÁø›fîxø9N"ûX1¹@Z<†nˆØ(oÃÀreY‘vÃ¾ºş[æç±<Øğ‚ìÜ; §GÏÇ^6"Bßi1f¯.¡>çe.J†¦Í!Hs-•×ÈÂ°`‹a”trÏ¸tÌe¡ß«GÙÉåk;^-#îtgnš«GB S(æ©à1
YåuVzI#½„PTL”Oä¼HÿòàM  Û2Æyw_:¾ç=T&$<qwéR“‚AÁªæŠäVoÉ„6ù“KNô}é˜`µÈƒ¯Y›=ØÌ£w¡
^;V•°æ‚ó`É«¢ŞRHû˜ê£×ŸÈü	üÚ|Ñ¥_T1§QG+ı-Õ­w)5Ér‡f@ÚÙº“ Ûs¸§³ô+vn6_€4WšŠş›Ô!ÚzX¦0uÃ4º5I%¡Ü¢ş>œÀX4ÌÖ-:_êòòáá4ñÉ¤—ókÚk|nj:±œ~¶ÖMMaêİ?z•ú°,¶‚BËçS’bë<©·:z—Ä^‘çÍ°Fæh—{•õá?-)4´2pÜdèÙOÑï°­ğµ£ ì7Eø[DBé#Ÿnv‰¢½£&ÒaÓl0\Í_îÅ>ëE3»Á+Ù‹oß¸‘kîœÛ©™ix¢%@¡ÎğšÑdşîïæğ}*‹Â•f=_OÉ	{Yèë‡ÂD8ÆC ¨:—?(îa1‘~ZØŠ'ÛÆ.×R½›ª%o/=<Ø¹½Ørhh•ïËÄõŒÌnF(ûuØ¾`FĞk¾¶ïT'$ØYüû
 Î›˜«¯!ğiîaõ#zª¦€Añ1š¬\#êùHÁ¿"±Üÿ¢÷ğ×ô F¸p‚!…Yö0Õ ÕO7?Ó "u‡bÅ+myKÖ}ÿ‚¿2.ŸˆŒ¢\®ıñZÂ´\‡ä0É:ãbTvÒ°†&Úú½ÅfÒ6A£À-s<È¹¼+«Œä¦¿~Š{ò‘·LR@Š¬Ñ}q(Fn˜MFIlµeû(ÚlöÌeÀÜT1÷w®÷ˆ³cáz6şî¤Úx¬\zH@ÖèÓÍ)ŸÎÀL`!w±ûÎĞ„}å¾º/qÅ²ªD¨[áw	X!°âSƒ$‡ú·^R€$@²<±çJe=Áeæ¨*Io\C¼Üj_Lõ‡ze1VÀNû2&¶»ÇwL%–Í7U¾ssª†1–à×cš˜Ùâñğ3SÇ®ºÎ¢.<l´nçî
ü/_ŠûçÍQ—Êréq<åRÕ'}˜7œà°`œ÷d¸JÚÉùÈ³Eû­B
Î$Ó^éïX3ñ»í)â<ô’†E»R6¶K9/ı[*œCv)T¢Ğ”ĞØ¯KGÇ’p´QsòçÏ“¯×…«5Ğkí™}fÚ‘«€ààøÑ¤ÚHû"ŞqrS^o’P¬ÔúrÉ	V¦À\*d¾ËÍ‡¡fÕç‚<!&dÃ<+ıMÇ`8òÀÆ ¤ˆâúÍÙ³ª”ãJ–ÏÕv˜!WYLÎ©)DÏ–Î•»Ú­*…#%|K/˜úmİù°voj¸›|ps¹©¢ë2à€ñäA…£¶QÀsI"sg¿D#Zu¸éMXÿÒŠIRìÿCÑ©vÉ¼Õvi™tzT%«¤¸“ÀM8/…LJî²ò€ Êß~:òn³ïS`áşSõXTxu£ŒD›>‡ÅÛpÄhh$.Dí'GÀÌ5ƒvÌ’)‡Şäô`*Îã9jí‰>Ğ®Ô—q$†úma’WmÉŸÁ°­ÁÕ2L{b²ÂáÑïıŞEP¶y}AÔŸ›J4-}ié,¯¸QSqŞ^h´ĞŸ&ÄÃÍKş2R,ãİ$ù¨w'c&[ƒy
YxtOîê	ÌqO·ŒZ/áÃtÙyIÍƒ®ÅG–üLçkp³Ï?‹:i£ö¨b²”˜¶3îi[ˆÛüPã:”@ùó,Ö´EÏÎVÃU8ı`‘ÁÂåá€ÔX_Í<Vä2ìEF±ù¨4ˆŸÈb«á‘èyäù -lÙ‰ô†b`9¡\ÃâN;Æ»kÖÔîõ»rƒ·±ÿ€&k­\€¦çÒ&ÎÖr§ĞU¥êo¢“æ;ãÃ}=ÄáDÑXÔï€`$M…3C•¹‰Œ› m¤êEû˜*²Óm¯­-5h i¤/û‰iŠ‰Ç]$epTN·ê[”È¯ÇR}7[·GjOå #+[.†lF¼¢z¡ô(ÿpÅŞA>f§ŠÁÒD!OvË:?:¿°¦hä¹aÓâ”Fç´£oİ=SdÆÔİÆ·v¼yÎİ/Y0˜Šìõ×ÎÔ®çaÔêşëXÖmw0!0ô©Hoø”ÅË&·¨,ªÑTĞÛtåèlŒ*«œÊo+ç…åâ ­}Ë×vt´ú¼‘:Y?¿}zŒÉMC&y(ß¢ó„,=ñ9XC›â×Œ¢Uå»í@t‡B€Ó¦ªáqw¼Sòİ¶ß<¼ÒÆ’Ú¡UPî¤1aH2r{c‡á
FƒmÒ=ÿÆÚ¡ù‘+½­‹îñÓ³Zœ£&v8cqÜr
W®³ë–‰†Ú ¥°=Í÷(_'·Ï-|´“«Ş¢»×¨^,°¶PàRÆÄƒÁgFÁVœür%ş:°3jÓã	ù¾}D0_—KÀ­ÛuÂ,<ÒÄkVwß9ÿ~0LÖ(= vŠu§şÈÜdóĞ¡ìT#'0œÁÏñÎ]¤éÆR ©Y(ÂYâÙ~[ë5öv} iU˜|şùz+wºjN±l®à–÷„E'Òp±˜¹©ÎÑâå@KñÈÿSË“PW/uûzß5;¯hY‹œÚÛ·ŠIó£†^Á—å¦‡È­Ñ¹­<¬¹"×  ×R£>È·{¨3Ò~t?§ŠAúCd’¤&,B´¨7hu»¤3ö¦¼} R"G91Ğnƒ)ÇöpŒ	9ÒÏêƒ´eò¸$ç9e^ºuæRü*øÊ‚ÅòèšáVEmm%Æ*)µèË¯qGÙ7Œ)µ"+†	ÕãZQxØ™Ù‘ûÉ½rÛ·İÁ¨ğ¤GfÁÙ¯åT4æµhxÎÎˆ•áPìØŒ¥/V¹İÈ·—?¿]L…j8CÄ¼Õv­K¾y×Üôd »O;ÀÊ^ån™Œµ½¨.eà1Dyìåñ \²ú»BdXÏuìáĞŸ×T›%ÇŞQŞté¹§»ÕmkÚí…yS×ãD€lÍ¶éd"2ÊTêŒ3xö$ØHİa]ãV»w§!3ÉÓ’Ø94U	@€ù v…ÿp;\•Gµ»Áe¦IÒrÏL–|> ²!r8Òÿ×ujÌ ˜Íù$ñ±+PsìÕop:ËÒÁõz}S×Ğ®íx•Ééb¸o’$¹æãTÜY¦KÔ†H¸«!DQŞô?uÍ¿DU¨P(±‡g·'@N&!gÈ‘”MQZØå>ZÀ¶èoà±oL\\¸E"EC™Á{Ã<Òª”–Ÿ9¥¸£HwÌ„ ¶W&qŠ»ü[?mòû£>ÆAÚše‚„6”•^ TÖT{Ì#Ù&úŠımGÆ¹rùzwÔqƒ¾áO`n;ÛƒNìºño^“Z
´±|ÊîYße•xšQù‹Ó›[âI~«útÈ½¥²×êƒ¸j½®£N¸jºª„¸üi{[n}ÌR‹.&D­UæÏáè*WĞX%½†Åº^sÃ˜vr³ô«Èàl%%O"ös4`ô-5=Ÿ÷­'JÔH€MÂ‰Y+[tå7¦@’²í¨YVÔ8yêª+¡ïb‚ã\Š=;_¬Šc®C®‘ü¨/
—‡èİœ7E-¦øÓÏ¶•_÷
Ö¬S…ê*Êråœà|"èÛëR³U ?Æ™ñTÔ;yuùèºQuïÑ(ä?Â§B]ë½€»¾"ØNRL‚MÒÈó„y@šZÃ2ù|€€/èh–ÎŞ3%±.HcægtÒ$wLÙS´Õ¥Q“PwÔ·`Ò-ƒıxèº1Œ<Škí?òÀ8Ô‚Š<É©ªÌå¶–¾…ÍÚîíÚ-ğ8À¶†V¶ñ ÙÆR>ªKY½¶Iú
¡>ês;Àá—Hbûv×%[Æ|Ôç¨	 õ›Şºîş…uJ`²%nü·l'¤$È%3Êp Ñ9m áv‡3 E¹cB;ÇœŒÈR}îø§&×ä4n¹ÅcZ‘p°ëúp£+![4ğIv¦â,‘i.(Öüw‰°¦Z3şUdR¥±ÎT¨÷ìşkV+v'+ß^N¾q ÆFãø\Ë½„¢n+5¿QPãAêÇÉáöß9Æ€”<¼üÓA	%_‚DóñÎìIVş\
éwVG°¤%IS“ŠÀw¿ÁVF¸¸şPÓ,Ä»ÍiS5ˆÍÎŒU¯Bv/€Œ-ùRüä4Xh61Ä{­õø@¶õ¹ßYCjfÿo-i}¤®Û})¢÷°”39CÎ z‰c[J—Xìì†›<Ş443×‹×†`Ş ‚%#Û¶ycØn°o:º  $PĞ™§ä[SJß$ZŞ­êÆÁ4`ÇÏz1Ğ°¯g.g„{˜£…8~šÉ0£şš¥¸«¿Òîóv*Ÿ\ÓörYó„»zé/àØÔ6A—=òÚ±)Ng&İZ×}÷„—å}‘Wù„Ï>ôã)D½9ÏîBÿKR¼{²ukøÅË\¦ã•Aôrd?¶l‘Ì¬›Â…t	é0qÎXÒú6è¸&èšÈw¸Šµ/·ÿ‘µZ?¾u)Áî\Æg£'ÌÀp½æù9ñ“íak;Óß¤n<+ÃK§&y'¡©æ©ğêÇ¿\å</3æˆ`Œßi¾…ÊLòz@ÂMFèHÑÊ`|unq¹Ëü½wE¥ÿWiÎ±U¾Ïh6‰¹„Ïí4ù'‡\L6¼Ï¿Oƒ·6Ä âÃõ“äß‰ÅØxº°äLáåú+³Í¼æ n“V8Ìzü/}¹;òJÜ	ãJ/~}K{]%^kWÓc‹½*Ã#Äû¸ÿ/eWÙI<¿2ë,q¸¦tõÑ”ÉQmïÌ*ÿŠô(°‚PıV}İG\C·q­ü_‡«NnÔzgÅ&ó×‘HK#˜I;O’ÿ.uä×^ùHv÷C7ûfïk¶8l6\´¯ú^™n§&í[¯=Ç‚ˆS  “g¡&œ·z#ùJ\uIœì®üÌ=šµœ'	mp×çÉä7¡ê„8áj?ç¿ Y0Üg¢0TÿI·„=%šXñh8qÙÕ:X·WS§q2ÊÿÀ™0şuB%ê+Âıp4”:´ë«Qß^æ¨æ<KÍ, l84*åÃo‚ù"st¹±].^Áv²±âmÙƒÈ–‘?“I€‘`‘ê¢îU>/›a:®1<Î×WSø¶¹ Æ‘²Šà´íĞåËæœ˜l~óä4Ğ£ ÈÍ×Ùÿùhï·®8‡¤¸4sĞMNQ<-m†Ó‹åÚáh¨Àë÷éœªn0ª…§‰''ŒÙ››®Ÿ'vu«D!HA;%_Q ¾öìĞØ’Ì´yg]GÏznXs´Œ§5(ÀÅqSEDP:ıé‹JµóéÑ›ü‰âÌ¨ê“¯R?c¾8n4"ÇˆÒeÂÚÇ˜Š
lİnß?ƒÜ‘Ş-»­:TœuÙD¿ÖÒÆ*¨Íİ(Ö]-÷g~™¿E ãÁ_<&»tÔtUÕ¡8Jä‚Œ‘NaÍ"-¿neÇ/:·î«ıĞKñß!aáNÀ|g±şÿm.ÅªbLPcp¥(p3–C”‡Ì!•™6C\Ò+æOÉ¥²5î¿ú¯_0º‡VŸğz‹cºl¨b °×àö*ZèÍ»¦{^ã—÷È;0€í˜¶òP´4‹@j?ˆC<¤N´.ƒ*y}V±6êB¦şjlÍ Á‡4ÿØ,n†ªl 7‚Æá§ïpÕaÔÎbWŒ1ÇS‡/kjÍxH£Åq@m–ŒŒˆM+½Å'ëoÃÊ	m×¶/Úˆ9±£íÏ%ñœ¬O>xJC=ƒ&…¤¶=¢‹@ÎyÂ•ÿ! eøc—cnw0ÆQó?ÉØ¹ÕLNµ&…È5
 ¢nú6»gg0'a*¶–aËî–<†óHj·“ït}t¨±mvaJôq6ëÚ¡Æ‹?‡®nhÎ†˜S­Ñ8!b‡&#7U‡hBÿXU>E$™¡l£ç@¥£±í—V&ZPÓè0j•Ö¦–j§ 4C1¥t¨«éõS€`øĞÏZ<F`–u|by{ŞCŠµœ¡]¸±È§)4Ù"kç„ŸÜÿ¦Ñ”Üsyü³ñLŒÄÔTHÒ/ }BÙŠÏ­—¿’öµ6c(ô+ıĞ"ïÃhUøÉ¡nEõ´·ùˆÁüİÔû+˜PŒÑÆ$.Â§İÇ¨tÆú¡X"á°ñıÃ-ò¥a®BK¡¥/Ä*å1ÛĞŸ ·ıvşÙ	rm1¯¬&@ È]$1ğÄPÁoµÂªÃ£pÑWğÚ µâÜXã!âyi„¬Ú<²@èİ£ğ|©6ëße†Œ”ÒuÜ¬ar/Ø¿ÿ¡:ˆÃ}}ïùìÀÜß\„Ğ˜GâvÁˆšv LÅ<ÙQ3eÌp‡(WàGù¾51ùß-n9å–S]Î¾ƒ^ ©+ğ¥L]ÿ]¾U[£vC™P´¡n-:ç‘å	5Ø,4n(7yË†,äZî¾‚¾S©!ÔE
êÒLÊ>›ùÕã¬³E…3rt_°¥û5ÆÖ†CZ‰d*ÍÎ…û¸g=ØdŠ,[ÃnÄ
ëò_$@¹¶êxw6¥ŞÚLÉ_x„²|“‹ÇÉâ-j^kò9´¬• ºfêÀäàÖ$vAÂó7§œJh£ÜòOİ!¶·é@n·äz/ÉíÉÏó9ÈÙõtû%# fTN|Õ“FÕy‘Ê»uQ±´§#ÃÆ€iy"§$õ-;gQn‘ê·…›x¦Lğ¿ Ä˜¹+|ÌkEÀ¯hI’²ÊuİÈá/—ÍBMV®s)4 §$t°‘9³x:ÛÓEhKE5Ê«Õ ÔÙ#3Ÿ(ßs5\‚Óeå‡4¦üÜ!¤˜ ÏKÕº¡QÑ\º;*DígÓ&<3BÆf–Ñ—ü÷•`…Š°î‰^Çyc½äşN*Ú<_ôÖÃL¯pé_ ÕüñÖé¬}ò¥‰d|r¡ĞYÓiOT·ùşjP„Î…ä,ƒZ»Pb<ØG>N2IËB³ø1:¶ÛºÌ,vñ<Eı˜ä­p°.WÆıt÷»¨5©|_
²Mˆû¤ÛÓ_‚¸Ña‰{‰[Ãõƒşo‰3L•ÜW$è§|Æ‹…ı«Qƒ6ãXxÈóMıí\6ˆõp ZŠ ³Ÿ×ØÚËÛ‰—çœÈ®Ü™$÷İ ü,ñoŠº{Ë§3Æî7ãB*êÃwgµ`ô…gÚ¼A¨<á>®Ø¿ûÕpY×jŞÎÊıËÙĞê‡jz~¤è(İPù#ŞÇuj÷4ôÿÁÒšìæ%³9sá¸ò^°FcpÅ‹sf›¨(€ÃÚÈğşC"»ü)}ğ‹åTâ!‡ç,Zò¶Ã :F,%L¡á‡v%ß%[p&º34lNŸ…İ–“u]·Æ´Ày½!}°w­«®ı|³B½u·¿?ÀD¯4h­ñmÕ³0ÈÂÊ‘a µ=ùÕˆ˜x“jpõÑ|(û²şEìºôÇ¦2Â Ä/šuXí0ÙêëNõ‘€ÿ¨ì8#w…‚×?Ë=£Q³([½—JºåmòÓ00\VY´«Çæˆµ|.¡"×yÃÚVaH–dar 7cXúôÆ"òÿ’Éd$Ğª†‘Ú4ß\)L¯ªi:Š[áÔçî$MU'±pösñ¯¥RvÔL•(B7ñ·±q¹óš}³Ì=ÂÆ6ÂbtKMy3X=ŒI«ÙIv¼t¶KºQÀ2@Å__²ôû"L½œ.QJã£"ìÈù~#AU™7£@p§´å©!.ru˜S°9^XîIAól‰Šğg¹ÖFÀsù¤>ïoBXT`3p)¬å7FD»©!7à>»Ğ'«?è? Dò2´Ûoe%ò¸#öñÛ$Ïcº›i×'„P—T¤ ç–;I±-H¿ğ›áêgØŞ&w2=|ø˜Oäå^ã¹GRR™”2ŠÉ«aJVŒçw¡?aûs‡Æ€¯´br/€¯
äg‡…"Ñó$ÕÒ$@Wƒ8¾I!~öÀÒşXœÒ½¯›ñDŠ¡+~¦+0AKñP¾µÔ¥–/íLø=’Só8¨Gúê‰P’¦¯„Èlkç‚t—=g`6£kUÒ¶ŠÁ¬ÊœLƒ¦üÃœ9À»qÍ©tŠâò
ªô€ƒ1›Ôà™¼µO¦HÉ“wknîxÆKõÅø"€ì{@˜ÖP•ádµ†‚?ZÉ¹şìX‰m¿ê»ÙV)c×?¤©¿pQ¾9L¼Ğ6öÂtJWu"V$<©x$5ìlßJİ+Pìµ…ÛHªˆeİ}Ş@P¡’û9ÓÑÕ
toœ‰9³=qÌéWµ"ÃB$÷™ÀËM6¿&±ÈI`hù‘³Ñˆ³îÆO”^ñVˆ@˜ˆM@~nå\a?¡±<Ñ@Ø-x¡˜K}[m${~éê5—>ˆ%î¦Øü€`ñäˆ³ß„r$åºCÇ¦Õo%3‡^ ³ÆÑæ‹ú^9THİŞ|u†ï²Ô‘ñ2
æÂŒ8Ø¾ùTş…$ÓG9TŒ_Ú¦E9¾;ğ¼Q¦9ê¨€°VLè‹İ*æx$ëvŞĞyø!éÓÓ_œ“ÛõîS.
ğáÅ:k÷„ÿcó¶ØÑÂôı¡:wä:[QwŸ;~´é_uÔÁ›W—æK L`—ÂïNr­ğ¿ ËdÂvÑ…Å_ğåM+hıœËË W7DGG(uH.ó…¡óO5ò%Z˜Ö½¡´Ş­+Ÿı±S¼)¤m¬‚{(qz‰<jÍkî	l(±m#ß°««m?t‚<©ÙˆqqíÔ„~¾x¤(cÎTto–A» cqÕó›€G“¥Øò»Wh{$Ó>É^Qÿ'ÀŠlH¬n%¼Ú~{“¬Í‘;üSó²™!ø*´+WMr;ğ¥'ş ºàé8QºQl¨í>:ô’ÍÌÉûT¡ƒnù!ËC;Ê®b­ã>ï¥)]©ôn©Êæ†ì(H"a Ää™w<„æ×1†±ïÙéÜ±%^&Uà9/×yWÀ¬xŒ#½K¸‚¾ûÌ”şÓiZú×.öÜVœ)Ûª_h™`¢Ò-f¦ëJäÿÅâëjeç’¶-—ƒqyÎxõ7œ%nÕ_çY5Ãå&?e­¢€ÄŒÆ§O¿)òHÙÊÈ£zkGÖLñ–LŠ"Ylb:<:›…¬<UÁh¾¼.×İöıñ”­÷3¼Crš=Ú€KÅûW&S£Ãö­Ş2VøšaÜQÄû@$w-äŒ³n[…æjÂ2¥
 Ó`95—GÚ¹Ä“/°T‘Ù~Vp™z4ĞgÑ9áJ	ó
ÀBÎ¡(ô-èÖºæFÿk#©èÓ*†ú+³{f%]VØö‚4À²*¹Yî¹¸K¥ÇW[¹Á=šq¡hÔ¿æ1"Vézğ˜ş•Ÿòn=JNM~@6ğª¤gòÅ”ˆùhğ¿éÛàH~MVÌp<ÊÑéÚa×Ãgÿˆ$DNiä–¯Êë<úíÂÅä™¯öÏÏ6v¨‚Í{VÕpí'ÖÍÖ>–ÿ‡£[ùÔ„ İHkº]Vmâ=ĞÖlG¶>M„°Ô ÿ¥UT
©â¿Îx9šqœï·M¦á´fqµ	ìœ‹tâñ	¬	DÌàQ„[* ğcúÔèmmZAé×–ı•Uvs‚F¬õ¬Æøã±à¤ìx5¦×ÈıèÉ²LÅ(R‘v§µæíAï /x{ÅLsF_iŒ/Æß=áDB†!iô2wÄ¸âÃWb/‘CÿZ93%!]cÉ#3Î}ÎöÖëW•S:P´ºı.¶ÛÜã½¡C®„oY5­¡YÀªÑVşøÀ³=²cÒœW?ÇR^$~] 0R× Qå›¬]õ`ûÇ‚]¬(°Bò¡öîd ÿ"ßvÕ:Z~ÎÆı¡±}®C©×ª›‹pÀR²Ì®jw¬aÒ2Ğ´¯8‘U«HyèäöoÆ’æo¸B\×2z¢f”ä¯”/|ÇÃğòh\âÖ¨#‚‘éìqÈÂ‚èZóûmó;šÅl|üÏbŒhC¤„yoéqÇŒ½ÈÒÒn¿½¶ì£ˆ·yn£ªM"*˜a4L!¶èŠÔÅå½ÍÉ¹ÿÎv‚ó‚–]Èå  gZîÖŞåŸÑ]t„ “WÂ;‡&šÍH+ç2.t]$4½7Î‚ê¸ŠiK<Î>¤©„>*Àd
ÀbN-ùTÅ@î#ÚL.§ĞoˆI5Áëq\¿ê I?Yõ»¹rò]÷)ÙÑñoKã˜ì VÄ{>×ŠŸ®CÚ é;amYP²xQ­Ğ—J¤üš¦2ğnÄ”+>EY¯Ô:@?…¨K!èÒc"`†Ï‰]y§“»‹75CB†êóiÛ~`Ò™] Uõt†iÛÙó/w0ÂBÜ¼ß^Ù­+ĞÕ‚—w°k[2Ë´ñÏ r(§À€ç]ÅóWVè¯g¢Û,VY“îL†²D¸,úø@Â¿İî¹‚ìéf…®ÿ»’ñæ°ŠÜEEùœÈCÊ[uÔº½Ğï&NAV¶–äN¶ğ³E÷é3QZ–ß~aª
óÑP™ÛÎ4Âèb“ğÖk	$Eq¡¯vR
jè
å*àîò`Z`G¶õÑVA“1¡4=6ı¯0 Ú8mÔMÃY/-ÑF¥ûQF7ê»•¡³uĞM
}<9éBéœÛ¯´I­g‰=NY×wÂ‡#!qk±XUè•.³ó,É.—§½¤ C¿Eyí™¦õh&
”Œ×7CT0«/,W›ºC}†~5Äœßûtz?¢ÇH^DİıSf)Äeâ†_®ÄÚ+
H¡XìR›ä~"PŸè.A,ÁzÈîv”1àˆ;sv»U¿·ÚÅÚ»³¿\]bê>ĞD¨‰iqb%Ë¾è ¢U¿/Q-#Ó[;Á·´Îpr £½°9ˆ8ĞÿˆABÂ˜ïQ61ñ”Ö|P IÅ·QVº@)¯$ôœäQÖöo
,¸”7>2ÂôııÒÆ·|¸‚œ<F€Õ¾íÓÔ®õ(†zÍN¾H(†½†yäŠ[ 'EÂ•¬h$ _RÉh‡Qæ•@0ÕV«dş›-ïø§$—è—Ÿ™%œWdÆnØényôğÃHv ÀvSJ–ïv8=Â3\ èÅ|—53ËÑ)³!v€]ãq¯ş	r¥Úøó÷’A^@(á»Â™”ç%°QR]!}Î3o%pDM”¢ŠQ
¼„T¥›~ÃròçÒq±=­c'††Ş£mù÷má{sFŸŞŸ0£²…,¥¸ÏíàÃÃHXQ´”×¨ÌñªÕÜê·6ÎÓS?AÈµòíúP/2î|ÔÍºÏÁ„R#ìˆó«ÈÏşÌòı °®4VÏ¼ã’“‰ÚX´°§ıÓŸÿ0º®¹îv1òÃàÖéSñŠkŠÕÆ¦ v O-G,›¬T$ §_ğ’ìÿ’ñÑöNÂ<DAVj%1v’ÙÀŒ.¥ÔœÇ©øâœfñ¦SH(ú3ˆÉŸi÷càÙÅ\aÒOûO¯ygÍÏ¼\ä°™Å‡|WÔ!”ŸTu B+d2Lg°<KÅõC"]p]õ¡Ş«Ğ†­šJÑ‚
pÒcJè{‚h§.áßĞÊ•UhjxºÉ}»«şózbî]Å!búƒŸ"0ø1§ï4¦Qi[[İÜ%mÖ	 ê³ÇÀ£å©¼Øì«ø5wñ´³´H¥|W×±á%¦+5ãíØS’Aô{Ğ`z¿†TÙ`Ìo°[GÇpPUÑ=)Hà,e´ >n·9B¦+¹ñz$-ô-C` a5Ñ¬SÎ»v©/K55qãrÉ°Z§äpc¨ÚùEö‰¢óçpQ ,JÍì†dÕT"ê9·pÜä"ÄŠY„§¦TœÁ=âw0^»Ax\qÈMû8!Aïß›¸—O
Œ–ïÆhÓœŠ 5ƒäó\ëû:$–2X]˜·A™ÚÂÁm*¾Š‰3Ô¯èÅŒg†şdÍäü>Åd“±gOÃà²B_æ­øÎç©\RâáqĞ³Èò!xÄ{‰Èœzîÿg.ŞÓ‘&+ØáÈ'—i®;Æ $Çv¹™ªW‘d—¨IT†Ÿ£Ôâ>Ñ\bM"ó»’òí8<ä¥()_Ñ·m·CFòn3ß JL%ÆñŒw€–ûıa„„[„€ÿl´Â&ßvC!İbdQŸÊC¹øâèå\˜VÛ·¸2†7³y•WIwØwÄ»„}P9ø¼ztbø³ï¦eù·Dá’Lƒ²e/lÆ†æ2»8©²'¤óM]ĞŒÛ¥Úí&Ô¡µĞ=I?Xò cSÙ&òA¯®.ü'+ıÛu¶qz\r<â™/d—a¥¸iÎC“1·ä	–!{BŞ^Säâ^¡u*EœÄ1‘3=9^våÜTëøº
3ü0Ì‚&½ xÜF
;Ù~ŞH‘î¾Eœ±pEc±L”G-”«ÈD‡ØLq:€f›XºŠ«ª#¾ùÄ+UÑ2: eG·Neg‘¾Ùq‹;çKçĞâKP›¥ïbå"Åœƒ'ğ×Bìl[¿ü3ş%±d8ŞŸœpı¢ŸöÆ’®"\<.MœõF€¼0Wƒ	¦z9ïÎ9¸ Ì}PâK´ÜFjûü6!_[®éĞŞy^…Mø˜ÜËÂ¸>i	ê"i‚‹0<œÂ S¸ë®õ²CbÉN µŞ¦§¢*hŸ ¿÷„¥‚ÁÑ¥=DøøwV›O€¦HC¸˜AZÉÜ§Fënz<^ìa[¨Íúã%÷¬"wUfšT\½kã²<ª}´DÚûüky¥Íá0² :ÖŞ Á-,‚§(2 Rà±áÀc«˜öQ#ÈÅQc›Eò˜)?±?†õnVKğz+Û“ëÊ( ƒ,8·x|©Ê‹ıÄE±©elñ\4Ú›UÙıójÌ˜ Zœ¼Pù´d…ì1g€PUXæT¾&¦’İ$ÎŸL­QäYçhš|o:šò¡ÕærJÂ$Õ—a*mD«·ó1/^{ì¥±vû´¾	ş†=[²Æt@ğ®-¸øŸ‰üMhPğ'ˆC¼Ù£Ö\4Qó¼3µíÃ%ä(a äŞx:Wß®N²©¯™sĞÉ3	Ê˜œ[[PGÔÎDÿÈA›û"€g.“ñ*|¦ŸÅ#u`,eC¾ÌgaÈY—{§˜=™—–øé¥µjh%à,[½:%<cUCİXÄ)†¹*”‘7@®â@:±y9‡ŞQP(zk|Ó9hØœ	Z'IGà¯8DçûŞBøYËÖ»ÇCƒ8A~(ğµŒĞÚŸŞR“’L~so4ú!ˆD·r˜…İ]Î2’â_º!;!¡Gi“2Ã;éo¨iz­Xñ„ÙĞ•²"‹yVx|M.)¦‘tŠ¼r|£ÔÇqä%J)Lg JP×­û}:@£–3kë"¢ °*lªúcdJgÌ_¼q+,ÔaÈF{ŒDd#¿HùNüá‡HºêMıÍ¶Gk· œ‘àƒ×.ÂºÇm¿I+öXM |ßĞ§Q£…>Éo=.ƒ=
R†	9,]÷„|ÍSúËt±Ğ—· BŸÏr€Xƒªùm’éíWÂ;ò;ÍØì™UV÷=³ñ›¦#~¾Ì4­ô;Ä;òŞ@5)½#	1{~U<—¹*‰‘{ÉlV+š}œ{E÷XÀagâÒš]şâ=2}~7!ÙïC]§®g›</–<ÂŒ‹áˆ­»‚½6<0Š·v³Áó—<$Ù!ğ…Ccë¥H©wª3Ñç€w$­Áãtktø¸AIMß-ºÆûòºõb-Ø—‘`ËÕi%æ×æ_9¥B‹³5o#QL¿ÃYÅâ€G-ƒÃÉ=E'Hh][İÇÿ0×Ú‚ç†Æê,0¡'eÑŸ,öÔá˜ûÇîÎ‹Nç»+ˆVpI„öºÃ;gE
©ê­@õÊêXCyêyË Õ÷?Ö×ôY½œ4`^ô½óƒLÑÔÂŒÙËÑ¢ã-¡ƒÌ·êš°Ã-ÀÃúÒµH2EVÆ›Ô_¥M>½±š1½z¾Nİ®l8³Å¨/VJ”ViÙ	ã^åº+F„I¡7uôÈs™f>3ËVÑ›^@X‰³æ1³¼Ğ}enn;zƒïtéhÏÈûFÌ)1ê]„…UœÙÍ¨¼H<Ì‹Í=Ü•Ñds—‚6éMÿÒÑ‚®¯
ç5TtÇ‘½Ö‘^å È…¦ur49Nº¢	â-å'‘9z_éfeË2Ğ œ½¦D<t3CEfv`ÑaºU,DÓ* ó!¿İ{lµSW5ş$ ¿­©eÿ-5Vàw¥d§šÆ1ÆğÈhvxt©KåĞ‚çÓšÎ	vTE”RöÀğ<ïAÉVGŠt_ùÆ_İ»Ãç¿ŸbsŸb í…„Ô¹G;û{9)õ3§AÓÅæõh”Ï9rAõ&±_L±Lˆ|' ˜íç­Wã—ŞK5;0Bºšt”³YÚãP\aCœ9wıŠáÉŸhI¯}¯Ëuq.åÜ´¦À¡ß_ƒ5>|Í'|úU
³Vú¸æëğú"´Úñ¿hsD…	â3pV¼m®{g-UÑ·‡{»×´ªÆKK d„şTnb2U–7ú“„]ÛS"3å$Ú¹Êí˜\   Ù]¼ñ®Õv ®¯€ği”b¶±Ägû    YZ