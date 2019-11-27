#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1031008222"
MD5="dce73a9ee52df183678bf86c87b93d1a"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21134"
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
	echo Date of packaging: Tue Nov 26 22:00:14 -03 2019
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
‹ ŸÊİ]ì<ÛvÛ8’y¿M©ãtS”/qºífÏ*²ì¨}‘V’“ô$9:”ÉŒ)’C²İÏ¿ÌÙ‡ù€ù„üØV¼€e;éNfv6z°D P(ÔĞuıÑgÿ4àóìéSüŞxö´!'ŸG[Owmm?İÜÚyÔØhln=}D>úŸˆ…f@È#Ëtİë;àîëÿ?ú©ë9¿ÍM×œÑà_"ÿm{Aş›;›[Hã«ü?û§ú>¶]}l²s¥ª}îOU©¹ö‚Ì¶L‹’)µh`:~˜¡G1<n:s[h°®T[^0ºK›ºJZŞÜ K©¾DD»Kõ­ú–Rİ‡»d£¡o<Õ7?Be“ÀöC„S¢ÊÚ®›ßBâMI½/ øû¸yò
¦ç@u2<0˜ä20}ŸdêDÅ1Ü†4ÛUrêì\ı"œTè•ïíûíçg‡F#ylö†Z{¢&¸˜ÑÉaÔ9›ÇÇÆÉ‚æ"x«ÛojÚ~6hzGí×íV6WûtØî†İQûug˜5·`–Ñóæà…¡¢^¥(j4Ï ¬T)PotzÁu‘ï æ€*ö”¼!È­Ö{µ¯×ŠkQÉ»=”œ«TÊÉÇa0¿Ãè
ˆZcUÇMîùÛœŸ|rK”©­¬fq-7¸„p…Vƒ2 ¹h&Ş|î¹;§\4
ª±C¸À<°À¶(S iHçşíPöxı†(•„Wz8÷õ<t}â¹Sà²ŠóÕ {°ª[˜°uN'0Ö@î}¡ö,²<2§ó1Gá gŒ6€v @©LÌè4œè³À‹|òW2¨/†Å¿¶Ÿ‰nÑ…îFS]ûùÆ Dš°˜Ê²Úm(AŸûÀ1gŒOëÒË^€NGShæo¨ 
?l×2j› áÉ¹:„¶¡&´¨µD-§¨œ tš¬Û\í¿t=E«ß’*€ÏÅ$ô,xÈˆÀÙğ¼0ŞteßyATÈ|–¢ÌhøÌ©u²Ï—-ÈpÙÈ,¡²l†µô7Ñ®Ôt¶~äæmˆââzlÑ©9áº ÍLÂ¼S³‰„O-1ÊÚ“Ô¨d›¯ıiå¬=Ï±ÁìPÌÏvÈçô/èê.È~gĞ;nşjÔâäuólø¢Ûï¡-ûM>>ÁURËy¶"{¹2ùe¨‚@Ò%ôÊI½^W÷jZ)‡_%¡"r'„´¸~\1_i¬¥h#\%W©RÉ4!QƒÌL
ÄJÜËæ®°’Š•7ÆÄÎMÛM)Uğ‰“Õahç}ÏáS©d–+¬+t¾O¢NMŒ9‘ç·Ê3˜ÌÏ(H9á†¬TdàäÃr¸(j’`É£¯ŸÕù?DáĞvgd ypH­zx~†üg{{åşosóY!ÿßz¶óìkşÿ%>/¼KôI£9Ÿ´«T6H×‡ÈÇ´ÏĞdãW”ÊĞ#qşÈ‡~Ïæ.¦kÁøJ~k)D¾9:À¿:IÀK¡¿æ³ÿ:@8úŒÜ¿gÿ¿±¹¹]°ÿíÆWûÿÏÜÿW«dø¢3 ã6oÈÚº'Ía3¶_I«{zĞ9<ë·÷Éø:Ÿ%ÁH/"sóšûH¼ˆ…æØ<®¿'cx6]ØIBî¹gÙSö$Ì0>nL‰ã±°/,ïï}3`"«“bIxä×ƒÈUªò8Ã'š&F[Ô±ç6¦…Œ&“×¹yAu¦ÄfÏÈ4ğæà@Ğ5ƒì˜NwÉyúlW×“auÛÓ¿LQAÉêò®æ­öVƒı+G–_ù¦ËxF{n&L`¼Š2µÂ™L"¾Ó¡À™:y«†ıÀ{ÓçuMÉ{ı8±ûê•¿¤ÿç%‡³úÿÆÆÎ×úÿ—”ÿ¯Ú8²‹uvşóööRüß|ö5ş­ÿbıCßÜZUÿ/*úÏ rIÂÄsC¶>„#ƒlÄ·È¿2£.xÚAHQlâ"4û'‹gD'Íf¿õbg[#M×
<ÛúB]©Z4¤“Ğ„%ğá<bydêOâmœi™ÄõH¯E°ŞhbYnñáïm.lÊ‹•æ|lcÁKá	ÒA¯…uçŠRq¼	ÊĞfáh
0jÓJ°ÍXDë.×±<Ì°ŸÂëyaõ‰z6Ü0"?ÔÕ' ˜V0±ü9réå(â #'d¼ìº·Ç‡ÛntEN ‡"?>|$eæDIÉÙÈÈØª7ê<³şñj¨IFÆn}PÈì ‹qê^0Ã&¸¨‡æŒéu( m£†*a,£ãÎóQ¯9|a¨zÄİ±Ç8CU%°ÖÁa†<“VŸLgE”ıöq»9hê¿l÷î©/ñAdé5i¤šqQlÿ\Ú~Ğ’¶ï\ôbwz’,ãê‡XšƒŠ¢ÍÜhi]i¿ÊÕ4† 6sãEË°Òã)ÄW‡sS T†~Hp1¤ämì{â{f†ş	…;€‹.ø–! Ñœ Á„Ùóñ‡:öÄãsWÜhAnï™Úü‹8.ÑØİ‹_üñzÔKø½Š½bŸ0U¼6şW²]	ÓÉšKûuÜÎå¹=9GnÏ/ÀT4Ûz\)Wk¹A*1ˆª.Ÿ”c.rT[5ÕÃæzØ2®_é•*ßñ¦ç	<’qU…ı.­ö§Ê2 á
YœnØ?;="©#â(,öçXËdCÛ¬7´1„5-ÃÕn–Ú¾}«=¹Í¡bb°?wzñ‘éöqçôìõèE÷¤Íƒ›ÂòX Ú!a¼<6o¹s,™ñ¶.ËªöXŸı¦–¬.UÄÒéS½¼Y^èm	6<Úˆõº¤Z@DUô”°n©)OrjË+@Bãéá^PY=
 ¹Z¾x±2ª	OW”çØÔÂ<§ÌÅ)ï¹éÎhvn¿´P!-R)yw¥‚µ2ÑW<à4XNæ?’Ú2iõÎFÃfÿ°=4Lğ€İŞĞP5q‰íc•ti¿È¨H«ß`Ë¨—ÏšDkM_ô^n©$Q¾^¿}Ğym d*‚U¾Ü˜Ü(”qÜ’šH%»“ ©c÷¬ßjJ^äÀŠ!z­¨Øèü$!~³ı„%j¯'t%•½ïO®vxŒ,;Oç¾F.Ş€bÓ^toLÀEÚAà»ä Ğ2Işšl>µ›Ónÿ¤y|«áµlH¸b¯T²ÄÅWÓcÓZ©õ«˜Z`ĞÔ~»ZLWBU’õeì_’Ïì+ /«àrnµz Ğ
