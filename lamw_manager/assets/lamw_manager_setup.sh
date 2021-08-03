#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2195808441"
MD5="2c414bdeeec20af20cb1882a71f1d1b2"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23072"
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
	echo Date of packaging: Tue Aug  3 17:42:57 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿYà] ¼}•À1Dd]‡Á›PætİDõåêì½ZğıcÑ"F˜Z&X=¬ˆÑŠYÈŠÈÉiëQo¶"ı %\öµHş ÷­PÖÙFaQ\»vp:ÔW+`¦Å¦÷EC+©QáVìÇ«^J@›„“£í(ízú&é0ç»«³ØÕpKŠûÑøõ/œvW¾7ç—×9Àû/@QœBÿïQp2™LJ·‡jpOî¬\îÅåkÆ~WóÑª¾pÇ¹µc¸šbX‹èz„³?·p¢/°f›ób	 K…§Ré€d¹ƒG’=ğÇ‰,‚ÏE\ŒD1Êg1ºĞûS/¿˜{âãuY§íeìí|ü%ûMs&©½bê£«øe„­¨lJª'Oö{ã•†É9;…çŠ!’2.#ò!Kxƒ ñ·³×oJÑÛ–lQawĞ±Riì&T~z÷JÏ—Oâ,§™ÏLï+¹J;&Ç˜@Œ¦}.wdÂ9 µ°D¡éxõ)Ì˜™ªÂ×³!&ÜÚn<'³İ}>9”d—O3T
0±®Q	LŞ‚’ì‡oãBÆY»ùZB„èQÏ4ùF€åšzP˜_qÙéV«&°ĞsR*˜ÜÔLlAìÈÇVÓÃmÈ|’÷	@`£Ö˜G0Ğ‘Ş­Ûš¯PC“H©ŠÂNxiíßîzù§ÃõÜ:ÎbàN¥µ×Ùİs_åÿ«QNAäz¹Tm™å\­©ÀÃô˜Æ´êóò”‰õ¨¿?®È`Tö^oû´(ğzı'x—³ëEi)~>ªS İî¤:+kÎ8©›ZJÌsİ·+$ë,óè±UßÁª>‰cTUAò„‰¹´³(¸‰3u^l—ÅêÑç^º°h`¸¢(å€øMiWeYï'(ùOÖı›©â3yÈƒ™ºw"şLù‰úşm:¤*®­~š~¿Ûtµap¹Ê˜i êàC:©‡Ìfò‰= dş^¤ğàRŠ—s%H™1 x‹Slù €×áœ²İh|¯¿Ñ÷,Ö•öG, ±§ì¯<XÅÎòñëãû£VÒ–oøïı—Ö_:¡˜¹X®v”µ¯o›7à@èˆK€Úyõ7îBŒ—ˆz<üĞt‡×…|˜Í¯"zaşƒN×63x:®\u
lâC„.c„qŸ[tDïœlÈZ÷í
í` /Ó9FJEµ ÌÍïŒéiPƒwKÍ_	Úœ·?&çã&®^_yãÖ–«:K¤‘Íz£š ï·GWŞÅ*Z
œO§÷eRğ‹+fml•ÎÉ,ÎÌS[?‹¸ë=¹ò¨ºåŠXŒdİ‹bVPñG¸»'ëEÉK=åÒòÃ®ñ;ÕùáªãrmÑÄ.Qàñ‚Î‹4f¾ÇF>P/qXôç¹©ƒ0Vœ]ş ×¿)·ÖiÑ]¯áäı•²»B‘ú€]íR..Ò5!³ğ…Ú»:/IrÀ;T0vhñ:Ó¿EÂ‚C\Ù×\Ö/¬šŞJÙŸ®H³z°×z¸~Q1qa.½2uÕGü½w
1Ào÷Ü`¸ETƒB_§ëÍlÑå‚¿ï'hª/Å 
Ø`P`{Ùšb‰©-æöŠ³€»*§óŠräó¿¡I„Ûn[¬qÒtÖ%½Å·üğ<Êpÿ¨µsÁµ$O{c
ˆ‘	 ³±ó‡ÔVÀUkÈ0HnúJh#şÜT”ğª $¨˜ŠºB³ı‹àæÀzG‚1>×^Æë$è½è‰­"ØSRe…rP··Õ%Gdº@v=Ôûnã1QûÍ3‘âz"g;g¦£æ!2ÄŞ 0är*ç¤°ÏßÖ hU]Ó^kšÚÄT|qf´Y]ò´$–Ş~Â.ş Ñi[ˆCŞL€JO¢›(õ#<É<½Óa‘©û²ş”èŞ¨Dˆ\À
¤šÀÔÈeSz7C–\#ÿrŠ\—Š7ã…û¿Å:^#u%_ë(P^„/$_JÙ*EQ©0JŒjŞÓe;B¶?¤òØàÔ/k«8©s– Ä‡8êO‰/Îµ'‡jäh/Å”ÖÇ Í[ÄÚÂöv1;j­Bíµ á —m¾Æ|øa(í¬¢4n,–>xí/úÑEËç_²wÖpÂLU„ëÌS\†óÎÙÓ´H*µd[4×²W8çÃg#Ç®Ëf ~6=iõÆòô×²“ÆH\¬¥ÁÕÁêô³üª†)^+í»&ø|Ÿn*d©—*ök¾(£†º?£Gµ&Jƒ3nE[Hù—í½û\:üÎ~ÑVğ^4]ÃV‹ñÕÏš½7·øò‘’„àqä7ÆÉv\¸Z[§×#|X[¸OÏl,t
›˜Á†>²Ò†óyIÌê^3šà] ğç.™c!ÎG¸K£6¶¦gØœ_Åãuo…ç×¶$±^Ò^İÅ‡úÍ‘$,Ã ©†|Ğøg]††zÍÈoé2dã¶5\Ò€-·â¦ é;FxJc2Ôv7D¥Ê`ÌdKßÇöÉ¾~gûÇõKuÌFı¨è˜æ?¯G¸uşe½]%Ë²ŸJmû<]ûÿEáÀCYbo¬jÿÀ’<‡¤îMœ£b%*¬ĞÒöÑ‡‡ÿ[s=§È7™DËÈôQ+B*ÛS‡ıïÜjpÁ¦A`£õ7º V˜ıËÓJ{ÖñÉ1Ômt³k&]¢hÙõÛI©ÄmsÖâß”Ş!/Ràõ&”Ú':‘ËŸ.l°„†«šZ¨wlæûÈ2/üêB7Î6A*ÅUæmmBNˆKæ1ó“ŠÙÓ#"Ñ¥5­¹~„£™‰½K'ßáæŸà[°É…r­®:ÑJwÄR$ŒB£œÑÔ±ƒÕÏÊ%‰ÜÛ<ì*hlÊ#ĞºğSª8Q¢ª«…«ö$í•rÃ#Ö:Rãs‡|úÀÊ“yˆöÆiA€öhğa!g3ñŒ¤}Š3¶t?0L Û»=3Œ>ïøp (÷t0pªŸ8Ë	ĞjH*¥Rğ
W" ‰2±ŞO/Ss
ßsÑÚŞgwX&ËlXš‹øâ(€R– Isâ€ºcZÊ„®Pö¾æªS#TÜšnü»ˆË|zñ¹âƒ+¨dÑò¿ÄÓ‚O&cò°$bNÿEAf…´ä*¸‚ŒÂõ{¾3–LPPßr`ÜòCXô’G×ğ!¡Jâm;&Í}ıp™fwÅŞ¾Ÿ*=”–¼ÅİÌe­ï^Üë5sÉÖajÎm-êWvÆ8ØÖ¹üo¦.—ˆîÓ’á³QR§^Á½¥¡ë2*¹›Tc7EO¦šıÅ53Õí“$û}ıäY¬ü¾á[?˜<²÷|˜æ­›LàüuN'«pˆEã0ZòçTm!{GŒ´£üãAÜğ…–½å;÷öæ:‡‹ÿ(ÒÃªÁ/’Œ[EAkÊüˆ÷ìÊAP‚eI
‘(¯Zr¾ˆù°”ÉÅ£Ÿ:Â 4·ÆUù½ÜRR?¡Hß¨å¼UÚ]2Ÿ¸oc±^ËéÂËzï¶æ¡ FªÊÄ0/²{œ˜&îj›tÌ	ŸÚåâçİî!™¨Z
UÜş‡‹öI¾D#dsñØ£ÒXH·g¤ÎÓS0 dˆ{ÚiËĞ¦[ º<¸¶öí˜r=„#Uõâgbå³ñ¾R¯‚~¥‰¼U–û¸ ftÊTdó€æóo%³ÒÓÌ“¹½dÉ!y9ë†û.……Ìê‹"±LÃÿì=Úoù†TÙÆ«V ±5õ3(È¯d$úÚ`w].óV­²bØZ®¿¬hÅ8qE)¯QMnìk_„kÓÄCËÇŒ£§Ô¬Ú+d2,Ázş0ÛĞ«½Ë‹®ÿòùD€‚ÚQ.Jà¸HLLá)à¼½»ğXÎàáÅ™‰»~¦¢µ§ùÈÌ’>òÙYI:Øé"4f'£îÍ¡¤MĞÃ2Wëa	\{ÕGÆ²>Rî="Âxyêç5Z~•„ÿH¤&*tAšöI¢¯ß~I¯µ+˜í)Ğì Ÿ¥HZUtU|^Ë<ÊTT€Ô·4ölÇ‚…U»‘XL°Ì«ÈX˜æyRñtmz„å¸ßÖ¾Ç+ØcÉR•­~·ÒeÇ„ÜJæšq˜P±ä²³éîB&~nS‹ñHnê’ls)Ü—<xEW¯ —3§%ª,ø»áfOÎ;Î­ ‘;;)Ò,ˆú=¥~èU’%° Í¯,QUs`Êvw ?­:%îñ5!óG¤µúÎ6Õ/†UH°PéqÌter58Ğ~:Dû»Íkµ‰ŸüÜÚ“¨
ûCa7rbaÚ«6›+°\f™‰@eÉ	ë®ğãgšãÑ™«=téëW}ÿ+¼[º›Ö)eÇ<÷~Ô¸ç¥FÊ¨¾zEûıÎ£[NOöÚf”1ß§nŠRi‹®ÆYˆIeE†,×xÆ!ÜK0y”`û-óó¯ ©[¹œ“6‡Snè™põèÀ¨v¯uÔ;Ê²THdXM†ğokÆ6ìrÄ|2N®m÷X¨Ê3êÛµ7e¶csXÇ>b§a¸­ëŞk?ÿØm~…×º^ÖUÊå8ûÆğtÀá]ù9 ğK8°7vYkè?4êM¿ÔÇ™Iœ‰¿’á«?Òß®]Ì-ß·°,áÉŒ O
ı`õ¦yªGrƒP!ØD}:êOıoÎ¶¬er?g1·°@ém–2"«ºm)ÏŒÜ‘g/«¥UäO+‚oËßŠÏ…KáÊvø:D„)³3·UK÷¼<]2…¸‹û–zÔñ`àŞ6¿(Œõ—ÇLhÃ-û¬GR,„æ‘CÕ®y
D§1ÛÇôvòÈ£²$¹?€€nÛï‡uĞá‰½^ƒ
ÿ×¯Èøëbvk	lë´ªN5}I\»¢ûÈÌ“»–im¦Øwş¶kIÔÈ‡ Xôû}§J]R Ífd8ÜÑ³íÙ¬!gÇ\u
Å;ªõíJ@hğEi~”ÅCé®ÊÎëK×pN{äGGşØá²«(æ0G¶ƒX›v°>XM:ç
àáI­{VKv€êÎtWIÅ‘‡p›4ªÿ
Ğ Òa®Ã©ÔrPY€„ÏÒŒ€JHVØ]i}—#¢aŒlËÉ$8	Ştg°¼ÉÌ²ÄåCşoZ'rôKüX|¾H#£#Í‰iß4²!']
÷Ù ªü(ğ{%Ÿà­­7jú9ğlhBîˆBa?ÅVªè˜-	ÙñˆÈ­¨O>Véñ+ÊÀÏê™¤ºdO®¤cHœ9jæËĞHtaè'u`×ƒÂò—ÙœzÙ¥áEÚ¿D•uÿ»&Ns)©‡ƒK–M<½À»ók¼s1F™V>‹îNòÀÍØ#Ÿcò²GÔœ@ä ôaé®î]JLY‘Õoü¶Ğ9gESå¾şâ!ôY®Á·Ü}C½œ=Ÿ>ÈÊğ‘Tôû…œË™bòWj„eÙãªV! ?2yÁŠÎ&AU{E“üs°}	¨¾hAb…øO¢e_¬zƒâ®íø?¶¢1]µ¼n3n¦ÓÇc‡¤ª!èÍ3…;;2¨šQóû•ÀÁ”ØìeÏZê^PØÀrq™kÕÆIù”4.·Kú¿³ëAº)‘,ë—Ušûi‘Ü|(=8÷ó}h$ú™yú}QTlÖNiŠBâ0ç^…Ù.ÌÍéˆb»Zµÿ°ùv¹Ë_ªxãP´ƒ@dI ¬'S”"É3Øñ‚½NZ’—¿Ô•¼}@hÄötfaEoË¾oÍJP·ı×k–Ù¬•·c„ïÈéb íXÖ}`¦¬¸/Æg† Íx3§¨»ùàl%­DiŠ<!Üğ*‡$è‹9¢1&<ŒuH2”\Aíar•Ôô<GÛ¸y¯øî±Ç6o%ydF¢•“»¦¿¿'» Ìx¢¤_SúÈß‹ràÓjF5^* îLk""QP°V.K—Nº…êÁ¢—7Cv\ÊÄ
ºÑaıEêoSi„XoğìênL	ø’õ­ÿ~ïpàÂÜ©påB„SõZQ7Ä$‹#vP„D;ÉúødõŞµÚ ¢ÿŠG9ıL«ˆ×÷•Ì¢1- ä½»ğÂá)¡WßHÕk5¢˜Ü‡a¯µÎ¼\z®QWoŒÓ*eµâC¢IR¾äÇhæšËYÃÎˆMœûÅ½§‘»ûü?¨iÖâ=¼ïC`Ô2õ—Ä=h^Ä‡íB·Û%‡D@#½PÂÄĞ=šiZYM†.aH©Âˆ7“ÜİVÕ3Â¸ßWÈğ(@Ï²AÛ`‘Š€}Chó‚`%ó¤”¼»§)~¢o8wˆõkçªØÅ¯Â»®i>şô)üQ-Šq/ÙšÙ·Z¹%‚È÷ôLy ä„XÄìO‘ÉúÆœCÊgnúŒâæàXCzÂHz0V1¸mš%ƒ}°î‚3c¡ßM‰>º-ì•ĞØÈäÓiîù'FË;¬» EùöÊ'5bz“ÖØ~(¾ï eQ`ãL%ñ0œ³%ÆÿuBR¶,n`–-À2$?Á!g6Üî
Q‘äZœ®µìj'lóĞm¤=ÿr—mŒ=O¡÷W‡[gU`‹5]áÙîëw±OM.²Ê1AŒ\¬¢©Q=¦t éMJ'°Nôİ°ÈŞÓà°gšgyÃoÍ¿p4JRnüÄÖU¢F	xHfAÇ7 >±q‚s›ë‘Cw)¡âøßiÑçº§Wh¦Ì…#o§A23ªÕg"×»ç8tŠ^¤2Qß„ŠÅ«­›©2wËêŞ‡°ÉePòSTË9ší9!)ÊòUX0x†ª7F®l)ÏôP¼Ó
ğCı¦]*Ò“‡G¯ŸJ¥9†q?_rg6jëòP¬F•?çŠ-mÆÛ-+DÖ	@°`Œå¨Ùñ­'şVÖş%ì¦¤4L®3{IÏÜÇiÃËÒ»©¼_W_FhcQGÄbeÏµ£çÿáÖ¶€›D=îƒş¤W©&·‚3*:ÁRèkK^Cxâ?ã]Å# X7†»v}ÃGC¬#ôó‘¢W«•í"÷@×!$öÍH”08Øª¹T³õ¬9}Æ=Wå'$íû0—¹½-•'ûVŠôLac#ì3I#5	„ÓÛÁÅÿ#{Ù©Êµ#m6ù½ß¡.hÙç"‹ÉûJcş|Š¯j¾Ë©"ŒNe¥îİE^ì|pX¹n¼³‹u©¾(¶¯dL3YŒçº|Ÿ_¨/Œ‚Uşağ»²°Ëà0=tUÃÓŠZrØ˜å©E¶ÛÑÛ¡o^¥m¢×şÌ¶èLAThbgZ¡Ì•–ƒ¹^\”5½ƒÎ•DB§tebğ*õû®Û_‚9S³%²¦íyktììZ­ø;˜øßÈÓÓ@gÓ•ÒüMH‘Lİ†GîäÕ®…i"L“>È—ªLïÕbƒ¥k:à<lÌµÌbE%³™c9 Çnyìß#?™wç´—wµfË—0–¶-ydk=ëÜº>ÏÓ§‚€ğU•Ûÿçğpƒ?× İH*øûpĞNú(0F€ËİÈQ_oa¾Êìü
œ¬„<éš
ì¢è´`³^5»~¹†§’5Óe^v›ÿ„hk2ê¢€„aiâ¦ç`ñb–xBŞ0í™|”¬şvzÂ'DjB	¥{éİÄÕ?Ø6şêï®€H3İ	4~Ç:|Ş»Y?ıøCOÇ}fÿøueHÄ&Tk“|ÄK¡¸w`OæcvˆV&2î_Ï˜€l‚Ó2‚“0Á€Î²>M"N ¬¯Ú3åmµ0T˜g¡¤Å†Şì;Mjuİh€qI¸¹8•Î(úóÂÛ¡Ùòò¦ç')„vnÔÚ=3ú^—;ü
»Z85–²=É“sÇ¤â¹ô6•ñ6ÈK5Yºä¹P#·ŸST0õ"ëc5‡IxAF¨+w 3€d¤	ô6ø[)Oš±>]¾~P›J£Ü´|2ğœûõ¯Êœ­]§êõñ:¾c\l¨Ô7}6~Õ×„FÖöİºÁfO—ÎH%ËE£Ñ£ú-·eQ9wÏ£“<Y˜òˆöÑëWckyş­‰ªIäN:æ¸D5§ûkè“M¶|„{M¬Ein¦ÍR•+º¥ïVÕÁ+pºõñ‘®v2@kãıê3Zúa/Øñsˆ+µ3HcGÏô-[báäYnƒG”£_-‚5+ş™3dY7óšPŒ/óÜĞİ­2D>/’7¡‚Inè2é÷„íü2,)ñ¦0~™&¸—ƒºõç9ÕGà=M‹de·IK=–HÏ·ö &ÓêÈ‡ºü¨0ANI@à®g°,DòUoL±i´bS'× `›[&qÀM <§@“œü4Ê^/käëá›+…âuß¡JÏ[êÿorYó%–š“ıë:ˆgQ%İ¤tA	—`Z|Œ×<|4˜¿ØöA(k(kcÙıO‹ëuq> ñ¢aaÃ{Â*
Wà‰ŞL£³W°CrJZ~½{£B—0‹OÔ³!E©(šc?¢ş^¥µÏß·¦©•è²FôuRrè5 •õã[QåZdã†îó'ãò¹~ÁD‚nJ“’5-£ÌÃø:õCh¨‘_BbœÛ¯ÚaK)Ì9m¤U[$ñ ½`P³›§i Ğ†ñíâ¢¶	²gg¸¹Òâ]cİiæ­p\>¾€×5›.HÕÀY§ãøòÎ’Ø*.9ÌÀ@ø”QşäRœèFÔUĞ%ï‚mÄK4U\<$ŸÕ¹ßzsD§Æ~˜sÜ¸Q4'¿ÇÃó	»UÅÃøÛ½	«<f<’I[mF?ãÜ))–KfO|¸Zklb‰°÷‚ßÑPIW³ÀêFï¦,Fß…78ÉİJıZj,§ĞÉôP×rd6h¤E†¸+Pí6¶Rò‚Çdé– o‡|Æ«¹~†Í.Ægf€&rV)¯O&ÒWº¤+ÖU’&Ó½µ’¼l*f˜bLHìJ˜‡î“/à/j¡ØnéÄŠ2ÚxÇ†¡bh'úÀfúĞBO(‘âû„2³°Â;Arë·¸g´Kìö ìy™e?€¯…Á	f„3Ùªëw]âHyª.ŒÒJò¢Dì/îØ^°.lbÁs¿S^yäÿgÎUÑ—¼¥Éˆxğu³¨šú] µó dôûcÎ:aTd¢oóÖ2>)¢ KIâ¾iÔ0÷!]D<„]^­˜Â”WúÄ›)£²PT[QûJÕcÛÛÀ,æ–xÖinË¡ñôğT]*š_å_Ñp*Ü¶B´õ…[  ÿVN;?æŒhãj&Mÿ(á?L‰Å4»’ŒÙ¨«¹§IH5å1õ°[§TTFT—û‰É×‘±ÀÏk÷×äÄAÿ~V•^‚£¶§%|J„^ZBÊJzLY’}6º]p»Î"…fÎìZBã>U÷Nd¯sİïyáƒ(iäåµ“ùŠj*©SGP¼Qs˜~L¿şM¯ëJÃ%1±QeÎ†ôèŞèeªI™ãuG’fñ3mµÖºŸı…ıŒ¢ rÇPˆD u|}®s>sÚÛePf`UÚrwé%.%»J›SÛs%ædQŒXŒfïS“¶#%”ôH#Æ®»±[áµs2ğèss_Ù@ÔsYû±á¬5§±àfV„Ú0Ü©µ.·¤LeÕ×£ÖR>†Üã¦âr¤u.Ê¸MÅëön•¤y.=§b¼}A˜·¿è•î.¶ë9¡óî[r•}{R¤µN·÷‡×Èê'v“0ß»(á5C¾n ‹Õ¸ÒPƒ¸‰&fB?I4lüû¼I€°H/ÊÈÁ’²v€Ë3#eŠmÛzş1O˜&‚0M‚VBb€f®İìªq.ğš.©Ê÷×«W¸ö!VwŞ~ıÁï¿åéŞ0MáîR÷‡sxCÍ¶1°ïëñ"‹˜(ƒÈ¨ş+¹~ÄcL5¶ÕúÒÆîV¤¾İæ•*AŸf~8‹i1–Ô¢t1<S	BN)ù“ÕËüõ6ké¬UYŸ¸^<ı@Z)KAğ®Ú³3·göëh>ö½†ˆ—z¯Ğƒš’5²ÉŸu½ÛíÆäo¥ N,ü
gâ
xÅ<¹5=ŒÄ&¶…ò¹ˆ'Xçı“²eÍ03&¤ºÑ@vzd^«R ıNz|¢?&´%ÓšŞÂïÜÜ{2”Ÿq´enàoeu°şe}~Ò;ï®"ÿæ-#ßw	jã¿"‡Üä¼<˜go*;Æ^¿OzÃ}>êÇßª%|‚¦ÇåH.iÛšry¯İ²<,·àƒWÄ‰M“	@-gBÅŸ¶HÖèÿÈ\zû®c¡„“z9E”(pé²¸O(h¶Ö”Weá9…É¹¦ÎÅ°í5¯Ö°Šú•F=æŞÿKR6™—Ş4Üãì¹–Ü4_Ó–{İg´‚A#†šÙYR¿5ÜâO†Zİ\,?°­ÊEJøñqÊ+4ˆ÷wÓ~ìŒ&+5®ïèP]§Ôb5 Ä8õ3f±Vv„†šŒÔş²evÏíëË×0'L¦ß¤/ìÏ°¡í\ÒòmÙDQ¿(*;UX-Õ)ƒçÖ¡µcÒ5´,M3IËQŠWÌ]¾XŸ—,B['±Î¾.r0‹%mÅ3š°ol6¥6kH5÷!ˆ;¯×–©R¿SÕ4Û†ôHrºL„T-j.Š±²ÎÁÿ·àŠ²ÁjK†)¢jÖ‹•u°ûT^«åRt®È ×"™[#F9çÙ£Æï¦a¢|y#~½A¿©YïdPªC}ªmì6Ô¥®ƒG@õãGdDŠµ!¥4gbxíÍæì¡·³è‰E¾bYo{w—¨”d|‘ÚJªvİôuXcaûLèmvÅuıÍÌ¢"¥AÃVÇÅ„A¥$eä=Ş±¥F>^RFqNÀ íÁ?VmÎFç2¬:çôñ ¢RÛ÷2Jl+< ÕpÜÒ{i»…Äçj@uëh‘Äd–v$|^KD@³/Ífßæg üìŸ]R¶Mı4¤á"›Ê|³úY{…?‰cj:z» ¥UŞ¢-ÿÎˆ«ÖI g’b0Õ
‰ª~h%š“MÛÜkVc¢¹ú¦½—oòĞ1şI«åÑvw`†­3+}G!ñ*…£ò[*
_§&Q|ğ
Gº„³ÖdX—IkBüNB8x¯ªÛÑ‰álµ©®sı³˜1?l27®8’;.w¹Ü¥:ç.{1°¯º~D¨‘y.Ÿ FúeÿaAj Ş|kÆKfz&ËA'î˜;¶7nšç|²ühJu°ãw›ƒ»Fb©úû6±‹t›C&ÙN‚^§ÿîk…¹¦V.íjïßM›ïƒü…•‚Ø19=Š¾KÖkMEáª„? ¨´¹I$:4;àüX.œp›t¯ÈÉ¡é‚än^‹
è/Â‡^pGèìgàRM5†ÍUf/LVƒ÷ÃLËËåÖ<»£_¶Ú€âOŞãmX	äêœ}ËlåÔbşBº«n>?a¶ÊíàçË?Y+"DY™’£®xÚ§÷Û„Ÿ"‚¯ç½ÌŠ¤¸ó$~j›¤ümÈêS”ë1ıÖèeñŸ–ú%…8N¯B‚iÃZXÊõúÜ^š]Ô¯‰OßÎ"w·Âõä)•·üü1°‹¬2@
ëqnÇš_Úÿ~íƒ
º€)IŠÜÄúÈ¢>äØ|,	HŒèº‘Ã¶¯œíB%«ÅÓ‰«!Î’œÅkÉõ¥£¶@!6ÔÍ{®oßË®8cuúa·®ıg‚MÊ§TmÀk,ÙºsÉg'ÇÕx¹±î.°ËG©„.ˆëbu©…åw»zn+~ğ"ß#etî1#~cs)Ø¬	5í3 äîU@>_ğDˆ}õHö6j]¼né‡†H¢2.á‰Rå\¢’#!€váZ¹p¥¡¡kƒ11¢´²Çİ?\î$¨Æ‘õT³Â“°Ùªê%¼Ğ²óG £9¥3VÅ»L­%íwu ;G®¥[zv©µ¸ı§·Û–à46¨,f@'¨Ö›—”G¡`^@xæ/î.šFĞˆ“	Ÿ˜ĞˆÁãHl¸*¸ŒÕı`Y‰”uÃ9XJ\1zËX®Ã1‰”ğ˜IÀ¢)vú}—h5ô|gêrÀ‹d§°<O£\‘x®©É%lÑg+’e¿Ú”L;Ñ†Rä	=$#Ù¸’0h¦ÿ]ch>$…ZY¡[4d/T<’zÔ›ÕŞóƒ;f04•ÁHËV``¥ôĞ+TµÇŞÚa|
Dy¸¤ij¦ÏBçŸ`
O$pYòbSö¤ùİ›E™i~XØkŠ¦¨ãgı -“û]cM)óMƒ‚Ëû\VÖtŒ>…®
äÉwºBâ v?A¤ ı˜3Ã.+M.7Å? 	§
š$!(ŠU_*–…
ÁB„§Uá§QµbÄnÎ2°+ÏÀÙ‘Ëò–Z>˜’FP2UœäğS8Ùjvà¯3Ñ90ajş07›.‹{KQ»->>Ÿä}nå÷àúf)Óh»¦ä§şJEp™şÑÉé@Ù<pÿ¥D÷â1Û;ıY&@qb¶z!“ùàüşšÜÙŠ¨¯9U”MÍ«zø	Ğ|·L$Ù|Şh˜VT|±åJ¤eëß*Ù”³ß‘ÖĞƒ|Œ·JÉÔvbÿ5ÙC/g³
[mäMÂb€¹Hò˜:¦hï *Ü6$¨rdùgjÿ°\/ÇÀ^ùºB*>+ÅJ(²É[1QólEWıˆ,şMÄw4*fÚõíşO8 “xÜ­ìØÚnfvf½€Íë[é!eIÇƒàÔVy¡{ŒVÉ‚Ét?Z	âİXL .âş¨ ‘R‘¡`13W}Çä[\ W#ñEFab¼&s¢¹8­ÆLş8—¡õdu\¤Âïovè›áAè¤ÆË›>Šz$\i›*7£Xí2÷ìÜ…GÉn5æM_\ˆË
ü¬˜¡<N M&ÄÏùyQ­DîÍ°¿şo~+YÅ³
f„‘^›-6ˆºCá¯Ú¢riVÄËÁÈi¡›mèó®Ìs3î†¼{‘+H^^pøÜ‡¢–
œ‚§u ½_íná{÷Œ±´“_jİœS•8&ê{iÑçŠ£0$>p§2|à‹PÓÚéÄ>óØ, i½~Ğ°²ÃıI–¬¬>-â
t¬5Nyz{¸Ôf±N‘¬\şğÜf›H¨áxÉ®>-68ïƒ*&İd«E”l»D0¯¬…îWÇ‡8"¶¨¾lî0[ãsµ­…¯	'‘µâzÆuv¦ï}U—Õ>R’™ÛDwQmC… ñqƒƒá±$ç×â‘=­gıˆñüîïıF‘Ÿ"{LòãÌÒG®|ámÙhìá–®a®Ûq‚ôıt¨¾¨.ÆFÔ	£°d‘¢~:â³°ÎF˜„=Xpa[fS6ÖRsŒ=¹÷ŸàÏ"¦èŒ ,Nb,€T‹Óóé7–ş5_'ğwõä3ŸTt5İ„ú÷®dp>ÒzŞ†t³p:‹¯ã}˜aˆ³óe@õ§`\z	ØäÂ–¬9¹HSßÉLT.³Çnzÿò=v|\Ñ`âD·Ên+µ>œ0]˜´lJRÿ)Ğ°Êkêf¾c%•³ŠÛüõ$èî$ibó-‚2]Yì>1{AL^AB¿së›i•Áå]£6‹õßöˆª§õè­Ë”Ps¶C…‰·Y\“®–,xìMÖõÎÄŞÿS.úç‰=:Tˆy±Šµrv Uı[»ÂQÎ„mœ~ï4p¬ÚÖß¡™™äu=iœá&Œšm(,¸âõÙ„.ĞØ Òp+´»ùWˆ€£[Z3pUşí{I_`-jhÌW½ÈPMù¦îAŞfÆ9Óœû¡…I ğçQã(5CÑ¯¿èªü|©ˆiÇmƒ•ÁŒShU§êÄ+ñÌ]«;ô¡`Ğµ:4Aª| ×H¤ıf—€RƒÓ1`„æÆêwö%”=>ôj•aB^?‚Gõş²V”.›Ãí™w3¬®–ÿke»F’¾ È(èdá©og•™ş¸É@ùß®XsSİõã0F£y±óÙJq^µæñŞï_Àgõ=°e¾ÔZÌG×fjñ³“L#3ñ~E?ü5yX½¯c¢q[“˜	–úHbÊx:{Sâ[qYÛ÷i¦’a¦ëı™»®Èã*ÄÚl(ğG#%ê ĞSğ,N¡j K‡êÍ"jÈçúj–ŞºA€LN5–áÛ´5¯ÈX
^´Ø¥i—gcI5ì”;ZŒ“]kæP€:K *Å`½Uq×˜rû>#]™‹öTàÕ?£àRTÆGÖË&¨˜O¥»§HQƒøìÚ8JğTQfĞ¬g»ÌçÙ›Ô¡/Z¾!à§'- ¼ ¸ó–İæ4ö($ ñÎ[ì¼„#‚xÿöëpL£|cşìåÅ)_¡êÈ¯Õ“ö,Ú£ øD˜qÒ
÷Ñš/v4TÊ_qÿ†Ç¦Í AŒ¶zåV5©'%DõùCû‚çTm'=ö»áƒÄ#\ó}ÒX2õÖZşZpÔİW0“q­¨!X}*è¥àÚºg´ûY³±^ö'aÃØÎ(Ëg_Vj[¶ûpcp$k=_	›ìÉ¶9ªë"ïİ3BWãDWßšÓÊ7ÙÒÊÍÔÆôFb³xYjá®W/l¾#k±­|Š¯'x 7ÜüÉŞ]ÅˆÜ½<&#œLâæR H]2[‚ój+"}®¸å˜©îÜ—OXi—ø›§LnšÌ‡@¾›•¥$NÜ®¡Ê¾¸îz¼­Ÿ¨°ĞïPØ<Ü›|)oª¨•`¾¯•˜s^ª&M¾*±düOÎ,\Oƒ{q:‘ğ_ï¡…ƒÕŠSÈ)Çr”6}‘^s¾Ù‹Œ;Î%ùÙ’}ê*jnÿ}Oğ€#ğ‹«³£#ã9£…AÀ]Tu,è¬q
Úó~<Ó~Î(é- *´ –…Vî0Âóƒª0—éüU!—€Ë*‰«·Å^WHDsQa¦•ï/¼t¥J­ë(ÊäÌÄ2-ttÈ·Ÿ]èt'X#±J1[3‰>„·fù,gç–ÛI'—‚…Râ©R­÷ÄèEØHK•%è„8•	-‰P, ÕAšç½Då²¨¾ìMc[…FŞé,òº 4Â t.æy&F2TRLËY£šĞlÅJ¶®¥ˆ s©ÌøXdƒå_‘äò•Ó¸­;*ãºšócéÌ:áä´,×cÖa3ŠG«}nwJñI?7½
…{L7ş(¯¢Y‡H´æ,;©l.ñÚóYÓûºZ')€zø´YšÉ7;3c)Ë”!Wõ+†À!V¦Ö>¯®—.:Ù½	1¥˜˜áâ ­îñ’sÁ7N!¡8@¦¯æïg‹›Ï$ƒjŒ_+tCÇ}ÓQóçò<dhC† @ø¿ÁÚ½µ‡`~ {hÌƒqÇ¬Ô-•qî3›¿­j,ßf²åÆµPÙk€.Ã¾ÚŞ ²éånláÂÑ ŸpR°¾†G<¶ßL¤ ¨u´şA¼Ïî†NBfv6à%ÿNÉ°±KoE?òq]"—ÌM•Óíâ¢Ö}³^C`Şpc!íó\Õ‘¼´¡íg×7òüuE yÃ2Œx:®Z¦øY½YSvîj$½¥„øÁ°Ä¥×†¼b¦‘YhTL³ÊX 1€5rdB‘sæ &é}ßú½Uƒ÷«Ô^@«'x_9Ôó4Fß§íUÔ'1o2å¶JdÆ[j 8û;íÍ-&E®œ‹“b®ÜA\Éåà®A¢¢¨Ó\vq]¶{ÁÀ¥½ËVh}c3Õv½Ë]û_Èµ¨¤1€wgO¼'ªü|+Alæ
f=Vk±©è’Ó EĞ8?])å¤¥µĞÚs…EæGAB%@Rğ_ø«k””\«ü%ÿzºçÉ:¢xÆ²dIL)£pÍ­Â+%‰ Ìì%~—Ş‡yÎ%ßUÛmvi=OÓ>]ˆvíd÷ß~¡Ÿ(á¤Z_,GêÆ²Ú‘¡ŸZëyt¤¥V‡kÔD¿(¦Ep¼ˆS`~r®‹Y¤*¹7ƒ?c¢¤MoÇ“z¯Ó+<j²ÈW\Õ~Gî“WkošŞûæî:¬’„§&¡o.´à¡`‹òËÁÿôHÕ¡R’œ2OM»=ùî[Ïn/@ GÚËÕqˆÌ{ZG8tAÈA4,~E×—”®?{òPÂ?ÕÃdö‚svÃ“°‡ëW¥¹‹şÁ— %ĞˆTÄõMg*µ%"º«HÒÄ€ÈYødŒS³ì;²%¦%ÑÛs½‹P4oÆ!ƒbWŸrr[ÓO¿@êá™"¥
í÷fŸ7‚I1ÒYKÉ¢êRb`!*µpAö–^L[zÑ¯¶eZ_Ë(p!-?Æ©©‰Å’òÎ%ğ¶œxI~.aí§úf¨å~Øİ´k_!µNŠÁí_DŠn¬ı5„Oƒê„Ñô)7½9“¦'	ot'¸\K-BÕFZÉ‹CúÃ1&bóâ´î~½ô1\¹Ä`KçÊÃ]zÑ•˜°ïµÀ,Áß”qöÙUËM)Ç+F]ñB)a»öh•…Ê´kÑÙÚ’bı¼2ÑDà5Ş*¹Û´†[	ks<3‹
Œµ3Ù¶ í¢îŸß=áu”)`©\ü\’âÄ®QˆBà«¿ZQ?™õi÷Ïl~ç·ç& áÕgëf¦Úv1ôBW×pz˜È©¶‹$NÖş!t\3¾%h‰lnì‡7IÕ3îü@cÓyAÕ{#­¾ê9KEz±+ÔBï«uW£Õ\¶Ö^Vèîü©†_®¯b=gÇ·%ßáZc«P§”§”ƒ<6K}º^H£†E´ÈeÒgïsêÎ#û„]„!iïò³BNõmğ,ÆÌs:$#”¸§wíƒŒ]—zU¿bå™wì¦Í›zô$QD¶EŠ$÷÷Óª¥¤=ÏøìŠ»rƒã®ÄØ™–ã÷_8&DààˆîÀƒl ~®ÏÈ£B~gè*t?œèS|<õÙ[f¸vŠı›ÿİC·?mÙÄ¨©ÑC#*¹ûàp$Pe§BLæb	U!Œö®¤q¤o Õç?Âd¯ßº"† /NP]‚ n«l
õkïY«p b{¾½G6YcìM¼ĞäXÊØ,ïí6¼¸8Úïø}/X“Ç£C®›[Ï<Ìh¤H?Êë[%ê®n3‡Ñë6»¯	4nÔÉZÿpèµïc¨â(„t91„R	›!ñmáìXÂb@€X¿©_AƒNõx…>>;Şd¹0Ó‡$£…ÉM~nŒİr³ÂH#rïÕÀbo"‰kmœ;ˆ³Ä@Båg~Õ1‘è¸<B›@ä¿ÖQ$D
ã¸’aÂak1‹ÀxÇ}¾o‘e[^³º£B\’NôĞÆebØŞNGdM	æßÔìòBC‰)ÏÂO’ÙÊ£`ÆƒH×Úä9ÅÚÙœ*ëÉCèÔn‡¸Ì‹kÀN*Øô(Q¾AM»w He„Ú›Í¬–"<ß 1ÉşÚ’²æDn>_°–tnìûo]¢\˜uAæyØHÉQuDóÆe6¤_¦–r™©Êá0êÊ-:8jÊÆ{H~Î¨Õf®¸Ó.ß‘3åúì"‰=À#JÈî¿J-k´-Ö±ƒ]„&ä“«Ñ°ºÆ™	Æ:BA’¾x¹RZs±Âô@¦$×È¸ÿÔ×€Ùÿµ4G‚ •œa‰Ğ] d,üó²G×È(Ã2a^ğİTVNÔ•,¼\œ,[è‰D|X»‚h:Iñ¢I/İİcV2,}óÒñ(E©Ã×í§Õt)Ía?ŒnëEíç"Ø—{Ü?t! ¤/¢DŸî¹4 ‘ìËZV½ Å¿lv;aaYLèooM
ÍâlÂ8Ü1ƒf¥‘¹†şıgˆV–è­ Ïáõ”°€¬ºÜ$T»%ÿËF®.ü3ò&bÏ3êjîËô`Åmïò,ş“€„ĞIÑĞâg`Ü5õ¯Ü¿¶±¾«·$ö`uÆ>èäzÓYÛy£.ÇØ*	›1\6p½œnï…#ºFGò—Tãáézdšcò–ãh|˜§]Ì—D!Âºö(³”‰ü=g†ÉY\»	2±Êik¤û ñ€åQ’ì&Î8µ¹(e¦±@j÷ıjœ2vûueÑÌƒ·øuäÛ‚.Äë14Ş7ÈPWw¤tÏÜ¨¥ù6t#ÎÅÅ¯‹ªV3=«ÛZ]²[Y–eIµ´u¼ z€	L&î1…ò®ÛŠeihüÂí±]‡[ÍXHœ?|2My@ü¦N£P§âÈ³ySªÈ·şUiÎuœ­`ÌÄgXõ‰¿ìÕZTÒpùŞëòßÏš :¥¯wE1©
Ô>è	Ö¡,ÙĞê«Í­xîòLZÿUõ	–d^Ÿs¢)xæQã³¬öÕ’$Z»Ç’ÉËw!ùÅœBÃY}?{yVÚ8nï3Î‰ÁÀd¡-Dq¡·¤rÄuO 0.ÅÜÂi4–ˆÆFÊàåÎòŒ›ipù€p9LŒŠ‹ğÒ¯à:ì¢0	µÖÿÂT†`ÖB*^ÉIZßÿÇsd*gÙŒâÒIVG1L´8ÙÄÿ¤ë‘“ôDÈ+©éóŒPõJïËÍÛÛùö¥tİJCím •4w¶×dY)Ì"åxi–†ğóœY¶¼\¾mmöCÕ]rcØÅ933b+ku1h°]G5ZÃûò@k©G€Q“äS]„|ò ˆj‘ãš)¤è'zrÎûqLk_Iô*pRûóÎò8-×SnøJ†_£ÇPìK–³»©IâßY™0’á„†Ìcãöw€]+Hp0“í-ûƒFlx=˜„6–¦õšooÉEr”­np`¤Yş>1Ø¨ùÏø¾sI»mB;ù1BÒ&ÉYBPû+‚M9?Ğ–ş3Ü\§ËãüéKıÿ½``Ób~nhÑÚt‰òÂFS—$s×Åagç• #Î»;l*;°f]`<´¤z‡f'ö%iòNB¶o-@\çûnæ ÉM¢ÌÄÄSp1àXS_ó0È…b‹t£kUVÓ1Cy®gµ*ÂFovGÛÊ¶JæÇÚß2zaG¸¦•Swßí©Ìe@æÈóA|ä¯Ñ1Pë„v±r4\şÂ­çş§‡ èÒíÉ-JwG}@©½i‡†+—Ç@§mÈú¼ŞÈùQ´‘Ë;Ã8¥-0İ³˜ªX´€h¨Ï¶fv½2xøHâv»¡¸ƒyjØ¦ö›Vàô[®v[º¨ûb7jj3ùJ)ÄO„Å Š
®D":Eê/ÙÃJ.ùi)xMÅwÉ÷•ïHiÿ%F·v„0’L•WÁ¾µ"—nê©íE#5ëb67zïÍ°½Ô- ÉlE8pÔæ­Ìü%LaÒø-qŞãîNğJ@c¡iëax]^§Jğc^óPãxüâ³¿âylLRğO«:ßªAº¤àĞôÕ“@b½–CVó9I+Ùšˆ£P‡«æhˆıb1ş˜8«jÊ/Üd¬PA{1…„2~l8ácqnÔ³­#ácˆc¶»ÉãÒí.¾Ãßê!¯'cQ@­KXFá‘©§—şû? ¤êIh^âü®NuãÇIa)¬³ë–b7ĞÓDcA¹*tn‹P¿]sññşÿÉÀ´60:Àøå­k¸.ô>pkózôˆWCÒî¿to*EjIøOsº=˜ 5¼¢ƒ±8Ê*D)ŸÄêh;KM:{ÂËM";F‘÷ ØkùTUå9ñŒBSGı]‡Üèû¡ÎgÅ£½¾Iú‰Ğ	Ğl?æ„¶î4@'²cÎbÜ}Fa¡ˆ Èìeô™ÚÏ¯Š!‚WÌ2éfSC>µ›U]Ba,Z7–ä:M]¹^7JüpÏ©Ípî ÏäM[%T¢ß>Ntb„/ì·CôV*v€"³ôCbµ™Ã’ÏÃekõ(uğøÊÎí+ r›å·é².É*‰Œr>çÀšNev½B%ë/ ÒÓûĞr}ÏÆS‚ˆNë
üfééÖkƒE°´Û~*ÊUŠ®?Ä}dkK‰Wú-c½Œ§Íù<¸Šá»<ÎGÖİ U@eGÄXLã±ù®R’õ[Š¥‹3Âu,ã$~›:‰µv~”$éËo™•î¡‰”òÉD/g£åÌGÒ÷±l‹L}óét¿$(ºşâË‡ğ²N0PÚ	=µ'D¢{ÙYuu6½–LÇ?Q°ğI“D½O6Iè,yv¿ŒÔ…CúÒU#†áÖyÄo-‡İ"3EzÒ/ˆÒ¬,&él/¡ÆbbÃ f‹şù\*®uûz*ú,¿÷­l¹rYŸ vÌÎ‘E"æSü _2Z’èâæCî't¿ÈË@L<¹#|‡äùxÎĞº¬ó'È¶ø<t7¯œŒ2+Jƒ!¼ìÕpŠ»™MéoôÂ½?YéY´WNâ„–f6r4#É€¤Ñ¹ĞOïØ~ußı¼¢ÒSW)a”>b~´|–°DbÕÎ9€£¸á=,„†U’ysNSBî¶ü5»¦Â÷û¦¨ÄÑ0×el9]F-½®`Øõ_€Hë}ä…œlv³7†ê :‚†KP¦Sv+P´Â«ñP¦4`gÈ©!éÍŠ*!+¿k.##``Ğáx|×á³p#ş¶;no˜ã'OÜùl!î“€FOó ó­Q*K°H]Ìã¿ûO3¨n€…Sô`¶ÊìÛj(cc¹)ºêî¿ãŞÚN8p]¦4-T‰è•]¤+ëÓÑ9Œ£å¬cAˆQ¦¼¼nn¶!KW«RĞñL£W´¨d±eŸ;óS]÷^ôpP‚-3Ouh…?F‚dÌïšŠzª WÂ2En=ƒå°—1Òñöö(°.ùšiE¬D¨tKeğ¤Iw…CkA ÿş£¦ğ¨v¹XG‚OŸÀ_ÙV;ë¯©+fj§ÛİZíäºcm2 Ú?÷…M‘z´0Ğ´;‚„kjˆÏZmKbÿBĞ„K)8ĞmGes-¸Ğ1!GÃ¦3¯ÎÏl/ÒS6—¥3Ñú—‹¼{Xµâ)ÍzÚZ’ÊŠe&¬Q=U‰eÙÁæ1ÕÒmì9­{#?–	¢‡êá<rû7âîÉÇ%A]ÿÅo’h%ã­Âğ¸ÙÑî1ëë¯Öğ-FÉ…_+æ›‘%©ä»A§aVm‰ABˆèÚ®¶9c=ı…ôs-ı]-€(á“\¥Ï½«õjÁ,2í6Âøê[Hy.Z)ˆ¢ÿm¥ŒÎãk‰ª§ÊÉü Ä‚ä‘SK2KÛ?äøÌ)ÖÄØÑ­›³4XDe‡˜s—ÕnÊß~D µÜ%ºénixÓÿÚKD9¯æèæ\Ò8›„ØTQ]U\àØM#@bÜÀ§ï÷°¡bKt†0³ùûT"¢Ÿ®¾^ÁPó{1=.Ns7{ıÂä ä´(ì©Íò¿›ªb”¸(T^›©UE!eÁŠãcÄan¸A_Dc95¯o	õ`¤¦wvY~	µ¾ò”_½?ÓaQÙ(ùFºà9¥OáÆxW§Z“¬rî)*˜ÕŞ{G6ï¼°±Ì‡+~?]†™ÍÖA%(	¦®Oèÿ2–0’µÛÌ­r õSCÍJŸcãF¼Ok[ÏcÕs9ÅÅ(MÃ»Øë0—®dñƒÛYËÃ¯“OUZ/_cá"
ÚÏ€%­+³áRu4JyIÂÑkòÂí‹&M“"H7ÅµËë%
7MÛ)ÎE–ao>][îÔè¶ìùÛJfÈ!Ô\u"¦ïrÊ+bG}b«®•{«?Ï'Êå¶yqŞbÁ¯«G®Œ›„Ø”•P“î®J†Û›è×Ï—ùôÃW¿?6$nEå*‘f÷’Ä‰Ï³K†¨‹í±*	 ^ªŒ©‘Ğ¤²Ábö‹´‹=X»Á8 Ä<‡æZq˜Á¿´{~\7´¯ö9CÉö«ä†ób²ç¹ËµZD55~rAÌwó5Ô²%İBY)ÂtëEûáJğy0¦Y*PlIÌV¯¾„v2d£®êÃGkOÚ*ã±IëĞjÀò¹'+éø>#+Qce
¥LÑ½ÙÂ¦Ä—iıÜ“'À“â€¿uš#³½ ³¼¹A)¹ò½RDåk-ÏÖÁ§-¡€€Şş‡*íĞšÜ)‚÷ôö¦r!Yå¥pc ´•¹9dI”U'‘[®Kz¸)ÄŒ¦(+“ğì„]Ô“iâOÊŒŒ=HÚŒ¼åÙ$¿PªãŒ¼eòƒ:gÑå‡UÀ`)²tÀW·}Vâ7‰”­~›²u\)63ÎX6°äHÆ{o€O9Ú°‡İ+K_.(ÜÒÄØ®È–Isîyª‡âÌÛß:4¸£ÙÜ
À‘¤¨€½… äÌ¸¼ëßŞ[á0´ŠÌ~l§Ù®4–6ÿ\¦Pø§‘Ï'éû£„i,ºŒX{¶~ë/¡àªe(—/&Ú—euz
£zØÄBGª„Úúñ~øw2•U	ÅbÖßÜ·3f‚ÀœÚ·y´ù´hÍùÏÑ{s¾¶•»Ü& @4LcÅõrğg×µÊ—R|nOo¢ê9šu#y¬¥q@Ô×ÿYd#€?mtU¡Şö40Ö¥`ˆ  ÅªxóÛÒZü”7~™`¸¹/[{!S~ŸFË1¼	ƒ‰DÚ†”7Û B¸KÄÿtAŒTınZŒÿ~,­ÆºÅÚr]I´Å‰»4¡ÃÄÀ¬÷"÷X	Ğ=%ÁËBï0g6•‚«*-Jv\:»r»(ù|é*›^²í=0§êÌÓ´ ã‘E´âöÕÅÊÑ1ıß4ŞN*<*¶ğ›Ö÷«,Xİ„ÿFæ£Ö
±rä¹ÅÕÊn_uıÓO,cyê9Ä¹¶™â´0j}ZÀ²¥lqp‰!õq"6kjB^ÅaGõì¤ùaş"âqm@Å×€í},+wÃÚNÿ¬c¬0²aÏ$çƒ•@$Ÿ Ù¨+V2¨gİÿJ ]ŞÉÒ™ÕÛ“
Ï3£²ç¨uåVGàÅ~ñ“™!D’{».›.SC9{È‘ŠÓ¸·mÀçäŒ?\O¸6”)Pšªğ!eAû¢RêÚA^ŠêşyC/°E¦½c*‹<^p?@fO*\³9Uì4"?„)óä~“äŸ÷…0YÒ4©ã™§8à4+ÊFç6•f£_n³¡üP÷I¡ğúÁÁàö¢ífàº¼üS£‹5¬”gÒ#Ã~µŸI-•#—‚ƒªäYøÀ6X¼º¡T;n²		@A÷î0—µ€ÆÆñpí@Ô½w/U¼Ç|£2rY°”/`W#×_>Ç*„t{ÜÓvŒx»Qd6!¦m†¢±Ã•Ã‡ıáFÆÁrld™tMLßÒBfÛRRï/”úb…¡'6è#Šp¹ë{e>6?’[¾bÛEm‚Ys†²0¹0R½v‡.™);©cvÙ¼¹z	Î/C³Ôağ•ÕM/SKï¼Æl@BW®/á)ü»
T ±‚Å¶ÊZcßO€^çÂ¤*ìD6<\ó×¥oJğa—¶‚€Œº»(ù{å¿0ÈqŠ&igÌK°O“Ä@ù)JWËÍ¼8~‡N”<XÀß!9ÑÖ²å%QRìy¶÷U›Érÿ+Ø“ã 
7|ÍW(lÃÅ‘rxY0&ÿ|€Ë®DÅbš6ó]ÌïNjÈè»”5ÊÅxƒ¼
óîÃ2`I£y¹–¸4©–X-'shtÊË²ĞµgOŠïT:×aÿã¶úórÂwWßŒôN"–`ÙSõ\ÒM…òğµ•uÚî4 ï1 `.z*Õhå4*
dY+S¼&€LÈã+û¶§¬sTàqö%«DNÆ[ü’(ìiŞ?$œëf×”yòĞXmÚ¿äÃ <÷m9˜4»zl\V	iŠ•“şJ£E5Æõ°ÃŠ6Ï©	d Iæà¦D¤±¦0­42é!|ùó=Ã^«Ö#Ë2Z2œúşÆ5|~³—×lÁÿĞ¼Æ€‹¬0¡R¼=yùÖÆĞ÷Fc½Àñæ‚åÙÔ:H‹;€WÆ1¹¥‹g6Ïd‰^îE70aĞ…x¥À10§@Ü43d«§¼°ğ€—K#x ¢®aŞÜÆÂü(Ï˜ÿ·VÁğÔ1PE 5/ø«ÿT£L–ìè‰àn\„x’ëOä`¼k>ğòl—²³Wh‚…q‚q§âˆ!:\„q=È6]+à3ß·d9	î‰páh©§dÃ.§ÔßPŒ6 ëä6‰¹Ğ	ÂPÛLÛ—š€È†í…_%&µkóKº·Uå^¼§'y¤úâeI×†`1<İÒp¢²«T?şéÿAM¤¶Z<Ÿ=.Ù í Ï3vşz¤ô—›X+x#m†ò0às#ÄÌ)9^ndC•X˜£øn½O'ª<›ûA–XuÇíÛİLã“}ˆ{²£4Eœ%Øalàæs`bxì½ğ#4å´ˆNÒ
bFâ[×ï‰%íóD€Tü€q3)qŸï¿c¡Ehxº8£z¶Ff‹…  Rûúµ‚O ·ûÎj>ãÁ¸&«°**³#ÿqÀc5†“±¤şc»ç6ØpâAY¶ªŞ,	'ò1ÚB Ô¡ÇDC é«J‚:Èc´ áSQb¤ç/»ßRp(B´÷B‘lŠ‘®úÇ‹cO!¬”—bIu]‡ùÑH­©İvé´J+=ãíscehá–nØ»*•¶Êäµ4ñIĞû5næA%{‘9ØzkvÀ¦7EèÏ>j$;kÀ mPâSÒó"³ïİˆ¡»š©axÙBŞC¾»	=ÓnJqûå·U_ñ¸p-Ä²¦QœiD‡=>L˜ÇÔw1¾)ã·a×–Éƒú9êlïŞ»Û&»!1õç¥"`á+ºFÍ"vÌš”¬4£I÷Óº$Ì´<ŞœûOØ¯\ë´F]†I´ëà%‡Š™ÚõŠk­r¼îv~z>ß¶+ï¿MôÅB!Ù{ÆÓœú|şJPÓDŸĞÙ5‰~0Áğ¿’e	9qÍâ	}0á{ÏHÉ‰‡-œÙõP>İ4¯ŒÀZ#æ$çÀ4<–}ÆûéÓÓ I )Í»yúëmpŠ'»j4îŠ¢m¨W}D¢ƒ&½[/Hg6š“¦wÆÑÄ„„¼MÇó¶Ğ,m4e¶€"šç)£Ym £ÛyÛ–•Ô,%¹¸ ®³!H@tÃ’kûÜ?ğ´1Ñ—„úó+»w%XÚMéÖPbqTÙãqã_NöFZbĞL¨iªL*ŠÌµoÂS÷g'±Ãp±àÅCZ-Êuª‹ÜŒµv»ih…ğ!‡·IlT@æı„Ù!H+Ù‰QÀù.¥ã`â
†XëŸâUIÿiÕç‰XT8¡Ë¢¯Ngºi„¢8j’éĞùœÃåÖ	éT²—3HÔL÷X¼peD}KBü³tÃ],ÏYç“³Y6Œp}wx MÚgúÓR!ÏÈ­ıeS=mşÊ·9Hª€Ÿö»ÍôÿñêE*§±Š`Škêèa«O¾
ªE=èÓ&F–Jì¯b ÷±ÈÄÁõeò4ŒV>ÜY”YŞß©mN"‰¼@*§ÈZ$!·|Uz‡H!ÂsÖb‰¡-	˜hA‹ŞøÔÎš„jE0/ßsèäŒÔ’·nÇ:®—KÔÏ!œÚ‡NVM_°jAŒ3“Î$*/²VG÷³ù»E‡UšIïıXyƒ¢Ù w0£Ë^‚Ô–ÁIqä†ÄÌ¬æyyæzâÑä_YpMBÀ:i……ÍkaO{(ãÁR±ı`V&P$ïSğÜ‘)v%’é,İê(v`Fa¤b¯tÒÁìrê§!ÄÖğ½„’.Ñ¥iƒ]ó®İş!ní;/ÜîYì€)³]wö-½hŒ»1XM¶Ö¨·(´ÏãÀÄmrCùÚ^_´}å¹\×+*†A£|¾É tf(ÇïUÂsLGÚõsÙ¯^”€aüŞNÍß/Ñ%õ¤eÍõş+ƒrpA¿b-Znƒ›"æ›b<b«?¸_~‹u¼•*êÊvªp™â1`EÅ–1–.ÂE”‚d.šº˜¦ÑÈQ4=óûğ*Ò(f‹J´5(¿ˆ®*œ‰Ûg¾ÀÀ¡	ªKÓ6|ÓCun·£Ÿ2ø·Í‡«…¥)ÒÉélmâmp½×M¾ÆNö‰öfï'šĞpªJU~Z?®I æy²Õ*ûL¡eÄ™ÃPÑ©ï0­s´øo{Ï™¦9ç²Ærÿ§O&ÛõŞK™ g“öØÄV¥¡‡[§Äq5@@{Ù¶já1ÔÁYMÉ>Õá
}÷›§˜Úi÷3-fötÕ¦Wş^n _Ñùì®l?úpzÜK	ßLßb*›õ
e,È_k†ûÊıå”k†
¼…ÆÍÎÈ¨V·m€Yãiù·¡ïè¬5(S†˜.X^B¿ƒS´&5#âˆúî³²©.¥ÜÄ™á«üÉtó
Õµs|ïá:%_•bc; DgK¹µËt«‡í– 1z¯dI¢¾ßVÊóèÌùÜ22.
–fmDåäR.òM:±BL}¿´i«ìˆ¡-tú|K·a ÃĞ>)³ª1¶Æò¼!£WŠsivÿcWò¢ø +‰™É° wAÒºÂñsz8ŸÎ%u¿+h+G_8&qym‡}j˜| 8lVªk lAjdÕ-Şœ¬6„zß¢H\EIäærŞHËßEN"wäÊB8–eU¹ôw¼ï$‘79ĞáŸ¸O`f Ÿß†d†,;ÈFxŸDüàbcMBvhÕ!ãÔ_MŸÔºöqÁµs‘½5Ã«®¢¿oqÀÈæ°—•ëD-D÷BÚĞ(õ;K$*o˜qÌùuNHF·ÓÔ®ß¯/N6Ûñª¸é›4Éœ”
ƒ·Í¡Ô	Sûí¿áİ¸Gƒ1ğ—Àê$Áu×v6ˆ !¥³B”¤=Ós{Ö_1»DÜã]¥¢.)Ñ¥Å(Õ¡CÏ›Ø:R1ñyù{ì?ÛµFJŞûë­=¾“€êG„Í¾wö¨ÃºuJò:ÜG•	^G‘Ş¬•!ép!¦ĞA:HH/¼iİ¾*’n:Üâ]ÁpÄ^‘},H§›=âù¦.±®ÍÅzb­‘¥Îòú-TX)Ö¨ú*7å¯7ùÌ8L. ”b„•§Û<®ô6:T7ìêÄúSà}^‹k"dxEğÎ•U"`­ùG©“í˜ÒÚÚi:qñP<öÄó»ìš°SÍŸ±Êçm³t1™¡ÍÖ›#ß¹ÂUp½ûázİ2WPÅN,5ü›æH–}ÀÜ2P7MàóË xQ÷ßÁŠ,{ìaç4ÖÀ‚5¬èš•íFV|)³ä4Kâe	ôÂ±€qa˜	A·§jÀ¨×mËPPRßS R]ïcìÙ4Kæ³¡FÇL^„qnÜÍ=	‡ƒŒÈQl>$Ä½}½%ı3ğQó6ê3ï°uÁ¥Ã·ƒá~uá%‹‡÷%Âj,M&/ºáµH¦“~G #d‡Ñƒ%v—ÌTuşpËÃ¼³VÒeĞı]¶ó´SK ¨C‹Gã=rã	Ï@!à*u¡ÈCX/›Z*køîâİDİ£6$§&Ã€˜®õä¢5Å{‡í¶rL/v¨L‚¯½jÙÿ“Æ×¢zCDß¨ˆ1d"*´3ƒõXÊÖ &8‚Ö„«ÃUãò¤(vàwëâv‘$Gø"ü]Ñ%5ÑhK

Õä²Ç÷šÁÛYÙ8¬Á…J$™õÎaœwÓ%‰Û¢Ó¡íºh‹s8qËÚ¬a_Ñ¹¸Ç»6Lï2ƒ=¬ÿn`/ğdDN‡óD$·„©Å§`¶ú0ş—u6 ¿­ù¡VøV ï3®<Ê/ëÂñ­ÖjŒúË÷RÑCd0f9¹›ìp®f—¢}çÄ°ùí‘—\‰(*ıõ§Ä– áäŞt¾ŠóJÃ•p2Z)¬iN=+o%XX8F‰YÎeFbÛq—\éj¡€ù°’ç×6ğ>³ôv… Ã…
=ó}Àæ²ÒÆC²š18»&/V‘z¦‡!¿â&ÔÕLxÅ<Z:¤ø8UY®·³ID–~Ä=Eô±£‘¸Èâ &!c0gèĞ>mHaÈÕš„‘“°-íŸŞS×^„}!Ø¢æÀ?‚8ñ‘“Aè0¾UçMºçk;H/öş$ùx-û2}B ß—ÑÔªãÑ‡ÇÎä:ŸjêG‡Ùñ±)ÿ=ëı£óV	é¿b»™ Ùe´/ü ™¸Få­/ÅAµM„×İá\’¦9h„Øİf4ƒ!cí‰³ÜoßD À—D>ğá­gxÏ.ÎKù”;}g¸fİjÓ­(Ú{f+÷ÅE7T7i„ÆCîo»t3tz»ÒTÖúåÜGW³Wœ¤2ÚËp{ÎE°sÜ³ìöºÎ€kfBŒ~}:SR+ğ“Ò2àë²G|ÊUòÊ\¿NOĞ½cü1Ş~ã‚îa‘÷¥Î€¦ÓØ¿ÂÃú=ÀÔNÿÓ(‹öøÓÑ¥U…©!÷ˆ¯BÄ=“øóÔÀCtN!óãÁ¡Å`šµÿIëÔ…Ş—=éËæÕ|–B²uúÚ«Á+ƒDÖ³h€ûy:ã]îzh‹½MÁå!ÒéŸ³é“âøFàk1µRûçuÄk^@a:Âõ“VÛ“w  (FÊÅF1H Íƒã{,2°C­3ÿV½¯.nóõ%¿)¾úµ¾zÓÔ»ÎB5w;²Õ–ºQ>PÖõéáçıáÿ@S§bú…Örv8ü	•ãèßTs{ø×ÆıÑç ›C/o‰šV	âŞ}trKh Ñ*I¤Øp—ú›¯Î´bŸd
M+,Lİ
Á™¢1ÚYÔÿ´‹@¶pÕ¸I¾G‹r›€ìÓ7jÚÙõ²Z”û^‚$	™ğe£f?Ên+™‘Ç\>\H*OVÇQZÓq”¶(U¼o§}¨ êß÷ş$[³Q„?Ì›z<—7¡plÍ™D‘Ê¶ÁëZt’†„ßÉ˜Áø@ aQLß||cëÉnËºK_* ²&k üêÇU @Ù»êİ–ZÙ2\€šÏá«|
>W=Yàí¨2çLVê¥XwÅ¿BÆJ@sÆÚ\ŠğœtõÚö•ƒe·±2 +d&ÍÅz‚-‚?éÍªÍ:…ê•1Gb¿‰êe×£¶?‰††¾^şI˜—a7¤67'¸â­g¨8"¬ğdáÊ«ø­èÌPú^’±æhıô°Û&N­$÷*Ç—kt
J¦ áY†'b¨bÃ=u$ê§ÌX'Îî5Ó-½6ÓSlrş¢«ÓN{½£öFNeäµømC¾˜}´~é,ªKD(#wUk?­ün¢G^¯QˆeFjÉíà2£Ÿ2›kX•¡?&ø
-›“[~¾ÄoÇPŸN¢2Ñ|ÍïíÇ_ÁÛ÷ H‡K~Ÿ(v aÎš÷Şıİ ¸á—e €0»‡Y
Sv
ôxA/ˆİï‚Œy·©·_7ˆCÏÃ¾x•î‹vX·û=6
oVE"ÖX¸ñ):R ‘2Ë
®Rãº¢.QGĞ/J¤+:İÃô¨Ã¨
~™KiÀ(‘¨ms†L  s"‰Öj ü³€ÀsAuú±Ägû    YZ