#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="991668972"
MD5="c299835a038ced4f275330aff15c4fcd"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26628"
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
	echo Date of packaging: Fri Feb 18 19:48:52 -03 2022
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
ı7zXZ  æÖ´F !   ÏXÌâÿgÂ] ¼}•À1Dd]‡Á›PætİDø‘0¹ÖXä?ëŸ\Ñ—jÇ6 ÅNİŞï]š&Õ¯‚Y¢¥ŒuÂï?¢CzFJ#6Şñƒyè„+ U6-Á²Í¿g/ÏÌ²Mê7@Áš]a[¤<?™öèrÁ¥©¡‘t”¹9€ËòíC+#§#2IƒúS™ğ>s•©ŞÓ»$!«MX¢š4ì5Ò˜ğˆ!V¿fCÍİõ‚NL	Ñ×«|°’ÿ®nia:ìäíŠ²ïn>úTt/å§*!İ{&Â¦,cPÔYÚyµ¶2¦b›'ok|9~XİĞájQ—¨iiÌ$>ø5V€DeÚûó¯Ô»óºfA|h~îK;1¨‚æ]"ÒfŒ¼¶G²b…ë«zÇ¹oÊ"áÎá\üZ|GÑÔpĞ¸îxFÌƒKf=ñùìmO%?¯®êíbÛ$k¹Õîª3æpóÙ…u„«|×›¼î°ŞÁ»nqøYUNtFrşfı$©¦‘[X®S`0¿6ŸÃ‡ÓN1ü3.Ãğf¶PbÌ:š À¢Wt^RYÊıÏP4ì‡Óˆ’¦ÇJ~udÄÙÑêğ„³;¸Ş[;—¦œi%ÖÒ‹vÕĞ`Ù†ºÍ|ç9jºFÖâkwl «I H¨Ì
FH~¿JâİÚÛ¹á
f³dÂ–£î|;$š¿ˆß[ÅÅJJã,ûl¶“Qÿ>]q”<Û«p,©óDA4Ãt¬ôËËm†g³üewë§òr¹øü(e{¾>²„ó<]¶±Şç‚~=5§²bS|¦Ë¨5“õ®ë>ÑS†¢ı>o‡ÏìB?på_F‘^Ïğ%+Â(%¾ÀŞ_oxú±Ñë(¯Yà2Òe˜\‡`æIİØÊçO£=Š‘Ÿ\MÆ “Ì E[Ñàè–{?Ÿ/½V)˜/h5—Üã<nÓ.çlÊÍ©ÉÓˆ€	–øeÊ;äø¯0®”ß’_WÿQM³IÕåv4­M»tŸ–KöV*˜Ÿh;<eÇÖTg{Ë9<Z	2¸‹n¶1³Åÿ¾Ï¶:­w‘“Áz 6{>z¢yæaèTïsŸ¤xb1V ÎF³ıáøRVŸÈ„İÎÚ­vIéZkt>[ìyàÛ-N=2´™‡^8.—Ì~råXdEpki´Ï´-VÙ´›ÄñÓ¡]4æ –ÕôÃZ/+€jëEgÂéhï¨µ!jïò‚±"N¾‚»”k—7¹÷èDÃšÄj¶¼=º3l@ä~ÂdÉRpsµÂ¿\çU*\¿š¾ê.U8;ÁEŒ§D£´¦…O×¤{ Æ¿ğv¬V§s*¡0àËå!9Ì…zq‘šÆºq/»ùZ…&Áÿ°vNIÀØ'D+«A“¢	ÿŞ< RÙşÀ•Å– ğ
Á¸PÃ'Ï·áòD‰¾!åƒ”+Í>ÎÊ¬åÇ˜!4sr40›'hÄªëªr÷¡â{Lø^ˆxü°òñŒ	OxhFÃ\º¨S×µ¹QÑPµnHcñ„¸eÉƒ‹lüK9Ì äQ\£İİ'wÆÄú¸fÍ})l VØ²×å,q_ƒ)µÊAKá°Û–2zmº+•h‰ÉÖ–?Pş+Më±BÑz ªìÎv°<¹L ‘'^yo²Nºh)t$iÙ¬•-qOÁã˜X¡œ ÷¾Ú–%Z¿ÛÂÏ¡}ÉÍFŸ,ç ß2çë5KÀJˆ²•ìĞC=2+ÙÓÆî©Û†-ŠzãŠ×½Ñ?)™zÉ¯ÅÌÖ™|>6³I+RÁƒ¥8„1ÎŸÑF…‚¼ëÅTÂÜ$³ïjGJlZö7‡)§èİF[“ &`M*
(3òÃ%EŞQ„Ş¿Éyb1$÷ı5sêC‚¯˜¦~m¼šÍ7ƒg×Pã7À¹.%‰âõ[Ì¹£løP‘¦ÄWDê•‚?äÔEövap—³‡F6ìoüæJÎĞ1¼h4rºÓJ)ßÆØBÅnÆtCëÈh¬ï,¨êÙ5=ÒÁÎ€†‚À¹]ål°9#À,»|L?ğÁ®Bîô™£š
„ªs L`Æ¿«5„0Ü`d©MËF_Á6/*&qç¾à@íQêp˜^<K>BÀçÙ¬ÁH’[ßH6=ÿ40/õ?kô>gS½¾>,±½ârsfrÔlXrü§ÈJ½­ë'z,Ñ¸ul&„€ÆÜP)* h^ƒ‹~Ê"åãëZUÂê§U½"íCğ*¼`¢õ!v®µHÜ1´ã@¡ğc­u”xŸÙÎ°¦n
£³z{’Y&Ç”P†Z¶kùaô%”eÌM‡Y÷âæƒ\Vâ[A×s€ã°|TÍrV–@@Iîë§@ØÇ Ú<ÁÇé2^|~™ºÙÓ´sŒ¬xë¥-Ï'ˆ«¢¹Ş¥|c¿=½P°á"=[è1NÒJÀÜĞD_¶ö¸+‚Høs#%èh`J6±hoş)ğ²vÈâ3/½¸¶Cu¬æŸ7IÉÃØåø%¢½=UŠÍèªpÔ§5’Ô]! c¦Ë÷Ë–÷@8ê¬ =¹êò§¥˜6ı%Í¾ØÈÛÉCøpš¦€UÔüÇ‡Ñ\"Òı“;«óÛŸ
Ì„ÿöŞø^BS{¯„H¹$#jı·€àdúUnpªYU>hÅ”ÕyAWè~¦6Ø…ÌæeX‘·-¯|X¬:<#š})Ü?Ò°SŞ9Ów’ƒİßéó\ë«H“™yGş¯´àU¤yvî›>üˆF{Fá9u2[È4ÌA‘Ï˜8ã{´ÂJE¦±~{9K—*¢5½=&&àx„öK’9Ü‹D¥’¸;lù\$ÁÅÿ¨[´sûZZ”hR	‘ıÍÉÖ@™(a£5Ãaüİ¥VŒAëPbÜË´»ÒµmÊYß99Û€$Ô¤€ñıñ†èÃô5ÍÈ)LU°,"Uui7ù¿b§’Ë°õº1ÇO}-™?².œè¤‚²&á€˜Ëîo-ÊÈe–kÉ}h¸áÎBÜŸ—íK‡qğ™Õ–4‹¬:«íÀ cŸ—p¶wŒhx–ëµ§a‡Y6ë	Gjrö‘ô‚.y4é®ˆ
X7¤I5ZÜƒ÷ó«­Ãü;U,ªj³ïâÑ­İqlß¦y"Çt%usŠ+Šÿ,·á¢×fªö%?Ö“0ø‹”‹¿˜£=ãƒíPj]“&(&s­®üÙŠDÆªÓIK€À¦^FÅZ¨…<8¢½.”ŸÄ´	ÛAªl8ÌRÌoP3ePoáhïr%¯™0Ğ«‡\€ëNN P²BYKÜàj²¶Òó±KN‘¬¦ƒ(Ïã»jkY€§"¾2Æïš»VÎû^Ö€™Ñ…Â?f>B­±I[¦<ë-Jí¾|ïâ'Œ¤Çè¢Î—BQ>pG9¹£¹,GŠì¶Wõ$Jˆ©D4Ö\HCúEV;#ñş)«&ÇÅ»^°u&w¤”Ã.\ºZø¥+;Ég«f¯gOœĞÃŠ–˜ö‚ªõ<|xi=õ®FA¶—%ĞôòjĞl‡­beªÌÛïÑ!èÍ,{£º—Ï†ŒBòäŞ»‡kèÈ,Ûcš˜ª]m0¤ëùÀòTaëWğàüo™×v;×l}¯ğ„0î°}\Aª×àâ¾ƒ o*ZT±Ò°ÕBËŠïõ+Ñzºƒ.J	‹ª|UÚ~8æY~Bã¢r©3…pBùË|@…û(:Ê†ÈµÚ(„ÔO·×Õ†².<´÷ŸªEFa¹š3ù?	2+IŒóe.ÄÊ×5*È—	¥¨x{æ»SD_{5±3º=… é´/’PoşMô×aNk	bü	‰‹¥w§[<y½	–×R~©Á€Æ¶.«Lİñ’7îkïŸ•.¤åÇY<Xİ•i#nµõ,à{Çéı5ƒòV¼nÖˆÁEr:üˆ-âÚ»zå‰Ë=`Í\î1Ä™a-›`1ôn,_·Tã,è=“‘	Î‰ÆiÎü¦3»ó”Ì_@£¨üÿÇ©¨*#°:Q)
‹öÖ˜ĞE[Œ H¼äƒ+´€š¢2¸“¶ÄìĞ–}Ê[6Ï(4Ù4yaôœÛş­¨sÔd4¤qFqUš«7q.ÍàfÌ]¬×_77ÁCÙÂûfÎYÎò›ì;ä6Ïíág'ş[ ¬nÔ£ğC{ÜÎ³ F¬tâá°GemïäÚ(hqÛ–ÎpÁK˜û°ñÀ4¼ÈõDÌ"¾¯S`[$—ó!(Ë°¸ïë®¥Æ+?*i‰S„D€Ùg Ó„MÃ”?ËpÀã0k¯¤‡Ñée#Ú¥ŒjÍ_®?éû®N—@Õ ?5c1Ôs÷FıM>&€”ø¶‹¶ X?˜f)àŒïÇfHûq?^‡kÏ	xÜ«˜ì×dUÍÒÎC“×¼\Üë—Qä«p<+VÜwŸ¯u'yµÉá–°;îìúœ@±¡ØúW@ˆ¦oƒŞ	Ÿ8MÿgQ^äËÍ_)CG<my•— ­±ÄC4Ÿ|ìDŒoß-)3ÊB~‰? !yr{ıJæl RæGÕ9uÉC<«HŒäÉ·Ñp6X]|‡ŞçÏOKgÂŠdhJE%äÒ¥YM’ôèÍÆ/D&€}„¨ÚFA£Hñ³å2²´A×½;}ÉaZó±€D8¿+ı
1²3v6¶ğædì·‰¾yy3¹…‘\ğ­ı¥¡˜j;‘(¼¤Xô¿‡ÇšDÛ¿ƒ<'UŸö”~yc]¿oí%êõså}şP.k¸Hõ­_çñå:siQ­dY`’:(s©ö83k¦Ù~qÓäŠØ pì¥Ïí•</ÌÔ%Éóæ—ğH	‘T¦¡núLt ö…°îÙ9l•Aœ•!Â!“ùm&Ë²;å Ø¿ãC	”îØÓ5"À
”,¹Î>- ró6Ín|$üT{º}ã‹êùµÙõÑÚ¤ÖI…å|9ï*ÁZ(MCyî S½EPnºKâÂÍ¨,ü¶Yå„fl„dyzªü)Sg4¾pY9ÜÁ©|9b/–mép×úƒã¿_è¶„áÕšö¾¢CªN-`1•PÕ(–Ìp÷àB"«e¬ÚØ!½Œ4ÛĞ•“ÅCüBèj¸Àƒyfã<o_àßgöˆ”Ø_?1D“¹¨}0Æ-EäO‘¢Á(”Ñ€(œ i2õ6àm©Xäp\á}á*Y¡èñø4éK¢™ÈîÄÌ3?p7d¨û¯ÿD¼Ñ®I0p¯˜#-|›ßDÚ /ŞHgIQUï<ı»Ğ¹®S´ÑI¤j¹-Ëûßvic8€+¨ÿk(}gEÔcİ"9#ÈF¢»ù6(¡ˆ†kaÀ»É»–(k¸RäL$“åFWÉ‡ü‡B-™T°Z·k‚WŒe	’K·şVTÕkãØ1ïÂ:"Yœâ&í" ‡å;Ãáä…"ˆŠÓü¶ÈÇy‹²+™bÆ–qƒQœ_	õêßè£ˆ# ¿›£k—ŸšÂqP*ù[×óÒí·7€ÍöÆÍ¦S‘b…Ÿrêïtpª'o©åÕ¾kñ¾a-æşûúD®N1ğ"Lİ:ºË­\È
DÃº†>c…	Ê©É¯‡q~†…äèO] ­`r’ßUİ¢BÃ•ûÌ==?J&äÓå—9üÈ@6¦C¹F$—´5RÑªÒ6¯Ÿøa1.ñ<šÌÁHN´¸õJí:M&é«mP†I–•w‹=5Ğ)pej7x6B	tØg—uü‹aˆ"Ò˜äS¿^ø·Q8ÀåuéŸ9<hYHÔ,ÔKÒwÕñÿ¿Cp³ŒbS[(¤O:‰<AªÒUM”¾Ùí@H6´òyõ×…‚‡­ÄSVÏKRY3ş ÖG‡ë€¾^ZAe_§˜KY0>ğ™û;×Ên„ç;Øw˜¦'î”˜gš±Ëï	´©v€Ny ãC
ô€—Â%7s—olBMÉ™åß®h¹r¾[¿8•dj ër»ı}‹$Àa#Õ¢Óâ¯9H‡A¶&ãj·²Ë™ÏÌ¢rÜ4·Uvl¥g·tÏÅÏYû§3Ìü×¡=«õ\¾flEv6=ZãA%GÓNœ¨@qº'©“·øŞï=â‡ëiµ¡gštà­ôîÇ‘È,¸¬­àWÿÉ1Òg ‰÷ÆşùH+‘[(ÍpÕÛ&ÒÎ$¼HPkOK¨Swõ³YÖîE+9‰l{ïæ˜t@âc[^·<ï€DNp5p¬îº½O†m€¢ÅªÍÖ}eÎ2v²X¸p3¬¸L’†*Á”…¹ßiAáNI-Ô'3×;õÊxNmlßs¹î%êİ´Œ¨«obÃÖ?Ÿ†Ü3Ãa¬ÊİQú73ú_KI:Â’Å OŠm2i»°±î»¼÷V26ÖÿDg\u6vPq$¡7RGLÓ~¾şï53ê?°Ôéa©½ü´Öğ"Ş˜eX}HĞ’õ@ºër[­„K÷CÁ3J–”‚Ä‘ÚÙÏ¹8]€°’VğöÍ‘øfÆ•L^TdXï•®/v*¿wl›İÈPÎ$­ĞÙœ`&“øU5ßDâ 
EŸ'oÀŒƒ7N—ê G9ÊÅJr|ûWç$çh¯XÎKÜéì+©ìîÅ_VH×¬·Ôùòç‡Y&‹˜í{ºğMš6ï(©ôPF*ô‚ûÓ©	ê"£@YÄ†@5£¬ï^lv ‰"õP;è·ÜøÄÉ«u¯Å|›Di“)‚Év))P_Èe—ş3!Ñ³²Ã˜]‘ş;F_9X¨¨è%#éÕz??Ğ
z»NUOHÔïDÌûÜ ³Ü
Z–A—ûÃ!™Fx4/î|ıÊÛf×ß Ax(¿û›VŞNÛ²S4Wj%}l%#Q§÷¡Dú…kÊ­ìÊ+Ôt‹~}fajˆ‹:ÿş—ÎÍì?ïÏüĞ¤qt~G
‘sÙ#û
ğ=ß;góäìC²Òáh–ëgÙ-Ó‚G¦ŸLè¸£X¥K„“ûè-p›Ğ~¶%­;ôTc–ƒIÜå3È vÂúğâM}™Ñ]|ùÙÔ;\EŒ@åŸ;N áoµQ¯™k‹ó`Şº("ñQ±ûC¡‚€H`¼ip˜gÆ«B¥Î$!±ï<½†áorYË³ÃÙô“±,Äc÷LŸB—4 5d–í’sµ3‡ecÜ+ÜG#â’ğ‹œçÅ@`%Ë‚VOÈ˜½NéGŠdlğñv×Şá¬aûÇéIâ5ÿ­9ë±†ò‘ç\õLÑMÆIŒ˜ÜRR1AÒT5ô£>Fvä¼°á2]@Q3ú!+ï'Cñ
AµíísÛÁ6Q¤Ø]ëÄ\kÊO~¯Ùå”OršŠ¨¼ô)'Óà|Ÿ}îk¬ÑÑ)Ê­K²™êš_j- m[b”zÄˆÃO6ïšWUáE|òF|qö€à*¬^÷a¥":=Ä{xêU‚ÿ‘DÅ2yS)ù	Ö²†XT-|.Swğ¾]ŒhşoôZ±â.à 7ëË¨­8±Y¼Ûœ1q5n»oi¨'`š
qı~‘ÄØçÀ`ÌêŞ®¶ªm5l“ŠÜÿx|dv9ìŸ»w{]ùÃWyJ¬Áâ.› |1¼Á=Âk¿Ú$ûZ¹^Ş[=¢†“å ×5ÒğÆËrFqWëÈåkŸàĞÓ¦µ__¡¦˜ñ ¸*èkÏ«_2t•Åü±,1‡‡@ôÿ~Q¬§|ÚQfÄ½×ç@5ŞMii„\2"5]¯1À“”9[,!çk}«(ZÌ’gü˜¶?$;„Œjµx0#¿ã”S™S0¦Q[¹1»vHw¥¨TÄ4ìšDãïµxvÆ¥¡5YƒÙ'Ò—òq‹†…=ˆìÆ‘½ÿş¡Êj{ãe²«bñCJNÑ’áişøD¹Û÷dvêx£Ş¿à-_LEùy»0<yiê<[W&æµ%?÷¥¤ôE¨¶¸+³õÍ&Vy“Éx G—›'ÑË>ÃOıÙÆö_¹!wì†T?3©`@c‚|åLI¢IïNoêÿ^ì7¡Œ-?Ãú+â¯n3aö˜ê3ã8ß,¥œ].U<BKí663—Áİ1X„Â¥ÄºQGÿs‡Çí‡;´M—,Ã2ÌÁÑs FbğTôº¥ÀáÈ
	ß¥u^óò—(ãä“¤E)ğ2ÁY×=¡Íş¼\ğ•FL@¦	{:ö1ÌôN™0š´Ç7GÆR^Æãpšş²›EÍİ:º¬ø¤C¼U*|P<ÜÕ®x›ñX”â£TçÅ6-aÆO¯»É3fÎÕ}ê
UşF,{Ÿ„æBòËıò×ê—¤ƒ.¶–Õ1ƒ•—f©É8òTÊC/©-ë*û’ó•sL¦>„ù1…üzƒ-ºª2ªµ—ïXÇ•–ƒFÍ¸÷³z¸¹eíuØIôæí÷ä/g£{ÇE9`‡
Ó-zÕG_==…G­ÅZWc]9T9cK©¤›Àyã±÷ƒ§ÒáïšÈVÃµå»´¸Mœ??¯€@H´_oÙ	ò—`Ã®’†"[ \ûÔÿ[m²÷1û•È™ïU2dÚÔ¡lÖ¨µ…İ†$”ÓQÜ^iÒÁğ;Ç÷2ô/@µw”õáE.q¸Ñ!A[ş1my]w0,Ş$à±Wv4ÁRg‡Ô|·•ë†Æ•±"¬Iûek$«|»£ ×GŸS.…{òÖúù§[÷h¥ˆ*
ÛA~ûQ›èğÿ-˜öÒtú =t^	¶’,Óì~O$a7°gkEÁ Ê¼œ³ÃBÀ‡?fSñg×£Şœ-BRˆ(/ÜUÅD\¾T[]‘2ÆxF¼WñÇ—¯û<Šİ¿RçÎ–¸ÛzÄé…;g~Çº÷UKË›[ÃúÔˆÁ¦eYEúHÖ°SéQ%oÓÜSÃ¦²„Àà,õyŒiíS¬l—ş 	ãÖ4ê Ü¬T[4h^‚Gê.u©^RUàÂPóZ*"3/{'@­
2¥Å)GÎ™]³UQêĞæÒkãåŸb7dv8vƒ˜ËâúÔ!=8ÿÓ"[=6ß7ì–å¶êÂ5ò½ù—Æ®liå½a­P aq"ü|#SSİ™ú¥V}ó‹Eô¹¡I’P”ã¼L©¬ƒË şË{è‰ñ_4G†š>ëıs¡“"ŸWOœ­¶O„¸#—‘‰¥/Šl8°ëu¯Ba‘ªÿ"ÚWªÂQ°îÙ¼³ÜÍBËjBÿT4×äÂšŞwóSWUîÕR+¬m2ØZ^Öû°›~=ç÷íÇs›ˆµSœ×ï\W«Æ“q}©Væ5j×8µßÄ'm¥êı¦'û<(_r¾+‹­E¡LXSR¶r³;7ø¤Üm?ÌÍ¹d…‹FtŠ|–8wƒŸbFkğØÊ¶QÀË5oF44³7ÿ|Uˆô¨iŠ¼ÈÜ‚ÏN ‡ÓÃ ZªëîC¤œˆºÒâJm«cEÒHq kŞ®íJ[KC*çz§DğÈÒ7¬eª!wPE-d¥®)\ã‡ÖÜ`ããÆ³"é6?&CÖ 7äW¦|°4²ÉXçAxXWÏRİ£Õ(+œ€2®l ¹¨ÚÕ	¯”îÃIÀ©6ÛSÙQ<ç?s¥‰ ^×vö+] .V`Ê(´1“)Dë%2jîõÄc
”§—ñF’M,,F'3"¶i@¡Øµ’AòdğM0Û©å²r¿ªï­˜é&:ÈÒLuœt}+®ÌØÂV† ›{~xP`ˆ|•ü}*kás[™2*Ø[VÌÈæ[YkÈê7ŞeFë“åì‘
ÒñBnt¡«,sÉdüAƒ4z;<1…*Û­9]SvjHFb`ÜÁ¨u?ßŠµôî|Xşì½^S«l¨~lÉß½x4—L!W*’>)Xá–cÜ²×ë¦¿±¾†9‰QøÈ¶%QDƒÁ“,´zæ1ç¡g°—Æært·ƒdó£Z+“K=P’ìKğ„)?îP¾%XOÂx²-2In[ÔÔæÉ=AX^®u–ñ4àÛÒ*µ½S: ç+ÛbÇÑú ›ÿ’ç}ÌÓá±y6ÌÃ«îù:‰}
¬Ö©óµcìVTŸú®]b"wzËÕµ³µ€SwG®”¾_œK^ç‘jërûe]«4‰}¸ìë½W½ò@”èŞK-pKe»CÀêJ¤Êâm°º­èLó¬Ë6¡'û"³XSÎo4ÖØhº#yê’„Aiò€ërqò|6¡¢ÙÂc‡ä~ùÀ8tøJNÕî7Iš=ôFJ³¬&.“³#D6»S·_Xq1Î‡¨Õ;©¥
T<¯¶‡…ÂO[I¯Y ×ş^Ì†ØNrh±gë|E—û‘8œø$ü¦LQıó°¹îs“¬R3ÿrâ0»Š]tŠ½:¾„ÚzÄÍ³Vı•ö½Õ‚\¤X/6–;˜LŞ•!Ïo¡åİä‹?"õ`æéO°¾êÒ{[ fÌK¹zóÛ…âúì;#ÖB(ÉÜcıè¬}ºSì…5ªXä…ğL=ãTd]*«2MGö¡µ !¤6¿,ÕÊZq>¨®úu¯š^úÅ°û÷'T¿›J‘A€ŸÈåjÏ=0ÍÄ\^Õı…»lRfSë;Kèa\’Ö›[»Ráˆ`Á¦±eâPÏÏ°™%rÈÆ¼–j;÷sî@q¤égèMi¦FØquê;fäaiN?²}5„^* í²’Òhiâ¤Ïévşóşôá ÙD`û×r4œ†;ÿ'vV¢ÎCY`°àlï7+R>ˆxiœ,‚´î\W!4æH*ªNx8°OÊLMó7E½¦†Z.øa\í±‡Ğ×¡“ôÊÿw&é”Á¦˜8™q1Z­w€…«“óË^'!(Zœ?ê¹ƒFÄ´Ä@wU'©>67‰İ u=¡È“¡Û”\¶ ÷¥2=ÃrEÅ_¸&Qù(M6®İàó Õ¡Ë¯9Ør 3
Lj=Ï«ÀáûC{Ê¹A¡œ/>LxÍš€àaQ½6ğ€ƒ£éã}„1—ë	·{ËÇxj~şCuuF)ÿVğ`N‹ÇJ~±ex·½ºÊ PÂJˆ¤Çæ‘A¨Úd ŸæšúWHñf'–ÈWë¥z-ÒC›5o¬—cç.ª“Ë‘»—ÛÕğ—¿Û ëZ‹û½±i\×ê;€¸`ÚHkœı´cË%ği…´wè ¤6“£Öé™ğ!I½R4¾<	"÷oToW<°%ÄK|µ6ĞÃ8'ãB¶+j  ô¹ÉdÃTå|eIñg ¢ŸH‹à;ßŠü…Yõ.}ªU€JüqØPÄÚÅùîKmFkd=ÿ›á¾1S\>µcYN'°S¬ê0e³ 9¾—üg„SgÆ3M«ı-!jR¶Å‹ÃrŸìıÄ6¯Â:^|¨.*)L=°ĞÏº~ÄÒC=N3Æ‹­•éC®¢ıš0_c^ú*¼3-—"èı(7æ˜¯ödĞ+:‹îOôÅ³|x&àYQøÆ?=B2ç¦b³{§`¼Š=¾ó3Q`L ÓÑÈ	âj¶€¶Í«àQêû6xÓzğõ® áPŒóƒÉš£ï_Ù”a|1>{¼\ÍÓ{«Èr‘iâU¿E¹¼- ·gIìê’|}/í›,R7÷‘Æš.lJğ9–†ÒvxpÜŠN™Åö¼Şc°Ãb6XÁk²ãñnÖ%®¸·x$U’j¢6_º;Ú?(^Ú]Ï~Xse{§9ÂÛªH@ìtV@í/:÷e³•ÌĞ²€¾—ş€«\ã·tcjæ¶|{à—ğ½G‰98¥ÓxãGç±3À—cI.reh5™Ì½·èÖõ7¤I±y´>“n #¹rÔ9€ë5eöÉ“i.ö¢\îLÕôC»Er¤$Kó31}pgK4"¬Ü³Q_Œ![aô5-Ùu†Şo(‰]!­ÉåJşo¶”z"¹¡×·Q:Ì»}ø¬	¾qÕ¥şÄú®>é_m\@Y=INù¹x‘G¨Ûq5s·%ù@ÿ%º¹UzÇ±î’eë˜ğı:ZºFÚ—‹Ö÷Ü2WeùUbã••´ÿ
]Ç´âÊ„ßöÂÃ¯áNšC‰ÇÉSúZr^Ë$"›zV)œøó¹3(­)$¯%ÏªÜ/+¾:®0e`Ëª5„AûÀº§Ô|÷Œ /ÔÇÜt9ï4[sÁº½Œ"$ƒ¦µŠ;€r‡´»¦yw)ïÈ]µÜzeH»‹(l'' V¢Ø®€¥vWÍ~¦äHÌÜ$Öäp-y‘xO"`@Z$Áh"0’rĞÀ²ül¡ëŞúâÌáf\´¼‚F]	-ƒòì5vœCôœßùs…]”çd #~ıYéÖDÁI°’Šo…Ó$Pá+r[š>aà±
ï¬wM«8|½q-6ú±¼·Z†ç®.6åğ¶üNvŸôyg–J¼*G6|¬„‰è`Ë—U,m<öKW;“Ô«!İ°åáOß‹’këî ºB/“ÇÿG¦»©¹/ı3òKI~B2²—Oˆì›Ÿ-GÍî2Eõ¾Õ·O˜w‘ÀØæteŠõ?X„å[Ë”Šá‹A»¥k¤õæ7p¥6ÛhpG Ö×”xlm¶ÛîÙkÅ²NŞôU¼ÅÔ‚Gzÿ^ÉDãşJ'‰h±2¼s·*é¬´7×°ğ8z±{Ap¼˜sü¡åpr¤Î÷Nûşª œ^¾¨H²)çÒø+`	~»cãøöYòŠ_Á_Ár”%¸¬t(•iòÓÜi2ÜIø[zßYÈÍ¤q @§«	àz”tP8²X¯#¸mwëõ,Fšé ©è<¬~˜@$•äŞXfz×T—ùâDBÃ!¢h¹4ÎÛåqÁ {„ıÉ‰¦" Ğ¨ ¬"™M‰J¯…$5u_ÑêÚVëb:6½_8Íõš3Å¤i$†>p¨ßàÁÏk‹{Ö&ÏãuJzÃ× ,R•`Ë³µ°UşPÖ.áÇÙy
=c“Ç O/šıÚ) "iÁyZ40xëò“„’õ*1ab<´ÉÒÅMK×úĞj™ÄlíƒûJP¶²)Ôäó„|Ê)=·É:€ĞækC'‡óuŞsÖTÚÏ×ÕQb™x)`˜Ñ3»	ƒš¸şG±“¿÷‹d ""j1ğS_¤C*ÅŸòÙöËvVÔ]2i;-KYØxmÜãé¿T }Œ»­²`‹€8—£\]}í'‚åw«+¾«­mèÎVM'«:]u³„‰ƒÀˆ·$PŒ³»Ô«‡±¾½®Ófv£’05êCÈy÷”İmHra¥ü½¥Úµ$é¢ƒå\c¬ê‘ù+ãúUkãW4Ñ„yaÄW´yWÌ— –T£ËÆ·ìWjb†ò¤#®?²Ë5â¨ní%hY¶n¡Haeÿ™	ß1È„ Jø!“t$ZG1~Š®Œ½wØ&İ¾iBbÙùÔ‹Ï»9b!‡ä¶¿1½‡é‚¢²Jq“½İ¦+eÙô”’ “&€j‰‚”’üéİ…ò—sÀ+…¹ @tp´+¤ZnØ«SH„ønÈMrø„V	óq	°ûQçV±ŒlúmÅ3îİ+ü=î¼ñ¼ì"ô¬»ê–:T…4„—˜af<,l"4Ab›/ómT.|Y’L˜ªqmEíÑñÖ™ÖÓ¶Ü˜è	qÛú·¦BXc®¶’*å½g{šÏ}±v¯•°Ã¼Ç(œšŒ®í×Ë/ 4˜ñ™•BMr4t3AiäHÖ€t¸+6§uSëÂÈ“´´³±ş‘ïfWNç3b;§`ë¸ÎÔİšæxóZwÈ_ØÌâõĞf1>:š²U^Œ í©’ °Ùm8cÂ’É¼Ò·
=£´€Oğ1àP÷›Å~mÅìuôí ê³¤9Hã@8ÿ–65[»	V­†U»$ì8Ô›æï¹bşºën8Õvµ}qS1İ1ó4*İ*FİüéÚnL°Û¯¨—/u}T¶èDÆl•$OuLŠÏûˆUZìå:Ÿ†ñ¯ñ'†í´ä/6Ë‰«Ã·C#û_UsLÄkİDTííqyuı&ÑµüoRò~¾âÚˆuù?Oh¬¨â ÎíjªqñÔë+‰£çDïƒg²OÔ—ñõvÕdá‘ä&E¦ØKíG8w¨ª~Ñ÷í!M¸WÑ28ÖŞ«?±Gçt™Vûª~¼¼ÊÓµ1«xŞÏ;Y$Ğ^ŒŞbúšlè±Ïs™{ÏÌÊ÷b?yøÒÏzÇ…S…L‚à]v+(vÆD²KK}êkXÿn6åù‘ÏöåÂÉ$F¬=î:CÙšLäAŒkÃÄ×âåékÈrL·!^êêt-ZR1•{‘ê»(¢òtÆWV ğd ‘ˆCf=GˆHº8Z Ë“0kÖ,¶|ß ©˜ÛÚwÉåŒŸÊ;ËãçÃ†&»š7yŒA
$é	½ï Æ~øxÜñ;>³¨Ÿù³mOYùLDeyÜÍd-a]A¯ìi¿¿ÖSíŠğÒ»ààâ‰­CÏÖÛk×)›÷ÄÁi{
¿`éĞ¨)~İßòK[Ë£3zšØ§x¨\àœXQuYæ¯r–“j+€®57ÍD=¿jP&¥…m™ğÛÁÑ$JFj~°6t_/tIV?ÜêŒŠ‘x_U¯¯GEÀa4p»M*ï™O¢2ÇÙØ;g€v=œÄ‰µ3¢Ñ£!–¥,øÅ­ˆJ^ÚêQªA1¨5»ÔLC@Z*q$Ÿ›”•,CÂ‡'åÄÂÃ´(ş„ÔÁû…æé@¸ùë‘±d ˜‘2	pW:‚äqt)¦Qİ x¬øYêz´o%>Î’Ÿn†#ÔAÉ¾b³m'lƒÍµçÇğÖ~¼2KE,_~÷î¥Ì%æ‹¾½PWòHÿOãû¶Ì—ˆ¥ZärH¥ù8p½UÙrØúİ±2xÒb†	¡>şöø|-¾fï®GáäÉN£|Çà4&Öj1aiQLÔ.64õ,2íôôÜU•|‘cÜÀ„·¡ÑõÛÉß­U(HŠéÛK¢†˜	ÅP¶}“¨kg§HçÄo±rùJ?Iï>ùäÕı"%>ÊpÌÌ_UoIhQJ×x‘UNú°µN«œ×ö¢lkMÒÿjo HxàÂò®Ÿø¡TÉÄó¸&´Âàu‹ô"Ï©K	©•µÎİ0ê«@Uj‚Ã¼ƒ<‹ö¸,t[Ö*.´Ğ[ˆ£³—w‘³ÖvWİÄÒ¡>$õwPqs&js¶®© M*iS+ç¤EéaE5g o£©¤Oş(,â=£e0â0Ê¾ÄQ½ø@XËi‘4ÔÇyñh¡=ƒs6°^©T½-?¸@ÿ‰úÌS!$­£.L`¤3äSp!mæêÌj€Üøta¨^öéä	6+@&EjüÚ)ûÄÌ9hçÛÜìfæu‘a¤&n‡üQ¡€*C-ÿr(ËƒmşqZ»~·>åšo(À<ßÏb—|2‚Uà[n$ì0z¯m Èùc‘oÌ¥LLî`{ê
U¬öºÛàB¨5~o$¥ñhëS¼mPË¬åìvîb·#°¬4p:RòK$B4hõõ–"V#“Ù÷#.Ş÷Agd=íÑ(ã¯!Æq˜E÷’ômı@–Ğè?~(»Q„{
=ƒÆ÷î Æ4ˆãŠ·>5]È˜°ŒÑœèÏÁ·º¹ù±à2ËN@AÛ1©CÅ|¤¶á‡«’g¤£NH¸$¾¤ã+ëeîo/qÛ¦VF¥•ÆÜ™èaº-¹|AC¶¢|^éõ˜º#bÄÆ“™O9Tï ”1‰†´·5Ö|!â»şTauBµ„;r5”À0°âû¢° 'UêF{¢Õ‰ZÄ»óğF†µG‚‰böG.1÷—æOéîÁ­ĞtV'âãj}ÿ?ä #®E¢³e‘Äñ<Bí¿xsâ<º…P6Ø©‚`S6*À£Ûß£+ÖÂF±èÛ_œ¿Ğ¾_ÇŒ†‡LÂ}D¡a2"Š“¾Ç‚ê|x)u)½ï‰¥ß'ñ$„ş0&™_û³ã7¿3şà‰Jÿİrdw¸¨“6G“‰ãÁˆÏ*€8AEX½Óıcéì¿úe+üd t¢QIØ^ùxóøì=½{UõÙäÉÎÕÂÄrÆ¿¸aGau½®s“!Ïçğ»d3IÒ:1²tMZNÙ]O}0&HßmÍ®0#Š*o™®÷IOÔ±O…pEøAÆSYòÎíàCÁ»ñJ?hÃ €0íMZ´_À¬ßÆu±Òû‹³†jË÷Š#•è¶i£chD³kÏzú¾±º‰]ö©ş¬fñ„eA¸Ç$Î>ú§#†¤¢x°(0ŸuÑ×ÊúÆ$`z@çÈ/ ò¹v™¯™^à‰M/iš`ëD`¶¨ëìJ4ŸÑ}æ6—JÒ$$î—€–1Q2@¨y7rFëbš%HùÁä <òËõ˜/åâR²lr’îzFTDMã Ÿ•ë'4 ‚Š/øçã?¾	b¶Ú“.€«^lÓ®š©./A÷'Â\ºÀ7 -“]ƒ6î„£
$
]q˜è§ò%£s“T° >6ÿI$ù.¢Ÿ$æ‚Ô|x÷„x+_zºÑÖt¸W¶h±âH#ÌgwßlÄ{<0\NªîíW ˜ˆÌa§z–Ùîø >Qlˆ9².+¬Jc'<OÎ²²:(ª†2ÈË^²1qÚ:¸åA9{‰¥I}€Ñ6q.|Çc”Å3PïÁü­P¸sÜ©ú_	
¹f<@Fé²×2Ú“¯½ÛÄí½$ÀHŸÍô¹Ì1¢9Üb­,5ÌZÒİ_–%2ÚÇê
úíApFæFÑ$FüedÁ¾VµK¯¯4Ë'Úa9>P(İ¶fŠièx[¢i;v‘+¸vîÜ2öÆááÆs¡£ö,,ú"Vb;È-½‹ŒûN¼@(\R€3›C8ú¢ƒ_˜ÕÂSti%}(àÜÛµ!PúéZä1-{3b½&áÅ~´õ“°Œ·TYŞÛñPNä&†«
=Éa…Ø¥uì^˜êÖåvÌLƒŸY³kğ”=û_ó (àHÓøRåsQì©)f1iªî–º\aè`~‘üfé|Ç¸B¡ŸC´&ÄÎzì] ÿ_aqÕu~×CpŠjRçyt:
'oEaş†šYşÌøˆ?v;¹ <·BÍ-Ô7RãËÂunıë?PÜûòv]+Ù
ÛN˜1Ì(‹|Ì?síˆeš•k&®Ú{‰Ro¡š[”¹UBÌH¢FsòNÚö-Ô¨îFÎ –©"_[Ï%º S}qâİWÍŸYåNEùSë·loPÿÑ~ãg§P¿ë ‘K†µ@Îmä@u¾«G÷Ş+à’MãæúïUÜ)^rä6`¤ÊQ/€ü~4'(pÃ%Y$›¸‘Ï\¢wf~c1,¯Kû¾r<Èòmî(cÉ)Ú¬^Z`„‹BÈ^ÂØÆNp®©ù—×Õ©¼"pªnú[}İGÀú‘
®ôPğ»j©Êü±Ó|0Õş¹q‡á›Pê¥e_^Ùè«å°éIhj;¼WàZüY/owí‘*³ù¼î~â6şéé¡ŞätĞ8¦@*­J0Ê|¡ƒr¤í@o´İ|şÍ ¯<-Ğ]¸üã§ğ×±B£‡^¸Õd,C6¯'­ 0xÈ'·€	¼}- ñŠxÁ­@Ä£ ²ÚY­ú`­¶ QIË?í‘”ôF!ó¥’Xy¶ş°<Ç:fg-/£5)ÊâvÑsÉñ|K)rÂ Çˆƒ$“ dæ:æ2ómhçš¢J¢ÙBëXüÂ©€´
{Yßÿïïa<¬oiå%îb1—ít_­‡e%­+Ğ‰Êqr1"'#°‚ìf2Ê¼óBfÄiË¥â½lÍ %ÙªÓ«¼yÃÌODRM.ì0zõpÉ×ñj[ôar ‹±æ“T4¶ÖÜõ‘º
ñgG’‡C"Àâ‘¬ÉvÑw@¯Zm¨É¢·œTKÇ9¬zÖ,8‹h^İ/Ó•àL¶r+×î³A+DîB¨t®Ì¡n’±z13?ñÓßQôÄªu,&šû3À|“oè=½æ¹¹i	t|İ¢ç:·00×„ì„È@3NSğyóÏ>¬£$jçUl…x!4_6„Ös×¾Zÿ£{«î(@Ë6YğºİÛÈqZÅöİİ½8,½ês9B9rÀC$òŒ‰Œ §ßaÑ,CÑ™M«Øn{†˜N—[ÙV„Ku±´<'7ò7_¥>ö|ØçŒó¹Õr/8×kä
	×NA&VÒÄ~¹Ì?+¿.+öØÆx=?·îE{iãiÂk%¸8	jÅª—zX¾ô1ƒZkš½ÇC™`|ûô¾'á@ûşè½µö™ua3ø¼ÔË%ğpœª$kl©4ê×†³x¼gpç¹³«™à/ÂH»À‹d]ÖÏè+ÿ•¹(Ğ3÷(a«7çŞ—Ogíx(ÔÁ€Úì±¦`&ŒD¿ÿ¶ÆCñ@ì»CÑ4z<‡ (ùÌX¨[`òşJ˜§ “4¯Ç–Ú—Óî×›ñŞ3Iì]¤¡—R¾dÇ"•\áQÎÿ_µ«Šåëº ñæxìû)#r{?¿çÏ±¿òÜ&ãZ€M†vÜNÀxæævó‚›w¢İm'Êp%ãéÏj…Õ8 %ü 4»˜+rÚ'!åWí_¡>j9„ğ(C{íğ&°)XØ´jQ! @qµB¸+ÍË²úfˆ´V)Å†3iB‘ÏøæBåÈÈ¨nîA‹Ô†HÓ<–±}”‰X™e¨œ#”WoõQvÎr8!íx¶Ë–Æg$%Ùw{¼#Ÿ[şÈ¬¯TA#ãIÇYŸ¬Ş>•@8T2&UÈ¨
YU„« 8+ºå:R§·åRkCnJ|m¾$¥²l„œ	¿uòr&Ÿ¿5Yæïó‘çCnNÃè”˜U%ÕÂŠ;=©ÜÜu¨y¨¤›	ei‡Ã%>¡ZâoÓa’ÌwS—Zï+òu6}ı@ÓE+S"â"¾Ä*m§_ë5Ù6<_bO8¾ K¶Ğ€'ïÙìáW²ì<T‚Ü‚ğéš¥¶¦G^ÿ`c´G";È˜êóç»‰µŠìIgÚÀQ2µà¶ ­ ºk-³¼•öÒÏàîV·‡”ßÂšÌÀ	Â¼ŠÚÃÚeg{0l½_“şŸ_¸ÿ‡(Ñõlëû¦ª7'jè}<¿­³¸£ÉÊª[=pO-ƒƒøªLõÃ!õïÈkD|ªb5*)gS5°©$|ßÅgBOfİËo¹äârÿhF<<;¦ÖnFKa0L(!‘Ò,Ò‚5vğ5'‘Irã­Ì*&ş]ÅûMÉ×c%6{‚¾ËÕÊjÔD$ˆ¦+Â¾J‰w·0ÒdxøâğY"Ú‚mTàî’û?\‡¡Úø¡ÑXD×/¯±z™mÈ"Ÿo‹2¡‚‡,ÃïARLØJÚ-U´¹ø²ÁfÄÊ@?,¼~«·¹%æhE:mù«P354-ÄT×Æm€ÎšNU‹O¸q	Œyv°‘—¶NÀ#©pæ¼g{°nCƒZkûÙiÛr]üÎ±…Ù­Ñ~Ó™¼ÃCyËöVmaÆä$+ò©€İ‘ê?¦"…ôB±ÿZÿ +?GûãvZÓ™‚Z£/\€wL›¡¢fõ„(Y~ÛÌóMçÂSzu‹›C	ªnùw8@ñÀ<·?oBÂ\­ÆDoâ	'Gùıø$¯”×?ß>€§îÔ«<Çxµâè‘ı˜MƒwC’mPEÜÎÁGÅ§
;ÎÄVü¤Ô»È±ûV>U}-…‹£90f0!2ãç$Ä¶-|Ş7h]?MVÚ…<ÀıTÕ˜tù–ö „á]Ê™<$±¨…®ÂRË_’€ı0@ìt¥¸eyê´„Ô"¤>5²’ÉÁÑf>¥¬é¨·‘{„ó¥5
3ãciÊ?^2i˜jÀÉOµ¼—hØ¶gœ‚•*Øvé!å'Nü½4Ë^¥|°kfÌÄÍõÒîZô’dØaÙ{¾Ê~‰¡É[®H}£hºÁ"­J¢	Öe¸ùà©µOòñA £|Óå~¸¢÷F76rû“ÅcéÕè-ÈvEíës›‰Õ¾°q³Un ë¸uîpg[ë+,èšÄ/æÿõğ¾ŞşÖ‚_JôôË<÷éï	é—äÒTlŠ«NÏrÈ'k¨î­+Ğ 	rÙ' şG†ÿB´Œn+PàÚ´òˆ¬,K+û\_Ûû}ê!òĞp1}	™İML#èM¹h…¡vp¤›V›6}»Öç•-İZ²~é@~<ª³N¢ı±4ÿ^~$Ù4‘X ÀáaÎ ÕÇU¥u˜„öãµÓcJß9p“³t&§¡Ñ6ÂÀù2‘Õò‚	Áê ¡Š®j(ìE“å¢+•FøúÍX–ŸR5%çO’3QÇÎ¯/EDğüN±;Ì¦Ï
³!(]SS&S©¹ÿ’Ãó#²ÄÅ¾¯a˜+ˆÚ«ĞÒfĞ¨ñgZúòpÉìˆâÛ`ê Z•~4`—ó’>
êØ“H®"kÅ›´#(Ñ´<æ‹KşÅ*.Š®ÀÌBRŞ)cŸºN8Ğ·YbÃ¢2ûn±)Cıõ Q­µ%³8É÷t‘ŸÔíFç/«áz;+†»4˜˜­L…•µQ³'?ÈÓÃlrWİ¹áĞ*³¤ÒG=®= ­T¶EMš)â¸[cv†ëûĞÈ:‡?7!Â¿Û¥·		B×´b³àb¬à¨fúËÚSÙÒ%%häbÁâµ GG&Ï:û%Î%Ûéˆ÷A¢,tcÀ¾;•&ªë~}iÖzzæŠZ¾ô†(½OÙgËêF&}BÍâN8à!ÒšF".‹å–ÙU—¹æq¤O‚ÜHàC@PµvñV`l9¡*>":–!öãDÑmgH9c$RŒ³?q6ì ³Ÿ<çôâ¯ÉDõêä/ñ.;È{¾·i-"d{.Œ+)Å’è¹[È™T2ÁÂp
Tê.íEQíPsVtùpÀ³eú®b÷öŸv:Rt>¬k¼ıó¯Î«Ø©w8=o&^çŠj§+Gh£õ¬ùL•ƒáÄ=½À™qa¬‡GöOŸÄP(wIïĞƒNj‰‹6s@ÿ‡4aÄØ5n¢S
R½u ú°(}naWâ¾*¶—w—æÒíÏ¸6è*pRÔLÎ½é·{@(X¸vò÷ã¯u-²ÑaÉå/±Á±-ò–ÉD¯s$:°Tù1OCÑãr™Kg´@¯HW*Jğì!ùApû£ÕFÂâhn“÷ÃF¨9.º>°É4Ó_Òº‘7­W´=7…¯.¥ÂÂ×«•ßO–?‡íJı‰”#ı.<^%Ê‚bW’År¼cz(G±]ªIONqâ>ë´ZÒš0R¾íwõ€Ê.´T.îm]íş¦gé»ÌyÏu3MUj¬áX_- ©µ³Ÿ»ˆÿW1pf×tŞìPcÅGY®ø²Ø:o<İæÔ7ÈÆĞ‘ç[ñ (­YK'BqJ~¾VëÇ=Aï_,êõc/8g ’ ¤¤¼¼_ˆµÄ¬ ûA ‚5{=ôf3ùÒC¾qæ ˜ğ£n|ß¶¤
Z‹‘ß7é#/¾xcTu%„_H÷Dh¼ÊT[|i®øBˆÔZ5t <~ˆ¾Êº4B•ñhÓ4-E×jNKÔ†áEš·@¼æ@4m%–‹Ğ$>ÃàƒEì/¿D|d1tÜ:<é‡Fñ$àÀ½»*îÂˆ~,ãÎ-ˆÜFc™dZkêş¬Ëb×ø¢u¢h¡‚‡ÜL§ƒ©DÑJenuK PÏ÷Ñ&§QüÜ ÍØïqv<Õ%í •}!®füÙ2¨ß™yÔi‡€ÆaÒÍÆ©çÆ¶×dîÓe×gõ(´Q9†Áµ'£KYúãÁõ¢–İ„ïk®…Gô|oÔM˜bÂ>ISıÑ}\h•BóöÄØÎªfûÖú,t¨¬™æÌWöZãØ’4ò¶N—ğ¿®„¸,E¼ã¾µ‘>\LàÏ*)½ã[äW\®]f+Ó¬¦pÛâ àŞØb’DvØ?ã¦ÓÅÒ1ˆéÑâ¦áÓÌÄ–.FÏÂé^¹€ßÖ‰à ¨¢HşçE4Lc¶ÃY+¬¶Ì™F:©
˜Rú!šıÛV¨‹D­"NËÚuÁsËàöÓÊZ~Ø½§è%ƒfw17³&Vb§,»ñ\¦^mÔP’Ÿ’N‰\²$çÂc]3c8\Ïhú±Ãz
À6W@ãØ§îz³Ô¢ŒÖ4Dü1±A„:XQ¿TçNrÓäs†Y\DÃ+üŒ¸»}BX’Ìİ™@zíÎ}é) ™^.ì2«áÄ™'>„¥îXÅ>˜&ñX“C#Û­œciø:Q–¥c+O–@LC÷ô =V˜Óš£u_ßãıãÑ¯¬
£Äua]áQçõı~M€÷¥.}ş‰7Ëè#èÚçë|í¼Å‹YU]§Ğl]XwÇ=±¢0Âø68õ–ve2.[Í?4pĞÅÃ3i™’ÎÇÚ@6‚DXVˆ‰d‹’*}‹Èf
SV´Rò‰¡ğßõ®îz">¶‡M:„ˆ[oõ›@ò×Ï‘ò~ÊzÅäÛ¡Ü÷–Ú’`ôñ›i!gğ˜I²+(H+IÑE*g!-|_ô’ÊÛ©dÇAµ[âÓBxÕå}
`N:ß~'dQ$bƒÚ)r¹P¤%Å»í\ëÉF-FóÓÈ¾kàäV¨?Šª'BÍMš$í¯U£EAZHn;V¸w×U)ªQ|ª)ÕL!S‘=Ìx«Ğ!÷¬¬¼W@¤º]Ô			Ê¬S9ï¹×-Zcı(  PÏÛÃà©¥H¬¯PÄx1-Ô!YÊ£Y{úì·á½¢’×'‰âš“/œ;Ê-X5¤À´­ :^?ˆï]£C_÷P!¯ ËsĞĞ¦YälÚÎ=”º¶A´#Ë-<ƒo·åé¯srq]ffRa¦,á‘qw³}Å¹vÜ^Éve‚Wƒq•ACA@é‡ß„¿ŸL„„‘ï(Ã+?rèòÏ•Öì{*Ó…<¦ü‹erÄ$ò F×•xçãd¾Úqü<)ŒÑ¦ŠœnYK$V‡‚YhbÇr=S´Í‡¡ ­Õ¤¤8
)UhJi!ìH­âD€ŞåR¨†j¯Ó‡¤`İ„„jcÃğÍš#DeÜ“üÇºnU…ÅÍÀMÕŸ‚;Í.¥,û,æ‰¬&w¾1ÅO$§Ç~+µè—6%y ï5DR9¦Ğ˜#Ì˜ĞçNZ±wÓ|J‹÷Ê3~O[)£à*rŒ]˜ğ)ÌIÜ2c–§'ŠÒÚ>Š¯Üå…{K
mæß>˜v˜÷OqâÉ„jŞ8—Ißr(<ª²äèd ¥úJù¨ë;9HÌ'7Bh‘^#.}¿ÔÒG8ÎÀHujvï}¼Ë†kr¬ÄbãB!œ:p/'R9s²ùÌ1V£¡7å#f
•!È,{>Ü-e/Œ»ı¤­!ïòõš»Xæ	‡`ØÁ§eÀÕÓæP@5êÎêŸì¨\‘Ùõ!­¶`£ø‡ô[¾7?-Ske²¿!Dâæ­aêN—çÃÉÔ~Êã(Ê,½PL]­hÓÃ¼Nı¨C˜\‘MÌªÂÑİíÍqÀPüşi+<óIÊÉtQ@ê¦k¾¥@JÜÆX’iÄ'•N\*»È¶€œt¼’ˆt¥$¶Do	Mn´]6{Ií™ëXƒ¾à6…Z¾œ!¨¡q\nBÅb8Ãù“İèµ!$¿ç’gîOLæÍ÷Õ`E?¾ÑĞlÌŠ£÷U“¯!WíÚ“ù­"ç¶³c£bÆR«Úœ½dßek“ó8RIĞ–û¸+çê^5j• Püñ@8ÑN(¿ñAñ{MDGÙ, ú*%æõé’wZÈª…¢_jJq:–ze:ı»»’ş¯ÏdğCçO2/KHpíh¥ôª»~0Ç+¦]2]r;>¬şG²ˆw¨g„™Ñ ^*v×)6*ùíêŞ6.¼[„|·ØÉãNGûO6b]´Hå@uªv	ÁÂŠEUÕ1ùÇ{¡_dì
CVV|ÏDœİĞWœ·ƒ>_ÅUa ˆŞºÀŞ?¸³üD›r°qµ½ÔˆcÀ}|óø<%*	¹Á²òî©›¤l‚E²¯hRŞr‰”˜š“äWF÷·²qİ•óãÎ|ê/½Ùæà†£½¦SÆ@Ëèÿüì^OV,Ê÷
a­$Å.Dn­”{eµ,IÒ­?)8gx(‰CDÎ%iI»ÑèÛ4i-ä‡HïÃ‘ôpa3'"|m­¸æZ¾äy¬çäaTJç c|6üòß60õ' e39XÖ´t¦ÓãO½DŞW By]ª±ï	Óçq˜ª	-ï7g 4–}@³Û5=‹¾¿È&kÂd–ªı®€´0µ¦¢ì…]æ ÔK¤|TèÒ„À]
¥·ò|Ñ_º4šxşLÿÊ1úº	×F«J;˜»¥0ë«±Ó¬f–Íl2øIåÇ“Rƒ[®nÀ?Øzæ×™–È˜ HlIZÑt‡Q¢œO#n’o‚IîvPğQÔ³.oë y)9-t®ÎÁÑ3Æ‰yJ8âPïÏß·¿]Øñ#âX<6´Uü˜ôR‚“Èe,Í˜ô±Ä|ÏÓÜº‰g±ô¬µÀA¯A$;ŞïÂiWòÑ[î!Îå³Ä»¾PJ“ûàÛ•“.®gãš¼,À»ÈQ4×7·t‘ÜÎJørßhbÎ3 ÔVıÈ§¼i(„ s$Î¯Ã ½†’šhŠKŒÜãv‰:#M|!ò£ˆä¿|ô]¤RöäQ_C‹r„²–v&)Õ×2]Ağ²pª2Úôñ¯äœŒ1­]Ã¹"‚yt¼pé|TÒ=ôiÆR}¥H®ŞŒešv{MLlm?.¦ßiZ­#|<&:–zPÎâ‡	ü„“øw µ[n3©%;^×
ÕÁ&–ËŞV&‰È÷öt)çS‚;&qßû·K}±ÎŠ…òrÖµf=pjÖ[
Fš¯øØ[J«´JWp*bv¯çuÎó°YÑwÌzª¹¡Dw¼¨k€ŒòËq:dõæ;0¨ŸÈFÛ§Q,é(7"ë
uÖ¡üyQÀ2¿A!9¦õXùæ»•0‚eqIeÒ‚ñ9±)ŞµŸÑ²å¤E/ŸÎÚ˜V¤lOâMùìÆñ­2½
|k Å`5/ ÄÒÚŸ_Ÿè…E²k€€¸R*ä÷(ÍQ"—¡æsîV•©Ìp;f3ËÎ¦D‹ß²³Ø ¾O<ğÓõiCK?g—ós3£œÊQü)2ï+ş!ÑÀ:öÈİÔál«3’JYúM÷…ìhïàV“üàv¬go¹è"{ıenFkTÆ¢äù(´Í·äré*üWkŞz]¥JéD0Pò>™¹qHZ”g%Qıà[bğuõÖ+cQ	õç_*A2$<úqËÖ!ó¯¾‚½{GM O*İ<Ÿ´^>÷µºó$ƒÚ÷Û÷ìò íº8"hBßZ0p&éBfbs`P “¡xge’Û© ‹¸~Ë>zXS}–k8¡‚Ü6~V*vÀ<êÙ¼—Kæ-üİol¤Cg'Vœól¯Á‹Â4à‘>=BÜvø¢GÜù¢Ù2áŞ‰g„¬İ±P– Ş9¤JQaãNcøªı	+K73KxCZı	ö}¥³ƒqEİzkE\CãbcUİq¬¨?¼'»TN}§==ÒJ»›0€®Ÿb>f
o	§VPkbœ•BXJµ¶¥0ùÆã4X =dıçÅz=¼7Æè"±wC×+l‚Õ(*ÌúÄ8r½põÒ™^ã˜Ñ!ƒ:õ·g°wW•ã’t†³êcûáêÁßÃßĞ£‡®/¼wÌÕ×n}Y0¸TÉà´^Õ”ôF×I™·V9‹u‘bãNš«N?9®ğo©¦(‡W’ÈQ
ÛSÕ³_Nj¦ÚH+x7>©¬±'[	û®Ì'|^~òu—r9³½CsOüĞv™¼…QşÒ¾$>0•¢²q&¢Ai•àÖÀÓ^>V¶$p6cÀÀ…•·é¯~Û€œş^_©ÿ²‡×³Ä‘o³„ØH1—¯68,Á!6ûïÿˆŠ.À½ş„€WIÓ@tÑ<ŸRC¥Wl‡Ş>©mİ£½¾¤f®€AOYYõ<¿ÇÕ^å§¸å¾Aìx»xŒ.M½)ÔÜºÏ¦ÂvÃDgíÈ/oÌ€¶ı²>%œ©ghK·y‹=ò©×EP´×¦Bˆi0è´bt-CÄâÆ#èP„”¹èkcÙsÈèâI0Ÿ|‘Oë¶8.ÿZ¥KÔY£ú7]¬RĞ{Ë~
×PÉ½?Ãöq¶‡~ÓRH8Î's€÷qñK«ÕtåßdPîŞ ²3Ğ öoÿı¸©ç´Ê¦rUÙ÷èß¥Ë{”6UtØb¿¡¤Øf~jZ¦ÙÑd
F%…t9™>E!ZZ+l’oz°0CëJóÀ6€“!rA­T¬fˆı¿,Cñ¾İ…/áS.“\€Şİb8•¦I*úÛDíÚmq ™à½PàÌkèh€h_¶uC±‚‹.„¤ŠqkÀ£édf’¼ÎÖ ²äÔşÚİiûÚÜ›ˆ0Ê;Wz±’ö$å&­$%ÛÃ³ÊƒiÙHe±öyÆ›õ‡håj’'YÌ}\â£ãCÑ˜ÍA—•…Ï¤>¦şD1‚ëGìƒÏ/¤~“óùDaˆ4f=ØAƒcÛª^ıTGxÉš„ğï¡İQ^wş‚5 wygiø9EÙœÏ“|ÖÚääu¤*FÎ W"ø¿p86u´îF#=QàŠŠş*SöoR‰¨/%´¾‹kbbqm‰S»öµ#¿!f<Ì½Õ#vŸƒ^ÄŠÉQŠ8-ç±oóÅ¾B¤Ç¢	éø
˜§ìú¨mõoùÍÂ—åÕéh§ù“Ùbğg‹Dêáİ4YPËUl–	İš	äE×n›‰á`Gâ±#†¤Ewâ,j¦oÓh©4§¾´ó»>5ª'$Ú ‘¥Ò—¾™Zés ‰Ã²ZU— ã•,©ğù‘Tl"ßNg——y+eıe?NR¦ô§ûG¹{s	åÌhº¦åI£JÜ;æ±"gçÆ"v8åÅÁ+sÙ	Z¬yEDÍëC5—NØæÏ#F³¾*£ì©¤3®ÆEµR’±J'ùÖ kŞJ)´±êkë†Üp‡ÅI5Œ<RÜ¬º	DÄä-ußõ#ˆKæXAXõ¯oË†´øšZ>ıÔñ’ŸX
÷*°®Ğ1í¶;àK‘ÛÈgÀÈ’ÇE„*y\»cØƒ7ë9<‚ôz Ğ_À•pOŒª9ù·T¬AvÉİU
ØB³6Ü4¾ªãzÑäÖÄ©™%*3Å.øµ›vª>ˆ±ªØxJqàª·‚‰B~·¨ß…B±/ˆVMk1úm’İbúmÑ4¸E·pmãŸ8Øƒ§ïBáÊâºá®Š9XE¯ÅûL¬ ³kƒëé¿m ø|nG6ÏOÿ©)ßh¿È~´Ûéoh¿ı¤ã5wcp·ØmÛãy@æ®e®«“½_9_úrÕ·5qõ¹l:´!_›Ï… ‰[§R	[ñ ‹ŞÛ• å©ß1¹;ALb¬¼aÏ?ÙÅW3{ÀäÛÔs32ï9aV<ÂH:ü²P`¼Jµ¿õığÓQ(º£nJš	¤šz58Ö¯
¯mÒÿà€IN†Ê„ŒdPsí‡'1¦ƒæ×­èÌ>ÖU=ÅœşU/ã·ŞéúÚ ê@)-nÆ0š÷©í_À¥öò4XC'õàrÕ‹,ë`åÒºªJP®`¼² Ï«¸ûÔóèÁ÷ûÆäO"¡’R+JóPşÁÖ¼buÇ‡ş8WİÊ`ûuñWX`kÆ{eU±ø'éåZÇ¼ì,X?‘İÚ|8qá„æ&ÁUZœ5Urã6ÙĞ	ˆùxC•«º¸»äeÛ[¹~åtUVÁG[Ø‰‡ëóÑ1»à½±‚áZ¤™B˜X°òÁCRÕ½}yØ»fáAşØÇ‘°»"ûŠ92Al.Å~ÕÉšFgØÉ]uyu6Cc»›º¨â%şW-f¢ª°eËğ“‹BÏˆºoÖ•¾Ú²ÔÓeÑjzªàl·œC¶E§{ Z Që1‚¾ÒI<ãŞ ÷8›Ê).cJxNtÒ<…!i¤°·¬¶Í*¦,‚{:c®¯Ur6ŞÌJ#Éş~ù6bué¥®G"Hğ/WHÉVgªq!ø~Z›‚j{t“âÁ°O¸Õ_YJ=}ÒU‹½Í¡ô­2üo—bÇ€ùıŒ™ä{ßI­M}Ğ ş›¾İä/şH¼„%Š?n¤òÜ¤õgje§_Èƒkx" ¿‘4!®a$5&©š,Ø––1…†nø¬só¸_Ë¨4Âûl­¶¯ˆnxß"YV*,¿¡º–sê43±r6`öo¡jä+jÿgä°3¥cdş4Úÿ¬¬ÚCéæ¯†j©c³vk:eLpNÁ^ÇØíòr‚'#É±[.ûW’u{ÆØz§|’OqgRÅ¬}¶¤­Fî¨5LøKYíC~†ØI¨J? ¥­Ì&~dÔ[]5eØ‚¬°¸¬Ó’WîôsßÍÜZîvY5
ü ï ©@«6½pd£g|“sgh†{È¼ÿT?Â@xÁyÃd¨\±îÂa‚ê­f"–ö³ê“–+ ú˜9İçPd.Z=MJ'­w;_s«ÄÇ^ÒºFªÎ—yŠ×ÌWçKyöÍáóˆ±'ÓĞĞDlx.EªxhiaSb-)ê6–Uÿ’Ï½¤vT.
íåpE‹9 ²teş—ØSÂf"ê¤¸®>}ñÍ”ù2m…ŞWı3çx¨ŸBşRÅ5¥ÅëMy¤í¨
Z$îúDK.n]vJF`gZßW™Ç£³…‹AÃ9E‰TŞEtüB'ÑÀ®hC4Lë&7÷ÌEÃõªEª£¦lÄü–×»3õ‹ª• úlŸ/Zë·]	 J;x"SŸ´ÔxÛ±0G%tÈ;ãIºHH±&(L:t~h¤{Ÿ¿¾bµõ±1¿;ŠĞWùD[N¤2íd¹0îe=Áÿ>ˆeCsMØå¶›)LîĞJTrkÿ7’h÷›&¾µ£I`«2ÿ¶	àÏ\q”YÏ•—=Bò}S ïfW›[‰óË<½u%¶mİ=„Œ®»àyÆ¦_.¢·ŞBe\ÇÆí@ØU/(óHgâ‰5íÙUÅ±0«îß³ËÔ7$q>2æx{[È3ßóã§g\£‘¿Ï#+ÒD6eöetùÇ“VbJL¨°Şö“ëÿ UhH"2îè$2’ë½mF¨@òÙØcŠ×òâÎõt$ÏŠ>ÂMœ!v*­ù¸½j0ß¯ÃåÎP“İ]F2WçĞ_İ4³¼  p3ó[§èÍGQ`'÷	ğz¤Û‡“Ò!aÖûÒ÷ŞAúŠe^1‚€û¬VºÒû9¥@ßˆóîUoÛ÷Æ´,Ür2%+8gœ»º)X3Á>nóÆl‘»C¸Í’pøşà–Œ×d^EìÂmøLbXÚ{û
‘es´O·åÓa,
E¶šÍ¤­nrï´Õg?ZÏó]§Ãİ¯B3?À­¬^WÍ>¼I1˜Úá9–	-_ŒR©§±‹ä˜º?È¯Á³(ÇthLÊ/;‘I}3ê#–xp"8+Zy/ğAë™¶
Ötš’åZë¥GèæÊ¦g,(K—LÌæôG¾% î­%JÂ_€Ehm hÅ»t'xd &£a¿6·ºâNeØ{1Ã1Aeìã0‰CÀ«›•A€kß¨u¢hvG%™§¡õjô¯Ó“êÅñN¿Œ˜ù’IPÆ"JÏ_$3ïVËÛ‚©d,f“ó9JiqŒª¤¸ª
ÁjaÚ|ˆ›h¾ÜÉF¦½·¯„ŒŸ,î°\Œ©¥&”ßFÓ>šO¶‰ l,çTumô»µ1^„àX;á{çğ¾ßfY6n:2 íj»Ï´Ï°Ëô—,ûy³î3´J”—±şŸM+Cç:óE	–
%Z¾‚ò¥a‡¶ƒgS|Œw0roNµÔµ1(•LÆC"Ìşñãj­·ßÀû¦~Ih›ïºC´ó÷k^!¹š¿­ÃËŠØ„ÍwÏ~GFH ¿M¿‡`š 'B?}Rİ°zqG ×›Á<ä¡?†'ğê³?hÑA`ÌHÉÊUéFÒzÃØbÒËIÒò+ğªò­BÌ3¹ÍAƒ-?¿¹”b¦™80€0¤selRÔ¦
‡SqrÂnšÂcyäáŸ°É@”£rÒ\—U¸Zók?+ş™„‚?XÄ´Á$Ø°MTy^şºÍ±6‡0}5y+m#<Ñ˜İ°â±IÙ•ù˜¯Ö±Æ ÔTôş”Ã‘Yey.ä]\ÑûËdFm*™¸ş"³sÎb—İ­;.ñÎ,+RãĞ€˜ôÄ£`IfÚ¾.°–C§}ñ²J"ñûÔïÁÇşlõI¨ÍÖÏæ:E 2](ÿóÒ³vOêß5úJè2;Å8Ç}^H¨üY“k1A“¸•$$îKu3÷[@¦¼äˆ¨c¿3a—W×Õ;§Ö‰"m	‘Ó­ÄğğPÉªwÑ_®C´üûşçæûê÷ñ¾oC¬Qğê|å¹õà9#àNô{TI¨$û_­ç<+>¡{)^5Œtò	'S(Uôæ†ç¾y6æÔ.%èwÃşÇúâ"¶®|™]ñ ³Ù<|ğætê©¨³{O‰Ìõ´¡wwé|“Ó‘tB9,le»¼)L…İï„^¨.Ä6j¼É¥ÇIy„p) ÷ˆ73?R@'ÀCıú÷‘ëbëqº‘´# &¿Œp”ö (§[ÅÁ¢š*MRÆŠéµ§++n*#6§âKÑScÊ%²›ãBÏ!Oó ByËÕ»ª”s8;Øv¢«£Ù€-òÅ5±™p„ÁÁ:oÚ[¨¦<æ¥m‰™ZK}5nî¤è8Ygçyèb7M8ª½´ƒı%Ô6Î†q;2¢¬ùu‡%yß•İƒàô2%Lhgo¥î³¬p9ÁÅ6¢ëozäÙC"‚ˆ0ƒÎ<£°Õ³Mÿ3ÆŠd¹y÷ÊGá‘³†ôßìCPˆÚÃz.²`Ï5ùÈgoÔ#XÍ¥¶ y$'ğqTŸ}luÊ$>Œ§kı	P¤%P6«¯±Áè’ŸTZnµ‰¥åxŠk–®…´rà¹ã; F$Á¡E°ÿjgu”x2€mÈõWZ_YXU*ix6„¹Ä~¥ïJlŞóGhCclÖ”½<Ì˜|íù­a{ü4¢>ŞM­ÀÆF‡T×¬¨KEâªgƒ Ô+QZ*Æï˜AÖHã£n†ÉH“9ˆ}V¶ädkÜÛz¸àåÊ‡7s5øÒÆp¢_äáÉµJ5¢9c£ônë¶*WÔŠ/YÌÈjÍiWOj9‡“+ÍÏ¸‹İ1y¦‰>H£ÕÑƒ¡ €FÙk‡"§ïRMhêv‡6{`°Âï}Ğ&Éw¼ˆ«*Ùò³¼:$î¶}Eí‘şÉ:½Ì’MyŸE‘\ZJH°tõ†lÆ¦~¨pLˆ,$Nn¾ó³./£ÑQZÒ'4B5µªêÈl‡´ÍóHpl€ê@5^¥ë¾×ÆG6$cÀÚDA^t7|„©ÒAÓ¯Ô(Å™\}Ñ%&È2µÆiÇó[•4«›ïç?†BJøuÊ‰q"ëë3t¦ê¡a&À(¾¦±Ö[/Q	E®Š„TÀÙjkÙ Wv<3i	ÂçgÕ ÑûOa¬RÜ	š6DˆùIŒæ"V¦ˆ%pøEi­êâT¨İr¡ÿÀ”Ø>”ÖK–i:é(†­‡ñ}_şõİà9nÅOøù	.åÚo“[Ù9½¥¢ıœŒ²àr{„QR_”VáÎ>H¿IÜŠÉº¶=@Ôù»D*S

CÒH=üZş£İü\—¡×æWÀ$‰"aHQlOQœ:ŒrÉáı¥$_ê«€íGüÌ}Q8¸ERMË§/f^ô( cC Œ<JÉû°ªzu»&™Lé™&•Mı£(e§õhˆ0$Wf/jX˜y¯±ªz[åËÏÆî‰$ŞÏ¬'Å³]3±yÒÓ˜/Î16Ì“·~ßÖ@6=‡î_ï²–¿X· €W=\ÑmPN®F­Í‘òß3ó>ˆ²ÇŒª R'î¨7Æå E¬3È›PùËEç‚ƒûÆğa,ú]
óY$èÈVÔ{à)ì•p?©QÄÚJdh,Ä2Íuuœ’‰‰­åD?œÎ°
ğó2´Ij¢JŸtÆF*œ>?Äv"şOüd`ê9¡¡ÎóÔJÎ¢x«Ø™;b„?]—mMˆC™”S’>,ÂÀË[ ¼KSZm›BşÀ1±v¸j30r)A‹ŠYæ&Ü»1êŸÕu™«È59¾ÚGl¿G/Ö³ÖÛñ İ&÷eÙYÖçh°¬™lÖË/9ç†ã¡Bˆ`oÛ‡AnTK}¹_qvD.»J­å¡ÌŞ	§¡ˆÔ¬·²+×”òˆg7à/êzñX—Îªx6ğ%œĞäÈ‡•L–„ï„l¬:h0ÔÍ'^Íş¶^ŠÄˆ4òò—á³ˆ9ğ Ÿ:a™òñ[n¹x•œî¥pn‹âMû#ÍŒ³~a2Ş-ød©Pá:ü rÑMR›‡`á5RZ=Uõó,¤õxWnÑêQ"íì¥ãHìJ¥qpğ•+½ì_ç‰“ğÃ+İ‘¸×öH=É†DÉ?Ñ‘î˜]ìºÆGv+ÀúÅî¢D¨º:ĞxDªb´ª$\uyÍt·e‚Ä¹ı#£ä$òÊÓØĞ¤‰Q‰ØÈ&ì9­Ú( @O`¢–òÅj¿@JU
Ê ÃıêÊq/÷'qº8v{µÅj`Ì÷âwZ}!]àËİr%9+nÇéÛ½Göx¾Ku„XxWGDr^ óFšÖcÇí=-"‰_,rª]$ì±…)Jn'ŒÃm<œİˆ_¬Õ…»/KlÑÔöÔ)Í6ÅìÌO@ïğ´m3—õ3m‡¸6Ù~VğÀâ” |é·¹“ÅÍ+µÎ< ×Õw;tÀIXº g¾ù(_ç4™ª[ª®ôÃ×ç9)mnŸ½¾¡tï6-±ú1£Øà¦M’På;şŸ<æ²SKtbôMÑbuşSğÕ¡F&qËNÿ†qòë4 2‰İ¤ÏÌLo?³¢0'ş4\ ²Õ~†eCPOh
ÍXéDáÀÜFa‰ç.Û†Ñ”nR…#Ó)Ğ–|î÷Í§¹uM …±Nù>V‘÷«P§¹=<åâ¯Hh¹oäÚ#BÏÍÜN€UÍ)Ñ¦·Èó¬elşb”AÿÒ¢’;—U  7rÁâ*¹8í&éÔw\ç«©ÎÑ¨c8û®èÎ#_®q0u#¯¥µ¤ÕùıJß'µsrÁÓgd¶ı%©éŸóÖB˜76T	F9á\U/aŒ*OS’·{G×2„’™½ÕØÁãDÕŒÄgwrìéÂK
äDi!ú
ÉGÄ®VÍ+‚ÿœ°À×“¢ÙµjƒœUéü_rFtÛjÑ«¡³A!Ÿ=Š±®VKKxG@Y¾dËŸÈ˜{²Ú'}€Ö=á!¶j©
äÑ'ÄÏ»·b&\•D ÅêÒ9óòN°Ô™œY3ZÇu}êÎö-l”Û¶	%ÀJ˜Æ	r;÷as}¶ÖeRÁ×Ò¨¿÷Ï45§8UéwH
ğXM_ß[¸}–ÑXÓşEöRÚ‘’T\f¡ö­Íj7(ùç\)/á DƒJ‹Mç”Ù!/¡?îÜÄv›*r0ÅÙÃøq¿LÿIÍ|BÈ€1‘PVD]óüİ: Ê„JGÜûo‘0‡>7´q;šı¡êÍ¤¢ën._\F”m¢\'¬0”9«t²­Å®¦xf½ÏìÍ@êEÅ±Ç"«aÖŞ÷¥‡§²®á[Z`)4Ôoç’i³f'–$âÛß&ñ3x3è   £¢„K¢Ğà ŞÏ€E¨7¦±Ägû    YZ