#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1414004621"
MD5="36634de99afd808d7fca9200d2f8085e"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="24300"
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
	echo Uncompressed size: 172 KB
	echo Compression: xz
	echo Date of packaging: Sun Jan  9 21:14:51 -03 2022
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
	echo OLDUSIZE=172
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
	MS_Printf "About to extract 172 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 172; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (172 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ^¬] ¼}•À1Dd]‡Á›PætİDõ%°ÑYŸg ^§TáB‚ù¡?š/}•aù$$¬¸›F’Ï6–šq}§uyÚ“=ÙqÂŸ*8½Yü!ğ8n¦˜­Òsî`·suw_Hôs®	óif)d ¤}™›c`ü:WÓà†…³©dìh×ä%6¾H3¹z iš€òÒ¸‰å¨`ÔÚûùä{k[hÖKoŞoÜšGSÌ;ískDCK7Æt¤4ö9¦Ël½‡´RˆA²q}Ö„¿×o8£4•¯.ò›)v¹kn›;!¥?îÎ(ôÓ-”¿Øô—<özX™U‹	Í*y#ÕŞ4ˆ"`¢Q*¯EÙU¬íÒ‘i?+ƒ’*"lz-úuÈÑål±K}Æ0«vä`¥“R"XTQ?&	t|Ë³˜-ë?/ò}r7ÖüzüİŞsSÉI™sUlş\%ÊJÇD‚ä˜b˜¦™Iíõa£¯t°²‡‘^Õ”Ùİ×°f•@Î|Ÿ;ßÿñ1FÍ¼Y¸õµ¤\N'|¬y6î¿¨„Ub€ØÇïî–Ÿ´”äbc7º¼óFß«n'HnâdNØIj{ğU‚ıŸéT)=E}"LÜ÷Œ›HÿŸnŠşƒÂ3#é‘ìq~“ïEO†UŒC¥ÁhÍéØÌiç(=l®ÿglA‘%&[4ÑâC›Ÿ‚=-wñÎ'Çs1‚Òz@Ò]S
