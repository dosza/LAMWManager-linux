#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="746206753"
MD5="a9422bfd1212313dd620bbb5c0a61a73"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23792"
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
	echo Date of packaging: Sat Sep 18 19:55:39 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ\®] ¼}•À1Dd]‡Á›PætİDõÄÜ¨tŸI]Ë=ú5 Ì<i;Î#wrÁ	²ˆ/¹Àc…®§¶¤Lqip%êü%N¨ÜEk÷óöIsº@µÑYq’$´²ÿÔxv€°–#±rö®IvŸ«˜µ£j)>%ë¯] ÆÁÍÙëWÉ	 ¾e‘Z1‡qÈ€CO\¾ğ"ù‰••±×udŞR´óg¾h†záÆ‘PÓ3~N¶•½èA•3”%‡çyŸ&ÙV­´T¶cë,
QÅ+bÜ–ªà"½]–¡»ròœhºæñÁ»22{÷äÌ§kU'swø@1ıüüÛN5q;á›öd|;£ùÇşÚLÿ-?¤®û„di †|÷úõø^°Æ%'Âx/&5İ•ÙÓ1ÓEÑÜZÑ,Ãñ|}˜¤_d®¨ÔïBÎÖš™ä€Böh“ã½ G¿ªá_µ·ŒØ¾»»jrı¢Îšô‚Aë3¼}‹] }åÉCí“ø¼C@)¥¶ ØUR$wº_LSgÜuUÔ•|
:‚êúWÈĞ‘£ÃÚbíŸ$1ŸÂ¹}æVêÈşzÄ³%]âşš–Á§ËúIgò”Kê€†SÛŸœ*åü9v›?ÔŸ·«›ıÉï°³£Õ±ww½Ë?dÑı¹ƒ¾A–ëNŞs’(0=K¯Èå€{](è(…>ó¿ÉÁ®	 óKm8Ù”‚€+/:ø~\cZt.êYT+çÙÏî@àîpç¾¥"”uÛ¬ÊMØ,Zï#ÎŒLüÔØpêæíM-±7§èÒk¾	øÒ²HAæ1ÿ»xËº0’™µ®ıÂ5j:
Ğœk`åŒ&¢Kowi¯3€nÌôS,‘eœüŠwÈÇ®í²u=²ù5´¢Ô…ZOXÇµÛC5àÌA·>ÓÊ7s€Ni¨¤©Hºì•È‹óØ¥RtÍq2”'¶Åğ]µ›bå\©£şã­êÃQ½f^d_Œâ¢n(ÛN1€D.4˜Ü[š.%yª¶¢dfØÜT¦£õ¦òûºË–u„AUºCaD `¤¬*t¢º:(bŒ‚´ı±ºv‡”UÒQşäó™«É \ÇhR‚øz¤Ñ2|BšÅÔã¹& Ñ/¦hì„F¼ØÒ ¨”€és<~”µhÜ,œïQşd•aİ“v|švK;Fë~!>Î·Ê‰å+Ó²,[ëñ¼@º)Á1Ÿ8$QœäbñBY3pZ@ï@%ê'SšÁñš«-«wZy«CMD&õ\côI5¿FDµ>{a.Ãwë•îm¶¢a)7sˆ`ÀÈˆ‚~I¸K$ìš¶XdfZzvŞÌÈÆUCoè¸3JÕosQvfu’ŠÑõé¼Œ(IÅ˜,ôç<±Ã’kN‰<¥Xß /ÊÖÃ´<iÖ4„àšĞ‘Ëú|2éIïû$h8ÿúHm†í*c°·ÉÓˆrc ¯Ûfdç0±iÊ—ºxÔ¡DÄŞö‘_ùæN¾«@[­ì}{êB'N”E~RÔÏÃû¡JéCI œ{ˆõô¥…ä¢tø0ÿ_´]†ç†•wµ(°M/hÍênÈ0„(n±±¨„BÄÔÙ¯xÁşëEˆœŞ÷?/Ì©´C?¯_4ó?Ø‰3£şÅ›\¯W?¯Æ+’dŞQÖ˜7ñJ*˜¾,ƒqµºKtGÕØ¥}¤.‚Åd¡×¬†Ì/HUè³¸ \ı­ÒCUó2oV3kYléÑ0rÍø¿è‘a×^®§Fãeƒv·½ÔL¿.ºUX¡ºªbÆÕ˜G·•¢x2ÄDÓgnæEÄäíşcµq„Á
*ĞÑr!V¯L™ä˜ì²!ÙÒqa/R/Jä}U›ƒ&“ÀèŞ;Îwp!ÙK9Æñ!?ª1˜ôf+¯é0¯¸Âf?ÜÃ¬LÈkèƒˆò¬tÈk¹$Æ3<_° üM›rÍlNô§~áßÓ«§ÌÏ`Ù_½ÆZ¡¢Ğz(büÄ‘|”»S+çQ*lò»êşJòZú_Ë1™*•Tq¼Ká ²ŞZk0ÜÆïı1î›n«nln
â”Ûövƒ^©·íà!|ø!ÿúwö)Ì B^©¿›¾ºLù3“YE±Íğò#t¸˜Ã1£LÑ¤'•O‡¡İs.ÀÕÿhAËF—6ñ
¼å5ZTû[Ûƒ>¡÷ˆšòÇ¹&1=vJ0£Å¦•:|×İèu"ivÈÊ	6®ÆÑFeâÙø?vÓÎ`&(²éıOùr hÅ/>—½7„*ñÖë'wï$yê€eÄÆŒ?äâvµğÒ¬7ñíÄ¨ül%ï®*‡àÍo›:8›}â†3„ÂMo_›ƒU =€}>oÒ¾MëÁòº ˜¸,áA~0°údÒÆ7×¨Ò3«%q[ó!I3F¼ïeı^ø<xè(æ Wì¥üĞ“z„‹uaÌğ3ã•aù¿5{­gI_â[¦j1‹IR1¦LĞ\èœ“u~¤'(Úâò–‘ôªCšaâEÑ1&ĞGÌ¥Û¯ß$£|Í†õÛ¦=Ñ	Eãö÷£ü­³X¹Ÿëeñ		'ØÑxdÇôŞ?õZ”æ&CßC“[³]tû€g²A¬=ÔÜ)Cú;Zè•Îl±’tnhiË\¯+É^àf»-É›9dåöTöÕèlyVM¥»Ÿ ‡wZ	5¬üô.€ı,k¨ÌsAxÆ§p•÷Ú¨­ßÓ¿İ*Q„ÕQ²«ñ½÷\ıŠPYo)°¢l]Ÿ m)ŸÇvæÆ*%"jÏö¾Êı´«˜…ï&ÿò9wõ@M€Ÿ{Ó¿È‹ìĞa—æƒuõËH5¬ :aÌ$ºœRµ@kÍ–ïÓ*"Dú]@îÅ–A×á}öpZ 1»™ròò}úÿDªnÂyĞUwPz4J”5œÅ›m"ş£œàM‚v´Hş¼ş?ı
O›N”)µS ”XåP ï¾õP5?D‘Ä3Z‰3s€6.ö.Ø"’YÒ ¾gñ‘àk–~Û· õudlšÉ’×(6ä]QàË&í ó5¨—‚s‚ÌÛ¢K„Ã?#«7ñi}ššÆ0í’Ï&jÔµLÓvÌ7Óhh
”eÑÖ}2ŸÊÕªÄå¯wQëşêÄäğGƒ©)F«‰zĞU	bÕD×²~*
ú*eéªâ{ÔÊMR¥À(Ğ‰‰å‹5½wW<²-?g½¡
%äº6sòD8æÌi¯ŸH_u1ÒËø å:Ş	·­şFÂ™Í™a2·d¤ªCåTL–FøˆßÄ´((`xmxy,"-ñ}«ƒWÛxrnCÙ—ûÆÁœ=mèÖ?Ot3½“¸¶÷¬õV¹¥shœ3÷ÆXìĞÈN³ªáÕÈídô=Aá'šBWËƒá‡¹³wo!œğ"A»R]aù³ÑŸHaäjÖ„Hš\äY€dudO6jÂ_w!¼Ü$F|‡b;Ç¥j=°TÖq³¿F%1UDë;¿oÍçÛÊ¯ BÁ£,ÆĞ¿„04ÜV?¤$”ûtY@–¥İH;ã;V ‚ÿˆë-[RhZùdB_%¾#`Ñ†[uXm¡Êš­öá^–ğHÁ¿
©¹óY¯§Z–r15„Wvò3)=@™şnâpŠ7å_K=!İÙ±ñğOQCùÄ Òíîò—¹ŸSËõO¬? §Ş}ª&a/çäº¼C¢òˆÕJjkù[’›ImÆ'NK@K±Ã]	««dö ‰gvF:ôëççöö©k…×|Æ»aŒ’äğ"+WI§r†…©#´™sªú`—¡´´ªÌó•ğˆ#£Yõø´-àd‚¼/7‚æÍZÈx5±T¦'xşÖ€YÏe×,ŠiîİöŒ^E§>™]G’¤œ"‡HÏ9tŒÂ)À–tƒÌŒiXY#­2¹?ŸØ¹-¤¬o?™J1âŠz5˜­Ø™…ór¸ÒêİX¥SDOJ}«eyE“V;ğÖ2™Uz%¤,JR-*¦‹ŠùF¼Õàµº<ÊA¤ÍÏÕ|eKºó°!dk˜f
2bt°VE [ÓÀÜK¼4NUÕ•¿|?L2Âr^J”TxÅnŞ¬s6Kz=‰Ä3ej#Ò™ÊiÜ^åÃ?1ËæŸ÷x^÷!XuÁŠæ–\tfçøhÏ’:<­¾\ÿCµÒ”öíô2¸­B™çjõ$Ï×
QIapÓ0ôy< Æ@;Ê•?ÿyÉ%ƒs'Ùøå”leBŠv¿±AöQ¨éùµ¬Èëş¾ù3w0MH‘Çºcq°<¿#|)iS
 ø Ò¤D—ZQŠºQ6”P3—¡òµ0§öA\]PU‡Œèò†Ğ×(•¬ïPHf3¯ÊŠ¡çç¾@2¯CÔšxù(¶VO’tn(/ë„b î¡BÜ6‰i±…7Ö“WJ`K;ëlŸç´Ue´JoÀ6KqüECcT»”ûÉM—L¹ÿq»­‰Ïû±ÌßÓ¥ÀšÿN{Gf±Üà=úÊßNVPâÕièè«æ>¦ ‚kTí4´˜ÍŒmæJ—–3q¢‰ò<³åzSsE+İ¢”…mü¿î¼sJyJ¤ÏNGOó;LêzŠ¯ù@Œm=ÍA%5éğ;Cä±‘·oTErùÏËÃƒ„zwır¿0ga¯Ø<Ürßlk™xr 9«ŒÊşzš¢—›`@oÛ!¼P¼.;0Ş˜NqfÜk«,L:Ãñ(±®îäÍ³V–ä½–ğ]r;÷O>—‡ƒÍ¹{½4n¿_×!Êà¬‰úÿåTzù¹µ@Ÿ™›JXğ¹ú<yrl£µHµ‹].ëÃîânLÂ×ÿdQå75nC·.Õ>ôpı›Ë×uâi×m¹o¾Š„¦VŞ÷P3çù¸›|»?Áqì¬Ë&àŠQ~K†d˜¦-œkë¬Jx	ÒEª^H(Ò‰û¡†
Æì7e¶0JO$c3ù•©Bç{Œ±ğE±rô<w{­ìÿ²øùEÀäÈdB@óá÷WR§õ¾…`-9[Ex¿Û¾f²›&ê¥p„ò&§N5;}ZÖ»m¹K¥MêÕ¹›=Knb)9ïÊZEÚ:İ³«	çöÒ"d WöO{ Ô[×š°7V¸ë³_§ÊQ„?˜Ÿy}ÏŒ°Ö÷_Ô{uâ
Ã¤ªÒïûZ‘\\xuĞBŒ…ÉZ©}qŸ›N¨C]%¨2Œñj4›£b‰)Œ¯•&æyô½È†±(“¹óe[Š<ºX‚ÀûS†XVk;œè6|‰ £Cº3µPšT·9—À¿‡NE3i·GZÙ?±4RËk¤c#ò¼-ókÙ5úàO*`;®Â™½Ÿ4g Uzt™4'oyòÂŸÄÀøµ&õüwnƒOq+Å:».ï¢{ËŒïˆJÜ?°Pys÷ÃK$# cõØ.9@hF†‹?£Î_u.±T¼s"¶ÿ}×6·Ê»‹¢£KÂ¯­ÔØD¿VO––[ø9ÿVLß­tËÿĞ7õOÌÉÑŸ³HğÔ^À;Ô1a2Æ‹÷õˆH¬!)]AÈqi¹(4>Ä\İmßjİráÈc“9VÔkÏñç¹7Zßbÿ±Ñ•\œ.Ø8ÓE¦!KU¼`ÉÑ³"õ õ·2+^ØGwàA'ÌâlÓÇÁáæQæŒ¡çò9Ìšøé±ª•¿-²J­Å5Æ¼„~Z—ûõSá³ëN¿¦VjFuö@}?±-NøäøkF!7şá–÷ª‡‰«‘Ê'#°ÙGÃÇcj_×nôV`u1,èäÑ¾Â¿İ—¡—G2})LJå£BÕo¹íDr(™Vg%¸°·ğéqnH6ƒ\<MÈ)*,d*ÎÔæ‰ºšïËEYKÚZ‘)10Û_ƒÏ†?]l½&ˆØ`—3/¹Ù˜.µ_“«^¸¥‰LVŒçm»c`_ZùJ¹^iU™‰à²ß6Í§’¡„'p™
ÁÜäKSl¥‘b«íc°ªÍ6Ÿ3’wJfóÚqw!Ædå®´èÑ¸èàgm”G É¨tÖûvcĞÀíƒyiw@™yáW>
îÎAÊ‘‹CåšµÖ^”¿9
+¨”„¢„9¬½lHñ?¬úB&«äòá<Ğ<Ì7›.ìî˜×y¶f‘î½çºÛO*C’ê†ræ!Ù™Ò-Ê 8':Yj¸¯æmeœvïƒñMf·»Hû§ÎGB–Ë­ùşÈ¡İ*}¨V±ÔŒÕÀÄ.Ù:8D»ÛL"Ğ©o"kp4÷È–Nˆ\Oè_°	9ƒôûÂA»Í¥çÑ‹I0í!ÆRQğÕ$<·1õ›À\ñcˆo°§µÍI¼^İk¿MZŒcGTKûê'ÿ¢ÁO1¹©ãspóå±%¦Ä¸ğNæ^Õíe$Yş
?o,´
”¯z‹©²²Ù~åšÉ¼ÊªßJÙ}ï}Eé­¬·ï—ŞÁëÀW‰ô¼ Í®ƒ4Ğ½˜Sÿ9&À¬`¨ÿ’Dè·şèl¦nzh¦ ~/¹3:ÿ#œ2öò{âÔ\‹¯2Ï¯6uˆ(Ê²u­j«Ri‡M(¥µé¾Ûeù0u_ï3(nÑ§”ã?ÔCÃ¤ n4xEòÁ»èëùL7Î
ˆ¸î§IïF½BlÛ´ÍÉ¡ESĞü FúÚ¨½m¹ª5„®œÏìv…ÃNSÁTcnÓ§:ŠFàÄÆÒVhÏ`Âsù½¢ÄrgOL½%Ò‡Ã ıãU;ÕÀw˜Àª½MV	ËªòÁÎyãÉ·¬FÍlI~_F„ ßI–àsŒnOã“Ê¡¥¢¥Á[7õñ[
ì¿÷®’¸etgMF²L»s®ÆË¡Ÿ é’·l&Î}ºWìºèÓ İ¹ÏL[WŞ7E0hm9Ö5»U¶ò —cÓ¸o¢¸§éÒèÕ-íÔf
}ùÉ‰ê|”
*¾êĞp
€“Î—¥¨sÏâ½1zÖ¬«}—yîh ‹Š< äÛøŞâTf£¦^]š’ßˆÅF6©¡ÉG¡ö‡H™¼ÌjùlÄ!é×!…˜ı[àˆì¼î)–P¡Ö·»Øşun“°?Fñg®[·¨^óà•Š¤S øõÑ]®~)¾"ıÄ¬sş`l&]LH)ÎP¶ñ‚ˆ€›S>û¬P.†E=k0SÑRJl°z^ú`Àx/­ØS©Á
}‰^…Tö€rLöˆÕ9BàÂi¥ù?"ßë_f>æ­CØÒ‰7iTK£å/{”ë"ó—zIš6EÁ¯‹àƒÛw1Ö;KS¹–®t–<(Öqî3âêæ}›ÇÇÄëÎUrş’U3
“j9•eBZ”§:ÊA…<ˆÄya¾W˜ Ãì×§ cX?päm¦óIáúœChÍ°\:6ô¦»b×Xdü8†®çaÆNd+‡H±dæäH	\óHëÓg^­¥ÙÎ3¤o´¢!ñ	GZ%ä¾ÂÒŠrÖ½][ A!ehPuç ÓÍKÌwüæÔ`I«Ù1½L¼£}†2øÿš`ı<IŸ+¡Ë‡€äDV3g…ÙcVc»ıQÏÓ
âùò„ÂL¸eÃ_ğjõìMâ`™è¬×Æ#ÖĞÃƒšÏ©:*¹XÇ¼O6pÙTá½è
”ƒÏX"T"qj¾êÂêVÒœŠ‹SÚr…ŞÍ“yP-h¸ñç@{P\‘º:ñB»ì‡Ã£)Í˜X?¨÷ìlfÖı^š’4:&ú¹öı±FƒJv^õÇ(ÁÉrZšŒ)R‚²Ş†hNF~© ÉÛS·î¾¸Ç.‚†[™ÇÚÓ~®!2ĞHL½1	g}O»sloHß ¹Yz€ãĞôé•õ¾@‹­Â°L~p7ÉàW‚ÊòKóA¿Şûã]#ÿ•Å‹É5ÿ!º8:bã»®ÙHÒµ ç‡SnHÈésQÌe_¤DWZ¯Yú
,l’Ï¸^=m³ŒŸWĞØWq|Ãé«Â¥µóèŠ¯îIàõ_/¿ò§ĞÊä¬üµ“¿½W8 Dgıí:ú7nGEœøI}È‡V÷sP'r±şûÜS’Ó¦Ckİ­©g$û?(É?Éùş—Ì€õëI8GQíüzHê§¨ÖÃ‹×À§ÿÑ8«„	.1!s ¬¢«£DByıdaäÙb€C®‚ò>©#œ»KëYü•*à¸¨ÂEZKá‹nrI¦ä€cœ€(g»W¹¼Ü
ïÊè*¿î¶_ÍÃÀ×VœşÉïWÚ8s~¦@¯J´éİì ÀÉ%ñ>aÖ…<og½Îı…C©]LàóÙIï~Û˜)ËÏoyÙX„o¸!	$(*
ˆÏÛ¯=!£Ñ*’G‹–STÁ$–ù»Çlğ~jøì3cÜ23V>%46ò/âÇQÑ‘sÏ?óNpÓ›—ë?-Å6üm´îü6œv„X‰ÉÓ3üHf:üä.3ï/Hæ¹ÒC(xù\[ÜJÄ'õi;±ÌÀŸªwƒ2÷`±¦Û|K
¦ùM­$ëëvD‰ø–\ÃT\¡¢rÿ:ªSèóâ±!4µt†mqÊlËíW†pFâßTna»`‘ƒ§8ò™têóhè??Íe5§ÉMÅ½]¢¨ûõıŒ¦Ÿ.d(pÍQóZ™CaÙ³İüÿé»ğáØ6RRSôiğP“YÎ	FRp*ÿ(ã¹àVcyöq¹É“ }\ VíÍ"U YÌf‚aÅ[è×A»bèğ·*Dı^ÇÆ'äß"¨÷v o ¼­q2Ú¡ØĞKC|kßsË®™…ÍÇnµB^~¡ëò	©ø¡XËViÆ—ÔqˆQQï~Ôç¬zsñEÆ¯§Ùùòè:?ÍI"5??tYe«#-a\Îğ#‰ëI9à‘ı÷NÏh.0£şïíJKrœ(8Æ—1û›ığ–Ãİ³‡xÿj)|cÀâŸ¥ši¦¨2Öl<’/?ªŸ_îÈ( CµK“<>Ğ"// ¯ù@¤°©P(Xî äej5Ú‡x­’>óBëair'î!“İÖd©¥Ì
2ª4\ÄX2ÿI1(b÷HÔ3™‘ÁşêÂnWj+MĞ¸ç¿ÔcSœØ…/±O¢ÁåsúA¾´j<FĞı¸	ÕN¶t>Äz‚e7>ŒÁ¨0¶>ü{ÁüôĞ|¡(õÂà‚Æİİ6ÈíÍ&ò_y æjÑTÁö£1&¸@¼üeõN_Á¢+şFÛ¥Ğˆ1ÌØ¼¾@;<ĞøOÌ|ëÒæ§7ò)Ìœ©&3w[.ˆæ¶ú™{ãé@š­ ÕËlÍWãŞ§~9@¥9ÃÌcÀòÅØh–hC\T‰ ’
Fe2d–ozòâ5˜.<ô€°Š¾`ğ@ Áei£Ãû°LNëÕ#_‡ñ^ZªTklöWû­8gÃ†Ğn°à'õ%J1°~¶øE©äbŸ¯iJwVk‚>2;ú
ËîÍûE D¿S—ÒIb„§s—°ê?–—cœ•ÍşŠµL’J[é±Mn+SãŸ²ÉŸÄ92Í{ĞªíÈ—YTWvÊÓZ£µ-,‘[Bw’"“D°Ÿ²ö×"İ§9æ8£ÚEPŞ½Û¿nõ°I-¯IĞ‘áæ¡õ3RIô^™y°	cfwÔG{ÿt¶†|HG”ı´te1ÿÑ²†(šÒKã.Êf–MØukwà¯yáù¹Fş÷t'¼V	]frcÎöÕ\[t¤æOÍİD`T¸;¶/9 r“ƒö‡Êc<sÀt»&ë:ç{7U$®H*D^ÈÅLÖğò` Ô2¤TÊ…ÆƒÎ)ä›%:é¸‹Üù~×ë«ßÈÀçØ*jN$,”4~fÓ5o——v—„O²V}J’;i|›û5ƒÓ[ÆPå ¹ş]úÚ9Ïoa^6ˆMÌá24ú/ÒqÅØŠ÷~¥í¬ĞÛ%[ú"PDÏ¯[ğŒî3Y\H|3ÃVüU¡É¿5‘MÿT÷’¢s}=»½ºcuéÁª`»c!Û›è8+	ïø<‹ĞjHK>µ#4¥º!x°Ò0ôòvÅ|$G8Uâ/öĞ[m,æ¿D¨ßùôÿ2hÛ¨j;¤ĞWÌíBR¯wK¾¥ø³‡[xè´q¶LËâ£ãy0G‡’ıî+	ü Æ±@ëÒä¾/Ms¥Š˜£…o¸L³ëDÙ¨6‘3ûDp›»8 'cÖÃ€şy¬J0k¦)ñíèÛ¦šùAİQÓdÖú0fyNÖ«1^@ş)Öx¢®ÿ¾ßüĞqŸâyì)^ÃVøDpÌíMÆTíÎ •——±“ÀÊœX:R—ñÈ>’œÂ±~§a3Ë ÊŞˆ#Të@,:ár¢®êuÉÔ¶¾F*E‹SØù‹èëx”œLä“ÛfDÕzÀ<$Òf×¡Y2…¸vŒ¥|ñ“ï â‘­Òbë~\3@+Ä`ãÒHX¤{µÛ|WLÄŒÀ¥ö…½{`®œ99"-$ml„wœÔ5ß/T½ò¶MšPr£¸†¼Û+!aÚ“ç…ÏW¾ó!wš@,ßeë‡“İ¢ô¼'¯~`FÔ+p?íjã0lÇ~åe¦0ˆqªÃÙÁŞ^â1T³EÖBÜ'Š¡Ñ·äM+j}—ô\IV¹Ì§»{£ô›25>Ecıß¹2Âm´ÁLÖ±³¯¦¯O‚¬œiêÚ‡Tk
¸@>˜êú” k—>¤ë/á0xÒ®ç¡«C×é¦>”ôÈÙ.g[9LŒ¸•˜øz±aÈ3¢]ëu”[æğ=0/A^‘îp .¾2¸hğĞ¼‰[ä…}+t¥üô,F&«GU×G<fëºz ûĞP~·‹EĞNFº_}rİRs£BW˜a=Ï€ORø¥Ãùk(¾m6øJ­óQÒïl‹`tB#œ'Œ›Åùu“©ó"°©…ÍmĞOÃ§‘‚ÆcÀŸÒ¸bnà¹GÄPÀ€¢™[6…ÅãrKÒáFT1NP\™r|ÛK`|¥h}?›­´	p—Ï÷)†ŸbQù4~N¢:ÔWK5}%¾rÊi‚rUdz÷w¹ìœ“†Hu™nœeüÇABØû
´K,Mpƒ´)R!ÜĞÃ//É]Q´øÂ†u.¯å°#^Abš¿ç=oÕ]iÅ›øÈhOÓş‘¶¶Z
Íœúú«³ÌØS<×{rìÿåÜéŒ÷íP¾j_71§y C¿şÉ7ö#zMKš¾i—;‚S9ëğğ5æ=4uXÊnKßûm}‡åëµ‘.âû¨–D¸ÏAqn¿Äñ±ÿ¬Á^‘<ÎÃ|°~„å;§LnMæV’û×w÷ùx+gÿÛÊİÚ•wHûÈµˆà—Z»Š=ó#¹{YS¢.÷œSè‚WªL?3sÈ³Š·òYb.y<	=fĞÎM9{Céö] w|h›F/5é±u•/Â¢ Ø÷o£3üóŠ¾³âªO	a âázR[«C)A9>Ÿ-‹XxúŞoúNIõ¢±T\æ·L]Çx ¦6”¬3ö—nä+‰öW	1¤-©DşÄm7]Å¨»³³™–!J40¢6½GtÆøRß›ÎÜ¢¹³JˆŸØ´rÃ<¨m‘rfjx£³
7Ëbc¼¾*±ãl¢™ŠI³»%cgØµ)’‡®ã	øô	P¢X_µ^u"
[\AÌ¦b\F]d‰*àãlº¢DDë±,qÇoÔö-}wƒD]oo…‰o5»È.„M’²‰¼Õy÷öæş}[ñ]"Qîm˜yDdâÌä9¢§Éi ûB4™£4Q++V qöRFt¢³] †¦ŞhYÉ§Ù~;0åáK	ÎÜØmÈ[a‹DšæmšĞòÇ[PjÇ€ÆÁYÿÁØQ}ÚáØ%íä)µİ„/ı8—8Ğ`¿ûîÖ¼şäŸ,2ÊiÔp‚Í'E_KëÂ!âxÚœQpÉA¤W†yßŸXuïZ’ì´ç.¾y7`öMø‹­$—¢	dJ†à¸Ø8ñµÅQ@nL²Î¨uİm	:–rL&sï¿òiuh%‘¿Oöf›ÕÓIü=_¡èG>5˜¸šg3Õ2¤½f®¸ÂKaĞÒÇ|O)µO.X“‡Äªyxşª¶W›«ÚN4rŠÎBk§¬­ã¾$˜LQ”„ÁRDéØ>)·QÂchQñd1(c£t_Pš\ìd=õ^$3^kg®f­õ/Ë¤Õ<ÄƒêWZÆ_Ğ¬á—ª¨˜pYP•|oÈ¡Úÿ|xÔğó2‡½‡.÷èäcŞn=ëßtä ş¡—O^<–òBfªû«¾ãÜ{Hû27ÙNOfLäÌ—`rüvQ’<<<»i•==qğİZWRØØÊJX£Á”ß'ú×ODà¾Õ½\ìJ6ÃÛvu»19ÔJëÎU¦¼G	RZ È¾èeûëäÌ~¸0Á(@ûÏ^Œ]"û†©•îm6ÉÒ7íáh6é‚¸ÉÖLÉ¡c¦ò"zúû‡ˆNü;ËDvÖ˜kø ‡š›T\õö‘Á×ìØ›~£ZŸò…Âÿ»ì¶ôÉƒ«W$2å—œ@lâµÄHö×«3«u¶XÕœŒ·N¿9ŞÙOÈò l;*Ì@<•.Â¨fÂ…Q£Œ››#ó ó½1±«æ’“C3îêÉ{8eªë"hî ÂÙ!´×\t
íå}!ZáÉTòû 9ñZä;+×h©!€ñ¤ùÔ;E##¹#ƒÓUxïuÜ®9÷ÀÓAä©I"<kâ—ş	Á}À NJj	cl¶4Ù‘úÁ²ûûWÌ¨-_œŒû<Äqã±´“dO•tîôŞûÏ8ÛCP­»¦£¼°b¢àiTÖ ·uáS½Zû£s\Ñƒ•ÕJÚœ²&‡£–J Œ ì¸øşîØÇ)(;Îïu`‚ßòéz+Í—(
¬ÛQ®²X›jXqÅíä)Àí}]ÙÉÎ‡¿æY½yêü®1—ºHD„pD1SLn±üCGnkê¼íÊİ¯Å##ÙÔoØ©6i§lÌ;‡Ï¤5w©™íĞOñK…[Êªqyñ©1lO:YdÂsè½˜aË7©¥XXŞµ¼wèX´ ~:•Cœ­:´BûWwØoQR=ŸåÀ«î¿HiÜåV˜%Ä¾[œÆtYAnòŞ&¬í",t·æn?Á-TñODt2DFY¥%¸Q1è Éxd_\—$êß±šR8÷»¾x¨>qš¤Ñr°´Ödc(l°£XÊ cÕ#FZ–©ÂÖÚá’D›·…[uW×Ş Ş©2mœ‰Wöc”Ê7•2Á1ÙÚn3k­^øÔLyS4°˜ëV‹¥ö(¥¾'ë:X›ƒká Ğ8Ì>ª8ñ¤.£s–§Dş2i¥¡§
¢÷eîÃÅqáÙÿãm°´±äM³«Ñ JşÍz£ÛÛğ†ßX²iÜ‹i£qx9KE%Î-”ìÌr†@È1‡éEk÷§jŠØ—iû]»¢Rõñ‰\ùÑ|Ã rìUémõ<ARı79„üE¥ÅM§qQ®câ~p%3ıÇà<»òM–ŞÔræl‹E¹UŞèÈY¹LCºi—óüD+¿ékÀ$B˜ÇOí©E)jO@Ãnôª­GMGØ¯éò?ÔÀ]ô˜Êífè™W¼³‚ö&ÍKG›ïöß'ÑJ5æ­ı‘íÛŒ	³Údc’ı'¶æVÈâÈ¨~í˜)-99bFævZÃÉafëüm
J®—RÄğøÏŠío¬„ÿÇ‰'´7ÿŒºåşXF“ë†ôì§Ïr¾ªåŠW‰Ç+šmï§+ÉõğËbX«­€Œ~êl¾ÏÒ“Ô õRäº9iSƒ'œƒ˜`A„+­K+ªƒòxZôşw›„j6—nqÀQxlC‚s€!Àû°æ ïüìôİˆİ£~˜uªÖ—Ï<peÿ43qÂBd¹X¸©Í9:×nß›‰“İÙR¸`ÚWIÿoTc÷N %âıéGw8 a_Õ÷*ıÙ1N‡°Sú3§^nàô=(ˆÄlQg°ÿóS»ØE@º`Bëº\n çÛJJéºıWMF¸ÒÈ´æX=œİuİğ‹‡™ıŒo\.Ë4Ia@šJ:Uz='M¬Ù_ê?KEMğ÷1ãs¦U"´by*Ov##<NîN‡‚$ª öğ~Bò |â’E[áUdñ§˜±¹¡”ë}§ê©Ñÿ[M0ÎJı1ãNU°´Yğ÷»!¯1LŸ`¦üVØçî©9èÊŒ‹2…éÑLGoÚõ6
©x­é1¡;«‚Ç
ÁÛiJ7|“m1ù¬äãïŸ,1+¬÷ñåC¿tïSĞ…é§OCØëÉWñà[{cácEIìŸıÑ	éuCg’ğ¯M`AïLĞQeKğÃ dA\í_jcŒíh	êgsø:;ıB±’¡š"¥[¥Æ,/&±À±U‚ÿƒto¿XOåç›ÄS™Y|¯ÿ¯Ë ¥AÓb#]À¦Èù„ä¡Û¥<Ğ½zŠPâB(¼W‘ĞW™‹‚*_£å"MB‰__îÒ;vÖ”ÄN( ãgÆÌœ"‚ÜÈÖb¡qÄ\¨Ú¸™"ñ&w™\·ÈÔ¢òÿnÉ`r0P•Á-ùôà42G#]%bâËOÛ™Sò;Å¯01.ğ”¡}&õÓŸ†[ÁNÿr–oì¹HôÒ;í“vËêß¸ÕMtìSîfËŠëŠÄ£/ÊŞÇûŸß¸m—à»ó+¤'nQ†&[ÆÓïÆAª±ñ0sMGˆ¡Ti'Tš3·eÙÒ´«•2±²ƒ(,WşzÚ‰m5†î–ø'»}Çü«Oå:õHd\O*šë>®Jÿ'†	è	ıJ=ÅèÔ¾®õì¡)Ë ìh¥o‚ÀV±Iö™iQ]ÀJôÑ‚ÜğÆØYSOàX¡®¹Íe4úí%Û:ÿ¡ís:şh³Ú¹Æ¹û°°Ò¨¢xà¾ÁøˆKÁ¾ÿ»‰rÏ§ù·‚¶o©<ÇºvFÀ/^3,¿AdwHMÓ´txŞ NAfz7'f2ÈB„ é‡¡à„ ¥Ò4Ta—ú|yÙeö(f}&ä
äÎ/O…mmg—™¯Öâ‘Ö(Ey+¤dğè»¬«îAEC’Zw: Ô¸·’<ëí‰&´Â`eyœÑs*õ?¦ÚQqi§6a ‹›)Lõ‰ÌAC|—w2<¨óA¨|‹Ó±é/ì=(&ì¨ –°ÙPƒë	‰\‚°d÷Õ|0 »799î{°W¹‚––½„ Pë¸ Şâà|P	RÈLD'›TsÇ¤)Ñn“=Í
³M7zy6M4nó—Ó©ĞZ.; ¢2ú3ı~1áqé/–º)w±jş Šß‹Jµãş“TV÷~ÎÀÔ·ˆÕ*1õÅÙî6fİÇs<y€†)/ëô?>Ag2ÕLf#õ«©3ˆ¢‘o?¨6WõH\%{¸;µ&„×®í/ü®²	ŠØ~RavâÒ§ÜI”j8î›şÏ‡É‹òŞ.šRP±œçÅåƒH2~»â][™ÑÔ‚dÌ“®¹t(óÈé Á=Vâàâ½úß<?TiğÍ½Â_ê¹dêöf	(šŞº…5²ÄD;¨¥tPE ‚çÂÀ+0]Ì¤9ù÷åÜšdo¯µú¾àr-xéG±AWÕ—«¥0e¿6¶šâšmW^á ‘‡T›2÷
‹ST^—7ä½¼¿\­¶ëÜ§éx¿¿f@Us„AŒ—}ùêaWCæ ,fQf•‚Í +´sÎÓ\$A0çË=ÂãÂ½îĞº1U4özŒø:AŒÓ=jn?v"µ¸pôwP.s7kİ[Œ K!v&Q¿ı,‚^!J˜u~"gÁÛmZU´4™ğ”<KëÜİám¬,­©û­úıù¹z¯8µ§_8â,%±Í$/å_›82úïLá~6É¹eê«ˆÃOå[ƒ¹Ó•oŠèbÎ^\éäæ¸u‚únú=kG3ì2A;Cm0,o˜¿tµH¼Å®Y–<?ğÊÚ+®n}ë9"’	‚Í]Èk7ğá‹N¬R-6‰‡%çO5˜×ö°£~ùœ­Ä[Ãß$Z¹³ìô1œÀŠ$toÁ>Ç%$!#šŒçç$ß,:Ìù]v5´ˆ>§è¾º´ı¹/¯|•ÁPî%âN¶]©•7	¨ğI9¶¹KM#£ŞÄñá(“t¡ğX`N`UJÇIüŒt	Í€Á<}WL1Ëêcâ.*Z±oR*÷MM0¸¬ÚGcd”úHßùw>ë]Ü†<ÁÜŠ«‰¦Z¿‡ùV7$·†û”Ó5õ*RfS.[	KGÍÕ6ÒíÓôRñB°™ËÜƒşNZµÑ!X28’>CÖós:PúT„|‰›ï¢'Íñ+¡ÇU›ĞP##æ\•ªkzö7¾–Óµãm¼yÕcÜ´B€²rÆR¶øÒÑa³Úà¥p;I/I@ÌŞZeP‘¡]®Ë<âÉl²‹Ûˆ1:,Kf
µœah|ƒr¤_gš¼÷eÇ
Úõ¿ùe<Àl0•	ùwˆmåU`Ÿ™Ÿnn#ÍõÇèş°;ÕÎØ½wl5ÀQñĞôÇ›&¨)–0É¥‚ó4ízßiôİ”Íf•£š;!b|úÀuü£ˆ§‰òëÁ
…ü6‰ƒäYú¢;Üö¾˜¾Éèe{Æ–ÀÿŞ™½­H\P«w.„ï?ÌâIá•eV9»ç ¾Íô¶Ùq®fH	ç9¡CÆ9Ï«vsã˜/”hm'Š?˜[Â=A8cÎÓ_¬ÁTŞ±¸Û$]Ù­]qğó93î]RY’‚„.Ó}¨pœsöKìïÇ;:V´—k\ouG‰µÔ„f#‰¨öûEÇ+ÃÊF+ĞébĞpsº/tÿÊ’2NøOïÖ*ÓÈÏ÷¶‘,¼f45’¿á—¨³ü¸Ü¥’"è4ŸÊß>`Uaİ¥P-ˆ½<;ê¨‚ÎÕ\¶Wó¥àkĞşxs 17t·Äy¿#x›î®äõñêHbÂ]íßÃ²/}PqÕaBw‹ú.£«Icãn=…*ÉY¼9KaYŞx¨Á•›ÿ4Ù”=ï˜EÁÍºT¾8Â~ı,ìp1åV&K¼»Ûì·>¾ğ‹ÓæÂyˆØ
áû8"„]T¬Öp >•(„î?åÿëÕ–>ÒÙziç’™+`Õ¾BÒ¿,F
éVìû¿T!m¤ª<ÁºÙ†ˆLfb†¾“ûÉñ¨LršÍøİûo“ôáF å	Á’l•Ã|ô>ÙÛ50LßætR,a‚pìŠmJ]¸i9%|³§æ˜×‰-‡›Œ€­v4ñÒˆÚĞÚä'Œê3alªR^ôœ“×£€y*ğk‚‹ÏjQí~|sœp ã¿p’ø%F=¼ìÒ‡‘RB:`€Ùê˜f_/@Q3^ÖlÃRU¦iQ†İC·¥K#Sì;§ø4Š¸áÌ®íÜ\w‘Z¬a¤7&¤lA’QW€)Jrqí7:Db+Ş§úªèÔ¤(‡ßÜÆØ´eÊQŒ‹«‚ATÎÌ^pkŸÍ7Ù{ÈìmhÔÒÁÒŒi*Ø˜Œ
À
+øÄƒX²-2˜âÙ˜0ZBš=i[s	W›Áv«@7š¥ÿß­Æ¿f0Œ”®_ŞDÌ»óøg&Oğ¹œ
ğ3áÇ™IwÀOkìtEìq…?õ0İƒE‚ç‡8E!1ù‹Ö«Ş3‰QığÎoìŒ<kcëúu''b£ ­"aÒàÁß…óÃÇ5pí¥ uïZU€ß:ÿ4WÑÜd•ã0­ ëº'õº>[/x¦Yİæ…¡Ø¨K¯³™{;³7âcô®î7:P«\-â˜ã,ĞÑõ‹ˆ%L=Á7%óT’Z·©yñ8x/ŒJs%ñ˜.6ômQ@—»;ÒÏ÷Œ—!M¸\¿ÅˆVzØåş©²¶¿.¡ĞØ&‘ÿN"3;Í
ğÑ‡N1@‡FNØ&t+æ6n	UÚÓZ ÿÑ	Ù´¥¾ŞÄN?ı7A`ÅÄ6rìñ°V´ı½Ği‰÷|Gß˜Û¬E(kYéP˜²¿¡Ã¼j	ªŞÉ¥Äÿ¥\…#_G@{s ¹3>¿æ¬Úu_€|³®ôs¨x@ExªŸ‰CUg{×yÓ«…auÚ…,ı˜u¥âš*¸-É°³ç=dÕğûô¬=E;Ûv-áß`…ÎêTn…Ø+ÓÏæÚÌŞ\º+nrò»øŒÏ°5Wkq~ËLÏĞ§@4œîVtF¦*uù¥Ü*¦mò/ûû Wú§Ì>K–¯ğ"P?¿-ßïÜĞmç@’²ÉŒ½á(õ1ØÄ×7ñôƒ£|ËÖø;XÄ¦õÈU¾Ôb2Ù{˜Yù£¡ºÀäöiº¡œa¥µT/z?Ñ9'-ø„qaàöEix)^×¶P2ªÏµŸGÚÅ}W8‡¢õ4Äãñ¿7K œ_fu#Üä,A#>vZ…#×ÈW?t!ìxCS0H0ş…¡asü¾ç™èï,Ç1ı”t‘-¡=àD.fLâêm$Mµù“‰Äa©i—ü¤Ô¸Jõe1¨‡ ¢ödo¸Õ#XqÏfŸJùÉáGñü÷\Z‡Yº?ˆ»ÆÀˆq?ì¡ÚñLêü±Xj.¤Ìš¡¡1GÍ Å’{GRhn¹ãI)õO<Ÿ…Æ½ıxL¥şêÓ;Îã¨ÑäX®ÖÚ^¦”jo5P}ªAË†aXØrß¤Rês—şÈ‰ ŸG¥³>­•›‘B?¦±ø!ÊÍ(?£€´ªCO"úËrìS§ä$iE×\° 
:ö	,áWWsıW¦x"É‹9¾zX»Ù 1Æ”‚ÃFÉòAe‡¿kàw2Y¸¾…‰IxiêåLñô­š/ü‘A«İOÆàñòszÜÔ p¶7ÿYİğÜÿD·KÅI¤ŸDØUº/ƒ³1‚ñö &Ëëª‹}ÃF	Øê‚ûTGs§‚ÑN+O³!ÓtÔ8ëŠ4zä€Æ"¥OÏPñ¥˜¯û¢~oYOÛ¶Yÿ]]¬íø_`›“ÃìğNìÿÉ¬¨Åê^RÈÒ»épñ¯§,¼§1 ~ƒá¤xCŞ])
É]¹>oÛhŸÆp­daæ.&ÚŞxŠ‘e±bëšnH7ŠpGfıÊòR"Ò¢à±OE+Kò¿w”ˆ¬P Pÿ$kd–õæ°Jë>³Âï©èäúò"·Âa*Í!¾KA__ËR‰¦ø	†d×M¿o%w0#‰³ÉÀâZ=sñôP$Ä:'~[GW[aĞšU§ñ¨mWòà- ò«˜ƒ›d”¦[r•tÜTè«c[ò¼£¢CXß]Åœ£
¤i
³Ú3ö2Õ#ë·-njØªa"QdŠwÀ¯ÍğÈ üpGÎY•µñGülÜÅ©vëõã¥·#¹Ğ¤ }!\1)¶€rÌÄg°v¡£ZÖµ#=Kæ5 ¶xÑ*²DÁ×ÃãĞ'‡ÖÁéWÜT‚~' ë®ô“‡Qzƒƒm¸!á˜^n)<¾ø¼oéEŞÛu¢TŸxê2ñ˜CUÜ^ÈêëÀ=šò@
²@z!Â–yJá-2hìğ§ò4íó"âPS§=±=S³–£ŸIäke'	ãê4–ôQÿİµ–FåjÈ•sÆnaöµè)I0?h_ óÓtôßsÍAÒ†§V6õfRÇËË]hqë!HH
ğšú	å±¯U¨Ì+V•0×v-"B@Şõ’Ë€ùµ‡=Z+¯,#ÍLu•êµÓDşÖƒŞvv/÷’P˜`È9ucIÒÃOÎÀZšQŒšñ*º¬hUFbÖù/•Óg¸ßÅïkÅ>:qÒËÓ1™<ÇsTÙ&.²8X İÄ^:3ÌŞûy)»?
–ÙHUñ;ÏV)N¬~*ŸÒ,ğ¸ X5Éaï, J@
‡£tUïÒïW¬hï K}[AÒ##bÃŠùP=jóÕ@©È¸0j"·÷ußG1õ^MÀ(´AS‰›&ÖE:ù(\Ç¬£j¢ ¸ñYöâ` .ñ7šš˜!][u¥ş´qÍ"Ó»¸¶Êÿ7òÅ.{¶®r›,aYñf‰F%”<¾~®Ü÷#Ÿ§  G«ÇäVÍ¬|DÆê$“F‹ÄÔêBœıX¥~ä/g¹æÛI»óÜ¨!àô×Ø İVÔ=Ùá¹8…Í‚Yˆ<¤ˆRCŠĞ’÷®µ,ˆ(•›ŞÃ:»´Œä6€Œæsï)ëŠÍø~ğN¯Møb¤&ÎÅ%_¯ê÷‘7d¹To{ô®Ú"ƒg!DVe£İF˜š¸±×Nò*GtÿAŠ«‰OÇVtşZ
ëMºY[ñQÀŞè$S±Ãå§wÇ{Úïopœºaÿ5 ƒ‘ÜD>ÇK|y+|ÉómxÍa2SÏğ_åF¦¾/zÀ¿‡Û¯€ÆñÕs@1•Şè'§äFE‹µĞuå2¨UA-IèùR~uÔd,¯(OfW=wÉ´æ/·­Â0÷mÍ]È'm´#‚œ‚ë~Ğ
Ÿ9‘†b­jtÜuÉ©ÓêmA­°½L¥½&¥–é§ÙÙ˜±º›uFœ†§â\g¯ocp‚O~^qÂo.£uoknÕÌ¬'H¦äY$d¾L‘ƒXøœû2cF)ˆ…èŒ€FëÑ C6%£ê–áfY2ÀÜÂ‡qí£²ËHÅ[0‚á8fÛ÷C¸ôı6™¢-*;t#D2]´ÑU?ëî¡Å¬ğº·åº‰²ÔhHºµof˜^îÉëÅÌijâiph^^°i„ÆNñ’Ö#';(¶Œx—D€·mR ÈAfäÀ6B­¥ÿ/¤æS„¥ê•ğò¤¿´ıi‚üMR.m¾	_ó&WË¡-S½2ÚÍ‹c­±HeaÈN4¯x4ƒÄ%åB&Ù¾%‘J$›áN§QıVÒ‘@Ì™ü-÷XjÏà-×¬î~XÓ’á\MksQÑèC3f½¼ì¶”Kùu¼®º#~î¦ŠØ¦$YrÂÖwn
¥Üw¿<©AJPâ'=0ÔDF)ko² ™*\”)¶ tÀ¢Ö%‚§Í
‹•œ#‹_Íœr„PŒF.6ØDtV°ö«¬ N3m™iP#š>x¢ª3oH8¯Asf†ğÒİåC¼¿P÷@¬†4¢ÇL)âÜËMŸŸš&–S_ÖU’½õò0wO$!_'BQ¶ğ×¢ê>›íI7œÍ lˆQw7V?Ü¥æô ½Ş˜G¦È»Ù+â¼ùá„îËÂ¨©8v#˜ùº]ÕóÉ™Lq-peã9…ıqa§ošyW[¤á°‰¡(YµX½Ë)ìŠ¡RË;D}åÖ_f£gøFöLxğšÌbQéØ	˜ÙIPÈÑ<ş=4Ì°Á¸T¯ó{šF½ôøÍpjÅvWµëÔ	€xÁWÊ‚ÊY»®|*•Éª:&!õ­‹ü@Î+º.x“A%V¡§˜ÃÎ¦2vªYµ„ç©±,ãGˆmü‚µ
ÜÅuË·Ë04RÊïğ:âíz¢Æ…Ÿ;*~Œ2>¸/Ç'p|ÕD×†kZ´ =ÿè$–¸,¼tiJ ÓfªÊó@Ó-S*Á‚§Ñ†ôü‚#¸3ĞTA¯™utšBĞ¨nÖ—'ÙÒ}f{ğ¦âÊû-Ş1¥ÙFD¯ÔÒ®¼8Âœ£wö1«PQ´Òu±úŒvÌÒuÛ-Bµe±â×öV£BÚ Šh¡#LTëè
ƒRÈ†“’‘eˆWù.3çRŸ²H÷A´Ğ•Ë;Ç¹­/ÊÓÆW¸¨².œÙ­!×`ª=µ²à¯JÏû,Çprvg‹õaŸÍ‰¯bQÈ“­]ÏIàäH­ßFyˆºIëÓÀé@’ZŒÒÕÓ|ÂÉI}å=ôõÄó×—©ªJ6š+‰d‹Gğ~z3>—½‰/ïeÂ`H­0¿Tï íjˆ½Ôû¥Ö“‘\ĞÜm*¿³ñQŸÜYâéH"Zã±`'»Ì µõğrQ-»÷‚5íÈÜïœ“BÛÍÓ^8ìNÄ­³äç•”?Gã›ÆeÜæhĞ£\+›­Ïƒ{Jüİ¦Ê{£WpvÑRrË?ş³“Õ…ğÜ(Òé‘Ğ³ÀG¢ˆà°I)É‘°ãûÛ¶F/'é^"¹Ô×ÅàÂígÈò®Jáwz´ÀS|Ï}ì¢µ#e  ¿ı'ü™š¿Q$0µ–åqÊµ­XJvfmo=ÍÙØB`[ÎÀ8›0V"Âú°êl•Í‹‘QCÛåÏíyH°icò”êíO…Bá§êí^;dîêâ\Ôì5¦ïi—zıæz¿öJ$íõ×™†ÇØ‡¯§•$Ïj"q£í¥	HˆM&­÷†;–Òca«S „í7X“‘C}#ïÇTM½[@e–“¡SÁõ×Šct9bĞÏH*±§y	ıZ§t¦Ôy«FØ%ó2Øj‘oÉÄÈŸ“òï£m(™-·«CÊâÍÓR¢õ(*?z¯1o¬t¼n¯pHù;8™çĞŒxª :Ä–„Éo¡«Jç@+]úO—gƒ[²~g Å²1MåaWB} ”Wë´FŒ¢áÆ¸º°cîF×~1!"ğEá,Etï·L“ØÿV“„Ëó† cƒÀ-p¾s·0¬ßõÏnäí=«6ZÉ©oI“r;wÆ»sOn7w§™á9ØµÖ¥ww|Ò€’¶QØ«Ûİ”FÃ©Ó%t–Áä÷Ç Ò`â¶{'gÿ[‚r|¼™Òu¨œ5YÔø`Ø\°Kèğ¡~ô©úU¤J×VùØ¤µå
qr-¡§oí½ìoWÆÔšæt`.Ğ<©0
iö’‚ï(Ãÿ‹’’€œø]î“02—N, LT¤v»,»Ú¨š™A%û
ˆç§r(-Î€„O[Ô¡!c†Ô6t=ãëJÓñ‰î?&OŞ‡aš5Øg°º˜êº”ãÒpà°6„A	DF÷.^›JDƒ|ø…-ß9ÏV!†cã÷y®Ap—KÕ™B§D8¢­¤<yTÎ™«Î‰Íåğ‹Âï»w)À¯‘N)1âáXÀÖ–Ö6Ó,vÊ@Ñàü‹¸r°(ÓWÊ3®èLF«Úğa¢í6AÈÅÏ©óÛ¢»Ê`»ÙyİúşEoa9;.ƒ¾ná÷Ümojˆ·´7mé›o÷†/Óê@0<NÚyú;H)mx†MòEã9÷ó ÷J^/{c²\‚-176J;Ç”[>˜Ü¯ı÷(ü~˜Õh€xÊÈ1ØDÌ˜6ïçiŞ>"Ÿ÷ˆË`“åk »	)ŞÊ–Ğïq¼{øÉYsÈlŠ™ûG}pêEQgg2&ª: ¸ÎwåZãBµk_:¯TÀ1V‰ 5›„yãîß.R>KşöĞ6¿êÌ?Ö"”×Rè7›1¬ˆ>*F'Sn¯  §ö#É?"Éœ–-'°®›~-Êˆyõ¹›ÿ9j6C6©’ß†‚¼×H00ÓæA°ıo•>éÌ®¼>#Uæg%ŒùXmg0AaAñ¾[2÷°p)ôkšË»F@Ié+8!××“.“M5ª8¡È¯›
`®¹ V‚ÖçXsÕ§*÷ªí^Ş­	¤u1C4Üêk¿
Cô ì2r·ÌÌ&÷Ì<?–ŞíûéšhÒ¬R`nˆñÿ¼>òMÂtg7WÊ˜kùš¦ëe~;>,ş áEªz²Ÿp|œqÓn§qFPmmĞ‰¯|8r­ã§d+,‚bºø@		zFT
½:Sâ”OæòyßT×!
IZxä…O!¸<ş1»ÕÂ5^§Ê³?œB¢Ì|£ü–¤‰rñ!c-îúœbÙÙ˜¸ù¦úÇê¦ï— ÖW\6"éÆ (3[¤Ğjè7Î~ÆTİk8kV›ô²9Ï{ô¨Š……KÏ^°Åˆ™ñA+®;hâlÃ¥IÉÖÎ0)õ¼0'·îDÀr~€ÕĞGaËŸv}>{¿ppÛç”ÊW[•±4psfÀ,™N< “±Dƒ‚Ärf¸Í /ÄÉ)‰Æ·JC$$–§³ÀÍKl“>¹š¿ş²ôÄ[l¿Y\X15ÉŒf’fíÒKº„ÉÙÚVâ8G1ßd|?|óG:Í=ó™‚\r=ùvVÓ@@y0˜Ë`fóNˆµf	õb•]w=Ğ,w4.g ûÆ¾8‰Œí¡UıÒ Â²ÓZ¥ÊÖa‚$çš¥ÆñŠñv#vm<
‹>ß·J2*SaòAˆ÷rr4øa0Jì|ªNÓéß¡’g©|¤’÷ßW±G™iô‹cÔá Îrá]$M¡(nBí*[,ÿ2Ÿî]ÙhÎËâ éïoÔaêf ºAh8ãBGæAª ‘ñ?O!tˆªñ(·õu,`èe«Ü˜ùúj=ŞBğè|åÕòÌ;ô° [ş/¹9¤[5=~vVQvıÚx±EFiÓ™`zÄU@œ+6{23«SAÖb9Q:{xÁ4ŠëNˆ}ø~s:sÃPgT8İWh¾DŒT5­“ëüÍÁæ<‘Õ1((Ã¡2b×‰¸[;ŞLÿ_Ğ­“Lh‡|²ÙË¯è°×İ°Y?’k§~}ÁOpô€÷¢)|¢`µ:öè‚· n¬¹ó'¯ÿS†¨6õlèd+M[QãŠNn9Ú¾¥À I4qPPè±DêLëD;ñ Ê(oò£´˜´vº¢•jOß &ã5ÌÅÒÚÖ5špçÅwõ€ê Ú1^N„ß¤N¹ö7AªÕ»w_'”ûàgGVÑ´€¨Q'¬öÃ¸%&…;b[©:/^*³4@yzA¡\gƒÚ’œ§7û7ÄÏä£Då`À’ã‹ã:4ëP Hhû3kÅ!œUÁkÆiW_ş+%(ÜŞ0÷ƒ+^b¡h#M×ïmÃÄ,$ùdÒqQµŸZÏ[2İÚÖ “å"„-šÒ‰Óğöš³‡eÙ}Ğàª@C€Ï=J}ÒƒD²ê
 ‚Wÿ¦ø” ÇÔPÑjÑq&jÖÉşM=H«õ¯!\lÑ8±í¡,¾È‹9¨ŞLÙı:†ó¹¸ú_wl
WECÊøñ»‰IÆ´ı0ÿ?»ÆÕü‰ÃzÄL=¤{‘l‰}[yüèâxî˜.¢QØ«èÁ—£3…¡¬¨¾ÅŞE	:I@I¨'©ÁÏLáäf¨¥ş²†,Ì¤sÉå:ZØØš.ÈÏ{àGªÂL¼TÉx›ë	Œ5·¨&âíŒ<ü€—çæ€™+­3j|’sec¬9º¢ëæ¯Õ|@Çø' /0‡ô•ÄÇÁ×Y
'Vğëƒ­‡-ÏËÉc‹ƒ³Œ;7}~.ØX±$äôÿÃ±VÈöÕ4 ªÑlÀ¼( »ıZXÊúåvæ‹)I­sò4Ô±@ân«]o¯³õ³K?á_¤J‹¡<ÖÅŸ«Un–&µ³bñØº´íJv}Jo®½åû:­¾Q—FşªFßûÆâş|ÜÎô¨‡ÛÜ%:<¥/Ü"ş±<œğı<Ãó¾0q0(˜3fOÖÏ}äâ%€¨¤î…‰úC®{cn¬åJ_m&ˆC óU;·¸Ü1vâV®Ü€æ?ë¾=ô§$fª‹©Fy¦_,mš¹ğDÌ/M‹QuËXvƒ`Ï³¬P×q5ÃLïB,˜„–®0’¼ûmŞ0ñÃIÂáïóZd´©tœ1R“ö8öoÖ@õ/l±½Ò(Û«U]d8,—@ª—µc¥¾ª 'mœÑäÏAwŸ¼Šo VËÃ1ÇŞıZŞÛ{x¿la‘ÄSf_†bYZ<‚f[bL¡fÅ2jIöAX¦ìİŞV£ÙñÉÆõjVòTeÿ<h»¯Lµ·]Ş5¼€™ğºœô›w9¤Rs
)Ì¼ŸÚÊPÇlåû^vÛÏ¦r	È—­7†k}ãÚ*Š!çTÏ}d ú!dÔªFÿ/¼;›¿³
å8ªá `fNı§	r­z#Xı3òVâe¿7à[µ>ò.ï%uV³†ïª$µ%Ú¼‘Û2œ+
wV­¤½eül'Eão½6í¡Ï×{áÂ1ıLJ,Úb üAÒæJ»¨|L+hZı Xî8°ã=œ$xØ#.eFIQXf†7ÌQ./{:ÌQû>º£6ˆ’ñÉ‘D-×! m<}ºò­İİ¾:>ÚSÓX90_^~CâÀh4§'R¼7¸×ÔÏÖÓ¶Š¾c¼&[Qo~Ì%äq©	BI5Âœ¯°ºıŸÓ:¦X*Ó{øUQŞtœd2kjñÜj™œıj»ö×u©‰)=ã5_BŠEÏQ«7ø…oöaSäÔu¡ôKµÏU³A@º>Ï¦(R¼"´ñ§R‹Õ†[ªGvœÕÆ`Ğà©dËÏEÕÚZÉEBàN—9wÊ[íÕâ nÏ|áp¿BREdüyÿõzğÀL\yÁgéZ(š!-QhÄ<~6˜—v4ë½¡Åí?ƒp¥/h:Lz‡"ŸDRO'ëÁLX),"T æŠ¥c <«Ö€9Á‡»I.ı¶&îˆ@X!Ì§øğ6Šöí2Glä‡²e„S-:¤3eo¿íÅZ§>Ÿ1¾JDI¡%7¥iÓDJ5ñ®LõŞ;’€ÂÄá©@EùƒNµUwó³µ¨²o·cõTQ©éË’İvKĞHÀ‡Xƒit²bölAŞŸ5A@d~:êºí6¿^cŸ+7d ŒŸiÖåNîqÊuÿße[Æç‚ †g»%FÈŒ‚aò–·
‡öñÎM½Xï"ßty†÷wÈõ¯ZœŠïã%œË€¢ë]ÂŠOÍ•ëôŞ­ºí'Ÿ¬zƒÙ½Ñ†ª¶ Ñ6O…>>âHz¸P¬Ÿr¹ø}ot01b¨…Âÿcaô­àËª¿ÀÖŠ››ß[€ÕÀ¼›`Ti@ÁZ.…“…‹1F|éqZÕGzîÑ¼
­LˆIÄğ‡Åªf oRçY®èGõº§ÔÃ›jƒƒ)»¹ÁÄÂ7úöeÂ]ZáJ´]MîÌ 
ãéêØu/ÎHáš·0GYiî)f²‡T(iŒ /"˜=W÷ï5š¸g¿êAùì«‡XR<`<)î¹+Ô:|u5DrLG*³µ§ÏN[‰ÙøRÀ¬Ï;Y/[é[
Ü~YMx¸¼êo‚!_V˜(à›èèØF¾oBÛ} qYëd6eˆı;ó'«gc¥Æ´¶h‰¸Æ~Ó™|¶?«ü8Y¦©Z–eh°Œwˆp¼1¬^egØJÆ¶ÆĞñ‰Âò€ü®[é[¼OĞœÍßxŸeÆN¶VÕåÓ¹Š†şN¸ÌÚ-zo¾·ïlü¥8hE²ŞI*“ }ôI2xQ=Ş…
ÑĞ¨R•#¢;³Xå"Hã6rRwÃÄÖ@Şé-@R¤H¾8İ[ÿáâdOĞ²Iÿqzï&[M…ÕR¤jQ9OR.ùÙ¯I²¬~íbåë=œ)6ïylğ’TİçJ³:!LàğÀì:"¸ÉŞTà´˜qüqÁ~¼uÜ[ğ4y.é]ô=¦8tzpß(®õ¤, öé¼ƒš{vŒ|øxLÕ²ËÙQlr°Ï ¥Ñjƒ¬J(Jf€ŸtVWÍdí#a	N±|Ğ°y•‰Ş*É,<((€eöéUì3w1,S © ½ì2Ù>s¦íÉ?ç«eD®.µv€@mÕÁ÷HôÌÏa$ò½Æ@Ÿ
X¾sşÙ©^il€}¤!¾u€NÍ|Z/šæJ¿]á;l$&øæ\Ì“º¸º>^ÊŸ> ş^’]ö„ºªI÷v€éE„sûw/õÒ<q†WdE]MÎ×èg9ôj6šúVL•¹zkâ¦en¥7šúª!Rÿ¤©áıh¶1}0È<µ—¦ËÓU8R¼×ü7– yÚûâÜ…]iøt“eÊ@Â€&Kš¢ç‰YØj!:2V_Õ“¸@¿ÀZĞVë.‹×zuQ-Ùş<x@j÷;Ø4p€±Rï²·Z“ı¸štÎN—0F/›}»ŠLnXaË¼TNs–PsÁáïâ$¬¡ğ7çß3à¸ ªITD‚¨Ö«=ÕUÈªëˆ9_2d9ÆŒ€©‹Á÷ÎVÈ"!Õo¸İTäí¦Õ	şĞtóR¬Z¨Ğû¿sÒ)hûƒEEµ5ØÊ&gl»%à]§Á™ÑBX=vşÍÕĞc‹7pàigŒÁ±~h‘†İŞ;Õ“»¢ôÏ¢w{	ø¿İW3ÚÔõè/†®Ûï‘O21ö¥ê© b¾Œ."Nbû„?>+§g½X ‹Õ{éGXz&•´™0ÛîÉ.Îízãû#ï0Àr5¾<é8/¿õ~|)ïsQlH¿öïR»_•p÷V!x…1ËÏÙ¾³„ÑLnä­!l0¤Ëil—¾¨è”/4ª‘½Òao•f©Ô,¨BY8³
İó¾Ï…ÿœJS€TÁÇX`Óvìû;sĞ6¼¸BKÁ\Œ¼¬£;#ø¶_K-"î¬º»øË#jí¥\’Ïn(´”¸wJïEqEû­qµ‰¤è #Mä¯¢tàıå™­ëŠ»ä{|8£W;À¶‚-9î)RnqÒ($)V‰Q1Œá·„”º1zuQ}B“Æl.¬s•|bVÉ·ÈX›ĞØ¥®YÒ¸ÅàL9y»÷ÆSñvĞ6ûˆÜGq|‹Ï™–<†ª
=òÓ‡ŞËq™j§ ¼+Võ¹ò_9H¤zÇzµ³³|şßt‘"‚¾w_Û
¿x+˜æÙôB?÷˜Çµô©n›½©¨¦ÒGPËàB@ØCHfÉàä<&™ûG¼¿~é8¨ä@
I´ÒrŞ¾‚Of4	ài©r³F§'}‚dö@a"
æ­®SJ#=4˜‡ÃìyÇIÒ+n87µe*şíÖ¹Mgñ.—s…›§èeœ²÷6oÔ4JÇm(	©!OÙ~³	Şÿ‹È[‹Ha…ï$ŒŞøÇJ‘L4[Ò¾§‹¯@­t1qæÄ;¢t4\ì×£êqè3«õ¤TŸ¿¤JåÊİåz¢îTBÔö«}ãñìåCšìâ¨´‘#(–‡…l~FN%äoX°*HÉŒÇ¨‹ë‘çsd^P=1Ç¦ròNí'®[9>òBZ[Áä×Êş+£PlFéŒ}Å‡.ÎlÚ!À)ç¦ë(lÁ ,)‘lÆs¢o¸;«{{ß°–U¦fÉ#+Wî©×Šrß*Sı­–}-x¨-«~ìæ(&¯3Ta6fğğ1<[©T—lGÓúB÷_w1™=•‡*ëÏ2;‡+qÓ[J±.Šˆ8A6Ê"ˆJº³/v®ìJbK/Oÿà«TB !§š9&Tk®*»hr~ù‚³œ	b"sºyåƒ©Ó=ÿ}‡F²=¶®ÏóĞjØiû„ìAM‹Ba÷Vã<I©fÚ¿×)VÓnAı‹1ë“EÏá¿Ï{èØœq' ™âdBö‘dg¯"à±Q3‰²å2|h‡ÑB²_‹}ìSá®PŠ ×J¡( ØRjk±#P¥Úï'ŒÕµLyªƒÈìeû»I€Fàü†°ßu”oIª}9]V¿çD:¤ét{:V)Z<¶Nô†_UÁdùĞø]Áø‡D®dîMÏËOeì4‘ €ÄÃuX^şù:­;f[g78ïš‹k?‡8´°|µñ4KU…¼Ù×²(0p%{@Xº1zËÚlxû ©1™yç!}nİ¦ÅËtœúeñÙš“µ…»?S;£gY>Á¨è,»‚?‚[«C¬^Ãv ¼zD©`w10ÚKŒ«‚Ôé¡Gúã‚AÍvf²Ó|0•õ\wOœ¬~Œ-ØqdîùWz¦‡&ÊWğãõ‰Uš‡f#ûfüˆÔ†øµ£òWÙ"8‹¼7¯*‡zèIüª0!ı ÷c\å‘Öši©„ãt¸ÁÔíÀ®KI_ıôÆŒ+â¥½ÄtÌ Şí5öÆ;Ó×0÷O½M	Z¼8yoºÍ‚?Ó²ÊñauÉöí¦¸ç˜‘
%,Lbã‹Õ—ÄÍoDEŞ­K®ØĞMï‡š‚u¨øõİÔâ—_ßF}âG9æŞúÁ@+şÉ	ñıÔ-2aá}óÇÔ×cô–R/lA¸Î™²­OƒªıhP=¾¬búªA¢Ü{1Aç‚ÿ±—e\v‡\¼É•5Ù0ãZÃT0=Í@ğÆDq6Ú&Şµ¶t®OmÉ¹ş¶â‘¼q3ö­w8PÕçÌ–TTØó+N=´°q{Ù¿ŸR»DêSEÑ®µrcu”kéGh£‘wˆ=_lœFiï¾ú~²tp¼†K²`ş
ºé¡ËƒR²… ¾”¨«CzÔ¨“ÂV}1÷ßq",    #.–@S^~ Ê¹€Àb½æb±Ägû    YZ