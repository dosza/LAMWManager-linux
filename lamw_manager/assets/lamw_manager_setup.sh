#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3315917556"
MD5="0396c63261fc85f47297985398f06183"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22796"
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
	echo Date of packaging: Sat Jun 19 15:57:31 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿXÌ] ¼}•À1Dd]‡Á›PætİDñrôŞğÁÙ áûü)øò1ˆ&‹£rqÅ£‰”ÑĞë,&ó`š¥Şd‡.¦³şËÅSH™2RÃlæYâïsº«SÒD=
i~ÌÊniœ
ÓC›HŞçc.1Ş@	uåH>õlYµÈxŠš-”ô™ÆŸJIéÒuçp|Áğ¤[pÉRÂ¡®Äà(Ò¶†£Ş.s§ß¼€Â NË ¬‡¶â»óRİ•gËoWå[+Äš¶ş¨¥åß0Xé3À ó>KEÀãcJï&)¿•¬ï¬¨Í¨ö,á)ü“¢ßéd¢0s£"Í¼jÄ.İ=Q»™JÒ¸¶èçQKæ{ÙMkìáì€¦RãH9çìÌ²òv|¾?±Ô.Hïóí’W€Š÷0í—]ZH˜$ İgÂòŞúşëQí¸«É7˜íjÔÌ×…ó.:4{†ÖıälÄ¸ÀºtLió¨b^#ğ”l¤O¤Æ|˜#”B~£Œ!jsSFdoBt¼}ZPc¶g_àÄ]*<—s>fRbñ=çm›ğûR‘éâ º£ƒwíÆÂHÈGÓËı>ÊqqÜDPÔ›ğ‰j
¬väêOñoÀ’³W—{«Jéö=¬x¿¤öuFœ—×*;‡æ8÷e]ßBU¿¼ÕÇz{ãÊO;@ÃvÖı¾ŒÚ›çàµ.‰1ßç¡„­&nÑ±N¹œpĞ“Î-=[¦Ê„PÀ1ì½
vÑZÂÈU@CÉ¦Ñ,»îùo‘ön0ZÜ>!¼,z÷Òg»Ï
1ƒ<kn QöZíÅüCbÊXC<cBF_Ò¸bAØ†RUÏ¤
÷[Ôúéö;Ü4½ÓtAL4Ôš¦jçŸ‡Î·• š×®qY€\ÿ-+E]Ìà‹¸¾OÓÊës4t%ê¦(è.É¡'ÏÌû«D_/Şd‹øDæ1Ô>z0å9¢J–?ÓŒıì`A xªJ†>„w
eÎ&ÄiGhSäKCÖŸ!
³·0Ö4‹Î?ÀÎ„@sÌüV[ş­¬„;£ÏV­(&e×$Ğ>(N2=^´¤àÌÅxa[Üü_²’ªıWPÜ‰Öj¾İ“&1~yxF·éïÖûökœÏìÀ|ÁJ™rª*7A5£Çœˆ¥†<æpÆ'ZR¹ò»ø¼.Ä0Ôÿ&Á[ĞL£«boØ½±î_÷©êÀËxƒQ0zìŒŞ™bğà–I
ªíÃÙÔ,j p¿kñè#@DzÿÙVĞÎBäù¡ı!5šË¶ä«û‘úeşÈõÍã£}à:Á½eŸAH­‡~JEÅpC^(1`ßÜM–¤ HG?|÷“B]Å†°.>£!a¤•¢ƒámWğF*tÇuRkˆ7M°üOj‹·|À÷tªs9„«ø&õ*R°[£Ğ„w÷>XRâä§ñN…œbCä ğó s±…b<CNU©hÃÏÀÉB&¥ÕÆ|¬ÿk\úyÒ•¬—&4ÂÕêáº‰ífÕñÛÄ;ØÎ>ßò%şVMÖ¯qßãü<Ü©Î«Ûw”>h‹¦–'ï|ÄFÃ³ÚÈf§èŞöyUËœÙŞ°ÛÏyÏ¶É†ãKò xÄx¿tÎ¸-Ö°âÒmèÍì=C	ØşûŞâ¡4©c@ñ*"õ‡;ky¥‚Ÿl4‚OËK C®Ü˜ÂbESj±Ãçj~¸ìXüéBJÕş«±3X&Çt„JÆIÃj D ô4"!H^ÒšPæÂÛı†V_m8ƒÓ_"¶¾³˜†jò—ìâõˆ—Ó-ƒû“<ü-ıpõèÿ=š‰€E‡1ã¥"½öinè¿ñ&WŠ6¿áE]À—jÿS©‰?ÁI-wø_wJÎÅ+xy\K(‚¢P‡*ci¬Ã½ˆ~.Ù˜¿ûBäø¡ú)	u:
êÏœƒwUe°z×-c3|İâ_*tc 	¨ú€û´Á:£U–ü×iÒ¿­V¸qz`Âü?Yg ØP¢Búg,Œ:¶=1€iÕ¿êêÚkñÜŸ²™7Ba”e|y%3\Æ-scø	t¼d±ûOGsºo09}”ëÜWz“’œÿŸ/S?ÖªŒÛ:‚£5»U0”õ[/¨î$°‡ı—îs‚Ã­ æ4sóHB€™L˜…X“¡¥-4ñ‰ëm¡Gµ$ÙÍ_qräÀ¯Ğ9õ]¡ Ü‘Üé['¨â2%³~	z“ß7BV.#âÒ°£ïÑë/g¹[Ä¹6x85ªÍ¬Ó%®’dÔrÜòÇÚ¢\ÿ¹qvğGÙ–ÓjÏ|šÒ‡Nr°›•å«M¯ÚûÔV7ÏO4]Ò½†ŞàÓ‚N$È[l¥¢#¡zgb¬qYaÅÜR†cê²±iüg½VfF3KPgnX{£´ŠİMÉ¿}~G$NªFÉ7Î,è„öÔÁ7¸'£Š®Çc@r$òŞl­†'µÆã7mqìP>Eê{z4ïZ+}~³iscÎhüX î¬
ó;Œ†¾®G«º‚åãRÌˆ4PK,÷™éºş
oÀm/™4›Ööd\ôVyú‡8õ¹¼àp$¥‘¨¶¦¶ ]ùk=•¨JlgOİæ¶nj¤’âÇÚq¸Ç/5µ¦«\ÓOæŠåÎY¹^ø®ˆCÜd›š`B0œûNÛa	¼Bâ›:“š§\x  Ğ·šÍ5ågeJ±ûoæ¯;ğ¹û>“Ø\oYG_\ÎâªJÓBÎç°ÿ[Gà ¡fò.“¤Ñş1²KëM<gÑ‡l-ÑêÖ÷N·'¦ˆmÌWŒ´·&—léQ¬”Öœ'Ê>ıyÅù8ôÄ%ÈäœäDXtF‡„=£¡céöße-53R‰uŸ)it]Eoæº÷‹/uÓ"‚àË·Ñ(ô»ˆ Nu»mé;ôeõU‚û?S¥pË¨òQo3ë¡§¨9Ìßm€{”Éõù½ ;˜ú ”á¡I‡	QVÜŸhğ°YšA»ö^’âQ„u˜ôÒ·MŒ©Or °„‰ß6js]ÇF—ÏÈ·Â ëCs}B QK¶µ†8Mgµ“ÑÚFº‹©—³u¶Hqê
…/Ølú¸,Ğ<áÇ~vÙŠÛòögÎ¿×`%_V.^4]ª­ vËÑXd>/y‚*û§jbôX×XÉvøáè£(ïàVæ
†àF„Ë#O1–ÒdÖ£ÚéwÕWDÄ0-9%ÇB\f­çc—’^'9»5k+c‰Ö$¼-q:O…ŸÈûø­|Ojq‰ EŸPÍ„L·hİî^JNùÃéT¥U5fkÃ•§MÑÌ‰bf}úI¡Mnş‡!\‡áğ`6Ip	$HÂV±ÙkCèÿåÀªŞ€KT¤úšä*©i5–Dcñ9iíÖ¦zb,¦“Ö@øË&@Ù¥!
ğ¤dnMÛ±™êOĞ<as!}[³î˜Á ‘„Âù8kL5¤E_Õ, €kÉÏÍÅzz®ÏÍæğ)_œl [¨C3HÑ#be—[Õ\Æä(QòRŠ,Ïmõ¾â¥å´à‡şÒhu¦Q­ˆ¢ù6°ƒ£™—o: è‚ùÎ×‘„4^Ş!eXF°ë‹¸É’º;ì#s„—w$_PòïCÙ(%v¡Ót9îeÍsÖl…
ÏŒv±	§9H'*­-Œ½=¯4ÍÓK€Á™Œz J_Tâ$û]³'§B8&•ì@÷›ã"ŸÏÂL¿œqêÓÔÊeñ¦qY‹‰÷@h˜%å·~Î¸Õ78öìA
¢A}¬Tşãfm%R´ÈÁc›H.¸^…ºë6lÂG’+ò×7ÅOÙáaª¥°ÿ‚||a^Ò%è6£{ ñ‡ğÌô÷Äà×@ªÿÖ_’6ÌøàQ‘Dßzbx£uíªf±ÉW³ï¤•&°˜7j£ù9d'oqMad˜ŒÜgAòLX |”ts^;¿×ŠX„Üu«'û›¢³…,ÂN™&u‚Ğ?ÿÁÀ‡—İƒĞp\ïW¿túAùTë «5ZwMz*ÁÂßXãågéµç(–é˜€±›¯ÍôjbY‡xïîáH³ÛÊBÇÕÚRºR¿æÏl¨Úáú÷ŠB®0{|³K8Ãç/gĞïà{!Û²7(^‰Ê9½yêÓób ö¤ŞéÅ7{å.=Ä$Œ7ïğùA˜,VÌ‡zP`L]É'D,‰Ë Â¯B!Uo@L¶ÛÜG$ü6°‡ŒîáÒÙ½hAÎqŒ~şHâŞ_®§hû£le¬,Ûot¬|‡æ“âšÜö´ÍÓ?Á÷§ì’l¡ÑW oôí¸Œ/Òïg1½ĞYïüôGsÓß>À|†M÷>	¤y¦hpªlà”›ô4jd0ó»)|¾a5¸ªQFoĞ¿öÃ½gïöµºP1Æ,íş _¼iO§­X¨ô­E«¨Np¸EÆ›¬cÄò Ç„©H—¨3¼/ÎÈ	DOØ ?~.ò›#RÓ' ˆÈÆß;û_×İ;ß‹ß]V°ñ§–Á£V;!-V‡%‘$ï¢köOU8ïoªQÓ¦¦cÒ×;ÏJÌ˜A^™™W²»yÎÅB,Ç|Ó‘•è‚»<¢*å¹µØ5ÓñÖŞÀ›­À›uõcÎ‘ÒÍFEü”©‚½„dm36bë|¯-õÏŠ…«Ë˜N™Wº£¢@”›–7QGVğßšªDš	,A’W(Ññ
ÂXmêÃ;º|ÂŒÉ’©×¬¯¾Ş >†¬_ÖJU¡ƒ%²€ùÈÂËšá‰6VídWÀZ»cV±pùéI†åª¥í,º¨»%&·õ_ãÕÀ—}b˜HO›àÁ:­çÀ†×Ew GwÆùve\J€&úË{– ¼”9ò¹ŸÏ±–Ôd¶éØŸZjS†›ĞFÃU‰¨î¼äK¤ÒI{šN¢ÑíÍkN:É]Òıä®iá¦Æm•è›G˜álš¢¢.†©.ıF]£×E.<¯ü8uoúKqrwâÖŒe|(r §+É•Fzˆa‘yeŞ›Xn¢pÜ7—úğëï„}VQ²÷¹N¢ïÜ¬¿µ± êó•æó·8`ÏÌk°ä8àz2|ÓÓ;„½ylGUn6ˆ¯p›¹Sş0iµ«MÑ1!‹‚_N)ÉÇêã°¨?ôD†C3Óß·Fù(”-N¯§'Ù‹°7$½tÍ’Mt½‚¨0³¬ÿ–S½"kû…n]äY€ÈO3\R#Q^bEK|6Siº(ã. IB'„!µ$3˜¶ƒÉAÚT­
LôSùúİNC©»0äÍ@Fdr&Ÿğr	=µàÕ4ãî€ësõæƒÈ$Ñ— ,7ô“»í'N@àÒ´åF§±!ƒ
³gÃìå½Oÿk÷üU·’à¿:şm 7şĞ*´¾êJ+ÄÁØë7ÆÇÓ	Ñ1€ù;ãXî†’ÙÍQ¾¹üÅjš´GÜmÕÍLÄ¸_òX²ÁXCb3š£ùæ)ş9¿9óô3´¥sôƒïÂbğ´Ø€*¤Qd  ë{«Ä«Ü>)úrˆc3]ŠYŞ´V4ÉÑ´Y
àı2¶‹dg*Åé>“°rÏ Buûuí®íz:Ö{d>gÓÏÌb9 R˜+0à6y½Ùı2ãÄ¨[†|ı
9J}S¦#Ô¨«/ğ•êñ'‘]2¶UÜdºíçF]„¸ÌuÿLbkô!9K/èlÅ­@Ùë4†Â	'“kßµÂÄÉ¸¶-ÄPgy’½ò+ü7ë@ÖŒj®J‘¼ğÃİ’Ğ¡0ù:¶?ËùÏåÅŠ˜^¢ÇrûjP'å*­Å2›@÷îìãêW˜n¢ò3*\¶¼‘Su$Ú‡ùÔW½«Te°ÅÛRr4%3mÖ®¦=İe2Ş¡3/`î(9Ëò¾ºCsò‚:Uèâoİ½ ¶Cw'ŸÒÆô²0=Ïã†-5?uóš½c"¬åïNB©Â ¤­½ê–‡ëÂlÓ~”EœYÖÂÀUÄ}ùª¶¢oËXWß³G®càÙ®:9K˜¾:WîÜ£ ¬v-Ø^ qíI:›HN¨4uOÄıK~mHağ1Ï”|BõP…¾2wø4¶N&±K*E|×/ÛœVç3OQû’ô:HŒì·½Ğ<×#Šğï¬«£…¡\1BĞ´(Ï9¡Éû’›–•oiZƒ•'¹Ğ¯bàÓÎBÁPR²z»oÆ¾6=Ç¨Q÷F·÷fv­?ËÓërË˜·Û€Z!*ÎÙË™çu_ç—¡û’Êã¤‘ãN1Äq%€Ó²=OÃ~˜mŸ®Ç_dÃ|ÛYü"sx•S–ŒsqÍ*`¥j¿ïó?0eFcJAÀ·Æä|x÷J68À¿vıÒØ²ltæ¹Ñùn7#Ã&ÜfÑ!y–¬•Sô’ëàM+ä{"xû±7Ú’ç¬ÚEş›bƒZPáfÍºxUçı£Â®ıÅYì61~OPºó(ùßàêI üŒxq¦ylJ ÄXNš^jÖÍ·1­a3`ïgzİËç‚jßÉúŠDÍëLä»´]*¯ã€©—¾Jğ±ìtİÉ"CL:`„=¡†ª¢ÊS]QÙÜw}56.¤`ç´ÄêvµDeUŒ4x³YÊäÍ4IÑ÷P^}µíJGbìÍÿs’–Øİ1ñ—Pªë+û<æŞ¨·,téßd2½­ÜÊe›”B?¸½eæÏ»J7!¿¿¡ÛèÈ§¿«}c@YÌµ½3ÃòÚ{ šøeRU÷—ßNFî7):ª4ëküiÚ³Ò«äè»çç!â›
GÊG}J¡‹öHé /Cù…¯•³AEÿ~Q¬»wXï€ø,}uÂY3¤¥¿éı–ÊOpO2Gjµqªs’só¬Ş9ÚJÈ8üx¡xí,îû¨ ËÕ›¾t[¬KÙX+™/´†Éö•§l7Ú O¨ŸÌcÅŠIæy OG›ş°	Ş„m|‚øÉ¦ûŒ
g™¦ ¤©\+ÿ³aRÜ&	¹çÊY©¹XëxlİQ7ÉaÚ1ëˆúÒ^e™íİ.e•Êé0áSŞúÅF{ßà·{OZõ^!èê–"ò'ÿe‡Ë?û’l|jïW½xªã·HÙƒÌ–µÅZ9oì$]F»*©ÙÌ‰îÃF²Î»nêèÏB©íù?Ï…-¦7Í8<,‡ÀX’Jâ7j”-(,+jíK'A:g(Ö±Ob>r¥"ĞJ3Š8³aAŒ1k—ÉhüÄz¿&9û†æS¦6ñ²¯ç0ªÏö“›î-eŠã;ï`¬Q„ñBÅ	‚Å®{	7‘#J‹Mgù*z1Ryfü‚½,¾!ğœ´+Z°¢Àãƒ…”qòa¸€·Ã´Âšt–¦¶é5ˆIèòÏ!F3Â¿sïÍr÷Å6»]2‘­åÃ¥¯Îå6c*CU/™F›\èX:û¯Å>«WWão)ã8èHwf ½€2A8±GAWø&êGÈåk&#RcP‡tˆ×˜¸Ak¿;ˆÀ^¾¨#”çƒÛét_hD%%Sœ×'ƒş&†~•Ÿ%sô(˜wË0·»720KÆX
äÁ !yˆVå"`Öm¯î$€†ŞĞíâ'‰æÖü6^×JoA=Û ;9xko›)4Ğ–å@
¸‡yÃkXn’xêÖŞMæË¥¤…$6œ=Dÿ7Äşd±›=ŸcuÔsO+sŞm…'Ú¬¬ oÍàšÂén)U½³ôo×Øoƒà}öPÍìRİU(¨Y³†2J	\²ë­š ·Û´b8—S(”nıS'3ÖúÍãÅ²¯¿w(ŞæU12Æ-ãi¼Ô]MïÁ€á $U‰ç«2ßô ~…¡0 Ÿ¥ê1á#ôBÔt´f:!7?9õ;18ŒìÚ7\¸ à–ùªt- ±ëİàõ’9°é;/)Áë£5_d¤S	Îš¨(UİgÃêÕ˜M")há'êZ>§Áæ¢ä;×`¾\<tAz#,^Ä ‰¯O|s‘ô.ó€öƒºÑ,a#È±0Ó?‘7Ç\À¸ëOmŸñFƒ:ºN1_ôsJòÊş¬5Şğú»J{Ãæt…¨œ5—F L±4Q0aµÆá|ÄàZ™‡ò›ôCãyà„âäCx© î]¿Fº¶Œ½ÀCŒ`Øìƒíc™Re¯c•‰/èĞA¿lv”YÛ¸è|Áh'ÕôàX+ÆÃí|±/èœ¶†?ã—˜Æ7Äl™»Ñ†ŸŒ(œ~¬h_q72÷¬¸@|ø1üÇt	]ÈN—kË¥);FŸO®¶]æ£0ØT-½è§ºìèa Qé±ÛF²Ñ½!A7t'­l}È›fİ´"vößsÜ5çFiTÖìì®ú£n“;NKq´óG+Ş`òŒ©:»¢*rÌ M¥­å0€AÜ*'àK`‘¯ÈÊE°Fa•:™´jø^Dä…x¹±EN±”Bßo‰;n¹‘ÑidZÌ)7*ş“ÕÈ‘^÷qï°$#esÏGv«ÏÿOGz] ƒ…ç9_¡Ì†ìï—wåóöUP7X+–_ËÀßãL¥÷$Çµbá™€3g %oE¼ÇKÑópÑ%è!è‘€¥µm‚÷ÕUd9ú}øãé¶x¿ôáÂA÷ ÌÉlá‘ŞŞ¼ì½‚dw}¦ÿÎŒ|A¤ñıÊa+9*7´¯	c©e–Ä£½º„¦½!¥¢÷ƒlcs}¸o½Äydk¡OŠzqšìX(Å[¨ç©në•°À"À¸3Õ½€øÔKÛª”kÉöãpØÇz¬$= -9Í˜c(ÍPm!7 ı¯¾¶ª<QWl ¯0²Ùí~Îåcc“–~vâ¯±¯×”­Ô¼˜’yªª%¼½@ı UÓ}üËF– £ÂË†¡+“GÌÀİ¡ÿjİ«-ğ9 Ü;lìÛÈ^NØåK*PØïÕ±OI;¸b²fÜ¦ôıK4;ı¾hfu†$Ñ=oÀjJE˜üôMA"­*ŸR†Tù³õü˜ñu˜v×Ã@û^ÑKb`­ÅòŠ„Œ¹ÈeB¢\´d¤èxè,E¬8\ê°-¦Uí`{´ˆ^ÉêÍĞT%şÏæD˜™Ÿ}Öú¸8\<£¹‹Ej;<ù$}ÌÓ‚5ˆñàõ²_*÷bCş‰ÕÀ‹­ÆK2fu ëã‰¥& Hâ›ß
„ØÇş7õÔ]<eçŒÀÂ¢tW®Òj®‡gôÊÕéMém.¾¯Kßy.şÅ§(U6÷;Ò_pöâ.¥‘ãßÜuÀš¹Ë6bVĞk†õ¸Û%#œç»qê.‚#Á= #óXíàeíŒöå¿+5´/¨§QÛKëyªá[^Ùølj~µ#íë•. Z¿n¬5»¾rš8höhîAİöhˆ'W<R?¿ƒç€,ûÒ{œ»¹ùÑQÒ¶Ÿë ï”#-²LÁTBj‘	s]ø<DµÍ²^VğbÓñÇ‰leMhX+•w,>SVÚ$Th
ÛO¬ïşËŞåP¦"Ù¹«âçwûºÖG5æ°„ÿOé-£˜Ò¡Åi5&@7$û:ã¿‘ÌÙ'a³½]Ïö¦ú@dÇtƒ1ç"Îïa§º‚rl{Ìk•ªÜÆª_‰¿W"z<#G-äĞ¾‡Öo¼ıãí¸ÀäZ3ù=³Ù§×pìø… ÓdI\™+…Ü}×+S~Ğ~_ŸCOà©5`ùä!‡–´8—²œÛ`P™Ò£úL(šÛÆ¢3˜95Ü¨ÄÖ5…Ï™ãrv_œ#¼ßÓ‰áUg¢p-N*7`[©™`ùÒY½°d¼‰ŒÑoÎGŸc]Uqáx‘?)7ÉØZÓq‰Şbâ³‚Ó•mSòù;ş´r8]ª¨fõá`9 ™<ü@ˆ~Ø²nT½iËlï&­ƒqpŠBülÖOd{õºóºB±İ#şü¥„€,ôîßÅ55éP2‡Yâé=_L‡ÎÌĞO¾NåİÎª;RÒÇ«€*J:Ó3µ¨G½ìûïÄ`›?ÜŠ>Ğ`|Mf¬áÒû¢í¸»Úár[Wª¢¢q	•qk‚SXÊyu(ŠS…àw©é•fÁÅ6ŠxˆÇİ|Uáî¤ .ïm²£õU°Nì5£è6?+I´™œÊ²Úvg¼C´Ã›=!¨Ï‘íëO¡õ=ß Œt`² Ğá„—ÆáØ¯bh6w0á!UêlÁşp®<'õ!Œ«<TÓk–[ÅÀñÜ¥	Ş“¬ÌĞ[ÅÑ éc@ÄX¤ÖD3ÀáìªÚ†6ÿç¦;³Nˆ6M$ôeQcV û“½Ù7ş<~‡:bik¹ÃG'ë 6-‹Õ#p„èB¸ˆÎ—\3úDn@|¿‰è§t“)µF«,©Hs*‹îAÄæ—<Ú-:=ÙU7ş·&\_X˜joœºhê5¤çK˜cï<‹¼€–+R©fË ·ÆMô‘‘v€ßL2#¬ñ"û*a¶áŒ%¤‹Ë±V••(™x¸NéØÎ½ ¯nAÏ‚±Ş\·û0ÚÕŒº§…JX·“3uÅ`]§J‘j‘Ï°ËJl‚–¼É\Ğ½bA¼âûA?"T^C{Œª‹ú<Nˆ_ª­lÂ©½İM×8uè¦à“ÚÈµoL2×„xc”¾L©e¦8ˆÃÕtn?uÉyÛO%¿/Ååæt¸1ëõÖ®ëÛúışöÚ9lçõíœ¨˜ÆqnZî|fÎFÙğ2z.?w‚ß‡U¶Úì«¿ÛdW6®buü‡C%2˜ÔN'fBêLgã±³µÒYæÃ”á°aqüê•ät´Ozcäo<¸ìe_ì‚<+F·™³ÉN˜ÙgÁ–ÉÚëâ˜‹æ×¨§Ğ&kãkBWD(µw›áÆ3t5$jí³¢™b¦4î§okšó]¶Î`vïòÀÁ™{3>ORfGéAòÀ`dãFõ>½UˆÄÎL÷#ÿWB`V^AL,`ÿ×Ì»©V•lO”ÒGØ|áÃ·f[5šã1qÀ’H%@©&½ghò)t–E‹F;§*í«T²e:NÅ‡7±°¶N…VG¢ï_ÁR_ °ÌLAôjæ_Ñh«	p|6ÅÉß´õÚ¦§^ãnWYãÜÑS }”¥[¹Œ³F;Bèº0Ÿrê5©‰kU²¬º“¥wMœª/ÿA$ìlZ¨r‘Mµ	ñ';Ãñ¬±:£T„ŸáQêÈ6‰¯·4ùúííëW´Çñİ¯]_ì.fŒğgñ HP9
sĞzÏq7reË’²mOø-ÎF&èÚ"‹’ŠÑ»eğŸ¬_,t|²ó52R	Oô2éª¸;òUoRFÀá’ZÉòb˜¦oR¬Ğ+º}œÔıeaÜqŠØl¶aĞínÚgrÈcjÿÃié7#İ7fyâ4Œ ¼0!Q{
äd9ØöëÁÅ&˜²´,£6…GÕ´Ã•dví¶¼H!6U!
Ğ‹œvh×ş>$PÑZ‘²˜[©ª¬‰™lg­9ÒßÖ)ça˜ÌoP¾9}¹VºÜğ. bf­Îî×ç…Ö)ÌB<œŒ(5(óä–2qÏ›‘MÿóíëßVa…;Ã¼>ƒ¥éL–û•µ0õ“˜4ÇÓêeãÅ{ª&„m‘¡TÔN?\‘áf¿=ö&[àÌê>
8Š¢ÃÜ/oÊ97b+÷£_Õ_êôgì…a	ã)lô/`Æ¯Uü\óî]˜¬}Aˆô®T\4İ]ËÉİ\3«´·AÀ³›Éğ#‡mOÙD8Q-q4ÏØ§¾¨'ü4ä†¤1ùzĞĞæõ*Ù=X~û¢Q0-X+ôxñf¥m)Úùä¤"¢ƒÑJü¯Q¢ØYhúwôêz`¶zqjp•™K²å!sOTëdÜ5wh…°3WÚ#ÚØúWö-‘âºï0ÉĞ¤Ë–gëŠÁõq|h\‰aß¤¹I·­ªeMa^›:àËë3G¨pHK©a®¤Y?
‘¬hOMŠ‘<»Y‹Ûaú/*HvÍ"Ø®ÁU?¨¶ÿi˜µğ•Ë©ÌõéÖEÑÿ\Õw„Élsj<h•ÅÒST ) k Q>è+~`”åw©ÚÊ“YÓÍşİêù	í2°]ãü•İ:Üñşè"îa¾„:—:î†Ş¸yô‚q¯n–òıntÜ7ó;Â l>c“¶x}_B	_‡®l-¾®!Ü‹R~t‹b‹é÷€*A ÿ
¥CWiÖ>‰²öo²}HØ~gædgß;PÇõajÑd|7­Gî¬Ípq)Öêj|¸µq5è%ı7>'ì¼Õ…ymıéeÙ9â?Ÿ©CÜ7Ñ=5Æ.w¤,l·›Énƒò—‡ı·—ì.(¡LPØ´/kŞL>ÚÔÅ¾5Å–¢¥A‡“ÔšL _9w6¢òOò1œÄÂZ¬D¿¥Ê|ßÿ?d¢æÄC‹‘ğ¼—Ï$g‚}úz«¤ íV³q|yäU6õ=#/ûÀÉß#JerT¶luNX7óÆë!-+jñàòçš{Ë·ÔñçÛg9?rï*Ÿ dÁ[hÊnı6q1èUÿ¢IÌ\SØ+ N¾„»¾=¯$$²ÒçJz6'·é0iK¢H<İP;_¥Íq:QòQsñr7ÕV€G(dÌİ_"2- ¢“#'ãBúòËª©İ]Lf÷¢³Z<‹ˆ>ÀàÏghô¡÷(MÜÌ=1ÙfN¶î!“Ø¸v¿4Ó©Èåúmå¼³ó”5”Àÿ†´ÉL¦—]U8„êÃË??À!ã<Ò~¬Ï¤D”ÓHIQĞŒ¾R³¹§»èO	0we0«c¸4³¤[Òwuº“AíJ…ÛŠ™â27où‘.øë©Ú˜[¿J:jö+“{8`_Âü‡İ T¸ØBåOÿƒˆ_zH”/çÔÈXVngğ@êPŠ8•,dÎ?Ôfşs6		ô<{òæÖTŠ(O¹H*¥¾Å|¦Šò™Èno6`ÀšË~à2O,UÉÄ„hôµÚ };—„ ?¶ Ÿî5w
^õ‰i>Ô‹|¼Jï`“Æ§ë"(fŠ€dg’›$£©‰Â4$\æ€íÈÄkÉµrmù-Q)<Ü`UÛx‡‹>®şË.¢/;UİhYZš»$ààZ¶vr](Zí‹@¡z›ÏÔpg æ²šîp™ğ?øæ'ÙtåĞ@­.ø&NoØ™QÔ¦‹ØÇÓ€ÆÛr§@;ër[˜·ñŒ’J{WĞÆLSäyj¬‹®ƒ5ozgßŠ]¯â´….ñdGGèQ¯¢KV(
wã#i‡QEÂU]‚8î3sĞhÍjzèŠ*ª²u[wyJPâÇ º»Û’“ÀÉ÷ğ¸—¬éÙAÕ‰ŞâaZ¬Mˆ«ÁlğË«íÖO¸ù‰ÑÔ Éx¤’ÍHd3-`‚²%¸D3xK»UO Jªr´ÈÏÁıGú¦[C3‘Å{ë6ğ‰	`…ç&¡F· xé/‡‰‚°È2·­ƒ&Ìo¾`Eß¸ Ú¦OPmD˜6?g4-åë8p:ïş+ÛOÙ[‹ 4íUM~é"@Ê—õ3»••€’&:µ+¶×˜GîÜ	Sn0d)3FÈr˜ÉÁt¸v IS’k£œÔ&÷ºÌâˆ=Îô
ŒUğOõêJ'ïoáìˆ¼ñmê1òçoKG½ra™çæ‰…ÔØ&'í¦œvr1uñ¹JQ	 Ş§‰: "}:36xp`
œEva÷FU%YEqGbEËí[XvË3[@3-©N2¨eRÉÙ*Ê˜é´k,ù±.izÉ*ª73öÓ ^DJûÇQ!½À818QR£uqb—¾ÁÕ­ã$Ü¼Dº4I|äxÏ9‚úLrS+äL+U'ùqOÍlù
VÿŞ9 ôæêkºM«n™{\õ¯=vĞ½#‰|k<Œj™â¯YXöSÏV»EõşUD%Œn½2!¸£½ã~.åŒòr¨kmÖm±äOÙ›{„ø{DEì «§ğR|È5[xu jîZVÜË¾šf’X¨ k‹û¿¢ó»ŒÛ»©iÁˆ³Œh™Üà,Z–âô_S^Z«]}¦"¨“¬Ó°J;ã¿[¯òXË Š<ÿ‘•A«tË£¿ašæ—ÕƒùòØ¸u[ísH>>Ócì2†+{İ–£–&ÛOÌIxà=vìiY/Ymš`Î‹yoÌ¿øC8T‹gŞóS }è§×¬ôÊv‰†‰!øšaÆş)ë$ı›Ì¤VSm‘ÄÏ² ¡†ñ”fñ›N„Ÿ¶tEW aiİâ÷‹Õ]*7å¨—ï™›,»†ŠaçZ+1ã½{“,Áœ¸ºì/ka3ïæ`©·°¼f%øa½ZE>™"ôk–£H¨8*Íú­˜Ù¸†“ö¬´ÖİO¬<€òVİ³™ğôz…Nv’Dé`ók‰(uEG”âÃÚ2}"U[FÎÛÃ£§±Áã9»èUH·G’õcOjÕÓ2¿,dş7'H»;659ŒLHZdC¼<Õg ‹»Ë_Ñ3jqh¬š
ÍYÑuvµò®Oéæn×µë˜×ûxŞ ä'Ş‹÷(—£j›‰Ëi¥’—$4„O‹˜‡§@€©o–œü’Ë9a4‡Å({×'@¤²gz3€Ô5i«©…÷	émÏìIˆ~Ööïª¬y¸;¦|rxÏ%ãT+‘wª˜Mí –=%!Èƒ¹	Iê
+ìX¶³n_ûxù& Ì]Ğ{ÈWn)Gµ–ôr%yX¸rØ=1É=–³‹”òŸºšöê•!ë7ö«¤ş¸_Á°µ3y“™Ù.¨
ó9¹Ø)g´/,`àcëÃvà_È©ÍÂ-%2ğHİO,®R¬ÀJdwìDóhŠ=²à	Ÿ1ÁÕäÉŠ†‘´˜º2càCpxßºìûóyÇ”²	X>!M4f`·ÆTBÍ»×–¤ËÆŞÄÅ¥íş ÌÀš .àO436_êé½ìÔ÷Ëwá Hçd€ø±»›”¬ ÜÉ`+şï3?Â))ú«Ï/jŠ“LT=ÿn®g½AÆK#´ø”ßå°nB’JÇUN(eöQ&T–ï®š„Fß/õ%ù¶É^â'jp?F™Òˆ+"o5
	.ÃÎx`gÆZ'ª$*ÅĞ	­pïîB‹
@ºô£YØ§_ou’›â¨RfP?éÓK±÷¯“M9ä²ÕÌ`ÅUTÒš0HË2HğrrŠ°Q±ÕVóÚµ""KíË|³HzÀOF79vİmEwĞ-
Û‹%RùE[®IÊô?İAºS+²¶bµÎ8Ó¡İ'‹$^tˆöt$¿È+[~¸¸ªÅÌjmr_è.äH^=ÅŸÿ*­3wmUæb8ç|wıqó&…I‘äô@qo{eE¾±ğ5¡€­°ÀŸéZ	›:N×WqMÓ/´’öÁÑı)£ÔŞ;µeêïÎy4L^ZnÙ?íPı’#}éÓıöu’0øE%&/Øš\$ÚZšğ1óÃŸ,é¤í2­#pshí‚Ì éà TÁ-‰ĞeğE&élp²‡“WÛ|øä‚b…÷–a~ì'@#âU{uÇÂ©SË
¡}Jãš®~ş€LBSİNµvÒ__Ìüö<P¿û1‹
wºmcsS_NJ{œ_ß!pºa×iÓòQÕ´­5¡ÜsæCÀ9ç­½«aÒ¡Ó‰Ô’7 ü6®Ï?2v®KP¬8gŒDjˆxÕˆ¦•Ó½
k°oj®—GcÉ	Øæ(¥×aFt¨&‘Ã~æ“Y%‹'}î¤0ÕhµØC^"ò[æÃÒ+>H>Êù5×GCŒzò9Ã¿.óÛğBlí€åœ3ª æ/ÎVN–i^¤KS>
sÉİWÓM s>±J' ?—ıZéåôN¯ôC@X¬M!…§×oIE.îñ»ÆŒ3Ş€YFvÅ©S—q—&Çètä;^r@LGeŠ†\¼+‘éÉx†èqz-$–3ÉÚK¨Líuí„Êã“É õ!â"”€•äùiw›Y3¶2¶—Ú©qíÏ^ËıÈØPĞBˆÁ8(”ı6ÕÇ|,Q‡Å—Æ÷H:dª²®#w‚  }†6@²®¨°=wPVeÓg˜cØ6O]t)Ä}¹+U†ìæjìy‚õ“‹¶3cyyÀ¹õ™	à7öù[Eh	Ïû.X—¦øí>!A¯‚«£WäªéÑtŞß²=òfºx€T’G†$eÏá
Ì{ˆâï€Ë$Ô„ñIaÇ™i®v‰*(Ä-åB!æ·'ß˜·Úô­¸!×(¹Ù1Î­ƒ¥áÆAGgF)¸]n™Q‹yÿ+S’_àéD´~¾moÁùı„HûX-³KPCG©Zöà‚#ÏÁ¿#ÓNPX™b½«#hDú¶.Hîn­£4×¶?HBAáwÀJ ©…Jö>?ÅŞJùa÷bq´«zıæ~fØ6—(víªcE‡ÚtpıdX–šu@íºÖŸñÙL$nÉU‚	IÍïmª°\,Ç1Âl3I”dZ…YüêÒ?îRÆÕ}ãT˜í:³İ·.I‹ñEÆvÂ+åB<á7¦¯]ÿİ¾¸ÓànÌCÈâKpº·ÓN€¯Óñ¬ÏJ‡}‘^?ƒãŞÙ:¯¿(UwxÆ­lÖì®”¥	×efjäçŒ¿ OjïßÀ½åãMšÄÄìÉ+WJ° TÄ¡XtÍZ×§šFİ`²š‹RhGİ¬‰.\a(î%3Q^µ²×JòPm¸Nş0¹§Íy§“Z'2Üº3µº2Qub•Nû|Ñ	NE‡(mF+úerb]ë ˜=MSHÖ».’Êfæœ­–ß±1'^¤,-ó"Ic<“Ãz~¥Â€6C	>HïÚúˆz<7_¥š9½ş¶"È¡åÔ$kü“ºêv.Û¸!Uâ‚Üb5SPğ¥"¼R™÷ÔTéšO“‹-C R‹U0¬"x2~ú«öS¯[íéÁ>ˆ’œ™K¬(¶çáÀã@C§}>AA•HşœÁØ…__vÈºA<bÍ|î“r¼‹K‡š½äŸ¯65.CÍ¼ªÔdµhñs¡$seÓ®P”3FÎ/–e£R¦¤0]kVÎæö–PõàˆYêÁÒüÔKCd ï>òÃo“¸IŸ[âàlŸs¾‡¹Ø¤Æ1-‡B¢ƒ§,­ÏË'æ¹	ÀÓä½¾ºiÄ=;nŒÅ$¶o5:æİ¢ÑÏ–Cfy‚,9æm"½{ø÷Šõ‚MŞEñı(Úp•Ä?j		kw¸'6/Á)1ñ†Î5 à3d^”ØÇr"ÚV Ñ ¹¨`dõ?/8êBZk1ı<uf”ºöqk‡ƒes`¥~É]!Ò3
6ªùw^ãuX½.…`2µµ ëoÛ]D™F±UÌ¤J€Î	 `ÉúØ¡èÂ_eŸD'-À“Ù¶?"Ö8&)l±ƒ†”Î*;Î¯7¹mW4³Ã¤¿4‘z´“Û!¡Ü›æIøñò#Weº‹S)ø.ÇîëÚÜ¶‰·œç÷$Q3Ë\šôHì±E–i®(¼l+TĞÔêı
¹÷Ğ¦eªüÍ®²õıÍ¾û J‘wŞøvi6ÏógOgIrÍˆ†™?GuŒ	qüğwW
?ï«Ü’¢j…·º³¼Øj|êŞ š–šúléfx·¶Cwg>‘Ï ?öÁÔ0pÓÌjĞ¤rIy¿…zÌ»4¦#’ÿm0?•WÂOt:¬Æo^î:ö[kfcœ·«1TZ@ÅŠS;ç¢ëˆÙŸ»ÂÑšÚØq„öÍê½ ø÷Ø;)…"Í÷K•èıë\CßğM¼É¿W˜$m-™q–•4Ø—š$ …O¹$ïø8ÕÌ57”‡Eu­j9Ğq¿•
Lèğ—:¯Ï‹g2/€òØ5a $M9&ë5VÏÒW¸s}5Ú]Ğ{}öB_Sâ®~ÌÆªè0Úú©ØòÖ|²¹.®½ë¡]f–ÑóàĞJFË:ÆWø(;U¾2T¡hÔgÿy\*ï»³©mK uÖ¤Qõ†ĞZ§Š¼â¶.LˆºZ4^okPWcµ0(İ(wªDH‹”LÂß#Úé` †£Ì‰I	¤I²zÀ0´	ãÁøŞù:eíQƒV^²_ø&‘b~á$f°ç˜ŠÑY«N‚¦QIÃ»~+Î±H›ş
ülI( <.<LÈ*0bGĞ"±ãÙï¡¦ AÒĞt#;eş¯ÙßÑ`?{`©çTÁ”-Ó»…¹»“"ˆ) äuŞñ•#é)o
V1*IGš%
üCX`İĞ4Æo˜·tÖ£ˆ“ë¶i‹ÓSRÎ¬‘‡¨báûøÓ¥«M·Ã)L‰ ôI]Ìg¾«^ƒ(«Í<œY÷Fc¼á~œß°ˆ5¦á·,³Ÿ¥Ê)Æ†7ˆèc›¹$§ÂG	aªû·+ÁÓ=™<éÀ6Ë1ŞØaÆ9Šgfº‹óºšã°˜±¬Å;¿>ê[æ§6•ôÙOz CÎJÌµk—hƒÿ¿Í™òİ€(g–yIòq@ÇµiVŒOzQçÇwt‡ä«•ù6 InûëWtÏÈ¤Xj% ³Z–»h*Øó¾M·¡ ®Û:ÚEã•:g=ñ<ÃWØG¹ğ7fËİšòè!'ñUŸIµå–E7õŞ:¨É¦Â„h©}
<SòmÌ‘¿§$n,e‹ôÚ|j‰ç¦F¶3ü?Ì©õp§y˜2ë]”ì¦šğ}n?•ÿùá¨J6‘lIÿì‰ç‚&ªæü‰›	²µ ììÆÕ
"×wá¤ÂğÏ»gG>U7À%ª2uï±À|*#Ìö)Ÿ?Ì0-2ß}/lâ•¥xË†ìÚ…Q9?†Å^Üvc„WÈ(iâZy!ƒ\ì½Qñ˜ı¿·BÍqöêÃ‡U¸6Nyç‘©pã/W8ıšææØŞ]6äE±
Û>‹‚Ä­­Ô©]ZÚg˜#dàpšÖb 2hùo{^ZæÕ(í‡Óâ!cuôú <Â‹GYyÔhtÙµùEùÕ;.[:Zjº‘²¡8Ë!Šã‚"Ñ·†uì™ÌëÍTîøkív…2óÉÿT²œë C€L¦ç¨—kÍUÓú¶×Û+ßÀ%ÙÈkZS}¥PkÛ‹Åv\Â^içr`’{‰æ’s¥ÎCóîÙcÛ&ÓRÙÏ\ÆVOd·À÷³·ˆŸ5lÁ[àì7ÒtJ¯mc!¨à{¹“ó°Åm#Èn	G¦Ú|°rˆ…w‘Ôeİ^Lå•#¤F²uàQ|¶éÙ|î'Tœ7‹ô|ùéš%ø§Ft³Ñ8©,³o¾=‚
Óüñráóe7vû‚‰•íã1b8ŸD"©“ÃvçJí¹YøF 8ç”¢K~MwËŸí§#á ÊJª§l„daZtt‚}µ{£o¶oò.‹½¡ğv•[C&´ç]Îz°Ú1ıöÀ¥d³.ìËsÃ¯uô#\ŸûîLØ´T²èÊ/”Š$¼Íåd¢”hA¸öæ»™KÇÖÏìÚóÿÎı<6]^ã´Ñ*ÆeĞº“=¦×‚oW=æÚd(@Ö{H'gó ë]p9ôY»­Ò} o‹Ã‘VšFÏÊ¯òRıÏN`éi:K›Â…*›E½ÈĞ?rX"­z8áLğr°MÊ®
ä¸Om@÷q«,ß//47oÖ™í=gYôöÃÉ?óĞ½Àü#¿®µÁ?î&“7«wyŠ‹*¡²|¶"2ÑRsÛõÄ2]'mkÌ+<”­›u¨\F°ÇPÀ¶t]Wë‹Zß¿)jòŞK¥é¿‚Õ×giµ£a.f7²×F…GËIx{’…=;kR/¹b¦²‘JQÄ—CbL@AÑ\JMòX@p6tt6%?êÔÏ²#ñ–®ˆ#yÌ@oé“œÄ5QêÛ®A7ˆù\S~qÇ%˜qBk¦ÈÅ…Š_8i¿ÂÃÄ`#Ÿ:ßtOÆ.<HËÖ'¼šÆHğ¼ë¦²æ„a3dƒ™.²mÎä“¾â¬fCy!ñnûFäq®‘/ÉæûºëckwßÏEú@A@Á	sJ©“¤A» „ŠNáØX¹¸ãD‹6âÆ	l~]Õ”sZÒ¢â0-tØ c¤rAçö^¼ÌÚûËå]I8¤À*eÚÜ¡0—8å«ûQ‹GÜhI½ƒƒ&+óœÆÚ¦°ïÅ6ZÕ?&±İ<ù¡N²ÉîßLG}06ÜHëò­Ãà\m•Y:–Lûè£#0Üï824­£,›\Vpœå¿UdÉ3¢²‚)r-p†}ì¶O;É+ĞÓ :ğvÊ›P/£‘ĞÉóDEÈ†5|ıış5'5)v‡¡uî^°§–3Ù£1<sˆr»Úû}yğT}fµDófØÀ1Ÿoñ8Ïü”_6ŠŸB“âoPr/£ziÊg¥¯çnwR‰§µÉUåìææ÷ÌŞmES©¥Ş6œÄòÂPm±+ó{NôKı¬ƒ)|Ám5–'$¦í¬Äñzsfà,gä8TG€ù"âi¶3½òc÷ú”k©©—!8E2x×#„ C%pU„ÓTîÙoÂ‡'^yOÎä‡o³íªNQ-é3Q)Êéìøïmôñˆ¹3×ÚïúW¦ádøeº)gâìl9O­`íô+×ÿ¸ƒ3‰¿¸hOØ?¾î8¥£Øv¹íÃ¦
82¬Î#MaÀıè ´ŒZ[Ô„zÈ­}^D"~ø/ö¾9WšÔÓ4àüpÆ¼èLFiL“ÍÕ„yğ¥Ó}ª†š[å’NşÄâêğ‚¦tª,¶k|Æ=°›É ¯~Äi
é †Àpm…öóFâ/øv{¶Ô8!4“cçkµ8™é©g…üÓÛ\[E•e¿åyM9ƒõê(…i§‰Sã&Ğ´zõÛ#°ìœ]ZDSše	*ÌÑzê”a¹ÑŠ™S(€0¬G:ìùîÙ©p¿Ñóª•@ËXx7Ü}ë¢Qj‹r,‰|’+6h…É égzaL†™§0uÙ››R£™ì^…ÚÚ+Õd–•ªöTÃõ?J¤ XòÈæ‚Âr#cÁ=2c]ı'e7	)8ÂUpTÆ#<Zÿïb/şß~EÁcîŒğaiÕè–A±&¢Š°i‰XG>ã
ŒZ[É}ÓÅÃş8k)¢ÓÇ?AÚŞN•÷{ÒxŠ5¯çHîøOáiÇæğ…O6æU§º;Ôm^­%,[d'ú§H·ùŸáy–•’³”a™˜”æÓùüö‡ö]@»)ê{d~µQ[R$MÈıÏ{ån5b	ÑÈ©Ú¨8û„2¸tWUåÁé¥øt{Úpî|;éğ|Ï<Å=_éâKğ¹àÿ;şCèÚ\Ş-ø‹f«xE?®w~Tµ#ó)–P£Âş÷,
O*W…ön.a·ši«‚g•°pk Ü«ƒß‚iœşç°º+FĞ£‹½ˆ3ZåˆzuRå¿¨Ğ-6ˆä€Rá¦bqXW¤/ÇV­U"ûÜÈélÉW{ ÏdÏ)ybù¹§“^©oX¿÷I]ƒXÖECµ¿0QÕ°Àöp‚NuÕ6²{üfV^‹^¶¡GÄ×ád“€)œ2[øÈ3PPLë’§µ:T'd†ã³+Ì·˜UWê	v(EQüÒRvõôå¥ï–˜š:ˆ¿îñHƒi€Y;$ÍêŠ6À:WğºR=#–§;NYè=hÔô³Ş˜|!ÍÂ•ïNbq{…Ùï@¢@ÆÖğª…ÊÌ¨¨¾3&‘&6Mğjî\,YÂş
(g°K'å}ğìÕTiùí™°İ*À´*oŸ´B©ÒéY‹Éá (FOVMn®FúóØá‹}ˆáE£VŠ#¶;…@•A»ğ­Ñ†âİ=H×†Ütî‡°}Z@Ã¡âñ¦òÁgD8±Ø¼a£rèqcêCõ¤ûº;Á5 qİ0ò„OşÕd"jv à¼œ®)àeç	_,mOÒâøä¸Î
ÀÙ®˜ºñ[jŞt9ë²CªÍ\¾Íá¿ÛME Î+H0„—Ê˜¥+Õ|u×ŠIéš1 æ©š…=“w@ÿ]ËgjKylq%T=Ì.)Ÿ¬°³Òä˜=—pOûhqvÈQRš:]ÎYCFœÔKàM¨üZ6ì`Ül®)ˆö#b"†Ü¡ØŸ[ Î:K8"Ğõ@nf/¡ÈØGºıt†wêôSİt´‘í—Ğ[Ñ’á¶3Á9z
EÔ>ß¡Š³ ×œÃcñï™=Å“mÑ6@Cƒ´r•ÉÚ,º)¸=0øÁÏ¶j9˜i­ƒÄ `@Ğ§M^è´óÌHx@ÑÙ‡C•Ó&Õv˜0ˆ»<L<¶òÆ·:|ôQ²q“?’º)ànûvÍ†AzÒ]ø`“÷EÁøQdğbNó™í{ÒìSÿÌ–	Ü †?Bİlè—¶È UuÆG;Æm—²ÿõ+bi¾;^Å2uœáW”H*i¥úF'ÕÑ¡n i¨¸%K_+¨ş¦¹+ Á·òz[Î×CÏ¶h“JŸÜ*QLê$5=x2ÄÓvÌ]ÿ€ñå 6Ü~‘õ+Fç=”fk4&¹è&«Ö9ö€"%®†ğaİ£¯°<ú8Š.1à?Ş&ãaOŒ¿»ù˜÷Ã¼ˆBwšÈğ–¿ımã2¦)ºáç¬~-ÉÌ²…“å/E‘U¿y‘ÎÑ%!u šIÒö7™AÇÁ'’a"d4&tî¹”½¬#øy¯»XËï^Å¿}ÎsÈÖT€ë{ë ~qJ5q)IÒ&–FÁÊ½†2böq¬o
(&åôSr*8ÄP:ïÏ-~äö±Ÿ€åÜ÷Àh¡õCI”ƒ|g-Ù+7v…/#O5 êÔq
z2&z¢÷£Õkh“ì‘Şv+ KÃˆª‰Ë÷âùêk@;ùTäõX­E}íCa¿np‘Ú¥·f	¤N¼9‚\cL¾i\Jœ³a±’i÷Í•éL9KF;ÑÇwe|q¨Ã¢zŠÑ$Ñx7Ÿ)zë7ÕRt¨¢Iş)„s*À
ş÷`?{µ0Ş6N6«ª¼{†8='÷€vSå^NŞ˜QSV5ö°&ÆîÎ¾3PÃ],Í‚UEÖ´f“õv&
 Û ¢œVïéØl#•1=­­ûna2ÈÄµ˜gç*ê–áÛ6.ºÓH3x†M?†©ØyáVoìğ‚YkÊfKÛ·9-k³5öyáñˆî{D
{v1CÙ
zÚ-¬²IVÔeN˜bÎfJûˆBÏ.á†á'R²¬ÉúÑQhÅP<B=`r¤Ë®èâûsğãjÃ¨š”)¾¨ GQ[£äl»é ¢EßğíP™½º#Tí,Üvı*éğ©4bZ·LUS¥4ˆpª€hQbÀKáPƒrIçS.~nëºî„©‚°ßKÉËúšÓg  4[ÃÍ
¤Ó]UË<}%í0µÍÑœÑ(!H¿lÊ|ò=¸×HâçW›µıxé0Ê¢ş›ÉR\J‡xÈ&§¬‰œy2ë‚EÌ%íL®Æ-TAÊöéƒ†¿7d¿°¾™¡À)“A·İD¾L¥eâ'†x	h†( ªí+]<É-¡X(¡“r÷ù>S¶=®üº)ÒŞÛ:2(
Í¢ŸîÏ Œ DnN%\ÔºjKW Ÿ1ïìbKçˆhQP.”´à¢ğ'Êó¶\µTls’”2©#êˆOf`ùYıt&ÅµÿÑ¨dğ"(†Y:ûXa ˜Å
êÙc
ıWHAÜ—®Âu0Ğú«yÜ$ft´*C]’!‡R¶G#\Kò^Åâë‰Ğ¬îÑR×9¾
Û¨:7Ñ¬çüÚh°xgğe(È¨zÇl¯FI£Óƒ˜¯~q1ÎÖ1?,ğö¨W+¸~ÉZmÇñf
Ğ
n;íÄÖ¹¿^¿™wjïó_B'ğó^
uáQP0 w®?
g{Ôêª®C­póõ	Zpö¾Ôˆ—ÉäH^—ÉçJö+ñ5ÔÖn Yc‘ÿŠæÃä‹Ä Àİ¨7ñ<v&›è-Šš¸”H§Dõİ;êH@ZñÑcºj…	Äš±¯Ô¯x!öû÷+7l÷hÇ[H1áëg]¹ç¿JP£nªC ïYÚ‡íckl­ÂŞÃå{¤Òc˜Ë
‰¢ê„Î‘\ûòå:i+¢R÷µˆ‘]§m{\æè#cèûÜÕD÷c8˜y-3{"ñï3ÎÖK2g¾òXHuOØS«ÃjôG·»7ÆÇb²¶’¾u›Ñ÷rÇ,s€[QÌ:LFØÊfv¸£ìFDE‚còü=^9oÓÆ2/Ù}ĞS2ì«ªFN oÎ‡1pÎ­»Øö£¤%Ğë´ÍC8ƒ şPd;›­Zç$,o®¢£Ãé¡VŞ `œf4¸Esšû®J\i4m~˜¯€ƒ}mŸ69bºà°¾‚$ñy©öh÷86² ãKÀ•*ù":ºq‡±œşÙ®úa¤tä•ªùñûEl’Xş/Œuı«ü¬Ï»uız=pÔéL4Ÿê’%ŒôJ¬„x’åÌßSœ¹ĞÜ	7ò*|ì‰³èK¿(¬ìïí¿œl&âÖÍÂŞËìfö3ndÀ/2÷?Vòê`¦éVù·›ÒšÙu§¨jBy´=ôÂe–²Ós­İòç†pŞÕ”×e#f›,¸w~AÆ,î´¢ÛWşÀ]…YİA…GîÏËnõB5ö²à«>|r; Í§™wÒºì’	(îg¯O.¬¶¨£èr†Z/¨Z-•"`™ æ…<»É7	ùŒò«zzÆvzˆ«À:DrmŒ³ÅôdLŒ8Ò	ªüb“€ÉCØÌ’FIru8*x{5§!í†-‘Œ®¾˜Š.[ôÏœÿ}˜<]aª³-üÚ¾™­æëmF¼È-ùøU×¾b‚!N•ë¾ˆ?ÑT,~ú¹ÿ¶0Œrl§ãârÓáù[à2–ô‚à_;		.…z
@H_şà¥;‡ñÅM¡z,Q`Ò€§ğÜ;Ê!§´!½ew™òX>˜ÓÚøä£›$qm	œbS«4€¤µ_ EŠ&QØ€Ø£³åM’óoŸ$åS@İ³ôêÔúáÜY›çE
ÍÏ&ü¹~# “ àdÅ#_ŒÕÖ¶DåÖ)ªb‰Ñ”I>º©]õ¹j>B\*™EP/şjaš÷ƒ;·^ŸY-±?t“=À‰ø}bƒ¼¼Éı«¢ûÜEUæ¡P×ñP70oÎ*]	Ü|àFs=Ó°q’Åh&Âkì‚u†Í:3ıĞY ¤€œ0ı©ëJSWØĞ¿ç.şF°…7µºğ?…{dÖæºW-y´‹©¡XŞ4O&u…Óís½¥L³áµ‡$å+~½z¬4ÙrĞîÿ+ ˆ]zÈ;­ƒ…¨3ª3éyR-ş¨„°¿Ì<ÄïŞ‰ùıÍ¸nªå;n«Ë
Ûé”œ×h‰UO€èP`x-ë¢qæq‚BGØüoËúıJ<UéÀŸsıàšÖ‹ö©-ÆtP‹	˜Ì‹†évÆ¼Z4FBµqşéWÿz±¾Èª{=H0\?¸~(‚ğÿLÁ‡ö½gOê€~=İW‰$ˆìY\by/·û;«¥hÆí(±Áœ™ı!1:ùAåné1°›x’Ÿù¿úŸQÖÄ&÷§„²,%óHo‘8-_Z~·æïh²¿×áÚg|­!P€ê§ÀEe”Å3É+j­#ªÏjC”»J"vÄşï„¤‘@ãòQÍÈ3?SM½P
±'Ì-÷æää?nË×)GQŞKª­ ô°2GzÙóM») ¦0êµëş‡‡ªI€¢ñ);[»B›/#ör×´•oy F–õO[BİÆÀ€ŠÑ¬HÖ-íŸJÁ±"ĞvécDU†T°ı\€&UCÊı4ÙZ1ñ"5a<eC>,›rù~Y MZù¿h•E±ÿz¨c¢"=,—h¾ïàq² ¦[}†_ï¿¦_¤GÏ¶B×hßc©@Êf–aœG^l«§ã8â-‘ryè©şdíéSº‹¾Ï&©cÕ¸ëuúı Å&sc¬p56*%^N{:DÊ|V!WsPÆYÌ9J*mXK\9×xÇÕ¿ÃÔL¿©ı)f[G_Õé¬xÖVƒ)ª@s³J-r é±äÖ{v¼.BuN|˜PŒÌÒ{S$4ÕËF×…ìSŸù µw¤Ğ:èÍw¡j	.šùÚ*æ¨ÁÖBîJUë("Şzáa|ÎÕ%OÊQ_<ĞÅ­ijdäbÜÿZƒ×·çÂHcw–¤]¡ ˜–| …B‚‹Ô
ËüôemØ«èî+Øµ‡â”›ìõ™†ˆx{Ø4šñçÒqšÿ'‰ó×‘ øõ3SËk²ÇRŞ*"@Údµå‘A&$3»û•$ğáŠ$|ÜÖ(bØß«·~H<=—Í-ñå32wRèg³º! ´bQs 7´ök¯,E[óé{¹î³ÍÖ†µûü®CgLR¬Á;ãøJÃKyFÕr®¯ÆBÄWØCşäP˜"¼"‹2©µÌ±lÿü"õD
³B×E¥­¤èbB§KT|8Cä"ÚD»øaİjDìEyú²}¹xÖhm|{¨×ô†Sš8^ZN ¸oÿG%íNOI“æ€-½^’›€¢™+lõdbwş«ËÏJZö‡eeûÉ8ÀëRöÊÚ Tå	?€Ğ¿„*…«”K@ê¬@p¶_qÍ‰fR/1Nõ_(`ÑÙe­>_l³	ª§\jşXÅÇ¼¡‘Ê<—­´3wHÆIy‘õ½f¹ôl¨{éÚé–½>¾(^à¨ç™¾®—¼ìĞKpTÆª#"¤ÆVBŸBÄHä¥ŞÀş–·¶vZ>¿o|5Wï=Ğ=€£$®§Ä¿H¸7‚A÷ç¦X¯q)3Õª|[¾1^uS_[õg4Á'c* Q,äs®‘–ÆÃä2sgŠ°+Y¡Îw$½·gU¿yÛ¼â9şlƒîiBy[T‚8÷¶&%)/Î?kîHtq®ìo_ª‘S‰¨1g•OÓÔ»s°H¨/ÃÓ˜ÓÜã8<ôns]sAäc|Øæ 9¥ÚÁç_]4aôe(RVCQm×Øg½”ºÿ~ëpÇèU&#¸ |¼YÑ§ÍÁÛºt»Ğ†–LÄ"7|µMÅı8¥á•™ÍUxïÂoë>ù‰,ëáÙâ'q rzVH(AşİÛÔƒèQï±Eşğè“%+ïÙŠÖŒpk£†=®÷lŒÊ…¶gÿïè­¹½°eL<«]FHÌ¦¤fĞ—¯•x„•ƒşWÖåÈÿÙ*0yé»Ü?„ 	|;§ôõÔüZÔ|*íñ¨¡vDË$÷’·1ÍšĞ’9¾&ëºúX:§·¥ÿÇ£+ÅdYŞû_%¶u÷øjˆvú4Åğ7·åÚ1ØÌİxyğq¨I
¹¯´ÒõêƒG_Ñ Â×ÖVK ?!W|b¹Röİ{ ğ©Î2¹= şël©|J˜—‰TØ»	Š€Q‘	Z»¿È­Š¶Ğ!ö}‚¥?şìÔ"ˆ¼:«hqøyùxIŞIMÀLYö°˜¬*ı¬@mÆÆißSBÒtò¸j¾£x"dG5&äæÆHÁò¿ÁzÛ5RnE™Æç‰]„_¡¡›u_"«©Î„SĞŠ"`!¥fÂƒO@„¬›‚ëpæ˜jñËE6;ôpúà6¡ó.ÔƒøQT³	`FfË¢èµ×&joé§ÔÑ´œÑ`1§³'Æ+±A˜¦»Q[»IBVAY N%ÍÒn?W5«^€CöA— ‚_!LıuÕLûÔ)%Ä·—dK³7ğŸ²‡lšc¾eì/9d’_eÔ÷)(ä—|›êNc-¡p} ã”\U«9~ÍüvLÛÙÔL™ş'Ê’²W¹¼İ®j ÚàÜ¿q?ÛSÍ¤Æ ±&¨èÒ±'ÁÈPÈˆKÉ@CN]î D$0'ÛìH;‡Â6ø¹óŞx›ƒ¯•ú’Aö`†k9Šø…0yÒÒö¨ş'½òÏ·²°J;ÒàW¢ºZ£T3I%¡ˆ7møB•³6ÿó¡™Î™Ù{´Ç&²æHó%—vó5ügI¯‡îj
l[DÓF	c6õÇÉ5Ï›ƒ†¼$*ï‘ŸyP“äœ2ô uÔ¯qÑrìÊ•)˜ßŠ§ªÓ`$òÇ>/ù¦„O—Mşõæ»wk&ÙfëW÷Ù¨]z’vmùß]&İß›ßºpÂäv +Õ­nQ60Í ÿªƒp=¹=¦¹°(ij[ªF¸³baO%†µ„È+¼4ã±ğİ»ºlÌÉ†V‘Î43¼Öv¢®J¹µ*s³rŠo’şrûqîÖhJíä:Fİ¹pHô€ÆÄAÖàó!–ñ@T…8XlÂ°cY¾·Å,5¹ïú2\ÅMk¢FïB®ïÈ*	Uœuàaê¸;ñ—|¿­2íœÄ!9eÆ>Q£©Ú´vìWOé	¤4ëÚU·X>²Ãz)ëí4Y«UÖÖ¼©Š€OUW]NNwÁXùãªÕŠb”eéGåwÄEÃ»©½‹³a™Ì”4	Û†ğ¼Å$¬ı¨`wŒ#xê•Ròı¤@;Û¿¥|Sİ»d¬¨Ä–dãö(bËü:]/n®Ğø27lYª›S×ÁVÍZÃ³çêøœ„7^ÏC]7Ò_õŞwo˜™%µ§¥•_Ìmñm;‚If5÷2ˆz±É˜Ë¤1J¹=¼±§$˜UX›õô"âÓöa%U–	|6¨ûi¨w9­–¼V©óÅØ×kĞs©òO§dÈ€=ÎQ
ºaEÍ™”'d;P®të®Îêz…_l®Û3²à_a4_*×cA‹>”ªJ°fê÷k&t¸É‘´õ6Ağƒ1¸œÅÁ3Hx¢^©ğ	œÃöcşëì1œFÎJ–~ªş¹ ÕÉ3ÿOc2:fÅC.z’T–D?kŞéóH~”[\¹A.â`c¬Ä¨~cÿÛYöK¯NTÎ©“÷YºşDUºE  ıåğËÂÂcÏ è±€ğûT³°±Ägû    YZ