†áÏV¿”Ãğ¾¢‚&µR´¸YoQÊÜj®wj ó-+Nó¹„Y3ÔH7Î_…±%(dÖáâï
¬jØüƒœ Gb¢áÄò-SJGa•K”Sìü[J£÷FKÂİõİ¶³ì †WóªcˆH¢€”…yŠk²=Ğm=ü,0üÃ{‹8‰U~†±èáåÄMgä?È£›Ã.€í´»PÅç¸$C÷?¬´£Á…ğ-bwŠ×]ŒÛ(mß7ÒÎ­ÅÜ,'àØç÷Û¾½Ã5$ù$~¿ÄDHä>õ·æqø“Õ·°»ŠG1°-L4
ÂÅEˆ:³×ÇC×é4CÛ(Hø<V5™»$‹)›kVÍó‹(ÕÑ‚ØôD	arùÔ´À÷°ëTevUà¡Û)‹ÅRC°ÚÎGR9¼ªâ‹~,@¥×+İì‚ÃTÛ@ÁÄÏc·´9ºŒ±•‘tú–õÑµ÷{küÏÇ¶@CïË”pñ}|\¿vf?Iß67*Ï~½±#¨cï“•)•üÔô0¤LÏ½§¨7‘›³ã^‡|+å4Y^¡^ëSq7úê¬€ÄŠØó2 ;ĞF~Ç:u?1rû¦o»ŞÔƒşÍb.ı^~Ïm@ø¨!Ev¼e‰âÇµ´ÒÃ‘8‹à¼Æö2\ØŒAY^G^Prú¼Ô eZŒ…ı!'B¤ À}9îx)äƒ°NÏô$7ÿ¨Ù×x-À	 Záw¼VË†q@çE¶? ˆ1üó‘l8É)%c˜ûXoRm@y@—€¸œ>°óYæî
î¢Õï)¯ºBÈÙÆ‰Ë-ËÒ :'|‘Jã¿Î¼Ú¡)ú8çÖÜ´Zíçã¨ñ\œ„’js%¿?wÏ;ºªòÿY$/TxóÿNÊK#UÓnTc:7]1º-švÏ´jŒN³©™MÁW'ˆÙojÚaùTÒA(R)×vI9X(ÎâÓã™¯ñgäPdFKPÍpî
3¡C©fÈíAµVà³WCµÒ:·g&(ÃÉ2}W6«6\Á`ÿ›î·+”ØGŒ¨ñ…;Bb°ÍBsõÊ]ÜËGÚ¡«l©8zjû¤Á`üìSÎĞ½Ã ÀŒ)‡€•çéœóÜh«•Ya9¾è´æû\:&HªÆ&Èp¡³¹¡e§Ÿ0ª„SĞ„”¡úîCÁ¬ª+§{	…ÑËÀ´6l?!Å«ÜyÁ`Â0X²î¯?F}{âÄri¸…¸?ˆäI— ={„T5ˆlÚÁ ŸÓĞC:écÈø7UÍM÷Mn‡`ôjçcé2ï¢·%RQø´A˜f2Q<ŒÕxÌ‰~»q˜cQ3ø´ÿmËÈw½_ÒÀ-[°””/÷šv·/€,¥vƒ´ZBfcÑ%lˆ:ÓâåPôXoæÖ¥ê D9t’í¼Ø’idy¿±u|ã‰kIııÁæß}ß7\6ÑüLï2
eıÖ÷1™íeFxÙ*Ò§”µîÊJÃ	v‹~ZGcı¤U„$é+§ß;\UiZò×/âĞÎ^~>„uøÈ~pèÓêzÛğ¾£»ù~•ÙÓAı¡1ª¤õÔl ßu¾>{èÁ¼ˆ‚{TÏÄï°‘ø£ªNîŞ‹ñŞÆÉ™	¦o¢˜Û2å±’åÌL\xïæ½á°Ä9­r|¦ÍZãÈûJzÒ2—<óæ|(¤´Õ‚4EM2üWİOtÖÒı UcÊ¾7/Ò|i#yÈ®úT6Ø!-Õa -ƒbù\Q¯ro`ŒÍM+{ª9™İ¥M.»,+O‹°*:Jeß}!ÿ×³ÇGŞ›Ò¾)u<Í[§áÿ>ÎiHIH7Qi£Ë¼fÿ¥¸Šêú¯óË÷óÜ0Ü=ÕİmŞ‘cjq´‹¼>· ô†Lpê
Ÿö#Æÿß‡ªl#RÔ¡½‰¡7OÈØ¢2S¿d¼¿—ş1¯Ñ‘JMñ”TÀbé«‹3|N*•L/Íó×Ÿ·q@ì“ßÇ;¶’ğuÕõöĞkÕ}èËåİäÏ\ú?€_ ±ÇxÊÂÁ#U”ßL××¹lÃqujkĞBª®dçc/ÊÎÒvD¥ öø©­»é†êŠ<9}Â\ë\&3€şu¢´ÙÊîô™XSÊ5MÂqjÙ°a·JVó’tƒŒx~#p¤H‹›*Fë¾DEã*iª(wbqÑ²oè0qáŸÔôİ¦éÛ¤ )±²åU}OÅÎ%ÍêDˆI¨•M¶˜PKWØ£NõMgÓgq+–ínæÃD GÒ¦Ä/é´¹XeUÄCwB¼ 1´J¢}‘×}Uöc«!œg\(Ÿ"%[P›÷-€p„½¤Ld‹GÊ7Ñƒ7Hv8	^oxÍ…`I#ÛÌiçV›¹Ø?}<úJo7a€Õ¨áä1äÀ-i[1˜Œvèpë XÉSøªàô·6"“šzšÂ÷SÎ¤çŞœ±8c”ÜîšÁ~'‚úÛäGúdeúøB¦a—|(ÙfP6mÎìÇÍ7•ö^7<AxµZÚLx©/1aÆ°ÃÁF­ úuûônH†ıŸ¤37‘-8=Úq5C´ZàøòEz?,KW‡í£ĞÍqC† šVEÛ !³‘ ,Óu¡Ğ3ˆŒœãóöEkãõ8‘}ÌşLóé?\®>?Ã|åH©Y>„@¥UsZX0»O7²a-­jé®2¨íŒuR›3¤;…ÿ·iÛØ ¯j¯YLæÜMrÏÙ)iæÀ‘/ è
ğ³Q‹$Å¸¼3À‹æâæ&µÉ9ö/­¬Ä¦@^z0¡"ÏŞ2~ZZDÜ½ÈÓ°¡
t¯ÌI,U˜‹	hˆ‘÷n”
Õúª&÷İıYÒ”¨hK8#_{†”ƒV ïiê\ ¨$ŠÿŠ»|}í•ê‘Å—™ÄL¯±S˜ïÙAıœ>2#ø½. ²hvÅ²°mÊË„êêÚç^ êX$F/êQ`=¿Ã–Àºg<¾à9îñ+©ÆFîy¿óÉìÛ*NÇß/õÆ>´x”H;G®/ÑÙ©Õ¿óh¦Â$<p½!ôNÂdFÆxMó—®“/OßLa5LÒÎê€6g»âçÄ×6IäA§óóg.L÷Fv¤ 8Çí}±ÏP§a^ÜÈ“¥3@İŠú4UA°ğÇÙDF– ç2XıT,ºD›å"ô¯ì7beM òíèál(,Û”•o	qï£RQc›MàØ;Cbe6ĞÓ²tSµ{ÑÖÌÊ‘»-e°|«T Y‘¦¾JlId½Xœ¾”£àÿãj[¾Ùp	p$Â-Ñ8ØÈíË„ÇØ>ìÈádešmp@|ü•³r°.k!4eŸy6’ÆQ¯Å÷'E\ú¦¡Æ"ŸîÔ ^
ˆ
xOÎ;vbS±÷”gåŒhğ²è“wã+TRÚZ.©e_ÑB™;÷*‚ƒOÆ«,wï ç¥°.÷ ©Ö=î>N/a¼Rµ¢:†¥á¼Ú§abòlG‘uKÛ°¦YÚ B-ê´ëÅÏi!öÂ“³¤–ôV	úÖ>›µüÕX­{ì,‰]ÎMÜ£5o6íL±]Ç³{‘dbØ·ÌÕa³+Òy””Ñ`¨³%<³Ê
4`YAØóîrœOŞ×½‹ZëÕòA¬2¹Kıı`QºP‹³xcŞ˜=Û«¯®\Ş„ƒÔ~Ó?ŸzãUm;äM‘Ì³b>BVmÊ/ dƒÏ"™°Ü‡g;“³*	ƒÒo;ù£©Ÿ~„œÿ¦lÏtJNp/Vq*/‚hµy€Û6•nRC€‡—Á,¡&EïTûÛÒkÜô.¿©ÑFXãÙŞw÷_PlµÜµ~¢éæè“Ùúcµã;‘c;mì)g²#«û§ÍÆˆçîíÖ î#—TwzœÒò·Ó£{_Ù_Ç-t.#%i%—ñBÉ÷f§Ü²2°€iR‰ƒ×ÿ®¦|§¢fh§,‚ÊşÖ…¾%¤ô·µËdTG—Ï4[šİ™ª›0˜Ä@–”ÑéƒäñP62.R«bÑ-æêĞäæÈ(Lm7 GæEÆ]…Zç:c;5ŸV´G~ÌG¯¦÷ÒŒé,aA¨ı ²ÉMÏœÏnplX_‚ëâ¡Á@”£ç{‚a÷a+/ïşºı	lKfi¯í™02è=àĞYmšeª¤ ¢5®şÏDÇœ ?	ŸY¨³{)W·ô†Ñ} •Ññ.zèa³Ì: %âùÛ*ŠS:×]'ıš!Éê}ÑX‰;ÀÖ¤A¬—Ò¼°hfF"ô~Ëƒ-m~„ ”H¨_·¢—]ûq<£'\†·¢Á9Ã·š<ï”D²¼3‡â6?9ÁBÙe°IúÅ~dœ9Ñ­ÆæÇYDô@BpTÙÀƒX¥Aç9rœmÁ\ŠÛ„S^êí¥=üÎ ÙÂÈ¹3qÃ>I÷sÿ¸nÕø"D¡5Î/ğ )$z$Àí-L·×Êóİ—i¬@IÓn†­ß°ÂqNA–2ø^Ubxí•˜
Ë%ó@ÉšKÈg¿hIa:MãÍ/­7êÏ–¢u!»¯m†¬»GÉ4*éæy;½^§øNlóÜ.Øœ²»8â§%bE4gY­Fs[T¨:~ôÄn8‰v™ù>«|½Ï™ÈSÍ+2İ¥ìT^;HOBÎ>@%¦¬áå«æŠ|:WRê!(‡ÁC¶‚ô(Ax;hbˆ×VœóÉŞ{w¢Ğ*ÍåGºƒ÷ÀeÎb.öói©ÏÙ?tÅ3`I
´ ª*îéï&ŞAëïä§
3;”x!WvÁaüêV<‘á¼
ÖRØ³+d—Zİq³¦òLúcâöåVÌ è‡ÊÉfrWÍé0=°¯­=¶K59ü…uj½8!ûf*1H³¾™kàÈ¬3]@™íM{TB 
JMq)ÆÂ.¼‚b{(˜µdûRƒ¢SÎÛ
hË|ëş|bGÙ·4wÖÔOãz×A]Íı°|İ@·´}":q¦E{–í„h;yÎÁ{ nbè›²Y¥Äï+QyÒä NI•ªÛ¡]ı|8™”öåÕôÃ0ù.FŒ:)«Yè´ŞÓ'çø
›läæ›c»ô0gÿ»÷á£­÷Ù©ÂP€2û$gÍ«¢BÛ¦‹’6âÈØP£mî~¾o"R7|h@dÌÁù÷w­éÅ³·OqÚáÜVTn´ZC'¥»|æR2Ìc"¥ª+˜kéÕ2;|
 §9ujIÿwŒÇ»¿’/hŒ¾-hĞ®ïQ•QÆ2ĞÖzzvSØéÆXR]G+Z-í!X4·‡ŞÔâÏ
¢°ÑúªÑ9ÜŞU»ëÊJÍA{ÿn1vÌ ‘€?(Ùû¥GAÉ”ù%P“:#©óø“Vì³"lpÎfïvÍ…²&\·-ñ*Æ7@ÕIZ{”¥ÀQø±lUç¸RıIÛkzUê{åoùˆ <?S	ÍæÏ<¢"òû8_]1`zRÇ1Ë•4ds¹§É»ô¤©H¶Pæ9Ù[±ØğæùN1»g£”!Gœ’k·g™8Å9K|8a›oµF¯j>Üf{²rÔuèp÷v˜ÕCJ¿p€0ÏBeÎÒ& W–ÌdZ~µöóNî–¨Ïvó1N‡~=ÒğÃoÊ‰Š5VgÜI?ğåŞıWÛ”<ïf··±Q”Lû9ƒ øLñ®ıñİûÑŞáÒîŒ7ÜNh7ßÑæ¤N40ÄqùPjFŸ«şbKŠ€„^ëÑo–ô‰“âûÃË	â†ÌçF–—¾ôBúeÀZ…²“+ğhz4">€²ÁÌaÀTy!ï~íÕ§İpØç”@Lí'˜ªŞ18¹©wŒÓÑNå³½hşöCñÌaF¨Ã³&JªË“|˜òx²}²ËuJA‹Õ3Mzí@»® ³h”¯ÙY:uñ“İHpìSBĞºIjÕµÌóvÎ-OHDŒ ¤Û­™™i–Úeİôû^wJ“y/!ØD©Ïx`Ym'¬ÀÆâ®ğFúnp#‹ãTGi®Öæ3R ã(a\DY*P¥kñNâj¤MGÔÏŒ)gşºÄÉ´_Å+ü5ü‡-˜ö¾§F*jCDaïîwC+QdšÍ
†Óª³æRš;Æˆ~êI€ñÍYi`l…É®è­ÚĞ®@º
DË€N%9ƒ¡gàƒ¨½ó+wÑ;Ş‡ßMaã–£}Âüª)%‚òÉƒsÁ–²`« Ñ»c*_@eÁák`lt‘ß•Še±DÇ”E€ì­!DNAï%Î€—ĞTÒAŒ5bğÖn-7Í:.‰8ş»7*ì³NXc‹¦O—MÒZñ†RaÃÆôDè¥¨CKíeÇ`V_¹¸0´£¯$´Û±ûâ‹¥VÄ~*´è5ç "ëU èi®!ÌàĞv`®bòVG& Å`<ŞfŠÈ°=¬GßwuùÅØ -‘+î’`««ªRCaY´†]Òœf“nº•'ø8t–ïçhşs™“`$åYK-|_—@r#¶Jƒ)L=38`»…“	4î™W S5 ¸ãÚ¨šñù¾Ò³9Á°)xzd¬&@y!€›hc»lÃT,P¨bVùÜûôìvm7ñ/·pnŠ,òÅç­*Öä«ÄdaŞ®²†`ÅîÔpÚm?òÏ•Djwrw¹`I ÔŸ”¤¨ŞÚÕ–ÛÊRäy}ú Õ>6sQoFŠòñR]œs„â?­æZ
‘K¡2ïÅZ
6 {Y—=¥¯;\˜^lÁŒD£İiÓc‚‡¹¡ <÷¯ê‹•§ÜBFU.~0úp(Ö$)ò«T³¢7]ZìáÆúP{8ŞdğÄbct˜É[óòíÁúï2šS¾[xÎbÛ„ÓìwKÿÒuäÅÒC+”S®®•-Ài«å«ÙÉƒ¨”îÚAéÄ%$år˜¸«Vb°;|Ÿ‡ºPä<0Œœ“EËÊ& {íÚœ~…•:‰¹©²Xìï§H[:‹÷ã-4å‹Ò´Nïöùbò_ÄYt×AÓ‡k,İégÒÎ‹6J±yYp„t		b° 0”Z˜O	Ÿ/ß¤ƒìE*ÏV²Vos– ÉSÂÔGºÎÒ³9úİXN…o€¦¿Æ˜ß#VxÙó…P°˜9ƒ×À‰îÑë.VYáQhÒ~ÏJ†o0¸Ôš€ÆÀ8‚*RË >TÊ2İ¬ï*`]ñø):s6İRŠM\dè:éO˜²@È½Ä–Û?.?ñ^îÖK9Nè†›ÓNâÊ[jª5Põü~Ù¨ßïïû¢‡~‹FÉM×ëÈ«ã8vU¤2û„h•#°<8.óÎ?‰cë‹òU" ‰Q^PÚéöÒnr¸ÌO‚CV?çI%¬>wá©öá¬Õ4~YùÅOtN¸qİôğÄ•F))¦½B˜ú10²WïÙHãvuë£Ó°Úõ"Í•† C…„ƒ+·Ú?Yi=ùIpµoá´ËkÖR×™»_Úïe'ü:c®ÃhÙˆÍLW“Ì!9øã³ênb2ss\E1ªcìÜüøò÷BkKüÜ,Ó?†Ì357G!D…á4Tš§&ë	-M–h½•ìƒıİá(6Âæ˜[W¡³8hî<$ qA@#ûã·üÀÂ‚\‚¯z¸p [şRš¦©¡JFS2ÿ«ÏõáİOæèçÁ1… )£»’dz»ÍË¡ºË…[:„M×ä
>›ÁŞı Ùû··À’›8ˆÕJˆª>@KoË@åˆ4jeÓ«™©	‹š‹-{Ûım9İÚÂ¥å2y1ÉOçfF<1àĞ·†š?O2u÷|îs`$›<.mÚZè¶­i¾ö=Ã4;'Må¹È$é…ƒnePcşY\œ€ğlÿeŠY³’z¾?#Z|ËVE 7BŞX‚î–…W>#ùV‰È0äx}¾J®*dl’R‡Âkw7KeTÿº81š(;0ko‚‰—‡…šàFhÃpåÆ?JÃUÌ"GtĞG“q³¹Kì¤Q^U¶:ASn0óƒŠ©e1ßë2ŞVCÀÏ¥
"Æb‚ÁìGYšóU‹‹Õú 7E]EÇX:µ`™ÙÕÖ§JÎÊ
»JN/iÜRûÿŸÈ¯Û^óñœ2eáÇÍ7»)x¹§ËLÏQíZ`Š	3¦÷.’š–êÊ˜¡b-İ@„”·”j‹mw°ÿ°Ò<zÇ½Z¡Sdãôl<@ˆOÆÉ¨7ƒÍÛè0n¾a±š;¤®hkœ]Oëlø®•HØ(è¦Hİ•9'J´Ó0ÏÂ}Z*úÑ%UÃ?\ò™Y
>;Mœ›õóÖïáe¼¾kÚ¶€ºGEËõXi™™Ö0İ,ˆD™æ|Ü± aC{ ^ÅÅ82]o(—voÂØû¤Ëîwÿft«[ÁŠÖİy±i ¦.‹”À×î¦4Îçô+ yäWhü1˜;ŞTïÁpzKáä¢ıH	0Ï1ËAÏmw¤³­²Ğu	¾~*päŸ‰à^;ÍèÀlŒFğ.¹ÌùÏÓ¦#Ò`¿U	%ˆÈ>›o›Â€X¾Z4W~ÓÇxKÑq	ÃT·ö`Iî2-ÑÃBÇª—`ğ²tñ,åU—Ù´8µ*’o ©¥:{aÀ„UÇŠà›»äxGŠ7Byô~qAÕG™[ĞÌhç^ ½?"µ5«hE
•™2€#~¹T„HD
€'cÏŸ‚?jh1´„†¢’`ş¾M¼âÂòp¹(n\Nâ€b4°0;‡fÂrsA[j—oô	A0)z]üîKp™Õ@úY‡Îtš"Ü=I©oÃ*s¥}ê¥'^JA¤ÀŠ&@]šû_÷z´ôÙ*˜†vMÄç¯–# ‡¤¿½úO÷ôŸŞÑ¡î 0î¹Èõ¬÷âXKiK´|âM¹è®ÍIaG”µÖµi¹0ƒ½´ùAaAôÈOE¸<ŸôZy¦ıÛÇ2Öã£6Æ½ä!qLaÔ’©ò<çìlTåP6fx4m59ô3şÎ!Å>kı…ï*ëĞIuc~º¦j÷A<]kiÿ4ª„ö]˜\¨“¦Ìt<¦3¬ã³Aˆ¦’BY›H8ŞóÛ­¼îÛ/²4ëóÑI.j«œ•‚”
|äVN_]&Õ3‚µtÊR} t¬˜6¤ÒŠ/á“ÏYq?€üÛûãeÎkçV‰=}£±ˆãø’´ ÇD!h4œ,„Ä<°0²ğs²|Y±w5÷Á:ş¿/7Sg'ÚRª@Å€¹·`}ŸÀõâ=÷M=?UŒ@l÷Z®l Ql**àE’ráÛ(§<®§¢d¹†IkØB‘±Å£îÑ:³ß0ÍËpÍÊSü¬WF—ÔĞ=<„,6M*,e2b–'^:Qò·OzÁFÿÒZä4ÄdeOš©ë"ƒ°İi£¶òé!E®|›ÔXLLç10¸<Rö®¤?åEÏì;r}›ª¡òçAáÒ%?Ì¦râB„R˜®îQì5œ°ˆ(Ó|³úq9*xğwÖ@=‡–Ñrcó°/eÕ³òmŒŸ “ÿEşÕÆ½ª+°ÚšĞçX¹]ÆpDP´g´p.G†…ªŒLøÁ¨™#Œø»v~ÏWQ¿ø×ğ	°?•‹®Ã,—ºñ2_ü_Şmí›ñ!+AnîIöß	Š¬[±?{Èœ^yÃî]5wÆ`â4ş*ßÍ ¢àÿû5Vá_œ˜‹CŸLñ¶¾¿Ö$ùäi¹™ôn¬¡òş,20}È©vfL¹K›‘·ñæ‹¢ò!VFÅV™Ğåê>ÈZÑ³ÓG­Ÿb–]4eÀÂ
¢À‰M–›uƒõsöx–‘V¦Î×1•ê™)Ãûú+SØò	€Aä |BF ù\Ò>MÙØ3ÊF2¦…d_;Óuêİlş§™„hæÕ^Hšto›>Äöÿl%`ÅedÕ{z¨}#›ıÇı&İšÏåZl‰éÓö;
íÌáŸªß6)ƒøÕ¯‹­Œüçëq’ŸÒ÷¥m¤[`›õ‡ws9­#åxë,­Nu!4xƒ®¾Îûòğeå[7Uì> ¢ƒàc7—â%dNîÅ¶l§Ã¹cÉQ˜!:	6U°ŒÕœòØÊOÈ]K´ñ"Å¡w‹áÈ®HtIíÿØÅ´ˆ¡~=äšaîˆs: Ş'Q6L/ÊÈíJ”2c½?s{G:!/(ììCŸò4„OÁ4j¡³_PÇêŠAŸ:ÈÙ1a©—„ÊCËµLğÍz^ªˆıc”cE æZDï ¹îåHÓ5Tô0÷è/{™»œ€H?Š^Å»Î#‘¶|	DúCo,ê)híÆ¾x]o{ut¶ä²9ş¨€Ù¦ÍzpåxV%%ûUéÃ,Ç-Jß”Ü}™;ÇH\ˆïb¯ÁËñU¨üğñ ”Ö×-rÀŞ@­7™I35[;ÙVèO`É(¸]ÎÜ×?æqŒ®Å \kQb<º×=,¥cÅ[;ÒÃQ{{·¶Z.³¹³¶Ÿ2Qjôó¥1×¹<@ŞÂ6Ãz’mI¤;Ä&ïó3%PÎZHü€PĞÕ¶-û’/9»ÕÖXûİı¹Î$B¸Ğs»Â¯¬Ö©ñÙ)ŒN«fGí5€‹Uå‚˜Á‚ÂŒg}¤ÉÀ8¹rÀ!_´ˆ”ØÄ´Ûyƒ.;åóF¬Ñ´ Y¨hs%¦>`ƒšH5—•ÿ€¤ßo5Ùz2P½VßR×¡çrë2S¸6’EÒKUª¢ÇÀE2ÇõF/¾Mñ8½}*¢—øáÁÓbÛnÅê;/(ÜiÌc~`²ˆ{í™iÍtƒkˆ%±Sœ™Vm<š`–ë˜Zpo¶o0˜âÊ-Î\ ²Y‚Ãss><[ñÅsÚûpB5!•³•ï…şŠ¼ÑHt&'°‚ÊÑÖdü¦OËÇ—ãm7*–ÃîgİĞTİ›^× mFÈ˜XI¼~,æùáx:€:iÍx‡_°
àjÁ”0~2âÇèï…†yZNEU¥J–Ùº0¬›İ¼£¡‹<İ­±õc-N‘ëªT¦È]Õ;æºÑ<O€õ«)A“?ˆ§Q¥.¯áNWf]‘ÖÅ= ½‚6ìŞtÔ8f3õ-Â «cİñİË¢HTÏz`ŸÀ]­"şzÎ&X,önU	ÇgÊÑŠH=cÏ– Ÿï¨‹ÆÊfáê»å”xév-¢(õg$‚½)CcF8ÊNvJXò}­oV³3™,İm3Js6í"…U8ÙÂh(8EÆè¯‚!ÊŸŠ¦ Ü…ŸÅiöšzpkº7`ÒP=h?1ò±´‚ş´ëwÃœ}ğ‹sô_^³CLeç6]Â
IŞÏcÆŞ1+Û¼R®“’‡j=İ´×´+z ®>ÏóÌI§gÆypdvQY‹‚d@#éŞ2*ë¦‡·Ò—‘XÆ˜Jã;‘_àøk¶›Y8t…^„µáœmÅÀ¦Ò<œ’›üñ½…«MÌ&:†ˆÁó)œ=›4¯†À¿Î«‡!­¶6°\|±LÅHïÃ{ïï¦«"òFô£5åãlÛK”kGkƒÁ_rFåß4¢äã—4¹ÆaV¨¤˜®56ş&Š~ºˆ0âO+mŞ0.”HÆÒÍ=©Píaoë•Ê›Ï3{zlm¥–½EüQ‰^4¶ÕÖØºä:4:ií‘Ã RÿõØrÚÓ]Í¸rÀî@-ì¹{[N2÷õ¡Æº›ÛÂë|Ë†k¡Ï’ú0‘y ¡‹F’¼@*3¨M¹6º‹Ğ#­w.¿—pô‘gOô­ÌxıQƒÁ#ÿ®r+n¿ÌòqùÖ€ÊF&z]Şëk^½*7Ú\t¶YÑöñG~¦Ñ’óg$´é*pÒÜ‹&>Q(lcMÖ4Í¸³›ÖòoB(…—‚¹¥/vˆ?2e—…â¯¼Æeâ±m®N¥é±H‚'†_Ğ‡©…ûË]İ{ê+LºÒPÌ©pt¥.î@ÀTÿ?nôÆ},ôá“âîùH{Yï(Ÿ·9Ü4¼Ÿ;*d9ıÈ?èÌ²a=ÁJ|lK Û÷u(M¥³õ,öRñıÇ ˜´¯Å¶‚ÊUîŸÙ:à<h4³Š{Èh>ğO@ËOÇŒub¤/¾ Äb}V-+“PğMøMæß¡J{Î¥æ-‘µqåê8;0¹isd¶¨HÌåò5áóıÿ}…Š]i`Ğ×”×Ú/'.ãîŠÚœkBàÒk¼;øB·ÛtÉÊŸµÛ©3æ`ÅFUt³B;’ZÙI¤®Z\Ãºéçö/"ün¥Öú¸MÍ„¶ÉTÂ%gÑ8ÕûæöÙÖ‘x¿'O±rdÀ›œH”Àé©.•O“¶#~¾æ¿ %Š˜Ö¥®ı¥œİ(ØR0*yûœ—ó]ñ¡{,»º§b9é~P’cm›£’Ğ­¿}UÂJ°Ÿ±KŸ+mO#£?S´õ¥»6îï¬Ü™…Rz8V ¹Úş^¢ww¦ İ°ÖS¯ûF€bzoƒ°—­låÇ¡(;ÑêJ,ß	%·+W‚ ã{s½/4üÍÖğYHX¾®ĞYx­°=Sl}¬‘bÖ”) s	;nÈ¤Ctªj,¹ú\î§Ä,¯Q&	ıŠMBğ—JERÒKà°:Ç5=wB%²aâr›··0f¼?nµ´ëµYT¦^’Î€W˜á'¤^îÅÿ!Üø¢òƒÉM‹T¨ÕhRÎİ¶ˆ`É[»*õ‘íÖñUD½âå"V®¡;Å<ñ0»Iâ´ì b6•‹e,ç/êÕóòkÛ4dğÏØ‹mC	r{Èœ,]à^¤7"oËè…h¡–ü`ğ$0ªÓ²+D'-ßNFÁøœ¹ÊÉß—›‰iN¤.½&Ø¦aó#D46yí³€Ú£|Wl~â’¶suZ!ãuÈÊfÀö©"xÁ«~3ÃI¡ˆó¸hûİEä~^ß\ã›zÀQõ*I¢Sn-éWoê'ùa;E,Æú9ìÍ~dZ-šˆ³˜·¸ÙËáüı˜B½~˜ŸFm0Fh‘›Ôó‘ë*ñuî$&†$CÖş=xÌ»Ç÷U‰1x5—Iµ*£<‘á[€Z®iƒsÊÈùC{yn›ÃÇ0’=Vo@<˜ Ùì6aSş÷]A&u.Œ&À>*â¡óÍ)ÈŠ{ñ³ÉUó!&>^¢·„IÁes~şr4Û@²Rõ1ĞåÕDj½ş—{5W–së¾6SÌâe`éš<ÔìñÊl‰ÔÉ*\Ò¥Œ"t¿~ó`ƒ|ë—\x[b{Q®©¼?µÍ,áÈ&²à~Û|8¡Ìµ¿«j¯Dv1€;ŠÑR*Úu<>ñQ^&ü·ÜPÙçùò´ş¯šòò‹œØÉj°®PµßÓjVjD¥2¡ã;·‡=˜6º Ÿ½HqLü«…L¯’–ÁS†(Rg‚!µ&meXõ×ßKÈ áÆjæ©)Pì†+U4ïGì(ulQaÿ±q*>]½tZÖO»-3Ãëõ7e2ÓRzé¨p1g†GA×W0ÎúÜ	ş‰6Üâ`ÜRq‡ãrë€åÈÃMã[¼€å%5_UI|…¶’˜«¸,†^ÍcÚ·tã­¢›cjFkP¡ú†-d@v»@DsU™J‹iE-°p~ÉŠÁÌ©Bÿ[˜ÕnfıêG\”meüÖ¿ŸX¹{Æ§/áWŸ‹±cµë»Dş\ˆøÉ>³µÛwœOú›Êè&¶
,næ*~1“öØ?Jwl”sO^ ?!"/1BÌÛ‘Zn	¬e¬LãôÎ˜ V™·ØŠ×èaâ÷ıœâ ƒ¿o³Ù—-p“V Î-&n:”®­—}; :=‰]B‰:z!…‰B8µ gTÄ“úáœ¼_\ßÑ€“·`’c`|©Êãª€x•ÖyJ8òß^Ÿ.	jÈH …,èMô0ŸMúŒ+xÇSíî! 6ØÌx{ÂZrÇÎÊ7hüQßAmñ	×Y^b&¥¯páÈ'@ÒŒŠÚ2»7—¢l<#m&(ƒÕ´—ƒÆVJX’8Òéò	š-áÆ)l~`ädø’ §6ÇYL!¡BaxüWP…À4Ü`Ñá6b5[Gğ7y¼·Te"8;üuÚaøVë˜é–Ì¢ÉKÒ´D˜;aÀ+í÷KOOÅ‘A¹\ïQ-¾8¹`X‰VSõ“­P¤qùúú®s½‰$êãtú’Åöh6–Èp’óça*ã´­0ø(`S50p] ¨Ã£Ô³?%oIc8ÇyÁcf…¤óqräšèÍ¼:¥í	F/9³H‰T5àÏ<QÅ‹àŠl~ŞÂñ`5İÏÉ4Ä(İ÷°}‘MğÒdH$¸NL°Fkvn"ÄØS“üq‹HDŸ`ÛJ®‡©ÊË!U‡û©æğÆi*dø¥ë¡z‚ø}¥.òg*]Ó+ZXúPvÖüÕAÃ0…`c¶|¬›L
­?—#z"ûÅÑúèR'v4x¨–TP.¸$ÇRšBı¾+Ô¬Û'húr˜®‚36Ë¿S*dËzSüÇ×ZE+ëà)£`¾íÛš4t›ÔÎœİUïÜæx¾Èb©RŒX'—Ré »‚£J2¸É¸ƒS¾Çå™'mS3Âpa@fyj„ÍšÃ™t¼!1pV¸î"_jNúI¿ûe0Y‡#„¼öLºÅK[,õ#nü,¹ú6}–G=ÙK¡Šúx’›½XÚ‚5j»¦‹)öUOa)¯*èSò˜ØåĞ¿Ğ®y0„Hßõí7,÷»æc{ø–SMO_İ!ôeË½qÍ•îº?ğSql3¨¤ƒØÜ4	/©Œcu´66XîmO[«ë¦rUP‡JhT4ó¯~3H™—G·(m>`Ylß)IŠƒà'Şëér24UİHvüs[ño^©ÙÔã`ûéìá<Š€IfY~­†ëX?VÆz>¾àHı EÁ›L…sİn*
ÊSv{”;UW“9W9›èê¿jæ¼3ªö};ü¦mén;jÛEˆÆ&},l¢VçA³`3eOŒÙ€éwı]Ûî=y›¿š±0Öc¬¾ƒq©)Pª0ûh•o½j>]ã™Ğ¸	(9–!MŠ£:Ûd³&jœr¦“¿ê^ œı¯ü¢ï“_šEågK=@°Z^—Ì?™Şe…­Lz›}Š‹GZ´Vôö„o/„¦’öSæei7¦TèË=¤–Ô=ö2ê¢	L×çSÃ¤W·2‰£Ÿ)ö`²Ş\ïí¼Iºè°uğËùÂ¼ Hj_èıbôí•P'`çÛˆgN‚é|­ÈaŞ­Õ—:#[¶fÆSrç°lÈ z^ÑÌPT	W’¤õB{äü_3éãçù3lÄ÷±³õcãè+›è½S-ÛUÁ\ÂÂâ/¡\>MË½¤ıÌüÙÇÂ”û;‹úÕ'–°ø+Úœ_œFK‡‘ÿ‚ïòÖÀ”ç»<ƒÃ:“u7ÕĞŞ[–e”¬È·.âû+æT‰Ùd–’ıG{„OHØN‹¥ºÊ|9 ¥œ0zóaë~´ŸĞ›ÛƒAÒ¬FEó„,È«/iÉ†-ü<M«{f¼P:ĞİÊåé~°À'İq~4Úçò¬E™R\tÃ´Ÿ_jsşÉn™ÑúÂ`{È¢‚ê­§˜±e$LgDŒÔ’hÄgO-L$5ûg8å^·Ü¡„?2”óÊı&IøíyS×*£Pâéıf…É5‰DyİGîd`·Œ”9Œq¤„Ü”Äï{”÷Ğûx2îS ĞD€Ès²ş/\Õ©y£yƒ+1fZ[3d ¥*>\JèUüŒ®©¿@ÒZ­˜È{=Ã¥1Ï™)›åÿ26”(\¸]+X8ÿA·s°% ¥DeÀ$ÎpI_r]úWaÇ![ÕGÏ«:Ş+>…~DYê*ä?9¤I'ÚÜ™`Bzÿª¡3&s–=6düU7÷ÕãpWŞ`.{8ØAòfà®$¼±m„Q!5èÔ<Ø°2¨šv3ÀÃ‚ZÉ“6§Êµ•¶tÔƒÂøD×ŠL|¹‚@_¶"šıøô©W¿†ÙœcEÃ´\åñ+gèW#<È
» ´í§‰Ç«/]±1Ö‘&¼ä½à!éØÇE®‹a0å9aQ¤h{ú3;wUSir×/§›¡h½Ù¥1Â×¿Ñåc›‚°¦©š ZÉ™imi^ô9cXR©ñVxÒi2=È+¤Õj¹„ñdš½Ş$f\Äø²j8?õ±Œ…LÇR/|€l((şŸ®œY¦¥‹ñ#–3>	wÍ¢µNÑÓa^ö‹ÙøÁ–zóx¹ÚV£ã×®Aµ`&Î
…”Z;ÓGoØôökB3éJy&ÙRè7Y˜1Â­;„]2|§Ä~—J¨^?@Y;^œ™ó£ÏIkE÷îĞÌ^}ßÇ|9ÙËøâ‘Ì£¦l)fİvœ»Ÿækn·ç°`C-ğÄ®»ıåKÏ´ºB‰‹ºv”Á-m‹›”šù&¼­ôB56úå(2‹ Œ±ş˜´á6Œª†cAyˆèjo‹8opÍC'èxğù¶B-ª½†&Ê¿ÃKŒŞÃ2	&—ç@NÖ&Ü?¸ºaõŒo+kõ›±Ì”Á# J(€@€’Ë×GÚŸï¦Æ
}9
P-Aş6ñª	B—v,:ß¯˜. ©šÎRƒdiqã³ˆ,¯öç×N"„dñJ†¶ş¢\›q§İã™p˜l³o#JŒUİ)õ XåºëØ_éÕPƒvÇ¿ÃäTg-ô»ìgˆ_êÒÑümÔîÑºn‡fÎ”æØÁ9H0!„	ÌP<	,5Ùl°¶*²QÃ*ê^8ï#|&]×j´A®áy/âüø*l	qi%A>	X“Fù«)”‰T‡K@¢óW+!ïyà‹­û†Ñc2æ~A½Æ/7mØ˜‰»Èqë!”1Õ˜¥›ŒZ0°ky‹.X€†¹R¾¦!ğ}ù·í#ál¼§`wçaw1û„ØğÎ
,¨¸nÇŠÂ¨´7#v8O—Y¿ëç üı´?VMÄƒ‘O„(¢7L$èœ$Sâ	izÓ–ç¥ú¶şƒ¨ºj@øöŠ
ï øA°ûf bÅû]@ìRğ'?Ã>E…ğëë6Ğ¶ùdF8cœ’ÀøTæ	 ‹õ7Vô‰¼Ò[4Qlä[Ù «Ûâ}}ñZî…é­JI³~èÙ§HÙÂ·ÑÙj\©ïJAÏlµH%cÛÿ q{9œG·Z³8ñ²
–ŒaŠuzÙ»Ïe¦d½òm+°Dq{Š¹SE
hıõüÎ-‡q„q¾X§8$7Ê®Lû¦sç½šóT$	M‰³/n›¯ç	˜Ã½Ia
Nå£êÊ²|WM°Ì³‘ò-:aSVQ"(¯ıŒt·|FòDŸí1?¨Ì›iÊ9eÛ\’¡­XöÆ[F$e°ò‰;aÅ““3¶AaÈï+j%8·[Äá	AVíÊ…{WæNA2µä‚x°
©a2&¬ öTc¥#ñ¡áƒÕ$åGÙÁÑ¬YÒß,£B±dR¦Ç9mîÖÙ¥ôPÑ75úôù,YİU ½Â9-M»Iê@q™æ»GZÜ}¼¹ï¶‚ùµ“ ÚÄ’õhHåŸ ·ïHe;¨‰¤££7{D3Â‰÷Şùô[÷lz¢®Íï›á¯£gLIŠ¥ÏeoBÒîğŞêâ>DÜihüì¹AUc0Ò2ƒ|ÒOjá‹ë>ê-Ö1ŸıŞ^9H)¦°ã¹W–ªıHGÚ‘ù*Iù­»`·xl§y[/šŸ8zîG¨ËoÊâò@†ñã×xIÅ[§åI”n×\EZ™`?¾b'Ò5%¨TeÒÈèåş42z¥ãêšD«ğpNäñG‰D­`,	–ŒQ*ÆÖpÜ¼¨ÂãÄ»œ6úßÆ‘4ù­Çøj~äÁ>18*D›58QM7¼ÆE>L²!´±²Ğ%£íŒ~Õ-qHo#KğW×O'(—"á¸¿ÎNùÙá™P“n½çªé¨ŸnÅ£qj§3‡E]ü¦€Z!îW7˜[ê‡ŒÍÏ–R·9–yÒ¤Š=]jÍ`Šç´bâaäT~|„ ®NRiÉÔª©90©rş[wA½Õô]éîé¤Hé}sÃÆ’!ö,Uöµi'{çà(,gÿš˜†ê$á[é<3 ÄHª{‰IÑO³QÄv^op²Àœ§¼èc®ë÷:üs#5VôÛPªsì'–“á<¡˜€Æ2—X&y Åİ.ªçÀóì ²³Ågv'0·İñ5>M/Ç*#®¦”ª =D¸¦ÇÅúßÅÉï™ŒÛI“ªŸò¸ùÙ@î„±£²$ÜAªè¤pú~œz 5Ô0?AVÙ¼ëˆ¼€ôÓ@éıÊG)«¸¨÷Û¨¶B¡ydT"²Ò	µÑàoyQ™.ÚĞ“?÷ ´êÄWù=[Ò`$ŸOÛİ©u˜¢¼Å(n~å*JÕØaUNX¬)u˜€kè4°x‘C<ÃŞÂ¾0Ds?8¿ü+ô#/&<•cœŒu³µéJ¶#á‚ÇÁãöŸ3,,÷ûˆ¡=s†ríŠıf?M¯p°%T€
x!H–N²¡$¤µÀRªßÕğ¡ı
¼ÀE'Ø8Eı¯ÌFw3ÃÉã D™S¥kWupvdşCÆ>åıúO¹8Ÿ/fû6«tË5Šé°‰óÉa^”nÔRw #&z+âDçQ¾F\áEp›ßk‘ïˆÈ)ÄíY…ª(J9R¾dZûH8)¥²Ô“¤šš$ÕU2>¯«8¨Ú«é½áx3gòËí`Ãî#%ü®d¢ûJd¤P¸QD,nı“Wók{cGóCzT[W€bÑ:ôáNfx…ÀRfôTˆò¯âºkÛ§²Z²F¡üïGªk†‡¨¾^àÄÉé$I·Í~o„º×øtÏY½ÿ}Ã ÿ¥ı Â¦{7ÉûušL$aif¿)W°]âR˜q5BØ¥ó¶˜)¤îU´î®LÀ½7	Ñğ¡l¦/…®$
ú;»oõl+„ë6NŠúÀöƒ5|ÑrR–#nŠík¯¾Ñ˜1] kHô^ìÉ$R5pyÕ‡¡¥|N(Lk“ãH½+,™1‡»Ú;­;ì‘wegmñÎ¡?	÷_%İ¼Æ4Š.ÿ$Š•ÔŸ	õñ/õµ¿uÊˆĞ»SŠt»â&sı@Ìnï›ô¢uR<RúÛİ'É•ÈãÇµÚs`{ãfnhTáã”£%	MqÒåÔÆœF€Ó­@/˜=ô?˜HÇ§Ÿvã†;«oFb¿Màä~è¯áµˆAQ¥£êÎë­¾(š­>…’Cn9ºç?Í„1Ä{*X_´B"²ˆ†ÿö@+â$öÄ½¯Â<”Ü,Qdàå
Ê…b36¶0ËJjbô®Aª¥û}t=:uÅ}~•^ÚÓ"_Ê#«†qæ¹J„$|€ãÃ®äc1õëÆïƒõ”\3‡QÄÌŒ«±±;s59ß´ŸŠvW{²ëğÅª½[NÕW­ËÈ;SdkÆgH%3«íÖ"Œv7Úiu}`İyZÕqÜè7Ö½éˆ]Ö‚HPo/8ª3Ÿ´5[cQyˆ¶v{’44¼8ŠÃY÷ävÆ^¦‚ê3D(³Y*< Î®d5,«½ÔŞ¯ˆmGdìg¶ŒŸòkH¬ææğcÎ[ærÖ"jÃ#‘ˆ„ S›Oo…Âƒ^)ox[¡›çh&å
ô)Ÿ}zVÒ`ÓB.–^U$w}1è‚¡]Z–ë}İ?Al=ğß±‰å'gô’|İU¸EBË|á]·|!ğy©µQ«…4óCÑ7dœìÅ@ƒ?ï³ôoášêĞ:Ú˜L‡;n`j@ş´Äq°fnR-ãümÈPÛ¤®ùû·ÒÅ'È=Tä˜?hÀlLe Lô‘×V—‘ÆĞ–Âá,	…5ğxüÌœqäH»üÔädA.`²x8WbëÃş0vÂdèÜwp1R6ë_mn’ƒSî ü:mëİ¶eÈ=±­ÀÌÂù)nñf·?nš¼Š¢Ñ·£ª°JÆ
DÑÀ&'ÁŒõøº'bDóbµŞHÒ»­®RÚãØkı7º!n¼\CFŠµœY¶ØÉ=şN6.ÄšhËÖùªªò¬Lı¦°ÇL‘Aä	èÜnK‹–])H>ŞÅ[ˆÕV<}g)ìÇ…ğápæ¼S·YXÊ¢èù£ü®Æı**)#™×"$€fuÆäap–Ç"7JM•…İ"ˆÕ˜Ù½Ò*™$Tê¦“qŒ‹i7½¼ğ=ã–.º‹ú%²Ø"DÔ7ƒ²‡0ğÂ›pÕa¹äÜÛÒÏÛW”<x’‘èÃ/¹ÇCÊÂÕá'L²Èû’¬Ö×¥a‘¦SNóo´
Of"n™ÙG9Iw‚Ÿ_I¢[YY 
—'"w8]L;‚YÁŠ³4"Ù¢eŸ…l‰6çûÖ€uü,{8ov
_^J‹j4¥j}³·æ2¦d#„»Îå4ña¾|éÑÔ²¨Ã~¨uÆõc}I¯Y:¦)ŞÔd£éJ¾ç¯÷‘¯_H ‰yï%çé.hâAˆ[+ÆböZI¶}¦U;Ù¨yÂ}À7ˆ‡o`|>Ø¨*Ÿ)]‚¼l¤åH jUwvŞ¦bçá#Úw{ú›âÛØ>Ÿ‹±%üç
P~'“‰Îñ<D	åÙ°¹±¦-EU4†ïI*Eçf«™	øfåJŒ©Èz‚¢®aäğ9uåÌd5KÚŠ(
Ğüéù´g"Öµ4å|3'oßd›Îğâ#áS7`Õj“b§ø—ÿ’:‚â–U‹±5X$ÈœkJ2•Åë¶3LÜ|óQ æÄÍMãóë°AT«Yÿ	øªÙt6¬§A-Rÿ]EƒC»fÚD'Uæ ù*LÓ /ïÚœ|üõn«œšïäÌ+>\ÏMf§T©óOR¥ÇZ·E„è™vKƒ²ßÒV.X7~„¯@ª}ú5?Â}Z’&-q~oøªy‡Á2ñÄÉÕ^Âf/BúY_&[ÇíÑòÈ³sc«ªš"Àu½‚ï~“ÄKr;ï,98İÚå|#­€!ëX…ğEŠæğ-ó¶B^ìyaër©j—e øì[v|{ócJè§-LœA#f²Yy]‚eïd‡µ‰ßºÊWígcêšP ‹bÚ“,æ²À‘2Ïg¸‘evR~²Ú»ôh;K«ÑxRÈİºqĞß>Ë–„TZ@øjKÂ(DJİ_éG’ÓŒ…:RsÛÑÑ¼¸ó+²3çCRU_“©[ÏÜyZÌ}’şâetnñïp©ñM²ğÿ*A*˜á÷È€õ„‡»ªbB¸üo’ŠQNY	è;Sëü‘tì±Eœè7ƒ&¢×kIv#éüÜ)ÓÆ­nò"—Â©·Hri…úFèow\ŒJ¬…HE¡º<4ôµë0œXÉÊïå <¾œ2W©œ[ò¾óö¿õˆæ×R6ò¤±ˆ×Sà1¨1ûêÙ™'‘s± œºÁ^Ò­²OòÛS‹÷?E]­&é².o $.æˆ‡œÕuïÓ²wl­êGQàNáş6ÃX›óhï°š¼Ÿ‘³WüºƒÊ¼Í<p™›\×¬.1/˜ÅE¨ˆTŸÑ1?°´ÀóšİĞğ ¸v=
íWcX%:Eš@ošH<,8p#Cô5ÉÀÌÆİec©uÖRGˆXiA¾¨7×¢XG ²ïCîq©s>mŒ‰JiœâE4A<#©¹M¤½áoNmáñ¿İQ´Ş0Üó9ÏÕšuª5Sz—²ú‡‰U/ÚÈK¥9bœPDÅ¢ÒO“Ä€óxüék;Ş¬/ë¾!&Â·® €º’ä0/9"¼UÊúA||•wÃUvËs”pYˆé_]Npy“ç¬s]Z9­‚”¹ı[¦§gÎÓå¨T;òde~9Rï\à[¿}Z"˜-Rÿ]¥¸8MÑ8u(f.³ Ä°VŸÄ¢¶ZõìÅáÈ,èX	9w¨ªi¬…Ø
@	WòŞZ¢ÙpÒ[ÃALwãğbG¨iƒ•^CÃ÷îÄ´üä¾[ªâôû¢[åKMy8¦çàNŸªÄd@%ò¸6òM0¯»A{*}d­®/‹aı˜ù
Qä-ä{EätÿØºëB:”íF¢Äó÷ëÎõj¥ìH‚_= ØkˆI;ˆßtsÌ€µKOiñ+ùç€(@ÇûK™I„nÈ¤kcMéËÂŠr´•ä­n&šwç@­
qR5êÀØÿC1ñuşƒ™î× /SÊ3¦:A ğ–Ú)ŠoÃ6&VäÔê9çyÚdB›±Ä‚HT}Ç‡uKZ@¦ğKøÙ‘’X€Œ–¯±˜{ˆ±Ï©y`Óæw	Ã°µ¿C$_!æo‘¹@ÁœBz,¹Ñq~–°¨	#t/aIP°¡ucs#vğºÀ™UŞ¾fSöj¶]G0çUWt®ĞbåŸlÂƒJ<KK1Îºyìì\SiS²¶ŞYw†8U$£ê/´ùªf“(7–)®Ì\7€&I6~Wb9¸Äï­•Øu3$L¿¥à*º,„@*F`Åô sëœ/™z–o©3¯ºiºÈÙ¥ñ»EçÚa¿¼Dš®Z}ÖÏEàU•áÑeák“|÷Ô9»y˜r‚EµÚ¨3™^ùğ>ë`D·òuÏ’è‡ÚÏµª™YB>ƒ»†œ5ÛÇŒ§1„ŒÿØhZÀ¥ìV=ú¥6ØºYv+$'×#¯öÄM²<¢ú¥ä `™Š!æ—şkò­Oå˜?çÌ¯¹8¹íÉØ©ˆö—?9*ù†§¥ôTò<±à
èKÈMPû‡Ê?MŸ7ƒ³³â,Åmj&Èûê«†,'ƒSy‘ÖkÉÜ†Úº)À€
ĞTé>èÊ\oUğ >0"8h¡äéRQ%OõøµØÉ€%¶PûPyİqİëù%^”¹iy)Èf<²21OdŒç}ú†:ùî»á)"¸£Šß’êÈÈši›šÊ63}m**¾•§Hïê0QVN‰ËBõ6¡ÀÇãªÄé+¡<j¾.|4óãFº­ö¾Õğ¡Éf3:}6µ¬–®ˆjÑìg.ÿñ€íf-±wNî
I!(Ù6T~Öh¥0b­¥`W[*@O`eƒEåì´¨ı¡3 ®R¦{±:Eã–3x9¬|Îk/µJ±as‚ìßW¦{R íÁø%ê†…øQê)¼|‹G¢ƒÓqÍ§0¤piKØ`bz¾F7ãÆîrWzĞú¢iŸ¹£¨4¥W^‰©&Rİ©V§ÅH ›m %¨ˆ9å‘\86áÑ
æ=¨Ï‚pê¯Ú²1šc&ÿ9Ån{Ê'X¿†òioò^¬0ãìçE{Dë´E¹ˆƒ}Ş:êCæ“Ka©‘á..Q³= /bò,3*l—ÍÜå#‰o“Ø¾¦e.ck˜Yùv[›^¦Lnûé¢zÅµ›YSİşÄ*Ê^õ^´$i>#Ïş8Î5¢=ÎÖ‹òÉÆogëT ìI2V:FÁ¶ë(„@Ú§y~‚>}ı½‹ïÖ±¯—‘âçé¸w™.Â`“™Àİ’‹[ñ¥“ılA5údÛáŞíwºŞäÅs†šlÄI¤äï°ÇµLÙ* Al>™•Kˆ"5”L"7áúáæô©/‚†oÑ¹ã»ftŒÖ{ÊC"Ş½öWR–1³Mš”ªå®æA`:ÙõÄÿ`K°y]ITa@bX í•íó‚a‹®=Æ›ñkÅßÊã§„
Óõvãºòk¸Ë;	vc›ÑãQ'´ªKÙš™+´V¾Qçx3æz–,€Û¶D,Pûı¡¾,–Ùzi‘5nòœ uNİ<Ê²?l k÷u‰UÅpU±8µá¤ñß;œ~”+xóõÌ{{!|2áYÁ/WGX²r›qÿU³OÖ»{Îë™T.=˜]‘«ìÕş%Í§<úÇğ¼°xã¡—ÙQÅcËõ–+{vÎA2ß|k¿“ÿYCA¼LIêË¸mwq.KA¢†úœVğªä>áİèj¾ªT·½¶;î[sîáz4AÿM€Ø‹Ù“iÿ·J6kêFLÎó1T®´b×/²p°f¨çœ§"uúÆ6/h¨Añk™zÅªãÅì™6n,óİIK;áÓƒ¾,¦îôÛa ÉcdÖ±ß–Ñ]³Oáa}u¾èg£•ÌÒ¸¨¬ùQA¾$uj:-«&ô •çÂ
ÌÈÒ¹éHv˜ã¸4ªÛğ“Òôì3nÙ6[=ÿMÊ´øE|,=Ó1ù¥P’ï0€F§‰vxœ;,9Yƒ^ÖĞê­A°p5òÑ.«¨“¹NÏ…êè«AHğ„LemÁ”OĞH ¾âëŒ
+ÁQ¥}[Ğ ÊÅ!*‡Ñ/†
0£Bz\ÿ‹“Ö^™’§Ç˜í ÄÈ0ÓãÈLÌ«wÚÍëDô:}6KCÉ¸~7åÜBì«Mˆ—ï z¶Õ)€BbÃÏŸø$·33—Å«VøğR©	ÒÙÓ¶og£M•ML>½Y¸6 ˜±)(—â|¸`–úÁëõTºCæ«7et˜ÁÃŞËNõÄbÅÊäaŸÇe­dÒ$×‡<%Ş‹,Şı	´ÚÌÈ¸ÈYøËlÿ·o‚S‹şİE1Qé˜­U9nßË`şÿÒ³=õ?Ğ!wÉµûO("Ëş5,¹|ò¬Ş.ù"BWÄlçUªPû™\häçí%YëòÇœS×ë©¤°O² ´TKÙM@¦ç!°8¾É‚rE,Îñz³ÑŠvBù®ja}¾¶>!¦ûO$ÑÏMÖë§E®¡;Ş‚>ø’8ÙQÀËÊÇ-q’Ê¸ë¤MÆ×ïïñDm¾PÊùë¼Ñ”|è9w!ÅB¹YôO÷…š›p¶&İs…p ãTiŠ[PÛ<x3ÏÀZÏ[™?”3A~Š-ß³è´¹ŒfLdŠ6©ÏÙø%?>æ¼ÄZ.”Ø»çm8¹,ŞL‡Ò¸61`İ|¨ƒ—ªt-ôß°!ñ®Ì?Â,Ûöo¡í;X×¦%Ğ®9‘eª`ÍÂoùxœÚ‹s¶èy<E"™‡=ÔWI¦q£¨ƒOR5±Òn’µnæ®Šu|YÚ60 tzQ)ü^G8£~×cEÍf	ğFbÿvîÆıŸwå8Ïë¸	õ†$$ñ7ŒoüS)˜oû±N)ˆÒÖ‘…kÒÎŠ\Ã:¡q@?}!´‡Ô´‚äßßñ‰è–EhI˜ïp]Ä´«ÖğİŠşÂ9şjµÓ;mŞıÜŒpé‡ûC´8¸WÕZ>0è0”‚Õ*igúï[Õr±ş¢]$³@dÇšÜZzÙW~fŠ…<šìºõ6¥8¦à ‰ÑÚz:‘Éd±éS*8Y4v2IÉ*Íø<½…g‰[ÀRù•B™ÊsäR±Û¬é7ÅM¬C˜xí!SVÒHbŠg<Îâğ¬Zï˜Ë/;ú¼ùx±›Ç'ƒ¤€ò?ğÒ5ÿ ŒápU‚›!¾ĞÒıpèO.iW„.ğc¼wR-§$™ô©pOê´…¦H éÊp¶[+<à8%Ş°=N‹*®™«î€+ı_epr2Ü^3ªaŒêTşÛ“üÃoùTY·ó–óÖmn]¤ ì Æ°„`!®¼?Š(¤ù
É¡Š¥d‹}×]ş]C
ÌÛŠSu=‚æûo©ìİÕ¡óóúâ ½>dõ]E	¦šJ…5Œ×®0®›qM òÎ•l$mäÁß–M»óÿ’ˆ|Y]ÚJm‰Ç ”y•F—‰@òTT¸emıµ>5´q¡ÀˆÏB;£[ #¥zJÃss¤‹¢”±çñÉ½'ú9"¬–¢Ù.‘,Å]¬MÌ%¡Ù{šÀ›èjDä’Hö:…6›ÜïzSèêÔ_Fmw—À®?	‘‘,©»“œOR<¥çºÙKĞEùw<¨‘c^•F“”¹”Ät<'&áLw"U©U{»9¾ö
"6´òä7×ÀÆ+ÔdÑğJã2oõwã4‘CEœÊ€A*%‹P:¬úflRãlTşt:ÜÓˆŒGÿÉj'ë%î¹JN~S÷Ö_0¦ôu˜/­†YS_…x,¨ÍïæXæ9—2>‘ŠE
¶t.lgè  Û8tïç¡Q@z“¡	A¿b5…I:¯³)nJY"W9Ÿ
Â…ÈXÆñ¦Ê!ƒe&Ô Û¹C\	ı­%ËÁ§cúFQn*¥a<üCOª‘Ÿ\xJ¾¬˜¦y¤¥†h×Î[œÎ8û'„d—j.L¢nì3ADéí.³ Ø œ'ÅhZ ÜG‡wrT.ˆ²M s0>N9@’IS\¼©.”EŠ›A$´Ò~èÓªkÕ!
ÃZäq©¯dÅä†!˜v=¯œ¹/õx•Y9<6Cê`ÿùËÉpšÌ‹BíÊ0cüè‘[Ïr74äÍBÿÄ‡3ÎÚµğ½v?—d³BSµï´îZ'ƒMEã†3ı+‘Î&#ë}íÅ–dF‰¾÷QF¨ËÓkT)ú«èÇñÅB[[· RúQ¤{NZ=\¶‘!OöÚËĞ½œ‘	àÙ“¿!tæ´·’Ìòîgx¸•çÄØ–l¯¿í‚gnF¬ï%ca_{²Çİğ.éı!r¬u¹§=624Y^98ÿ˜E‘Å/Z_qó ;Şhæ»Êhs4äVÚyN¦$q¿’†ßé|:¦;¼,C¬ß…Ü,rõ~ænÒE9„QÆ<K™š-®%!O2í†@hÛ3oQ<ÊAwk§ŒhcÚİ±,eÚ=œöUÛÍO×¦ÁSx]·ül¦^Û4@>jQmgi3cn—Ç©1¼“•¬sâ$0t8C*öÔïeÅL‹ú§e«n?¼MÑIÇ½Â­ÚO]pÜîX†EH®0•-	{ Fê9 ‘í½n<MwßdG–ÉLüÂxbP'Çnô­IÏå´Ê·…,ˆĞxYIĞCjg5	•zP¯  3|ógng»«IõàQˆzÁÆ$V˜-9Ô—–ßi¬¨…#ÀÀ²Ä.Wõ¶×'{Hæ­‰ïÎóbˆÕ‡gSQ0Òû*¥Ì°ğû²–¢¢E@UäL£Ö¢_S+òs)Ê¡cüıİÈC`"9¹"Îa°Wxİ§é!†“’Ücw–|·†CH°ò¸ğ’¢ÿj¸7ç¸6"±ĞÕî›cÆ9<ôi¿‹0¤rñQÕTj±¹h£§ãÆÅĞ(Ítìg„ßY„Œ4àıîôG²ml%åkP€ùjÅQ|¾­jkô²‘¦ ”EZ°¹—‚ŠÂe_ønG\+8JU 8JQ×tUş4ZİÈO}›öLµ;ìÅE˜)oçem2k	F{Í˜“’û˜-W®hJn
Ù%iFÎeJû¦C·P‰HÖNê€‰âğpÈ/+ËİßA?¡EckĞ¬}Ş²Í5=77Á· Í¿’©|@xuÕBĞwş^ëGPwÿ¾¿¼o×b'ãÊ´4ñà»iÁ‡Ó$<ıããëÆ G¼¡JÜyÔ´Î|C„./ßº„ÓMG.Vµ2s»òá÷@µÈœàü ªÛZ í¸í‡jFmÀªVÄWd˜})ßcÙóîÖô¬ëQm~ÖC¸2tWcJõAƒ›Mx–üxùÛA¿lïDì†)E†ÖLDıÁıÊ‰VSXcv¯	ÅÑÅ¼@eI-^´ŒÏò(:" Y®P.‚&{µ8«(J0¤«¤ù1šócûM‡tÇ ·ˆy†¬Äbç\È»¼kÊUZPÒ1}Ôâ#è€ÊŠÃxû™‹”«ŠŒ4O‚æN8€y;öèp÷ÆğhÀF‡oèÿFq U¶SÅî5o(ùüùHqq½| B= 8WnAQb7ı´?5¸7™<=ˆ½ëò;¼,%w]ÎŒÀiUMÅ¦ø¡¯$-Ë´ ©Ü>†X+ÓºæwÓ)cg¤¡JE~Ç$~ı™Ø,Âµ}vËá8kä5õÇÓhZZE8“ Á 4Í¦ïæ¸Ik¦]CÖá[ò &å¢YÄLD8ÇaŞñ¾Ã(ŠÕéI.ÁÊÑ–P`g|sÒ\Ô}ŸøÅ×„ÿËÈ•ä-¸»…-ÇPåıó3ÜD6åše'Hs¹ê{A~Cû+!·e:G†ÓQœQGŒÃT/L€ht&ˆ¬¤Kği·Ï4İªt•zŠ÷Ûšá«àmÑ‚‹-cOó¼•ôlã®ÕÌÏşˆx_ÍL „³Ù¸.áIÿ#"HOÛ~´[G·!¶[¢›5(åoù é]IÇ¼Nhˆ$m+oKì
é8õr9îÊ©ØÙ9}Ìõ±¿¥–7&\¿‘1ÉÑ²’Ü?R‹*7”çŞtì¢×KUAØ|	i Á­z²åSÅüMc1úøÇoŞrÓ^åÀ>¨N¤Lòn£Õ=Ò‡fá9„?±…[4[l*tGñ‚÷KïŸœİ"åà3$qHAÓ¶·ñ’vp:,$«¡tçS±©'ë×Óaí9¹>†snŸ“8¶ˆp*_ä­>ŞååçÕ«]’¦Ø9«ØZJ\ä´ô¨I±2) õG„5¨ßEœWÀLÎØß7a}“~66F{)Ûj3Kè5Â­»r.¾¨0}Ïş¡…çİ¾â))±Ñ!ŠvH¹ä2¢›h¹°tö/áhØ¿äf£,‚¹‹œ# æŞzT8ûbÕ
nMèƒ0´qöŸ˜«ÆÍãç¬IAÛa=µ;%‹ÏœªRïŸ¤ÀÎYMkE”Iä?VŠ9ìcC—PÂk²nò¨è;%NN *£}ü:9¯ ÑÿÔ÷dÏ)ú¨GöÑÏ¯ÚÒw¦%;ÜNLùÚõ"-Ğh2Ï|t”ä>3(Jñ^ı¹Ær*°aj¿î‘É†¨ÂOì#Ş–?ÀÏèĞœ,mãä ˜,OÊAó”·ì£€; ù6»İËx¢è•z‹ØG°WïŒÜõO?ä)\¥p§
C™ÆñTfEM•T³^òPœ;ª6GjìRæçŞ¸šbŒYÂŠ#„Û»"¢|À\#‡.Šúùş#ãr	ÁÎÜ˜L½SÖ”ïdNu[4À$¸TÖè~ê=*Œ Ÿ£Ÿ$>¸mş}ùØòƒ;ùE)FÄk °®UGso@v†yÉéãàˆM+Pª+êÙ€‹™Ã†‘aãOç§Y¿ ]º¸ms— Å¡ê²€.£ñÌÅED(Ó:ùúÊ§kÄ 3Ô¶:ı7¦F•Åd…T?*,Ä‡“ì¢éÜÔ¯T—i‘*û½RûMôÊĞ]Ÿ;Í)¬÷°"ÃK+X2¼ò-ÍS”5o[td*fà	ÖÌÂ%¿f¢9Ä\YStM¢Nˆ˜å¾aÁÄˆùaøõëÄ[[²O®5Örî‰ÔmóZ˜,ì-”µìï×%2…ÈsÕ¯”
(kÊûÿs“ÁZ|Ló×;Í8XlwQv­õ¥úympÛ]‘ëÚŒÕG¶'ì‡J¡ä˜Õ©wÙ"Î†™”ù6é ³g¿‰šŞÜ'ŞĞÃ3†Pd©yÙBË{­d`äˆ„}álÁNÈP–Ì‰ë;8^îb‡gÂ6ë{Ö½(aıQF¯ıIOV…†6D‘¾ªÕhM.ÀkÌyLÑá¦B©†ubû ZÕ)øU%‘ à'/ ˜"ôÀ‚½ïê”*÷ïß«û–|ßËÿ09÷!sØÜXş ½¼»‚çUrˆså“¾è?à	äFQ™šk4`¿9¶Oìç-Dì
E`íú>=i¼][­åŞ!)¨•ã¹Ş3¨ºÛé¡«­)©J†©]µÜ’MÂ”Æ2P	¡.ê)ƒ0eù¯Ö&‰~çÿ]A±`©èÂÀƒ* \«êo.¡«Ÿi‚©Ib—!ÉÙNï9¸õ‹Ê2>nßkæ:rÚ™q¿ß·WÈ©ïé#4•—-YåˆXÔ(Jß	»rp\RO¡s$\†Õd˜xÅº_ºÑü'íìP.•@ä3&Ës'vêñr`õ ³ëG[X]ÆÜ†®ëpsé-FFÉĞLY½3Î’´ªG÷Š´·F¡³_¨yìàŒ_2ö[¢şsVıpÕÅÖi¸æé‡Ì{eQğÍ\)k†Ñ_€n;*,.PÈš²c¯æzGª4Yxù@§œ4™åRòa@c{>`#¢²é_ ßT^£)Çå¢ÅX}£ò\ü'"™È1€{Ï_äƒ5¶7re¥²ºA˜îõ84Ti#Pc0ºŒ
®1Ÿf€3õ˜4
°k¸Ç¾Øga6t¹.Z¾ù-™Ş(HeãO´•¼ï=~È(Jà2úìè&eÛ|Îò°ÌÏ¼Ä‚ÎèpÄªX¤/ù«ÜëeüZŸLe€³~bŞñ´½ŠØm¤Q¼wÓZì!ë­]½ï˜w–Lš´K¾j­§ÆqwÏğøÕ`M×û	]zßÂ+lˆ±ÖÉf  S“¬ö¼nH È½€À©º®Ú±Ägû    YZ