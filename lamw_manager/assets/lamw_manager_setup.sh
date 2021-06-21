#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2464036743"
MD5="42376ec0bcc37bfd7afe690d1c542556"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22940"
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
	echo Date of packaging: Sun Jun 20 23:33:26 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿYY] ¼}•À1Dd]‡Á›PætİDñròåÛ_ÑÓb\ğiŠqá«Õ¾É±İšùuÇ>Óœ>îK^µØ„±J·€FSÖR˜BM{–Ï•7µc²NÜI³VTá‹†uĞáê·„f©}.M<W ‘~>8uÉ¨îÁÕ óT#âea ct×Â	*Db ~åÁU(ŒóoV<Lş¹ëí¬&¾Ã\ÅYe‰	FœfVµ‰ï½LëéfÅøĞZâ»Á,}˜¨¹QØ wCùŒ‡O=ka]vpL1—ÕP5àÚ—è¥HØš°gá%uÍüR˜z®íÄã.õ¸3£µST¿£©¸z!ø+³áutÑ~€Å¢yFœxUÆÜ‰ÓåbOïcwcéİYj¸úÔÃE¡æyğ)”ù¨ÈÓït:(şîGóXu-6¼”áĞ¾óÄù¨¤V;ÊÎ ZmÌøtz'àš%W¸@ælNe£®@‘tºgô¥YQMÿ&MÜo?ú	´B§ÛÏ~/›FÒ¦Ì‚¼¢ÒÓSa4ÅØX-!
