#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2078553016"
MD5="a5f5ea73954740cee1f0012415c8f286"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23440"
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
	echo Date of packaging: Wed Jul 28 02:12:11 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ[O] ¼}•À1Dd]‡Á›PætİDöo_“, Æ£éË#Â÷4³Aš`+£6˜’!^l°ëü|¤0,‹•#í˜Œ½ŸáH€IüOCˆkËúú;…¤÷.a¯Tkƒh¬Mu‰ÉÆ0Æà—…{Í>Û
\Ï°-äz	´4ºk[(¬Ë „Ñ¬‘Fÿ*'7%0zŠÿR›Ú¹ì¯Cšâ¡ ãÚ‚AGôSbÀ]uâøÒCñ½ıUJZ§œ¥˜.ÊÖp‚¾ã¤	¤z`ø×9Gú
±EÔ§ĞÒ…¥ªüŠmô#IÎe¯Ÿ2‰@‹|ÚP€Ğ™IJÓZÔ½‹È-ñˆ_{8}¶¥`sá^J¢	ã63#F5O2¶³å~ÚQğz~:ÀuMouæ~W¨8Î![5 «])A2ù>_¶3­ím”¡çqiğ%ö¬/ı{‚:¿- Ê>”"‘.ÿñ!qhSty–Ó„v&¸A§œç|o$ ¹`svBiRìl²kî,6Y¡åT?®B	Å]İ±…Æè+Ïˆ6ì@|Æ¢¦‰­J%œâ¶2¤ü2qšÁÙ6Õ×˜]#0ğ<`$’:jÕ°ÈÌdb'×‹bè>ƒ®>Ã¹ÇeÖ\uf,[â[‚³ÆO»³»PÖRIHú´µ…Ñœ$e×QLqnâi¸š^V!g¾Š_¤¼7çZà7 e±2,‚Àû¹°Âï_s®ë,;ãh¸†%ëş·GY>òm>L›Ò—Ù÷:°¢µŸ0!6lÔ¹º!I¾ÉÃ „k\FëKàcÔV© ½Ó #Š}„ÒˆJ´E²‡«åô¼ª˜}Äï0|…[d
È^;šMB¬g°¹ó•Ñé\Æßóqbìæhe&Wâ~ë&öA­­e˜åk:¦ü;lO—zò\,T%ÿ!(„‚â:ßÆªpÖÍ–ƒ¶Åşõ¿FÔ…›[³­¼©	€²ÔY®Øü_=·‚Ë#'Ê½—…O4õÇN—Q8X¥¼Q›eM¼ÅÄ¾Ëpiİ¾çzl¾m4G)F”GFà&ÃT×XÇôÄLø±$ûäœ-Â•É_×GÃ¯-¾r1Í¸â’Ÿ7…C?ÅÂ'÷ÆQ3Ó—ƒjfµSŞ}(U.îÍœéÿ1Ò;iD‘²F”yj!WHqÍ=)(éıİÁ0n‡éÊW…¸{YCÔêÕí?‘(šC¾wKètRË’É–­¡W>äzA;ÂGeöcqàË¼tÜÏÁx8ÔıÍÒŸİÈÓ°‰¤üK¼¢;½!—&C/¡°´p]¾·8…w‰àÄÊ‚E1F‹Â¾¾V(Tú»ª¥ŒÀÔ°¿š•ücîŸ›_C”aÒyË·€‡~öÓ@öØåIŠ®ÃØšŒ…Â`Å$® ‡-»…¢…
=Í]ÚA~3*V,¾A±µ¿‚•Üõè;PÖf/‡ø<ŸZY®L-J;¤bH¿âË]¾¾khK£.WÄ‹ªÅL-C¶x×Cº7Ğh;cB#dno6cI¡êY®sl÷tH5r”ÚÅšÎêgÌhíºÄ;‰ŸG0Û6’ÙÙæH=1ku_¾pP&v¤B~_V4b<Ş"Îµ )&1ût?:/¤£N·}OPE	çÀÿq¡sar<ã2
$¥¢ÑTÖòÃ†ÄÒşXF .r¶Y™¦l(CqT	,˜…mäD÷$Xiª‚¡Übò"_j¡¨Ò°ŠBª…ß—Uó¼€º8’…½…Ö”WÿÍ– ^x§Ú®”¦ï2'½oÒSŠGzeè¤°˜‡ÂªûeÕ®°N8ËUs5ñ¦Îôyj˜c…¾C–]£µNÉ´F™}¦V1¤JsæUmüJ]KRÆ–PNkK¸íúcM„†ˆù <3ÿØıİ›u1è÷q¥7•ò¬°J¨Ûñ8×Ö%ı5–ÁSÆ[¹n‰^îœ[e+Ó×¥íùï¦5Ïõ‰”™lì·¾B¨½hÁÙ=6ÕcY¤½ù‚øns!±ó„µ¯Ó€53`I•—?“³N†©fß¶R§ˆYm¥Tü¤sîP•—,|òêë}¡Q^ÓÏF²ev3+ƒÖ©Çß°Âìœ)Jm[ºnÄ$š&PâDk³÷ø‡ªZm_éòd_µ•*#±#5êø)‚EÀÍÎÜUõí¾	3ëz§>wÀ5$ªBYdåôpïÖğøhÎ)*Ñ¹¹è,nVşâòñjÇQFJ8'ëqÃ‰Ø,‹®¾™÷|pò7‚p^œÀL6ÓMñB²>zë :Øp2®›dk…¬¡,éá@’N¬ï0±ÑFÀ! ÑÀt~€¢ƒÅAÄÄ$ª&ˆËO—êBô°îê›¸t#Y_vR‹è‘õ»‚¨õmÓv›ÌˆáSmšÊu_ù§V	ù°ÜÛôÓ†¯¼T­iïì<€ù'B"ÙR6OÚ=KŒ€ÈJ¶ÔŸè²­æ H}F ›2;şÍ¹‚rg©"/šjº/&]Æ)è[ñ"İd±¤usn§Eœ1üÁòïŠ,õ@¸HCÌ¡s.Ò­–Íáq&…ÍMzŸ˜£¨gìœëlj"›ükò_ÿJéƒ³Ò=ÆA¥yìé¾×úóÚ)ºš~Ñáî1…ƒ ©°µÈ™>M˜Q©¦{ƒ1ä'…'®Ê#] Ø*”uMÈş{E©ÿlŞü”QÑD[²ÎÓ÷l•}'Ÿb§Å½%Ù«½Ê‚jÓû=-Ø‡‰›‡[D™¡FHÑÏ§Åã”¿î‘%D’oD@[l9LÑ»=¬ıÎàf?|X®8Ö®ûÓAm2?fNôPZî«(¹ìAè­Æõ›DiI›µ'¶&Ä#±Œôö{wÙº#«Ş4Ñ´at^7^ EåMÍ5¤®ŒMÃ\Í™*Gèi
*t8…ğ˜’ÑZ?u¶ö^ê …Ş¦İ¥K$‰ ş* 3D@/¥ÓÄM	“NWéùHìÜZ)ÒîæÙÿªÂ÷ºjh»²º]-gu{»Ôõ[8å*<q‰AØ;øİÿ{36‘5 $)rÑI€ïß[Í•Sºx€$Ş–¼<á!¡ã liñ<#-ş½OüS[;}ú1AŒ}@ÑòÂÍrÏßß<;Êq—U~ÂèœsZı·Ï¬ ç#K!f¤wd3Õ½è>ß€Îz&µó~Í‚vè$Ôv$\¥©IÍ±%¶€[ •všé¦şôÇınF}‘¤µÅ Øûi0WÏÑt&4Î\Ü†}¼&Há=‹]µPßE®u4éÿ5İ_f69Œ²2i~pytbàÚm9ôüGşáIû’ˆ§İD ±ö£*ä—õun–~¹×}YO§ì¡JA™Ÿß‡ÚO„ú´˜H()që;¨]|ŸÒ‚Ê×Câf¶w1şVSZ8»¦rsËl}u0LXÍˆÏ@ŞÎ>õ:«x#p7ºdotiáx@UêÆFm
ÉV±U°f'ßäM³‡P)ÛÈ…ß!?¼x
¸Û{Q—×¨‚´’`´ÇÁ¾¹CïacãDŸ ~i˜C¼fià¼ïÉçÂ+äÁo4˜ì §–³!½Læ–Š!¢ïÎW$S}d.^Ğè^¹ÖØ¸U@[¦ô\óù0õ“áÁÔ‰«coâYàAæj›¨ĞãgœW¶”eFÃGº²ùEaÜcÛú¸Û´Ş°›/y¸»ğSD¦ÖóCfD#-ÊÒdzÎc\;ƒ¿Â¾# q.°½èØPÖ4è½qß TÚÍ*»—ÛaŞD`§©Nàõº£Í£¢qàøƒ+¨V½Wí+ÊËêÚ…£=ğC›•„l$šnjÌ™KÍÎõ„¬µ12í„jëÁD“.rªÎµUÃ%¼Âå,9Ôì£léyÕx&[Àx'`=¼½`­ôZÚ…0-dìNQê/£´øğSzÄèwv\0xÛ	Ÿõ€qîõÕı—€™Hñ½CÙcÎ  ŠÑtmm±S÷ØÒ ?Ò¿Š?™¾Ñ–ˆz ¿K2r(>Åú>å¨!ˆnº²#Z^|Óeµ6Ì_ÛàPáTñÜtÀ’X!ƒ^\\0r[õÛşšYËV’	V\Cš|ˆZN§bïo­‹qægŒ«š*ôåÙ~PRbR…zpÑıcJ– ‡R“C"×Àò[iïã›´-]Nx°HÔ!N«EĞÀÑºù`İÓdT‹Ò—³5Õ2_6ÙŸ\qchä¥Øn»— Nƒ“÷DNéy! E´©İYÇ ›dC¸¼ ô8q*/øß«Û¶2‘@ãğE2Æ¤XKYQè¤«TùşÈ\UÑ„Æ8–“Ü·öz´×aT0&¦ª™9^ƒŒ…œG·Æ$„²} ÃŞîÑ]°“ÍŸ¥±7“åŞÄ¹øwá\“Õ<ÚÇ”+××ÓìƒPoy†6/àVëİMa¹÷ñB
vC„Ù ªœNÄ°BĞu¡ê¤é„XS'OË”ˆ®ÎùJÀó‚WD“ì3Ò§J	r@aŠIyô$ sy_5ØGoûEktÑ;¤¹P'’/ƒ“½Û¨·äÚOºæ)i®È”¡Ú”®2C­è½ÙVNëõ@…£?æ*hRy6ŞÖ¦›êüÀès,•åQ*¨ÈË<µİ-`©ædHÑòôp£­Ú¡òİª3QY§Òv™­Æó<ñİÎ{ÙÏÕx´ÉµÛøg¤HÔ­-¢Ş¿iÆşH»LšØ»Ã˜2Ü“‰zSªŸf¡×XÊÖ,m¢òÃE¿éP˜¾£Îí–t3Ô—meIépe‘¤dN˜·ÅmåÍFpBÈk0Ï‡XÀëË<”,ÂoäùãÚ¹§.cî˜|wÎÅu3|cş ré…Ìu˜‚U`“ÏQØGÖ×6°[1Ò€‰É$9£x5KıÓœàÒ§,ôjĞ»˜¯¹±á”È%8˜ Õm„œ\2.´Rñ$Gí
ÁÖÎ•2¥Ù½2ûÕ©ÍH(İ'$‚Å  >éyø£/[óı¼Á6½3êL»º%I©´÷ì>ğ/íöŸt¯4¤°:X™aòlìŒŸ(IríOùyÄ88h{V9ViÏ_äJ•Á×•½ºÒoÂä¢ª“L=”f4‹)dACÎÿÈæñÎAŠNj	håQÍÊ'y3|KÅƒ„¨áŠÚXQĞAÓ¹"ÉS‹®’pÉ2|µKØA6³†ƒ¸%/ÅaÄ*Ús:Á*.8¬ov9æ®Q«PR:ÛÎ©em^3<¨Ç†ü‹²æÑ¤Á6ŠÀAì;‰LÂë™¥‰ôÙ)h(q™kâÃ>²¿`ÏğU>æ•Æğîr
ãÔ®ëÖö¥/¢ÖEÂ`Ù~ÉUŸêOje­[IuğêÍ›.ÍP»vÄ…;¹ €İñàò¸³¨ëBL4^¨¢R^Í¹oÄG‹Fg ñO=Pè|$¯s*N3ï¥RŠ‰(±k¹Êå¿úŞØ¸QY'4°Rf; 
91şäÉL®Ü’¸lªj9-†íì!»HÖÂşNğ9ß’¼·7[ÅMŸLñ—á”5>€©âZjx$“T#S1S³DŠ€p°ĞÒªÖW‡¾ãÓ)ANZ6ÏD&óÛ×8’áãco]}WÕ]7×Šõ·@¸¦ ³OYû4-Z?èÓßc?úµÍI\ÑÒA€û2Ê×àvQLj+kÕŞäÖfãÊ2;bï‰óè°*TÆ+mØ}›Û»…Å›¨¿‰;TüÖŸnî¤šhÅ‚–5OŒŒ€Å§ùùË]~{ã]CÆüJÔaI„hÈH')i…qh,&!2+
§CtÃr$>–~‘ı_ñF“&Z
Ü–ó-€}%êßÂŠõKÄ™çCa)DÆrI.ÂI"ŒN@Ù¤c<K×YØæhv!—^lîBj®,ªşÄû“¶<I*Ê·½1·:‹j›¢“-RóÿyowÜ1ÔEÎ%s@Î&c˜tfôŞ¹rt›2zm[•¨;—S¾å{åü`d›0>¶ÇŸaU’dKÖ<“øËÉİüê•òV9}²–BÈT_–>T[µÜpP­Ôv[YvoE„WeËùF¹9µ¸ô½’äU£=Ñƒ-é^N|0K)hw”?É^X+b°ÁíP€WŒw¹4TXÎ.~Q¡8—úÏ«‰i¿7¬ƒ O>O`H„ï1Ş×7“şUejÖíÂ6VŒP^ÂOWİÄ<›
N jwÓ‹6š¯ò~$ dDj}ÆÄUB«ˆ@]E­J¿”0uØ™<äá6"ìwjgh‚İÄŒOk£¢óûp‚€ÖI1'ñ•.–~ív4ÚÌ0'ä’Ä cvt– ¼,ı‚#z^İËú-ğ\Í÷İŒÉ³eBI£0xuÛô“Ñ££|ùam7İš	Û¢›¨ô‡A9ìõÉ"ÿ­!?®èìŒ×lÿ„Š˜RÈ=]TàÃ=gõ?uÏpË‘SğÁ@t¶¢Í{ÿyÙıOœî»-¨Û¤üm	°Xæ¬OÏ÷™‹r»v×àOakùËR’L¤§?C›ÁC[;±T*ÓjP.zKrü–L*ò
¼¿e8ªªÂÿ3ûÔ…’*²¨…¤½•ÄÃ%ŒldªÉ§eœBñ«åFJ'<±ºD²Ñ¸AOŸW.ªáÌ”[âI÷»ıªÄ’‰ZF~¡\#6ŞOcwæReø#ZíçşÚÚ íôQ Ádö *¸g óªê	PêÜ.ªdNmÊ'Ìæ§%åRö,³òVvKjg´ÃT/e­´oK jÁÜ DŠ0rå2­@ÑnEr»CXş¼7¼:œçø²G–U.³†Jı“Ír¯vœM–“< bÀ¨îX\s^ë<]nQ°Ü'jwĞ5€ñÜX0ó6Bì¬F>À8ì¼ÿo¾‡>¡¹:13ÂnŞ¨g¿Nmám¼7\iXÆÉêP,µ‚ÄgÈ]½¬¤ƒ,äf®ıÀœö„bË9C¦Ø{Oô^~Ëí…ºäùî}$3=Q!÷2ôÌšD$•uŸæš½*ßgéƒ­b®®n£°Øˆ-JºùÚ,¼ğ)ïÙ\=é	®"¥<±öĞùŠ{äæÙyº_ECˆ¬Xkä;ˆE ÷Àl[OÊG§O)»Ô‹¾KƒWåâ°gAê½HKf†«m€?\²bW­P”Yor)nKêt»!ˆß w(e­:‘ßÛşw“÷Í¨ü®W3­kdÿò,â¬‚$n6cmEd:5Ay>½W@|ôşS®Ì•Q´¦dÒˆôÓÑ6*’‡í“nRåÏ;$u×Àò”çuŸ'îÙ:·0R|
 oâ\Dh£Ì×~vº’û¦^•aQŞû’iğ… ôn1Bö^&ÅRÍ¼cB{(ä^†>Zš5+ô@§ ©…É¢i¾ŠCth@®/fĞ®d­[•^/Õ7™Ã…ÒŒüo­»6üöU£
5S¸soú0D†+&ı.'å"”J$JtÙ<´šÙòÀ762là1ªQşsÏÊH79K&RóB9¢¥ƒš×ú!	Ö¹P!¢şaÿ€”M†5U~~ÎBÁÂŞÇğs@ÅVmñq0´ö_Ä«ikÔF¾Q8ë-Âë)"Ò­«Y;’+X²«:.Ó©IzMU¬Šã`#M?u4¾ü~™N..Õ™‰–]óşí7ÌKÏ	&²ùC6>•™GNa.8kÃŠ­bb;IŞ*Kxşö<®1#´Ûç'š^ÿ8h7şzËb<ï|Q]00(¸¢¶ ˆñÁô›œ MrğJTGa'õÂÄşÓèÓ‚}º6Œ»	äb¸Rhg ÿGU	bîZ›.´YàÙM4Ğ9X³“î^£;è¢ÏY D¦jÌÁÈ‘Ç·¹‚¶“,ĞY9Ú„½»xÏ©–ÛÙ‹ÆÍØ´Ş÷’ê®Kûz´ërQ[yeü¡t×Ä,Sš\^L–èï*Ëà;’|¨×¦bL?¬ôÍ‚¡Ë–N)"©‚¢c
¼
Ş8ùæ: ƒª¾‰·2¯? ñv¿9“Øj‰eàÓœEûım`$úN¥—üZ¸iäguUÜ9ıè¸¦yÏ™Š˜ûê*/w/»Û·Ú›Q·0^w¶˜f¦Á«0x“G€¾ƒ{/_êª];9t_˜í¸6ñjï«ê)i#·“¬ÔüõCÃµ…İï–¦ä Ô£u<¥e¬q9=•¹cñ†³UøâôxEZÓ‹`Áñ¼½ğ,ËúiWöôº~üÑf!;‡ÈÅÈlÏÿ½µfÓº˜iÛÑ¦Œì60˜írÉâCEˆ¢×µîWó3!©¤-°*­!¡OP²º-6¹^”SKXÅF{´Ö¹âÂ$İ³‘ Ë-X@FuÅ6«xÔ`§š'HMáßMÆòuF€‡/ø{N,ˆì®¬â Ô¬ı¬ùş?¸wì‚¯'$Sˆä@Wƒ©ã·š½Ú¼Ëh¼6;"Ë“}|«}fzf\+¥’­‡áŞM~ënq¬W¾IA:“íËx+CH©±ÑGß-ş¤è¼o­éç–®íj³íÛê>åI¨Õn*TÅ•á(qğ5Ş=ã LYxÈİ÷î³„ĞÃ,Ï­P“ÉÅxPK‡‚,¸,¦—¢Ú³mæ}bëB’íÊû+u_%²á 6®§ãöå×Á>‹P<Õƒ;6iäÄ=äÿûÒIj‰ş_°9CÂ‰Ê:oÓ†:pûÈoƒàf¢ødqÚÀ–íØ$óùK»Q¹=D3¸%Ïø£1eÅ]3%2NZ¤>Åz¶w_‹±n~»å¨OÚÔK‡IËÛuÂõf KÉŠºB7&a Úb¬š¶cÇG³¯m¹ª·±¯&+ÔZ”dƒ²ßL©
°.Ÿô£E­^r4UèTcÙú
R}3G7ıÎÛËl‰÷¾ÚÄZ4ÇPL_õ šO½P˜Ï
ÀäG	
Ô[qù3|ËH•œÃ„‚İzVáxš&šL×W¥Kb}4øÜgÁğÉAÁ^Ûh	ªó:~e¿8¡ I–¹("ÿÆıëşÿ*ê9½yôûòßNü»êí•…[½Üûœ<bS¥lK©8íŒ’n]Vqº·-_g½)©æ¦¢AÚÃ2ôÜûìóúâ=c,Öo˜wŠ;i\ºtD6‰Õ>¦”N¯Ì»=€Àµÿ!ˆ2ìãÈÌ#Hü%¨&0tW—N½	ø<§ƒxy6`0E–Ø“,@í†dARãåuq¡CäbÇ“Ûf­Mª£VŞÛ8Ã¢(-_%cš`¼R‘&M£°¯Æ£­åÓÜ<–KÍIİ¬¼Û×oÅ¿ª5'İÇUz‚ÀfÏ’¼îihï*]qtŸ×*à
!Ç¡?²E£Ÿz”¡<mÿ\v@—UÖöÇÿ¹S»…Mè±õN9¨zÿÕÄKI™ÒÑ{$4ô8éR•TI1Coòìx]ÛSñİ¯aŠæ> ]¾¡ymr“ü\+ãÇ%÷ÎR·$„%¸d/ı¹e<e™sz­zÑ7]Æ‹óÔ‚øÎëï<˜iÊÅàÏ9-—U Öwx©³¡™·ÿÅÃ	aÀG‰‚z‡}8!»ªİTÖIÈ±ıàÅ:,ª|Û¬À cl·˜$xXÄ}¬üš-I.lÆ®A€å)–ÿí
y4ÉA+dºJ|ÕQÂäA‡éH˜Šc‹LºBºˆÊ ¨ê—œì8ú@ç˜ıÃî„0e$®®ûrwMÍ]9)EÔëz( ş²lSWÒª>ö¦ï6ïpÁUÆbÛ4n·YzÍ4EÚ	&GSõtÊòÎ@şzÍ~yÚjK´;¬Şk¨VãîÄêÉÂÄObšYÜìµ<"¨¾ğmÒ•1¸o¥#ZzõjC‚¶+çJÈEt°!ÚÑÖÁüWçì^TÁyxµçÔ„ˆøÒ	æs„éÕ:íU•.±âÉ¸>tì'i&“u5Ùqe_GQÒ€ Û¢ÅïµB¸]§XÚGcølHx¤"’R·öäêæt¼bÏÜş`•L	±‰µ×";ß«(4İÅÕ’uV?¶Ëg-ËCi—½Ë¶u"¿şc›+á@YÛZä ¥ûºO‰³éİ!a]ÒĞ
M>£€m±ğâvà1™ÆSkçA²°óï‹¤4ÒĞºÄ£@á ƒà1ã‚ò¸P¬*İ¿ÑåéG„À ÿMÇûÖ†Ğ©µ!AIo(ËzPW…VÅSj0GnàÏfı˜à£Yî™roäØ>ÍÕöHÙ=¥İ=ÇÌ#Ğ«ş–ğd«YÚT%İŞ:hŞ"?B±˜°Ti
v»³(†Ñ€ûûè«>×kW†…Ï¹ãôW¥Õº4R°tD-ØYgœ«ÜQ!hïã¿ËŠEš¢,1şš©lnÓŠÀX/{B¨ÿŒ4ÛÆWvxC6å®øÏhß-É¨À€3x
4~ÃáGlxÂÆ{m ùğN‘¹x3ÿ‘^§ &ãz
Å;‘ T••™8ÊÉc×ŸYT=Xe~Õ·c7Òa—ã4Ì¦äß6¹¬Nˆ·sá¦Óğ.&Kè{Ï=£5ÀÓÍÉ%&Å6U
@2°D%Ì|°î¿ôÇµLû"ÃĞù0Åúõãã)mX±0Í”aƒC·à‰ğ;3Mh¿TšEaÅ:è¥ö{G"ÿÅL2e+–ØHŠ‰]FœŒ’ê¹ı¼ñn$­¼ÊŸü Z¶'(¡ñò²-õéCkÁyN·º¿"·ËûÄbÖ­ÖÏv8¹Êz¦è¸s ‚@Õ(é
"wp8|†ABh@”9@]Qd|AL$~ ıµWÃ‚•²z™Ï§¤ƒö!Ë<ĞŒjsÀ íİš?]/½–Ô»xJ{Ú-¶÷äB0lÆœ‡1cš¤w7.Ô¹ínhO»¸É‡/?ï}r„®ı'…ä½­bBü£°†º_<Yïû’¸­„~ÓWÎ;I XğnuÑşÏ¨Ÿ@‚íƒğ¤nË§òÊ36ú¥ÒßALß>Æ'´µÓŠÔXâ‘¬ŞZ›c,R´|¦-‘ü£9j*/93qZ‘â	9#'+ZÒ°¸»³‹W*C–½{ŠUßÏHÌ–Pş<ÂS!sù¡ªsg‡ˆ)ÀáöSïÉV_¿zÇAƒLİ°š"Ëñ•YÍö8 {4aÁdšª¤+5â!ûsåurÙé”æ­“µÇüş’P•Õï×ì½*0RîÚâ@€BO‘¢›ó²%2x‹iêGİZüÖf 	ÏÃá&Üvæ
ÿ©ÁÔlßùÙú±XŞÈÕ-<y€¥\±Ú˜»‚ûüş/Gj¨=Ñ“ZuÎsÁ~-äXwá•—q­oĞÍRpû§_xCXÛ„¥#Ë‹>æçäp4KÖH¥)ìvƒt±Ä/è%Š¾E"«Eû¹r\6p,ŠBú×HõEÌÀø¯+ïrN@‰ùLÓÓ•wpQ%.H®ÃxÜ<ˆïxDÈb;æ¡u[w.şMñŠ=ÅR»” —fıÊ¿<R%íj	'Œ±¶ta\y
œWI|f]x@ô¨x¿Ä9ÿôé^.,ÒöÚ•èi8©_É¹³8Û%±´ö=Qòª-¬ŒK¹sñßP‚Ò\Ê¨«Ç¬dıİM‘Ip£BO.«*&äİ$ïÀ¸n{ğĞŠÓSLº0_LËgßıè#ÖÖ*?6H‡ækcÖa¤jÆ<ã¤M±'tw¥&@‘S1yiSŠÄ@aHÛ£Ş|€åYJøX'†1Î|İmÛóU”ƒîtxåE¿KN±œAZ.lÊC×:öj‚â´KĞŠîƒÛ¨³EÛÀ½(±H§ÃÄRÊ‡´¿;X_zWZ°ÂÏ,ß*¬Ãè¸PŞEÓ[Y¹ö“:î#ËÃş9:z÷)’’@ª:-q¾w¯*—/jWâ¬©É*´ğG1mĞÓĞñDiğŸHÓ	5®—çGáÁõúQs£×ÜFÃÀH·á±!ÒÿLÄÓÆb0HËÆÊ½Dšš(½_AxdzİÉFqË 2	7«V‡xx{ôĞQ‹ÆÀKÛmı7ùZûBÀËifeşDÚ®Çe
Töv&MİõÁnÆ‰V
Ìg5F²ˆËş:(6ò\ ²ˆ|ßäk!÷(°o‹ºÖR[S bj @åë¨TA¶'ê¼¶ı[·SQ¨½©î_»¦:ĞÍYÔÜµ¶o½ô€ ’®wIäCO¿=SFzÈ5,ò4øËE<9Ÿ›2îYôwšOc¼ÍÀB° ï}},ÆÖ.Áö¶qµ^(	
¾ÍÕÔü>ö¬2ˆˆòÿöCçË½o
¶È|ÄªLdış/jJbÖPâ(ñ—Äµ<ËÇë³âĞXdí§‡ÉIAü 
Ùğ7í?}æ9AædW¬»ë¥\ÕÇCäRÛU¼ ğCpëFlS— ª4b¥¯üay<aÏhvêL°‘Ÿ™mÏHFtâƒc*³ŸÚ‚´KA¿Plh@Şêe	;ø„(éS²Pa.m<Œ6§éó®Šú¾•×|Liíg	İş.2m>í@ª0q‰®ôx…‘Œ_•}Åç'
7”R³aûK-ïÙiêÏ3X¨Í³î`İŠÁ–	0}Õ)ƒ£ÊÎ‘æU§òmıİ/Šüœ±OïF12Xç¹0Ã·mÀä•›2ÿğŒXàìÃ¥TÜè³@^ç9*]?ş¼t#ÜyşL“»•n7€‰²f~½-B—çpÛ¡U	D¸íÍMßí–MÀ•˜÷±íôÊ—Dqøe9jŞDAÉ
â	Äø;š¿0«Ğ=ñ±†F¬ˆR<Ü÷+z“ªÎP¦eeØ9Ÿ{ÒgÏÉzzöÈÌñKâ‡ÁÔ]7xPEá~†ÂŸkÉìK¶Õº™*íÖˆ]-íDªü–¦÷I57C öšoŸH±U*[ä0Ùj_²©HIä >øF*&„¼EoQ ”¿_e3÷…‰à >Mü¦ı"’¬Ş~%ğÉøgÊœxöZ/1nÆ!É}ØŠÂåkÈ©4e­>ynW`±ø1DNIËùè>°›Yæ¼Î©0Š¿í2¡ßÑ+'„Áã¾˜Ú˜lGK»emFğï†lgÌnb.ĞÇ®	S?r*«¥¾£ïûuT½¬r‚ìáÑÊ%ôÔœåçZßX7B[Ö¡Úq[&ÃÃè*l:o›p|UF{eŸg]¯Aãà”ŒÖòÜ7óúÄL‹Ø}TÔ:Gş…Ì0I·ÿ G?Ç¡[Øu¨O4ıIçzG„ÒùÙ<+Š«FÔ Y¡k2â¯†Üoèş½È»ûéëí®ÌšO‡+€OJf·ìD=M!@ì=ƒæiÂ^àÊ*oB‰X¢O{¡ÈåMœØßNÓ“WÎ,‚ÙĞºAÎq/]mkÊ
›
UÕ@jÍ?†Aù¯YÏ»¬†Ó~n]Ç˜Í7WÕRìÆèÅòzŒ¿Î¬ûZ^E »Oa©}¡¡v! á’ºƒ¯Núe	v=ns+Éhm‡É™M%’Ó·–p/İ!Æğ¢KDTTlLU•HL¸¹T(S%o@4«íqĞ!¸\à×¢Ü#»’µWË©’­
Ã¹{£Q¬ÛC!¤>Ÿ8åa fóê€¶í¡å9©?‰“Ê‚ûÒ£3°öúõÿ‡¥Àz<pÿ9L½E*ˆEæó§ôÆ¶ã­	®¹Š \ŠT¾ÕÂ5/¹ş¢^ÿÇ#ïİŞ®)¥7ĞŸÅk	tÙ`™œÍÖFšHxéó„X,fPt§7ã%ûà OÎß÷à™8i12r2£G¹Z|¸FLuôA$.µ+»…pE¯S¿@uj>‘y›¤ò¡_ãqûJx.C«’Íc¸p°¸C·±{®¢â€ÿGÉ
ÍÄ†[¶¢v¡'¿Ñ›n/XX¶ÙŠäB4è›œ­Q£$/RG¿°
WÜ,ƒŒÂÖ$C¦ {$«„n¥Îƒæ»2”^É~Òø"˜MÄo×JØ –KÄ”;eŠ:òGIÌM~/"İ	NÛ¬`ÊÎM”BIzBò{Nú:yifîeNRÍ˜ªÁ.ò6{<ÍëÇ/‘Kß!’qñŞ¾!s
S:2vbÚ£:à¤“ya±è!›ÄÆ'àÜ°¬É)Œ3=ñÀ–%`°#<¨*'µg¦_øät,ê…‘²õkô
÷¢ÀeùóûôÓÚNÇÍëi‘çeŞyÃ°OÀêÍH~×1€‡sÈ÷8÷» Á¬*ÈR­ëì6š-¿¦‰qx‹„ê7ôŞ9uqÙ4Àş<ß|†Y¶f>ñCEì,%F²ş6J&Qğ—È«MOËtxœ‰f_kİ“÷Å ¥ä:Ü1aaÚÊmÕIå-ÀÊ[ßP9¡=:ÊGsQ\ªBö%î¶Ğ®ÛŠ•]4˜zÂï-§8PHÿ+S ¾ä×ûU²Xñû¸CÜ¹LYÏ/ûĞ?„d$/(w’:Ğş [¦ùá™âï´6!Jw»Ê7`JJQD”'Œh5Ê—ˆàáU¥·„ëWÚxŞ ÒrŸIJhoï¬ş´‰ršò4KéMI/åm°²|˜ê=¶Osì²»^b9{üyGQ„49¤ÜÜLoŠVcáÉ4Ê™¾¦—‘5™=ÉLÿ¤vø²'ÂS?½î½âVˆ©ãö²F	‚üq{XØ^G"ı™LHƒ>0Q%u:ıti·.X^‰	Ñ	<íğ•´ –Æ+­ÕÈ:q=´ºR²7`¨LÈ0¿;ænx ÕTı·¾„n—0‘)AúÂ
Ğè¡Oo3ñ&Ámšª{@L´vAféŸ7XGF!:Mç°y=ÈğÔX@@/ÔkìwÌd.Q>ÖtU "|³L?ãìqZñŠ›¯®ùD“'à¨zš‹îİò0½»2£
˜½8JÆ çRp¡Ut@>C‰%$‚v¦qæÃTµñ…°@²“£°På İ‹¿cÖ™ˆ}»W»²áåL¢íÈvv‹ßŠC-v=­CŸÔœ¿5ÊBMæZüÌı§æw<$_h*êÏÇhLÚfĞü×%Z­L³ÍÄ
S%”OıôñÎ3‡N„¬Øe	$Şï6À™}‚ŞÒE¸;_ıµfw—jØx3Ë4àâ#é‚ “À97oaw£L˜”}ª‡M™o('ÚQ"í%†8Àcšæ@Ñ`©Fmô±@ XuOÇîõ†éaoµôŠP^Æoª;q	¤Y}¸‡m}X–‚*
:«‡ÒÑ×½£Úl†ğk0¦¦ÌÆ\åc3 ½6Íµ‰z¦—® ‡¹nQœ‡È%¯4¯™<k‘ïJëãŠÅËI[¹ÙM„Ğ]AÚÍÚ]ÙÒ/÷‚á²sß®Õ‡ù–Ñ,Ê™R
óÃy—‡‰ŒD=G–ÇUª„EæïKµ¥vTV	[8Û.œ–ryœÉd´ù1ŞqÈ„N…º¬á€—«”|óÆµ9³îqh¼Jƒ¶»0Uágï5äÙˆŒ$ï¬å:/]~=épÙŸ"çèZ7ÏúMU7¯k–ÜÈ»z´§4ºÔe.Û²(†$3fG¶‹pæP3¤—ÿ˜êWXH×tå¿Z—½ËÃØaOPª\Êu
[V B1”l ¯|¯!Âîí¬)&E Â?‚…Ä¡¾cğ9D¬Uà¢<w£gô––eî9n’Çc—ìåí•Àï³¨“éx5ÏÚtK¼OoÑ!WC7eáyÙX_•Ò©Ë„¤iÈü"&Îg¾Çeà<üëš²|i@ñ©óRvİ-%f3NÿÏÓÌŠs’¶ó Lë³6íÒ  ¹’Y@ÕU¬ß½ïºTîX³Š*µÁ);•Ù‹p£àëñçfägPtq3e5_[¬›ôí±XH’Ğ(I·A~Ù(Â9C ,>ùˆØ=O	TEkş^E)5-m„Üg+YÆÆèïÕ?tá„ŸŒ¹&¥1ÿ$¦=–®„¹+Ó%B=´“Y–á<şW¾äƒñ°ƒj ¢Qœ¤FN±^IqI˜ÌAoÉÓ£jéíÿ	@‘µ»,1NmtÜ8	¥ÏDÖ°E“IÙ w¢oÄ*¬eSĞù˜y.Ä–œ¯½ÿëË¾ñBwU?â¸É áL¯“ãKrô›
Ï¯Š/@¾±!½:ÿ›Ës%wÒF÷M·êyî*ÜRàäa1Ñ<?†êM*‚cşùú³¢S2X–8{3yÊîÜX“k+O=Õ]‘bŠ˜ÑÌÃóËb>~*âULøÍUÂ½ÕLÈ¹±loéì¦{IØ¦ìLJ>ä«ŒyÅÎ”yÙkˆ-9+¼O]1I:'Ö…XT<5±ªõÕå½ê„1ñÌoCÌ%ğ1ÄáÛfØÅšÌ ¹«HléÛ¶•¨ìP¾Avë-¶è¾–1Š²‘ög€†^k¸şj5)©¶ùöM‰U‰’jÉc:U”VşWx´B–E×Y=½™@¸êÑ7M¾—œrA@q´âABUíHÎ'çÈy|£}.h^< h­PSz¸Ã4¬Uoº@òI„ÌP¹DìAáò8êPDÑ³ØRÎX
—Në{.„›ÒÇQÍùk•åÚX ›øökRá½³¥º }~’{À}sâËÂ§W"$š•}V™9a°Ï¬;ÜĞÕ‘X™‚åoM;!iê”Xóa½´¢™M$óÌ³jÎ”IóÊ“,_Os} Şµ¿Ü¶[´’ÛÍí<Š¤üO>éVpÌ¸ZFm~Ç‘T÷ôf×$şK–•ïÜ87_1·i"#¿ÿkü4ó+4ìO¢`}/†õ—±ŒŞnFl}3Fˆ_ÅIì‡\ü?J$öêŒçP°F­%Z‹~º¬…Ûñ«	Ú)ÅR­Fám*%æyU-YŸÛ6j«	±–Q=àŞ­„)±ag^”š”­²¸+¥Ú ù¦Õ>Ù(#÷Ïhbñú©:ùS4[Nrl­ÊêRîx·ºEÈ‰’×ŞÍ5	¬ìT{²Èn#?†ÃÎ­bÖëuúWœHŒÕÁ©Ö>aVÿeBúü¹Ñwš™×ÇÍ‡Û¶K6“t£BCK:rÒ*¶t:Y“6uÄ[&Ã)W7ò;¡©İêàB›»½Rçš<iDêä®yçxYĞ£äÆük^´xçk{ :{ft0~ı ÒÓ^â®ìŠÛçæ&42dĞuG¤hÏ¦×"Ì„‘wk³Ÿ‰µWZĞÉ•-ÖvS/ÇCªÎ-!ÆT±©
ğÂõğ Ğ”'ê‚™[Y†?uf©®Æ³ã0HÀ¡^ù’û—±÷rY¶‹{FNÌpaG&É2»À%æ\†ñewñ¾ü¿¡M/3è«’ÀAyã\<&‡ÆIŠªáIˆ¸É.Ğ¡ÈWÂbÀ_ˆvv¢Q—s¿³xĞå‰üéú¶s@©$‘ÙÔ­=ŠSH–AÜ(rSdŸÆ+¹aÖ»èó¢ew¤¿‘Ş×.|òYèéƒĞ½/ú”½‰ƒ*Š£0/0¡Jœƒud‘W»H{0tŒïˆMã¥™?«‡& òìëÑıgÂ~àv(nÿ4gxÆÈgÁá0‘:I”Z4:5ß1®XÅàû­8·÷ƒ°«£/M/ş+‚r0,ŠïZ!Ø3Üä£ˆÏÖ¶•d=øb\ş[zIh‚³TbFrÓ¤V@¸gq¾+u¼IĞà‘Y³¬<§nŸaÑn<
ÊÌå‘êeçxZ}M+Ù@;Y(8€·†°{÷HÁD±f¨3×	T@0Á€î”yÇóÎ!ûµÍš­Ò1ÃÅ àµ æg;=ÌÇ<aÍ¾D5Øénn¨rúû:ç‘¥‡ĞxJÁú°.Håè® ¹“I—²,wë‚Yæ·¶gIˆğÔ#&>úÂÚ€d¯®lô	¸m„Î¨„6]:ß8©ToˆÿĞäª}…9K<Vá}ønsxo;é'ñ„D”è>+NACõz©}·; ³ŠÄÏÜ¼òLF!«(¹áD6›zÛUVb°¡	º¹¤w@·¢ƒ?Ãóµæ)	¢ßˆĞ¸_ŞxzábWêÎe¨l2éÕâ•ûw3º£UB?åûº¢/r¸­æöÎµøUû™jÙ& HkGê­­I&Gc$É™Ûö¹ŞõzT)ûeïøÀT5ÜP£Œ­lßµÆŞ 1Šä«R¾ãÿMlW‚‹ÒcSKx|4U%Rkëu«U½ª)ÔÜyHğç„ğ&eĞÀ@È)ü¿|2~9 ¿ä´–â’ƒË‡×Í¦Å¢? iÊc’ĞdÿıúæB„ÒuèÊBùçÜIVsÉâĞ]•Qê[†àc.–İŒZ=£µ$êsÕVÖ’·Áó ­SPkòT¹PÃâmSñ)h/ÜÜ%#€ò ¤C’í—îÑ |p÷˜©r+¨Kˆ›†=OİQçÚÿüä´ZÚPö2¼‚T¤0?—ÅÙ†ÖÏZÒ*~„¡ÙYtÁ­sŒq–t>WÔ‡NÌn8‹TÈÀ¼ÊeRÌ˜çn$„P‡ï­ÕARMÂ€W%~ÎÙÈ$^Ê¿nrñ!ç	‰@å¨pÊ¤ğv˜4Ó¸lÓja¤5I=9?ií‡9)\’C£íş¢UJ–oİ9 uòéı`„†ƒ—IŠpWh€´s„tña¨„Îa!ö\k‚Û÷RX…ë Õ"Œ®!®Œ¹#_ÕÁ¾ÏJi lQì7”uş¯Îjµ½ÏãÃ"Z˜Ÿp™Ëñ“ZÉó"óÙj\µê!6ê™¸&=úÀ÷FŠ&Ôá>‹Bß
2W$.IÊÛï‘XIJûºúñ›Y”%–»é£kä¬¾p~ùTÒËğ3Ü<‘=ò„ë¾­›³„ÉŞÂŸ÷lÃúù"¹'šŒº¿š±û_€SşK!?¢Nœ`nÕU®ój	OßÂÜèi;¤ªÍ8¤[õJMS³ëFÃª‹fÑÛ	ôq¤ñş?ï=vÔ~q\í.ø6
0ÜÁ”I8ûéª“ğà á!bÍYGÃÌtQ(˜–gp ´9Ÿ°C.â*ÔZ°/Í¿óVèqaãæş¨
x}Jÿõv¿—&uKËß#&A.]bÉ05Æb„mœAÎ¡»'ìóR"æÃ­‚ú¦\;]æCÃóË×ä%£‡?›av>Ä;Ÿ•ˆ~”¢Kó–I–‘.q&	ë[`ëõş™ÍÌZŒ‘4çuª™@_B‹Òé/ÒÀ°ƒ"/ë GÃ	]Eò½±‚H?ş ¸$¿ÂQ±6úœşˆê‡%šà ÉoËã2BÙgt?3ìZ$¡™…]{g«l4½íú6¶OÜ‹e|@¨]Z‡Úea¦ûAVş®İg!Q¢ç×ï¤´ø‡
f¦gZœüÄyÏ&”.'E/e¦J®dÔ©#w;SÍ·6¡O Èà]>­ ,ŠÕ—äÇ-²RÀ	1Ê”¾Uµ.‹&^Çš@7KŒˆ8+¥³/É–qÔ\•‡lu
€êÚşˆ*-Ÿ²_8ö^ıŸ6‹Â}½r„©ÆäNNÑÓ¸3›AY×ÃóV¾4Z™†.uŠpe@$qv‚KºûBÂL:äÅ@ÎÎIY¶—©blkÜ*+˜ïZ.Õíkúös1yè ‘o!¤A¯ŞÂıtçA~3q[7Bİß#UªßeÚeèÅš»bc÷ÂM¼ıîÉñ—¯¤cyu¿éXª[Ë¾0Û³]÷¬°Ü.öl/í±½˜3ùËõ6Š=ízÉ—#°‘Ö OÏs½\iDÇ÷ñ5º5ÑHÏõj°¹.ñ;Çwrğ¶IÇU±BªìW£Ûà¾Ï~‚3°¡
;@…­¬DŠY.«°ÈnÆ[)7éi/–©ÑË®´Wœ`ƒ÷)Ö%¤-3:t7t_¶Hú¾Œ=%0'ôÃ…AW;p’iŞíyTsj›Ë¦Î.'(OVœòpƒ’ç‡u¹<ø…h(]êL÷…ÔûALxhåÇÖ˜¬y^‡î4Âß“ÄL²D=S»–¨öp8/»XØ†Ó³@Q(Íµi·i1œA WÛˆs˜-7:­/ÜÃ[7„µuñŞƒ9²PÿiŠÔ¿¦Î í"ª™üˆˆª‘í69‡g-©Šİ5òz@VXW…ˆ;İ^d&EÚï]%,©‰"Àº‡RA³™	¢¥u6sW<¹ áNiÍß°± <jFv@ß €uZWó›êÏ›Ïôü01ÎÇ ñÎˆQèICÒh,ßWy×èóûDˆr·cMßwãmOKÎæé	7ìÁˆK²ÑX‹”iù£¹nc²öË¾ÕË‹u¿óå—ánÖìr¼³óc'qŸ¼U˜1°7éQ3…µ j×‹æ*Ùd-IKÖ—¯ ì¶İ"üÉ3ÉaˆŸ½œd•x]´Ê×‘Ér.À¨ş h¼ŸhÒ§U[—¡%t !9,¬vÛÿk€åÄâCÀO+¿—ê¡=b‹ôT!ş™rİášbïCš"TdŸóàlUTSñ|AoÊ$˜(–køv%q¦	]îéR·ÓÙu™Ú#O<Ú·uøê*¡Şä3ÁöA+N;T˜P¿À9eJøÔXŸ€ÇÆJ$ÆM­›&&xğóTöƒ©CÌHšµÍ‘‡æ–õ¢3³R;KÊ£)»¡0WgœNÙl@¼\{2-‡,h’@¯®V&üfòHˆ}ä/¦xœ­FV€£îSã
1F€ï1?^ºÓBä	×¬øz½£ø¼Õ|VJ–‹‡ô'‹Õ2~‹Ñ·æ{º6­(z*Ü%hûÉ@å<ôyæÿı—øL²2&6qÂ¦; ƒ³L^2ó;r_jÔPDY?'GdÓTbI{ŸÈeK¤ëÊOˆÖ±±h>ïøçÔ±!¨5"}bê´”ÂÎ¾’BoÚ6–´9Åuïeº£uæwç67iÒlñn©| 9€µOª·µƒ?@—û·<³={öv‘
4Ûò¨µca+ >–JgP
±5¯È'§~X¾At½ªceğ¤HôE`’- …ã]¨dœf™“£^P­­v~aä,e}e‡/LóBöx¥}©·Ó“Ûôé[ÚÕwê¾r¬n aV$¶¡´¶p˜}wådB¤aF¡/:Î,hÜ7cwgt05‰œ‰7å5¸îß˜)’^†I­^ªYoF„²M~.!)Ù/õ(G«ë=vük{e!ªG!QHò>Á
}Çµ,'AÎ~×˜Åú—ñBıe
j`‚õ 
W—’¾“³6Ç2­³à¨ãŸY·Ê÷V±f%¾¤"»=võtÅt§Òkh•KDÕŞ:r;)*U º“°Ä¹oTŸy/ ÇË¶›Ëi¶Q§º…åløjrÄã‘Ï¨lí¥ïA„ÍÕı ‡õ§NVOá¼–+~;‹Ïv€PHŞ—>'qşÕüÙòêj'—‘¶”oãüòZÀo²;ä“-t ·˜ên½×ÂhLØµ(ÓÑ	E"AÈşPÎ¨ş©'î<aÒ^ÕÇŞr’øâÎè±xny%Ö‹ b]g:«bÔ–~pZÿÎµT“69+FïüÈ/Ôº9	Ö:¬˜cv›tßtÌÆ+qd°šeUvîkRü•6¾šËü7ëv|ZdñV”,Ôí"nğiïNr}1³tÄı}=ÅGW_cÁå
€gÍö÷‡ö\väè¯:ñœı--eá#oVÅT™‡òà  g$øFØñ7ğ'2n$€¿/€öZ9íÃA Ô¢;‰°fT¬u—«(ü(…P>ˆ³c]Ë§MÄÁ+²t**Ëê½È“‰g±Ç2R³¢èğv3 öŠ: ¿L-?D6ˆ”|ËÇÎÚ>n:>‰$ã‹tƒaá^†\l3PÇ@ëáŞ±Ì”ÚÖ#Ì²ÀĞÎ¢ÅĞ=’$ÜaÑj.Àç47"_#=ÀjÚß6Kiãà£ 2 ËT°
İÀçÂ÷oü` µ¸c+©‹NÄ) t
¥5ÒÃ-»£…02c”ón-æn·\¤ä\’hùájÕe 7–¥nÃ%ó°îç¬vht©Ê…ÀÉ«¡ÅˆK,£lz­Õñ;JD¥‡¢EÑqŞ—»§k*Ò:ßïF½Ê"HV’Dú¿¢E"ï†­¸P>–ÕÌïÒƒ3Á«[ú3#wxkâu“Ê"şÃ"ŸùHà|"Xö¾Çh¸Òhš DëåùA}š÷@¥ÃîQ_ó¢¬k^”«”¹s^ŞJZ_´3»l˜E‰¤Ç"2ğ´ä?…šĞZ‚½®ZK»DÎmo¤Xğ2õù(şŞ<ÓM™4›Ûhò‚eM‚)plì—7ÃĞ+ÕÖ~·‘b[ö.êé«^QF‡Z©Q½‰2"íèôKÏD˜mË°¼2Ï5‹ØïúÀ8q«º"æ4j™°!¾Y¿Ş>ÿnØT,±,{hV-ŸóÖ`w6B§!…âˆ:µ±…â¬*[¾‡”‘R1:e®Åé€+úÀT'Ù³Ò¥*Ãr~(ìµQ
ZövZ¯O©ñ,Şxñ†•S=­´Ì…b“£ÅSoea†:*bÓ3ºcì<ŞTêı«— |`Ô“	±‹êÍóêóæ^äOˆ\A„ØÇ5p7²~¢—gô?©¼­º3^®bL®+kKv¤=—éWıç¸ß¤òc¢ªmò%¯8¶øŠfïü.öÉ„0h…ÔÜ¸ppb	ÄVÿÊˆµ~:;NFˆ7x¸Ï­k²ç^ÓÎa!uäŒ‹½øÑD{?#$ßéÉ\ÜÎXVÿÂ.=	ØÑ­¿ÀuØD¨››0`2üÆé_;²Ñc·ø¥·š©ë? éoJK(C©;@¸¬ ı#<ÜO-d4JĞ70µÜmV[W¦Ö‹Zp ¶Ñ?)_‹Ni¥ÔÒDuÀŸ¶
–£¥\Ô¿>€¸h%äZÜ³c
Oõø¤g§'„¹6Ô*Õİ¼INĞR"æ?úÑ"[Å6¦İ½°',5z@›((œ¹YË|P"JŞÀ¤îÑ];·¹Hâ‘K<5¡ğÌ÷LË!fÍx_ŠÃV=¶	Ú0ÕQ»	è¯û
›;Ñ6#<cÑé¶iQ‚’\ÛüQTU‘1&¥ÙŒè·N.LªêÛw™r0^iC=™S¼¼b{¾¢‰¢ZfšlI„ë™BN½3­®ß\‰““§l«¸%Tù2l¾%SƒøæzóşIîœc}(Bô9¡ñ/9C)®¥1	Ùï»Š÷ÕŠN¾SÂÔy¡b³’Náı1ÁÏF«+áÇÁ¥­™wú¿L®¢È¹¥y
Í¤n±I¤Ûm`İŠ¥¾”Ú×UêAXªùœ†è‚$ç7µ{¦vÉşm‚ßˆ ßí9Çq{¨’ìs$uÆKíÑŒ•”qƒu˜ÑÃ‰	ÁI§nx€/ ^ŞÜ4Óº,m‰¯Mm,‹€¬p
ò
oÏ¡»ßœìb2ŠâÚ “eà¹e0È^ú#¾n\£åd(ˆ@_/ùôoÄÍÏçH"±ƒ»+Mˆ@™ ".‰1o`x<^ Zj|„Cziˆ[»1Ó}_)‰8ßojûìıØ»éP÷\zÙ3ö{q4Pj*/'jr^p<ÃğàÔc¡¶øç5­Z+ÍìŠ¶Ï‚9nÄ&aáÎgJäÿ;q±f{ùÔ«·(o’FCF"Èf|ÇçYÇn:Š8LØ·Ÿ|7,?7h¥û5slpØ@êüªP[u¢¯Íí—¹Zı€¾„š>ÃQQ¤|'ş—Úzäø}lU$»Çn$KßÌ5h˜NÎôÿÈ¿eÒà€%ÊoAÔ®-	v¸ÒŞÎ
fN@|áæÑ;3½â‹P¤oCğ÷¶¹=œ‘Å&Ç ŞH(‹Â÷à2à³‘ÖíXdÏÊêŸë9íT†å6Sˆ¤˜ÂğŒ$¬›Hñ†Í³i½X/•|n«¡æ Ìœ©Ú‡€”Pu°ç”ºäe¥â|—0ˆ²*Š&²°)¤´îñƒÿÀ$h½iÖîË™À…(Ç;Èÿpîïù%¾EˆÊ¿ ¾*Á[	Vp†	Ë±§“él«HÓ„ïVQ‰ìÈ>VJ¬Â?d–PÕQ;i©×_ƒH…¯VG*îø¡Tü=e±a-7³2à6Û#¹R/.ä‹ZGd—¸‰G;éšz+;[®ó69@½ "§˜ÍÃk±êT{ß%’·B‰œ1t¥Y<­(¸œëê¾¶b­¶i&SÇbÏçÁİ2>ÜÏ+ÖçHì–ŞN>‚Wˆ’FJºJ²¬ä˜A‚(¼ïN¦ï |
¸
lÍzUğÇU‚ÚäßlkB¼xOç qæ¢<õ![À±u2ì¤1±'v«â¹üÊDLù½pcÈp]Ä#.¦M !œÿ®‰<±[sY½Kğè†é„bLÌ¡ªJX!QÓ+Cú4ƒ$”Im“­eÄÎoüÓİsu¶yÇ@ä>ï‹2ïüF—Ú¬Â1•åÏvøx3óónW1‰çEç>ùÓ!óâ–$|s×€ãÛ;% õe-ğ‡Ò2~X¬×ûŞ#i 0+MF³SÇˆÜ-ór…ÎğùİìBWIòí$E4ÊÜ=$\ü~‹ï8İ¶5USí'¾•“&-»‰sB¬v'·“{y8ª÷bc´N†¦¹/+y&Â¹EY²•³œ¹ƒØ
"¹A%Qş&à^´ò5×ÿtìCu¯ğ“sES‡tVö‚ì;|„Ës¸#iÀ7“·Ãòõà´ÔÆÍœEl«ÅÍ®è-É;ë¡è@r–)ùË}lç#HÎËip/í7ÃkÛa‡¬ècæş«•D8®Íœh®§‘š%Ş•[bıœŸO&g1€§õäñ$In{>®ú€·h ÌÔ¿©C°ù«W:äœHıŒjö[¥K/Œ´Â8$¤0B–Èk	Ô<¯^ó­ş:µjÃ®9Iê)ÇëóÜ…WÄİâMİ®ñ,Ï„°¦I¡èÛlw÷á‹oIs4áš–¾Mg„Œ× ªdVw\0\M›ÿ‡ÓòNã@aM©%øÏiÁd"š;féç¥äDğ$ôæ5—:•—+\pk–K$DO°mÆh0Æ4Ã¸Î1Õ¾ğ)&ÉOĞ(¯UĞ1GÂ~ŞÓaÎá.k¨Ä`ÓŠJX‹İÔé„ìGÿµqê´ï‰Å? ÉŠ3 ®°²æHì×g-‹Aq£VfZ+Òˆ5±AEA¹íÜOQ!Öy³+GMpeSïdGúL¥Ç{[f|§=ÆÖY©Áå«•Sbd‹ïºÏ¤Ô—!ĞH†l~ \L‚q#zÊù=¿(°Ü‡RU.±“©~˜ëÜy„{ôÛX`ƒ3ËÉW	W–¨©ĞfIq[`)'¡…!ciî“½j´[
_OÂ½\óağÒ™`†EOãeÈÜ d÷–<c6lîÍÈ†|•†®
#å¦GXş·°˜z]L%5ä¹§ğrñÜ‰-Çï¼÷–ç³ëâÜ×µo[ô}ƒæ¾#xñßŒß¿l1prQFÁ³?7}`ÙÃªâCr ĞIPx0¹/í~µí¸)kêïZÙ¯ûàš„"ô¥‚/ƒãOê Ü¸“‹&×îùAŒ±m"-šĞ?œV?y
Æ&÷[pãá²>-Äïí
äĞ *²O´Dî$gÏ¹Y·!lƒuhî”šµ
îÚ¿gáXàâ:z´İÖ¸;˜ª•n‡b3­”ÙÍP‰¯»-kÔ>@ğ?]®@D›šŞc¡GìiŞ0ˆ)¾›ËCvşÕpü"ıÑÈ,æ[Á™{ZrûæÅÙ®ÖİßJ®$äÕCâK¹K‹¢|‚4õ‘2ÓüY»¢&å‰Í¨2S_¬ü´f8öEMá½Û,Æ‚RR§[ëÉ>¦9èÌôí@ç’\9¬Ï-iç?»’P‹¸î|ÊnPe0Ÿö>O!Kÿ8®—òGämU‚jV&ì{1Ù—dÆPH¡EG›"¼¹şw*­zç_õŸÑ’#“’Ìä¨fô'CÑ'è5´\\oÚ‹§Û‚ü³¿†¡&‰3]İQm÷ß{WËà[nÜßÖÍñjç[­†gUcƒ,`%Ì&<®1´xÅh&ÜşJ	SÓ½ÀK0Ë@N”fÎ£¾£µU¥„8SÍ½ÖL¢KîˆRÂ»r¸«Yİ.úfU€‚á»Øk–^*¦È¬ ïÚV•|*“
nÂ`­Uß?ÒÆåI.‡Iı6ã€öb`V?g¯™-/qWî1æ§îÑX„tÙşØõZ|¸¨j 1öş‰"rİƒ¤:·•V¾ogxÒŒà¢ƒlyZ|­>K¬S/@un©Å«ïµjÚ sŞË'ô›Ô=Š(‘ñ1ÏÉH|Ûò|õö }Š‚¯1†(§İÆÈ%['Ñ[üÂœW€G}Èêæ2)ìî©g$^³ty;†k"ÌR€[:Ñ{ ¢éÖ˜»ÿ¹ÈR>|°×A±?»Êwğàú‚¾ûO]ĞñM6(¹¤\É\¹W¹©n`®ÚTU<Jšp8Úâøí<šoÕˆïèCİÉ<Êb:UËŞRs¿‰5•1C?“)ZĞ [¬Ò3U½Ä¢ÃêäÙ¬ òÃ‘D7§®Ùğ²}ƒ˜ŞÜYò9›ßÖe/Aš°ä=úœîĞ1²08 Î‰õzfüT­L|CÏ^/Ö7Hqô4×ï>)Ø^-°k™$+´ŞÎèÈ¸QÕ&o£Ò+µØgU=5yğ»×ëàsj‹ı|(DÙéÁ¸Cğ›ÍgRVÓZT„O(„.É½ÚlŞ§'æOÖÑãïÃÛ¦jáCÃ¥Ì”ä­FÎT¹¶5ønï¥òbç½šá	é5Ñ—›`¡Š»øÂ¬ÆŠÔ¬m5gúÀ6¨Ã··22yZ%Kc¹döV’ŞÙ"¿Eö¿lB› "÷ZÚ<SÊICã^à Í(c®ş×*ÑJÏHNJÕàj‘P¢{&¶ã“ı3ÛM9¨˜O‰NtéÛNb³Ãü¤g¼'´á…›¢¬á	R¼RöE¼¤#è«Ğ YZ©‡ÇÇ×ş5¬Ù­öieœã·»=5V¤IÄÊ"€4QÄö‚§òMŒ:ój<&ÄºæÎ›!/º.º¯§-€æ²OÁ¶ˆ5¾Óhk³ê/ÎüÙ£erºj™)ÊTfÁ¤:›‘6‚s½ıµ0é	ò®“2õ,w¬ìmÊù*HAR²xÑå4h–z;­£İ=•‡d€*ø“>ˆV	—S|ì	ó:åÄY(”é6:2Å©›â,f‹yùk&û‚\×"£;Ö
[ Š‰{waÇ½‚÷ZŞiÑƒúo²åĞËõâ’æ¯Ë’}
±é¡ÂÉ2c£¹p_M5Wiô4ÿqÒ¡oô¶€6;¬7lŸNçÛµÚIiö7"Ne˜^\$snãÙjè’İ\Ü‰ãÄ´à³R{ÈzÊN×J¨õƒŸıE/o1~·¶Ç±JŒ}Òn¨N<•À6ÉFÁÏş3Æõ'K•²ôıy£ëAdÎy“r
¹U~Hç(y¹Â-¦÷h…p2›åÓš%âsgõëU!5òªn”ns¶ºeÇ†çOÑš¤OÈÖëˆeÖúïü'ái]&íÛ³ÛÁßÀI¯´**ÚÍsÇNuw›Ø2J‚x^´`Z	g3-:RõëàY0%Š¶}Ç-Ï××=wµ‡€3~¸`œsC‰â¹Ê%	aY!)N+á[`6‡ÅuêbÔgäœ×Ó©5‰]fO(ÆGÅ‡Óaym^¬âFõó¢“Ö¡$éu‘²ä÷¿ZÜ	¿† ı(äÚ¤ß€³¯:TRe‚ÂIµ´r²{ä±^¾qkÜúŞ£šJX,09®`]5§.ù6Ö'çÔÊŞ|)°äì^.ÉY£¤Éo•Õ4@„U¥âê]Q•©›zf—–¿r,poõ
äj­*•ã&‹c)®§1Pââ—?&d˜‹`
—å±îolØ4æxC,1ˆˆ«®-¿¹•øİÎ	¨ağby»CÁˆHÅâŠ«À0‹,RÕ
2–ÀoƒîÇš,ë|‰ÁÓ—Îíı†1üxŠÌ\&jñ%h†‰•^_bRPıÿU1XP—ûØpR^ÉhÅ^ê¯È„A4Eì²xçW½‹¼“§Ñåæ…_m-2g6!Ó®Ôr4ñ”[iùÅšÎÃã’²iÛ†ë²„_0}]M…£Ù‚†Râ4(UJY§ÇÜ¦¸dZø>fN)9ãµ~`Iø‰l6Ãƒ›îá‚ÙQÈ3t2]a¦(ÿö‰nVÚ÷R156eÒäoÒ‹‚Áô±2,‚Hòózf—]ú]ÓŠ™ZèéGm´ ªÚ-Hå}ïúë
4féBj£]“Ñ éEx\ª×î÷,cµèİÑÏ¹-Ïƒîø6ÌA/Õ³V}ZşÚ7¼{šüoÍ;7îáÙ°õcI0Ÿ½ù¶‘ÈSßz Ÿtz?¶›ëW 6îó¨¾7n+ıi!HÙ#]¥—–[š³O‡ÿ~US’¢IİöB°Ëz4@iĞ¾óò JwÜø¹µ!%IITìÙ«¢:ºPãñ8'1â9ßµ–#$ãíC)eéæ1G9óÍJÇÕ&ê<áØKcCDè¥^w¤Q~yÁIÒÉ ~Yã¼Äİ:Q1Q(lıTği2ÅA¦ğ²qÓœ	bÖóFÛO2ò)>e\€£ñ-¹ÔùPIê1Ğ{uİ­S¡ææ Xlçd,óö“<)z	 ä!ë€<g\…áNvûg'´íAşùí™ª]Á6—‹9s;õôÀ>õç¹şâÄZËº'lbËp“ñ‘AÌÙÖOiÌ±_?lb8Ü²×ĞK_Ã]«ãAQ½ƒ³DjÈBâĞqq
Çvñİ:‘î¸;4Æ‘›ì|’ù5ÍÂ@ñğĞOqØ†"Wleu[õæ„›	÷ğs›p„	ò5èãG%n&(´2¬]8q•G7‘ÆX0õË©c3%’É¶«ñ{b^KÀ*êå[ëæ6¢©v[äæ ¥Bû>u™3QÁó<¹d'qJ¬RU•£Ú¢o+X59oˆÊËôëÕA9D2ğ ? *ÿñ¹u)™èÔÓ¥MR½`0Tã§Zà§‡æêÓ€ñ‘Wİe¯–Ãr¦Ät¦_²ğv1Ë‡pÖØë.;U™´¨Å£8T	:Õ:•p’¦bÿ¼’w©š¢Åï	Í^£ä…f ez}pÄêÂMl\$c Ua3)$ª¨ã†‚.ÈğŸØ=An9PD[eŒ@btsà%lù‰'V…Îp“"‚p˜{‰"TeUÔÃ¯^ sè§gipm¥U\¿.°¥‡Bq“tÁê3ò¼XĞçŸvüÅñ–‘ŒçlÊ¡xÎ¶#G.Ò­ø;¢¢j«êE‚îëšnÔ³¿Òr¿4¬«œ Ry!…w2ë_Æå¦lñFìâôÊg¹î|ğ®{º¿=Ï-o¡™E÷BÄB­|‰HOS’´¾FVº]’€{€kÆ7dQü°4 ©2üa¯ì÷ŸŞËHé1JãÕ.ÀÂÈ=åò¿áÓË¡®ô:¨ô”Ê¨mÑØVâÃñ2}>@=şgÊø+g–Ãe®yá2ş@ğ;Ğ¶¥fİk®CĞÖùİæpR´4‡Ú
HQqNoÜ}³‚²¾zÓº±'÷ÁRÈ‰½¡q’­#YÀ1Do*Zé5Mz‡†ˆ]|ƒ(_ÎºéĞö÷13VLw.)@©-11ÿ¿Ì‹ôqÙyŸ "!’ˆqqUQôñ³EÔ¨tJ5„ñÕ‹]f+nO½¼²“Vª¯Ú‘pã	Ä}E­Oõ(´/aÛí_H¥tÃA÷BT¸şÃ\ĞQŠ›Ğ:&Apš›Ós¤[kŞ‰µ©P æ>?LZàÍ?ÿ¨B•%/oiQĞ š»v¬7¥­ÙÂ6‹f÷ ]KhÜ;Ó&*S-´0¹İZ– Ş<¯ãFÙİj˜)<“ÚRé   2²ˆZ‹g`Ë ë¶€À üF,±Ägû    YZ