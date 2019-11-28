#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="500824836"
MD5="d36b7cf4b5b5f46411d9eacae821ef04"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21417"
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
	echo Date of packaging: Thu Nov 28 19:52:18 -03 2019
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
‹ £Oà]ì<ívÛ6²ù+>J©'qZŠ’c;­]v¯"ËÛÒ•ä$İ$G‡!™1Er	R¶ëõ¾Ëûc`!/vg ~€e;i“İ»7úa‰À`0Ì7@×õŸıÓ€ÏÓímün>İnÈßÉçAóÉöÓFcëéÎÖæƒF³±¹ùôÙ~ğ>Í€–éºW·ÀİÕÿôS×sq1^˜®9§Á¿dÿ·lmös§¹ı€4¾îÿgÿT¿Ñ'¶«OLv¦TµÏı©*ÕS×^Ò€Ù–iQ2£L‡ÀÏc3ôÈaà1æ‘G-gab6”jÛ‹FwÉpjSwJIÛ[øt)Õ—ˆÈswI£ş¤şD©îÃˆ]ÒlèÍm}³ÑüZ(›¶"ÔèŒU–v•ØŒøfoFBèzÅßG­ãW0=ª“Ñ€	48À$éû4 3/ *á:¤Ù.ˆ’Sggêá¤B/}hßï<;=4Éckp84ÔÚc5iÀÅŒãîÉpÔ::2VH4ÁÛ½AÇPÓöÓagÜÑyİigsuNFÁxÔw^wGYsf?kŸ*ÊUŠ¡Æ@ÃètÀJõõv@§¡\ùÛPÅ‘7Dƒ}«õ_íëµâZTònwÎU*åäã0˜ßatD­±®ã:÷ümÎN>¾!ÊÌVÖ³¸–\B¸Â@ªA˜€|k¦Şbá¹;£|kc‡ğó@wÛ¢L¦]ø¶CÙ£k¢T^éáÂ×óĞõ©çÎ€WÈ*,ÖƒìÁªn`ÂöÀXƒ}±g‘å‘]L`spÊhĞeCh
”ÊÔ‰NÃ©>¼È'%ó€úbXü[`û™è]ênä81Õµ?‘oÒHvSY»¦RÔñ¹sÎø´.½è‡	èl<ƒF`~SPøy`»–QÛ„y C¨jB‹ZK@ÔrŠÊ	J§ifm\çj×ø¥ë)Zı†T|,&¡g™ÀCF<Øá Ì˜¿Áê	åMW–ñwD…Ìg )Êœ†Ï@ÚÇû|Ù‚Lgf¦	•U5¬¥¿‰v©¦³"7¯s@ß®G™‘n( ÒÊv˜wj6‘ğ©%JY{œ*•¬óµ?­µï96hÃ;3Âó¹ò9ıszI§„ºK²ßöZ¿µøyİ:=ïº#hË~“O§Op•Ôr–­È^.L~@ªÀÁîzi‡¤^¯«{5­”Ã¯W¹StBZ\?®˜¯4–RÔ.’k”T©d’ˆA¦&b%nŠesSXI·•7ÆÄ.LÛM)Uğ‰“Õe¨çÏîS©dš¬t¾O¢NM”9‘ç·Ê3˜ÌÎ(H9áŠ¬TdàäÃrøVÔ¤%¾~ÖÇÿà…CÛ“!ÄÁ!µêáeøâÿ­­µù&{ùøÿÉÓæ×øÿK|{h“"Fs6iW©4IÏÏÇ´9ĞdåW”ÊÈ#qüÈ‡~ÏÆ.¦kÁøJ>µ"ß‚à_'à¥Ğ_ó‹é Fîß‘ÿ777·
ú¿Õl|ÕÿÿÌü¿Z%£çİ!9èu|CÔÖ;nº±ıJÚ½“ƒîáé ³O&Wù(	FzY˜WÜÆ@àE¼(„0ÇæQXpõ=™À³éB&	±O@eÏlÈI ˜a|Ü„Çca=_XÍï}3`"ª“•bAxä×ƒÈUªò8Â'š&F[Ô±6†…Œ&“;×…yNufÄæÏÈ,ğ`@Ğ5ƒè˜ÎvÉYúlW×“auÛÓ¿LQAÉêrVóV{«A>CÄÊ‘å—¾é2Ñ™	¯¢Ìì€ÁæL§Ït(p¦NŞj‡a?ğŞôyESòV?ì¾Zå/iÿyÉáß¬şßln­ÿÉıŸbáU›D¶cÑ ÎÎ¾`ü›½µâÿ7Ÿ~õÿ_ëÿŸXÿoê›OÖÕÿ‹‚~Ï3€\0õÜĞ„Ô‡pdø¶ƒùw@æÔ¥;H !Ší‚_Ä£‚Öàxù”è¤Õ´Ÿïli¤åZg[_È±+U‹†tš£à|øX™ùÓ83-“¸é·	ÖM,Ë-?ü=°Í¥My±Ò\Ll,x)<@:è·±î\Q*7Å=´Y8ŒÚ£´l3ÑºKÃ,3,ä§pÀz^X}¬N"7ŒHó‡ºú Ó
&–?Ç.½G`ì„Œ—]÷öø°#Û.É1ÄP¤ùãıGRfN•”œfFÆ“z£ŞÈã9a¡†šDdléÖg…È¢§îslÒ‹zhÎ™P‡âñ“qcÜP%L€e|Ô}6î·FÏUX ;ör¨ªÖ>8LÀ‡ ¢qÒêÓÙ¼ˆrĞ9ê´†C½uâ—Á°Û;1â%Ş‹,½&T3®#Š­?K[÷ZÒÖ­K‚^ìNO@’e\ş°3MsPP´¹­¬+-ğW¹8€Ä”f®¼¨Vz<…øãêpn
„Ê°`À.º”¼}O¼I`ÏÍğÃ?A£0(à°è’§‰>'Ì^L>üÓ±§Ÿ»BğäFrÃxÏÌæ_Äq‰Æn_üêà—ƒ¤†\Âïuìø„©âµñ¿’îJ˜_ ºt^wÀì\œÙÓ3äöâTE“±mÄ•rµ–¤ƒ¨êêÙI9æ"GµuSİo®û-ÑáúE‘^©òŒ7=OàŒ‹*ä»´BBÈOÏ•U8<AÂ#p²8İhpzò‚¤†|„£°ØŸc-’m³ŞĞ&àÔl¼
W»^iûö­öø&‡:>Š‰ÁşÜíÇG¦[Gİ“Ó×ãç½ãvfBt
ËcH‡„yøòdÔ:¼áÆ±dÆ›º¼WuĞÇúü7µdu© –NŸÊåõêBoJ°áÑF,×¥ø Ô"ªâ §„u+My’3ÇP[]{ˆxH‡ğ‚ÊúQ ÍÅ
äÅ‹…	€PLx¸¢<Ã¦6Æ9­`!NyÏLwN³sû•…Šİ"%’uW*XÛ S°ğè}ÅNƒådş#©-“vÿt<j;#ÃØëU³Ø9RIo˜ö‹ˆŠ´½áP ¶}€zù´E´öìåAÿå•$Â×tº¯Ü™ŠàB•/7f W
e·¤*RÉî$HâØ;´;‚£’†9°fˆ^+
6?‰AÈ‡ßl?a‰ÚïYI÷Ş÷§—;ÜG–§s[#¯A°€iÏ{7&à" ğ‚]r h™´ÿš¬>µë“Şà¸ut£aµl¸b«T²ÄÁWÓcÓZ©ö«Z ÓÔ~»\ÎÖBU’õeì_’Ïì+ /ëàrfµz Ğ
6ˆp$*	Øe]hÓ³­R}¸!+Ùni·ï¡&Ÿ¿DòóÚñü`EÚË¨»M ÖŞÏ¸‡<MJ’ñè1G3ÁR2±ÂM¹“ŸÛ&|,—ª·}Hò[‡‹È‘œì¹ y¹u/šãÛØ&rÇl"*ÈÚ-lÃÌa[<ó¼p¦Ï•-¹@ÈğBƒ=„Tâö¶Ô&]u98jzh4['ûƒ^wËQáÎƒŒSñ$dÍÍ–¨¾Djxâìj—ÀÛ?…œœç3BRúrŞ–ÄVåË#	±»úY6®T†Å¤oNÏÍ9w¿sĞ:=Á7JmûE’°Û®E/ù¥—$$µk¾©ñ¾w7½Ö\@™pøk•ıß¾şË¯1q„iÔ²Á•ıaeàÛë¿[;«õÿíí§_ïÿ?®ÿ.°ô«™ÎÂüë¿$½ ®Åç%Ïzğ€2ßs™=q(¯ír„xĞ›»Ø¨‹ÇÄëÄe%¼®V¯n—~;´ñÌ9¢i(Õ¸’eò»–tIÏçíß(8dĞëÆØŸ9Áo0¯%.a¸ÿB.ç€™h~€û>:Îïgâ¥GµÔ“x(ó*ÓZÀ4Á[“ë ô€úÃ]¶ñålQ‚„pJnŸW’‡¨äg¾{>‚îº&ˆMkÿYèZtÉ¹IˆØn8#‡§Ï†¿GcÃP#6Q¿'­Ñhpm[/©kyÁ4ÿô²s²ßü}Ç½ı¡6vvvàápĞ;íªïDsÀ«¾uòWÙ(Åøï8ŠŸ¥o7µ˜Ò:oB–xIÀË˜!P<-ÆcU®!K›fğ—È^z¨Á©˜ø‡\÷¼gL²”Ü•Teñ“+#rÆ›¯¾Í"`å¨o†gÆú‚¥æå¢*—“ŠĞ%±H"ö°ò-ªÆéjàa[?M3!Mjµ{ k'±F¨r$R‹¦4EIã<E<½¶’û-âzd¼›ÔœØZÜ}àÔR¥Õ]ë\÷3sµ`z­Õ@'“Åë¸M`LØ“ 9‚ß–Sgoˆ÷¸CÏs †|G/'j«ş£îP¨‹nQeˆËb•ÊCí ÊoüY
#¯G`‚o±œÓğáGĞÂ˜ tŠ]¥ë¨…ßŠ’ÕÁ¢Hb[Hª YxCŒHr¢#,B¥Â¸nÙ.µ]¼È\ÀÉ™$Doïx¢•ˆrÅİ¨3éHMîÁ¬¯™Q©	.Vh.(.lû¡Æ‚ÂÓ÷f¦Ç–8xhA’áZHœãÆÕ”„>•¨u*!i±>®V·,¬:ÇB¯xèü¸	ğEK|lX´Ü”SE^l2 µ˜"*Ñg<Lj ¼¶‹wk‡ƒÖşQG ‘{üêº`óBˆIşÑgéãN$ïH¤Ä¨÷!ˆ‡¼(€•ÕİVk2Té9]Jü.Kaé|·¥½ÎõŠWWH1ÏOŞV‰½1ÒiÔä'ğb?²vòh$n2k9’;p”íL-5(?cq¿oEÃ|	’œ‘Ëh*…-LÈ«ğ¢<3A×[M|Èc=¤Ë§x=)#‚F1î_ã3w˜p€ïağcF¯¸¥Ú‹ÀÒ¼7“şˆEf`{D\ÓÒ›zÉ_j$&€aefC•ÌŞ…Kƒ–ã¤‘8õ\ç*¾¾­!†Dúª…
@¬¬äac.ÜØñ‰êÔX”§]hD„5•xì˜¿Å.cáY–\Ø¿™AìíÄj»û1ƒáñÏ­Áé_òxvÔÆ8)¤¬¥"*Æ™³fÒ4¥º_Ö›êyYg¼–5½œHQVïäQa0„ç¼¾ş-®ĞMÈK0â„D$‰êñî¾—P§<zd=û§ÚuUbÎ›Çïnöìï¾Û r£Ÿ84½d0ûİ`ñFIw³ŸD¬+î öËZâÜ9—Èô]…·#¦#oŞ’Ë@;kCÜ>ºTµ‚(wğ¦ÄALÊU(M9õP\òz™.¤ye­üôDíº3o÷TåZŒƒv‹¥Û´Ÿ\xÁ9óÍ)™ûª7x1„p¸“ÁÅõXV6WÌ:3&ı'ù~0goİCğòÍY.³w´?–²6£VhŸŒ²K¼3Æ˜öçŸ9†£^ïh˜A­4qÀ“}éŒTzàòeš´©1…6F69D±˜Œ‡§ı~o02n%Uì$—MMâní~m@F„¯P„ƒ4d*æsï^ƒX©ñ‹u±„©é]…“Ş¨{ğëxá¦¸AğMá
A‚ÀGˆØ[÷ù™p‘]R&^oİõ²•õİS®`ÎŞáîİ¼Hmxœÿåäì¥¸jı+÷Öå/ß‚Íæ±DÇ$[f“êF£fl=şNŞ1´K.·¸İô}'}ï!«S~ ƒ/(Èõaß`#QÊ¾Ç÷]ˆ2 ca!Ë—rî;±pJ÷¤xa/¨î‹ú +­»Ü{´˜7g·-ÊÎCÏçvfÀßì‹fÒÁ—GŞ‰ÜE=1ÔÈ¶DMM½=-v>¢Ú¹¤ÓÜÑh¡Èİ4$xaWšÈ¨4˜”ûx>y†*‹rx—±å¤u§è²òp0¬^·¡‹ñ(*ˆØØ0 «C#7¢ÁÂvMÇ˜™ a¢éÊ§F+Û·˜m”9©¸³í­BHÃ9„<âpôbïğ´¼¶çÀÅ=a÷qM‘ÿê¸í˜ŒÙ}ÛÉÉ
ée¨_jâáŠŒõŞƒkâŸ(”÷Ù.V:Y9 lÎ·´‘©ÒF,oœç{¦EaRÇ¼«|A¯ÀÖXÌµå½¾Xrè  4~‡µ'¸³—gÒÈ–}È4¯vw_k/ö;Ú	,eI;—!åïİ¼Ëöï¿‡!†|¼á¥éDÔ¨ÓøãkMÜ­Õğ-_ VÛ÷ğ5i#Ñ‰s|[iÂÖ»­ñqçätÜu“„¿T§0Ï=ƒ|wIÊÆA·_ÚÓ ÏáB<Şï_Œz}~R@@:¼©mŠê}@gé{QgÔñës×[P~·Ô´@®uvÅBºĞøƒ6l‹¢öLa!´X»A€¼Ğ"HâëgáÂ©£¡IiËÔIØìtsCırá|”%Š³%>;ü2±üHÈ=P¤Cc6g£?Âş&³ƒ÷`ÜÛğú%¤¢â, uİ“.O”²ÓxÂï‰J0ÊÂ²&ÑgØ@t DÉ”¶ï±PœØKQºçXã¼»5Ô»]²ºâ1Š†2õgùS"˜\ÛGT«äÈ^fY
P•{µ<Ì*‰©+A–0ì½¹4“È•²k±ï—;µÚu¯ß9ù¢ß¸x~£pß[çš¹° &%7È~òÃº‘›Ÿ;(UMÚBsa@¢˜#íÍAX…ĞÇ)Pâ!˜éñ‚ÿ’‚¥#ÉxÓJ¤U‘JÖ~üüV‡_s’¦‹X{ğõN ,…ü”ll*92?üÃ%0üÿ©$›;—ÀÖ®óÔ2ØlÕ%€0-9ß“W¼%Èß ¡rÇñ‡(“^ğıÇS4)9¡}á¬„1Ç2éÈ{•jÌÚŒO şãÿ¿p@™qg%)ùãG¡IhÅ>‡KK÷/˜÷¥’:ãØøûs¡ñ*Ì0Ã
0á3ğEµD¤.b+yi_œX½á¯CC>C¡¸¶˜·¥^aX"òÃÈqb6ó.Íİa	‡446ãD:Œ©8 x–:n¡œd÷ã£‘ŒàWvÁ÷ƒODó$_5¶¥Õ‘Õ‰{ÿ;Å]u¢`Ñ%§‡?ºú‘UWÊ˜âßÅ3ÂÏTxJ÷ğxD]så¸VhàL©Å“‹‡ß:“·ø®òÚ¬» ­ccô¬eN%ÕòègmNÔÖ¨’Ï!·#È]ÎNëF$V;5¹N¾J˜dŞÄ!w/e-²ì¬RYMJ1ªàêFA¿.¯ÄˆZÂœÆg+ÿTå³YÃ„[Óë,úßö¾­¹m$Yó¼¿¢rZ’×$EJ¾ŒezF¶h·¦eI!Jİ3cu0 ’Ñ&	 ”¬v{ÿË>Ø‡}™‰}8ûØıÇ63ë‚* @RjÙã³KFØ"ºWVUV^¾<“J8ÔCÃWı$E‚íÔVS/²zË~ñOU¦E(Ùç·ÿ3LĞ¯æ§«­•ÆŒˆRÉW”æ(™pP‡—/é·ÿÉ.½ŸCôdÈ)!8ÖJÍ;])éQÕóÃ<ğØTâEÀ´V)%šôà’Ò	2»
ÓwFÙÍŒº‘+®ÓÛú;è1,º£ƒ¿¢Lèè{B’znoŒµ \ÅPÀÁÑñBù/ÂT2õúÅ0:ƒ=-fğ‚·W4æähU©"`ßkßôŸR-\Ám+ÓŞ¬®ÂáÂ#œ˜·YÌÔôİÒ>Ùrf£²=+«­õútŒÎ7Æ¨ÌIktİ\%ğTä"k£Šî–ú;§¢º±Ò<}‹UŸşØôW
‰æåÄ†Xs*Ëù—¨İ<F«/¹êÜP6g *ÒˆÒÕ1áœPÁ¨š,¨ã¥¶ğ`ô/jdo ©ZDºÉŒFKœp€kz­5™d‹el$ç#õd)½êñy1‘Á7f…iÍÃM-F
ú³É Ÿ&r\H×Î~‚½N‹ÁÈç_†	şú1G,Á|8IâïËd5Rÿœ÷Ãóóì×t"¾ãõ²øvnÔêûm.w!?ı×ğÆ	×÷óÿŠñ¥8¸¦¹Ÿ8ù‰?Bëxñ]Ú´¯YU,­$Õ¾ª$~Ä«¼ç%ÄÑ2àb2„sÑ˜¤üšrˆ±wÖ¿$}d·ßaåß	–E×şqÊûøSE
Âayµ¯¢ÒÑ{ïÑfH#_Q¾Æ¿Â_Ï÷é+0¨ü)”Õšß~"&„¾É—ÓT}ÅO†ĞØ¹®6Úømâú;õ§#ñ¨„Eü—uŞıIMÄYìµ7À.Æ#"
¤”8ÁÕ}™}IÓ‰6b0¤x´iáğ"=i_E–là¯‚³ĞÒ ’£±ğ/,½ŒÅí¸¹ÃMb²¬¡0ŠQ—>/ã¯Èi–l1:Si1r!1°/ÇÉì38#·›µÄ}ÜıËmòyu	Ê:/çJsaÄ©¼œšæ¸E—•Îª§M•°;Í[ÕwAW²úf£uJ³ 5~áîEügk½(¿r“
…Ù…ê–#³
ù”7éèSÑĞ—Ü*u²kËNèLFWr.™€ |ıxV×á‚d±íâæR}3%œö¸¾ëÏˆ°<7¸=mş¹İ1_»–*ù]ÜFy•…¡Q©ò±éz
*åF"9ã»ü^jÃb•d¥(†ofMiA´Vî""ğ‚øÜßL´o2Ù½–UÒÌí’¢™BnÄŠ_‘ÎK`ÜÚGKj<p'÷Ù¢éÅ‚‹Gıh’&¸G7»õÁ‰5« šÈ¦s—â"w2Ö9…Z.şÂ¨ŒYÿW«*4IÁæª	t'@„†&DŒÄáoàEO<ßÃÇšŞŞû|›èÌºV˜çÅÄe™=w±øœ¾VIÅïã¦PhİâğBÜ|Ù(&gÓ±Ï­Í°üj™Å”<½õ,œ^lH_]ùeƒ´Íù¡M¾íì3ÖÉNúD»…ù–òò2Ó™/‹×)‡¿ó¼Zğ ½åÂIòh3šÅÜl±ŒÒæ²æTæÌ%Ø~fˆCÃFæ1Á”'¦.H’{^HLí bgSá‡C££^grçëuw÷_÷ÊS:NÁÅú6~Axñäü‰g¸ôXvã¢3£[‘TNjÆ©-»S)¦Z¥s¶–Á~aÈİ»Ió´Y+BÅ4›xÿ­“bÖ-{‰ä¸¿í½‘Û‘İëÈâtTô92]#ép4ÛßènÜòŞFğ{*îûÚè|jº+ó|ƒn—“ûİ2¯ğr>“”r;ÊM f“ªÏ”í
ö;g
Ú2{®fuÚÚùş¯G á!–}]ÓMRnì*v;O1‹‹Ø{ˆ-î FkC3“½ÎÍM» jÎÛËÓOšhç˜G+e‘àv±È¥Üª¡¿hÄ/İ¾³+¿·sJ7Ûş±xR~Ò%6Ì"Æ¹mvÌ
t"qaÊoöW7¶Š˜K
4†ß·ÃJò‚•àgˆh@N	GÜËs$g©­'Â«f—°¡YNåÅUn¡QÅj¬•c r|³5	Wä÷ùŞµ0^?&¯ºz@´îş÷(x•ªé³'ó<%‘¨nTbCë³Ë„T‘{;øühûèoYÁòèzZËŞb5UŠj5ô•rsE«—@ğWk÷×Vr/(Š‘+  ¨˜co/ É	r£É—=‹éxXÌ—ßÊyˆ>®•şÃÉ¾e·JäG<GEÂã~T	éšŠ6à	‰¼ »&Wlcƒ)T²¥“¿¶¶dETßwæ•&FÚ^}C|PÑ‘q@_j²¦õåÏ?~Z±Ú•¬BqŒ«L7y.Ïˆ›Ú^qy\ÁVVZëãKƒm_yö'´8–>jn«±îÂ`ù°ÉtÜ“ãWõ'îŸS/Ÿñ…ÈTuÇ—aÑÿ€ÀOzçï³=^[†WÇ-ÆOİæ»h4	æ¦)ŒÓ¤øWÿ
	Ÿ»¢,!B¤á{£@•U¶ge™Ÿ5-m¤WÏš¢/º¥[~ŒÄÖh5ñ
²‚#^0=/`\¼˜m±I40ù¶Ö‘¥|abİ¼‡*M2Bq>÷P­­JÏÂªë8'´ó·}‚Ò]#À_ØtÖgg2`Ok«0/ßñš[YcTN¥Úš]€a¦àÊš!_»4_	Æ%­—©6Ê(94¨	Y›7m?ÖÅÂª¹ï02§hcO6r¥”èO±¤]<å´¾¢ÁqæĞ8¥¦8i–¯¡q ;‹gÁÄ›”$ì¤i¶ ¥Gî/Å=Á,¶EÅ.œüáüVpÑß=äD¤ŸkäÛ_ÁÈo|–‘GV¶a9û%ãÿµ6Ú›­Bü¯Ö2şÇÿmşÛe†ÿ¶Şh™øoô7#Ì×˜Ãh¤yl·{l—‡³àƒÎ—†ØƒÕF¡®àÎ7x/Şƒ/”ËÒ
Õ|Œ7§úzïàÅöû~ûhÚ{¼Ú—Ñ0ŠÑåSF©ş¾{´ÓíÔVNƒ·­­öhE…³}Ôİ;à¯ÖáİFö®wòâo·wğõ¦z¼ß}}´{,²´²äHVUcy×7Ê¤d›FÂí¿Ÿì©6³çiV4o÷÷^~×CÖÉm^zÜrÃŸ¼¿À#ÕkÙSo‚òÅ$MÌWoğ. —xÒLŠYUõóÆ¾ë¬9É;à.ØS,4¿ïC¸3%ıe<*ugÅCàÁXnNÕOtç±19sÊh™D€mr` úÜî(¬p0x€jgŸˆ0Ó#ÄdNy:ó§¨&¦)»aÓ oŸñ˜Ù*²—nÀ±Ò:u™‰æ~Ïeß<k€À¸Ê/M9å*IîŸO0´
e÷wÁº®µ°Û$ÊD7xĞæãÀİYi5QY¬hô”Nã1œëÂQı<š}Å¬Åğıt
íÀá¡Èİ;+ûûİË˜™CæÖÚÅ7¤q>x´ÌN!QhV–2ÖB×Œ„¡ˆË‹¬ë‚ÛsÈº"úJòZŠ'N?/ñÜÇ¯zñEÂøPÂ¸Êß4’‰0àªß£C•hËKØÂ`7í¬ÖV{È= ÿ\Ã	ª©8†k@ëâ·D·! *”¾Áä=:«k6üæ›Ü jÀTT§=ÕZŠØ®¢É§2L¬K>ĞªÒÚGøÚl6›ìÓšu/RàmŸ/
`Sá‘k*UÎ
…öXp›o½úÏÛõ¿¯×ÿ¸õãš‰¤ã¹0-ÌÃEğyÃ	¬Áéñølæ[•u@¶®¼}„4(ÛI‘N¸´±pÃ¡iŞ™d±EV6½Ã½İããîNûèhûoXª˜ÊF•MN~sĞµİP²Tlr¦JzÇYZá0ãĞ§Òæpsx.7›LØ4	WèƒÇŞ5©¤DŞ¤…5
@c¡RòÎÏé”66µì;ïFV’Ş 9sZêL•QÍ-,j)îeFÀóá£R*&¥¯l(†&x	núg×èéPäL(•%Ã@[º6e˜[Ùì	·'¬«Skm©ßjÃŠÊòƒ	×}§¶¡ŠÁ˜Še@Öğá’I-+¦^ŠHˆe,/-#eÄwN"ÌDîõê!4Œ×Gô‘K×rxì~S°‰q,&ı$b<{ÎÅMÎ¨7ğF°CÂq‚n^â7Íàã3'÷+1©N&Ò`áqnÚ:Ì”¨Fnsbøy|«3%³ün]"è•—²†”ó‡3Wl+X ÉkŸ£hR´ÀŒİ4+S!—i9C«KÀ¾–ÎŸoÕ}[¶ùPåJO$²À8ÜQ)ie‹ºš@ÕŞ‡k¦ÑqF2›Î(aÖµ›‘e¦ı}3£ì™˜cèçÎœä…nFkr«Í³¢2‘#5´Êº:ú®F@kãíÆà†ôö»Á
Sz£‚Î¦å¼oéıWåmK-º™s­6VÉ	ÖQ¥r€pÚ]Äy£p¸%46Ç¹ç&áhÀ‰‚Àš‘*ò&ŞÎ¦©õM‚aÄÑ:5,3YEÜ¬®ã“ûõûZ%ÉÁ#›s Ï8¼„)¿’Óq®[°¾’ĞóoÚ0\ø?İ™hò…¼#¢`&tr'©`ftÜÁ/‚T[­B <"9Lçyà'ÄºğØåùP/\•qI¥9û€Õë0qïëˆ•€oYM¥
²PU¶¤¥lD;'iMãÆAJ 5dót}Ç×Q2â{®åŞJÛù÷İMGŒ"Í‡:(k’¢L‚ ìp;÷±uã<‰£A$Qò€ÑÖ4Š n‰wŒˆ<€²~û¸FÏB´¢Áè…iÂÃ]êÅ4¹ÎíSë…‰È’Î˜-Ãäo‚¤ºv*Ü­¼]ÿQ¾%t¾z‡¤sˆHÀ˜SØÀtÎµŸ}ÓbÕ`üïSÒEæ° 8±PÓ	J{¦,b±GP³OÛ^˜Rü„Z‹{(T*ØªÖ–	Š(º‰'ÃÔêó3ñp2×G#æÁ"„İ?ÕACÕ`Lq®Ö¯8áutUŸ½)¶(EW„À_Ë'îÃÒõóğC}b,§eÃU2OYõpâÃ ÅA¢&*É/mR±íµJ¢…SàTàaw±È~K'Ú}œ1ÑXEl¯â›ëº¾¢çæÖ~bÏy+»7O5‰@²Ÿ0+ôi<è‹Äÿ4q÷±ßˆÿóğq;ÿgã!<Zê–ñßoÿı¡-ş«Sù‚~^ÊXïF(wQ
øãkÁr4ó“/Ù½:‰4P†sİœçHV¢#7[Ç¸9DÍ/ôƒ>š	uì˜Æ™ßj–ôÒñÀ’ƒ[¥¸cÜ<
u™ºŠœŸ#Î ;úL˜51ÉFg­¬z|.¡br·7	>¤Ú"‡Ğ„kÖi<
«}´'@åòÍÊ1ÕZô$¼ºH¢RB1ìîœ±;q¹]1|ˆhb–¥Æ-«ªào«×Gí·xäJÉƒ„
± ˆ‰ <Àš%´ü[xåÁ/mşo ³¡óR¶@i”B•®d²©"‡¤õĞ×T	©/	Ÿk„BWä«{¨áHsÏî2ùÙhÉò86M.‘Ioöª·÷çÖ‹ifW*RenÀ
kØK½tšp›¼‡³í¦ó­›*K¤~øÿø¤Gš9%O&!Ë2ä¡ñ[Ù«ıƒşë“]¾âÅ)¾Ş’7M#–fÊ_Õ!O•#YâåÑ‹GŞÏÁ¯>$æûí?~ûß°J“è,FñÊ‡™[¿Ù$<™ˆ‡"iuVYmµÚ¬×€Ö[Ów{¡Lá1·ş,ï HâÄ©+ÄH2”»U #ZA«fT¥“/údéSU[BH®Fb³)¨"b¢¤¹ôMş–Ò¸Š-@&ÃŠeˆk¹W|*MmHFªh)1ÎñËwÁà}—ÄrPM4Ï¤¸oë÷j>.	ãæßÛ{Çİ£ıíãİï»*.šÚm8á?•Ã¼Â
ğzc7Íˆ:p­SZ¥AûZ÷Öí;†fhÓ	–¬s–: 5åËZÉËQL
c„ãä]tE„%GC1~õÆº9lÎhìw»;ı“CÜİºx2uZYğğÛ	ÎBú¾Ş<˜ã¿ì|ÇDgï½xúD‚­fn÷IşÏ¦“ÎÛ§ÙÛû|æÅ]RøƒÃ1~ñTİ,›ûDZ7%¼…ÿ€M:ìyŠVëŠÚL	ÔÎfBwjòÁŞqO÷@=áŒ¦ŒH''¹«¡!ÇROhm“i?r
y±»½ß€`z=4)uK93kkùÈúì§ØşĞe®­6©¬õÃÄÒ	yR-^NÃ£äãé™Å4ÉÎ> âš÷ù×¾ïP5
5¼ËÊêß—¢§ão¾ˆÖkÎ½#ß!¢ïÉX=çşÚ×‰!]>²{¾ÇXâ…Ì§ˆU¿ı‡É¹É‘®l8t
»…ÀÍ}Q½;%0úş0Mòp´âpFõúd_jyü±~6?a«uŸN± “ ıËQ÷	#9û¹7¦>‚¡xâ%;üÉ	¨ÎKßõq–PíÍ·ÿ=}‹ˆƒ5%…$3¦“›_V2Tl8+Ui„Ê-!²€ÚU\–¢Æ¹*aVs¢=™Ã¸P©+Œb·v’X€èÉ`S«r¢ÖÁyÔ©…˜ütÜK£É·a´ÅõÂŞ)ë
¤V0|ÓùËö÷ÛÜ§Ë­eÉTí¢ 2CÔ¸í\sBmjbM•¢ÙTmi\³fR£dÊ’cñƒIâˆ;êQÌäbNñXVéhÒYiÂÿ¸¬ñ^F‡Y/Ã_¦{õŞöo6O™¿Txƒ"Ö±C•÷™"yÎdé"ÓÜšà	Ô”Èß3‰7RdpDÂÆÌÏãö‡¶$¹{òlÿ=jt&oK(IIÛÄOŠ,•¼ˆ«nNh^çYr‚sÃ<O¢.¨–­1\"üòA¾|!†¹dÍZ¸¥Õlí±òv¿“¡æ`ø5Çh©4Ï¼ä¶Ñüéì s¶RH ¤YáAN6Š-ËÆï86Öê¨íí¾èÉû¡ö¾æşÇ'd‰I€oI\`±TÃœ„~„¨ÿ£ £„¼êùOàs
´C}m˜½Õ1øGŸ uM]¾ØNzİ>sMém©A*sã õ&ÃJFƒª|–“£½,n?­ñ¾rÍ{:6Kã¨Ô–Èªæföv_v÷{İŒŞÑö›.0Şx«×‡á '´k£>ÅQ!”u…ş’?úEiõª€M—9¬õÍöşöëîQÿå›­â·°âKÚ„ËôÇ[Ò÷w[Ö—»*Ù“íÌ,º-hj•G Vı^á6­õøİFKÅÕ}ìV2_6A‡ø”Ó{'CÑ6_'–÷œµ|¤º€e0Ê‰/ºÂ˜Jš‚R” —aKˆèòÜĞ@¢ÍìÓnUr¨ö+n+Gİ½îv¯Ûl<=C0¹k¯ÑÖÔ^A¹ùAI9wd–`Œv†³”¨ÕÑÑ2 %éÌîf‰ˆ JFU	*óÎ”n~ü\³DwÖ8Î,õNtÍ&”Å%T	”_˜TÎpàà¯sÔ~C@	iæÀoë£ÈGp(5Dõp–2Ìà6w€§¦']™B¯äÅÆKõ‡¶LÅ£¹KU[g‚ (°°&³wÙşw%r	Æ#Ÿ{á£&©ôkaX
Õ¢ šÈ(W‡$•Ï¥b‘weôº{Ì5}¯áÀ=4Äğä•Œ‰¥İ.Bh/:«î`Ü£+ƒpˆ¾ Ã,^²zÄYyªxÕ«ñ0ÖŒ¬ÃaY8šfa^0„í7øœÅ³º…1>Ù‚ÑšNMíÓãŒÈö•ÄÆÁô†D;?‹5PŸ¢Ét8Äá<–_û¨Şkf5yÊ[œìùy¼YÌ¾cT9äÄãÇYıè²dŒtØ¼±°.£y™¤ç¶u¨ÊWéíu“V‰ë]°ì·Çéq^˜êóœú'½¿©H[Z©„›†Xli7xtYĞö¢áqû@>0R“5³ÒÆÂµ6J«5jUÛhÎ‹Äã”[ê™c¬6I0bBé…FÂPÂØ‹Ğğ2™"CËAÉt¥ÂŒÂe:*ˆ«ÕéÊÙ7Û¯w‘'Ù>ìïîïtÿÚYgU†&AŒWR¡î®Wš‘qcì¦¿ı3#´Ú&ƒd3!5Áa€ü¼	Ú–ÄÑğ%cxŸäÂlÀñö‘`ÑU·ÈÙ	x¿—ç¢¹˜],İÜşÉŒ·&g¼Ò˜MvÍÎ+hÛ>bz„¶YƒÖfÕÙ rSğ…F…ĞğRÒ‚úáğÇƒşÁ´‡coØf«ğîÑAO'éšCÑ¤¿ï
¾¡Ğ¼¦OÇ?‡#±}sïsãhËÍ‡rç»Å(:')¶P«wİ0¶ˆ²›IEm¨¹ZœuS7U*®”µ¾d8½…3({¯ëqöÈJ!m¦æ[k¦bËü8›mL“eK…ªwŠŠivva	îCJft@`¢œ|÷µòå9B­®³ŞîëİıcØ½¸÷á;`ãmMWo¾ É}ÉæwW±aÊøŠôŒ“Ú8LµU:c/r˜Ué¶)¨æÕv}“ÇÃW¨‘Hş# ç$èSêu7n?l´]["%Ãp¾ş°qEÃ ”D m%F	é]óS¥/Êãè„˜OkÉ0ü·<Ñ_ah´AĞ©“ŠNå;waş6Y¶%}˜Ñ¦Ñ±¿äŸe,‰¶Õ@"Aö»x>Ÿ…È½Rº,¼S¹†«ï/¬ Û#n7ìİX¹úæ%•‰î„™3ıf ó˜Ş¼òÃa€œş•¦ÔmU]§®èVIq!ñ›º2ÆÒ¡*/“Ñ…3dcÈÑ9gŒŞM±,¦[§ØñÛÔœi	-3u«¹Òf+3qcšïÛÍÚ7»Ç_c_s®.°†~¶½kbh{_4¾ß)B·ˆ+ ¯q˜³öù¾×İc·4ÅHŠï)ğ.ÙT/^œìî	„ÙÒ‚ƒ°q&M¾Å‹?}¨íºqê€sN\‚Ã·æ’§Á¨óª0Ò²y‰½ø}ö¹‚õ¢¼Éû>!¿ %ÒœÑlâ›İ}}ÀòĞ¶{œÜÜí]m6¦="³n¬gÁyD¦ã¤`š+³ÚÂ“"5êWÊE·Ø¶Õ=–·å5ĞE÷È³J mUÙ*Wª+¿U†IîBZûh]6dAÈÑyÕ27š2V@µùì¢r|²áá~f¤q«OC†~dh¿Àævnv
®I’ŠîY[ÔWÓÄYm¼İFjl¥r3UÏÃŠTÜ3C{L¼0†6Ç37XëñÍUí§®şKÛ&µµîrÜbÜ/8~©´'Uvz™é°ÁcÛCMp¸»ÒF¡{¿´Ş
|ì8/ë`<¼&aÒ„yrÄôr¡,9ŒBÑ:ğ^‘z ­ªO¹eÅ‹!KÔ~–/$gÖOwÅ|#¨Uş,üz»s5ÖTŸO³¯¬~TÚÍ¹ùJB¥É˜²xfÛ÷}ZÌiÄdÌG¼1ª€‰ˆ×AÊ,ãâ¸°xÂ¸bèº¨üä•¾Xcºù7ÿü~L¯H€FxV>ÒëÄ‹ÑÇfİ¯ly-Vúæe•%¿ıS:ß³ ½…QÎè‘ˆ0"xvFÊ’oÖˆƒš'ü\ÈÒN³ú‚;ˆŞáï5VÕ
yË_C)¢‚ÄFA1LÄ±éò,,SDU.+ Œå‡6¼¢±šÚÀ£4`³<X_b+8êhÎîQ’`ŞÔ¨²˜©‘¥åÖÃÉzµ®#Lø]gYh
3ş9)
‚yï0Ìœ7ö‰Éz«…@î\Á˜0(VÚRÊ˜İ+„×,÷Gâ†Æ%ÅÄÀ`€{äàĞß@[B(â(á€`@‘H(\A$Ì!e ù[IµRÜ§Ù.0˜Ê²2jÒ"Ò›oô_S¥øf6¬Fğ‘Ağ,}dğÛ?‹½…?ZdC¢ö‘—ÂšÂĞ{şÀÅq€ !,ŠsïgØğOÆn$ ½&g{l	í8 Y@£¿Ş_Ï¹pe]]07«Bs²ÆpNX"İ¬-›¹¶Ü°1›ò~ªj×ªŸ‰çcæ´jge+cÛè÷a®*3¾³q3Ã…N½Î°‹;_›ŸÚÆÑpc@±8¹?¤â$rãûI°;?«õÅ'n+V$1!Ò-Éš^-9ßŞšP·Ì¤=-”&î“k:g€R2º|ÍPCZšüI‚ÿÊC“V*/½¦ÛÒ ø¡[U	„½ËîÙ}”„‘6²Û;/ÒèÄ."¸0p÷¢aÈšYû\ƒXtiå[]„g3Œjøx(7º²hwl#iÆ²«˜Á”8×Õº1Û¥¥¡t7&œÔÜ^êÄ=‡ĞäwşŸç‘û0xÁG›k•¯Ì1eØÎ¬³›Ás	V2Ïl•œ¼AENìn¹+ÃœJ®×ªÕ%{ÏJ$n•t“½½ôh»‹ÍºäpµWçnà¢PJo)©3“²â+¬kV™Nõ¥ÙÁ˜Ö“™i‘å¨™ìNœÏqz˜qøD´‹ûÍ\«âô¯Ù7àô2_şX7YEıp9£æc—…‚×­œû5wŞ©yŸşuw¾ÉƒæéQÈ®ÆgÀdáOoªƒ6ÔÍÔötÎ0½©¼Œ7‡{»/wûÛ/¡Œş›ƒ.\Á«ìÑ^Âàxæ—kq¤À*ÿ7+ÜFäõŠ]ÃRÒ.oRS;§ÆõYCÈªÑY ;1Gâóü÷çÑYH¦eµ 3TŠ(9bJDGn_ki¥|¹¼plP¸i·a;É¦ş}48gääÏÁÂIÇêè/7"³z¶²»j‰Ÿ°ccª9‰ MºÈª0DP†‡»S°4zG~‹¡Nö#Ë²çÍ®¡¨²wÎÆ¼íc;1ô@’F‡BT:ã ËcNÉ©e= ÇÆ,óºl‘FIúR„%,œ"¶3äÓ-ñß“„ò´ağYâÿ<~ø°ÿ¿oâÿ¬·—øoKü·›â¿•ÅûXQÜ8¹§
ÅMœ^gÃÆæü©4S»ººj\†—^ÄíÉ {ã,núp—hö0ìO×V'øJQv4®C{£ºŠäÅ_#ŸI•VÖÕ5¦Dƒ)"Ø—1?aï;xsxÔ=ÜûEò€—(¢Â‡ıvzoéëKüNœ2æ,MQçĞ¸ã3AßuÍş¦—R4ïë7	ÑT˜"[¡9ë’¿|Iéx•—ùmıÄ:V¿Ï~ÔìHµaœƒàuê? B[×…z]dçĞD
ìFÆu°ú+V6¤L¾xúr4š7¯…ç‘õÌØÿ©€w¬É8ùÂøŸíÖãÍGüÏÍÇËı¹ÿßÿsÃ†ÿyü.À ¬¥/ˆj=IŒã¹\àÎ’/ò-“	­qå$iàÅ »¤J¤Íå•‡®§ŠşZŞÓ{^ßGØy'é=fbE	«Ø÷w_¡—úşùUÍq”†ç×uDJ_s”ø¡ÃÃd•µWKI`H\¢<™î’ÿ=c¸kâ”…8Z³à.=Õ£íİ¿³¶ıæÅnwÿ¸Ë'Ë‘·8^%«£ßót?B2‹ûL3+£Ûıuçugûx}z-|ïS-/P0Ñ^ºU0àÒÉ½ü¡»÷ÇÃçÁ4ó˜~ŸLÊ¶JLš¨º§éiz]1y¨îxã0²ƒ!¬ô0öĞ)ùgR:kouô©îÓô¾€]û#%Ã'ÅZë›lï¸Wxñ$ÿ‚ë„ß ¹ÃKëS*š ‡\ „½:: "Ùßé¸cDX•¯…û?j4$=5¢ÆS¡¬ÓZ@¯:ëzÌ~‘òß|‡¢;\gæó®ßÊùd°¢§°¡ïQ*à°~^QcQD.‚Ö#÷‘äì}w|pëòƒLY\Gñxb1k­3 M\2Oic0õÓóQ
¬s–T=ÙhµŸ8è½¸§ †S nQÃ¬K©d·õA=€›øqw’úæÆÆÆã?>ân%Râ“ùL¡ûËú™z“ó¨êÄ­'gz®›µEÚu	NG+÷“hÜ‡'ú6m#ß˜ÛfV>Q³Š ¦Üê	ô¨Ñj´\'ç¦3sL{ú`¶Ÿ¸ŠT‹Æì ™ÜË¢a:ÒXÇMP$µ[ewVÚ1Ù
ïÉ8—5§uGİY›UmÊÆtk–Í>s,ö§ºùéÖ,Ã|ÌÍ3á·Ì±~r›UYûVÎÜŞ¬£Ìœ}f7ÛÔÏÙ	³;WŸ×9êC/ºÕÏ@%’íÈ÷Ó(böË¼ß@I‚¼Ÿ€Ù£C©#d{ÃE˜¾›ÑÆğÓh‚¡g¼™È
$Lç-î„¨*2N¾=§Œè˜ˆ
fºşîNW¦š	Ó¨¤¼¯'B‹04/›œOF‰Z+w‚KâÓãè§`¢ÛHU‹¬+
„“‰7ô>À¡)ûò¦»Òß=î¾1ÒÛù¬¦7A]'$ZQ`iß§ì_bjÕ¶ÙhÑîc>ÊÇÎ
½âhÕÆÈ_¶[k~ØxÑ§[UÖÂÒUMüİŠ£ùšgô%Â 7¼	FFFÒ&â¢K?Şá¢$MşQZGCê|Ÿê²÷êÆ‡Ÿ]G÷5‡£ã¦Y1¯5ÂÈ1Ù	©ÁÓuºÛ{TªØûõzqàUaÂ›<(¹§ˆ²ÔHÅáÙ”Åœ£ÒI—ó">tÑœÈà‰iu‘ˆàœìğ„óìQşuÇ•aÜLnæl6OÍş'Våûê¹•\àL¦†{Zi¬"¬ÿ€Egğó~ŸadSáŠ—bÔ« ƒ¥z˜Ô±cûh£z9nœÇA0ñ Ï5ES›©w‘4óÍ…ÏG°L9p¼Áù…Á=ß y.°iÊ¢í	è¼“cÜF–Æƒ¶ş Õ‚)Ö,%©™Äq2©$üB%´O”³â8¦mpÂÔÊ£ƒ^¯¿}ôF]tîc…B-q‹jTÄÓ©•g/O$ÿ„ÖŠ›’ÎDÄõ×}ºj½ùö•‹1ãÑJ Öz<º|ì¹LŞº¯vÿÚÁûìÊšSÕš†é­[¸m@k¡ö•´ÆÁ9Ö¬^ç'6œSô—òıú„«çcÒHN½‡şìœéùD<âOúXTc8yO ˆ!ğ×u®Ù­s¸\Ûù‚tA6p	ë˜Çš{WM?³TüÁ­ü9Û‹Á]„‹¢õB¿¾ª6†Š´ïı»L`«Gİ×İ¿²ï·vq÷è9ÎG}ƒ­pñ‰!ƒGe1¹1–9í‰2Äz18=î+-áÙ‡V«î—Àï]¤ïa³R¿àâ1	?œMÏµ‡/Œ£¶ükä"jeo?¤I*¿{é{íÍÅ»A]Ö„çÆÅpšndßè¹ëd0´wŒ§ˆĞÆ’éÙ% ³‘÷>`|z£Æ€€Ş!(‡f˜c/fòÊÀ9wÏ?cğ¢UB<ØÅšc§m¤Ê8œ;SĞ»äõìÂS&„&ü{S¤/@öbèÃ1I¢×`ãh\Çşº¢°:zvÜQ°I¿}û£ã”Ú0Ù-]”üÅ\%÷Ònôs¼$öÃö.Üì<JY,‡õLH §lk‘·Kü÷4y8Ş¡\øß‘Fˆù¼³°¾ÙøcsH"ˆÕŸII'.3i+×;9D2`ßv¡™G½;‘‹²o×E~Všİœ×Ekšsf¯|ÁC[rgÈ’Õğÿ§5ëĞ¨ö—š4fÔœ¥¥º¢é\¶·Ïbo÷Ø÷Ã°ão ×W(Ì.ôåïJäÄü%\n_–¿ÕŒí;ÖÈRâ.+­ø‹U~Ç-¶=,dåÉJşÕì|­–±{ğSˆ+
WÛÍÆ&Ê×Ìíæ8ŸZ»ÿÑMö!zº`]bÇSN5EdAvS4ÆA
´Î…ênAxìMa¤õ‡ö:ià¯7òmÂ_ØÕµ·ew&òşÁº±i6ë­>åÇm¸ˆ•IkĞFœ·¦µfw÷ú¿â
™ƒDçÂv”K_`ÍóK®Ç©÷á)Wá˜f§iÿòÏ2İÕ[°“3ïzR|ît?½&¹W¼‚,ó	FmVoŸJR–À¬7«bæG"ã“Zİ²}iØÉ¯ÿ)k)ö‰7[7™)­±PÇÑt¬ ĞS¨ó~ıÇüê4ó›²ú#öÓ4I•i/U{.-2Ù*á„¡>! d³¼K/¢3 ¶6¿5d4{¤¡5üÀÁ+øjÔ‚åsÓ£²ZÈJIhHPà(ĞÊ«T3•gu:¡Òññ|º:¿õ¸Œæa£Pa:Ÿÿ`ñ¹E@FÆì€¯•§¹µ’o+¬<máÙ·Ôrüö w¬¥F]êõşÉ›İ£übM<´m‚¥YhÉvcpV¬7Z-YêEÇÆ§ã¬/ûQŠu¨ºy×ıOöâZn y‹ùâjWE¥ÁçÓ„¬H&*:Å
£’0a
Ÿ¦·#BH3‰Âãß“£ıë?Øî9¦ÂPôCtÂ¼Ö³Ó"D»¬T_îdÜ-{Çã\û_ÃßàËÚÿ¢åWÑşwcsiÿµ´ÿšcÿuk0ÔogÆMûÃcşL&ÆdUôEì}¹Kh^á}²Gêh¼­Ïzù±ôİò»ÂıOÃùV‰[nËfØ’º‹d@Øôh\OĞ†gd‘<F(ïE[…ÃĞÜ;©>*uÍKX.ş:Õ¾qÕ?èe¸Ö©ãè¡9|)Lús8é˜ £ÂÃ¿ ì¨åŸHo^äÈ»}&U@€$4«®3õ”äƒ•JµEOr:'HÚÖŸs<gÆªôÔh9¤İÌãİÁ³‡ôL˜™ÀïGê·²§	K©-ôbÖÖ[º§ğ†QßĞæÙG«ó¬çoó…˜ÀMnMÏj‰ˆMo€,3Ó
^V/Í7¶(YD¶9¹i½Š€2İÓK¸ÓÇIgµ†1÷LÔ<|Q@°ªZ,8M¢´ˆÍˆå)ãäÊ÷"æÕ96Êµø.Zì¾È;N»Õ±)îÅÄ5÷NÎ³‰º™çû O «
èpq§ÒrO@	@ğ¦kë ßæŠâ”§e…<­I|­ıäìvtÌYÔ§æd2øğH€¨˜PAı‚‡R­ipØ& º)Ï74‡cVOÎ‹Ş¢¹¸'Ì,ƒUÉæBIlRùö—`Ç³´"g?aøµëMÑ-*8aØ²Ã^BÍàíàéZÂÙ0#a&%+ĞC¼Ğ®$À·@2âö æ£Šøiã½¯øÊ”u•*mídˆÂ1®é‘]huŠ7-ªBÁi¬[¼ŸüÌ&éL!C8öxÁìjyjlã(J•Û¬'wx3ŠqCÑúí!œ€øö¿E9yTÍO<.ó¿Ù Ô¿R¶”c­şT:Ú œ@ì"ÂºgNÌlABu!8+”­g®òòXùÃiía$ï·ÿå{ìÂ“[oìÍ‰¯Í$<´@- <ª L¢ClNÄm¸w/ÀgìóoÚ
á‹ÂÛcv[wvQV·J\HôN¹Ğ£ç\FQÀ"ÈØ£ÓqÎ*„MUuÎ<n>\Í§Í›¿èäo»XÔAù0ŞyHn›“rèdEæ=]²öxï#ß?ªôM,	€½÷Æˆ0ÏVµXÿ„ëË¢á##6âTÈÛd ®š*•v(åôíØ€¶2¿ó|Ùüf±©hÃ’ ¯³»hôPµıÖdÙ™-Ñ
~ë[ª'ØDézénq@IÃ³Ÿå¸æ¶(iqøÄŒ Z©pÇ½r^ŒÕîÃ-œKîæ†nÙüØ¼,ğr?CµÎ"‘‡3ZI:j—êzñ0DO~—NhˆkUhŒ…¡Ãš†2‹&`¾¶9œz‹û8ú
9Ù±ıÎ‡_~‘¿gŒkÛ¤•må"¹nˆD\°gp}"ÅC‘w0UG‘3âÆ²Z›Õ6YíQ>\ï™»Â‰ÀÑx“ é¥1Ú]Uµ"½˜D€çÓ!É ¦c¼	§Ş˜BB„Ñƒp?rDDîÈíŠi P`”JÅ=]rÊ/M_‘ak˜WI›©&…z@,‘}‰ÉœºF3Ûàº¶æÃu‰	™4n [–¼£¶Lss½}‘Ä
W¨£ØOM¢L£dë©bál=ÍãÅ˜í´5@ÃQÉï¥ÖÍ´t7µn§bÏnmY Œ˜½ErËÅeAÃ¢“Íl›rà•y'aFg¤œ1VBîTä‘I¼°Åªäo›E°²h["Ø¸Ÿµª\Ãtû1»1ååP»,¸ç¥™}‘3]å‚‘€ãßcÛ«ºbám®¿¨ƒĞ²zBM›µDâ E—N¢Õ{µ?! ıbèƒ„ºô†°QÂ¦)ª½xé€÷äCIå[øJm½ª3£$©J‰
1w÷XTBÓ>ÉŞ77bÅåï¡Ñ°£H°ˆ{¯X(‹³Û±Êoà|òÿFÓIó³Ö1ÿ?9ıO«õğñ¿±‡KıÏ—š@ö«é¤1ò¿şÃz{c3?ÿ7.ñ¾ŒşÏ2èáÔ;Î³És§‚Ú²gÁè¹…6’wÏšğ†ÔÒî“Ãó:¹¾ˆA;ŒL²ÇV•{–ÔÕ¯‘0Ÿ˜‹ŸÉ2tî3½‹ƒóÌ²åxXA#ŒÜçòÇ³¦÷¼Á˜3§yŞ`LÒ„%À%$vÇËM>Oû€MS„ğ,+ïøây½ş¬)¾¢H,Ä³Ì6œgM§ûl°DC¾pG#vßÚªûN§ÓÁƒçÌ9X8Ë4è©S‘Aí,+é§H‰ÏâçóÊT¶A²di4À€áĞ…T¹Ï€QzŞ‚ŸğçYª¸Q«¤‰eD+8úU‚¦Á½0Ì‹dnÓÌ(«KZÜæˆê¹Ó®¨WÔ#~i H¬KRğ@­$åéÂMÅ×ëê0:u*¥"ïÀæh(KjA%k3ò—æ _rìËŒ©>Ã˜a$ş“,ŞØï0~ÁE
ËÌù·åg‘ó¦ğóñ€·àÿo´—üß}-ÉùßXßhåí¿6Ö—ø__fşO]<ó'èÆ†ÂJc®qü­É¸=a.šU±íék=q¡
µá/Í2Õˆ$Æë4zß²ıí7]Ç4Õ<UIÓ(g<LYz»û‡½İc¶æ,v4<Ìşöôü×ıH?áÒ?{øs0'œgKdMÃË¥4¹,ˆtòºÓ*Íªd«ªU§õS~ÊŸpÑñ<cŠŒÇš8ÒxNÖ½Ô»nïåÑ.5Ö1X{âÕ%›=Ç<ºñƒaøÏÃã8ˆ\9B<oİú@½q&Ëì¦ÍtåTg]iäÁü†¼!ÙäIãëäÆ‹	ylÇ%£ïä†’±ŠJ-ÒÍàir¬ã|Ge¶M·W.£ªÈ˜šôäøXOfL¦-±À×óğù<•
¹şR°ªWâÛYî0Ô\0®—ÃfR¨ùùå­Hğ#“M’Œ%¶GvL|Àm¶åsä%é©0Õ¦®	mÛbµXh×±ĞdÍ—;I8ÅA#Ä3l…5¡ ‘8
Şøšn‹Ğ÷æ–è*‚"cÜ¢é8e^¢Dyk¼õPïTğÔºÖ%‚©ÑkJ³µ"uöœ]nzª…¶zSô‹³f¢2À£îaRRí2ôe}À—½n?è1ÜË¤¾ÚN¿=8ròĞl«>=èGıÖŸßEéîJ-³æ,çÿ¯øÿÁĞZ(cß»ş- ÿ{¼ş0Ïÿ=|¼”ÿ}!ùßK>õŞPŸp|¿B!–ÀÜ'›°†CğÄ'*T¥À0Äè,‡§á„&;ç……³c‘NÀ;ë™ÄeÜ›D^Ñ^VÃç/‡¾—NÛ†Ë>Å”xÍG9ºô0—f‰pßå&Hğ”Ílï­g¶åˆ õüw€²J.Œ@uÓAÌv¢«ñ0ò|¦ZM•¸Mp“Kà$t çw[v„3~ŠĞà}zÖ„™ö:B2°‹WÏ#´×SL‚1RP0P'8¡h’›§§ØQÖgM$$°Š¤n'rÍ·à_'f-i‰)tü:Ä¨5õ–òÑCõU‰Bê÷×)äç¿Œ
ŒfÜíé?÷üß|¸±Qÿl<Zÿÿıß§†°‰íÈÇÏ)„ g©Ì®Øyà¥ä‡Kål
§:âE4ç’ó€¡Ø.ƒÑÔĞ~ô€‘k' WÑ~÷‡ŞS}§*V@Rş>P>ÂêêçÈ6ÁAÀâH64$B–`[Q!å§¿ØE{W: E&uN‰ìé}¨Ñ,ßg«iì“‰‡¡ß×”ÉŠÙc'™úó|8ıèº–è¹÷£+sb0Ö†$É”Ãã&ÚÂg»Í0¼gd¾®—ÄÎù¹P´OjØ6/Ñç#2ŠPÚq®	ûy«ÅzZã“k˜Ğf Ièù8>àtÌÃ.{Àµš…ØHp|¡{ @¦$ ½”WS:xøY¤íü$¾Ò¢Zğ²zV9F‚+É†(«ò‡\åAŸ˜‘?³CY²Dˆ2É«İ¿vwJè”0õi¿–‚6N20è£÷ƒó~ºĞ!'ã\hçUø¨NZó‡Ã0½¶g¢Áà4iXúg%’“?õ "¸&Z’mX’G-ø¯LR¾0Ÿ”­ËYÖßÉÑ>`…ê¶§x˜µşx‹õ
¥4ÖË–ğ¦A·†XOB
³ö["îÑFÇ)ãøĞzª¿aĞº1,Æ¹U‰;Ë9LŠ¯¹,O¤0š,‡R#+^WqYò"C“Hâ›IÖd{¦ÁP%mÅ¾A]0˜XEâædÄWŒÔ€/‡üxg´¥Íè­'ŠY¥V¬éíã3òJ¡)AM””	8ª=>832P$¶ºØÒ	ìòqSÌ÷ÍòAm–|:áµõ\ıro—½Á}ï"Hò'‚Æ
ry4A$ƒÏxÎ#Ås}s’ÀÑ¦qÖ'Ú6ÏÚö—•i¶DîÙhafèwÍZë%,L
'Ü$›Ú1„)Z—_6 z ˆ¦ã!?¸ÛSÈÇ-]É7*ü`±·/ØOÆêÜ+/ŞBD4»ÀğÍ„rŒZhpş‹éïšë_œÿßxü8Çÿ·Û–úß/ò¹ÿ›ñY2ÙÒÿ×Ù­ÕÖÈ4Å/+æ)şo°¯R%¼HF–«ÿş}Ç¹ÕÈğwy­¦»¯	hdªgf¨™eüÍ7³û÷¥ây~E¹hle/Iß¦XvÒ»©-çÇìPÃe¯fÖvë|,Ë©T®Zs´×J\‘½Ì¿“çW±7¦8ÊZ‚¦	´—€úÕb·rÓ¥éºÍŸ»Ôçàt@ÿ¸ìƒPÆÎ§¸ò™cÌĞ˜ÿ%A$‹×Ÿ|=M‰²}fA9JYU­´@ƒ.Š@g™n¾¬ iJœ·}YI6æif¨ñ™@Ç#’‘BÖR]>[+¡|C½ÓİŠÙM ô®I¡ªÖ1msbVaP"ZÍ5EY˜¥İÀ¬ôÖÌD–í¤’Ÿ?~Òè@vQdÌ†àíì$×ãcT6²ó†Ğ0Y(ëÉìÜ¥ı—vjE>È77t–ÂÔa­¯·U²w€JE‹¬1éØÒÊAğÿ$FtÃùLê(äırş?pÈûÿ´7×—üÿ—‘ÿ¤´úhêáTş÷iS ê„Uå%+Ã—Äà¨Ôâáy7
¾Ï£á0ºÂÛq¥…¢4¥Ï‹†,½w×Uª`„¿$™3"è°Uâ42Á$JÒÀÇ½áN”ægÃèLh¸›Gİí7] {WÉù#MŒ
pB<!q¹Ûè—EÑ-­0['ŸªŒjd<.áÒ&2_x	ôŸo;Z1²¥ZG¡<ÛÖµ¶¢Õ("‘Ö«$›DáæOşûú“:üŸ=D1%µZ¿şg.m«e$6êG‘Ú!©õ¸Ø‚9ŸT‰¿şƒıúO£Ø¹ˆ&12A~Õî>qëçãq{{¨	ÙÅÙÃµúñK'
MRHzğAá…aˆ&&•İt%1Îÿ$"F2ù³œ…GRñë‰Î+iºÏ÷&“­µM^W%ú¤¢2~PzB¶†º: ¢’d)Bj©%F“˜uZê¢4ù}€)’{†¨8“*š(Æ+0Ú±O¸™hï¥~Y!Ç$„,K­Ûv8ÌùùùÌ¬H5ğT¯÷OšbA´Ö3Áó)Ê	ÅŠ®yt£ÆDw2»icDÌ^…4qPEãH‚Á4†™Õ#hÈØMÎ‰–FÎø…Q™i°&¤oÂLÈ÷¤{XÃoÂê¡¯ÔyÁ0ùê`„W·e<3Wmıºh£hˆ–_›‹¥‘äò³ü,?ËÏò³ü,?ËÏò³ü,?ËÏò³ü,?ËÏò³ü,?ËÏò³ü,?ËÏò³ü,?ËÏò³ü,?ËÏò³ü,?ËÏWøù¿5h±  