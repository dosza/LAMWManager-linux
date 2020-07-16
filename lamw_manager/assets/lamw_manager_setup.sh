#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1043691754"
MD5="f53bd3c33078a7dfe69ed13356b19dc9"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="27316"
keep="y"
nooverwrite="n"
quiet="n"

print_cmd_arg=""
if type printf > /dev/null; then
    print_cmd="printf"
elif test -x /usr/ucb/echo; then
    print_cmd="/usr/ucb/echo"
else
    print_cmd="echo"
fi

unset CDPATH

MS_Printf()
{
    $print_cmd $print_cmd_arg "$1"
}

MS_PrintLicense()
{
  if test x"$licensetxt" != x; then
    echo "$licensetxt"
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
}

MS_diskspace()
{
	(
	if test -d /usr/xpg4/bin; then
		PATH=/usr/xpg4/bin:$PATH
	fi
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
${helpheader}Makeself version 2.3.0
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
  --noexec              Do not run embedded script
  --keep                Do not erase target directory after running
			the embedded script
  --noprogress          Do not show the progress during the decompression
  --nox11               Do not spawn an xterm
  --nochown             Do not give the extracted files to the current user
  --target dir          Extract directly to a target directory
                        directory path can be either absolute or relative
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

    if test x"$quiet" = xn; then
		MS_Printf "Verifying archive integrity..."
    fi
    offset=`head -n 526 "$1" | wc -c | tr -d " "`
    verb=$2
    i=1
    for s in $filesizes
    do
		crc=`echo $CRCsum | cut -d" " -f$i`
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
		tar $1vf - 2>&1 || { echo Extraction failed. > /dev/tty; kill -15 $$; }
    else

		tar $1f - 2>&1 || { echo Extraction failed. > /dev/tty; kill -15 $$; }
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
    --info)
	echo Identification: "$label"
	echo Target directory: "$targetdir"
	echo Uncompressed size: 44 KB
	echo Compression: xz
	echo Date of packaging: Thu Jul 16 03:05:24 -03 2020
	echo Built with Makeself version 2.3.0 on 
	echo Build command was: "/usr/bin/makeself \\
    \"--quiet\" \\
    \"--xz\" \\
    \"--copy\" \\
    \"--target\" \\
    \"$HOME/lamw_manager\" \\
    \"/home/danny/Dev/LAMW4Linux-installer/lamw_manager/assets\" \\
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
	echo OLDUSIZE=44
	echo OLDSKIP=527
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
	offset=`head -n 526 "$0" | wc -c | tr -d " "`
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | eval "xz -d" | UnTAR t
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
	--tar)
	offset=`head -n 526 "$0" | wc -c | tr -d " "`
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
	targetdir=${2:-.}
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
    tmpdir=$TMPROOT/makeself.$RANDOM.`date +"%y%m%d%H%M%S"`.$$
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
    mkdir $dashp $tmpdir || {
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
offset=`head -n 526 "$0" | wc -c | tr -d " "`

if test x"$verbose" = xy; then
	MS_Printf "About to extract 44 KB in $tmpdir ... Proceed ? [Y/n] "
	read yn
	if test x"$yn" = xn; then
		eval $finish; exit 1
	fi
fi

if test x"$quiet" = xn; then
	MS_Printf "Uncompressing $label"
fi
res=3
if test x"$keep" = xn; then
    trap 'echo Signal caught, cleaning up >&2; cd $TMPROOT; /bin/rm -rf $tmpdir; eval $finish; exit 15' 1 2 3 15
fi

leftspace=`MS_diskspace $tmpdir`
if test -n "$leftspace"; then
    if test "$leftspace" -lt 44; then
        echo
        echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (44 KB)" >&2
        if test x"$keep" = xn; then
            echo "Consider setting TMPDIR to a directory with more free space."
        fi
        eval $finish; exit 1
    fi
fi

for s in $filesizes
do
    if MS_dd_Progress "$0" $offset $s | eval "xz -d" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
		if test x"$ownership" = xy; then
			(PATH=/usr/xpg4/bin:$PATH; cd "$tmpdir"; chown -R `id -u` .;  chgrp -R `id -g` .)
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
    cd $TMPROOT
    /bin/rm -rf $tmpdir
fi
eval $finish; exit $res
ı7zXZ  æÖ´F !   ÏXÌàŸÿjt] ¼}•ÀJFœÄÿ.»á_jçÊ8.&N}ÖóÌaTÑ"Î0¾-J¬¤fg•`máO6jİ[‹ş”ÆQ]ôªßvÕ…N½µÜYÛÒ—>Ä‡…6GÎÆæèJ=©UQ²M|¸ğ»N¿=³oH!,ı´ì§)–ĞÙ7ıŸ±e×
òÕÅL}‘ñ‚k`)ÈÛ= Œ‡xœTH‘4o~L*û——”ê¶Ù=J´š‹Å9t’*$âÙ‡ñÜ;FÂÚ³Râ)–˜W§ŞƒKC
—+rû{âJ4ŞIß¤ô>°4êÎ{²×TÏ:@<ÂöÀİ¼KvŒ-šõ2ì2ğ÷;7 ¶ÓAv@ÔèMb¾¹K¯åYäËˆbV-—U6ñéNmÓ³7íŒÑ§ÌÒ$Ò]u/b˜L±5C¾³`ËO‡.5RôûÄ‡KIù\3¥½úÑfØÓ‰V©Ü’5·úÿÌSè/Ó
æ`)®$ÅÔŞozÏmøÃ:¢ØJCôßÿÑ2ŒWÔÏ‹—1‹<¸à:‘öÿr÷ÄøOı‹æ?ê‘«Ğîğıİ0TŸ¯rdª[ÛG´®ÑIxÆÄ¬øÓ‡†×"Æ¡Ã¼!Ğd³7?µO~¯ƒ*W³²Ÿxºâ­¤¥ù(:»L'øC:é²§o.äbfY²nİóùr—VØØŸIl­oÄ‰¶şG"2dñØ¬APOuÂV²•™“çÌ›Íyß”!Äª¨ÄÍ6ö¾Kşù=ÄòıO-—5²#ÿYr:Bëgl€sÓyÙ=–3ÕË]yÕ7b:¹×¼Š’‡Yœ:jH±Ñi„¤;ÈºxAÜŞ˜´z's‰Ğ_²ËX–‚LšÑ˜oJ)<©\9³ÂªY?{A¶ï¹-.rrŠsŒTéêr);'kb¸˜ó'uõ ·««ª‡Tˆ‘2†nÀø7p%däp1~38l,ûÎÑº–f~,¬ó©‡=±5»ç_Ù$ÊÇNYCr|Š¹L4ôm}P~ÜU|yÛ)ĞhŞ‚İ‡g{#‚¬“¥q/H,Üiˆë<RIªı¼[õ?¹‘¼Ï:¡W½à™¾êï£;’ÔÙÆo@sA¨)ºuNÅy‘…‡Ø©j[¹q±$pØoò-CgL.Ó
-]ú*ào¾Ok~€Ğ
ßûk`Ç*Pk»³*‰9§y¬³ØŞRòúW¿„ ºHœy]°ûÖÖ‘ö¸ª70L´}cÄt‘ o¸&ëqK¢å¿íØ «!cŸc¢òZÕNØ'_É¸«İ8 äéáxM/ga&tm7Œú—	è”U
g¹Û§^~ªÃk&º°\«¤™>‘’{\éY’ìõ{³¸V:FUM!€#H¢O½ûkLdîµd¨r@±ú×}q„x¤ $4ÃN‰-!äĞÌ÷G|Á›¨bç‘Æ6U,ÀB¢‹Şı‘J÷ëè}úXšGPmgƒ©/PvbÙc¦ $ÿùœú¹ˆ&s®jæô?c.û^‚<Ë/>ŠC#Ác\¢_\Ÿcklg 9äÊ¦$°<fNcÔ7®{æC9úüÜîƒ‘<«tm”‘)x)“C0šö«*åbã >È¿ïÔ_‘!EŒ­?¹Ìh=?¼ãvÑd‘yâ×'’Ê™;riØè¸ Hæ +Aäè!2†å"o¢qÃÉV„DÂ÷YşXèqsp<m ¬¨ØNnÎ¾r¹ Òhº‚¡ßÉŸ S—ôÍÄ†¸~@iÙ®ÙR¥7Òr]™£¦&Ç‘ wôÂÔAÅh.ßÚ8 ï©êçü3kcØİ ô-GèÁ]^‡.w˜;Ñë¶\fGÃKšÅÂä|‚1¶n! cCÑ%£®¤8?Î	Á‡±&–sL7NCù^MŞÂÎ¨)_U¨:Úyµ·æïUû4n0çxT®
Ïg7úñß¢uŒAüµƒCÌ Û^İ½ä8"Û€Ø¦Ö£`¾{ZÅ1O8—@p˜ÔŞƒĞïFêSq±€'¯ññõú€×Ò‰¥}a9 ²Ò˜ér–[÷kûUô—ÙÎš%×YĞŞâÍD…<JŞ2NÊ¹*	ì¾£gŒô‹lıf¼¹ì+:¾^'d)VêââmÔ	å; ûYÖ;‘ÂDq<ªoy-.<´gf2µ˜| Èş½¨{¯Ö(‹£˜ç¼Š İpãnÅ6Jr’…â½	»P5â“EšcV0 F2r°2CsgSı¨8ğ'`4]1Úº³ÄB³ßİ[ä>í8²{DSgpr“óEø7ŞVQ\µ1CÆ$û’@¶•E5wPéMou;:Ö!×0);äÿŠ’ıÎxdİs4˜îÏf†øéÎ[Y ÿ«D7˜aT¾PÒsn¬{¹H7u,GÉ9¯¹Ù÷ù%7÷Û^œ¬;[¡8:ä¢Hı'oX…ŠŸ?bù¶;¹»&œ~j¾àX˜™˜FÖÂGè–£JÍÄú$"jh±jò¬pÎ-ımÊ†é‹“õ_œ)ï€(O0(™ù^ò«Û³'úª9–ş;bÒ¯tÎgĞ›½qÄÔ<W„ÿ@g?fÓjœ@xè^ÿƒ­ıã'ÚvÈ:4NÙ€kFR3Ğıúö=×ä
»,=#Æ
¨
†wş»|“ùöcÜrÈ¿z§ôÇV–Ûx#¼|ÛÁGm$óÁ€jQ(‹®Kl3¨´³)¯L³B&×A.-ÁR}K•Û™nÍ‡ÇÙ7åÈÛØ`ï õó#à£±±;¢U¹ÏË˜À>œ@$ë®%Â†Xn)o’Ã˜%9
ç¡]’Î“axxNqŠ±Ä«!çoå˜Ëb„ã]”ÑŒ¡ÛÀb ……³^k6¯cUM´yË´£,’Uãa2¦‰†ù/HÚş‡r »wÅÎ0ëOãô&·óukğ›Øk­°Jddùµ'ô#}‰!¿$UàÙîÿ Ğ`¹YA¡a6Šµµ?<­.ª>Í +pŒ¢+ñ4Ûsñ¶7°u2CÙíõıSD¡üj“Éß…ö¤¶q”"WCo.¹<dmŸ`şv%çŠı½üŞ4BıTJLŞr^ìˆpyı¶Ò5?ÉIû+ßÆğ¦LÕ6r)eÛ“%Õ­Cs^£‹rv”Ig6‚^ü<í8´Ìå›øz˜üè¸´3†œ• ŒIÛSğƒñ\³®/9¥­ÏØ/¶ı6n´û¨–8ˆ%*Vz¬i¶ NŒH|Ù–kñ/ÇuĞUÈØöM`|Îk³ñ«+Úcn£]¹†§vtn|èéVİÙâ™±;\]£Á+\Ä:¬ï€-n	~}pnµ X¶©n3ir ±±‘¬}ŸòZ%… ²æ,ÌBI	®*Ï„±Ø;+’W İÚ@ì2Ñ¸­)a´CÔ³ÆCAÜS±`O”î%u^®KˆĞ˜ÏıõW
UÄoàŒ<4CiZÒwÜSŒ£>Š3t˜–öàÈšôŠs$x®}®Ø«ı.ì\ÌµúíÆ9jŒ“çğ$€fFônëà¨kf›íÇ¥©??+ñÿ#±$Ë…R=âÌÌå¥û	‚kâ`êò;db­1”\ ¤^>„<fÊ´¾>¨×âjJxÄËc‚a8şˆ¯­@+}£áT/ñ¿š”>!f2hÚ¸(åìÖmûAUÍÔ¶ü(©Å5ûb·Ñ'à«iZÄ„õgûâğ
º7Óöï¤+Å{xùî:ßàü{nJİL(í·`…z|=ÙÃé rrÃ—}›}¢ØZo­îÚ0¸]©If÷lRÈAâ{iŞÅr;·`¤	ÀÏİsıiº÷5Ø»bDeÄ=[Øu‘i,O×0E^>º2‘D¢µ Í­«3s§(lŒY¬s+nàOêzÕû¢¤h½æËªO]0I¸aŸ¿îÁœˆ#ùã·!?´}ê9Téé’ñBÁP_baJ7,e…Z‚Ë:+®~S@\†›ş²İA ä£Ú9~4Ó2 F~	 ãe¼Ã}™eZ‰a„:^…]"/ş}SÓšêº?NCWùwP†îa·ùÖ0£´]×më@<;Ò¦I¬_Iñº…¡¥ÔÚ}W¥º•„*»¼(D		yõN6Ğ¿p¯­)io² ©|øVï•ã±|.åàó9ş ÕÀ‡ÿÎRÍÍ—=¯-Á‡ù»ıdBFİ1@¾8i;³¨«å®¨£ey. ¿H¹˜³ÅÓ7~Ö.hÍ)ùA™€Ëhµ;¬8hÃFŞå~ÖÁÅeäf‚ÉÔĞ»9Ö­½7õ´!Gÿb•t¦áE©§m	³âÃòĞ=`à¦Z¤c“A¹ÎÑLâÂè«áyü*ñqsëèùT¤J|Hí :È.W¦Ó–ÁëÓ_+ÂGfW£×õ?¸ò¨WõÁH;T8—½§bÚwk’(¬ŠQM=eTô±AUÁ³äò‚#PY(`¶çkˆ3ç7‰ı«÷‰uOÖJ§û<şšHŠa¶ä7EHúÙ|Í à©şµ}EŸ=bÉfO—hÏ—x„Á’ôcè°É àKüàqz;õ¢ü”À7ÃRlæ)#¡hhNfK3	ÓYĞLµR<n{¨¡øšZ!"‚²7ğÖ¤;›ü4zó–Zµ™¾†ôRÔ¸4(q@Ó¶Ë¾û\½›qÏûghî*fÏo/QÂ"]ë_ÊÈ"~†gÖÿXNƒÒÉ°İ›×Z9If÷ÔÃÊ¬ˆËÍBŸkmªŞ—}Šyòå>pEóAªe	Dk#hÑÃİT‹Bº·+jĞ¼‰nõqaÔ,QÀOHo²ãåÆØaÎêvÖÌU	Ès?Ká{Knê€]ÓhrL/ö·J7ÖŸ‹Œ{)iA©7 RÁwÓŞõMÀ9£³L	ÂÈ#÷ÑãéYññî‡a$ÁPZé
 ”â®µ#& ºææ–)Ğ›¶Ø¢Â„ˆ[é‰|}øÚ ±ÏS¥œ?ŸÌšà_–±e·tã®;¥é¨µ¾İ¿)+ôh“şQ_¨üŸÎñoóK`çÁ±7ÛtIÔh*–‹°_†³ê Pl…”d€@+„¦|ÕòRÚ½Ÿ]÷À6¦eÃ{Ô&D¹¥·ˆ{ƒ†$İ†* &Guîl¸u,½ÀçÖ>jÆ~vBô¿ÌeyuÊ‹ë¼e:`gTß„ÌÊ˜c7¡×‘} 	?ñ7F1jÔŠ7 ×ÿDIàŒ[ÛÄíÿ˜Œ>C¬â­$¾Y+Å±×½Ê	\éôÚ¼ßKƒ—CiìèµoØ0æ5¶3_{5†}z…Â)üÚ$É5{Ñ3I·û"?ÙÔûå6„˜+·²–¤İ´J“Œ±¬V*Ü{—Š$âæÊ2g®#~N#’¶†ªÖÙÊuŒ( ¡@ğÑV3hÌ…45’fU¼	v…ôPAË˜Ñ'‰¶6öígPH2ÿ%€Æ×5€L'fìàÍ–æ=N5S³²£gîîü–L>gn|,VÆUÊÄ9ÏxÅ1y­<¬©k‰Zª·hÒâ¨tŠ£^µõš–•>GÎ’,2®#å}„Taí¿è)ÚOî}@™dj3ïSÊš¡âù8>¨u± Š9ò:nÏF©(nPpìGê2±Ğ`=§ÊãO,7°®$y¼)¶~‘ŒpØRmıOYq€¼pG]â@|lûøÊ»o0…¾³LÒö·zØ#Æ®ŞÜC_²ÏĞ/#y_Fİ‘i Tâ¾tü¬O•jç[™¿·rYqUÈDUUöUÉ\›H[Íwó(LÖ…5àl†áK*»óúk_¸8›^àşÅ’~]vâàX›¨Õ‚o$g-±ZT»>ğÎÊi”c¿ú;<õLUõÜˆFßÌ¢`ÃS÷kü„ “ŞaÛïø<Äv‹03KÂBæ	ˆğsÜ˜.‘½@@ßÀ‘‘¯¼Å$@K³ÈiJ@áƒµlØÜMvi`ëZÅvO½„H/u0@ÂÊMçvêÿoš/@ÖöÄB¸CùfÕÌC¼Œj x	F¸ªãx–äVğ;0IwÆCàÈ¾Ş1ü&ªáoåGwYøKı•k*BHˆ»8Íq‰Èrá:9(ˆ»sìçSÔ?îX×€›ˆ5øá¶âZÆªA Ù]O¾“¸ÇğÏ‚ˆş4ZÿoD]PXÉr’$éi&«y1ç++;èèá„Á°ÕáêG˜›\­ÅB‚@¬ bùµ—åĞãóˆ#—Ëÿa‡×wg­`WğdrÈŠÃïwE¶rxˆ^†‚Ôiv3Ô5ú,xÁNú»â"ëùÉ€
 Â
‘·Šßœºê¯ Qjş«Uyµá=Ä¿¯l yZìs Œë¯|˜íÍßnß ,?$Grx/-ƒwÛıK‚İ/[¯ŸÓIóx´‡QˆY¢0XÿùA`$å–MÚGŒéöÓVìò”õInI­wgş£Ã%ÚŒèŸàšË½»l ”"%èp0è5\Ø'sx\À½õë	1¢ŠòÃĞòy‘¤k{©aÖş"²ë«åU“‡¼á»A­…TQ»÷6¯Ù`,­ø¢Ì4±oAcˆ\Ëaz3âMXNFc)–0‘¯maÔ	¡Ævwp½,®×K÷0üKUàÁÂ,ÃØÈìge(Œ’ÖMnEö›4g¢ÿòNò»8ìqÏIø¬ıEşsfO/¥„Èt#P4Ä[QgpqKº(rÁXáEëïF{21¶òbkÇ¦z  ¾v(}üÔ‹/rKGÍÉQ9¨£:OVZ[	Å#LrT.ŞïWÉAu“\±Sı ó‰¿eüÄ·,˜ :"2éI,M´ÂC¬¼’ùÊŠÊCŞ˜x·4qWÛ°ú<ËŞü¹É3b
=¯üûñ¦gºNÅÕ\ŠkÏM¾=Kõv©Úê ¹İ½whsMÔ@/îö‡ëÖ}ÄkF0Íèî¬?RšÚÓˆ”Ff˜oc†2…¼‹²	‹¿¸ëlS—20xîÏf—nï0p°59,­±!ï[¿çRVäÇ°Z‹œ7@¢Üiœì8N^õ³T°T3õt
ø˜}ÙoÊ÷ÄÚ^ì Æ¹<á¸ZÍŒ!Î${Sßz¿Ê xòƒ«ß4Í!ıÅ´§«Z™ä9ve‡J0/iT1ğ<IË2paíØÍ»Ÿ{i$|Ë !Òl[èöb´`}‡)ÃOÿË
³ÿ1’OêÕ™°¸ª¬d,:f‘Sé}}3(óHI×êÅ*¼Ã[ìl¶K×ˆ{SÑnxÈSĞã‰¬ô6”&@çÆ4ÊHãgÙÚ÷X¹’ì3®©tZX.Ò¤Xr<§7î¨À	ş0qş>²V*Ê|÷•‹..Ÿ(v÷ë¼Pß
<‹í)K]Èz§Á¾,Q.ÿ9öhx8.Sº¢cfxdáÜ–Ûæ}}s/ßqn›2¿7ğ9‘Ü2§›Sz|³/1Ëœ&UÑfKŠ¬¼‘ÁğrÜœµ”ìôJw×:û[ÇD±Z]}¥Š·Î*÷6båNN?JÌ¥†şš››3ëìªH›ó;šz{o7W¯-êuÛNÅæPÜñ¦•—Š5ö}UúÈ«QƒEÉş1‘İB¨™¥PêS¯FÉì1G—ê~ƒ8µ³ı-fJ12poÜüâ¥û§ÙyCv¡|èêx_Mcû7¦.Vç‡9@)Ñmã·¬THŒC4˜¹¤%İÆ	\é_œe‡{áğ“ô´¨i¬'m/2üş]ºoÂ–Oü}tµ|/••Vi!Ç~pÌ×Ï…†å´=‹•¦¬(ÂD‰¨ÃS
ù!Š™)Âı£^ëvxjçËÙÁò¡H‚6½…7J?;¢˜ë¨C*B®¤¨¤#Ö¥ÃUØ>?Æ¾)*¢€hŸ7Eü(dîãA°ÉŞHİ2Ì½´åïlTŸq×¹*ğç~+§y$w´ÚTÄyPlÅó¬¨y¦ÏJ‹ü§v¢„ãD/qÓV•ˆVïª5šØ9¢6dg¹"×mOR‘¸™ğoì´-»îQHzi3$WÔ(*Z1#®IïÔao3ş]-ŠCN×ğM¢Ùué«â[Ú2ºä 8É$ 5tsškÊ;JÅd|]Ô¤û³·3ß"ò#PÆ•û?aZËN9î€²Nÿ°Â?–èYAœôXT`Dƒó–Ñ;ú4%éèÙ¡L|@³”`+’b""]ÔìêÂ^>4ùàÜNX¢ãÛVÍeÀÇÛw# ¥å˜­İî?y¤ë8$$R“ãÚñ'IöòxËL>”|oÇÒ])‚10Kj£„z1±ƒ:)§W€í"ŸW‚Îÿaêï"÷ÉQP®i‹â–	åÒ2²¨ ƒIİµK¶qÊlò·VbñœFÔB€Í éÜÎÅcËEérÁÇpÎËø>g³à¿5ZÆ}œ6¦š†ÑÛ-"ˆ{$ç’ÒXî³‰:<SèÖïñ$pB€‚UşCUæğo`ètÏ!¶jX½» ÒÜ(H÷e¤Õax£AfËÄÀòŞÔæêz;;ço˜|÷Âu Q§ÙSRrxÙéZ³?ÑWrO=ô3ƒKæ“0Û&TÖİË…ş„—îÀ7ß§¨ã."gÃÕgş~Ûz½rºPìûø
NRK®”šåXí;îİOW÷¶DcÎƒ î³å´åËĞÀ:I'µT¢ÒÁrJ½¸ÿÆø.>5^u£U+TMå¯YjÑˆHË³ë£H†€•ÌœÑ…Rİ\S™š }¥È¬¿İÌáp”W<¨k:‹ëVĞÃúæM¼èäŞc’Ü˜]?Ÿ|šß v!"8( N´‰Ş\ìÍ~]Œƒ}â·öËÖNÙÏ¸&i’È2*ïÉ!A!çB£mÊPÃ(™_±bÊC,9P_2U4,ÍJ¶p_ıb7ğË9ÁNRÕÅ˜ƒƒ'°!#„}Ô/'ÓÏ??üœ•“rã¨ì^SH"ı«¤sUĞIú´ËŒè?
7£I%‰˜şÅ
`¨“4f¬—q†2A%„‡‹ö³+¡·s†Wö¸
(­ç]ìiÃåÔ=é‹¿¿ı4¿4?Ë*•ŠuN¡ ÕäŒ¤8ñ€ÄÉ4J¨âõ-ƒØ7çœ	œZ‚zÀÅÙ<:$¡ˆ6£›Æ¾e´!ĞŒ4ãHyS*z0pë;ÏL‡ú¯?çpœ>¼hŠ¾¯UrÙÜ]¨ [şmœ9[¶üŸ¤ë5İtÊÇŒ3ò\bĞjmmbıA_`Që‚tœŞİ?DUÑC$O}' X·Ú ‘üé€[Õ¦·Å[¸#zÛŒ/™A,¤lÌ=u—qôæ¹Éâçtˆ`K¶+/ôZîhéÁãybKÑ*êQö½óÆ¤UºL{¥ ö¬‹x¤c6-K&ö§L€7_kß
‡¿Ãnü\¨<W ¨WÌşù°µä´—áÓšOS¸C™†×0Tk¡C¿K-bl;Ë”9*„9"8=5ydÏÈRØwŠ‡³Xƒ¾‘™Q‹µF|m4ï\gÂCõÀGôøTøûpÀ¡Ø0i«QL³ğ"™T‘à’„€^FÉå_ïYÜ3‰±6Ø6»OI^)KÓ§~Õ]bJ”~gÂx%.óî«Ò«©<¡N"¦$ï	ƒÅGPªÄ¦˜P,İ(\mÇ3]TÁœT€£\NnßLDì}!~tá?ò¾	ÍE¯"df”ì·ÅÈWù_2¤şq³¶kˆÉqŞü³ó2TtĞó3.)ƒÑègIŞOiã:&_ëÀJÓu*P$›Èht±@­¹ó×¼LI0Ã	€Ÿ}2¼òŸKÑ;_nYî¬¼û‡Qe¬ÜjNSjgãz´…p h>1 Œ5(	ÃÂ5ˆàãT½…rc½µ|ùJm +’ÁåÊ”şvõ¨×2§õ‚;^â¬ÓÅ\ÚëœëiÜR{–“|7Èóódäš²Ã•VÈIû¶‡âÛÜ!)éNü<<UÑËÂmO°"òÂ$I½ÃL¾Á²jkÖzGÇHiä8såhfË;O#q`ú¦¬õ+Óÿ¬‚¦¶’9 ‰IãG·®ífÔ„u‚sÇ|ÿbŠ®ÖqÕÌŸ{¸æ+eŸdUÌÜ{&ÃLÔ±¦Øƒ/—õ¶îr×±ŠìhÁI¤²#Hçmgåq9™Ú †â“Çr>§ÿİM ›Éø>\œŒ)¤†Ólao¡c4†'*0-LÍØ¸ĞGû¡Õ;Ï§˜›°HGZ8Öîğ(÷3–°r{ ø‰ÌÚ"Èúg5´DW&8“Ş£aR’÷mP%ÃJWûƒÆÍl×üù„EéÜ±À¥ã‹Ëùòÿÿ23ãı„ç	DÍI®TJ]:ùc>7‰>Ğ&­Òf"í¤ÑC'Ëğ7şÁÚœ¦uÈÓOÿ_«uòp6ª*FàÉšrpúŸo9YNÍ¿Ã˜åQX#E	i=ª‰'¼û‡àÙŸ'>ÀÍo6Özåûİ}|/<ï§É‘g6L!Eı1ì° Ø4L3¬Ówcİêj–ÓÊ\R“1†äp°SƒãN××‹"Dá½ OS=ÏHÖ+Œ½³7Cˆüd<<2´ñ0øZä¶îQÉªş_’<ò32ù%Ä®p¡
 OŠafÔS¢üK"[‚DGØT@Œ˜_»(#çÊË=}æ
öHŒ|V×Ï›JnÑZÇ;-”i;XĞ¶c€ª›Qƒ™´·I-î#teù½qM§_&å[ µ}ğÿnÕ¥QœÑf9Z<Ì'æ‚õ z,Ã8|D¿Lš"+8~SkÉ.:Ï[!]&57~À¶¹*|Ä‰BÚJ‚õ¢“×ŞÊu«+zâ¸SËÜ…Ü³0ëĞ?šÃ¨p˜%l!ªm ­Ë¿«‚Mğ¥Î1S{ï“WÕİÀºß5x1ÔÔ^QfÀTÚñB=N)KO‘H….óÈ¡EÄSšJÌ³Ä‘:è(3Öq¬ÊæDà6öº8…Lğî2ÙÔÿ¡¡Îó]‰Èg•â´{ı«¡NN'°e”_â½á¯l£¢ã	‹¾ÀQÛñX_ºJÿª€qm`ªI¿ï§¹eäTáoı»·Ä¦Tˆ¬bî $¢nölk«MÆeØ¸Z,2 å5)ˆòPÛV¨­ŸÙq#†æ®:d‚‚Ÿ!5€£zBâğAş
ò„NõşGG©‘ÇÇÏnî9Mà*q:ÏÿÉ)e£¼†KŠÃÍM?DÉŠ©<y(®I¼²ì¤Y[Bfá
ÉsˆiĞÂ"qöŸˆˆÆU¬‰ßÓRèr¶·­U¹Ş®:ëÖ,ÓÁ #ı7’^­Ø«F¢pÇ²ù`E;Üã[˜^ğüê@I7Bañ¡¶Ù‘ÂüÑ"Z‚ÛáQÀáZ;f&Ì•ÀZÊäú¾Êˆ”ßA¸ı³2)Ëúyòÿ@à	ŠA(ù$*Ğô¸ÿ$/ïQêÌY¡$w¾‰M÷Q^È÷¶%0¹ßçx¦ıÖ‰Tê£¿,÷î5
¥\!ú»µÙÑ¦½yïİföØÃ1{Î hÀÅ1ÍùÆô¼”?V`Jn°B†"´,!Ào½ıœj1«ä©É³åûä)£–dët§	,±cÀ‹ øJ‚œ{[-"œšH[¯†§Ê÷ÍHˆEéEM Cé/òÄhrª‰K#Tu¾rÿ+2\U Ÿ6qËÙ2‘Öj‰á©İ9(ôTÀ²À2«\Å-)^RhÈI
Nô‡¥b¤ƒ
PN­ò‹İ5‘uÒaøºFßş5cF­ŠÆpöØªs:Í é¼íÛ¹#r)¿ÈèÈ·»M³Éb‡!¬¾GıÛ:ED<:¨Ëôö0L áWğ	00[¢ıP¥LÑñ­|×øˆeM_,H«;_SÉ¡Ë>tÓBgw³~	K*kITO¼+ÙŞ{¶H¯ÍÅ½)-s «Çı[íoò_9§8¸½Pª é£2ùšè’¬óîm=^¦=#uvÇ ¿5m÷İ*à™Ég¡Ç¾n$
j©ş?ÔÎÉ2‡tGv>;=òx~ÂÕ¾6B^Öİw4_ŸŸê…;ßˆ5ÃğôIWƒE*áâŠß®Ôa´‚x×F¬ˆ‹ñÃbX~hê$û©ö9C¸wÂi%kT6ÈÚ¤Óˆ˜Ä ø.é„BéŸ"¶ $—ö•óš­0G$ÊB“»gI<9İD÷~ÅùÊ˜ÏÁœ5
kÙ'Áã(Ç}ØcÒsC ÓÕy„}¥L32M@ä(˜0º­Ì#Ğ)®‹£+ ©â´{Œ¨Éj˜pÃPT0ıaÿ³¿cšÜ«Ú;Ÿâe^#QNG	¥f¶aĞ™¦H7†zGá"2<âÀ’î´2ÀÓÿÍ\ÿêˆÅïÔ.µè(e«'s•>“îf:TeˆM¥&õ78zõ¯Ør¼àr‡S†[FÙèÚŸØ(u[¡w.pØj £è5¶=L¦²r$kè‚{s€e›m°¼NojKmÿ)6öçÁÌ=’Şíä”åæXò—Bœ0êºÍ†Æ©½N9Sï=?ğd¥«˜‘SàÌ¯‘*B6ó%I1Ğ|<Ö‹uféú3:“¾×#ÿ](Qc*XÍå:f4¶-œ3ÓÈúÃB«:Ç)k6h¹qÚt…&?¾=Nš†øqj<@†1îVğNñgàˆZ±/!€ğ¼pxÀşpµå\¼)ˆ„š3Gñ:>X
AÈøAG¥-·Ä—ÙF´e?U#ƒ88cûšáÙİÔ-·,qkiÈ+¿vHöÍ$J½g'ÍgX¾¬r°$4ê_”–âŠù|1½jÒ¹åq{ô¶ĞlŞ·„Çÿàïæ(ÌÁv;‘#y’¹ıVñ¶²XT…ó/‹¢??l¸³Ù¿æ»´}Agø3~MÑ^Å‚Ã §á¬Ê!ZgXša£Ã§äğ+)^ºx„HºeD3tá‹[Nˆ˜ÿIÅøs²ï±nìc~7,¦ÄiöÁ\û}Zæ÷6ŞÖ:}Éûñ Ê8g™••®N¤™QX¡8?³Ó
ìc.¤EzjF‰ò@£¸ìmÅÄüÃ£í² oæ/õ¾bûu1¾ÿĞÆé0Á¡ë…@E’ç¤ï6ÓpîÇJTÒ0É`"
´	ŞŸ¹ÃGÍ?x£ãëãŠ :…P°©‘Îcõ¯ÚE€J Ì
%ë‹É(‡Ì½ÉdÓŒ}]®Öäß«˜)m·Àèl¹s†Ö9fé%._Üõ¼ìí´ë\IEN?<§›˜«¬j{ÄKWç°½|ÜX2è¥uê[}(^öé?Ç„fÖÏóÄ~{¥<9Gµc“éµñ´Éy+±d"›ğ¹ø¶ñÖÔÖ[Ğï®vàË§5;ïŞMW#S~~M-¯_¥õŒ$ñ½Ò}³[G[Äã[x×?z?:\#?sÓÄR‡V¿àˆRa¶ÓûÙoÒe3§†Í„aàz²U!ø,FŸ`3˜{B¹Í3³=ñm‹áZı­èŞP¯éòlóíÚ¸!JaÊ„{i©ºê{Ò$·IÚÑü€WSÕÅÎ6€Ïù|®R5ğîVÉ(ü
¼Ö- »¹ë3eÿ{Ë¥Há(ÛÁ=Ï"€¡¢Àc•=R­šàÙ¤Âó§Ô±“î¹‰ìŒQKñ8õ3W€¢°àÑº½Oìè¶–WUØ;
hJÏøOb>%Zk£L»¼¼Õ…L,á€©ŒìTá#€µ}\cz¿ş0ßRÊ¢åb<œ`[úZĞö™ètb5lÆò³“#D›……:E‚æqhœ.KáÒ"4^2şHÍºÜwãpœ{ÄÌóƒ ¼¿ÿ¾İÊ¼º;CŸ×ÄN¾pÂ›çg9`_THÌ4fl¬ÒŒıó–³K œ~îMàkz‡µ²uyÄù3€ŞjŸ»­ mdÖ¹rKíiğ“¶ÜˆÓğ,_ˆÕ¼jø±ãúzá¯,ÎâYƒ:£Ø(k9P.Î!cŠ(¬gj±¬ĞU™À-®Wú1¦d+Ü/Ãeóô½Eæ.AMñdİºHp›o]E2…‡«šJÎ–ÃL¥”œIO>BšXe®Ñ°ÁşM¼Ó·”ù`.ÊîµŠ
zÇ4Xé6€Š«Šzü3¥ÍóC:„»7§âæYÁ”N£·ú‡ëè­}ŸÃ©¢C?ï¹CúœÿuJÊ @èØÖå†ê|¡…ÈØ6=€’¾uÂš©óµÄĞÔâ=ßbJ²©ì1®ÌÜ)0SÔN"ÆÂ±^yl%¾€ fàÚâRxŸYo9¦ÄÁAy€Í «Ôà„}Ô‡¶yÄ!(L™"™ë  Îñ]ÿàdvñğ¿änæ…– ->¢ŞÜQCÚlªë5Ğö‘æÃs" #1ÙÍ>!KÚ7©m!8£4bÆ.Ã¼f»³¨}uCcèfÖ&„-VrKïoWLÅüiĞOX¾~g òñûuÕµ‡“&øFRÉ¨„2ùT¯\ÓwdêÍP²¸º»)h(yt«	vVJöÊ</±ÉİKƒ/¯–·SE¬ğ ,B¶ıx­n‹ÏjÎ’7¸}!4'½Z·Ks¾ºÍûenÁßº/U2ôs‡>$UU¾Óé†¤	æĞ²Ä£ßà/"¬ÈûA[<|2Å=„‡ÃíWØÎ\Xq¿)û²®1ÿïi³#„guAî:×WPŠüÍ@ Ò‘lpŠ#ÂÜUß»^}¶`¶¿_5¯ ±¢gû 1u D& è‰ØŞÇûw0Ëa2‹!r$Ù	ë 1ƒ|ğøë¦!0ŠŸnur*Z°ëÀÂæ@;;×êôãX}… åZ$Ù·Ùs7ïx½Ğ±GıuÂ)¬kY»×Æ‘ D¬ŒÊCØlç´0wI!äÚ;B ŠUb0’ÌÓ&À’Yë×\äQ*:YS)"%•=w¦€ëá“ldåñ*³~6~J“Â@­Š
íÍ<BÂ¸{ĞciM
xé'Çdw563áÜ ,œ9%9¡Ìğâ1‚3ç¥]~AG¦Ïgçµ“ìåK»§yÕ>±zY1´Ş PFÁ}Ïœ×æTŠÉFD€ ı›6î¬‰OZ	‡<ƒÉÔM˜î_Ñö¡'ì“ƒâm†Ha”í]æâ.ş±W®Ú6<Ú8¤²“/
àå#®•æLŞÿO<ÔvNa‰=ùLÇiPÃ(û±sÎ»Ïşí£:‘^½•
84ş{tµƒv< ¿‰°ÎNVàyYL•
qpRnŒ–­¾éŞ§_ÙOp›^ÑÿâWIÆZ.’@ÓÜ±×VN'6ÍG¥´Za†BlÉiƒ™Â¼¤şô"Û6ıÁáX‹lğ8‡²Q‰ª:—œş	ìŒ$ğú¼¶píxµß#ipÖKöWGµºln9XBVøXÉRÉİ½)ğM$X±¢şÁ1´~#Ü‹ö×A:{1+o¨z8mŸn«t8’^>gãd‚¶¤!&ï[Jº°¹´ã,<±ûõXú”&š³Wº0{a‘¡¯ ”@ÇyCw‡Ö¨lSÜ”üÁè‡8°•ÅmE¢}Ù¿±›¥	Î¨5O·8g`Z<âêŞ¬à£l.»:§w6e/~”;qVi×Ÿ¯¤ì&“|$€P=6Éúî8"$ô.(•)--·Ï…æe&	ÉOX&¨¿‰8yÖ8Jàî)›ÉÿåtzÓ¨ß£–Êé°xTOuW/JG²Û·5]„ j3ÑÉåîÍùKûàÔô<ôŞ<½BÓÖk÷j‡	~l³;²øÙ-:Pálï,Úp“‡8)è­o¡rKŒ±^(R+Ú£~PaıÕp Ç÷ªÍL¸ŞşÖ\}w™œ3	÷[æÿEşa.	q»Ğ©Œ¹+YZd£ü*%Ğ"8Ã‰ŒC!`şxÄDÅæ„ãÈèÜ5m•úxÛ˜wNq3®ÈjFH‹İÆ{”Ù4IÌ{i]?†ìÂ'­ù€‰Ïf‚“$úÛá.%jfn =yK)k÷„(RDpòuò“g2YzV]¯]±Ó{ßŞgLÑdÏ’ù¡Äv‚¡ËÆÕuûw» ©HX¤…Ë±„+6¼C|û/@,'	»2è©º	"fXÁ[ÿäf=?:9Œ˜¶q®Lp>âÇ1­÷q|íH © L	ò‘}ŒXbÜG‡˜½¥¤—ĞAÒşƒxùãkÀ‰,Ğ’$æˆ)Û¦’zWÓ/ÄİÕÖğ?øq'
º¥Ï›2»ÅÍ’ãZåÍ‰‰XÁ…àfN¥İˆü§b>“íµÙ`ğtÑ`HEj™I`ušÔzoR¼cÜ-­Ò#{	µS_`•· Q4ë‡¡±Æ)İ#zu±•,_’-*AI¦§ÒHş±ø9ş¦³oÄ¸D/ç]‘®`Wà¥ÌDF¸k…UgÂgşêNMQ¢²”ÚörDÌÙË¡!òÇnºˆìvF¶›Ğ-¾×‡o.Ôv¿m._ÕH0Â”CråDÅáKáÑcÍkİºAÜWãc{#<gŸ‘Oyæê/PÉ•~*6Ù°ÓfŒ5ñÓ„Kå2P]v	61p¯`úVª‹Fœ_L‡¯äe¤·x³-r!óo6¤Ÿ@’Œ­¸3a=ÓG'zç2NDtps’øZNnÛ.–ï-åc¥\÷­F,ï“,CŞÆíÀ®½Â5úO}NÃC~kÚ•aĞ‘AÖ–~wy¥#™ÙuáõxuAÀ®ÿìÎ3Tsf/xÊPI5W=²Â¸8£9f»¤ÿgk:[P^-&øµÛ²­ø[8l:•a.(!V?S½ş©`w&eLºüÆZÒäe¸Ër>a±~­Ş=c¤°#Ë48»kÛøœ*U¼å]Jû)-‚ù¿'U_f´é¾M©Q€Æ©ñªØ”•]£Ø»y K$_+g­ß0Æ/@ævY·c4QÈYØv˜Bı½ RşYÒ$ÛÕ wÎAË¨Ô¯ák#wtš7(°Ç9‹èg!İnëô-ºv‘£SŠİ¸%«ÜE‡(v›ñí÷aÚºO€¡¡`µ$ kS»ş=•s{;Röƒ_y€Ã8£ddìé=ô%—nhtü/–w	r¬´â‚öbX,YKXù‰gÒEøSìİï%óG€q3YDòYŸÀ­p¬¨Ä§è=ë­Ø´Dr{"t–˜ÿi?ƒ¨ı!3¢^ÿ0^èFN¿÷cÒ’(,l<]gŸ¯tŸLóØâ‡¥–g“ŸÏ*mßIå&Ù|;‡AïU Œ|!”ªçéİ–8x;«J«º t1/Åm Ş)ß%GËsì›İÅËAù …Š$2|Á
?“:Ò—K+ˆ¤˜´´ØÑ–ãMPú'm¦(« Â*øöÈifÂ‹ƒ]ªnÁZî/s¨hZ®J®SÔ¸`Ìî÷[7*bÜªlxÚlİûkŒyêŸr¨ºù ç^Qı8VóãH¾PFGoôV9=İËşæ—Í+C!á^$½Aã58Y)©«•:Ë²ŸµFSÄËĞ†A'ìì§xÛè:#=_‰Ÿ¢ç™—øşzŞïiÜ³L%E¥8½E®¶ˆ#š¶©$“âW5@J˜(u> á
òH{T+dOÑ´İ÷ xÜİ…Zmğ÷İ¿Å—3Ó5€?%ÿÿù=ô.% Ç®^uÛ;!âoİ.(?è`İrÒ¬Ü0ÿ¾”kzFA’~Vÿ;h‡³$]<Í—Ìa{Dªşb»ñ‡Tÿƒït¿“)ÿD€¡#şnz¹œ8Ÿ$I°mñmVúÃĞ'Ø@:×tA×O+µô¦R®•Ü†«	TãÒ§h(Ç·ıìWm¿ê¤yÁWiì†³VWÙÚ2¢Æ“huvÕ“À~ÙA9£¶|zŠhˆ'«~âD×»ñ!W!4-×vvûR°ØÁ2r^S‚7¬óPO¸ÏÛ5ƒµëó›R¼!¹ÀõOÉÎ“{:Ë> š/à¸@RÍX­†|>RÙÍ«hÎ$¥åÆ÷¼âá,SF*6OÜëì(º—İÛ øV¤*WwZàV¸$'Œg³ ¯xœĞ`v.jNyºS5
äyªˆSéãÊiÄœ@M‡ÙÁ[Îß]&ÅpNfMœìjË4áTLD|ßñ¡«´‹­¶‹„-ş|½e^WÊX9HĞmöùà@\ë‚YUQX¥›Ô²”}š0 ÎT/=luìä¾”#ˆ)y ¦ ¾ÂûëÒæ]*‡ä)iéÆ2á´ö$øff½ã!
ì~8Ü*_fÌcáåètW`Êº{iºs¿FrMÉ©~®¬ ¬:-»øu•82y™ç~¾kù¡}™b'Ûşcéö¡EÓÏ±TïM|¢ySröÿq[EY¾ƒ­Ft}	_Û…@öğ™Ô)*gpU$¹°GtËX>6)ƒWE'Çßb"ü…¹Z:<®¨9e”VS~Å$<ÁÉ7ZŸhvÆ¶<n¢Ê~ —’„:°5s¶:keÈ—3ÁC"Ó³şP‘ÂşxlÎZ§®8sÂY`)EòvÖQß9ŠÌÔĞ|æÖd»Qã-2€È»Ñ1ÅßÜâïpJúªUÀşZ÷ÍÔ õOQ=ÑzzÚ{±Bqbo…-ºiÀ§ÛöNóááıÓ®iÖä*¬“*ğğ[ìáÆÔ'o¯@Y¤¢:¥á*Ö&}tŠ¦Ù¤Sjˆï&ÜòÚ]ß
 &ÏS»F® m& ü èWKÑõdÍ‹ñ™Aû!ÊRw‚6¤ÿ‘€S¹¶Ü—¨BP´zA³w3Œ®UúU\~˜àHŞ”ÔEïäÁØSˆ}©ÃZIñ·„ÿ@x®|s‚ôYuªAUÉa™näÖ‰ÓPü¸¿!Ë®çŞ^>ï{tßÕë]à…ç%$³~Ù_bÀ*´£F¹	){ƒúT¯¥†Y„_ùxã,õI¼Áj1i)‘˜xHÖ»jªÛWèJ´ £ûé?Ï4ö—êÿÏŠ‡#IlZN³:è‚ÄÃOèñä¼öø³S™¶Aå´Ô áFœÅr_j\±tV|ÑAÑ4€‚N®<Ed[ái/ÛDK
>z[Ó§8|c¦0Ïvh «/YNCSòŒ¿Rˆã}‘ÀğjDqTn~ÃäCúâåùK¾·ôPNÕG®©×ldúWK‰“ŸÀO‡L8ëA¸|0†ã6èE‚at&pŒò#­^‰Jıè;GÙB@È-vR;±u=n€§Wçˆ€8½}ÑİªÍÌ?eéµ]ĞV“øl“
q‡ª® x·Íö$»YBx³4±¶LQİã–ŞõÑæÀ“PÉıEâ{0MIÚ _ıCEë¤n4¯9%8¬cB¤8#J—éè¸¥\ø×` ±!CÏk.Ğ÷›póÌrİíÑr€Ó“üo“ÊK¥½Ój‘°÷¼¯¼ğM§¨Í˜ÛèJ“UNîˆ2À5:d1N‘“ØMÃYÏQü0µó²óDû#ÎÓˆ?ş^£n}`¯L¦ş]X)Z…í-¨İZ4ÃÛû©Å@ºëœÌê¤)ğSG×¬Öâ$P¡lŞ|ñâ3Ê¸Ÿ{µõ´Öí__·µ¨Nœts¯­KürY7 IÅ‚§$vAk„C§¯±~Ğó«
ØV<µSƒÇëÊÔ>7}YDøm÷NğPŞŒÖ…E˜7^I?Aİ‡öĞöˆñÜ-H
ã´X»#ŸÎÑ´@ºçû1>‹ç-¤!¹´Ä"»XFfÎÁ¥ü›‹‘ôf,f©n>:ë,¼eÙU‘×ÃÊëß%Wí„£˜Dïå6ZèO¹@ÇØæh6I¡Ya­^Ã;Ñ*1ê÷æß.ÁÇ AªÙö°ŸøÂœãû¬rZ}{öI‚J£¤©´ÈŞé(Ô‹€GV­p>èøecÁ§Ào4æ,ÃÃ"#Ä«Â_³‡jkê›©5*ä[sõµÄ ˜NBW&NÊê3ÚKÅ¶ŞeK®q?n ºœä—¥ÛtçWp7-m98ÀÇLŒ_ZQ!x¬hd¢«ÚdoÊºcuß×äI}ğğg“0šW‘LÜöÚZÛnST•vWjÒsqw!t8K P¬C-ÿ›Á®=’eA])“Ş²Ù¯j©†õÖ¨E`±dg­øÎÂÎóoıçEî‡íÄ®Ø›T>SkVKF¬¹”¸Pk•#º0P1ßb˜¼Hœµ¶î¾aJ˜Äìzág$}ÆHî‰Ô·yCå¶ST¼‘es67O|¦¹’^j7—áPÚ7Éó÷'«G-0Pæ'‘S0b“äWŒJ[ö‚SéZİâqwÎPŒŸª*õ!—‚Z˜TpÌ%Ib<^"Ed§äY^ÏÚæh´Q¦;§*ü÷ádh/)‘2…‘¼Û«¸?¯œ¾«Uöœ
oèí‘4á ]+çujÆ¦ß¾f¡S™¨u=²1jäùZt…=(Âçëe¥uOsÃï~œNÙNPÌÛO³+õg};Í‚ò´™c=§Ëû<è‹ó0—"µ´rd.1uéÍGìÚİC‹„ëËr"<¹^¨F÷¤ò–MVQ\’d=c!÷à¿¶L($_Èá<Ñ3«¢²µL%ü]ÜKY²C¦t`/q£Së
ÉkŸ'Á$€ŸãºWêEÖ:zÅgà?A®lË¼T‹·KsÔ3J,äú©-wÄ‰9ä¢Q*NĞktE¬B˜.q<s­±ÒğÛr€NÔ"AíïíHfÂı;†)™ËüWæfZ*\ˆlx<¸§]X@Ù1ÒÓ¦ŸïĞJ¦ÆÜÓ¸dL´í@_¨*vKcû A‘óœÃ#ãu\†®úSg_ı	¢|­.@ ¨˜p†%x1h!Jãêxàˆ7;´\ğÿÜúÖÆ…Ş£¼µèL˜r!}ßkkè2öÓ’ÚQ-;Ş¼G®Æ‘‰ÎàÌ´lh3›íA`	ñwXZGğ°{6óÂNîİ¢=Ü¦[öÂ¤.pD™;ÿzêøÏFõ—Ã;xxşÆGuÅÆ÷'t¯ßŸPl˜+8oâ6²øĞ5~µ¸ñÒ’ ‹Ï\=5d)ö¬é´•	tz8ßĞÁ¸Ö³íì{×™µMZğŞlz[î ÚJ ğĞíò!)N”€&ŠdsnêÊæÅÚ3¡j”J‘\¸±%}X“[ØQö@8_–€şÉ•¶qÂxÅ´Ùù
:ğ²P`PÅ+İƒ1ÂÆ°ñI¥ªôŸŞ_,ÑvI?¢MDÚÈKåyhÓõèÅ¦‚ÄuuŒïşÍ‘.EeR@ÙÍ¡6ğÛ\^©rõâæ9ä×ÄÆÎ-HW_§]>cO‘
şØ'S¨0f«T§ù‚³ÃƒHeH‡u±ºzÌİ–sëà¥eiAY/:ıVE«²K®$Å‰™ß«¨-«È§WÄÖ2¤·C2ş+Ş¨Œ] ÃÆí[¼Mïçö<wMpVj½áêÅ‘Œ{»Š71ô´Ò¼±ºsDdÜIMŠÉ‚bçÚãú¹ıtìaÅØ(Š]1¢€§êïÀüèğw7?†êìÌÔ…»\¹³àæÉ)ò—9»d.00iº1Š´Ğµ‹ˆ›$V­¤•Ù¬ã]ú?köî|±ëˆ/"Tl˜I©æÊƒ-éÉì¦')ÀÎ!Ÿ¿É¬şÖ/­‘Ø%Í‚¾2=}ú½X˜˜'&u[xV’äÿ^3±K²ôÒ¨K]7(‘PÁØ.ÈÈÀù&hM	9zY–7¶İ<`ŸË€9’š;ïĞ{Ô×O)ádXLœÕ1=-‰i\"½u$Âá'¹âìÏŸÊÎWr$k—™â³=ÉXÖ„æx€_š‰B|©hâ™Fgf¸°
X0Í)|®*kU„ˆ…¬‹‘v]„ÁABç$®o?O{x-;ÿWº–c3¼y¥ü03VaÃ9]#‹Ëa›œô:;ƒ!ıLİº^1rĞSgÊ)‰u³~çÇ–TÚ{ÔxrìÚx}pÖˆ4m™Îı—í¥•hÈ_U^}>J+‰_
6ªî™³ŠwÚÎóöı¾¿áÁ³ üÛ:>eÍr#À×dtäfo§Àş >VgNâPjRÙNÆ·=Í²ßÚ‘J´˜ë³¥°ª) B…[äPœ™ûjSôÀÿ$€`~Ø­Ş˜·ğê_•kUd8¾ÆFó&:¨Ú¸P'ÜP¬Öh²­’êT?ì’ ¤¼aøÊFVÉU‚ÃŒşË¹iÖ³°¤«š´ÚKŸıÔr*sƒ][Æ˜ŸTX¯6®ÔîUÛu‰’Œ•'1P’WÊI3hJHĞ]j¶øŠ³š:ƒ–©ÒIi‡K@›µ ;Ñ±^jÖÆ	Vİ&¦¹«²ƒîX/÷;‡WÛD¦Élcœòé#«ƒt·Ûš•›ï¥ĞtUn‡‚ŠğC‡Äè·ïgøWôÏU¸™5—c’A
pæ8J²ù­BÇQ³zÉ§ûd²„÷9_ä)"mş+|GÇz$}†œ>¬bû]3ñnåÖĞÒGí²Ûô3aä€fœOë;ÃÇ¥ŒrÇ¿Kö]À¿J²À±‚«ø,f.—Â
0`½ ‚8†}`ÅÚfY£~Îp‘mZÑFór@hğ#&ÉD­HP…jœÔC¶Q4bg@ˆè¾iz!Lc
|@Gé„°øiƒª©íòUÎ	ÆRóãd£’Û£×ÌtbÖ_Ş¥_2Íò[ğ„ïÿÓjzıZôœ'ì›9äLXWß«{›/ÈÅÈÛ[ßÈö¡·nÈæú‹íö5=n6àähiOXF¸ö…£h0º´¹ÛMıñÄNNÍäf‹Ãş_M¤¾¾Å3Ê‡f4CJüm÷¥åJd…’C9ÊÍ‘´DHÓé³K_¯‡xB~+è£<¼{É¶Î«Àì ^ğ7ÜîÊ‰Ãì4»R}˜yc¶¡F@$¤®z6ÇÓ0ÄhU8²1¹X²s•PŒmÙ"™£ç}ÃRÀğµõy³~Ñ£,„\E«`ımxlËc´(Ã™1K{Yq—7;=ûj1ÑÂD#Ó˜¶Ïœ(m$‹Èí³“Ï‹‚ŠPÇìì€ÂÊ
Ñ³ÉRçó0óÓG €¯¾d.>at.×Ö˜ª&Lİ+É¾mY‹j}…—meö¸›!“r%ù. «ÊŠ¯ĞPZ+Vf¯åøUî÷ÎuÔé£êØ.g•.ö‡“9õø}˜MĞ^4 °?’Yu0A tgTÑÀ‹ÈJ¨W¯à_4˜N©?m»BN?¤ˆOÜ²¯:j#«âg×ç;ªaåÍÆ±:³½Æİù?È¯ÿQéÊ¢Ÿ‚p´¦<'Q(iv¬)"óOÍ\¤{Ğš9&¼ ñD´Æ>h;»œÏZ»ßxcChWëß‘†‡VãÙ»‹-æ–ş–Ö.EÍ÷{‡¬|ğeùƒq¿¥Ñ2Õ TĞS¿ğ
áv
ğîúò&?ò`µšœY¼ÂíÎX`èB¶Ğ@2)­å—ò: Ù…ì…Ğ™ä~ îú_}fLÇ÷@[âE^Œg˜…g?¨?;ŠŞõŞgq½7ÙÍÑ#Œ
lG ğw<Á†n<œê•£¾ĞxL~ØlY6WBi£A¼‡óğĞFíÒ^4BNÊMßreúxMÎÀ‚Ş5Úï„rû[41]t[~~@2m#zô”ÑöóJh\ŠŸ3~K¢úû-½tzüa@ÿ6ô*ôyèÈˆ_İĞÊD_ÿÂøRÆPd‚ ¥À2U´)\“†tªæCÄwUü=øä¸ÍißŸ@g\ÈcÁ­¦WG&‚Fy_•ëÔ¹Õ,r¸Ïƒ@¹¶ğ/÷¯ß²àÔƒ{¿8Õ]ä‚ÛŠ ŒÀ?ùï¬‹ƒ`x¥Îì¿˜-Ö¸Ìˆãê6õwà©Ö°cg’MD	í™zò™ê¨Ïz[PoCùg#Wå¿¹<–#ÄÕ‰#ÄµºÆ6±O\€µ•»ÅıÆO`_”¼7éÏ0ƒUq ò†è}}İ¡€*Šµë(^9!ª}‘N¦»zÅ¥sÂˆ'çl‚ìT¾¬)ÀÀÎÏ7¤(Ç¨ÇXõmÁ¯Fä"o*D¹Í:a “ -äØÂÕaU®ôÃ”‡”W2£kîs-u'’W~‹ç@—m¦€i^m
N¬»&ÔïªçŒÖ]š4"y$0büë¼)WŠÕ?×}ÀUŞØ½[ç1ÆPE&zşĞŒi6+Õ;U'/p%ÜC]}·?:Ãn‹•`¬:Ôaf•TëĞ/Iµ~ŸŸc-e&¾x"IŸpBÊuVyı|Û"+¤pS“~{EŸjw©õtmÁŠ…‡?=ÖèhJ‹Ÿæy¹b²æ´	§ú6°\Ğ[cNÆØÔU1¤ÄØõïÊÀû:½ª^A	BEœÏe<×!öñ„iÖâL4—‚ô‹½ôøh£¾æÛlç.Ğ³ƒºº³A_¶_ğô`=b,œâfa¯a¥µ¸Î³íÜ4^Uùú™ĞAL«ãuCFÌÜÿŸë—±¢>DÕP›Öïé–ed‚;SªO3l‚	æOûº³¬û@JØ'cq#µe=ß=Õç@oÜpÓJàFyğŸ‘Cğ¼Æ‡ÔÒúó§£ê¾®CqÂ”§¶)áïÏ‘æ¯Ï:µ¦'ÁP`¿Ç¨èã÷Á:c®Àè<Å÷‹7æï_]hŸ]#ß}u5EÍ9Oó31ã«•z(/ Û #X(öCJî=-¬ÔH³ê+ñ‹%¥Y$aãU{©Ê€ÅÉ°_Š¯Ÿî9ã”£ûGğ‚ËĞõ$€*U’f×ª0mb3cëİB„?Ä±ObÀÆjÇäfÔAÄ§ÖZˆt1×¥ú@Dı‡u$ğƒóõÆò¡¶¯êal™5ÑËPÙ±˜Ÿ«›’‘½ÑòçÕAG\+Ñ(ûèP°ßÏÕÏçŠ¨û“-ÈÎñÅÈ*ÍÌ|&4jÌìódFÖšgåĞU1“v'”‹Úıˆ;t—UpnH’'Å¹Fóˆ$œü"9öğ÷àÎ™M·Ü[,*ÜU@•ZÊ$yx;;MòÈ»‚ÌQÓ‹A¶Ã¦»¢ÔÉ”ÀßK™Œå³óÇP'¦ŸòzB èğĞ¡Œ¥Ù—yp#€©„¹²[©÷®^˜üã¯x1Õgà2.‚¬Ş/ıé<¿X˜ÛfĞÌŒépÔè=R^xQ_)O[ûïçcW Ælî~])Bºs „,°N/…×³õAë8ZœtãĞÖ:½PVQ—d¬á]©œÉ
¼
Í PİkÚ¼$B›ƒ#+Ş+å$ç`ÒÀï©RnºËöëĞy	r‹8úÉúşw	ÜÜ@Ì€İ§ˆŸÌ:İÎM°\k£ÆÒ/Øii¶‚ØO­´‘õŞDóÊSÑp0mÈ¨×îiÍBÙÓ"´ô§#5ô‡Ì%º¿ÆÌkãM}ôÖh€U?Ø(„I@ÿıÒ†½ühğÒØ½—	C¬£¬¼ãıU•JÂTi)ü‘Œ?j†’J3÷Ûbæ³—Uºx˜1¬ßÈ«Ä,DR`ˆ$OØÿŞ›“Â=Ëªš¹´Ÿè»$å›Û~›6§6Ğ%æ›|¼3AX~Å©F7©+ÅyÜyõ!CüÑ[É™q ÃÓÚëõ¨ù!ih©ÂáOØëÃ¨-ÛØ–úRnEHBÈ.ÔWÌa'VsÊüæO ß7w[¯Ï¤>ÁçÈÃtl!B¨“¬÷©óÊ~KÍVXêƒ” ¨æ3yÕé‡bv•€+G[`óµŒ£É½9ˆåqBUÕ¼NäR–EæË"tÈÿå§Õï«âê™)ÁnÖ9Úz á#Ïÿ-ÜOšAÁNf51‚gG¦~§8„ş uÁ¼å\ï^Ç\#­òVÀqËÈ>"‚~³òÊd…N|¯JüÅ×»%	
´ãpÜÅƒ¦ìÇÕy İ¯xFç	X$èu¨€£ƒXÿŒ
KçAnWZĞ—?Í¡k;ÃŠtèfÎ«^¬­A”ÓéL—+¤¯¼¢Ê°>¾ıĞÓ²qß%èß;#z.44~öt˜Ä$]áÎ¦{.08{Ùw,µU¢{0 Ë‡?™ùJ„Exîº–oIIµQQëböòÀ‚FÚ×êéÑÀ%*ÓÕŸôZ¨=Ñn¾Ğ¦Út:ä3Ï.«iœ(’+ÃÛe”ôÖò˜Ò(‰€kó„;)‡­‚M7n©t)^8øƒ$<Ì¥]O3‘Œì
è³8~áFZ°¬†‹ÍRİ© ÷ïG#ş{gÓ–‚‰ ¯òæ'“~>PôyQrHôùœ"äË_«b7²	0<—~Ó!P$¥ºÏÃ˜Îáeİÿ¥bDÍÃ;€¡¥wšßnJK} 0	ßwŠ,íì &®-ŒMBDÌ¥)§œÚNP'CI:p½Œ‚t/±?ÎG·c·¿¬2Ü¶4J¾ÖM:DyO²iŞ1Ø°O‰7Kşœæä‚Ò .¨ìÏÈHÉB&İ>µ-²ye}§v›e,¿³¼İMó½ùM?&Üb¾—%2](øê­”Ç ğ¹'òXæR¿ÂÃÿ©¸¤ÂÜ<1L1š>ŠŒ|V	Í­³1•¡â!f'V±È—–Ğw]gãIqS…úZ$ğì¼Mëp? ²Êh™øzçà«sÂgIı½ô?y½x}J²«?Aù¯ôKlÙmÿ(‰¼ğ,‰f~±5vÆÂÔ­¼n07Bá#7Î"-SåEîé•LB²6ûÉ²ç§ğüş^oÀÒbÎN°K¡0VÃ¿bôô^¨­ˆÈÕ€â¯LÕ6°¹ €¸1ıò
M§åj“ÀâıŠİ«ÈvÍR¢?ü²}Ù€æa?–ınxƒuÀp•Å³^—uL”0*Ä­•+'¥²;å"}÷v¶ô¢EQÊ™ò–`ôWtá÷gÑ
}’ëÊJ¨7Ï@6déÁş5k¯–BW­êÊÚí¬Ğ¶Atkˆ€ó:“0¨-§+Ÿ|Õã:™xÙIô¬;³L£íøF—Şİ Â;‰5òór\V6î¼/+ôÛäqŸÒ™¯U-#æÚ91Ãtç—8¿óè”†>¥UğËhf–0_	²ÛQ59õXÉ"0wJMœ­GH”¾!ë)H³¦j÷XæµS\xh0xTÄ:şé’µ¾ptÕhÊ»rƒlÈàı!=eÏu‘`uˆğñ’Åªq{‘ßBÜú-3)Ş2›¤¦O«q‡å¹³Œ‚ƒÄ\=v€—óa°ïì¥•Ìük ›i¨A@ùjÄY6z”	mDæñAd­İkP¬›£›tªëútÈN'Pñ5Â ¶€Û’ßçï³A ÎN²CSf4jŸÏç’Ô_ÜRQÿ˜oz·	`©@%}æA±B¬ÅÈ«\	¢¨×XFKğûÏ¶À8’¬œé”ŸÂ¿ÆÅ±¤”Xì2%ùî*Íx°œ^BİSV‹8“ÄßJ@¹…¬
/y!€‚ ŞŠ‰¡”‘ÄHF­„v‰‹ßüaÙğ97Nõ\¬ã­ëêÂBàYÙšoÏª•û7©‡tZ-ÌoÆC—{Ä0$„}P¯1´òu¾¢ê&¶Mà"öõsË™êqËP,üıˆİ¶N›ÓY¨^5¼\mT²;Í÷ş7ÅB_"²ÄL:Íç™¨ù…‹ëWlF¾%[qíX¾{9˜­oî‡_ÿf°ì€quŒóL¢¸gd{¡d³IÃ¹ö­3Éö|AÕ«èÑ{ÓµƒıÚ>Ùıƒ¹~ŞSzò°Œ$I¼Ï TBºy;=ÙĞ‰Š—½wÉÆA‰a9WÖnCıtØ’™ÇspÒÂ¢¸E¡Gz¹”İ"œÔßaËÓ¹ûíŸ7Ã£õã†CÏÔÔ˜ÿ¿êpñ· ¼Å¬arJÚíqPÊ4«9¨‰ßéi•cÂd˜Üåf¨9?3wú)¾+Îå«K¬À½İ³,•Ç‚[º“¼.k%ÅÕ0€İÆ¦*ğáò+Ítú^ï8ìƒ/L«ÜÃ_¥ï~<Ôßq³ra•‰“bÈ …›ÊxJú–Ñ¤úxB6I(Êhßjj >ÓÂª\xR“ƒ}£ÇùœX¨›a‰wıV0’¤ØB¼œÛ¶XÙıº±_\¥•4Tát¦r‡ÍÙ°¾x¯,ô‚ïF¾ïöq
87  ü`Cßï»Âaô¢ezáT|Öê3Şl$.–ÃT.„òXKšÔÔ$ƒİ¤IÈ¤J9Sùnù&„éXg‘X2†½iNfSB«õTlÖ¿É 1«î¡,\¥|ÙKüºíj'¨Ìx¡qp6Ón§ôN|xáÎBÅ¤%Î_NâIçÀÃÃúÅ?ä$«Áu“Ñ‹„	ş"ÑB\.ÎÊe6Ëª_ı¦Ä§©c¨?öı ‚»gëµÄ:¶ÌŸí7ÙŸÕ´€ï‡™=ìZ¼	’.KëFCfº£3h¼·‰hR—çrÔÌ¥œzŸ=şóg9=ˆÀÖósFõîğ‘eš<UéÔ,ôlØÙ¸¬gÄâÌÑdj^ŠüG¿öóEÙ?UèµÜ‚¶"ÉıÜÂX®Q(şq¢ZÔø¾”ÃÀaU_BÑPwRÅŸÍ¡ğâFmØwãZG«Ç@ñ³®)ö‰XZİÿ"œè{8§vOY‡}ğaÈjÕÂ×[(ÿ§DëÁ•á‰b+sÿàKhRô´¼‚³{¦‘±ë¼³½àÇm'ô%ÓH÷û¸JJ'#ºß\ƒ «åÒ´f:*“Ã|¶˜äAÑ6^ÀÊ‡±¶‰²»u;¿Âíè3…–\ĞÆş†"¹ø¿ÇwyÀ»0w2‚íIRpÒ{¨¹²4fİh®İrğsÓ=)H$,"wmıùòğBw':Ïy8ÑğdçB]‡÷Ú¬2Ğ©=§˜yJaÓg/ĞÙ°W–$;—ŞÛ›£ªĞ“(U<ÏÓ[«¦p®&ÌD{oÊN>Yà²ù‘~‡¸Æ¼1E“	¡7¨âºà¡=1ê7¾PNõJâ~ª$$ŞğaS'wO2qg…-Xš¢ŒJ]‘4“ÕŞ¦ª3y‹mE¢Òóg8ÍokÖÏi¨±ï@Ä£‡1—Î(¹j««ql¦ÊÔ€D²BA›‹DX#r•V_q‡—âŠLÙã°9zj)7tSYLıŸùÁj3ÑIŸLÅ†îÄİm›(Œ÷a™Ó¾£¦Ø à“<yú§!Í“ö]C¼–™9ƒKÌ<Ã¹ AºÕ	×,Ü(J¬Ígü
h…‰6<ïà¢ÁÎ4ŒÛû&¸
‘X#à¢kÔÅ=4Ó-`Ø 6¼g——¨e+Š]8ğgÇâŞˆ&Æò`gå½üª¨¥
uĞ/¤ïãô[ÄÌ\ñ4H×çmq£qlÆªÿÚr ¨¾>€öNçTÅãù‚ğ`>Ó™kp?JW…oşåÅ+üD[Nf3Dèc;QK¢-ÚÁ	¾Y™}P*µØ–êÖ¯ªa4¾6oçiA™¥}RØõw‘	í f=g»Åj—ô{}+(³‹òİR“l(°'Güœ	…#ıœîĞ}Ï‚´Špôáu sĞ›Û—]¾¤Ğ§cÛ;óIXmÙäJ'I).1 âólînÂ~ê6S[™gÄb¢æBwÓ-÷©û3Ûo¯[‹«OG-çYoevAZUqúH¡tÒá??GWmÍç
°nõõXu¬U/}ß`¶äi!¡‘c§$¿CÖtË&÷Ù3¬¦¡VfÔ8ÓÁ©¢”»‚†ë®nç…Ğ¥¹+?=ç‚µ§~Ïm"=òNjæ@ÜZåÕş4AyM-Pïæ-¯4LB<:,#U¸%’ã @N·nÑ(ÔM
®Š€İ}«ø^`Ê9»ŠÖÆ÷ úŠÃÜu6ZTÊmAnÑ Ií¡%âSsãÀl XI¶Î£-psœ³•ö*ÓäÎıšœæ­6EÂùš3)ÓÖUIbøÒC[0é2µ‚xhßOÊíêrşá‚àswÀöÑ:7Jïıh?ˆ&¨æha#GG<G-¯¥Ÿ	GÎ`JqS¼µ½x©îæR ƒÅù7^8ÓÒ<= Œª§ÙYë¬ò–Äé¡×DD·$_Xş®¦Î†?‚2d$Zã=ßÆ¢ˆcVd/ÉİEiÛTFSÃpHçÒüÖ®¢}‰úøi¥d‚Êw'U¯½èà¼+”dbë©È*v¦»|m$²V¢¥÷lƒ;ûOTŸ7áÁK~¡¿¿Œ ÄÉÇ¼Ã¢a
8îrQlßœhbÇçû÷óõ™'&‹ÉÏ½=]À*ñŠ*ş}ô»!õ¿Şø‘4ñøEH¤=DI Ê0ëPV¥¹K„%ä<^	Ù¯3¹@6İí‰`zp±¹¶+@a»ØîNLuÏ¯C©¡Üí<FÁGál%Lå	Øg‘¸ì2ı?waZÙb"ÎÕ1˜0ÃX¦S½,E*sà
Ò³¥p†¯Íô@í'à±8vß`«ŞvG¥²s£ÈiK'n&NY˜Ò±±fò‚àê§>¯à1{0²C%3”}Xpe1hN£ÛİaÚ3À¥áÎ¾$†iÿ#ó|´WªÂˆF\Ìğ#{áòG,"<‡~73%xlü~–p›S’ãtB½V£(ˆ1a&‘Æ9—g¯Yù.… ¸éÈt¢ÛÆzpnÜIŠ_}ô’ĞöSt·tÍØ\EïK,gü«ù?!¹S¾bè[E‹´¼·6ºjîMøvAŠ}rbË`Ñã°>°?[ÁÏW¦òùœªÜ¨'2-•™#ÿØTTS•ÑT4mê=´¬ÈéÚ\ô|ŒuŠp^«ğ^W–Üı'ÔèÖâ”}#ó¿¹‡JEqåvÒ`Hœ´Ö¯yßâù*»6_(£ÔÂD‘-i™>p
 ãâL´ ÊT¿{«ÿU!frJ¯Ğ9AÆ‰»Øîå„ì™ ã«òhÆ_3®ìzGcâ« ÇLòŠ›ñ$jè¢ZXŞ Ïà¥0õh°•—1 Çóëmbş¬c2ÂhæíQOöéĞ$õT\ï>Â5%,Ï5M2lM5î7âÕF8ÆÑ“$èv7ãòWóç«¥i95 ±Hò‰pIFÈlE'—›NU~Ú"H· ÎÆ¿ic’NùøpKfé_Wn{îv, Æ&b¶EËÉçR$AâºÀJšhR•S]iMûBUM@moÄ®&õÅlEÖ»¯SaÖ£hÓ©,Á½JõAˆšP°ˆBLãeHÑ ĞœrG>ò_J¹Ãëû“ÇlgX¸¶R›öRûJxXÔä`0W™÷­^mÎ^ü§£î9„ú4»Õt\;ÿä:-hJ.pöÍ«R3x×ªğ,!u}Ü<™êó!ñÛPE‚0à-³³Sw~I\ ïğruùs3wÇ”X+ÀU´\#¿ÙO,¿¥ûs ä÷X8İ\®³+Ñÿö¹Ä€¥åñ}È
ZClFr·¹Yå	ÀâÁu<ß’5‹ Õ$åjeP‘®j[½f`+lÛëƒwAµ¾h
né?F<ñL_®òà¤e-H÷Gt`îÿzÚò*Äú/;Z0÷)ôÇ†îU3¯Œ»EZ4Q”Æqç¹d@­©Y¿3<]ou‰}ä0†£GÈ´ÓZíúÀ­"Z§ ZG9’¼¬Éİ?í3<òWCyğù2¿˜õ­5é3n©L†ÕÒóşa ã"™-MÃZú&N¶‰iqûuOËvx÷éßIWÑZ^^D¡^Œ®_Oó3ĞlT™Ä	 xØ³l§/¾"$ıÁI¨Õ­¼wúH)ÃbÃ/?ÙG°ˆ¿ı××¶Ä¹ÿïĞ‘C—‚‰ºÆÑéÍõİ©±Êki¥$Ïy™;‹]ÔNÈŠ=åİ~îo&O!	”æ-p Ë~ôûyu‹¤©²qò_®ä›{›ø¦ş´œ¾ Jl&÷zœ}b
‰§ñíE¢y,œ™Ú;¡¹JÏ6ßó½é¿CjŒ{e#á´ÏK£ÇäBàYU47#L#^ßPQç«õØé˜Tã=·$FÆü¶:+ˆô±K"xR=¾Å?‹xÜ§ü{	³©šwÇp°ŸÂcXË=£T"ÿ©:äºsÖæÛöu¡Cšûb±­;]ÙL B[I®®•1qUxSdœµhñG5 >÷ =”îˆ<[†W)ôKW%‡(İaı¤åªØñ†Ï+áÎ€‰kDPÑØÑ!«o$Ã¯L¤Òö²O9¬4ÿå7£–°]˜Î>Ä²5éõ)fÅZÙô,»ã»³¿á¯‚h$ÌÖÛxŒh]°b]€¿ı. íª‘ôA¾HK4Ïx’iğM^/¶ÆÕØ³ôØCL<ĞÿâæÎ¯ãğãSaÒ"ñ£ÃñË¦ãLœoB£¹ús–öºùNQ8Tr7µ#X!<^é‰eq:mr?‹ôÀxN4ËwŠ×çû>›;.ãÛgİ§ôêkKâ±[lå9<MÚ¬*Æ$A:Ÿ@»èÒyòHàn7"Î5zK+iV¯ÛïÇj_”%ÖSœósÿf$Oi¦5mÅş£ımH‰(—ƒÆó{1—›Q†İ8 m.ˆÓ™z"Iï‘ˆ¸|Gßm53®S]ùhø‡¬“ßîú8Ø‹õ·ÒÑ8SÈ§TË¦ĞIg³( éF2÷>©¹©;(# ëŒrn0ô?¦çVaç¼œvxÍq{²Ê(1r‹	| m‘¦Y§ÿø€P5JàÁ”'iÏ—JnnÉ¡øšzß1oiŸ¤yÜŞÖ7ñêÌ'f×†‰7=ba÷Äİ,¦jØ~W°'úÎpšO´ås/’ªı…ö¥{áx3§ä«v¹Ÿ•R'Âÿ×©ø»	°cÎ$@,&EBÃä‹J‚J ™Ô‚¸í„¸é ä1.Àc±.¢]+è…–×ª‚„ùşÕé›¦0B©Zqq^P1ö@[’ø	ä¥ê‡÷3UÓÜ7ê*Ò|ŞjùÕâ˜yŞğz™‹»MÍîÜò+ÏÕ¾•Pÿ÷ô[ÓSköAÍn?Õ|şQ|îN¯‚ š¤êŠ­É¦ç~O^ó-åÛêĞ@= Ò‘Éì@à¨"CHÜJÈds‡Š`™,tb›0.ñq«€Ûƒ†¹êÓÔvQÖ‘HZGä%³¶`ã,i,'H‰›øµªšãÖ­¶I]m^ÃwÎÿ>Q¬Z²+•.MÍO÷§'·7ÎŒ%2=kŠfE/§qĞaÌTWêj¹`)Î	%5{Wo*h‚÷'Haw^ à
]6Sæ{ -á{“¸ÕMúw#¥wiÉÑ Ä¸:/@òWìÔßË^0ƒ d¿ôòx·Øcì}k5<õIc€»á¾ö¡}anËk!$ÙÅã¾$àŞ3~†–Ã
¤[¼7kñhÜ“æŞı>Qp(Ş©KyŒË0Êq+‘ŸG¥ÍaøfÔãØ‘Äø6~…}ŸA`9š‹S¨õÓU¾ÃEí™‹‚@Öò4É&ÍáÁ|Â}Îæ>[ş—g ¶àDÑT«4ÂÌFÂûE§^=Sj~t,´òÃfBóˆÉ’ke‰•Õ™]ÑKE}%dWPé¿W-$'ş%h¹{éQ%¼«ÊPÁ­‡ğnSr3ët¦¹„ÇVx%,ßãI†dŸë‹šşôqôëÉ;OIëÊ®Şâ“"úÎ8]Võ+ã€|ıÓ^Û‡¥õ¸µÆCìßÌ™m™²ïÎA—?¦D·ZEá0]‘tŒXïIú?›áIï[üÊ•&£¯£øöÇa¦¼‹`ã”!¦4Í‘s •—ÉzÒÑô}óiûC5Agª¦:/ÿ(6Í°²É…‘}F jÿw¦£Ú+~¤³>qD»÷"Ï2fiG­´ŠPQ›=Á–UúWI[Ÿ6Á0Å3ãìó­WÑíjÀe,’·«GÔ4o®L£‘8y·-5p?|®®mbóĞ”SeÄœUË¥¾I8H„®j÷ql0ï„Zbøª"ŸBÈR±Ü.w—‘å0ÅÂ}n«d4|&]¿»”^ıÅŞT^ÌïÌ RœÅ°ìÎ±RVè¿Í:æD´øŞ¿’2'kÜç·0sĞ7ÀRyWÓQïÒ]bŠÀ@ì÷·PV–ÀìtàX÷‰QpİaéÛD%/pÀPJì^€’/dÌ™(4¸­å×‡æEqP´XPb=ãWMKN7ï¸Q<+òïÁ-Ğ]nVÚm¦%=«^öYòæp¾TRßj9æ¼R;ÑN4ş<ÄŸPÅ&PüĞ}Ç¾”d¦y›Æùh}AÉ¦&ÒÒ|ŞAW£s‡óıİº5±5¹û3"QÜ‡ÈOwyñ'K–•öï*»ÒÒkCÉ}ó¦·“Z³kôfï0H™ó…ôcuã|÷eå­SyÖ(€Å¦¤“^Å•šCã½/L×dbÎq¦ò“×tµß·QtZ°õì«ËY˜[†¤£ü³ÂÍAëmiÕ@•ZàÛŒ†º…21=ï˜n`Ìæëş‡'ÓÈ‰3'‡­k;)â%wR.ç¶6WL“u¿ü)%ò«¸9F;{ø ‡Ëì¸kJªgû@Tıƒ?İ<•ëÛh xd@âÊÃTˆĞÜ¯hä¿	?éxôrt2£<'š#«ïÎÂ(é…¶ìY?µ wå ÌQÆŞÕFµ+òN¬÷ge­,¯_­„Åe0ñ/è!*ùÀœÇK¤v™z³DÄÿù#SÑòdët¶èísŞ+Ü¨Õvî>iæ­ÌTƒşÄïhWt-ÌÜÂ¡TU¾ŞÑ¬(“Á:]Èo\T~_Ü/YX!Ï€@$Zá6j™ÈO…}wbG0á…OÜñ“z­X Eä‚émk ¸{7ÈİDóbîD²zÖqì{ÅŞ2A@¢øxš¢¯Ğı%cYì—MEagßº#_Ï'DoŸ QgO({‚åßXÂzSÌ–¦±ÜzÌI´(ßbÒV°Ã[¤’AçG®Vš–URÎC
ñZÌy°ú%ÕÆ[ O}«äó›ZnãšOıİ•?sŒ,£ÏÃé“ĞŠ%¶‚×¯yfÈ{»£!+šj*ıñMÁKh3›9¤+ã¦Âû÷¹èŒ‘k'éJ1büøòTkóVÄ§ŠûXã²4hÃKyA‘ØşJ¤õ¾MQGĞcª(7r—nFÑõ$"´Ğ@‚·[b¡©3R†ü§8õ¸.à¸ãş÷ÓWÒ"ûtç¨íúÚ³Cï­ùO?úé¶£@W¾à!+¶ByØ5’w‚*PÙ&pèz  Ù c¦ÓQç^ Õ€À0ø[ã±Ägû    YZ