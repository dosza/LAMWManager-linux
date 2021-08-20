#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3450679936"
MD5="4c82dd7dac50491a63f8fb9ef0ef7116"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23568"
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
	echo Date of packaging: Fri Aug 20 04:00:30 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ[Ï] ¼}•À1Dd]‡Á›PætİDöaqÿÊàéãXŞ§q?+ëÚ•É<Ó½kÏ¼ô¤¾|#|0D—¢Ê\ğÂè—ûÌÜë¦$kìë©8±|1–×Ï•S÷ÁÉÑH®a& ÷öøbAŒ¸[^ö›!¸Á\7ÈÀ4´µdJSĞòËGFJ
#¯^Ab¶b7Ê`İ3¾)ˆº¨Q+ïºÙ0›Jr çáVN5ÊšZRÔ7ûÇ¶RılYŸI\/ñ5/¸NzL©o}ß¾ÚúG™x]	£PÍÈ6¢ a‚’y9¹ï³¨—°¥*uZ·]¾¿³f¹ãÀ0rdÏ\Ù8H¹Ê ´“eWçK6C¢]ôİ¿p¾L'Ä|}Ö¾¬¼ôrOqı7)gğÅÕ°d•^ûøØ1",Ôs§>è§¸‚tÔBƒ[òºäğ«?gxøzâ]vŒEƒ‹– @K®~CËå:T1aÇz‘›	3ü÷Åü®‚ôUW©Ê¤nÉ=dÀq—oÀ(	ûŒ_µçÊeÈá•yb÷´=1ªì‡Gì·Yyì@ŞN³p`œ€½©è9¥IE–C$sà”Š¸ë+'ŞHWt1q«ğá³¸n	B¡=®áé2cJ”UÔ¶¾”òSf¸Ã†8€ĞË„~—c‹2	,Çàò„vÛõ\ºTĞéÏ«ô9M»y¾­…SòÚ3Œè§‚0Úä±áTÇªG¡Y›nÏ}
Å1dË9‹sks‡—$‰2`q?Í9€D¾¯°¾9J¼ç(?Ñü»ˆÂ€^«àÜs)p³³Ø~îpÃ4«±u°ıT°èÃğ.Íã¹%\1J«ÀSAiapĞ¼$Ü8g ç!ŞÇ‘ÜŒ¬ãnîq@"ki…¾G\ÜÎ1£¿E5si¦	–¸¹Uİó<õ“u¥Ñÿkı÷H9íƒâÏÑÆ¼ïdİõSiP¥”¶œïˆ@{Çi; tãr}A|{–E'9ÁWÑoFƒ-ª?ö„Kè¤Ş¸^ªk^Éƒ«­µ°C-Hã=Zsãçpôp"”õ†›‡¬µRŸËã\kr£û¬Ÿl¯©a²"³·%n;ğ›¡ï.„DÜ\ToÄ6¿0”ÍØ>Ã(Ñ»7Şœg¤Òİ¹«û¸ˆüŠ¼°k9C^Ô‘¸´‡ó+¤ƒ}P¡«BİGPöW’şùsÃQŠ«4¾gÇùÿE ?¹3%PÛÈMÈÛ^>YWo­xÉ+@óæôÑ‰ttW<8+½æ¸,Ç¬tˆ·ı]›¿Yö½Gvş'´³ºïéFšÆ­ÕÓ†}87ä@üµ§Ü¹“º)QdTÎüÇùğ¡ËÙazY$…“ş)á%Évë‡¿¦`ş•íˆ	İy¯¥ºjÕl,€=†¥õÕ·«»O¸jk—imÜ´ŠÜsÄ}a{]È:†<æ@î·{©¨’J¿??ÂÇ–3Kğ£ı™J“*YrâTp¥2@,¬a>Ë²°·#!l–Ì·¹©Œ¡p¼sÇrßZq]a!9Gc@InK¼~5BìP3R‹éNû:Ö­z–Z_µVß½±JÍàR¢#ŞŸZ‰¦L¶9qYáàå¬ğmykd5è9s<òÎyÚşA‚¾#ñìj»*¶ãÆßè>»HOW8e”¡®Â„'+WÎÁ‡Û°B&  ›ÄsœÂß2ş*G{¶}FÔÕZMIdâõ6¡=sÈ]  ãêr`Š£´±¾NLdÄCI“ˆ.¿Ò¿Ãó¾cÉü	Çiüù¯cçÎ?ä"X¼#H£€ù	¡7ÑŸoq!ùØ³^}Æs}Ï#:Ü¨w0óÂÛÊ¼|å ¶h0x¢²rræ)†pè]yhü"¡£gb0e0¨U"<“¾š$ö&òˆå{œ!«ièğUäUD é“FØHñn)Ÿ¥;ŒM
¡Ğh¯Bh=‡AK“Æ¯‘ia–ÁåV:ûNr¦Ñ½œ.dÜqõ'µîjçE.•¹­ÙØwv
UW)pÛjÉÑ)Â6Ï×Æaèe·lûÎŞÉ•d÷My€^½Ş›ši:œ¢.¤Ù¦y1}¬qŞ½·ùßgSB>>Z3^£´	XÔ/<¦àÆÅĞ‰Œ¦¿Ñ,…ŞRîÈçK\‹RÃI:ÚüU1Ïxg®Q›X?•¼]³æåt‡éÖpÍÚ\Ú\/§ë‹MßÍò¨‚ñFg Wn#èHŞ¯kÚst7ŒtR&°W
BxI`Ÿ'ß1›tûP³©6EÉÆı­´¤jI¢­iú9K®O”›¯VâŠ‰W[mâ>øªcÛtiøù¶×É9§F"3Æô$tb±T Úo¢şhou¼PÂoso.£w|ëD¼Í¼r\p³eÃªlå¸£4ÎPóW¿dGlß~ª­òò“–YÃ¯ã’vJ&Kí—†x1ßÑ™Ù5S?£eåkÆ˜š‘YÕ4b*#¶†fR,Ëi9;ú¤Ñ ‡Ó8>Pc*’Q“:àv',sÄ••³tà€¡áÿÁÂoë=c#&«Qf¼6‘øäëjñëÊ†ŞpÔòq†2K¯	­’7¥ØEû<é}D—e+¢ß‹C­RCAŞõĞŸ0%ªÃÒáÏà—©lİsı@’ÎN	pzë‘Ô÷¬à¨âÛì×há³å0İí9(ªÒwKŞl!©^qœü*¸˜<³7FÏCo+qZşæµ‡;sƒHK-R–·Ityßµæ¦¶
Rñ˜•_*/,@hAß}rSx¿qö›Øë„Ü¢•œD¬E*£wMR8€Ô”×Õƒ†øAñ 0ÆŠ‘QæÏ ¶= Zõ<çËşLıîÜabfÎ3º£XÌê“Ø7œn
£-g$ÖŠ™°Â{½$	=Š€ó }“Q+’íga:B•ğ,‡‡ÖåKy»ÊmávŞ_’Ô;Êı–(¨I^¦o-‰30cË›¦G„rDÿnw‚SÃ†6â1W,UÄàôÜz¸å€cÕL˜Jè·Aˆ8ş£U¦§SÕVQz¡ô}ñÛšJ0H¡íjw½F¤å
Wò’éüêMãÖ"ho}Yì“
Çv†$½&øƒã5œ ™å'‡„Wön†¹G¨ã¥Ì#ß¶×™s­â/Tnú²÷©ç&mFMu0•6e©~ğrè›­Ì§ìC+p‰8Ú#ERÎ¬*•{±ı…5fÆÖFœçîµŠ‡H'j´(oPùŒµ³¤F`øâİ-’ç»o/2ì“$ÒìÎ@røwšJÑÉ‚J¯Ëg÷úš¤‡1¿Á®ü¤€œhcûºb‚¬Íììñ§ANÒÓ?¨}´îÃÿŸæ¬xhU+Ò áËíç†áHÀß›Oåµh27ã††¡ŒP„oq˜kõè%4®ˆîk4Svƒ¶NÎ?ÁİâÂà [¢§æşO(Ç»c£«owúˆräPºÖ›3Æ¿2Dgr4y–€y/#¯¹7|3 -î‚ÌÆ³ÍH–1V¥•"È0L¡aË¨È»RŠ*SíNiSğËWïVˆÅC[â1W¢ •‚èg´OŞÓà¨ù§ÄÑ›A·r•^(`eR,Òç\;Ô Ë×–-:’JíÊğ‚U‚F5K<YÍ@°ßn6fõ._Fó5§¶Õ/¹Ç+s³Ş^ÍJ„Ğn’¹ºÆ©3–vş¾–Õ§Xj5äs¨ĞDÄ¨}ñ”ş7¿O†	®>kd~²´ã© ²½§É¹OÒ<ƒY¦Şx“ÃÔÕró£1 ëp„Û…{KÎ¤¯ægRGE.&šôõÃ‡Ézà"]tñ¦üú6ªdLQˆ™‚FÀph[Šgé‡ôA¥¨³ri™8
¼m¸qYñ>ª05Úî”(1›ü¢Å ÊİÌØÅY×:¢rŞA:¤ä9Y©LÃğ.¾ÓFié£Ò)ßÀBåï	ìÔlz=)CÓ’Á«?Ó@@RDGœõŠiÙÙAKY£/š›)ÂÓøÇ ŞWÔ^Ó^£e™4 wÕ\­Ñˆ‹¶HL\óYÔ°µChI÷Üàô€¦eT„
ÇI«ğ…î®“hwÔˆ¬Ê:ZË-C5@g#
GØx®„XZ?ä™Ecşk˜FÆtÁo,üÇ!;¨/ÕÎ¤bƒgm¹¬Ï‚9õGÓèõxc:ÛáP]Ì=—Ze	[şõsBm*C¡1£~õ§^hâuìø¶7íÓÎˆfLëUs,öóäiŞK›¾‹ÑLáÔ1!Î7ïıºÿÁ(âã$nÉq2ÃĞ¿ŸSöå@	Ğ¹$ dò\˜ø\…¹îÅ£\ÿS}fÅM`Å$A5QY³!í‰ª=1«®J4¢’0<±ÂuÏT:]€ïşi67âÎïßM³œš0x*.aÌ¹Ò µÔªÉ(¹¥ş±1Î¡(‘Oav0‰+ÿÔÍ²ş—ZÆë+ËÒ½©ÔWÈ÷ä¶"KŒvtf±m‡êdsÄ°C¹9†.¨ßQÊ9åfKúĞu™ş ÓŠÙƒœ¦Œûqßş¤mHÎ ¹q
"‰óœÍ@SÅ“<î©¿HÎcqvË?yˆ€uÁ~ÒÃ;Gñ@g'ğZîe”µ’S·2Ö;ùQ¦JêŒréAdi³UFe³;3Ö!Kß“¤öôÅ?½r¯Ì€ÃtoÇMH	|¬üÔŞË9¯Èıä^,ÿ+×‹W£88ª8;tÒcNëG]GMP­jrYº5¬—ê	jÑx>níp[‡~"g¡Q>ìÌ ÑDŒM¤Šı1]‰ONüq¾jÖ¯÷R»<ç`°DŸñ5Îã'O®VDùÙTDZÎ}ŒĞÌœfw!³´ıÕºèhÍl|øÚÅi÷xõèÈg,¤ †GSÛSnA©K¢Q0+¶ˆ)zî1Ú,û'Lãr£ÜG2V¤¹àŸas¼×N;ËÄ…ŠçŸTğs–é]‘—Ç•ùùŸÈùz(ÈÈ%;åÒ„ïÀ^!•1ç» ¥Ş{p3¡·6¤¸
¸úù^uµ*$+ç‚šx"“ÏÑnÆL/F€™°,Æ¾ÁKy	†t«'ìœ?‘ìbñh±_ƒVˆä´Zøõ³ñ}şD¦ÔgŠû8yäÚãi&UùğÀéYıÌ¨ ¸ùÒ>+Ä¨X¿@ş3ÅfYnõà|Œl@|®è¢i÷ıĞÒMNŠ13J?ƒ ©šg×ƒÇìUºA+Ğé€Ğüâ	…(Ø¨)à)NH¬oö{3‰c´âYß‹RÊEÉócUïXGıÆß±Ê“º&læ˜{,_’ğ*/ÇîÆÆs LK  3şã#	[ãïZÛ¤UŞÙÈş'çö)ƒá¹“EAèš-™æfs@†L]É©ÍD¦«(Cè–ËÅ	xëşDSé‚ËeäÍ Ä> 8Ê–†2²€{ğù¡+ñÿ"VÖ®CÍƒz;·êŠS%E,à’[KÖ»"£,í<,	?u¥¼‹`¼_Ô=Bc¤)k’i?ËFÓ¥=s¤¯ì°»@EkrzÁšåtÊáxQD6İ~Ñsêã Æsk©g…3¹Rÿ§hiDõ¬øyfc…Óé.+¸±TiÁÿÛ~€»ÒCQ‹¥wüir!2şts:ûÄ¯¾w)ıæ©²%\Ô¼ rî4Å	iá$<æB œÒ‹:ÍßğôlÇcUœX¬
4æ«KˆMI•?V•~+µ¸ õwA4.İtƒ?P]´ñÂvRCİ åÔÎ½àÉ>\mv$05²¥˜)J"ïÉÏ¿®—³×
FØÌİ¢K(pÎ!¼/6—T+ª°à‘„n	uØã¥dÕæ]"`5â'Ùš‚tbNÑ³ˆÅCÏu+Œ÷ÿZbU[BÆúŞ6Àe´½ù°ä¶sP«eÙô„€¤Ï{r½›•Y™Ğ#Æ¾dhÕÁ0áoçë¹0TúhÉÒ¿F`VS?/»r³{æL;|d‰.QæÆÙÚÖhÔ//Ôm «q¶3œØ)"hûOÿ>ÇãdMk¶e-ü®_Ğ¯WnÓ‘´1Ÿöw.ü"“0ï5‹YÂÃ£j1ù;£Ä¬DoÕ¼w	jüX_’¾—Ye¥ÒWàæİñ¦T}F’¼ƒ›
lÖMºdÁõ4ù˜¿¶¸a=MS…')áwú›:dğovšái=…Å®O>;nóÊ[hÀLËÖò÷¨%ÒİÜåf«`tš¬|£ØsÓƒùY%ş$—¹=U{Åäi1xÆP2•{§Ú–±{­EâÖ‚¹ÁIÄBgN?šĞ0“/Éj~	ı°p/\¨±8	.ÇK{!§..Tn†ÁÎ#3jr~€Ş£nMÚÿÔA0ày°·VÍ´àw‹ax½“°o(Ÿ4„ÉX£²äœ”ôsyy~Úwª5ëçíÛ/0qµâgKEÇÔÄŠ¢GvSÏ;[¸¦™ĞÍ¤Vb_µvËûOîºC'5AÔ×Üe8_Éü z´…Ññ•ˆ¾Éˆv´„[{²ífa¬Ä­D:ÁSãañ¦—ÌÆ²4ğK©•\l9×àÂv0¥?Şìl}˜=9ªJÒd›CÛò¡5‡)qY½P§`G–EşÅ	‹ægù-±FË¯VxÛ‚ÀIâyBfF2Úœª„qÂ.
ñZG¯WÃåaÚÍwşA¢Õşq£çMúIÿÕ)/˜/Ni[OÂYI`Ar†W61¾$Ù{õp—B4dU`¼½o0ËêÒ|ÔûSä³÷K¬×©³J_V¦ùq•5v-òŞ¹ÕêÍ-«v+9g¦$“)ÍÚAkÓúŸŞJŞ]s[IœºzE TeäJæ6·â&I«h$=;Œ?øbéO#WŒ¥'›»‚ZWDë›îZÏ²€¿(9EØ‘'Ùaõ"GûNgZs—™x%`†ÖÒ]	VD¥ÔMâ5,#ò 	Udcıø°ˆ¯
Ğ ‹’…÷#/¢!GŠŸí`alR=qEé‡ h ûANéõ7Õ›J×=vXvˆ¿ÌPº‡)±”äÑ¤Å4Ìwuê…8Åk‹ˆxmàt'ü?Ò… èŞ?¶Y+I€hæ\4ß€[k#˜YMÏç“E½š
í6ÎµÜçÛ€õâ8GM"vçn°AÿÃêÜO0ôä°ìç©×6lb¸ä¤®¥¼+dwÚXhÄÛĞÈ@ş?>Á«è6>^EÏzî±êî5m†Ø¦T$ÏĞ½(" M§<_®‘=ä-ô¶H–_¶è¨{–5/›‰„ô‰|Ğ¦4ˆ^Fmb>>úÚ¢’sI³‚ıÁâÑüªÎ2a;ÆÊ$Î4häÔr9iÓ.XÒÉ¬BòŸÌÔ+›ªkïiÀéa+· ‰øf?·‚ºäåkN»Ü"ÑĞ“,¶ÆÈ–:õãdªšÃoWP .“”È—¸ò ’B64ı:ş¢PœG“´àU.7³T€5pw‡âhßË¶ËŒc³npQ¦j0GpŒñı¨Ğ7(Zº÷òïWuS®SûI*"¯°ù‚—kpT(»ûTjĞÛ’î bõ0Æ„SåÉTÂbJ>3¾áo§Z×î8ç[(sÙÅ
e‹fX·šI$ùbdæS‹„™’4-w¤OÒUW}lsbßïpE A†òØÓüÍwíœ¾‰p¸ŒÖ¶;oè´3ßÒ¥}Œ’àoG´e[oõ{èT'+Æ÷5PÅæäld±Ùl9vˆ…8`BYß‘0‰ßáøÄ¹ÖÜo¾ùîô§"Ï®.Öµ3lÈc8êŠ#¼KÄŒNà2s©!Q®´ö+7ÆµjØ[Äyñfö½Mş·Ìô¤ÙsKwóü´Ïóã›=v“vRİÏeMvXÆõşÚ;áQ7¬hvú§©üÊ1ñÖˆÕ/4(—>üe~G[Ñë7+!(Ú¢ÉFÓ3Bğ|ôÒTÛ{ÿÊÍş¥@r=·‚&yD¾¹pñ¤²ŒGyÓ>N[¸2Å8¦Òİú¡v|·~ZŠn^Y­'_^ÊNép‡Â3d†vaqœÿÖr7`ÈNõ
:·-p_Ô|TŒ¬ä8‰Î†ZeÊWY>}Wš¢Š¹]í(R½º3Ùø1€’#¦©G™K¤ß0—6nZÊß´ÆÅ*¦·!ÄíJŠÑ›rî/·óéö¡ÑÒÅÍú’(D›õeD%–aÇƒ¿‡†£\ï‡3uµÙÀâ“•H'jMyÜ	æ2Ôş+e=6&íùé<¡º-UbÎ9ü¬0ş	°/KydM7
7ã“×bìŠØR #y“#Š|BKò³ ªèÊÉYë·2î›­A5V~dîú¶¢#9ín¨8Qvâ×#c¬9‰vÄ úŒÒ¥ãş¨o¬ÍDšÔNB† ¡éß4À“ÏY;{óĞ#«lŸ°Cà´™}Ó^ø ‚„.ğéš¸‡H…ò·Á·ßÑ‹bR{ˆ‚5$íŒ”ÂêTÎÀ*p‚øõæHÓ^íÓEşj®åLı&ãmF~—®]ItŠâæ˜ì¢Âèq¶¦Œp¥º7Kiù%SÅHä¶ÑKˆımè_B(Á´˜­ääã?›e¯½¾›F‰9¥rªP2K-&Ì@£öa²F¡Éª&m«m´YB!ÑÉ¢.˜ŠH" tÓEûEĞkì"lß2—gÀ´ÄP(ÜàŒòÓj³-}p1ù, b3ó4ÄÜ¶:MÀRÒ35MEWtp@¢í²Fùİòq»^ïz(}Ìp(›TeéŸÿŸêÌI„šL	0”‡H¸Ó˜“)Ñêv#®,6N­ì‹ÆæàÛ> ˆ6ZôG4l-1I´I8ré
3g&H÷hÆ‚Æ…,WtÇh–éäF¯tÌÌféQök¢væ¢¤úí!#^¦.dnš/?ŒºÒÇ‰iM5ZĞÚS[¬×Ò{¢äv5<L{E¡õŒ`„`¸¸»Ù†ÎË+¥Ê¤'è˜;ÍqŸé6¥a8Ö6ğI4´Ó¹ìfà&ğeÕGƒáÂU¡ğ‚ß¤Ñ×o~0 ]u_zb’ § ÑùCîjoâTP2ËZª²J¡Oğ:§àöX‘ìo»¼$ëŒæ•Ær€¥Ã·J³X¡œ®=É[ÎQ¸.\*K°SÿºåK^_N›CK‰Mš~o¶H)ı_×ŠurôU§_€c„ëCä|0Äê4†Øer4–ÚÂ'*Ùı-ƒÇ›ëˆJı\¿ÑÙr6- áæÕ`İtû:ÇÅÂÏuùûb…Gø&`OkD5ãPI‹®ò²ë"YÔ?İ±^É;c/¶’€öı`‘£±ID°ìN*¹IûoFŠ§ë|Jã4ºATÄ,ÈË)Ä2·Âz­ùh`†<\¦Á`VõqÎ€	Nç¢?6]çı%Å¦`30q6ÍúâÚñÎª[Ôª`L|g^àa	8r­&Ñ@©Ÿ=vq[ÜíÔSìoŠı“±B‘$9Â{ô&O½Ş§r¶Õ{ã-Z ÷ÉOßöíñF"^H_,Îo›¨XU'6«ã¨_U†-¹4Kı¾á(zçßKÎ93C4>°»á¢<Šı¦	:Q]ÂÑ©^†Ğw1¯{x]XkQ2@¥İ
ítm`—¥ñ¦Ü"æ-~H]¯ø#lDê*¦üŸ©>UUoù&´	÷ø”0pTî+ëÜPJn¡æ2lÿX[ôZÚœƒßŒL>Ğ|ô.ŒeÜ
â¡å´îŒ†ÄáLnÈ­hs–ß2X|.g EHgî€à·íIŞhşò4=ƒüÄÔ*`ŞÇ`åÎ	i‹’‡øaiƒ`Ÿ2«ûåe%€)ûn‰·ö‘%©1+H¢o¼²–d¢ŠšpÜ¥º$x©ı(Ou8qpt¶k..-®.†S! oŒ ?ïƒB¾…Š½•@¥Ÿ¯î_¿3%ÆÁ Ğ0ğ‘_æ	ŒšñÑO³Õ±›n¼æ˜ŠM¿¨İ~ozáÂaZ°~§L˜ªæıo‚s,/Î¬ÒY»¼ıFÜ¸äjÉŸ&$Ùåi…]ù^eÄ-=Œ‡æ–|äÎ¯ù(uşPm7~l}=!u¤’^|{·b­P	\¾FMg¡Ø_UÛîæJwÒ†1< êŞM3Ê­	ƒö†!PÎ¿ç¶©³Ux•üµ­ ÃSïKÜuÃ™Òª
•nybÜ Ø3…¤›Œñú!ì}gÛkˆÑ’ƒ8·qU	=5Ğ ×¶ghå <•Æ<Ù¿* %À5™ÈÀ-´Ó%—†şµw± ÙÙc!õ²ø S;b‡61Ğ@Õrò}Ì!ò2^5á3€<OXRR»XzæÑÜßDIuÿŠ‡{Ğ»ş 5pbtÉ§ŠBk¹U“©°„Æ€±De·•ñ$K%ĞOá½Å¼Hİ 4NÛ±±m¦X?®¨¯’[€=Š»vJ'Õ®V–k/˜ª WÃ½e™¡Y04ı£jeÇûH›|ĞW:S¬T€şŒè(#6C°Was  ê ch”r¶z˜Âå£˜×ûQ!8ÚÊ‚*‘Ï4Çædİšq!:iI›êUâÌTÁÔó¿/BÈm@’Å7b˜şŸ7W†gV+š_Úå¢KIx14ÑD¿QøZµµ\å!U¤Eµâ®vŒ†­8Tö`¨‘†ÌÁì¢"o…Jİ~¡Ôëlõ¿¿“ù5£a#ge‰«+AğL¹Y#1l{ê—Öf:±M‰í× "ŠÕÜäÆàdô7õm=@Jå¨¤C8¯‚«3›V"";ƒşÚVŞGó(ANZ;9æ–,´èÙ~—°¼Q_‚Ö0°œ$°µş²[bkLöµ¿ftüÅx©1?Ét#í»O1‰æïÅ¤N'¶_‘İø“3Æ¡tY°˜!¿äÊÜ€ª-vƒÎ©àMÏ‰¦ ¬,Ùø^©XE ‘¼D¸*ÆG¦P¨­i›p0Ø›Wk|‡NùWÚmu·D- 
oHò‘ÒÕI[¸Áì@ç$4û«©îÑnÉ7D©e/_ˆŞÚÌ ­{zŞ&AÕé;3y:”—&µMVš˜yæ¸|[<AT•,bT,ä‡H±))Ël¸UFîàÚ$¡,u0].qÇ3Ôi³exm©úIw[4¯Q5ÂÏ<?SáÎ¬oyœÈÆ˜ô†Ì:1Z„l‡XâÁr‡k*gÿ©ˆ¥è÷¹,}!Ğqúm=‹â…¿Pck¿KcŸÌ¶ùÜàXY€3´5meƒşÚV3C]Kƒò¨X¾pÑ3niÎ9óVc™'3¸æâ Ãy½Ïd…·ŞÏ1—nzˆZç· SŠX@äÎ)	“2±“3Kú€r– ã1 -ß:_õÿpĞ×êeTìç.(9 äôÉ»¸CwµÔ,~­İ8èV1˜òVR‘æ°Äd¯Ï®¿¶¸Ôy9µymk£}*Ÿğ£ÿòfórVSÀ¶¦_#òŸ§¬‰£†­)üŠµ$Š±l áM·Ù„:Áö}uËˆ})Ğ”ËGáF- Àçó#Œq¸…f¢ïb˜E«pèåÈV4hÜ¢„Ú>!áE™ÑÉxdôÙ6uÅÌ6¬W|¢§Ê	‡ä¿ôÿ»0ğ ©"Ç»¿ê9ü–‚¤òƒ¥Ç{ƒ¿u"êQaÒs*™óù~vâ:±•à°²üØÉ=Ê¦üÀŠ[D6ØÙ¥cÂP+¸·ü Yb¾…ƒÆÅÔÓªs–3‚ùeƒ9íø˜\ ÌP©Ì¹ÑÀï8DXÃÒ¡TUŸQ€ÕØj?2cî®7,»Š¶ì7zOÊ’Úvª<Lü=	bg@	`Š{zqù‹8Pò¤B£–/gln`Åú©•©øÓm@m	re]Ø›súCa¡<?·zcN‘PŒÿZ«Vy}›‰„„ÓœÜmŞÂ“åsgaÅ¥…Ì+ÖÔ-—yFù?ã
Oh<%I¾”îın#r”Çâ Şš°\g‚ïº~)hğ9’¡‰Ê8¥f¸Ø`õÏ™×09T_\Ş°ü^€óõ·2NÍJméır®©Ëé–óq_’ÿ3¹tşÅ–ôÏÿ—¹Ù]²/O“°¦$£Xó.š¨·r#—NX2ò*“>÷KF“Ó1*Ü{”2èÁê£Îl-:e¶ËùïÁÄ=²5¡GªÄ·JåØøÑ`jÂì(˜ÑÒŞÌÌ4'H‚2Oz¥”ÌŸC¿ÖOÑQ»×Ui°úÏµ`ª^€y?¸Œİµd–ğFÆ1Uîó+S
CkX
éx›º5kç\OyW)å¾ÓÇcp¾Ú©(|Şõ¾§ÁÙç7 £ïN‡@ß)Âoriÿ¥Ÿ•^r1¹ø}êÅËÒ]KLÎƒlCmÂ£Q¨‡æ¦‹ñúÀ‘Z,!š ±Ì
ŸÅ,ŸÕöÔËG—ªÓ†Cé//²ĞÉå:l&ê²lÛÑ‰kgùÅ
° C¹ù0àÊ¡Áeš„€ü=W®šÏcûL’aÇç.öH×C§‡T•“¼‹7Uˆ-Ø©ChqWP?Vb¦Ì8ùîğ{W ­CO©Ê)Î6[·{ÿ7í‡éteÁìî}ÑëŠ‹°±˜ØL5—ƒÚûJÄØ]çì~©@´Šíâ]æÃJ>³âŸ‘\2„.İd<v°PóUÛ<Á_s›š©(°3in…ŞÈÅi2¾óšOcíø°¾ñ{Fô˜‰û¦¨^Ö£LŸ?Ù4•*~2mFj”ğ<:Df¤?Bx¦ØÖÈ†*÷Ö'0<ª>ü\~=ÄT,¸ø“P\:I~%¯I"/ä4Ä\¬­ºËšÜ–ÏÊ¦µ=Ã>¥^¹âÚÓÙıªî x0dJô\›q3sŸ|õdªX?¶¼_ğÉğù…åëÇ=„’äçà%>×¤1orlB”ÈTFbjùÈ½ø6Î®=«	h„:Î÷X¾‹>½ôaBÅP’‘MeÅ/ŠäC‡Y÷[àœôvºV	ülM‘Ìİïšë¡‰ xØf[{ùİ”¥	hí¥Ç*Ù{›Í2Ñì‡¤~"¤„Û_4&.é³enİ4ÀUÄƒyñVÖhóò7 ÎU#ğ3jë mg«©4RÉ¹!ú÷º˜©›kM]€xÂÿİA0Ì‚õ„Usk ró0wŒ¿+Ëœ ºİù%†…)\x°Oï”ËÒèD«€íˆn9ÄĞÅ@÷èÄR| ?›HÓÿÇÚn©†ZèÛ±¥&”¹â”š‹Ê¶9õ`z˜\é±ó=}'AGîm²qÚNOVĞúÇıP²ï!åÉŒÕÊ*˜k»'¬[Â{3™<s†`1«¿xÏ‡h|Ã‚ş&Ä³™qô«å­TİÓZHş¶?Ş›5™È˜‘	}>„óŞ–6U^ˆÅÄL~™æov7eA«ÇÏÊ@Aå‰M…„úæÄœ²8K%TUËÂbl¹ÓØcÆ_ÿM<?›ÚÚ±;ÿ‰Ä÷“ ?²áVxSâ…ñãz‡Ş}#]’…¢Ã/H¶vÅşfK
Qí²wí¨ğ%ÊTÆ}ÈÃ¶{:ô‡I
·ö­´¼êW½õeÜû‘ù8a•ş˜;×Áx&˜Eüf¶HíÀoŠñ­Åº3˜.^—İ‘F_æ¸
y"’5ÉD1N(F\.¦»·%²ÏE• #¼æ"ìª0j´=@+IíÃbÆ£')ÒÀt,ãş°Ê×°TºOVƒ¦û4ç|óîœmüÉCU±¢lÉ=ú¥—K‘‰cÒ‚½_‰Í¡ŠN¸GILıéß|8'5H7BÏˆwm*úG¸Ë‰Ì·X7îmZq‰¹æE(†Uç2áà*˜Psy]&n8yúZ‡¸/8J>åµDBB}8h¹È
ü&j&Cf™–8Å¾ù=m#T…æ… –†A*+`âˆû°Ö£Ñ1t¶"µI«ÁÕ)¡)½èºAtÌ™$ôÂ«fñhWîï˜ö/B¦­XäfĞÃN¤eúQ_8­Yü	ò FÓ€ÕeXƒ3>?ÚÊğdËì?”uÚ.Ê3ÖĞSõ#\rä&¶X°Œ}ÇÍ/CJYW]•O²xÕ  :R¾¦3ÇƒÆ7×R˜‘iŒ¾D´ĞosEHUc&§é›ƒhÀ¸GùMr¯9q…½õ`3,1.I)jH;(ÚèÓIO±Ò†6`²ùjş?§hLRˆípˆ–”´TIP+«ø6"É>£gaqK3“˜‰`çø;jÆm‘Ue™{5…™¢[µLé#ºîê¦ƒQÖê›t”tÌD³Ì½Î|œ²üÂ[Ö"‡Eüï°×ÑŠƒ®JçÏPËmØû†ã×œÜ¯‘bÂ‹ÉÀ‡Vò`îÃ´T¿>oN<U$j~­w•×}¼†¼yY\Âõ¼£.óŠ"Êj‚u:#8oãÿ•Û&ï÷a3!ª?ö›<ô(Û’[9m›cÄr£™’¨ñÔPÂC¨dş?~¿âZ¹øGŞÛÑDõ–/T[ü¨Áå°Å‘A#å=¶é«İÈàVË¢-u[ë¤(†’(­ªö»¯]–pœ_™°b‚æU]áFêõl/K‰Àåì‡/ò„cËÏ†,:ö*Sg+2C&\B¶RŸÄR	ĞK›lût¿¤­cŞÖû$(ìun‹ÖLÉëNÆ( eù³î[—ĞY4½‘™bÖÔú„#ºÿ~ ËeÒ0ŠÒ7Ñ„²KMO %/´V‡œò¨(QOÆˆQÔ¬<J,ÕÆú{gc²˜×Hã^ê{ˆEìàè0 É>p‰NiUæ9úà»¦/)Ó‡ÜJîuÔVÀ×MËƒÊi51©CpDãåÑÕÈ^t§òpÿà¿$ìÕT¬&!ªÊ;e²+ôœrOxØ
væ~/l£ÄK(§sÄ­á8äêX;İæE|îç3Æi§<OîÁ´¬%lPÕø@{m–zB‰Î©Â+éÔèÆ£ÙgJfƒ«°^!ı"„p]„¦¯¢¦@DMìš¯îJÍÓ{'{q%¸úá9D~D75Ba­¥›TOİ“@~÷KËŞi;<(ao2‹D½CNÖÁŞ¥¾v XR3Â1vŸõ\}K.|ÊÜ²ÇºÁ0dÜ)t$x”~&}î…™‡S‰‘:‹Ùş¼8Å–üK"ú9!ch„µ sÁ»ê=Ós÷:ï[:$&ÕWC¨"ÑÔï›ä²ü)<C!Z€ï×tÜ^p­ôê®BDğ_}ö
:Şe«í±$³ğ¦ƒè«uZ€dÚ,ÏÒyWÛ`óRG¼øùZû´Zi}ê=Ù…q]¹&Ÿ ª~}Æ VNÚ-÷ş‘Í$¥ä  }ö¹±%i¤pÈYã€ğ_®¦ÚÇwÈMzÚmEÂxš ”ÛÄUr~~ı… U¼YÄĞ]_`ô2¸p$ã½Ó¹…®èXØ,À©–Ç‹â4Ê}p_âğ’gˆÏ·÷¾/¸ıÙ=Şü–õYº ¹!Ø—æiß¦Ï
4q¯†NaH*´Éz)ôÃšæ_q,` ØN)—'œdÂD®À <¤Y»Rí¾måI$À(ÒŞÌ²?÷ß× õ
Gk ³+ÔôzWøoV(bO“>–È$°¡’uÔB·ÎÓÊ	·5)4ÍI_cHsJëMwÅÛR£Óğ èö”»c«Lt*—“ª›põ &bŠQ«Šd¡¢–-D7k¿Ï_E'yfAÀÏñrâeK£²]ÿš£õ@dğ¼êï!‚Çº.ªĞ¦°¢É6V:aÈdı¿•fãÕ[iÆÛwÍgbia¼TtbøFSåRâaĞã¿59×ˆÆ¼\iy€ZBÈÉ`ûĞLĞbÚm«âG]µ¢ô©@é1‹F§t›ÓúFÌt—'àÅ€œût}ÖOW[d:_ğ„¦¡·.Ğ5“w]¶“™	?§ş­ºnşq½õqdâš¡m¸-¾M± ³Ã´µÙPUµXEGÊºÜn©9:¦#L2UÛ"†øäĞ%ì9ƒmŠmÍ'Í¾Àc ®Z˜)¥B°âÇğ|ğµ)JËÿùkF ª)ªùŞ˜Dnkcˆ 1ş‰ …~˜Ü5m	?i¡+™èj–‚ a‹ù–ô>TÃ1ÂÌÉJÀªã†{˜Ø-Ü»RÁË~ßUL¤ÆV58/á)x^Æ>Ï`Ã„nÖ†²‘rÕSoBâ÷‚ÙPtâ7¸î]éïRĞB‡7`NñFró_¿KÍ^ôéº×®½6êœ˜±¬3t\6ÔÄºvèó¯©²àùİœkñ)•ŠœãHt…Ä‘Ûîl&¿Të‡Iøá/÷ç\­÷Q á­ìr’õ5†(ï¶âÅaYÆ¤N<¶Vf4d®ü4Ï2—
_«(‡ à¨”:dèÜLg>ÛÖö˜hŒ2†¶äÀß™™M5–Æè•<’¨ÏSÌÍâN Ï9Å)L„s[=­¼:¤”»~Õ›"@tNo‰_\Š| j°GäoòXä}<ïéøÃ„Z–ĞÖ…HgHRF‡E¬©î3K[ª°Ô†(ßşëh»“™>kĞ‘*ˆoì	‚Üë°‰ÄÄyd;ªÈã!¸†r†øND–
Ú”Vî³`Æ»¹¬—×ı æƒ¶25?2ˆ@ÖùZfe#u©=NæsÍqNO-lÚ…‘s´ÎÊŒaB‹GõÀ›¶×àKˆ„è¶Ğ?%/Ê†@{g÷ï<z‚O&ÊÑŸË[V…ŸíRaü`¡‰åbÉíò–š\Iïê¹«c×	Îúş¾½ÚÕwñ"g¿“÷ØiØúÎô„ˆ
Ù¯ÿ#x–	z²Ú+Ñ¨PfêHá°–²µ©]h£:SÌx!²3Üù :"Œ
Ö-ˆ°Ã“ş|…g£S z @Ú”nºø<ù>z¿j×¥€UæycIÒ¸ h”Ÿ9ª5Ø»’ÔW÷§R:'[>a–&¯›àC|…VÏpÎÇÖ³£ÏÃ§VåÿU©İ~CöqÖÀ¸u¨Óc#(¯İ!J¾ï­Ì–ÓUĞN´<ÿ£›…Wu#›š"â.Gèâ°^-
 •Ğ§ëÄÅåIæëÄO©ÎËïpµ},MÛL=oŠ=@¯ğÑÜ_D{Ô7ŠöF;¸Lçğ’6Àã@û –É^äÒSI‚ñå+ß5ngÚÎ^€Éì@4ƒ#w6ÿˆÕ»ĞˆšD±³?âs“'ƒùÆc_dEîhˆí¨»¢ó)|’†'è´úšdö´‹-#eP÷Dy—t^qàâŞPhÌÂpğ•İ(’©ş’ª›Ä¡NTÀ›CÛ¨Nu€óı+üpNkˆ¤ùpÅÕSèøÓ|½÷=K§SçòÂUD}û4púîSw/¼Ì‡l&õ
n¦ |ACÙåç	ÅO’†ve Í%zŠ÷¯ô*Yc3"¬`“.½¢*¸x²&X±KŠë 1@£	áîïÜLŒ‹ÅğËeı$!
$¬¹`‹©ç	ÜİÃ^àÈ€ÏØ‰è’ùù AKÜÑÀ2…XA–ADñ)(Â´Çª‹P²Mó_6À­şW”ªÚ/Ó"+W6PıÍ£2ğ#ü|E½ˆªg½’úcÔ_$ºU#~gTû–’ÏY~ö1†Bçu7µàRI&dŸt*xpœìR|í“ğs4MÁãuşú\¤›â]çUpFpè†o3ığ÷oú‘9ÈM»/1?³ËºÎ ¤¤äÒF¾ÈPà–i®‰·.-ËÏ}w\#\d³LÉ€Ø¼”û­Â™q…õéñíO?6“Ï'<xXJüà¸“~0" Ùo)4ğ‰¶_\Ø³'6Å@9VÕ[ìÌv·8‹n.Sİ92ùâfødbxö¼Ái‰ú* HÃ{‹ÚOÚwœƒY 	Ğ9² 5_“}2N’7‘áTq®´Ü µÉ®ój¾] “a`râÎ2y!IÏU‚MùoE% öó“[hOŒ¸)ØÜ±Ó÷h;*ªŞå¯ÚìÍUßKÕspOTó;àj‰üncÓŠE[×qc—0ÛpÚá\KiU–£«pşW	Û·àT=›ÿB Üg˜ú4V†…·3Ëˆº’oqµ‚wKfê@”³ŸbCFÕTˆaÄXeNx}Sh"ôâèæÀ}ÃD–2…IAˆx.°}'µhÇàq9|Æl_<â¦”;QØ8ïÿÒú.Œ'şf†¾Äæ½î™ Ò_çA?¿?B[Ös¾(¬b€úÚd¾œM[kß0TëuãnĞ-ëšÁßZÓ­ó_ˆ¿FÑr‡SZYèã#¹+äç«‰~Ğ
õY«æwéÓb!hFe¯Pµ$¦êˆĞ.«M0j Ú.Áş}è§5«Èˆ8å§j·(ªÑü.Ó{T°Ô,sAÍlcá@Â Ô.Å7Èm:wF
Çv«ÄK8A«İ¬nM§y`ËõoU^ªbîÃuÅQ*w]n8è®vÉ]/dÔ²#N±,ğ	$Ô¹´h¥·íÆ*'–R ,-å²x’7í PMG"diµ>Ô*¼µ2Œño2&›;ÍÂV¹IÔ*ê f7|Œ)’ ÇŒ¦^EKDG‚ûu¶ñ	hó1‡CÑ¦Åƒÿçâ|5M¼©¢Gxé;–¾âQ¼ŞÏ¸Q¿+éjB8}ëw“cxw–ñå(İ?©u>’ó«Ÿ(´WËşt¿÷‡WŞ ë‡t~ö>"HsH
ÔñGîì+j7aA…€î!]) ;WĞSÇ¥-4àl,Ãf\ÂšN€1æRÏ¶·[¦”iê( a©í¹ï©-÷0VÚWZí9'4.Ä
ı"?dş!Ò5quòÉ»d®!]u¼€¡pÉ-Ãúh½ìvfcÉN„Q‘	ÄZêœ²>A…ûÔè²·$·dÑöˆaHÂ±)ÁşS&¤8Ú¼‹îİ-Sä}˜=Bç ä4ÁòáH °äš·hîb±œ»@h(Uö÷ı=œ–g_œµ<é“°b?W¡%–¿d´dlÊ´ô=º‰ö2cd¿ËdâŠ„ëX±ÄŠ Ì¾Æ¬©3”XµLô©uÙjg21t³>ItvÔ«D26)Ã^`D´\íòÄœß•ÓZúø=‘Å UÚ¿’gF8æ‰cÎ¹ğpcrIİíõÔ†7Ÿç×Ù³‹mÅÂš¢O’ƒcş<µûÈ3 ÎàØBÅ2‘-Øn?Å+†o]ËĞ×”FsÙDAÛøÇgØJJ¢0šÖ¯ xéù™­B¤Î¥'p]ãeoÃÍ)k’ÁÚÔQq²5»–w£¥›²íÚ°iÌÍó½—×¡« µ?Uˆ€P_®ß¿»!œ—öì>Ä™ëÊW`{^¶póşø~–s]ï´µ®•r¿Xü MÉ>ëu–ÊÀş¦táˆÿ®]¼¯h#ÎomF¥éY¯ğpH6û|R^¢»äÀ~ùA7@Âª@a^2ÿ>a°ìT1Vs+\:³fêÉ]5nFØŸ‡Õœ?²&©¯\,çqÏ'_ê!‡n¨‹NaÕÔæ¼/ºYF¿+ù—€áBÚÓ{ÅP¾ÙE”0ï¬”;¼”¨)ÈX¨ë1ƒ‡4mË=ôC¼ÒÌ_õrÀ0ü,'t&9»÷£…ı©–—IRuBôy¾82ÒBC<d¥DAL, •„2›Û¦Hp¯ìwzò³BX½aúÂ$Í]4Æå%ƒ†vÀ¦Qn5‚"ä²;<çLL,9Ïş’YÙIfITT•À"3BoÆséeHS³	Ùé·J.8ŠÇÒúõ×3ü?T´¾µ-¨W‹ †DêÊë¥*Ã½Y2§ çÇ¶¦Fxo"u©Ä¹zM`^&ã&%G'd5ò@“ÉçÉC`¤ÿK†­;º)O?V†MıdÌ|jæ8=>ÏßÊ·‚·	=G.¢±X ‚Ø;ô…µÒ·ù~ËJ±{bé¨ÕóIBr¾ÍÂÜ1²< ÖÉK˜İ‹k§‚å…ˆ·Pù/X~´_3P´;8˜cŞG™å¾di|\Ò+~d¦ô7ëãLJAø¼îğ×•›FÄ@´ÿ?ê!±÷u2	¾hÁTêôĞ`ú¹åÔq1Äu{¡
Š™Í[z‰eL¥‹6ª"£'N0D/.ÙÏp?ÄÔ¸¥nm©LŸu‹V–ĞÎA;âYMÛ÷‡jÀÂ×0%RHÙ²êE… 9ÑKŠİ:6Tf/CV ‰=/úÊræ™ 4-ÊY®€é©öYÅi½	¼Êb`‰2‚Ò²†ÿö¢¶«¹A6œ‚Èöb ÿa8PS7£°|5Ÿ.ñ…›ƒí˜låj—\l(' ‘Ê¥7ÌPö§j‰2/Yhªº%ón‡<ç^B•pîÃôqiõ© ½Mp×ïsŸsUÎğş#ìxC»z×ÿMıÏ“k5Îh°Üè®ióiã&¨¦tí¸Ún1;eAßŸÏXÉa~(1¯eRİZÿ†$#j\)Fr)Ä¥“‚mkæ²ñp´¾ƒƒånoÂzP#ÓÊGÙ||*;Xådæ2å\Ü6dóy
Ö—›6U¤¿×VÔ÷,/sß8y+®4Jv3¾¤AZÓx8©fU—¨5ÁßbVGJ©®ˆfqîâóÑWùÑ1Òˆ9Óe°€¬É-ØÖ6ûíÿ%´ñĞ^£L¸*¾òÃİ`ıa!Õ0N¡9 ¹^rÔ”5]•LÃ¤³°e+¤¿9¾šY0Ü‹1¾ÒME+ÁÑŒW€`¹ZÕÖè.ÚÎ6"&ûá)ñ]Ë1.hl’¾ß‰tMC_màEÙÜŞ—ZÏ~ˆhÌ"”Nû¯?Í¾¦«EˆÇEcAÛ>û×Äğxı#¼Å8+Fr±áqüàşÉ.‰İål‘®ñ•ëªœÔ	…t­Ì—“R2ã8ÙÖ%}Kc­uÒb·"ä¥ƒöÍ„ß¯±ê 5g}ã99ÈnÒäÒû&f z£ÖÑ®i“pÙ”üñ~·CöIùØşeŞ²\üØFŠåøğ-+”¡}LŞ&éê%ö4Œ–½ç‘¢–Y—Ãé‚á:ğúîå-¹?´¯ eñtËeÒÁ¿Xé£Èè=ó§9¿´HjoÒŒo¦ü€âKyêİöì±Cãû<nÜÒ*b•é©ìT¤/Hô4™+Æ1`Ó·yÇ”şQ*œ»T`«À¾GïïÈËû¢Æ6—x-•èv7"™‹ÑhO“|Ûu{…FØè%+,”´õ‡İ:¨M»ú«éh3›»!BÁ­ }ÑL"e˜=iÅìĞƒt4ñ1%…÷8rAê ‘÷Z¢2Lù?¬à*˜G@ N¹–·)íÄ¡—!H1×^Pù˜ÓT^r/áâˆŸ¿§¦˜¦b©0.Ÿ»µ¬F!SÜÇË#è0]yLSQšfº«¯¦\Q£µ*3h)”†¢3èD@e'ìfdU×~]fc—;§¿ò§fÈƒûBÕ/rü)ÊJßâL×U`ƒê‡®¹ÅÙeÎ¬·¥ì"#q*ƒ ê/a%ãde©³ËÙVÊÔ)Q#R›æ|ÒJqWmÊ§+ovróØWv\6Hg×x–UÜõÔX8ó‰¦ÔDŸ²¯XÂßßhN®*!m²ø	—ÄåİŸO\«XÁÈÔ+K«
g	Tƒ¥V­€©s@³é™'dÁÅÑ¼s·¢tJş8ÃÖ"XéËÛ»»SœXDæbs U<jwA\B0ÖkÄ9g'ŠqF­sz¤dÁóÈ#'|†±¸hOS>ÿY¥xSè*Úº¼‡™ëøVg>eÂ#¬6
Ô)GÂnj¦µ®ßLôöpLDœû5×¼)õËğª6À^ß]SY»††&î2\?»ûØiîre«ZºĞ6UéğaÌ¢ôˆ¨‘£e(©0B–'-’åFõ8Ì¢‰\l¥`R³»(±¿À2Îôôæ*(ñLu[ŸÌ¿­—eÆr!N§Ò†•({úœ©Ù]ˆ‰Ä<‹AòÍ¸g`Ù+v¯J=Ğ:=©¾#Ãˆ)ÖxKÓÿ¯C¢Ò˜ğò ¯sNúÖÖmptæ€á%z×8*rVĞÔC3Oç¢ã¢ö6—ÈJÿŸçƒÏ¼§‡Ô’ë•ÃmšşRùY›\™N?·…v¯FİdG¤ÿ!ü½ÃÑ£çT»%ƒ¶:Û–Œë5!<SdV	ğá×:+Ä)Ù÷}Â€ÓtmÂ²ê0W*Y¸ã!#«=C–á¢>Å<`¾F
ÌW|d¤èV½ŒËuYú@š¬T’8ïQA¡1Ÿ†öbÊ—XV)bF|ÑyÚÜöäğÉÜÃÿ#tu.2âÈó½VTQù"ŠªÁĞ6^=²hÙ‘”:ª?ĞÉ´ĞµQ;-ƒñò¶jâ¡ú?ÕôÑD-À   "=£Òo‹ ˆÚæËëùì·Ê8Sü ë›µÂ=6sÎ=f…õÏÄæ€t0]Âyšˆµ—pQÏYÁ÷éğOY&Ù@cÒo›¦43‡½ŒÉ‰Hl"!pÂÀß×eÛ¯$E òsb‘Ç1¯p¿ƒE+ş‘\Ç”y€˜üÎ°ƒk¿^§¸üöŠ’":5Ë„f«i&ã§XÛh(-8 ”aÖæ½q†($¾ñO‡À‘Ï+–	…ÍÈb@Îs”á¢¦^€—İˆJ_@¼ëìÔå¨ŞÎ#‰2±F^Ğ‚.İöIe×C`‰ó=d”Ôïa¶ñ43ÌÅÃ#( šë–6kRí¢$Væ@m|ŞÏyç£õz¾šaä+ã#p”ÇÿRHq+Xšˆut2‰ˆ§­èí$iº*p`tR{2/Êä?H²€~¸eºnPD?¹&üú"ìYšŸ;ÍdN(˜7Jìıì•[NG¬Œ4â›-Œı÷ˆ¥ˆ±/şÉ³Æ¦7c¶nÇÊUÛ'È#a]&wéİfİ…È?İY.@¡ú=¬ı7À!%îğğÚ)Ô‚^à½Ù÷øá ùW¼ğ§ÑÎtâ#sœÊ¦{TO( Æe2ó5…Q“%5TW·ßo—™×•ZÔÁmZô/f–Ü T±·ãÕs7šL¿%£Ì³LLÁ\–H¡©"âkŞL¶Bã\‘ ­l#“ –F³ÛğóĞÀ\ÜªZ MÑƒ›sŠ:(X™ï¨¸Và¨púÃqäVï¼s¡)ËjkE#(¡K#	>uòÂe\©oÍße˜NşŒw¿Ê´÷„ßsÛı ¸‹‡¥ÆĞ˜ş3=K³;%r*~kËé1ö4Ÿf1	#yaeÒÖL(cwXT´ôéºíŠ°ïT)ÇøKPSÂRéàøß3ÿ{)'×^‚.Ìèœİ).òóÅ+£Ş}IŸºÔó±æÛ#Áp?Tí4Ûp±ÏÎ©ú°µ<…Ød ¢3ÇLW×¤½‘ ë-xK*Î‰én@€úZQ ¸iSìE¹Ä}/gÒöoô/ÍM/Şuë*7ôÚp”Xîé‹è‹ØZ'5êÉeÒ^İ´4&Í{öÑéÉƒo$EŸsh\¢Ÿ½ÛwÂ’Ê¹¿7yú5q¾K¶éBá!³F®ÆŸº³„}kæ(»Y‡¼vä{ù_ŠVâ›”ŠYÕc
ß¹«¥»ZngM„l·Òö™ßJWë|'½U™sËöíÎyµ-ˆâ!oÁÄS;pÏ
}•´ßGúÛ«ª÷¶R¯Ê‡šsŠ¯Ÿ€‘¢Ÿ«ã”öMgğßFĞ‚øBÀµâŒ0ª‚Ô¶×¦é;7¡õM.z~[/Ô®	„‘Ş. @ßı™t~õ¹MxëqãR¢é¿~ySPøÃ_«³Ë’‡ı^PåxôıTá³ìğ;Y‡‹	UI@°’-ÚF×`pşé]8î”¢£ÑAÈü2elÑWW!Y†gd¶tn©º¯›é›i&işÂÆPìÇÃ¾ÒSŸ‰bñŞÜ7=OÈ("ãH4@ÀçÅÅèÛ±»jÁéA‰ÖïeÜ«ÍÒ‘÷dÎÛê=
À~ŞÆıĞrê­`Ad=³sÇ /.2¥Ío)¾%*R}Mùì?ÅRdÌ¬7tûrÈ„GnYêÇvMzø‹‹À»oé6é›1»ƒ&Ş4û56°ûˆJ¥´i8ãBrè’”ÚSò9/·º±ÉiÈfn€ñ]ëV}óqâ„
ğHÁ™ €$ÄoA(f eõêô@Q²)»G?ôÂüäwHÕŞ_‰š.éW'gİu@Ëeöú3FÁë€4ã”nÏ„ûüUÇI¿”¤n’½UœNË!FcäiP­¡B$şÆeTM{d2bgíyÑúwØö 6Î˜J9x¨¸ÊküAjÇ)¡uŒK’¦
IUtˆiºİJF(£VoŒ»©ÚyB«”o½)Á¥™ |ßğQ8'u÷˜İ4ƒ­¦ÉÈ4mĞLl®¥,t8¢ø«ß¸ìV´ç#Îñ2uA…«Çvø^ñI6NynÈ¯P×^D®×3ã÷[	ŠŞOçz8ÒB”¶¯¸{W²-tC>,Ê/v\~dÚÃßéşÂ\…|AŠë¤ŒĞìcK3{=¡Ê$Ak?‰w	B…©ºï+h¶£>nsp4·ÂG’9ß­…Œ8å-½Q¼ ‘Ê‰@?zÉ&Q\¼=›š9â|¥ÀMÆéø9·B<~fÒÏK2Aı¨3PSÍ88ÔùE’i•¯®‹²NñX"+½ı`S®õ:íKö ıjì×Ò-=±Üw‹=È+£_°•5¾D/ıô$« “2£jO…öA«HĞ‘GDµå‹fıVG¼xp]#0úåd¡PÄOÔ!ßê8phÚºı‰+ŠéxµØ'Í>Eº&O¹+9ï†©>Ş$ˆÌÀVÕèò›?y¯`Èûá¬m •Áì¾Ş¥n†™£îÖÃÚÃ#´UMƒngya0&«›¶¦i«i£Ú’wø±öuø­Ô#-ıÔQf²)s°Ë4
p,r¯d¥áÖ=(½…¼›©ÉLPL2eİû·i²Å™»õ¯@”l¬üã	©™
§Á0ĞjG@Æ˜İ ¡#`²Í—ÂË\	Ÿ#¬91_{0!Ìº6İÉÌ¢h[ĞÖ*¾ş„oè¨Ùì¥…ÁKß—(»Â¸õ$rè €yÓ§"©ÙQ‡ÙRË)°'¢B¯kƒÅ“êÍ÷R{»pI^]&´³Ä!æ5?fì*›W'”FàoÇ-ö1ùá@­{E%]\ûÊÚvºzo>k~YŸšUÿØ½@fãOâ°t?d™+ÿy;§íß–`ØyW…8Ì{ï6nùQ	ãL»ÁÍ±Ã]¦"PÉêÇÇâñtŒHÿÅ™ :”  ‡ÍãqX$aQÙ:bœê,x50Gß/¼hº"ĞÅÀ†—f³s½öús@0›ªìÉÑAöƒaºH'ßNâ^&i@"šËØŞ¢àWvU¤²¤¶QÔf“àuâI‹¤rY}´oRÖJD.Möuİ¹®[î7mmŸŒÙh¾0#>‘ÊZAŸò\´4µ8ñ›Æ¾½4xc‚Şº9ø‡v6õdí0ØWĞ¨Ù¿©IE˜ŠUR3†+Æ¨Ìæ­ÙÀXèÌjH‘n¨>}Ô(vpór‹åË4ş^zïkvDô‚Ì£™­}æş+„¼ØÌûZàQ.Ó–BZÅ"´ƒíÓ”É³QÁC8õgò–L|–İ4°N½ÿ[CÍüGÖq»­HR Áºëğ(GöÂolÌUÁrJˆj.p­M`‹¯Tì¿W³EË8Z‚o°y9¢`§Œe5„k£òlÃ´b±ñ|”†X+ÿŠr‰ö=rŸ)ñøFÎHx‰Z®ôÎÆåkW,ìó&Ìÿ†'Ÿıò?A½yäÒuc0É=JıF
D?Ê³Ùb2Q9ÈŠ±¾w%	ª2ÃUˆ_·/fÛ_fÀ5»%/•õí­¤rE.F‚À(xj­¿‚ù¢üOMo±âŞÈ¡Şı5›Ì ÌvÒ¤J¯ÂîSG—ÇÜ¯ïÃ#ÛdË†ã)­kÛUà$„ÎªØù@ã4ÏÆM´djú¢y:0o~;@Âmü r5A ªoıoĞM¤¤v¸$Î@—É®{¨Õ;ÓûRé6ÄÕÏ)nZÚr»Nsóñ•›vúÌEH&¹Á““EØ@fJ²\ÊØÎŸÛçt¹ØBŸD°d–=·“rîœÔUŒçñÃìëlé2%½—ôü:êÁ}£oà/–^ğÈéÿáØÿR8xÛçÄ1Ğü;Ş> ñvÆl“Ÿ¤çDÉ×]èv²¾İ4 T·ûæ(óÖóşéõIÌT>«Ã9èæôôƒšÚ¯^uHGú[StÆJl9ùAÊá›,´³÷™§&$@ïëœ*3ÇÿkĞÊ¨bZ }Úp7ù©b5·ŞFhñ´¶´!¸Y“ŒMBÔ˜€«?p[šÈVs@2ól>9T*$ï¾WXØNYlîÒÁ—¸oü*Èo&¥zÄÕÂÎo’ø)°Kğ’Äp ˆ›ºò§àJîSÁwé×ƒgï©‚Ød+bAJ–RR¹ĞÍ%ØìHŞïÈV6oH;ñÒˆÜS/iOaÉ:d”%ËmûT·i"a^®¥&”pE”t"¤0¡Ü§:°rÊ‹¨óu;ŒíóîYeMmÇµ˜O9_ÓüacúÔ…ÀÎ÷)9VU¨6tÖ?ªCôuùL]Ç›vuäˆ¬Şâ¨ótçïB~.5µYñI
=­<İ6˜@ÊVbãõgÑÜXÌ´Ï«9(±ğàşjë‡Nš[ÂŒ–İşC[3‚†1—OÜñÃ¯êÌC–=l
i|O¼pšı*{wšMTÖç¨rx“‚ˆmN7TŠ±á~-Ş µºv¹Š–îs2iÊ`3Ä+ïê¸sCCŠÑ™fX÷¤^@u[ú9œL¦HRT¼+ …ì{xvÂa¿æœšÄ}™R|`Dõu&n]äQßT¾a}*ÂìW.·°P“
Òò Ê:µoî¾•¿|üG“ÂŞÎ{Œ(a•µR¥#¯DÕmfùtî0FçU­D =Ï~3òzr” ƒü1Y€>Óóß_tÅMüÁşP›©†Õ°½á½¿ÍCî]åãü}DªÅè%`tc¤lœ2¤-Şî8~q$üİºjòå×ss<å†×÷9ßEìPµYCƒÿÄ[½Ì»×ğ]05Ö"¥–R³M¥"ñi“}B-œTŸn6ZY½å±º%Lï“qsÌÜ5ã^Õ?§ÙïRd-Ñ2¾ÜüÔ—ÆÛÂEújÉ(®œ¶M¿hR§¹†®;¼­Iå“l­„ıYUv<×ğÔàçßúRDÍ¿uØ¹ ƒWÑé‡¨½fÏØ7Ê¿QAG§­Iº¯gˆDµ——Gu|¨‚pLÓİ7¬Â¢8¥ØU™[’û©rcÓ6¤â~cÆÖ„ª°à„Kó«ŸQ0JÓ©
.lgrº.ş/K³˜Á—š„ƒ¥›Rë/x®VqÑµ—ì8\Q`pŒŠ;Éº“¨9Â óÎë5¸6»ÈÌ£ß†U ¾;`ê‹pwøêÜ¬8!Ka\kíãd	VÀ]‹…ëZõ™^vh¿ñ”ºÀ Ê	˜Ï™ÈÄlÀ©yÇ7e=‰ë²J”R›pÃh®'ÔãÔŞLYí‘è%Ë¡4‡Eí‰M>ËmgD«’ÙŞÓ•Ìi"Ñøò3»S rÊ(Uß¢Y‡øëI2Ô–©|¾)üF4Ü)oIpŒGe"Ü;'ÏÓr)¥
:UU¢5Û8Ï¿Û£ßèÜn¹× ¢ 4&gáßŞÅ	1BfEy÷Ù†5LRñƒr¹+˜Ş’,$„¸CCzN$úı`~ºj2œÎÁ6|Äæ}"	„ø'µ"ºø,²mpjJ’xän,£5îv&‰6!)Ï^üımôÊ"û…Z¥M-¶ëÆÌâ"ı k/®FB¶A¿|ªL9¯'ÄA>UÄŒ^ĞU^óLÊ®‰»~çš¬‘!²îÚÌsE·3Å6Dèm‘ò­j&-à$ôÛ}ñÍm¸=
6CAÙê2ö]»;r;Ë;9«]6ÃÁ^ wRfS©Ò<¬&SÖ[¢úÈ¾Ÿã¢S7’'hÙİFÃ¼eôş5bü%ş´^ë'Á}î{rŒ—ÿdRÔ s—±—æöÀPjÒàP.”8+Ş¦i•†Dò<­ˆ—N_Â[JSû¹ÕÃ’|Y‰0(n$üÔDcù°ì%Úı!©†®†359%ßğNºõ>e¾áXûÄd„b¾3êBÁâäVG,u9‹ËÏ'”à ¬@²-i	+dDúØšÅ‘¸¹;²` `i4&¦X?óH]f«Öƒ{ O®kê3ú©µ©qÏ ,ı¬ÍÚpdôú¯6©D–Ì®éÙ2°
½ı>fî¨çŠ/5%°s¿øà•¹Á‡ú€\Zìİ÷ºp"!€¾Æ`Å€tˆôíüøh×ü
š7—‡íı)gğ1…»}­sOµqïÜ‘<ø’ÄC¹Ìq}$7ÊÀ®pü„²UÎá¨¥‘g×ÑºÄˆ¢ÂÚ±éáËÈ£½ÈÙ2j¼İ»„òÖ8£¸ûV7‚zxJ>ñ	óKëë‡¦Šï¿~Ê×üŞËjÌè)\´Ò·yïè•f)X»Yª2ı1Ê~ µ®©)cš8îİvRX\€LÀĞlP3Á"+qËÌ8õä–YéLÉF:¦‘¹K?Oigİ_¬?‡^e4pJx~e`Ú©E“%¸¢ÜIØÔH+Ö’sÖOçf‰×H0¾(3s"Üƒ
Ex_5¶r°ÍWÊ‘›5(b¸ŸR"ùØ«Á€ÛT-Ùssn¾ËÁ1‰Mçã@àWÒöRûÁôg´ä$©kÛš}Ø¯H†ç³z×¸÷È_VíŒWËµK¢dUT÷ÓƒÉ%³"“ş¸;8¢‡Ìğë†…iİ”#Jñ Ó%pU=7/…"EcqÏ¨6#ËŞq[|ûH6­")´Ìò[A/ÒëÄXİF.Ä¨CmÑ™ÀW[~«Êê¿j"{Ñ×ıËÖ~eN:×âN‰<DGÀı‡£üÃk°V¬ÎË½
±¾Å³ßüŠ4õ¸«¼;<ìd'”“‘ŠÄê…¼{Ôè¹šävß¹R —•Íj÷!íçgå]zæõt»´Á=	.:¦'}ªjĞÓ‚Š§À?-3Ä®¬‘A&*TÕ/•»ï:¬8¥‘{BT2ş%á*«å•l¹¤÷úøÊ¬¾Ù°TW¾^Kzyà.»-6°»w{™VÄ•nÕ“y'¥Àè˜OÏ/t¶”»
Õ¯ ±¼µ\”sİŒ¡ †›‡i@1æúÃ üiqã¤*XZl¡£lé‰&Ù%ìÈzŠmO1Ÿ:^\´‘¼^İ­Ø”|éÔÈe©ìY ì‘1ka¥1ßSÒe»ÊCúLÀh4 İÅğHĞ$‚ÅÏ­Èçwía§¯nôíÚË3­Üe}–¼D3T¬:@¶÷sz»ı#ÁÎûÇ.õHSé“;:ÎÒÿ/a·İïI¹ ¯{lî…õ‚Éüü60GC8ø 5ËF G F£}f>mü¬¦ó+ß¨á,½æXã^hœAi@9Å®Ä-µ`SÌ¿g²œã¨Å}ûa;np•@FØÈ°’Ş¢íôH“¸
kiä…gËûdß–tÛ@kÈR4wú#ÓÃnSOüW6ax‰\D`ù|,ßÙ«f	)ä½	~_ƒãİ-£?v½‚÷M#=¸M]ìç‚¦§Úªè«ßR¹qĞëQ9›·úÅŸÓJòùÎsòƒ¨Ä½ÓI–LŠ‚¿mt˜Jºœ±xNÁÛ><ò…]gAb8îbo …ÇİÄ‘;!”9n.ùÄê{keˆ¬6æv@8eâ
ETpÿEä²SqMœ”=ü„µé„÷ĞCaàd²Ç\¯°”’—r%aŒE¬Éw[{jÑ+]eMaŠô,VÇÛ¥O`›Ş@<	GÈø`ßŠ|]H«7oŒ7Ò(FŞzÁ=­p/^Ô¾p60¹ñÅÍå5ìû	zı"j¬ZÕjV¥k%rù![¬ ã_%··0q,íˆ¶‡=¾íñpB‚Ñå$÷™Gòô5jV×zøÔsà¯«”çù{'6/ÑÕQ£†Ç»c;†š!È(ºàöWj^–árCÜD3µ!ª@ª2	Á_œ†ºšfeQccˆ …2¹[°¢ÂLJMBLwÚÅ6{à ´$j—ÓÕéßvÇ[ˆYöL˜¶¢a,Êú-1á‹wC¶ƒ€›L\Éa­yíSh~|[,²ùC…›Í0£lÉ^ğxbŞğõ˜uÕİ§tİ¼  E,_­¼à› ë·€ÀÕ&±Ägû    YZ