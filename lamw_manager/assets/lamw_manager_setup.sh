#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="424519731"
MD5="8668e8933f78f07909bc55e5efc12f9b"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21200"
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
	echo Date of packaging: Thu May  6 22:15:55 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿR] ¼}•À1Dd]‡Á›PætİDñl;§ÖÊi7H¸$w@l¯)¦1øHıB¿<:ä?ñ´Ö†CŸÑ`¦LW¹,İ•–Õ.…ÄtMåMŸ¡³ÛµàÓæÚ?ü¿3ö¿¸ÌïÀHjZAéC/J1e&`ŸOCˆ #,uÙe;ZÃâ%”ü$İ¿Šâî¦9â8w`â„Õ÷ º,Á‹Ø£Ù÷b{¡XŒn5=İ¹X·=ú@-*_‰Ö‹¤'´heÁn†DmEJÿ—ÄœÊ
'‰¾oŸ²„ş—Ãu‘r 0W>¥³Ø!íª¸&“Aû1Ùãdœsx-ıYk1åN›ˆ¿–Y BŞ´ÄÊ0ZY şŠAª0Ñ¨$Ğ‹½;jdQ
ÚäÀ°VcªãnÜÊÅÑ
Åãÿï4\Ïï<Ú8¬8¼
è’ÇŠga0Óå–µh†?Vï2¨v¶1 ¹İİ¿õ¹®#"jÔ¾ßÌA¾
 Ëp _† Ohb†ÈRuU@»ú+úFÓşV»~O›¡bûvVñ=íŠ¥Ìı÷ß|ÇÃ€Œ34LA	KG+ßB]˜®dü½wÛâ‰®w>boĞ—ş–µëBKIø©ÜZO·«ùrÈáƒRyAÀAa:xUàf œ®hõ\]åíÇ {-Å,eÍ]£@­iõ;¤˜™7Éÿ5•?ñïd´,UÓ
