#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="38061698"
MD5="e12c3786ddf0aa3e8ab27a7f52189088"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23332"
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
	echo Date of packaging: Wed Jul 28 04:24:38 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿZä] ¼}•À1Dd]‡Á›PætİD÷¹ø h¤£3&r_BMR‘ÏRÏšaĞÖi
3³¼²‡9Ûë+e(¢R×	˜t!Ú`îšyáí#g|Ìù—x%;+¹¶³Tï©†ËkÜÖŒ|ğ3>)µ÷Ào°è‹cRşí¯`·RB¾‘Ez¨{LÕ†VN¤¾|•“?½ë§¥Qhx  øfæøö iìü¯$e‰ Mö1À,Eµ;^ŒšçÉvy,ägĞ
crsÉÕ…oêa!…ĞÍ™PrvñM¤=ÀjÙ&Ïk-?rãY“áÍ©ûF?¾óù¦T&ut·' '>Úè4Ò
ŒÆ¬7ñóhL+¦5æ/+TI±ÆeÉ²:¸³¸ôŠ¤=\bRÿ¥	!Es©9’µÎ/ŞúeëâÃ«ÿ@o¾?%‚;Fm*h)¼tS÷¬‡@lëØÂGÍ@»8XI)$µÅ)~0i·<•3‰*ĞÂÛ…4Æ!Hƒöcr»fu†¯ô^6jh{üóès¹¬Ñ·7”Ç(1Oªá¹}¦´éØË saQ¨Üê71Œ¯I­»b—gZ5e‰ÖÛÑ–irp^~Ø³CKVHÔyîÉŞíZ3 ª˜Iét­Ú©ù8ªúùú¸Ï€JR¥Îğl7"_pM“êUÓÙa¤ÀÄæH€	Mævµ±g+Fuoú_5 à<gA!¥ÓzÖ-3½üÜÍÔ…Ú'ì‹®ŠŒAÛ÷‘Ã!¹HB©6ı‡nNyşânÍY¬™:£À›0]‘ê†Ü0i­ÎO›–@÷c%äV@ˆÎ;Âßÿ#…+‰’öÒ-°éû¡ò*dà2ÛÆºâÊŞ—Æt6—¨oÿ*t±'»ÆŞ"ØÎ—‘ñŸtƒéxõut#[15Ú’}ufE¹
~*:!!µvXH˜ˆÉbh•îOÑïitì±lqÙZq½¦îS]D ”·ÂÀÁ†pJ÷ÈÎ3r¢J64Œ˜9oíµHØsYVn2M#xëB“"ôÂğß&	6XÓÌ4p¦ ÓT£yu
$Òe,ÆÂ×¡d]À$G
èŞø#Á²üW§Ëf]áŞ“oüô/¤€N6»<;ŒOë"Aq§&÷¦‹:‘§³Ñr´b¯j‚G¾»ÌÚ‚I$;“ŞRg]@2'÷®»é"¼;”¤Qn+²ÆïË•šœ@8V“dõë0R‹\[éI8Hcû³á6~ÊÁ6¤ºÑ1W/Cj~€u/×Ş\™¨šı¬)ıf—ğwg)ÿ¾s6ßÆ°®‘uİB£Òô.ky»ÄA¹ãzxršÂ¸š¶jâB»ğïw(æˆ–y©`~	pë­¦zåÏjÆŠ(ˆ· ¬Ä¶à(†BMç‡|üa|[)š‰¢À¡'.Ù|Š»õ®ge½Ó¯·i…ªg|ÑŒø¦Ä
¶¹R‡Âƒr¤o4‰pÔ³;Jãi÷ölËšxÉ¸1Øıêïµ!_í²Œr5;•´ÍÓÈ±Cõe{­ß …|†f0„ÅÆªF§¥Ë‘™½œÛŸ[L~Í	+d£~ŞÈ‘š²©Cgèp1…˜s=ì¿;!¯Ç‘~ùpxğXµ2Áú˜éê~[”‚R¢A}$‚k²‰÷kyÇ‡ûb}s3½1¯€Œ¶ÜíùjõÅ’³!àîJ´fŞê¤ğz +è;ÈùV¡dí„ĞĞFÅ€KX£cğ9™6eºGáAÀÉÄD˜¥Z&3¥QxŞO~.'ØÁÚzZyS¢¼î¶ğêèn:¿ÜîLƒß¤tpÈ1jøDÂ‘ºç:kgMtÖ­Ñ%;ñÀÀ1ãêô|›tqŸ%ÇœAOX (Å.pîŒâd³§ÚºûQÀÜQü”èÕLÆNV>:œÒş‡d(|‘ËxŸßéÄıV¾­0j/“f?®6›Øf˜êç˜v•Òd«<¹	z,Â›HQ=òúEwÂ?Ÿoô@-æ˜‰Y—ßRä£í²Oşí…º”ÁÃ–ÎÅ°GòœSjj}Ğ÷Õ´û¾;ÜKg’ÍĞ… îúß$õOy>­ 6‹d1pñ>Ï”Œ?qdew¿YsPiGeıñ1äİê”ÊÈñXéQc’äéêQ£JŒvôş‰SÉé1ƒ‰¤Õ:9FÏõŸÉÖ#ª´Ş$Ä«Ò&ÖÄ’…n@YIá-è0%àZ€,šÆßsìİë&ÀBmÃTõôˆÉWãVµâ¸d™AS×ÇP“'˜GŒ(áfD•³ËŸÎ8Êòiİìv
“ F@Õ`OoÚ\ÆEß Ú…åéÖ>8!Rg4…C=â?&HËí­~ıŠL öŒ}ÊMª…¶‹‹¶˜õóÁ«1òô.‹m“ä)âËpUËÏ˜÷,À¯ £×°ºp	À»]kXÑ­|×_´O^êöƒ¥İ6XiÙúC¸÷-Nr
Ÿ-°¯®˜eë]¹â0(î"ş4G7æ¼L`¨Y!x&µYˆ±•ß7ë
­íµxŒİ]İ	æc¿´£¬^²}PZf£X €Ö[s*uÂ\4ÃŒ¼i!µ,Ô™c\;añj}.…ß*öSS—-ß9ÙÚš³ Sgl)‚y($$–i3×jùÂpCN÷±c?¢‰)ğ|B{ø¹¦ ·†ˆ*€Gº´xH´õZûp=B»:%O«ñğuªClUàz°"õA®iÒ¦Æ€Ìk:z@&òBpàéİğIf›uåêV-Â’°ëÂü·ÜƒÚ‚¥c=kDP’E=§™UEìfk-ø¨©0Š%œˆÍÀOôÉE»²h”ª{%¦Ñ å._¾zB–Ö0T\ù^¦±íŞÇfñ60²;	î":(‚àŒº¾UØŸµìø`Jô·ŸŸ“Q(ÒÉ-ñ¸I@o²"dˆ°Âë¾‡W	„`I«k˜L8ûRœNª'jó0äÒø @«dpML±pÅ»ùır¢cÔ"İ‡‘Èy±ã„+œGµ°îLR‚ä3¥;(€Êaúü8ÓÁ]ü%mÿ°òäu4"¬Ñ7[`uù,tä
›áã¬<M"5M”qqã†ÑÉ3Uæ•‰Ì§•éİ4ì½ÜÁ˜;|–ğÚ‡U€¸KÌ’ó>1Ü‘öo‘Ûü©NæŸªé¯ù‹œã}”IT¸eÉ,â&o6¸m5+9Wp³í„BCˆüü?C÷éç¸U¹rÒg1CÇéXœdãNwUèn¬¢Cdù{8½P4JØî—ƒëÜˆëİOeŒËıÙG’2‡Ä³sxı
FxV‚eUÃ¡‰Ä‘mÆ>4À½6ÉçäeØªíM3êú©µıİ˜©ã2«5–#ùc2vÁdßí•­DŞA­¹Öƒ'×Ä±´Eë‘±¸éG%>—‘P1óÑ]­n¶qíÕx“v´)˜Ğ#Í‘\•Ë»Ã>xQ‘ÊXQÖ¯;j¤ÁÉ–
2…JÔKF›ÛşSíÖe§*kÆ«o¤.áÙÄì•áO¼Å_Š1S=Tµx¢T‘Í¨ë¶X40»ïD†Øä—Ğgì­Ì† Gs©ıhIô¤âX-J$îb›¦\Ä"êŞk¼uÅ$»
şÿyæ
;º³¢ ØB‹ÌXÏæp 6Aƒ¯Ï*ßm\™ƒ\L,‡ûÍs‡µûP1’¸Ø²®ğé¶£? G¹‚>]3ho˜“6{ò Ä;¥“¾`;rjÈhqÃæp¾nÁúçS±9ãE¹tÖŠ/•òÅ‡\‡ñ¨\ğÆ—,ş6b)D\Bç,Zıºëeù7Xv¢0yÆµF/˜7FI+Ún³™éÎÎï %!4ó €Æ×\‹c÷NNêSÖ¹™=İÛA¼ÔqpÜy›òã¡¯0PãMº¼M§Õãq=ˆS{l Õ®½‚ÌéôšÈŞß|¸uæ­°	Ùß@Ò¤ßÇ³ Ó;¡¥dY)zu€öwºÕğH4Wkªñ‡ŒÜ²¾=:@3sğ˜õræöï7!M vBO­êd<ÜjEÂ4\¬TêßævoäÏ6>X#æˆS5Ià§a`Ó=Š›!øÒÚŞÕG…_¬ÄW <[3
‹IOIs[1pVÀb”˜ÓÄ'Ç©Š3Z¼Lq£`†¤é;\<«›õÎ…İ¨Å8
¦–Å•_½lLªr;/ğ;Y.}…3DXJ'şPš#öAòÆ×1¥Ù©I`§öÁ^…n5øsÛJ¾Û¶3á/pŞ=2äzœŞDµÌ	àBF”9Õ ;ß¦”QÀÑù?|/.¯ƒS’¾Êm,éõ)ÙØµJåÈ+Ü•+&ŞqÀf’—3d%Sx¨èĞÀŒ	mÅL‚,ió2Aşô„ıœÙ^‚’ÅªxÁò]¼‡ıAŞÏDs8¨f@ëú&˜h±—lC:ÀœzŒ1yCBh¨½ÿ»êK?'"ûœC¥jœë’P6(øÈêÍ(ŠLù–cÇêÀYBû3EäVOŸ1}yS@ç«±p`ºà1‡Å?e€j¢öşˆ¢<$ó{ã•¢=|\üÀ7‘¿U=ÂÑ„e±8YoçãZ$ñU £ÖñYÂús´Nó˜pGä"a*¨Ø›ÎÓ/FİjÒgi¸nöM
Uõ–!	®A»nß§-L%Æëo_ŒV6èïsØ(·ÎŸ Ø×^KÖ ê$úæ«áa9«$­ Ø9H½õ7>ìÇ¦Áyì§£\8ëkRúçÒ 5'7òPg°èÔg‘gÊ[›¨õ80¼2ª	ª(rq/eã`(7Û½‹AÅ¹•ÆŒæJÚ$ïtQ9ínÌbqb$ÊOc FRÆ!çh:Åëú#×¶[&İÕb‰¦§i§;¹‘Ò¹ªÛè˜LE-ÉñÜ$’Ã>‡ğä˜Tº>UK¥Kê\A£ôZÓŞOíy(-õ_8a¥¹0ĞHKİMI²®bû<}¢P‰9>¸G
šÑôĞì;%5 Ÿ^x¶ö9½Ï°w¦âŞs3„ãèIÜ·»¢S·[»- iÅµ¬]¿ÌàûC—’}¿L=c‹çg7IO£bŒšay'ŸSúø°›à‚8a}$Éîg1J²Rxõ¨-_‚hi€XBêü~K'H³GDQ«8Ü™ê²O{k¼ëc—ÇÁFh£ÿ¾C>A£c&6EòÓz'6ap(V¨Ík=İÖ³“PS#-.ßùß9^•<ÇŠ3€½îMü_CÌ]ö£VÊ¢4Wåõ#Zb­>SêÇ Àâ‘™úxë½T¤ê¯Ò£æJwˆuöI<•—C;ª+hú“³ÓİDhqDOiÎbõÈ˜—µÔaXv†Ç+Ê1úû½ıÍa›ğÌMàAï°Æ«¦Á‚µZcû"gèÿviŒ¨—õô¤–dQ“b€_ôŞk§·½µ¹?GT)!Ù½ª ‘lğk»•„.S¥ çÜ{pw£Â0ÒE`¨ñÖÒæüëíW«*0¶¨6ğ+¾Í™ÕÈ„ ô€£Ïşôè‰•4#ÿ¾*É
÷m#à­vÃVîuõ-¿“ÛÁ³©İ¦PX|WÍœìÑ§ü‚dvCpÌEKh’F¸£ÚV2gl1í®áêıIB‚IÎH(iŸÊÒ¿ÙğZ‘‚Jóğ
l¦m­E¥:&:[ç÷,-u?úüö…)uâ$nÖ&
7•\ÔæÁáŞ®WXıùBÔ¿¡Ea»‚#ºb¿Áı¡eÄEõ0€Ó	¶ ğ0OpŒÓêÚÈŸ`­Ôów¸Ìï‰“%˜’?fCá»—ô‚Ëh‹}õ¿hâ€êŒ‡ä]~P>8òêdº"#ïŒp¡è­2Ñ¶éˆ´±°˜…I±ıÌ¡<î¶×¬‹²VMf€KŒ†›Ôî0@†[[µqmÃ¡SS”2"	R¿ìÍ”Òøš‡ûHE3Ö R3ÈSq
¤+_wfªù<ü	ÚÕ´Çx².!ê»œÂÜ¥ë[·¶YÌG}öîç–ecüg•n§‰­^r/·ÅÇµ]‚”fé>Ü´U…r‡ÒBîŠkœM¾“Pe©¾F?jóu¸´¹\èYMÍòŞx	³eğ
L>²5J’K]pl²–íEàıÇJWØÚm"VŞÖ=Ñ:)dÓ·m:¹Ø;G7vd<¬ñZ*ö¸Öã Ø$‡ãÛÈà¥ŸàîÇúQß¥ï‘âÈeÇ‰CÕ¦s˜ ÷ïcä;=é¨n&Æ÷ÍgOú5±7*6D¶ˆÙ!•/«¶Ÿßˆ©•Ş!í¸Ù¥Òúl/Q[zÏ,Ô¶e4Ï˜‹Ÿ‡5ExßÆâÄ›­½M­Á·ßÈß)wÔ³óºÖ+eğ£ÖÉ™tšTlã»Ğu:ÊÍÊWAwKèòù€Ó Æ¾Ñš#u+ÿ¤o%§ß‡¿ø•`…f&Š¤¾ùx¢°Æ¯®UçNe`W İRß½ÍZ6&æ“ôdµçÛÇ¿†øù;(I‘,fØÌ1^@®¬÷iò´½úÅ|q½‰ıPË½èlìT–-où¸­ñeDïJã¨Ğy-•ˆ©·ğ£8ƒÄ1!]B_İáê^TZ@‹9>l8Oj“jcvŸ…Ì÷&’HşÖ‰å,+ÿ+™Z*`ƒä=G8Â—eìı‰(ò½ÌÓu,$lÙËl?úEµé“h$Ğ—¤+‹M©4³l½şì9ÓÙëYhÑ[ŞêŸT2aôY·@QõÑÌÇ16ÁÚÙ[á—lj}IÀ’â;MDP+ÔiJ+i˜D»–E0]!R­Ëüeñ9·Ö	6MPN|ÈdŸ\cÍr ş‹‘sÍÌ]Ú’¾Ù¢É¾V3åêåæ¦lËC¢òHR-aêC’°_hå€øõ Ö5\TÊêş7	Hæ*ñÅĞ°­›nê¤ÏıÿïŒíÁ°°À‚^‹@¸jFa,FÃ¬>¶O¬gù;[ÓãyÄÒ†úbí·M ÒNÓÿ5ü }q•É˜°yŸÍ"[ŠfA,EYTK ñjY¸·:›Wf¶tùL+¥mÖÆÁ™ò)™`àîÛ1¹âÿTÅtÈJ±µk¡QTu
i!,Øs<©Xpõe_1¹ßSg
İcz¡.ôhjTJD¹ØÇök_î¨ ²¼z–£ğ¿-¾àà:yz«µ¨ˆ	–I4o½]@i±!·Ñ*Id~Ö¬º¥šNÀ>iŒ¶%Àrå¬Y+ODø`––?TtÄ·ÓcÙÕGIÆVY¦:¾ˆ¼è_8½¹%VÂ_?Qg4Â¶,V_ĞÙNùA+Ïëô˜.È¬+$5ñÚó‰Ü:³hbˆĞ¼ÓïiÙ¢BÂ¬*|LPàP]&–KœùoGšÇ¥ ¤CÏ½ëd ÌqÁŞ!¢:¿…lª’/aŒ‡§Ïà,]0ã¸z=Š‘3CQ×Ô<dÅyöÌÃÁ>ü= ‚ /ÓIòğ´p4DğBiöòVKï@Úü&=‘Ä4Œ½"¢şÀIè¡ÆÖ%øĞcDG6ØâÛş9ä-¡a¹ÛZŠ³º¼2ïïÉÁ¢¢±ÿ‰†ã}€¬ÊE‰œÙ hLÛ A?¿{ĞêÒÊØã¹¹JW%diÊ4o$LËógÉ|IG-ÕÇJüGõ®@M5ó}ªázÌy™hngëh¼É¦m2åœj·]•I×§ÑÈü­8tw¼zfIk•~îıo#í'<bœ:¹xšeÀœ%Î?ÔU”úŞzâÅèLèo›¸Ë½PĞå¬§ŠëÇMÄµ¸y-âÏ·âÏ*[ê–ihşXŸ§¥eF¸¢øİn°íèj!˜ˆG'Ş‹Á°ù$á]7-Ã¼­o¶D#²ÆGùóPõga”_y÷¥ÚX/«¸I°’ÁÿıèUµºF<'ûd OõtnŒ,dä¶‘ÀI¦Ôpí;¾Z*l`dÊ%´Qnƒe [dQÍÄª&Ll_ò½Á"Š†2{GĞû#Œ)Ğ~ÏÑ`›hÑŒQÖ)6ÉQç±#)R:-@]õ¬£x+^0×áˆIÒ+ø°¨‘iÅêÙ’FmüywŞ9ß—ÅüØË«Ú·I†8ŒÀï×uÎb˜~XÀ*Bƒ!u
÷ÇşTÙq7œ¥NsrMéï<Ïj·ÒF³q	?ŸnA—‹¨wıv£‚ĞBxŞœg£â™to‰›u¹°P‹Â˜ô^Y`ÊÚİ¼<tÎeéŠVLR«BÌ”ä=¿ñ7ddo„².“ˆ­ĞÃĞ3}C:Ğ=×WÈ ˜ß*Ü[ÙÃÊ ¡AÕ¾G!‚PhıâË¨¼A-€›üG“üc£Ã›â†n®¦êºÂl'!£de›y)×#° p9}êk•ÈêğÀgß/º½ŠÚ_”:ÿ «oû²lXT€:1+´­Áš‰E»^@"Ãê%ç{.í²µ'r¤æÉÊ%/s¹Ô±†eôğÍxÓ¾™g˜3Q¥éÖ4r›cÍMc?çGbKœ¢Í'Vø@¬‰‹·uZs×¥%°PÍÅ¯Ûi·{^ª»Ã¢˜r.’?ğMÀ[ºUÎªYÀ°±ÂŸÀp~‡y—GZá ‘%z³ºÍDsôr„Âyø³UÃ¡E¿°Y²…<æ}î-¤˜#wÁ¦)~Aåóö…ƒb•3”²JĞéÖ:†oœ‘ƒßü`Xaéø¤Ôp,”²ÒÆóİ>µ”V¨àßqx<âît….¥ŸÑoK	ğ®»c êOà~PaÿS´EI™êäßš†¹û9¡J¢ôíE°`Ô¤|ş˜âO1r İ?Œ¡ï×‚Øôµı£B‚`
]qpšeè¯"IQ3).:~Ûhw—'»–:Rëg´ìÀÕÙ%”å°FßwåƒáL00s±ƒƒk"BR„ó¯‡8Æi‚|Úæ;—|ªÃ¹¨°‡´æ†¯àpÛcsuÚ Ë{Ğ/—å7]¥C½ßh¸S¦Ğ÷à´êÉ	&_æÊÍP/ÅzŞ/d,SÙŸò¹è½‚\Ò+åÇF®,SG¾Õ‚ğÊÛMËQ>/ôè¡¸­}qŠ{ÍNë]Í›„[Ş‹-5ÚxXı>vP»#Yí§eÄ"k¨>Ä»Ì¾.0Ğî<Y³´“§CQ¸’¨ Q`ïÕöÀ³o¿WJºÆ”ë%Èt-bÚ¨^uúùVÈØM9.wÒÙâóÓ²ôçÌÏÃ|…Ñú¥ö³Æ ^–1R,h•™_…ÕÜoDAÃsÎBØ”jYÏı»¬óJâñµ_xù‘üƒ•­(%-u¡èÍtD|şJ×g3Ğ:ûKNI„`]+¦jw¶½¤F;[$UQ«j ä¼™ş‡ÆØû,»%ÚÀ/7Çï#²?»+µŸ¾oí¿Këò@ù=Ö.¤ÎóÿZ´–e´GÄX½8›oá>qÒŸï•qfÙes`¥hXÑñåK¯}[æ~Ï}"Bô€Ù™‡£«Vüí*<7Í‰°¯!EDSr©Ğøä3f‰ø|¹ÇYNĞ²"ª–R“š­b,ÜšŞ†~V©E°«572ÿåx2 ±ch‰> 8Î¢xG-KÇáfëj<áfé¹!]§’ h_ĞF İ–’_}m¯·¼—U‘7:"L„·ŞPVœx`‹¨gÿ×IãªÌ<ùÁJ¬É÷N3ıN@¹Å±}°ıƒzaj£Ë9¿ –˜ß™¶vw”ÆœS– äğ%kE‘½WìB3SXä—h˜>­ğ0C4®!­w› Uv©\¸.â4½…,î$sNÂZ®“RñƒtÔ+R*êHüÙ äÀ;¹ˆàëoKÚÏ»µ1a¢0©ã£\ª_¿!U×_.O¤ ­8a?¹ ï,ràŒ÷¬ÿWÕå\Ğªsá™,Æ·ãé|ûrû@'´ùº×ØÎŠ;Eêl•}¹ûşóìNÅ“D·h÷…¨O…5~6póa_?ù”vT#ª.s¾¹Ô¦E’dkCÌnór|‚TÕ¾×µG,¿¦‘²»Ë[w1nGD‹îA.ïÔ•N(|Ÿ‘}ş=€óİç8Ã²Å…ˆ¯Óœşè¾_Ë¡2ÛJ3{t†d#ŞLzœ òGbr¶GÚ‹Bq¨“æ˜¾Œıèv{_¯y;é	ü¿çÆMáŠ¯Åì–ĞŠ‘ç’uŠ„ûô<˜ÛoÏL–/ Î)6²>Ó€%îœ1Ò£¡„œH¡4R{uÍtce¨Ç†(Æ¼†ù7
½¬•ÚÊÌ ¡ÄÅ	?0–VÉ*LÃt
šù¯øĞ‡ğóÛÁg'-¨­O„¨é™³šeå6Ãì*n™˜‰/î,ÄöOÑZMCJX£ÃÙÇM4Ê:“ê±iÛ”¶ÌE3:6ÅÇ{İë:¬oÑ· Òğ`¡È¸;Õ{ïÏÏé'—Ü }dÌ
V§W=“eÄZ¿Êİú/pB‚2¯”»{:Iùh› [Å8e1E¦W¼Z—ş“+ùºÚ¼­àã´,á²èî°t˜§²µ5o`­ÍÎnª93^Ÿu7=\ÎñÔN1_®ªQ¼6’)æ‡hmµ½„?|3,‘%:'`(ÍÒä™™DEs­Fgš°
©ù1ÕîÑêşÿxst>{æL:¡J	GËÃ‡pß‹ŒS/€ÿ,»Æ×šxV/¾GJL[›÷•ªœ×µ=AĞmí}!¯-ñ-¢'±}Ê#ú<İ£˜ÁåX‹9zR•%WKºÙT¬¡RÔT"+¯İ;Lˆˆ¯{pM"Æï$£ØÑXÖÕ0Ó@õcÌ6‹oXä-ùC¢ÓÓ0+…Ô¬Nsm:9–æSÏ¡×UèsS÷’_ü–ÑÜaÂıÌ¥ïò¬@h+¹P|ÇÚ¦°¿ÀÙnu˜ª^á*?pâ\w\L¾®®ïOš«gñ65İØÃ8µæŸàšÆÑ‡!CÃ…u_EñgfŸ´3üòFÇz–"‹äÖi=-'Qïn©c6‚y²Z^Ä‹a_w1Æ•Â'7 šŠ]Qs8Ö`°ZW½µí7•ùùâGÈjPH±¶“ªÓĞvşS@éöû ú¢/o¢QïöœÄê”¿_d¡÷4ª–‹~®[>µzD±Ç|½_)f
ûuõL€—ETNãl'ƒå£öèğÿz×ö¸•¨~XYêµ'[S.6€`=N{ø;¨‹H¾~	´Ä`–”HÛ™Ùäb¯-â†á >µë6Â€©àÇy®·«Û:]çt†ñVc‡˜fŠ¾aÀY¢ÄìWÁN 
{K4z:M=Üäp§éŸWTl~1[F2ôÁ_ËßD§øAğÂî’xÑÚXsä&>yUIoÏheöé®ê°ÿiÌ‹û¨ˆeOLU¹¢JHöÀVÎ3oêÿğ2Œİ¸SéUb;wûH~«Ö®
[Ë¯ˆÀ6%tĞÙõÑ,ZÜòsü¼ÔwoŸÒ^Êq„BzÜ…'¨è¤,âÛ…ßû­Yhd8š{‘S|ĞÇ4’sï1/õé|ğ›´ş‰Ü§bŸĞõ!közH6cİeEpåE)®5ÏüVsUõüék»œ}÷7$³dJAª¿ÏÂ¢gÀÉ¬¾Ü:–VÀl¸®3:»œÛä\›óMÊ˜İ@˜ÏT8ï–iò ğQi9§Q*î›ºÌ°î÷«°T2« k~ Uc|¡FÑÅÀ¤l×XÒ
û œš¡·„5Ì¶]*e’± î/‹şıçËÈå<:%*ŠéKÂÿğNä×³¦ªÚìÇxİˆ`€}qÏ0òñ7ÿ•N‰Z¸ëØù-­&>ï_Œ3c7)üïW½ĞúÈ|mÅ#È¬ôr’Fî7×I…KGrb@éi$Á;Ñ•gØª£ËEûUCµ%UdiÔ"²\?‹”Z‘œ™k 8$BI-Üÿbª¸o¶Ü–ˆÙ­#’[ö'^[ÉŒ'x*ÁUoÈèúçàò6ì¾+'cÇ•Ğ¥P•É`¿øŠN™¤«²¿-¥A­ó¶:F“J4İ}=kr•„Ôóê,Ì¨w²²I¬í;ÁPAéê6{­¢à$SR•{ Ú›)L(´ˆn~÷İ_}è¬ğzæŠ²‰
í©*b›N4È@]bPâ[%‘ÔÎËÏŞzÇØ~©¦GùŒŠËï£œ‚vÒĞşóô6æ­¸ÊŒ®ua·ßZ‹õÒ—~)œ­ów€^^Á÷·)ÌGŠ*‹Sû¸­Kô!‹™)§òÖA\NÀ¾Ğ  RÜÁQYŠ–9¢’RµäK)±‘J„ÌµáÂø¯¾ã%â‹Oà-tª]¨’*DãİÄf¡¼øÙjFÄœû­¥ÀÜÉÔ0G¿j`0åM›Ì%nß87näo½#¾¼yÿØ)o¡í´Â”x)›şü1ÑiÎª¤móñá'„§~Î,éà2*ıL¦¼:¿ø¤!åˆë»Æ‚Jt+:ËïÎkó§!®µMıå÷„p4Àqºœ+¼EÀ‹K2lFä®[
¬~H¹C]X}o¯¡Ç³˜Š³?…1BJ¼…¦í—ù";-/Óš$h2üüqDª¿ı©s¤cl%º5’#ZÍLïß÷s£h,â¤'ß¿g]¤ØÏ0²Ûû©O¥›@ª—N9°*~’…!Ğ9`Çà@²<j~é^7ñg›ÌÊ`ğôb³¾ö8
ÁGDaLl´á \_{jÄhJd )'XÒÙåZú`Z¿Øİ:b u›M&Ä›bÔ)ÏÏ}é~`–I©®1×²DšÉ!ÙŠo"ƒ»<¢åpÅª—7=ÑÎÛ_³ø•}Rs{eÛË?€F)z?BFé„¨ ,6k¿ˆ°0‘ï-÷0¡.ÛmºŠwÊâ¾Œ§ÓîÔËô:˜+Şéû…©#ÿöª6Û†clö®—½¶mA)I·5øoÎ"îm»( 8›I¹=è’Ù— ©TÆß?­K¨âJvÏûQ¸Ší€‘:N¸¯îÈñà?»Yá€8}‰é« ŠÆŞd½0k1ì¸æV¥ˆ(İæuÃÈÃ0ÉbËÿk­¨,ğÅ—•ÕºY‘!ÿÎ_$¹Ş³•í#…Øšh;K cTÁw&s\ Ç‹1Î$°gôvı³¿¬<äÑÙµÅğó\½òOCH¿!
x¦Îé²1¢+6iâç¶É¿ÙÚõ(
äG.Üø¾Ï×ùè„ÍTò¥]òràÊ:-œå<ı[ =WÆ¤1êbLŒ`úeŞ|M¸mÑâñ*ùˆT÷ğ½6Oşƒ›ë†hg±„ESf~ù—x·?ÀÓòÃjU~û¾„sî»ûƒpGzËl "íwè9<{Íht‡€ÖB8Ò5“vÁáV7 *1›¡Šİi‰gµ÷'&8×Ş,1}–£ßzC*gÄ?<Ğ”[¥éù’ß˜'Ë•ÍD#¬’‚½ğ•Ãà,$°é
pCô³G ¼lz•şìäÛ5#pê|aã@wëš>À††ÕàÀv8Õ÷+ŒKË4öQà`ƒ@à…Å6œ|0iœƒ‚‰iUí¥) `
¨[dæ¤V¯ğ]™¹úêX	´åœ%)k¯´«ÁÂ^†À´L/_3HÙîÉ•ÇÅÖşL#ÒWM-×0;ïO-/RKMÜÏ7Šë5£°ØÃV·u8ú9s\Ú§À¾õÀøğiÉä?rEAÔ¦¬ÎÛ‘kqVÂ•Šrâˆ(sI/=2½XãLcŠåæºÄ’‰¨3]¸_·ù>ş”UÑÖúÎ[~ä_2Tãôƒ—óİ'©ŒÔ;Y½Tÿ²EyÙ´ÄÊ¡¸Nt*PP’"€_‘!ƒ´Ş‰Ò›•Alé
‰*-³nìLA@€@ÔÖ”u;î»öS§C¯´;:Õ¥RPñ‚æH_ËÒ½õ®JBÂn¢t`hüüî2“¤š9/ğ˜Àª“ìrÕ@*%–û÷='‚È[4û¢ĞoÌØy·~óÈ®v$2PªViZ}p„ÔÔ3q>ÓØõÎœXRÇ˜§4æéP2Ôï[']÷Âú$×[
V~!)\ËÍ1óG²÷tÈÚ‰˜7€¬lüŞ¾EÈ[’è3é³p•w…!ÓÑ¡óJ$j¨PŸ±’¨Bnâ6££î1Š~~UMÆ§ûÚ0d}øjÚ£³Œ<ëš‰ AºQÕï¶Hßs¿ëò”ˆ™½)ö Zº…&‹Šˆ¬¤É¸î¡€–Ş·G¬Ñ@®&›ûÊ† É"tğ`ÿ*½iBĞE™¦š s!ë”¡ø”´­è b…ŠÂ¾Âî¼¸e5ÇGÕív>?7ùcŒÜÊç¶&w™¼Â·üÃT¸åÜß;aÉû:/ å¥"¾´W§Ï‚Ò(˜BöFÔÉ&X3«°¥¯Ì?Í¦˜³`p‡yßÆÕšÆÚ$ãx7,¾p©\v2aiŠ†:I©….RKØMy¸˜ TO†{Km,QtZ¨÷YÏw™ú½scÂÁ	€]™kAb) \±­f>Š[æ“'ÎLôıV Á*O–²ŒÒÿÌgÑÄwà7¸_hPP°“Ä¾­îîYõ½cñ–"pDqÔC2+¿Y|÷1¶€Ø·Z¿ù¢•ñfêÄ¢å,; ñT rI&³f#%š3­ğ°]_åuí4”ŸƒÌa¹ì%¾éf@GiÍfº…³‡¢Úb$üM)€ş².^ğÊ1ç­c5Ş×,Ÿ.ÈñèC×¾Aí¸‘~·.On­¶+Ô,<­
S•³ô6@|a·.T0ı§D×sú_Ü.ÖUsŠªXÀ–ÊÔ8¶4è%° ò”íÇê*X8¦z”=½–6~ëqå³OwÖ©»zu,ğ·Ë¼ïiÔjÆòÃÊm­«SëCü0³¹ïçÒÖ+·êØNNFŠìâõšÜEw	õ8§úøütâËOåY:3[e'GÏôe<ÿªÜõ1”wcÏM:§€6ƒ¶¤fÍ2:­êƒkµv,j—ä\Ù)bº\´5‡1‹¤U@M”Æø×Et½T.®vÑŸB/šmŠKøheÕâÑI²ÕŒ‰cğïmqO`aKõ¸ú8²Áp]o·…À8&¥Ÿ?yÙßùŒìF	Y²Lÿ†4
8©'ğSb^û€‚†~–v{›êş…3û@Ç×„¸eøÌ™XrôÑ`°[l~ÙÏ¥0ÌÒi7V®#¸"›C]JÛ¸W“ÔÔ&Ñ1ï
öïSqÚ‘.C<Ä _×2íÙêdöÛjÂõhÔÓ!-?"²³u•)ó¾ÈÕBC4[ûÿEk-¹N÷L/m7ŠÀ!ğø7û;ZªÑ5<§ÊA- µ…§¥Ã2<C!±g|Æ¦èùaÁƒ¡T’&I6—‚n±»;ò ¹¨Qà/ ÜÒÚèÜîYøO7ı¿êº_"_[ËÇ¢½å¥\©,gŸÙ'Âz:B‡OôŠÈ"”6
9Ê¤F2£¯ƒİªt Gkr–¯­Ü‡á³ìdgñ4ğÛ¼m¢OnoäÚd˜m>é\BÀ2Hß–AW&K³w~¬ËWe…3âÓ¹—$Õ’¡ØšÇó21,Ÿƒóç› ­§-2„„ï­È
Lª¶¥ØWD½.e¹7ÈNÄP<ãÈ§d°Kò¸ˆ£îm\msG0ïãlcÑ(!]ğ¸‘ ?¹ÒùŞF‹J®:!È¿­oô¼ğjî`{ÅgË¬óŠÖ4è¸ğü&:B€šò	$}îd Ø—½TëîP®¶e`aLÀÊ\™'³ÒoHûåR_"KW¼àGŠˆ$ês·M¼½i&Û`p]Ç`çüjºûZÍü³üyÙèÅ+Î+©Yo÷yçßöEQ‹[ÜÖË­"$Ÿ°´È"ExÌ†EBÀx³;Tô]™°mğIWÉ‚ò»¾Şg/™ó
0<³4è\­ÅÕ´QÁ´Ël‰ˆà[Zßg²¦È"’?_Cø$f®U»î€b%¾fSüš8¶|†+8õ¤…Ó	ôÕÊR²Àõ7é­ãEs<‚Ã„ÊªŠBiRÌÑx@°X»­"œÿ0Ô9ÂñR¦é.«½OK®ø!BŞK%ı"ItLû¶ì–/-ƒ1¤\ÓÄÛ#ÄbSì¶±S¾!ŒN¤•zTõ¤u+À´ÑÅÕèu a¦É¦ıxÚ¥œÒ0iÃ(bt_D«İE5iÆGu2ŸOo7ÆRw0ÎªË[^ÂKH†^½
ÁÓ\TùuVÙÂ‹>ĞÁLõ-¦¯u»1›Ù]mÎ2¹EÂœ3êÍİf!_#üô} ³V¨“è¢Âã9ºNOíÿ"Ô¹IÎĞj8,í‚äw¯–ByaB(fB#Œ‰$œ‰šP¤q¿†…49!Õ¼ç±Z)*‡"‰Gsî¸šaZÕçë|¶œôz#2ã˜ù}:p\dne_:…S-«Qr² 7º»Kì_µ½À8=…X%SÓ›²cè=€¯®2u\’XŠ9º¬h-ûã!q'_zÏ~°eø¤e9½ÅàçÉŞ¯©ßÎ8¦Õ©Ş÷.ŞÊ™Ò~ÓmÓ­>W;­'ÃĞixWGÖÌ[¢’`ğŠu (‰wEG' 1 ø—g‹H<‘d]\£æô8Ú}„áPÓ¶Üe8¡§‹@¬½ºO%æí—>ŸÊÂ¦íÄ•õúè1M†Vl¡ÄEF"í>ÔX–¬443Èùì:¥9¨¦ãÛ¶Ä?@Õ$Ó¬ßÕ\†"#ˆX5_ß,o¨Rt,ÏF}Ö—|‹9q¯g>J¶^ÒW)={0\ú‘ PÚO^¯ïÍÛ=×«¿ğ—am¶1l¹dZıİ7›ôÔ–ç÷®êœ|6k€0>´²[“c¾5Wd6 Û¿ÜñKÔ„”ædğEö/”h)°AGy¾á,¶Œ ¦·ë ¢e]¯Ò‰(•®ÌÒ{¦®’çxæòº½¶ªY_ßğí½ï^ÕÙ©`Mİ`—­­¾O€Ì®wË­‘Pœ©y“„£1/Æ»F<ÑÌ~úš›(éëù~€l%úE3**øßwß Tè¿ñÔ~‹æéƒ¿ı1ÓÚs%Uâdy.|ëã¨ÁÈè…®ˆ®ÿ­—½³x—”ƒ±ùÜ¸‘À93rÉZ*Á>8`Şq1Àî•ãòTÎ7„Ç„ôo*ÿ2h”#‚_¿5BMcVóPØ×)÷ÃtUJFÃxº„
Yå“©'I´–ª¾ıŞdh¯£‰S¢B#$=áNªW>)8f¤×=Ñ„ 37ó D¿„´Ç(ì¤VW^§ ¹ñ}cu8äâ²¤ôk“‚Ç<Zé”g{âEĞ
ÙKÃ²N!ÅE—WA¹d(«‹R2ÚŠ?öF—w¢ÃQT²£˜%*ç»'ÎS«=™wØÂØ]…^êz‡›è§‚—%—xÅ>U*kH“üÌ_¡†ˆğöÓì°ö,…É„‹şæÏvĞ[ø­Òà¬ÕÎŸa~ÃæBØ~ßKÄ1HÏ#/ â4tbÒÚ!ÈäXåZ8LõãÕºô”
ühª¢H†bÜâ§Xj]k](dÄ·äÆ®K¦ˆÙV¶İ3ëÑÿ‘À–ER><*²Ä{p†4ğzäcS.üHiÀSO°æ(5â[›ş£¾5`Ş5†T²ÜÅŠAC.rÖ§¬.yEyıÃJÄ¦úÍmä-Ôÿ ¾ãé^të¥a“cáü’À KßW®‘Í›Í0‘â¦‡œ†´µ^nÃîKÄdmP*¶“ä‚áH²Êxm½”×T·Ñ›«8¢pŠçtÑv¤\î—§ »¢Tj6:Äû|Rá2Ú|ÃÆºYÃB…@Óºwl“i_©Œ˜ÄIo^ËTŒœI¢7—MêúøâñÖ"Šu\’´Êzt}/„ÿÅ0ôà¶ƒKup  °µBMGÁ¼ÚØßº_†â1F6‚Õ@¦iDÎñHâæ#!cöú6ŞY·…TVòbŠ^è×‡ô5r ÂjB¯ûb~mâ¦òa[|ëjòÎö…Y8mas{¤‡‘:r×¼VP„>€§cTĞŸRoåš)¼……®(7ğÌònğõı’K’UP',ıÅ}ÃîÎŒ4I§¤#Ğå›ØGÏdL^V»9Ö¹ !nxSåİáà‰¢³4§ƒÃÇ‹¼‘¯7'`î™XBõÀKĞvr3´/.=W»d÷åßëN.6¦}4nZGi¸Š`ë]™xbQ~H~£2i‹ùšg,	f§mXHâD´ğ]­#ß†}º|`†°`8­âŞ¦"QmÜP
wI=«Z¾«;¥K?ÓåJTˆEÊŒ& •©œZTŠYÓıJ±¥¯yÅøSE\Ó
Ç_o‰tØ_ğ$îyXLƒo`õ@ëãMõÔyA„Ô(ÕÚB#íÁé±fS j:µL…eüÁ²õµï sïÌ<22¸ÜŸWÅY­L{Ùsˆw“¿Nµ\_›˜n˜s À_§İ¾é8€„R ß§´¿s×WèwKáROàP¦–5Õ#Ì€%¯À:!Nî!ÃĞN’ß›çÓóŞøy$@ºğ¢ˆ;`qÌW6áe½YÕïk¿QQrøz¡f?Á“*dñ…Ş%á&rGĞJõ“~3Œè×Å×Ç\®ûD'ŠÕ=ÈtYh5İr!üŠ¤.:¾ìQ‘ùx(ŒÂoxJD
î²úÜ>*[ºU\)T­À‰.¥Ó sœ.¬C^¥Ê ¸¬Æk¿ÙÎş+ÀK•tzœØ¸¿„øeq.kŸDÈ`aùO†LfaõK÷¾&ÔûÉi=Ğg¿ ¼fOn{ÿ‹ÎÑ}_¢z/Ø”¿û&¦_w„ĞÍõ¸(8Ê§5£Éå×‰…½ §”êøûÜ–Ös„Ã;¿!‘>EÇä4O¥L)=$jÓˆùqÒnò9Õu¯`u¼J$AWÁïi÷µ0ûâ ­
ä^ôH„õµÓ¤_lş4B]Ü­ĞÀÂgº§HìauNÇçÈ™]¨ø7uôÙõi¯‚êßÂƒAödtÜÙ½JÈAî|Ãy¿Rw`"±*¨zK“»ĞÌL«ÿ¨—Í,!ÊÄ{‘â¬¡2VZ5Vû'¢h 5ÜVy8øÓ°{z†©X,Yâ‚Xnz.6ÕZİ–z1¥øpZ®*/ÿY·tƒ*{ÒÃÈWEÆrñ$ñş\Úz1‡•JwÖ[ÇÏç¸îx²˜1Z>r,×®sl|”$ÊîùsÇ¹±²¥•èhgü@–_GÛ—%;}ü½2Ø4"Éù6_<¢j` ]­ µ¥ÈP(ÑcqŸª.üõ\“æ®ª"—Ğ˜w“&‰C ­i
åàË‰5\xG›FøÈĞÔbSX3ü#©İb½ïü0iš mùnonáû ä&[ãŞÉÍôoªiP¯¸Í´şËI.êDÑ—Í‡½¸8Ã©pÆ§˜O²û~Ã³SkØCzÚ4èS¤jkxY&Æû{±Ts”{ï´÷ğhÖ¯5½qæºcS1a 	MµRŒD8L0ËN¹íF©(ö¨Tp>é˜¨¬ÅûFò÷Ç º6n>NĞl(§*×UÔ_‘UsîæÏ/wï`<6]²•«ÛúºY@Œ'À éè¸/Ã¤©áÀ,	SvÅ”ÿŠîS¢c±­a„7i,Så#Ö€?'‰w>¸-ö†Ş(cÏMğTS×©L2Z7Îxå£Íª)¸PŠWƒ±†osò.ÆõÑ“üyŒF2Ğ›ö:¢âˆD—b'éUóŸ4ù¹®#ió7Õ
òô±T<jÔ˜+¨âÛE/	nğ?£ÿ¶oı¼a=è°•š±ÜßÃºØ8´[’^7qrNÕ4=eÓz™Ø9 CÑå%µĞ‚“ƒRt Å[8¤İY†ê9åµ AN *xÈe¥|JÌ¯‚±ºá¨ÆÉ¬Ç:×ßXoJ”nn7Fõ¸±M«õ_ -GüÒî(¨I©™Ö3P—¯‹iŞêÌjBN`aÚ®Î3 $à’8SnûYÊâ’Éïí€ß¨Œ=Q`†šÇHêc¤øz&Sğ½©i{‚®Yó­ãš#äIíG¤™†ÏéÎÏäp™á8¥ğä²Ó¡kHÿ3%hhİı¹%ËB!£ÍG‡cs±c4Qú" üz¦àÛ)Û´y†5¨í’İ¥CËŞD Ï¤#]Ç¹`	Aj7u´[›ÕäÔTpÔæ´øŠ<YÆi:Ú¾¶ŠÿQ/ŸôHŸ·üóåO  j™dBIdç¾·YYäRšºoabšì	Rş9˜&3çV“i~ëzûuk#Ë×ÇL
Ù¯d:]A`"ßUzar+‹tŸpºXabDËÛš©İ‡4-¦¾Çzç} :!!oõ1ü¥+Ï[6idtëäÍƒªdˆ°Äò…¦ª ;‹?
Õ.tÁ§¸§(åwÄó.©@7Vi¼Âìú³Û0ún•Ø½i•‚ÿÍó-Ôã³ihš	±²0~Â2N	©æÙ£ê]TÚ$Ò¦©eAı-w cŒïÂá°˜‹ïpœB'n"ğH–î×}Î-[
µÔğã}ÿøÔl/Ë–äÀ[ûï;*²ŒêĞÅbŠîÊÜèù5V@³j¿mßA¬;‚ÔşFA2Rí–B;c4À’…÷«m¢—×¾mAìcke³Ô5²·)7ÖSÑù?üJMâaè´=E$)›¿ZË~=Eù²ÿÕõµG‰j"xj°©¨d®’Ì¶êpÜ*õDÉ0j	 %³³^ÛqÄ#~YS›ÄTûµ“Àß|]|M‚»nó_ñ
ƒ'*j¨(„±¡æ®LS†‘ä(W¦ñĞi%ç>ÌQ~‚~Ì‰`(§¯³ZT9Ò9O({Fbúú|³½ú„¿Hfr”©-æwàğ!8|OíÑ5‘&d(=Ë‹ìhä$èiê“7? Y`ªÍ”¨U «-ª:¥Y”C¶{˜s,6¡Ş“,zóĞ@=‚¤ã.É3<ÅûhT|UâáÛ%áà-Tjsc¢wQÛVI?²—P^âó×†ô×ı*ÄÏ…¹jiD>ü×FR?î	Ñ³øH×q[‚Ât¾#Õí\¨l&¦.TrÂGœi{èù?‚yW4ÿCI)9ó#öıõÀ†¢û3 ˜ötd¤íú'Os7œÔŸ«`½=ÔñÁ’j·^>Å«î¾Ùk«ÉÇT›fÉ¸ÎËü  öIæÑ®4!‰\_ö
hoe"rnÜ›…X´ñ¿’¿!ÿsò²ô<ùAĞÕ§¸CT‰bïì	³ëŸëÿÎÊ­§È'¥é1<“Âøô^ á“>îÜOúÃ­H@aÔòHN[Áˆ$¨ÆÛí¢Ğ*ª Ÿ›/ÉÊ¤^İh)Äfu¼Èb{¡-«·¦[53–¥÷QÊ±EœõZ,ÑüS~šÿéEàBpÊQmÓy—‚Ü!£H‡aÇY9Ì&Ó©h“T¯¯Ãs*ÚL06Ùj=.k^Kêùa‰îj†¦'½Guv©İYXôèVJŞLøG¢O®ÖÌó˜Œ,º™_á‡Ö+)ó!*kÈNà¬ÍĞÏVÊú1€—EªÜÈˆ:YaêÜÓ_>7¥¡k/aO¹Oáè¿–­Áİ–Òeœ&w§ÌèsÂÜ­›¯!m ÔÀ´¯/-ÑëÜIk\/M«ß-¤x‡|u‚zŒ¦«,^Q_ßLUÆ£µİF:yNm=Ü?…B—Á‹»\î'6‹/€€rû­v*W®’eykØ°qZ;ö¶­Ç¡+—*~ŞLY@¨}vF ÑÂÈbæ‰>&úNêòm*Bâ+¥\¾Òı¬é]!Nh¤„ë<è¥&[HbSÈô‰´M¿«3ËHdèôÈj(øAŒ-]#ïŸ_Zåíj™ˆbÕÌÊY€äKÖÑ>Q¡nrwÉg³Z…¥I<áˆĞ2hÃ1‹—æóÜœ"œ‚ªÎj¾¶æWf=ĞkÂp¤y¢¦AH¹Â¬'YÅ¼£˜tzEƒ³^$™åu@…mÇÃmMt­ÍÜâ7g±«ÃÁkßdúe-/ä%[C@}'‚Y>¡äL/K³eS0Çbƒøx®ÂĞ ˆ­[˜ƒSL¨jm¥Ø©àí2Nœ0åÎiRD¥ñ/k§?·¡½‹)Ñ> M¬_ñnMªÁì£J@ªÎ~
öÑî$ŒÁŸZƒøJò”ª}ú¡ÚVÁùÀyjh}áZwgu‚V00v-Qi ”Û³”ÏÊ÷T=EíÅóŒP[Q/@Fâ¿1F EªÈ^‚Ÿ¶ò¦¤mÖfl, $É@aB ¥ÏÏÖ³GÕï) Ê ™“å=zDfÃOÚ:ùhÿ
|"¿À, éNŞ5¾‰ä¨”:¦Ö@ç¢s·\l[u³Z=ÿŸ!ÑŒ Ù”8ã¬,«¯«@1µÇ‘V6şÕ“îÇIş»éêæßLğ‚+‹;i¨{ÁzĞ¡/k–²'ñ¯Ÿ?Ofè“Ë÷xä¹+]¡‘0¨)»„öYONño)Ze¿~ZwUlŸ}#ì2OéFÚ¿“HÁ˜#°l’Ë„@5Ò|º–5S¸2=ç±S®M¼ñè˜Èçc»·»FÿÿdU¹_¸ŸÅï¦l'Qziã•¡(Bœ…=$°¤YUÎbps©bš³^(ˆç†bVeÑ·ıeƒb+åTªß›Ç‹²#` |¯€1
Šj$H}üvaü›|&cÖ›ÈrÄÀgëOx´u²x„”»“#‡¯‹[ÄÍ°'rrf,ê•ZX!*¦R´Ã*Ãô¦|qĞš­–[’-HX"“Ÿ?éæ-oŠ‡Óê^¤ŸîÕ¨¨ ™v1yI¸0ã›¶††íÂL®2öpLÌrÀõ½ºˆ/ãós1 õ}êğ«¨7~5‹àcQÈQ+Œ(‚ku¡f”L¢”>ÏktkïÅ0Îoƒ5—F@F)½e,oí#®#½Íy:)$ ×‹mÅ¢CQ—l—5Aç‚&P]¿Œæ8æ®†Â²#Ş²,»/åàĞôØüZgE+Z³I„7Ëó¨ ´ëÒ›duàğ–§q)ïÚ¿N÷¬}’¥7øx#a@l9¥¹ùG“=—'“øÈ5Qxì5^v@Úœ9<ùK…Ğƒ¥õ»è}sì^3¸ÕÃiv0}øì¶ÿ^$döÈÑŞ1ù°£Â&Ç/ê*ŸšÑÏu#Ñj­Hİ’*<šÍóÊšï4§ef|á“€ÒûˆÙìÁµ8Yc -Šà)•lziŸMq÷xñàRUë“àoRnôóhß'‰¿ôñ#]Úß,EıR=†½Ô.§ ²AlPñ@/ø'DzT9.M1Üpñ“6›ü©ß6åÎÔ¤u!ˆB§Ş˜nn—V=ÿÕºÜ·MŒ”İ9gÍ±n_ü-
Ê‰û¬Ä´[‹Èfh:‚™G)«AÓòZmê¿a›ñ€ñ°Sx™1A?z=_KšQ˜S¦JˆT*ïWŞğ—c£-èäPÈy$ôˆlÑ×ÜXP°+”uéâ32 7²¨~œx:KáŞ¿L|ª¾Ëõa0›7«·^Ã€)«|›¿nİÚ!ÿ†àzÈú@]›U˜Êù·J_0ÎuÎÖíîR 7‰ZaÃQ”äÈ7z	’~ºbKáİô®Â‘òïî4‹¯éÎ¢19s)ü¦Lê…qÊ‡å²ù›œçÇùOH7·:ãã{çïÚ¡
ÎGÎ?ÎW ¢#·ÖŒ_*ÔyCA.aV¯r“Ş=±óëáÉR¶™ö8~3
/×€¬yJz{Éb“ûàŞ*5dñøXsFîoò–ï¤ipÜswÃIz¨ÏÓYõ\ß¤LÇˆê°µ?¬GhÕ?)*JèJHØ°ğ-\t-+›‡$çœÌÅöUøRÉ!çÀç}³÷Bï)[.ª8é±ÁÅ)õÇŞI­ŒZ«AÕ]şš(î[¶\oÙOÕØa«› W¸¿…òh3¶¨lµxÖ*ŸÉ²tjKEœ_(X)µf1Š×ŞÂ¥Åa>6OešÑ¡õ? ã0–ÔÚQ+ğÅÜéd(Şğk[ÃËæê8;ù'52éïeß`¯A[ú~,}İ±ªÍ.1ßJ YÔ5æÇQ¢Xs£Üär›Rh/\°£¤·ï€¬©Ük&H¥¯!a¼GYwÇŠçU-BÕÄTÉˆ@şéîÃCÔ¤Np¶F¶uoRzÙ†v–P~=JL‘a•qqB¹’óÏ75„¯·zœË€ÑXïÒ™Ä¤GiXìÆ±)ó£èÿJaf¡ï·¥ê‚:ŸÍ_•ê(ï<w"9¡Ú	~rÿU^QÑV­ÌÇ—0UWø0ÆúÑ›#ªv1Ë·ñi²³çM©	Ğã{§ _s Y}_7İĞer7Ÿ
Gq˜¤#EWı½ãµÉ+ÏÒ÷®Dær&Y–AÌI00ÏÉüms«+)›{Ø„Ÿ³]LšWUÕ)ˆÕ>æ½@ŞÃZ…ÉıdÂë)ætæ‘HÑ_NncØ 5å”İÖ<nÒÅûŒqøá^MNÜ ãÑë¤öÃÍÂËÉ·æO=é…Gì£"‡9#À”‡Ç	„şKET[(nyè Ì(×—I~&¨—p	2ïÉˆ+Õƒó†Gœ[¬i{½0ğŠ£ÇwD	·1(Mûï,o*ÌèŞzîÄ®	rQ¥[Ëâ¥p’Šû<·óŞ	J8È±iğiĞww ºg`ìê¡èfZı#C]Ôº…óqù½cVù…Áë½àº­Ã8Œ(Ez]Í$-ÑoÚIdˆã´ÛµİŞhrÙÙ²)­ş±óÅf†€ê;|ç’YyÓ°Ç‡7Ejğñ“ìZ+ì»cj…<”ERë}1ò³ĞÇaE\]9)Á> nN”ĞJª(pAçÌmø0EAEØJ^ôÇÑ¯ƒĞÂ sBÇ˜fÉ,õføewÔ½…øğkÁ¾4šüÿ ´møOFâ©(¼·ş'c3lD"â´hí*<Ü¨¬Õ³¶=8ÁàŞ_·½Ë]üBÙgM˜ï'
ÎĞò}É¶OUøÅ ’Å1«–[˜à¶¹L³;÷ª‡°ÔÅZq7h|_èK *mÓòÉ¬ƒnÊæ¡Ôºd\ŠüérÆØ¥iUq*ÛPæs;s_„}K.-?´«ÎÄ^"&«ğÊ„ıú9´“ÊˆRjÓ]€í{STÑ†”|IR à9íç¥I1<H=êo3æŒ˜âb—Ë
dàR f;Ì¸ÃÜ1
àævğ}5RÍ‰ôGGöÄ7@[ÁûoÕEcåŸûbÀPvÁ5jœtß<âÀ"âÖœ}oÏÇÛš‰±îƒ«—HtßzÊ[ÿ4d!>ÚW@˜dfÔcqßp~K}÷kmçp§y5a…<ÿÄŞ;ıD+.H?Xz€¼»cÉ)½i·ÙÓËrØ®q/ıa¥Ûyü»õè´åG‡úÇ¥kÓLM&æ9Ğ±¯ˆk’Ôê×Î%FK,Ó$Uò¢äı]«½ÁŠ6%bõ–x„DõÁ×àÁt8p6©p%:®Õ™°ªå¡ÆÇÆrk¬Øö:î*1<ƒË;J~™ô’ÃâÉz–*©†<­L¦^h‰;øåà^!ØUsH¶åÏÚ}ùÌR7Üˆ÷OşåëÈ²^¡oÀhÚ	Cü€DZåşX,òÔÂ4z_¯á@³£Ë4ïo+ôÏ6_|·ƒş–›éÓÊÍ„ôLfäe|W}~8=‰mÚ.£ª9†Ô”|Ÿvô
áÎ$—3ĞU·*µ‚™\j:Í§üˆÍ’Û»2éï–c·—bWˆ²ËÑøó[Úrÿà0	=Ø
ëÇNc»ç¬^©üëñË}vş€ ùRxŠ=³TŒó£u©çğ–)NS'{£e‡r{ÂîÇ™÷>|O¹L„sî–#C~„ì'¸}ÖÇ’;Éó©¥N÷K3>PğÏ U´-j%;8¢¦ˆ!œÕø¤Q·›ô¶r¡!óÉu‡écºÑ—XÂÕ¸í}#oÕmÅ^)X]º•=Å×§Ro(¹`GË.´„7X§ã«÷í”«‰Ò˜ÊkÓÌgÒÑ‡³ò;/j¼²…£ø	–k®ã†2ÒgÅ‚¾`Ìr-i8PU.Øº—*‰ºS?oxup¨1eÛş2AD˜ÏŸ/….4˜˜S)«@%0*Íæú8Ö(Àr¬ÃBœX,Ar÷˜p!C]k®b;Z‹²eshÕ@\EIsé\S^å“lX°=qpš8^æ91„Š]®[Ô
“O#ê›;\Ç*É8cÛ¡ -ŸQá-¸<é÷,°X…‚±ùªù†|ŒT&ı ßO<á€ÊÜ‹ã>´§®Ö4 Ã/#£»¢ÿkgŒ´êÕÎŠ‡g#¼’,¡ø¶‡Š}ÛPÉ ’•«cápğ¢+:%ÌGQFR`M[YlÍÈDQåõa’ÖÀ
1ú)"Šô°ù¡Û¦-øÊH9u¨Ô²åü»%‹u?İOú†ˆŞ¬-›éï÷¿«Ûb+·½Ø9q—¶Œ0T¡Dk×¼³²» jæÄZiofªA~t™_ÙA2ÓÁ8)6æp8Ñ’³a}²2ù§oÔ¬ExÁfR¸	™Ù¤ÎV§óeie5ÜŞ£<¯Ö®Û„ÄÚŠ/ö±Vø$–'ñ´¾ês\µPJş£4†;w_JÜ×e,ÿ
éíˆY4½°5[`¡éİÙ’XÇ`e™1	Ú«í”±ÌPd½Û€£—!¼€² „Iî©Éæ¥o_,æ·İ®ÖÖ·<[XSõ€ÁúzœÄÃsİ?|“€—ó¾.ŸNSÂ^XÂO0İ…¨ÿrN1ß\õŞCÀØ8£¬›ãÿyïØ°o9„Ot
 ñ¶İ°†ºçVUiš†Z³yHË·ãÌÁËB#tH¤aJÈ2¢ëÆñÍşİeßYŸâ‡u£*T¿ÉÜïdÅSIÚL¾àçğ|Ïû¾P8×êüª/§£{î€Ì?~=¾Š·YÚ´²æ4ÇÃ)„ õïÎGN0‘BIËü–€¡”¢•ÂğÖH§ƒ³3½éØeEdÔÛÂÿ©{ ¿/è#®í7øZï';»­šù¾TrØÃ"N ˜Ş¥ã™ØQW¢O*6•.w¾ôÙêJpQå¯ŸPò]èó_2¹9Yª¯uÎ‹ğü­2¦ß ¸¢r‰mePÂSSÕÑj ©jÇ·Í5ìTTß¹L÷AÂü€rÏ#‚RÜÌ
Œ ­EµqG¹Ö"FÂ­b,O0~œnwô½—8­®Ñ'
z'”šÂ[ ôã›OşĞZíšq$5€Åá'{2³3wc§
°)Êáªÿ9Ã+E…‡®Ö¤ò¤ªI¦.œrgC;ƒmÂˆˆna&R *Ä+->bº/HæÑRû†mÅ£ò-“(~ÍÃÁ?zVp5ûî=Â‰uËø­|‚˜ößc3Méå½JÓŠêµ{Sê´R	ÈQO¦¿¿çÊèÒºäB³"ıŞÿ-EÂtêÆ´²_©m˜³”WKh½xbSöÏ˜{@˜fÒ–eáÆWö_”xtÔ6ƒ/«„:œÓS/®zŸ$ZÔ7 Ç‹º%ôaçmÕÄ	ÈoªÕû¤ÄúÔ ¦*ı#ïôÆ@à” ÄñùläRÁ÷ô3B–r’#„èI*N„m×¯(_S¤H.d–1]hÃ®äŸGì¹Î*çç_šçe3ˆ‹°9(·A¾([&h¿šFgÿî~WÜN¾;(—Å‡¯]ğyo™zâzs¥ˆ5íj$º÷õ5>'áÂQ
¥šËƒ¼b©b
Ç&VZÈ-ò*?2­¯Ë¨„k×æ¨w{ˆ†[/<ôsÊpÿTf2€¬®»Î?mÌq†Ò†'ÒëÇF‚MŠ	¥ T•'Xœ¨¿£hıû^goêÙè¢˜IæÄ+ÌîÖµw²ÕŸ±çà¾çğbqúL›(³íŸ=”Š¦á™$ÂÄJûˆX¡=Uäí²X+[Â¼.,âÄø>ÿqçÒç>„£V‘ÜË#ÄÖ9Ãffcm¨à²ÏÃB™.zRÛœJò­şÏSôzÁ÷b-×VÓ`ôæi_g+²·^š¾%ñ3=“j”¦r"ÉŞyŸIì7„-ÕèÆÜf•ş½Ç,­õ€>r]÷îqSéR íkÈÍnp%°"»ğX~y¦fuÒ‘„òÄs•"4‡x@züÍJnÌ¼ä-İºœâ"°G0²‰‚>ãpeZ–^{EDqıÛ#9ûë³Øu]–“.cŠùS^ó©ç«ti*C‰hşaÅh¹4ŒÖH¶é0K¿¥ÿÎ¬òM±¾.âìÏêÕJÍıåN÷³Ï-zî‚l$#üœ-ŞzÆû}_³b8A\½ì¥^wL´&œßk¦W:‚N‚4Ø–Íÿ•à#Z¨”¥Æ´˜ÂÑÉ’w'ò:!¦^ı÷ûã×UJiûÃr>´ùì¸¯ÊN–Èq#êÁ…ÑàMá¶îÕ©:Ú7qşÇ3ù ¬À'²|T¯£4É‰Æ½G.J{aa0u98Ÿ£çÑH(õ“÷u·™c"¬t”˜Ea%ß_Ç†ÿ â2 6kX\ÄÚæÑ:zSÁ]ğ]ÖŠ`­âxßKßÈî2‹øËŞ§NE~Ğ7ñÙ%¹ÉÕ‚ñóf:0C½ìh9ˆ$inQ[¨Râ`ÈëR9İSæ¿jbë–ó<\®gJØ²á×»ºwP\cB/~7!ÍÌ•"%Ë%‰ÆŞÂo•H'lë 4Ğ€áy¨»šŠKÑK@Bör­ÔlUgÛªŒşøû9½µƒ5»½	ÍH€Ğ<ò>§¿#à¨)Ô5vnÜ~¹ƒÏ‚">«1 >#…Œ9['ä™DşSöK0…ä&’ceªP.˜š)×«¥ƒ=UºôÖ9ÅµÄ%éÙ­U	Ëyõ%UŸ†¢âûëx’¤¥H\”„âÂ¦ø_F¦¸"Á+â˜µ‹½Æ‡˜”7x^—„~¦Õšg]üîâf!0“ÁtkbDáÑ=_¼L¥™³.†5Œ±ĞŞ©J#À²,>t·‘v&»íğBäÜ>@XÓ¦¸øEü‰·[¸{ƒ°ª¥ªëü²Ø)•·Ät†=Ù<.³¥xÑà"B«¼åú¼b¸Q.¬ÑÇãÔÙİN;F·àßùñ/š—Ik`}¶k{ê#jãƒûxÀ›Šk¸ÜM5œ#Üûˆ}â1¬²§r¶NH4éÆ^X§ GNQ­v#nqõ¼\¨Uz‹¼ÇĞÈ|ë=n.û¯<ßŸw®®é½,5ÜwA»;NW­º_¶·Ä:Ù€.‰xTtT³Š?¹ËÏÚñ-bE}íÍŠÙ;Ò–^¬%¾qZIæ}3ÜtXöJĞÁ{ğ4oÒf”WmºŒHékÇ6ÃPÅG¨ù÷ºL…Ş­(>a·€¬ıš‘}3ÿ$¦6ìD‚İi¸mÔÉ®T+ş>X:{¦ÀÄÎIj®ö@(%Oél±”¾XDíge¯?Å•@–°Ğ;p×çGÙ"à&yÜ&3õZôm‹ŸïæIo¤(¸B=hÑÓõ³dq8zöTº#À‰0½a{$¿iÚ3L½Ã&îß%îU’6_ö§w°ÓĞşA9™6ãT]úq¡‰ºàcÛJ™>ˆ~å0>9İÚ1k_†ÛTİçˆÜöC‹Ë±æâòH2NùT"Êîµ†›ƒúXL|úI~¿ugï«i3ç3Iù¼HPĞg<ø¦ ßÿsˆ5ÿC¯I¨ü¿ªrÅ^»ÁB!é•Dkmÿë^A!CEŠ‘Üåäé¡\Ò¹û–©`“şGŞ>»2
°dÃ¥ò®,•SE¤Ş(‰}$Ïç2ÊK+¼ş˜İ‚_¿šÓá[·éıy}GJA—¡ƒŸ©= Â]•Øóœş8ªCl¯š²«
ãìª®€2³}õÜ÷$ë6µ¤u4&5g%íå·‹Xê…›“ªAt÷xÌàÀOb“z  sC´e¥ÄaŠ €¶€À¹uN±Ägû    YZ