#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="50767096"
MD5="e1f77276178a6bb107a415cf570b4a83"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26152"
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
	echo Date of packaging: Thu Feb 10 18:00:10 -03 2022
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
ı7zXZ  æÖ´F !   ÏXÌâÿeè] ¼}•À1Dd]‡Á›PætİDùÓf*ÿo¬C§Uó³¡	UXLÀ:Za_Ä}=¾[‰! Eñ°}[éÛP½áG¿ÉCB7¤ˆ%¯vÀÖVãsHuTŒ#Ü¥\®ZQÆŠçÊ\±)£E.Âx8¾íŠZ^â}3`náíÈ	b³ A ŸmRKˆ+"2À»ÃD+–;)gan‰ÚÂÜ`I[ËkÕah7+ÔÏõ)¾‡”düË 8tk R
ìÀk4ğÂş½ñ¨KO‘××
Ø¢[ü5—«©X8d‹Çæ†eò`Èåj§±ÜYxP†ØÔ€]·G¾*B@rc†/šk6"U¿ïŒlEˆPŸ#Eî
d.—¯¥’6ñ´lEII€çtUÑÚc±p€<ëAß"q$Ì[rsêó˜L†FS´»@/—=mMöhßs›º’»±;›ÿlä­ÌòëW|6 Içj‘ÿ³õM$|~1FCR	A­í~y{QöşˆL2ä4û
¾E¬ÅcvWé—­“ç~×X @S]¿qæıœ¸gÑ©Á‡ `Ó~u¬©âºÀBb;²ĞoU*-ù.8=vÃñUW™—$ov´6lor+¬oÓ†;Âª7ïõşèµ=>¶»ëµn›²¢¤Hæ‡\Ü<Ùå—4åJ{{ÅÂ$B¾-õ_“@²p;ô’°l¾šIj”ö&Öb‰y{lĞávVÇ‰-Bâùñ4Cà3ÿzníÌõ
Šc¤9ÏıZşaş<;sÿ† æl£HCdI­†ŠÉífyFš´“Ísš»“l‘òŠ8óLüü>]?Ö°”—†°õõáòı­³Nğâæo?¿k}÷'ò,²5ç°ÑğÁg±'=ì¡I¤²¾‡Ãø~âƒİ¥—w´IûÆˆó7”ºc²íÇW– Ôd>Ş¡;OÙd·‚¥è	$ªİAÚ{Ä<”¥7šûá P˜Sı[ÚÒi²®$V³$yDÜ?•é9ıºHQrW©¨ø•K³;7t9Ú§¯˜ µñZ}ı¦"[ÒS¿óM}É{”±×!fÂâæ,ü "ÌÀà˜_g·õú„9 ¢«İµœNY­ÉgoJªéQÎuÍ",&p|8Îó·wmİ»æF¢ß/tŸ†&i-ãDÃhD•fÆÿJ<K>Œ*9O«çL÷V|Êš/RxÊ?Qy*3í†7+Küá]Ç$ÕWm‹&HˆZR%o"<–C?­Ù|”5-Í îøºˆázÅ ¦a™âËL¼*Uæšß›T÷°‘çûb_S>xÚMn Ğ`å˜õÃˆ·¯×Ûù*ù@ÆvUI™"£x—'œÂéçÀºz]¹H±g9	Šˆó2ëKc/-ÅöæƒI …Ú¡¾™¾ûh»(³¢—n°<ë)¡7d	©ªl}ÈÉ¾~î
Ï;k}¿:3WÙ1eD!è×!&}ÃĞëŸÈl^>áKÖĞA®¡û`MKkm¸ƒ—Nd36lïnÆ»9§ îø¾Í *Wœ>>Æ–;üDoxØöœÁDU“°×£qƒd[8Ñ1xoŞıHş‚èA“¨$šJü^¦¯ƒÎÌÃLâ….k;C¦rAõÄ°@Hğ}«X	e†ÓórYÔ]XxîªIÕĞŠôœ¤€÷H£{´¸õ›N¡¾ÖåüZ‰æ R\ñ“«÷%-á"]î½Ç\ "Qæ«º;·ÁnÇl¹ìènVìiC®[ÃZíâÅUBÁäàôj¾eù^
Ó¥I"Ò±ùj’=¼£ÿ`É]©ÌŒÒ‡Ä?²Xÿkâ h~v(~¥!ãï†›BáÙ£EÂnÙ‰Ô	ş½›e ¡=ó~É„Û>>qªˆª‰¨ÀH´šÖ?5kÃ|C£‹Ö”ag9¨ª¸˜£«¬— V‘ÿ(Xyxó§.B0Æ–;ß\ğxxOÒì/‹…7¨¿ş§Û>Ò‹Õî}#ÏfA×`Fõb‘êlşãënC±ï‘œ_B%2·¶ÕV;×•	ëÜmê-)üºÛH!zc¢¶oš}3	DlÔ?‘”ªìlóO)ŠôöNmáŠõfÁÈJ HÔÌù§gàå‚ƒsÅW‘ï,ÔÔDĞB *[ÚFğêDs¸»½pğ&N(ávŒêüŸ(Rr53¦˜õ®ˆºşFì3¤ÄtŠÓ¢ Ñè Gh¿´Ìµ×´6²‡¼rÅÆ¯ ¹¹©²ÓŞ®¬MÑÏlæÑßbÈGŸyËgå0ø-Î„Rê×kBøoÌ»íõØÃ¡Dg/FLìÀîÍ07ñÔq¼öMã,z`¶«6PÚ‰3²±¹@à2)91=÷§Çì‘@|ø¢îÂÓÖm¨Àä;õÏ‚ï-ô:K>b‹˜îz<½mGÕf!â¨½•^nµóÆ’kM¥ŸX,;	{>xã¶…ŠO›ˆH½X´\Ø•ÏÜ2«eÖ÷c4<ƒÕğ`	tQàBÖ'ßw° ¼İlsµÊªö5˜óIXÌ€q¢’ìÒµI§•9La,Êeõ4€·âÏˆ) N’_k1"ÖJ~M\S}\Ö!˜0?Ï²U1ƒÌÊvŞêí†ShuÙ–pîu>zKœ˜Ïx&úîMJ"O”Í‰?ìé§Ğ_%XR”ø6I„E-éG
J²»@qÎT®)äøÔ÷‰Tg-_n)qj4²p#­Ô<HùÊ€~2S×÷UªŒ‘7D.<×bç¯óCÛŞ®
H¢ºãLvtO…â/,0ê8¥§@Pô,w?«ú‚g7ì°$¹ò;œ|f!P6uaÉk	D-w>ĞüõxÄ©ssò6bÑg°k¹¯şÌÂ°>§ §+J‡ˆ÷P{Q?ú9[Xé'Ü²ÂmDçU£ôq©ğ­­l–›ï Eè’BƒÑ˜Ò„‚Š•“GãÇo(Œ“ç$ÙÎ·â±ùš«MebRk÷NÆÒ/¦—«{Ô²{ z9ÊÒ,ıˆ•«ı’0M%°FºÕW1ã”®–ïbßĞ0f4TÃı‡`| iBÕ·µ% q¹h#¢µ,~!]éø5Pöƒ×¢y†>"}—Pı//-ãzX~a"ßr¯L…«²^ıWƒƒJòŠöÂš6X:S\Œ!‚ã¨ ær®Ï×0mÆüïÉS€lÕlº¯Ğ»#ç]erA+ÔfSUñçv‡å_jT_x—4DfèÜÖ!c¼| 9ßE±3ïˆúNíO¢ß§piAH‰J,Îî±S°NÑÚ¥+0¿ò¡µè÷PÚ7$oáŒCm€1ØšÇ”ÉITM‹1µñê1—’;â†?ø°]	ıÃg‚ÈB«G²¾ïöŞ¥àŸÒØğ¸ŞD2g?	Ï/ÉkE-À¡Çn{RÑ‘âT¢¹e“ú‡°øM³T#(+!ìµ B=¼ŸÿÎ³K28‹sPòGÜ§9—V['ééÕcLR¦ºy
Ö×Ö©k˜í'HÍmV05ZıÔŒÍè·¾àÃqí­HÀƒtu—E–oÓö¯@ßE?^·°¼Â]şß ºÑ'”+)oÎ˜mnä%’~Èlß—ÿ÷ZEÆ&†56ÚDh#‘Ş"'»Ø)ÊÙ§¼F£üø‘*&óó°(é5Ø.pÓÌ›-Ü ˆ¸Ü]`c[€z±5	¼×„ĞDB²Ë¬c¡Æ”qö“¬ŸëJï_¯Î/©Á¨`¼ ¨ù©´;	-qĞ>”™Áîyô9<¾Ğã*Ã1a‰ÚğSOr¤õG–)yõˆácXX`’Jé‚¨4¶{19wÕ-;‘C^—³0Ltåã«€À(µæH_Vbæ|Ÿ‘»Ÿ¼78F{$–(JíçZ©(ÿh8i”òJl›Cš¾GİTÛk+xKäÍ9î)ñïÇ‡x¶Ôˆ¤‹Õm:¬~§Ï¢Tô’(fï”*ZV¬¿ËbGm$&4îî•Ğ*¶š„)YE¢:QísáÕ+õ[!’&Àé²¢®TòÍCgÎ¿èM;epí¯îº°©O—1UÒ”9èŒ~Rn6à
_‚o‹½å”„I²‹ˆXİ“ ¦<Kñ6ïó¢^½ãx¨OcJ»”ß¯  ÓÒl_aùÎÏõ6ÍCéÄoÔ^¾×{/#òÀÒñÊÄ§ÆTÏF—æÄÄ­pöÚUOÛíö¶ÏZÑv
!ÌbÆ¡lX”/CõÆR#œM¶Õ7ƒ k0‘ÅÙ‚Z¼
¯~<ì{d|çã¾he;mf¥,›ù—*4İ¿Õúk£z¾ì¨Ó3–Ñ¼jb£o‚·èÌHĞaf9C¬z'ÂÑkEé»İŸŞ@Sü^»,` à›Ñí!ûãÕ“Ã|‰RIÁã5eqØ´ÙOcõ¦·ıo£8Ö•ÒE†Ô{óÃ›ë‘ºÔîÆ_±–»è3A´0Yö†Øí(]÷ñ	¼ï·åÚ$RB8GÂcIŸ4™BÆŸ
¶Ÿ[Ò”ç_wL3º'Rõ²ëøİ—í’jYs›À©è.	„/Óz­Hv;«ÀĞ«åÉ¤İÆ/ÏP‡¦ÿx™´ä·$ÆE?‡İ‡
yïÖ3¡ûuPş"Ÿëğ”´“2|w#ïp@Œ&6>Òì›e(p½Õ
A©‹„Lf§°gí‡‡ÌXP=ÛÁ"JQÊ:Îrê+ÂiL3Y—vüÈ)Ä!øç|«“pqZÖ9ÜÓ)9×U…˜sÛÉòeºê&Z³0}ëÅß[cÁªµ¥BUå©Äş¶s?˜™Vâìé¾Ç™:¼ÅWÌi`¹ÃÃïª]%„($…¯Øòó+ÄÂJôü<ŠçÒáÈ‘”ty¼ÅÑg¡q`aãÃ7"-v(ä—;tS £‘W¡À¾'„Ïÿjõ´mÙñ,nx`âC!`$c”ºõU©`3`#ŞAg×„¬‰×cxN­¬¢m“¼Ğ€<teõ—-Ê9pi@ö Ü–²7ˆe)ı^İÂkİqQŒÅ .`œX[1–ÚZŞ¾CÚ“j…‘Ò7Y^ûîïmÕ^k"³ÔäWï;Ú—v³°ÙµëÔÁ…¬÷Z/š4ü¯Ušæ±+ Æ–Å«0	æÄ<1!9 íHMš0k%ãìE½Œef%¹!>ÒÎämY‰fdB< 	ïŞ5vÜÙ6N¯ğ±»²°.…Úiª0ÖGPxz°Ş"óƒsØ„h9‰„}sQ©‘ AÌÿ_&)– ŞÈÇ”õXìD†ü`T.¸Ş0¾Å¬Œ×Û¦]Ïjœ7œÿª1é®úÒ8¯Î_¨[+ ŠôE¹Ó¢q8anö5Òcq<9ÙÉô·Áû‚-öÚÿÅ´÷°rº®Ê‘ô-Q0ÁCôÈÊ¿µÕÓ¹0Ùì‘è±‰¶ÆXÙT­Q¸ó«n1KaÃÌ
=üVS{TŸÂeä˜ 5î?9ÄÀ‚—\ô	œ "'Ü>Ì4›ÿ7^¡uFŸ®Äî÷3Ì3öİ‡â¨«E4KLï®Ë}æ[„¯åĞ0%T[²ëvÇöN‚ÄXµ>ù‹ÕY:àCbj¦´`œÀØ'np$sHÉÑ·Ê_0^ãGØ8ûÊÛÒş;«™®	­xr@Nz·¨¸LÏ“‰¢ûaæ‚ën V½ä¥ÒCğöĞ‘p¾¤=Ê˜ı…:ÃB,CRáĞk?§K(ôŒéw5‘°Í´ıÅxé6™LRåDôPq˜*Ê¶¶=rqÏÇ€±ù·’mÁtµ T.¥Á#}æÆ#c;yR9Ç2©¿ªfDmÈV#ûÙ¼}fÉXTR¬ä|«J¼¨àM)‡æ"Åæ›„˜^S\^(‘FìÃFÓm Ò¬ˆ'‰Aè¥»/Ûûû†Šj‘½|,Ÿ>‹>®¾7™Ö¸¹AkÎ’Òëı”£Ÿ^HY‰Ãÿğ*‘a9!MÏJãù¯Ö,J-(Ã °™Yı,ğGy±0’ÚR_(ôO·¬3-‚Ñ§şcÔ!ƒûñş1ºõˆiöÇéw)!½°‹+Ø6iÓœ…`š7ösŸZ(	]Š”¨1 ërÔÊ`eo3ğƒŒAL^•T¾iD’æ§	æ°¦|6ñdÉ§¥$•¶äıïî,üR§Ín*­t˜1cø5r*TŸÈúıj¯x^ÛxnÖ%­ˆg$°ÙğÔÎ5Ì%ióãĞİï{?öÔ·²…ÉrPàéÖ|aQDÙ~‡}˜-zı¸qÕ
©}Ô-}¿O—wà|2×VNÂæàµÚİÙ“Ş¦Ö«åå¨›ĞƒúgKå­çt<?8ÇöØ X‹2Â&(ÏÒœ;»é¹XÌâiÉ…Ö»µ*e²I›år&5×°û+]ÔuÕtÆmL;l}ç‡Xèu’ÿ±HïS·‡‹³n¾"/k3‰*mÄ¦Ğë»=†ı/ÅéúèÔÃ›=‘¥C;Ã,×J3(íÛJcÂŒªºÙ¤Õ;É›fä¦ş™àƒÄŞ×EóT9‚¹`fÆv-4må¬O¯¨ÿÕ{û©ÌÆJ£¾(…1!n"ZÁ:¬a NÒ¢î>|©İQã†Än£é ‚ëÔ±H‰KHNP¤&d|ÎBÎz<ï"Q:ª}ÌC&.aü	_¼§€~ %È ­†~ß+ßà×Æ6§NFĞÖvŒ%x`mØ‡«òş¶šTå%ÀğjwÀ[\ı}“,q^IÎ Î„$‚lÏ¹¶mZ'Û}àQXëï¨Ü½~':hM2ÕG÷ éÎ˜kvA])x·TŞÿå)naL¦•´øªn7­£|¢ÇÎäÇ×':TAèÔtåA]ÿ9÷6x—Ğ„ò,[ÒQqĞ˜d‘ñp§Ú hpŠ»ÕìËÂŠ´g¶D‹´ˆqE7h …¾xÆJª]—³Ÿám=ş;s²vY™lh¨áóB~ü$n˜¨ƒ<·œ?.·Ò»ì#AÉTÕ§¬–£ŒzyÒÔMáQ&CÕM2Š¶ÛëÄ(N.Ïêôğ„_ë®§bÂ$YúP¾?0s°/iÍÒ’Ø¦×óÕn·dÆ`6Üı‘‹õ6íuÙ¼Ò0%Õ¦,¸¹ò9ˆCJˆXw|4_QØ¦ÂjÖAiËb|-íRSÂÀÌeòa]´Kf9.Ü¡c+J.j˜s#‹ÉÍõG€Ï/¢î›>»‘€°'ØĞğ	d$¥äë\‹ø^¹šUZé¯Z&Ë—­›WíN°4ïaì{?)ù	§%§õj÷±5j\Q<n¹°@Ù®—Ç	Ö4æÁ•14g™tŒÆıW›ş{="`äe¾4«ÕÀİaŠ¿oíVğ¸Ö
”£İÈ¦Ø#˜'Çëàf×²öÛ;]Ò
.Å}![—ÿKmÎŞuª·/u*$Šdì¾ïáÈ¢–}¹¹Gê°
×Å«ßú(Y6ß_b'áÊÓgxk¬.ú¸'^#6ÏX+üîrªiß"’smfZ†x{{·îHÂHK.8›º½'&pŸ½Ò+ÎÏQªfD—U4È×KD‰B×€<&È8xJ¢›{&NQõ~¿d2+M1©ØÎjk-»ïGÊ„ë(Øv>ÎR"£Üòj[¡anö@%ş
X¸€Zq_($šFÕ,n ;µµ$o©:ûªÉÅ&­>öÏÇUŞ³¯tµ¡ß¶\},kNB³º-`Pm{ûÓBç*Ê…a$"ÄÊ³ªñÕ†bT”8¾ Çf/Çà¾®×jkçH?©(£m7³˜âsçJn¬µŒiY\l‹»±Î ±ÒCÍºÆ‚ÏÔ£Ö”ß½†˜N¼Á9ªÒÆ;Sså;Ù1ğÇ­[ëA¯o¢·ÍŸlÄPâ“%Å™W‰—ÇŸoÒZkŞ·’^ £î?ŒVƒ8'ê½Ã%à“ &0Ü@˜NqD…‘·]i,'$Ä…ñëuï²Ø±¡§²â…{|/àÆnfógóğ‚Åğá°!1¶^ü^lgTÙåƒ‰2‰9Y<lıĞş)™‘æØ9â_Kï—
H.Ç
fBáÓ»Vîñ¶èD.8KEè§‚j@õ” †§&İ+<<,t„<—íÔ¾Î€òìhd8í±#Ú"7Rœ­ï)æ7¨à}/°€?Bûzò˜|±<Å-POã%X¾P\UxmSşW{ğJùsKa#*3,UOmG Íª—9’¤ƒç‡¸>Íàñÿ*“ñúKÖ/ÏGmÂƒcZ5
‹şäÌ§|øëßëĞ
?şõ\	íóıg-òÿcƒ¥»—X(·o•lizS#¹Ö#Ô¹ß~ßœ|¢rÿıjá#ÏD%·­ŒfÈ›w^ÇáK7o+Î’¥Õ˜Ö­Û¦?‡¤å\4PºÂ2N“¼À ü~ĞÊB Öû¯¡UüEzhfC@İäÛMùC«Èš/ˆr+	Ó´ÆV±]LèZ5b\ròïÛ<Ó«8Ğ›Vœ\™Bt)j7fı<ä5ı,ZJA¥Q	±‹ƒ=JÔ÷Š/D¯çÑ¡3Q}6Âp¡GˆÅ¬jŠ¶óøÂİ`jÁdÍÁ§ı¾ŠPÇùqb/ÅX:Ú:‹=`½'å°ÿÃ3Éxı2É¿Z¿İ¼›†¹ŒUÍ:Í
ªítÑoxÁÌÖ³ÅÎ„ïû4{6,ìÆ³*ñÈˆjÚNU~fdêŒ~ÕŒŒNrŞ¸^ÒÙ•Æ<ÁÁOÀ¦PÍºéÄäµ›.¸DòÄÊÆË¡êR÷2uÎWÏƒzÑäéÄo+Îéí’{ã<OB÷°”:š%$ƒÚ¨bæPÀÇ0#K"À]°'œ™tò)›?äáOr/c¼¾-V­AÌWáJRjÊ ÚÕÁ•~ŸàRİ#ÕÔqú?Aö‹5~OÀ–<’¼ÔQµĞˆ$qõ\|®w{2˜¿BÕ.æ9äš.Zñ¨!‰¦{}ÆÜ|Ä©\à,Öüüı™}Ç-¹Æ?XD¶qC»…ÀŸ²Äğ¶Ÿüjm÷g¯µ˜¸ì“ø ¨ò YùxVBœ6ÃÁï˜
ççhŒî)›
Õ
f:•³]_İ½üÉl²ä?³á;Âà/ÚÅ ú†°áï_¼äF¤L+r66 Ÿúã©Öìİ`Ï¡…ÊofkøëJmÃ.?ñcncà…$–÷Î¿ÖÖ«‰¢â0!yñæï½`'÷óWË)í´‚åÏùî®/äıP­½QòìVP˜ï;™‚¿]¥i¤\fîëpŠm;aOT¡^tËÂÖ“OŒ´V²j° ~(Ü§Ô‘wM×7Ÿ­Ë‹"…ñ½@ˆEX–¬A›ğRòVÛ!°î‚…®	·%Øs6È<µ.ø©Or•"8Y¹:yãm†İÁX Ät²4/QİXƒÆ|Œ¿&óùÊWC–* µhšVÄ¦(sn÷ÒğŞy‹¹˜*—XìˆìYÃƒù-d¢!}¤Ëñ‰ãòÓÒ¦Iù"£˜ÊT€ßü×g°“`¯DÅvı_‰OKé\/äS2|õ«‘fÉ~|V%[üócÖ_°{zuñİÑX3”%¿ÃV>¨Aí±fFÊ
Åu£	GİX;@ò»v5
˜ÿG´ûáv€àî´&Êˆçõh|Ác”¬:t= øñoZ=´ä’¹ø®Iç‚köcäiKf>?î°D‚ƒI¾ÿàE°†á,«ö,lËàv1ÁƒÔçwäá,‡#M¿ãÙÌÓsuTÊwXÕX¥€/`?œ?³!n·~{šÚjvGuÿw›ãæ´Ì•à/d
s)nb‚"ÆFÏJMuËáCÒú£#ó9×Mâó†úÑŞ0xå¹;wfW/î×}ìj #óB}¯w§"ÔÊÇr­T‘_ô`å÷³‰3şùóŒã¢lk)0{ã¸MÅNáXªS@Ù³¡…«=ğ¯N÷Ør>G wÏM4¸c!n†Ó,Ü¬n±ë±Kˆ8©²µUJèb¤nú¹Ç¨x;HÁÆBÆı/*!KÆvÍ>E>”Ó7Ëÿvù—¿A›¦¡:%…‚…g¦ 8ªVXØÜeÌX¦¦«Ï»ÔHÇ¢ß’«µŸÙ^Á§Ô ‘"B†BÏ:ìí©ö¢ı(è˜H9«¸ÿã2Óm²òG+®KT•ì\ià§€RŸáè
•5ØŸm}ü/*/şSŒÓ\’\XÁ¶PN¬Ò“ÜjµéZhÖı@îM¿ë“P°‡ØF×:¦T[ğËm|§>ä]àAyÕDWn’€t {½„R6âÍÀM2*«I*ìØa#¾BÈ‚wÇ%œˆ6!°ìirï"x]šüìJ Ò¤µa±÷ÒÑŠ¥²ÿøÈµYc›àd˜k`êÔ-Êòô+‘nÎxıÍ‘àkC(‚(\e}JJÙ­>%›Ç.uãÑ?Ècì¯eĞT'};à	CÇèÀÎÎ™Òj^†%\*©u•[Âˆß~…$Ø&—^¹s'©1˜•Ó[“””ó@6t,ñäè—`8"š÷õ?ş……ÕıÂ.ËD—‘ï”šÜ‚TLÜ×#«z¦)->M§(¨kö©íìü;¤	ˆö†’l-R–‘=O>âÚ'Tœğâ±ü^8•–|.dG`áGÀ•‹y;8H”*Æz•ŠâˆBŒ²»Œ5ú÷æcÇf-§H£ı—ÃŸ‰pœ,@¸İ-ĞÄDÒÙG9NÊt§p$çüEI›RåäQÔå„®¶Ãô¨‹Æ5c¶Ê&_û~†¥¨p©2¦‰è¡8é³ĞÑE§~ğÖ@k §ĞíğD	+†C“ 4³g9?&•?ğÏ]ÈSg¶(ob¶¿ :÷åbÒ“³‹Äe9×ï¤ÄPvª­¯?™»]«(­E—?Ş‡¼¢$–RÄòVlS`××ù Q1¨¤zÃo,…Ä‚eúl¦)ÀBq»ì/$M\˜ÆGÕ9ü$¢häÀ=Q^8ÇbÂüWãÚ¸Á'.¨M5¼){(ÿ2¾²"Ç²	¯¤¶UïP#~,
_J@3àÿr—€nL”‰’şÜzèH HôhÔGıE©EvMÅGĞ2ë–ÄéAÜô>HZz¤ô÷ºo!`Vc¤èö^·NYÄFa/Êì»dùÃƒÍ›Š­XT¸jÑßÙùáQµ‹[›(åìÔ ûË!®
G,¿*Z‰>XŒY;…ãjŸhw¸</ØCËóGúÄÅZÃß–éÆuV÷iv!jº…!q+)8±
D1-JÃ”¨
Š;…lmõñW{±õ,ŸŞ8Õ7P0˜Z#ÕO!aHj¸f¾ïÛrÊ÷±‰coI°9:Û²‰Çğ(Ø+ã†zÍ’0¼Ş—Tñ5¹K¡k¿ú«™ºxe•ˆaU‰&[SCù«Â60}ûhÏ™ğõa» +º´u\‰‚È¤RuX	EµŠÈ­›^$ûãR¶“é Ù›7§EÒZIO3ä2d=ºÓ£>KÇæÕ¨ƒ-ı5´õ*¯ü?r«‘®rDÑµÙ.réŞEÄóäNEUˆ@F/PèéR;ğ…˜#£8£Ytt'knç[ä‹1Jûm³˜TóQDã¤¯™Ú›ûA™®xù µDİ.eñJloÛ Êûƒg-d¿âq>»=qkaæ˜‹Úpí’ÂTF|]Øæê@†Ç:~i¶Ê4i¨xGú-Â¸òÃ£LÇ	]¾8ğbüüqEÇL|v™2¥¿À#wê ”»xÌ¼ÉXsZ"ø«hèëuÚLØÉ¹±|\	à£ $*ÏjìHo'4Àñ¡®ˆsrN÷cy2â(¿+¦aÓä[V=/¿ÛğßãÙÕ'ªŸÿ»GRÎjJôNh8×ƒ¨&Ÿ%à×±ØfAÒ«ÁâæÈN,’ËRpfõÂ‚yN6R(•Ú
XËU‘ÿ:h¼q‡¾p«Úù¬9­'É/‚ÊætË¡¾ëÈG·i…@±,s‘/æ•ÔÑ{Â~ÙîÖ=G
¥wÚXı¥£(L Gªke<¤ø¾)ø—yÃ>ß§.B‡¯E%’pZdÓ{ã±E†C4¾ Tğ_GÇäé³+•z¦#Åw|±„SgÅo±ÆP–.¾ÕòŠ43?å‘>AxŸ™â©Øü]v…§'\”
ØÃo±£mª8é®‘lS©´“ßg+;yëR2ààì¼Lïp‹P †Ñbè «¹ç¡
VoÅap‹ö"®(¹ÍÅ½`3Tc³x[lJs{Íğµ\™Ñ.g¶¤'TBázçèÒß}€/\-yNïî¶Ù{†ƒgÁ˜>Åg&€İ„şuEãÙZ¢g‡`}É»˜BõlÜá¦aF¾ŸÖªìä?_m”.Ç8…s|ô,9amg§‰0„…w“æe²GQ4aä~ÇTW
”k§	RpukHˆ
œYqe?¶50Œ4å
{_1Úù®0sFÍÙ$~Æ“r _Ç}¯®Ë_Öñ™µ«¤Ì	øñ¥éRûp–zSœü•I?ğZ,Z6t Ñ‘:¸?"i/¡÷Bn;-ªxI«áû&Ø[ùbâæ0WïvKÊÔ¨æAF6”‘Çy±*l<f•ª]û³±B-&5!JëÃ<Ø
ØëòÙÙÕvæĞÜËa]QaÄC{ÇC
9ï¼¨Çµ­ƒ¨mşgd•°/3¦G~Ò£7šÊ€ËÓÎ5"EÉ–5ÈrŸw}&¡²DyÁ|a·£y½:VĞ©C%%Q7Ãæüt%ËêpqS™çã?mÿâBœ(øgäwå ÊB`i]òãSúgÛbrÉÛ,z1|³-¯s¿øø*›5œ§®•O÷ÁŞï<ús$<í,¤oøŞ¹³E¯”*®:5½ŸÂ¾Ù•„sXÊ÷ÅTªÒ³a'`ËªƒRˆ§J81·äéJŠ8¾eÁqIĞ.€¸:&K&“Ä|iMÏ¶n"J„•Å‹Çnå\B<×lğâ%%°a@şf)I3KÇñ8èR!¤¾ò]×±ÕnwqHäI’OŞ¾
˜Ãk&d4[	Vgœ[!o|íF£¡ÊøÅ¥ı^°ÕR¶²ôÄ¯àÑÛôQH$²6É=U‹Ykíq ©“†é¯¬Ë-diG‘ò*ğ[zŒè”–!Lù%.> ©˜Ñ=áD³™ş=_‰f˜”òånhM»D(†n}Ş:ôTa¦ÇHfé'!%*•‹|W'd«ûlW†49sª»pª{ÿãæ|6ì?ŸğQ«w}…º
~¹²¸– Mƒ)#˜ÃÄEà%yvüg@KOÜvÂßnF9Sy¿Aá\ëˆCğ»GrOĞ4mÁÃÕ¨ÕÁ]V‘2Eõˆ˜¯&)ÄÓùŞİbƒ—ŞÀnÎ-
ù`2»–”€€ÕlÌğÖM*Â)lAì8ø0µå,¡›Qyq“@-éÛ¥Ævè´0IgHc…y®sX=ÕyÕ7«¤${8XÄüÒ‰BH¾!:f^b8|8ÓCÆ„ìƒ™Í€‹XÒwM²+ Å×l·ğ­`3GÎÇGä_Ë¤öŸªÿÅø%*¡Ò¼E(—z„»aPLÃŞ&";1c†uşWò'1>çwÌboPê]É)Ä‡òtoÂÎ+èj8S–³¡/Êã¸“tç%ªÎàlI1BYN¦›”Ãïei’g(ç_n®xÙœà¬ÛPÆhşåÎ‚šëMâT%)æ¾<©6Æ¤“L!hb(¨Ñ»qd7[ã6òòxİ†izï–OlÿÈ¹õ ÃÏÄsÊ(S¶Ì×Éµwôëél
˜óïeæü7ÑVyYdŞ‰MãLÚ4ùOí²lY²ª»ûÙF0…\±ıO|n`Qe¿ÕœŸÅÜ¯¯¹7¥»„[:¸ÃÍı ¯q×=•Â}ÙÅWkø‹_}‚hÃÒÁ…ßM¸+R‚ú^»4wâo«Äù~µËdó?“J?†zï^Øò
hÓ ùŞ„Z€³">¬’>|A¦&Ú	lek³q~çh‰× '~í8JªQ¼îY+ÂMßX±“5±âÊÄå
(ËEğœyò—Åà&ß§	¶<Çò]Ÿ—¸†Syn¢ÿóÚ!L&w®‡íê¬şÍÏ¾Óeòwı%Ò)}ƒ7^8k©zb¶v‘üÎŒ^Ô$¡ÆåÊGØƒ›i-¢Ã®Euœ=$¨(@êµqáñXşÒG
w9º8Ú(qŒ…]DU…ºÃRYw¶'-R¶`ù¿gÁtî: ù}¨ñqjrÊÀ [",™èø%ü­û‰`‚Fê!ëµó…“Ò8ÓÚmLl±'-¡5Î÷‰9')‚ë@4¿—+Iiw"Ò|ˆEÅ†RŠú„ƒX”áB	°X0A“6ù^Ÿ£´—LıYQÁêH¹
´fÓğ×æ û}h‚Eì¼Gy{D:2‡pqî=÷o4N†ÛÇ¹ŸqE¾¢ªå/BRêêŸ(¦µN _pÙ  O¿öÁÂ? »	ğ:jû¾¿İÙn³{Ò>Ä%2àE©Z=â2[+šs9[1h>¹´ß–ô8]æı)ÆõÏªÙÔ	rfÅâ{í¼Uç«R—¹Ï=h-İx_3d;Õ•Øó¥2»×J=îñ¨¬Á]?`n zAXãµ˜'ã?—®Œğü_4ÆÊ¡±©Ä!_DÍR­ ˆ‚¤|§g—ÃÚ~«"Øäb¿`+ş[“nÇºöfNÃ^Ÿ©oòL%‡…&;(³’ Ldõ:,ı“qĞj:•×ÿU]ª¼VR[yN-«3ö€µŒõ˜ kšÙ3ZE¡Æ}Ğ6ša8méİœëæ¼é™¤Ã2æ·íš˜şÍøşË³Ç!Ñ&•Ë?RDô°ü`ÒÇjÈ‹ğ¿
×ß×C-?m­=T¼½ÅU#’¶¥QÛÌÖchö`v.&m©3™¾óiĞ0ĞVÄvw¤Éo^ÈaòÖ;X†Ÿ­‘Ã_=<©ZI–’÷9·à0;Î¥îˆ#†;M°›|ãm5Ô_«NÖàpTkè=<[½r‰5<áH°‹ ³˜qä÷e 2];·Ôˆ×)ÏSˆÔùèMÍğ ¤ŒÂ È;î)J”HF}„Ë¿9U ãYXŸQø’Öç‰º~ÙMO²&/¥¯YAùú% Ø'/>.l$Œu[Hë½sK½ç™ó]Œ“dnd`—t²©Hêş§È;Luúû7)½KC¤ƒ¥ôZõ9x•~ .¸Mê7U¯Ö;“Æ%RR,·&zäÖü'©Áê~æõÅ„¸„Û"_øø¦½†D¢Õ3åÇ"#RN=ô—…V™MÓËúŞ/šèP>E“¡“‘çCÔ×ëš‘ú¬réSBGÅâ˜*[.œ}_ŒšÏœÇ™¨F¥Y˜ğÎC•|™Cğx»)gú7¾¦ş‡Ñ
kÎrk~şÉÌå8²ÕZÎdç/N×{¯­ğ­'°_%3Áæyÿ»ŠşkL+!¿»ûCÈ›yÄ¹šâI2Ræ}º\=/öªŞü
{¯±Ô1c-PÃq:¦Ë;JWá`ï`ş}êNqx„¶ˆêy¥t–ò‘àt…@ÁŸ,›ëâtvi*“N¸"âÿ¦XŠµ˜Ö´WpROÙøR€h›´Ãa¨ù´ÖÑu¥VÅyï/%1d¹h"›E IÅc[.bK«i~²£ºªL‡ºö¤*ŸvÓ{–23>É¬‘¡:æ{[e\ƒ·:;à rïrzÖ\9f6@©|˜€FŠIHGPP2CœßÖû£	İiÏC,û<‡àƒ†igüæë!rÓ3ÓÕ¥Gİ\¶fC4ÓõuPüô[O»»‘äUUêôÿëî©FPĞ)@&ø9öBçá®šîCMA¿:UÆƒäff+ûêA¸C0Œ\z–ë:<v3ÔÅ“µĞE"bÜ¦ìûJQCDÂJêU¹è$àf¿.=ı+?Îö´¨]¬ Õè²XCE$¾@'RØ,Ş…w¹å\œ$›3v*Îï¨+°“|®~Ö>M«Æ®-A{lê¥0¬ÆçG°OÈ¢£ß©`»‘^íÓ-´P&!gĞCf'¥q^[JJÒÕ€\™Í\fP6x¹m™-ŸHòëv¢´|QGX\qá®«ªŠ26øMŸ[V*³D€8ÍË9},>öTtçÛÍãîõí‹Ñ†âQbm8aÁ~-xÌój”`]u~ŒÕï3…˜r8Ô3C	ÖRêÖE_Ä>ÿ`…+½]Ù«3r¥Hb×#Ç:¤bÊÍ,	)GC`H|ì!şæ{Ï1N­\QV¨ZÄŞÎÑÖ#‚ì¡;k±EÕƒ
h"­ÂO_Ü“,.P•O½òšú*–5fŠêHÃ´{ËÛC£®Çnµ/­ç›¬kCjØ<S/ÚSQûH,„Mèm¬9‹ÖdÛmå<{yph"Zò%Æ?ã\=á-r¼cÉbÁo†O!rcœ…®“c²ÕMxëÃ³ğÈ­.z™Ñi… eÔ×Öùju“fŞ</°¸iø~'3®ifåK7üFŸüTş™)*w_ÁL‚ú@(R­H§^ú˜«m¢£ã\²¤5ø aµøpã y¦™Ê(Çô<9í7¹ÙCpïp60ëÃGÛs±d¢"=Kî²'`}L¤m/“uì+Ö…«áÉ¨ßÎk"
ùø6îØ†Í˜×R#Ú ¬ÚWÛùô}Z\@µÿè¼(Ç×»Ô.1o^’Ï‘¥-##8bÎ—]rP6‘ù›‚20®ùNeaâzäÃùzKKË^=ÀÃwtİ˜0Ü>KŸuA|^m0G5¸ÉA­¤/‹3?Ÿì•enĞÚuÓòİJ@4Ä’üT®íÙ¾“ãŞƒJæbç¯»ÉwnaNé8Xó.àq»„ÀÈq"cıÓ\Š¿L4Ë§]¤ù{i6=”+AF=»’í=bºÑ8íJ"÷›ëÿAAÉ¥q*G¥<ù«B«”^@xîÌéi¢ª~«GAêûu ºKÖ°¾n‡dâ‹™×ƒ¯ ‡½ÛÍÓ8M ™”ä#+yÛ;ÎE‹~µ"ˆP•h2ØÊ4‚ßàØ·@ô Ma,³ª’ÌúäÕ8LR]¡]¾îs„ŞeKÛºõô¢o&^ì·@N	Yì¥VçƒL|¸îKyÎ7ìP‹B$t<¨§÷e%Âb Çá¦3®t×CûìZê_i][Ò¹.§0I‰,x^ğO¤(ÎÉl)®ÊóIšùÒ¯v=¸\Lı×Ìså%j³º*¤mÎ¥ÕÁ|åV šƒjƒshÀÈTÈé]õW„“qÑëb¹NÄê$õçàÒ‡s‹Ì“1yCÍ¡¬l;0)Ó¦0tÇÛÁŸû¾c_òğ‰…^zÔ‡ÜÉ rãT³ä•Dñ˜7¢*UÌ,êç`¯T4fò†³æªŒ+Š¡%ì©»²›Æ”ã¦ƒªÌLiäe6Ê¾ƒÔ1Y÷Šx¦'£'²‡#ú$5qx +ˆÎ"Ã¼ô©ÿöû¡% ÂB·8¼OƒRo.µ÷U/7J1õÆı0xÁ8Jä—İ™•"·§.‚ÒlúŒgìZTÇJâšNÄD°GScE…4\ıÂ3ÿ°1ş_­•º
=¦ÊÍàÕˆÿcË’EÊ„3RíÎa%&ú”:ª€¦!‡‹–°=#p.QTïUÅš!WG—ÃË`wÌYí–ï1TÔø)–&ŒœFdŞ˜éUõ ış7«V9.c‰ªMæŠH(‹t(m­8bÆ‘òÛyvyÂò§»é3ÂŒÍÚkŞ4I{Ø™	ÂŸ|õ0#ÿ®ü$áù<lÈª–'T+á˜¶ ÔÔ![­²ùlñÕœ!`³È«÷y|fTP¨‘PÃ3ë )c™Š£§3¸“[«­
¦µÙ™ã½ø½œ1™óÆaÎ.ûñ(Øâ¯/È”DûD · ¦Î¥ÿÀSU!{ajéò{@~›±A>ŒxÆ)æ`8;%|ÀÈº4TÅæj¦3LË!§†"Rzıf?:6º¸;ßrgjÈ˜ïZå–fÊ¸›³Mü.çEW©ÅJ~ x'º3äÎ[©*%µ”E;¾æ~! —rÍR¬ºØXm‰©3´I‘êy•¡‰k"¿5Ï@M½[°ÌGeŠVP®’ÙãÍD¼Ñ¦ë9â…ôrg/j?#RØ)YBQòîlmå¢—

lÌISÈRèuí¯T ±pÁÈJùµ1fğ&$46+ÉĞ5“ ¨Ş_ï7K²u:ÁIOÒ‹ —Éj8f·¹-T@¬M¢)¾D%ÒãäØÉH™Å¸ÀÊ¼)€Pš­3‹"Ã¨qÜèäóÑT»ga‚?=HKÓ}¼'ÕÁfÑ9&{ZÖNëb½¹òÔÜàÙŸ¦¡#< ¦ °|¡²g>pöMTëtá?Ë°µzèŠÃv!R Gú‘6,º6²‚è"íªÕÊ¬«JÒÉr.š¾AS)](úiÿ“ó’µ-ª­SYÊq¾Yÿ¶‘õµ!*s0Pm)ØÁ+T”JÉz<a0Õæ¨¶åÏûª!«X|*H¦¢ñ3¤ «?3üÌÿ4{«ús%F"bõ¨ŸU;Şh!Şò6cƒ—ã¨Ãˆßªş×r|Õß°Ó·?	Å_Èv¢Wï|6€²<°ÎOU(k¨TŞXpÒ'W7j?éí¢*\¶ƒHÌèAàxÆD‡ådk-N˜U½NÌ½[Ë¹–Ğfh;‰–‹{Oı`Ô Y†!–PnGÌø5ï¿f3È‘1r¢Ğ9’-»@$ô¾Š,óQVÌH°äæ!,hETzWT62Ş+•-oÎ…Ià°ŸZQ°D ÁßöiPª¥Wœ^¾u§tQÔa.jÖ– ½×MúN$îö‡7oŒçİC°~0Šú‹Ì+è!‹!¦ŒÄÓ%rz}6ìäñ—~\¢òŸ›£›ŠÌ†Šê?ÿû2(ÇŞ0Rx²Ú‚ºœHò'{kNîÉ ÙFCİ™6H“1æ“rÛ³+G-Œ-xíñQ’Ş±:5x#–.ZbCHG—>™’ZºÉ{ÚíXC¯Œ‘Ä¼?	m’âT~Áúµs\·”Îùñ!	|ÿƒó¯Ä"œ™CpA`´¤êègÒıéšür¶ÒŸ ¢­®6^éI||–^2/&—Ğİ.}‚Èöƒû{(»Ä™<ÃyÃT8rê$ñc©¢^tø½¬Ë êfsåº±Ğhòî[Ô«{êœá{„¹®ÛôÏÑ³÷I‡çÎh„Ä‡ôLP¦¦®~ãä¶m3íÅ’"C”óïzs™t—7â=Î'[n"²Ç÷"ãl7ŸìÇ­ı^t5wÁVD3_S>Ì8Å¬(¨²­1SÌsŒÒ&7ê¯š,ú¤˜··–lÅ®?g+@7AÍÓZ‡ğSH³M^³6ÄúO?şæ~ØÌ›eÄ(¨—õÉC//"©²ÚDº§€ÿGãĞîsk	Ãé°öØŸë95!~ú¨…0ú@ğ”&Cúª<¼»½+ºm`@Z8†¥»Bæ¸é7k.‰Ädâ¡öştŞ• GÀNuåùpNq™§`u‰ZRÏ$URÑg~‡`&Ô‘[Óue¯zòì;ıY•ËéôLĞ°cÈÂÎKèıR§?Y‹…Kx=k– m¯ø4¥Õ`š·bgIAƒ+H4²´òL’Ñ© ûWf{} ªã^Ñ´$t›X¿ƒŸNHòÔö]ú)ïúqÍE•o&äĞŒkäYd¯JÉ½
sD—•»î6'É·‡¢p(»³İ]´Ow‰Ì®®Sÿ¹ıó(ª»ŠœÉ3µàLÛOwiJ½£}E	F¢Éÿ,  ª¶"H2ë†TĞdÅ¨cÉ3®ódpÊ¢N 3ÈQQ«šûİüº<±§şÇƒW»º–“óqÅÊÌ‰›º]âPK!³~ SY}ZàJqRojáH³ôIÒìšİøC0‚^îÃ1Åÿ˜i&‚cx¶Ñøîqwd…ÙKûé¾à©¬vÕşâ$m2aà°8\Ímaˆå^À@_½ğc2ŸSDú/Àˆ…ñÑ]§òàÓºÏlÀA0«“{û¡ÀM+¾9BT("ÕûÒ>NKW™Œ\EKXo§J„HOs–GÑoŒ?îõÁÄ¸/‚¼Ì–“Tè"Xˆ']«RyÙ†&ám@”€w­1¸®Öhq*Îƒ]@b0œõÿ/£Çvğ4åé‘³ˆ0fªöËû[…D6à{Ä¨kõe²¼î†Uõÿğşæ N›nÓÃô“²^¨•p$"šäË^ÙÑÈ)Csà¿˜P«’u‡gÜq£!*‘÷QLş	QX!œ¤+N‘¸ÈyÂÿØíÂ0ÈğÚ´Ø©ïÅ>@=¸%à;Ï(Í‚ûì;Ö‚üñeúµTgí¸NG…@±¹(ğ¸9úCzuÛ‰ş"†_á¾³ ¿ƒÈs• §!á c¦šˆŸ7C÷Ö†?óx{rïŞYÜáİÛ±dFºƒîæQb>§4©}iø/?ä¥±ÖŒiH¢™“9\Ï(õÀß
÷daæKR$ŞÅ±ÌèˆAg/Ù>p³e×Œw!'ñÍaò´32g19jƒŞzù«SØ•¶?!rJĞÛmWw<—là›ü©8FçÎB´¡1v7e·ùü(Â$ZÛG‚óÅoÉµ3Õ62ÏJÜxIG”ë•<0Ì PZ7_G€İ/”<esSbÓ‹c0b€‰Ü.„u~³©İHgF²nÇKÔĞÎ‘’B’fšL±ïc¨ƒ‡3Ó»ßÕ‡DÜ¾ªBT¹wœ6vpÒsmhº¨ØEšÏExl³ß¶Şrš!¤œ„#ÆfÍı\Ç½…¨ŸØçBVîUëCZÏ²7 †ÏJRö wÔä–§ÿpqì³h×$.hnÑ ÉÍIŒH¬~`ŠÌÌç¬àa¥U‰ey:‘û­„X§*f^1ÄÛ~µ‡)|­š»g^¢:gI•‰ƒ0¾ —Mñ|ä½"Æ’CæoUà¨X{‡Ã%Äß¨FDÀå:‹òÚHüHxy ”:ßU€&âa>qüıéİ8ûûZ?“Ëw1Üz";<–™û«ºàBhN¬ZMø]M¥5!Æ0€K<öj‰‰ŞµÇç [2cğ©ìYdñ¤âó©¤ôn‰[¸]7yNF/Ó¹û¨ÆT8""S4./Ë¹7Â8lQhÙ4ğQ+Cy!S]¾† ®Z‹wJ	ßM{‹àíuc=ãC?(áÌ=ä!ÍL…zı™¦½ì ß!-‘!,#8»íÕ..ï›OP@}Îg}NaÆd¶ÛDj\\¶‘7Ó¶×#rÑNÉ›	vd¨‡JÜìw[è5{¦8’úSJñ]4ajÎıšh`DRÄ†˜^ŸöºÛô\U(â¦¼füfìŒrŒşİ@öæ<4ôò}k®xcúhTCKºSm~QË1k:ü•Ü_=ŠÏ÷ïè»y²}i÷½¢í82Jfg"¹–c·O|«å¹Ÿãî©nÕ@Ü×ÈÆWŸccñ&	†‚¡K´ñ½ğ+iÓBw2Ô4<0Ãà «•ğÀ\†p.Dk:òÔ*Ø|NXÓ»›OtÅ ªuÂoÆaÂÆªŞ‚jAİ¡ t¯ò·õ´sQÑ©ÃfE¥}]²¢Óÿ!ıÇ^!¸DÈ¯Z­†\Yê­œ5<Ì^ßTbÖ§p+³Œ’öïÉ©ÈÑ0eûu€˜tÊ!nÁŠÙ&K\X¹#ÕÖçãT‡ÎV•Ÿd7uQ¨Åcáßğæ#Ã .¨ö–à°ıÓnLİ‰…ÛĞ0×ÿ+c¥ÃÆ•ö‹C­f³!˜öf¶¢yHËÈ6Ji.êê*ÈÚÕXïØ‚%{B›òPGx™èÕnƒ¸‚fk­ıí#'Éæçø“÷&öŒK Õ€×ë¢N€-	ˆG$Ğdo4I*|·‘”Èˆä&nCĞÈÍÀ:sÑ8‰E¡wWÿ$b¯Ërº¤ªOjAˆëf FÕ#P‹kç`Û°£~%Àçàª^°–ÔaÉ¤ã—ÉgLõ­ÌÿÙñøöçÙÕ–æ
iĞü¯%'U€·@ì¿]n{ópJÙVô¾¯\½4@fYƒgÃÏÃ{ã^ ‰G‘ÂK­²‡ã42ë„gV´œin5êÌÇc$›Æİ”2šş»<ıv‘NwD(Aöàş¥Vê}qvÆfı²¦M“aD#É»ÊãqA@}êè,»>YÍCCL!å•*¶n@ÅÜe-k|úÀíåÜ$­[5•Uş¦1îz‡Fväk×ÖBtÒÇ`5jìÆraù½Wô“ù•z”·‚z÷!I¼;L‹»Œ§^ù@Ş¼Sü73±±"¢3m	ØÙ	a°M 3ñ*óƒEÌÒZ-\º>>å/-’û²dá%ÄåsĞˆ©@Å¼Şï³s=§aIÊTá“×p®µH+Y"»|Ü•<ÿÌ@ŒO–»Øn¾«f€İî´™—h¦AÊÒ€’½HSoRãëXÔ2U6ğ+’»ä×Ğ§à½´¯éÜmãJİ‚Ã£°«²U¹şÂ¸ÄÜïäi®	KTûjYú20k(Û¦{T€™ñg‘¨°U#hÛĞ¡Çç²|©ì,%¹¬ÁÒ·ÊÂÁòn$xù
†Z›Ò³íÏ/rúOE!÷¯,:'Î1 À@‰Å¨éõ|ÌÈ`Šİ^”/ğ´>–A†{®ó)%ìÀgRİ‡ç3(x¼¾â.•dÀ5cî–.÷bD„€`GrG åDºùà ˆéKÃo;öİ?ÿg¦…#ŒQòH¹htní†NO2œ†|àÁ‚I3şzµ*ã7úÑWK¡²‹¾
-¬ò?ƒ>yäx¶#L>ä2p,ùA+jd}_]Âëz[*Æ¨Pnå¶¨\1ıI!!™_2ÖD¯µ²~ĞH¿–ÛÌ7¸kãÀ'-HÇŠo,‰şgh‚.W!©[wÜ¡Qú ´ä(Íæ¿¥ÄÊE¤l¾úÇ.ÉÔ³ ®*>VÔšÕj*h3oĞ®$rÂk¶ğ-CÖ”ãıKà#R¦ãş^*MEK¯eğ>oT®n¼P*K.j°ÖòÒuC.Æ¢ôX[Kyœ´;ˆkÈ»jxTçšÀ²Ñ‚ÿ÷&¿ş-Ö´˜)~S„™½—ÊŸp•z·ÔÁ|Z?’sÔ!OŞQ«j±ZJîÉ…9IOÍt&§ş8ª4­Â‡–Mş¤ö»çÈ:LÏuŠ§S©'Ày,»í¼e:ªáÀ½¨‡·®½³¼íbKAIÇ;üƒ¯_ª8UÆÎ;Ğgkú±ƒd­ODøØ«[„*	8äk|Õüßd¹3pÏ1=Eûù;én‘÷¹ÇkÀ_¤Ö—½ıİSïYÜ0‚ó‘i]‰cÌÛßüGàa¾%€şWÆÂGÕUu'yÉ¬å)@40dáoù5Ğú«‡²ÖcÈï‚ÒªZ>ÚÖğîçL6RÕX[U´şŞqa3…Ü.{¸^ócÊG4ƒ®` ¹õæŸ’nÌ6µii›ìirPfÌK¾È]ìBêú‹f.ªûÍs!‘4ÆÁèÿ>H]K¶!œ@>,€ƒÇc|ê¦ºÈğ«ÀY+§Â|Æ9ßí´‹ølsrX„~†Áâ{¶[Às‹v]Âİ÷í‘ê¹ø@mfŞû£aÀ£d5/%˜³?½3„@– nç#9kë¡0Ê Ë|2„y£ ‡$o<E¡×e:uóüŞ¹TÛ8j‰œ=ÕÀ	d0…wX±EyÅß¾Ÿe+¹ànekÀ§-¯â3¶ 9Ğu"8\iæqâ¡(	a!¢–/Ôv:÷ÑÆRÃñÎpk'äN¡Gˆ‚¯ß×1Ğk/ÃèQFKj&5=Rª"éé=™!å}Ã„š|c.WêCV¡ºw³Ôb 	SLûÒÍV!~Ú§ùºâhƒŞŸ/(Ê®zIø[»²¥€MèF»áy §rkÛå÷
Übf’÷í1çô0Ü#0	'Ìµ†ˆH Ñ[6ÿQ!SÀ¥¤â.%"Äw‰óâJs¨×=x¦Ì ¸Œ± ÄéŒçÔ³òôebÑDçùøäxF?§UûQôÈ&ùÏ2_·ŞuA&ö¡[ã»Ï}ı
ˆg´É¤©EÎÂ¿)ß\H§ÎĞÁváquÕÛÙçì±‡8¯8³ƒLäÌğ§'uDrÂ!ì‰H0Oá~yÎo{ÇÖ%_mÿQ¢]ƒiÉi$6m¦­0»~„]à?Ö^šâ<×ÆÏB6v…ï«Dl¨µö©%”‚|9BH6-ªOÛ®G!äÜo¸nÛ_’sÚ¶f%ƒLhn>«‹±i
ğSÑPnİ|)ãEš$“A<>Eí#WüG:½üól0ï¥ânÀÕGÕ
Ov‹YÂNÑrIÎWxÏ.YÿëíTÎåBÏD@Ø¦“[™9x¿‹ÖM,?ÎëÙ1×µ°&66L'zÕëÚÿô¼?œ×©7;`†«Şµ0·ÆÕÁç9€…— ãÍí¿ÉV\³JsP‰‰v4é„*åXPë#H÷Ã¡îûaùŸ”’ÑGuwqXI›³7sÙ&Xs7¬·ıô®GàÒ¾!\ÊüPÀ’)‹I•qXá©§›I‚İdı¡çLí¼Û^#Ì­¼ÏíÌq…V’İó	ÎÍJS® ÇlO1Æ¹	f¦ÆÚ8•»Aş{Ù®E|£…/¶Ÿ'8uc±OÑo)›F¬§bn(vxÊV›2rƒ*.ÆèlJ=mØ^ßß†îe)¬9^ÑÏ¸Ô¡OØ&yõ´¤‡†XemŠ­ããÍS—8¡<å®2ä”_,jİq@ŸË?‰Á`°z1ÎÂğ-Ş­d	óã>sa  "?Õ,Y” nj¸ñ<M`ĞĞÕ{ìKÛK¸¨ÙX„Âæ}÷r)Ô¢ÑKj'õ[N)¦\àj`‰­½xù¥rsá|¶Ş£ 9¼`@úz†™Ï-M>¬h®Ë|U½;î¿z¼Ÿ3Ë˜Ü57ú¯ßÓF:‚,]³bL·•@0iwèÅùş;Œ]¯9GÓœÌ«oî–Ñ4i¡¬ğ‘ à%Ñ Z‡ å³´èÛÀìğõ©%¨S’b*˜÷çYQ–´”Cã~É‘‡@øE :^ç
ÏŞêØVk™ñsÿ8˜ˆD—Ö“\İÜğ½„h‰°Ê%ÍéÆ¹ ~¤Æ0‘à~aƒéû–°tWıåÕnÛmŠºH_¼¬h$
zÉ,İ[›¨R…*<iÑõ"O›‰‘¹"Ôµéä ÁE­É])ÏtµêBŠh©®QŠ€øš÷î/¦Ç4¥W½¹2‚nƒKI/_¡ş¶‰]Ûp"´Ÿº_WÑàYnõ½ËÎnv«rîø÷¸779]¤6AI™×…Õ¾ÙñÇB#aàâKÓøÕcì¤o—9S)˜Íj]lí2ù‡â	£Ece˜H£ĞŠWï
‰‡ã>YğkÚû`Mç•ªe¨©"²É*J¼‘–'QñW¾jœS> ƒ©7ñK\Å7ëÆm"SÕŸÿVãBrç¡Æ`ò9àƒ¹~	ói~‚Á‹"q‚”?Zú÷ïÖÖ“¡v è¯‹^ÚîgBÛ/AÄÁü×ËÁîÃÅ]¼%Vg¸1«Zƒ×UD$şaå}û;VÓÁÒİaGËÙªEk•üPš%ÒzÂŞM*Û.ŞËŞÔ]f"ÈÀpƒ!a ¨-ôøù#]øG¾}¤†ÀÌ²y›„¹½l@bây˜‘7·PL…Á~
±jøæûÎTíèwJçé†vúNA;DûªŸsßv#>Mø¯ê„—ÑñŒz%™Ã¨ä,FÆ®ÿM¢·ÍlŒ=Æš8sw×x~Ê€È
å­-4›ƒç´Xïs`;ƒu¬O² \Ñvq©Ë}TuuC÷„|}—§ &ğ U…«v°Ğ£¥Ñ	ƒ N8y~7 Å ‹ÀÊÖ^JóK«F²ıâ	+ØÜª$A|… DHÊ.=íqF:¼ñÜì@XízuÌwÀc´g2ê¨~á«³òIçt•ÖæcBø¦a&F¤
¡Q3O&–Õ;Y;¿ŠuÛ®	ØşEt´òÿûËtøì®ô©Yl¨V‡oñö…¶3=ìÅIs%ª—CŸ’“_ÓŞõ™Ší™¼`7–¬^‘{”íØ;À/.û6>„KÂ¥?œ¦ûpŒye½•Güú‚:Ú­¢ÕÅúA¨‚R£Ë.óà¥Œg”œ4…„¯/@ÀˆÇ½K¼§¥ö7ç+ôøZ_ %´Ÿ®×@Rbút=IÜƒfÒF2!ù^6L d»Áí¤¢œ½×šÜŒ.‚í¾C¾,ziÆb½v•ÒËø]´Ç óŞ²•Èï/2p¹³v°äCøQëUÌQ*’·éû„¨(­h)Fx®ø¡#Ç€ÅwÙì)üêVè~ÍS“okçj5^ÏÅZ˜·
(”/Ş5xİ¼ûÉã÷u^9¥ºTÙ0^ºqçé¦N<ø*s»|ÇéÕiøùæ©·S¶%_VùíÒ"5‚Ïg¼`Ô^á
ÊA\™hb5µÂe)x*»—òôê–|{ksÛx`91AEwh3U1ú_˜X¿ËP?ËÄ²IFˆJ«Œµ–SL÷ioˆéB-V@KiVé‰gÅD·jy_éL¯ú8á:¯¨“MP:‹E¥òŸ¡¢=PÇÁ^Sx5w=f \…9U™Qp¹¸Àuqš£t{˜#!!x!…GË·Ò3!	ÕŒ?ï&\ £~CÁ{µe†ñ3ÊÅY¾•2È­œ2s¤ˆ%m	)¬E“!µ¯àK`9êšn±ÊğÚ>Jj[6Se}~dâ’YLPä­ó8)(¤Ğ˜İŞ77º¼çÀÀÈLĞb×`9%Vÿ¤„ÉêÚÌ…¥5ä}¯`i&tZN¥7Ÿ¨ü’³ÔW?À{ŸõnÊÓÚ	x5äÇ‰¥ĞfX…Ëğ@Ã›€¸ÇWñ³qô£¾\?!fT–*á!9-òeü¦B¡´VæÀĞûSòd8“ìóG¾JWªĞLkZ« ÿa*L…>CÉîÍØ!¦¼öŠ@\L(:cëCòñ‰Z¬Ä¡Î5Ã¢j”.¤¤‰Fòüs1ÒÚ¿¿ ‚¹tk§êbczx
|a2>e%8~Äé~«SûÄo§fš»J\	¸¹$;Î¦×‰[ŸöŞÃã±‰•ûøÚ¤:|$@aÌä.²Ü‘lÑõ°´´!ENB½å"¾­8J!!÷‘åsX‰ä‚¤@±ÊäïYV"1m¦ošğÚO>¸ŸãëÄ)¦±€Òk‹&çó’µ£P>¿æšiNR»°"àõG4à‡QYÕ@¡<¨ÜÌsÜŠEÖñi’”‰Ç[ó9DOŸ.XÄÙöL/lõîš}XÄ?¢ÈMô¹T¼M(mÿË^R•%«T³²›+»zP@å-'¶àhyHÏğîè.>+ŒaóÈn¾¼=M4¾%œ`.­ÜNˆš©g%2Æ}ãdrü¹˜û¥jÓ!­Œb]ŠiN—|#ØåVĞ6İÊæE0Á‚±_ßq÷LZR˜Ï…ø!âï‘&<G¾@ü'(YQÔìh#KŒ$`})H çÀUkŞ·$ 6ä>W)0 ”—Pí.¼8ŠIúaúq\¤	|blö¢;è÷+XŸÆ€}"yA¥ßÏSr©×`w”º ®;µP/áÌ'"0Ç³WÊ	O ƒ’4J0›©¹Ì¢ãq)·:‡#ïJ(v~MG¶©¡Dyİ¡‹ô¹’f«,ê£èÃá¬2İy6<*»}·ÖÏ¥Æ—¾|Ö¾Í²Ö`¸¬™W×AŠCÊ®cÉŒ9ø°Z ”T@:ùNBß•T²ÍèUNxz¸îe+İÔí:ùˆ‰mrÛlpnª(7ä(‰'XQå)·Å@"‚v­$¼ùm8${ĞÑjv$"°pâ¾«Ã«µ²‘3hõ‰Õî£]á"³‘[!ÏÒêËôÏ™’.‡4ÿ™ƒ€ä€JE$o—<¥ºk> ÿìÍ„Î,piašx“Çïâ7ı<º›Ÿ¾‹f1ÙÙŒkºz\R_ÁÊ¼¨[:&EøTá0$ÂÑ}~7²ô©ãóã6„xxŞsG+woãÊHıÖŸ<7=q|í‘¸—V«ŒÕ_GYÂ'˜|Å™HÒAÛ©ä>Ô²®ì”Ÿİšw\Ì55&]_Ö3/Ç;@jF–¬<ë*‰Ø0š>¦êRÑíå,¶Í ¯TÙ£õÂƒ=Âu’Ğ¾_¿Ù¬øZŠi|o¦şz¸sbÄ¸©h‰$—åVæÑ·K®m-”1 ÷C¹ÎKzØ2ŠC–cÕ­ê£÷wrÍÿzõ:Æhe}Ûbæ„öfÙMBİ»Ê&Ğ¢]%Ñ²[¡fÆv%æwd$˜=ŠgÎ/}›
ÆšÒYzBÕHVÉµ™‡×ºã€5"+óòvx”¨ékõ'äW/)á†ôòÒëhB;'<vïÜœ Ø­ë‰–‘‰üt£V RKÆ/K-u©ÈEZL$¡jşç@t‡çŠiÌºÓ`L€±lÙ b¤¬!À#Uß¢CÀğIJş{Fıq©l/Œ\øÃ˜bÈïøXs¯Ëg©Ä[°e;)âå†|tø˜tmxwÎÓ0_m ÂÒ	İäˆñsÀ³”Ğó[lŸëm¹Ô©[¡|îinq4T€4ÖÓºŸĞ1aîI^-Ñ^Ûßlì¦u—Öÿ©©®iœ÷c¥O}{TP;ÖæÔ)oÇ§ŒØ>tç¤ u=Ì(2æº=4EßğcÏè	ÇR­R£eI¶¶~óT’%é¥)ø~úê4;í_¿‰ˆ<Ln<Œ•çŸ.ã¢øŒ„¬Hfoª*Ú>D’ªàrÄb^h¥!MUÃQ4}~Ær¥¬è`}O¸và#s!÷Õ<Ã½ÅˆZõ¼Ñr×F@S¼¸FP–Ğ£ôWıı#z‹W°^òg“¾mt³JÀbEÖá
Î¡ÿø|`Ã
1y$Ğİ¥'×azZÙ’M‰7WŒ•0·¥ÆŸeÚîW@š%z¼X¬QlÄ®ÁúŸwÕ!ˆ×ÖÈk¢óñÊ*Ş¬k «ï¬Y7nó	1_ ZÕ1Æ“ÓFîIRã–¦ô¤Kéh›KÅ9OQó§·ír}ğ§Ó¥>§d0¨îOMhÿõvûyµŞQ×yqœ)IÜx½»Ú i¹ü=Ù1Ìpç˜Ş±zW³)ü*ÕDçL9S6Ïšá÷6’õ
ºB…«ì›^R÷”µpªUU2!´a\¯vrÏ1úaã~\¯Ï[Vï|'fsVOù•ş‚P˜°İ½41¡¯ôeÚıp†cÊ
Â¼JÛ_†QÜõ|˜œQ)ñl,Ãk°wF™İÑ½$Z6ëS)¼pØ‘Šß™23x«_âl£sƒØø0„Dh¯ô–½ï2V6â•\:V<çL°ğ7Iˆ«Ò˜•´ûA+
dQ*\Oì&ÕdU7“Ç8jM_rC©Ò½Ä‹˜¼aÎw™Õ3©‘<OgÒYBÄ³ÅìaØmç¬˜hZ	S<vAõA]¢ƒ¦P—lÊh²Ü5œÔm\ğì¦•¤OĞYfnb§@˜·«¯D[¥~x¶Š»BÜŸ1r¤~k³~6ÂeÄV\9?•íÈ&6ÖK°¬vÏR²vŞd+`£„~¯vyPÏÛÔ@°«âÍıKˆ3
ÈcÚ2.ö2şj/`ßjëUtÙ°¸hhè
ìÓÛTâg\Ú4Mƒ°¤÷şdík^M*G@ÙóE¹Hı"L‘ÿ{ßXòF;ájñ»z<äØ¿Rj±·v¤h×Í‹;•rLk¡æøŸúP†¥–ı¿©ğ&Ç>Æ õN={K…ş¢†Àìğ‹€yu2ïbID©÷ä#º‚(­>£ìqáÀİ™¯	,Ò¦'aÇR¦FÜYí‰eÖ¼¦£ïÊV°óqÙiÑ5RÍ™6›pWÁHì¹
VN÷Lxul¢IóïÌAMó8»ÁÃhÆ\„²íÑôVÇ"S;Ó¨‡$U“ò¼Ók¡¤‹4ãĞK{Ú¼µ‹Ç@&j+-ÃZtqÌ›ùX®‚ÍÌSLŸYÓ¡õ!‰TÎñÒ—æOesVEÓO™8ïù}€áîmjÉÚÔáyİ÷/ûtv‚göW`q;.ã nÇş{bÛEÉz49Ò\
H¹c|ÚâD> õ‡Í@*}„Ûûæf•Ìñ)ÂL¡Üç¢Éõ”ä$3YØk–9# •…›½{êœbÂ–  YgøH—J%ò@œ÷¨èI~‹ÎÅƒ“w#ô¥qİT”hS~ğÿzAsšúUÜåïsø‘–ôdN	X4êq,åâˆç¿ŒÌ®´Íër-á¤»¤¶lwl'Í!}ãc-í(6¤–ïm	‹¿ßWı®‘j]lÜ®ÓlJ¡óÍ±|¡N{ŒâT ’áX‹§èwé´‹oæ><¢âÄmúğåÃµtÏôÍæĞÕñÍØp€IQÉÊÉåY™­
'É-76Í³ƒìrY!¡Jå~2OØ¸Ê»;6ëæ?‘7n2c¾Ó·¶Ÿëüşî‡©ÚHßqÌqR}x›[ğ–Wê··C°H0xlj]Ô[­·M”Ç>@Û»Ö‡”-Œ¹™ö°µ=[f}´¼×T¯/§¢‹÷zyoİW´äZ.WâØãPz•0ŸÑ“7‰L;›¡@ñ^ ôÁÛâäÊb6! ²§×PíøµÚ ÚÊ½r'º,Zò1Y/»F?^àå6yÙ–¾÷€Îúõ7XJ¯¡4köÉ¢E«ÃÄJ·HGKà‡›âO5’Yçş®Æ…Q Ô®@æƒÕıVŞš?Ø=TiŠ.Jnà¾°O×ôª‡‚ÔÔ¼¿39H¥…ÓÂA)ÈÂœÀ sü—Õ¢ÓĞL¯ÕyõfMSÚÅò²„t÷#Óş?J•7Y…4Ø¯õÉfkµQXJh¥7ÅœJ³`DÒôépZ¢ÿçíÊ9wİ òpWÕôcF†I|pN%;p¦—:V¨àmTy2ÒwfR°ÉhJõ°™áñÇà9{¯.%©˜·Ç%-®ï4Iı‚|áqÉ–€e‰1/¹P»şòÒ‚T ­ÕÉ4ªÇ}q·BÁ6"kÖ#·‡ÌkPà<(Í
L(I­9)§~Ï¼=I20-gâ¢¯vå)9  ´¶åíÃ<ğ/£Pm–×QöÅı	a=%XT“‘ÙÌ{ct´ét7~_B&?eÒï®ıÇ;•¿P¨ğ)^£ŒóDgÃâõ­JÖ¢eñÃdWßıÛd‰ô¿ÿDG2ÃÅ0*ÇLUGïÈèz42.9AEÍf,yy!±†KùXÀ°‹©ÒIbš}û¦DBrå=T²¼À8ÃcP(·ŞâJ$k”É[Utn?O³Í@\–ÎHÊ¯É$¿$ÂÅÆ•Äú*rpÎlWş,³ŠnÙL#šBßıÎªM«?FØi!û!«¡„ŸdïòÖÂÚ¤æ\–˜`N«ªê†©&°S¿¯ş™T©ï#/ÎÅÎ€igI &Éı’ÔôD$7”ICõ½%iÜt	bxØ`G§æi5Ø“ÃèÓ‹2€Š‘b²ÆğÒŒ®;äûñG—°]¥Ğ„	ê~×ß¾µc ÖçÃ÷CJ[‘-èËÿ“ê¾³#•Ğ„İMõÓŞQŞ}gÎ§¹¬À½?kO}:ıà5?àgÑ9Şdì\©oà®(ÆUÂúŠ;Q„vøï^³ú°‚˜b–èêóY¨‰ñtRØpË\XU¨¦šÆ¾yv9eİ.H¾&®*Ô&SUÚ±·Æò¼8Şùš¿•û\#~ÒPSöŸúZQËÂ Â³:Ä¿İ±Ä*TE{§Ä3“û8À&H¦#©¿+Œ•ĞwÆÈRÊ¶˜å£~ëœYD‘·È@Ët°÷3÷«¤©ãÄ5µ¡£R‰üçôZáÙßq‰%§N´<@¯_iL%ö@’–n¡ıEKÅ‘R3\L^°Nßˆ6àƒô»<”3DØN>\¶İJÂu}{9*=Š±Ç³	”$ µAm®~5€F’İçóİµ˜ıÒqmRÄ`‰ùÕÛŞ/Æi¾øÃÑ9.İ[’@Stkö?ÿG6Q“]v tÀ©Üœ·PiÿÍğ&±Ú·nrÕÚûÌögmîÓå;GšøĞw¼ÓN›ZhÈëU&ü(8:’#%Aç±è<y:óôÛ;Q4LYn]:ø6/
ZÛGğâ¸˜HÌ+òÍ}ürXúœmMûXªà«ıcÌ`6×a ”ôÜ.‚_ˆ ëŠë€ÉÁJ@ğ×RÄîFGî@±ù
)¾J&09ùØ€¤·šû!FššD˜ŞbXüì=;¥gÙÏ€7¼ÖmİìT-Ù±GrˆU£‚«yì#€·Ç3jÉmº—gV%4|àHJA<¶ñuZ½TÃÉ´Ív`Ò$§'ŞIfé¼®Â®
”fSÚY(_İ±‘'§ˆ3+A#®ô=?6²cÒãT:	Z8öˆN8Gñmˆ\Û“êf¿ÂÃ2•¶½qÁ•cO3óÖ}"ëşT÷âx"¨:,JbŠ[ëìÈÏGz×è…ä»ãe>q 5ëóúRĞJë,*/Ï²_ı4ôrT7p4:Êcõeª¿=›3/4‚r±XDÓæËQš©f‰M	Bİ¡¥ ÛÀ½~âó*M  »µü©PíÂÁÎî43Aikg!gÔíe¤ÕÒLsMs›JŞ h_§Yq<>¬›­¨Ñ;©aTÑ£‹l–İ8n‘#ô‡£Mûhp‘2+7O‘GyI¨MƒSÔ’Q—™šyb¹¹c¼HåK>ıè‰A$®„±úœÁ_z,$ª=»‚ä†çF½ÒD¢úpd"Z_W¼y’ô&áO	AD;ïa„¦¶€_õ‚½¦(’Ou1¥ÜúÕ×‰[×…÷çÈüº«NºÙ1äè{}É®éÅ]½îOuÄöF%¥&}-òæT‡®âÅÈ;ùÅVçÙ	s»{àX*9úòHĞl”VVƒVjî±k2}:íïİ¹3ÃT’ˆ'—z½ü^|meVkË ]´ü2Ö½Şë\}À”lGÂ¶;³i®c€`d]Ú/@÷”QøV%Éµ!áù²R¹6—4ÃX³²tÄ“ÃD$±|óåª,ºæûXÀX“Ô=¿ÿà5@Â_m?¡¡>B>MuŞbúï¶ÄÔ%‰‚ £súÎ/ö$¼,}bÌÁ,¸¯#7ß\7OìY»\™½kfŠS\+>/‘©šÁ<³j4D=á…îÑÜºq áõ'´™ñvuÓRQ£¼‰ç7ù“ÜÂ7/T«Ú¸¦¶)øğ<5òì7	®‡ô+M?Zç"÷¦ZàA©-»dguŞ‘-@[©*ú“~à˜MG{Ë"¦³{loéÃ|ü&aÀZ'ñZµ¦`íß%e^Šín¹¬wqï‚‘áG¤ß  Nk².â$<F „Ì€ù‚L±Ägû    YZ