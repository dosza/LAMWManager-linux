#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2440041046"
MD5="7661d5ba629909705ebcbe0803bbd9bc"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26608"
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
	echo Date of packaging: Mon Mar  7 19:15:29 -03 2022
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
ı7zXZ  æÖ´F !   ÏXÌâÿg°] ¼}•À1Dd]‡Á›PætİDø”/«,(¨ÊlÚ‹•ÿ‰Ú]8-&h'Ì´xEÒkQzùƒQb64pÌ™øq#gFŒ1ë®<”aB<Õ‰ºch‚ï"¿¿PÃbN¦…93Îl´á­÷û²Áğ”‘ˆÎ4«Í<íÔ§äºmnå:bk‘·)Nù÷±¤	‚  òàkÊhòı¹­¯¶y6¼Pàb'ÍÜXqù}­^ˆy°ã<»–š–àuÿŸî ?¾-WÑ¤¨ Y;#ºNÆ‘õ°¢ÀÎJÔU© íLoB«ë‰¯id*·áÀ!XjŞ°ãH9Ï`Y1fÛÕ£¢Ø¹/&gÜ×sÂàqÉµfÙÂëû0rNƒ¿ı½x—ç	p©¹­˜ùığã#Ù‚y\«îD#%NJÕTyxÕ)}Ê*µæÚKÔA¤9ƒ¶e²q9qË™ÌÄï„Fgÿ&Å€š¯¸lXîŞ•6Jğ;>®s^fçØ9¹dd<ô™(RN’&ÑÜÒo£Ù{¾¸
r1Ñğ¹b;.P”\%ªvüCœ9í`¢ØCµrNJ‘S Šş§{¢G´¥ã¨éœ-HŞ.²ÃùTêÚ*1²#xŸÏI?ãurNIj†‘%Æ(§’Ú©˜$)·È]d)	1È)ì™‰[°«²µTøÖ 2lšªWâV˜:Œ4
ï0¡ƒÅ€x¤PYtô×ôöÖ¤ñÀšU¼ÚTµ_çtOX‘›…T´á*Ü¾Rı‚Íy¥şö\;ÉOÏ$0…'Æ(Àºà€¯<æ'”lhL¬[Š”V³aÑ!¹—;ò‘hçpù_Ù-ÕN[ÙsVfÎcV§¹;XĞZÑ’»ÖI­	İşô'½A®Üµwà*¹æ>jDÜnqS-0u“ò…,¡Ü¡syÒWUp¸©’)µGö8šeŞ¯}–ò¤q Fv¤€FLºKyMş³í'ç‹ØI2TÅ›zˆ]UU¤<L’o„ õo&ÇşfÏ!(3LÇ°:½‡o×ûæ=èj×#‡`lùÂ»ÍÓ>²Î8q_ÛO9¡Ï·vĞçU«…òÓ ù^2=ØY“Uo}ÆÚ3¯ğ[†,Ò+cmkÖ`N’fm.tíß©a‘êî©^öêB·Rî<<‘‘ÈûÔÂ®®ìxKÀ3]’1‰WşÀkPâû¸§ã:F¨ÚÉSDhÖœjñ1Ÿ!Ò9šùÒûWıè½·¸öpèª‰OºÉnêì¿ à¯„V?å<®2|ŒTcd¢£©¨Ôœ)íuKˆILê”åšÁ{ÒzßoKDş\»X½Ù	«}›9”7†C`»”óı$bäˆ€°½ fªMT¾eá¦7	ºåŠŠÿÚpô¿^x(ìı^«Ü¿DÚĞˆû‹ ÂñZD¤rĞ»‹¼‚yD`„áià¬|h+U*aˆ´FÚÈçX>™ìŞñ“-aE>;ø`8š#ª³;Ã|%›<Ã_3Ú,Y^ÙFw“GY}£Ÿ­wÉ¿|>±¤Jé0æ/îğ
,¥Oëø¯AieF›øäÙ÷-2üx»Om!'m…q:R¬Gz—¸Îôæz±l_Nm)‰^ÊAÃ£İ—ŠÂË°¹î+É˜<$AZ×Œ#á+h‰R|NÄï|ã”b‚Å•áÛíe,P¤XÃ¨ìĞßYÀ ƒy3ĞÔœ=¢¡ìG¿BTÈ^¡Sh0ı‰ç'6Û1’pÒ¯Ğelì?èRâ€êH,F"À®>«˜ÑÂãWëO0©¼gåéùq£e4|k—¾Àë°W°XJË× "J»7À%YÎ&ÒA:¥šlµvÓ7¶ßZöÕ	Á]ï=s¹q{´ô`ER
0ñ·7èÌp ÍH«³v5–,[6ğµĞ2[	;P%4yÁâ‡ëf°ŞÅ¼l?œ(öáé(Àôïš9½ŒÑÑç†§2Ü(ó­d$<Ìƒj•‚İA¦HĞIãÇ•fŒè-úoë÷lÅ€IKİBÇ¿Ô.+Ñ]Í–ï&ŸCn>ğp(û‚3÷•ŸÅ/*„Yô+Ã¦î–Ëæ
V_ñæªÚä“D¼7jRâ‡Û~¼åÍH¹y‰¹´&º5o$*¨½Q6Ãò×Ôngo€—/gø½JÅc;Ä!ue’½Ü¢ÿ`Òê›|2ö¼Û„¿#u†E*¡FQ¥(ñÛ•ğ±6tşW«Èçœlİû
¶­U,w»™ìëÍŞ³Ÿ ÖK;B1úşÈNPJg8¿X1Ğ}upâ„pEÙ©1±í}ô¯¯+Ìas]m÷q^ŞTñ•ÖD$œø§ÊÆ•’zÈòqwƒk-¨î· ü–<õ¬k éx¿NHXÔÜ]VëàZWÊ\.pÅ„æ´ÏKQH¢ò¥®Jd7O)fk*›rà-¼“aõ¶·‰f‘’[Ù¢¾7µpŸº_ın–]Ö_ÿÖùŒíPÄåE€ë"…¼tŸ*Ç÷¢¬V-u„»Ú°1oÜ+î)L–{4Øÿ¯¹ .;!I|fNğw Š˜Öá×q3*İyæ¬gÉœ%KÓğ@`‡¯cbåb¢ô¾[XI¥{6øv¯îÂO^²s{~G>ûƒwù4Bä9„AKFf‡pht¯ƒı2å°ĞÕ2h8‚*ù›H¬RMEóø¾87w/±ö#áÏˆ”©UÏ‰7¥ñ{ĞÇ¯§›Ä‚Nš–VÆó³]-,ëv;§)m½Ë€"×›[”iÒrŠé¡ß«]Úã£5ØÒ+ˆŒÕpSg.¿}/ş”.`WÏ´,å¾ˆ¢^Üi¾>“C÷» @Á8·p(®Å¢’üõ3 jæøÛ:Ğ2:İÍ.¨±.h»]“ê€	%Êè‰°5lñ WßaÑ/9Lïş£C¦ÖóDe÷Àóx•T8Ëíßä4ıšˆÒô÷µ[ZŒ,^¯°•5¶5yM*DQœT9¯¨ía©Á±ÃÌ€ÔA ³—6–Xºå—,e‰¨6ÎPIV¼zİ[‹–~XÄêb€[™-ÜQú2ÄûÀ;¢Ÿÿc»5£Ğü«K4¹ñrš]œ/Î/è&=ñ,YRdåÓõñÛ´‚C.†˜ÿYè;0^„óÜÁ çÅ\ÄıZcÕÃö¤c×QHŸZµ€ÇõıÃĞ1
;WÎbÿ¿ÌZ'}³6¸jÙˆşR¹ºÁóÓJV¹¬¹­£sÜşw,{Ã†+W÷À[øBn²²fâ÷«1”¡n¢õwÄqê8”YJÂâ¼ã½ãººÎÛFV[ú€­±@q¶V]š}jb¦ù*Óªü(w»Çù7ß4·yZ^Z8;th›_éÈ˜~aR[ø„>q@ÿz« îõPû³€İ=[<êb)!uc~J$/U[Ûû¼¬*‚Š&bl¦a`›ûsB>8õÔ@ç˜†N“ák£°túUS[kã6@›:Vÿ‰s­V´f'@ Õ}ïàó6é€àG:L»ùœi|È¥•ª.B,SŸª‰%!ûo×‹e5¬•ÿ`K“ ‡À¼µ.y ç3¨£À3ŸAßÏ.á`y:æAUÑÓBÓe‰·€®â[rOIR¼øŞ~\jâ¬W3†Ï²kÃf‹Ì°–Rs„ï¢‘goÑ€Y ‘¶'âğ¯©Zæô YÌêİ’!#LçŒ,F›J°|ûü‹©ƒ¢^Ú˜;¡±:ÅpæuÆŠQÊĞŠ²Õ_“;?Có(>ùj2[Ã§ÜQA·|T+‹:ÔÔ¢§ß„Š“Õ·t9Å'ÂUªæ7šÙÊÍ¤w’®™gÿ›{øÕÚ'ğÊDøà»a~„ğ?¹lTc¡BÒ´+ZJ¶záÓ[ÃBÙ¾JÕ%FKªC´<)ıZk8r‹±z°r9,”tçÉG SV`dºÒ¡ú}Œ¤|“‡¡ƒ[À£UN<N²aazé k×fÄKß‰“Ö–~¬WÓÈÜéUvTÕ`Ç¾¡a3Wê¨xü±x9ıÄÊPSÔ÷è€“”cAë„¼F+ĞïF…â¦®IçİwÉ$Ëº—íO¿‚Ğï×z.ïá—óšà$£-ÂctWÙÒş?¹XÌôŸ©åØE`BÇ	y·¾”7Å¬ûWÄdş[¿N¨æ2Ì’7ÌH×‹~³À‹ŠèóÖ+LíïÊ1½òİ3&)é‹&ŠÒä^Ïz
AycAå\1!Ù!Ñ×ë¨êÀËÙ\ÚkÏÕ±~b³1[Vá»ïçM$ğŸ¬+¢2õ]¤OÒYÉ›CšÊ*L¦‘ß+0È¥h Öø3,¯Oºm¾ßuÚ	JÑ\-‹ÀÇòñ¯`?NÍ-v«ëeó)ã¬[©-5®äSÙtG‚Šzà›Š†aÜIQ:ëÉd“¹P¤y=G™]á(ÿñ|Sı¨¥‘oº¬ğ<["ñ}=4eö*ªÛİ|kÒÇ@íLåÁ§§şè:)áo±ÒÂ%sÃI*S6ç®¢fğ„6È(mıAÜ ïÙ¯?ÌëÕô OİæÔR°¢Ëûm¹L©Jï©X,Ê¬‚AeÚşñGo€‹´7ÉbWy1Äˆ,hÃİ(ºŸ×r‘»e(cÓ)—"ñ4RÚZóÕµ§#^–m3¡ìi89è:%%†Õ6sTçáMÏ›…Â#/=DéQÖi,i!’Ìe÷ñ!~˜ªöiÄ™
M€µ¶ÖZ3@J—™AÜ=í'ÍMmÖÍ(Ë{ömô9é`5ô=o‹ÏnÒ•ïM„âãĞELÅ®ND&Ï˜¦&Ùeæo<i—ìxy’Z&’ÄİÌ×½s'»,÷&‘Špû:íğÔn‹IDÕâu*;I±t*MÜÍI“j8wxe®zI“MóË«•à–oriÇ¹@€IÿmhW l„˜3çƒ$³Í–&­Ã§>Phú•K8ÎÎ›p$Áğ¹ôn ô˜Ù2*Êåß¨Ş İÎõ}cŞ,ÓĞ_—M!9úÉŠİc e—–Ëşğmçµ3byÖÓe‚¹«'›[4òöÆDˆ2MQ÷%× ¦q~Ğº³ÿ»ã·"£8	©õÆ¥ÀàCZ¶úkÆBº‰ZÍ p‘8˜—÷}¶.£îQS÷ö$a[îDî£¥7£2IXİ´‹–©±]F¢ŸÕoÊ¿M4í"ì©üO†ïLĞûC}%è¹$³·'cdòşd6T¡ÁF,nïşbÍd~©_Ïplƒµ6\İPšË.ÚÍh4 E0$%2+iš„gZ‡j.qÊŒÏ%”L…Êø6)$ò1ú¸*ÙñÁf19(œµşÇ<öËKÒI#G²Í	ó,ËÎ"Åªñ	oàÆğD‘!œø@ÊÈd3TÈûOfïjÿ4ş"÷;V—6b[ÀpBÅSøÖ 8ô¥{ë)i›ãŸÁ|èà<xë„<Õ#ò¦ŒßT²ÙyÉæW•å~Pñ— €a…ËkåºÆƒÕ«¥D£vÂ>{™¡ŒrK5İf7îç\ä.(bù¢™zù&Y‹	€AkÄS?J9(Æ¸ë-‘½¾8ºEDÿ êE™`AŞJ³ó÷‰ATuílÊXÁ¢¹{<àwˆ°ÚØ§Jx“l:kÓ),Á€b¾Öo nòeö\?˜9Y¾fô>¡u/ÄÂÃÍl°¸26W»P wW€*´41q%Xùİ öæ¹—Ñ¿ÿ‰½À‘ş–‚åƒ+–âMÜPyyÓ€ËÜ.„IÉ€¡{·©CŞ‚¼¹•%OŞæ¤<Š÷Çp¸Á[(=¼. ÿCK¦Â£Ô«Ö¥¶ÇME_úÂ:²[Û°%ıKeĞzÿ s8e¡ "î6?TZ6íòê›ó”e@t‚§Ç^8¯v5Ÿ5XâÔÕ[ÙµaşîXWÔ!îu<¹eUE™¿?iéÔ[¥tyÏ(ºF—í„›]d†©ôÚ,—|zäV!
SÌ
-:ÁÔàD‡àÚà ÓÖÎ8Í=ó†?‘Ä™†¹.u&á}¢ÉìÈ`…çsbI;AXŸûl?ù;ğhV–NR\å—/Ã¦¼HÜí!¾6Ö;×ï
{úĞÓ;¸
UC—™{ô&<§ïÓ_Üåë	ë[ŞÓ†£'jª€¹õR¹ÕãF¯{p&ì!øßŠ²½ĞÁÌÜ{Öä;Ì"}óæÎÚÙ”]›RYìĞ-ÈKôgZİ³‡È;jïf˜mÅm‘~ÕÙ<ÑØó6Úyiqü¼V3Øi•Óğîpğõü%”Äøšı
ÂlºBõûâßxg¡˜ÊV”ÓNa$#uí_M 6Şí˜üEU(×<±æ™¦Ø`’;æyğy  ælMw#·LpeÂØL·hz"B"Ã¼‰-¿Û rnS¡¼®cŸ~pÒâ
B®Dİ6AEÆqÿ>ã¼˜˜¾Ë’ÔÂj)#±¾õx•k«hÛ·'x$‰\` Âìu¶ÌĞe•¨@¡ñ=ê•4—{3Ù#øB€Äê: £håV
…œ@3“9E&½@G˜ŒÉÒÁ—Xi2èTcÁõ%’Fo¹eÖ–«#¤¯Œl}ÑİmÃ†KG!^j„H|byíŒÈH×ï: eÑ‰±Véğş%:¾èÈF°ÔéAÄ x¡pÊ‰OsõàÚ#Yé´nä…¨à›»&]Öfˆcğ¦kñüŒq-¯¯“¸2«„i¡ÄöÙ¹ñ¸ëÑî€ª©ìè!æ½O—öéÇ'#ìp+Ÿ¿Na\=Èë	")Š“¬9óHşCzjv)ÊÍ+HåJ$Í±Àû¯½‘ß–ÁßHóñ÷›¯×Â±-Ó€!nkÇ‹Ÿ©í	xİİ›HLr×`²¨õ­’0G2Át»Ñ¦ú<³œ^ åëQŠ,–ê¢‚¹€s2k×oâ´BÃ@;ô¼ñ Ô˜'>°åØdÕË)>Éá å¤eähoÄ´&“!â „İ´SÁ”Ãú8$¸ -Ñ±#úÉ+AêAZË&½Ab_ÿÙ*¬;Ìh#şBËDÁ99¾û.éf[<JOÜF´•è	›'aÜLúsÜÓ¦V;xSğ¸Ó¥Fv à¸ÂÀ¡¬€€×SşægõØ,'S†bĞyÀ5Ê(ö}0)¸‚jB‚ÓLØ	=ğ[y}Ê\J©eÈm‘Pù¹5ÁÑ¶°äºWŸ”·'âáğëà(¯4¯˜;!^@ÔN9±TM’
¾¾C™J—ç0úé°*Ã¬ø™Äøf}
ĞèòW&Å®BñĞ¤g’øfm6·Añ ^}æŸòz—wö+Æè#é6FK0Ù-~Ö–w/"}iÕ"\z©^oşÉ./5³Íş®òZ2Tä„¹f\Kòj<ïÅnGæ^¹Z²:Ê‹œÔ
º×¢Ák˜¼<.VºY:'=nFÑ6Jl•R>~ø{Q½›§EzÖÆfãó½)rªnLßeUˆ?@“º¸b¬;>*C˜~%'	ïRækbkVîÌ›·!qA€saŒ-ï½F˜ÿ|Á¸îeB‘H†$ˆí¡Œìè#Çæ/‰ï‰Éğ;Šw¨JË]ak'XZºGâ¾
A} ‹˜È‘™•&åÊL¿éÜPäßh>>ìºÆÏ¶³Çb[4æ.&B,5èß36ÍkS°ˆG}’–;TÎÙ“$‹JÅµ˜äì©P4µñTD›Mò óşê¥(Énz‰½ª—u†½9œë>£+“¥6‘|‹¾»uµt‰´Ã‘º›UrJ°%²Ñªÿuò!!A|$-æ,ú4+ûz50Ë+«˜`7ü†öÀ)¹+/3›«™(õBäƒh¸Zcˆá~ó|H¶P~U7‰ñ.qÈ:‰_¡×)9ñ_†4ÜÊ‰ø¡òqËö…™eˆr®ïÌ“ 6è:ğß[´ÍäŠÙ \Í'ŠQÒf\"Ù  è^<râ_ßÓp»[:ôæÚ$ú“ØÈÅPó|£=v…Jáì^nI-š)*k9_…¯•vĞ§#¯‚ñÁ2Ÿ'<•pÖ£så(X8-°«pd¿†Š#¢-a¿#C€À0wc}f®f÷¡f2\ îa[á	/âEKHy=xÍåì†:ßZ¬Ğ–×ëaÇ%€N¿“8`!L/n@+11Z©ZzJ	™A²SÚ[A]“¬§™„Ä$D¬È«xe<7ı%ÁÈPôş9öµWA;ëÙíte´[±ó`+öH.#T™úZ=–¾í	)	pÙ*¸©Ûe÷õîd™ZzÁÔĞÍ³sÅjmBÖòëÆDteE†mgîÜÔå³ÃôßP5bÍÃ)¨ †Ës…%¯ŒãßÌuy„İ)ä6ÍÙ*¸-¯x1Òhôoö>¹¥ûŠèÂ¼Õâ\ú„ëÊF&UToıZV½™áË\‘e/Zµÿ8e­%ÍGQËX~y´İÓ@ÈsªË½“0_	WaA$g9n´=e.¥å+$©‘ÔÚÔ‰Ğ1È——É–ÄQÈ]VijJş€!Ü¥vß¨½+š¡@èh3Å½FF%ZÿGæÅMcø+Uì“»ñTÅ]¡€Ï‘Jµ@vnWLÒX5lODÖqq
’ç¦ÜBötùp	pú±Ô'sqÚ6°*Ù¤ü»YÀEMò‚³Ù¢% à5#¨Â<^¸ Nß–|qR9PXå§]PYıt÷M!q…eÍóÜòó}1X0=
k} ´§¼¯ÙJ*ÆlÏ?»õx©4ø”A0ÌA£¦|^7]äÓ¿à¸E˜½Î§Àp¨%œ^²+d	hgÔUyºämÏ4¾‡üä9ÏFÑ›Rÿ”–l[„¿(¶½g,3Âãõ®÷E”‹ L]Ffo:)#ÛX“(ƒ¾æõŸìÒ.ğë”µv~éuÒëQóFÍæe¦;‡ÍR¾/]ÜˆÕáÜ[*d×£™şÏy°ÊycZ]¡²_­å4ş=Ep–˜ÊŠ%ÀóŞå¼hU|†Ãõlµ¨™3Ï{lw5Íh(İ4"$PFÖ—jô‡L“ä?Ñ§Û;~QÉ0x=ÂÍ+åC¦cÀY]7;»•¦>·ú©ˆYÊ[šèóÜ–“€ƒ‰¯
6pŠ*«kÌ]¤Ğ‡š-®'X&,Øƒ ¿$ëc#C7Y1]Cã/»B’fônA`+y+EÏÜ»îéµí=¥îşú$æ” â^ËÅÏ¸b:®Ú¤­tYßd[‚7Ğ¼S¹ê|ukYø3K&d"@ı´øoÜUYé[t »H1µĞ‹£hÛ±s€êó¸;X9q?3•T«0©°~°yg‡I¡5}ÃLÿÚ=îÉ:`­øgÜ‡ÅXgòÉ ±‚¡Á³¼ÍişìÑ/mù†›-=—åÉ|©Å8Î8HˆpÀ&ÄF›ÊU¾r9ë’¶mÒÕóÑç¥·çzŒ´yãªg@[ˆM1o[æ#ŸºTQ™_Z"ÎÊ\[hÂw	’,ñwï…:â®Ä¿—bé‚@Ÿ¬»ĞÔj—ƒPÉ™ê
£ÚQ­Šg£3ŒvªyñÓÈrØ*ÜhÃ¸¬F°'øZd©¨">WvôOLsŸü#yü§l:™}\ÿ@Õ‘º«ëe86‚Ï^wJfk0u›5£Ãş}š2c·x<1sSõß}ß”>'¼¡r"‹:n 86Ñï¸%Ïq>EãĞCÓhF_ŠX+G6ır¥>/{@V·âT%ƒ¶å6l×2‘¹œ&ª$ô¦æ×¸e]0•ck"ÎÈvb$¿oŞö—JÄOÍì´›W|œµºq`UºmCN‘İÑğ«‰!!‡ù¿Òâ1Eu°b“föDçÚ€Ğzd
¿KfP-ûL3P
UÎÿSDí³zpzë‚Ÿ¯gıbè›OùUWÌXYùŠ9PìœvS<ñ¬wğ^LÜs¤ñjµ–ÚAÏ§ÙìÎ¨ÑÀkQÔ‰†rfY”Qó¤Fw c¼E	¾>¬FeµØ³ ‡·UöEÍ£IL†´PH7 uXûèğ·‘:ÛFyj6Õş^¾»Ñ¾27R»z¹kn›¸Ù·1±5 š·(cÆğ{§.´lcÎÃWÂã? B4Şdš· ª-ş t&^ÛqÈÕ&¦õ‰"ÍÚ€® #J¹ÕdeS¬
Ïi_bü Üû;­¨z‰ªS‡ •å/CdçfŞñ¨Ğ×¹±jc(N>ÿ/Lj==†c¢#ÍÑrÂ˜A6‚´C°ãŠë¯<_½˜ç9Y¸<O8011¸ó;×p©bÀ7mªX HÛÜfdüIØaı&o0tÍEÕ›¤d°©8ÿ|«$Í‰ó§/M?§Íí`} '
S%¢Î’L‹oDÌ½Ğù}–8Š y/ï7¡Ñ¦ô\b÷û¿eí'U5–çb¼°àÃÁFä'®™!1’‰ã±]v$o-Fİ®$	m%NW+éjrƒğpÈ«~ü°ÂÁòë=Y&¥(GãDEDuŠ PCµ{ÃÙ¤×«.ö4d_ó`£{ôW©±^e„X)¡“kå S(ÙÜ…âÊ‘•ÂÍŠÒv.§Û)â¯aÏÊsBZ~%©™JdiÇ&­±LÜY<~q¨ş*ÍFşvÖÌ%E¿`;UØPöiú*íÈXf~7ƒ¾ºÉR¸—[]ı&G6£a5&+‹s7ş…ÿQ§Ô¢$'Ë)«5U=İ‰|ÃÉÅÁfÛf·I²qi¥¦¯äÉ+(¾z½$ÆN‹©]ö»\cdÂï£Fít«v:e°@#`…t?Z»p€-óˆ¤%ˆ$¨F©f{À&r	ùÖ¨=-¶„E;Öèè±¹¼'ìl7¥/^^ODŸRtO…€…‚ „×†Å›RÆÑQ…ˆÇÌrsmD(E`•NŸÏØó816§ªÿ«Â™üv©ğWI½§¡Í.]»1E“®“ÍşHŞÍrBö¾i NÁŸ¶NRÇÖ‡¯£½QËÂ\¤ñ+šlN…¤
-„áºg”‰Õ#ã1Û”²ÿSâ×ä³'[
£,©z™ÔÂ#z@¸›ücÔ˜¥Ÿ×hEX°ÃÀâU¡¥ıXQSÌ¡vî9’İˆíû!ôj0(ªµ£‡ÕÍdGÎ?]2ÇP%Ùd†Ó×Ûáyq•ºP“t(­mR*à#3 „ òÒ<ŒAßú2Ê'|¾Î°ƒ)&˜	Ùõşrº]Dp×ZH`!\ŒõûèI,¢)êÙJ¨^0œ ÒmùŒ•2À,³ÍÇŠK† kn÷fØ<+?¼©ûX&hšú/”{%bğ$¹ıÆJ!-¬Ã²Ïyâ‰4\ĞºTû"J"d,?‘~l(ßn’¡&Gu­)I±p£ñÊ¹ğ‹7AXÈGPàqŠDÎYª`¹ÕÔt£½Ã¤x qÀT¥¤İmYPµıõ—È©51ê|²;ûŞJ4†ºáÒ˜…^ŠL÷ˆô¾ äŠ·E*;—Ç–ßØ$?Á/
H¾ºá% ?¢r½ì3TÇò¦Õ<PÈRÛØBFëï5LuDÊ[µúÌ0.ªÃ½—KHß”|­éŞ­"rö.1‘YnõjUgxÁñŒ£åÿú?yıßR$o/È_thd)á‹& Ò¶H–µ'ã§£bzT]›_#ËÕ´Â'gS/ÍgM Qàé0É¾Kó)zèâÔZğTš˜-e¼›láeŒ=M.¨¦ï V¸ƒr¢È[o?]]X¬F±sŒæ7…RŠDéî¿Tú;@oa¿ÛuF¸g"Pá‰ÊÄºÕ'£šjœñ PD.U-æ…î¤¼w5× S­ÊIÒ¡õ5˜€£8ÁåÇ6¾İÁUÃè[Æ.'À¿Ò|aŞAå@FæÃäµÓàüV2>[tûød;Õ·7&„+J³_w°b›>&~¨1X™iJn¾—¯ÀõE½…úÿ9âô_k“Ú¾à!<ğúR×i´Çe;¨0Ûm¶“;V•³Q5äGÜëÃy…VOBÇùH›mí·xuÅ™àÍÿIüÒÆº§ã>K-KpälRi#6¨Zª@Å ¾í
	¥C!N¨
D8h§¤_Àäû'šçZjí[3³˜ù=®š¶2ë-L»x%în;2ê“2§<Ş›FèÀ§÷ğP/“æÇÎ€÷U=O‰Û¬’·í¢¢5äÁˆ·×+Ü_Ã6£F¦ú,Ö$Õlãq©0ğ ôRÌAP’$³š¹ĞÇà¿¿ı‡¡Ùycg›}<ˆBª¢’Óû‘ÛûvhA6Öê~í–×Ú`!EséíòŒCIÆ€ÓH6G¹dV²Jlğc×÷¼  /e¢¾…œe°ä^¡RMæ§83e¥‰5¨¿ÿ$ä¸¶•8!c|0jõä
è‹ô0±ª3ÚıØQˆÈ1È¹—¡¨xÿ=nè­'8#'PéŒYè 4ã3[ÄWEõ¼î$,Kd45XÀ[F%ÒƒÃÕëÛ˜¸âù¡Ñ@4
[_Ó*{Àø¤–b•1W!¿ÆeoÍSÔk÷BpÈ¾ã|~nÄJ¿æ ·ÏAÍÃÅGc{+ODuºbA\fğeÚÔ“8dá¯‹6VĞUÏäG=5¿¹â×QÉRU{§Ô\;¤rg´¦
?É‘eßúïûá–nåİ=D*É†Í¥‹áü¤İğ]ï#¡¯‚Ù>€BNèµ‡Ù²]dû$½fÎBTpÌò¾‚?/:ìû¸@6¬8ZÈçÓÓ8ÊĞ”u3Ã¯÷2TcFq§„Îdàe [î´(y2ŒTŸâğ•®¿™[7¦†«5ÛKŞk1BŒ¢DV†.Ö8@ ™ñŒ7(õÂÔğ%GLq¢ÊJ‰O)Ü'èÔëØ"À~ÓÕ¸–l‹5_-&üJQB¸¤­ó}íCšşwñßùXãÎá¿êüúŞOªŸ‡€½ìLM ST†°ÁkÄÂ!2 {@Çîlç[ì»]¯	Ò kµZM°œÑa\t¯ø°èú5°ƒGëxîMG¹±úìİ¼ë²æ``sûD¨İşy*ûA{9^ÍG|€Ç¥W`“ê~S„xRïgôt»£&†müÙìÔv•? ™ù“¡ïÆu}—¿q¸Rq(YoZçÂt5î'ã¨ß²Fñ4ú¬R$šÂÅôã¼MsDÁ¬Y¤Û­ã-ñÆ	–ˆ
–âæ±hz7À!VŞ¬¹~ŞŸŞÀ/¦3ì4½¸J\ğÒ|Cc®­ÏtˆÏ8ˆ<Ğ%É+…Z‡ewêa‰šé |Âÿ'‹İ7Y¶jcÒ˜aiçz÷‹İaÌ™ÆÊ›+q.¿h¹—÷£qç³¿ç]'÷ÃĞ£­ÀÍL$7ß¥)MÉw…NŸn³b˜GÈ;yĞ®ƒË¶ş¦Íï+¸W
ãâ37jåäŞC	ŞlPò`ÈSãMlp6©Ôæ”V&(`à‰
”Ğ)·İP'ªBf’Ììj­Šb¥;´YAââíÎ;D%8]jNªj
ku¥f :YÑñ?GyÁ’ì±îéZ#¢yrĞ¶ëGçØ@ü€ß¹Qó«¾i¥ÙpûJˆ ½¥é:	Ü•¡§ú!’RŞ1pôÓfî+ ¸­{’Ê]‘iÓò`ş¬„Ö•Æ9Çı&9†©"Sàı¸+åE9\ùGáºåüm§z=$gáÛ¼Ú¸èJ­Ív·Êlì]öh…9Y+ ”>
OÊ°ŒÉï$Dú„L($¢Õ °`T#‚§Ó«êÍghÎ}o¶ˆwáál“,b5´f´!=j‰gÓã@âmµÖ=Ì’fú+óÛ„ì¬c~OÏKÇÓ@Æ‘¹e|¤AO4¦ÎÒö],ÛßÇíÏsIŠ8â@»7óÆù“ëK9°óZ~º 8”Í“è€¢æz;6PöY·Àh¸íÌz‹´æ™\¼TP¸UNÁf«ìKF	İRÆWÇİ2·âóú.ë%$Å4.b•÷şÏ(õEÈbSÁP@Øóõe”¿ş8á+ËÈşyÿÑ˜JèŞ…³
ô6`}÷…à
²eªÈğrLáBäŒÂ•°–9àyƒ6à°A œÜAÓëáNİOÉ,ğàşÇN€ÇotÙx£s#¾|çD6iW‘Ô	ûµ¹½ á„3pìùÍ[*µ¼0îZ,İ\'&4EyUC[’¬ytIpÑ[-9Á“Ñp¡8;1(ÏiU²7ÏÆwCÁ‡ı·š~ıêÛ¯´¸ŠItÖîâ%ûØÆš÷ü^,ı ÁÈQş¸¿îT84ø«ÉÍb)Eª(+iêx d~[TúæÎç¼dü+Ùwõ3›ShY8¥ˆóq|R7¤[²Mú	;µ¤JM×î‹©ÕÊ1à8&+ä¡Z'?çÖ
.X™AàÀó“üe½±;2§Rá)¡îÁx“_şá~R™B"Õ0ÚÄ©s©¼!FÄÓSèïµµ?+”[n©Œ.¹Éõ,“Zé&Í¼A÷åüÑÚÑ ¶•‡‚ÒäsÅíZğ‚óW¥õR‘ QGŠÔ+9W·´Ÿku¥Ö[2˜ÆŠİÙJ@¿!­Òòzi(¥7hûíÿ†Ö‡Î58gXç‘°Şk'q*u.åbä9óL¥Ø.‡DvyôÂ&Ø©	ˆ¿©)œG–é¹'P—7ÄfC4òß?Äå9<úê­¯Xê«~7(rk+İh;¸&Cë…ŒëÓ*6Ûnº ¶~»µj~¹m4|îÅYr¼=
)u¾«—ÿ£`ê‡²Ïùwñ]ä1‰ikTzµw-ÚÆ¢ *±ëŸÏáL“™F.v?X¾®*H}ÙòÍn,âA?£’=ˆQV+K)‚
Ç¿µY‚{AW×$wIBnÈ¹ ¶@¢.Ó”Xïâ*ÁTd9¸1£ß¯bóëĞ‰Ó}ÛÔÁcPÈ¨ÒÁÅ)‚0ú{óY¯ª^–®?°»>-èA!²œ± c7õ?°±’ÖÖ@f‘ƒËH”,T˜Ü™ı¤3!ì-
#²¡o+Ÿ+ìT7Ô †×ıÈyÄJ^ÁgÛ1ˆºïÏúkk[KvÚOS¿ë	Yº}
†û¤¹éU¿°_Æ¸¶Ä14uÔTšlÂÈ/Ë„N(t“ 6F'å.MJ _î†”	WòŒŒ#³ñhÔÿ|ó©m €ã÷ËNuë\Ñc‡%Ã;İ°F»‘S6F^Â@ ³¿½S2f
#¼ªP‘Ò;a¯Y“x†…lßÜ_QTôaâJ€ûÈà7Á¨3› Ş|Xƒ.\˜/3]’±gÄ†’sFoÀ)wÈ(Dı÷G¥s­óÈdurÏ%}‰isÑj—¾¯5iÕó}†óXŞ§;Q0‹²š€4Ğ‚©]qğ{Á9$İ¸do ñ+½©4Ê@››hÕ„ÏO²ÄŒ	5Xòæ¹8S³.‡-¬·‹¬SXÀ$	pĞ¼‹Ä©/(é“Ù5FÁfoDÈ¬îzBIobHİğ¤¦FRÿ`¿L¯RõäAºÛ¬ÚPæQ[ß9d8ÅçùŞpèÖÃÁ’­øJ£$Ÿdkä~˜–jcz’¬zZ±Ÿ²KÉù24²·¿íx®×˜Ù#ózZñSX!ÕJÍ9ßm	ş·2YF&RY‘gìp!âG½&6M÷•$g?´eNë,[5n·m·æNv!™–ï e]{>7uZgÁªüoT2O¶¬º&>l“ôC¬f¥Ó{Õ!O,ßûLg®1•b×«ïôÔ¤êÿ?nI*pK‚}¼îøÂ8W¼I)òxbT= ù›:V²Ÿlù]ı6Ô4}Xà
}CCPÆ¼7J ı×¶)•úÌµ‹ğ½µ›¤ï•	µÍ¡*ê)¾ü]€4İU¤¨V4Æ¢Pô	Šß^†™“>¿¾*õ€°…Ó³Õu§jB¶¸ãòÚëµ.m1bĞC8zÍ]R°,™îŞ1ÃïÁ=#‘Ì˜ÁŸ.–¹£š¿V}ë!ö·˜ú9üGr Qt€AûX\j£Kè·(i‰9
®7ÈEG0î»ÙÉ=¶Ïc1`‡ ŸÏèk§°*q²Š×®9¥ÏpXƒ¯[ö†[‰¶ KÒ›|ıÃ +˜ğ¨ô«™ÕèÑ4|Â…¼ú¬JÔ	%:*çJèKJ¯Ã º[Kõ9
ÚIï*%xü‰ºÁ‰¡™ÂÂ¤nhw`8IG‡ñéOlÜ¾ c]?á	`åLÈLŒÈİ]{ ‡ıÇ[ï5ÔÑäN b@ºÆ],åváUP
É09"b·Üµ¹ÄeKÁöü»# øB¸¯ˆƒ2†Âş¤û3t¤Sç#Z@şã£J ˜­œİ‰3ôšè¢`?pÜ<u‘Ç~]+q{áq,ûô°Hã6Û¹#Bç©.ü8P5yı’HÇ<Ù&PFô4Àz5NŒÇÈbµLº‡_Æ¬:ÜKÍ4¸jîõİ2Z¹ïŒK®¸ñ[FŞyØˆw× or{÷ûÑCXde™¡Ç¨òî`ÁéÀ‡S1ÚPB€Q]àï…º<)lıÓ[Ë[]-4•Êjqr-šÍ‡şd’w2¹6­ğ´u¨	,×£i<·Œp=ûÏw&Fš¯¨¨BıZ¢{F:vk^i™>5¼û£¾ğup|½59(±ñ»Ç„q 9„3UÄè¨×Û¿ÿ¬.ë™÷aëÏ2*¸°tñÔé!´­€4¹Ba‚fÃXàœ;ß•æËW	+•¾Ï1¸°¤”eùˆ
Ñ Ä	w‰¾ä{O@äŒO„ ?kUçV™+.ÓwõæŠ)ªjS§™ÉpÖåĞ² Ò,®ß	ò´(Â+™ös‰ıÃBù%FW	kóâ•+¢K-5„™ñªYQÂ“`Öx¸ªçó&¸i8·Eàk¼/›óVÌÀ{'¦îó(Çhw‘ã'ıM…ÖÆ…sÙ'¦^,.pÖ°ŸjŸ×ç-gJ÷š±T$¥ù*O…¢bıÕVœÀµ5ò¾àF«›†"Íğà#óJ‹6¿ªÊ™sâ{[0ó3{àuèëõñ>)™ø™$32Hí9¼W[óš'ë37JƒÈ¯€0æL}'ˆ|¸`¬‹l†…"¢@<D¯‰kb÷+ÏßJŞ$àFcâEêäÑ!/tË¹é+0ŸkZ|«3sS''î£‘âQIçßÄ¸’=¡ßë£’_Ém‡±bnsâÇVˆV±<ÊP(Ø£a~Õ€ kï…ã'rÁ0¶oí‚»€¹›ÊÃ o8§./‰…ş!¯EÉ‡ºåÊ<d­ÉÄÃêçÒnöÚÔcsì‡Ò½lŸiœèŞXŸÕßOi‰Xg)´’ô%p‡HUú©°Ş©]
Wël}C_ö`ıÕDÀpŠš	ó%Whı!ÊpğÇÛ÷8Dnú4é‚‹q%2|ÄÎòŠ–$Qêó‹OE—×‚âIMiÑ–Èï®ºÎŠ‚µl™§2©º¾<ÅUÿR&Úú GIß~`¼ùmğÑ R’3Õy ¦B~`èéÓú›>ğ1ŒäM6ÈCzn‡†Ò<lRuÌMŒn™QÑ^ŞqM¨çr¿…QÑOİj Iz;%¯&…dœDÿ1‘Ø@æ‹°ŒÇNÄ-®N%´ÆÔo(Rˆø*ã¾;‹h6[ç­#ß×*¢±·¦„[Î|Úvwqn–	xÏf_‚,‚Qò^<PÃ`õDƒåxFLŠò ID‹Æ±m¯µé|-Dê  ©KÜÂÏ4ödÄ¢ä:™¤‡^sãÙ[àè™qvk~eYÜìs@×]\­ÊAõ¥˜›QìI1/¼y-ÎkÔù´2¯'õ9Iıi`Aİêıo{Ø—@‰Sïà/Ú4ıÎæƒÉ 
Œ¯x„i=ıñs+‹Ô¿w·¸Û¾Y·‹‘EoB^æ.èÏíµdcBB÷ò:­_«kpÈŠËúï÷¦&ÅO<–¨J›xmƒİĞ-ªÀ±)ˆÚÊÆó‹9é‡ ›»ßSæøsAÛYbohC<¡ 'ã¤5°0utJNßê›gy„Û.uù‹×ûØ¨‡ÏšW„¬Ë¬ZÂkó@˜¹Èç_…iíâı± ÄìóÁÄ,ô¨ïóêĞe·{¥åÉ’|,ƒÙ8-É5ÍÍïŒH›ËaÜû½³hjN•:¡qYº¢7Ñ‘ª[ÉQØƒpˆÜğ»è®ş&µ$]´ğâæµ¸B®õfÛmÿü¬Ów^:(š#«z%(å@Ec‹î¡ğŞ„H:\dxÓeŠ¾ıí×{X÷ÿæ©ù™¨§8ÌÕË-«owVêN™8Y $È )£
ÖêbŸÂkı–£.M•ã§IT†Ò4ºp”™±O@ôªuúdÅ;ŸÂï‚6)~¾êOÚ
&cH Rq£ÌX›sñw|¢…Ñ{ğ“#TÂ"u=ª†ş¾Î1ğ˜²eÎö€Lå…§{Q$R”¨±˜Hs)@l<tCF¢p™4ó~hW,9ËL®<œ¢p8Ç»UÈ¯k±«ÓZ¿ãşC úĞ¨†dÑ‚“¿Ô•oËş{Cæ-ˆÓÈä™çKœªlrw¶F ù*V<VĞ®äxêˆ™Ö-wÇ÷và?£‚ÚÓJ:ôÃiLDœj®ËÉmÍûÜØ4XÏ¬Ë{jCßç®2(:­|ˆ§_'6½ ^Õ÷¸Œ»+Z¨!ôñİ!+Y:¤4ÀÉ¸ÌGŠ èRé3 ÃQê]·½à‘1ÙâMœ´–/.¼M p—eHd­öÔ˜Oªqßw£€#d„2X÷·ß¸Ö|Ñà=ÛÀ)\îÙ Â"D´M8ï€‰øš^Pş¦/BŞ§ib× ‚%BÒW8Yow|l/˜•Îq	Z/¥V:n:_ö•H„wë¶%³3Û¼´ük¾àä¸jökÅ^¿b„xæGwbÔ›ÂZL\¦ïLÎlq ¡À6Ùf
Q¦OiSN;æ_·<šhù=ƒMÁ=$èãcnİa$[ÑŞ_:¸‚{r‘x¢%„ÈûJ?¯—¿MÚÛocsuòc²8	İ§ãg±	—µ˜äŞyâùG}FÙü%ÜPãhYP©pÆ+TÍX«|{^÷'îXÈº^¥_¯Ubj#»
ºbA×.Iñí¤Bìà~òéÏ¬.1"îM^£-i–¡Å¶¿!V¸Â°7©6ÎH]z¸9­ªÓªR"³–{Úmœ5¹ˆj4jõ¦p‰S3"^®Y+'ñgÆÂ’xz$ÛxIŞ«<ª€ôªîşBªóP!ØFmª'çop!”D\¯[ëbjÛOyÑŠ~Ô’!ÑF»ÅüÚ(êÕÖ§¾VÆŠ9RıİÇ”f©g•¹ôL!šîŞ0-¹Ô
Ñ†µ¶£Q…0}SKm”cI:ğÉùYluíë³…•¬Î«ÆAÉ¢#Œ\Pî.I¸<›|÷_p¿æÏu}ä(óşõ(ü zô­Uo%òŠçÑ®TéöFúØÔ±ˆ(ë{é²q¥H‰r;Ãv¾ó:ÚÔ®çüX,b§œ8¾ÎSq/Õß	Ô6BgXé¥¹DbßÌÒ—ÁOÀs¢(F¶¢ù»]y&-û °ü+"93òŞÂèËhÑá³Ë]ÎhŒiÁJcªNÙ©pş\Û	ş%_«X:``‡wğô¤¼Î¨­WÏ`\$T$àÒàÀÑ0´Ë¼Ñ«ß|abê|B„4“2´CPÂ¬O”¥Á6/9ijî±˜B-.HG‚^Ê¹uËÜbõÆXŠ-,QE‚	åÈ:£ªô¶ªİï®¹ö›-Ÿ_e±MÖx:"–[ÉzTsŠşNj[û­öHKOHy¦³+Ëy0Á'XÜ'±âDoe¿‡`ı›C8©ìñPeFnp”ûm©{çãn¶©|b—L×pÇvŠ†*˜h~TfOH~©`‹iÁ‰¹}çö˜L‚.„!ÓV¤æ®zP	×ˆú}G&.*ÙÒ¡¸°¿Ø	'•‚Ù%4[íÅ9p5?šsË>"×ÇliIÓ*ôãŞÎÚ@öàÎŞÑÔH/)ãGàeï‘ñ(…¨sè»³f UA=Âcär%Z¨¢m¿Ğ\i@ ¯TÑg!
ç€ŞÌ†q)¹#­¾Ó˜ã¶±‹ª³ÅöÛÿ´*Y¥B‹hØá3?ñçæ‘téÌ#„…x¶4©Š\H–”Zª‹-$E:]<ä£J“²œDÊŸ‹êöòí¡Mlìt
H^Hvk®›û5x>"MÀ»"Ç C	Îñ7Æ†a"µØö™<­kÿ^ßf_¨Z×>ŞdD('VLĞS|mÍ™õ…ïVÁPFGŒ‘mª{ İ9m}˜T¡`¢"Ní×CT<G„0 YOùõÖĞÈõFŸq—¿“ğÑÀ:C‹<×.ÒÀVÏÂ§@—£ÌW»åÎçÂ©kbíĞÎW<ò*ş7„÷W†ş/6Ûk–ÃxºÂÈü6üÖX¯›îk¬ÚîÚ*\ä¿°‚)¯e(\Æ,ä™º;¼ŞDëvÿ¶#/[k:İy/lé¦T S!DŒ~Ğd“¶Yø¶.¥q¾B!îØßé×ªEüpä_|ÕìÏAu´Ç.¤A[|–L0Ax„ ‘ùR%;:o‚˜¡@ë•ÿ¯X²²XEFŒ"öá£vçn8É¼OŒ	¯ZŸbÃè©Á¥$<™·¡tÆíû‰¥ÛtrÄ¦ßzTåPƒhš0Ü¶E¯0µ1Ç<’´Ø†*÷Û¦>¾”G¢²ğõ¢†[_×d¿K	~;.†)¹÷‚ì5ùs‰¢']~Š©{øİÎª‡É¾'&@3Éı©\öw¼å÷à€¹‹ÔáJŒ°Ì¨ÔYÕ+?+ª±4×€È#ô—²ó¢ş?Å÷ı ¥±cón`t|µ{v0B(›ºSñõv³¯£ÂViFş{Ït¬tSIõ,]9\ßLÖˆ’5ÖÚ+(\•°övÈ˜µÉ¡Jå°á8úÙší‘Æ_ wÓÓıEAáÁ¯¨Ù¿ÄgÁéÀVRñ*Éõ#é½Ï0eø”‚ğ}ƒe×é–ïñ1_£‹T;¯ÙË$xğy¦ù2¸›lIÇ[H®ÀÊ?S‡ÍgqÖÇ"ydÃÖ,G2àPºf#½[.ì“X¤Û]
P·‡~ÓñQ#ÏÄöŞDæu(¬û”úcÈS7«çcƒ|!ï7*o5QHR9M{Ê'B.–mJøV>_FÌA2ç,o³P"t¬fÄ/ñäğJÂ·ÙKg˜(gŸSwÀ©v‹Õm0·iUDåÆÈıc,ã³svY6\RxŠ5rN³èÑmmÑ^òB™óÌ¡ä ÂtS0yVP» hÕ]ìÜ°&Cµq)ÔEìøH’ëÉoÅÒ˜ƒItüú8àÖ™x*şY‹£Æ<v®føˆ‚¨øñ«·6Z›Aœ´¿›ğ@Í.DY@'yPuÃß‰2r®İ{û<‚¾maaÜQÏ×áYXù­Å(ÒK‘¤^ÄÀ/æĞ :9­ò÷Y¿éI¾)âç+³‘›Ú‡,9n—Î×QŸëÚe­‰«(£ç “<7IY;¬¤ú1:¹FêPß—¢ò¡}TÑ:·#¬^ ‰$¸VR'ñzŠşÿÖ%kÒîØ£C¸ˆ&Ö#8ä¿ÛkjœOá \í]å|ÀßsoöééÊ®ñ\¢÷ÄI<‘{‘Í™æsÊxÚˆ®qü7ª¿Ç*MHu§92š€Âtq™9T ·?Z‚_ÔîD²äå5­d"À6²_Â"â×iUôÛ»åâò-¿oûÅÕ.VŠè “®M®À0í®»û¨îş,h…8@qŸ6n€zeŠ‡N[,ç>qÏƒ…ÑwİœöiMÜê"@MÖzÇKÀ{Ú¶ªáaWÙ/©ßf–ÕG¥ŸàŞl(<í1ôCV&N*2–°DÏ·Ö©RØt’ÓR)É@¨3­É#ƒ	‡a¾/A‹àĞŒb7ú96ÇñË*šníTWU‚†ÅİÖV‰Ç=‡ëjJş®!R“©p…«*p*ß¿%5—ãÊM=[JMoÔÚÖ|¹a\jip‚G¨¶?1Xù9ñ-m`¹ıíls1ÒE#ÃÔe£½µ³´{Uıµ[6¹1ÕN£†ÚÑ¯´Qˆ¨ ÄO £ÂöL¨Ù‰ü3h§ØÂŸgíS9NQ(ÖNÈN½
YÏ,¦:9
PÌ1JR˜†+2x'«©P¥vb
mñbåt-…É“×¼Èğ2k½A3Ü‡GsHzM¹’0µÚ…˜> o©¶K•¥]{H¤u+¥äD¸V’ËR4j3.¬§ ßfú©}ö- bÁšN`‚9£©èKáÆJİô¾ñî|Ş2‰²K´ä3‚6ÊµZwòmyC&%@šGf~ÇÇıƒèà`/pKŸú$g7{¹ĞjjÑ)ÏÓk+(¦š[S#®¦¿ÉhÏ{Z¨æëÛSgãIè25ÉT{óg>“ï…a6áH5`¸â¢Şt$â³şÅóî^åÌÂqË?ppCÀÜ½äË|7Ü Ì0ÃÏdÖu¬Z'ÌÒ	bì÷Î«v7€¼e)ìcSå]v„à#müëíXhZ{ÌoƒØÓÖ“?ùŒˆJ­LÌÆ)P¨ALgÅh‚Ê‚f³¬”µn°È¢¹=^À¾^åÓ7_]ä” „y\Ğ0³ê+	4:Ÿ©ğ4Æ­#ˆCNÇ«ÅŞÜ«|õ“\ë‹<şÀ è-$ö
q•ˆf–¯0ƒz]ÙxK)ıî½{·GHcÕå/·±g¡UOgKÇ>ºãüNËİölC'Nü ÷5Pt_…æØ†Ğzf&/{ÚoÏ´/ÛÂŸQ- ?˜"ã@M“)ûGáahÔ Ùa¶[]ËMœ¼ÄGCŒ½ô0TZR	ZYşã¥4Ò‚!grkøPE~U¡ °v½eÿ”¯MºOÍò°Y¯a÷ñ3­D¦CÚš÷xvàE(CM¢ ,£?…nU˜âI·ù0y{æĞÿãT%5>—İæCÏŸ¤o4Ş—èQuêÄÒmg¯èæL44ØæÒ¥ex-z \|7ôÔ^xÌqºQªÔ&qÚ>ÎVŞ¤[8¹;î¥Â}æ%Ê¡C9ÜÀsósHõï!åˆ'3}˜Ä +[¤t_Vc–	¼©Nbgg¦]ùóİÂ	ààßŠk¨\š¶É;x"ia}Ü‚€©à¥uzƒpÅ*¼R¹ì’¢Z‰‹/Š2ÃNùÕ%'Ë«ê†ˆ"ˆnkPÇGÉ±.kG`HEˆûÀoîtkÏÊç¢a_<ÆWä×ZÂ*´Ï)©“”.¥“p†¤/&ÒæzAã©/GƒÎ©Tã‹s^8emİ>Ğ®Œ>´YÎÉKúç([nZÎñÊüÀÿJ|vG²g*¿ÿí”fÎñ}­wåMdpfór
õ§Ê$Ìl
ÜÇÕ.!ñ÷×-È…ïgf	8_ê<5N¬C§Ö”œ¹}D;Š“J…”URÏîQò™+U‚$1,£
FSü¸úŞ+*Y'÷)ypÜØLÿñ~ıßFë]ÓmÜ±Ü­\¥ùë;Õ³í6ÆÍ61&	ĞOÕ}5ƒv5Ìş¯†h€¨Ä­~’ÚÔ¨#6_ìÄŠƒ#¿¼VÜƒÏÀ’”g#AÚvÂ§ı¬	;¡Ñ9Uìy‹
ĞüÓ3xâfPàdğœÌ=ÃYÈš´ê©HÿŸêì–ËójMÚ;}¦ü¼¶ê"m—ÜUtùÃ±kš”îJ!t?ÙxÌñ¸™ò2ÓyU°û•'Õşíb½f?‡ôÊ2i½ÙÜd˜f´¯5E]¿gTı–iÄ¦Tœ’×œ ş¦fç<SÍë˜>HšfÖ›}ğ…}%÷À)»¤káò%“‰/Æ>%Ä{8uMÚ½°–Èº@CE&…L.IL¦áÜ;3`-¥,yf«o³/¬èfÍ¢{jYd…Ø±ú§0X3ñ—£é@,‚ê¤J 7ß™i´WÔ¬‡wĞA˜û
6¥MßÖ¶“ÒA&ŞëæóPu19ıB¸nü¤GßijT»Â÷÷“‹âÅ€‚®¸ëªLIX,²ĞÿC“–ñ¸>Øš"Øà$´‹ê|Hw}È&C\XÿjTIõ¨Èš§·¶}Dçÿ.øÆ«/_69TÈ;îk¯H‚ĞûÂ{…G|£ğdv‰öPKÔ>–(™maÕ%ºİéÛ'#ÓqÉuúÚ´÷çî/…$ïšáÎG1ô×&sîÈ;ø%Ò}çpÀ~îU˜˜Á-5kmŸÑÀu^á˜£rl3’—P¢²ò„2ıiJÆ`‚Ş"µİ¤F ƒ‰¬ĞPš&¶­şÇdq¸¡™9sï¥—ï%6Ï–,œ“©º'¡( ._±®Ò¯~Z¤CpŞyCĞ\”êddÏÓ`!áªÒÏõš@Q|CmŞ¿iZ ›¨İvùòımú™ÛËüô6Â5oÆ8,64YÒ@âFµUJÈcº‹È]˜ÏĞ iH¿<Œùu–eK[«şş¦¶Ö¬«ª½ÀÓ9ÂOš}êP1)ÉrÌZÀµà´X¦0ç‡‡Û7f‘£iëHva}¹–§1Ä`€_ĞÜ¬ÖÃo¨ú,d;ö^õ<Šo?\]À«ò|>‡ ú”z[H»Êå¾Rùæçu
„Wh#Xù½p¾7jxV³Ê)ó…Ò<‹¡ƒŸ?Z$3B‘FFï7xA4Nè/Ÿ—KÆh^®6î~ûLn2İä¾eQ‰`Z l×¯Ğf¹k±ÆT#îl1š1zVÀÓmE=cê"±ÊWæ]:R°&Ø±ĞIúGÄIW‡Ûj·¡q±8ßZjHy,ºãe@µFQh¬ş½P:ƒ=m€:Î-:/waoWŠ÷»yÉ>°í ÿùlÍ?;]Æ.8S=ã½Á>%½´= ~_D•ú³PîWXökò†#Î—õ”Oû@ÜqPùÓòôœ$÷~UH§©²•ÂÈôŞÇÁêã_ç,ˆæ÷°]İö¨%ÄLèóè¬%(Dìè$ùÇÜ³%ÛxrŸ#T­áûUQÓıÊûèEƒ'h±÷^
ÅÎÅ»”S«EŒŞ=Æ"š¯k‚¯Ş4G¨Z^Ô’ôúıì/¬Ø®õ.3`âÕFh¡»ïŒ÷7d·XSÙô>vx3{tŞ¢C«"œøsÄôƒaµ¿5¢Ò8õ/`%–È	Z:/±ùU®Uï¸¬äİyD³‡ÊãÌX %U»\cc—È¾ˆ.M)Œİ=¾óù†ŠVG¬]*m,G$úœD”ÍwCæŸ‘À–s¢t”÷C 6¾›/„I^•ş»y©‹^@¹ã^×ËÂ—´z˜ÃƒCs	 RÛ2è°wßŠ¹á4JE„f€,…!"b<¥„ŒdåHÁƒŸöpJ+«Á¶Î0T~—ÈÚ¡L)Ùr6>¤¨Ø)ˆÈpç{úìŞúoo“â¸A[FÙ	™\Ff{0?úègÉÔù>ø«Xà>ÂÈub•‡Cù3vàe¶£wêQGL”jSjZMò¢M”#;'Hyìl`J&[’²ˆÉ& RalÙ.ÅäÅ….|¦T›ïAñ \„~ˆJ91|òâˆ×…çßFàË,u†˜X×»¼qÊÁb"q«–V´ ·
xy¢|Të ªµ{yeL*¾Nõxƒ2Æ~ò€mU˜®‚ëˆ*Ö¶Ïf„µ$êÊ¹pÑ™¬ßÆ¢h B5•¼â¤µÌR%-‡Q,•Ân	IK;EL”Á£©
óËiæb6b6Ğ‡ jÃÓ[É‰X½Vˆ£?ØR!.æµY\™¦k½êÍ£(€°“ì£œ0må¯	T±e*£`ÒAÏ¿ä ÅgÖ½Q¢Ú/2@òœàæs#%Oµ½zKé;CZ;mòŒÇÕØÛ*^ì
nƒ"Ú²ÜØ?ìGßé¿·ÀÄNVØ,n^­õŸ˜P¡ë°0e&FUTŸ}·«œş™ú¥µüIª*d‘ê»å)+¢¥m‹³5?ì>gÇââÜh]˜A8Ù/¡03‰‰[;‹c²Ö )&¸}}‘‰»n<®¢òg›=ì¸W‚a¯WıK¦œtŞvlÌC¯LV‹1µû©?5iıÕ-ß–¨øÑ)Ö	ë”`‰¼îT6–|R6–QKïÉèİ4…­`5¹¤¿“„ÆÃ¼è†O^1Õÿã®ÑíJ€;üÔy¯í#Q¡ˆ?Ÿ"i×w9™2ËŞdV”L’‰2Ü*å’²¯„¬ê^V¨L€7ŸyÙ¤”"ƒêv­€`3ê>ğà¾Då7—:ëóŞÖ&t¯sœvÙ1œ–Ô‚İWæ™Ên‡<ßÙåÖï7â¡wYˆÚ
—÷57½Ó|àè³²È‘`ûrj‹‚•T5a%¹q&
EÕ¦«äRrwéi’À½ı¹ÍàåÅœE,ffÊM´ ! …°:‚"sŠÿ•’Ä–ˆ7!ë/få¯	Übï5T³¨q’©ŒU°PÍyn¡[Ù°Û¢Ú3¡§MÅû#Ó_"‘0„®¨ÄË¿s®%wìÂğšÃ  ÿ§wÜ”İ}–ÄJ*ÔÓ÷š\,§öDk«i@!½†ô!hÅ¢û¯à,ùºÂ
â(ŠÎÌóƒ.šfÌë8)¯@r=$ã%qâß¸·eG’3X–‚ĞT+Æ%u;[óúQå.Ñ‹LÅƒÎ¢üZ9á™PÃuêKÌ?ë³è¿.wbíšYÅæÎ‚»V‰.
ÓE)s‡›­Ğğ÷Ş).Ï¡³¡¢LëÓUÔNá‰èCğ'3][Uc^$J!_ÀLÃ1­‡êñY(ê”Ÿ¤ôSoé6º²îÀ"N¯5«Ñ%•ó"HD‚Í¾Ÿ×è3Q€…kwXü]w®0×¶½ZÃ«ubÀ¹
Ô×(¬ğµfR½fpÇè¯Ô]µÚïi… µ}a~[Y¼^«øÒçú¸T=ƒdZ±‰Ğ(ôØa7‚ò’8[a"Ô(é÷Téwx(¦j«¬|Z³wKãşÃ×êæÔ3‡qqÕ{ÅÏ{Yàv'Ogà-‚ƒ›‘_’-ÚhöL¶·üÆÌæèî‹#:¾Å6³­©¹e;.Bú©Õ?Âğ¥ƒ‡æ0¥ğ@’%ñ¹¦,^SÓëï=]Ò|ú¨h¯•I»Æ Ã¦›ÍNÄË™±Câ¾ùĞZCPNü_ûİ¥r£~Œ+‘JŒ?Ä)C9w_š”Ş  ,ø$ÛdÿX%·~eD6Ü­½ÓÎQ5ûîBb7IlÆX&uº®ê*ò²)ëÕË³f¿ÁÛá†V;*XºİdæÛÎU{ÖwßÌ‚x´c³/ı£ÆúĞtSpàHé¼õÔøã4h-øãz9ÙI;Õ==îİIöÖÄ£ˆ¢îË§‹8ƒÁ”LÈ*›ÎÊ$ª°¾REÌfÓL
Î°0•33u™UJS5nç>%ñâxuo?ëä¢ùğr¥D8¥¸³ ¶ĞÅÖ`évMÀ¤ëªƒÒÖ–†Ñ~mSæÉ‡´¼ÿ'c×®òGj2Ì=&²÷Jğg–Hs?°MîÍ¦.)şş»ôõò/<)Ã"wíËp·„Æ^§åBöÈ!WY:ÂeÑÀ‹íÜëAızüRÛú‘±ô4Ãü	´)cê[SªùüĞ9ĞŠåU™§ºnL›&o
º¢8O³ãçãBT—‘œdÎ»ò¸B§ûşÚ…£ùk «-ËÙÚ	Ÿø=¿Ä-ëLôH§l§tÇÛ Ò€è#ØÕ8ØÊ®0Zo†Mß¼¿Ÿ 32à,SD!ıtï¬ŠšWÆ[¡Î‰™ã2T‰­g?“¿Åuj<è°˜9­}¯§­ m±ûÔıQ¨¿0¼MÑÔnÿ7PÅj¼´—_·A¯:1¤9Kfy‘KyŠqVıi^2_€×NÁzgjn	PD0OÔ+ÇÂÌÇK}gŸe(¢'6–mL¬S×§v	ÆS–5ã<££äê+$¥îµÌš^Ó{c¼êNñØ`”ı±1Y—±õş•9{îé ¥ß›Ô}¯DzZ ²%¦JÔ-)¸‰““z4_V–œ´h5˜± ^fÿëZhÇö!V×¯/Ğd Ì¾µÏ[íÚìç­h—7°@®şÅı§¦÷rnr?àßá§Ãj;(ÜÎy%Uµ$qâ=(ŞòÎ-V ‹Š»‹âU’%ú$eK;YtªGƒñJ4„br0ãÙéœ·×®	‰;`X«‘zĞ«ZGY%çÔw£C0á­u»ŞÏÀ\äd˜‹u"²?ãÉ²ŞMî£G›®
jµz)ëS³‘ä?ŒH]R±¤œ[M&T®qnÏÜá»PãrCê¥ëÎ`û3ìİÊ0¤Y;úî?¡ÁLÅ¤¾`°ë6‘Ù«O'¶)v¾12]Œ÷ß7u<«PâÍ™wŞìZÑÅö!’hyÄì¹R†KÌL.áàæÏ”bíÈ¹6`×^3†U~C7+öi_™_ãıs„µÅ<ˆ”²¸Ü»d¶Xoecì§`<á`Ş(¿µÒ©qFË­ô´Œg¬„ªå,ñÄ*%şøêìâwSÜ@şœWNaÁxMÜ¬2cZiºË.àş8ŞvtTP)í/“‰z	¦»Eá¾ÛãpH—$CX:â[“ÙYbDü2´f'%¦ÁŒ>i«Tîâàw—¹ãë5S4	§Ì-\"ÛÔ%ş·ûˆ· –.'›‘–³A±€‰ÛØİÌ'¨(ÇñjÚ ‚ÌmçÉ”ÛS)w÷ªDeø4ñÄüşõp*0Ñm·è*CW8ÊVS!­‹Äß³¯¶ô’Ó³m&v8K¹QŞPUÃ†Öä ojPˆ§‰O:›™Êó^°>UOÈw;Cx=™ë¦’0}±Óo 2_İÒâé¨é,Ş¥Õxõ®ÈÛ)3ğ›/‹¦”›®Œ63¼|C7.L,ƒÏÃ‚<÷4_t²ª–…7uTrˆ5®ÀÌğãîmØ¯„îy!çD)•v/Á!îòüôH´E%òS=ÿ±k/]8FO¼n×‡‰øƒ‚åtÊgíØ¶Õ?™«ëƒòËŸ!¡·2†Õ>İÚÆ@^	+:Â¾‰­Âç3çºÒ[7}8Û|>•nìp</ú6=ÍG HÅÑŠ%+<W34&òiLq¬ (hN¬Ålòo Yğmzx½‰3Òmâ)ºdıŠê-œãM=Ø¿KfÆÛ+m¡Ì)—KÒ]5ÿW[Ã|½ìBV±ñK”5räXáò,|ñ+î¬]fğ;oç¢Ü'±‰¬ÕÊÇ¶Øí’qR˜¬œ+Á—&_ù¥¶ÊoæÏÕÎnÆ‰ GøéB,p¼ºŞ5‰”u±ShİoõU<Ğ9şXĞÂKi²
I¥TLáŸŸ+näÂAÒ‹¹Ä¼dWFéÄèÙçáÊ-4}|5;yôçCAêé3FQôvì¦ÿbakR&ÔÌ@vòËÔ!qÍ±xìôï,e?ÿşÛ,; )k£È¾Ê“³Nú)İc 30¥f éàD È(ÂFâôKt§ócŠO9tLv0Šnc¼&ı¼QC£d&¯.¼)Çè6½^ÎˆüÈª²‰¾‹¤ÎéÍ~·glĞF55nÙ‹4(éw«}T‚‰½å²A€…‹ç¿›ÆÑàÓ0+ÏNe9ŒÆˆné_üÅ¬K×kÊkìÄ÷I nûƒË,®©»§“‚üùaOËF<4lnŞÉhaúSã¤œ9–Dü#úàËkû„`.(Lr&õ@V÷æ)YaØK¯ˆw<ı‡Ğ¸\Öšq½ó¾©½ŒS*Êj‚óvü¶Ykvß\Ú~kİùÓB©fQfm:Q9[ˆv±ç{âX…n‘_eÄªsúXÊ?"ˆ]–t€:5>vú‘ğ¾‘(,t¦dd.¸âj’[ïMf¹Å³6æmK*NĞô®Öèã	¼–ÿÖLV*œ
ëtê‹lvÉä[¢%<Ÿ°Xı=g¨à:çnL–moOÓ5+ã¹„±¿ñ³( 	á«‹ÂêI¹'Ù›ØPñ6'wËRˆ²	™ö‘mp¯,¢Då“ş6N]‚Æ5{ï‰q_Ã¯XZ”ê6Pÿÿ”0é3çS]cV“&¥÷$¶_µÖ7:d`Éí@0ó%8KƒÙ&ï =ïeÃ—
Q9ª"#åsÚRÎÑİİ	:U}ˆñ 0‹^–ÔÙÙ7|ER®Í×·?ÊöhK6vlE-p4ÊPò±2%ä8Æb=qQ£)§pÔ»[³;Fä|ky×Ä©ûÛQVWÄuLõ“¾Ì¹(¾D¯»½­†+·õ(#­b€;üd}~38€Z²©oÄ¤j.˜|ßš†uPó„)IºÉQùÁÉY *¢’œDñê`Tv#0–²“aƒ ïRÉÎ¡µ^U6Ôã–÷`š‹óS7;içá}ßŒYC‚9ºv²¤¼hUf1ñ„¦Â2PC~¼­oÄGT« =ä.ù«òó¡İÄÎ‰ÜRöøş	9ì
gz
\š>)Å,Á)2Èé00#8èu$´£Ğ’_™uÃÇñ\ëloT«¦}
WÖ»õ·8&Ïè¥;…›[Û¼òíİ,W‚çú2ÈN?qù
¡ôğ|ó? ÷=Ã§Hn`À	ØmNÚV’2Z+øšJâ;ï&B\Eò#/óümÌÑÍœ ûâ­ Sã;|"ˆ¢¾½Ï'&Â˜Îgèº>:E—L©Ø~·âğ;ìÅ¬œB]|&BG’–è[ƒİ£À‚·ÌŞD6¸/
í´n¯x£<˜*äíÄÀ‰aFëY?`¾Íë¾­úmÜ6JË6ŞŠü¬íldóƒ†ë+5i¤¨\WŠ»Ëd³´bÖaÃKíçı#‰ì¥n{ŠÕmòW}Øtü€àè}3¾é…æ5NİÆ¼¦çJ‘ÑWœ+QšÃ³$o¡âH.äNW	v-{‡±Ê‹$¹+6Ø<}FAçoÀv`÷B+¦vĞ"Vu¸À#Ìùô‡•$I’°¡|-I@²%¶fˆ¿ÈgœÙ®Š°TuáEŒZûßñ	2JI ‘ï%u×t
rÇ/Š@/1ÖÎ{v£JéfY£²¨½¿z0 ‡$ç1ïaÈ×ÒÍA}çÉv­bˆg§ËœÃå­àî§Ñ2Œ^Ññ…ûÀÿhÏP÷¨‰|\ú–Í%(,{ˆ±|­Sııõ*ÏÆ!4š.ÿÌ)”ìÄèÜpß#·İç%ë0Ñ ÌT¥á^Û§ĞñÍŸÎí«ÿ—ÏıcÍg3ık÷U•53ç!Ä=–ğ’ÈrÁAßîG.7Eå §€æ:¼C×BÔEĞRùb•X¤°‘E(Sâ˜Â‡q '¶×3ó©÷ğĞ‰öÜûZrÈ¯”#jg\Ğ_@ÜäĞ …›®À?Zör	jj“CÇLŞà˜ '”ÕÎyD/™N¯ÇÀ	DY^Ëkşx†iê¨ —¾G¼k	ñM‘f‘¦@¤W¯Ï±ÿ€™§AN’V,ÖÅñ Âúÿ{Dâ:6à¼•$Éx›[ébı1,héÿ9³œ”¼*òNœ<fX™éìü5Õôd‰èFKLÓ]š¼[ùVq=«d”'Zf¨å=œü›;š³Ät¨$öF‹Ê-›şı7ËJ-¼¥·¸˜f{ƒ1«¼Éh?¿4(}¯ ö½±Ô& àïIÃÉ©·Î¸Â‹ß•I,ó“HCŞøCş?0Ãß¹a’û;ó{{Ï`³É(Ñ[õ•S!ÈO ©	¬¾Q[Ì /ˆ€şkäŞŞE¥j5ÊÕeÂwäñ&ûs=/ÖÑ[È#?7 ©Kâ$+n½ì ï}Kt¬©\Sìè°ÿ¥õ[Š5ã@Vr>£ÁíB×û·W;Ù»y[ÜxI†ÎÁ.†»Á¤ÙNC5ƒ;Ä×Q>‹º¯Ê½6AşĞ/ßğş}ÿgÿîÆº6>§o™YÙhif° E<ÚÜfçğIàòqAAJLL	ÊŞ‘É¿.2şû¨Ÿ 5Àù¢ÖŸGF_ıUO}ıÄ¯Øz6·ÖP¸\	E5Ë,-yÒSTBÉs•?uHÚ¹æ)à]¼ÜU"ş»ªmÕ¸‰µ¯¥â‰P r¯°V^¡_n¯="eËµ¢¦–ÈY+ W‡Í÷ñKc«Ğ=B/<öMr•9ÍTÏ,ø^ Ò?X½]À´´À¿Õ:}ˆ6TëÎR¿b€qkN;Ç›2¥°Ù´?H%J"Ç÷I$j´ODtüT'NÙ~J;£ã¹#İïÕü’x=8> Eg=Q%®ÇBÒ]–•µûT×{¿¾.†A:gû2ğSá³Œ^âƒc÷WòÀl(wqQ ~›obÄé@[÷à_ÿ½M:gÆ€lô9ĞM_Y•?–ô—_cêŠaÑEu*±è"!®`Be™¿Êtil»ø	@É¶ Ğ8·=yÈåÉ¥áõ'GÀT~´ÛŠƒö‡¼>¤åœF…k9ÄÙsC©ºÈx4ÒŸ­UoÉ³Cå
aëóéë¬¨R6ÕÃïÙ86u|S‡@tpÍ[é(‡ÒÀ"{V’£ò‡JÓ5õÊ±*©¬t»&Ä¿×ïõ™'˜ŠóÜúpØ'ßrNµ]o™4ê%ËWHaŸKÄ”‹ß V´RpbÜ¿şíhï&Íwµ¬ä]–™*R¤jÁ€wÄG0Ä.J8Ğş³ôT¦gêD™Ô.|¥Àxî¡²ÁÔf^-'pÓœT¾:uw½¹H[/Ô¾;Ãm±¾iNÎêH¹>—tGv+ü¡Ñl8Féñ4G;Œ749ŸRş˜çğTà+·Es!… ìÙ§nµù¼:‘İºF-{ñö‚xl9öÆi-3±|\¨«o9^áº#UqÃëƒôyÿ˜™wj[¬¸·ŠÚUÎìÁ:²1¥i{Ü0Oc¤ùÁeñè¾€Ü®Û¾D7ÍD–Ñ‡èÅ¥ƒÂbÔ¸!²ú _lãŸ*'ß<—&CÌ³™•©d¹ä'áPy>€WÊduyH ˜c•xH<ĞxM}@Gz‚ÃgX§ÀÑèZ Y¾úĞÍç®p²º4¥ù$ÇqA#ŒÂLuóo\ÜÌp!Sw>ÂIÄtåwzíA»… –<‚™.‡yò`%	MÇãNé‘ëìM’³ÊCZÂko#ë2ÉĞ#4BßæÊTÊ-Òæ¿O+&æş‡‹\uk{àZ§dA’< Ÿ`o®FE£»ëË<ÜrùéîK„:0Wª[ß«üŸã«„j"7Ø1~2ŞŸz0ÁP7²ñ'q.½.L±É	qïÄÅyÒÃIó[(bDZàJú¿‚fãN‘Lìqòa¨/UÀc¶f“°½¾;Œ<ƒ7i’Ş!ØÑ²]àW·¯ØíRH³šê¡(…ãº/è¡ıGø)všP|xÃ(äSÛHBòo±0.±ÑW“¾‰Öu¥ÓYÊ¡ ön/é@®0Ç^P){å™wtzø%HñÏÁ[Ç?¤*¨‡ä96ı0…œÆÆ‰¯}JA²í‘?,[[pñ2°öBÁ üš 1j&İÔnbÎÔŒ‡–qÖp	³w‘G˜uÙF%ôƒËÏUÂšxÂ¾yîı{Ë¨X»(°‚¥ğ7÷RVè™ryF~$ò±¨“Sı¦İ!l¦«\§~¸N‰h÷”qÈ•‰êİÛZoîW9ÕÃHDÓäm!—Nèp`Eç¦«íŸ5®n¯\6¶kFà]„ÄÊÍJZ“0¥‰ËpÒ³”ÆË¡ôàóÍº¹„Ü«111cwMäiy½Éò{®¼`û½‰ÆUj2ôzı]j»9	EìYì/ÒÇğŠ¸¯‰QÚˆ6„Ü•Ìİìãæîl ³
:¹‹,vÛ„¸Ui¡xN~;\ê®xº|ßš½3“q¡Õ4°×"j~é·$óàpÆVĞõ…ÊÈ&¿°Ú æL	ªıo*!-StÂ8HDQD>qYˆáà)$Û;¥¹]=zb9 SWNß8i’Ê—©æõšèÂ;QqMa	ûÑğ>ïHü¯ø¢ãÉ²ÈêæÀ@ıN×Ç0¿ÛÒLÿqfÓ!‰Ñ_îŠ%×ğ¶€Pze§&£Ü†@ªê¥T”>&m#È*ã¾¦0ô{5p ÀPWäK¸iB´Ê°BöB‚#Ì œa8Á!µW.™­øP?œT}‡ÂÎeÿ´G›Ô„u=1²d¯®¯f†	ßï²ÿÏüU–ãŒ¨ˆ‹’1Osn!èâò›…CßïÛú~@y¦’ÕÈ%¥ìºR*Ü‡tµu°Ğ  ïgºŞaçc ÌÏ€Õ)è±Ägû    YZ