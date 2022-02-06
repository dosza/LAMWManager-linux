#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1787152970"
MD5="cf07ddeb2f27be63f0e677e1ea15d0ce"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25940"
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
	echo Date of packaging: Sun Feb  6 20:07:23 -03 2022
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
ı7zXZ  æÖ´F !   ÏXÌâÿe] ¼}•À1Dd]‡Á›PætİDû%w*t?yc«¾RÚüóy#›EteW"íËœJ·¯…¾6@³U^ÒV§&V‰¬ƒ6Á[H^SÆ P‰W?(ã—I>h4Â®MØ²½<1²ºöVôXS|½Güİc^È.+]¨Và8~(®Ó¼Ã¿ˆ—Õ‰eÆFıIäò!w@åàSçz•ÚŞê’e¨1»Ëí¼â=CÄfı¿Ã÷éH4®Ê¾h?ˆ¡ó>p+ñrYRŸÔÆƒÆ ŞøÖFÈ^P)r·öI'ÉÀ’‡C¾ÜˆškùQÃ¨ïi|j„õ©ü)™ëåò¼ª‚TÁÈ‡EN¦Ö¡t¨«s‹ˆ@Ë#s²£r[!['9¬/Ì,dªø|s’7®|¤uÀä¥j‚÷ÆgÅô"Í/[¿DKşOÉàÏ^Ş)ÊRF”‚Æ°Ú<p5öY§Ã‚ êIÂğŞİûbÜò—¦Èm¯Ú]M{}Ğ¸šÑ7°%YItâù¿ÉçvF$ûU}óÂäùú‹Xã"Íæ"ÁzĞŒ	9q™N¼8³ìâøåDFM|Ş„r±§é;J˜Ä•ºƒ¼Î«%Ûz
‘‹…*×+BŸ–b!¾·U)Ë¬†Sœ¯På–ƒª[ãrkø‰[½)´ÍªÇ…âà{áG‰¾6dXë™eˆ¢w~¦È½	ıÍ ²”ë
õr%¹6+÷y7Í…Q°ërP~èòÊÚ­»Ş¼“ø@ËH²wTGˆNPhkºÏ‹äÌ“OÜe= 'ã‡çl#Ê)/o%V]ù-;z¤¦ÁqsŸ·9jÑÏ¥k÷ß£¤s†Å˜Öÿôş=–òú~öĞcñŸÑ«”ùĞMıNŒ/æ|†K|BBÍ]‘¥>^nîY7Ãâqécuğë>]Ç¢,N[Œ¼`ÔÃQ¡óÑæâzG’½â".weœùê¿oĞá¢@MšsîB(<ö€Ïïø;FšG‹s„Rş±¾”øÓú„i;>î;‘»„¼FŸ'ÎóØîQ%ÌJµwüÈowøCF£²‹«šÊé’áÇÿ¸ùYˆì³7ÈˆÜgÖõYM7ı@"‹t4y»Ëµ V‡±ŸøèøÎĞŠ;l6›Ñ³óış›Ã« ‘Ûe“ıç™NÆ³·fuyAPóI¥N×`¸aµØ‰µ5 <|@c¶6MóK7é¨˜föÈ# #ñ0Ûy.ÔåÜ¹ÄôÙvj¡<sáğ„ˆxwGÚË¢ÈÊ†d525eÌC&‰Ús&âI‰?…î}õ^Z³Z¯J$N´@ìéÑ-CÄäpW8u¡“h;{hâÑ¼)Š_Üè î
é¨rÄS]ëæğªç3üÎ‹|=ƒÕ
<QÏß\Ñ¨OŠòÍü:ı÷TMÔ#õøÖ8ÍoLÆm¦o³r–Õb{½Š)e·Ó¡­h¾ª`ÁDÚÃ™“ÏÒß±ÜO Ê¶¯—|µ.¥îÇò>fªïçez©@dLÿuÍ˜]¦Ñk÷ã1Äbgqh Züzqˆ‡Am@ığzÇ´ÌLÿ:¾xxÏ aÿ¡?:-d‘’€h"mOrÜ‘„ÿê+ÖZ Işê§¢!F ^İØÛ¡*KÓRU–ş¡K²ƒN%îƒõ1„¥ ‰»9Û6M5MK~~VÜ—‚˜Ã=“î²ò²˜Jb¸PïÌ¡â±ÁT\'Ü¯¡ŒMDíKqÜ/A±ë8e¡0·Z–d;§§çmEñóB®ª±÷gp^Å»ßg_ÄÊ}%Ï^Ûc„ ª«e‘®Ïàl·E“u…ş¿xb§(,©UàkDğLQº3%çŒ~!%Ã²£1@o+'´çnAõÜ\›E£ßÜCJ½
¦•F›émE£ïõÌ¸(T‘èÍ«ÿ › 'Â‚¥­U¶â`}B©î@µ¥B|^¼Mª³F›åî™Ä¾si+çú:
²pDÁS+¨¥³—‘ì·”'·òƒ­é=: ÎAèÚÈÓÈ/w¤nÍIK× _Hâ~¨v„ß+²tÚ&–5•rÏmï¨âˆøÌMñÂ@‚ÏğòY%WW7öšŞ=”ærŸ0yã>O—í“ãà§ã.²½á¾zŠ(ç½a¨*Ud?±!ºF‰ÿ€¬åcŞp‹%Ãgñr¾-¼Óz“’/RXO­ <Ğû 4¹öŠ1ò"VØÔÜİjNØVG?Nİ2HªÁİ4Iú¬e™/±NŞ”–`D„ØUÿwB‹øz‰×Nó;˜‡ÅµUë¶v“ë´`%|N«q‚éàã>é g/»êºï¸·œe€ä²şM»/ç°—ïş—ìªğ[l>2İO aS¹€Šˆö®£Ès_±KÃÍf9ÈTOjîé?ì1·4ºr<$wÜèë¹úl÷ë¤\k5u0@!å'Ú§ÕŸ(@C=·©q’'ÒÛH’©h×èõí	ı•1»ş"&‰ş^Ç	$.‘Ò¶¤¼„gÚÆ÷{@-Ä’d& ÛùqÅuä+¼>ûßÁ$ô"“[cúÒ
×÷WlV^6ĞAwIGŠÑ'!¤²â5İ3/4µ™!Qä{)ãv[1X8Ò7v>ˆlÓÔ!V´ŠŒ¸ÕKxêğ‚ğè¨ 
ÏGš‡ÊAì¼,ü¹<*úAÇ2ô-!®´ÔvÙq¹°Ó•NôPÌwëFNF|B×têŠ¨ş±g‘\9ñ€ò aóÈj›S:S³Í$LÑú_"ƒ°j91,ÓÑò¤Ã«
¯gËÎÀb±L/©Mr´¿T«‚_¹yO^Üµ	$…%2fĞ¥Ì¥„ï'´å|sÚX•Ãg¼~*Üˆ_M¢ü÷·¯İ¹ùÜ`m0ºOGtQKC‡IÍ—q‰¹‰J¦ÔaÖnç¸CæØSÍØ»Èğ²yµøïİF60¬Œ[“…
¼İY596JN~ÙXË¢i2L]¹tïRkØª/ÃŸßTše¬ç¨†·ˆç m›‘›`ÇJ7/´Ò„ºW»³+u¨“Og Êg8+ùÛ+AÍÀá›UñCÒ“‘—Jº |„qÊR[rùĞ*¡¡<Iı?ÅZc)i\BXĞ¤ÁáC¥ŒZ­CºlnIÌ·j­ŠnÌê°‚…Ï¹Šº`±4?/éË¶^50—xwy.M)?QYØç{?£ÏÓÜ¤`v)¦!àà¿óZÄ€}æ ­“ruê¶#sè"ôQ B°Õ˜â=ê(êæu#ıÕØ_ùé«~ª-è¢?QÔ¨ ]ì072aF/D9Î8S­ûõyğ„æpi›#7İ¨-ã÷—Å¿ßG\Ü‹/GÏs˜–ï`WHº+gRı)h(êM—$äÙœy×yu‹˜IÇ–ßÅm¼ÊİİÂ›¡V¯dd*8p£$Ü4%bµ•'æ‘á³)£Í=‡)İ‡`~ø‘ò&Í&áê_}å÷9~¼X½ôçö
–°3wˆêñ€-î÷­@/ÊŞ0¯¼Â&Ô•…‘z’4
qL÷ã°Æ()tÌ¿ØüÀ£‚²7H´”n=ß-ŠX¼.N*18ø¦*)k¦¡>.BäFMÜHÆıÈ{¬ê¹ı±2Ÿ
Éõ±MóÓÃ¤{t.]n“ÅHsÎÇ7A]vÍmñœğ6Ê*Åóÿ—ù]v…fÑ‘°\Yuƒ{Z—ê<(¤àÜ±pŸ
	ŞuÃ8Aç~€'ò‡{Òd4:X†iåÛ‘œ=Àd²ş;½v¯÷ Êü‚ZÁñQ Šö;Ne%…d¸‘–-£$ß]VF©aO˜Ë1¼€^ÔP¢ÀÌ?@“lª“·ut¶H”U2jqÙÈÂ«&Âª;à×Ğ -—‚#U0~Æ”9Åô¼f:T›¶m‹µ@ûÁ¹Í®Éd¹Şÿ YÄQ€ ‡§U£ÃR…%üÓ&åg
¡Zû8¡P&³Oz“Ã5‹cD9CÊì«›Á°”hã¦5š¨–xa¬W»Qú×µÌìAG‰îP^ˆóå2B ƒIr9.Xş¨"9^»píqêß‹ûS;HxİfWÅK}ôÉS mA\ßË'Æ”2p¨Â·°¾—Ü‡3fÆ[–Øåş'(í½î±Ê>GîY—…ôySçä^åb«IkWŞmÑªÇT”ÁM¢ÚTİÒy-)c¶Z“ •pg¦P?ß\qìÕz.Ğ`½tü#‘êÿÖğ½BÓ¿ÇÑ­•iNÓÍë´f.ğQàAÁö¤Pİ!J»ÛHo¼¸^Ó²EëCç*¡	!4èªw¢3&à®ï¹:´ ‘²*Å–~š¶¤û3ïò¢á·òã‡z%R2µÁ+<_÷3§‰Ê°³S/ÿêÑ3ZÀÍ³7ê|ËÕéË½”+l„6@—ÏÂ
û±d.¼Ç-dñ<m'7/N á¼¹-1¹!fc0ä#qd—xºé
¥ÚL«¼s	·FŒ¸Ìcw|8¿öl³Ø4Ñ>7Eæ›ÄÀß­ÍJÇåoÒAÆ”uØ!fÉ^@š˜eaµuÒ	áğ§#ÿß;=‹îÓ»	½SC\Œß@ÿˆCşHñ°Ÿšùoõ1¢¾¯zèr8J²ş¼^t#A*	~`ïÛ–şJô÷èïÇ—AÕ 
Œ5$í.¹÷ğ/î«m|¸$3Şß­ò¢õe™ó„¶Émy]lEÒ(ê43ÚKà¹ßÏÇÁ1´y·aš
“Íˆrû	ZW.e™xuY´•šU[~<p0Ÿaé*>¯›hFô€˜/°Ä··Âï+{­ø,eê`<­¿Ÿ±q
ŒÖÊ¿ÈŸ(¤€¼ŒsKëß(G ß”óSëë€^¬Àş>ğæc‘D’ı
,¸ëiR¬ğ÷[ÚÈšĞ‚µ\cÂ(/MzW
FÅ¸iœO+ÅÒDŠíQÚWÇW—1Œ5¢÷Š&=6Ís´biæ:2@²£°åÁİ£Z>ƒ˜±‹À­ºL©Dâ®§·"ÏñX@&1yËF8c@äK\SË‹¦°kgŒ]©1ŒÍ$‘ªèDÅmÿ3ÁDr"ÚÏÆ6DŠ¿·*ÒÏÙöÍü¨”Ô2[ƒR&Nµá™½ó<‚€zD«éVÍÙîÊ0glî6gÔ.gµ“ƒÌÅ¸9™@Û]vç?Ç)±c.0JkµŸ¤‡§„S=aâ‡ÎûÌpî(ÔüÕÈ(µ‘gâS×Êe¡1].æĞõíY–¾SÅ
,QÜÌõ`™Üƒk«uIµù¨4×§øŠˆü[£{Yk!ÉÑRÜTOcziòóÁ¯©3&ÛÓ#²¦gGZ×NêtÛŒ“ÆŸ«à‰èÎÃñ³û.-ÿîÆ{a,Tïƒ<×dyÉ$hFf3uMïÂÚH>ó…¤pQímvÕ/[â™	ÈMˆà4¸…qÂEX:¥ú.¾Uœ7´G×kbüÍªsº°€ZkóTÂè´aaè%çP¶Ï>¬QNÑüÙá(¨”§Şô•@gØ;¢~/yá/±µ4¯(Å¶2ÊA*Y›º¸\gw+l
w”øşûÍ¢v6ÄêjÙ¤c}¿ÇÁé?ïI]UTÕnM×	•”­*®8Hf&(í3†À5A/¸ËKÒm©~[@(u1“ku‰Ş2}°êyÄ9SèÒ±XZH«ÃãŞÇ`.ˆëÎ8pıÓ¥|X¯Ò-M¼ÌàV¤¹ø¹8½ÏõÿMëöµÄjÊ²‘šä)¯û¢İ5»Š±Lİî!ÆW¼;®’{T”¦LĞJG‹}ê»u5}==ÂCÌL¦,#4ë®šŸs)W¿ái`9õËnãÀv*4T™dO£ø Œ/Å¦ÈÈW“ö:D
Ğc²øÀ­’×A7'0|rÑœínY3TÆe»ÜÂ_Ô©¹É­	ldó1;ü?Í‡!Õ-mBY¬e&6°ö·6ıÑ
š—õ½Š˜7@µåÁ%+ÍtÈ5iæœõhú¯CÎÀÛ\ªe
‹W<·\ë\>X°…Wî³îÏjÍÿ]ó¬Bñ×‘0D†y›5KßjN'] ÒN•7‘ğh[Ãèu¥µ98¦DÂKa8,:G
—K
 —@¨j[âBfLBÃéšH¾ÉADŒ7j«œÀı¿@E¼Añ¶ë- ÃôçwÔŞG‰Ú¤ÄÜ­°ê „9q!“ü$ipùgI•S×w
~ù!	hyÏó:)È½ó(4^¸W:v§é1´€óİ¾V†í~¥9[$]kº8V&ÇµNÒ^¿b™ãiUãÎ—w¦åÀ×«Ú¦Œz%!—7°·XPìĞvY©h’Dƒ ¢oLñå¹`õfÕÅeOU¤¼§%z{Ÿšg§±;eX˜Cƒ¡1.ÀKŞ£¡¡T£o^Ğ¹ÃË·ç¡Ğwš›:>ƒèúÎ‚ŞéÙ×Z±3xlW>M‡r´ıé`Í¡J;5T
ªSB“=¶c-¥œ?³Õ%‰ x+~õ– ¾&…Û¼·(Åê½¾ÍL™Ş)ºûX—kT$ØOİtĞešì]*›P8ÍSúÑùq©©ÇÒUv^µ66G]Å—º«’²ÀM’˜o:æñš¯j\…–d²Êc•¡Äœ/c ÍJÈVEÑçb¹ÙÍÅ­rìˆÂØÂˆxÁi7×br+±–J“8¹éÌ…ãylVL†i1ò›aRÊ'Të^”øCÿÆî…ËI:?0„˜U´ò¨Fq=Sé+'‰Ü¼á/wZÚVÉ¤!híl#÷ -ü;Kwa_
ŞªH€ĞŠB§c6­Q'"«Úßó¢^6_•‘©Öq¨£¢/ø°÷rÙ_²|Ç‹„ÉÎîJ=§?Q½C½JgÁì–Ü¹$VÜÔ”˜û'+v¤!˜iï‹(1¶1YN9ò’9·ÃUM7Dğ®LÕ)±µw[ ²?ºMúGCê2¼y¨j|ÈÉÈf²ÍG#@¿ø¾òp
¡#¦Mq×Õ<Ui$ªæ•¿'¼Õ†ÈkĞÃšwôÙz­t–s¨AŒ¢—Ÿş\ñÈ—¼pr ˆŠ]¶wõºyôê¯£Í+õ`Pßü0‘šÁ°“òQ8Æï8(ÓáoaË=˜f7ïj”KõBi	.@MN<ÃzL‚úë{†\¤H_h—H:A#©à*·Î}¡,«Øüg¯Ğ<ºy…÷—Ñã´ €c{¬©•Ê¤œW“Å_ÚŠ]ppŞ˜Rù²¨íg,ãR2İ_ì=¼BƒNíØ-ÅUAğ•~SVÇÏÓRKQ2bp¨=VÛ@*OU]›xsN"-A6bÌÂ(ªŒ¾"&û6·bŒ³‡0üâ[–0ùßPq,Àë™‚ÂáÆ]§°» V*éiÉÚáHŠ[_šQ€Ó¼Q>)¹ø$¹.ıkÓödÀ¹x+]4;TózPºE”Ì#¾^cWLÈK4İÅO>¿ÍÉRâé"ØLäô®c?û\ÅŸNÉ˜4—6Â7˜)kÎ€n»tŞéÍ]%_¼ñßı™w”—ÀWB H ›,›|13ŸÎÏıœá¬»·w« ÔúP%ÃÆS]˜šÈ’¥GKÍ®ÓàD¸¨…Z.“]¸z2Â#õxºáNçÇs!ÿÚÂæ†ŞEywl¶—ş˜©ô_o‡~añ½RŞ«.ë{Àº7¦_¼¤âG§ìr¬²VédSXË¦Z˜¯ F)K<mOŸSnãj¡ûìš
ª†Ešµ†iEñ‡@ ¼˜ãìÎÓWøÄ¯/p	ë$"SØÍrsÿoˆ·w*U7bÅ¶ i¤§â3È“ËÆ«¿œƒïºí©/´(«L|(Q)‡ë‘šP;£©:şt¥øÃ.4V2a#`gİ\4©h°¡$²N¯~ïsj’¿ïaëïş…N•Éö5öÅtª‘£‹òºã.Xz¸aÊˆ1šÎæl	¥'YêJêĞ@!UãWKo/eâ[ÇÔy;Ô¬ºâ£K=_‡Nu¿¼h£­Ôêâ[$@.ñu];W¯Ä³×€99áwëƒ•—KµåîåàE·Æë/í5—’¦~ö³›Ÿ²tÌ…±ïëH¾›í9@æ†·ùVo`NéDû+´
‹dP;ˆŠœÜ}7S‰½MûK]W3„ç$ú›ºö¼‰¦ˆÎ4¢§
•¹sy¸HŠ¬Éµ%›şíèïP!IĞ¬¹
pãzÑ¨°{ÇŞM-~²`yèt0D@ñXú›íIş68ˆ±pÎU¼ #×GårEúÌ,ã´ú<Tƒ¼›³-ü>|ã‚‰h}ªğxò.|ïñ1Älı›~©»Ä3¾‚ËìÆÍ4òä£âYŞ2ú{ wƒ¤ã¨Ç¦>¯PH»\´æVÊ»„ñéuxaö¼ÃĞqÈÊ^ı2§Cª#¾.—×‡¯!ùBç²—¢!&^6Á³êóD×˜²8·'ÊK$²ä4¯ˆèIÁz'
ï•D0~ûmı=åW¸ÖkÏŠÁgıNğuèƒîÍ‡GN?°}˜¬Ñ¸XõzÓ/°=ŠïP‚óş¾_,ÌÛÒ$ÊÂîÈwQH£$Òv`&²Öª·EƒÅeƒf'üæ…£!¶9hOÚ!ºİzÌÁ2éœ¶xEæHíîílÇzÀîÑª/R •­*w|Óz~^¡÷è$#Ïw°to?÷Ğ.•e„û	NĞaŠ¤‚
1#åxäÆa£¯DÀ¸ ˜ÎrUï;~<T¤¾– NâK¢¬°]şn¶!Ä}êzL‚HI…®ï7ğTÒ1ƒlÙ!:`D+‘”¨Xe§3rü=9¶3ÆÔˆ¦•yí½‚'†]»ÂĞ–ª¢,™5”†Ò×òë,ˆ3™-_øÔy¨"µBÜæÔ¸‹‰í`V–!]³›¸ß
Ó’ü^P§‘Àm/	¹u«S0Û2Ì£‘Ñ·+¿É¸1ühµ_Z8R*Àş­/ëO#.3PddŞ–èÙjUm#ÌÛñO{>CÑ¡ØIİJ)aÆâ6«µôcGI¯=  G\9Ášıiä0.ÀeŞn\`Ä¡iä6ÇZöZ.áê÷€ëBèáÂ/€Ó”Şt«‡í¥øõŸ«mC%óÍ_Y£ÀNC~ 7®i—¼ø”®Îš5“z`ÁxRo–€ ‡|Ø†½Ù²ÿ„¢¡šÂgi‚â¸¢ğ”%î°êq|6¡ 
3}nàS™ñÃ:?Ì0=|,ü…/¢H”K^L4?ĞêÿO¿Ò9—‰­&Tõfø!\ZZØÎÉ0èáÇ7ÿcxLQ‹f†òwõr¤Hp:E2|ûÜeCÌÊX;ıÙ÷Íäîä´à‰iğ£hï….gkº¿Í’IÕ HÊÙ ‡Næñàlò¥$ ù´nYe:âd>-ıáú;;ÑE×h9ÊqÇÁiôƒ`y‡¢Ú±«–´M±(ÏÒ9ŸÆ:õ©	ïÌÚœÃÿŞ»bç%D¢ÜKt]¨:et…®V|çŒ{˜Ëbe(´šĞ£š·AbÛÓÂıãQ¾ZoˆPaZmWa -OÀZ#ñ#O²Ùyz•/åìÔyˆH_ÃÃ”:Lj¹jCÛåñ˜*>š¢Ÿ|^¿ßeègF(.şÀòñËêÿìÈ‰X²{ Ñë„b™
€±"X¯Ó‡ÓTQ0Áğü4„T`b¹­ùˆÈ¹M8X`/'4ÙQÄ-¬¸k6[±¹R=Gç?í¦hÛ‚)Ÿ…M¬û>YÇ-òş—°m#j†ƒIcB5%À5åÈ·²¢Ÿ@…öš4Gq±Ñ=½·‚:¢ smÌêÚ€Ö{-a¿hÔ1+±$ö ğEÿ`Îˆ»–â^¹KŞ²>3ñwN©&¤\“»öFÄåÔ½­©¹]y'ÿšÒ/èÍZŞ*]IÍ_üCÿ†#d¤çéjÙ=ãVçú`Æ³Ï—|ş5h	¼¸×mÊæ^œ>æ*£Ú{ ß
×ôKâ„ø•*Œ'mßıß$¤Ÿ¥«Iœy¹nHŞhö×$÷–ôìÙO6ßÓOHwäs´+ëœ¥, ò7Ç:‹ß…èYyÎ|AóÃ¹¡®-v]V¢³.ˆÀ×ó®r0Df<Ì¬Ü±ÀcÆ™G²Òv‚ò–æº9f­£´Œ¿½„`'ö=•±L•½árdğ¢I9<7ıÿï³0än¡¨R™>’Wû9I‚|r%¥ÜÓ.ªC½AÔv[> +Üˆ%¯!°^7?·£ó~7/ZIûÂğ ò*å•š*áoÿĞ“¨î­‡œ—ñhÈOfÛDşX1äšz•Ö®YĞ¤ê|g˜GFJ§…­í!XH¤ÜXĞ¯¢=’ØQU¼çˆÉ&cªÜÌD^Ä¢İäòŠPÍµß›ûx¤°Ëä‚`¬·ˆ¾£}æ…ÃN\·`‡I˜v&Œ#S/¿£Ÿ7ÀŠ3Ùv;¥	 ®à¯AÓ“˜â¶Ø'6¬Œj`Å³TÜÒ5ª DhŸÃ¬ÕÁ,¼\”©S•e6&r™Pò–ø¼µ¿ô´Ûù!}ÇVD_Ÿóíå*µ%U³>®%_4f¿®‡"F^øÃ0|]ˆ˜O²Mƒ—3_`!&&5'Ü€CS?˜o¦íòD«Î­ìVmSÙL[%‹gQ;¸ñ†Ğ3Ü›qêdßÕ­{v}TVÅ0á ˆÕÔ ¦w†D|äífô\+ñi0jŸ$ºØşÅ
EÌ\\¾0-°td’ıàP*é³?„PõN>¬r¬ã"¡WP—"FA5Q$ØîF$åÇpqc~Ô"c*5œÅNL`ÿ¡²?ºY&„l±RÂ¡ºÌ‘}á¹=ö,Ë–g™˜Ä‰y¼úÑÅà–Æ0Õ1ìº€ˆ¨†iSX²Ñ:ıÔŞ›?S®Ñ¦ßß©yüsŠŒMj‹Ñ¾¹ q\%CpŠÅÜ}[B-+²ã‚BcÊix¤Æí ‚}8·‘;° kCà‹EŸ¢Áåôh{¯q¶.­p¼¯¸ ÁéÃ+×ª“ ú±ë·?ø¦Õ’1Dø'À¸{3G¦jqï_w€ª3ËïoµÄx´3%t!K)”4>ômÎ‘²êâ2ÅÏ9l¤ÜSİĞÖ²rçäÿZ~3/¤*¤h×ÜJ„”¿—2­ÁùÕı\õÚyÏEÑºU<co=Ó%ÓŞNup.¸é,t¡H?Â¡ÛHï]ê0`Ø¢l[72© ‘„AÎ8%¾ÌnjØL‡¯«m¯Û»°zğåØ³¥%õ?p¾#~cìˆƒË€µ|ÈIÇä†dÛnCõpÕ«†<¥×üo’‹{E-…
3ñ,=OßRVHlÊ½‘¾2r7¶¼1(]Å"ºÆ‹¼ËfƒÁRM[Õª@Eu*ÂE0ôè7ÿgĞRxÃ¹×®eÛÔ(§îÔ$ƒÌ`w­¿7ú—‹(ö•m¹.° bPôĞ3Ï5?æU½¯¸œåÑG ”ùeÎôäÎQ¬¦«+sn¯•wİÜ“z‚é.3á×VÄ]²³K¿fœæ,%¦ÎöR;hYqcÏÀ”À£şm¦¡%uğÑf*†¤ü©ùÊ¿İmt¦s&¤<°M»7°ğä}BÉµ-Ğ¥MöCctˆÚN$’sgvh:˜mHE+IıÀ­Ëwß3…døèS†Šiı°½sUÜF(:mòîÜ8#Z%¬¯5GîàÖVö– ¾…Œ•£ï:Ê¨Ÿuô{ûRp¶üi0Ãz	{Ğ2I%Q$ÒcÍl>ïıŸÜyw%&g?wšYòŒ0™~­CºD×r ´´í‚ë F6íŒiÑ¥Ç0ÕM»‚x,è„ËM×.Û‰Eâåg„ö Û¯/e“W’Šú›Tu×Î¥]qDÚlkdVû›Ú†;âÔ§UHq€YcÓì&Çú±Ç!°ø{¹¾R÷dÏØO(à±êÖÌ—–~©EvG(•±ÆJká[!‹Äƒ~İ¬T3yÖ95Py"ğ·ı±ê£ï¸Xˆì6ÑÂE¸ˆµd›]ÙóâIl€Yş`°Ú†¸B^/¦Nx|ešœ†ë’ Ò—P‡*4Ú¤³pŸE„ùía:®ı5î»&MN…™åæÿOğ*>–TyRˆ
™‚@$/¼ÍÅ„´ûÎ¯ì9®ø“ÉÛÂ•`òìAä?ÓÜxº[á~9A,»¨Ür‘KĞîe…¬'#[iÖ–H7kwäg"B=¢ÎJ„q“ıøÅ¨˜r—ìÄ\«:lk¡´TêS‘­JiÚH?<DÀ_-sV×ğŸP¨XÄ°T16ã3î	E^ÆûößSŸóÏÊ'¤9Êš¥ÚÔ#>`m•2F¶Å­˜Ç"ìvÚà)šXuq!ŒÔ6*ÏY­7›{u@²Á!ÃjW¡l3üÛ·K«Æ‰eó¸hDqÓ×F~»mZ§«d`Ò’Uïä¶h¿ßç’Qõ9¼—Š=€Zş¿&eø‘aíJ@å[şÖõDùº¢äìWôbLù‹
˜úÚÔÀ0C×‚>ê³¥ï;}Å”ÉË‘‡(*ğf¨¼ŠÎÇD	\Vµà2ü°Š8…£?œ5ï’ÀSıLp…„NÆ½å0WÜõ‹Vq®+	›”F–ÕU< "o6Ö^rp?*ï¼åîpi7Ü±}±¢/±ÁEİ~¶Ù:Mõ.52=ï%úLúeƒã6¾Ô„NsƒânœDu)*dÃ§V£¶ªm¬ ø8íÒhØò°&Õöã„—EPA¡HéÇX•á×GT¥ÃÃùæ›‚-{èuXÔâÚúødÚ¨Îu¶¬À İÔà]©™ŒÔ¦c ®ºå'ºí±1” úŠ?ê!ó9’ã±´á™õ­ûQ{§³ğFR#k‡î•ÆÛ ”SçVÄ»î~–Yl“™Pû;Ñíè°á—ˆ‰VÇm­[Ø’ƒêDî•g«*ôK`$4‹¤¼RÙºF°‰ï÷²_s ¦R¡‘  Ş©ÙËbq&×ò,àg07Ï«Ôæóåµœù‡U|£*ªëaºãKSV [µì;´“µ"‰(WTğ µ<ú<¶Á ø±ó×`@Å½ı¥©©’Gşh&dŒ«wØæeB6I`ÄƒşSöÃ¦”»Ï”ØkÍŸD²ÉúÚûlâŸh›šË‰¢¨Tûè-EGo›EJA}|²ó íy1“7Wa}µGm,Ã
Ié?Èø"è™ÀkPå#-/i¯&,‡õ—«¡êhô¼ZÚç|¤[g—Ø%Øa‡×ã‚2‚¾“ıP&x»wÄ.Tlf{Ûfç‹¸”–ÙH£l¨Í–dµ*²/C èô"å‚I›ía2ß!Ä;±§6È7
œØ_¦Â~½~ä½{5?ˆ¢­óÍì3ëËX˜½øìÍÎŸ’ze*8–ißêF£4âh”8l4Ã-ØÙ›Ó¨tAÇ¼äp?òØVëÎU´›0äÙ@İp:f¹ü®]¡k^„xŠ¶m+á‡&€ğÇL°zQ×!‰#3·"wÛ}‰è†‡š‰·D/œˆ|ø÷Ú]€İÒ^€Î«ø­P¤™”ekki‘hıíTæc_­6{Ê&cQ "¤Ü% “) ÜN©Pı'D<j—ÚIÓˆ'a§”£ş4?mM¤Ùbä|úDÍš³ƒĞ÷ŞAjÏi8½-­—q“dæ\ÂírP!`{ùôe'‚!Å™pßòdLÙ…Áº4V}d;¤RğwéÅàŞÓ5ˆN¯á8Áöx,¦ÒCÒSm¥©Ñ«n]÷5õŠªè3GŸÙU·ÅP"àíÑP»Ÿ.„¬BøUwß¶³úËSÅŞH©$Ea¼òz(*8Å×PlÆ‘’]dÕKö±î8¿‹1N%ÎÎbm­VË1ßí1Ij×ƒ÷Æ][R¼W6:(9êg¡¹	\o#ö4ïçŞì~¼3„²–¦agşøôşOˆ˜Ø¨HŠr§7ÈklØ‰ÙíífRüĞh­İãÑ>³,lKl^t“-æuæòİ“î|£c­£±É-lj¬KÆ%|†Š³1O;]pHÂ¨òøæ'G½ƒÔŒŠì¾Æ»f^ÿåï‡åf#1H?µA^õÇ¼ÿÌ›ğAà•)U4Ghİ•¨KoxfèPFgZLiÙÙ¹ÂC%ehv¨ØÃ`B	f“Uì»˜MÒì5wø*Š·®¬J½¤ü@§xXÊNñ]s+>d•&Ø©_ğ“|#Vnß†âå<]†«[<U,£›KKCt?!J5[”²¬‚ê“‚ $+lKzcJ¤ÀsÏËCçĞ.Íeë4Ş ¿B‘1ûÔ9/RüX}õ§–xkÒéUæôõà/OŠE…tÒ“ï‹­c_5˜-(–ä<ûæmRLwjaJH$Zâl»±´0\¨73nãƒî<¢IüAÅÉsL{G‚2×úìé–Œ¥3ÁÜ®¯üÙ«š›Ù¦Ìh„+3É]g¡T§jÙy	çtpMVÇyX7f {¾ÓİkºFÿãïÌŒ=ÿqôó~†âÓ¢eYØ¦¨äì‚ÓÎ°öØŸàU;«Áã6çVİšL?!#ît,İóˆuJ\úídƒ¬ç"tĞRĞªúø¢®›MŸ½İvÍ¾VĞ¥&–ÒbZá™¦±3Sfìl¯7;Ã˜eSŠÆrÍúğQg“(e#„!ÕÈP)O	²CŠoì®Æ_&QÿF¾‚ÖD¶–.-wVh÷N°şJ;âJèºq5¿È±µX^µ55Dû@Ñ˜`˜Ïª@Yúğ	r÷ZêíÃVæÿÒp§¡7–s fÌ–1\Næ¼a¦ÖÜ.ú6<úÍ<¿S¦Ÿ¼{™ÄÙû— !ä1È‘éµW«-ä=9†¦šÀåš†Êç¼gi”êHTß•Ñ:w\7
à‰˜-+L°ÛQlK˜³…7Bk°²¥I<q¯ƒªöÓQ«èk˜D>%zyÛo ‹FQR=g¢Í•/%ÜÖ[†„c¡`™j£Ù-â‰Ò°6òQòá[àñtRÕd©ËVÊ˜~"C;V>©Å2L&‘tPà– ÒÉÔjÎX
-®ú0¨Up]´x:¸…_¯*Qn mHT®¤½AäF.ÜU*<¹ûGT:®pP«ğ×TÂ¸»<İÔtİ|ûÉûÆ±eJKr2¨¯°K)^úÆ(&æQŠœ+¤™"dù“è0…AY"ÜÎ;ç×)â!¶ün„*_wñóĞ“Z­nß¡øÉRÖÜÃ	“íEÆ£HİÅ©Å+xãez ÕŞ’3N#òå/ÀêıZğHö?x~<¼3aşy< qA|È:ânËÚ*ñI=ÄA²z¿ZLWİ.X®dÜ(K¨ïM¹T'²NÕRı™ZÜ*-r	§bëáe1,É ÈˆïÃ|@
•õ"ĞìßE”æ±âÁ×§RÍÅAw’¸Â®é•âœ¤¥©©¤(^õ+ˆL"#×İ¿™FêOmM>sZÆµXàï±Ğy˜âÑÆH´,YÃ†Æ5;ùQºjˆÀ[$\fT»õ§ßt1‚õU¡œá[Ot'–ƒ–¡öÏMAaèò’_JÃs½¹§<Dğóx	T|›ô‘^lGZªŸ	£5;ïx§àÊûã%E¬z[ªçñ²m
 N2^³\c&S²Ç­‹ÔÔŠ:"%„—õ—šHè3şs·Õ| …`ïfâİ²cV‹†ó¯œ]™eÈÅPàäòª°•L¯hùZ2²®c°ı
¦†®¤ÄØû)t!Ãòi!Ü¾˜Í|+Pc*)ÜNù.é¾õwyµêÒÀJJ³‹Üº$1Š:”Ï¢ş”ûß¤~+&^7¤\ë½µO¦×nB"ÙšƒrQÛÿÓÌQ†ƒ•~8–é™µÌıvÁnàTûğ—Äª_òúbL"·˜c¸Ÿÿ¸0Îx`˜9´Å_],Üúz¬Â©¨Ãœ\3UIï\v¤­èŞÖ48Ş=Ãi’Ğbâ£!%ÒŸ!…Í§:ğCˆ"*èÑI‚!Ö›&$ÉÕAŸIVRLëkø
ÉÙ £i’3b½›ntÇ\ğ™ìâ”!Håcãcî®ú÷UÁxW2?'õz¶oFğhÉı©#K	°ÙsxÑªŠ†‡ÁÆA.3™QU8•QÎc¬úîë\òR½Er=6!TmÌo¿ûŸàæ%Xo±‘2då„÷¨ ™MUSù©Oy‹cĞ•r!@£º´~f©VÊÊrV¯å³†²§CÙ>ø¬t;´¾Äú»ã%dÔWJ.…loİE“£lNÄV'lŞõ_×ú³”¶îH$çØ}hï .¿»'x–-zïÏûK(ĞB15S×©ıÔ;¾™GC En¾G5xå÷tÛ‹{mš{h!î9Vóì.HÕõÌİ…&íWx‡£~‡*ÿñ¦<¹iˆCØõœØèÂ©IùÈ`Æ3vGjŠiååf{®›	{U:~S™ü‘¸Ö‹/W×:Òß™ äwı¸Y°«÷b¼†XkH™Õ‹TßÌ”ƒKË_KÑ?Ï¬øİgØ7ù˜Ù¼ïîÿk+î§¡µWÊÄğªZ®§	Ê¡$0#ùÊ5¹9ÍR¸1A‡•_Ìõ©Áûòt%Ukœ©3@p—(K4= ^…˜{{UÎsËÓ×†éQcıu]İQkCC `P#e‡ßè‹/¤½<‡«ÚÛÒ42½°ë…Ì}Å…dğ4ø÷b#œwE²EiÄ-ˆ#“\†‡P£báÆÇNz"TFcBEÃæşd‚ÏZà­Mâ©G0œ^î „°r²|Cz¯Dàı•+¨ç8Ñ"y¬“œIï†<º$·:†.jå­*İYÓœ&üƒeÚ¬`èÓ²FsŸ°NV­ÈuışZ;bhØYX´[$ÚmÇZjzï´*Lõ\¶Ã ƒ¿İü3Êèé·ÍMU9År%ùĞîró*±Ğº¦®oìF‚?ïˆJSiŸÙİı˜’.ÍÂ”|§p.3»˜q8p)Á 7c›‹Úïùx|ÀóÒ<L
'¹6Rğú°¥Õƒ¸Ä`ÏÙ¹
*¬ªWl•ædÿ1ÓúZÄ>ìZïÙãXİ~ø^­‰²%†É¾‘bİÊV±7 -Xí9ØZDy»4„Ïa
ıï;¿õ=HDjÊ/åò‚ŞL–ßæŒXêëŒŒ¢Ô}œÃ†¼pz}2ŸŠ­^nI¦`f3i=JÌ8=ß:†×ûìÙ˜97¼:Ã-G¢Ïm_Çê¨# ÿûÓ÷	î­‘&!WoöIFØäFgñÚ6‡ ÌÔ“CÖ.ÏÁ
üã¼¼n/@ô¾Eè{Ükjyã¨¨ûëÛŒy’ŞQjS<Ğüü?×doıÃ,3HqıÙ=ÏMdæ*ñu»A/8Ö~:…Ü‘¿@ßÛÿ4Lı n¤t¨|"µÁEà‰ °ş"u‡Y$ªuÎIuÅø°ğº˜gŒ…Tå¹·2Gª£´‡éŠŒ‰×•Àhò?\>gq„U½\Öd¤ÇTÁ‚!(M‘c–æeh/,{y;äÄ©“¾¹Üä…›ıåmÒòù1áĞâmGn×¸XJK‚ÀâªòMÕÆÿ˜Àçª¾/‘CvõóB›ô”qÜ‰H&Šyæ@¾¯ŸkùÓW£Û¡*üA|ö*Zç0ô­^çÃlG2È›ø*Œ˜½¬FO…Nqª‡kŒ
UtncFçWo÷"Ä6Äöí­˜ŸaÓòtˆ9Må;YDƒz£Ğ„áeåï…6µif=tHH?âÑøÛ›…©X'.Lµ "×b'. „°æ	ôŞNÏ¿¹cI¦ÙF•tÖsh~N4Áé ßWU¨K«¢ˆ·Ù¦2õ–.¦oÎòö/lá=3YK{!ïO@iµa¨J÷5±Y%bCÜvgëW7Í”ZN7½I*ïƒÁs±Ş…x~F4}ot¡7’ÓSÕ¥,¿ôZP/åü¨eÁUGI©c”ßöÜôï}K¡¨ğçŠ¾OÃ_2èÕ[éyæûÇÈÈ2,aŞ“Ç|r«qAjÄüÄ@ÀèÈjÔğ‡&‚YP¼Õ¥Ã¨¤‹ D`Ö¹Í"Ş'T’Rè@ü…ÕMV!õúHêÕ.M¸}Q~×Cıao½)FîûÎª»œ*[J²ã7ô£""{ÎÀkm^S…2ÙJ*PØcRŞ×T£~šV&H|‡jÿ9õèXŸ«Ô0ÕyDƒIµDq REÃ|ù»jş×cü~˜†H˜Õ:ôaánYaé¨Òï¯ÿi|ëPà¼rŒm"ÿng8MŠ…À8y@&K¶ËÖeÁªÖ¥1bP‚ˆŸ‚«n€bFÒ|Fìİcy.’Œ&/G!G4ÂÎ oƒş±jİµ§éĞ¬¢(â’‚`¿33£Ñ›Ë`é¸–Õ°°Ïr©'óUtäHr ÚdÉQ]ŸâåO¤Ğ>š\ú¿A¨í À¡fíìgÃß¢¾¦Íï²Ø”&QŒuóìn±bã}	G|0T£˜9éN.«Šş8.µ\„4şb÷ÈºŠjƒ—49(¶]±Ñœ
,^d¤b„¼÷0ŸÎûŸ†&L‡•TƒgD¬\Gİ†Y/Q}ƒYÉÀ'_àïç†àœëXæÎ­xKà¶]¿õ3Â˜ƒÚôrÚËúg+ì7¹ÒÒâ’¢ZQO–òßÄ‰kÇß»'/ívïq	áİ4şÓÎèçT{´òÏÊ€v9°§
Nu¾W®i¢%Êw®·Ê¥éÜïÔ
»š¯@Ú<“_÷£+©û’	Ù:S9BÆ569Á;àP®ÌG<W¢À§Ùô¾	qù—l$İÏOeÛ.œ³2eóTÂ%´pä8‚ÉËNh\³~¿¬Ò‰úÁs”Tê¤|8ë£N•ñštØåÑµì))µev_(Wér5—è^ì†N{RŠÃ¶U˜	=®³„u÷Ä—m8±İ¬FÆUYm®â+·GìE¼ŸÜ3D±ÓT©³A4ÇÆÇ·.—©ó›Æ6=“´è±àC» ¬^Ã%ï÷ÎñI®%ä\´+„-¢ßŒ‰“$oxÜ|)J‰^Êÿ5+«COAXë·oD¸kcq*²O|û6x¸‚)û7×kÚó$~Äı©.âpV5z–ô'½é<QêÜJ¹‚–xnlÊÚÔû¨=©¨È->Ï8ÃX‹KÈB5KúFİUeVû1e"
°¬9”»ı;jC
/É!ïUP€¥…”<\3Ûlx¿À¯ût‹c/÷o‰jÇ«À|¾l˜^Ôl~2B–£à£E*BŒovµn\…OŠŒe>ØçŞ¦Lu> ö‘Mı¸¨Àü$U)¦õµ´¬Öz‡8a¡Ls½J×t«¾×0êA‰RPœ~¦²ä–9w’-Ú×}”{ĞĞ-~†—>Z¢¬áŒÃ»¬\”<\Lí;{/lKRÒY¤êÍ}É6´yœzâhø¤üÒ:§PI¦Z”‰Ä$¯ö ªyi½îÎE?¡ Ş¨bN\*y»š>UgœŒa¥ïÑH™ù-ág1l‚öÙL—\½+hp8Ñ{Í´ßè4lƒìt „Õ†$àÕ§k\ági’Wˆ’z()…Íå˜‰½”œ„óÀ{¡	„h?¡Öş’¼§Ğ$¨Ñ³`mÙG‰dÄßÙÊüÛÊÃØ$İÛÌ|Xm‘LåÂ&=Æ
,#7<ÙõnqØ6Çøtâ×hbcİ33b”q9S¤Ğ]óò |]|"Ï_;H|‘ZòãÓQË¨âí(:–À\[(ÂcŸØd':Êª–*roïãb
±[©¶jE·®•Ù| \ù…R£¤ÿ!›Î‰¥@ DxC!¯ƒ‰6ÔêJÊ ÈÑ£ÒŸr² ÜjoZƒ©ï$ÀléãiIQÅ#*³QåóøàYš¢×©…Ü¿_7ˆÀ÷FÛô»èËuƒÑºÀ	ÿe¬ñ[?k ğß-pÖõo±((H˜ÖM‘?¿N¨ePÖ×
şé•U»áù
óZj8Gu±Ì²Ò80î"ï €&U±ƒCæÙ´‹vH}VY&xxIP‡.½{“ñ•TãN°:½f×É:×·~×¦ê© ,5N'¡åŒÕ¦ïiëÛïcì–ÁK}eNç#—² ·†öJ—_™©Q¢›™ÏÇ¼°*uu
OMqeuh\c˜ÌÖFd3Ï—àwÕZ‡uêµd¶=dQÿ3zérÔÿÆ©kPæëÂĞÔ“V£7¬èî7J9&·•¶º¦¢ÓÅ†'Âqæ­§_:ˆ­,é±í¬ğ6»ÚùéW'ƒ.GUœâ”ô/ò²èV[EK=>Pol—ŠzcH4àú9¸BR
æMøo¦ûê/©ßİ‰j‰¦.NÒöğªAEOşÿ¾Mç¢8ÑÛåäJÄ€è ƒıS½‡P™Î$,kÛ”–¥èÑ3““KÀº07S"\¨P\!Áçm,Šv‰°ÿ+˜5æŸ!¯˜5”/£½Ag.b–@~=ö³j~{54Ä µéË‘ŒS¬gŠ?4¬“¹Ğú¢àŞ¼Ydƒ¾Éœ»C¿@Ÿm±ÕøyxtÅ8Í¦böºJs€7©ÒÍF¨TP(ºC­œğÌÛ»æ¬¬˜ IL›ßDzÃ±'¢ Jt-“”ğwŸÜ5 ÆÒi-"Ï˜îZi{):è ”+ÑÚ/±*ÕÃ!4ÇMÎ|C‹¥ÚŞ¤‚"?—úGo
£ÑÉŸÕ3+,ƒ¢ê<!e{Ì‘7£lXŠn%(¦¸Òäass3¬‹÷8/ÿŞíiz¡‡M¨Ø)¡·¢ï,Q/ó&àÇß*ï-‡j“œ ê¿ |é¸Ã¿š‹`1g#ÿáê
c‡µX°è»°É™VŒ¾åjXÇæ+Êü¸œdò©ÉU™Ê”¸ß^şñaø~ÕI;Owpùs×+º/šÙ+OhU8é*tápIªÈÆvcQyoÊúÊÀ´ˆ9[âH«0ê`+%Cd5O  Ñ‚-Ç°^ƒ«”Ÿ²i¨ì ?]´<¢#‘İR
ëX>Å"xÜY"ùP/ÈìğEs>{ˆ&À&JÖö½1iãæe-u(yP
*×æ‹½-Z`C.+h—¥³ÇzÔãŞÿB›ˆÓô¿—”=÷ì~ë°tQêN–o†!Ï—æ´î+ÌA¯eëÒ%ÁC™-MX{ø.1ºc×Ïzìä "û®WK;E‘—ÀÄL-Ş>3r2ûÑB¹Qô1û»ş…“@j rIíï@íæ::~	fÉ’Ó7íh¥/ÆÿãË¶tV¼7¼ùğ¯ ³ºg˜òª_¥äŒSx´Õ1Iûõ±È((íxz5ì‡é|¥ÿóQIæ)Ù¡À7Šâ¹<ÊÓ“ I´…kè‚c¨£¡Œ`7­øäËğ¤ê·Z¾ÑysCíÆ%çîÃøÒ=õ1d†€—Rşå%õ}NÁ<v¼»fp˜DP'B^àd+,T´—¼"ŠäæÊè1&q0'¾x®’)0®è¼ <˜‚2]vQ¸2<øí)¬äĞÖlHH6a¯oÊ0†êğC<Ù'±1^ßC=5ñİM›®ø»ÿ4«óRKJ®ïZgWÔ—¼¡®‹¡©<ñç+ .vWu³¦ÏubÜşevz)÷A,«–'5Cı?j\`Ö¿?¯Ñ¸,ç"­Ig•*µ>%ŞâCé½EÙú+_Ì]çip4µ@îi—,F¸ˆ+L y/¢O¯‚ç…Ï¢4Œö÷ù”ÈlßòöÎfÃ“ı°İ#5ÑŠ6Z¯+î:2z4ï¬:˜œÂÈ·&ÆôY 0!c¸İfƒUÿU£´òlJP
FT‘ëKF ©ş»y›ÌVğº_‹€±j„_t¹¨v
ô_tK_ŸNÉX»PóB‡9§ñş"úC8Ç¢D>-sÍ~Û(PÑZà’º!‡ŞiG İÃ>Üí‘ÂøMgwuŠCd9Ü
Ó:¼¨Q§rØº’lĞ
 	×Ù­^µHà½¤s*eoİÌªT–[¸^Ùntvh<(Áî ÎHx:ãlFâ™ƒøÕ=ìÁ8JŞw
 Ù\ı¦ÄÙ®öç1ş[¢ôÀÀtIR‹3;¦bç8Ûé·½ë	¼'*°’µX8+
aã&€…iÆ±<®)õnuƒ¿Ò‡Éoé à«?(ç>ŞÇU@®·1®ş"¥\ƒ‚Ë>c»F vŸ«“S«aQ‹

a<Òì~z;A}>õÈß–l¹½‰ı„ÑÖjbø"-(Á3ØÆSà3õ¸­:Ä´1ÑªÏÎñ„+(Jcê‡rœ¼ß	1kò˜ê!§2¸>¬$«¼©ÑŒËCV58c\ãnÕs†ïs«ESd•I&Ó|oßÊŞ"GÕşiÔ™è‘ö&ñE	?ç¸ÇÖBjê|ñX,ÔŸ˜‡Ów¬‘  ÛÚ 1SA5Â5–ÚÕ1Öô0êcĞvpàÌ\uô‰ìCá09ÿß—%*5hÀƒ½DÁV	lO™äŸ™½ ¡Fæ/âÉnwà;ÖŸŠ?Ÿ5øÅ8fNßÒ¯ïîF
40„„sm0®†k[ƒ®ë¥õ—ãÖ (
_°?ñåzÜƒ1¨Ÿx
3´è^'¯ùÑaZ‚@ø‘ÃéÍ×ÀìPMæÄK8}=ÔåÓ@TTÀtN»ÓP&·Es°Wx'P!A8
)ÓÛ¦¡$æ¾+’Ú™h×é¶°ÿÉ»R34ëÓ Aû¼«íåØ“<Mğ3ØÍşÅ(`ÃÄ‡¼g`y¢|@Ã`tzUğjçÁé‡Ì“€®ò:ä/K~69şa4<‚Å¼}5ĞÛ-­ÎÂ0‹â~JeûR·[±…p]éUx¿—• …;°DƒY5øZÎrÄ#xJ…^ªĞ+µ<E¨ üQÖãw2™ÚñäUšuhòñ]Ò½sÑ´3×(\ú]…K®¡,TåÅ#Œû4¶óZ3#?e—ø¨€c	%ø?y¥ÊÌù]ô'­½k„ƒ”2D-%?;íñ]Ï§•±.4»†2esô Sp½Ö¾ì*_]hgy“â-½‚Ô«şĞ”Şôóªà©2˜që(¤Bt:ÙPÛk·pHÀ›Ö†*ÓaGå0—+_9~L ÃÆ0t~"i¥“uàœÃbtUz3%Döå#VÈ\æ¯Q-Àoä ó?Fpİfq¤Úˆ°&ÂQvî?$buGÑG¨FõòÃ¿kƒ¾é1©®­“¼êšdYÒnJaâ`×ÅgÃª&¼µ	ãÙåb%İà]
˜®g@¿\L#M‘HÇªRFïG¸èƒ!î±Ù´Ù4"%ûÑå¿şò•õæ(Î_
Û$Veæ¢u>­ŞFcAŞŸLúhÜÛ›Ñh–%D Ş©ÚøŠ†`¾€Ã!˜˜ó•´IIˆ
AŒš¦awÇ½øÇ6H×GXödAèZ#*v1pÌJğ¥»&iÂÙ4: ş¾BhõZqm|r\úrènú5:U y.Ó9àVè4õ«…I‡ì~¬Hî5jók”Ÿô£şUIæqÑ# Uç#§ğ?Ü·>RÉ{™Ö`[ÛøOíùÓ	ÖÚ[bàeeÙ±çr~©¦ÃøJöñöI<r¥°'v‹KÅ
ß˜¤HF=~z!ü¾ˆğÓ›.SŠ#5|'#µêê»Ä^Õãô­îñ¾<&\‚0ş°|j…ÌZK6ú.”êñ.Äşo\‹5+¹sÜ¾È^fd Ú”=äü_"•“! æ$ÆŞ»¤v”o6ädWÃ¼ĞÎ¶P/Ótpîáãä(Äãœ´<h¸‚tDÃqòĞ›v4/†<\›=+yÍ‡1Q‘ñ'LœïyDÎ™¸Ø1`—õê	ZıÒœYÔ8fv!©(eoU–Ôç)ÖGãf,ã7yÛÊ-ã«Q±n"ä§ÊÏ¹¼cĞM5»ıæÓha&º5Eık1¼|ùQy1GwUğO±Ì&;ÊÑØä¨â;áE~Õuâ*m³áû´¥xS*XÊAt)îüèY|Š‹b–?¶¾ô÷(èÊ=y¼4®Şã^’Ã‹‰n®„e $86ÿ²<Ó/Hr¬v@@äNwu;y[\“ Ş¹WŸi&xš[Õ1ù8–M,ÿ;”•5N°†ñG4…qóû¾s&7'ÎÃ$ó†÷šEï®·ùC¸°kÍz&?ÉI0‡§ÎÒóey÷Ò·Ol¯D¢šâD`ù¯zPí„Ş	Kü'G‚8ˆÇaKñö™ñ÷zg_¨W«Ç0ÌKŒ+—n-!aÌÁíyà÷0[Á«qÎĞK—ÇO‚üWï¶Ç«¢€‰<ÓÀI-³·ÊÄ†”oIb¥#·Ûä½|>TW2Äu	ÄßVö1ofæ»ğ¶¢A"Ã$+¯Ãª“7&‹á=cÙ5XĞ®¢œWy¬|R4»AÆ*v"ü$z’»–ŠÜ£”kNWÃ³Cd§7ÖIòuÍÌÄedVûÎnÂšÅ…;WÇo—§²qpÊ¹H!›VÈ¥¯ÛÉieWYH¢®˜Ñ_Nœ?+‘ãdo|b –aÖÆ‰ú|hx2®;j*±”ÉS#”GZ¾´ú•HÔ®u8”&z>i\{«ás¼7Ğ’²pÕo–™_¶ÅÚ´¶¼èÌKíˆpÕş;O9|JL‡j#j!W4}'Ş²„©Ô”reáÄqp¸T,CÏ6ÔÑnåXäí^$×¡Ly‰Rí‚ŞÊ:i#NcèoÖ !Ç0à$ÜsÌÙå9jšØ•ğºNÂ4­å2—g:¬ ”ó[hWŸ6¯³qçnË	Ş‚>w=b\”ŞQı–÷d«ÅÃ&viå‡¶ÁÁ¦ï] µêÎ³.rI×´UFIx7zUSXåâ2‡:
‰À"_Bë(®ÙUm¤÷8euEË\wk³Œ[„÷úkøÛ ·%q±D+ `ÍÀnÒÛu.ij¦"Úú‘dİÓ,‹<“M$xÃÕ¹~²®OD{Œ=LX0)Ğ#µ[GºŒoê#ìº'Ù[x¨ßĞÌõMüŒBºH#ÙÄ%Pt›†0’5Š×÷ËJ¨î‹59pA²ÙÆ$fLšş0~À8ÈIÓ¹ îÓˆù1¦½¬ _úÜ™xf—uD± |ÍVD?<â$1ÛI~+–1¥"Îv²Ü7‚Ğe)®'M¸ŞírÙãÄÜ: ^^+èø_ºv ì&5¹O<6¯ÿXŒÚ¥ÁîĞCE`vn¸%úZ}¦5p§ÑÆ´P¾ó/´[õ‡ıŠ4Í'ÚÛ{»´”¨v6$ûVĞGÿ¸H›ôåµ¤<h^Ó•ø=èAÆ‡F	‰…kA- ²d	ô¹)ÔÊ<GÁlV	±Š
!<ñcèziu¨})ÄÌ¬Ú¾Ş“a7NÂÁ<ØbéÙÌbâÃ¡èmd;‰ô\`®«Âùƒ(8aÛL­½n.íç»f:Ûµ-[÷s²Û[ggòW%"öI èEğ]ŸÜÌşÒ;Ùs:Š—FåÆ'ÅÿÚ˜¥CT­+Ä	=ğ:L2=Êß½‚Áa]=å6¬ËuŒ2M²¥Î8¬÷?£ğ1n,ô‚¢aQkÄ/`MŒğïf± ÀRá$HoŠç©'VTî ­Ù®×ìåğ/,\²uê}ÕìV„Š7â¢y×‰ËŠËó/ÄBGoÙòÌAÕi4*/êJ‚ã,£qß£[,5Äé3+^©4™<U£øÚ@éÂ>5ù#¿´\™™€Ô@1¬a¨%ÔjaÈˆåô·cò+"ƒ"_È÷mcmÜ9© À…Œì<¥Xñ>UÖÁ 3ë&ˆóûiğ$noxõÅ:ç¹[ÚOT®€»\y”}qm½¶Av6í£;NF9A¥OÍ[]ï#+B] }}‹a½$QœÁZ»«‡µÀ„(W¾^?t Ş²hıÒ›5“loö¸´dÂ4,ÂĞè6“íGvĞåÆ¹ùZï»#xÆl‚*Ù“¦U6«)7ù\œ’‹q@}ş9ZÏÖX°ï„½>B*\©3Şš5àáS9L…#»ûQ&Y!V«E£ç8Ğ!æ_òİQÑçA¸bWuŸ¹(fxlŞ*W(€¨æ1UmÒEÕ—ñ¤ÎuM»õFº¿HfÍòTß
ù¨\Ád–Ë»ÊŞ3Jäú/\Ç4QbîaéBmTßè¹(¹2Kòz«l¸¸×«”É›¼iî1ìå|¾ö-Á›ÚÆiT¨¿óHÌŒA(<_ıw¾j^İ‹¶¬˜­VĞyrÃÀ@`j"	=w(×áãŸ$á_lï9pKpwc‹j$É[L˜Ì&±Í‚x±ÎOi÷-—M6íJt1r*²ÕD-êå›ùCƒ#I÷9AšKíbñä²´#¥Y,–šÒ°÷boğH›ğ/SĞ¯@	Ëçv*9¦CMÊÑÈ†[›l­éYT+‹Tëòa´Å¦,1‰ƒ¦‰xk ÷9X+ÏdßQš?Ê#¯XfÈ(‚[Qæ¬×rVÉÊKùq>¨3œİ)<Ooë…&˜b³Â”YkåÏD—b	{\Oˆãn*Œ€ş1*‹€öÈ6‰_ø&ûx^e†â(É@2¸à–¦ır0•Ü’Á6w·õ_Œ)(.$õ¼x~&®¸
â×™ŒÕÍºo¤}PDx¿õNAğX%s<HM(Pş yœ‚á4ŞBk¼ æ:Ò‹B'ûûU;`«Zmµ+,*Ìªé±ùØ/ĞaÈÿy°*×7f|°a«JG‘†­ö#Â	Ï¡½™a¶&”B»ì(Ú¥a€ŒÓ<ú…!ï’¯4Y—DÂ®ôâÎh…>u)9Â#À¼TôË¨Ò<‘Ÿ+ ¿—ˆµ¸‘	¦svÕÅoy×]Q­î,2‹t¼ª”0Ó /Z·W\zm_²¦\¾âFuR••yÙ‚rÉ®äF¾PÕnCÿáÒ9˜ëK«÷kÜëRÑ|qzŞÃÜDx{C¢¡ÿ,Ûè†Œ§{Ì¸"Q™¿H™?¥É¶Á×ı‰õÉ ç¨è5b5¦%Ï*oŸë‚2Ev`,*B¯ñsA™r<S¨ ‚ˆÍ|™óáÿïı=»$IÒª=ĞmlüA“É;)ÊAq
–¨­YØÎ7x“BU‡Íy¦À).)j;¥'/.0×5Ä
ª®~ÒÛŞB«ŠÙÛß~‡­ûë½]zÆƒØ²ü},æÕÄ4¼ÈªP©ç³1ïç•5_;ò{@F€DsNKa"K´”.Râë*Fû$¥%‰Q®r~¯BWªMÎ+Çº9Åğ€¿	=gª‚FpÏªû¶¦õM$™ÑÆøPDBFÌVrÉrî*?	~³"ï¥Ê–!í†›åKşZ–¢»şdêÒõF½¶AœóøáÕ97ÿÑÔ›×Ùïcån
T×¸­Ú\_£‡UKr.~Z¦cjÅ÷œ2,/ø×I„Œºİ7˜^UñªÑ†Õ‡¯œ‘áìª}‰ú]§b)‡ÄŸ™e X…Á›¨J°D•ñmˆ­Z¿/]ÖMÈ<¶}­€»ˆÔhĞÂ@=:3¹yE¾SuÚAØQ³Ü¦¤%#İìĞçÌL3_!‹J-XZ¨}Š#¾i`’~o*ë;ƒÄ(giÖ´ÔÚ4ìë6áJ%‹¤¹Æ¤È/ÖÆÿ'í]öB³êPÉOP)…ÒáÛÿ·P²vf)Á@:‚';_l™Ìyß“*?WBL÷Ôu”ƒù,Í.NjÿZ4D´®™Å	ÑçpôÂ}ÎböèwóŒ>×ÉD*(â—’Åù’ªéP×îÚï‘LLÌÆĞšçT“Ôµ"ñÄ‚äNhAá{Òøu&ç‡zuçd†Õı‡™nåİpAu5Óš|áu
Yò|©ïÒiCÔñ)Ôp¥´J+öV®I©+­°CNlÌƒš:³´FÌé.Ğl²T5^Œf´ƒº^¶åârnF	 6ˆ{ÓŒ›Ú£ïCÓÂ¨œ¿¥h¾…ùDš[X,ß{!¶ó1Fİô üÿ rí•-›ŠøYM|£t©èÏ4Ü‰ÅÜu[²z†€Ä©VÛ®…Œå›ìNg)“[ä¯«íŠ‡bQ¶h6«Í“v•3™â@Y•½e¨8¶‡YË·¢Ï½#?äşà¤w•\Í*âÓóúKwxÌEZ?(n±É7I2«ıÉİæä†z˜‡  ÑÒu¼– ¨q˜ïy%½-ÙĞ™¢ÉEa³†ÖôxØ©ÔjæÒ9sJm©%Œ<+A›(§‘Œ¾‘/
€ Qp—ùÂ™Í¿Mç0[şúÖ±&v OÛ†7ß²¶€!FµÇÅ!ñ†ğ\Œß-dõ½R>ÎÉa»’v_ÂêÏí.=Ä¾ù^®KRwìH²S´JK&•ä¸r3¤9Ãñ‹z–B¼f‚÷Qt>,¬=šI´Z´ÉaM¼¿•V|ï¾húÿÏJJ)ÕŸU„L"ZE"U²Œ ÑáÁñ\š$€0‹bÂ?š;%Ó•kç«GhÖÕŞ÷öÇãHÍ›> ¯®ïhtSØ™ĞtÂ¼•1œW[^õC|çwöiéj˜Yşî¯”†‡±Ù’Äáî|¡ª*x~ò ØÉùaÇÑy¡I(ÑNÇ¶6Ğ°^Íná^Àé |t£ÚÏ1µB·ÑıpVã`†a_ŠaØ¹ÓÓf‘±ò7ëğ8fzñbÏó;æÓŒæèÈA‚¶í¬—“ìºè„ŒŞ¿/é}ÅQ;¤õÏC#ÙA°o®‚êQ_£u"%Û!(Ãˆ[`§®uYâêÍŞ<gˆa\Å;9|«H©™äÎ4Ögæ!}Å—.ÆNlË•†ÕWJUÈT‡š·e=vT¥½
4Tş+6¦•M5TDFèÌfd…·èwôA—2¨ï©KíÙ«‹ytu6D(£LY¸ömŒĞ!uİ9+ùË3Q¤'àBsjbój£èëˆìsùÿNUÖ3œ~ûX`_pĞu|sñvTÆOı0ca‰ıùnhÆKiJ*™YN¤V?KÒµiE¸*k·›ÖñW¿}’‰¥Â®£ào!*Eİ7	FmqÉ	Lãe&Œ1~ qì7½ÜÜ£¶’n“ƒåigUîz4œßç5Ş½I¦Ú˜U²¤èîŒQ¤gW0ºlà“óÔ¢0æbÿ¦ÃÍé?•?÷F¹tBK»aP÷îz”_œ Y”…©w»”ûş¢JË}í¼as,"qº®$DH¼\ÁÓr«¾ÏM	[J~{Xåg[1îaí"^bã’ä?ĞSR¿ªD4ÿ"g@'È»3ãÏJJU#p¾é[ôHä¤Ö½U{l|Me¹Í~B‡«–K¾âü›&0HdeP&îô°äQ&áî
æ‘;kïó÷ûK‘Ka8(÷¢R^¼Fvú«ÏÿùÁªš˜¢¾Â<‚Äƒ;%ê)hhí×U`tZè¹|êŠª©¾ñJiFÆªk¶>Ò!~Môë¹ŒYŞéjÈWa5°!YCŒ­N Tnv˜Q"±qaÇÌygEòól‹{}Cô²^>¦Zû­Ç,ªµ— €µ÷Uv	ÛxÑõsNÑ7§[Şó¨¾B^lG Â{Ñ<3A d“i¤|ËÍVû~¼<Ç/K&]†ô´aÈ.]‚`ÊÔá1_s6£
Ò€4‰Øz¹­Ş“³u«&9‘J°±\¨¬éìd™½å”GµÃƒš`]‘”“VÅ7ÔM©¢ğÙ8ÿ É§Åa½‡°÷èı!£µÒbÆú¼ƒGZ¯°k’‰Z_¼æ4â•"j»nó…Õå¬3?i 
€Oë[,<Û8_£KFàî	€Í›œ[„·b'{ZÁ)2|µÌo·x0LßK®Šƒ.HÓê’ÀpèèÜ‡ˆ÷~›w€ı$¢?+š «¹Ä‘JWş7´ÿ•…XbÕ²Ò¦ZÛ™èœ‚ §·\ìÑôÅÌĞ“8åçwSÅù %UşYéVíRHE4ÂËåÒ%ìò€¦ÍĞÖÂÒßW@ÚaJ8ıØça¯ø—yÚFR5!§Š­øjaŸÒ(Íşğdkg«Ñ›à­
}ª»Ê+§pÀ¿u³àš_Ÿ¥düºÀ°N¬Éf2Gü›=ë>¤ºÙúo&éœÿãâù¸¤=»òƒ³¹§LÖz»}cQÕyœSÆÃ;ƒp#Yè+Ï9C¥ˆü~ØŞSÛ3A>Mğ	bÚ_fa1ºx ¨VZ±â2>Wmxôa{~[*şˆ1&âœRãäAD˜²{¯›í[gÓzQebñmÚ‡Ó^ÌÕ™™P<Ìó+Ã¸/@İˆÕŞ ÄÏ:oÑµ˜²JƒÚÖI9ø?‹s;]õ„¹Cô÷ Ä9äë«ã×;*U\K`ı—5ªÛïİ²å/c¹–g9„àtnğèº£F@>;³öS+ò°'
[‚ğü‰ K© ër;ªÏO~}\½q\¯DaÆ:ÂAŒSI‚^>¿ŠšwÈø	ÔñÕñt‡$™Ö	/o`|ô¢ù/î´ËÂÔÅÓƒ¼ZkT	Ÿ€‰Ú3!PğH¡ 	ºÍ…¹ç¨õ$Á(~IKÑ¯d ^¢©â÷?€—ÑKE+„ì‘i‹‹ Î¦‰ùiA<á1ÿü˜³¡óø1[¸R“+­K!_Æ*êHFºå„Ê '0£¸iŞD²œhôQHó/nÀi%Ëxeq2 |™{’Z»¤<ôÙ
b{ì;ºV•€Y¶
?>¨bÜÃ¡o²ş2Á‰>£“ÀºÈ¬NÚ0ÿ¹)G¾Q·åìv˜µe18“…ˆQ%•¯.FèÁ´jˆï]Bçs‚ccq¯j•ä¡Pm¸^ÆÌï0]ÀƒKƒ‹¸Û³ Xèïh¤¹K+SßŠ¬FÇÿoœï(ˆ»w´vbnøÏLQ½ò25@1)+ãCõÊ6$½ªÀÒ–î0SEo¼ ĞGf‘÷·£¯SM,Ÿø‰²–ÉÅÀP„!'óê­÷ìºB—Ğ&NrN^ø…ËÆG„0ôKnĞŞ]Íar_o„×Íƒyr­J³v¦´ó·rk¬±+ŞyOuQjAö¤vŸ!ö1UÀN/¨ñxßßú€$µêşk–²	³–À›.0ºšÆñà•7-½™>Ú{YãBv­y&	zË3ÅDKã¸¾7é.î©ß¯Ûj@ß"?ïùL[ì÷à]Ğ°ªmÑ´´!8ëüÀu·fíj	˜Œ[»î›ˆz÷ˆÜğ€8Şs®w[ú‡Ô£m¦¿ræEèHa;‹8‡é»şkøÁ¾q¼1½ª<2Lùæä÷Ã¯MKmŠı0<Ô‚‡x«gËt/Z!h ˜íG­_P}ë ¶şTV2ÉÙÍgÇw¬šjÕÃ›8ë·Ù7¬¾3¡Y<‘ı³ ÛŸ÷‚Y›Z¶vßì}¿bôíQ2E	Şeqµ”Ş)Sä>)Í<â]I’¿y bºI¬úls¥.íÖ›ıÔÛ´g³ötšrÛ%Şxz˜)/L”¤á<E™›iqLÌÍ]š ¦–Ch÷œä:ôfæÏ2èó|Ix•6KşE6lIUêaA:VoW­*É«ïßÖ£wkQé§}é	ã5Üäà(ÅÅ’é‡Meà~Û!q˜O¦—’ ÆDÛI]“Ğ,§ã`á¿¢‘¦,fƒÿ=7ÇmqY©F}tU,Üˆ)‰ú&×&G&òÁc‚™m¼=ñ7n1´(YVyÕœSg.Œ§fŒ˜ëv)}JNó~ëVu	À¡1“H<lòqĞrÙ‘Á,}™(İŞ¶²IM‹Ñ´êèø™ŒY:ëÌ‘²yÖé»^kòÊ˜úö‡ Äÿ¦ë%¼•Šæ‰÷í:ıf*“J4şwŠ¡‚–Ã_øöÔø”	™I€ƒWQÔ§t/hê„Ãm"¥{xY’cnw  étƒƒgñ‡ØiëcÈÕª©60iK+Q¤wVUĞ%Wßª.)d†7ö¼Ür0û¾õ?šVı3Q7í_€Ü5ñËÙ€œŞ€´ ŞI.zƒYí\P<üY?¿ˆXwqşÍÅjŞÄòª±´×fSõ4úôòßÈv,L¼2³<ßµxëÒ–¯©{¿vEFDb6×à7¢D’“,[1Ë‚SI uºt2)nÆõÏ.ÄP~áNeD‰ª£EŒì‰K˜{â’%0A©ìD¨“ù[L¬·Öaİ·÷]RÀa¥×lôïÃNAš;Ìñ·/?ƒ^È„µ5Wäë½÷DXŒö¡3ãQx
±ŸÃHş2ãÉÎ÷´´o _ ¿À¤M1h—\Y&»—Mº1ùëÎ”J«j’`%Ÿ°(æ_³ä¿÷ëõ3ÍI ¸Üÿ¿hm[P†hüø`­æ“&†™NZJı¯ª¡)…‡åäÔko£ùÙLû6’Cƒ ÔzÏÛ ½Tpğâbn·R -:[‚kõØÚ;âFô¶øï´É¦Ùâa¤˜F!­6˜Ãc¿÷d˜õ›>ˆëGÛzC}C®ğé¸®“¨¡@²pÛx{¨TUR+AYe4E­^J´VWÆ&š€&ç¢q<ÄQìÔz7à.ÌÙİ1UëÌÿ( îìùq„d‘Ñy!¿ZòxÀWgªNqÒØgX/¨©cYÚÅM »¬FâXD ûPßYŒ64Yõj.O:ceÔ<şæºÉ¾\&'°'pÍVGmB‡@(@ŒXSu]ß¬í›€ûØ@ü$òê`—,3ä•C²YûvPùkOh}hñØÇú.ùí¦fj­òQi“ptºgYjF‰X„¿4ŒÑâË5ù@d·;`5‰p`JçâáXka¨X¯gÔõàHñÈâ:1aèEC»Èäûû]ÔôáÁ›º›÷Ä2¾}Ö¿ùùw§hÁ£&¼ğû¬tYPúøÛõ Æ±—¶®½,‰“Ó·A+²aìW½f–öc™®Íî1˜c ?9…e•„ñ}ğ‰ DWÖä=mÀd æó3Ş•÷^@FÊs]KPFß0ç&Ñ	©<¶;QêıÈéP"ĞÅ.j9V|w¾¢§9œ6.‚ãZ¬~m/Ïu„q;]2›‚<üÈÂÙ;ÎıGiøñÙ<£Ï[[Uûğ†ZUoÚŞºã£ãD-ş:‹"7Í¢ğÑùıÖ!•×’·<â Œ0¿ïgQàÙ—Q¹y¤b>…Z`À%­‡Ğ´î'åä_eÈ7Æ³ê P<^Æ3:$ê¶Õm€{º4”DDœ~\2£®oõEÂJÉÚÉ!Mğ+«oª“Ôk3¢á=Ô·€Ù&¾Õ²ÈÍŞÊûyù?°XÉ¾}€¶±¬%ÊXYÆ  ·ÑEB´
Vl ¯Ê€Qù©®±Ägû    YZ