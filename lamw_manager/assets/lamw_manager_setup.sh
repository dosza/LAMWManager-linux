#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="431127743"
MD5="0368aa0f4c851e90e24a19b7a349e104"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20204"
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
	echo Date of packaging: Fri Dec  6 18:03:11 -03 2019
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
ı7zXZ  æÖ´F !   ÏXÌáÿN¬] ¼}•ÀJFœÄÿ.»á_jg\`:Tæ&<f+',Ûg°£*‰K<£VûòÇ°²>µsQ#MF{İùCˆçò’÷@hå],êî­ÿ¶oğ»ò"`UôÏ‡?ğdqçv‘ï"Hˆ’”ƒ`İì<«.F±Y-õÍ#NSt“”ÚVHVà_Wş¨q€	£¥NÀŠï˜qv½¹&Êš6kò¤Ú­Êõ²÷b÷eƒ+¶.ÿªFY¼f…Ş–ğ8ı× F½ÿët¬F)×8oäGæšVpiO/)†a NëïëU¸›gçvÿT ì1ºîˆöã&ÂªíØ´ÖF‘ª_¼íxÆÊÆßœ“'»Ç·f¹š9†h7€Ê»YfØY½™)ZĞà6ÊgU53õjz£õæ÷%j¹ÌÎáf6íû1©…¢|êa:U‰¨z§ŒÎœñzÂ@Û,{Šîôf—cbâ?¯_3µúÊ´î³id:‘1ö­ô+J4„ ùÅœjÍ7yvÆ&ªèaV’¼ÿ] aú.Jç	õ_‚„Z}@Åı_[òcZıwÅd²pPC¢¯¬¸ %ºÈ„Ô7JÇ9øñ	æûMâØ¼÷_Ø„Øñè%¸tÚøÍWŸ™ =A³ó†õùë–«çIõt¼s
ªFìÉQ:!K)ú¨jJ²~vËp×’¨Eaà(ŞøÜhù¨¦ùğ±A~àÑá«PÒMâImæÿÏUæ0X´;³§¢ñw£UŸZxAğİMÃá_¥4:(ÉïSàÃO¸‘y±j.	¼ˆ±}É!z÷~~~é$
Ù>Àİƒç˜;· U‡,+¦v‹§'÷¨9”–¶Æ‚µõ{Ú¡%gqR]QÙyÔ²¨gîGAìğê;¾Äe“c$ë]g¿ášTnş¬¼JõSP®ë…óPVLø·tÑØÂQ+Åà«TÄ’CV€íI	1“úsb2´…ÅvOÎ_td áP‘îWn~ÜP¥U4=hÒ"×Ùg ¼Š¡¬†¬óx
å(Ò$–ÈOIs­}YGa9şH‚lLSB+ ¯±Ï)~)"btn“5K$e÷Œp+¤j‘¯ë-FNWôoS¿ ãÌ¢d–ºÀR‘Xp	~¢FÈ²6Í^ı©ô©Í_dÁ„û Â¿{›şÀøÏE®ÙA{Ì·½àœÀº‹—z¾b‹¡ØåI{OHñY'
OrÑr$)?«[z)qtŒŒXdš1€AÊj÷:e{ñF9©rìâ\CĞ^HG,f…•2¹µ¼–üy­M‡ô]âºğAïißšÍÿĞa”Ö'£ñ¬²b>'‘Z4VUæ0ğkäq'Ñ…©'Ñ.Ä¬42f.}ƒ[=kÌJ,¡[&á!èì|FE£Ï§»Y£…¯tgHj»Îjäƒ<©ö¥|€ùIl³òŸ´ağøğ°ŸsÎçe¡ìc†*} ã©|\ì4Äj·§L—Ú²OÌÄ–<Ûº‹árcğrƒ‡mÚ¨`6an@,)úÎa=ğï%Ó–X>/¾Hë{™»,È2å°0I)0æÀŞÙ9òš,¦@Bû…ƒŠŞŸ‹IcÆÌ'kWõx	éO‘¤!PªGÇš>à0¼—‰ÂC~ÎkôÄ¼â‡‚Xî§vÖfW“|R-¨üÑÏ‚ÀV×ÏC×:ÏÒôÖÉzÈFÀøxVI’·sçÌ¨Ÿ>fä_t)s¼ÕáÎaÂC†¨×ÂØèâË!XH5ŠÔ6r¹ˆXDyå}šdŠÈWFß&Nş&ÀÃõ²%â9™q©€‰›Q°^r‘ÁÜá=˜Ğ¢O–rrQªıxP½¿ıÇÿEvÙ‡eƒŒM±Y]»š]ûg[äë¨hs}æã§ƒßv‡M —ªk~W›¸ŞúëhÚ£™õ:zÎzd‰‚ßİËS *Ëmm4ºt'ctZJäM#xá#Ş­`ÊÁŸ¯’zÏ±¡¯Ahól®ôg×7/t t ÇôB²qñs©;~XÇùªªçäŒÄáÜ¤^[?“¾ÈpÂ¼Ï8Ó%ÒšrõA¹NáÑØ•`õÀ˜†Bá¼OŞ(³)gB-6a²Õ8g%Â®ìãş,8KöK!‚N-Èûû#sæhãä¡a÷†t<Œ÷C¸±,˜ËLòz‘gâ˜‚İÎÛ"¿‚,ÑMöa;QìO”b®ë3ZO\ú@õ{¶5€é«”ÊµìÀ˜dµO›å§ìZ%—ÖlN9Äùöù™NWÜjæBçÏôGøÁà±í ^œÓF®|ˆaocä_3èŒY\%|_íûKBÁŞ‚èDÌ9	@éèš–F-ºİ+Î¼3R®±İHâ¾›6Í"%eÒº ïù±;%wÕ‹•®¸şÙ$ZxÕÕœÍ;JÈ Û¿‚S	¬«‡iŸ¢ævştA7	Ÿ?›¼ÿ¼Ëì‚M)„d“›E—W©»ˆ°Ç.¢PÑ…^Ğ¬ÿÃ¡µx­&4õ¦¹œJ£Ø9Zœ3±kîÿ`¾Ÿò€š˜à(HCçôÿªt`¿ˆS3(@“8?î‚Œ‘èé!šPêìşGøû•á·*ºs¬Y¢®À8ç†Ws¡è†bBª³CRØ¤ä|D:bT,ÑÏ9bÄÒW€BœŸ0‹y?‹A‚
ÓwÎDÏÓç/©]!Be$“®ÙÇäm²ÜwÚ7ù¬ëÊ°¡ştC§DZ&=ñà)? t¿ƒÚR¢wu8‡²nZ&¶w0lÙhÛ¡fÌ2e.EKÅvewZ-ÉÈd¹1åœ>ßSÙ%]‰Z›ôUdT!¹G'­Óš&$f¨¿6c\±c>Ö|ÎïİL5Õ&sË)‘´hûdÃ€;:£¸†Y{UKïQyH{³·º5òŞæªk¯Æip&!Up©»Ïkø{à3Ş2ˆÛwZA5ôšÂç¥{(¾‚ä¬‹ËñiÆvŞÓOÉƒplN„{·aXH4´ùùÇ¬&°ã7›®1—™ŠXÆ<+GÁ[L¸Œ@8Ô±Y\X–E‘qÖñëçE*z¸»&©b¶b[fSåşš6µš|)ïœ*Z=÷¸Å(º†àİFÂîõôo€ìEp8ƒ„`Ğ‹ÏÊ£d:³û—¡­¦‹)ö^á')ËŸ¬ççı"Éí…À¯š¬ğ6ˆDˆ_Õ¶RGŒ×‚Íkş†`, Œø½ñ/}5êø	9yJ¿‘)¯ğà–\S†ûøúàKèZ³‹kÿ«khIBäæì©~Ì~°Ÿ:j·mùâêıpµzÑ•0%×‰Êß›–—&@Ï~Ù4õ­­qSVşóùÓåË%…@Y—'ä“Ğ¦®.ÔJJíÁ;r‚§X»“¯‹^¾¬- é&…e¢óÆ†.+iÏÜûïfCåi¥èIŞ'ƒ×²é~Èéû‹ÿ\ºÇıkhHç½ÒuÄN“U%‰Ö 
¿õ1“+¸ãYQ^^Ç ¦†W“¯û”#ø­Eélwî„s/¥û—é2ËmA'ñ-YT3{v8‹Ü²O£MÛ£=ºg°µ
ø=[²%{[g„ñ”Éó+Ñ%T„K´qd Üÿ¬5&«cç£Ì1¹jˆ†ªW²ítŞÚıIÕ…øÓFÉÔC}ŠêQE3,†ôhM‚=9[':»š•?B[˜ÁdıÉt)eğó~šªnvÔ1& z
b7IŞã¿9¡]OnN&[HEù¡ŞYB3V¸I”ÓV¤ä†Áªì¸HSµÑ3Ò$ÁÌ¤±J¤£™Íu•,©ó:Õï¡(¾M{¬YG·á‹3tcš´“¸‹ÿÌ?ı-Õ·1–W…‚®S{ÆpQÄğ×Ò~ŞO(8EäI;1RrY²46[ğd"‘p¾¸¹‘õsHİ“æú¶-¿°'\á!ÿ†ë¬ö„rVàÎF“=Óñ	^\d€Ój!S`°,ò]¬	&7T±%kO¿×_íä}~MÒÒì7séÑsŞıÃ!DoU¬â(Ï,¬¯<M­ÎsºëSÄ—Ès"0E9şD-B¶2H*5Ô¹fà’	Ù=%kÜ [íû1l œ(ä`da84‚Åp}_D €¹lYä‚ÖQ	E.ırÂ\Œ±œ.×ÔÅnÂö?^•<p{€¸g$EÂF‘S SC}z¤Ó6û*‹`|Ù8ÇqcÊIÚÒ• Cº–¹ÖØú)hh¾~¸u<»Ì#™:d4“­¿fSLwÏ~ºx¥Q£ctè:–#e{¸Ã4¿x¯µ+™Ÿ«ªmB‹ tgĞ‹`]eÊp‰Z¹w$<…±Á¯yøêÃÍ!_A’ì†æÉ2‚M{<NTªàİÁ8¬å(­åLA	ÓEcŠGö}­Ê™ù¸¡2Ğ|ƒy}•¨Õ0ğr²!Òœqwda7ÊÈ‹nct‹Ìu6%±kî†Àexe0•ˆ~õSúÎÖ ·Ü“7u‡ô±À$ÓÁPé?ùˆö†°¦O
¸i Ydäëºèµ­üÜBKÜ7!Óq¾CJUàWxÆ3€|³¶À"¢†ëÅÔìE)%éĞö3³»q²ğÍ‹®‰ìí´ŞTµŠí0¸XÑRåü¡ÙÃ­Ôüüâ3¼÷A¿j–É9Ğn]ç[¦ŠÎİH¶@ø; É}éÆÆ‘@üXFssçÓeåöÍ¿i¾bWÛ6ÜÑ`.ùãË±©é25±ÿâ'Û?Äl'ÿ^ÙŠ
ÛêêÆ²ÈåñøTİ”Ğ4»Oõïı°÷¡hJWó‚ÈÈéX†{“$ÿpÆœÉ\ÒL;O¹—A;î^É‹şNìLÍ‹uµ§wcÙfIK3€Ü›gÇ)ÔÜG•5¢}\¶y¢V‰îÔı8˜™Ú¤Åj
|ìv†¥·rL÷^Â®÷ìI¤´C0™Ü”wMÏ|œaı@$¯ Î1È¤pp£"ñÛôk-Š¸eÑ¡¶7Û«?½Î¯1$™<”·é?’=*!oÆ™
cÉ ›•$äç*Æ—œæ¢Bà;÷O›°ä·tÄ­×å*oé-ôVtÉ.ÿiœF–ß3¾
;K	@ Ë#b§8M˜ø±IhÛ­Yñ¢Î¡.V#¼Wä&ºKZüÊlçO÷éĞÇñ4~*l¹S½a	½ZÕºAjy}1İZOtÄ6-Ì£n…ñ (ÀñZŞò\aU=H°zcL¨kÆé/¾dŸãp¾gfÌô*™3dã á+§§uÏHÅËğU‡nÁní_N^Áµ9£;ñ[F$×€‚€Š¸}óDgD5«WÓq0âô6Ş©…Ğq¼óêÚ÷”Ê~hú…ŠúV½YÛÎT×ÜúF›85•Üm6y*xÊ¹á£.°D¸²	P€¥¿[ë9åGL•tÚŠéÓŸT:Èô£Œ[X±IÌ˜‘—wK;-5Ã¡ôÚq]›~ÆC÷øbnĞ0†|;.Æ®ÔFÂÒ‰q
‰¶®¦¡‘)ƒ9#y&”ÊOVÏãñ‚K÷céÆKå×4¼˜lÌ’DÚğ~Õ-¤ü$%¶²ÉWnvCâÙ×D”ïæØ¬Tº©n1i#ßÂDQg6~§4»ôïAŸÛÇkem`§
1 úbˆ.ß‰ÖÕSğ%€²±Õ«h‹
oÔÔ®ô5&.-±2d¼¡ÌmKÈN@‘ĞÒ7¶òØO;¼AÆ½\ò]Õ£0Í8èúØŞÚbt;¯êİ<ÿúùµbè¥«21e•Šé­ÎÄ++Ñfî2ïªbv?›…8‘-ì~5‡»ÈØõQ1," k¯«—>Ç3Â¬ç´§šŒÕšZ¤'¾€oê6ªàíŒ .T3º˜:I—âÃı‡²¢–!ô0^·åŠxDv İ¢ëj€ßØõ¬ÄC…¢J¨{á¹$²¼j»ÒşMg¯r:äçƒ[ó”5­ÃgÂ´õéd\Ç¦¨°’ÑşlóTZg&{RIÓÑn8å[Z&l`çö”o¢NiÛ×ÔÅoD!Jõ;’ê+”ïş’y¢·ó1’8…&áıwíƒCÄ0ÑÔb™çŒ@Ú2Õ£Tv½¼]j'æª÷9ÿi€†ŸŞFË‰È),:rœ¹êWÌ	ŸÉm§Œs7ğkÏ’XÓÑ²¶#:b‚l E2kC úÍ4é‚¯l”¬ÿ°TŠÜ]¹¥ğ`å`ãŒ®3vÇ„ÛMó0Õ*’®L0•À—|)keÔ“´İ³á´!úú	`F07i(g³a-÷©È•š.çCæŒŞğ.¦usbx¥/%£EµA;CtÈlgèğÚ{rJ:;Ã5)Œ´?,VŠÆ(Q½µ:)µPæ±á”¼CÿGy3¶ç¶¢CÅ~Ë;Âñæ1=f%wºÉ€.µcÓ1{ÏÉé'C¨³%ÏäK9•%´Îk—qì‡usyõá`¹ÁÇ
Øéo¸¢I›%Ú¨àÈ¢MqáÑİÅôŒüq¹!c_BšÆêÙ˜ÇÀ!n“âé>ñ“ÏEv×&ÍÙåŞ´ÿò¡7‚‰ÃÔ±rAæ”¯òs·cäö”LË 5[Uk¹ƒ}28Š;ÏŸ«lâ1ª‘=,íøL€ğUoa÷¢­µëĞèŞĞu’°¨ËsˆÅP™¾‡fTğ(
áÙ!QÍÅVã?;8Ç$ş|Q€"ë~{^ò~øyÌ–LÔì\×0IoLrcSHCé8AË‡ä=¤%7²Nšb·•rİÅd*7í-
Êµ‘”ÃiÈÚÉŞw¹!
ú×:ï©Ÿp¹¤ã|bÉş#M7–§yÉI*LĞÆË'ÛZ`™¤œÜ@µ‰’ƒöØ§ÓÂ3r Í@ğpm0G>Êa¼¦HØMKº/:Ü®¦ì_!+³ÑøàqI[º"ô#0¿kù	ËgÅÂÚ™	íSËUŠ§ Q[¥»WŸµLô‘9AÖ00ò	27:ÍM®&´¡§àğˆZàx—Ï‰‘×’
€fM'g…¨ÙDRTÖ˜	†Şv¯Ğ"­!ç¢ÜD]·MñoR‹˜ü€ù%‹q\}G*üú•½/S¯ÖÖtägePˆŸzQËrCz¢Bn^Ã¯JÂ•|%yÖ
ÄÀuÎg¬ŸB” ;š[½H¼“Óx,g¨Q½\¥S'/ÿ×}şi£ÀòÒğ×u?RàVLÕlŠ=Q‰ñ­±UjX¹=3™åÀgrh˜ªˆ3±$™DpÁûöÁ6^4*v¥—ÆM'ŸˆIlÓvu_†^æª€=cVóÉğÉ&¨÷¢»P„8DG¸ÙÖÇW·Ü~¥Õœš}”Ä.J†#)ù6-5î)µ2„ÖBÓ~°Y(+b!qCYøì;Ñ Œ²%3· "¥d|j:¯€z:SÔè´rN]PğÆ»g¤[Ô“ÀĞõG®8 <’ØÓO÷}í.Ğ7®QbÆ…ÿı`æÒ¦ÏŠpç¯¯.Op¹é¦¼xp"§]¸PGZÅïÓ5–ŒLçù`	±phf±¯v°çJØ‚¯¦¯
ô ôã`åg"ädLeÿv”gvVóıƒ"JĞ§hcÉ8r³£û½JîÕûîÛÈÅË•İy!·“ƒ'…'+ÀOPù)„\;+sê«M˜©„%³ëÒÃqãó á8»êÖ:hç<"¢å¿¸Ô¢>„cø_¶W4jıQyl÷x·úÛö¥8AMO‰'sŠ"lÚŞüÆÿõásLŞßT?ëêÃ8yøûÂs3‹ĞZ~ëFBÌĞP5>Ç³Z€|¬^¿ #îµ.Ëï°u¾Aè<ƒlÊŸÓ%÷]E;ö(  Z×	*^€i°„31ç¢K!e jú[¢©µ¶I´2ö’ir´–^ÒÛ¼‚êš­#îìbE…ìëGğÂóšNÀTØƒ­à?TÉıïÇ³qxÓ^>S×q3—bÃZ¤PßÊvÛ%Mé˜	 ¦¨¹òç”œ›/J6¿qŠ¡˜&K¨è×©µu"Å¤c\¿ÌÕ£c™—€OÜ@ö¤ºRÏp¦ı•ÎôN¨N¾÷n	şµf>l?S¯R\}àQ3•¶Õ\V¹¼9ötôú·M=ùÿ¡ú˜ç·â„^.ç$–ßÙcÆ0˜lÑ˜ãÕì‚à°k_P“(#ÿÎ³0Fbm" º(±N¡qãÖWNÀÍ#§NÄ `6]R9­e:šÓä4^®fµÃû—Ù!3ô³j‰—ûğŞ–Â*‡Xö"}82^ßİÕçÕ‚¦á™±/™)^V8ùÏisëa
~¸Ò—öm\Í]zˆÄ‹œ+ÄÔ9â[IşÌ1É©Ÿ²<FŠNîóM“±0 ?‹îƒîn[ºÑp#$E5w~\B{Ÿ0…”À/Ø˜t€7cşj6kBÀY¸¢á#:ÅÛä•ºÛP*tÆ¤¯•
c©ÍĞöÄcîPÏ7šJKd¸÷p´1Ê‰Éä=ÁŒ»İ´N©Á<h![Îó(¿Ş ¶µJmà¾›şÛõø¼zWá<¶ã†Ú.ıåÜy+Îş®ZÉÕm»&·æ¸üò+gM¹m91uªC¹§ÅåiËôJFìÑ ŒW »ƒ2`èá@2Ğøeu°Ö0Á¼®€:hü6²á~i'æã/"v}o¡İ¨•Èòcr&MZ×¿¡„XçbÄNL1¶şõ'æÎÒd›­M›	25òk†­°¯4Ş†£Ç}æ”ı„äpÆˆÁ/­â~ ,¬!¯ækŞŞl!x¤êµÈõ.M–û…¯îöòŒbø/†J'ZM§¸óé ìHhŒªĞšá~¥q]Ó•¸]ay×nÃ®2À2óe˜ï¨©ogƒTÌH&Ç ª"f»R2Ÿ<ˆ\¶gÜ¦­$¾Sí7XóÜa°>!	f=…ğ¨Î_aëGT,‹mÀŒˆ_ô+öÆ¼$ÊRè€Ş+¦„l‡gùVòPèœ¸ÃXş~$4zÁTK9µÍY–Ã«g˜TZHÈ#ò%©=áœØ îˆ„ÿ2`Oä?L6?ÿWÉ-e’[çò”»5÷5|`*µSŸù xÃ¾Š?^ôAÌÊ•à¨I¦††ê‡µ!í	ÏÜjŞÀ¨%‚àLs£ÓLÖ÷/oÈ8­ÜESšğaáqŞÕyaSÛ‚ü›€É¿¶ƒ"Ü=%~@âQ¢¥;™ÑI7"a7ºI”Fyr¬æGf+Lˆs;`_S±£„B Jß©¶İÀ1S4ò¤O¬y`EÒ|}MñMò‡ş†Ğİä“~×ënò·Uò`AÉf<Vô—–èÊ°Áú%g¼šà©o›/rU¥]ıWĞzü¹¯ısT\?î=ÚVoòÒ¡¿³Š×7Úr‘@íùql¥nb½™P["\ˆ^Wã€×}«Ùòî,RŞe<´aQ•È½jkÙ2º_²D±èMúbû_—DX¸KŞKÃŠB”hxÂ;m]~ÿäxÌ@¨ì
Û&jP³íÕa»—.ıÁmÂÛªjhZŸå¥¡ô1Âé=g_‘(ÜxjXğ—œÏ#·ßMç²”“ÓdùçHæìÄy~=ç² \1=#zÔÎ§Ö­b,h†d0E(ãÛ•¬õâåE÷Ä•¼Âª“¬ƒÑ9N®ßşş\ß‹ûò–’Ş9:"›ÓŠR)Ù’G‡xÑãDB¹C.¹g»æ¡ ó¤¥ÖËÎ{ºí‡?Tœ_Ìá	!¸éà]ª#û9ÔŞÒ%0Œ‚·ò]Êéî,â€Ñyõs¿ÿX)]ğÛÒ”B¾
§:Æ»Ù4„x—&Ä%®~c£$~ı}Ştd ŠğæŠö
lê|nŞ<ïŠ]²L0©è
4¼ÜŒ|ç7´YÿÖàùnÆ7¿™UÎ·|°ÓIX´5¡€¢z¯ò±V¿Ì%å5¬:+?$™n2Rş¥4-£·söŠÉÑ¹BÔieUé~' Ş&‹)@´E\=È Iò~ğ¦s^·¥ï*Ãg(öÆúŒWì–íëBÃStÙ"otIAS|-çk¯·½õ¥igRÛüäÎ@.”ÚãğC¬&s¼›+µg»ËùmT¡é¸ø„"ı¦ºš ¨“o+68²$"ª­qVºíkX>¶£ş…I	7;¥”­ÉxÒ
ÌÃ¸if¢:a-säbAÑñ&cŠY¾¬l)mEëE¼-ÊwßÆóÑ‰|W½1/ÿ…µ+ûô}«È§rµ²t¸ÎËNŸ|¡ÃÍ 4p¤‘3}œQ:ÿGEg¢MÕñ²8íí’'¯pš7kdœ:Ğší©*£½—¨Í=;+DË§…¥EL¥•İfêşZ}D#
J(¥;K·Yƒ+ÖÇ×ëVP/\qmÚx†lGé]¾±›Š°rèÊ«÷Ğe¥/z±¥•RˆOSl)Dûø™K² ğ¬.˜@>İ\ĞHœNGÔ*[Nœöâ«VæN³œš\FŒli» ¥Ù:Xf• _¯Â‹âJ‹Rµ¥TfÔm¡c&YgÚ«"tãûNãÓv/‰~«äQvÚh2ˆÚ=`wKÖºo¹26}~Z°…JDV'Ëï	%™¿ƒ _uÿ¸²Œ·h bå$6êrºuÙımt;ío®šY-cSºæY°ØDÓ-lğ©ô7c·7•®/ÑIF!£r	¥í*'…JË’ª½‚Dgô
a®jY4¯ÄÀ*~;²¦Û¤¾‹eAr8ØâÎµJ«åâ2{Qû”^sß!MæfjÎLŸü]™o0¬¶2#Äôw6ÂJ¸MQìjF#2< ˜²foáªºåOdÂâõå>¼ïwaÚV×ù„®~JĞ“£" ¤–¹Ä×ŞË8àîÎ\e^ î:uàU¯w+¨—¸{¥¥d£V›,D˜Ã€6‹œùxÈ…VòO|hÇÏ®àbJƒ¶^îµgÉe 7Õ’¤'>9fiP-½tbØ+Ê¤6w±mÜìwĞĞ´g¬ØQ44,®×$a€L‘@l|ã„Ò%mĞÈ!-ã!>ü§åîÌn»¥-²İ¦“·A=—ÑÛ]3j¨í& `y9%ÁlñtÁ§­_ŸyĞgÊz9™ÜgFÚ'_åá¯£™y€Ê-;µ¸áÏÒĞA._‹7ßî˜úÿ½y«—êÎ7•ø†'0qğ	Í ¿ìVe*{†•†¯¥™;Ì™è&>Ğíd¦Š¼fm»Èë²Q¸ÎÈ4®æÄí›Ï° ä'ğô³ªão	Âƒ˜‰bt@ÑcØ¬Ìõ¦pbA8Œ\9¾èÎ¦”DA=rS\4*ÁŸ³„ôÍQ¶[êy×Ä=± @Êø	×‘+b¹tˆ Zísé…ÎœL°úl~‰-¥é	"ko¶î" Å÷iÁÙÔ¡ÎˆZ *ğ•?[ÙÚNn_¥¨¶9IµZ¨¥Òr8^k©u]N>7¢:2‹|ˆNÔK¤ÏSŒì|Ñ@[‹eCKV
ç®‹©³’`^ÛßØÏö–ŞŞâÚ ±çTíÄôf'Bqˆ¨˜¾‘M–Eù×Šï™étSzâŸ)Z­ñ^HgUÔÇıàûy+ÿõÇr4G•m›¶É¡í¤EÉU˜Ş…&ÍÖXJQu$Ÿ´2á=Êí×÷Í	£ÚçæH`=È<±9o˜ôÔ“5‡>'`HE*Ú»¶~ûgw“\±Q£ X‰s%JïãOH•6ô_SÍÕUzæÑ¯ö7‚«ã^"Œ/1İŸò—ëdå+´n.VøÇ´R½V¡ï`ŒcÓƒ…:“Eé4³swxn>nÍ2ryŠÎM¶¸µ¸zaJN¶ºĞ=óø6Bûiä×=	#Øtèî$.óY¢loÚKÔß„à™ú¤_³áªdešv€ cà"~×{‚º$®kÊ3Q§Å€})†Ö'+RÑ–±‘dKÄ³ÁŒ«|ºÕBüÀâ8œThÆ”kvR÷c]/‡yÁNĞ¢»±Úòé²´ÓÜ˜øOò7¶;"m{”-Œüm*ŠÑ´]8Û`qm”,ËR-’ƒ§H_r¬ì¡uLôkÚÙu?Îs*IŸ²ĞgG>©é‘Ç¤¤aN¯Õv´“Ø|ÿŠH™õÑÚ#÷Ë¾S0éÚ@œEæYVëÁ+àeËÜVÃ1d,´Ï:lõzõ‰9ŠSŒ¢<pE„yó~8¢ƒÍñ‚¦8Ÿ9ª/]‡V¤ıR1-L¡Œ­#*¦f`)‚Ş73úÄµ6¹ßz&nàrZ€‘Ê3;nI¾¡[7½ãÈp·`ºS¤X1>¦€¸-
ı›•®Œæš(2Ê(?¥³şŞÈ ´7IuË¶%nêı@“õ>VïÇâæË·‰FûT}
ë”øêÚÎiñ])â-eTûãAsA!tsÕ	H{?´Yhi8Üş–)8LVó•ÖÜœ†Òèx\R…=3–z.ª1‘xM|:}é~|8Fõv ÍÇU,œg#»­š‰ç˜`y0me}{4,F/±·s$¤’*a@ş’lĞ]OC®£QÑó¯º¢(¯ùËı‹Áb<Åãšï µÌšO'Ôz#¬y¾®f‰j¢w-yT’$¤çÏBk~1…“™—+;–ÿÊyÚ&Dtò§”{‰šÙJ«vÚ>mí-<Åİ]ğßø>‹S¹NÏBc÷v/ˆxÈLèS¿Vİ’og×DiMûbŞx‹%Yæ½$Çc4Óì¥x—Ó•k°ÙìœÉ*CÃƒ~·—¯ògÜLôf¤ã9ÿúf[*±/=‡Œårœ´;5éôÔ®_]âly,ÉPÍ©²>^/°Ö»ÏB™S¶övRoBœ_N+ÒgMh˜ËŞ`š!8õÏRopşïy¡/ª¨¥lfA~ÎUŠW¼ë¢¶qé1N‰nÍrÅ*
ù#%¶3œr5`#XĞtoÿ½]„Ä`¿Ì+©>K}+óß“Çšàrm¯¿Ùcÿ2ò¯™! òK›‰²Ÿ¯1ï*	çàÀøF<#êŒU ˜™ş§ˆ×K ÔèÌ}ËŒ¼,àPóó(rF’¯%µn¬A|¹üÿË©÷¼q?4?<Hì]7·*6Íï‡‚—´½Å6¬ßö„gH'µŒ!åŞÑŞÕl‰¨lÀÿ°,´^œÁŞSxb³]÷Õ³$ÌÚlÄ~,¹!		öO.îÁ^”HB0V+}Ÿ¿è\¢ì± î$œÍ ôô÷HE¦Š!”ÊvGt’tíréŠÏÓ6iI§£^Ñİór×ìU ŠæÍv,Şzöu=E‚!Šn¹
ùÄ«h7©Úvrm¬®àç6œÑşSPIâG«â/¼ÄÀ8…V¾ğYË¡§˜`Å¬Í\˜D.kİX7¦Ãâ'P³ª”qÒÚÔ¨¿×ÅÔ´B7÷Ca«bfÓêš]ûºi&ƒó[
Èi^!+äP§	\Å÷'QŒPŒ?òÒ°[(ÁÛå¿eÍÎ‰#ÒV]VÇŠ˜RMr1_†<ß›¡vAs|İ‘†lyhÚ±ÙĞ<óÃÑâÙGÑ°™Ü1îêíÄ'"Q†7R¥€Øñ«½i+ïó
ƒÓ«´Ktú-?İc²ÏE¡“Hìş©—e„N]\†iÎéìØ‡Šæê|Œ!¸Íã@XeIãÉyU«ßEúâ÷ V‹İ¤P ó=sá…SU½§Ã)[Ô)¤íƒîZu{B—¬µÊèÎç2zCQ©…Ë·‡wbaõ8¦ûÆqš±g“ƒ3Qèô"¦·"Ø/úÎqšßöÕ9k>ÎÍÜ€¯uÖâ©r÷ßìPãKó3"àÜuZRÂ‹k3ƒ¶mcäliÎÛû,9@Y†+^/İ÷®›Ä˜±n¼9@³ÅH§+l‘Ò>ú·¢ 4‘SÄÒİEÜfÿÎT±sñëÇµì\OŸJíXşqr}¦Û9D·uú)u·¨0Ç®	i½ÿ+®Kœ#—.‹òB$!Rf‡ø7æe IãZÛíUuR<»¶€†€Wı´ÖêµReñŠVâ;&œoü±iÉà_®!@%Í~³Úb.“‘¾s€o™âeZ[[oİ"ktY#ôÿ‡÷ëE¹œÑ´M»/+­«‡ìR¬vÿ¶5Àİo˜ÇÜ‰u|¨-Í×éFYùwğãGÜW‚F¨Ş<*‰uz‹¦_³®¬”Ó§;Î£m(d*º·
Ñ^ â‹À‹à‘üÊûéå‚jB–Gµšmv£â‡ó±G ª“]ˆÃmSÈy³’ı€Eõ
–´ü'¸\Ã	±¨U	üû§Ü¸ˆnÀíiIpŞ%WOÄ
İ÷Ê3_	K=¯?î$nb|U¹<šøÙÙÖ9 ı´Ó«!ís†ş†•®áö§˜8‹Ñ*û¶zå™.8iË÷5˜€´êğò’A•Øİ Òë‘Öùª˜—a,¾g‘/›TP	²¢îË†ib¹ß\V–¾Ì€Ÿ±M_ÏCÚD"tŒƒ^”¹R2•TÌ$.ÃqL€­ñZñÙF"1Â‹Fß±™ÂBj™®bdªÁë¾‚qØ6otÂîw$¨®ß¸Yh?´'+t¹û
ó1<TÁµıæK«9>ó÷ „·;öÑÏĞ0êC¶‡ŞÈˆœy™Â$ò¤ªj7 ¯ØaZNUc­À,¹[•uHÖM9Ï<î¯:N¸Ø¸óåvJôë]ÊÀ‡mıYW$!g¥mŒ;´Q,"º5k+ˆ b¾d½…şñ‚N´¥Y€„«³áËƒêë#šorILùº·„%L?ÔòÈì+r!ü~¸[Ö ™ ˜î¸	Y]ü@Îv‹úXr´b£èÉaˆçÏí‡k%D”ª‚®åi5‚~T¥ş¸PÆğ~€ü °ŒÏBƒÓ¥¸‹ğËÍ,’uUa;ÏIKy+}™7|yŒ#­ˆÊq©åâ6BŠÇñkÉDmõ=tÎA>NÈbÙï,gËíz¸Óàk.?ÂÍÛÔÈt™=9R~¡y¡J7#)Ÿ¹ÈâúÆ0'"š.W(î„Äô	•ßöL0a8†š¶ŒrOÅ#ßL°äPíd¯Qæ"b3úFYÔúÔ…,X6FwÔÄ;>'DüİË‡Ü*œİ¨ÉÁI_&©—_¾#‡¡!åïÎÇ5M¦†£½G@'t(‰ı‰Şô™ıù“Ş¥“« ”Î>*]z>­&­óNˆJW¶xi=¶TPB§é•Ñ)İÍôa3täc ğ¶„Â›i-£ YÑŒD	2†ìk#•Z6wÇBl'«ZFánº÷¡0§D<xñıàı:û]L›µ ä­¼G“ËõìX–$³ÛoY™3H ºAÓŸNË¶Eµ€ÿÄ›AHéYÊøm™Ç²×¹QïAFıÚAY¯ü¼&c>qYi%!œQ‘†Öß…Ä±4;„¹9¶5Z êñl¡Ùccÿ„ëBÆ¨H‰³Ïñ¸Æ~®¼™z¬Ñé¼Ãü¼3’ÂM€Õ¬"n…F´}„Më¥pİ‚“{èa˜^Ç0õ¢dˆˆ7Š!'HYgâ¨¥?‹Á~ót)GzÄÈ×÷GZùl‡ŒäGµ2ÕØ*N÷.>w;Éİ–)û±5ùtR@İ…ÒÆÑ¥£FØyg'²ä‹üUJú'vÂ¹…‘·-ÍÆjx &YY5ñxøçı"ÿ‡vÿ…ÛyKêÅ6=UÀ"¾ü˜¢~ì~·îgS›Ò™!âôâ°Ÿ¶İî¿Ï¬b‚|cY­v6™¯;@ê‡Pÿ¬â‘‚4N‚•åá³›RL3ÎÇî"şAŞØª—…àÊXûO‚hw0Ã¿_¸£¥ÒJÅ…ÍZšá‚Ná–kW-ªDö'b_666†#®B¯´•ºD `üx³ /rÄ¹Ö-5 z§b6îˆzâÖÿrÌ*ÎØ‰3«ZÌB2ôjI	î÷'An×¡?]^ HÎá¶»;ñ1\¢æK5`³Õ¿Èñ"ô$¼»¢û	F¥Q]¸š¼X•%eÍ,ı
À¬É¨cÒcş’¨ Âğì°Q@!2™Ÿ”¼‡Bà¸öc¶‰ÌgïÀ¸²1ÙŸƒ»Ò±#„öòµ<òAÉRu=»OŞœ8ü‚}ìíÓşâ* ©s¼ş>8ŸøaM;¦Jx;¨%ß‡2øDŠ×ƒı²êÈ­-È—gr“v!‚É¹O¿<—Ì¸şsê¶X?µB‘ÉûUfÔı\?OŸæ7{+°»Ñº¡äÒ€qhqK©Se—-ÊğS1×%uyÚÛÛìöİ¿¯y>ÅvãaU‚Ê{m®/ €²“ÖG6Yù~8%¡û]ò™¯69¥¾]n¤_ê'0%«)_…¹-•x¸`¶ ¤!Ä•—±‡±m9˜w]Ä‘òéí5¢¦ÌhhçzldÖÖ	(²›”‹¤gí=c}s,‰™|ğĞf!ÂdÊ˜»…êÎf§ó‹™á‰6Ô9’µ××"” ~ŠPé*š›–’$àáfFJ'ÎYµr¤wx@©ı¦·7œ(Ñ‰'ßƒéÜ{a^R¹'Çø•¯%ë’³?ó?Bì%éJ"?6l–•›+ƒÑpøDIçêMÎ½AlÔÍ‡ìGá»xaŠçáP‚[es²øÖ5 ¢Û^l‘´Â˜½ıE¼íM‡€º…ğƒ6X/nìºİ¯æcòv(›~<í÷‘¤•öÛa JşÈŞƒãb/¦Ğğ‚çw[û”w5DêÑ¤[.öÿdrĞ‡äÙ@ê£7UÔaì³1dÙÏûF}e6àêé™Xâÿ¼è—`Ï`t õ¯ø•hšÂ—†wÓ§E	Qôü :øW'†È´3=$ûæÔÙmH{n	Ät" ¦639’UŠ¸T[tè–u!»˜¢q=:’ñ«S­·Áèœ’´;ÀÚşğ×9ã1ç6)?ÛìğR"Â+cZ>`êÄœCg‰C]vx‡NÔÙÈ6âí@óĞ®ào‰ËŠı$Ç½ËÀ ¯»úaèÉãür£÷x8$è©1‰íĞ †}üj< …ôzÍ;P®#Zß\Sš%9!/´šptn
É÷%"ÛÄL³Z Ò<’5J1A œ0\+¡êİîBìÇu`zÜåŞºÀ†ÜÀ¿XSiGjâj¸Œ…ÚL´å¯Œ_  ¬4$¦SÊEnWa{çDB,±s‘«G-ë1 
ki‘Œxz±ÁHHÙ‘qKœñŞ–IéM­CkMC~hß§sÔ™ØFwÓ\B,d]åWL¤£ "¶µX	 =ß“'(Ôf—Ô5øj´h]A¯Y¨	@FD®0õè¶«êBV™N¬ìş áoÁ.«ßáı ZMEëW<Ù/0²\ƒ3„ê¥.*°×Cïš£Ôƒ&îáŒeKhÊC¿`–pÈ^ÄK´>ŠØq_¨ykßâÆÏu|9ıÒÚÕ½ƒ1¼xLj9ØÌM×i¼\ün×UfŸşô@"HsqW˜Ú½´¡<‚/•­ÍÔo;¹´±ÿüp8F”’;´"PaOkÒ¤‘‚Ò³iµ¾p42€D·¾Ïë!ÛÙvıMjPb×yb*õ])å<€Ã¨Eôjs˜çàªê~XH:³UT#êxc™?Uíl³«“I—ßÎ[Ç}¨ß r¢lµt¨Kf˜MvÜ0¥Ø_2sim~“¶Ò£ù–.í;ˆÚ’/ÆûC¶ãC‰öªOÊ³§´|Ìt';‰Y'}¤yFò¡µøÈÊ;Ö*7 ‘ºÓ“sSt+NäÂ•½oAP7&RO"¦‘ˆ“B|ØT[ºUM™îá‘GåmS–^~CÂåÆK‰a<ƒWut­éÃ¼TË_ ª²»‹–ºn7%‹ éŠSe¯Ó,Ó˜öYåxº­5ñ«ğ8d§¢·™Cuã6\ŒĞ™s\"z¨fXAÛùıá¥Ë²'Rª=Ùõ¸b3ÎWóËNÅS çÁ´ c´»Å¡õ¬›ÏóÓ»çŞ¸”.²×‹
7§¥ú‰ŞÁ3 ”Q²#wşó]´¥iœ•×vz=Í0ã
ÅĞ˜É ›Ô˜õCÔ‡¦;½µ’qÆJ+XÛü¶¸Ä‘ÉÃ_ŠRïN:hçVÁã	bşwG¯z|µ¯ôÊ¥Æ|İ¥¢üS‹,¹CÚ%Ftt¯©Vş¯2û¢Aj–tn£fƒ/™É·Ëz#œQ¥Ë{&îï–’ifÿG‚7Byï)º„T%Ğ 2<ºÃ	.˜¿£xPú	4Ú{âS’c§ïEÒÌ<VÏ-µŠ¨œÔ1ün:òşRõÖ(0<ÑˆyùÍÜ
ˆ§ôRŞ%|P]‚^­ Íˆ5„X\cbw ±ŒÓ-¯@ŒÇGOô±/šˆ÷·JÁæ¦™ì¿ğÆ'D>Ñb†YËL¯€ikŞúb×Ô@Ä9Æ³Ç¤Ê/¡»+î€	­şxÇNö§u›‘Ë­?ˆ/ı„÷ÌSŠóiSŞâQ<³k©»²ÆføëÏ˜P´¢ûXGWT’Û8QÔwaÄi1Jp†–Ÿ>«aúwJ2pâ'q±jöªâ°Ê <L}Ò¼Í½š-lÏOŸİçp3‰vWÎÔèÇªv“iòÂ•M+¹wìƒSW-àt"`ƒF°âv§›Je²2~Ï•~[™?ÏY$	)ı³¸8ÿlñò_ñµ-½ïgkÉ ‚iIÜZ(y8i`PB˜D]ÈàYEÒUp¤‘f©%ôÒŸfSsJ˜wÈàÌ;ôü§PWÿ'gàx®œŠ#Éau'6;ù'uÛ"ów¢ıaÄí­_}Uç•ğŠ¬DV•H»ÍQzyÏ%Ú¶ Yş ÉÁÕNSoâ%«ü.·5Éè¢Áb‡ãÜ¸í«ß¿ÍÊen¾,×l¯Õaf÷±WœíSŞ¶^¥ù<=ŸˆL(ª·rYàº×/ì0-Üm³2¦ì^jåèâ‚e0D¯áwŞCCW—­;—H(pŠßEª¬¼âò7w ô“ÁRÍ»35›Ğkë}¡Éä±†áÍî½øHõUÊ¡iDÿGù”öö%ïV^h™2qªPlúYŠzü„r:vFñáâ¡ÍLT‡ıÈÈB“5Pf¢¶Bì©=òebÙ=S„jôóæ6èRœÃTW\GŒIV½·z­ØƒwqmSwáh(±uã÷²ÈhÒóE­œ—á”ëF½D´vd^+^È×¹0ıvPÊ~?¤9kI&Ôív‹=šÒQ¿	|®)h!ß‚ ıô··õÿğ¿w€ç'®™7¬µ"vÅ8¥¯îùg£A\Ğdj¼¼™Œ)eQ~µoéº_ï2Ë3’Øta¬ş¨‰)qè‘ïï‘İ£jW6¢’R(—ïº‰ïƒê¡NíŠB¿;àrÑ©JùHXÍ Á~íÍ˜î¨ñ×_†0‘ôë9®ÔG	×d<4RôŠ•´Í¯ıƒ)N®‹o3ĞCULËèıxÅº9øÓÁ}ô$0®|O8]Áj& ¨jƒ?ÙÇ›…ØbNVÓÂ+²?vã!yçB€¶ÅÇñ&ş±¡İĞTş2È·©ò‰wórP„)©ˆ÷É–ÑÄ¦nÁr=Eß&Šs„¤wdi¸wSæ=ÛçÿFÄMV½3Ø	µ	ÌŠ|ÿ˜^[²“D¢ÛÂ	ÌaFu•êDq³.+/»ç%±ã®Ök’ñ aÇ³–_¼Æ?ÓzÏ PŞY”uY!í¸ä²‘å —Ñ¹şáÑF~™$İ…À]ÒÜuZ ^‘}ÑCŠ„Á¼Ÿ±H Îÿ½°ÁuÒÁôªï[Oòµº\LË lßgJÛì(?¶N1BO£+5˜‰Ö¨¦Ó¢H9„ w>;ĞxhÇ]¯ç(5âºtÑ\:ûÍßÊ¡şRºÕäÏá^«A"§3‹èpm'rñ]CÃtñ”çãéwİ‘5Ä€õ‚v¸Æ÷Œİc‰É¼ŸvçşÊJ&íºÑÌ"¸#¹rt¡¨ün¸ ‹[´ÂW: €ügÕ4¥ßš6½C­PúÎí:Øm¡¨a|¹±M•yy8w‚Xg”·ßE*ó FQlì•™…ì±AÔHnëîêl—çr¸Ç&w+zµJ£«véGu«c9œ•3¿	ªtbÛ,àäPó!ì´åãz.+3áC Î\ğ!ú¨²ë6®Ê.†búAA›ĞI¸ˆ~B>èIH³k8r´uë>åÅİ(
HTë ÂÁÎ–>À@);5~Ğ‹\Z|Êîˆ6Æèiw¶ìdã–b-ªˆ¬Gd°È~Éğ%_R?»jiØàÜ2U x³ŒÔbĞ©k³¡&N˜âyÜ—ë²„BR«Í5RÁ…°¾¿ã¸éİğ:Ã àìyšágÓK6Ô]¸üâÌ¿Á.Ezèƒt'q/YH`¹r,¯È¥ubrzß²A'õøPÿÙ:l7mË–qÛö±z|M?uN¡°ò€JsÏ_f¥~²†Åbq+•”¹Ş‡Z!	µİò~–ß‚ó §æòiõâ“»ğ ì•“YüÃÂ‡Có(mùc1fĞƒŞøJ(ï·é€<²í¶‰3œ‚ß> Â`]Ú¼“¢pƒùOİòÅy)É’6s{¸¯Bl|'¬ÖğuÂ0Şüê…Ö%m ¬³ŠÔ–BÁ»nÁu+“O2kÛšvÇİ.ıDS´QI¾w8Ñ ”}Ôéê_ge…jˆbÇÅ>0¯ã#ÿnÊ[é9.&øÇÛÛ¥à·Ó’@œ¥û¹šı—ûÀ²kKÔ7Æ@v• æŠ²Ìıíİœ=–ûÎM‚Ô¥ølüG/¢1'Á±èF.÷OµŠ¢ÚBĞÿîUü4éŞƒŸÊcè8‚å¶
 Q¦¢!Hk İÕ¶k/ö3pÙÁ%êYYî°¼gˆL@ªÙÎ™²‰Wt’ôã62.AïĞ€7ÅÙèén}†ºó‡xÚŒCç
Z³l«•»tËãæÉiÑg½GkĞÛ>:å±áÁWê°HeªçøóõØw¸CÓ\­µĞ†ä_9'5«u$`Ùè»•¥–³µvŒX…p™¤C¬;1B¶ecHbj¸ß+(lYêÓ°ª™°(•Ö˜Ufœ6x¯¸&æÀë'Ûdºg;c×Ğ]· ¸WïOÚ¥$tóãŠ·Jyı‚ã:¦?åô8öQèÿ[ÅPiØf©¢¦Bq€4½û2ĞX»tÛ%şzøâ€O§Ååy7¸¢	Ey?/^åçé$Ñác’á‚Ò–›\ÔÌšÌ]TÙ4µ'©; Ä>¢é£ztºUpE60G1ÆÍ83Ÿ^¬VwR'v‡k	¹š’ÿŠûØü ŸıÏí–aà½1d‡	¯—áŒKdƒ‰cJ`	_$3qE&uœM-fÄ4±"õFpüò1!o-¢—Œra(Òå9ëŒÙAÂ”Y*sÃxÎRÜã"l }{0KN+~ şÚMüè¨Ä’s¥@hgñ¢V'²%¿Ş)]²×ôVª(3j‘=miƒ°+Ö)ìÎãĞ¼ÑRZF
€ÈâÌf4æÃ†rñX=;ƒ«ØØ5qd{nÑ'ÿïV£9Oú3¸%ÈúÒSW½ÈÑ±“g`ùwÓøŞÆEÎÌçmt§?®Ö¿Œ›×{û(í?ÂDÛ_•‰- mOÛ˜ıî]¶W*UÍ°Õéïk@4¤Ç2²­ù"ÖÿQdl…<ù:3Y+®ªı
O!²d3ü¨jº0İLç«0Ñ‘„ÍnÛüM‘>øù‹N%C
K¿†rËÊAªVDjä/#íÀ×±B0jR„7œrÁÚj2Ì)­jF>´	ÆË·ÒÑÖÊFiÊ}Øas;ñ¬k~¢).=;1§±8ï%§LOiyfê8\7ú0nàŒxÔb›.'Òv'e˜ê§iîo$Õàö«œŞB¨be=íDµ+p48—P	ÊJ‚ÎÆÛC<õOË„j4ÇdKFÙéõ³Su"€#æáŞUÖî8Û3RÛ–“P«q˜ïu ,2¯òÕ?#h®ØPüìíğræ]Î@ê%]°!a†y;›ë¾Hè_´}–5Œ_(Q¯FÔ#oš’ 0Ÿôóx{~2bTõˆÛã"kõMùÄoïó6¹OZZèóu…É³#Â+£t*3l¡\Vì¡Ì©/7³u[¯·ñßxºR.tR?Ênˆ©A{€`…>EÖ3µ Zp‡,hz ¨ÏÚU¾ŞBÃ­ŸøÔ§ªÌDñAXI¯e‹~xm~ğÛ9»ôÈJYİôXÛrÁÅ ^3A%æo'JXfÆÇÃ¾@W#ÜjZ´dDO%"^“™K€‘¹~Ò)ÆKyà“b‡-‹“V¾ú`ŸoB¸Ûc„H}ÌO’’ˆ6ëP’¶(›U±ëälŠ>uu&É/à[É¨°‡ğµ1OrFâñuWÚ@/!ŸxP¶rAo‚Ôı´…e%y|â²? İr÷v9c§“ñµ@C¤ğ`Z*ãe	[ˆ§…©7òo­¶¸ÄÁÀñPá{¸ğ)Ç[	’÷¤3RÓÚDiÑŒoÎr[ı²#ÿ,V¸¨Õ†ƒMØÒåĞ[M+VİŞÔ7H8Á×³Øµ4#5ñ°íA¤˜¼àŠ¬àrõ÷ú4øc×’©ôV-ù¢;¤¢ÜĞgÊ<èŒƒTÎahU”ä®W(wîÅAÖ^gÒ„‡v¿ıZ’İêop&–#§ |íF¨ô¼‘s'.ñ¬mŒÄ™äáOï@ ¤©í3T¬=ËpŞCíâv ù–ğİÀ‰mE|$röèòÕ¤–¢l©ãã†’cm÷öb©%à"Ø’W£‡3Å.cŸV&ä:Ø@RrŒà<¤i|M²Ü97“Pš,Ó#E½rñ®At's\µÈpPm˜Ê5?éTÖ&X=è>—]íİ‘4˜¨€ÏO-’Ÿ[PĞGZŸ*ÿ}}[à¾8±!6İ=î®9ò‚8Ôï®@Y<Ğ·àñîúÂİW×äº:|×6FF9ïN‚x«qK2Ú8â¬‘ü˜±MvúÜíïÿ e~€›fÃt+ uC6ºã¢g‡œ…‘ÊPnìÕr>¥‘—ÌcW ò–U[^ÏJ[x)kèQ{g¢T©´äÆ¯0WÛ|¡ÿeÚÔBbëYüóhm‰QcÓšÌ¤aLƒù¦@¤nWáV¡(lÔ#õ¨£ŞnLU$¾2bMwU‰¢9ON>ø¤Sch]I‡1T©Ä¬@ú–ÕàëöA ê{·G
a°’ÇD `Éy¶> €²Tæ“È‹[ëHh°V]ŸSî«îC£ùCŒ²†z#ÏÙo[Û+Ø"?ÍÌ^æ2mò´T¿øëQÀj]İ7‚$æ¯àÓ)š8=qeP£â‘g·É
Pª§G_Ñ„[{×‘L4Ûõ®ÖÓÒED¥¥ĞÜŒ÷R/ŸE¢Y-ò <Nÿnx?<÷À‘~Çï ñàC/rnzkåQÚş«!>#_­ı|«>hÂªºİ[}ŠªZ›ÃEP::”{ô7órÔ©†áNÎª0o5¨ÆÆpOÖî1¬«å	aŞdÃT(@'~ùÖ15!T¡-ı1ÙYÆÒ ùí§©#=ƒ±ÛŠnwiÈLA~¬š­g¼ò"&5nAº	EÎÌ>å$S…Õf€˜›ÔhßyÇÔ›E«‘%$tõÙ(?ú²ME¨X¾f8ÖpKíÛ#şNQôh
(<ºèŞŸhB­ÿUVF<7’S©,-PÜã;¥æ[µf{Yü`@QÄŠ³øÂè†!
+O¥üÛâËå´•“=´şº¥HÒ¶½´zUÔn„zücVd¦o	DÿrsAîç;T‹=¥¤9æşæüü¦›n|é_¼«PçcÕˆo¨Ö›.¥êÓIŞ`ñ‹¼d¾%øà±ô<_lè³ÙµĞ`<ú6ñVYGƒ´us 6·Œ¹„1ò(z¶ºk|€ D3R€oòõã[mé†÷Íß‡ig×p*óL%ÉweÕ†£³>#jLõ	Ái±ÊçkïIÎcHÄ«„…ñøÑ4• ;Ø¤ADşc»¯	Š¨óîô½B(şkÆ^¸òàişØn¬ëàòŸĞÉˆnk«)Ï5áp3ú¯„¢˜`¦Ï#I„„ï³SŸ.m˜=Ôø¼î€y6•üJ‰ÑÜU _Å½ŒÃ¸²%Ù%uĞ†×LjTÜy¡öèa3k=÷Î¦îÓ©yÅ%w|0 Bªœ¬UxLo¶cEQ~ÿšVk.ı…‡3K ùÿÖ¡©w,UÇ4òõ\ÒVë„»‹Mw(ïø„½˜÷î…'sƒéOÑ»m¯ç;äz¯K8A3bDmøÅFœëÊ©¬§Îz‡=ÎÕ¤\‚sryK%ÎĞ¤ÛRËtw¢;å2ŞÀ"0"y/ù¼„î‡YQw”ë»üÊg²Tæ%Ã#}İfÿ\Ì<³¿ëàL++mr¡ĞÜÊ ¹ÊÛw”[.qLw^U±íJCó±pè’'—¡–¤•ş!4»úU9aÂ7 ÅL”¯ÿkjÙ¼ãSLLïµÊl÷{àµìÆPpâƒ×æa¢‡Ûõ¾‘Œ8ÏÏªuş°ffo=Ú˜ü¥S?II0•AH±-óĞ¢óÎBWÊœİ…áîb‘A5| †C{ J
Š9‰-n€ÆÆ»¡ìû1S±bT,¾Bø¬mg¶nXT§|‹Ê§ßİ ‰ä/`[Î1İ_ÉÎ…WşÌÈ[6q(“Úª®ñíşgÌ—MY‡[3ÑÁQ-2x3Õ?|¹6VÀ:iÊ1`j"”J‰§¯WşHş(èï0VUÀ¹Û0
Ñbt«Ö^ÿ6äºyF(aŠÂºç{_zNC
eª8_Õ×İr˜'`ÑØãäCˆ³QÆ¤ªVL§|£@Ëü-“*QE±±!¥L^¢»ôKO].şıŸábĞÏõ_¤`¼‚–w3Ãã}«åŒğı„²Pw‹ îÂaã[ÃR·™¬Ó ÔãÀktwÁù›pêÅ«èµ{fµ‡¹ø½dù)EA@&'Ü‘?6cêBËN° xæ5ÑIú¨˜ĞÎ!ãQwk€€İªQ„¼ãÔÀ•6¦Øã“í¸¯ŸÑüë¦éGüˆ
Îb˜·t>Û\¼Eaè•Ã½æDH¢÷jé½±]!ÕìÒ1øPhïNÑZa‘ ×ävî]ymÿ.c
˜%Š‚i›@Í@j×-³+ÌÊG¿—Ø1©¾î±r¢¹…]‡bÎ‹Gr§r}ñíšŠó¢¤{5AfgnŒÁ³…íÑcÀĞn›®rƒõvŞOª”ÂVÌÀ¢>JgŒW¬uÄv[»Í³‚cQ$üš¶bí	Ï?ª÷QøçL“©éê’T¸ˆÉ¸a¡›—`5He‡É_ä17&šM0–’F)Ä%»k~å®oÇîEI„â¼sÌ‰ æƒåÎv•Ìq|6dÁ¸úï¿‚o²dÈoBÁ­©”%2ª¡w´öëmçgªy*°;82äì	?äµ?a&zÚ=¨#-ŞÌÒ0ĞeAû‡<B’oúFß« ú7ã‰g$Ïæ·]h?Yâÿ9W³q¸µ·»ô½“MÅvqbÕ3.‡âägT¿iú‚²Â–•ô°şHò‚ <ğ¯W¨7ÌPÅhòÔÅ !ø›E/bCÁ/Í«‡BëÖDíl©â¦Ú¡Û®ua()ç’Í7r2ì{gıóôÚ†Æ'È²àÒÊ|öÛTÖD‘fÀQ|hš¦ÃUINvJFkcË¦<n$¾X1JM_²¨|:úñm£áš2<âfê^ü€Æa$«^±ê/\±NO–7íR0oäJnM`´4İ/Û‹¢Éµ»?\ø»]A àzßd6Æ|F È€ œÎ•	±Ägû    YZ