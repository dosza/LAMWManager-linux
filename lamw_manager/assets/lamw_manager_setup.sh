#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="97392603"
MD5="689c2e5f597c25279cd53fbb41f6fef5"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20867"
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
	echo Uncompressed size: 128 KB
	echo Compression: gzip
	echo Date of packaging: Tue Nov 26 21:35:11 -03 2019
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
	echo OLDUSIZE=128
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
	MS_Printf "About to extract 128 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 128; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (128 KB)" >&2
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
‹ ¿Äİ]ì<ívÛ6²ù+>J©'qZŠ’í8­]v¯"ËÛÒ•ä$İ$G‡!™1Er	R¶ëõ¾Ëûc`!/vg ~€e;i“İ»7úa‰À`0Ì7@×õŸıÓ€ÏÓ'Oğ»ùôICşN>š[Ovnmon>}ú Ñlln=}@<øŸˆ…f@ÈËtİ«[àîêÿ?ú©ë¹¸/L×œÓà_²ÿÛ[ÛO
û¿¹³ùäi|İÿÏş©~£OlWŸ˜ìL©jŸûSUª§®½¤³-Ó¢dF-˜ŸÇfè‘ÃÀcÌ#ZÎÂÄl(Õ¶Œî’áÔ¦î”’¶·ğ#èRª/‘çî’F}«¾¥T÷aÄ.i6ôæ}³ÑüZ(›¶"ÔèŒU–v•ØŒøfoFBèzÅßG­ãW0=ª“Ñ€	48À$éû4 3/ *á:¤Ù.ˆ’Sggêá¤B/}hßï<;=4Éckp84ÔÚc5iÀÅŒãîÉpÔ::2VH4ÁÛ½AÇPÓöÓagÜÑyİigsuNFÁxÔw^wGYsf?kŸ*ÊUŠ¡Æ@ÃètÀJõõv@§¡\ùÛPÅ‘7Dƒ}«õ_íëµâZTònwÎU*åäã0˜ßatD­±®ã:÷ümÎN>¾!ÊÌVÖ³¸–\B¸Â@ªA˜€|k¦Şbá¹;£|kc‡ğó@wÛ¢L¦]ø¶CÙ£k¢T^éáÂ×óĞõ©çÎ€WÈ*,ÖƒìÁªn`ÂöÀXƒ}±g‘å‘]L`spÊhĞeCh
”ÊÔ‰NÃ©>¼È'%ó€úbXü[`û™è]ênä81Õµ?‘oÒHvSY»¦RÔñ¹sÎø´.½è‡	èl<ƒF`~SPøy`»–QÛ„y C¨jB‹ZK@ÔrŠÊ	J§ifm\çj×ø¥ë)Zı†T|,&¡g™ÀCF<Øá Ì˜¿Áê	åMW–ñwD…Ìg )Êœ†Ï@ÚÇû|Ù‚Lgf¦	•U5¬¥¿‰v©¦³"7¯s@ß®G™‘n( ÒÊv˜wj6‘ğ©%JY{œ*•¬óµ?­µï96hÃ;3Âó¹ò9ıszI§„ºK²ßöZ¿µøyİ:=ïº#hË~“O§Op•Ôr–­È^.L~@ªÀÁîzi‡¤^¯«{5­”Ã¯W¹StBZ\?®˜¯4–RÔ.’k”T©d’ˆA¦&b%nŠesSXI·•7ÆÄ.LÛM)Uğ‰“Õe¨çÏîS©dš¬t¾O¢NM”9‘ç·Ê3˜ÌÎ(H9áŠ¬TdàäÃrøVÔ¤%¾~ÖÇÿà…CÛ“!ÄÁ!µêáeøâÿííµùı…øëéÓæ×øÿK|{h“"Fs6iW©4IÏÏÇ´9ĞdåW”ÊÈ#qüÈ‡~ÏÆ.¦kÁøJ>µ"ß‚à_'à¥Ğ_ó‹é Fîß‘ÿ777·ú¿İl~ÕÿÿÌü¿Z%£çİ!9èu|CÔÖ;nº±ıJÚ½“ƒîáé ³O&Wù(	FzY˜WÜÆ@àE¼(„0ÇæQXpõ=™À³éB&	±O@eÏlÈI ˜a|Ü„Çca=_XÍï}3`"ª“•bAxä×ƒÈUªò8Â'š&F[Ô±6†…Œ&“;×…yNufÄæÏÈ,ğ`@Ğ5ƒè˜ÎvÉYúlW×“auÛÓ¿LQAÉêrVóV{«A>CÄÊ‘å—¾é2Ñ™	¯¢Ìì€ÁæL§Ït(p¦NŞj‡a?ğŞôyESòV?ì¾Zå/iÿyÉáß¬şßlî|­ÿÉıŸbáU›D¶cÑ ÎÎ¾`ü›½½âÿ·_ıÿ×úÿ'Öÿ›úæÖºúQĞïy¦šú¢ßvp ÿÈœº4àa	 D±]ğ‹xTĞ/Ÿ´Zƒöóm´\+ğlë9v¥jÑNCbÜÿãË#3§q¦e×#ı6Áz£‰e¹å‡¿¶¹´)/Vš‹‰/…Hı6Ö+JÅñ¦¸‡6Ç3à€Q{”V‚mÆ"Zwi¸åa†…üXÏ«ÕÓIä†işPW`ZÁÄòçØ¥ãˆŒñ²ëŞvd»Ñ%9†Š4¼ÿHÊÌ©’’ÓÌÈØª7ê<ÓÁÑj¨IDÆ–n}Pˆì Šqê^0Ç&¸¨‡æœéu( oã†*a,ã£î³q¿5zn¨zÄİ±'8CU%°öÁa†<“VŸÎæE”ƒÎQ§5ìê­¿ì†İŞ‰/ñ^dé5i¤šqQlÿ\Ú¾×’¶o]ôbwz’,ãò‡1hšƒ‚¢Íİhe]i¿ÊÅ$† 4såEÍ°Òã)ÄW‡sS T†~pÑ¥äuì{âM{n†ş	…@‡E—<eH´ @ğ9aöbòáŸ=õøÜ‚'7ZÆ{f6ÿ"K4vûâW¼$5ä~¯c¯XÀ'L¯ÿ•tWÂtüÕ¥óºfçâÌ!·ç *šŒm#®”«µÜ •DUWÏNÊ19ª­›ê~sİoˆ×/ŠôJ•g¼éy÷d\T!ß¥B~z®¬Âá	¡€“ÅéFƒÓ“$5ä#…Åşk9¬h›õ†6× ¦`ãU¸ÚõJÛ·oµÇ79ÔñQLöçn?>2İ>êœ¾?ïw¸`°3¢SX@:$ÌÃ—'£Öá7%3ŞÔå½ªƒ>Öç¿©%«K±túT.¯WzS‚6b¹.Å¡Q=%¬[iÊ“œ9†Úê
ĞØCÄCú8„TÖh.V /^,L „bÂÃå6µ1ÎiqÊ{fºsšÛ¯,Tì)”¬»RÁÚ™‚…Gï+p,'óIm™´û§ãQkpØ&XÀ^d¨š…¸€ÄÎ‘JzÃ´_DT¤=è‡°íÔË§-¢µg/ú/·T’_Ğ9è¾6pg*‚U¾Ü˜\)”IÜ’ªH%»“ ‰cïtĞîJ^äÀš!z­(Øhü$!~³ı„%j¿/d%İ{ßŸ^îpYvÎm8\¼Á¦=ïİ˜€‹t‚ÀvÉ eÒşk²úÔ®OzƒãÖÑJ„Õ²!àŠ­RÉK_MMk¥Ú¯bhNSûír9[UIÖ—±H>³¯€¼¬ƒË™Õêt@+Ø Âu¨$`—u¡LÏv¶Kõá>†¬d»¥İ¾‡˜|şÉÏkÇóƒi/£î6Z{?ãòT4)IÆ£ÇÍKÉÄ
7åNf|n›ğ±\ª~Üö!Éwl."Gr²ç‚æåö½ho#üa›ÈC²‰¨ k·°3‡ilñÌóÂa˜>W¶ä Ãö<
R‰ÛÛR›tÕåà¨u8>è¡Ñlìzİıq,G…;2NaÄ“57[¢ú5¨á‰³K¨I\oÿrrWÌIéËy[SX•/$ÄJìêgÙ¸RR“¾9=7çTxÜıÎAëôhß(µíIÂn»½ä—^’0Ô®`ø¦ÆûŞİ|ôZseÂá¯Uöûú/¿fÄÄM¦QËWö‡•o¯ÿnï¬ÖÿŸì4¾Şÿş\ÿ]`éW3…ùÖIz\‹ÏK$şõàe¾ç2{âP^Ûåñ 7w±Q‰×‰ËJx]­^ÿ2Ü.)00üvhã™sDÓPªq%Ëäw-é’:ÏÚ¿QpÈ ×±?s‚ß` ^K\Âpÿ…\,Î3Ñü ÷	|t:œßÏÄK"j©'ñPæU¦µ€i ƒ·&×Aéõ=†»lã=ÊÙ<£	á”Ü>?®$QÉÏ|÷|İ!uM›Öş³Ğ;µè’s“?°İpFOŸ:Ç†¡Fl¢~OZ£ÑàÚ¶^R×ò‚hşéeçd¿7øú{ûCmìììÀÃá wÚ7Tß‰æ€W}ë>$ä¯²Q*ŠñŞq"?KÒÔbJë¼	i`4Xâ5\$/c†@ñ´U¹†P,mšÁ_"{é¡§bşárİó1ÉJPr[TR•ÅO®ŒÈo¾úF4‹€•£¾ë–š—Gˆª\N*B—Ä"‰ØCÀÊg@¶¨§«‡1lı4Íx„4©Õî¬Ä¡Êm @H-šÒ%yŒóñôÚJ~@ì·ˆë‘ñnRsbkq÷SK•Vw­sİwÌÌÕ‚é1´VL¯ã6i€1aO‚æ~[Ny¼!nÜ/à=Ï\ò½œ¨íúºP4B¡.ºE•!.‹U*µƒ(¿5ğg)Œ¼	b¼ÄrNÃ‡=Bü	c‚Ğy(v	”®{ ~o(JV/ˆ"‰m!©‚fáq0"É‰°•
ãºqd»Ôvñ"s&g’½i¼ã‰V"^xÊw£Î¤g 5¹³¾fvDA¦&¸X¡¹ ¸°axî‡
Oß›™[âà¡I†k!qWSúT¢JÔ©„¤Åú¸Zİ²,°>è½~à¡óã&D,À-ñ±aÑrcPLy±É Ôbf4Šx@ªDŸñ0©òÚ.şİ­ZûGDî!ğ«ë‚Í!&ùKDŸ9¦{;‘¼3 ‘O Ş„ ğ¢ 0TVw[­É,P¥çt)ñ»,…¥óİ–ö:×+^]!Å<?y[%öÆH§Q“ŸÀ‹ıLÈÚ}È£‘¸iÈ¬åHîÀQ¶;2!hP´Ô <üDŒÅı¾7ò%HrF.£©¶0!¯.tÀ‹òÌ]s l5ñe ô.wœâ9ö¤ŒPLÅ¸ÏÜE`À¾‡Á½âb”j/KóŞLú#™íUpMKoêE$©‘<š >†•™ET2{.Z“FzâhÔs«øú¶†é«* ±²b;†¹pcÇ'ªScQBv¡ÖTâ±cş»Œ…gAXraÿf±·«íîÇ†Ç?·§C|ÉãÙQGã¤²–ŠtªgÎšIÓ”ê~YoªçeñZÖôr"EeX½“G…Áórøúc´¸B7!/Áˆ‘$ªÇ»ø^@Aòè‘m4öìŸj×U‰9o¿»Ù³¿ûnÈ~âĞ ô’Áìw7r€Å%!ÜÍ~m°:6®¸ƒØS,k]vˆ7rç\"Ów	Ş˜¼yW4J.ıMì¬9rûèRÕ
¢ÜÁ›[1)W 4äÔCqÉGèezºä•µòÓµëÎ¼]ÜSU”k1Ú-–nÓ~ráçÌ7§4fî«ŞàÅÂáN×c	8ZÙ\1ë\Ì˜ôŸäûÁœ½uÁË;4g¹8ÎŞÑşXÊÚŒZ¡AL|2ÊV,=ğÎcÚŸæ zz½£aµÒÄOö¥3RéwÊ—AjÒ¦Æ<6BÚÙhäÅb2öû½ÁÈ¸E”T±“\654‰»µGøµ¾BÒ©X˜Ï½{b¥Æ/ÖÅ¦¦wNz£îÁ¯ã!„›âÁ7…+E!boİ[äKtfÂEvI™x½u×ËVÖwO¹‚9{‡»wó"µáqFü{–“³—âªy
ô¯XÜ[—¿|6›Ç“lY˜M.¨Œš±9ôø;yÇĞV,¹ÜâJtÓ÷ô½‡4
¬Nù¾  ×{„}ƒ!ŒD)g4øß?v!Ê€Œ……,_Ê¹ïÄÂ)İ“â…½ º/ê¬´îrïÑbŞœİ¶(;=ŸGØ™³/šI_y'rõÄ\P#Û55õö´ØEøˆjç’NsGo …"wÓ4à…\i"£ÒxbRîãùäª,Êá5\Æ¶“Ô¢ËÊÃÁD°zİ†.Æ£¨ bc/À€®|ÜˆÛ5cf‚†‰¦+Ÿ­lßb6´ARæ<v0¤:àÌ¶·
!çòˆÃÑ‹½ÃÓ.ğÚ÷„İÇ5Eş«ã¶c2Vd÷1l''+¤—¡~©‰;„{ü)^0Ö{2¬‰¢PŞg»Xédå °9ßĞRDB¤J±¼qï™z…IóJ¬ò½[c1CÔ–÷úbÈ¡ƒ€ÒøÖàÎ^Io [ö!Ó¼Úİ}­½Øïh'°”%í\†”¿wó.Û¿ÿ†òñ†—¦Q£Lã¯5q·VÃ·|ZmßÃ×¤D'Îñm¥	[ï¶ÆÇ“ÓqwÔ9NşRÂ<÷Bvòİ%)İ~iLƒ>‡ñx¿3|1êõùy:Héğ¦¶)ª÷¥ïEQÇ¯Ï]oAùİRÓ¹ÖÙéBãÚ<²-ŠÚ3q„…ĞB`ìRòB‹ ‰¯Ÿ…§†&¥-S'a³ÓÍEõË…óQ–(Î–øìğËÄò#!÷@‘Ùœşû›ÌŞƒqoÃë—ŠŠ³€ÔtOº<QÊNã	¿o$*	À(Ëš<DŸ`Ñ%SÚ¾ÇBqb/EécóîÖPïvÉêŠÇ(ÊÔŸåOŠ`rmQ­’#{™e)@Y@TîÕò0«$¦¬YÂ°÷æÒL"Wf<Ê®Å¾_.tìÔj×½~çäˆ~ãâùÂ}okæÂ‚˜”|Ü {ë‡u#7?wPªš´…æÂ€D1GÚ›ÿ‚°
= S:¡ÄC0Ó=ãÿ%KG’ñ¦
”<9H«"•¬ı:ùù­¿æ$M%6±öàë'œ X
ù)ÙØ Urd~ø‡'J` ùÿS	H6w.­]ç©/d°ÙªK `Zr¾''®xK¿BäãQ&¼àû§hRrB/úÂY	ceÒ‘÷*Õ˜µŸ üÆÿá€3ãÎ"JRòÇB“ĞŠ}—–î_0ïK9$uÆ±ñ	öçBãU˜a†`Âgà‹j‰H]"Ä6VòÒ¾8?°zÃ_‡†|† Bpm-0oK;¼Â°Dä‡‘ãÄlæ!\š»ÂihlÆ‰tRq@ğ,uÜB9ÉîÇ(F#Á¯ìƒïŸ:‰æI¾j<‘V3DV'îıwîwÕ‰‚E—\œ>üèêG2T])cŠÏP?Sá}(İÀãuÍ•ãZ¡3¥O.~gèLŞâ»Êk³î´uĞC°–9•TË£Ÿµq8QKX£J>‡Ü wI88­‘X5îxÔä:ù*a’y/„Ü½”µÈ²;²Je5)Å¨‚«ıº¼ÿ!j	sjŸ­üS-”ÏfAnıM¯³èÛû¶æ6,ÍyeıŠTc’Z @êÒ¤ J„d¶y‚´»[t Š@‘*@aP )Z­ı/û4±û2û0ûØşc{.™Y™UY HÓÏa³÷ëÉ“'ÏùÎ¹z„Ãwhø4OR\°ÍòÊ$ˆú¢Rw§_ü¯¤Rb”lóËÿëO`=¡]Í‡À|¶Ö/f´(µ|E¿ÜÁq% ¾áeKúå‹«àç( w2ä”k¹œ-ô¨ô¢.bª	bà¿F«ô#š²`IéY\G“FÙO•º‘+®Plåô6İñáŸQ&tü=!I½r7ÆY îb(àğød¡ü—ÑD1•Êe?>š3UˆàöÊÆœï‰Uì{ùÛÃöÉ&ÕÂÜ®b0ííŠá'ádÀ\øµÜà`¦ZÏ/ì“+g:*Û³²ººQ©L‡h|cÊœ´V×í]¡2,R¹7JhniÆyKºËµ³÷XõÙµŞr.Ñ¼œØgN­9ÿ_7¥ÒêVƒ€Ce3
ªêP¡Qº:&Ì	å”ªIƒz< ¢PWñ¢FúÆS‹ÌB7#•q½º^­ËspãÄhMú²%R6’ùH3™ÁE*+ƒÊø"ŸÈâÓÂŒæ!ÑE‘ÜûÙ¨Û™Fj|H×ˆÏZ§EwĞã~‚û½1#–à^’øû*éÆÕIï‚¿{ÑÅEúk:’ßx½lDÃ.~åÆWı^ƒå.ôÂOÿ«Ã„ßûùÿ?Cù¥8]¸N2?«ãä'Bíxù…&mÆgšF[+™Ÿ:I/æªG¹„qW¶Œ\ú°a.«£	ÿ@Uùcœw®ºI@ß¡êöì£ú;Â²èÚ?œpJâ¡LA8,Ã¾ñ)+|mD42ğ‰ò5ş„¿A¯GŸÀ r(”Õ€5+¿~"&„¾Tät¢?dñ£~ˆô(×õz¿F½pD§½é@~Ñ*áO„aÁ/¸¬s÷G“x$ÿ¨bo‚.vq< E+eœàî¾J¿dÒÉÈ1R<Úiiáğâz2>e–tà¯Ãó¨×§A$3FkãYk<·õR·ég6«Ä¤Y#©£/}AÊ_‘Ñ,l	:Si3²Ø—%ÏKõ3˜Qäß¥-ñ©±A6¯©"AYçå\®ÍQŒ8Swƒ3[ItQé¢tV#Q»S»S}—t%«lTëg4PãWî|ˆÿÍZ/Ë_ºMÏÂìBMÍ‘Y…|ÉªôJô©¸ßSÜ>ê¤×‘Ğ©Œ®à\î#2 á$ì™Ç³¾H$‡nŸ7/²ß³SÂiÈë»F€#Üâ
Ì´Ùp·b¶v#Uò«¸â*sC£SeãzëÉ)¨+‰d”[Üò{Š«‹Õ’•¼¾–6¥*ÑF¹‹ˆÀsâsw~k0Q¿Ér[-ë¤©Ù3$E5…Ìˆå9¾ü:/T€ñËŸ©ñÀ±@NŞ‹¦—n<èÄ£IÒô{ôÓ[œX³
*Ël&w)/r§C‘S>+ÃÅ_j 1ëÿÑO†Š$`óÓš BC"FâqD´eøïßï0™hÎºVH˜çÅÄe©>w¾øŒ¾QÉ’%ßÇ3U¡P?º£Kyó±d£tšœO‡=Ö6CÀò}İ0R‹)MzN/	Òï®ü¢AZHçüŞŠ0&ß tÆ9ÙI‡Önn¾•¼¼HÃtfdşàZ eÿWW¤wœÀA4Jm„}»˜ÛÍ –QXÂ\–ÁÊŒºdn»Ïyh¸V€}¤ğÅ‰‰Â“ÁIr/r‰©Tì¬b–ø¨t4ÃêLQ¾vëäd÷à]»8¥çåL¬ïb´€OÆx†Iƒçy<S‹” r:PC8œ¸²{KùT+tÎ–³âo¹{?©ÕÊy¨˜Zíï¿¥~’Ïºå.‘÷· ½·2;r[9Œò6G¶É‘eq¤fÛİ¹QÖÚ~Oå}ß/5ymĞİr²ĞóJ[!ï7²ÒfG™	4tRÍ™r]Á~åLA[fÏÕ¬N;Û3¿Óÿù€gYˆ¥Ÿ«¦JÊ­MÅîf)æ0»w±ÅÄho`fŠ¡7¹yùÒ.W5óöêôS*ÚæÑ¹²Hp»XäRîTG¿·hÄ/İ½³+¿¶sJ·Ûş9R~1%6Â!Æ¹kvÌ
ëDáÂßşÜQ·ÖŠ˜»5hß·£JòÂHàgHo@^#îe9’ó˜­GR«ì€—“°¡iNmÅU¬¡QÂj¬•1 ßlUÁÕ†YÀ}¦]ãõcò’o:Dk|ßœ‚·T²möTM‰šJ%.´>·LH¹·ƒáÇÛÇIVG×f9ÅjJäÕªßÓ›ËF½‚¿R~¼ºœ‰ /F¾€¢b–-Ú^ €%'—¸H¸$˜YlÃÃ|¾tü–/"´q]Zæ–Lõ-½ÅP¢^Ì9–<îg®‘lÈú«ê÷’kl0…N@ºtê×Ö–ªˆJbº3¯49ÒîÒèñAeG†!}”UÂèË?ıøeÙ©3T°å1fí2Så¹8#Ô1‚ExÍò¸œ®¬ÒÖ‡WÛ¾üò¨q¬lÔüzuÍ‡@7î‘iú§'o+/ü?¾¢^¾äÈ?–^¶†WÑ8¢
ş!Ÿ$çïË=®-Å«cñ3¿ö!„5‚¹©Iå4%ş5?!á+_–%Eˆ4|Ã`ê²ŠhVšùeÍÑFŠzY“}15İ²c$I£SÅ+L¹`=/ \¼˜n±½h`ò]­#MùÜÄúYUX6É¨ÅõØBµ¼¢,Ûø\—À9aœÏHö	Jw• è¬ÍÎdÁ•W`^¾Ç«şÒª r–JõÙXj
¾ªò5
ó`\Òîğ….`½¸€‚Cƒš°qÛ8ğc},¬ô”m‡‘9E…ç|*·‘Ë…‹şÛI¯‹g¼Ö—8Î§z)NjÅ{è³±8‡Í³`âJŒJî¥i· ¥Mæ/yš`[§bNşt~+AôW9-Òßjä¿ƒ‘_ÿMFYÙªÓåì×ôÿW_olÔsş¿ş?ğßæá¿]¥øokÕºÿæ@³Ü|Fc’Åv{$vÙØP„Ÿ¤s.¸4ŒØmäê
î|ı]xi÷¼}P.K;HVóu0Ş¼Ò»½Ã×Û{âûíã]4josµoâ~<F“Oå¥úûÖñN«Y^>ß×·Öƒeí2|û¸µwÈQk·ÆµO_ÃAüíöFoèàƒÖ»ãİ™¥&W@²ºG\Ç*“’mX	·ÿzº§ØHÃiV6‚·N:{‡o¾k#ëä×®ÖÜè>^â‘€Ïkih0Bùb2Iì¨nĞıR$^A`i&ù¬ºÀÊÅ†=ß[õ’À]
T°'_h½NĞàÎ”xôW°Wêær/ìö¸9•º=Zw’1§ò–ùD:Ø&Æ.>ß“Ù¹»OğÙ¹'D)ñ…—ANmÄÉ«‰­Êné4@¬…ãÑì3[{v`é+õ3_ôâ01ìÁùâ›—¸·Cù¥-§\!ÉÁã‹ÑZ¡â1â
Ø×å:v›D™h&6g¥İDe‰¼ÒÓd:Â¹.Õ/âé°'â±¨¢Ÿ^®8<ä¹a£ ¸¹|pxĞZvŒ™=d~¹‘¡çÁçƒ½İ`vr‰"A³Òœ±ù¶'í@\]d_¬Ï¡è%ÙW’×’?qúy…ç>x)_&‚‡ÆUı¦‘$O„!;¨şˆj%Z[öX	jÚ\)¯´‘{@ş¹ŒTÖ~Wa­Ë(ÖD³!X-T(}AòÍ•U×üæ›Ì ÀTT¯=İZòØ®½©På¦ö%´®´ü>kµ³ZM|Y5¡îe
¼íãEl–ØsÍR‰ùCù ‡=–Üæû òóvå¯k•?lı¸j#iÁøC.Lóp~A{p:@| Íl«Ò¨Ö·U;ÉÓ	Ks7šiI[¤eÓ>ÚÛ=9iít¶·ÿ‚¥Ê™¡l4Qéäd‰ƒùÚ%«‡m¹œ©’öIZG³œfúTØV‡g¹éÜdR§Išr@‚ñ8¸ÁEªV"÷×Â*¹ ±Ğ)¹ós:eŒM9ıæn¤%™R3g¤NŸ2J™E-ÅÅ‚´İ=øOP©^	“Ò§ Š®IGA‚Dÿü-İCòœ	¥Ò¦èhËCÓ¦sk==iö„u5Ëõ-ı[ï`ØQi(L¸ï›åu*{c*·mXË†K%u\¬„”5ËÚo-+eÌ”‡…Ì3d&Q´^ÂA#¸>Z™tuÓHdw´›ŠMGÀbÒOÒ Æ³çBŞäèÜzÃ` 4ó’¿in ÃNîWrR½TdÀÂãÜ4L˜)Y"srø¹&u¶d–cLí¹^¹üHd0üS œ<÷%YÁH^û
E“²¶ï¦Y™r¹lÍyZSö{éüÙğNİwe›? %~ôÄeA’;*\Zé¦.%PuğéFë‡8#•Íd”0ëêí–eúûëfFë3	=ÖĞÏ9Åİn­)R›eEU"Gj½*›ÏÑ÷5Fï6·\o¿zœ0¥·º!˜lZÆú–âWÖ¶Ô¢Û×c•œÂ`ÇñDN»Øâ`­·„Êæ8÷¬"F!œ(¬+¡!oâíl:	 ¾QØ­ÓÀ2“UäÍê1>Ù®¿G®UÆÓ!ø¢gsúGW0å—ar6lÁuöwµZÅ%ôê›şŸîLD…zRŞ“3:¹“I/Ä:mï,HÁ/Ã‰±;ê9Gx´ä0œça/!Ö…}—g]½ğSÆ5$Uêì]Q©ÀÄ…x¾¯¯!VÆŠ²NzE®ª\I=ØÈvĞÓªÆÃ	ÔüyÌÓÍ#q2¾ˆ’1~ä;î­DÎ¿7Öİt ÈÓ|d‚²&T€I„nç"¶`œGã¸&Iœ<Dúa"ˆ[\†Z°²~ù_¸GÏ#Ô¢Aï#…i„…‡Têõ4¹ÉĞ©µÜD¤IgLÇ–¥r7Azºö–Ø¬Ş¯ı¨â	]…¯?àÒ¹@D$`Ì)0“ó—ßÔE)şó…t±=,(ÎC,”îtD£RÅiXìT$ÜÓöCMÈB¹Î
KKØªú–Š(ºI ÜÔšó3
ºp2×="€MÔb‚†êÁÉÅ¹R¹Å	Ññue:¦Ø¢	š"„½ÕlâlÈP¹ˆ>UúrºÔ:\ó”V'>Ò8LôD%ÙcL*¶½üYK´p
¼%¬àf`‹ô·2ò(?Æ“å,’¼ş‘‰ëš¹£çæ6~bÏ¹À%'»?O7‰@ÒŸ0+1}ypôUüÿÈ5qÿ¾ßğÿóôy#ëÿgıéúÚÃûÏƒÿ÷;ûêòÿã›«|AG?o”¯wË•»,H;üéÎrõ“¯äÙ½4‡¨ çš9‡Î'‘¬dGní·N°:DÍ/ê…Tjº1S»Õ4½K»¬•â{uóÈÕe¿UdìqÄa¿'¤Z“PlYÖ¸ÊªŒ/TLæö¦ ¡Ñ†”á¡rs@øeÆ#×¹ògGqT.ÛÙ´û™Àèƒ™„{`Š$–òC(‡İŸ3v‡Ò¯#ëXÃ‡ˆ&vYzÜÒªrö¶f}Ô~‡En®”,HX®Š˜tÊ¬YBÛ¿Wüh˜ğó ™­g°`"È¡”R¨ÒåT6•çŒº|âÚOBzÄÜçZ®Ğõò5-Ôp¤Ù²»H~F@6F²,M
d“Id¯7wÕÛ'sëÅ4³+•)ò27`5lO‚É4a›¬‡SÂvÛù6U•R?üÿä´M/sZLB‘fÈBã×Ó¨ƒÃÎ»Ó]Şñ2F‰¯·ÔMÓr†eh²ã«
ä)1’%^ƒñ ø9âÕ‡Ä|¿üË/ÿviŸQ<‚rÄ~jVÇ—!—„'ñ'­æŠ(¯à«¶¨À5 ¾*VMj/SØçÖ?©; .qâ4ÄH2”¹U !ZA«fTe._úŒô©«-XH¾rFb³¦-¨¢Å‹’2bé›ú­¤qK–· U˜r+–"®e¢xê—ÚŒz¢¥Ä8Ço>„İ-ËA}p4Ñ<ÓÃ}Ã¼Wó¸$‚Õ¿·÷NZÇÛ'»ß·´_4Mmxáoªa^9x=‡²›¡Du¸Ö,¬ÒZûF÷Öí;†jhÓ–lr: 5ÅK[ÉåK/&¹1Â‹qò!¾¦…¥FC3~ëÕµêš=bÎh´Z;Ó#¤n-<™šõÔ	xôIì„çQ }_«ÂáŸv¾²³‚{/C_˜C0£ÕBÁí¾¨ÀÿÓé¤óv3]vÏgVÜ¥äˆ?c8Æ/7×Íª¹/”vSÂ-{OÄ4¡ÃSÔë´×frH )›Ü,«€½“¶#¶@=eFSù¤““ÌÕP‘†±Ô“*jÛ¤¯‰Ÿy…¼Şİ>è¼†€`zmT)õ5kgÕò‘•s §Øô…ïªM=Öö¢ÄÑ	uR-^¹†·ÈÇé…C5©W{´ ×¼ÃŸÆáÓ(Ôğ!-«óX9ˆ#&¾ˆÖkÏ½§âÑ÷t¨ÃÙ^ı:	\—¯`Ùƒ^ DD¢G«~ù— Vs“Y¸³Åa®PI-Ln¶5Äçİ)Ñwú“$G+O	gT©Œ¦ãËPo?TÃ¡"æ'¬×Óé#7tNştÜz!HÎ~Lûƒ`(^É‡|¥‘ê‚É‡Î>{3ùß3IÄ8\ÕRHRcJ1¹ù²’¢bÃY©K#Tn‘-Ô®#8àÒeæª¤ZÍu„ú4¤ãC¥¾TŠÑÜÚuDbZO›ZRˆZçQ³aò³a{FHf¤Ò¿SH}§´+VjÁ0ÑùÓö÷ÛlÓå—ÓdºvY€™!j¬;—ÀÜ£P›šXÖ¥:U[×l¨Ôh™²âXzá(ñäßQÌd|N±/«É`Ô\®Áÿq[ã½Œ³vŠ¿L÷ê½íö7$O™½Tçxƒ"ÖÌb‡*½ä™É2E¦™=Á	ô”ZÈŞ3‰·R¤pDÒÆÎÏş¿,ıCW’Ì= y¶ÿŠ5&“·%Iéµ‰OŠ4•ºÈ«nFh^á,Á¹¥§PtËVn¾|íoÄ(“¬V¶Œš=ÖÖî÷2ÔöŸFKSÒ,ó’!£ÙÓÙCãlı f¹S9Ùìy(I–‹ßñ\Ø¨£¼·ûº­îG„ÚûíSNÈá“ 	o_`¹U£.œ„½Qÿád'dUwÄ?Ì< ­[Ï×–Ú[tZ×~Ë—é´İêØ0+h*kKR™•tLŠ•Œ
UÙ,§Ç{MXÜØ,³_EE3ÅíÒ˜€ª×ÕAİÂÌì#bÃŞî›ÖA»Õ†Ñ;ŞŞoãW°J¥uÃaBTswÈ
¡¬Ã(4ñ—úÑÉ#Hë¨64]æ°Öıíƒíw­ãÎ›ı£â÷°ãÚ„ÛôÇ¦_ĞÿW[Ô—û*Ù“íÍ,º!×Ô
{ Öı^fÖÊün+£âÒ²9vË©-›\‡Êë½™¢hÛÑ‰#YËwáÄ¢F›!ñ¦ËÑÄŒSÒŒ”¼¸ WBD—ï"ıA‰24³CÔªàşP"ìW$+Ç­½Öv»U«<=*CE‰hÔ5uWP¬~PPÎ=©%X£â,¥#ê4tthA:»»i"Z £ª•YcJ?;~¾]¢?kg–z/oÍ6”ù%T	”_Ú«\àÀÿÀÑ™Õ~K@	¥æÀ·õAÜCp(5Âç!à,•›Ám6€§¦ç']«B[Qj‹bãÕó‡±MeĞÜ­jì3¹ È±°å&³}ÙÁwr	Á‚/‚¨^“‰²kOÄª‘‹‚ÖDº€2u¨Å3£ò¹«'_ä}©½kğKß[d8ĞE1„¼U>±ŒûÂe„m ¢¹âwûÀ=úÊ	‡ìZ0Ìâ%KÇÌÊS•À«^û1°f¤ÛÂ3^æ9“AØ~‹ÏY<«Ÿã‹±XĞ[óÂ©©}¦ŸÕ¾ß8˜Ş’hgÇq±šS4šöû8#ÌcaùåÏ:ŞP«É®¼Å—=ŸÇ-‹ÙwŒCN<ş\T¯
ÆÈ| ›7Îm4/“²ÜvUñ.½[£nÓ*yc½ã¶ıöpr2.íçóÌóOöz[!‘±R	7±Ø&ÜàÁUqBWD5`ı@õ’5³ÒêÂµV«µjÕd4cÅGb‹á„[ê™cl6I8òÑ•„¡„a£âe2E†–AÉÌG…Â&*ˆ¯Õ™³ûÛïv‘'Ù>êìì´şÜ\%*á¯¤"Æ·;¸^JÆ5ô±;ùåßÆQŒZûÀdl&¢¦!8,¿`„º%ã¸ÿF¼O²ğp²},Yô\Õu2vŞïÓÕ…l.¦FK?C?…k3pV”Ál²Û57¯`!sÄLm³­!JmÒAeUğ…F…Ğğ&ô
Ú‹úvúÓ]ƒ~C¬ÀÜ£Ãñx:š¬ê1”Múëî‘ärÁkútøs4²ëÁ01ŸGWnÊƒï[ÑI±cµÚ~×mc‹<v²±¨n5×ğ³n¿MŠ+¡6éAŠÓ›;ãi¥ñæ;nnÂ9WHCè9ÇÖÂYre~Î6&ƒÉr¥Â§wòŠivva@Jau@Ÿ`²œl÷òÕ9B­®ˆöî»İƒ ^,¤EºŒ6ŞÕyõæIæƒ¸lNºJ‚©ü+R/µa41véŒ¼ÈaV¢Û
¤ šW•ö=†W>#‘üG@ÏIĞ§Ÿ×ıqãiµQ}ê»i±ºóíõ«—q|Ù«ÀA)Ò¬Ä8A ½>U:²<F'¬Â|:K†áoúÅhıå†ÆsuR1Òè£˜rçæoC/K«Ã®¤OÓµiuAÒ—lXÊ’¤Éåà¦Üùóù<Bî•Ò¥îà½¥¸úşMT`{ÀzƒÀŞÍˆ¿Sß¾¤"qÃ½0s¶¢ß`Ó›+?ê‡Èé_Ñä‰¾áS×™/»UP\„@<R§®È‚±p¨ŠË$CtiÙrDtaaÆèÃË¦vZ¿KÍé+¡c¦î4WÆl¥*nÂ°}»]ûf÷ø÷Ø×Œ©ìçÃ~/%ï†XÚŞ‘ïà7yè–~Ì=î s6¢‘ï{×:ñ³‘ï€$Ow9²¦#^ŸîîI„ÙÂ‚ÃO@8““xù§µİtĞOpÎ‰OpøÎ\ê44Òó`^VZ1/q0şN:ü@›zÑÁèc‡_PiÎhI6q÷À°,$´ëÅâA‹“›KŞ5±±õ…“°‡1©Ó»tĞ¼4«-œW£y¥\”Ä6œæ±Ü–w ‹æ‘Ÿg•@dUë*/•+¿–úIæBZşìÜ6¤AÈè¼z›ËÍŒ)+ Û|ƒˆ	¨¨ŸtxØÎŒ^Ü*ÓH ê/ˆ¹›‚_’ÔC÷,õ»iâ¬6ŞZ¤TSı÷"ZR÷Âä‡£ ÍğLyKb=&®šúæ/ƒL{İgÜb¤Œ_ªôIµ^ªº'uğÄvßx8Ú]n£AhŞ¯´·ÂvœË:öoÈbEª4a„³@q¨¬\(KF#×ÃÇ#]´NÇx¯—z`ìª/™mÅEI—%šeÉ¨õÓ]1›Ærj•=¿İ‰¹OŸ›é§¨vsn¾WiÊ§,Ïl÷z=ÚÌ“X(ŸxcÔ¯ƒ³¬‹ãÂâ	ëŠa¾Ee'‡´ôå3Õ§Xı/ìuÆE4Â³êázcTÆqi÷k]^‡–¾}YÉ/ÿ¦ŒïEˆÖÂ(gHD<» KeÅ7‹ƒš'í\HÓÎĞú‚›ˆu?àïUQ2
yË—_…}%¢‚ÄVAè1LÄÀØty–š)²*_äPÆ²CG/¯¬¦œ6°—lV ûK’‚QG3zj	fU–S5r4¢¸Á¦» U¯Ñu„	_ ë"uMaû¿¡1Ç!EA0÷ş‰ÀÌıèç@.1Uo)çHÃŸ+“
ÅÚpÀøA2v÷rî5‹í‘X±Áº¤Ø"  ğ€<úûÖ‚J?J8 èc JSæ€2Pı­ Z%î3t;¦rìŒòôvŒù+eª´ßT‡Õr>"3H@d½tù·|oááÙVû ˜ÀÂ0{şÄÅaˆ lŠ‹àg x‡'e7PV“³-¶$†ö8$Y@g½³ÖYË˜p¥]]0·(AsÒÆ0'¬Šn×–L[nÙ˜u?ÕµÕÏÄóÎ0sFµ³²±môG¹û°w•íßÙ:…eB§£S¬Å<E¢ó+§âá²³Ód7ºä‹“í!5'‘ß/j€ıùY_XVîHbB”Y’3½Şr¾½3¡©%™Iw:[h’ø[BíéŒJÁèòÚ®†Œ4Ù“ÿ+vMº´ôÙkŠØV
]À§È·U@ê»ìîŞG‘C¥#»½ózŸöÂ+\4	q÷âK©Èšjû^Ã1°èJË·´Ïf)Õğxh3º"owb#iû²[²)1×U¿5Ûe¤•„P™Nj††qÏYè‹ò{ÿå9Aä>,^ğÙÆêÒïÌ0eØÎ´³›Á¹¿+™e¶
NnP»_îÊR§R»Äw>Šš‡’»gk%İ†¶m÷A¬çYô»4—€ËB)ÄRRo&äÄWX3¬z3ê³{’5°µ'SÕ"ÇQ3Ó;Ù=œ8¿Åéaûá“=0.î·Ts-ÉÓ>Ó/àôR_6UVG?ê¦†ãøò±Ka‘…àu'ãşEÕ¤ujÖ¦ÍŸ¯ò`Xzä²›‚ñ°©û“Å›ªÀ mà}3u….Ğa6•ËØ?ÚÛ}³{ÒÙ~setöwZp/@£ƒDÀñÌ—ky¤æÀ*ÿ7+$#êz%n`+—7õR;§ÆµYC(Jñy”˜‘ø‚ŞésŒè,$3²:–ò(9rJdGî^ka¥¼İA4´V¸­·á:I§şm4˜3ò²ç`î¤c¥:úËJ$2ÈR¡°”İ•
ì„=³PÊH]ÒEQ‚!‚2‚q ²;9;@¥wä·¸óprYBœU»†¢Š(ïÂ¼İÃv¢ëdIQéŒƒ,sŒy§–ó€Ì³ÔëÒMr'“7Ò-aîq!_îˆÿV%˜$”§õÃßÄÿÏó§Oğßğ{#çÿ§ŞxÀ{À»-ş[‘¿Ÿ®Å—ûD£¸ÉS Åë¬zÀØ\l*5µëëëêUtÄ¬OÙ«çãZîµ6ºı©pm‚¯”eÇÃ
´7®h¯AÁø+¡Â1ò™zÒJÛ³²*´ˆ ;EÛğJ æ'Ğ¾Ãı£ãÖÑŞ_È“D¢ˆ
;?ï´ßÓçü&Ns¦¨0´‡®ÀøŒĞvİĞ¿©À¥Õ{åßJŒ"´•ªÄVÆºdï?¾¢Œt¼*ÀË|†¶~Í¦¨<?z¤F‡ĞOŒÁ%ğ:•ğA[×…JEfgh"v£ü:ÈEå­(Ra†/£r«ÕÚíká<ªôŸ
øÂ'_ÿ³Q¾ñ,‡ÿùôùı ÿwÆÿ\wá|Ñ)kºÒÄ u$Ö‰q…\.pgÉ×qù–Ê‚Š„ö¸òr’Tñb^RÒ€¡ò6@ÓS	E£îiˆ=oÒq“É#acEI­ ‡'»oÑJı`üj‰æ0D7DJ_õ´ø¡Én²ŠÚk¤¤0$¯PLwÉÿ™Š1üUOsÊRmèG°IOéx{÷¯bçPlï¿Şmœ´x²<u‹ã
Y=ógÚ’ZÜo4³Ê»İŸwŞuv¶O¶Ñö İ4Ü÷nx9 §bDúS0àÓÉDşĞÚ{ƒcîó`šÙ§ß{e;%
öš(ùg“³ÉQ|ÉBu'Fa_öa§Gã ’(¥·êqXÔÑ>:¢ºÏ&%ìÚ(œT”¨?«®mˆ½“v.âE6‚ß„÷a¹C¤3”J‡&¨!— aoa‘ì4ıË!"¬ªhiş/’Q+T>Ö¡Ğ«æš™E;³_¤üıïPt‡ûÌÏáú-_ŒºËf
ú¥ëçe=yä"h-0rßÑƒœíïN`_~ê]"S6® ^%_Œ‡G'Fë,hŸÔÓ‡á¤ÚÕéÅ`¬sšÔ =Y¯7^xè³¸M ÃË·èa6À¥t²»Ú  `?6'©l¬¯¯?ÿÃ36+QŸÔf
Í_ÖÎuLÆ¢ª9®¿87sİ®-J¯{Hp:F¹_dã>½xÖy¶‘kÙÆÜ5³¶‰šU0åNK gÕzµî{3™cÚ6³ñÂ×K5¯ÌŞ„5“‰Ì+¦c!Õ5$‚2©[+»¹ÜxÉ–¹'sà\V½BÔtguVYDµéÖ,}á9ôOMõÓ­YŠù˜›3áWjØF?YgUÕ¾•Q··ë(RgŸÙÍõs¶EÂìÎUæuúPá­SqÚèDªÙ~ZEÌÌÚ$ÈÚ	Ø=š1”&2@J.£É‡é9†Ÿ#t=ÌDV a¢<o‘âPqªšğí™Çˆ¦¨`§ëìî´Tªğh1”ÀãCÀÇJ"E±€®ù¸,<nÚp>Y%­Ü	¯ˆO;Ç?…İ	š”t±Èº¢@8İĞìš
`Ğjq¾/û­ƒÓÎîIkßJïæ³jÁßªH9!1ŠªKûqı’S«IØFµNÔÇ—Íe^öƒjkä/IŠäÖ™/ÚtëÊêXÚs+P×ÄqËak®/é¹ŒĞ32ÂÖMúñ¦0©q$l¢I©³U|©@Ê*Ü««Ÿ~ö=ÓÖÛfÍÄ¼ô#Çä^HULß;nmïQ©’ö›õTÇaĞ×…Ikòt M‘eé‘GçS^sfŒzJ']ÆŠøĞEs"ƒ'§ÕÇElç¤‡'œgÏ²ÑM_¹ğÓ×p;g­vV­u¾ˆÓ/|çBTr‰39‰ÑİÓru™Â:OD|?Ïà÷9z6Ñ®xôz¢³Ô “znlcT¯†Õ‹qÈÓ§A… šljm\&µlsaÆ³^Soµ{qiqÏ·HqA ušR¯y}:ïÔ7¤’¥Ğ0ê˜bÕQ’I,'“JÂ*¡^}Q¥œKgëV 'L­<>l·;ÛÇûúº`rËäj‰5ªñ!>Ô«¼xstªø'Ô°>ÔÜ”2&"®¿Ò£«Æñş·o}ôZ°×Çƒ«ç/Ôíñè¸õv÷ÏM¼Ï.¯z%£i˜ŞÙ¸…ÛÆ Zµ¯ =0î|gX³J…Ol8§šh/ÕëUFül<“FqêóqÔ»Ê9¹É é`QÕşè# FÀ3ÜTøe·Âp¹®óérÙÀ%¬ikş}5YşLSqÀü[¶»HEéê…~ı®ÚxÑíë%`|wî0q,·Şµş,¾ß>ŞEêÑö¼;[ácˆ%ƒ "ŸÜèËœh¢r±÷gû
GKtş©^¯ôÂ+à÷Î/'Xé_pñEŸÎ§F`7ˆÆqCı‚=r×ÓØO“d¢¾ƒÉG#æòC·¢jÂsã²?¬§_î{)mÓ„Ã)"´‰dz~Åd1>†‚§8jtô‚204Ãt8ÆB]˜szçâş#o•P;»Xõ\ÀóDFJ‚áÜ…†Ş%«gB…rØğï5™>Ù‹®‡$‰^CãaûëËÂ*hÙqO‘~ÿşGÏ+Ôarkºhù‹Ë¹J&Ò­ôs²Kì‡í]¸Ù{.x”"_k© N;ÕÖ<o—ô>Ğ4dáÜı€r}àR!ç;Î£ÊFõµÑ8Ä%‚Xı©”yâÑ°PºríÓ#\âÛ4ó¸}/ÒbYöİºÈg¥İÍy]4¹¦9göòW<´w†,Yÿ¿Yvn¡JcºšS¥ô¼T×B4Ë¶"âöù8Â}è~ô	(ş:r}¹ÂÜB_+s$\nßÇÊöM§g)y—UZüùH+¿éçÛu²üb9µ”¯^·¨ŸBüà»ÚnT7PF¸j“›“ljãşG7Ù§tè™‚u…O9õ‘ÙLMX†Xë,DĞwÂc¯I%­l¬ÑËü½gğ¨º[tg"ë< ;è›f£RïP~$ÃÀE,ÿ‡´uÄ¹5´5ËHİ+ÿÿ€C!uøBê²ôö<ÏXr3œŸ6ù	ÇV{8›Äğ_6,}»z¶`òcj]OŸ;­/ïãQ&Š+H3Ÿ¢×f»©Òv½i3ÿ)d|zVC³ìRìŒÂäïÿ®jÉ÷‰›mªÌÖ˜«ãx:Ô¨Œ)Ÿóşş¯ó«3ÔoŠê;‰ÅOÓd¢U{©Ú¥‘)V'ßÓ²Ò)6+¸
¢>¾“£c`ÁVç·†Tƒf4´†ì¸†? F-X>«ÕrLZJ&@C‚G‰¾P\…Z5SåpqV7 :çæÊüÖã6š³Ûè…
Ó¡Óøì?,>³	HÉXò^ÙÌì•l[DnçÏ­¼¥·ã·‡í#µTêÒÑ§û¯[ÇÙÍš¨Û[3×’ôÆà¬X«ÖŸUëª2|k”Ó¾Ä¬C×Í]ÿû¿‹×7t—·œ/6P»È+†OÒ"iïOD$•J¢Dh|0nGŒç
…§÷HößÿUì^`*tEßG#Ì3;mBÔÛÀJÍíNÊİªgp<ÎÕÿµì¾®şo}ıéó¼şïÆÆƒş×ƒş×ı¯;+€Kın:`¬ÚŸH§ógR1&­¢¯¢ïËXòånÑ§{ô×¢µY‘Ÿãş1Kñ<æ[n¹+›¥Kê/’aÓãa%Ajœ‘EòX®¼m:Cuï¤öğQwÑ¼teñŸ¬Ğ+u¬«şa;Åµx‰šÁ—bdÒŸ£QÓ•ş9aG9¢¬ı¹ÈApu;Lª HhQZ:”äƒKK¥:…dŞœ iÃg<g!JëjµÒndñî ì)…I5øıLÿÖš#úœP±´“Ú\ïÈgm¥nÚqJÛi¸uz!ê<÷Pë<íùûl!6p“_6³:<bS,‹jµ*ì´Ò€WTÆWvŒ-J‘†b"3­·1¬§Ô†Ç´ô’æôãË¤¹RFŸ{6jFä¬JN`“(-±Y¾<•Ÿ\/}^]`£|‡í¢Cï‹¬ã”³[›Òc(!ï¨ørïe,›¨›éâüvÈ`E.nTZ£câ	hŞt]d2—§l²YVø
FûÉ.Ø?:jš˜ª¨/µÑ¨ûé™Q±¡‚:9!¥Z5à°m@u[ohö‡¢’\ä­E3~O„]†(‘Î…R’Ø 7ò)ì/ÁáhEFÂ²k7›bjTğÂpeZBÍàvp:‰–pŞÕH¸½I©
Lo´+	ğå-…ŒHäÜ1
¡ôŸ6ŒĞzğšw¦²¬[*i'EÆ¸¦;Dz¡µö):Şt<¢Nkßâıäg.˜¤3¹ÑLØã³ëíi8°ÇñD?`Û€õdo'Ğ>nÈ;CA¿Ä““ßà[”—5A5ìÄ3éRû›í.Bmğ•²®kÍPehƒrIE¤vÏŸÙr	U¤à¬ØQ¶™¹Äå‰qHËNë =¿üŸ^@À8àÇdÖ;æø×
Z¢†æ µS&Ù!±'â6<z”:`†3öÕ7ğƒEáí1½‹JÒ^”õ­7Åiz´üË(
Xä2¶ÆèlØ‚³
aSu3Ï€;º×óé²æÏùÛÀ.ç ¬ï,$·ÄMI5tª"û®X{¼÷‘í:	ÕïM"	½ï%B7`Ÿ­Úk#°ş	¿—ÅıÿAJlÄh—·I?D\5]*Q(môí¹€¶R»ólÅü¦¾©ˆ`)€×Ù]´z¨Û~çNŠôÌVh9»õ-İ¿Sl¢2½ô·PÒ²ìÆ°w!ü:%ÍŸŒAªKKl¸WÌ‹‰òc`¸¥qÉıÜÀĞ"—•CşoP­·ˆçá‡V-M¥ZÁ¸¡¥ß¥Ú ’r­Èc©è°j Ì¢
XÏ c¯Ş<G[!/=¶ŸÁùğ·¿©_ÏÓJÆµápÒ*¶2\×e"ìY\ŸLñT¦@
¦K`9Ëo¬(7DyC”ŸeİqwìÄØá)v7…I{2F½«’Qd0&àÅ´O2€éoÂ“`H.¤!FïAH<é‘»Î¹}9ä
l¡¥S±¥‹Fn@ù¥mk#3lm³àki3Õ¤Qˆ%ro1•Ó|‘ÀÌ.¸®­ùp]rBf [@ã-ïi’i×»I¬ğuûiH”i”\=Õ,œ«§Y¼»®8*YZê$¦…ÔÔIN%Í®o9 Œ„»EŠäâ¶ a1—Íl›bà•y'aºÎèqÆÚ	™S‘"{ñ‰ÕÉ÷‘›E°Òh8<Øø¿i/t'ø…éîcvë•—Aírà+Íî‹šéFBÆ¿Ç¶—–èŠ…·¹6ü¢BË*	5mÖ‡4é¤µú¨üG¤?G½ax‰BWA%MéPíõO¼—!§J*ßÁWûUŸIuJ|óWEÆâ#4ÑI!—ác›k.wŠ¢À"¼b®,f·b=”&A×û=Èÿ«µ^ÜMj¿isğ_ğ_æı§^öüÄÓ‡÷Ÿ¯5ÿpœ×~Oóÿ|£ñ0ÿ_yşÍçô¯9ÿëkëõìûïzıÿãëÌÿ™œ#TcÇËŠ…1S=ùÖ†„x!||VÛÓKQáB€›Oœ¢J5 ãeè{Õö·â`{¿åÙªg:é$Î(Q–öîÁáQ{·íÙ­9{
fvñš%EgÇ?ÒO8tágcáe€s\‰œi¸\J“É‚¸§ï€/+ÊªïVºUg•3fó!ÌZáéıÊ
6®#V8i÷PW`ìvZí7Ç»ÔXÏBr@í¡ºÙ»á“~ô1ÛG'Op.¹j€¤¬vËıèÍB4,CiaÚTVNuV´Ai¥ì“5„ø=5cCåøz™ñ’ŸRêšËÑ÷2C)Ä’N-2Õàhrœã, ×l.3¯\AU‘2ÉÉ1ØLfM¦-ĞÀ3óğ|©	…\ÊiÕ¥îåg(Õõ#S©ŒÅñjØì*GşÇ¿ıí½Lğ£PMJÂ
qĞØÕ5²` ël©p¼«P¨TÕ¢®I-×fuhhUÑĞ’Ëš·œ8MxÅA#d¶`ÍÉAB0¼d·-å½™-ºÂ è
ã¾OáBˆ˜¦’•_åÖCÜ¨`Ó¹×‚™ÕgJ»µ2uÛŞ.«®-úÁµÆÇi3QP÷0)‰vÚ²<	‚Ëİ(“¥ÚX$èó®_´ÛNO¾=<ö²Ğ,+=
èÄú?}ˆ'pì£iùªçıÃÃ¿ÿÿ$ÿ×í°VºZÙgĞûjøokõF–ÿ{úüÿû:úâO}Ğ×Ç'ßoÇñ@HÌ]z®z¤G|¢Æ@Ä†1ËÁái)¡«ãÎ{@áâD¦óšÍ¦÷2î¿ò–^ö£W/ña^8Ñ-˜T)JERµ”@V´˜B,€;LôŸìâ_‰é¥÷e-xÅÜ
Yò!êg½Ò!¢{ÈwÉm’} '¼&Ç«_Y öäe‡î]¬Q/4`[ŒúiFšÃQ8ÄI
Çô…Å
òÓ,”$gxYÃYñZŸèÈ£W ëÙôWëÊ%›<£qøJx'±ˆf™8lB[’É8^¾ÊÖ+ƒ!ÁùøÕ¼r´]ƒ*MqWâİé®Ébér_&ÓÑ«:ü„?/kPÅÜ–(½ø—áà•ùÌñ²l¥eú 
´o1iXÒâöTÏ]šÊœá€¦mU’ª'NksfÙªHƒ5[R¬™İ#Í§Qeº8fÚtÒ%LŠ¥jüŠŒ5îÒoâ£dÙ¿Bmv.lï¿Õù¯|£&÷{úÏ=ÿ7Örø¯ëOÎÿ¯sş[B‚c^-`×‘K
ÎãéDÃkqÒ‡Ç]}>½d/Zõ¼+RÌ†b'ì†ƒópüD^>Z¾»ı õC{Ó<¦È#Ğ)¦vèìPÄÔ“Ç‘-(lâ‰`T#3’ıV2#”p‚pqÌˆ]TvéM»ø’PÏô,6‰äXHË@{¦£jòA’m£Y†JÕĞ¤>™öbôà$¦ÛYb¦;¥ó€ƒ “¨Æ@p&%è¤jf•À™õ5$vÃøZ´•€XÁİ¼IÔ9?í|W¯¯>RüAFXÿÛİ?·v
&€b‰`*şèbÔ|DåB*ÇE½æFâmô	ÆP)¦‘7gw&ê+°¥´––HöjÔì%¤Ñ¯äêjÀê:®ÃÿÚáhBkL¼(Ze³zi,¥Óã=s”rÕmO/ñ©ÿá«İ_A)Õµ¢¹a-$KB¥Ğñ©ùD¬œM‡˜`¨C3Õ_Ğÿ
.¹B¡Æ|¹Aİ7ÙAÎÓ&‚!– Ô¸L5O©yÍ;ã$’$"E3—Å-^s‰¨JÏZ]0˜X9•äeô! ¾¾ta ‡œïüŒÖ½ó„B1+ÔŠU³}<#o50 ÔDI…DVØãÁ™‘œŠT”£Ûíãı«ç59ß·Ëµ9ò™¯aF°PõÍŞ®ØGz—a’¥oÆ¢U¹HœœrzÇšÓ³Vôí—6³9Ñ®y¦ÔÇ¬¦&àöG`¸éd¹ÖÂÌĞ~päÔX	/…SÖ.¢6Æ-î×ÔÇ† únb×,¸âìànÃ}Y°Ò©ùFŸ,öãô÷t¨O1Y 1Ğ2v!8Ç%z"$ÀñÀª…çANö_œÿ‡-{ß\ÿâüÿ:ğü6ÿOøÿ¯ğïñão†çÉhËü¿É‚®ÔW9P¿"Ÿ'ÿë^¡„É(2õ?~ìyã32|!)V º¦Û€öóÌŒgfUßõùxüX=<Ï¯(ã¥(’ŞÛ´ÀŠŞİ4ş1‘ÏpiÔÌÚîœO¤9õ“«Ñ#ZKVÒÈlœ:ôó½±%gÎŒ—@w	ø¾šïVfºŒ·n{Æä¿û|ÿÎ<€WókÀUäcìüW<sBX/æ?dFI.’ÅkÈN¾™¦à±}fA™•²ªJaÖºÈ¤oóE8–¦Ây)x±/*Éµ†9ÍŒg|!ÑqhÉ(ypá[¾X-XùÖóşm©•p« ˜]Sò_£cÆf$ÂR- @
œiŠÖ°ƒ•ŞÀ,Bzga¢Hé=ÉÏ?¥t º(3¦CpÏúî%×æ1*ÙyCh©,õdvîÂş+÷jEäÛ+:HM©ê0O×kD²JúP©l‘Ó'x¸ØHş?†D.8ŸI…¼÷x˜÷ş¿ö<«ÿù´ÑüÿW‘ÿNh÷ÑÔÃ©üÏÓpL*QR’~·C»d‹£Ò›o€çİ y?^Äı~|"…1”ÉÒôÓcÜ“›QØôw}%¤8Dø+
A_¬§¡-W!Q‚’m ÷¢:pŞÏ¥Ş@í¸µ½³ß‚eï¿RdƒÒ÷dÒ% t ‹¨A7©¹%”“—wÓsurSgÔ#ĞÈ°H‰EF5!åü¯ƒúÏ¤sÇ(F¢ßıÿ´óİ±m>0ÊV£\I©=¬@%Â?õ>V^TàÿÚØÓ*E‹G,Zl`Ã¢e_ŒººÄ¿ÿ»øû¿ZÅ’èI¶WJ²èøèß#<zx‚ƒ.Ô‰¬ìò8InôÇmœ¨tHĞ¸G“ˆèIÑZŠ¢hsïN–ëHOâ>šµ&#˜9qéñ&¡¡4˜ìp­*"è#ƒo6Ú¦n 
PJOz•aäŸ¶”1âó,Œ¶–èéµQ×»Æöê’6à‚Ç=µB½‰ˆE¯ÔG–=-ä„ÄªE©¹…ò|úÿş=ü{ø÷ğïáßâÿ= j† h 