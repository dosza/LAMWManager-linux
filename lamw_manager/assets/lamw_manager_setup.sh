#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1931539455"
MD5="c9fd9d360a715b32f00621b7ea25c8b2"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23480"
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
	echo Uncompressed size: 168 KB
	echo Compression: xz
	echo Date of packaging: Sat Jul 31 15:08:53 -03 2021
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
	echo OLDUSIZE=168
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
	MS_Printf "About to extract 168 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 168; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (168 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ[x] ¼}•À1Dd]‡Á›PætİDö`Û*8/,›Õ7êsãÉşòòViÌnØ‚ÅÆ;WÚ}”‘¶’qßg|?•+cD:´j¼/ô 6ãª5oYäñvÊ“ÓŠ£ò àÿ«;­ÊØÄÎº«ÓÅD§¯'¸112xjBQTÚŠĞw5.!³Qâ*s”K”¥»àf8ñˆÃlA¬Øà¼ÏpıqòŠt2µ*T#©d¤‚Ìl™!µ†æ:Daÿ‰öj*ôuÔ*”SXšFú¾İŸô‘Î§`ñµ¬RÈ[â-7ré¬‚®©JÎ½|ü-Td	yÔ?YäMs¯ÔiÁ·Ô=óÎş•äš©X¢É’ˆ¨çYR§?ÔJ‚?	]€à$¹9y;:pÚgšÕLô|è.²WÚ.¢8ˆƒ÷SŞ"Â›z¡Ö«ğU;X}BCA½B‰(1áZ|&Ø¾h+B?¹q8úÇ™M$Db³ö‡r©÷`ë-6OğóÂñJScnG	æÊ+­E#+"“¸:O¯¿ójfy]BxHr&´/iBš|˜ûT?ÂTª?t<£‡ƒK›­
şIĞ¼	~ÏÕ-º©§ñÔ½íüI ‹„¾Õƒ¾ª|Á`)RÊ.ñ4«•îGô½ŞõMÉãxùÏÂ@ÚpJÜ(!º°[FeaÏO²”å*_º|£cÍÓìè¯,ö›i¦³À³a¼‘hj­˜ş`le´£UŸ?¾#öe*¬H¡ÈA˜ğ€h( k&‡¼n;€‰£©æ¥±š<äéáHuØ[…Jí·ÿXÿŞš5ı#Dr¯‚HáëÓxvÒ|Šxğr®¯p‚N}ûsÃ¥kBã	4…*2ßP*³Õï	ÏÍ_%£Í1a Œ•’Ù‹P£r«P[æÅªr.¾4ätˆ7!œ¦òï‡®!Fët“ì­WÖk6ù4Ú¢ )6>I¬÷Úa©İl’½É"/= šN°e½Æ·ÇÒ¦aPò·H±Ö$İªAX¿ ùd(‘Z™öğpË\n
p“-¯©#¿Î;òÉ‹HW_›ãçF**àx£ÍæÎõ«´¥Œ[õJ:ğ›NHc…’j#„rxùÆÁ[™øş~Ô!MQ1rª\¯­Ä×›¯¬•‘'·+éä;YŞ‡ĞAš™-kş˜TBØæôw$!úye©¼z­õä¤õSm@µ*í<.X6ŸH÷`Ş†åş¥ë°¬’Ğ\
ÜÆç·(DZ8§Vüˆ6`Å(Û¥<¶¬ ÖüLózÌ)jÂ±IY…}j‚9¨’%Ûº_ú±˜‚”ëx¨ÿ<óü¯‡2r|Œ<,‘Õ'°ÏMÓÁ^ÿ Yá©êdÏQ‘ˆ+¾\¥9àÚıGóÛ®¦Õ¯‹C™ŒwôR51ƒ^Ê-•mëeWÚ8•ƒŞ.ÒŠª€PÆÚÌˆ;Sğ‚ï}»†r-Ç”“ï©‹Ñò82N@&†ï&´¥ÊUª$zSÂâöÃ*m{*ù,2kM9Ë¬{Ê(Ñæh+¸÷e`ğM¾¶ÍiÏ*2ƒ?y7ya–H%Î{ßNeLŒcBT»IÚÜûÖ¨P„Ùyç¸¦âçRiúmÚQD%¼?ª
AzÔ~ PÜĞ¾–G,âR›İ{»V6±?ûa’³‰
¶ƒƒ®Ìï~iæ!¶<µËvù‰¯Î±Çn¹‹VÀ‡ïÃ–àÈ]ÒãSH;Ahş[±@‘{”ÔH
ô ¡×;ï–e…b<êeÁ‚zÙZık‰ÉÂ¦À^*éº¿Ù;2²IÅw¡†ÄÁ}JYó_™Úğ7ÃÕİç—~¯ÚÙ®G)+ß')¦ôµä>e¡u|½iä¤lÎ[ä 2UVyÄß…Š÷ÿ’
ûè°:•ç‡XáÒœæ÷Åùº£³FÇŒ”Qçâ\ûóæÌévUèÇF‰WI^Lˆıi	AÅ÷(N–D0ÖdaY¹\…H_Å˜}l:ûÁˆ)°3tLÄ |´@¿ÜUÃåò)Ì?ZÖ¢©OkyÏZHt_ ñ?
WÚ}îÂ9TáÌëØiºÖñæ|<!øäûJzZœ7—– ¼X6·xó6-]._Ú&[Îæ)‡ëí7øÂ¨¨ÜjÒÂc}ËfBtƒ£!?Oê„#Áié*&—ó•ÖGb*ø]ğ#-­ÓîßÈWéµ”1Å§O*SºæW$ú5Y¹B‘Æ¼)áÆ,ú’%‚°ç½4äÁ¯‡7øR¦b›z.â­Ò|7ÌÜ$Øwö
§ï¬ÊÕÿúø%÷àëGAGVº§â•ÒqQÊwŸÃĞlíÃ¥Ÿ*é°1Àf¥+Ì¼ÛÓKC°Ä_/\ú`°<!`'°´Y¤_6]m»MFwÁÑcbLSğ
—wë5Æl•UaÈY©á÷Ûz]!}M·Lß	`0Ã¹ƒ%<Ó2_³b<rp›•½¯÷|—R7¦ºÒŸš´÷ìn­…•GÌÇÚò3/¾%÷ÇilùL!Éªe)Y;ıZMØ^|€Aòòe86SÛ7ŸP)8hcÂ¯d<i˜Y$‹YÈÈİ€œ<¸ˆnV¶ĞêvıÊ¦VIï$Êßÿj•S£¾¦ä=Ç/c3ß	Q·eyFç™< ñ†m?’yºŠø°–6X4–+¦ÓÿéT”•hbëÕùŸQÚ€]zT=Û÷D.Ês>ß[näczÖÇóÖ¬áª!ûmÈÂş¡ó!Ğºí„[Ô!‘ñ1’©£³XC§Pê·Õ5º.Á0 /“n@Á¥Ÿo¦|”_É]+·î×õöÉ@ppo—Œå„½4É$g:fªá’
­d¬7ìÀĞòuåŞ@Õû.ïî°JJË9e/™™mÃNèU“ÄA•?&˜éFÇqÖQq.LPz2´7‡Sµ˜½¢ß8rV7°Ìwòl„rÊ8úNYÉà£„ˆıÌ7 ¥Ş¤.¸“ı¢½â­n8¨O&—;÷;×sÓƒl bfË‚7Ôò}Ú>Ú¾ÊÒµ4+Î°¯`LêŸF‘`+£ª÷¾™õíáåMr^d&Ã²©d*_ß³L‰™;mH,nd}¥”íou»ƒgÙ"ËÍ;´šËğ‚^Q¤ïÀÁÉ%©
^æŞ“¶bµš»CQÑxP„L~V¶ßv¥¬oÔ–|ƒšØï%‘åÑ*_b/ÃÄÂWıs„óØR„ÒµQ‰´g ~ÿÉÁºœv!ŒoIäJl Åå‚SY¯,;03
ÀVy½öv‡"Œ¢àE ìóótİDëì-jÎ¶[¢ÒÅÖ8h…)°m~BYëB èDK–ˆ&ØmÁ™šwƒTèšËpBu
ˆïÂ~––öh	³S(›59ÌB`'ğB2bì\îÆÅt€İÂ5Ü(¢ë;vFmôƒz%¿hşLŒººQ¾d‹Ú¥xg$xÍÓ2ÙO6ÛÜfs¯Şç’¸sŸyÛù°Î*9Ä¦Z‘ÚnQràÓYQÓuo$M~T…­æª<›¡[1ëò<¦y(æÈ™ûµ°’i5ËÖ%ŸA,ş—UV÷ÒÀù c³,êàºuës4SG}Üe³wï˜
ï0h+«¦I1ö±'*Bè]¨›2[Uø;×J¹Ú[Aü³US©ÒŒ1L…ÃVã$­«‰à8q·M*FĞ$LÃ¡ş½K„½,»¡)€×]-s¨9õJ0Yô9­>şóc¾Î4³çÒü—^ˆ¡ºülì76*zè…š:	œ&nŸ§·©§‘p`¯}õ‰í‘2ù|x‚2gz¶³0B­ØğBU íN¢­•ÚM¾Ì,Šzë\G[}k®V%#4(²(÷¢§ŠÈ$)ÕªEà€ Ú\¿€–'ù÷ğßÉ`kO¼ÌËÌ– Óú`#<åıÑƒÙgTÎ˜12ĞÓšßD1&’…ÍÂlèçûûéé*)Rb@dªLÚ¨J,Vş™ID.÷›´z¾®–ÚÙ­zš¡âhü/ô7¼ú³ şN†¾ SPÇšèÚ5aåjÇ%K>Ãp£«VcÜJ€îzÒ%@–	+N=fıøP>ëU*ÖøÙaJŞÊ‡$Å5²pÔví˜¸ø-ë­áğ°Êx|,LAÙ“• ìñ<qÃe[ÉIMˆ»¦˜H¸S›
­Fğ»†cJÓ¿‘ëú~lé	^´ËÀ’ áÑ])¼€d$É–'çoENÃ¿w.Uqnybù`—yˆLôJ|Âÿ %¾äÁ©w BŒ@VZ€ê÷³.ë0=wYÏtÜ}äÀ@²N¤¾X‰¤Ljç®š	ûMi'~ÔxŞÿ–s6«K5e'ç69›+ç­'––\m¯ŞrÔ&ø8æfù¯b®4Gêá¢¤òÔÜ ‘3omºW<c
É¬º²â9–?ú;µĞÎSò%Ôk5xÀ¥Õ<>'Ã·Gx	¾_Ş{	ˆ®ÎøÔ@¹Ë[‰¡ªvbÖ?-§Ña¯bÕs–~§KŸwœº°¬@Ó!¥`EEíÌÄ¦[iáĞMÍ2|òÄ;Â€ÿ³p¢!ñ­|jîùøknŒÒe“C˜à|¦²0Ô­É%Ä´Ğû²öF¦ûGÓ¼e¯W_Tšè5=õëÃÌÚäû¸0U}µû¶“?v§\ØÍò3ÿ_*§
ßt–°ñH6ı­=
wr!Êİ=‹ÖÕúA½àÚæœF)ë*L‚ğWÊÊ|	ßk¡mc^a”è¢®ĞWu hÆ¦T¦•öÑò!‡Kv(¼§mt‰)³ïsŒÿ8›¶³I•éªx~ûíu™;ı6…	¶bjZÈøûï;ø{7 µê•ø|?oâµØ:ån5ãPj—x²1|¿Ç7Ñ­€‰>¿!FjB€°³óN =¿)úñratj	¸Íu¥uÊû«˜—«ÌV{?ÿ$gâµkê‰“ÒÃÇP„‹Ãê]Bf %ÍÉÀªÕñ'ÏW|µlãm^Ö İsì¸¨7dì~î÷1í‡Ô‰	Åd €Ã«lfZRË¬—–qNÓVÁû+·^[%ä¯WJ&&~M+’@1A#–¢ 
àh“‘>“¢A§Ú˜;õó½"ıT¹å@?³81BÓ7™ÿNˆ-@?|Öá¿ìª5£¥ì`qYïñİ/^Ğ$ŒØÙ£M‡"UÆÇÆ™4Séeô¦R¾| OFØêkApïÍ€yzAaì,C¸9v:ª7ÄA-ÉX6óœõ]Â~ğ&·ô¹şŒ ÜÚ5à=¢)©Å`6D(LAbÜé·•tíêçS^…Ø–"+Ï54™ÃI» ùœö-ä6ÿ%+ãÎÓYÑDuR-›àò#1ıòx^f«Q‘m9AµÂtã§n\š›—¼¡¥%
§İºª'éŠÛ÷
ûRFïRáXS˜ßìv¬
¤Ãî1]«Wj#Ñ  ßDÑSÿ	k€§{ @õÓ-¶:i«œËºvŒWÍ~¨Åru+ÖÀUƒ¥	Ù|Sf”ÊTV‹åhõ'3A{c-`Wr3~(Y,P$ÈF}FîŞ"|ÉyÆÒ	<½x[a|‡…ùÙµ•jïu)üÉ¡Ş¸!ÔğÃçñƒø–°“1c—RlÂu6üFŠ¸ŒX÷,2ŞÛéZ³NAKÔ³ˆÑÀ[…;OŒ‡fÌh¡)I¤ö†+Çéš)®ëŠèX]D5ƒi¤k ¦¤zî+3k¨³¿5½t¾„²I(O¬–Í‘8$vœÃAtÙù‚ó¾_„ShAAWqè>“8İ†y–9’H<jR6½Ğn«ş† rìı…S¦«Ñ³A„˜Şœ4Då!|iÇ;w’fÒPry§¾¬¬şäœË›s‘ÎH³JÒÔ½á§Ä•oyƒĞûÊ©“*\‡„›Æı¬òÕ0ÇŠ“BşCûV–?´p¥Õ7PÖ‚4}2*>‚hD'>Â|ü‰~¦¼‰Gu~-ğ;Ø7µ¯I‘ÕUæªô1Z–úGC7î¶Êƒëb44ê¢)‚¬<ºnb²òæ?&ëŞÿS3k"£VEv¤gÙİ\cJò^°a»ÇF6B‰ylßs¬€u7V¼†Ymİhã—ÿ¶üz/B
wô(ŠªOËÎküƒ•CÎİt²¸Ú Ê’ä„ÖÛX%ÊÂ7swÊ_ö´é1ê³I‘`ĞX§“AÖìOÇ	'× Jmd‰u«¿£fÁy–€9 É£é”•¤ê¡åDùÜ<kJĞ„W–®ª³ VE| &AÇ–öâÍón¦eîNôÚîV!bà¯ãÂ˜ôå»Ì6ë•œ}1pè6j){çİ"İÚ"p´2×ØÀ&ª³5&&H™^œ…EÌ6ßó2¾ÀÆî¢{î»êúSÅwÈ6×
F,~¤ğä²Æ”A›<gk)uLøæÚÆ‡Ú®ëGÉ3ßåà¶İ”=›Õ÷ 0WÏ/Â±²;} +-L#Öös1d·ç…V ¯æe„»Æ‰‰»ÓØ™ˆ!ğ=b@%	Qàl¶ŒpZC¹	Î_ÃzW'
^ub–CCFÄ™J‘UZô÷y¹ôD'cÜ’”cLÂ5uÍ¸ú2Œe¦òŒ^¶I·ßëX[Ô°¨*ªIQ:÷ó³ƒ| ‹³»M¾ªqÊØv–Ÿs¨ÿò‰¸¾´ÈÁ{„ç9ş%r}gVÓåãéÒ¹î³oĞ¥	˜=ë±ÆÜ¿H7Vù×Ï\$.5Ôy#Ğ–MfqTÔ+jÌDÃÔ³õîU!åá;ï/FÒÚõÓşŠzå|v4«u{l=3<öîòØpcœ|ã>Z²¾|/Áö^h˜¹õå™—#()*SûÉ®élüö™4¬­ÑÒÓáñŸ?£ĞÌï¼Jñ=ÊÎ§£¬Ÿ†—¨´6
?Ş2!ÒlîPcÊøWçÜpû—§¤ÎíõÑL.kZšÎW$  g8èlpŠU¨SÚhÊFv2gPõ¼ÌˆÎä–Û€‘~_£½¡äİ#bˆFM€àŠÑ}\ §÷ÂóV›¼êfr­<)·d£a}*[Up<øÁP³äœW#İú³±Óß\1š±CŸ şÿ'b»Xà£/qçœ‰p%’äå	‘¿¸¬ĞÉõ_®,ÏJ’/öew), °à-Ói¼[*çî_W@¬9·µajİ" ­ÿ2NKHô]C¯ ¨­j`]Å!XkZšæ×2‰Î«s'Å;.‰[¥©‰J–%ßµ1?·lr×ërcúlš$»)¿˜¿:ˆn/Şë\sİüß(z!xÖÿêşs@˜£ÏVÊUı¾C3¢›–;G†Ù,Ÿ¼Ã3M¸‡Ãêhv%§éxî°ÒŞh4	 †"ä&%å‰Şt7®§
õ‹™ÿ›¸Uj>y?²n?L’PEj·n÷•¬?H_}Ğ%Uò/Ç`IèÆ¦Ü0) hÍI”{H*ŞikUÀfCğÎÛá„ØØp¯kQ’³´+ˆƒ8Ğ@‘İÊ'»BKúx‡±Wñ'£…‚72{EznÁ0îÑ©™«–ùÄSWw[ÀûFñMœ®ÀFŠÑëÑKÕ¦Ìu£õ¯¢8(Õë9$Nˆ·¨EÁB¼ó5³×æ+›¥Œ,œÓèW×g§yë×ß»áK$Çg¡B­|ÊŸ¦-3­1ªI^@Ú2<lMù®‚´0uÌİ§åôq©Üõm©áLz\<8¹Qm«JOKŞs¯y89›Ûâˆ”ğ!ô¯9lËØïÓYş.üEsë¾£Tî©ÍvºaÈ· ¬	wkl¬,æŸŸš”1Ñ5&Ÿ`Äë;¥—ñ3xç’7™–—¯‡,È¼e™ÒM#–¢)Um‰‰âlN'ªø8¾“D¬ÍJ&·ÛLST²àÓ”zâ¿	TÊÁ#4ÅÎ EúÈƒp˜È"Ï`ëœ[½Ãè«ÃÕú˜Åª¯"ÔÊ”²eµönÍø{Ğ_ôÄRûä V„ÜÇ¦FWËi´ä!Ğ»dÇÄÑ´_QÔ›³Q „	 êÀEÃ|P2 Ù¼™k$+˜`ŠßHà|{®FbĞx· å§fŠõ8Uı@­[4ø¦x©€TâÙñĞælÃÆæƒ¦Ì[Yé¿b­¨:«Äñ*T“5²CßpXHèà}5ƒÃvbƒ:|ÃX1{òü5ghØéİuÕUÂoÚv«q ’>sô/^«C7âu«şWûğİ.‡c±À«¦bTQ\Û°ˆç\Ş¥<EL±Úÿ™DŠn)–Sê¨KN$t
Ù{e+qú‹|È]Â¥QÄÈ‡	~Å7ËáäÈ/ c\†®rzs° ´¦ùKª»êÿ{såÆıì&ÜÇB¿C…—ˆnI`ÊøÖ²¡Ùğ\ŠDD†‚w
Ò&TåÆçÓÑ»0 Tº[FÈp&ÆgÓÓğBjS?ZRîöÃ±w®éÚT›Ò“ü5]°hOÉŞ¤ÌW—©Ã\·h–ü=¡îºŞî˜!Æ>¼Ì¬Æ’GÛ¿[8 B'4ê3|É P2æ""õSeTZÍ§~K>ÀÏ2Òz5Œ ƒtû=(dÕ§Ë ¶¤Š/ø«ÖâM]0Ô‘4Ÿ¾³"¯éÙ
ÓÀ·¿zµ€au-^UGsƒª’`Oäª„SË'7}§g¤ş©Å!# xTÍp°tnrãunØzâÚ>‹×xN¥`ˆSŒ‘±¦#¯ÙİpÄÎ? ¡]©bL}ì}Íúï¨ê¸ÿÌ‰xË–©ì&~f{ğ8ôC ÆÄöÒº®ÆA:L<tX•(Õˆ>õa¼ıúL =vÖ¸Åa“ğ `®9íd~ró¦‹Ã4ˆÁC+n:§á£DØÉÊ}q†Õ,‰”â”gŞT´N¾@Z˜×Ä÷ãz’'^;ø+ªÌpìğœK8áŒ$X gµP>g”‚÷;üÔdÿùzœŠ:c5oö@²Dıâ€RñZ#xî”Ï:¢Mù•0ˆª0âmû«ÇP`hPI*R 6è÷-ªUî“Û5w\gÀ½aêDgF¨èæ:\ ã¤M ^]:˜ğ÷ca
ŞQWÆ…xàÕ(œÜãéÔYşì§*?ğ_X\%P—ÆîÅ™?<o*^è»Øv—ÿt‘½ ¸!SëWmÜ§ğÏ¯û+?›#&–ê‰V.$[WúúÖüd ?î1T€L)ñÄË’¤aÅƒÍo „I±È%Ğ¼)Pü?YgøDo¡ ÄÓ¨ˆ.éQ·¡‚ÑgInLöÁ—_9¸;m¯~îwãÕQ"¡ıàön3U’ªˆ¦O#	ÑÂ®4˜´g&?|^z•)šÈ÷trbƒŠŞ¤B›~•¹a¶¸‚™Is‚Ã·8şé…‰Øsv17~ûYÜyÍÈş“œØ$y¯Ñp\ 58½×¼%¥I%Ûó.Òğo¼êË~.Y˜=•¶é–~½Ö£)‘:ÀƒXewŸó2¹«ØÚe‡Vr¶úßœ‡Áléqú_³è
1ƒ’2Ö¿™¢E¬²Ç­}ş)Ò‘«àÖúçh;RWëBœÇ î×"É|Üë+­´5|ûy0MryKCbòºš–Ï:Kp]ëíE‰ò¶ò ¥êqs;ŞĞäöScÜ#|ª½Këñ¼Køáübó|¬6Çä)ÜÍ€™{Ë*z
LÜ
h¸%EsÄ®w|«{Æ!õnè1ÍÛæº§pV4ÖÇq’•švÿ#ï¦ô,”V„éUDM¢ájZyÄËQ!ŒÏÈz!9cps·©ô£=Ç‰„SœP3¿ñ>ö×5ndìtHİ?Êm
Ñ+ô˜È\-C˜-ì-{Ü÷ä›œÄ7”D!ÈÔr.cº#şËŠû?Ñ/… XàÃy…›¼½1k'l³ıìr†	Va¢»€Uø1aU¯|²ô™bhù"ÔÀ-…&v¶ïeÊ_ƒSşáÏğd…ZËL_Z.Yî½Œ+‰íşÍßlŒÏ-ÓZµ$ı“¼«÷(É<cÃ$Û™f9(Lc³’ˆ³g,,@éó™ö}ÿë]«^…gC›{)9
É©*˜+[®í¥ÔvÌùE§qQpĞ"»„LW´½Å¦ ïqÀ¼£úÁ™ ‰DEºB_—Ğ@.¤Ş²üó›ë®vô1¤+-Šİ8İŸ,=Ç„ˆÖbÔ}Õ|.ûk°©£ÂbÓ.ı[1+8EcmÖ„…#9xè*Eİlb<ş½K]³mŸL³ÿ‰W1ÒnåÑ«…ÇÔ@š’ŸrNgrÑ®ËcRh	å(ğò«¡r˜9,Lñª|².­³R™y´İÑÇœ~­9*›ŸHYV¡õÿâH'~·¡»¡äµÎ¡'®· ĞãÛğG	µŞ{a“W	cpŒ”o0×@ì%ËÍöÍ×w#¥,ñ¥P­ï.`§›4¤ßu0áj˜>4¬®	r÷2†o[`‡î
ú7.õ«°5S¦Ô§Eç+oˆ˜ÑìZqò—I@”C¿úwDà%¸æó4ĞpæH…Õ
Ë(]{ö›»£úbINz¿ïµó=)=J– Áq˜¸2õV´½>a#ºI©œµzP1ÅØgëóåH$=Õ¾ñ} SÆ8ï™{-Ùò„ ¦:‡
täÍÌ?ÚõÌŒÓ–ãI	}©K¡ÿüLJ§k¹·ë¢ÑLaâüäPŸà¦d­º»÷?>#Ìí94š¦¶’ümåèV"­®.ß4áÑİÛÚ=şHršğ„ºï˜´©ÒHËŒ_µjÕÂñŸÌ	YÄãA7œ•2’›ÂÕˆî›+
1jy×Ÿ/`QßİU1}	Ÿ¥jÑexñ¹Ñâ°ü<„»1ŸywT¸…Œ®„TJ»ÄÔ™›n‘Òe4ŸïVxD¡ÊÂÈ0ÃâÈÄ«T8hÊşö|B«¨0¶ÄRˆ¢õ3öİ=Ç¡S¹3®/Û¢ Ó~0 JksêlûGû)°°ÍÄêÕ½&í™â_yÅQÊ¹0™V:ÅÇ|Ì÷–s‘ïj2ÿ¤°,Áâ­®ÏĞ!è®"ljy¬âL™¸'¨ÓĞ°R©.şÀì0fÇµ…@º°%	RßşiÈm½×e0…?K&5‰·äa:Œ(;ãßÊµjâF["Š“ÍÈuxcŸ²ÓhÃm;:fÁñÚX™k™,@©¦.üS¯F'Å¬vÆu¤ÄùHtı½#U5‹Š˜ìõôş6W7²*÷¼„Â0øÎµ¹§GéD¤AÍAÙmµ¸»Š¯ü}Yd~n"k[•BEæJ„@Ú“çldà*\Î­ühféÒü%°¦q(èº¶!çZÏ‚sïa¸ÎáĞ…¯ıU¦ä¾mŞ#êÛø/iØ³ÕÿÉ«c¦ÍMvi•ë—,‡¿‹œ}Æã{C§×¿÷Svp
¶ÄßVPjÄ™$õf/ÿ [‘¾‰yl,§;v/Â`qU_b¶~•-T3{Š «š
r˜w«Ãé­«%ã*Wq*û<¡îÌ®øqëßÒw÷“ólØ¾°ãÊÌß¶p¡¼q–Û{Ù Ğ‹!FJbøĞåºÂüX¹‡Ü'ÂN®Õˆ#ğ”åÏ\9ŞÙ#Hèì“]µ—Úş´@
nX)Of÷Ø¥©IL|ÏSq9ïF¡aš)µÏ'’¤À,dûÓèèÕ‚KK!¢œé)"&ÜM'¸Ÿ(‡Ê²{w‚S}>Òƒi]˜K4{^à™Œ¡ßÂ’ÂŞ7§ÃOr}^5Òù¬Í›ø4L·´y(Í¤<E+‘/ªàêvÀí(UØÀ½Lú¸BÄ÷ÃO êE_8}H¼õ14{Ê[UÃéÄ§¯˜…"¬ ÎrÔØ[±$•}
ÅêöÀ‰¾*|€Ahı1æIÇ0Ày·b•£}‚×Uw¡}i“RÈ2FÔ“ã;øøIuzÈî7Æ}Şw HÖ(‰µ³7áƒÔU$+®L¬§$Ø1f:¯_°á³¶xŒèÖr»Im%¶èÖ€p @MU ©-Xå2Ş:ïõáp_ËSãı´}vO€r¶oï¬PD¼-J^œ³[öâSHAmÂ©Ñ¿óÁLzvø„ ¦TŒ2—ÎÄaµï	)óµ.E‹4(0é‹ËCà„¢]£¥\s¥„”s‹æl©¹³ÉÑ
+®Ùí9º5ew€KáJ]_ƒwÓàWÁ/gÌc'eIdçIº”i‹| ;ŞŸ½’[›~X¯´(éÏHû"k¼ñª+Ş Ç³G40{HÖu§hï›±4ÇÉ•ÂVw:¡Ñª’¯ğ,`pï“¹G˜óç‘Õ4"9%1­¾ä˜å6Â÷ûï[üNZB’îh2ÿã1È ¨üÆâĞóŒ³ÄO’ú4\ôşÑXËüT¤˜W6Ôš24,«Iü–`|~ %3Ø\¯’‘]0Ÿµse
‘lÎARúÿ_ÖŒÎ¤dV'¬Î²bø¼Úœİè°gèuEiç=9è–5Úa¶­ïàoñÏÁÔt·,³¼ñã´8—dxÌGìBiU0rEV`g¸ƒ¨ÙŠ¿ía[eÆ$O¡UrÄâox§­ğ­2B¢5{ÇÜwäÌG¯l“M;ÁZyÙëb¾Ğà¶’‰Û$@õñ»˜Ïÿ‰‰ 6£«GÔşoşó¨W˜W.IÔrdàrÂ)šĞæ®‚Æ§â…Øßj|¦oE;)£ÚEØWâH—”–
SİÌ¶_O¥§ö/Ó?!İPT_Ã`ìb!×vFAÃ8¶’ßÜ6XoÓ>*¢°±‚…Û¬g-À¡1ÜÆótÊç–§:ÍÊŠİ°#câfÓ¶ŠŒ
ÁÙ“½„áGçLCìõSBL…_ê;¯êínIaîØàRç¶ü’oà°æ$¯á¨“hÎ_½²@Zı;X«D¾(…—Ú?‚'#“·ÚŠyÊ¯ÍeÓZ7º1kûÒZ6•ÊAÿı„‚Ì¹§¬¨ï}SåŠÉÅ¹•ië1%_³_Y¸$W˜ÃÈéŸµN
6GQ '`å÷ˆæOûÊÃ+ùğa¬ƒ¹¨f™K—·§¸ÎC—ôã.1M§_»µ–9c•ô‡MõŠöG>T‰±ÃH¦Ö@Ğ‘ @¸Aœ×wV5Õ‘=˜WgÁ§·öä•øœ‚µ¥Áˆü›¡ˆmre¯9ê(}m?m¢TœÁ·Çe«aéèìdŸrÕå 5q®
EÒz,°ëÅÑU9 Ææ¿¯¯˜Ü¼WÎ¶Ô—+·d%¯FÛ‰mšhŸUelêmIÙJ…]á¬tu|)M|,GìÆ‡‡™Så¸£íy.(ï?0ŞFğÀ^. .I(hZ‰i§	›wP
Ê¦”l×»ˆ¯-o¤³GbXŠÃ»¢Jì|Y-\…DîWjœ¯1bö÷}£Šƒxa$1pÉñ‘»BÃxu'JhÆş3Ø
‚çnÁ¢W?c‘ĞÜº›4Ê¥_Ë«Ğpı1ğ÷÷£™{Ï™÷X£ú–U-xşÁ”F6M0?÷ªîríMù„h`şu¹úGßÓÙkãÒÄ…r‚v6”ñ£«÷ëö6 ·ŸĞc¸E&3Öäƒh’~¨ÌjXğ×M˜LÚêC(Wøã;1Å«¾µ¦ì„´V»« ÊÓÇw-*õ5èÔª–XbÙêÀhª*â‡ÌÊtz¤i¹Ã´­H,¥nªİŸèÂLÄ=ØõÊ¼Bà>VfÜ&%®G:%k¿9iJ–û—ÿMlf]ûgù›¯:ì2ø17H[+hùı–š²“ªÙ0š¤â3ö‹(@şË‚]8öm¬úp‘ÚQ
¡ybSÔbÂEbµÓçx}BçS*½öÔVIbf,Nµ°4e6i4rıèÏ¬™~ß€âNÃ„rv^ú\òX»7RYk€'b,¾Œo_Š×fWó,ÔÒOd·FgĞŞxNÕóë‘sõˆRœNŒ©œ<ı%f£‚ùËá½UKÅaLíÁbXDÛCO¶’Uªò[ê/2‹ªˆ;ˆr‰PàØûüúŒº¡í[X2ëñ…ôGP´f”ÿıÄŠÀ¼g{E#&ÿ¦?»,ĞÑ#›å÷®'©MúµsÕÕ;mzD?·Ë„0¬9ºŠY2šGÅÜÌƒ~rÜU–s½È¦f²TïŠPVZV®%â… †­rÛ!iÑ·Òõ¶û}‚^¢3ÿAí^ßşøû‰Ë¡L ÈzÃ¦mşó¢ú¦ğÆy.+/‚?4Ñ^tÉé:À‰kCä¾¼¹ñú4†wB'c€”\zÒ†r’¥¯¼íÚ×[eb êW8;å;Ò=(ƒÎ†¸	ZéV‰ş	kõTõÂ²>¼‡Ö»°j»iÿ%mW°£ÈÇÿÛ«n©ÏVÒ|¹kLÇ'@¦®†v|Pùàzs=\e€_=O_«)b‡íÎ5»yjÕ•D{fë¾ÉÑÆŸaùÍ[mÖDOõÊr¯ uJû^¹	5Ëxê=Ğœm
_^T	ˆ©1 c)ğ–èZ™F=J4:šO¢¤?¿÷ Ã™íÆÏÓnÊUËØúY!¦MV4óáš#Ë;€têÂSo(å
)3‚òkBhS,ºî9 àè$æ: ¥.xCèÓ«Ò<`é_«’íb(–Å_æ.¾C2øÅôa®÷2´Ò„'ãÙh¬í
.¹}Ùz§õLG—ÅÇ+T¶që‘¹­YÊ!ÑAÁ8sÄÂ.æuË~M0t¹b°‚¿I4xK‰°ë6¼”B×Š7¸†&Âbå,ğ)ë‚zËN‚™'ukcônVn°3Óèu˜ òC¶<!à`¦2ñ†ÜÄ%KùÄmˆÛÑ‹T‹—LğYVm
ãQÅZ¨¹ší»¤Ÿ¹195ÏZ|]È°	Y`÷—ŞV*çŸHW—óè¾_×}M]ål]„T’â{¡ĞnP'5b±•ıïÉ•XîÌ<ØŸ€Èõ*F³>P©KÄ¦ül;«VïIš¢Rv8ş[aîšáú¢×İ¹M¬øáúF~Ü'/Ã¨õâ¸Lz®V
0djSºÑş”ûEö”¡a?oÑ¬E
6-©¦ÚÔt/–Î„Çê Ù4êd®UH‡¤å{SÂ^—W9 İ«Ì²´ M^TÒLbh"N‘Á)N­;kÇÓÀ±µ ½ÎO6Ò¿¨F"EzŒ&Be÷í]l¼g·‰nûèïE!©_Ã¤H\k#âÚ¶¬­+#»/râê0îÆß9W@N—>Š7{ø}%u¤eà	¤z®ÎqI¢ÃE‚LÒ!`EÉeDå7^YŠŞ¾Zšº!n*|‹"CH2‘€ü1$ØŞpŠXĞ12Iv#øA¯p±(ğ‹æ;)÷°%šÇ(ß`öÒ×n­iÃÇŸì.?ı´­õ*P¨qBT¯­h¬4ÿ/K~ªw§%ÖÄ#
•G–‚?1ÄÃ:¾Œ¨=°ó¥ô!Ïyh=Û#2W–Å_ƒÖCl~v+ 1KĞrv›&“İZÙ|EùğA9ÑàïÔÀóØ/÷Â—B¶bx!­ˆ‡@‘FApâ*4Ø#ZDn6Èş×Šç:Eé_]’…5¯(élÕµÕµI`®BÓŞCÑ‡œ«ù[«»¾÷sª‡)8ÖÄyMÂ×K¿{½( Ä÷p¸Es“Mº[c±ÍÛ†2„¯Ä†¨Òså£ˆ„ñS7ó2q)ÓæÀhÀB¹‰;ãJå 0\>ÊßÔ=<(ñ0T4&¦âÙ[Êi–D>¥Ş]Ç}öm§©Õ/£+ñÈÆÌ)n™K¨¤ÄZRO¦úù<ıĞ^L.ş¬>IêË)'šÃ ’¾´0‡æ'K¾Øc–·Õİ—a¡nä¥ı]^Q~Í×î3W[rOqE;w?mYZH=ß/Ï˜÷|É6á…è¨ï'ÔÄ¢ß’áÎ‚­†E"n·&ó9Âpmåvó1NGş<4¿½±76éÉ*İî	Ü
~ìË³ÒeNÑ-Ş@¾;3}]Óöfµæ·ÇßvYÅ¬Ô‘àLy™üé‚hgğ&ó)ÊrÖ‹½3Ûªu-2X3À:a™¬Ò@á«VQÏ]Gö`‡7¾ÔäfºÒÕŒŞ¶å·Ò²0æfƒ¸À½³¤ŞM?ªX½"ãV®mÄÚâÏº<Mìó‘)+W¦ïadé$ŸèúĞŸùöéj¬ú´gO,˜0Ñş¥ö€<¹ˆçJN%Uäø¯áz–…ß‘,Kû…ªÈ¦Èş@oŒ=t Q•Í­İá9 ~2|íOV&/Oƒ(å–ÈÙÂÜµfŒv‹MÜ—îÄS ¼ŞËlH¨O•éBNîÙg&ŠÊ¥àÅâ¥>™Â>r§ûÒI1t~àå¯q®ê^ud.øóÒßØkXwhŸ“/ğ¸=Ô¹Ôñaa¦¿dŒş(tçÛ‚åeüV{9˜ğ”uÒóTÖ‰L5'–Å+–Qş¶·rÛ‡ÏRÚ|J=!3ÿ.‘s,€ø(suæ$VëÒÕûIªÁzÜ¨#9°ütwvXcnZ™E1ä­!ö¯µ~PÎcIâû-.ñîA38ëù¸‘çE=ÈÑo¯K'ü9¢dåÙ]üåíYà$OvÄâ´)çu¾,X–x“ ˜½ÒÂô½Ô¼±$å'q<üÜûOİ¯Çå:‡ƒP\eŸ¢¿Ã%½şb_¢/OÀ_ULÒU0Öõ€%A¹8w1Ã×$tş´±©³èÎà‹©ı¯òßÚ¸96‚H¶,c»6C”Dây‡¼Ç%~<Ó+WZ«œrOø Æ!Ø*c¼Ùºè9o*ò_:@`‚|f½İ*Şc¿kiË‚Sx½QpC'(˜YŒtP\@ñ¡|¸ÕÏ)üş"Pù~´4êLWX‹Ô&@jÇ«í{
cî–;é{š¨tñ˜~Õµ¾İåddZMÕjÚ\¨å­oÆí”uŞ‰‰şÏGQ~ì]å¡5•¯†ùF!ª8\+ŒÁ–áJªÅ¿G}¨£Y:Ç«²Xï.°¬†ö;Gn6{Äm^D°c£P2ÇÄÊwîÜPE W>{‹ø™ëŒ’E\uL;?5 Ø[hVß’‹¼mŸİFåÅzd¨Nã”¦°Wù(¨©’SŠCŸíxnÏJ®*kóÿì¼\;o a’°’¦I«NÙ ÅÃ4÷™¯öÀc/aç:½’cuf›Oï¹JogÈÏ"¢x%ìm@<]–¤7yÊäëñCoÉ‚¼u¸«ÆºKN
k.òÈK]çœC!C‡„(a‹¹mNàĞß¹Üëk»RğÑN>Æ\IoW+-‰lƒ£ÅôÀìÔ©Xù•"”T€õ_8úmÍ†]^¢R÷Ş`îU/jÔ§Jè7øŞ $ôá/2\'¾b«ÓuÅjàLJ•MB¤Z&ŸAeŒ¾’CÚÙ,"iÄÚ<áù7egv¸w²¯LR<¢‚X§ifEÏÙ9+–ƒ&ûìË)Ùb[ÍK3˜91h" -è“ª´îbƒİhD	“[Sî¶ñ¹È‹×fê“$XcôÍ(Xê§aı)3«’•ÍøŸ´ËŸªpú,GÃ­fâšİ?É:‘¦Ò€¡wa©«9¿€İzÉ8üÏÎ½"n@0İW9)z×k)¡ Íã=§İŸÂİõË=Ê—(€ö·;¸#h”‰ì+¥®àúJìE+Ö«®¨» K{÷,‘}è+«FFTûŸ’ÇEİs$×£ò¿¾zB´ÓûŠ(âk¢h1z%°¹¾TÙHw‘ÎV¦0DÒÅ|KŸ	t–6ùR«ÌtX¿ÎäÚšşt'¬Ì-çiìÓ°—T¯!W=ÚS‚ô”¢¯Æ–ï[ ótX÷óe9w‚0¦}Ş'%ó˜¾?ç|+VJ[l¶Åk6.²=Ä*Ÿ" x©¤¼ È¢Ÿü¯óân¨ê8C1"*}h¢
:«GWÈı2ùTV`ùøü<“
JQ¼†ØB‡(ğ3í‘÷÷rÔUI¢°Ö“¶@q	ßP*k,RO¶~Ó}^]òÆÏÈÛQ¦7~ıéùmÌ!x»ÿ¤›ûÏá	½NZ÷ÿ›}k3 H
 ‚6»èIçìºòš‚Nª™ëdW3][h}€3»ô‘n*Æ\çŞ6ÄR;+jòœÔğpÉáù}ã¬é.äø—¢£	Et ¼õAQ™Õ†]Şuú3¯ym“x‹ş¨EúDÄ÷M¹Gwc×ŸÚ‰¸êûÉ©_-?Ô3Ø©A8rç !QíÎøEëÖ3ìÔön·ô¾YåùŞ‚·æúá*‹
EÂ]­Ú=	Ûv‹Ô[CÊ*…†*vœ—)ÿV+NÕŒhñ¥©‹İ,…EÅ¾¢½ YJÄ ç²ãÑ
›I”å¬òYÙÒBB³Ã3+AõÆ¾TµÕ(^İÉÕĞ¦miWèm4¯W˜àÓˆÚ•„ä–Tk½Ğz	6ÅM*æîæ;¸ƒ°001 Fšxb,S4†“Ş¾ÿİNN×’_å}Ú=MHa@Ù+¿4x¶é,¬_1²¦û¹ƒÿó~¾ğÅ˜#Ç±E‡
3ƒÇ³¨+Ø{~{Z{‚ôUØ‚“òŠn¬Ö*¿¹N†ÃU¬àzÅíJ— Ä"gË°ñ¼Æ§lÉ9}%F'ßëë[Ox
ze…Mú\+ò3W+™ç6Ï›ğD¨gÅ-iJõà%…ûA¶mÓîÀTñw°ŠHº¸-m¡ZËî½Ş#æ$3¿wfwö"é_¡D¡‰Ş,(h/\1Âë2r.5ôñm¦ízáğÿç…”ìLDå>g{pE´‚QÇ7šSätqD	üÂ]gz-ÛåXE­îX9èFüú©ìvÃsÁl	¡‚°Óªï÷êEçÈV†)l 1ØF—ã¿¯jX…Ù·‹|gıËë{É„ıŸˆ* Jú©BQÃØ¤¨5­É*™å4ùÛúøVgO„¹€õ3ìV5Ÿš¨Àv>Û»f{Ü†1~¯Ix;èUC—ìXHpÁÅX‰H$°±=ñ¤×jC¯‰ÿfQ;ÆC÷N¡ÂæW°ò®%€Ş‰u[[2wêè€ zufÛú…öƒu5]¯?¾Á,`«ÀšÀúÚ½ªÙ<‰X[åÀ€nEşéoÀÁTl8$w·i-±MÅ´a%µµÍKà–·»bÊçkçÉAÜ´²ªØ	kylÖ×ìaW†.W[ymc¼qÂi"!ğİ÷)ä2¹îqzöç¶w-Œ˜{»@‰#TæÀ—7ÈlOì?k9·˜BêÇÂböÖs)©‰¡üÀ5ôã‚ìÉ«ûrWº«m>ÄD5‡rÜböê!mP'Oşó|¨šá§¹cºŸÌ1<¢” 
!p[€âÌûF°;“W³.};-7Ñ¥†Ü]€u»€ví
‡ôàšÜĞ~hæd‘@ˆ¢º\Ó´ÄÀà}r?ÁûÍ{~ÆÙK1ÂÚ¡#b7[hÄ¤¶8~r&WítÂâÛu è¦Æ;<11AšéÇú¡êKw‹„ ÇVC™}"dÀ"Q ò§¯;¿GÓœ£¤ÓJäk<´Mß{¸$&]ıßí}à¤—èEĞ>ÂjÆçD*cÎ.‰İËùTEÆ—(P zhn¤é#†¿ĞKë×‹¶çE«PHº‘‰ldj¿6¡&TÿnÌŒä²¡Ò•®õ‹ğ¸÷’ÏV&#®€Æú¸JL¢KÛäuà/İXŸOçşåB“Õ*6™>ÂUêİÀç†åAfGÏü	eÓ¿²8ñÛÙØ—,ÅK4k]-jÜU4’Ä«½üÂ¡Båç¢kº”ŸaèN³cKJ™M±&»K'ç\dÎòD„·€œw1ÜMì\B|sX“”|İsíwòBïäAòºF¾ûS•ÿ¾lpLÂë'ÆIàR¦½ÛÂ?OUòÎFCœŞmJÁ…õ´Ò/µSh‡¦²ØI•‡³ªzİÛwQi<×ˆÕâÏ~Ëx\¼êçÙ€ŞÜ®bÇQ73 ìâÓkØ‘^ÿJÔºâµÌ1ÕÄ^?ñ5¶ÅáU¸ x…b¬ª£fqNGbf‘¡åÖÄÍ´¼µ °­Üñ/Ú}•)fEB$GƒYŞ@G–cpdï1âhzI­a³)«××î6§píd(f€¯\»Ù¢èê«2ùP#8ü’3]n°x¬%–AÊlA‡Ô‚¦,-NUÎÛáş¹oi/úÿÒQ^OÌ²5fìüâGwyÕö;r$é…Í•ÄZŠúœNĞ•0§£túw¯sr;Vû3Gˆ&"Yñ¼#šĞA2§ˆ!cÒg´Y_½4şVİ’JŒÅ%¢µ]¶Œ#¿=qº‰ß@q rmİ ‡KÅoŞ§K8_ımâÙa
…ë%l¼xÓlİÎ…ˆêº¿²ãuéÀ
Éy¡ÈgƒVšò/ )ãnğn;.Í½•3*fëÎŠf3?§èW8eÌACš¦jh!ªBı’êõÈ­ŸğÀ~Cób_JX¼L±rÚ#Ç ÎˆlõäêÖ':Ç•ğ
ì^€a‘¨r+üJÃF®…)N9ÛEØÉ£;qº‘SÏÁ5p"ªxªÿsÛ­`×Wên˜ÃC*ŠX¤Lƒ)‹.åª¬ñÓÃ@‘X™ìaHªSêQ÷¦>í¸cÿí†©kÆCêŸ¾}±åcÁÖv×wtHx-<PÚ­Sïòÿ?œ6d²µZ£’$§Ì¦2âª:œgŠ)”°'•–#ì(wÑb3Ã'ò}…·
7øM( ŠÂïÌ;ô.=/‚)`?k§º³µ<íMøRó–!-ë`Èù„ª‘¯”x¯–2=šÌ1±cçÊOt¡«Æ'ÅÁ°¡q¢IIÔ7ºÍ2ğ£äİ÷ˆ1Æd*¹a•rEpšIÖ¯ç¾.ê@FGÛ›LÏjØ+E¿.üUá_?KøşŠÊJZtÀu.ö¯ÁññºŠeóº’àÂCOJOÌœÍ¤üÌä›ŸE:-gÃ–Âõ¥yRSh5œ8hgä *Á¬uåB¬œávaJ¦(ÅQ‚‘Í]Q¨Ü ó*ªßü8c, öşöôˆ°q¹°vM‘B¥…»Àïeãû ĞÑíY>s
¾€z=OİIUóãÅ°A˜ñËCÂ{évW Xy^DôCÊ²¾Ô””væA4Ìl$ò…~gf-“­«px|ê7™…~øvú„×è—õiò)6$­Ç½EÖ½-\‚1Áâ fïÖÛª¹.×3¼²@k˜ÚØïPƒ¾Ü¡s/Q¨­~jÒ¸#3ùËS]íMJ5ÙĞ­ã.ùràssU7 ™jg8pQRS×æ²Ì-A5Î!!å’³‹­ßÑ‚‘IÈ±I¯›Ô,» ş9çŠ'X5y)_X Ú°8-ºü§5N.Y›ìã£çAÛ‰ˆz‘VC+’–ĞÁR‹Q“À‹~ë>ÎıKĞGª [ Œ¼«kÃÚ’­\Aš	T½ô4Ä"ŸYoDaŠù›"RŞ–iäû7<¹tšFÏÖ-=È„Ìšg°¥ã'úg,wŠtŞ7öÿ{Ìb?ÂHŒ/ÇsH‹>‰j×AÆjz^>Åú€Y"/Ó‘¾¾ıSHŸóK·…O*®­h[Ö"FrÇ{£GZ|ƒ;Œcóz?ğğ×»¾Ëb† ±z¬/Ù!NıùÜÀ½rÍà?õ%R×Û&ZÇáì¿¢X,+aĞIB
,ÉŠ÷@Ê¢û‚¡=rûİB(«CFãŒÆù şz™I,ÿè:½.ğ0ÉF•ËA`M>ÆÁîïúx»l¿ oQº‘Xè´¼ÊSã¨mÀçÑÕ-„‡Qñò®ó \‡(+ÃSÂOjÆ<©q7œ¼“çĞ@—İÈ(TÎ¯»ÍK®>eµß­GfiÑBÏÓ(­[p;y£¥6õ&¾r_“ìÍûáË"ÎK8D,&ÁÂÓÁ“8ˆĞpg¥KFìµàáTËïšT‡YÁAÒÕgúTí¯Zº©R¿ìÁ‹ëümq4?{{F´møO™Ï¨;J‘W»9ÛÑ^:¹¦•#Ö†ñ?âÙÖUŠ"¬G‡	.ÌX¸Óf›`ÁF?N¯«oò@Oh†z!¤ZrœízÉG„1×¦ì#]ÒËPQd‡ç-Äàªy\V~98Ê|µ^äù¸T¤‹Ã“üàş&•Ô4ÎdŠtøŒÍ”»t£ùäc­V¿ø[ØªÂ¢¾"]ÆŠ.SÅ¯?wİ^ålœN¯mF9­c1_ÅˆìAV§é]a–fbÔ3÷BX˜<uJNJ_ŸJ8›äí¿ À£Úq†-}7ğ‰ÄVùİ•h´œi?\cN2t¾nfTt‹OÁğ¶OšI¥—Z«Ê’J,–Í.E.ğ£´K#+ì„*Ë›‰MìuŸ$‡J…'!øJªÀçyÿ÷tv¶
Ìèİ¸F^Íİ„ñ9ç?$İÂ€¸ÿ´ù-é•ĞûÓ7aÿ÷#=âîE¥B?ïëqš%
'Ù²ÖtóAÚ¢û)ÎÒè³—ÿ›»ıûßºR$‘“”!Ä”ª ¹ÇG>Âæÿ]~¬ŞK~¡‹SU‡D¦lJ®uƒUÌ,Ã@‡ŞTŸ
OVöã•…“…KÓ»MÊ6å0³ò5“ò‘ä1ê-şb^ÙjòYpÑu2ú¢ÙB±¿ß”•T…ªö
çÙê,GKÒÀŸ!.\j)Vq!¸u·\{âV}Ûq¯Ğ¦Rò^A	•šïğuÃW[™òûÑ¿÷zsŠ-t&ã¡öÄ€>uw›aÊ…ÅÒµÙØ}LJ‚Ryıæoø©ı2øJß	ğî˜}	Ÿ–ÅïdÏ=¤‘ÇÌñG;$©×êCò‚z¾SÆ÷#ÁAQs8‘ËßœöÌóXzó…€2Ûó<Ù½ˆ6mÑJƒi(Š^ë×•Êö™>2~ì#Š³ÍN´‘"¶h<¿\ğhÚv ó­
b"—ÙpÊƒœ:…Q;+D\ÿc-`SY}ÂªO¹³ºÛÍGåqÀtjä…7²•3÷ñ†a#MÊ­¸ãnİÀœ†ÃÈØy¬ë'ÃD7K[‡T›t›Ÿl6I'·®zj"s  ßØëé¢±_î¥]Xo¤èHK½àpìºäÅÛìº£¢‘®/Õs„W¼ÇË71s7a.c3\ÎOi.jú™9ÇyşÆ«x °0j¼øÒZBRi=¦D!zf«ĞVµ¨}^¡´·Ú¸"·ú`!qëæ(6qµ¤6Bæ³üÈUñ¶³Zã™*Ô@~!ÙÅğôQ^mÍ¸"Ål ßl¤ğ2*ÍÜº~FMŞˆå—_}×k¯š7ä${8­}ÔÇl;“Á8Ø’3SÕ§«´õ°1±ëÁÀaƒ­µiçîeÍ£v¢^›º–ôü1ºîÓ¶:v¢g_Yˆş„`ßúèá¼"ÅW3•ıÜÚ¦gLˆ(q¢GõÍıòA ÒW¥œŸÜó+=Dm‚Ù% ¯ˆßÉN	ıú¡Q¾¶G›‡öî)~üH8úµ1U(ş6•W5ëˆ#.&B‡*GEÜnÓS—¨B¯×PyÉµ(•øÉ£ú_:ÚÜÚò±É×u<>oji»nâØåw“ÂVùrÜØíµ¤œäŞûÓ9¥^¤ˆ‚'£†O™ÃàODUÙš¹GÛªYªam˜¼ºĞâôÿ^ïŒT	5»‘“·Ö&ÊC›8¡€½¸xk±!d…JãF\7%ÍdİeşÁoıJÓbI)Á¤¼Pz
_İ\ü¨ay]ĞÑçÒbKÓä0ªÏóâD~¢æ'Í¨Aéß=ÕÂöì	Ä­ø0˜“/ñîi«£[Åtñ«u?Ø	`aÄüšŒ:œ¡‚ñŠ©ÔÓ½›9bªQ~½#]øüé¹êÿRj.î©¨…:¿²æAyÙßŒ´V™~·ú$¿ ˆÿÜ·*¶mÎâ¥ÅK¥³7dƒÆiÖ1á5äqY3~ÇøhG’½wõ•¤{y—­òÁ(Ì?…_ÈˆªØà§T U¦½zÍÒ´IqDÔc/±Çbÿ¦Û`J¡ÎãcL)‰WkJ ‚ÿF8\úÁ7áòÛµM%
7mëòÌ}<$ûZŠIŸ»p$Tgé…~BéŞ±SØ†‘#åãÆ–Š5úùé£†¤ÿÀã£¿½*¹’0•@Hù£
ËI=+"¡—ÀŸNwÂæ¨1S);½[°ŸbæÔÓÌùgZ3È9c‰–û6û¨P¹rA+1êÄ{±>£¶ñÓ½…~‚úøíºÒ1Î¼+B;Ò½I¦©µä«G' º¸¼!R9àu¢
£m§õçl´Ÿ9°Ä?¶ar)0—@r<Ú>¡ı¾_FÔ¶lwaKV˜Z¯ûÓ›²‚‹Ö¯‡ë£úü$3&ûp?{?DÂÅş* öw¸SÕâÕYŒ‰Äû)/˜‰s4Ùô(WR¡“¿L›ˆŸÉ™½“ä9J`ö¡¶ñ¦ª(Ãi${¿™ÌˆÏaùòTNr÷igò°+’¦Ãè[ Ê:b©ºÖÒšú¶¸¶~ŸÓÕ/éÔüÆÃ¦$^BMÖğˆ‘X»$'H¯ K YŠşBÌr¼j?Z´É-Q'İ ZP\kY£}µË¬f6?˜â<ú}ŸiœI±*Ü ¦¡9u8[‰gíùiLCÀ—Td&ŒÖ^L‘4Küˆ.å¦¹ó¸°›
ÜBDÚÈ¶ùÈŸ˜,½Ÿmˆëñ–˜ª¬~Ùµ?ECêìœ+:Ã(:&DÈ‰?[u	”§%Ÿÿ–%¥GjÚ¡ƒ\+Û‡§y¯ûôèÊäHÁT c\ĞuëOß%“èÄrÈºØã¬Ëê²£EÔwVëæ÷ñ™œ—.ßhéOÏéÈ31¸QÄbÑÏcE*$tv-	Ur TBğX¢»Ø­÷äK®†‚fâä4úÖqïXœÍ‚R‰xšİ‹ş5ª¦yÄ—ÿ‡5WCİš÷ÂÏùÄu¤L™3Ê÷'™Èöœ¯oQÊNú£7@ühÔf'dâ`,/€Í¬M »“bŞÄ¯¿‘ãşbúØsà¢°İĞS(y´ó­ÑT¿”KÃUŒ7ÓÔ}i–„˜ák1¨bî˜ÍŠ½¨5ˆŞ·b¦(šîrÃYz³‡8jPpÜ>µó¶_Ûİ€v¼†ÖÄg[”V±¼~‰úJ†Äö!Fß&V'çüH<s³G[Ü¡x¥ùbÓ¿#˜Õ
ƒ½·©Z´wäó_òLÄ”Kï×
2Á¢‡¯ÊåÚ,<:Û€wß/mÙ­&zÏéD–8Ü“"5hHCº°ÎŞ¶¸¡Fÿù‘Ì¯eş8Ÿ#!¾A{ñú;Áóú^ßÄ%»ş›É¦ï)*:L8Øû nçJÑ|¾$wG>l¡(PÌ'Ò;gô|e7ásœs\¦dNgö ÇğÏ²¦ ¸ø‡~mõŞ=-æy.ÒÜÁ:ìGgHïda§ş.Õ[®/¼)O8ËĞ Ã!OW›>8fuå‰s1ˆ0•CŒµÑëûªt	N%„¸Ën4HÇ³yÒúCd?–q›ëÑƒbBq¿iö¨ÒŞÊü¤·øÿšQBö.ë:SÉ6äh&€úâ'Ú?m‹RÇÒ#h†<oˆßesEå"ŒP/Gé¤>€e³³Í5oS`Ò‚6…—ŒpÀË±}±éò±EmÎ¢Ğå 8Òs·©şGvÀšÂ€>VßÚé¥Ù{À0‘…ÛºISœqÎH°ê µ@Àº¿Ú9š²4ÙòçÜŞçSß™òÈÔœúLW%B½}l[Lù}ÔóQVNü?ŒmõÇ¾
RÔq^ê°ñ²ÂÔ°=~í©!¯Àä1ĞÌš¨€"t›h¼{ ´ãêbEÒ¿6«ø‡`¯"—ø‰ÙI&ÿ2†´em‰ıæŠwqÛÛp·öó)¡LÁ7ûQ¸FÖS;Ïº'	¢ş>à­£A-Õ[Úi'J=mW/W3õ~>ÙÇ¶X2çQ…™TpÁ/$P>7¦‚‰çr+$e„/œªdóèNÿEì“ü3­ş`8GX¬úÀ¢ÍéÜ-QéIÆ$ ÛwDÔËÊN¼†
f;úÕE­T:­ÒDª‡’¨Übwà²~4n¤7‘GŒµ¹ ä.‹Æ‰oGßS-Q¤L]&^Ok½¯‚¹®“Ãn®×÷’ÉéØrÎ´HÒ-ZÛŞ¢Ò5ÀƒÎA
ğ­p¿à´@Wæö¦4‹æ­–99¼FÒ}/áÅ“´´1WnaœvrÍ|˜hş†ÎéÉ‘÷h9B¼ O‰.#À%næ:Æ9nh¥•–.àÍ#_ÙĞ„Şt–ù…û­
vŸæõ¨ ‚³}Ô‡ãzmÊ«î&úÿaİ2å»î&´[+%`jº¢°%5†`TMløF€íT.¾Üˆ»]T/ã¤€‡²{^V¯øu˜êOÆ›Õ"Ë@’~Ü°³9|‰X§°»»nlƒ,çt™Ş„æT_9b•ÚõšÚwY„ş¤3ÚéØ2&˜°Á =_€r³„—6{’Vk?T†¸ûsuŸ„ßİÌÚÍôÖUnkôº$$«Ÿê>b6ó¨«xºô.Û?Ô™ì IçÙgF\)kÈOÕ—	‰soàuchÙˆ^İkIm†è0üQ{œ,˜_&¥6kÂ¶<KÄ—ó×K] ÍY¥D¸çOaPòˆò§1Oo\ëú0DëçsüôĞ&Vÿ»b^ú“*n"öè{±Øa«4•²¹şãGêğœ½UŞ"ñ®nËÆMË?SäEfƒÑ½ñâ&°GxX¥Û‡Ò @ğ7Î¶ºÖ˜ä×MNıx&%¢=ş¸íC¢¯×é.ƒ¿+\»=4Ú³rºoú’ï[/%áæ¨{êùÒõàÜ<: ÑW49%KNKKÒ±u`t;œ±—\Ñ²½Yi,çB>1m¤z{S”*4i3é]9:ñÒ];X%~¥>–¾›Wëê·Äjˆ´šÃöÔ¢ÍÚQX£Pr$R$ úŞÂûiKŞ‹ÙfÁ:ü+ Ì°aZ?4Bk“©1õ´Ø#yÄ	[oÜÃ
mr¯iğgÙÔR¯Œâ„[\‰Ãa(J á~6k‰ o‹ñf&µ]=Ò¥L²ñv¹¹‹c×P×µ0‹F›Ï¨›Â¬r&kØÀ^ùaî¤Á‚@f2ô(±üícº";¸§"@ÿ¢7"ƒÉİKÊ‰<ÖØ¯i„$j8šGı‘
¶7İ~yºÊ°1³xœÏÍ¼½ê›MDò© şBª~(O¥ëhº¯¯EÁúğ§£mè	Š‚L:>¿—]‘Jcãu	¥»\^¶F0*û¤Ê¢B’bËÏ·³9w>Š^5äîÿC@g5]•À=³9¹¼b`"Ê’ôòcnY-’ààír‰Ù~°¸Í¾ªÀJj°GciŸ¾_U ’´ïbiŸı¼Xr1bµwúXX»XİjÒ²?ª´yş˜şİY.)™ t±{kú2²²Üîw™"
ë}óz¾ŒÃZì+¾€½5÷8Êm`\‡¸ÈµL)œ†X¹ëîNbi£ŞW¶M^'Ê.U%_9è_ãáïÍ‰">‹ãÔ(ã–58EF= ‰Ø3ÜDM:z]Ö?N0Ëµ¬`¾)O0¹ÄLB-Ìù Ë*I1Ãê…	—?ši¯1ÔtÊJôø æÚğnç.*ö¾ıEàÌçŸŠÍâ9UUÛ@ë"Şã•|s@J.Í	ñ@¿tíËµ¥âGı/›Ó=ÿãìLåQó.üĞo¼óUZõG‚<ÿæTG×*ÆM>” -æ\°QÃ'i­«h©ø@Ğ¶ú²°KŸ´ÙO†İçÓ[,ÓïiQóOÈş&ÑN-¾Ôé“©3tIŠ_x wñÊş\`ó”°‹1­À¸JX>•ìÍGcTõÒ&3öâÂz<^¿\çPY SÑœ•j$s~X¼T`QSåyù¼G	¤kùÄƒ9í+&U¹ÅjYåÊ+“åÚ%úü¶SOZd#—ô¥ÊÊkm2yØ$æG’×¾Bt!È‰-Ğ"œsú"ç™ğ*IöÎ%˜àœ·C¶.¤×ÙËZ³
\NóF•Y"ÚR6§äuË€tâìÒµN•†m‘¢z>r-¸4ÃWš½ãã¹=PW×O”’·ß£qà9Sc.ŠÌ–@†³.iP9åºÃ˜L¡©“s-
’fªbÓm´)pÜè¹—\²)f¨[ú×:T‘ÖÀ.ÈªŠd÷ÑÎ
æ;WÚó	5à…èläE’z®á6;ğdÈvÅ?è˜¸¬®U˜ŠóÆXn œy5Å4z$IU '€4Y)áÛßØxq±‡MpÅÃ§èKs9©Ó}'lô…³ùğN‰rÊí<NCyëîğ°(æš·äˆ§X;ÿµtòHûü¯£ìejóáÃŸÜFÑ”Ö•ø	”*Óµ²Ò€Îm[­ÛxÚËd]%Ÿ‘­¢ĞÅ™èdE‡ÁóEe[„FÚÃ?lL€Ûî—ü[±º$ä 	½ioÕ]p?› Kt-.`¿Œã-Zšt,~¯«‚ ˆ«GQ±İ;²õxÔµ²È%®oa:§4îÇ—³µoÈSoXù ±¤=KøX†TÙY¹3s×³ÑÉ;®oál|o(o íÕAT,â÷…"e©1½H{Š_Ã~›†Yµ‰öO¾]9ÿÉÌİğ*!>ü(.4n^îuì<ÉÛ˜Ù?+-Ú^Èîbb\Iìô³¬t¿
@ŞVsÆ—3]8N?l<à’ñÏI6Å¹Ñ¢O1fíZ·/Re<¼7Ü³tÍS¯>C
LòØQ0eØÜâìAD --2ÿÄŠà“Ğˆekv‡± 0Hñn°Oeš}Æ™Ï2ñVUÑ
ğsp”¼'4ÒòÕ˜ J]u±Y,{*ÊDWææ%Pwä­8s¢cŞd1È‡ŠÏPYÁÜá}+Ï†¡fÄŸ›!2cK©`íÍß©ªä?/Énÿ¼”â’uµaÉh ‰jo"÷Ø§ pş/*àçqì¡¡-\·Ã«Ri®>SÕ2=™ğáæÙ×¤ÛËU ¾Ü!$üj¿¥É"ì)å Øyw`£ B%%V¼Ğ”aŞ†Ùùf •ã$cøáhí]"«B³Y·‚eV]"‰ê=4îq"şbì=4aÍ±•Må’a¤’8¶úG8éÑ>+0l…Å	õ–D¦F›ù”™²([*¸“ù=œ÷¬QøÚâ¶œ¬Hš …½&ïyw?Qu¦Âà~K{ÍËğBõz	.ÖOÓÎİ@@ UŸÕiKU}gá"ÎÄ£éÜn:Î9©tşÕÈŒÀ?JY²‡*K§®…$Ò^v=0‡çØ5Og‘kF¨£UÅ½­k“}eƒ–)9ÉRMïºT§ÓZ÷5× ÷ÜÃƒ­±ç^H•ùE²\)a¸~v§}M¦qŒÄyÉNÎF®8dß¦Åx’G\V­–3*x{$gÀ6
™¥ñÀw’ÁFyéº5Ğ>¾Ç{ƒ*c`Mf(›Ğ!.?h Œñºï‘PMu—Q‹·‰Eš»Uñ¶*»"qad,å?NÏÙ.ôfXÆt—êÁ›Tı5db`\âhb‰»ù'ÿ¤¦×©–×ˆeÜ4¯o ‡ÆqMïÔE²·šhs¸ºoÙ2(\óhëÇÍFhŠyÃ“àB‘`ò„FÏŒéìÆ2Š	ÙEv”Ú5ùccœÇ…,B ¤«qëP›ÀÖnÕøP‹ÄÈè†.òBeÃÈ#$ãìwÁz8ƒ·)>wšÓ#÷òX¯GwöSd›!ô&[Š×asÄlcñW2yLƒÅ›#0Nš>‚60©ïìeÊ0ê¡áƒ…:
B¡C$Ss¶äœNä{GGà©Ì­¯Ñ€ô'gDHXÓ¡ÌŞz´˜H”‡Deê'·?Ô<Ñ^¯€,LÊ*jîùràsz‘¤-{ÆæTÏÚ Tí½GX¦ñ™ÇQØê;.ˆDşD’¯¶†ƒ[YÆ0~_Óo:¸h³}ÑøCÿ‚h¸½d\PÈâûtƒ}Îù±b.!¼@sÎ6§"ş([ÉŠüm:–SÖ4*cİ^GÄrNÔÁzr3­†›0^èÂôğs}hıVVP‹pqR€H‘œ¬§½œ  çËáÕÉO›˜ ”·€À„jRë±Ägû    YZ