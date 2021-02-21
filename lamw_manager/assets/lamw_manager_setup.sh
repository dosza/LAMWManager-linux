#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2759277282"
MD5="b62ac8add24fe4eb230e39ee4c08ca46"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20976"
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
	echo Date of packaging: Sun Feb 21 19:07:48 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿQ­] ¼}•À1Dd]‡Á›PætİDòÂ ÆàW´š)iÀ­Åe¡Õ¸iõ¢dÈ¼/gu.=s,ƒí²åÁéœ3ŒJ0w(©İ”™±Îæ]Ï‰c“ÆÆ›Ä’y6¸Hß"º'k^!§SI¹Ù
¡Mş$Ö.Kn6p!÷ò@ìT¥`ÉM®Ø–ÚÛ×ÍÑ$Q×7/ì7r4‚Ğül;¯*DlvÕ@.ßÑ´ I«LÃ]é¨
_f6tJˆùg=Ñà^…cêß&³y»KJØl8‚#Ç~ùÍ]W½:¸—iá/Ò¹•£¹ƒICd4ƒük‹ÀdUfà¥l€Ş+é6]µìÄCç’yøM¹‡–Ü|X®*æaSßÑ3|µ·Q¼\”u£øA²0ÚŠâvmXNO®_hÒÄ ˜£b„§]FaÈø¡ö/jP4“ l3£Zğ?Ä3Á)P¢pyP•H;¥Ry~_¦¶Ø—,}VkKóFê İÇ¬ğSEËlmÏQ!£6a3®}Í¾+»«_DİG~àœ;¯ÔPDtÏyÉf'gc0ğ´ôEa—)<«²MÍJd»1Ô£MÑP­3ûË	~ä¼Ç(Ï’êy·G”4íİ¦j“t”µkì¡¶øµ|9!„ê{<Ö.Lm?¬#¤-îää­ÿk!rË%­Y®ªh¯ó|H¦ÂeÅ(—ÈÂ°bëO}Öõ³ÁA?½Ôï+¾Š‡~ìgĞF'•›`\d¹›· ãã^ãørÙwî[¹|íÁŞiÚã±`­\zg[Æq!–FT+ tÁÓU{·³PôÂŠ‡]¨Í’¬8k1ÃDÑD%-vë–Qà—~„$:")Œ¼ <sÆJ\ĞwFV?â(ˆD·nß8~Êy®Ù|ìËCöÈAúÈÄ6Ï‡+W”d½Ø‡+˜á×ÛËuöÖŠ˜]‡*.ß'¿áô°…”?,·Û$
Ó³cåÆ½™(Ğ$u~4ß”¸|>ŠS'$ 5¯B}¬s¬4Û[T!NH5-è]±f[ÄcÜÏM÷ÄõFÈ³œºW»U"…Kx•Š4†nå”*¢¹P`Ô‡œÑ¾®·ì­+j²²R<œİmÙ—,°ñ!Sa¯”EV‘¾K’ÈÅ}H@»ˆ*Ş†æÛÚnßÑ¯ı§]»ØmäÉf›è¿zO1&¶<^şçÓ/A @:Ï®	çªéÎ¸ ï‡şÏ>QG0)”‘ŸnÜË7¼¥K
äb³ã™ˆ…ê)°Ìe~y
zÁ$±;‹Q¦"äé(4zÜô7pvÑ	åæÍŒLÊzÛq³½Zï-`¶4¢]û…Z·E:¡Óô‰œE–@¡	ö`é¦~Úá7ÔqD3Ğõw{ËUH§oƒıÓ*÷ K\…Wië§ï®×òğMı}äĞ­ÕÔs"¼³F l'	²«3úØÁÖ94Ë")Óç½X|€öÕô°Ê{ÔJŸ‰°(Šn.²ê,mFâ–ñ^/; SĞJ½-5Òs.kšAŒàYÇ‰$lìÂÁ(õú„§v$ÂİÑ+ç
À†P¸´di+ñ½Íp¯†_œ¯]où›å!ê[•éøå2M.¥:×ØfœÏı•'/E³d8 %‡Æ„;Ê›ë¬—ò-#JLÙ.M¤î4^—œk"–\š^/ó HÂKµ"V;ğº'ñ/œ)¸7å(³1ÜQŸ"CİîLL¼]×é$buş˜W–C8:pLpUí¿=¸ò•ì}¯í{sÚS;ì+{0†TÅıÁ@Y˜{¦LeÕÖªÿ®X¥ùãR³¢=êJƒX1&xa¤©6_oŞæ0Äx;’½ó`||£.g4ªÌ
˜ŞI)‡¯¨&ŠğBüÆ£®`íÇúc]%’PŸİğ3êÙt0ë5åÉa¢¶9¼î0Ü¯óî,ÚŠ® !•‰Æ¡ÄTõ˜ï‚™Ál÷Á°EuÒk€¿yjv„³zğu(´3*¯æÓ·ï tœúSî«ÙÍÙÙNÀRÄ|¶†È}ÿ<UŸjã,²§œÚ¼œ;S„¯\„cG[ç+%Í„bıîÂU#6òahÖ9q	°êÕK zR˜ëôÕjLñ	°í8ûÛÓ‹®q$ó+Æ":³Ø…Â€FxŒ>™ö 	ÕÂ` Åç¥_')²™­6oœşaEŞÈjƒ\19aª	Óû÷_ãÔŒèÇÃh–àİVÒPœ©Aûc>Z>¹@ÌO{xıIføü€ ›1óaŞ,âr)ğéÑ™·”GÓk6~›‚Ô6²Ë—Hí[æÈ’ˆZÄvc–;o¼âD¡×o=<@¸g³ x^Ÿ¢UN¶y›;Ç)&ùõ»Xi½Fe5ñ>~%ı
Qy† y¬«S@Ò"|	î¥·/>„ê4¢¼<tlŸ‹Z=¦9–½¦V|òXº÷¹¾J†0›§CIˆ\¨È¥œ9…×_$`œ~š!†©”¯½4EQôFÏÒ•øS=Üˆ(Ç½Å¨ˆLƒû—ÕƒXÁÿpJˆ¾%¿¬¥lÕî¶'mÓ†^‚¤ĞÕX·œftRnŸÇ”¯8ã)I¶W<Ãùy•y
]=uÅ©œQ«¸7íñšÅš¹h&Ìe"…æíÁøìÌºŠx%fÍôIšün^s¤‘ˆá,s¬P½S>pJ"ßfQf©u_nÛ¿`…{-d,xî{üÓû™™úfşÿˆåE–¹yó8é¾<'Ç¾ÉéëèvñÂ±ÓîÑR¼?ßCsùUôw(ZCô£
 ]ø¨kuiø¿GïD•ÎG}F¿Oq72€U6wk÷3½æƒˆX›• Ö2ÆsNp@¹‡ÃŠiEÄ»ZÚ5a•Ö&!—“EÙ¸¿!Sî#«ëüî‡
'DÜêÚxmÎöüË*ÁçP\ìòG#ÕíŒ& 	‰@ÅC çÃYQ
Y=G_Ìñš…©©s‘“-úäÅZ8û{ƒé=*×Áßû	˜'Zì ä¿ åáuóÉ-Ü$âŞ0¿IKT°Şfî¦‘òm2o¾ñ˜W VUü,jH†Lí•{5¢†kÎÃMC›Õ4ı×ü×¦d¹ÒSkLâ-{I¶oLOş´™­ORİb¶›²é^NÎßPÌ#k×Ññ0à.euèÂOVÌmp{L‘>‹Ø„eY7»¤äuÄ_ƒåhŞyz&¤”„cşâÖbåÖr¾|Ğ¯²‰©5>Z{Doıb‡vOE¡AıxĞÙãœÛ—…KÃzDãêòìU€åâœ#î-œŒ¥çÒŠ¬|0«°¹ÙÙ%!D„M«‘ĞXÏZÇLYWN1ÛÍí
h"hÓm{Y›Æ•
Áûl +Å»ğ%±ììëÁ¯èğ|-«ó@óZ*u£¿¸<>¤‰†äT¦kwñ^üš="³Osyl«iY¿wcÓ%˜h—ÄäÁ
~kz³¡´7s(_1K·Ïn‚½ÅZÖ¥Å+|"viÅÉuÓWª›&óî<¢á[½=’öP7±GS¶ôJƒÒfAÿ‡•¡$x×$¸:ä‰AœòwGÎ lüÀç‚èç[u£LhÀÕùÒŠ§1	¶IÊC…´=ìí+CoJè Â!O.$ˆÙFõÕ›ê>ïïkµìVÇ¬^€¬ä{\l‘–nZ¤&SWt¤Ó+M8…PÙ¼—?Làª^[ Ô›ãùĞMèrôf¢K1rş¾s`r b«C,îrZWåˆÅÚ±@¥ód(G`Â³/Kã56×¯µeÛ¼ÕÁ±7åfòÊÆ¸áÜêÖõÔŒgü™£œ¥kÌoKá÷„íV¿º+ÙPñV‚_Y™æ¢^İZÑ#æúpMåK?ÆÑ+bØÊw%uï“\{¸¨ì³Û.×;*Ì©!p’*\n†	ŠƒaÂËÚÔı 3–Ïã>Ã"ÍÏ^…¿òÄĞ»(®;ünEITY/u¤fe…¯Á\ÙKš›âÂ9Ó~ÚÊ‚Wƒ3k¯}eelÆI4’Ö¦ã¤ÄÕğ\‚oÿVy]~XŒ 
„İŠÒ'¾Ñï`­*ç‰­#½G¬ÉH)%ÈJ`)+³æÂå+y.PŸë¬ÖÉd•7ÒØb$`š1Ûa@µ„Uæ3U`
fˆ‘Û‘Se"ïİŒŠš‡¸P;-ˆÔ`}&ğs’Ú3ÕD;bh˜i7?ÿş°ù h3ïOpÛj§P™Æñ¯ñ=jA½~šäG°J†|ò{èÔ©¶¾ XyM5‡İ¨Õƒ†.>ÜÕ¤ €‰Èúö:¢Ÿ#ãvUk†lÆ3ç¹ã?%÷²q[NFİYÛ”ÌÉLEÛï›’‚²‡ßÑû"b˜ƒf¹û§İ¸©Œôé&ÂÄ§ö¹;gŞ‚lŒ†F#×GÇäŞN«Á=+a2óõ1~*qö³r„X?8bù,šúçæëD=£ Wyµ]»¬¢PåXá‘äÀY>JIÏRuÊ¯S³AÀ~´¤Txµ5ˆ@ıRgŸéo£$o›6–×z×ÿZÚ+óÅ¡\™^Æ™¹Ş¡Àİ™	.'JÛ‘8öbZ«¸YÑûñ™ÀA| şÖĞRMlqÛÚíë†;…ÌŸ
“û¸•dJèæK¶·“‰‚ŞD6'£š«O‹áÀ¸Õd 7cåè×CÿÖûª\ z’ß£dû[
(˜Œ¸îÁàĞË"×Ÿ&7Eœ+EØÿsó ¸·f>Û.écúväŞõa¡Î#Á[]®ºÏ?œªWjœ˜åJeÛ÷·­†ÿÈ'-Š÷ÜdwVÅGá5Èßó‘ƒ6Ó&!êÍ˜wjhğ†c&îahaÀõ=Éïã÷Õ}­¯&KıË# ğ6"pê¹ØÌYÍûM˜$ÛĞ¨ÓÕWİÑjÄ5x„~ü`™ÀÕGØØÿUJƒ­OÿüóûœÅĞ™.b™Î“¯±v²dtlrKİÂ­@ö'nÉ—~šú'fü&.×ˆ¢\Ïà¾ÇgnÕØùÄ™€>×E™xÃ]Û±£Ï!Ü¿5zvZàop"ipÌ>¥6Š£YÌT‚UÄ£“õGØiLcµ¶àĞh¥°]}.xæÈß4M£2)!m»²9ê $¨bÅAÃ=ßt<ÜC)V¥5¥LÒZ˜*ı“¯’|Š‡Ñœ#-CÀÌ¢5c„+µÕ–¤ìÑ×—Dæ¯²àø+¯ŠCŠqÛà¡ß%Ÿ»;]¹èßıÂŠ§òn š,ÁÁPOÃ†À§¿"ú¼¹#
Yø†êp´İaX¨!“±ä‚bd½Ê’b*‡(Ìe¬Ğ'>ÖÊ-‰¶9[ÜŒt«ˆšûÀWÕı>ïr÷G@²I…§®lŞ÷ÑOÔê)>bÚ–Ô7ˆ†¢ùPj9Â©Êl,â™íÿÅD‹Ñ¯Ê2%Ú_	õIGÍŠ²@³A<¹PQş CÁ
ÚK£¨ƒš‰{$d!WØ-aúêÌ™‡ØE´ƒÅñ]9CE–Òsö¥myàû¢µQİD˜€ºÕ3‰™} pYÛ|W³Nå+NÒöû>hM’É:¾²‹×mIÒ9×x^Üé>ØÛŒèv1kw°Oƒú¡mµùÉKõv`úë›­Ñuño™xéé{ˆìb©½çK™`âwÆG»R/†„ÓæÒ›Z‡•êDÔ“äZ{ÀêJã‡˜«i?H‹;ªnë‹­FÄ ÂzêîxıÚ—1ıÍs2\±êøé<4êš†‚ÛezÄUh¡—x.äë‹›ÉÿÏû®RÂ:xŠ™!í„r¨=iÏ1™(Å>o^æaß‘”ÃÖ@a“°l•87üÂßÄÎH³G™"éWè%MŞfij¬ĞÍ.¢à3ˆ¶l<nÊµ@d?á`½íh*ä$	L´®¡X¢àJî?jó}«Y‘Šşüó^Jæ{H°=?)U 6 §şøsoÃ7gãqÉ*ê±_%//˜ñ¨6è×ÒêÏÂ "R°¨8ÆGÆ	£­á’3<"B3Œ‰äà»yÁ¨‹ò/h÷º™ÉöˆÅÚÍ€6¬µ¿m»rËg:*cö	tÂƒ®nÌ‘° `0K%x»ÖÃä¸jWê·ÔU?¤+¥$—â‰Ã·x[(,Øäid« ‚ÔàËdÂ)Ú•˜…z4O2´ä%ZèD#Ú—wËuhU9SĞwà­F½Ö\aÆì`Æ!¨<TÓLğìĞa9^+fEM|Ô­g÷ÿ¦ğé…eS¤ø•¹Æc®±!^ñÜl,)ìï”^ñ¡Óåfç>*õ§ÃƒªóàÉ hhèåİÏiné¸ÂÕBÚ’’Õgæào,â2è…3ŸE£…±ûVR¤öNŸ¿¡a$<¢UmN†>†ë7-ªâ-:§98%6ôKc ¶ÉìŠÄ¸M^;*oÆeLª‚Ò5qşE„'@û
$²Tem¨ş­÷$¨8ÃÎ±*íÂŠ¿÷>ÿSØDĞ©iì…ÏÔğt.sge¾¹ÍJÛ$}O
<7agökU!¾CˆÁ·ıîEæp6?BıDíÅŸÎ×ûmt¼ TéTöımÍQ›Ò”_Ành8#9ú!ƒ`²œ°]Ã¢ÀìBâ@ÚF”4Š4‰fQÙyd{v\&õ,óÓL­b~ëG£FMy­Ó×ËÖß¾9|{j¡5zÉH†)\…ë’<ÍÓ(ƒE¤ºö¢páAßĞñ"s×İ ¨kzXº¸şƒ¤,I¯™¬şcåYó£òÔBà‘‡w[7t<\2, u9&”XL±¶r{ÌÖˆ}ûßÃ*˜.­ªø~Cª£a0¿ñ,Éø:ĞÓšHÇ^ƒô¦Ô5%è+n&Ş8Ù†_\P·÷x±İ+ŒNüX	gw0ŒÓHj¹/áûª»Å›n´/puùç@Éoá¹aÅ/?2›¬c‚šÇÓÌÚÈış¶ÖPvè,JhB	ÏH¯}
H‚>‰Ä*ò	 +Tôh`’şîEj3ÛQMMò÷›ë 0S6Î»d4œñı M-#ı]ığ–>ët—®—gy«A ¨hE}âŠDÁ®qµ”ıNÛÀÕ…É^D7Ôç†Óô´
,¯¬ĞC'X]#1sÊ˜=¡.Bd‰RY\:ô@ÍoNc._OÛš)OGsøuFUÜsNî¡ Ë¨:²ìğ6Óì¼nÑ—3+¡Ñ™°•Ü‘ÀCÁZ•ıÆ²Ø²y¹£’²©`-¿¨ˆ| 6…‹VôcÚ¢Ï³GÏ¢å%Ù-q'›CodUA}ºT_²õ‚–‰¯Rš¹ºƒ »nÏ‹ˆj.OŠ/T Ò¤¼İMq•Èt¾A{v÷~¹ÅsÙz±8=µÄ 5ĞYš¾Ğö9·Ij˜Ô¨Ğ$$[ñÄA™ÆÉ¤.p{;3¨Š¸ñ3òsåŠzäPÅÍ›ë¯„Ö­zN¾hérÊ)º2Å6&
zÄkb†#`.§ÈıM´ŠR¬é4GÒoIÍC“2(Dœî&+2Dœõ]%o>úô°^EÁ'0†‚×íÀšc:Ğk˜ôœ?®Å/À#ıÚ>$½ş²õ@¤„Ûøè11hONæ&j~;0`¸Œ8Û|½øC
é‘µ"ËàŒÁ!`€ô³¡@İËA5İ½,Z	-«Nü$¤£â&i6 
QÓÛ/‚÷¿0_™MTJ—Ñ§ÏM]Ø£¸î¨
·h´ßbQ¢k(&ŞÛvP´×£‡4T2w=ƒ`Î¿'3W{â¢ï"¤LìKßi|ÕÀÔÀÍ/±? j›*) ndNÇ&Q‘¥l†UL:µ#³±7¥b§•âÜÁ[Ú½ÉÅ™‹#Tú§R/Õ$ö S‡"†E¦˜£/à+u±=VœbûJµÓB¥
,ß‹\…Ä_ò4´ÀG£åÛÊ¡º¯x~ˆÚÇ6vPF`y7\Ñd&AãRÆÑÆÁwWøa.²w-'F{^àÅ_]Õ™tˆ›(Á¢sb?¬÷Ê¾wn·Ç%XæMéĞ–N²–§•Š{vz¯œ¢¸ú{?®é<hÛ~[·ÕÄLUgä’Ähií&~ÙtÿJöÍš~ÜQw~¡bĞ‚0Öê>¢jıtæx¨›kÂo&ŠQI±P:»$âÅ˜"w7gäüè©şoM¬*ÃoS·aZ$!/î´…ºğQ%°äÕ=¦vÔfºóê•ÛUonƒ÷/CK
Ñ¨Çí+×İK-—Ë‡t@gwJªÇ„CG¯GAq7FB•ğ%OfàûÀkŸ˜”0s÷äNh„ˆ,@x‡? ÈÎ»d¦3qîfılAx4¤@õä…©eff>?½¶=ëNB:oóh·Ä•‘À$—{ ëÜzdK¿‚ÌåÂ5CÚûÍî“Iª{àT³coxÖˆH#É`)q3•ÀzsáÕÎ¸ª—¡ÑÅapj#…ËG{›`ˆ‹KFQnq«":·R5M»Ï¨š}íùÖö_Ÿü?àñã”
÷W~X&×ùìİ€+%¾v÷,Ï25©k9«t#cPu÷;¯iZ¡Ä—lZŠOK)ª·3Ìü‚Y÷™ Üè®‡Üÿ¾-´ìl;ñ3ÆKuÔı‘uÅÎ²”Œa*—ù·Tb¤E0s&õ(ïÇW±OrÈµÛ£Pm\©ÁuQÛi7ì‘^ˆWÜ‰§–y5 zÿ£Ò—@¡VÚ\á›_#Ñ“àKJ9L­£ş†ï6R8kcßŒ´(_/<ó¯şË¶e~'tÇcw†??J€¨—÷¸°ë°Öjÿ¦gJe*¦SôÜ·ÄÂ¹&œ;ë“WMş?±{uT:º­ m‚wÈ´è«i–OX¿k;	NğÊÒ‹˜Ç¬·ºäO½*t¥º‘‰ÛÒXÌu•Éöˆ »r\-àg³»|9'nK¾^Äx°úaÛ
I	Â¹Éa\|52aU•êÀíFø]ˆó6_úR_~M6ğ
îÑO!NSŒ½'âØ÷FÑ˜‚A›\càÃ4XÖI ·{ëÒN­‹(œY¨¤¡¡½­b0l•99Ç«Ì6Àöş/C»3O:Ş†)ÒïrKöÃÙ0è½G§ÒCûaëú)04ı¡™çw–ëù‹SHG'ÍM?höU$507Õ°¹1ÒKL‚®¬È3ŸXğ^|¥9£\]Ò]X5ì´¥à6gUä.·«Ø˜õ–´ó#§Jíù­&°Ò?Äjè…¡¹œªâòX]¸¢î‰Ö)•2—ÈSo:æ·y2éªåJêoJ	wÉÌÍÖÑuìê]¯šıE[ZFu3föË¸º·ãâ0¾F÷µp5_j	C5
‡$ÂeT5òÖ4u4zj®ÌÕ{y5Œæs¿hıšt¦Ä«ÛÓ¡E
3¥3i\HŒ­aVĞ(¤G}û”ë”.7Ú›ÔjÆNªÒA_WD)˜Èõøë ß „Œ†qé†ÊåÃ€C²Ícn€Œ`×µ.uí;±À„óáÎGT¥ ¬øLÁWÓ‚ZäÒ»îr%„şÕŒ›°ölñğÄ÷_§Ñ[½•‰.»9ì}ƒîí¹U)}ÒØ¦¯³XZr÷KbbkùKöB
š€µÕ	,"¾³&–x‰ù÷şf­Hsß/İZMˆ<6è‰?0æÇRé›vKc¿>Ö×™¯¿Q”Úöœäùh¤u»Œ½{ÄˆFV|9ÓyoÍt3S*6É^~¼ïk‹7±Æ’m™P™Ú€ÓU—¸#cÔÂQDúÉûIÕ<×&€Ïç¹C“¡ÇIL•`Kœq«Bw…›ÓøK¿¿à9÷×­8!„i„3g¯ÙaàÅ^>På\İè›8ši–¼%A„üÎY1¦™Öt:ê™Éúâg;GnëH3Œ»À¬8±õ7&—Y†×P¹UCĞ¸âÁïDIàbÊUaÃJ‡b*N „ñHwû;œÄâĞùÈYyéŠŸ3¶‰?ÿÿ§ ¢FKÑnó.pcéÂÑÅ¼E7
ğãd Å2¯Z"V"ªö{ºN~íæ4d9ßoK¼¸Ôß~§Œò›ÃÒc¿C»vÕêmø÷'Ëûë/z3¦GÛÇ‚°\5wâı„¶<¨ê,0ñfó/rKáEãXø™–°ÓLæÕMö£9—Ÿ)3™U±†é9µ+dÃßè]şiú&Äèa—¸%EÍÀI#LYV|"«¥\+}{Püëö5s®;¸Çøhˆ/œÍ<OŸú´»HÈêY¯rÔ½|wşlT)NÛVüÖ•¼?5ÑB›;I#n¾E”HøóV	"¦ExÂ,W!VÜÇVhœwús x1¸[1ğ ìŸ‰(óÔÌêprïÉœşäZy“
Ìpâ$3®m8pCş¹6ú_v6ı¤Ä:©Ç½Ø:†øeOiújZë·º1† 8vk›Aˆø1ĞÕe®Şe±+ s*›×fÜeByîÿ88^&à)6:Dƒ4V_Å·±AFÎ/VÉVµµtF¥JHf3¥Â©ZPvdÁŞ®öç~ÇsjM°fkåF~NŠ'±¼÷Énƒ~#˜EdTÉGúÿĞcdŸêü§ˆbıFòu™”œ’b:ä„	¶VX`W½OÕÆ‰“àãØ +±
 Æ<:ñÛJ Œêªkå	ğ…Ö!CÄ8N»wÉÂÕ,Øöà~YÄíxëíãƒ€Ënd|vÕı#j°£X`¾v&íòIüu\2¥iÎªè‹`·LÚ}å­P‹N¬¾ğ0t½“­IGGf<`h	yFÃƒÕ8<;€ûföÜ…ú;en4]–Nñ§Q°PÚ|¹’‚?&N„ğW!èe4ûùpñ·!c8§^!÷ê6Õ[,¥Ë$fr9ââb€àYÎ˜ËsCÅÁW22ÖÃĞ‚‹÷·šl†îJkºq±`‹iRğªƒ­ô8ÏJƒ@P “|¥$w®˜í-ü_g;ADÛú,ÔTiZ'¬I^íŞÂµ)`^¸¨ïÁ¢‡÷9‚I ­Ç‹"wƒ'~@ós+ĞTûRğV¤/)ÑÙµ`n@ÔdØ¯ıÿ´HŞHÆcÎ×ªÅ¤mQs ]Û…†‰¯óCfîç^(}`áQ ĞŒfá@FˆÂ ÛCÍï„©Ì6$lôm+¦²Âï¨%ÊUw‡ÁqÈ­>h»ç¨Oq)«³V·KúeÃoØëG_gaô0 ‰‚xÊ±çL_-:YkxRÙ@ğnÒ¥ó‡sQ¸]EŞ:RI:Q5pÿ\­}Šı#"…81<mëC7˜8çÚ`ÚŸÃ	•q.¿ŠW5L‘ÓxKbê¿L#‘Q…i’‡ŒçI&ëâ`óMº¢À‰ µ§k0RÔÊ÷ôZev„ÂÄp“a?ùh\-imÑˆ{×§¯‡D7,¶ãäØròª«{UüÔòuÁ…îõ½ÿëuI¢¤öQ¡$BŸ±@ÅŠf	d3ó^Öô™oiFhF23—³Õ#d4gÒÄ~yë6ş´Ê ‚ÁìA£8´õ„c¦¿fwÿûÓøJêuYá[§û)|^Çó õƒïê mzÉ®è;‘2›©¤É¶MØìígn°ı5TRóTdi?Ê.çÓ‘›­ ¶B©*ü«	KØıXèß
