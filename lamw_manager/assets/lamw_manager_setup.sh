#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3663605655"
MD5="8f7bd22b1de238d58aa9d1bab0b49548"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20668"
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
	echo Date of packaging: Thu Mar  5 02:17:31 -03 2020
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
ı7zXZ  æÖ´F !   ÏXÌáÿP|] ¼}•ÀJFœÄÿ.»á_j©E°œEùqF¹QÚÌïÜh\8<À­£r\ú8‚ä¢şü;“ëµŞ¡±§46d°9)
ó+wG±:VXíÒúgÍXÒv‹³(VH›°A‡ÁÑgÀõlJfF
ªhç>Mx>OÂÖÊ%Û¦õG«»P¸?š*ñÇÄ‚,êQÃñyibjK>~8tív×±Ú­€_ó=RóèhŠ¢0tÒ`:rİ9ùŸ0åc$6l(hˆÁ@Œÿm/YY“’Èñã¨˜6Ã£@ño«r¹Š&ÿøÃ´™y^T_·Ö­Ä·š0 -4IïÁ¶yŸQÄ0Yİ…,´L?¿ –¶Çd¢ Á)âV´¹-”rJ© Òñ:r^HfÏ$[ƒ¸	^œ‚©kãJÏæDëğÔ(«_ìï(¬{zÙ^ëyHzS¨Å<nrË	^ÿİLªÁ'ö©èËe®ÜùÄQ¢Š|Uç¤ğ‹ü!ÉÚ¨«“­Fç{­¶5›ñ,WÎe¨ÒÌAZó=É›¹?’Üzá?ÆT!æ–Sö:ã/uÒ ®óN#£2AßëÀ¦Ôé+Şg‚¶´M1¤üHCˆû©ÛÚ±ÑÏ§`Øòê_­|
n:%	û»» A33·òDÓ›şëâe1m‡dØâå¾J#%uĞÃ»ÆÒ˜#OñÖòBâ®Yõ,ˆê—4éq«!zfzèÁÖğ`õğ?æØ%óÍ¸Ö?È ƒ£6j­Íš`°%–¤N½Z¬ôşÃàö31>©šùF`‹a­„zö+üŞëöÄ×üŠ›ÜYã6Kh2iÇc«®´X+°ø]éÕoT£1Ë0ôº$ë-Õ—ƒê(Â¤Å‹û†3èîw¶‡íà~Õ½¿¬¯3²²(Ô6Jî  ÌgÓEX–X;±N”4brrMé\-xNf•cFbzFëâÂ´5ÑM…wrRÁ İŒ% ~š~—ùW•Ë|U~8J™xCİ÷'Ó¯ÅĞiÏ2y»}&ĞÆ‘òjŒƒ¡
´şÿi?›dí6å	! R&g_§.'ğòu…áÙ±1~iã…Œ+Öû¹a¼€á}ÇúE¾ØqÜÓ.%X+ûÄÄŞ¶äœ¢A9ÒšT½=Òù,€ÉÛv'²ÊòÏ
KiÎè­àÈ5z¦€úÑl÷ãU1W\/ª÷`i/¶Às}û»##b¼;Í·eç[õ	“Óñè¯wF„ˆ¨‡J'×ÕÀ“=#ñ¾~“/é@õÌn§@À9¯0¡aºñk^&1.NQîoÇü{GÍPïáëôiÂx<{6h	Ôâg õäŸ Kph#ÎùÛuêmÙz¦M ôhÈ;c.“Œ½3Á%PŞu¡ÌÅ¢’ÆÊâ¥cñcòVx0xÖêDM+2WÈaË˜íÀ¿¬jµßÙ“=»9¶„¬Ó
¦;Eœ„«Âçq.úËÆ´<`YeÿzAœÜš|İÕŒOíµªSë”†(>ŒÎ/)/5áµÎV	in×Ü¿cÊÕjkëE ÜO©ö†Îè‚ñ?­}Ø÷SDÔÇù~0—su”®¹ÿJd„Û.F+
%mèàE5|5ÙÓìW­h‚ÄNWô  YF‡»NÉÊÿG/wu~¬£ ?õÎº„Uİ™²ÁÍ/‡Lí{®¯4ä–€ÿ°ìÔ…1¤*u©=
ånåHİé,ÕI“siëtRàvA;íæëµ85 ¸çõ•z;ª>O& ª~|Ø+ªúmYÙş|õ$N	M&ÀöS×â“ bNcAÇÙ‰û.ĞtÔ¡>=Õ'jÂ	•Yàå}H±ªEâO×"zD3€…6[£\ÙßÏ pÊÀ¢¿Í¯>ı²nÇÙNß:6c‰'“ágMÔsb«‰º¥|2owbnÇP™óËÕQ¦ŞáËPã9:‘ÿ˜eJı·È‡ÈçÏÓ6@Kôà<_…&ÓÛ$wìZX%ÀxfWÕ"€ï@à4exëDl³ÀfôÈ…8RP†oæ6şèJM·FW¥ÚU‰:³dı)‘…‚s©N&‹½‡SÍ•0ĞkÛÂÑúè+VI"âIIÑ±¼Fûó$P³¬zl]_½vù£¨UVjkÛı) «³‚ÈV”æLÉxÀ0º²ø¥qÍ.ùô ÉÀ¬[£è®@^çOôJ[rŞ×•mûš­Î ´~ÎäØá9<ùµ×Èuˆa®§/4Î/r:¢`_›&gÄ„2ÛúD,%)u“ˆ…Äc“ÄØ_SfôíUL¿—mò#f±h4ùëü~}ïÊ^MaÛéëp Õã=ML
t”aØ£ÔÁ%aÚø©ZrŸsqèİû¯VÄ-Ñ}ÓımùĞTïÑ8ò3BÇ¿Ù@ƒ©=³Ò`/ËáÄ¼)”Å0 =çÌI)b>üõìµêCG?¾—³Š]é±éJ­’¦
rEEKø v>÷;.íïÍÀæ¬Xo2R@öHN5,ô@Ôt<Ê¶w1şâ%‹†İ¤Zxs©­‚„ñ¨Hü„}M„ú9:ÈÓç¢!ôöX0#>¹àª^íÆÖ²œµ>b$tÀ¿¼w8äV8àÛv‚Ì½}”Ò9­¶²/ÿ±i’÷nzQ ßBa¨\Ë&¦Ã$Pü²qòıœ)xğÆ<ÀC³•“¿0*m{»@[*Ü#í„PÔ 	t¢ÿ]Q–®å…xGüZ‚m/…î_V€"-Xİ-—ó€¶ª(O•]À1(t£Ü6yŸ¹H’€ñÌçÖ(~Z™:êÄ¨ïDô÷§•ÌqÛ2u4$¤'Çës¥îZü~g4¨¡ü¯òútù½Ÿzê]yİ%Pâıé†~ÖI2#áÅÚ”íï\c÷ÂõÍUaÎÈÑ–ıInëxRœÒ²èÎ3e~ŒY2¼¨²Ö'Te¬ƒãŞ¬sbô÷uìLı ryc	çQ­Eî,UÍãknZµ°»­]+ÂE—ÔûH”°¢ùsoñôŸ L4ıLi¯Ã›ûšåÀ{ï}–÷ÔóGì¸Ê*SÉ]ÿi
L	Ê±.–Hq™ÍÁ\;!¢Saª[j_}dğÅ½wo Û¿ğ8ªò‘•MæúÅé—:–f¹QĞ1CN~)#¨R)ÄŞ
x5™Ò#7‰öÄHÆª®·W™„¥¬®ÂøOZğ¼é«a å5 Î{šçr¼Ó|¦fè
\İ•tĞ=*o—¯KÛØYü¿GÚÇljùhÂÎ#Ìı+ùı=°²I‚?Àm×íXƒù±®]BaQõ‚Pê‡Zì’­şª/‰Ğõ©c'/ç×LN:á¥tÿ,xÓ'~Ä²¬É:1¡ø^mòtòåw:I~@¤’…Ê²Ë²³BHée—äô¥¿hjÆ ŞŸL¡¶Ë Ñc„Ö†]–U¼:G²dÃİ#ßöôâÖTnšÂôï³4zh¿<Y¢#‡FdÙ^ ¥œ|gÒ5ÒˆÅö×DtX1N‰*ò€¡V‹G„8R{vtg^è«dÆq˜…TwM‚Œ,‹Õ®HÙè¨û¯7,ë^-œ3%Äi)Ä8Â‡k'Ï?â]UÏ½8Tàçñ•(”ïìyîòn-\î>Ú¼k³[Q—¶Ö9Áq0Tïÿæ$l”
=‡réU·Áî\3#¶uTÀFÊ0cwº‘0Q€kçõ Ú€ê…ı%…Á…õ ÷R‘ùdKTmŠYcyq„U«gfìâ$áÖÕôüJ¬‚6¶ı@pÎé -ñVM0p~'bÍc3u!_
O¶ÖğµsÒMU<ÎÛİöô`Ì+~IR5}Ã¢›ıe¶Ã»Òïü4s+ğ¤M¾÷KÒŸAYK2©ÛC)ŠçUoY
ıÌïBÃ…¢Ó.}¤7Y„”#ôËdpRQI{hÀ"—˜÷¯Ïë[©{oĞêÖ¶£+*ŒÓ‡…¹•;RÖ£äÍ
ı‡Ó&è™Ù,ÃÍ>WOx0–
])_çÑ×ûKÓÒòª<¢õ(üèf³ñÿıQoD˜“@Ú”ÃËí·iM˜9%öÑó2Êíç-æÈk²jƒZøÂòøòv·héU}6Uƒ†rjæà¥¦ş¹ŠGğØ˜¨‰¬¡CåKÒi´I…Ê}ÂàíéOIv~?#ÒäÏ‹+:“-¾7—#ZŞüxNÊ¢^Ÿ†‹W„˜:¼#uÙ­|£¡’ö‘^àIwHëÛ6RÊ¿¸™U¤jXcQ—¾´Ávİëm¸T;­ººËÆIí¡P>„O‚Í‡ÿU‹¡p_ÑÒ²SI„«ÖV^Êcq–[¯™Ez¾JW,€€÷Øø@`›åÃd4YC¬¤·}qmÔÇ9…ĞXec}/©ÏIµ±Ò(‹Ùk ¤†’p¹de`ˆ„^
òmƒıÚ›‡†í¡µ¦{%$]\\9x£a?Í+J4×HöhE ²b-og`7Èæ®KĞd]2Qß¯ú]ÖMls ôÃİK³#¾†èé7rç¡qçÄgx%;àü“™„½±^a¶¾V4õÏúÜÕ«²à(ªİÂµ°òù&U…€Ë<ŠA¶èš^ÛïÂïEâã «€Úøø3[^šx
t@G{Ùâ=>eû0†!{C~i”q‘_–Î€±‰!İú¾$úo†êûÒÒ¢éFñ~ú‡5
7t‡!ººÙŠ.ê„æ&çñ°whÂÆª¾H´‹cš®/ï)Š=ï—Ú-SªøiM¶z'ó™Õ×\×9p9NëÌjBûPğ±YwK5ìØİ½ñß» ïKj'¤XLJø¶˜ºd¤ òİpìUXfÙF×ÃxhŒ!˜Ë‘0ß.!»­µŒ«ğKßÊ#¼Ä¶æ«‘†ıUæía¶&’Rh8ÕC•´2eºøî2ğÁnI8í«ºlYÚÜe2AµV«YôÖ}?âs˜ù£µ~<–jùfÚm#•ÒtOÊ³çÏ¼0ZÎ©$;Ñë†û“Ú©$B½[	 —Z¥KEo*…ŸµïãgûÑõî¸2Ë·ÌY¼¼»^Ò:µı{Äb>‰ß(ìØÿ+}Ï€úUÎ´lÕ¹·›D¿Ò'J/¿EÃ@g.-qäÈÆäc#È˜$-Ã=Û"DàusÚTê:FV$®Såœäg—şäúâYkæ½±ÊBÈ´,qô/Ì4?´ôÎÅ
l"ñB«àR¡™U¦i<Ù9;Ş]P€1Éy)iî‘Lç’‘ÅmÂ©ävNú]1+>À”ÓàÁ3Ğ•ŸuØ¾İôE8áßp˜®Åo+Çå2Û]<ïC‚{
V"~¤Úa,f*
İÆ´t>Ï\Ÿ;ÚvÖ·‡ÆFàÁ¹ÆŠÌD,è·K½=¶^ß^µ‰—yñtø"@ê4‰Ã®Äl5ÊuO~®£0²}„Ğ ‹D_&œˆ^M+“¼G¹' ˆ"ùv?üoöBRf-ë²¥LìÌë	Ãÿ€œ†_dMƒB7=Â`§,P>ìƒä®ú)ÊörÚ ô17ÛÏ!;!Çy°±qÓ	Å‹Àc½æÌ°ŞåÍßûíOşĞP¬/¦T4|“[¶	èá}œeîÉO™öõy$¸ úÓnÒªøõÁ@)mbä‘¢‚Ïî¾•Ègˆö=-hœôNäÿ?ÁW…¯v“l(¡WÖÕw!eAÁ\èÅkj|]  dİ{Ş½ì/ç¤ÖmZ˜šXØÃ*Õ¦´õğR2}KÒ÷¯xÅ,m:R(œœí÷ÔÇ`3 …À¢ŒM^ò¬ÿòº^³û‘…œ&Yø %¢Q¯¡ÃŸ|&Ê8µK±rÉª­i…ë€úö„OÏ©©˜~ö³Z¸—ğN5ù}Üÿxwí]nÉ³F,ˆ³8#"Fb"N:ó¡}Ø4Búá..º“'[#‘öÑİœİ%ˆI~7#î[f† ÈœÎµªvvbe½Ü«_b?XÒ´Éë+Q’w+éa„wwq×éá·Š¶‘Ğ)o©¨Bd"øÅÓûÚ) ¹!Q/³½R“ª°GV£P$*¥~-&JX¦›nQ”ï{°çygSÆ<t\ê®è}ğ½9YÍÁ|¬Íò°Õ<Ûe>PÎÿ‡%³“ê{…WÄXæFï/¾ğóï=”ã·÷¶¤ /İÆ¦3Yšû)õ¼œNÂäÈŒ;úœDé£«³ÌzÇ‘œòàÚ™R«Üç~e¼tRÙ¹  o«øñÓeî´´jœcå¨+½œ©šÃù!ßp;²Ë2¯'ç¡³F·q«@Ü
ôø·tJ¨Î ÇàKùi«®0ÉaÌd±‘åî?^–±\'ŞŸUoˆõ¾7ç}qé¸ª¤H‡hgËdQ v€Äh—¾Š \ò•ºÇSk­Ri%º…™h0-9zæGæ-s•ÛÛâû?+Ú¸·İyÉÇK)jç–«ÎPµX(ŠŸ8˜’Ã?X¿èhzL¤`Øyƒ?st<”Ñ&t vïÕ(ĞÍ©ßÒS’ EÃäa÷¯Õ'^Åëğ(™¡b½’Sì‰ûè9¡¹€°.L¡ÿÕz{µj„i%?CoÚ!Ì•p;8kĞ$§˜½Xá¯ŸH5 ñîï)a#Ù·Ã±n‹	**‹‚T`×®”¤ ûæ«ê­Ñş;uÊËDÌ	ÖGä…?ô_şç’ë>_„Ò+¢¹Î{ğ[g@Šjàı5İEØRjHMT:–ÚÑ3c$Ai­ŞeÖ8) œ;2zü˜ ú™ìJşÎ,ç‰8D1öL­¾ï^”¥D¾á‘T$1ïÒÎ.­‚mÿÚ½3ÒCxÿøæİ¿çO]€­´6sEÊ:vôªX5ÛT)x×o4'‘/ÙÕìW/ DónúI@àô9Pºç{G…‹”ÁYp½x5­ñ±^)c:†¡ £"íA¿>ıÁƒ¸Úr†ÛãfÚÑu´ñl[ôÃ?q¶×½œ¤é9÷€æsd'²±©—
½uˆfí‰…«ƒ
RIR¢•³ùIvø¼Q{ğaş'nëùLÂ”NçªMTÒZ_ ¢©œˆË1/‹s’ İXS„O£• *0%=½ PtÇk#s…4ÇÌ
êî§Ş¾X * ˆLf®~ÏSÂÚ2ÎÙ*|’`¸g;æí„¢ï÷’›§º£
­Èìò‡_YSòbn÷n·“xeOí1·$µ7Ï„ûk‘ÀïÈ¾7Itú÷íü]¾“òl1IÀçk¾šx}Q–s%‰++S**Gô*¥ám¡œ¢ZÒı&¼oxÛDiíÃÛ]î¬Q–[œƒÁ³™‹š¾¬
ORÊ´ê–pâÙ1êçşC1ó2x_s5¶„7Á0{¨“tU6±³ƒ×çËëI—®©ájyıfo?­±Ê%M£pÍº‰¶~öÿ/*í¡UØøB¸ÚC"MAÄ«BRÍQXKbÿø.DQFŸ68½Ğ+Ã’ÃÇ(pm±4@/|R»,™îiÑ„$èåYï0ÕIØQ'x7å*;¾k…·\@;¯¶q#ÂĞÀÅ»‡Æ:!V<†4Åœc7ËÜÆlc	&ëFã'YÚjµ–9:…ìLí	3c,e¼¿d“(|)Ma¯j¸B¢A/à…€›†6šó==s÷Ê®î·‹ŞÍOVš¨¬jIĞqIÄ|y^%ñ&×ÇYM±§‡JçiÇŞÃ–h²işÿiµş³)0]dëg±ÑÄ~mXå"=›z„vëÄåíéıóß#ÊÚ1Õ‹®(ÙûKrRÃ³@£>	Öó+Ç6xkÓĞ„»Ÿ5T}Ë® »árN%’kbg›İ"ÑSùWnàÛ‰ìR@‡OŠ£ƒ˜	òÈğİã¥sxÈ#M’ìÀšb	u6Ã›1ÁwSĞô9ÍoøàNìğ(íDmĞzø¥¡„ÇÒiÕAŸ jùGô	ˆj–ÅpçfÆ± „„ş†‘}uÒˆ2í›@zW,0¤ÿÎ¬Û˜7SkµŞ¹6èÖÉÙÓâ¹ªYÆÏ~T¯Â¾a/¸À9@ş›Ç³h€k-şêŞ‡]“âÙx¨{¦£ó9‹Ãt`Ô(€Ò¶RÄôÿÖdÆÊP)Pg—‹÷R£A16ªÅ¢^Â&qÅCsæI”j§F­0øºë&Ö«²â«å5Õ˜¼Æ‚`1ÿ°ºYÖ}#ØÚl'™>İj%©¥Á}±yB)gÑ”ƒ•M‚^Õe'¥(“×ß©lHø¬{$|ä’dKèÀLd;)ö*Œ`ù†ÏD;œ*EäĞ—ÏàÕ±»—VĞ-–PiìğÇÔªÅV^Í¹Š`S%Ñ#¶áRÇ¥;V]‚£ÿ»9q(ÇKƒHğ©6)ïÙÏøèR[?ë™~»gø(l*a UœÀÛ:1‹OŒ»Ÿ`xı&=÷ëdhUÂ&‰3ò"“wÚz¯’–uŠ\sñœ	3âD•¿RQP‚,Ã9„2èÍ´2š%Åè¤³šu¿*OˆŠÉ?'”Ù,[=êÚW¢¤æ4­şoT ìØ}'é×ó‹aÑwÎØñÖG¤fñ,Àóe§¬Ğú)0lëÿq¶ó®:ù¥s¬d‹]Uì“LÅ>zF@¦*ı“,¡aúµÀ†€]J\­èã{ÚjXÙI³ù¡‚ Ú$ÍEúl”enü`“*ôÔ\0‚+×ëFÜ€9\üœ5pLŒ*´‹!‰	Î¥jW%ãûËÅÿ|ÑJ	Ë×ÌÁMpºÃ&Zæ_ÃÆùZGÜ„Q­Œ&@m„Ÿ…ƒVó4¤¿á± níÀÍbĞ4±j_Ş{&•):´ôêÁ+tÃãuR¥é¢Y…ğ<GiJÃx°úAµÂ8O"S5Ö¡ssÚªâ ù fĞÌtdáı÷pÏvİ­×šöN“,*…Óu¸öèwS>ãÿ×I‡IPNÒş4{Á	BMP˜ÃÖÊ£;ÅĞ¼×äk¼·#ŠjØr­ú_å‹{}ßíĞøI¿êîhZy2ËBâÍw‹Ü£KiÀÓó°5®¬zë$üíË®;pÁ†E,íjt}¯İ6³vë¿‚º\w…¨(šG&
ašÚaŞ|§ô²ËûøæÏ?¯ñ€Y„ß››{±×]YbÔ*5VV9:45o	‘…œà%¡€PÊZU&KêM3ĞfmFÆ.øg®3õ,«š¡9ÌH(¬„~%Š/š~p¹gô[ÓXzbw<Rü±…|ãX)V:¹Îıå99Ô±&tv	x?ùÃ›ú3lBQp÷~†Ïü<LJºDË%?z÷‰¸­şÍÛß¡‡Ê¬¯q•Æ°Â k1ĞŠÛ“I™²NCë%K¦Áh7Hâä=X—m¸§76ş'Õ¢› œE:Ë/ûıÿt"4µ´[Ê¸6f(®ÉİÉšOŒiN×ÌwâÃœ¬ı™‰³ZVÊ‡Jè5™ â;Âj°tè3<>Î„ÓÔ÷@³b8uZ‹ùmá×ë¼µT»»óÂ¾jC!‰½¡é¸éwïh¢ÁøÓ³%,lú¬ùBæƒÅ1Œ%EJl±ÛúGä7ËxjcÙ0“IC¬ª O~@İğvM¢ GÒâŸµéù€ŠC©yêÊİ×’N®Oytk#‚a];AµE¾Î¾£ÂøğúÑÉ5öñ5¦†¦)æ?ÄwÜ|‹%pbmé–gà‰ ï ¡©Q>ƒõíË#3K»˜ø(#c/~‡¦Á£7Ü0Vum7ø@k¦˜ 5İß†¬%½4šp'şŒó©œ8çä¬Ñœ=åÄ%^–îLÔÏ¿ÕŞ71)Ö½Âh‰ÑYùÇ©ÜüÃJ}ÁŒ£Ç(É^âZš¹5yqë"œnOj‘DGä'Zy€}ï„ö`ş0Ä¬Œ-´;Ê6|gåô8uÎ[h™’¨~ @cÁ¨`›Y=ÄÎô´à”®‰%ÀHêcD‹¼4¹ŞGõ2„^;’Øzü…smßÑ‡$¡ë|—N2G”‡UÕJ­Sºlµ.@2/9°Ô]f–¦a\bÎÊ/¶v9j¶•V ì6çÔ@Ÿ:#ˆP´sWa¿]]+!¾¢$™Ø·u•U9„³=¹E@'ú!ÏËÚûJÅ-ì¹#ü÷~´ªÜ€+gA®n\VÆv[üÉ^_×ë ÎŒğŞˆ;Q^9kÀf€óÑÆÃÛÇŒ1'¯Zä½^{•¤—?uqƒv7ƒ‡h/íW6iSJG¬yl7$'ÌÕ%ÒÜç{¹Â@8š®S°Ëd"‡^/T×$0ç¤£ggŸix‘Ë¦jÖ#ÅÂÅPyê×{…H©[a:‘×#:Ï§i¹îûzöeÙfpİÁ=Rqñ¥§ZF°…›halßLw–=­Wÿ§†úè0«06¥Íü*•nğæxÛ\ĞŸæl³£¹¦å’¯@fâ[Ô#±Zpÿ=ü•@Z´ÇN:÷»qØÍ](ì@ÊmüF.EŸõï]ÏJ†ØOt¢‚Nã!ŸT†Á¾ê.Idzeµ~{65M‰ÆØbÏ²HÀzñxˆˆ*Vm×ÜD°áf=íÈÏ²:…4—¤í¹Et%¯ß[»Éôäı ÇgYãz£ä%kJ7+OLú9"^ëÕ•ó©ÉLî`öR(‹]	/fK	['S@uH-K÷ğJÿ¿C˜MÚ°|¢iÄ‘¼cæˆ *Áñ _'übP1Q7_rêL- —ˆx´eÑxã7.|ÓYŠ½¸¿ØÍ!ŞYxXôêQDè„íÅ§Øó[W)÷Z!5–Ö4û­tJÊîAş• .u@§Å7xrõÉëŸ¾jÕôö² HøÊXcâ¾g0ÈšèK²œI+k°Ğ‘èe­Ä9ğ‡ÏWeü³kóW•ˆ¹Pıüa&˜¯^FÀ³Ò5Ä¼ÙO§İYjÃiÀ€eŸï,–%Yñb5ƒÈ.sI–FDsÈUãûÏ|%ÀfGºÉ§ÙoÊÅÏİpºÿ.Ò%ÿnÎ}^wœÑo0±ÛÂ~®sƒÄÉIëƒ©ñ¤°5"‹q¿Ù'EDDK~ËÁ\a(–%îš?½#s|ˆØ	Ø`…µ¸`#69«m–"Ãë4u«©€Ò~DµÒµ¦N%íŞ[¯€høÉSôC“Ù½Ç1âx±¤‚EÚüz–[Íòá2¢³ÛĞ†a~¶X×íµWfïş°3]+™?ÿ_ö½•f,·gŠ$LÌà”ˆí#””:CdLÆÄª@’ˆ}ô¦1ùX§.•œ#}±MM°äæT‚Äo£E€Ëïzı”0ÙsÂR¡3kw–Cy:Œò,Ü_³ºûÿ%ªs1Qõ
 v¶Ÿ¡¼?ÑhÌÄûÖgS)X¨2|p¨TUïÏÅMHŞQöÎ¬ô'€ßÃ:Ó Â…$Ş¸12Ù5ƒ£Ã±Õ­ÖírÔëÑB©ó³È|{,ÜÿÓõ{ôkÍÛ¡XWR¥²$ŒT	œ(ùk§¿]#38¿ *WB‰^‘Óp	Ÿ}?Eg¼ƒÏÅa.MÓÿÅª?Å¯Š{'.rÒp»mÉ™<µıw|é\İÆ¬oŞFã5èkÒ€¯°Ë”}{»XkwCX]Ú†}‡ i¨: vèKc¼*IÎ6x;<€‡­À%Ô<¿!÷ÎTê5yŸÅÏÃÌh|›0z3ıØ(RŒ—Ã»9@
ó¢àÃkÄ/²õúîo¹yÕK_ÇzÄ÷y&óïOÔpİœùğá[°— ¦ì'·¡ØPĞOºßò0¸·Ì¤áóû„8ü<å¡çM®ªûwÿFš%.ÖÙ¿q¦VËkR´¾FÿğF¯^½–&èDë´Å“ì®aÇ‡GÙé^Ie)Û±ÜŸR¼ó„ôzöNqXÈjx•®·Ú¤fÃÇ£ÌîQ4ŸÆa‡„ ÇÚ¶ÿîå=±0ıWÆ¯¸%è»9¬÷c¥¹öÎg:ÿ•ŒşEèìcür•¤ƒwƒ5@?\°ñ¿Â£ÓÅ|ºz8AÂÒ;¼bwº[ö>¢"Á¯?ƒ]ˆÆP2éZ¾Œ¦zÑÉÁ†œj.b–ûûhìô£wš©›78‹üÙk[¹Ä­¢¶·ÊÌü²Íå„mQ-šœ©ôá1©äúIb˜°¨š¡¶(¾(Aç.ĞgI‡òDéân·¥bÍ[‚²ÊYiõD3ú%¸áÖ‰ÄäzƒéÌÙmùzj™xÊ‡(êòíã¼»åù¨ád³:ûHø7©Œ·Äúá‹‹„Áh¼Boı†˜99Ì£µÃ0â%»ì@’/IDKi‘u<1kZø™Œ[p4¬fêVÚŒnnauª(Ô›8­°X§6ŞˆŸ%ĞğcÚ7Ån£Ò–4ÖXE’RØR•*ÇLb@š.ØsËP­g ë`V0Áb^”Ùş0ò $“ÔrÛåhÃ!štWÃê(u‹Ü=j™ × ,»—|Ä«|§ê¡È•ûn	’VTòì×²…45ìƒêGÍÑç•n.ƒ#œD¸]Âùqš¤¥`,ûŞ¼^]·2ˆf„õ{¨ÈpšvB‹Ô×XWáÅƒãĞÑ„/NÔØ+£İ0É4ŒşÔ åÒeâ'¾”Œ
B°ÙkÆ}V~êğÊÀ“ş»ÿ^™ƒ{		(ŠaŒƒ—ßğ—€|ËŒFùÇ-¾!Oã.	?¦ˆ¯›¬|ÿz.‚f²kë‘I4mó(›ª!¥í},ø³ï°”àİ°ŠSH_™ç—Œ-qáÌî}©Au4NÏ(à]$ÛzE¹U31ãˆäJLnœŠ;d@¨’>_C€u ’²¦öÙœùy×à³òn4wED!7Ô"ÉB¿ÑJĞşœ5Ä‡íHcePÑd“ãÙ3–òù2RŠá5½äIx}í–±€é¹îi…ÿÊyWì‰4eX}ğ™6Õ°oˆˆ»L•ö¸úŒ½11ÍÅ<Ø"ÌQA<Œ†çqŒUT­äqYUå1®u§ŞÍ4ˆS&ÏàÎá]÷lÙßÇ,ÊÃs9NA¾™ˆpAÒlgkíì˜µ-8Ùw“_ï?,¸‘Èƒ6Ÿ¹™¨ÂØ²º—ËPõªš)Q‡4nFuf¥‘Øœ6‘!Òùxbk=ÙÀE-¤)N6Ê¹êİˆí“_Šóû™«}®I}Ä3‰O™zPæuŒŸàêéÍ}_G¿Ù|ü„…²8ÍF¯vkF´†‰¡ï‰Ií‚òM8’K8Â—ø1p•]—¢©,Î0¼%UİÌ}T=}ƒió¡ş+!©ïÓ‘ÿsôÿæôÅUŸZ¬{(g<¼/Î›ìa©¸LrLäÖOV>@sÍâŸÁ[-ù$Š!cÂAh¼™~Uâ8R*ü‚ÜZ~¼œ³]xµ”ó„éoĞ¬òŒğ››çXß½÷£ÜÏñŒøËƒ˜è×2#Êü”/a‘uÏÂa$ÌçvÍ›_•@Ğ·Tu
wÅ…ÀıãPŠñ°µ0¥Ø«ËÊç±#¼D¸?äÀŒázÓ˜Ñù™ÿS†Â¦"RO¹Œ#KöU+í´¢gT:ùO‹Ú¦Û‡VÄè[ågN}½µi¦õÄ4µC1¤*ECùğ&ç3åâß-S?@˜/ØvPFß¾&d‰‡ãßï’·Ö»*l_ßÄï§o•d:p	;R2áWÜGtu*¤)·ƒ–Î©‹Dª0°O†¿'€_À„AÂo¹Eõ0ß?œ	Ê!ì×tÿ{¸ïèµÎ¡#G}›õ&8†îûgªå¹ù s¹÷ÄuóéÉTk4º=`@ê‰]\Sb%™8O/5a’B|°%®vJ–Fãƒ¡ó™i…(V=¯{7WşèlÅéay–6\ŠãO?Ö{N>„È\8V=ô;Ûè½ÿ¬[è¦‹„hF8Ö%™ÄæAÃ›n§	Üh0 ¦½]‰Ã$ï´óé$Ûò.†•ÒÓ•aó—¢ Í®èED¨*o’àsjüœŒU˜%t]º‹fÆµ"Œ‰?'3Óò˜åD|ª¸›KØTUiú…×4D`6—iv• FÍÂ¹»È„‘3å)£p‹ƒœd‚ªµlmİzt’ÛşÍº<¶¬ÉÎØ˜‰ßÀìgŒ½°¯Hè¸Tâ
å¦u;fEÔĞoúNÍÍYğpÎ\ü§¯ıÀ©^4ÏL'úG6…ğ¨¨¥¬`vß~ÔU%åÁQÂGü,g Ok‰Tî­Ş_ëaÒ=.l¼U7 Ñâ8èÂŸd}Ìç,táÆÌ0à8oC³ç/CÜ¸÷Ÿ­r”LÑC©ıÙj”ÒV-WÎ^‘Ë9pÏb$ŠpÜ¼d`ÃL¡_Ò †]XÑÍè¯™ìEõßyP¿ıÏû%»óóŸÚ‚>ë,^ŒRˆ¬\èº‰€+Ú+æÆ4@—ôQhÔô\¦BÄ[f0<~SÌù™!æ£?©Ï©¥Åø×}Åi›0y¨C¥lÒt?‚ƒˆpF§ÍöF&=6nÁäûmê6©\_‘b~x›N%Ó?²ÆnS:ƒËƒ!y>«ıŞˆ©Ğ+Úü”¬Å=J’îTvğæì ™Š¼ïÈ¾(<½×zRK.uµÖ×5 N0ıCù8Æ‚–oO¡Ûo€%àU]iÚ­ë!…X‡ÕZf¬sy)òe¾Àœ]‹º9ƒåAF8åàg²*¦ÚçğJVóLş¼Vîræó¸EÚŞx¯|-Ÿ*HïnA;kŒâÚ3e2ŞşTÈ2÷İŞ´# ü^¯ƒÒuŸSğmçAøÍç¥ö‰6oşóò€Iú„¾qÍ{J£rÊHvÑLòŠvŞ¼ÅUK
,dÏ"ı¢‹D}ûaã¾hLŞºÃTIK?ÿNˆ^',—zwÆ¬şÄÖ
¦«ƒõ}w‰D¦ †˜;œ>Y~çøìÚÆçÙ£²Ì}-” ‹Ë\;L2z¼€˜ÔLÿ/‹éçŠ?ªC9M{­‚|cËÃø˜ëëã,4°ñu9c‚tĞ©S>À•SûúU
ûE>S¥æ ¼òVöö—ñ‹÷†?^•ˆ—™Ò6ÌÂÏ,²Ar'=e½iâúÖ¡ä×åNÎ´‚Ø°»¾Êÿ1Prañıa“ë‹uWêÔb]l#BçŒ%™$·ì‰ /Àg¸„×ó|I,ú&¼ó×Gg	m(øÄş¡ã ŒÚPJ¨b½ùÙ9ìÛøš9s?ßğÚâĞÇùø¡œ€¤õû%Û2¿kgı¶&È“0Î”SHÎ€İ\Š†¥l|W¦äêõµáì/ÖS"Î[şŒşRH?$~=aßø
Ô'‹-~‹¯1ª½7öş¢± )M'' ×¿ı÷KóGÆÃ!¡ÇÇ7ß?'®Jˆµ<jf»Rí“_!oTÔ ì’¡(¿äD,`Kÿ>\p>+îSåì{&dw]HÆxÆë.(­ps»Ê/cúÿ²¡[Jß@*½ÑÿE‹pø¡
—pœ<{½]} u´¯ux˜$<Nùè.@i%H`¬
ì‘]ÌoEJ»¨Ë;åaêa ~]¶/*ii?.ÿaÆ|pİ~VåK¯w×¡VÇl"[·€ù1/vŒ‰ât„¨Q>¯gh„Û$¨=Å£—uğfi 7Eì#M¡ÂDc ¢c¯T–€è5’‹ˆ‰¥jµ˜©Æë´f·Õ­GDÂûy—í8hG“©Î2…<õ‹Ñ=óbU²]Qt¿uU‘Ş6òde qÍ’åTÆİ¦.Í±CVlî[Û˜””‚ÔŒÇŸÁ»s&½=dÇÔS±ÚRy‰s›ÅáˆvÄñAë¸†Üš4Äµëîd”mMYDñŒØÃá%Ú§<óX›r8¼ÒCO¿×½³Ö|É™¦êXÿP*mJÕIï£Ù5=È¡IñÀ³»oÍ¢€‰w¦¯“h1	„ËÍºçòügÎz%G"Ë^-<Ö¼òK=Á^¿ıÎ·vÈ“ÀìÓŠyü« vÔ2'ĞpWšÎEş<³¿¦±×&#ı´ı¥Øz ü+y>ŒçDO½À™^SŞÀĞ<‚•L~¿û¶z2Rû»Ú)ÙÅs3p0ÁÏ‘?²Ìk ªœÇF‚¾êÄèZãõ«j¼ÜƒÂ³[ptÑr¨×Éáœk.èÃóè÷¾
' Çªß¨‚ù¡‘<MÖM¯ŠÜøËó%B©/ÍÂ¥!3òû9Ù‹k–ÏJïäl?ÑÖ…‘+ñ$4¯¦wå0{HHßõÄ}
«•{†±¦?ä¯ÇŒ¬é=9~àLf ıÊü‘î¹#`™údÚÃêY¯H¿bğHØ4Wÿ¹9ô†ºtÎ¬gV]qå=eõÏ¼ºj–×ÇÎZ¨ÎÕğ—•*İaiÈ·Ã'>×ûÜAµP‘¬xæ6LÏû€ß±µ~Á^«% 1™Èòï$-A„8<à)ˆÀAø˜—+Yİ6†e¹ÌÛyÄ3¾
µC1'õ<¼Saò?&ÂÔ³ñ»ü÷s™&c)EÉ‡º·v™"ß'Ê®ªpB·ÈgœáÈïEÜqôkEZr‚
´ïúh¦iåM>*NRæ8Ã¼şÀ÷‹²¼}.ºR‘ğ0-‘‹áßDÄl0;uäy.”MáRÁ™53õPµŞ­§;wgŸ,áÔM°VNİˆ°X’*æ…g4J…pæ’0‚˜>•Z„z%­ÓÆ,Ÿ­Ï
¼ Ó„ZF1€õ`HtR,DÏ:±ÂÆK”äY(9™@wşWlÄ…µyÄÌ1ŞšöZöi¾3„Òï’pám)ÂábeCıÒ &V‘ÔúJ y“Ü¦9Cü*D>
@±†!{<­3ëë„7Ú€™üİªİ³Í­>Áê+àÊŞ‡”sû ŞºÈİ‰¨,+ºa”¢•Ÿt7ŒÓ§·¿CàPˆH÷ŠÀ€/¦p¾à³”ştû«àp™WÅC‰PÄÿ£Zš¬)2ÔjgMÇ€Ÿ¼°5Q5$Ü¿ÈCgİ@÷_ızÈ¿z‡ÓÀİYèõWÆ”biì<Er!Š’.ñGŠÍîÒZ)_áä++*×Ì
T¼Èé/…³ÛÇá(uğÒR¦Æâï?Q'{v·„Ê0#§0ä$5îÎôØT`lÑ3ùLÈ.ıÒùŒYäÖBôPÂôEà/uìÁò¬äÀzKxcëÿênö^ÆEã³³pg‘Ì)Ê±m}¾m0gêÿ®k/Qø(CÇåw;²™2¤ÆÅß$YD!ƒRö-¬n:º²ã¡QMH#R­B¶j¸ëÏ}ì[~çòTÙµËG¯E¡ mfú‡¯;ƒg±¹CÇÙ´;pÿé^	”áÓ®¶ ®h4JeŞÕg¼˜P‰hİ.Œåü¢ƒÔàl}¶gç$E¨É„]—e‹¥ĞğÎÉ“$·ââŠsñÄÃ­ı1 LKövşkrï
¼ëüŸº– ëp¡¼ÂŞplIÎ ‡íú×ãÕª§3jUĞx4‘šº_Ş*p/Kµ®7\‚¼d ¸s¤ƒÆ_€o$GË:ÊÛÌÜ¥qµ¿Åp>ÓĞ¶‘ş`H¬·)ÂˆWãt†aƒà¼¿òçXû…|62ô8¦ä@ÿ&.ÀF®İa÷AI–R«]@øPU\U3éf å/İõĞ“Oäşì#À²•ik‰†@CÔHœ°®#09D¦¢ß2I‹Šg*ªä"½[Ó¯ÔÂÕq%|;k&~è¿ÛeÒ«¢|{?gÁ&ã`C*ºjŒ‹|&¢¤cqné¦»¤ßLY(|}û5»L
oıUúÿT&xö±INÙ†ÓGC¹{grh=Ä¯–óB[Ì:B0N;oxš–h:ÑJr(eNÈ‚ç£  çü!laüf|CzãQñ$KkS »üÓ"·`@©€§p

ßÛ ÙWÑÎ²WBùèŞQç£”£JáÒ¹¶R¸ˆßns)o´Úˆ¥sWF_"ÆLnÆBq…öb-¤Aº5Qğ¥ñ€$×îüon³ù#s¯ˆãfû–±TÅßüåUtÓêM‘:Z4ŸRsSó¨ñ÷>XÒõ ı‡@öf…¢½Şvƒ?o=ÛY·ó
ÃNĞo.–XRñ¼Q:p[š WÍ@ÿmŒÿ»âfòív´zÎæ¦JÎWXæ‹¬í:ˆ¸ğRçg™²²ÃÈh~1ª%":ì)j.Ä£ãU!‹fœcÀrŒvÄ†*{!ºbŞÙ;/ş´/«Ì]›ğ>ı_îô9FYÓH½<Ëš©_mÿ“lÈ[Oy¦é~8ÌßÈy*¢Î |hı	F#LŠ"²0VùvåDÅ¦9!s·ïª-\Õ4ÏÖlŞîİ­N’kºJIÂR=! !n‚FZ.ãÑ]œõ3>õcp?#¤Ñqb¡@ûUPmÚ#ÏšœN õÂRr‡ÿ•ã›L Ñ£$GõôÏ‡³Õ4ŞÀ¬€YÆGéu«ô­¯¿Ïºpsn@€l9)¯v×/Ô,éÅfdöKP>*ŸËÄ¹7ŞQø<Q
­¸×ÏÖ¼)A	!«£™àŸôßtzğ;z †<—Š­xHUÊ`HªôÎ‚˜TĞ•ªH"(<9cÜË'D¼6úA"vßKOg2fí½Ğ«Î7êo¡š»¾&fŠ*8‚º‘!ûŞ|ñn1€ğBÖšºÛ%0#Şëˆ5”¡g.3ÈWgÆ£ì¬y*f¿LHÓ*´ã†®ã&ƒ<Zì õ6}¼#Ñ:áqßóÅUïş…'q=\úËIŞ¤°ÿÎ@SkÅĞvŒø+ôœÃÓ.ÿg‡L78×\8¨¤’R,«…ÔİHV×Óì'{sŠ{ÏeÖ.MÌŒHµ(5‹i­Û
[&‹Î´CHÖBèVàòİÉååc‹×¡ÃhÀ_”üœjkWÍÑ\X&­aœ£†£U7ûş>ù›MÏ¨Æm‡oğXuÆÜÿ¿§Š8õ¦4Eá•vwÜkÀr®•ÎõiàÚkÀ¼LJÅ3uW$ngŸEZNBYú¯ë]]ô>Z9>æ‡¹4QµuÜ(À·Û8²¶8ğ§2|zBÙ²İşèGE>§FÖ÷ºÂÕx‡'ğµÛu¡„}-¾-§ùÅ+€ƒIÖwVXóP‘ï#–ßR_?æ½•ĞÎF­˜hÑ–‰AÛ²Ç’?D9ÿÔ¨åÛv‹ê
uÊ©Må¯éâêì6XìDÎƒş:UÒã¸¼n' KÃ/Bkh‚¸:áĞÀ“)4óÀ8Ğ­b÷ÚÏúüŞ£`É·3t§¿d)PbÛ+ Îgwˆsús3"H~ºÈ€z;•Ñ/å/³¦ƒÖxÜÈW‘$NW¤‡šãˆtBŞÏ=¯Yè8Ôvğ®–@‡[ò¤&ÜS9èş®^¨"!‰"•®E…¥ï©PšQ­òïçÇ»ñ=kÎú—€º¼ş˜§;l¨E5ŞBI`¥#¡›*©AYÛ”¨&[…jñS¼ş‚F6!¼€:EZö±C<GbÏbÅB8væûÊm-—İx?åcè†ê/n`¸;æäIí@õ²	Ò”²Ã™£òÑÍ`¨dC†£]Ÿú¼?^NÖÌaõæ‚ÈJ ­™Ñß	
xéá&O;Àà›åå™J¯ª¸MÕ‘Kósl¦WN {:“!•¬ÅpêêpşÈãÎÇ:SİEÏeXÜ©™”6âÎOï¶®UŸ?’q¡ßpUÀèÓoÊ ÉöæTMØY7^›âÃjˆ†#Ë×‹¥Kd6ô[Cå¤[¶X½
Ùmì‡{HUÂJfÏh‡İ.ûî´(òüõp…}˜ÚÏâºp¨z+S¦Ë°	bÔNÉĞúO·•Ô^şµ¯aÔ[ÕÅtW
'@ûšMArHºiù)¤¥›§÷à<ÁPCÏ–­i ‰«NÀƒü@?J›ûmzªü$¶‹§váÍŠt},ò0Ê™½£à{Et.-‚ff[>ëBbby±±,Zÿ@Òßm8ˆ3J•=.âÛâƒì°&Õk®&D8WÏñ5°]$SšÏÓ›ofñ» Q­_i…ËôÙÓb±‰ö‘ºú±på°¥7d”&±¯	ÓGz‚t¤”n¤µç??è|¤@è,»èC,4ı£„8-òò<ìÎ¿*÷iğÛ+úÙ‹5µÓ6ÎaãoÊA;1ñ®(–¯Ù{c-v©ñGT¢½YÍ˜“Àc%c$˜!xô¡½“í	ç uùÁy!7—MÅY¦N½¢Œ½Úèó.¬f?;7È=òi,ğëCİo:e˜@ñO[3=$ıüræWäuŞÃñ-dù]<âMJµ-•tMŠŠP|»ÊÙ;©©Ty-YıĞˆZh°TR”C¤òúèX@K´%-åÆ¶.6A-qnİÑ­xÿ¢ŸÁx˜ÀˆJŠÄ_î–SÀ±ú;ªÊÈö¨,ôÒ£æ,“GZµöÿ-Yo8
c†‘‘ówtÍ¤¤ˆndI]!t]µ?ù …è»Şt¢ÊEe„ö7Áš-H­³bÏ))FmsãÈÕoï,»v…YŒdKí7~UúÜ„it©Ñú3õ?‘TªÀs"Š×~î°è °nëÔvç^ËX´ü*rúpÁ$ôÒÈPªk[T¢Ü1¥†Ü¥U°Ì
»êõŞ1Ÿÿ¢ÑÍ“‘%
ÒêÂğ™ëí4l¿z]s™ª*T·¾©vĞ`Ë•&ÏÖÅÛúššö—zGäÛ5±*\½TJË`t÷³Ÿãtu²äû}]ğL“ëÁµTÄ$‘ĞŠ±OxL¢vÔ'±xcÀVY´¹´9$œs*—{÷œívkSƒøwñÍÔyÏ5zjŞ?«+Ø3Ü0&y¦¸MyL{ãÉ¸ìpF¯ÓK‡¡²Nï…Eİt=Ÿ»”Àê'bâ´ÓU>º9biš•øQ{.W"mGSvšzy	ÁÁêÜg5ûÉñÅi™ÃãŸ†[³gèå¾¼ZÎú~¬–*´Øi×îäPt»ÒQ—Ê²èÍ‘…¬ç#ØÃû¿ê–(}jhˆ°÷Î`Cm,ÚV&9İ…˜Ï,]
›RfQ×EË³Auo‡Qü]'¨|ãIyP2yûEÒßÙ©te‚âœë§\)¦al4móœ¹e88)Ñ:ı Îqƒ~ä™Şıñ`o3™Ñ^‘ó°:1IáQGàpà˜ESª€éÿ0¡)14OyšÙ:íû6@°Aúj•ÅNj~Ù¹Hê52• «ã™ÑıŠ>ãÅ,¾SÎQğÄ¼áB¶)÷Ğú¸)[½¦aŞv’ôØe2ZlÖ€UİÀ6Éáw×•™I£¨úa/{zøV\Á€ )ÜvNA‹NÓ¥?ÚI}!ÖdéçÔcqÏsù.ı‹SLP¥<,·dºè½6m§^NXÈ÷hP›ç"u9KıiÜ3U
c@¾@èb/{ÿªîUÓÙ=”¡.^µÑ;bşªãBñ±DåŒt­†¨rÄÊ¼jN`w¹¬‘“u‰92Â*€Z•[+¬Ñó9Âæıë¾ßÎ&<wd˜kNÄ ñ‘×7aC Ñg±ÇÜ ™ä6¸ËÁv…cØoÌÃâWÖ·1ÙëûŠƒ‘aZ˜V«ØZø·:ŞÇÒnŠ²Œ?^ìÆA´Nx]'È˜¥—ö$êÚûÉa úÙ]M v½ŒëàÜÙ‚O/|Ô²£Ã"ÚNg Añªá<ı­,EêœÉ”õbˆˆmKYë'–e†PˆØ_©ÀC6W›¼Ìá¢Îå¹ú2!©(. CüBh¯S%U2Ó@}s¾pš•vspÏÃÓæœ€—!•~,‚ÿÑ*Ñ/RĞÔU„İ]{üÀŞN ÿ{JApU`bwœÄ‰/±;ÇôĞ¹½ …9•¾ÌjBÁ›1–ù™¡Ùkaä²œ.4öQ¨ˆyØıIjúo1î™6±iëŞ%r%‹ñâá¥´Ó«ïµuLßîÄÒÎ»3ê¢~·hz^~1±éÇUĞåÉ²Ÿà?j¾eRÁ¡=œ%âæ¾ïtA—Åz€ÌùÛ÷éfyŒ²=·@÷áæK˜®lP `—¥®\Ê ´£÷j»mY½ŠÃgeØ\‰wy|mÃzˆ$ #œ10âÙBšÛİ•¸¹¹=T70^g¿4›LöÑó®EĞ˜Óø¿Yæ»¼;ÚŒÑ¨på/v†úu,‘¥¦ rİ¢ĞìÓ–i–‹^ïæ)ÛïæjÁÿİCÆÆ6i[f"7¼tdAg_`bhôÙí–pÀÄ}©3Ö‰”·å ø¼®g«qgåv6%gm†Héÿ,~}¡º4OÓGmÕ„?T*˜LÇô—ZÂekÎ™Îì™ßÃqiŞ/O8›ˆø2ıÔ¢ì\´ñD:_D½µ+‡T?oêE_\(d|Êü5âş§j±Àˆ	P@(§“õIdÔ€úã<,Ù­™í}^@W˜[§³Fvä,8¼f‰¥®#âÖ:ƒLĞà2uË×6á‡×¯”N°,)´¥bæì\Š±Bƒ¯Iœ)4SÊÔ{^“IH«ÖÎ`’˜€ºŸx_š6‚J}oj4éª¢w±éd3}luæ]"XÄ‰%’Âäñ>@zFğHô\øyCø‡	ü±
î¼;´wîºè–I¦zğk®³‹1‘CD°d‹)ú;:-NäJÌªa	42‹§Ê!+úĞWoÙÉË»Şä=Ø£Õ­FÄÄIØã!=„Óy!ìÖsˆ÷	oyš%eÏñ'ÜzZp@ê7”’K‡ÀÁï©nƒ†C¢4+z%$áh"ìº™C‰YzîySñ¬Ş5½	ùñu”{=D¼@;rØçáoÁ:¯´¹o›Mì™gú6ü£&Aı9ÆŸúÂíã ØÌ·ık+‡…õ^{ö$¹B·b©Ììğöv;+·ÿ‹†HäG7·¤ªóv’i{ıŠ,Ì9–¿ïj"T}`‹Şª ˜¼7À)$ñNKÉ|BU¿Sè-ßĞ]ú±~úv2»rJÖËØà´ÅQ)oB	j7k·Ø( )INİ˜Hİ£Ï(•TòÇ¿3ÎŸªvê’uWÇ÷¦6ú.&êJßg”¿7èV¾Î/ÔªR}±KüË‡‘›U‹æu;²KÓ˜¶ô]D-1=¯7Ë­†lª”êŒÊ´' Ù|^‚Æ†N½<6È<!}g"™ıÆ7œ1zg¢z¼DÆr.MiB£Ç=Ã>T»Ä/+ˆ\3K @âë{Gh’Ç{²²”	æ
—âE,WÒŒ¸àï_©1ùšŞz¾Á}(œ””ç¸X'5÷L‡q+3&òÍø“]Ğ³YLÂB-“Imøo‡6•µÙL°fåÖhŠÂÌxì?ø=`ô"ˆØKÁ”•éÕZó¸ŒÈ¬–¸»+OÀ¤(ËÎIÂÅ¦³‘çƒ¥ih+²#àX3\á§t§`ˆüCÅ„ìâc3=ÿ¸yf>WnÉ×™GCNÜ»&å³Ô<f,ß;ÃÏyR÷õ"Ö`Ä³iıâµ;€¡™Rºæ^sòqK>îçHB—€-;·»áy¾–Øm msgF±ŠÀ£ùLpÀGÌn¬"Ò×µÌ³l¨yˆ"¸ûÅı:Â½}Éšëú©ã¿,é ìÈœ»É…§‘S©÷%¬KÇ~Ã/­Ö,‚4Òş%#¬ÂÎg1'¾n—¼[( V½fQEå_l³Ÿ¢Oœ^—Ú-…Lqš»»–]ÆßJWß=Û¾­jfhTıd¹ö2!óGm÷ kğ®ÓÄùAù~‰F39úö)uó Yy	41uñ¬
wü±ä³nfİÅºRÊr0ëÉ=»Ê¨xÉ4´–!‡"P –ÓÓH )óÄ¤4WìÅnÌwÖs¦ã_kÙ›İo•›M©è÷„.´„¥ÍèHÒ÷Ô9ğr§F«'ä .*f*¼8Ì¼“lÁI¸%¡ôX›H9×Ù+¡Rz£İ½Ëèx1šĞàC¦?ãPãïNÏdYjn×‹‡íÆ¹aœ+y!bc†QáØwŒVğş­[¤Ó•ZÖ.gáÃÌZdÇĞğ>ŠHÈ,¡Uİ`ÎQÌw¢^v’³ªÒŒ½ò=«"O£i:É¸b vwj";SÊæûUo¡×:D2ÿ°ğÊ@= ¦¹H	].¢P™P*AbEoWí–
 êŠH,ÌSAÛí‘xÔµ'mˆj4Ã³LÎjcz Mn†¶ìÆÍyÎv
/Au•·ùú{do:JS²´°:šÇÀŸ—»6?cWşAàbákË}cp”QJĞºSº!Òd²"(„29 `…ƒ`~)
ÈD÷¡SâFPùà l ºâX~ªÈ¹jíùª—fF!9‘İÖüy4™ß4‚É/C…+šÊkÄ~wÓÕİ¾uq9—Ó~@œÕ[ÿ!”]\øRƒòªì€$íª~«•HÅX6tç4óÛ0ÄK<öµüXl²Ü ä›Tø–PFãÆßß¦Ë9¬¼å¸†iÁ¹n«Xv"’ÅMÊì¬Dªv×%.0v.™ŠfG
[ş<³ş3pM•x ØéÙR±¸0±Lu%¨ÅXFÅÔA=ó;*K—Ó‰ó‘YtûUZágøP¿°ß@/]-0&Ê°KòÒMS»zèA]´Âp¥FsÒâƒsíŞ°Sn\¾ Ó_ÖŠ]ìµmì‹xµ¿–Óæçç¢§òV—|cËÙÍ47[[@b	eÚO<ûß6ñ İ!&Ö2ÊGôy1‰t÷Š|q;QÇA»û`;ñQõetÏ“á»ïü’2E4ªJR(cíš5PÜ*9‘$7’+|áĞ=8åûÏ°àO² É@k$–.š0ª´²È%ÍjféC’x%s¯!e[Ü!^½ò–,Ù
ÀİF³ù6¶®E#Å‚¨·-{öÚ“læîòë„Î§>‚Õ@~ğ›İ^şµx7‘=ù•'ÃÂÜ l'Ôã>QÂO«€”
&Y~	v•ó´ğº9KßDÇÃDàHä¬ÊÁğ:[+ ´ÄË›`‘#X´Mç-qÜÄ²ï¹ExTçZaŸ'~ 7z±ˆ‘ÓGıEÓwÚ,ñ‡åv´e )H¦–úrN\Û÷ÿÂË8a6ƒ8âª¦{ùq2A„Š¬H£œß5Ú/’IbEL$¥/š‚”äëƒs¦G‹$0Ÿ|`UFC•"amÇIÑ²yT‘õ%£l;N;O€hÏÅö"­˜cwÒ=,”¡ƒF©„Í«îq-~•&E×"üAãSÇşÎôg¹jù'íÄåĞÊ‡ÔÂI¨PÅQ_®*»%ĞtRæ[;”˜tû¾ Í.9€²I{BğšÔ4_¦–ÅÒãiYÑyè²KÙ\3AIJÕOÀÎÏA%ÜÍå§®“¾Vã ×ì¿×…³	Ü%TŞ¬à´4­6ÕD«åˆÿ!¤®Î ¸ï Ñ¢&K\ÀYòÖ`ÊI¿4PÍ°³MË>|ñ†Sa»¸ƒ¹¨Á.ŠåP«¥ó€S¹ñŠ‚ÅCk0ä÷Oy>tG¹9PôZ•¼!öHVJl•‚3ßâ‘/bı†.#Àß-cc©Íù×7‘ë’–q…c>M}k‘`}A*)¶'[h]Uk#Ur¿H R~®Ç³NÀO¨%+ß[¶ÇAÜˆZ§+Rp¥J8Ç;ıwDÜ™K[	SYp“Ô%ùÏ ç°mdÛ™=N©KAJIRòæ§HÈZü5€TŞéSË-ëdÇäzJÚäZQgƒ“Cá+m÷ÔØG=ôİõ	ãõ­v’Ÿ Â' 0„ÉS´ï53DÔí‹xÏGS>]8·Ínÿôg$Í–½:TI=ğç²R·óÆ+íË•5vÉ*¨°¸± ÷ønÍHxXsKw5ëRtlŠå³Æ–äÇW®£cù)äJæááÑ6ôùy˜!œf3frÏµÎÍ§×N>h6~H•o;´ÆcÿíÓ	[eb;jBë16£eøˆñ9KÛcì³Í1UV|&ş™±ŞÛÎ@ aM’7qSàªPˆ‡¦8´]9Rå(Ãm4C"ó‡HE·b:e'Pj]î;¯%óı*¸ú¶í÷…2µ<1{MÓ™?4“Q}ª’gÜã°_P¨Ü–y{'ì™ÆÃ¹òwooÖÙ‹	õ4‘—/uŒ¹ü½“1V]:ñ2öJMw/µw•ãÍ˜®KWØiñH1êv¢^,+Ïàpe/c^5¡yHEpt-W/['›¢Ğ£t}µ WTü˜pJ¢õjŒi¸«5'éğ&_õ²\uX$útiX‘¡Ö†_¹ÚÛ’É­Äo€?)İGNÍ¼U­Ú V•ÜŒÉx@•[u4¤B¹›a-&2Œ„¥’djp”@âzkÒd<ù'xDd¸ĞÁ ß^É‰yrD°B;-1¸3ä[ì½ù1¦uSpUÉÍzê™MoBÙİí¨.êAP”%İŠ‡)GÜkf;ç*JÂ0A3ôi—<¥Cm’Ô)XÎ=j“Sƒ—Íİ½(T  ÿ¯Şm 1İò ˜¡€ ì“Êa±Ägû    YZ