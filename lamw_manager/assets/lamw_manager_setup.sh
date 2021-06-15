#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2254716907"
MD5="6b8a5534d684c06fef7409b8e227813d"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22272"
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
	echo Date of packaging: Mon Jun 14 22:59:37 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿV½] ¼}•À1Dd]‡Á›PætİDñrHdVò"%)8ä£İ­•7xEĞµáÜîñÉô‰îî§Mô½}jñ:Ì‹ 4ú°µeZ)Ï;Ñ;3xLRˆÃäĞ¶)sXã4_Nÿ/†^f’Åß½o4Â‡W¢MÔ¦àìçÛ³I^ÈĞ¢t”©øÎµìËÉôÎ´
4¸“6½p•v}´æÙ…é:<pìÖ˜	¯ ÕFîª^Q­k(=½ çC¢–Z‘9îï{UÎsŸÛ™™¶Pê›N­o•Ï<à5ãàô [£‘7cĞÑxò§âIBøX’ñ\v&)9†p`Î‡Kí¡|·„˜¡ñÃL	.öj ¢T
Ö\’fşñqılC!JjW<ÏH)jY4‚H¿Eíu¡g+]s—0;Ä)¡œ*äbI&™ÅHÃ>Fj€í¼¾Ñ‘H‘’ÑF<sßòÄ=³­m§Áû$n;	İlÛùåól‡(Ğ¤âI­ŸÔ†ªÑÒ›_bÏxÒİİ%öpw’ræu<aäĞ‹8ğè“¡Ñc9’
Ö”/¢¸lD<©¹Tı­+ï¥8Ô0®Ô–,æõåú5àÀòbLÈfş1JûÀ¿'³®<Ş0SVµ{0²b"e-ÏWtšŠ9WCgV(¬µ‡!âÏq#É€^¹Êxãú¸OD¾Wh#ÄwÑ§4Ruğ1ÏÕè)z·Ã?¼T±÷ê©†s9ùdö‘y+ËuÊµåaŠN T"Z9TßQÔ"-oƒóÛ©Îdü&F­Í{J|I®SŒ¥°]¤Ê`cDb4£©jh7z¡¶x¶MSöWÅkº6ÁÒñ^¢â¿!Aİˆ¼¢­ƒÇÀ5–½]ó7”ø„æÉ:è£˜:gŞ™‹abÍå÷e,ÿä³‹¡ ëÈçÕx‘÷{ ‡g1½¹{{ƒgÀ€¢5çk8W |ç®Tb
ÿTø)ÆPÃ”2=úècGlï™RÏMIŸa§ºçşìA82IDæår>%*{}d±ßK®àqå÷ÌıqP&î Š»ópkxÅçg£áRù…OZ0|©ÖÛ}YÜ h¨èŸ{ğÀâÊÌÎ(™³=1lÆ„Ö¨Ê’‰NTkU‡ Rá*mş—UJav«€."ïGye…[;åc@Ëá	«
Vü!o^»j¬Jkf±ZÅ…Äœ{Q:ï«dv@œ¸ÏÔ5KÄ,ŠÄ†Íçû­"bÛó.OöboKØvÅÎ\.âá–€ë–ëÙ”o{!Â>Û¨}m–vwgæäå½ppO@ÕGoµ)åê£oÁğ}æÔêğË3!Æ|ŠØ®§Y~ó{àº³kgœ§t3Óû˜#N ?!¶–«èaşFº80i†«{éL£w;¾SÛHÁô¾t\Æ%¶4»WºD`^H‘Ám'@
2Ğ_Ş.0AéöºÑ1OÓVG?ÂÌI²Á%Hæö€ä( Uÿ²É{)T‘kô A[¬ß0¼gNt$È„LØY½˜"ÊNÜ«^/iä25Ô	Ûú//ÍË®ş?XŠ‚¾ş¥ÄSºœ*§˜ª,óã4§‘¡<•ò2!ÁA8t
ofYÖw•ğOsæTï_\ä!¹ÊµÆøÃ…v
¦X‰‘Ü_DZ‘dÄÌqòã7ûäUe\Ò  {ŞB_Æ°x‘ê96·€¨©…îVÓyÅMõ­˜c©’y…Êt5Ş*?C“0;Kv˜ ˆ´Ô¸RJØÜ%$AN«Ã=­-²;ä7ğØc¯@ûTÆG¾E1Öa	j	Ç>VSÌng}0½qĞƒwx@4¿Ï,f¼0¸$$À ®kè„Y$øø%Åñ|O!)Gê@X¦2)ÒTÃäDÍÍZ©9Ë]ºÏ)±=Æ/Œy¿Ï´[UVæÑTd¦ÖñHfÂş‘å
¼ñCïYnò$Á1õ‹œÁØ¦÷Ì¦Êèø©•PøØ¬€Të\‚!Ğ#22~¦òe@[³Î&01?+ÇšÓDâT¯¼à ‡¯hú¿è¦D—}ıd );ÁÄ‚‡6Z®ÔÍ9:ds¤ª0u¯¹õÅë¤>Ì«>ªÎÈm6'€xŞ·à_“&»ıÓT‰¤Sc]P¸hÿ‡ÏQ:f‚¼táÀı}:5¨D§ª)iëË†’¿Û9,\? $^³U€„($€­ İ©¾P™1œ‹ÕC‚:p~£šãñûŞ.”ısºåA{!£>È<¾Ø‡óÄ{£ñmİËªÅÒí£¨h¶‘±ò%ĞaÕÓ‰û!Çf¸;Î`“d)½#C¦ÔÅÕúü7`²øº½N§ÉşÈÑiy1üÑíø†¾[Õƒ„›CxI²e,mÖİçÂÏ÷8é\½oü\ ?Æi6£é8ÈÎ)Yu;5•Ñ+"nBÆ¹©:«rš«o˜÷ux(7Şÿ eôogÑ[§[ÆåC?Øø©¼OS¹iÑ ÄÇN¥Ôû1êaĞ…@üEá9»S6ƒ½Ş“é¥=lŒWÔä[Ó¾'à`ßB"!Ğœ²™G&¿V>—z<µOÖğJĞ‰Æ×ïB}\kÜ³ö‘Û§+ÅkáN¹¾ê{Î›'¥L§4:E„wÃs@äÔK:ß¤ã´gÁLÑA,Û
âk	QJ~+9>Ş„v5Ÿ£H&Âi'S±:œtNû‘³>õ3ÍÜx4A¾±”G(½­Wz„+KXÑ›N¤bş-?`3×™çÍªbİTx_AŒ¦Nš.§ó¡?æŞÿÇ˜HH´Â”§|Àç-@(yüJX#å…0TÈÍ+S.ßÖo²Î›×[—¶pB©¶‰¿~²€[]0hÆ„©*üü°Dú§øÔãzÎÏÓ§±ÌTÛ=»“ÁvùlÑ¥Ù^Àq…xÊFrÜ"ø¢-àØŒ¾iQ!ê¿Â©rêJ…Å6XYz/¯ü'Û09#ÿ!ĞJñ‰T¿òbj-ÈzäÏâÒMOl¨hØEpˆ`J®=ùØwÍ%$U_ÃUÈÂƒ*#»¢&5ıyì„EœFOFÓ$/ã»\mé0³ìÏÓâ8 ãuËğ;¤öåç‡ŸR1^ÚÍ­‚dà4áÀÕ
ı¡ù:ª€ãÖiö*¥rI€wÆİË©E4qoŒŞJÍNuVçlS©Ôaw¬°,ò|t}£¹ŞjÁğ?§8¿¬Ğ6îZïÖ–=¨äİq\G·p›Ğw¨#œBrµn´­¸¦“Áôu…1¡‰Ó_`ÏîÒªšÅaõÔmPE#å[¥Şy8”4JÆÉaK‰VåEËÍùT÷xk
ÛòK¯"ùóáğç}¾ŞÖK—ş€$äA¥²¿Qê¦êÄÛ¤ÓvtJä2—ÜdÅ©uy£\õX›×ù6=Ş¿ÑÊòƒw]Pàï”òÍ<`l!±1«›ó/íñdxdWUIqsŒõÙâ—{UAØæ+¹Zj?ÆÉ8
é'ç Ô"Um¨ÔÜ ¾|µ½óáÙ8/`Ö€çÄˆê3¿äñ!©îâåĞpVo¾¡Ì‡Æd6¥>]Ë—²X àB;¾Ğşî#êUn¬†]l¿F¡˜Y§àX°ƒ$7Š®’ ø­ùø}tÂi0FÿÉ8Ö§÷áú÷Fq•'ìÇ¸”‰·>ÕùÛ;.oÌjOWLöúìæZ)º'†±ñ_šÜ£²ÍºªÏ×rÑúpÏ_{roöo´‹ü®@/E{Bêë6tÄ’¼ÇêÀğVü–@ÁWîØ¶Ê<@ #}ßYz˜×ó=›,‡I?GÌåí%Üşñ¾	«¹Øİ€·ºD÷Uq"]r ë¶.ÿ>qNkûûñ\Ü}PÒpˆŒ«ô^ıUP"ª÷õú.e¶è;8A5.’5ËËJ†Ë˜~© 9ÎĞ'ÍË²ÈšŞR.³Ÿ«°æyİîâ§y;6ëÔğŞ£âºµø‰cMª:/(Ïqİ²Ğ-ÄğØ8$¢u¢ÜRæX·çif¸¨O¢@Kâà¤Véé[FY¯—Û‹`IKñxğÚ[Láyı§:i¡,éšëÕ¤ş}F‡o\ğa3çÒpç†pÑx!GP¸ SÖrt@Îÿ’j"“Ò‘ÏÅr‰°  î>tg·#LâÚ¦VpAÏHØ™4#ğ¦W»9UÌXEyıyqm8hğ„4	#âÏƒ-
'Ô¶ê0c’#S2o>Áz¾öÕ‹@ğUƒFXEtSŒV/Ÿ/x‹RAÙÒÇP©çÍgßşÚ§7¦ºŞ‚FÕ7Î4Š¡ã¬•=º|}Ì°0†iŠqN¶ÊºÑeŸ-vÙŸïÙ£QliÑ’O—lŒ*†G»ëAá)9¾öF‘G—=9íc¼ßR‰ù7˜lÎbÉ"iŒ×Úó™¹2\D z:ÍèD­Õ‰	ÇkÊeÆ¨ŠşB¤•éÂ¡QI `ÖPsºH2Ü~¦tì¸pzƒPú¼Ò3¡Çæ XJ×CÊÅì_{fÁ9¡%Oõ¤‹Ås6%Gğè‡ëm	euîf/|	¥{xÛèÛíÃœ)—½6~{ÔZ0§ëÆL¡M=ğ
WİWúPLl7¬r“ÏŒÁşêãÙ.{IC!i‘ë`~ªú.õRÊ-•uFFGeÜ2µQnìÍDªœ˜²¢kšÜ!­I³Ê’PEØ¥j*o=Œ]©œÂ7ğMwHóÉøVµÄœ¸¹bĞSJ—JÔƒß©eUì@ß·²×ÜVs’>àçpøİb½´çŒKˆu·®T0¥A\ztÔ/÷óöµºe=xßĞ=µ(ŞÁı£s°±|¾‡ó2±:oŸ2ÌÖ.A€Íx-à;ØãÚlº3pÁ=%ÚSÀW-/YôÓ‡ÃŒ—É½3
–R*û‡g-` 7ˆ÷õ÷› † €<kyZ~Ü¼	£§qŒ~=“ uì+q„€‰+6Öò‚€œB$ O˜¦s¥‰æ“Ãdàıì+‚»GS÷ÛåÏKy!¾›nùŞó  å2èàGºß›ÉĞ=“(!3E€÷’¾‡©×]ƒË7.®JN¤³X¼	TWá¹Ê³0Ùœ=+ø„œ`UÃ%3e±bêßÀ0&ıî?ÖŸ”û…]îp…}á:é>¦Á6ÁSûôzftw$[ûònysî«æµ•°o2¨¼İD†R„>àlhàwŞùœ,#ßdhtÏó
2(šb<ªÚC¾ÕU‚‚ˆlVÌ{±¡µ˜HTÜ²ô–\UÑ¿õ\WS«éR—á5«s.Tƒÿg’˜<ÀÇº›è“Øòkã–sqØFØaßªpĞ?§wåñ@¦N4(..’Ô>Î•Ü±¶u,_ÉxCc ƒÏA]zâé@yJˆz{ÃŠEnôØ?’i·“v‚ƒ¨baŒ.¾×)|JD__	djMÓ/¦“}'jg\¿<9àörD¼¡ïªğÛOjÌ‡/ÔlwùæÙ«¹qZJğïüåyĞ"JÈ›_›Â³xL‡…Ù%,
Z‘\øs·.‹˜u|FMgƒØON×»D•¸ñ³yh€â(º\›ĞIĞôêo{`O_ƒî-k¡ÕÉ4„ZÓşSQÒ-Cpb6ˆ9ıŞ×È}I~²ÿoJ<îu«FÈ%€D±ZÉ­c©0@ì5\ºK—Ğú›²l0Ş•?C½à£¥qnX²éÃ©—,3æÑ·GÑ¹ĞvêŸïuĞi‰;gŸt=Ç”MF]†½‚tÓöæ>Î°§§ôÅêÒ†ƒ©§ÑŞî¿¶4Ô\eT¦^Ë¼tkîª³]!4‚_¶JùÀöœVRËf½8>™'PFv[¿¼D*b227J8 ùéáÿõœDn¯ìØâ±Â	\0›İ Á>æ¶õU…0?ß›W®C¦Õ5^vØ­9Ÿ¿ )sü£Ñï¢0õM©‰kƒ&÷‰W&K„Ş&ÕĞÙ…¬p_JÖã'æ¦œ¹i„æTûİ·©˜EV“¯Ói‡3½û!íLk1ÌÍ±İ¶¼ğw{Ï Œø³ª¸“Á%ûcngY¼T.w˜»T €v–=Æ,€‚¹˜Ö{»~{×ö\’ø©=ó8foõ¥®Şß-íŒ¤±êõG2AuÚ»ó
á³òTçık¤ûë5†Ú%¿X‘všBnĞ=d¨PĞ’ÿ¤O=}iğ‰‰™ÄÏO™kU—’Îw…46Œl)I} =|µòîçõU&uHqÓìÁ™” )&.m¬‡L;hÏhVº÷ş_ì a˜ßÂ†•×¨
–¯Iİƒ¡ÇF™ÒM¸•T_à=‚”±œæî½¦©fãó ¤Rg›è² ×8Z‡Óœ¬ÿ¹1~ã# d4õ]$“‡yé•<³§a zğ ÕÃØC†vÙél8#.w¸wgK.tš[ı«»4s‹şÉº´U”»ûtäVUaEğòœ"Ï!2$n–Äc“o…oÏ£t«$)
€G	2d8æ¶É%zÚĞoüX¡ò^L¸İ×4|Œ§É†[92ÒS¢J—dşWGƒÍ&óº*Ğj r9•ˆÿrüöDIäEÃÛ°y­JÃXE„;§C½1*UpH]’Ğ|Óòé7HQ
SñÌJË°.
ğ Æn•³Óİã·_=s9¤}fªLŸô°¤®Y+Ùg13Ò»àÒê½_Ò|]Ã³¡›U£}9ÖJ¡,åé&#Ë`xÈÇ®1’ÖØ«‹' U[æ++U}_lXWëŒ·¼ºÚ^ö˜İ^ú±#ÀÆ0<•mÃŠ®Ò‰Ÿg	¯ü#İ8"X¢ìYú‰Œ<Ô`W…‡ş¯m9yhÎ›|b·RzŒ­S“¯æ>ÚõËJ5Õ—¤ãôwO£"DB¬éâó`h¼"ÚPĞÎ½/ñ÷'Q«Œã³–~ŸËÛŒb=Å¼®ù†Z,Õ&é.²§Â™2):£)8&;-½+4/†6Ñ©ˆ±äI×=PÀ¿5÷y7ÏK{™Œƒ»ìØf#ÖÖÆP ¾¯ú<+cü¸ÀsuÈ¢“»ˆÓUÒú;æ²‚Ì qCI'äV_42Xwe¬ÁM$èª‚d*}iÒ{¹,QÉ´¤›3Ğ^!
z– [cÚ#U9\Iå$²ÍmáÃêj8*‹†ïZu%4Ä¹'uV…eÀ'G'¦å2†ªÄBkÚ¹7uˆBGºvsÇX£Ü¬¨bh#Â¸…1¶0îã—¸îæ&»òºœa¬,ğ–Øåêˆ/¿ÔÄÂUØ”¥í¢×O"zRO@ŞEÇ‹­:XEnÑîÎr(¨FµÁ	}1ìÛx€’ÊWÙ–“.°<‘Ğ¤‚|º$­+ÇÁ#M¢áœ…õôİ(úšˆe‹ßóOâ&îœ¯±¥û’HÊg<‘B'•mÍ<<šTŒ®¾*«³ˆñ~À©¸ƒÅÄã¥÷¡gáuL¦<8¿æ[@êi‹ğÍFÒŒ•ü­'ØØèÛy÷z;^S hJöŠÓˆï>‹ú¯¥Z|yÓ!Õ|ŸqIÜÊ»rñOŠŸÓÉè¡óYêeæv™IÀ¡nÓåM_HÿøŒÆôm]NEÍe!ªp8 Ü¶7[÷Ì`‚fÖó³#•™?ûd§¬ùëBˆ>‚?Ÿ¢Ãşû8u£ü½h0mLı'œ¶gSL<S+Ä¸fD-Š»W¤Öy—zÏi’‘Tø£1§±k«4€÷Ôı3Ø4¾b\)çùp¦On)NnİÓ*·ä89UŞ3S YO5ø•)ŒÇj	ÃoPNÚaÆ$b]ÂŸ¸@"ÍsYÃÆóN÷Êó+údmáoUl×ãìƒ*‹xHª ñÍ£Ë#“îËhĞ©‰¦4ƒ¦²@wÙÕãøÜõL^†Í¤ğ€_ƒE~?Ò½nkk, è˜ïõ\ü.Š&æô±pªÂB1ë.O\RĞ¼Qœiziã ¦«-ˆvAñôx¿­ˆYPwŒıç JOƒßoqòö²qôå\Ëõ¶nób¯IÜª›®pÓÒÏv@l1N´±àsØÔYÅ`;J:x'<Ó Å± SúÉ
„4ùa†Œ©ÎK|Àë[ ÜÛ¸¼ùğ<iÙó²C¢IX 3ö[¤úÜƒ5åWÙØÄlZ¶}–UƒLÒwºêJÿ|ë?€iyÓçbx¥½ÎĞ@JİıA…V„©Å€Mqçk82a—j\|%–Î„.$A²1¢×/N,àáiŸ¬AØÍô!)_=_ìÚ²ƒËòµ~ìG}?@‚á¡¼
RÚy
÷~`Ç8Ü>XYn
s4[xÚªcœS&È½˜ºbrH”éìgô½AÕ‹JÈ›±¨bÛb^¼Ù	²˜‹ÿ{{ãÿÕ—y»İ`i_Os\@‡k#iÄˆæ»Ql"¦Àl3ô?~î*½”|´i«ÙÕyÒi»ñbĞñP§ÍJ—šâì¿zØµwèÿOõ•e×#«­7›x}Ù´Mşê6¨eD ’ RMÅéáÔPóÀ›É³X<äGãoºÀ?5súè”XŞ÷.²§ÊEæ9ƒ‘L¯œ8•‘mïL—•§äPøNŸ8ù
óÍyà<aÊ‚Ø(2jˆÒP{ğj²	üäæcÁ–¶7álª–g]‹âıáö»n¾2Pd.ôWkµpŞşZóş«ë_<]¸¼Ìy6£€°-…‡D~Ø´ÆioÏs8¬ÖN§ıLÒÂ:ƒ¸[ËÛf{yëoé§‹âµ“ QUFÖF’`fÃÙf›Ô ŞnØte¦¡”£-¸¦jy=lìúFšrïÆXÑÒ|1ˆG‡1xİmÒËxÒVùªD˜èc#Ò»˜	ğëü´AÕ­îÄ,ÿÄŸuóû»`ºèÀSF
j#
I¢-U™<(WêûãYÛW$'ã0Và1W#Úñ#7;ÇA­ª˜œIÌ56mV€PUÉùã“©Ÿôvòû$òdùoùÉÇ¤h±¯åjD*Ò5†RSèV$Éõs[·„K{¿‚(úƒzîÂ¤WÉ

[œ9ñqZäø•;î~÷š„]¸ÒŸdŸ(&<½öP]@c¿t'ÂâPÁÊIõiIéD=óDi ÂşX!FÁ
Ë¿9¯;]0-¡E÷Æ[`‚
Êï©ìÅ¶Q(sÿõÇkï~\ynJRà`¯\Š.´ºÀ»†]ÔÍ£°¤ÅCÂTƒ
ºW{[€sÈe³£AeK/ãÉòµ*Ó\X­ã²«¾èï&4ræïÊÈíµ}™à­Ä™«»—1 áê™¹\å§1ô¦yÖá$ˆùåVCÔrXÑ4cIÂg)?×WA4Dì¹µĞ_–_?.0°†9êÿî¢a¹µFè'k{×ßÅ±ÜÏï÷°„ïØ[ú@6Ù1ºv{ÿY×SãØ°X¯“.dÑY˜ª–ú1³VÌà•úş‰â¤?†pœaf(Z›é1€çÂÆ†;^U3Úª™~ÔÑÕÇUûÕ„ĞotÙäBv%r3¿h‚z{óÄ¾R¾Âc±`YõXùH’ëÑÛİÆ ²B¸0k×"V~×»VftÀm¶›DcjÓvkh=yjá»İ¶ä‘Ò44£èN„Çpâx [i»I–KìÜ¾$C÷:ÁöRÿÖVåïô.ÊPqÙØ’“ıèO™mSÑf;m#¬sáÿ®ÔuX
nÛKÿÃ†çšP#b.ll‡,$øÍø•ñ/›(nWÉ²E”È¬D;&vOåòšD*±$š.±J®\/+¦9c@k¤/Ÿ#ˆÉÅ§¡±	Y,ÆEñõF«qMò…bà›Šqr‚,ƒ6œÂn¼k_î2Ò‹¹3…ÈI¥H6JxğÔ¶D;¯&·FDÛs3ß-|ÒˆéÃ Rñt¢î;¯Ñ.n’É²ÿIr|$´(èéğD·Èïójµ5\c…™³Ú½£5O,4¹–ğ†–×ş@h7*ïÀ§`M Š¾À4§]¼åsWä”å ›JõSL†¦u¯ĞFõÂná#LğË; É»}òé>mwÊøEu‹àf¶Td­~%#¥XÇ#tînJ’¹m+ì›ÁŞy²æ&˜Õ½6È©&´»…×::ôoZ$«^è)àøZf0@Àª²Ü§Ë7*7İşøÅŞtcxˆÔU*7¾æ±‰Ú{Áã%Rûœ¹yµ3•Ü¢SÆyÍoı–¥Ì£Ì("›ßš1Ø)‹ {çV\Æ?^ÃÁlÓbds§’K@EØ‘SVD µ¥á¥3[$z²BF¡q¥F¡QùúzáƒæFM•Õ¬ø™µÁ¥æ§ì§/r˜2½U\8–º­)YÅK­LIøcİş,Ï.+´Õºíö[İ´,Õ¦AÊ#›˜ +Òÿ¾z!÷UC»ïVÓ2¸f–Ä÷j0>‚Õ›ø³Yï
¤=QĞ·Ã3ïÙË1+Ü0Ÿ²~‰yB˜AÂÙ¤Ñy¢ó`9-ÈH÷˜ÅTø8ÇÈO; f"YªÒX'´z˜ó‘Ÿ­»@(+Æ”Ÿš÷’<ùIx Ÿ"5”6wI'üı-\±Æç2%S_ÍN…_r³2U¯€àé ¼	±ÑÃş6âŒA¢wò:¤?N¡òwzÊ¥QÏÓkW€[«‡“_vN­|o&@2ŠşØ‚I§Sy4Æ?ïê­&´¡WÀ+‚m'Wh~0¸­®nIÍuÉ÷p^(82­ÏÒŠ÷ÓO`cL¤ÒåïIÉàoqÙjV½iİ™j"Áà6öA[œş0fîøÏu1·¤·T±@İÛÏ÷¶“GWÒ‚?k_òÿ\±vı
…Ó,íô :Ş,í´´F\iá³İ0˜<tBEœ«\ƒ†Ôp[ª­Zöi"Ô‰	{:EòÅ¢€ÏCôu¹‹„Åòô	Zº'¯ëÄ­†ìÜ!ì·Î[¢’<ïÄx6Z
NF'6Ã`ˆ*u|²*GïÃxSš<×»òØ …ÕéßA96áíV5.m¹¾†Òëê3°–2næcqü$üØÛGéÕOÜ›qó1ËD03ëG‚Ó'³»^A´‡µÇòkÃoJ*Ká÷Ù0†YGìãR«õğğ!Sˆ”‡g=£“"Â3b-÷@ÄsÉÂoàHêƒoó™¸ôF°Ë9™"•#µ“Ç9ÆÊl°§œ¯üì> ÊÌ‡Ö^âôº{nÑ8—à~µ…Ëô1~;š§àÏS ´‘»dıÛdÓC¶G x-áš€h‰–Š}ôÔ¹§Ö!%ˆ Nø	×mp‹ü„Ìş´«–(¡-wÊãpKÔÓÚíë“ÍŞ›5pqÏu¯s“ªs˜Ì¬nÜ˜ÕãóßèR‘«ŒTÊ(m¡˜¸j¿© c>$‡i>ç‘gªi*bˆÀOªŒıDQ	êñAØšYåìÈîÌïÀ[ĞPÂ~÷TœVòò0t£.GÃÒÜ´Ç»Ğ§XKL’°‘¹Äæô Ëìg&Û´*±ª\!#ùÎò\©zÎ¿jÔlZcÔïkƒÛœúª¿Ù´é¨!¼4°ƒ—Õ–ŸA†_–‚k‚Q¥–Óu¼owOVQ>pÀT½~õ7'(ªı'v.{P‡ù2|´ÇÍ¡ÑC4ö$)˜ÅQ>tSA$ı°…S6°DƒÄıU’©1ÄójUÌ¯kBæA°guæ¨ëåûDE´Wê Pì÷x·tÚÊ@Ò? õİï7Ï:Â¶!-HşC¢†]›§,^
Ëın3¤«@ÔşÒNzğ{© èf(ò˜ûªvÑšÄÉ¡ËU‚†Öÿxéyá_
&ë],ğ|ªcõù«í&HvµªÚÏkİà­ZØcY—şM±o†„™Á06â n›ş_(Iy\|òÑ¥ønˆÖÛ;Ú§qVÍõ'ğLwOÁ£ğÅVFÁ‡È\d)ùï·.X/¶³Õ½ûÛ(DÉYŒv«4ÿ‡ç³+‡Å´cÉVğ*¯ƒ¼`ÇSô•òÍİø6„K!¢ã:‘b³;‘7’6îJtC Ú›Ú-ß–$T‡Ÿ•ÇÂGñœ¹J@‰Í é(àê]gÚ,Œs"Ñ©:+Óä&RÁ(fíö3šÙÖ=T4öãE—âÊª°¬C5¶†	B}H#Ì²gâÔ‹sÿ¹øµ“­åÚ¦ç\Dy®aİÊ®z©wq1¯	Gø/3àµ{ˆäŠQAàQÒ!QÑPç½;=ŞSIJˆµH]íÀ.§dTE2´ãq Ï5+Ø>¹X(İZ`<~>A²!ã£„¹ò 0¥P8óøü}Ùº¡É‚t|mì´iÌÅ´ÅƒŠ/À}äZ„<÷!ºjëÄü²ÌÄ Í@µŠ„©ùx–Â,şŸ £‹L3×wÅ¿eÉ[€GO¨¯ã­ÄébÙ l«$»»
ô÷t-Z ­ÈO±ĞÜ±7xFÛ7Ü‡ô9Ã÷ø×õİo&¾C3OISd\÷¹ÑÒ+¯;ÿug‰¥å.Åš¥Ä}E€%ä–®Ê“w‘›©éç¡30å¸î-MP¥änÂüŸ2B0ßd•†%ÓÅyşøîFvıÒæR‡J5™ìaò}	 Ms!{	q£÷%Òˆ¶®Ç6ÈU“æhS#{é<êîèân²„!|V»SÌXvnÃ20ÒŞË.Síû,µÍ$uB³Ù%Š¹§ù`®'íÛaDÂAş¬Ëd6¢Å]ĞÎíB
ÂáGÆ•CLa£<37š`âcäy7GõîÂb½íš]r±3«»È\…~±¢Å©ï¹ı„À"]›eÊn”üY—©–÷Ã{™Ú¼˜Eçq#˜¾7dÚ6ŸE´O=G¡éZÅ5”¨ùí½zhD¬€vLöc¡"Ì@Æë‘g‚ŠùGø"²ÊSDy{LwúîÚeàıî³ŒäÖàe½‚t³3·-Q "Är~›"ïL§£˜{æé—§¢É³×Şü,ÅKÌ-ç©kÎe¤Õ--÷…âƒdˆr+Z÷Ò8«ßõôİ&–˜TL´gşbáVk™3^X~i0‰QÑ9îø©B cÍ`ì2fµæNt¦‡çRºó;<œ]W9ô¢½²Û÷}Ò Õ—WV-Ä7à5ºÑÍ’ò—ÆJIJM		‹ §&GË¬}NWˆ2`­_+SÛ|Š?ŠòÃƒ?TÎÛñ:+ß3ƒ_]ÔDNUrıœÌ€óšèép¢#œ–wË Q:6ºsZŞğtùÌªÊ±øqUğFm<.k •õ¥hªÎ{„y´Éb/NĞ°·TŠ¼ĞS	à4œñ¼5úAj~W¼LŠ•?6SÎ19M]’IÛH])ú4®á%àÉ\U#>Äü=îĞJ7 öµª%–7àaUºúi;G¾yÙaU3ª\ğ•›‹©¡-ª:ÒNVßFMµ[UZÁìèFçÕG
ÖT^ÓßlW	ÔÙ@êáˆ9ğ³±Ô~oÔ§ğÍ"0M;z÷äzë}Î$ºÉ`Ë½ıƒ±™ì>ñ”n-Öpê´JM¬÷Û¡NüØ¶o²áËI¶:w²ô…?¬A
yÌçY“L ¥Jû×aÏ¡òõğè‘ãéŸ›Hè|W6ñ>ü%cM©3h³È›)Œµ ç7o@êıà;$¤H©Ri²Á³ŸR™‚ª]ûFç–0cˆú”jÍÉ V\ARw9z•ÏÀÔ*±.š#,¦„Êšrß…Ö4B§ÑµEáU‚Ò·4·‡jšb×¦]4“0£8áÄÅ5 ıO µF.{²|«]œ&è™Ë¾/†¿éåp@ò²ç¬”X3IÇ¨qÓ1•NÚÉXÏZcÃ¶ôíYÅÍÂøŸ÷ãÎƒ-@=z¢ŠcÂ¶RÉw0N»Ëçßhˆ?r§$p"‹v%ê8¢Qåí²†ò´üƒ
Kd¦„ØCHvÈ€”ş=»X µ§6\`3„¾ì5¸Æ:M½_iòº-A\ñU'uƒ4£C‹8Àš8V©d\<9gã‹¹98ˆ%ïòZô¦‹Áöä{X¤ªWÄt±‰Ïœîûúu÷5KY^l…ù±Ui}‚…ödÀÃ1İ-:3˜sĞWj`à„¹°÷¼qÌ&)‰O6ş™d¬¼@â¬Ó¼2»Nÿ¸Üş^ù(Òïÿ[
±1e=¿›ÖåäCVoì­-ş™0Ú¤£bF³¨éæTíÿÄ§Ò@OÆ±noâ‰×Æˆ«>.iğäÀ¬ëEßµ5F,£A;xüNFHå¸Ä~šõçÙŞÓ0ï8Ã46­º³éğk1}ˆºš-Š¨÷ŞÕ ¯ªÓ—¡]#0RıÔ_?èÏ(”DFs¾²j¸Êt>ƒBZ’n¼
Ü•Üğ[¨é(JÁö†Aı¬ÄïR ¡æ-oæLÿ©E¹~ùnn‡¬—HD<’=èRcØˆJ Ev=®õßœ¢ëÅü˜ZV…xl"s+âv[w‰ãÄsg~It¥n`2^şvFUî¯Á˜U;jé	ÉíKY@jæˆˆËÅ'ÂxÂ´ÉN~İğÔ‚Ú~{•D¬gY{..t‹8V=
÷&f2MŞ\Ğ4f—Ìz¬báX|ò=L*“aã½æŸy3He2lP ÅKÄO¶Ã4
RÎÖ¾ô¤`ssÄ*ãî~®¸Ç>ò¹"5ÈU}bµ2B&aJY9x34Ÿø¯F4‰m¹j sëu¹O&èŒß&g>gN¦3=¶= Õ;jÏ£,tæ }½TYt¡¹YßQ´¿â6ôQ¶øû–îºİ³X‡“>´KChõ=Š¶>dù¸–Ìº¥ãœ»_¹®İÍCóûı™ß8Ù9	Š(ê©ëËYp'± F8l/`È¢2^Veó)YFjêİUSw7	—ñuzá”,tÛGï¾¦ùÖ	å0Z;¿µ¿@5›½ã›x}‘ºL”a»ô­¨aî÷A¾ş¨5ÙÚ§À•2¹Ù‡wùÿ™p)¤5¼w˜!41eô€­m¤JWZÉ¼1ÅTŠJ„¹7à‹ÊQo¸Åës”ÇotQ£¼^­³Xtõ4?_şÑ$’µVó}¥º†È›Ë›Õ`à…Rm‹\/(czäÚj©g¬ğçæÚÅ|ŞêÖt?cûûgl·–XnŒ6ı\jà#İ4vµØPîİ/À2I½×y™naZÒ‘cÈ1£¼€*~y*h}sÆË9ë«€E—>E|ß-0xâ²cÿÓê=”1¤ éø¿Ôb¿í5K“¬~Ò¤hÃCçÃY` È³8Á¢Áé8à›>b4Qê}pä~Ğı+‡”5Ó(£Ô¯í‡,æ…¢Fùñh:çáÁÃ¢?!·q‘	[,ÏØßè*Ù‡WÍÈJLDK›©	xà¹åNÅ¹/®øYÖt=¤ü'¾¤%”+Şåşæl]:…¡“fŠ•ƒy*Š¿{Û [”
Nµæ¹ğ˜U­V£ÃZ}t·¥¼üLQÅ¾„{EÁ™Ô,ûDĞà¿	·ï{d¦ú‰ƒŠî¾Íº™Vàº­^„„Íq 	ÂÍÃâ;|vìŠÛ-hOV~À]¬PÈ…¿–KİSÅlzõçrŸå>Jg/—<ìŸ|8­€ö¨3OšÊ 3¡m$ø¤Ğ|öÔàüŸP=ÉªİŸÁvšS“TDİfTXÚë–™\‰Is-áŒgŸëşl2Zd·éà`…7.…q!=zªÒ£‹öÅ2ñQAÖÌ‹•„}¯™å>}ŸÆ‡f&å¬Æp‡­Ñè¸]„‰~†(é¨R:tÓTIÜãyY9üq¯_À'şƒÿ‘ã +¥ğã¨İH2ÙIõŒaÿl5âÉ¢İšÅMÉ ™TÅÙê[íÒ€s¥ğ3ë²9
^@¹WêÍ3¥˜¦Uâ3“„Ö†S6½y`›~ó±Ja8Î¨Îõ˜³ÜÃ'5\³oàIédÔ:²0&Áo\ûİİùY‰nÅëQå®A&XÂUôä©šq"úPSs0‰ÉŠ]“;ZCåÕšÃ”	¸³÷†I{ÄÏ„a¢ÀºŸI˜–ßÕ\d]${®%iFk=©E—®cô9Ùü0ñqãÌ´¯N%&®Só%øÙQa„G
æ»òÉÉr•şx±¢ûf9ıq0_ÌúêJ¢^^ê¨&“9ÿbÒXaÆ){ô'œHï'ÙsBŠ#¦ÛĞkİZë³zÜpnµ*ws:•Hø™ÀO-b›=îiª€¾±qF©RSÓ”æ½€·6RHiÄ3gÅaÚ½x,a;¯@GôP7nae¾FßJÊ[üøG£RÜù	Úˆf,Øı3äÆÌp¿ašâë¾tû4|`é²TlH]]Ö„Ÿ	Œû¸±MªêØ:+@â|BÑ·^àèÃHXİvŸòxtù§D`ŞF·šÛ•Åe¯ğ¼	hĞ‰Ë|àY¼pÈR²Hønwã‚cô‹¥`÷<‡ÚjŞŠ+(ŒÚÄ4#õ¢^èÊï^òÖ{§g~-NRSErÖ^•À¸Z¶›]ß<n°I… Ê­¯MŠ“VÃ6Ô¶×h—XVur¡XˆşI„ıên3Í>ˆNÂÈ¯´Ùõšå7ÈOÕ	`C¬%K«{’³‹¤7Lú½ØVM
5ĞRèÛÂƒİUbÏu[zó1LRêì~&,Ñ±Íñmf/I"º+Fªwí*DJmL?@è
NÎÍƒÕüÌ`[q.¹¦>{‡cÿRŠˆü'tétÙ[ù‘;öß9«óK}{ Ö­HÌ
ôÉÌélí*ÙáË†}~ş»h¸J,ıeøZ
ãÒ³áAe:ÿZØfªĞËëÒI`ıÍÅÿ9á:F"ß}`Ø	Cµz&ø®·z8ÿ%HF<JÅË5.³ê•§`ßC<³ş
••ÊÅÁ¿w ,°va‘ÄÌ§–^o#ºVwáo}\Ê«”¦Ù"Æ®NÜ’–P…÷e½a¶?˜	ósE )«Zê(>›‡Ot²'+İÂK©Éâõææá˜Á hİ½¦”.“\?	Œ¶5¿~ü./tæ¯l«®»—²2i4øCJ†¸ı‘ôcHÁfâÅ¬Æ±¯šèÜÚ¯p+A•0­´j;¡‚y
Ü¯xó±ÿªñ—­‚ƒ	ŞMòy“L¶;à¥Ş°ùXÙ^-<­Û—íÏWãÓ¤–tş…¹£š5ŠfN›Šx A\4€ğ€HWIg¨Ğ®ì4	Î	EÏ§úeå¯TÛ½ó/mş}ep5Â[©K^x¿…½Ü¿h¼šu|ŸÛİ’ÖqnúÎ "‘Ù“-]·½áp‘,Ç‹m•¦ñìÄõê=
Ìœë¥ƒ‡%ğ ‚Œ³9·ú¢áÙbhŒ¼úĞlşÊ1Û×ò‰1 ê=±X'ThLíÉâ!PX…ôq\Z÷RØw¸Ïêü†7ä}» ÕÍ{¼‰èç|¢¿4Ó6û‚{Å´¿rÙ½R;h2Ó\9k%Ë\èò4ÆÜl!R;N‘zÙ²v—úù_ùx2•­Õ~F$‚•š­1Oqíò€øÚÿú{ª)k
hIr*n¯ZüúkŞ„‹¸
Ÿ×‘Ñ Ä¦î²a0T<º+-Qåö>¨¥Á}SN`:Š˜šm1QËí÷$°úŠ¿øHÔÑx0wšßCg(kHÃÊä¶³u‚½yeÌÁe¡ƒµ–å–¸h3¢Î 2B”Úšóc9†lîÈíDÔ.Wˆ-‡5^)Xö?>´Si1‚î™¨›±V2»´0…¶JÆ8jê¸@UŠŒdŞõ^Úp^_Ã$ò#EHt c¢¬ÒvŸ÷ŞUöë¥Mu¡ÜæÇw¥Š£;ÔŒÎÊæ–Ã8±”D–\Æu]Z­Z†£x½6êY •V.É=bá[Sxõ5m–ãà#yãú»u^O¿<x`ƒ­,ÿˆ+m	(í(ÜK_DÈ%Oz¾œÙÙŒ‰jâŒ±¿"e)—áA!a¬¢.bW›ğr|~êUÓ¹XªZ¾ÈÑò<ØöË*GOJî”`.“XlPä¤š¦ÕËãtGI¦åü%›‰_.‹¡;:ÔŞ©hƒçtÂ³PFgWyĞù
A‘øcÄI´2¤u+É¡W]à|ÖÉÇ˜^ğ>@EöQtZšœá£yOz™3ñ·‹"Z«…âĞ×š¿„.…«æÛ×ğ2W{Ïœm“Ö’NÓœ.ª¡lœxœÌûÖÛbÕ/'ö	’¹NìUÀ¼ŸÊ>¥ºe¨Ÿ¸zOĞ8¬…#º´ª´¨TşjQS½ZM­È?Å8’¹>ë(ü7°¹çÙ™Ë•¬ª=¿,¡4~%‡óg¯¢µ/ $[ÎÉ°›Ö¯é¡¡ªØµ"£
C>)á½ËFvÏ+‡N`.ŞiÔ©æ-#”·4e®t²¡wÉu3"šsûo!äÄ5ÓS“.éC…éè1gR!û~*%ïRyæŒÄåj0fUpazGÌd&&á99¯:MóB†ôşÊéÛNÊ•}uO‘(#|ÌZW”´½"¸IÍ’ŞhìÛ=‹eúAÖİ%2<m!ÉPíÎÏÓÔézw—›óK{UyH«<|U‚ºš t¦™rµ¡³]Ùğå5ä+ö¢·vŞO{Tù¬Í“u‡š+BÆû5à°LJØÉÕÅXÄ0¦OQÏ§sÔ- u¦"DÒ—_åÊAVi½äŞb°†GÀ£.—ÖJ°:ó1“œuèñ1‰kZŸ·óæîd:Ãş-¸_I8¼\şÙIÓnM…d@Äé— k¨q$ãh#'5öM\œXÃºfMá€¬4ŒE6ıÉğï‹â˜fÇ4 ÜÑ}´³¢ih}kĞT5íWœó[¼óI­“N°xkCTÂ´kÌò_‚ƒ² K™Sä$ŠUs\:øí‰ÑîúQ<Æ³Ø{#åMÃzà˜e¢ƒoàù+ájVÃ˜=GAPC¢:šîÉ±;Ó,8ä:P<|J,=¯s±ó¡Ys›—°>â%¬TQøÿ) ğ'9‚~ÃS²Ãè;òj;ÉÙZàï¸ø»f’ÄÁ8
µ«»ƒDøUC<^EDŠÁèÇıìV­&:‘qR±"‚çLT‹:ùúëWgÀÂ›uÇ9ÂeæHz²Ë A4q‹]wLÑİãr:ÙNQ•å(˜Ù,ûÿ³±£~š
­”ÓZº¡b…b •R!“j,'î%Ã·S—í5»KŒ¿ÕŞğ•_¼Rš›fŞdRşP,_aÖ_q–Î®Hññn*{C~° W©úŞÔäôÉyN ¥e.æåG42nSP”=¸ËRõv^¯èWåâ!”Ò®OéoØŠP²dQş»<¥ù¾;šhpÕr…kÖ÷¢üEUö»`3ZU@=§9áT¡“„]°Vó§g äU3‚)8Ï\RašUîHqh^éÉ|Aì—¿ê½+¢pÌó…:Émo Rÿ°¨ó„£´W¶¬cw|tTGY®õƒõZ–§¬6Ïqò¤Üå”&'0ŞğÜ ÷hÉçau½¬ÌË9
†#ış¢¨NºóR)Ë~¢‚3.ÿ’»ÓÙa4ôR^ í³­
÷7Š;ÔîÇÖà÷‘¤³5T˜"Ÿƒ"£cà¨[	¸;2ÔS˜k‡œ3¶ô„ü¸<{™cá05éÁGÕrr²‹€gÍzÑqŒ{!ƒpù :J‰´«iöpuï¬ûŞÆŒñp€*áa¹ô‚6'ø¯òzWš•m‹YnÙŒKq÷~•/%R¦(ê¢¿¨³øâÎĞ¤¼ÂªHƒ$·}Ô˜ú£ g%CÀ'|p]¶H7“EntÃUµøR­øú'}ÀL>·Kªwdj‚\<4Òp<w““³é :÷ŞY*!¨½ÕXNå0¼UÏ3ªyåq…ù¿æ)KÀˆ-›Yk/ù‚TŸL²Ä—äí©_}–ş	+'ôç'jƒ*bLs4dç¿ú³Up_•È"Y2ğ>¤Š!†Pd[ûHäÑ6Ò0˜_š¿Qïıª*óñÓŸºª4³„ÒFı){˜smSÀ&õ e4œí8“64ièÃOÅ¨íÔÜ2Ÿ:zÌiÉ–Ü¾3—®L¿5 ,jÒfu	‚-‰§Q~EÀDéamÄJÈè„(;ÆODãŠ#V¶°-VŸIÅ,ùåxn,¢j&ÚµÇTs¶ ®~ì@”‡-æëÔË$±›¦ ÿRTñ>€T§ˆ„m©7<áóHˆÓ¦‘h.Ì¡Ì/tXôÍm‚)ÏÌV1\­R¾b¹J#Š0R­Ä°S)ª+w‹}—bF2w=Ms¯GoåÁàÉO+ê» †gRzÌ™,€…}óÔ|&{Œûvz­w•‡¬½…»µCùªåz-ã‘Ÿ/æÂ*¸ª2x>)r®ˆUŸÆ®72ŸkÓ
—§D”wÊÌ§Qâwš¼u±Z)á}÷N}^ËÀeNê‚-;ÿ½å`	Ùpø£Ï¦¢„ÇiYa›ŠCÇi 4¯ÉK›Áq´
}±f*š=#ÆM-5{¹z»0-w:¯à˜ß) ĞAŠ;R·ËÿÚıˆ“j÷Ì›áÙ¶îÀ«è»¹muÕCU -Â’
Öüï¡õ"ÛÉ¸Ç¡ğêL•¾#ÿÃumzuÃÎC¤9]PÒıU<©@u3â‡\Rñ4ÒÙÑ@ÃIlsY{:ĞÌ-ˆë6îmôœ¦MŠëÑ3r³è"R"æJD¸:S¨4‚Ó)¦¨]t‹õg£ÕHı°¤Ì>ú¿ÒXÖ2â0>`E¶ù%R«»EUü>aÄÖeÿÌ£É±}ì+…®+øş¥xæù^¾l
g¬C¥e˜Àaî²_e¨"”Pì½·ŸŠŠk§¸„ÁdÊpµÿ¦èêùq¹÷€–We>Å“EÅıÿbú´§|U+a)Tnğ¨>Å Şyn‘†8˜ÌxÇ%‚é;üXªw$êúOº üZ<_Z‰w}iËñ´)è¹œ1–åK4"Ã°fşL0Ö—¶D2†uQbóÃUN>"¥Ó7%ƒî¾Œ3C[ƒ'ÀX‘‰è#ôæŞ”tX «6Í–j$b—İ¼:Tà{«WXÂ1°b
3îeş"$¦ò/‘o‡2T¢ßƒÈî™¡0ì›ård@Ê ëfÛ‹~÷yä'6®›¾ĞÎUœP¯T^ĞQáÅ ·R Ï·35Ïuòs½§¼<3°¨ëÈä…ÑaKÕ‹qV÷É…o:"	ªu8 †b¾()¨ÖX™®œr¶/İâ[Ê$ˆ¦ÿİ‚óg`ÁÌ½Ş¨QŒ¼J•Ğa…”séˆf<LÁrU§ÂW={Ù=şİuÛĞ1
:œÕ-ÖSm Š¶
vtj'g·K¥ÃŠ7ï,%êScÍ.$õÕ#RiQvfÔZÎQçşÍĞ×j…LÓÂ6èÊİ§ƒx‡vrIroîğ%é„½µ‘ÃİÚC¼ùÛEœ?—ÖIŒ-ÊÆü,…Ï›CË†gÊ`tDY_xğŠ8İ<¶);qU[_*BÌò¡87™ªnÁEô¨DÚrŞó|·Â[TŸ”‚ºhã½Ó&ÂÍÔæşó†:Lo}`!`£NJ_/WC‘K´®Şüaú…|Õô{uåõˆŞ^Óì $è—t¿M–’OX‘ÄucÉ…ÖD«ÏóPçŒ£ÂÓ€T˜*Ãv½ŞfvZ¤Íê¶— /HıŞH§%ü‡ò#ŠTa€AíÖ9o¶/Í(÷¿‚ñU‹¥qm«p„-8wU½=Œs®O”(TJá¢¨|PÏÿk5§‘B€®%º¦^Ï9×Œıa®£÷ú¸r–Fa:<*†«VáäùÆ,³¡šÊ™(ø8M¹Ci$äò~(àíˆ»RÄ	5L¶B…lŞ
<}#D;†W¾Ã‰C–¡æbïœvu¶/«¬„‰]
bSf%è,¦[ØMËvR¼SËS:
&'EMÍ?m·©ÒôIeV§ªtíêİI”øÏÍEWíy™±Åˆ¿ìX]Å¯-,¸4Ş*¹¥{ß3XÚßÕfƒ—%Dw¢<¼Sõõvÿª¹éæãs¸”dz=u]Ê* Öß-ö¯“x§}ÕIÔCÃ&%fçÕ$f¾İ¸"ºY<ˆeõ$šÉ(ñà&S¹æŸŸ]0ÜíŸc›¹pÿeuÔt—<Éä«twÎ¤ó\pİ7Ÿ›|(¹õogvt¤­œ4KöÇùEğàõ¹û!¢ŠÅ_UÏèõÕÒÎƒs®vJÏ~W9+ç™>è4ÊLÑ6U·J0“Š,0^AÙ–el 4QHª)qäñ–(ZïÍqĞægAR.Âî°9¹„¹Òß0|u³¨Ü…ŸÕ6¿ÌÅ`º8­nˆ‚]r½Š#hq%×‘=û›Ï_ïe¾™ÜKÇŸøº>:Èèî3Ç©¿ÒÍÈ+ÑÌÅ€“Ä`CÊì¶X™Ê‚l1½Näñ¶^Œ–Pïùå_ºv,Dyoƒ¶HœzvŒÍ[ì?}›Ã‰¢&0y íºwúÂı& æ¼V^X ¨~2t%øƒx¡z¬êwÖkc9ÜfûÆøCBÆÎÉ¯|·¨I´s«snı°Ë±­?Ú»ŠÌwyãş.,P9b‚ú_çQHr¸•Êş¶>ìÈ:3q×ƒ•s4/œ	ä}¼"sä½ÉÕZ æšR§¾õf“o„2ıY/ÈbpûM¤Dõ§o…%7Eÿ¬//%^Ù·İ97³ŒA ú¾Pş#ÎT/–å„å©á–ykF ˜—Ô2“s¥Ä(}a0:oYØº¤8ò¦¸}<9[ÊğúÈ…¬ü/¶JÓb7òªZÜã#O>LR›oM÷Bæ£ªízM?Ìs…R8_g€Lãù@LÚOÏ4°øŒÎğ¾j¾Ò^«­Ò35Ò¿^•W•æĞy+ğÏOä1·”ÿv^ôK^:h.„½(¢¾Rj1Êâ—0ÂZ±(|Ò=„M,¤æÖ3§p^æ/×ÇŞU
{Ióğ²;^ğtˆIp¾¥kf³İ
ğø
T;Óüôèø€DèÖ¡â%ğÌq?’g‰´ÈkœˆÊåšeWk'CÌ¢—MæÑ;C¹éâ}âxéÇsqá“MåY‘Y!KÏ¬¨Ÿ…‚fEn±sŞïj¹ƒ±Ã'4ÁÓ£Zˆ¯7Aã|µÆwÈ@ÊÔ;öœfªRCä ’ÈPİLD\ ñ-J#hyâÍİ‰*ÃìÓJ•OÕ2ßŒ~"aÂÒ9µøT¢¹ÒcNıÑ%öò&g£ø·~ÉèX5èz)8Ğ‰½›UÜÏ½­yæó¼Ùx`KQD ½s¹°è;4G‡/W,iñp)öÆ¢ı[%©^KC‹³øLşÅGğ_÷·Ì¼šQÄÇúpüõ"ÆŞ½‰°š'e¾WcÚÍ„ÄGØŒGLcs¡xÂÊ"*Ìh½Ç¼/‘#û òa:<¼gH`i ”9!gœ¥,}•Éö‹’l_º‚ä]æ°œX·F»íá4²æÑÂLšÑ1„)Qì“ã¦Àúo ÿßXHeç şjXæu>tì”ñNxf2È2wãÑuĞÏÇßü=7#`ümØzŒ°àXìX¤êİ„ë;(ì»tƒØ„TÁ ò	atƒ ±„Ç&ØfõH€Nr¥¥ê7óı0ƒtêxá›ì/{$¼b"şo„C¯¼R
p˜Ûâ»¤šlÚCKsDÓÙÊç”GL=sQ¥Â|UÈbYTĞŞÉZ“|#¤G7=O“æŒüÇC„ÜER3ˆöH/ÊXx·WÒK*#¹â·ª«:OÃ•Øû?Q°	Š©³Ëª‚iVd~õ“³€Şl¶V»û¡]põCCÎÃ3[AEĞŒ$Å(÷ÎM#'v¾b5µ~\‘BDlJÉM„ıÕm
G`ÀS–îqZ½”GãhNNvÏ5&	5ç“‹Y±¾°C_®ul@Ö‹ Í†^©©RË[¶­ñ$N8®õ8áH(n=è–n™écZğ0ù—Ûç[ÑpŠ¯÷ÇÊãÀ]ÍÔÈD+`o(¬Ó2Pt˜6ı6p¬¼kË†&•Ùw*Yù›sPİŒ= êZäEÊôæÃµ,§Ø9…ŞâŒÈ÷V`Ï‚±9øNŞ.¼w¦rî[—]˜¹;‚6Ô]êÃ“ZáSŒE‡?0.`œ÷®¸|‘ôOğv®,œËiôíÕBwM8‚Ä,?ñ:ôx+yÕ^kÔş·Áß;$±CÎµGI5'„÷Ö0ÃìğÚÑıö_ı_N*¦£tŞ)ü3²ïØâá‹ßÿ]Óµ–°Q¥{Œ
>ˆç/u2[Fcìz›J‹%‰*†)æb­§úQ)òïåš,NpÀœà]´àœ˜9ë©·ESkn)õ€“Œ œL\‚àûøQ(&fûvĞŒá=9CZ7`¾~%%ìÇBz4 ‰­¿¹çëeøj[ÃıBß¼36 ß8\´bsn}¨Àæû!Jøè0by©}+2‹_í<u,®ö]Õçù-ÀÙqÆ%<nÌÖé#'ì:¥qëö/âGl Î‘dŠ%v§WÀ0¯¿Ÿ»É£&G¼{¨éóæ@o§›üxA_=êRÇ·ë«8•Íöpxî™@Èiş{Ò½äká×ùtqıÈİ˜a¨³;.%«¬æQ]ØL.#è)Quxekodô¨J:B©úÎ(jEp±Ÿ|$–Yâñgw¡t½=oi6ŞÚŞV6ã/«7"È¤ôe(ÊÇC]‡{}™á5‹hõÌWH®8Ğİå~ìÑ"ô.ÚdQ¡uÄÄB»u7b·Xa'ùd™ÂCÙ(¨m&Ìx%"¼Yi@H;İ2¼†pÕ²Gh¦tM¼ı}:ìDå<ø'ó{™h²±.ÌéLø3‚p$Ã@É$;ğ©i›?ïLØÈ¸{zØÅÜİ“.ı³-à×¯ĞH—¤ùõÑ¬ÿÌ‚—äy³½@…3S?a–n)l°Ñ½®2ôçX¦“+€“‘è®ŠğOHÃR°"ÿ‡´øùQû„ÂÃYÑek¥QËìqW.øÑ©¶.Œ¾¯"£ÙÿäI°~$‹_üWÌMŞo£\Ä¬e§W¿ØÀPãå»Sª=ÛC‰ëPå¨Ù–w_S¹~™Î…ÃÃiHf ãÅúoc ÙïTÕj–62€eíï¸q+íÈ—]L_aYÔz©.“FÃt "hB-„]…‘Áç ¦+7ÇZBÚU¬¿ÓÆæ6¤†Ì|H~ZC"Ô)ONh].	N½¶º0÷«»ÑìTÅK‚û¬”˜[HMƒ=Diğµµ¿gKîÿ*SÓ\ŸüùRªR/t^¢†İ‚°Å
èsaşÁyµ2ÑàÓ\®=lÇ‡;íŸñÚÖEO'óĞ:¹åd{gÏÆœ÷à âöšr‡°¦½Ô“›“¹ĞÍÚ^İP›I‚ ¶Ğ¹îf.TÉ-¿7ıãº.·ÇPdy¿ÂĞ9OÃ¥ı|‡|qkO¶˜éÀC(êU¼cËô‚ mX2Ï„ìoPOü‘gbÎ­»Ğ°ÊE.â¼ËaÉ‚QD6oa]aYOíS¼»ıa.k:f¡åá	~Ë_ÿj?1–‹¤/¯uvÈß"Ñ×}vâ-L[ŒŠ‰Eš––Å1 Ö{2¹öµ…»œ`€Î“ú!¼÷ôŒ_€«2=Bğ+ÚJ]0şî¨}‰Üş³¯Â+'|.q ‚^ïÚ÷N³X…>qÕ´J;(5€2Æ´×¨nQæ‘!İa!ö¤O)XiQ[L¦N'”‹>Ì-ûÖoÑ‡g†oùÔ-AGG	+\h÷èÜÑƒåÚ™=Ô=ud!Š½]v€vµx*Õ9“Xd¼v˜£wF|$úfÀH¦ö9È9€g6¥•£ôeüf·dÆ ›»Ç9—Ãér'ƒè£%˜ËÇ¸E>38åÂ˜²s¨q7:Õİ9 !D§ E		¯võ&“Eî)…w$#«ß|ÖPD
ıÒYUáİ5÷së\'éâ½haÈšñ..Z»rY7¯îk8ĞoˆZñœ²—/–jÕs*©_ÉD«÷›ˆlqkœêJ-ê¹§½èüt’\ë^ô~nø¬Şµèò÷ÿcwTõjáš—s²OÓ’“n#¨½(.«{’e2’^QYTWêı°/x!òMkÁ
ßˆ¾ÂNMƒ]cá€Ôs@ã†245Å¨$9cÌ.fE›æÏH~äöˆ.¼ VÀëWÎÄT×3î6ş8ñÿşi¬´ş·;ú+`ŒFs·º?ÿQ
fïªÊî©åLï?bÇ÷OŞş1òtû¾*^ñÆÿS…G=01J*ÂD³ˆ4b—aßnEg¥v7Ê0‹5# ûºåü‘ü¢Ã!ıŞçDÄgŸ$2òÓ(İUã®‚˜ü¼M+à
YluÖÑšŒ	ø_l7·õ›Ó¢·8IVZ%,¢Ö.•ta…]’„¦Uş––É:k¢©¿ª‘²G:34ï!E@È=|Ò¶ In(Şl/+År„øÖ3µ÷R~«¯z»èİ?UÓÀ±nÕî¸Mö™Vª…’g«¶{Š{å	–&¡ ÿÂ´òEİ¼ó‡ÖŞK™Ğtóm{”ğbâ†¸5ÏÛD|ò¤¶ø+|Ï»/ü$¥\~D E*`y5ª“Ğ o$ê^°EÇqü³Y’¹h)}‘ÓL’04èy»EÔ—+Û@Õ[¦ì}ü¯”5jÎä™SIÒ§>‡¶ì´@æí>–æYƒáÓ¤½^|;YjPùÃoúÀF¥©Nxw:QêS¬Ú(Ì× @Jñ‚Pèiuûs½ğxekldµuMÒ5üºèsŸ\MÈĞ•Ú:³dq0¢W»'pÖ©şš)Šfı .ŒúitÔCÇ_Ï¦/³ÜyWq¡u”`³Ôã¬>Ÿ‚ÄC)+ØĞ„4ÂÒ7W-	7*ÇGÛèn(Qêà—°Ša÷TåSsU¹úû¼Æ€çş÷Û¹Óæ~ˆb€2%\}j¼à ë}Kà}-Š5œeeVxY«‚4‚$û¶nâRŸÊJ¬JÏü§Ú]ÊÜÔY0Ûüó§sÜa'ƒç`:öJaÑPr0ïÊ|q0«L×»ebeZC<T¨OŞâ¥[øì¶ª¡F¼0,Ô‰Õ5Ûùù;d©X©a€ E¡£ºÚPÌpÆgŞd¤XÖ[Ì®{fœ'¾5?Õ©ó„'Î4DßıªÃ#•Ò=0ï U#éi §xUmá£ÿü›*ßT±$²š>•CvB6¤›Úç»f·Óùªnbƒl|Ê!Å³XÔ¶!ÑÃ¿Ù­‘0Aİ)Ã¶ä ¿uŞ•è&NºMûÎÎ§ÔOlÉìXu³6İßÂÆôŒÀîwGR_*&“ˆîiËÜ6¼BÁ°üqÆq‰À…`÷½êŒIkjó¡^Ô	ó½ŸqMá»/¥Â±ÙÌ|eWø?<EÀÍ8®S‡¨XMHáu¬Çæ<ùE5c"ĞÎ´_euîÇ+ÌŞ—Ô«úı¯ïy½±A<uØ “uœu‘4%MàÏÂw×œÖYÀroò†;¹(uD9ûIóøyÊ(IİdÌ(‰ô¢Ó>W(ôpw,©AİSÄb#ç*›v
®ëåÌ”ÙØÖıƒ‹Ş‚†4J(q˜G±‰Şí`Ñ3n²{e¦.æ¢Ï
Pí£când=Ä9¾„,œ¢îg‡TÖ•âGº,ôÃRPMÀ7›ÅmuJüø…K9ı„>¢‡ÿ‚œ”äÙárÔÔÀ"¡­œÔr½õøI€£Ú¯ÏM{Ğ¤pÔL);;oÿÙä ÉQœµ´L:°ÊŒ.¿MÔÊÚÜÆ`Í
tÏåÏ¾8”°„	—Ùğ1"gíá¡G$Ø÷lCÆYİn@Lw‰°Wè‘şC‚ÊÜN†ºœDÍ_‹¤[¶|§Ï1êÎ²úÇ§ ›áq;škÿ·òl™È«õjFïõyX¹‹sÆÎQBéİïB˜'ıYœM)ı05TÙáeÛ±¹™¸¡˜Rz²vUÑĞİJ˜a¥@´6ÅdZ«‘à1í‚>ÂÃ¬yaj#i¤«GÃ¹Q»'b™e¡³‡/Ò’ÜhÉõÒõ<^’»ºéè³d§Pù…ƒ›+§fÍMóÌb÷¼(!¿}¶õxk—¾tV·ÅHøµ…„Â³ZÅ12~StF“‡3nÏÉ|ƒıü]«lódk#À“Ä ØŠ¹ï³w$[
w_Zo:V^u:˜6`º»ŸB2«Â¤_´_Ée¤ÈíàqıöDÒûaŒeÒÓéX?Q~rÅÄÆÓ[Ñ™äˆØ‡k[Üc5~ñ+iæîJPYÕÊŒpA°œ[ş(Uª}ºÀN3B°¼2!BïÀâıgÇÔ¸¶9@¦÷ğÇà÷Y7Ô¬|ŞQ8°"z²“7@/ĞYWÚ¯+‚æèfï‚¯B{#1ë:…¦ú§Ÿ	ã     eRm×Ò, Ù­€ğpú…Ú±Ägû    YZ