Tz­2®ôbÀUø®R!¡…"6`¬/£¼éBñ/Ô™"×Â¤”Wx]ï• b¥X)6EE/•¸k'Z-ĞÛJ`ÑFYÄ¿”Õ\ğ~ˆN{.OŠ)çà> Q/ëb!tQ–}·¨øKP ¥Œ'CÕÍŠP;ìø ˆ•c=.¨Çg›Í‰Ååó8"¦Š¬œşd«íiiP¾‰XõZŸißd²@¬{üqâWı’FçJš×ñ¼äå DsŠü8ëKGóƒHm2qxqâq¸"m§$ö¤í²ŠkvÔÅeóp5QÆ¸¿i"Å¿8Ùz•ôKáô½!¡rJzP+ï©¼`½ º%×³~6Àp5Æ4­%ZıFrËç ½lŒøÙËú¼¿NN‘@-Ÿ£4üè´ˆÈñ £¸Û¹^Qğ‹:Ù2<D=éû;áz™_m~¹EŠjÛŸG%„o:ÆLÒ»ğõoÊïÜ³Ê‚ÕXÑúğë9û,nşßÑÂp{è•p%ûø#·Á!`ÈÅm/;º±¢á-í'”Aª,õá¥1íêj0é +aşèû¦ÓGÛÇ@.ô‚£—N½¥ñ‹o!éŸp™˜‘Åd‰`y¾±ÌRšréí§úµ-§@ß”ŞÃÜ;4Ôå—„Ô*¢òğ¿¬`¥½£ZĞğàôßw¡zÔ«ğ\Ñ†Ù%‚µÓÕG;0pÊå½Ç‘º6¡×Ö³h*ßƒ¸u¡©¤c¥B¾jìb|¥®[‚ÊÒ:&ÓßoNCe—Ş†úù³Æ]Iì]2y;#Ûº¯¦ğ»œa×±Ü_$öƒƒ'§”ÖÑ[º()Ò_ÿ¨M­Qzúx:QÙ'Y¼Ùå2ÿt˜S°Aº‘ì wÌ HE_+‘ƒ{Sr9ÉSpcYkıÉ1g@ëxVn¶©@Rƒ¶Øo²ÄÜÒC·×Mé(àX4¤é;îÀùå€Ö|¾>oŞ÷]Wy­¹Á’qÛ2¡îüLNºv/0F>¥öµUåû]Î•wd-„zğ|ÿ7t´‰¨pÉ£¡îr2Ôñò[=âaŸˆbdä‰ºÃÙ6|{~#|DšEŞbk³hàsÄ×q€;˜‰Û/”XĞ^„9Íƒ4œ$8•øÈW¾ŠŠÁœnc¹á tª°l1üØ êr±´Ã÷İõ‡Ùw3˜k“‚sìLdZ£;•iŠkŠZ¯HúŠÒ«Qà‹U)¦xÅ í°¯õbD¤‰6ˆùG1ÛÛ¤áİglRãØD¯¼?4 #€±­røÜ|úó:)ü‚Vˆºcc!ÃW¢ø„]*"kòÏvg+ä¾üİÔöiï_ú†ó„ØS‡Ò3ğa}'SÖºÖ&VHÕØ7ÂÁÆ„z=*úñ[i‘çöÒ–¬µÎ`5Ì?û™—Œ¶ÊˆPSñ>ˆ Ùşk†^}¶¤fZfpl$I°
ĞEæúòQÔû‰—Â­ÈŸòí‡ÿkO U¾õ’ÓfW ğRØûhPb¨D¬Œ^4î]XgJETÎ!IùëMŸ±AxÀzêÏÑ‘Á–ÿµÏYi£{öÛç#0š–hèõ“–|uÑáD"Án9_–%S9B!İÁF'¯h)bÂ¶Àæ€Û¸–öâ]¯ñ]BÁÔ&÷±&¼X¾R‹p W2dnÕµ˜ÔÉ,fæá½AÑË—qâÎ
e·jCA7¡Â‚Ÿôí<AßÀ¦eËåd¡ÆĞ¯–õJ*eÈ‡÷e:ÿ.6½«a…¤±Fûjv”o8Ák.ÎñÄêìÜ§ Ğ´¾‰RÍ*C·Õú–6†˜æ{$“‰Ï†™dYÆ÷î8v,s+W S¬ğ”wÙÙñ~™·j¨P‚aà	zsŸœØ--ec£°ìã†Yo¬&'@³¿G«ËWëÄ`ıA¤ü¢Ôbõ_¤¶/EªigØ'”ÂÙıÃû%‡¼i‚Ê/Í9)ÅÔ¹}‘oe9Šh‡£²7X‰|‹½fŞ:ât8“Ù_ı•Ç’£¼YCÕ+~Ã[TZœ5,îô(
õrc)×PğªnÓ¿—°Í¿‹Şô`1+¶[üDÃy®ÖıEc§ØÔ9.-€=€åÙğ)Âõì@$VW}ƒáLÌd “´ğİşQ|ÈÁ`áLGÒ•Ö ô[NZGè ‹?i8×W´²JA…ı%»å¥ê$¨tŸb_Ñ^èÈl\‘‘°_nÂÎ''ÃqI/&6ì„ıcòXÌÉ@)Fy¯c^ŸÚgá·L¥;Ô­yåÜÚñ ±t	†Ä‚kÄº)jûŒ7#ºMUkì¯sIb¡·e»„ããœÎC”h9xÕ"f)˜X×„{<Ş1–6(|*ç$„Ä¯…œÏœy"Ù*>¨îm¸? n;ïµËKÅmª…BÄBÑ?„CJOAŞc¿£}zŸÈşWz·å
oÃ‘ ½í±]~8Là@#ìÊ -ÊCxZ${\@ğ¼_qLğ »8’"Gqa»É%N jË°›Šlsr€T†8‘uÚá"ËM¸ö1‰Du4O9Q¡š†hpOÊ=>ÎOºır™L.lÀctç€jÃ‹ğ
BuA<ªÁV?ós˜¬C7é+
©e#ö{óÁg™¿lå”³®.¸z¹Ìî<ƒÛIêz…¬ëÆ˜*?ıë£×Å”»—=NÇ>=Ü!¾ş¢Õ~^Ëí$zE½± ]Ç´äHõ**FçŒo‰„y{Š
Øs† ål‹¸\O¾}Í›eD~+7„EË<€!çD® øxÁJÈG›Xä·\‘V8¯çŸœáY<—øÓw_#SÜ;ôØ€˜‡#ğÚrb•1ú=eÉ+ÃùhIzërŠ ›éUkç3‡Ğ¤F¥¥"&?áÃ¡âÀ: áR¤©`È)RÖnÃbXÊw¹£41*¦w UÇ;!†‚f]=éØàìÇ6–İ‰ ìû%„*ò“ËÔ^9«myßœ/“Ğ©;Ft×Âİ	íZ
cÔC îc7æ²gæEÿE‰p÷P _åÛˆ÷£ïœu'ÿºs=èĞ·—‡ìßóÁ*†…£ò5”¼F^©’ä-GN¿Gíbè$å‘×Œ‚u()É|^
È·0(Tõ•ƒ^H?[:!üë›4SN“Á´ÎzÒeÌ|âØ#:œe<1œÔU¥'~C@,¢H2-Ùí¹‡!vñs VGÑîÚÆ|{^x¸Ö‚îÊÃ‰°;«á›GbÓ˜å¨¨ô÷U	o5OªT©¹Ìdı\Í)Kÿ´²İÜKØçN5²?>ìæfãÄ5¯ªŞ—/kqMÿ»ñÖM \gñÓÔ«È2ïÒGiy4lü%„WÛšë¶z—wïØZ>Pàdç?g¡¨Fİ$«Q/Íj
kâÌfYg3ıêSÇÔIèÿLRgx7‚z#÷49 ÎÒ‘+ú‰¦ğ2Y454ÒÏŞô®OĞö|î÷’kÓ4®lÆ°û€Ğ¸ßÒôb$„ë¨šjëCS@¨`,5«in±©İØVJ8èû¢q:›‘r1„2Pô÷´w«_5$Ú¿ÄJDkL4Ö8PFµã©¥xšãèÓæËš}Œ?ÜıÏ9$GŒt0(÷èzÙkB(©Ö9
®@‹—‚?êú6ã52ã—›(Ñƒo1ŸöÍœC(†]<LŠIN§ùÆ}J¨?/ÄØÄ½¹^¦&†ø18EX&âWøf	äP£ö>ëât,Vv<"µ¯qâÌØÍ}VÅØu•*~@¤dS¶d$¿¢‰üÆäê´ÊÂN¾I©vÙ¿¬Eö4b0—Ò†ÙoœxS0=üŠ½ä”Î¥FÜ)±BŠ s3¹³$J7™ê~<Ó¦?u"‰™éÚãÂ›uÃÖŒ6½¸áªÁo<+j'mÓX_ã¯=ıÚ—•uÁ©¹˜`Ô÷Ä¯—3Ÿ­¸À&ªúmfÁ¸|£°¶³Ÿ÷ƒËÃu¯2úÄ¦d‘½h(a} (Ï€6ó1nóiƒQ…mœUfXò4)ù#Ü•ñÒ}óXÉ*&rÖÖ6Ù¹%èŠ•·ßWÉû·H†wTû(%f"G‡v‰|^qçÄFK…×9c>¦WŒD¾|ö0Ò§ê" ‰³Ô”Ù¦ZAÓy	Õ²­ëé
ÚyÍzá[jTê—_øûOï·S£[=tÜ¾¿•tÿB€úlÿşóÂNÍ!ægO¸³Jä®‹Áå0)é½·zxÂ“ïŒØ{@qè‚*”:_^Á}z-ùáÌ…7:¨d×&¯›3PfD52#	‘ü
h.MmùÅ·lbØ1d€ÅÊôí4s#Åáæš¢ JòÃX7cT¸KØ	Z.É€ ÓÏ_´Y	v©)¡:4'r²àH¦ÂİÒ&)ãPásÒLZU^v1Z+ë>SéÛIPëŠïû[I—«Ôs?-è].ª\„ÌomvÒ€´NÓe5ûˆ‘ó÷z†Y= ».¹yD¨so\:¥ûUWmPKá/ÄQhx÷	¬,…~êS/`ú;‘¾Ò¬MQ¾r5–§s»ıˆ³”eŸx0â;P¾L‚]à[Ô]¹Üé‡;u‚6v] WØJÆsn~º%P½%>´	Éø¥|Çb§•$/hVX‰•¡¾jœ¶¾Ğ21É×1æ—•‚´‹2œuœèÍ9V,ây­Uá?Óù.ã'‹åĞˆı9jöBÌóò.F,å`ÖQ@±mx6ï¼	Á+ÖföËWoQñÑMÙeE”øÕì\Wiô6zÄ I¨2€TbØA¤{.2:ÎÑÑ¢âÀm]Sg;3á1qsmà9kÙcÈ‚.ø*¢.Üİûp•UXç*˜3XÓ a¾û]¸PÃÌoQŸ—«ÖÓ1f@´}Àk–6G(kŸ®ãÌï$Òş«"\¾—D¼$Ö¯Ïœïq+` )èI"¨toC?)fe]³*÷’,q¡‚™ G¸fw§¸*s¥öœqWğ]á¤šù6 Gºÿ½ÄKSÆ¿üh@&2<Ç^Ïµ¿ïúï¿Kq’=D­!ôÙçHœ÷H#êöÉ3àjqkC€¨pËğõÙ‘´h¿Y:ûÿ<‚“Ö£ZP¼|,â5ªé‰,Ğ/mö,qœNÂhĞÆ'õ$ElX€#°ó¯L8]¾Àå+½\*`!J"¨M/˜×¢Ğö¥º‰Zfo*÷Òİ´‘}}Vº‚ÿlÄ?!@4#6Wáö2ıt»¬¨G¬ğFé£wıE ¨²GİúÙ.{`zÃ™*(ÌÌ	¶V4¥/¢»š}
Óë–£´|Íˆ4YÑI®)Ñ¤ äÁK•Üa‹¶+ï9ª·• ¥ÇØ0RØ(áé‡ö·ü¬ÁÑ.™1öJ¨R¯v×¨ü©¾Ùœ}ŒˆÃ²“l‰t3è2/Y¹äuòvÜ[ä$´@oXü/m³ñÖÊ£İ}#„q÷o+³0‰Öø Ç—ÿU#GÀg'ğÌ
É|êÛÔ—^2ˆª±IÈ$ Ù€âÈE…7Ş3ÀÅ©©÷ÅDÂ„Ée‘Ğ­$¾¤'ÀKÔÒ[
iâÔM'Iy™û±øzønDTedı/¦OÔ-½tÔÓ[¸4m‡û8–îÉL(k¹áÆ™xæŸo®ÃJKWÃã‡»÷´¼¬
_¾‹—Y)cNBõ"ÒuÍK:Åa!Ö×Ä÷…«#€aQ£û¢½{Ş÷§û$½Û°S™
+]t§yOŸ}ÈHèâ@µ$Å5VH>VòİĞ5. —¦çÙ#K_<åäHw/?ŸjIŞÁ«1}Œƒ.şÅ<a$š©O‘¢÷g­({±™×ÃŠõyÈè›R(ƒPXÏuÊ«3eUÏŒ£U;´Ûã¿
l:z…Ì“-=§–ğä0íë—ÛeyÄ-zİIÑÛÖíÜ=ÀX*>Àtpv0«ZhYÿ@GígOööÌã¼HJQ¢ìw(Wˆ}O¼sî±eûe€¥iìáRpº“ÀÍ7ˆ“kÚË·÷p¦Òg7…"_¯-ı•¯©ÉÂ÷ÕZ^ğî¶c|•nJ½¨œş\€ç.bEt+FDÏ(±àÃ=8îqé’±ïV¨F5Z]Şx~‚²æxjRÚu»ˆ·R¦]`_Ç!JÜEBÇ¡°•a……¡²`2ÒM	 ¤\ö[g.ş<ıiƒ¤„s	”…'u°ÜÍCn7ZÀ÷:0Ë.K%šm€ïÎ:^›Ã(#@–Êğ£t°\İƒû¬m.m×Ù!¨	“Çö³ Óì“DÇÔeZøÀm–P“¯éíøKq)= ÛÍIFÖ°Ë÷8’~'uém½äÀ¢­¸nò06¸ü™°¹º!_‰M;4øz½	Ö#5O&R	i?¨ïLI5É0Nû±/+¸‹ÏÀ †`F'êj/¨oéõøï).½ù­íø²pèíİö)ÙRnLv=yA?â›©z¼ÓæBBÙ(¦@ÙìØùõÆnÀ„®Á(aµÁ½#Ö²wuÕ«yèYÛBŞ»¸Ş­òwc?= üâŸÇ—Xâe°v›‹ãŞÄ}w¡\?ï^ÊØİëÆ¦Æ¬^sq”2^Ë“ ¾ 7>Ÿ:´w™"a–iº¡>ÿÌ‰XŠr—MdlöL­»ná×’Ää°ÑıXPO%şÑéqZMEuƒª“›¥=Í?±J,4¥#ıxõb©™wõØi@áíq†m«¾Y´VY®mˆiê¦K™Ô&~òTdtõ‹MëèŠÁŸÑ‰s`êÏÅ–
ZÍ;Á~Ô·<e„Ğ.lßùÖà¶ªQ%{øôº—”SG´k;ïEßO	OHÂŒ(F”Cµ$¦f‚¦”Gå‹™ÀOAÃÎšĞˆSˆ§ÙG e0¼[v-ó )XÃwßÜaí.+“¢]›%¼³€f­yİÔŠ)ıÑ¬Ó3ÔİÓ)é|†Rg¶=óª† TËŸ™„$,–Şpv€¦gœåLÌÄYĞnsAU¢fgÓFŠz€ÒËVé&øñb%:áîu`<úáªæ	â1*Ák—O^Ãƒ¬™#TTcãÆ³VåO	ŞZøÉWa":Ù=ÜÑàU.¥KH
n¹@KïÇĞ/17ö_×ÅÅˆ™·±şø4İ&•„¸‘"};'¦”[)¢h$ØÛÍã°Wi'÷=ÊÁ]8:È	%Àï€)Á¢"Ş
Ôjÿy†0õrH=€†©Ø
®»è^ñ],Újª pGUÏØÑ&}ÃÉ·Ğº¹Âl6¶¶…3PÍï>m1>ğ¡§•Kj^á´ÏJ{ZÏüæ
T@\§x‡^!ğ[m¼\“Îäl5nšvóGá<ê¨XUÊ70»å~º#c„6ÊïöËë¸%tHåËY4^:HÄtH¼%Œsƒ©Üê­lÄ»³¤¼‰Ã#.®5£ù3W_Sû=öAË“ Ô~É\|3úİÊğ_Ö°P\ƒ ç52¢ÆJéµª˜9Û&ôæ)Q·-6ÛäªAÙQÑœßüfI­¸ıM\ğË©€ú‚p%pôËNîMt¨`yâÎ™¬J8^ut¹‡ËZIdµù’ã>ÏvÃê#Ûß>º‚¹Î!fğpÍQ€]ø'*yxıÈ½Ùyõ%fqÛX­¯ïáË}gF­?úÁè” W5¦ã}ñœ=óşröƒàrĞ(ÃÛ°òrÕóºâSåtA ÚŒL,m €‹Œ1!°bš9]hÕ`wlIã`<gÕáØV ÷º(mûAT) ¿mƒë§¸‚‚U,Çİ÷´BåcÊå–ã¶
Bı­R+z–i!Á·÷q;S2j,‘®	¾ÇáÀ€0‚àé!²ìéº½xc”ã´GXåß?ŞÂSÂ|{š®Èıò%C¼M]™ıÀÔ*R‘XĞwšœ|òšøÔr¾EWZ{ÃÇuÂp7ø2V&	Í…ôZ(Uã÷üaBŠ õ'LÛ:OÉÿdö€ØšEV—æé%¨ícÓ#=roØ[³+#,¬8ì“ªd
sÓ€¶ÉYÛ$¾ˆÆ¹ØŠãH¥Àåp(#på­T,áOÔÜRîœÀ+üû7¸"Ùµ•ì¤OJ‚ãÚĞ$H÷ó«iRL‡o¼ íâ¿ô¶l5Q/ymg§¾¨P>RÛÂí™q~ˆ[]³0F‚á½qNîlÎã*ÏÏ=ÉÀ‘¹™Ë{‘ÌR½«Bıÿö;*ÊF˜y•ì}}á¿ß9=uy¶Dd|)L†Ğƒ´ƒ!š*|Ûª½E½¢Kê_¨9&¥¼fED¶åz8)¬FÍ9ÄLëÕDjtÊÏô‡öúNõa¬¬sŞ…&›¥a¦fUÀÜ´²½@CYL/ÃİRùö£P³<İ/eî7J¹f¨k‘ôµ¼(
Õ_"ëÊuÓ*½Äæ=–(ƒËjÄ~št6_NÁÙ«Æ$ŸØŸ¶^¦j·Œ¦+¦Í±byX0FH¼¯Q'uò\A.~NXs]lÿàUŞ&]kÉÛ–¬_CfïWR8¬­.ÂŒ¤<³™Dª‹½şÂ`D÷õ*ómGÊpĞ^š[Á¼
‰_jŞ\{Ä}8üfTòäfı«ııHv˜H«K´oUF>lîW·kKû¥ÇNÔßz›±šr@Éõììü“4¬µèü£rÖ€+ıHåásS¢1ËÁ˜k×·ä¸lâõ¾`ÓçüƒWY¾ÅX2iÉ5Zy¬NßëlÅ·Q™Ö ’.b0| g1‚úı«Äéå&îËüTñc%;ˆUÇ©v¦“>fª¿Uµ7Í}˜Í¬;æşL_+™^lŠE¦^dØvncÓáB‚¾C´*jòÙ$Ï+Æá¢¢f T®l–æ¯—Ô™:¼±³»æ2A=ÿ1ì¡™È…ğ[ÊqûÅ¸o/Ÿ<Ë1t]ş´1÷~2îV‚ü”c‘½bp×,ÌÅ0øú#İ¿Q`ø ×öújôjJ,ÎVsŞAL^]ˆ¦·àö) Ø÷•Klƒ·#»åÈ RLU¦éÇ’%×~µ¬04º¬ªaÚvÙõ™”ä·\¿ÃêÏ	N7ÄÕEZFO:<iá7érú÷ş¨Evhä"b\bë´›ñ€Ãe‹™êø¤¸àÆyªÚÈĞ"÷¾|²­na‚/0âôÓA{–*Àeéìf«·£¿¿:qô¢°´gá¼ÕeƒZñF†orúÕŒ.’_.oÍ¡¼dÕRĞa‡,”Ü ¬ò5XÅ$EºşûME¥pÏ0–!ª±€)¥æ¶AàXüà•üÄz§‚n3X÷áÖCÊgZ%1MqsTü¥Æ™}1ËİCgş6Í5¿J¶bãoÏ–ÓU¬X”Pµó³
o
ï_Ù²Êw"lÏ¬Œ\b£|ÚlUÍ¼/+q¦Âi_•Ôğƒp½ùû£;¡£‘¡tÅ’æl&Xü¦ƒ¹|ûl13]Ğ|J78š	qÀË|§ø&¡Õ¬½<È§OG±Ô%3Vz¤äNîìèá—$M;ë£$Ç”âv×r=Hœ‡Æ„x$gÂ-1›*g>¼Í†YîcAsÅññbÍ‡¿"Ûü@AÇ5±1ÒÕŞƒÅ¦ˆİ&q…ÏûßÂ¡ÎÏOŸ+î.<dúàÁŒII¤\AGÿpágZ~¶½´ÏYÀó1›š>ıy…özCX‚ûÅ¾ø°¤2[ş—9:&±¦›®ø¹0‰bš¦à´ú9uŸE$TJHÖFJ¢6”Ä#¼ÚlmVÎ¦]2ÒW@DlwfRÿ“fß«75£Şµ’P¥“[Æ€Ò”HèŒ‡Ñœ#Pì„Û!§íHØJøğé,(såi¾¶êÿYw/›{à…”zù•yş)ğVB"‰tÊ5	ßLò€"ìEÈÛ±úú§‹ÂY¡'~=`Ï’Ü3´ªàQÜˆ0@>èÛ}m;G²Îf8z`zìˆ™ÔMrà‡\³\»U0Ş·û\“t«fö@­¤‘—›iŞÑüŠP©wW¶<CJpv6¾óOÊVi&Ä4¨¦ÀUT"¥Ö7‰ ~Á›ÿæjiøÛÈ0ÍJ·k¡ùAG'(.‹$®xŸ9ò
u–Ê‡œc9 ¨1€'=*)î,@&>Or@Ò>?ªøè`wû€„Æãñİk¹bÊP{ÃÃ¯56«gO>pw%ëğ` J4´®Gë8½ÅI¯ª^wJ—§|j£À8Ìg½§WÿpÁÁlŒj®:"¶ç™*êhlÑÙ]=ôjlTF ¨%óÛp[ÜKx-}Mbq2rÓ©Rğ6P\9‹#ñOĞƒ==A[üıÌyÿŠŸ»Åvá:(Ôd&˜Xì(æ`Šc|İ	©_¹ˆKÆ~Ìp·¦8ÓsN—~âm´…»àã½Oñò»’;yFqÃ8ñıîm]VŠ-E&õy½#ƒµå!Òwñ9 øüNÄ€Z@‚ié[AvM¶Ÿä"Z[Uí8Åğ:m)„o
Ä•=Tì„œ¤’Åãy¢’Êİ›°å¬ö÷`p¯Fpõ&Ï¤Z
½AÆŒ
Ñú##}­vıDsŒU%uNd9Ïğ›ˆğ‹eÿ“qVª§ÎuJ¥AÀ÷¿R­MRâQ8Á2ª8," ”ÃEc©íòæovûÍ0cfÓâA¹zRœm´g¿ ±4'–=œBµ<ow˜][N*Ì_×Š24§®ZK^„]¿sC)\ê!2÷Æ.(×	kŞ°dfù"·±ùLœIÂ¶YêÓjÔw:]éÂ<Ã–·ô7;°Œõ/‹T®°˜?PBÍ+²EÕÂûLÓ¶İP…³)IV†õ¨·ºów%½¾<nò}i^«¥Õå¨6*ü.˜„-Í/êûô:öJûì6ª7ú69Ğ“
7?Â Ÿı}ŸìĞ„§ID©Okcjé²‡ÃıFÖş¦òìOôp¹;¹!Í~Å®ÿ°ò¦‡UˆÇ#›¼?4y—‹dPš²&r\şGNÍ´3)0¿äz1´¼òËæ!­êì!&q¸µ…ˆâNˆÊ™wëSqrgZ/ùü¦ÚğÔÒÎéª»J°™Ëg=®Gt/iÕ±(ôrN£vl/MIIdûû€ÂzëÃlx¥B˜SÍA/?—è±rÕôC$‰›S Ì&#¾Ğäzfo—n?ŞÌGÏ<“0“ô	İ2:VÎëîòoöoÓå„T|w\·y@jÚ;ÖŞí†èÑÿ•têß%İ \T¬Fó"ËDùLS[T/Ì­¨ØƒDûó¢Í€’ÚM›tÍYTHÊ3–z3Gˆ—ÁĞ+½üÄûƒŞö’v‚úy‘ êş¦³ñï´ÖGÄ’øE:•çsƒ&f¥SîÀoåß
Œ§BåŒÌYÇ!™üªê^P¥4‰õbıOÍT–©ôŞ&õÍdßáR®·…nßºêëì ²äÜYlø³¢mÃaÙáĞd~æG7AîH­ùÿwêñe-³©Ğ£¸,gÜq'öôÙ?âÎÇ6á£‚e¶NMŠD¹G+LzWˆ84´Q‚£D«ZQõ\Vë´×#["Pv“B‹ú¶/4ÑbJ¶f€ 4’­«ÉB²wQüÜ~92Füò-c¨w€æ+&™¸#‰Ó!e´fÙ¯Âb¿…eŸ¬%ˆ­0ª#6B2¯*YêÅjE2×›òı–WÆ¼+tÛèæc‘LádE¢ş ûÆ¤–@2ãJÔ[+úÕoÔ.#Ë2ó¿s;­´Ô¦!7€‹&FAPÊp_zjœ6¡,lÿw€ÿ@çã pà’>W¾±Ã=9ÑzYú@ÿ¾™ä/š‹?¼¢‚`¡W^“”uøx¯ö»øíF#²%Ã3.§H7Hû©¶’ó¸¹	`cAMgµ¢ ¥ù÷ÍB×gÜC]ò•«XZ-õ'œÄh×[ë}®ğÑV\Ìı~ŸN!P`’°4&’É›ÓP7®bFğxW
ü@ôôÇBˆ"Õ‡˜.–Ÿ›m¾Â4«P,Yÿ@õ¼ÒÓÛJÚÊ…R›{K¬)ÛF35Ù2	@é)«X[œ˜ü”@×$Ë)Çl‰Mò2Î1í•vf6…ÎÄÂ¸±d¼7àaÜ¬ê‡¶%MÅôıšåœòİ£ÓU¤ºYíE¢FF¸:Í<
el–«éíÕSÈRÄ³G£ ÷~>­ªŒğx!×£%Š;Óæ€)uÇ¶d[Ô#eˆÄ[(“6ìû$Ü»ëKÙïÁäfÿ³œ–@Ï?2üÛw÷CÙU‹ºõïn¢™»Ú²¬5¨éÙ‡	¨Xùd"Bì€_ì? º:4²‚9”âe}ˆ_çn•ê«Y$94X÷®÷'(æ³]n¼ç@İá¡šå(ÁÉĞ7‘;Ñ`ñÃŠ†\)Ø ×cu®×Q¢Ó”¶±èM´ïİsmÛ®¦üË94>ìÃ˜êáªá˜³ãdš„šêEl_RŠ»¥Ô<]2:eM*¶òónMw«¦Ø{T	ùÑ¯Z°S\§ÌÇTnN†öóEƒªEÚ*¦|Ft›üÖF@µàr5¨@¿XQ![¿¢¬vçL°Ú`"ğ™Ñ ]ÊÁ´ÆÅ¾dã6ñ‘|O«g÷3ÂKÃ;İëĞfµœsÚ(U‹&i,}Ø£	RÙéÔ>£Ê(Š—·\º5½<ê›6°ÈäİŒ~/Ùæ“ë¬=Ó(Úı¹J6¶»ñ§!÷£‹tÌ7¾o ò}ä“ı$x$EBÈUS,†ã¿9ÏøpÉÚÏ•¥«úM3ìˆS^Ñ°G$\@&ã¶5Z6uëÏ–±¯ké%I`·—•å³Pæ‡-'º·K€ :½¾¾¿³Wû1ønù;¡\c¢Æ¯s5«> y¾Ö¯~j,³zßñCƒ¢ìTPs?˜¥®A€1"ëV¿(Úğwc‹V¸Y»µAÏnvâ^zĞĞ*õt6-` ›hoc
Føe	vK£ÂPÚ"¤[ßdU=Êœ°]a•“<;|/÷Ø¥û„48¬‹x 4$gD6OV…éÜiE;y­è'âUy^¢D‚ñòù“íU‰ú„£]¡…Ôè6¥‰_ƒ€ØÔ>a1 Â)Ãôiæû~AGªc`“ÂW(¤ –„¢ãPÌjU—J˜«ÉA‘V1k*³¹l uîÌ¡˜ã—‘Ï…¹é™‚›4~ÉÄÎå†Ê9B˜ÌŸi«Ğ¹²ÛF¡s¦ÅdcİF®1bO"=…èœBY‘ş_3ò¥$`°ürdÏ¶ŸÙ£È˜»¿35èm Š8AÏx3?ÔVµŞJš²àãÿ2¸Œ&~…R´`ËÉ4¬~I“*ñW8PDø‡¶îì‹Ix”–ĞE Ÿsdèƒá†§.1İQÂ˜©Ú`ô ¨/Qo¶ßbºàzqÏÈå•É ÿD§”îÆŒ}Oø]ö}éõº²æ8‡#3Ûkèv‘*‹Zk>x÷¤ôˆŒ~L\FA§ôáY£ —¶€ã=‰êãZğ cµl±›ÍÃŠö¦Øí$•æ[-U7fğ¢Xx ÔPŠèW…á¯ø,ïî:—qlÕÌ;„‹íR›¯½’‡²§0¨—ÎU¡VÔî“édZºÔÈ¯§>‰Ğìv¤ó´@a8ŒÊÒ,p.Âm‘l )¢³®"=ªß¤¥İ ÊÃÊ–Ë\,`ïùd¦Bç3Ò
é½˜ Ş!{EmÖO×áµó¸Ëô@>Sk‰ün¯O}ÈèÄI§‚±W"‚›#\ï4LúJÓ~¹kñß^­UØ×ó;üe™qÖk© µÙ}ñ ©üÌ@z ‚Ó»ÿápz}&À0~ù<91z[Xaô„$õP&¶r»ˆfs$XÛY•İ'Š–N´t;~_ös^¤-×blèÔSU¯®ûÚãN÷j©Â&„$oœµt&Í“å[Woô¢]Æå¿(ây‚gbØ¡0®‡—ëÖ™ÓÀ"I2s¤œxÄµiş´yx÷ÂµŒÿñYv	î,O*+¸¹¿ç9Kágæc¨@A\™Z­y¯Â—ˆ8<…ó:×]G°–YWtÚ#n)üĞù£Z÷ø¯ÑuD†»²Føq_1UAfÖ®îólŞ‰Tû§i±ğg +©D™ıLs	¹ñÿk¥NÕµ¢Õ[}Ò­oœØ*×øL—í²*eB0Ìh•>†Ü¶öGsíøşŞRô;L:y“¦-÷~[¾êÂz7fÁ–.”µa'¤Í/}ôì”!ñj"ı^,:¸¯ÍÖFJ¹ŠHš·x²fä?	(›­,†¾w¤ˆFy ¬]±÷™nB¬"û.à×è0Õó_èûzN’ŒZF?ÄŠGêÙäguÎ¬ëL„r‡Sª
LäˆjÆ /\Æ[äÕ´‘wŸçŒfN®ë#g¨Øùeækÿß‚»…tî!LÄ+P×0Íê-ÌËç	({1ÄE?BŒèÎvULá»ÀÚßl5Õ=<|÷_»İ=³ UÍfîEs!©¨ÈÙÛ¨WRo¥©®H|ÿ	£>a\©D§@®•0åAÖÒ,“56ñYÂõQL|kŸã^È¼só”Y*~)Q7¯÷pœ(|†èÆY×ÏPE4ÿÁ­Î»í‘¹¨åoá·Â2heãspò%DñZ*eÖÚO3È”0N‹V	úÁ“çÇ§ä1å).˜°¾Úßw_?g3çCv"l"İßj*ÛeW¸Dó^ÊÇ+[7îKº‡.÷!~¸œh­ü³C"ï®Ør·¦Q>eTÉ5¶IuÈÖ¾¤ğ‚ş_Å‡—¿o«På¿Ş$” Ñ„¹WQöeL Í4+?Òÿ$uÄe9Ğ½?+öşW¡Ú 8/µOï»ì<[©I~ç®ó'n+¡~™±§û(íœ;ÄhşrJÈLÿ^<àpŠ`şØGïà²®Û¨œÑ|ÃÎ•Ÿk›'ÿ]ˆÙ_5ca‰2Ê]¢â½ÄÇÀƒO\R‡cqHí õ`ßÉìÑ7´³Ã–ë½TVí 4ZÃŠ(šÜæ‘aÛ7\â¬ 4Ä¸wiÕĞøAÈBT– vûÎí‘ÿBµôÊ€ÍiM…éI.„«8Øtµî°—‰‚:Vw;…ëRyÉÂ\-F)/ıH£vh…‘é0¯E>)èZÅÁ—˜t¿'7•¨›2~…íƒö_vjŒ%2ƒŠà&ãÕdÙ2	‰”2×2j	ßÈïø5îòÈºoŞ]›è8¼FfUô6Èa ía{ÏgPjü³ÍÒŒ*bŞ‰°‘(šm"ı6~İ ïqıFüŒÓ²Ó¢¦€!€E+p>GÆ¾qĞv¢<íã8uZıx¹û>:Ø‹®ºj€^3“+,Ÿmñ=ÍÕ64S®{aÓÆ‚Â¯É»FMâ~ê®—f,T ö^Bíƒİ®ìoºòÓLÎÄµÈ¾ô9iµûüÄ‘şœGCi†ù8Ø<§7
ÉXiAed…ÿ/Fà=XgEG¼y«šœ##W©ë¸ÿAÍ€¹î¡¹¾”p2y0—3œ‡5Ô+Ëïz•®ÃWÅkÚ6;5Öa‘{³êyM8µÑ º'«ë§¡tÁ”bb½¹ÅIÇ˜xŸr}ºXtôN,÷`»:ƒÄÇ—43óÇu¾ä,É‚3M
a9í€‘#+ùbªl0SÄ‡•úµr'óag	"¢q!C]û9üEıµáæxVzRx“%Êƒ7S3Â¨Vùu`º<ƒì]x¯ ’??@‘E/R"ú+o¡p¡rë¢æ­NDfÅÂPû#ZÁ>›¾Ør–@Ë ra°Ñr¾ïÜ~ÚöSO,'aÒ…:éCJà¥hÓ&FÂÏÏj‹«uÿÉÒ"t$*+MyB7r¬Fñ²¹J¦¼ıÖìa¥Is×Ø{~šğƒS½eLªxvº 0¦LYÅÔ	`QO~Ùrğ»£éèyÁN1'ãşÃ¦mæ‰!ÁEô.1ûËBˆUMÇä}ï@||!‡tbc+›6½;ùşÈ¨Ñ¼c€æ½ëíĞyìştD¦?½&ÙÍ‚ë'œ¸—®ScÏh‡Ğ›ÓtTÙÌAf…cÌ0¤s€kŠpçÁQc’ßK›“k*‹í ~¥èvÍŠù)(]‚@@¢S#;e­Ñçõ~é	S¾¤(y\Ä×ğx<j³ßŒŒ¾ièŠb…ü8:cÇB½œ%™6™·¦æÖ¿%Q4ìR¿*À,ÓMªT±¦{àQ¤»RÓÕYk ˜¥£ƒä'ÇUOƒsŸËE)¯ßr‘’íœA¹LæeÂH^oNÙ`çõ«:¶L­L·3ÉBLSyG>QHéFí3Ä_²1OGL=öD$¯±.ã¦¼sz€ô¶"<õòŞfƒ†İ®œV+@ĞÉ‘·uè+Ev“±“Ù«ÑN&û,Ë²£XLÁÁbl-n9:PŸE¾:õ9¿èì9ö¢ìÇá÷ŒPˆ‘t
ï¼X„PO¶s{¥OT4»	ˆwùÉ(³yÁ®²KfÛ¢œ‘’Î,2‡µ¦yİ}:ı—ºëAWP¦¤[şóS=Ö¸iû0;õõ³l.÷~¨âêKƒª‚ÉÚUâ‰ŒH<ÚkiÅ8æ™Úy ú]FaÏ_y*¿&Æ—:¾;KnÖ¡ü0ƒlkõşÖn¯„b^­zæ»Z–Áë‡Ó3Ó	WNŸˆ0ë`¨M#97XóVJÆ–Ã1A¼µoN—,¬«ãÕ¿FZæ²š`œ‹ùÎÄÕMƒ±İ%S§°¡r{£HãRz ¿1§“Tmc‰a›[\#]NÊƒrÈÑªC(µıâ×÷¨üåEŠN)ĞÀ­õ5“ºÅŸ¯GIÔèß*…D@â²9@şGŞô†˜&+ÏÕÜrZ6]”36f‹·Ø€„äE¬'ËÎÜ8ø>á…ªÑFv"#n Häm½zXZ°€ÁpŒ!5I(%ÍeŒ\Ş÷‘Ïrsl’)læ=Ä¼;w“Ò±5 º4Ù¶çálÔŠd+&—Ş¦ïJş{û¼1”tù`ÂTip0Iµå\Ö¿0õúN8G3=¶
"xõ¨k@í$ˆCõÄ/9ò¼^±œ‘z0:â?šÑ?×‘`Wât~©Ò¸'‰q´~*r‚³Äüj§Zkü{¶rn2ÔÚER†,)Ü°»î¨£ñÈ¼M~¦© "Ã[XE¬/.òMø>Ë<<ØEÙe^İáBÎ=EÏ|ÃÂš°—°ÒusÌ#KtößÖÖ‰ìy[ja=ÿ©—û08îWƒ‰f¿ƒ,êøÄ?®×Un MŞm¤7@«„})…ÎÛ\şÒ(x–„áò<rõWàô3SÛLÎÈããIÈ|ñè-\øïçŠfÍæ¯x"v|İ‡¤e½:±dà€sœ$Šw¿ö=Iñ\ÂB4à;%É”TfÚp)L%Ø{÷¯-C„%&çYª”V •º|Q~±¬ˆR¨n»1sL‘L€3Jù¡<gwIƒFÌ?“û@‰ò÷EŞ0Gÿó	¤T®N@pU‡P#×Ÿ—ßrV™80?æ•6˜<7F*¨Vnöj¥éZúµX¿	©–Æ*eOGˆ<ãè¸ŞrRB½ÜĞ2`¥0G‘Üs‰åvzìèd°_Tñô›uØI9Ë'x§ô¸ z„ÿTğ¥ª”„ŒŠfA"üa½à™„…«[}'ø0]¥1ğ8¹ÜÈ­ª-=6$Ãv¢¨áìÉßéRƒ£/5?î,1É?y^KE¯BNå^âs¼ aÀQJöÊF1r$LôçÓM‘Ußü€Ó_vX·ït"Œ	UÖ˜^íğyJ”w¿Êfo²éwúU¬€;T¢W ÷IÜÑ÷f­¯{?î=fBú$‚qªixƒŒÃ™Q&ŒDÀuà`ÈØ† ¿Z‰·ît÷ş[ÒÍSå²¤XIWÉ&FD—¡ŠN¢ÏUUf„?ôÇ†[ãpq1G+º·%dRcæíØ^FQæ­§Lé”—öxyêÒeS ùÆ±oƒ¯+oõõ†Ã„•ãÒv´ñ"kÂwÜíXF0…5œUô€B'qàdØ=.M-UGñ3íª„w
¦€(}˜]ªÏ˜Õræ¶+õÖ|œêş¦–¢©úZAb+¢E_ø½ß6NªİX´‡uIÌ[^€ƒç0ÙaåKê*p]b²Èó0‡ŒğJPNz]õn¢¬–¢¨))Ü6È•Ù¿;eœå~PâY	u¯L° ™âŞŒp­«%Ï“XQ®ÛÃº/ë%_	yŒV¾éEhãË]³) ö+Ñ_\õ¨zDzún¥Õ·My±…”Gì†.VÔL|Ãtp¦ÛZå:!xan (Q<qÍÍ¢4¼á—Öúkæašì÷À€™*ŠñÉ+.½áüú4- +ƒ”}×¢·ƒ$~ÿ Yc’7 ë'ëŞ}æÕ:A& iáÓ |åÒX(–&¼^¯0…oïn ¯¥>uZO(MWJü©+ğ|‰*ê€íËàr¥F"iû‘‘¾3]šÒ¼5ûß²"\uvğd„Rzıl”k4Ø£)hÒ¨/LŠMié³½/–H÷Õ&Aü¼¹BrtÃ°pÿhM9äİÿ–Yœàæ\2õ÷«çÖRP¨f¤é%}}izE?…jG—ªˆµ„˜á‰Ö¡1ZÍØ†>û¿s'Œ˜¹ø,´²7¢AÊú®oÅ®6ôÎ¼ĞY;÷À:*8 Òö¥pwŒıx-gÁDí˜)³@şš§<ª_»d[õI	2è¢®Ó[ÊNüä.Ïâ$?k6,t‹Ú<&¸‡D—rÌÅyW•|%%Şì@ºk¼ƒ¤nÍİ_h,ÓØ‡GÙq‹)½°ql z!àb:Tp”ÆÎŞJí¨rèdĞ†´Ï<È~é“8i˜»â.ÄY³KÛ]i³ô¨$ªÜÁg^	üĞy„Èİ$İÇ÷œ€œˆIê‹‰ÎlğO+ÉÜcd¤eR¥ ¥ÎfåÊ²È^6‘:'ÃÉ½š¦ISq»*9rrl&ÕB¬ƒ²ªB˜}"ƒÄâë1éêÑ”TÀlú9øö
8âî¬~²e‡º¯nGb>¨.p‡=e ‡3ÀÔÃ¢ŞBĞÓ¬Î?®C]ä£gyúcmWi)‘ÙÒ®V¨§œ¨Qi¯—kw¯©ùÙë¡ç°æ}"n´pnÚMh¤M[ï¡Q'%»Õîë3J6¬øÀñx”vÀqıµé6şnÉv
‘$ävV+Ë÷«{¹,¬Å5ÈÌB7qU^Î:3˜j™†mç›n+‘-J¥/BU„	H<‡‹ ^^‘×®«R/z¸b}–RãåœÂ8M•ÜÌ#èÄ^@/CÇZÃ)Pô* Œ-,Áù’¢üÔ£š»ÇûÉjßôPXÿñµ é†baÆæZCÔ´u)H›æéÕ¯GW|i…/Pí±…£ì»‰Oqpå`ÂD©6Ÿ1ÄİÿÁ³ªªFĞÍRãu
~IáõÛÁ„•„…9l½Ãôöàñõ†‚¥¦€ä·†ı?¥îœÇCn¨Ş½F'^æí”P,dÁÃwçócæ”+$şh(º~,Rbè‡HóèŞêš=9’s„‹•hÀ²‡%O><¢+hS`(ÄhÜöŠß>kÙ<³ŠÓ%ª0õ›eJ!,¤“‰ÄµüsšKx
q{)É4dh!è¸%®±¥Ô(4ı0s¯­oŞ;,O# E	ŠóRÖD7@Ûò@ì\[wâ©HÀú<×H)’æçêAërğ<"&Ü«JnuÚ¤ì¸|h¶ş¹U¼UÂ8Pâ|4.9D½Øèãb ‡ Ä§ôo÷Rµš÷ÃF)l[”ú½=xÔŞz9UÏ  &–Û%ÃFOÑ›?-ƒ%¤3×­£ê §±áFP!ç>lñc¥ç*eê-C~§ÀKéı­ÃE_Gÿ„¯ĞŸ¶‚–]å‰ol=÷,é‘ä—qì$«§üN€˜%qdÄSçK]N±UDÚµÀŠÓ^«E7û¨À»…èˆb‰VéÔ¿›*Üš,ùªï9nu0xˆCßWŠÊA>q	~	2-n!Ÿtï¬aÌğ§ñ™Jn‰´6ŞZœën.Œm«kO×ã÷e8£wfÕä9ŠùÇç}¯},w†™92™X¤ÜÍ]ARåˆO rFt‡¬q»Ñxj²ömÑ½‹ªxG“sûB¨rO|ìH!Ğ‚%Kí^³’µkºº(à|\b6ÜHÚs}¥.­})Ğd1JÜåà‡²Š$(Ê›…® ˆòíóOçjlà·Œ®5LÄ¢^WYy2Ğ#°Ş}3ŠKş•è:næİ¡vˆˆ‡>Õ³Öa¶EÛó/B-éıäØlyæC$1ügD
B$»Iş[)T®Bv!7êlO?LÍ$üv5ìòç®İ¯k–“ë÷íš•~¯õ{±ï‰ÚîõïA»æùÅá”è¥úîóØšÑÛ/ò!½w]öt¦²´!§ZÔMÇ¹•Dw˜õ«º¿tÚšG@şRëæÊbİoíçP†¸à–-™áÙã*ê¬/ö¹FS?ƒP¶3•]M¡‘GŒ1“¥ÚBs_İÂvğ‰bñ“¿Šeïéãóâi×GŞîxÒ6¢k4{;>c°Øˆ‰»“ÿ#2¥®¶¤Á““,q:A,c­0Nºµî3¨¥ƒ8ŒŞ$2¨?:5=y¬€Ö€ñ~ú}ŸŸv‰&j=fRáM!-jıCt5JSñvÚ“Ò*z”qí†ùQU	Ü×åÇøŞO!Y‰*¾øN¤»hüÅò$2#ĞP´+ËMQWã(VÂE,€Ğ|I *¬¾ÃüšEB·OÇ—úF€ëÇ;‚ô…ujKıcNÇ*¸Çx^â=G‚.ØIçÕÅŠ9Ê&ƒª”í¾Û±£¶ÜÆ’«òe•®óp®ı?RFV§‡í"v«:z±¦~qÂ÷­“X¢äì0E—8èßZ
ÕŠ"kV,3Ñ¸éMµúsl*•‘Xúa8vŠŠÁÎÌÖNKİdÜÅFR—Û<ÔvA“…$Øš§¾ÚÙ„VÂÆdIï…ß%Rnäà‘_¯Æ‹úÄë.$óS#©Z§‡uÂsäwìò†Ä©yÓÛ-¸°ø‹øÿÓ¢ãÉg*=×VĞÍ,’$Eu{9—$#,¤“ÒÍWß¾Í:?-µG3,=…CãŸ~JC' µ-ğ)—Šœ}GRè¸|Ô c¦f8KéP½9@ãaª1Û'ÈâØwğó1áôÏkÓâ÷JK0¡AöTƒT,ªöšÒV¨eÃtÎUÉl–Á(öV°”ƒÄvVGÊo»ÑêcŒrw,’òoûÈÇ‹óP~KürL¿hQ­Xâò&¦:yJğlÖë+ÉÇœŸ37NÁÎ£ôXñüÚ¾¡EË•©“Ù6T³][r0Á¶ı—æ–Ğ?CE'&ä#æGÙ[5_º®YÓlWËÛdbÅ9+2„fĞéeMdb™}TƒÍŸ‡q$êD8îšQ}‰‹[$J2j @ó+Õ¢Y$÷øöŸŞ°pã›1ÈBX.T©¹{4\¡Gê{‚ÈM	zúsÌàšÙy´4áº õ…kú)hÒì˜UàEÈ,ë1=ã ±¹.ş)¨¶wË«n‘î0«™@§Ğ?&	dÛ`0êW5“ô.Ğ; Óuş»§*8´æ pCw%–
¦ö&o%'±aÅrƒ?‡#MŸíFO#=Ê.^.{
T¦ıÛ¼Ú@QÈ	a¤(j¡í4`¥YÛ	e&0¹ó7í0CãÛù]l‡JçKİ‹ö”:
 ˆçE­Dj1àFŞŸrw5UÛ…¾¾Yû•Y¯‹Ø%CÚIHe?!«¾ nŠRíë1%\]ÈÜ›­…CĞ}˜G¨¡+µ+Ã\3ÆŒÂu"síô¨RûY‘Óf­fnó4D¤›Ä†“ë!Ó[ˆ™È¦yQêe[™Š“‡%#:\§Íåsp²;wƒzÔDî$¶ñÁÑt¦ã%FI÷ùÕ
±Æy¢]…‡†%=9r¢DdìsO™€Â2”ºÎ´Ë¿çÔXißa­ üe×p:Ç#!–ÃlÔGux×ÛnGš‰§«›ªøÂ¹;
b®˜…%·yr·Ÿc$ÕZªLÕQ›xÏ`¬¸Uï¤­0P%67§ì˜Ø_.Âé'¯Øj›ı%n¥>÷6¥§Û#ãrÓU?@\õ6ÍV÷ü.­ØŠR§¼§½2¦hTxÃ§FmâgŠz¶ÇÄÛñÆ;¡÷ÕS±uÔc±Pi‘f+‘E4J/üŸ±Ównx¨n&Ç­Ë×SÎ?†Q€½äZÌ‡ò7c·xm’ŒÌé: ¤kĞ—§I-9G“±?ÿçØè—ßKPglN"? â!zñFŠQáw~-HïåS&‚G†] 2Ÿ~LXáûœïrÉÍÖŒ Í7Ÿ­ZÉ¡œ‹[°½¯±Ÿjbƒ§k3£:§Õ_ö×˜”a&ÉôB l&Åí*™ÍË”æ&ôœi^Äkâ,ÆÒû\ ãeí™?Â†	ÒâLº×µÄB.l˜‚sàÎ)˜rµ÷4“PO¸_f+Ì h«Zd8ÃÂ/!tÙ[ŞóE"\ğªõgí!
›w˜³ 0à7Õ–I°İ|Útkr%q¸Š½"/' ÎÎ¯°Z&vĞ›ü¥\Kè8ë½OmW8Şæ–B^I§TŠh¥Ï¦SÚİöóï}I©6å“—•úØ8@EÖÅF"E@æ‘!©/¼âŒÓp Ç6ÿÑ4n–íÔ'3¸µÊâC¦ø¢ëöPIäÛ‚ƒN×\F+^è°]Hí°˜ëİ© \‚“}p×:_|·luL“ÂP±®¸ ÏöÈEL7p2&t…>QéRŸ§hRŸÏ “-+ÚºæäÔÉ³Úù^lw³ƒVb}7UI'¨´Œ9sÏ´Ø¿Ãe%Â%rn>µ™L!oXÒÊÍM=·Ê¯üä[ö­ØVüÄK„˜®ôòô¢Ø¨¡Åe3"²ÏY)£{(Ÿsáke=«÷#½_ªŠğ¬>€õ9yòríÌ´¼¤ƒOp”]Y¢B?ëö8ÑYlBº|!f¸–ù“ğÚg÷GÿP›Ö´ŠŒáªöYÙÅÂDÊ7çPäfÖ©»ËUZL°-,‘J®²sûìjùóÔjô‡ã4ÌPÌ@şúÎO¤¢³’Íºa+â©{…=Ù-5fÕ`#‰´òİ>µõ”ÁD05z½ı(íöì=ê±xè|’‰³s×ÀØ)ƒ‹…ök,êşM!J˜ŞàŒÔµ÷®|ÌàÁ2KHÍÃµ4K‘»$g¢-cÏÿµ§Š=Rÿ¸°|e¨eÒ“ë	*õÌµ"biÅ¥è†’¢;’0°V¤_?¹}÷³AÕŸU2ÌìakóîªÃ'áNÂ+
>G%ƒ+Û>xÚÒŒŠ¹ƒ`Ü£`Èc=Ë•k˜²Sô3U	j„TÈ°h“}f*@|"Â²h1â7‚½ş^>g[iœ§Y–CŸ´+> $Şv{ÇnJıéãCÌ4sQôToxNÙ¢¬Mµæ
²ÅÆü8oÎ„™¢¯ôä€Zãl»ZŒ´ı)ìGÊ•‘×Dó^«gÍ]OHûHğûÚ)‚)ÛD8Ç¸å.ƒë©Dud÷Ej&ğ[Íä‹¸"dAŒ.}›—¨gRÓ%`!ËNµıÊ†ú$ºË\±…È€¦?#o²ZÈ4ÑWÙ‰ôJy3ÃpwÄş¸,«j†6	 ØÑ<!ö¼4œ±P”ßz•_s—YÁï@„xVZ¯|T!lÅÜü}Ğï­—4>ÎÇš!ÌM’º¡±jm‰%I À¾Ğ‚S¹ö\Ş	FäÉ¥XÉNé—Ÿî!§şËú>Î–\Ç€b?©“Ã®Åu˜©›7l¦' JCnqğ³Å4ğø¯[jÕŞ%5Ëu§„4Ã…TK½~Ëd9ªüáÉ·§/ œƒòü¥¶ DH…¹ö.êˆäwšay†U<{ùR§^ÒĞU×„U²bÁ´İçˆ1MOt¦Zm#ıË7%çKÆNÊs"ÿÏ]wWÁ—ß[2¡eTÄâ<)'p„§Üíx 7¤…Ecè¢³ÒŸo¼ÁœpÛşÔ´s@ƒÁªŸ93.Ì!¸W>„è½+Î³Ğ i¡¾´ „·¦ìs›Rói?H‘	°ÁÛı—³Ò¹ÿ†}9±Í]ÆY•BÅô2eœÔ¯YGTK'·‚ÜUq*f•©îL ÚÒ1KGsïPö%¤?Œñ¢ôÛø¥ƒîğ—DšhyüˆÿeÿÎİR?²ËfÇ„…&èxN#øX¨áıìÃ!jXßG:Ño†Üî9Ílt¾Rÿ),´7ÄJ¨J¶Ry,#_ş¾Cæxí‡íj„¤«¥inmâã!UÃ &ëoı„w.Iãşİ!xËm9O°hÈmr3¢‚\<ZÌ‹:š\nÚ:Læş»²cVà~'Q«º,¦^;ê²…îVtÂìjëë¹`P^u|hÅPçXÍkú‡òX")ÑôP­à˜Ì:<·¢ıè1ÉÊâ÷Ğé^ªMÀéoC’;>tß¬ùßäcYá\d]ŠZ øõ”şmBÃEÀŞíåÅïN¶§)F&\5 3wÊ[DÅWyd­ˆ‰JPÀ^›Œilï€„Åí<¬Xâ? 6¢
ğCQ¡·£»„ÙÌ^
bSô-É–•ûR·¤yç½®/Ä¹¤ß¾ú‘’[›éTĞ@Q®Ú9¸vĞL¨ü»EÁøÿÆ¬]ªØeèÊ×÷éHÌü¯#] ®nàjv?ªls°"Ñ—\œ\æÕ¸ŞÀH†fƒ7·BğÑùËæÊ^s£$‡ih.¦g>ÒÑ[ıA–çºÌi¥õzwO3ve:lârÈµó‰‚|Ï4	¯£p¢ú2‡Ïö:3íÎl/¶«…ïº²8‡¶që8’§°f)Õ‹İ´“ä_ E0{Îƒü<`Î?5n5vûünSy¨¯9šoÑ–Íâlí?\ìQº¾¯»ÏÇ‚¡ñã™ªaÆ…véÈ²)Ÿb. ÊìÎ*ÿâWKl0r¨TÙIÎQ¶0|Êí	b^)—"ÀsÒâÚŒ\8’µùdT- gn!'n\ ,fH'ß²œ±ı‰	èz¯èØ…ğ´°3}£«÷İ^ƒİBİ>¼ÀfëşèËœˆæÁ¬çWiz ¨òEFlóÕ°tSoug­˜Vem#ÓŒ‡}ìK‰"IO_+âbS]ccÏKhÑèÚ<'‰ò-µ;ôÄÀŠ§è¼ 'ĞÿÎ.Ü,¨ÀU]à{Í'{R”Le	¶éµ¢#ÑRfæ\¯n™u#î7Åf°(¦ìE­m9ê¹‚÷¦”§ıôr»­Ãˆ5 ƒÍa‡KÏ¸=;Uà=Œáœ$ŸK§
Ì®×r¯,µ"‰” DÃ"½¸*ì¸N³Èß8JØ€³=’”3)=»Lı‰ÌÒIÜeŒ}›¹»±ëmuöS8?0hi8š¿Ôì5¥ 6”ÒÂ"­
—?S²R'[KÉ¸;=È!+$F’Læ1Tæm´ò°gö­ãÑ¥ÔéÃA£C `§H£8&A…¤ÔGU ÍF½¾;òÒ«˜@\Møh«¦ÿQ3õ9Ñ`Z¾²18ÿãÙUéWRÙXnŞ“.ƒnŸÖXã€¥ZukØÃsÇ«Û,Oİ¼P…Şåuÿm%ìosJa½¯o)ŞfÎ’Õ,§`a.f§(¾P2¸m6ë×—HëpÃœ’¹5å±u©âe8æ%- boqªfÇÜ\-»ÊÅ íó{7ojj¤ÏĞAèÏ6/z{ÂóâÑ5’óSc±ÜCõdµÀ¾>…?ì÷ë×&×w¡€ôl£ıÛ\mÍ‚+¤²‚ğ€V€©	3üº9-8 'PnLÈ’Ú`ÉœÅ>?şp=ƒ×{¥ì`9 ak  ŞÖ(jş Ü	+¿°,Î:4_yîiÁr“E·¤3u9Ùzp„ÑM3²içíİÜ«z)è _G„³ª	†¾v8ƒt–juoñ,Û¦IQ`"ê`Âå­²„h†ŠÓóXúÆüQXUÌ÷f¿áßŒ€òmààµÖ"e±„ÉíBèæ¾ÀÒ(m½ñÄã:r¶‰Ø€+¶Ö[$NPÿ<UŠK/Zc}«é ä Ã9w¦#æÔñœ,6dQÒ>tßøÄ>ú$EõöL”ñß—Ôµtj7S&iPe›OC¹mª1MBñAŞÙœd”‡/¹ôt“VãÁ4Mß]³ËH#2›ıecD.æéĞd¸ÒOèÔi½¼Í£áşRX®Ã…‰q¦‚x „X?FÖT@^q/†ÃÆ²¡}1A#Tg‚û„~·Ê}çJ¼P¼ÿì)IÑ…Ğã£é ò+Ú¡xA
Pæ•TFVX¸ÀÔQT&-Ù ÊÕHZ2µûx¨Nü^­sÜË™ÜÉÔ¼!Õ©D4yÁ«Y	    ¯„ 'ÕÑí ©¥€ğp¼×á±Ägû    YZ