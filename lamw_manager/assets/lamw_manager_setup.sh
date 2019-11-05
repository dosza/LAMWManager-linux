#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1323574573"
MD5="2daa26799f9039e531d98364a468c6af"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="19589"
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
	echo Uncompressed size: 112 KB
	echo Compression: gzip
	echo Date of packaging: Tue Nov  5 02:17:12 -03 2019
	echo Built with Makeself version 2.3.0 on 
	echo Build command was: "/usr/bin/makeself \\
    \"--quiet\" \\
    \"--gzip\" \\
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
	echo COMPRESS=gzip
	echo filesizes=\"$filesizes\"
	echo CRCsum=\"$CRCsum\"
	echo MD5sum=\"$MD5\"
	echo OLDUSIZE=112
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | UnTAR t
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | tar "$arg1" - "$@"
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
	MS_Printf "About to extract 112 KB in $tmpdir ... Proceed ? [Y/n] "
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
    if test "$leftspace" -lt 112; then
        echo
        echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (112 KB)" >&2
        if test x"$keep" = xn; then
            echo "Consider setting TMPDIR to a directory with more free space."
        fi
        eval $finish; exit 1
    fi
fi

for s in $filesizes
do
    if MS_dd_Progress "$0" $offset $s | eval "gzip -cd" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
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
‹ ØÁ]ì<ÛrÛÆ’~%¾¢âÄ’cğ"É–c…ÉÒå(¡D)ÙIljHID €€”l­>fkNíó©}ÙWÿØvÏ`páMRb«öb–-séééûô4T*?øâŸ
~vwŸÒïêîÓJö·ú<¨n?}VÙªlínc{µ²Uİ} OÜÃgF, x0`®ûaÍ¸›úÿ—~Jå¾ğò—çÿÓ»ğ¿Zİyú•ÿ÷Èÿ’Ã&Vß›ø/…ã{å?>ïÌñ§²[y •¯üÿâŸâÃrÏvË=µ¢ù¥?E­xæÚ3„ö€8ù€Ì|<f‘¯/=Ø¨;F-<ØÔŠûŞ4ùèömîö9ì£”N±K+¾&@û*¥íÒ¶V<àa?°ıH´íäwè{nÄl7„À›F¶ËCzHqÇï#hÖßà‚.ñ X0šN¸…%­ØáÃã(òÃåòÅÅEifÏ˜çØîô²„ÓK½ <°û¬ÜsÇ1åj&›F‚í¹&âë™6}% ,¸:kš%Tz"÷d¥øllÂ•Vp¼>Ò½?Àø<?
µÂ~ë¸İi´›¿Õ66µvÖtãŠ­7­ÎA÷­xÜ§ç÷×ºV ™+G˜U1† ×tÓDúø ¦Îc”ğKÀC©ß&c>rÌ4§ş 9oúô-ä–x—h2fb¢ïèšV°‡ğö-Wˆë5Ôj`>†÷ïa¢1wµBvC`lFÜó Ö„ÙµÀâé›€{.<š.T´ÂĞÖ®‘Œ1á8˜‡°Š¤m¿ıóN3Jå»¯"ç¨uÖØœ3AQIŒ¿ˆı¶³³Âşc°·µ;oÿ«•¯öÿÿ±ıŸé7zµö–ÚÿJ©Šö§½€j¥\}Z®~·Æà“ëEà34#Ş0gıÂ‘èg.ğK\ÅEô»°àZ†}Ê’g¼‰TÀŠ—)İ“¥ÇhËĞ¸†ˆ±ÏÜÅ›…<ÔÄopùE;
j¼ï° †û(îpGôL]´¿4­Øº0pY„lûB€OA üF|‚~Ã´ÊÚ.¿äı'p6€	Ú°]Ñ8´ş˜¹#~`¼yÁ‡Í+i°ÑúVuxX]‡Œ±]&—½ğ>i/ VÔ†Ü	9µğşØı¶¾ÓaàqÉN~i‡QøP‡o¾ß£.íªø„¦ÿÙó"„œıqùf»‡¶Ã7šx<ôŸ "Àc£ }AÑ¨Ò¶i´Y„êalI:t£€bâ¶€Z1"áNİ¾0»Ê‰ n‰zSw qTšÄWm"ÏĞa£:Œ0xíÑIë¤ñh	Íò$Ó­Å86ñıJ-M'ÿVxô33'vnjA¢Q•Ï=äî¹x$2 —'4Õ”Ã4h
ÕÖgÌ™r"xƒ©$)‘®ê» $ŠŸ=A )ÏÑ/£ü‘låi‰*†Ú^Û06º¾cGH{0ˆA†˜mSˆ¸©…q— !öÖt”T<a‹…CDT³(€ß|3GÄX$w)`IÙK°­$]}Ô0œ•´êDk¢^–„N5®ğ±\~W.Ãõf*½¢™F¼ı)
{{ôó±S(
D1Xìø_apŞ2ócİü½b~·÷~¹WIFúã,‹|ñK`:ˆÁl`÷%7ç±J7 °[_¡(%@àÉCÖƒ¤WÜE+ñnŸù<TlˆØ¤f\j7¬³n£cuÛÍ£ÓÓÆUïtê¿Ô˜3bš`TÊœyã@â¼±a×*{ö÷yÏşöÛMBWŠ³X¤{š®Q3šôweÜÓJtlB§P”ä¾i˜ÔØÑX°$¤Jå.HË˜ÉH¹ù6•¡‘>Ëm¤²)ÎeF'q,Z¾¼b	LIXÈ–¡‘6Àÿ  jE*a‚ô8:ËŒ~ïÊÖäŠªPJ@†ƒ ¬
mÙ·râ)“QİK¾'Œ•¶JwEz_3¶“ÖxgHÓX„ÂÂPğYÙ:N2Tâğ£T¥Êùà
–À%«¶T½ÜHOZ)ñ4äPvHr`Pèh@®'äcn\U“c„/ºpUğ0Œ	lÄ×!ºá{èÁe.ü®ËÙ-$ºN®X~¼A?Ô£6”&Œ›"ä‘dªö†à‰oIy³•±öjeæbòË¤©CÀJJ¥cÏÛÇï¯çäUÂ·ót'³á#6Ñô¿õôØ¬ \ù§
ac”‡_;ia–°KR$iÓ­;îÿ”Í¿sÿÔö—M»™ ÅºïsRj!G¤2:Z)Z©RC\šá;#?"2RÓ²Mİ¼›XJÌşºXŠ‰0BB‹éoäœŠ…î&kÊÔÎ‡¢jĞ²ˆ4—5éşÿªl¦ÈàøçhpGyûËD8Â#GáağïSşÒaî9Âw:!dÃ´›^ÖŒˆÙ˜UÙ¿Ş¢jx¸'tpğé¿œÈ0<Ö¹c†x¢£ûûÔy ¥1\ˆ)¾B[mí>Š:_€ôé?0îıh3APò•`ÚğÈ`ïIŒŠl`÷Ñõ2˜&s˜‡j5É ‘hs†Vá«ãy‘"±]76.Æ›Ø›"Z
°›x/0-â!Ö€ÄOzCş§³iÄp=Ÿ;Ğ,Ú¶b#¼àÄ'«qFí‘K›A…¦.\ØÑı¢œŠófÈòß¹<n¡~—J%¡¾ÙBrÑOqfVhŸÇ=Šø¥ç£§5µô¸F›~ğõs¯÷?}J¼˜½©í ;>wğ¦üß³ê|şoëÙ×üß×ûŸ;ßÿ$ù¿jy«2Ÿ<£ç˜tÌ“Ê¢íR‡ùœ`	–ß&	`”n'ãÿ`$Ã"”½nªwg»P†z½³ÿÓ³êî ğìÁ=e	µâ ùıˆ< qàÓ¿{äv†~p/sØ€¡¿†ö>Ô8aöéß›ÍlN~ Ø¤‡ˆ¸†ô
ùa{Ÿ}­0@ÿn‘¯É\S™Gı²†S^ryD7Iq®DS¹’ÇúYoêFS¨>/é2ïÁ/Åİe“,:pMÅ Ë‰B‘©‡Çz“.àà}T¿»ıL‘³HĞ©¦hl—*¥JÎY§iákººıgnipçà>sJ^0¢¦2Ò¯±QX¸Ã°µmU¬Š„P¬æÑK«]?ı©¦—§aPvìM£Š™aû‡¯Ô0¢!1j¥şp4²Óh6êİFM_»ğëF§{Ô:©Å[¼Ze#3SO©N v>#•vnµ¥µ[Ú¡[À42L¶qùü™…:&njÍ‘;]ØW&…8 Ä İ‰
µ%¨´5¤ùRÈ-A£R(¨]	g’×®'àõ{Ä¢OÿD]¢‹ƒ9¡ÕÀÃBŠ
Ï!´'½Oÿtì~|>&`¹i™Œl—²ÿk7¿8ùîrOè½Š¼qFñîKÅ{?3º›tü©Kã×F"a»?&jOÎQUÌ,´4ç››¤RŒ	šk!ÏSÔ\µTœm›»şFˆÕÄğDHŸk‹ãè:œ»3Š	ìiçìäHÌí)Í¢#@bPV)¶J³‡\O†Y‹ãŒ«…¶¿½3_ç@tOëÍf<ì÷£6EÉ/î4NÎ~µ(I*˜Æ¸½0@Nf w_ŸœÖ_]C¶dÅëR–®%ÔÒè£¾dw‰Ğ,]>‘¡«Å^/†Œİep)<ˆ	™
Ö—n¡)rjÄÅ¢±5§´iJëäğhÍ,'q)«"„	‘˜ˆ B{IMûÔƒ‰8$Îİ½ÁÂF%·`ÉÈŒ%Ö
v¡Zcò”ò-C÷4âA†À~ûÌ:­w^5Nk­U«}ZÓÍÁBMZİ¤_Æ=°ßiu»rà¾£^ïÖÁÜ¾>l¿ŞÖA	_»Ó8<úµFœ)H*Åvc¥ĞzqK¢"™\AF[gı†¤hFóç)°bJÙ˜l2T>Ú¾"‰ŞnKYIxïûıËgÂŸ©õÃL¾0{5„‚…Dû©u}ÈÄÇòCføofÕÇ¸:iuëÍk.?—lq‰àëéÂRí×÷ÄUF æÇËÙpå¨B’ƒ<Tv-‘ZÓmCgE·ôÇÏv–ŠïmìÎîd˜s±ebı%‚šæŸ„svëø¿Œı İıó@#Ê1ES9ÈçTn&Æ—Vá»R©x7öÊ7°6‘CYñ\â<Û¹Î{Tïğ™(ì¸b")ÈJîãÊQ
¼ô<ºjd~|™Ä|_Ü¥Óuh¦ÔâöıL[&ë|Ø¬¿²[dãê'ÖÑËÆGÕ¬‘ÌÌ—6WEƒ¹Õ
ÉÕV‚i¸òM
eÁEûŸA'gğñû‚¿œs„Ãâ0c›²rµÓ#®VèŠR6ëŸ³?Ûî€_ÖŒµ‚ŠÎÀ¸òqDøÖ}t-{Ç=åâ<EÉûÉÿÅ
õùs7çÿâÿ­¹üßöÎîö×üß×üßgÍÿ•ò[&şö—VÇ€’Êq:Â;O‡{:¿ÙçÒó=eöŠ~À}ªì›ú£ ÉªN±µŠ7rgKÿyÎ@Ûn=q9ï©G„ z<-¤…!Ù’±2VÓ5-w›·°J¾şO:Tœ”êĞBßÙdY0¡T*‰”Z÷å°Ì`(á…ûüfı÷zç¬kµšúı—ÍÆ’»}	R¬%i°°-ãj	 Y™³°ÍN¾è.ƒ}vˆÄ={Á_X$^Lpıªµâ€£‹Õç9Âá2s°Š¥KÑæ²'ÜÜzÿ…K ÌxÌH`‡öe(”½Jn›¶2 —J¦ï¿äx£\Q)‹à3âj£GbÑGi¥Ç‹•é—­ò	±„â+a¹ôm>F#>MÃ#™²—/t(İ¾+âÍHÎqøóô¬+RæIÉ’ˆ¤ @\V¶£{ğ‹w´¬WgGRâU!µ§Bš\8%±Ñ”‰£‹3N×Ãtq=ûÈ]†ÖVÔ|úÇ§ÿD¡½^@wïT¤âP£Ì´bìåE|Yù d,ŒÏÄ« ÿ|¦FU¾ö‘ÖèÉNÖçÉ›v{ru–Ä`~d"7”+É=óu­^%±@°±²VhÉº+
‹t[ŠrŒZ¾ BˆÚ4AC[Vu¨ïªÊ£Mœ'ÀTœZP…ú\—Å¤8_e””şŠÁÄØı1ïŸãJİ©OÂ X+ÊÁ·2uzD9ÇŞ… ™Ò¯Ä•‹{ŠG¹Ê>Ğ–)]Fæë¬ıªS?hˆÛˆjš°/á€÷l<AbXĞò¹ûóÁ/ãá¸õù-±Çÿ187Ÿ›ø3Ù€´©/ÒŞG¹âÄ•§EUyñ†hªG/2çF…îsQFJôøà	LCaÍewµ:w\”*Únœ`§uĞ8¬Ÿ5Ok†jhvuP·z?“Aƒ:ë»(nŸpÇåPzŠ’c‡QZyyE>b ÈjõP^hÅğ­|ákEf+[ /] 4‰â¢hÔA_¶mU© |al!«–Q…‘+p±Ûô)É€Ä—G^p.Õ¼g;vôá!œÀ¡èô¡ß¤Ä¹¶¹Ê.¡prwrkdDÇqûyr<”gL&Éiµ‡(—½’$)]Ñ)êÒmH5®¸Â8…e=V‡æ©kKk÷›±¼Tjªïgì:s“v±åbHuH¤.?4ÓM3„ÌüçğOÿ`œ9¹E…ÏJnVqbë£I«*g/¹ü;c'v;àoÆé]Âi€‡z¥¶ß™ÑŒÃ-FV«…Á-MÈ£Ÿ;ç J¦†lêD5!1³ğ@¶Ü-|-âÕ.KÔÌZ­€“So¡X4V”ŞË¸˜lÆ%ÅpÈ’§úö[ØÜÜá˜.láGÔCF»ñÕú…Mwëâm—‹ïŒÓ@íÂ§N!E¹¸¨¨Ì¡Àîà"6çv#Ï÷ÉìÅïÜÈ2³øu•t+86wåøsıu]İ«¤Ã’Õc ñ+§Ì/|Ñ«O¡xİ4’‚n$P2¯ÄìeÂ´ÌÂ=¢ª¨¸`ÀıP‹¿pªü¤C¬ÌyAŞ.í%G4q:kÖßïÄaÙüÑl•pB|x0ıÀûƒ÷#’$£éÍä¹±æ|w¢RóÎuNŸæ}HÆ,'IZº›[0*@jf"ÉïÂœºˆŒlt?hK
+İåg€N¯!ãAÂœØ”Hİ‡7(,x‚XU— ÚÂ4Ş¡¥RÚòvdEç„i0b\ÍY‹k¬£qYş(#åJö„r{nXæ¹°şNìN<˜{óOhÛµûèäUjLxx¤—vÔ–_1şœ+ÆŞÎ•ç^MÊ¼–¯·Ve1İ†Õî´~ıM¾D§nz©Åê6:áÉî¤§Õ9M:¶¦œuš²ÂæE¹ll½0¶Å&•©œûÎÍC“V2&„Ú_‚àœ:ã™Í:®ŸÔ_5:ÖşñÚ¼Nı¸qŠ‡Ú†x¹ÍG*Ói,Ü‹¥Á42'ÁøöEŞ@&cM!*g]äíeÃ^2óåÙO[­f7AN”Ï.Jzõ•‰~,Áco²…Á©Út_È-F¬Ù°N²ë	¬LÓõ,QÁDf‘¸Z£o ûDƒ5öÂ¨fdië&nawJyêİ\KÑ­˜¤ëy:š7ÓQÊyŞÈáñ/¡~°è/*Ø}•Ã>9‚.‚¹©›ç<²„î’‚¯ÂüsK¼¸LÀ%»[Í¸è«àÆ‹EÑİ*>›ëùl®åsóh¿qÒmtsjƒ"%‰ bŠå‚¶FÈVØfzÚ# Ò©Ùh2òİáb±PïS¬Ó^£š\˜ı_1w±›$YrT¾êîÕİõJ“ÑUTW|Å£löšr¡¯Êo«‹äk¼”
Õ
“ó€é¯*‡ºuİ”Vg.ô)z£waŒ¸veú£HœÙÊªr‰ ˜ôŞÄÉà|áÕªVGÆ+à|¦ø)Gí´Ì*¥èÒš©åeKÆå·›†lU“,ú²Â¬@=Q_GÇµP?5ç.ú¯sÕ£¼”şì“ö;VHÄß°`BiFªC¥?Â[üU*GU @]–ÄÔ™8‰\—RQB^İÊeÔ4nºQU3z„GòfMŞªYİÎ¾Õ<ùeEB5®æ2Ï&#õ'Là	D¸L,B&²ª—_DIÏšÕoŸEŸë ƒ®AŞ:ÒÁå‚4ÆÑ@0—“¸ÓjZ4.©=Ù‘%Cµ½ïx.×ã+)µQ}3ÍWRjAÊ
ÏÔá6ruP.!Ü-Ëbí^²py9ŒLŞ:‹‘?u]šÿ‚V eŒ«¤Ÿ®JVÁíe@ŞüÜ…k©Z(öÇ¸/Øİİ³3[A±ìåM”Y*Y7MRI‡¥[-¸©»`gË>‡	%k“¯ù-7³îF7¨ H‰?{®Ÿœ
»“1˜6²ÿ»½oënÛHÖİ¯Â¯hƒš#ËÛ$EJ¾ŒdzF¶h‡ërD*NÆòâ‚HHFL ´­8Şç¬óp^f?ÍyLşØ©ª¾ »Ñ )ÅöäÌˆY± ôı^U]õÕ [oGÜN²
‚åÁ–‰RC…‡@¤h¶»u4!;áaC'a[DSTÔc˜ª”$ñè)c(xõ®x€ğ”{éU†-·ºyÿş}5œÕ‚i ›ŒnP”_‡î@IgDaZç@!fÕF­±Q»W… Ò¹ÿğõqIM¾¼pÌêè†³³šR÷˜«Ë:"x“¯‹6@5é#H§,Ÿ'p¤šT)ë‘t‹Ï%šÊğ‘¾-Ghò›ã[êB>«×¤M›iDD•FT1Ì*ñQf(™YçjÜ0Q–k]q 09Ğ"ÁLµ(.Âi(_Y…vi;$ßÊçí¡|õZ«S°K,Ğ.îÂœ©%È*duƒÊÃhô&`dÈ3´zFMv¢	Làd6E[Æ|™ˆJıµsä$	´5[Ä5ÿ7KçÿlòS45rQ³xEŸşVk8“Wˆ <|±G³ÿvs‹ìüiCWyl]İK™êÖ¥|>Uµ8®ƒSVVo.ZÖ{Ğê¢-üV²¡æ½M¼81Ô°“1$N	ë5¾eeû?ÒÜ9ä˜U›{îÚPeøA‘‚#æd[›››şx¿aâ`Ÿ‹•ÚÖóè¹x$I“×_Ù‡%Í{µfíïŠdœ)ÃQóút[/ì—uªn_ä'L¸ ºÎœÉvlN‚|ìqtôÁ{ˆ9—œ6-VœÂtÚ)™LÕÆÕgÓÜs±<Iyšk¦Úiªë‹-;?Y>AW¡s²ğ‘ë/-İï¹°nŞZ.ë~^=Õ—{ß.ßñZäN—?X¸%HIvRÒxx&Ö=·è’åPeİÎóÎA˜[~w‹ÔgÀ0,-íÏñ»B	ÚxèäşÂŠÈı¥ª®kÂ,Ób+¸Ğ	&• ÀÜ”—6ùø„/°€/·âöV.Ã”ıÌjuzõc‰ rs	­ºzN_ònÓÒh.—YëÊ…DñÂÈÔ½¢ì.ğ2ï'£(!8'O}Ñ¬’ì¢×ŸN}¡B\VÚUåyŠ%×n¥Ã ÇŒ0˜0\ÛóÍóZp†_£ä¯´]08ëjõ›ßâßc[Å4%¥± GÃœ¥âæUZMñÂüªÉ7–·ºvª/¸vq'Ë¯`ÌpíÂ¢>ï:¦ß=Õ9•Tw^Í0V–JTöUÌ¼"
WÜs#Û—8K&(\éÌé­òëoe]ãÈ»´ä`õ9¼xsW[©gÎœÛêYx“U)wÁâğù’“Eó ÜdÄŠt@æÍ¹tâèñ’ŸVãÔŸ·›|Uf+4,%½²Ê
P¬fÇ›9©uB*áÂ"uE§¾üy	4jXÖù¡UsuWá¡Ûëê,"ÅÔ”c7?¿Ÿ'äÜíèwSÅyu¼Ş¦il›
ÑEş=V$Ü"3nÃi%°—Zô‘Ş–g»bU[§ï9/¥õ[[zç[ƒË¸hĞœëªÅs¶;Ò.:k]ö>Bå¼3X~B/8b“y^‡“Ñ%İ	UYL“ò$"	¥¡%ÑQ’­I-,Ğ5ƒY’„“¬ÓBè·®~ÔVÒ'k)ñL"ní v,;ËJ‰DŞvı´[±ºßcC`0ŞO4ávşÈªÇ¥\˜®Dæ¨ˆP;iéf1«¡j2 ñkmšÄ„‚Œ0¾tñiHaµ»Ïù‚(ƒyĞï-ía‰¼|E)şş$‡ı„>¶6€&%€û!ÎÎi V¨ËK™ª8lªŞ
Kıo‰ÆÉÂ4%íïA€>XLîa*£$
œ'ULé‘Öö
ÚF@.:Ò:«è(¥¿ŠyŠÂŞ…#)ãäHP˜EŒUÓé ±Ös¥GQH2©ØQ´µ¡¹ƒ ÙÉwªP +H,s"„ºòrªÙzÉ+Ëé%;*Q^aÁ€—«5zc™¦3ÙÊ˜™È€ÔÛØ¥“@¶ş.c@“£è§@L(YnÅöÁü…&}>‡)2 ŠÄ]JšÍ³æP
 Í0!p–`@&xƒx]À¬ŠâL@B‡xÿj‚¦8%Ç”tNY±ÂŞH×gaŒ©Î—ë A”›¢¿åDR0ûÛ=¬è¦#"ª)ÁÏ‡uğë[xı	“fø8È`a«õÖŞ5znÂ”RÖ}ğ,sä¼I9œÅ3eÈ=ß¬T ß˜ø&Q’7uÉÔ¬ÕÉ+ÃiZ‰úvµºlYu¹be¶$W©J_„éT'X5»T½ØyÉÊ0.Y,‚¨˜-²“%W”‚Îİ«w!:›
ª>nc`”°“*smEX=ûIv­?/‘3àGl+ˆ
i%êŒ¯˜vqçŒ¨ëÅ	‚ĞO‡ÏR‡Él)•ô(ï5oÅ4SqìÿŠ`C‡.æ)ß¿ŸÀN‹a&¿Ú“æ*‚Ğuêì‘Êì2£ÏbàÅa—xK¹qÃ™İ½'Y|2ß‘¬m$qü^Äœ¦q"¹âÃ÷“02[Üô ªÉbÌP¨âı¡ÌšqxtS}cæÎËÜH%:N1&œŠj\Œ¢XbÃ“ØèiánÁ!ôœº¿­ˆLˆè¡ÿRtÒ%wk}å÷@ÉY$Ö3¯ÅüjğÔ_ƒ´I¥’}ŸW¨HG}^ÚÈ Í«Áwj„éÇ‹»e%G×¸Ê]zH}-¸ä˜·+WnË.È1o.1ã„sÙàb3°ÅáQšÜ‡¼©›_":Ù#_êùg‚q H@5½¾¢ârEœ)ğ˜?Í–{àâŸu%dtÒrF¼xèĞ·(]r}Ø„HX9FÀ%Øh)¾‰QnQ¶²¡«ç ²pAÍÕª*=¹™0Š¯t}]¢1L¯*ÏcÿèEçi§×ß}Úƒ<úû‡{m` +ìÑAÊà0æ¬±8@f~ 	·É(±KXJvË_ªÄy]È*ñY;1ƒ`8h‡	îÏğßh¨4ˆÊ1oVŠ\¦ÏõK--”/·qM´î9Ï?²‹ ;'NùxöÉW8ÛŠŠ¦òÁsÑ Kçí±
´òP:œh€DSÅ"úİçcwµ•ã!«²ítÁn»;ÄZ¢3Ğ4‹„”rÎéT±¡'İG‘óÔ+œó¿ò™§ÏÈ+®ƒáÆÕÎÿŸĞ<¾„ÿï÷î•ùÿÙÜz°Qğÿİ¸wƒÿyƒÿ¹ ÿs è= (y ²¦ú’8 –ÿ¾Q§âÓ	şI@¡´=P¢räM P7'/H}&lÌüXö{W¸äÇœ’†Q®d”ªÿ&„ñMR™Ü{z•\§ãˆ,“Æ€r]¶Vˆèƒzi5¢Í²iN£<¯Ò×ûŸvsC¤Ìót¥Oî“zø–¦ôŠ¦-ScVU-ÈUó]
Wéku&•‚”fÃ*L}EZßö©A_,­ˆÚÔ¿Sdôp¸I_úBÜ-[¾¡Z±¿P"ŞwE„ïH»@ÑX&TšjÃ·\bö‡áä!Š­óÎxe&6¯À¹[J™Ğ’J!Üu!3ã
!0úïÌMÿ’ô7šüR›ëg1L¨œ$ÓùMô~Şº½zgİVÛÄ€Âı¿BÃÒt/ØêGŠËUW„şÇx‘P‘2\@Õœcu|gY„™â¼‹Ä{Tº¹Ó‰/Å¢aèY$*5»èÇÓ,EwëWföË/'u©®òàB^´Mã{[Ñ‘ÊvY&Û«Rš­ÕŸä5ä àc1«Oš;ˆe\Àö].b8ä	Äs+@õ¡Å2Ôùfrít^dâ-ûbfæÁ*Ü“TÆ9è-6|Z¡›jG-DĞ7&8¯]UR]ÎWrØO¨¼<_ŸBÑnc:™¿Èd(¼ZWnbä¸¾–°ŠšDÈş½çkQ²F+î~İnsK'4œK‘ë“q¤h®â¨éÑşÙZ¯5ì1É 	¢¹ÊàK&Ïjs(ItÆZ¯	ßB¦½	)ÍÊ”œ,hhù…Îß¥¡WÀ*†y¶˜@“ŞY R¹y‡RÆBV¡â³0•¼úG«+^•0º6¶Ğ°?Wx,	i¾“Ãİ€¥Á¯ÿgHŞ~¥ËY~{â€huùó•8w šÀöÈÉb8¼uë–AB"™‰W™¨d¤ HóNËÓjH®]w›ãs"Æ1
”Ö5W?èaW©òÏÒÏ„öóãNïğ“Øùól¦éL¢“Ë÷oÂ$TkÓ.ÈÙ§£:º¡œK˜Z”±š·hœèk[$ÕØü”“I	/¿µ“d;òt¤€MØj¯³ßî¿ÜíôXé>L£ƒŞ<<šõ)¹øâí?¸sÑ¯ğ&y_ä¹ÒV¤dnKÎ¾“‹ıì²Å-Ì±hg’:¯ó›h´PÕıÚdùÑ,…í!âjß	VQ:G ¯Q¶nÇ+Üv0¿AQ‹İ'BÎ#<h‰™Cf±Õ;@R3^‘ÏÃ]¡+¢||!øËö‹§pHáã‰by~Æ>r›+)i«Ä·şã]&½©Ş¯ml±½î]¦;J}¸î-/šëûÊ™¨öºvŒ¢;¸„å–Òz+Ù:4m^Ük†·4”j¾Šû¿‡ô@~Üß‡såçŸåÛƒ¼‚‚Ğm:°ÙØ¸)"¡IFhÂğ‹÷DìN•×î1à!Ùj“­n±Õû¶yo›Â<yŸÒÓ0íf°làÔÕ²$¯ix>‘¸`6A¦9^‰•¹¸!
wÂî¸Ö[ñÅ0,ÉRósgh&]BPB%½&ÊÈ½ eÊj5·0ÂÄ.Í‰Åš¢ç…–ÁSª¹õ^?K"ˆW¨¡ØNa3‚D!õ’«¥Š’sµÔ¾Ì3ëéª€vÉeï´Î­¶t¯un¶òßqÜ3Ë·|ë¥™N]£OkyƒXtVæsÎ¨03&·unò£ÊœÀZì}¤kñ¶
m’Z.Dÿ‹6Bµ¡Ó(½~—]yòYZ[m²™mQÍå¤ıÁ«N¬Y‰P­jJõš³D0&Ä¥ºQ[qj/‰ªb¾	GS›É%ë‡–n4‰î˜;£"´;“wÁö„ ¹˜¡¨ö–Fò¶0Ò|	çû_ñş§(ı:şß¶
şßîİ»¿usÿóï{ÿ3Æ«Ÿj0ŸÓÿ[~ı#h×}Àr×AÇa:˜Øx$Ü(CåN’êuş*ï‹„sùh¦µÚ×¹²T ¸×&¶ÄµîÉ“îİ^{¿Õògé™—íözÇ£áwˆÍ|‚Ï¾kì?†0R™ñ7îß¿/ÏOZşt4»€|ıÓÉC5¢,~Mf(VIfØÔaı^CÓÖèÖA˜H3Œ<±³ÀÛl7¥eg‹êRåÿé|:¸Ëœ®:5_óœuVt-H—–¦yV2X9!i—º³gÕ¸ 3]Í„ ÃøX‘ÿVİzø{T
¾ƒótĞ"à‡+g{ígL¾şíéÑÉîñ>ÿ¤|óÊWá —¿}?”À˜ŒÅ¯08‹ª"øÙHÃø›ßºìñÑQ4»Q…eÇÈl^ÀópTKc_jİÃÇ=+o$Ş®r³î®ÔVíõi¢¸Úä—NÂ}ûÊÊZõÙÌøGğLu`‚²”¾ÀÄÒeíÊ)êw®‘&ÉFk|”`YuùÖóºî)Ïš„LAœ
mğ(áKM	uQ÷Ú²3ó®›Ä$R:©¤–+pXVQ"åÕºâ»0ŠÂU‰`k°¡fáA¾F…iüî5Ğ„(Õt$èkõò…‘—`±QàãÒ¼¢íAØŠöñŸVÁî”[•
•HZÔı“`öğ¯­5ãúˆ_i¤8µÖ w€"“N²¿ÍÂ'£`ò{\^ãhÅ‹üåSğ
CÚvXêÍöµwÕßÙh[mdPÃÇ],(ºD²+XÏü›ßW=~ÌXiß›Ùh½Ù2ï?^”‡ktôŠàÆQUÇÚ5s´Ç{n6´;216³¼NÎ¸Vt1ÓF»
aHB^‰8†qJ…:ù»8SÂ±@ª”NÊñYDú“Â;-Ãëi-bƒUVg°£ü¨gé,@SôÁMŞÅƒx&qû]æöä—âÅûºWä~ù¹MÂªı5aŠ~›W§ª
1&Œ’7•Qî¥´Â%E‡Ÿ}~çˆ‰ÊUìÛ]éK¯†‡»¨ÈeÁ{6æ÷º9nÇí¿êE@j‚"2.&æ@±?Š]mZÿ:ô®jâç´Cst[q/^²Ë’/,Fà,9Ë·§ù¥!dç3“anYW]Mz	£xŒêé› q÷Û—Y¹åİ¶œÆòE¸’ë†-Ò¦fh?AºÊÔÄ¡eÍÍ!Â„¡e¢E™BF†¦‰'N%Ú°¡vŠ]¸u&ìLÎãm‚…É¯Û¶íF…3”9§À^…¢G_Û=Ú}ÚÎãI¬ êôÃ1š˜~`†Ãaz:áHÍÆ¹IyÚBU„|ĞË[¬½P ÈQ…›ï¥ˆ¨ºZøDrN¨µª½P ¡,¤§èC¾Okcø Ğ3¤ß=9B×@­9“Èç#Ió±Šòöêmü³.ƒÃ^çú:ØCæVY‘Nâ,:¿¬¦@¼¯{¦#×¥ )ô‰è«Ë;«4å®YÍr;p/4O's&!Ìg Ûf®9x:)Ÿ€yØ’“Ê<|¾½¸'ÔY+%Ò¿¡9Æ®Ä5nU¤Fãè*/è	J¡}tPŒ,fãp2cÈÆáç,î¢¸g¾å*En°tí©S¼ )Zª¡sèó@So‹Ï%d}@ !ı&Lî2(HÀ	¤Yjâª/[0×+[²ÆãhÖÅxêÄÈ^:µÔg£±†éÛ,û—ïï¯öøgÖdÉåk>xŒÃV>¾:	¢ÄÑU*íá åTçCgdÑ8H.«œ¹¯rŸ«®Ã˜ïãyV¹Â ‰úH+q¤*ÔàYfÆƒ‚ İõ‚R©eØä6jğ‘ÒõBtgŒZç¬-şér¶vóİğæÈÑ³­½\aJÛ)ÆĞ’S=ÅóŞ·;ÏO:Ğ×Ñôâ?°M³éËı§£ MíîŞ‡¤jeá‡¬şz-…QŞ¡7Ké«ÊÕÑİaÑÅm¼ZFül~IBgF|29?¢Œí­‚šPè(¸ä­ü6¼„]f˜¶¸¸|çˆ·{èY†âÎ³Ş;;f'½:JP—!»ÜŞş¾úí^»z@®vÛ²À&_çã÷?»Y"ùß£YØªML÷}•«¹Tdj[İ‹ñ
³%×ÄÛaˆŞJ}@é8®úûíƒ“~§×Ş—²'çšB!ysùÏÌ•‚§Î ô{1©ÜÊ\Q——3ƒÙ¢€_H$á9“pëx«Y»˜@òßa^×ÓKÄ¨ÒKõbC\=g#¾7T3è*¥0mc¼@Mjo²ñ¨†[Œª[¾œøn­s¨}®´	VJ‡§ ¥ßŒ-‘…J*:$O}…W–çFšë¯²ó7¼PAç C×,$KçÂuÒæb.è¨!JÕm_—%OÔa±-ñ1ìN‰"¿Ã\.@ŠláİdµXıdyçŒà"‚Ü'™§XEuh92óVĞ]¶$fÓÖm_IÆ|7&‡Û.GÁÒ‡p0™Ê®–(Ú|xU¨d…ê•ãÖêÇŠQòb^Xwƒğ¡Tà%˜¼¡û£w!ìhp“Lx—64$”Ó¾”@;w O	íÈ4ÿéXt™Î*ìEğëÿŠ¹„¶ÀAœ$aÂòRID®Fø£Yo4õĞøÖ¼¥ˆî<×‡µBêá˜-¸GãR:aÔhÓ¨‹ƒğ½ĞÓã5Jã{ñKµ&J™=Â{á/à„](“wJ}ñšÙ‘Åy¢|·kyÿY>Õ7Z  x0Ü x‹qºfœÔŠ“=sfU¿Ä	çV%=âTÃÃîİ–~IÅÉ8¶H1>Ê.‘äà¬ál4İLä™bÛ¾ËuÃ¬Õ<t&î9)"œ5ÒWÓøç#qC×Ú)Hõ5£à¼<›]HVµuOkM»Zİ¿q¤`iƒ9áLZ[»²´C&õ¢sî÷iÅ¢'ÕŒ]ÓtÖ8¦-Ï Å†‡Ï:Ï…	¤õc^‹bùËo¤…ÙéêrzÄ]Ç5X|>×üUëĞw“3¥„5ó]ã²æf C˜”PY
Jˆïã8…Ši»-Ñ”ÒÌt›ª"‰d‚f|Â1Ñó*©‘™Ø%\½Ú°& ì­ÿª×ÒÙ™¼ÚåúÄ¦—"˜3­ÕÛYXµá¿Îø¯"cc¼G¢å×ÿ;Ê`>¡İÖ›@WwĞT•ƒÙ%(Q÷ÁÌ„²súõ³wÁOm® éÃª[[N×JZT	†·š™©L‚ª±V«´Hè¨si(7"EKèeÍa*’¹¥¶éòÏYgWØóÓ£DAV«£ø,‘V:®äõÍ}b³
ôøê7‡İŞ6•ÂÕ&\Ù`Ü«eÃ/¹ÆÂ¯:Õ‡~i›\)ó^Ù—ÔÕŒju6A'hF¯,ˆk4İ\%ğU¤Ê•é+ˆD¤‡y+ªkõÓWXôéëúp­iQJ¬ˆ3¥’Ô—´ĞfP085Ô/¤±'ÚzbjDñÍwåÔÙÍöÊVªÆo‘9#E—âÍ÷Q{Åôm?·l® rÍ‚‰=NªPµxZâçpëF=&ó#s†yˆÑŒÏ~„½N›ÁxÈĞõ»?RİJğ… 4èğïÒA\Ë†çüyŸço³©xF~³M>™{OQãdØä‚Ò>¡jÁ$åº(üß“P¼£Xg ,if½Ö’ôGş	­OÅÓÛÁù…ö˜ÇQÙÁÒL3íQEÆ¼èé[C25ã.¦#XpµiÆ_pÄKœõßÒ€CÙì7ØFùwŠy‘`’ñ6ş˜ÆëŸ¾GÚ£(tü6¸¿QÏÀ#
Üø#ü†Czª–…¼š0!ÅÓDÄĞ“œeêAd?¡µ?úMÈŞo6ñi:§ôw6œÅÍşˆöDøÜ;oş…,üÌö2`“1M
œ)IŠ»Ã»üIDÍ¦ZA—"i@S»ç“ö(’äÿ><‹†#êD²ï6Ìú9Û÷ï0®%„Ô@6øÚRáJZy2èo€ç6â¸á‡Fç1w> í=Ö:”+y³¶Yk}©—Å”&Ã+—«&qjJE.E¡;x•_sÛiuí Jº(åZ}NĞ©äNNMM</Joï+§uFp/Á”të×*ï‚˜ÂêV­qJ»”ø•›£”¾PíEş+W)`éQ˜Ÿ©®45/“‚›haúŒ€z‚HÁË¢œçaiPä&J1ßòC7çXìöş–C‰7^c	.™È	.“j4ôu^eÉ²FC­,»0/ì.œ$à@1–"IÙÍtËw 8ã™äY:k`‹2ÂX÷®ãÌEq>+îîx¶ê¼oÚË#ƒĞÂ=|a«WüTWßdDÀ¹ã-K~1ÒtACŒÙn¸0¾£qftì|MÍµ$S³Ç—h«(«0EùN½7áSÜ`O(Z²4’ßÈµŞ¸ª¢0•†½úİ;Úwr¾
+óó¡m>m
1`æc YıyJ\LLg¤+#M£™ÜUÂ«`Îçõ›éíÚysg–.ÎìTKåM4ÁŠ`í>ÅÛ¾z>ä5yhM‘å™%-QW¼ästÊµ2B/ä×¿ü—€æ-`>!t çùº’|TËcÚ;-ÇÎ±òa*#3œ™¦¾o-wDªx¼8"¹vÂÊß«;%Msâ9 ƒò* j]‰–o†¯l9¶.y™Oº.AU¥u—è/<å›w3õÜ¡±o„ñ»•h÷x_İ1p•vìœ"›®ôÈ™“¡qî^'w$Ü–ÉHµëÕ}á‘zíz/¤j¾hùÉ½äU“pV\ƒº ĞA ^+-¥²`=õ•ËtÂ¸p-ewç/™Á8š¦÷·Â‘™åğÏ¨Š»"ŸæâÊiÒm÷zƒçİò˜a¹ÚCR×1_]ÂUš°RŞ<‹T×yS°Eõ¸b:ùÀêCŞá$k¹Ï B¬ÛDv®Úìg†œ»ŸÖOë$Äzıetüf'İqç¸ÃıâzW³—µÍeÖ²EcYÓVÖ0••–²óe?¬m&ï3!ÔúåSİ_[dÔz½”Ü¸õši…‘«÷…{•½¬5€šš»>R.ÙÆo)¨Ëü±š×hg}7úÿ¿	à¦Íùãz9¼„óõLœÎŸİÀyyûfÓeüé«Ó½BƒGÌj“
–V±äœYœ8]*…Iæ]¡N¢.“Â"ø®ÚùËßÚ‚¹›u/CV¢L‡ÜòºÉ1iîIiŸtEÕªR¯Rç£¢[Ë² ³\0	ª0be ìÜ\,IÛ<ş³‹6ÆÜM¾Å¤33-zû3q¡yeª\®VÁ¢R,	ˆ	D¡ò×Ù…4˜;»4€]ø~?Öû¦Óeˆ§ÎàïîIïp·×yºûâÅŒk”·‰Ò¨øº7¢öÁw­‚MpŠm¦Ë4¤Z×e+Î"ñfd	¬9|?Ş=ş!ÏXgÛ«yèÙ\ÏP%t¨kZ¹»ÇÏ»„e¾fà(´|MÙ¬Íh³^NMÊp™$¹6%YŒş-ûoí<B ‡•5şbÜÙÊ¶å×µióèT‹`?ªˆ„µ‰:à©‰ô¡¿.ßW\}ƒ1TÒØ•o;;² Ê‰ïE‹r=íÎ¶L4dÒÃªÌ‚imùóëOkNUÅ’õ'6c•é¦å	qƒp¡só³NØû„“w:¿öèO(Í”Ö¯~£¶á#€Ş'-ÿ¤÷¬úĞÿÓã5ŒÉ =¯<jç9	*Å 8‰	ÄœÛ›œúu”ÎÖ	÷«.Ô_¥€V„ˆ}•¸¤>›ãPeU¶E©´ê
bÈ£ºhN…nÑ¤Új¤š/’˜çˆ\ß[Â.a9³s†ÀH»jGæ5…±Ì!ÉÍät¡K5Z½]@MÕfÜ×ÉWò:şÃ`oÙ˜Ÿˆ‹…äÓÕÛ0ß…Éº¿²Î¸Ãgò1'C}É—%Cºfiºùî©U›å”œÜİÊ`ëª5pyÀÅÌÈ—Ç:çÙÈe k$%ŞúZé4?Åz’ºÀ)ŸİkåŞ¥êGZ/_5µÉ”<,—%#oQdT¡rOJ³Ê\q0³mP¶KG¿·¸¹—ÆßÔå4I¿TÏ7=¿ùEz©ÔÿoÿSúlúìeÌÇÿl<hÜ¿oánŞÛ¼ƒÿyãÿmÿ·ëºSŞÉ®åû-C9	ôù=–!Øå×õ¤BÆ£8AxOpßµ÷Ú­ÕµÓğUcg³9^“»û»Çí‡<hÂ6ó°îÉ 3¾ÙİÃà-õY`ÿ‹ÜòèCYãëyR´-#âî_O^¨¶òï„YT>{9¡ZÏÆ\C¢ÃôI¢!ô5r¥Ú½HçùYÁäj£³—mtÌ}f¢™GIšİ²‚Àg8!”š@kõ6ÔeUY÷L…¼ yåsÈåêşº§ÄÃEKbÂqg•ãİÎ_ÙŞ!Œİ“Nû ×æÎ3aøI=Ç·¿Ğì”øıŞóşŞno·¿×9î¶4|[#¥ù‡y¾çD(òi™[ÂÃòšËŠÓì4{Ğ}°¹R«’wÜfNÀ#sø˜ÏQü>L†(Ú&Q8b‡#ØÂ¢$`@‹üPDfÙ	{í'İƒş³ãC¶ƒ½–OVı¾>9~—bh¦¬qòªÆWXµíİn[ûJòêIø¾?#„ş(C(K-‰’-“¿º7Ô¿½Âmxm%˜Ü†:PEq¯İı¶wx´îíõú‡G=-CİÒ«åÃ"“I˜Õ³ 6;gµ³$šÛtµ6Í‡²¨j)ƒ*=»mÃ
Lõ°ôM•÷Ì_v¿Ûµ»%ÇmRù#ÃpT»ˆã‹Q‹z,ïê@…Ç)Š+/q!‘F*äÃ[›››şxŸœªò¾Z®‹)êy«á$WŠ^•ÊOš÷kZCûkç¨åÏ­}WÏºù.1ŸîëÎÈĞ»_yhsA°éEçiû KŞ6õìùBïÃ¤>ø6ïÊ‹({3;£~üqo%–ÉhÆ·[xQÜvkºš¦Å~û¨O­¶ÜhXRE´Bğä	/š¼­*å'ø€^è<‡õ¼f‚\Ësq `XEek@>x›å–_ğİgµÅT”tõR‰^S{Q7çĞ»PÙláµP×|ñYÂ/)hÚ›°L²*LîÚ=O¥Õ?¢WTc¢$vîÏ„`V†*'O2$‚„ş)–P… ğµ?åù¢È¿åÏki::“÷ƒŠ‰¾Y™.0ÒSQÕ8‰Îf¼×õ¤Âi[¾^[¾; SwEe®¥¤vÍşFËÖv‰ÚF­\X´é»Ií<	CnqG-OR½´iœj¹|ò=[‘ĞÑ‰âjØ8×®İF°.nUÃÈ!ï$5dï4ú±wVŒîjúŞº#¡ê4Ì Q{X£„¢a»Ã‚p'pxQM»İ>ªÆ‰ïÆ&¹Æ`òÛÑˆ?H-pÔŠÀÙú¼İkáUÉaW½	]V:¨«C.üßÿæ™ì ŞğÁÜNÆï>“ôÑÑqûYç{B¹_¦L«ÆwVnéºñ+¥êWR‡·Lêå*÷Ú\…¶ÅªÕ`8”pWly\‹3 ñQ:;ŸŠOüK³ª¦o¯„‘Å\ºÉÂ<ó?W•Åk‹¸V…¿d}!Q_øé‚ÃK½ı®êx>©) =÷?gÂP9n?oÏ¾Û=îà–Ñõ¼—Ç}ãõñ‹ÁÂ'üËw¹îÑ‹N¯×Şƒs¼ÖêGÚ÷ê§õ:û´Î#v{y<Lxi}ÑtØø£³FırÀãEöv(õÔã4úp6;×>‚(‰›òÖÈEÜÈC?di&Ÿƒì­rñfP•%áÙp1še›ù}÷=4óå³¢åŠ$j÷!2AoÀÈ0b ÃIßg›Mø¿I0Iasê7±‹!ĞÎäÉM”s'†ı3ø†§ù€ö+Lø6TŸ	1Ğ‡¯Lp%ğXã‘ø!ÍãÃIfƒ7U•!R÷»±I<©bk}‘Y5MŸ+CØ¢_½z­xÒ¢Ã1·»1Å09ÜŠÙw®E¹m5uŠPV„…%ó<å[‹:6½œdÁ‡mÎj×êºPæ˜¢ÓÌş–3ø¯2çL_çîmIğ³×şôJÜv¾¶xù<ñI
Ù©ĞmÉêçÌró"æş:šñN6˜5¨€¬üå²b“x­ußŠ¥Š8M˜†ö*Å¿ü}qq*Yy½˜ı8K36›")$)9bŞmÂyA¹)azeR´Â‚wA4"å\˜œ°T××†åÍïh¨p÷OBİÖmÉü¹#¾²R1ŠêÍİ£ÎZŠlÕ0<f£¬¼9i”_ÍyÍ€FÌ3=¶}{qíq-˜…İ7ñ{†ñNñÔúaöÖà¾¸…ªÁvAìeÖ…¶î˜æ¼IG«ùjD,-6÷³šœì?iÛk5ÆÓQ+³Pcâº‹Nl£Ö¸_kÈÂP”$6A²-q†ehi±é¿üƒ=¹”ÃNÓÛğ1ı> 2¥ïèoö6åW;%„aÕ(•©Â!|Í¸;\r‡q
Ã[²·ù;ëœc,HŒPîRON‹ÅÖX¨¾Ü{x”É–ıàƒ‹hĞK‚i‡¼^Uó¾DÁÉÒm@n¨Ó¡`xÓúfót™"h¦,-89û¦Õ<î~©´StÙ&^G][çDğHk_‘Ira3¸ºFÕ¿T4§r}’¢¬:3Ä0%¢ 4?KDê:;ú ö&rÒ…ÌÜ¢lKÒ¨T¯œ¡šLË­€£«¹2 …š–¯Õ=_a9í%‡¯ùĞä,—ÕŠH~ó!ìe›ª4Á	ìwôØ­µæŒ¦.Ò,´ÔÖÚÃBĞ‹^·Õh|…ëJ×ï?n~¿ıa<Hë_´Ôòxpï^‰şı,ıFcëŞ°{7ú_küºª‡_püËõ6¶6<°Æ¿Ù„ér£ÿó~wîüÉY:İÑÿÕéíÛuş‘¡BÛ]°ÆCVLSü×¸v‡Ü€L¾—IÈ¬òïÜñ¼;w€d‚§GÓÇ`j¦^ÄÏd˜|6Îä]UuÊş<ÆBºƒÃ£n§»¸ “+)ÄÂ_=J³$\<æ‚’Guñú:BºyĞÜÒ®å)ªUG³h‡qfÚÕ]”Q’ƒÆÃ¹s@N¶Ø,k¸öÚİ§ÇêsÄÄÏ˜‚ÈZ±A<£ø ıd2$óï¢·ÀSõîâ$	fYŒ¾§\ß]fyq&!„Œ`ô\.BÅV™0,PÛ>	•ÙKîæO¶OŠ%f\ùÈŸÀå"B¤`õ’˜$Ë—`¾ç©’Àè²¨ùY3eiKi†Æ¼(
@È>ã”fà˜šRşã–¥•æäšÃ<Î_
B³gjr©M)7Óg£Hœ±õ’™Oêlé‘µ÷WbÖ½şùçW"“×FÓÒ£
kÓºÄ,yñhÑPÁVU¤ÀÇú,>s7R‡è§ºŒèGe*:‘åûÇ““ç­Æâş;Iù—M	ó.@µ,ÍG.˜\2RìÁ1Ïíî¿M±‡q˜’7ªA<›d,@_®3´ÖY/™r]ŞGe=»¨…øŒ–diKæ§.m¿È¶d¶Bd1I;\ÏVÃ'“Î¹òş@#×€ú‘Öa¨1r »pA#/¥Ãx)…KX¦¸‚x‰¸­ô¾9<†BEœª{Ì»áÿıÿåxÀkğš7üßW}¥ÍñßÜØlXã¿Õ|pÃÿ}ñ?õ‘ĞAŞŒ¡#ƒ«©õ¾19ª‡Ì×Ø@Ÿ‘FvSø)QÜ–dö|¯Öı†!ãæ™gĞéÆ“H6Ì3ks´˜ÅZ?á¤Ìéùñkzä¾c
æ˜§b$gA"a+	Ç_iRE¢«ZVOù	YüÂ©cã{N£Ÿ5êÇøN·~Ôè;'ò>'ÿc²?˜Ço`~°¢¢=«¿ØÊŠÁÍ¼§È¢÷=«+Úğ–°$88Î~j`e÷¡¥Ë¨(‹ÇĞ¢C†qË¸	-ÏS9 jã0ï²İàÖ©ÃÁ\~Nâ_VI’ÔXÙ4"­ñƒ ôÅw¤¯é«¤è±i’u,Ök“ï|Zó%§Hq¨„ø†uøÌô7ÕJà­¶k]ÓF]œ1ÍÚJj†´±wu²˜“¿œ(^@óÕFô°g“Á·‡ô¡÷~gã ¡bıºwCÿ[Ñÿ1L4äA~.%?³Ÿñ:`ü¿¹ñÀ¦ÿî5›7ö¿_Çş—f´ÍĞĞ³ãğo³0	qLYÅ#¹ÈÊ£³ä1ê-¥–-ÚhÆxlÃï=çñh¿&°#ım‰Ü¶Õ!È,1ô[Ûò;>¼®<EQ-†»_0ÌØm:Ö¥K¶‘ÒŒ{o}°7Ixî4â»œÜäˆÕ¯ç{«ô[&õ³Q|¼ä™ÔÛ»{ûm˜öşc)æàŸ””ãQ=x‡êüœGƒ²¸délJØVÃÚ£:´D4M”P:‹FQ&Ü¡Ñ
s5r[%T=PÏPNÜ×1«³=®ú$@ğ~FìiÙÈLxNÃÉ_ö¾}ÈvuE¼CQkdiuGa™ô¥ú°
ÿ2¡½nd™ûwf]ò@¼lŞ¨­+süåì—¿Ù¤8OD}‘DMB$QQmrHhñ?L‚”‘ŒäâÜän’õDê÷BRİ"šKQmcêN¶–"½4†üáÂˆËÅ[Â<\‰àS]ü	t£†ÁT“›ku“Œ4*Wƒ^G¸*ÄŸ.O‰Ši81Ä«¾jjÕ<S:4ù„
ÉN(ÔdH†íôHÄ;EÍÔ[úLÕ2!Ğ³ÒØ¼†B¾Ænèƒ­ó?	‰JÃş'ŞçÖXpşonnÜ³å?›(ÿ»9ÿ¿ÆùoéÇ|0Ú€<¾ Ñ‚½@Ò0!ÀY<ËØ$|ÏÎÃ ›ÁæI[ìÙì‚‘\ÍóŞ‘É>«²ÃAŸ…É]R#ğP9““b«<h¿ìj+f#¹Cu&ğq8àAPiêüfÛìQ8~¬sZ}à«fÓZúæQBônw8”»IºĞX‚àƒáN0ÜÓScgœ{Í9n•#ñ	¢?äğü¡¶É™Ú&©ñMhü1ğ³¬Ná 8C)ZY/<ë|ßŞ+é†]²5e»BĞK[±‹Û] AÖøã5zÑ/!—Ú†ŞR˜C¦ŠFŸ‰Ìš]‘Èõ4WYf\­QõC<Ã1yOÄ“öÍŒhÂùİ—·¶yòò«sÍG:T8Ô”ÔDH¾øŒ±üòès…àRCb™Ò¤S:‹#à7*„½	ÆÀQ-ĞFõş.hCÑk(ds›j±®×ˆFTyT&”™_ğÎ™“€üŸU%ôúîñş»u1ŞWK¥9Òé¯iØ$ó{ú¢ÃöÃ­yR{©c¿[úØÿb´3·&9VÖ$ÆŒ¾ú”ÀŞ¦~ÖÚ5Îû˜=¡É$`;€j‹öÜrÍ…¡ıà’56´™°ôT8!ñUj¹A~âa‹ÁV'xÆıÚ†{¶Á~Óxhwîî,C^qD$Â‡‰Ÿb¶×è¯èSn«Ôâ¦+d:RârÈ×âN{CÆıúï‹]û-{ÿ·µ¹eÓÍû›7ôßW¡ÿş}ğßrø71Û¯ÿF—h‡¨H_Á'
±Â™¸nêäyn›K¨Üşêß0Öİ~,­y[…*ó:ÛÑŸëÆ<ªô-N«²—ì¸ß;ì·¿ïôòÏˆŞ²Ûı¦åã¼RY`¬Ü–Ø«<¡ö
ÈÓêwæ$ôr'{G/÷ê«v[4¯zîêc2(Ÿ †1V7Ê>ï0öÉ;Ÿ"Ã•wñª‘ØQq/%SfE¤¡A™“7!‡ÓxÄLÄ9>õÂñIcÄşgšS·r¨<rlÎ¡Ê¢ìÜş§oÂÁ[4f\EP>í‰YsÆ£'À3uÒ.|'ÌnÇCoI<›JìZJ&ynY}¾«Of£‘§@joi(µèŠ«8í”j*ûÙ(¸àN€%<Ê ¶Îûx±ß@èx|M†­Õ¦'üc®âÚğe]üUÅw×È]!UL#ÿFknõ#ş©×U¶õO¬"İgñ/SÃ'°Eğ»¼Ö\±ûøµ&î>°R¼‹0{ËééşæëÇ3İ:—áªzfUá…KÃ;jcÍA¥h¸n‹‹ğu¢ìæ#LÕˆiùùE¹zG-*}Í¯ş©´Ô#„Â
Ù·QÆK„÷·QFeNß†Â'ïØ^§{ôb÷‡Öªx`ßókÍN¾åÏìúõ“.ãŒÍî^šLS`-R¨UÆµX.ı¬rW²‡_Ê£BºŸFºÙj?¶˜Z*f)ADâ”,Y¤ŞJ>ä4È—‰UY­7y³9êºVú(*KX²¦¾Qµ:)®óã8Î¬ãÓ[ÉW¢˜°¾˜Ğf˜V;_.f3†Ùß>½æqò}Æ#½
ZÈŞŠ¾B¨úĞŠUm`Ù™?‡ş¯‘0¤ÿÙ ¢ÿ”ÒÿfsË–ÿâ•ğıÿ¯Hÿ/ë4Çö¹ƒ)ã—ŒßÕ>Ë¸2¼$—wÙ¼£ê¿jÇÃè\ÂRº3ô©fµ,´Eß“‡ÅDA*š’åd6ñ*zqÂ³j•§†£hŒ~1ºaD}¹É¥áè\é	É&GCˆg–Âéo3y§-“Õ¢¸şu˜
/çtªõ½€a¼åØå¦ÁDÈÙ	üF•à”ĞÌˆÒ	¡gjì´Ê0†CßSâ³ª3BûÍ®ü5÷ÿçÜ#az8¬e²/°ÿÏ¹ÿÛh6mûßÍ[nöÿ¯ñûZ‹º=ÛŞJƒÔ28ƒ~Aº¡í­ôb¦İ%ÂV^³ i™ÈR®Ê]ZFwÆ¾Y˜7¿›ßÍïæwó»ùİün~7¿›ßÍïæwó»ùİün~Ÿé÷ÿ E´ h 