#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1728604334"
MD5="66204b07a1bba3f172c54783a278df87"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20640"
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
	echo Uncompressed size: 136 KB
	echo Compression: xz
	echo Date of packaging: Mon Mar  2 08:43:32 -03 2020
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
	echo OLDUSIZE=136
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
	MS_Printf "About to extract 136 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 136; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (136 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáÿP`] ¼}•ÀJFœÄÿ.»á_j¨ÙÏÙÏ9\Á¨i—/ƒn­ı¢‘j=~® ».øCr¤±wŠ3«Œ*k4õöŠ\È:k³,}—Ëü3ö7»ğ°¾øƒ¸	+Ä»!ÂkİÊ±Vî¹®á#ì©k¨	+œÏu[İŒÔßÛ²È?´¥³qõˆK×ş\×[cÒù·¸>+^T±¶ƒ£İØ·l¿ûâ;!c›?½-Sëüã-±·T„ƒ§XìU½r#Dúú*êñ¸Óòc8|wVr!E¼H"s~©Ğr9¥[~ ´°×†³ôÉ­­¶¡Ñ€Ë˜ç¿HÌeéŠÈ]øDØV·À·xšó7 $Å\#î$z¹*ğlOÑ?À}¤<À°$ğXFİr7°:À»9ÕWòM_ø{]½ğõ¼úZ× œX7·ñ±ŸFUÕÈ^Z”îG{”åÄí…%W·ï(8ûOhøÌüÆmä÷+V³èø¡>1µs©ËDƒ5&V.E'Ù²Òîw)ÜèoMUR"„N™ŠĞd~İÕ‡IÃg(£…”áH÷ã¹éîÈ<Va†-ç}„Öxƒ_ßÀŸmÎZâÔ÷n€hßú¡0"&©§œzí¶t¹3’7‘ÌYM†b±;œ« ÛÖÁHHÇ´šéN5O¤Y4Ñø9„ô’~â²~'Ú8BúÏûMzÿ@³ÅøT‰_Ø!˜=³LV.1‹ê'nx meé§7Ï¿PÛÒƒ‡à…A†Â€…8<®¶¦XÀqŒø\q.QJ°
