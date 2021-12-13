#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3841130579"
MD5="e56eb2d438d1527fc24545c571784c92"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23932"
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
	echo Date of packaging: Mon Dec 13 17:49:00 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ]<] ¼}•À1Dd]‡Á›PætİDõ"ÛÂ Ç;ÂÑwÌjTàwÓO¨š§`@¡|yw&§û4áÛÏãªõú”rl}.›B¬åuA8
‚3)ŞÚh·68Ä]òcÎŞ\ğ“B¹ûı.Ğİ	—ğMã‘JX.™³»ÿMü×SdY²ûdAÛy•ÀÙ‰ë•ù ŞÆúÇÀ?áïW»·Úu&‘m-T8»£ç#øìBz[!ïa¢õëO0€D;ÂÜ3  áêçr˜“|&ÙJB»ò	^]¤<Æş)ñæ¨tÕ®$Õ)€dÚÆ„3¨IA_Ş¬ºšœ|K§ÁFU”Ö\û®84/™3¶ó`ß“ûİ~€ãe´Î½°ö«œ¡L[óe¦„.ÏA:¥ø(¹È±@Ø8W¸‡%»Şà:Uw)¬­:Ô‘ŒLAOK±ø@¸›M”S ­CI|vòÍdóŒßb¯³¢ş"É:IÊ1èù?¡1“E¿ZgM°©˜ÂÉRQÁ)M|6BqËŒcë›[ÓúKÈ]2Ú £ 8MxÄ”3i©™ f;àŞvÌò£º¯ß‹œ7$íL§¯¾¸à¦Û`¡ØQ^b¤ì×ª´{ƒØO¶>8Vå;ˆ™ã ™}QÆ½R1¨8¤·‡ÊşŠœÆGİÑ¼›ÈÃ]°ao˜²Kzûf=XRáI|Ùj1Œ°×Ñ”9 ×ÌÙÇc3¥/…	9¤
ÀhiôµÍ|~5ğÿ<ÛoØ@Çc:Ú””â1TW‘ÈÚ'-ú›o8ûª£”±›5»Ûäƒ‡İYŞê9¢vúH~l^6¬¬*öu!ˆ˜•ãSÄÏmK/p‡ÁøUù·İ~Ÿœ(İ¤€Ã>
2øD]Ä×D¥­jC—bÇgş7Š¼Ğ•õ÷ÿ[”× jN› cûcé'Ó„!,¨²èb?7¤İƒüKg`Ûç&o¾òXe„i¡s0rR3³ÑI‘ğd§_a^.±ô¥æ¿ş“ÔFù,QÈLB3³é´¤=èîK7h>_w9†p«RRÓÇ
•:ü§”S:£id[¿CãKàQÃr«7ÊÎˆÅ’‰Ît—Ä/ê£	äT–ÇÎĞÌkØÁn%©vÉ0É‘Û\+>ªb/ÓÙ(™2|Ã¾Å-³¨y¬B¾ÙI#Á.·–}‰ïëòÕÙÉ—TdÙö;Jî…ØbàpÒ-‹Æ9|[ìs3˜›e˜ìw7“›Zcz¼6lªst İÅ™tğÉd€‡4˜üšéÙ¥µVß
o-xîh®ù:¸&Ş©ƒ¡%Şş…ùwØzÖe¶%†İîĞÃ‹}#fû2¢šô)qriº‰ƒ.5ŠÛß&VìÁL=ê‚ä‚x¦/©V˜wh¦Óº¡Ëz¥¸Ô–!‚°ï:ï¼—pAv²œJ «ñ‡­tW†¢]F
2K×¿¶ 3A¦0¿Ã*x°¤OõX¢şBU|öÇæ¶xòaÿSÜ3¡H [¦â¾HzÕF•«¦KÅë‘ÿ†]ËbñÏ˜]1y¶h¶«S!j4n‹¬±X7Äç×ÛæFĞu{3²Ü‚£Iµo!iwy?÷<Ğalš˜XsóÓA%šNyğ¿aÙ`ÈB¼èŸ‡N.s€€4Fû+×?yAìt,ÑY•§8¯d.@5íßpÕ+ñÅ1ò0Î'‰ZHÔE‰èt¸¡0´OÃÄÁ%
&NÀ°Ù¥ÜÓ‘ÔŒà#cÅsu^jç­Æa È ¥”ÙŸ§ıÃÆDpÜ (òÆ™âV^¬Ê¸ô§ÅÜ"}ËÍUc]ÀÖñ4s'?ëòÔHnmÜ‰²Í„dáÑğ2¦ê)¸ò¥*×Í¤ÀÚPúÉõFRpn&ª¢°BOÍpv¼E­cnGñs¡“x­rV©tVRzŒÃÉÛÇÈûj@7GşF±áŠ5Ä&×i\‚€º<Ş½O¡%kJ¯åğ_²òÕnoŞ]œh’~êaîê‚±zÛĞLÕsú…í–KnMïÃ	=ÁÑ×­IÈdåXÛ‘ DÂ¢~H}ğÌFì/Eb„Î8züÀ€hÆ¼Îš„ûá1Ëÿöè@]_FæA”Ì@ÑûXù®`ß€IY¨ƒ†È¦/¬S´·Z¦-4qQõQV÷YèzC¼ÙuÿªÆx9êo¨¶„Øƒñìq"ëXq®Şê–´õsR÷‹Ó}÷àùtå ¼&ÀÃ•zÁ„Ñ³u¶g¦P>ƒÅâÖÉÿ;ôÚºE©^€ı–‹ökP,“€„ ~ zm`®~ã%9Æ‹Y­õp=È†D cn~l° ohp„”ÆnL Bb„†FÅª£ÔD\ï1mííóyaìÈ¢¡Ğ®U@5ÄfÖPÜttŠBS½6ƒñF
jT74©8	50˜QÃCWAUÀ«ìÏD©­©gƒ»õŒĞ¨ú_Ê*E½ì)%ÿµ¨Ïº¿Öé9ñõ1c=?	-;‡ÛšáËœPˆ·&Ûùé6€ºoÚi¿†c	y.lÌëÇ0g~ß—ü«v6™ p	k·ğ
‡ææDĞâøË	‘ÇĞi[ ¦”­±ZZ®	 *å?PË.S°ÂE/Š‘¥»¸ÆWQµ‡ûşÍqºoãøO.¬Šâş/Jnš§æùdÜºYÎiNY|¯°˜ıô§w´	¾ŒndMîYÄ¤¦Y81°Ğ®Kùa\ª£š¹Úvóë¬Ô?¢¦¨™ÑuÊ=¶»j|P9-Tæ„ê×¡mLëh2¸×øˆÒA˜Q*ÚqÇPˆµRV¦Ë'\BÑÂX01 OSu®âÈ)•¾Oä’iHûœidK#‰(N³€§Gh îA#6“Ø‰x<ózÇá*¸ç±+Eûğèºœ»(ãâ…x¾-YFdËÏ‰^o`aüqcÛ¾É.òpUµ¹¬™Ä1.óÛÍàrCmí‡àÙP=–ISE|ÖòOMü"LÕı­wMóœ„›ïŞ3SsŞ%¼êTÈ’ÁEšV´òvÖ½H±Ñ‘¶Ù=ŠÆ]özÙÑyÛ©y9ĞTyb8ËèX`ãQeXnxd¦£¾–g«²§ê+SHÌs0pğSaÈ:ÿÿèH³6~q“˜H¾÷vùk–£´¿•%NÓPry¯
6êë®jÆÕá Ãšôx££NÓD¾É[NïóÔ¨¸`f›fW*ï#zeÇ\Örğ/ù,¸;ƒá¢7²¨€4®yNÃp¸.Z.ö;ß|Nri|{üiKÒÈù>íÜtm® ¶õéÂ=å¿Ù°Ó“¡q†€ûˆ°1—ÙvE¡ÿ·=,å´
D¯ûJök…{ıe¹GœáÒ§•ıM¸Æ¼Ü}¶"@Ãî‘×Ï„ü„~Î5yç§G:§‹YiMaHF—!ª¤‚.åÓ¡”z-sqşÂ­˜€2idv9š0$E:›;=ÑO˜şg½âL¶™9IZlM¢Ì&z Pu$Ø‹c€“b×åºÈIŸjÍ”;ëˆ|e¶+p¾¼“‡¤Š¯ZñÍİÛ×}ú^«!ÿ‹Å–UvW<»{6[Ûé4ZˆKŠ«}÷ ´·­¯YÆş –8ÄA6ï¯jï£g"\¿ßŒÊ¹S
uÙà3@Í/lm«<¯võBôi,‡ùV×Ã1ü\>$ŞçlI¯ßkB&¡úÎK¥ØåÛpáÄœèj}ïò[Ñ˜CGX %>@è«{¶¸´‹9¹R{!¼:ÜEŠøÅà†œaÄ‚ˆ†dŸ~H]½ã·0_¸y|rÃ·¸ˆË42çÒ‡²èw}¢ûv£ƒA^a=}D†aŸÎ‘’¿vŠgqß…R÷i0÷ù L÷„0L5™^&ƒ=„h€U”{—ıŠ¶!î¾‡ºy³€ÑxéŞ ®à”BT8ÂÛ?ı­¤º¨mèA ÕpSí…í§5¦NPZ†‚M) Œúì‘¥xİåíy°U’²!6*Å9CÏQ`M„7‚ËŞbRÙóW4çtÔyíf¶ƒh‘Ÿî¥¬tcJØØyµh^%²ÉVÜê°R5pï Ÿ”è½Jø¶D‚Er×ªJZÁÄta6û"oë6È§²Q.ê´¼¾–±~/9h±Y›eÔÍ!ÃŠS,¸°%ØŞq2\f°p¥`ü³ãeyªP¤`Õ€ÖµÙPÙe­$&¶£l6éV7_é†,4ZÔ ¥M"Î‘­Ë“ÓéñğÓ0ğ½Mù‘§f±ÑÀÌTìs& ƒË'…´í‚½¶Ş^&îÔ|äd¨K>²N„İcüLÊ éŞ‹ÃÇM+FŠ ŠÔ—¨ãÔı5ş„/fa$	ÀËç|ÊŸ©qºp"sæé!ìZ$Ìu¨¨’¢ÇrÎÃ¾!‚­ôØ*’)§ÿJP"6ƒ9aVØâ]bÁ|'×›Ê	q&ÖédLïr—­ä.dw>V¹C<cÖ	3Ç!3˜;S²Èœ´êº3â;WP¿ãåñáZís±ô?ÆÚ‡VİYNx6ûOÍjd`»`—Y¿©Ç@ ŠöÊyF\Çã6Â4@ı­Ú=m_Ò”*·£ÇŸr­M07äÉÿÇğIÎœb:CdfwLAÌmÆùW3W˜D†š3ïÓ9¹hGàU}cú¼mi-T“Éê±“XÒâ¯º¿9f²NO/WİR…2šVÜ½o(kvâAYªåğBÊİÊt]8`¥Á\ŞÑY˜H{*ŒÙÄ÷#µGòÉTçjøäVÆ9RÈn6³#“±¡jär&¶j‰Shüú*y4ëŒvK¦|¦×˜ïõÇ#M ûşN]PŠ>
á¯{ıœœ²„¾P#áÅ:øgÔPá{¸¥…ÛÜÜ¨Ë‡l­#¡^ª7T4jMH7pS	/‹·—û[p^_á°;‚Akç‚êeØÛÏÈ~SÑ1¼O¸È‡‡ ^]¹i‹:]šÚÇÑÁºHTi[ÆF•+¡°( ®ÜBCÊü<Â‹•zsı½k€@$-¼vFH6çÉ#€/dcuA’—£¦zgM=·!cù"°´Qaúêz/Ö1ÿ£ú¯:z–,k'FÈf:‡Î<Zõ™7-ÒæEI/Oó
Mößá‚sJ›îú~pé¿¸Da¨l-š~‰m[ÜÓúÎ9ë®şúŸÍ“[1:ºtYtµÚkÖ‚k~å£v…T¿³İ¸ß\¤;^ŒÑ&S‚e ÏoU/2(“ª"
úÌZG-z]CÑ,“Ïy5û±kı¿Ed¯J)¼­ëBc$Ş1•”ªıQ®/ÒÕµN7ğ˜KÊ`ô {3:‡å8ç!épuê/%+¿íÍXØ÷<‰·'?~²İ]Q‰t$wÙ "’ëçœò@Õw6d!XÍÊôJİ’š®Ğå¬Hd˜÷B®;—áé
ÅbïCøÙyÜ­€¢}¤ÈóŒóÖ&/·fœ“|+¤!G¨‡æÍ‰Ç0s0EçFjîŒı½d‘#aİO¤î®·¥K =a
ë9~²±ÑîÙ¢³RÄ‚¤ê]?@N„H™kæ”Œ-%›6¬œ‡ÑAâ‘ì;´‡È°Õnäe‘V’ò7u)³ÔS;AöÆa¥N†‡]=TE®ù’İÀØ¶½Šc¢ú ÚYç°¬lm5F÷â¹'}-$æİ–ˆÂ~Ç	N~ÂÇ3-O¯Å¨duÍİ¥c
d
<(·ÂìIX)P„7|€)#óãP³@*0¨×@)Ğ¥=l¼ú¾4¦Gxşò&Z	ÄîûjEM‚2yóMšlÍôÑğ·¹İÙƒ&­z#¡ı»Ói¸.¦ƒFå¯˜m2DQh™Oç©òÃ²ÌâNì…³ yñ])Ê½ÑÛïl!ù–¯uNnâfä4Å©À"Á¿®)­r³GÂS¯ĞÁ?wIé:9;â-L[J=eö.à#û¼h^:#ó]¡Šdªw7hÁÈgrÓÎ~KR­XÌnV…Ö×„†a»ÙP—&Bß9Øş'&£´æù6¦Éæ|éóÇÍ£Èóí#º?‰§ùïü`âù‰ÛŞ:T?D'!(‡M¯8İõòè*ôF¨ÈáV5ßÉ~ÄHÛ¶V"J¤n+„„ 8´“ªÍ"6ºüŒHAÖİQ3¥¤Ã’áåİÁ¯ÑŸ‹ñ§X‹.á5Óã0Ã:Gäâ3|š-ïáİ‘Ñ¦I¤~¤!¢öÙR×Úú¦XäSàĞÜd€îßûù%ßèà•)ÒÙ(s¢˜BÃî™²İd³ö’[^ìaéHMñs¢oŠ<	®¾Ä“¶Ş­tA1ıí´·•MÏ~áXFŞºâ	“¾z×ã›ÇIú.t¾íß«ÊJ» úËùåÏõ¸2pIšãçŞò¾ ã/9}«8¤£!®†cE_ÿÀeªj1¹ä›³òV—â­ÛÃíÒÜF¿³›µ©/İ“)Ì±Ñê8Ì¦`õ\ÀT5mvÖøÄe³]Ñ£Š®Ğ5B:£«$ƒéŒ|²`a©ydÁzúI 8<}1D0Y
àì´®€_uÂ•¢¿ß¥Ïÿ:¢cà)šwë3¯êæıİdüßVbÊüĞ•³=Ÿm\Ó‡"—CÅƒhù^Ê{û:Ü bÕ|à	Lóßt™Û2éV2_i›Áw“ntQ]ãcõ€ëÄ1–±R€s2°DGüÑ•›…NBÒş¥pÉV­Œ——è]€0ÎßTiàÙ°]NÃóe½!ƒìÑµuîI²ğeC(#/p#ÕåÃl!ó£ùÈJ¨Ïñü<%Ş™Kc›Ê§	/'Q†>†§‚¾ÌCQ„ŸÀ®ê·~ªÉµŒÆ³}ômÅHÖ{ÑEè½Ïø{ßËıİ¡:‰íÅ)aĞpñ-EjJ@ˆéYĞŒÔÖ/e.á8Höú“fßg÷¶xm•
î±û©
Ã˜×ç!	/t*&CJ»nâ¼ªY6'×änv¥bb-ÏkV7òÇ&j¤›^›¦ËÂ›6#9ØãÈ—]“|ìÔ[k·?£Dà­øpèGÈr–\d‹õÑy›é'EZær3Ü%ÿo~íŒ| “|ğÓz3ã6[K[Ÿp`2ÂÙ‘ÍŞ$º¢`P¬ŸxÈ^W/éqØ$×İorÏSşƒ¼ãDÅ“+ÂìW°½¶¿ô3€T¦2Á˜§”
Ø:X—67iÉbƒ+*ÜÿÇR	]¬ê@SÂ´eĞ8€N&÷ùy:u…g ^Š•c©î/å¥C)¶ØA7ª4”ydôZòãHİs½§nn‹aË+80Fè#´ÃˆGõOJôPa®dyÁ1Ğ¡şêB-X]“]¢òË¨»w§ö¥<ù šÁK`†3=f~ca$|‚‡ß)‘4v	ºà8;Ü
!ÌB­ÛÚõUµÀ6P|ZŞ»¨E†ìŸ‚òi…—aúbí›¬ÌøiŠ+à³Îm@®Å7cÈËÈdÿˆnÆ’c&vJ0†[1 ñÌ8
„^Ëµ²{ñ {Ir2”,ítšh“Ğ]-ˆü±§ùøèßI
Ó![!ö´ı““°ÎÛ~ÙÚY¿˜ÓDÚìá§ÆX)¼Óp¡÷»—ªoƒÂEÖ ŠÙgŠvş±xÌ¼ñ2gTF±Jï˜¿Ågù¹/^’H5$?®™½KÏtÛÚ/ÓµöÙL½?Œîü	•‹ÂŞ‹—ñÄ½sô®‰
^;ŞİxúM]MJ"¹\BS²QX—£‘aç¹±ú*g—†ºOK‰4j<º‚‡§«Ğ;âçÊ€€ÌõpD2æñ[ÀJ–p¶ç
d—Ó*ı%L‹Òæhv·ŞòÕo`w¯Ú“G†%ËóA2b©û{)ç›EÉï= ÷	,`İN/¥'YNƒGª×øHtW­rn¹8Ìaoôg“q4øtÁµ¬ª9©|ëÎPâäxêş^İ!±}ªàl·2q9¦NOä›¬„¡±¯™Œ&â/Î~Ui…:e‘M®±€®˜pˆÆ/·T7êcxX:m¿cõßì7šJÉõîå—zø½€NÜ$Ä;‚àŒ8±™¬™ı„™}¢£éË	,ò¤£“.©kù‹Lü½æA~»
û&ŒÍ»–j]„ÂØ÷¼°xñéÕÇ-rOÉã— ÔÀ\¬­CÍHğ­~ØıOµôÏº[¹1ƒRóÁ é\Æmó¥	5~ÜÁRÂ±E³ßTiäif6ü	í.ÿ-]}Âde9ëıQÓ„¡¢2ï£ËušÎo—ĞCŞCÍ½í>ùëzKËÔÑî®ñßD©¸
Y½jlõH†œ«,5S +ÀüóB±I
‘k.®†Wı0éİÃ.d´(zzÍ¯Äá™åƒ#¬”í‹ÌâkÈ¶"*ïúÏŒ»†év|=œ„¶&­ş=i¹9aUü¡ÍvŒ¦„ÔÏ½‚ 'mÆùØ—Û×giùT£±‚íq\2¤¼™y¯"Ê­i­œ÷ÖO	9}IÔ6®	Ò* ¬n¸}Ó­;\‘>½VÓštHåzü  #æ_pÅİi+8ƒ"[$0ş@Ä4]Ş ¾wmĞRfÃÓàBH„H–JË›h.øoÔâ-ó@8ÿ2p‹:Î|ˆ½å#İ3ø[˜f•v©ù”äzJ²¸Ø[’èUnŒ‘I9ñg
67!vM"N¬Úxœpêìãl<|"á§±ÉA[‰şmŒ_îó_BgDáÉŠ²¸0ú×J˜±Ôã|‰c£Ê ?+ zğDæœgQŸŒ5­ÕA„¼”¶¾×M\LğI›Å€àZ!9á*q ¡…Ÿ@D¾fV««2V©İKLª*KúÕF¾ Ê>. 4%éÊğîn×á°7¥æµVÄB™Ûèç%õ  + º¶µ‰ü±˜ÙA\	Ğ3*«;™3gÜæØlg¡v´ÓNx•[ñ!‹+:œJÄÕR™óÏ’Œ‘/ô¾Eæä±İ©]UyMa¬
ø#ùPéşŸğ¨üĞEÏÛäğ¨DØ¾üÎ¿¯—6ï÷é€:²—oî†ŸŠ#qyìÕÃ~˜]¢€ÛƒêõS8È«-§uØ\àyLìÏÎ¦Ş¼úë¥Óİğ­dÍM*7ÂÓNÂÒïŠš.÷~æzœ‰/˜óÄ*XBFRuu“3„cÉøàŠûŒÀËÇ¬üh®Ír$ /D•CIñßÒl¨ÑÇWûmÔ‘Nä)‘øÄ¦"‡ïaª^«mÜdÓdL,-Çşü#ı"€½Ş‘§ğ):Ş¹UMøôáõíj
.°Ïêæ	&n½ıÑğC×İ¾ó1¬%´¤üÀ¹õnò¶v%#!kç4îœ·ŸW}MÕT’1)«…wÙXRŒ4ô±yª(>§Z„‰mŸ|.íeiê/6§ÚÖ’œéÇ]ÙƒRkÕy#ª
%-¦ü×‹õÖ’¼9ı]¹`ğŸíçsn¼h8Áãz‘Ò±PªB;Íi¿‚ƒ|KÈKÌ·Uç²€¨¯T¾IFë*d~„>,o€
¼İó'²^ÌKaxÂÑëZÉ9Y i$1LÚ‡t°¨‘†kƒ7´Åè0½Ûr…ãC’ø¡gÇÄQÍ­Ôõ`Àæ’İ–«TûØÙ^˜\ËÓƒÕ%GÊòúÿûé]†ıL:|8	l½D!€e³w{
{ÿŒ–')äˆIá©ƒûôˆŸ|}ÒÌJ^ˆ¢àñ‘LipGîÃY£Ï0Ñ_ˆĞãÒÍ·IÔ²?ƒqL	Ç¬á¡Î+‘Ï"˜<lq°‚ó}CÉœ wg3Æè¦¬ÏêÏpÿµ¯ıEW«M[¢Š]œ‘¥Ç.ÌNrŞ³SL¨¶IÄ*şİ¬´´Ä‹9TT®3³´ó›‡Ñ&Tábñ#ND†<. fQÑÄG Cíí`¸)7Eš#`ÇM-[ñò¯.èEHqs#ãË«¢lä‚&(şâpcñõ2^—9[9w¶8\»¬•c"øoƒó°u¨ré÷“şu„úLf¶B‰Õü¨ïIø‹8ÆÊ ‰ÿHÀ]í×hhé7h´wXâK ßº’
ƒº|ÏzD_q±t˜ ğg3êÜŞwcÄñŸÑ¦YQ²?uª<ÕE²Ì‹N \™µÑ›úÖ5‘R´™:€Iï ™,Öz¸¢ïÔ’µÒFmw»•Ìç¾¦>¤âŸ×h©ï/@}Zñ@ôÍ%T<bézÜ,<ï5Ò w$ÉÅ¤c)å¬|WÌ2«YñBÊC–_.ÏŒëíÜí§ÍT„a'’[•x94Úô ğÊæ½ïd[ï@!Øm	š²Lİ™úoò%b¨xÓñÆ8[T»#A	ÆÓ·|Y@şj4x¥&eƒº=\dèúÛÚ ˜“NÜÏ[KXûİ{ì$ÙN@IñùMxr®ø‹“(ùmÅÚ:€Ï"DßÉ._Ùtºêñj8A´e '´)3€¼(‹9%!*İ¨zÙû‘¨¡ŒB“_Xıİ5º`ÆÎ„ÇVÙÜ`–¨À,³èHıß&±°lìšò(,­:Ïrÿ¨IhÆ\º åbÀe2o¬>üe%Kœ0hısèûÃvúF¤JŠ ˜‰l1ùCNÃÔDÙ÷#‹£2Í
ëM=½—*Ö·‡Ÿ‚nwŞÆÎÀˆ‘øÇ¢¬Kòº·v­A‡‡ØdÎ¯èIX€“È'ëûÈƒiURR‡»BtÓ1°ù*pù'ğÑ§™¨ŠãÄ1¼R•p/^ø /ğeØˆòGp‰Å<kÖ}Í<Ï‘³ÆxY!‹§ö\TÄ¢X÷šÏ·|‹['áoFŞf4ö©¢‹½›É=™iñ(Ö`ODE6ñƒ5Ü“ê™bŠäûeôR¼{‡sšY¿E6(ÈW²ŠÒYf%|i @Õ°Z´2W4~p°3¶£á@0×&6æ²XÚ"×¦æˆhV)á5©Ö¡Š@\™˜9ş iÔ_`ª¯>Î…yå[ÒtÊW ”pu:ÃĞE¢wLCØ¾Ô[¥‡Í	>>$"wª¹˜ÌëJŸÛñ±û‹•”ù&#e›ÔZR¤+ «xıU£$"[ÍŠ—c—<½-4Û ´ÙãÎòÔ.bç|NU]LHvJ6l…ú—`ÓchF}zV­àÔqÄNıvù›X¬mŸ8ßÏQ ø_M˜)yë‚h<ßfm”YŠE_¢„.—púm{Cö•0hË[ÁŠ=Çzn¼“YÏ‰|S•Ó€¥ë][‹¬€Şü€^¨€Ïaq×şà{´ô
'k2vŒ>‡Ó[Øià²ûeª¢ÜR˜ïëo„˜+éZQYÙÄ`ú¹!‘x0Dtó—a÷Uy¦Vá‹YÆdv]ËW¸ÉŠá¾tÖ‰Ø¹| “Ä°ö‘¡˜WÏÆWìû±1ë¼÷Ñ¢YE«0 Ù*#>¹ÆäÅ_ˆ´½=ôx{M{ÌÛëÖ‘HÂuyÈúrÔNñÏ\RÈá¸4a´e |öµĞ²–3â·Y†„ß†ÈÆ/·ÌŠCt¯ú´×=K(½õÿxÊîvešk§·Lµhng4Ê1/!²áe6Š,–G©ë[+´+ÈxÙƒ1†ÉÌ·a²Aò?ìšë¿e»MÔñnpgeî)ÀšCjößK
Ä…÷[÷ş‘7Ç#^3b·­JhnàÓŠEåQ*Uİbrg:­¨–H©”9#;="J2Nì}IŞ@_àĞ›¯zòLd`à\¶OóİV™êOk|'ûøªÊj®ÇÆ-p®_
Î!a¯ ì1£~DÇèÊØ™ğå£èÓwÌÕåvçHÚ‡fúÑ}V”q ]/V$ÿ.-;­•v~¯£…ó˜œ¨öMÓ5­ıò•öóñ³ñÉM7¸zDÿHëmo5İ~]DñßúV KOØHêùçŠÀ„®¬CØœ nš£ÍKèa‡˜^F|1b$¬ìƒ8ÚÓ.ªWşxa…<¿g<à;–BTé]@µÛÜÓN’ëR)ÜàÉ³‚qĞ`ÇãO§ñn-^…Z‚™ÚKf”Tˆ½3ú¡/m›n•œiÒ)•W;D]¼™·éi:Y|šÁ?uKsA9fóşÊêy‚saÛ,véT¯¯|æĞ6Óo€(~KÆ@íêc:J¿Œ„¡‚~Ã©ÛaÓ}Ú€J7ü~b3bÇs;1n:¨Ãû1öÙJ°ƒS;)!8¬Üù_HGÕ,=–ú*v¢•f
Ã%ÿ3î›éáò
gÓ)ª“Xû‘ıU¼j¼œC5˜zÑ›ßÂÓŠf½´YË¨ş7˜­7ªÓATxó(tÇqxœä±z:_FÄïM10è¬ÙÛØS§ù;Ñ)Î§‚ÂÅ×ŠÅ{®{*°ä%âÔ®ÀEsïÃŠ›wª¬”´ğDUä/Ø†ÚÁ`»|2¦jbçü®±LÀÛ´¥@V1§NĞ$3!X£àG?×Ûã0Í¸‹ó>ÚÀnZÖK±–¥™İ¯q†pı­=­Mï­_‚cÿ  á_	H8ã/EHÁjìM;Øú|^ªsÓ]ÑîvƒA	vë]¦y ~®Xñ72õ¹n(„ØCIÁtòU+`bzİü|Ò—½*¡v[¼ËÜé‚£vmR|UÌÑsu„Š¿“/3˜€õ²ø3<ÎÖ“Ñşù¼ÖÕ“_j‚6¬UU†´ËÑRÂ%'j`+›:%ôyÄö u'à×òÿ¹5ê%Û3&Ååi]­"+{Rì–õiinGıVCNÿ‚ê"fö©oˆ±ƒ˜|ÑkÔï5O}? V"éRé£“X…»í–»{şggx—IµáÁT`&í
Ä©#I¾?œ€úËŞ[é´Î‡Ò‹N>ò°v"2Øk˜3ø!ô³Ùj©ß
5fõ¿¬İ[¨qÓ¤›g‚hÏêâ M©è­”Û=NYq¯p”¨«%*œ";²bTÁşœWÚ-÷±T¦Ÿ÷İ²RËÕı†°Õ¶{ó£z^.q+AoôH5X›ë&	¼ŠÛÅÙN[y®Åc*ö1Q-…§’Å\ÅxğrèO›+®I¤zQ´ú¤7Tm†œÍ0·¾°†Ç“}ÛEáòÏZ@çdtJ*ßÄ]³[&^ R»®¯qoä¬&£	ìs•…Úa!P˜1³èµh‰
Ûµãé.â»««H€]w,‹áÖfP/ºñZuª» auè õ_§³
—aÁ°ú­c¿ù¼€lĞge,ó	mXÜb‡8øĞd,„#}W¹Í©ârµÍK¶R¼_È^²lŒÁJî Œ%Òñ¹Á	hÛvñØöl}x4ÍË"èÁm]V×ï%Åt²²4À^‹æÚè!èx×Äšwf8uzº	ŒYĞF·;mtM¼a–“s™Î§.Nõ¸2şìuíßNÌÑ“Xb’Ãö!Ş9Tû$N{(Ô±š2Äb	7˜Òà!¯I¼Êì‰"+h<†…ë}$oñ„#¡E 8;¿ërÆr
ÛhX{iÜáš<*¦ò=ºŞFönÈ«1¬¿QdÌ ğ²ÊPK[œµEM»¶Øıí ŞÉUO‘PP~"Ğ‚^fg§ÂtOe„‘¬LÂQ`¦B¢{l­Ø#ëõŒ]— ÓZ™0Ã,bãoôDu<}Å‡‹ù;¾7Xa[oR HJ³{CxÕ=³µÊØ÷â¥C\$r
Øš10ÂN‹@as}>UP^–g—ÅgfÜÍm’Ö6Ë)yÎ‡ü6)Y‹û§¸†wOÉäyleHVE,l<“Ä½Ò/Ü¯Fı¯PW6Wô~F-ı \R€Øëçºöš¾ÌÍfÃ~©¥2ïÀš"_S`ÊE¨ã{Ajæ=êˆPÃ4Ú«Ù¥ÄÖ±Dö½4*0µé•(YNqÔwUƒÀ¬Àú l¸j=RÖ½10¶ÉgÄh¤]ÃâÃšÊ½¨]ˆ—#”› ‹‹Óìúû€ÂºP ¼«ŒÑBK…?ü’Eú)J&,)-yv­
¬p4¯~½ª-]Xğ´Iı;M°¦®¡vÃ)„
8ÌH×"‚«;PX1§\û#Jl ~ÊÏïŞ<Ÿæ˜¢úÖùËÿM²~QøH\±ù›ñq%ŠÒ·<G”Jr“d‘m^¤†#4´XèÅşowï×­~7É+ìí„¥õÿv³™E¢ˆ‡w{G@K Jãş’p3œ‰
XêÃÆóƒÃ2‡Ğá
¡4% 8ƒs£Ú8Å™y8Rµà˜×a£–24Ò~€Ç‚+·fË ”ş~j^w½pIß…FU‚‡7pÃ8C±jßl€ã±[3LÒKmïÊPOêzşÜˆÏªì‚:0¿¶¬läm¥œÇB[ŠÚˆ6É&«8Ö¤÷\Ék©ÇqŠŞ	´;uÎ3vv¸•¹|§g´—Ò(ø!“Å,¡G.Ç*ºS Ãøº©,ö-ñ·<‹Í°…şuÄÁ0Õ³YJ“¨o§ÉâMŞ,lß=µÆGuò’íæBbç¶€Œ=V2,.¡^ñ³R ìXî´4³
Ww§«äIÓØ*òcÊµl\É‘eådÃÌûûø3¼>DnÜvÆÈÒ·’f|š,AÏ5¬v3MŸ°JPÅ˜rÌˆJG~]ˆOF^\bDÏX»ö”óÆÇ˜#ë„iNT.JPÈv1r	ÇÕ¢\~×7lxA#+Ïv|HàõÚU|^£„ —ë®ôê.‚õ ›!— Œ8!h5ª72ÆLR,"]©½w‰Z|ÜÙ’àØ„İ´¤‰Q½ôê‚£FØÈ}iË'IºF´šºñ“»(Ê`C¯·`ÍTWôß~ü\¥ŒC9üñn”ùSøêÔÁÊ”6—g‡ÿwÕÃ<pŠş‹î¯Å¸Z|©¿‘ÈyD!+_ó,ÆÀÒŞ2 ÎØlşn4şÑe¹@m¹D¢²T{ï9±-õoá;Ş7ğ×‚º&!µÉ ‹Áf¡çË`Â½dgjŠ	¯ÓÛÄÀ+sÇ´ÿXu[Ğ33„%}™T££Væ¯ó”@*ñu	È¶8Š=ÌÓ·Ëlğb#Œº™ãO­N~´†ã¬t©r¤ŞRÒ¹ø•Gˆ/GÛ89	jĞáNab"·×Ü‡]«\µ€î¯Ôä/—YÚZ@„k"ù¿|—¯ÅŒÓİE†Ğ@İÍp$v˜0|¸U†¤e±û1Ò< GEHp ˆÚózLÓİ8ßÊ“7çW/~­‰/7ò¯”µôULH1Ã¢1~öxUÔï¼F“;9ğá\{×–}J{À®” ’Lº‰mbzdL#îƒÛ§œíÌ‰wo2Ç’‘€º9¸×¹ÀŞïÛ¶™ÁÂÚƒˆè×qêÿ£¢½¸>^Ïlª´Ü‰7ş¬rçĞaÂ–OÄ
Õ5å… å5ªÄ6óRâ¤Q=÷~§·ÿæss*Ø¸pN³,¨–x"ıpJø|Œ÷[cŒÎ;¡{Œfô ƒˆMxAk¨-B‘œ!Ê_!ü+ƒ±9JĞ€8N/F;Pª8ÏÖ¯e€EÒ1 !ñÎX¹4İ°	š¹¿ÆŒÆjİ¨Œl1i‘×ÒøÂöß#Dºe€\Nöø¨¤o0ó+ 6Ì´Ø"!0¿qj6]cÉK©­~
h áçµTS±RJ`$ĞŞÏŒnvƒÊT+–İY ä«epvæ?VÃæy[ñÿ…•+Í ŞcáÛ´U•×Ô75@À®İ0Zÿxr'©Ê¹ıf–‹ëkªğjËÅ}úk¶Î¿û$Ş™ÿ2KÑ@‡$±°UDã¿sdĞ5$Öó5vE¾Y]|e,zîÄZ¡<¡T$r’¬ìYIÈ1QkKÚŞzÀúf†’‡=•ÆâùÂÒé“/„”dT-A½Åßy#T}™i9ôG'b0•‡xËßà¬Cs3¡ù?´c×ıºŸµ$+~wqÿSqO x“€GØ±J=Ò€™êœ­§\ÔdFá¹[^8 º®ƒŒÖ3%™UĞ—øæC¬üDAÆÓSåzaÂ8ú.lCõ± _	<Ö†XÕ•ëZÅÃJˆßm£:äŠ2e1Í~2şÏ½‹UGyT<xÊe©­@”e³A``’•6TDàIÌ_éÚ~DGÁ• L~§üêî¸df_Ó¥¨P4F¥ÜßğÃM¼t¦w t„‘= [ºa±ÁåäcÛü³Å•[1¡¶¶kËÃ¬Ş«†Í+Òâ§¶6”Èm­èê¯zÍŒ–·wĞ~/z	#k±Ô{˜şd®\ğGY÷]ı#«ôdhj\j+ÑXÿ7UGdâHÂq2³°ZÅÖ“!e—™¡»egvÕtÀäTlÛˆ·°‹Dr½:m*Ù?µ‘¿Â±'ŠûéV»š/D¡àm-¡SËœÆ“³œ1ˆ¾iã¢f <<ö[Qg{H«Òeœ?* “y¾Ñq°ez4¥Ä«[±Emë†É¢Uc”o§·I@h’wåÕ¦Aœ}é˜´êZÍÁJº’Ã²@›C}ğ¦àbà‘A•N‘şÁ$Ü4_Qç¦dVŸ‹€ä$aOm·°Î6º`ÜWè°ù-R Cìj@ÔÙc6•eßúıëç(¯ôÉƒ¼ó'^€/@pLJ
nïnPÃ3ym·ã®mæ‘;¤ÙvVÛA³ÙSæëbxªç|„?ï2-©ßéva
pÿ`ï›8Á‰7ê…K:dÀB÷~`©5K'ªè§éÇş‡UÌHŞ‘®Ô»mê‡¬Õ‚—·¾¹ÉP}‚ÍşV|¹†õBÆY»†¤ŞÍx¤·›g ]$’}³»Õ$œªq¥q ÚœŸx¢:rÃ[‡fQæ –Oâ|Ó}[n64¯ARÔÊãjóåtkÊ”G3Ï)áÊ¥¢„Ab`€_8¿%ƒC–.+º°»”JÓ½îôáuf|÷MZ)õ­, w q—§ıŞÁ‰ğ"_	±^&¦Áè7`p¶lÁ)½1¨Èø;·˜^¢jL¦TP£édnÕ÷ Õà—ûçz¦?ªŠ³Y¨“£AÜ÷ÄuÜàüiæ*­\å»ªò•î†é8å5Òy1±V]•r#hÄ#ĞÌ"Bğ¸ãÏg•~Œ#}>:®zø¹¯ZvhßÖ¥˜iÄgUhø>KKJ¬èÑgË„Óml•$rhS¥‰Õö¨3³0dG–3ñµ÷}´{âû±‹ßóE¹d/~R±'=ï/HıúÈUm½zÆ^‹ÚZwî¢„CÓsäŠ?ı*òH…IXÂ|ô3ËØ…Îä–Š&n	Œ6fX½e—á£Ü_ci(Ú f2ó_¤ü‡[Úú›+AÍĞÔX
PöªwH:X~¹`ŞäëÉ^ÆÈ‚<Ø0Áß)ğœE`Çsƒ Ùc‡»¼à¦[À>èÖ-;­bªH/ESgïB‰.ŸŞ$Ç0X5:…¼=mşy°€ùãÎ3Ø~®^4 éÁ…¿¾sV²ñ·®Z®g#º¦njµ Uú@â1ÑÔ@É.'AÌø”¸Ë˜ÄY}Õl„º‰-	98\š‡ú^udK=€d°Æçtø2Ú‡oI5Iô»’MŠÚr¸bªz·yºu¼<C³P~-ÓË	5ñúõ¹ß#ŸÁ{İ’,Õ<!RÓ+ÍÌB°ê”ÜE+Õ.ØN^‰løwV¸•Ê"òöqÌ'Ò5¦E~íšò	ªÄ¶@gÆ¸Ä¸öÿ¦2wØÅÅÂàƒ to_Ñ]¢»^:~(kJpü±hq•k@É—+0oGuÀçyTĞ±@™ö`®Ë~<ã1ç¾å’Ğ¯©Ü97˜§Lr¯ï2`éñQ ,¬¼»y?Pú1EµìiÖEÔ|Ø¼?ê±ÖÔw½
8ımÎnÈ%½Ğî¼`_l[Ehş0o¤N^z/Ğ†[Ö†1Àge—jz+€ËH½€ˆC§G˜™‰!…¢¡á]ÆôsMş]Ù<å\ß7%À+»˜eàÏôkÁMäw!´7úI6ËË†Ê&­lSU%æôê,8m£GÈÛnØÇ§¨aÂ¦~’W>ù†õƒºûGÏNSä7œèÖ¨Ï‰]º§q—â|¸Ñ«ÑªŸ[ò	—*t$uŞC¦/Ên_Ya9°ÌŠµ“Ö›ôQ@Ñë“dÅÇ[
ó©…íeT™]eß.˜—İfNPâ³Œ[4™g7Ã/Ñè +ŞGìrXA,xOÜúé_tZ'ç“<‘¥Ç'ŒˆOŸat˜_õ!§ù‚¥(ºûæ%©À*i„³D¹nxÊ—aØ8ÿÂhA.7‘«šF˜vnr’¡®2î‘~m>ÿ’¾ßìÇCÀ—|­h3ñ)ıEp¨TøëP^…ç6àĞgì„è¥©ñ°ñ(;åAÜ©Äû¾V9: ºJ^è¥»/Íƒ@0ˆtÿË½ğÆÜhŠj2ÉNâ\B¬xY¦ŞïîŒüäz…@fÛNGcHC)–ø4.ĞùÕËµµV\â§3¥_±Ë›O¹1Q‘á£fì éª´b´¥1æŸté‚±éH­Ú¿"áŸKŞğ
9×m¾ˆ`¿\XzTÉûÃH%›™A¸!ïß7t+úÃ¹+8F¦íıÔ_o×oj€MÀşÚEZ}ğe™Æ¯¢{dÚUÜäÿåİûK‰Û¨îegÏ@YÔ•×N,0ŒÂÈ%iAË²âº€f«ÉÈÂUß"{ıl=fo¶8Ÿ£Ñ!L}´Hv÷ MyÁÏ}è~®‡ÜÈš¡–.~›P°ÙcŸVãøÂÉğé«ÑEŒ˜Dàgz_ú(Lb-8gbL$Z[›C°xˆ“aÎşkÉèâ#ëL'O0H°ş	´ÒtX,eöO‚ëqß¿Ì„ø·(%òÿi¢J/°ù[ï, ìœ`ûtç]”„îO
¦y	Ö5oË ’¨ÒH–&‘anrÇd58qÈF×¶üXÊ‰5|"²76ÿ7Õ:›ãÔd„tD(‡–Ÿ?æŞ}Òr	Ö—N&K-Sí.§YŠy£³"lï»ênœó$åÕaÉ\?êÕ´ó¿[Xï·Æb¤ñ2%ß1ÒÙ#u±¡´I¼³Š-ºªû8Hè«“b¡û0èZPD.×æÿÄ•n“…€Œ›?˜"FÒ¹˜O\Ÿ+°7?)6è^µ»Ã*Øgc’[K@Û¡X¯Í0z¤ßmÅzŒ"0‘‘Ìtªç8ÔwŞÉõ,YCü53È^:Õó”‹p/™X†å£ÅÙ†ë“Û02+¿Î!ä1Á…½„òäZ5Ğo˜?G3(—'å®‰—še¹7éÃÚY×b¬ˆwxg°¦	3Éé(ŠøcDR(dÜîD*—‡-Í4†f˜R8íÍít>À«íĞ·Å­ê¤bââ£·[ÉäÎş.d»d|G6`î†p1’•d}šNy£a]]}.@HüŠ‹Í<Ÿ¼g/õêÕ·_®—WŞf%u$OÓçûB¢j‘ie¦9!òj±·}1¤±#~ã)İÊÂôp}…¦yÆù«wÎj2s«¤=ÜJõÜÛ„iTxbê>?wDÔrñK’E0ŞØ€H^â+“”$DI48ÄÒ=©?q÷hşÔ¬~Pùİ’İ`Æ~? I[§a3î<ı–¾¬şéš™så*Åxq£À‡‰©ŞXt«[-PŒÅÊvo²©ø‡JcRşºİ¥¥1XÄìã¶GøEŞçAë¡ş;oİ%¸Î-‹†Ò®…[ôÎáŸ¡&-Êq|j<ïÅ‡Ü@ó^>Ñ6”®=½sõA'#|v[
ÅWëšò),X¥Å£=7é í¤Ä[I_BŞd¿ÖÙ~5¬ÌTHo›&gúËq¡À1‘±;ˆæ‡Æ±,òÚşÃfõ1u’üÁ}ëÌšÊ‰%‡J
¦v>Í‡êDE¢Hı"GÏñ4şuÁ3ìJ¬íÙ_ÓxçË’J¢c;P'5 å‰œ%ê^Â–ïÓwçİø
©Çe:gÑù ­rÖ<ÏKW©¯?I3™p¡ L
6;ŒâşÖ¥Ôc‹Ôúg½\[‘nƒêı`¡CP€vcıáHJj™X}28¿KK*H½Ÿ³^ÁŞ«_:I€=®º«,\\kâYç5€ÄuqË>û×K·Æ?Ğ{t:§Õªë/’¯5†ı’2à,›õ&¯°šxo»w)ùÏš
+¾£·ø„Ç£#”JÙêç*@~V8úä½DÍÔBEÜfMcö‚ÛÛ'u…‡Ç	í^ŠD„F6˜ÊØ ¿¨¼€Tä7«šHëCxÙ×ıx”B’p¨¸›TeÒ ·áôI‡½6F/Şk.tˆA¿íñyJV;ÙŞ|Ù£Õ¹Ææ—)¨„ü³N¹÷™-£Èl§÷F·ìƒ?¡íL™~-¡§`û>7‹L×Ìæ-•’­	€b”ïå·™í»§§Õ]â1äzÆ®2ãªå{ù/UÒ:J`§G_Šz~AV4Íà*Ï—QIÊÖŞ,úÜ&»²_¾¢[“`º¦É?¡½`gºMñ'¬¡á«¯À¢´ëFieCMñ€­ Øzc©“[ÃßäŠQ“É§Ğu@ãÜOáÿj¼HÂt¯ÖyYHJ¡ÛİÛÍºi}b€©L„üÅ5QwÁÄÕĞÆ‘êûé!¨¥n¦7^»=Œöv5YÃÙ"ğIaÄj›=!£«èlfj ÖRôÇ-Ráœ5‚/ìAÔ¬ı1yÃHŠnóº¡İÿTW¨Ëc£nV®¶{ÿN¸›ß†óæ9,ªÊ´¡ÑCC-"Q±&i&¡>rÌ :”Y÷~ešnuø’ç±Ÿ#”†7Ë¶@'Ëdñï†[»ÏDììe¢ÚrYÆ|¶V•ÒÑœ¤mB²™àùfƒ[¥ôî×6€GM~ö¨&M°¹ôß }Ñ›Â©VÙü`C÷eË›ûAiÎ¨œé ]ÃÌ]ÌCNd¬¨ª+EyŠÕ~
Š àºlÕæ-3ÏğìAÊzˆŞ4}ÍwXûVQuÀ±nÀ,´\¸;ËâsÁ©˜¢‡…\3+—Ô§ÛB
ÿ^dkñÿäï‘nX£IÇÌ½Œ(<aá¾lF[7Cİ(.™º7©(htïø†&¯à§OLôŒCŠ×U‚óòÅç%Üø=ô|Õ;ÛøL«îbi@’o„¬›´”}"œ¹Á2×¨«$WìöŸR*ÃgÆqÈuŸ“&MÜ}bçeñ¬•c’¬FSI°)%Î2óF‹‡ÖÒÍ.)Ü’‹ĞàTV²&’Ez?o`¸A«·”Æ¤{vÏ W#G§‡/zíé‚›>³Ø	=è¾,ÛòÖt¯Ša)áœ¯Y«LãÔEJ'ŠºyÌ×õ,?d»Ğv”¬ˆÛåyÁYLúŠNåã"J»˜#ÀÂ.¯ò£&RéÜí‚^°.‚úª’uïÇ)©ÙæŒTe°ÁÄíg4Ë´Íœ°O‹V8Ñ5“şd‹¢ô¿^.¥k¬“'dæq]Ö•Üğ|På“¬áß^8C¾40Ğª5îªË0¦e›îæËäü‰Ù+nJV¼+«0şM¡T³¸ î©3 ,ë-’^³»:‘Nj….¨?Pº`Ø<½ÅxG“ö£Gš]ßcÍ&|¶¯«ÂÀ"…õõˆŠt¶EìËÃ‰Ä +E†VÔƒg³¢è›¸…¡.¬jYe º¤ ®¢ó"$à±Aƒİ˜ÍÚ´.Ì9õª˜İGôÛV­Ğşyğ3úlx.ÛXk€£[#p2Úu›hÃÀñO‰-/¥wH5CT€}}ûÇCƒW¢rËr,q¼.ùÙÒúÑú?cM}9é·p§ñÙ y;v—dM<vV‡åz4³Œwà|¿rw_!T~›ÀB®IÍ0¶êƒVø Ç¶Áp+c£âÃn¬Å§à1ô›Ù}ü×ĞìVA«Å„Wfúê¨ô£ÂãPQÊ—±e„?ïšIı“|F:›É–KÛ]j¬öÚKB‰É3«çX+((ZÂs@+Á5‚~±|]GÚçFC~yúI'ŠĞ¿A])ü¾ÅrñêQÑ¦!%•(ı?j«–¢N¢Æü©lPÑbF€9Ï·rJ£Ö¥-bVÇÁF«hşª†¸€n]<S/”T“€iäß™8˜„|a'A-75÷]™b4ËkîÌ£=ÁPy·°è{=al.x’ÑV7L.ú„‡5õ¤y²e˜Ô'»dÀPíy½ÈÃdxÎî¶‚=+rd)ÿâ²˜àÓ{øc™€6ˆúèÏúªô$yîe}1ñ:%…Yœç¤¾ıKÕÎèİØ9Â%>¶İ“k3.àe÷KIÌ×yî§4{ş¦uS*çŠèÓá†]“o^b•+Àm”«™S{>„f×+û±IoRUıa—ù'{¨
9| z’ùÙêY4¢‡ìÒ¨TÕSYM?ö³ñCKxgÌ«¸äh”Óáå(\ßÛ“Ÿ¯ÂÍ“^I]Ç‘¤ƒ{?äĞ•*aôpƒ(TÍÔšà‘ÑŞèXIá/ìyõUhdöw¶µ˜X_z#_ŠäŒN€ãñw‡Ìwîg8îd`XJêwnRÕµj1ju^+2SØiÒ‹z Ãj5:q\¯gÃY_ÔÈ ±¹çYÃÅ²‡3FYXF÷%Ÿ öñjSÃ¦şİšúW8£èFÄÒü¿ø|ó
B)‘åUa‡_¸ß•¹[|,¶ÙacÅèæ™EQ	üvkS@ºJ3g- §gÎ©xÇVŠUDãTÀ³=¥µ­q;ûL?‡_D¢º{µRÎ»İ¥UGz*ê]&=<dœ³KÍ‡íí×ìÁ^ÏåÜ—Û¢F‚†IŸ.3“¡·Ğ¹ÿUÈT}±™Kf‚|NåÌ&Å!ı	yXIğÙ¡¨áŠ_èbjÃİÒjù¼<ÅvN¿·†#J²6a9›¤ğ„!ÄÕöG»K&‡¤üôĞ­9¶Ké	i‚}‚TùK)”æ,~	Ëi"d9"ëW£êúnÊr7Ş}ÈÒÊÃŠ›5¦x–ô¢±ÆÚß½‘5â}Û;Ok<ótR!Ñù€Y"ˆ|»¾0¢G¯__úgi‚¦—`úC;æ´I©¿'×]v|›ü;?6¹ßÊ)AğV¹•Š`gÀ,=•Ì€8åÜ!%Å˜æğC)zØK>¿ËÑ5%SCÜµßlª^ìm–-É¬d–Ç§×Å±š*@…¿· ×D§éâ¼¶S´SÖ˜îó„•Eä†˜êÎ¸N“çwLÖ
0ç»†ßÀ&'ÎÜ[z¡ ~Ğ±ã»L	Òí™p@2D±ç#î³ND¢úó£–„M(Wãæ¹_»ïÃ3\Ö"¦„ŒXeËæıwIh¥[Ø×rŠ À¯àÙ¶D`qõhĞuMµ‚e€tˆ²–—ª¨˜d»ÀÕçò9´ÓÄ‚h—:”¾E&%°['±x¬'<*Mgã…îRÙìÖH
‰4Yhû•öšs¶É‹ı9$z«¢†¢ÑŸ‚ßæ3„4ÒÁsªÃ¢`E¤Øôqï˜‘_‚×‹¹e60ùilQÊõÛ€ùSr•s²í¼Xe’zó0Ç1´­æi,$¿>Väèûû³íkŠÊyÏâo$Ç’ñgMÿs:úÿg~â»bÖ§›D¾¹¿şG\	‰37&Q…§7ç_!u„G­¹}ğDÁ‹MM3â•AaAı0‘”G}3‡½İõLÒo-¼/¤ÓÉb}sï,kãØê‰e?ãVjÔ„n–ùu­:Üã?›w®´èêíóÖ/$&şKË
2’´B!«ÂõÃ‚ ¤íÔá	("¬†Øqe¼7_õ.;\’s	ˆƒÿµ„Õë²BÏ»Õ ‹áÚÊÑ°0$ÀBà™ı âóÏôwMÏr7
Y6s‡ïK[(<*%©ˆÎ³ÏiçrÎJÕoØƒ®ÎC+ğÃ”¤Èë-fÂÓ™ PğíLÌ9UpLhêÊ­gŞıI ì€ı'¼ëRq Q‰>™7Zø¥QÏƒ5N t¥emëêWı’6ÑÇÛVm—ôƒ5„ÊÀEïRÙ°;²-ôqìİ'_º	!ş.Õ,°.çÚ½Nh‰ÄÁÇ'D‚$chi»¤³p§ìèeÊpÇ˜cH(ˆ×” s³Çi~ªpšÕ®…GĞÚY8şT¿Ç¤I‚æ~CêTµ4ıÓp&ğâÈ„Ó‘¡½Ó¤Y£4)™sz¹™‘fœ>
	>êu¨`ZıÕ6D·L 'ÂÓÄ:Òš† Áq	+§¿:5‹7'E>RÑ;/üƒµç›ğ¦G÷§:şÕz•1ïğ*ºù™Ù/Ê|]İOWÓu\±A–ÚëiøË9’¼&èõ‡ÒEc{‚ty«ö‰ªs‰p(3ü/45\(52àNò9ı$œ¶¨dã¶JL&aÑ/ö©Q¬1ºAÔÂt.!éƒ&(ÌRM`^‚‚hüÌ]Òš¢ä‰øgYÕïkS«ñ$²k/sç3ÀºÙ Œí?edº0URJ¡Æ@<”@­7È|Š9´úÕ©sô…»GGèé&å‹ÎZğ²Ü(¡Ê7¶ÆœXÄvCYíw üNŒ„M[êÊmÙc¼RÜEÕ=„YslÄßî½¤I¨§Yş!ø½’Çˆ¦’¶=D{¼€ZJšó*JÎ ül×›i¦Ò¤Ò¸ÂöKñg´L o±béõH®t|‡,“å&íÔÅ¶!İ¯Ğÿ‘H$ÑŒï¾	Xn‰gBI–àÈ¼Ê<Š¾ ™òOwÑ!+³t&ÓéÚeñA²×ÆšMß×[ô±ÇıO~g±èÂ-ÖòÃévs×ùƒi]nôÎA£İÅsjıÛ‘ÿ‹ÈĞûBÂék`”B8¿f¼/J6W¦#iŠ¦ü&jşmåSêT6º>û-djIÅÁæ!M•^:Á‡ŞÕ¾—R,œ®]'lÇŸƒv¹A4È€èY›ÿĞú•„N;`÷02ñnCºdá5ø ¨ş&¹ÔV±/xÏz­•5â²cEíÍ ZŒPºFNgšm¦U+Vï$ax@Ø)(‹N×PbmšÆ»ô€Ø@¨;Û=ğƒ	;"×`ë7ø\ùÓ`¦‚~»I#Düên„–yU/¯FOLA„2S2i0Éñ¯¦ƒ(+¹	ŞÆd4tj\C¡~y•Í_xÊ‘àO²cò­•òŞİ?na´•+â®×¦¬ã¤»%>IQœ®Uş”Ï7­1[µ‡¸¼ò›OŠŒ-†9	©ç-çøvHÜQXĞbbiÙ¦¾I-rĞQŸkÿÉ,Îd‘€ÕıõzåˆLÖ²ğI(j«Èµ©Qîû$º¢Òp³EáİIqâÇÑzKÎ¥¦¶š›Ö7=¼ÛûW {B &ãÁœí2W®XÙêŸKÌjf4cˆ¿ây Üä{TPb‹TÈh1qá¦§tè]ûü2gÛç ¯šZ8Â?„¤8¿˜jXOáÆƒÓQ¼ÖÎ:aÍqı$’»×š¾»¿9úØôQï&›î‡
ÒÚ°û>@éük„Õ ìYšƒÖ_Ú›Œ¾ËÏÎ²B+CHŠ‰ø<¾<ÌäxìÅŒ‹îÜ`°)®¿óõO1÷©êo8LMëbŒ„f”êÎRhõûµèïƒpUj·Øšùô-¿»±Éñ«-¦ñ9- GúARG,»³ç@f}V}SœOqİéXUà†è:ú·ƒş;Ò¡?/;¬ò	„ºg!ÑeõZE•ªhrß‚)ÀïF€`Ñm0ü@ qö‚DÇ¼ÓhªêZÇÁÈKDeFmİŞhwS?Í&¹ª?İmaj[‚¹mÔ™«–'âô9W¨ˆ“Òï€)æUÁ“§éQWï÷¤'?PSJÉ†ÍáV®O+¶/clüRÏlçgO?Ğ‘_—óKÊ°£–9w– %>G…´ 4\ğq];ã´ø¥Ÿ£6à…†‘›ÇKØ'µ6˜XIÒg¢òù3!•sÿ—ƒ|“mL]J‚­H(‰H´—…Œ°Å§ßME‡Bß6S°ò(ÌM}Y%ªd”tMOfÑÌK´Ñ…şíMªÅ‘(…À„~‹:}¯ ¡ˆo_ú½ûÆîHgndšËBõëC$¤’>hèY©¦.ët£\ö)ºB‘ØK¿äÒêgl€>ã˜ˆÊ¯“6—èøœ±l
œĞñb‹/Üğâ˜­K®øí´Œuë6ó
ü@'?3fR*…=Ëªª?1ÅòlŠ±`1Ğ !‡„­:½›èê|8¦
Lé/ß%]UÙèêúéğ~N,•"q9)nsp»ÇZ·ã§ùL¯ÄV•;i‘v×é¼vß3ŞgÃ¬+|neñ`Írq›/„%#Ë-1 x˜–ÓWûÍ‡øŠtr‰gîx­šnÈ|â6AÎÖôr?¦Âa4Ñ;t\…~ÉâËÏµ™	è|ºÑì)÷Œ8Bdÿ„]'³ı§€v&Y,pş-êš87Ÿ/Á±'¹zvÈkéJ{úyÉÔº$íÇš$)˜ ‰fÇS÷\[-bÚu\¤ŠE}A:ŠxûUdLÏŸS=Ñ	­$öfè”â^¿bx8ÿgÂ¥BmK+H„¥îá&hhü¼¨ÌŞ=ºP©£”d¤ıŠÉÙ×¾Íã,tØ¹ËatÎŠi
ÄU'?D{oÚ…ïß^ õG Áıçˆ1ÑæIÉf&ÉîÍĞ7}¨)g^¬š„À‰¦6É·úÕ
u7ÃK8#_‡Ã?Å	x\ğeP/Ë†Z‚ WIU•¹G§r“«ÎŠ¹´ÿ„w@Mg’‹Àô¸Tœµî4s·¦ÿú,ãÀD®K'­Ñ`½2EKW{ªJ‰Ä‰¨€Ş¡d±×3aŞ,µ]¨ö}Ò™}Èr´ÿº)m*qÜ’.Úb˜­qĞè®±Î»dæQÏ½Úß&ç .bÿÁä*`‚²ä”ác&Øgà‹Turo—ªšÃÔ3Ğ©65Wzî¹3ÿ´¼@­1„~'O5Ù U˜/]e9ÏXåpÆš‡Vå]ëb?—uSñ|ÑE-Cs­íÓ¼kLµı5Ä "
ír£0aSç^e<>öN+	Ä¡¿;š %r‡Q‹÷ˆÂpœg
nÆ	•¾áªzüÂäêÿ ›‚›áôúğĞ•‚Ö‡"Ìi+Ë\Î×…¼:ÍtlŸÎİS„d£ìî­ˆ·Z`VY 	],+Káév_^N$ë°|Wµ« D*È‚¹1‡X£“IB·¾£#0íhãU]w‹OfuÊ,à
¾ßID¸ Ç±tâ¬—"Q-#S`mF»	Ap… gß‡ê¼GY•Ó[ ˆU>mRé3:tC‹!’"ğ‘üŒöÏõi‚sNE«{E5v+éìIi±°<BrÑk‹
6M"³êş*BÙF=Mé"ZÉXè¢b67˜«:X®»®O3²Åè0b¤Püõ”›³ğv7E·~üGõ_¤X^Û¾gB2—bãšÈJ#§iœ7"‡dZfdçeJ¶Ó:™×$â¹µy WÿÓ£6GSä;ò³EÃnE OüU°&°D|	:Å„$°ª™vëE*¢¶µr÷à?G½f#°yU6¥Ó¦\#nÚeğ[±È>CR=?×a·¦K §ZkEŸYqä
n Ñ$Ôbô,ú%Ì=ZÅ~?],
{!œ)Òu:ÊÇ¬C?ÂÂü—Í<9hùmø\É!H +C‰} ª©Ã—,Á(gqËÖĞ]¿%\ãq)yæ}oÌÏe”B7ßÙnÌ¶†jñå¯šxÒÂ§Š-SÇ áˆÿ|\mqEÈ‚!5c°4k¿h†mÆWMÍHò…¸TĞÆB®‡JõÈ,tÕ™¹\n´_y€Ø³nö<ã•„•1&ìêñ¿Ú~<n‹BÎë~D´b5Á<äTuÏ;7<¸ùfP'Rˆ2ı¤UËÌ‡Ô¥³wúè}[ö»;Á+çHS0·t§¨ ´ãwa—•×â=FaÄŞ|NK×%%;¦ 4|`ÇX¦Š>ïó›¸Cæ:ØãíèÜ¯fçN_WSMŠwÅ“=„³#F]ãgœ¤¢]6¿_ÉeÓÇfG-%O›µ9"	ûTT0Ú“€nÕÜ8i¡n%ä¸°¬„?O4Ã,ÿá‹e°qáJ>º@@«	ÓŸÈ„Õ#Š•&ı'
Ïu¿	¹éGÄÛ=xL¾ášÍ “¾}É­EûÃàPl’ı\PŞ¯ØÃ+”ßøINÁéÎ(KÙˆfèßÿe$ïªHÌ¶¤&ÆÓÌ»Ô™éµGïuUTÙ‡ÂM½d¸Ã™‡Å­Ö¹Ÿ¥ÆØa2GA&À(¤ &<,¯ò=¢€òr	ßîÍybgs'‡XËÛsÖUYÓ9'my®ˆæâõß~ó–÷ëë¤ZÓ¾‘ª›ËW° Zr2•öü°`v^ 0·WƒKÃ
ü4ZÏÇ„Æ\Ì›áÜ™/gş ñ˜•%[¢ĞD$eEÖ˜ÈZHÿbA$˜“;ãçËÈkÒ:l+ï–s½<ğLIv’€â³ _—”æÃê=‘NÆN0›»È~o)×‰QõT:’»i'r[ºëêßn—œlõPó'­ù’"r -˜d®Z$æ±`Ü+Ä2nuùAj¦a›sîmIf?©ÕA'¦À#ŠÎw!´å.ş×—y~W9 Ë‡ãkWãƒÍ6LÊ*š
òTè¼ú•¡ê¿±{† Ê—©©iSÎf¡~/¢úŞÄÿßøäü¯yW¦;¾*u¦&7„ğK´O,µh³Mµß™'°«©pÕmhsµî·ı=fX[ÊAÈÓö­¼¥?H,Ö”÷ıÇ¢LLâßœTğ+şN 7ÆÁ’F“õ»(5|+Ë¢n68¼×Ä¦dÅùÅcNÄhñÕÇ2/˜³3Ô˜¥ìˆH3ƒ…°ÿ!­ àºÆ:ÿÇ‘Ên›-¥ùv:“g„LOŒÎĞ~ßs©Ï®Ì¤WGL×“$Ÿ¶ïÉ“Ùªì´5LéˆáM?‘=—Z8+|Õ(…¡ihH:òšÃçà+ı÷ëÁ—KnÔZ^¥Œ[s®ù]g÷=Ê¤:ıOó
„TBÅ¸Ë.!0L²DôÿÆÊ-ñäVwÃ 'ˆ«zí”İ÷p‡ıÀ·àİ‰&û £G./´c-›z~ıá]AšõEêbÑò¯øÆÁˆ¡ }xábe×³İ’U¡%ä§Íiˆô0
KnbKB¿Š¦,ü)z-¸CÒh0¸&m[+ÎzXåƒHĞ:U@x»Æh\¯T_¾àêW(Ãı\Şä:‡±½Sˆ‡‰*BËÚÒëôKxX•&3dîupf!C£Ø³àen7®âÊ„¥†unĞº¦îMT:»Íû‹ço¾‰*h©xG–zpG6A¼÷ş—Cú{xïVa‡ßàÈı‰Æ&7N—®“mKtíF÷ªëğ@MUcës3‚æs»æ¬IèRP.vB ³¶“‘¨Êœğãª__µİ)¥ãÚ23ÕIPşQ<Yö}×Â’vœ¬|›fºAÖ7¥#Pà-kŸ‰bC%ä²5äĞÜå•ôa´BÖ4ašQmèğ¿;Uh(E Ü@nD¡6kc5èoN8ªPÁğ5ÇqM²âïËË‘d€gõxö‰¶^êCÖ)Û(Ø˜M7}6Ê<¤àù_ÉBëF#eàÜE8ƒxcúiäN@¯J^NP
‹õ·•Œ¬Æ?Áš ÃÜéŞ“‰ 5§F,>%›9LüÉöGá¾‹V®ÅšwÛ’¼ÓÓáøĞ,:íŠ4g½›ı<"~º&áØ©Ğ(W˜X9Ë×K„lÓOş Õ)`ğßAyÈ²ebì(æs+ëNIÖ¶¹Uå9£‚#Š²Ä¡è¶<ÔŠ½´V:–“²ƒ¾m…e4òé1‚"9ÎÁ_wv ™vŸõó,Äˆ¡‚*co­qR8¿ªcî4'ä+™)FğcİøJšÏ•–j™ÓSÔÙı0-ú*²dûiÊ¢W®@²{Ğ¸X#ëFşÀ¨¹J2º¯g¨tV	;gÎÔE¡=‘ÉÕHÆ¹‰Šp*GAùÁ ¸óŒ{tó6ß,[™‡…š®,Ø‚ÓMD|yXŠ+S¶Bb†5ÉkJùBråª`|{B†:dGNMâÿç_¦Ov¯/35¥AÖ d'¯×Ïş‹mSÿo5ı³¥ÒI5¼#÷âÅ-U+‹ï…ëÇÌuÇ’ÇÊ^‡ùa4kbZæ¶b,.d‘@ùªw?ºDw0ïfw/æ«ƒÑÖ‹0¥ËÚú…y1oƒ™3ÿ* ×`µeÚQà¨úIİÖ)şü¤[d7^@²0š£ªÈŠ«ÍŠÿX~áÀ(7]Vä—˜\#‡Ì·ªR¿UèIÌ‘Nßaı­ÿ¾ª’ßş¨mÿ­¤ÃŠ4œö>xx°¸ıHƒc¹•=_öµöŒ0ÆÜÚ?‘¸^åš•7“„ _k«÷Ö‰–;3Ys7£L)ØÚ…Ò	Â!‹r5ÉEÕ'–Tã‰|’ƒ™0c$ÉßÑ¸H”Lf“~¹m…İÛÎM¤Ã?Ïë•Ìf[íaš íB.vs2pGæHKlK6ŸZŞhÚÜ‰¸êğBË)Î¿€¢/³Í§€Ñ²Áç0Nugá®í„[}gç±İKq1|íù„_h8òWÇ¸z½`0%0ÿ`7˜q£J‰¾Ã²°zÖç"İI=òd¢ŞÓ~bÅX¢	gF³m˜Ğ(ÕÜ0½‰™ÎúÛc™QŒä  Ë}:a/›$ Øº€À"dXk±Ägû    YZ