E\jD¥û“tû¯¥K7
ZÏ€VšON*ÀéúÇ(•"èáuÌø|éªZ14ÿ°å·¯ÀJøâ«‡Â°]\ñ¤\)ÔòÏ‹ŒAïÒOsAŞ¯‰r[ÂÅÂ¤|6çùo\bÑèhÕnÏ.­Y€ÙFWZ÷9B½¸,ª+ °S&8s•["qR»™B2>’Æq,dP|¥í#²Ã[ï2‡‰´áh.\‹”[Ü-)IWq¾p¦ú£oMïI*¨ÓÔşnã&ÑS{ê:§õ#†Ÿ›1³é¹´C/ôFM?óÓù‰'=î]Ù}ã^ğ\²ù’o©aì3Rõ æÏŞî|Y¨76Z‰aF`B‹_·OşøíBÈ†®+|ì
âé5 £G5éÒÇ±é!“êß:ÿ²¡aƒÍ“"ørÍ¢@{iˆÎïdû:#É|ŸŞ…©€µ—£~ ª°k¶Ï/=G-JRÈ~×Ş¬Åù¾¸şÇÙ ¦ñÛÙÜo|q4U÷o¾^Xª†½RnaŞ{QK"òİ|“4Ü¡üÇ\»ÿ;‚6+¸Öe¨ºúœt~u3ª”y­ƒQ.Pd-e;†Üsÿm&IŞvcøWØ—JêV&)/d°±V"ÑZÛœ>³ÿÀbzq ê¶)üOÀoO}¸n×úüQ»ş9|;Ê.ñşmÛÛÆï|,h×%lB±Ø6äí¾tct
@²ª‚çÃÛÊ¾ êŸõIzQI8ÿ’¸8Œ™ÃmÁ@ÌP.,§£0Ú¡&­}õá‰wR\nW2Á†	¬B8kbÒl-­ÄÃ+ÑuüŒ}|×¢öEKá0Y€Ü¹¿†Ğ&J-¯İŞ{èŒ0 9å”•çQ,TÅ³B¾å?%eE£ÙëàëØp1e™ğ ãï«w„¹ÕÀëûdœ¾Şş7Šæ'ù;ªƒ7É3Ş¨oR|§yÏO/ôØæj+âìÚóeHµ$Vn 0ğF¹¨XµşÚ`8P2)µ?@7À¾:‚åÂ¼Ê‘Wİš ‘ËÔVù™ô‰™©ææU0^—4gy¶L®£ätQ,ßë3õú~À¬5Hİ¡óÜTÜ±EI¥ulŸ—±á^„Ïo;?AÿµtuŒ„ã59õà÷xò>HB™	;a¥£ˆK‰‡½|,&_¸ÒĞ'šÕ©C²+âá*&ù£ÜÖ{A>Šd©EÉä¯…±›^¯î‚ßBÑ?VìhkŒ7‡±Cj_rÖJ</Û _zØÈt| ÑIùK!´qİ×èÒş‰øXF)^êŒ–R1N÷·É+˜[ãÓ‹
¢</j¿®"aw¸˜?"NføÏ];“A$oñ¥Ûî9€²Eûxš”jDz/‹li¶ı,[¼£Oé.>¦3®DóÙ¼"zòŠÛ‹Sæ•bÀJLŠïüæW½D±© 4V˜ihKI³P†L$vqN»QÆµa !ÇıÔÄ—Œ`´»»Ğœqé¤áiZô	sAã1×ç¶¼ynxÅEçª¥³øEîyéº«\KØëy…T÷úˆ‚ä]½„M‹y“Æ”œ÷€dÍY‚¸qÎŸBŒäµ:„èÉèÌÙx-•K¼‰ÁçÑ³5u{'µ–9$,ı­iaÑÂËòQÜÄi[é„²¤HÉÕÏÄë¡¤Ç)ÀŸƒŞ×NmJÒã²ğÍc“§–¹>¥Íş€Y«GaÆ{Ãó©\&×‰@¨Éš‹)oíøÛ—íşæ7‚‹ÉUÆ¬¤” ŒbQ:G1ÙcÊ¨ô#ˆÓX0z¥!á,ïEyòd@%µ{Ñt1˜BxÙİr¾Èbu‡é†9u³ •+?o<ıw®^y®:ƒ&³	Şd®úÃ#Ö|Çäñ$¬Ç»x˜Îsª“ém…û¹Bj ¥Ú0hŞ9Ù*Eİ.§(LÅ†¼é/Å““~êUá8eóx*Ó’ê4Ğ½ÉS}ÃéHBšöz¯M3)Up‚Ş¯<!ê|Ó ³2êYøšjÎhm‘„,Õ@Ğ³3XüR|F.÷õ•`@•Ø#¿ßîg¸ef¯>”çäªì¼=øXq·ŠLŸ)˜ eçn>Xõ
¨©;»BëAn.­Hğï3 êª|ƒ|Ö¤Â>Y¿èÓßA!R¡‘ÄïD>ÁßIÄÆ9ı%Wx:#lÇ„ğó²Ú½‹Æ7nÅ¼5Jwìjx/ïR „æ6Ä+zFpûñ„É	®<‡u“ûl…ğÍÌCU<¶Ñ²P—vJ<½âEFTe/òŠz/¼w‚uóÍ‹ä-U¥MÄç\Ôxˆ»óiÔÌ‹—sÉIï8ÉÄğ(<êÇƒbËÏn|$Êñ]E“RÃaŒ»6’ÈR&ôŒ[·h—xúH|Rª;û¡]@çÖ˜£§06Ûòh²>#X6"ìşCòá‚×îR$Éí½5s‡¿*ÔtäÒ`áøåø_1[¢«ëÆÏqB'™“ÉaõœBø{˜¸gÓf|)ôV£nJí^¸¼Ù‰ÕOİïLÎußk^Ò¸W+‡Ò–¾”Ò©Û«Øµµ¶¨€ÿApÊ1¢: §ÜYÍHêŞˆÒ1§å5f¼’ßÍè×˜Èš¥g›©ùKáÆü 
xRö4½ƒï£ÍŠl!ôªÒ9ò›O'ÅZ~L4‡.°…£^€FĞø!ã]ÊŸŞn³üEªiÔºÃ §Æ­Š¢->‡Ö;I]Éz^iuˆY &aíïp±Œ" `™t—¯ÃOÑ²2••+ÆÀşğwW|œejÃ{.×î§c„@œÒü¼$…>¥¨ê°÷˜ªkn<g.­whúEªE iqR§¾•NmÍº®0À«qì’"Šp€¼Š{ûAÒ©ïwä6ÖÍàƒ¦!Y€y€« Î€µ VŒ¢’×èP&`ú²nGg;ÉïÊêiµ|óP­½’±»#
ìÜUF£:p‚VŸËz…ác‘ñø\n9ùvz|¬g‡¼Üğ–ãá	ºëf˜u-5Xpoï.$Ù|N~Û½–KÅ¯ï6Ã‘İ¹9Ñríô ‚¾æ«­AÂĞ‚µ¸İ<ÆœöœzJ1Oû—¥Ø‰lhA-K³Ô\(ğÛÁ ô•'G7Š¡Æ´ü<«÷[gcØ—nñf½$rWŸ¿š+A-3Ã|J[ø7¾ç'Àuëkİ3Í<Ï†Š~º§¹RÚ_ÎÄ—Õ*¶üèCRI8ó~Ú+»)ŸP«>¢ap>W§eÌíc‰‘ 'İÙ~‹êi†´‹M/ä4*‚³·ô;S½
méÊ•ÁqµUÎèhÕ'ÁW’<s|Ô»mæ´„ÔšEÚ}JhŒçŠ ?£M?¯ÛõO ,s0"ˆF{<±ËpßG’çİ×:Ğˆµ"ÌƒÎ
@`v=ò÷¡ĞtÖÿe­ê†«ï¯WøAcŞ—ÔĞz¤T¢v¡G(Æj“3CÃuP†ÅPN@+×ÎÂMeSm¬g M2cg#Ç4A€e©ĞùäÎòô˜`ª4ÜUP¶¹\<´Ié€eV‹—ƒ=`Şï“•B›¶¥W}ã`Ğ©İ'ÊŞ$³<»ó# J%„ ¼fÇßÄZd ¡,×Å€ï/CPñPOÏ”—‰8}µ!„k’”h«úôc„˜¸ßÆª¥µÓ"„a	Ãy…1ï©`{—Ö>L9D?v©
ß–Ûƒy4w®Â­Bõ-íI¶¸„!BÉ*3…F~J Õ8€^“Ÿ…vC´taƒ(¥f­¦©¹¶¹yU±pa>Š	%ş·î
ôLnPXÒ$òYğıKƒ,­ˆN¬ì—Æ!ÚešKtå‡¼ıW&ÆKRÎÙ=ªÛ2»µAş^'Ù§…€Vn~S?»kŸÜ ¨üù 
Éä-ìæÅ­öÏ_²‘?©XádM÷üM¥tır
ùá968,ÿ²°¡(ÜYqÊ¡&ln–FB,‹E´Vß¹‹§|ÊGÓÄ%PY§¿‚‚ÃYœ¢òå‡2y—¥"2…U<•ÅDµãÀKÁµ9™gèÂk¿'>¥÷ã¸HkpA«.\PAävC#ÿx°i¼ç*|ÓŒ´U.X»jItw	ó¹Ì‡ÔãñåÎ£ˆée8”€ÿ½5›OCTÖzb8$Šïû0HĞjNúıİÔp}<Ä
ÁôÉdü›á˜¾@Ï×ş B“œk½È×¼;Éî¡yâI.ˆç@Á¿¢Ï©â×¢ÇÆ^À\ùH$@â~CT¹0/[s±±Ù¡%úòÙB¡ÿ_}#;ë6¸Öbh½´dÏvQtŸ¥Èj\ï0Ê!R8wi o3¡Ÿ»û> }Ş’ĞDNø°áW’[‹7d şÔ“B“!áÁğîŞn#Â5rò§¿sc»ÏX	èéøÜE¾g–Ó§~9eÈBÙœÀOÉ¸š-¬Tèî=ıŸd{=ïäŞ XwË¶ÎŒu)8ÈígÇì˜¦‚[»†í¹Kš”\OºŞ\ğZÅcŸ%p\”¿õt•¾†+ç÷çJ%cÃùÛÎ0â§±ÀÂg5d±°Ø°ŒûrÏèüOVº3€õ	hgòœ,+€Ù×š!­ÖŒ}¿pà|í0QòOf<fù*§b(´2'	ÖæŸ>˜NJ1°i;§Ä¹[ ÄÓN§GÃoÔTT=æö£HPLp”Z¦æÏ||ù@Àë”2ÂºgÄ….„î²(wLBTm¬Ë 1<aƒnMLrŞ£›š`@Š8OIâ*a“­à‡ÒT£t¶Zf£AÎÓëÜ|>!T»ÀBúshÕ¹^“‹ºòÉwzİgôÆß:îÙ!†`NWGğ¯iŞLšU¤¶éZÌñ§QÚã¯ıK$·¬ô°éYÌ±ñmÕ
H>ˆÕ‚ìel_’ksµH½Z<ªÃÖ4±×§\nˆ‘5…C;FŸG\Råˆ¨7 -!B¸“º8À7¡¯_p¼“«»ŞA HØ1–ıìÄ±ÉXYß{<‚Ñó ƒÛÑ„ÏH÷7l;ëcŠkPzÙ¢‡ÇãŸ·©ÅeUå·à“˜IYì‚“al5§{ª	%êuIÉü«-Ø‡‚ÿ<XµïˆÕv&g&Tî±? h—ı9@Ç°§Ô,¬š·Ô cûëæjfxêPBuK“aÜï©!-Ò~ÿ„‹ÀúÌßz)ã‡¨Ò¹,j«üI&:7mÊ~±()L«í'5ªß‰å+Î˜Ø#6¹‰%¿.@ñ“ö³Ïjs¦Ã{oYD½¿¡¾+ô~ó
_Ï8ƒ]K—m›9îYænÎ‹H½¡‰Î¸M…CªéÈO~dMÈ á©z¼O•:2¢ µ_%¸V]G®®€Æ*‡¸"ä§BÉÂ…ñÕÍÿİ›ãàívX;úlŒ/pj]¶¬MûºCóqCh&	uËÜ)Iø`¬‚¿•>
©÷U“i¥öÉ6lÙ2k2 Ø‚Ÿ7“Z@`¹¶Ûü8‚ãk®»œRŒû>%ËJJ¿ëpäÑìuÍR!màô£Ã÷Ü2,Š²<›’€g¸¡À¹ÂzÄK¥«KûVşm’îôW:ùğ"‰PZ‚v0h¨Ã 5c`XÁ[$OàVÀß¼Îlé…^¶ˆ7Å›vYxfï«AêÎj²Äh0ŸÛ˜!«v<2DkØŞZ+"ÄôßíÈ÷<ó_ÔİóêƒD˜õ¢§·(D²clîGÍıuœ}ƒ½›†çxÌ5WhƒßÇ±ßX aWYåYÈ¿….ÇøOS¾vÃÌDßì ~Uâæ#Ôà¢^½¸iá#¨­)¯åÙW0›¹íš[÷ˆd\l€3H¥	Å‚sŒMì‘İò›–«vŒ¹R,U§–õjn5Ù,ÿä3ûÅ„òúÆ@æùJÅz’*¥¡lhƒamİdä„V”H!ñd-ìP%ıÍ]kØ-âì¬¥ÍH´ZtWæ+å\nOwP…,zÿpÓDÿ¾zîæ‚¤³ 'k¨ì“œÃ	SQºÆä[5`,tÖÕrSµ`w¶`¯j”«‹Ä0‹AZÔ]Â]ù´’“yaËU=âPRóĞ”¯ŸhT®p‰·¥-K¯Ê?P#ª_	P?å¸SöĞ(€™¦RQÃ¡În¸?ø²ÛöÂ<ş`ñm6½¾—(Â¿T¦Z)…ÿòÄ¾AU%4M2
 å„šT×Õùê”Ìİ4ĞæÌIoèã Ş–	oû ›AyJ‡Íô–ZL'·‘
Áo¼b(şˆíƒ9_cvQK­ÿ‡áÅL'‰Ó#ÆF¥ì(ÁnTÆNÏ‰ÄåòU„ÔËóÓô9 ~‘£ÅE3ø~\ÌKğŸ4S‘CİkÏ¤†%ñß¶Q|7v4%EW‹‘êOƒiæÌ(rq~sÆ“ìgíz}z-éµ5ºM;ì	œM×˜ú¤}N­£ ¦ÛoÈÛæñSÂü/û.˜G1é™™XÃã™qzëp-‘?Í·¿O>$OFn³ëdQ&”]>õ/üw…H6@ı„¿ÏèK
m4%>ÆFê‘XØ“43„T;i*İn«MÑ‚ 3Îñû$Eª@Q‚j•kşu’UÓáÚ‡¡OÔ£š’ŠßÂMAÏôHP‡	$¢–­:Éò¼ÉDjÔA]‚:²¶ù•rÒ1ó$!_Q,VmR{v¼€¶p¹Ú4ÍíM,<ÎšÜC€@5ô²‰ª#(Î[±YA™ƒåÊÚ´½úmQ ÎµMÁ+Õ‘%2T	G]|ç™®àÉ®7‚_OJs ª*p¤OüZ$ËsRìãƒúÈnú+\jfƒH‡Ï&È4.æz@1k5h~’ÀETñ"·jİFñü ŞhIS›·x³ë2‰MjŒ•\ç0— Ó‡Ÿ¨ºŠg ä^w¢PÆã¼Ø™¶NÜ™:-¡³yÇñ«4máOÜUn@ŞèSX%Üpc¬‹lt>çÑNwUàP%Gòf?êõ‚9?ãaÂº¯€¹õêlŠ6Âç½úO¦” ¢\(¥–e~Æ²³°¶ÓjvtlOåiTa$ç©pÈª…ë’g00PÏ{_ãUÊ³tÅës­/¸‰z¼8ƒ×NZÎºRÅ_êğm‹8„zdhùnM4{3Ù×)F¼Õpqí ¨µÄ$M¾€Ğt/İ³ä¯µ&G|Êİˆaà$Ş)W£„bõ8¶Øg…x‚IçNõªèÿÊ¹Ä·<,t;‡Ì`Ÿã¡kŒ/-›óe›İÁ0û÷>œ¹ü­Éüå+¡¾–XÂ?¡YvHwx?´¶ [Vˆã×?ü±|U¢ŞV£/OºrŞm™ñ««„„¨?(>[,ik;¾’Õ%%AğgûÁ	ks)f&Ïç‘z¹$q}dŒÍ5s[)ÔcnÜ'ÉÉœ|Ô£•h D¤½Äa•Äi?©\HÿÒÅrüü~‡ªKÛ¦æ—:İëŒ-sµœõ”Š8â8·šMrˆ½›vŸáÓ/9šKù»‚¥³	@›6#ùËlæsÒ+4Ëª) 2ôäá AuÿG`¡`e˜Ÿ”9ÄB&Pjp°¡×İ`Ù¹·bBÏoá•îı¼5K×Tƒª®Öéª8Í_ô{$G€³,U…eÚ_lÈa>ºV®œ¶¨‰W+û
±¾û04ìz7ÍOq7NFØ9œÿÖïzUHÖË˜OŞû|:à)òÓš‡Tşe5mo=bŠŸxØq§ßùØº=ëãµSö·T¾èéTBÖ07 –9Hÿ*Ø¢—š¥Â~—èºÕÙ9Ğ¡‹æ[Ê˜3N_ÖOØ‹bQR4ú÷èrkf”õË;ıÆÄ++ïŸæ.ü@RT™Ê~ê›¸ìüµYói+ÆrH=cÉ4$ûé_fC_C[(HÁá‰¾†t´
›1€–¡eiV4¯Qëo06~X]Ê%.¼ê‘mÁ`5hÃ¹Ïú¿‡éÍáGòÇùı²Ä‘Ó%~™wx&¸ö¥P{ÕŸÓŒ¥¨ÅGô¿
˜<&£ƒÚÓÚR»§íÄ´)¼¬+Õt’~4\üÄ|µ»jôyÙÎ?te½´­‚¼”f½ı
”¦F&ÆMç	l?KÁ@l’²àš.Ø*”:ˆbP×–dÙîşt:#›K# ?Án×<‰9î.ô,™ŞŠ’¶Ş™ì_Ó
æáV¢»ş`„¿‡gy-µÍÒ¨Ÿ9øjØ¤£H±ëİÿD¦w#å®UOVaBC=öUƒï¨iî’éhƒiéÌùJ<JƒÊó¤Œæ³…qfÈ"˜ƒÌ¯R€"ÁŠ3“µ¦|báa‡¡QG@1©ÂUy³şŸÛ+ú¾X+{Ä:Vğ—Ñ´N…Të=¨ğûq°šÌÑ0•zM›])=¢z¹FY„#K§s)#§Zû×TÓš	Å´ÕştmÂ© ı “PßÙP/n˜­X¨;:Q!‚()ÇsÆGRÖåmRûûGŞÒz	´<Wu|CVÖ[®"†nláNGş‡=(°Ï†”‘ÔJÿr‹¦XXÿ0Iã^œZ¿úéN„#b«¡k°Hná›–®º[ÿZÂsj·¤˜éAzoŞàl	k!‘¡;àö5aL­Èƒ ÁÒ™˜æ°ëŞõÄ!İAÜ°¼åô·«s~ú'%ÀNØã¢M¢Â rØ¼­‰!2œË7"š¨òªFn§5Z&J¾…ŒOš•tôE‘À×¬(×(Ùô¸¾&¶ìÏR
¿Õ¿öğ Á•ı ø“ {¶L¾u÷Ç—Tÿ‚Ü‚õ¡ıú±‹¿^™Š:ÿ:ÊœNd¢¬†&€M¦‰(Ktıs§y€Ø4Ó€­¦ÁÀïõªK£Oê/©@Ã²IË=hC‚3µq±HÎ¾ÚCC?î‡Eí„Q¹ßåSÓÎxRmûñ¥w¯¼IB¡?WR§!qÂû–Y²öcÔ¯Ÿ¼OAŞqc‡,„µ!Íj; _±£dd¥Z†jüx-§n{lÖÎ1-gN›İS…s÷Å÷…»¯šÌ+«Ä2œ9÷'Ò;·TöÏ¹û5Wgë/ùfúMêß¦°M6¤áO#¶×Ñ±Â#=ªXè¯8Ãà£_@X¡mºƒŒ‹õ+¾ 1R§¶¯?pğ.Ğ[ÖPb‘î”§á^éÃ	øÄ>Ü|~ïÕØÀSV÷¨C’¢ÂÛl®·ÌÿVmâ$ ©ÕÍöeayÂÖEÃ,òXs‚	¤-Iµ¾VŞŞVıÈ]¼‰,*½¨tk)”ä?  ¼.x“î4ó\¢<.Ò‰~ÙôR>#—çn:¾×ıQwù÷¬k* Óóf¯ï±3%C—ŠRªRw~Ö6jE…}„£¸¨-°ël\d÷‡Z?·Öfòåå§pH`ş3‚ä\EVó¸'Fo9Í®zvŠ‚NÂ’‡n}ãÃFi3¸ö¤ıkÁ«bæ.¶õÎâì.Wí³_¤n	p"TãhÈs;^ßrmû|èğˆ»s:T…ÿµÆ#½?{K=Ô3
TÊÓ+Åià?%;MëÛ’¬Š«•†«JÜı¬Û®áÀp{¸Øh Pıìáê$^†™[ ĞIĞóñ-tDhšmüiw£²°Fû‰Wëİ¡jNô¢2Ç)QLà´dÔ$ìmyr1Ù_F¯©(ñ,D¹ã‰~·èxCĞÕ 1¥z6ïåş©$|ï1?vKo«¡Â 8‘«+.ØxJ5y>*¯0 :›uS”¯‹'1ÿ‰`ƒG‡°Û£!Rï±Äh8OUÀã÷“V}Õ}Oï£‡£‹gñ­«0ÖÆWb‚âØo(·Ì¦a€(ûÖçv"lEWÄ­ÿ LºÂ	f‰ïE‹$€çÈÏ¸Ğëi¨é, m‚)rç1j¬ïÕWI0Îış`Miôª/ñà´zôÑh-,ãÅÅê·Ğ:Jô9–wÃœÛŞÊˆ«¨¡’]Ô?ŸJÿO}sÀ"¥:# 4ª˜šà™”oŸ´
³ÕÌ…8½‘×şHÍ•±¹Á³~ÅÉÌfs†°÷eN wzqŞúxoÖ¥2º WÓÈ¹¨õê{b×°ÜÉEß,2$Y5£À8Å-=íÏfÖ¿ş­`"$µY
_âU> VlŞª¬VÀ‘j*7ÅG˜„U ÉÁ½ö~J[O2pËTG\k8	›8"ªKåZíOêÙjÅ†â¦o‹¿!™ÅÍ…ËçÙm1öBo¦oÊ^EíÉÍ¹¯<N6Yq>4—2A¼çv‚ÍÓÚô)ë'ÿ61è(íûŞÍÌ+µ#7€>•…d8/&ò–¦*U£š@+¦KùV¹&ß¾ÌÓ¼±ÁQîŞHİü~ÄjŒ¥¾êVÛp8ÜWWY‡ÿcÔÍ².ãÃ$*ÁhÍs<}L=äŞïŠŒû]ÂÎ¬ô£ş¦çÎnnL.®‘œâ/ß[ß»)qjIÇ‘V¹ëæ\6C¿‰½6ÎØÍ8œ]Xöšè®ÏPôDà^öè‚6Q´2&#í^­ÁûUXåä9äâVF!iMfFo„Šêà§˜MÎ)“Ã?—Ñ¼ÿÌ9’ò®¸ş5†:ÊMVänsÆŞ;N]2Ñ£˜úû$¤^Mªã¼YÃö[¼,Ë…—‘] ¨K÷0¥Vî%VY!µ !
¬®6òCñÇRsğDärI1C²¢hIÕUÃRœºş2ñ„;›â~–ù#vX«jıF•o¸ñ^2!ßcÒ²,ƒİ™—TQöõİ«,÷ckêìŞ	j#Ëš,KkÃÆ½Mƒ½Ûƒ(íŸõÓšâü–ó³‰{YU•£FÇŞA iAX@«bSË§h~—¬@HÚ<wÔ±|=ën:¬Ø4“´nw<¬8=şÛ”‹æÏ+ÓÏ©Ö CÍ5]ipg­wê?ï%—üÌkWyñ7[o~Bã„’ò-Òúa›¿FÓTÒ,eeÿŸ¬(~¥ºWk>MöcJâÚ"e^/À™}z~×_àÅá«IŸUîûåøÁéş‰*|WV£fåöëÈ[÷¿ó'Û8É•62€WÈBä FÖö§Ze%íVÊ¼³	Ñ!^ún½*ƒw!Df¿\A;¹CU!yTşÉhÅ÷ş%®A•VGÔ²s—,êQì ğ¢°³şí¶<å¬ÿa£Ï¶=˜ş¤fİt¨o.ùÌŸïæLa¬è³Â¯ÃÁ·,Í‹}ÚÕk"~=7BÜgÇNWÔruU+	*_I< ¨Wûêğ@s¶¢Co°n`Š?Ù©Šïz»94ôèñ÷EÒá˜¢„Nt¥ŒÂ¨ÆvŸdG‹\•“Şáã(K'×ğ5UŒÊ4´•ÓĞ_‚8ÛWÕhp<€Û[|:!ou8íuóÌ¼e‚Vé	ïGm†~iAÛ2Ôä-¶ïÏ?¬Hí¯–é_Œ±¹~1wÖè¡©&D&1c<Ş^%Ğûã‹åõ˜à&çœí»u(
îà®}ôR„ŠÅŸkšR4[BÈÃ:E¶}Ü9Yÿ[õ‰¬À{!öÍ+æT6DX8PzüŞï\ù2M0VoÃkAÆÓŒå¤İ<¦è$'8c§×Mj{dhøCğ,W‡»JLx?Êì{È„JçÅ—9Õ"ÔV¢à Oìe"ô`òª¡fE‡fĞ#´	%uÊ]U4‘ şõ®ÜHÊ£m!@GÁ)Zä!Ô‹â Ç9¡Ôf³æ=tE3Èu¿7©Ü‚=Ï“× ÿğ1—ğ4Ğãí>³À¢ş&EqOŠXÚÑIjÄ­	v‹O!}³€]s€«ºcD¦¹èË›¢pA×9$@ì×à—qÜR}†5İõ¯*|ÙÚjõŒx|æWJ¥ğã2dş¤ò\®¿Û±¡Áä3dCÇÊîı`UÑ‡thÜ¾ÀÌûş¥øeaóÉÆ4ş^"C±F9ä¼l¥qÜşh±¿Ö¹z4 åÑñQ :“ö)k‚ÓO1‘9Q8Z#^ôùëâµ‡] q6@•Ù›rÈ÷ŸšyÖ…Öø™ß{©Õ$¯¸Ôc |“§zÏ‰Z<‘Áã7¸À÷~–Q®pv_²Záİ¬Xº¤ÙC.}ïÙ”y±6–íˆC¢¹2{`º4N¬"ÜÊŠZÖ·,“:j¶Ù{¨¿I'ø‚ÆBj¶_Dï§rú4Ğ\u	DÉc‚bœ_¿¯áº{Ïæ·é¼=¥[¡²ëv‰›yŞ`À>ûc>‡%Ô­
n×ÈöÓòîÅ¦"ûŠ$ÃKLK“ËeaÂ(å²BAY¢5ÖBÿğ6¯>¯~¦EŸyS‹eaÖS?¼d&é™4P¬…ª·Ï¤M¬(µõ¨ÅGy‰Ã„ú‰=}Œâ„/ªi*"ş9A:,l“>:PxüpŸG½Ù(–ÇĞ*+KH üZÁç€1c¹ZÏsònr¬š0=‡2á¡½&ÈË
·@À•îf²;€9
.«>¸©şÛ‚qu!ù¡O'yQ”eÁ4b"õ!•ºràcú‘|¨ÜÚ#A sÉªW]ÂÁ„Éç–@ä¬üìFRÁ-%-ÄÂ¬"#Î ÑB_
»•í¿ò{è¨ E<t’à“ëg3.q44ÄOÌ Õ‹ğ·ü¯c ‹ÃmêY€˜\gƒø3 óSá–ş!˜­ÙTC¹ÀÍ¨ÄKZ[Ú½iÕ"Ù<-éò:êMjïŸÌ~>Ä8LC$®!W«bê†v—@ŞÍ Ëä¯å³ñ—*ıoómä°WWD#©)òŠA%`0Á¾ ¨GŞßb{Næ;iq6í¨v!«”sÜ@Ã
×‡!§5w½±úãÌ÷†ä<x}m¸ÌM?«2òõgÚ©»”ÉS“,¦OJ8è¸ª¡Xf¾b|öu©¡êãH(ª0Ì—|}ì9Q%0ìù—hŠ\biëH4’æ‚Á¼9ašëÄü›'ã¿´ A7Ûp($»aP`A¦¬6¡ÃÖ¥NBÏÕ'`Å÷h1í&±æı›r]"	° ¿ û´ãj¯›¥…˜vÎ±ÁëÆRJov„.ÕõN ÆÉ©{´“æË5ª@Ñ3wÃÎ‚‹£|ÿ…ÏÅS>ƒhëYA=<‘$ê]Ï0õ[>·ßõz‡ËY:ş¯qjÍcÕ¼¡Tl«> »’M]õB7Â0š!¿© œ‰´\ó- ¿3äºÚ5°L—NüPb,Y’^-ñàÀMè ?¿_6>È’©ˆö‹¢]Üè•'1G‚¸>ilJL… ¨A¾ÛiË#”ß8eTÉ¤ºhğiTQ™ıÿs áeAxHş÷ëuYN=cFKQHóhª<„sÃ:1Î-ÚK„’h6ÏL>ƒ'ÏtÀB‰zwH‘¤Ô‘Æñ}vø&yšŠÏLlzäVV¶CQ‚p–±†uø©¼¢h¹o¹z)®!$“¨Úç§ˆ?[ÄÍW©¬·@´ÉàG	Vêšš2™ºXŒºÈ¼Øu[N1ßôFâNA©“.ÙM×p·òC‘;!)öEâm »'Ó€Íœ[Úƒ?ˆßZ2-à.ÒRwK½=íVgß@êÛÿËDÌã¼saoP’¡-mŞ—¸§Í‹¼cX¸·²-O‹jEà3İE”Ë1ô®WÈÜ/_N({Jo&X:hbİÁ¸ßSıcG50A¶5'¤Í)ï¬—£…öÙoPÈQ8T!é$:b˜Û9h¡¿’¼iX€=I]ŞÀû>î¡ÿ'(ÌMÊ0`#¨01\|>e
éèf¤›0ÆÀ¹ˆMn¨ÀS¡p¬½sOÎ”4•˜ÖS‡Œ[Ãqy»xîÑõ²‡˜¹ul¹9rS‹S#‹_5a n+ü'+#x…Äo™ãğŒÓ¶Àl#´Æ=LUî¬i:ëº
ù›Øµ}RÈÎ* ¼=y×pkGØ»ü'±¸¿°ˆ	QÅ3glÕÀH6»ÕR>.­/¿Ó•Â×‘´o¢EÈŠ[±tÇ+Ûàê‘›:FîNƒ&–€ğ‘üŸô«dÃ?%§ÅÍV(Oğ^Ë2á%®¡,HK%‡£N"\òİR‡ç[4Y­h‡lô»q¿„`±{¯%İš¯5o’^û!åş—Ca¡óõÌğfŸ~°—Õ$:åênGî}ğÔn‚Vç©ß}b·Ãô³y¡q$İšÓpİ<åXaÈaÉ¤¶£yÇ¬´20SñåÖ}­¨˜Ftèï9WóÂÙ1D­İÓg±Ë§áóÇÄÑÚ1TsK”˜2¼Õ$V“×|…X^A7YÆ¸àe¿ !·ıÚDÜù@cÛ³!#–ÊN‘zÒG^–`M]n•½6-<‰e©ÛB½´l9Q	Ú4îü·0—fšŞƒşüIqç‘‰¦CÌ`?Ã¯NÏİÄƒx3è›Rzxbä
«İX-™*/ñª.E‘g†Øò„åİâøLhJˆ&Úšº»A(å-±,a´¦¶g¿ÉõÔ)fF‰ª^4³å¿ÓãtÕ'ñåÿÅ–Kp_®,±±“òâÿÆ€éOKØ
t+§aEš¢)~âæĞŒx
C†ë	µ‹Ö¨´M?hn¹÷ÌÚø
ôæÆ‘R|ÕlK$Dõ9‘„z|®ä!f<9 ;§Ü|üåKy|?~İnŸÿëë[	üš‚D@Ï»¸c"•áä›ä1°Œdò£>´mÔÌËìÌ*¥#”ƒuü\±ÉT×ñ_èò¢i²XÜG0Pn?;j«ù¡>İ¸#£#Î\G mâ3Ç)(ß}"AS	è ĞÕK&ì„ÄéY‘.ëZ™2síÁOÍ%§U:Ä¹osX€àÃÏ3H£ˆö­U#JŸŠtÃİUÏI¶Mpet¶z•¶…s–vÈEÕâapºüŠ“[u2CHÉÏ0/ÖŒ•êÜ¶òÒ\@S‡ÔÍÑ”³¦ãpƒ†êC\Í{m»ºª?çj	.”…d¹éÃ7
¥t†RoÂ¯%F'"bYª]ùvÌÇ…”’^*7e&3°‰Ù¹¦è´¥Æ€iàù
şÅ˜û`ìbPá¾ª¨N¶uUº£}A¡³Ç-Ñ•V¿Œ^6 ‚Í³¤Ç~<’¸G*ö@?i+Ko”ÍÊfÑ‰b ê"DO»Lj=÷+º‹>Îå9yÑ“v–D»•Ì¸*jŒôëÔyFM=ÿ<ö• ´.ÎÔœ¾€H¨ûF&ü¯wbÁå©O6¼íõhûJ‚Ù¡+Îa¼	İÜ4¤N~'ÚÕy5ÜL°48;âN“ŠÍ¡ ™ˆ©ÕİP])ğ øª˜S1º¾GÇ8,½2Né×¢«Ğ8+¶jK»P½|EÇÄßàîPì˜¨zŞ*€a0—¯³Ç3ÑÔ'gDÂyÆY     U§–k¯®î É£€ğŠFcf±Ägû    YZ