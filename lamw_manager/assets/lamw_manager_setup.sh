#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2115329168"
MD5="b6cf70828c966131bb860222303c4144"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23412"
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
	echo Date of packaging: Sat Jul 31 16:37:44 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ[3] ¼}•À1Dd]‡Á›PætİDö`Û'ç„ÏOD€î—
Ç_ü½º§:¼OæİA+(t¨†¢x›¤õØÁ¶[ğo *ôà n‹G-Ú·{&®õ5ƒRı¨hG{ü„<D,7Ì9u+5ù¶écŞxõ4AÎßI$í‚z hqfÏ7òßV/§Ù toÑbÚeàøtCb—Ïô>•z”èö|W©†¼<%Ü:k6ÙëHÕ™<ª‡tS~V&~Tª©ÿš«ÖÊcOìÀwÎë]ÁÅññÆ¿3|¬îú{FğÜØ+QxvM…=——®M¯Wá1{ÛéYá;0VÆ‡àßDzÌÚ—§@¦ƒWià¤¦ÕjnË# †p»ç)”]G%¸s|ãQíŒ|·?ÎoTÑò{Õü)—ìK´ÑwUÏìıÆ\ÛgA‘˜ß7ëQOì„¿uõˆÀ`ç’LÛ—8pŠªø>÷Ğ)š0E¾Yş~ÙU»¯úHjâ©‘§Écğ/†ĞÜôGÉØ‘’ Oñ’§¼êÎnÃêœµ<¿	ógS`˜ "&ô)À6ƒãßÖøÂ»'øé_¨"ú ´EÉşï—T*™Ì˜vÇöÄ´±­–ÏHÀ~Û
OÔ¢Ï­)éOçì³ÌsºØ®½vâ0,Ñ43¯çÓ>/,¹Äş€sÅ£ÛBªkœ¸³Ğï»<+½Ü>İ;™?ÇÅØÀ#ëË™L:”f$fO‡n}_µ8á1û©f›¾%Ü”fI¹àèåŠ}Ü–ã^8}ì`vêOá,·w‰q#¥‹ê4	]Ö–üÃPDwcÌc›ÁÌzº”“[jXæ	t=2qùÎ·Q÷_ªµQy‘nQ8­Q”;œ»ŸÊ;ö%xjÙyd±ç½0H³˜.
Ÿ,á¢2 ‹úè:ØÆ31h#QrôæG²9‹8NÆ8Ã§ˆç$>éXŒyŸ‹ˆ(#NÕPn×Ÿ~ƒ	Ïİd¡!@–S­5íã»B©8°S.ÕÚàöc—
«-²1‰âÀS€#gKJB“‚¾7ÌÇí¿"úqo¸$Ì
[tš`;Ò«â ¤¾ãùti$[UrîÁım÷c–ñšê÷\±¢wPè
éŒº"=ÀştÆä¢±p+Ÿ§’‡ˆLIJ†ooYçz:1±VÂãïıŒéyJù¨¾?ŒÍˆÄÜÚSÇR-™ZM@(İ/
×Ú!óş­Í¾¡ºÿ1[wD	íÆ-q‡:új£y/ğæÿ5áÌ £'¸·Ö³Zí„«1oB>Ô€Û$ï4ş«Öákö¼`n8‘:·n2µB¬„9­/Ë¸½¹Uï!ĞLPjiîdI$UÎÓÊ‡ÓX/˜Ÿ åı=œ]áÒÎMI¥/eÖ¤àOë²Õ136C;h 60ş—©z.B=§“ w)soÙëîq"™RÁV&æ¶£Êmœ”N”9§Ù[]¹nGèZ;Í|ë¢k¡vÉ¹Iû”L–€Š5­™ô¡íF×¡º~@óù—¥eªú,X¦³ËœU^v5-‚\±ã,¬sQz;
H±>½ğ+œa±n[éè8}Õ:[Œ)ãk)4+‚¿ÄïhÜ"gÃJîGœ	@ÀŸóiß­ªé™¾ƒŠÁÎëÄf VÙ#¤ãt!8XŠÛUÚªr İûû«?p¾ÿµÕo³bú'H¬Oİ¨“Ò„K"Cú*ÅM’¤øiCÎËĞU!M8Åêá"DÙÕ…ÅÍ6a æWlR+Z~ºmÌÃÌ ğ’ipÓÈáP	
G{¤ıÉ­¢¼µÏr^¿…ïÛ+¤ÀjĞï nÂFee'ÍüsÉilM±@
ç`¾æ´Ğ!U¡{.H(^m	b–Ş,cûšA›È…c–Õ¿îl70H]õvé¢¥: «¸Eo¡¿KÇÊ~¢8ïÇÉşêh}%²Fg—2b«OYÔ`—c ÿü¾7Õ€ø£»N@Ğ8í˜İJSƒd‡ñí~­cX±Ü]@İòv2| €¢AìÜìYL.t˜:JFHµ†‹‚7³ò 2³”œ:òYøíÀ=6Jf'“uKÒÕùI¥D!Z\“‚½‹ÉUOR¶0¤È %¤ıÄõ"šÅ¢n£“ü!¸NÑK}:`¼¯ •4œÁö5ÄÄ1GúÜ±>”
«0ÂÌşLÎ§¿›.¸²\§€‘®˜ûTâ4û’İ[$BTùÅt>Ïûè‹Ôu…=}tı¦£YüBUe7 [h…ê İšOãd'—ÏBÇl?: `ü’¦r:"î©dS6ÌáNnB#%€P\[o·œu–Ûyõ8Á1fı0ª—®Ikb¯+C,â	ñÃf¾íÄ‰~â£®4÷ùÄéHµÜGò„z× Ú´+FêZ&ö,§Æ=\œ–‚LHá©…+´§0©ÏÙ hÒ…r*œÇİµ¾¹üeÔSUÜ§Š–(Jù$0Q¥%d&FÃ"-scæ¸Y¥«=k
Zx¦ÉÈy*ìãşGo)KFÔ³ù‰+	q=9=U^S75¥Ş¸¬œçİ«Í›?‚Ö,ŠPt€} —şlv-ıüË¥Qî‘WÄ«@A’bß3†{£?hPˆ
Ic[IBfõğØ7¯#ÇR€ävGÊiÓ7”ì€–áı¾(^³««›cgç®#ˆ”MU<‘‚Daš¸H.p¹Ùchk“];,®æ{úó&Â@goÒÚIÌæ_í¸"´§x/ äújn <j\T…X‘bbğmuÎï€9´äº#ÿJÅ”_Vşm*«B®~ƒş¨Ÿµ˜Š›ÂeïúØÇ‚}Úu-ƒP+¨c«,•-4‚béÕ oè÷V
 Yuç‰¬
ìGö}ãRR¾>ÿ3ØGìOaq[‡³(Dìl·æÜï©Bªº†X÷ÁPFõNŒj€©2b2ç‡*q~i¹MşÉÇV>ÔpÍ|¡ùËªåS+ÿ ×Ÿ+““®Á
‚„s3‹Ø˜™ ¾Œ—C–OÖÌw3
.ÍÀ 	„j‚n!ó°8¬™O6‚ñluõbµ¨#4ë{äíÇníÔ|8JqÆê¬Mæ±ë–gS~Ö{1©d&şª®‹‹¯Óè^Î²¿é£Á„šÙİ¤¨F±#>Óuû É„2á½ºç¾ªÜş”¦üâçõÉ1u |xÀ+ü}\±Ú©ùí4Ù8 öãŒ…d/Ò‡ì6FİGì>µ nâŸ"*Z£A¥Å,ÚíôC(’ÖŒ¦¬6£ß\¨k)Á•¤ZÓõbz±Îc1°…Ü1ã'AòÁô`I3Z–TôZJú¦=		ËÉ¥öÍd" ±{Dì‡­¯-Âæ
`ß{˜‰îvŞHQ”0š$]‘«†ò¦õTäøğº¯5ù\›Fä2Z0µ$)"i&vÓt“ÍÇqÎ¢jë‘‹‰Üôs[„§~®¥ÿ#4õ»×ğ-›ì¨PÈbé[˜`B>j"Zü´Û‰?«v”a£ÿnáZtEY¾š%ê§È°ÄŒadÆdOy\a±ÎH&rœøhV&´Uş’:úO†×…¥äW»ç^e½.†\¦†âe˜3ı|«ü¸ĞZ×.ûu¿8èç,ñ»Õ÷”`°«êeå=4Õ˜â¨8­©‘Œ}€??\a1 ª6YŞ²Íå˜»›.OÛÈú„²êsk÷¢LKo%âi(çÎ.ÔÏz #˜(õ¨›|ËØµ¼a“IÍKb5¨‡`ºô–ÿí<~Hùæ[Ş·Uø>(lÍô!Ÿ\©rJT^,œ6öï®1ÏÆsØ[Qã =C]{t}P"Ÿ¦ì¯#o¦h@€à¥Š¡l›Ä„±³Ó7rİSõÀg{­]™ŸÇsäq^}­	OäéGÆÿµéDë‹›·ù7«8X#®“š¡‡]U€³:EìÁ\uÇER},j9òH«çÿşå+Ì ëÀŠ|.1)Ûº1œL#\U2ö	;E4Gó¡yTM¸ İ½œ––÷¾Ö\]ëÑ.ÁPÃ Ïğv…’10]øQkáò
„æ”n¿ÏÌyÀÌEoâ¹Ï<§™#YIËÛÚa$İ
ºHğä–áàµº*5u{g:ØøW]D9’‚èüNbül9ØU$“¯¡!‡U¶Î‘^g
« Ÿ(ÎïB±`ˆ_^†¨_}‡fÑKÒÎ—sm‘îBÀ„õ0ë¹˜[2[à1XT>lw¢`xÉŞB˜äJ-¶e´L÷#ÏÂŠMÜÒ"İŒ¦ÜNæ×ªFÅ^×q%K+•ÔŠ#æô«¼qçR`ögb¯W)l—×IÈ¦x\ã¥_ñrC3¢òÓo0•j¦T8»İİ›HºµğÁzÑæd­(|H„bZÖÃÚ;#‹l&h(Ov…=´2X›\©–¥¦e­‚ØLQÚL½ÏÉV1#Q" Ûlsë¿ª‘äİ“»Ü’]¥úıšG»”Çí -­¥Æ†XÂ¿W:¹\y›PåV“
q¸kyêeaCõñ0>8UWÉ“-…Óxñìè¬6!à'nx4zoCj)f´æSw6\ô†MtŞ€V²/ÎãG Š4=ñ`%ûÙÏ$ØÑË5…Ë2meZÛÌşóÅ×¤½ô< Õ³0R¿E°ÕÅÄP­ ó31˜õìb_î¸‰u0»é#7‘ìöĞ…2®@•¬‘ ÒÂ‹€Kô»ŒÜcŞL5ãÌSô»a#?Œ§¼ÔBl‚óLLwÖ »å=d›ÿ¿d–k}Ã=ùb´ğ'¼ˆ[1BdRñ6B.›í½üÇŠ€Lùô®g6Û°”{Ö£1T¤%–ªÕex{(ßJGCšlÙŞ ÈŠıèáP×$‹´^rÉ-]Ş›çÎ#µ¨e©.ø7ƒ¤"uvè¹¡<O	š\/
ßÊ»äh0åO¦Úü³6«B+HƒÍx<“»ßT¼hŞÖEÆIºŒ×[±¯ösdùçC?m¢²Ÿƒ{ªºª¨Ú+ÉjËóGãæ†;¼Ø²¶½É2šS ×´@‹®çİ™ Ã#7 ,ôù¸wÒVg T|Oø¾¾İÉEŒÌkuÇx•—”Ö~;ñò^”ä]»åBïŠëÿÜ!Xd½3m67šÃëÿt¥r+sõÄÛ0O
J¡0 Á&s^"ø«ä#¶­K"»Ò™µ#c%. YGFoÊ—fíÙ=C¤¢Y3²`h’¤WR>¥›œÁíˆİ_fPöZfÍƒ|æò¼M)”\àV=`”cs®<ñ¤;ík¶ÏCì9ŞŸ!‘Eâk¢¡/+´qL$qœ¯d
š×PY‚Ğşt}=•}ŒÆÜÙpÑn³¼Sêzã…zûÒ->…JC°¡ç·8F‘)‹‘lV7aã=H€Iğ`*Œ9xœè‹”*v	!É@&Eà.ÂºÆˆ^5qøU`F¨ƒ:RÎ–„¥À“Ï’Gj&ç€»dm£^5HG¥›ôXv|¥)¡éŸX=NÂµ.<®2½—‚WFáXOÍpâ©ªúî¥u%SÇŠŞ­@0ûâ‹ÏÙ=¥Àd'9¼×RËQĞs³Z‘}ƒ|=¡	òFü•¨(ÓbíIqë½Ád'ÃÉRÁwµ£$=¶Káë¥âËªX†)ö»ºZ9lz”Õ‡Çıœ$râÎ¼ s~¾e~ x˜ ÔpèWïBğ‹-Y¨ÍåeÓ"bŠPĞ„n_têg{ëñ„.ü‘Ô²úò{Ãº÷¢­"Ö§9ylMÂú>U‘HLhË†­æ{:ò–“!FI‘V°µC5äF^^–áq”šÌŒ!õÊû²g&ÅfF„»Kûü2Ï”²û‡Z@ÌDˆ›º¯j_üt]Ì_òjíì‚ÄYM“„lÁ)#è–^Xˆg… ø*Dµ»@}b€±ü†r‹Ój¢.\aÛuõûÌgr}÷º•ñ‡Ùç§íS¡° 'uïğ|O®Öšÿaav»wÜ%ô¥š»Â˜¬˜? 5dº€	0†O¦+tòˆ`üÆ9 .˜¥+Ü—/şJ-?]«mÂ÷ça>ÃnlÉ:¬vÙË?DÌP©Vs5¿øt0G‰fuÄ¡¡O*·á|»ş±üÆ6Ñ%d›Dû'6Óä[b'p:î>Ã|P®÷v¸êçÕ.]¿ÑÿÉJdG­xø8ÎTVzÈ ñÆå)Ÿ1¾en|@›İä&¡¯í5á¨$JÔ¶F2W‹sÄŠ¼àæA	$“óBõög.uŠoä#Ì´ô”•ŠÎÓÆD€Èáa>³Y qHo*¼„uAzªHj÷}¾«öĞÈy~$ö&¼skÛ‹äKÏ¦ÒÜÉ®. L‘İøÀ·¤
ÄÊËà-èCQj«Æ½<ÛÇCøšCW]¢—ö¼œû3“£¬rÅ“3âñ„©ØAËİlØK-N»,˜·.Ø¾ÂG÷KÏ€Û¹“"3f4 ÏI‡#ÕCîº
càlÚ Sk‡.L óÍf¥ŞeìÑïÔ“ú9ª~#İ:ÆbÎ¿y‰kÁ\å	QŞÛã™ŸXYò$ÏiJ}ìœR5ÑÒMFj/2û¯L±l$şXÑïÙrÍõ´ˆv¿ç XQ[İÓO J­Ú±8%D°øú×fä V¬Š©
7è&
ºŒä\uUĞ4ßªDAùAjŒQÿj š0ˆé![@‹~V}ä™ÔÃà•¦ùe­¼¨£´st:AÌiE(}'Ü vrn‡œ¥82&kŞ‚6ç§Ò}n4¿šlp‹Ja50V4ÙªN×Dn
)=ÕE€ŞÂ©ƒOöf'n0´2¾Äè¹ÍIU?¨QbÄ”†•£”·$bæŒ~òœIè-.ÉTûöop®Ê>Ø°ÇÚw˜­0J÷<Ÿ÷}ù{!_-r`Æy…ëlƒ]<W÷O#h•ŒËúz¤¯°ë¢ÂšŒÌ‡Øu˜ÏmG'H–­/?^šÜê=^ÓşN\„ûªß´$£@9†#"©³<&®[jã±‘úÃ÷©ñZ•·ç÷ã'i¤dÁÙîs=o5¬ ½â“ÿIÆ]R½Pá	Ğò1Afu\q*‰Y»œAğGuÍö#³ÖBĞÛnúÕv?—¨%-èİ"Zç…tã-ÔQ‰¡y(Íğgò”?´ däa¡½˜p’‡ëA|j'à:…Àç­3`½b"–™¥°†àÁÕV”VOî£CÈÀÊšõ0G„ı±|R»»·f½¤ w¿iK×ŸX­9Z„C:àît–Å ÊiP.ø~ÀÉ÷‚Úª¯†¿_îô~à„Ñ%¥$Lÿ·ÀşÏæ=Øƒé97÷ œh=Ì]w0^ı‰)‡UÙ7È½êÉ&²–Ë?„Yât—æn`Ê5è‘~ï}ıMÒ³gb™™çÓOa\À…õå Ï¶İøC‰oåo,VÜ„ÕHnTùÅã xû”Î1v×)Ø†‹/`
¼|³²ÒPG:OaÜcşQ zĞKµ"ß«&òÎ}¯Õ­/Vd]ñ!q·®@ìÌÁ¾¢’ƒè™30
Ç­­ô¿ó nÄÑz	£Ä?ÓQ-êĞ«AH½	p7ç¬qRX»ÚwÜÖÑ ]Ë28›ÂŠÒôT\?)ı£É`Y¾Ü=œº'£¾¨öŠ)]J¸xÁN6…³ö´¿Òp§=àCúX«ÒA3?ÉƒUG‹™hÊX™_8`hHeêhÌÚü’,0gØ­~Ôll‘òk»w“YŠ½œGº«$¥›ºãjÔfûò$@³ñ…ÑÒÍº¦šBµ? Úüc•!Ê…€
Ç¡°a:me~çUVŒàŞÁÍ‰æñçÁtÚ¾?U>HÊNn®hİçrW¦5/à(Éa”fÿA_ÛMscµU_»ïF%(©u±A…_YtE§ıìqüş—ìÜ	&i«¨Ãh­ó\]*´Ö˜fm¬{€1ó|P¶gÖI`,ŸåÃÍO)ô~î·ºâÉ4	Ñc7DÈ•cªúQß•_$R\x>¨¯BL¢ç¹Êªºœ
¸´ˆ›Ì[¿ß'ƒ„äEóçléÌ¾EÎ;^m`£ ³çÇ&÷}N*ƒ'—ª9Û
òV‰$4 :¦º…8Íëö°†]¶
ø®MÂ'¹~^KÎ;vè345<º7¼Ä¬Ñ¡ q±œŸÏ°ı+0;¼Ë1³`Ö\‚§GW¤4Œ;Š73÷V‘]ÛùàèÈÚµ´¿0•e-ïg=ş­˜aîŸ!Ìuğ´NüG¶ºÎÜ×Uh®€Üßù ‚Qèl!à›ËÃ47¹ï‰ÃrÆZ-Qb“HïÆµşæF§ ‰ÎV=Â×÷N¦ÚØ7Göã$xıl1¤&@Í<¥U¡‰§‡>	G…eà6´÷k1T
†ª©µ¡¾a0$âÒï]c¿¬&gt ¶ÉÖhv9ÚÎ¿l…l$ó
 ·Ä6uà9“£O|
}Är«¢œ¨Zq¹ìSæ…Õ VğÕ¿N­PFè7ŠÏÜ‚ääÇE™­²#^AúØÖ[00°Ê†X×çG4àèËñ3ÿuÊNb’,w0«¾TQ)óÚ¯‡@ª¬C¡#"¢s–Kaİƒ{ pgúwU[˜ H–Jm€şó­í/'Äõåï¥°ÃZö=méäûó·â0H§ û³°Ï¢ùµ=?ÿR·Z¤
6‹b‰âœœ§÷ğò»l àö#Ê±|Ş‹¿¬¢	-•mô²û u:«–’öĞÕ&z½Áƒğ6ÔnÄv3FË,GÄXçH·3>ÁBó?*Øùg()Ú-u#`(‚¢_ó0]Cúé´nî×™! ä0y&ó¨ß)ËD™d±Zí±b©Ißğ›z°Œ	¨](6•ÎK®‰†Ç*SOyô57Zœşã)¶#o4åRĞ ½ƒxúŸĞ;ÎQÉæö¤oâ æEãÛº;ôÂÊ³Q 
WU`LßJ£ôùuóˆw-Ú¢¥J«®Bˆƒ?Ö9ÍsœÑ1ö¸S¤ÒÏ”q´ˆOzG ^¤‰a¶Á}Ihóä˜&%V„Ÿ^j9kÃØj€ªw½—UTµ…1îÛ@FÇ[ŞÚ­ât@í(•`Ì`ØümüovQº·â˜K¾Èw±­ú-xI•¥%#Ò¸`“Íé(añDŞ§Ú¢GdØCİ&r ¬SÿH$–ÀÄz,”ÆY>‚}3{o¹R”,#[¢™õü£D.´Mšw‰Œ¾PÁ–ï¯ûWÙÍ:©X¶Â&Å\äÔøìùe=h Ûş×ğº¬ë´È%*ÉƒBMLåy7T°(è( E!=0‹doZè™Àû¾öë¥*Ïé·4-åGM©˜c;ãóÆÌ³IOHÆ•Ô9×ü+$P}D2å¡p.µ†²Ÿîv"â3"qZ«»`œ\•ÙC½×2‘T@ùÚ)fo×Z™s«°oWŠí}ß`G^©¯ñõ4â‘aö/Ï¶‰0HlnÏ˜IÈÚI©X­N–h‡E©‰˜ÈNø¨Ì¦=3°ÍĞ3®³Ùi#¹„â“uŠ
Ukrª·<
ò‡ûÅ°TGûßï¬6$ía¦N¡}¨í¤µš¿€¦:Áù„İ…£l%éˆRTdÖ(uû°H…¢ÃßâÕV¡U2M•¢¤Ö­ù_r$§İ?Jy\ELdU<ú09b~ºt|HšmæN5CË”Ö&´Š0ª?µ°r¡İqï?Ã÷ïìG{!?qîØ¿Ğ„´•ÚÉ*|ÄıCDgaIÄ9@;İ˜ƒ$  •~¨>TÃ:ñÓ»Şyä…Hµ‚\HÌÃæÉ·tù}«`é'ÔV3CmÃ) JáQ.»°`^ãw?ïÊ³3¬ª.¢©øyF•ßFözvcKX#StÕ«ÆYM1$’¶Oê«E?[U¢š™—lğçÓr^³œãn×íå‚§JÎ£ì¨–l…S7ı!fĞ·ÛG¸¸&ÿ_0cJšhÿPgŸ¹(g1bƒ†^¸›„%Jk¹îK”ãVG³Ïu×+Î™èNÌüîÌC¬DE$«_ƒ¨bø1dâË$vö©XsÎó‹õvÿ¢Eãb~=ú/[J‹Ë¦oü9çÊc¥§’¯ßÌ¶ ›à#İK—6»[.a(as°œÕşÀüK\k“¾,¸¯¤}‹†°½ãÒŠM™Ç~y8Ë XÄªÔ„*H‚¯ö>>(†,'bBòR§¤¸ÜíÖuâ“/§ÉT§[
ñ#.7twë‡o³ÍS¿'soË]¤„ÿµù5qç2ÒmÒDµ 68É%A‚ä¢ŠŞ‡/\ä6¿È³uy3ÿw˜Š=èÓp£İ¥n­‚fGùŒšõæå „ğ~5íY»ïÃ'Ç‘\ÒiÜ—ñ»›†bKĞÏh¥Õ¦’ˆP÷‘¥öÖGÍÃ.¼Å>eÓZ¶8íİŒÌ5bTÉ”ˆWi\v‡·YÌó"dø©°Îx¡ÍùúŠÛ«ö+4¾L‹¬Q#{e¦äW%còmÒğ«CÔg“fëİŠòRzö›ƒ=IQªòB’³‡{!±6ûV¬¾ó ‰œt¯ŠAGÓ]:	T03Ûb¯À"bïc'2g\³	è\ØlkêÒ¹RSÏ|BS…ñ»}ÎÌ)tûfq¨!#Ös>>£š¨9Ë¼]Ç#ô0£Œ. ÁZàÇ¸-	8rã‘HP)©HñœíìDùNq!šI¢;öîaı}ú¨¸v§¾ı Äª„-ï/^0wr2ÎÄLöV,0KÁ]Ñ(±çzï(a~6î.7yö'={á~ëgÈa˜2{Óo)N%:İæçÜ i–i~KÓí%ö CÎD{štè¿Ú‚©$ı×&&Óˆ?1•`MFh¼Çº£ìµ£…àúŠ×vŠàGfá
”#í-¨lØ¬õò©Œóõ#ÿ*œîoSğIhÅ¹6€¬Ùİhô¸30ª@’(ŒÜSAy%øLĞ‡™HçSÕŒÚMÕèú”ÔF’å<WPMkY 7İA:ÏåT‹K-]ÇºÂZbÍ~cì˜g.ÏúŠüÑ KFB¢³¹#3£Ñ«±‰ãlëçÀ	Ó½>*ş¼Ì©Úb/ñ“¨šú„ÔÅYnõšŸhªÃ¤_œ­=?óGsÍpŒºœŒÜ]ÑÛˆÈUƒ¼¸YŸóèpĞm4l`uVä
' <¼„~;\òıâÇ³•	âí—İr¼À‹[½©ÇmäÈ BÈ·sv”!ñó£,î[!‚ù»oÓGY±¤I¾\ƒ„¸¬jc®úZ&±ûÿfe <ÏBÓe™œõôı )ëOï)š¦’2D8Z›EŒ9Uö¹àÑ£1Å+÷Éæ=äh]HÎ·ó+Óá5„(¡øçvÁjÃm§¢Z|H÷qş;ÑÊO«IæÙ İÔ ŸH¡6·ç¾{7öÏ3½M|TÛE‚·—ÂeÌOv}Cù‹··ju§³¦‹ßk_ô_ˆ=œiğ¯9[0]tA^Æ®Ñı…¬J±©‡u¹®/´:ØuTzî’8úåº¨–¸	¯#ÈÌ ™±¦ÚGPfORŒÌ´½¨u ±#ã¿¯´”Ì8Ì­ÖjÛ]“e‹Ş¯ÿÀÈcxåCÚëXÃx)j{e%Ä„óuÏli8ãWì|Ë6ïsºÿÛµH¯X›Û€Ïxc¦AœS^ÙÀÅ1÷	[Ï¬¨}Öÿö'İÙ.¦GøJâ•~µp µÁê‘"^¦Ş ™}ˆL™&]†İ|ÌW«.ŸÍôTq5İ]õf+ñ<¦„ûL—İÀ‚¡º‡ú§ÆŒ—6¢é"ÀK7xˆì‰×Â*)e+ë)Y^B¾p”E‹îxg¼t)ú´ÊK=€&¬#¢%$£JEı5Î½8áŒÈÁ—RÍyûlvÎljAì-•·så‡ùó^TƒìhŞ!·•”@AJ¨\»×Ó¤×ûp“Á¹èjôvpÌÖáf4ÙóO‹†q6¯«Ù4åîl0¼´UÆdñ4Ö,/½ù!šÇNn&3üw’t•?ËØäL×ƒ3åK¹yFˆÛ¹±';£vT|ù/IˆıÄDÌÈX„5–k3DÅâY­®ñÕ¬1Œ+e«àæ^ ÈDZS™O9x¬]Ñ×Ç=éÌSBXª"EëüÒ~ÚÚ+?ßã+^lšˆØŞ3Ò`¡ „lb/ÍEMDÀŞÈ/Ğ]9ö/‚¡‰ëIßì<v>	B¦<új–Fšnúa†qÄ•I0û2*·Ö3ö™mnø×·(@L¤…Â[dÃd^eÑ°B#4°SÒqÍ¢]Ê¶;EÉ§D¸Ñ–NhÉøFE/¨<‘•Šw=¬
à{Åı€jp.¤‘[±Ÿ};eÕÈmÁÅjh=` †o˜âm< 	%Oâ_Ñˆ¶{a$+.ÒGåœÿµ[‹Nöaı÷ÙZÖPWùÅ '¹ïÍ0?d°Öö~)'Ã”µH0h„ÜÏ®=á'ÈDfzS“||Kÿ“Âei¨ÄäéPOa'ÂjÍÅ%¨!‘~=‚iƒÃ(¢’1½P˜²l ˆ†4% \‡µ,¶:ˆJeöŞİ×Ò#‘‚p,pJ#ƒŸ=ÿŠÓSÜ#§B¦±D!Z§+dÓpâ¤Íìä½UÌ®;­í‹İ,>ËÅ>¼ü«¦ÀÚŠ^æùw"ò+:zpÿ[,ùÖ‰U–~îX!œÙ?í=YÉ¼s÷¾
Ä·<yG:4¡ØÒF¾oÔÃ†Ã@ƒÂ¥œ4æ#_{¯ûÕ¥~]ÈóMÈè¢Ù]×ùD­¯¸ƒ>qÄ;Ô³@jy0ˆ0òbI\ƒx™,b^†Ü‘ÄZmšÓ°šª¹Ğà—ÄõÓ±£)İåÛw¼ô—‡gW»A·Ï™Ò.#‘5äp¡aÒZrßß%P¤¶C¾Ûâ>8l[ç,!>¥¯ÇñƒŠM!½©Zë}^%8åjK;YëÚô«ƒÚ¼6‹ñQ»u«š¶ÏpAû{{(ø[¨.iÎx¼¤‹ÎÔ]±y~áÜ²å1gŠíYÁŠü“W¿;_3YÏ7€’Ÿ--â|İ$èK‘NªTÔeî4ì¾x«‚@¢£ÅQ}«–‰³5ÈGvÏFÚÆ·rêØ!ÌHkE”fÑ¸œ…§oÈ$àA@Ñ6ÿ>y`Ÿ”^œ ?%m”¨‘@¹YÆ—I©E•0;%ìH>¿(6†åp€jlÑŸ2*CgõEƒî%J)«(ò;pB¸ÛCŸŠ 5r
B.•Lo³ógò¼~Šã©«6×CopyÆ‡WÇÉ…ğ„ŞÕš›946«‘(8BÏ†ËjäÊ‰ß×ï}0˜nì'“í	nu&ƒ&Ï“ñ_ÓOrx~ğBÔŞ`šULB˜Ù‘„ö»G(>È%;×ùóôÖ¡>¨yZ¼¸ZàZ|×‚MÙåñs&N7T«‚Ssšï5±GõmJW=pƒßÉ(çw
ŞÃf^+˜qÿ” õI)Å‰om©â)İØB0g·a8ûGuWàŸ© ûÂ}å~·XbLE
»îì÷ó
Å=³CKjSæñÔP…ï‡Ø3Ä
GÆl@‚ò4+şî½†á$µçX¥CM#I¼@=yp›mÑHUjw•YÊÄ‚î·)“…Ò7"ƒ°Çıû‘Éã¸ÍqnèĞºŠ[iÒ®Ğ´¾¸±ôhö“ÀXMöB¨Œ å4Jƒ'O4g½Ğ‹•üp3Z¸ˆ×ĞbO&°w7µ˜ŞÊÀH„ˆ_”"æ1z¿›jØ¬úûÔ) ]ó'øjäé(±ä½Ú˜…–y\üóÚSUáeƒRGöŞ’óÿÃVĞ´¤GŞYÌÈüóbépe^o?ƒòÕ2¹?Puñ%]•\´£5äaó	@N†ÉF.\^ÁÅ&’OTs§0hk
Û”k¢;"Şt¡ı?ó^ ø\v“€ˆc
ìõ'ß¾:ß|<`F§³=/†­ÆZù©¹7¼UÏ~ÉlßËR‹C…gÙ‘SZ#:ÂŞşQÄ¯À¡qßâSà¥â™zš+Ãüy(ÎÔ´v@'’O¿¯!‰3]4´=¦ºNN@Uöáì_šïÃ£#¦D@×ºKîwÉuÊğúí6wßàÔ´wf¥9LØiÄí±NŒõ¦³1%ÎÀ­‚5BàíÃäğrè	_ÖğÊ§ÃÈ¹õ2Ë‰ıÇO¶ãı#ğ†ÛÈ˜°“ŒIáÀh=~m<ßŸÄ™¦¬ûz>Égd¥øH.µÒLøï0˜$ÂA–m¼+–3æRÿõøª]–’›dœ"m¿3ÿÇğbÿR‘lg9FîüÚ`f€öƒT|’¨ÖŠú‡îB-àƒ¤”y>ÿ&À“éŸ#±…~m²Øçğm{‘<…­M(€>;l6›ßÉàY¦y8FGRS*Éf‚QËÔ*{©TSc¯ë#Á
hşA)üĞÓ'g•E%ù'ø[Ê~:Oÿæà^<z³¾âÁCLZâ´MŞ9ç}0Fàl-.÷AXà=èËüz²6-”äÏl2RJÑ
é“Ò=ĞyÈÅ*M—‡è¯„'6püßVÓÇŒ4ÕĞŸêºu°_ÚŠé­XU=Íšd™šyî#·Êg›öè^‘ô›®8Î„)@>aÍH91Ñı­K>ĞĞA”ÿ¨éô^r%9øáe£ËËN8«9uÖìRĞ_bTmğšöÄÿ'ÕT1‚›eZ€%i…üˆ½ç&@><{=–«¶bÅ°X™ÌÚ eº_#„ì¾«İ{å»‚»J‡ŠÓéüäˆÿÏA£Ni”Şª4O˜W…‹‰Sš­İ?ËûÃ0<8uÖOÖÏt¨Ë¾|0ê¾‘+ÙÑ@ƒÒrÓ—ªúY%Ãd*"9÷`±.éJ¬ÿÍŠ†8e¡C,¿ìÏñş&¤óº(\
_&—(ì|!Nâ6a@ö®;b}…˜M:±]¼HÜ¬‹E-¶°¢.ÏXLQú›ÅÄpÆ²l¬_xLE€•s£èœÖsÚ[ Ä?*JÁPŸùãT¥äµHÀü$›]Fhë2Ç «õË"‹P¦öQ^`Á ÷¸èg‰G÷ ó=$S:ÿaVàèàwîÛ;)/=_ËYª,Hst-OÏõ?öFÅ“QÆ´d\­nÅ‹}u5ìqŠ
•”`õ ~dú™ùñ¯‚¯H Eör4³TlÓÎ±õGæf2ù–ëÄ«m0¦9ÒGD­¾Š»îfœKm^/}Zwí«¡–&w¦-Ñ7q?nšZmğÈŸêº¯òƒ|êJ&Sµ#ØY•!y!÷<‚±5§ùY€''®ÎVŞê_J'ßîŞä’£··Xc+Ò)4l“2’óøé+¥(À‘T~‘Ù0³ü;s½[›Bu«*¦ízUÊçcÒáy c3ÚØçìz–Ù½QõVóâÇzï®wD…7\•7%´Û†f;«ã'Eø}öh9o¬šù•÷%Èğ¿˜ö¥;b|»ìÃßİ”V¹q¡X—+éT{t§_*ÒXÃš¯L`ƒ²¨àŞÍÒ2Û[c+¥©!kë^ûfûÒ8ƒ=-9¥1­PN(Ózë2Œ¸Z[×\!×–«r:Û7†°–¦°µğÄë6/Eî¡VNq“ş…´ğ©ÂUIÊŞÖóxá‰-®0&Óì±uşDå{J–Á÷I$¿FĞ»rãÈ³"½«¡]—æw-è&«G¢¸L÷ ¯¶„2äL¹!Æ
.FB2MÂÍPûóBN~^d
ØæóqE˜¸ú‡
¢Ô70mQAø,]L:
J°Ù?[´Ğ»©^šâ’´ÕÓ¼«æF‚=}R¹ÖuŞ,ÎÓ¸0ñÂTjPGß¢›¯'îœ8V'_7˜ÜÚ{™„ìœ"u§ª~‰ãHÏœ¾]Òj›Û,©$Å±÷=Üµxåy
Z÷e8×Š'›D%í)o—ƒ¢jDRq	ãRHÅ^8ûÎ°&§ê "ÿXjúQf¥ìÎN^ÂHÀ"{…îSEÄ]EChJ¤›ŞÅÆßG“^‰7µÎ+3k˜	ÅÁÌGÈRı®ß¼vcÍÙù-Ã;ªFu¬°wÒVÓ9ézş¿TæNø{#^ñ	âë»ÛjI‘£Í¥p»UÃå£=
5J	¹»¬C’œğÉª‰ZeĞ´V”!b{nJÅšÔ¤cZŠ¦İô(†pÑJf)©×8ö$¿t.)ÒÀlY‘cœ™¼¤~[óöKOB™ÿx‹v"[à ‚–Â¬wÀÈ&?ø2oH5–ÓNDT²B Øväú~-00çSw¶ö0‘?¬½5¾KGü³À5Õ¸‡‚é¤‡I¥ã¦ô‡,ßÁ!)v¼ìX‘*ŸËsDR€úÖoÊ42öbÅm"í9–bc…¦Óåk«_MÄÑH¬H‹“?·aRü©¸Î¥Ç+)%d@ø¾ÌíEª‚‹UñVXñøöA9¶cP<óÑ§•kÑ·*Óoõ%@å`=4„ò–ÂÊÌÛ//ÒÓòËZïèzld5oUSÂ1ôf÷R½Ü»Ë¤gÓFGMK.Ÿup2t³¾,OüDã‚Sİ»ŸA-¯¥Ba"1İ€»	<éÀ…é8åœE¦˜:ôŠ®{"~'†Yêçù›XÖ$Õ²t·ß¤#vZa5{Ì}æ :;’„F*ğñ7]¾Pİ¤İ°]àÚ“Í#,Æû¶3@TÂ¢«ØDqP±ã­ZˆÕs@ûM^¬€M´>²V{›äßPş
·ï6×lßñl¢}¦=Y[v©$£t5&¤±ŞşˆúRVŒ*ïÊè2½T6!„U
JÒ&§Ä£)vˆ¸AÒ(Bá4•´" ”a…èÆRzVü4~Şçİá«¼ğö\D<wÍ; %¾ñ-QR¯=–„İ·%O¡1ŞC4ãÕ¢ªb‹É¶”ºÅ`+5G~ÿ‹hL)¢0‚~7¦–-
=I:2Ara—§ÍQè+¢G^GšÙ¥ršÖçâTONí$©ÛHıÍ¬²}ƒÆV–R‘¦™â¸Õ%ø)U%ÿÿÒöÓÖ‘ ^)°œ$ş$v¨<Øô^0½'š#| '“ƒÊ˜Y¥\Röå\XµÒáê=?jèÛÁ j\UÇ¢)Ä‚İƒ“@ÂÏ§N—EÇûpÿ‹:MöÚBt®öz™/äÅ&m _XƒòMüúIV+¨%)&oÛÇK¢r>«µ
¥rÖùXÒ%â1·{JâõL ã‘“Y{ŠSçtì¥¼ëVG²à»x§¸×?Èªjªzız²ßŸ8UüBsE/4iø5E‚y’a±&ª¤Ó>Ô Uš`üDõ G%ğ ÷O¤cì€e	;İ}6‡ˆæA+óÛÙ‰Q·yØì‘dFÏiÒ)YX–Y&"…¤LÑóÒGåB‚S³÷ë»]:{¨$¶|Í§³Ôi¥qt`áq_»üL°›bA*øF%wŞ7+bå§zyÅß,0Ñ „ˆR³¼>êâı–ÃÊK44fz×'VÊü@ÔÖÿRŠSÀB¨
A!ú¶œD4Éè¾š
)‰ñ­Ä…8V:ÑÄEº_àÌt@R|vH[/@f`Û· y§›Âõæ.
0 |RˆÙ&‹bh êô5ÿq×ø×Zvµ›ª•€¼«^«ÜIgjÉ®•Şƒ±œÇK ¦t›€öT1¤½1¾E¸Å|ıTô«ı	ÈTì®ŸÃi%†^Gƒ•°¡ü)[dåŸ™$´õÓôø>Ê‚ŒöXà^ìÎ†á$:ê
5¥­4LíË{Kg¨ú¶GòÉé Û6ÿ¯·"Å<VõP@$òÛæı)6
’>–cŞè4@ÒHdão§)Ü^tU“
st®rÚ0]7j_¹´ÚºÚÁÆ´ŸˆeÕÎ;#¤“Où‡ƒ¨d¦µïõ(ØQÉ¶ìæ.-m¼?Ë¿¹o¢‚ÿ$/İ¬°úB'³'’ïı1ÿ’¶ÒsVZú<•¯'kòİÑs³œÎd`XfÎ}¹;	`#5Áb}3Ğ'²êá5¼-©u|‘=“ğB&—0Hé¦VzÆ¾9¼lÊºù¯€ËÙ‡v»‰P×«23®Ğ*¤p°ByO¿Öš`¨YB†¿Sì/~;”İKæµ8›äØRœg?z[ jÍ³‡ŠîÖÉg÷ïÿÉLœ«m`˜‚CQcâÓ…u°ã#m	0Eü¶bµ)”"ƒ§A(T² sdRğ…
¼œ€AdR©GIVùœ<©R»éˆ¢ ü@³>¶	±º¼ÿ¤É‰§ËC¾zó†Üid™õÃËòäüß¨|½¥½íĞz¼¾-mßi>äcÒğf®í”©’œ
÷XR|g2©»ğ(æ[höuş¿g…‹l>…WfA=Ô“™æÒcp508E„²"h ldÓ=4;[ÿ
<ğ‡Cå»ığT4°g%¾?ÇÄ4èì JqRà$<î¦z£ğ†+LµuZˆ"'—›ÔPühi¼Ü¿•³Q’ë	^h´ÅfOâ¹ëõ>Ô1:7Ã’ˆCl•Ñ×A„0ë)ÀÅ.µÁRÛÒ¥'e˜YÄ£JeÙf{óæˆ"Ş3¬Óuœùzô‰-;ùdo]ñÆá2™<\¹Ó\ ÚÌ,¤S€St¹;¬Õ¡«“ç’;¨èj{^+gÙpA‚} úÑÉIUu‹m+VÌˆ Ô÷ºo¦fûG–`)¨"D^¨Íèåœ¡ÜºˆõŠùDSBñK9ƒÎÑI´Î)Âù¥šu(¿ĞRÎ—£®•‰Œ!¯jS¥÷#a¯M‚l:¾åÃ„K²ŒOÍÄ†nz²ğõyò,³ãÆ4šLz£^B<Ş¤ Ö! ¢š’@ƒ£¢Õ:Õ–**T;¤i\3=œ»«Û8<ùƒ0Õ$Nÿ@–³RŸÃş†'B%[“LÆÈvp3¯Ÿÿ¹Å‚Gmîİ tÓ1Äîôñtµ¤ËéK\b´AC>!•3­H›5¥å^K ÒÁEA£è,ç»_.¨…&­GÁŸ!>¾ê
F=i¾d¡öcŒ:eŒ—>,lÅe»º2«Ü¶¯êûM°GÃ$û’'7‹‘óÄ¬ƒTÇ5€šâ¼Â ’o%Å}<©lÈ{åŒ€Û_D"ˆmuSŸr™ªåT^8Qª+Âe¨Èf°»â3©¯êLêQ ²oÔ,ãâ3æ2y²k4Ï&…gƒ—fYN/·7şê+_~ÃÒ:í‘)	×¦2|¯[ú¾ôŠ«Ü_—Îä"KªÑı+1º§õœ¥jÍµ`îènXK
rœ³éÃ‘\f‡c½|UÃÜ’¯¶l¿ezšíÙƒH©ÆïW@3Ü`ÔIKkd@8•!X0dxY{·hŒĞô3Kc‹ƒVÒŞA¶‰Ÿ.˜`Q¤Q«wZc—aåpc®eg …x H^C1%7‚î~F22²Ùx•ŒØ˜3şPàåC™i^]§ÖgiêY<–¤6¬¥j
îAôÌ?ÎÇ#‡ÍÿŒoã"™
¢/cl &øçÄ?®¶n%2ÏÆøëÅæÍyg‰ta…:ŸtÛèA<xÂZ*d¤÷Ôî­¼5¯ß'Ûöyêíµrhü88í¼ä	$Òz¬¾òsiÑŒBè÷FAÁUAÕÿĞÓ„XÌwO>íÉ¤g6*e0¿R€ÌÅ$Fµ ÷ôpfh/ó…Ş­sc)Ëº… £’qï©¬@Ê#óı5@NH`oğÏ¹ŠsÄÑSŸ€rŠ8]=Ï$­_ö¼ç„ûSSóÈ±, 0«ò²VÍ]ß‚ã6/s®¦!ŞíÄğŸóÊi>@»ÉwmÈÜOñ9î7h!Q×Gbä6úèÊ5‡c&o¤¨Q‡ƒ4ì×uÀ™T”næ„÷
Å¬{}‹ø¹;iß°Ò’v¸×ÿeÅ‹¼·à½õ€¾2u´ı¾(+SiÔ¯ùõÂFÔˆı²•Bæ0X]qŞa2àu{KŒ(8l>HÀÚş¸¯úZfüOï­Y—ü’~¶3ExÃåDÁ§¼!ÊÀ\5+­ô²]f³dÁq˜.ø‡qS¯°»Ô	?Qº¶ÊØ–h"­ê~ç3¯£<6…tá:b²9L"m–'½tM	ÎöH¦øìÀòp›„	mUyß®ÎwàS§‰åãÑŠÏ!xúÈ9ef~ÙAP‡Á²c`©"¯úxµ.
W¼îZk¹n¸fğfÛ6ŸšûşÒh}É)c9ãä†çtK-fôÊŒ Õ
æÜ®Şg¶"|MÚ¬ŒU;¹…@†qõåBEµ‰ß$Y¯ˆkÂ™VC«Ä}	ƒàÂŒo9ä¬€ƒ›÷w¥4İ[*F<{’!„¾g¾Ä>_E­áı?à˜;}‡µuå/jCs×D á°åIœº/(7à²áÿ!gBÒàqñ¯a¶ÓúKÎ™cùnŸë¸qüşzÈ
†—Ÿ{»f nráÊ¤e´Œ[Y1 ›®BÒç×Ä•vz0çN:Åª"ıÀ¯$¤k|¹š]ˆ„QµeÉê§ÜÆ‘àŠ­)EKàFn	·•Mz^W/iûÏ|ä?=n§¯ÏˆúÂsØa*³4$B¬È¿(ÃÉÿw»?†?èÍTÜØvã˜œŸ8‰MI‚¶;ÖíN±æ½¾«0Ÿ)4r[ëcsúbd…Mr%>´% ®ÔG^„¯"KQ¼ Ze'sVp¨¯™“U€X3	:ÌX‰Nı@z´Ûxüœ˜³?®5ŞrP8‹Z¼ñ7Ş¥G¶…Ê\Àl÷@g¢x\=óÅÏYÚÕ«ZI„Í1~¦zÖd•öm¢ŒÒ¡AUVzÿ2ê ,Œ1¬y-SâãOK,oÚ–×Å‰¤Šç’‰`#j-{Ó„tF\6êeJ:UÜ’OåÜi«5´[†ó¬.c‚8;Î:– æRFÀ‘¬D-k‡^ÎÕ“Ù‹Ø2ƒ'@==>«’™¢’D§z¯eØajisG;¢}ñEÖáwöÄG0™iÎ…÷õ/Äôñ&ô5fZ)S®<_î$Ìµ‹À`4”¡rÏZÚÂû}ş ,½¢ X#èŸ~é£Nƒ<›à9ùœ5@dJ˜Ò}-¤ÇCG·öëÊ|¨½ @ë—Àâ PvTS5l"vÿbß?QS2Wúv¶ÛQ#ß·+y¢·…¤ŞqHW—Û,RæÓ…
PD!ÙîÆŸ:ØdÖ;À"ë1èÂ¨<‚¦N­%®¦™I*/Z®D<”ñvÇv&·–HOe^ná’ÿ«Vkbp;ãÇã’Å¶Bf:s×VÒevÑk‰hu‚UÓ¤lZ¤‹œaÅ&Qş¯\b“è¹9şªÙ:÷Vø×UĞ“>†¸‚Wô²x½Jy^Mwğ¡dñêÕ<ú¸HO%sï–˜EV²ƒDGÈÏ†{44’Ğ+m.<&OÔ5»ú…uXRR|â1Õ[Âõ§dÁIÚQÊîZ£—BjIu[ê2ù1ÆèR½ë*ªMıc$³òÙ›Ñ‹K¡Dg0\2¢˜*NHF•ûœE%±×Ğáúo£Ï‘Nµs™Õõ®Áooiƒ@Î[rĞ»*óñOYi…T†‡%_±.BÀ+İH›Éš˜txX”óµæRĞÁÎµ\[Z@áˆ¦¨Òt#–7óˆh1¦æ€Î~ÖÕúqØš[ŒíB^3ŞæøsÔÙ‹)qœ]g¬‘l#]‹ÛgIù‰×ïvEŠñ$}iFjo0|y:”J˜½´/Ãê9/U£jK!ÊC´~»¯yQ¼	ñ°¬u€ãÙÍõğíË-Ğ»€ãB‚óÜJù»`»~š­á mé9uôï1:{}?'…VÿŒ‹wtÃwúÎ{ŸÈÉUŞ8†|-fšè$lKşÛ¹¶q;C”ÁNûv˜Æºµ×fwt«AG¶~Y8°{/Ë(ÊY £—£	[8Oíío°³ˆ-ççDê«	ø³yë-(”l¾ÿ#óâ~†oÿÏ5œŒ¿2ö¡¦Œd)^F&­ –½Àª¬_¾Ò
÷:İ‘Åq(!ç°"õ•ó{'äKÃzÎnê!ŸÉ˜µ•¨Dƒ ~<xœı€½3dy¡dD!¹qŒwi»Évgô+Xfiİ²`½	4*òêjRÒÌü­¯ò.¸Ö>‡ëË¯¬8a¥¿Õ©áO¬³kñVÀˆB*½\ ËmëÆ¯§İ­#íU=&Ã©K
x¾¤„G>Õ´ÿÔy
» w†¯ŠÈ`¬Ğ°g?’@Ÿ}±Ğ8aE˜£IÁ¤ÑRÑg}ı53A#H«EEëÛzR>	!:VRN¹óÑxI#ñcåEù!ê½eÆ`‡EîÈ“^Ñ“+…²ˆ•9S]”@"äş)IÍõÔZ·báÖÿ—Êr½X
	2ú»bºıè„·%İß¹Ø¤c÷šÜ's©Gè4ùåéŠ€ö•VÉaı“L²‡“zeZÇNß¸„¦0 P!éÜƒ©Ã5©i¯$¢eÛí qëè*Àpsø¼Êd1›ûá;&á¬ÖwbK£uSÓac’Èå+º45GPOnÊTvEnY¶?û>
