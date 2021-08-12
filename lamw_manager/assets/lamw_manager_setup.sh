#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3675445726"
MD5="290911e57b23e143a206d02a880e5be9"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23916"
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
	echo Date of packaging: Thu Aug 12 14:14:15 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ]*] ¼}•À1Dd]‡Á›PætİDõîZ±Seº¥v(ê7HùM{)|+ß†=¯¤ßõ.Æ›ñïJÀ*ÊèçOêG§!›ÄWÛóD{·,³_«İ@&ágh2«“.FuEO2á%Ÿ£üpg™ÖT†ša^±¡:‰ù‘µPËFGXq®ë\Dç0He†òSG³3´°Şé®g	Á¶ê“{QÏnŒÿHí•L;±*­ìÇ`'Š|¸VĞJ¸nŞ3±Û- ˆÄ…"qJiÎ0‚š!ùÙıı=02(gW]ÙFØ¯L? –
˜bÎ@–ú°{ ªŸo,Ù’
°l`#/6Æyh‡QàC×R­Ùù•š{UÈY#H_p)ã<eíì¤øªî’#àX‰
Ç¨³pª/>ä¥ëİ+²x…œ’÷›¶²Øp%“^y]ìn€ªVfQ Äuğ8§*…¹Î+ç—Ê{ªd}Ä?ûÀ©*¿”p1ˆp…A—ÄƒëÉ	¦y#Mî*ZT®]õa3†ÖÊY½WƒÍğ”x.YRŒeó»`]"7gì°ª%&e®ÍÛ'&ÀÂ]µdÚèÑÉ°PÔa6ÛP¾È=Uh
oâ8œ3™@—Ø‘Û+ªÛ“¨Y±µ#ĞkMïâíœë>¾Õ L´øÀ«RÚçÌAf-:?ä¿¦uåÑ,uƒà5›‰qb†$¸4ş>DkB3aÑœğ3ìàĞødù•÷/ÆYÚÉÛyM„Q1«ÌéEf6ªÑ‹İğÁxlğø0Mñhµ+(£ª®İ‹ıKÉ¸×ÔVŞn¯Yoxÿ_¬­5qt·×e
 Â²¿O·Éµ{¦®)úø“ò‚zze¯ ›n^hˆì;˜º&IMşHvJ£„ì))¾°‡Œzä‘^§„¥ÎõÖ«7LªèË¨Ø½hÎüı”	»4í@
