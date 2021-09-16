#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3864065741"
MD5="bfbedae76787328fbede681e805902a1"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23748"
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
	echo Date of packaging: Thu Sep 16 15:46:32 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ\„] ¼}•À1Dd]‡Á›PætİDõ?9XŠ4•YN ˜ò²ˆq¶‹È<EùRsÛşÿHõæJ{‡$¬¿e.2”ÈûQ’G#ïDÖvªQ‡è¿zµb‘²”]Œ²ˆ_Å®ÿşã?Ã+[tıºYÖ(_l„g"´8µ€åañ©Id¨—S&1ëOŞ' SÛroÑòæ?>^j™Ú‰ùÉWî`2Åm‰»¤ŞWPÙQÌYZ@3j%åxÏ4#vQmj2Od^úf~º;éÃ­¿Ñ¦£[)xÑ ¨£Ì"ÃëiZÓ{ËºO—áß“D¢PkÙ?ÜGñK}Ì¢§?@½eİloRúKT¨%şÃæ×c{â((0Pa%İ£˜NØÿK)HE3®¸¬¤üK,É¸#œæ9ÑµÚ†Ä¼Õ{…`¥çŸÆ÷&trÙ9Ñ€Ôa„º6ŞŒã¦ûî6oû¦ ¾<ÔÃ+."Ò!›¸ÚÑôŸ«5
g¿³L±Ş‡¤O2@q{±ÆIIæü<â¸Õ=1ûeµ²’Hk„^`éàœïÈ ô'©È¤æ!à„XGhMóNŞõ/Åªš Ìê5oˆ,TÇwjö¤‰±Øê.–W÷‡F\îÙùß"²5²%/€¾hèšı[@âe§¨rÓ“TÀ›u.ô“ßé«4à8ûğYKO<—Ü!¦ÏvKÀ×pO¼,EâÓ€¦Íí-?c5ÿnG„\Í¢¼gaÈï|ú÷¦aÍğ­ÙÛ‹7g˜J.}:XÖa 4œğh9ØÚ0ÏvÚeŸÑLšCA8"	*øao.^€KT2í~k£ï®Ú¸¾nUZ‹¨Ğ‡‚Ñ>ºZíÒçÊê,Ÿ'Í8·‘l„í9½é„œqY/í¸¤ËeæA–4¾Ï:pÂDÕ7ˆ‰û/­ß«öqøø¤µèQîT3”ı¡M3ïmgqÓpGV±/d_pã*B6ÀïÔ	ó­šå³F>é”Ú}À8ÊßCO6İ*• ókÃ‡o¯¶İÁÖ.=¡)Ó^|ÖÈíóKêfYì™d@Ò Úlã®s5W'¸J×Aë}ßûV´,váwÕ†ûî^zï5 ùºÇºfÀ÷/ ’<97/{C´#‡‹ÅØü¯/²æÈñ|Û$jQ£oó4±ó£U;Pq{YîrœS*ÚCèùV×s#óˆí#
‚¾šsùìà’ñOñĞŞ[æ²Ùl9µÎ¶g¬4©™òûòjïbk¥0m1×óK‘»?å†xs¯Ud\Y‚É« şµ=bl3ÚKÄbüıY÷/ÏU7Ø:f:rôŒ`7Oz¥ãâê*I#O¸óËz!
¯ÎºÜÇoê
ñ³— F#  !—~êu¨¯æ’4]¾šv)Ï.Ç$™ˆŸ°ï*¸¡‡è&ş£¬Î£bä8b˜sœÈş—ıŠFW,íK
8  `˜Z³¼0¯[†Ş>õë—˜5%#~ÇÍÒ€Dõ	Åª±ã] ²`Rà¥s1ƒn`Â^§U:Ø‹5'˜](&›†d?ğÕ¯Ÿã#t"mš¤mÈ·èØßÜé$Ä>=Ub%|%’-—ãrMcğ jÏ¸âJµšUúÑ·­Hhö©BŸ} yÅWOˆÛÿ±Å>ŸîQ	çEöEo–~Çğh òáÄ#k—Y3éeKÉñLdv²‚8± îZ™#Çí™”1Ï|èñScKÉm]@Êá¥ê`íUıÇiLPåqı-¦!aIP'em›àFæÃBÊÍåS¾/ÛÀí¸¯…è²§é§&«U^„ô·Gm’dÄÁ‘”l[õ‡
4£Ÿbo@‚~ä¶2GÎhef¢O‚ò0GìÈœJK—º%JÍŞ¹å	èÅÚ4±!ÖÂâXSpÇø€÷Œ‘H(MÊ`Z·’-)Æâ7:eˆ>Zl2CP¼E[0¤ë«OÂŸƒúe8RÈ¦àSÛÒ±ûÃqìÄòÕÚrq„¸R-Û@õZìşdqBÓı TÑ+’øc+Š–dÏb?iËwØeÚ~\ØòÉßkİ‘yäTRÑ¸¥¥ôßöFPønÁG?ß•§²‰²Sê7bèİG€áæ­	ÉÖxÙ†E´ığ`¸¡(\š¹ğF™ùøû3Æ^'±Æˆi-I–3ym0•æQmEÙ;ñ1£ÂÇ²œ7r·±ÌõpŒÂsfØSñæl½<ã]gGMÇÒ0«D??ªÇùC&ş¬/Bı‹M}şı±`00×M³Miô]¦IõiÜüQ›§]†$§²Sõq¢:‡ºQ”#ÜèJÊ±ˆ7¹|êZ0°Äl¾¾m‰­«'÷l•Õ˜Vß«™O¥b¿„üº›ÏS%ª½5ÓËTÊwxÊ¢¿Ò­—}1bå´Œù6Ì|;Z1bÎŠ´ÑhàÜ`R)®¾0½fû€…{Õ‹øÚ8“ódwL³H™Ú$QáîÚPÛÀéXJ!`Ê™HõM–«´r™LÔv…ùT¦âRšú0éóir’ÆÄ€=6)†ÈcIUS)'éIİkÜ1ÓyQO¶œs±@"›êíKy“áEÿ‘¦`ø·AeC•ßªÏßƒ©—X._ÑM6ßb„­ÈJÀtTõ¼S«ëäC*BÑ-hÅ•¥pùûŞ\´l¹‡ŒOix¯ÖµÙ4)9I¥,I‘O_6Íuvá
Zµg\µ—œ'…%0ŞòÊ:Jß$y x¿, Û—7s'@×›R²Á†m:a^ü±¯ª@éšâÕ¿5Í˜0¥uZ §ÖYkpJÃœè2'<±×ì+8å%T'E\Ç!é6pŞÓä6¾nØ±R3d0[(ú…§ŠÍ÷iİÅ#OL®&2U@¾şyî#ÕWË“·‰æ¸¬¡E¥:Âó¼^ÒVT•¾Cğ½º1¤a]iãD$,ıcŒVdúŞ/´ıŸ¨ î¹éfÒJHí¤µÄrW[Óé®_ÇÑŞK1ÀğU£¡„Ai`K,‘	®#»Ö	Ôò/K¿PZ½ŞÈs^gq„ÌŞkŠÄÍé«˜‡ş:ÈyåĞæ7Gó(hô%ÖõrÃasôñšÁ:¶Pq‹\éÀ«wì¼r
©·&Ç‘%ˆ3ÅÂjR!Ì”GŞ²ÕÊ¿•å`ÁÍ,¦X é³Èd§Mj-_O|Í¯ZÁæ£²x5mñĞ'p=õh SÓ˜¢Ş¹İ@¾í@-Eq\}wÅíÎ<·®‘aU €F›}tˆ&IÛ)®§63„Ö¾)âĞ™Gwƒ-DÑº }DPMyä%OĞİú.ÀQUeQÙú‘$ïÛşDâªbd•>ÓÅãô1§tŸz§Ç?Îí>ê-ÎªB!D±˜Y¤›b|Ä÷D7dúİ	úC®JY1fãB]Xj8–Úõ]G«6€R•iiC‰ î•Ûñ³d²Z-Œµ4&Hr§GÃS"É³+–ğ˜¬"";ç™2/vÎ@ô*‹4Ö6Uú4oM˜¼,ñWyµ’iÓÿ[ê{A‰^nÔsğœ†Z‚ô‚½wŸÊ^äª*ªOó@º¼ÁQArÍàÍbmr×âŞ¡yƒ«ùŠ~r™$Ä5¿9°	KÅH°D7Z)ç8è³òUôœI×,‡’İàÄşÛŠYæÅğúvq™D§ş›>è=óÇ‡”-½ëË>Ze¬¬»\Ö;L½NU°(ºÑcó ‹vY%Om)éùky;ô¤|ay¥Á†vûÚ3˜³g€ò¡é†Ú†u‹¢Mvâ§æp]Ğ<ÙÜ³bğ3Bá¨õ­Ü§-~Ÿ„¬N!PXæ3°º ­×õ.®R–²åÉD¢H"Xrhn³ëÕö<vS€ØÿSŸìÏt>ğÄäHˆ|F«£^	Î­ÿû/;{š[mĞÑòÅª0VÇß‡%È›Ûl4i¼œÒEÒOÃÃİ’å£/NúÕ¹É%`…ÿî¿ÖiùÕ¬¸Åå.ë9'-ò3mõ­½R®”–¦¡Ü
.>‚á! RÖue0ËáMµ›?G‚‘MG5øhÉ€“1 ñÂ>z~~ÀåP}‚ «XfâQ,ñˆj} õ¤ÕUqÉ#³áËøÄò*³G5}¼ÊFÊ¾',»?·»ôFdù€§h¯P{ÌşoDØı‹ğœ‘:ädæcd-ÆMK~>ËºQÓådµß2Éš¡ĞáŒ€Õ°T6÷ré%ob a‰W“?-â”(~"Éd”ûİğ©Q,¶Æ­Ë­E
ÆËİ‹Ä‘Çl{ƒ_±»yÛ^MËëGGJ¦p¯4­@¹‰§%òø3úK•Û¼¬kÍ0şx
¶O†üô=ğs'?ëÁçEy =º*Tª…ˆ)‡&+(Ìï[6˜×~š?-ÑX14{ıq|é‡,=¢ƒşÎ*Ş˜B%Ú–3l°ñÏäÎÀóâ—îBÅø^›&\i¦È]®'¦=}*^rjÌÃu¯(÷-~ Ÿ›Ş¤:ÆHyÀKx…"€v­O<{1aˆ+,WqÒ0‚ğõáúl³Qc$œ‚RÙ‘±ô´oÃ]²øş#Ïô[LDX¡Éma›T)×İ$†÷<moK¿ëH²$ï«‘	ü¬.#p+ŸŠ(ñÕœ¢B÷Ï˜»4şèû$ğnÆêá“q^Z>®¤0>»)äóM-u`á>ª©8g‘R ~Í…¥Á‰-§;ñƒsz¸{á§‘¤Ù
O¤’d –?UÕ…µãÆ­%IŞû²Ç ‹ô×˜øg‹c‰øW«4 Õ\²kÜ>5•{6°_ÅÂÌ×²ÌÙQ·ñÇóPøF`Ì<}P¬u¹?ÎI…xĞëÿ‚{"2\nFæã–q”¾DòR½w 7}3„…{‰{èÎ\‰YƒâÜÕÿÈº[ìoÇ6Ëu=UoS?íâ­×ÿ€É46vH	ºùûÛ¡ñİ=ö®¶»<!ÎØÍPàÍZÀka/…Ÿ‘¨ÆÙûdÓSÎK¬šÛıC4RLìÏõ<é æ[¸íË`Ú«İÓU˜ÖÃ;÷¸XÙË…•i÷7j#)- À¨€–®Õé=Šûü4°hëûè3ûVN9ü~±7øi,Æ¨Y9=^BÛi†*Ë~n.,<*ø¢ºFâã†@ ˆånÚÆJ³;{èØdûö± ›TÛ$°KyÍjO¦*s&ÿÛ“;NDÙ³»J€}–Agú§×S:ù±ÌÊZ£˜YnG©9RÏX	â_”İävÒàÊº;V[”
³«ê½Û•ƒ‰<×vCêÅôÇC5£îV©œÚğühñÖpÂ¯â1VxD6#±LÅ•Íê›p¶† ŞĞNmlšÍyµÅPe¾ÏªbqÎ#"î[y` ^¨iËhM¾]WËæ)7 qóŞLaúKÚC° á«äc#/':qã–Ò-%Âˆ­+Öæ1!É;6[]–s|WW¸bÖ5¼ä¨™¦;—óÚã–ûV¼C¤Ã3·q:¢,VL(J"t¯V“ş@q.©Ç®¥'mŞx÷8j^ëÛäå!$™"°ÿ=ùøZ5Xü9?I.¬2©ÖûO+àÂŞ~ŒXæ.àö«•sò¹6!»”Ü«A«²1•Kd‚Û ã^îËUÓ{Yˆ5×v7Ús_7û¯ŞÙ¯,İ‚·ÿüÀju‡»NçÜwb®§e<cˆ¨$º”¹é%€T¡p¬0*rl×¹#×vÈ6èºXI.øŒ0®=á‚~ÌÃ5W€õgmjNÉ«ÏønVûJŒ£¬vÖ0Î¢|×7ºR¢İ¢Kõéî´3»<kÆc¦æ³Ğ¼uÄí)*P©[h5‹Pûê‘Ó:TËO½Qg¨»?ïtQÕ—+O„pĞÍ­M[2Ö‰>N¯D_QöŸí8­©›İº'kØaè´oå…Wz†ŸËVuwAy±6xóãhÅ â=({l[Cõş‹“¢A@ˆˆˆÀßr¤{’3¸ûòÙ–ÔˆÁo£|W	‹‚‹Eü\Ô¼{ANtÙàVÄ‹{}È=KF|¡¿Íİ."ÕæqÑœxbi‘Ş¼ğWu÷¿+kCøpp£‚¿ÿT“G›×¡§eĞ=r%ÏÿD!YM«Ø ,&š×wó0Ç÷—›˜I™ƒX8Ò­gG” ]ÔRòWı…4ÜŒ€¦]&$_+Şï	 Lˆô­ú/ŞV˜¶]K:Ñ‚8³Ó©şI¶ì£]Ğàµa#¸gtKÁÜƒ|¬k
›7Šk~Ï°rt$vú”Õ¤ó¬ğ<Ë4ÒBğ°zòÁ–ä/oª†J¿@Ús‰õŠÓ˜ÊÀzâ&|Öd†¶Û“4°ÌÑÚ@‹>Ùqv¸ÃIŸeËËŒ˜W"/X˜RŠ4q)¿72ÍÒ’TlÅ,7˜ºhXò'Æ|”€_®…™˜ÚÛÊoøZÑZºeÙ[˜,¬?ù¦Óøİ|;iXk¬…)=*¥†½VÏ|éñ~Òˆ%‚Ğø¤,sÁ™zyG! À sšŒÑé@%MÜ€²wØ°•xÄ˜ÕZ] €4æ|nµ Ÿù'd«byHàşŞk/‰ôXhÈiLò\ƒíö ³ï@{y”vÀı¸¾zvl¹ÕXµç‰Ò
T„·óN(à¥Eûhë@¢yù”	ù[;zWôÄî„`2õÈÇ¶Şm…êHœ6fë·É4Ci”`úkd¾­HÎHü$ÑU@é1¢É=»Âõ˜ƒ¹:æ&"qæKM7` éË!ñÎ¥ßşA;¥â¥ILI#ôqë«Ôi…ßÄld›ÿ¶UGØU:9_˜®íBo¾l™PrÔŠpëêçËvñ¾h/7h!HKV!9‚=ªK`I7šfÁ ÁşÜbÍil•µ›P?­Fçµ½(…+9°×x¹?†B{4¡úŒÊö­SàÈòï l¼îVj»_êº¹~Ñµ¦­@NÔlh’v0ùPe±ªJ£EfŸ®­òHÂïÍ½âødıÉ	Bş¥iz_+â:3—%7Á˜'qv’°ôf:1òF,Şì¥™¨èÎ«H"òˆ¸V:\¬+é}¼x˜„vÑøE.Pª\ƒû-ÏJX©ê·ö«Èİ/hºË~Şã$	“Îh:›ÿ©hûuZ-oŒDˆ°­„1€ ·ZEÑ[=a[6Î½ş,¬”…Á’İ/'wÅ[c,Òşyï'Ş·`Øm¡ï›ïgt€ª9½®åa ©éúeâÔÜ|œŞ­º¦AF½­ãù<¢€N"—(	îÏªÊOİrH¬ëJŒ<bÔ´S‡§]Òº°JAÍë//i}ŞOŠì[Ä'TGçUx7•l_œŞMˆı2ë evP‡UÎ@ßÑdÛ‰¾ÒsãìøÂLV&$£Ao<4v‡'%Y&Y#UqƒFPŠ)¹t¿ò‡üÔ¨E>|¨dç·öï^]±»¶?qÌxÎ½*Vœ»ˆµ-,[òzÍƒ+­(ª“nBÂ3·çk3`pşgt·'^@‰®ğò/†Õü³­Ë¾¸CÉ$ú/mÀ‹ä9õ2ïÇ“°¡y3õÜÊ8 ŞŸíå‰Š!¾çğLû ë<Š­+oÖa´i·ÆÎú"S’™.•€ì#Ã¦qˆZ™´Âd¾©®Lìq¬9“
_MÁ›Ù—ÂÎÙy:êhüã¥wÆ±hÃ[ÌÇÓIôàâ â…f½­[ÑÔ·^û“0B,C^'
TFƒõ~Fií9Düsä®õ²Ò3$Ú´4qGmŞüøyN°¹îÏàøë$T1{3=M b -÷­ëAŠC¼%`58derU±2ÿƒÂ+ÖÄQ–zªæ`ğnyğÖWFkÜİiFŞ‡;a(êˆ „š-ÌØÂË®ë£˜™>YÚ4æ–8°i@›ö¢‡“â£˜Eç.~Ò~~èÏâTÕÂ¡Ä7[$	¿Ä¥´„ŞáC âÓ.Z`p[)şS÷€§©²¦O˜.r˜`…\¥æÓˆÑöt€¶RûıĞE$(\ğjqG’ÌgC}7ƒ…Åÿ¹(«N!*«n D9!âúÃ¡	œ†düD€ó§ÖbÂî¿ÍŒ­Ø‹P‘¥óª •'D$pö]ë«íò
À£Å³×q¡º2V„â\¡I¼ ®§¾N…*	Ì])ºÏÜlÌş¬,ŠäÌD[( ¸´‰´ë×C‰y¤qÉ4È=®°ÕaÔ(Oùù¿„;T-o>•sS"çæ‹øöÃ)båjØh‰7\>İ—ß¨:ûBø“Ó^u55‹õT¸˜2%'Õ³Ú:¸jªVÏRÜTe Ø©a¿ˆŠÎféÅ<}vseTu»DïdKB8Ó6¯N—y>*÷Şvç|À^×_Œ	54k4;,S ùòÂIjp¤Ï,¤G_L—±Ğ1zÇLİÑKô:^®âuL%³F¤ŠUhHÍƒ@ƒ[ª¬èúÜzGÆQğ.«pšŒ„ıTI?“Kÿã|ÕÈN‚CÉ/S„ÁÊİì$¤lH•=ügcLFåÂª‚ğHf+ {©ºífÉÊô]“¨.o«\ÕéüWŞï@›ºu¼8ÌL +`±K]ÎLªªßƒ°HÎQC²Ş`šë…Wc²|I¢i??,]æ¿öÎû.;F7ÛPïu
çlÈ.|“~%œ¿ß(Ï²ÿ÷·Zÿ˜Ãªæ'}æ´º¨äÕ/¢Ñ;Õ7z§Oœïôœmv[#5U Yœ):)Ê+Ú¶Úlw'”9ë|×"¬(ÉÇnl.s<¬xíÒ­.øÖöÛ2Wo¼xdwşn7Ä íMÄ°ğ…Âj{·*ºØKğè3ÄŞ¡bk£„¶¸ª,è‡ĞŞ}"ˆş¥G å"²xV‰__v(…›uhKÊÿÄV®',o¯ş1q¸t±$ú$a*ª—KlZ~¬G„Õ`my%J®)×‚DÿÃnHˆÿ2òä,X	Ã#¸¿‚ÿ'`¦jŞÎpZÁm_#HWşQN¯¦G8)Ñc¦0Û×ºİF¤<ZUK_	{0µHÄœg på‘¯åµ1Y1s ›<P}ö¢a±B¬p„9°¿~gğ½¹Ğ{áIyÒ5’¡«¡Ù;N6Ì­4¤lñ¸ÍöBĞÏZLê87hB)¯•è1t½å©™\¤&;·b´SÀZv¤ë¾zX@bO^5ï¸õ…Ë˜ÈŠw{ğ™Ï?èÎ€©‘Ÿ<ÌN“¨c¬·;ÔEÉ¬pV¤WËï›õİQT¼\ÊQ®P€¶¡`í"v’Ó9dñ\…æ¬)"r’vr¼ëÕ¯Eæ+u#<Í-® İ:¹Ò±+aNYÊúÏØºj#–-e…:À6¯GÍëÜ:@ƒÊZÍ»$½‚õÏHE`úJ%R9ós¶Kw©2¢	Ãkµ³±€•ü#•[ .ç—6jès@¿‰ƒ:"ÿÿ$Å,Ç
[°iEäÒa0ş `»‚€ ¦>œ¥xº‹§5(\gqópR¿Jfß;ñcVr]õGÜÎ¿»ø^·lˆCgÏç €F–EìhVíĞf\@İÇœüø(sŞ é"Ğk¢$zrLuC<éI	Z	aª/5º?r+õ8şªÄ[şVÍ@«’Ñ†ƒøq­û…šıÄ§û’bD™Iõ¸£·U±èáËœâC<©)âªÀ'çæš§wíSÜô£ÓÂ1ê!Gs´:Å±'±p„¿¹ÕĞbügµ&Úä¼y(±5´4—?F§?ûÈ‹‹qj¼m[w%%ŒÖ€ulê ±Û£(.·ÿ‚ğ[ü¥ >1Ç~ûËG›¸Bß õpøÙr’˜­î4: E[kq`•?PœWëøå¹0ãdşîëº/8)Üş‹àü¥©³â£.û*×ZïÕëÀ*úwE'! !óJqW¶éMèìKx°\Èz±`õ”¡d²ÚÆfù)Øó_¤\í¾ÖÀ¯VhüE‰1G8ÕK
{QeŸ¸>Ë´ @£±bófnßŒ`j§…tÿS¢sÚ¨îõ+·„ë3Ò>tº‚Õµ/øÇ0@¢òÃĞ1„ı ebÂww±¥ @NjÉhøá«ëºÑÂş^L„¶]7Õƒ·|ŸÍ ÀCüÖ¯NÍüuC6ôÅ;½2˜Ö–6™.Cu„JX´ÔT—]É6ÍÌ8ÎY9=|7¡«ç1Êñ¤i®ÂÿÉi±_fÕ$mîÃÜha²XÊ®çM‘ˆ.!tƒa™)°eÚP¦x>ÌÔÓ-0¡MC°Ñ)0n³@+GÏ]1ÂŞd® ma ¯{³z™ç]Q1}ÖËy îD­ğ‰{dşQ‚¾•İ:R×_îxÍ›´÷!<l)Ôw“·µ`ãŞ¸­2Î¬ão">°ï 8È¹-½Ë§t, ®š‹¹_Ÿ”–Ê«!Zgøë%„Á}%dÙ’ äûI°Ñ
Üº×ÂÒ#‡…Ö¾õŞ˜Ëğ<ÍEIïÑ¸‘à¹ëÈt´[À×^-ù¸^ã1|ÜÎ¹éVoøÑS#”Me`¹Úë’Ü4µ2p[-Â(È­®§¯Â%\2<C‘3?@Iç½Z×…õ éÃğR!•¢0¹‹¥±¶*ùMD®R[˜¸@~ãdkSŒÚèüß; ¿ßVÃÃe€6» ƒ­˜‹ìŞÓ_fRìõÑ¶¹.=×a;†õ³…œâ+ÕÏ‚îúaQ{[ĞXælúÓëp¯èVV*‡£ù>GGèx§HŠ=HI\X)h|ån4©aa0]6mßƒê#ZT*İğo(ù¹ˆpOR)wn…î„£ì¹»›Yj¦zkVê^.ãaA½ùÖÓNĞlâù–Œ±OQÆ4R•)HnJÍlõÿ»©¢TNñÑôõM#uFeÏ°çØ¥)>64~°Œ	o?eÇ)“ß32iâ¬ĞiŸ!Ûë?`mT2X)5LB_@ì­ùãBäµäıŸ#Õæâ1Ğ„®'µ‹l«$_í·0‹IÈóğŠÊGÙBkHF£1~ãpÚîÆ,: }¾|X–rÚ5D$4Çƒ¤¹A™h1ìTg®î%´CK¤TÒ±ì/O­"ÿÊÍÁß¦ÎÈŒ%ÆìN0‘!VÀ¯¬)%pÈÙÆ;Ğ1Z‘’FŸƒ4ü~^¦Eaöë^³·
Š<ÇÏ‘‚'ÍìÛÎºx.»vÄ`$¿œ|p^6Ç„Û%‰ÁmT»¨òØC=¤A—t'İ#"âJ^ÕQ¨€¯NÅÂ€9¼«YAhœåçø>¦óÂO˜ï„7ÏõµQ±üämø>æÇ^¿•Œ¡‘H)paPFQîqÉ*ÅÜQ´*‹Q¥Zœ[Šµ_3‹Šcqñ¤Ó!©»„ĞnSö©ícÖİ¨„a3(éÃÖ><ò—oğ&BnI.VÄb<:„cÙx~ŞaÕÜ&m]º÷Ó]ZÿßmY%˜Ù)ë—Rÿ~ı‘c@_†ZéüÇÀÖÕ9ZœxzOJ@½cîâŞb¹ËK/ŸHØş©
V›İ7,êLˆbe, €‘©>è[gr;~^3Òíõ¼;ƒ¢òC+QÉ+çr§–7Œ}“­?bÄ—-OôO_Ã°0Ö‘ŠT_% Yˆó'FPclı1Ó¼t'Ì-‡ü#«Óì&ª4%6;7èØYfrªºfgÈÕÚ ó =Q¶+LÎ¦VİWM~¥(èMTÖÆ´€£¤vHÜ¡?ƒ1™f’3?Ÿ«æı· );%Óóæ|4üÛıJ|-ÌÂ.Ÿâˆ
£yÂÖ¯Z‰ˆ´ÇjíY­¸^ÿáÅ+[oµÅÜŞy¬Ÿ—!ĞÚÎ@£"'ÓÈ0€c¬gw+™ØG WDjå¹ğÑÂÇÈ§‚šG®n˜£ëGµÈØ‘j:É0 g˜{ÖÕîÃH<é-ŞaXo
Òêzt«ë½ç.µ$¾kv$D&‘Olp«8W“â–ò¥êœ%‘eL•‚ fè%Dö‡s÷œÒHc+y®ùWF7o~\'„=®Õ$‘Xg-§ü=‚ŒÂ©Ğ.ËX,ö lrû}ÅéfÇ!´
×~(èV¶ì]qJ!µğCrãrèÕaš—ˆ
_7û’çğoËTÌ=ÏXˆºÃÛ× ­™C1(ĞŒŸsM=GTîŸ4«3İ½aS:µçN=^óŸ¥DĞ½LÛ]…ß)“üÎÓ>³HÌ‰Ó½ó>rß"Ø&j!_š¯$»¡÷S>.H¹Íñƒ¼4¿ùñşñE\Îôìgg‚¨îŒkîÜX9«éÍô— …Õ`æ6×[–è]…;®([˜°şâäWY
³ 9›ú‡m©¿ìÁ8&»h‘°)óáÅ4'ÓòY-²q:ÜğÂgZTy‚tÓÍ¶èO¢h\ËøL¿ÕSiÂ`™º(, œ·E¿iö€~Ë˜GËşKìÒ;zòŞ"ãBKÂ–©Êã­’™¾D¨áÉ¯9 €È¹CôµÙì1¨ãDQó»Ã=ÊÉwª3‡¹·ÕÄ+U@»¸SQ¥°tÀØ¦c0:ŠôÓï×˜Sü”eWşC«¤¼ëàè¥êŒ¨·ÒÃyÀ‡üÑIëE˜‘‰Ñ~=ræA.Á+ûcŠvÂçˆ¼’O(]CWâR^«ß^Œ\<ºNEğô23¡ù]—±³sM<£Ôêpï·Î¡eÛ B¯z¦ÒÒ¸_dŞgñ"_ûÔ+aÁËğg~<]T®ÕlåîªÅ„›Şƒû zmáóàpŒ×áf§°f½¯®VF¸¯ÓãóöŸJJúÄPù‹7ª?®oìFná%æEŞ‘,ôÇÉcíàb;"6ëYæ$Ñğ‰[ı¨•¢™ÛİÅÿŸÏ…uä‘úÂo#åà'Ä»št$>IÇY6wLWô,ñ7Î¡-ëˆœ‰Ñhö¨Õ([
£˜Ø×œù¯[ÖsrLÄ7ÑHÚNV×Ô~/[g|?ó|œ‚*ïo&ßáGóœÄÓ‚o½oà×XEğÃ3š/ûÆ	À,iªäÃÁ+¹µ±pÒ2ÈœR/×Ìo´½ìå)l¡vùÓÊ:¡+úc+\]'gÖİ§]d÷4O3}|ÛÌ¬§/’H¤Oo#–î•úÛÉn·o¹%âsNÇ|F#Kc€9ÊFkGuqBH“w|TÇ¡agÏg¼˜¡ù£áwfã>f©Ü…ù.Ë–dµû÷½Îàzmü6|¥KN”ªâùHªë—„ŠÚ*6œÓÁùn³»7 òD€ûÂØ#J|MäFvr~ş¯õ»;ğhíğŠ]Ìø“]Hl‡•f­à7áëÅÆ¯ì }¾=º<òª5A¥,‚Ç—%üëP6–x Mª‰	[wÅak®jÕĞxP°L‘c6ÀëÒMÁÜ”;@ùPWtÔÔœ©üæ[î’L#¾MèuÏ¿'hŸ;Îæ;Û]ÆÈéZÚs4áŞÒ
·Ëïw²îr,ì_£Ä_Òné©qÛÉ}r_ÈZ}›Z0)¢ƒ/iëRô¥R@…;·}oô—„ÑÏ{úwû£6b*Ç˜r•g¹YÄ–çyÓ4ÙûB\2ŸÜy€Îœ´}Ÿ|Y—ífİ\hH¦¢{«ÏLšQ6=ı‘…´<¬,œ›¬XœŒÁRG‰¶¤ƒïÛ£	•·†§À}¶ÖÕ(^z­X#O„ÛÎí§všèÚÃeçóp¼şÓû„ŒkŸT¦ÈØu†åØ¼G`.† i„ ã¼l¹¨aí2Èğæ	‰¡w :1¼TYpñğSñ'ê+ü	ÄvÑk… î^%å³À>2 ÙùÄÌ>OLG²u…S¥˜J,
úÎS²5ß’ù²yŸµÕ¶ÖÜ—×¨ìs|V½ÿ  È›€ƒN<o}Ïø†#êå¯Õ—ûøÚ®â¹/¨~ıqéíz{ïyß«*ˆÒSÕl£ÈìÁwœ=ñÒ"ÃT‘<µÎvÃŞ¤ğiÚïv{úÃ'6æË³mqr‘˜#[;JôÜpŸ+U	j œÁÙ"Ltå_ÙêËEÍÅsİ¾“ª.°âÜvˆd?µ´ˆˆ9(	&´E!F±AY‰|`ê¬ÁèÃ5V5ïÚd\ìœP³ø¿má*BğÎÊdyÎ²ì/çÕîßY×<¡åyºû;Íäèª«7šOA¡ºÛôç"%#˜Ï£æ™C‰æ=¾µ]qB”½M^·/o•€¸v©ÒÖ{L–B´”<ˆL6ĞÖÜ÷Â½‰ÿæ‰,2Òæ‰nê
Â`c>ÕäòãaÔU¾4FÙlf}lû«ƒxïêŸÇ¢h*‡«(†Qş(GO	<ŒZôy¼™A#Pòô»r&lFŒåP\t…O5sŒh	nMfmL¦Éş4Và7[H%¹–‰ß¾1=ƒhç5À&]§îeÏ^aAÏhµû”ŒåÂJÜŠNÒ¡úw÷Y)‰cïş¨:ÆU÷Ûy¥[ÅîH½¾´¬ÛSÙ8ş8ÅèE_UZ=T‡’´¦H÷AJœDØVášÊÕ—	¬ ıWÄ>8uÈÍ~&ñ7½ß <¬N¹{ĞvZÿß¿±š¯ÿ‰•Õ:'ßj¯‘ÇØ>ºÜË(ìĞ§:L ´H»ë¯Î´‘Ì²™÷C_A,IÑª†»e¾ŒÖà$¹Ñ 3–Š#ËÍØığq³F†jëZ"İªÑ$ç ~øÍ ‚†â{ Ğ­–ºÑœnƒ¬ò>;¸NÈ,mD<:áªKZæt[[üà8míºÕ"wÃ¸+\ƒÔ¿”µ¤°8ĞåŞîĞt÷ãU?Ñ N<›Ü_]ªr{û›øk‰.!}<NTqía"
‡íºLISíîY«¯ø!Ÿî“BÃß#‰é’’[ì3l
‚ÔŸ’BVo?\H‡ğgév9n>ÑlfÎğÄ)eÿhºÜüæ%ãŠR5´ İöŠÜ[çz'÷©¤ÄŠ¢Šç½â»gúÌğ÷¦e6ZÓ}NåÆ-AÂxğ:Ä;Ø,aı3­4¼:¢Éö(şéÆì^é©©ÚÍIH[°TáëüÃŠ!ŒÊ‡/ì‰-ìSzfñP<Ñ»vìÌˆw‰DÀğ³É6®^Í¦´ÀD€ W%ŞÉ,¿ïãîKğV±ïâñ‰·úp¼çšÌæ"”¥è¿ô±¼«xkFNúB?ìhc<X2Ú6y³QMT¾cú‡®qÌñë©pŞà¿/A×lÕ\¢’üÚ’e“Å¬'¼G$4õ*[ñl¾ŒÕÜ¯`M?pÒCµvJAÿ¹—÷+Ù}_ú˜ù0l>ãa8Pò”3&lDçÇi´e%ÄÜLs3}âcI!íF¼r’jRŒŸÍ:õOdaQ"ñ,®d§7XlC%l~è-çŸq¬Ãò®ª»ìé*x7ÜB;Ê?ÚÆ×H¶–á,;-m‘-qFÜï¯UÒ—GÈ‚¬kLòãr@¡%{T¿¿ßşÃ±pN*àÀTA¾¥‚¥Æ‰†ô†F@”nBoHâG‚šÍh¾#Ï<Ù	;t4^‹ErşÔ;ŠèçnZŠI$Ñ®WDAŸ•Ğ9åÕ'K[B¶(XiºÌ‰`Âöïk4ó+}æM`òîXõE”ş`‡|Ğ:•Aıˆz2^qÛûÀ€ÜõgóÎËçŸ)ñ">¢ZóxIH€^ş–S×üö0;kµI¬áÈMìš"‚ÎsR¹K-ŠRÜ’Õ !#ÉÉ›+IbÏùà\0?Ãj‡şÂ‰"ùŸ²5-­è#‚>y™’~ğÿş}7pà¸Ø&Rj”Dá50<«ÖÏ”ŞúôÅkèé™ò‘)qG§(8T,P’òŠÚg/ÓL?ê¼¥¦¬ël÷Û KüƒÆ}³rûÔêò_ty7À˜Sá.Ô'!Kˆ	c:´İçN;¾µÍ‘F {—áĞ• 0ìˆD:ãÌF³!ŸwÁáT›PÓª§§oƒ’ÛyÉ8•¸kdrUOÅNÅZ†Û¡-Õ‹¨•×{t`›<áç=sì\Úäµr·øĞ|äWº¹7‹=¯2²‡M^ê¸%0ø¢p6¯K©“KÁ4³SÜ\ Kşx|¬ÉuOø;ÿ‡n°P«æ²ğ†R¬éTÖJ¦½«BÂgW<—’Zz¯ŞÎÀGO"r—×Kã¡~PBfTš‰S„‡„‚{ö 4tMª”
äÖ4j½R­ppY­®ë%Ó- ~7Ÿ „º…ÒÎlqÏ¤H?¼„üm¼
å¼YbÄ‡hú…@æÎğ:t2·ı“„Ø_Äv\£/ş%FıÄ.`ìm—M‘ÂFçÂQ1Ù´Í'…Ô&>ìÔàiT GÅ³\óQ]äÁSÉÎÜkäCLÀşR¹oC„æä¨3¹B¢ —tôAÍUáhE†
ßt¶Qj.–sjê¬ÉZA¦R2
®o»–û;¯'ãïæ•>ã¯rbQñ‰l­›q665ÒĞè}Ş×ÉÛ¤îĞdğ%øî²…DƒçWWÚ _´ÊÌÜvJzsèPº—x‘-â ^âs¾ğêŸòdËp½µøÔæº_"ñß¨«B¶[„Ä/0fZÿµè|—• l¶ Oô®ÀÃ…´D•w>ÁÆ³¹CÍõ¹Éâój1L0ÓaRw3]5İ` Ï«ÆAt]™—Ùvñ–ÏîŸ¡ı¶ÏŸ£ÒñP¸šÛ9Ø4´e*|ÙC´v^>[—06Ñ‹¤2¾µm7[ÊtlyX(R>[kŠŒ(Yuüòl:Y%4Ô=ıõ6Æ™êgÀ’3“¶Œæô‚`Şä-ÆhNçÍSE	Æø÷ˆõP€†½„vé½è\VÔ1_İ~ÿ9şÊ•etĞ1¢w-pDÊ©tJû÷WM’À,-<1Ù'_…ü2ÍıĞh‡<c"JC¥‹=ôÀQIrqFªºÖ•å@Ñ <¶È~¸# 1ø <åv@ƒ,àê‰/9U°éyKw²Ï»—aE‹¯ÑëĞŞ
#cü]ğ\ˆ9Zhã1sª/Ã‰¼¹’®h…0”3‹Z½µÁe&¥“ë¢¬Ô&"·›ORúÀ
9ÅNT,ŸÚ]Õñ§r8\gÁLp³’4<‚wbğ8…Ã¶_}
ëÜNÕ”æ\Q¶şø•
‡’•”­M[¯Î0ká63:ğÄ›µ^‘îbY¢íÀ/‡?'ĞöS“+.^â«¢uëßûÉº_ïbC[ÏU<š¢.Ó%GÍóÌ%edƒc¥Œ>ıIş6f×ì{ ¤ O`0H$h–‡-]†xø+jÓ«ThO×õzçÖqºx~›l¾®a^±íü{õÂÛ* 5Ù¶Ñ¥ğ·éÙ¦¹ÈByÈä•è…–¼ úO.6œ¤Qæã5\eÿ|á&„7O]Á¨ÙG$‚æüK¾O>2±–'²dGå–cß«´Iúè(ƒÎV‹Àê¾ô#a{`š¡¥oª™	öİğ%¯@_â:S°bÒL¿ÈÀ›S…Y¨5ô„ÙJl?µÑ“''f7cÒ¥gu}úT¿¶j#+õ#¤˜€%J÷´E¤VUaÊñãO#U;	”ZkØÑnõ›	ÏÖ9«¿‰¿T/ÅXl––ë-®ºº“6 ›pÜ"¥FÎ´d9Ñï½6^k¾º#×:–›>G«¯<-¶PEÕwBzğ<?^zÑY4fé'lqã4Aå°j+‘{øt6x7õH ºHßçü¡Ğ Ÿ-÷¿Û/{£’G'n&ÜX'¦ŠÚÏàÖ&o’J·€Â9Ö¹Ô¢?¦AÚj4×‘SÕ´`~õ4,eX6^X½$èALtM
 Ë[HĞåÂSêëÔK[€$¬ß}•ĞMêàZ4£á8ºôF†Òè ß€k‘˜—™qNi:Q÷Zoã6ó[¬)Yl+¥šà›dˆ?®¹—aß£À‘UG}ã¨[J mwOY=ÔqÜ¬ü¦"Á½ïÒ<‚aŠN¨ÊÍüæ¤JLÄRè	r)}ü„öĞ0îÍ×Ğ£3Iğ®II™ƒ£ä÷“©©Hˆá€É·³zª>CJ'DpóôLÌ¸6BÍ,è–{6,<V©‚â1Ó×‚á„Šë¿®Ù!¿66±¥°ÑÚˆPv:æFâ#–k/‹\ášA9y*Y#4dìœì8uïí¬ïÏ‰»Ÿ5©É×%ş¬&\ÿÏµm¬c³UH9¥Œzå¿ß»Ù$%~J§LÔ7©µhz»Ybf·2ÏvaL°¢¤Ù£Kv›Z‚Ló	z²5™
<˜­ı;YoX)?SÑ1nwˆb¹†şöëôLÔp5Á
ü¸{´š&€sŠßK!*gjØL§¿Gk…âÑş+ÃÔxïßäw©úÛE¦oe{BnØ-‘p6å¼âÆ-ã }+u~@zP[ğ¼2ã}åzÁ‚©ü h(?Çk5w)âÜ2Ømw”äuß5p0¿ÜÊ­Zfá?‡è&æŒ…½oÏ Û°íµHÂ Îú7Ix.j»–TÄ	ÍØ‘o}¢C•»â2m°8•µòşæa9p“»~Âví6óÎ.\=\ÀJ’ÛO­²Úß
ÙB¤l&z(İù_».NÒæ+%æ…Æç3‹iÓMCÌó±ÚısfÇ­14´ /hV«µğ(ñşô‚óh±7Ä·7ı#`n_T§µÆäƒƒ«ÌµyW®
Ø:•Õ¾5‚ Ò¸l6WÙŒô"Ä‹,°·Mtı}ó=`\¤İŒÃ‚Ç<z`ÈÈ«¬[pş¼i1#A¬<àÓ0Z}¥Íf_“nGø.Òş®Ó™=19ÜãĞ”Î[òŒ¨e{cæ…Õÿğ5ßeUşÄÜ8fäğ°Öéõõ%®µ‡-Zg”Lì‹øœõÃ…É÷¤âyu.ERÇ‘w¸øïº	s™78 $Ñ»•RTJ¦PÁgwøZååïÀ‚Y‚âığ™™ùÀT¬ÜÓ©ÙI¶YbáÉ2°QxÌ;	ëŠ oÛ½„qE®4ğ*ıÏw±^Î›»ÉÃ#Õn¹©^­Ê?@æìİ2b\ı¢Ç!KÂcmJİ·¦Åÿ3O®khÕ3})ÕÓ²ÄƒŞ¬hùà5Çøq>Ó.+Ö•ÿÑO¼\_)‰®4şÃA¦(îßà®^€­ 9ÆàM‰Ğ¸1ÒTıpò«“q’Mßc\¼Vr‹ôíEÍÑ©ù·rákèê:å!ïão\É¼XdW&z:®Êç
pñÊ~÷Úµ†ægº›QŞ…ù³$ˆÀ¬NR>¥‰,F0ğY
}•©ÀveMmü¥©Úš8ˆÓ^ÿ»XÒ“BSûnáõoÚÍÇ/fäDÏÚğÜ–&H¯¬Â˜ö&©µÉòó&Ë×è©¢}İFX§Ü»İ(uÓcùİÏI0N‹Wå‹ŒÏ¡ÛÒ7F.Ş•ıôV¸ée¢´ùŠ/Ojßáäö'ñ;Ò­l?ÌGÃÍI'¥tx(TOïÕƒ3°àŞÉî/kruñó4X–ëÀĞyØu¦öÃKïH·EXN«Òİc“Cû±?T~`Æ—jV¡ædøIìx:û¿WD[¦tiØ…·@ÍT;@ìó.²Ê)øgã½D/îk‰gúWÚê„mœ·ŒKw¼'½+h&´V&K,zº·öFEà5ûTşF²Á´ŞlpëeRDê”F¯ÃÜÅh®ï½a¬j+3jNˆ¹üœ+RÇû2È,jèSÃY`ûûjN©9‰¬y!6ë¥B1‹(é..5ñÂŸÕßù&ÀÈñíÄ	©=ì×Çks
)|µ±}ó·ÔÒË¤MBÂ0äƒ)Â‹	zÄjtXœêÉ;CAúC´|<ÍåÍ vLŠ)U Sä,Ümgåâtë/H.…‚€QjÙI«Ø
—›÷|Ip~¨lOëoÆÖÆ;Jîœ¢¼¥:‚·Ëçœ„¦Õ‡éf'Ø.8`W–	Ÿ1şïê¤w´>"ìw|ëÁ¾:é«µºÆrìÂùâ@?T—IÒï³¸éŞY¢•¿¤<	ÍèXr=`Íÿß8e¦¢±Ä3±}èÎát¯µĞ9Í¸¨ŸúOêjÀ,ï>PÜnêj/¥	Ãq‹‰¶ÜAÉÕ–fN*—éd=^‰ÊãH;¯NüZá2a–%C"† }wc”NÉßjTKÕä´rìì~Çëußúİ×ş
/ù£ˆ µWäGy+U·ÍÉjkIà~ĞLÜQ¿Píèóq™¨Íz5Ş}6i´Îˆ&ÖŞ™L` ¥Ë’Ê’Mæ¨¢š^ÂífÊké¶VdÄ?8!©WëLù Vû`…V˜kiêæ»ÍoW©(dñé¶¬€š6©ñì³iƒßó¯eÏµ0ÚÄ>ëà¸oLog³7†ì àÈêÚ×¨ÜœæÙ|ŸûµánK4 Ú•û¦Ñ9AÕR™ğöAy¨kĞ¯…Âİ†€Óş ”Õáÿä·Ù=UNyëqädœªjÊ˜¸ ÄcôEoZMâsß‹iIêA7­MûàË/íÓ{üš›w7’p†T¨aš4¸[ÓáıÖ+TítÃ‘"rÎæ¥†ÑN¦¨†S¦ö¾z>¡buŞœœO24ÎÃEÒ÷Ô›gîSdœ½ùÉÛøŞ?ZÔv‘‚,Ô®‡)ºõ®Z­DúÂª=#¾ŸÎKWò"?Êâ7”º}{’!+™µ ‰¢ºˆ1KBÙ8,ÅÌ[ç4ËÀªuM[Wß¦…PIêğçœü••›qíÔÌĞš~“[4 [ÒŞÏV$˜âÒõd~ÄĞ[ğ±œÉ@áÇ{ÈÊ¼
IÒ3§ÖêpL'AÕÒ²7Ó(c©îêÕyùõ ù?;¼DN5s@^?ÇrökTüXé¸¢^O\%ØÃ¿âhŠÃƒ™.æ.u£xRS}²L`ur¼õ‘óø pòIJ¸Œ57Ìq…P"<÷¨ıñ´{_ä»'P{ÉC×ëHóóZ/ŸŸÅ<‚·wS¢á–dÉóXÆ ËÒ¹ÜÅ
	1İ«ÖvEÆ_¶¼i¦á;‚{ºxtTèåU‹¼1ukò,ÊåàÒAUÌSkµepİ%Däk+×šF!œ^5äûù4Ë”zc:[ôÏl(D`›p‰Z[áJ¹
õ»Ì`Â6‰ÌŠ¡Ô@YŠ3â·ª$O*f&‰…°¦m¼•Î*@‚?ÇW–¥Èï]r=Å–‡ÍøªV[I™úº`wZ(ñ-Sdyd¡XÈ™f–
‡Æ…~ó*E!t"Uu‚]ˆ¹•Î*úˆ»Šn·.
I”?ºü7Nu+7ìŒrW kÑón5_²ªİ[Ò|ê‰YwHoD5-ÔÖó+¯È.ìF­ßå¸Ñê&7„$:}w¼“_Ã(Q¦´C+¹{xüµ¶£¬¤Wk¥M–%w½7Àü–#g#è»V9lzH` ËrÑé‰1¢¥ìFŒy—3òå¬ºˆVºnNí8ûıÊTHß¼üŒÛªG%Ëƒ1“?Œ)~á<7“ì©[ó÷`Œ‚€h<uaiôÉn;SN{[}x©<İ×n j_Ù‡Ã3.:½…´7 +)k¾†s<<spMÛ¾Òò_·˜òÊ×ê•ÖıWu†MåıÂá‚$ù,hÄz\¬àÒ¢¬¨—8ArÄÆêú5IøÄ´Ìhä˜Vß¼pöŸ6ÀfS¨ÉÃ¾#ÔO
^·õI‡PSk-B"kGöä7ş‡Œ£}”>š–øfÃ©¹”a¹w›_ÂıaÏÜÈëŠ·ãÉgõ_ŸV {±v£ö}èô$Î…9	±‰ÈªtµÔ«ÛaÊÓ4Æø…Ó”bMSª
ßBiüÇã=(!’"ì%-¶ûj«¤¢ÿº3 Èş×U—¹¿O-ÎÔWÈRëjpPÁ@‚Á¨FÇ¿ö{"ÿB[æ'†WzÜ¯j {r‰)ÕâIŞP™<,QÃm_æ_é7œÈÎtçMêİË}ÁÁøÆ¯s1*N6–¾X¸é¬S,"©ôÔÀíí«ÃÎeJ²§à.Ù–İÄˆşæ÷õ¶ÍƒÈE(T¼gêãœú4H†&€AÌzß˜o½ÔÅ’ÕßÁ€Ÿâkk¹e(B`P¯‰ÊÀˆw!Šº%ä[rñqQÔğGş˜¸iN‡/fsçÃ~È%5Z²òôüßeƒä¶‘ºÚ—¯ÃPGİ•ö-ynöågr¶–ïÛ2¥8åØÄ«¾wSÉ^®AY+j¶083Ò3‰Ş´‹0ÿ—Ã8ğĞc{ú$w°¨o‚ŠÌŠêÌ¡rJ³ãÑ$¾¹5”äİ¤ÖóÃ™}]ÚçôEOU
€ßÕq0¯z­2“(-EÆ£4EÈ™,>‡GË˜EÎe>k¹İl\{’ée4 …Ñ‘FÍëFñıäëe°Kd0¨rş6+QÑ¨OÉÌã&&¾ÃÃ´,%òægV•&sªV+¶Iİ4°œøÛ+1N?Ë·dÛ^XŠTB`fm‰=-6PšÀË.i)zOîq¥Í^:ñB.3Ÿââá¶ÉN¦˜;Ù©”D
		éhX’Àçáß|Y~õóFz*U#-ù4làWlÜ¥G•£8ª~p9`»SwŒ$k)á(—é7¦¦™‘¥¬|Eî`¾SQ¹"õ8Ç>íÎ)Á‚&…ùAÔÉ®, ¡]%t
&‚SZÂŸÑJçù)U€üo3ªL¹GœÑğ³ ˜º~aûŒ#èÄòGù)ç@
·›9­dŒ`EĞ[é5+G!U} ”ĞQù¿`ˆX»xK…@°K£©>¸ÿ!Ğnd"ò™×©Å»õ ÊtÍ3(°ß„¿“Ú™Ó¿ÚùûÇç„“aCáñÂîW
·ˆY7İÆî£„úòŠwJ4¦k’mÖz¸*'_ãèÅÚÑ€FŞ4@Ì^où©í¤œ€fØû/Ô]È“EÃi~5LP«¨ZDLäNß[mÙ»šQ¬ñ…2•Ø[1B…¾’«½mÿM-\kY$(ÛUÉEğÿ”êp%¿Y¨^ÙêÙj Ô«&Ø´I’?8+pÑùJHé*Æ‚J .sşèĞtqGÍaÇZDH©ÅÓsáRç¢‹¬t1Bgš­ò¡+Xâ•8PÕöu‡’İ>utş(¬ßµjö(N£WÎ®-õ&w¨îmJšÈR$éÁs
&è}»…wpÎKîQ=;9cºÀÁlÚè^‰¢T 4ãlOşU0ñÀ1cË“k$h3N.JğjšT§Q=RöÜ6nINê	¼áàVhOèŠ-Ÿµp(çš#+¸Êº%’î¶ê¿pûg69u»Ş]cä×•ó‹Äÿ şô¡aÌc)Û–uZëVânñ‘~~°úéˆÌd˜ÿö•1½W˜ÇJ.iOD}H¨ÀPu°½$Òfzq@cR/2¹ƒSÑ ìWxZhŸ”p˜Ì¯x«C’F„*ÀDipæé“	7¸§7õ±ñ´b²Òu“Ş®?Û5›ƒBßé.=šwç´¡'ıĞÉ2ÅÜHĞöÆ„ws9¹+ó'eÕiø{„[MV¯g%Ñƒf$†¤t¦	À§ŞÖ½q ã÷fÖÆ¤î,ı“Æu©VõÙ™ÎO&AÌÂÄ¥§’×‹Æ–tsa-ÎûÜYIf{ ½ÎÜj·~±{dŞYôén÷Äˆ-oå_pVj²ÍMåÚbõ>°aCÿ†[d,V¨J#X8Wd7dà_İ>n3ëYH-ÑYñŒ,ëó7¸=4*QÍFK•)D
áYñ#ùò¥+º/£JJÊgg$D¡Wjhj6t¸šå«§“şÏü~+‹1y}^ôš$‰+ÅmLà˜Ğ£ÖÉZiä`¿J}†6/³] Óx¶@²iQ«l#Ú»ìĞó¹kàø¾¼Ïµk	ßxDE0|ÔCeîÕ!¿Vo;%&²-¢ÂÃóy”©/æ¶İ´Iä+”‘•ïµšX3ˆBõKšQov$ÀyÚÃ¼(ìµà„ô
»¬ö‘CíQPÇ(K,ÂL@+>“L¹Úİê}E‰<A~Š¦¾„ÍÀÅ×ÛÁÔçÎ¼ŸÖåI¾üLn€„÷&†W™ÜŠ›|†fÓi§£7oEÏã½77Ï¯{Ï˜mÂÁ«UÖˆ"Âî/£#¼Z/}k-5Ô0=¨RÖ—³ æBÃíÈ­CJ Ğ©9M»¨¼Ö]7Ë¸5Ó°™Êd5 ]$ÇÑæC§kşFé¼Ñıx¢ø¼àVˆÁKKÒƒ1ªÉ®­b7«&P™eşA°s|!5´2“æ—~V‡vzÉ$ë¹~÷´?kcË•5¥“OŠSŞ&!ñ'Qn«¶F\rS˜ £+ß¸Øí64-,@›­“Èís#£Ş5ï¶ˆ·„-)¨¥Rşq\XĞÂr’Ãa;ÇsÌclüƒ‰š”*xñœd“Ew–»-GfŒ)fk(ˆá­N €œ99ŒÁŠ5ú·ÏŞ/I‡5\|%ë´Q[UIasmlm½UÀöh(8=-*İ+¾R
Ù¦¯Jšœ¼käŠd,äGÜÇÊ2O«u:ÃnÜŞöˆûß,¶IÉf±­©Ë;æĞn«· |\0ÿ’ø £S¢/ $Ò™ì%’j1Ãx
¸$ñøw/÷æ™.ôpw*ÂRÀØ (Bğ›ğdf¯¹‹ş[uğN¸•ÊKåcv÷('¿˜8¢6#×=$¦³gdm`¼·?œ¨ºbÊmrrŠ#¾ö3iä¶s‚n=ç}öæ3‚¸&áGş>‰q)EAÎËºí¥MïlÕ¦·u
MªC8¼,|Ú–<éø íñ®×ûìøˆƒş–?’ï¯ìN·ÄZ1„„¼õ8>HÁÓ
‰,_Å—iÆÆjÍé-M¥î s¥K‡ÉÒ¶È÷ÔlK¨2éøS+„ÿi‰™Âúl©¨ìóí›²»§ê,ú‚ÜUŸ¬R¢ÇŒ«½£Ê>÷Q.ôu’çÉí¼³¥ÎÁ:ôà z{-N\ˆÌ!ÜçV¨Â‚„ÊÃÌ$÷ƒd8cw
¦ésğK°T!ä«KâdÎ\@MnÓ/¸èê† ’ôu=Kt‰8·w#î?ÅæËìF¸¤Ç”SÔ@ùoñ\½Š(`K+EÈÎ{u¡ü¹ÇK1è0n/5Ê‚»“di^&€]
áİÌã«3ãöu×À!‰21	ŠâµgÙˆíälDHvã¾äÑNúNqµ!§Å/ªïØ¼(<\½¡®ÀMúOäÄĞ-iSmVĞ?sÎ¬ã(‘r€‹#Š¦PÀ;Å;õÑ.W Fzüaú‡àÔ Š^‹N4*v¿’µM´ò•˜”»ĞOÖËlwp@V¼ç,áá•<ózJŞ7ÈEk™£ ÿ«ÿTì®GùÔejƒíÑ€ódhPröçé¶ª¥z	0ÌÄr$õcg:á<ïÒS@å®Şø¶ğ¤"”Â )"YmÆòvf»Éô¢„ÍwXaoéÃBF9À©ˆEû±Â‰uê&—.-¤mğ¦mêwåç&jq¨gî'•ÊÛ{&¿9“…{X#–Û«¤É+*é³¬º
9´eË34àú]ö<~búx/]÷_ğŠÉéöWl±¹¥l¸ï£E¨~’ïş~Ãw>ü—a7ûPÀËs†ÌŸRµKŒEĞ.);$³Ğjë:Ê–©$€3Ö™1Æh>'¡ó`Á›Ò¹q£îp;á·£Eq^Ûİ@ÏGºˆIeÛŠ/
Ÿ‹–Ù%8»³5á¿×‘¥G'OÓJÏ+x~J$™Ú’+¾ò¢kÜµ'Ùè²)\–-·šZ¿¼TÑr—×h£¿ÁhçÃ_šö·oğe*R4Œš…â±Z8¦®tãÚYät„À½ÿCì{8½ƒ¿á©(vPqù×@Ş/ÑÆ0š~ğı‰‰ÿÎ…Îë’~IIQ•Dî»ˆÉõSs+Ê+Ì…Á”{`'“m	¦ iÎİßÂ¤REö¡p$Bÿ~şı3MùÏr7€©ÅÇPRoµúÕò]ÃB¹±ç©H‹@m6B–^™ù¬’)³ "cÉ¹BÓ~ÅN^DmFpäÛ/ü4¡IÌ,¢¨Dü‚i Â‘»ÿ–OWÃeàİLïU”ñ\_Ôõ(’'\º>„MÏï ¼\Ş˜0Ó`d¯… †ÊŞkLĞ˜rŸw³ñ F{†ÿ#-ØAÑ}õ’5fŞ\cOÖßï©çã¹ ‚ú·¬"-¢<ÖE•åpHô^ í-¯x^¶c¯ÿøÜ8‰“ a1½\ûzåª!»Ä:*]‡OyùH¹´¢:•òQÛôÇ(íğ.@Kù&#oáVjú[ÖÑSi6UÊóêXØ’Áï[İ’…yg0á¥L«ÔúvÙu°C‘Ÿ^ç™=ªàòî-Ô¥«ù_FÌ¿ŒÙ½ÌÓ½6Ú‰JG*â4ò‡V×.˜—’‹±5zQë’Ç§½åÏuÈÓ®_C‡_7¶‘ÂúçÅ<yÅÈ$Z2{˜Z.‡Îåç“
[¥¿¶œ®TP…Ô4%~?¹æRÜ·_>mİ‘aË¨è²§¿íHÃsËÚI®Rä†ŞP¡L­B -ÛœZ¶áU¬unO˜ÂÛV+¡uç<¤æÒ®'ç"	¼È5§öŠZŸq8Âqo`Ó#†Y!JŒğ(ÿ|îİã*)Ù>€ŠÌGıx+8şkVBpĞËy”ÍH/…Îwò%÷r
à²[öYo©ğf|Ipn~šgØÅˆ(ÍA-õX¬ÇõÌ(=Ÿ(>P¹ï÷Ä–™¾›$³¸ÆÓâj
Ø†Wö|"Ô˜	 [X3ªï%Èsè– ¶¾±{BğIbôE ·^)á©¶ADó6&aÿ1‚ï‘}ÅúªØ§?Âe‘ÜB¬$æ¾’´Y’ûà$¢<ÊBŒUï‹Æ¦½À ˜÷‰^×+Â…¯|„o\A>b¸DËÚt„[¹n§y`kİÌámi-snF’sg³Vo¸Î¡\Le8µè•® + 8˜Ï“´'Ş°©!ƒWÍ„Î¥šlÔk3–•ŠğÒ:?úèê«ÌŞˆJ 
®T0÷s.ÍÙ.²øâÙ½gÊ)ú1ü\¥¶‹í¦ÊgÄÁo­íİ7°*¦d;!‚Ù`ÚfÉÑ˜$™ì3éA:½œÑ#ó”=ı›b€6îÀÊ|ÊCQª‘	ÀdŞ|üt¬„1[%8›bä,ÓÌNëUĞÎâêNªËƒ5(‹ºkçne´éáµa¹~ğâ_Ã”ó%JS¶Gåwn¹z™juä«8Ûôb3»Æ¡èÈ£UÔ{ t¢¼È‘àê½ıÀÑ§j-ƒ
ÿU†ÔÒ˜¿©§ùDØ=€àúe="Üû,¬ÛÊf$·a½ç)eĞ B*ÕÓñª·ç›†Ö¸$×ÚgGuIF½ Ó‚¿„¿¢Ş÷®eFW·’_9ùqL˜­QoyhîÁ'ÅÓi‚…,/Em;C0PÎÕ-ˆƒØu7‡™Ïæ!ÙÀÂPtÒBZb?u…I®¨TõŒÍÉ¸§
Ü“Û¿#„ş\à5n?iè8ÑŸP$Y¨ù·ƒİóph`¾Çã5‹gÄ/û'V]"*‘
~½ÚÈÖ w2*ÊCsöØñx»Ûv6eš8*aM!,Wh®Éïà.Ëkï¯.¦¾ˆÆ/ÔÙœ/ËFcâ¯³ø6ÇàÌ/µš%a¯.™äñûõÇï-@|¹Ht7rª=ò¹Ëúˆ;¶İ¥c† Áì«*ì/şÍ	.pïÓél‡(‰f¶ıfm[ÃH¦
oÅ–u3ÒGå=¿¬Mpí7u¬,ãNVú¬lKE0ÊÓ%|éñéCr¬œD‹áÚ3ÒÏ÷ÃŸÂÇxŠ½§¥ô?õØ2ñ2{Ğˆ}°`lØ’K†‚çˆ®Ôù&èÚ{Ë€Ğ¿3•ÄÒjğ À–CC½“ë~Š[Ğ\ğìfº‹J¦g˜d‹àA02§–ß|‰¡&G(¤*¶ãö'YL=q94óûıY¢¿¿†ãK|Çµg–E´+†\è7ÈÆIÅÃXô®R¡)¼’*m{_EŒhªFàÜëßš»-ÅíT®aÜmlÅ±=S¤Ìk[¨S‚×¶6õ÷ÿ2š«Ê„›7Cı/jW‰¾KDÌÉ_4¨ù6Î@şU]åŸ]^ÂRkƒ4Î`Ğš-€@fºs¾s?\h£‡ÖÍa8•¤™qTeéÀ¼Òhª[}×ˆGP¼âúîn¸€³ÄÛB7Åj÷R“ÔQ• LğUÓ…Èã533<®ŒÑŞ„.b‡ºeô-gì;³¦fİØÆ÷å"àè§Gqï„q&oóZ°“9çí¸‹_{! iÌ“Jµ¿Ù°
õo.U%Q–©ı}@–gÖyòf]E×Mİ&ŞÃƒ¦Ğ­t†I†I‰”¶èUˆBœO9£ó«Îò—°®–¿gn¸z¼êØ+Ó4Ïn,°z?âÁwïï"ÆñL`	üÔ‹`GO\¬ö]M6ºÛ9ÉŸe©äNPÉ>J1²h
ÅfkÃÖº™´?Ü§
SO {¶%úÊ\xx½pTàåÍQR@¸S³âcòıå˜¤Ñ’¤×Ì¦§äBÆe-]¿VN·îE-OY˜¿’öÿN¸¶å/ô™ÿ'^ËYØLjU	9ò2	;C×(ã˜—!®P”üc¥Já4îéÁ}ÔïİÎªuñ¶ÛğVl·¤ÆHO|(8vıu¢±1kÏVG3Ğ^Í¹†÷ª²º/ƒ‹ØB
1¥Ø¤òjúÓãZéoû£î×ñ@qC?½¿Ã?¼øgÁê)"<ˆÒ¼I>‰o~Hk­‹Îƒ«¢Í»2J[ç0æn´ qŠŞfFıyjõ/]lD? ä¬QÄDRS°&¶/S Ğ1Ÿc'Ô2ë±8ììh’íİ!aqø	,`PW}i:“¡Û«†Ô5µQv>VÚD…†>És™Ñ+×ÒéÑj–ez. @r,ƒò$eo€[©VxúqYÜu™ºà;3¬}'`¥`±y^¡k!Úve¯MÂlmÿÀ oWêĞî•ÿîÇÍĞÿj& MèîVBbd7Ø˜La®)Qò{M‡qaiÔ•?á™ë1Ç½qø®T³|ùh5B6ñ F§÷Bµ›,­®,×‘ šÏ´eIP+ òÜ2ÿ´+qîö–¥¯ËïB+J5ïìÕ*¥O©/‡÷¢¡
Ï±¯²äô2§»f^!çğ?¥¨M,{€! ‚&ÍcZ®`³a¿¶˜1û—ˆÎ<Q@ñÔìYÇ±_˜*,î4·ÔŞ±[Ò¶ßz^²íÊ}÷Ñ	+J‘_Æ¬}µ¨‡€ˆ^ÕïoÁR ~"A±Øfn¤(Éõ¡$‡I˜sBmmX4…„{¹e”,Zt5,*,À¸´óbè˜|Eİ_0qêPÃ.Úñ‰·0s[SMx»JfÇM”Œ¤üïÓ^Az;×X1ı¤qÀ	®u’®‰|f>œ8@ì¹ş9.³iAˆşvRo2”*Ú—ŒÎlhHİ!-ÔQà™øïÈ
™Q+ŠŞ}ziĞİDEkúŒ6Ì ñƒ[«$:ëê@>M²­<|˜C’’%OFê1×÷I¥2e0{Z¥£v[nç—ïŠêŸ[²aÒ[Ğˆ«X:#~ùu€¾‡Ğö
ó'ªÎ›ëÎ,O-µ¾yÁÎ°X2Ø¾N£{àw‚úrëQ^ƒCgBy\ÍrÈDÁœìíL#³ß®Nn¼)L“µ‰ØœQÈÊòš/‚	PU ò^aÔ’Üß|Ìä2?¤š]WÉ½+a½|æx&aÓ˜8Ô-døòw²d¸­•xB™½  tXŠ_Ğ¡5K\Ëh~saT“¸´ÜÄ§¡Æú ÎÏj‹\Pé‘øËAÙ“ŒÑ¹o1½¨YyBÈ¤OeëS¡Ú
wÂ°rÆ(ÏÕäş»TòÁÚ68T>M`Ë’ ÒÕMUˆ5[#A?&±ñšèéÀ\ÆMØŞlÈ„üöVš/•P:ÖCæ«5ş–0@»şÍG+Cš:ÔnGu‚ªGR^b:&Ôy`&/³Îù4ĞB]|ÖóéòûB#A&-Ål!‚é|N§ÀA1v½¯ cRë:ÿpaŠÀiúgi¢åÙ`5«…Sñº’Ï>²…ğÌË1©Ót}>_E¤K-Û¦ß?zùé3XÂ“ZÛ–ÙdÑâµ÷®FĞ)°Ù´^Ey7Ç£Ô•LVÀh'è÷½°§6­î$šÍÎ$âaõH³ A2·y¥óÕjSè¥F“¡¥„ŸAç/,H#EØñ</òQ¹?Lg¹Š–ÄË÷bW±_rtÅà»©á½ÜŸTV‘-î|±}]}¨D†¯!öo<g;˜™WO<ëÖcÂ¡œˆ Çï.qóÒÒ-²iS?`½{‘€ÄG*¢Îµd7S¸1¾²4[?»Üoc0DŒd´œ~o˜d†­1â*•u€‡[kR×ºßĞãÎšà o¢qr:YKŠ  ¹€À^‘‰Ë±Ägû    YZ