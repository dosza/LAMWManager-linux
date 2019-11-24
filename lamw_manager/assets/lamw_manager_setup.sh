#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2873157905"
MD5="8ebc4da5f1c60dfe672406d34c72d2d9"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20446"
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
	echo Uncompressed size: 124 KB
	echo Compression: gzip
	echo Date of packaging: Sun Nov 24 18:17:08 -03 2019
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
	echo OLDUSIZE=124
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
	MS_Printf "About to extract 124 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 124; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (124 KB)" >&2
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
‹ TóÚ]ì<ÛvÛ8’y¿M©OâtS”|K·=ìYE–ulK+ÉIz’J„dÆÉ!HÙn÷_öìÃ|À|B~l« ^@Š²twfv6z°D P(êĞuıÑşiÀçÙÎ~7Ÿí4äïäó¨¹µ³»»ó¬¹³¹ı¨Ñllní<";¾À'b¡òÈ2]÷ú¸ûúÿ~êºc..ÇÓ5ç4ø§ìÿöÖöNaÿ7w7·‘Æ×ıÿÃ?Õoô‰íê“+UíşT•ê™k/iÀlË´(™Q‹¦Càç‰zä(ğóÈ“–³0±…JµíE£{d8µ©;¥¤í-üº”ê+Dä¹{¤Qßªo)Õ±Gš½¹£o6š?BeÓÀöC„S¢ÊÒ®›ßBâÍH½S/ øû¸uò¦ç@u2:0˜ä20}ŸdæDÅ1\‡4ÛQrêì\ı"œTè•ïíçgGF#yl††Z{ª&¸˜ñÉÑ`Ü=ZÇÇÆ
É‚æ"x»7èjÚ~6ìŒû/;o:íl®Îé¨3zãÎ›î(knÃ,ãç­áCE¹JQ ÔhX©Q Şè4ô‚ë"ßa›ªØ3ò–h°oµşë½V\‹JŞïãÎ¹J¥œ|ó;Œ®¨5ÖuÜä¿ÍÙÉ§·D™ÙÊz×rƒKWH5soÍÔ[,<Wcç”o‚bì¾aèN`[”)Ğ4¢ÿĞv({²qC”JÂ+=\øzº>õÜğ
YE‚Åz}XÕ-LØ>§Ók°ï!ö,²<² ‹	lÂÎºlí@R™š!Ñi8ÕçùäodP_‹l?İ¢Kİ'¦ºögòAÉnÂb*«b×T*‚:>÷¡cÎŸÖ¥—ı0 gĞÌoª 
?m×2j›°ÃÓsduCMhQk	ˆZNQ9Aé4Í¬ë\í¿t=E«ß’*€/€Å$ô,xÈˆ;€³á7X=¡¼éÊ2¾ó‚¨ù4E™Óğ9¨Sûä€/[)àÒÌ4¡²ª†µô7Ñ®Ôt¶AäæuˆâÛõÄ¢33rÂ@ZÙóNÍ&>µD)kOS¥’u¾öçµ³ö=Çmxi‡bFx¾°C>§A¯è”PwIºÃşqë£ÿ oZg£½AwmÙoòùô	®’ZÎ²ÙË…É(c@8"Ø]B¯ìÔëuu? ¦•røuâ*"wŠNA‹ëÇó•ÆRŠ:ÂEr’*•L1ÈÔ¤@¬ÄM±ln
+é¶òÆ˜Ø…i»)¥
>q²ºõ|àyaÁ}*•LcUcÎ÷IÔ©‰2ç!òüVùc“Ù)'\‘•Šlaœ|XßŠš´±äÑ×Ïúø¼ph»s2„88¤V=¼
ÿ€øw{{mş·¹ù¬ÿo=Û}ö5şÿŸŞ%Ú¤ˆÑœMÚS*MÒóÁóñ mÎ#4Yù¥2òH?ò¡ßsÃ†±‹éZ0¾’O-Å€È· Fø×'	x)ôWÅübú_GÇ ÷ïÉÿ›› óyıßn6¾êÿ¿gş_­’Ñ‹îv;¾!jë´F]ŒØ~!íŞéa÷èlĞ9 “ë|”#½ˆ,Ìknc ğ"^B˜có(,¸şLàÙt!“„Ø' Ï²g6ä$Ì0>nB‰ã±°/¬æ÷¾0ÕÉJ1† <òëAä*UyHáM£-êØÃBF“ÉëÂ¼ Œ:3bó‰gdx0  èšNŒŒAtLg{ä<}¶§ëÉ°ºíé_¦¨ dõ9«y§½Ó Ÿ!båÈò+ßthÏÍ„	ŒWQfvÀ`s¦Óˆg:8S'ï4‚Ã°xoú¼Î¢)y«v_­ò—´ÿ¼äğ/Vÿo6w¿Öÿ¿äşO±ğªM"Û±hPgç_0ş‡ÍŞ^ñÿ›Ï¾úÿ¯õÿÏ¬ÿ7õÍ­uõÿ¢ ?ğ $L=74!õ!D#¾íà@ş9uiÀÃ@ˆb»àñ¨ 58Y>#:iµí»Ûi¹VàÙÖrìJÕ¢!†&Ä(¸ÿÇ#–Gfş4NãLË$®Gúm‚õFËrËÿØæÒ¦¼Xi.&6¼ öÛXw®(Ç›âÚ,Ï€FíIZ	¶‹hİ¥á–‡òS8`=/¬>UÏ&‘F¤ùC]}
€iËŸc—^#0vBÆË®ûû|Ø±íFWäb(Òüñá#)3§JJN3#c«Ş¨7òxÎÇcX¨¡&[ºõY@!²ƒ(Æ©{Á›tà¢šs¦Ô¡€x¼5nŒª„	°Œ»ÏÇıÖè…¡êtÇà@U•ÀÚ‡G	ò@4NZ}:›Q:ÇÖ°c¨wNüª3v{§F¼Ä‘¥×¤‘jÆuD±ı;riûAKÚ¾sIĞ‹İé	H²Œ«vÇ i
Š6w£•u¥ş*‚ÒÌ•5ÃJ§\ÎMPø!ÀE—’×±ï‰7	ì¹~ühf ]ò”! Ñ‚ Á„Ù‹ÉÇ8öÔãsWÜhAnï™Ùü‹8.ÑØİ‹_üérÔKø½½bŸ1U¼6şWÒ]	ÓÉKT—Î›˜Ës{zÜ^\€ªh2¶¸R®ÖrƒTbU]=;)Ç\ä¨¶nª‡Íõ°e :\¿(Ò+Uñ¦ç	Ü“qQ…|—VHùé…²
‡'Hx„N§ÎN_’Ôpûs¬å@²¢mÖÚ\ƒš‚Wáj7+mß¾ÓŞæPÇG11Ø_ºıøÈtû¸{zöfü¢wÒá‚ÁÎMˆNay, é0_ZG·Ü8–Ìx[—÷ªúXŸÿª–¬.ÄÒéS¹¼Y]èm	6<Úˆåº„Z@DUô”°n¥)Oræj«+@Bcéã^PY?
 ¹X¼x±0Š	W”çØÔÆ8§,Ä)ï¹éÎivn¿²P±[¤R²îJkd
½¯xÀi°œÌ$µeÒîŸG­ÁQgd˜`{ı‘¡jâ;Ç*éÓ~Q‘ö 7
À¶P¯µˆÖ½:ì¿ÚRI"|ıAç°ûÆÀ©.Tùrcp¥P&qKª"•ìN‚$½³A»#8*ix‘k†èµ¢`£ñ“„|øÕö–¨ı¾•tï}zµË}dÙy:·5âpñ˜ö¢w{h.Ò	/Ø#‡€–Iû¯ÉêS»9íNZÇ·*VË†€+¶J%K,|5=6­•j¿Š¡:Mí×«ål-T%Y_ÆşU ùÌ¾ò².gV«‡Ò­`ƒ×A¢’€]Ö…V0=ßİ.Õ‡‡²’í–vûz`òùK$?¯/W¤½Œº»jíıŒÈSÑ¤$s4,%+Ü”{™ñGÛ„OåRõÓ¶I¾gëp9’“=4/·Ds|áwÛDî’MDY»…m˜9Lc‹çÃÀô¹²%è ^h°çQ€JÜŞ–Ú¤«.‡Ç­£ñafëô`ĞëŒc9*Üyq
#„¬¹ÙÕ—¨AOœ]BMâxûç“ó ğ¼bFHJ_ÎÛ’˜Âª|y$!VbW?ËÆ•Ê¢˜ôÍé…9§Âãt[gÇ#øF©m¿LvÛµè¿ô’„¤vƒ Ã·5Ş÷şö“×š(­²ÿË×ù5#&n‚0Z6¸²ß­|wıw{wµş¿³Ûøzÿûÿqıw¥_ÍtæïXÿ%ép->o,‘øÖƒ”ùËì‰Cym—#ÄƒŞÜÅF]<&^'.+áuµzıËp»¤XÀÀğÛ¡gÎaMC©Æ•,“ßµ¤Kêx>?hÿFÁ!ƒ^o4ÆşÌ	~ƒx-q	Ãƒ—rp±¸ ÌDós Ü'ğÑép~?/=Š¨¥ÄC™W˜Ö¦Şš\¥Ô÷î²÷(góŒ$„Sr÷ü¸’<D%?óıót‡Ô5AlZÏCïÌ¢KÎMBüÀvÃy<<{>üe8êœ†±‰ú=iFƒÛzE]Ën¡ùO¯:§½ÁOĞwÒ;èjcww½³¾¡úN4¼ê;÷1!ƒRQŒğs¡øYúNS‹)­ó&¤Ñ`‰×p¼ŒÅÓb<VåB±´iì¥‡œŠùÇ¿ËuÏÆ$+AÉ]QIU?¹2"g¼ùêÑ,Vúfxn¬/Xj^! ªr9©]‹$by +ŸÙ¢jœ®Æ°õcĞ4ã	Ò¤V»‡°vk„*·A‚ !µhJS”ä1ÎSÄÓ+ù±ß"®GÆ»IÍ‰­Åİ‡N-UZİµ.tß1C0W¦ÇĞZt2Y¼Û¤Æ„=	šcøm9uæñ†¸ñ €;ô<raÈwôr¢¶ë?ê~@Ñ…ºèU†¸,V©<Ö£üÖÀŸ¥0òz&ˆñË9òıégŒ	Bç±Ø%Pºî¡Zø½¡(Y¼ Š$¶…¤
š…7ÄÁˆ$':Â"T*ŒëÆ±íRÛÅ‹Ì˜œIBô¶ñ'Z‰xá)WÜ:“ÔäÌúšÙ™šàb…æ‚âÂ†á¹j,(<ı`fzl‰ƒ‡$®…Ä9n\MIèS‰*Q§’ëãjuË²@Àú s,ôú‡Î›± _´ÄÇ†EËAI0UäÅ&P‹™Ñ(â©}Æã¤Êk»øw¯v4hwr¹ÇÀ¯®6/„˜ä¯}î˜îîDòÎ€DJ<úğ‚xÀ‹HÀPYİmµ&³@•Ó¥Äï²–Îw[Úë\¯xu…óüäm•Ø#FM~/ö!k÷!Fâ¦!³–#¹GÙîÈ„ AÑRƒòø31÷ûN4ÜÈ— É¹Œ¦RØÂ„¼ºĞ/Ê#0tÍ°ÕÄ—<FĞCºÜqŠçØ“2B!0aãş5>s ø?fôŠ‹Qª½,Í3éXd¶G@TÁ5-½©‘ü¥FòdøVf6QÉì]º4h9Né‰£QÏu®ãëÛbH¤¯Z¨ ÄÊŠAî6æÒŸ¨NEy
Ù…FDXS‰Çùkì2aÉ¥ı«ÄŞN¬¶{3ÿÒœñ%çÇaŒ“BÊZ*Ò©bœ9k&MSªûe½©—uÆkYÓË‰•aõ^CxÎËáèÑâ
İ„¼#NHD’¨ïnà{I yÊ“'¶ÑØ·ÿT»©JÌyûôıí¾ıİwÀ@nô‡¡—f¿¿•,Ş(	á^ö“hƒÕ±qÅÄbYë2°C¼‘;ç™¾K ğvÄtìÍ»¢QrèobgmÈ‘Û'—ªVåŞ”Ø"ˆI¹Ê ¥i §‰K>B/ÓÓ…ô ¯¬•Ÿ¨]wæíáª¢\‹qĞ^±t›ö“K/¸`¾9¥1s_÷/‡w2¸¸KÀÑÊæŠYbÆ¤ÿ4ßæì{^Ş¡9ËÅqöÆRÖfÔ
bâÓQ¶béwÆÓşü3ÁĞsÔë3¨•&xz ‘J¼S¾R“65æ¡°ÒÆÈF#‡(“ñğ¬ßïFÆ¢¤Šä²©¡IÜ«=Á¯èÀˆğ5Šp†LÅÂ|îİk+5~±.–05½«pÚu!Ü7¾)\!(Bø{çŞ!_¢3.²GÊÄë»^¶²¾ÊÌÙ;Ú»Ÿ©3âß²œœ½WÍS ÆâŞ¹üå[°Ù<6€è˜dËÂlrAİˆ`ÔŒÍ¡ÇßÉ;¶bÉåW¢›¾ï¤ï=¤Q`uÊdğ¹Ş#ìa`ä J9§Á÷øş±Qd,,dùRÎC'Né/ìÕ}Q`¥u—óæì¶EÙEèù<ÂÎøÛÑL:øòÈ{‘»¨§æ‚Ù–¨©©·§Å.ÂGT;Wtš;z-¹›¦/ÌàZ•Æ“rÏ'ÏPeQ¯Áà2¶” î]V&‚Õë6t1E{tuhäãF4XØ®é34L4]ûÔheû³¡’2ç±ƒ!Õ÷a¶ıUi8‡G^îu×ö¸¸/ì>®)ò_Ÿ´“±"»O`;9Y!½
õ+MÜ!ÜçOñÂ€±ŞaMü…ò>ÛÅJ‡ +€Íù–€–""UÚˆå‹|ÏÔ³(Lê˜×b•/é5Ø‹¢¶¼ßë@”Æà°öwöóLzÙ²™æõŞŞíåAG;…¥,iç*¤ü½›÷Ùşıç0Ä7¼2ˆu`|£‰»µ¾åÔj¾&m$:qo+MØz·5>éœ»£ÎI’ğ—êæ¹ç²“ï®HÙ8èöK;`ô9\ˆÇáËQ¯ÏÏÓA
H‡7µMQ½è,}/êœ:~}îzÊï–šÈµÎ®YHĞæ‘mQÔ‰#,„«`—"ZI|ı<\8u44)m™:	›n.b¨_-œO²Dq¶Äg‡_&–	y ŠthÌælô'ØßdvğŒ{^¿„TTœ¤î {Úå‰RvOø}#QI FYXÖä!ú, ˆ”(™Òö=Š{)J÷kœw·†z¿KVW<FÑP¦ş,*P“kûˆj•ÙË,KÊ¢r¯–‡Y%1u`%È†}0—f¹2ãIv-öÃr¡c§V»éõ;§?CôÏo50îëB3Ä¤äÓÙ[?ìª¹ù¹ƒRÕ¤-4$Š9ÒŞşä€Uè}œÒ	%‚™î9/ø/)X:’Œ7İP äÉAZ©dí7ÉÏouøõ0'i*±±ˆµ_Â	€¥Ÿ’R%ÇæÇ¿{¢Ä’ÿ?•€dsçØÚMúB›­º& %ûrâŠ·ù tAî9şeÁ¾ÿxŠ&E §ô²/œ•0æX&y¯SY›ñ	ÀŸ`üÿè13î-¢$%ÿqüÈ 4	­Øçpi)àşó¾”CRgŸb.4^…æaX&|¾¨–Ô%Blc%/í‹ó«7üehÈg"t ×Öó¶´ÃkKD~9NÌfÂ¥¹[ ,á†ÆfœH‡ñ!ÏRÇ-”“ì~|€b4’üÊÎ	ø~ğ©“hä«Æ´š!²:qï¿q§¸«N,ºââôøñ'W?’¡êJSü{ x†Bø™
ïcéŞ ¨k®×
œ)µxrñğCgòßU^›u ul¬ƒ‚µÌ©¤Zı¬Ã‰ZÂUò9än¹KÂ¹ÀiİˆÄªqÇ£&×ÉW	“Ì›x!äş¥¬E–İ‘U*«I)F\İ(è×ÕµøQK˜SÃølåŸj¡|6b˜pë¿ô:ûßö¾­¹#Yó¼²E©1I­  uRĞ%B2Ç¼@Ú1ˆ&ºI¶ ±İR´¬ı;'öa_fbÎ>Úl3³.]Õ]€4­ñÌ!"$u¯¬[VVæ—Ó3ù‡ïĞğU?IqÂ¶«+©Y­iO¿Êø§"S"”lóËÿ¦0ŸĞ®æÒÓŸ­Õ‹MJ%_Q/wpÜ@É„#€oxù’~ùßìÊû1ôè9%ÇZ®z§Ë%=ªx~8€ MU!^ü×Hk•zD“–\R:A"³ë0½d@e7SêF®¸F±µKè1,ºîá·(ê~MHR¯ì±€«
8ì/”ÿ"L%ÓX«]£3Ø3Pc¦¼½¢1'İ=V¡Š€}¯~yØ;Ş¤Zø·­L{»bøá`ÀX¸q0SÃwKûdË™Qe{VV[7jµéoªÌIktİ\%*rÁ$k£‚æ–zœ³¤º±Ü8ı«>ı¾á/ÍË‰±æTšóoğuóP(­¾ájp¨sEÙœ‚ª<TèE”®	ç„
JÕ¤Aè€(ÕÕ€€Ñ{¼¨‘¾öÔ"²ĞÍHf\¯¯×›âœ€\{ÑZ“½ƒl±Œä|¤Lã"¥•A->/&2øÆ¬0­y¸é¢ÆHáıl2è§£‰$’éZÑÙ°WÃi1ùüË0Á¿C?æˆ%øƒ Ÿ’øû*DõÔ?çßığü<û5ˆïx½l…ã~…_õı—»Ğ?ıW÷Æ	ïçÿÿâ7JqpMs?ëqòBíxñMÚ´¯YU,­$Õ¾ª$~Ä«¼ç%ÄÑ2àb2„sQŸ¤üªrˆ±wÖ¿$}d·/±òïË¢kÿ8å}ü!‰Æ"á°¼†ÚWQéè½÷l#$ÊÀW”¯ñ¯ğ×ó}ú
*…²Z0gÅ·ˆ	¡o2ršª/¢øÉ0Àz;×õz¿Mü`B§şt$¾Ñ,á_†¿!à²Î»?I£‰ø#‹½ñØÅxD“gJœàê¾Ê¾‰¤éD£všZH^œOÚW‘%#üupúC""™1Ï˜ã…¥—±¸m7·`¸JL–5J1êÒçeüÍRÀ£3•#û²ä8™~g`äöoÓ–xŒ»¹A>¯®"AYçå\nÌQŒ8•wƒSS·è²ÒYå´A ¢v§q§ú.èJVÛ¨7Oi ÆÏÜñÿ›µ^”¿t›
…Ù…êš#³
ù”WéèSÑĞ—Ü>êd×–Ğ™Œ®ä\"2 Aøúñ¬®ÂÉ¢Û'ÄÍ¤úfJ8í=q}×Ãˆ°„\6n×AÌ×®¥J~·Q^e4*U¾1¶·‚‚J¹’HN¹Å.¿§1Û°X%Y)ŠáYSêB­•»ˆ¼ >·ç7ˆ‰úMfİjY%ÍÌ!)ª)ä(VäøŠó¼TÆ­~´¤ÆÇ` yrŸ-š^,¸xÔ&iÒv{t³[œX³
ªŠl:w).r'c‘S<+ÃÅ_h •1ëÿì§
ME’@°ùÓš BC"Fâğˆè‰ğ=ÖŞ ~ØçÛD{ÖµBÀ</&.Ëô¹‹ÅçlğµJ–ù>¨
…úÑı(/ÄÍÇÒir6û\ÛË÷UÃH-¦$xöÖ³pz±!ıîÊ/#ÒB:ç÷V„6ø¶ Øg¬ƒôiîÆ[ÊËË4LgF®RåyµàAzÇ…“äÙF04‹¹İb¥%ÌeÌ¡Ì©K°ıÌ‡†m˜Ç@OP˜vx2¸ Iîy!1µƒŠUÌ?$*Í°:“;_¯s|¼{ğ®WÒq
&Öw±ZÀŠ'gO<Ã¤Ç²y]‹” rúPC0NmÙ¥bª:g«ùöCîŞM§j*¦Ñ¸Àûoe˜³nÙK$Ãı-hï­ÌìVG££¢Í‘irdXIƒ£ÙöF÷cn”·6‚ßSqß×¨ó©á.Ï³º[Nn#tÇ¼ÂVÈùì£”ÙQn 5T}¤lW°_9RĞ–Ùc5«ÓÖöÌïô¿Şp±ìëª®’rkS±»YŠYLÄîİBlq1Z˜™dèun^¼´‹YÍy{yúIíóhY$¸],r)wªcè/ZñKwïÇlÁÊ¯íÁœÒÍ¶,”Ÿt‰³ˆqîš³Â<‘¸0å·?{Ô­µ"æNGÃïÛá%yAÈJğ3„7 §‡#îå9’³ˆ­'B«j—°¡YNeÅU®¡QÁj¬•c r|³U	Wä÷ùŞµ0^?&¯¸ºC´ÎÁ×í(xKÓfOæÙ$‘¨®TbCë³Ë„T‘{;Şİîş5+X]›Õ,«©W«¡¯7—µz	¥úxu9A^Œ\ EÅ,{{‰` ¦œ˜nTà"Yà’ g1‹ù2ú-Ÿ‡hãº´Ì20Ù·ìC‰üˆçX’ğ¸UBºf„¢xB"/è®ÊßK6Ú`
•€téä¯­-Y•Ä÷y¥	JÛK£oˆ*:2èKUÁ´¾üùûOËV¡’U(1c•é*Ïåq³@#˜„×\WĞ••ÚúÁøÊ`Û—_ş	5¥šÛ¬¯¹pD>l2m÷äømí…û§WÔË—|!òK/;ã«0Æ¨‚Hà'	ÅÀùûr×–áÕqñS·q‚ÁÜ4„ršÿê_!á+W”%DˆD¾±7
TYe{V–ùeÃÒFŠzÙ}Ñ5İò4[£UÅ+È
xÁ\ô¼€rñbºÅæ¤Á·µ4åëæ-TaÚ$“!çsÕêŠ´,ìás]ç„v>ã¶OPº«ø›ÎÚìLìàiuÆåë ^u—V•³TiÎ.ÀPSpeÍ¯Uš¯ã’V‡ËTëå”Ô„¬€Û¶À‚ëba•§Üv™STˆ±§t¹\:éO±ôºxÊçú²Ç™Cã”/ÅI£|}Ô&²ó°xL¼A‰QIÂ>5Í QzdşRÜÌb›TìÂÉŸÎoGıÕ$§Iú[Q¾õ; üúoBydeëV—³ŸÓÿ_³µñt½àÿëÁÿ÷şÛ\ü·«ÿm­Ş4ñß,èo†›¯1‡ÑHóØnØ.w6fÁáœ.±«\]Áop^Ê½_>(—¥$ªù<oNåİŞáëí=öõvwÚ{¼Ú7Ñ0ŠÑäSz©şºÓİé´«Ë§ÁwÍ­õÖhY¹ßßîvöyÔÄ­gq½“×p¹½ƒÑ*ø ó®»{,²4³äHVUc‰ëeR²#áößNöTY8GšÍ„`'¹¡;¹#óûŞ0„kKâĞ_ÆC·—ı`06ˆÕàòÂcü`H1¤n»ìT>ÍÉÈRz±|"_“aá ŸÕÉÜıƒ'øì³†c
B@æä¡3Ûmò6bª˜ºkàkøŒû²V¸Ô¶ûæ©Ëü(H4;íG.ûâe« Ğ-@çP®hÊWèFÿø|ò„¡¶&{Œx€Ö[µ‰İ&#š¯@@‹Ó›™Ò,§²XQ)Æc8o…ùy4û,ŠY“aıt
í@òGm„s‚àöòÁáAgÙB3“dnµUŒ¡g»Çƒ{¡ÁìäªD€Ye9!c5tMÊ±·¼`j>(¸…<8—D_IJ~¾éçÇHğŠ_$Œ“è*%ÉC`ÀG¿Gõ‚
Í-“–°µÀ.×^©®ôğTG¾¶ŠTUşWWDDqÍE4çÙB…Ò7A ½²j›€_|‘#¢Eeñ¹§ZKÔ•*İç,¹NhUiõ#|m4NöiU‡ )ğN9–Yâe–*œomØcÁ~çÕ~Ü®ım­öÇ­ïWM„+ ?äÂ´0Áæ'°§#´Ûç£™oUÖÙºòö l'y áRÀÂÍƒ†AXM’&i¿ôöv;;ıínwû¯XªÊF•N~sĞ_¡¡dùà,¦3UÒ;ÎêhWAÀ$CŸJ›ÃÕÔ¹<sn2¡k$L, ^{78IåLä½À¹°JşD•’w~N§4ÚT³ï¼YIzƒäÈi©³'†JnaQKq²à^†ğşÿ•êT0)}e#àÑeèÄKpÓ?»Aô€<ZB©´(:ÀrĞä(ÃÂZÏFO˜#a]íjsKıV+VTÊO+\÷íêº
=šŠe@Ö°­’I-¦"E$\2–@È—À–‘2â;Ÿ"ŒDîõ*Æë£ù‘K×tx¸öLÒ«=£Ÿ¤Ù‹gÏ¹¸aÑ¹õŞvH8NĞüJü¦±A`zã0pïƒêdâ®Ç¦¥Ã?‰jä6'ÈÏ+à[)1å1ºÖ‡˜¯¼üå°õ3 ›?œ¹b[ÁHú
E†¢¦O¥Y™
¹Lv ­.™ú½tşt|§îÛ²Í'@…?Fâ´ ÍˆsÁ•N­lQW¨ÚûpÃ´ùCœ‘Ì¦3J˜uõvÓ2{&ıu#£ôŒ˜¢…Aú¹#'y¡ÛÍ5¹ÕæYQ™ÈÆ‘¯½ú3ñ}Q@kãİhpËùö«‰`…½ÕAgÓrV±ÿ»²‚¥İÎèU£UrÄêFQ*	„Ãî¢ƒ´È…«Ä-¡8=W]€Ëy '
^Fò²Oˆ˜x;›¦Ô7	†GÑÔ0Æ„Çq³º¦+"ÙÛûäò$Éğ=s Î8¼‚!¿’Óq®[°¾ëõ:N¡W_´€\ø?İ™hò…""'#tr'©`¦×ÜÁ/‚T[Í‚ƒ:šr˜
ÎóÀOˆuá>Åó.XøÃ5$•jæV«ÁÀx¾¯¯!†Æ²ªJ:e.¤lIK=ËˆvNĞª¬ƒ”€cH?ı,æéæ;o¢WÄ\Ë½•OÜ/^O“›Ü±V I–ta¶¥l¼“Ñã®ĞŸ¯~ÄÜ'œ%n‰K¿×¾—F	İR¯/qTÏDHË£3e¬õò‹¦ĞåTÂ†Cvf§Ó7^˜’#j“«ê/-a]Mzäì¡©‰9‹YR8ã`‰ÅA’yŸÏME‰˜*+µ˜*7º®MÇŞKNQa?ğWó‰û0‘!Cí<üP…èñè_V!º†3FZ$T#­DNc±çü‰ï8kú4Ÿ›[û‰à.Yyà{šÿÎş_™ïß÷÷"ş_Ö×æäÿëO[Ïäÿş¿ïÕÿ·0ï³|AG/o¤¯oÃ•·(H9|ñ5g)šúÁgòì]™Ä*¨²éÍ\gHF¢#·ö[ÆøÁ•CsƒÛzÕDÚvLÛÌn1ËGï’ñÀ’ƒk%¸cp¸…ºL™xÎÎG€}&ÔZ˜<=É²ÂVV->—P!¹[‚„FBl¹ïêá/«DBçª-Å	P±|g³rLq´Ö=	ï~õ]*’PİC»Cá×¿+äCD³,E·¬ª‚½¥^µßb‘Y(%U(Ä‚"%œ² Ó‘Ğòo"k_Z:üÛ<@^ã¹ÅKÙ9¤RUºœÉ@ŠL‡ÖC›OTóéAQ¼Ä}ªá
[M_İB	)Í-{Ëä4d¢%Ëã˜d@&¹Dæ|³W½}p<·^L3»R‘¢(ÛæøÁ^ê¥Ó„óµd=šml·o]UU"µÃÿÇ'=zRrKºì³,C½™Eößìò/b¤˜tKŞhgHš w|Tƒ<dˆwX/y?pq`¶¿üç/ÿViÅxGyÕ03«šxƒ(l’„L”@”Ú+¬ºâOŞ_°pÖÍU¶ªïöBhÏ}.ıY²Õ8ÅˆQx!	DQGC¤‚Í¨JŸ¾è‘q¤GUmÉDr¥+(Ï´MM&˜”DÈKyäo)õY2ĞâeaÒ­T†¸•‹âP½æ€DäS %Æ1~sŞwHüõÁÑDãLÄ-ı’¨èBŠ©{ÇîÁöñî×åKm6ëõµúÆ2+`ªY4œ4ÍÙ¼—­viEÆ„×ú´†OØÔ=šN°d•°Ô­)ïNÖJ^¾p]Q Œ‡b›Ëèšf“¤âök&1Øjt:;ı“#ÜÒ:xµ›™ççğÛ	ÎBú¾Ö8œã¿ì|ÅDgï½}¡“`F«™ÄX}QƒÿUø!»™Å.ÛÇ3/K‘Bªo¼Îî‹MÍ_¯lî©Ò’ğş6Mè„ç)šÍGÊU/¡Ğ«íÌÄ‡mWeÀŞqOÒˆ›pîR:£ã’l” ß Ô´ {ªúÈgÈëİíƒşk˜ ˆ ÖC=B·TÊ”Ó­µVP÷‘y¬Á&Š}à.smµ¹š0C¤V–İL¥,õ§~‘B&SÈ‰:ı0±PX‹Ó@_`£[äãéYãÊãà'˜	Ã˜guŸV"m÷ù×¾qø(5\feõK—ÅÓqÈÄ5'¦#ãcöd¬Â¹1zb¸h^Áœ{¾ÇXâ…Ì'J¿ü§É‰“›·¸íh3W_>b+Ó1¡¹õ>lN	½?L“<@ª˜	`§V›Lã‹@­İ?ÖÃ1Çæ'l6Óy(v›$HÿÒí¼`$a>÷¦ÃÔÁ  Å/Ùá!Ÿ‰Âuš—^öq”ğÁ—H{úş«JâG
<J4¿>e8Ípz«Ò'Z‚6H¯ëÜ,E•óyB¡ä:DMRq¡RW¨ƒ(şñ:$AÍ'ƒq®Èí‘Z·É ’“Ÿ{i4™à(Ô•¸„^húd]´BÿƒïˆÙşz›[¹Õ,™ª] `OÈ¥×K`ìQfLM¬ªR4m¢-×”I„C$§"y(?˜$ø±à«
>’œ$î])MÚËø—5Şé¤í-;¹½lKÚtõßÛşfC°½ù{}™!XÍÍ~hÃc¦Ö çeo
l­¹Hx5ÆF¯òWaº#)2Äa®aæç.ªU<[’ÜU†0c¶ÿ†F:º%Şéá…ŸkY*yE·q]Mšü«:õÇG2<ãk.Ì%kTu¥³b?”™õ½£Là×³§6Ì<•Û-ó‚ƒVÁêı±´
‡²ĞùcOìL6Ë±MK­êŞîë¼˜\ì;nøšqc0|Ü_KÒÊiKàD1‹y_±á D?B8úQÆQBæ^Gü'p¬¹wšuãıÖĞûª¡WŠ>a¾šÙb_:éuú„‚Ë5¥ †õË_ÇULâ‹Eù,'İ½¶BÒmmV¹sY¹™æŠ=›¥ñ}TêBÊªæfB	ìí¾éô:= nw{¿—¼ÖjÃpŒÚ<ÇQŸ|ü7P¡¿ä~ÚXE@‹é–‰µîol¿ëtûoöw´Š¿ƒu^Ò&\ñß·İ’Æ¸¿ºØ²¾ÜWÉüfgfÑ-1§V¸k\Õïe®ÔY›,m$°T\YÖi·œY‰yˆ¡|¾·3xg3:±Äsó]ê’K)û¾è
{fÎ[fÎ;GQ4]R„-!ÂpB*4³O»YÉå¡B ¤¸ít;{í^§Q'ÜtÔ`r§Ö¢QÙÒ^Aùû{I9÷ô.oP; Ê(jµÀ³´$Ùİ,M€ª*	jŞÊÏÍÓÏ5KtgÑqf©÷AÍÆ9Æ$¸h_˜³œ!á¿áÑ¹Ù~K¤©vÀ%
£ÈGÔ(5Äw+`0¥ÿ»mn™MM/ºÒ6¢äÅÆËwm™Š ¹KU[gbBÇ[Ãc¯|ØÁW%²Æ]×{áİÛ%©4ì`OX
ÕˆIAs"›@¹:ää™QùÜÙS,òÖaå]ç˜?A¾E†}Ç‰!ä­tÖ¤].Bô´íw0ŞÒ•Ş!D_P…¯Yérª„[İõxëFêÑ°,íÉc—Ä“7øœÅ³ºŸÇlA7Â§¦öé0dûJœ¶`zCÔ§ãbÔ‡h2qD8…åW?ªxM…&?óŸöü<^hZÌ¾ƒT8ÂóçÏY­{UB#ıen-¬Ëh^&iRl%Uù*½[£nÓ*qO½ãµÀÆéq^˜ïú¹w©ü¥ş¶²"m9j¥ ‚„¥9@ÛÑUyB[Dİãjyœ0ò‰mf¥õ…k­—VkÔª¶Ñœ]óÆ)¶@ê™4Ö›$1ñ‡Z²PÂØ‹P;6™"CËÑ²ô‡;„Ët¸
WyPÓ_÷·ßí"O²}Ôß=Øé|Û^c†º AŒWRá£"\¯4-Û:Mùz…G]Ş˜nBj¢–Àôó&¨ôGÃ7Œá}’‹<°ÇÛ]Á¢ªn’µğ~®ÎEs15Úº¹ı“±&gDiÌ&÷fç´mH§˜î:lÑZ¬Ò#MO®½U¦-¥çY?^zÜ{x1ö†-¶_àÄñt’®*Š&ım÷Hğ…Æà5}:ş1œ‰1t"æâst´åæ¤<Øùj±[f«éÜô|µÈ+<“è‹*]Ps5àæûY©RnÔú~ÈÎxš@Y¼ş@T°gÖÒbjÌ±µ|ÍØ²?·gÏff‡A”Éj¬·ûn÷àv.JÅuî1ŒKlå£>9¸Ärvvaù@iÌè¼:ıD]yÒimgĞm±5E\Ûùb&Û;œrÇ¸3‹ÍV:¤0>MÇaª­ğ«‘ƒ°B7HA5¯´jÜ¡nÖâ%ŠdGÒú½à¡Ş[Oë­úS×–H‰ÔĞG­?¬_DÑÅ0¨÷%a50‹£Ñánø‰ÔåqÈ½:Œ¹µd Û-Ï@s·@úÌ¦b„ÅDù®_¿5¥Û’>Íæ¯Ñ±7åÃ2vFÛ¦ ‘˜ö]¿x¶Ÿ…ÈùRºÌÇ¹³t×æŸXQ£G\XÃÂ´òwøÛ—Túz|Œ ©½8Cx˜ªæ•¼%\{aúDİäğµìÔİ*).Dt¡(XfşWJªò2ÉŠ›+v1ÈÆ›¢36ÎT]N±,Vö*ÏYÂ;Ôœ=4ÚŞùïôĞ¯½ô+½=¦İ®}³{ü{ì«n¶Â×óáĞÏ¶wM$mï‹Æ÷ñ;¹`ùú· kÑÈ3¾ë»¥Ù?)Æ“7YÙP¯Ov÷ljiÁÁØ8“ßâÅŸ>ÔvÓGçkÀu'.a¼[sÉÓ`ÔÊÎƒyUiÙ¼Ä^ü>Hûüq}Ã/˜Á›¼ï–
jZÍ¡–`1÷wt‚åqmw0.Z4¸À¹Û»ÚlL%KfİXÏ‚óˆôáé^x^šÕg£~]t‹mYmKy[ŞqTX´-ü8«ÚV•öR…Àã·¥a’»ÌV?Z—©ErÈYµÌÅmhF†ŒPm¾A¸»¨¤OFnF¯uµiÈĞìU ØÜÎÍNÁ_¡Ä©9s‹úİ4qVï¶‘[©ÜLÕßópIª0CÜ&^Ã›ã™Š,‰ùæªöSWÿ¥m“ÚZw9/î”S*É*=ÄL5Qè²í¡öˆp´»ÜF‚Ğ6^*€>vœ—u8ŞĞŠÂ<	Ï9â@šîP–œÊF¡‡GøÆˆâ®¦z ­ªO¹eÅ‹~8Ô~–/$g«@÷Ì|ÃSSş,üıvæz¬=›nf_Y­[ÚÍ¹ùJüeV®hÓ´íû>-æ4bÒ‘!Ş•@» ‡0ãâ¸°hÃ¸bèïXùÁ!Ó±Æt,®Aøı˜¢HøF`P>Î×‰£]½ÍdAé*[LÌË*K~ù‡´\gA’êßÀ#ñbD˜ãÏ¤=š§Mj0Ş!e=MqJl£}8¸Äß«¬¢[÷l–/*¾
†R¼‰‚Ğ–,ˆ£=ÓåYhµˆª\V€èÊ“6¼¢¾›ôDÀ]`³<X_b+8”fNuRNÁ¼ÓÒbjL–F”7X÷#ëÕºØ×teşL§.Ds$)
‘yïŸ0Ìœ7ôÄ“õV
Ş!Ü¹B5¡0­¬!´ô cv¯à3²ÜÈŠ+E—@‚y„jí‘Õ
âY_ÀÜŠÆÜsªüAĞËÄH$ö-	NÌÁL Z]IµRT¨é=0îmÉ²2ªÒÜ¬›1ú¯Œ©R^i35XÃ£†È`j–gC<øåÅŞÂÍ]Íö‘—ÂšB
è=bPqÀô„û ì
Ş°	àéX4U¦ ³ÍĞ0t, ¿Ş_ë¯åìÒ²®.˜›U 9Yc8',á}n×–\[nÙ˜y?UµkÕÏ©Î1sZµ³²•±môGú°0W•é´Ø8™a¨¢3 ÂâDçWA=Äf<¨¶qTúƒInä©8‰}?I»ó³Z#>q¥Y±"‰	‘¶VÖôjÉi íÖ„º^•`&íét`4q·˜\Ó9å•êr
šşs´4ù“ÿ•ûÛ\Zzì5ElKe0àSÄ»¬J tevwHg¤ÌË‰Ô¿İŞyF'~påĞ„Ó Gq/ºJ²™&ñáõ8ˆE—Ä•Ex6C!‡ÓCÙ–¹pcóIÓAÛ’é!ˆs]Í[³]ZZ±JjÍíá¥–és&úâ(óÎ¿='ˆÜ‡Á>ÛX]ú=ğ‚9¦Û™µbv3xîÏÁJæ™­’Ó‚7¨È‰İ/we¨bÉUâZTõCÉŞ³’‰k4İfo/=Úîc³.9œgíß•¹¸(”ÒA,%uf²@VĞˆ5Ík¨3) 4»#XSó2SK²53]nİÃ‰ó[œ¦s9Ñíâ~KÙŠ8}àkö8½—ëê®2kx|ùØ¥°°Üu[Ä‚EU%„õm¨`Í¯.¡Y‰²ë‚ñX™OÅ›*‘”M4u3µ….Ğ¦7•—±´·ûf÷¸¿ıæÊèïîtà
^ñ`öÇ3¿\‹#µ€ôøW¸Yá6"¯Wì–’vy“/µsj\›EBV‰ÎØ‰DÃqëÇ¸?G9Câ0-«nb©ı#†Dtäîµ–VÊ—ÛÈÇÆ7õ64t>4“¯~Ü>‚¨CõàXOKÒ×?BûÎ99ùs²pr…=úË•LD¡VBa(Û«”˜";6f¢’“Ú¤¬$„2¼8ôP‘<	 B=òc¼ığ²i–:¯ÒE•íÌs6îmÛ‰¸şI	QêŒƒ.wÌ9%§šõ -+³T÷²Et%éá‹¯pÊØÎ˜Od¾ÏŠÿW'˜,=ƒßÄÿÏó§OKğÿğûFÁÿOsíÿïÿï¶øeş~V?>İS…â'Ì%µî x¾)5ú®¯¯ëWá•qÕ;È^?‹>\»=tûSãµÕÈDX”kĞŞ¨¦¼yñgBäÈwòõ/kÏÊ*SÒ”p/“8¸b£
ÇÀáşQ·s´÷Wò‘(ÍÃÀş7‡İŞwôõ~§Kæ,MQã(/x¸ô™ 0€¦ªTƒû;jQ‹¿5Ï›„hn+´6ˆÓl¢	]!¾¢ŒÄ‰HÀö}„¶~bí6«=fßkêºZ‡ĞĞàØÂÚ7øv-ƒ›U­&²sh*…{$ıGÂ¬ö–•‘”éá‹ç¨İ*G½qûZxYÏŒıŸ
¸`MÆÉgÆmµšü×ÿoûÿ=ã¿_è”5›ébÀZOãÄ¸B†Õäó¸|ËÄfüBk\zSIêxGÊîóĞASÖyë¡…¯€¼¿‘WZÄ¸×÷vÆIúˆ™°aBA	6ÇƒÃãİ·p°ƒN~•ğw¥áùìÕcÕQ’š6wÇUÖ^-%É
 yp…¢wºvÿ¯Lâã®:êÒ $÷š*	·œªt·wÿÆvÙöşëİÎÁq‡–#/¼¼KVG¿ëæš¤Aø¬ôn÷íÎ»şÎöñ6šiôÚšûŞMÍ/(hĞh‘®c•¡¸´Dr‘ßtöŞ -Vœ%˜Â§ß'sf[…/æœ¨¸§éiz]1ïxã0²Ã!¬ô0öĞöûGR:«o—
õ¨îÓô±@àû#%Ã€æbÍgõµ¶wÜ+D¼ÈGğçó}˜îi¥Ò¡	’ä+îm÷&ÉÁNÛ½#Â®Œ(øh¢**Š¡â]Sµ@Œµ×ô,Ê™ı"åï…RN\gfxâqù|2XÖSØ€)pX?.+Za¡ µÀÈ}ESrö¾:><‚uùÁ¿@¦,®!Ôƒ^uPœsxtŒ­S’[…)‡8G8‹ñÜµ ÍQopP$>Ø ¸–ˆ_ul¸7.
Œƒ´>˜zõéù(Î\ÑI‡®Yo¶^8 ½¸MÆÄ)Àï¨QÔÂT²»ZÁÃ•-¹aOmc}}ıùŸq){Ë,ßĞiíLÅäìâÚqóÅ™ëvm‘öcMÒÊı$÷áÅ³ş³BÛÈJé®™•uÚ¬"€ç·Úd=«7ëM×ÉLÍ¤iO'fë…«VBÑ¬ s&Y4ÀBêk¸ÇŠ¤vıøörë9&[æ=™Ê³ê”b'iĞI«³Ê¢U¨´}·fYO0Ç¢	¬+oÍ2‘ÀÜ<~ËLé'×–µoåÌ:Êfv³Eıœm2»sµy£>ÔøÒ©Y->T"Ù|?"fGæ-8Jä-6ÌÍ ¥ïíaz9=£á‡Ñ$ nÜ›‰Ab[qœãNˆqE¾¬®{È=µM\3]w§#SÍğ8€vïø\Wx_K„ĞĞÃ /O³F‰Z+w‚+bâè‡`¢OE‹œ1ŠŞ“‰7ô>À™,Ñ"û²ß98éïwöôv6Î>|5$5‘D+ªóû4‚ıK­ÚÂ6êMÚ}ÌpñÜ^æÑËfoPş‚ŞK`»µæ‡-óUeM,í¹¨jâqË†Í/qœ×½	ğˆ)Û@0YfÀ‹(Ü£à¨ç‘°ˆÒª´ç«øTƒ”u¸¶×?üè::b ·ÍZ Ä¼…‘!³O¤:'¦ët;Û{TªØûõzêqàUa #”ÜSDYŠRqx6å“bÎˆQOé¤Ëa ›»hNäÅ°º8‰ø£ìğ„óìY>ºíJ¯n¦—`æl4Nëş'Váû¾8"è½ÀM#?JØr}™$ûOXt?Oá÷:heániè£>Ô “:v„&ªWãúyò‰¨ÔMm¤ŞEÒÈ7F<ïÄÂ2äÀP×çs~‹ä9B»,sšQÔì óNÒ¸%Ô]€–Ğì¿À«–’ÔHb‰8˜T~¡šõuÊ¹ä8¦–pÂÔÊîa¯×ßîî«ÛˆÎ},Z&×mG•ú"õ#Ø›£É?¡®û¡â¦¤Y]*j>İdºû_¾uÑ%=êkÀZGWÏ=—ÉËéQ·óv÷Û6^——WŠÖ4LomÜÂmã0hµ¯¤=@w~çX³ZŸØpNµÑrÍ÷kş€?YHrêı³8ô/`çLÏ'"ˆ‡ô±¨úpò`,Cànjü½Æ±mç7ÊéÅ´;^Û<ÖÜûj²ø™¥âwjğoÙ^ô$ŒE…'!úõ»jãù`¨¦€ö½ÿÄÆ±Òí¼ë|Ë¾ŞîîâîÑsœoº}ƒ­p1Ä¶AP™kqtÉN{¢ô_tjg†îGKxö¡Ù¬ùÁğ{gé{Ø¬Ô/¸xLÂgÓs-pà…qÔ’¿`\DÍ,öCš¤ò»—¾×b..5YÃiº}£p×ÉÀ†Ûî(Og%Ó³+.Ÿf#ï}ÀøğG½!Cx’1Ç^Ìä•sîÆ.à9İ„¸/•UÇæâ€¶‘
ãØüL,“ı¹¡L9L,ÿ†H_ ff¨ÊC‚nà5Ø8×°¿®(¬†66÷T lÒß}÷½ã”j“Ùu”üÅæ»'iW¿:Ş…)öÍö.ÜìPM™×µLH §lk‘·Kü÷ÀÙš.ñÙ øß‘Fˆñ¼³°¶Qÿcc8EP–II'.‘<3©µØ;9ÂiÀ¾ì@3»½{F‹²ïÖE~Všİœ×Ekšsf/ÆC[rgÈ’UñÿÍª•4ªı¥Ê¥ÙlÎÌŠBc—v.ÛŠ¸êg±7†û
ìûáØñ×‘ë+f—)ó¸14„Ëí›òXÍì¡mu\&î²Ò¢X ÙG´İbÛóni–_,ç£ö`çk6İƒŸBü=£pµİ¨o ŒpÕÜnó©µûİdŸÒ¡§Ëí%î?åTCDºzç04A}¤0×¹Aİ-u¿!ÔáşĞZ£‡	øëügğvu-¶ìÎDvXx@÷É%T­Ù§ü¸±üOijëóÖ´²Ö,ãî^ûg|€C!m“è\hñré¬y>bÉÍ8õ>lò"S«â4à_>,{ûÎ#„Èäûç€ŞUw:Ÿ¾‹&¹(^A–ù$âTì¦|¡Ê˜õfUÌüHÿôj‡ò¾T¡ƒäçÿ’µûÄ›­kä”ÖX¨£;+pT{¯…?ÿ}~ušvOY}Çûaš¤JÉšª=—º¯l…Ûğ¹Á3 d³¼+/â3<ºŞ lu~kHóh6¥¡5üÀÁ+ 
jÔ‚åsÍ¦²Zº¤¥Ce$(p8åUÈY3•ş<gu:¡Òqzn®Ìo=.£9Ó°‡şÎ0”VˆÄâs‹€Ô¹Ù!_+›¹µ’o+¬<máÙuÃÔrüò°w¬¥:c*úàdÿu§›_¬‰‡ªS°4-Y@-ÎŠµzóY½)+Ã·FÑ±ñé8ëËA”bªnŞõŸÿ‹½¾Qğ'8½ÅxqSÁk\aø4!%•‰ò1ò„…Bg%L˜BJĞ”#¨D®r&ñüG’Ú?ÿíc*ÈæÑöFÏN‹ÕB°R}¹“½ìjÔÿêúß†iÎçÕÿn®?}Ş*èo<è?èÿÍÓÿ»³ 6Õï¦È­\XeuşN*æ¤UöYô½ù£xß?Ü9Ù#}¼·®ÍŠüX÷‡ü®ğø“ãğ‹…t`Ëfè»‹d@ïÑ¸– =È"yä1/šú’p,¾¤øøê¾h^’0pù¬¨Ğ©ôYÌa/ƒOG‡ÓÍA±qßÃIÛÄç`iT5"1x‘#ï"ôÃWafjÈë¬²ÆT(	p—–*M
É=
BÒ–ÎaÓ«¬S¨ÑrH»‘‡†„°§&ô€à÷3õ[©ö@èsSNª½#ŸÕµ¦nò,`àÆÚ÷Ôy÷Ñê ëùwùBLŒ3·ªgu‹h‘Ó¢^¯33­°ugµøÊŒÑ`xI#¶ÅQËÈbñmó)3gÓ"òD|‘´WªèáÒ˜ÄˆØ[Å¢Á|,¥å˜…†[_é'[Æ×rçØ(×bækÑû#CRéìZ‡qu¸5 BT­prF~ÔÍlr¾úd²¢0A·¿.GœÒ¡7”„
E¶òm®(ïÚ,+d³*¡H´ö“	½{tÔÖá=dQŸ“ÉàÃ37d¢jõR8Jµª¡Î›~ÌÃ–y8fµä¼hXs/ÄÌ2X…”b¤ËFÿ2iÙ„îÏ˜¥9BoŠ®òÂ'†-;ì%ÔŞN ‹œI	»Ó6YîIÑ@A¦qMG)0nbì¸}±pS8Ñöš¯LidºT¡­4…8<]ò2‰ƒ±NÑÍ­å-Şë/?ò‚I|VÈÎD_0»Zš»è8ŠR¥a`ú… ä3r%ENPˆï!ô¢@Ã÷¿æ:yklR!ç÷1³¿Ú *¿ó7•º*­P#v¡~Uâd»KÊ)T’M	û–Ö³Vxi,hòÃYí¡»ï—ÿã{„€’Âñ“ı{ìÙ³ç&^·€„ª<Ÿ‰î°87àäÑ£Ì;œ°¯¾h)(,,
/÷™¨@lÜ™C]úqQœÂš@»//%¸Y1‰Rœ;pR!¾°ªsæ	0KÉ¼Z¦X®¦ö¢ˆ†a" Y^ërèìz˜œ’’t²"SŒ"{¼õ‘å'zéUÏ,	€¹÷Æˆ0OVåÿ„?gFÃÿA:†Ä(÷ÒÉ0@ BU*íO
Á±!¢le ù²ù=ÌÀÑv%‘gwÑè¡jû;É²[Â¢ ¶TÿN°‰ÒğÖİâÈ«Ä†åxæ6)i‘|"İ/-q³ÍrNŒU»-L‹îçş…F0ÙøØllğrƒjEœzg€Írê¨]ªãÅÃí|øM:¡"v®ñ /ôPV58fÔĞóµ}Ìá³·¸‹£¥˜“ÚÏàtøé'ùëyÖ@Á¶¶,ÙVÎ]òºHÄå®Ï'R<)pS%p¸EÃ93«¶XuƒUŸå}‚ñî˜‰±+Ì‘P5½7	’^£Z\E+Ò‹IB{>’`:Æ{pêÉ·† Dè¢÷#‡<õ‘èèŠa {M(•ŠÛ9)/›–V"ÃÖ°
®z šü1Dö%&sêF˜Ù†k·5×NÈH~‘ß²äµeš›ëİ‹$Fx‰:ŠıÔşD%[OgëiXÉl§­àP~/µn¦¥»©u;{vsË‚ùÅì-’[.."‹>mf€@•#Í;	³yFogÆJÈŠü 2'/l±*ù>ò²ˆúCÊ+-‹«'÷7í…ê ¼;Ín=órğvÚL3û"GºÂÅ"wm¯,Ñïr=øE„–ÕjÚ¬%)ôÒ\}Tızn8C°ÉqpX[WŞ6JØ4…×Â×oá	¡
9)©|_©­Wuf”$U)ñ½Ò]eÅ=uhŸdb>67bÅåï¡Ñ°£H¨G¯X(‹³ÛÒµ”$ŞÀù½¼ÿøÑ iü¦uÌÁÿÁOîı§Ù|öô?ØÓ‡÷ŸÏ5şp 7~OãÿßÿÆÿ³¿®ïğ9Ç}m½™ÿ]o>}xÿı,ãêâ#çíğºb`Õ¿4!A^0ŸUÙöô‚5_¸ŒP%àÎæ¯(SèÎx¸N½÷%;ØŞï8¦.Í©JšF9í.ÊÒÛ=8<êíö³5g±£¡ aöïNÏ_sYÑéy÷{ú	Ç.üìáoÌÁœp’-‘5/—Òä² nÄÉ;àÌÊ²ªÛ•jÕií”³‚ÅÎáÙËÖ.$F8©_QW€v;Ş›î.5Ö1<PÇG9‚†cîôÉ0|°í£ã'8ˆ\6Â+R^ıè‰zôæb4,CªçaÚLVNuÖ”Aªí“¹
û†;DÇ†
ú:9z1ÁÑ3¡©vM‰õ)[RÉ¡Eº"•ÎrÍVºÓó
â2ªŠ´İHNÁz2cÈ0m‰Š¤‡ç©PÈõ—‚Ú£ºÀÍÒz†ºÖ#Œ‹ã%ÙÌ*(ÿıO?}'|Ïd“’ F<4¶GvÄ,À•êd8ŞV(TèÒQ×„m±ZTèj‹¨Ğ‰iÍ—;IøŒƒFˆ0ly  _jHo|ÃÈ°^H|sKt…ûî Ñ®„ÿ+˜ùUŞz¨÷*Ø´®u‰`g´ÅšÒl­ÈGƒÀ³ËUO4/0CoŠjıqÖLxÔ=LJÂ]†ÆFOX‚à‚7Ê¤@¡"³İÃÀŒVÛÉñ—‡]'Í³âS@?ê7ÿ|¥p¢íÿªãüÇÃç¿‡şñÒmL´ ©üÏˆÿ·¶±¶ñ¬Àÿ=àÿ}&ı?È®ËçCåÄ!¥7bì]8FüÁœEÓ”ƒkvx)éÃá)|Ì!ôÔçŠó€Ø	Áè,ˆŸ0ÒËC3—“WÎÒË$£ñÅ«ƒÎ7½Í—ñÂ§Cøéå0|%OÑ8EôèeeëÀA›2;¡G
?óùBÌ	è»øÜåO(Kõ¨gJÏŒm²—Áè•´	{øtRO._6 Æh–ö€\5Ú<&S,8îÎ‰şí”r~ºkÇ±j‚')A%u=« Nk®!ƒ7ö¤'Ÿ Ø
®æMâ'Áø/;_5›«Dæ—¢°¤ÿÛİo;;%@H¤.ØÇÍóÉ`ô•¨p¤‹°J*Pâmøh(Ÿ¦Éñ©=õ•SØx¶ÎJ$ƒjö’ó²“‡Ï®Ì®.0¬LRšcìEÙ,›ÕKm*t÷t*ªƒë2jÍ?Şa6£§(¥¾V6!7Œ‰dp¨¾ˆµ^Øqå,RÎg‹JOõWtU€$‚¹ µàÜ£#bĞóôˆ¡ĞØJÓ8­º"dŠ-•sƒ‘8‘µFŸ·˜x9PÚU|cv1±:ò¿Æ§Ñ%0rq ”À
 –>Oïâˆ6µ½ó€B1+ÔŠU½}|DŞ*ËM¨‰’2aúºÇ‰3#áë×¤OÈíîşÕó†ïÛåƒÚ,ùô‰×Ò#ø¥êÍŞ.ÛGwSA’ßßîÆû§¿˜tÌì¦ºÊnÊ˜Ñ·ŸHm¢³>Ğ¶q¦Ô]şPÍØ”;Kôâà™yÙæÂŒĞ¾wÛ©6
'ü}‘Ú14‰\“_6ìï:¦eÃ€«Ìw.âŒ?Û¢Oø!Ábï@/ØOÆê q–Œ…h=}N»È¢:µqøäsş–ì}sı‹óÿëÏŸçøÿVëùƒü÷³|?şb|–L¶ôÿut¥¹Ê™&øeÅ<Åÿ{…	/’‘åêüØq?F12|Ã­XX—¾œÄú!>¦xf†˜Y–Ñ Bø	ğø±<Ï¯(‡Æ_Iò6¹Os¹›Ú§¿Ïb„.‹šYÛó±,§¹jÍÑ¢ÅÁ®Gæãä¡_ì®"TR‚&	´—€òÕb·rÃ¥ÉºÍŸû”çàÄÕü¸ìƒÆÎŸqå#Ç˜!1ÿ&G%1I¯!?øzšaûÌ‚r3e³÷ÒyQ´DÏdóeX¦¦4Ä/‘Ø—•d›Ã<Í1>ğ4e¤(¿T–ÏVKf¾!Ş¿ínÅìO z×¤h^ë˜FBÖgQâY K€ò‡Œ5›¢^Ì`ùn0k#½ó3‰È²ıƒDòóé'dEÆŒ÷üş`Ÿr=N£2ÊÎ#¡ñdQÖ“Ù¹Kû/_4ì³ß88‘oÿĞ!^:ÄSÇ¼·^#n«ôŞ•ŠY}°‡‹àÿ# $"úãx&5òŞãu`ÿßZ{×ÿ€ÿŸ=ğÿŸGş˜Òê£¡‡SùNƒ˜•%¬"%gñ+I“£R‹o„çİ(øz<†ÃèE
1”ŠÒ`Û‚b °hÈÒ›IĞvw])¤8D|2â˜­§¡lVºŠ|Ü^zì2Î­Èå|±ËµNK½‘m95%iœ£3¸ûB™q£ÛÙŞÙïÀ´w_Ém©]îeÃ{EêıÑùy8¡ˆ›LáŞÊ¿)Ê»i…Ù:¹©2*ÊxD.Râ"£rş×^ıç[çVŒ,„Ó“Kû_°méP´åJu"è¢Døÿ}íEşWæF‘(Z<â¢Ål.Z6:—%şü_ìç¿ÅèI´Yô8@¬|bÀÏÇô0öP$2²‹ã$¹A×åú‰J‡Ñ=„˜„…OÂæR†›˜{7]NŒ#=‰†hØ’L`HÄÀeÇ›€†P,x¢³?ÀµÊÏ÷&ß¬µMŞ@% „ôFD¢<ñ§'dŒøü£§$zjn4ÕªÑ¤½jBä€¸àØ'P‹(r¢¨™úÈ g…“Xµ,5o¡8_Ùƒ~ÀÃçáóğyø<|>Ÿ‡ÏÃçáóğyøü‹}ş?q'> h 