Ğr±s`Z›Ô€ìkW®vŒšİY,×-)_NÇ…¼Í`¥¶Âíè~l“s.’ )45f#’àı««ás%Fma/Î‡¾;ØÛPM˜„ääŒñ- ï)Gb¾ÉÌ·9èÌ,u˜£äÊC‘ åŞ,M©Hz¬¢ú|rıÏ ¤¹­rCZÓ:|¨‘7º¥ªñy:²²¯„RÚTD “MyªØŞÀ.sì&õØÑ½£µJt—XV!ƒ3¸¶`JlJmÒ›¦9Ú¤0ÇØ]ÓfşŠôüqe&ë~»1Ó»Oİ›1İÌJO;¾ŞfƒÌf£µdEW`b=½4Õ¬rˆš ¿Ş½kğ|’— ”¹ñ¯‹<óiÜO*%õ³Q‡êÍµÄ·üëÔ'|£/$E(¢ßg¦Ê|wcÉÔùèFª'÷&M60àÂ°ÖÉ¾{íúñOa·fıä'¸ÃU4Ovc¾ÃÙ?¬M›B8ß+èñz09t÷‘§™›^W-Õ½O°^•,‘h’ÌÔ8Åv¸û2Ä´Xùœ h†¶Ö`¿œ¿z“’3)~™¿9äFH-Í
 ŒBZ†ÂåÿÄñS°/[ ˜¿áÏ§ë|&âØlN˜„zøZíö(Ù—Œ«ËD¹sä—(Œ'‚h%4]5XÇ÷”'8xaÍ€È	¢•£m†éàØ±bÌ»ì®JÍtbşè»WŠoÈ»¡´Ú›&¥äÔıŒC™+¹îªK7i3ûµı ç¥Ó¯v4ñÍ¥¶·c}‰ê@BãœûÏ
ù…FâÅö¾›ÂW}.Tó»¸Î8x"aÈØ;ôwäY±Ã<y<Î$öbÄADÛU’zV·À*+xgÔÉ´i£®i'tç¡qóÄe«»‘Z@SÑmïâ€¤æ×@é9(ùd¾uì#‰ıèÆ}¿¿j,Âõ©Y•¯Ô£q³–şÅi÷¼·óÏh€³• 4ú.
åVCŒAìö„m˜İ›9² ÊA)R»UÈ-+täO3v9s°]bzåëó+=CvC(rHVbä;8îM íøÉI£$µ¶äeÖ–÷ MÊ(_ÓúRÛïÔÿÙ¥]‰?ûpŒ€“ºİp
YÑKÊÍ6Ôší’åœãÈWYÕ“#ğGˆÁC‰çÊ•-æ½â¸µ]†M´ÚÙÜÎWŠb3Bˆi{÷Bø¿>y( !BìâŠy­ç#ìhÃìØGI}dÑ }ÉØA-ÂbîÜeZ¤ŸµÌ“ŠéåÜì5i’o5ÈV¸QÄó€õX øÍp/šoPH_E‚™)Ú#ØÃQ)ÒërWfûDKÂ Ì7›³»¯f†Ï0…Ñ0©7†Í2pUXûİÂ`ãzÄãçŒĞİm­Í}å¹~Oc·ÙMGªÎx+|è„>UŞ$ŞgÆ”f\şòÔ«Q³~ğ•s…lŒ·z9ì[ğê_ÚèÚùúXp©ÎÖJtŸrJï–@ßøÜª°á,Z“o!ŞšGp)ÑNÏĞxú{ÿê'ÄI‰E—Ldğu$oºÀÇúÉzíÆ-Fm¸/µö»±˜{YQ.FZd/TëRÃi+”AFqô§²
¡H(<™¤àÑæU²µ¯fÚnQM Ã¦"eÖµ{3¨v‹ôd’å€ QJÎ€F‚8bÁ(È¾¼lÇçJ´c³İçû¬–EV4>]¡£”×]Î@„NjÉ ôÁ¦å4²×iù0œí¬“üÔğ7Kx·>=å_š£{À@ÈÂæœö¼IPÖ\Râõc¼PéßY 1~¸°r©`­’÷0ö¢ÂS`„E¬íÌf·Ç9`y¡Ñ®ã„ñ¾´0ù}öÛHDy¥Ó´QzÎ#AZ{¿Ãi‰™%6k³›/O¡R¼[9¬˜Ûƒ=»

˜CÌe•QTÎW<öVYÒÆcØUó•©Ä9šF?´â—dï.¦gª‘ÛPDa ƒ¬úÁGU×µ
ŒöXk?abePbµ‹ÕÔÆ=&“ƒ‹“9¸b)ö{¿[#É-ñúaú£k¸Ñ¼çYuÓû8œ(GÚĞÁ¦–˜dàN¼;Äq1½ÖæO–|È±™İ†ºnHÈnqO°wı¹Ş Ç_e[„K“ÛÓ”+íáúæªY;Ä'ì{>Š”Ê™n0.q% ‡ÑÊÔ_UºµC7î 6HØİ‚Uz@Oêx¸…|…úü›¸¦ÎPÑ2í3I£ô~f¢šì^D‚·â¸ÑW=IÁ×Î5OŠ)©Zğ€W\„øùôÊƒ#[6µß¢ÔaÌkhá’*1+ƒIç›>- ¾ŸTÿK ŞñÚ`Æ‰òšl3-ÇœÉ5Ñç¾3N™§2ãp÷¤–šÅÃ·Ä:¦’Ï‰Ÿéw†ì²U*R!£Áyû®\]á;Æä>’VË%›**F@ôÂFî”Ï¸3ûÒ|×8¸ÇtæÏA‡iSáú®	b[ÙZg—«nÍ•ÀC­°Ö~2îşµUbıY~uqÚ9øÇ~nÕvnş7ø«‚‚dö”Ú	³FÑX¬{ÿ5Û~ä¤‚Ox@7¸÷FÚFy­ÕS“^È1È¡-è“FšæÒei#·©Z
İßŠ•™iáíXĞ…÷µƒü9ïõúN7&3Ø¶òô3KøĞÒ?dˆœ@üm‡½‚ä¥­|5;¤,ëú£D(=>#;\ìÕUp—öµŒA·Ğ»³ø}Ú{'¢ÎÆGS˜ç0™zÒ'ì›Î•ã$ßmÈæ"Ñ›$Øİƒé¥É5Û¬ùèŠœ¶ŠkFõÅÀ©±‚ü¹ĞùpˆƒBàWnêG"ÚdĞeÏxšªö¹<â¡¢½ûõ’ˆoó^ë¢€ób“ûaí}é£(Ëf&òd©ĞHå´î~¿†Æ…oàÒğP
`šÛ¬^$vææİŸxUÇÀİ£ç'ÎöÈ‚Qæö~³4á·µ†F£^Z•ÊÚ`ŸÁuFİ
KP×’<Czœ¸^<»æõ‘4º«µÌ©ó¢‹î†}µÏÍŞf‹ošçDİìˆÍ“Íÿğ†ìka–‘ŸIh…H«%j†m¼%è –±^y¿§5u
_¥‰;xªUÒô#X“õŒŸ¦$LA? ¾^”»…³ŞJ¿[è&"o)ù¯¥Í”ò_Æ™sl­{r«æ²bø±9°˜Û_1­Bşc[>8E¸)–ÂáåSl8Ö^O~¡c[ÉQoß´ü±"ù#>³hsŒA¤‚:^û‘¯œ.·ÊÄ¾ëfÓÅŸjl(IgïŸrĞîz•kÜÔ·#ë'Ë4YòÁ¼À$u†	éVà÷Ô2ÉÍ„¦‘È•'D©Í&½”çJ‘&K&hRé,6–“/ë?r„&1QĞÍŠ.0öÚ!b™\@sGÁ—\ñPJŠrwV¯§kÖı0†Âú|,xl²A)N¨+2×©z{<’aE“¾ynñ+äš9Ÿ{Ñ\×ÃL7ˆÇ#Å¡÷n^
­
ƒÃkd­AKÖ*Cöû¾í~±X‡¼ÉÇÕ-yÕ"©ºD… Í$-üş³ëqÅƒ{r„ËQŒ2©EA*Ü£õfá6ÖB¡_† é¸Y4¹úf
_2¬¡‘O6B'3¡ya¨‡³¯Ç™›+„ÈL´ÖÚ²‘8
5ÁxPNå1‘qŸé¦›ƒqé@ÖÆ¹9ø¢QeIÓ›K6-Mİ´´ÛóàızMº9„XP¯­pBoÚx¶‚;rk@8d…cø~ìÈşÄ€ø®M-ƒ_½É4Ÿ]$@hî¬¹–‡ì`?€Ìp´×&ÑYz¤­ÆŞ]b)Ñ}‹¼Ëu¥í×!C‹dg:´;‡Ç(8õE(Â &H’Éi@6çCƒMÅm;FêYaa°70ÇBmj+"ª€0FâøÄú6 ‚ínÿôæd?Â@¢áÏ3CÓÄ¸€Ú¼Ÿñ…²åŠÄ'Û»Ê£V›Ã|¾jFU®¡§n17–÷/"
°6Ş6 W‚ı5 VÓÙİÁFälænJçn¹AçàÒ®ÂÔ”Çdo-{3©IÆ×¯sşÃkVË´Î›G@PKÓK0Ø"2Ípûd^ÕğV‰şKfÏq®È7·+³5êõ,1…ì„^1¦¿t×ÊFßúg
ÔÉhbóÿ“p4`·DÁÖÆQ´ÇÓ#
fı2—ã2¡H·¿«8x4ı!û–ÚÅ»Yù.S¾¤½øÜkøªÛùåhŞÊÂ§±Ä4WŸİ‰Üb;]ÄÁ4PCÆ?ˆÖÈ{”Ü2P-@B%I«¯x%›±ÊÉ÷…Ó¼U%nüÍ•<õFÁ~g%NwÑTEBzZŠ<!RvÎ ùS’_Âœ?9cèï†„Ç“òuÌ[]nŞ;Û¿ÂŸ®Bäõã†
æxny×·8éÿ¹t´¥c•±ş`g¥~ÑCÃÄqÃá²ÛÖÑ%ò:ø9­~}@Ì›jĞ>b)ËçÚ¥%úzÛ	»fã„d[µziºÛ =ÂZ×š¦ƒDÛ´q€ÌÙ‰.\µ¢%rO‰O	møÓÖ•V4´A§©øÏq¢İ½¯çW¨RO<e^KX¹a.-Ó9˜§\rôí—s°fğôYˆÔjA5šß%WÒeN0Ó+(ià€ï¶¤Â'ê±<¡j/“ÍŸÈ-æ1f_`İ²D ›&°Õ¹‰»îO±ğß™…i$×nö3ıûÒôP†&±
(¡Di‰µ+ —:>r5Í0¸ ‰¾E…<«`#`sRÜÇw,ÑÔµšüsE¾Î0&ÅZ„eÒì†ŸğDí,D@o_Û˜ø=m•tôcrŒüÛ@L7Èî¬ésRµ)ìœ­Nº¶>&Ú;e qı›k¿ø‹`jĞ/ÌnØã…*Â@•¦JEçá«æU=oÀœÈEàcœrxló4ßÓÔÃù,j1§oa2~?—ä¥FÜRN
ÿ:­ªY|#j]ÔiM’ñ×ñV„:lrĞ<h†¾öÊ”‚Ğ9ğ?›Õåªút™]óç±"

Øİi„wòB¾˜ +Êõô7·‹+p^ü¿Y¥Rh« }¿Ë
î×0üğ–XâG°†şAK*+©Ü%úZæräRu»_1&~—g™±ñCX;!Ø¯<Ğr2P?{Å8ö§ú*¨Ü‚L‰k"š¾Š–·H“Æ˜WWmÁáè'@n¤‘5‰ù6¾«abFÍÃ¹wĞˆ8$iPh™¸á¼
6*¢]]s*¬¨ D(e†•0Éøm¥yV
2KØŞ&Ñ¡S«§àÿ2êO]"ì®Ñ~¢Ô?Ê3¨¶˜ ÓÂô®‚A´/v‚Êªèæ<TƒÖíĞ$W9×~{í‰©û"‹ë)9LR ª"rï^Õ:vz<_qìŠÛùµ$ÊñwŠ4éüÁ¸ãgı£vú€ ôc«®ßalí»ıØcÏ!ó×árßF^E²Ä–g×øq$ŞêÛßJ™ìºgô­ºI‚Â‰Ä,üK3Y[¥qWV9ùü…š)±Êƒ†Ëûc¶UXyJÿ	Q:uö(Ëäí}$‘ŞJÚ&¤È®i­¶w9u£¶ÕøôÚôğ‘ÍVüöÆ9†y–Nb‚mŠK"Ëá0VKƒ²Ê1› Š)L¿4{Jc=£'lØ|ˆ¦ÀÙÛ‡—ßUh8<ú ¥B=oáRCT|ENHY™…Ó	êŞÉåc ºËó¾¢T«Ÿ(ÒCgsÅG­j,…’/]`¶j:&0aq°#ĞXy˜4Ğ§›åhMşóĞ@+­"G8å²H•5¶Dä-ğüè¿¸•¶³IoÄrß\œ1NŞ]ù9¥>êÍZ‰‘_ñ³çŠ1³?î	ÙoàÆV…?v^Èòº÷›ä:²¿)²S‹iÄü^·Û	¢|²'[¹÷\ºJô ;ÂFü¶$mßÙw0ÊP°c²h½Œ÷¾öôšŒíæ
fBy[ê­<®©Y–íh@²-ŞlêÏ¤7ÁÓöÑ)>Ê·¡$s˜ªaóø¸çqÜÊ•Ç!WïA¬?ÒxÛÆİŠÜvÏîm zx]×„è÷Xæ°éïİ[ùÈÆò$Ûì^ä‚‚1qt:7:û$F°áÌ½¤M¶9·½ü%':V|€'‹ºSÕj-.
ßù²»á.C4ÂXªAC“2Kóõ-•¤*_Òg +àƒ/!uœ¨çàWİx*ÆaEt­F:‚©xoÇ8'ÆÆ)O- ¥ïÏÿ×,’èˆkÚ}ÉË®ïaæµù*^ºş]÷­¼O ,È•H)¤‰¤ã¡ÌÊz^©E+dTxéü%•9_¹ œÆ¥ÔE¯×şJtøËË	Û¶øªcÄAıá“"Ö>ìz§ÈO o’ByC]ÀÜ‹URğÜ•şÓ–×£¦òƒ		õÜ[7XmËAÙ =3­øQ;¡4P‹Ù§æ-™§£ÁÏP!@Û qU20R7ÈšÁrŒüEíx3èÉÔÌ¶¬»aï¸ŞÕK«ææ%-ùË›Õ´[vWŠ»®»š²(X¾÷¿«5àø:P¼X‰Ï¬¸÷«¤Ô¨š(W	Jlh’¼êÙ$b9U{I‘=*é18¹	óózK¡oü½F~zÛ>ÙÉÏTßaŞÿÓêŞ&HŒñ+È†A­Šw“¨Ö'uäèµÓÈÌ+Kcé„5Î·°…ĞÑ˜ÏjÏVÃ½AO™h¾	ƒwT²›iŒ¤Fâ\ê½g Ó×õ%ó|¨D*8JZ rë¸ºèŒÛyİÃùšmï‰u=-ªL;©óÏ<w©ı\ó« éè}•b} Y¼ÑÅÙpCÔÊ›¬;èûÎÓğ¯	Öçáô&8|KÕSn²0ßÙàTŒĞÊıÛ“Lz—Õ²Lx9{¸ ß¦kÇÜDZ‹
*á¶¸ä[Ødù<!ˆ>ÿ]¤o‰¶ü©Óæ¦ùJ9ta½+Õ¾õRÆ¾„Qõa2krX9-KŞKö.x„µ‹üQ˜ÂL§Š’¼.5=Löª½Ç©öå»ÁŸ¬¥à÷s¹îpş\nÑXyqŞ²„£úöhğÏ*uÛ•º“ÔNÓ‡Ô#²±ôÕ­QÍt€émÏ´è)¨Ë6ĞK}5 :,d(ğæØ¦òÕª;qşÒWe'	W(0rÓ½’·Ïøkµ°ÏéS÷O&S%pFßg}‹8j>¼TÁ¬€Ê€›Ö¬ˆê~ 1w÷Mè˜»ß™¿­ğÅÅûß-Ã°³‚b;åeĞW#ª˜Fhş4Vná†H ší¯ÓÏ±¶Dcò'
Ğá…ô¡}VÃ±İ|CÙö°¢úü.ç¿J}ÈßRæ/,ŒğƒÉ}ríıtâÕÇ| NÓìº>uŞ|yenZKƒL›¢Ó6EÑs	Ù@ˆtÌ	A@Üù“- şN:œcÎ?—!ÃÕV¡ŞT‚…-Lí‹7k¤C#‹ãBĞræ0o€©Ò€i¡3v*-è±kÊJ¡¾;ÃaÏ@21
MDgÛzhÖ¹ä<€i¥5P,ˆŞ\Ó,ö”U²,·›sHF›ñ#=á¶¡½à’ÿ­fø·™AQ_¯É€[«[Øµ&FÚ¯‚Äè¯”ÿÑ='BUb¬
Í•ÖåóaÈUå›Ò,pZ?ªå±AÇu|‡¦°zoG>gë’!¡w–;.éKeñE&no#e1Ô)c!ÎÙD\syUO^`İô/+Ø!@eø˜T¥?÷Â„±·Šˆğoa©E4ÒfÁÛeËörä_Ô=‰ÂdK#äÊ+|¿}ém}½ºú¤¿µøÖph‰[í¸@>‚°õAÊ×®ÇßOÂ)wAwã=¶àß›¡õä™èÔÌlçaY*u7¾(ÿ`z7Cã “{¥D¾i$1vzs†¸UUÓ×ÛK••Hb	a§íğİ™Øcv'óÙhİZŒbkátƒ¯™\Ó©7á½|ºO¯½úÍ“Š|§e2ä¶&ÑiÊé ê*4_s6ªoIH+ƒ8“]ØòV¨~­8ôpU¢şä³:R![ç·i]îI©q"Å‘Œ,!„…ºŒçAg‚Â#¸4´°­£»ÀÔRĞ³˜íMÈnö¼P`»ÿIÿÁ›40˜ƒ›ûº[8¹™óÒjk~‚}¤àØã°$áTÕóÏ¶b­†î`/¬K­Ql7•ó­_?»—hˆ‰¨ŸŸÿ²]§L•Gº1‘¸FªÁá-×Àğ'¡]ÌDo	ÊñB¡§°.QÍÃúïì÷<?¯Z¬e6xÖ®»´ºxa»Íçibƒ÷‚| !y/Fé9Xg¡k¤6¥ÌÿLVI˜TH´¾-ÒÊßAŒéœlÖ±VªyédŸ£`]LÇ;E¸§áÃÃ4$³.Ã)¦ûù¼6¨f½2^ßyÔuIív8Ñx „ú¯”7ªÅdÂ^J‘ĞºÎyß5CèZ=*ŸSTÑÉæïÔ¼jş5ObÓ³¿õyÈİ‘D•ç¾ÅJÍSøös¨N€ä_Jª	Z0×š¢Ñz6å]y˜:%Œƒ
cºu7é XicAÈ“3sêÒíTVºCYë€¹ÒùÃ¸ç¥×€„·Ï¾fc>Pwóœ×ˆOqzÄĞ~/‚âp v]—ñ÷_äÉ¸$*$|°‡ZŞlPÕ†¢–4» ,‘…Ÿ‚´(V&"R˜Ö®jÆæœ}L“ú#_a!j#)ü‰|á|é®Ëÿ=ç5<SQÒéRSDiàspüÁ®õU§îB­¿rœ§Y›åk*)³9K>^lr:aøı‰ãòe|á H¹}÷ğˆåhß‚]o»œÌ«®Ü²´¢@c>§èÅÛĞKÅy÷èmNÉÄ5(õ"Ó²¦øˆú|¼XÚJ¤NsP3¡å®âŞ¼p¹vBßqÏŠıcæÖÃ(¿T­w±„…Ü?Rœ-ÆDS—]§(¨(Qğ FGW*¶$Ìw“»=ê¿Ò2›™ÑˆB¾a92:«¬Rgğàä!;y@ëTß[Ü—¼l\’‘f“3Ş’½¯±¸´××å’;Æõ×Òc3ÍÕVc˜V²Z{î¥¶1	»»Wıçÿ}Ã#2˜»~:êçÖSA>DÖx1CKW­°Ó8Qgj9d•
rA»ñj1óñe»éR(Ås&Uá4\€:bOËià¶¤=§ğÒZÄ»-ƒTòO§ÑGÜ³K¼Çø©=GÒ€ú`âÃÎ‘†öğ‚7Çº
QE3åN­"e‰
hLN^ëOvA‹²’¸@!­Å¥"é‹‡©B)ŸÇ» õÆt­ÿi°W¶§H´‰Ï^ëËÙêe}JÑc plÓ ‚ßàÜ”‘·Ë´ÖÒÀî¾÷3Nmšl»~”HÕ’›É'œÙeÌ7åœ&ÛRqÚÅÓb6¯§ Ïj×7ã5óøì]ºİ>òu'‰F×™Å))Ìs^Ü¦c´l~BzC±R½w¢Vf‹éóß[Ó‰ù*í ù÷ÉÇJ~Å¬r€¬Â¬æÉ™ej:énız]’ùt—Dåä]TÁ¬¥Å©¾RŞú60¼g?áâÜ.ùÖCŸöpOSašE¹*ÃÉI} ‡ÑfSè+¼ŸjªŞ¦Fıã˜Ü¦ ïZVnz²!À_Š+²c¯ŸB|¨!Ö!dbİ_=|¹7(ƒ²<H(¤ÿù€ÜÄúnãÅí32MÌÖºw‚&.úõıLpÜ=A+°ÚÚX—R9%¸íÄŒ2:|ZBÑ¯ÂŞ×\‡~2şôûç QK€Cu[úå½MWCòpÃoñy“NôßéRŸÈ£Áú}^ûÙ_shûÓeSZÛjâ^¶å~šù•Â¦ƒÚ*‹±Ç»h8¢…VMXÿÛŒMŸu’èÆÊz%†ÂàÎ/âØôÔŞıÓSf¾;£;Ëİ‹‘š°¾Ñ¥yŒ\Êq“÷nÕMßX¼-'Àƒ]“‡‰¦ãÅWVÃ1B½Ó± ±NB¦I´¨Ï¾ıµõ|°“ …Ó;wˆ‰˜}Qd#<.‰ª·üwãt>evüØ~Şú`ÈôŞ<†¯oÉ{ÚooÊÈ)ÿõ×o:XäMûè%î,3Mvt’Êã<ÂdÏ	²å_Á[ù¿A<ğ)PI„ı³ÆIk¥¨Å˜EV7#”æc5•èƒ¥í2+9€£ŸIa˜3áq¡yåKEA³¦R-ê‚"¤,„ı{Ï:Óæ¥TÆmÁäFïGÃGÕß
W'y–fŸYŒ…²ş<»mìq1Q¤D0fÅƒÂ§é×¥Ü·dXô/¼º(ºwƒ_[g–Â˜Ş#EGôi– ‡,gDÂáÅÑôBnjB;dJZ©6Ó(í´;Şÿx˜¸Ì¢ù‰ÏÕj„E‚N²çdMØÆ³ÀFòÏ¶R4I×„şÿü$4p¾>¼9V|ÒÒ$É©qkK%(Ş"C‰ÿ?ãŒÈ_òàüß9§¹+¾Qo )4dcEU•Ô;ı©2{‰“ÅĞÛLØ)r~BDíÌ0„¯hÙ5Ÿ;ù±à³ºŠ#÷.ÓDÏC6ğŞÅ¯n¹O¾ÎŞ=”eøgèÏ÷ñ{ÿr{or\Q¨e*‹Ô¿ oşA2‚š-æ±i…®Š"è£vÔUDœd­²‚Gâ$VPkşˆLÜğå0µÛòŞuš
î¥{Ë¸.	]> ›$eQmÄûĞy}L VèíÎ¨«z©]´C~)BF½ÖªM+`Â*÷’L^|ËT®k(E¤é¯Ñÿµ.‰†m¦½ÚÕMNœ™ïÜx#rPHÄÆ²L-³¢?o"‹ŞœŠt£½b.ŞWdßÛÑ·~†3s sNµµÂßæe ù8®l+ ÕÛ3Ó~Wša²îa®åˆ"#'KT":šíßÅ…–÷½­Å"µğ9Š'à¼ ÈØ¼èÊq&'uyÌëŠˆ_Â4•s'ûÚ{ß![`ñ²âé¡©Óµéæ©
¬é]y8MÀ…,Õr¿šõûQ+ksÀ¿—$—ĞıæòS'|nÛÇB¤ñbf ÿà¢Sd¢À‹xä‘6öc‚[4Æª–PÕ©H[nÍšY•Ì˜³yñ1Ú<ü€+é‹R!M<ĞÑ(w+œš‘í†m“Š_ÀÉ¦“)k/*—VÜÎA}-lsÎk•oÀ#ü Æ„¥d3ùÁÆ¼Ìs)¼~ÉÙn¶]İ>°Ê@ljf½ êu %Š— w‰o\ÑæÔ1Û70pÕo›¶4äz•è¹ÑíÿšŞ N ü«·`šSNê7İ¾Y;<9ËÒ¯»§Ø.…=4ŸLŒ»8ˆI\ÓMr«·CÒ·._D—Y²&6èOÔR°$FÈS°×Èõõ·>YR…Hó`§GÃ88İ”˜´9A–Pæ2*–¼FEÔZk×öÇä±*[³Dhnµ·‘ZDP¯ÙõÏv;{T†%Ña>=}Û‹VKC%‰¨#Ì\AiGåC¤tìdè:ëø…Ğ†ŞXR®{İº“Ø$ùá%İ¤>g+n¢Fº(hb=Ø…	@¼øÛE”3/³)D°Z¸¦€-ù­”ÕïvĞÔô“ÈĞæÁ­iùxîÑH~·Ä5ô9rt2‰k&Àc;PM-•ØNñ}å"ûê¦¬ÑjĞ¥.voÛ¥R/3‰Æ:sØG“uö<-s¾Pôõw"G}-àËøåŒJdx6
‡*œÏúa~Ñ‚‡ã¨]Ïø&‹´Ã+Æm1ÿ…ñ•W/~huŒÅ¬€]7ƒ­¢³¶L‹” ï¾8î¬Õd«8VCÓÙR$òšu •ùGÏ®Jê•Ê‡=‘döÖ¤$ù5	Ôº®èftÓ‚ip*¹XŠµÃêĞ­(®‰G$Û—hé‹ÂŸ3·m™¹^£öwk!‘j	}Íg0äö“Ì¹½'2Ì1Hõ¤‡_qŠtÛº£GFÔÚÊĞ Èı§÷ã§Oƒ¤ezŠUaM«‘fHÒ¨':’sş5U3˜âºSK‹sS`û SG}ÛÀs{wV¿Die•}3©ˆ°§>ÅcvLz_qË[Ó‚`õá¦¶aOÿ¾1ÈóÉ1z>£ØT]šÊûãÖÒ‹¡©
¦™ dptÈ|é¥ºtÕUéŞ«KÜÿçºÍÙ—‚â4Ñ]dÄN[‹¾cG²4{³Éh^ Üy2V …7#=“öq+Œ/ì± *í%!R%}¯ØÏ“„ŸÂ×§‹Ó¥ d¥“åÄí¬üã$ˆç\®‡cG?½2Ê-šFû‚ûªµB8í-4;ª$pâf¿”'Z1a™ïº}e7bĞ
ÄA6™o®œ%#·¤›ÊÉÓM=36€h ^ #Ù-~óà^>˜sxSRä!bW ®~vh8Ö®Èô@6PáŸ¹?%n=«Ê]X}´¾K„’,¬8ç„1°Æ>€Ç"	ÌLŒB&Æ ĞÕœç>Oî\½u>b ñ.D  VW¬ğ}­kyVı|‡Ğ]ÃLK¹d^e=ªõmºÄ(²Y=«ˆ¨V7ÿËÚ÷p¯ ûh,óH¢/ácÅ,Xìn8Jv•Jr¼gHÏ$ü_Peö.J™²_×Ï_şLøÇÇ;øcÙc¯‰[ŞRr8OˆQ¶mÄ™³Ú¨oÉW£—m@ıp=çj>i‡`¦SI6Í?ŒlÕÜ<ÈjdQFu!zæXjÙ%¸¿œÒÄQnµ¤¢²²1®~"§!âĞl„H¥”ŠÊxİô¼üg*d¨‰íØS:ë6Ø‡ÿ+şÄØÊÂb.t^Ùí5†³Lƒç
é‘¾‰$@zyËÑ˜RÒ“•04å\Í_:¶ÿu˜é,^ŞŞ½şŸü&.#Hxô°ìÂ×~U=;ÍÇd®GşÍM!¹˜ìÓdìc®½¿(şÌ]h±;Æ¡ªi•­ÇcyæäP`ç	YŸ'´²§§üùS‚ß™¯]hôQ–Ø+|c9±‚×®UTÎ¶BRnË@2¿†L¹?y\şF§èİ%²óÙöHFU/?¶¨ÙXÿ¥ñÁ˜èAbØME!/¹îêà ·ÉeìŸÚË¦…âû{Lp½&ºªWİö‹ƒ•±Rj»İI´T÷Ê<KıÒ>Ex5Q¯¾å~ZŠdıD—ûbíq¨Ñ°û“ÈƒU8åC!~›<Ë‹£HJõ¸ÉPÅ2’=Qq!}:éUûù†’zv¶‘/g!hké)Ê+/Â˜%£µ£Ü—ª–Ì5/«ßµ”˜NB°
¤@ƒ)ÆëÙ”ş-4øV56Ë	w–_(¸&%Æ#r„iS¤ì˜ÑÓ+ğô	•éZ½—ç²Ñ)Á#’çI©Bï J² øÉ@ÙzócsÒ©Î¿Zñq©şãB°rëÎt6n/h1Â]Oés/9Å¼$y	ùĞ¢}š­¡Ã¶órlñiê¥ğ$	˜9á½²móxh½7[ç¿È#$êPG`Öïbj‰û,}HÑ–i|CüeËÈ¾+J7~êYK¢QNÆDvÔÁä3–±ÄĞÑ-~à Õ1÷pÄtKS‹Üj˜Ü /ûB°6É`@Ü„up*’Ğ/ÛT›°”¾6Şä¬Ùƒ‘ŒÂ¥=e&5¯+g2»‰g{¶¤Ø;'-g“ºz-,¤t¯…­k•Ë8‹µ¾¨5xÛ=äP7ßaÕ±ÉP•¨rœb%¨rÎàDr¬5 IÁÎDn|ä`@ıŒÈ|ÓUµåâY9ÌşY|Ài”E©×ƒ›ƒ7$ê{èü>Ñ‘'Ûñ¡¾xƒ[° b›Aİàv(«ƒçq@!z[åİ¯ã›—`É‚ïIÆ*Bé ‡\ÒH]©Gµ´•ßÓ£Â;¸L{Ò»i™şÏÎóà@t !ä‡É3ÍâØèN¨İ’	uµN²Koü0ù³ÃŠ¢Ãí­2aNR+?uß™ĞŸ;™½ªlíì7ó¢_ÃËü“¤—9$ŒdŞC-)€ÀM²óµ’öÕ5g¶éR‡˜úáË6ñŸSYÕ˜ˆ€Ã¹˜‚ QUàQ«‹÷÷ãÁ¾±@G—J•aŠ™Rµ]1‘–9I:ÎHøG`£¸á™RZÛbÈ‚"ĞY€İLvX½÷&r&©¡eŸ1Xt¨ız Ô‡›VÓè?Tæ£¬åœO&p“òü[ Š>BªÀ&81„½8÷ÍMG•Ø/ŒGÈxZ°›×T‚AÃ¢T¸DÖŞ³şbíšô7ıÑPu®tz³Ã/è™<Õrx?à£ú¿ü:3”ª€KYô  \©£"2u!)ƒ¹]MÊïnBÖ!®üUU¿„T.nWİ·|*ŸUT£3ã¾Fë—‰ğ˜î2”ö¼9Gá‹3ş­úÆa'âZœİ	x‘ÄÖ=+ã²·6÷}0§“ø‹$²^#U¢éˆ<Ü0–S rHš4şôJÖ<9ÍÓö1lœÄ7ò?µgù3¥!9	qWM^}#8ô#$qßdî}–"H†`àwOócîÂ$È¶J;>æxpÁlµ˜ê=jLxL(õûôºE[»÷~¨*w×”Z,$¢™ßğËF —`	P74!Ò0ÖÄã(›ÖågÁ8a,dpPßĞR¶µ|ut}­Áaf«iÁ‰·'ĞfÇæ·"øÊ©Ù	ƒ²1BS1“="àŸdRíÁ¾_I–Õ åzî¦tÉQ P¿¹Á<+ÿÿÊ~±Ñm€[qôxxƒ „˜rò=õu¦láäÒÖ;o¡ù7‘±KKõ2=“á)  ß¨0’*´±ûÎ:l¸†H3j²BòN·ÄJJ3œVLtÇÑÅ$şÚ¶Í©¤AjbJé6½U.X.¾;G$ì¸•‚#}&WH#¹Ñ˜E À‰™±kÊ°¢šBEºÑ–P;HÑ&éİòë¯N&ß@Óüõ¦šù‘Z”½t3>x:®Ê¹×œrš2€ÅS>-°Ìt%-¬N©ËDİG”_4œÛ!UØÁ²cWÂ¾Ô©ab9Æ‡ÚS€Šn;%8¢Êê[XH™¿G™†e©hLBÒOâMj¹Ò¤ÕZCt( ?ô~jw÷b(ø[$¬¾JlP›+—ZÑÎØâd{rR Éâæù4¼Z¨q?_-”.¯\’à ¶å¾CÌø_©z;'%©.ÒóF€‡rËh#»û–DÔ¡…iö—}nk²~?·ú*TƒÅûy€(#¡<ªÄ¹<m!…ü\	˜ÂoÍY+H¿®»ù Â	2/F‹÷ÿª7p‡òö“öøîÛÿ›Xê™)ˆ>Ûvyaâ?Q2vnbÆŒƒ¾ÃHÄ’`\Mª‰æOµc£sKATƒ¤T*IËRpÉÔZ¿joé_$¿3.YX¬Lb÷a@	])b…ü{^Ms›û—±°øëşr@Ô.Ê_(øã“>Ş ¯q/j{ë¼.>Ûí1w¿‡jÃ”¿_Ğ¥ ]>`w¬É&Kd©òŞã1Q—š€˜öày!ã#GğSg˜¶Ìµ-‹‹M‡Ø‹:Şê&q0)s*’ğ!´†)SÄ÷	]	í‡~t5å…Fk¹âN@Åİ€Räã™(¬¨è**Tôà 3/RÖ^	şEŒ°ÉàŒ•ÔvÖoXaÿë <k~Wúß´¿-Ã•¶{ğ]şûDX€÷˜dP5læ…Ñªãn)3İròb~û|Ñ²]Œÿİ¹;[8Ôb`îQ¹!OnÃË½@RĞ/?•„©²ì}¯¥Š ¿R¡ êú–j}ó}mÄšæãu¹Ó°Bˆ7uê1ÎßPÄœqÕ0£«WwøF>ÔDì~ûı£|g	Åóñ5Œô¯Û_#¶¹š@;æO‡Cğ^¶R |Š‡wJHÒX9qÌµo«TAÙ°Š1~¶Iğmß’ ¤Õê$ÓH§«F>}ÂX€5»„n×>´nàôefÃã½Á˜`±¡Á• üFËŠW7°5çw&kÊkå¼p<TÒÎdN^8kÃ,3ÆÅºY#(š5o(qÿáQ]â#’…èÉ:5øs¯ì V÷ßíùH5ÿ+$ÛÀ#?JÖNe YÏ YRÜ7+GyGçê{XÇ4µĞêááQ9eo’{İjP£ãƒ¿:0Ş#§|ÉÁµ;{ú“ÜŒ~=öÂFoFöFTnÅÿ×ZtUÁI%L×qÏŞ@?k¤ÿ£¦	—²_Ÿ0fåAµğeÑ›…#›MÊÁQÇgŒ\f’uærìyiKD&}x =¶ı¥w ig§ƒdéD¼xn›ùòÓ‘‘ñ
+yæˆµJ„ùĞ”G~6 ƒºêÌÊtìôß Iµ½ØpiúbiŞd°ş²fn352¾Ú	 …ã?,!2Å‚)-Ó-[!Q)R§¢»Ôê™Åy”ZNãŸÇâõŸxè¿Y¨ı\vÖÍÈ7w?[_ÎØ
˜Æ­
'ãRM©‹â÷ôÊxFıæs9±#uTMt
â~·ƒc7^u70d¸6rÛïÌ-ç—ÛQJ¯–6b¸GƒMŠOÇ\8‘*sÏUV</<ÁGöbêÖå
ã©bß½»v.ı4D¥ÇL`%$÷2‚SÓ{WØW¬r#)š–´Q`?o¶V§ó8â«‡-WŒŸÔ‰éÓP}qâ% iÌë„Úx™«ú©7É°GYü
@{
h<TRŸ÷†¤"ÕûTğ‡nÔÔxRÏ[ØúÓCãß#‰ ÃìÇç	6 €Š´¼Ü4Xfœ© frºÚ^òDÓÕğŞuàN†[¦r¸ÄºrÉÜY¤æëş>§iŸ.Y¶3¨Ã]Ï4„–êAóÛíUòùM½__%Õ£}ÌäĞzc¼êo×Å%¾Ğ¹±æq~óÅ—U*»ƒ8×æZÆª*Jˆ«‘§œà:ÇÕê¢V˜àRPÆÉ->tÜç—LûĞ·#³nßLqu¹¹ü¬7NÏÁn‘ó«•#š¯¾~¤ÒÑöĞ`Ş¿†Då7‹B~r“k©É@ä×<^”ŸÂw€|äˆæÌò¾ÇÓ"À{“[R«°,JöØò¯V\<©êŞJyÎêóÍ;CãYÿª‰–ÕaY¼ìÓM ¶VÏ‘m\™àˆEÜ®®¥3ªo/û\‘0ŒY9@+9NÄ5 ÇëC ÎßŸşz•zAœ9I;¯³ø#¨.Ø²\İÎøınşó—æeÔ×àiÛgØÆOÔ“MûKëÜ&exÊíñEœ@¡¸É-‹ˆŸ ›¦£Ş¹•¥¥SœÓKú<ç2
Aèé{fê$J”§ŞÄIV9í«şd!]¾À|fçÑ]Pş*9N}m’*|«|òî{$”‹Y‚Ê#mïÂ—•ïa.hNŒÑMú[cvµ{ÇWHeò·y4¯;‰Ì!tÃî¶çk}úG„F„¼F6xıª vóTrñø­—“ç*zLï­òg7?`ñvaî¡íbñƒü~Wb—'ş2j'‹’tŞ]èl4´ŸÙ*¢Ø­³K^vŸşœLª÷”Ğ7ps^/ä‹´C~nxÕ¨*VÓ¶áûx}|ÎC1F¦ØœÜŞ—3Tc¥TQ¬½Ìjå t?Šğggä>[8§¾½©Ë±WÊ(?]ó¶	¡KXXš.-OYœİ¡	‚6ÛÊµö¬ÎğºÏËË§Šâ¾U!KÚ[“–^­9J ~I¶!µ,âè4*?[xT$’vwËáuEütœ…ç[¹@GÒÒ­,İ¼2(ÿ& „“ÿ®¸÷%nin~Á†jü±^
“»‘ æ]À˜æÖL0ºi!‡RµË©È‰•¸ÅG&ı±˜ï{ÿª£O(œpDVÕ€ÈõCáÄØxC¢ü¥eÎ)_órw™€j½›ïc5üÁÕâ7şí#‰m¸»tÒg ¥‘‹`6aE7R´ÿ•hCxí³ÿíŸºm8¸h=Œõ|Gwe¦ìÊ)ßQq^…ÒşÏ,WÇ-"	°fÏÕnTcø%ú$ùX!Íş¢Ÿ“ĞŒ@¶Ï±™Š>@^lÎ‚~N\[TgqÌOm>L†÷ÁKP5õø5ØºÛ"ÀË€Ÿ4JÆU¯8¿]c?_K'ÂÑtlâ •AM İú7!Ñ9Ôz>y¾hÙ“’»}¸`jÅtâ­ÅÉQ QçNñ¼gÎî{[©¢–IìÎ+ú ùFZ5²ep"«r±M1!ÈôEÙÆìL@€NÔ>dOÃ§Ù7‘éƒ gÙYÌ[¯79<#+Yy…çbÁ¸ÔÇØ{­W>;òr“ã5–Læ^
QÊz¶3¯ÃÁš¿‘”.Ã‘ÊŞÍf\œß_/†ËÉâšÈ©ÉÓnÉÖî}ŒsO ”põ‚]iÍ—ÁĞœ”7},—Ğ[':ví=Ùı$^×±×NA—3_üŞM2rWAÓ8×B-ÖäßÊŞò[ŸÆyK»ÖÔå­‹äÅïĞSë 6q²úd|*ÀGÖAm¦Ã•p%¡;ÁßkVè1Ñä«8sÖ BJOgóuo‘ÒI>×¼»‰‰•tëµÖÄè»_ËaTœğ¹«Ñl…í¹Šu¿#ïih}^SDXµJ“Õ}\÷v#ğµÚ+ç¼j\`‘XOÄ-wÒhh^ŞU`OóÔùb_uÍKı±>Âƒ£?TWuÜ|á‹Ş×Óî™§M”êÇ]Îy÷hÌ4¬wR’;jãd·}YE¹ÅÌä?êŒöÍ™ÍÀ)­ùì”/¾Ãw$¡|Œ`ğf±ƒ†½rc‰Œµupì”}DtbSèVVœUæo‰ã`rÇF$‹Ëw64³´äÑv·p±.µÏg€`”‘ÿo‡ß¢]÷ĞI#ÿªô<ÊÑ×u©=!½•ú¬Ésãî~ò„ñ·\”°2t‰‚I—Û]5Şâ™Ç²‹ë¦¹k(½fÆ/Y<|<‹Wûï‚ÊÖ¹>ÈÄ7ô§¬®ŞìQ;y°bÙıJ“¶ä—]åú€RÓîêx‘=¤Ğ­´zV«22 ıŠ˜ê8¸3w¿ÔñømD½	7?+7µ[Ù®:†IÂ ZÖ#J¯äSØ£,¾øUTö‘SêÛòÑhµ;’?Õìù„Ô(™µ3’§NVº‡Š¨Ïu¡§QOÚ¥‡¶
vğ'c«zªÌäò+¤{Ş(a)Û²ıW;ük¦Ñ¨†}¢ÿæf¡ÆÎŠICL|÷·7>î°ôn[<‰4¦ş­÷ˆ…,ïo½¾É:@(QÅ6‘óAì‹OXøX`%ş+“¨ËOÎzh’ÀšÒ;ì˜?âÛ>fÍ"¢73Ğ@b7^Ü§¥‡;º¶—_ëÛCülî#õF&EÉß!Íÿòª¤ áCZ/y5M6gåxÊÏLê•ğ¤’!Å–GZØïåĞœ{ŒUa*!48èF'{…÷“ŒE™Î)m5eK(Ç¾AÃßQ§‹¦øƒ­ŒÊ\¾â@Hg³·ìÜ£ò¼L¼Ïï7NˆWaÏsOS±Q,Àsï@†ÁyhÚ¡<¤ÃäN/^şÖ°«õ©$<MHğ—Àlå¾FAò™w¤åæ¶JÖZã0Lä¶ëá²
µFµ–myÁĞõt~‡TêBhU4&-OÓùîİòìçb–¬MZóußNØˆ-`èß’(õ©ŸehÔ²EDÿHè‘ì¡â­û‚äÖæöúLö0·0')é	ßî±8ÖKO]Û9©ğtXLGè ÌòK”ÑB¯øê¸äşÇ/Xa'®>'Y¯îs~i2âÿÙÆ<g6ë¶ÆÃ©SuçhÛ¤õyq‰ŞõËÎ-KœYXß¹ÎÅògå-ÍûäÿbMÆğ„¶˜^à‰Qaˆ|„ßĞÂÔ|“éÒ©œ2¿‡¹å‘KFø¹h‰q©ÁqË+œê{å7jıÑ<8V–ş¿«â¯§ §V÷‚Š"i<58¢{ğghQÄ`.ææ'‚ª	R$bè…®6Œ%/:¾ûEAŞrOv™©—/*«)”N…éÔ%´ÌÄƒĞQê5STHY]§‚ÃÍòÛˆÁíµ`KùÖdt¥Ä[2Ôvú÷¨KÁØ9Óv×^Ül¢G+‰GuYÇ
8ĞÇÑ#+æŠ€hå¯¦_	K·­&ØòÊA¡==ööØTE'-ÿàøIåSä^/Áq¨e6¹6kç¸7¼xP@!¡RL'R4"v(B uUîS·u}“¯ï4Kü‰x–Nä•Z&”5¿l}ä.Ğ;o±ê»oŠºVd®ãÿ˜Rªâ­±4Ød¶Öì¡>x®x[
nyÿsÁM"xz‡[fıŞĞÕíÉ¿A>;˜yBÇTS5ëuÜìÇ»7‹ó”3ôÈ@•é˜ÏTZ$„xĞ o²Q|wUøTày¦æÚf)H¾‡"	¤¥Zò–Ô+Â"áIå|$˜Öm]½âöïù›¡s´!‘¨Ò¤ºÆQ*•â¾©f5PõQ3Gi×òÙ¢4“xa±±Fá~åÓA ¦n˜¢¢î
‹³IIöZO¨k%™ò·³{4ÕmØü;âŒ[lÉ°j÷ñš™^q´dÊs›ÿ
†f’z¦ƒ9¬UU"ùß¯Î;—¥ë {™‚¿qg^ü<Y¯Î¨#Ì­Ñ…1-× >\Pà¸‘‹ÙıôÑê :WÂtƒ“y0	†ø×¶)¡Æ¦£EÀY†’Ö¦UòÊsB?=÷üüÑºF*‰*èl&
i³½ì$ç…¤’M	âˆe!à!i$í" iø£Ğ¼(ıt Fº
¬"Dµßµªw)01â)|æ¿„ı×ªãIçú0lëïÄY”+k^…½u9j­şLëõ¶(´ñ•o™o°zH4kòèÓàA¸8=îÉ3Ä(I9[¯zˆg·ÉÈXŠÁG•¸ÛcÃ‰ IJ;u ~‘Ãë»jQD¤hİ¹'ûÍÅË#‹	uí$ç X¿ÕH¡œB#ÿ•²‘&Ãâ"ıŸŠ„.ÿ†9Ïí]’ÿG`İpË„»ö›ÏV¸ º¼EµVu¤HØáYØ®VÈ¾©r×³”—Ÿ×œVÁyÕ24Q¶%yØvÀV°æ…–‡‘Û½ÏÙætİ­ô²u`±{Eè•Èà}á¾Ks!%ñJMß€‡ÍV¿ ‰'İû0'ëD˜¡ËŸÆêKo"§³2ïƒí $ÿóæIU¶Dó™«„EÉftJ–%óXŠé©#áÛO×öHçkAòõ[æÔÅõ‹ˆÆ çb…ÿØè€â}]ä…<Z½ÆF\PÔ,‰’'ŒF°+•ïñ@Ók©e€%û¨Å%‰–€wG³ë<Ğ`ûÒªÅßÇ½Õ#vİLH„ì•"ç ×Çß	á[ê}eáÈ-?Ş³’l~Õ
â{€£©V[%˜g¼ÕÅz}Çt5?¤¿³F¬7Mm]{9L;uaõ™˜g.SfWîÓsãš$‚íµ
ñÂ_Üò%ªâéœß)—ñ2‰Õ}…Î$"jš&ÕL{İÃÍé¡5F– ,ô_k¬é£LòIü@L²Ş
oİ ‡ø¢} ƒò²‹Âopt+ŸÈ©¾Lc«èøê*$¹ƒ‘Yñú<qv÷;g¾İf!;õ£À{Nf[
™:èXêÄ¤*ê¶j½
tª)š4Ô8˜ `²•{˜T€¡{€HÖ(’Œ¯Ëøsw;Ÿ‚í×›ˆ]²:Ùòñ¸oy›‘q®“¾d§­LæÈgça×pc²"bX{Çò€Tµ~ü,D·a‡[o[êv¾/&õªÔ.µôš¾à¢O{À“œŒ•jÚW»J›zi3k›ş%Xšd¢ÄËØÌ£U¸÷›ÜjFÄB¿\×§”UšnØŞqœü^ÿû~ÏšÄúñºÄÔX"ñ`¢…bHa?ı|,,$RÓ¹İ.çvT´WışõáÂ¶[¿]*â)¼‘r™ŒS?ËPy¥>Ñ`]§K‚Í£‰ÑóÖ´rù*¡À%ãüÿÛBÓ¥ÛÙ®jê Šô1•õäÎÅaÎ4çªxf‡^µ+åè¤0´v+Öı&°Œçº¢×å Î%7Y=¡¥x,¨É<¹f²Ğñ€×çé'] £'ŠùPğ;õ´3¹fú6;|ucÌšÙfIWßÂc.[1)ÔÒ;Gw–Ø¥×Ï4òøÊdcš?ä3‡nÓæ`Ô§Ïõ™‚ëÅ¡Tï+Xõ§İ§´7[¸}¢,$àŞ®à}:d„©éï·œöÀi±ğ«=¼°Qº®ÂÚNàb;Ú;ŸĞêPw9y¯Û‡ÙGµ†ğ3-=šºú¤T¯“Ç¡XÖ`nÆ¶èÃ„"2£TyÛ1VÎ†Ã¾ !»èJêıâŸÜœöùÃ}ôİß’Ø•+,Z^s§ˆ2Üy'„Â‘<P&=>ò÷I”fÏÄ²mõR¿æQÚ]eÄ[ø¶`âö²†ıˆéÈ’¬Gò_óØtÖƒtBf_!®$´cĞ%o}Cg~14G®ğ_>Ç’÷ÒY µnMœÔ¯3¯ìåxÍñâßÕÛ¯‡Ò³¦BO5&İIV¸½~.ó¿¾_¯c°TÀÈ+«¾´éÎç‹ò´é22»Â«J“–_¯ªD]] 
Ê”SYO8Ï Š·qX@ê	»± $!n¸Ÿd”*Ú—FVÈ¿ƒ©Gcà¢¹Jm·ÄKL·›
±0£Sÿ¬7Æ~]ƒ7ì‘®PµÎÃíO
Éİo*€Ušš½Z[£Oç'‚Q¨²6£¢ÊgÀ,ÈöRµ¥ÅÜìº¡`ZÛZb¢‘ü§äÈPª¯PÿæÄâen §>:ÎÂçøk½YT>‘1k¢Â½ß4ŸhÒå;@à Ìy7P®×³ê	zI±Îz
t\—Ùâ\è_/?Î8“ñÅ»ßõ§ ¥DT~Ü2R¢¹*Ì42aìşˆİ$6³T8Ñ£ŠíœĞ’%ESøáïùæJĞ–Í<Ü¸7E‡!òs_ Bõ„³¤wĞŞğ«¹£Àä,¡AÔm¸›Ø•†K8*m‹ÄS˜B|©š3èé…í»©2ÍË.ŒYªQ¢ºï%…±zˆÃ+·Ê…f¥„¦kÈÂÊûí.¼ëæ1ÀÚFñ†Êœ/_²	Q^_†šßüÆ4MïM.p—Hd­QÄ­?k!2…ÓŸ#lÑ­õºäÉw‹k¢æ÷¨ÖDt‡ ‡<$çO¼Ô„!bÚcuu…jç‘iM$QFt®ªÓaéçj4Ú ì–ì/TQ©è‘¢+c¦/Á8*„3.ML;>ş5Øğ&õZSc¤©«Wÿ¿~ÅP¢¡†êä‹gá	ŞÜÏ]C/0°P?i~æ¶:Ç¹2|U^FÎpø” ¢¯½­#t=ĞÖf.ñéŸÅ¥ô¾pD"z®h! )<RÄ
À³i{"?»eiî„azq†ÑâéT,eåó~o€‚î®;¶NbìÖıG“º|óû‘'qø›9 ú×¿>½xT¼¹a-Hòºogl[œvI•°‚da„·°eÔR-ªt];ùbcµ@‚S¶¾æ8›É* 	Z‘€rÿ»k1BpÄA·¢E”×ûåàhØ_ß1¢zÏ²ñ’byğtºŠ–Í¡i©&AÅ™Ğ$Ah[‡BÆo‰â‚úİ_Š§ª£IS*¼}U
êBÍşBK1¯nó"½):Û‚¼A¯5_i?%0/ÕäkçñÊ†º>Ö.gúE™CøWâSy4RŒèp‰Sú–2šò×ùvÿ9AF+r»/®ê‰‰´wá ¼Óöq-­—áDñú–É;Š“¨©ßE¶ì9V6¹êIM¿§Vïm×Ù¯7g¼jŒ²eéY<¼ÌN,çë€ır…‚³2X©Üª
#dø,r!•îÓñJü¹oĞ +¹Ã_®u+^ët¦ı#{•ê9V^ßV¶‹ŸNv… )±¿,ßÁŠ¾æ>¥5„¥ñ_E´Û›¼–/]İ$m¯Š3Ø­æ-=)·ÓG4Iú;Ù±Ty¬-š2ÑñKw¹÷¡ ïÌ7‡<@,ËÖŞe·[ô+³.?ĞŒ7ÿ±#ÉbfĞËqo‘‡AøãéîsrØÌqºŠ³<ïåá5ãÄè®„‘ZªH^xy/*lŠÓâƒîÍ<+¦P>¿^v.›øÜÓïÍ8ôÎhø?ê7ØÍ­,PgzØí'Ş
‡ —ß	¿gŒ„‘ÄSvWñqÌFå©ué€B\Z-ıìŞ­MÓë[6©2QÄ
¬ßOı¥qW-Ô›„ŒäuŠtQ¡œûr$tã™º}Š5ày}<aÿ´´:4”»ëVŠÛÈ8I€9^A\aË+‰qı0s×Ÿ¦ğ?¨¹™n|yìÁTı„n¢,i]Ò´ïB xĞB4ZkÕŞÙ¨ø;Öâ»Ñ€wğä›h•lJóV•&†'9ÚïõQd½$İ¸Ÿ?şVp§„´MÊı`MnØ´5€'¶Úãìõ¾4Zø°£')´ºÌ&ë×Ÿ°´š"9ˆ*“l;U´ÆĞ,†ëú3‚52aìáÖ‹°àEñ»¹Ã@ªÍÀ…+úã€÷òÁë–õêvÑJ~éh.Ğ½…VQ…Ø>.	ŠD¯Wi[ûÔ;Ÿîí›TóF~ÓZ*PS#h…ª^ÅÑÕ—İ³cÊ
wğùU‡ $™>nğ<‡P‰I2¾\¾ˆYÔEü§ß
‘$Ñk9(ÈO}=Èhá{‹£É9§¨™,Ïƒ‘a€÷ªÁ…eÙ´R5qˆ¸ÒëYj'òÁz¿Ò·Ì.ÉÇ2R|h[;MWXs‰ ÒJ%r%dW9‰I\eh!ç½i÷Nõ2|Uç®	•J"ÀƒÔ2æğ:NŞ•â®úÖ®Öb§ûÿ,8È‡65²
j÷à]V¼vè9#w cqöOO<qĞmE0ÃÉ>˜hŞ–öd¾K‡½Se1y¤®o›y'Éêq1Œª¾)Èâ
¦B”lw5ğğ¼ÓI<t…¤’¹ªÕ]èõåÿj±¸F‡¿(%ÂR ôÖèÔ7ğ (*5ªe½0ã	ÈÂƒ°!bâéçvÚSb.P‹¢Ã- FŠ¥kÇ‘.³–¦r{öxvšGğßzf¬jã*dV“)‹à_Öq“UêhW·m2Õbi|³j°ñ|Æñ+¤õñL[Êaø¶]7y[ŠvĞÑnÀÙ<©k9­wµ˜îĞÓ@Šãû£™°\Úÿ:=”"ªSy’í+))/ª·|]#†üˆ¨½lWX÷ÊZ *ÊÑ»\… Á»F	Ä´-_,f9Ÿ½
bû)Ó›VõJúzd"±M Ï?öÜ5©İ³9)ã¥¹;ñUxv¸Ö{È‡sŒòmô¿à*nİrŒoøkg…ùÃ¯
®İµ¼]©G¹ÁÆQİäéßsŠ¬Õ¡«çŞï
z-jğ«ØÌM|ÖÓÚ­üIÖ ‡'˜z¨É0mÌáO„ã3gÚÌ92èÀ‚izOÄò+àA>¡šğ6¬'ób„­ĞIT(Æş÷­$]®°,o€€ƒ&æxÕá×ÜK"ºr†q—¼SÓ ²KTÇÑ“![“ÈVJŒ/Ø‡÷
ı´J,!Eåùó!v<oC^è¸dõÛÿÜ“®·´óëc¼ğpëo!'L	®•Î/=iªf-]Å)sÏãÕ¸]°Tt˜˜ÏAÑ„îâÖwÕ°,¶‹º6ÕÜKYñæÌÃ°Ëá~ê^¬CŒÇ3h
…Óó³ø}ÛğW7o ˜†—”Èö…7j#eª¯ã¸mÂYû€Ax+ ¾ÉÏì…_ƒÿmĞ§~!-·1¢ñ²  ÅÊæå—å. ü € ÷ÏÏ±Ägû    YZ