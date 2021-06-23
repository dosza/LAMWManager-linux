#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1148424809"
MD5="33e433c6d2977a9968f93e69fe6e70bf"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22992"
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
	echo Date of packaging: Tue Jun 22 22:35:10 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿY] ¼}•À1Dd]‡Á›PætİDñr…Cl¾|ã&eM ß´×‘œ®ã9ÇqÌjúñÎ„YƒH<XanÄ¢ç+¶2ñ¬NHÉˆp4'[ìWpÂÕƒL¾Ç>]0ólƒÏ}ëÖQxÂğÇM«ÂW€ÏÆb¾äfĞ©¼
3ºëC
Í©néY
vñ¥*n,<¼Çw:ÄXYÂ"ŞÖQ‹‚Şí•• ı{‡Ï1HŞRG'yfd|6Já¥î?Ï¥æUÃò‘÷LòBÂÇEø'º0›q0 jQÛNÊX›U|@&®¦ÄÕâ>3ôxšV4P¬1”ï¿+ÿ(ÖW´ÔÀ…a{ì±dÍLûÏÉ0)’¼K³yä9¯+°–9øS7œŒ‘Ò|ÕV|£>
|£ó›ù·ZN\wòYÔğ1Û’ï<í†=ƒˆWÑô¨?‚ÜÕĞ:H iæ‰9€Ê<ü¼Ò;x”A­Ãş´¹Öm<Ğ•,ãk*Ç¦ìl"L:ÿ€³ò»ò:3’–Z¦ß#ƒ£?•Ğ }µ¬VŠk‘©ŒZ(uÒØëö¥Ä>q8•ìÍË¨š+¨Ü€®i­±PY;h¦ÒØ#Ü®éz:æ³DaL‰ß‚Í––z£™>ôßC”£]#Ël0Õî=<×ÏSÕVíàa¶ì”¨œ¤ûï­Iş…àÖbn[Dj¨İ?®í_—'¸â¯Ò#ÛÁ­Ğ¸ÅH®½Ja3ÀöÆ¦´‹¯ğŒ¾ÛeGDÆ!£’l¼j='ÄªFFdâïÈ^ÿ¸ÁË9,ÙPœm©¼aôk]Z¡:ÖzeØ~ÀxqòNïA4ŸTíxe  Ş†”.^3¹ğı1;&X ¤
M³‡+¸½ 6FÒªˆAåªÒ’ş5UWµáó×…`œiÛZIŸ|¬C¼0„âÜåô°!UÜ]]Ş&—^ì7Ç….Š××âÙÇDïæš¿/İøûÇG¢FeUaİîz?‚Ü_ˆ3š'‚mŞ¾9{{æQà3¼
½såÛ´orİüÏJ“Ï“ƒS–â»ÌOpß"Pq‘ıÀ ÈfÔ9ákÚù—ü…kÍ‹y„ï¶KÜ2A{$0½ƒØ€œUViÕyç@5sÀ"•@­9Áz‚§+fÒğİğë Ê‚\«T±À2ì÷:Nÿä%îWLhÖD¡>‹1m¢j±“Õ«¾ğ IFúü%XzÂ¤LíG mH4£˜ì•+g]Fİ«§øœ',",$†˜öƒË9^.%µpĞ;[Lİµz#ã:vœŠ8döx®v/«ç2¨¼Šğ	Åô†c0æâÿ
¾‘“Kb¥5bLá*ß´âä(Ù„â
XoI…¡ò5YoF#uApÒdÓ°~2	ÒÄº.;ó·Ş‚‰f)‚:ôU]ÉJ¸Ÿ£	^ÜùDg%	TF&PL^É“îªÔışóAûXgdÁBË®zò¾@,MZ¨İ”˜¶³,oöÜ\DØŒx‹Sµ¶YRX<Eİ igø`œè©+ƒ_w”Oç†±0ÿ­Ğõ¼’›“.Œ
—Eìt8ÏìåMï‘¾ŸÄ¬YªÄ şU¸–Ö¥˜âC>QŞöIŒU'´ø˜”õ/L¨: ¦âã†&ğH¾«*Çœ¹Qm>`Á"^jyŠ–Şí¡Ó t+Í:¡V$İàˆeºMåôŸ¼/£í6ÑãÍ“#ªã:½şÔYø±<•PŸOh\r¦“Ö6µeFP—E…n¹ÌÙ¹Æ.7lêá/Ëõ‹Yn(l§n€F¬Ì#!«´7ïÖË w+ì_:
Ã€«2QRÿÄı	3‘Š—‚³&QW}èeÖÔñ‹éÿ­Ãw^^ÎS,‹r%_ja,‡wvïVVMÍXš‡ûE<J’8q+_8–JS¿×Tº£ı¶Ï«Å,Eş»×U¤ş@_ñé˜ëuK@lTğ³õ,Ö¤’bt-eNf ƒ¶~âãÙë"ùï„zI«I†¯ Ÿr|tÿ‚z•¾y¦mø½9ÀÜÜYjÅ·¡v¸;¥±ÈqfAó!Ìs«H£Ül\ß›c9Ç6&¾T&Ä%¬4ÆDD¦ñÇ 9kªlğvEwğ¶ºöéÉ^œš1ïA‚´€ó±}ÑKĞ1¨Yœdœˆ*[ÇÚÄÀ¾öqØa)Ğz%¾Àc>áŒb,´Ğ‘}ƒ×8¸Ïbˆı¡{p«†Ö*¥ ØJÊÕ˜ºI#Qçuv›]Xòİ*O»RõÛ¤ônşLw¥ªd‚Œ?P8.¥0›Âw]{z½òN)ø/»Ó•9À‚SÍ«•™*/ +ÊW)ám7%µ0Õ¯Öê’@LMØôÈë«3#ş\ıkX9{é½–¤¡Æ™£pu»1cPIY#xp$ˆ
¦Ñ	¿§ Óâ`ŒÓ1ë€¬ğqlò Î±t‘‘12M“¢4Æ!ÁR—Š’’ŞÑ®I¡3…ö~øçv£ôş¦LgµF½?¦³B2y[¥»ï¬bZ³ôœi@î“©ãÜQËIÜyÈ-Rr¯åÜş®ÆØä(š;§H¯Ğ1Ë_A"S¥[nÃè‰ülÕ¡½rˆ¦ó÷8îJ{iÄô&æÍR_åôèÍ½“Kø¿fò©`¨ÚwWwúkdÛõ|#=e ıê0¸‚‰Á—X^Qg{©Y…“¿°öœ~-„Ó—M;h­X¬­¯I|ĞYæ‘½aÄÔ­ãÁqz¼=[mÉ|}pìÕRìRºæ´ƒ+Âb%3áŞ°(OnC4@ÄÀ²[jPZ¦z£ ‡wÖ˜ƒX„`(.*§ùœÌ()/“ı¼aÄ&zk'zÁ±+!ß=¹­UU ñôÉ¤šOËWÔ"û“NvàW²rÜIš‘1úÜ ¥Ø)Ò[(=«æ›šÖ$hnÛõ§ërp—!@êÖ¾~Ë rÄÚeÂèDÇmòÅX¯` Ï‡şÿ¬Û4\çò{˜ˆ¹±.ƒ–ò–0êhó"WƒÀ„ç¸¶ÁV-ëGAŞ8Pš¹L'q¿><Ö}RéCÅô++ãfçù[†Ûçª-ƒùÎ‡—]K3vJÌpSÅ&OpÒ_ÛöòÇ¶loèJjfÎ$«¥€m„¤ ¿à×ûy|AF:p¦03%-a|ù\„ZôñÅ¥ÿ]OÖ•~²yªª4RSˆõjQç|bÉõŞç:ö›à-ªw{k(ßî<O\åoo>£ÿ	Äµ†Aù¹×­vö64£:%£åò*j×åõ¾³±¦2[;ßãĞV°ñ¶;ãÄX–YõjÑ•9„Ãœˆå‰õ{éÉ¡„Ê[€3‡\c–1™ê½µ1U,Z\§SxŸ¡V8Ş»ví[ç=œ%ÀÏ˜[Ó(8Hè‡m¡İÇ‰ZõÃ¼÷¡2ñh>xßd®¹ŠfŒûÊçÚNWOÓŸÒÌ7oŞÍ«	úãK_„f"e!XîéòH xY,ØlÂh¶=ÊI„=®Ÿ¿P!Q #x½tµ_x0ª2øÿ¤E»ç±¢)ySÌ*_¢,o8a6ï*lJ†eÔ3YŸ{ğ_¼a9tìÎàëƒ4H”KWÃœ·ˆŒã|Õá¼™Ù’‚3SÙOu¥ZãwÌÖ˜ªº‰ŞtIhR)ñ»êÌì´)Û‚W÷™KdÎ„uÜù¦Š\šªºÃõÖd~Í;%Õâ9_ÔMËŞ±Æ˜¼dÆƒT_bULCƒNĞç×ÂàÜurÜ)ËÎí€û}»X¹(è–¯QL¨Á6©İŞ4:Äñ‚0›I¶c;ÖÙvLß6³ÉY‘ã_ßŠáæ;alÆğ}ı0÷´Œ¬Ş'%”ôŸ¡eÖæşS}P!bøÏr®ıQÈˆ~‰· ôNG`°2éÖ¨|+`”øtÄB-…Ç¨·ãk–IÍJ5ıh`-¾ÑCÆÇÊ×ûHCnå©Ch>Ä
?Ÿ”còJ@O 
¨ı½d¼u,tEõ|ÕYéŠO¡ö<w‘©¯,	M¥oá£rXº¸2] [€i¨%‹y .™H—ø­Âô
kIí©Ö¶gÄzÒ>¾ä¼Ùƒzo~œwd™p½&×åH”ˆå}€ŒPë¹JiLK²çôUìL°­S=?êßMÁ·fÇeâWäÛ³ MÎ†Æ¨±ByooÁJ™û¦²ÂIv1n[®èw®ĞAô™«R½ÌÇAí÷,âağìÒƒ;’!½©(Gáã"©fæÓ¨¶jbå[#²X»1lÅ›Óxç.é]øÊ«º=Şj:k;Câ¥úêöÌBÈ	 uÇˆÿº­Õü\¸Ş¡£Vl+³Ã€Mº&fe–M,0¦ñ‘”UŒN¹Ñ\dV-ü¼è|\ÿY
;(>€´âôy.Ù`'‰NÙwïÀX_©‹·ãÏL(¶òşÌE©ù†}
–¸îî°“9 ±ààÏàßÌ-baş)ı° ŒU©zD¤<©B°òxÜˆ^E—dA[B·§ˆ$Í(gŸHU!ªê9kbOÁs0Yù†:-Ğü|!âz|“¦@}¥}ÍLâJ½ì]›;¿jb~×·iòbÙ½‹ˆDÃ¢\ïô‡°5=vÄœUa§*p^1Öb#ï˜Ê¸#z¡Ò-»°°5ÉÿlŠ„ù€yÓ]g`ëEnlÃ×6Êpà3hŞ¦É•~!7nŒthQVĞ¼”–*-—ÿOì-J¢Dzri#˜ÉHÑe’kqLŠÔÔ‰{OVÏ¨g›kÁd$»ÊR1“>ª#C¿.Hj×›è@wqëój%ÜËüK"ÑÌa6ö²«
‹°(ªŸ'i„Õ}î/Súj‘Ï-äBf¸3Ô:]eÉÆ×€Ğ™gô³Ë}NÄÏc¼††´uS)ê9ÕôWÃÈÉû5<¶Ö 3¯Ù³Şóañ„•Ælc÷a¥^Ò“Æ}”lx…r¨„BìUñ‹öè¨7ı±O¸‰Ê§œ¿[ŠuæÌŞ1§¨4ÌÃ£… õR@°M¾›®M•a"UŞI‚ûü`¾Ÿ|¢q!¨'òÉÏçRÁ_têöÓŞMUAhK@[	ùU–ŞSe4¼3+Ãº7î Fß›úÎÚl‘Ùi2§2ä… ×:\™ıDPL[V—ãL»KäêÃ˜"äæ¿C•JQ÷IÚNĞ½\¾Ò>Öej¦Ç×¶Æ²?¤Ow1¢éA»DlÃ)vò3`¢Ğa¶0BÀ1ªmsÿ"–Œm:… \œ. š·vñ^bqq‚x!cÍß™`8éÔ"å­’*G<o¥5,ŞÓŠ-sãOª //®[¶Ë Tß69K¨
µì¦\uZ4’Öı¼E4ˆ.lº©@ˆ~¬˜$š|º% "•İ$ÍçÊ;ÌLõ]¡!^×»>œøû®dA$Yœ]íÚ”Ù­¡«ÂÚaf|óAxi-5RÁ´Æ¿¸çu,oæòM€í§!%Häò³:Hê¬şŠµ²kZĞÙ‚g»OÆóöÆB×}Å-T¶š€GÕÃ%ó>­A¾£P• îÛŸÍúœú;ú”]Şİ¯ˆ¦9İ‰n*¡Ê5Š|7¶aÓ)% t!Ó¾f[8¨¬h³Qxûre½uxÏ‚Y¹U©ÓjÔÓ2è?×İ›ÀÎ8„)5/ë¹	HB ÌöJIqêê,ê²8ÿ¡1Ïµ‰ïá»;Û³Oì™ĞÖÙõôR^ç2l4xe¯Ìì\†´Yµà(p%ğ¦Ÿçiº¤ØìµGig<X5>Eï`dú„‚8…‹!°ÖD|Zâ)±*^å°;Ÿ‘ø4ÑÆ]ç+¯Ù˜÷’¯T˜ğc»(KôÓ’?€™g‰­zøS¿òê®®ìfƒÖâ‘ŸÇÎ×”lM 0×MŞ>Ì0µ°R.ƒ ÛÇáJe‘î
>ˆ¯ˆ p?IkTöR•%e‘¶ZØ!Ù¾¾b™’ü0{zÕâ.®BùYgİ¬L¶!-;ÁÈÏï3M±=9`WŞ:³ÌÅëÚK ûËÕÁñÏ1Õ-´Ô:şlí¹	bNn +{Ln=r!‚ÌXt‰”º’>iIøêÉ×Vyƒ÷°{u[ü9Çñ½Ú1Â—Zpv©ÎR•jÁ¯D°3l72Vôu·r¾.sE°MñÈy¸¯£šÕ79ÁÎ;	Ôz]!sÛ^øÿ¾®Z`Ã…\±ĞHŸ¾àkìScqµkZ,ú«s_°‚ğ’ ä§"^/c{àYà>¨E ¡ô­íÏü·Óo_Cö<0&UÃ®Yp©bH®ù·kb$Ş{6ši:…µôÈÈc¾Šºx@m˜›/'CÅ møhêtCÑYßœ,d®%Ù«D8)–Øô.)½-Ë6ÙEø‡Ÿ‘F È-öµ¯ç€òS}ái:˜#TıÊ(€Ä8îz” e-¥~XA_SÀé¯Xaö¥6DÄÅ¥«p.fm@<N«QOl‘¼Ş•¨|4	ÂSH–^Íaš}y6“plÑ_ëBK)sÜ–[nğº¤8ŞÆBë>+ÔFú
@2(X <ÊÄzµŞÎÓClŠİÌÅq
FE«Zrsd¢Ä®TôÌ5‹cõp y°œì¼t‚‡¾ÌFÈ‡cİˆ›$İP7 “›ÌrPb<ãuéóø
¼¤tö$3tÀOWu†-Ü@úŠ›’šøvÁEúsc–pœS>âTˆ‰D`!•y26d™ÎÂ»Ñ½¹>hïOöLixÛ©i|7ÈÆ|—+ı¦Èh Ôïue) +Db¿?"–¹Çgz†6Š\î(smµ„ªşÏ>‹ı-DNâÖoV½ê›Ëê]õı<¢Šå9v±° ú—ßUWHíYjüx²POpşõ÷|ü“ÅI÷}dp¹…½/£Í´GvWgT–õÍtn-¸ÓïP»V~¾ÆŸ´³üt¬Š"^ Ğ4øÙÔ«Á{\¢ş€.™j~•M…	N%ƒpå& [¸©¥ñ®ˆıÚ	å—$}“¢_{öt,(Ì½ÕBLwÂ<82ó^œç£µ¹C?~Ôlâ€à²ò…âûüÔPgÊ<ÓoJ;MĞÅn…Ã4Şö$l[;BÉ×œ8Ò÷ÈËYXÍ!€X ıœ¾–‚Ö½ª—¿o…Nš‘7ÿ0*îRØÔWú™ÿA6Æmg½C%YŒí„ ˜îãşé.ìª1…ÏÃkëZ—3-/¹¸ˆF¬ñÙí'~ É5‰³{q3Zğ[û@Æ6æŞ6 N{(¢ÀkŞü7E—M‹X?ïİÓË~¢> ‡¨ØKÜÒy[Ê‰õ\xéEø¨Ô,ºpcEŞR’@îyHºªOĞ%ÆvH»y!›ø5ÇRîëgbŠóØ4§²u Q»"åè¢.—ãHÆ~şM¥òWÛ†oYÜùl¡Í<Çl·è#`Z¬›U¸'5Ô5Ã–¡‚ÚÖG@mÑâçˆ;èå §¸8M*%RÄcB¤èÆûrL–âµEâ¬Şr@7$Š¦6“İZê…+HßUu'&J)T¿²Ñ½KÈÁ(ìúF¯fÌÀ%>¹]¡É]ûI…èïLdã^*ËÉ]Ä7¹QƒæC_*©Êuæ*“É¿ŒëËpNO<söáÆµõŠ"H.Ì÷`;ñƒZËŠ.Fªv¨à³Æ5½| ¿†8J;0éö˜‡|¿gĞ§z‰rÉççO6: ¿íš7ñUS ËùÎj\«i1GUÿœu5(*€Ìô¼–‚¹|·u”í½Ï”$­¤ü¼Î[~“Ğo>¨•$:¨àŠ@_ÖÊù½¹÷Œş¢t'Bã†FÑ$J~âiW&M“º‰â3[¿€j¿õÀLãÓ¨ØéáÏÏä©ªB—­ËóKÆÜ,Á_¶ç7——¤#Ğ>1D&jÇ	fƒÈg‚1c5;}!r<BE%qrYIŞš÷Ø2dj<úEš2€g¤»~.$R²â,ÎÙ†ß˜ŠNb5)†w^¬;s‹FÌ…ò–	” ¨õ%¦ÔbG[ÊÕäDĞN—şº¼7*vñmÆÊsŠÎ{kjä‚ÛPîÕÙçQ5Ãœª[.]€0,•E°s¢DÄø(O¨‚¹_·#*R‚&_õD‡a(ß~Vn¬X4C*öPñGŸñ;šá¬…â,¹×Ó¤4ñy¥o>;Qñj•Kt¹Ğ¹¯‰ÌL¥ÿ»º*˜Íe§‰bò90¿±£´ í )ÑãF£·£)lÎ…œgºÎàc~‡YÓBCCv£ü•“¿ıØ[ãù¢Í¦×uu'
pßÀkèâ ”ô¿~è£1 şˆ¢°¹¡|ÎµDQ2ß÷Ë)ã®Kÿ©˜Iˆg×>½k«õ!+¢2œùfÉC<¯_‹øÈiÎÒø|a¾xîU‰Ç–xB¡şÉ'…ºÜá!Xr©Á)İkQjş€pËÙgCãéZìü
;EÎñxá$ ÷Ià¯öO¥2Üv8BW†îˆÒö2‰+­^JÃPr”µ&¿‰FsßHòWGOP¶ú‹ÄÑ Ø[ı¹É¼¥ãL8\âë¯¥Òd<Ä I0{-õ„ZÙ—áİbœÓ-„¢•ÔÂx/Füƒ¨l=e†âïÙ¢ïè«B„_ÂTá×àxñè6ıßñÒ–ú}ªë®±…¸ÔzİVàpª_3¥µçëàfŒßªãWk\AŠ>ÓmÆéŠ›r]
î'([Mµ¾ñÿÁĞfÍ3Àwş7²x“b¡ñêC•¯ÃÒCò9¼OşÕ¤º¬p¼RösÀÍŠQorÜÑ¤"S¯ç}ã¦èXú*gDÌÎ4ò¤µ^†Kÿ.Ñ{ßº¡ÆÔ·Á×UŒõ›¤Ÿíİ7+0ãé%ˆ£9PöX'î—Â&4Áw{ÑQÑE,ªéçb”^£nMQUna#úU8"Çöw¯õ˜Êût×€•×N«#¹8)¸ÔŸlÙ Ò=„ræ³Râ>Daq$ö"·£tR&,oğÿoAÅ`ŠšçË*Œ€)ñ~„|’è®–•üsÖ	¨Úï‘MÑ¢‘'†‡Ş[¤Ôˆ0SÒÄÇ×ë3lç¶ø°è¥š&¢Æ}†è{»Ô2é2âÃv§•¯wê$GÛXÄ÷-M˜(óÃ9Õß!2´ÑHq»d$½¡2S';âé›ÿHuXÁ(-àÍ‡0£‹UÃ÷q°S5ê*`7’ğc[í›ö—šœ¥fÎEÜsm}7¿Kur—Å…&Ğ6Zõ ĞÏ¶àEÛKBp{¢.¦°uØ¦–Õ¤c~ë­®ÎU‘êú-‰õµLl¾díĞXRÂû¯¹ùÜ?ÌğÁI±+hš¥5xŠõ‘ÎÒGë¥œ>b#Thñ’)›–è‰&ÃoU¡lÓÁ¼]fô695ÓÿSyBŞ®5 ¹Û5Ÿijw²î¡5 
Õ»j’“ÄÂºù$¢Ö•x·rhnÉë’v	âö˜ÎğÄTáŞ¯ÙÅè¨2'ëÜ˜O˜L?±·óµäç\^›ä'O~Û„"¯y:5Š01 Ù€ª X†ñâñÃº'ò­“¶q”Zı(»”ı{ÖÏ!m…ŒÍz9€;…>j3ß&3»·-KÆ§â¥@í;‡_G×¥}”!{1%ëğJ<;ş™×‹=,.ŠÛ$tÈŠFOÎÌnl
_…±¯2²ÙÄeË¡`ĞÜA»º#&¦™ôì„{"Km£Õ¦ty6şØ]Â¼f<·[»à²M Œp“ËÉ¥o?N<Àå©ª=Ë¨î½z[Ú7ÂöSaûäÖ¸>—°SeÈØëöá¯%]©ÛZ:Pü8r€}³_9ÁÆÃuZÏfä¤ûŸ³ôTwqÈ|.¨­¯å¡OBäÂ£kAÅ¬ú²aúÉJ÷9„,u,šê~DÁêN¡êX²úÊ–(4Í‡*Ö J@ããJ< M3°¬ t€¡ò•Î?‹+Ñšm]’	tÎjõ¾Pò†µ=bÎ4'ÌjbÅ¤£+)dTÊÏ7KÎOlQ:!UøÕ´%Í4»ÊGfŠ>FŒÁ‘r2%÷H\»›r…dFıËÛŠj>½EAøàÃï0NQ˜ğ]­ wp*öY­ÑDÔ~.ÜÒOoŸÓÆÁn´w…y Øğ—äY÷*juêä©E<5—×ICÂFnÊäòµÀ/ve<r_>1İki²	ËûÖ '´èµ}¼Ø¡n¿ø`€ãÂ«BÕpÎ»âdgi¶röê÷®€$¾\Õß#ÒCv[^IÕ(0ÃÊw”Ënÿ±eóéØÇ(-„ö|]>÷=xAó5ä 'B”¯;K€¢ºñ{
u¬†:0'i?ymEÌq“(h-ó|.ÌîÛ´í…ù
Ù6Ã«Ğ
sÆ¨j²/f·ª<ËŠ™òˆ;be[6ÊƒÖÉøü+†	¤º«{"÷9³°½ ~yJ¶üêZ”ÊrGˆ¥_jsâŠÌ PØòfıßb}Ceì+ûìÜçÎÙÖó¹1Ñ[qq33Œ5RÓ5GUc™˜$–íHœdZ¹Û\‘ïÂŒœ}ÇèxäxÊnâ«ìş$¿O¹L+½ë‚bY…Í°wå¼8dÀı°·#nÍşf#[×`ŞhWé}»ÿç`¾Q¶ñÌ»ô¯õ¼X[ÛÆŒÍÎf©ÈK(,?¶«ÁK÷ÈàwÈGô!8y}¿4*÷¨bù†³1ÔÆyç÷‘‡§äeª>'vÒ{xø yvš•Q×yçíöcÇ<Që›& ~Dm—WgçéÀ¿ QI=µød~ÔC‘ŠÙCñ•ßFaÄ}üò*aúÿ|¬@\šw›4>fY¼š‰âü]V>…²L-ÎQWØy
}Ö‹bÿiÓûÃgÚĞPJßã\	>:NË"Ó ”’†–Ï¶7 ÿqäé.ı—İ?YÊ¢¥Šc–Ûz)"…˜jÌŒ—8¼Ñá©ÏUkk¨vöYÁvÎCHFî=¤GÂ\î
NK'Õ[ö¡/dUj~’·ÇµÔûİÏDôıÃ’\3KÅîm´XöóŞÜzxñ³¥¤S´ûßq¸AÛ)f‰^ğ0Ó>lµ‹/¨UìkáÀDoĞ\F%A·8ÖÚï¢›Ä«4šg«¨Ü+¸½6‡7ØºO­gtÃ'×÷”ö´ØµüF”8CE˜M¢´­-œ8¶ø÷¾^Û§ÉÆğ2Ö4ßúŞÓ“Y”„KÓÔ)%‚Éµ5»74GUÆgé²-ì¿ÍÃ“NvÃQ‘¼¸#¢	é›ª÷®ò–&$Ë±§DÛg‚	aŠ%{ÂÙóéÇzE”oú!äâb«gş-wÀİüÓn* @s¹ÿÃRg´÷ã¶Ğ]ÎÓYŸÆ
|@ş¢CÉy~ÙT{TôÕG+Ş1xêÖ[æ¤²]
UãlK¶H¹RlWÇØxHĞ¹÷xñ-8g»8ô­â¤öÅ†"ãv€78l„ìmùGë@´ücoŸõ¡¸>°=¦<!z‰ÿ‰fœí¡)…¦FcE›R6°òö™ÆŸU¡Az<Ù1á*n!àPßâÄ’iPô¹ {RF¿ûNW éÆ2g¾5Z‹_Å?à–Éº`?µ¶xú©ºÜ«‹~ÕöSa™nô+ÂöĞq;‰ˆ İ6Ÿ˜3ƒ§Õkõ»lğE>Ö30Hğ|§31ñ5eÀ”²[ª†rrßÙÍÅOÚ!”®TõñÉ&£¡0÷]%õ§u„–Ò15¯NÆ½pŒsì7èÇ€TL}x­Å Y²&uáa`ïÉå·xZõûÌ ­mò˜ÃÇ
”ª³Z !ÚåŠä SÕS…Ú´YNõŸ…náÇaq/p_:ÈÒÅdª:Z°ãæè@¦×œQ”Vs¡$şlK¡Ñ³İªH}a7HcÛQÓ†™q!•d‡Öo—C¸\Â•}Ğü5wÇëõ(G8Ãı›>ÊıÁ)Ñã•ŸnÎ3SÍ—oe\Mğ®nbÆc¯ÍÆ¨é"û+¹ÁÏ³"·i½™˜ºq(èéæGîoXr¾âñgî]Ö’‚%nø‘
6Åv®”_ìDİz×Hn°|Å¢F	Ü5(!S‡¡½IÄ!ë'kìAÁB¼ÌÊÀX^R™/´›8DİGšÇƒÏ.³2á³N¯«2§ğoDSSÚ—¯Ûsc>Ük„¼LŠ|±OXêühaÚä¥.·íÆ‡#!/®\ŠÓiÀŠ 2ñÒ§î,h7?1Äz+­n(«YŞ¥utï0ıÎå'ÃEõÈe>ü]
gÍ´j=
Ÿjİ”ENÕÌ?iç_W@]2o9Jï’k|ÉYoÇV “1®ÜgÒ®éæ>¾ŒÌ¾å)jyq«¬émb«cDhXú ë•òoâefv’åIU»zúY§‰Ô½ñ.U“
€â”òWÂøºq#„×Ê±erÅÈ,LŒ»k),
SgïK5<<t\$¯Ê,‘Aæä‚.ôŞùCH£wº¾máaªÂvÔ"wA8o²nè„c‹AtİBD÷ÛÜã"MĞà9V-/è¸íM¸ØoÄÒß¦+ wªèƒeö%h®f—éƒÙ¨U‚úLæÇ¨²,¥Iúx_¼»‹ZãA¿Î
Ñ+©Ò¤¹O)eÑtîù÷ ¡9KÆ«^.ølvÇ’‘ë°u'²*3Õ2®t5MâRÂãS…Ë¥©Ì„VÿO¼G)FÊ¤»%…	…ZÕä'[À¥ÃjéË±SKI¨{1{å÷(%¬ «F©~|ğÿõú^ÚI2ÄI²CV¤aIH›0ÛØU`ãqÃ**ÁĞH¿Ÿ!?7/Ò“™¬7şú†mèÚ…èŠ\ÂˆXò¶zç|3ÃÇ™XäÕşÙcì$'wÈD3bør<ˆ£ö/›OOF¸óLÄøîz:;@E<øâÈÙ¿"RË)‡‹Rßš[¾ÃîŸ16êCë{ ÜèÓœˆPŠMiİf«xz15ŒÕ™—?÷ _µ]S¼VAJõ1FxDƒ‚2­h˜pU2Ád.fğ8	ê1Àß ei›é¨ëõzc|ßqğ"é	œ3‘§©ºûÂh;BË7QRşnÀÎ!^ §˜)xû)$ï“Ò7\Gšûİ•Š&¿×„${>ÎZ`·4UÙĞji_çkÙ…,«mi,†ê›å%_`÷á,êsP«%–Xà,û}hg²]óà~Iô®³Ä[e<YU`Kœ‚¼’¾ŸÛ`CÓaª?õNOÅ¾Á¶§7_Åùl¢
d×ïĞhçæ½;pœ–	ÛG eĞø^EÿjÓÓ
İÌH²”3Õüá.¿pÇQçö¢ı©»(dUÇ”ÔÖi61ƒp£ªü ú'\–|\L'[…”s0‹@*Ù‘Y¡¡©“­Ol‡(ò+€Ûö”¾\Eâ™A¾¾vØ”ú1?‚ø¡:I_z{‚B¼!Yò Ë9I?˜¦V¼­ÇéaùmF²ü%mfM¹VŒï7n9º- A§ÔÍÀH*Õ$ŞãõùãAmã¸L^¥¹º½xòÊß~fÎ‘rëD´ï¤«(œ$!ä‘æ(Î[‰÷Áî‰ĞÉàšCÈRô[-h?ÚŒû¿óÆƒÖè¢
F­	5ãiªSiİ0€EØ;J<ÿKz”h#È—jó¤Y‡¥9¥óWkàÊ¶ñÅÖu¥â×Ífÿü	…¾•Ä@Äúî7]¶Îq«Xò9§R·×jñÀÖigUÖÖä¤ä(±m¼&Bióÿœ"®¶s½,»7QÌDXB:käWÎ%èñŸ¡]3ÄÕ¨©õà¼*8R(LÃeô†t‘±dÕı
Zÿ(¤…ö·ãã_¡ÇÛŠ4P¤zÊiœ<"b™p}°yF ‡ñšö/¹“NĞy>ºvKÊ9¹Q+IQ¤hhˆbŞFì2†f4 ¨ôÄ¶V¨(ËéÙÇÉ•¼LgÁûü•¹¼-hµº©Ì©´zœ·ÁE×Ó½›H¶ô“GĞ`ˆ+¦ğÓòşVxg´tLcó‘iÜn¾4Í³Ü=e meAÆß¾£«\ğÄ‘ôçZI•I~ósP~¼°R4™IkGşqhÈ­”
Æl§7úcf'&HºÇqå]|ŠÙën)Y|š´dÃLM¾§08#*ë7öåa´!¢+3Ü‹#¿HÕ@¦Õíf[´Ùmlgï½V£¼+]]¢N™±C…:Rï_.'ˆŞcÅ t½ÛÆ¾ìO©Ä7ß yÎØ) 1_u­å;ì£ÜÕ€M.p,íj¹ñfx‰õØË9 ¬»È~p2–<áe8X‘	­‡îX
Ò¹İÊİLtşëlR´¸œåãxëY÷OŠ¢ÎŸœ‚ïn`)~ÆŒ5‚ÅÍ&C“1\*@c@…è¤`ûíì˜Â­ã]mO,èX>ãßîÂC]"6b&cƒoü*ŞKÀ[ı™)(ô¾‰p6#ÁMËÌ¦£@
.„®â.&•Äo4_§æÍ¼>–èjB{¿"l²1ã*ovG#iˆ'ÆÉ#BU™»o6°±ñtİ${·Ğ•T`Úfšç×‰¿%tkPnåS½9ÊŒkîaD¥ã@éM;½¤Î!•
NC´£ ß}İ¬kÎÁ#.27¿æMeÛÑh1ş‹ˆÚ!Z ğÓó
øæîò´
¾ÍVÍëV¬}ÇßĞv _åûJf?Ï ëüš”–Ô7aÁ„gNŞšd¨”¨+ÈÀ®*‚®­À‚·¬xD3³ècšßû°Şq]÷oÃIƒ½¾ş“ª“d©øuåÈ|ªÛY7CPqãs}vEÍkÿ±íıI[Ii&ÀfÈ“½Ì§Ü}4ÍmzM£ÊÎ+
æ÷Ì¹F8]‹MdÜİäm‰/•ÍNÂ	ãüY£…¬dø¹QP’—s²ô« Ğ•~™|ƒÆÍÇtØcopÊT%›>ù³ş‹@†şİÑ•Ğ|´SôORO/æ©‹† øRŒÚ†·¼¦Gü
~ºÊqPz2¿‘ôEYse`>#Ï2/kF¨
ªÉ÷­’V!,øÈŞ½¨®PRşÚ=|¤IÕ¼ª§*ó:ìãv¨ùƒ@¾Ôø’8CÊHºeM4Fß†mÍ\Ùœ*yß(³©Ís5å÷Ä‹T€_Ç…:ƒ&^ñ‹Z™—Ê‡šöOİB-oy¼ˆSŸ§Æ´K=ÖŠd¬æi.ºƒæ <İs­ƒ>Éû–Ü<¥–CšôPÇÛÚ)Š=£óõÑ˜~àøjĞ¿2â›öâä£õ¿-Œ­y/Ùªˆ:DÎOÏğg4¶¿Ó3ÎÈ]
*ÌÔi¿ÒÂoUqêã¢ÚD•Œ2…¤û	ÑÛ5µÜüØ“)ÌJ<ì;F¤ş¯eT¾ÂæûcšÛjĞ‹§FuşÌ;2úäEäfë`HwhNÅò…4e[º«û«?YèËü<¤Â‰ªšş;	³;#9G§¥¹Î™‹Ø;†<Á+o[ÉZÙ~qŞ–ô´Š‹áf"^Ë$y¾ù#Î6~$6ºq††ÃÓç¦W›œı¥c%
WğmfÅÇ]fâ-†V
n©°Jw9 ÛYÆá*´C…Pˆa{ÙÛíAxH‘TÎÆ£ÜLêòaœõz–6 Bş"kg)*0Ï+	Rız35B5E	sâ{T4QÎêÏ~àÌIÄ„æ6ËM*Œœz{7fŞ|Êí/VlAÇ“âÎ|r?“¤€ÀõÇ˜îò0$/·Ò—cvŞ
|2ÚY@¬gÅm­Âdu™·çL#Ç±û"²Â‡oÉ‘àz5İ½±ÅLi¤8Şhài6QÅoûÂ7ˆ
˜bÀoê|/K½i`EhÚ&(©ˆßŸóƒ¾Ú´¤˜4š€låUö3!4Ø÷·†îÔï¦X}0—²­äD5dùõG`†wMöz¯Bü-î’ù„¤bÂ–¾£º8€±ô9ß¯^4åÁY Õ÷¶Œ{Šë.D[ßåAT'&/ì=(®Ä1óªB²d‰Õ"‡£`í,™Fİ¢Ü9¤›¨:X°³^\¸ÔÄ¤ô>6[€+|É1Yà&SI%bdGËáR(ÃúäùºY“ÜÕ»°Ù»<ÜqxÇ§øŠ†P¤‹üU±‰#y6¼Óó?.ßĞ+›_ˆ(wdPw/R!3![™Gí‘çëmĞ j®éƒ®×ø—@¯:A¬NÑ £øL,ÔT{4ƒâq2SÏÆ
DÃ“ó%ˆ¨oó©ØXkÌ¬ €çƒù®Ç÷j#Dl“šs“kØsúMå8-Ò<bÿS:„CØ~\tUEºçàşÒœ6]W5ÎÕ9
+âêSËtèSfÂ×¢C$ä¯k]VğÄ–Íš2“øá×óRøãLIÜt±;[ÊæNœª¼jûğ\ñ-_Ô¹ÎÎÏÜı¡>ÔÄõjÃ5”1#–û÷Ä1”üäVôæ¹K-è\PllnÎ;k:¦/+±÷h¢=¨;ÓåÆ”rÊX¦8c²†å~'ïÃV¥“õÃõ¿ãµx ¶¨ù»Ò>ç;RdMˆŞŒÙX¸’øÁM.4^¥ñ»¢Sl<î8_	âöà°ÆÖGÍEx´O A–¾:(eÁÂ¨¾ÏŸcª¬ _1ı-tlÖ`èÁ¯2®äé÷­u!‹öCOº¶ "ã^sxAvî`µ:d£¢Ö±jL6>_­¯s*âÈnÑpîç™@u¡¥d²1øçÃõI°}zÇKe;Ù}g»S$Ú¬IµE°¥—u²pD¬ìSÄ_Ø2µØ:~¬mŒ±	>bA7}-DÙ(ÏÈ“Ä_kÙ0Hh4Ç:uö¼ˆYê<ßŒ]ø„ğC8ÄèUI=ivzk.è¦¤­"«~S2ÑWAo…¹%¤N†wNıDt Zúè"ÙÙø,èzĞ‘ÍVñÚè÷qâË5Ğ$÷(½¯|Ãƒ_¥õ´ÆåÙ~Ì0Ô@¢£şãX/rJtÛë@+W³\l¹|DÒL[T}>«¹`Û¡^Åa˜„ˆ%oVHÖXl&«®Íf¬–<úw½îW·)—õıèxÚÅ›t9°AD œ÷ÚÇ,ÛD‡ÙuŒ½üç/' ıçU‡¿Ü«û¢u„¼öÁeîØ³¡@ADko¾“–Ä®"; )	ğ”
ù®æTn‹œ¹Òºc¼%™¾7Ió{ò­7YR^«§³Ş-ÿµƒw?¨±ƒÑR‹ÀjtZå‘6±´¡Q1…mËÁ.âHÒ…½øn. ’÷Kây•æŸëèÊû?M]HE.k¬8›g{Å¢OÖ+xîè.[îe¼zoıc6ô.GK–_ºqcmŠƒu–µç´ÕqW„İòï—Ê¾˜øPµ÷?ø |Ó‡Ùù@¿‘$æY§Å27QrJş£%"„ùÙjÙ;yîdö;æt¼rôš:É@:™¶«®OR¯î³µ„‰ò×»üF®fŞ…Œi§vÕÚüçÉüĞ\ò•òuE_Ş¼•ºT` (¤Ù1 ¼?øŸp	¼Q;¡A§IVzkïkcË•f÷¼Ñ‚8Tr»‘Œ%ö»†ƒJ&VÉlÒ^ËÏ¥Ö;:Q~ûŠËº#YÄÕo¯ÜÆv3İùÌøPNjgªº9ì:–{]ÙÏ›Uk²¦­Mn{ÃR‹6„’Åõ˜DÅİê?–ÒBÏW…!²²a ŒƒğéE­Êû†Œ¿b56xcd	şò2á»í­¾ıåh'pó²Ë 	ÃªV\ˆ¼1Cl«+âÒ¾ãG‡ º3‰áÊ>¦$Ôt£E’u/Çjó“È+Nëo.n˜ŸĞ·"ağKå/‰Úyõ{=•ŠKr²7P›*Fƒ&m5ß1´1ÙLXªĞ]Ú³ÕœöR
°|£à:Lvæ¨àºQ#–‡¤HÅÑIõg>d´ğ¨k1¦ŸÏ¨K€<{h@-­kÊàZ½º}íöœÀ¹z\t±Qfù*)ÿZ´^ÁÒjWÁTœÃ’ì¤
6ìS@$I *¢'üBŠÂÿá)Ø›&GÌ,éÁ4©»ö'Ë¡Ÿ’é©ŠWun#9æ„w…zSGƒU¸Ş¡åk4ø¬]ÿ9zf·ÇÊóŠW§X6‡O´IS„>š•åáyV5µ}¿&±"Úp:á òq	U@oÙ¡•¶¨ÕDz1G)-Åìn°íéi!'ãù éö²<±°eAşØ.€Ş½kşÖÔ+Dlº¯wš»¼vGÏ.+Öğ¶z›:‡Èa>„t”¦^zSÀíHºÄËm¼ÈáÒYôÉê¨:Œiù$ĞÄ0°½ƒz?UÑ©…ÁJ¨7‡îCä¿Cq¦œ€à§˜{7µØhÄ(‘¡ &p'@³éê×¥M~ÂÆMmi¾ÄŒGf(¤FñÕé¥ø#s¾!J4M~9])sv¦ÇäÛıìe1)0òáAVNâÛ„›dà÷wpn	o,»QàWŒiÜ[Â/³—ÚıÌo¬‹ãÜ–sù#İíÛ¯˜sË¥¿ïTÛ®¹ÜÔ)y¾Vs' –¢ZRßI„½DÈïÙóäáj¯…è»´&i¢s‘{¾A%*Ú„/ç‰™3î)R_Ş¡F¨€¾Ö„jÁ`Õs£H+çİn«¿"ƒÑ;ød"e¾•l…=`ºÓöRbïr÷S”‡·¨k‰Û½rZ"ÄA"Æ1Õ®J§ŒíÖÑòúræ'=NœÄ5åDîÀ¦/ê^F-«ïÿgœzŞ-ê‰ßÜÑ~ìöí`BñÎÓN•‘pø' Íêß–ÓR±{ÅîÁcÆ‚’Ê›PîÕ”*Ï“Wpˆo•«K%Øl°Ë½ìAöm»;øºq‚¾ïÿ½­5ŠÂÓ
Úà÷Â}mFØ?-¯vè³vå@²‰y–ÖÏ|V˜İĞä%CğŠ§æDìíö‘h±“™Bù¦k?TNk¡v|ÈŞ‡ÉüQ¿ z_Xh¢,„qxZÒî=Õ_”ÛŞù(ÆŸà)ˆø”Yßk‚V_Ä®³?½ªüËï²	ÍŞ9¿ŞØéo•BO@]E¡Ğ¦çÁÔ®Ğ±­gAë<¹wfõı"E¡.8´eÅ`Õêõ¸P*&}t’lçFÌšXFªW’¬Ğ»Âºö;ÖtV7™kVøq‹òÎjYÌ§I÷m"LfÜšûjr[ºZWí§) ´Ç °egÖ—ë8‘´wÀMbJß¬V½%Æf+›
¥.g'‰Û±ğñ©gº¹E•§Ê¸&)&§ÜmÙF&¿K›ÇùSüGõeŒZ¤O˜w{20ârÕğÊÚ¯T‡À;°,}ş§¥viæ#~`Œv³êNJ[ß5ß¶áÅÖ±y™P–q?òHuD¬úöcG,_ÖÁ­1Ä¢GÃz@ÿ©|ÉòQ¾ÀĞÏXM ëÏV’ù¢üÅº7İgK¬ ’Ğñ#â</8Õõö"ıØ`¸Ş2¾­pWŒ êTâ3½‰’—|d‚_;+j¼dÔµ^b€®Äy!¯îœ»,J|
s)r÷ìGj„Fƒ
—ÒŠ­JĞ=®Ù¼
s8kİãJ8Ö¯ç –à}<ÈËY' ±ã¡ŒÕşLa+•6+©Œ”µaÁïRØ?‚ØÀS	—á_œaJDË¼BÒ4\~s85&&tŸTî=ÇmJ½ A7ÿä8^¡~ñ!ÍÙKN³	«$ÑªæÓ&®3
Ò«ÛıÙö‚Gêq›ôoä™7TrÚœ®xGä1UN(éÉñœ¸ø™ ?X\µ8µjR…Ğqó3‹8Î§¾dkˆEz$èv\%‘v‚!J.ÙhhS ñÄCw;ÿÑÉ¾OQÏ2NK‰ªù–éÓê×w©İûTÃuåù¬·ÄÏT0ûƒ[x 0¨p6œ‡#”©é*îB,/ôå:qàÑôİ†€ ¦¾ì×
ZŠåÔÙàÄKIrÛªÊ­Ô³<qY¨ËŞ§‚¨dJß:B‘ú3Ç,¦a-§$ô.‰N:»ùU‡`‚AdùˆOxhX&È£Üàë£~2¤á<
°bùPÇò‹ËŒÕ'ë¾Q¥X]>ˆé§ÿ³ ‰şßÎ«é][ƒ?®ŠŠ9ÎŒ a+#Úñ'ÒÅMZ1¤UMÊånÂ]Ã›……ÄyÙ¤œ€uY>µıŠp\?è£%ªÍĞïC~hï6Î£àëº»‚®£ˆàO=,t[×ık-Š•{/=‰Èï¢fhîŞZu`¡>œ½vÄ„ÖÅÛÑÍëvi½»kí4âúbG¹ í;_;«®Á¤
‘©j¥‰¶ÈÆ‰À¤¢:ÉËGçóÅÂ¥Ùy0‰˜Ü	XÅÖyN—ÿÌ£`ŠŠªQ.Ü{gøÉş°ONêÙş?¬‹½£©¿ö¯F©vL^à"¹Gæ±ò	²ê{}ºmç‘ì	Ú9¶ô*Ø†NÅá¾±hPgÒttğ¸t,ªKMyÉoØYÄ}G–cxÅŸåÊ#Î„µY¦øÅ‰u§85°ğ/×ÛÊ7{#’]áN½bi‚¬KóKY§œ÷¦ü§>NØğîXŠƒ¯Å„×
D+KV›1œÊé=øR^ï\|° ¤½mX×T+}–gGs­räZ¬:"Šª;2Öøª2Ã7jà5á×‰@•Ö.ƒlïIß"ÿ¾ş]zÜÑZ9y§"ù±˜P¨ÔI¯ü8—äˆèH®ş†”ŒFˆ_"’Ó¥Hƒi[ØçàÕmŞXŞ82ºL}§b8Óï¦yÄß+>h®ùk«º(ànƒp7ÀL~^V}œ½CšÏºÓ»Ñ¢Ç¹ßEû¢FaPG¼DM;±P|[é‹—úfg«!«Š2òrÈün°V$Á?ş …şóû•]ø8®Ë°ÈL‹—íÏ"HßV€½¤çwÆîZÙ±î_w^¿èu±ıtÒu™ÎŒrŒd9Ñ&û´·“X4€®a“·Ğæ`yXÆµ_½ŠbZÂù_û¿t_±‚QÅä'²[¥¨Ô¸¬ŞD\ä^…ëêšrdf¼M‹}ìüN¿ş0Î÷”Íq©ÿ1,òZOAùÊwã6Š`RîÂæú³<¡ÅdÌñïøÅ"^9]†uì*³İïi~ M
*1ËÄÊ”pn#êà“°ÚW1´Í\åpŞ ç‡á|Â©.²·]ŸdPW3nÆsÇ+vİu¤u'BO[ë™îÏåFõÊMM¸Wô¬İ0£.íÍ ÈwÔ%Hª&G7¦ UzEï¥`:@­äXùÅÈ”!ZÍ1ûæCí"æ³©lk¯!E[SmÒZ’—µ¼‘Èÿsªëx­Œq£lŞ>ÖÈcìıuhK~.Sv`aHŒÈø2X^™';İ…š&(`“Š¾²3%L‘áhçÛªxÖÙ¹íØ´|W«Æggv§2ıñCk†ª€,d•›ñ}€xügè¹tÑxİ%ÄîÆ
\ÿPvÖ!zo©"À$šÓ4†	ìÿYZ¿³à£cŠÏiHÍ¶Í¶ç¼}ú±‘¾xá•49‡Ÿ¬mğº®å° ë¦ù'>îÃ¹JÏ£THø&®L $šc,JºÇ8|¨ÊÓ)¨JL«Á-õ¤•Ë5`/ºı©y€2°“‹@L¾?¦ÌhGÉFê0.ØÔ…oƒ[LÀY´'H%ê†«o	c_—¥ûà¡÷ÛN?yÜ	N\ÂèÏF*Ş¤,mÄEP¬B
¶ºVhqŞvDq Ö™l0hS}và„­OAÅjI›Ò×Íî‡™dÇ].ºšáé)öí:}í—ËÅ‚5ıóf‰0LşÄ«¢ìj4şhjw¶ñ˜?ËSû$8f™â™@Ê&ú›bkÆã:ÊïGîM7[ì_z§¼Iæ­ˆù=?æ8†Ášot	Á‹ åë6Bvò“V;ÕÉ/õiœœ„\ß¸ì~poƒ¬¤/Y‰ç˜4UÔ¶Œ=5‚É’á°#’ú9Ë~Ü'aãÍIïXŠÍÊ1İm»0ÙS…¥Op4Ho¯()JğğÖ„¶6¿¯]üFep-`™]Ô¯@Àêa€İtL\R¦ş'“¸…*y<§I!¹WÕî³×!ÌÇİué–»£õhQ+ İŞ³C7¾øbITğ(%ĞÇ¬2·“n)éçMAÕ»![Î¶É]Ü˜-ëëğŠ:†{é¿1…mŞŠP”qNÉšEhI˜.°8åJ-J,'ÅÃöO®Èå•O6z=ä»{–•—}WçyTxyùÖ«ç´ïµ?í×®Š
sæ(4G:]2)ŸÓNÀŒÀµ–Àû—0óáøgq³µ2v¶7<hzëÒÖƒáHÌÙ9ˆ”5 H‡(gğ7ñi!ıRÔC&==j÷ºÄÂvTï~Å”÷F:MF!|Ù_oõ¶?Ö”ÏøKÉ§ÜWp»ïe J|äl´J|Ñ­ÖÀN×s•Êx†Ë¨Ë‰CHUø±eq¼¨géFÔØ4T¾¦¹ü;z.  îşko×÷Ë[oBöÿ¬’M+D’SQ%~Z^ÃVÂî;”7.™€º=ïöœ#ÈEw[ğuÜú~Pæ‰¹ì|ãàù„Ùo€+‹!ÁØŸ6I›ğv¶@ğİè.l hPñKdÍcèPÙÉ‹çí-?¾¤JôÜşÎîqÙLúú>ÂÑyF°”%añ”0Áw«bÒ›ÎĞì¾),e²[›~WäÇ¾¦[Şïf7>|

J4Çğö;tøjm¯×®?€#İüoÕ9CTsˆ§dã´#KªGÒµÍDWœî?Fùõº¦¢ó¦äVSÊğÔšÙ2š–[kdMgÿÚÕu?vú¯ææ3„&‘9~nlÿÓ»îˆ$EMÖÅüQê’ÿüw3ÀRñ¿ËüätÎ@»vØy‚â]gKTËÛ…¶Fhõô_¹ÍÛLªˆR³9È¬Ù3ÊyE»ƒø`ŞI1ã—t“ Á‚F¾!ò>lGæ©yóÃFvp^^,±š€Ò$ÙòÚÕJ×ä¾ÀœõO`CÛ~¿JnôÇ&®{6Ç_SØÆ¾ ßŞfvÅ˜te5ÚjwÈğ/±©KgÈZKÂÑƒ'½ä<ÆV¦L1Ä&…ÙWYpx+;/UÉ%ª©+Z!ÎÀ†Qãõ5é†€…õøŞ£¦ ¡rÏNµÆ(™~:2Hi¸û¬Æ}Ük„ö½E¢UäF9‚ÉŸ†ï£Ô†ÅÇª8 ÈÜYIU: œiL@¸E©UCØw’ D± D|ÁÔ:£õŞ]¿ÆDA¶“ÊÔ[ØcKŠ`Ìã}ßËåşñ§oôTğEÛU6ŠŒ'ò°³‘\“]f#,âø±tÈœ_A´øŠÁ¤`¨¡Clq‰ˆ¸°D¸¦SĞ–ƒ¬––hûgú§rÒ{ÓM‹]$$´÷Qš^òt[:½c¡Ğƒ£‡N†ØZUØ†”PÜ)Whè§ğGŸûİ¹<ñl
_ñù*¥ğ+ŸdÍÓé‡ÒùˆóœØ‚˜niÑnÙ,<ƒüÌïPÅ«:»nTÎ8)³Í‘ ÈöWc*-$ævÎŸ“¤WgêRRÍÒ÷Ú9d%%û)¯ÛEûUšœÚ=Ş|ä=×â$×xŸå½Äóà©ı®dÂ<#ÇW7áÒë‹Ön(3$`×Ë ;¿´›·Y}{½SU XR(çô…ø¹[ì:×t…Zê";_Ay1sÈEîn†MæM[gwÏX,C/¿Ö&±|+9ùLöè7í†³¶‡4ÄË QZ¹4t¬L+—ho+¨õÇÅœ‘E±e{ªgª5ÅF‹s¢WØm½¹åÉH”À-o\aÖ·{dñ2ÁhI2T1¦˜­ğ×)Ÿ3Ø¹•ç?Ãğ®Ë³LGìuê?€åÈ„7î =l­tá5‘L¹d+ŞRU«İ­ruISylS‹i}ä/Ki!¥Éhn5p÷IXÕ-¸ú”OéÛ ê^S3uàg·ØB¸V:›ºxYî´èÄ^2&têÈ¦l‹BI«jÅ‚’Á£Õı°'#®ƒNÒêÆˆJš!ËìD&7-À¾ä@‰ µ]ØC®h1t ¯r_>¨ØÒAp›Ñ%·ÎN¡¨S§ÄµŞC«ô1<’¿ø®
Š8[ÿıL*>„wpGçÍ‹
_kÅ
qß'KşÏöÆÁøî3-%¼—ô‘==¬PÄÈşLä&ÑùFBÓóØÛ–Wµ*À±lˆÔZ¸¹˜Å¦RrÅj‚£¯Œ·p½§™ûFĞ!¶LIÚgk™S_Ş—o*Û@ìÁèîÒ/¸}{Ïê$î/â2Ç)·ğI·ôfó/lĞü!ƒÒr5·Ñ$aûµˆº~Í–ÉÛÈ…ˆ« øMà!‰Í>öX\zº Õ>}/´«õ —õ³Ú‡©Á²üîz¿<
ÀìµW%2¬Î-Døù…;¬knºm®uÊÜÜÎ¦½0€†!u
M1Aôe'0¨Š³•xşÒøÒã«ÎÏy(Çh`g¢Â+Oc(5ùV5ÉŸyHÛIÿ…ŠB§44‡5cx’ßŠÈorîá¹Ú Š:QD½Œ˜£sj=^ÚæÅ/Qr²Âš{ï$•Öb,[ÄhîØPÒ°U÷*Û&§¼Ì99Á˜æ_ÑĞpÆ4YZ}æÊ„©¶$š7¡¶²§¿¸W%
 vÎ½W@×äãÔ¼c?¤w´oéÃ½•äjTİ“z…?ìåëÙYI,¹gÊÙH÷ãÀmÁ'Páñ)µ}§{D4Ë²¯ƒÒ%†²±ÉƒJ3È:U/àÖnšt¹hİ°¤½=ª:™ÏİşåÄÛ–zÀ€TŞU“i¥YÕiŞù½ÌœúcçP–Ã‚æf0”­˜\ŸSÇè¬•x~
{¯‘—¦H–´j¢Ôû'˜rqeW(—+ò÷,‘\–RØ­ZÑht%h¦|“`¼"¯AöA„û<à‘çøı3e_7t·‹ì³>Ú–‰‚„km &r˜PËRF¾Éñ´‚…&;;¢A'ü Bn¥‹ø2,´ĞŒ[ö*Ò¯x×CTS­ı?h±a8Ğe–ÙLİîtØù_;G]<Z´İ¤™´öÚ å3+Îjé¦$QÖ+/šKér³(½¹>Ôé’(cğ%ØX‚ÀS–¨ËK³?cë·­3æZá9õ¢ë8x\À8Ô1pV¦©µw$T>˜¬|[Ùã1ŠDg7âœ•´±®¨äSó†¤1»2âìßnù"j¯2L0<·‡®ÒÙØ¦éS:ìé‘ÒfÊ9–öş[Ñ‚	ip :"ÿ÷ùÜ*a`%Òİ&à#ÛRR=*° Áê¹4oşØù‰ Ñ-|½¼¼Ñ:!R±È²0£;Qà:şíã|‹mGµµA	¨ KèJ¹@"‡>…±ÿşºbw[#Ü*Èà[d7jÆk;ß bÜ¸’ïâ	ÖêƒG>p{|0çYéS2Yèjf­™-´† *ûİkr	úŠ€=ÓÃÕ:=“İ·9c¸8^7Ç~:x_2I ¨ä¨¨Ö=—È¨·TFU©Ù˜âÍs½‘Ğİ/S£¼{¶q EÜŒ!ºf¾½X-©.–Ò±PÑÑmdöKv:xíUèt}0) 67kÑ[¥ãä‘†„[\–BİjZïäáéö;¢_ˆ¸JÍs¨Êôa•€f“óô	2÷™lÂa!¶WÖwxO£ÔOøû¯#ÄÎğ£Ëªğ¿Úiõó}_#15ÕüèàÓê$Ì)}ŞÉsâÓÏÎÒÔ¨
Ô&Ì$½¡S÷;yÑ…âŒÚPï"ú°4ß[p¾B¹³P8ò²m›!`Ï¸ı(õSËÁH7Âİ7Xn‘ŠDØçîl²ãë·O:HY^1À°)Ú=<†ø4o©´åQNOLÂŠ“ŒÓÁ_-]ABA£k¼}Æècö"':qòéŠÈa©6Ãğ¢<S¨vÂ_0ı	HU¯û%‚Ø {5Cö„`9Áb=³ı)Ì<¨4-p5-¹i-v¿‡'À.WñàI­µèüş¿+˜š:µ“Õô|©m7Ù”ÚIeêá fóğc—Kù˜´ Rr-¤÷¼i`·1ÏL€®´mnov/}kıÅ\äßwêìDe´6İÁàçĞô³9<a83:‡©&~7V6Õw…bÈ*×fæÄj1²#á‡¡¨l¨¿î{6Â©ùŞQp(5îîû™ğqõë#‹<ó²K)\YÓ=]ìõùg0c)7AĞ§×‰®l
ÓC¨öÂ÷
Ìb”OrKhÚmr]$@ÌP{g®=düÀncœN__êÛUŸZÖê
œâ&¹N¦\¾}“”>¦#|Ğr÷úG^kãÁ¿ê¸
.
¦‹ğìr¸uÇ15­lÇ[(7Ò„×¬:§JK5"Ó^©Š*#}3Iy¿¦+3.Cªgı×âa$tŒ3zìÊ2Ãûî¯áôJÇÁ>Úë£ÓnPÂoĞÍR,¢
¸V“gÒôn]İNŞ$Ôêş*\íŞó‚ly²€fu${ÀUrWGöpe¨¾ÚŞÃ9×zõĞö–>_nbPıYÇKÄg®¾Rl×	`×ò¸sÅL#ÌÛZ]ı ëü¦AE!3Dˆİ7ùë‚ñÒ1è±ƒ5–ÚâÆå–ÈÅÍƒø^`Yq"`­—h¯4-×eëûİwüzhÑ´×°ËeÎéµå=…ví –>åQ.°œ™Ÿ8†\ÔÆ<IîÂr	5³q€øŒôP>÷Mû^XÚëXO}–ÌĞ÷ÓìÚÚg§B ¶AQ-Fì8M%ŠFBS¸P<•´f{\6öóõ›0‘”KóVdèHï·d8"è¤ßÚ¸\AXv‚K*i»(İ¦6xiÌ’¸…*
<a‰)¡7±ûgŠà—04×ßy E8« €ƒ4t|¥Ê—ÚÏşı+ÜGìI •Uí×s/ …ÑÖAW2ò‰]SÑõúb'[»ó7ŸÌV6ßô9´Ÿøãàh<ÃŞ7ğ•4ƒt’øİ)§$ât?—¨½lÀİ)†ù :˜ú°ñş<GR”m3€¬£&Jölø¸7^’‰Ÿ¢\g«Nç÷€ó$}‰Ny–q5ñk*s£†O¦1s}QŠ]UHŒ³Ïy+0Û²è{\M
ó+ÿÍ£·~êpu‹·•w5¬B• ½
&]<Z,ÚGç:QjÍ²Fmg„;×}úE.FËk®kÓ²V1‹)ÁäZÛÅJ8öXŸù$††x Ù–Ë|ÃCúş]í®j}åê¨lô?u%å­Ìó(ŸuÑV/èôÜ{ïpÀ0UsKO0ŸÒ¸Q<¶0ûÿG5Ì+S:|âÖÈèl¡·-õ¶˜…hìy «¹"z[k#!¿“¸›»İíeMaV2…:<Lé`¡Sÿ
l+‹Ù¡/¸µ©®ğ*ša=sX8À=«©ßT”Pó©!/²>™¸R5>÷²
ˆ¹£çQ¨…è¾B¡ífÛ¢÷• Œım=¸uÈóZQ1t}ì^œdİg¦±«%ù¸cè@¼m=èNÛë”lòBÛîSËôÄÓVÖQ+ƒYJÁÆĞ¾Xré}ÅÒ÷ğ½t2ÙX2Ø÷>\Ø1 Ş–{Åää†áym£ßcUğÿG¥£m¯È÷d†!Ïé¯xÃlèøúDpäÜÔö\òî¢Á%Ï÷Jê3ÑAãßšäOcEØê‹õKúı
^¢|¿2Ck‹Qà»ä¬ıCË…y#tÙ|"²é;\N$`p¼ß+*2Ê¡åú¶ùAº¬.´bâ°äG•ÁåJnö?F	ºÍ­Xá%5på9Sùr·–½"Àáp„-¶$Yù_¬#…sCü”¿iëQt{ûÈ{í2F‡Ø‹r5 c¾óËx›È²L!¦ €$R+L²8#ÒÃş]ÎìG¸æ]ïB×í­q+'ÛµßÜÙÚfô>ù½eçm/Y¨w@ç ¨…Œ¯”Üªá$¦áÌgè}ùkô?ÌÃŞx3ÈC%v5Æ†›u<	”´¤Q³hã€:Áqd¨—Pd°>óxy8U¡#·¥£$ù™ T¢&¦ğdÂ—Œ«‰:r~'K5ïº4H¼©§PHü½ˆ|u£^‚ÑËÛzüÕÆ áµ]p¹oª$Ú,{„ŠSMuÙJsî iùæL‚S¶Ahp)ÓªVÕ:Ã›".tÙë‚®”ÆİµL(ãäZÉÍ?E4apÑö¥Cå­`·ñK„Œ:OèE†Óİ»ú-Û6ÑÉÆ6Gå•{³Cû²Ocæ”¥HÉò"ªKèà'S‹{^›Póü,½ë½±Ìåİ`
 pƒ?Kh~9 8À¢Ç0'1È(+¸¾8ôçläõ1kIërÃfQÜ™6ì¹7T„Haû,ï1rmfmÜ\+|àó[-*}1:CÕ‰óÿªw0m66­Ç×"êcJtÏ¿ŞÏµ5Qq];MX"/µ÷Ï[ğ –ü¤ßó+ó“nzÖçŸFt”oÆqÚkGU(÷Yİ)êö¥Ã«û&å3æ‡ÈÈç NĞ;r}^uüŒ|Œ­‹´c%{jr^òùÏÜŸÑÉ'¤r`
EÃd,WqèigâzÅ_äJgÌß¢Pp~Û‚:š€ ?)˜dç°Wd¼æP™…ğ{qC6%aÊEÈËO,ŸÇ| ùÃˆ)-?KùcéÿÖ°|$ÑNôÏ+ŒõÒRZTÿU$õ~Ä/îıU¿¥½}Ockö}ÓÕùóXjkÀIRâJJ‰ù‰Ñ°Í55÷,iå	w¯7Âİç£ËÑ>Ñ0!”¢[ú‹#r*QìÑêîÑ›¨0ßÕ
ldTzÂe×VùÍ×B’?š„ßü”Šığ·aPSŞßTbBÊ@ÙÒ[à×µ@à²Åx($ƒèrÎ‚f-~-EağDı¤¤jÇ«
.qN§ÆuiEÖN5të9ó€×éé'5t|ÈC—m!K]—)…9pæŸÆ*0éFÇ”ºÜ-•XuUxC4Á¢AVnÜôßG¸Ú}çŠ-©ã4[“Àm²Ü€N	Ô±Ÿ°Fı©c?56‹yê_İÕqºƒİ?œH+Eóa:ğçÄsè=øÚëã¥ò¹XÜ;¥+Kß #o´Åğ?­ ×Fëv$™3=*÷»§Q?C7™˜Yp÷}Ba+·ƒ»¥¬Ír@æ6Fˆ˜å¨4©ÏŒ´“w¡™8cd²;t1\ŞÎ•‡?ˆ9õ†¿UèïCUm7”{M_äV¤¬Ë°¤ıù‘Âq¡ØşÒûn¥B'wş4¤¾2Xqâ	gŞ¤§ƒ5ş
I3Ñ½…
,w°¦Û/? @‹ Ÿ ¾ ÅWhç¤£&ß³ËøS*Bw(Òâµ|yçwö‚“^     ›Šìüø
„ ©³€À7Ø6¦±Ägû    YZ