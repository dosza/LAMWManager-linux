#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="316915473"
MD5="c72d4aac6d0e0cee60b27a56ba1c3d38"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26464"
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
	echo Date of packaging: Fri Feb 11 04:00:59 -03 2022
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
ı7zXZ  æÖ´F !   ÏXÌâÿg ] ¼}•À1Dd]‡Á›PætİDø¨,©!p3ï}ÌiŠìÃPVŒ•âDL‘gyÁåRCÃÂf•×•¶Ñ‚ªİEP™o»ªËaùÅ‡G³1™RŠH¡¹RY)â_X*k&‚rĞ$KX¥l.Xüã½¦·²Nš+’¤3(*Ù=wîA%Jù”+6¤ògIÔH¨%p¯£ØL¶ƒG_×<M Ôİ/¹‹×—A[/˜éÆ<ÇÙ3·°É×Ar8¿şúòs°Ö4 „`¥V_záµ¹c(u&FPèsêÓ‘ÅñCä—DÚK~<Ş5ªWÚ+MB’
ıXJY‰}ÛvíYfFÍ0Mh*Ûá«ü`ÀÏˆœc¥¾H Ë·Ç¾B­~nìğ–	©O:Ş°IYZØ×BÓC¬$«ZWï@tM©¨½OˆøD`À¾º„í”÷RVœNV…6ı\¡©l¿®ã ­5Aø,­ÕUÜÏËaøà<ü?µ#Á¨ŒSİşŸhZ)sÚŠ¥R•<[¨Æ£–~‘.V¿ğ äÏÛÁŸ¡÷Š©[ñZ2^É»ô°Y%7!ñşm[vK‡AÂºhuÏ 7ûRN/5U2	
Œ>Á2˜€x šB°»á’FB[UB8ÃV!|Œ¦U†Å·™µiÑPŠÄ…Ù0hÑìÃÓàş5²¬ÉÑ‡Ó;Õ…ŒhÏˆÚI³>_‚6¹Ãd¼ÁÁaö³Ë$lH+Ò]æ®Bc]¼Y‚®fvI¸à5™Opd4güY40·aSÅ1pg¼z£m÷ú·ü®-ê'İ;eê\ñSÏÓB&£€í¶*ÿÌOº!ÿbèpÕ¯ƒ?!Z^g\´áÄÆ<oèæ´ÓğGJİ À»áº½&/p6ç%•Ğ»W6®äĞ,Ã¥FéR€ïùPÛ%ªP·ZåöÒb&õîáe&¬¿€ÙO'{’ÁUbĞ`ÁâşÍníá÷Ï‚Sf@™‹$Ìt¾»ŸOì U"¶ ˜""¥5éŠë—
²–şh™lK\Çßœ‹çj(b¢ÛN«¾Çôœí˜¤¨tÈ…Ô§UşH•Ø‹;ıÑ#º1’¿ÀO:ÃéÌñ
7Ô~(IÙÚPlı£Y¬°cô5ÂûáÁé¤Ã©Ÿˆ~°ÚÕ·B~–Ğÿ2¼’œ‘Öæ
Ñ§ZL«ˆp#Y`à Ã>Üô³%‰/,¥_t9^ÔIpï»]t³D9|+Œ¥¨ÿM'JK¯ù‚é½FâVÁ”xHSPì¼,³H¬p0ñJk,"_­¸…jİœ”m°äOj¶š+0ª^X­6ï>\Á³Í¬VÌv+ôkÛ˜²iŸ¿ËÇ®…d5 súáÄPâÚ‰İÉy'G4û.ÿ¸gwH×3oä*ä:åœÎrw58h'Ü"»Hæ#ìÙSF×ş«{êòlÑ"#eÙ²lS³Îâ\i‡ ê(–tœ+W°G¯õş¥‡ss	—5·ÕÅTJpÚn¶É¢BïF*Ÿç’ ;C"#¢79 ÿäúòaO6E¾l¸+JLPK˜+ ÆÅìMMn˜.A\ò·0ád¢/¸×=äZßÒtªúFœœ=Ìbî"ÙÂ2é˜õMS7R®ï`Š0×Wü¦’š²³k/|°¡?^’Êÿ6«ñen*€fqN^Pcğ•â	U<İq3ü=?v%]Í‰ÙYï‹õ)×ìµ_êébÆ éˆÑ¨”-ä£‚ıi*eZ!”å‚ppáÈÄÌzxª‰²y`Zh™&XYv…@İ@ĞÒu.Àà Ñ¶Ú®Búös¬Ã2½µËÈ©ş9¤)Ä=ÿswğKfïziÖ~S4'#Øß…QyJnËÎXGıï·ÅSQjø¡8‘¡š¯PúÅ* 8	¢\û›£Î8C ğ¢ê÷‹´IÍİ„,Tz¤%f¨òÒáYSÄßfñ\wÅ’„%¾ª(tjéÄ;…OP(ªªç]K=WY`Sè%2i'}”¤à¼‰Á§¶Ep(a1I¼EfUVÈ[¹ß
¼•™ú6cŸÅ¥µ
Ó3ëÿœul¦‡mÁæ™âå
e˜t) J<háÚÂ*¤µ-fL„Ë³(¿Ce"ƒÆrÆØÅ@¥©¨+~¼V>„òp*u´~ìíNK¶ªãí¬‰¢Ô=<Ïv»u êBùÒn­Éœ¥Á¸¸·ŒD¶v ìõƒÙ•´ÓÊ	Ô§l0É–9ñ7%²³#yõâTÛ¨-ğZIL„KbQ½ó¿ÀZÀö™.õN¤›¹$Ôˆ›‡’t,.œÎ£{@Äg=ètwäşğá–‰¡…GœÆ˜Ã¸aVFXp­'ĞTH²_ŠŞ2Jò=D@@
OPë¦^8ÈÔ„@py#ÿÏBÃH",ÊrÎìÖ½mumöä‰j”îNiº5Mdwóg*L<“›':/Å‚i¶ãQï†éµ>*ÈåC=Ì=ØÃÌ´•àÉ°°|e£B€Äôl$çÏì¦èƒÁ×A®I¡Ä÷èXçÅSoüÜI}qŞs÷ê†6ÇÔRzÿ”j3}v2¨ĞÂ\ß‡º¾â‡Úccƒçá"D"ØÑÿ ;LËÌÒİªáŠ7Qúmv¾„İêÊÓÄiu¢„ÉùB© 
×Ieé"*'ÔÜù~º”‹~Š{ı¬Ğ–ı§õŸİ¯öëU÷k„7)EÒ‘·À—ø•HÕl!iµœ¨×B¼·ë‰dW¯6àÚuZäAôs(8KÉ=I äpºdåd¦‹„ØçùõÒ”’zÊ	o3(,O†…g÷–(=êµ»*¬0õ¸UH©±&ÏCÜ^§?~ç«Ç´ìâ…º×‰ÏMÔ‡¦ ½@!â$
Š¡®#ĞãĞH´QRK™ÓONÖoo?ø
ºŞD‡û|wÈƒ¸N6é^¨O@ñ‡£ã?XKjş«çá‡3N]ÓA&û^ÃÚÂüXü
è€Œ†rì‘—®É»p	Çg¢ˆİ-¡@}şæÉ6†e
EsÒZ)j(×ÍõËQØ¥œ¶€Şc;õñ5Ä‡ß©‰ªù3R§²!ÊëÃé˜™¸Ã4® Ók¯Z8b5À¹Ğ«dFæ¯¸ôçÎı]ie­G²Ô· Ú{V6h›àí½/Eÿ`–ÎŒ	£Û—€	p[.xÜVÄ21¶bxŸn³\1¢}Ü¢ğ»Íš8">»íëèÑ¥ËDóş©{_uUõ§.r·hÊìë0ôª5ã­C33Ğ¨%µ’Õà"šU•)Û¹o"n®º73“²¢ºéñ9Åbğ;O‹Õ™ÓTÄ@8õ²Cœ°.¨ú‹+Í¦K°^Öğ#™ùfW_½„#7¯­o±½>NÄ ÍßP€g’HĞé1înT9(õYCéİÒä¼m·Ë¥¹€gˆEqCİ¥çsõF0mıÃ2(¼Æä½+·Šv˜™…¾2‚CåE¦_Ô¦×B€)3OK$È 6Z©ÍKUÇøØÇ±pôRÑë&XY;ÒSo¼OHz‰òàpïí(ã:ªÇÃæ9tÃ
¹%muPƒ vpY)â®È€{ hÿØy×ÄÛ½*¾"ØRO´ÔfÙòV‰å%c|«ù;º‹‚úyl“”({LÒ}EM{ªˆÍ@c1‹¨)u@€,H&bÌõçÒ%ƒdÖˆ?ür?7,#Sgßgâ ¯¹FeúVgµOÿÖ“Ê ÁùÒ¡¹æï¹éŞãÏŞ+-ÁÍÜŸÎï@*°[(9yıN7&2¨P¤°Zypã´³(7§ Í f
'÷mç†~¢–×ücH]‹-íÑ¤WÃUÈ*î1B>¢¥ş'ØWkE—®5s€/J§—AU]Z¾s÷=9)]ıÜ.á³3Î‰ÌËÒy•ÁäÃyK²–.•7•coN„‡Œ¾ïD:eîJBê©³/‰œ»ıÆÒ|»ª¤Óœàz1X‘²>z3·?ç4ÈQÚ[YÀ!ËeEY9X5€.BjÂ	ÏP3Í/åë”iÌôîÌƒßÁäÎ‚zODÍ.ƒªÜ-¨Ukxk”Îz7øbó	¸Â‘j­jƒÇ–ñ†vWá×>MBP ¸ö"aè43ÅGk¹I*$"É‡C¢;Mß²+¡âÌ~k0(*Ş\ıŸ<Ä‹<$mtJK‹ ËÎ%)èå)%køj@ü]ãû¸0ß/Ê¹8K PM"ò!Gñ³úñêd³1ƒş¹ÿ²¤À ’2+?béÏ€¨rÎ…GËÄMó0%ÖIaõC7$¸Îb“wu¨\Í™(b‹«Hncçåƒı FVZ¾éVëgyb ş(·ˆ0h­²uvNÒåÃÌuUå<Ã.Ç:¤µ”¸áóÎ,¨¾ ğå^»}õ?ƒ×4˜ÔEPkyja0ÑÚ‡D×Bûø"Ö¹	wOÁr’Æ¤Ë ‰Fo®,®•ôáĞ­‡"
é#ÿñ3Ñ]Û:Óü/D‡ZÍ¥!5†õ½—ÿ&mOQq±¨<Æô¼™³cjtÛ¯ùpBÍª¦ŞO½ö{¦Tg&éTŒngè_$Fï™ÕìºD*s@Ô£ş£™±ì~¯µÛ¦2ˆ4‡İ)æ÷:şLA(D©>(‹÷¼¾ÿéŒy‚{²tdœºnt» (ã·©vá"2ÂJŠé×6o29àÉ˜$¦ÊÓÄ*òäUe–°´‘ï R“ø
²kYI¬ª¨Š]•ôíÖ5¿8ˆWòeÈ:à¯‹ÍHÅáÅ9iörX§V]Ù$’üØŠ×ÿXØ—ÑzşşQ
§7€w¦Šc/ÏÊÇ°_›è”Õá?Dö á,mÍ’ƒJGKÜrvrC|1kLklœ_t¸éIVnn6W}f0¶<IÌ”'íN©Ş‡9ELêpoPW–óPøêâõ{²¸‘v¼TÈ/L•Úb¥÷ÉéItœ®®À:¬O#Œ8?UŒ:’rÃœ2§¾Fã‹}T¦°m·æÑ%¬uÃş·• Àø¨@IC¬Åú(O¤Èéµ¸éf‚ÎxÚ€àÈÆa…¶‘ğ‚t©$˜T‰©x¢>a9ê’:Š˜Õe¥´;Ñæ[	®Y æ
•NQ!Qu
¤tÉ-g›†Wšçìrƒ€º¼â9.LWÚË=é¯¯w{“ò#o"Ë‰‹slÛù[ÂÜh!²¤?AŸM?‹é,§\œ/N!D(øƒ×…š+‡b>·;qáyë5Ì¬™Û¹Q_Á­D/3Û¬a²Ëc	€	Ò÷®Šó£t¹÷^®ûDÁ1­xÛ[¢,kÍ©@;ÈŠØU“Ùkê| r„‘® ªdv¢&ÆX‚˜“İF¯ñ’…¼éJØ†nÛK†Q½ã_Dµ0r«ã2—	!ğlš{‡†QÀµïóÈ$ !J/Ç}ézfìğç2o9ËŞûw6‹ìÕĞŠÖ¢(@¦Y$Ú¡ØµÎgç f­Bf¾&ä—V1c{Ê:crÆÌÕÚyUq¬Alp¹õºm>m‘-îœG¯ODpEC£Xuà{ù5¶_M4Aë~I¦î·¼¢““>ã>ŒDa·àl‘z——héH!„4¼3Ú^¤p›égÔâ»Í?F‚İ1m…9\ÃäK#™´>`ˆ›ÂSêu@°
™y°T.ÅäĞ®^Ÿ”íÈãÏEökääæaKØ<ÙÙ­Ñ·t±('§Àë³¶™9bs2rô aægPòŞ*îo‰|\
jŸH-¼çÛq•wşŒNNBÆi/¬ôëìV·°%¬‰å#ª~r›y¢k:Ÿs	ÍWsõ>—zCmõß·ëÄ&Ö 
¤MÖÅío^“íÒü^.cz=a¯`şPıåµÕvX»É;n ø(Ü1&š»lÇ¬0ÊªmrÉƒ6a84òııÖì¯ÇUGq¸ÑÎp8ÊPÃÁó %“Ñß&xoÇcK€>Ò~½%üÈ§÷@ŒÊhyCv6@h…šáñÖ¡ÑÎ:>JêU¡ˆ`-ı°'¼ÛÀßÜ¥„ÎÄ+$,WÂş¨ œ+/õ÷âE=œ©JtšÚvõM
D¥•[ Ó×ÏJ$qW¼#­ô¢fHW€L;/µ–° µ.ªÇGh#Í…¼tÕ‘ñ?Û8¨eÆ[n¥€¶ÇöR)×÷€—®fZÉ¾®ÚmI`/ö+;–´«æÄ F6J°£í@®]Qì›ü9C”Ásù§¸úíH½·py#%öh"¿˜h<LIğX^häª[\t[¶`¡æúÙİÓÀyÛvZR œ÷ DŸ¸ï¸å„%Cøş!òLŒ~éGG&â»x¶”¢zSn‹Pğ=]¾e’†OFOÄ†f—å®FáÁ #a “°¿0Ñ¾jº8‚ÙStò+¨PÛ%y&‚œĞçÍø0%1A¯ß¯¸ƒø®4Ñ×³<‡Ó"G–	ö¢g»—B´òª¬Æ@¹lVô¾8xµ´°wdc&¸1’Šuö?×ê|ö«@k~î‰´€DM›â'óu“şì"ÃĞ&’(*sùöÚÒ÷+Bùª¾Î=f©™C¾9FPÍ‹µpV€Æ—(ÈoŞĞ;"Cè…j“¿a.Ü/¨XòtÑ'şã›o¯ü‡½Ëh¸éøÒ~ñ	¸¿_y
7ôRpk¾Åb,;‡Š1BW2Ğ½r¯psùS•)ÔódUYÅQã Êc%¸aÅÅQ®Å;m‰£ÏL&ÛíÌÌU}kˆí‚Ònÿ5û²3¬$Ó`J–ºW•©¿š—Ì¥pÆ¸´Åt^?«ñ‚<˜øû˜ÓåŠİ?*ª™ÒÄÓƒxŒ–v”*©œØK´‹i7
°'İèqUY[U]Uã¿ß–kõ#(…(@ÈÇ×êl7ÔdîzÿŠj|VI£Êë	áI5ØæÑ$œ’Õè=y­úí½½«ÙE^Ìº4]¦£reæ™ª©	”tjç³ğ¾«©sî!MIgÑ%Â'K5°HÓ'ÆÀ’M¤”ü±e3’Øí»±-rÒ‡
è<¡èèW“q@) ´6)$aƒ§Ïİşdî†~-ÒÏòE¥¿åG¯ŒÜı;Á)ºÎQÿZzè”MÔ²ÚÕ‹3„a`hŸ],ëyeTn!sií_n†œ0ˆ‡~~q’Wò&êÂ@3zdg>°£‰ıkü%@ÖáÖİñ«ßıÄ†d*‹&
Ã.v0¨aôÊq°r\möË–s\]¥§nŸHÊ¯˜ÖŞšüŞşç+ë9­“[©±]Ç¦f>3´ªß*½9¡Xk„ui»wğèí29?áà{5h”¤EEºğ ^é^vÊşéQ _Ed€‰ˆÅ —ßËÄ“¸2ÅæL•O’’õ€Œ&ÜíÆ®€ÛÆ aé@åÑï"H_wU)cÅ¯Î«hÈ÷AU€aˆõ-Oæ,Æå*›!å·şî‰’éf¢<çúîIv†m]é½/m+KJ^¢O¶òv _ˆ™<á#»™ªxxYºŞ€µ¹CüO?T~.b´@‡“JÈw2a€˜¯m¨3-‰½ğNø ] 1b`2"£P+(ë‡ŞT) ¦´£dÓç)˜pm‰Ÿ8FcÈûá/ÒZC÷Û2Ÿ€°\ä3YìvYÑoÎÆ³ƒŠ :Lâé–P™ÅÃTP…`s%Ø4›±ÎôŸŠÊ%ºıß€¿¢©˜’‘ˆàkĞ'c*ğ	97}n)·ÂEçŞ kµá^€-ºÿoŠò~ÌC%zİ§&<İxjÖÔ=”PúE¸‚Èóˆå³Z-çê
ìÂœ¢ú!,TÒv8B€…¬d S1àIÊ9c=‡cÀ	:EFãâÃàrwåN®ª«*@¬Åe¢DWèBJ™şÂ¬²ÄG^à“I–[Mhä´M…ê®—9®\ö5®¨d_®„oLşz‰‘­Z›¬¥oâ;ÅÃì^ Øš¯²ô«\V½tü÷–ºç>,@‡-ZNÓg/Y9Ï:âî²ã_íRğûZjh*‰æ­tgf.&ôÂS•?–t/m§«ÊØ{éNSfì²²¦åÛ ˆò›õ_¯ˆşÊêûË_M“¼®½»t¦ª%j=®½'UÑß.^ gÍ»Ïë`iÏ®ê©‡Ç¤w©µÅb2a~ÜÍ“|#‘É¬(ó’z#¨§ún‚' åqª£ëéš7#ÿˆtø_ó›‹ëşEòØı<ZŸ1>ëŞ4ôM@W‘µçz!?ªË1“&X8Ş³!ÉTàèë^]`÷PU+ãÂôĞŸ H÷¹®Ë•m¬Ñ Œ{Z?Í	(™²^áÃI‰ÕÊáçø8’bèÔ›~ò¯Y.‚cgı0ÍF`ø‘æw‹•ù²j¾FdĞ×IP:2lH;™{b3¨Ëh”¶.â×•Ñ`Y°]>#Î¯ƒ\ºqƒ-½ª¨³Íc~ ‡÷øs‰å!]Ór¤Éb’áW|¹j,?pXvı|ğq¹eÙ˜% 9‰ü³ÁÄZ¤à2OLQ.´%(‡x©|„«ùäÖD¨ufÀPG) Á¦]a)<Ê4rA`‚Ò‹MHş©z"Ğ±3ñ6ÊW¢¾¨÷Ù‰ÆØ–v„1ÌÉ©üOVœaÆÅ:iÖ3Á§.^i:	,ªã€Üdöp…J-	ôKÍÎdÑW(› Ê€[ò…w`ƒ¥äæû×h¨(ÇˆSZ[`ğ÷‡˜Q¡ºµş3ª‰í‹i£É$VŠjº¤G"|D=~Ğ»ï&W¨€‚rø =IÄÉ?ÑÖÏvÂ~4Åu,¬…#'Ùüdì-ÉğQLùf64Ş3¦3íªb¸	˜Èç}[ÁcB”N)ËeŞ[9ÙP7VİElk¬]dP×¿Ø{@2çŠÉ#‘pé£¬¶sL­QFªÃK?ÁD¹mëÁk•GÌØ„,O<5áŞÀ}ÑF$yÖáö×í?¿Õª©jPNMë^’?qdTHñ~xGo»ƒ#r®_Ö7°µ©Ì¦è4'o¾Ó½÷Ølíù1mw)ÄÍ7…ä]Ô´yDëÍÀYõ£"µñ^èC"ıUO	LÂP»õ—œ†÷10nş»ÿt[Ö±Ÿó#SÃàõª\ŸY„úŸ¹c
]¢ãŸN,`ù¹¼Î^k—Ç94ş
U¨Å†êë6^TİJV+ÍŒÔ.æñ³×¦{ÕD~ÒnN§#˜­Ökü|¹8€šçÚj|¨ärM‰“rIĞCSÜ¼^_j—?Œ˜Ûú€‰¥”æ\€ƒÛøjWh}Õ%µìÃn–0ô+€Œ qX4°Ô»mûxÕtnx.Q†ätÊ dŞß5›âJo)nw-&¨Ö'& Ÿ.ª°ì>oŞûË€B‡:NÇƒd—lruIwÊºGu·ÄÁ	lİ“°£”v¸â'C(?‘IŞÏÛ©UG²¡&œPA7‚®t;–›ôıô=ÎÃ¤¨ö×Á¤ìıÀFbİ®¯QvUÓïê—.‰_Cœdëåg€Êp¡	¹tmÂ¶örÎYMóIgˆ¸]MiÄwJ4‚KÏâ‡ )?÷ÛOWº´İîÎû‘ÀÍ€–ï\›¯œş¶î¿ûJÆÜFÅ•)4„kÆÆ…asİC®o'ÎXè©ÍrƒacäÅ~@•QUØ…Ãj[UrjÜ%‡1­¨Ëº›£æY­{‹ñäØwÔ`ıˆ3l¯*‡”ßNµÍ—?å&Ô¶g‰ú´E½1¹Ôo‰Hî**x`­1qÃÉÌ\jÄ„3ö;àßG81b¿óy;^<±$˜N·èÕ@6šT˜Û•®Wìµ«RT‹å#tfó4…º‡IÙyşÇj™ì”	\±ÚQâ¥}ñÛJºæèıg'º°˜íÜß4ØuÑHmû0šîiúßäµd+K«j¾$÷63*UÁíóĞˆ“Ú´–é®“{7a<ÛmlMÂ¸Z‚â¨àõTªåtVB\-¯_Ş´";ÍkÌüZ‹§V‘ğü>u{ÊÌWäÙ0ŞôCR‰Æ¶Û~)–ÊøÏoé)"‘}j\`©ƒºnK7®^E€—Œ³ãU6ÊÊ~€Œ¹p<Çä¦2ñıcĞ¨¿õÕ:£µìuÖnµYl»åƒ5}×yû,ó/*”Ö6@Ì)HÆ±± ŠeÂÕÇm­İ0@órdjeÍ:Q\£”ìš©â‚?ñbœ‹ËæûŠÃâÌí*ç”+&I¸íR–1ÑrA—AæâCçv˜Wª¡['Sñ¿j ¯ÜZ¿n¸`{ş=4\ˆ5²î5|º•œ1vìöéÍ·ã6ÁJœ\¥²Ê­áªTÎÍÕ»8O|õ˜ÚxúJ¹b]=£i1×mx»Gù/8µğ’¾ÜÂø#âª[0?MEŒNNÌÉ°&é"ö6O$»=fŒî!£mùNU§`õ8yDÃFYÍ) pîQBòâÌouÒgStŞ3œÓéB?zÌÌZSÑhûÇkX’¶ÌwíçìzH\{gûy4Í9åİ'VÓè Ğò$Æ„›{nbhÆ‡ß“§÷7îŒÚ”½kØµë“6™v'¦Ûó+êÜªâ¡¡½Ã¢{]¿—R¥d¸2ÂBõRƒÄŞmÀ\/»Mê‘û"aD„ùˆİÔ.÷&ÅÈÆr£‘ÚŞúÁÛQ=w-!“)òvµ5ö¯5W@NÙ„”†¨+ÛÎŠÇ$ÌLo¹7hÔgöòAøû„¥KÊ1å¢’ZM2)õh–óêæn¨e[6iúyvT\¦•O£aQıS°˜öUm_Uë,UPå>ùÔ~NªŠèW|áa›?º€·÷Œ½|À¢oCæ*×ßmú°t#NBıÖˆE³yñMxzªtÒÎ'Š¿9ÍlzpƒØÏq†î÷ø1è6˜Ï<¤«BèVFª;¶#…”‘«ƒğEA&øë°$/¤$O6¾,•	fÑ¶aYÂ„°c×Mo˜«…$D&PnãâT	‘?±Òu§3PÏÌ)5¦Î5‰­lûšóv_5®ÇR?oÉâV‚®‹R *Í©]Ø¨*]1’xÖ,ˆAåéÖXÂı ?O,ôÇVóe¬¥Ö€øCˆ¿2Ğ¨Ôi0í1‹•À­F×PÃ0Rÿ¹êºr#ÂBÎYDdç£A‘ç­jxDr<;(pA•¥ˆSr|ºf"So‡¶B%¯áÂ›+³r)õñ’ÍıJâ©ú‹ÆÍ(©ÀÏm¶“$	"[`€Àn¼
1oÚçø¯½º|Ì7¢ûY¹Ğµ¦n‹f››™æÎ"~LE<±f6ÛòálêOÓ´œ©ºlwUå|’V©?ï&qÎ¨š7â{8ÓTm±÷ÍA»Âw«‡Øl’a¾ı#%û÷S]”ÿ´
¾WVì‘G+Yõ‹ !Ó¤õõS—EÖÚ#zº<8u‹J}Xa–Šşø jı“í)­CˆÇnÜÆğ¯§ŒyŸlËô“¢Ú÷CxOzi¥Kœëå$û1E…Bà ÒárÕ;áÒñÌÛ—ˆ(‚^Š\ÈÊšµ‘­”@ÍS³±P€ÜÂSènä¿Ø¬ˆx-‰ó,ö¾1ûìd]5’ÄˆWvŒs¾7à ŸtÒûÄ³W«÷QĞ­ú¬€HÚ›¾böFÕi¸ú9÷“«f?güßf„#yH@GÊ´µÜ9 “rÓŞí<w×®Tx]ƒ<×WıÒ­÷6:à2ˆªÖ˜,›~®œhMRlS¤oáò33-f1‘œò]Œ—o7—OlØ_JYÌR‡˜)%5Â28°5/…_Y·›ÙÃ[Å½)Œ•eÃÓ)b]ò£cÍ„³“¯–NÛıÓ4¼~£kf<ò5}à'6Ø®×E+ö3O ‰PĞYaEÇêìeWï¾ûpÂ×"¤"ÖØè~ã%ü_f?#›³¡ªHÓ~…Û!HDü3ül@*î™wh›u6b/=Zı©F#à*4Êİæµ-"=øúxwh^ñ	e¢ót`sìú¾9x\BN²Oºà€¦APwitWv%ä¶lfò7%Mú¼91;¹zõ–›Æ=bI&ÕÎ}!è«Åd+aÿx1ÛiI)›o«¡_+5tWw’ÌÕáÀõ‹lÅŠ{Í&ß<¼ şqÂ'”,ßûiÕÕ1}l'²š]1õş\…lOê*èàáÎ'[dĞ§ø½o8M³+£³¸Y1‡QgkvğsØ@_o%aE%‹¥_] øİ=Á¹Ÿà(ÓÊcmpÇu Ièøi{SxŠ.Zµq(MÁ¥eğ­¹mS‰qOÆ{´Ú×ßA4Ä§€ˆPô]ƒÊ$´s$!5çX~>.u z«ÇïÜ’wí\©í½…Ü‘Êæ…Tùî7ùñ•[9ÎR‰’™Ç´ôøJ=_´æFØø²’t¥_½€'>¤ôzšµÁ£[åkû”[—CµÚÄŒy¾ı>iøµvP+{nByÄp’&*†3ö•Š’÷xŒ¯teU5İ˜Q ã*ÂyÈ>¿&O'yOWôæĞ!éóf5(Õ‚ÚÇÍÚË°ºÈ]‰¾*©;ï?î¶/šÚ}±‰Ú¡ÓLÊ)— ÖÖæKµsÔYÉÀã‰ ]FğÅ"¾°ı…{º‚÷% r2pDp¸RRõ¢’ËüDˆˆtÌÎ1Sõ#/Êî§ıÁ @Ñ{Ì‰.CˆØgŸåÍKG´ç?$¾äI€ÃP—4Ş	™"0ò ¡{DëZ%­U–“DíÄÒ¬:l¯'W``˜•“qö·>	íÕµ&= 2?gá4ªîòng$6!1´¯¼¸Î%ÆÛ‰JVTTÒÜ·k[´òşî3=ÕOÌNşã,-dĞëüøcÈ¶ş| a£kaL«`áˆi.~!§¦¹Y½”ÿ‘mš°“ÊÓösFa²Ãñ	äv}0)%¼jFÄü•h  éƒâ•i/¶®TM/4 +mklêÜÉÒË´ÀÊüÇÕ+§êµä>\›†šíšV€û¶²r²~0¬À¼|C†kL¦k½•%=›‹‘Sã¢şu\.(m°*§Zì>Üî†˜èõı6Gt`¾¹ccQ(´uúAUmq6YD 2+y_äØ¥Í¢ÿØ×È€éƒ;İ'*Êô¿²÷H;gAÅ ºğOµvI§µí¾z¾ùzûj¹¯søs åß/ğİXzgñ>v2"É’¬×tP¬£ùéœ4CÍÎ<fó§º7ÿúm| Ğ™gYSâZîô‚//aàTQ§Êÿˆ$W£ÆNNë2ËÊëØÇù¡JŠ»UšzyÔ³¥…F¨.øÁ#à89Ò‹µ)¬Ã‘£T<ÙÒ„ß@éT1šÍ5&A÷7Zäò>`ò5+k\€#®¶¤h˜(_V‚¢:h¶2z.cw“0£lÉ;O %Dµõ#Rg­íA¶6:
%a¢Î]ÍçiÑv_*Ì!uVdRD„hûxÆ9|Œ“.9j‘vûVõ#£'éÚ_Ê`¹$'æİ¬ ‡ ¯7ª×Ì_¼OòtXt'Š™}×–Nôã·°ÌEyA³ôŠkå“6£©ñ¾COù‚ ë“ï­&bnµ¹yZCŸc:'‘Œ	‘â2¹Äûzl 4œh‰º5PÄ"¢ ïa¬£®gs!atÜkÒ¬KL¼1¾U,5 h¨àµ¨)õV­JÃ¢)¤×ÊÍKAĞBW…Ry1@ÆÕ<Ş R5ÊQÁÍåJ¢0ÖT–]ws)(£cØ-ÂÌJ~ç!iK-{‹4Ì^S–e2¡&wJ|ş|=•L5ÿXğó„Ÿ'Ö*/ÊB^¯5ÍÎ×~—>òÏp‹üé–¸MU'OA˜Ïú-–!òxİPOEİFsrğ6©ÈÁŒø‚îåÁkÄ`ûì
Æè]Q1E¤Î³Ÿ/‹¸ŸY(>KÑüeÎ«V nsD¦xMĞ™Â
Şdgi†ÓY	xtYû-{Rp¸€n ‚±ş0ü£Ö@0Ã~rØª¡XœñZªn„[Ğ·5˜Ğ´(N˜¼F¿ 3Í¾Q*Nç¯lóÜJT—.Vf}dCBZJ‹æƒ•pãÑ%mİÏT,DÁiïqK:¬Üíí,÷¹?ºÀKà5ŒO·W kë&¯4aqß,ı|¶ ¨Ïr{¯¨+ÖfX-\ScKq	H QóŸŒÕ¼Ğßœğ÷ß’ilVä‚Äb0u-Î¨ÿ`ñ¥0nÍ?tØ[5kñbWlÃ¡„×Š£³Ö `Á­‘ò–um¸oZø©¡™›;Š¶ Uû’Ÿ‡|-üç§ÿ£’D&¢ü˜	l®¾4ÿ¸Ñ‰)d}kÒÒrŞ81î¹	İÁ	”WÑ£UvÂ¼»›‚:ôÒÊèÒ¸'£×¹m—õ+Û!U,ĞµğöñC¬àxÖ}tub“-¤ç°uğ÷)ÿ´M¤•Ñ@.>e´‘ª•bm|œ:Spöœƒ/ˆœdeÓÛˆ=­^ãr•©L3·ß}¶ŸÙX!Èû¨Ë˜ê#¼áBª<Ì],v'çö…Pàö@èß†u92åyÒ± iÕ¼‹SS";$Òìãñ$f‰w³D}ü>ø[eWwÙÅ9ù	%£´½ûÓ"9¼ÖX9÷Vcm¥ ïaËç°É×›‹ÍÜ4¼Kÿ:`%qªÜ9g*.ÒésWV'U)³ÃH­÷o…0ô~¿ßşîÀ9ğ+OBDŞGÀà¨Ë¹í,4¡DÀ¥aCÇI[æ	eioJÏ9ÅÍ3‡*\NÑcÖy/¿ok„Vå—_šZİq62Éí¨Çö³O5u'™aü\±Šñµ±g5?ÎyÒ@Â6t±–ú¿²}CÓşœ÷ş.4Ì‹Z}ëÜÔÅ*,Í´m‚î0tG­Û…èmuÓfNä+ôò¡©OÃú¾<º"]x'ª.…’¢h!óèq1JÕ|à"%½k…³eŸ
vıÁ·ª,:qÑDb(é×¸)ËaÆ¬O›»J"k^	.›BO)®X·—šâ¨9ø. €R/Âå¿¸£¶ÛàjWnomÿO[­§` /?{£º¢~«É¼:ÇÓsÂO­€ƒ“ ıæëL†”¸ hPß<Ÿ9Dikç‰Œ±<ä…YSë0¯øª²ıÄØùØ©Ö\+Ø
FJœ¬]ßÕí
ø‡(˜ğilrÊÔ6¨ƒyA¯D	ÕÒ¤{2Ïn!¯úØ‡£ wé·7'9xã“š‘ñR¤Aö‘{”Ríd1ªe~Gi%³Oår)¨/$ÇÏ¨iü+jK¹ØŞˆl|L_¤'<¶e— Ùê^:ËV©r@¡Çœ^=4/?÷QVEë<À_•:V	Ò^_šmÙ`DM½ñ‰{©kz!%+šØäÛA°ç¸‡	ÿÛÈÿõ­ÖLa<•ã1©z¾7xoÊı±¦Ê4®ı¾´«Ü™Å»ïİ-4ciVfBE-@|VÚdOÓ	MÛnï)ŠULtföì!Ìza89Œ²"Ó¼}ÅYŞÈ¥ÍöBcÆİYœñ¼º~´$bSœå6QU=h:Å°æiægÇ1»Yº@¹vF%$oœÙïà¬êÿX—â¨„dFèa˜à8İÙâ'Á)uj?a„9-b ½…Æ¦z›¶…;´íıÉÅ†àn%«¬¨œMLÍ%§0u^	tq@{0öOüfPq#%í~Ğ%È›†Ñ¯†p’qÉDÅ«İ@$=X_5½¯—Å©‰ÏOZ/{Mh^qaf¹&,ğ®k¦f²S›3Œ]œÄiÔòïüºqNÉsÉ
šxf€Eñ+±ò´céL­m¨E{ÃZ®Ó&tP;uwØÆŒó1`OÎ]]¶<?÷æz™äJGäKÛwÃ±„g¥6=E`‘¥‡§h&Û±ZxÈãú˜Ÿm‰õPÖÀGÇ:ƒÊÉ9¯è^åwÁ™l9–¢J8Šï¸¿\>Óà•.¦ûÏ°dùj:ÌùÅX®ÕæÅ$dÚ³®§…»'™şóÜıü´ÕšÛ%Ósp“"pğÜ€\r»àKâíEĞH.Â.c*ı÷ë0ŒírĞO®p8’YOÚóXjYCs·T"k ä£‰Ä¥ó/ Ee“[ìøå—ú™¥‡™Ë{º[Æìvš¨„³¦ê8àµŠ“<üëëÖ+C)B‚Xçï¦{Ü˜”ziÂÀÛşøì0¿Œ°;úÜ]ÂêE~;}Ì1UÜõ©t\™ƒÃ¢8$Ÿá•}×ÎFóC‘7wN„>Fî˜'’ƒ§‚Ñ pj·¾5Fè_lÒ”
,JÙ›¸€³îNŸGzÃC€CkD_õPÎxá‡CxlA 0ÜQÍ˜—êTÈíÍ5FÁß×ÊÍâö”ÉªØµ8”1“PÍ£ÌLM‰‚Q7İc ­•á[ÑJ¢ÍírW±ÔÒ2Ô›L£…›¡,‰‹Ûi
x–bƒI†GÅ>}†DÅ™ÉC*„/nÔFºbøOĞ&X°Ã±AkR‚ú
4{7ãÀ:Ú0é˜ª€i® ÑE‚å]Ğù@OA®¢x sÂê¤±§n.xp{Á9ÇAã)¶d—xƒ¦ÄıÿòÍ€zW‘†F_`u†xYüÂkÀqŒ^w½ğ©F¿nØ±@Üíóß6ü«j5³ ?:“¨ñ´lÍQÑR½cp=<ô?	Š¥Jè´W?i„üü¤	E%8yıc…MÁºÅIöØ€/…2ãúË
¯I€çW–ßë6ïş¢°õaiÑ‡5rÎá)G¦»gEæ$Tê¹Èÿ7{•`:ĞÀæÜ‹PV©¢¯4ŞÜ„×E$È·aaáÂü¥fY$7’«y"d¾ë¥ZÑ™½Ù2œ Ş“NÖ
zÑŸÈs©õ³“±§ŞŒÌ©¾Ÿ}
38ÆÉd AÕ¦#¹åkî#¦NAYeßF–£ƒø)F™l2¡bTµó;¦ÿA:ªÆÑ§ĞJ­ˆé«id´tÚÎ-k^¥–¹1–/ÂĞå­¾ÌŞóà)ä£½Xš2*»ƒRAU¬PRç¦i )|¬B® Z‘Yñ[˜y‘J œ¥¥C•`3¥ÚoøcõËUıÄBÛÏn}.Â+àõ˜Nv¸P`%Øşd©8–7ı6ºmµ€Lo[İÓ÷× Ÿ’_ƒÿEjõíª-WÀÔ*3×ÈÌÎ‘Ä=:gŞ4ÏzádOÚÿ¬H8:0€aĞÎÑ¦ÔH˜ØëÑOvgd}ß;a-O²ÚkæKïOé}‘b(jçÊ&^È…¦ˆÉ=MÑ]ë»<=;8"TFĞĞYÁ*ŒugÓä^÷Ã‘Ã‚´
Û¨§k¸çDwæiNÃì”§»ú@7'ˆ[‹ZJÆ"W†¸ğüœ¨’f‡Çğê®ö&ë¡³úïş«I4	ÊÏQCJÊlõƒh«ƒéâé	Ÿ&ğGÏ7ly5ì‹:ˆ™–ÓëÏ,8Ñ¹ )KâÈ6Ÿ=¿cqè¦]šU…æ;şî3ˆÊ’¨¦	’’Mš.L|£ÚZîÓH2ùŸ¾0òòÂœa<_>Š?¢¯%/#eŸÃ.a=èX)z¦€­©¹ÄX,ÜˆRª:C|šzß\*%š7Û?#©!!jÒÔÌœ`™“X$ih°v0î‡ÖÆş3^óúÁGjÈEH—È/êàciŠB ÎîùÙ’t]2sÀq×–ß*Z<Ë[Ğ¦¬âp‘a¼ãlûG5÷]…s˜e¯ff'¸2v:*«ä4¤ „›W£c(’ïd„öÇÚÑëŠ`˜‰à«œCzH†¸àñõ­õª‰­`…aO{|şáPK‰•ˆ¨~Ë;“)ç7¬*ƒ¾óĞ„†OX””F‚`ı¹„`t>Fg$ßïÕ¿¶XìUh©mWµ2›—Vğªòê)öiy0<a@²L™µmñÌ¶.G²Ô™”—QoŒ‡Ÿ*í=ƒwgÇÜ£] ¶3{¦NPÕ6r±ù.b~{Ê“‚—Ó5][øeç«Ê²GÆÑk¦ ÉÛW¯š[eL“šÙR­Áİ¬¦&ÜònuÔØ& Èê¶ÚœßûIàËÀÂjüDÖ'Å æ =Ø†»ÍËTMÕ¼/ò™çû5RÙÚÚÒHL§ØöMKb2ƒ¸†¥óšY;îõ& ›.üa4ü™xt|yÃ³-Övy¾R-WrèÑtÌ=y‡i#ê¾+‹íŞT ÇZøg[±Eeğ®•0;!“»F¹í4Ûè2‚}Ê NKö%;ÚûâfiM=@b–¹O¤m™B0Ş·£çLÓª×Çé36Š˜ú¹ë´¨æ†Ëãv|>
}Îk>CKm<À
Ë‹”ü§_`ĞÃÀİX£¤Ş¸5ëõÿ¤Ğ|Iıñït¹Õ”Wóg×û	?²ÁJ€)'Ùó•¾Ò¸9iì5u×”#Sd§ƒ¼øw!œèÅÎÌA…îø²CX1x¼û¦¢ÔÎÇI&û§Xà©¶Ç§±^ÿíö{È¡-¦æ˜àGğş÷ZË_9÷‘¤y„Y‡j:ÚÎ§#ñ¥˜‘eó:æ¥Ö¶p½Î½´Òx˜”B÷ÌßÃÑØÆ+*ºõévúfwº¨l~‡› ¯P£:üIˆŠÅbu¬†Sr Ô½äG~qéÛ={ÍÈ"áu_ «‹†£3Ã¨‘Ÿİ—ƒÓàë!¯2OƒÅ—ıZû›ıñİI"E›ÎÍâ»0µ@(#B©dJÛÇÆRcu’\RiZÎVüK¥× p`[‡	¤ln“Ã›âNöëdäáãíár¡™ê£·c*sîLLsGÓ.Õõ«~îÌŸsM†|¡^=u6vÒ&øäw{…ùŞ®45Â<%ºa¡ç1‘Ì•PÑk¢63³0€=	H×e9ƒ±¦æhIƒ…ƒ	S¾áÜjxkäK_j¾šÿè9IóSûM“ôy…˜Õk¦ß¢úqğñj ÕF9²…Te‚Ÿï"L0w…º²É9šº‰%ıP#¿n³Ù…Y¼ö±±vûMvˆÁÃãĞËF½ñ·Q+û~Â›zL6{y"Õ&7eyÙäıùõ•Gni†Ÿ”Ú¼&w?i£2]Ñ'š›öUìLÉ/ˆá”ÛVïRKÃˆï_Êíà¦(Ø;/v¼},@H[;`~õÀ)× F‹^ôŞò0İïpë}ºFpR:D•z#12Ÿ¦Èù0…)ğ•4Bœ2÷»{Æ,ªÊÅ#»ö-ÑyoÉFÀõë¯ş˜ğÄsÒ·hfSM_$ÄY˜¢ıø÷`æºoœK~^°2`¼aFãcÊeÙÕåE»{å=NçÅ9¾{¤-&œ|·xwØ~+b¤tkÄqŞyÅEÃ‡±ÿKÿü3gÃÄï«ËD±œù ?µšîXC…‹™á˜_f˜êĞ8„ÜaQ¨1ßÈ½yÓMİi¤ÈùĞ£D:çÊ41Ï&*ª£†sT£¯³£îç•u Î¯*V•†Š$ÉÎIŸ)[Q2W#3mES^MÉˆü¸’« ¼ëFã™
"yxÑ<ëtºé½~ÊÌ¿Õ6²ÚûsÀL£Ï|û¬¤öA:ÏC©¹Ø4/üÇ~Â®uê³<¥-Q`æzî$9‘;›Ìü™1 TUúCñ2z¤ˆPÎÑõçp‚M¤Np£íš2ãùP›l {dî÷ğ€òÍ¶İ°d)réõ ªYÇÃ®fnµÓ},Ã´Ñ³ó¾=<u%:H²¬†XoD›~l…'0³ïø†ËAÇ¥„Àùø†zÓKDŞ\kË<JaÀHdÿ…©| H10‰¨Îx¡Óz!Rë%9Ö-é±RXí[ƒG<š¯ÈCæ–õÅOˆègİê~jM$òÏ(©Ú» mi^Ş¸' •ØıèIï!xHÂ‘kkv9°ù£.Ğ÷U½­y¡rrBnªJA¬Lé"À2Ç¹5ÿîLük:Ê3Èib ÔÂ®·k"É%$Ğ¢¿’o·TQà§y‚L¨ Ğ<%*Ù…»àúÚ±_ªt‘£®©jQWÍ8Não¸0Ù-ù˜ıc'ÁGï¢w„,^1gn•†¾G«ç7ÍÊ‚Ël·àt‚‡>aœŸ üñq§ù½øeÏäuèSÎ‰È[t8´ªZ[%6şbZ8sr.Ç¡p¸)|8œÈ—\¢š8~ç_„í•(¾‰ÀF á¶4ÈòY¦µ¥jK¾Œé¨¢¦¡¡İæ©Iê4RuÈ/~Sêi*ˆ;ªİ.”óhİ:é‰€ÄŸıV¢o‹Pø‚ˆ ôÜµ¨5€¦ª÷@-4Ø˜tÎÚŒÀ3ˆ!ŸİxdŠ{éµ
úh2ÌI2nfşSªÈÇ¹r·VŠ˜A!D³h:=eÓ §kx™«áó$‚–»<î>W•ì.ÚİÆæaÏì5È±¹eöÃt«óvÊoe’¤‰pX½ÓèÃL$ŒAˆmü¬ºgWËQHUÍ¹;É>ï!Ë4u¦suvJøTÿ“äVµ:·Ùk0¾Ÿj)¬½ÁËÛÒá•`KlôØx
aË{A).;Z'~?|¼û j.ˆÖCº1„{ÒËŒğ–«DR‚üBMÈ2Œ Mnq®	åş³óş tæ{àIëš9zjŠˆÇL?‡È„O¦‘ğ'Ï\i"š8Ú‰5"<HXªëşßø·ŸãZÁ•](ıEàòº!	³<İÍ
¿º(;&"œIz(²ÒR,­C°§æ´£(æ2»[Ógx<¾!Çh€oãy×·Ñç5!¾˜¶¦º0±‡]j~Ùk›¬ÈïçÇ6}Y€uB+‚)Ò‡{+':“ãp-¿¾Îd"™«Dİá>\…D[§Wê`Ÿš3ô¨Ñ—-N9}áÄ`˜øÜW˜¶fC5 ƒKïzX{)ø¹ZŸ²3sr×Íà 	¯ÎÒQ7¶8+ß\¨T <ÖÆØŸ‡Û7§glš*s´µdö ÓlÀ„«@·Ñ‚–«&P\ŸGEñ•¾$ïİÒëÌ"Ÿd*:!å0õ%3³+½S`|*J$šWÙ°ª²jJ2eÜ}n¹=,~ø/X£„ü«± É[Uø*QJçGWH¨I9ô¿Ÿ{^¨¦b)75/:~f$³ÅQÏT|ÂºíùğÌ§hKú½mŠuJhYu…”!œT^=“®Ş	¦Ÿåû}“LäèÄ7Ÿì•´¡!y€ç²ÆÓŠôPÔüR˜[óYú`©´ºØ^Ï(,«Ër¼&ƒ¹Õ€<"RFfMÆ¨Æ=PkH6»JÄ«Ş­êùõ‡‡pöÚæƒÙ;tÑñùcõå8Ÿ)Ö±ïgéYMñ>ÊJ†ç£kıÂ¸rrz ú‹¼gˆİ	ÕAÛ÷AÉª_£Ã=ÿú–/Ø­^<†™éwlpÔÈ9Ú9mKT ¡bFAÊ(±%d-ß’­B¼ŠV¸¥·¶\ ˜´oÆy~ÑI;¼Ì¸3ÿN¨G¯J³5â,îzÀ t˜Ho]ì×#ÆÀå"S[XlÕ›¦ÛåÂwî<ÍbÎŸ®aSˆæ¾1ÖĞ«ÇÇÙàİó…ß2"²‘5Æƒ•o‹-l÷Y¼ïòR˜O¡“¶Òå;|]|+s¨»¨œ“8â<‚š@¤™4
H.m4¾ŒÁ÷A@áL*¹³"M36Àªa$§&Ñ¢‹ñ†¥ûŸ£hÃÈæLZ×ºŠäK=í2x{9í†¦•ÿû©%Û5jx—Ğa^¸‘H)! vBCş× Ìæ÷ü0ÌÑTÊ	å’’®F¢U]Y‡y¬ºb¶¿Aúœ>mQ›!Rfj-Ó™¼
DdæK*Îõ€
`9iKÜ±Íz¡Œ7Ø¸8K–%´‹ÅH%şó­£IÆ”úœ¦¦AÅk<3Kj‘ë€5{×Éòğ>ŸvW‰±ÉÔã 'RtÏ¹'/ñØT®8?N`Ù·-ÛMHíÒN„ù#¼tS±As/ÔºÂşÖÓq'o…)ÂÑ`µTğÿØ»ªQ‚A P/di6œº˜±#Š~'7ßé}O%IôNúè'#)µsËÜF –„™‘ñD¨}TÛS¾«Éÿ×>uÙÜÔø˜T²\×‚¶Ş'”Û¹ıMÏGÚ7O‘Â ÓÎßü{^¡'šìÂ&Y$és	1â\úŸÿ¬'|ÇYl[Í‘,ö"•ÄÙ¼ù¹.Jk±¢‰êØà68a¿*^!Ë0IëP¬Ôdé°şöĞûR‘6æ•Ú¥”´Ç¼<šì|‹b;et_Ü÷HŠ¸w`œAUò" xlJëŞ«ğ ôSÓÉôr_Ra@XŒ.·‰SmóEç·+úì
ÏÍv­¢;zt­Õ˜àúå –ÜãåòŒe²V,EIh	È=Ş	?$Ë8|¬û ŒÄT¢ˆòºC$@Œ{`®‘¦Å³÷s¤Ê¾FVäOk>¬È®™Ğ	Õà'’Å‰ıé=÷îÜ5ĞÍÔS Wâáz}8Õï™‰‘9‡à€Âº=¾ìøßÔ;z33èRï5Ğxb[H~£d¥Qé¾çK:vÈ{¾Õúÿ³(¯Ø1‘Îí\ñ3–eƒa´Z›:Éˆ­“/al¾:®’’ËƒåÊ¬“~ß§›zÅ¼(F!,sC¥’RÄ5vcûfşãõğF•†=7¾H®©.#ë¡ê@&é;=‰Ÿü4USÜ€ñÓ³N„—c õd¸iw
Èé%Œfvÿ¿xš¥{„7r79*y`íˆ§ærĞ|«‹€Í`aÍæšşÁ>“, §×Ún£ùƒ-Rcú¡†l5 öôïÚ4ÚöF`OÆœ :kdYpÒT
ÜyŒÆĞ«º.Ó`¹%†_qšÖÆTÖ|ìš³"à·ı ü¬W+{SÍP¼¦*­ïãû¦JV¢fÇ‚	ŸÄéh‰ß=¨Í^yòüÙ[ö¡AÏSQ§[ ­³“zbM\÷è9UÛü"ÛTx{½iê8óÀàhÈQoĞÿMğŸb¶6fç:Ee‘ĞÓñƒr¥©?ÃÈT¤Ô’¦Õ¥ºÎÿí3÷s™G½uáK(s]-ğGy*/.¨Ó)Eè=†[ĞœS¾údìsmØN¥aDd¦ˆ¦•ÈÁ µÒŒ÷œØ}Ğrz±š‹u:œƒg;E±@wÕ–P¸«Ğ,óè}?O ‰ã OØè9Çò‹(«ˆ&ŒÒ*¿!g	‡ÖÃ85”E\—;L,º®¤HÂOïYOú6ÍÒË“BqÚ7â—gŸ‰ïn–DÙÖuİï/M©Ñ6E:©bêgQ®¡NÁnëÆR…B°FÊhu¯–·Â~Úùõ@sb÷~gÄÃ|úHkåïºw_ïİøÕÎz¦Ÿl½gˆTÙxÿ¢bBË¨¥I  ßA°úA+d:+)Ÿ±³öíq†psRD*ÜåÛ}ìêwäL¨/²ömmÌ˜¥i¹ó•/Õf’‰uòË÷ÆD˜—´N-ö‘»éÔÀõµV*€ =„äÊÆştÊÖ
~Pç‰$¶Ë×ïôe´ÿWh¼8êpÌ,û¤“ş!‰‡½÷D8Ç‰G¢××]É†jÒu~g¿p?Úg™üL°«¥dïti£ûóíU¨ğì¼ñ»şµ •+`ø’BŠU8¥ËÆ–} Ö_¤	ª÷l=77ô½T²£²i¥İÁnÿnûlı-Šh¬„²»"İÏP‰¤ğ«­;|ÎiJ7A%tµ‡°’|¸á!Ú”4:ÇÁ(”7fş»¼:z4Ï®šI$"©íå´gôØ¢³şÉßQ”æŒõ@AÚf¸®¥¦òşh®ùA«(ˆøšzäæ(áÒS@²ük«ó……ì]ÔI Lí2•tmy=tíéVÿy§ÚU€ ‚ÕóÍºìAÔç»>¿Ógf²õlS*-^;¯Îó”IáÑ¸|' öª˜’s%adãT‡]HÃ¼~ •ªØÂ)#çrb¡T_–ÅKÌÒš\^tq„÷m˜œ/(
€è9ô)c´}ò(î0›$İPye‰ÙÆù·Ç6RÀ²-q™:dqÏÿ³¶ÜèSM]/`58€ĞPuö¢—­œ$eü¿»µ7Ã%y®Û­Ø<9”ÓlÒŸ¦c%¤ırKhünjhz	«ŞhlŒ)Du´8€ÛMô²>ÈïÁ,ÌÊ.6a=V$šv5”FÑå(²éÔa¸š¶L¬’È55p-Ëø÷‡‡.úHÚñ®{’Ò§i'¹b2èíÒ!íŞ¯b‹Q)µâYÈn²°ö5bÙ­´êØßˆ@R«tnË¡s¾¿|}G:)ŸB¾ŞÚ~AÙçJ¡¨8“H0|Ñkr¯§ßb`vû…ÅFK%eşŒş‰¶G0õÚ’ÑGÍÿæ'U6C"HœsñzNÒÆh57¦+xïicŠ-AÆ¥xDô~_O¿cà‰%Îİü+»|lĞ˜ÓMS±… Â~×Iáê[˜;şMñZˆHÇ‘±cØ¨â@ÙÛÆX:Ê  r—6¥xS¯1ô¨}àÃ¦4úC¡r¨B±«4Ù=E³–y8™†¼²Ö`ªès!òC“åÔ¿[î9o‹ÆwtÃƒpÛV€©ú“XÖš–ê©`YAºÚ™o}Ğ	l2yFtD? ~O=Rn–ôBÀÒ…GÓkZá€¢ÿ0¯ÑG'§K¹k˜§Ë‚ş_go¶‘®l×ÿuà³~ğg’¥+yf®–¦ÕYóoÂÛÁ+úÙMBúª¨,ùeİz+cAğN‘>0zd)DÖïï|‘|ÖÆ\!B¤]„õpuõ½8zƒS×s<pµg6ıf\Xv–{ïÓt(§‰RÎ)_¬Ïù¶‡¡ãpéÕg8`mŞh]UóÎV2ÎŒ¡™Î2äzê1¬°à€ç‰ÊÜ£]AoƒØ{Â¯ÃøıÌ:ßı¼íÒrÏÏŸòÊYŞÆ“Bú4£sÌïH¹Á93û6y¶S+(w?fdC\cäŸ·›!<¦ŸÀy’±Ø~å°ämıüìíÉIşZr‹<jšÑ¾C=1gÎ³(ÕÍ{­¦²Q;ÆğèV¿0‰_Åªö¸h [Ã‰Ö‡ÎizêÁÄPµ%S¾fŞ£šƒ`áú—ê©BI‚``ÑÆÏ2_SÀ/bü•—™Ë~_È`©–YéMénsW`aùªÛH§›Êïjë— RòŞWRÓ=Ä½¡j°já"%Ã|UB.‚÷H×¾6y}D®IŒ¯ëxyùáÎĞZ+WL¤~Æµ}o¬W@É¯u¢¿íº¹ÎòZ ¿€‘^ZX¢L‰çJà7Œîz·Œñ£êK¯[Bÿ¸à\QÇj($Èğ&ŠGFÓCt±Êu6€6N.ÚaB	=:«fåÑ¦q]kóŒ¥[5ŸÃÍµëÓY©—×ÿ‘—[ùÙÌ7µ™	óÛOÕö@]w…yi*Ÿoâ‚$ıƒËƒ­Næ¯zyÎ|ùş‹ÉÏ ºvØ”¹-!ì×¬¨/Eü"W+P=Şs˜eB‚ƒÀ®ËÜ¾¨Ä6aç€"	°ó+´º@ÑíRAb èö™Qªú¹Pó/b	¼~  F6u½‚„›W—èqÓ2¦€äİTÆ‰Wû;„nöj‘‰¸Ã×àMDÁHIàp%zi`äÚƒ‹Ûª“ú;şçG/¯ø8g3‡ëúzôòi©zj5+aìn$•1•¼›Ø Qèòk.î²â™lW(ö…Úı3ë£%Îüé§Pû	ÊŞœòÊX¹¯8#,¦2+DV"ïè˜EP9f$"A‚1*/ @z/4AeéŠœT9–¼á
Ú}w$ªTPéé©D9Ö=¹å™¡£TÀàõ%<-ë¬Á›„ dš8ã>ñ3ó—vŸj°1 ›)kâÕôÉ9P*{¬Íào|fdÙ&rrAÉŠŠgŠ…D(íó³¯­@éºZKËºıòH«ØØÑ,W/^;õÿµ+`ÄÈkı}¸FH”ç¾0)ÅÑÙ-3í÷¬IÍ¡GŠª.Ç‘â´H&ÁvU”­=éí£ÕR*©¦ä0ÜfÒQÄøÚ=Kå}†ÕpÆe/EÊìOÆ( %K;ÉöWjy}ñRà1"°`wû„“ãuå(X¹ŠœKê¦‘Ä^üØôX±åİ)iïVñÏås1%
j=ôòj¹"ô¹Z—ÛD¹~¶>ù ïß¾’¿ÛF³È«  í3ÓJÉ2†ëŠßå á¶¤;j™¨€>pDé:ÍÕ¸eNh –
2U[3‹‚3®'c$K}¨s…?MµÇqÔ, {Á¤ß×D‰,se­~rì×æ¯{yIY-4‘&àqÀÆ5öXµE>’J)’4 gı40ñWêÓÄÑ½ÎM5%¾¬¬½zr [|Hñç:Åçƒ`2ıå„ó”£ì‰õ6lZ¸0±3µkY’xüG›”éJDñètºGªÑB2|KZõµúnU¸µìİî ¦†^öĞñŸl2‘ìçôöÖ(g¯œ´œÄ-† 
¥(6vèšUEGÈÜ-t…V.£P-ĞŒn³$­áÍf¯îTÂñªdÙH+à÷`¸‚w_‹lšyòƒÙ±MiŸ„uvÊ_ùûâ§“ Ñ9‚ËO&ÚëõıØ]±Í@8Æ6‹ ÈˆiöA©«Ÿ£ ](æ™'€­m°µÁ[1l«¿ƒ?b8$æB_§VÃwŠØº}GÑó Jú*sü
FÂ¼Š\¿f _ã³úøçèzÜÁ¨dPa}ÑÏp¹ºäÑ¸PZßè[|ÿb+t Ê†âÒ&.7CzÀIáÓÏ!}ÏÇ%ÏoÇ«ß³¥µN	ë:ñ¸S®?éW[ 
‰–ÜÉsPZ©‡¦Ş“'FoI‰ã±³ÍÙFÆ—PeíèFAïr˜·€\:IfğùKg7GéKƒá¶ˆnà³—p­ıåïİ<y«´/È3Gñş[Î¹í‘“æÜ¥gŸhÉç¦–*)Ï9[Å55’e,^Zú³òœi‘L¼öË±`§‘©ÑzóæuRu:Ñpü¸™™f÷ÆËÏ‰Õí{~î—”û.6ßá¶ËJÑ^<àÅà«ÁU÷ç+æcQQôÂb‚7à)°Ö+_âmákã3îT‰?=>VÆ0Õ{•y$ïÇT’fÃg*
êYÊ|ı|Û¥½©F}>NÀGmfÚÛv­ÛVæ—îñø_G˜|µZ_pÓ«.øÙO{"¿,ÎNœ¦OVŒ#	+SE†“c­L{lĞ»¯¸™C©.`J¹³×õ…ñ†-ôr¦…Øn's¦Ã:ûƒ%xù•…B*~	 M¼Á<t.¾H˜£€¾5w’tœ ŞÈ8Ëq³Ä÷¾Dğóc\W€Ô8kl±‡µÍÕÕ—ÜdÕ@i¹ 4EøßR¨,|Fşù;²‰`bHÒ9E>}¬‰DÙÅ¸™$x¶ÓÅP|šÔÊå¯{ç)í-â›X¾·|d…/\ñ(*n4I`YR$I££·êğmWáóp¡ØCí*Ú^5Ş6Z çæ-.9ä5dŒô€]2zœNÉv$S'Hãº
Í,¢P&fõ5Tù9â›¿èÁ8zRfªfÏk\4L—=kÇS^.³åÉzàãF>zãT%w‡{­—NşÒ^.Í‘h£U€µ+xşFóUj¹ºàaã8XZ£“èQ!Zšıä< Ñ˜­İÌ¸}ñÉQåmMÃª€ªòéÓØ…….tÕ:Âùè.˜œ\SŒ&ëw^Rš%çgÂ´r3pøZè‡;-G#aÌˆ- ¾1w]‚UÙ¾»è†)İm&z:º_:¦6†×»&lÇğ¦s‘¥bõ]íxòá:g==X#nîQ9G‚6fKø…:ÅËæ£Æ(”ÑòaøJmè–ØÈşªO C©ø¤-SK‚^+`´B	BšŒA ¸¬ŞPœˆÀX İá?şÃ"gøÛhCÎ5êÛq#ÉDéf—Åæ¸ÒËö8bP·=Èz\Ğµ5ÌI¾ˆªRîÌyw¼öÍ;¦ÊÏ_áî`ì˜¡FRn]kã‰ ¤'êV×[ş3áq• »r¢L
ÓÌÆ¤!Ô|§Ó«t	¢~šo—ê	”a6@+ŠkÁH†‘>97ƒkMAQ
©Ö{ÀßïL(·Çà9cá‰A#\Iä3aÚ:ĞÁ×Pm‰NöÆ/ˆßpııb5üõ»{ÇÖé,¦ùY0b\=óöõ9•÷,¯W”©¾:|^l{<‘òÎÎe”³)-ß!%ÊË?²‚«”‹ şĞF€l=E"…b¡uS ·	Cr—ÏdTó~1àHX„üöµ3°§‰ù†Á¬äÇ}£ı¾ƒÔ"`€Ÿ÷^62`\±'øİèŠÅ`kıòÒX~Qò.'&Å>·eò‘Çßÿ'j¢ÔÍÊoôjküÑÑœ±C–¡XX7yÙ2´¸‰¬GSí:Œq¶|¦2U"s‚?ÒXµ‘)è+ìmœ#ÅôËuùàĞD[7è3ÁP-«‰UàrŞq|Îò26çíN	¸ş
±P“- ÃÀvûzæ¯àóyÁui§m0¦'‘vlK˜»JÚÃ bA^:ZŞÃÇ:ô)ß¸Õ±În]ˆæ?Óá­Ù¶LÎÏİPÁqF&W‰Ï“8À¬*UÜ4^`Vš£°/wÚt<¶af%“`ªßh 	±…{›îğŠ™ÎÖUõ:Wıš ŒVµ‡›Yp°tAëƒğaRïôÈï©Km"Ò÷@jX[s¢vŠìîM¸¥‘íı§@¶0˜”1htÿ¾õQ$ªK‰Ø9É0÷&ÙĞ§1G×Õ!•Œ1—Î~&mí¦%UŸ£G	­W‘Û¤#&QöÁª™Ù–œ2ê´úôÜ7†Û”ü¶Y&êM¿	İUTƒD³ÛRòp©!lpEc« °2|û'¯N“7sœ“z<~î¿¾)à¾&ÓX}¤÷GL4Hk9?ûéÓ°Z¤/¢&Lmİñ.«kB®xzhà“ø>©¿Á÷IÆÜıĞ§ù%¿ªLÿjÖ4œ>ãWËã÷@+Õ©×êœo—¯ãåÆu]î‘Çş;€´³Şœ34.?ìQNåˆÓo»äĞ@ãÛÁÏ©íg»¶1¢ÃçAÕEûÍwÍ™Ñ	ÄŞñØ¾ø=n‰û€‹Ö²Æÿæ¼jƒ
®Ş5^aeHß\&Yè5Æ/]#4×Z~²'f§.ô”S–”,£€^Ä",Â%Ê[æÔ[Xæ ®Eê§V ÉÒÜs9ü”ôwoÅ¤[ ‘âl­Uè2•úT	¢SL˜¿•Açêys¨±¶LïibÊ@9€ÅùhÅ7Âp=”a4“.<ÿám¡Ygı$ÁoG£h£AM_„…dF±ê0–3êYp´Céë»áë'F³l_¾a&Šíqç#²ºoO¯ë#à‰‡^¨'õ7Ñ^hqö-æ^|ÖFÖ/`ÁÛ êaûZ„E,ÉÒ’>×$ÚÌé…¢œ[¶éHX7ûÊˆóá(ÊÇèÖ7sÅ¿¬Ãäy²_õ§¡¯¶…Y˜ùiY‡
¡mü/n±w¦Õ–50.bæb«h>7³’d-XÅ2m"JA²ğœï34İ?RûaåJé¥âà©Ì:ö„$W‚èûPyĞJR?ÜşVQë¬0hådXq²¹fãŸ“A¥è„xM÷mî‡fX™‚¡»†ÙÖ“è,p½mU@Ó‚®@ièˆ¶tk™–X~Áp_(ÜÒsK A³Cc${y€ªíğ-œf€?Á§p©SüD»(ÜiòHh¥‰Mj_ˆ÷Çº'ä(qu¬íÌ«&Ã”ÿğ¦\}Á0
Û.å€ˆìÇöp²»_­ÖËÉàr# &D¹B<ˆDfXBKŞc«"ëÊ|m(„€šáGÁA?ê8:7nç«í§^¬ ‚ØBqªÜAuõE±ù3™ˆ«äÂê™©…Ÿµ1„•Ûˆß£Ê©‰Ñàá’VÀM}ª€Œ¾uÂ :ÿ²Ê¼ª®égÜ¢ƒ\\- à-	,±’Ú=šNğ™c}¹”eìy(¬’mõÍ/pDÀˆ'uÍŒø¢–îõ	Ax‹uC/<"@4çğY;ëlåPA2Íl[?hÎE¦É¤ ıgèeVk1ûZµŸ†_n¶­#9ÄvŸÆ 7p…ŠHé©¼±Ü÷‚»¤Fãé4l¬{–%¶ÚÛ.AØÈ¿¼Eg˜U—I‹‡·óL»à´R¢µŒ8ÖEì;#o‚²À_&‘wã?Š)ğÕ˜[È‘8lò¨ã›âõQb¡>Ñ„^r0ıgf>•[C	å;g2};ÅDB‘áÕ	n÷.ì¼°q©Î!¢¶÷æCqˆÃñüüìÎ¥%£G	*ƒ£WO±ƒ+¡F=èe’<¥ëË‰y¿7(š5Ym$a^dhù•ã,9o÷§¾=šA-Yô­_¥bÁâ0ö{Å±ü•FdşêäÇgÎìó3÷ıƒÕJHVEK&FŠ'[ÆÓè¬»‰ ƒ’áı”È9IĞP(¶ô¦DÒÂ‘—İ.ÖO6êoÈQ÷=¨#ŒO>eÃe
Vµ—[sM–½ÿA¦qĞ©;ßì	Œ@ÒÄ¶^
ó¡ÙRÔÍ×cbRØ³;bJßÁ2È¶«ânşîÜıáŸÙÉÙ³Í°«¤kn`¡//zßdç»«‹&ñĞ+¾¨N]ò("PÆÍ’Ò=åw{ôÆZİ<æøêYº‹#+˜ÿ©6Y•š[*Ä®yÊ7¦$ğÏé¯øŒÍˆª}œİ|èêö×´AIÏ’ÖWG#M²ı@ºAqü¡¨zÒ±"&wn¾ç/ñÇ\Ò‚¯r-—ŸAûş7ÈV:Õ!z]¹ëNüIûŒ-dûm5dlx¯Ö"v½@I£î!AÅmÆº%è?vıì,v\ò ßû¼ì>½I€ZÍ†};À»
Üş±UEüy²æØ·b	Û6>äöëûò¬(-£Á[ÙK¨“=Hà |ú˜¥iM¸CV? ²ø@	ƒpu]¦Ä&ˆWXû}c™èÁõ®¨ğ¥øÛ|_°ÎÕ;Óâ˜Ä´ªíb½jÃ–ÊÄl²ª ®\‚6U5bl]@6ÄiR?@÷yƒÎšSÅ#ız´Ğ¡ŠyL_ÚÿzÏ5|”ël{ıdÏ{-ÆYÃ¿Úo˜Lg°:W>ÉaššH§^ ïæÖ"}_rS¦%±µsœÜ¿”zúa?Çjï‘™§~ş™öM6#œ*ÂŞ—òÏóÄfy t)î€¹XŸG.~İR­3ÌœœœºÒwCƒİ	­—'
şà+Øs›*ñ"6÷<èà_Nzÿ²ÍÄ;ˆWc:$‘Tÿ/hQ *>)¦·#
SíøsîÔÆ÷bêƒ®gC İœûÇâé­ ‹(áë›®$%º›CeqçŸvWŒ&×V«˜&eÃw‡ã"Õ§:A³âYW}çlş3úıià†º"˜I'p²jzMn9{Ñ/·¤Ö¢s¾ûõÌŸµ¥(*í•L†ë’wMÀøk¸İ³Ù>ƒ]>+`ÂBw4.Ë˜Å¨¸ôMxHì5¢˜‚×È¯ëÂ$£„i*à]Púù„öß¶Sº'6Uå÷ôŞ§Ï»C/@s•HÚJix6tV|™SBŸàCâ²‘ºçLM­¾YJñÍ}-ÇIRı£éë¼JyUD¨IlÒñzYdO—‘øBYô³Ux,Œğç“hv;”ª|ÒVãn'ÆUÈt8è³Q©´–$¨¥äwb‰œ½Ÿ‰¬Ü„¼÷‰k‡NùüµcœV`:”ªVèZ*ª‰%Jî¦£`¦ğ±;Ş<¯„İ— àÕ5[m²èÕe€ôq6éêBT¤eI”pgdGpß·ãµe¹Ôâ7dá6:6†µ®¿Ú (©ëáxk
Ô’T‹_¼hpGd¬¦Ñ¶5K(´ø£+;¸L)˜oø m‘lMÙÆçJÓDp¿zä«á_ÆVkÛÆoôÓ»…†k½­†Û"‰é#„ú²£ÈáE“7ì¯è}¼ãM´»K	˜‹Qrw>;œ$©	²,—¡ıÓøŸŒ=yƒ¦
&åğn8£K~¡<èÈßñ•x2¹ßãyœşKÀBó£Øjí1ô<•_q]a ˆÓ¦Îôÿ©a¾=‚&ÒÍö·]ıßT“¿ˆbs õ)¾ÚPïø`ŞxÌÅ‹U*\AS°õ‘ ÂFÙ~
-Úô§™"zĞÍìõ?³ß‡­'ÒÔX§„„S9¥ŸŞ&f,0N²8ÒŠm½6–¶ù)¬ğÌ$bÃãºŸKöôÄ6HÌUÍÌÒ<nRU-ıÕc~œ±²pş(#:x]éZa`¾·0êdÅÄ‘vå ˜kŒ:8G ßÄ"WCìtÎJ2¦¥j-HŠ«##&ıBôøÀpÎ2_åËàX¡N”Oİ‰åwßÒáÚÉázA™·DÜ¦ä†«hÑ7= è·«ò|@®–‹¹Åœìì3ÎıEğíy&±…1"[3Tÿ}Â÷©&h0fQª‹Óïw*i­÷EEÕ|$×«Èÿ/›ÆqøŞhO~J}O­kÜ?]O8™…óÌq>ÈU9Ú&{f'Ÿ$PË­´ë›j’õåA')¦]WÕ¦BqâªiR HXeîXsÏ÷…ÿeB‰LşGê”"9šÏû`dì
ô›Ë²œ‡ÊùÇZ8æU—bîg¸síäEÀuv‡¨˜ıÊì­ŸùÓ=@ÌåÓ+‰6˜R‚F€”SUº»)ä6“jG9´gÚKô€UªÌ‹nR¾ö¼ZµA”³ú·dS'Íw|ªnv"¿i‰÷Y˜}4;*LÖOá<F>ºÔÑQ—|a¢Óºø;.¿—@ Â9ê P6*ôhõ)§- ÿÈ1x(.T7_ÿl‡l)E9%ƒåÒ×:{	qÛGoì-°·´&!î¬@Ç„nwçJ¿}¢U*<–ŸHŠÖj±©E•½ez3Ò¬QÆ$t…eğ|-õ„®§¬ˆŒ…+„g2d€«¤¦zîn(éĞˆ»³]íc…›w*—CÆÅî¿«–$«eŞ ärâ¸~E‰kîˆ¤ûï†©P¶øˆÓ r¶C~K¢°3MˆëÉ„İÏ»šep%Ò´A:¿õØì·ãV¾sy–ƒİÜÛU+4¯zÈ“$fZÃ@59´ÉVÈ Ê(¥jgx×{}­‘*\qûüAq[#ş8;t°&Íá2ªõüòW6«OšÔöÂZuKÇ¶AÍe'–ş*˜
™›ø;¼ ÏÆ‘1!:b|zMğå 85Oü4‰!¬Î¹§•D5zôO¨Ã•>¾	—â»×ÒÏC ìO0ÜNÙ×QnÀh‡ZcêÊ¹—Öu59«­ø='Ô<­¨K£ÖòıĞ(ÁÑİx®“NÏ²ÙË)È¸Ú{[Òqï×WØƒJÊh…ÄîH±©ÀÜÙğ´_è$C¢;§³©ÅÚ f%åÄlÏÚy‹bœmË¸Qæ¦.¬kªŠ³ÚÍÎÔğÑhêsaˆÀŞĞ6|úõ Î‚s¬d×¬VwXœÅ½ÏC°¢bğ!Æz™ÏòQHÄîì¹¯Æ2kRş8­Â7'¯i„#îóµé±Òü•dŞÅ:ŠQÎo>Ç|aŸÿL0mdñ¼²J§ŞÌˆ7ÒæÇà0	Å©v?}çÿ êºFÎ2?H„;2àöÜ_Ş|G–åİanÜténvp4‰.Ë 
Ë÷1F3’+7Ê¥›×ÜÃº*'ÁøábJˆßxÍ!ãŞ#†èö"„²ŸÜ†,X÷ş–2>O[4ğ”#aù†dĞ»'H•ÆÛo—Ö#Àë„R_ğÕsiœü×[“§wèó| ÜFR…3}M~FT‹óYİ"ßwáio.%ùÿZ-¿=3øo `[=o²ô¾¯cí¨TæĞâ	Ú.˜Şñ;lÍmö.Ğ.§*TãøOøó!ÚòGbÍ]”_öÔ|•TÈ1,Y·K²ìÄZpåÖ8ÅÑÈïËK‡Èæè¹í§ªÏÀ—õıöT -àB  ’Â×ï<×úŠ ¼Î€¤/kŞ±Ägû    YZ