qh»@jÖ¯]lŠŒéË/ÎÔ~4LÖ2©ÈAºˆNd¦vº:ÛJM‡R~sÃ%ØÂ"ºTB>ÉÃÅtmú½-Ô¨ß—r­<#^Ú/†Ê/
ÓC¿`—ZÇ“ÖäEx®áø,ıãğ¢ˆùÌİ¯0¿º*6¨Ùà$í]>)èùğÏ\	Ñ}ŠJÏûÜ8‹ø)®’‹†áâæh|Á:2'ö¢Úª^k`Ãklb)Ÿº|ãu×sbeÊ±½‹Ë’šŒµ¿Á`ÈI¤í?^&ú˜jĞã¦9²@†Ä×¾v6³œô–HÇšğz‘Øë›©{šİÆ ıOr‹_”¶ëC,)0 öS«1dï¨1[3ÔI½æS6Â‘³ô¶å¹¥	yû.‹˜¦ü…_üÿñ£˜QÅÑ¡#@ÙG‰ ¤Ú˜ó ×İañ•P!½&Ş8:=Xê¯G¸yê¥"[øë/ËüãÔìHH6N•Ê6*Ô
îÙº¬eç5×GŞÍ™kãí¨âo‡ĞİX¼Av˜3"ƒÑ3¤–Éä?4ãt‘¥tô¥;‡äşlö(g 4.NÉs$ì›u¢×ÿªanó….öQ…”ˆ+]"{³’iâÒÊÅL^­™-ÿ–¸¿¹46O¿¯¦D“ÍY½ôó´/x>vî“‚¨­\¼Ä€6‘#k±µı1öÄ‰¯€èÉ'Wñ±u›£,q®“G?üóEÌ#æ‰"³F8
²Ã?àµ8XÊÛÉÉïÉDàÇji] u‡Õ/#ïÌı|ú¶µq Êÿ6ós­ÃÌãjBöxw+Ê/Ê+Ö3ÊVCy".+£.İĞ{ö;o}º .ËÂH[¡"]ÖŒzåûç~(ØLM/ıÊâÄlw
sºéš*çn^ÀSÄieˆ"Éj'aº×c‡Ô‡ê•ÙNkÅ¿»-¶¨‚Ù¢ş<Ô>a¾[ƒÁ6“rVDÀuÌ9‘¸Å÷4!R÷ıa­70¬Uğ‰¡`S\üÀ¿è8P-iî¨˜ø€Qm³•·„©(;dãjów8­ö”¸œÇ¹ş\öõñœNj¡l²Ærævåë(W(88éy
>B¾ÿê.ÍïE„²5`ş(œÊ )ïê1íÊî³æQ“$
õàæä¸a]!Ò’Ï—€Wf`ˆÒˆ™€ûPlÅÜ:¿·.â¿Ÿ†ÇÔ'7±ÓØiÍı®ŞCÛZäÜ`¸Ho^„Øş_¿*”EVVéñjl°ãdˆB}şF¾NmÚdü3úE¤¡õ”ùÙ“ƒe ğö~|½Zr¿£” ×„‰Ëşú’0Núäˆ 	oÆŞğü4 XêLÚ5Û	;?Õ†Qô$1 kø"p¯Îã•ùx`øˆ+d*ekZ‹£]ë²ŞĞ¥s{ù#)j‰ òöFDüX]ØÁ˜AmšŒ ê}©7 “c&« Uõl¦^ò¼´³l´É«_EíïJIÕ
Å€Í$¦ŒÙ¶ìma©GôFÔ…Æ¾â+	y_§Æœ‚¶ÄtÚ*‹óV+×«-ëD3¶§y"KEÒP‘u¯«båoj=ó¤R=èD.2.¨Ì#œÃ.˜*WœH¡ò íÓGâëÂWº ¨+º¬qñç&Ï- (r!Õ[T‰–{<¡KÙœ%0R“+]°B·Â¹ø¤ç3çHàO`L†ÇQœ_hB T8ÎÇM×İMâ{r½Z |0¬kŸ©ÙÅ¯î«@¸mT¶†Dy5Ï
E^`ûA½QgŞwúÅ`z õS‡TEÊ† ÉW¡EÍ›ÁdM6Ğ¾0k®ø79oï†[‹“	í„rRJ„ıCÍ¨Û:¬ò‘;³ª5Ğ½ÀÆ›*»&ÍÒØœ¶Vk×–ùS¾Îê…,e±×âÈ)#F¾ócvÈ¥]~#O
Wµ!ú·`,Ó“¢üâë=ÈU¢:WË©HÖ^†=<…«×uDû€w%|’f†=ûÉx)NF2¼ÜhñÚÉ§æ½[QøLÑÙ}ñö»«NQsğÊ:ÓIÕei*ÊbçÿÒ®¹¥|±t$›¨¯_ĞÇ’0û‚MÛ–ğaˆ#1ü4ÆÊõŒvèå(Û‚eÕ.F7ïu›2`º!ÓëJ¢á@ÀŞÒoßã]ŸdÔs¢”¾ÿp+Î&c:«ÜÒzŒypT×ØÔcqı|[n½[ŸîHaèñ*å@{œ1I¦['›Z•]x¸M™£Â‚J»y®ß¸Án†YCW'EÊ·Z	üİÖq‘ñ…‹óàÊ‰ÜÙàù'§ˆ¤ák+ğîÒ_'^tªôã#è¨äWk
kí˜ÀÅWhùWw4uÒY«5ËÓ-ÂS›Äô"Wx~bıVNµ^4T)†`”štG‰KŒ¢¯ÒªQCêàï‘şÕ´54ŒçRN8àwšŠx(Ê°Ü‚¶õ-ªxƒF»f7Y*äqÃ‚»mµ5ôôÑ&®ìµ+ÓÕN!Â4¥c¢Ú°j}Õ€f‰;ªã¶%+äÛW$â¦äƒğ»L%t¾AØò%la|øs®A;©±5<åŠÈ
QiÔ‘ïmc97Õˆ;—¹pÔç)¯VåÏ’EQ€€tn´ÿKû¸¤{6‡†ôpîr½ÚSZ¼lñW™H»j¹A!cÁ»ˆA ß©˜tÅu¬À‹^ Ö3gmòş	Ûùlb/d¨¿›6/1l?&Ëÿ€°ªç¸ÀıÀ¹ ãÚáwlÛäLÒ5^XZLìqöê‚|{Õ¨¨¿Õ÷j$X=úBjè`	àK‚*„ŸB–SZ^7C—•öz<,yælJQ½É¡üÚÆNz×	š¼O“Ã¯±~úeİTN¦ßEëÿé‘ærÑ†:ú™&eÙïuá ¥ûÌÎ×Rú4(î+¦4Y½o¬V3†è¾#Ú‰ˆvˆ6‹<€Æ_÷èGŸä’Lÿ«•ØdÍìI\Ä£bà€rsA)3èEÌi·ì²ş„…F4¼Ò{Dìwh°q¸QâSØYøS—ŞìÆp=êMRû-‹ê¶ôÔ±ş(Í¸oešP™Àå¿Ú;¥Š ×âœÄ]èp^¦Àz%¨äÂİûËeå7­ ÈN\~»m#ìü‹h¦Šuõ¶“·¾ZÚEfûrjWÊ-í­#9 ,€O°4’Û{?àÁêÚZ®aòRc¿»ÌÛ9²¼·úvŠlÅ¸‰_Æ\8ª.d4‘Hø©&hv.~é`)Wß;WÊÍ‚%6¡³–VÁ‚“ıIÊW¶ìYŸûİş Id:Xnw}ñV‡¨5>ş¼{kztZÿ¾Í!sgİü®
ÙM•#‚ÕÆAqzNl¼œ+7‘+²­ñõ†-ßCã»——˜õ¾77Ê®ÕQ:škìáB‚1	Ù3|?™g¤ŒÔªZWnÍ :HŸÅŠ ïX¦ÀM´k‡²Ü2—şş/¹¡ÔMy=ìr…ğçLŠ£!÷¾µô(‡‹Öz;mÖ÷Ÿ*ú+|«CÅs=xLkù—°ˆïƒğ†Ÿ‚‡ ,ıö÷!ÛÀn¿A4È6ó‚eİÈş»m®­À˜ ‡ZSZ¢ë[àÃ‡ÅÕÍšYSÇ}V@¥Ş ½ İ	†t“”Ğkå‚¹S@J	¢ÃeJPzAC†Këµ]D?®[™Ğİpwç¨T,ÛÌ¶ÔBXÑ 8Å—ú³¿2¶v8Ÿ"¾ÑV„trÜI•«9ØtROíî åáiÁé#x5_³‚ë°ö| ¡AR9S1)`›ßæ-)á©Ö@‹U¿¶„\/`ÙIâÇã§û^Š§ç=ÌöÍpÌ+?!ÏĞX^“ô2”/«@¸‰p"#ÄC=ïVã¦oWMÎ/XƒdÕŞCD‡áÙË6ïWCô¦ğ?²MËá%½lŠûİLÿÔÚ”IÇeNkĞÁ VOŞzDÀÈámÁ3‚D•Øy§r9ùĞâ´ÕoÎÆâÔú«,mœ×êA<Æòc‹Ğ»ÀŸTş5ÿyö!-©8¿€Ôl/î’àıa¤¸Vi ×ğUJht}/±”pºøÍ?á¶,a[8ıÙ©ºm ?rw“@7Ü@EU\£ğ¥êÚ½O+*ï|Áá~b®ˆ]Èè—Ò¼p]d¾Ú*Œë"³˜›wÕ¼](Ûóo¯ˆX…ÓA6E$¼C|Ğùzi1Væå½Eõ“éò0 ­-‹Zh l÷¦lˆ'w¹ÕYñb4è¸ßP‡õ‚e3ò€—³„z¸hE:­<ò‹È%q¸Zˆ“°^ ‡í3'x4·æ—^…Cü•¹¬‚6,Ê÷Y{•Ó‰øFİ	’—4^FªÕ’?®xzÚ#¤}ôğLwAõD¯ÑMø¶ÿ$³õÄŞ	t$ó5ÕMŒØ?yğ[r
²\L8Úğº
…[8¸U¤WávÃVaÇEdÄ(™şÜ`N/‰Š8YqÊÅ¤eş Û%çJ)Í¢Åu¾ó@P2»ä’‚Ñ;<1Î>G‹Àõh ÛK°œÚY<Í¹“k$ØLœèÜjsÍW²Íh,¦µùgÓ´Œ~ê‰(ıæîÎ^5é~®jÇ„P³âîƒ®Ô—­ÔQ¶„=é-Ç+ï\Ÿ3#‹« >âËœg¨AÕ¡oîËGäŠe+Ì—¨ĞÚìÈÀoô]põ¹®˜ ‰…?ÕúÎË|á®3L°rkG›šøÜÖ¤ÁÑà”_…è5ˆè+m&¹ÛĞÌ D .¡òI‰H§!X¥ŸJíüZé³Ç`6D'ê“Ö`<ú,‡J²%oß<L8#S°¹Ùú³~”rEÓ] „è'êJw"SšàhjÁ2½ÒÑ‰¼
CeY¢'Ø“.€Àâ¿qâ0ûDë¦ûÑo¬ç}Fpã)Ê·×w×Ìù´ˆåz'Ûşÿçò–qFdVWœo>ìlY
¤îíOd8'Î_{2åûA$es°ŒÆâ5ÖÑõËt¥½Éü•ú«ß–7±9híßøí€¸Ë;%vvNqz %2l%<–>[`L¦É‡j¸¬°ìp—êA›·%àÉŸ¹ËOÖµÓâ²S0òÅ~€Üìóâ‹õèm£«ÚÜßÃ‘aYĞnß{±©X×ó’²0ˆ¼Òz%£(´5‰H3Äù bÔ†%O&ûX˜Ê#nÕSõc7ËrÁ÷Ñkîx#²d¥B,±Uwê*ñÙ[•ë‰DV(ÇQ°ãEg@!Q!¸(·Ê€ß9/^ØÂZo’xÊ:ğÿİmáŠy½TÑxŠŒëÖ:?ÛóF¢ƒ^–ˆÉKøä®ËÅ¶åÔmoZ'kÊ]ı©ÛzaxÈAÍá5Öšr‹ùÊÑAğOßb¤+Ù5é~<ÜìSd^}8B5¯5#ŒJÇ8ÕhÍ!T¯Ó	*á0',L‰³QÈb×ĞíaÆòûÇ]Ëú½x¡öqÉ€)ôÈÚ(PÔ‹Dn‹
÷k|à¬½´ƒ	è^¨–eG|:Û÷êÂHŒøaêÖ>Fƒ{[²ÙÎH«É´Ôúh´,\a´mÃKZÃ×›œåèLg§	æ}á¨mKŞÙ÷Ü)ß×Âõ~ş;æÆ5ë(Ãüâæ\áwñhâÎ¡!Şad' y”’8æbna”ÙK{ü Î"ÿ®³_Ğ‡Q2»º‰/uË7(¾%â~1Å…èjiÛØ•P»ôÕÿ²š<­”ªÖÕæó40ŠŠ`$+¹ÙôRy¬GÌJÈvŞÕ.İUäY$cÔY
Ò ÆmKœ|ÖlİUı,àÃâì,—½ş‚à¼W£
 ?Éw…‹c°ıŠÏPÂOÃÁdñ#ş’ÿZôK¹yåéíLÙ.ğ¤naáEÔäƒ¤DY\7ıİB)(ˆ ¹
 ëº¿£²æ$Íÿ]›Ë”Ãü½rAÇY†jªö¼P¯'‘£=P GÎé ›©‹œ÷ûø·Ûa6ò%îËjÍO#Î™Ö!EÉÒhd³ĞÍó—%’*Vï;†Î…b‡xÊ¨òÜËËB‰_[»p†°³3K:³˜ºW)î×gò ğµL}Ú^Z[ûû–úû“ø	*x3RPïuöV+Õiá©|8ê}VAÌ0Wù¿@ÄM&³ô€uïc"–0Ù˜ëœ§˜`}±Ë[W‘ âTş5,a(¯ß+Î‰|Yo8ĞÁ6ó×RLÑ‹×É!şĞÿU¥ş–?vJhÛ+jÇ*RèÆ{ÍÅn<şÍ"(µ iÿîÁÚ€t"š
ÔWşÁ×	=ÅdŠ¶<Ğ3°íò¢ÊîÜ¢¯¦9€Ãíj"¡İ¡¬{İ·ÿ&e]7Cj*€sÃÜ`Lhé³é¢Ü…‡,{$Dl¥9eñÆ äFqŞ(Éğ;Ü‰¹øa\c#aö‹Èà4''nQ„³CìGì?³ß™À¨÷„@(ÕöòUxõÜX—úÁÅ» ›[ñ:ÀÔ5Å²\24Ióm¶Å)¹O 8¿ğ«í¢ô×Ò`wóuAŞ8âX‚¥»ØSÖ^¸šürğªv	ŠK´ğ%J	#eTqå«*õ¯c:V8i»2¾>~İ-ª -t„=¾šÚÂ!À%‘–: ğƒšÃ·¸z_¥Âı”ÜÚC] È±MŠ Sô¶º©˜å¹ãÌ›Ç¥ùèÕ­.”zíbxh"¿Z“uTP/Œ:D;Ìnc§ªâŸ›±Ä“À&UN¿óV:'¥ğÌäÜfìş¬Ì0
Ÿ‹ó~-g/ÑÒn\«i]Qr8ğ,ïf/óæÓˆP‹½*pËIöÜÂÿSkÇ¯L2õ§LèrêæÔá`1¾ÆC´ø#üdg,!‘í¨’Š^†å$I—(i‰G6¨ìPÕÉ4JMUR¥èÉ."‹`ÙIÍ 3›z’bïÀÅ-¨>­Á7‹ÿ0:âû©|©Š=ç¼JK… ¤w±ùûÿPéY‰„|¹Ï	ÓˆùeP”x<~g…V@øb”„t—ŞĞË?ö=<«é5é~z«½ë¯Ü9Ôx¿‹½‡ŒÖ ™³zEyÜœ}ÅäêßË)ròáY€Şplz„d¼ïöO}˜|÷¯p›v>ÇN‰ÖOî–¦ñõkåÌjF‚­°KƒŞñÇªğTe„{pûläóáOúÇvÒ»èØó#*õQ{¬iƒø÷™ˆ£{’Ûj`çx„”í*ª¬Mt¯Z­^vÅD*¸`·Z´p7¯`,n?Ò6çŠPK""ŒŸœ©	ÁYJ¢†2š¨§ôÄ«.p‹³Œ‰^:C«ÿÅd,ªõÏä¢¤Ş@¬©Îõ$À±kıÇCœÛ°•ş*­¾Õ·iÙ(W|Å¿NDš’&dOÌæ¾Ê;0lM¥¨Ë†BWÂîOÈ§&åd%Ì?Tÿ-ŞßŠóT·ãAÛvÜ+QĞ	?°w{P?gÕº_šlšFôe™erQ3ˆƒêïW}¹q¤."^÷ÛĞrFœ_˜ŒÖ ôæü	ŸÍäÖcÚà\[÷bZx>†[!›H™˜ÎcOŠ°Pnİ­)-ó«¼1güìøû„aE VÙÛPk:¢¦Ÿ!şooG¦ßKÕ†›á€GUÃ;4C—K£x¹<+
è‡ÔØõ§Û‚ñ½ ƒAC¬1HåÀºqqèÙŠÙ~—÷‹ ØõV*ò6u~r#ÆØFŠ‹ÇÜ«qE/I`ê½å4fı²¹ü‡@m‹úÑôÅEäçq'}»ERÜŠy2ÔõOçÔ¨îŞoâ=çæœ[Áo™SÄ#9~^ğˆNTĞF8‹ypÏ<ñ
ì#4x¤“²ûªM^HìÔ^ç‹ĞrÆÙZ÷ÎŞ¹5"“·úgûƒ|´œ¯DM$WgöË[—- Ğóÿœ$ş>%œx  4Ù~•¶FÃø Ä_SùA‡º'zµ')ynÑ„t±l…l²å‡2ZHO¤Sy&™JgìÎ—y;˜ÓcHo9/.ñ›N2†ò'œª‰¢ÂÕ0›	ø—a¤ıRcœ¼7„jéhé‹êh}™Fî
Š˜Õt,g¸èuæü[*C­:µ†ÕŸøsù­gQ¯w˜Ì{Wâ–¢¸Ú=ù4hş+>c0êƒ!ŞÈºo8)çãĞÖ05zá&;l…I’ÆÑ:*÷§±6–Otöy¼³7)ç–ÇÁUä¶7<¹Ä@Ç4œˆu'Ğ@¬mæuÆz<ÓÃº¬³OÙ#¢Ñ)YE0˜c¡¯~ônk¸)t&º_ÿ+§©”Ø`‰j 1¥P'F—Ï²ÅxhÿU«•ªåã^ê}²;Á{ÄÆ¬7êw™&©á‹e…úJ7!Ò¼	mòşkÉè#@yŞMê¼#+c›dSõ8^bWËZ-òÃwÇ+œ&œ§Êí¿¥¤‰oNu”â=kÌi£¯´Cƒ¸Öã…*p#ÿÉ â çÂ/æ7	Ì–™ø-@Cj¨y¤Òr­@‹Ä¨H_u5ğÓÈñË^XEÌPåQÄœŠdç€k/1T’@'÷àe"´‡úE@'aó_ĞD ©¼˜Ó4—cÃU>˜³é1²ˆZ„ˆ[èÕ’ûx›ğ5n#äV;Ì]SG_Ppìånlî5ºÔ¯ôSrnÜY#_¿OéŠUÃ¶h²r˜ÇEùâ¢ÜSZá=½%*>ÏÊ*{İIÅÈqZ©dü:#îAâ¦Àz ƒÎ“3(OccBŸ£}¯G”p¦Xií'”X·?ÍJÀŸı[Í’#B)ùÑû¶x~ùEBŠAÌÎ­? '£šåQ`Oë¢óñ÷ª´—J>¯¥nG 7f h(Å§æ~1i¿:‚vÃĞb º«[J?|’ƒ3È@#“$ø
kâ~__ÍÆ) —ØSKcbûÿp©¨XŞîFæ.Ş„îo.c¢À¡ê/vÄ¯b”øë%R×‡÷]\­?T\€°ş¯Féık;F—íNÆá-b°øf8Šš±ÜÔ4x@Á¹ëV£ˆ>ZÑ^fªh²ÂÏ|°l¡²-+¶`ïuèt€]q¬O24’qQÆT–ÜµJc¼g%Iˆ
C©¹4©–xZ4å rq&=ïóiÔyH»‡ìfÊ¹u[¾;
àËUKÖò‰DtIÒãçR&’³1ÖÆ0ò¬-ìâÆJzw~a€=y7ÑALúâš—Î**{ah½£€‚6–ÉÂãçÜÏ*d'¸ŸTE¾HKXuÄFxh¨‚Y 7,¤ J¤­pí°ìt­³T<*têĞzåÖš	êjØKô}“ñÏ.½ò¯ZjµGÿH®‚¯]ÁXš.XAY„KnUÜrŒ®®Â–Í§É`VLúô¼ÿTP§şÙÂçH‹gUàpëÄ]Ì@¼¢‘Šü¢sMsÇX-rìn<˜´^5ÑêÉÒ·$ri}: ÷ú5CRj	Ú@>î8Äw	Ìu~V¿'‚´¦ìõàYŸº?FKôgS¢¼Ÿ<Ì-Ôw4`“teEôñ¹“äì’<¼]±XÃNÌK
¨[cs§RáñŞ–ø+ğ30¬l¬'ªÃoxÇpñÊ„*1œqõG6D
î ‚ÚÛÿ»lÍ»òìÉš?—v’WÀÄÁ™ˆœÚÏ¿Q11ã9ÛGÈÒ¾Û…Ğ,K†ë‚–<}ã;ÜêXI›¯Şªß›¼Œ=bèóMpüVvv\urQ<Ø¡Œ®¡ĞK)„ãkx7‘+ ß8cCùnú¢oÃ18yêÀŸÇÜÒ=CSP<‚Ã­Ä½[/[†<uuL¦Ã‡]ùë6S½TX„¼2·\±Æh© ²™>Ïµ%äz(@ªºõ–ll\êf2€üşO%œ™®ñr–]È
Ÿ^î2…Aa=:ÛË±(Ôƒ>’}›3…Qp%-ÅÀ%‡…jìv+c¢ ƒ½„ûÂIÂPèÊ¢±ŞÉ»ÔüĞşor&¤¥5µ5&3ôòzTU4üÅ´*5¾¦€œfŸ%(‰ª€¼RÂÇ…öø¯ú'©;ÏÉû”Ùgòür¶ß¶›*‹ô‡ïĞ¹ú ÿajN¡¾šW“¦Š
ƒ‚ÁÀj1á÷™óKéB¨>hÏâ:;K,bCD5Á2õG® ">T$îÈÁ‹³ÉÙ¢zÒÍš€©×Ÿ7'À&ë˜*`|‹oD‰ÜÆ½…¦¯XŠœX¡g»šêÃ9$K¥Ñù$½3šg79Œ4£K1ÊpmtdğË°$aÿŒİşA£øäÏ÷àÓ­kx^Oºğóí'ÄÑ»ïÂuÆî+”ÍdÄÚ8õŒ¬ŠáO
6>ïJ•"88üÕFÎ-í`s+GrmÖ–„g…åì’ğnôx5ğ¯ôëÈo¤êƒTî&%´ıˆ®›«~¼Éi> 1lÍYP+8açy|ƒÌ¹Ûb²Ÿ-XC‰Éòá×§Š”É!’K˜ŞÙGjèá'(ÛeAK¬“SårÙ¨8öª÷r´8[a‘8køñîD_OEj.}|d¼á°]7$Âé"ò_ãÓÜ>ï®Óª$Ï£“$œ¬+D›õqÜßŞò§•3à¯E0^ Õ—kuÜ*¹úy gnÚ€ÑmÃ² JCI±£çH€×mã¹¡g4M¾*}‰'­3/UeW<iµ1:ŒtGŒY],fÏP5Œ!=Í­hÑqvõºŞÛùÜÎ›_ş÷|ÖÀó»P 0GXÈ©şƒ´œZş)j›ªšÂ>²YŸ@V÷%Wã`BF‘Zõ=°Än¼Å M8¤/ùT6ıSÃK~–uF[ÉˆÓÁèæ4u¤_Ü]&¥¢ÉCnÏÙ›qã4'âª >Ì†‰QéçG³öhèaÂüÒ›í[ Ş%VÕO‡—‰ˆƒcJÊt“§G¼­Vi†_|P
o_üùI¬Y5
½ÇÅúæÍwG¨zV^µÏª®å®E#0~w_øàIJ^1B]SvÊG²ß-ĞR[yŸ>¶Â=X	‹Ãñ?€7m]Úw¶íşâ—úÓv‹—…W¼ŠNª½Î9­€ "èŒ20óX_»2-Tf•z{dŒVĞ”Q–g/£·Ö7«S?rÇà¢i}—u«Ün·ØÊÈq9—ê?"4í3ğLCäˆAÜZFÓŒØcµ8ãd‰²*/v™ëI/ZzcZ!/ÃIPÙèeò^Ûò†M©®¡¡NÑÆô[-Q·ùF–ÜÊÌıYdk”=aŞói=1dçŞØWpsÄ?/Ô•èØÏK6aàY0a±I}…önñº½}æc”½·‚Ë‰™/õd´.IBk†J#†6
G½ŠnÅlb­ñ½İâî’a&ß\\¡DÆ`Íëõ¦uİ‚Ş
ŒG{¦Bé¶,k£Ÿ!ÆáJàUh‰êSL»H¡oÀ»äôuTŒPCsÈwL_¦’©y` %xØ™ÄS^I¨ò„¦¶
Ÿø.]:ñ vÚÂ×…ø‡0äé“Rô%Lh
j ^¬@OÇu;WËClË;M`_s‰â­ƒ~î€{:y$»û”RÁ`àrèğÇl·`§ûÓù ’²Ó¥³q{Hò¶Îßzc¦¬®jÅŞo¶ô»?ŸòÚCäÏ3ª0ÔŞ>ˆS	]:§íÏÎö¹¤vWˆh·T)Ñ	®Œ Ù[k:{äÛ!©vHi „#{ú{ l·	”×Ÿ–/®†Ù•nÜ^cÄ½÷xOß?Y	-‰œ.y.˜¶€Naâ‹)^—
©X™Â‚C/Ü†ô*E„û”{4›Ş1ÊÓÆÃ’ï‹¼#M>#‰©à3#P¯y™{¼İ4¡&¿ZŸûÕk³Ó•`Ş•È›®ì©°ıe6’0sÙb'eì¢¿.PØi-‰.-‘Iû–QyD‡_ˆ5{)¢›n ~Ñ[¯ÿ«ÕR7(ŸAE°ù­ê¡iéüÁÉFœşhŠPKı`ÛAı¾d…¯_¹—<u´åJ9=øõÍ?i¿ŒÂd´ŞÒû¦‘ÿ’:ªôÆ›°‚Lïƒ{
Â¦ãÅêiákRÊe6$VÃ>“òG_œÎA­?µé;$…)ñğ`=à8^l·:®ub±ß%ƒ¼…ÇàbÜÙ¡kuy€ıT=ƒÎ£îy£DGõHd-İ~è&™ı¤ëí¯¦Ï‚‡p`9 µù¡™iŒí¦õôŠk }ƒOŸéŠªrÛı®¸©,+‚¦	C×'Uj-_¡G$T]Òy3áv«Ù 
œ†_¤4­¶é»¾G¸.˜±MkNŸÙÍ>nœ6Â›B‘Ú¹põåÓÂ].˜µı[e×uiNÏÎä#I¿4[lI²8Í²ğ6™òáftrJ8Ğùôyeæë+›<âQ£8'	„Ï4b	¬Iá´@ƒ¦h¾ë\"1ûF²8ÛçËÀlÄºh—@ÀÊ^Z³.Ÿ]?Šãhàb’|Hªd—¾Ô_¶3È-‘Nò£éŸÿFÎ˜TL4Õı4>.¬wğÿ°CƒB^Éâ'-Ì	N.òŞÈ¤üj‚êö a`êÊš¼N¿©”JCÅûı:Ål°5Èû¹óf¤œKî¼‚G¼-; sPQx²š‚.Û3,'Ä
Š>ƒøAí—í5Ş9%¹¼Ve#úUãÏÛš¦Ö.ÛÅµRMƒÅ~,ç´»ıBÛa®¬ô“·3İ`á^•äWİ§ î±«§Ä–9À|û£Ôjd~ÂPßiŒ uz¸…îènkyY~n§Ç/î›ìZ6.Î~¤«¿)ïº±5Êá˜eié6TFú&sèC`Ÿ8@™Ãx>ÒİX’èW: µkşã}ö, á–½ebÌût`ÎQ˜ßö7–ÕÑ¾¨SiyÚpÓíæ?lo¨Iv6ç±°¬G÷E×_vl­ˆ5~úğáxË†€ŒfÛ¸TR$º¥ºxlï®™—ĞJœOz(ôM*—§Üd××æf¬&ãÉSüMİÒ)ÁØ:ë û¾ pd¾¹]i3Ì9/ùDÙîÎ¤”ú°Ï^”³íÜo/–†`bq¼šqÈk•YAnîjÄ5ï5dŸÓÛs¾yp)ú/µÊŸ=Îá Ú‹q	›`¯T^Ú^ä÷	)ÒşÂı‰tœm÷_0ñg>?&Ó·DŸÆPÒ£|w+tÅ	İ¢yùÈK[L|Ry½x§¶%êK<¨E[Û°p6é£ÏÍáïòG8ü—ÇÎßH(î˜šíçaĞ§§uU=Ä»›µº.Ã`´rT³:ÌQ…(›Ü*D=ÆW0B¯a"wØŸF#­=’©ÕQ n”êØ7NñUïyïûCHY¢JïànA,›U’æö$–õü˜’Ò‘”ºsãq$³\Èü6a)W_XóJFMÁËw¯şt²ÓcP-HÌò&ABÛøÜÁ¤˜Ğ‰›¦HR¡KÜÌŸ
Ğ³†*³DV³Ã—>`)w“ÛaÏè×­íì´F‹qêólı<BÀeœ¥m
E÷›š"ë(Iâ6—yü³K‹iÛÓjB-YDsƒ€VSWßòŸ¼õ uü_\³QÒ×;ióÌéqmF½”‹©ÖÆGìÃ‚\ªçÔè‚9àSHªº­@ëIçN¼D:¯>™Ñš'~.d¸ÙğÅS¸7Êpn¤1şbUYô¡ÅxöğÌM`@ÈÖ¿—ØnÔ ³	XÓ
ækş²²òeÜüñãÎöÎÄ«UCvÍ‘wP‰'0 ê ~<`EèÇ`fI¯³õ‡ P=‚w¾©¿5fíf¥õ@…ù+:’^“W<ìê$cõº%åÎNaû.²9OßÒDYÃÕB ¥T°ª¼¹ZŞ	Š£´—ôÖœ‚Eù¨9S›áåèÏÃ°ÀHN}âWHº5ZÀÃIÌ£_€A¥*t~”	úHSácB|@ Ÿ3S5~rí	¿ô,*şç®UNÓZ.[|™MÂ}rdfr¤¦şûµ)eviÉ¹:!%Y'áÒN¹^õpï“Å½¯ÈaL şê©¸AUşøïÎ-ßA"Ş¬Rt_‡z…™´Ê¾×#YŒÆ‹
n8y†šÂößÿû_‡P<ºrõ(“ıµqÖ¾ºî=Óİ ~ó­¨8Ò¡Ëe.K'6tË.`¾«î¹FXú'ìàK<n¤œâKªke6êíO³­á6Ü§;°êí´JgÜüVÎ7HÿÙ0tóŠQõ "–?×ñŸ[«¿¦¬Äàøp¢ª…jÙ«KãğÇé®ôÜ$ô¨Df{ÍtÙf÷Ó¡îe<×Š,Æº¾GQLUDˆVÚ²ì›Şİ_ÜaU/?N×=dôì‡ k'ªn¡èíOßÂ)ÃÊC`÷Ú%w«+8?è—^âü¶¢†	×–ä1Ï”­À™Û…U¦ëŠÂÉb»:gÛ(ÊzDEüĞ Ûíƒ' K“~§ÕeõÍ™òÅÇ ãËadïhşyäà\š|»m33˜bˆ \é†²Ï„²Ø®[ka/S€xg§Ä%®Ø¨Iõöæ¢ÎS°»ƒ«è»“aĞŸ¢yd§…ÛJÎ`€Õ‰j6‰Ä˜{æÃÍEŒEòù¿5OS}Gô©:Sy6’•Ó$UÁç4õË5Â‰’õT˜h%š#ö½1À³n
òÙdTöõƒ¿!ûŞYÔˆŒ½_Xµ §v9‹íiPUCø\«s0‘«DŸñ?™g¸s­m..•ªÃÓKS­:¶=ßFÎÀ8$˜ËÎ/¬BîUTéß.<H´çm’B[ÒG¤Î}ò!4v	§kZ"ÚìËğ³us÷Á/ñ“’â	¤²ôÚhª$'ÜIL3Âóy"EÂ©2ÙÁˆÎ¦ÌbµºWu•8’—x©“ğG'¿JÊ¸(rÎïÊUöèFç{uÎ’fÏÃ
~†H½v.ó=œ‹ºâ˜Uô¼›ı=éù½Dy’¨Å]I¬É&­ÒAóMÖ´ˆa¸6O_—)ÿ“rå¢ºÆsZŞ¿¹‰³€òb6_yĞûs#c§Ì•L¥’º?·ïIZ6ûÂ9GAcÁ†ú?Qõ„:¶tn;­Fµ£0g*°=4fPc`”gi™ô‚‘8êíuÃ­šŸùÊxã¥zªÁ±é¬Kqo;n5=TÌBâ} š×ôHˆKã¯ãb¦%»íÉc İ¿õ-²e·ø©`Vİ‡³­³Bx¤^©ƒÍ%v±KÙÅÙ?,
u…TbŞºIb·\ÑŠã”à¯Ó·#³FOç‚“‹C#»%¹ä+…î&[	?èÆğµ}ÑQšÉ³«s9í˜3TIıÑ@êŸ´håçolÚ
¼<ÉÈ Æ$ÉH‚‘ì3ĞólØ¾\4–-•b9N²a\õÍŠ1EÙ½œå|{óîJ/Ÿ^î†1_å©¬N„?}!ªŞ¦+ê* Æ¸³³cH£©şsåU9ÕI‹®8¿P-Z¨ñ–±k9îtÉfEGùdTx`óø2š
î„ı$è’=\+É5³àvğyòB„o¾CíB¤x(Y «Bdq{mi¶ :ÅÊ¼U<é®÷ìÙÁsít%Ql<™§›Ş™Æ$¾XkÚØˆ#§«›Kˆ\ËœÔzËô=jJHz‘üıü{aCŠd¾¾ôôkF9H7+â¨‚0ë­zs‘'M9‚tø#lŒä?M™éZè*g[§ÕUì2D‘l¼»z"°ÀG³7ónßJ/tÖîÂ¡B©Ùv
 BA·LZê«65C6A'Ç¾–.°­¾£ÖMŸĞÑzó:@F^øÖ‡µr	mÚu¿™¾‚y™z ”›h(‹²‹n8õèÀûj ­hÜA$¿Ä›ñbß±*z4myC„’?6Ø%PCôr¥ÄR‡²ÆûÛ#Ñÿ;'ë2îu´NN¹rNømğK%?ÀÓ¶„iXUEŒ‰ø’2§J*(<‘….o0,Td4I=Ô-¨A“ıŞ>êêëdyË5QVŞr),ÖÈóÙi’² 9H%Ömñß*´®:øYà§—RUã·ÙÓËŠâ`ÅËÑËl#öT%$lk¢GãŸ² „6R°G%b9âÍ_Ç?Ë#\Z¢f-/£+¾ÑêE™…aŞ;ËBF¾ñkrA?"Ü(!m>OÍ0;vÒ4¤àìL§¨ÖŠ{óÃÔ!a*Ìã¤ÉgÜ×m‡u\ÈfêÑº[TÙY2ÇtX°JùTäj¨%óàOüYVN$¥nÃ±¿MZÙèœÿX<ï˜N$X=`@}	AóÏŸ«ŠÁ™Ä4DÍ¶Rà´İQNM8'¦o?0cÜPU· QåÒ_$¶÷ •·Í>[ßÉK›yi˜½3†ğ¥&¡º=‡á6dÑïß½iïkxÎîûÓ	:%et4øş*ñÏ¼Ç¬¥Â»ŞZÅ?#Cv+šcô’hüøŸâD2%t@l5zŒx¿Lè²"„´åàş«Sü&/ \2ÓU>áå]1².4dĞ”šóşQÅ¬Áyê-$•=²å{4’ª9ÂFF]†
