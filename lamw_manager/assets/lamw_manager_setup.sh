#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2225077773"
MD5="2542895992c3bf99958dc93ebb8e0482"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20553"
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
	echo Date of packaging: Tue Nov 26 10:38:03 -03 2019
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
‹ »*İ]ì<ÛvÛ8’y¿M©OâtS”|K·=ìYE–ulK+ÉIz’J„dÆÉ!HÙn÷_öìÃ|À|B~l« ^@Š²twfv6z°D P(êĞuıÑşiÀçÙÎ~7Ÿí4äïäó¨¹µ³ûlssgóÙÖ£F³±¹µõˆì<úŸˆ…f@È#Ëtİë;àîëÿ?ú©ë¹¸/L×œÓàŸ²ÿÛ[Û;…ıßÜİl>"¯ûÿ‡ªßèÛÕ'&;WªÚı©*Õ3×^Ò€Ù–iQ2£L‡ÀÏ3ôÈQà1æ‘'-gab6”jÛ‹F÷ÈpjSwJIÛ[øt)ÕWˆÈs÷H£¾UßRª0b4zsGßl4„Ê¦í‡5:§D•¥]%6#¾„Ä›‘z§^@ñ÷qëä5LÏêdt`0Ée`ú>ÈÌˆŠc¸i¶¢äÔÙ¹úE8©Ğ+ßÚ:ÏÏŒFòØµöTMp1ã“£Á¸{:µ’ÍEğvoĞ1Ô´ılØ÷_vŞtÚÙ\ÓQg0õÆ7İQÖÜ†YÆÏ[Ã†Šr•¢@¨1Ğ0:°R=¢@½Ğiè×E¾Ã6T±gä-Ñ`ßjı×z­¸•¼ßÇs•J9ù8æw]Qk¬ë¸É=›³“Oo‰2³•õ,®å—®0jæ ßš©·Xx®ÆÎ)ßÅØ!|Ã<ĞÀ¶(S iDş¡íPödã†(•„Wz¸ğõ<t}ê¹3à²Š‹õ û°ª[˜°}N§0Ö`ßBìYdydAØ…œ1tÙÚ¥25C¢ÓpªÏ/òÉßÈ< ¾ÿØ~"ºE—º9NLuíÏäƒ4’İ„ÅTVÅ®©Tu|îCÇœ3>­K/ûa@:Ï ˜ßT~Ú®eÔ6a‡§çÈê†šĞ¢Öµœ¢r‚ÒišY×¹Ú~ézŠV¿%U _ ‹IèY&ğv8 3fÃo°zByÓ•e|çQ!óhŠ2§ásP§öÉ_¶ SÀ¤™iBeUkéo¢]©élƒÈÍëÅ·ë‰Egfä„
€´²æšM$|j‰RÖ¦J%ë|íÏkgí{ÚğÒÅŒğ|a‡|Nÿ‚^Ñ)¡î’t‡ıãÖ/F-şAŞ´ÎF/zƒîÚ²ßäóé\%µœe+²—“PÆ€*pD°»„^Ù!©×ëê~@M+åğëÄUDî‚×+æ+¥u„‹ä%U*™$$b©IX‰›bÙÜVÒmå1±ÓvSJ|âduêùÀóÂ‚ûT*™&Æ«Æï“¨SeÎCäù­òÇ&³3
RN¸"+ÙÂ8ù°¾5icÉ£¯Ÿõñ?xáĞvçdqpH­zxşñÿîööÚüosóY!şßz¶»ó5şÿŸŞ%Ú¤ˆÑœMÚS*MÒóÁóñ mÎ#4Yù¥2òH?ò¡ßsÃ†±‹éZ0¾’O-Å€È· Fø×'	x)ôWÅübú_GÇ ÷ïÉÿ›››Ûıßn6¾êÿ¿gş_­’Ñ‹îv;¾!jë´F]ŒØ~!íŞéa÷èlĞ9 “ë|”#½ˆ,Ìknc ğ"^B˜có(,¸şLàÙt!“„Ø' Ï²g6ä$Ì0>nB‰ã±°/¬æ÷¾0ÕÉJ1† <òëAä*UyHáM£-êØÃBF“ÉëÂ¼ Œ:3bó‰gdx0  èšNŒŒAtLg{ä<}¶§ëÉ°ºíé_¦¨ dõ9«y§½Ó Ÿ!båÈò+ßthÏÍ„	ŒWQfvÀ`s¦Óˆg:8S'ï4‚Ã°xoú¼Î¢)y«v_­ò—´ÿ¼äğ/Vÿo6w¿Öÿ¿äşO±ğªM"Û±hPgç_0ş‡ÍŞ^ñÿ›Ï¾úÿ¯õÿÏ¬ÿ7õÍ­uõÿ¢ ?ğ $L=74!õ!D#¾íà@ş9uiÀÃ@ˆb»àñ¨ 58Y>#:iµí»Ûi¹VàÙÖrìJÕ¢!†&Ä(¸ÿÇ#–Gfş4NãLË$®Gúm‚õFËrËÿØæÒ¦¼Xi.&6¼ öÛXw®(Ç›âÚ,Ï€FíIZ	¶‹hİ¥á–‡òS8`=/¬>UÏ&‘F¤ùC]}
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
œ)µxrñğCgòßU^›u ul¬ƒ‚µÌ©¤Zı¬Ã‰ZÂUò9än¹KÂ¹ÀiİˆÄªqÇ£&×ÉW	“Ì›x!äş¥¬E–İ‘U*«I)F\İ(è×ÕµøQK˜SÃølåŸj¡|6b˜pë¿ôúÿ¶÷mÍmÉšç•ı+JŒIj€ ©‹IAH„dy€´<#*M I¶ qº¤hYû_öéÄ>ìËLìÃì£ıÇ63ëÒUİÕ HÓŸsˆ‰@İ/YUYY™_ÆÓSù‡ïĞğU?I‘`›å•Ä†¬R·§_eüS’©F!J¶Çùõÿ '´«¹ğôgkõbFD©ä+êå(™pğ/[Ò¯ÿ›]z?½“!§„àXËeïd¹ G%oô!ÀcSUˆÿ5ÒZ¥Ñ¤¥ —”NpÙU\0e7UêF®¸B±•è1,ºÎÁ(ê|OHR/ì±€«
8è-”ÿ<H$ÓX©œÃSØ3Pc¦
¼½¢1Ç]V¢Š€}/{Ğ=Ú¤Zø·­L{³bøádÀ\¸µÜà`¦ÚÀ-ì“-g:*­YYmİ¨T¦c4¾1FeNZ£ëæ*P‘ˆT¬š[êqÎ’êÆríäV}ò¾6XÎ%š—bÍ©4ç_áëæPZ}ÅÕ àPçŠ²Uy¨Ğ‹(]cÎ	å”ªIƒ:ÑQ¨«£xQ#}í©Ed¡›‘Ì¸^]¯ÖÅ9¸ö¢µ&}Ùb)ÉùH=™ÆEJ+ƒJt–OdğiaZópÓE‘ÜûÙ¤ßKF9H.¤k„§?Â^§E4à_†1ş"X‚?øp’Äß—q?¬&ƒ3ş}œ¥¿¦ñ¯—`ÜÇ¯°sã«ş Áå.ôÂOÿU½qÌßûùÿ?F¾øRœ>Ü@“ÌÏjÿÈƒP;^|C“6íkšFK+N´¯*É äUO>ğ¢¾hOp>Â‚9¯NşU9ÄÈ;í]öc¾û²ÛØGùw‚eÑµœğ>ş‡c‘‚pX>øCí«¨tôÁ{²ĞÈÀW”¯ñ¯ğ×è+0¨<Êj ÍŠo?Bßdä4Q_Dñ“¡ôv®«õ~›ü	ı¦#ñ¨„Eü—uŞıINÄYìµ×Ç.F#"
¤”(ÆÕ}™~I“‰6b0¤x´iáğ"=i_E–tà¯üÓ`0¤A$3Fcá4[z)‹Ût3†«Ä¤Y¡£.}^Ê_‘Ñ,l1:Si1r!1°/K“êgpFnÿ6m‰‡¸ûëdóê*”u^ÎåÚÅˆy781Õp‹.*•Nj"*awj·ªïœ®d•jı„fjüÂİñ¿[ëEùK7©`áY˜]¨®92«ÏY•^>’›ÀGôšÁÒ:•ÑœËCDf€ÀOü~<«ë0A²èö	qó)‡3%œö¸¾ëaÄXÂ®@O›·ë fk×RÅ¿‰Û(®274*U¶1¶·œ‚J±’HF¹Å.¿§AmX¬’¬äÅğµ´)U!ˆÖÊ]DŸÛóƒ‰úMfİjY%MÍ!)ª)dF,Ïñåé¼PÆ-²¤ÆÇ` yò[4½XpÑ¨N’¸é÷è¦·>8±fTÙtîR\äÇ:"§xV†‹¿Ğ *bÖÿÕOšŠ$`ó§	4'@„†&DŒØá1Ñá»¬½;@ü°Ç·‰æ¬k…€y^L\–êsç‹ÏØàk•,ò}<#P
õ£{aœ‹›!¥Óät:pm3,ßS#µ˜‚àÙ[ÏÂéÅ†ô‡+¿hÒ9¿³"´É·À>cì¸G´››o)//Ò0™?¸H9üçÕ‚é-'pLâ'şĞ,æf3ˆe–0—e0§2£.™[Àö3C6
0 81íğdpA’Ü³\bj;«˜%~H0T:šau&w¾nûèhgÿM·8¥ãäL¬oc´€OÆx†Ie7Îó8º)Aåô œØ²;KùT+tÎ–³ìg†Ü½×Njå<TL­v÷ßÒ0Îgİ²—H†û[ĞŞ™Ù­,FGy›#ÓäÈ°8’G³íîÆÜ(km¿§â¾¯Îçš»<Ï6èv9¹Ğ-ó
[!çw²RfG™	ÔtRõ™²]Á~ãLA[fÏÕ¬N[Û3¿ÓÿùÀ1,ÄÒ¯«ºJÊMÅng)f1»s±ÅÄhmh`f’¡×¹yñÒ.¨šóöòô“*ÚæÑJY$¸],r)·ªc8X´â—nßÙ‚•ßÚƒ9¥›mÿ”?)?ëfãÜ6;f:‘¸0Å·?{Ôµ"æ’£á÷í`„’<?`øÂS †Ã÷²ÉiHÏÖ¡U¶ÀË	ØĞ4§²â*ÖĞ(aµ1ÖÊ1 9¾Ùª„«õ³€û|ïZ¯“—\İ!Z{ÿûæ¼¥’i³'ól’HTW*±¡õÙeBªÈİmï´:M–G×f9ÅjJäÕj8P›ËZ½‚¿R~¸ºœ‰ /F® €¢b–½½@0 $'È
\$\ô,¦áa>_:~ËgÚ¸.-ó†Lö-½ÅP¢AÈs,IxÜO*!]3Ñ<!‘tWåï%ÛØ`
•€téä¯­-Y•Ä÷y¥‰‘¶—FßTtdìÓ—²,‚i}ùóûÏËV¡‚U(1c•é*ÏÅq³@# Â+.ËéÊJm}|i°íËÏ¿Aci£æÖ«k.Ü úá 6™¦{|ôºòÌıæõò9_ˆüÇÒóöø2ˆÂ1ªàøIL1pş>ßåµ¥xu\cüÄ­]„#¿F075¡œ&Å¿úWHøÂe	"ßØùª¬¢=+Íü¼fi#E=¯‰¾èšnÙ1[£UÅËOyÁ\ô¼€rñbºÅ&ÑÀäÛZGšò¹‰u³ª@6ñdÅ¸…jyEZvñ¹.†sB;ŸqÛ'(İUü…Mgmv&vğ¤¼óò½­ºK«ŒÊY*Õg`¨)¸²fÈ×(ÌW€qI«Ãeª€õâ
jBZÀÆM[`Áu±°Òcn;ŒÌ)*ÄXçSº\.$úl'½.pZ_Öà83hœò¥8®¯¡Oq ;‹gÁÄ”•$ì¤i¶ ¥Kæ/ù=Á,¶NÅ.œüñüVpÑß<äD¤¿×È7ş #¿ş»Œ<²²U«ËÙ/éÿ¯¾ŞØ¨çüÕïıÜã¿ÍÃ»LñßÖªuÿÍ‚şf¸ùs$‹íö€íp7`cæÎ¹àÒy°ÚÈÕÜù†>wá¥Ü{ğåƒrYZA¢š/ƒñæ”Şì¼lí²ï[4jïòj_…Ã0B“Oé¥úûvg»İ,/Ÿøïê[ëÑ²r¾×ê´wxÔÄ­§qİã—pÛÚÆè¼ß~ÓÙ9Yêir	$«ª±ÄõŒ2)Ù†‘°õ·ã]UÀFÎ‘fE3!¸uxÔÛ=xõ]Y'·véqÍÁäÃ9	ø¼–†z”/ÆIlFõ½ş…O‘xÒŒóYU•³Æ×Yuâà.*Ø“/´AÏpgŠúË¸WêæòÀïc¸9•ú¢;É˜SzË|$l“cŸïÉìÜ
ûıGøì<`#"Æ„xƒÌÉ O§6âäÕÄTe7t ÖÀñ0î3[yvàÒ8Vê'.„~¬Ùƒ?pÙWÏ9 pn‡òKSN¹B’ƒ‡g“GµBÙCÄd°®Ëuì6‰2ÑL|¸9+­&*‹å•’i4†s]ªŸ…Óñ€…«3¢ŸN®8<ä¹a£ ¸¹¼°ß^¶Œ™9dn¹‘¡çÁ çƒ{»ÁìäE€f¥9!c9pMOÊ¸¼Èj¾.¸>‡< —D_I^KşÄéç%û8à%/:JWù›F’<úÜAõTc(m™c	[ì¦Í•òJ¹äŸË8AeåÇph]DqI4j¡Bé„ ïÑ\YµàW_eQ¦¢²8í©Ö’Çvå-H†J7=°.ù@«JËŸàk­vR«±Ï«:Ô½H·}b¼ÈÍ÷\³Tâü¡xĞÃnóWù©UùÛZåë­÷«&’Œ?äÂ´0çşGæ'°§#Äà³™mUÚÙºâöÒ l'y:áÒÆÜ‡¦AXg’ÆiÙtwwÚÛ½V§Óú+–*f†²ÑD¥““İô×n(Y>lr¦JºGiÍr.˜qèSas¸:<—›ÎM&tš„)ôÁ‹"ï‰TR"ïÒÂ*¹ ±P)yççtJ›rúw#-Ioœ9-uú”QÊ,,j)îeèFÀÀ?F¥:%LJ_Ù8PtM:ñbÜôO¯ÑÒİ'Ï™P*-J†¶4mJ1·ÖÓÙfOXW³\ßR¿Õ
†•†òƒ	×}³¼®BEÏ`LÅ2 kØpÉ¤–‹S‘¢bK àK`ËHò‡…È3¤'‘{½
„ƒ†ñúˆ>2éêO#İÑn*61
€Å¤Ÿ¤AŒgÏ™¸ÉÑ¹õúŞvH8NĞÌKü¦¹A |ãpp¿“ê¤b ç¦¡ÃL‰jä6'†ŸWÀ·:S2ËctíA¯¼ü€e0üS œ?ºb[ÁH^ûE“¢¦ï¦Y™r¹LÍyZ]öGéüÉøVİ·e›? %şè‰dAg‚;*$­tQ—b¨ÚûxÍ4ú!ÎHfÓ%Ìºz3²LŸcÛÌ(}&¦ÆÂú¹3'y¡›ÑšÜj³¬¨LdãHWeı9ú®F@kãíÆà†ôö›Á
Sz£‚Î¦e¬o)şemK-º™q­6Vñ1V'9@8í.:b½Q°JÜ*›ãÜs‰`4ñáDA`ÍP
yogÓÄƒú&ş0äh–™ğ¬"nVWˆñÉíúäZ%šÉÀ=›s Ï(¸„)?÷ã“q®[°¾«Õ*’Ğ‹¯0\ø?İ™hyGHÎLèä“ušŞYp?÷muÔsğˆä0œçş &Ö…û.ÏºzáOWTª³÷Y¥çãù¾¾†X	ËÊ*Tè¹ª²%-ô`#Ú9AO;¨7ö¨!=øÓ ˜§ëì(ºfˆ’=p-÷VÚÎ¿×èn:bäi>ĞAYã`ba‡Û¹‡ˆ­çIöı8ãGŒ¶~ Qq‹½sDä”õëÿÂ5z z‡œ ,L#îR/§ñufŸZËMDštÆtl*çx¤§kg‰›cÀ»µ÷2~ÓUøêIç‘€1§4°éœk<ÿªÎJşøß§(¤ÍaAqb¡ô§•*öLiÄb "fŸ¶·^ÿ„r[(,-a«ê[&T(¢èÆtS«ÏÏÄëÃÉ\w˜‹vÿDUƒ1Ä¹R¹â„èğª2{SlQ‚¦ş`5›¸K2TÎ‚•Q€¾œÎ•WÁ<¥ÕÃ‰ƒù±š¨8»p´IÅ¶—?)‰N³\ÜÄ"ı-<ÊqÆDcy±½~Ã7×5}EÏÍ­ıÄó—¬ìşİ,<Õ$2 IÂ¬„<èó½ó /âÿGĞÄİû~_ÀÿÏã§¬ÿŸõÇû÷Ÿ{ÿï·öÿşØæÿÇÕ©|AG?¯¤¯wÃ•»(H9ühÎr4õ“/äÙ½4‰|TP†sÍœ}çHV¢#7ö[Ç¸:DÍ/ø=TjÚ1S»Õ4½KG}K®•â:qóÈÕe¾UdìqØÁpÀ„Z“lYÖØÊªDg*&s{“ĞĞhCÊá¡-r}@øË:G®såO–â¨\¶³i9æ3Ö=	ï.’XÊ¡vwÎØ¿\¯À>D41ËRã–V•³·Õë£ö[,rs¥dAÂr…XPÄ„S`ÍbZşu¼òà—†ÿ7Ùxó¶@©”B•.§²©<‡¤õĞæ×|R#^à>×p…®ÈW·PÃ‘æ–İEò3²Ñ’eqlR ›L"“ŞìU·öæÖ‹ifW*RäenÀ
kØM¼ds›¬‡Óí¦ó­«*K¤~øÿè¸K/sJLB–fÈBã×Ó¨ıƒŞ›ã¾âEŒ_oÉ›¦áKÓå¯*§Ä‘,ñòèE#ï'ŒWóıú¿ş_X¥qx¡xåˆÃÔ¬_†lTÄC´š+¬¼‚¯Ú¬×€ú*[Õw{ñ˜Â}nıYŞÄˆS#ÉPæV†h­šQ•N¾è“q¤OUm!¹Ò‰Íš¦ Šˆ	ˆ’2àÒ7ù[Jã–o²0éV,E\ËDñ¨^j3@2ò‰–ã¿ºğûÚ$–ƒúàh¢y¦‡û†~¯æã3®şİÚ=jwö[G;ß·•_4µÛpÂß”Ã¼Ìrğze7M‰:ëp­YX¥AûZ÷Öí;†jhÓ	–¬s–: 5ÅK[ÉË^Lrc„ãø"¼"Â’£¡¿õêZuÍ6g4öÛííŞñ!înm<™šõÔ	xğ‘mû§}_«Lüñ_¶¿c¢³Œ÷^„>Ó‡`F«™„Û}VÿÓé¤óv3]¶ÏgVÜ%åˆo½ñóMÍu³lî3©İóúƒGlÓaÏSÔë”×frH v6*¸Y–»G]9FÜõ˜3šÒ œd®†Š4K=®¢¶Múšø‰SÈËÖ~ï% ‚éuQ¥Ô-fÔ¬­TÈGVNa?Å>ğ@—¹¶Úäcí ˆ-'ÕâÕè4<ºA>YT“şiu@ˆ¸æ=şµ7À8|….Ò²z¥ƒèé8à›/¢õšsïÈ8Dô=«pn¯~Òå ›±7ğ‹½€ÈcÕ¯ÿá…rn2¤+[#BÅn¡#ps[C|Ş}o˜ÄY8ZqŠ8£Je2Î}µ<¾®<„C…ÍOX¯?¤ÓG,èØOşÒi?c$g?ó¦ÃÄÁ Šg^¼ÍC¾ĞHGu^rÑÃYÂgo¾ıïê[Dä¯*)$©1¥˜Üü²’¢bÃY©J#Tn	‘- Ô®8àÒeÎU	µš« õiHÆ…J]¡£¸µ«€ÄDO›Z’;µÎ£f9Àä'ãnN&¸Í¥-şN!ôÒ®@Z¡Ã7¿´¾oq›.·œ&Sµ‹È9Pãºs1Ì=
µ©‰eUŠ¦Sµ¥qÍšJ’)KeàObGüØöñíÅqÆç÷e•Œ&ÍåüËïet˜uSüeºWï¶Şîm2{©Îñ3D¬b‡*2EòœÉÒE¦™5Á¨)5:‘½gn¤Háˆ„-Œ™Ÿûÿ2ômI2÷äiı-jt&oK<’Òk?)ÒTòş!®º¡y…gÉÎõ<‰º Z¶Êp‰ğËÙşñ…d’ÕÊÁ–V³µÇÊÚıN†šƒ}à×£¥vÒ,ó’ÙF³§³ƒÆÙêA!Ír§r²ÙóPlY6~Ç±°VGywçeWŞµ÷·?N9!‹OÜxü‹¥ôá$„ˆú?ò“(ŒÉªîÿn0ó€¶n<_jotşÑ#h]ó-_lHÇİvÀ†¹‚¦´¶Ô •¹r€ŠI±’Q¡*›å¸³ÛT€ÅÍ2÷á+wÑL±'c³4¾Ê×ÙAÕÂÌì#bÃîÎ«ö~·İ…Ñë´öÚÀxã¬R}Ó®9{äG…PÖašøKşèå¤UTš.sXë^k¿õ¦İé½ÚÛÖ*~+¾ M¸Lß7İ‚Æ¸¿¹Ø¢¾ÜUÉ˜lgfÑAS+Ü±ê÷2×i­ÌÀï6X*.-ëc·œÚ²	:ÄPNïÍEÛŒ-ñœµ|ã'º€e0Ê‰/ºÜ˜qJšq‚’— aKˆèò}ÜPA¢ÍìÑnUp(ö+n+ön»Õm×ªOÊLîÄZ4êšÚ+(V?((çÔŒÑNq–Òµ:Z´ Ùİ4@Á¨*AeÖ˜ÒÍŸk–èÎÇ™¥ŞÉ[³	%EşG	UåÆç&•3ø·<:Cí7”jü¶>
î¥ø<œ¥t3ØâğÔôü¤+Uh#J.Ql¼|şĞ–©š»Tµu&‚n2»àÈö¿+K0î!øÌ†èE0N¤]{Ä¨FÑDJ@™:$ñÌ¨|.õä‹¼+õ 7í#şÒ÷tÑCC!¯¥O,í¾p Cˆh®¸ı!p®tÂ!ú‚³xÉR‡³òT%ğªWãa¬i‡Ã²p´—…yÎd¶ßàsÏêæÆø,bzk^85µO÷3"ÛWàÓíì8.Ö@}Š&Óág„óXX~ù“Š×Ôj²”·8Ùóóx!²˜}Ç(qÈ‰§OŸ²Jç²`Œô°yca]Fó2IËmëP¯ÒÛ5ê&­7Ö»8.`Ù·ÆÉQœ›Ïç™çŸìõş¦B"m9j¥nb±%ÜàÑeqB[DÕãú|`äKÖÌJ«×Z-¬Ö¨Um£+>[Œ:la¨g±~ØÄşˆ‰G/T†Æ^ˆŠ—ñZJ¦?*ÌØ!\¦£‚¸ÊQş8»×z³ƒ<Ië°·³¿İş¡¹ÆJU.ü¯¤,Ä·;¸^iJÆ5ô±›üú(Qk˜’ÍÔ4‡òó&¨[…ÃWŒá}’?°G­`ÑsU×ÉØ	x¿—g¢¹˜M,İÌşÉŒX“3¢4f“»]³ó
Ú6¤˜î¡mÖ 5X©K:¨\|¡Q!4¼„^AÁğÂãNÿ`Úƒó±7l°ø÷h?Š¦“dU¡hÒßvßk^Ó§ãŸ‚‰‘X†>ˆ™øÌ8Úró¡Üßşn1ŠÎHŠ-Ôjú]7Œ-òØÍ$ÈÆ¢ºÔ\ÍÏºù6U(®”µ¾¤8½¹3(×ßqsöÄJ!¦æ[kfÉ–ùi:Û˜&Ë–
ŸŞÉ(¦ÙŞ%¸)™Ñu‚‰r²İ×Ê—çµºÂº;ovö`÷âBZÜ7<†qÀÆÛš"®Ş|A’ù ’Íî®bÃ”ş)Œ“Ú8H´U:c/r˜•è¶)¨æ•FeƒûÃW<#‘üG@ÏIĞ§×İ¨ñ¸Ú¨>vm‰”Xİù†Õó0<úUà $i(1ŒHïšŸ*=QG'¬Â|ZK†áoºÅˆşrC£‚NTŒ0ú(Ş¹só·¡ÈÒè°-éã”6.ˆı%–²$ÚV‰9Øwîüù| ÷JéRwğÎÒ5\}fUØq½A`ïfÄŠß©o^R‘¸áN˜9SÑo† 0‹éÍ+?úÈé_yAòHİÆğ©ëÄİ*(.@ ¡SWdÁX8TÅe’!º0†€l9":acáŒÑÅËbºvZ¿MÍé+¡e¦n5WÚl¥*nL³}»Yûf÷øØ×Œ©¬çƒá İŞ5±´½'ßÃïä¡[øĞ×¸ÌY‹F¾ïMûÈ-ÌF¾â|<9Şå‘5ñòxgW Ìì„3®ñ-^üéAm×=ôSœsì¾5—<Fô<˜W…‘–ÍKìEü¤ÇH`Q/šÁ›|èòj"Í-Á&îíìë–…„¶İ£¸xĞàäænïj³1õ™uc=õÏBR§vá yiV[xR¤FıJ¹èÛ°šÇò¶¼á ºhùiV	´­*]å¥ÇÊÇoKÃ8s!-².Ò äè¼j™‹ÍŒ)+ Ú|ˆ	vQ9>éğp;3zq«L†vd¨¿Àævnv
ş’$ºgmQ˜&Îjãí6Rc+•›©ú{,É‡{fr;şÄ"Ø`3<S~ƒ%±ß\Õ~êê¿´mR[ë.Ç-Æı‚ã—J}R¥§—ªî	<Öj‡;Ë]`´!Íû¥ö–?Àó²ÆÃk²X*M˜'æY GäK+Ê’QÀÈõ0Çñ­Óïù7¡ÚªúœYV¼(á²DígÙB2jıtWÌ¦1œZeÏÂ?nw`b®ÆÚÓçfú•U:…İœ›¯ÀUšô)ËgZƒÁ€s2éóoŒÊa"âuĞc–qq\X<a\1ô·¨ìä–¾XcºúWÿó½ˆ¢H€FxV¤×‰¡2M»_éòZ´ôÍË*‹ı‡4¾g>Z£œÑ#aHğìŒ,•%ß¬5OØ¹¦¦õ%6 è_àïUVÒ
yË_úC)¢‚ÄFAè1LÄ±éò,4SDU.Ë¡Œe‡6¼¼²štÚÀ½4`³<X_b+ğ9êhFïQ’`VÕhi1U#K#Š¬»’õj]G˜ğºÎR×¦ÿsRóŞ?b˜9oüä	“õ–r4Ü¹‚1¡P¬´ô(cv/ç^³Ø‰+6—ƒy î‘BŸm!¡ğ£„‚9F"¡0‰‘0G„”êoÕJqŸ¦»À¸c*ËÊ(£y¤7cô_)S¥ø¦:¬†ó‘Ağ,ë}¤ÿë?ò½…?šgC¢ö‘—ÀšÂĞ{şÈÅ± ,Š3ï'ØğOÊn$ ­&g[l	íÈ'Y@o½·Ö[Ë˜p¥]]07+AsÒÆpNX"İ¬-™¶Ü°1ò~ªj×ªŸ‰çaæ´jge+bÛèt÷a®*Ó¿³q3Ã„NE§X‹ù‰Î¯œŠ‡ÍÎNmã¨¸Ñ'_œÜRq™ñı,ØŸÕñ™«ÀŠILˆ4K²¦WKNÃ··&Ôu£3iO§c%±»ÅäšÎ( Œ.AÓÕ–&{’à¿b×¤KK/‘½¦ˆ–Tè>E¼­ªBßeg›ô>ŠÂHÙÖöË$<ø—\ø8‹»á¹PdMµ}®Æ~,ºÔò--Â³J5|<”]‘·;6‘4}Ù-™Î”8×U¿1Û¥¥¡47&œÔÌ^hÄ=‡ĞäwşËs‚È}¼à“Õ¥?/˜aÊ°i+f7ƒçş¬d–Ù*8-xƒòœØİrW†:•\%®õQT?”ì=+8¸VÒMööÂ£í.6ë‚ÃyÖş]š»‹B)ÄRRg&dÅWXÓ¬:3ê³;‚50µ'SÕ"ËQ3Ó;Ùœ8¿Çéaúá=Ğ.î7Ts-‰Ó¾¦ß€ÓKA|y°®²Š8úA?5Ç—
¯[÷/ªî ¬S³6ıkî|•ÍÒ#—]ŒÏ€HİŸ,ŞT	m¨›©-tÎ0½©¼Œ½ÃİW;G½Ö«#(£·w°İ†+xÉƒ=Ú‹Ïür-ÔXå_áf…Ûˆ¼^±kXJÚåM¾ÔÎ©qmÖ²RxêÃNÌ‘ø¼A„ûsˆè,$Ó²Z–ò(9bJDGn_ka¥|¹¼`lP¸©·a;I§şm48gädÏÁÜIÇ•êè/W"A†Ú…í£ì®T`'ìØ˜…RF"h“.²”áE‡Êîäì •Ş‘ßâEè‡“ıÈ²lÄYµk(ªhç³1·ØNt='á¡•Î8È2Ç˜SpjYÈÜ±1K½.]$‡aœ¼n	s§ˆíù|Kü·*Á$¡<mèÿ.ş>~\€ÿ†ß7rşÖÜã¿İã¿İÿ­ÈßOßŠâÆÉ=Q(nâHñ:«06g›RMíêêªz\z!×'ƒìÕÓ¨6€»D­‹n*¼¶
ÁWŠ²ÃqÚV”× /úB¨pùL>i¥íYYeJDĞŸ"‚­Éóö¾ƒ½ÃNûp÷¯äÉ"QD…½·íî;úú
¿§Œ9ST8´‡ ®ÀøLĞv]Ó¿©À¥Õ{ÅßŠçM´ªÄVhÆºdï]RF:^¥GGàe>A[?³f“U²÷š©Ö!ôÓcp¼Nå->ÈbËàºP©ˆìšHİH¿bà|VyÍŠ†”éá‹ç¨Ü(GµvóZxYÏŒıŸ
¸ğaMFñÆÿlÔŸn<Éá>^¿ßÿï÷ÿ[ã®Ûğ?.|tÊšRú‚ Ö“Ä81.‘Ëî,ş2.ßRYA‘Ğ—^Nâ*^ÒKªDĞ4P^{hz* è¯å=±çõ}„Qœ<`&V”ĞºÍqÿàhç5Z©ïo£“_%Ñ‡Ipv]A¤ôUG‰šÜMVQ{µ”t†äş%Ê“é.ù?S1†»ê(NYˆ£5ınÒSê´vşÆ¶XkïåN{ÿ¨Í'Ë‘·8^%«£ßót;BR‹ûfVz·ûaûMo»uÔBÛƒnSsß»©9âå9µ-Òu¬‚—–H&òm{÷ºÏƒiæ>ı>›”m•(˜4QrO’“ä0¼ò#²PİöÆ?dCXéAä¡QòO¥tVŞ.êèRİ'ÉC»ö5%Ã€c‚Šbõ'Õµ¶{ÔÍE<ËFğ7á= wˆ´†RéĞ9ä ìuç ˆd»éaUFó|	ĞôÔˆ¡â±Nµ€^5×ô,Ê™ı"åï}‡¢;\gfx×oùlÒ_ÖSØĞ÷(pX?-«±È#Ak‘ûHrv¿;:8„uùqpLYTA¼J¾´ÖĞ&.©§ı¤ÚŸzÕéÙ(Ö9Mª¬×ÏtŠ^Ü¦€áä€[Ô0kàR*ÙmmP`à*~Üœ¤²±¾¾şôë'Ü¬DJ|R›)4Y;U1‹ªfTvªçºY[¤^÷˜àt´r?‹Æ}|ö¤÷d#×6²¹mfe5«`Ê­–@Oªõjİu2f:3Ç´«fã™«H5¯ÌŞšÉDæÓ±ên‚"©]+»¹ÜxŠÉ–yOæÀ¹¬:…¨;èÎê¬²hT:¦[³tö™cÑ?ÕÕO·f)æcn	¿¥†mô“ë¬ÊÚ·2êöfEêì3»Ù ~Î¶H˜İ¹Ê¼ÎQ*|éT¬v*‘lG¶ŸF³#³v	²vff¥îçAr1=¥áÇÑ]Ïx3‘H˜(Î[Ü	ñ	(Ï8UuøöÌcDÓDT0Óõv¶Û2ÕHx´˜ÆGJàñ!àC%¢X@×|¼,<nºp>%j­Üö/‰O;ŒÂı~‚f#%U,²®('^ß×û ‡¦4ZœïË^{ÿ¸·sÔŞ3ÒÛù¬š7Á·*RNˆµ¢ªÀÒ~HBØ¿ÄÔª-l£Z§İÇÍe½ìhÕÆÈŸ“¶[k~ØxÑ¦[UVÇÒª&·ìh¶æ)}	7ÈUo‚‘†´†ø£hÒ7E¸èøqGÂ"J*¨H­âsRVá^]ıø“ëè¶æptÜ4kn æ• F9&;!Uù`ºN§İÚ¥RÅŞ¯×S|o¨
Öäé@É=E”¥F*
N§œ(æÌõ”NºŒ9ğ¡‹æDOL«‹Dl ç¤‡'œgO²ÑMWºpÓ×p3g­vR­õ>³ß¿ğQÉÎd¢»§åê2=„õ±ğ~ÀïSôlÊ‚1\ñôzå£³T“:vlmT/ÇÕ³È÷'äÒ BPM4µ–xçq-Û\˜ñ¬—Ë”Ç[íŸÜó’g\¦Ô«A^Ÿ€Î;9Æ¡di4ô€zï¦Xµ”¤fKÄÉ¤’ğ•P¯>«RÎ%Ç1u+€¦Vvºİ^«³§®:÷±L®–¸F5>ÄÓù*Ï^Kş	5¬7%‰ˆë¯èªÑÙûöµ‹>ãQK Öz4º|ê¹LŞ;í×;?4ñ>»¼ê”´¦azkãnĞZ¨}íqçGp†5«Tø‰çTí¥ƒÊ„?ÏÇ¤‘œzï4
ç°s&gÄCzXTu8ù@ ˆğ×ş²[áp¹¶óé‚làÖ45÷®š,~¦©xÀ­ü{¶»Eáê…~ı¡ÚxÖ*Ğ¾÷î~0q,uÚoÚ?°ï[Ü=ºó¶Ó3Ø
CqùäF_æ´'Jëyoàxöh¸¯p´§ëõÊÀ¿~ïô<ù ›•úIğñtz¦ö½ 
ò¬‘ó°Æ~LâD~÷’ZÌùE¿"kÂsã|8MÖÓoî:)mÓùã)"´±xzzÉÈlä}ğŸ^à¨Ñ! 7dÊÀ¡¦ãÈ‹˜¼2pÎİœ²søGŞ*¡îìbÕ±ÏÓ6RbÎ)è]²zv!”	!‡	ÿ^és½èúpL’hà5Ø8W°¿®(¬‚–wT lÒïŞ½wœB&»¦‹’¿Øœ«d"íJ?G;@bo[;p³wlğ(E¾ÖR!œv²­yŞ.|Ğ iÈÂ¹r}àGB!æÛ÷NƒÊFõëÚ$ò‘D«?•’ O\ fRW®{|ˆdÀ¾mC3;İ;‘‹²o×E~Všİœ×Ekšsf/ÁC[rgÈ’•ñÿÍ²uhTûUSjN•ÒóR]Ñt.ÛŠˆÛ§‘7†û
ìûÁGØñ×‘ëËfúò¸91„Ëí«âXMÙ¾iõ,%î²R‹?_ iå7İ|Û³ÎB–Ÿ-g£vaç«×İƒŸBüÁ!wµİ¨n ŒpÕÜn²©µûİdÓ¡§Ö%v<åTSDdg05~uì'@ë\ˆ î„Ç^JZj¬ÑËüõFƒ'ğvu-¶èÎDÖ?x@÷Ğ7ÍF¥Ş£ü¸±ü/iêˆóÖ4ÒÖ,ãî^ùW|€C!uğLèré¬y>cñõ8ñ>nò'Síá$	á_6,}»zç¶`ü>µ®§‡Ïíöçwá$Å+H3£×f»)ŸÒf½i3?ŸÕĞ,{ ;?şåŸ²–|Ÿx³u•™Âsut¦c)€Ê˜â9ï—¿Ï¯NS¿)ªï(d?NãD©öRµgR#“­N¾§#d¤“l–wéC|'GÇÀ‚­Îo©Íih?p°ã
ş€µ`ù\õ¨¨–i)é 1
úBq’j¦Òáâ¬n@'T:>›+ó[ËhvÑ¦C§ñÙŸY¤dÌøZÙÌ¬•l[XnåiÏ®¼¥–ã·İ#-µPêRÑûÇ{/Ûìb=Ôm‚¥™kÉzcpV¬UëOªuY¾5ŠOÆi_öÃëPuó®ÿòOöòZn y‹ùâjWy¥ÁğiLZ$åâ„RI3…Ï¡	ÇíÒãT¢ğÈÑşåïlçS¡+ú!a^ëÙi¢ŞVª/wRî–=ƒãq®ş¯aoğeõëëŸæõ7Öîõ¿îõ¿æèİZL#õÛé€qÕşXÀğX?“Š1i}}_ş€%^^á}¼KÏÑx-Z›ù©0îOÙ]áágÇá|«Ä-·e3tIİE2 lz8®Ä¨C3²HÃ•÷¢­B‡a¨îWü>ê.š—.°\ü'*tJ=ãªĞMq­ÇÑ1B3øR™ô§`Ò4AG……NØQÎ†Hk^äÈ;ú=&U@€$4+­1JòÁ¥¥RB2oN´¡‡s<gÆJëj´Òndñî ì1…	5øıDıVš#ú”P±”“Ú\ïÈgm¥®Ûq
Ûi¸õ>ê<Pë<íù»l!&p“[Ö³Z<bSEµZefZaÀË*Ñ¥£a‹’FdƒC1‘™Öëè)µáÑ-½„9}t7WÊèsÏDÍÃˆ‚UÉ¢Á	l¥å@l†/Oé'WÆŸWgØ(×b»hÑû"ë8éìVÇ¦t¸	wT|¹w2–MÔÍ”8?ø=² XQ@‡‹•ÃèèxJ ‚7][ù6—§l²Y–ø
ZûÉ.Ø=<lê˜²¨ÏµÉ¤ÿñ‰ Q1¡‚z9!¥ZÕà°M@uSohÇ¬Ÿå­E3~O˜Y+‘Î…T’Ø 7ò)ì/Á3fiEFÂ°k×›¢kTpÂ°e‡½„šÁÛÁÓ	´„Ó¡/GÂîMJV »x3 ]I€/n(dÄíAÌG!şÓÆZ^ñ•)-ë–J´µ“"
Ç¸¦;Dz¡5Ö):Ş´<¢Ncİâıä'^0Igr‚™°ÇfWËSs`…a¢°MÀz2‡7(7ä¡ ßâÉ	ˆoñ[”“5AÕìÄ3éRû›V¡6ø•²®kõPihƒr±‹í9>³	U„à¬ØQ¶¹ÄËc‘Oä§µ‡¼_ÿÏÀ#`‡øˆÌz#om&á¡jhàQ9ebÛpr nÃƒ©f8c_|ÕP?XŞÓ»¨ØºÓ‹²ºUâB¢8eB–?pE‹ ccŒNÆm8«6UÕ9ó¸¥ûp5Ÿ6kş¼‘¿	ìbyÊºñÎBrØô˜”C'+2ïé’µÇ{Ùş¡“PõŞÄbØûAÌqæÙª¼6ëó÷²pø?H‰¸ åò6úˆ«¦J¥J};6 ‡­Ôî<ÛA6¿‡©o*Ú°$Àëì.=Tm¿u'YzfK´‡œİú–êß16Qš^º[PÒ°ìÆ°wÁÜ:%ÍŸˆAªKKÜp¯˜cå‡Àpã’»¹¡D:?6+<‡Üß¡ZgÏÃ)­$µKµ½h ¥¿KÇ´@ÄÎµ"^Œ…¢Ãª†2‹*`ms8õæ÷q´rÒcû	œ?ÿ,=M(×†ÅI+ÛÊxr]‰¸`ÏàúDŠÇ"î`ª"gøeå+o°ò“¬»"Ş31v…9£Û÷&~ÜM"Ô»*iEz‰ Ï¦C’LÇxN¼1¹2„½á~äÜuîÛÓ@®À"(•Š[º(ä”_š¶6"ÃÖ0®’6SM
õ€X"û“9õ	ÌlƒëÚš×%&dÒ¸4nYòÚ2ÍÍõöE+¼DÅ~je%[Ogëi/Æl§­Jv/µn¦…»©u;{v}ËeÄì-’[..lf`Û¯Ì;	S:£Çc%dNE~™Ä[¬J¾‡Ü,‚vDÃâÁÆı]{¡:Á_˜n?f7¦¼j—÷\£4³/r¦K\0âsü{l{i‰®Xx›ëÂ/ê ´¬SÓf-‘ÈOĞ¤“hõAù¤?E½±B—Ş6JØ4…Cµ—¯ğ^†œb(©|_©­Wuf$U)ñAÌ]eù=¡iŸd‚š±âòwÆĞhØQ$XÄWÌ•ÅÙm‰Xåú±×wşòÿjmöãÚïZÇüüdŞêõ'ëÿÆß¿ÿ|©ù‡ã¼öGšÿ§ëOîçÿÏ¿şœş%ç}m½}ÿ]¯ßã|™ù?qñ‘s‚jìxY10fªGßšÏ˜‹Ïª¬5=gõg.#T¸±¹Ä)ÊT#º1û®Sí~Ëö[{mÇTÕ8QI“0£<DYº;û‡İ®c¶æ4r4Ìşîäì%—œuŞÓO8tágcæd€sl‰¬ix¹”&“qß _V”Uİ­T«N*'œÌ‡pÖĞOïWF°v1ÂI»‡ºc·İî¾êìPcÉUH”‡êa0æŞƒ>k=Â¹@äª^²Ú-Ô£7¢aRûÓ¦²rª³¢$R+e¬!Ø[î©*Æ×ÉŒü<ŠPW”XŒ¾“JÆ–Trh‘®G“cg¹fëtéyÅà2ªŠ”©HNÁz2cÊ0m‡Ïç‰œPÈõ—œV]ê^~†Rİ0Ğ•êhÀ¸8^›I¡bäßÿüó;‘à=“MŠı
qĞØÙ5²` ×Ù’áxW¡P¡ªE]
Z¶ÅjÑĞª,¢¡%Èš/9vsŠƒFˆ0lÁš“ƒ(o|ÍÈn[È{3Kt…ƒ KŒû~8…!bš
V~•·jà½
6­k]"˜m±¦4[+òQÇ °ëìpÕÍµÅĞ›¢Öx”6…u“’h—¡-Ë##¸Ü5ƒ2)Ph E,FŸpı¢Õv|ôíAÇÉB³¬( öê¾¸Ñ´|Õqşíşóßá#ø?éÍ«£ÁÄ[ÛXËá¿m¬oÔïù¿/¢ÿg™u80Ô€Rz#ÖPÁc„çLÀi8MØØ¿bg¾—>Â§À’½HÕq.I1øm¿ïNıè#½<´x>yá,=“(Ÿ¿Øo¿ín>¯‰_>ÂÿKÏ‡ÁyŠîÃ)Š˜:Ïk(ãÈÚ„qT=R8ÏæÀ
z„dNÈ.^ØÁÇ®Á´’Tz¦ôÌØ&{î^H‹°‡O'ÕøâybŒfièÈU£I]<EŸßƒlà¸;Çzú×S:Êùé®Äªi¤Wõ¬8«¾†ŞØ“®| `+¸š7‰o8˜øã¿lW¯¯>™Ÿ×h„åø¿Şù¡½]0„GzÆ‚}Ü<›ôGP¹€
ÇqF/¹‘x|„1”ÓäÍÑ‰úÊGØx´NK$}ujö’ó¼ÄÃ©«ÔÕ©£‹u’±gET6«—)wvõQÊU×dÔê_ß‚šÑı”R]+"ÈƒU¢ã°Æ3["®œÅ}Äs¨#=Õ_	$Z:	1pîáˆ‘4±èyºÄPhl	¥F2Nk„şÕ˜bK%mĞ$'’‚¢èdqÂË`.Ğ®20¨«#§RœŒ.€‘‹|©>¬ `é³ãŸÑº6£·P(f…Z±ª·ÏÈke5QR&,+wùàÌÈ@ âéè®ÕÙ»|Zó}³|P›%ŸNx=‚_ª^íî°=ô¡sîÇÙıÇİxİàã/È€®“©YNG™å}s’ÀÑ¦qÖ'Ú6Ï”ºÃŸ©›rp^t<3ïÏ-¬Áíy×°j”°0)ó×EjcÈĞânM~Ù`°¿ë˜†5®0;¸-¸ˆ3şhCj>ÁÇ‹½ÅxÁş{<V§˜( mdì(@ãÜsôDD»ÑÈ¨…çOş/ÎÿÃ’½k®qşıéÓÿßÀ?÷üÿø<|øÕø4léÿë,èJ}•2MğËòyòÿ÷
)^$#ËÔÿğ¡ã<|ˆbdø†[±0^|>‰|õC|LñÌ1³,£F…ğàáC)x_Q½(’ämrŸær7µO¿Oc„.šYÛ­ó±4§¹jÍÑ¢ÅÁ®Gfãä¡Ÿï® TP‚&	´—€òÕ|·2Ó¥ÉºÍŸ»”gàÄÕü¸ìƒÆÎ§¸â™cÌ˜¿ÍŒ’ ’ÅkÈN¾¦@Ø>³ ¥,bU]X AyCçT6_T€…4¥wÄ¾¨$ó43ÄøLXÇÉHQ~¡,Ÿ­P¾!Ş¿énÅìO z×¤h^ë˜6„$¬O£Ä³@š å);j6E½˜Áòİ`ÖFzëf"K÷ÉÏ?ùè »(2¦CpÇïv’ëò1*ÙyCh<YõdvîÂşË;µâä›?tˆ—ñÔ1ï­ƒ×ˆÛ*½w@¥¢EVLzv±ü‰ˆî8Ÿq…¼wx˜Ãÿ7Öfõ?7 ù=ÿÿEäÿ	­>šz8•ÿ}êGä¨*f%)ù8^ >Iì›•Z|#<ïF¾Ï×ãY8†W(Rˆ ´@”Û……C–\Oü¦»ãJ!ÅÂ_ ºl…8e™°
‰b”lÃŞğÜc‘fÆæ‹]®uZêµtË©(iHítÂİÊŒjvk{¯dï¾ÛR»Üóš÷‚”ûÃ³³ @×©º½!”•—wÓ
³urSeT#ãÑÈp‘Õ˜ó¿ôbè?ß:·µbd!|<¹´ÿké€;¢Õ(W æp¡@%Â?>TUàeìa‰¢ÅC.Zì’Áæ¢e£eYâ/ÿd¿üİ(ö˜DO¢½È¢G>²èˆ4 Ü÷x‚D^j‚DFvqœÄ×èY?Qé q &fÁ£  Z
‚`sï$Ë±q¤ÇáÍZâ	L‰˜¸ôxĞŠuö¸Vá¼‰Æ7km“7P	(¡&½’(Oüé
#>¿at•DOÑF]­MÚ«Ê',ÀGµ`D>(ŠRô´#«¥æ-ç+»×¸ÿÜî?÷ŸûÏıçşsÿ¹ÿÜî?÷ŸûÏıç?Ñçÿw¡ã‰ h 