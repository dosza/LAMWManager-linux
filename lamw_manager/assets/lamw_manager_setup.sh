#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3372042087"
MD5="e27ba46425308da0c253d5ae81c9ddba"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23332"
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
	echo Date of packaging: Wed Jul 28 04:21:30 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿZâ] ¼}•À1Dd]‡Á›PætİD÷¹÷C]FVK‰ëïy¡e~2_ØzÌuVQJ‹×‘Ñà	W=)Êş™¤·Ñít!ÑÿÕ=šÿU¨–U¥ÃtĞ")õf!ÿCÏVZI­vˆRBŸF“?¯g˜õ¿(¼1Ë§á6N ¯6ª$I¡877óÿmœükàÃl3M*8<ßäÍÇIWqö£¢)n¬jÄ”y¦²¬2>f7@[»VÊğ%f¥ÏÅµ¾v^?ûä˜îÿî2æˆÌ…Ù¨¼=1­ÙôÍŒcÛ(?Š¢e»Öì²d	Õ¹uªb;º6»qÔåpU2G€€Y+¾Wî%÷³é/7%uŸdú+L`÷hvç«4©õÇëû÷2Şˆûæ¼ò(1yÏ]&õÂ´^êâ,‚*·B+Fk«Ñ/Lı]ºôH|T/;ŒÛë©µyM5ÆwP"}š_ÄmÁŠòÃÈª§Î‚=ç¿œ7*«péŞ8;nŸ;ùÒ/8B€k1Xkògq4ñ…5H£•qèÂüf‚rF¬	>®vzı{´ìöIşü%şê“_™4M Â—‰¨û9¦Æ˜t_ÉêµÎó†ME™\7zºËHµ+&İ°üÂä²Ú¤Ú(¢Qœb€¡¬!1M‡-!2­€>¤*‡¿²Ó•_DÀÇâ1¿ßit¼*&­©2Oİîá ÔQKÆı×|ÚM. İÛÎ°î×s!Õh^"9ì÷“¡ázCx&Ã÷bÏ3HpPìÌGS«3«#M®,÷û,Q×)RØ~ÇC–=ÜtÅ)«ßıá/yÅt‰æs± ¢¤ß%ÔŸå81À@X8]>²«BEgg×à ¯%ÕZáV€°à)”ëñÿ–>1ÑÂéè:›¸zäºdLü·}]‚¬³£b¤GÙp	.¯`±#Şˆ(wÔnøµ?EikÑfä-lÈ B}íì‚Q‚œ£îJ+óû"°=íxáßñcÏ9ôçâÉE¶øÛ®›º~õÿ0ÔìbùzÖX¼å¦d×È»õçmc;†."O&ú™jÛ™{”¦joŞãÁjÁ®oHşV]§—o³lP~K¶ãO^YGîÖa˜dıÀnàI¡¤Ş4Y»FE&åœ˜.éÙa•3Ô¼#×º]•]»Àx5@¢x€¾‹‰ğiW¢BN®nÍl¢P–İ;C+'S®¿ºJ†(Öw6>c&ûVñ7ºÖÎ¤[øêéFİñ=Ğ©ÅÏÍ¥ÌÔIëGè¯—9‰Œ÷Ş,øwLÏ\evÊ2æŒ=¤8L;Ùqï§n%â‰yÓÒPàlöz‰~+‰ôiûOŞUI¢6¤ç3¼9Ò1áÌP~5–ãgï',.ö¥J¥­ğ~Îÿ‰Ş£Šm> FÑ²Ñ”­'æŒ&˜ÌçPgh@QöÙ×mEµRzM0Y¯[Á3¨–=k OÑ ²8€wLæ€Uì¤ğÈ%â)­Ô@Û0ehåâM_R©e†skæ¡×è®ow~Iuq•H† üô›dÃˆ¶""1hé×Vßš¯8^%*$;-V~áa’"D£Ì2hƒ[­1rö˜ù@	)O²÷Ë’¶ÈÁÃÄMRE¹ÿõ|®ÙíyÁ™o÷¦·¯1))¤¢DÅq¡bˆÜ±â[›©*EÌÛ£YRwÃXŒ–ïËÅ·õKù<]ŒÔ
)¸¬öK¸Îú l€ÔÍ‘Ê‚ZFøŠÔıìŠÍlÎ<Õ5[íu´>ëÆ*J:E[»Ñ£¡]í+ùzŒ…æÁbÊ/W‰Ñ¤»GDª*r›2~†„x;úò£ißƒe®ífÎWn»]Nq½şØh'ñÉDª¦~glÄ{^åíÕTn:Jº%ãdØ0€8 ¬é¸İmºÿˆD€ĞlêšıL
¶LÓi-‹îıÌáU~© Ÿé*Xì+!‘ì%kp
FŸ(÷;í&?¥;¡¤ßqÄ
Eì‡y1ªyg?Ô3I%*G½)öK‡òôÖ
=¯ÊÔA{'åŠ@`L—0zóëĞÊ.¢¦Â1zGïXºñİá?^r$Œ!.67•º:–@[(ì
t„ë¾àª>6dV]P¥@(÷BŠÙ~!Ã½…¥˜Ÿä)Åî…†	ø:ï1ÈîåZæüÅ`Œgx»ğ°Fğ0¦Dy†çö¹¬çi÷ï¼
°7Cf“òÌ
üq8™¥ÿ~Iè“5OqäEÆÁÑDê÷o>,0Ó$Y}$àz©¯™`U®ıÆDÿÆÅÏÇše§˜ÜT%ùôHù.Y˜·öú®=MÎ$Ï×ö—jáğÈ”Án0A|ïo±®²Ÿ¨¸‘¨íP³m×;ş€-BRåŞQóÅöEúhi5‰³—ªL“òvT©>ösÛh¼¯llJƒ–:Iñ›-…Öˆ%H¿YîiÃvr3_ò˜_Oû0Ø½½yş§'p”ie.˜¿×©««…ZJªX<<ˆriŒ€áÛ“Xä †æQ=ı€?0?2xelİ"³j§1D)¶	>o@[2CÛ"F¤¢Û‚ƒ&¢’.’ªICL×@¥]ÌƒÁê- ”@Îˆ,Kr ŸŞ_—a¨	ñN·ÜŠK.›¾( <oş;ES]ùZ9!„íÛàXvÏHÿ®mì‚‹:p›åø7bÖ†ğ7 ~¥%òˆ-Ìùz& ]„f'‡–”ÃÕœ8}á·ìÜÙ©è«@¿’¹ÑZÀV5¤7~ç`¡óPÁDD×pãËêx-ø@6=[éx=	ë±8º˜uŞ}U`2NÉ]aÕ|êS 3»}4åÔñ{è9%Îiêi‘2ûNC‹ É`zÏZ®êuìúÙ¡ß60á f%R[¯A×‚›ÊhÂ‹'x’9Ú*
@¿œÃ
F¥Q#A±N[|òbıüö€\ãˆåZJı:_í\è
Ÿ[*nd@†ùîñMNêÏW`jÓ	\´‚¿+òQöjxŞåŸ¤Ã€Æ“ÜoĞƒ8Ì‰£)â\=·ıÒ¸p å7i€š•9œÄâ(;ØëKÅ{rğT%^Ş5]²Z¦Ha’Ÿ!ÁbD\ÃÇşŞ]ü''Æ›à\_œÎjFW3¬>W;Â¯×81È)Ïım³Pı—ı»íÓPd-^gó` ˜8I¢E“š¨T´dvYÜd$µÕ:²×=)/·¶&ÜQYÀ8ÍS	×Êt`òzW(ÜÑšX4dÁ—~VØï*q&÷x¡B
¹µ‚\–şİÚŒ	…üÏõ®ö1º?¸ëö|­)â½i> j¤N¯É¥¾R0‹1Ş¤°R—T†µHË·IšOLI¸=YmğZ_™ë¢ûĞû3°İ’xZøââ}!rë×®¹4²èCœğş²‚µNà¹é+ú2%&Yg×	"_»æ,(C¥›à
­E~¾éqĞ”ŠÃÅZ=ØÏgÍm£fÙ'é­ ¬{ü›¿îš‹!üĞ=R,VóÑC0u™Ä›µíÂ«`],Ğ’D„a»>z¼¡RfŸ¢&uõü¦ ƒ#Çbô‘ËàÛÎ£W·÷&×ºŒ»d«Á°ÂÆY.p8Ğ”›ál“P‘IC3ÑÓd U_?à'ñğà¿`}šà:¥Ê±¯ØFğğ/Ú»l1ç5”­ÏÙT£=:¤_{™¢v™‰™£^ôÏ›Ø¼BZ1‡D%BÁßwƒ
–iİï=pìë‹lÉ&YE9\ae|%c›ˆÈ¨,<êyu)´ÛwûŠ›Ç‹Ö¼¤šÙİMñ¹õå&›¬R7>nÄ«ıÑG¥ˆ_«lg›üåá&ƒ®ğÄ½«˜q÷ïTøE ”¾j¿óDÈğ;_àò ê•“Khu,ê?A4Y¡Èå‘Z°áù*Ş¿«	ş«¤é¬@´Û’CI¥íÏÀ4S!‹±ŒOù—„˜T¤,Æ°•Ü`¥È“ävÁÂŠ“’DkÒªo 7[rR­çÃ˜yİ”jfoJ|i{hp¼MHÆ¬	ü53#ßÄ§}z¾"¤øıŠöÒÀ€êcÄ¤$®b 5²_ºœÌ¼ës:z*¨˜‹÷!¸«Åà!ãH´nÀ8“Oœî¾Ì·üìdøı9c"`5‰!(iQã}5¢]ænÎÿà-İ†1·)aC‚êß4tu\³ğu‚W(Ïî‡ô‹»ã¬ò›Àù~”<F†9È*#˜§eõ$íÍ»¹‚Õ“Ÿvè0¡ó%¶1|àD^à2ömÿ!İË½_˜×“ÅŸš÷Şó6kj2,ÅüvmW[§é7ˆ1†èÏ.a¨ÅßÏ¡şGùï¬Õè‹eÓü~P¶ğE˜|·™8h›aWÔ	Q´¿Uo²;û()wåÁÜ}îˆßzÖï~¿³ÆÕ¹Yÿ‚Éº
h(L!ÔÚ3¨ÙwTİèÏlahfRåo{]œÎşóÿ
ŒiÓÏÔVäàñƒ‚îa=ÿ^åß¢	.aÒÂ3hÃÄc¤îÍ…ˆSj
€·c¼‡
ÜÊL31©™#vhÚ54í¹iÍçgà5¦=LPâ/ ìØ×‚Ãê ¸èı²é¨…Ø:ÎLƒ Srî¸Ë9r'yƒÓnêÄÑÇ\ìÜh¯Š®¿Ô‹O³úa=>¿#ËË;ó™¾ H‘›íìşw®È¸Ó$H5?™°#³G_11àw^5EDfw‡ğç¿˜v[šºs?ü/\‘ÿŠe¹ÿšÕõÉ³cW¬³{m6t#¼ óêØ ‘«|Sõº.ìÕgÿ€góÖg^JèzÉSß÷t "P½}™æ>Á\…ĞšhÙ ¨áø’:w	r?­SOs±ùxÑUÅQğ=(º˜HP+ßçŞ°À€U¯†Ø{Áo·<ıò–"³ KÎ#6x²vÄ-äĞHöñmiÚ,FÏx)3QO¯†ÎQÂX#ŠA9üwÆõL³ÿÀ%@rà$ªª‰NèËãu’_†æï¨”j¤^ÜçbpYÿs¤qôìqM`-ÿ‡˜æw;²ˆûœBš+U}e2`l=%obÚo„¾³¾P¿sûu)iíËô81ÿG¤ÏÏ¹¹g’íï­²­³.«ºöÎv!m)Ä™h&È<!|pÅšU¤£Ê·sŞh…
99íÌ~N`ŒƒÇåùÓiì’¨ññ}şµOš­eÅïˆ—Ãîº0¨ü´ª¾sïùŠ?ª~xaqUÍö¦^®Ê}!b2'}÷‡Ê¬R-Kf8®(ot™¯< Y'—ì%Õ ¼^²YÑKHÉ-ÅÚ•×$‹²ç¸Ç¡¾²-ªòßé«Ã‹şÃ«9â
NÌ)ße{hÜÉ"¡ğLE`‘›¬üH|‹SLê¯Ÿ4m‰ÛßÉß^¡™lcÉƒÿß]R$Z	­Wë÷´Ïªƒ<¶ÔeÆcİu(Qh.­$è2H˜ï\„•ö‚/’Èè8…Ügx°ıõcilBx“„#§“A ´ÁÜéÒÚ±dİM:>zeƒI—îÔ@=& E-
gÄ	©ÖkFtö¥È&_ĞĞøõTë÷oÓ*¡Ó´ŞeTƒ	JœË!…d¼íPp'!O(Ë…ÆvıOg¡úzÌtİÛvĞŸ{©	RùÂ!fÂ R%é =èB x’<
¯KŸQx.G×d7#îŠE)UÑJ^wx5İkm=[ï-g$·œgEàlFÌ uü>Éin74:à1(d*²¡WŸ‹)ªğFšˆˆ[LÂ1Whç'lA•ÑBÛè8$ÂÈt†SÙş‰$ıõª¿B‘¸¢#ÙÕ ¯	Õİó^ƒUóŠ@\¥˜ €«m—@;<X QWÍ‡Xê›eÚ0×«ñŞ—JWğ$8b˜ŠÕ'`¹¯oPtYjJVöxÖwÒ¾ÉÊ×(B7ÉÑ@]uÖ8‡›ô32úÀíİôHÜôäK?ëöâxBşVdWCH_È[´Ÿ+sâ.Çä£Éì‹ô1fb‘9 ;Ö@OÈÌ×f*$37i+ôtÜğˆ‡"û—fÚqÖtG¨DÛÛÕ@å€sšÑyDñ»ögŞÁ„¨jScõ³ÂÍ‘°UÕ±&ëû‰’dQêÕá¹W‹/€€‰¬¬üœC8¢^Ó«#cn„f§#Rj¢cºâA.§ı6!:Y™º¥şy¿Hœ‹mšgúï;8n‘&ÍRš&­q­zWıNTp;€u9şÙRR’ş9üã6çøŞÊ» ‹â\w‘8jeÔ©ğÎˆÇŞ H}òÏ)QÙPö^zœKgJõ®_û8U³—¢êAZì3+ÂµşØƒŒÈŞ^Ôİ#U*µÍúcöŒUU'†Úz™V	V¶´a=æª'gÚ ë3½¡ƒX—­ş”K'ù¤Goó‰J
).oÓ.Äiÿ–6÷Pª@²úÙÖ¹ÄÃÌ‘nŸJI ¡ikD¹Áù1dçx§†z¬tÅvÜô–'²©U“n´â >y ‹ƒ¬‚“´È¸’á«jÈÉÑ¬¼¢Ø¬vfØMuˆÒ2'<ãÇtJ!ŒÃäµÂ7S¤]K£DMœE°‹.øŠ{aÏñòq—’ƒ?c×ŒÆ„;Í¹©U1½‡û‰äORÚ!bua6–g:1”z¤‚Râ…èÔĞ‰!8¹¯Ñ|Åq¨(V{Çº$úağŞ€.€©óÏL\—_mMùuœO³£m°,Î[s×<á©†86q}3´,Ã§Û€1dj[ç„Û]rcº¹W²'dµ´‹ô#ì°È2€EÁpGëú‘éË¯·ã˜XbğøØè¼$AlØ_\ÎqÂŒX×ó4ÏÛ±fû~Ç¸ï%)'Oì˜ÃQIğ[î÷¤©@B›:"	+•…J¨vÀôÔÑªWw<_o¢hØİ3pšÃÀ»-ˆà»dêcá®ï–ÁÕ4!;´ZøâøÊ^!5ÛUĞn”Sè#!Åß¥ Òl€Y½dÕÇ›)§ÂĞn×Vïû`Èïùî‘À§Y_éKÕš)*Şè¹’{gb Mş ŞN<ÇºŠº&ÂÑı¥K®D¡ë!yB4ÉPŞBÛÕcÂEéwæP‡¦<Ì@Ö"Vˆ¨¥¢½PìŒ¥ŒÈ¯MíküXHÒÜûşs§YÔL6ƒëU–~WœÁ~Ü8 :+–ÇÚ;^@rÉ‹¶ 4¸H¶ˆİjAƒ¡º¤¡9ëõ¹$ËÎlŒ[Â2–Ò‡*à|Š iÓ#1~¹ÅTˆk2Ïbã:âG‹áËÉQ¾=rÙ²j8G+w3ŞUáëäu•w8¡WAÕ])¼dİ¹Ñ¨1»”2şk¿£Dp_h!×¡æñp<úÆ€>©c?è8luI>²<†g°çAwŠóÜ&×šŒÆ}r…RŒå™q?Ó
»×®İ›»…ZOEËÔÚ‰h•é‡ñ*éc%¹¦%6cÕÙ]öW¤ì¨$áÔMg;xÑÅşÙ€Ü®LM"D„p5şp.†â)?ÅüÆE„qğçåûBƒ˜|5Àñw4³U½¿	¼¥3s–JQºÂĞ=¥PZp3*İy´>ù
`é ØúÆáãÎâ•ûvs ˜!UÚ!?zlı¼P?kNoJ’‹Ş!i²’f—œ<z˜g$8.¯iÕ/†á×“m3sº˜©vTÂe{8­ÉÊôSÙ° ±F›ÅÁ@2şIYŞNüTulne€ÏøeoÎ8P x0:à:”ùß„¥¹7>‘­Üói&è,}U1ÙÕ<pÍe:šTR÷V0ùPXõ>~×›Ë^õÚÅ9ô‹›ªä•Ì²–ô‰Ë;h´ëæ5K¥«°­jºAeÃ—¶Ä¶ãåÔu‡°nÈËg€í|Qİ„	¯Øx[væßpFnßt!¬ğšmWL”ıáæŸ-lv›§ÚÆ!JÕkMl_Ïr®ò­Ê…2c-ô!®áØ—·¢«’¼g´±!YzÉ|9¡#µ1œ ]:ë¸Åˆ'@ÒäÑ_âÃXó7·•)O£ƒu¹kqJß—|ƒE*êìq@äü˜šø(T*ß¸û¾ØÄØâG—p({buÕ!ĞññÑĞ<ÌàùPçuÙíäú^ó£} ÚvÁzñ¶ë<Çë:8ò’É£¾EWSÿO*qbÎ^Š;ûˆ²ªJ·‹ú öò„<‡0!ñÓÂs`<8èï:>îûîÉk,ü–&‰=·íN¶ú®opÓ*îoÛlëèq4œqÚtÓÍô}ÆvÂÍº€Ä‘<!µ“7xx$™G?íFª1‘µM»CwÍ…"EG@äK‰3?†Èm•YFiø Ş2F¼eÆ Ú‘”YRŒUvSÚÙî[öæ?fùÆgÄø•­iÉßÓ&Š2@óšZÖl›¯lY&øRİ¬¤K	JAßÉô¼‰Ö•{İãôµ	<A{mu“,¦ŠŸiÏ‰Ñz:uºÚìdŞ¾Û‚’7Mw¥áÉ)JåB¹8¿aõ¦¶h.”®£³Ç |ÕKş9Ëï°§aã¢=¼ğ¸w¼3zĞŠ¸úE2ºØÃÉóX[9\3xŒ&–®M©[I]ÜÈ<½5Oí©|Û#+ BMä4q½½Å1Ó’÷şU×µ«Ô=²ÊĞ·4ezYK­PI½™íö‡E\TûX7ä¿)ÁGâğ+³¡€±³QüÑ”ÿºjf3ºéx•´ö— h‹JØíÖèX0.6åÏ]™’KƒsFHS8›òÉïÚfZ
ê}&J¹k^"«3µqÈ_ûbQÒÁ((û¤Ù©ømÊáa»¥¤vª¯Cxé%CÁÕ{l¦E{¼¯ƒãË„İu9‚‡?“QÎ¥ë™ÛTî‰µÊ«ÉBÂhµ¶Œ`GíWiœØ‹ïZÄ;h˜/Yõqc¾YY,l6»£Äş®¡’’Mş/ïš¶nÀ"Yf§ùH¹’ƒ2Êz´ :"8ÿñLÒË§;
zÚİAñyA–>Øi3g!ÆĞ–õÒ( ÙÆtÕiP³0z-àÁ.è’éV<¶SŒ-şO•¬<:ÓÖ…·˜hGÂº¢MßÄıÍ
3¥üŞ~ãú§ˆêšßÓyröYØõÊ	\P©øU«¿GjæZ~0ó~kË”B¤Ï×f4İK[Üu”ÿš“¿­-½õãÇ©íLX+XX*’›–û?wæİúÈ®>+«ñVˆS(¶Åi5BÕÿ’5”rÍ•U÷ãäŞª³’39·ÄÖ{_*wd]oCT¬Bª&Æ~¢,q°¬}lİè'@ø§†Î[Vi
¼³AÂYAêÇ--ùŸ4ƒ5“;Ğ¡j÷§cĞs®‚!$mf2§³Şøã’c×ïõğ’úÏ)½y.XBğiÀGøPÅŸò)-¯9úÅö+½kyT¬XÂ¥¶ü›Æ°‘À0™²îâåí„bÑÃ‡ÄÆuèÇ¥çíˆ®ŠüÚÈ~8SêGË<°•ˆ¤mAê‘TåØk‰³9h4Îi7Pë©"Ö°ó[¨
z dÍf*=2$/ÉÒHª–½ 0çÑµÌÌà/ÃëÑÛì õo‘lqÍÿ–'~q1ı[Vº
ôvCQe!"€ŠtŒ†ÇHàÜz,9#ÑåÍÚ7È
ÿ¿$[¯[ÿ`%Ÿx,A¨vùú´,Ñ’ş|…ı_@Æ5 7v0üÀ¥ÿ„Ï¨ïııä&côfk>×éø‘àOã®ÍpnÎ2j‰˜ï0n8Ê$Ì±Á’iòÇr|I1ôºI`Jô\Ëb í_!Í£;=ëå6í~Š³½ì!]›LÎ«/õKÎw²iØó«1u“^_HXâz‹+’FtÚCT=4œÀÓp¦¼KI¡ébõHPÜÍJëHˆ·TÈ°ƒ:*Y$JRD‘‡·ªªe8ò'„S;¸Â|áö’k?ºÑº´–p%¾nNÎ”'?FŠí€¹†üd{‹w’C5$Cı±: ²ÀNªœÙ!6Šyi~àİş¤×’RIùR1½¤Xf–ô‰uLÎùZŸ1é)ÈŸ$U«^¾zÁdìß‡ÀŠüï‹zbQ\¯ÿë)8­©¶DàŸ¯Ñbô+LzÅy.tmkÌ¿ÊÖå5¨pˆöKP¹rYıkşb_óHõı“‰üauKf‹ÈËO-êg%¾W9·RV!òÊhìe§E¿/ºc¹^ v/h†oĞN¤•*ÖÄÿ1I$äìè1¢;äYÌ¯ZÄÒ7D0\x»÷Ÿ	/Y¥±(‰¾²Nó!èÜôÑœ`cœì8Ë!ŞêîüM ÛGl•0ïÏÇ­Q@@½’/K‘á¶•ÉóN,¦9s•Ú<wJ_
q3\Äü8T‚¹Ä“¨7y•Î} Jy^éÁ7XÄøøÂM¼—XÕVg¿´ı°.'
ÿëF—¥h¸)È–iBÅÇDñ}ô®6Ià™É°dI\ãŸG8HáôJ A9@÷ècaÉ­¿^øÈ´İ¤º uü÷ô(°ˆmO0‰\ó‡Ÿˆ4îŞ–û¨FÙ­…][éSÙA¬v—h˜àY@#uŒÙÅfK	³’?ü1Í.å£´ûì€+qkpˆòó@2'İ‡
d)ûP$ˆWêpWÕ;íîœÅâx×õŒ'ˆ%{.$’| r¢Sèı$s¼7+};ÁßdÏLM%ê¾ùû}s¨/¤Õb^R<sa8ä¸5ÏE¿‹ÂÑ(>,d‹ğFØ*,aY¬É“æg<Í*fUtö[_àÀnZuƒ{†X©ŠÁæ¨N·Ycb*'›`Û+GLÕUßrŒ•Æ®<¬&'bÍ•aœ‰¾,.](‹ûÇ€,_Há½ oûùj§ÏŸôêºj¨ñ^o×½ŠiT	Vi¯H¨L,7*@7u%úñ"ÿ…C4z'YØ0‡ß›ÈÀ[Ø¹ósL?â?«÷úÖÖjE™š7B„i&E-û±¸Ö‹'`™(XZ(äk¢00Ä·ûcûª
Å*¶rU1I+UŞÂZ¢ÍRGı³™w‚Á=“è+³({=4	?ÇªQõ"Ğt5IŠÇ…|w—Û¶ªÙş;ÕXnô‹³€ŠqÂÎ«ÁœV¼JÑÂÓş–š3UåKN¶U&û+Í0>šô«mŸ‹Âğ Iñ’ŠR([JÓîDŒNdßT•ûŒş‚7Æ{>³è+ìh\Vg
ÈÏÁbi*4*qş|üIZ+Å;ïù·Ş„Â[CÒV „…K÷¯ÍÚí9'&öiLímXqûezbepÄ”X>Æ!·Š-–ğø|	%c.ÿ¨²¿ïš€vŠªÍn”¡Ì tob¤=­#%¤¨éŸÀw·ëx‰=èÚrİgˆö”ˆşeqò/ë¯9d6‹ÛéääA%3ı|I
6Ş|ü•Ûî¼´S'ŸÕùÄ{÷ÜÙœ3b^%¡-ñ¥Î[§Ãó/şŠeñ†¥s Ğ»ãkû£¤ ÊJ¤û¹î¹Âö<XUşS|	0Pª%˜¬R?~Ï×2¿à‹qÎr©`™ qš‘¹ë/»¼:9Rgc'óªlê}6®l÷h'|)òLùTnÀòš¥S®—Té®.®…“Ğ^ü•ü<0((3ïl-ô(sÉ¸¢@½ğ_c•ù•­0ˆùû
‹ÙuÎ|@‰…e
•üsŞóekìQDƒİÄ.¹›[§RdnÁRC¤:7v3–¥áïh4ÂP-ÛÀIªÃLØ®Ù~bv^È§8¸Á/”²øSÁ&“û&¤zP7ÆJ¹k)w=üÚÜK„àÎšñÈ	©Vq;Æ4¡(ß±´ÉCÎIM,úñ¸Ë–Êpó@D|_<ÏÇUù0sÆ#Ùˆã°ÉT°Nª-}ùğ*Œl5ô•~ñâ^<Æ¢¬®âÂ|¢í0Ìœ }ºd×|ttÿh&z8Ñ;¤ÂßÂ+!¥‚pØ¼´[G‰Ä4)åçÆø£õ}R^÷:¨›Ó;«15:¯| ~/8wüG”JêwáÇ"ƒ;ççZxy%æ¶#åIÚ°v–hõ›+i%8ş0YY¸Tçÿ+ÑÎ¾®Aà¥O©‡aµÚçUWÍÏß`äÇ¾¹±³[ß^è@E³ 8ÏåîOrş^FŠ4ù,±xªzjú@»Ö±’cÏ	ÄÓ]mO» "<ŠC¶;iºÌúÛ¡"®øJ¢°ÇJw’aëü	Ô”lîTüÌ€ˆÍ¤\a¾yZ=«A¼7ùB©ïßÌáõÿp?êTšT
?µáØ!©¡â×nvNJ™Í{ıÄsÚê`ÊçUN?P
ù	mi dK’†¼7À,!âáÿÏvÈÊ°ƒ~©Ñ\)ªâËáZ¦]3É¡œúê€æ­[‰WÕh­êEUÆıõø˜g¶ì?6)Î‹T®±Ñ?áí˜ó·9ƒ“ h‰IMåÇÕz¡Ã¨ö0æeµø†73Ü?, V¹d¾_•ìBÊ°;b°´òü‡~	úô[Ğåde‹abĞ/o™-ædÿáİk"ÆkûDt‚üt¬ÅÏé\¯æ?ëRmË+€QÅÖ¨G,M¡¯ïo)|æ„j0.½×®%eïsİuğéôµSÓoXú/àÛ’	6ï©ÜL¤¤Ç´Aè¸ä?4]îÂ©©(ĞöÒ5Ë§ÎØÃIKP••	:ˆ¿Oİæƒ¿8 /ï«NF—ÒµÅ¸ºûOaãgşbÌô•çÁ}ücbBÂ³óû­ô×0^
²^bùŒ87Ó|d‹3]H³P4¾Ø†<%±z«ô: Çƒi¸ˆÎó™£’ş:G¹ò
v0Æk¢á5iÛ¾)Î!–—¾šÚ(L2XD„Ûu*pÒfÚ3øô´iš’i7¼UK±ĞW-[¬Y‚¯u¼5jÕŞïœöJó[xinù`÷h#œµcûvuáóìàM9`Ò¶?DÕBë–›‰3ªª}ÈÅÄJf¥xŸóQÙPÌî÷à)M9ßdˆô4B*"&(åGıâèÍà‘¡nao"5š˜&šÒ|ıºÄEUr†¡â¨{WŸC^¤&D•¡«$œ\Ù½@İÜQĞÍÓ—6M7ŒU–…è¥6Ze…bP½ 5ífbmxƒ6á•ğzĞ-<9<ı¼úÀûô´7B…û •°ão#Rí¢õxÎ¨ªâ™±;ùß3´cò³µCyk˜ÑU—áqQÏ5 l˜–ï¥¹‘Õ¢¶äâ£zîF·år¼8›3? ÷mÖ3ié·Ç¡ı¡æ‡ßQWû[œí›.´÷@è¬°µikêæüÓºHJÌô~jpü„ñ ÿuêaÜÑ.{D¦Ì®mİ”tñ|øn¼Yİç†9£i,ÕuRÌİ°óK“,­@C´¢nmlIÍ vœæ\?™ÜÆŞlw(fÑ!ë‰°3QZFqO°¬˜ú…Ëëùq5ÅÌÿû¥e×Lß'Ág‹Ñ¤.p+ş¿ìÍúE|F»™‡İÌAŸn‘rÙğØm;úö6].¸)FlB_õmƒ‚|*6’õÕÁ#ÚäÏç¹ˆçµJÎªÃÓÄ»®RmN›P	ç¨Ã\Í–²E ŸõuH ÛàäRXsµ“ƒÎz›Xß ŠpI.ˆ`‡B±ÌÈû@Óì–¨D7ÙUŞ|ì>pX„$‚Cåã7äap§´½rğ{º0òğ à:3}zÁPß¢Iå‚‹Í˜R·®Ä¡dù9÷î/Ôü[]Gx¢mf?™Ü°ÿ!sÙÆZsÍvÃg‘IÅ‹(«ƒÿPf1Ì…X4?™4©q‚H%c¡ò‡š¨é2i'Ò[ßÁ#ùü‰ã}p©i¥-Ó›L9ëUYÜy{†+ş@G(.ªÔØ“ÿ`—…>T¤3°œ^Ø%¡™+ÚánÁÈîS6LíªçÖyUÊ„–¹ãİ:¶ø!â­¬:.Ÿ©E>VˆÏİ@´¸‰úlÊ¼ÑvĞkƒG1>hç
p™3}3:Áú5AÜYÚòHmíAr ûZÎG‹Áhz®Â8BSQ!
01óo×„ãcËd¸k	¢çÂ 5²^”t"=¦ ëM)¢ÿXÿg„OL<l†áz€:ÉØÕŠ^ în|çbÀL*v<ÖY ºyRXj2	O ]€ôjmÏ«£ğÏ”µ@R9NØCƒ Pƒî‡¸³u½sìVR_<„àï‡×¸Éè":93«<ñmVµªÿ×êÁ»µÁQŞëŒĞQGl·‡3azV'¹ú›6P§))A»>ë ŠFë†võã0
£Ú¦vş–ùú€›	‘­éÔ¦ ¦x¸Òv¢Â›2ç VÕëqK'JË,ÙÉ‡¢Gã#ªkß½‡•“Àz3»weO«ÕijGì§^q%”O1UÉê¾}&:ÁÁéÃô9l
ÁuƒÉ³
t Œ[áXD{»<Ş¿ğ]£Eà¯Ú\]üïVd^;€k¬‹âGw€¤ô>­Óš`0·og¡ñCª…¬FMµ§éH8®óØ¸ó½ƒÖS4æsuŸ$Î}	šnş=´ÂÚÂ1(â‰%–¤IÖÈ¿“t‹¨(Ñæ‡ğT&ê]`"ÏF¬ág×!Ï„?5ÈÃ ñËeñÈš<qŸÑBIÊSŒîMcÉ‡y/'Ü´uy»OÁ=ú$¸+ˆíÇ$e±î¶][#&ò$U>ÚLŸ?–¤'†ñt2zÚ¡6x¥ØRÆ\‘v~²Îº”¥dFŸ/H‹ñ¾o³Ar2Ğ•XÌ@#½“PòKŠ¬q+Í/au5ÙçCF]døÜö ©ğ`]‡ W˜<ÉĞ%s®¼!4û÷’&Z4¨Ê€ÍR”ÿš>	lnˆ¶Å	´d8-àò¸ÕE>MA&Ì^UÀ•Œ*šô‰&’o	ÏµÌSókÌ/NÙfXn«×+„‹QÿæÈË—CUhQeáó~‚±Ù«ØìîUö`&eRÔA¶Z£h@]¤yt"êàşœÌ¦<9Oóñ~«` Õ£ºã$_ˆ®Ç°FÄ©Çùà&¾6>j9}Z
¹2åu9! ^ÿáéKc)ú4T†ŸkÙLøÿîİ‘ƒæŸ€&+”ü‚`.·£ª÷ÜÙJ2¹½Ë08HA}l
³„Š¿´µÂğiÓæ€n¡Ï‘Aë€üÓ
\û¥Înt¦‰œIRÌóÊôS"9ş²3=ó­—š±‚‹C,¹=¹’8ô¦Sg9·èÎ òû W]ÉëÄ¶>‹³é.Ö{iÊ¡ê`‹¡–YzÎà´•såPP\NR«XOïQ2júß\`ã@ÒGkòyü~s´lÿ¾_*¨ĞaO=ôcöùøøïÑ£_ÉÉ°G/à…Í/ªÚr÷·½¤¼ãæ0dUÜ7P‚û³¨ã†Œ@mã˜×5kŠ/œÆ¶A•}Å?ô•¡y›å•2Z_V$Ş#/	2‡.å’ZìD [÷VÀâ‡`X"l¼{ò\„Ñ¸1ĞYhìÙµYğ^rD^ºş‰ø­nğ·š`·Û¦t¾itHLvÁ–šJŸ®!0¦kˆ4Ã‘nÌŸ8@}âãf»7e˜ïİÜõÀÔvÈ¬lA45#ÂBHèúpûÒq4éU®™†ÿ¨åÄ×"BJÄ“&$dy$ Ù6¢0ŸB5É:[/#Û²Ïµ¤Æ"0Tß9ÜD a0D´Èú°¢~¸v¿çé¯C`Ûòó:ø6dDµ*Èä–/
¾ğ'Q(¹.9&”¡o=ÿkRíÇÔ‚ìÆ±Yi>iÀİŞğZã]YÁ_‘Şÿ	~J7P™4ÎûÖ{£şø·]x¼UÜó˜C|.<kßLŸ—Ù˜ğS†Íİj…Id¤(p‘çm@„A;Âf,Q
«¹ŒiDø ¢‚µ ø%fl˜gI‚YäP
{(µ:t [åmúÅ§QC$Ù”•)k{i 0•2×Éÿ›Má’‘„
TrMı0ij”OV{wép§4ŸgeYsÁroç=ÇâóÒ<{Êyä7QåÎÃ¦Ò¸u‹Lê}!–‚nV³YÈıî.0…*à½*«¿GI”'í)S×Ü„Ëc9‘óÀÄJ“.Š´ “Øê°AÚ£m¨¾Aë©Š±IOn¥ËüÃ˜’½Sf6wMC‘ü"€s‹i+°ÓÌ:,F’™½ol®¹Ì+HÇt'ó^ßa2Í¼m°øB¾¢ü‰é:¤ÜÔ´Í ´Ñ*yÇØ¤b`3D5Lúq™\R/)Û?Ä:äİÏÓÑÙÊèw_X$jÁY7Ò3î®x™óKWVé
À@9L<KwPD
ˆ¡ÛoR³3•¨vRÙK2—ãbí ‹9µ>Ğ…Ç2j|n¦mÑÑâ¢“_OİÍÏÛå¿c@’·T„ş˜»"­d¤=PÀïy¯½:íÚ®6¨ÉœX€„H‡b"|x†¬E•VqCî‚äú-plRqáO8{¥CRV3ªæİo> Ëû•5<uU’!#CpÅºŠGs¶Ğk$zãÉ¹U¶#š•ÿ!f¹"ä´¨g4u¸­QŸl
Û£“<‹5–Z,Á¥WhÉ9¢÷S­‰İ `R-tüşJü¸ƒ³Z7ß’å_\™B¸qb±’ ß»<†ÅëÛ5±ŒEè¿KÕ1ÜK˜Ìwı(ôBß»^VŞ(]n¯fgYøUXYv#óg2Áfa6‘!Ñl©½âi§â¸$¿ËRG_»“~Y‰ã-¯”—İÿYš¿(W”Ò¬”ì]±œe‘ÙƒgQ:?%`YVÖøë™ÕîC{¿üå*POJ–yçuÀ‡“½»Pk{Êz®;›eáÒñı÷fôr¶Pk	¡ªedpS4+ñÉ&êÕÈ¢Û‡­ÜÔXw¡ò€&	yõ	[ØeÔbBîÆ¿¢è|Òı…ı?Ò¶]t0ÅQVKl?ßÓ×ÿø5 SP'‰¶vÃ‡öÜáÃĞ!Tò?¡?ÜÚZmiÕ7&Ç
–Î¦²JŞ{¥û±ˆ78‹;b\Í,á×æP§¼Go0Ö“üHB„!y®LÈ'Ï%‘%eĞ¥•¶‘k¶[m˜t VtA¹ v¾£UâQW HîÀ;r˜BÚ=M®R\	.j^„;ÉbÒé†ƒÑµ=â=Ş¶}Àéfğç4›vš-^ÚNË?jÈ¼@øo'­MUïú²½«ê”5–†ê¤/êÔ¸Áúx3œïØùÎO•FYèßÙ¾ÛûşzKcàº6eø¿BÀD°P ®8š„XÅ;Ô/…,L8´ó!ZºÓ¥4›“$6•”fæ¡;O¦íOÏœbÎ­T®û¡P¶”›ÒbOØNıLŠ}ç„ÿ4:Sõ~a«Q#,1Ÿ¦°Øn¼6«·“g„ £ß´jFx;Ù,uíf†ñœË©ék…šÊy—óZD¡%Æª"H²ªºzd‹Ó¬áy^Ädg&IĞB|7^'>*áNAxşNêåÙD*bO»XwÅÈÊ´ÙL—÷£ñ“tXÔ¥µŞ ØàĞi¶eFäŒ€‘˜ˆ¨"wZÉi1³â`êÆï!ƒùãô-¶T—Ù=‰8çßÙ€)YÎvÏ–	’ô%Pšæ"³¯º‚Ó°dƒèD×cïÊY»<'½r	Z} y5¾|”ˆjM]0l}”7(W~7d\”JËWç,zÁ`:ïH:JÒo±„ÕÃü×]ĞcúZØX—“µ´U €wÚŸu¨nŠ)Bğ‹!8¼	0\é«Ó$Ô"ù¹¬uìyü3µüü c(°;–ÑØâ8X=¼YÊˆ³ü¾ØÎù’#BÃ¯`±¾H¢ØÖ“*!º!².(¯$ëÌÃiO»sg¤^ÑEEŒA¦r†G› ) L#ˆãupéB¦´uìqsVuïœ‚®Flñc;Rètv‚nB"Ñ
láš°X ApÂ¨M¤¼÷ (áŠÕ¢½(‚Š’½ƒïéP[³;
`Ş"·ñ“Ş»‰ñıŸëuô1x‹w¢üşäÅ·iT¸¹…S Ş|3ÅÓØ»WøÊÑÂªÿ¨²¾µx­Ë÷™Înÿ÷æødç÷ÅŠ`•‹N¡ V¸÷«—®y(¯îÙZ‚må<ñå½¤-ég%LÙÒËNÕNT€R!¦ÂÚÛ{¡jB–SÑÆ¦Ñ W(İÈ_º¯ú¬Xb±m	mP®´Ü#æPFˆ€Ì”ÕÒÊÂJ’Ö¡Ò–Ûşÿ!vàD»pCşÀ°Ñ"¨3„•ÊÚµw-³>ï\¹‘¾´Aïß­–-Ú,è)|dÅ‚Îq½ˆêïÃœı÷”á'Î¯÷ş`–5ZLx—ŠCÑ	ÄDThÜ¤”˜uH6z¦UuúÜÚâCÈ)Pv€®VŞ<ñ¾ÍF+Ã å³á^áóß}	
öû#Îú“IØœo)êçw¤Cò"»,û¬÷p…Ÿ'ÀPê-¦%Fæã˜I’/òğQnZ·áî–­ µÂªş[L\e p"F_nê¶ù!Iõê“=±I\tåˆR{O £ÛÈÑ¤›¿‹YM³_^WzHm²V'±«È‰Ê˜ªê§”G[+j~;jb¤Z éõ\ˆ3ÁhÎ[P&,"G1«1.ù<Nï_>š‹)ÛvÚÔU(1[ğZAGq®t2O¤eäGÖx¡Å§Èe¤€nÛœdNŠ¡f~Huó_?)*‡BÊ½”èúLÑaXğ®„¥‚à¸ WÖÌÕ«`?‡hVC}’a·=jÌ=Eâ*ñ@m>iP«»”Ï™ÈÆq¯M¥Á§ëÆ¶ÓÜÏQu¶¯Ğû-”†%¾*\ãGZ~*‚Ø›Wp]>;ÊSA7†§ŒglmÆcÈZ¦İòµ­Ê™ñoö¼LÓ‡Ò¿ª1×r?¸uğ"$î6-g§k.9V–xí‘kÎû§¢H“A–6Z&ä¯¶ß;?VgÂÆSF¶5W()r²£({i‚$Ã´TÊºàÌ„`9b)Y;…X}¬@„>Zh¦dW+Pİ@³Ê£®5*“õ® qäh´ªAäjqª4ÊÄÅõîÃß:E.ÖôTş¢ğºÿ›#cÅGİ2«)×İÑnîŸ×ád<™±&ï2ÄÀøàCó¤¡6ê{¤Yä.4j¡ï0œøSyÍs±ËHÆáÄP–ô
ãğ\HåÉînóW-MõRÅÛûì 1F`P"½¬y§§ª¡Ú8Ä§§Mİ£ö´SóbÍe•Vôb<$s¾»6ÚB<˜D³Äiò^ë´4W›iëº¼%g2ÆÚ2­LC;íÖ;Ã†&¯F0g?=|œå¥<¡v#…SAÆ;)áÆ3¼İíéîÇXÎ®X!}=ŸAÑ¹« eOÑs&œ“€#ƒ¼uøM=şO 6Ïz©ây_«*ˆ}û®‰#™ÏB,2ò;ˆ)y;óvšx”ÌÛ"}1ÁÛÉùY©ûou“¾«––%R/S'NG“k±Ñ'4fyÃÚÇ”,J¾¤Z ­d‚ıG¸î*Bä É¤ŠêVe’§C]PÜ’¹zÙ¶ÛTpÇÛå§ÖJDa^Rë;€¿©^Æª³8±8éÕ@T6sàûCL~>ò ‰ù»ÒR¡êû»x%ÀÈè¢ŞŸ¶!»º-LrÂD‚qŞa…[ş»dßŒºgÔÁzœùE½éú‹Oªe;ågúÌxîk; ÏªO?gì%ØCÎ$!0w2£·mÍ®>ÍXD3#!IXGŸpgµèÓpbVsâ°ç.À˜ÜïP^sÒĞ{¢¡h‚¢«éaô!û€ö4í„&°Gºi±É¥G¤²Æm!'¨f],:º56ø(o/iWôÿåÉÍ×ÊtÊFŸœÄXH&CÎu!ÊÉ5ÿL¨5¶`X*lbç\W¼Ç„o±ãrŸ3ì.QTõ%PÀÏTÄêL¶€e,vzaÙÕ’—“(İQ²µÈ4CuÃX2‰¯`]”)ÒMâC.pµ<`~Y¸+[/õ%Èêh»¶<öÜÂ\†UãLå¥÷ëdôkLæ›ÏÙÀŸ)Ú%œ´•x/icT/òıÉfJyã:ƒ¶&ãSf*¬Û»˜'ÑR6´Æ §ÿ?úAR1™fÛŸë	`ur/zGÛ§K7xŠ@ó#:˜.êƒ‡ËtĞÚLsàkË^Úò²ËuEÁ z*wù¥3ªëS`líî@jXù“i¡Ç¡ìß]}š÷H¸«»×HFÌhl»<)Ò÷ÍİB«²'z™ ˆ|iXŸû3ÜŞJù­àæ¶ë…Š·Ëóa½B‘Ôák5ŸW;9¨:„­fÂÅ[—™œ&>8ˆ‡
´½´kB•t<ìµ¦#Æˆ2Ù’'%ôU&ãêßş‚±®ù8ö¢v‡kÎK©•ğF’¡ò”J;[ú_{w$x½“m“ÎÄ)§.—8æÕ±oÚ™„/í»NGt
Ê6ÛJšUQqMƒúÈ[×% 93|³Õ5-­»”GËT¯ê«w•€YvË_ddíïp©«6nÔ&å‰¡6§ñG¸ıÅÌ¾kğs: /5Ü?•q0~Ã«ì’¹vòïsÒåk"y0ø9ëºä2k	“dM²õ¡NÀBíCL›2É×P›œ±ò®1e›\Aïz[—tëX¶8@–IŞÑ¸ü„{ùåD¶G¤¿X«'×ê^ˆ0N©r%»)«Ô.dv¾¬rD€î]eÄÑå7Í*ÎF/d¯Ë`ÆñV&²UDŞX”DÓ–ĞÏ©ƒét‡`#”¯D€ú¹²ôe@jè¯N«8äTÌ`„¥ğ•[tw^øÀáPN¬Xå¡ô
@G5×g#]oAg‘ŞC±¼ÿ*}3Èûâ´ÅÚË/¸Æsyês° ßøØ<tW®'tŞ©ré.¢¬rŒ”iS‚Roœ.Zóìƒ•—pç­÷oÑ÷ØŞöàŸ²J¸PTÙğ+zæ—îTºcøÎ§FßJáúÕV%€›SZ<³>´ø·D"hf3Jj®Ó†Q"JĞ“9Z„I_Øéœ·õn ïÖòEB>Í2ó%xŒt‹?!ü½L½ƒMj$izùEÑ»Š®¾’i%„2»·½ œªÏ‚a¥8÷Îs‘ûz”`	F/ø®P æò€MUgCËÎ°…`nù‘Ôè¢›Œ¯bïØ—í€XbK®œ¨¾ãÚŞæ0âˆyÍQöj\¦IÌ¼'p*‚²ÔæKEz½ºí\fZ‰yÌ´Œ…f0‡!‰Õpq¬X<eşöÓ¿“|ZX8½Çı°<YÊá(Ìˆñû×H¨¬»]L1œ€–~©ê&B†£\sñ/:ÂDYl9–`%É~ˆw:Ä•­“ò,Qöà¦±sük3š¿¹¯œí‰.ã:zåù}Ç¨ •ƒå7éA6Üíºoª_% ãXlãÙay/0·¸,ğ£Ã!A*³ÿÉè'®5Ç|È+{â§ÙÅ£s\ïçÄ|®©ºÌl÷ø?v“¼màEŒ¸A€ò€PŸÊ^@£‚¡òe&AWû,à,ıÏkµj%¸ítl@tÎòfKvÑÒîb[/ë2å§ş¡2Ÿ6"ÊËÏ©'u¡ªş0sŒÕbŒ®î}m^x6Ywù’ˆ‹¶éäMıF9©LÊÏñúİèÆßék­S¾ËèÙü¯úW3Ù÷‹Ö¦«Ú|$GlÅ.©^7‡…M‚/Í+êa‰uÜ»^î”ˆ‚CÑ}']Š‡Ó;-,\Çç!jc7+â8É_Uù'|¬æÒÉ‚ïy—<¢¶·BùÈ˜o‡è¸¢~àd5ÈŞqäıåVˆ©&I›õKwéøtäü–›³üEí	²‘·ç/³öÏ`d©™&÷¦áÅ™@5¬;TıLÇƒç‡Ä-ó=ÍÛüá0Sd}Ü‹Étç]×VZ½ulÌ&–>›±ïÓ‘-Øs×+2Û9“_ù®c"‰‹2!ı­X%¦uáºyD}Ñhdq`l—uV‘mFÏ\
:MÑ™¡™>İNÜ¶LÏßÆİ;ñ/xÏãüë×"8g%ò\£…kA<Oä·4ƒI.<o4`Ë\‚:Eæ^·}y¦Š¢w RÚ6£jkI–Yb«E¡¬TPíÕÜJm/n-ƒÑIÔ EnøQP¡·‘f‹§Ÿ^¢n°”T|ç¡²eÒB]–R,€{¬‘’ë¤M»åOä|ÆÉ¶M}ˆöÆªŠSj6¢!ÃTw•çlÌÆÁ.
û]³-Ê€ù-g:³°Ê.¶x@â¸Tù«°©‹HRŒÖ:S½Ìš§è›ç?¿JnñÑZR¼ÊrsÛútœHVW*e‹ëŸ‘EÿË IFKü%AJç¹ÉqÒjNFò¹ÓİÌq–ĞX›ï
PÌd2vJÚLØ‰@äAM¥«òÁÑ1{ùêkËá ^@>ı´,€ÀŠd)¿+@A;ƒ?LÔÍñ¡Çƒ'Bã&$º}L¹Páã%V?§¤Ùİæo-`JX-Øìl$)æ¸é‡ Î86†Ô§?:îâ‰È_Í^‘yĞY[dædL`D ¶Úá¬bÏ%åCÍ$öâ­C$âÎşÓcšñ~¦TAËï©Ù´`ŒEÔYDçºPæí/¦l#Ì¨`  6–^?¨»y½ùG­AF!ß)SÙ1+ti¨à^EEöÔ´ObD¾¸ó<iåUÜx“’vÿøA¬p¥Á\ wCC´2Åˆ-*¥!UœÃÅåàs9xšÂXåÓA¿«%*ß)İOl±¤uÈÍ)2/ƒúov¡Ce $ndÊŞ]oOUšç7nHr¯kzPGˆhP=?ŸF­$¸MÖzÄpÏ³£ú-V£yüH$ÿ·¨Â÷Sˆ@µxáåo4 B¨5q®
FrsÄG0Ş’åÇñg½›
taJ£>Ä¡ üÁ®Š²U‘*e^ùRÕB$ò\¢J­Êâ®øŞ2gñÊu2ynR—8¥ÿdu§şÀ°>8»İq-ú3ğ`eFûñõr\htbv;*ë½ü
	P³8ƒ±$KR%¶Ÿ¸¶ ö`uAšCÓ)N°şéğŸ*$€/¯«sE]+˜hMZş€¿ÓR±Å
ÆK§t/9İFhHÂ¢uUÇœ­zéD§ŸcOÏÒ‰i—"€#¸÷I"âşë¾{¶ltï6\å&êŞì>å³ ¼fvXfNş¾Q~İ<Ö6EÙ¬öòÕ8‘ÛÔxdÊ¾œQkB4ÎÏB-m#¿°-‡P5ÊNÛ¿gVlè<ø;Èˆj¢¨Ÿ0;	üé!ƒC/”eË…ÂÊ‡IÜóFu¦;,I™5 iŒ>ÇCEePğ¸UNò]ÆRŒœÎ˜òLD+Â€Ê%ÇnJ‡˜ğ	ZE¬CôÍ£*U³é¸&¶ÈèĞ_;ë'!<]:³%e1x¾Ï\p‹õ(&gÏáĞ4?7³ìâŸa›ısÍMˆçmW§L'®ˆ§äö3tÃ´¬ ¾‡ø,Šİ‹Iem¹Ä
Ô{ŒÇdh[DîgÕßªµNnó˜«=[Şo$zğPì9P/Ş…öBD@Ñiİ¼ViÏ¬&ìŒŞq·D~A„KÕB¾y²ëè!%6t£tîÏLb}{F,Ã ¿°m•ùW½BRXĞˆì¯›ÜE­È~`¦ˆõ Ó‚3áòn#?e¡°,GNµv°ÈKg‘•Û=¶´á ½ˆ!ÕA’¸A’fk·ÁïõÚÈƒ—©Ä@G/÷—keÊ0şªrIÕ¦=ãI¾ï‰áÊ†…uÇ‹œ~ræ=?Bù—ü÷‘öVßf¯lî%U.Âÿiø5C|bç8Z1°‹»-–ÚcÕœ¶H.‘ïÄ¶(ù{¨~_jíqŒÀ14„Y$ùf ìÃRá¦|CÎ£ÙÕµeám'¹'ş2ê*R¯¾^ôƒâl_uúÉ§Å»0Î.™rX¦w’X9ÙzJäÿ‘1‚+K£u	,ÃÈå\|»Oü	ÖÙÅL÷ƒŒ±g™gSW1U¸!Ğë)¹*èwèÆšÆ¶~QªªÇDè]Öè¨3Æ±]¶`¨…‘kë&M7:hm¹|Cúsšo ¼ lâ>~ãl›½bût™¬³D¢(¨ëJ¹xU…7Ü¢&	¾{PYû$„µ!Å“*ŸZƒÊ°VÏõUeí¯nc§ƒ€é(TPuŞß•åéY?Š¸q·ïiÈÃéœ4V½d¥o»M³3G}Ùz«ó96RàiZmt=Û>N¾İA0´ ƒÇ.óJÜötI(T‹‚	²ÈlÁ@ê"Ió‘å±'ïE´[~sQ¦_æÈã°áH¹7R¶»ş÷!Î_D³Úí ÅÊ°^ŸÏ*C³.BÜE÷“Éˆ~~½Ä•¯x}ÜVÂ«£;@Şú$¨ß”€‡XÛkdšo"Ãk}L’n0–¢˜iãBÒ2‚,ğ1ßÃú)¼Ïuü½œ<`ÖVGzeî² -sàìÔëTtÛ`Èãÿ·í¦‚±zú~Íƒ;ÎàÿÈ¹y fv{Zß‰,E6îW"˜ó&>®gDŞ)É6™MÜ_Açº'.b:µÛÅ©/,+2Œ‡°áô@"l._	%kØúäKÇ¼N¸à–†«rÕ 8/Ó	òû¼¸i!ÖW‹ãÜQ½Òv*6şïÈ6ÔĞª¿
Eş°kâã@õ†•zU+.-–ÅQ`>Ûó0«íuÃ	²I¢©6†ñçŞË´Æs¶Ñ¡!¼íÈàÔ§Á*ŒÊÿü¨–xá\T¦rÑĞÄ9ë€ìì“àwë¯;µLâÇLs½D¹Boá!1nUàzKó$Î^—U€:vÒ0â›`Y¿#;ß‰¸ğää(Ó3ö#4Àç‘¦µ$5©® ¡âf®áBÚ†Ä²W„i³òéâûo4jŞ€]]WÔ+F)ú$ªm7jÍW	¹ãúGº|¨C\8î³®”±q™geiÖPØ´}Æì„¡oRğË^Œ>S-÷‰À0ï¾Wv©’ì§¥’î Ü`v$D„vÜb`¿ôë´\²x.²ÙN˜+÷lÚÉëœR[y,¨t³ªÎ»›wBê63k4‚g4õ_Ø!ç‘h#üLŸ1ô³²P'wo†vÖB~TàCâ’©ÒiîØgz³Sğe¢l!àe{`Õ«‚¤Ê€]`ò¹Q¾®o6ô$œ·Ü9U¢D×?½!É~Ó1¸–8ª³¹Î"Ÿ<¬/@Êıb+³Ìšvn•Íq¹ªÑùÉ ¹xĞ‡ìB"5í¨›O¥ÉZ\Ûì·~Vû•‘’Rs;%zØ£eÚ¶m{Í‚lhœ·ëf3Kdç8ı	L¢X _oü™»ÌØMV÷ê¡çÛbG6¤dêa3ù¾õLg^Ä…uÃær	MiëFÖH,™A4É‚–ÛßÿW²¡Úå„eê¸…ĞÜ-8D“ÙäÅ8‡Ã;Ù1iÆÚNE”]é$o4¨r.ïpÂèŒãä!ø”Œß°s”¶u£ìÒÎ#¿éåå¸00Ã‡†XĞë$ ñóG–E^ƒ$´´g7‚ U­|ùKèC/©,ÎL¼º	…TË¾ÕNôŒu© {(`âViœˆÊ±¨m­æøËBÖ+Då¢àFVSsçŸÿ_tèy½Ã^Ëı¿’ADmØwëÕ®ÙR%B#‡pw q¹¤ØÒxÕ¯ªÈ	+•µ«“ÉÓ$œ¢¶_¡ºW(±(™İÜ’€Ò>Hù&î§»3…t´#a•ö]ÛÇ¨"Ÿü‰L°şü].KG	ºÂœêƒFqFÙ?H›­èí¼x®oxkÆ=¸j3h‘N6°[®:ë¹¤3¡•œa³D‘^­ÂÔ.U}Çeåß1½Ş8÷£¯®¨wó”«ƒÊÌñ„Ğ‡³÷»Wê4@›S³)ù\V`Aüäÿ‘$;¯J¶õ’&¹§@ÚUHª«5«¹Mj3fWÇ5~nº$á™5:œ±»öcäíÒ\Ç99(OºØà‚³˜Ñ2ãåù&±aÀçgóFoksë!È©]°‚ïãê¹·©’Åæ!XS½syÛj>_ÙKëÒ‹¸É`Ìˆ£êdä—š”«Â°;”„ABñ„¿Óà¢UÏ˜;{›GëµzÄ‹ü¬ƒ&Cf¿GM‡Ë»ÜSì_`‰µiS7­}¨˜/¨0á¶Ûª¨o=‚“Î/°¶ñ–Àæä¨BœrT;5…¬OL‰r…¼Í‘6Œ`Ø0DKˆOH¶÷|›sÙDÆQ 
d¬dÕJY[ê?G0(ÓêeRòèÀZ„ê¸¿ÙĞ ˆë|1©DàbÆm•İğ¿uc¡–¿öLûÚ”x¯KĞRr˜·Y€Dğ³HecÜ1¶êİ‡ŸšP¢Õ¹X;»±ª’Ò}ñ¡÷ùÁÌ1IO†¥y‚3g`˜%âÀ˜¸}‹H.ïíOŞTzyÜÓ¦[JdÂ…jÑƒt!Éx8µ
ÿºp Ç/!¸(c«ŒBŒ+	 Œş8‹VE–2SXŞu=)§øÃ
Wu‘;|.	ñ³Ôñ›idö K6­‘É¶Ó^ÒøTé÷Ÿà±R4Ç©‘Áh<ÔDH)ÎÃB:“KÙ™Ê3ö„ciû0·¯t1ÊWŞ,"à·G Óô/š­x|€¤—7¼V¾íF™%KÚSE@ŒŞGwRü•º®ÿÌçØùúÄºáY’òU¯Ë°aÓ]Šğ÷‚3„ „äß­(]ìÚé–(ï¤³Š2Ó½(=¾^brÌìC¢áèu¢’ÙÉl!)fB·T@^Ö¸Êû$`Z„ØL¦:”GÛ³NKŒ}í_×ÕzsL²;•û†©4âĞ\’ \Rô®§Ûğ<Â<@¶s‹xSƒhºN~àpÌÚÛ=†}æ……¶Ái„û°ƒdì<×]€¾ËÆî¯f×Lğ•KÛ5T[0§áÑ+ƒÉsgRæíÍ…é¯§4ğápXøñHÍ-Äur„ùB´9˜Ñ¨tÍKûø(hìâÉMãèbŸÓW<IØúL]÷0[úÀ¼şĞJ†ÓÓóŠ¿ÕØtVÙøÿ“_†171¶°şü1myUC†.S]ÔŒ^¹8YÛ7PÂÃÃJö~~äšİİÕ÷½Sâ^µµ ][_;AsE&<«2jl.“pt[ØËä¹¥W,6E®7„¥Œ/mğ¾]ãÖ³—¹£ı´àóJ	mÆû‘twÄï²m^æùoimË#·C¹ ‘ëğ¼e-ûûĞê¬*Àò?
Ï_uGğ‡¬7«+¦m»),ıÅ‚,Çğg#¿9í¤vñˆ…Òfã7ã¬zÈPƒö„Uå@d¥âüqÿ¥ÚhbÚwÀ8jo™%‹@múÇ¹i.ØBkvìuŒ;¡×^_ãv­‘R‚iãÅ§pZOa¾ Š'(“ÚKkÖ'Ğ§@0úƒ<,P¶Ió¤€µE®\¯ëğá÷dH6"Ê3E%Ï ­C6b=¯Q2oûÿ·Œ!WáÕXPWl×/jxùó¹³CïÖpu8(T›Ê"ğ^)%6i»XÍP®»£ıˆşL|NĞ‰N½ñöY±Å)ÈãõZáæWöÖt®üğYßşÂÖµØ]r¢Ä^\ÁåPAçã¼U×ÚÀ,£ÀÂ1#Íô!~>=wdÒyº› å
@Û½nm!­­-IéÇOÕòšq`Ês;#|÷°b÷v¸e¼'ê TĞíÏ1«Ô6_<––èİst-k‚3t)‚`×bğj!ÍmJÖèÆ‚<iØóbAôˆ’B´$iÂm+ı’•>şîVGĞ“ûÛ°n…Ïh½Ö¸°•Ñü„[0rHYO
œv×™Ù-”4õi÷2« 7—N+Ã9Zmå…© U¥Ù.é\ğ™L$8ñRh§’&»8¨P ™®°N©>gPk	%7;O(0V9'™åS#.LvÌ z¢00šÄ€¸-®‰“ûEGQR©ÔñÓÃT‡Zç§„ŒÂƒØ °a‡|«Ãgô­<ivÉ—ÉíÀEÌ#ŒÀêè5XãµbXaø†”†Ça°‰üÜå•D.œn‰çáàã|)ı•ÚLPd™âÎ›šèc`V>÷‰±dÆÈ(´ÍlEPĞFõ*UL”0*vïÉ´5xH
yC3ø“YJƒ-tKÒ~ªÈ„CNÂmf°ëâ¨ñÃò_Ú£êøò/y[
×É¾ùFªŞ()ÕL‰¹°}J¢”è;Ì‰ew>ÌëGìu=št°¤Æ³qcB–ûª:p›YTfjä)
ÑœéY¤@^ã
»"<i}p>AŸÌ¨?Û·=òñÄ-9/ê”'»åÒœâ„B•[Ï/İôñ	PúJ…lB®ÚßÁ¡ƒ}|¸YKo ™˜ò³—Z-4;–‘ìÖ·È4{ÈT†øˆ³ô7·î°©4ùLò•½f1Ãã‹ìš„ºG9Ç=³TŠ\3£íšVz†ÃŞ5›$¨½ut›ÆKÎvËU‡‚ëøã`dE^I9³  Íà²‘¬dAóÏıMÔØÏZşÄ…)å`ÅF+êğõÙ¡—ŠõÛ’I±®ä*Ö6†#êbÀRÚ:<çd„a¨OEßŠm7—]?æ°|e €¤èRÖ=m¤¨¸İÊ÷œ±nÖLqÈÂW~<hN¦™?|s‚^ØÃ,±šöæk@2/§SÌè™@ı§Û›×7wZ<ÁÄ%µS×·#…>é•W%ÍIÙÍhZ±m2e œjàé€Œ‡­tö’Œ8Ç’³ùû£pòîÜË5b7ÄÅdu¨±àk'¿P ™øUiTÉğeâf‘1ÇØ¿‡qåLßje1£¿YÊ‰ÿRËG‘¢½ìÁfø5ì!Â8&¦9Œ¢sRœ˜!jöl½†ïÿg&ŸŞÁÀ'r‹(&Ò†±ªHÀ
¸_ã›$©z£Eíåç¿İrl›ª”€VCØ¥½©hÌ¿÷Êoÿ-!dX
ñŠ$Q´qøgEş­=fM-š”34h.:)şA)Ò
‘üÈĞÈùh/>˜ãÎaœRœ’—Æ)æk¢1#èÈ ÜœÏ*õ×	öìÌ<¦Ø€6nìÿ‘W4Ü{ß	ú5„e„ùC‘ ÄQ_¼©­¹… ìk³ê«¦HKo»ù!ë6¡Â.¯ aîÏÑ¹5;põP<¦”§Q«.z<Pà•LxT [0²<“Kº–P	à–ß¼–»p–å¿Ô­`€ÌÓûĞ1,Å1™ÎöÔvş´ã˜ú¤¤@æJ›„âËRÔÛÍ¡kA#iŠÍç›ê’ØhŸ ;Ê¢Vaª‡øØ}*¡æ±@ö^pìÓÖĞ÷0oRÍŠİÚè™NÛ"Æè¹wV‚XˆEcK˜äyÙµ<¥[#ÿs‡—ÿL’=¯+Aú„!–GĞµÆŠSòtyä©JğŞòØA´ª†6ófö~aJ»ğyz/–Í×`ã–ÅËªÃ€`<–Å«k5z³2~ Oş£7o<8+Ğâ¤yúe©Ó“¨U‹(C÷İ0)íÓõß ñ6àİºÚ±ÒĞÉù‡i}E÷ìk Ë­b¤ªt-yü³$?İŸe¥ür‰—TĞ$-ëD¥ĞÆh¨ck'#OjTU\îW4ò˜÷1…é0
ÿÁ÷FW”y•¶ìÔ”py¼j,°HÁó‹eZjşÁ£¥{ècRªÁ4w¢Şˆƒe?ƒææ/ìiàN~4#u¸!ìÖ}r›ï¥Põš¸©3MF˜Íª~ğmådJ†Ô[şEÁS+zîˆ9‘¡FY\/s¡QøséÄ§p¯¸„	Zåvî–qÿ\ëTÁIÇfÒ¥ÛoróÏ¿­Jw	xöIj‘DÜX‡´Ğ‡wÚxc®ëaóäÉ    ù´[õb şµ€ÀØı8±Ägû    YZ