­hÌ9w­Ãaˆ&XªQÉZgĞ%íeö$cĞfqºŠàiy4›ö,ÂÉÍ#7­ÙQİg~¤»´2Àmö„‘? ªùLÆ/ğ«¢"ÓËµ
6ğÊ>(Cßµ·²ßÑk@IÙ"m;ï$„BşB5K JH×º‘TäÄ“¤c‡œ“£ƒYê`ĞV…*}÷Ù-Ö‡s8†ª²¬Şaú/ŸĞSªUøşƒÚí²E€š6_¯b5£sÊ£ ]æ9²·Jı`vÁíèÿCW`Dúı}G#£V–òÓzû`=Ü9º®uy¤á¶ô_•áWÁEá7(ùdÉ¸Àƒ¼M^g'øîÑ5í>S`2âÆtˆb¼<#É1oØsğïU<Š¬íé5G¾Rùï÷ğœF÷«ĞÀ“Èæ¬«dÑ—q$é	ìâ[ÇÑ¶sÒy'`fÜIÂ8½rt=æä™;ÖåWÜöÏ?HUŞ°¡<=r+©häº1,şÎ™Ù/9X=“íòRÓ¥U=°¢ètìİßGëD:ÈUåÎ}zÎ<¾Öz¥Bœ)ŸË‡¡ü)çf:­Ãÿj¨†³Dè\ã/Ù¹e{UfhI»@ß£Ù:øı.¿Cºƒd?¸¦x»QxJv»#ÚàGÏª.€cÎ©Ô ¬M¾©¿ô\,µt±ıLJ{¥„›-bí{ı-?Üîöš(gİˆ•ä]ØÁ E„Ä4us¯0;d‡&	2½s1L30GÊˆŠ"¨.måùà×çjâÃk!rcX‘G€m9X]Ò~‹İTTÒñNóñ÷éKÁ»İ»RbûCªGÑ’(tøAï5Ö7Á^I¬¸y>})rP2†6¹áä}¥ôXí©y7¯aÊı$oßGUWt¶‘¶å2ôÛWÌ'ºÖî^ÙÖêJäÜ¨A((Òaq„œ}J	Ë<${‹	Y•šÑ1Ã9Õ Ä1|Êº”w@Ë›AÉ“HŠëÁ4%“Ñ€~v:½cæmŠ<¥)&²om¯skğı>œ_\Y-åç.¨Êã}äò¤–‘î=ºvõg)k”Ò7!P},‚£Âr–ºJw2×–ëç"€|óıhúWò´ë™´7/°'[°£ß™è¡ÛkFÜÆÁ*b*´«Aışjï‹…MSÙ~ıÑp”t*ã·>ŞÕ‘İ¬a©	–V¾ç@åÁô,én„.(xœlpybYAn¦ÈM‹äbĞñ‡t­ML¦~áBUèºß»€Òõİ<’SùC½äo$gš;æ%V¼m§°%s“ÌˆÚïHú››ãI®¸¨>ªõpŠíú€o&ûŒú@,l¾úÿeÓğL
¥±£÷ˆd|a9Õİ†ÛM*A–( Ó
/×8¸ª±ùÃ#ÜÙ•Ê:ˆ»»À2ÊÓ¹¸íªM©àéõ¹¯h,³cİó¥ï¾_½d¬ñö<¥êŒX±„]…#PŒ:ÊJ%¸èÙnûø¡{¢d%c,ªÄÙÕ/r;t”í†r"P%RxÆùÛÌr_
F¸6ò9>D½íÜ^šc¦gÙ@lVAÒÈ@Ã°2iíªÄ!ª¬”ı±0ÂB%^…l’“¯nƒ¼XÇúÕ(dÖßÖí„ÔÑi‡e/C59ÑI<ms–­Šmğ¯˜ä”/H®ßLQ^pºj¼Ş‚$™*JNÄLĞkç ©r/Sü<b¤AcÔ¼a*ş—|…z[ÌÀÓ<Âç¤H0¦¦³ãéöV¿RuÑtğhzØw§Å«Ô¾{œ¬ÔÕRòÛÏ‘Kô¨R8mFÀjÏÚÎUov‡„¼Òç™dÓZâÏ˜XCJÒÚLA‚ş¡“›O
lE ş›9¦Òí0HãŒfdªÌ	4áSu,–Ğ!ÿòw!—9tŞtlóÈ®Ñe¨O‰	=´–`zw8ØğZ·%…,eqî*ãXi"‘^ÆÎL¯+N„¶ğm|”ĞM.‚z«ÒÇÑ®º;'˜²Bqm¤Iû²l˜ê?Pç1± u.ÃğQ¿ÆÛeûOa TÏfÔCĞ¹z2öm¶@ë0á5ì$–“OÅÂ$
S°6«fy®ßšÚœ±ş¿
h÷u½j³ØóSˆ³…“OŠ@Ûâ´Gs—–şş^m8;*åš}*d€o-n´‘0á˜>f7ûëöWÛ)™£SUŠzÇ¹ş	Áı–<0ºL°SƒjbâÊ#ÙãÜ8Êñ•¯¢N8«^‘J(•”2ç|5ÀlNĞ!&ãëG/0¶šL’#V$-k±œ·!‘‘~‘`²7[\×*i[Ü+Yè£Ûtvz *’t”x–`‘ J l¥RæåÔvf,Eá¼ºxó/}FS°2Éñ#íØÈ–Šm¨ºğ¦…ÍØulï§yƒÖT	¼ÀûtÀ‹¨~†õ ›ó% ğ›v8S1x/¾˜×f_9ÅfšFx9^…eÆ|Ãæ¯ııx‹Õ uŞÜs–UÑLoQ<à[ÉÛ´/¥ÊonxõS$IoZu¼ÌıVFá¨|ÜÿEjASu´0ŠNÈC‰(îQååä~YgPO,Ô86— &X6VJàNk×­ğ^Z
e3bàzÙÂöâpÇW‘AÃ]tr¢ê»6¿»_ÀcC€? àª¶ÕxÑ·€9LNr)pïGÁ_à‰cÈåç¼ï­ø±7S åbpA‚¨TŒÜQ{9?…B†{S=¬ë*JŒÇUxğ’Ô"õ¯ú¼CHPò %šÿÌ™Á7«.Øâ©ª†£óp-lÆıŒƒÌœlŸÍÃÊfÉ-ÈejRQd;[›¤Í¦«Â ëÛÌ€Y0R$4v2r>Uõìî®õQàèB@hçR4ç–ÃŞÏhüÉıÛ,²˜/SwÖ£O×î™¶¸LÍ…£Àtó”¸È"i”ÛÚA´D¿˜½kgEÆhbº«¯šiQ~ãjğê,Â­p„¡P¯}Ï-mpğ,lö²Ü{­»¤Ş8Ú Ót)H”²fF ØhRZ#rZ¬tAíĞí|’[¹h€V°´ís¸·|ÕÔÖ¥<’¶DƒD®éîÜ”ŸuXÄêF(]ìá®‡Te€‚k()ÿ®b;ùnâU	Fyî^scfd×²—‹”“¹òYgÓM3Ğ{ö³|5¾ûkJòøÓé÷­ÿÇ­İ[-i$ÔŸâOú’ƒïÎ>.~„ã”‰læµ0áèÚWt¦–Pã_q°ríô2»zHCp…˜’ıÓÍÈÌsì:z-Š`3=Òëê¹wÑèÛ…¤Øq× ‘7–şüÎJß·*hJ~µUóõÏAã¢ë´a‰çqa9_Q‰ÑÄTß˜¿/0t?”7ˆ†8 Í;M6-Ä¯İ=µµ2D§´?&­UÃNGĞõ!Š€6d­Ãø¨! MÇ×q±Š€Ä¶‡\÷«	0˜ódlÕ3‘ë'×ß~º×¸s²TAIgâ9VB9”`¡U-x¨V$è†W«\,´-Üg‘ób¿yO·ò?Qïjƒ
¶UJ°oÇs‰Ÿà„”éˆßË£*{aÌ/±q˜`*…y<…}ôİ3êABCB Å'0.¥6ÏJ¦&IÚ8biıS³PûÆ•ø,6É®FRô_I9Kº9Ç$pLoM¤’ÏP~hìë®ƒ'Ë‘åK¼L$•‚û¿¢#¹š-¢ïO1± —K›_¸ïüÊ|×2}>lı&%‘[&¯ËjÌ*ı¤@©kËm1w¨vòV_OBòØ¦ß¶Ï	)X¶ê
;J\i~˜<á¸Ræ^ä1ÑW•9Ir3Egö®ğÛÕ¼»‚²'#dh3r‘Â|`·åÑ¥”‹º~¼xÁx-œÒàÕÚYíôÕÁ•¹•Ñ¢j$¼Ö—&ÏXjK‰qIß‡„”q½™
¸9{ú‚7ãÓÒNvíìå7w-B¸<l ráTD®
¬z+²˜Gá´ùÆ•2ŸŠØíW¸”¾Â,qˆkbâëÏ®.ßàƒ	Œâ}†Y Uÿß’~º&Èa‰'ùJz^¤å°.Ò…‡-GvãGrR/ƒ>ô|ÙÒ¼²á'ÙHeá^Õ&·Ş~ú[±f ö1ĞMà­÷t ‰.Ï|í%›ƒ†
¿³wÓa$VËÁÔÒ˜ÏÇœâ¡¿æêòT‹ü‚+¦S¥.äFBÑ'_CPnTí[wÿBÛšGQİÏ[ª»ÍH[X¾u1gê‡^p yaMX’§.‹\Xi®÷Ï©òšíö¥C±šR˜cºªH½(z;²©hèÃš>'Ëq"%İÜ1«PülË1¥L¢Ù&-×é7<º‰¼fúB 3ùó<p2•°„^®g#y„‰€Î®ŸAK¦5˜÷O‚¡ÖÄè¬ıÚ&ùÚ„Ëå5of0šÍaïÉºj¹><ñ:şÄşã¹óùƒ9¬^¦lçÁ”„…%*J«Ş&€»Ğº\æ ·Æôò½¹S«U+‚ ç¢/y@ÁÒC/Â™\µÄ?Ä¬©ÑO;³Ö4FñhÔ¬Ò$® I¿g'c;mVÎu%™´’*İAà¾ÄŠ°t/HÁõæ)cêr)Œ`öËSòj-NÔê¯ùúqÇJO|sñ7tz¶Œ“u¹O©’ÃáY‘`¹Zı¦€7Çø[¶pO-•W}/t(G3÷:/cÚµZá:Â¿İw÷âÇ0Y²sGñiK†]jàKOüHÑÄô½Ğ“Ëàvê²û'&nê¿ú]`*¼%®6ôô
´ğ+¾€wøÿk¡u¨úLú«ÒãåŞF0D!{_So\¢¦gñMÕIàrøZü+(q–µ‘Â°51º³¿4Ò/áhE§›oÆòJ2OÆ‘VÃ 2ã'Á:Hè\2
RÏ§åòê “ĞÇÍû½áóÄÊõ»çä{VBÚÿÃı¦vâ}wí)ª¢9\¾'â‹zz‘\ñ|Hô£ô=FÕ4UÚ*•{’³FìÙ÷TŞX²AåøÿdĞm$šx§ÊxãÉBİ3¶üĞ=¾47æ™U~Äbü*® ›«/|§êİ¦f#š1áßÂ2<«ı$Â¹yÿç}£+m«{÷0ç[MüáxŞØ„¥N½æÆ4>´dî|îƒAFÔ3	ğŞ5yÆ»uQ^_Ck5¥ãæ­NaÌeíÓŠ€,b†¤Úåğ˜Ux&*Fê ÚH}ù#^²ijÛ2¸/î^W£¦ ´“¸ØÖĞ\ş/õäMÿ8Ô`‘Š­Ñ\'8,,Ö¿åE•8Ùş¿§•©ü ı)ùï¡~Ô¥£îŞª
›#®DPCú¨Ávğ¦8	Ñø½†ûøLøØøLœª§àß¤±Ò†»ß92d8ñ:FFîºÅ®Ù+ŠØçQéJ¶½ò‰¤Ÿ'ù<G»GºİÅxÒl—Q¾*l—½ë^ÙB»ÒYÔÑ»áÿ9I¸‡j-¡\¯?3¤'Šƒ•©…Şú¿yƒÙ×‰Áûİ®„kqŠ÷fgO#Í•…æJ3_ÏBAüÚi!¢/7i¼0Áõ}æşe-’¯|Ú€D\K\ÅPİæ'ç=¹ù‰0Ò£eîéR$Ïˆkbåut”ÅêÄ4ßK´LïáªAà ®b7Ù05ßÖ$ò£†}ÿğòu?zªšÏE´‘ÕÊ`Zy!¬¶}¼°¥Òøá.{*©NWüiG<úè^ùñŠØ™h¬
Nºœ$v3¬H·çI=ô±½çOLş§çw>ëÉ{…ú®ÆYK‰HÖW¥ğ+#¤·b;(íKH€9ÉÁ&9gí(1tâe“ëæêœet.ã–"©z·¦m½X­z–ÇO|‚hÛißôgÓäñ
jÍ›¨ây› +ut'™ÃèY~ûÛŒD nôÀ™ôÙÏã§¾ hM·sóf¡RC¢F-.õó0\¸™ F‹K¸6³ÏÈ„€˜ÕÔ{Î­< *\0,Q÷ÂÕ®rí½ªÛ§·s³‚è5–µ±k4YÁÚ*şƒş<Qª<u©Øˆ–‰DüËdr¹4	öãø`P(U”(>üß%?—h_6_Fu€°6İ1t\Ã÷w£Í%gÑShr{=ÉìÄ”å½k¿p¥9†×LõŸKpi«ĞVƒé‡(_¥’uNPdú–º
­xJ5ŒG·Ø2£o¨i~›öQêêâ²¨àZ¥À$R©Ft—ŠÉ¯#kM±‘1?'Ï$Şr©“„æ„?±:wÍ©ŠV×DR.º,?ä&…˜æ³ø{—Òx…å²h•_æŸox,‡)•6@üà7Oˆeåf¿ÎedX1àÓè!ôm½ô”åHš|müoVata’†"Ëëı¯€‡Ø,XÒ·?ábß¸ğ„o²zÎ’š	ÒÜ‹5h’=Idº•Ò¬¢Ö&³+çäï	‘ıÕ˜ Ó›ù¤eçÂôh 2t¬-ú@f48»QBô—±|"òê»ŠƒÔSp”Bq¨1U¶M¼¦ìÿxº7Š»]szû¥vDÖJøÎHÒÍ¸•¹¦²Ë/{:s«Ò»ŸÀÖ€=….nßİP9´``ëú&%åVØÀ•f²+_P¹ª«ÿ‡? ÷4"´èÁd7×¾€è0òáÛç	5Ø2l÷“²[‡^&\,«,Ôm²àcµXÒã{¬èLNÙû9öZˆ¡¢îÎ¥÷iH…ŒP\ÿz¶¤'=©òÁƒoVQ†>£X¸Ä,Õ÷¹»-/¨PCÚ•ƒ>_'tÌPQ…~áõ 5¯YŞğ×‚¯I8Œ±™T½ƒ‡)B!´{ª¯$Î)+hRz80Uğ¬Ç©õıs@Vòûá À6$İ 7°ºn®ôÍî¢½[1­9x—>¨ÊaTÅà¹g4íVT<Ìš±íŞ`ÊwDÆnä}=¬ñNQ åÑ¦ãpG+ï`„ßKÏ†¼¤ 6Fğ(	BwAğÊDöµ‡]Ô½‚ğ9î¾¬¾-Éw:ğÙ+Î*¯{˜û';ß–Å<­ŒĞDâox¶Ï;­‘0‚uŞ¿øoæQ‰¯ˆ>À gqåY¤j¨DKx{ıÍÿn`T¡‰YÒ_ÉÜ;/ÃúÖ¾"½Ë=À¤ntXKÎ‘C5‰VG×øNhŞÊ±UT+kêµ_›¦†§‘ÿ@ÅeÃ¯ÔIGE¡[põŠóz°¸‘3KÁ°‡ãæ,;ÑªáÍ^v±§†hj&«dÌÚ…má!ÕÕªû«kŒÊæ|yK:cfÏ;\<­\›—""ç’i…/8„İšĞ8‰¦!Ô€¯J¾}ÜB[	®]À"O­ê,+W¸ü¬'İ¥†8ËAÀ~ª5ˆÎ†«ZeNÙ¯„gŸ;› ,Çİ²F®¬ŒK]Çû›§œ?¼vQÔ5ÙS"ê›Œël©ë;fr ™R>$'°:hBDtıW‚(aï}À`ñ†}â–|J xeç"Jºü„A2ZHj«`N_5	Æ†W…‹r
É'0 ¸Öq/ö]Œµ€ƒsb‹Ü>™Á„Oa‡×ÙŠ«ÚDüêàÁÀ§È©x÷0Zf3ğ1Õ%½N;|^ šOéLÕ`l—` K"¢èêÊG&LYğV?°r¨»éş¦7EjIw9ÜèD¡Š`§À.ë„+J%2œİoY„¶û_ñ&Œº^*Kó°FÔŞm±G·öû«,Üh$–°I®(£–¤^w–ËäeÀ£	 ßÓr*‡ØDºó3±@—ÕZñ_©8àè26H©ğ—èoÓP4ã!1X.¢øÚO—<º¬G—Mıo>n·¦âa&í#‹Ó	4†Ó…×ôÛÇ¹¢TàÛäb^9×süíÍÊ7˜EV7dÎÈÑtşaä£u¶ãLTºzÒ‹fzb»ÛÔÕo!:“‹”ŒC}Æ\Ñ*òDëJN–Ü¹ÿ§@?İ¤$×hĞáMì_„zí„:E»·)÷JÉ¡y&ÄP%”¶qïCóç«éÿ±ÂòFËƒb'Âé£6=’Á@áaØ»@ı‚Šò¹ED¾÷‚ »Ù¶pSiä‡w@söß5•k‡£T©=ıÌ0ı¯T;œ1;V­ê}Üš.AØ—~4,âÌ±QB-0¬
ZMsqğrLulÒBâÛq£e6°}YëD¯YoÈ?OŒ@©-Î~âËÃQøsß½ê¥ú8ğ zkÕ‚¶½ÔYlƒ…·õf÷aµ¥—(%$–°ñÊ‹£Á_;Çùe<WtIo¼˜$]·èôQ¦}sM9ÇEÏ–ÕĞ¨šÌõ6³ºíßTp`Z”ÅÄ‹$F^\Ì:ÎĞCcÛÏõrS|ÛäYu‡e¨O"{91£„³"Ó	¥µ¬–øUvÛGWúB ƒZÀŒNä§İ¦$ 6EUq‚–°”CıR7E	ÚU¹)ôk«UÎ#í÷ ´ß:7!xSÉç;ıE¶eºH»Ã7şJ5- Š6ÀuâS¹Ácàû{&;ÊÄ4H»ƒ.|•ŞŒDş¿#J€ìª`W¿IJIÅbzùqHçÄ<R…hÃ2-R”æ‡ ¸`{ î˜ööOÓ›L,Gc`"	Øˆ‚1rÎW9Ïî§	–	úî„+eÈJ‚bÓ±Ã"ÁCQÀ/Ğm=.S²zScng”ÛnŒ 
ˆQ vš]ÃŠ[ÛÉİYBP†rµÒG#fYëFb¸?L³O]Êÿ1_½™TV(¶á¼
ß!¸ibV€üòŠÙJÔPmë‘m3¡šŞ·ÖšÃ^–í¨¤ıô#0¾ &£Ú „øî”Ùõ„–üûyi8DYãfÆe!
ĞÓ:ZÄë•áIFK/úWçdMm \BeDLS©%ËƒÎF.È…¿ü­¤’ÎÍ‡µİuJyœÀVÕ&{„˜ThX>€Eí®–Èğ%‹®ôÈÄ <nQë€¢+TüUÛ×ê~ÿ†É[½êki€Õe5ŞuÄÑˆŒ ¡Âi£wzOnQÂ×—‚PsjÒ}E =×z–C³µoÁÌ¬èwZ¼îä!wi².÷ZrÇıå²L’Ü>†&5ÃÒc’rZj–Å¦xæÀEÕ:n@K%îñ
TøóI 	÷À­0iD§ÙùpU»<lOÚàñ¯Şï1ífJÆîõ>ùYÂƒnÇÿ–‹ ^pyÎ`£ƒ>GÓØ¨–bò1Fy:Øf[£9‚úò$ïÇ)”™ü1CK'Cÿ¿‹¿«eñ´“Adn`ôšA!ô%‘Yu²µ›û°›zhŠ‚$kõŠuOWh^ä—±?À;Í]pŸô{½û4C õ|Lí#E\\Ì…+rİ›:Âş‰ñé»YG8~Õó‡5~½ÖF}À
KDÙ \ˆY,5#c!ŞWÄÇjwCAU4‡eÊMæíª’p_DÎsèGª.æ¬ÕœqˆiBßwS… ©lƒ¡?—BpúSXƒÂğ:¢œ\<êç—ì~Ôr”'R{èĞ—ÌR°ô¦—oA*Œæ¼B©‘ˆØê?F“iÔü ÆåŒïâî¿à{¨²‘İwÒiT"î·E#‰ æDI}ÍùçµŠŠ%¡e+:›Ùm;çSTùX»wŠ
ê8°Êñ²¬C­¼h‡Å O<õä°^„{³ü¶¢í¬^Fş}ÍD V2Ö^MàìtŠ7XjTfâJHç\·XÓt¬ãæ}ƒÏ­ny„ŒÚ½–tUÀraQåæGn¾uµÈ•Ë·m‚Wü]}0ò`’ôGã¬Vnt—±D‚0…ôÇ*YÉ¾Œ¡­×œaëT{ù"³èÎì-¢c}˜nÜ±¡&^ ‹ä™FßFR´|Ë{ÉÌ›H^bôßG¤üÿÔyY5G*cšqÒöõâ³c9ÌùVšÃœN\Âà=Q4ú†ŞgN¬uÌçF ®ëÓe'…Ux>×á[Séó†]Y•\DTÏ£îwyÓ@ùE#«wB#p12Ÿ¾xÛ/ 
œ,	öóaìÜBâ$?˜˜¡ô{ßKú†ôQŸX¹{u	ÉêâÒ	ÆV/¾%Y¢“ÆuºKĞ4(OÌ5y~ÃŠÉãº3„,nğXú¢ÙHê~¸:XWz}0˜›Œ¢ø±^æ²6–-\5,¦Áó‡›!¸Û¥—Ğ6FU£\Uy’İú†@sM`/WÜL®>s¤ã³:0şü>¦$|ã‘êİg<ßnÇÒcçÒùåãéŠz*vVòEı¹ ¸ş·ò.XK &â’Õ³ÆÁ¥RârÚ<Óii­ßYS
Â´äpgZjV_^ª¾œDÅöøP™ªå îU…ø‰…OêÍLŠn9xfU=÷Èİ3üfü²‰‘ÃC¿ŞS!Vs©.¢Ñª£sòïNY‘äü[Ü6âaírºLç Ÿ»ƒRï‹¿ğÿ’áD‹/Ï&}ƒ«)­¸ãZÎûÁ‚aˆ·¬¸#…uÚ´¾ïüdõÓk72gn•[d`‰Ÿ-é0¥/ŞF ¼ŠfàiÃ…9‡’fBÊ¯)÷à…¯$6¢®’ûĞ:å-ÙŠHñŸ*pĞ§OŠRÄ÷	Èvs‘‹‹;®9‰~7:`—hrõ>ËÛ>[hÃL«–şni«ã**É_LÓè8T¸6Ë†€şı¦wmBmŸÕØjıåÃí¬»KsªrCwˆ	'óÊ3^„¿ÑÅÖ&éÒä”4G‰‡C@'îİøæ5ö¹G›Õv™í¼q‡­x~ï8f&ÿìR<	]ØéÃòYD-M_‘´äÅ@S³ë¸`‚
òÅm²»ş¹†nÜºu0rDè½Ù‰ÓQı6ƒøt”G/wK0HÌ[GXH‘¼èÁ’ºsàŞuY+ô0;,$¼=tŸ¯kuùÈzÛÃ,×¬œX2«hŸ«(j|‘»#ÀØÈØä¡„@Xxİ™ıÓ5Ù—<îçì'{ƒúÃ÷ûVVLå½öçgÏëÖD-~"¤~¾èM½ÙçîE» MÓğÿè‚—í~O“ËVü>ò€ª=*Ê‘;¾°Ô!XˆĞş±Tß¶»½9ì×mgdÛııE¬2î»´¯u3s_Ï<{”™lß¦µx×jßµdlåíaÊ:n™R|ı ¥Ù£åg'Z˜T„òôêâiw¹-åè®€Õ7Ğ'Zaá~ÛkU>0¨á,u©ùÇš%²™Š†ôÀI˜İr×‚÷Á±qÎæğ9k~'´ÈU>w	şù3é”ë–Ól`Ô÷¯FRï”üÎ¦ÏŒäÔ²RªX¾°©•aÉîo€€¤1%iÙç™Ä5~É Cp‡›"œ¨0"vş½	b§ØwƒX"ã¾!­YMÚvíÒzï§|õÃîÃ¦íİ”sœæ„•Çª†¼¥Ï¡ËÓŸƒ{èAÑ'‹yh`*C´	§ı²,Ãäê›[(DÊiÿ£/ÑzQÁQ#aœwj¾Ş3Gbp!mdS}Vw¨¦<Ş¸!ÙÎN]‡éœÀ†( ÎŒ;³è›oq!İg:ºŸÎ\ĞùS› º]%à¤Ğ;:9"Ú8ËXr4ÁëÛ\—0+Xï¨u¦»7Ä€Ïw]È5˜SÏ½.Ö4…(Éqî”^&Œ×¹©²GE×oæF^ãpç¹f½˜Æ­ŞEÔ“:æÁ8ïÁ?Æ²øY6c-ÎŒyŒZä“¡·få>öJèurÍY	pfv3•ÀJ¿´«ƒ`@ A0(à„ì{ÿÜü¾öÊ˜›Ÿ¤}TŒYé¶³(
2¡‘Èp¯®«ØŒ¥§Ì
(ëM]¨Şt úÎòDôì
¬ò¹dí´Ğy¬y»}‡@*CS¦\%¢ÿ9ÖİcBS}*¾2­¢FBıŠB±àsåÚÌB¾Şşûî˜ÜŠ?Dâı¬ë„¼ŒÅÂ›Dû¼t>¿„£¯õñÿ~r²‹^ª36w$hößÔJN·y»\şLN¤ËŸ˜çÙ´Ìn[ Oùƒç­Zn¥1fOñÀ fAÊÜ?Xß3çñ‘ÅŠ@=OÈ]‰1ó:üÍ¸““=×•«²Ä”ZÆí1nE<äÿ0Owb‡÷şÖ	Ï	1âo%`²ihâH
t7„=Xì—‚©bvPyàêË#‰7oG; úäïÿÇDT†w»K¼º„ˆjáÅ$JÉ®¤5¾ˆ3f}DçsWkÑØ ø¤)#aK19¶¨Q:ÁS,)Ğ¶,oÓÑWéî¯ÚxšoiF´i¾ºæ?TÀæx¸?Ñİ“šk¢Œô‡¨6É¬öÙ›•	ÏS	–n»$0ßÈIk›€Wÿ4+èGª"\«¹ ÈP.xf@1Ä^¿ÕM’Á°¹_,pG•|ÉIµÿ¾i+±      KËnü8 õ²€À9à±Ägû    YZ