;aà4Ğƒ‚ÓU§ÔoËª©òÚ¼€¹µˆ[	2ßD:5sâã§fÙLÅ\aòpÏB Hw 
_©²HTîë÷€+ekïhE†S´~Æ…õÃQ„üVjÏ¯-óv/†ëî9ÖŸx<]o‹h`nÈMW•2ˆ´Ò/÷KøÔC„Ãß®ß½R5†ìÈ5äÒur`zl•+·c:=ñÏª-ÏŠi‘åñšz®ë¾æ_?d?m¢·¼ğ¾Ú4#c[SÈùpâ Ei†,ÊD,ÎxÅÿÌ( tÜê·d®*ğZµïêò%Æ	˜M·öÕÃkM¢­‹;Eaı9¢©µ8Öø¸èö9{œIwÛšÁÅ†Ä~æZJÌ¹a
şA‡¯áôü×£ó¤wRTÜ‰^¤>Õh„eŒãH¡üz9ŠBµ®57q‘š€÷D ‰Şè‘œH[,h¦C6}õuOi™¿j”d{ÂIÕC¹±Ã¿„‹hÛíÍs»b@çİªíŸ,¡`'/»±øle¨U³b}‘±úçR(ñş ,Ìdëí¤¨ŞfF.²`4œ|Ú"n{v}Ãük¿oæa".ŸóÿåBsEŒE¾*”zÅ±iÿ—L‹#Ap„òìkÌå °šñöÔİğí=bÜÔsM’~•Ù6ô†ĞŠØŒ{ŒBÓD!Ô(&¡sŸ9¡Í3ë‡-ZÓù‘ÁÈ:ñ>6òP=;PàrjÙä3¿şßè(åoÄõäıK$öR)×’Hè"§@óÑNà‹e…A°q±ŸÇ™U<ÎWÊš0‰“u–µ>
õ¨L LSÏ×u:lá­?{!ï­bm9£qBL¾k–ì2 fQ$o—W¼ÍwÔ-aæjç¶€B&ÙX‚¦}ê(i^z¤(hP]®6W²Q¸³F6OÅì‰@:¬ÂÛ6&ï.\nga¸ÿ“úd=fX¼Š?O+Õ1´$öŠx£©Ï[m|Üs¼g¡ÊFÃOµ-à*%…U¼©pBİ£yêÁñoHV0e™&f»ŠD½‹‹Á
RšA¨o!Í!;hN5Š…vÎ„&B&mìt=Ü¼ê‰¡c´zâÍHÕ:Ü€‘K"c&Ò=k_¿†i'™z(ÉEµº+>õÊ±Ÿ­Âx
øã[¯MEc}ˆÀrZ1BecäKQ›Éº{Uz$ÄCÚ¿¨¦¸s"Âà…Ï…‰R«tú~‹F{QU§´œ^Î?<¨»šéÈ«yw¥rğc÷Zæ¾†LJ¬BÒz`4”Î‰aÁİûg³_ìpkBv1Øİ{ßeFËf”0Úí½qı†¿†G3f¸¾~[[“½lMGlüÖœ}ävª"2¨*O:Şİê•`8ú1æ í)àLƒñ.À†/ıBOuÒQTZ®xƒ¨ Yà^éı•›3èáDšÍg aMƒû£uÉÅQ³GFrÀ–ÏÜ§Ëlß~9À4è“ºïğèÁAÎW=¾ìò x¨†#¥0`ÄP(¯¯} ²eŞY…ò+ÅºÖüŠì‡Hİ—r®ÆQçÚë7_¬x|l Ôû¯5è¦f	Wù‹¬AË”D:¤>*é>yşT©$ÖfM· %¯.?³2Ôò"o¤%çıì9ü¡d¼Ì¯UnşõĞ+mP&¸§ù‘p9.pá×m­‡pîÃ±A÷´Âsâ~ayğmÙºìŸ½òèğ*5Î\ŒFÉÄí1*×>v¨R¼ld¿É¼kÓ*¾„ÖÀV¤®ÈÿÃĞŞ_«‘¬-’úÛÏZÃr?•1oYi3ÿ6™8·Yû	ÈªT\ÂGPdrø©Å†œ$$åi¾`H-!S¦˜°uæqŞ+’	³l‚[;fëa'Û£}2ŠyÊÎ]b´9Hø1«Ò&/˜†Â5MÊ <~èé‰‡¿Î+¬Ø	LµÅ‹ÑŠ±VÉ²Oíó#˜œ Ñ14P%²7]wúáeÌ<€9
ñ&ølæ‹oÉ'édO­˜âZqéµ	Ã6£LÚVZax¾I«–²6™Ç*EE­|¦Ánª§¡!«)ÌToÿˆóPî¨ˆ¨˜˜ Ocóv»Ögj_·O”Ã³˜b–µcÈj?;SÅS Šˆ¸i8Üs§ü€Rˆ—…æ\šh	ïïğRaÜé™ÎfQÁÌ[EÑ§?	X%«¡}ËãAé¡•…2ñÖ³ŠoÒ¹²„¬øÒ—Û†ãñsk„	X8ûmĞº%‚O%¼;ÚC_¼x¿ Òèpåç¼ÓNE¬-Àõ¸	(ÁAªêâGTF¸œ1rb`Ôû •Âb©ÜõÇNş@ßät0Ÿée©&5Øû\&¸ÄÜ\™­´#r1]‡–:úaèDè óÄ©szŸ½§6|‹ˆ.vfÌ0µoª ÒúÜƒ¬ÊÄKI&óGºa$?¸}§äë} ê•Aİ”u~Eq¾9ŸK¥&ÙÈş8_Á³ËF ›åü!_æP¢Îfw°Ğ`2ñÊ2s†Ó¶ÛQ@<‚Ìm´Œ&×•8×İògÏ^ŞÄÕ64nD@a!bäÜ1~ÈN0™~±éº9šMÆ)ÙPK|lõ»L¤9¬Zê¥#Â04,u×ŒáW)âƒh>äBØÅ_Ô'á³nÖÜÜ FiæĞ%Ÿ+»Á›C™\Ş¥¤ÆCƒf@(î¬-Uµƒ­«V¨ó+Â¸†lBrQbº”ïâ<|	3S¦Š"“ŸR˜‡ú˜°á=ÃõwùFynwè&ØğÑçª–gÇEÀôîıèfÕ3|D38± j™@¬©œDÊlr*Ya‘fÕ¬? ïlíy±…:ßv¬#„ÚğË—íÎQp[¯‡x£ÉÓd0¢mÓ]ò(éR5'éÛèMÅâWé!É™kù Ã½
—|<cıÛãËMÜl./ÖPır3}İ¢="0•­7ÒF#Ú"bñE±N‘dµŠUı&—ãHA”ËÚ·Áà†Zÿ¼­¼=^”“ı[E¡)Fw)“ùrXv’İ¯Å±Ìı>tÃóŒn ß¼ugkP®ö»ş;Ù ÑH¦†'ı?û+ŞÅj„W¤>¹;F²§Ú"åÒeâgê{¶PbÈ¥ÁB´»X„:÷VÌ	6ßŸŒR¦’oÑYËŞí=›×âuÍğhUİ¤=)ˆ&pÎh&.’MœŞ®Bö.>® œ§i8ò´/A¥Î<aá–« ËOÔ¡KLÔPU¼û@X-Õ5ìİúF{íí`»î¯;F¢‹qın"ğåêí¡„M	ïL‘wÛ<À$Ì>¸ßvÖDlÃE›eTŞh@m=Ş¦ÎªÙ´&Ò>éBÃ˜lpzdœW ;ßmm–>úTÒIDÜDJ$Hu–Mwúme•Å‹cü»ôè™nT“*Öü¢BjäV †ÛŒeB1Ê¾oe5û8İ¯”Ìl`©
¡
-u)j ¹«`®-6òPhr?FN]´w+šş.\¯&¡9+?5M^óná'‚«k%qş/S±éb)Vš·1@7<§‹¡®ÖÖYc§ÒìcÔ “YÖ–N&É01ÌÍ1®D©„Á‚U§^¡ g¦âŠ23¨Ç6ˆJH€ôúU½oÓy>1‡uãJnÌy…íz86ÖvóJ±.c¨fôy´šuYÃ®§©¤c†áP 	ìÏ|ã¹#BÍbj³*ğmN´7kÔZíBR·p|øºè
œÙ[Ÿø)»ç±ÍÆÚ¯æĞÜV„<Áå±
=-gZ$Pu(ğ2BÜlÜiYÎtºè3× àI‹ş‰Ì‹Ğ\!>êÚp*Sİ‘8j¸61j_‡€Øú¶.Gb5¸ÆÉÚ¨
šĞdm—\ñêÌ*OãÆõg'h«˜z«:<²{dº‚ÁşBAñ.á#ıîo<O™‚ AÌ»Ä­Ñ ú=…”Fn¿ù\K~ç XŒ|·Dúª(‡øí…ÿá¥­ ÑlÔ¸b¥Z[K2Eºa¨tÌ#'ÚZ®ê†zFc†a°ï
Ù ¯¦uSfTbİşí«!¹#Ó!{¾ùşU°°=7ğYÈ{°MNÄiƒ`I'²Ée"ŸÛzGºÌö÷ˆhäwwÔu;2­/ÉŠä\Š‰ËËõ¯{¢u¡XiqoU¿}ï5öTüó˜¥WÀ7ˆÖŸ}e9ş}x2ºÏcÆ®\*Ÿ§¬å1V£ŠŠ}FıOè#TfS¦Ûİ„<A±‡¥ ‡b§W{°=¨AH€¼„ÍpS/ßl!gÍ>â¬ª-¯·jÜkFˆÿBÔ<šf@C'"Ek«1ùà4‚®¸6uŞÕmôÂ4êyÑ#Ô‡Hà¥šò2hÏí¬ù5*>ga™5øFõ›0³ì4yØbóµJÍĞ5ŠĞ*>dŞùôñÒ€w‹ÿ¹ySM‹×·Kdb9zV…ö¼‚ÊÁuá­"ÀºVW÷ØQÄ(ŠvAæbÃrÕç,í{Åÿq?Á±¿p:º¬'‰:©p·¬</ mµÉc÷ØöÙâG—%ú‹†1Z€ìH<Ê¨…¤LNhqœ
§˜fµÃg%¥gë‡Q»×¯"™|BV™ä’#VÖ4INm€&÷³xH%"ZÿêKïTòùpÆ˜ÕøÀÊ]Æ\ª€š²õÎ £qFCÚŒK¹‚éÇê U¸§ÛÑNyÉdYïùÍß/¼Œ2t0æ<ÎtDÅ(¾·I#àh?|ò£·ò¡¹%iŞŞém˜~fıYzÅ´(c<Ç£„ô	çÊÁß;üaĞäuhÎTßÜñ‹Xó©Ùœ9.ÒâG¡@”‚ˆYîÃ/Æ•Õ?9¥B\)kÒDp¦ÚŞó Oş 2]z\œ-ø'C—*X.İpš…ÓäßKwl^Ş:ïgZ•œÿõtmÔ7àÍs›_]˜ÖÒÊ’®™'Êİ>İ%H*Î:Ö…y)ì ³wMpQ¯|ƒöÌo rzmtiÚñşPøIûæ²µ*ÅšqÌÓpƒÆ†Â¾7÷Óºè‚”& È.Óe·ÑX|±8Ò‚«‘/ìbà	3"“È)òû•—Za—ìmğTÉ–ŠåF93ÓJ¹ö¨#´ëNl/MÓéûŸG‰M¬³ô³+‡$Œp+¢ºéÅ@Í½!ÏÏ„‹.î¢ÁI$ÖAb˜„Zì*<Cé<Aw5}Å%'Ù›¸Db NhDZÁÈ×u]ÌJ¸sOËı´a%cÜÿ}Ä}"3|‚%¯Y® A;*´‘Ïºƒ}ü:ùGi›¨([Æî\NW£Mmˆ±$î"¯ú‹(¤æËÉ¼EÃ¾ğ•¯%øv‰8ô%ã7Ğ‰ZíÏ!¦l6údN—Û/pÏ³ú9%'Úbììæ¯ûhñä`‡¿íMŒ®"À‹èz²£!|"Vp­îœW½Øìã Ã¦İÿÁ/ø†ˆ›|›Ÿ¢[{N4µ×KíøŒÍ-zÕ`YXÙ×(^œÉ$¿KğÂ+4çNyjÀæ‘!J÷ìXá¦W§´ÛWwøà©²%Kñ<…Ìõ0¢1=‘ØMU@·îf£˜Ìòåsğü¸L7Û¾‚"|“Íâ†šXXM;Yp ¬>f7˜ ª.êpK·)ANŞoYîÜ°ğ`XÃb_eº‘=‚q¬÷“Z8ËÔÉ²KÃB
s³¶•6Ü}×\úkd—0î	ÓÄÈê;ş!(iz†•? 7äqCÓŞ‚S	7uxNÚõ33äÙi'3¼B9 ášläŞ;N|eÊ]sò°’Ú—•g„Š™ğZ³&İÖ¬È!ÍÊˆ?Áü²(Ïë»,ñ3èÅ@xZkÛÆP®ß§âõ%š’Äx¡»n%]À35¥º¢¾1€ÜG­`~Y’ÊNı°Å>˜N€÷ìšøÜlO"Å‡ùÜ4n1!<Ø3áĞíI¶^ª:Ç«Û/.Y(JØúFK ¤W
Qœ ¯x.©ì«íišŠB}K!Eàq²t‹"‡éQÀ¢QjTÁØï¤"š	¹µn¸8ÀcˆP»åğéNP¨ğê>60Îé¡ÁF‚5êßİO!ğ‘Q§²ƒæBhÿVt+xSf`c–¸×õDj5O ©Ó¿Ó1)VIçı#.¸j»-¥&´e”“zÛ~€]Ñ]=sA*w¨6s£:×šƒJu2ç&vEéš“©ŞîÂÙû">”ŞZk8@h4¿ñû¢GqG{<9¸&i[¸SR(ÌåËš¨UığïS°™ zÜBE¾ıjæ¯ÃüÎ'¸èïè¦Uâ»ñı=lÂÈ¿Î5<øm÷ùUĞ.5µ9ŠÍq÷3ÃbøcŠ¤PªºB¤y&x)®\
Ù«PÌi½ZÌ g¨º%6aÅÊÍË8Ööq›Zö?×–Ó3]WÏäÉQÿá™M®€Ú˜²æ÷š~®ë„0Ú²•cÕù¼ä}‡#ì„M} ì¿œ!¡áß²CšJõøtÌ(OñÏ’í­PPxF3¤~ç‰úâÙ#ÉêQ'sKmøúÙo_n&z‘B“FV*ãgÄÉ1/"dÅGGæÈ@ìï,À¼Ñ›š°q±í}ÖĞ¯ x2ïƒ
c8°M÷¨^$N[Ó†Å!u,>ÂVÔ¨)y®ÿŠôóøùôÀBx=n»›•LûõnOÙ’§D@í4ÊÚ¢&Ôı'\w€!G5Ÿù%Zº;© ;$FÏZÑËDÇ@³®™ûšRül±9´uLB‡AóÙˆ¹`By“
)*¢<]ˆ¨>ş{`2Nòú]º8‚-ğèj7bv7ø»š0ş8xèlĞÈTp‹bí×ÔaB¥‘¾qoÎ³¾}§×Š5èì æYÀõÌ+2!ÊÄc¢LÉ»óY7J—€šÊ¥ÇLĞ•X}Júî×w9Å•P[w|Ø{ÿÖã›D¿¢˜ßğ„ÎÏì³p¡´ó¤9G­°8Àe¶aô=ï`øšFL9'i>¸¿ÓìëPnmü€möÚx³V*©wTNÂOcg¶’ËOÁàß|ş+w…ÃU†zŠ›Ù*—Kjäû„è½,f?«—\9ôd: ´BŒ…ÛoËPMÉ¬Ğ«³jªÆ“+œP>4/¢î0ñÅûĞÿ`«´kÅ‰Ãs«ò{a2\á„ÜÂ'aáÔ*qƒ(°6àV>V–hÀ±ùé›˜”1|+B†iP&ç¨¦NZßŸ:‘PºÀ’ütš¾™9O‡EıÔï‹ü8zŒmV·«U6o©¢šW‹i¦Ù·/£]¶z_Ü¢œz+82._Re‰„ 9ÚàÈ^+uwõq"ÿµ=ÎŸmgøõßÀVì4Q¾ÏóH¤ì`:®Ç{^~f¹i]~0Â{#K}šŒh¿H6—'˜Ü°jOl)Ógv¹SıtçÉF<*3Ô?+™zÜm«ïAœ"erXê°i,)Ë50Èøw!Àéšë”‡	Iìœÿu­pÀ‡Ö9ËR–b'EânüDbT‘¿Ap!ßĞÂ;?ê`MxE	4%g®ÁÎÓfÌ€¿)¦¥Q€}d«-‘©ÇÉG³[“…b §Ü3Û«4
:Scƒİ	}ïùIk6—õº¾Ù1-[­ñœ®Å:zt…¤F×÷‡´2#tä›u11ÉàNÿ}>ƒk¡èÎ0Yd¼Ù#LúFoäR]ÏBš’cc/ü™ñëz–ïş2…°tcu¢Mb$ø$”òuvÄ z×ğµ”¶Æ"p+JkL7¬ÜEâœÔÈâc¨ÈñQ:²Ôuä,d8Lƒ9À¦wµ;.¤ª·ÖRúç»ÿWÌ«ú%şPŞÏCj÷qÙú°¬anv¦?ÑqÔR±{^¶Xê_â(è"pâ»5·+tåšª©Õ—ÄkÚ’#ò,u””mót¥hâƒ6Şß‹^é0säµˆJxî_^
¦ñ0êù^vÉdr3¾yŒµÕÇáGaqôšªÄ;h†7ŒåbsUıáùÄÒ»îh„I‡knù{ØÈÓÅá—{p|K»ãÍXÂˆÍ}Cˆ¼BÍA_«™h™Ô6Ò‘Ì¶Î¤Wú`ºíLZÙÎò°—rÊ—.MvM#¯¢så)©Š¢Î
r8¤
“ëTèKÁC®¿âø“šü¾ˆÙªÏ¶	ÌÆN§eó|áYÅÉä+½œİz÷„ƒõ¬4(óhnØ¾®Ñ	ÒÌPC.cœq¥ä«‘Z%Ä qÏ¶ez?p'ëK2·}¼›XXaLN)6Vğ?N€éó-.jx4{˜G}V»öOc¸B*İ:)*MV1¼–Y‰ ‚B±-|ŒÈÕuPSî‚¡?EFİ8
~"Îj«ßºú‚h,Õ7ÓÉ*s¢ÌüÅëÀ¹š_AÑ…¢}ÇĞŞ$†ÙV­«ı(è©ÌKštÉÆ‚ğ­(÷ 	ƒ=e²ÑÒ¡CÕ<ô™x‰l²"ÎQ$…í(Ô!HÙ8ª|NŒÛ­¼bÕëjĞLF3xPş^Õİ¶ÌTâ6!`l£«hÎşŞØçE];ñ+Œ¡Ã*ÇÄ£f­BğeK‡Z šZÿÏD“!ÜLXlkR—V/òs©õ×H°Ëc*†[Ä]  •…ílcv#IØ;¿oîbd³Fè_–§¶3¾MÀİ2ih‰âEf˜Ù04Ñ¯s¨½-{Ts|pl­g®VF¥xÏŸ¾oñ^ü~8uö{YÙ„P½9åpÁf½‹Ã¶ bd	»wÉš(w©¥p—RvÇMö3üöd'7«9™T±¿óü-…¡F;}äû-M˜ôdÓíèÊ^†£ˆ00Mhú¼0AQÁòàÙ+ñ\ß›Ğ¼7wÔ‰Öb¥FhÚÚR…½ØqM_Ø†¡û~gT»‰÷*B‹köÉ­ñ÷6œù’ÍˆhEx¬õñ°ôğ‹‡4h¸ÉÚ%Fâr¹–İã¹\xÌ¥)l14M,éÍÌÎ¸¤hÃƒé{Ùé&ŒES	²…h<š¡g?{C şéÒ²ucÅVIõ1õZ}5¿|ªÑÕ|DÅ6şFb¤OaMnGõß–'â°˜€Ğ Ç×qÎtÛø”_ÁfBYgšúv•
’™Ûf¬½ğráU„÷z}ç9.eÚ:JDuÿ6gContwTÒG§.¸¾æ'Bb	CvLæ…½NÖçßıGÍcÚCõpõÜŸòÄ÷ÍE<’·dË<Ùo„h*ÎáôÄk»Ö!—h!\|ÔÔ‡3¬ÈE©Æòş1®éÓ›,:qÄ|ŠS~†$U<6ÍoòK×ıcˆğ’h#ô»Åı²|7-Š²NSi}·^§’uæ-È¯ĞLJ/x[„%v&ÖÔWUeË`èÿí}É#};Ç*^P«ùOÓè}e±¿cô¬3èìSZ®ZĞ˜û=ğÈyÍV}‚×œ w“+€AóİX©*5ï¨Ë'Š©ÉÏ&“ßñË:»8®ˆ_}âå£[ ¥å¶IíÏNéPœí$¢Æ1€N°`¼|6Ej9‰Âœ;ªZl]xÈƒÇ¬I\c™Ú1ÊÏù‘C“['Ëlå$jsAFæ¯¬Æn´ŒKÙ>Œ|E4âå5_Ò«Â×NzØáÄ™ÍÆCHvVãR|°œZæ.ûº‹#Ğº‚|å‡aªUËvc:İN½‰j~p	±ğêäbÁ4
’êºÁN³/…he×QK1mr ¬Ş
ÄrÖ!ƒ­(3}µh‚Q³ƒ"S®œ¾@sÈmøMöŸù¿'6) ÕÅ˜aòå^RÚÛ›w~ûÖ—·ó·Çw'¶z;ç“Åì.¢S"mÓÂq®.á„¦AØƒğyİ%Uª‰äyWË¯OíéÁ"¤Ğ€”’»½çòJÈ®È	8 	©ªóy¬ı„>Ò]¥»¾5â^-[˜$R"aòruÚLMjáê§uŸ‡{Æeƒ&ü¨ÂEê¿º\!AzªŒÕ§TúsÈd= Õ˜Úwx¢t˜/Ç‡®yKAÑ×õ¥ºäd‰Öç–ègÏ;=]àëÎ 7Ó×÷i3|šâÈæò-Bˆg4 ıTp‘×s›Ø<ğKAÈÀë–ú6µËAÚ³ÙÓ´ÿÌ©{ŸíL1–:Ä¤T\£GÒáõRşfz+O@‚HgR"¢kÃ­ˆºÁÖm›V¨ë<\!dUÆàÆ "Ò>£-P}ÉYd¸;;¼×Õ–-H?Hé¾D·[À8]y¸ÿeßÓ¯k•9dšõ}´è_õa¼Q3Vº‡ªúšèÀT~àÀ’®]” ‚àIG?—&ÿã!¾‹;JûQŒ”@š~ã<-?Ã'$|^vLè.ú¸I{Th­T¡«Óı_øoËÊ”á{TYBßëL©§µi‰&•²øH¹–•¢µ§¥³!0…Aª…WxŠ4LÀrõ¯”Ì„aÖe¤¢¼ÏÛwa‚Ş¨7Mšvqsqé	¾fª¨Üç¤œ¤.ŠÂ—› gğˆ£à-·].ò×Ç®Éàı+b»î¦òã¡„ÄtM‹s~‡óóTº#ú¶Oÿz§G0Áq5™ÌÇy’Å.|f6?Ô‚î†“ÃÀsŞdá
Ú5ñºÙ!Ô?­1bá°^Â®›ÄA¥+t3.²L­ÉÔ±[Ë™Inï£šqşqnÊ*OÛwóËİ5³ƒ´§ÂÄPÙY¼ª&_µ` ÍÃ»*-ÍCõğ'?Á]ÇÙ,¸B±0c#*N0—Rˆú¸ÔPGÕAs=§4£–Û´?ØAv’‚¥¼»¶.‡Ü`P áBùT+4»ªfö…ÓéÈ±ÆÿDR{rØ¢ÊCa¬È·¾ß‡ô¬ı ÖV/¤º«ÊiÎ‚¸’vqĞczé+‘k5Ÿ(Õ»ÜæJú´+‡Â™Îs’(ZXüÅÒñ1µ_C£Ì?ÿñ
4Î@Ø“„‹4O‰OÌùÂ}@YMvGE!Öi-¢oR,¨óFŸÿ+®õ”¥¤mí7làSP"…JÁ]XÃñå4¶ˆÔz³ŞLbÄ‘ÅöAƒÀèìsCí0% ù­cĞq7ü×2g S¨¥‹¦BÌfiíå$ï4<ng²Ãÿß(™ÊÍçı‚	\Wı'x‘I“„àuê2/ĞãÃ‚ñ‡s¹élHÛ&;Ë@Q-ºğ•Š5‰Å:Èºl‹@á£ôï®£¦™6ÁÊ #Ô{øx®uéórä”÷ËÀ#Qî¾™Ìl/¦D	´äC>Ê<¿å¼/B¶“r¶½“sƒ„"Lá7šD^¢V¹ÆÇ"ÄÀ¼–œ7eÇI¥Ñ—à®GæöÊ–û¾ÃPàºWR4–‘\E´¬£75yµÏÑçˆÍÀâa­9
x¥œi³Äf`ãÒñß)ÈL¢Àë/Y±,‚K|@(­·ÜE]Àªß¦¢eôãòòÑ›Ö@´Ò§4MP“¥°ª%ÊgÇÁãYòö{#s~AÔ¦Æ¤÷]¢T%•+oÍÉw=b2…=–
¹ÙM“EßÄÎá,‡:¦Â¢I~ãË•…Ø…ey”8ı“œàñ›)=u–Ÿî@!êÅZÁ2ê6È™+: ’’
çîğ»ykNø©ÀÎŸE’WA™]{5^mÀ!lS¯bÜyP¶ÙvØõÊN¯éüf¡:ÁLU?ë—Â¯,5F©`ÒÃ§ÂöŞ-²éô¼}@bÇ|úqË£æªÀ õ-'ıÂ‚KzcHìıFñª¤ız}h 3ËÆ1¥¦ŠıÖRÒš.ayfLÁye²í‘°7[q¡=OmŒeÑÌ7q@ F‰Ö)¤4àÜÖo?0úwÔ°õ/şS•è ï(gqÊyí¥}:C¿
ÜGÓûëÉ¼SÿN±MÛõ™ó—şÀ•IbãKÈ‚»øRşó•y¾
{Sıä¾¯¹qÎ±ÃŸåj–×ïÉZ`;ÌóÑà)WÃÓlï÷ÂW”×}Ànµß˜UyN$óÔı9(Q7‚ifÓ°U³_æØ.tA"$Ü-T”’(2¸¥½zo‰)N­MåCÔÃ¡}ôĞz’)­‹ˆNDû‚j5²÷èCÿ±_œÚŞLÚ‰BÊ‰WÄñ´Ù~tôi´„…•å©Y	û£±&’M¶Ü:›¬Hu¦^!ë®Öš"ÒyÙg±ÖŠ÷/˜Áo'eHô®çÎ3±â¹0	)`¼pA3R @€åÕ¯[­3\–P§²«¯„?ŠÑñˆëĞ»Ê	ì¡ÎÈqĞCıSĞ¢\QVÕmí–•¸ò:RSŠqzˆ57¼˜í¶Ül)j_…£‚M:¦ŞS‘²5ù!å‚Bº
 ¿“vnŒQg^Ûnš4@ŸìÖëtN'ùNÉ›Êœf-„X†àgI:äË+Scdzpİr§¥~!`‘«6Dù(Ï¯â!»tÅ]é­C…Æôä~öÚc	°il«µ Ñ^FŒxb³P(‹Ò9‰k›mAR@{÷%X°›”²ş­›d067,Vr~ZºvÅx\(b˜üóÛñ¯_âqåº'g÷jK³eËp‰’	ºù|LõüFãç¦RĞóFŸo7
Q[""*¸LÌ€ :™“pSf]yºIr´ºÏŸºÌ{ùI±¦µfOµä–ÍÖlÓ"†¬ß,pöu$‚øN!5Ïw¨<uÛÔ¢lƒİš»Vİ˜´’¹+Sµ’¡~ä¯ÖÈ•zêàS¸7ªälU|fzŠ_Ô?¾¥öèÉ0ø{¬ÃqõîHC†Ø‚9Íì«9u*ª¦˜¯pÉ_?äIÎ$oæØ‰…C©]‹°uÛåò›PûE!©°H¦•Lóy%¿|™ÄZhI;gj¦Äûíî‡d‰y.ü É[PÑüÛíÊ°úñÈ§œcÁ"ø.x7`AWcƒ[ç‚t¤D
r¾÷¤¤Ü/)óe[pH©]º+ˆ}Eï–]’ÅôOæŸ/?^`Æ[„t£¯rq!{"Ğó•İªi‘Ò¾´Ñ¨~N˜&/>¾]‹ÁâëCìfüÑå¼âGAÕõ˜JiŸüİ{/vèqù¯ğšt‹fLagXåB,¾´“t¸ <k¸RoˆnÚîå²;ˆ¢9üĞ¡ı7¸3ª“>	¤È@‡ìs¦tì1î®aÄ~]_=nºRÇ"¢’(ç!¾ÓŞÕ­…{&üD<ş?êñùÏ2[rÉœízãuŠ2,++ZÀ)ãÑWº€Æk8Éù%çWæ„¸lªnân±á¯4ÓQ2,tĞ¥r}…eXm²€kKÚAy»Ìèßæ*/2õÂ~è’‰4!À±ıÏø_
fº~v¹¸CFÿ®_2×ÿH8}˜¶ózı!·ˆÂs©ïÈª.ì‰@t¿ÃcÓËäq"¯1¬¯g4+OÁ*Ã6?ô'¥xR¬‹± "~c&CcìRŒß{næKIK*..&9šíG-œHŞıÂâ,;óFTVN<É<®úEŒpç¶·û@Ê-Âoì`·aÊ1ÓÆ£õíøişkAtn´Ìº®2g³dÔZ¡ám v¿JŠı“©šı2“‹ ÎNL~sæX8ô½´Š
z1Ãşƒfœ¬B(ˆ_éE´r¯kpåÿ)i`ÏÀø«l=ñî¦.qğ»1¶7Û\Ñ0²©ğ‚ş­ai=õ!Ë²Í›«ü6-­Şü _T…Å®?9é•öoÉR:és3{Q·]Õ>n$¾Z„‡ik5o*hnA¦€˜½Sl·BÒ=1´¯!êŠ‘•\iâ|¦™5Û0Ğs‘m„E ¾e[ù  ¨§g
ú+ ¦×"‚‘…ù<±Ğ»dO œi¨İ3½šê|püÈ_µ¦*yM’»X«á2ËÃ
Ì¸šûlmT|ÏÏ.¤e o¾ìèû„—f…­¡ñÎ¶v1VÃî…È[ï…Àã²£ïA+À7ˆ/ùÍnÙ¶OÄÑ
ÕU½r¦H ]MÚ£*“
e…›#©é›µ^VÜóÀ~ÎĞ¼)ªcˆJİ!„IÑjÚvRq>Õáù åZÚH²(õ›d}®Ù… ìz_ó•äœçÈ¨ïQ¹§ûÇåÔ³agt-ªğ´³ùX	ğáSIKÅØîˆ¹# pñj@8 ş¶aktG‡ÚIË¡íù3P‹)~n¡§¿	Wn š½¯xp@c.¾ÅÂ0õ6˜¼›1? (9;Q]BKÖ$¯ú„y…r9{z
`m—Õ5Œ-O MÁØdÀ„F;äÁµ¦u®½–QÅ÷|^lÅØ3jÀ}î¯Ú±¾ G/Ñ(R»İ*nŸ]/êé™iï¼tá¼¿ò&v[Í*"$›ÂW>ÃØçZ ²÷+@°Z¦uòMÉµmõT“ ™C™)Y·Ş0O´2gXßxÉÔ·íÒ‡öœø™Tª}îÛà@ĞN4G´(Õâs	é1ƒXé>•‚ù¹YG€¨C2£«3ÁE&¦ß^qOõX¿Íû)U&b} êˆsäâùˆ[Quiµ¯…€cK„ı ätİa¶¼ŒÙŸz
ÆÃ—›âæZ-±PÓqçØ!ğ—snSôAÉ…‘»pd:÷gá¾NÛ¬‚ì§UÛ{Ñ
‡¨çF›Låmvnƒ=…$s·r1nÔ-^Øß*û8Ê=.í4k)~ˆÈu¬ŞL)Ñ¸GsñÖB#¾u'gy‘ºv]¢`ı|ŸF8šë/–I©~8Éîü”ñ+í]Ò—*J–¹’yø)0t®ÌÉvC¦rï>(ì?b£läÊié¿ 1A2<½°&ßO‹éV­	œÚøü	¸«úefˆ½¼|ÉQ˜°O«YÊ@Ô*X_{.oÎDäş½S‰.·é³Ëå÷”¦Î¿¸]w¡'­nwëÚİ¼„øph×”ÄÜŒšºv»„¿¸¸»^/g}íBÿh•:¾HtşpF&ˆ•/vAîÜ©'WÃè•îEGS Ã–SHAˆĞš=š°Ow‹N.ôhMÑu¯EÌ¸«èRôòç[âáéİ²N[µ/iI•Ì±sOH“Ùj»‡ÒÉ–xU,Ô6@4úupš: TüàŸşJ`pßT:óQI,L¬M¼ÅşùBMUğC†²î¼ [¯–xÊ©Ü‡q\.pá“û*
g+§Ã'ìÿ®‡’
ßÛŠVÿÊñ 1ëØËPf8göb&éûí\[ÛÓ|~ƒÎêÈl±¦hôïæJT¡§Åıhá_¾—ì Q¼ëş h\‹cR/e‹KÆ%±Ô5—­èùYš&1SéÀ©êFUŞá·UÖ6WË‘¯ÓNk´Ñ@ƒÿåFŒr.¯ÿ˜™T<H%hrj§µu¼o±’«„fÖ‹ew¤û3~z´®*S¤Ìùm F=#jhUGy‘@'ZÉì2*´^¿lo²9xIfŠ®0÷1‚rÌ¨§òRqëˆ£ƒ‰,}:Zu­fÈº!ªÏxü¡$‹M;–ò½ÂÊä¡F>!âh‹d¿şÁÃ¤ÍVN»İ¦Ñ9ù¶ôyÙŠ³æĞÛVœŸ1ã	˜Ï'B=¤f¨/Û1mî¥‚eøhî9h/Ãˆ‰7¨ÿ;(m,ß=x[jÛ[Rõ|†2ˆ7§?©-øbŒ–á+ÎëˆzY}ä-ïi#Mµ»ÃFTvHğß74á|h”'ÜGeOLºU=2”QµÄğ¢¨@ &˜³\t¦nWA²—e”
eOÂûU›ãéS&R>’ÆÙ;4¬Û‰™ò™>vpfØN?17ğå)ñoE2êúbüi³Ùkánb7I ñÔ\(I‘9·<7±›NTÈíÙãÃ¾%Ğ_Ç6Ô¬gøˆïÿŠ§ ’ñ3…ç½E ½Hj•Áåõ¶òT!Hy,Ñ“]»»©Ú=véI>ôìEz,¥9>=8‚?Ì·jÊ‘m?ÖĞ;T¹täÿ]Dô×;*?5GN/—.büøœm–•å¹Âáê°Aª6‡/ë/˜ëù€˜Ç-)#ã§‘A0$d½ˆ3±û`$Hy-òwUffwƒcËîòåèaVJúáĞÖÌgcú«glºèº3.s¸Ìòï ¢1«¦8§°RÏ‹òäù›²Æs#dÕS“…Ó#)*™ Nì³¿84dÕÅ5»¯ş"í#O]¹Üg¡'!îº âğÎU
•cèZ«¥ÃÁs9!²ÓŒçØ’÷ï#|CIAÁkM³Ñ¡D«ÄsBVæ ûXàx¯˜Ë”]8,ÉÊ4¯èZƒ£NÄS‡šûÎ
'¥Uö¶/œQ |J}7Êp1İ.d¶ ±'à®§-Ğf^¤†ú¯©xfÖ+Qµxm•W§çÓÍŸ7Ø©MåÇ½°sna‚™e	G"îê)ŞºPµÕ3"	oâ?o¯¥<ôWo“js©ƒÅ@;={;­ÿŞ´Yvÿ0˜»5qAQ˜¦Y=S5º’P,â¬™<º‘Oú®	BÂ;óE³€,Ö¾4@/İbÄóÆg¿z5¿À)"o<
¶b™ÒmÉ¼ç0ç£şBšY–|Ï$¼­™„¼Õ÷ÂŸd)pÏ ÓáIæˆ§´N;öB¸Ÿ|Ãí¢ÛU=~§°ş
‹ÿè{Ş\FI«ı˜ júP#ìça5ÛQu}t¢ÕuKo²çíO”ÇÌËÕ™×qıƒéfã{&×‰Šl¹¤;ãXÙ² ïæBæy¶ãâ¹M„aı‹rñSÌ¬XÓ€>¹Æ­…µ§}ó¾ã£s\_A3Q yWr›°sêŠşc`ò¬Æÿ©y°,mH]•¥Ø«Yéaı1rØ,Ó°Wğö+»ÖJ¦sÜ„¢ääÄ}!$i-ÂÛñ€–c?£“}^BVåí…ÓI}¯GMŸ2Uh@i3èåv®6CwÔ4Ø¤¸jŒì\ğ)åxÁ\•fç_9L"@OLk&Şr®-ÿ‰ ¬Ã‘«şXI ¦>
†\‘Ó”=:å#Ó^b5¬İ>®ŞãÁ—@ÆaZgô]MbØq!tõ¢¬‹¢ÔÌ8bĞ²¿YYD—…ÌgŞöjæ\í·ªÏÜ¡£NÆşü4‚İ´ÏŞÆ•Áò›ƒŸCÅ±·¢{ñ3+{‰}@cN’»rÆŠÑ-4/E&^ª¤PÉ^¨s~&}—tÂÁ/²ĞÑº¶`ìâ³”iÜR•L°ŠğÊÔ—ZEF¼c®W… áJ(¼xÑ™C6)ryO¦`g6üN(OlNN
è+ærl·‘}8¹{°‰çÈ3*Á–ğ¬'İ_Ë•%×
QïÔ&˜É<ö0DJ©àï@¸X¢ÒZ£öøø^yÕ$,AgÕIı¥7 ¹7¼ldîZÁÇ[a¶Ú^rò‹RäØ•ÖlLF©9Ø»Ä€àT±ÂÉ‡·5ß/ú’rã« 7e#€¸r’zY¦I[ÖÂIx3U¶[‘nV-¡'Oø~‹×tÖæG¡¿a¬'F'¡éd3 ã©ïçk°
xB¥_çHÂÖ‚~^}>üÚéqwºÄLJ:…cÆ½Šús§(”ÚÏ…Õ–`–~™t¸ç×IÎ{Gf%XZgÊ6æ—)LØŠÇ¹ï[ ±IRb·Ãò?jå”4òZyBƒ°Hmuxñ&Ğ".A­’åõãıdÔU†É¾=£o8XƒU§«~2
»jÈhÿ¹½l3qÍ>|‚ıÀî\]@|“‘dLôöU™_°éáS°Qt¾‚¶8–’Õ0şª’eøyÙ/t¯¤Ôs¿ü,¯ˆ¾’K­P$@}Ø%c•?€ª2ÇÖa$Šş u
>t"¤#ÆVt½-??ØN%¦¡ÀÈù©WúV%[†3¾nuXl,tš(Èƒ|XGO£Ÿ«bÿ\!Ü^Aì¸Uğp¸j²ŸM-4UıÄíÀ¡äµÑş$¼ARø1ÜÌ#'bâês¿Q¦‰=¯Ğ”¤õ7&5şÍ­ù-š„šl3nİa)Ë…•R@ôX¿¹• .¥D²0tè'r(iá°ÏÎå.¶7=¢ÀJî6·ËûÅ/kùü—ú(o©‡x‹r	ŠËÖXQ '‘ú°´á²«ôù{DÕa¼DzıÒ°3èëÍaìÿèp´PqÖº#‘EO×Š÷ïOƒf–æ›9yáí…"+¼ ÚÖ©åueP!g±Ë&Q
â‹	¯ÕªéÂtQ‚(‡ğ§öÒí@¨U·5~ŒÚ«Er²*nÈ›ê4AÓ*ş§C1ƒô1£fLÇ,lu:ÀÕÕŞ°”{A¹-s¸ŸwDC!zè*Äb‰î{–£B\Ú”òw<BÜlØ<ÌAc‡Ék(D ·¨>¢WÊnê-a\J‡ØA4Ù…úZ Ü–I9.ÍÇ+4t¨˜À:œ¿ì^*)ZUêÑ)' Ä9ŒósHqükJ)¢ K±\ nÌ»A_Bøş,{›˜YZ$Û&tŠUÚ5—&=tìÙhaÿD^Úz¨¯-›4šdg‰$ş6®„ÓWàú¤~ ÔéçÒ*#_Ô‚C¹‘ô^Ï¶ nÅômU
M×öùâ4(´ë.nöØ['Ô‡Yg±´²rí9}¾@ªvÖãTdL|ÿ%€K³WVgøæ¯ß™®ş®ûõÛHp1­ÉêÙ²ÆæO~Ï@Ÿ…€˜,(
Æ!q'-Æ	ÙÒ™àŸ _a#ÖºÅCùßtãùyûdÑI˜ÓÎïŒ=AÉïfnƒk¾âaõdú°}aÍkÏ}Ó6™ç °/õ¢5Åşã”Õø,>FsŒ»º×TÕëœ$Ñ¸‰ù­,oğü–¦˜»è¨cÀ<E¨›øâğÑ5İ„º›ÉtJ´0 ¦UxĞü—¬ÙLh­îå2­ÓXÏÕ÷ÈÀ=.ø}ŒV #o±«X|{í5 %8÷£rcUUC¹ÔˆosÑƒ';Ø´<˜t³•­ÒZßldé
ÔcKto8,Şz¾÷LÌ:|´Fúâ©È`Ë	´ä(÷w›*Tæq¾¤ıßÂúÃEYJÁº+ñ
C–£½QŒ"Q•ğâÃÊrD ¾Ûoö©†­K 8µ~Úñ>Æå|ÎÔ¸1Ù%S/3€ı‚‚Î>C\“ë5}ñ¬äë8Û†.‰±[EwÄ!b@´Èâ° ¹kWrw$ ] ŸprkÚ.å·AÈ™©E–q-ÚÍğàğ”Dãziœ4ç`0ƒ3Ù3÷úÂ‰]‚iŠ-ÜféW¶$"ğNK³6ÙN6Ï¸šk'UË¹#ï‹ép‰P“…±Ş
ì¾É°«lÇÉLs2­ÛŠyòp¾!ŒçË…#7™ßt.Õƒ#L@'ã^	W5¿ô°ÔLËÑPi_>Pn>fg¯¤¢Ãı›‹ZA"gre¤oÃà
…\ˆl"ZœK
Œbì£yºŠ¢“É8µì÷Úºè­Ë‰6³2\ÛJj¿¦5c/	0Xücu-ï÷nŸŠ+ë‡ÙbÊö+õEsÓ8ÒæMàÊweJ:Ñ#¶rs:!Z.¼ov²X–iD¤d·;2·Èº+ó4uÑ|“èñ9j"àx® :(§„é$Ú‰‘²&‹?!š’%°ï7÷»·iì,³%ín‹Øıë(7ïpü9ªCf¤&"¥,˜SKÅBö®'8h1õšÀVE­Õ-íİBÿÄ«“‹SFÁh40r/©~º²N7H(¢¸¡ÑÖ#<Ùg_e«O7•j§Á/{Èfl‰İz÷“·ÊµVÄÖAfÆh|j5d'Üİ²ásåqIÇ¨;BÎ³ï³Ö¦›Åèó¯ÿêrú„–Æ.hvÃ,Ùg6?‘ÀK‘#§tÖ±Y$ E•>‹Éò‘Í~€.x%º6àôFCkXªuhò]yÆ»µ“ïÕ»WÀÊGÿ÷ƒ0TZ°‚©ô÷‰°¬M‹eï2ğÖ˜íp=¢‘;¥p[vŒÛ¨Ö¬‘ÿ(ä‘ÍTf¬ÅR³ÈÇ*#<Sğz5W	ğß|Ù.é,_n9Ç9ÕÊ“‡¦ıi6[w)ñÿ-Â!¸G0F•¬çŞl¡3†‹¸·z'ÖZ@Ókd‚Œ¸µJ	€©óJrb`@çÔúnÁË°”‡A$¨q
K„×"÷²©ÛéæsmÌvè¾oGøàÎF<eÓ}ÅÓ—{uzv#Ë0Ãn×5\›Ûè(Ÿ£×—4¡”Ğ©jLÈÖôŸê)¿ô’ÑqºĞï1òÄGîyhqKIGœö¼º¢ÁıˆwE)ŸÓKÍ²Rc¬aîÕg˜tˆ f,µ¬ ÷ë‚÷ñuym :-x=9 6ï‚à%vëÏºr’‘h×Û÷t))N}T/›< GTCĞ)¸Bxz¼¤IrÏºIOGğø£†}^ª«)\gÑŞÏx­‰£¾Ô“”3òfU÷ĞwÈ~æ¶b,ïø_jíİ‰ÎùdW“‡î”{¸ùÇXd#}{o›FÃ&Oí;÷ºC/YyÕ¤ô§¡4äXTç9à©9˜r¬:¾ª.¦C™9b¶H¢it†ƒ†Ú!+ä#mäªX.2š|; KR¯9„­@‘3Ô¨c%ª­÷‘ØüôÀ²ÉYFÂÖå¥AÙÊØ4J#[•œïÅïôfÕxJN£¡byFÊ[_•¯+’TZÒÉÏQê³nf;Y~Ÿò¡•ÿ'˜¡©b‚]iÑŸš›êÿ6ÍÎÀšRT8.ík–©…ÈMò©Œ÷±ÕšjY9Œœ$â{Ã ®nqwkB.$Z4,NÙª`ël(‚’8% ‚Èí"8`íÙÉCYX"ğ®TØcY¯6êôuJS“Sß]JÏv“¦úı"T·åëp¨Êú2Pÿû®!¤µº¨™5Œ@}ˆUÄ v3…nÙTi²PI]€œ›ÀÑóhì¶MzF|³†e­£ùÉZ¶ïƒx0_ÏË%c„ßÄ¤ÔÃqp~NÊ“yæRG.u¾#òÙ¦d¬îÚ<§++@ùİhwkL¬^´${8·Ë+hacá$$qçÅ…D~³Ì¸	T×C´ı6ßçŒ§™;W§®£åvŸ}ˆü
ˆ`– CEáme ÷¾M#ùááÁëXt;ö@ÚßØ°÷õÆy‡ƒp)÷ß.>oëºG¾r¨_)°ä¨*cÑ3Ú*½&YÆ*¶$²JWn‘w¹	ô5âĞ_céú+mß7–»ñ"Ê¯ûæ£&ØÜbXµOÿòt×F³õ½v€W¿8È|3±™ù¨ôÄ`t‚q1Ç™ÿ	ôÆ/ñCğ6	BƒÍGt›h×¾~€©¦`ñ‘ÉÌ	Q)|e%åúê»gø"ÛšÄôªJ~«Êtm¹O:ğ€:°—œ<bxı|T½!mÚºÿí—­Çid”òF^ƒªÊ(»/!ì$7Må~ó,x'©>ùâHpÖ™›àÎ°:˜óš­ŒxPÅ{öv9U]Kª•^×7¦G›½Š%Y8öı¿“·¬øÏë&ç™™Q)˜¼(òí'Ğ¦‹Ë‹=ÁòŞÜL¨º‰¯|ş
#0pÙ‰”ŞŒ:sÆzÖp¨ofI:zY| ìâ)L®½‘dµñÒõ¶¶ŸŸ¶-~tZ"ò-KßÉÀwVY°Äæ
*Í¨	Á+™æ‡Èh¥\7$d*¢vrºK96±Õ!¸‡?xuØŞµq¦OÔ•	'ï¤-J…I"Ë¥“ŠùZBÊ¼óği±#Ô‡fÜ"i]goì't¯.Q¯Şùµ&9İ‡÷‰‹‘Ğna
ŞÒ¯y°—É.ìAôpÇÒwP2÷€…­âQ¡ÃBèĞ¶7ºô[dWƒ€˜}»3/ù”wwÓ‘wÎ(¥¼F;›3h©JÆ†4R=Àoåîû aå\fd«ø¥Ã\Ç+k$ƒ®®˜Ë±ÌsüÊ’|ÓÈö&x`“¹şÇ¼Ñ @lBó´OàK¨şÇ  ©˜Ì\’®|»mYf:†^ÆÓÏ¼µé
[Ì,9$yä¾B0~ı¬·Òu;¥*ó6MtôF;ïİºœY‹…»½¶Gº’ëxéú¬pÅYËNvµåÛíC¯ôdG%ŞOßşæïÙÄ‹67>ÉÕºİŸ„aŒ…ƒWEÆoÿr#1UŒßø¨"Ä¯òçæ ¼ÎÓóõ\œJ®XİÄÍ–ãã­.Ú25to«cVöİQZz	Ê*v@Ã]&®„H‰`iµWƒZÊ(jPÈ!Ü(îw;æËR7Äµ9låÊHËÑŞ‘ı¨K…ûİ¼Ò¢ì3.€ÌoÃ{?U[¬ˆ[É…>üıØµ@Á¾CÅåÊ®Ñê€ ’-ñ¨,©üæšM"¿Œ¾Š@ó‡\'Š_°Qf`g8!ï/¨œ4[ÓœÎš#XmÑK|ömE,pxQ&¶QÆp¿v¿?ÿQûW	sÈòQk¶£DØlŸ"4`ú)Ï†:µ’%Í‰ \0hVç	÷‚"TÅp÷¡¬!³%ÕA$Ã6îùø‡OXvw‘ÜòLW›ÆmÄ.áë	¹sUmúÉJĞÀÿCii›µ—HZWe„C|FKuÀH0Œc;WrVJófÑH:)uùw¹¼£ŸøYk©¥Rì_ñÅÀT´—I•e`Ã`Ğ?«¿MæÆ·gf
0ıëŞ1ùüĞ—fé½¶Mx™Áîõ~ò6‚–ZKÿe†Yµ0iÀâéÿ$f”–ˆ€¬Ò.K%½êÌÈS³i¢4ğaÎ.‘§Án´Á¥L}#³‹ŸI¿¹/=¸~AêqfıA§X¢cü©7PiÏ”
[7è>Q\rµ¯l©"üñÆ×å»nWÿß¸d­SÜ(…+¿% |Ol2ãˆ€Î¾_Û9V„ÂÈçŠœ¦é9Ñ Ğ‘ÿX÷_wºt…UKæ™µs6ÒUf`JÔÚ:ÌZAXÀ!h|„Xşq‰4/äKŒêR]´cá·^KÓ`¬	M…ß2£â’Ïv«S¾†ü’Òào’§›'›hPk÷T¦è‰Ø9p¢{g¢ÇÖ#÷Å˜úP>|{eãQä_©ı¼^ULğ®¡Á,ıÿ«MÄ±’®ká³nßèº>Æ{º\^=“ŸÜ¡]C¸æöÔ¯RÙºÈîF îš×ã°£½q®~ -hÄÉn~ÿ,¯÷…âziX¹b¼Là+Ë´Æ7ÉÒ|ò]#¹ÓòÎâ¼ÏdFİxf<“ó
ÔÍ'Š!è‘]ÒÙªC4×Q5ó&1‘„¿FÜ+Äéï¿ôíI|oÊâ µVßf¹-¢ãyc®—ª—š—u31¥ıInÒ
±nË"7Ó’İùr¿¥Õ;:İÂÎF+®âŸOÁKTğ xpñX®ªqÁòi©FÏn‚«BˆR‹ÀZ6"Üh 6¯µÂ\ˆá¸©=ÃàÈ—õ·5;İ¼¡1¥‹w¼Ù©œ	Ö´zµ³'šf—z¨ËYÊpL7Spü»½s1j­°<Q‹]ÀºkX/ˆpCˆ—ËÖĞK"Ğ›¯QcHÂ)ë\R‚7‚n Jô÷„aÜÔVğ¨~Ù©7ÙR¡İ¼Ğ¥l¿²’!|%qËHğmäš?!XFÔÖ·³‚Ï£$îàæºKú„Åê]x†VŠe
 ‰[Ës`ãaı¿gù†*@”s1˜É6zdŠo<úiŸT2w|Ã7\‚Õ­ø9²[÷y8®ıP%ı•¬2›3‰P§ù¿Îñ·pGÉ”@Y{5ïxGp±ëiKZD‡	~§™òú=¨Ó®çÌ±»=c7RÉ²ŸŞ~¨ †hñÎ¤Há$šÙæÊYM!oKn”x˜õ]şüZ€p*ÆÚwÖ	=8k³!;`ï;Ü4IubdDC!ú=yãƒ¬»R˜Ø,löó}ıTàÚfJe½™E¦ÔıÏBı67æ"ÃZ­Õğâ@EwG¹´|vnûû ]AÌUİ’$^¨ø—BœŸRÅ°MPÆ®ñ~ù·‹b:B¹æcA 5ğÄpõsï•Ÿ)Gf•y'Bµ µ¤u	éà¥GÍ½²ÆdéôÓ;#X¦œ*’ŒîÓ+–÷ğPÄš
ƒõ;?µr!ú¿ÜùÓ‘“†½·B'Èá%²?Ğn8¶¿˜ÃİWgqk‹åşjÄ\ Ùè¸ù¬©D¶½áô&Z_·îD„¨h?8e7
fsË‰÷âNGfªJš°ó°ºiùj®’vĞ´ô·ÙFÃÒğ'ÂÖÜDõ¦ôØW,ª*‡Û“*·@;[©~qÍ¦
øšÜu¥1ÌÓfÈz½azº>E#ÓLvÊÈğLZj¦í,½[çB‚½Â%¸T²ÃñîÇFûºvPkÜATü´®iÃBø+Wlƒw4É[|]·^“Ğwàw¶h
ç-y{3Ä7£ëÇÀâ)´/]³”ò†›Ñí	åêÃ˜», w‹×Ñ®YŠÇzŒ;Z<o©EM¸yèJx^øôñgå-L•5}œTps6RÙ©¿Q3S ı
ğpÆ¶½ı¤“gèşÛ¹O|WĞ+dğF8)ÌÖ†­˜W–UôUÔ8š~?AáCU\5¡ˆÚ÷D¯q/3 ³&İw^DXé>¯àe+=WŸbæøLÂØÆ5>ß“»ö¼³Mºe¶æ>«™ƒ”Ç¥Û_oİ7´„¢(ÜsŸCc¬JŒ3In•½õNN~©êIo@¥-¢t4Äİêİ®ekìĞ®ü/Ø8pŞEšIFM§¸ä|Ã«~¤gÉ›ÎKâqÍ&ãïÚ‹Ò}7z8#+¨›°|ÍšÄ¸ÖtŞ-‚¸÷˜UfÊbcÄ‚½zgÒuTH#à&Õw­ÜŞİI–™5É.İLğî;úÙØØ«8”iÎÈ1À7×yE(Ÿ¤©æ>ãT·^á>ÑXÄ³¢çş›è}é½Á4å ÃçvÚÒÛÃ´Mß/"ƒ¿ù”Lÿƒ¦Ôÿ¦&r ÃÇ2¼Ô_….ç%ÂjCÈ>**şZÈi¢²+şÀ©Vm(íıqj¾£ì–—3V#:ºCÉq²áët	LZ€çìÄŸ˜ÔÀ÷;--Pú+¢¼­çËÈö|#n?x‹Óf[Ï#˜Sí´(ñ¯0Ô‡‚\Ê¯•5~*iˆÀÇ„k¶ÕAbqÎd$.†b*V‡˜æÁæĞŒ¨°Ï?2Ív`¦œ©í(r•)lİÏ©ú‚c`›‚eEoRŠ¯ˆ¢
Vº¨E‡tÇĞ{.,Z–DÂ]únOJe õZ‰{Â ¸úN¾ãFÁÂx§#&„¸éË3ú‡8$ï .–9œ}©Ñ .á¥”Œ“•”gÈ‰ö’nŸIÀU5»µØ(ØVF¯x‚'QDjÑ4°Íxÿ}Kÿ¿As C˜S²hĞ–(ª¤?ø’+Ä¶ÛC	œ73ú‡}^ƒPÚÊV¸gBÌûÛ`mO7„ÃY5:<°§Q2‰‰‹M AÙ“†UÌ¦kĞ¸˜•„©ær´5¾F˜¦Th¾üe\ŸuHn*E—4îZÁªH¡à¯rÌ£®#ë¬ê·Ö¿¨XdDÛwoN.«ºëP¹/£­9'ëoò_6	œA&Æ%³½âÙäyöVA"¡ô	·R¥}.t 1>~™ÂDö«"ÏS¬ìÔ	 (aÌ<Óƒ?¹CVØ=ÕK/ aI?Æï¦×‚#<õsd4¡,4"Û–ğmÄe'±gÏjªD.¶ÎxTá	°ôıŸé[‘ÌÀ×ıÜÂV!Övù¥LÅäS«5e—úıNİïÒ|‚aîÿüÌECÚ†÷U&nr¯İÜİÙÕQ”lMHxğ˜W£´Aš^hñM
Š<‰G$Eš››²²|a©»;ùó´ÎÂLbÓğñpZd¿—o&'Ö,™Én@^­°›…šƒ¡%_‚4e;x½2jKz2ó™ ©üIàd)ç¿äÅÔ(rW·uF‘×(iŠ¨®Š­Òc”o÷_~ÍêŠOb™‚‰®±¦äŠL­ÒwŞdÓ—KÿÓÖ‡Ó¯ˆ×üÏ•Í«½5}Ç5¯*…XAÙßïwxÌ=®iüä[Ü
ºØªŞ©1µ_ì´õÍ, C¬tæçŞ
yˆ±³ŸI=†ĞQ°Œ™9Vv'ó–¨;’5ÙÒ`õ\tÍÄ|‰†Sœ£‡7m`.·UIÌ»…Rø‘–Ğûv¡ûøêoİ§ï'Ôÿu]—ıÉŸ$P[¸gGBÚäÒµ…â|2íÅPu\ˆ]õ øíÄ—sWÁË C8òĞ‚ğK	½UFÛOD¼ŞU$­Ïµ”T‡*DOö·úx¡-Yï’ôWñ¹ì—Ü²€GÏ?	î±ÜÙáÄĞÄø`ëtà(DMîY½¹•8YŸ4xv”m±‡`¼DaÄèCY¢R ’•–—P…ÁÄ¹rß^WÁ¡2ú&fµŸ1¦\úàV7DÒf®ƒµLË‡ğş”cTx,YŒ²9¤{Fò#S:£Ì¨%æ«©ôæ¥¦ ÀD î€ÉóØÔnmõ]8f1•°9YÙì×k£)£î´(MìêéBH¡X˜è	NÙş|ñÂ’
L Ûj"ƒüÎ´yÄç.ê…0:uzÉVn€a¸†•[Àƒ†’COö±±8ÂµÙJc›¿p%¡8ZÅõÒIŒı»ÊÔ.›˜ÿ²7ÌV‚Ùü£iLGf‡ ôC­U¹hDñèAÎWŸ´†å%}³ˆ¶¤6‹v¤ùÉŒ€‹—3Wí®6L€²Ü,*ÆTÚsdzÌ©«NœZ,i“G€k^Ë i~'X'"[ÕôoÇ­>Æé°;Ñá_»öªHö	ü<#ëo€]X[ö?÷ŒTà-X™ß:Ÿ“_¸,²`´‹ "İOV Ú4ã@İ738¥|0ŠMTêÿùº‡¼’Dr^]Ä×êP©VOÚıF£àòkĞ·Ñß_ÂôÜ
IâJì$ù~°ıŸ²€<aü[Ë}D‘Kò‰	œıŸ€ŸŸYä2ˆõµÜ¬…´Š0t¢µ2Ú¼†9ûë¯ u9éüêÜBRêZF3>íÒWR:ôÄ‹ÌU%7£tİA‡eáw $D·Iœ·ßÔf÷Ä2xàâ[ƒM¿-ÖpTÉ N¤tC²XaŸ¿É
d`doé« Z›¦.PÆ¨şxT×ï%”dáÆ—şèíi{@få$×'W&Âq"$tÉ¡ÚºgË‹i%»"†Â¸Dšˆ\T6#šXÙ¿ÌŞ]ÜÉsş“½°¶»¹Èm2†yct	3±	˜*Líû)ùtûR •¡<îŒ ÄÅ¿°ü‚½¡ÅIå–&R/¾aT¯¸G‹nQt[ÏÔ=’Ï¬UïÁYíÆlá})Ÿ>ˆùÓ¨ÏŠy¾no‘¨ÁxçÌ=B[P8&/Â†P	·BÂ)6Ò‰»ÅC´š1¬‘Àø…k¶ß¤Ï^P¤é)€Ğ·T>Äfƒ"S’«ŸC‹ ‰I±#2u(?÷ºo.yŸş	Ğµg¾£>ò®ÅiØà4>L’Ô»5G"Å×hLMÍÛJÛc†¢$S<l¡¶:¡.ID”ºe	”æ}¿¾¼·ì!do¸_îÒ9	Ò×LÀ’¢†LhãÆy$	zÆÃ´È3¦²7K‡ÿø‹-œsow €ú0‡ú§şc{a`Ä)­ÇûJ:h²¬†øß3Î¯äŸ—@ÒLL²¼î]Ë€.[¸$BÌ`q%ãƒ™Á¸j@¸¤š¥Kòœ€ôÃ±şYô‚ïâKà=SÙ{†%ØJ´úÑáS¸¿Kà£“üx“bø!Çñşl±™YW·‹¡Tuı?ˆMCøT@>ÀŠtÒgï?êí«4k†Û5†û¢¦"|”ì¾?S¥½öZ Ù›û·°Pò~TúDl!Íd0÷z`;»¥€ß`úÇ¨~8`ƒwÑÑ«ëF)İ²˜¬-­ÖÃûÒÎo0Ó9pI…‚Nf»t|õâ(õ^J@ƒštå­¶1¹?VhÚ°šÜğ¸¿g£¿ÇcnùÓÉBLÈÊÂtÎ(¸şœ
ãµªé*ès§Éë+»«Á7Ìœ@S/£Î˜©–wÿÿ®:u=÷D•µëX®Uíâİ6Ãb3eÕÍ \0T$Åb´:
‚°ëÑúP§eXO®€ÈÙXÊ˜½vï H!0U¾@Ó1éÀÈ'c´ü‹ØJ“ˆ¯ºlè¸Lë=’œa˜f’]'ˆ¡)–aèê-ÿ[kITEıC·'ÑvãŒKL…í´Š=Ø,‹k€şa©vCD°’šÌ&sşšæoPf÷÷6DÕò¨<™*oR³jè8˜$§Ÿ8g¢•¹Y¬û-Â<ÓWñ<t~ËÂTR¦õÀL:VV^«,‚ÆÛ‚hŞ¤iOšğGÄvÚ(ÄÄ12ì âTE‚(ÀÙ:ù)¥î²vS‡ã™";ÖÍ$3c:ZA¬<igªI0 d§§0ª=¬mT+W¬ğiĞÖŠŸ1À^V…'Ú?c	>B8ˆn±¶ƒ§Y)Tª.7qu²¤éŞwz˜ LRæèêRšfá†v¥£ğ VZà¡Cætx£x[TF?D´aj%

Â|Õ]\)5Ü3?~ãºô­ÕÔe`[îå5İŞ,ÓóäuƒİEÛbuì5Şk0¾­Ÿ{âã> ÌªïìµÍ•= ØªGøĞrPV*®¼&/{ºå;ù\“¾-1NÔöüİM7©Ğ9tü÷÷8ÜÆ)—…†N-q†šÙ$¸íXò²È¦™ØŸPQãÀ9î†ãE+¬—ã`äáO÷‹‡£2 ‡ÿı_ÌŒÎ«ø=äªj%(ıˆú´LÌZÌ&eôFwPFÒ‚ŒAğ3¶µ?Œ!Ìï—­"¿!¤Aq],KÎu¶n»îÿƒ˜«Kô½Rï+}È|WYÔú9Æ°WĞ¿øH67zs†âÂ9ŠÔá7·ß{ktw¨–YWÏzméÄ­Â6 ÙH¼‹ìóRî’ÈÖ6p-6åpÖ½EIâ{ÍckÖ<UKÄ2ÉŸ4»êß¬²9€sfßa¨ğWmÛ9¦Ê…ä•²8b"U¾(—³—‡âÅ7:å)·­×/™ght(ì£}$y^1† bRòÀÀõRmÑ²/®W¨ş—Q ×‚ÎãÍ°½ìCËÂMd0+ÜĞ¼ĞMK{W];¸uV€j:îñ–á<¯ºTu›VUO³°&è›â„Ì+Ö‡Ûèzµœ7˜JÒŒfÔ$ÆŸP×îd|L5°/0‚Ğô©#&\4­R»¦²€Ù¢€[.kh(Ûß£¶úÑ;ÈvİŠrø6Ê§°äJÅl`sÊ:A-µâ!µÑEgïH»Î–&’&j=;±|.‹•î~|¬¬€Ã{+¼‚gfvÌÊ*âÖŞò«ö¥şeÓ
3VğRíi˜r±F¯
­jÔJKŸÔFY– VÒş¯qÅØ´ÜïÍ_ïš˜È`3½<®’'Â±¾0ÏúÊÎt­Ëåƒ ;}xwl0›F‡–µÄFe–€RıÕ{^øy[D#O›î°úãÄ$¾ı,ûÚkZÇŸ< œ´¾ßè/bPk-¿FmF@²…‹iYnR Hÿë«€‘ı?Ê0Nó{Ç/1 üR'V
aº“¢¿ß‡nºtúp(”Iµ‰·gÊ<ä-±õ„¡Çx’ÃÇí6p„@¡XôÀD¨ù‡9©Óÿ3t½ÊLLÊo±ñLo5U>†ò^‘WcÑ»lŸ6…úŞ""Z€³W8†–ãÏtö0	¦P*bà¿$=Ê)D ÏªzX4Ñš°gê›A IêCmü«l˜Pï3¾µŠ=ÍHTyÇ–@)—Òó®—<‡±Ïè7Á    ~“vÌ·*Ç= Æº€ÀÉ„R±Ägû    YZ