6ˆt4*IØe[h“óíR{xˆ#+·$íØÉç/Ñü¼u¼8XÒö2êîR¨•÷3 OE—’ìxô˜£™b)™Z¡PîeÆçö	Ë¥êÇ‰I¾Gt¸ˆÉ‰ÌÍ‹íÑßFøÃ„ÈC"D4•"lÁÌaš[<÷¼p¦Ï-¹@ÈğBƒ=‹„Tâö–Ô&]u98nºè4›§ûıngëQáÎƒŒS8ñ$eÍÍ–˜¾DZxìj’ÀÛ?…œ\ç%7BRúrÑ–ÄVåË#	±»zÙn\©(ªIÏœ\˜3*"î~û yv<„oÔÚÖQ²a·]‹^ñK/IHj70xSã}ïn?z­¹„2áğ×*û¿}ı—_3bâ&Ó¨eC(ûÃÊÀw×·w–ëÿOw_ïÿ?®ÿÎ±ô«™ÎÜüë¿$½ ®Åç%ÿÀzpŸ2ßs™=v(¯ír„xĞ›»Ø¨‹Ç$êÄe%¼®V¯n—8~;´ñÌ9¢I(Õ¸’eò»–tAÏçíß(8¤ßíGØŸÁo0¯%!a°$'óÀL4?Àcç÷3ñÒ£ÈZêI>”Ei%`šÈà­ÉUPz@}¡”m¼G9e” !œ’»çÇ•ä!*ù™ïŸ`8¤®	jÓÜzg]pnâ¶NÉÚàìùà×Á°}bjÄÆê÷¤9öolë%u-/¸…æŸ^¶O÷»ıŸ¡ï¤»ß6ÔÆÎÎ<ö»g=CõhxÕ·î!…”RQŒğs¡úYúÓ-¦´Î›Fƒ^ÃE@ğ2fOŠùX•[ÅÒ¦ü%²Zpªæş!×=˜“,%%we%UYıäÊˆ¼ãÍWßˆfğrÔ7ÃscuÁRóòQ•ëIEØ’X$2ä	¬|d‹ªqºxèG`iÆc¤I­v`í$¶Unƒ¤Ô¢)İ¢$ñ>E<½¶’ûÍãzd,Mjm-î>pj©Ñê®u¡û‚»š3=†Öj`“Éâu“ö$há·åÔ™ÇâÆıîĞóØÃ~G/'j»ş£îP¨‹nQeˆËb•ÊšvåEÂÉë¸ Æ[@-g4\ûèú“O„Îš]ç@-ü^W”¬^PEûBRËÂâàD’á*ÆmãØv©íâEæÜœIJô¦ño´õÂS®¸m&=©É=¸ëÛÈ(ÈÄ„+,†ç~h±`ğô½™Ù±%š°Ép-$ÎqãjJBŸJT‰:•´XW«›–
Ö›c¡×<~Ü…ˆø¢%>6,znLJ‚‰"/6€VÌŒFh•è3Ö’(¯íâßİÚa¿¹ÜÈAåÖ€_|^9É_"úÜ1İ”DòÎ€DJ<úğ‚xÀ‹HÀ@Y–¶Z“Y JÏéRâwY
KçÒ–dë¯®â>?y[%ÆH§Q“Ÿ ŠıLÈJ9äÑHÜ4dÖr$÷à(“L:-u(kŸˆ±(ï;Ñp'_‚$çä2šJaòêB¢(ÏÀL°5ÒV_òÁéòÀ)ãHÊ…dÀ„QŒÇ×øÌ]$f à{ü˜Ñ+.F©v#ğ4ïÍ¤?b‘ØU…Ğ´ğ&^Dò—Éã1àcX™YWD%³{éÒ é8i¦'F=×¹¯okˆ!Ñ¾j¡+&¹#Ì¥>Q‰ò²ˆğ¦ó·8dÌ=Ò’Kû73ˆ£Xmg?f0<ş¹Ù?àKÏÛÂ'…”•T¤SÅ8sŞLš¦ÔöËzS;/ëŒ×²¢—)*Ãê½<*†ôœ—Ã×1£Ç¶	ûÌ8a#’dõxwßK(Ø§<~l=û§ÚMUbÎ›'ïn÷ìï¾[r§Ÿ4H½d0ûİ­œ`ñFI	w³ŸDë/+î öËZ—âÜ×Èô]…·#¦coÖRÈÀxkCÎÜ>ºTµ„(wğ¦ÄALÊM(M9õP\òv™.¤ye­üôDí¸SoeªŠr-æA»ÅÒmÚO.½à‚ùæ„ÆÌ}Õí ngpq=–@ •İ³.ÄŒIÿi¾ÜÙ[÷¢¼Cs‹ãìï¤]›Q+4ˆ‰O‡ÙŠ¥ŞcLûóÏSÏa·{<È –š8àé¾tF*=ğNù2HMjÌCá#$ÁÈN#‡(V“Ñà¬×ëö‡Æª¤
IrİÔĞ%îÖã×:t`Fø
U8HS¦ba>÷î5¨•¿Xk˜šŞU8í;¿nŠß®!|„Š½uïĞ/Ñ™)Ù%eêõÖ]­[Yßõ
æìîŞÏ‹Ô‡Ç;âß³œœ¿WÍS ÅâŞºüå[ğÙ<7€ì˜dËÂİäœºÁ¬›C¿“wmÅ’Ë¡D7}ßIß{H³Àê„Èà
r½Gø7ÂÀÉA–rNƒïñıc²Ø±°åK9X¥R<·çT÷E}€•Ö]<ZÌ›óÛe¡çó;sàoöE3iãË#ïÄŞE=5çÔÈD¢¦®Ş»Qm_ÑIîè¬Pìİ44xn×šØQi|cRãùäª,Ëá5\Æ¶“Ô™`ÈÊÃÁD°zİ†.Æ³¨ b#/À„®|ÜsÛ5cj‚…‰¦kŸÍLn1Z )3;RpfÛ[††syÄáğhïğ¬¼¶gÀÅ=á÷qM‘ÿê¤å˜ŒÙ}âäd…ô*Ô¯4q‡p?ÅÆzïA‡5ñOÊûl+‚¬ 6ç[ZŠH¨Ti#–7.ò=Ï¢0©c^‹UÑkğ53Dmy¯'Ö:(!`í	îìå™ôvË>ì4¯ww_kGûmí–² í«ò÷nŞeòûïAˆ)oxi:5êÀ4şøZwk5|Ë¨Õö=|MÚHlâßV³ÕaktÒ>=u†í“dÃ_jS¸Ï=‡”|wEÊÆA·_ÚÓ`ÌáJ<Úo†İ?O-  ŞÄ6Eõ> Óô½¨sêøõ™ëÍ)¿[jZ ×:»f!küA›E¶EÑzÆğZ¬)E Ïµ6ñõópîÔÑÑ¤´eæ$|v*\ÄP¿š;å‰âİŸ~™X~$ä(Ò¡1›³Ñá“Ù!z0mxı¶¢â, Óß(e§ñ„ß7•`”…eM¢Oğ@‰’mÏc¡8±—²tÏ±Fùpk¨÷‡du)beÏò§E0¹¶¨–É‘£Ì¢ ,!*jy˜eÓ V‚,aØ{sa&™+3g×bß/æ:vjµ›n¯}úd¿qñüVá¾·.4snANJ>n½õÃº›Ÿ(UMÚBsnÀF1GÚ›ÿ‚=`zÀ'tL‰‡`¦{Îş
$ãM7(ùæ ­ŠT²ö›äç·:üz˜“m*±±ˆµ_?áÀRØŸ’õuR%Çæ‡x¢Ä’ÿ?•€dsç6°µ›<õ…l¶ê@ƒ•\ìÉW¼%Èß ¡srÏñ‡(“^pùã)š”œÒËVÂ™c™tè½J-fåO şãÿ¿pÀ™qo%)ùâG©IhÅ1‡kK÷/¸ïK9$uÆ¹ñ)öçRãe˜A†`Âç‹j‰H]"Å6–ö¥=q~`u¿ùA¤ÚšàŞvxi‰ØF³™§péŞ-p@Cc3ŞH‡ñ!„ÈRGÊ›ì^|€b4’üÊÎ	Ä~ˆ©ãh–ìW§ÒjÈê$¼ÿNIñPXtÅÕimí£«ÉPu©Œ)ş=P<C!ıL•wMº7€Ç#êŠ+ÇµBgJ-\<üÎÔ™¼Åw•WîºĞ:6ÖÁÁ[æLR-Ï~VæáD-a*År7‚Ü%á\â´jDâÕxàQ“ëäË„IîM¼rÿRV"ËîÈ*•åM)fÜÜ(Ø×ÕµøQ˜SÃüléŸj¡~nÔ0áÖßô:‹ş·½oënãHÒœWÖ¯H0&© ¤.M
ê¡DJf›·Cvw›>8E H• 0(€­Öş—}š³ûÒ}öaö±ıÇ6.™Y™UY HÓ²w8G"P•×ÈÈÌÈÈˆ/.Ô%ŞCÃWs'E†m–WÆAÔ•º;ıªàOI¥êÇ¨ÙççÿÓ?¡_ÍûÀ¼¶Ö7fÄ”Z¿¢oî`»’	G ïğ²%ıü?ÅuğSĞ=JJµ\Î—zT
ºQb¢	b¿úF«ô%šò`Mé‰,n¢ñ{TöS£n”Š+ô¶òz“îäèÏ¨:ù–¤^¹ã, g1ptr:Wş«h¬„ÆJåª_Àš3UxÁí•9;Ù%ªÄ÷ò×G­ÓMª…/¸]Å`Ú»ÃW8¬<ÂÁ€±ğk9â`¦Z×/ì“+gJ•íiY]İ¨T&t¾±¨2#­Õu{–ÀS™˜TÎº[šï¼%İåÚù÷Xõùµîr.Ñ¬œØgNm9ÿo7¤Ñê6ƒ€Me3ªjS¡Q::&,	åŒªÉ‚zÔ§¢ĞVô?àAìŒ«™…NF*ãzu½Z—ûlàÆ=ˆÑšôdK¤b$Ë‘f2CŠT^•Ñe>‘%7¦…ÍÃE-Fr÷gÃN{Ü*"ù®_ük5ì~—¿ôüÛë±ğ0Kâïë¤WÇİKşŞ./Ó_“¡üÇËF4èàWX¹ñV¿Û`½İğÓÕ`ğ}?ÿÿã(”¿Q‹Óè8ó³:J~äGh/¿¡K›ñ5M£‹ƒ©•Œ¯:I7æª‡¸„QG¶Œ\{0a®ªÃ1ÿ@Sùc\´¯;I@ßCÕí÷ØGõwˆeÑ±0æ>ş˜Ä™‚pX>„=ã«¬´ÿ!x¶eà+ê×ø+üº]ú
*?…²À³òÛ$„Ğ7õr2Ö_dñÃ^ˆôV®›õ~vÃ!ıt'}ù¸„¿"~BÀa»?ÇCùG{t°‹£>1rÊ(ÁÙ}~“IÇCƒb@RÜÚ‰µ¼ÈOÆW™%%üMxu{DDrc´&Åã¹©—Š¸M?3aØ$&ÍI£}èRùŠœféÁ– =•&#+‰A|Yò¼Ô>ƒµü»¬%ãê_lCÍkšHPÖY9—k3#ÎÕÙàÜ6GÀ%º¨tQ:¯ˆ¨‚İ©İ«¾+:’U6ªõs¨ñwG^Äÿj­—å/İ¥‚¹Gaz¡¦åÈ´B>gMz%úTÜë*i/uÒc†HwèTGW°/÷™6€pvÍíY¤’Ã¶Oª›çHÙëÚ)a·äñİ|F€ã¹%˜i³Ïİ6ˆÙÚTÉ/’6Š«Ì‘F§Ê6Æu×“3P)6É·¸õ÷ôBr«5+y5|-mJU*¢rçQçÔçîü1Ñ¾É~äöZÖIS·gHŠf
Šå%¾<ŸÀøåOÔ¸áX 'ïŠyÓË	7ê·ãá8iú =úé©v¬i•e6Sº”¹³‰È)¯•áà/-€Š„õßúªÂ0‘$l¾š@wÄÀ@hhBÄH<~/Zòù>>6îà}¯ÍËDsÚ±BÂ<Ï§.Kí¹óÅg|ğJ–,ı>îh
…öÑíx]É“¥¥İäb2è²µ–è†‘YLÁãéKÏÜéå‚ô»+¿ˆHsÙœ?XÆà»À:ãì¤M¼›o¥//²0ú2¿qÍ‘²÷÷«97Ò{`?&Ï6Â]ÌİFË(,a¦È`eÆ\27İ{†Ü4\`o)<AqbZáÉá‚4¹—¹ÄÔ*vZ1K¼I4:šâu¦V¾ÖîééŞá»VqJÏË¹XßÇ/h/Œ?ñ—ÇjœwæñL+R‚ÊiCá`ìÊî-åS­Ğ>[Î¾(İûIí¼VÎCÅÔjWxş-õ’|Ö-w‰ä¸¿í½“Û‘ÛëÈát”÷9²],#åp4İßèaÜ²ŞFğ{"Ïûu>×üåY¾A÷ËÉ>B÷Ì+}…¼_É?J»eĞ°I5GÊuû…#m™>VÓ:ílÏìNÿ¿Ç å!–~]5MRîì*v?O1‡‹Øƒ{ˆÍï FsÃ 3S½)ÍË›vÉÕ,Û«İO™hg„G'g‘âv¾(¥Ü«^wŞ:H^º?¦+V~if”n·ıS~§üljl„Csßì˜øDáÂŸşÜ¯îl1“5hŸ·£>jòÂHàgÈh@^#îe%’‹˜®­‡Ò«ì€—“°¡iNíÅUl¡QÂj¬•1 ßlUÁÕ†YÀ}^»æÆëÇä%ßˆ¶{øms

ŞRÉöÙSy6I%j•¸ĞúÜ:!]äş>?Ù>ùKZ°Úº6Ëé[¬¦DQ­z]}¹¹lÔK ø+åÇ«Ë™ÅÈ— PTÌ²µ¶(€å$»QódC‚™Åv<ÌçKé·|¡ëÒ2ÿ°t`ªoé)†ucÎ±¤àq?é„tÌˆdp‡DYĞ_U¿—\´Á:ÙÒ©_[[ª"*‰×Y¥IJ»K£oˆ*;2éKY!Œ¾üÛŸ—6C³PncÖ,3M‹3âb6FÀ„7¬ËÙÊ*kıppm‰íË/ÿˆÇÊGÍ¯W×|8tâ.,2Mÿìômå…ÿÇWÔË—<ùÇÒËİÁu4Šh‚Dà'	½ı÷å>×–âÕ±Åø¹_{÷ÃÁÜÔ¤qšRÿš_!á+_–%UˆD¾AĞuYEkVšùeÍÑFzõ²&ûbZºei$—F§‰W˜sÁ¬zÃ¸x>Ûb›i`ğ]­#KùÜÀúYU`›dØƒâºì¡Z^Q…-¼®K`Ÿ0ög\ö	Jw• aÑY›É‚</¯À¸|Vı¥UAå,•êÓ°Ì|U3äkæ+À¸¤Ùá]Àzq›5!-`ã®-pàÇúXXé)û£pŠ1ÎñTa#—™şÛI·‹çÌëËgSİ'µâ9ôÉ`çaòÌ™xƒ£‘„›5í QZäş’_ìbëTìÜÉŸÎn#ˆşb’“şZ”oü(¿ş«PEÙª3äì—ŒÿW_olÔsñ¿ê‹øü·Yøo×)şÛZµnã¿9Ğß¬0_†Ñg±İ‰=6áGœ£ f…º‚3_/ä^:¼OÔËÒ’Õ|Œ7¯ônÿèõö¾øvûdÚ[\í›¸ĞåSE©şv÷dg·Y^>¿¯o­7úË:døÁöÉîş¿Zƒwëé»ÖÙkØˆ¿ŞŞÁ×úñáî»“½S™¥&W@²ºÇ»¶U&%Û°nÿõl_°‘>g¤YÙLx¼}|ÚŞ?zóME'¿v°åFwøá
·¼^KŸCÔ/&ãÄ~Õ	:ïCz‰G`Í$ŸUX¹¡ãÏ ë{«^ò¤Kö­Ûzœ™ş
Jİ\î†È`¢'§R§K|ˆ9sªh™Od€mr`ìàõ=¹İQXá°ó¯»¢@„Ñ€!Ş ğ2ÈÓ©8E5±MÙ-›xkáxtÇÌÖ‘X»ÛJıÜİ8LğG¾øêe#.ÁíPië)WHsğørøD U¨xŒ¸ƒæu¹İ&U&ºÉÀƒÓİYi6QY"oô4Œ°¯KGõËx2èŠx$êÑO/×$EîFØ(xÜ\><:Ü]vĞÌ&™_näßĞõ`„ãÁÑn0;…D‘ YiNÈX|;† ®²F¬¶çPô’ì+ék)8ı¼Æ}	^
FW‰`R]Õo¢$E"9@õ4c(oÙ´„%VÓæJy¥…ÒÊÏe ²c¸
¼._±…$º·P¡ô ìÑ\Yu1àW_eˆh SQYÌ{ºµ±]GROU˜˜—Lh]iù|­ÕÎk5ñyÕ„º—)ğ´O‚°YâÈ5K%–å…öXJ›ß•Ÿ¶+]«üaë‡UIè¹0-ŒÃUøQ½!ÌÁIñx4³­J; ZWÜ>BTí¤H'¬mÌph¤w&Yl‘•Mëxïôtw§½}r²ı,Ue£J'»8˜·İP²ºØ–ìL•´NÓ:šåÜ#Æ¡O…ÍasxÖ›ÎL&mš¤+ô!‚[dRÅ‰Üä…U
@´Ğ)¹ó3:eĞ¦œ~çn¤%™R#g¤N¯2J™‰E-EfÁµÃ]ø'¨T¯„Ié«èƒŠ¡I‡A‚‹şÅ-zº‡9J¥I)0Ğ–‡®M)æÖz:zÒí	ëj–ë[ú·Á0£Ò§¼1á¼o–×õSÙ3 ©œ4a-.•Ôq°ú¥¬”XÖˆx
lY)c^y˜)d6!3‰ZëõCØh×Gü‘IW÷8DvG¿©ÄÄQ"&ı$bÜ{.åIö¨7ú°BÂv‚n^ò7àã3†“€ó•T/U°ğ86fJV£–9I~®€—:[3ËoLëÉ¯\~$2ş)PÎ¿^ørYÁH_û
U“²vì¦i™r¹lËy ­©û½tş|p¯î»²Í&@‰/=‘-ÈãRJG…¬•NêRUo…Á?$©l¦ „YWïÆ–éuì/mÏ$4-,ÒÏ9%İ×ÔR›EU"—Djİ*›×ÑE£÷£ÁùíÁ	Sz§‚)¦e¼oéıïÊÛ–Zt7çZƒVÉë$ÇŠ@8ì>b‹ƒ~´JÒ›ãØ³‰DÔ†°£ °f¬”
„¼‰§³É8€ú†a/f´NËLFV‘'«Äød¿ş.…VMäà‹‘Íès]Ã_…Éù`[0¿«Õ*²Ğ«¯@.üŸÎL´
u¥¾#¦`&´s'ãnˆuÚÑYp¿
ÇÆì¨çáËa*ØÏÃnB¢Ç.Ï†zá«ŒHªÌÙ;¢Rq__C¬|+Ê:Tè…ªr%-Œ`#Û9ÄH;h7ÇPCvğO·ÄéèV JÆè‘ï8·Òrş­Áw“¾ Hó‘	ÊšŒÑ &Av8ˆØ::Gq'L’8y"héE·$¸
ûÄÀY?ÿœ£ZÑ`tÈ!‚ÀÂ0ãá*õz’ÜfÖ©µÜ@¤I§Ç–er'Aººö–Ø­|¿öƒzßOè(|óYç‘@0§4°€™’Ÿh¼üª.Jáàß'¨¤‹m² :±P:“!Q¥Š=Ó±Ø#¨H¸‡í» Sü„r=––°Uõ-*Qt“@…©5Çgt`g©{÷E “Vÿ±	ª‰1”Ì¹R¹æ„×ñMe2&Ø¢1º"„İÕlâ6LÈP¹Œ>VúÆrºÒ6\ã”V;>i&z ’ìÄ1Û^ş¤5Z8Ş<¬àd`‹ô·rò(?Æ“å,ryı#/®kæŒ™Ûø‰=ç—œâşÃL<İ$r IÂ¨Äüèó"xĞ‰ÿ#yâác¿ÏÿçéóF6şÏúÓÆ³ÅıÏ"şû½ã¿?uÅÿñM.Ÿ3ĞÏëİ
å.ÒºF°ÃüäEv/G!(Ã>nÎ!óI$+Ù‘;Ç­l‘Aó‹ºaÍ„šnLãÔo5ÍG÷Ò£#[¥øg<ruÙw?GqÔë
iÖ$”A5®²*£K“9½)hhô!exh‡Â$ß¬=r+r'Aå²MË±¯	Œ>˜I¸¦Jb)OBIvíd\G¶+°È‡ˆ&vYšniU9[³>j¿Ã#7WJ$,WˆELåÑ,¡é_Ç#~i˜ğ³ ™­k°`,æÈ¡ŒR¨ÒåT7•—ŒºbâÚWBšâás­Pèš}M5¤4{véÏÈÆH–Å±Il2‰l~sW½}x:³^L3½R™"¯sQDÃÖ8O–°É{8]Øî:Ş¦©²Bê‡ÿOÏZt3§õÉ¤„i†,4~=}uxÔ~w¶Ç3^¾Qêë-uÒ´‚aV øªyJŒd‰‡Ç`Ô~
xô!5ßÏÿñóÿ†YšÄ#T ±—ºÕñaÈ¥áIU<I«¹"Ê+x«-*p¨¯ŠUsµ——)sëßÔ Y8Í1ÒeNèˆVAĞª)U™ìË@Ÿ‚‘>uµŒä«P`¤6kÚŠ*b&`J"dÄÚ7õ[iã–¬hª0V,E\Ë¼â	¨oj3@2êŠ–ã¿yv>ì’Zêƒ­‰Æ™.îæ¹šé’6ÿŞŞ?İ=9Ü>İûvWÇEÓ«3ş¦"ó²ÈÁë9Œİ#êlÀµfa•ïİ[C´/ìš¡M†X²)U8ê€Öw,m%—/£˜äh„ãä}|CŒ¥¨¡¿õêZuÍ&†˜AÃİİöÙ1®n»¸35ëiğè£Ø	/¢ ú¾V;†ƒ?í|#dg÷^>}a’`J«…‚Û}QÿÓá¤ıv3}»ìÏ¬ºKé¿F°_m¡›Us_(ë¦„[vŸˆIB›=§¨×é¨Í@¯l6Tp³¬ìŸ¶ØõŒMvNrWCCÆROªhm“Ş&~by½·}Ø~€`z-4)õ3kgÕ.Ê‘•XO±üĞ¾«6uYÛG'ÔN55&÷ïÓ‡iR7¼¨v‰×¼Í_Û]|‡W£PÃû´¬öc z2ˆxñE´^{ì=õ}Ïú9ûkc\'|ù
Øft!’ ]ŠXõó±›kàÌ6˜ÃäP¹Z˜Üìkˆ×»£o÷ÆIVî"Î¨RNFW¡¨<†MEÌNX¯?¦İGNè$ÿéd÷… =ûe0é=|¤x$;üäQBªÆïÛ8JxíÍËÿ¾¹DŒÂU­…$3¦“›+)*6ì•º4BåVÙ@í&‚.MQf©JšÕÜDhOCæ0>TêK£-­İD¤ ~²ÄÔ’Z¨u°5Ë&?´ÆñpˆËŒ4Úâ{
iï”vÒJ+^tş´ıí6ûtùå4™®] Af(€ÛÎ%0ö¨Ô¦&–u)†MÕ–!5&5Z§¬$–n8L<ùc'Ä»CT3$™˜SËjÜ6—kğ?Nk<—ÑfÖJñ—é\½¿ıİÁ†”)³‡êœl0EÅšav¨ò±Ğ,ÏB–©2ÍÌ	N ‡ÔêDöœI¸•"…#’¾0v~ÿeÙº’dÎ	È³ıWô¨1…¼-yIJ·M¼S¤©ÔùCu3Jó
gÉ(Î-ó<…º [¶*pŠğáƒ|ÿx"F™dµr´eÔìì±övR3Ø~ÍZz%Í
/™e4»;{èœ­/$Ò,·‹ $›İå’å’w<u”÷÷^·ÔùˆP{ß±ÿq*	9bàÂ[XNÕ¨;a7FÔÿ~8Å	yÕóO3hëÖõµeöVÁàm‚Öµïòå‚tÖÚmØ0h*oKR™ô›+ª²YÎNö›°¸±Yæ¾jÍ{>°KãTİ–¨êfFö÷Şì¶v[@½“íƒ]¼ñV©ô¢N8HhÕÄmŠ£B(ë@…&şR?Úyiı*‡M‡9¬õ`ûpûİîIûÍÁQñ÷0ãÚ„Óô‡¦_Ğÿ[Ô—‡*Ù“íM-º!yj…#ë~/³Mke
~·•ÀQqiÙ¤İrêË&ùŸ2¿7SmûuâxÏ¢å»pl*Q£İxÒåÖÄLPÒL”¼¸ WBD—ïàúƒehf›V«‚óC‰°_qY9ÙİßİníÖªOÆB­ÄÆk´5uWPl~PPÎ™%XÔNq–RŠ:-Hgw7MDP@U­¨Ì:SúYúùv‰ş4:N-õAîšm()Š?J¨¨7¾²¹\ á¿ã×n¿# „2sàÓz?î"¸”áõH–*Ìà6;ÀSÓóƒ®M¡­WjŠbãÕõ‡1Må£™SÕ˜g’!(°°&³uÙá7z	Á‚/ƒ¨‡Q“±òkOÄª‘LA<‘2P¦Å<S*ŸÉ=ù"Ê<èİî)ßô½ECô‰áÉ[Ë8/\EĞ^4WüN¤G_á}A†i²dé„EyªdÕ›A/ÑŒ¬ÃaZxÆÍÂ¬`2ÛoÉ9ógõs4¾‰9£5ÏšÚgÆQí+ˆƒé-v–ó5Ğ¢á¤×ÃaË/Òï³š,çÍÏö¼ÏÅÓÏ%†œxşü¹¨œ\ĞÈ¼ ›Eç4š•Iyn;IU<Kï×¨»´JXb»€i¿=Ÿ¢+ûú<sı“=ŞßUIdLG£TÂMC,¶q7¸]œĞõ¢°} FİdM­´:w­ÕÂj­Zõ2šñâ#µÅ`L›-z*ÍÍ&	ûB^z¡‘0”0b4¼L&(Ğ2(™y©0e…ğ…‰
âë@uæåìÁö»=”I¶Û{‡;»n®‰’@“‹p„GRãİ¯#ãÆØÿüQ£Õ>¤›‰¨iìÑ¶d÷ŞçIV~`N·O¤ˆ«ºNÎN û}¼¾”ÍÅÔèbégÖOa½µ8ë•!lrØ5·¬`,C&ÅÌmÓˆÖ¥Ù ²)ø\T!4¼1İ‚v£Şû€ƒşÁ°GWƒ ×+ğÎÑáh4W5e“şºw,å†\cğ˜>ü­Äš&3ï3ttåfRî|3Gg4Ånµã®ÛÆæ¹ì
dc^Ûj®gİ¾›*TWª…Ú\RœŞÜO”¾7ïqsöÌÉ!¡Ç[sfÉ•ùy:Ú˜Ë•
¯Ş)(¦ÙÙƒ)x)…Õ½ƒÉr²İ7ÊWûµº"Z{ïöOaõb%-®Àw Æ»š"Ş<!É}ÙæWW¹`ªøŠôŒYmY:eÏ³™•è´)¨æ•Feƒcá‚+¯‘Hÿ£€ ç¤èÓ×ëş¨ñ´Ú¨>õ]‰´ZÃùv{Õ«8¾ê…U i81NHï–w•¶,Ñ	«0Î’üM¿8ñ_4Lî¤b¤ÓGñÊ¿Í–V‡]IŸ¦¼iuA®/Ùg©Hb,5H²ƒ{åÎïÏJ¯”.ï-İÂÑ÷o¢Š Û}¶ñnŠB¬øúî%©D˜³ı¦( ³˜Ş\ùq/DIÿ&ˆÆOôi¯ºÎ}Ù­‚â"â‘6uEŒ…¤*.“Ñ¥3d(Ñ>Fï'X–0­Órâø}jNo	#u¯±2F+5q†ïÛİÚ7½Ç¿Ç¾f\]`>õºéòn¨ ímÙø6~§İ2®€9Ç`ÎÆk”ûŞíú…Ù(v@’OwùeM¿x}¶·/f?ÂÂ™Ôx‰—ÚPÛmãÔäœø‡ïÌ¥vƒ~#İfUa¥³£á¸Í$0©çÍ?´	ù-‘fPKŠ‰{‡&Á²Ğ®s«-Inæò®ÛQ8Ö‹ğ2&Óqº`—š—¦µ…“"7šGÊy—Ø†Ó=–ÛòtÑ=òÓ´hYÕ¶ÊK%ÆÊÇoK½$s -rN² dt^=Íå‰fJ†TĞm¾EÄ«¨¢OJö3£·Ê$èG†öbfç¦§à›$uÑ=m‰úİ4qZï·ZK©ZLõßËhI]ÜK‘{ƒhlFfÊ/°¤ÖãÅU¯§¾ùËX&¹î3n1®Œ_ªìIµ^jº'mğÄvÏ¸8Ş[n Ğ½_Yo…]ì8—u4èİ’ÇŠ4iÂ<	g£Py¹P–ŒF®‡9‰G†hŒğ^³z`ÌªÏ™iÅEÉ%z=Ë’1ë§³b6Ô*»ş~»s30®>7Ó¯¢rRØÍ™ù
B¥©˜²<³İívi2c¡b>â‰QLD¼ºÌ²s«'¬#†y•²Ò—sÌ4Ÿbó¿°ÛÑ+R UùuŒĞÇeİ¯myVúöaU$?ÿC9ß‹½…QÏŠ0&xvAÊJn6˜ƒš'ı\ÈÒÎ°ú‚›ˆuŞãïUQ2
yË—_‡=¥¢‚ÄVA1LÄÀØtx––)²*_äPÆ²¤£/o¬¦‚6p”lV óK.!£fìfM–æ35r4¢¸Áf¸ U¯Ñu„	Ÿ£ë"MaÇ¿!š#IQÌ½"sA/ú),¦ê-åiø3cÒ X;?èRÆî^.¼f±?6X‡C ƒB_o!¡Œ£„Á€}™Pº‚$È˜}BÊ@ó·‚j•ºÏ°]˜Ê13Ê4"ÒÛoÌ_©P¥ø¦6¬Vğ™AÊ"}¤óó?ò½…?FdCâö~0†9…0{şÄ¢â D†&Åeğ,x†'c7P^“Ó=¶$†ö($]@{½½Ö^Ë¸p¥]3·(AsÒÆ°$¬ŠîÖ–L[îØ˜u>ÕµÕOÅóÎsFµÓ²‰môG…û°g•ßÙÚ…åB§_§X‹ù‰ö¯œ‰‡ËÏN/ãh¸Ñ¡Xœì©%‰}?+û³³:_|fX9#IQnIÎôzÊøöÎ„¦m”&İéLl¡qâo	5§3(Ôe
Ú¡†Œ4Ùÿ‡&]Zzâ5½ØV] §È»U@Ú»ìíİGQ@e#»½ózŸuÃk.‡8Šûñ•4dM­}náDteå[šGf³Œj˜Ú®(Ú˜%HÚ±ì–ì`J,uÕï,viåB¨Ü	'5³†:qÏ`ôùù½ÿò’ J–,ølcué÷ f„2lgÚŠéÍàÜ_B”Ì
[»7(/‰=¬te™S©Yâ;/EÍMÉİ³‚‰­’î²¶nm±XlÎÓÖïÒÌ\Jéà-%õ¦Š@N|…5#Àª7Õ©¾0»'EÛz25-rl5S£“=Àókìv>Ùãà~G3×’Ü}àkú$½Ä—›&«ˆ£uRÇq¼ùØ£g‘…àu/çşyÍ¤wjÖ§ÍŸmò`xzä²›Šñ)°iø“ù›ªÀ mà}2u=£3Âl*—qp¼¿÷fï´½ıæÊhíìÂ¼À$¶g>\Ë-5Vù8Yá2¢Wâ¦’qxS7µ3j\›FBQŠ/BX‰‰/èp}…ÔaFV2ÃR%G‰ìÈık-¬”§[?ˆ‡Ûv®İlêÑGƒ%#/»æv:6ª£¿lD"Yf#ôìuw¥?aÏ%,”2A—vQ”€DPF0Š4v§`hôòanNî-Ë±gÍ®¡¨¢•wÆÂ¼İÅvbèdKUé”,³y»–sƒÌmÓÌëÒIr'ã72,anqí!Ÿï‰ÿV%˜$Ô§õÂ_%şÏó§OğßğûF>şÏÚÿmÿvWü·¢x?'Š³ûX£¸É] Åë¬z Ø\n*3µ›››êutÄlOÙ«£ZÎµ†ı©pm‚¯”eÇƒ
´7®è¨AÁè¡Â1ò™ºÒJÛ³²*´Š 3AÛğZ æ'¬}GÇ'»Çû¡HğUTø°ıİÑÉNë{úú¿“¤Œ9STÚCW€>Cô]7ìo*p(Eó^ù·Ãı@¥)‰†³.ùû®)#m¯*¢#È2Ÿ ­ŸE³)*Å†©Ñ!ŒÓ4¸Y§ò^ÈbËà¸P©ÈìM¤ÁnT\I¸PTŞŠ"’
óùü9*wÊQ­İ½Î£ê™²şSïC˜“£äã6êÏ7åğ?a»X¬ÿ‹õÿ¾øŸë.üÏÓ÷!eM9}NPçNbí×(å‚t–|™o©.ˆ Hh«('Ié!U!(ot=•Pô·êœ†Øóæ:".£Q2~$l¬(iu‹ãáÑéŞ[ôR?ÜÁ ¿Z£9ˆÇÑåm‘ÒW=­~hr˜¬¢ö)é ÉÃkÔ'ÓYò¿§jÕÓ’²TGöìÒS:ÙŞû«Ø9Û¯÷vOwy°<uŠã
Y=óœgú’YÜ¯4²*ºİŸwŞµw¶O·Ñ÷ Õ4Â÷nxùAÎ,Äxé{NÅ€OS$óò»İı7HŸÃÌ1ı>ÛœíÔ(Ø<QòÏÇçããø&‘‡êN0ˆÂ8êÁLF:%ÿPJoÕã°ª£u|LuŸKØµ?P2|pFPQ¢ş¬º¶!öO[¹/²/øNø Ø^:ŸRéĞEr	ööä˜äp§é_aU½–îÿx` éiŠZOåeñÔzÕ\3³è`öó”ğªîpÙÏs¸~Ë—ÃÎ²™Â…¾G©@ÂúiYÓ"\­Aîb1ÈÙúæôèæåÇî
e£
bÈÇ«‹ñèøÔhmâ“yú W;“ :¹ìAtN“ 'ëõÆÏb·i`x9àMf\J'»¯
¬lâÇî$•õõõçxÆn%Jã“úL¡ûËÚ…~“ñ¨jê/.Ì\wk‹²ëœQîgÙ¸/µŸmäÚF¾1÷Í¬}¢¦B¹ÓèYµ^­û^ÆMg*M[&1/|Íªycö&ğLæeŞ0©®á"(“º­²›Ëç˜l™{2ÎeÕ+Dİ1@wV§•EK ¶1İšf³/<‡ı©i~º5Í0ss&ü–:¶ÑO¶YUµoeÌíí:ŠÌÙ§v³Aıœî‘0½s•Y£>TxêTœ~:‘jG¶ŸVÓ_fı
dıìM!¥‰®WÑøıä‚†ûC=LEV e¢Üoq%Ä+ ¼àT5áÛ3—MQÁN×ŞÛÙU©¦@Â£Ç4^R‚Œ>T©ŠÅšËÂí¦û“U¢ÑÊğšä´ãQücØ£ÛHI‹¢+*„“aĞ	Í>À¦© ­çûr°{xÖŞ;İ=°Ò»å¬Z0Ä»*2NHŒ¢ª Ò~Ç°~É¡ÕKØFµN«ı\^>6—ùõ²g8T[”¿"->,·Îü°ğ¢O·®¬¥=·êšøİ²gøš§ü%Ã Wƒ!FFFÒâ¢K?á &5~	“h\ACêlŸ+²
çêêÇŸ|Ïô5‡­ã®Ys„˜U‚¦0JLnFª21}ïdw{ŸJ•k¿YOu=]˜ô&O	¥ÖY–¦Ô(º˜0SÌ1ê)ít/rCçÍ‰V™ØÎI7OØÏe_7}VÀOoÃíœµÚyµÖş,J¼~á=¢’KœÉqŒá–«ËtÖ~"âøy¿/0²©ˆpÄcÔ«ƒ¥˜ÔscûT½T/Ga8 Oˆ
j²©µqp•Ô²Í…ÏFp9H¼ÕÎå•%=ß!y&´iJ£äí	h¿S4nH#KëAÃ|Po¿À«’ôHb‰8˜T~¡êÕUÊ¹äy¶mHÂÔÊ“£V«½}r ¦ô±L¡–Ø¢/âé‹º•oÏ”ü„ÖGZšRÎD$õWºtÔ89øú­1ãÑJ æú¨ı<ğ…:=Ÿì¾İûsÏ³Ë«^Éh¦w6nî¶1€Ö\í+hĞ·àŒhV©ğûTı¥ºİÊ¯gcÒ(I½}1ŠºW°r/‡ò?icQÕŞğ F 3ÜVøf·Âp¹®ıé’màÖ´·5ÿ¡š,¦©øÁ½ük¶ƒ»HEê…~ı®ÚxÙéi0¾·˜ 8–NvßíşY|»}²‡«GËó¾;i[b…O,u<*ŠÉ±ÌiMT!ÖóÑÀqï1p_ak‰.>Öë•nxòŞÅÕø,Vú<†ÑÇ‹É¥ñ°D£¸¡~Á¹ŠëéÛãd¬¾ãÆ›«÷Šª	÷«Şd¼~£ç¾—ÂĞ6ı~8˜ B›H&×¬@ıàC(xxA¢Æ€€AO (C3L£`$Ô‘%÷ {!®àE«„8ØÅªç§e¤$Î]hè]òzöá©Jş½&Óç {1ôá€4Ñ kˆA<¨`}YX=;¨@X¤¿ÿşÏ+´ar[ºhı‹+¸Jæ¥ÛèçtXì»í=8Ù{.x”¢Xk©’ v;ÕÖ¼l—t?Ğ4äáÜyz}ûR!Ç;.¢ÊFõµá(DA¬şTK‚2qjX([¹ÖÙ1²øzšyÒzm±,û~]ä½Òîæ¬.šRÓŒ={ùnÚJ:C‘¬Œÿo–¤Ñí/4iL¹95JÏku-DÓ™b+"n_Œ‚œW`İ>ÂŠ¿R_®0·Ò—ßè‰ù%nß¿5Œí›ÎÈRò,«¬øóU~ÓÏ·=,dùÅröÕ>¬|õºµzğ.Ä¹£íFuu„«örsšMmœÿè$û”6=S±®°ã)§"² »„¡	«ƒp¼ÎJ}¶ <öš4Òú×ÆİÀß ß}¶aU7Ş™Èû7è6Æ¦Ù¨ÔÛ”—a"–“Ö 8·¦‘¶fW÷Êoñ	…ÌAâKi;ÊÚ˜ó<bÉí`|Üä+Ûìá|Ã¿ì³ôîêû€°“RïzºøÜÙıü}<Ì¼â
ÒÌgµY¿İTWHi»Ş´Š©…ŒO×jè–İU†Q˜üó?U-ù>q³M“™ÂsuœLR 1åuŞ?ÿ>»:Ãü¦¨¾ÓXü8IÆÚ´—ª½T™b…pÂğ>! ³‚ë êá=9f luvkÈ4h:¥¡5¼á`Ç5ü5jÎòÙô¨¨–²R2T8Jô…â*×LTÀÅiİ€NètLÏÍ•Ù­Çi4ƒ[…
ÓaĞøì‹ÏL22G<W63s%Û‘›yÆÄsoééøõQëÔH-ºôëÃ³ƒ×»'ÙÉšhÛS3×’9ìÆ`¯X«ÖŸUëª2¼k”œÒ¾Æc¬C×Í]ÿçŠ×·tÙ[;¨İ•ŸO²"êèOD$J¢Dh|x:fÜ!=.
O÷‘¢ö?ÿ.ö.1†¢ï¡æ­™&!Úm`¥æt'ãnÕ3ØgÚÿZş_Öş·¾şôyŞşw£±°ÿZØÍ°ÿº·˜Áê÷³cÓşDÂğ8ƒ?“‰1Y}{_¾À’7¯pŠ>Û§ëh<­M{ù©ğİ¿fW…ÇŸ=åV…[îÊfÙ’úód@ØôxPIĞ†Gd<V(ïy[…ÃĞÜ;©„]¼Ô7/`Yı'+ôJmë¨ÔJq­Çgb„fğ¥™ô§hØ´AG¥‡NÙQÎ>QŞş\d?¸Š:m&Õ@€$´(­	ı”ôƒKK¥:=ÉÜ9AÒ†ùœñœ…(­ÓS«åv#‹wÏÒ3if¿ŸéßÚr>'T,¤6×;ŠY[©›~œÒwDínˆ6Ï]´:O{ş}¶¸É/›Y±é°EµZvZéÀ+*£kû-J‘†b"7­·1ğSêÃczzIwúÑUÒ\)cÌ=5_ä¬JN“(-±Y±<Uœ\õ^Æ¼ºÄFùßE‡İyÇ©`·&6¥Ç.PBQñæŞËx6Q7Sæü¶É`EÎïTZ£câ	ht]äe.¯NÙ,*d³¬ğŒö“_°|Ü41TQŸkÃaçã3	¢bCµsJJµjÀaÛ€ê¶>ßrĞìD%¹Ì{‹fâ»Q"›e$±AaäSØ_‚ÂÑŠŒı„å×n6Å´¨`Æpe‡µ„šÁíàt-á¢*J¸£I©
Ìo´+)ğå)•Œ¸<È±cB?m¡÷àÏLåY·T¢¥QãšÎéÖš§xÓqUˆ!8­y‹ç“Ÿ¸`ÒÎä2DSaçÌ®§§ÀvÇc}mÖ“;¼@Ç¸¡èıONB|‚OQ^ÖÕğÏ¤Kıo¶;µÁGÊºv¬5Ÿ*GÔÈUDZ÷Ìˆ™-Y¨"gÅ²ÍÌ%.OŒBbØ­ŒDüü¿º;Œaƒ‘[ï(˜_[(xh‰šxÔA™d‡ÄìˆÛğèQ€öØW_54Â…§Çô,*—îô ¬O•8‘èv¡GÏ8Œ¢‚E²±E£óÁ.ìU›ªëœºÜ3|¸O—7ŞÉßvq\eÃxg!¹%lºM*Ò©ŠìsºíñÜG¾$Tß7‰$ñ¾›AÒ€½·ê¨ ú'|_÷ş±‘ CŞ&½qÕt©´Bi§oÏô°•úg;(f÷0ME–xŞE«‡ºí÷î¤H÷l…öó[ßÒı;Ã&*×K‹%-Ïn|–‘.„_§¤yòÉ7Aui‰÷Še1Q~·t.y˜ºA¤ããò²À}Èÿªõæ‰<œâĞ*ÖÑ«Ôn0êEèéÁgé„&ˆ\¹Vä±4tX5PfÑ¬k¬cso~G_!/İ¶ŸÁşğ·¿©_ÏÓJÁµáÒ*¶2‘\×e"VìYRŸLñT¦ÀL—À(rVÜXQnˆò†(?Ë†+âîØ‰±+ÂS­N0“Öx„vW%£È`D*ÀËIt “„ÇÁ€BHBŒÑƒp=òdDî:äöå0P(°¹J§bOÜ€úKÛ×FfØÚaÁ×ÚfªI£Häb*§y#™]p][³áºä€LA·€ÆSŞÓK¦½¸Ş¿H…—¨£ØOC£LTrõT‹p®fñbìvº`à¨d×RçbZ¸š:—S¹f×·PFÂİ"µäâ´ ²˜l3Û¦xeÖN˜ò]ÎX3!³+òFd3/,±:ùJ³vBÖGÿWí…îß0İŸfwæ¼j—÷Üà4»/j¤K¬	ÿÛ^Z¢#æZğ‹:-«$Ô´iSdÑ¥“xõQùHzƒğ
!„®ƒ,”°hÊ€j¯ßxà½9%)©|‡\iÌW½g$Õ)ñBÌ_ù5/¡i’Û±–ò÷ĞhXQXÄ#CVÌ•Åâ¶B¬‡rÃ$èx¿ıµÖ;IíW­cş~2÷?õú³§ÿ".î¾Ôø[ °^M†Õ~÷Ëà?¬5õ,şÃÓõg‹û¿/sÿg´pè=ïåğ•·„·e/Ãş+o$ï_Öà]K8Oö.+äúÖ!í0RÍXÑîYê®~•”ù¢CÀ\¼'«Ğ¹/ñ~^¦–u¨ÇÃ
ªQì¿R?^Ö‚WU!¼Í:p8ND"PBjw<Üd3qÚ'âb2f$„—	yW¯*•—5ùUbîeA¯ê½¬y¼İd‹€%Zú…ËQÜ­zì5›M î(|%¼ÓXDÓLƒ6½%Õ¼ı”I ñÅèÕ¬2µm*Y8LC!]îK”^Õá'üyYƒ*¦´*¥–üT*KHlóÀ@Äöd[-#"U¬mL”–‰%ÍoYDõÌjpŒªåÜl–ÿ	]'m·Ò!PSHÚØœ»±T©hÚ€´R¡üKê kwV›«PİK)W¢¨“…Ñ…ÙX‘¶È"ê$ÑmÆšZ“¤‡Áâ˜ªà”‚IáıËâóÛìÿ0ú¿xùïùÆÚBşûÂão._rü××ÖëYû¯õúÿëËŒÿ¹{şİØPYiaÌUO¿¶·ÂG³*±=¹õ¾ T¡ü¥M[¥ê“Æø*ô½jëkq¸}°ëÙ¦šç:é8ÎS–ÖŞáÑqk¯åÙ­¹y
fÿşüò5ß_ü@?áĞ?[øs/œçJäLÃåRšLÄ:{×¬fÕºUİªóÊ9ï›ù'¬²§â’õØPGZÏÉº—º´ÛÙm½9Ù£Æz–hO²º³{Ñ€£?éE`C>>}‚cÈ•}”É³Ö­O´Ñ¹X†Ü0mzWNuVô‚ÚêÈR|GîÔPI_/C/!õyBJ,7”XRßËRˆ%ZdšÁÓà8é’ÌÒt›n3¯$® ªÈ˜šîÉñ±™Ì2L[`oæáñ<W
¹ş”³ª×êÛi¢o/2E_"_Ç+²Ù*)ÿÃßşö½LğƒPMR2)¶GudS|À6Ûê9Š¡ôTšjS×¤¶k²:,´+óXhK¶æ)'Îæ8h„|†m °& ©ná¶ÈûŞÌ]á (*ÆM'Æ"H´*o•[5po ‚Mç\W¦V[œ)íÖÊ|Ô1xØòöØôÔmÕ&è56J›‰—u“ÒÕ®@_Ö'"ApÙ[ôù¡´@Á¹<AáÙvvúõÑ‰—…f[éÒƒvÜ®ÿÛûxÜ‡SBË¬zQüÿ+ù¿Ó€W:ÚØ÷á”sèÿ6ÖYùïéó…ü÷…ôoxèƒŞ>aû~‹J,‰¹O6aU,àINÔ¨ƒÀ0BgyØ<-'4µİy¯(\œÊt¬ ‹{¨‚èE¯rÚ>İŠ—*µR†d-] +Ú \!Á&õŸpq^‰øfĞ‹ƒ.j
YZ!O~DıîaT`ÚÄSt/ai!7	€>D	‰ëÕ/, {ò²DcÒ½‹sjÕËíÓ4GÃp€ƒú“ÕA“,”4gxYÃQQZÍÄ­Öd[ùdózÌl½¿î² %¶úï÷¡µœ«©÷ÔTf¤”ß•jr®~/t‘³ÿ«X  h†ÉÃîş3÷ÿµşûÆúÆúbÿÿîÿN˜zÀ&®-? <§T\Ätev#.Ã`Lşp8«/&W‚ğ"ªwMy Pì„°òËC ºdT³ıp÷»Ö¦¹#LPF ]LÍĞC˜¡ˆ©+78~GX0‰Ç‚QÍ—÷H0°¢ùB)'Ï|±‡Æ®İI‡n1©gz›3.C­fô¨UCHdÒEĞ…˜Ng‰™şí„öŞ"Œ™T5Fº7MªfV	œ]_ÃÅnßˆ–2 +8›7iõGIàO;ßÔë«”|P#
+ú¿İûóîNÁ R<-˜J>ºvúĞ¹€
GºHĞ‹%ŞF†Ê0=êEã[w&ê+SØ2ZOK$ujö’¼‚%îj wÔá¿V8‰E\6­—+ì›TÊU·=¹Â-¤ş‡{p3†¿„RªkE¹a1’¥¡Rè¸·Ô|"vÎ¢ML0Ô±™ê/$F©PA¨²\GaĞLqó´H¡`¨%(5²©–)µl£egDÒD¤ ¨&[Üñ2˜‹´ªt-îbbuTšÙè}@r}/èÀ 	9KïüˆÖ½÷€B1+ÔŠU³}<"o50ÔDI…DVÚgâLÉ@AÅ**ĞıöÉÁõóšï»åƒÚùLÆk˜/X©úfO`İ«0É®o† ÆªU¦¿dR'§’Ş‰–ô,¾;K µ‰Îæ@»Æ™RŸ°™º€ÓE€à¤×—ıyäâ…5¡ƒà–Sƒæf…3¶.¦6ÆwÖÔ—ë»Ó f…+ÈwÎË‚6ÉÍ'ú˜`±÷ ¬¿g½‹ÉH€–oû‚s]a$bìõ­Zˆ8=Ùıûÿ‡–úç—ÿ×Ÿ?ÏÈÿÆBÿ÷e>5¸H†[æÿ¦ºR_å‡Â¸øù<ùÿ­s…º'£ÈÔÿø±ç=~Œ×Èğ—b¥ cºhd_ÏL¹fVeğYŸw€ÇÕÅóìŠ2ÑØŠ^Ò}›VXÑ½›^§HßÈk¸ôÕÔÚîO¤9õ•«ÑãµÖ¬¤/³ïÔ¦Ÿï­9s–`ÜºKÀûÕ|·2ÃeÜuÛ#&?yÿ¹ '©æ—\«>ÈËØÙW<rBX7æße¨$™dş²ƒo¦)¸lŸZP†SæAU+,Ğâ‹<ĞYz7_T€ƒ5Î[Á}QI.æ4S®ñ…DÇ#–QúàÂ»|±ZÀùÖõş]W+á60»¦ô¿FÇf4ÂÒ, @œiŠ¶°+»ié½„MD‘®t%?›~Êè@uQfLIğÀön–k1Š(;‹„–ÉBQO¦ç.ì¿²hps+Ú80‘ïnè -¤©Ã,[®—U²w€Je‹œ1éÄâ`#åÿ‰İp<“
*y¿ ÿÏÚó¬ıçÓÆÆ³…üÿeôÿGcš}4ô°+ÿû$Q êD””æƒïí—Ä’¨ôäëã~×C—q¯ß Ja¥E²4}õ÷Äøv6ı=_))ş’…ÂŠ #VHÒĞÈ«(AÍ6¬b:pÑ‹/¤İ@ídw{ç`ØŞ¥–9~”Ş'“-¡^FŠ¸Mİí-¥ü›¼¾›f˜«“›:£¦L@”a•«ŒjBêù_	ôŸ—Î£Uˆ¾÷ÿÓÎ7/Ä¶yÁ|$[z%eö°B
]ÔÿØıPyQÿ5ØƒU$ªYµØb·®9Ë¾vt‰ÿüOñÏ¿[Å‘êI¶WIŠèxéß%<º¸ƒ‚Ô‰¬ìr;In!aßÜQi“ ºGğ&Ñ“("^Š¢hsï—kKOâÂZ$C9péö&¡!µ˜âH­êEĞ††Ül´M@ ¤ôÃÈ?-©cÄë7`Œ–ÖèiŞ¨ëYch{5C…€¤àQ—@-Ñn"b¢hN}diĞÓBNI­Z”š[(÷W±°\|ŸÅgñY|ŸÅgñY|ŸÅgñY|ŸÅgñY|ŸÅgñY|ŸÅgñY|ŸÅgñY|ŸÅgñY|ŸÅgñY|Ÿßğó«@š  