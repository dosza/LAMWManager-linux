#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2015997461"
MD5="940b2e1dca7cf508c2f20edd47a3a15e"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21126"
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
	echo Date of packaging: Tue Nov 26 22:08:16 -03 2019
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
‹ €Ìİ]ì<ívÛ6²ù+>J©ÇqZŠşNk—İ+Ë²£Æ¶t%9I7ÉÑ¡DHfL‘\‚”íz½ï²çşØØGÈ‹İ€ EÙNÚd÷îµ~X"0óĞuıÉÿ¬Áçùö6~¯?ß^“¿“Ï“õÍíç›[;ğ{m}mccû	Ù~ò>Í€'–éº×wÀİ×ÿôS×sv9œ™®9¥Á¿dÿ·6·¶û¿±³¾ù„¬=îÿÿT¿ÑG¶«Lv®Tµ/ı©*Õ3×Ó€Ù–iQ2¡L‡ÀÏ3ôÈQà1æ‘§gfbV•jÓ‹FwIlSwLIÓ›ùt)ÕWˆÈswÉZ}³¾©T`Ä.Y_Ó×·õµõ¡…²q`û!BÎ)QeiW‰Íˆo!ñ&$„Ş±Pü}Ü8yÓs :œ˜@ƒLr˜¾O2ñ¢â®Cší‚(9uv®~N*ôÊ÷€öƒÖşÙ‘±–<6zG}C­=S“\Ìğä¨7lŸöãccdAs¼Ùéµ5m?ë·†İ—­7­f6WëtĞêaëM{57a–á~£ÿÂPQ®R5g} VªG¨·:½àºÈwØæ€*ö„¼%ì[­ûú@¯×¢’÷{¸s®R)'‡Áü£K jkË:nrÏßæìä³[¢Lle9‹k¹Á%„+¤„¹ È·fìÍf«±sÊ·FA1vß0t'°-ÊhĞ™h;”=]½!J%á•Î|=]{îx…¬"Ál9È¬ê&lÓñŒ5Ø÷{Y™ÑÙ6Gá gŒmÖ‡v @©ŒÍè4ëÓÀ‹|òW2¨/†Å¿¶Ÿ‰nÑ¹îFS]ûùÆ kÉnÂb*‹b·®Tu|îCÇœ2>­K/»a@:N ˜¿®(ü<´]Ë¨mÀÏ=!Ô5¡E­% j9Eå¥Ó¬gm\çj7ø¥ë)Zı–T|,&¡g™ÀCF<Øá Ì˜¿Áê	åMW–ñwD…Ìg )Ê”†û NÍ“¾lA¦€3Èz¦	•E5¬¥¿‰v¥¦³õ"7¯s@ß®§˜‘®* ÒÈv˜wj6‘ğ©%JY{–*•¬óµ?-µë96hÃK;3Âó…ò9ızEÇ„ºsrĞîw¿µøyÓ8¼èôÚhË~“Ï§Op•Ôr–­È^.L~@ªÀÁîze‡¤^¯«{5­”Ã¯W¹ctBZ\?®˜¯4–RÔ.’K”T©d’ˆA¦&b%nŠesSXI·•7ÆÄÎLÛM)Uğ‰“Õf¨ç=ÏîS©dš¬t¾O¢NM”9‘ç·Ê3˜ÌÎ(H9áŠ¬TdàäÃrøVÔ¤%O?ËãğÂ¡íNIâàZõğ*üñÿÎÖÖÒüocãy!şß|¾ıü1şÿŸŞ%Ú¤ˆÑœMÚU*ë¤ãƒçãÚ”Gh²ò+Jeà‘8~äC¿ç†cÓµ`|%ŸZŠ‘oAŒğ¯OğRèGÅüjú_G‡_û÷äÿë[ıßZ{ş¨ÿÿ™ùµJ/Ú}rØ>nø†¨­sÒ´1bû•4;§‡í£³^ë€Œ®óQŒô"23¯¹À‹xQaÍ£°àú{2‚gÓ…LbŸ€Ì<ËØ“@0Ãø¸%ÇÂz¾,°˜ßûfÀDT'+Å‚ğÈ¯‘«Tå!q„O4MŒ¶¨cÏlL&w®3ó‚2êLˆL#$‘IàÍÀ€ k:12Ñ1ì’ó0ôÙ®®'Ãê¶§¢‚’Õä¬æöNƒ|†ˆ•#Ë¯|Óe<¢=7&0^E™ØƒÍ#éPàL¼ÓÃ~à½éó:‹¦ä­~Ø=Zå¯iÿyÉáß¬ş¿¾¾ıXÿÿšû?ÆÂ«6ŠlÇ¢AÅø6{kÁÿoì<úÿÇúÿgÖÿ×õÍeõÿ¢ ?ğ $Œ=74!õ!D#¾íà@ş)uiÀÃ@ˆb»àñ¨ Ñ;™?':i4zÍ;[i¸VàÙÖWrìJÕ¢!‡&Ä(¸ÿÇ#–G&ş8NãLË$®GºM‚õFËrólsnS^¬4g#^
»M¬;W”Šãqm'À£ö4­ÛŒE´îÒpËÃù)°VŸ©g£È#²şC]}€iËŸC—^#0tBÆË®{{|Ø±íFWäb(²şãÃGRf•”œõŒŒÍúZ}-ç¬w<„…j‘±¹[Ÿ";ˆbœºL±I.ê¡9ez@
ˆ‡›Ãµáš*a,Ããöş°Û¼0T=bîØ#È¡ªXóğ(CˆÆI«'Ó"Ê^ë¸Õè·õÎ‰_µzıvçÔˆ—ø ²ôš4RÍ¸(¶ş@.m=hI[w.	z±;=I–qõÃÎ4ÍAAÑ¦n´°®´À_åâ CPš¹ò¢fXéñâ«Ã¹)*Ã‚?¸èRò:ö=ñF=5ÃÿÂ €Ã¢s2$š ø‚0{6úøOÇ{|î
Á“-Èã=›Ç%»{ñ‹ƒ?]’r	¿—±W,à3¦Š×ÆÿJº+a:y‰êÒzÓ³synÏ‘Û³PMÆ¶WÊÕZnJ¢ª‹g'å˜‹Õ–Mõ°¹¶D‡ëEz¥Ê3Şô<{2.ªïÒ
	!?½Páğ	PÀÉâtƒŞÙéK’òÂbµHV´úš6× ¦`ÃE¸ÚÍBÛ·ï´g·9ÔñQLöçv7>2İ:nŸ½¾èœ´¸`°s¢SX@:$ÌıW§ƒÆÑ-7%3ŞÖå½ªƒ>Ö§¿©%«K±túT.oz[‚6b¹.Å¡Q=%¬[hÊ“œ9†Úâ
ĞØCÄCº8„T–h.V /^,L „bÂÃe›šç4‚™8å=7İ)ÍÎí*v‹”@JÖ]©`mƒŒÁÂ£÷8–“ù¤¶Lšİ³á Ñ;j,`§;0TÍB\@bëX%~Ú/"*Òìuú}ØôêÕóÑš“W‡İW›*I„¯Ûk¶ß¸3Á…*_nÌ ®Ê(nIU¤’İIÄ±sÖk¶G%/r`É½Vl4~ƒ¿Ù~ÂµÛ²’î½ï¯v¸,;Oç¶F.Ş€`Ó^tnMÀEZAà»äĞ2iÿ5Y}j7§ŞIãøV%ÂjÙpÅV©d‰%‚¯¦Ç¦µRíW1´@§©ıv5Ÿ,…ª$ëËØ¿$ŸÙW@^–ÁåÌjõP: lá:HT°ËºĞÆç;[¥úğCV²İÒn?@L>‰äçµãÅá‚´—Qw—@-½Ÿñ y*š”$ãÑcf‚¥db…›r/3¾´MøT.U?mûä{¶‘#9ÙsAó|ëA4Ç·ş°Mä!ÙDT¥[Ø„™Ã4¶Ø÷¼°¦Ï•-¹@ÈğBƒ=„Tâö¦Ô&]u9<n;h4§½Nû`ËQáÎƒŒSñ$dÍÍ–¨¾Djxâìj—ÀÛ?‡œœç3BRúrŞ–ÄVåË#	±»ºY6®TúÅ¤k/Ì)÷ uØ8;À7Jmóe’°Û®E¯ø¥—$$µè¿­ñ¾÷·Ÿ¼Ö\@™pø±Êşo_ÿå×Œ˜¸	Â4jÙàÊş°2ğİõß­ÅúÿööóÇûßÿë¿3,ıj¦33ÿÀú/I/€kñyc‰Ä?°Ü£Ì÷\fÊk»!ôæ.6êâ1ñ:qY	¯«Õë_‡Û%Å†ßm<sƒhJ5®d™ü®%SÇóùAû7
éu:ƒ!ögNğÄk‰Kè¼”ƒ‹Ù`&šŸà>N‡óû™xéQD-õ$Ê¼ŠÀ´0dğÖä2(= ¾Çp—m¼G9™f” !œ’»çÇ•ä!*ù™ïŸ ;¤®	bÓ8Ø½3‹Î97	ñÛ'd¥¶ßÿµ?h†±‘ú=i½ÛzE]Ën¡ù§W­ÓƒNïgè;é´umggz³®¡úN4¼ê;w…¿BÈF©(ÆGxÇ9ˆPü,}{]‹)­ó&¤Ñ`×p¼ŒÅãb<VåB±´i‰ì¹‡œŠùÇÈuÏÆ$AÉ]QIU?¹2"g¼ùêÑ,Vúfxn,/Xj^! ªr9©]‹$by +ŸÙ¢jœ®†°õCĞ4ã)Ò¤VÛ‡°vk„*·A‚ !µhJS”ä1ÎSÄÓ+ù±ß,®GÆ»IÍ‘­Åİ‡N-UZİµ.tß1C0W3¦ÇĞZt2Y¼Û¤Æ„=	šcøm9uæñ†¸ñ €;ô<raÈwôr¢¶ê?ê~@Ñ…ºèU†¸,V©¬h‡Q~kàÏ\y=Äxˆå”†+Ÿ<Böc‚ĞY»J×>T¿W%«ƒD‘Ä¶TA³ğ†8‘äDGX„J…qİ8¶]j»x‘¹€“3IˆŞ®½ç‰V"^xÊw£Î¤g 5¹³¾õìˆ‚ŒMp±BsAqaÃğÜ5~03=¶ÄÁC’×Bâ7®¦$ô©D•¨S	I‹õqµºaY `]Ğ9zİÀCçÇMˆX€/ZâcÃ¢åÆ $+òb“¨ÅÌX+â©}ÆJRåµ]ü»[;ê5[9ˆÜ
ğ«í‚Í!&ùKD÷Ó½ÀHŞH‰'P>BxQ 	è+‹»­Öd¨Òsº”ø]–ÂÒùnK{ë¯®bŸ¼­{c¤Ó¨ÉOàÅ~&dé>äÑHÜ4dÖr$÷à(Û™4(ZjPV>cq¿ïDÃ|	’œ‘Ëh*…-LÈ«-ğ¢<3A×[M|Èc=¤Ë§x=)#‚F1î_ã3w˜p€ïağcF¯¸¥Ú‰ÀÒ|0“şˆEf`{D\ÓÜ{É_j$OG€aefU•ÌÎ¥Kƒ†ã¤‘8õ\ç:¾¾­!†Dúª…
@¬¬äac.İØñ‰êÔP”§]hD„5•xì˜¿Å.cæY–\Ú¿™AìíÄjÛ1ƒáñÏŞY_òØ?n	cœR–R‘NãÌY3išRİ/ëMõ¼¬3^Ë’^N¤¨«÷ò¨0Âs^_EŒWè&ä%qB"’DõxwßK(ÈS>µµ=û§ÚMUbÎÛgïo÷ìï¾[r£Ÿ84½d0ûı­`ñFIw³ŸDë-+î öËZ—âÜ)—Èô]…·#¦coÚ’Ë@;kCÜ>¹Tµ€(wğ¦ÄALÊU(M9õH\òz™.¤ye­üôDm»o÷TåZŒƒv‹¥Û´Ÿ\zÁóÍ1™ûºÓ{Ù‡p¸•ÁÅõXV6WÌº3&ı§ù~0gïÜ#ğòÍY.³s|0”²6£VhŸ²K¼3Æ˜öçŸ9†ƒNç¸ŸA-4qÀÓéŒTzàòeš´©1…6F69D±˜ûgİn§70î%Uì$—MMâní)~­BF„¯Q„ƒ4d*æsï^ƒX©ñ‹u±„©é]…ÓÎ }øë°á¦¸AğMá
A‚ÀGˆØ;÷ù™p‘]R&^ïÜå²•õ=P®`ÎÎÑîı¼Hmxœÿåäì¥¸jı+÷Îå/ß‚Íæ±DÇ$[f“3êF£fl=şNŞ	´K.w¸İô}'}ï!«c~ ƒ/(Èõaß`#QÊ9¾Ç÷]ˆ2 ca!Ë—r:±pJ¤xfÏ¨î‹ú +­»<x´˜7g·-Ê.BÏçvfÀßˆfÒÂ—GŞ‹ÜE=5gÔÈ¶DMM½=.v>¢Úº¢ãÜÑh¡Èİ4$xf×šÈ¨4˜”ûx>y†*‹rx—±å¤µÇè²òp0¬^·¡‹ñ(*ˆØĞ0 «C#7 ÁÌvMÇ˜˜ a¢éÚ§F#Û·˜M”)©¸³í-BHÃ9„<âhğrïè¬¼¶§ÀÅ=a÷qM‘ÿú¤é˜ŒÙ}ÛÉÉ
éU¨_iâáŠŒõ>€kâŸ(”÷Ù.V:Y9 lÎ·´‘©ÒF,o\ä{ÆEaRÇ¼«|I¯ÁÖXÌµå½®Xrè0 4~‡µ'¸³—gÒ[È–}È4¯wwßh/ZÚ),eN[W!åïİ¼Ïöï¿û!†|¼á•éDÔ¨ÓøãMÜ­Õğ-_ V;ğğ5i#Ñ‰|[iÄ–»­áIëôlØ´N’„¿T§0Ï=‡|wEÊÆA·_ÚÓ ÏáB<<hõ_:]~R@@:¼±mŠê}@'é{QçÔñëS×›Q~·Ô´@®uvÍB:Óøƒ6l‹¢öŒa!´X»A€<Ó"HâëçáÌ©£¡IiËÔIØìtsCıjæ|’%Š³%>;ü2±üHÈP¤Cc6g£?Áş&³ƒ÷`ÜÛğú%¤¢â, uíÓ6O”²ÓxÂï‰J0ÊÂ²&Ñ'Ø@t DÉ”¶ë±PœØKQºçXÃ¼»5Ôû]²ºà1Š†2õgùS"˜\ÛGT‹äÈ^f^
P•{µ<Ì"‰©+A–0ìƒ97“È•O³k±æ3;µÚM§Û:ı¢ß¸x~«p?Xš9³ &%Ÿ6ÈŞüaG]ÍÍÏ”ª&m¡93 QÌ‘öö¿ ¬Bèã˜(ñÌtÏyÁNÁÒ‘d¼é†%OÒªH%k¿I~~«Ã¯g€9IS‰E¬=øú	' –B~JVWI•›ÿá‰HşÿT’ÍK`k7yêl¶ê@–\ìÉ‰+Şäo€Ğ¹çøC”I/øşã)šœÒË®pVÂ˜c™tà½N5fiÆ' ‚ñÿ_8 ÇÌ¸·ˆ’”ü‡ñ#ƒĞ$´bŸÃ¥¥€ûÌûRIql|Šı¹Ğx¦Ÿ‡a˜p|Q-©K„ØÆB^ÚçV§ÿkßÏDè ®­æmn‡×–ˆü0rœ˜Í<„Ks·@XÂ>8‘ãC*¥[('Ùİø ÅXKFğ+;'àûÁ§¢i’¯ÛÒjúÈêÄ½ÿÎâ®:Q°èŠ‹ÓÊÊ'W?’¡êBSü{ x†Bø™
ïŠto GÔ%Wk…Î”Z<¹xø¡3y‡ï*/ÍºĞ:6ÖAÁZæTR-~–ÆáD-a*ùr7‚Ü%á\à´lDbÕ¸ãQ“ëä‹„IæM¼rÿR–"ËîÈ*•Å¤£
®nôëêZü‡¨9Ì©a|¶ğOµP>×b˜pëozEÿÛŞ·u·‘#iî«òWÀINIòš¤HÉ—–L÷È–ìR—nG”ªº»T‡'E¦ä,“L“”¬r{ÿË>ÍÙ‡}™9û0ûØõÇ6. ÈD’”Jv×Ì’çØ"3q€@ â‹u	‡÷ĞğÕÜI‘a›å•qõD¥îN¿*øSR©ú1j¶AÆùõÿöÆÀOèWó>0¯­õ1¥Ö¯è›;Øn dÂÀ;¼lI¿ş/qütO†’‚c-—ƒóå‚•‚nÔ˜èB‚ä¯¾Ñ*}‰¦<XS:D"‹›hü^ •ıÔ¨¥â
½­¼‡Ã¤;9ú3ê„N¾'$©WîÆ8ÀYœÎ•ÿ*+¡±R¹êÅ°f ÅL^p{ecÎNöE‰*ñ½üíQët“jánW1˜önÅğ+p0`,üZ8˜©ÖõûäÊ™Re{ZVW7*•É o,ªÌHkuİ%ğTæ&•s£„î–æ;oIwc¹vş#V}şS­»œK4+'6Ä™S[Î¿ÁÛÍ#i´ú†Í `SgCÙŒªÚTèF”	KB9£j² õiƒ(´Õ€ıxP#{ãªEf¡“‘Ê¸^]¯Öå>¸qb´&½Ù©Ér¤™Ì"•—Aet™OdÉiaFópÑE‹‘ÜıÙ°Ó÷‡ŠH>¤kÄ?ÃZ»E§ßå/½ÿöº#F,Á<Ì’øû:éÄÕq÷’¿w£ËËô×d(¿ãñ²:øVn¼Õï6XïB7üô_5$|ßÏÿÿ<
åoÔâtà:Îü¬’ŸùZÇËoèÒf|MÓèâ`j%cã«NÒ¹êá.aÔ‘-ãWÃL˜«êpÌ?Ğ”CşíëNĞ÷Puû=öQıbYtìŒ¹?'ñ@¦ –aÏø*+ímDDøŠú5ş
ƒn—¾‚€ÊO¡¬ğ¬üö3	!ôM½œŒõYü°â=„•ëf½ß†İpH'İI_~#.á¯Ã‚ß€pXçîÇñPşQÅŞìâ¨OLœ2Jpv_§ßdÒñĞ ·vb-$/ò“ñUfI	^Dİ‘Ü­‰gñxnê¥"nÓÏL6‰I³FÒ(Fú‚T¾"§Yz°%hO¥ÉÈJb_–</µÏ`F-ÿ.k‰Ç¸úÛdóš&”uVÎåÚÃˆsu68·Íp‰.*]”Îk"ª`wj÷ªïŠd•jıœFjüÊİ‘ñ_¬õ²ü¥»T0÷(L/Ô´™VÈç¬I¯DŸŠ{]%Mà¥NzÌéêè
öå"3ÀÃ®¹=ëãtArØöIuó){];%ìö<¾›ÏHp<·¤3mö¹Û1[»‘*ùMÒFq•9ÒèTÙÆ¸îzr*ÅF"ã·ş^HnÃbµf%¯†¯¥M©JE´Qî<*ğœúÜß"&Ú7ÙÜ^Ë:iêöIÑL!C±¼Ä—çóB¿üÉ‘7K ää]1oz9áFıv<'M¤G?=õÁ5­ ²ÌfJ—ò w609åµ2ü¥P‘°ş¾ª0L$	›¯&Ğ 10š1ßÀ‹–|¾{xßkó2Ñœv¬0Ïó©ËR{î|ñ|£’%K¿{šB¡}t;EWòäcéFi7¹˜ºlm†€åºadSğxúÒ3wz¹ ıîÊ/"Ò\6çV„1ø®°Î8;iïæÆ[éË‹,L§¾Ìo\s¤ìıÆıjÎôØ†É³°gs·Ä2
K˜)2ØC™1—ÌM`÷!7ØÛ@
OPœ˜Vxr¸ Mîe.1µƒŠVÌo¦x©•¯µ{zºwø®UœÒór.Ö÷ñšÃ‹'ãO<Å¥Ç±çy<ÓŠ” rÚPC8»²{KùT+´Ï–³/ÄßJ÷~R;¯•óP1µÚK½$ŸuË]"9îoA{ïäväö:r8å}l—#ËãH9M÷7zw£¬·üÈó¾AÏ5y–oĞır²Ğ=óJ_!ïùGi·£Ì 6©æH¹`¿q¤ -ÓÇjZ§í™İéÿ|àYbé×UÓ$åÎ®b÷ós¸ˆ=¸‡Øüb4703%Ğ›Ò¼¼i—\Í²½Úı”‰vFxtr)nçËRÊ½êèuç­ƒä¥û÷cºbå·ö`FévÛ?åwÊÏ¦ÆF8Ô8÷ÍYO.LñéÏıêÎV3ÙQƒÆğy;ê£&/ŒD~†Œä€á0â^V"¹ˆéÚz(Í±Êx9	šæÔ^\Å%¬6ÁZñÍV\m˜Üçµkn¼~L^òÍ€h»‡ß7§ à-•lŸ=•g“T¢¦Q‰­Ï­ÒEîïàó“í“¿¤«­k³œ¾ÅjJÕª×Õ—›ËF½‚¿R~¼ºœyAQŒ|	 EÅ,[k{b XN²8O8$˜YlÇÃ|¾”~Ë—ú¸.-óK¦ú–b(Q7æK
÷“NHÇŒH¶wH”ıUõ{ÉEL¡-úµµ¥*¢’xİ™Uš¤´»4ú†ø ²#ƒ¾”UÂèË?ÿôyÙi3T0å6fÍ2Óä¹8#.hcLxÃú¸œ­¬²Ö×–Ø¾üòhq¬|ÔüzuÍ‡@'îÂ"ÓôÏNßV^ø|E½|É‘,½Ü\G£x€&øG~’ĞØ_îsm)^[ŒŸûµ÷q?¬ÌMM§)õ¯ù¾òeYR…HäıP—U´f¥™_Öm¤W/k²/¦¥[–Fritšx…iÁ1Ìªç9Œ‹ç³-¶™ßÕ:²”Ï¬ŸõP¶I†=(®ËªååYØÂëºö	cÆeŸ tW	ğµé™,ØÁóò
ŒË÷áhÕ_ZTÎR©>½ ËLÁW5C¾Fa¾ŒKš¾Ğ¬P°iPÒ6îÚ~¬…•²ï0
§hãO6r¹éÏ±t»xÎ¼¾lÀqfĞ8ÕMqR+CŸæ@q&Ïœ‰7(1I¸YÓn¥Eî/ù5Á.¶NÅÎüéìV0‚èo&91é—¢|ãw@ùõ/Bye«Î³_3ş_}½±QÏÆÿ¨¯-â,ğßfá¿]§øokÕºÿæ@³Â|FcœÅv{$ö8Ø@„ep.84Œ˜mê
Î|½Cxéğ<}P/K3HVóu0Ş¼Ò»ı£×Ûûâûí“=tjoqµoâ^<B—O¥úûİ“İfyù<ü±¾µŞè/ëáÛ'»ûGüjŞ­§ïZg¯a#şv{_oèÇ‡»ïNöNe–zš\ÉêjïÚV™”lÃJ¸ı×³}]ÀFúœ‘fe3áñöñi{ÿèÍw-üÚuÀ–İá‡+Üğz-}Q¿˜ŒûU'è¼é%A€5“|V]`år„?ƒ®ï­zÉ{.ØS,´n;èEpfJ<ú+8*us¹vz ƒ‰
œœJ.ñ] äÌ©¢e>‘¶É±ƒ×÷ävGa…ÃÎ¼vîŠ>Fz„xƒÂË O§>âÕÄ6e·là­…ãÑ3[Gv`íl+õs_tã01üÁùâ›—¸·Cı¥­§\!ÍÁãËáV¡â1â
˜×å:v›T™è&Lvg¥ÙDe‰¼ÑÓx2À¾.Õ/ãÉ +â‘¨|D?½\;<¹a£àqsùğèpwÙA3›d~¹‘C×ƒG»ÁìE‚f¥9!c9òíH:€¸:È±.ØCmĞK²¯¤¯¥xâôó÷}$x)]%‚I	tU¿‰’‰0ä ÕĞŒ¡D¼eÓ–0XM›+å•J(?—q€Ê:á*ğº|Å’è6ÜB…Ò7x‚²GseÕÅ€ß|“!¢LEe1ïéÖRÄv-H=Uaz`^2¡u¥åOğµV;¯ÕÄçUê^¦ÀÓ>	^Àf‰#×,•X>”zØc)mşT~Ù®üu­ò‡­ŸVm$- ?äÂ´0WáGô†0'}ÄàÑÌ¶*í€j]qûiPµ“"°¶1wÂ¡aŞ™d±EV6­ãı½ÓÓİööÉÉö_°T92”*œìâ`ŞvCÉêb[²3UÒ:Mëh–s@‡>6‡ÍáYo:3™´i’®Ğ‡`4
n‘I'r/V)t ÑB§äÎÏè”A›rú»‘–d6Hœ‘:½Ê(e&µ™×2#táŸ R½&¥¯¢(†&	.ú·èéRäL(•&¥À@[º6¥˜[ëéèI·'¬«Y®oéßzÃŒJŸòÆ„ó¾Y^×OeÏ€¦rĞ„µ|¸TRÇÁJè—²RbYS â)°e¥Œyåa¦Ù`„Ì$j­×a£\ñG&]İã4Ùı¦bGˆ˜ô“,ˆqï¹”'9Úw Ş0èÃ
	Û	ºyÉß46€ÏNÎWrP½TdÀÂãØ4L˜)YZæ$ù¹^êlÍ,¿1­K$¿rù‘È`ø§@9ÿtáËe }í+TMÊØ±›¦eÊå²-ç´¦ì÷ÒùóÁ½ºïÊ6› %¾ôD¶ ŒK)²V:©K	T|¼ÿd¤²™‚f]½[¦×±¿md´=“Ğ´°H?sä”,t7^SKmVU‰\©u«l^G?Œ6Şwä·ßL'LéN¦˜–ñ¾¥÷¿+o[jÑİœkZ%g@¬“8+á°ûˆ-úÑ*IKhlcÏ&QÂ‚Àš±R*ò&Î&ã ê†½˜Ñ:,3YE¬nã“ıú»Ze4ƒ/F6g ÏQtC~&çƒ]8nÁü®V«ÈB¯¾i ¹ğ:3Ñ*Ô•ú˜‚™ĞÎŒ»!ÖiGgÁü*³£„G,‡©`?»	‰.»<ê…¯2n ©2gïˆJ.Äı}}±ğ­(ë4P¡WªÊ•´0‚lç#í iÜ @ÙÁ_D <İ>§£[(£G¾ãÜJËù÷ßMú‚"ÍG&(k2F˜AØát bëè<Å0Iâä‰ ¥xAÜ’à*ì{ gıú?q^DhEƒÑ!‡ÃŒ‡«ÔëIr›Y§Ör‘&2[–É9éêÚ[b·b|ğãÚOê}?¡£ğÍ{dKDDÁœÒÀfJ~¢ñò›º(…ƒ™ ’.¶É‚ê<ÄBéL†D•*öL[Äb "á¶‚hLñÊuöPXZÂVÕ·l¨PDÑM¦ÖŸaĞ¤îQÜLBXıÇ&h¨&ÆP2çJå˜^Ç7•É ˜`‹ÆèŠvW³‰Û0u Cå2úXéGËéJÛpŒSZ=ìø@¤Q˜èJ²ÇTl{ù“ÖháxKğ°‚“],ÒßÊÉ£üGL6–³Èåõ¼¸®™3zfnã'öœ\rŠû3ñt“È$ı	£ó£Ï‹àA_%şä‰‡ı>GüŸ§ÏÙø?ëOëÏ÷?‹øï÷ÿşÔÿÇ7¹|Î@?oT¬w+”»,HüéÁró“¯Ù½4…h ûº9‡Î'‘¬dGî·N°9DÍ/ê†m4jº1S¿Õ4İK:l•â{uòÈÕeßUdüqÄQ¯+¤Y“PbyÖ¸ÊªŒ.TLæô¦ ¡Ñ‡”á¡z“ |³NôÈu®üÉQœ•Ëv6-Ç¾&0ú`&á˜*‰¥<	%Ùı´;’qÙ®À""šØeiº¥UåümÍú¨ıÜ\)Y°\!1”D³„¦<ø¥aÂÿÍd¶®Á‚±˜#‡2J¡J—SİT^B2zèŠ‰k_	iŠ„ÏµB¡kö5=ÔÒìÙ]¤?# #YÇ&²É$²ùÍ]õöáéÌz1ÍôJeŠ¼ÎDA[ã`<IXÂ&ïáta»ëx›¦Ê
©ş?=kÑÍœÖ'“F¤²ĞøõôÕáQûİÙÏxùF©¯·ÔIÓ
†eXrà«
ä)1’%ƒQ?ø%àÑ‡Ô|¿şë¯ÿfi_ŒP=‚zÄ^êVÇ‡!—†'UñP$­æŠ(¯à­¶¨À1 ¾*VÍÕ^^¦pÌ­Vg dqâ4/ÄH3”9U #ZA«¦Te²/}
FúÔÕ0’¯B‘Ú¬i+ªˆ™€)‰kßÔo¥[²¢¨ÂTX±q-óŠ' ¾©Í É¨+ZJŒcüæ}Øù°Kj9¨¶&gº¸o˜çj¦K"Øü{{ÿt÷äpûtïû]M¯6Ìø›ŠÌË"¯ç0v3Œ¨³×š…UZ¼otoÑ¾°ch†6bÉ¦Tá¨ZSÜ±´•\¾Œb’£Œ“÷ñ1–¢†üÖ«kÕ5›b5wwwÚgÇ¸ºíâÎÔ¬§AÀ£b'¼ˆèûZíhş´óÜ{ùô…I‚)­
n÷EşO‡“öÛÍôí²{<³ê.¥Gü!Á6~µi„nVÍ}¡¬›naØ}"&	möœ¢^¤£6S@½²ÙPÁÍ²z°ÚR4bÔ34U<@Ú9É]iK=©¢µMz›ø‰9äõŞöaû50 ‚éµĞ¤Ô/TfÌ¬T»(GV.`=Å>ğC_ø®ÚÔem7JP;ÕüÕ˜<Ü¿C>N/¦Iİğ¢Ú%D\ó6mwñ^BïÓ²ÚU€èÉ âÅÑzí±÷Ô;Dô=èçì¯qòå+`›AĞ„H‚Ht)bÕ¯ÿÄjl2¬3Û`“Cåja"p³¯!^ïNŒ¾İ'Y8Z¹‹H8£Je8]…zzü¡ò61;a½ş˜v9¡“pü§“İ‚ôì—Á¤7öğâEìğ“¯D	¨.¿oã(áµ7/ÿûæ1
Wµ’Ì˜RLn>¬¤¨Ø°WêÒ•[AdK µ›6¸4E™¥*iVs¡=™ÃøP©/b´´v‘Z€øÉSKj¢ÖÁ~Ô,G˜ü|ĞÇÃ!.3Òh‹ï)¤½SÚH+­`xÑùÓö÷ÛìÓå—ÓdºvY€™¡ jl;—ÀØ£R›šXÖ¥6U[†Ôl˜Ôh²’Xºá0ñäïQÍdbNq,«qØ\®Áÿ8­ñ\F›Y+Å_¦sõşöR¦Ìªs²Ák†Ù¡ÊÇB³<Y¦Ê43'8R«Ùs&	àVŠHúÂØù9ş—eèJ’9' Ïö_Ñ£Æò¶ä%)İ6ñN‘¦RçyÔÍ(Í+œ%£8·Ìóê‚nÙªÀ)Â‡òıã‰e’ÕÊÑ–Q³³ÇÚÛıAHÍ`ø5#hé•4+¼d–Ñìîì¡s¶¾@H³Ü.‚’lv?”K–KŞñ\lÔQŞß{İRç#Bí}ÇşÇ©$äˆI€oA\`9U£ì„İQÿûáx'äUwÌ?AÌ\ ­[××–Ù[ƒ´	Z×¾Ë—ÒYk·M`Ãl ©¼-He6ĞoR¬d4¨Êf9;ÙojÀâÆf™cøªU4SìùÀ.Pu[¢:¨[˜}DlØß{³{ØÚmõN¶vAğÆ#X¥Ò‹:á ¡Us·)
¡¬šøKıhç¤õ«64æ°ÖƒíÃíw»'í7;FÅ?ÂŒ/hNÓŸš~Acüß\lQ_ªdL¶7µè†ä©@¬û½Ì6­•)øİVGÅ¥e“vË©/›äC|ÊüŞLQ´í×‰ã=‹–ïÂ±© DŒvCâI—[3AI3APòà‚"\	]¾ƒëH”¡™mZ­
Î%Â~Åeådww»µ[«<=Cµ¯ÑÖÔ]A±ùAA9d–`Q;ÅYJ)êttt´ İİ41@Uµ¢2ëLégéçÛ%úÓè8µÔ¹k¶¡¤(ş(¡J ŞøÊær„ÿ_g¸ı€ÊÌOëı¸‹à.Pj„×C Yª0ƒÛì OMÏº6…¶^©)ŠW×Æ4•fNUcI† ÀÂV˜ÌÖ	Hd‡ßè%G¾¢FLÆÊ¯E<c¨F2ñDÊ@™:óL©|&÷ä‹|(ó w»§|Ó÷ÑC$†'oUL,ã¼pa@xÑ\ñ;=}„Cö=¦É’¥å©JUo½D3²‡iá7³‚É l¿%çÌŸÕÏÑør$æŒÖ<wjjŸgDµ¯ 6¦·4ÚY:Î×@sˆ†“^G„e,,¿üI¿7Ìj²œ7?Ûó~<[L?c”râùóç¢rr]@#ól-œÓhV&å¹í$Uñ,½_£îÒ*yb}ˆí¦ıö`|:Š®ìëóÌõOöxW%‘1R	7±ØÆÜàşuqB×‹jÀöLu“5µÒêÜµV«µjÕËhÆ‹Ôƒ1m¶@ê©467›$ìyé…FÂPÂ ˆÑğ2™ @Ë dæ¥Â”Â&*ˆ¯Õ™—³ÛïöP&Ù>nïîìş¹¹&JM.ÂIEŒwwp¼2ŒŒkcwüë¿¢­öAÈ İLDMCp`¿`ˆ¶%£¸÷F<O²òpº}"Eô\ÕurvÙïãõ¥l.¦FK?³~
ë­-ÀY¯a“Ã®¹ec2)fFh›F´†(µÈ•MÁç¢
¡áé´õŞô†=º½†X/pG£Ép¼ªi(›ô×½c)7äƒÇôÉà—hh%ÖÄ0‰˜yŸ¡£+7“òpç»ù8:£)vp«wİ06Ïe·P óÚ6Ps8ëöİT¡ºR-Ôæzâôæöxb ô½y›°gNi=æØZ˜3K®ÌÏÓÑÆd0X®TxõN±@1ÍÎLÁCH)¬èL–“í¾Q¾ÚG¨ÕÑÚ{·wx
«+iqİ¾1ŞÕyôæ	IîƒÈ6§¸ºÊSÅW¤gÌjƒhlÌÒ)3xÍ¬D§HA5¯4*{\yDú ='EŸ¾^÷G§ÕFõ©ïJ¤ÕbÎ·Û«^ÅñU/¬‚¥HkÀ‰q‚@z·¼«´eyŒNX…ñt–äoúÅˆÿr¤1ˆ`r'#>ŠWîÜømh¶´:ìJú4åM«r}É>KEc©D’Ü+w~¾ˆPz¥ti8xoé¾UØî³İ ˆwSbÅ÷Ôw/©Hİğ Âœmè7E˜ÅôæÊ{!Jú7A4~¢OcxÕuîËn!´©+ò`,$Uq™äˆ.! ›@‰ˆöAXXX0z?Á²„i–ÇïSszKè©{•1Z©‰›0|ßîÖ¾é=ş=ö5ãêóù¨×M—wC­ moËÆ·ñ;Eè–qÌ9î s6^£Ü÷n÷Ô/ÌF±’ü{
¼Ë/kúÅë³½}‰0[XpøÎ¤ÆK¼üÓ†ÚnÛ§$çÄ'8|g.µôé~0«
+­˜•8}Çm¾ I=o†`ø¡MÈ/h‰4ƒZRL<Ø;4	–…„v£X=hIr3—w½ØØöˆÂ¹°^„—1™Ó»Ğ¼4­-œ¹Ñ<RÎ»Ä6œî±Ü–w ‹î‘Ÿ¦•@Ëª¶U^*1V>~[ê%™iù“sÚ!£óêi.O4S2¤¢€nó-"&XE}Rò°Ÿİ¸U&‘@?2´_3;7=ß$©‹îiKÔï¦‰ÓÚx¿…ÔZJÕbªÿ^FKêâ^XŠÜ“pD#X`32S~%µ/®z=õÍ_Æ2iÌuŸq‹q½`üReOªíôRÓ=iƒ'¶{ÆEÀñŞrmx„îıÊz+ìbÇ¹¬£Aï–<V¤IæI8ä…ÊË…²d0r=ÌI<2Dëd„€÷šı›ĞcV}ÎL+.J†,ÑëY¶ŒY?³i¬ VÙ½ğ÷Û˜›qõ¹™~•“ÂnÎÌW*MÅ”eà™ín·K“yóOŒ:`"âuĞe–upœ[=a1Ì»¨ìà•¾œc¦ù›ÿ…İöˆ^‘ğ¬ºÈ¯Ã`„Æ8.ë~mËë°Ò·«"ùõß•ó½Ñ[õŒ©c‚gä©¬äfƒ9¨yÒÏ…,í«/(±‰8 Qç=ş^% €°|YñuØS**Hl„ÃTAŒM‡gi™"«òEe,K:ZğòÆj*hGiÀf0¿äR2êhÆîQ±`ÖÔhi>S#G#Šl†Rõ]G˜ğ9º.ÒĞvü¢9’ÁÜû'B€0ô¢_ÉbªŞR.†?S1&Šµã€ñƒ.eìîåÂkû#±aƒuH±10D@ à9x ô÷ğ‚Ê8JHÈÑ—	¥+H‚ŒÙ'¤4+¨V©ûÛÁ©3£üG#"½ıÆü•
U:€ojÃj‘¤L ²ÑG:¿ş{¾·ğÇˆlHÜŞÆ0§fÏŸXT„ÒÁ¤¸~E Ïğdì†@ÊkrºÇ–ÄĞ…¤h¯·×Úk®´«sæ%hNÚ–„BÑİÚ²‘iË³¡Î§ºv£ú©xŞaÎ¨vZ¶"±ş¨pö¬²ã;[;°°\èôëk1¿"Ñş•3ñpùÙée7:‹“ı!µ$‘¡ïgE`vVç‹Ïl+g$	!Ê-É™^O9ßŞ™Ğ´’Â¤;‰-4Nü-¡ætÆ ¥€ºLA;Ô‘&»“à¿âĞ¤KK¯Q¼¦ÛÊ äy·ªH{—½²û(
£ld·w^ã³nxíÃEãGq?¾’†¬©µïÑÍ ˆ®¬|KóÈl–QÓC»ÑE»³I;–İ’L‰¥®úÅ.#­\•»1á¤fÖğB'îŒ>? ¿÷_^DéÃ’Ÿm¬.ıdÁŒP†íL[1½œûkˆ’Ya«`·àå%±‡•®,s*5K|ç¥¨¹)¹{V°!±UÒ]ÖöÂ­í!ë‚ÍyÚú]š¹€ËB)¼¥¤ŞTÈ‰¯°fXõ¦:Õf÷¤h`[O¦¦E­fjt²Øq¾ÄîaÇá“=0îw4s-Éİ¾¦ß@ÒKA|ù±i²Š8úQ'uÇ›=zY^÷rîŸ×ÜAz§f}ú×üÙ&†§G.»©Ÿ†?™¿©
Ú.Ğ'S×Ó9:#Ì¦rÇû{oöNÛÛoN¡ŒöÁÑÎ.ÁK¬ÑA"`{æÃµÜRs`•“.#êx%na*‡7uS;£Æµi$¥ø"„•˜‘ø‚î×çÑYHfdu 3,åQräÈÜ¿ÖÂJyºõƒh`q¸m·áÚÉ¦ş}4X2ò²û`n§c£:úËF$ò‘e6BÏQwW*ğö\ÂB)£tiE	He£(@cw
v€Fï(oqææäŞ²qÖìŠ*Zyg,ÌÛ]l'†HÆñ±T•NÙÈ2Û˜W°k97ÈÜ¶1Í¼.$Çq2~#Ãæv×òùøoU‚IB}Z/ü"ñ?}Z€ÿ†ß7òñÖøoü·»â¿Åûé8QÜ˜İÇÅMî)^gÕÁærS™©İÜÜT¯£ë f{2È^½Õºp–¨µ0ìO…k«|¥,;T ½qEG
F_	‘ÏÔ•VÚ•U¡U	"Ø†×1?aí;:8>Ù=ŞÿEò€—¨¢Â‡íNvZ?Ò×7ø$eÌY˜¢ÂĞ¸ô¢ïºaSC)š÷Ê¿• Fè*MH¬0œuÉßtMi{UA–ùmı,šMQy,~2ìHaœ ÁÈ:•ğB[Ç…JEfgh"v£â:HÂ…¢òV‘T˜ÏçÏQ¹SjíîµpUÏ”õŸ
xÂœ%_ÿ³Q¾ñ,‡ÿ¹ñt±ş/Öÿ{ã®»ğ?Oß‡”5åô91@;‰µc\£”ÒYòuB¾¥º ‚"¡9®¢œ$U<¤‡T…4`X ¼ĞõTBÑßªsbÏ›ëˆ¸ŒFÉø‘°±¢¤Õ,‡G§{oÑKıpƒüjæ G—·DJ_õ´ú¡Éa²ŠÚk¤¤0$¯QŸLgÉÿ‘ª1üUOKÊRmØG°KOéd{ï¯bçHl¼ŞÛ=<İåÁòÔ)+pdõÌséGHfq_hdUt»?ï¼kïlŸn£ïA«i„ïİ4ñòƒœYˆñÒ÷œŠŸ¦Hæå»ûo>†™cú}¶9Û©Q°y¢äŸÏÇÇñM8"Õ`…=qÔƒ™tJş% ”ŞªÇ-`UGëø˜ê>?–°k døàŒ ¢DıYumCìŸ¶r/^d_ğğ°;¼t>¥Ò¡	Šä ìíÉ0ÉáNÓ¿ Âªz-İÿñ&À@ÒÓµÊË:ã©ôª¹ffÑÁìç)ÿà;Tİá<³Ÿçpı–/‡e3…}R„õË²¦E¹Z‚ÜwÄb³õİéÑ1ÌËİ+ÊFÄ W)ãÑñ©Ñ:ÚÄ'óôA8®v&AurÙƒèœ&5@OÖë:Å,nÓÀğrÀ-šÌ¸”Nv_XØÄİI*ëëëÏÿğŒİJ”Æ'õ™B÷—µı&ãQÕÕ_\˜¹îÖe×= 8£ÜÏ²q_<k?ÛÈµ|cî›YûDM+„r§'Ğ³j½Z÷½Œ›ÎTš¶Lb6^øšUóÆìMà™ÌË¼a:R]ÃEP&u[e7—Ï1Ù2÷dœËªWˆºc€î¬N+‹–@mcº5Íf_xûSÓütkša>ææLø-ul£Ÿl³ªjßÊ˜ÛÛu™³Oífƒú9İ#azç*³:G}¨ğÔ©8ıt"Õl?­"¦¿Ìú$Èú	Ø=šBJ ]®¢ñûÉ-?÷‡z&˜Š¬@ÊD¹ßâJˆW@yÁ©jÂ·g.#š6¢‚®½·³«RM„Gi¼¤|¨$R‹04—…ÛMö'«D£•;á5ÉiÇ£øç°3F·‘’.EWT'Ã š}€MSZ-Î÷å`÷ğ¬½wº{`¥wËYµ`ˆwUdœEUA¤ı0aı’C«—°jVû¹¼|l.óëeÏp¨¶(EZ|XnùaáEŸn]YK{n=Ô5ñ»eÏğ5OùK†A®CŒŒŒ0¤5ÄE—~<)ÂA'Ljü&Ñ¸‚†ÔÙ*>W eÎÕÕ¿øék[Ç]³æ1«Ma”˜ÜŒTebúŞÉîö>•*×~³ê(zº0éMJ­)²,M©Qt1a¦˜1bÔSÚé2^ä ‡Î›<9¬>2±œ“n°Ÿ=Ë¾nú*¬€ŸŞ†Û9kµój­ıY”xıÂ{.D%—8“ãÃ=-W—é"¬ıDÄğó~_`dSàˆ7Æ¨W!K0©çÆö1¨z=¨^Âp@ÕdSkãà*©e›#2àrx«Ë+Kz¾CòLiÓ”F5ÈÛĞ~§hÜF–Öƒ†ù Ş~)V%é‘Äq0©$üB%Ô«/ª”sÉólÛ
„©•'G­V{ûä@Léc™B-±E5^ÄÓu+/ŞŸ)ù	-¬´4¥œ‰Hê¯té¨qrğí[cÆ£• ÌõQÿúyàuz<>Ù}»÷ç&g—W½’Ñ4LïlÜÜmc ­¹ÚWĞ ;oÁÑ¬Ráö©&úKu»•!_ÏÆ¤Q’zûbu¯`å_å#~ÒÆ¢ª½á@Œ@f¸­ğÍn…ár]û7*Ò%ÛÀ!¬iokşC5YşLSñƒ{5øK¶ƒ»HEê…~ı®ÚxÙéi0¾·˜ 8–NvßíşY|¿}²‡«GËó~8i[b…O,u<*ŠÉ±ÌiMT!ÖóÑÀqï1p_ak‰.>Öë•nxòŞÅÕø,Vú<†ÑÇ‹É¥ñ°D£¸¡~Á¹ŠëéÛãd¬¾ãÆ›«÷Šª	÷«Şd¼~£ç¾—ÂĞ6ı~8˜ B›H&×¬@ıàC(xxA¢Æ€€AO (C3L£`$Ô‘%÷ {!®àE«„8ØÅªç§e¤$Î]hè]òzöá©Jş½&Óç {1ôá€4Ñ kˆA<¨`}YX=;¨@X¤üñ'Ï+´ar[ºhı‹+¸Jæ¥ÛèçtXì‡í=8Ù{.x”¢Xk©’ v;ÕÖ¼l—t?Ğ4äáÜyz}ûR!Ç;.¢ÊFõµá(DA¬şTK‚2qjX([¹ÖÙ1²øvšyÒzm±,û~]ä½Òîæ¬.šRÓŒ={ù+nÚJ:C‘¬Œÿo–¤Ñí/4iL¹95JÏku-DÓ™b+"n_Œ‚œW`İ>ÂŠ¿R_®0·Ò—ßè‰ù%nß¿5Œí›ÎÈRò,«¬øóU~ÓÏ·=,dùÅröÕ>¬|õºµzğ.Ä¹£íFuu„«örsšMmœÿè$û”6=S±®°ã)§"² »„¡	«ƒp¼ÎJ}¶ <öš4Òú§ÆİÀß ß}¶aU7Ş™Èû7è6Æ¦Ù¨ÔÛ”—a"–ÿ!­AqnM#mÍ2®î•Ä$2‰/¥í(k_`Îóˆ%·ƒqğq“¯pl³‡óqÿ²ÏÒ»«ÂL~J½ëéâsg÷óñ0óŠ+H3ŸaÔfıvS]!¥	ìzÓ*¦~2>]«¡[vWvFaò÷ÿPµäûÄÍ6Mf
kÌÕq2hH4Æ”×yÿ·ÙÕæ7EõÆâçI2Ö¦½Tí¥²È+„†÷éÙ é”˜\QïÉ10ˆ`«³[C¦AÓ)­á;®á¨Qs–Ï¦GEµœ•’	Ğ ÂQ¢/W¡¸f¢.NëtB§czn®Ìn=N£lØÂ(T˜ƒÆg?X|f‘±8â¹²™™+Ù¶ˆÜÌ3&ÛxKOÇoZ§FjiÔ¥_¼Ş=ÉNÖ$@Û&˜š¹–Ìa7{ÅZµş¬ZW•á]£ìØà|öå0cºnîúßÿC¼¾Õ ÈŞr¼ØAí& ¨4ø|’ÉPG§x""iT%BãsÀÓ1ãvÄéq¡PxºµÿşobïSa(ú:aŞšÙi¢İVjNw2îV=ƒíq¦ı¯åoğuíëëOŸçí×û¯…ı×û¯{€¬~?06íO$3ø3™“UÑW±÷å,yó
§è³}ºÆcÑÚ´—Ÿ
ßıSvUxüÙóXnU¸å®l–-©?O„M•m¨qDæÉc…ò·U0Í½“JØÅKİyóÒ–Õ²B¯Ô¶úG­×zìy&Fh_Š‘I‰†MtTzøç”åìåíÏEöƒ«¨ÓF`Rh@B‹ÒšĞOI?¸´TªÓ“Ì$m˜ÏÏYˆÒ:=µZi7²xwğì)=“f&ğû™ş­-GàésBÅÒAjs½£˜µ•ºéÇ)}§á@Ôî†hóÜE«ó´ç?f±›ü²™Õ›Ş [T«Ua§•¼¢2º¶ßØ¢dÙ`(&rÓz?¥><¦§—t§]%Í•2ÆÜ³QóğEÁªä°à1‰Ò2›ËSÅÉUïeÌ«Kl”ïğ]tØ}‘wœ
vkbSzì%äoî½Œgu3eÎa›< V4ĞáüN¥Å0:&€V€àI×ÕA^æòê”Í¢B6Ë
_Áh?ùûÇÇM³@õ¹6v>>“ *6TP;§ä¡T«¶¨nëó-ÍŞ@T’Ë¼·h&î‰°Ë%²¹PFF>…ı%Øq!­ÈØOX~ífSL‹
fWvXK¨ÜN'Ñ.z¡¢„;š”ªÀñfA»’_QÉˆËƒ;F!”ñÓzŞğÌTuK%ZÚÉ…1®é‘h­yŠ7W…‚Óš·x>ù…&íL.C4öxÎìzzlGq<ÖØ6`=¹ÃÛ	tŒŠÎĞAĞï ñä$Äw øåe]P?ñL@ºÔÿf»ƒP|¤¬kÇZó©r´A=\E¤uÏŒ˜Ù’…*RqV(ÛÌ\âòÄ($ö‡İ:ÀHÁ¯ÿ»°Ã6ø¹õ‚ñµ…‚‡–¨¡9€G”IvHìÀÎ¸¥˜a}õMC#ü`QxzLÏ¢réNÊúT‰‰ŞizôüÃ(*X$[4:ìÂ^…°©ºÎ©{À=Ã‡ëñtyóçüm`ÇuP6Œw’[âÀ¦Û¤"ªÈ>§+ÑÏ}äû‡ABõ}“HBï»‰$Ø{«Ú¢Â÷eqï¿“I:ämÒWM—J+”vúö\@[©ßy¶ƒbvÓØT´`)€×é]´z¨Û~ïNŠtÏVh9¿õ-İ¿3l¢r½ô·PÒòìÆgéBøuJš'Ÿ|ƒT—–Øq¯XåÇ pKç’‡9¡D:>./Ü‡ü/P­7Oäá‡V±^¥vƒQ/BO>K'4AäÊµ"oŒ¥¡Ãª2‹&`]có˜{óë8ú
yé¶ıö‡¿ıMız6P
®GV±•‰äº.±bÏ’údŠ§2®`ºF‘³âÆŠrC”7DùY6\wÇNŒ]Bàhu‚a˜´Æ#´»*E#R^Nz¤˜ğ$<2@êbŒ„ë‘'#r×9 ·/‡BÍÅP:{ºhäÔ_Ú¾62ÃÖ¾Ö6SMõ€D"÷S9Í	Ìì‚ëÚš×%d
Ò¸4î˜ò^2íÅõşE’(¼DÅ~e¢’«§Z„sõ4‹c·ÓÕ G%»–:ÓÂÕÔ¹œÊ5»¾å€2î©%§‘Åd›)Ø6ÅÀ+³vÂ”ÏèrÆš	™]‘7"›ya‰ÕÉPšE°²h8"Øø_´º|Ãtšİ™ó2¨]ÜsƒÓì¾¨‘.±b$dü{l{i‰XxškÁ/ê ´¬’PÓ¦M‘Q8F—NâÕGå?" ıbèÂ+„ºz°PÂ¢)ª½~ãI€÷2ä”¤¤òr¥1_õQT§Ä1Uä×X¼„¦uRH6|l/ÄZÊß@£aEQ`Y1W‹Û
±Ê“ ãıôÿÕZ7î$µ/ZÇüüdîêuH..î¾Öø[ °^M†Õ~÷ëà?¬5ÖÏ3ãÿtıéÿáëÜÿÙ@-zÏ{9|å-ámÙË°ÿÊÁÉû—5xC×ÒÎ“½Ë
¹¾uHA;ŒT³'V´{–º«_%e¾è0ïÉ*tîË@¼…—©eêñ°‚jû¯Ô—µàUUoFó‚N'‘€”Ú7ÙLœö‰¸˜Œ	áeGŞÁÕ«JåeM~E•X„{YĞ«z/k@o÷#Ù"`‰–~ár÷Åcg«{Ífˆ;
_	ï4Ñ4Ó MoI5ogEA?eH|1z5«Lm¤JVFÓPH—û¥Wuø	^Ö Š)­J©%?B.!õÍQß“·¬ŠTnÛº(­KšßÔˆê™Õƒ<]§tE¿¢ñYxÒ.)}µ’$“Í¹› Š¯Tôo*TÊ’:úÚÔĞ.Ô‚¥´Í(VÚC€¦/ÌøŠöE6T_€fØ û$‰e°™ø6/87avyÿmñ¹ÓşcùådÀ{ÈÏ××òßWsRÍñ__[¯gí¿Ö×òß×ÿs÷ü!º±¡²ÒÂ˜«~kn/„fUb{r%ê/|A¨BøK{´JÕ'ñUè{ÕÖ·âpû`×³M5ÏuÒqœ1¦,­½Ã£ãÖ^Ë³[s1ò<Ìşãùåk¾):¿<ù‰~Â¡~¶ğ7æ^8Ï•È™†Ë¥4™,ˆtö®Y/Ìªu«ºUç•sŞîòOX5d=O¥#ë±¡´“u/uh·³Ûzs²Gõ,Ñdu%f÷¢G7~Ò‹>À>z|úÇ‘+û(“g­[Ÿh£7r±%§aÚô®œê¬èµC7¤øÜ!©¡’¾^†^Bêó„”?n(±¤¾—!¥K:9´È4ƒ§ÁqÒ¥é6İf^I\AU‘15İ“ãc3™5d˜¶ÀßÌÃãy®rı)gU¯Õ·Ó$İ^dJºD0¾Wd³9TRş§¿ıíG™à'¡š¤$LlêIšø€m¶Õs*é©4Õ¦®Im×duXhWæ±Ğ–lÍSNœ%ÌqĞùÛ@aM(@$R!Ü
Âm‘÷½™)ºÂAPTŒ›N<ŒEhUŞ*·jàŞ@›Î¹®L­¶8SÚ­•ù¨cğ°åí±é©ÚªLĞkl”6/ê&¥«]¾¬OD‚à²· ¶óCi>‚sy‚Â³íìôÛ£/Í¶Ò¥í¸]ÿç÷ñ¸‡&„–YõôÿWò§ ¯t´±ïÃ)ÿæĞÿmäå¿§Ï6òß×Ñÿ½á¡zzû„íû-*±$æ>Ù„U=²€'9Qc bÃåaó´œĞÔvç½ pq*Ó±,î¡B¡½Êiût+^ªÔJE’µt¬hp…Xg˜ÖÂÅy%vâ›A/º¨)di…<ùõ»‡QiOÑ½„¥…Ü$| NøM$$®W¿± ìÉËI÷.Î©U/c´O7ÒÃR8êc,LVîL²PÒœáeGeºV“Må“Í{ª1³ÕşãT—-±5z¿å\M½§ò1#¤ü®ôŒsõ{¡A| ı_ÅA3Lv÷Ÿ¹ÿo¬åğßt±ÿÿîÿN˜zÀ&®-? <§T\Ätev#.Ã`Lşp8­/&W‚ğ"ªwMy Pì„°òËC ºdTÓıp÷‡Ö¦¹%LPF ]LMÑC˜¢ˆ©+78~GX0‹Ç‚QÍ—÷H0°¢ùB)'Ï|±‡Æ®İI‡n1©gz›3.C­fô¨UCHdÒEĞ…˜Ng‰™şí„6Ş#Œ™T5Fº7MªfV	œ]_ÃÕnßˆ–2 +8›7iùGIàO;ßÕë«”|P#
+ú¿İûóîNÁ R<­˜J>ºvúĞ¹€
GºHĞ‹%ŞF†Ê0=êEã[w&ê+SØ2ZOK$ujö’¼‚%îj wÔá¿V8‰E\6­—+ì›TÊU·=¹Â=¤ş‡{p3†¿„RªkE¹a1’¥¡Rè¸÷Ô|"vÎ¢]L0Ô±™ê/$F©PA¨²`GaĞLqó´H¡`¨%(5²©–)µp£egDÒD¤ ¨&[Üñ2˜‹´ªt-îbbuTšÙè}@r}/èÀ 	9KïüˆÖ½÷€B1+ÔŠU³}<"o50ÔDI…DVÚgâLÉ@AÅ**ĞıöÉÁõóšï»åƒÚùLÆk˜/X©úfO`İ«0É®o†ÆªU¦¿dR'§¢Ş‰õ,¾;K µ‰Îæ@»Æ™RŸ°™º€ÓE€à¤×—ıyäâ…5¡ƒà–Sƒæf…3¶.¦6ÆwÖÔ—ë»Ó f…+ÈwÎË‚6ÉÍ'ú˜`±÷ ¬¿g½‹ÉH‚–oû‚s]a$bìõ­Zˆ8=Ùıûÿ‡–úç—ÿ×Ÿgíÿg‹ûß¯òyüø›ÁE2Ü2ÿ7EĞ•ú*?ÆÅ¯ÈçÉÿo+Ô•ğ<E¦şÇ=ïñc¼F†o¸+ Óm@#ûzfÊ5³*ƒû¼<~¬.gW”‰ÆVô’îÛ´ÆŠîİô:ıSúF^Ã¥¯¦Övï|"Í©¯\æ¯µj%}™}§6ı|olÕ™³ã&Ğ]Ş¯æ»•.ã®Û1ùyÈûïÌ8I5¿å
\õA^ÆÎæ¸â‘Âº1ÿ!C%É$ó×|3MÁeûÔ‚2œ2ªZa_äÎÒ»ù¢¬©pŞ
nì‹Jrñ0§™r/$:±ŒRŞå‹ÕÎ·®÷ïºZ	·	€Ù5¥ 6:f0£–fjàLS´µ€ıXÙL[Hïm@ l"Štı +ùÙôSFª‹2cJ‚¶?p³\‹iTDÙY$´LŠz2=waÿ•Eƒ›[ÑÆ‰|wCié MfÙ:p¸¬’½T*[äŒI')ÿÇ@HŒè†ã™TPÉûıÖgïÿŸ6ÖŸ-äÿ¯£ÿ?Óì£¡‡]ù_&áˆU'¢¤4|q‡¸$–D¥'_÷»~ò|¼Œ{½øU
#(-’¥é»Ç¸'Æ·Ã°éïùJIq„ğ—¤(V±B’†F&X…D	j¶amxÓ‹^|!íj'»Û;»Àöş+µÌñ£ôB™l	ğ2êDPÄmêno)åßäõİ4Ã\ÜÔ5e¢«”XeTRÏÿ:H ÿ¼tîÅ¨Bô½ÿŸv¾{!¶Íæ#ÙjÔ+)³‡Rè¢Føçî‡Ê‹
ü¯Á¬"QµxÌªÅ»uÍYöå°£Küûˆ¿ÿ›Uì©d{™d ˆ·ş]ÀÃ ‹;èÑ(è@MÈÊ.·“äöÍ•6	¢{o=‰"â¥(Š61÷Şx9±¶ô$î!¬E2„!‘—noR‹à‰)ş€Ôª^İ`hÈÍFÛÔ	TJêA¯±1ŒüÓ’:F¼~Æhiæº5†¶W3THXA
u	Ô'"&ŠæÔG–=-ä”ÔªE©¹…rûÀÅgñY|ŸÅgñY|ŸÅgñY|ŸÅgñY|ŸÅgñY|ŸÅgñY|ŸÅgñY|ŸÅgñY|ŸÅgñY|ŸÅgñù~ş¦Û,·  