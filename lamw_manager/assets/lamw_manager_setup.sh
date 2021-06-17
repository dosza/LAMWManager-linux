#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3225464792"
MD5="60b05fa993e8204a1989e3ea2e0e3662"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22512"
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
	echo Date of packaging: Wed Jun 16 21:24:56 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿW­] ¼}•À1Dd]‡Á›PætİDñrjáuËğÁIÅí	Só‰\KY›öQ·İ0Wc»¡ŒpyUsŠ–š¹¼KÒø§3&ı7ÆÏ"#´_gÓI"ãÅ¿Ü*†¾dü[ĞÈ£øÅ‘İ È„—ha½-)[,•Åæ-	ƒÛ§(Å«`¦vâe1?B,ÓnÉ˜ƒ¡ÀAŒÆòj¡Ü#5ÂÂ©5=+'¤ÇçÏ‚Ê’2zLj»³²t×Õ6
Æ­°HãŞp{MšÕˆ,e®ZöH¡ıv^2N7n//–` Õ•Z‡m&rìBYÒ'P[úgºŸ¤¯ëƒ¼Ÿ¿
”"õÃ,wG(@º)Ö›w#XÖôÙª›nŸ¡h	qÁ¡ó@Uc9œP™Ëw¶¼\¿¾Ì!k=Ç3wP¬‡¢IbË ‡ğ4Sí?‡YiiÌ!i ÆP´^É›í×¥sâ:%e+{¹ÒòÁgM§dæ‰X/dv"ôñuXfáº1‡nëxCÛfPàù<ßÜØgSÓëMæyê¤Ÿ½;h9Ğ²O};Åïÿ¹€÷!äÚçŠŸ§Œw;ü±˜óI
£‚ı8xn±Ó§=7 <=y¯æ~g)Ánµu¯‘Öµ4ªAìô€‡+†F$’l)ˆªkb<³l;2™¯hò‡½íª÷ğû½\LƒúÕóU ÀÑµŠ8“„òZæè5?š Aar¯N†ÿö¸&Êà,ê5ªç-épWÒ)6p¸í™ ÖÑ‚øñ¥MÊmôÔı)fÕï®VÑËUkÆüÚXJÙÃ¬ÚàÉêˆüæìLÍñ`Èô÷Loej—^±.x£Ä;bÛäı°±ÿ¸;ï&<9’F•JĞ¾0â;ª3¼ƒTejGáHK<àLË8xf êXªP¥×€¬Ø$$­‡’oÃsu,’s@fóZ-ÅÒË!XP».æÔ °ÕÜ÷âŞéYªR³‹çäwŸå¯°E;Á$yÜıš-n?ÂrÔkÚmıTEXj1òòÓùºFÃÛ8‰š0U¡ieNs¨M\!­òŞ>­‰t¤JğK!Óä•æù³¶*¾Æ˜_y|çoÆL:˜&œısdìL‡[r|=üÏHä$C"…8^®©ÛËşt­ZûõØyÏãa·í3}Rÿ¯¾±ğÚf2™—vÉËÆÉ]OI²K4Xø`ß{KÕm?d,~¶¤G2:C˜€rû8ä#ßHB¬<¥wuHüÙç=–‡#PÇu²¤A¾:J x«Ø5è`ùB<UòIÃq©ÊªÖ'Lİ4¿²n1;DßEMXÕŞ›{{?7ñè YÕªÂ¦Ş±Ä+Ö@·nÆ²­šø<Ğ|ãh»¦ôa	f•´_ô#`]˜ñ´Šh™„Àt0%¸Lè–wßš+…z·h®ëÑÁsG¬Ut» ä¯6U‹•‹öåÇ8
œáú.ôõ­/°¥¥™T]À>k[ÆYiÆºÈŒ·™È¦0Ê2W5¥ß6™=™"½ÁQ•eƒ…w ô,šœYĞ@x}R9b,IšõÚiÎĞ»&H©¬rOİßu"ûs 6hÚ’kÔ„?´I%>ı›É~«û‚½»™ü1Ê2©q”/Ô1P×Ÿ³‘à‹P9úŸAW •öºuÙû0BÂÃô¸ùåÖÔÙ²êPªÇˆ ®áCĞ—ºCUñòR¼©A°Ûj—¯%&Cì2@¤ƒ½ü…[ÓJÁJNfƒä>¯ø	4—Ç`qY”.µãÆû¥êº÷kñ«åŠTon-³G¼Ù;~7k1šĞ 	Š›ü†ujŠÓ–@V[}ş_E‰\õXàavŞ›§²ïm>¿a§×šÑÙ š©ztKx¡¸È{¯‚WçŸ³æy|uÀÏ½pÎ:‡5¬=0‘~èDá6œÍ$À1Lp:j&ƒ=¼Û„Z¢4Û±½Z*íÄp¬X äAoúç>lUé›b¾ã\TŒÆ²@_[×˜RĞŒ÷á|›êşa¬*XËÊ¼êÕUéÙ¹§Î{·ò‚¯à;yå"ÿœô°fÅLæÂh3§˜NhN5yàµTSÈ;*~³jÚK¢ûó`¼nmè¡Èfı=„·ƒTû4ÏÊ›¶“ùÕ
[‹ê•(wxÖÛo°íA?­¯PÍíöm4z5””­:ÉíaY¿	,¦+šA¼ğóG~L…E–;üıPbâú_[ô=¦|‹*_ê;h=B¢³oRU	Âƒ÷*BbòĞ¶@F
öM†<‹ÇbÙbYEBA9£Ğõ,Òøç=j9Ï–¿1Lãx›ÏN
SeÇ
Ÿh»ÏNÊ$`¼c*Áİ(AÜ	$Vˆ
U¯7¬o,¶½ø§W."Ê[ø…“Ğì×PÏâÉÌCÏÀW‚¼ş¾qå(‹y¥)3À¿š…±O6†vÊùQ*UÀM¶X+_ûïIäİDú¾g	W‡1"Ä¬ôÊ­!†ß«I©«vš—×öñoo}Y[7šœ,WVB#[‡L
|'5o­’J­v}e›L­Û¬ŠeN—l±•,#Ç!¸õ`¥şˆ©ùN9öíĞ¹ .¬êİ.Ä0²
hW`Ù[İÜ/ÕXØ6)+È]¤ÿÍş/g%%¹eæ%xyKˆ€±êf|\”•Ö0Ğ>0 mõ¯
¶øíNå6ø™úÉ	©½\˜ğÚDeëOMR<$M5y1GN|Á…ÒÍ`¡Ç>n)Ò°_ãì¯Y›¡VÊÒ5!°Øšt&T%‘?Óhîµ0¹!­¡5­hthvã;xå™á/Å(Ò¾be+•Û±¸ßÉ³V–çÒ†Ò3Òf¦ÀÆwn=üG }ë³ö4Ió Boå71i3”È/¼¶ºádáBjµ4°¬Ş‚Ñ4øÌZ‰ıxÖ
Í{)’p,›r Ü§®„måB£ÓÏK8J$³dT¹UkG+ºÚpD8W;%;1‰.êÑXñ.à&"“ç4E«O\|	Û;”òÜ=c6s?sÄwüQşXôL®ÊT­Šò`5‚ğ’3Ï‡¶tPa}H%Ü.Cl¯ubãÁû¥»'_ÂZ`‹‘›°[Œ“¡ª+TY‘Rx™o7š•<œæt4nè\t|7x"
²ptî¸CuZ‘µˆ„t›3é{sŠtú9nôÜoZ÷s)V¦İáÜåvù4dÎ`~şÂòX+bÂN™›c}{AÄ¢ò£1/îèNñQµ>pKüûÕ,}*§ü è—÷c±÷’FŒ¢ì^–G‚œû0„:yÓ|J¡4E¼ó@HwÍôûÃQ8+ƒ¤‡ê}˜˜>L},Ø%?÷T¦Eåˆ@…Í{H¸ºcÙš±£T7B¨ÏùtçŒ`XÖ‹“Ö5ÜÃÌ@sM-nP˜,‚Ãòã&¨·ìşEt*{©áPa®™,ßÛƒN‡Y;­/6Ü#”‡@~)3ÅßMH$1sW"%+{—“uàÈ­ ÉŸ±JW¢Î-Ìª77;|ŠØ÷~Òe$ÁÚçV?VL¢°~ïE3²ã’/Mq„}‰Åõ|YüœUãiÂÒ+Pi¿Ğùß
ÙHm¯üCN†MiE)ãZ­HË¾¦Å'¥¬šìI5q‚Å­S£2²¹DsÖ3Ê×¤.H”ší˜år¿ËŠ+4qÔ29p¦7wÑÿŠÂİf|ÌAßX’:uò‚šãì"­]ûVOD¬O%x?ÛÙéEeÕ¶Ì¿ùp©W”ñªĞ]?˜);N ´ìá1¦ş“š‰Š0ŒyWÆ5c¬xİ¼µÍq£²?–ŞÇ¹wéºdÎjÛ
’órOé¦ÇfIŞ™'‡ñ~«*¸ÔZÙ\›¼Ğ58÷«l#İ½‹Ìh­®0fx!Šnƒè¤½lù’Ä§IŞ¯Ò·AûÛ+Â}2èŒepTLğª‚l·ÆS„£ÛÛ^ïù‡9<iĞĞrÒİVcÉ‚±ÂÒT!|\˜ÕÉÔÒŸ¿¸ßW£s­]Y_-¶şÀfH“”ö]â¿ıPÉÙç,¸šÜ½C]²å&x,Ö\LöàhÖ×Ø£Y3]V¸{«p÷ô&Øï9¢†e!úf!V¡^q]áëÀš¤á¼¹®¥|Ş<Ó5éÔ›éõj»Ôµ.Ô¼K÷Ögì?œ|¹oë»'{ãs#k¦%œŞV¼±rá^±ÄùˆóT»w¬îıYKaò(oJíå\zŠ–Eé*l¦8Ø‹Û•àJíî†]¿¹ztIÍ€`%8‹· 8oòt‰Ëu&¡ë§©2ôÊü5e;D"J2ÉSw›Cxw4´Ù>›!ÏÆ=;KĞ']$aÒï“Ø·½9¥ĞO„2‰84§ 0†}Åe¦şéKöÎ2Â±ãçº´ö¬íW_|@E=AøÀÍîH‡ ¤«}Óøíîn½K:ü‘ŸÈîJ•“<æ=9“úR™ü(»ÒÙşÕ¤vÓş7å†ÊjûXñÀC?¾¢Ilv½8”C¾z/ëAş ¬¹Iüş+üˆ@×ÈË€­‰q‚íB"úy³§oª%Ö®Åé3Òv†Ñ{Dq°0¼„ÈAñŸ³èIàÓoY~Y/'ªvpj D®é‘øÈ$?.â2û/Ü™†pWÊH‘M.àç?pWåAªÀì²êËLQä\éŞpÕo˜¾#'nìqò)>µ+«ó`|õ‘Ó O¢I `Çº¸‰šm¢6u¾4Yø*^¼ÇKİËØŞ…ı¢ÒÕ;àŞ|‡8Ú¬•íQJÅô3dÔ¬nWùÛI<j©ö>Ù<!‹C.~N‡ŞûöW·å\M…Äó~„?ÔTm”9ƒltE‚ßT®ÛË|Äd5Rÿ8€¾a1â·ä	b	Ï3<¬k9±)? âb|¹kø,¼÷f(JÚ¹µ#ü7NZ6+œ=ıµôï:ş v»E>ZPm¡¿àÛ*	¸˜Z+8Óª‹Œï0vI¿u™£
zâç¤.ÜöŸ¬²»îÎ@Å6ræù¯ ¦”åMy`apéÖƒXy€Ö^‰éãxÄ/vã¾
õîÓ»)"z@¢,‰ß'–¢ü<-6ğô,;ÖßÖMvÃ±&Ù§V<2®à-”K£¼6ãDFR9}ÕnVXÀêSÃ	w:#Ç¦ÀqC10ƒ}‰/
»çï™C›q]Qâ“ÙKËô<û2*‘[ÄçDÛ,‹]¹UŒŠqŸÌÑ!!/ÂÃ–®d»:'ÄTf8t^fÿŠ~„%#æ›Š.ÜArW/|¹^³76Ü³]*N ÅğbS«Øh&•¡ÊÃÃN”kGl¬›Wøß 8o/¥¢‹8¥6ÅóåÂ31Ôc„Æï×¡¾\b·¯êG ŸP`ºéì›ì«n4„T•×1Yõ‰‚DƒÚ–SÑõ¥oÏ iÌ°?‹-µ¶·”$ĞÁ4ÓÅ6—ø÷T‡ïöUÙÌ«0éiì¦t7µ&Ÿ™>$ò³xQŠk÷³äÔƒcÉ9t‰@¸gïû+m‘g$¤÷:ƒ	¿v<j¾5}ÌuXFs”ª[…û£í*pe~^ vu¥ìûw)íÔ›§6*éêh``¬í~[9ås©N…æïÚUj±ã=èÎ_×›’unÁ’{?ëû#d–?¤;ØšEn(3nW…¬¼„OÖíF»+î` ÙXª—½Aç­2çË«ïùÎ¹çà×0Ó³µ+}[D…yA„¢˜*&á tL‡YDIš­>u»ÃÓ{C¼AA¶ 7öÁcHuG6egÃ—!n¬­î™¬~œÕˆÖ5§¡nØÉ7ºH­d$!°FÆ°9mæ´ú»o™— ql£ˆ0u—™ŞÅy Ğ–¬²$(‚$&eè9‡¡|¸²×{Aæ_ÔÄ~r`Á¡óAp«»|ÉAÄM“`ÂØfSäÔ8m1•œº_Ì¦á»AÔ€À÷ÚQK^uzË·Š(ÔôZllØæğ×gf	†caÁ+i:XõìÔyEUåÄ{ª/°¸^#K ã…;ªOßÜXëé®%«gıEkË®9àJŠXn½"à'Xè‘B¸_h›-k@ø•L,¼Šê ÒğÇŒ<0M~ŠfÖÅÎ¨š-ptéš˜j‡éø´E6uÙ˜;jŞôütkršÕ†Tf"ø~ÍeÄª¡i	[´[‹ÈÃüª‹Îõ¤"ûÍOe´«Jì£p,i¥ŒgV#&maX`%\f©wL¦²D¤äq¬$×ü»1·¢rö0¬ÁOSí&øó«µrÇËo¤ş¨NMõ#šIğ‘GÜÌoŞyZ2Ö=ú‹‡±.ük7®ú~Ä|òh}±k§Q9³ÑV–Ø"òˆ§hÌJiÅ„,2·g¼’>fíÕĞ…_|Ñ,aç1ŒukÜ«ÖdP`2À÷yò*ä7‰¶?áÃr¶ñcë	6‹=ºÊ5NQ¤²/j«	Å/m¨ûœ6(t:˜&}ˆĞBxt¸ûyfÏ¨×úá$úEƒü²—pM.èf@×¡…Aî‡K—~nÀ´^d¹¶`õßVy_çxß,Ó>®y÷bÖWd“‡à.zXÃ¡)0W'€8 £€o?ıÀÇ•¦­‚,Y{o[ –¨§O8Ñú1è¤Ü¢Aj ÁÜŒA	zR‘;
»”)k³·àĞ(„ÿ·&¨x$ûõ®£|õ*BŠ|ŠöCXüÉ
ç«?°¼•xøånc\´‡nÒáyJœqÂ{ú/6mŠFPµ1Õèe"‡<à,·¤ÿ¬Ü;Bºáôóî˜IA0¹ˆYÔÂm6§&Â¼IßÖWªo„š&ä¤,å`ar‚z£)›YÏYy¥g	İ\Ã1¡ÊkSìú?:Ü&—”Jwü“·ß¦qEÅCN[:Ø»òÈòÂŞ}j5’?Ï<<qæŞds oË~A½-†^¤ÓÆ¼ğPc’!ÕhŞ@·«ŒbLğoM¸‰TdìÊ.]±­:Ã…GîÿOÖéîEæàh;>üî9l9ÿ_[#6*='¬ØYÍÖŠÏŒ-×„q}¯rnĞäÚE®{àÉÒb“r­G™8y· c]òü’‰LÍìı³m©oÅ2.Yvæ+Wñ|»g"7‘„-…Pÿ¢ù¢¸•‹Ë!ŞC¨ë[&”¨¾eECv¶“‚‘ëùÚK[M@Vr±3¾wJñBrd·Yóçk‰ò¹;0ğLúÈq™Á£ ¶…ÿ´sûM8=£écj‰ Øi–Ÿµ_c·È`8ÄıV	Íâº—ô®Ãß|t
Ìk²¯d|ÃY¨©í
‚5¸:l_¿T1ÀLÕæ:ZBÔ/½/ÑX»£\âıÍg}
2¬cîöÍG
GášL¥€İ§ÿî|øù+*3ÔÅbƒ<`Õë"#Ğ’ö«$yİFŞÓæº__ArEÆwÿé!š¢°ê¨°Š”ÊNÖe¿ºXn\Ffìd/”Ü(Ây¤]©k¡!3ˆa~[«†1>ødº»aÜÔ7Ks­l%•[|EM?{Y¤Á€<Áñdqò	´æÒ¦K®¨¥hë¿`¢7÷Ú…Æ^ÄrŞÁn„¤Y§G:İéÂ–<ò­1Æe”—ñ»HÇi¾w•ËE™åb`eÛ•oí˜êA¼ÉbÎ—Hw#®ÂCVEë(Ûæ¥Çskx+¥â‚ÕÔá®;Õ®ƒ÷c8®/×¯Z#ÊeÅƒzmñ6çIJÒ<TbÙM{œNé$i·]¥Ay½(Ó`lœôlkf›tZ;Ñ:ôŒÊ8a±•)f%©Êşñ©MR²ıÕÎ_nä½¡¨ÿW"[Ê[¦ÇÁ
÷Šä["Z†Q2©‰¬j“G#7!N8BóHŠ_§ÀÚ%áàÄ3T_|	Šé¤+£Q§ËÇ_):ğ|9ûYY÷¿¬bCJæ*o‹Ó&/#C33"Ÿ7//Î´•‘·e\Ë}¥Ò:îâ8;@şÑô¿1/=(€årpŸ†#ûİßw'‰—p¼\Tíb°æêM«¹OÌÊèŠÒÕzÙ>Öœ7wFe8ƒ-~8s—ò>2$2?oGWÔ.Å›¬Ö-…‡Şew)\õ¦W§¨¤Ó›*sÓËg}TÕòvn=»Ú¨ù’ËĞ¯23^ôˆñşãI²Qc‚9õ2æÃí/~tÇ‹ğÔNTLÒ{’˜ÂöøRò*MüŒ‹gİÈœ÷â5r<feWÔnŒèÂ¹ÜI6qZIuõˆW	´áb.¦Áoß}Tc;qdñàÌëJ­ªSî$Ò¤¶\íØ?ĞpìS~:fruë?Y9˜?ºs!Õ$Á¼µ…ëeêÅ}ÖTÁDĞ¹J,§ú'œû)ÒÈbã˜0K/¤ƒoöÊÜ²Á”Rš¼<n*sìË²È"ĞŞ¢¡3Ö”	 KbÖ9ªSÁîºfl"._× Âªÿ¦
©z½ô“TaAli¾+,Œ¾Ïèkó(& Úà¡k´V6dh½ƒ¶‰ñ È¦ÿ{x*ëûıí»‡ğ³ˆÑ³c¬²Œ=l—›l®sSÿ1GRLÚº£T6¢ô
ü[²ñèÓÍè‚*Jæ¶‰4¯å<ÉÔŠc?á‘ê	&ÿAıç€!ô•Ñ{ÕœbS«*ÄY ¹~}7ş7Çß„D/
ê=€qdVådÎA`°/ñîÚ†&©=€åyº¨è–ö;ñQ5&“ŸvH‘Å¥ûÓ†¢xz9 Úgï¸Åvû{5ÿÓ‰ `ñŠQ„‰v-^û=aËš»Ø~ù½«%D{(äô^5ê¹¢Ï€×Ü¼è~
|ÒIÙ_"D"x‰[jªŠsÜûïj¼›¬ùqî§ wUš€*‡î#½$%ÚÚÇ¯)¹ÎÑå+öÄc!pöÔæ=5ˆRõcDãxİ)Ãª3¨RgCšÆmãcñ1Ñ$U>Ä©8W–Uôb¦Wí“˜¿üĞÑ¾$…è´MƒMº@qcğ…˜ïr&’ŸUÆƒ¬µÆN.r5’{ej4³@ûxî§ÿ²T±Š´ «úğ‹ªÿÃrt,Î
§;°ëÏÂãƒÙ;RØ!]Àöñ¿q¤oÈp„¡*üOê±Ö3è°©ÍsW<sÔˆŸòbKœrü˜~Æ³êĞy»ñÈI@ÊÄcPÈw,F¾ ½¸ŒgG «Ø&ÏNâ•‘?¹L{Û˜ZoAP{}1¦L.ùsõJ¬&.øCç*6’¼êƒÇëFRwôefñg¸­xş'‘˜à»Âà:ˆüí³‹•n@NK² ÓĞÑª Aø­«¨I?¥ı^c—÷ €'ĞLHÅ˜R¯oüë£’ù<Ûr‹kíæ½ƒSë.©ùäšÁ\£a¯ZCp(!U2I
3awH}Y,İFº‰Ä/â>"+U{:m0uÿˆËì³üî)C†—°Yÿ]¨İ¸Š]`—Ò^Eš‡Ãm+sı Sx®±$¿É@ã`qÜ}İaº¤Ö7ázv™õÍnX=Fì6ÙšvFUZWÙSiñHç1®ĞK¿˜ßàåmA¹rİ¶R¹²)],/4`Å*RX_‹š‹ûc£å¦el( Âng@C*. ãu‰½qTú/ıçpœ]6yW‰ê§xŸÛ™û£Vx¦/®-¿ •X,	q.Rè¿$‘/3µ(/‘ï±³ö˜ŠƒÒgy¥;‹ IÊ¥.Ó!RX×Ü8Û¿-ú´0ÀÅÖøõ¾\ÒúY*`á“zËq=YkâK
û*'¥lJ#DHv‰!«ùÈÑ©şœnL€:?¥˜Ÿ:¬&ÉVïn‹f½:LSd¿áßSÿå×‘ú‹‰Ç8…mÖúİ6«J\wMõÚÄ’Q°)K²Iš
pşHËËRY›”´üŸûÀ4K˜ó}?äÂŠÁúø`Cê}Ğ­©÷ö8ù$q$Ğ(ol!5?Ï ‰6,+“.³zÁÖiíSGpáº4u-SõÌB5ÿş	%µàõï•İ3g¸ƒ~¼q>yö€Â%ËLXÀv/'a­¥† d¼A¶7òdb«5À­ íìÜY®‰¨„¾²<CE…"yj6ã—sÿ<dè4OZ$ÚÜUíÈÖÇKîU°6Ğ”pi	I¯¥¯Ğóª"øÒ<&ä×ë¿rrWêi¯ahÎFUù²]‚ÇP´€aÏj…ÿ.o¬pû(OË´ñkü¦WE…Jäk a ?‘ÎŞİ?©ƒÅ@¨şÛºÖä²)h³ec&éß‰ÒŞ1{p0f–@Ñ&Z£mºxùôA™ø˜²š†Šï
|É:¼¸szÜğq£ÍÜ„môWO-<‡ º7Ó³½]ÄbF9˜'OM½‘%¼Óªı”³íô/C€†}BYWÎ’šÿÂ*´ÍŞY0ÊãgZiF›…÷L@"åò2PJÄM¨VbU*MÌ—FñnŒbÖ£Li›Â~c_6Ş_z&Œ4Ÿ€ènÅç(:¡à>î+_sO?f=>æÚˆ
ı/¾àş¬)kÙzˆ$›¿Ûl±]lÁ óv³ÙánäÔÇtX?üO2CEs ¢f†ÄÃºËõM:Rô^U†:7úâ*²>j3÷•\O¿ÊîÏEpœõXK[f ù¨¥>——úñgÊŸQZà ¿óIõx6¨""VLMß²•lB@CnÈµf7ìı
—ñ|VjÑ–cÿC¹!5lzš%ÄC®ÅÜğ©²4£gàÂ|q§æH±=ÏsÄhÈÈ²,”¥®òØş¨m+ÔŒµŸf¢bÉÿx¿ªKiœ¸œšLâ˜òú]‹)ÊZ$|	‚ßŸÅz\aëSC:ø!(¬Ì³¼@ìo­¬Wæ-tÊ÷$˜?øÍ‡Æ}OJ+°AŸı»ù™V¹\î[èáø!pæÕÎ2Â%nsjfù0şŒ’ERÓ¬eUg›P£Ù™˜mß[wY’ÒdûÇÖ!lÛ3àóØœ(T4½x–ï`6, Ö»Øhe0~{àûÍiFk|ô²´:€½Ú	”ğC_…ì@Y¬ÕäHÉşe/ùÔK½ıéyÊª`÷âªÿv¬cÑÿNqÓ”jş•x'U ¼\ÃM³Ô	¶§ËbĞY]L 8h´~ÏRÕ‰‘ââ)pHE1(Ç¼ÌD9+ã‹oÊ&cw3K—¤ú>®§¤]§Ò›%§´1çlcn¥¶Ÿß'Ü¢;ÈŒsôùÄƒP¼Ã›éÒÙ™™ KdÌfô8c’Q 'Ú~èÅë›ó»ğı«0ı@Á¼ÖµÁEòø·IvF<•7!VHVo±ùO²CåªÜ —:Õ®6³ZPxjja,Õ>Ş*z2ĞTñKvY=˜$]&€6]‘—^cì .¡äÜå•?µÁá7Œ
Ú°ŒÕ5Õ O¦"ìMØÕøı7—OÕ]çÇ‘“.³µaU*{©‹Gñ%2º¿ÏØ-¸(Å–W×÷!ò\óù¹š€»±>è¢!Kvî$¦:lxæ…|Ÿön@„ëÉş·²¼…˜‡Ğ­ÊZ!ix8İBŸ:Ì	ŒpcÙ—´^oú€Œ®zìî`µORHÉ˜ìX¦Qö)á¸Ä¶>H]Ìû"²ŞéK†U	Ì¼u Ò™ÆwŸÓæ$ªKõkê…®Gíã #"k'nş'ŞKäzĞ#Ó´õ´5/¿ïÃJN®·Ş5¬6sªçé¯Vœ+§ÎgË¼-à,ív•n–
4w×#e¤aîİôMºÚvÙe$G€Ç¯ñ™Ùûs+ñ²~Šîñ–§Ø¶2ºÛ¶€V„€|ÊÉ¯kë¸—ólEŠğ±Möı3—®ö³˜+¯*Ù°ëê|!"ÂE¶Ï—nA´ûßë×NàŒîÇ¿İ¹ÿÁº²¸1y^ˆ¡Qêå)•R*¹/LL«I„sO~|Î.É&y)³4¿=µÂ}Y¨Š3¨–ı=`à`“el`l¼Müšå‹RÙw78×ÎLµÛ3
ïNİ>¯2½Ú“LM¤Ş8ä½B ÆÕ2\s¦¯uµ>G;/Å}ˆÖû½½f¹r-È^³òÅF«L!÷—ºYç@ñ¤¢Ûî³)YÍŸ·×èEYR‹êL×v8ó¶EŒhôÉ‡İ;rÖ:>@ú¸1É‹ñ«="â­…4ĞÉ£ÖA¯KX·h©æ&oÚêZãY—z4ïai·¯µàf¯x16Î"îz1¬{z¤•v3U  ¤á]I ú.Çcß®”¥Î›¼8ß–Œ¸¸3?SRš|×ûıwdå¿¿KvéœÀ6(>m!Õö|%¨ƒ%+7ãsò«jéæ„&øCå—`­~/¨æñÑ}&_­¶‰‰­ÀÕ

Kİ©nZ"6"³#Ì”lôòulËfU…•=n ¹ÒjÅøVıÕI(Îp1hıFğ¿Ü™”‘ÑäßI–b$yù²öà[¬.%-_
j–ÊO²pÌuØ!"£1¼&Ğq¬' ¶ÀH?e—ø—şÙ—k$³;l¦b°Ğ!Ü#³èOq{ï-2PØêgÚo,ÃDx§µĞ&LdJ4Y”_4Ík˜VŸRm\ú$÷”›¥Óî¡ VèØ	Î£û(M¸?Aaf[¤g‘• †œ–Ì­Vò£¿è;ÇséıĞ´(çÅ-ÖÄ¸A4§²±oÒ@2Z&0—G›Ş	'Qˆ¾·šàlC^C/q7ÿ±é´EQ->~7}}io’"y<İõ&úë$l-yI=Š„ZWÑ!½€Ñ0ëÒ[…Ôgí•¨ .6*VÒ˜õIjˆØP±œŒ@€Àô*¶OÏf«æï`ŸQßvÑ«[ôê¤ =¬“ßá'Zt=åğ˜Ï«½]
?}ò…Û ÂVŠûc4ÅÑÑL3™ĞTô;ÄèÒ)¶r¸§§°™+âv¼t)C¸­&<úÓ1Ëî2 ‚û<²Ğ¥ª†)÷fRˆJã(LæªOÆ§³ TÙ¹¡â†ÊÜ¿WïÍ„¤*c~: ".Æö´"æ<'…**280Ü´¬d=
¥U}¬*àW’7ãüÊ²"&lÒEÒGr/k@ùùøäñC`:ñd’0ÆÆœ b0µ‚ñQ`÷şU°$T@ìºìcíÿÒº¤­“æ²BŞœ›•G·¥ÈqÅ@<«i:»òlYo; ÍP?Õ`Ï;}[IÃÏ¨İ—õ¾&õ°(Ø¾×)*×ë`€(UKz¡œ¤1[–2Jú-Ê/Üš]  »ö‡˜UI:qÄO÷›Ú~ğ´S|îXÈÑFß7GãWºµÉÏ•®_ËV»ğüëFYŠçÈ`}e»ä` $X”Ÿˆ=c[3Ş•^1ø¡õup÷{ -t“ŸøUÒdÌÚ…épøuâò™,…¸¬Ó>wVì\}Æ£GZUº¬şr`çIï¡¦òØ]¬Uiğn9ëˆi©×˜@yy·ş°+kEú¹±'O,‚ÎÃ!Kİ˜Ô¿x)üåµ®ş‚È»„~½İq%ÿ·!fh-Ñ[TÛU;òÓÂ(sÑ' ®Òó¦M^xóx)xƒŞo§Ë“ù´ÉgX¨ÆÀk1¾p³”Â	½·NÄèoxV”ª¯ô{’®Ù=(¬.„¨Ñåc™‡GG÷D™":,ÚØ¥J‡:g¡ÕÛÍü`]ÿÑäí^\ÍÆ!	eÊé˜Oó8¶õF8t±N(²•”Á¥:Ír´Iy¬»â˜øË«Ëtˆ­¹ˆã‘Ù’RÕd½Déê"Z„>¨‚VÄÙÚ·ÙFêåù¢@|Ú7ÎÔ˜‘TµŠ/-¼vòòT§éàóËn¶˜úóæk*?ÎÔ6e‚ø±(¹	wã;¤aòP¹PåIÒŠMÑ¦€"hrêLÏ]q4ó2<ÅKS£}»±YíŸì_ªá&q£ÏbAª|ÊñØÀ;º{MXl©'józ,-xÖ,&Ì‰®ÖR ©˜‡€iÃ½Õc”œV“]kTÇºu:â	×ŠOÏõK¿¢_º:1÷İDÔ|9NBJ2*ÂKKåE7o?Qø@‹Ë½äH¦&°ÊİĞoì†Ÿ zµjq.Cl)i®Bc)ƒ£	ÀÒ¨ ²Jù5Vã%ZÓ*G ·"hOP¾>ŒM·$¬Hx¯ g…^9lÄÑîJu„İ@)g‚'o£&Ú6“^ôtèülà¢"Ù¿+V<½Â˜_!]Ÿ³9P×Ò³²’‡æºe«Š2€vJß±“ Šö¶•,sHûİ`œ®ƒRÉûw»ª¯Ú*ú’Ş	WOƒ{N·Ùˆ]÷M©EGl¶%mUšn¹º±ÒôFÓ ì–>‹ñ†SÉ>§¼r4GƒGğ+R½M‰|ueš”j‡Kîu‡Z79¯Ë*ƒ^¤?íò‰¹W06{²ğ*aŞ©Æ,Pâ·#fùˆVéÖ™õ'8]§±Åõó|g“®ÃstJ±æÀ[·nCÌï÷	†…­·g—WW€Éz5ÕJ-$©ã¶.)U1çÌ„²çš¹ Ôk5êĞ«Š¯ AŞâzÖl^W´M€ñøW…Œù£‰3I]? £õ*ò±í¨…#™›¯±rKV3ø-…01ø‰€2yÈ*â´âîi\;ŠÄ‹ušiüÿäWµ©TQ@İÄHÀÏ˜}…Ë0C0Cç+±Â€£ëb=/á–­ïi+}£†¤ÚüW.Z_{ì`óÇ$ã¿ÎÉø›,Æ„¦5ü·œÈ¤ü[„?ìX¿â]a–ƒº6#Cù	26³Á‚L?-=uu12˜Óu¦Gs·_Œ—ª¸ô2/®Áˆ+*†KZc_—sQ]>™¹±k¹ -‘:Ó’½AoR»æEöMt9ğWÏyL§ûm¥‚”Bçl×€*~gnÂ ï_[„ájı·û	ÂŒEÜş­uàTõ6ŸïËMC2‡º®öù^?ã©—(¬ÿsùaû­ÿ)³l¿Võ¨ñwºÍzŸåØl}ti)Vÿ‚›„İ´ï÷ù¢ô¤:[´˜mæZ%•ø;}û{¹µÜ¿ï0R—|Iì	Çè6²´/Òvkİ[áØºşî[Ÿ
–Ñ»Fç\$îREŒWŠ©š±1„BòLÖ—±7½7Í¹E0à‡´àQ¨,·! F%buMÀ5[õïGÌVRè)UÁH4µQy2X`ûm)á›®;¾?¸%‰¿B/aµ†™Iy•´*º˜ÆÄfVÂFJ¸~ƒFœõqg«ĞA})ÿgà®:¯Z<?ø÷À‰UŞ8JÇ½{§{.TÃÓ3S«U,ÿ»	2ÄÈàÃ@íMW}…Š ÷ŒO¶Z¢(vq6/Xä†”¨…"k°šå8ëëùĞêœ‡-¾!A=<ÜTFÑÃñ}ÿì¸M.c€¯ÿšæŸ5èrhäb&ÚÉÜâŒª ÃÜt‡¤#:L½Ák¼`¦´ƒçhØËöÁÙ¨ˆŸØ½ßbaP@1AÎ±rxi”Nñf´–ÓÛTÜ^®½’=Xöµ†eQƒc ĞYªû ¨¶‰¢ua›.¢À@âñ¹5Âº¹›«~«Rœnk3Ñ:`CÁ»À°Æ*Y^‘p¯º
öQ¶9¸Êõ|wÉñg5½úV—»”‘ó .ó°‘»Ercóö¶‘nê<<XˆÚ'x¿™SFzÙ™Ÿ|8&•­Sm_©Û¾Ù·ÏõîÉFFô™^˜Wé°7v]Éb}’üêQĞU°µ#®SŞv±kíEíÈ(C]"±–QôV©‡åz×s9A>Åq˜ŒÄá‚4ŠÿÍhü^¶DÕµr{g9ñ[uÚ'#eËJÒÃÑì‡
šĞBÜÍNe·'Ş9P /b¿Ô¸ß’ı/=”Ä@ÏÙ)'tÕœ‚R,!6#bÚ‰ûÆÌõÚänªgóÂO~8ŠYa‚¬!Ñ«·0ŠCı…6¸eE!9ñT]`Ä¥àš ĞÀGy°¢ÕXÂ0Åc\z
e24¨úY§(<6lZÔíùÅ¤àİ’‘/Oóıvˆt®UÖb
ä,šˆab‰ÚÎyÙC¹xD³–&Şûã¹(ôQñ¹(°ÂaÑŞºÀ-bTw§x¬ì5):Ñêõ«iŸ¬&b#Úá¿üj˜aæÑÓÔƒ)„mºd}ÏKÁa³a[t‚ICàKûl§ß_ş^o›÷MOVÒ)d¾Ál0o¬ò }=dHÖuw;t<bé8§q$Vb¶³Ü&ªî‘8‹¼šq2u
ñ}»{Îƒåê’ØI¥ÈmUâët ¼Øv)Æ£˜Kö:³£ryd´Á(ÂA±"GĞ\ÏŒdx˜èÄÙ' zË8¦[G£2Õ±ò
|ğÄÒÕQèAıÏ8r\Xæ}­£=šyAÜ’Y+‹É;ëC³Bxûòl¸yúinĞğêÕ#ße@8L8±Ë×Ä–Ék(f.jĞâ`ÓÎÒÑb<ë¸DåºK]ŸOkpÍB ¶¥Eö9ëbÂ-/ÆŠäõ´%Bñ	²Á_Š¡³B‘ôQ	KŞÙ>™j<ì‹‰¶é­óˆC9©iÔ}í7}_µ%Lµ·Øâa¼™,[X&øÔG	ƒ%“õ3¨5{ö;Õzìñ{·æê®ã¶µÇşİı×é=¼PIÉó|ü2_¢iÍZTuÈXûçsı·È,3ÓeoQfQóIç0R¦!ğÖ­^ÖûS? å7È^Üp†•ææìŠ­Q÷i0\½\9]¼‚ngj>kÙÿõêzW€/CA°‡éº›ÂXk@ĞêRÃÆûò+vÑ¶
a”œ„úN)p'CÎ™®HMûI90õà2–©Ù*!tä	İèAõøOTÙ ÓÛÉÇRw£¡'‡È½„Œç[ZCŠ†Ú[vì\&6	œ·t°BrP°"Hı›P=Æ×„à£lZÿ¼"XòMoÖÉË€›¡ŸÃæ¿FC<¥ªÛûç‡t³Óö¹÷Âg ¬#F¹HäÔŞüPêº5gqš6êÿA,vÎ„³ï÷°²Ä†ZRƒÊZ‰hŞO{X†¥ĞI_Ï‚—ÙŠ+áxô÷‡INápÃ8;ÜHøÛŸËØ*qwM²lŠàOà{41âØ•$ş¡`ĞgMvƒİ¯•&ıÀ„PË€óz±p|“ÂÜ—ƒ,ê6•&”TH"s/vînUfXµÁxQ1ˆÒ#aC&G *åÇ¡-àL DvL{xˆÛ"½_5ÛWÊU˜ş†Ö¤“ñT+ZB$“òïHjS»^—ãQš ];ÑFN¶Ùæ½ï’÷ª[ï"J¶Ø«£?Üü7‹RA’ùd´æĞb63gŞÒ¸}¿È{OÙ»œî“ÊtâZ³9{~¼äœu±¨/­l±5²C8!_=§«ª° Zh@œğØwT@™c¹!ğÜH~´îoœc”ÂR½a9j2èŠ, ¿÷}í–“œÀœ¦‚pŞšı¶ÏšÿØ´ª‘d?^ø4™ÚQcïc¿NÀNĞÅìl~JÆXYorH‡9Ë¿ßmªª¶ØßºÊdˆº¹çA÷ 4‹Z%¨µ˜Ôçò\Ñ4ä¹c
(ae¿ã~6}ı˜Ñ1S_Á®$ëq.•5”h·Ş¨)º±9@¾;5Ï^æ€Z2—RáC‹‘¸„İ3e-Çjxeãb,T;„\×WQqéGcÂºÖi[¦ÄH÷{Œ2C^ïÚÃßC(Fl—H0^nwÏDËšB›šdg¹ó =tg·¤öùq‚Iìïˆq¦ÕLJnÏ‘§*¢?İ?øMŠ7/³q€)ØX‚GFyh)ùºçEY“wÄY!égÖ”bfñeˆÃaµv3û(#ná.ªöĞ6YñYW!¦ÂRb£æ³İùİÜËÊPXæTEª‚¼"u _™jF5ıM<Ÿé`F$«…#ÚEuíÖ¿Îæ7„áûlº˜LÂ£û¨wğ!uzP›Z;¨ú]1#÷'—ºdÀê<lï“D+LÇkY56j9âß¤ƒMGPÍ)ÙÊ¹ºb†¤@k,H´ù“§»E¨onæ\7˜sà	G
‰%D» Ûç–PÛÌ^FeTh£&–ææ±fı²àBád›Şá&Q¹Í@KªÎJtAºuìEX,š¤¢ù°ÜêûV¸s¥ŒmJ÷ŸüùËÃn'J‹2MIÿÔk(P†ë>¾‘·õ.•Z"ÙÏl,ÊµÛK±HÑdÒ´;ßy‚¡òn	¤ÜCêÔ—Ì«¯jÛãuË·ÔMZ(Úÿkn–Â[vVÕ‹_¹\QêiÛ”âKæ“VÔ5
Î¡°3ï8y$°µ'KÏÉ:4ã¦×Yë^@ûsĞ[·xbúoÍ‰^^í4r°Ş8Óä(5ğ;q¼µ›¬„Lc2Æ¸…¢)`QZGjØ9¤À#âk,ù"Ş¤ÉßcEšŒ¬„,ár™…ÿÎüº±ãqA
˜´Çyt›Ÿ˜Èõ\{\Iİåœõ	Ô+ºRsö–ØFİ¯ˆğ³lNsu Ë­:RßAº"ÏL‰ªm*í·ºN«PHCuë·ãª£^$Ei7zNIMù¦8ÍwEÏp›¤ÖğŒ%Pè®ÀAüiúÁC´±k{@aS‹”>(¼¯¶+Ì²ÇR)·P
bpÑ£Òî§ÂTqW©õ²1ñ;P,ï8rkÀ,”Væœ<>3xù¦&€]ö€	íÀÀÏÌLíÈMz1tÂQo2,-ôÈçlCqÄoÚ‚‹Zìy•´g"PÈ¤F?c4.ek+ÕÇG›<ç”É!À´…£x]›|`T 7M8x ~D‹<AxÙ¿­(Ú@°ÿï²RÛâÜ­6°¯ò{¶C2ÂŸ–6[İ-²¶¹İL£A+!¤eˆ*$û£‰rñ¥ék‘¤…z•j­£?5â _[jˆÖÅ.•"	RtSh~&fï›Yu›ª¡Y#¹jÊ3~„È´ò½ÀºpÖ¢8K¤pˆµÊŸ¬M‹/ê¤¦;4¥±ù^ø;¸ŒpÜ£Û½Ş™L¿â$öœnPsqM(‰Ì|«ğ+ÿ—íŞ—¡Vœ8Ey¿UwT TšØe‘µ¼3åFLŞ²ßØMdª5W}Tº„ãïpZP{µ €Éç"=})ÏzÇ''¸2PsëÊœÉ)o82®ûæåIrwM¿¤>Õjî4"ÊÇò”&æS_Hğc7›ÚÊàmB9êÚy§!>ûzèÏç
1\¤¸ÕñuŸXù<Lø§ÈéÃõû/;p²ˆ¢•ğë¿9#Ç#~¤@ÌÓÆµ¾Ë¬÷KëµwCVåã5/]J½Ç‹}wXpn¬-I†oÈA# JìÛâàB¼Y:%®`´–¶>D–]>èjmp
š>r/„ÚLÔ{Bâçlëw‹¾@MÃÔŒ‹ç3¸Ó H<–“xÍ†Ài “3 ã±¯o+×Ï—	ƒM7óŞ )à¥yŒpÌJï–ÃÔÍ=j|µ¤2ÂÃØ.?®étŒÎé“N™6?‰éóTäŒ²2Õ¡Vótk\¬W¹_	àjïsÓDÈÌ!†Ê§÷´ôb7œÕ¹YuéÁÖë¨×À3†ÿ„¶=‹ÊµÉü…3ˆR¥¾Á4wÀö_"t¿aCwT?=³Ù¡‘,KR@¯;Ûæo
™séí0ÿk4y1¦®x`'º‡sMĞ–ÊSkÿ]òU!cYò~>Ï7ŒÄ§ß˜G‚7a…çP5S82|öÀÀ?]\üiôéS¨®¨„<Ó!ŞÀúëNğd”4.¤gÚãTµDq½] ÜÍhóm‡¡ù7¼6‹bzı??<¶  d?Ÿ°æ:º,u5Yè C"pØâ*‚©˜ùS­\X‚Ù/#”ûöóÓü¼ÏóE¹eå¯õàuk¾±®Ô,¥<ãÑ4Ğábú²a"•Ç +Ó]T2*‡9NgJ›ÉÜü<¿zefÇ:<\Ù ÜX9†©˜ÍŒcKß¬Õ´>Ï…³²
Î:g).ÍÀ€ku¢Œ­—b¹¡à.('=àÊ/A¬EP:ÌåUw!18Gq©vıDmÅ|QËÅâLodò\DÊÙÜ&Ü´+	İnhµıNİ­=Ú¤
’œ4]1Û›ãwS«ŸO¼"­¸œÄÎ1#aîÅm¡Y=eY£½CvEFçŞ-Aìãën€Â…—^#w,«KÇœ±\»'=ÔN¶µhBôrV,'¸ĞG>šåg»¤BWb¯ëÇü£gÃË¨=;œÒêÁĞ·C!y•ÍfÎÉô¤·6'8R}ŒT´êù‡Ë¶Á¬ş õshoáŒ¢\®˜RÔFÿ¬%Ø…¼½Ğ9Ûñé*ŠìÈ_lôÈ®1šÉë~"ï.F€û›€Óf¸²%ÎéÑš‹fÚÉ7óö×FıtÑĞ•ë¯R¸Šçë¯kí»k*3İ ,¸nÅL¶˜O›ü+İîÒµä-…P89£ HB%Û˜ HV†G“wS²köRŒ!q@ç€”±iGZ î³Ø•u/¼^£Ney©+€Î%F?{¯PËA›?ÜA›\+½—Í˜< ¹F*
÷aõSi|Q/Ì±€xÖ`Ü|©Ã>áŞêÓ$vbî2Ÿ²krÍa•ú¨ZÖŸ¨3Ÿcµj©ü(M—&¬GBæ-1pO²=û–	FÃCåu¬V‹)Wu”.%ïå|)jÂeE~´P‰Ÿ¯	éˆ¹»]nÜÀ-Z&O îŒ,Şûçw¿o	zÖGß‰Cİ£Úr™~ –ß§ÛĞlİ;¢I$$´pTû5ö	b×ÓŠG¼“3Ú£0ÑâíFƒËÖ™ZT«m3l°à!°XŒER[eŸ:Äïâº\A	>û÷ç{°ß;Yğn³ş~nÉàE4DÁ¡ŠÛáı†„r­ÁÑzƒT´é:ªéw[xßk“X@ìÖ~ñmÑ6c'/ÿkv>á¼ÆLìy¸´•ğ&ø7Ñ
ÄÂEvÕXüx¬iœ&»U¡ò( Ş¯kÛ„ÖÌİŸİÎ=N* ş ADû‰+ë…ß¤µ2ğ¥†?ÃºíEš©z §§hë
P³J…š©€ø§n‘Ôˆ9š³|µhl<¹v¯_,‡Ó¬Ò%AiŒJÄ]ÎŠzîÌÉVÀdO*Â²1í¿+S¤ìN«V}œc
ñTø4gRñP{ˆÑøŞ÷áTœ0¿2ïé÷dK°=Ìùâ.>ZŸ“’Wƒíê
ÛaguLíC,®ôÃ’Y)?˜Çuä›«„Z‚¿âÉÆÉ7aû±±("0á$ï]]ºJãŞsÂò4–N+×GqÌ®Zà¦v”ô1B¯‰‹7o\ ü§l|Ê›×2~ã\
Ó_œG!å9å†–²ˆˆ”±‹á•H×Œò„$Y?µ½‚ÓâŠ‰°“2¡[¹š8•ŠfgÛ@gyõ†é‡àmáÑ7pqè
`œÖÒÕ3¨R¿yNzKïÍ*n\wA ÿç1
û]5á¨Ğ+­ÂƒPmZâFT=µcÂPœ¸µÂ8KÚ»“lgÙ»^ït¤GàÉ¯"Ø¨”¿Ha~]…åQ¼<Î3JĞÀ­ ‹Ñétlç(ïùö£Ùİ¬>÷$­Û°O9¿™^6½Æl^òC™l{6ªë.ØTl±’%B‰ wMéarÌ,#5ÆCp¥9¤óMÓÛ¸ßlÊ°|À ´­ğzyÅ™GaA\÷±09ÄQ—ŠÅ,†›}B?ÃnŒD€ÁéëÛ¼‚ß³–Õ@Ş<¼ôEœvpGJôÎu:OÈÂaŞvÉÍ[Ğß#mÏT~½©ó¨B$²8ß°çÕ?·Ärı©“P	+:İÿÛÚ†›	"£‚&k9‡Ò¢şS–ÀQ`FÂ(œ³ª¾˜ônT±Úú™U(åŞiÊ‰bè˜e¡Aº€ÆNºˆ‹Ï%¦mĞéxZ(/™J’àÏ÷rÚ¹8êE•g&a¨æ+û“Ç–*è‘8«ÌoÔqQïØXšÒò¸C¨ó¤§0’}­†§şÏìãÅVÉ©à¶àh€U:ºíÕf(œmû4ŒÛ@LOÊûê¡I½$ÇrG%M™-~¨¸|€ºP	)f³RŸë(B^¶·»[tÛ½µj©#shtÁ/keÉ“Î|Ùz¦µ©[hçXpğ*L;ÑXÈE·š¤dO›„P ª¸G¥ KK[‘ÆX:n`šµ—‡äÇw	×í«3$Ê`„ÂfÔZ£‹J³f"÷l;rò42¡A jnvë$ÛÖš3ÄŞA#á©hÿ‘gÌÉû]³%ˆù(û”ãğÕ8´È´:0ÀšÏ`N²ûáôŠÎ}#ëKâäËèş] rÏÔátfj%ú˜Ë¡Œ\%L<[2ŸÒ1òü°åÜ›4Y7.ò¸¨r}•m²xosñœOr£bõa”|¨Ó8(¯1¡1ãºõWÆÂ$à}â.2Š¬Ø€c°eeL/¤\ha24ÅCÕëúõ¸76DG—Mµš)FØBºÍÖ(¨°–à+PÿÖ½y¼ú(ı…ˆQì7r“&¢ñÌpÿåı“=¤TÆ&xÁK—ˆ/û¡”âÈ©6÷ÇÖêê÷g…I¿Xô­:…{ù0KA¥¬î¥>×Ü´iô
Ö[ô\‹EF·Åş„ƒ?ƒ%?†_úæln^ÙÄ€ú3Ú–É]§n"0ª¡ê°÷ÇÀÉÙ[øÄ›,š9âŠŸtCªeµ¿§Ôú^Y:.áA}·ğšW}ß- ×9L7x€À’xHRKßuÀ€õb£ˆ³Q‚cªº3 Œ9›µÇÑ4~3v{…ÈjÇÙL–çP³K!ƒÅ]ñ•~ÆO)3<,Æ´[NéhNÅñºıà>¸sA¿ã%Ú›ŸîşÜşÑ=æsZ˜¬\ænaIŞ×6ŠğÁ5í×¼úõÀàº¾ŸİŠ¿C©®	°¼$éapı–Ÿ6Úm†6µYRáµ—»/Èá
[äm†ú°!šT‘;ƒt‹å7³‚qj…àâÃJímlÛ£L]FùpqS@Ò•È†T¹U~ d¥q« bL"¼µ$*Gä{È(OÚJ©°ô—}¼‚# „J†ÍÏŸ×,jùe]/ÔÑ’1ö)Ñï„À9$«L¥ş^Z†Pÿ!J&*‰”[¶uiÜQşpÅcK÷Ã5£j(°ú»jºô Q)8iÇÎ@´ßÎ¡Ø°g¦ŸXoyÖ²šd…MÄsÕEõO²ğùíÑ·ôÔƒy+[N·üü°2óiˆWaaÍi&ƒcĞ.³€L†Ü3Í«j&K2Rß²â]—PĞ–HÊo¶qƒioz'TÑûsâ³`³ßªÕM¹v¥©·CïÌëøñbpH­íÕ÷A†ùÁöğ;ï^GÙ6ëi¿\®37)/¬0‡Ë¦ox©FX™ğ“>äì|¡K_ñ–Í'ºÏ_ğàŠ”×¨¸3dÜM/Ö–¡ªµÄ"¾òO3r_Â¢ãÓÛš÷ãÃU ©âû\@® ò8Uu:\1ÃÎî*KÌ`nwPEŒ+Æ–rthß+ÀÛ*¥VãU1â>XåæÂø‰‡•¦¤„1‰Hé0¤e'ÍI[K“À7+:È‹]±W’iMH—5ïá“TstğÅ«Fîº¯¥?v{8N›x½ ô6[iØ%Ui‚½ÌWœĞbEš"0Ûó%	¹|/´í¨”3"Ñk¿äI'îš>!ä{Ú¯	—„	Nhfg„my”áèS´-{Ô‘

œ”¿|<Ñwrj¹°DhBÑeOQøzÍóU×hA?SSLwâ,å]½_)y2‹2[:F$"¸³”ëN	®mÈãìKxç  ³3Ä^–1v¹–ü¤ÁJI¼}›,y€•OV©ÀÆ–H H¶Úñ„ã.ª™V‰9`¢øŸMg¿a6nå¹ÓXŠªÍwEÉ:@¦§ä%JĞª`±±Îş°xs™Bîøõı)åĞ½|ÈÑ²i2~¨wâWğÀ†:â/>ûâöÚ?\gæªçdÕIg@ òİ˜H¿Q§åY"ëŠÒšğÄCÎÔ|eIØúT&"|;%E*<Ë\â gË*Šù,¨¨J1YŒZÌú¬ÃVÿ‡)•§Âf#mH–ËKİ,çÚY/İ¾ªRD@îçIÍŠ^N÷<£û¡şÕàë>QVœ8«Šx¢0OØqH¯4SRt´¡ñ–{ÚÊFc±™rãİ/g½ğÕÅ:ê§YŸFıá£{¼*“-¢G«ÀÜG:Şf~+äÌ1xÎ£ëâd ¬¯ÁGx§º…ªÙ1 Š˜d¥>~Z¿zNeo,Ğ+ ª:áÍ¡=I\›ˆÂæ¯x`Èk½ú»/¨„ı—:n:‰øÏæl¾³"+ùšY1Î"€}ºÓup i|Ğª¾¸{×Ò*ZcÔQŞÌ~©å^½©dõ@¨eÌ ¹p¯±¶æ=m7?Ÿ¨=¤XÄvsùB¼û`_ûàŒé’Uy|·('¬vµ3ûg\kü‹Àä<Şâcóéxó™^¹äşFy$÷—z¦ÌŞ§2=†x%ßú#@ NUAÄS‚¥Œ|c·Š½‹0x¶óOÿ¥¸rÁ'jPvér!Ğëße‰b20QLD\kRr×å“øX2.™;'Ş—óÄÂßB$¸ïe‘¯ÄšK÷Åœ„\‰„şQ–~xLó'9‘Ñ°­¹ïØ
Åt KàtKÛZ²¹¬Mï§/‚}Ã#Úè´µe!Ê.*ä¹vçÂXeşmü(aÁÙî@­¼.[h†…û;Iw¥•n‰5!ˆÖ%¡¶Â^¸:zŞ0Ê|­»MS%|\f‡y}§MèùÃëğYŸ{˜&\åêÛ»ı†'Hø8%¥k^`bCN¤„œçùú •©i·µúoÎ†VĞù§!"5 Á°ä8ci”‘©À)N´kI)Óğ!b+ò
{I©Ë>sKİJBİ‚“õŠw.ùÜÿ„«›„O>]Ûõğİ*A¬6Ş¨ú©BQcN›¼`¡×,8IßZÆÎÿ>GvncV€åÆ˜Šœì	qÓºê	¦qÎÓ[ëdça#8mî@Ù)
Ğ‰RümsoØÇG}ãõJ¨Ùc
ø?5ô4Š¾s*²y›B{=|º*¹íc<’5õº[Pï<IÏº$2õ
9éªµ¦#f¸ª)’${¯¥‘Yä”ü…÷‡ñLi§hA•Ü˜ÁéÃ‚ÍbfY+ÔÔj±šnãHz—ée»_hù€f
åsæùn¥QZ®ó©Ôü¨Ï(µğB)ğ^“Ä¦¶u©cJ7hè+T9 n“åÙÔh‘Œ»†ÕdÌm8ÜÊ|Øï¬ôÏÀÔ<&ë¦Š¯âxáÙ\ä¿YÃ‘è6Û™$T°ûîh]{–v¾yã2¸x·÷ÊT$RO‹Îtíı”Ÿ;‡ñ¹LÀÜ£6#<¾í€è: lÜS®
Fí¸†	JTÇµ­Ä†ò#(ÚÛ&˜Bóëëáe³ôóÄ)Ï°«
ga’ãÜ¨Ş\yùq««‡½úøm&{:OAáÔf)‰ÄòW×ôæ„dmÎé@uª-|=ƒ«M×7ª¿?\İ$Á€%ŠÀöZ …Jsš”|ó¦>X¯DJ:{“I„5r|a™¡KhÙ§2ÛBrXbŒó dëáçËxE½,"tÖğfÒ%4ãHœí_ü`;Ó› h›±ò8¿ 8nH·Ãô~lÂï«-’ÖØ˜>'^‘ìPÌLzŠo=U—¾èáU^S“]Ä>­ş„ó{ZÄ´¶=5‘db¼ÿÂ#DKC¨¬íº×À+½IuE2ÒŠ°gñÇ5âÄÉÄ±ê''˜4÷=î’ÿ¤Äï"â:‡Á“o}İı‹.t¬©i­k…îëŒÑïŞ±Í]¿¼ÀàÂoÑ_ûß"äWDå^¼›«J`ŞvŒ-€a	uèÉá™î>.”Ö’ªE*†Hëùî;)ÀWC1øC£Ÿç¨Ú.?}A	kT7b¤©]g!ÿÙ…õÕ‹ƒ¥.=H½¶åÚú2dAÈ÷9ù‘>åêãÉò´W­x@ëêxæ+iTÔmy|™9ÆHÏé®ÜÀì,ÚƒY‚È+ŞzSÏâEî(p‘xş6ª®ºÕ¦Rê²}¥LÃH¨^ã|è àùãQç,+=L,‘¥ÂóTG“­t`GšÆM+ì>®+²×hĞ™€ö$…÷«g$+şÑÜÉ(º¸Êî~§gI<D£`Tì–@š6;èƒjˆüNBN1õ8s‡eø–?¸öòÍ­ä÷ıº^‹ÂÄŒ´_Ußª„3Mìc©"ü÷Ö‹ f1õÒÛ›³b”µQ-Fî«…ØüCíëÿ¸Jw¼L1Ocûec±²!U±¿J-bÃÔd‰,bœŠ$„Ÿó0,¾‹‹÷àºñ)çÈ6m¸]£„>}ò¶ùîêÀ&• {á¤€mUå<Ş.§ç¡Ğ­ÀEÒøğ—ZJSà’¾û×Ğ¦ib>v (”gá¯Å«Ÿÿ£YR´O%ÄÅÜ»*L6±}¤p†ÜéWft…à6Äİ´Z~*vcyÙ÷êçşğØÕwãauÃD®¹?ÖáÅDg™/Ÿ±{ÔâÿmÈ«0hŸ@<†¡ŸŒæ»ë*“¿ ÓÅ\“NÓÂ•å^[':	ÛËœ²(b^gÙìW9ÿ3_g²ûICãJ|¢ìX·2ÒíóÓ6Œ-uR{)Wê®©Ö€ŠnSş¶gIŞEõ›€-®]xq\ü$K :&¹KQ°÷lqËaâ—³ ¸Y÷r2ŒÎ}Y~v¬ä/±n Ò¹'{A·VXu®ìÔ‹r8+†*çĞƒ©Àa[Ã‹|{t `]3#2YÖÒZ”hq,‡Hõ5Œâ¡e1¦}'JÊÅ ½¶É“z\`é3‚v(4§õı¤S2æÅÙ’Ró>‹yBQœİNéÌYeG™\|­§•ó†(ø\†Ó:"µtbj¢Ê ,(Êª›ëœ½I™íµ*l4pb$¶÷*ÒÁ¸ıÁ(L;Ï7ht5XÊŠy„Åz¿…¾(Â5wÔ!F¸6ŸäàÆŒö,Ëfh–‰Ôêm:'Ğ_Y§cÀY{È³m İ-Ğ5‚Ô`“±’"UMæùÕ³1İn\Y¤G—n¹r"vè¢)«Ë»æ¦õûÏèW…‡½qÈÜĞ‰
Ìÿ´Š=rØæ!Ö"\|S²€”î°¢sŒ8q\´’W'í¶z€ƒA”Á}˜]ÿ¯YÎ$:b%Š–î?ÙSÓË‰<T¨]Ù` sãSu£WF„×1‰Õ¢ìÆµ\ÌWí¥úoô×	T‘•¥/¨.­‘0½&ŞØ’üä¤v^È#]§¬%ÙWq{Ÿù¦ôÁd_#…Š*¼–¨X]šë¶ÚÌ3B{pP¹y_Ôeµ}ËguÓÁ·9”Ø1‚j?¼À,œfOø}Ç•ÀÛºä$v:8´Ê·¨ãW(˜BÚØ2ÔÅõ
ûG³+Ğ}J4X4K„‡êæ½­‘MÕùó«Aè­ï ¥ +¡H#DœärÖÊÎÍê‹ls¤J|{tx7M"”ËÁÇÈXÑ÷²åˆÍvë²^[ùİ6Æn9=Ê8l,E£Â6õ¦¯&¿gj?‰^"æçA²/­?fı(Š!‹¬~·t$ÜlCS5\]UåÁhéQ.)¤I¼ßºU„¼¯|Ù£?šc¯è>æ‚uƒğh8÷‹ÿ³W×Rw’:ÂÁ¡WrÁŞ¡íÉÜ[ûƒ#ç*ÅŠ®-ÖÀ5ÏHÔ?Qée^1•$ÿ
„&æ#Ğmh÷ìßP—Ü¦ŠU§T(ëÈ¯èvßcj½à1ö…Á¼çşv”—ıl¤†e3Î$õõL{÷ªüÍä¬'Šö'Œòä«Z–;YTôÑœ—K{æ“®EqT›=52=EƒÛ’d[Ó©€„Cw,vğ+s¿Í^sL·>¦MhŠH¥ñ¼¥8ÄfÊ÷¢ÒùøéH×ÁyèÿÅåK½w¤è%0°²ÌqN„E	-}X^‰ãˆ-øİíŞ»ÛŒº5RP›+•5È¢ÇmkÊ.Ôğªa1IóYÆŠZ'IåÒ—ãë0]U´Ìİé7v'ø!\.¬§§±>`¥Ë¿ÄÁ'Ğàc6°Ö«HïÂ‹sP9‘
Ä3‰æÿq+v+ kÇ[PqBIó­?Q3‹²¦²fı9}á-û†AoÇüiŒÜÌLüCN´g*ƒ	>n¹y]ã[“˜f3"ÖÏíF¼=N­™`@QÿO¡q+ôÒ—XtíÊq\	_/çïaÕ‹‘¹ZÏah:w4°¤l—µİG.Y¯2ñ½ƒ¸Ì»†O`µ@X©o³oáä½É8¨l‹òÆñ3kïS†/~´suªiˆ(3‘³Ó/…•˜(LkM=rV‰¬ŒZ¡C=ı­ÖÏH )ÆÊJ ùæ¿±ÉÇ33Ìà‹  Å$—Úİ
Ñ.§‚<:Í%/õ-øõÿ0¼Ÿ¡9èAßüç¹¯‰‰¶-†ñî§
…‰XüRc ·¤†Á} •õ2˜WZfÄâÕ”áÑÿr˜@HäÚâÕ¦Ğ1m©£D¯!i±ÜF‹K¦ïxÕÊl½÷¯Şê*ñºR™’?à0ˆ˜ŸW+»÷‘Çg”|çá<şW—¢?ìÛ(ŒeÍ8´tMÓFâ`¿Ï³›ìH¶x»¹b'ˆ=b;Kv*ÜÍz9uÌEYk,šœ ‰à,¼éŸş¡Ó    ¥­áF0 É¯€ğ‹«“£±Ägû    YZ