ŠšF8ß«!>À¸x>ÂkXnª„i_Ù÷£IñÕ²÷óÍHXn»kÚ‘Ø‘¼í>‡’Q›I¨ƒärõÏ¶ì¯ù§·½Üf„ <ç&A;Ó{hšƒ¦_qnË‘zj2ÿšö‘%ÛU+†¿ÏĞ6}	=ïó±†äÁ}³Xc™,KMêíı)™P—0Ã‚û/^º0:£«/˜‚¨¡<1õ2öÄÃçÏ·}¡P+“ Ü7UtS< êYÖ©ızhï•ìşS<+”G½K¿Ê„Ôò’ÓÁ~Lá‡O¡ã,Cçƒœ¨¯GÌ;È¶Uù¾çl/#É.¾êS1åOJIâC]I%×NÅ½LÚÇBÛşAz%òf_s&„r:8¥%ÈJÊğëBìT8È{ú°—Aæ*–šŠ©Î¾n*áxŸ\KÎr¼Y…H.fÄ¥·{Kî š=Y>¶Ú,ê£÷§AMı¿EB\aã¡¯†o–©‰q¹‡ÏjŸ¹ÖGl;İ g4ŒtŸ6µ—ôÚ,Ì Kïetš(Û¹âg•vŠC×ÎƒâÕGòUC•;¶–g}à,5ÂâĞ Z!£jNDê×ŒÃnçXx{?ç³F,™sâK©ãv¨]Nvà•èµÎƒõáÓ˜†É]FİŞb{•yÑæÆìÏ{õ–¶Mr+óè­o¥¿äïX ØM?Š}¡Ú¨¡/udEo	ÉÄö3#›Ñİ×”=zÊx"ä÷m.t5ˆT1ğW'1¬u_‘ß/]`~……Àî!SûfAW?+2µÕù#s.ş CsñcÑ’Ùî[pOÏKN„ùß59Ÿ9k*sİÎ‹˜u,hÕüæVÎã•n5cÎ¸£5º¨o Ÿğ97i¾9ë^a–ÚÜ3ÛŠë…u8d´Ç&H6Ü6æ^¨ës%Éo•­2C-\(×ç[Ba*g¯vjÈĞé¸¼OE¸ Õ¨ çè§„H»¯Û*Ò«lJŞ°Tö®oŞyuÇ0õäùåùÅÍjƒ7ÈÌGmò	Y,KŠNŒ·G“"=÷p„Ã0‰ó ÿgO—Á$&kÔrƒòÙ¾Ö/ t.¸˜­{ö€Ô­Ì5/åÿˆ~³æAÄ!»0Z°?Wi0(ÖİÇhİ×]@Óñ·¸Ë¤EÄTÅ‹Jr“6nUÁÃuiK’&íç™.Ûœ·$ğêmü<‹¦?½¦Â~{\ŠÑ`³o+¬-³éBİÓäÁ’\ì»ÿ]ã#¬ÈæÎµº§DˆÉºYƒ'‡U¬/×©(ü@4¯ë¯zç8YİËõi d|gÄ:Üéª˜k‚S$*±ãB‘ˆ°!úÍùš÷-İÎ2éû6ßßÆ ıçgwâ…3@Ç»@ˆ_‚~„İÊÒ«„ı™¶òNaUÚÂÆ÷¡Œu´®ªSóØL ‡oîq4ß°èZ1ÍU²ÌÊ³ù]+T¾F1Ú)¬å¬~Æ›¯Xq{IÒêòÎÄ“ómá¡ü— h"ºñ!JßKöQÒ2l…Õ¨ÃQŠŠşè°¡Å=ä+¹ÉO¹®Êcêf"¸srÚ|’NŠÜs÷Ø½Aœ&¼<``Én+ê”v¢©Ñ §AıYŞVìNmt7¡ÿ¯KÊG›Ş¹	#É|¶éö¾¬Mğ´H=“)‹œqÔSò[¤§lP Fa;#eoQR/×Áèİ6úëî‡ê•É{+Ä<Ùş®]³—’¬FÅQ‹’[ÿ^F†tp3q;hvÕ=Õ:NCÎ°·=Š oôúI©xJmØ ó>#ÿå‡Àí}ßÛÉ›ª		‡q¤Í(í¡t‹ ğ({ÀÓ„I[alº„Á3lymÉUíC™UÍ:"’ Ôóô¾UO.‹•Yùğjöá½{ò.c:°±tg¤@7³gá¾Ì8İHòsGJTÌÅş'|£¬´sHE«Sû•?óü‘ŒÅBÆPñ’>Î`ÆZïä«ÁAî¬5ÿI®>¦V’ˆìªº PªÙë­©¡Ùs`•c«?”.Ä™=„ş"ÜÙİÎÔ¬Hà†Ëˆ®åüÊÜUv!%«  ×ïk…Éıé•„Š#Â­¢•™Qòââ„xMNó˜Äœ‘ŞŞ3²xÚ|®Ñ-Ë¸Î¼ÇúC§³iâİCAóùw‚£&oêÚäœ¬~´ì«ÀbEšm@â­…âïóH’`È+W”k–Çîİ>çŸŒœ`6«» É:»­äƒ_JÀ2»Gğ½WvøNU-×Ì¯®£“
t;½T´ÊûDc:éËÄrÌU¥‚o=óÈ®Ôxå™×hñıÿ(ƒíÌÂ…Àp#`˜uÕ'>ĞÓõÇ÷¢Â¹mß®f©‰Îì|€Kœ»\¡ğîÉ(Š¦İàtú™Ê&§ëÔ4Šûs€Í°É!ùb²û¼këÑ¤æ·Ú àÆzÕĞz±bXÛíæZ;cú¤%²FmœÕLú‡yDå]ú•ME›a„‰3Hf0zÉ"–JppRƒ_…]u]ràİBúŠ4;¤õ´•ƒ`o•İ!a~Ÿ¢™ÌÜÂÆ{îl!ë@DÚ‘c§_‡xdæå–¬O™h­>^O~Ó:\ ˜êÛOHS9ûS¤¦4ìˆñùä©iÈîD÷#ß\î@3xöyÃËˆºPîìb‹Æ»?¹f¶"E\è,Å§à¤³©}//›KY]©ğØÆœ÷°Zß"a±Ÿµö&M²ìg¹ó’äGÁ²†¼ŠoÎìáç¯9ï=Ş 3}nâ…w\ñ~­ƒ$çZÅ#zd¿œ“X¸İ¤ªó[¾a„Œ¢«n”‹Bê_œj4lªuútõ•„)ô¨7m˜IÛ°Ì.ÔºÃ&Nüğ¯ïîZª&rk=§Yo¦tìÛh• ªŒ1Ş¥CÕß{µ]t½Aø¶¹@«5ÃÉC«-Öå‰­©µJ±šõ§Z3æj3¯x1t„OÜ xa‡o¡˜
yTóBCÿ È>„‘ Õ½PZ1@
Šê"ÈƒÀòÛg X¡]„ )×säâGné¶o
ÏU9ÿ¹qZa=†ÿs|eÃ‹ô¹üGûÕÂF3B ¬5	úÃ¾¯Â“r]q,–fésyWG‚¥JFÉ[¼9|¼LÅmGPjcŞ‘¾nHÜ^ì"‰„O„NÛà	¸™ 3Eñ….Pï÷<!i¯§ŸÍ[pqãé½+™Üè.Š»ÍÚ#$„7B«ŒhlöÍ<t+äe¸Èª1æÇæñç{b…C¸¢Ù<&Ç]%#)´Á·T*!¯Ùq™&¢3íÁ®P¼<ï&šŠ¤Q›2Eƒ‰8½±€ª[NªŠafÙá¶24d¸`÷f€«ÎvĞ{ZÿrğM
¨	˜±YxöÛ•‰ÍÙ†d#òLz8áˆaaÙN~*7,ÜzáNuëzuã<y:(‡„ú1¯“ª½ëÄ£Ÿ4÷ªÚ‰õÔMœzg5®ZBÊ¥¨û7Â+Vì™ô¨?Sm‡ö4à3nn°ä±pmÿ‡ÛÕn¬÷|³'ïœ“HU«şÇ¢YŒUIõâÕÚLe§dI$².“ú§ÒŞš-9	ú¥˜(m}©PIŒ¦°ÃõE{€îˆö•ÂˆóˆF·,E«ºî€y“TÑèP!ùÔÜÔsícÒ‘ÿÎ¹‹¸ØiF´k°Bé0Xm¶êGu¾{ ÔÄë°¨'ä}©„Ü}@„G¤oÏ_€#gë±IÈ5És°ÂyÔ Š™$0“›ÙÏÔz»Ü_ÅO5&ºˆÕÜ´¾C¬P9cA^ÀÚÖ‚Ú•Nm>ï7¹È ŸR"]Ê… ¸Ş9˜W¼‡}pŞ[^f½‰ îtqäù}¾´‰İb¼4æ?ÉDÎ¶5Pa¦Ä¦;õÊŸ=U^µÈÑ¤BÈ˜ønŒ"ÔA>béc²­œ¢=íyêZELGùï7•õ€y¸š±ÿ>¬°?®à!µÛ_Î8·Ñİ	¯Hy\wêÄl¡‰ÁNŸìeê|Ğ³Îƒ>wµKw”ğ%ŸÇIÁó&¢L@Ñ•BçÆ™'¶Ì£í…1¦ÿ
$’‘~œfî¸1Û]ÃÀQÇğ—¢lãµ„\ íìfn"ÿ,Šºƒ°ğÆè\?”÷l³ãÊrå jçt: ˜¿û‘²Æ5‰:†S‰Ç¾$IªÊ0Òõ;jBéaë$½0¹<À“ ¦„ùcgpHÄœ”Ö',©ÏJ”n´}<ß‘×$YK=œœ4®í?+Ú¹2;óÆ0,Œ‡ïŞâMË^Òäõæö,3 d/˜‰z	ˆ´Œÿ[5HH¡ü8hø¢âÚ1
Š-E^’8ïôË‘lÄÚkßªä}ñã<øèøï3ÇEÂBK›J*óµ¢+0ÁÿÕmÇÛ"º¯±4@VÁ&¿cL—8i…KÁ9õ“ÇË†rPª\@‚í8Í?§ÿğÍ3ü¯ÏIÏÔÕËuâVÀuP³#ZX“2ï_HáÔï†Ş.¤¯­\‘¶g¯6cŸ#‚TSKm_Ç;MÈæ)FÊ4P‚ ÉmJèÛ'ó4,·Ô²aí^rL»¿{„ˆ2eğR5€ÑN¨¾%TÂÕ=9«eà<r~m›!;n)¿ìğnR[i—±PÿA¨|£Êæìj1ş±û0}
<¡aÒîWú	¢Fép_ã³Kû„øä0\H¯ÿŒŒh“‹™OçvÛ¹Å¾¹‹¸gk`…{‹›räsˆ,ª	´7Şe£‘òH‡ø1Ûô	è”’Dt{æÄä-â×¤îªyj M9‘ÔÜªH–M”0©á°^Ñ@™Ô£ÚÌ€¬9y€u§0^l¹Z*à,`H2cÛ,×C|sy,/ô`bÿŠ´˜¯P
“_ÆÊÅÿÖÌ§s7"êƒNJÆ«9òê*‚¶ûŞ~l¥qHı^.•²-(Eÿ°Hˆ^U¸}Ã â›çw7sbzO˜;WÇ’t`!³ˆ¥İpƒMÌ¤ğtIa³œÅb˜­*òÆÍŞy¥SçC*	%”O‰˜úÏÀ—‹ÈueòMˆuû%.· i@á)3q¹J?B¨hÅç„¦’w%¹¤®—á¥BÆé®çm"ĞMa XZÊ\g\úêiÖN‘œ&:PåFŒñfÜì+Æ ¥ÊJôãÁÛ cçe›jEÈbŠŞµnMl:©‚ÁüÁ'¾#ìãR¯á”etòa™÷ÑüyãåƒZÓlYáï²¬§]\{ñ1’
¢ö­Ïï†[*ù™×>4Á¼+[àuÃ‰Ÿàÿ<WëK/eÊÂè]¤%èÒ™İ. âĞ6¬³^lé¿«…èk­åß]¼U!ø„˜GÓép÷ó>1ncV¦Î‰åUŒ‰gWB@ ó~ú~¸`dÊ6^<´40˜» £lĞ»Ì—â
–Ñ£êÙ²v
¨Ïè£Àh1W#òÈ’©ß„ £DÌ•ê*4·usOÎ¤„]}[ôcKP	Oî]Úv#tÍuÛİw¬O.“¢Â>”Ø0³ÍIHÓ­§-nS2!Å'§Üb—ÖæxÌĞO*â«œÏw¯ùWö€A#ÏºÀb‡vUj58¶k
&©ÿè;a¼í*á.¹÷…>Z0N×w”ÚÕí	>_J¨½Ò5Ó±tÖÛfmÜ‹M“Í:kn¾-¶šº¯Á”Èƒ/Ætaà$®ıÎÂ&ÑÚ5"ŞY¸xÖRU»s²î‡•Lbkåpú
äŸî SÜ2[<¯½ÅGy²]Tî[m¬2º;–ù ¶Îô¹ÊÏ°sé2ã0xÇÒ»5-ÒmÛT‘Ñ âKŞ{«Ô~¿VUùM”0/Mò©Ò²Gw—à)ªÑ*ó}(ÙûŸapø$±
ä¶8ÔMOrÊSà¥HBsŒ<8Ã1ä˜Ò>làVs‡1ù¦˜Ò¡ä8-§ºná¤]Køb©ìôY)¥¸Ù,·{<ëÌÕKÄ!`î„Õ íöày;bÎğú•<¢ë¸[ÕDÀ§ı»7XvRNÕÀŸ‚çô°)›VA/îj^“8qİMY”á$úA§£‚È2Ğ
úK£*F×q‰ÔG1îg=]JöÈb5¨‡ÒfİatiµÈ&óıç;— …¤yßc Ac@x¨¾3¤€Ó{Ã÷	Ë$³Úë+<NC‘€bY=*¸Ùx/¦YÂWNğÛPÃ&Ëaó×c¾¬aåE‡"¤³h	izzµ+ñ¹rT˜y¤Eß¤"‹+éŞ½ÅŠjH[¶âIÑ£M1ßÜAÍ@Vß”¶D2R$\.¦>È‰a¨İ†÷P¡8xÙ3‰\ÁªGò²÷b­–¼.’¸³%“ùn>…¾-´r4ÛoôØ{4ıw'ˆÁcÌ=Ïw­¯\‡ŸËCM,hÖİ„ôôI¬†{é]şÉõ³uœK/	8%ú	š€àÉŠ*ú©ÄrZ6=v—&³]´2W¢A}C½pŞ	d<©~áÅ‰äÍ;am$û[ç5=±™¹E¡•H$7 ¾ãkV¬‡NVV÷=ÓçÜÀµkŸ÷]½b1?ŠAšîÏ8Ä2.27P¯²êy31 ‡æå1U^·µO,¢Xíÿ»Öáí=ßÔ‘Cµ1o>rxÉjá‹s:(S»¯"g\y@ªÄŠæI Ú|^éhp‚õVÈ=5Öha–xÄ}26ü’õ"‡
"÷Ïr=p`Šl;¶]½ÌJõMëÚAG!:‹¤zö˜ à·;{)y=ÀÁü‚ÇÌ.	İ³bdïRÁûE„ß‘Êµ™‚x¾ÿ¢î|×Jş¡Õ…X¬Í&,Õ÷¼èâ|j¬5œf0¯Ük"!^± ôpnˆ•ãK piÙç5|üKÒy(Ù±³8¨ºŞ¸:Ğped'•Kg0ıaï¶MŸéwÑ\,6wFYB!5Ñ4bhıˆÁ³B!Ö,µù^:gî;5é¯°ÉÇ9üù­vƒÎ‡¨"o:ÿ‚QÿÒö~iKøBªù_WûãÂËä,öÁ'MœÏK‚ã÷ÄiÈ¹Gqè"ù¦8Ôú-+{&ªnE ÖÄNQS±‘—ù³štWZ€©¾ }ÔSUFıItVÅ¥àú|ah«D
_‘«Èˆè.ÿŸ™§tçüøZú€q²‡ÑQ6†ag7K
ïÆ½‘”h„#h”{8‡Ü6©˜ÓpÂ+¢Ğèü¬úD@ ïŒ·ÆW0VäH‹ı^Rõ³ Ñú3Brd»W¾kHç´!üXU<…_ D®áª=ÒsƒÆ|öÅH³ñá][…™½>gb‘aDƒáÙ°ß’Q™êCW4eŸ¢—Á¸˜yàYì~1>/—â…è*ÂRàxÇ¢·ºUŞ"
Kr<T\Nå4¬¦Çv9  •¤ÔÇG-[ Ï¶€À »{°±Ägû    YZ