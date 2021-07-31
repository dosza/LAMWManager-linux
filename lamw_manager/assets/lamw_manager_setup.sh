#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="579433630"
MD5="2c0b64acde20a54152e2512de3845780"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23312"
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
	echo Date of packaging: Sat Jul 31 16:52:13 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿZÎ] ¼}•À1Dd]‡Á›PætİDö`Û'åÜ‚~ 8_ü™	Hîëİª×"¹œk#QŸ#Ë…±i›t'×Ğ÷ü ¬ıÈi	êÕq§6ÚuŞS7†»kæ‡Ğ’óv²'µhˆ£¼É¬5ÛB ¢ƒLz©/ìş‡Îw²‰ñx ÿ‹b2=¾Œ¼ŒP¤I{Ošv‰À2€šœf­<cşJ!Í¿dŒÜâÀE†—rÊ%ô¯Ê–¥äÆæ'J¤*hì.[ ı­à ]Í!)Âÿ5Ş»äÊ¢.Ô&w(æ)V8vÃ{‡BÒÓ’¥ì$0-HÁvÈ’®O#L¤#ÍÒgŞ`e,E’Ä×/C¹³÷ûH8Ò%ı…) Û[mBì‡0µhÃl\õ!Ë°ÛV“ù¶®µc­˜ĞµpÛ‚¼&ÿÀ³Hû¨Äà|bÀiŠ@R›b×”Î¤wYÒÜÍRÆ°8ë¯ÂÕÊ“u8åXç¯+à7<éü E$’‚´ÛBIF5í{ äIì‚’©} ômÒF·gCI»#H%ºS-ÙĞ™¸ˆÈJuã´5>5Z©Tö¥½_Ö·k!wö˜PÆ“Œ®:r^¶OO¥Gşòò1¿ô	øŠyÕ’‚NW±š8(›öåSI/ïoIC˜µsZÛµJô'†€/\íÔé#ƒ*™í¶ı%Ÿ¸KÜd·}ş@o#YŠq Ş?÷J ¬Ï¬C	s­µşè³«QwQQ&y18Ù;C5HvØä,h†|ÖÖÍĞşÍ3á)–¡Àæşîb3z„›Oøq4äu˜¾Ê³½X÷ÚŒwFÑŞƒo¤î…S¡¢
Êá÷:õóçt2qƒ4yïìíÀBz¶¾:YMìì{‚dÆ? {Ë°ìdÂæxcì¤zÕ¾’	Ô`QMÅMÁfß¶oñ®£¢ÊÛÑæ3SÿGí9S¾MĞ›a;Ñ¹½šw¼Ki†Ã5?w³Puvà"ÜÅùlÍpğoR»¸¡…F©Â†C™qñÚÄÕœë¨G\¾Ï}%ƒiíRîÚÉi8,“ƒ—¥Ë&š1İöŒ&*WYÊû±½ÊL¹Âe'1V“ªa’úd¸‹nµv¹dõ[Ò?uÿU<Ø+kÔW{×$¨Á-ö¤øò8cM½Y1•˜ótX8\»ôËJÊxXÏ™Ê_µˆß†Ò'ı²Y+±ÕvUwxÌh‘µ6b“é×‡=<][.º	N:¯^ffxÙôÚFvıó™æl/+ô×Ã….)Ä°WŸG½opNV™6æq #åªÏãñô¬ú%¬ä(iIÁÑê;”[ãü¾3YYU¥5Ğ`‡ÖÚš„GNb»¶*Ã]üåœºLÕğªrƒ?æ›¡‚9³•ıë­¿uÇ-o#nh,ùØÌÂ]x½	Ğô[\ˆÒ'ÓuÊÓú˜˜Ÿ¼ÒÓ`÷dH]#]$¾;Kº"ë$;èª¾Âû"_úÀ^Âo³–ï` ÷ÿÔÏµxÂK9ı¼ıH“a´qÿ(%–^îSå2¦³¬É»/‡¶[éAíH£¶Ó"¯^")Y÷£¼¼TwñrT·Ä^ì‘m¶µšã`¨¿'ïr"Æ,áÛÑZJ»Ô»–ã<Ğİ‹}Î6ÌÁ7#îû0“¥)2®J³h`É—'Zç•ÿfŠ”M A'q{¹"l ò”Y‡rğ©z-«?ƒYWßÒı©ÒAªÒQ—iÑßõ|ş’Ig={Ø˜¨’Ÿy¸ãç4fNÕïq.‹2&/RÈ{­|Â/ \ı9Ç¨Ö—nZïc:,ÓÉ»²b€Ÿä¶×*YEëagôÙ¨BZ"‹9êÁN3«?Ì#ô,íü¡º­	ÿ6ºE‡³¬èÓ¾¥‰ Ÿg”)I´@luôª!åÛ›0ó\z{¡¢CéîÀuÿV–p8!òQÜéŒa¨µ-¡ge½‚h<7tB$<ºŠ7Cï’yTSù½÷µ3v„¦‰Ö©7İÍqò“‘ÊßF°QB!Âmw¦Fœûa‡ew–w¦‚l"¿¢«È’uì7ãèÏ™Q2›Ú3ÅÜ|‡Yú~Ñü¿/†5Ó…j7ÅÅéÔ'ÆÏ;öï’^‘§d;Ë÷™Ø	GVˆá<=õ½òu¶©»”±èÎŠñ•_'ç)¼i	ØwŸ9Û4ŸÖ›6y¢İ¦î—Q&wE‚E6IlÎïåŒ+ÌâH0ï¹òéáPéKôã1öóÕçîm©8ÚÃ‘z@§ ä#![úëöıı×NÖÒRüºÏ5iÈÚ­¤¶ï©ì>Š÷«u¯>‘NÁ¬ô7Â“Z^éÁ$½·1Ó,lÖg(ÊÖ§(j”›ºª–¶»&/p†€›“M¸SL[ 1mÏ˜ØßéçÖd¸À˜X¸ |1~?2â°cp†ó{½L†u®Âoï”fÅìOnÒ+ïŠùZ°™œë?%”]û à¥ø4o]}¯¦ö¸¯ŒYk½Ò‘:Å»^]Ğ'tÉ”ĞHôœ/K$‰jò,úİ:üĞêcÒ=Ãk'r2LÜL/ÍÉ–ÇàA9İ4ğ$vØsÙİ÷BÕ¿‚}ew,™±Œ´#Å=ÚÍŒÅ£˜¦ı\iÑz­RQuö,Ú_÷Dnfàjÿ·Ï¶éAÆÄX»*V2Ò•„ ë‹Éq´‹Ïsä\‹A ûÂß(ù´ô%$¯ˆÙŠ€C^~-:¦~¢¢e¼¤¸û­ùc¢ºQ<Sq[!<©ˆekgÛ§õİ‹»V²¸Á=É{Àu&‰€±N2ü\äEG˜làµº'j<¦8/Ñ!¿P`=`Üx‹DÇÃÍ«Û0v«œ$£"'véw`õÃ²›—°JQ•@É¼ÿÛ P‰7²j€T
ÏôÓXs;‚Â®Nb,zjJó\°œ(*B`iíåîÆh
÷çµCOÀık©ç5xáU¤½.§jIä]›((Z½·Cr†¾Ü“ğ(¬!Ïö7h3¼3p*]ï‹DZÇJ
†Ù´’,2M}Î¸Ù•¥† CBƒ™´Ì×V¢N3KÕ+5³8v4ò³¹0ø¦Gö€•?ŒÀ“’v–³÷ó®ì—÷éà
…œB†èŸİ»0·aÍjÛ²şã–Al ÷Ó7òuçÕjêpâ­»ÅÊç¯1yµú¢qbC¤CÎ¢‘¹ËûïûJ•ËÒğ²c‚ÕœŞté	ğ¶wé‰Ès?Ç¾‚Én¬›l»FhVú%¤ôS2a¶ğiWzõ$V^»iA›«äoQNİ‘ö	(»änsïqĞû oSúÅQ;çq^@İ…=P-Ù­ï=ö½bêxß4ºQÙì."5Ğl^àj‰Å]€â:Ù¿²–á‹'ó’m„™p€ŞÚ#âJV“W—KFÁÃ§Õ€¬v\=]NmF:İ»Ş@13+ _M¦æ„'=éNTh6@–ñÒ0P‘ú–Rï÷-´Ó(}ÎŠ RõÅÉ6DÔH¦EôNøË I¯»LÄº’¸0>Ô²	ØY¢—¯ªW%¹Gñæ¼œîj45½2½BGbZ†Éä´é1SkRó1DÙNÇ†R/«cè z°äc£g)í	 Òeö’ÃR¤ä¬ŸÓáI+`üõÙeYï‰×»H­w6nË6şôAf ƒšgD!$|ªå6¥ÓB†Sğ±oí­5yÿóŠæzâ]fü”kÌıcUÔ&ÖIÌ_¸tQ¹§š£õm©]r¨å zÕ‘¶éÜE‡é'Ms¹.Om—ĞhcB¶'C$—ú?LI§[GB$\³¢éK¶»(CËÇp×»vÍZ©;íÿd…ğ¬³ Ú‡c×#”¥:¥iW¢"–1wN’é©œƒÙxtƒ+ÃÁÑpooäÆeëŒ´=n'ş+§q%o/!ª_Tü££hR±İÊÂØ½i˜P¹UrÇË[óZ‹42« Sr8…M	Ä¬E»TøÎIİ0wÁ—/÷ \Ñ¯ÈÁë„— 5ÏzÊ³U¼ZÀàeĞœ¾W¨€Op)?a?q%Ñ‰İ	ÙôöŸÒ¹‹—ëğ]€ÊÇ)[r}³y½w…Š/îäÅİ“£VR:1/y¤w¶$
²¦×À¦K‘èŠŠA¾ˆ¾ö1S2ıÍ%Z˜sR"“× ôsáóØƒ‘>ıpX¢•™4÷J«è¸XïwÑ»#‘¨ŞVkªv ÑQo€ŞRDvÔµ8Â¥^PWcÛ¯Õk’_(ùì‰à@Ñ4H¶8Ig0y-ñv4ë¦kB…-\³zÿìÃ‚I;ñuFz±Ü´T\ oó¥’ ‚yø-\ËdèÿßŞ`ÃŠÇ–¢`+ ÷‚šï	~x$§œniqâ;.§üZ{úëãó'¨KŞï>nË£À+ÖÎ·mÂ—uSšåÀGÔ*@Â;30U£ü¼ì‰Î¨ »İ9qœ‹«™_®w·ì•†"ì¸ß°¼>GÕâµ]Sª·•0*H/ÔbC·©DíÏ*"ĞßıÀ)ÌDœ#¤=Ò ¤JÓ8Ã ”“¾FÛàÃk^Ü8‘‚»•hÚùÜı´ô¸ÊGê«#nB¥·ÆkÙ'ò$}“CƒwëÕ¸‰‘`ò*=ü>b‹Œä'†§¯ƒ¥¨Û5šİ©pçeø» ÖÅ“¼Y7Ëk9 Èq«ı:}í1¼€ªŞÊ2Q¡Q¶4åºÈYúae¼%œ&Ø^+¢ç—Çj ˆaé€[’kÓ)ÿ1aûjgBrÇñ?Å.ËïÑ×n€»òB=O.2RçA¨vu±ô´ _;Õ’YH…Í'Ş§¿ĞØÔ‹$zA~RÔV8Şm’  ÊÂÜ şÙTı)ƒëO§½í¯­&œó©_Qe¨UÏg¢Ôl¤jóeqÊÙÉ†è&XŸzºÉ»3@/‹EÚß@Ô8®0, ÊÍÂ‚ºìäçá6!ÓÓ‹kÉÉ?Òá’™]oÏŸi4‡ƒŸ˜!±^.ŞoÔÀ¸sß;KúP<Î1ÂşLèhÌÌWRi4\×*¿‘ÓÅ (´­ŸY‹nYjQî„¹¨z¶;`Ä<»9şámñ£r¡/Õ¬›Ú"âÿ&%ê™ha²U°	ÇÙ.Ö<_ƒKÀ÷d Õ-¬£á¸MKøÊ"ß`+4V!n©œ·Àoyñ’qÕŸsj,Ô±–…ºP/=œH	¢«a’…3¨«ùÆİ.{û0jw1³ÁÔr*à<¼#Í3UÚ£Ó€7‹ÛŠíÁÎÚq3cHNMš+;Ã85±:n¥èÑ8ÏÌ¡I6ÈµÆ²‡™ò£¤eÀ]Š¿l©oBW·m„¬&1 'l°Éqfˆò®kõ¬˜îƒ“wHM=ÿ¥Êk×ôH(Y±bš\—“;"1d²l›uCiî§íÏØg’şQ¾è‹^îl-¤ÚtriÑòrä]á	¶mT§gzj#î©JÁøv¿›úItq—Äi!œ¾²<'¬epü-¥Ï^í£‚ «%ÆzÑ¼YûDGõ…Y˜Ğö<òıœÌ%µÎT
{ /&¦Ç°)fá;Ü™ÅƒbYALÙğSÜİ'èovNo“CN{ø”Z/6P‘æ©5Í2–55úIŒ]Ãı^2e!Šép™mên!9HÂ;ó 0øç-ÖRé¶p?'dúa]ªá€ğsz÷;Åy‡1>£-ny ¥Ó‚A½6¶c(EF¸K5âuÀ®±nBsmùœ£à:šrQÆ´ÒB¶°çĞ×¬·³Šaè¹ï^(ÄÂY¹gÔ¹æLŒ$NoÄfªôá¾mé¤\R±d“×ÚÑõ#3Y†"$ªù¨„IÅ¢Ívpw/~©;§pâ¿%"ÁìÍjïß4œ4a+£{‹Êw`ÜGæ‚»Ç»ïT2^e}ÃLÔ¤:5~PÆ,<âœÚ³òõÃDÍ™Ê]ÍE¬¶'rqàÉ•Gß0<²=ÆÂº:[|ãdÅ¨$Èûwp%ó4&¬”O>…+C2¼¾}´<š Ö~ü@« –o°U&é«Zo/Ì´’ûâº^ÔÂ;Ñ«¯ãóĞßkè21¢	›"ûé›¼Ï3Ÿ8ÛOL-ïíåwª}¢„{Öä8Û6ıå*óÇMƒ½âEi#Û‰x,B%-ç@dO¡XdËÁVŞm˜XcznLbÓ[×ßŸìMë€f‡5ë;Š;dPşÄë&âh€jìE‚·Àæ§Œ8éöòÀÕ#=È‰7Â¼Ú 6ö#]æïÈšl‚„:qx2:Ox#fÅæÕ~£HpWÓx¶~Ú‚DP‰Óı¤¨Uf†Õ¢Å(éAQ˜D\ôY@Ş‰œqŸöá'S•d,Jm”ÿÇh‚qü©­Ç}Ú¹"]ß„g1=3¨Ç¡üßií'L7ÈWğÈN°£¼BE–„Æ_«£#*\Û9ä3Òv™}Ov–÷$£Â”à®=õ
.,ìNÿ†¡Ó•j0´å$ËÅ“ãJSäªÈÒ-nNÂDwÅú!7İœÚ·ŒÂàı$"+ovå …ÛûÑ¥8Ã8x¾`WŸc!Ê„ºß»†õ×5ÊRÛ@K y¥~—¥{çbé'ÍQğV£Ä…8FQU|¸¹.B3ÿCØ<ãS¯yG“LfBn+/é;©R²’*†ïSO‹1Ÿ†«Wb}iâm4¶Emü
Ô ·‡ÚØ‘–DÖíEè™Ä/èí=wAŞZ®ºœJšû«§G2å÷ğŒÌh§+š‹è€9Pó?}+tkëñc ¡<`ª>»®†—ÄJvüjºşGãCÊ?æ‹¦Ä~aÄZ—&-¸¹BJÚÛ[ğW<rZˆhLûNCÀ”ŠÍBªÔÜwÿôkÚìë‹¬MñOÚñ§{æY¦rAçFÌX†úú8†¯Akn‰hk¯SÈÑÇª·Î\uK¬«Şj…s3Oo¥;å¹èBœéaì‡Né_ûÀyeâ±5Sl{ãô8ƒNÿÑ‹şï|@‚WwKØà5DU)9Å¹ûİn<Ì¥¿r’ê¼ĞÂË\„î‚ÅœVÔó½_aVdõB&4S^â>ù*îêÇó¹a¢ÎIW±óß,K@5T)ç\şÒÄ¯”}~è‚òèloAèh¦Y€ÙÅ8fZP˜\Fâ`¤üófsê:ËCŒÑ.Èz¯z-n#¬BºĞ„SëNÇºL+"„¿×êXH"5»~óIXñ<Ê“\9Ú|Õ¥_–>ÄïÕØDË¶›îö4{à’ı¤1‡¾…o#¿'†M8z{\ğnÂ—š?Ğdm¾Ğ=’^ÙlËõCWã^
Oö~+Ó/•®öSB)¢æóC8'E%ã’m}ş&';ßÄSCş€«‚†ƒJ¾Q}Èß¨‹,µ½î¬	—ïğ„w'u/vu©2×Gà>ío`°‚³7°r¸."8Éüè0œS¢jÔ
š$x7>NóI=y¥”eNáí¤¶T-¸Wäâ"UQ:‚„!ñÊ<5Í¶ÚğÔ÷É)É™{’™~eƒŞîKNùÆœ¡°ÜË#÷rnXCh‡h>ä —1ïÆ”–«ÿ®÷fš²€ÒW3RéŠJ×L¡ĞA& ¸NÙ*dF±â°ŸŸ9şïå,Bd2¿'=_£EåË-÷‘N†Ş=9ù:½™Æ´E¯.oÏ¡„m®ŸŸ2k>h!@ó­’®2(ÚßKk­S,¿ÆFKDP0÷™ÿê—¿Zxùó8í´ÿMŠë`
ñ`õ2]øE²`141µvº¤êqlèÏûÛ¼Â&¬ˆ±•-Vmö„×ä•jR$ñ²2(.u¾ƒ‹B I&•	Ñ6ÌÜ Ò7¾Ì"2YÁ’ØÙÛ.æz<¨ôe#÷„gá3*Q3ßR{ô=¤+j²+†á&‹šà®M-øÔ&4U*‚&ÓŒ€Ûfì0ì—”ëGñyùóìĞOT=DpOŸ.WHInX%Cv+“Lxá÷ÉHâ6f7Ù†^±d°´ß3ô„<£ù[Ôt…¬©7ş×Û.¯m¡Æ³†!zHAzªğôNºíQÆ´h˜˜ÒK›ó³lpY%ÓF÷a9¾ò)4êWóĞš×X6nN{Aïæ`×ºEüÍ¨»Fwœ­ˆHªÉ31È´3q™Y¡45wJ´¬âHœƒ·,÷­
 ²'ëyŠ$·~ÛçÄğ›ªlVËšÄ(Kt™£™Ñ»ğ&ëG§Nb¦‹ôŠW¼EÈkÄ)ÀÕ,X•{Ö›×:÷ÆËôÚBˆ§Õ'=9;­@øŒPıNÙBWàH´··h–ÚªQ„LZØK~²‘‹_¤‰@ê©…›€×‚îğ…ı5­¶B­ƒ\ ÈéOĞí¶º¥©=ˆœâFĞ¦6xBÏ ."$Éù`	’UËb ãB¯%£™œõ¼ZĞyÄˆNmÚ³Â»9­}ĞûøröNÄlı\-‚§’i„5]À„ t‚Ü(â†ÅñV­¡>Äôf–ƒ#ğÆ)4×Ó]¦œK¼„$«îõ.ã}ÄwymÄÓòáìWí½ĞQÇO0ùPvõ“£Ñ®%“>Œ'_tiÂòLÏ¯Ö ÖÏfÍ…:N-Ÿ&xYÏ™Lš™î¹$Dª+²yÆ¡ı?måÕ'nîµW]3˜¤Hµk <¬´i$ğ,dSíş(@·«•MÊÓBJ›Éˆ§o:ÿ”Ï·:¿kÏ>;3­lé0x)3Òïv#U>Ì±G7ºq¦y­ƒ³œ{CŸÀ0ÃÂà»C ?ÛØ…áÅtºÍOìP¡Ã'v¾Sˆ KbM64FÁ>µÔTÍVgÏÄèe‹Ïyã­»qó*>ı50^•;Â
­~‡I*ã'ğÃó§µß}‚xw£FlàN_•z
gßšûwø	OÀÍ°Qé4<å¸n˜5.j[nø´SïDU¿1ÛRt¾R"µtì²^á5ùŠ»êƒb;„:nw¯ êæş‹M¬+LdUn–³9VBÛH‹ÀŞ8³ˆ»ëŒŒ=Œæ[&àFÚ2MÕ†ÇÜí©bÒ'Ã¬îÇ¨à°´ìÚ§0laCêô´!ä3ÈÀøFeY]{Ò9ñ ©#™ÃdY÷ròHhî7;F®‰”åÿ ¨åú‰zöõÛ‡nú|Å‚Ş"KúÁ³0m‡éú›ë®Úp×{ŞG|š¼ÅaÅ/Ëdñ%‚¦òŠb³p‘{U™ ±’ÚÙÖÆ$œÆ!iï±‹FPô?|2’+âÁYâ/„ú@PŒ|B Á>İA›ÒG±§q
'8[“?ë¹›Ïñ[}±5»Vğk%¢– –ÿ&ÈµİÒƒQIßr|Á¨¡—'¼\/ù±l8¨pçĞ­	Ä–;P}yò13¹x)Ï\™¬øäÁNjŠWßtÒƒIë¯¸X™‰œÄÊ§W42QÜ²)Î%Õ,\Òm£·íûÆW$ãr
mRwKÉ÷Ğ!!À­½ûÙWuÆ.¦âÒ¥ëw®"–ò³S<™ !È€t³^QŒ•«ú†ãÆ}ïÈê§uğ@öÉ'`~å‹ÎH¡êmFÀpS3=H3Î³<¢t¤–ôÀİˆéNŸüaHüÅ8ˆ¬Úä¡¤—’Õ,’ø<ò†RxHtœ¹COévk(­¤HÑ˜¼2öào`}aòcŠwU°¸èH¹ª±¤å |‰e„#ù›k4J{¨(:×—ÚRÔ¨ì…*Çäèp~#@,)xñ¬ğŠ?%=W	ÕÒ@ãÍŠÔárÙ?LGªú¾ŞÆc„ŒkÌô;%ñh±ïMÜtNb•¿'Â*Ã_-VS±¥G•/³Šøb>ZJ­V{ëa<xıX*ÁÎ<gÎğª¬–t/’è"4bZø$§O J†?øæ2Ó%L®ÜKÄ†l
“~®Í	*èFsh‘Û\Ö•LzHfsá‰¸ß6;#fÖaSí‡=tßy¦ÕZ_é€Œ1A\-–B¿•Ò-xÖjß<TQFÿ?=äf¼­ßQ’f«]UÇ§`_ú©SÉŸQ>yà§IE,ıàö5˜<d.	3<
“ÌZÃ>YÅC’¯—´¼CÕÅÃE ™A…÷ùƒ"¥h<¥F§‰~<Åê£†…aËy2g²¶©¢MÖV-’¦­şx#İ5Qb ,€3µ[“Î=_Ûé§ÖaF’èÃøÓ§“,³|Œ‡wfÿ¨éXBK š¸¨ãZW;­YM,¹ÿ–±(7DÎ¶m_CÖ²‹ÍæsÍ9qİô»=HNmÜFƒlš´±E5H ĞèÔ‰LÅÖ9ç_ŸÕşÀ·ZèŞJŒ6‹à»¯ ÎÅÉHJ•À>9ØæLj1A§² –½‘Ám½Î“Ï¬:?Í4‘‚#ÏÛ «Z2+V„eïÁ€d‘;ÖCÍœJ¬ye¬â†4›Àæ2S•Fíªda'×Dk‘hMóE>_4$íÌ©SCfìÜE€‘?_$µ=ÂtVåAMxÍ§acx¢Qjîp#XÒÉ¼L|EäQƒa^–åŠk
G™o£®ø¿”I¦ö«U’\»ngœaÎÿ%>™7M;ñÎR}R!’ğgF÷¾‰F¿@+;XqXû±€l^Ìu7•ğ6±öãÄ¾e“6<µbº„º„øçÑÈ ô†¯	÷™xÑW ‚³^ÑŒNr}O‹åâÊÄ,‚T—Ê_6µ_pğà§dØbd€øXfÚ<Ê‡5ôVÜªÀn¾Ó÷İTè·ÅX“½ÉK¤â]t;óÓ#vö¹YOEĞÂ%ïg¯7:Ç+2Àw<—[÷}¬›Ş™´>ÜQ3\ªìŠ¤OŸ:uˆ”A\5L†ÂB—F¶î
_É^g£ñ¾qx®•~…´sÇ*Şpåî§®8ƒß"ïwÎ»é  kmµôÑ°Yj´™g•JcĞ¡;É!î­èØóï—˜TÛ±8÷äèV‘”¿Å+<6‚P&u¬
ö³AÅ1]ÙbÙbaĞÎFI¡r‹¨¡ã@¢Ô æ·Yú”‡ ó•8²€·cºŠÚĞu>K,u”™Õ@K±ˆ5Š½”¯Ÿ5X.íÎ–PgÒÈ2ÃÌ©C—ü¯¶9¯YƒœÜ!×[:<•]èƒO™p„ºÔˆ)0œ‰`
-ÿ ,ç/JşêT^Äb*e|ÁÃß@e¡Å›uSÈ)#÷Ù+€¢8NMª•(á$Ô;±Ox–rË&Ôç‡]ãŒ7’\,“±ÿŸœGdk¦•D¸Uq#íE®zÏB„YêÑDh`c.JrÇ¸şºr{,=ëÔWÈók_Z™#U€c‚ÂıSÛ H¨«y6ºa¹ğ\¨Ô"ˆÆel:nt ©?2áWùu-ÄÖ—wÉ!f9I˜\~ûÚÂcûW›¿6€ª‹6¾SÉdı“{xzI¨Î’Ø»,e€y–ñI£CßÚ\oñû^"ïß_>ªN(¸¡V8T[š.’–Êz‘›¦¨V5GsX>Ë±ªõ`7¨néVûY¥sÄ-]ÒÇ]G+Ìş"å_Geİ^`	õH¤oÂçBÕšÒ[dUjˆj® Ô¬Ê>3#Òt›ÂÖÃÕö£ç_†#;³¨€ßüÇ ¥ï³zõ…ºâ]ÒákB×·BÍ1¹ şÍPAvø½ßô)Æ¯Kò‰L‘=~æĞUËC˜Š¨ÖÇ%ÖÕ,'à{„Í:™Ùœ°şı±qÌ^­­ûå&Ï„Âo€Úø”ƒÑš N`è¡‚ï:µXÈaÂa.¿²a§¦ˆbÕğ&;ŸÒyÄ™Å B©ÕÈü³ëä@¼ÔICJÖ.·Úóf‹FµSİ0÷QNOŠn€)ÓßÇªØÕäUXŒbŸ¥ÛÍG'[ŞÛ³ù6K  ƒ”> ½ÊrR:®ŸÏÇ;Dó¬Ì€²çiİréÏ¤º¸m…›jŒ\‡|A$“eº4»O1ÒašHÆog¨=4aT§Á!D®§ìlbø
¸òNÕÚË¡À¢®…Óÿ®<>`àù‚›=aÕUŸiXö\nõı¦©…aõ—†x$)BÓ¥UÊi97ª1/:ÔŞ‡¹#ŸÏªE®0æx´‰ÃÃE®oA-ç¸°p¦û]b;Œñˆ‚…†£Ewñ”,Ïû	ÿY#´zâŒb[.;˜}È·«N#‚UTE2]x>‚
˜MÉ™A¢²ì¸ãWT1tí@5šõı<ÍĞ$‰Å‚¬NÄ5]1 /‚İvŒÍuPŠ?¹M©ì“(2/ùlùsÅû|Ì&âÌI¤&±Xş®ÑúÁ¡ÙŞ-'Ùæ‘k«”z-µŠÉò$ÕI¨*ÎÌ*â.‹N»Ô=V",â•‘Ñ@À,„fcN…ïLÅ8”è÷äğĞGˆª[[ñqÔò‹ÇúrôÃ^BÖ+­ò@Ò))·î"ceüMÑêäS˜LÈ·Œá=Ú3JS¢øTÔè4¦^M“qæŠgq!{ö{ãØ4¨¿Â"‰6¶U ü3½%Ó÷ò¢…N±Øüb´ ¡y“„¸0V¢/YŸÖa¦bÿÉìêié©>0»?=¯n
” #=ñÄ ¯	¦}Ü0³¡ÁÖ–yVôw&Õõ;(£œå†@ö,ÿˆE!ş7ºC¸î*gˆ¸—ø£‰Ò˜…»$98°Ø”U5?R¨Õø&~Èuã¦,Nù­Ÿ–$€ğÀ¢à2­™HP…wµ€Ü¦tğ½l%(á¥Ä„pHQˆu¯™T÷_ô«ÂM,Ñéà¸-p’E–R¾oDdtX+¤	^ÃÔoçú¯L9	Ô	t–ÓSªÚ´ìğh[îêHc>ì;L=Şà_l°¸ûağ1ÏkóşQêy±„T¯æ;l$oh=‰]y+ÕÅù3Ö¾İ´u–ßŞ1W—œ$/á_¡:13ƒ‚”~çO)måa<Š#¶ŠÿŸëüqàÙƒıŸÕ‰Æ/:º«†QßÃ!]oF†ub2;Pµ*¼·!_ˆe‚C­9» <ˆlÅ—Qì¾+ô¥øu
—8fØúÄàwÜ)µU¨¬/òƒã]õJƒvs‰	»ÏGâ¯ÉG…DÌ‚‘‘ÑN#™‡ ÃlÏRô‡X$È‰¢õş~Õè²[ËŞ¶_ÇI–JíœĞôˆşUşrkÏWËzÄ.TŸ¸˜Šsúùº‚I­‡á`¦ÊxÉ:ëí³şg!C Ç‚ƒİÔÏé¦GŞo è§ØN8f&ÜÉæ  Cš“;•	ı·Ü˜`é¸V`Ò&"Ş‡øb£vÓ7@o1¬şrà Ë+oÇ%SùíGŸ?
ï#•¬i¸~àø?×¥'£û¢T–v|8O(hCr“M)°Ø©ıl_ÿ~ñ'[·š¾áq"!º!’' Z‡ø¾ctfï/t¸/Æ‡¡˜º!ƒ'ÙPKuöI'ıË/¦cùØøÁ
´Õ‡?B5¶€.ç–íş;¶
MµÃtŞªĞ®¸DÀ›ª°#R‡”qVà>'†³sœIË÷†Äâo4²Âoû®ÊÂòÒ;K‚4L4Âuñ|§Í2İ7€ÃLåâºÄÚ\­1(½"Ì?Í ¯+ğpÿ°l¬'ë9}
ªó-%D70F‡Åk÷;™
k+2ÏÈ"»¦Ì‹ş‹]º~}ˆ+rÚà£^§7à<°ñ\¥¢3K‡Á†HÅ•æj»a¡í¶R•ÃCi±Âì[±äGŞ£êR›eCl#-ı1ÉêšÊ*,m¢‡Ğ+·#ô[wP,ÌC¢1ÑCD)¹Ñ3—6¾ÖL!$„»ÉÑs¦¿eIŞ=o5fÁğM54nÅ¾YÍ»°ìJb¾ë¥0ëÿ…+WŒ¦G!“X¼äIôZRMâü­
>•!V°âEÒ<¤M‡—®ÍÅué¤
³OA­ir ÁŒâMgÜdÛÍïÆèCUÖTG§#.*Ä)Zø™\ÕbyÀ-7FÛS°¢`Rq{@(±€“¼ªàŒ4;^D¦Ñşš· Šªÿ°úŒMjø4*s‘’$ Uc)*Ñşñõ#ó!C¾‚S‹¼—À¾pí’î¨ïŠÈrZŒ°í]@Ûø³×¿
E1–ÒÄZ–}½
!õ—'€íIŠÑ©ß¡‰+3k°ºé~i¶–å‹ªIøÛÑ ’ü¹ä6`.Š.fW€Æ}öõ§8Â1¡#*mÖì:hJ=¥…níE?Œšù÷ŠAşR7”I|'U^?Q	}š!ÏZ<sL°]—ä Ò2@ÃL&û³ni:õx+Z[¢ëhãòÄàa÷tÉØ-‡‘!¢Y6¿àè!‰*“ pk!Ì{6&†T´[Û”ôÊk**O?Ó‡k ”3¹áê,¤mùĞôë‡õMšSR¶ï«ÈwëlÑş…
¯¥IĞ`²áÊoÜê·”ô²ÜîşÉ,®hš=­(°ÅM8ö¥-,)ª@ËËk§e)\ÖQpé¡ `ÛáYî~È5mxİ#½I9iå‰Ë$;×ïzö<‹š¤oúÒ¨ÅŒc+íe•ì×Y™c\Ã=jD_øÒô¼Ixˆév=ÑÅYÃa”£ñ@$LO/Kj ’,->–Ñú¹ÚÌ´[™3z;±ÿH„€×´7cNµÌåe9ØÌ7ëaÜfÿìi^iúkéR|7?Âæ6Ò¡X†¢D¢}¾Ş…¥Òõ1êqÀ>ßzÆ/á²tis4Ù¬7aûl•ZöİÊıÈò&&¾Ôk<uVÎ2jƒöƒç­ùf@ş¹m”ê+fùãyCºÎZ‚ß9,Ğ{••×ãOîø9ÉeØİÂ‘ñ,}k5r“½Ñè”ÌJ4n¬TCÊ4N	SêÙÔ6Üc€PˆºNúŠn?Å&3î¨.,ß>H…P£ÆÂ§‘©Ó+¹4¸!†¼±åm`¢¶}&³ù¯Ë=ÁKF»ñüX|Îªİ”£mœçÌBŸr¸;X{×@Šù› 7û€á€ûÎ6°^vÖtïšy-Zô`HMÇå­ıAè®Ö'-°û r™LFƒüÂ+ó ~Bt‹Y‹v?|ÄèñØ“¡ñ©Ü{@¼­ l½¨’`€E ¸¤“^(ÛM¤v¿ã¡Î®Ğç×äĞ%ƒebIH¯XÜÊdôœÄ@âÎàÀnµOQWá®šRÓ˜ğ8íè[†Í¯û:(¬ç2Mñ¿„­ï'aÛ[`Í¦zD€æ}é±—6ºçn‹t¬7½Ğ…Ú´ŞìÄzl7sáZ\ó·Vá‘Úfß”Åõƒˆ³î`	œt“q®3AĞówd±Sz_÷Ë«1÷¥;øïxgÚd,/ç=%öX¤17p”+Å{ó5DĞY½Íu8ˆÔ=”!òöÓ-)Å^@×s)m@ß	Õn#	"\vZ-òLPˆÃZ–‚º9œÒóÊŞ²I¹ÿ™¨,íâ¡—ªœà©Ø éÙ.¬¨C\êÃMfWîÒÊ;d+b„üzÀ^ÚÛTì"#…	„µÈ]°2è¢•AX/–#|ƒûï^yÇÉ÷Soº6¬9¢ªà ËèÄ‚#MPÈ£e·¹ƒğ64mcšY§ßáG0:e«çgß†(—mvöœ‡5‘¿…F‚„Â©ĞhBÛ=-æ±Z¿xXŸ!! ~vØMš•Í4QÊ–"¾i¿5'§À»Ët	‚ïfŞÓ’­™äh0zÈåsÂıgıŒòx8pp0‰ş‘ôä‚5Ú“Qy†=-T,ûüu'f@w¥Çğ”&m‘)Éš
Pşiˆnœğ Î”HrôYçPùXõrO0?bÙÍäCÛ¾ŒD/éÿ+S%»ìİ	Aş°*€w_¡uÖu¸‡/DÜo‰x¿ğÓs8ƒ‘!Z†öfR×~ó¬{W«ÀyôxbÛFqmNXQ¾_MvƒSäâı¿ëwTk;}àpâ6³RF½NqMı›b¢¬A8øWU<lèàŒy–rû^háÓÄ·Â™ØXàªÉĞd›Ê¯Å^ˆ¬çnYŞF€%o)î]¡A»zPšµiØÙÅ4‡âU=OÓûajâ¢=¯†S_Çüdyå!DkF=wğYdõÑ\—4¦Ì-V1…Úéç¨û3fNŒX‘<<5Æ×^U­#Tõd“-ZüÚEÏ0lÀ‹éùFõNì¹ïåšáĞDTø	†xl.Ç-ÇÎíÇcª—¯õ®•º‹l¹nõeˆÕuÆ¿……¸À›ë6}º{h·éµuzö‡Û‡¨ÎäFe!£äp+7†µ ûÂH'ğ·×m=İ ÃJ¶~4ì‘ªxb›Q›0ä(\·:5ıåoÕI_8‰ˆI ÌÊ„g3Ãı^ Ü“C…Ğ0¾ô ªäÜ­ºı“ÊÚ¯¯ßî¢àïi-RÉ]Æ=í»å"«Ooı¢Ò˜A®ÕskÍ¶HŠSÚû öºÉ¥Şû"£õí”>©ïÌ$„Ôo:ñú19Û7PéçÓácXğ…†{aƒ™)!TÁÛË0ø]DÍÓÁğmå.RJ,€Øä06¹Å†=r¥}bA³Ô? F¤ğ»ˆ”¬‰49õURÑæ­]x4Â~?vh;„y~Ù¥YĞ7¬Y\£¡y’á£8Ú*ˆÉã)ï/øËä‹Wğ·hXub1Ëù—Ès 	um{)±ùº—¸'(2ü¹å˜& €Xf°|9¸§<ûnfÇÚp{].±Ù¤hHğ#„õ§)ºÈ)¿"¬û5ù3ìh50ÇÃ,¿seğj,„%ôÒ0•*34Û(|ª@ˆb£o±•+oîÔ™“òQº‚¨-<eøÁyÁºÄÄ	Ú0ì<èíÍ£õùŒUŠ`›fM›7²-‡o(mŠ!ÿ¬7E®Ş=Y-B)iÇÈĞ;möœµGğ_ì€×? }ÃTÍn®oÜNz¶BY-èí|»1
Fğ“˜,Àa‡á%7:ÊCÊİ~äËïš|;Ëó¾î*DÀØ—&L¦wĞ'Ò q9Ì3£@°{¨!¼¯†Ô~5ğÉ’Çãys•ğmÖ]Ã42é.n“•„»Ü¿"ëCØüşóVuB›F–èÃ<5ÀºWš¨ÓS
›ëiãæ¦Sa•äüÖñL“i8Û÷£İÕ¡uƒï‡@éİT`Àh3·“=ÿÎ¨XáÍ½CñV¿?ÈÇt&kç"WZ.&qçò³´R©Nb‘Ğµ7pqÚùÕefØƒFY¸!X/’ü®hÒ­Ÿ?Jˆõ‡ŒSzá16ĞvŸj¬'Y‘i^¶ÆIúî¾h'Î 'ÕèZØ¯$çaì-ùê[tR?rÁêÖ$o-Ïk>`RÄÑÊmÊ
¤µš¨±‚¸Ì¸{\Tá6Ø¹£¥¿ˆM¬Fàéó)FC)^şvìóÑ7nÃ¥{İæ³E—Ú,ôf¼‡Ì r8¢€±Çñ´éÈ†èÔ$+šp™CşŸÁÖd )¯åìkµÔX>bÒôrÇVÈ‘&.0^ €Wää„Ñ_ôxËÃîûğö!ëÁ‘¶
£…	øRG–í U¯¥î<İ?Î´zÿğHAæ©]!¸¯ÌCYKÂ½G#hVM‚˜µĞtn İYëŸUs³OJ‚”ë·*£oñû†2ÿ±e™÷DÁƒ™.Cã¹œò±O‹üšùF«ÿ Ï†û¯ÛªÍá³ğQ3¸œMYÓ-Îv¢R–Wy:¹«¥¦28«Ã§<v¾· ½‹ÏvƒW¡éRã€®oŸ÷r ¸¡Jëf°(àmÅ°šçóıèö¼f´ä¦±‡Ÿú÷õg|mãï±™BŠu^¾÷…²õ_’“:>§uK%cµ(>ŸV”Üğ_`-z;×ÄÂÿ´Ğ@"Œ´‘5²|ÕVw€«ı™}NéOÌã+?â™Î…J•ÕäF@œˆçÂHÓîtƒJë…¹1YŞMZåShÿ›ú¸Föå³5ßÿÇÖH½©s¼EÑ©áXl'b•â¼:Ñ­ÇmfÉáİ3µ[×“´dT5ĞTHŒ;£¤ÎŒ9Lód ¯oãrˆåŠMâÈK‚ƒ«õ-ş:c=S™o7/§µ‚¶=m¾øz÷jgqİªç+~Ãpp\xéÆ	o&bJNHb`‚,Ò#x+Õÿ•ŒÏîFx™«W%L¢ÒPÙ
Ó2ĞÍÂÖ\TÍÎ1øƒËI§¾»Æ­)Nmİ¬7„qEâuÂ†ƒ<Ø¿dŞ×Sç²ß¨î]òŠ=ÓÀ…7~S'ã }¨6§Èá5äN`KyÎ_XDaöHQ»NS™¤é™+DTf3&D	‚«–ÏGDlñ-·;ÛCâRÒzBØşúó`huÈÓEûd Õ.UÑ\.¢èSŞ8	,`Ylù#VÆ³ÇšC¤ŸÍØç‹wüøR[îHàJbL•¼î²·Fªx¼‘ïöãé°FÁY?QQ6zzğ×å¡ExNğ+h’UBŒ.”è(ĞE€µŒWˆîTï¶OÅpïoÑx×á'ñÑáY’Ä]ŠqÆ-S¶B`ÌxŞ¼¬W© TBZH|ns§å®ïÃeâ%ˆ>6ïğÜÓ¨?±/QªV;"<œA–ª¼ÿF’f¼tEvUYæ°ìqó¨³k·E¢4éÏØıÀÕ¼Šÿ•>…$QZ$œ,=Œ¬à¡úOj‰UkºbU?/,7ëÓ&ñf{úƒı]:˜*$ªSÉÒæ<s@#~âLIÅ"vr3¹Q=H˜Ë²™ü|Ãp7¤!N+»:¥eÍp:L(q×1
í»ÔvğNMi	q»ëè?ïfy;)bÙò'«2ïÌ•Kâ)ÍÇØŒ;pnTï¯0
(XÂù²“%3lšş€uüûfQí`_t°²Z£P½O&¤Ğû1gÀÀ¸×^aŸŒ“åoí‘$­öîÂ¨5”ÖE†êıñC·*^e@TUb|‹Óˆ„uÏ	’[Ç$ª4Do›Åƒ1±İ¨(øÿ?‡íEÿ¥é°Yºš—~‰ÿy¦­_	¡×ño5ìš±¡ñ:$™²I8ÆÉ¤Ä¤a“‚è&Eòl'İ¼8àœ¾¸B§Ó”îàl·zt1M—Ñ¾L&JYší„A5.Ve˜ß+ñ¤¨Â›rQjÁ…G‚iàQ-ÆJ	ÒXõ‚oägâƒ#V$a©>*`ì¾Ğ@c›ø­}ò°úUiÅR „Ú„ï\Š,VEgÁë˜~bÈP¯…âJÕ’X°–Î/¥šgM`{µÏ±ñÔ8³Ûâ€Œ[Ò®Ÿ÷TG­s¿N®B/‘tÉv ”‰1 ¥a’ØÙÚ÷,XT·g‚0«®İV a¸¾Z0lW]óD«²ûëzâ/”¾«Í¢**òêÀáÉ‚hW8?Ù[v€Î¡İòfvÉ”É•Úª4×\‘~Wß´K6şÛóœ›†QÉ\™‹Ú÷FóHÖÙí?XFlô¦“‰—É×<có%‰¼¤@à[‹­il$’cêC«ã;>Ç9W%„±%`×V;ÊøÑÍFqÇ!jÅX»øÏ´ö&¾Âû|©î¢gúø™f|<?_3‰FD l‚ª}„X‘“×h|J:Ã'ùşAÍG”îHËŞˆ~‰Ã-ÑD¤; 1µ»‘x©ª‘StÊ"À¤åFÂR,âê}›©úˆ:M,cÆøÕ#ba?S‡FElî8œÃ­M½ã×Ó´‹Ó\7%³'—e£	Xuì3‘Ç7ä„
æ q˜ãËdq<º%ÀŸÿ~C
UœSãÎ›%d6XQÊ¦cıvsÓKØ@¸óA~öG·Í’xç>Ï¸_Ü_ZÅÿëù©Âî6ò˜#·9X>ó½ºÏÚáÈ•ä‚tÆ9Û„§ˆl{K›”Æbuz?‚üé@sè×lö±šú5Yr-¤#gŸl‘oM*ÌP‰ÉÍ'Ãh	6áuïÑ¸Ÿ<5c}%®4ë	½İ‹åªD%|¦tµM\Ä.M‰™
ìV£\B™›x×Íœ¼ĞÊ…ÃÒ¡«}ğ!ê¬-ñNUğŠÀÌßr÷ùkm\QWp¤‡Ğ*á^MÕyæşRj÷c¾DädwG{Pş©Ô4hß½¼=şş)¤Ğ7±UúpÕz×—AßC…¶P÷iVy†kş(-Q§æVÌ|5p ñÿ2ù]#uaÊ@KBÌrtÊ¦=¹Tİ`z‘»~¢œé&ø©Ï°5ì·ègºÅÙYÉ„$mûş:ÛÍòyÇZ*f)Ïuå‰:`o5²®V0{Rw s5|VÕLĞ	Éó—_Sù1 Ò‰¸h îtì”•>L¹ë^+(k¼ã’
r3{
ÉAîfa–{š™K¹PË)Zó4}¨Ü3tß¬]gOÍ›DÆ*œ4ƒ-  ñùÌ¼È•W1\œƒ–û/hí‡ôe
ıŒ÷¦ÂµJs|¾„æ¸l9#R’¹uŠj½‡ãf½Á¦åU~.Íâ@Ÿ4¾'=õ½R¨M1Û7°Ó@	Û¨Äy¾Ÿ?oò¤±äËö]õ¯jııê­µş«2qJ'Älüú˜¯2Næs8cÿÄjFg/Y]wİai;0Ù­¸~1±W½&=ğ¿XnµQˆÊÛœÌ0ÒQ2Û fùícÇï²6	á?™ÑÍòÜ¯×¥ãñ oS=ˆáA`ûğNWvZÂ&\x¿7ŒNx›BãR3Æí”´P6A§Äº%”ü\f”ÊÃ¹ªœî.¢F;Y‚l—(­®/¬`…áÒ1–éx»›#€ì9^˜º ü€‡/|ø+&¤ÌmüÚäòçF¿ô3cÚõÁÍö¸È`À[MÄ‰ğH|9‘ &÷[ä‘ùSşƒC~Öş.çÿäòº^ë\ÊE_U¢'ò®™ƒ eÀúGfl49¦£„5R×‡×ŸPÃã0äc„—H¨•KuReŸˆ ¤%ù_WEwE[œğŒ³’P—`ƒãqÏ*2CuFà(7-ôÆ0ˆynÊ”¯ç'·6ÒêE±É›l¯3×ŠŒÛJ­‡ßUb¼}4™ÅqÍ`£¥[ùŞÚæùR¥ÔS£ƒ°©¥ã´YSRÏW3c—œ’¢™SÆ´zI$x?ydogcKkN,Xã/5 C¤±eDMk`ÖÖ6½˜øøx†hßÔxë½’åí3Ä7¯¥v¾i°l«;ÃJÄNAìn+-âT7Ÿrx~İc«8Ë¦%²çâô4CqLPÈŠ“‰ ã›ê"iË`OÏíj¶öÕÿK<
ŠÒ”€#u[Š¦á‹$*]*ı„kUî¦6˜¬„bÀ¿K)È¨1HZ¦ß8™s*{¶Fx·1Í³ÔÙºŞÌ»« iBÄR ®'Ua´âëc”äèö{¡¨·©ğĞ We£²u²x«ã4Óü7³¾xƒ^áæ^#Âa$qôì•İ!D.S_b¬]ê,cøïTŒ½ŞqÎÏ×z”<&yr¬‰	ŸpWå¬©´å¿ÿ€AsËœß•,—ÄÙøéìx­J¦Éêuë³Ú¸0üß…bÓ^×%}£C“óÂØtè)9Xó,`_®ù•òÛtr˜“«•<JD/ßEBU{Æá+^âSäÿÊß>d0ló%›ù§¤3<˜hgn´ñÙÇ£lÇ7;KE®GïÑG¥Xn¬~6!K#.z…­»ØE ÿÎ'0™O€dÏöÊzÑç¶œòôÓ=P* Î‰íÅXıtşgB`e¸^Š#¸‡eu9µÓ`€0ÅŞ²ñR•iŠ˜Q, fê.¸V;¢CÎ$Œ76|ûûÖTäÏ$ò²
¢ I4m´åÍÁ'è:rŒy3\mw‚€…
ÒÌw•?6í5YäÃB2ù0ÎS½ûmC¦[Õo#d1h+æ¼Öü•’& ´ÀË¡ì¾Y_3ˆ(Å30YÈ£Pù££Â©Ñ:ŞÊË¡ŠåÆ^ñâT(ŸÙ3&ˆ½õÛ÷÷KqıU‰X oŒfËë›Í³ErÕhËÂê÷
æñÊû¬.Ü>„àÛì	İB_§¹›Š.5«ÈL§ãÙxÍ e$ ÛpÃııƒÎ¯äVõŒZ9sÄÜŸ÷‰Pçz¸å(“F
<&ã	kwØ˜N£˜kxC7+pR±wvâcjŞí†ÄE¦£:bø00€Uş&{,dX8­gV=Éq‘Ê¸øÎ5?hã8›ñD¨¸!KXÍ¶ÛŠ°Ÿ(Ô^ş¹êXQ½Ü
CMƒ³Í–ˆó’Ié·ÿ1tRÂ°ÖY³$ö¨PÑ™ÄÀCMØ[e# ß5Æ‚ƒV	ö}3Ñ±ğDq%šR¾ÙW–|Ÿ"IE¸¼®çõ2;SÁ#1©1æib=!%YWÉÁÎ­`ØçÇ%âÑ_Í]lºÛË¨ÉĞM† şu7”Ä ¼tj‚ˆg°ÙÿV­ÆEµ`Å–­ö±ë¤¼l‘Œtc‹-%£Ñè^TTŒre‹´&bXŸÅj™Ëc¦0_÷éeg	<…AÎp®Ã!Ât¶Øşw€‰–ÎêŠung5¡Ê.5óqä››ëô"´rĞo¤c…¿JÉ“?LQ \Ë<fçT3Ÿ˜ Ù+¹­/R
Bê¿Ä‘?Lª@“¦±¡Ÿ7Õ%ñÿ½{?ßÜ®±2¥ÛŠø™ï#3šOdº¾H±‡>Rí›šşÍ+Æ¿ÙqÙúy°o’×¡êVÜÿ¾ëñ™:^}Ir‚s'É:My@±| °·”Gãô/Øb€™™™6Âm’jóàœAüê~'ƒé¿†‘IYy ³Yí*#ùM8vS%¡³=í±Œi<äƒ}TõYw §\9Áî-T:VD¾¿Ww
¶EÌ‹ƒË°2¥¹âìK=ù2½'Òfù÷§¶À€C@ú©ìpÄ»ÙxÏ±„*Šşv¹µz·n./Zä€€k&!#ƒ"¸s > ØÃdÿ¾ñDP_4Ş¼sÚLå£'("YÖˆ©à³UEGUú÷«y7ß’‰Œ[‘¥Ôÿ8K2"­ÙD¿iÏ"ßP6<Lÿ.¸yÒtP	ô<Ÿ×QÏÊ°è¦wn)°ÆìàÕÄ—V™*Le^&ŸÄ¨Ü?#]Êw!P”¦¹'Òµº—ß_¡¹¡£ÕäJ¸Ù½ôOEUø~“kŸ98½àÉI8qzÇ¥ÜüwCøsªÇ‡†’uQw¡‡Mi<0µÍñ—´Šµ•éÆi Gg‚Â¿ß,Šãs™Î-÷«Ø(…)50{‹^VGŞV˜A<í@‰µq’ÏS—…@j¤ål[Q“±ÆñÍGÑ~|.$P• ÕıJæ…gkÖ¹êR®ÄÂxïÖxt†œ—š¡ûÏæøLøıøÉİ{â"‹âºªº|é/cØï¢ùĞ[ck¿5­q¾¡à6^µuÀ’5/]™h„™šOtÎE9>¡PŠÕàmÙ%Şšª–.M}MnÄ2~˜ûñÌÓ¼^tÌâ-Â’¤ª¯¡æÈFQ`5Ãÿ›°jvs°Hü;RN´6+Hşá¢@¤w1D¹íñkfs	{)Ë|ÒÁà±;bºÒñ×€RO‡3æ†ãó;²”Ó÷kÙÉÁOrrmò¢<Úï·JrÖjäõèåğìÿÕDGÿÕó®NŞë«µÆ°qİTÊ'µàHbª$³JdÇi³
j¢kú‡Ğ¾r.\4Æn2/»[áì•˜yŠ*0èuà©V–j+úÂX;o?†~š1ì{ôa%ÖD)$ßë×/5wĞµ”ÈßóCr`càø|ÓbIçÈÙO°xX@j«½ÿf CjóÕ¸­8áá^¨BÂÍ‚&Ì¥¾Ï¥S¢4èåywó‚|¹½ìn›³uçÎ“°v¤è½˜º7s(œ&ÍE¥Ô²´¶[Ğ£UÏÂäYıê1`j«s°fŞŸñTá«ÇGAdıÜ3(ªÂ+öíÕ‰Pr!q¹‘…´ôÕq}]£ëı²™C"Ø€ÇIÒ4è{õ
Ú¶œ,Üù¸“åëf5ğğİJ6z‰û4¼¨Rz†â¢×Z #Û&¾Å×vM kª1Ğ7Lßr·	/TÚ$J„é%ƒîíàï¶ÃÜBgÃ—2ÿ*;–\Ãüµk$ßHfãPÓt!ÿípî·±ÓNQÉmf:´"»cø›š£ašrØU>¨ĞÊ¿â_”0q
ĞÁÄ”¨k\¥ÊÑrÃyIÂq`@¦a%òèX.¡±©˜¬™Éz*˜wq@¿½iaW§ç¶‡lTQÄRªnwÙ0òƒ.[l¦Hç”}F?ÎyË^oë‹½šûıá	ßíòˆ bœ:Y$Vd¬†O°ò·ßßé‰hÿ>7õdÖ§Ì¿-Ëô’ÿo»ƒ8Ô8 éş:ò4DqøjL²D@F.X8¶^«ÖÒú„ß°ÁÍŞ‰K>oË©¥¹×A"¼r²U}îç‡T³u^M·×,Ël×{Ó‘ÕçÄöÔÑÎŞ~G¿{º
«Îú#n‰ÀÉuéVû„×¾¬˜e‘Á&¼S-¡Æ 8ôœÅE37‘ÈkNŠ‹èK<Ê‰Ô‰RŸ~a½ÃmAƒÔŸ*ı¶³nTû7¹vGä™rx9 šØøV¹àô½FS¿İ+ìÊñøì©1šér¡n›ĞO7R;ŒÂAéO§Ä‘É•å›E²ç &L÷æÏ¯š7*D÷(ÃEí]¦í¹çNie…yµüĞ7±DŠXFÉ~C\ ÷†õå‚%r©•ùg·I•Ä­Dö_2y2ÀHOAq…tãuÈ€“fãWBÅxóÈù¡c’QJaB
àYrè	,î†[Ø÷•¸ß&¼9…+A‘‚
ò`Æİ1ùâ²–ÖIæÒšWD–z‰e€¡M2Õÿr î«çk$Ù˜˜ö};çk¤~š$ÀäeÅšLõ\ËBK†›8TPş“±…öÅS¼â¾WšÃØ¶B,r“ÅáYe·%ué›
<|™²•XÁnØ
 zĞÌN‡É­WÌ­äœÈÜ3›8ò­·Å¤$‹ˆZ-³†¼_ì«t~y›ÉSöVŸze¼|¡d²2ğ†ïUbú×ãºİUló§÷“ŠT²N¿“ILŞüqšµ¤é·¦Oí¾•'Ã¯Ğw9}n¡œ"V"Åi>®ÆóÌëÆj¤§¬¬Dn;9hÍ8sâ‘*÷4Ø\ÃÓ£©-³]dè1 IB·âÂ`/Bİrúê´(é9ça™-6º”Ç°¾1ÆPâ±‡[L5”½°—6ê×‚¹÷2K0İªkõtfõUXifÇIGJãÒ_¬ğ¼ÒË[lÍÄ‚UV/óxôXûTv{ ×ë¦§‹¹Z;peB=ÍäÈò É›eSA`Âò•å@mÄÆwÄ(âÊ‚¾¯w]ğqzQ÷râ€oRŒMš©Šé@ôo©Ö†«üWrmå‰âî¢†ì†Oÿ8T¹iÆ" R–‰}İI7¼m%ÉøÙ‚Qğao¤lOÉı»a›‚Ò<	jÉ*c™µ½…ÙÂİ”ze|vş¥Ìå´}B@fkê™ë'j:‹$Kò<í <bãØ•zİò³„ƒƒ’¬Ù'ëQ;‡>‚¿û@Yk)ätØ¾Gò-ŒX»„ì¿>=šSvë]f“‰1F±`Ñj
Ep.¦ ˜I*¶Ñîhšhø'H·ˆh¬¥ˆIÇŠ
erÍ¯˜ø>3Ëôx8;jûûÔ ŒC2>Ú÷Púˆ²aIN!·££ÚÓ¤Jøû¢”İt‘C9úûj‰îÎ5¨O‰«v®š¯Ïä ªø’«fÆeVzšã¸ˆ’^Ëqá¨rLĞkát¡‹©!!˜1†Ø¶GİÓkDÈ'”Ë³åíØÉs$}.¯K¤j³K½ÒSV€ØóäÄw*Ñ`ôY¨…¶ß®ëB È¦U_×/"lã…¢B9•Éãè~O¿ô(s¼ºğsÊåš€Ÿû}§CP·¹Cæ_K†.ËIÂ¶Òû˜ÃZy!.((j¥¬Ÿ®,*²P_¾3S4n}“.F'âhœà'œ6Îr†5îà¬%çV¶óùîüd•&U‘z*ãÔÎçêbÑÜŸG•€}5Rœş#/_1dïèl‘ÊÏW Íz–ëU© "ŞórÁ(Ò[w¾•	C†&#”{]¹]·"-çû/ôrÂ@}{VŠêsHsV#<®,dE=ö…w-íl{·È„æ!J°»Q8HÈĞOfj’h`b¾À3*º–`J‘71Ñ€³sG‡±h¼eD&'ÔwÆ‰dAºt D	âøE£(4Ş}ÊúĞfà[`ÓG9<X‰C!¼>ø´º¬_U†°Í’u7bmú.o…E‰È®“¾GùËØÿ¦}Ÿ;w"`Æø†COÅ1Pä:»ŠĞÎN¾ÊÁ¯‡÷AÓ±GÅZÿóÄ„˜Aò&ÕaBéQèa	óİ¨BT´ÏáÃÙmF„f,Ö?u¹ëšË4–oFy¤E&³I•5Â,2(Ç	ŒñËıÆ,by¿şô‹ä‰9ëZñ‡;ƒÁT1,2~ˆÙÑIgWñ¯V>FlXi-qÂ$I§Âºîı9|Ç5¸*ä„Ká[«¸"ŒOB–„2ÃR…¿ÿ„™Ø¸¢CFâiY¬5YköU‡ë×Få3XöÚŠÚ7%E—İÔ"å÷6+|òÒG£)YXÏ²[’Y"%²Uuî‚J®ÄtƒïÀß¾İ»D¾x(pæåµôÚN¨Aæ€UpªßÁi²*f$\¿í‰©¿İ;ÕİSÑ^]†¤eà:8ı‡*gë¦eÎ
'+öv+×`÷ kö-•ıÚ)K:Gd½¤yÊpe¡‚x…¢“ã‚)Üª¦t£üJÙ	‡úb¯yÕ°úù…Ú™Õìaø¸#é&6&¾Š?æA¨p}¢ÿÔşı@¢Å?k»0:e+®¹)PLÙíŒñôÌd=úßÌÜ\0“ÏVJNáv••-·©uÊf’Ç¶ƒv…aN_²\s¤É1@·éSHI®9½¦3)Gú%<l|Ìf¨©º9&"Ók-ù¡|çp>VNMŸ5û?pOgºî˜KßR~’TöÏ‰|’<ü *ÛÕ–@:’FXc¾3İŠlv¦ ¯†ãA3$äÇ$IäµE‰ÉMñ°(³e6AMÏb†ÛÀ¨zw]E¥„òWznÑpéYá VGŸ¿œË<ÒAÀÉˆ1ò„Êú ]ré†'^Ùa˜_°gŠh‹ƒ¹5„øK³ÂÚí˜eÈ•Æ37ö#tŞ[b’¾ôş]Ù|¢Cş3Á´h}ë€S(¶¶¿{œ`ä:)§¶ôZf!‹oº>—p`Ùqµk„„õP%¢¬ïMt÷wåjÿ$ÿÿÌ%ËßEß*Åñm[2Ñ|ñf	„mYæäbˆ£İ‚‰¡öÈuTH—u+ñ?W|J|¾7í Oaˆ|ËĞÄ-ÿBÍl`fjŸÃ^¤¨úæËÚLÁ ¥#ìmÁZPÅ`'í£²;½=rÕœëfj§©¦v¢	©Xxà±·Ö	™Š4:ätê„ÃdGµ×ò°v2)8`TÁÀNü?i¹éÙí‡æ˜˜S]wÛm¶|5a>öE–HOÃoËc¾É¢¹oµÈ…vÀ£åøÒ+JÉE‰zë§’·ŒY ´ìeãó KO…éÅ©§mKŞÉŠŸª9P3 šš7øı;”˜!lg½x¬YMiğAÃ½K,Ej¦<§]Û±!à‰ÃŠ{n,)î»(F|yrå@~^‘ı?# |½õ¯£¬ø×Æ‹¼Ê¬Nô
`Rg´Yi¼õuhÈŠä§2;?æ{éA2-&303å@=ëÈdî«zšòSr,®Ì`Se˜ŸÅÚ_|TYÏ Ì}áÖYmÀÓÄ]ô0<İ6ê–F'=ŞVŠG_¶÷&”6gñş†ÃFSAİ¥M‚e½•ÉÄí@Î?Û‡7Í ÔaŞƒ{«5±Ş¿òÁ¼8MØAIùÇ[+„³‰t¶¦İn•Ù7	“
GxU˜L–T}wâ÷»›”Ä!İ=iÍÇ×,¤×F¼´æ¤@fI„z+Ê¦s¸u1qş\Pä–İÑELLŸ®2.ˆ\jÎ\Óú³‡nw¡ß~úİÔîÌ›GŠÎS>.²š”5ö2İs4QÜöf+D‚×„æı¹ÆİŠ×.ŠÅh–ÔÍµe„Œ–ÇUA2°Íh£w¯Ç¾³ı¥ÙVe§ü$n,ä!ü‡Ğ3„Ö¸	 ôM‚ÎA+Ş>Qr1ÊÄ(Ù\d1e¹|šÄa"÷şHüv½Gí}UÆõÖî«öL{c¢s¾y7“äïÜşI='ˆ®vc	% §ø¦¶ÖùÏ‰\{ß×ïè.™ PYúË¿pus¤9HyURÖA÷ø‹/X¨ƒ=ŞyvÌBÚkEıó§1Aß¢· j¤Èqµ¬£¤	ÁÔ)‘ªß(Bˆr2¶=Vê\Ë.€I'ôv£ë-ÔîĞø®_~ktF‰b¨C..²šB{Û"j¢«—s4Ë†7ÒãUci&ÕÛ/„ nL	˜„Qk½Â7
À´=Ç€iÜÁ
ÌÔPÓKn¿QØeX½Äg¼…C09“ùgN"{jo#x3/F	hP¤±²=b¿•(ÌŠªnn'g,çë¹vyT„ÎĞWè®|ëyØê,˜tağn¦+ìî§“™Vaüû¯Ü¤âöñDñZC›Ç¤´ó¶âòD;ôë#!†5ªü½2Ç©hŸ[ğ®öcL~÷C@ñˆÈ‚Bo™èy²Q W4àpb÷EGøBåÉî¬émê¦u~£ï¸	á*g÷½$vZ´ÕN²ğ÷gr'zÙA¶‡Îøgó:9¥k\äÀÙùÓŸ@'~1êe*Œ âÍJº¸ÀUko\e;9\÷Öİ’À5	;cp7æ¨k‡óp<±¬"[ŠÔ“L¬«â€×8{:Òa/Õ,0áÉ‘¢•UïŞü#Æ~ :ŠïÖrg^?ª‹Û•3aX òÈV Ü„Ö}® BUùZŒ­|+:¨ĞB¶ºU¤i‹®+ÊÚÚär…{HT))0ÅáZl—©ò8õ­¦iVÑ6°·àÉb”Däd	!—d[ÇÚ ¹5é’>¬N÷WÑ³¸ä*ãŒšuX\>ÔÇ1ğ¯ÀÔÌ“Zq@1éÈ¼;|<ğ²GÙ¡·ÕAêL“¬(ÑJf4ö™÷Í’†¸›P”$#›f™ó¡iASÓ’ˆVtc»Nô;Éãc5©¦˜¢/¶ú[Fğ½FÖäfŞLE’wV†,!ãÈ³™tUBàÌMV€WfİÇ‘uw
bpmÑåtAà¢è”ôcâƒ÷.½ÿMBB'¥¾U0·¾Æñ€w×X~"ÌÜš'D¹Â^—ÃÂíoa7ãŒÆ}zQ¤ñ;í„V `ø)9¢ì›Ô>LW‚R+2]ƒû B…C‘6:ÚO:9ãÃà­^Ÿƒ‹‚¦(Ÿ£ \úó®6Óè	ô)3©Ò¥8Rõ§on¼Œ>ÌUó!21¼±ÅR{_L=tüFÆ5[Ú£ß
xiK„Ù•z§<³³»+E‘tà²”Ø0e¥Öê¯œCB9€¤ûª[¥ÕİÑêuôo§~\Ñ9N˜Vo¯Šw¾ šIš{%¢²>oÎ«3ÎgXåèM3:•’Eù±çæ6˜h¡ò à'åu-<ü+F±Ì-1c@IY[™ éù!|ö)Ğ”«ë”ôR%t,³X†KBä'¬ı0¦’µ´OàpC
Á(W’/l=¢©²­¨Ú¾ĞPíĞKô@ª­lSßk-™ÒKNàø‚š¼OY½pI3®Íeo‰ş,dps+¡†l@:ü¨f
l¥^jÓ¶Iô#›ğo©PÚ›3}¬¹½#@Pœ½Ãõ1èÃâFßìQõ;í%›À¶r„B•*    R<2æï êµ€ÀUUº ±Ägû    YZ