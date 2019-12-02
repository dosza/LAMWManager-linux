#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3317210719"
MD5="c5b15107f9c8d1799f7cac619b5082c2"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21506"
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
	echo Uncompressed size: 132 KB
	echo Compression: gzip
	echo Date of packaging: Mon Dec  2 19:05:28 -03 2019
	echo Built with Makeself version 2.4.0 on 
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
	echo OLDUSIZE=132
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | UnTAR t
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
	MS_Printf "About to extract 132 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 132; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (132 KB)" >&2
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
    if MS_dd_Progress "$0" $offset $s | eval "gzip -cd" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
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
‹ ¨Šå]ì<ívÛ6²ù+>J©ÇqZŠògZ»ì^E–5¶¥+ÉIºI%B2cŠä¤l×ë}—=÷Ç>À>B^ìÎ ü )ÊvÒ&»woôÃÁ`0˜o€®ë>û§Ÿ§;;ø½ñt§!'ŸG[;O7¶;›Ø¾ÑØÜl<";¾À'b¡òÈ2]÷ú¸ûúÿ~êºcÎ/GsÓ5g4ø—ìÿöÖöNaÿ7w»HãëşöOõ}l»úØdçJUûÜŸªR=sí˜m™%SjÑÀtü<1CcyÜtæ&¶Ğ`]©¶¼(`t&6u'”´¼¹A—R}‰ˆ<w4ê[õ-¥z #öÈFCßØÑ7?Be“ÀöC„S¢ÊÒ®›ßBâMI½/ øû¸yò
¦ç@u2<0˜ä20}ŸdêDÅ1\‡4ÛQrêì\ı"œTè•ïííggGF#ylö†Z{¢&¸˜ÑÉQÔ9›ÇÇÆÉ‚æ"x«ÛojÚ~6hz/Ú¯Û­l®öé°İ»£öëÎ0knÁ,£gÍÁsCE¹JQ Ôh X©Q Şè$ô‚ë"ßa›ªØSò†h°oµŞ«½V\‹JŞíãÎ¹J¥œ|ó;Œ®€¨5VuÜä¿ÍÙÉ'·D™ÚÊj×rƒKWH5soÍÄ›Ï=Wcç”o‚bì¾aèN`[”)Ğ4¤sÿĞv({¼~C”JÂ+=œûzº>ñÜ)ğ
YE‚ùj}XÕ-LØ:§“k°ï}!ö,²<2§ó1lÂÎ:l í@R™˜!Ñi8Ñgùä¯dP_‹l?İ¢İ'¦ºö'òAÉnÂb*Ëb·¡Tu|îCÇœ1>­K/{a@:M¡˜¿¡(ü<´]Ë¨mÂOÎ=!Ô5¡E­% j9Eå¥Óldm\çj7ø¥ë)Zı–T|,&¡g™ÀCF<Øá Ì˜¿Áê	åMW–ñwD…Ìg )ÊŒ†Ï@Z'|Ù‚LgL*ËjXKíJMgëGn^ç€(¾]-:5#'\W ¤™í0ïÔl"áSK”²ö$U*YçkZ9kÏslĞ†v(f„ç;äsúôŠNuä 3è75jñòºy6|Şíw†Ğ–ı&ŸNŸà*©å,[‘½\˜ü€2T#‚İ%ôÊI½^W÷jZ)‡_%®"r'è„´¸~\1_i,¥¨#\$W(©RÉ$!ƒLM
ÄJÜËæ¦°’n+oŒ‰›¶›Rªà'«ÃPÏûÜ§RÉ41X5è|ŸDš(s"Ïo•?f0™QrÂY©È&ÀÉ‡åğ­¨IK}ı¬ÿÁ‡¶;#ˆƒCjÕÃ«ğ3Äÿ»ÛÛ+ó¿ÍÍ§…øëéÎæ×øÿK|{—h“"Fs6iO©l®h3¡ÉÊ¯(•¡Gâø‘ı6Œ]L×‚ñ•|j)D¾1:À¿:IÀK¡¿*æÓÿ:*@8úŒÜ¿'ÿßØÜÜ.èÿvãéWıÿÏÌÿ«U2|ŞÃÎq›À7Dmİ“æ°ƒÛ¯¤Õ==ìõÛd|’`¤‘¹yÍm^Ä‹Bsl…×ß“1<›.d’ûdîYöÔ†œ‚ÆÇ)q<ÖóeåüŞ7&¢:Y)F„G~=ˆ\¥*‰#|¢ib´E{ncXÈ(`2¹s›”QgJÌ`!ñŒLo ]Ó‰‘1ˆétœ‡¡Ïöt=V·=ıË”¬~ g5oµ·ä3D¬Y~å›.ãí¹™0ñ*ÊÔlÎdñL‡gêä­FpöïMŸ×Y4%oõãÀî«Uş’öŸ—şÍêÿ;_ëÿ_rÿ'XxÕÆ‘íX4¨³ó/ÿÃfo/ùÿÍİ¯şÿkıÿëÿúæÖªúQĞx&šú¢ßvp ÿÈŒº4àa	 D±]ğ‹xTĞìŸ,4›ıÖóİm4]+ğlë9v¥jÑNBbÜÿãË#S§q¦e×#½Áz£‰e¹Å‡¿¶¹°)/Všó±/…H‡½Ö+JÅñ&¸‡6GSà€Q{œV‚mÆ"Zwi¸åa†…üXÏ«OÔ³qä†Ùø¡®>À´‚‰åÏ‘K/G9!ãe×ı}>ìØv£+r1Ùøñá#)3'JJÎFFÆV½QoäñœõG°PCM"2¶pëÓ€BdQŒS÷‚6éÀE=4gL¨CñhkÔ5T	`wzÍásCÕ#è=Æª*µ0ä!€hœ´úd:+¢ì·ÛÍAÛPïœøe»?ètOx‰"K¯I#ÕŒëˆbûäÒöƒ–´}ç’ »ÓdW?ì@ÓmæFKëJüU. 1¥™+/j†•O!ş¸:œ›¡2,ğC€‹.%¯cßoØ33üğOĞ(Ì 
8,ºà)C@¢9‚/³çãÿtì‰Çç®<¹Ñ‚Ü0Ş3µùq\¢±»¿<øãå ©!—ğ{{Å>aªxmü¯¤»¦“¨.í×m0;—çöä¹=¿ UÑdlëq¥\­å©Ä ªº|vR¹ÈQmÕT›ëaË@t¸~Q¤Wª<ãMÏ¸'ã¢
ù.­òÓeOğœ,N7ìŸ¾ ©!â(,öçXËdEÛ¬7´1¸5-ÃÕn–Ú¾}«=¹Í¡bb°?wzñ‘éöqçôìõèy÷¤Íƒ›ÂòX Ò!a¼<6n¹q,™ñ¶.ïUô±>ûM-Y]*ˆ¥Ó§ry³¼ĞÛlx´Ëu)>µ€ˆª8è)aİRSäÌ1Ô–W€„Æ"ÒÃ!¼ ²z@s±yñba ®(Ï°©…qN3˜‹SŞsÓÑìÜ~i¡b·H	¤dİ•
Ö6È,<z_ñ€Ó`9™ÿHjË¤Õ;›ı£öĞ0Áv{CCÕ,Ä$¶UÒ¤ı"¢"­~w0€- ^>m­5}yØ{¹¥’Døzıöaçµ;S\¨òåÆàJ¡Œã–TE*ÙI»gıV[pTÒğ"VÑkEÁFã'1ùğ›í',Q{=!+éŞûşäj—ûÈ²ótnkÄáâ0íy÷öĞ\¤^°G-“ö_“Õ§vsÚíŸ4oU"¬–Wl•J–X"øjzlZ+Õ~CtšÚoW‹éJ¨J²¾ŒıË@ò™}äe\Î¬V¥ZÁ®ƒD%»¬Í`r¾»]ª1d%Û-íöôÀäó—H~^;.I{uw	ÔÊû§¢II2=æh&XJ&V¸)÷2ãsÛ„åRõã¶I¾gëp9’“=4/¶Ds|áÛDî’MDY¹…-˜9Lc‹gÂÀô¹²%è ^h°gQ€JÜŞ’Ú¤«.‡ÇÍ£Ñafóô ßíŒb9*Üyq
#„¬¹ÙÕ—¨AOœ]BMâxû§“ó ğ¼dFHJ_ÎÛ’˜Âª|y$!VbW/ËÆ•Ê€¢˜ôÌÉ…9£Âã´›gÇCøF©m½HvÛµè¿ô’„¤vƒ ƒ75Ş÷îö£×š(­²ÿÛ×ù5#&n‚0Z6¸²?¬|wıw{w¹ş¿³³ûõş÷ÿãúïK¿šéÌÍ?°şKÒàZ|ŞX"ñ¬÷)ó=—Ùc‡òÚ.Gˆ½¹‹ºxL¼N\VÂëjõú—ávI±€á·CÏœÃ š„R+Y&¿kIÔñ|~Ğş‚Cúİîp„ı™üñZâ/äàb~˜‰æç ¸Oà£Óáü~&^zQK=‰‡2¯"0­L¼5¹
J¨ï1ÜeïQNg%H§äîùq%yˆJ~æûç#è©k‚Ø4…Ş™Eœ›„øí†S²68{6øu0lŸ†±±ú=i‡ıÛzI]Ën¡ù§—íÓƒnÿgè;é´µ±»»GıîYÏP}'š^õ­»FÈ_!d£Tã#¼ãD(~–¾³¡Å”ÖyÒÀh°Àk¸H^ÆâI1«r¡XÚ4ƒ¿DöÂCNÅüÃ?äºçc’¥ ä®¨¤*‹Ÿ\‘3Ş|õh+G}3<7V,5/U¹œT„.‰E±‡<€•Ï€lQ5NW#ØúhšñiR«CX;‰5B•Û A€Z4¥)Jòç)âéµ•ü€Øo×#ãİ¤æØÖâîC§–*­îZºï˜!˜«9Óch­:™,^ÇmÒ cÂÍ1ü¶œ:óxCÜxPÀz¹0ä;z9QÛõu? h„B]t‹*C\«TÖ´Ã(¿5ğg!Œ¼	b¼ÄrFÃµ¡?ù„1Aè¬‰]¥ëª…ßëŠ’ÕÁ¢Hb[Hª YxCŒHr¢#,B¥Â¸nÛ.µ]¼È\ÀÉ™$Doïx¢•ˆrÅİ¨3éHMîÁ¬o#;¢ \¬Ğ\P\Ø0<÷C…§ïÍL-qğĞ„$Ãµ8Ç«)	}*Q%êTBÒb}\­nZXt…^/ğĞùq"à‹–øØ°h¹1(	&Š¼Ød j13E< U¢ÏXKj ¼¶‹÷jGıæÁq[ ‘[~u\°y!Ä$‰è3Çt/p'’w$Râ	Ô‡ÄÃ ^@Êòn«5™ªôœ.%~—¥°t¾ÛÒ^çzÅ«+¤˜ç'o«ÄŞé4jòx±Ÿ	Y¹y47™µÉ=8ÊvG&Š–”µOÄXÜï;Ñp#_‚$gä2šJaòêB¼(ÀLĞ5ÂV_òAérÇ)cOÊ…`À„QŒû×øÌ]f à{ü˜Ñ+.F©v#°4ïÍ¤?b‘ØQ×´ğ&^Dò—Éã1àcX™YWD%³{éÒ é8i¤'F=×¹¯okˆ!‘¾j¡++¹#Ø˜K7v|¢:5å)daM%;æo±Ë˜{„%—öof{;±ÚÎAÌ`xüs³6À—<·…1N
)+©H§Šqæ¬™4M©î—õ¦z^Ö¯eE/'RT†Õ{yTá9/‡¯£?F‹+tòŒ8!I¢z¼»ï%ä)ÛFcßş©vS•˜óæÉ»Û}û»ïÖÜè'B/Ì~w+X¼QÂ½ì'ÑúËcãŠ;ˆ=Å²Öe`‡x#wÆ%2}—@áíˆéØ›uD£ä2ĞßÄÎÚ#·.U-!Ê¼)±E“r•JÓ@N=—|„^¦§éA^Y+?=Q;îÔÛÃ=UE¹ã ½bé6í'—^pÁ|sBcæ¾êö_ ngpq=–€£•Í³.ÄŒIÿi¾ÌÙ[÷¼¼Cs–‹ãìŒ¤¬Í¨ÄÄ§ÃlÅÒïŒ1¦ıùg‚¡ç°Û=dPKMğô@:#•x§|¤&mjÌCa#¤‘FQ,&£ÁY¯×í;DI;ÉeSC“¸W{Œ_ëĞá+á ™Š…ùÜ»× Vjüb],ajzWá´;ìş:@¸)n|S¸BP„ ğ"öÖ½C¾Dg&\d”‰×[wµle}”+˜³{´w?/RgÄ¿g99{)®š§@ÿŠÅ½uùË·`³yl Ñ1É–…ÙäœºÁ¨›C¿“wmÅ’Ë®D7}ßIß{H£Àê„Èà
r½GØ7ÂÀÈA”rNƒïñıc¢ÈXXÈò¥œ‡N,œÒ)Ûsªû¢>ÀJë.-æÍÙm‹²‹Ğóy„ğ7¢™´ñå‘w"wQOÍ95²-QSSoOŠ]„¨¶¯è$wôZ(r7M	›Áµ&2*'&å>O¡Ê¢^ƒÁel;)A	º¬<L«×mèb<Š
"6òèêĞÈÇi0·]Ó1¦&h˜hºö©ÑÌö-fC$eÆcCªîÃlûËÒp!8¾Ø?:ë ¯ípq_Ø}\Sä¿:i9&cEvŸÀvr²BzêWš¸C¸ÏŸâ…c½÷ Ãšø'
å}¶‹•AV ›ó--E$Dª´Ëù‰gQ˜Ô1¯Å*_Ğk°53Dmy¿'Ö:(Áaíîìç™ô²e2Íë½½×Ú‹ƒ¶v
KYĞöUHù{7ï²ıûïAˆ!oxi:5êÀ4şøZwk5|Ë¨Õ<|MÚHtâßV³ÕnktÒ>=u†í“$á/Õ)ÌsÏ!d'ß]‘²qĞí—vÀ4ès¸ÚƒÃnŸ§ƒob›¢zĞiú^Ô9uüúÌõæ”ß-5-k]³Î5ş Í"Û¢¨=cGX-VÁ.E Ïµ’øúy8wêhhRÚ2u6;İ\ÄP¿š;e‰âl‰Ï¿L,?ò éĞ˜ÍÙè°¿Éìà=÷6¼~	©¨8HİAç´Ã¥ì4ğûF¢’ Œ²°¬ÉCôi 6(Q2¥íy,'öR”î9Ö(ïnõ~—¬.yŒ¢¡LıYşT &×öÕ29²—Y””Då^-³LbêÀJ%{o.Ì$reÆãìZìûÅ\ÇN­vÓíµOè7.ßj` Ü÷Ö…fÎ-ˆIÉÇ²·~ØU×sós¥ªI[hÎHs¤½ù/È«Ğú8¡cJ<3İs^ğ_P°t$oº¡@É“ƒ´*RÉÚo’Ÿßêğë	`NÒTbck¾~Â	€¥Ÿ’õuR%Çæ‡x¢Ä’ÿ?•€dsçØÚMúB›­ºÆ %ûrâŠ·ù tNî9şeÁ¾ÿxŠ&E §ô²'œ•0æX&z¯RY™ñ	À_€`üÿè13î-¢$%ÿQüÈ 4	­Øçpi)àşó¾”CRgŸb.4^†äaX&|¾¨–Ô%Blc)/í‰ó«;øu`Èg"t ×Öó¶°ÃkKD~9NÌfÂ¥¹[ ,á€†ÆfœH‡ñ!ÏRÇ-”“ì^|€b4’üÊÎ	ø~ğ©ãh–ä«Æ´š²:qï¿s§¸«N,ºââ´¶öÑÕd¨ºTÆÿ(¡~¦Â»&İÀãuÅ•ãZ¡3¥O.~gèLŞâ»Ê+³î´uĞC°–9•TË£Ÿ•q8QKX£J>‡Ü wI88­‘X5îxÔä:ù2a’y/„Ü¿”•È²;²Je9)Å¨‚«ıººÿ!jsjŸ-ıS-”Ï‚&Üú›^gÑøÛû¶î6$Í}EıŠtc’Z @êÒ¢ J¤d¶)’‡ íî}pŠ@‘*@aª
¤h[û_öiÎ>ìËôÙ‡ÙGûmDä¥2³² ¦e÷pD *ïñ…¼„Ã{høªï¤H°ÚjDCVo¹Ó¯1ş©ÊT£5Û ãüò‡ĞúÕ¼ôkkucFD©ô+êæ¶(™pğÏ.é—ÿÅ®‚¢€îÉPRBp¬•Zp¶RÒ£j0ˆúğ `SUHƒü5ÒZ¥.Ñ¤§ ×”NpÙu”½g0Ê~nÔRqŞÖßCaÑşuBÇß’Ôwcœà*†OÊeRh¬×/‡ñ9ğ´˜iÀŞ^Ñ˜Óã}V¥Š@|¯}uØ=yFµğnW1˜övÅğ+®<ÂÉ€¹ğ›…ÁÁLÍ_Ú'WÎ|T¶geuu£^ŸÑùÆ•9i®›«Š\@¤bmTÑİRçUT7Všgï°ê³ïšƒ•B¢y9±!ÎœÊrşŞn
£ÕWÜ6un(k¨ÊM…nDéè˜rI¨`TMÔÉˆ6ˆR[x0ú€5²7Ğ®ZD:ÉŒFKì°k÷ Zkò{-–‹‘\Ô“iR¤ô2¨'ÅD†Ü˜¦5™.ZŒîÏ&ı^6šÈAò!];>ÿx5ìıÑ€¦øw8H8b	şà3ÀI_¥ı¸‘.ø÷Atq‘ÿšNÄw<^¶£q¿çÆ[ıA›ë]è†Ÿşkã”ß÷óÿ¿OBñµ8}8fÖÏF’~Ï¡u¼ø†.mÚ×<*–Vši_U’AÌ«|à%$}Ñ2àr2„sÙ˜düšrˆIpŞ»ê§}e·ßcåß	–EÇşqÆûø}E
Âaùµ¯¢ÒÑ‡àñfD#_Q¿Æ¿Âß`0 ¯  ò§PVhV|û„ú&_N3õE?†¸AO€s]o´ñÛdNèït0‰oD%ü+Â°à78¬óîO²x"şÈbo‚>v1Q ¥$)®î«ü›HšM´ƒ!Å­H‡éIû*²äGƒ!"¹1Ï ñÂÒËEÜo-n“g„QŒ:ô¹|EN³ô`‹ÑJ‹‘+‰A|©x^nŸÁÉş]Öû—ÛØyu	Ê:/çJsaÄ™<œ™æÈ¢ËJgÕ³&ˆJØæê»¤#Y}³Ñ:£Y€?swÄEüoÖzQ~å6,<³Õ-GfòÉ6éèSñp ¥	¼ÔÉ,ß¡s]É¾<DdØ Â,èÛ³:$‡mŸP7/r80SÂnˆã»şŒ$ ÇsC*ĞÓÚÏİ6ˆvíZªôWIåU†F¥²ãºë)¨”‰XÆ-nı=½Ô†Å*ÍJQßÌ›ÒŠh­ÜETàõ¹;¿1˜hßd>r{-«¤¹Û3$E3kÄŠ_‘ÎK`üÚÔ¸á O>`‹¦.õâI–v|ıüÔ;Ö¬‚j"›.]ŠƒÜéXGä×Êpğ@eÂúï}U¡™H6¿š@wÄÀ@hhBÄH=ş^tÅó}|¬İ;Àûa³‰Î¬c…€y^L]–Ûs‹·|ğµJ*†~÷4…Bûè^œD—âäcèFi79ŸÜÚËßª†‘YLÉãÙ¬gáô‚!ıáÊ/¤…lÎï­mò]€Ï8';ííæ[êËË,Lg¾,n\¤şÊıjÁô8Š&éãÍphs»Ä2JK˜+2˜Si™K°{Ï›†‹Ìm ‡'(OL.H“{QHLí bgSá›C££^g’óuwONöŞtËSz^ÁÅú.~AxñXşÄ3\zÜ¸èÌãéV¤•ÓƒÂqæÊîUŠ©ViŸ­Ù/ØO¥{?m5kE¨˜fóÏ¿ÕaZÌºå.‘÷· ½·r;r{9œŠ>G¦Ë‘áq$fûİ»‘ím¿§â¼¯Î§¦¿2Ï7èn9¹Ğó
_!ï7òRnGÖj6©úL¹`¿r¦ -³çjV§í™ßé>ğ±üëšn’rkW±»yŠ9\ÄîİClq1Z˜™èui^Ü´ªæ²½Üı¤‰¶%<:)‹·‹å@)åNu‹ÖAòÒİû1[±òk{0§t³í?wÊOºÆ†9Ô8wÍYN$.LùéÏıêÖVsÉQÆğóv4BM^±üÈ+Ãáˆ{¶DrÓµõD˜cÕğr64Ï©¼¸Ê-4ªXmŠµr@o¶&ájCpŸó®…ñú1yÕ×¢í|Ó™‚W©š>{2Ï3R‰êF%.´>·NH¹¿ƒÏ·ÿ–,·®gµü-VS¥¨VÃºÜ\Ñê%üÕÚƒµëE1ò ³bğöÅ œ 7*p‘,pHĞ³˜‡Å|ùø­\DèãZYá?˜ì[~Š¡Dƒ˜ç¨HxÜUB:fD¢¸C¢,è¯Éß×Ø`
•€léä¯­-Y•ÄùÎ¼ÒÄH»K£oˆ*:2éKMÁ´¾üëwŸVœ6C%«PlcÆ*ÓMË3"³@# Âk®+ØÊJkıp|eˆí+ÏÿŒÇÒGÍo5Ö}8ôã0™zòºşÔÿóêås¾ùÊóİñU”Äc4Á?$ğ“”ŞÀşû|Ÿ×–ãÕq‹ñ3¿ù>…M‚¹i
ã4©şÕ¿BÂ¾(K¨iøÆÁ(Te•ñ¬<óó¦£ôêySôE·t³ÇH°F§‰W˜ó‚¹êyãâÅl‹M¢Éwµ,åëÛª@6édÅ¸‡jmUzvñº.…}BÛŸ‘í”îşÓYŸÉ€<«­Â¼|&k~eQ9•jkv†™‚/k†|íÒ|%—´:|¦
Ø(/ dÓ &älŞ¶üX«>â¾Ã(œ¢AŒs>eØÈ•R¢?ÃvÒíâ§õÓBã”7Åi³|ı¨Šó°xL¼I‰ÑHÂMšf`PºäşRä	f±-*váäæ·‚#ˆşê!'"ı­F¾ıùßdäQ”m8CÎ~Îø­öfËÿÑZ_ÆÿXâ¿ÍÃ»ÊñßÖ-ÿÍşf„ùsÌÆvû‚íñ0`c~Á¹àĞ°Ú(Ôœù†!á¥Â{ğåƒzYZA¢šÏƒñæUßì¾ÜŞgßlï¡S{—Wû*Æ	º|Ê(Õßìïìvj+gá»ÖÖF{´¢B†¿İ>Şİ?ä¯ÖáİFş®{ú6â¯¶wğõ¦z|°ûæxïDdiåÉ%¬ªÆñ®g”IÉ6„Û?İWlæÏ9Ò¬h&<Ş>:éí¾úº‹¢“ß¼
¸åÆ`òá·¼^ËŸÔ/¦Yj¾êı÷!½Ä#fZÌª
¬_$èø3øŞš—¾é’¡=ÅBô‚ag¦Ô£¿ŒG¥î¬Âşd0V‡“Sµ? ºØ˜œ9e´Ì‡"À690öñúÜî(¬pØˆ×Î6B ÂhLoyòtî#NQMLSvÃ¦Ş8Æcf«È\»ÛJëÌgƒ8L5ğ/|öåóv\€Û¡şÒÔS®’æàÁÅä!C«Pö q¬ëZ»MªLt“m>Ü•V•ÅŠFOÙ4Ã¾.Õ/âéxÀâ„µ>¢Ÿ^¡8<¹a£àqgåàğ`wÅ1fæùµvñ]F8<Úf§(4+Ï	k‘oFÂPÄåAV‹uÁí9ä]}%}-Å§ŸW¸ïã€Wƒä2e|(a\åoIŠDò ÕĞŒ¡J´e%°0à¦ÕÚj¥”Ÿk8A5Çph]¼â’è6ÔB…Ò7x‚²GguÍE€_~i¢LEeqÚS­¥ˆí*Z|*ÃôÀºä­*­ı_›Í³f“}ZÓ¡îE
<í“àEl*<rM¥ÊåCq¡‡=Òæ» şÃvıïëõ?m}·f"iÁøC.Lóp~dÁpkp:B| >›v«òÈÖ•·e;)Ò	×6N84Â;“,¶ÈÊ¦{´¿wr²»ÓÛ>>Şş–*f†²ÑDå“c3ı¶J–Û‚œ©’îI^G§VxÂ8ô©´9ÜëMç&6MÂ•ú$IpƒD*)‘÷iaBĞX¨”¼ós:¥M-ÿÎ»‘—¤7HÎœ–:¿Ê¨Z‹ZŠÄ‚¼ÃøÇ¨T¯ŠIé+Š¡I'AŠLÿü=İCŠœ	¥Ò¢dhËC×¦sk#Ÿ=áö„uuj­-õ[­`XQùS¾1áºïÔ6ÔSÑ3S±hÁ>\2©ã`ÅÔKQ)±Œ%ñ%°e¤Œ9çáD!²ÁéI$¯Wa£a¼>¢+]Ëãi²;úMÅ &&ˆ˜ô“,ˆqï¹'9Úw Ş0‡„íİ¼ÄošÀÇgNÎWbR½\¤ÁÂãÜ´u˜)QdsbøyœÕ™šYşF·.ôÊË˜…áŸåüË¹/Ø
@úÚ¨š-0c7ÍÊTÈeZÎÃĞê°?JçÏÆwê¾+Ûü¨òKO$²À¸ÒQ)iå‹ºšBÕÁÇ¦ÑIF2›.(aÖµÛ‘e~ûëfFÙ315ÆĞÏ9)İÖ$«µEQ™È%‘·Êúuô}€ÖÆ»Á-éíW‚¦ôV']L³¼oéıÊÛ–Zt;çZm¬ÒS¬ã8Îä á´ûˆ-FÑIKhlsÏM$¢Ñ$„5c©T äM<M³ ê›„Ã˜£ujXf"²Š8Y]#Æ'÷ëPh•d:&_ŒlÎ>“è
¦ü2LÏÆ»pÜ‚õİh4„^|Ù†áÂÿéÌD\h ô13¡;Í!ÖiFgA~fÚêháÉa*ØÏÃAJ¢]n‡záW×Tš³÷Y½âş¾±X	ø–ÕT¨Ğ+UåJZÁF´s‚‘vĞ4nfPCvğçO7_°“ä†!JFò…ï8·;ÿF£»éˆQ¤ùHeM34€I„Nç"¶N`œ'IÜÓ4N2bı@£â–—áˆÈ(ë—ÿ‰kô<B+Œ9AX˜F <äR/§éÅ§Ö‘'1[†É9éêÚ«p·b|ğnı;ù~”ÒQøú=’Î""`Ni€é’k?ÿ²Åªáøß¦¨¤‹ÍaAub¡ô§•öLYÄb "æ¶oƒ(£ø	µ÷P¨T°U­-*QtÓ@†©Õçgôag©;‰G,€EÜ?ÓACÕ`Lq®Öo€8áu|]Ÿƒ)¶(CW„p°f'îÁÒõ‹èc}a,§KeÃU2Oyõ°ãÃ %aª&*µ6©ØöÚJ£…SàUàaw±ÈK'Úœ1ÑXE°×?sæº®¯è¹¹µŸØs^`Å)îßÏÂSM"ü'ÌJÌ}Zú,ñMÜì÷âÿ<zÒ¶ãÿl<jµ–÷?ËøïwÿşÈÿÇ×©|Á@?¯d¬w#”»(HühÁr4ó“ÏÙ½:IB4P†}İœCçHV¢#·[Ç¸9„…æÂš	uÜ˜Æ¹ßjî¥“¾#·Jñ=Ï8yê2ï*,?Gœv80aÖÄ¤A5®²êÉ…„Š±No}H9<´C¡¿Y§ñ(t®ö££8*gw6/Ç¼&Ğú 'á=ĞU•âŠa÷çŒİ¡ˆëÈí
ŒáCD³,5nyU[½>j¿Ã#·PŠV(Ä"&‚ò€h–Òòoá‘¿´uø¿y€ÌÆ5X±rH£ªt%×M%$­‡®˜¸æ•ñ’ğ¹F(tE¾º‡4÷ì.ÓŸ–ÌÆ±Él¬D&½¹«Ş>8™[/¦™]©HQÔ¹(¢a7²iÊ%lòÎÛmç[7U–HığÿÉi—næ”>™”0,Ï`Cã·òW‡½7§{|Å‹7R}½%OšF0,Í
”¾ªC*G²ÄÃcŒ‚Â1}HÍ÷Ë¿ÿò`•¦ñy‚êÔ#s·:~rixrEÒê¬²Ú*Şj³:ZklMçöâ2…ÇÜúWy@G NıBŒ4CÖ©ÑêZ5£*|9Ğ'ãHŸªÚBòe(0R›uLE%dÄµoò·ÔÆUŒh²0V,G\³^ñ¨nj- yEK‰q_½ûvI-õÁÖDóL÷mı\ÍÇ%eÜü{{ÿd÷ø`ûdï›]MqNøÏä0¯°¼ÃØM3¢¶®uJ«4h_ëŞ:¢}aÇĞm:Á’u©ÂQ´¦¼cy+yù"ŠIaŒğ`œ¾¯‰°äh(Áo£±ŞX7ƒÍƒİİŞér·]Ü™:­<xô‘í„çQ }_oNÂñ_v¾f¢³Œ÷^<}ªÁŒV3	·û´ÿçÓIûí³üíŠ{>mu—Ô#~$°_>ÓB7Ëæ>•ÖM)oa8xÈ¦)mö<E«õ…ŠÚL	g3¡‚;5ù`ÿ¤+Çˆ{ rASÆ¤“ÜÕĞ†c©§´¶Éoäòroû ÷ ÁôºhRê—*-3kgÊ‘õsà§ØşĞg¾«6yY;ˆRG'äNµx5:n‘§gÓ¤AxŞ"®yíğ^Bïó²zd€èé8âÌÑzÍ¹÷ä;Dô=«çÜ_ã:1¤Ë@6ã`0–PÄª_ş=ˆåÜX¤+[#B·Ğ¸¹¯!^ïN	Œ¾7ÌRVì"Î¨^ŸL“ËP-?ÕÀ¦Âæ'lµĞî#tf9Ş}ÊHÏ~L‡™‡`(éò™FBª²÷=œ%¼öæì_gI¸¦´dÆ”cróÃJŠ{¥*P¹%D¶ P»`ƒËSÔ¸T%Ìj®#´§!s*õ…QŒ’Ö®#R=bjUr jìGZ„ÉÏÆİ,LÍ£-~O!ìò®@ZaÃ™Î_¶¿Ùæ>]~-O¦j
 ÆmçR˜{TjSkªÍ¦jK“š5“¥S–Ë œ¤ø±âİ!ªR+æe•&•&üËÏe´™usüe:WïoûvSÈ”ö¡º ÌP±ZÄU>`Šä¹¥«L­5Á¨)5:aŸ3I 7RäpDÂÆÌÏãö‡®$Ö9 y¶ÿ5º·%.Ié¶‰ïy*yşG]Ki^çY,Å¹a'QTËÖ.~ø ß?¾#+Y³mi5;{¬¼İïe¨9Ø~µ-ÅImáÅb£öîì¡s¶º@H³Â.‚’¬½
–å’w<kuÔö÷^våùˆP{ßpÿã\rÄ$@Æ[X,Õ¨;á FÔÿQ˜%qJ^uGü'HƒÖÚ†q}m˜½Õ1øG uÍ»|ÁN»»=æšÒÛRƒTæÆêM•ŒUv–Óãı,n?«ñ¾’‹ZÅÍÒ8•·%²ƒª…Öì#bÃşŞ«İƒînFïxûí.Şx«×‡Q?§Ä5Çqâ¨Ê:ŒBÉ½"‚´zUÀ†¦ÃÖúvû`ûÍîqïÕÛ­âw°âKÚ„Ëô»_ÒÿW[Ö—û*Ù“íÍ,º-hj•G Vı^á6­õøİFGÅÕ}ìVr_6A‡ø”Ó{'GÑ6_§÷\´|fº‚u0Ê‰/ºO´‚’ZAPŠà’"\	]¾ü$jĞÌq«’óC•°_‘­ïîïnww›‚§Gc&9±ömMİ”›””sOf	Æhç8Kùˆ:Z’Îìnˆ dT•¢Òv¦ôíñóÍıYã8³Ô{¹k6¡¤(ş(¡J ŞøÒ¤r†ÿ-mQû-%¤™?­â‚»@©^d)ÃnsxjzqÒ•)´ñJ.Ql¼¼şĞ–©x4w©jëL6ÂdvA";øºD/Áx„à‹ bÁ4“~-ì!Ë AD9YuHâ™Qù\ê)y_æAovOøMßk80D1<y-cbiç…ËÚÀ‹Îªß‚ôèË ¢/èÁ0K–¬sQªYõz<ŒA4#ëpXv³0/˜ÂörÎâYıÂ_$lÁhÍ§¦öéqFdûJbã`zC£mãbÔ§h2qF¸Œ…å×~Tï5³›ò'{¾/D³ÏU9ñäÉV?¾*#ılŞX8—Ñ¼LÒsÛ9Tå«ônºM«Ä‰õ>¶XöÛãì$‰.ÍësëúÇ>ŞßVI¤-G­TÂMC,¶ÌÂ]•'t½hÜ>Œ¼ÉšYicáZ¥Õµ*6jyñ‘ÚbœÑfC=sŒõÍ&GL\z¡‘0”0b4¼L§(ĞrP2ıRa‡ğ™
â«@uúåìÛí7{(“lõövvÿÚYgU†&a‚GRãİ¯4#ã&ÆØÍ~ùGÅhµBéf"j‚Ã ù´-Iâá+Æğ<É•Ø€“íc!¢ªn‘³È~¯.Ds15ºXúÿdÆ[S€3^iÂ&»æ–46¤˜¡mÖ µYµK6¨Ü|¡Q!4¼ŒnAÑğ}ÀƒşÁ´G—ã`Øf«ğÎÑa’L'ÙšCÑ¤¿ï	¹¡Ğ<¦OÇ?D#±}­÷Ö8ºró¡<Øùz1Š¶4Åj5ã®›Æ¹ìfdcQÛj®gİ¼›*UWJF­óƒ§·°Çåïõ{ÜÂ„=vRH›©9ÇÖÂš©¸2?Ég“Ád¹RáÕ;ÅÅ4;{° %3: v0Qİ}­|¹P«ë¬»÷fïà¸WÒ"ß¾1ŞÕqôæ’Ü‘lN»
†)ã+Ò3Njã(ÓVéŒ¼ÈfV¥Ó
¤ šWÛõM{®¸F"ı
€“¢O]¯ûIûQ£İxä»)µ†ó—q|9 AIÒ&Pbœ"ŞßUz¢<NØ€ùt–ÃßñË3ı†F:©áôQÎ¹ó·©ÈÒè°+é£œ6.şb?ËEÕ@"AnÎ]ÜŸÏ#”^)]Ş«ÜÀÑ÷'Ö@€í·ñn†B¬üúö%•©îE˜3ıf( mLo^ùÑ0DIÿ:ˆ²‡ê4†W]g¾èVIqñ›º2ÆÒ¡*/“Ñ…3dc(Ñ>Œ…Fï§XÓ­Ó
âø]jÎo	3u§¹Òf+7qcšïÛíÚ7»ÇÄ¾Z®.°‡ƒœ½kjh{O4¾‡ß)B·ˆ+ ¯q˜³öå¾7»'~i6ŠßSà]ş²©^¼<İÛ³¥‡q¦MÎâÅŸÔvÓÃ8u 9§>Áá;sÉİ`ÔÎ÷ƒyUiÙ¼ÄAò!Ìzü‚õ¢‚É‡!¿ %ÒœÑbâÛ½}ÀlHh×9Š«In.{WÌÆ´GdNÆz^Äd:Nì"@seV[xR¤FıH¹(‹m;İcy[Şp ]tüqV	ÄV•­r¥Ê±òñ[e˜ZÒÚÎeC„W-sq¢™‘!T›o1•ã“÷3£·ú4bèG†ölnçf§à7Iò¢{‹úÃ4qVïÆHV*™©ú{UäÅ=3¹Çá$ˆ`°–ÌTd°¤ÖãÌUñS_ÿ¥±Im­û·ùÇ/•ö¤ÊN/7İ6xl{¨]í­tAĞ†GèŞ/­·Âvœ—u8ŞÇŠ0iÂ<)Ï9’Pz¹PË £ĞÃ‚Ä#B´N¼Wäßh«ê“µ¬xQ"d‰âgv!–Y?í4FP+{/üãv&æz¬]}>Ë¿²úqi7çæ+	•&cÊrà™íÁ`@‹9‹™Œùˆ'F0ñ:è2Ë88.¬0ú]”=9d¥/Ö˜n>ÅÍÿÂA/¡W¤@#<«Òë$HĞÇeİ¯lyVúæa•¥¿üC:ß³½…QÏŠ0&xvFÊRnÖˆƒš'ü\ÈÒN³ú‚;ˆõßãï5VÕ
yË_…C©¢‚ÄFA1LÄ±éğ,,SDU>+ ŒÙCG¯h¬&ƒ6ğ(Ø¬ Ö—`!Gµì%	Ú¦F•ÅL(o°.HÖ«uaÂè:ËCS˜ñohÌqHQÌ{ÿ1æ‚aôC HLÖ[-Òğç*Æ„A±rĞ~Ğ¥ŒÙ½BxÍr$nØ`RL x@ı}	´… „"ä‰„Â$EÂRš¿•T+Õ}šíã©+£ög-"½ùFÿ•U*€onÃj„LÀìè#ı_şQì-üÑ"µ‚Ö€Şó‡Æ(Ciˆ`Q\? À3<»!€ôšœí±%0´“t½ŞzoİráÊ»º`nV…æäá’°D(º][6­¶Ü²1›ò|ªj×ªŸ‰çm	sZµ³²•‰môG†û0W•ßÙØ™áB§^çX‹EDûWÁÄÃåg§Ø8nô)'÷‡T’„5¾Ÿä ûó³:_|â&°bE’"İ’œéÕ’Óğí	uÛ(!LºÓéØBYêo1¹¦-”’Ñå#h†ÒÒØ;	ş+MZ©¼Dñš^lKƒ.SÄİªJ ì]övÈî£, Œ´‘İŞy™Å§ƒğÊ#‚‹²gq?¾†¬¹µïáõ8L@D—V¾ÕEd6Ã¨†‡r£+‹vÇæ	’f,»ŠL‰K]­[‹]ZZÁ¥»1á¤Z<¼Ô‰{¡/Èïı/	¢ôaÈ‚7×*YĞÊ°y+f7ƒçş¢¤-l•ì¼AEIì~¥+ÃœJ®ßy)ªoJî•lHÜ*é6¼½tk»f]²9ÏâßÕ¹\Jéà-%õfŠ@N|…u-Àª7Ó©¾4»'DÓz27-rl53£“İÃó[ìf>Ñíà~K3×ªØ}àkş$½Ä—?ÖMVG?êçãxó±GÏ"ÁëNÎı‹š;ïTÛ§İŸoò yz²ëŠñ°yø“Å›*Á Màu2u=] 3Lo*/ãíÑşŞ«½“Şö«(£÷öpgàÕ xt2ØùáZl©°Ê¿ÁÉ
Ùˆ<^±XJÚáMŞÔÎ©q}Ö²j|'æH|Á Aş#:©Ã´¬d†J%GL‰èÈİk-­”/·Q
7í6\»!ÙÔ¡—Œ<{,ìtÜ¨şr#ñÈ0¡g¨»«–ø	{.a¡ji]ÚEV…!‚2‚$
ĞØ‚ Ñ;Ê[¼}sroYFl›]CQeœwcŞ`;1ô@šÅGBU:c#³¶1¯d×rn…mc–y]¾Hâ4{%Âv×òéøo‚IB}Ú0üMâÿ<yô¨ÿ¿oÚñÖŸl,ñß–øo·Å+‹÷Ów¢¸qrÏŠ›Ør¼Î†‚ÍÅ3i¦v}}İ¸Š®‚˜Û“AöÆyÒÀY¢ÙÅ°?u^[à+EÙñ¸íë*jP|&T8|&¯´òö¬®1¥"èOÁ6¼bˆù	¼ïğíÑñîÑşß(’¼D>ì}{x¼Ó}G__áw’”1giŠ:‡ö€ÀuŸ	ú®kö7u8”¢y¯ø[‚I„~ ÂÄ
ÍY—üı“+ÊHÛ«Œè²ÌĞÖO¬Óaõì;ÍTëÆi1¸Y§ş-^ÈbËà¸P¯‹ìšHİÈ¸bàBVÍÊ†”éÏÏQ¿UFóöµğ<²üŸ
xÂšLÒÏŒÿÙn=Ù|\ÀÿÜ\_òÿ%ÿ¿3şç†ÿóä}ˆAYsJ_Ô¹“;ÆJ¹ ¥Ÿ'ä[®"(Zã2ÊIÚÀƒA~H•HšÊë ]Oı<§!ö¼ÎGØE”¤ÙÌÄŠV7ÀOö^£—úÁùUÍqœE7uDJ_ó”ú¡ÃÃd•µWKI`H^¡>™Î’ÿ#Wcøk’”…:Z³à.=Õãí½¿³C¶ıöåŞîÁÉ.Ÿ,Oâx¬~ÎÓıÉ,î7šYİî¯;oz;Û'Ûè{Ğíhá{Ÿixùƒ‚YˆöÒ÷œŠŸ–ˆõòÛİıW8>¦™ÇôûdR¶S£`ÒDÕ?ËÎ²£ø:LÈCu'Gáa¥GI€NÉ?”Ò[óx¸ª£{tDuŸeìÚŸ(>8%¨(ÖzÜXßdû'İÂ‹§ö~'üÈ^:ŸRéĞ9ä ìõñ!ÉÁNÇ¿#Âª|-Üÿñ&@CÒS#j<—uÚSèUg]Ï¢‚Ù/RşÛ¯Qu‡ëÌ|^Àõ[¹˜ôWô.ô=JÖ+j,ŠÈEĞZä¾&ƒœİ¯O`]~\¢P–Ôƒ@<^£XŒ‡G'ZëhŸÌÓÇaÖèOƒÆôb”èœ'Õ@O6Zí§:E/î™€á€[Ô0kàR*Ù]}P€p?îNRßÜØØxò§ÇÜ­Dj|rŸ)tY?Wo,ªNÒzz®çº][¤]÷˜àt´r?‰Æ}|ú¸÷x³Ğ6ò¹kfå5«Ê@­FË÷,7™cÚÕ³ıÔW¤Z4fï ÍX/‹†éXHc™ Hê¶Êî¬´Ÿ`²Ş“9p.k^)êº³6«,bÊÆtk–Í>óö§ºùéÖ,Ã|ÌÍ3á·Ü±~r›UYû–enoÖQfÎ>³›mêçl„Ù«Ïëõ¡Î—Nİég ÉvØı4Š˜ıÒö(I`û	˜=š1”:2@Î.£ìıôœÃ÷£	†	f"+2Qì·È	ñ
¨(85tøvë2¢c"*˜éz{;»2ÕHxô˜ÆKJñáÁ‡z*T±ø Cóñ²p»éÂşd”¨µr'¼"9í(‰¿ûºTU±(º¢B8ıPïlš`Ğhq±/owN{{'»oôn9«Lğ®ŠŒR­¨ˆ´²ø—˜ZÅÂ6-â>æsqùØYá¯W<Í¡ÚùKÒâ»uæÆ‹>İª²–öÄx¨jâïV<Í×<§/¹L022Â6]úñ¤0mò—°ˆ²:RÛU|ªCÊœ«ğ=İ×¶Ûf-Ä¼Ô£Ää&¤Lß;ŞİŞ§Rï×ëi$a0T…	oò| $Oe©‘J¢ó)'Š93F=¥Îò"9tÑœ(à‰iõ‘ˆàœ|ó„ıì±ıºãË°~~næl6ÏÍŞ'Våüï¹•\àLf1†{Zi¬ĞEXï!‹Ïáçü>ÇÈ¦,Ã/Ã¨W!K0©çÆöÑFõjÜ¸HÂp@!*<jŠ¦6³à2mÚÍ…·£8¦$ŞFÿâÒo‘Ü
A lšò¨E{Úïä·…‘¥ñ ­?hõbŠ5GIj&±DœL*	¿P	­ÆÓå¬xi[’0µòø°Ûím¿UÇ]úX¡PKÜ¢/âé‹¼•g¯N¥ü„Ö‡Jš’ÎD$õ×tÔ8~ûÕkcÆ£• ¬õdtõ$ğ™<=ï¾ŞûkÏ³+k^Uk¦w6ná¶q ­…ÚWÒw¾[¢Y½ÎwlØ§:è/5Ô'üÚx>&”Ô{çI4¸Î™]LÄ#ş¤‡E5†“€ÌpSç7»u—ëÚ¿Q‘.Èas[óï«ÉâgŠ?¸SƒËöbpá¢(B½Ğ¯?T/úCEÚ÷Şı&Õãİ7»eßlï!÷èzŞ·Ç=C¬ğñ‰¡ƒGe1¹1–9ñDb½÷÷¶–èüc«U„W ï_f€Y©_pğ˜DÏ§ÚÃ~%q[ş‚5r·ò·³4“ßƒìƒöæò}¿.kÂ}ãr8Í6òoôÜ÷rÚ?
ÇSDhcéôüŠ+Ù(ø2>½ Qc@À`È”C3LÇI0ydà’{08g—ğ¢UB<ØÅšç'6ReÎ)è]òzöá)Jş½)Ò {1ôá˜4Ñ k°q<®c}QX=;î©@`ÒïŞ}çy¥6LnK¥qW±^º~Nö€Ä¾İŞƒ“½ç‚G)‹å°+	`·“m-ÊvéàƒMCÎı÷¨×ùw$”b¾Ãà<ªo6şÔœ$!’bõçZ”‰KTÃLÚÊuOØW»ĞÌãî½h‹EÙwë"ß+ÍnÎë¢.5ÍÙ³W>ã¦-¥3Éjøÿ³šshTûKMsjÎÒ‹Z]Ñt®ØŠˆÛçI0†ó
ğıè#pü”ú
…¹•¾ü]‰˜¿„Ãí«ò·š±}ÇYJœe¥± ²ÊïøÅ¶ÛÁBV®Ø¯öóµZ÷à»¿p(m7›¨#\3ÙÍ‰Z;ÿÑIömzºb]bÇSN5EdAvS6Æa´Î•êlAxìMa¤õ/íuº9€¿ÁhğxşW×Ş–™Èû7èÆ¦Ù¬·z”Ù0H+¿KkĞFœ·¦·f¹{ı÷ø€„Bæ ñ…°åÚXó|ÆÒ›q||Æ¯pL³‡³,†ö³üîê]@Ø‚éw¹w=]|îì~zO¬W¼‚<ó)FmVoŸÉ+¤<Yo^ÅÌDÆ§k5tËHÃÎ(LşOYK±O¼ÙºÉLi…:§c)€Æ˜â:ïçÿ˜_f~SVßIÌ¾Ÿ¦™2í¥j/¤E&[%œ0¼OGÈH'Å¬à*ˆ†xO@[›ß2š=ÒĞ¾á`Çü5jÁò¹éQY-Çd¥¤4¤¨pèåUHª™Ê€‹³ºPéøx>[ßz\FsÈ°‹Q¨0·?X¼µÈÈ˜òµòÌZ+v[XaåiÏm¼¥–ãW‡İ-µ0êR¯Nß¾Ü=¶k m,ÍBK°ƒ½b½ÑzÜhÉÊğ®Qtl|6ÎûrgX‡ª›wıçÿd/oè’·˜/î vPT|>MÉŠd¢¢S<d‘0*‰R¦ğ9àiÆq;b„ô8—(<ƒ/ähÿülïSa(ú!:aŞèÙi¢İVª/w2î–=ƒíq®ı¯áoğyíÑò«`ÿÛj?ZÚ-í¿æØİÙ L#õ»Ù€qÓşTÀğ8ƒ?“‰1Y}{_~%n^á}ºO×Ñx,ZŸõòÇÒwÿbs…Ÿ<Ë­·Ü•­‰(èñ¸¢I4ğ"y«¼E2¡¼­†¡¹wZx©»h^:ÀrõŸ¨Ğ«öŒ£şa7ÇµÎ<OÇµğ¥82éÑ¤c‚
ÿ‚²£f?‘Şş¼ÈQpõ{Lª€ 5HhV]gê)é+•j‹XwN´­?çxÎŒU7è©ÑrH»iãİÁ³GôL˜™ÀïÇê·²§OK©-ôbÖÖ[º§ğ†Qo¢Íó ­Îó¿³1›üšÕ›Ş Y4f¦¼¬\™o4lQ²ˆls(&rÓz=å><º§—p§O.ÓÎjcî™¨yø¢€`UuXp‚˜Di9›ËSÆÉ•ïEÌ«l”ïğ]tØ}‘wœv«cSzÜŠ‰3*ŞÜ{–gu3'Îa< VĞáâN¥å0::€R€àI×ÕAÎæŠê”ge…<«I|­ıäìutÌYÔ§ædÒÿøX€¨˜PA½‚’‡R­ipØ& º©Ï74‡cVO/ŠŞ¢VÜf–Áªds!$6)Œ|ûK°ãŒ9ZaÙO~ízSt‹
N®ìÀK¨¼<@K8†r$ÜÑ¤dzˆ7Ú•øâˆJFdbî8
¡ˆŸ6Ğ{ğš¯LéYW©k'CqMgˆü@k¬S¼é¸*ÄœÆºÅóÉ¼`ÒÎ2D3aÌ®–§À6‰ãL]`›€õäo&P1n(:CA¿Ä“ßã§(ÏvAÕüÄ­€t¹ÿÍv¡6ø‘²¥kõ§ÒÑõ‚‹ë91³	Õ…â¬<P¶¹ÊËcIHä»u€‘‚_ş÷  `‡6ø„Üz“`N|m&á¡jhàQeb;°s nÃ_ä˜a}ñe[!ü`QxzÌÏ¢‚uçeuªÄ…Dï”=zşÀa,‚Œ1:ïÂ^…°©ªÎ™{ÀÃ‡«ùtyóüM`ÇuÆÛ†ä8°ù6)‡NVdÓ¥hç>òıÃ ¡ê¾‰¥!ˆ÷ƒ”1’Ì½UEmÑ?å÷eñğ¿“I*äm:WM•JJ9}{. ‡­ÜïÜî ›ßÃ<61,	ğ:»‹FUÛïÜI–ïÙí¡à·¾¥úwŠM”®—ş”4<»ñ™%]0¿EI‹Ã'Ş`ÕJ…;î•Ëb¬ö ná\r?'0tƒÈçÇåeûÿTë-y8Ç¡•¤£¸Ôn#ôôàgé”ˆà\«âÆX:¬i(³h6Ğø˜Ç©·ÈÇÑWÈË·íÇ°?üô“üõ$o \Û ­lËŠäº!qÅ!õ‰D
ä`ª"gÄeµ6«m²Úc;\ï™»Â<‰ÀÑí“0íf	Ú]Uµ"ƒ„T€Ó!é ¦c<ÕfÁ˜BBŒÑƒy""w‹äöÅ4P(°…J¥â.
¹õ—¦¯È°µÂ‚¯´ÍT“B= ‘È½ÄdNıF3»àº¶æÃu‰	™4n ;–¼§X¦É\ï^$‰Âê(öSÓ(Ó(¹zªD8WOm¼³®h8*6/u2ÓRnêd§‚g·¶PFÌİ"ÉrqYĞ°èd3Û¦xeŞN˜Ó]Î+ÁÚùFd/°X•ü-J³vBÖmGÿ7í…ê¿aºû˜İšò,Ô.î¹Fif_äLW¹b$äø÷Øöj…XxšëÂ/ê ´¬RÓf-‘$ÌĞ¥“hõ‹ÚŸş1ôÆá%B]C`”À4E@µ—¯<ğ^ƒœb(©|‡\©­Wµg”$U)ñBÌ_cE‹—ĞÄ'™ Ã&#VRşŞE‚E|¡ÉŠ…²¸¸-ë¡Ü0úŞAÿßhâ~ÚüMë˜ƒÿ‚ëş§Õ‚?ìÑòşçsÍ¿ üj:iŒŸÿa}æÛšÿGO–÷ŸåşÏ2èâÔ{ŞóÉ¯‚·eÏÃÑm¤ïŸ7á]K38O/êäúÖ'í0rÍ[UîYò®~”ù¬OÀ\ìyÀŞ'áEnL‡ª;,³Åş‹·âÇófğ¢Á˜7§EA¿N²”¥ õ¤¤iÇóŒ‰§}ÈÎ§?xÂ)w|ù¢^Ş_QáöŞó&Œˆ·û‘Ì°DC¥p‘Ä#öÀÙª^§Ó*+9‰Y4Ë(è™jä™$á‹
^Ï²’^c‚ÅË.X15t!U÷s‘^´àçt²@;¤E‰c +8úú¡FßÑğ2+[ÇŒfˆ8ñB(+kÇÛ¦¼4,hqC'ªêšÏ; O&„ûãì…TtPI$zvŸ£¨½™«NTäqÜ#etCí¬äQÔ5iÍqî0'Z'¿é©¸çEdpÓ=ŒN¾@Ù¯°âÌí¿-?ÿ?BşJÿíÎ wÿŸ´7–òÿgå}ÎùßXß°åÿÍõ%şÛç™ÿ3%¿	º1¢²ÚÀlœ|e
îO™ful{zÉZO}F¨RmøK;²L5¢ƒËĞ÷İ¯ØÁöÛ]Ï4Õ=SI³ØÚÌ)Kwïàğ¨»×õÌÖœ'†‚ˆÙß]¼ä7…gÇßÑÏÃ#üÙÅß˜ƒyp¢+‘3/—ÒXY7êôM§UšUéÖU«Îêg\æ,>áªAãy.*5u´ñœ¬»©+0v;»İWÇ{ÔXÏ8ÚÑYmóPÀFcİúá0ú 2ÁÑÉCœD.á™Ì¶n~¨Œù‰ËÒ¦Í…1ª³®n¤´ñ–¼aÙ·äKãëYãÅ„>—	éÿš‹Ñ÷¬¡d¬¢’C‹t7šç8ƒ<V™mÓ¯çƒË¨*2¦';	|¬'3¦Ó–x`èyø|É	…\)H¹J}?K˜Fº0KÆÍ1ä°™*Fş»Ÿ~z'|Çd“¤˜Ší‘]#qp›}ùETz*Lõ©kÂ@ßµXúõE,ôYó%ÇNSNqĞñÛ@am(@(B0¾a„Û#îû­%ºÊƒàÈGıx:ÎX*Uîo=ÔÀ{<s®u‰`k´Å™Òl­ÈGƒ‡]o›k¡Í†Á½“¼™xP÷0)]í3ôe~ÈR¾C3(<–bÌ³xÌWÛéÉW‡ÇÍ·: ½¸×ú×÷q6‚sB­yËóÀ)ù¿?€VúÊØûş”¿èµlüßÍG7—òßçÑÿÊM¶šxÄDœ²lxäõ@²¡Â½XBB‚ 	°a‡r‹ó^@KìD¤#()@e|oÒ—r»ûô™Wyáeåù0zñjˆ!›i‡Í¡×¸‚Gˆ.Ï0%éiP)‚8}ÌÃµ-U²†–ÆYŸä|„IÚÌn=w(@Ø´¿² ÔVs=Ş1&l'¾ã`ÀòæßC[%ZœßRØûêÅı–‡=áâBa4x§7a®Ä”½‰‘Üö‹=&ôÔ‡“pŒ4&#ÏÊµ½Ó13fÕÜ<5¥—(éy)f¼¢1E‚·×Á»ôàvS|{Vİ¦?ç½kÚçUö{«Ògµï>uå3ëÕHq–«rïQÍû{(ÁØºØJå3]äûÅ\­wíåéîŠó"7ú§•ÿd,`8h„éıJså¿ÍGı_{yÿÿ{Üÿs:`èŸºÄ¿hŒğ¼B	tÓıù5»ƒŒüaqK9Ÿ‚„‡x1Ï»"Ç\V‡¯ÂÑ9ÔĞ~ü‘k.[òÁî·]ƒóNÕ2—Kï –Âjëëw›à``ufŒ›Â	!Ë0­ª¿ú)‚Æ4ØÚ»¦}2d Î)éˆ=›ca4k0`«YŒÓI RA™¢š1¶Òé fÁ ä :®§zîƒøÚœŒµƒ!‰ÔİãöÑI}ar¶:Œû¹¯è%q§.Á!µ@§A™øóú<aDÖ>t–X]HÙ_`È[-ÖÕŸŞ`øÓ”¶¤ HòTÏwÌñA§cv= 	Ğl„Àà ãKİz0í#é¥¼Ò6Åw.m+"õ¥Õ†—İĞ³Ê1â|i>Dy•ï<aŒa?ø*R ów.}IşN„(“¼ŞûëîN	RLÚ0¤¢•“úèCÿâ’KÅ´#‹Ç8Úy}ª“Ş<Ñ0ÊnÜ™h08M>y‰òA=¨™–d–äqşë†“Œ/Ì§eërV‡µÅwz¼¯X¡ºíé%î¦­?İaı#…B)õ²%¼iĞ­¡Ö•â¬ıÔ•ˆ{´Ò~Î8>¼êo´r‹1Æs‹Äæ‡‹×hÃ¤$ö<O—´pš.R#«S’Éä¡–&‘Ôw9’´N· A¨–XñÀ .L¬İø'#¾`¤ú|9Øã]œÑ–6£wP(f•Z±¦·ÏÈk…¦5QR&àèöùàÌÈ@‘ë‚¥!àÕ“¦˜ïÛåƒÚùtÂkë/øMÄ«ı=öùŞe˜Ú;œµû>ş‚è&?›«³™AÑ·'	mg}¢]ó¬±o8•Nsş=ıùÂEë0CoƒÖZ×(aaR8å.ÔÆ˜!LÙºü²É`ĞÁ4/öànO!·t'ßÈècŠÅŞa¼€ÿÕ¾/
 ƒx;ŠÑğÃ·Êa22jùç9ä÷ÿ÷-õ/,ÿ?ZßxdÉÿmü³”ÿ?ÃçÁƒ/ÇçédKÿ_·V[kü!­lãa—dÅ<ÅÿñUš,’‘Yõ?xày |C®"•¤0æõÜ3YW)pföà4<˜_‘qÖKñğ’ÜéúUqïò7â66u«r]nuïj˜Òò•¾’»™Jà±ù­]géªÄĞ5¹à…|±ëÖüjÆHUÚ‹Ï}ZLX&´¥ÿ£	Ù	q}ouÀE¤ås«’¶ßZÃ%(jşj(£=M‰™ÆÌ‚,ªZ±´@ƒ@Š‰¹UGY•‘%¶e%¹ˆ™§™a Â®æü……´%µ½¥f"l­d–#·e„Ìm]â²×z®±¥*'%êa«)ÊÅ=îÂ4¥,÷L<É»¶¿Ä¢…™CÏrşD6"óG]ZÁÈšEÆ¼â»ÄXõ”ØÇ8ÉN¶¥{Ëqæ64e=™»´ÿÒÄÆMãht³ ÿl±ÛæË·i§­PİD§aUÜf‹§¬ŒEuzÔeø8Ğõ=KqĞ0»®_™ÂBÖ@0"3b'[Ú ı—±ÿ‰"1¢'.Ÿ´JşÏéÿ¹ißÿ<jo´–ç¿Ïsÿs˜7£©Ùêß¦aèª¡*•8ç	Ş>#.•!+.6B©e†Üöğ"ãkÔ$PZ$Jƒı Š¡Ë[–İLÂ¿ç+£„?&ÖÅŒjl•äE…L³‰Ò, ¯½ó™óa|.l]šÇ»Û;owì}uÀi÷h
Cè°Q?‚"nr¸ãâUQuO+ÌÕÉg*£™€F†kÇ¸ö«ÉD€ä—A
ıç;ÁVŒ,DÙà¥ÛÖïøE«QE&-«VI7ÊíïêOëğö'L”ÔjıüŸVÚVËHlÔ*Õ#®Ríràr1é«şöó?ŒbOIå&šÄÈD÷A´«ĞÙ+(İ&Aj‚DFv±—óÛ+İü—¶hš¤ˆîµ¢‡QD„Eš›Uö²•Ô·ÒxˆHéæOÌr.zauøJuP»k
ÁD;*im“ê
‰>¬(„6qõ§+t«xWTÔUšLEH-µÄhóNË»Híş¦KÀDéÆUA®W4RŒo8.%ÂMFƒ¦È(5”rBJè²ÔºŒâ1ï+<•å&†Š¨A„}spÚ¢µ_<“¥¡Ò¡Î…á˜èNf7í¹±İÄJ,X)ûÓfV $c'5ùá 4rÒOŒÊÌÂ5!}fZ„üHÈÃƒ&¬úJ—¦-v£ _Lñê¶Œgæª­ßMó´‚’Ñq›Ø-…¤ågùY~–ŸågùY~–ŸågùY~–ŸågùY~–ŸågùY~–ŸågùY~–ŸågùY~–ŸågùùƒşÁ±/^  