#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="555878776"
MD5="bafac10e8f989659f4b319945976701e"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23744"
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
	echo Uncompressed size: 168 KB
	echo Compression: xz
	echo Date of packaging: Thu Aug  5 14:20:34 -03 2021
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
	echo OLDUSIZE=168
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
	MS_Printf "About to extract 168 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 168; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (168 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ\€] ¼}•À1Dd]‡Á›PætİDõéİ˜–WW ¯j…ÕÁ`¿Q©’¶£fVèŸµt†r6N0˜9¦àÚCÁM¯¥^§[E||æÂ?ävêö70CrÂû+úş¬dú{ò†W¡NuïC}ù@qQ±Z	súê—š‰?ô£uYÏÏ =ÊjæöB0!]Ş¶¸ŞkåRá²Z¤².Ç2JM!Ó±×á(~ß'ìåğ‹­®zû2x¨ßÛó:Ö51:'©“©#ê*Öq¨kuÑÕQ@%ûÍmæ4FØ_MùCÒ¸ŒÀó·©ÎOİù$íLòr}qE÷±®Í#J6°wÄq…>P°›¶õ9ÇÍ²N&®ôüñ!#l­™æ0hiË¨†¬Ï'ÕåÏÁûÕ»–3‘
¦æ`ûÁ˜!`ƒJ3RIûjœ+ƒ2¤$*ñó/a–ÛÁÒ?˜ÛÇÔ(o¤OLªmò’Ñ~ôúÇø+lØa õ€¿ŞËõ©µÄüpJ5›ç«Ë¿#NU%²Å{fl1æ}Â3nšP°F„pÇ×-ß K?æ^Ös‘XÚßèSã4%‡ÛhÛÖEøEÅ3&°{”ßÍ!â€­òï÷&ĞÇ_@ç—ğ}ÃeèøK¼(²}¨ìu¹†"vn¯ÆÕ}gÅ	¶d”³ıñfšùÁƒ)áE”•jãíQ²ÍåîíCA) Ğpï¢É¨KGÇĞa³…Åå2›±"(ZDŒù:ÙA"„„´E1¬HsB¶¨4IÜ´>Ø¹w7¢	Å`P:Éll9Z^éÖ’c}ÿ}wO°¸ĞI}‡ì!]­mËÆjl.Q½«òÙ Zøğ¬g1½ı•oål€½8¨Ôvß—¨hrE¥Ş[,¹gsİ÷ëÕW¬9®•~ /ñaXÅ{z9o´Åµ´„PØş@yï¦%ÍE˜,~ª†Ñ„6*))
·À~g3ë­^ZaWº»cÅW%,Næüè³…Ö¨[›i–h!–¿â“é_jİqŠ
1õÁ[«ª¼ÔÕmD¥›ç¡œ™`j7ò ÍöqïC£-`4ŠêÇ9à4õ!sa_wsãïY÷–
ÍğC\¥;Ø^ä©YÈ«Ú=v|—‘ñ
©†z1\Üp²†,xsVğ5E@ÍÿŸS»zl³öpnNHØ{4Ÿ¸ÿV!Îö%9pdCòÜ»ú]½”%Ny]W.ú!¿èCdu“šİé*ÇdtızµŞ…Í'³RÂ÷sQ›šç9Ao4¶å|F¡0FØïÁí¯e?şº•tÕ¹Üè«›Şßbr¨»qÀ¿‡ï"Av‚y¤¬Úœ‚Ø	öVÖyŒº F'{îÖçí|ç«îĞ‡ÇÈpæøêg«Çâ³X’M«1r}P$9ÆzŠh²L»&&	-ÃAoÖŸ½uùãÉH`s—&½ónMvDª™¾`¢s/~Ç»…ÕUòÍ4“0¶õƒ4›4Ä‰ à«Ròè\±Ñ%Ë“\p<™ØÊU¸ù«0[3\¾àNõ´¶µƒæ¾j–ÑÆºCÉ%N›])ˆŸí²ƒË/ùÅ£esù/yù¨ÂNö®·r-}˜ª†·ÚÈ9|KñÏòœ¼)„ÌMï¼oøaŞ¾•#Q˜²Z±¸³şwİ­ôiß1Ã>1ÛöûøwM˜Œ´ ¼˜•æÇ%û®?Z²» P;§øsÈ@Këş†7Åù½ïÆï]<Ãb“n°ijÂPåÉÅ¯ükÂéáÌu3Õ|Ç‘ğ†™›Ãôw¼Yé‘©Ôº¤`u+J~âÄ=kË¡-P‘vã¥=³¦†T=~üñç|µ¯’]c€¯ğÊ	^f9‹V=^»a‹M&6Ğ½Ô—h[€¾­pŸ˜tÀŸQ”7¢;YÅú=ÇĞÀ(
¼VRk1%¬âµdmÉ˜óeğV¯5ô‰«pÆ±”„Ã$§AØ/jÄ`ñ_*©ƒ1[€Ö§D4Oş8ßael†>œõ7±ôõÁDÕ¬=rY·Qíº£¾¶	ïÚ}ñ¤¾AÀ»™í¬VÑ#ÑÌ§wëñP;ıÊ}œÌ¿Ì‡/¥BóJVmÜ—õ\Tô!5êÃ~y8/snjÛc*V0»úÇ%—ŠGTÎ!†œm :#­è½b)`¾÷Ì¾‘é#²¿e8Í`Ûì}¡ÔŸĞY<‡pDã1ê¯G½ì,B;Dìˆ©Äd‰ñ…²Ü±ÊÜ‚³x.|nÔ,ØÎ=óŞö…	´+%Â’tæUP¸Ög‹£È¤Ö/ >ø#Ò«­ÚmÿaºûÙ·ªs)ÔW‡şãÙù0/XÒ(±*xªk',FüÒ±ÃS¨óö¬‰Çu›»L~(‚X¿Zï[–*¾ÌSÏÿÈ]òD»F~‚Ñ¶=¾=¦ÅÇÇÄŞÓL5H ])ÓOa^yÜ«—€àáÖt†<,?>)i&£Râ®q\­@`'‚oŒdË¥êıœ±)"‰„?^åZàÑŸÈ‘²-[pY®…È™¢†JV¹ZÁªL(É;²)E’Á¤eõCÁ,‡K,¨ è(ÑÁxã.^4ĞÚnõsúî)æd*æeNæ¢û¼Cb²‡	aé™{W¦ûæ	³\¢!2ªR|‚Îk<n°i‡¬­‘Uf’ø·`û‚nj^ãs}‹Ö“wóğÅÁˆøêû‰Q¸’!e‡3ûÊ4ùB¥²t%^eMA‘…é5e¼ĞşYÂa½Ê.šÈJWäcàˆùÉ/ÃG‹}l`Ì|m:KŠ7¬4œ:Ï1İB˜fÒvqäş²±,YCÀâålƒŒò&<ø½ôÙf™<-D¼Ú¥İ­ÄåmÂ°o•"¼f`ÀsN$Ïo58{Ê"9È,ƒjQjĞo]Â/d¿ãÙ”Eºxï¦×Ù‡lèšÆÀvæ‹K YÆ-`ÜĞ¢‡zèùQ%b¹Š]²½s;ùıìFĞoÜ=Ú°8­ÇÈGi°`cš¼5“»?Aê‹?£Á’úšÃöÅìcÉ’-ç/O%LY¦€FE|)©)åzĞ „¨3¬¡|J¾(€_'©àÒ‘/ıï°ú°6qÕëWpªó\Ô‚Ÿ…¡'™¸p¼]|±ëO‰8¦¡ZäĞ{ÕJ¸æ4<*‡6şE?{ıİçVrP<X·|<Ğ ˜Íé 9ŒòşºÙ¨şÚÅ/XtÉJ–hÈcíÒo÷@¢ÅeW»^¸³âƒ)½ï¬…'Ñ¥øß	„ÁùÜÜ@U 4QOâ ÜûZ İlè5:‰,;9y³ ŸØşµ†§—4JrZÆy<*‰´ü[så/84EÖñwêóõù.çwİëWæÑNé±İğM#tóMÖñòTÃ¾wFoEP¡¯lQ¼~ôR4ìêÍ#iT`"ÚövÉÀ&¹¸šäòzC§à²Ú»—:7¦IEÀ[Iÿª7.pë:|×x²zïá‚çš™ÈÜ|ÁÄn6}^<PU¦hxUÔs)’-zĞ¨’ØnVÒ
Lâ1¢8fFÄ9@£2ş1ò‘ôu-qÛ¾‘ÖW®Qô±Ï«÷¨Z§­©9ª6|HŸ	®ğòQ)Åv¢õenp"é@’÷Ë-·ïÇIö'/š&b»%ãí¤®ˆP‚ïI‡¼´uEşy 0ÛhŞSmŒ¬Cuz¯x„·İ†fz·91¼ê#‡I„„Ë ÁqKl ÚQÔŒ)ÆëJ´kÄTèÍât¡°X•…M`•F|Hr	Ò•Ñys)>7sİ¿·˜ÈT,½š-†÷áŸ"úOe2ª³´TÍø;©QiRùà£h¯5ĞŠüö·)wÏÖ0A·³º¾å½·~³­ZS3œ:KX:EmÒº•zû²q´Š >ŒñKàÎÎì¯²
]œ„ùm)Îæñƒõ±ÍWf³h{ìÁcÀÔÏu½Ğqş0k×ÑçğğûÚ+Dm÷0ü¼!¥±q£	Cşe²½ñÙ!¢(ñXp+É9X¶ˆ.[¿¤fE³À)î5Å|Ë ‡’
,»­–âƒï¢aÄh’B¯F\´ìRSìüt§Ñ™È›ÙÿGª×àùØ2[M‚˜Şm›EtP`+êo¾‡„X5İÎ:–a¶Ã¯Fö'm l5Ì¢¥-éûÃbi©«ÔmÕº;i_û}_GÎ™x/aÉ ÷9òEœH±RéŒ±ŞæäU€XciÁ0‹TzÅ@®|¢“+D'z.i; ÃtÓ)(E„?ÿZœ ÙÂpÕ’ y„K"$	¯à6“Ë	7`÷×b¶ºİ©ã«)ä­_¯í"¿n²sœ1V°ÓÑ5¯>+üñáé´+Ù£„ÖO*ûp“õÕ6É¯©!œ’Mwıñl:bÖärìviFNxhW®¿I6 ÚSCî°®t½¾¥k!øŞÆæªc M: i
*ß	G¯ÎÒÎ}Z½ĞpaÁÌ–Z™j	#Œ5y‘mq)Ix¦Ÿv½±nJÖv»OóS«+DQ†)+×šŒµpˆ( F	úà€}¨rQDõ«]\+>4*U\íbH¬]$o¥{÷û³Q9º\ààÙ~;‡:^®~]^®²:¤	¢ù1ææ£"	@8Ë³”ô<°T3å†r=Uq¦Ø<Ù&°C„‡…Ë8KncÌÂt€Ç˜ÌXìß)ó‡ ŠÌöz9"‹wVBHÎÒ¨¾~Ve!uÿ®›Æğıj~Á2œ–ƒ 
‰b<uµûˆæCå²y®^´ôBÓØõÓŞÜö ˆ*u,'†éu~_Á=ª¡+S˜·pâ7z—@v‰«¸"¢ƒ¡t+E×i éØ7ì{WÀ4i_F‚ÍÓpÁl+{°ç“õƒ ¸_²€‹l»¤/s=t²Õ^©ñ;ç{û=ÀGxüÁJà€è¦öîT´Šú¹6ú=ÙŸ±yíÉt…°cı@.ú…Q&Á†XØ3šW‡+ş–+¢³^hİÀó…?ÏVyOQ¾ÇÙ>¡‡ß›•s{Ú_¶½Äòy»¾äT~Tvîä;+Îö @†Ğh­1&‹°Ñ¢šÏK"hTÖ×¼Ã§Z­…éY§-DûìÜÄì‘óJ¹¾½ƒ3’*o®/yôZZÓáŞ[ öT"ü)ãRnª %=ºúáGpf“^,âÑˆ’
ç:À€§ìr4ÖğÌRŞJê^‹œßHè	²ŠÓº:(&£¶#vmepr|¥Ã•	ÒT2µ½EÏêr_{Ô—‡$‹sÖ¥4Òu<hÙYÕÃÎ1øà¿°†wd[›Bù¦_•¢o"-5[R ìæ^à…‹´MõÛÃ×iFJ9<æ.ôOfüû`6HlêÙzfxØĞ«âí<&ºÛÀ©@¦BõWß›êoT©pßÜvµÎÓÄé6Ë`Ã7ó‡IâÛ²]ı›oÕnßşMÄ–­¬é”ú’.´–¢ÀºwRXåÿ¸®½Ô¤ãà1Ÿk…›tù$/›rn_¡Ìz©è×âêÜ’Ëa,½WQEÔ¨¨éŞxj}ää5ë‘¿Ï°¶å+LØ,-AU{¸V¨¬blİËi Ä¼©Ê:WßÑdl“úãÓ=&°£=¡&ºš’’—u¹üß£¾h¦ŠÓØ}÷³)­«7]S]W.N“½ëó4„,Swçø§³*µi}Ø5‰‰—¢o)g°<R ÿ4‰ü¾L®|hõdÊÉ”§0°ıÊC‘Ü¾“cã~•™pa4Ş¥2©J¨Å,YEÔå6Ö»KğÆååv3ƒ)(Eø;Tå´Ä°µ¨Z`¦‘¬_^ÁÓæÒ¦}€v0Dÿnœ‡o>şŒnq"œ0|ı¸ï„¨Y×.è¨†é^Ayl6ùEËF[©	4$.ÌºP²bi›ÒèŸœÙÒş…v‹²·3ÏDQ:#…f¼™–dRôF"îÙ­tèÉ];Ëš1µ³î¬}şaSl’ÈùHÏ9¢>5Şçw©•şô1Ò–A’<$^-c¡¬ÈyêÛw}ëÒ²˜©Qœm¿]î/J1yqTÏüë©´^óË¼DdŠˆñNnÂ]ÁQQUH@›ªe%È)P¿ƒ]„hï\¤´ş…ÜÕõÎ&ğ›:Ñş˜Š»lÂ=œµf"“±¼8Iõ$kj2Óÿ«™cæ¥3ÚÖ4j©¼Œã›cã®KåûB$wfïFŞ>ÎÛ>å™ÈGsx7NÁ.·9#Gœq•?¥Á“Å˜Š +µD/R¸jò|àÂı2n‘Ğ¶WôÓ]ÖEøeœğ$‹ygÀESM<pQ§¨¬ll¥S
¥¬ÚmtñøäÕ1[‰Ã’.^&±Ì¿¤~¼%{A9áãç5Ë9—ù=:Tp°ú>DJl„‹Te+ù¥4ª˜uÓV„a*÷µ±ŠÑÏÙ_f&µÙc¥z4#cÜ‹s|	†’èr3!Ì 	ç6½é ¯'XcÅ²§|í2áã!ˆyîâhÕ„ÀíÚÕ„û~°nã½¯¼)ïÙ“M4O¤UNßÂÖvR˜×ğº5¢4&Á[Ã×<ÁVÄ[PŸæö÷ÛÒx—ïÖ¥jÅØv“#»ûÆğª²&´T4È¸PÆc_Ô§/2¹'u2„ş4‚¢ à¥<YkhA­çZmÄ›'tîŠŞxğVâZF+´w›~U¾x‚Ë;›j«a¶/–’¶	Yñ˜e«e\ÖºáÊsJ$²^Æf%øa°+ş´xû!?ÕB÷Â‰3¡'î Ï
r @UH®î1Ñ`İ–òÈxùÀuÖ©ó\Ò‘ÒZ€Ë7ï¸“$È|Œf®®ÈĞ7h Ñíp¶¾Éu‘Öîë#U¼
úòw(‡ÊÁf@\]éŠ…)üûW•pÔ.Ú*ÜiÄËpíeÑW¨ä•ÅÕ3şW†ùÇ×B\#‘=µAáÃcã¯¡°°ØŞN†/Ì¢ö­ˆ=,À›µØ)´\ßlÆã}§šlª8~†ñÜa{
›“*ñ ğ£ğHZªR`«Á0ş<ò/&Ğ}Ê´°¿ÛÙ×ùTª—İKâD‘<\eì “²/ñ‘yœ ıæü,«D[¹õàî‡A2Ò¨›îŞs_O¸²Á²Ã»5là>9ìp.Lµ{Pñ^0X\ËÓK*ÁŒwÂ-=5„°n³7˜îÔöVş5m½éb{F1Ææ/£ÓNœÅ¥VwÏ£ÏÆLp½˜ÚğMõ’¨‘\p¦ù?¥Ñu‚ÁÙ!#œ¬<"$Y¬ß¹õzFsl°|òä…¶•‚j.Œ„]ƒKfü2!zD^Üq*ÔL‘<\üj#ŠÏ)´2©0ñ³wB¢”¦´é¾ñ¿å&º¿¹Õ!Ğ`H÷¿dú?ëU°ñˆÊ–û“o¸lv‚C<ï'4Í9ÒôÖ=U÷¨Ìm/3Å¦Zquï÷dÌPªi7(ñ¦ÿ«Èkº|qV¡AIãÎ—¬ïXcóİãüù˜êĞ{k7uïUT›T,&.‚¡L­w´Óä”Ë!£…Åë¾öA>É;}“|eñ`xB3H½ˆí“²öJ5«e]<rÜò‰	çˆ½Ëf/‚ÙPÆ›“ùp,Èšr;“4š¤2÷hÅÁ-wˆkø«wb´‰j›\éèôn	´X!úòà¦XÃÊ$L@¤¶BğÖi2[ïÌ¸öãÛé“ıæ£*ëˆpQC‚=]Œîtàp1Z§ı‡æb£nW¿ŠBÛU3 ¨?,n#%~®ò	ÖCÂÒÚ$CCÅpÒæ«Ğ¯a?a\væèÒ€ŒŞæT|??£ÿŸŞ’:×;FPÿYwn0¹bm;Ã(løA9^/›Ø¦%¦o‹SyâL%P¨§ÏJ®úDJf«3Ë¬1‚›{hIaLCdî<ñ°øKÛc*:2¯K£ÂW=9Ôî?|*Å=;Z°8Æƒ
	‰‘¨`´¶}˜w¹“aùÑ)'p;);´µ†´¾Ks¡ÿ‰ñÔl|(Š®·ñ®½÷œ›j…&¹0·ä1 E‹¤Ó?€¿ñ-M”ªk¯úEhşJcq‰àú¥iLrÆ¼(dşV_nCqI@YwØ+?ï¨#¤.&ˆ75^Fî¢øÍ}Û àô¬°5YYUÁ%1¢vc¢eÌåÚìNU$İHJå¬|Æ Â¦l&F/zós”iÿèÀw”wAp‚?TU»=E€iàpaÙÿİ¤HˆUÆÿƒ*U1!x‹Â3‡l´Ş(EV'ê/*sıÈ(qAçÒùéÎ-O|è:D†İâß1¢¦õ[åÔAXÌõEŞmËÉñ5­:Åd<+äaİFÑ°€eŒoÿ+ÿ`É-s×Œ~NÁÏÑìy;´óİ_’´½ılq‘-Ñ,›1‚(;hZÉê†íˆÅñFx—6Jì•­K–Õh&+PœÒya—ÁOê‰,¿MKÂƒÎ Ù}|îX‹Ûş"QËë}/B’}4µŒ |6,úanyånsY=ÚÉï_ìEünB:Øw0ªEÙÚC¿îìç!í•yãÉ½2‰ìÊ¢z»×0§¹|¬òC°FÑõX~ß.GğÓYì#çÌÂcÑ‰Ò~şØßò|1Ø|§+¯å5Ì§‰ŠÖÙºÍšIıKV!Rlî?ãŸáÕ×pY/….K8÷ıš)âY&Ó’ÏÓz^ºÌC3üÅsW ëÙëE±%K6!+zËj:%•sp1»ò`1pEv®~Š«Ïñ Û'à°(úk°¬’2sjÀUŸã{Èyw»f=ÌDx'[ÿ¤æşü3Ãš°œu£	Òéà¨[óPÿH:(Z2Äñ;¡\Şs 5«‰z $:wVwçà\TX(Ëuä!ZÒº-·W;wå —sv‚%úYêJZaŠı³2î5‹ñİƒV>²“Œ˜ƒ:G‰C}V@åsüEqó%|Aê…Õ™‘!*ÁíĞ:1Àëb£wˆ)å%d.gß’˜ŞºÔÛ(‚B¬Ì³ $WÊ°ÚM=elO31lĞ­8Ùr—Ê­–?^Ôh¢ew	.œ7'M©Õß®_¯LğµÃ|à}Ğ®ÛUs	°04†¡ß—ò¡ŞÙ8|uêWoÁ·c}ô‘4Ÿ½0©ˆ%Pµgˆ~òŞNóKÌø¡X›Š{¶É¨íwôu‰{×~I~²i¥O@oÄWÍÅ^Hê*‘S£á@7°h$ÏÕG«s]¡¤­3•GÅ1·;ª †RdÚbW
QÙƒ9Ç‚"-ÂŞ–y²„×*…ö‚Á™[Ööf°Ç¨ãFéÓŒVêËk6òÍ+iàrÁÙÌÏ¨‹/—ƒÛ!|Èe9ÌH³FÃ¯?=ûVÀÇÁ„Ä¾Í^S^U83Äã”»%•f|È©?¥¶ïõ=\+yff_ÉºÇã‰Ñ¾72“Ø)­uˆ:z@“Îã8®1$æÄ@¨u‚u“&^Ä˜_=e­Eğ,«:.ŠM}¥†‚k ª_x%áÖAß7ÚW×”E–; eáª $´k¢¤e¼~åµ»Ä¤TheÊå4¼KsLÎq²v
ü²1;ÃÄ9×ß0»í]ıâO?Œ=íŸë85q-YÊ’°?Ù¨9øêG|vÃÀÄ¢O¼]Ó…‡iO¿–ıº»^Ê¢bgçøùN…ïú÷ÿ\–¥æ¶sâé
åIÍÍ1ù
H3·a¤y Í'•yóF·[<ø;D”Ã¥Åe0©‘@_I“ÄBe¦å/ĞøÍïhÒåd†÷+ÍôMÃ‚~µ(°—üŒª3tÑ\â¨+8àyÍK«¹·­¾L]¬¸¢)Ã{»”Lî’³š+ÀüÏËµR#Òi­ÚÅ/ZöNHûtRÉcpÆ	1dgùWr~¦ÖâÖË8;Î‡ğ4ğNğ9æı?•6üôø»
„+‚Bvª ø—ëàÄÁµÓèŞ^Šüvú7fD*f{³ğy3‹öóùŸ08(ò¯CÆ1OsŒÃch*TÙ‹{]bã‘4äº¶½y¸(µfÈšÕ8¦ß&8öˆ^>ÎÇ
«°!òvaµá§ä5k2„¨É^)VgÎi¼¿F”,9ÑÛè#A¢†ã_v
Æ«o8¦İ¿v%ıÕ^2q zàI„¼%ª<-¾MfëBë½¶ÀMƒh!§1!;O¥yşæÃšÍ*ÄËeå­Aò¤u ĞJj$›[!‰zúùIç¥‡ÏµU<RsÈŞw—e¹]äÓw8­*÷ü1ò>’è›‡é~ÉÙïá;/ı	LRğ³½ß(“ÎÇ™±Ö„´¢é¶½0zÌ¨z*eü[sÇ8=ÿéN˜»½¬B:tT5ïôöT #Å››ªjÂ¯%ÍªÊ øo…¾;æşc'À’‘Ÿ†¬4$¬pÅ+i‘šò%$ç œîQ-m!§˜Ş°¬ÒŸíH\™÷Ïûn7Å‰¤lMä–ŞĞ.c°8\à>†´º>í.‡·QŒ¼!İ¨U
6¬±“œN„EcÆ½-˜X¼l)NÒsÚĞĞgÚƒP¤QÆpß™I$ñûü*7İürI°Ú@Ü4ë„éCë.åQÙ§<g"iLº)(…‡3W›¹Gâ³æ/”œ† ¬£˜ØWñÙ ¿?qn¼Àö·<·+Æ)^£0£¡ÓĞ(·X‚ èëâİZU.°]cÚ§êeêÑı%œEfª/O>ÃVDPÌG"¥kÿUÄ*m‰©’oî}İ€2ßE">‹kµ’»ÂmgóÃÉÀ—Û‹RŞä.bHâI¢9SkËÀƒ	™Å§ O†§>3Æ·äÎ)Úgñ€*„½¡œÎÀŞPçÁ´¾KÔ€>\Şûü¢´#ØŞn>şàù6‚ÔÛ!ş?…êb­€ÌÓø§q·0·ïvÖ)50¿RW$Ôş`í»ú’G8³
NÛã™÷íĞ”b©²‰¾Â˜™²`¢.èê¾r¿ÈauHGÑ ¤Bá(#9Oª-PSf—25ìKD÷.D’|Û¯º_2òL£©Ú¬iÌ€aë£şÚ÷jî¹EWo3{OÌ†&²èş›¬Ù@ èÄrÃG­¤F]ÖÒ«í
T\7+Ê¼0=­ÁÔ.˜Öek¬?UYìÄ+áE·ûÂöKkŒh-ßÆs{}ên,®æ0.gÈiİ¬yy²Åö@Ê]¼4R>zî™BÓSSï ØSÈÁuÏš4,t§‰rÚÊÓ²‹ó:«@NC°<ãòËÈ€.YF¡¹Ó¦Bü¸©½—a\û¢ñ‰DéºBÚ4\‘oWF¯œzy­<³ÌGV?gAœ!ñ?§™µ}ÏÏa& ¤½h”ùs{RU1°	µ>™^Gp®µõñ„ó¤wD`İ}E!g~§b*Üs`wÀ‘'ï`Ì<…ç•rê«tkA3ÁÔã‘ôÄˆ¸>›ìc®Ê‹ËÃrönàßsÀüzãô‘èÜ$
îDÕò:ëÖÅ£h…vÖño©¡L-gÌÓœP±\ædƒj¢"™ğåóh7Æ6û>kníc¡]\…Ø„š¡Aõ­¡.¹‰ ô=4’#ÄìyK‡İÌÌFIŸrRóc¶ÁƒvuÎ:]P‘s¿KØŸÈvGüĞI¨%àrõ/7»ÿi¨‚´íÔsz°›N±iVO”K®}#á‘Nx>È©·À}İ#ILf‡aÙHÕ˜¿ù-”Úûæ›Á"Äûøƒ÷·iA¶·8Á8ØĞ|ıŸ&ÔİÄ8\"Z¶]sp(M¥eG^‡tl¼Cx²—ÛƒªêµÁuwmO»‰k‘Mj¾Â¹K4tSèâàÌhŸûJÔV=OZizğıpLšR†` è¯eö	€mg©fÃÜ¡¬ÁÉÂ˜ÒR²¨Q-!v—'»¬z§\›ÆÕ´™LeCu`İÓŒÍş×O¿^wDgı·¹„
"ï4œ:ë©&‡ú1B¡1¬ ’Ã¨\ª$1‘m°	cHÅÅŸ:ÄL¸{-_@=ÆkÃ·ª0?!…1€äV¸H¶ ïª¸ÛïïáÚ^¾Â‡ÕšG¥(ë¯
¾ÊCú6[‰œ"²“ó¶~aM.DÌ}­µÏN?œK¸Æƒ%ğC€‘ì\®ã±&X‘ZÒƒİœZ87š5^‘#@¡Â´ñÙÁQtÈ`oh¢=üR”»g«4¼UØ=e *ª…i¹şå`%ŒÅ^›“³ù~|u2Îq_µ¢K![0ùKNM9#tp-÷Ğƒv:ìJ§X5À½Ãì©±5ÛÁ¢3~¸óBïÃH‚^t Z‚•
˜Ï{Åuaó?W?#J¡³ä­òÏûW±
`*PŞ«SXŞ²àÅÍ>»èà“Â£éÚs'¬vˆ5¯2Gr< [¶5ºÿÅ8í9¤A)›†UğĞã _‡‡˜Ü™r;÷„T	´\!-
F,ËÚ6ã¤®WÅi¼^@ÕÇD?o\cS%ÅŞ´İI„@0Ëoÿmø˜JºærnìDÀdÜŞ
=¼Ça×o)ÔşSN5F~\:Şö'¯9‚Ä“Ù÷¹-lÍÇ¥ßÃ›ºƒ ‹Kq?	‘ÛçÇ};tàiD‚>Ëˆ£Oƒ[iÂèDÔZ³[ó8â0Í3Šªş¿:§u83Ù”j£›Øù%‘cBN=FòNø7/¾×WŞ0Û‡ÌRé¾¢§¬+TroyÒglÚ•Q
“QhA™=:‹d·ˆNvÚÜ€û»
Øí’¾‹¶ìš.éùô6=Àë_£J–pGÓÔvÏZµêıı.Ü‹{øz£€{Uµ§ËîjzİäïŒÄ§ú¿Kçœ¦•…R±Z™R¯ƒÅ7,˜lˆ=y]Ä1¼íŸ|30.Ô6İ4aˆj EV/
ºíáuJ’˜‹·šW:ê~işñ×éÙŒUŞĞA>ü9BŸx±á
43tİXŸkgâR©©Ãr-À¸oH¤1 wpŒ§^;u}Ü†Æ(EK´FÆ—:L(ÇğÃ‡¼<49ØØhl
´Ä+r*Ş-5nªã×·÷1d¤Ø·YãÍƒï©P-aÊz7‘¹ÕË-dÓ—Í,-¯îğ­ç{b÷¥ØØ+½6Îæ…n!)ÀÎä¿|F=83wGO9ÒÎãX½›§ÛYÈ89B‡ÉĞƒav‡bÉ¬¸X£²Ä@QSë#/z¾C ¹Ğø²¯æ9k?¾TÁ#Ern=ˆ%×ƒ†m4aL¸—QS”p³ë_VLÄ¨¯=fÿÀÒ/6&!À2³>#‹ËdÄ7ŠĞ?ûÀ‹ºˆæ–æ­İoXõµÜ4/ˆîhWÔÁZ¡nº³ûQ»Ğ°±*|
ôR£Ü\Èb$çº‡”Ù÷¾—çSÏ'7ÄõqóÜËMŒ YijÀX¢ÿ«#*˜·í]-Ö”fŞ‚}üÎ2zù˜ßWÜl¼B‹‘…SÙUPH/UÌ§òåï¶êV [A ƒ»~Ş»Mêğn&é9?¦ÜˆûÈV”°näÈ„=º†–ºkLş
ìeÕÔe£ïA–`#\|¶å7ñÆdĞœ,&2Ò•3"d‘ò œêÃZ£ÖğSìçF s_-?Y*´Äx£z×V›Æñ¼ĞëL™£—ì)Ów´ <ìIİL®–¶®¹Q±«at™‡Âò1I¥‰ÏŠ{æÑ"%Ê`´âÒĞt_»ø¬›ä!ç…B0+®Î,‚Â×XvàÌİ™¯[Db˜ÚØåÒ”‚K¾› 	7Äÿk’s[qâŒ•ˆ¶Ec¹¿ú>°¥v8Z‡ÎÕ`¦tñ»ÖéÎ„ßã0ÿ\IH@¨%é÷Ñ/Z	8°#ñò S`Òvò¦†aÔB£6È= 7¹h@€Mû!ØŒş¤Úˆ"g÷Åƒ¡Ê R(pL—A¤İÜ±™%ìrrŸÉü’•‹ó6Úª¹…p5œ`ˆÏ¥pìÔn7,ößÚŒe…N¦ ]Ëb…&È8…nQyeWÿ¸Ò7£B±LöS$ÈS›'G"Ÿâ×İPï_3±®ZÄbƒ•JÎ;u:T%ó‘x «Ã=‚á2-¿Få”xC¥2Ïß)‘ƒOYã.¹w½õ_•ÜİZ¯‚óÊ«Òøûj¸‹ÇâÉ)ğØ´ªâêpİŠUˆOÏ®›ßû°îBQ­'O`ü“6šg”?·ÛşgÌhŞ)ºÍ¿šı—øà¯¥«\2§Øµ«Ü· ¯µàbÂğ/Dçzù¢®_Äîªù>I&¢8š$¤]ŒÓ¼–Vé5<S3ìTÅ?Ö»ïô=Êk)5óZZ{z€Ñ$z¡p}c¼4ú±× 
šŸàDV\1|H,‘ˆ³'r6!ò7jXíy ƒ­.ş¤ EúšÑwzÉ†µÈäâ=ÙÛ”6;şº·lB‡àÜX±R¿ÈÅùJ¥ê'¬‹jNN=Ç¸şŒªãHO¬•£=¿êSCÄ}´ƒûZ\	,‰ë´æo’*æ‘e²˜UaæİE27o ?o.»°GÍß°Ï¿'Ç	A¹ùÜñDâ¿ 4äãT½ç‚óEb8?Ò|ø~ë¡BX%_Ïû[Ù9ºTp9Ñ½!tÄé¥øã¯ìĞw×‹rĞ†Î‡õı|”¹Ly›Ïnà¤§Ø_Áœ:½øíüÅ´S”‡ËCuE?­Ü¼ÖŠ§½ÇZg•VK´Jsêb`JæW ±Ue\ÕˆıæjÀ;É–¯Pˆô3­€5tÉí«±!Aªˆ&Ïsä÷Á‘93gƒ”Trù«M”Ö'ÉùÌt.àaè²°ÌSN7ŞÏ®¸¯~ËæµÜÌd,S!Ö8sõ±ëßO©ä3ªáPO–k÷$,ºÉ	Cd ¹ò·ËƒÜS‘ÌG}İáÂœ’•»!4á~%ÿ™«3Äˆì¹ÂGâÓœš×;LéçÖ8áêé0`áÓ3ı	Ä’sUÙ¶ÜÇ”1m‡0û¢,À‘]·ï*!íš¸¶ÔŞQtÉ¿Zm¾gCúºs®…:è¨Ÿ25¥²Ğ
p”Á;)<IÆrğİ£¢r"ÇL˜‡ıA´DoÄ%ˆ€ŞP İ¢e´t# luğ
Úå|Aµ#.C)¤j{ÅÄeF‹	1t\d#M¤ÈfL`]µjvW<¦Å¥¾JÆ1<pßHİõ²çíì94Kš~îÊ kü€?,ºé½;´ó\!ŠCÂ´
Œ6­9 Ò²Òö¿%„Ä6Ú×¿¾1 +E¬Ş>&Üš†”È‡é6)jœ¿Ê_
Ád§N=SÌ¥ıÖóK/ˆ\µ!çÒ.ª™|´<]æ/ƒ¼µç^‰MVIµM>†­%©ßÛ¹·«˜üwv"Á° pF(A·óyI°¸¥†%ŒÄÓGş;àGsFPà§÷'§¦<fòy©±ZØzßK¥`,ë¯Â½”d7bM5ØM¡_¼N>5¯oòUPí©ŞË
1Íğcê¼ÉÜæL 'êêpšî’·º4!ÒÆì¬Øl„³=>ò[R­Ï"N½Y:6¶ªä8$ÄÉ{d“Sof=>›œ;|ÿ¤ †Qï@ğõ*‘;Ó`«t¶`À®‘†:æŸ˜7ï‰Ñ`P÷Wù[:Õ£/9ØvtP•íáÜcº¿¹*Ÿ‚¶¬
ø‹P*Fõ"Î`ÔÚœ%~Ûÿ·×i,±Ò‰C‰ÑİØŞÎLJ¯8 CI14ÆòîÚƒúûqÍ«ì@Ÿe&UÃU32¬MØøy‘î—Æ¢Ú°ÌÊK?Û6sÅHòéá9ş´²ù	•`<õgÄ}û2·à©löµ1W-ûÏÂØKVÕY,Í½I*J£8P¬ü«å |®Œ¢rç’§k•ØÓœÿ²Š†”›ö|WÁH"7º°Š·Ê›o{Q·›7¦ªÀ$²DØj&t„I™-³œ mÂE@Á,+€è®RzZX]é¯Ğ"OxQUi’¢Ò\§îğ¢+(V õ’Fò8^ÍÍ¨/ÄŞf,ØZ~hıW„ D¯)Š1è“J¨#PÚğ·Hı¡í³.9ÿt
<£Ç"”ù$fz ,_(T®eØ’ânÏ½òs½Ua[6ß½â¿ÆÆG_‰¥À#úû±mè$•ÍIQó¯:~}ÌÍt3û¯Ù*yOå¨÷¢za#Õ3x]PŸ…8è ¯İ‘ôî¾Ğ\jÒ
Â_}Tå½U=9Æ‰Ï}¶HÆÀq¬¢c%'FgnğÍËgùm<ªX‚I”Åyya‹Ÿİä‰Ä<agÏÒö±·U@àr#%ª%ÌáaT‚C•j‡3…Üu@ú ©åÍ-vè;03;œ˜õ8!İí2E¬¹ÉÈu›D¿9aVŒ/ aÖĞM™eVr³–P«î˜Õ•€¼|}Ÿ ë*ê¿äw`Kã·2ñ¹ò6·å¶3G8ßúö¬„šBäKÿ›¤N2<|âğyi%u³¥j“£ğvóíïÖ>\·µ[áVhüùİƒ>‹TLˆ_'#­À³€u} ôÜ]˜íDáG]Bgİy†O¬¸Ì5¶*;ót%¬Õ¹,J’ÛàâíÛ“ßØóaùåYv˜‰5 €ş©¿™Ïm'å?Ó:¤Ø±eÀ¸mKVµşóFÔJ	Ô­zÜóäjx¨½¡¢9¤Îcké5«	f'¾&³c±¤1Å­¨pO#×|™É(õ„j{Ù1E¸Ö“7éRÁV˜dâ…Îg¡^äyX›Úóö™İ`¬¥Œ}I‹2®“lò+PñÇ[|…í¸µ <q·HûHÄ%_‡äĞpõríØÓ¥´xAY{Mt˜¦È¡˜o´ÌÍ„Q^@Ry\%a\+Ï{ÉNxôUC;vdEt‰Cğqñ4– Qmİ=/Îğ|ˆ9x¹ü74¯„§İ¸{$¯›Ñ~¿"û6Ú®ºÃ¯{uA?8––‰-Ê"şñëv;®™#œcc&­ãŒ8o%WVÂiÍè;±2HÌ2ÕË¡}»‡"íÏ|cqÁ¹@µ—‘á >ggBí†Ë™Bñ¤[æî›‡2›½™`.¹JA|Œî²ufÿ Æƒ‰“)˜ÿ›‡¶R×{ò&Â \©å¼§AX?JÔ- V…GÅ-¨.“¡Iiàµ}»éˆyÔv4a:¸=Íèşÿ€¶(m
Ü[@Üx%&jŠ¬wëw³
£r1q¢q äøŒÃÛ/(®‘®|üQ±­˜ÿzó¸a­óõ`*[‡ä„ñöT¼~"­kç8bŸ¼`U)ÈßF#QÄ¶°­o¯“Ú¤kŒWù æîj»ôà{BWÿí’P«)Øõ#w²»‚1û]ÊW˜¢ï®»Aq²ÔkW×OxÏ­s	K\@à]ÎÎä>PçéZÄRl¼<zE=É•C%	";K¦
Ísúªö›±òœŞÜ©¹×K’ÿ1Ú®Ç¨t¶İI­‹/¹[©Í³ôÄ´‡#W_:é´[L<MÁÒÔ'5İñ—…8ÊÒ?
¡PFÜùÔ©BÉxãV”ShãGÍ9±+çT(öa~hğù,—Í'²M;~B.„Î}1.÷hŠ¿©¤ÿÂê®¶½÷ó›¦ãéŠ†ªı;L•} ”vœØ¡k—\¨òIülO ®
Ÿ˜S;…óGÿ5Xï§ä*şÉ{%Yœv‘â¾Í»ĞşVBHù°¸áè­”Ä×	8:c+Nwúv¤EãlÄC0ƒ­ª#X(¦Ÿìå‰´ğ…²¥0(¯Æ¼ùTØ‚Ëâ5ıİ`Jx‡ÛÎŞ†öÉhY{p5à·ÄpbSj»ÊNÑ'<'K[­_>e·uT9NúãµşâèÚÔ–’.}•>Â„wk¢™¯ÂÈÿºŠ±_ É	Ş°cŠŒKT¥P·FdIËØÏ? Ó`Š4ÜÊ7Û‘à:ØïõÉ6²DŠ¯»¡(—\q6mĞ,G ­ÍâÒç);áĞG¸’$`ãE¯ù:öYVÉ&r1paôXHĞäy0ÂH‰=F(æqñ‚s?˜%¡ò‡íxİ9YÀ-*jÔÓ¯sY½B
~‹¼qè9hªT	‡Ï:»û¡ãªRf,¨½+"TZ.Ê»ò©ä‡Ø,@t=X]aµG×«¡,àP±ÇRÊùcâ–“ŞsÃä$¤€zH{™^H_¿%Õba¦îÎ¨gî‡BÂëÒâP:¬ğÕ²†âèAÀ—––ZIå}3ImØ}Œu½ß”¸‹‘nôqhï ½b?Çôh_XúæYi›ªÎ¥³MFİı—$Ÿ#€Ù€£©ñ¢`Õ{&ûz¾œu6Ò7Ú”©ƒL¦FºÎw2¼‡DõIro:îz.P«¹¨_lÁ+a!AÂ¿‚‰#nxÁÈápcés8äƒÒÙò‚…2Š7@––V>Ùê¹jøO«MT|Ú+|®*_(J¬rÜ
µ£jNd?0§›]´õ‘¸ŸecÙúÀõX™tıVe-’÷@
"õİ:"·Eo—-ù drŸ-Î¾ÄÌ¡M[Q÷{Çcõ´’­'êE$«'‡Í€–sÉÂÒoî±ÏLİ¾¦~±$ç?AA<}ÁYuR×òØ$ÿK¢îíI–t†ùDÔËj0X8²~–-ÙfF€z‡TıŒî£f&“fMhÁ… _® ü±âæN™†]©·zíµ*]ëa6×Ç¡[u¢Nä;¶İ{d15»u \_åµJ“p{‡]¸jãËrŒytÆDóQh­®×Rû£Ã[÷üı09N8Élƒ¢k€ìWöÉwŒ´ÉÿoP¤.ëlE}Ùê)ıÌô{AçP©½®Tzıy¶æB¾C‘òòĞèæ@T5<İÈŸobi¤†¼¦
ákíëoµÅ<ŒLëò¤nÂ«8ƒ¯o4©@=†dSš+éÔˆËDc÷äsµÈŠPŠÑ0Rk‡{¸â{ğ×¸ÿ¨ša‡ûá Ÿ%©9q®è¨4Zs©B;(/cåú%¸ñöù…Õ°Yg¬î~?W}^Šs\ˆYx—Á}¹hl¼óCÎØŠm¼^ğLÑ,™PÇ»]@º"²0I¼üQrŒKW7PÜİòl”J>$©›\`­'*"uoªW|´´Í6„t-O‰—ûå¨ÀÚ‡_á.éìQš}¿ÁóŞ54¬§š•¤ıs6#¼&š»C¦Æt0ˆ-!€´Kçˆ¦oœgİ_— JÊÀ´?·3p%.Ä ­7Ò™Y¡Z@…¥èF ¦(ÅÄ fDU KÔ2şE7úŠ`«µ¶ñÔÒ„ĞeÖ|€ãıjªÉ……=Í×ü³>ÿ[·Ö”ú6$ş#tÆ˜[obB1Jm-âCé6ïÈ€Šë5O2è4 ú¨po˜p<ßæ¾ñØ•ó^ÉPƒÔJÔşEkãÎğy™‰}èàµV=õAªs5©/ÆOKEËJÿ{èæşº¥˜ó)]OtÀ#0œoÿ«mQß)UÏÑ(d’£5ü*0åñ×ŒÕÉ5“ÊïìU?”'yß÷Ş'!ü·ÿšQ¾8úèË‡VrJ®òètİQgª'yÎ/€º$9¯ÍˆŞııŸp–Ä'nÂy«cövàï°J›Ê×RŒ¨™y“m¿%›†f †\…%Lã–¼O
˜ûÒ^Ìa^K‚‰nÀ™¹²?R7Á_Şº×˜Æ÷b{/X¿y*”}™„†¯1áê

¦ì‹Š9K3ú+Ov©_"<íM<0‚’PN;—$Ÿ‹Kwf.jÚŸ9‘Â³É¨^ğ½øú¯ÂğÚ
H˜,È´êºzŠ£e§°LfÉÆ ÍJÕŒ¿°TÏg1“Õõãü /ZÕ¼~KûH:^B³"U4`û½ÉsùAÇÉÙ»2 ’XF0¸Ô:Î±?™Oàf³MU€›ûSGrœa`0UÂ!M}&3¶¥ùï8e-Íõ‘‰/ğÙƒ@+|&¹ûZXlÕ¨²"’KÄã+Â–ü£z0›N›c<Já*å;<QaÇ4Ğ"»¤è6”YwNœœàq`ù<Z7Ü%-¨ÙÂÛŞÁñ8íîëò|8‹yª	Ù@XÍ¶›ÂCM3ÓğŞL1Vÿ°ƒÉnêg8NR%g_‘ÖÔ¦B‰;rI1w´DŠ7´']1i6Q¿«vçFXheßbB,íUÁÕşÔÇÄJõ>E”O±-LÇø¹RãŠÑ<Tèwß¢n-s,d²-Šta]iÒ!]a%.^ò÷‹ÅÏ`xeÓeòmÀòÍ¦ïÕíVs\¿£·IBmÆWŸP¨•7'¥æ°¿§şİ–-Òˆ_,ö9u¯¹%
Pö¥Â´òs–qÔdßO8”Ù;ˆ¾ğDòXv&öõvÀ!`A€¶×åËg«XˆÆ—u)¡ÖÔ©æÏ— …zGê/»B‹×b±;O~+ÖÑ/‡şÖ/NmıÄo÷Aã=kÅ ¥.pãÆcGwéHŸTúK®1ƒíà€:j‚/iÀû¥úofG¸ø›!†çá¼?§ïv,VWDqÍ/¸ÈoÇƒö¼—!òEDlùæ2PO»½5úÔ¯ìOÏş±Úç*sø-Î-ñd«ø„îÃ_ÏnQ;‘o€ÙC2‚ÛwÂn¢Š§}º›	^DyÈ\‘˜m.Õr
oÔiÄ“BÏ%KŸdh¯G78¹öUÕYE„úæòÉ6úß¹W°>vlu6
\
$Ğ6/cìfğ€×ú²™ç2¿ú’ªÔJx8†¦—³YÎÊë3%(.áûÁäfŠ›ş¢Å²ëu}†²³'SÔF¦œÏ˜šÂ.Ña°.¥ª‘_ô˜‡ó˜…ø®Ûª€é‹zªÓ½¡àW8ÙzÛï¹f‰+%+pÌÃ¿âßUÌÍ@ğ–FwêPv9Ïm#©´'¬›Ù*åµİœ+B:'Ó[»ª/.
åOŸkW®k’!¨ç¯_\3W1RO¯<‰XUÏKy¸¸SØFàùÒÏ%İì¡òšQW™"t,Æ­,ô°¹^>@Ÿìşà°tî/!q²ßqLix×·¡Ğ<6¡n¯‚ş€û¬³°üyˆ%+AÍ@„Q`Ô•ÂD®î|ÖÀBìó—ÅDÒ$éÈï¼½c¶£`¢t7bØ9ZPv’òtŒ­A´h}"¢ì2DcPäÆÕbqsï4E­»b`
‡’0lìqş’ìürÆhuB§N8ş,íÁÜ§óÀ6b½ÙıÆrW°Í±Àè]:·ƒÀVÍtqUIjÈ¯Ú·ûuÉ­¿åâ¿øsİZ`õtÍ×ó£³ò>š"İ)Ù±€¤ğKÊ²%€ùñ¡[®æŒV¢D¡i–bŸ¾»AX˜…‚³öµ2áuú0ã.­kVNDuo"÷é‡#îÖ³‹†ÿÎiy|DŠhcM—Vêò‰èbÊ¼õ¡•–$LêØãJ÷ü:-—Œ¢Í|h)y‡¬DIøî5õp¨ºÅë—x²¸–ÿQ c.§c¸BÀ4ÚĞ]¸í(Íh˜,m»œèj‰‚Ø’ïÒUºc°Bt/—yÆ)¬|ˆÜEiï ±.=¥²°è¢™OGÑ 2äìI´t©³àĞ–Ş3	Ş>¶…®´2ƒŸšPÍ1`Ì²Â( ç‚5D[cÁ—] ½åÂ†ËUËËH^ay_2ºÓŸh´4W >¨ƒWBº†Æ"ˆ=¿§7Ñ?Ç’F
©Áˆšx¿Ô@ûM•N×£
ÜgŒÚ¢.±õš¡)™7	vçiüÄ­ûfƒÂë|6}ºŞL‚:öqğÅºö–Öh¯»Ú~v)³P·à»Ş,µEÅ=Ù†ŸÙT¡½NL.á Şæ‡9Ñİe–„M÷%º‘+&`Ññ#v€ß¯Ş~&+Ÿl§Ùl…‰ó\¥*v'Ş§«hÊ¿Cy)Ù¡îT¢º.•íömNnLqÿwÀæ,‘Ùş\èL.»‚6ôÙ C”JÒÅxØÅn½ÛÕ’Î,5
ÁÍKÅ¿?‹ßêğÒ”<,Ôbr…cX:İt¥I¹Ci¾i»w·÷TYá1=Y‘Â½ôrt-røÄ2©‰Š§ª
¶×Œœ,ßìOrß½ãl©RDÄ^>_Û‹[Zµà©²&gRì×Óê§¿ª3&’î8“‹ÌÀjn²Ù¾çîûL4ÕŸ§»}µeÊ¥ÖÊõf¥«æg°¥Mf8”¨²hµëàD±L5šTçFÆæ¨ş-—1ÄøÑayÎ8Í$aqŞßÆŞoşa[é* 8Ùó¯ÌÖ)Š4€û$†å3vxiÆsş‰¯ïïH1¦Ôİ°Ä„P¿
Ï +?Ô³óâ@¨ä+ÔM§tQÉ£÷k‡Ÿ³Â@˜½ş3©ËòV–Şì!!—zÛ•¯ù‘åãÑ×?õƒÇ3Ûo‹Ê‚òØ;‹JMÿ6ÜXuáñnğQQEŒ(“ğ\]ğÛhÜ‘~Å+<Ö÷®4ù-ã®°3:¦ÒÒG…!z5ñ¨Fğ•Í“Í¡˜¡ÈUwë×1‹fÙ*¬W8şˆû*û¶6³ãîÛVw´¸Ê­Ìá‡X=dÁ…9?[„rc¦«ÓV&>Ã°ÔBÒ·½Uk¥úØár±÷…ñò©ß37{ y¿z^ñ%Üåƒ`Á^@8Ñ³Zƒ_ˆ[1 üò¹	ßè¸Ã`>¢^áèsye°zìğ¤£Òq{3€@9GÑ%”\
ßTø¦X9«X9¢¿ojd|13U³É"†¨IÑmukÌY×‹Hº$c½=¬Ü+™<Ïôù¡ç¬zØ`}7VgkeÓçİQL“Ü”` r¤°mN¬å…ÛÖˆ¡*œnŞF¹€oÁñIßç×i#§,ŞQŠëLì¤NÄ«‘<£å¦/l÷÷‹Í‚Ñ&;Ô0Éccñ¹¡¼!¶eí+&›¥â‚§tEX¡ÀÛc§aÖÏ÷VVöpãÎó’ûxãd“ÀD°<ÁyÄÜ0gÿ–±	¿Š(¼tYy ‡C$š»à|¹y#¾™-`¦6¸Î:R•-ºN^|8õ‘Yˆ|¡¬ò‰{ÑBç¯ğQÈ	t#º¾@‚sK 5âœÍ>ÔfNŞÃúµ5Ì›á•önq÷@tæAïš^ç†“‚Ø„üt)ÀÎn×.JtA‘ê?æ~VŸi;ºVÕÔ?Tó_xEÙäf×Î¥òf©çU·G´ê
N²­¶š%@³b\BàÇï:¦?qH®®\YÛ„xÊP'k£ûšÜREñÔŸŞÒ_³Sn/Âäø„h§äT(ƒ(ˆøâ²^OhÊŠq•Öèxô»¶Âñ.ÿOÔE–Û&¸’ôgèˆ$úN§ô‡¿|pÅñ+
$›aNb0hL*”¨<‰|„õÉ_§ntCiˆløN_Ù–©ƒÀH[ÿî ÿê'CÆØİÆşÊyĞÃ¢–›Š“ô­ÍÒ²]ßÍ3îb±˜íğîDn!‡íkuŸ”í’ø%bÖnlh:ëR¨Fmˆ€,÷/©É²~š›Ë/=›Gp7Cˆ{à 6’–Ö>”âÚ·ìcº2­ û™¿<PZÆ¹ù‰ûªš,²é[ÂoÆØÇ-7{İS°¶äàlÌ¥*¹Ôò¹a*Ğ©N„CW*¹á“¢×Ç°]ë¯xÚĞbã÷L¾…i4ê±ó÷€¾_lŸqğ=hˆ·ÇÖºD$ŒeK9{jÔóCJöi×¥Ğñ¼¨3ˆó	=c@øÂ×LoNüUÒÕò³g6
ğ¾k=rz‘åjÈ„œpN¹Î ª5BËg¢¦ÍCÓáoäà9~Ì†±İĞšöÂ·:Õ9ä…¦x¤ŸÎ×¸e@[0é]„-L¶é6Üú²‰ÚoÃY#_]#]Ê‰•VN5U*B4Xéåù6)¾XQø;Å ÿ\ÉÊ>æÅN×Ó¤Z{¿½26,TœU?à§ÍÉ€üCÓ©Lõd¬iÄf."f¥z4V\•¸"Ğ’Ÿ§ˆïµ^³ø¾X*y*+ 59ü9šMU}0äv-cô”ü}ÿ7¥´ïlÇnõ¡{úØE²€¨R¹v±ZpWõsŠŠÛåäª¸ú)]é˜Ï ‰Şµîıt÷[—ey_/V˜­Ï%eåÏéó·‚’ı±`Rÿ$ 6=wT-ÍWîAV‡Lc¿dúk ÏçXÛ‡¶%´Rä4¢'D„€.tè)Î]Š öÍXÂ£œöEâWîºLŸğTa:Ùæã[•RñúU@]¡ÍÃ0 –y`xÑöüÅ¢7³¥J8$íh+œ¬u5Ûû—Ç]¯8(KÊçŸb\@‘«]·"=Ü	zRú•¬rSLoW?±³1Æ[f¦V9ˆËeõ[|Ò»±]ğÜ¢åIş–[÷ù®AF)Ó·/Ì:(>¸‡9™Å ®›³´
$…†.LMõ=|½¢‚—^ÃÕ´{%»`)e´A¿äiu¬f	PéBbQlù‡`«Î”RE^•òŞjy†{}ëFÛØClË1»Òi]ŒÒ ì§Ï|ƒ»‰Ç6 N/§ËQ\“Kóö#$ïQDW(ÏB’$™ 9,Å’—&Eú6Îi*àú
æA¸W½8‘Uê,bÇW&ëH+*…AÕÏš„;è"ËQ.ëñßğ¥[¾N]–'ØİÒo8½¯¥{Ö èíkD&"=¨Èsƒ=Qğ ?wMCcƒÃü´Cq„«+÷‡¸ÏÚs™ÜoµÈµ$òRGÊŞ¾…à=¶İuÃQüÕ±zX?–´3ë“–¹è«2[ÌuwºäòÍûÔ®x:zşéñîç’cH¡·qNÍçÎ›"+\^Û|ƒ‰5'z¨Û’±¢u×ìıªëB¾ü¯ëÄ†: @VÇÏ.~¼jšäQ4/@a²&Ç|1<ÛµG™ùY/Àg#Øi¨§	.V•\Ÿªfô¡ØM ‹>Û˜]ôs<{‚±¡]”ø¶¯i¾A•;‚Ä™:ZÅV°Ãcx9ë¥¢+tóŸŒw  iµñv…z¡ëâú"+ŸR]±®§¯wAC”@Ú.÷bLõ1óg…»[gé7×^ƒcÍ¼ub™°ª·Ær0‹<2-æ‡Çô½bRV}¥DUx¯iWœ‡4İÀ$^©ìK- Ä1@˜ŠJåO*k,±@ ¡„dg1jVZVA¦”'Åhïº¤“&dF:KìñÎÕw›èJ/¢Ìr‰6Ëª¶ÓŸ·ÄÃåfn%hıP5&sX]L(ßÎô€Ù;`e\úŠÙpÅ üº…Ì4ÎÂÇÑ^iÆê@ÂáoGÔçß>£Ç…æ;îÔ’-æøot¤¿ü¯`ı„ç‡ÊvJ¸Æ©ÊœÕàLfÏU1Å£ùÀN˜JÅÍ‰]£~É…®ìÁ¿÷¯`ÑŠ~N"³3]ÖÄÄ¶µÉéchÆ‚A-¢²9¹½Ök’¢u†÷7#=®Õ$_Û)Â0<iÛm{Rx³f5ÌòµH†æÈ?’r™7(j&R-X_X¥û—jmú'B+ĞO!?ŠÌ‚Ÿ)ò8ë›bó€Ÿ¬ïrÄ€;alZº@0`“ó­ı*ú=zn‘_LÄ]™jµmGÇ	ˆj­à€Wj‘—4ê@U@¬µ«¶lfaçh¢÷·[®áÂ;Ù8³ºSD*ÖFxİ¢?KÃSºãéÄ_ÿXÌæ4åd‚cù³İ¶áh–xcIûË1<>Ì·"rG>AT(7>“…=âYê~&êäO\:ŠL>Â}iÎÜ·[Çå`^>k{Øm¼dŸ<$˜—æAm”ò?Âu!Â+‡Óæ[šè›wa-e°ğfWD?ºÚÆWIÇ€Ó/ò–§nc–ŒóÊkÏò÷«¬JgHÖ°ÊÔó—ƒºï±ÆT*`ªišæƒ?`‰İñ0eLîòÑ¶‘ÿÂ3x’ğĞM3áw¢Z”' òV`B¨Õ°ğRızxĞÊï´µ^CËãqz1#Zƒ
.ü%k_;G?r©ÙĞ^\zßºÏeÁ»V–ôÎñD4ºÀ­Üé`à+B¿ÕŠ)é`Ô¸´îVÏB19‹_LëÈû*<åªæ&~ˆ¼àÿv! 8x¹Õ^9%îñÓt!SnAû
ŞÃ#àı}•›iqê^óR	8©crÈ{K¢!'Õ cÔÑ†XÄ){³cSD_ƒ³UµÄ]Bd[Áz4`[‡…CHb¹ìıkn¹ŒÛÁ6n5ö„€së  \Şï{Y·„÷”Åµ]q©µ‚y!?>Ò#ÁcJª—¡âhßøÂ§YmøNkÊ¹mÊåzõe¶ì·#÷æ<\˜{Q‰à`+g²$'m? RÅ«MÌ“uŞ°‡K½R17²5—a™.ü§0g-.Œ»Ëó¹cDPn¯G•s†%'HœŞ‚Îğ #yDs(¸ĞXyNÕ;b]îhè¥*Ø–¸‰¨H"4Ó+.ÅÃÓq>˜²ûé‡0v.HÂZ˜Ù¨Q°¶İdmà"cN†)#Hmã^o×¥†¶(è™Óm$kE„i8AäP¹s?¥®¦qF’Ù-ŞĞ$dvãºú¤ÌÕ0>ÅX4ì<¬w¬e9~¨/„ƒ''Ìt8ª1Ñ”í{2ë)œLwÉYÌ3¾?ü®Ù %Ñ?h%OK:@»i®àvÖT °bø›>§¿íğ	ïÿÜévZ.˜×»”;í£Bq¥ƒˆí¿9¥øS}:‹äÚìçúŠıÛ¾1h²Y¯²ü”.šR[J‡pöÏO¶ò0³7£%Ôn˜e3â#¸ÆŞÕfêåã#ùm2»Še«jİ¸WJè¤¤P;É=èÄ“œ¡6´N}ÄÃv-»<˜ãÔ{JPñ‘…¾»#³J«ÛÊ)ÊMCîà4´Ëì¾Ê;k-÷ğq'É iÂ9À†aQG_NĞÂ¨R~©Ú·ÔôÔ/$>®
_×ÅM]`©şü~^©üÁ<Ä'ñ¨ÄúÓEˆû*ŒÒf?uBëÏI´´Í‘cXç$›[Ôï£òbTapT±ĞXÜ6_´Åé“]³JŠôè†ïXÉç&*£~A`ÿ¶ø	/Z£È‹ÿÓW:û9G›¼=}2—¥”Kb§[ÙI•ÅkT´P?tÁŸAƒ@ñYO€µˆ%…d©¦Ò™’¯, 9‚3yÍŠÂz2IiØ.2¨´³"à³¼ı{f‡Ø.•U²ƒ» G#–âŞP8€Á¿¯ÏÙk½©Ã”2‡$Î§=0{‰Î¦À^ãtÒôJ4Ü¶_Ë@É[“'–Ì¯	×3äÅµğN‰SŸ¾A	Óš¹ÓRéSô‹móöEÛ3“ô'±üCÎˆX§\€q/Æ¶Àd)BR§ƒm¦,"®ÓÆ.O&e”à†î›ÿîÆ°ĞÙ¸ØŒÒïùÅÅĞ"Dá¾ğÓl¯™Ëï¢dOÁâU6¬1¶ÉàÚjpoªVâWácš›5NÏ6ô%uH8vqWÜ”¢ë}ÎósEÓç‹*Ôı#—ŞAgà`¥ ¡¯t"K­|W#e;ÎG£a¯˜¶ÄH¿D×Ó}²MÑQ>ù&±I¹óşXòü­f{ê×uštûYá^]¸ÍtjÔÄ[´š§
«£br£Dë	 b3Ãw%HıâİÏß àa Ôt@öı¾b,¬£õÊd€—Ößø¥·z ˜Xqúif¶´"A%:W9qÃÎwÛB²Ÿi¶úúÿjC§“ŠŒ™
†Š¬ ¬µ­°Sî³®¢¼°Š¡Ì}PÁ.-úÓí´¡S¨fÛc©CZbM„ÒtÄİÓUw™P3 İíâ7AW\,è/°Ø£QØëğ5L9$EÆÈ¨zûeU"Ö@òÀ²CÎhÇ’ù½GÑzß"×·?’aÙ£‰çXŸ=*+rï†it¬8½İ†‰ÆÇšç_§cTw@àPÁ–ÖºP­ÇW·˜âu@Ã<€ßÖ¢*j4¾çÌûıë¾‚Rhô{Äâ,ÿkéƒÆò¹®Ó¦æ&Röw#6(ƒ+";Í. ZW AsnÀƒjÚ=t…&Âğó;ÃÈLš…A%iwI¥ƒ³Ë»?P•–±#¸Œ8¶9²GQùjÊ¹£¥‚#’fóÙÓiô¸Òz>S>È/ ©¥¿q#uQÃ.=tKçl3ètçÅõ~À»ôâ°å‚N™2zÄ}H®†ùÄN«Êõö
ëFáÔ‚]JÌSÒêºŠö¬:ímÏTwTDzÒøEMš‹ÃÆìˆÆÒ5ä äáÉ2ÒÒúı˜‘@ªÒ–GŸKVöÌA%ZÙğÌáïª‹¦,™<eNş„I–øHUµSóêè¯ªİG÷J‹‹3l®èƒ.X®ÕØ=%ÖmBJ†¼µ¥#øA×ÛkXÚ+ùxËÍ»IıÔBRÖ€ 2‘KÏ’l¸æ.„œÑ+c×—ÂSÅ‡î,ü–éÛRB¥ú{ù"Z
5\N±°ù‹áxoäÏ–ƒŒÑÑ|‰šf+{2¹Ÿë^ı\êàx&ñ?T£Ì\Ê9¹fV0SæÅZUR3~ï83¿Rd Sˆçtà…Õv…ZÎ¥ä…ˆ5yµËñ96MÕÓ#ó3ocÛFZ×Uéf2ÖJŒ£ÔÈ­,’#1®([_?}\kc›SRu½Çúç¥€6—|eQNhëñ6ÍáÊ›º"Só$Ş•½Èd„tYzÿ?R#rUÍÀ¹T¥ÒhÙ‰©A4¢¶K8g{0,2p”øXód`!nhñ½Õ©[VnNœHå¸X@ÿ†º”ª¸Ù7yT A›Ímæ`µ<½
V)émwB/ğQ¡Ò©usq%—®Ë‰“7‘pÛw±._f¤¯ŸÂ\X‚¢is<´æ´kKWyøQN
GV[ëƒí”P ‡Ñî„ h	9oÅØw–-ˆ¶KØÚß(:¨y(O˜@¤øbÃHÒN,[¤cêŠê0s7ğm”#±a(ìVÀÑgFf9¯<–Ï,şô˜ù¡èCÑ•l,"Vòs»ahÛ¼÷¸ıLŞÅ>.Yÿuô¯“:¥Wè¶[3ÍæB¹åŞ)ÈêdOTÿ\ÕFèü—ñD4Rô>¼}ÆVŠ(öFí*Ú…g¥ˆ¦EˆúÊ­Åf0¬t’Z§²ƒÚæ=r#Û‡¥"ûC‘ã4“¶‘Ï9şgK¼‡2µYÃº€ĞU)f3y—ÏšÏ’$1˜ÃÔŠ¯ğ+'Öúeµ5º…—[L?§óônüvá%z¢²(lËÍÑRI«ø¦øúH9ÉY¦†–¸ôı§YıãÛäz´¶üZQhŒÑmä;åV3É‚?Dc-I:xH8lÄaœ`^E¢×9Oy<ˆ«µ4OxºÏy+Ïö¢*âÜî-KA‰¤4™(§Á)1sy×çu•xöÑYÂ%V¶Íƒ˜E‘ù¾†"ºäé»ä]Skˆù ß‹Sá°Š ï‚S™9Fº#q¯_Qæ¿†0«eÑ›u3ç-7ly×µAõrÒåŞıĞDlêuÚş]t;'¨–`«î>ƒà ÜªÚ³PÒëÏÁuä¸ğu4"–'"›O^ †ZêQ_Ó¤í‡ßÖ†ïiĞØíLns‡‚İ€˜»¶?—šqGûéKqf¹M4@zô½ú
r`¿=–œu9ª›`_×cÕ-X‡AıËş (vüdß·«Zü:œƒsîI¾yü­Cy```—à^¦)~ÓçGŞF/ªÁNĞrsÉˆ±eo3góÉË¼hÑa>ñ÷•XEx‰Ùêşô¬Fà¼!¯ŞV¡»ÄæDùÿf‘
]Ú³u'£_„ÂË¡\wÈËG:ÓĞÃ—]ŒAO Dï#VÑ»÷çm"ú¢Qû$7£Q¾oÚŠê BåÁn¬zX'AÖóc/"¥„8×ú+A^;dH 8%p*‚ÄİósÌ6Ê½Vç½cfÇ0\ª¨´Êú@{¸æuúğº «|Ì[Xá†ËüÕz¨Pl [HU(5b¹$"bM¶˜\9Hîz–8Ú¹Ğ¡#3%ÄtLÜÚQİDç ÃË)mo#VoÏ"B˜õİò›`¨º,ñ"$ç‹qÍ}Bî½çg½YVöanv¦F‡Jı­ÕóÖ=s?qpU¯¯ˆ,¢öEá]\ú³ØCo¢L©"SİD„ÌArüM”T¶Âv—1hşDşyL¦àÒQĞA%¢ãÅŸ™ÓJ²w“êï\yRİÚ‡<"MıÔÂœøµ„¿©É÷ÌäŒiMˆîÜ77ãpÄLK]c(ZVçÖİd°™yÓxÒ ôÕñêK0¡›î·5ÑhhÔêƒœ]Ädnìãÿ³jË`T¸£¶o&ä+›
‡ä½9v‘;Èªù^§p  óÇ¢Bı2J œ¹€ÀˆV1¸±Ägû    YZ