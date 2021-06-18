#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="939394180"
MD5="4080a2dc1e16d929f9f2f127f0814a12"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22828"
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
	echo Date of packaging: Fri Jun 18 13:23:55 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿXé] ¼}•À1Dd]‡Á›PætİDñrèjZC`rŒ‘£UPX&Éª®N×¼/Ü‰	]yµ•v­ì÷uÑØÏ³m‘ß‡Ùw…zá^C²@œ‰Ö.7¦İ¤cP”9º…æÔ½zåtåj	[¯ØOîğÿ“ãËtØã‹­Ò¼şfŒŒfMxáÓ(œ$‡Ø2iÄòköJ¦ß«×…”¡‰Á	ôˆK;ªõ¾5¶ÿÓ\ Nmä¼{ÙıÉú¥ìY‘‡áå~È°NR’ÂÆ¶âJêÅNºà÷y‹–õ4&Ä‰‘±ª#ÂŸKfŞÊásÔsq|!Tìºı²¡ƒı‰·=6çÑ2+jG®ÕÅ°û,8ù§E™z½XË”=	ÚŞl"ƒYù×ÙêCô\úİ—Ø»M"óöÎàj,Y«çµ5U¨l7ÈKœ¤ËÕ'ø£#5}cÿp›A Ö™ 0U}W—‚óúuì¯âV-%£^ğ¡eê
ó0ä±qÊ/I¶À¹Æc«Ñ	½ÊåøZiÊsq7}D†u81Au„GYªªŞ:á\²ª5Æ¼BŠ*Ûß’0;ùzâle)Ä=Üu‘$PqÃ¿C[Š3ò¯]•åN6"gïUèm!oê¾³ƒíÙ„ºÁÚ#wêŠä(1ÏC”ŠŞbV°ŠbE²Dƒ@¬U…§ùrÑH<LI4˜‘­&Ú:5á‚g*ÿ¿şb<PŸR—¶…±¤™¥á¦Š]1@c=6QÀS1‰”	ZŸv|çq6_z’JSÑâ&»!]b>ËæQÉ>O¼ü»ÅˆT¡İqaL…ÇTt‘h?Ó äï·Ã?ŞÂû
òßÄ*ƒÄ6|§®êj|bê¼Y"ƒP\uŞƒ`?R¥¥ÇÀK`üo¡óT;•Ò·AçR$™ëw²?]‡Üålx&v„HkHU„Ñ¹·Él^Úî’ƒº®±fVğİõcPš^8Åbk¾¦;˜öuÇ^´„İ(Ã—İVı£Ã-§ã_yûSZHŠø­Cô0æªyã«àˆ°NXsU‹kZŠ–ê¦f.<u.ıRgn=;wñ7öŠzj©‰ã'Ä&Ş¸/Í†Xtc­¿švA²ÛûÏÃ”Y³
kY§Ê6å¯øšÚl‰-L	¼6òV7â"bÁ{»\„İÜLG#‘ŸÔ3ßûNSÕöc!l›}3ÑmŠ%K>+ZtŸxL¡}.väîßæÜâLïZõ,|fmÂ¨d˜VÆäòA×²Ü‡|®“#Ÿk ø¹a ,2À^±ûŒ†åı(¿xéBd³ÒÊÅ‡ÿ$«ÈeøpÊÆE# ‘2n4ş²ê¬Æ#ß†IV=Ã"[
ÔÜT*æ|Øè¹¦]UÁşÚ5£Ò¥¡u˜¨ù“S¢1b9p_p$.ïÊà‘	n§O…±Ô¨nb6b³çšWf<!g,g×ËeéYÇl¶ÍÏjÆ4Š}¬B“ıŠ1Ctî¸ÏM'WÇ3Ÿéøb1H¶Ì¿rù—W@¬Ù9Ía§noìäş€úæ–ân².©d÷Šç©¯°¤nàœ6òË@sÏ§á0kVDàÎ˜. zÑ£z-nÑwVæÏ‘ #k`mã‹B„=	3İ©5ï<$äSBüpYVÕ!dL+BW¡¶«¥ä`_Ñ( ¸¦ÂöçĞzXäıšyQâÿm“ñ]áâÑ=(~õş V	"lÂ@“#kÇk”Ë¦ğr'!öê©|
~—F¡­ Jçéò‹÷lØá‚S°\ ÈrF‰E€	-²+ß7ûğ%ì2UÌ^³æ2ußÓ±²y™÷8(<äùß³Ù¬FfM(ºÈNôÆ[ŠmÍ‰¨k¼lgÀ¡İı¾QHŸ|UëBÙF’[È¢…­x;Òˆ…Y}ù‡[F5|ò8Ş1ß–ŞfûCÃ£Öf˜»ü¿eÅ¿‘fLieÁ»£DœÎutG#V|è6¾!ç|½4”ö ˆ¶IGn­á‹D>î+v:b!Ör¥zŠõ¹OşÁÄ%àEıÚn3d¯¦]A7s™ÆÛO©”ÔöZ½H Õ÷È;±ÇÙ3`!wq=…ºB}kÚ:.FpÂg0@<)ÙrN.¡Œ5fÜ­úĞğ—Õ	ÔÜÕÕÇ<İ ÔæÃİ6#¶ï>‡@ñªıôRUó­×¦`”£Ã¸c·Áü[–­şË+G¢2şİ«“É(ìÀ(Í¢QïÂ¿½ŠÁqÒ|£ÁŞUœ]¤pt©á°]Á "ì29KÛÔÚyáGª4Xù¢°<®üÒp‰ö€©èÜÿC1'•ÊåÚ¶Ú^ÃÃT›§Œ—Öh´7&<Äf½%;€xµirÎvì á”d’FB|ÜöÈ
atö(aE<cVvZz”ÎôYÄ¯ÍŒL!Sà!Ì2$ı"TRÃıÜDx$Áª¤³¨Íã¾˜jhù4RÜ×Ü¤—€û© ï©JÒL%I«–{´Ã^˜  nk­w®”Ñäì€›ÌgD‰Á©nÉ¦¹aøØ¨¾&y$GËSØıï]@CÏun§Û¾&íõÆ1fZ€OR(Ş5^U*ƒÀy˜X[ ƒ©dÿëßÍ£^xê„ùîú Œ"	xŞ¬P}ŞÌ(s(¤)æz ZJo3”$î‚§»¸Ô…Ü¹­~lÜ¢öÊ^9_iÔøÓ7Ç*¯Â/Èğ$üjAårw{ãz"­ÿLÖ½¨n‘¢Ãš¨3v¸Veg+L®ËæXÿÚ‰;t¡äî³°oe¶Ù¸§œ­Ş²9ªöâª„¾^Ô:–¢O/HµÕG¡~Öh4÷m\òÈ$vÕQ‡ò¾>–·°‚X‡(?vze¬“&¨N*,?4 ¤4§ †È9ã=yKT1°]ŠU¬¤–Á_ãfX¾¶Ãÿ³	¢İŸÖóËİÑ:	Ãğí]ñàÎŞeÓ\òv˜jl–MåœùŞ•²ôÀbÁ¿ÎG”…äm‰ö„ÚáT/"2O·ñ÷Äfrºo'á.lwcç·ß¡¡éâ¡ÊÑ_˜vZd£3øÜÊgöâ1é;¿¬8Kä)Å.ßXqZĞ–§Í=ãs/oNR§¿Á×ƒYLæŠ† ½tìç ïD­…­ Â´ğë™¼°ˆ«¼yÒ"øœ˜R™MËòvˆ'
õê8ÉªtÄ¥»B+D¶±!—]P?Ø)GpsíSöIìğ¸¬®º$…µp/,
Å?oIÚ(XÀË	G oûlVgšÀÍÚÚ5ÛŠij·õ·x®ñ«†»6"):DÏjÄÈÏ"Õ¶£Š1-Ëa¬äUa,["°ìñ0E“ÃUÇº§dÚ°}™–	à%0õš•ïE§µàO’Ry×æI…ßBfy&+nÉ ß[×\VçF—c(OdXLİ4 ×kGUÁº%š®p,¢†äaÇ7©¨Ñ>£G—0¬şfˆ,Îà5ú54t=Òó‘&(b¸v§	a76¦çEt®’gªKğzvV¹Óm©ßñ‹¡D Ë£ÓoéY‡¥{®şd·ßv1YùŞ,E&]îZº[a7‹ÊsDó<-Ãî=—Ø—İßœ–6»»k>j@$¸HêÖŸ,bÚ@~ëe-Òê\‚'1Ò²(	×¸H¼¦ı÷UVww[ tœ=5:o0tñ2+”NqÛ´LØ¶nf‡ö*ü ôÿ‡^Â¿ z¶4²håéÇúíQL½sÑ”nHücšúÏÿ™;…{ğ6£QÎX ûÅ&æ+ò9ğï´Ü·ğ@Šåf›Jå"1<F!ëÂk0b<¾¶pSZ ôl\²HOÿÇ;°öËŸ&™|g3¦²‹41óõ#N Ã³Ö‘f½¥9#D“d¹ç$ú¯U•‹¿¡#íìyùŞ_¹’:•°bô¦”g–^ffß”8ËAß.5tmP£‹‰üÔ>ıÑ”#	»¨¬ÅPêw¦ŞIò‚æíE‰·ÿ%4Ù24İ}¨aSÙ(İ{4©½hX7>¼L„à1{=ŞœU…Ë°æÓKuÂ‡D‘Ğo2¨fˆƒÁX¿oÚ3"~#9¬´]ŸLûZìF<ÓkÛñ K`¨¹ódo¦pZÊÀN„Ú½ínwÒÍUİ¥M»¦5Ş7rò‹è·f\Îzî	ï°³½iÔGíQ0šÃÈHÁG¹¥Q±ˆ%øæÆ›@<%ZJ1{İEqÆjûáNˆR.äUï”Næ¢î\´W–•|K–…Y1ğéLåğ‚²"Ã÷÷@Kæ†â‡¶µöµ¸ôâ³Œ`·3¬³V2Ø¾¨h²¤®gF0iqx5ãÛHÀ£,`fŸéä®Ğ¤6ˆåİµX-à{Dı0?,ìÉu²õÎYÉ&Î(={c¸¶ıt\ZrÎyçã"´®Õªæ7ÃRÊ<ˆ]à
ğ	¿†Üº={XZ7#1©¡Ÿµ=GòRCò²(¾"ì~ÙUİ¦f4kšã_Oƒ¯Q]{„ç¬Í1McÅ‘c*BéCè¶Xªï5g+%Àí`µ Ñ³4Lé	MÑİw¯%ş›É¼P‚gìç.ñyoŒc,*ÆÂ yŠPú¡WÍ£']ÒÁ«°é9gäÿë²Ø÷bÌ@ï’] +ö±!Z6Ú0clSßtx’ÿ·6-B.Å=¤n^¨æ>¹Ó¯÷IÆ@u”i»º²bÄít‡¤'3ê]Î÷ì9k‘áÔß¿w°¡ëåoî¨ŞSú¾o”w	ÿúî?ÃÃ­÷¾Bî¶-Ää
cŠ¶!p)ëu®pâŒ(¬ÑÏTç¹Ë[-}›.ş(Çhvç5ÆB
ıbü)üÒûşKd¨Å´OÎç_Yˆ% ÒñqjÛİ·œvŸ°âÎ9óKÖ ÷¼Y×…çİĞØàbgÎó-ŸôÚIh/¡¨+JõRyÍ5P1,8e%{y0©N/¬®PÌ½¡ŒO÷ÍSe.f¿i0{œû™÷ü>ÑÛ£¨ÚijXÕ —D\»<<¡„Î´RÖôébçk…#…™Á(égPa‡á#C“é[û“Ë%6ƒZ‘ı{ğÏz]u1OIRiÂBù	è
‚ÒŒkªôš¢ÏÅ‚U.±BæöISâo»ãºLÄò¨©ì*…€ªÃ/'vlû<Ö8ÌiÜIë°“æ3'„êy“Ãc³`‹Í£İÄx†œÕ½:?¤ocÌw —z‹¹è |ców14ñ+ÙÖ.vú¤­®6ûÿÖ§Ÿé%«ËFLùëçá©³@ÍR˜K"Æª´É²oï-²>zí&oİ'ÍVKºîáªSÉ¾8
C
 yËÀÃW8Zó—Ôã€À¯}æ…œQ¶¤ mğŸÒ1Ó‰ïw"üyvµ;”pğc:=«Œ¦×39 uÑ»ldiÉÃı˜g1\ÈthöR1^Á6\†CĞ<´´„¹Ó€“[…Ù.í5=k„š¬Ü(ÄEğ_VÉ\ïYÀe§•Ìiÿ#(håÚø>¼ZÙ0ö¡ÕÎÿââÅãÿšÁ¦gq6Ò˜CéVãy3pÎƒ}iU†z˜«=VR¥TËÂïï÷Æ`Lp[¿—ˆNË‡vÕXæò!5Sv‚ôû<BAŸ0UòÉq"#=áÉÅ;mÖ]x|t>OÇ–râK¹3q7î§{•ôPæğİVëU‘õ$'"ÊN>„–ï\É,,°ğÃâtf^.Iz¼“ÿ%Q¾†–şL)Ş¿%~”ü)ƒ¿#[óÓq¶&ÂE»œŞ³7„-ÖÄ¾RêÔòAH|ãÄ´şĞrÎ [øÜÑû´ğÁ©ò’ÜÁ9MÇŸÛ˜úøŠt9´ì—¯#‚cbG³
ÜÌµ¨~
´n+¥ÿ!pÿxHÅ€—ƒ°ôèY±›Ë´fÄc†~â…±A§Z*Í1]¬¤—ˆ¤ÔÑBºZµ³õe©Á8Ïƒ8©†6&u¸ÅéB}u .h”àÓ±d@@¢3NÈêMÂô1m‡ÜòOĞÙˆ²"s?èGe‹˜Aù0‘²¬î¾{»xÏ'd• Jå;•üÅk(›¶™orfÉ#1–L£±É'¼Åî½İ„,T<ØšÛ4^™ªF¯¬d–§RÀLaÚ¤/İØ¬]2jŠ5áJÎ2¦‘@†VO¸ˆÊ'Få	Í†™åÅıs®|—E÷±úÅë¹MîÑË*RüPÀàÕ6b¼}ùè„mXÛöË¥<‚Ğ@Õ¯a.˜^ƒépªKı¨ıy¸®MÓ¬(ƒ	ŸÍà¥¨gŠÖÃ[ïj³.–x+	€i”ûÇÏ÷|{àÁo~Äßº™Åì¯Qæãy® ÊˆnYÌRönThDña8½ƒn;xVËê°†¬‘ÄS;”;ï™Xgmõ )Ü7ßRÜı@ö/ìçÇKl4jfô¾ñÍÕÙˆ"H@ş÷¤HAè}t3ƒ1×-I•™®T¦(¤õÏïÉ´ÈìèĞnLı”ƒizrnòÛ4=`FêÈ­%F§&¬a)U,ìÑ6|ÕbºÃ³ï•g´(µDàéí¸qŞ“…,b*œİ\j/|ÚŠ?Oé´?=¹{¸ı5nÒ”Î=ãK« Q°§Ö…ö
6ÒŸ¹ù;V‘ã6ååZ7$¿+‚¼ÀÕÿ‘º|ÅÉiÑÚ£tPxáƒé1MÖN ‹;”avÓÂ>È=Ö³"µ(L›Ó4p‰÷WÚd¥ğ)«\D’s´‡ù¼Çİ Ş‰’¥Iw® [¡ƒœé_—Àp¯ÈÅ´W®$YS”˜¶r~ëÁÌ®„î¡&•:D[\so(m”ìÊ¢Vñ‘¹ô*w€‰‹“X®R9‹Ÿ]|ég/³?¬•¯‚Y(¸5 &pÓØâìc+‰îÈ@oŞ»JĞVîŒˆÆŞ%€k¶[McJÄ»Şa]ÅqU}5ŞÙ\¾î8ÔW›Ã¢­˜lèÀ^~%  _Lyü#ÇÌšÖ!>?eóo!!È,÷¸üs3ğ™©N¾šJÌÓ
ñC²¼¥Æ¶ö<G]¾÷ò6­$eI¯F#€ÍÏÊ@¿ËwÍMôóÙ	`Íkúäµ|%ßª+ƒó˜ç”±Ñî:Š±°1.]÷½c{Í…³]s>«›ËNí+¦OzpvŒÊ8´{P›$|"<~¼ŠAC¾Cà+÷rı.0äK›*ÖxèEyõ%ûû5ÿ—zßô+HyÃƒ™{mà£yœµ\Ô£ŞÄ«•;ñçç Èæ 3›XÀ[
²‡7ı"‰ç«ëá?”çÕ/Æb\·rÄ‘}Yë‘?¦z	•7qõ~@—Œ* B¶Â‚Cx£cwÂò†#öCUSîYP\Û@…Ze9i¿™HÃµ{šØø± ×ô3Êa^*Y ç¤ÇOê*kT" §»©­Õ²R;@Ëô<BÑ¯½oÜÅ¿'PB\R®%%mªgÒXF¢ºX±û‰§rÏ5êŞ"Wé¢§˜¬ùÖèÍÙ=r—{²<³IáH`aĞ»á¸§5‚¢Ë @‰ïË8B¶"b_¼=)ëO'5¬&õ™/)œy'Léhåñİ˜“U·m#°y3/dJOìzØwaëŞÌÄ1æyVÌ;S403ı ùÀ˜‹—·¸À×û’ZÔê!t,®š<:mèŸŸgc°º9=' S&^ ¤¹ĞOB\®Xù…}¥êúİ6Ó*ç±Ğz4*;Æ‡_W/îJ¾0O@?BÉ¦jX#û}Ç²ZHM2çß¥Eàb®İ»‰5.[ÃŸŠ÷"CĞ¿Ã™ì»z‚yVmı|[„;¯ôK&/M°¥ü:·™l˜(B-û<&¯	›0Æ#Ù ¤µe-&
–|\`Û	z!ÀÏOlİí/]k'-C¬tC)ÏªqzˆÕS­{QAwĞ#È6ÔKù3>8Û-}é×£°Re†ƒÊ8ˆŒ]K1£S“!ßèÅù²e]>B(•!„:`K B’2µ+©$v§T+e‚˜ê½Ûş¾Ï[Wäû¦ã'>j,ô÷™
8í¾|,–#\j±œ‹VuRleqÒmW1ïuN4´m(¸q™;‘£§nŠéÌ2çåô{Àœó:u`”ÚœTªeı£]Z€Ó×èßuTéí|ïßYu Ÿ¸µ*Ä– -—¢_Ë%¿·¥oeö–"Óœ~J§‹¢lt„ÅØ™É¦¯o&²H|.Nò.5úI_…u#Ì»XWq1z‹­‰õsåšô
î¤–!f’¢Œ!Mì•fŠ¢ùM•“en`|é¬væ‰Kï§(]{âÍ¡}	¢Éb®r2»…%˜Îàw¿á¨’cë•.²M~W®Â'¬|GŸgç£ºÓk?øœ¥0HéSeµ™MÖŸ½+½#¸I;ş'”ÂÑ†@ ÏåWdò² G„Ï0œ©ZK—S·ÎÁòyï¾æ&:éjÓ ¼=
&ó(l¼¯´Æ ¿Oã!¢2Æa±Á*n‰ÎøJğŞ²e¿\ŠwFMDõVõ5) qáŠszÚséµÓÒÊ¸˜B•İ>
È¹õÜÒÈF…¦¼¾Ü¼÷óãŸÁ^‡©°7ş´É.ù×ˆ´{Nô*yG.B¤ıp_¡a Øè,Ä(©ÃÉ¶ll‘Éóó³Ÿ&,Há«ÏT˜É¨”4!Ñ'ZîírÄÁ­EmGğˆ-L á€	„É¥‚97ç ïÏŒ%!ç€÷Ù7F<PÏö¿~¦¢¬¯Y}01/Nd	§”	O$õÛjc
U9sÎÏ¸±Gœø¢‹®>nrt1·İ]<Û\ùô.DËİ>í°í8ıİË#çëÀªg‘Û%èpyRšCa(ö%õ»P-ÌR(é?¯÷`Ùu,Ó1Â(àŞ–qçC@Yd¶s×¼ĞşÜšA%Á+Vğ¬ÚJx¨±˜©Õ!#CãÄ(&­¯”YI®yÑ9× ÉAËAªÈ‘•úHgú½yì‡6ÑV6R$¹ú%-Â÷-Xsy"#ÔZ†;TÌ6¦99DrÉ!¼ŞŞÄäø]	)å²ï¿Â°¸y"¬#÷‰,ÇGw„®-„pm¡äGŞˆÕ:İúş*ĞPŠ%È,èú“„	h4ƒ(V‹mK¢;‰Gƒ|Öççœb1jT†ÕéÂgkŠ¨Gvâ®Dğ{áXV^¤oÀÕÚµWÂ–¦J©¢…A®Ãû<¬dÛÁÑR'AR(X‹`s9À[±ú0ÃQI
ŒÒ•ë á“åHaá„UÆärr¸ÖÛ‘š¾Ô]Ä(!XUbº”W	”®ª]umRh‚ˆÛ"=±U¡¢°^wDôgÄA<×^ÔÑ°Ìš™İŠ Aw.=Ï‹°ÚSÄ«kıø ËMÑô„šš@yÑdD Í½ÕŸl£sïÎPƒSæ‡ |™£VyÙî0ê´‹$çİ¡ÙQÙ'Køî1MƒúédØZ
nX™âg-ú
Ï4šÑT—#8¯6t~$ÕX¨¯üşÑ/«sp,K}F=ƒ!ÿŞ%¡gãb2{>¦7å)ÕÅ9åÜvò«lÂ%7L/èŒfşƒ§Õ¸¡Ë“.X[MåÅeÕd$wÂ Ğ>B˜İØpîÁh¿"¡‘ç¤¼µÑöÉØáğ"]†Zuø¢b-tË”•W%ô­ç œu÷¼èrÚÅĞÛÔ©Oc+®€‚/n!Ycii¡!yÁ-}ú\!ªµªd¸@”(U9½üFıÕDJ¬Tâ'ÆÊÈ_êÌ¶%åc´¥ôëˆJô  ‹dt9¦ñA×ÍFÒÎ½2‘!œUñl´IÊgzU’*Ú“Õ½(äxh Û6åº€ =pöh9®ËÿµªUéa&®a
X	`7..Å0ø ŠÕfN?Î¹·5ªŞZ ~¦ÃLHĞZxÃš¢*ñÁ2Å¼B¹M<†Üj2rxW Bù¹jlå_>‘ì›h…+£Ú¾PLôcÃ¢lm,Tôæ»¥É¶Z›f#ªeÊ:SB({)Ñ8D‰V¥,ïšÂÑw#÷eÈ$§·]à¹ÿlÿ”˜¼Y +«ê¸Éå£‰]¡şş=;ÙGe÷WÊQ
–jsvÓÀ„ã–4íò;]´P#Ú!ì bHF¼-Éù7ÃĞ$.vFPf÷­8#°$™°~†ƒÁãb)’—j\·7ƒ„ú|Ï˜ƒŸEkdŸ§’J·®8di¬GIí†`Ûï»¬Ä/!ıZ'å½3Ÿiz4ˆã‚>û¼å-Õüğ­ÂÄIíw²¸Â©c¯T™S8ÔhZ1“q56$ò #‘ş¾¹§?ûªØk’*¢¡BÚW×>ï5Qcz‰ä2_«áI]ÍT§}>tØ¦I.ÜÓŠ2¯KÿT¤şV´¡Æİ×TÖB4?¥“f)=ÖjÎ‚«÷–¾:¼d47=ßÔo2z¾	ïÜ˜ç»ÉœÄÊ:æçÖ^ıïÀãœ¡(U!Ú¥:Ú|Œb<.ß¨ø­î‚Ğ¯İÕÔú‹{Œu•ÏL®»½õ r7+˜.Ü/å´šMéíÒëÆòAÿ1
?:Ö—ËîCk_Kk(ç|Ëg6Œ‰,í¦·ñ¼w[…éå\†,:bˆùÃ#¸eã¦»Ç‰Æ<ËªkÙ@Áx®f¸º¢mªKäZw‘m².dÅ 0F€-’JYƒ_ŞõÀ=n0MÆ`/š¸j–+T†%ÃòKgùØÌ•q:gwø~,D‰â(é0â»›b\ã…ÀÃ=£¡$Ÿº&HjiÓ²kÔ~à¿ ü„¬òAxêr[|”‚A³×eòúÆøŞ”?½Ésı+“ç˜ŠÜòÛª@Óe`Á—ìˆ üOr»Er:6‰`bñKÒs!s]wøšP¤gDDÏûæ%…]TÎl(ØMõ7>™8)õTæocdr‚ •Ø,i ü¸2q|Ê*W'qº‹ÂŸ‹§¤¹;Ú‡KE]óõÍUÆÚÉ ÷n=®	JÒàğ¾ŠfÍ7´rSØ-Z–ºq$$—I½Ì%.xÌóˆ&ÔsÿË‹şká¸¡ EV-kèÒ~0[C,B£’÷aPN …*Â†éª}ï;,Óp!Ø›Í–C,üæ„<µÁ¢_”“í­K†€çkh ğç5„ú¨¤bTôTÃ´†ÖdA¹T\'s[8Ä­ÑásğşAègz ¸YTÕC«0í%£\ªê1Ğcš#ó’QtYìïa}ëa7ú§Êié×Vñ^îØ`ÆUÈdûÏÆÂ@‹ì†DÏ¶‚¯‰Uª¹5
MËz9	º¹,â²k@úñ÷Æ}„Yöc¶5îÉĞ\;€Ø¿LÊı„ˆ`Ú}>œÙøl'óâ¡@šO•
³©BÃ(Ôl şmæûa0^×‡)~iÜ,_)÷‚([Õ}‘µ#æ¨œ¼Ûé`Ë=¿©×/Ù´S5c¢[pÍ;ùè˜îÍƒ™ÖêãRuÈqMáè*Úhk£+¬Ìëâ–~¢£gÍ­[u°yâ³?MÕ­$DG Ş³o®–ÔõwFO‚´q6}³ÕŞ¢ä±QúÁì©M±~Ê`nı½WêÍ‰@ïÈìödS×sôk/ŸKÑGs±MrL0ï†L,ÒÒL¤ğì¨«†Î™o±öuuSÃÏµÀ‘EŒòñWØÙù/a‡\A3£ÖR˜ORÎö`2§ŠàÙ„½[¼›îE`°®š?ò‰;ÌçyBÒğ£íˆª½´,ğ¸;¯5¸ÕJa2_ÖéàM\$@1ÅÆ{YÂæø1/ñAQFŸÎ'ôğ6ú3éÒ„Kíİ¡ÔÖbı£ µ3ë@ËÈ<âT‘<Ô%“ğ ì_É¿÷®0®•’o][0’Œs´E?q½ÒB³éd~æRAêVAàTùö‘‰§íÖç<5àñ¬hx!-¢sÑ”©ğCĞUaêÚÿi¶Ê9%Nì†<¨¡~e?­Ò†'×¼T•'˜G÷†Éh(qQ#õ&å³ÀÅR‚¦ dêJşcÒLL‹e|ùáÅIÇeÉWÊ‹â5[_«H&w½òvz„K%"O7=—:ÿFÜ'_Dş‹î@=´#Ç»%ŸÈµÔê¶p*J¹¬²ªÂCÛPm‡\ô‹æ$"è5«+ıNk'3½‚ÙŞ@D~µã56†,úÕ-óü…Œ„. èc1¨XÈM0i?ÈÇ\ú¤>µ¦}n(tÍ± üæ˜·q*ırÛµµ1˜mNÈßµç©¡œ¬i(âšVòÕ—Ú@ıĞàë …íÀdÊä‹sq`ï¬ğQ¡•pf§ûm`…HÎÍÔd%˜2Fwu°sEÅˆ¯¼$~»H}«–(`”	_¿¤QW&B?ÇÚ/ivâ75cÒâ»>”mš{·ô˜û¢úøí{= Û>+Eî|rëÒwú1Ñ‘o”Ó‚gL16>jÊÄš›³ƒ?"¾íå®öîA¢½1Uú^«Ÿ6QfÌpˆâ
é3
—˜z¡vöÿN•§á¦ ªÖZ1e†ê—˜İ£ÈÉÛ%Ä‡¹‰€˜UÖ<éírÜ–]²º>ƒs|óğzÄùF·ËË l¦ÎÔOÈÃ[­=:ŞäÕ3İ£$%ö¸¢v)&¦9™ä¦l3×Ê“˜ò¶Ÿ{õ’ û`¤Z7"ôAË ‹æí"ŸK¶Ç‡bèâhè²µoÏ¬lP¿œ&¦Òùœj‚ zJùEM“a<—¸åaŸw!eşqß&Œ8S9lYÂµP_ÖªBy¯ô/·™µ¥µÏaZk9ˆ¶ñD‡£ÔÂ5¤ifÎ{ÑZešºÁD÷I¸Y
ˆŞõ{In?¨Úš"æ%4
¢jÓT& l­Û«ÙB²-ÏÙœÊ4ípî½¸Ñzx  M’r€Â¼ËÀ­ó\ècwÎÎŠwvGà9exÀÙ?2VÀ\]ŸSàB!ê"†xÅªdï©/ÉÀ1u¬ Ä)DwEGë•§re5›ªÍMä"·ş³M6ĞˆëŞ
Ûrßö„^zbæbQRMV_¼pà›+2@Tp€"³ú½ÕĞyh¾Ù—}÷$~ôşäO¯êË×\¾ûS`b!¤&ËæUœ*—EŸÙ_NL4±¬ÓzºpiÉ İ—0‰èÓQ·ª7¶Ò`¬û­%:0VÉôVò»S9û3'¬ë¼ë¬T:ô²àe) (î› »•øóW„JQf±ßóôæ~LÑ7x!b –ê›¼«Øá¬Ö©„Ié¥‘Èšm°Fô“¦ÍÊkå)"Ó{;(ºÛİ›OúÑƒÈÿÿß¬¢4§†‚=‡jüŸ6·ê•ğ“b¬§ö{÷Ÿx#Ô›3F=X¯×¹­ÔAz±¥¸º }Š…+€°oŸvXÅCÎó˜ëÁ­¯èÏ°î
N–(0—…¡’Eı·y0„˜‹¡üÎİ®wï#Ò&¯u-EÌ_D±ò|B!ÅU¹3‘5¿k™%4­\¢Ï NĞi¼Í4¬ßÆ´ˆ1ºš„!]¥)¨¶Bş2S+·ìVĞ%4Õ‡ÿ;ùcîõÿe±`oUŒÜ¶àcŞéGû$‚iÜgLA¹?y„ÙãÈZnš^¶ëû<J‰¤ê7:©#…Wƒú—È—bï¸½zå4ÜVPĞŸş¯ûË³LÁ]–¨©8ÊænB 3;ÆTöåİäıÊXßlBYÙôBÉ1»t–JŠ¸I¾îúr‰\×¯Q	q¥İœ¥7çXE÷¯póíº‰…õ.Åİ¨¡Q	şÈq£,ïº¨8•E¸Î’tÜİ?ÏY.‹¦£$üÿøv2Å¥Œ.ÇcWÇÜ‹õ€«İ­òÕ)®ØR
°²8ş‚ü#²s®íÕ˜!YÉ²e+QN”h·›Æ? –uôQå‘79~ŠÏ“4÷¯§Øğdê÷êXp›ÍPbAİVEëúÍÖ…üíÅâ?¶½ò1É^ó›üô-Mlôğx±Ë³Æ÷ÁNÅlTÜ*HiĞŸzËòÚŒME®EZ…æÓİû«•Ú…•#Œ‰\İkPßï†üPU«ÿ¬N²£f._ vÚPœšĞQ —’hój˜Õ3¤í‡JI‰ê¾·ÍqQÏ¸ı!~3;o#¾jİ6+HØ•ÇNH•6yÿ_J úyÎH×8Èû÷Ë(»E”µ›B®'í/¢ÔıìïÊ£.ZKr§x‰´™‘g8+;ç­YÈÚ!²¬C
uª¹¼rÔ¡ºfŠï’’Ä_Ÿ–‰=3òiøÄóÅØ· 6^I:?ª_‰˜3f)êæîŒçã|T‘vë—ç¸,Ë§rğ‰Åèk™¬^>u÷úÆ¶Â¸d4Èêíjó‹“Ûœ-Kâ»‹alQ	ã(„"K<ú«qâPkŸŞyMJ`SšºÀj»n’%“RåËV7|›,(8à6f"ùZ®G/20YhW`Ì¡_$#ãv©´M1.Ğ¢¿:“K¾1)ÌXÃŞË¦¬bå;!™ˆ&’cÏw.Ï¬,È/£3pmşóD: Ñş­-4„ÿgèOt³¢Ôâfx{ŞªJñ…‰Áfèî@aÖBwy·6D|„^Ò'=ä Óu[)}Wy±wÚ»C·ÍRjğìÈHş–¾D2bÔV’TÄkÓÇ\f›@6ë|ô\  	mƒ•Äó‹Ù¤]Sş†2%Yyé[Ò"©RÚvjÿ¶œıN~Ì{˜µdx1èä268xjüõÖQ
şZğ6ÕUüØö„N(~Á—‚·¢İ—ÖIŞ"Ã•ú|Ú”×Ï[¢¢(rÎöz”G‚ÖäB5×UWaÿê¨øXŞªiŸ–fŠ+Ê¸8üÓ<èÏ#³¹	FNP„ÛÈÖ2?[|lröbK“c:½ôiå—ùB‰õ˜ İƒ $¡²‘}ŒPÖ·Ì´y?”(®8¤%â(`Àä,¬Õ‚.¸C÷¤²q^!’¶P~:ÿbî©*[Nê&åt¼.`¡òK*M6¤6p¡ÕùEB²ÌeÒØY”Ju%ë­ŒoFÅ{Å<ZsíÂÄò´şøÎ¼ÛRa]‡ é”mÖÉ‰‹ÃÀÆÔ•¤RÏqŞ“á(#ÉV÷ò£Æ¨¬Ş— ° àÚ¯è°)Nô Ùz¡¢~½ç!aÂ¸…v^…eé8ˆ»¯^^9Oƒ\É,bb¯\ÎƒíˆhÄÎÖô*&š‘íÇÒ±¿¹ÌåÍvãƒ·ãü#gAkés‡TS	†µ¹mpõê›0İº7ËÊöë…y` JE6ÑÀ„VåøÃüáØF˜	ğİp>v¡AŸ}J£4ãY9ß›ÒJ‰#_³¢U”bÁÖ×œ{^Êıy²Y­ÊÓâk­/¢ä|O£‡e+‹
ø…,[­·Ä‹Òİ&ÃhÓ¤nCœ¹¦n¢©§;NŸfT»æy¢ç{Üóîà¾A_ PßzäÁÛœWÀ†Ğ õ”õäıâUOKTîŞ–7©ÓT¤¸ $—~÷ºÔ¼AN¢A:³‚Îôë‰º )›µqõ>ñÊªGä èFĞéAÒ¥B{y¼¯ƒ/bre0ë¯Ùådó˜™r²*¸q±¢JàvmË»ÁGNŸ:ÇàŞ©@óCiZ`@±üıšK½XäJk_:t	zí'æ´ÁKÂ†É{3¤3‘üiÚOšòQ¹Ü£Ò¶Ò¯ ‰2‡I_Á[:]BØ·É A¸ka|/?C ê;ÚØ°e§á==ŞˆÇnÑ~«Œß'U¯¨µ¼Õ¤XÆf«h²» ÷&ş£ãW˜²Ğ‡T>@Ê,zÅ–$¸Û¹¦ø‡a@â-‘“•‡mAa×kÉ}²póáS,	½Â“²ù)nÛ.ğRl³&{7V–”p³…°A8KoÄˆ@.•pùNˆÂè=ˆx½ Ì²ú›v•CL½^æ›öıÌÆ9{œÅF4êü=ú4;GÕCÌ„¸wxğ–>Ñî¡rÊ».ú0é³{z.oOóás-{i2£x>.ü é¸önX¼Èy½5ƒ‰š]YcÉºrÑjÛ*WµX§d=ïô½é·Åô¾í¹1Ÿ<nx¹]ÏqÒ°“És_rFe#‹¶Ï;ç’rªÁjå±-å”^ş‘¢OÍøU¾hsçìóÖ 1•œò¬5r~>‰ƒ»o"6¥÷2	±Æ&Sf±·V•Cr< ájö‰ı ÆÎĞ¦±xD¡†¸"C» ¯¾ÃAêÉålc|î+îèC‰h°ñ§¿Ï@ÚÉ4Êˆ–qœô‚WQu‘M$§¾­û)mâ]ãÇ]ïnò–bn™æLØTpaéT¦·Çöc¯Zubø¦åºíö,7ÜnÙ–ëí¶ëÏZÃ²¦jFKòTLÇ§Û{åÙná;ç¨8a™æ’¶¾sjäÜZÚ•»oòBj×Ãnä‰öl2Ù/¶P–™„ôã}Üú=Ÿ$#ó§ÛÙ¯O}2ù“‘öBA¤ãÿ¨B[ıBgÓ°¡NbLçª×‡=©m:ù¸ b;Oü‹Dg}±.Ä*êXŞDÔšX4§¥AªœÄ€´óêê^•§ÎŠß¯í¹#“ ’‘i÷´•è|soçJkşÃ}'Ç±øÙ›ïæˆ’œ@Óâ?Tã0àf”«û0oÔzE0£ğÛ‡Q“'î=l+ÕãäOÆi—xÀëì¢Úp mÜ‘¶İK5‰xşÅ yâK.ÃiäAhŒÜ-@’+8`ûİ}d'‚µF;ÛÕ«ÑGå&·—¬·Uóê«¥Éå¦ã3 {,Ä+ãÄ)qôÆÌ‡œzNÌxöiŞü¦Xñm×GUç:f —!ûiÉ§ÿˆ“BwçyW“oº¶˜·IŠ€¼4¾ø¡µ©›¹¾ÇÑä`Šı?mFÄÌ7­"–Ò{zæy(²åCf‹Üö˜7S!íp¾÷4µ.“ÏÔ4ãËP……é’Ó)EvgZät8Ä±%Àü?€oáz›¦¯^3¢Õ].Ë £ã%55¡i±ÔÚ:Iˆñÿ›åû*‰¦3é–b¦o@éĞşØ¤"İ¾¤´Ì%øÂ‘©LÑŸ¤Õ/xLÃ “kš0rñõ`Nèù\­j›½şæ·4øŞY83±(UõO+¶¹*çÌúßxÿç%ÄÅõüü<góv&[‚Î:ËU·åÅåèaÊ}Æõ¶ª¼Ğ$Êm8g›¯µ›µæÄ§šwqO“ìÿ0±¿5_…¼=Ú»Ó_…˜Ğvic$‰QÀ»mD—¶€™<ÓtS§]®V{nökm7—<4Ï‡Ë
a*¾ƒ>¨±ä‚?án#ß¬»!qxz÷$İ›šÌÏ§)Ç©LÌš+á³» ‚ùïTÊ ë¾í`+U½˜aÙ£âvªow½h®3»’…õ‘9#½Q Eõ¾®+c4=‚ì¯ˆãbéUÜ®óíÆ÷FDZ¾ªÌô£4rã(3DıñõL¿}toØ7ğÏØ…§Ş(èìÒkFÇÅ§ÿŸâGªÿ§Øz@‘½íğÖşÏ4[Û.Wñ:“…à#îÍ£ÆŒ÷¼ØÅ˜ÃØîcÖ'H‡vOéÜ£Š˜ÓéâFš—ˆ¿MkliEë×,Y{—¤À>7>A«ÀmèwfÓÍeC¶ˆÅ¸—ë‘éÅK|íÁòÊ†î}…!.À¶ÖNÑå&	½ÊÓëR§¶o÷¬[å^:aCpÆéE“NòH‡z¼ï tÇ¤ÀCOdYoJ%mlTrlìªNT i²;õÅ¾_˜T ß&F\Ofå0Yœ%ñ†–ù Õ<z4Å„§UÃùş"¼³(2™q‰Ğ7	ƒ™bµê‹Ò¯xFXõÇPš˜±Î×¤ãT9è™v¼à¥Ì2qQ1º£Ù8Fs(HWğê¶0 "=ºÒ—­|±[xÓÿ -è¢&¾aœV»jrTVÂrœ†œµvıİ©ê_QNDP?ı -A9zmÇ\Ösƒ¼ì~ÈÍç¯ìT4ØÈ>‚==Õ\˜©Î-7çˆ{š­â~ÌQé(•|zM*N§Ëƒ¨ô˜vChÔ™¸#ÌkÆf/'\¼ÜqÎ¥¢×S]ÔK~Hí´AÈÄ¾Ã?™ŒÿâwÕtÚ,T„.ooŸ—"“R³…µiûæxAzµ7³-H~Y7lªJæÚ3`¾º”˜çß ¢Y9‚ NX ¢0ZÑãåäÌ‚ùgìºj&³„Ë¹ğ×|SÓÉë˜ámÀ‡ªJfÌ¶r\!”0ºÍò )ò2µÅı"]½:PšªìynE†]qYlÊ•//Ç;m6`èö€¾Â0LãŞ°åÛ“”Š)1£‚©aÆë%)dF#¥3p{œF‡ip®Bc±éIÕE§ë'H†¾Ù ,.°¨šÔ˜ô	-—LhB0º–ÿp.Æâ?;˜lâßç±`8î/İ6ÖL=SJò«_]`sØ8ÑbĞµ2€åv›d$“]náªÂ¾Ú‹‰ M[DjE¿9íQ„¯Ğ4QOÉİ\»fŠ6ıMm†fW`f0±<ôXXêcÌë*MB@xdñˆF£˜LÙ”³×n@Yot—	—ã,ëU—Ôv9UfíEM.Œi üÚ8õ…Î€¸b±¾‹˜ÙÓCäOy_Û¤¥Ÿ°=äv)0Ñ¤y©T?1n½–á.
5'oâw¡Ñì‘©ö-W½‡òd³W¯±‚ŞRç/½vÕ¹+—Az5¾Ñ(ÏÙdèX*ÛóÜ´Õ4GÛÕöÓ0;_&·d<.êjø3I«¦HwÓ[6ŠBA&ªŠˆc÷Á9ßf,DÆš‰_âMG)’X$„€ÊqbÚ´«R_¾îÕò—½ˆÅ QÑ) ö3vÄv«*ºßNWOcœ^±Ô&+C54 stæTzÿ$£9Ä	ıòî´Ù^ QuH 1æ“Æà6Oö!<IäG0²èäI~—6ÚìÛğœtV2_:†‹’Ñÿò+È½yåœ#ò@ı‘8yIı¸ëâ_•6îœ-ihÇÀ«g6uŒ]óÁ1HQ´§Ójî[Òd•Æ¹E+
7JÃÂ“‹šúT„¦¶²÷ùÀµÍ ó*˜D‡#â@[:Q§Ö´K¢X„«cl‰/ÖNyc¡fî·iˆ™¨!†Òa³`é	“?9‡µOQüFlÅ†©;ºY uÛ™I*j]/A	ŸÑ9–U…4Ë$ìÎ¦ÎK‰æÄÕ¼(ˆ§O¸r1¤ªk÷ê–ÚóaÜn‹.IAÅ¼ÛÊYññâU²¡®!!úÓ)rÈş«};ôeóVû™
`:U\.Ópeû&:LƒDª?G=Ñ¿Gò`¿ZF•ı3´Ï—hEÃ¡‡“!¢)úQü#÷so˜CÉ8^ğGB¤şÅ41w´q¹Ñ¡9zÔ·‡)¸¹ç4NAÉñK"øGğ­KÚI\]İLdhÅÅÒMa…{/Ş#Ñ›u-Ö+@ìæ«[B“±ì*Ñlı(ªc«¹r>’+×ifc~ïûŸ¼äÀS!xSÄ+¤òÓ7ƒ	²öäU˜JäÎRŞy¯,_·U Á“Fì÷Ó[Ê÷‚î²é¿÷MaÙõßl™Å”L[>§Î¢†íiÆq‰wÁİ¹y§üknU:nÆÁê ÀÀÍœOÛwDÇ6µı“„P®£ñ(÷ôƒÂí”!Ê¯çòN/áa’ÅYláö¢[t-ó]ÛÙŞÈÁ©I=^Wß(w§â}j"ñ‰Òqüî¤§¢¸*CŞ«“‘§Jü7™§¢Eª%ÎoöEùuMÿ×|Ü·”È"<b<zAéhD
ŞœQ:×­Îğ¯í Â—!¤›A¼„U‰íH–>
Aê˜+ó3µ¶°)â½UÀ–òœ©ÓAh[l„„âèÒGˆ™pó¨Ö2lä«ƒT1Û– •­£4£ä$çtxM?Í(ÂïéÚğ.½}öG»• ì„˜¯¯DÏåç¿º‡Úe
gÂëKÊ@‚…Š¨hòo®’âÂ®,(cæàÅÁÌ–vX×3ÓÄYhø/€7:ãE÷ÍïÚ‹KRTkèFŸvlì-Yâ&5(G¶k"²ù&%Fjêdì!¥iÎÏ5%ğ»Ÿ%Ñ;)be_5µıX”Éiû>õ©;K0ÒĞ‰kåµÑÙ~´ ’‡eu¢æŒ¯v3òÑ¾@ªHˆæ0Hd›«°«ÕXæ”Kn|›†DÆF(º—õŒÂIäÖ0WıúêÁ›SRîÉšfÛg}Áó?½ƒiY´ØÎ¡ÏÁç–™;¿ÚË-5eåãm»âG‚É«ŞLÔDK
¢»¶
Ô<æ§Fµæà:Ì8Ü´U6¯vÑBaI£˜Ò²-J·~‹OO,xs·Ó4lŸB#©ÌÉvæÅ™¸j(@Q4‘ıÓwÕÌæzø_¯İÍ¨ŞNtÛ„;w:NÄ&Í#½î«û2m<ôøÏœ$áf€ltdÔ`NÚ9Àåƒ6‹Ò¾àv ^ÄğW™…ÁÔ®msƒ´€RÑ¾¶6a3Œ?/$Æß<z‹G¨e“Z„ÖîİJ‡M¬>?R°æ-uë}½&9İ „†vNÂ%b]vÉé^m?šŞZWØ@¯¥ù¾Š ¦#IÁøñJäÏBZç®˜xjGÛGO%Çš”º7Øá¢c”«+i½JSs>Ö
ä{Ú™”.4ö±ïÖº„õásÍ[}òŠ2Üy»j®ô£q*v,ºC$%És4[¡©£Õ ËÈØŸ>ê÷îiHœ[M¶—y”6b§wûĞ-°%í”±†QC¼Çü
º _Œ­cÚC°ÚXfÃñ²P…ûÙ?Ì¼Ç[”ûó­üô^Ä æñCƒÛ¢ ÉzDJ^/1Æ6PDüÿ²_ózAÈç?ˆ >Y‚ŠXÔ¥Î^çëˆÛ°85Ñ|¿C¢õ:^.ËP–Ë¯ä~( ù%Õ¼‹hwƒq&ÙÓo‚;1£DöYÂÊß€r#òë8hføgjnÒ²˜ş„»›à¡äE?AGtpÑÖ|­à¢:)Ë.~øğïô,äĞvåağ%”®œÓ"m ó¥óK]JBÅM¢SB_m„ØlWÎ¨ŒñH €ßg)_²pBGpPLX¯$˜/ÉŸQ¬sq‰éìî'|ÌyØØRÔ"^°‚?•èÿª†±í…Ò‰,QAj$cıKíPbV#±A~î´Ê± ø;S.uÕ&Œl¡´$W/—ô?ß³ï (Ä÷®ÇB®ª=Ú±m–v2"-6`kÏù‰9_Å¸`“MîÎ®fÇtTµi3ôQü1?fI¸Qš·*RFŠÂ‚©éûƒ–r„Hg‰7QF”/Ï»kØl˜#'—`G`ØOñƒ¾3¢İ×T­÷Ã@¡Ú&ÿP¤ÃÎ£s÷2CIç"äfF‰~ÃãşõhøÅrj(Mã!ş·ºÄœŸÇwï¦G¹v}HÎ™‚Á¹_CqE©_`˜¸uPµŒÈ.¢°ù²…²ÿC"’5îá!C~÷•›¾‚ •h?ƒ¤^Tigu	‘Äp3Eb’EëUV9LŠ¦­~{tœ~ØÖÆ ØÖŸáZøµb,ŸÉó¯
uÛ8«FxÓ­ÊqËGâŠ­¼à«4(öK-z¦Öi‹ÚŞàÓî8½=×ëÅÙÜï¹ğ™²­oÖ·ìÏø%½
ÍòkWŠ²û/Å½RúQ¥\Ù<À–œ4»z^€Ô„eÂŠŸ¬k®.øMâïj.l^;[’i[²è‡˜—léa~(l!zŞ“ÙEïL—Ò×7-«m	sÑoûÏÇ˜Ãv‰;µÎ?í¨Ù\©İãbµ£øæÔ¾Ñö&W#«zı¦’Í—Ì*Vt¨÷ù†€<ÁóI¯t1D.‰…Ó“ôá¶âÍbÄuò&q©>î«½c+vPÄù›±–œó¼t>=Æ´YÍç	 ¤ÎÀ¸jëğ.TÈ€F¤¤pİ¢¦¥bu®¤GpÎ‘ÿk]aPÚ{(J]Ÿ‹.
å,Ğ…­ˆ®P;@9B„_äšR÷ô“Íáé4-òœ.}´~“wâ[·?:ü,]JIìh+|Û½µUzæ¡¦hÔ¡Ëõ“Ñ"‹’™¬CÄl	°l©À‰µS´äöÙğ¸ö;9×…e	VÊ4+8·œ­DRù2HFÎ9¡kŸcÓ+\ë)6®[º™<õ×õÙô0:³ÿy›wz‡„^Ä×”€-š¾É_x¶rcìU
[W~=sæ«ítùß^ŒÓ“ğoJå_xæ&t¨ç¿¿¸·AtÙ“_ÃÖş—§C4gÈ8†kn{s„_•Õ,ó7IşâÑš—¿ÒºğÍ¿LÔ§c¼àA2B7:ë.Ÿ—®,¤WŒówKøì”³Ì¹5mÔõå[Ê=Ùã t_ìMÕ2§j™akçË¾¡hÕÎ„I„ïşš8»7§I}{‡ÿ±Kõ'sl÷Œî4 ¯P“Æü¾Ì‚şï‰EÁôWã::]%Ê]WSƒÅ1#i&Ò÷¶€-
ß-ËÂ­ápéLşğİè~W3H/Ò›rÖk/gAÒ÷Z}˜«·’[¸ëj {S¦@›cï5Ö ã]Fšãiúæü'¶àƒÓGüF1T¼¶Á:_˜¿8ú¤±V<¯W·¢ûojéK´U)ã)ÒØÏÏä?—ŒÅfä°r¢a—äû˜ET|Â‘ˆ ³[“ëŠÆõóëh“_£RîV¼•M*Ë¦5c·MÊÅS).ë»Íeõı§iíè"K•2fŒzN¯Û—ø:ã·LNÊq<“£—ïé®¨îláÈœÈÜ¼Ú™Âò¡¶¹‡›‚>k‘®1	¡Çş,OKu:¾ı!È{e‚sÙÒşaÿ‡–8ƒğJ~íwc§Ù´–z~|[#~DPâ+vÖ<jÍE%Zn„(-èg~ .…õm£!±Ã'÷ò„¹Ä`Qî¥J$ÃN ’>RøŞtÌ«bç‹æ¤DšÁeG¹ÁeÒäh(“·İŠ(ù¾ŞÙ*è£SKëhüõå	Êßı#Í!-E?Ñ,	X¿Õ'[~üªÛYºtVK¬Î†YX½u+¦<3Ú³í\ÔN.»cù®È—Àbûw„:ú|T\ñ':Ÿ‚QŒëÛ°U·‘$)Ç j‚ÃjÑ]ÏÖt^¸›_ T³ ƒéïsnìR,»?mJÖä%Z¹†ZìH•[¸è2ßéZ¬ãu;¢Å¸~$ôìõš˜\Ï¥k²VpaïYüC…>J¹¬æß±*F¨ÙN¹ïÔÍ¹<—SÉ¶ÅM×·,]³bdcH"*ó„ïÔÊA»MÍğõ0òİ’)º¾ÊÈ
zB0ßÀ\uºïïøµsİlúŸˆÖt¯1ı?N02ù”Æ#j28oü7†åšhc?[LpI	ˆ…l¤ìĞíDõùØá4”¤¯@Æ˜ÏœK7–p=w5@Nÿ$=Ù"é€ÉüîGĞİÅ‚©SK)óõIôkÊ¼ @tGl¾9Ú2Yú<‚­R¥Ç·¥Áß±½ò\h#í@Øj?Ú½×ì˜4F `s
'SÖöãz›Œ@ˆ*è H–(h	ÔÅÜÚ„±æS N%¼Ê¨ÄÑì·‹p¦(á¤3úö|=¶ş;Ÿ0->Ù|uøDØÒy%Î÷˜°Ò?_…TN«EÏ_ı}{Hqù·4F¤šAnæ$Ã‰š¶Í-ñXfxxµ3[&Tt8bKâ®ãe‘GâvıÂàaW”ù_Şõºã/‚’ÁFÌÉ&ëæ…÷x¼×<æ@3ÊÜ[¥y\9ŞXs/Hãs))ù#ªˆ;J^NÕÙïk¹pGÙ2bSÛO‡gt¿µÇ¨ğ‡èC;Wú¡i%ví”>™_©,àúÁ¢ŠºZ¨)¼:ç‰ÇÌëÉ$%±>2´Æ¥«‡‚¾„ø(„™B—o°JD:oaËƒÔgÒIÌ5’Ã!›h^¢{y²ï 3C7£Ì3>“$GPjFJİ“Dç<Y­ø)ààÉ®U{Ç•9bøp+aä8¯`lí–%v0v¸Uùò—u;
ÿç^.iH	Æ	2(9Z6ô‘–¸'ŒœªÁn¡Y(ùë==è¸áO(ÇÔg–=fÿGÃM'si”¼LV¶±í#ÓB_ëÂ6{QûWrCZ‡CC”\—ZûI¹>e¨?ºúòAs¯Iñœì®7Ê¬û|…Yóçb jC	»À„$7şÄó$mF]òı:Ê•;ZõÄİZ¬‰ÍBÏ¢wMGkŞ à¼Oš°Y¿ÍB¸‰šÀhq®lw‘Ô+²–'ÔÖîmâäëñ\è<TÜs7<hOßMZĞ hå#P f?ª:³šv¶Ó—IVÊ³uk1º"Ï`¹(ÛÈVtû)X6"¢JƒíŠu„ä`5¶°*ã°+5æ­¾\{ÉŸ€“Y+v¦ÅÛ½x‹Ê¼şK\Õ¤‡$,…:ñf‡ÔbPå÷F¦”Ub¸bÒflº=7ã(9E˜q;sÏe"d¸qûö\äd‚ü„iÇ_W¾MàwJIyÂd‹,lm¬†j¥{GƒhChgûEqı¬Û2S½”ˆ®E0à}­Ô~A¾;õ$@$ÅjÛË&…*3éÁ«ï-ÃU|óq#F_1ëé3»ã£)Î®œdxˆŸŒˆœGå<[Hsër!Y`¥€9üq—•uÃÑ&£ŒÔòZ•ËÑfTpwä;eÚùp¦Æ‡.ã¨,¸UfMwA˜˜(Ÿm(ÒGÌU­#£AR¤İò)2=5ù t¤æåæƒE­äœly.ÌwíöEK ±ú­}2Mà~‚`},š¸ßú¢ÖŸ”¬fÌêë¸!%"ÖÌTÔíNÖßŒT©!UKKó‘@bÌßÇ¿Ò¥=NpÓ¢ä­é"Œy¹Ã<øÂ¾´İ:Lu,#+Ãlã%/`ç¿i{î¡ %µóZ§Ğ¢DÒi\YH€àHĞY¢ÕJ¨Ç§íğeƒ"=1Ş„ğg–W<{<¼é*q@>CEûUY=
dÎß0BÚîo†<×%Ú	„VT7¡¥C Ôş™HhÙr5RdşS{}wÓ£´¦‰å`¬r÷Èl»ˆéÒó[€x".¨€×üo< Œ­æP¬ '“¢N?˜‘@öú¨$‚¹X-*AòücET@ó¬eáM"à9Fs`VÌÔ=xİúm…Ò›ƒ:‹ˆº®{jºÛhvDÜæÌçœ“6×mè¯ähÎq¢J­¾(‚$Û/¦‘[Ü ˜i@Ÿ—<¬ĞCÌš¢®Ã#[@¬dñŒWTÉÖòŸÓ
u'=9úRš°mğIÖïğºÒÓ|y^ÀM<uÃ†Ÿ¨VàfT
@Z C¢¢)·ñH£`âº¿c(–Uü)^_q&Y¼	ŞÖŒŒğÉ“gqÌ¥ã"SãÀ"íTzÙqqÜ4Şbsîõ#=¸Më+%DI|¦ïÆsšj!:×!ÖOÄ›xÃ?KH–õÿÉ|[r%ÜÆËnñ {~‚…õ“İT	)‹›¼NÒß@»a¬’ÛËmÕX‰éŸ†eÍå·Ì ÁŒÉ¹¡GÄ]ìq]Ş©!(g
Zƒßn s†·…‚4œƒc>Ò!3ãGîò%Fv©â¶îşJ¸"ˆ±ø0·Ú8¬°²¦P´3îßUO’6×ÕÉTŸIáMC8²ìñúNÁ¨$ºiÔ]€Â¥™kLO!‡:À¾üÑc—ŠàHh´ÏC×İÔ'¿>s»Ş¬-Š	óOÃuÆÇâbÍÌlêıÙT-êUr­JÉ_8aPäá'.q]sôT=ùC“½+¿Ã¬)‹†±b„ş¿ëú{ÍÏCE–z÷ĞtÃJ[ 9IÚ n™ÒÀ"²PŒK_IIz©Úœjú|¼r·G±+Ò·œOÛçéÆŠÎš¤áÍßfæ×¾){šÊ¢Ÿ™Ëñ áµúX¿.»nÖü›†òsBŠã¥zãU®<Úá˜
Ì	%ONRÔ@TÁ5J“ÒM°¦«tjñ5&OÀKåİ¨‡œhv†Sß '”RÚÃ]HÌÍÔâIêå¢Ëtäîè§ey“•C`ã$_ÄÙîñõÀ™	;_?j…î…ÁşÕ²ºßU£ƒ'ŸòyÏ^~$_Ç"úR‹ŠÀÌwİ>Î¸+T`AW¶ñÇ»É\UßCAB7×c”?@¯Ğ)*Æ¾ öEâù±ÿ÷
kë~Ôõw.üò˜9(Gˆ¤%—¡ÌWs7ÜŒµÈXã @¼†	Z@ß'ãë¦4tÑö‡óQ§‹¿ô:Å7ëÉ<PÅ¶»ïÅÙ£FæñÁ DK×dnySâÍœq—ğR”ÓtN›g°mÚ»xÆv€öö¶+­Dï×¢	aYºÓcl.”+R¢N£Ÿ÷`a–µ|«œ«V=Sîm¡c¬#CvsRÆı2À£'kúo÷0?íÒ®Ëío©¦ù,õô–q}IÕyŠõ>Ÿ›ñõÉqÊubæhL†R]od”`Òm L»æköá±pßGWH¡6m(&-õ†UÑ@ñ7fÆ%8W¾}˜Ã. 
íqoïõ¸ğáË[±µiµ„B³çV3ÂHÖæ)Ñ©šùÛ2"¤¯¯“´$•)å«Vf>öÔîÕØB)šŸaXzä=N Æ•/ÁY‡VY¸Êºw…û«w&?‹ËÂO‹6CNŸõM¥‘ŸT´7ó	
k¼ÙÍŒSgOíœ?£ÓZo–ã[µ	‚/ ='D¶¬öxjÿ„×¶9–û}Şh¸P¡È‰¾0¾ïqî'›C‹®9j_&•v—Ó(¶4:®\®(!hÌæ»şÌyÎG¶Y³§`Î¡ZX’j›NGŸQ±3¢@=$øb"¦Ë°Œ¥€OÃYÈæ05É©v®¯ı:¾Ô, ¯ëÿD~A'°U’1Í'mÌùfÑÉ3Y±‰toŒ`ÖÛêu°Ü5ÚØ.qÌ¿·ã¡È:Íô¢>¼ö
“xTÚn¬¹ıØ`¯_ÏRµ\‡ª ‹¸,gJjµ:`İĞÄ™µ·Óp)¡¾¨rKiÑFå
	/Q°"k¼U*f¸c;4‘İ…
mÕ‘=»è†d¡zë8AŞîEeİµƒˆ²ÊÙ~6[.~æ{ZºZücH¢U<Ñ.ÔSÚáÖ”c!ìœ²‰lœÇüM¾ğP°ÒÒÈPfø…øÄñ—µ{Øx„›IŞïÕ%»ŞX½ÜûÖ†˜‚8–°2£ÀõÉßª+õ³¾y%’F(µu˜=˜w¸5ì*x
DƒŞÑs÷d­ûö—A©ÅÓ»…B 2âéo=Ûw¼ïµPªòCDš‚´haØ€Î¿£äşÈıèH:¾0A&,_;ƒ ]•ƒ!™¤“ûbZ~§d­}¹'K¶¬¤LV®ùŒA,k÷³Ïÿ¶¾[)­ÔÊ]ÊÏì!\Î–4÷xR‹JÏdå#Oé±iÜt› µŸHØB®ÃÏãQJšQA\b¹¢)™LÁ°:B‰C¦ºº˜;Õõ­W‚°p8	¾rÂã÷³aö*a!’>3i)¬î=—#x²ÓÊ%yˆ‚•GèfIS²ŠÛºƒëëÎn†ŒeK,<í††á±6ìÏ4Ö{M\{8MT}q«+àõ¦='ÖSWÖ¿×ğç§µÕ5càÛ'¼_¼°"{şVˆ…-z&i&Õ‰Á©ñœş×#Fı-€ˆRVB†IªH*¬-
ÿ´.
§Ü"z½	Š`ŸP3'ŞnˆÚ}ü¸h&·NÀ+£X‘÷q¿ˆÕ-e¨"ibZVŒ˜ÊQó1ñ P7—“eö9'ñ¯gÇ±¦ƒK·ñ^—í-Uş×_¢·=ô›ş©äÓ††1±³ı'«Cöw¬˜‹Ëss=ÑV†;ƒ„·A–¿°QÛ£Ob8Äå·„x¿½%}#+±M:Äs£MªkÔâËNÔ}ÂJwË”’øµåaš}!bR­âºylã,ñŞBWJå-&zuèğËx˜¦b¢¨pš©<ÉÒ•ìšˆÔ¸]1kƒ.-ªšÏ	è²WX°r1†V1AŸ¬¢ìğ¦Ø–“µ‡X¦ù\‡4°:¼²QöM£«Aµ{zTÃş’ĞácØp¡;–´gxó­[Ó=ÇÖãÉìñZ`ë©–^†c`øŠÅ¨€x)3{‚î=%áá`ç8ûQ	«Ã»=ûDp‰øNi®rç>v†“D÷úXıƒä>jŠ;–½Îb?‚QöhvÍúÂº
€‹º|ãr¾ºÆ~Š4Ô6–½~oÁ,,*ú]jqÕpNÁæEAğdt¿ÿVJöëàQV#ĞØô®'æø²~ŞÆƒî—Â ÍãhY…’‰é5|¼b6Håº¾¿„;›ô=råš0Ñd:°:j^Ñ8F‡9&š%ß~¯+>a÷«V?Û¬T’<ÛÕ¹,Ö«âbv½³ Øtø3S#NÏ.nxë­Cwc’+ÿ	/%{H•É³="áŠÄAàmJYobÒª!b­àW³¡%ı‚ßKÖÅÛTÿû]ëbIO`-¢~aö†IFcó`¶~ãÈ‰šñAêç×!¼vI¾óÆZú0BæÃC; ”½îú«ı¦Dò¾n±ò´À¨Ähz£ıxí± ÛVã¸ ğ8*ôLÁæl?ôkµ,Yàwj×…S—ºypùÎí¶œåúµ0‡öÚĞ hU¡*_sê½PNğ§
¡o±½«˜qCk7— 0v½“!­GUÚ.¥CşŞ%¢¾®Ò™b5>KG5&QûäTŸ@´ş¸Ğ¨5Îî’ŠøÙ]åjrL»¶€Ÿıb0@„bç¶Ãªp.}Áçï,«ª&’_LŸ.ÂŒşÁ­tºå.x0•Şsi¡0Œ˜‘“ÿğŸÅ†3ı9B}9â3Õ­Ã£ØÙ)NgàTÊ~aÂI.jĞ‚¿ÂšÕ•¤dîc·,0}-;ö«<
ıt!+æ6Ç43ÓE:bì¶5Ë}Ì"§êË4İõ4Än€ñXIÍ×Ø§î1Ëì$½ıêÒÚ:‰'KQÙ%Ùş$Ó—¾$|¼v‰1$®ûª[lRø§“ª+6|*¹~:@ö4må@øëTå'=d&É‹-ú9ò/²Š›•Áæ¹¼Îµu+D‚ÕócÕ%½Î‹ŠL›IÌŒ‘«G-°ÙWÿ&ã%¹~T½aTQ¬ÖÈÆ; ×ñ,Ø è£şÃ#gÀ†(=†5’éL¬¹..“ö„Ôth:µ(]¡Ó½pª!ö«ÏÜëoĞVq&^× fË    ‹?‚©Şì÷> …²€ğ¯2yC±Ägû    YZ