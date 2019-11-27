#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2286902667"
MD5="ced00b3d49e61bbfcd3afe8c79688270"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21238"
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
	echo Uncompressed size: 132 KB
	echo Compression: gzip
	echo Date of packaging: Tue Nov 26 22:48:37 -03 2019
	echo Built with Makeself version 2.4.0 on 
	echo Build command was: "/usr/bin/makeself \\
    \"--quiet\" \\
    \"--gzip\" \\
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
	echo COMPRESS=gzip
	echo filesizes=\"$filesizes\"
	echo CRCsum=\"$CRCsum\"
	echo MD5sum=\"$MD5\"
	echo OLDUSIZE=132
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | UnTAR t
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | tar "$arg1" - "$@"
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
	MS_Printf "About to extract 132 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 132; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (132 KB)" >&2
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
    if MS_dd_Progress "$0" $offset $s | eval "gzip -cd" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
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
‹ õÕİ]ì<ívÛ6²ù+>J©ÇqZŠ–í8­]v¯"ËêéJr’n’£C‰Ì˜"¹)ÛõzßeÏı±°»3 ?@Š²´Éîİı°D`0æ ëú£ÏşÙ€Ï³§Oñ»ñìé†ü|5¶î<Ûzºùlà›Û›ÈÓG_à±Ğyd™®{}Ü}ıÿG?uİ1ç—£¹éš3üKö{kûiaÿ7w¶6‘¯ûÿÙ?Õoô±íêc“+UísªJõÌµ4`¶eZ”L©EÓ!ğóÄ=rxŒyäqÓ™›ØBƒu¥Úò¢€Ñ]2˜ØÔPÒòæ~]Jõ%"òÜ]²Qßªo)Õ}±Kzã©¾¹ÑøZ(›¶"ÔğœU–v•ØŒøfoJBèxÅßÇÍ“W0=ª“á9€	48À$—éû4 S/ *á:¤Ù.ˆ’Sgçêá¤B¯|hßo??;46’Çfÿp`¨µ'jÒ€‹öGÓÁ°y|l,‘,h.‚·ºı¶¡¦ígƒö¨wÔ~İnesµO‡íşhØµ_w†Ysf=o^*ÊUŠ¡F@Ãğl ÀJõõv@'¡\ùÛPÅ’7Dƒ}«õ^íëµâZTònwÎU*åäã0˜ßatDmcUÇMîùÛœ|rK”©­¬fq-7¸„p…Tƒ0 ùÖL¼ùÜs5vNùÖ((Æáæî¶E™MC:÷l‡²Çë7D©$¼ÒÃ¹¯ç¡ëÏ¯U$˜¯ÙƒUİÂ„­s:¹ €±ûŞbÏ"Ë#s:Ãæ(àŒÑ ÃĞ(•‰†}x‘OşJfõÅ°ø·Àö3Ñ-ºĞİÈqbªk"ßd#ÙMXLeYìJEPÇç>pÌãÓºô²$ ÓÑù@áçíZFmvxrî¡n¨	-j-QË)*'(¦‘µq«İà—®§hõ[Rğ9°˜„eñ`‡0c6ü«'”7]YÆwŞA2Ÿ¦(3>ujìóe2œA™&T–Õ°–ş&Ú•šÎÖÜ¼ÎQ|»[tjFN¸® H3ÛaŞ©ÙDÂ§–(eíIªT²Î×ş´rÖçØ Gv(f„ç;äsúôŠNud¿3è75jñòºy6|Ñíw†Ğ–ı&ŸNŸà*©å,[‘½\˜ü€2T#‚İ%ôÊI½^W÷jZ)‡_%®"r'è„´¸~\1_i,¥¨#\$W(©RÉ$!ƒLM
ÄJÜËæ¦°’n+oŒ‰›¶›Rªà'«ÃPÏûÜ§RÉ41X5è|ŸDš(s"Ïo•?f0™QrÂY©È&ÀÉ‡åğ­¨IK}ı¬ÿÁ‡¶;#ˆƒCjÕÃ«ğ3Äÿ;ÛÛ+ó¿ÍÍg…øëÙ³í¯ñÿ—ø¼ğ.Ñ&EŒælÒ®Ri®h3¡ÉÊ¯(•¡Gâø‘ı6Œ]L×‚ñ•|j)D¾1:À¿:IÀK¡¿*æÓÿ:*@8úŒÜ¿'ÿolnnô»Ñøªÿÿ™ùµJ†/:rĞ9nø†¨­{Òv0bû•´º§Ã³~{ŸŒ¯óQŒô"27¯¹À‹xQaÍ£°àú{2†gÓ…LbŸ€Ì=ËÚ“@0Ãø¸1%ÇÂz¾,°œßûfÀDT'+Å‚ğÈ¯‘«Tå!q„O4MŒ¶¨cÏmL&w®só‚2êL‰Ì"$‘iàÍÁ€ k:12Ñ1î’ó0ôÙ®®'Ãê¶§™¢‚’Õä¬æ­öVƒ|†ˆ•#Ë¯|Óe<¢=7&0^E™ÚƒÍ™L"éPàL¼ÕÃ~à½éó:‹¦ä­~Ø}µÊ_Òşó’Ã¿Yı¿Ñxöµşÿ%÷‚…WmÙEƒ:;ÿ‚ñ?löö’ÿßÚøêÿ¿Öÿ?±şßĞ7·VÕÿ‹‚şÀ3€\0ñÜĞ„Ô‡pdø¶ƒùw@fÔ¥;H !Ší‚_Ä£‚fÿdñŒè¤Ùì·^ìlk¤éZg[_È±+U‹†tš£à|øX™ú“83-“¸éµÖM,Ë->ü=°Í…My±Òœm,x)<@:èµ°î\Q*7Á=´Y8šŒÚã´l3ÑºKÃu,3,ä§pÀz^X}¢#7ŒHã‡ºú Ó
&–?G.½E`ä„Œ—]÷öø°cÛ®È	ÄP¤ñãÃGRfN””œFFÆV}£¾‘ÇsÖ?ÁB5‰ÈØÂ­O
‘D1NİfØ¤õĞœ1= Ä£­ÑÆhC•0–Ñqçù¨×¾0T=bîØcÈ¡ªXëà0CˆÆI«O¦³"Ê~û¸İ´õÎ‰_¶ûƒN÷Ôˆ—ø ²ôš4RÍ¸(¶ÿ@.m?hIÛw.	z±;=I–qõÃÎ4ÍAAÑfn´´®´À_åâ CPš¹ò¢fXéñâ«Ã¹)*Ã‚?¸èRò:ö=ñÆ=3ÃÿÂ €Ã¢2$š ø‚0{>şğOÇx|î
Á“-Èã=S›Ç%»{ñËƒ?^’r	¿W±W,à¦Š×ÆÿJº+a:9Bui¿nƒÙ¹<·'çÈíù¨Š&c[+åj-7H%QÕå³“rÌEj«¦zØ\[¢Ãõ‹"½RåozÀ=UÈwi…„Ÿ^(Ëpx‚„G(àdqºaÿìôˆ¤†|ˆ£°ØŸc-’m³¾¡Á5¨)Øh®v³Ôöí[íÉmu|ƒı¹Ó‹L·;§g¯G/º'm.ìÜ„è–Ç	óàåé°yxËcÉŒ·uy¯ê õÙojÉêRA,>•Ë›å…Ş–`Ã£X®KñA¨DTÅAO	ë–šò$g¡¶¼$4öñá•Õ£ š‹È‹ ¡˜ğpEyM-ŒsšÁ\œò›îŒfçöK»EJ %ë®T°¶A&`áÑûŠœËÉüGR[&­ŞÙhØì¶‡†	°Ûªf!. ±}¬’î íiõ»ƒ lù õòY“h­éËƒŞË-•$Â×ë·:¯Ü™ŠàB•/7f W
e·¤*RÉî$HâØ=ë·Ú‚£’†9°bˆ^+
6?‰AÈ‡ßl?a‰Úë	YI÷Ş÷'W;ÜG–§s[#o@°€i/º·&à"í ğ‚]r h™´ÿš¬>µ›Ónÿ¤y|«aµl¸b«T²ÄÁWÓcÓZ©ö«Z ÓÔ~»ZLWBU’õeì_’Ïì+ /«àrfµz Ğ
6ˆp$*	Øe]h“óíR}xˆ!+Ùni· &Ÿ¿DòóÚñâ`IÚË¨»K VŞÏx€<MJ’ñè1G3ÁR2±ÂM¹—ŸÛ&|,—ª·}Hò=[‡‹È‘œì¹ y±ı šãÛØ&rÇl"*ÈÊ-lÁÌa[<÷¼p¦Ï•-¹@ÈğBƒ=‹„Tâö–Ô&]u98nºh4›§ûıngËQáÎƒŒSñ$dÍÍ–¨¾Djxâìj—ÀÛ?…œœç%3BRúrŞ–ÄVåË#	±»zY6®TÅ¤gN.Ìw¿}Ğ<;Â7Jmë(IØm×¢WüÒK’ÚŞÔxß»Û^k. L8üµÊşo_ÿå×Œ˜¸	Â4jÙàÊş°2ğİõßíåúÿÓÆ×ûßÿë¿s,ıj¦37ÿÀú/I/€kñyc‰Ä?°Ü§Ì÷\fÊk»!ôæ.6êâ1ñ:qY	¯«Õë_†Û%Å†ßm<sƒhJ5®d™ü®%]PÇóùAû7
éw»ÃögNğÄk‰KìÉÁÅü0ÍÏpŸÀG§ÃùıL¼ô(¢–ze^E`Z	˜2xkr”Pßc¸Ë6Ş£œÎ2JNÉİóãJò•üÌ÷ÏGĞR×±iî?½3‹.87	ñÛ§dmpö|ğë`Ø>15bcõ{Òû7¶õ’º–ÜBóO/Û§ûİşÏĞwÒİoêÆÎÎ<ö»g=CõhxÕ·î!…RQŒğs¡øYúÓ†SZçMH£Á¯á" 	x3Š'Åx¬Ê5„biÓşÙ58óÿëŒI–‚’»¢’ª,~reDÎxóÕ7¢Y¬õÍğÜX]°Ô¼<B@TårRº$IÄò V>²EÕ8]<Œ`ëG iÆc¤I­v`í$ÖUnƒBjÑ”¦(Écœ§ˆ§×Vòb¿y\Œw“šc[‹»œZª´ºk]è¾c†`®æL¡µèd²x·IŒ	{4ÇğÛrêÌãqã~wèyäÂïèåDm×Ôı€¢
uÑ-ªqY¬RYÓ¢üÖÀŸ…0òz&ˆñË×>z„şäÆ¡³&v	”®s ~¯+JV/ˆ"‰m!©‚fáq0"É‰°•
ãºql»Ôvñ"s&g’½ÙxÇ­D¼ğ”+îFIÏ@jrf}ìˆ‚LLp±BsAqaÃğÜ5¾73=¶ÄÁC’×Bâ7®¦$ô©D•¨S	I‹õqµºiY `=Ğ9z½ÀCçÇMˆX€/ZâcÃ¢åÆ $˜(òb“¨ÅÌØ(â©}ÆZRåµ]ü»[;ì7÷Û9ˆÜğ«ã‚Í!&ùKDŸ;¦{;‘¼3 ‘O >|„ ğ¢ 0P–w[­É,P¥çt)ñ»,…¥óİ–ö:×+^]!Å<?y[%öÆH§Q“ŸÀ‹ıLÈÊ}È£‘¸iÈ¬åHîÁQ¶;2!hP´Ô ¬}"Æâ~ß‰†ù$9#—ÑT
[˜WÚàEyf‚®9¶šø2ÇzH—;Nñ{RF(&ŒbÜ¿Ægî"0à ßÃàÇŒ^q1Jµ¥yo&ı‹ÌÀöˆ*¸¦…7ñ"’¿ÔHÃÊÌº"*™İK—MÇI#=q4ê¹Îu|}[C‰ôU€XY1ÈÁÆ\º±ãÕ©‘(O!»Ğˆk*ñØ1‹]ÆÜ³ ,¹´3ƒØÛ‰ÕvöcÃãŸ›ı³¾äñü¸-ŒqRHYIE:UŒ3gÍ¤iJu¿¬7Õó²Îx-+z9‘¢2¬ŞË£Â`Ïy9|ı1Z\¡›—`Ä	‰HÕãİ|/	  OyüØ66öìŸj7U‰9o¼»İ³¿ûnÈ~âĞ ô’Áìw·r€Å%!ÜÍ~­¿<6®¸ƒØS,k]vˆ7rg\"Ów	Ş˜½YG4J.ıMì¬9rûèRÕ¢ÜÁ›[1)W 4äÔCqÉGèezºä•µòÓµãN½]ÜSU”k1Ú-–nÓ~réÌ7'4fî«nÿh áp;ƒ‹ë±­l®˜u!fLúOóı`ÎŞº‡àåš³\g÷x$emF­Ğ &>f+–xgŒ1íÏ?s=‡İîñ ƒZjâ€§ûÒ©ôÀ;åË 5iSc
!mŒl4rˆb1Îz½nhÜ!JªØI.›šÄİÚcüZ‡Œ_¡iÈT,ÌçŞ½±Rãëb	SÓ»
§İaçà×Ñ ÂMqƒà›Â‚"±·îò%:3á"»¤L¼Şº«e+ë{ \ÁœİÃİûy‘Úğ8#ş=ËÉÙKqÕ<úW,î­Ë_¾›ÍcˆI¶,Ì&çÔFÍØzü¼h+–\îp%ºéûNúŞCV'ü@_Pë=Â¾ÁF¢”s|ï»e@ÆÂB–/å<tbá”HñÜSİõVZwyğh1oÎn[”]„Ï#ìÌ€¿ÙÍ¤/¼¹‹zjÎ©‘m‰ššz{Rì"|Dµ}E'¹£7ĞB‘»iHğÜ®5‘Qi<1)÷ñ|òUåğ.cÛI	êLĞeåá`"X½nCãQT±‘`@W‡F>nHƒ¹íš15AÃDÓµOf¶o1Z )3;RpfÛ[††syÄáğhïğ¬¼¶gÀÅ=a÷qM‘ÿê¤å˜ŒÙ}ÛÉÉ
éU¨_iâáŠŒõŞƒkâŸ(”÷Ù.V:Y9 lÎ·´‘©ÒF,o\ä{&EaRÇ¼«<¢×`k,fˆÚò^O¬9tP?‚ÃÚÜÙË3édË>dš×»»¯µ£ı¶v
KYĞöUHù{7ï²ıûïAˆ!oxi:5êÀ4şøZwk5|Ë¨Õö=|MÚHtâßV³ÕnktÒ>=u†í“$á/Õ)ÌsÏ!d'ß]‘²qĞí—vÀ4ès¸öÛƒ£a·ÇÏÓA
H‡7±MQ½è4}/êœ:~}æzsÊï–šÈµÎ®YHçĞf‘mQÔ±#,„«`—"çZI|ı<œ;u44)m™:	›n.b¨_Í²Dq¶Äg‡_&–	y ŠthÌælôGØßdvğŒ{^¿„TTœ¤î sÚá‰RvOø}#QI FYXÖä!ú4 ˆ”(™Òö<Š{)J÷k”w·†z¿KV—<FÑP¦ş,*P“kûˆj™ÙË,JÊ¢r¯–‡Y&1u`%È†½7f¹2ãqv-öıb®c§V»éöÚ§¿@ôÏo50î{ëB3çÄ¤äãÙ[?ì¨ë¹ù¹ƒRÕ¤-4ç$Š9ÒŞüä€Uè}œĞ1%‚™î9/ø/(X:’Œ7İP äÉAZ©dí7ÉÏouøõ0'i*±±ˆµ_?áÀRÈOÉú:©’cóÃ?<Qâ ÉÿŸJ@²¹s	lí&O}!ƒÍV]ˆ cĞ’‹=9qÅ[‚ü:'÷ˆ2‰àß<E“"SzÙÎJs,“½W©Æ¬Ìøà/@0şÿô˜÷Q’’ÿ(~dš„Vìs¸´pÿ‚y_Ê!©3O±?/Ãò0¬ >_TK„@ê!¶±”—öÄùÕü:0ä3:€kk‚y[Øá5†%"?Œ'f3áÒÜ-–p@Cc3N¤ÃøŠ‚g©ãÊIv/>@16’üÊÎ	ø~ğ©ãh–ä«ÆSi5duâŞçNqW(XtÅÅimí£«ÉPu©Œ)ş=P<C!üL…wMº7€Ç#êŠ+ÇµBgJ-\<üÎĞ™¼Åw•Wfİhë ‡`-s*©–G?+ãp¢–°F•|¹Aî’p.pZ5"±jÜñ¨ÉuòeÂ$ó&^¹)+‘ewd•ÊrRŠQW7
úuu-şCÔæÔ0>[ú§Z(Ÿ‚&Üú›^gÑÿ¶÷mİmÙšç•øeI“)ùÉt·lÑ:º-RJÒmeqA$$#&	 ”¬8ÿ2OgÍÃ¼t¯y8ó˜ü±Ù{×U@¤Ù3C®e‹êºë¶k_¾}.•p¨‡†¯úIŠ¶UYM¼`Èª{ú5Æ?e™j¢dxœßşÏ0ù„~5ï<]m­4f4)•|Eiîà¸’	G uxÙ’~ûŸìÊû9ğHO†œ‚c­T¼³•‚•½AĞ‡›ªB¼ø¯‘Ö*¥D“\R:A"³ë yÇ€ÊnjÔ\q•ŞVßAaÑu~@™Pç;B’zaoŒµ \ÅPÀQçd¡ü—A"™ÆjõrÃ35xÁÛ+sÚÙgeªØ÷Ê7Gİ“-ª…+¸mÅ`ÚÛÃU8\x„ƒcáÖsÄÁLõ[Ø'[Î”*;³²ÚºQ­NÇè|cPeNZ£ëæ*§"LR±6Êèn©¿sJª+õ³·XõÙõÁJ.Ñ¼œØkNe9ÿ
µ›GÂhõ7ƒ€CÊfTå¡BQº:ÆœÊU“u4¢¢ĞVŒŞãEì4U‹ÈB7#™q£¶QkˆspM¢µ&Õƒl³”ä|¤Lã"¥—A5ºÈ'2øÆ´0­y¸é¢ÅHN6é÷’ÑDÉ…tÍğü'Ø«á´èüË0Æ¿ÃAÄKğ>%ñ÷UÜkÉà‚é¯éD|Çëe3÷ñ+ìÜ¨Õ4¹Ü…4üô_ÍÇ\ßÏÿÿ)òÅo”âôášd~Ö¢ø'ş­ãÅ7tiÓ¾¦iTq°´âDûª’B^õä=/!ê‹–ñ—“!,˜ËÚ$á?Ğ”Cüˆ¼óŞU?öè»/»ıû(ÿN°,ºöŞÇŸâp,RË{¨}•Ş{O6¢|Eùÿ
½Á€¾ƒÊŸBYM˜³âÛOÄ„Ğ7ùrš¨/¢øÉĞÇz;×õF¿Mş„şNÓ‘øF³„Eü„€Ë:ïş$	'â,öÆëc£M
œ)QŒ«û*ı&’&b@R<Úij!yq>i_E–”ğ×şy0ÉÑXxÆÏ-½”Åm¹™ÃMbÒ¬0ŠQ—>/å¯Èi–l3:Si1r!1°/%ÇIí38#·›µÄCÜı‹m²yu	Ê:/çJ}aÄ™¼œ™æ¸E•ÎÊgu•°;õ;ÕwIW²êf­qF£ 5~áîEügk½(¿t›
…Ù…ê–#³
ù”5éèSáp ¹	Tê¤×–Ğ©Œ®à\"2 ~âôãY]„’Å¶Oˆ›H9˜)á´÷Äõ]F€å¹Áèi³Ïí6ˆÙÚµTñïâ6Š«Ì‘F¥Ê6Æ¦ëÉ¨‰dŒ[ìò{z!f«$+y1|=mJM¢µrçÄçöü1Ñ¾É|d÷ZVIS·gHŠf
Šå9¾ü</4€q+-©ñÀ1@|ÀM/\4ê…“$n¹À=ºé­N¬YUD6»¹Ó±È)ÔÊpñ@EÌú¿ZU¡™H6WM ;b` 44!bÄ/ºâù>>Öôğ~ØãÛDkÖµBÀ</&.Kí¹óÅg|ğµJJ†|Ï4…Bûè^—âæcÈFé49ŸÜÚËTÃÈ,¦àñì­gáôbCúÃ•_D¤…lÎï­mğm`Ÿ±vÜ£¹›o)//²0ù2p-rø;Ï«Ò;à(˜ÄO6ı¡YÌíFË(,a.Ë`eÆ\2·€íg†84l3À<Rx‚âÄ´Ã“ÃIr/r‰©Tì¬bJü`ht4ÃëLî|İöÉÉŞá›nqJÇÉ¹XßÅ/h/Œ?ñ—Ënœwæqt+R‚ÊéAş8±ewJùT«tÎV²/Ø/¹{7®ŸÕ+y¨˜zıï¿åaœÏºm/‘÷·¡½·r;²{Yœò>G¦Ë‘áq$fûİ»QÖÛ~OÅ}_£Î§º»2Ï7èn9¹Ğó
_!ç3ùG)·£Ì j6©úHÙ®`¿s¤ -³ÇjV§­í™ßéÿzÀ1<ÄÒ¯kºIÊ­]Åîæ)fq»w±ÅÄhmh`f’¡×¹y¡i³šóöòô“&ÚæÑ:³Hp»XäRîTÇp°hÄ/İ½³+¿·sJ7Ûş1R~Ò%6Ì"Æ¹kvÌ
óDâÂßşì¯nm1w:*Ğ~ßF(ÉóV€Ÿ!¢9`8q/Ë‘œ‡¤¶s¬Š^NÀ†¦9•W±…F«±VÈñÍÖ$\­ŸÜç{×Âxı˜¼ìêÑÚ‡ßµf à•Ê¦ÏÌ³E"Qİ¨Ä†Ög—	©"÷wñyg§ó·´`ytmUÒ·XM™¢ZJ¹¹¢ÕK ø«•‡k+™ÅÈ PTÌŠ±·`Ê‰éF.’.	zÓñ0Ÿ/¥ßÊE€>®¥şÃÉ¾¥·J4y’„Çı¨Ò5#mÀyAwMş.Ùhƒ)T²¥“¿¶·eETßwæ•&(m/¾!>¨èÈØ§/YÓúò—?­Xm†
V¡8ÆŒU¦›<gÄÍmŒ`^sy\ÎVVZëûã+ƒm_yşg´8–>jn£¶îÂ `“i¹§'¯«ÏÜ?¿ ^>ç‘ÿ(=o¯‚(£	şŸÄôÎßçû¼¶¯[ŒŸ¹õwáÈ¯ÌM]§Iñ¯ş¾pEYB„Hä{#_•U´g¥™Ÿ×-m¤WÏë¢/º¥[–Fbk´šxùiÁ!/˜‹0.^Ì¶Øœ40ø¶Ö‘¥|n`İ¬‡*L›x2„âÜCµ²*=»¨®‹áœĞÎgÜö	Jw aÓYŸÉ€<«¬Â¸|çGkniQ9¥rcv†™‚+k†|ÍÂ|—´:\¦
Ø(. àĞ &¤lŞ¶üX+?æ¾ÃÈœ¢AŒu<eØÈ•ÂI†í$íâŸë+gSjŠãzñú¨Mdçañ,˜x“£‘„}jš- ¢tÉı%¿'˜Å6¨Ø…“?ß
 ú»IN“ôsQ¾ù üÆg¡<²²5kÈÙ/ÿ¯±ÑÜläâ5—ñ?–øoóğß®Rü·õZÃÄ³ ¿a¾ÆF#Éb»=`{<Ø˜ùDp.¸4D¬6
uw¾¡ÏCx©ğ|ù \–V¨æË`¼9å7ûG/wöÙw;=tjïòj_…Ã0B—O¥ú»vg·İª¬œùoÛÍÑŠ
~°ÓiïñWëğn#}×=}	ñ7;»øzS=>l¿éìˆ,4¹’UÕXŞõŒ2)Ù¦‘pçï§ûª€Íô9GšÍ„Ç;Ç'½ı£Wßv‘urëW·ÜLŞ_â‘€êµô©7AùbœÄæ«¾×çÓK¼‚ÀÔŒóYUÕ‹Æ×YsâwÀ]24°§Xhƒ7àÎ;ô—ñ¨Ô­•ßÆªps*÷4ï<6&gN-ó‘°MŒ}Tß“Û…öûPí<`#"Æôñ™“AN}Ä)ª‰iÊnØ4À[ÇcÀxÌlÙK7àXiœ¹lú±æşÀe_=oæ€À¸Ê/M9å*I^L1´
ewÁº®4°Û$ÊD7xĞätàî¬´š¨,–7zJ¦ÑÎuá¨~NÇF¬Áğıtrí@òPän„‚Ç­•Ã£ÃöŠ…f&ÉÜJ3ÿ†ÔƒvƒÙ)$Š ÍJsBÆJàš‘0T qy‘Õb]p{y@—D_I^KñÄéçûHğ²]ÆŒ“è*%)¡ÏT¿G3†2Í-“–°…ÁnÚZ­¬v‘{@ş¹‚TQq×`®‹WÜBİ†`¶P¡ô ïÑZ]³MÀ¯¾ÊQ¦¢²øÜS­¥ˆí*Z|*ÃôÀºä„V•V>Â×zı¬^gŸÖt¨{‘oûÄxQ ›\S*sşP(ô°Ç‚Û|ëUŞ©ş}½úõök&’ĞraZ‡Kÿó†XƒÓâğÑÌ¶*í€l]qûiP¶“"picî†CÃ ¼3Éb‹¬lºÇû{''íİŞN§³ó7,UŒe£J'»9èÚn(Y*¶Åt¦Jº'i­Jî0ãĞ§Âæpsx.7›LØ4	WèƒEŞNR9y/p.¬Qè ¢…JÉ;?§Sm*éwŞ´$½Arä´Ô©*£œYXÔRœ,¸—ao ÿ•ê”1)}e#à@14éÄ‹qÓ?¿AOwŸ"gB©´(ÚrĞµ)ÅÜÚHGO¸=a]­Jc[ıV+VTú”L¸î[•õTôh*–-XÃ‡K&µ\¬˜z)j !–±¾¶”!ßyø¤Ù`„ô$r¯Wá a¼>š™t‡§Èîè7›ÀbÒO² Æ³çBÜäèÜz}o;$'èæ%~ÓØ  >>ãpp¿ƒê¤b Ç¦©ÃL‰jä6'ÈÏ+à[)™åotë1_yùË`ø§@9:wÅ¶‚¼öŠ&EÌØM³2år™–ó@Z]öGéüÙøNİ·e›O€2Wzâ´ ŒÁN­tQ—c¨ÚûpÃ´ùCœ‘Ì¦3J˜uívÓ2UÇş¾‘QöLLÑÂ ıÜ‘“¼ĞíæšÜj³¬¨LdãH­²®¾/
hm¼n9ß~7¬0¥·º!èlZÆû–Şÿ¡¼m©E·s®ÕhŸ±:a˜Há°»ˆ-ôFÁqKhlcÏM$‚ÑÄ‡5C)T äM¼Mê›øÃ£ujXf"²Š¸Y]#Æ'÷ëPh•h:&_ŒlÎ>£à
†üÒÏÆm¸nÁú®Õj8…^|Õráÿtg¢]h ä!3¡“;N>ÖiFgÁüÒO´ÕÑÈÂ£)‡©à<÷1±.<vy6ÔWe\CRiÎŞgÕ*œçûÆ:b%à[VQi B§(T•-iaÑÎ	FÚAÓ¸±Ÿ@ÙÁŸÀ<İ<`'ÑC”Œèk¹·Òvş6ï¦#F‘æ”5NĞ &Fv¸{ˆØ::O¢°ïÇq?b´õÃE·Ø»ôG4=`fıö?phEƒÑ!'Ãw©—Óø&³O­ç"M:c8¶“s¼	’êÚ)q·b|ğvıGù~ÓUøúNDDÆœÒÀ¦s~¬ùü«+ûãŸ¢.4É‚â<ÄBéO'D•öLYÄb "f¶ï½ ¡ø	•÷P(•°Um*QtcO†©ÕÇgâõád®;
GÌƒE»¢ƒ†*bLÄä\­ŞÀä„×áuu:ö¦Ø¢]üÁZ6q–d¨^ª£ c9]*®‚qJ«‡ˆù±¨8»p´AÅ¶W>*‰S‚‡U\ÜÅ"ı-<*qÄDcy±½ş™o®ëúŠ›[û‰=ç–¬ìşı,<Õ$r IÂ¨„üÑ§eğ /ÿGÌ‰ûı¾@üŸÇO›Ùø?76–úŸeü÷;Çl‹ÿãê³|Á@?¯d¬w#”»(HühÁr4ó“/Ù½<‰|4P†sİœ}çHV¢#·[Ç¸9DÍ/ø=4jÙ1S¿Õ4é¥£¾%·JqÇ¸yäê2u?Gv40aÖÄ$A5¶²ªÑ…„ŠÉÜŞ$44úrxh‹B'×¬=r«|´'@å²MË1ÕZô$¼ºH¢”'¡ »;‡vG"®#·+0È‡ˆ&fYŠniU9[½>j¿Å#7WJ$,WˆELåÖ,¦åßÀ+~iêğó ™5˜—°rH£ªt%•Må9$­‡¶˜¸¦JHQ¼ |®
]M_İC)Í=»‹ägd£%ËâØ¤@6™Dæ|³W½sx2·^L3»R‘"/sVXÃnâ%Ó˜sØä=œnl·oİTY"õÃÿ'§]ÒÌ)y2	aXš!ßH_õŞœîñ/ŞHñõ¶¼iÁ°4+Pøª
yÊÉ/^4ò~öÇxõ!1ßoÿñÛÿ†U‡çŠGP8LİêøeÈ&áIE<I«µÊ*«¨ÕfU¸4ÖØš¾Ûe
¹õyÀ)@œºBŒ$C™[:¢U´jFUúôå@ŸŒ#}ªj&’+C‘Ø¬e
ªh2Á¤$B\ú&Ki\Éˆ “aÅRÄµÌ+¾ •¦6$#U´”ÇøÕ;¿ÿ¾Mb9¨&gRÜ7õ{5§KÌ¸ù÷ÎşI»s¸s²÷][ÅES»Ÿø[’Ì+,¯g1vÓŒ¨³×Z…Us_ëŞ:¢}aÇĞm:Á’u®ÂR´¦¸ci+yù"ŠIFx1ß…×4±$5ã·Q[¯­›Ä`s¨qØnïöNqwkãÉÔj¤AÀƒl×?<èûzıhâÿºû-e¼÷âé33ZÍ$Üî³*üŸ'·[éÛûxfÅ]Rø½Á1~¹¥…n–Í}&­›bŞBğˆMc:ìyŠFãŠÚL	ÔÎfB·*òÁşIWÒˆ{ rFSÆ¤““ÜÕĞ†c©Ç5´¶Iµ‰ùy¹·sØ{	 ÁôºhRê
3fÖÖ
jä#«ç°ŸbøC—¹¶Ú¤²vÄ–NÈ“jñjô9<ºE>YL“şym@qÍ{üko€ïP5
5¼KËê=”¢§ã€o¾ˆÖk½#ß!¢ïéX=çşÚ×‰á¼|Ófì<Æb/`ŠXõÛx¡›ÌÔÀ•­M}†ŠİBGàæ¾†¨Ş}o˜ÄY8ZqŠ8£ju2.}µ<¾®>„C…ÍOØh<¤ÓG,èØOşÚi?c$g¿ğ¦ÃÄÁG@Šg^¼ËŸ|!Jˆ@u^ò®‡£„jo¾ıïë[Dä¯))$™1¥˜Üü²’¢bÃY©J#Tn	‘- Ô®8àÒÎU	³šë íiÈÆ…J]a£¸µë€Ä4Ÿ6µ,w jœG­J€ÉÏÆİ$œLp›F[\O!ìÒ®@ZaÃ7¿î|·Ã}ºÜJšLÕ.
 3@ÛÎÅ0ö(Ô¦&VT)šMÕ¶Æ5k&5J¦,9–?‰ñc×Gİ!ŠâLÌ)Ë*MZ+uø—5ŞËè0ë¦øËt¯Şßùş`Sğ”ÙKu7˜!bÍLv¨ò!SS3YºÈ4³&x5¤F'²÷LbÀ)‘ğ…1óóø_†ı¡-Iæ@€<;GÉÛJRÒ6ñ“"M%ïâª›šWy–ŒàÜ0Ï“¨ªek—¿|ï_ˆA&Y½lk5[{¬¼İï…Ôì¿f-µ“f™—Ì6š=tÎV
	„4Ë"ÈÉfÏC±eÙøÇ6µ:*û{/»ò~D¨½o¸ÿqÊ	YbàÆ[X,Õ 'á DÔÿ‘ŸDaL^uÇü'pƒÚ†¡¾6ÌŞªü£GĞº¦._lH§İvÀ†¹¦ô¶Ô •¹q€z“b%£AU6Ëig¿¥ ‹›[ÃWî¢™bÏÆfi|•ÚÙAÕÂÌè#bÃşŞ«öa·İêuvÚÀxã¬Z}Ó®9{G…PÖ
-ü%ôòÒêUš.sXëÁÎáÎ›v§÷ê`W«ø-¬ø‚6á2ı±å4ÆıİÅõå¾J¶Àd;3‹nŠ9µÊ#«~¯p›Öêün#¥âòŠN»•Ô—MÌC|Êç{+EÑ6_Ç–÷œµ|ã'º€e0Ê‰/ºÜ˜	Jš	‚’— aKˆèò}ÜĞ@¢ÍìÑnUp(ö+n+ö~{§Û®×!˜Ü‰µ×hkj¯ Øü  œ{2K0¨â,¥µ::ZZÎìnšˆ&@U• 2ëLéféçš%º³è8³Ô{Ñ5›PR”P%Pn|iÎr†„ÿ¿ÎÌö[JH3~[…wRTg)Ãîpxjz~Ğ•)´ñJ.Ql¼ThËT<š»Tµu&&6Âdv;À‘~[ —`<Bğ…1Š`œH¿öˆ%P˜4'Ò	”©CN•Ï=ù"ïË<èMû„kú^#Ã!zˆÄğäµŒ‰¥İ.h/Z«nÜ£+ƒpˆ¾ Ã,^²Üá¬<U	¼êõxkFÖá°,M³0/˜Âö|ÎâYİ/"¶`´æ…SSûô8#²}±q0½!ÑÎÒq±êC4™‡8"œÇÂò+Õ{Í¬&;óŸöü<^hZÌ¾c”9äÄÓ§OYµsU@#]6Öe4/“ôÜ¶’ªx•Ş­Q·i•¸±ŞÇqË~gœœDÁ¥©>Ï¨²×ûÛ
‰´å¨•J¸iˆÅ–dpƒGWÅ	m/j·ä„‘š¬™•Ö®µVX­Q«ÚF3^|$¶'tØ©gÒX?lbÄ„Ò„¡„±¢áe<E†–ƒ’éJ…;„ËtTWªÓ•³;oö'Ù9îíî¶h­³2C“?Â+)Qw×+ÍÈ¸1v“ßş!Zí“A²™€š†à00ı¼	Ú–DáğcxŸäÂlÀÉNG°è¹ªäì¼ß‡«Ñ\L.–nfÿdÆ[“3^iÌ&»fç´mH§˜¡mÑš¬Ü%Tn
¾U/!-è ¾óxĞ?öàrì›l¾À=Ú¢é$YS4MúûŞ±àrÁkútüs01+bèDÌ¼ÏĞÑ–›“òp÷ÛÅftFRl™­fÜu3ÀØ"Ên&A6µm æjqÖMİT¡¸RnÔú~âôæÎxš@é{]›°'ÖÒdjÌ±µ°fJ¶ÌOÓÑÆd0X¶T¨z§X ˜fw–à!¤dFÔ	&ÊÉv_+_#Ôê*ëî½Ù;<İ‹iqßğ¾6ŞÖqõæ’ÜqÚœàî*6L_‘ñ©6m•ÎXÁ‹feº­@
ªyµYİä±ÇpÃj$’ÿH  è9	ú”zİškÍÚc×–H‰Å0œï`X»ÃË¡_J"Öa&†1éİğS¥'Êãè„5OkÉ@ş–[œæ_4ôÙIÅ§â;7~›jZ¶%}œÎM£bÉ>KYm«Db:Øwîüù| ÷JéÒpğNé®¾¿°l¸İ °w3bÅzêÛ—T$n¸fÎ4ô›! ÌbzóÊ‡>rú×^<R·1Tu¹¢[ÅÄ#lêŠ<IU\&9¢gÈÆ#¢s6Î½›bYL·NË±ãw©9ÕZFêNc¥VjâÆ4ß·Ûµovÿˆ}Í¸ºÀz>Òí]+@Û{¢ñ=üNºE\}[Àœµ×È÷½iŸ¸…Ù(v@œOwùËºzñòto_ Ìì€3®ó-^üéAm7=ŒSœsì¾5—<FÍô<˜W…‘–ÍKìEïı¤Ç$°¨ÍàMŞ÷ù-‘æPK°‰{‡:Á²Ğ¶{œÜÜí]m6¦="³n¬çşEH¦ã¤`šK³ÚÂ“âlÔ¯”‹n±M«{,oË ‹î‘g•@Ûª²U.•9V>~+ãÌ…´òÑºlÈ‚£óªe.n432¤¬€jó"&0ØE%}Ròp?3Ò¸U§C?2´_`s;7;×$IE÷¬-êÓÄYm¼ÛFjl¥r3U/‚’TÜ3CÛñ'^Á›á™ò,‰õøæªöSWÿ¥m“ÚZw9n1î¿TÚ“*;½ÔtOØà±¡¦8Ş[é£Ğ½_Zoùì8/ëh<¼!aÒ„ybrD¾ôr¡,Œ\sÑ:ğ^Mÿô@[UŸ2ËŠ%B–¨ı,[HÆ¬ŸîŠÙ4FP«ìYøÇíÌõXS}n¥_YµSØÍ¹ù
B¥É˜²xfg0ĞbNB&c>âQLD¼RfÇ…ÅÆC×Ee‡¬ôÅÓÍ§¸ùŸ?èEôŠh„g5Àù:ñ"4Æ±Y÷+[^‹•¾yYeñoÿ”Î÷ÌGoa”3z$"	‘§²ä›µÉAÍ~.di§Y}A‰-Äúïğ÷+ë „¼€å‹Š¯ü¡QAb£ Œ&âÀØty–)¢*—åPÆ²¤£/o¬&ƒ6ğ(Ø,Ö—Ø
|:š±{”S0kjTZÌÔÈÒˆâëá‚d½Z×&|®³44…ÿ†h$EA0ïı#Æ€™ó†ÁÏ˜b²Şr.†;W0&Š•ã€öƒ”2f÷rá5‹ı‘¸aƒqI110˜G à9x ô÷%Ì-!q” c$
W'æˆ2Ğü­ Z)îÓlLeY•?kéÍ7ú¯”©R|SV#øˆÈ x–>ÒÿíŸùŞÂ-²!Íö‘—ÀšB
è=dPqì#HC ‹âÂû6¼Ã“±	H¯ÉÙ[C;òIĞÛè­÷Ö3.\iWÌÍÊĞœ´1œ–E·kËf¦-·lÌ¦¼ŸªÚµêgâyg˜9­ÚYÙŠØ6ú#Ã}˜«ÊŒïlœÀÌp¡S¯S¬ÅüDçWÎÄÃæg§¶q4ÜèS,Nî©8‰}?I»ó³Z_|â&°bE"İ’¬éÕ’Óğí­	uÛ(ÁLÚÓéØBIìn3¹¦3(Ôå4Cii²'	ş+MZ*½Döš^ìHƒ.àS„nU%ö.{»d÷QFÚÈîì¾LÂÓåĞ„Gq?¼†¬©µïÑõØ€E—V¾åEx6Ã¨†ÓC¹ÑE»cóI3–]É¦Ä¹®Æ­Ù.-­Ø¥»1á¤föğB'î9}q@~çÿyN¹ƒ|²¹Vú#ğ‚¦Û™¶bv3xî/ÁJf™­‚Ó‚7(Ï‰İ/we˜SÉUâZ•¢ú¡dïYÁÄ­’n³·m÷±YÎ³öïòÜ\Jéà-%uf²@V|…u-Àª3Ó©¾0»#XÓz25-²53£“İÃ‰ó9N3Ÿèvq¿¥™kYœ>ğ5ıœ^
âËë&«ˆ£ôSÇqÔ|ìÑ³À@ğº“sÿ¢æÂ;5ëÓ¿îÎ7yĞ<=rÙuÁøØ€4üÉâM•`Ğ&pº™Ú.Ğ¦7•—qp¼¿÷jï¤·óêÊèí¶á
^ö`öbÇ3¿\‹#5Vù7¸Yá6"¯Wì–’vy“šÚ95®Ï"!+‡ç>ìÄ‰ÏD¸?‡ˆÎBâ0-«™¡”GÉC":r÷Z+åËmäcc†›v¶ÓlêÑGƒsFNöÌtÜ¨şr#ñÈ0¡g‡(»+ø	;6f¡œ‘Ú¤‹¬$‚2¼(ğĞØ‚ Ñ;ò[¼ıp²Y–8kvEí¼s6æ¶CÄIx,D¥3²Ì1æœZÖ2wlÌ2¯KÉq'¯DXÂÜ)b;C>İÿ­F0I(OúŸ%şÏÓÇğßğûf.şOãñÿm‰ÿv[ü·¢x?}+ŠŸî‰Bq§@Š×Ys€±¹Ø’fj×××µ«àÊ¹=d¯GõÜ%ê]ûSåµU	¾R”«ĞŞ°ª¢yÑB…ãÈgR¥•¶gu)AŠ¶şCÌOØû;íãı¿Q$x‰"*|Øûş¨³Û}K__áwâ”1gaŠ*‡ö€ÀU Ï}×5û›*\JÑ¼Wü­zŞ$@?PaŠ@l…æ¬KşşÑe¤ãUFt^æ#´õkµXõ!ûQ³#Õ:„qZ€—ÀëT¿G…,¶®ÕªÈÎ¡‰ØŒë ç³êkVDR¦?_<GõV9jõÛ×ÂóÈzfìÿTÀ;ÖdaüÏfãéæ“şç“ærÿ_îÿwÆÿÜ°á¼ó1(k:ÓÄ µ$Æ‰q…\.pgñ—	ù–Ê‚Š„Ö¸Œr×ğb^R%Ò€fòÚC×SE#ïiˆ=¯ï#ì"ˆâä3±¢„Õl‡G'{¯ÑKıpƒü*‰æ8L‚‹›*"¥¯9JüĞâa²ŠÚ«¥¤0$÷¯PLwÉÿŠ1Ü5GqÊB­ÙGp—rggïïl÷ˆí¼Ük´ù`9òÇ+°duô{îGHfqŸidet»vßôvwNvĞ÷ ÛÒÂ÷nixùƒœYˆöÒu¬‚—–Hæå÷íıWHŸÃÌcú}2g¶U¢`Î‰²{–œ%Çáµ‘‡ê®7ü!;ÂJ"’ö(¥³æğpQG÷ø˜ê>K
Øµ¯)>8%¨(ÖxR[ßdû'İÜ‹gÙ\'| Ó^ZŸRéĞIröºs“äp·å^aU¾îÿ¨	ĞôE§BY§=µ€^µÖõ,*˜ı"å|‹¢;\gæó®ßÊÅ¤¿¢§°¡ïQ*à°~^Q´È#Ak‘û–¦äì~{rtëòÃà™²¨ŠâñÅb<:>ÑZg@›¸d>ö“ZêÕ¦£Xç4©z²Ñh>s,Ğ)zq[ †“nQdÖÀ¥T²»ú ÀÀMü¸;Iusccãé×O¸[‰”ø¤>Sèş²~®Şd<ªZQãÙ¹ëvm‘vİc‚ÓÑÊı$÷áÙ“Ş“Í\ÛÈ7æ®™•OÔ¬"€)·z=©5j×É¸éÌ¤iW'fó™«¦jŞ˜½s&ó2o˜…ÔÖqIíVÙ­•æSL¶Â{2ÎeÍ)DİÑ@wÖf•E[ ²1İe³Ï‹ı©n~º=Ë0sóLø-ul£ŸÜfUÖ¾1·7ë(2gŸÙÍ&õs¶GÂìÎUçuúPåK§jõ3P‰d;²ı4Š˜ı2ë7P ë'`öh)ud€to¸’wÓsÚ~M0ôŒ7Y„‰â¼ÅU@yÆ©¦Ã·g”-QÁL×ÛÛmËT3 áÑc•”ÀãÃƒ÷ÕXˆbñ†æãeáqÓ…óÉ(Qkå®E|Úqşä÷t)«b‘uEp<ñú¾Ş84%À Ñâ|_Ú‡§½½“ö‘ŞÎgÕ½	êªÈ8!ÖŠªKû>	aÿC«¶°ÍZƒvó¹P>¶VøëGs¨6(IR|Øn­ùaãEŸnUYK{j<T5ñw+ækÎ/¹æM022ÂÖ]úñ¦?®ó—°ˆ’*Rg«øT…”5¸W×>üì:º¯9·Íš#Ä¼…‘c²O¤'¦ëtÚ;ûTªØûõzj‘ïUaÂ›<%”ÜSDYŠRQp>å“bÎˆQOé¤Ëx‘ºhNdğÄ°º8‰àœôğ„óìIöuË•aÜTnæ¬×ÏjõŞ'Væûê¹•\àL&!†{Z©­"¬÷ˆ…çğó~ŸcdSŒáŠ—`Ô+ƒ¥z˜Ô±cûhT½×."ßŸxgHD…GuÑÔzâ]ÆõlsaÄ³Q,Co­qipÏ·H	A lšÒ¨y{:ï$›ÂÈÒxĞÔ4zÏ0Åš¥$5’X"&•„_¨„FíYr–Ç´­ N˜ZÙ9êv{;u]Ğ¹
µÄ-ªQO_¤V½:>•üZX)nJ:×_ĞU£sğÍkcÆ£• ¬õhtõÔs™¼=wÚ¯÷~há}veÍ)kMÃôÖÆ-Ü6 µPû
ÚtçGp†5«Vù‰çTı¥ƒê„«çcÒHN½wƒKØ9“‹‰xÄŸô°¨Úpò ànª\³[åp¹¶óébÚÀ%¬ekî}5YüLSñwjğçl/w.Š"ÔıúCµñ¢?TS@ûŞ»bãXî´ß´`ßítöp÷è:Î÷ÁV¸øÄ‡Á£¢˜ÜËœöDb=Ï÷–àüC£QøWÀï_&ïa³R¿àâ1	>œO/´‡}/ˆÂ¦ükä2l¤o?$q"¿{É{íÍå»~UÖ„çÆåpšl¤ßè¹ë¤0´-wä§ˆĞÆâéù ³‘÷Şg|x£Æ€€Ş!(‡f˜#/bòÊÀ9wopÎ.áE«„x°‹5Ç<OÛH™q8w¦ wÉëÙ…§L9Lø÷ºHŸƒìÅĞ‡c’D¯ÁÆá¸ŠıuEaUôì¸§a“~ûöGÇ)´a²[º(ù‹-¸Jæ¥İèçd¦Ø÷;{p³wlğ(E±ÖS!œv²­yŞ.¼× iÈÃ¹ÿåúÀÿ„0BŒ·ïÕÍÚ×õIäãA¬şTJ‚<qh˜I[¹îé1NöMšÙéŞ‹´X”}·.ò³Òìæ¼.ê\Óœ3{åÚ’;C–¬‚ÿoU¬¤Qí/4iLgsj”—êˆ¦sÙVDÜ>¼1ÜW`ß>À¿\_®0»Ğ—¿+ó—p¹}UüV3¶oY#K‰»¬´âÏ@Vù-7ßöl°•g+ÙWû°ó5ÆîÁO!®pÈ]m7k›(#\3·›“ljíşG7ÙÇtèé‚u‰O9Õ‘Ù_û	Ìu.DPwÂc¯#­?5×Is ½ÑàÉ&ü…]]{[tg"ï< {›f³ÚèQ~Ü†‹Xù—´mÄykšikVpw¯ş+>À¡9Hx!lG¹ôÖ<±øfœx¶¸
Ç4{8KBø—}–ê®Şz„-ÿ˜z×“âs·ıém8É¼â¤™O1j³z»%UHi³Ş´Š™‰ŒOj5tËHÃÎÀıOYK¾O¼ÙºÉLa¹::Ó±‚@cL¡Îûõó«ÓÌoŠê;	ÙOÓ8Q¦½Tí…´Èd«„†út„l€t’Íò®¼`ˆzrÌ ,ØÚüÖiĞlJCkøƒWğÔ¨Ëç¦GEµtÈJIhˆQà(ĞŠ«³f*.ÎêtB¥ãôÜZßz\Fs¦a£Pa:Ÿı`ñ™E@FÆìˆ¯•­ÌZÉ¶…åV¶ğìÆ[j9~sÔ=ÑR£.õúğôàe»“]¬±‡¶M°4s-YÀnÎŠõZãI­!+C]£èØølœöå0L°U7ïú¯ÿÉ^Ş(ĞœŞb¼¸ƒÚµGQiğù4&+’‰ŠNñˆÂ¨$ˆ™Âç€§	ÇíÒã\¢ğHjÿú¶w©0ı0oôì´Ñn+Õ—;wËÁñ8×ş×ğ7ø²ö¿ÇOóö¿›O—ö_Kû¯9ö_w6 Ó¦úİlÀ¸i,`x¬ÁŸÉÄ˜¬Š¾ˆ½/W`	Í+Ü¢O÷I×¢õY/?¾ûSvWxøÉq8ß*qËmÙ[Rw‘›«1ÚPãˆ,’Çå½h«0`š{ÇU€JİEóÒ–‹ÿD…N¹g\õº)®uâ8:Fh_Š#“şLZ&è¨ğğÏ	;*Ù'ÒÛŸ9ò.ƒ~I 	ÍÊëL=%ù`©TnĞ“ŒÎ	’6õçÏ™±ò=5Zi7³xwğì1=f&ğû‰ú­,GàéSBÅRAjs½£˜µÕ†îÇ)|§áBÔøhó<@«ó´ço³…˜ÀMnEÏj‰ˆMo`ZÔj5f¦¼¬]™o4lQ²ˆlr(&rÓzÂ|J}xtO/áN]Æ­Õ
ÆÜ3QóğEÁªl±à6‰Òr 6#–§Œ“+ß‹˜WØ(×â»h±û"ï8ìVÇ¦t¸wTÔÜ;Ï&êf:9ßû=ò XU@‡‹;•ÃèèxJ ‚7][ù6—§l²U‘ø
ZûÉ/Ø=>né˜²¨OõÉ¤ÿá‰ Q1¡‚z9!¥ZÓà°M@uSo8hÇ¬_ä½E3qO˜Y+“Í…4’Ø¤0ò)ì/Á3fiEÆ~Âğk×›¢[Tğ‰aË{	5ƒ·ƒ§h	çC_RÂMJV ‡x3 ]I€/n(dÄíAŒG!ñÓÆz^ó•)=ëJeÚÚÉ…c\Ó"½ĞëoZT…‚ÓX·x?ù™LÒ™\†`&ìñ‚ÙÕòÔØFa˜(¶	XOîğfã†¢3ôôÛC<9ñí1~‹r².¨šŸx& ]ê³ÓG¨~¥l(ÇZı©t´A9ØE„uÏœ˜Ùb
U…à¬8P¶¹ÌËc‘OÓNk#x¿ı¯GÀ	ğ¹õFŞœøÚLÂCÔĞÀ£
Ê$:Äváä@Ü†Ò ÌpÆ¾øª©~°(¼=¦wQ±u§eu«Ä…Dï”=zşÀe,b4:·á¬BØTUçÌ3àáÃÕxÚ¼ùóNş&°‹E”ã…ä8°é1)I'+2ïé’µÇ{ùşaP¥ob±ìı fŒ¸ólUQõ¹¾,ş72b#.@…¼‡>âª©Ri‡RNßèa;õ;ÏvÍïa›Š6,	ğ:»‹FUÛïÜI–Ùí!ç·¾­úwŠM”®—î6”4<»ñY†»`nƒ’æÉ'Ş`ÕR‰;îób¬òná\r?70tƒHÇÇæeçûªu‰<œâĞÊ©£v©¶ôôàwé˜ˆØ¹V…ÆX:¬i(³h6Ğö1‡ÏŞü>¾BNzl?óá—_ä¯§iãÚ´ieÛ™H®"ì\ŸHñX¤ÀL•ÀQäŒ¸±¬Òd•MVy’WÄ»c&Æ®0G"ptûŞÄ»I„vWe­H/"àÅtH2€éoÂ‰7¦B†bô Ü‘»Ár»b(ØBJ¥â.
¹å—¦¯È°½Ì‚«¤ÍT“B= –È¾ÄdN]#™mp]ÛóáºÄ€Ì@7€Æ-KŞQ[¦¹¹Ş½Hb…KÔQì§&Q&*ÙzªX8[O³x1f;mĞpT²{©u3-ÜM­Û©Ø³Û(#fo‘ÜrqYYôi3Û¦xeŞI˜Î3RÎ+!s*òƒÈœ¼°ÅªäÈÍ"Ø	YG4-lÜÏÚÕ	®aº;Ín=ó2¨]Üsm¦™}‘#]æ‚ŸãßcÛË%ºbám®¿¨ƒĞ²jLM›µD"?A—Nš«*F@úsÄĞû—!tåa£„MST{ùÊ ïÈ)HIå[øJm½ª3£ ©J‰
1wå÷XTBÓ>ÉÄ4|hnÄŠËßC£aG‘`4^1Wg·%b=”ëÇ^ßù#ÈÿkõAØëŸµ9ø/øÉè§Íc—úŸ/5ş€ìWÓIm4ø2øëÍæÓÌø?ŞxºÄø2ú?È ‹Cï8Ï'/œjËû£–¹¿{^‡7¤–fpŸ^TÉõ­O<Úa¤’=¶ªÜ³¤®~„ù¬OÀ\üL–¡sŸ{ì]ä_¤–u(ÇÃ
jAè¾?×½5Æœ9Íóú}’Ä,(&±;^n²™xÚGì|šp$„ç1\yÇ—/ªÕçuñEbeŞ°æ<¯yœö²EÀùÂEØCk«:­Vˆù/˜s²`–iĞ–S’Aí,+è§H‰Ï£óÊT¶A²di4À€áĞ…T¹ÏQzÑ€Ÿğçyª˜Ñª”Zâc!d	©¯ß ˆúh¼aU$s›ÖEi%XÒâ¦FTÏ¼äé:£+êõˆß‰'í’”7P+‰3ÙZ¸	²øjU}ş¦J¥”äÕ×¤†2p¡”Ò6#[iš¾ğ‰/i_dCõh†°O‚XÚ4c¿Ãæ×&¬.çß–Ÿ[ÿ0–Ÿ¼ÿ÷tóñ’ÿûÂã¯/ê/9şë¬ı×FsÉÿ}™ñ?sñÌŸ 
+Œ¹ÚÉ7&ãöŒ¹hVÅv¦—¬ñÌe„*Ô„¿tFËT#’_ú®Së~ÃwÚiªy¦’&aÆx˜²t÷»{]ÇlÍyäh(x˜ıíÙÅK®):»èüH?áÒ?»øs0'œgKdMÃË¥4™,ˆtú¦Õ(Ìªd«ªUgÕ3~ÜåŸpÑñ<åŒÇš8ÒxNÖ½Ô İn»ûª³GuÖxuÉfƒ1nüh¼‡sôøä"W'ÏZ·>RFoœÉÅ2$Ÿ†iS]9ÕYUyB7$ûÜ!©¡‚¾N†^LÈó˜à?®)± ¾“!%c%•Z¤›ÁÓàXéHi¶M·W—QUdLMzr|¬'3†ÓXàëyøxÉ…\ÍYÕ+ñí,Nwèœ.Œ«ã%ÙÌ*(ÿã/¿¼	~d²I’ÃÄöÈ®§‰¸Í¶|L%=¦ÚÔ5a m[¬íê"ÚbZó%ÇNc>ã â¶ÂšP€H¤‚7¾a„Û"ô½™%ºÊƒ È7ıp:N˜+QŞo=ÔÀ{lY×ºD05ÚbMi¶Vä£ÁÃ®³ÇMOµĞVCoŠ^cQÚLTxÔ=LJª]†¾¬XŒà²7À¶ó‡Â=‚{yŒ3„¯¶Ó“o:Nšmu@za¯ñ—wa2‚KBË¬9Kúÿ+ş¿?ô`®ô•±ïı	ÿÿmæù¿'ë%ÿ÷eä¯øĞ{Cu|Âñı…XsŸlÂjYÀŸ¨0P=– Ã¡³<†š<îœ—ÎND:. ‡(P/rÒ>İŠoUr§"ÉzºAV•¸D,‚;Lû?áâ¼`»áõxz”rn…<ùõ{ˆQéOÑ½˜!…Ü"| ğ>šHH\/~gØ“çu 'İ›0'V½Ñ>]Ks4ñÇ8H~4ÂX˜\¸3ÍBIóÏë8*³¥šÜT>Şº£3[í¿NtYĞS¢÷ÇQ.ÔÔ;
3LÊJÎ¸P¿—Ä{:ÿe,P`4ıø~Oÿ¹çÿ†%şÇÆãeü…ş¯ÃçCØØväc„çB€óTf×ìÂ÷ò‡Ãe}>½d„Qsœ+rÌ†â0¼òGçPCóÉ#F®y@zF¹âÛßw·ôSaŠldr•Â*EX]qÆñw9aØPÉC1­¨¿ò	‚ÆÓ_ì¡½ë`Ú'E&uNÂlk>Ôh–fC‚5DÕ‰§ƒy8Œé‚ëé_OéLàÇ„¶)“´Fâ@ªÓ¸&Où:I’ğõŞíİŞ;í{’Ë¹˜ôGïÑE€Nìš€®ÈuæuğÈ ÍËƒaÜØ3Qs9‘Óó´Dò:§f—„"•æHæH®ı¬ëO>SM”Y½ÔfÃig_§R®ºé%¯ï0!1ˆ%”R[/šS›Æ\0äLã–áÉ˜OÄ]¬è,b°XOõ7Œ¢6¯Ñ€t,=bÎQ0ó©ãyº$Ğ„”gšâ‹¢8`D’'¤Ğ¦ú´¸ÅÄË 'ÒŞ00f«£ĞĞ|½óˆ;z}€|n–Şùmh#zç…bV©kzûøˆ¼Vğ>P%eiŸgF
V•áêw:WOëb¼o—j³äÓ'^SÁE£¯ö÷ØFÂ½ôãì¥ñQ\@Êé/¦	…S†­£6cFß~J µ‰Îú@ÛÆ™Rw¸±9ƒ;Åq÷à¾6ıy`›ë0BŞk¬k3aá©pÊm„©!CÜœuùe“Á­G&¨A²Äİ[/ã¦—ä¬|ˆ±Ø;ĞößÓ±:ˆDÄ‹·£ !¶.10ÁnE#£"Îlıß}s}ó›O³ö_Íõ¥şï‹|>üj|O¶õÿuşcµ±Æ2MñÇòyòÿ|¥T	.’‘eêøĞq>D5"|ÃE,¯€tO3mLñü5£,ƒ_öøŞñğ¡T<Î¯(«è%é[”Ä‚ô.j…ÿ˜¾j˜ôÕÌÚîœ¥9•ÊMköZ]­Ó—Ùwò¸È÷ÆXKĞ4AöP¿–ïVf¸4]§9bâsŸúÏŒ”ÎÃß£•}Ê¸ù3®xä34¦ßg¨$&Éâ5d_OS lYPf¦,‚ªUX 1/ò@W©n¶¨ ËÔ”8_Û¢’ls˜§™¡Æe¦ŒêrÙZÁÌ7Ô»·İ­˜]¬wM
 µi$Ìˆ…Z¸@˜iŠÒ›¥ŞxÖFzg23‰ÈÒıƒT²óé'•Î²‹"cJ‚{Ö?Û§\—Ó¨ˆ²óHh¨¬‹z2;waÿ¥FÛ>[QÇÍ‰|{E·ĞtU÷<]7¯·UÒwC¥¢EÖ˜dl©åü„Äˆ^8q…|_Ğÿãiÿ‡¿ëKşÿËÈZ}4ôp*ÿûÔ(PqÌÊòÎÌ7ˆKapTjñğ¼ù>_áp^ãe4‚ÒQšÒ=…C–ÜLü–»çÊëíÂ’ˆ‰TØ*qÊ3}Å‰?À½á^TÇçÃğ\èëöÎîA¦½ûBnsüQªP$]2¡Ã]ı Š¸Iİ­k†Ü%/)¥fëä–Ê¨(ãe¸0‚êLH|éÅĞ¾uîjÅÈB”Ş÷¯»ß>c;º†ñH´%Rí½J¢@”%ş4x_}V…ÿSgÿ0b¢¤Fã×ÿÌ¤m4ŒÄFı(Á:æ¬.÷Z°!“¾*ñ×°_ÿi{JÑ$Fú{äçQE< nİ÷xÜE^j‚DFvqöÄ7p¤¿t¢Ğ ğ&fÁ£  ‰ÁæŞKVbãüÃ!b Ä?1ÊéY(p¿ë¼°¸ò…7ğ&“­µM^W%ú š!un9!şt…(u50‹ºJp¤&RC-1Ä´ÓR3¡‰Ë»L?0$³©(RÍYŸb|£7uóQª?(*ä„d~E©y¿ÄÎœoŸOÍJÔ¤êÍái],ˆÆz*çíR—PŒèšG7
LóNfß"úÈ¶‘FF¢À©8±ßŸF0¦zì5¡ÎyĞÂ˜	¿0*3ñ}V‡ôucö×p÷ªê°nè«N$®š$U'Á«Ø6™k´z“Ë­P£óÒ nùY~–ŸågùY~–ŸågùY~–ŸågùY~–ŸågùY~–ŸågùY~–ŸågùY~–ŸågùY~–ŸågùY~–ŸågùY~ş~ş/ıIi  