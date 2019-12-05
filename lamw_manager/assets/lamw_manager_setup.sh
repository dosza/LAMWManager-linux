#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="512633229"
MD5="37e2b955f21ee0f55c13ede038ee1ed7"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="19784"
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
	echo Compression: xz
	echo Date of packaging: Thu Dec  5 00:25:07 -03 2019
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
ı7zXZ  æÖ´F !   ÏXÌáÿM] ¼}•ÀJFœÄÿ.»á_jg\_~ÅÖô	†ä3uø¡Â‡ÛUÚœ¡9!şÉŠ2?}øØ²jt-øóg®á´“Ñ3‡é®Ø–Vs]0ïÒ>Á6¶s™j¿±‡ä­+jÈÅA\Õä$h€¿ø’T`ÖgL=Ëv•èãH©çXz®„˜\3ÒœZR¹79Åº—ph»ş?]©åõ{™ŒÒ6I:
ğı–@dË·hí|´S»¥ÿ¡ó=Ï?ğ$¡‘#šùîA§oK7QQi\Ù75ˆvuå9?Ñìk-]³a\=Ş‚î€XÆ“L¨‚J$•e# ŸYiı3ıª˜dôYØ!?OŸæ9‘K+×8¶LW—;šxÏo’p3 $¤Âœâ\x~“ã4¢hŸíx¥TEd*0N"·)ë@S»“jqÀTœèï\Iª±ÓaiâÊV¸§‡«›Í™¶˜h
¨3Ş9¸Tµ+"ümõbÒY1ÆŞü	AU!_ş’ùò ,Dç¼ÅJĞˆ‡ºy‰İÕşaõ¾/AòeJÆåÍ÷õo¯ŒHHHtê}ùf@œÌz÷çè*œq¼H—:qÈ!•ÓKÄ>â R_Û)B$´–xßPZ›%Ó7G£I¹aòæÉ”€ò‘¡@İJë[D±%’ğÁt¯!éÑ›|‹ß-y™ïq]¤ıË~^ÃA‹¸M-ß=¡rÁh°¦BûP´ºğîÅ5ÆÑÙWùqJGÑÑ—¦8aş¨ÃÃ…&¦çß¨˜Ê=9nJ‚µ3 ®U˜m~ıëû2×­<¨™Ÿg_™Vd'T¶î!Ë>ªó™wÉøLQ€|aï‰s)mäH…@nPš¯ü¡Î¦u-‰¶Ggš5Ú4
¡e&S*wöDù
w÷íw3Wş%ã39¿¨pÛ¶Î®Óã_vLº±‡Jcˆkz‘PÀÆv~^u'•3¼9c;¯LRÅİ‚e¿«&“'™|w·£RÈÅ+™£å‘I” ¸Šªã¶#¥4ºCHô'ÔÙ¸@¼ƒIàùi<}ÅÉkûé2»z5ÍZ	ğ/¿'8×»sæç¹â¹M‰\Œ4‹8”Â\®é %³7m	SºWùõA&,Ş¾í¹u³ñÃù’º{ğCvyxÁÜôÀó=;‹‚ç%N4?©\¦Qb5Tô†pÊ]¦Rsx·\Ê˜aVD°_4ç–\ø~­æe™¸c
l3™ÔÑ¡äØ€ØdØˆ1,EoÙ|ˆ+ş¶üq·fqê ëğG‡™mŒ¦^ã0#™ xÒÕÑ;QDOCx¦û$´‹×ÔÆútOxÿ+êtxÍÊÎ§‡p	|Ü£Vß9Wu^…Áo™K~Y$0‡avŞ#wİ€r§cI!Mhv¼®¸pSÄ½?hÄ‡C¸mC™Á“'ª)Í”ş‡>á¢BèF¬¼ƒÿş 3g×:‡“`”Uçè®WW–q¹E×Lp‹—m"Ñ¼:_áJüÃt1P×t-eG|S È>\2}{á•å$<fh!ßÔyx¼yiC1µé\‰÷dªÌPGD¥ÙPBÒiÑıæüùù[áªy(qB¥.şK½^Ê\ÌóqÙo8±=/[¶h‰ß( Ó:Aı—+¤ñÚâùš„üÁ}ğMJ‚¬i@cÃ‰˜Ñ¸h¦Øş¤‹?†óº9i=8_Å¼—Ük±öµ?m‡]*ÆNa/%Ü7eAò†ù•ÒnWhË5~´ø4F—Mõ©Äzw©‡7Vˆ‹íìf]ô
Ø`O`ŒeU.§Ó”(T cyÜ*óEQyæ½zÔ$Ó]¾wômøÉ§)ì¥ÀTªæ
Ã¸VDPXKh#³šrX£”‹ÕB5)	quĞµÏâìf|åIˆA»:ÅÉM]¿ˆ†™3À\áX0šå·´Ç£N/FH»JY6
Iè5l–YlZFçtFósóÉQ•Ö"ª±ÒÍ‹Ÿ0ë³¡­7éƒ%8w°ÉCTÎ2E$ÏDì³Á–‚4ÂÍ‰%S‹5À×ÈÈïJLæ^*ñGç½üyN±¦q¬x$XŞdTÜcÉZ:Ú_Wm û0ša ->aÔpÎÈóD©D è;—Føš†YÃwcyf(ß =@Ôx.T©Ó›°ı ß¡aFÇ:Y®ùÏÀ#ó/f¡eY^3z¯°Ñó©¿~/µ=±_ôú¡ìò\¡uÓárïßØ*•HÀˆ˜‰^öß€ù’u&s­ûcõ²*‘¤Ã®l.#kã²åˆ9AıÇÓÑM±3¹ş§ãÎ,R1Ã"ƒPğá–x@²ÚËé?µÿyØ‡F[ÑA|0ÑÊ}2z|nééÚÎçíçlÿÏ—­Ôü¬\«çü?![J8É47¢ve˜¿Âó@>p³ôG¼íWÁL `p	yİ‘Ò)P+÷éåãäî´/mji’´ã–â1Ÿ.‰¥C)D`p@ÛG¯‡:ŒD[­%è^|áËa@V8Ø5'ºMs2£%L_dXXïrr…ûÿ?âø‚î©ê¤ª]Æ„¾×­eåùÎ‚`†ÛßN(FWdr8ìÍ£Âçr—ç)Ãyî•¼gJ  &RÿC_«¶´9èÑÄıN¡ñ,²*GVR-[&öm@PjFº¸şdĞ˜õ“QÆ®QÓ1Y¦2Y)˜°‡"”À¾¸\ß¤É36Õ^^¾Şé½[¿ì)áÙRŞ;jİÛÙ„­)je®bî–&2duáS
ùG~©“ŒßÉ•ç>‚šTyÀ¦ûâ5·qí0ÕÜ¾»û}_âàİœÃ cşaKÔÍ
ÙïŠbª6ø)n¦Ò@¬íP#¢8ñÈn˜ğ©vÁŠ´-ö	Ö–YQÆÛrê¬.Ä›b aâ|‚œÈyûù .ó0ôÓ™° _Í®za‘"B¾ÉıØB^SlêÑ¸ù3£ç¿Jës‘áRàë¥¡›®¸ŒA¥í^n£Rù¼¼ŠØÇ3©¨,n¯ñc)ñ­ğÒÇŸmÆ†s(Nß]Ò¥IëÉ;—	j~v 7VW/N¶bÉ¸µ¸ÓHˆ-Ë›,.¸™B}z½,}?­Bm¢{ôÃ*eÃh-êÏY–dŸ øŒÃŠ;ÕŞW”¾Øç
€áåñ!|iÂŞUÌCôb£«_æ?ë{$)cpj¬@y—9©Ô˜Q5”Uîí~;“€œŒÒuqÀ}4<ráEWMv½š|˜X€fÈG¹<ldİ6MH<p°äÃÎW!}˜F@eGe#˜šwâÉÒ$ÒTfâæ‚xô;Céèoİ© —ÛÇ>Ÿÿ¸­úˆœçe¶]<á~‹¿L÷ájYrØWB#ô+Ä°Fp_JD _ğÕ‘³Ğ#4£#Õºï8*7nÑÕ^_ƒNRx¦9§„pôÒ«¸Ø×Cıüì×;… ´æü1@Ğ¼€\JûÈÑÔã»Š‰V_€Šx\>ú.Û`·¡LÒüÖ¦´¹­ºæ$X;7­ßDai×´ƒ¥d"QÕÄW‘6Gæ™mÅŒè7„TÈnÚ­bW˜YƒŒÆ‚x8ëYĞÁ'B$b7h‘ôù{E^ñ²˜À:78OJŞ×ó]œÎ¿ÙK†L
È­Ä‚ØÉù¤p&¼D%z¸(d<A
øÜXL&>ë²Ï!p‰×söÙ0rÇ¿ÔcÎQ9bÒ³¼^ãÍ¶ÿ¦ôĞã±!koß“ÃUqc¼
è0å}Œˆı.Å…8‡pyèÏ’ã ™aìQo·İd7¢oÛ0¤•œÜ^öNm;ô[Ôş˜	4d½lÃxAªó$k:¸Üp‰‹eø@ù ÜÉ,c¾¦•ÿ_	òåÕ‘áGq¨2S Â÷¢¹ä‡	½zÃŞºBº_f¿4ws¾P±Ù­Š:š±·ó@É0¶]¿GGl+‚7¶
ÖIX­ËA‡ 9*‰u,}Õ8Y°º¼¼Ô>§3îº³Fğ¡¾€"û$‡êâçY>X„»“”SZùÈÛXğ`v«!ñe	#jx»UrÏ‰57—xR?Õn·6:¾7{’îÚè8RÁS.UÀc;ê3O“:+êÏ1Š;KTû²ç yëÉïF1Ù—!IV=Ì‰r;²¹
0 }UÓÆ½ÄÂ‚d}ƒ'•±ÿİNêéÒ	|©²8Ï¾ÖYÊlù[×ñ†5Ÿ„~‡©3ä†ãdÈÏ}H¶5İóSw- ±&°" l=ö¶wP@¸d<61%ä3(8AşÃ_İËÌ©#JÄÉÔÙ[Ámj`ğí8P&<ŸZˆDa‚âßØdzƒ|Í	¬U~Ê(*zˆ»”Ù;¹GîÃJ+ËY¡ÊĞ•¨o8›ŠÚ»ªšÆïñ©®ë^ÕË†ùBX‚¢ıÇlC ğcËlÎ‚6èw! wL­¸}X§2êà[·©‰ïÚ· yãÆŠCğˆğ¯V¤ï¤]¶ßqvOÎš¼&¿TÏ²Ù¡P çŞ|æñÂ/JøÄğcĞ•&Ÿ/^—Åÿß>«¸é´Í%ğäè¥€ıV…¦º¹“"ÇŞ—$ä.ly¹"$úgV»™†aD©â/± Â¥ç¢ëæ˜R,È§¸†‡KL%Ñ*8g|™ÓÊe¼Ğíg„è*øD*ß¶¤=ì–{c}ëoî…s_/×Ñ²óq;m NO û=ë½×-ìÄÀq°SH¨}cjĞïÂºOl×ÒÏ„‘Š¡ôV¼qÔöêä¼P…€S›>^¾hüô,hA¾èÆ1w=:wjnb£°k‹²OoÁ/9ˆØÜÉV1Vf d‡àö›³-I`\
ñù;ĞrĞJÛ8Xíp×wcçÆØ"m½!eqñ~ìDi½Ò	+L?Aü
5ª¬#µ
r rÍ?R=w`Tza³iîÌ-`ï …7Ôzèş/*b–l3º†„^*ƒçÑ;åq\/2#¿Rqßw‚W‰˜¢QöÆ‚[HÑ®U¨€ËÿC0"ÈŒaÕ¼òµŠ³â–Õàd|ds¦ÛÃ)fÊ‘=ÓnæÕóQ¿ k›‰K¡Â®2¢QGÓràÛH`ô•@7³¢¿º„Gİ$•&#Q‡ïİ‰üÚ×6ìœÅªÎğ>¿tÓĞ]m@ö'K¸ôÿkÍwŸ„ğ4pAKÖkù0w2åéjçº’xÒ­RøuYùâw˜øèrJA ¸uÄëœ?­2Vºî@î­ÙZ§ YOvÜÉÒêØÕ–z€íQPj´¨¡r~ƒ–-Q¬¶kO+‹ P“8˜m˜«ŞK²ôt·¯Ù¼Ã ÂğG3º± …™w‰ÆâáÙ× ¶U£#•µÛBî*šeÚ–}EšÔ^©‘&xŞĞ8©µLT¸–&çÉIÿ§°Õè1ŒCˆëç–(ºA
	gÑ;fïCïvVJ‹z6I1·ísÍÒ´O£Ï`p€ã"œ‘¬[k+„¶ÀlŞ)Øm&6xßÙ¿…ãîKù¶wïLÉô÷î`ÇÔ˜ùè-ßuQ ‚:ÁÜñá·Dr÷Ïâ@lZU¶‘	.âQ[ò¿1¼öRx½ÚÈré™PÈÔˆåb¨8n^-ÍÙ¾‰Œò®T	ƒ	à“R`{ÿ¹K&eßk;8±0ëu´ğëi_šÓÁ|_F¾YF6N0Í“£2bÂQ«b¥×ï&ÜË“‘Ÿñm'ßÌÖ;¼êH/„ï ÊzÛî1qÈoyŞ÷?ë JlT…Ú:î©“ØôŞ—§;Ë6Zcéë`F”§§=µLù ’§º¬˜7d-Ä(ìÔVp:àÊA”)©j@Ã?Ù*6èa)}+³ììvÀ*Iv&p]É¤óïãœês«İä™6PìHŞ¬–‚A8¸ ÓôÇKú:Uß½ÌCÁş°PâÆmº1n{?½ñ4ßgÛPá€Î]7Jlüù¿ëTiªPP×JÌ‚ İ†M?l&bÆ#“‘PÛâââô¨¥-qÈ…«§,F.L¬(ÌİÁL„GhÇÉu~Ú¦”…§Ë7pÉW.Kù¥ñs"¯$Áº1]–­Ä±Şv°8XH´ÖV"zê?x‡W¸z%!€½J¶®İ"Ÿ V´Ö¹!aã`ÛoX2ù	áŠk~òıå~şî{$Öòözqµ‘Šû\†˜ÿ]À<d}uG1öƒ#ríSÂQùv]x„rÏ[Ä\â¦"~D^µrÆ™ *ópì5‘UâàÃô¼±æz?š9¿–*µán%ôıš\İb¡ÈïÚ®ÎºˆJqÎßè2~ÆÓ©`5aZâ€#Â¬¯òt«Ù9MÕ3·âï5 ¹'gÁw%Yˆ<üb«Áµˆú9Ò‡ıÿÖPè”,l12HN;€ò
ÏÊ˜º(Ğ½ŞZ_IİjêŸFr	£©Xg£f§lÏ1t}ŞœåQ•kû¦$ÀÛÖ†ú>ş×ÑÖæ„=ÛyB¶3Üárx2›vğeƒKfu!Ç³E	$wåB×uJ6~L·ƒ`ÅX†[®Ø¡ëõıÀ™¿dC"É
`äÕœ¶y–û‹‚ímïØ"B¥Ã÷b.v6Íi%Š¤C…pQ+/ü‹cyz¤‘ÅLK b5"€zÓ¼ĞIãÕ|âÔu]§¼*\¾IşÑó=Éí 6óÅAíRI,WµZÚ#éu•èÁëë®JhN>é¸´_Ë?”ækJ
†ñd+#ÃUäy«¯Ğ7¤"\Wìò8¯¼,ÿ÷˜Wor<{ú}KqáPòÍL°_¤*(À<ş2óòC¿s ¼ª "™ÈUø8µŠv1¤¿˜:(ş²¢eÊ[ÿ§%Ææ²Ãæ
½ÿ(l"ê¦âKÁbôQş.¹ûH]‡ê±Ö^½GKí)b- («üüÎÁÂ¸Èøå–T±¦á#|%j…¶¹İ´ûJ¼icšLe2„£Ö‡-Ê¯ÕE]ÀQÚÿdÓÔ¸ş,¯É¬C“(çõíU&A²ÃjŸP;Iíg:bHÑVÉéÜÔ¥;6°ğÂ1ñ/^¼ìS¶¯´ˆ9íLÕ(AÓ~3ãÑ+Ó–CwUM£BX ›!WMŸ3‚²‹Â­mï-{Á)ÒèEê N3b¯kî]~ÙYBÓ¹N/¦R­uFá	äë¾„ãUñ¹IA¨ÌÄ›f«W–­k"˜êÏDDuÈ"–ãñÀ.w­¼'b•gß0¿übM±Y@‡úo§Xòc˜Ó9Ñä;|ÑÄÔ®à‰IòÜ¯aÎb÷Büã•–p4£~²£ö\„Şgß1º›#8ï¿“˜ŠİQ…ÔŠ´©'i`eº|MÿŞ<-úâ¸÷kH}säS*¼Éñº¨@TCiçM¹*sÌ\—¶äJòú¬ÖYÊlAÏŸ,ä[³<=…L.<®¿T¾«F˜ŠÖ+åİ3Ÿş(©*^Ã_A8´’¥×g? =¹C.#\÷é|¤ÿŸ2äq[V(âz "¹RÂTÍàBı0HPJkıöÎ° ßû›Oyò÷]ÿÌÊ©(.x QéŠFøß[´îu3±‚Öx/†ö:¡8)å!…»—dl€a
?
ñy[ÛQ…âe#ù”J‰%ë9ğWBê5ş1–ĞûÒNÑş?õ!•X@E·kä»“O²»Fy¥+Ü ñ6¦‹Ş$¨V³ÈCój¿GxŠˆˆ·‰›¼Z_¿r»ÔùpşÅ~ÖRœLÈq:— âõOUçÛ¾%hĞ^v¬êc×–şÑÇq†d‰¾sØºÚÇ;¶œ]úØy—‡¤µ½øé@üÿcŠ5o™B#/…öPĞ€cú-4!	1/ÙÖ›”×ÊƒÀTBğøi%jæÛà}ëêŸx_KÜÙÿ˜4™Ò2nªÃ=•†+Êq›¿5ä*/0Q9yRÂ§’Íkyµ£×ƒ?n•ìé&ş ¡…à Ì'«š„±s)~ğ¶çÛæ:ÀJÒçl’PEX„l´:ÏMßUØÈºVÒÑ¸xêŠ›`~]}4yh{–ÉhÂy×ç`É‹™ôØ	7ÎŒÈŒl?H®,ãé_Ø	ÌBó»ºUæ¹C9©ª áuc%êdÔƒ"H¹Íçœ½ÿrÇhûE¸éÄ›¾Mí°8ÿ.éåOcóµÀĞ ^„,‘N¥b$%õ­6tŞö„µ^øZS‰•6v)•Z;4²±A¼‘GÛ³dë6h¶½AÅÜì]9çã¡h%¹©İÕ¦o´B×µ½lnœxµF¯ãUÕäj…’Èá¹¥%<6EÊDœ@º#=”â‹1OÇ€tŠğ¢÷MTáçœã«–´aFòÌÑ¿vCK‰æİ«é}eKk@K¹w“ºî¥VX^·àÄ ¾z=¢~l‹?¶Â¢ Ğh"¼ŸÒõ–5êo[™7>™È¹S«—+<+[Â9énGöéõãÄ‰B´èS¢\ÙUŒ£–·ï‡ô%Öâ}——˜!*ùª|fRÙ„–ZJôşó-ôŸêFá5¬(z7büx£ËhøË^¤şà§¶3ÖÍ¹É+KR†€ÿá&/”4¹l3˜'Hòî8kÏq2O'gzğ*“"äü: ;.rÑ»¹éïtTã=r‘¾n#UE¶‰¿Æé³t[`Î,3v„ú¨zäHoŞHÅIØöü¾ès¸T…ëìçXí¸NĞ·F‹æÃ9Éa¦¼å×ÿËôZêÎ(Š—DÚ×Fˆ>›€ÅPVä¾tøc`«3n‘^®!/õË¢·®à×ŞİôF-å¼}”³»[›	Ñ®88Ÿ‡œ÷@‹U4¬å)ÈŒ@«ÿæşE^qUÀE-6ÇRé€¤I'’SÒ7R_mfŠUÎ¢KlşK2›£ø7‘Âz@
®)hæóŞ‘ÚømY‘|Qİ&ÖN
‡Z¦)Eèj"½ˆ lšl§½¦÷EEør½Wì”8İvîJ6s˜ÀÂİ…ïW‹"ô’YCĞEúÃS:ªi€½ñöAÑŸ$ˆ’òùt·ˆŞ€‹‚ÉÛYUZòIŞ2fc86X«04¿}CùläÍÊS%ãp”ÆQp¸nÿ|‚^ÁòÍÒ”kßÁr:|)ISè5ÜÎøµ¤|•*Te(¸4ªzÉb­c0ö`¡…æ/ö¨kÿo~ä]W#™"²Ş^	"( ²ß–•ÿ¤ÛÆŞ.'ÒŞŸ[Ï¿6¯Åç»£°QñoÇ™¾¢¾('~!ÏĞ®n ûôn>¬ìHğ7m`9my¦7…‹ØPÛ±Ä¯¹x4#°Ù0W‹:ÂÄm~ÏŸm\¨9' scŠİKí”`vÑiÉc/–ƒğå(Á¤ÅöŞƒ·ª¬hùJL,§Ù«‚ê-HUnˆˆÁÏ¢æ°´(Œ	5M‚ÚP>ƒ”.5”hº€Ö¨5bA-ğ´½û`à{ Qù{T­lóºõ*ñ·ßĞA«
›œøl‹Á'½ÄéÎc †›Ìıq€” +zX~q³Ö§‡áSˆU²d,Ò¸×B‘A­ñãıMO‹n.ç­ï(­†<'zÎâ.*0@­)ø­Şøö¼#è*Š“XÆñå	ê„ˆu@[-@Ñø<STÄ,éú@Èß`ü-Yï
ƒòØÚ?‘E>tº-¸UA|íÆİk­ôÖ(pŸn'»[¶ª')/rr"6s­¸zeúR·1AÜôHÿ¹º°J|‰ÌßB„oP€^×)mRG®ù.Ï§£û“¬ê™5Ùµ ‘b®áé\K,·yálzÓ]×TY¾HÎÆì‚VKù¸}%¦C÷>aEírnO¬Ã	lùÂ¿ì<=Ë˜¯¿C¨a+×§Ê˜ßi§“+ÚùÚX]ÎåÛ^€$aà€_nøİVŠ¯0ÚãèT#¾JÁöÅõ•º¼ôë
[%>¤„Æà çªy³=/(/8~øÒJ¸qıè3HlB`”*DAâM@§™÷ƒw"Ÿ0¨§IÄ²~¾F&Y8 =Ÿ?G=òq?dï5Ö0Û€#6aUÛ’|M)vòŸÈb}\Ø†‹RCÈ0Æá;G*ó te®´Òpxjò?mh„b	ı¼t3Šˆ\ş'É©°~y4öF$TYyÙ·h:¸‡±MĞ&ÜD/5…·Ât&Ï*ÈÔ
ªŞîhn:nàŠÏ*^ØJÎ´ÜşTâ*­=¨ÒrèË”ÌºÉ°¡úxt—¿?zÊ/m—[]»¿X“œ©(Kü[®ÜÃ°²ZÑ¢Ö²1Æ<¯«qœÊôô;y_ˆÛÖÒ”<g D ¾f,5Îõs=«-0b×xQç«:=ÄïÂAC¸ıı&ÄØ“UM%ÂÕÚ#–EkY¶q6wIĞ¬!Ğ·”TÈai¸eÖ(¨5{Ïí( Ğbp³˜¥É8›Ò5øëÄÓ'à;Ş7òw£òmu²´lÅlïh¸‰¡âà²©ü9RuåUsˆë?³ı§5æƒ=´X®Ó/kúÉ™zdp9M¥H6ÑEFõštû±øìl:ôC©·c‚vmrÌ¨œVŒwšÅ?Ï(Ò‹`ù´e¡ãP¹‡‰t¯°/üd)<WAI²¼Z•—ë6îvL.3:cğïªx5´viIMçQ¤<ŠB(æ,JjG/u¦R¡fä:õ•S÷Qù;ïşo 0Ÿ±ı-Û¶Ñˆ	Ÿ‚¨¨I2®{.V¦É´hJÀ
A‹VÏ$˜­v«lçé¨­oÃÆ”=KïÑø·®e´#úªgàu]óí™Î¨ÌW4°·oË|Í¤ô²WïLî´Öö¶\‰ -9Ëğ¾<ÈPÍ½§$ï5 b tp˜2Î ”NP0 ÕéŞ‡(9Ù¯ÄQ’œv‰ˆÏÕTşw¨¨+¸(}`«šm<Üˆ/ĞyQ‚ü·ŠvıvÆò¤³ñÆÉ~d¢M„>AaµFÆçÖYƒA¦-‰_è"«7:ğñ¾2Æ›xj†á <Ôê…£i÷r®KU µî‰ŒT×ø^‡h³¡JĞáó¤İç*LM…“”°ôM—¡ÌÃÙä“œ±ÖÍ-ÍoßÇ­CïÅkÚ`‹F;Î±ÎÖõ0˜4!/šmì¥9ì˜>Ñ®Zê‡o¿À¶”ûPFàÁÂò Àëf×ü!ÌrC£oc½•F¸Æ¥¦¥£
>Ìièø}b€×5ª¤£dhlÚ™G¹ØŞg<Hô<JÀ×¿¯6äóQ·!ÍY Md”Ç”1CHZùß°!`â¬UÓ
à·ø^Nƒ’%¯öß¯:èA°c§îÈTÅ!Òx‘ÇûÉñ|º¬¯èáš­gÈe!½¸ä^ ĞÎ¥Şaãâ“|räVd­oˆ-Æ)ïú‘ ¿¶cëÑ«$¾=—ì„Luù…¿B€›Cú
íx……
ÈsáÁª©ı#Ìoƒd€õ\¥¥> !^	¤¸Lvï{h¡wßË…€Ækoÿå¹yZŒh)Ïœ¬o¿~P®ÏyxÈå1Ç^Ãün¾õ‚„ka§ƒr"$)pyŞ„oà^Ê ¡ÿÛÌ9ÇwğÎ.ù\q!VŒÚÃçOïtBÇÄ¡w"{£R1ênÅ!&E2än`*¬™ÑÇvkf4¸î¿UŠŠÃùjúÌpX=Y]ÿ“‘ÛƒØ§½ùé‹Wú‰qü¶ŞüvædºHr²_Ú½0˜¼ÆÎs’„˜¶•õ4ï˜a®J§ğ>WÖŸüÍ³A´z¶\h;J‡^+-hîÌ,õBÎ§NëøÇ‡YÓn»XífÏŒ¾/J)b.æÛB£#[g¢€b›{Jó>ÇnPëÕøÛÙ†×vUĞû˜ñ~o*¶›ÚûÔÑ2°e#âXĞâtiNò]+”DûÊ´¼¦Z•
ì,¾€hÍé¬ûµ[eF>“ƒ‘‰…V,œø	§üÄ×ì ÃÔ€O|N±Éq«—^=ó”ì¤Ğ@9§L0i_·Ä×Ğ¤:ùWo`âNÅìâÔ<:úécæÿÅÆ•CÃÍ…«|³ğó’fK‰—M².:)WVâÅHµşºFmêKêI)ĞÍ@œ“â×Ì“3–^—t˜Z”~a0pºnàƒ~›Ğ¸3¨fCµñ~¸1sb„BAR
ìÓWïæò»Ş‹âş<¶ÊU4ÔìW†¹ß›ÿó=û·*ÍÍÂ^ùfIòNß!ëm.N‚2¥·l)8x¤&^kr×roP’‰^Š<–láâi£xvŠå‰)O­†3d“ëM)û
.B2ÿ¤‘ü½CY“[JO¿mK?ôj*]<Ô;äËÍÉ•?­wpO¢]ÉWdó1¦Ø*
Ü˜Ì›¤ÏPQ5ĞC®R+hË{İñ–ı¤°PğºÃ­E…ML·ğº°$Å<>ÚbİºŞ`?{@5·ÃuªW\eÇµÎŠ=Ö] ö{*+Y{úÒU³ö­)EWZC_åâï”¬E9oÉi¡ğÁ—¢‡ò{3F9ÂaHÊ½ÏFV§¼Pı\;ÆˆÂÉLÍ¥ \;ƒ£Ôpü.mˆgH¹Üúâ ôñn_;Š S
¤v+}xi»›;3KònÜ£3¥¹ÂÕh©—·m¨MƒËŸ¤0àóa·*èV³zE‡"í‚zGŞùªLP›i°ejAEñ*49ÿK_ä^gêV‡‡ö$oÈá qÖØ:™CŞ&„R9öÆSFv1‚KsôàCÑâ©îäø­d@$Ö@rYßlÒB²fƒ#…êÖ~ŒYQØøOëĞÇ‚.¶ŠÁ>Æ7}Íˆ4§À<™A_S|/Ş°åOu¢D'kŞ’BâşÔ²n‰¸§I|M¢"¤Ş~Ñ.Ç4WBÙ(—=«×?wRS ÈD9.òáÅÕxà„Xô³ÏwÏ®BÖp"õ£®±N-¾_Fˆ~Ítxâ„ÒNŞ÷È)ŸiX‡bì·t$ìÕAM¢‡Ç‘Î?+/'±ö±º«‡™‹ ë0 ş.ªS&*´Ğ[,ÜNş’a€Ùv»+Cä|©j€p?Õ…ó%ƒ–¦¯d[¿hùğ³l_n£/%‰+Vz›¯Ï ^ &˜.éfÒ@³‹Ux¸&nñç.ıËP³ò•¤rŠçıFÏs}˜3ò.jC“ÓˆŠ6i+3!! ¾­T2+´3Iq½½4<š–‹_PªÍ«#ÂlypØm$N4?ƒ !SÄ‚f¼DÓ“?Ä¹›’¥?RÎ”Ò”€‚[UWä;é?¡¦*ÿ Úñògm„CÃV.L[LŒà
j¤¿mïcì;Ìt›ñôw”FFùÁĞA½IoÍ°°À°‘é*ü÷ÄÄYyıÕ‘pìG¼–®‰Zçí€CÑõ]=­o©¦:S8Ñ×É^öø¾šÏÑ6o3N¢¢(gÒJ*zñt8boöb¶x'öˆTbÀü(±ƒ#"±Ãj&+zğy?`Šû*ïD†«/Q¼ïçŠç >{KM$ƒñÔ/å¥áüèyÁ5TTĞUèÈ“.!/œ3mZ‡pîëCww|ÕxÕÔM—Bb¹4Bø\P1å‰)y²¬ÉS½C€Ø.·hOÅÍ­ÈÉ¼:eé÷1×8(—¾öA`øÍìD²¢Ğ)Á (pşãñ¥sªÇ*ğÕXÎ#j‰HGã=¯4\8¶­U®œ¤~ÅwSØ`9W¬4ã6I¢¯Uø”àcy(Â<ôØ+&„è{·
T_À7äPÖ3‰†=›c½ÏWšúÌ'†4åáàºwåç+ºQxs­ZOş‚ºDõ×­PsË‚Ù§Ô6IÑré‰—œæi^¾‰×Z~9ñ—Çİ]ÙgéßÇèjè>Ö)¾RÉy–şmSÄ:8yğô}údïÀwW«cAˆÆ¡Ñœõ@PFÍyòânŞ_¼$GÉÇ­
H)5ç·8b†üøC–nAD8ñ#Ìsˆ‡&SÁº8Tô¿RÇå’^¶°”|ñºÇhÏ 1Ó‡^!gmac˜±ØInI”í¹,ÕjCéÜÖsF»¥æşqƒ/çÃÿo„iSÎHñgJ’¾ÙP—÷ki|›µÒÒü2@«èæy²ÖYí›ğPT­©­ã[ÒÖm¿iÈ_Œ¥ëx±™µÂË… 5G-=w7*ÜôqzNmÒ`Û0}ğÍº2E.qá@Ñ%ß@@» Ø©»À+yäõ€mwO±cjß¼K%1¤/³¿zÁd"54‘ FNÄe™Gím`8Yéı$°}§Q¨ /c\Zùo,çã0æ$E*”jH’ñŠ€ÁdÑø*iY x/W‰=˜ìÔÈùoëC¢zˆû9³µd±gßÇñ»Šw˜9“öº	üˆ¥³±–[öÿ-5‡*ØÓå;Ú	(Š×D*±?lÁgÔ¦Ò4½EĞ¶¯k|P>{DMßrÌ¹¶i‡yôåÀä-„ÛQ6×İD4V®Æ*ƒYMÍ+Ìj©œi>ÿNÿ‹¹C¾¼|šä¨lÜD\“œğ
è•Ìuwe2ÎÌæÓ“4;©*o«¢¤`<1ó‰¶jIQ{NMŠR™ŒŠ·ÿYå¾#¤ÍFZ“ñâİÆÄr³†@Iøî9Ïu?ÿ	8qRÈ¤d ã[ÂÈ‚kQU*4I—>’³’Ç>èTa Ãä×ÚB~ ôÀr°]d…¢ëDã¾9²ÙAëåBªDIa‘N'fÁ&ë××öŠ^œ6¥)ßş›±Ô2Sı°•`r{*U£oÛHó×5tØñ”„A	”¯,ë&ö1ÏœŞˆ^×ÄœÓ‡Ìsû”Ü+ÄZ—m’¶fIxZË‘«c#É©&¶é.¼S&Ìïƒ¬ÍëÖ6•¢[»ò³XIœVW‘œm™‡²â8#œs©­+î¼hÑoªğ?‹wM.»{ÄÆ /ÊÄ5¯¥tĞXû›·è8yÈOZ•áöĞôÛ1¾Y£ºÈË¡Û © ‚º%ñtKWJ¡İ'Âs.=ÏKky¯ø4ÚicK‹‚cüÖ\„LÚ§HbS(œXÊ íÅå½¦%‹ıºkÙîìTâºøûæÚ«ÛŒ5d~õCÈYüë«3‰ÚŸK!A\¨iÎïá›…¡t€–m¯øñåÿQÏÇ)ƒàó½-…&l¼ÆDNb«dRÆ6/†~“C*µ?~×*[İ EÄ¤¡='`ñ=t†²mYjrUÚEëÓR_Ãh_€ÁCHEÃ™0ÃÛë@MÅxÅøçGcLPS=3ÉçFº¡%<bvlY?…™Ê¶aiÂõY[teëJÃúÄk%Û[…h—ù
 [ÙÃVøƒ£ÂÒîÔãt<×òjÚÜ×_ ÂLÃŸ¹MvwØ×Lß`i™ü?º˜Åœ.i ¸Ê¿zÍÎ(/g+®Ë¸L‚c‚ìá Ê¤€ªü7×»?¦/	ÎŒ=ÛœwB"Ûh„ßïÊ’÷I2x&ö?w]å½hù³E˜©:ÇŠ¼ánÑˆÆŸP‰á5ÜQÇÎiËÅçMÆo¬êæµÇÚd”ã\ï°ÑûJG	Û)¼Ş`´¿]èN`E
Òà.o`ƒãÅÎ7Â&øĞıÎg¶Š/±é>ş5udWMHğx¶_$C/»ıBa'IêëGPı¯,ŸŠb¨H÷MéO–õ¥P]&Ñ‘˜t¨F;ÑBfP|FÃ+6L(ò3
NÊA!ê¸¡g;&¿V®kÜbÈ{w%hƒ$D#ÃªŞÍ°•¼@ ]ß[3û¶½İâ‡Ë*¶úƒZíœ×ÎôTÆç"2dp\N Mëÿ‚2—lş3*¡.¾ÃTH‰¯zÊ í£¨ö:í~iº”RKVÒ[ê{wïñ7ßà.4ÅpÜ„ïX„5<-‚5JZDDDÎÍùÒ_ï å‹W1l¦ûíĞ½9Àqm+f‰­ëƒ·ûÒÀô¤#¸Ó} çÔ¥æÆïT½¡÷Æúkfşƒvˆ[OEÏãÈmÒÕl#Vã¹U0&‹“ëÿ³SéŒce±FÓišİøãÅb\¥Šª0À,y‰¹JMJW™C0ê²ûlÕÇúì)§pNg§ºI˜ñûÑÈx:ƒ­t]çs†p€xË@|àyCº×zzâ·¼û$Œ;òZ×CAF±À0°åÔ¾Ââêºÿô ñ¿(ÂñPn§7e›(:d¾b!ôrŒ¡øZ»íÓ©2=ğÈ$¿ò5iì6»Æàƒo6%_8Àì3ÿHuŸòÇ&Ê6ëÛÏ‚IÌ²ÒÂ¥†:YI&C‰“°~°Ãºà‹y?Í:Œ4fşciÁÁÄè–ïª½y‚”?I4[~ÎL&fF•#—d´&ˆçÙ›nÛ*ú?®ë,ƒ¾Œ•=®±agvÜò8SîÕ©±¥h÷_Y«®qûZb­ì†& U‹ã±s…Îõd(.3ÂÓ²
:îÂĞæuïƒ	•—Ş‡\Ş°"Ñ&5fSˆÛÛa‹.!Oæ’­H?•5™´G –ÍéQÛ¢ª ”r’fş Ÿ±ã¾˜Óã­K¼ m°#]›È+£	PÙ¤ÍE—J†Ó%æĞj'à­ã„}_Hsš“VÉd3´ÆÓĞMj8º?$¯g$È eü[¦îï.”¨;é€Ñšx³øG|_8‹¬eŒhV¼lçoÒr×’„˜|‘Mùöƒ|Ê
JSqóú]H[*YÍ¢¯¡Ó%;ğ-Ÿ·‹7/c­AtõµÆii!8¨|‡b8x‹ğ0üT§ë{rzÉPúêJÃç_ã3Wìa)»ÿBg2ªm‘ìå±±k-H£ï• !	Ó Áâ\ÍÍÂ¶áKùï DË1k´|H, ˜·¿†MÏ]@Cqˆ6	WxåÆ2Hğ¦©®’[ƒåµ«9<È¦.\áıE°nP>%ŠS?¦Y£%34i[n²J…•QãÔL0jÃùL™ Lqª?V$ã x*¸æEÜ 17ÖY$Ÿ|ËÄéEm·°`ûqH¾Ÿß¤äÂÅWwf•úT¿Şr¬E¦ß@–n¬`›
š•ÜO@ËËMŒÖ+ÉmŠ‡í.à…làøkÚèòpÓ#ùàLœÍe²<0“¶a¾%Òi@ëš-XÓ‚ÙºÇ4!Ø/Èz‹ï×±¸ ƒ=GŸÆnê¢&ŸÙÏÎû+§¤Ó3§lT^s?…Şé¦Ã(õ-–•©íúÎy5.Ÿ—ç¨É=,ç{ÁÇ8m,½G¡‡ô,D­Nğı-E’"èÃ2Â2¸?
¿¡£€¡ú–i€ê™Y!È™£w<—]RuÇvìyÕ•·…°	j¨Sˆï+t—¯¢~n(u˜„Ç›·öOY 97†ÿ½'d‹è{öñG‚Vqµ¸bŞ‹éq’»MĞâ<_º‡áà>¢ÓŠE¦h\¤w¶§D 38ù³aó8bìg¯ç3Ùzï™ë¯!÷ÌÄ°wT‡ûà4[RÇö•M}‡²;<Œğ.c«à5=Szã•iğ†r:CLîÈ;/Í-fºè4«7ÎoZz¤ûÇıLc]şÍwx­kfŒí§µ•¼{©İÂ«¥YCµº‚éuî†1a0e¸F„ÆÛòíø±Ïú ¨?×*:ÅCCœ¨:üúş@ññ½:	’´N¡/`kPûG"$$Ù½%aÑs¨{¡†c®kĞÉY†€äÄ~>Y+µµ8IÖWÖîØîNæ T]·ˆÔIÅ‹E;Á8ÏP>ÑÂ'±öÂìM
AÁØÄ(ÊâÄ›ÙlayËÔ´?ÿ–Jæª»ªíÜ6ú‘nù€"O|¯›ÔFq³¥úW^U¤ÚBºWş^Ã±t¾OTøÁv/œõ9ä“í I<ÄÔØó=Š£Et©ñ(wÍÑÈß´4bÔûÓúëÜ¥J¶«k-Ì¸ñŠ™¬ö«¿…‡ùD[“ÀTº”Ñn6LÛù•)XV Ax§ÎX‡èM—¡$ˆÍûâ.y]ài0æ\Q Î5îÀ#{BøW÷·€Õv\$Ö‘¶ü´Ï„°ÃLÿ¼}µvˆÎ…^òÆÔ ÷­%÷sÃ¬8ª>ÇÛÌ.RYBùSk­Ö…\Š¦dìVyY±É=Ù0/Îi¡””Ş™^Éòz*
 ·\|°¦¿‰wçh]ûw¾(³Hó&µôÃ²°i}'îäÍ{'vF‚
GpRìüG}ÊÃ7¢T.~XÛ ñËSôEÄ"ôWlÉA’p¸ˆ^^ôÊ
C(¤¨ŠuÉ?jO*Ëı3î ßMÒQÂÏ]Rú1îĞJæ
!ÒËM®¢İÒ¬¸#àûï 4û±œcYzT²‚Z/ÿN7>Ô²är¯a·Vı:‡Üã!Ö¾.ö…/‡<ÿL¾-òËşÉüÿ½É/êv«¥.j0¥Û!5îCağî“ïH‹Á,u] y·2½4?‚Œn?½s(jífYßL…º¡FŒ®Ü€½jÒVq©Ï\õ:³!Êˆï”Õ¢TíËZ4â˜GßÜ—¹ssfBz„švŒ~‡ÚØÛ%î°a”õnX÷rşàs«9ĞÒí/d^˜ş.„çgÁPÅî¦êÊ0¡[§éuÛpTšœû…émÍJ–º¤xˆ iÚ°³yIĞMıá:Î•è»­ßG¸¶€Ã2§ÉDüŠ,0Ò ŞN` ¡YÎÚÎĞOèÖ¤ò]oE«ÛhzQ‹éÎq.=¸S+É]í[Üô„Bô“×¹Ò^UÉù`'Œ/çv,u—zš™j,­:6Å­VÚ:ÂÍå¹
fşIº]%İ[¦ İkµÉ„Ğté]W¢5V‡È/ö”ü¾ªĞ¤;Ö{âØÛ—aŒG…Ú•û³\şB$Ì·’ƒreÈÜ¼&!9û5¦·ó„ÃÜ~«îÀ9DşÛ—¡TUÜ2nHĞLaâniÙÜ-ƒ‘œkkRÜpúı›*EÑçÚ=VÑ€¢‡JÉÆÖ{@øö\¡ªdg¤(–É}8ŞëÚİÛÄ/„;‘Îù£O_µã£ÀÜ?Âµ>!PÌæœ*9eÎx-¬UÏ|)$UËŞ›‰{4Ì£1¡˜=c›şUW^¹bİDjvuòä®È>›Ú41‚”;PîÊ´· ,;Šr×BÚhò¤Ö$
kÌÛ@ı
}ş ƒnx“åŸ-”èC×Îøß‰SòçS/ÌAé¡¥˜vA¼¥î™Êâh.ña)%nRá¦ÉQ(@Ds¯®n¹ÿFÅS‰ò(h—foÁ $Ğî:\†8æk{G.´Õ¼²úõô«™ƒRÛsúZ%g=ğÎì1Î«‡_ä¯B™
g%Ubñ¯X!Ër EWï’°%-+1¤s‰å ¿V´×ép$¡4GE+u™‚é½e…¥N­in†EdZÓ c¸÷Ó aü×¤³—¾³?îÆX÷°”‚ÉôvñÜÃÖÈ9p®”i¼É|şÍY·À’L¹}§œÛÔØ°ÕšÊj“‡{nş~,‡Éqæ¢T\ƒ¾ö°×Îq÷ø®ƒÇ	§²Zz’_Œñ¼-h$ëFl}˜Ç“Ğ>{$Dn;é–'øMVÉ~VcŒG óè åyê>ÄÇ½{Gıœ®á‹#¿É{ÎªÄâ	TŠ%aTCC¸¦˜•$ıti°ŒFÖÁ…•¤±ŒK’PôU§øgvÒ¢äã-¨ÍB€k[«ÿ"»îÊ±Ÿâà—ò[Û#‘¤Ön÷ö,€ |œVS¾²dÈ7ræÁGU<×c…¥‚‚[:¿yHMX{€°÷w¦GVE:-]~“8aëâCpÏÚ˜P’~ÅÜVmî4¼"{|™-´›((t<åŸ`|é-âİUZïÚp§ÜXA ïtœRæõô³ÙÆ‘®xx;Mo~aÓë‘€Ë)Şäøº@Ùá|¢#ãü¹uİ½iã¶Eï¼¡åx4ÑÕıdÁˆg [cĞ]Ê—FZbİÈ‹+4ph¾{5ÀÄ~(·Ô‘_[ïOòqënÁ‰¼åƒ~±b%nŠÈÑ®÷…Â)8hkÉ×Î)Û"Îf†ƒnW*ë% ÌGd|uP!±¸„¾®lK}ó¶X&9éwƒfÕ@˜ûìİçA%Q¹j‹1Wóêg>QDbØ¨7¼/ôÓ|ùŠJƒE •S’áD…å>hl ø6:QÛüõRtg]„õªE±‹,D>°eq&)ÊÙx~¿Vª,-e'åùªÈ&±Ô„_Ï?Š.ÑHã4[|ÿ´8 _ Ç—>â·“"¬ù¡Ô|S…ùÌAò<ÆSì q9‘îbßBÂìÖËÛ2'¨»4
Éú¡…óEöcˆÚ’«Ï_³è[AÅh{Yc–©¦ªç3Ís&£ö©™ˆPme‡xcv‘Ôn&†÷á
 KFÕ¹-¯L`"ÎUKÖ²XÃ²ÜºX:vÜ;<\™+í]¹Õ7ÑÄCÎ•ƒı î‚rx1;˜½IÌÎöÉp/%Ö9N‘‘3ÔíX’NãÄÍyk±[3õ¥¶Ş¨äÍ{!G•	7z3è	U°'´}í¼ç£"ÔRñ'íÚ;4¾íó`Éâã^ãíÉÏY¿MPHŒÖÃw·»ÍS,´Õ’1NíKvÇ°¦êŸî°}ˆ*„
Ö¬rá’Ô9Üıê™æVpÅˆ²¶eÇ¬­vø˜5oHGé—M4‰c«Î"X(0VŞ5j‰²Ø÷É^¤İ‹Æÿ7e¶5<Oz?ƒ©VàŞO¾SZÈ@yçVÊ‹-‹¥²1c¸Kògíºr~q’Z¢ĞĞ0qã‘éŒ% Î6´•hkå$[ûĞÆÔaºÜÉ›¢—z;,ÁZ;½÷ü^+5·˜šg“•ªØ‚x8<<ËŸ'’å½XÿÏ@6O9Í™ùéEà	åå—4HÎF„ 6A… ÿvS¤uÆêÿåƒtÉšTóxWd­óÀ»yò•€˜J³!Ë³2q³i5í>Ãbvfkxë—}ZËYhE4ek[À3"õÆÈ	í‹{rİ&;°oaÒîğúµºº
ñ¾õ!˜%?Z¼\ÌmĞ8ÈõåR^¡CÀ£¥JŠ¾‚å¦Ä=,éwuç¼]7˜ç8`ÊîeıˆöNş¬c©uªïÀ:İZKŠ!Ÿ’11Ó>MEq8ï{=tlıª1·yÅ8w±Ğ’± ÈÈwÿÉ§†Ü’@gavZ5ü* ˜ˆrÒÏ´7Òñ®Uj–z6ì6‚­¤5«"}f_Ï(³¿¬i|ÛaÕÒcÄÌ2³}c´“v>·VX¬äl×Z"X/‹[¥>qL$Ğ\ .b
2#ÃßÉÔ¤Ë(l‰§¤Ù'Í
;¼"ÅAl+’F·‘¨ÁfúÿoîOá/_RÇ]§ã±ßÑ\¾ «/Üàˆ+ÕÖ¹©¬­˜v\Z”!€ó_ĞŠ„)±°,TúóµºÈg³hGH-¦İ-Ù"¨*ì‹8¦c`rÔºˆßO’4d”Ğò0dt ¹ØmM¹&Àf‡ô:G¸¿{Æßü–°w1–6H<ŠN_4
.ëK[ß@ìœÍïhAÀâ×`+Õ¸¬¸ãiH|­3ôß7ƒô$E3i£ÈL×1089Ì°ı–ºvtU}‰Paˆ¬IŸ{Ò2§ƒ, vY:¸·fHÚ¡úpş€eá·ƒîPŠ/Âğ…Õ¬TsD˜å¯]Í3ğNB¤ÖûìJXâO‹Í‡S¿/áúçê…O,PÁƒCíÖ„RßY`wñ…j¼ÿ\Àq~‹å·x;!™Š+_:”8Æ®PŞ¶ıÛãôˆî±ÌTšuU.FóHsÆ‹Ù±§‰9¹Y.Èv$.>36—%úsy
ÊX´½óÃDSçIÛ­¡·ŠštJİkÀ0÷×´íZ$§.Ì¾ù¯Ÿ’˜-†5£hz_<óX–¤ò'H¸Æ¹r™¹‡“y²Xn–U)Ûºò=0Ñj èëñ—D>Ê‘Ñ‘+Æ`t3X-3´}\øÂŸt+V4~Â-ˆr­Ïõmä°öEYáwd‡CúpÍÊ2sOëôôIÅ£élª\inp7ùø"ÍÜC‘…¯ÆMú¢ ¹É<_ÄGòÍwÈv]-jïu‰o'¥s$a&Ü—®Cülş—l©¼&h1µ{7³’¼<:ù¢œ‚~=Û?ö“E¥ÔÖÄeáT¸¥PƒÏBÅY’.CRPrYÜ‰ªR^´0Ú	ÿ<öù;ÈùÒmğ®\£%§§_"ÍZI!Í†r§$í¸ªİë­±ì¨ñ$¸dÇabp£N{ÿêIEQ®pWÕW®˜vn,´òÃÁŞCnn'ŸÙÀÂ^¶¢´‰„\f[N=qªuc„½æ†ğûª‚İrä2‰ §Nk{¼”NÊª>,Mñ;OœçT2-Ó$:NøÙŠvüfüãİNf’—¹iÀxë„ûCÅ/†ÇK_#D,ÚpÊE>jŒ¬r	IõjJô¦<}o‚ı³_»„¬ñGÃÏvÈxÜ
_˜‚çÁ+x§üöñ¡â@	7ï&£&(ÈîÇŠpÓå_ªÛtÛæ¼0ïøû¼Aª‘ôôuL…äœ´¢…@‚(5–ä…Ã²{8˜±$;¼ÍôMeı3{©•¶"ëÓLçñ·ŒÎè äX¾¤«%Ôû€×í#K3ŒÖ.ÊŞ÷£Fx›|<4
·Š\‚ÑM×ÿù¶‰µgt/ï³İ	3gšLZ<À k¤U•d,(-Ñë(öÔp»†XıZèC@ŸøÆO]ÉÔÄm¶MMñÉ¯Su+¤1

ü{×$«ÆŒs@›”•W~±Â^Ì*‡ÇoÒ6«¾¿°úDnE°5!Ln@HÎSuÛ1d”×2¾œSEbj#fCğIØhõ¶
sğ˜û5ó4êñ,¾=,>!ê>é¥¡FRèe¦¸}+Òø¬¢±{ïhf_#æÙÖÅ2)l\lŸª_ÁMÏ‰d^,;7¯uÍlºäÆ¹ÚÖY¢tíâ¾ç~Ù×§Ñà{|+«bÌØÀù Ó®qû·†A}âS$,tcIíF,Uh“ÒÀíã"½ÁÒ/©ñ/ ÊÄ_©­Ñ[”ÕİÏrjØmÈC—{ ½²`µ!bŞJ#(ÔVºQ£]Ò†ñ”ñŒTÕW ;0[#P-î­£®[¼'ú¡p”:†¹Ofáñ]HŸµƒ¦âú&2B'd¹; ûÆC"”G;¬„–°Ÿ‡g7-“¿UÀØ¨)îZ0o2§Ñ\`ÖŒNC1W{5àÚÛ«U‚(+Éã­ò’ÜŒ\Ô.Ši¿4
]ŸqZı ²­Š™Y+s/0&_äÌÎ×ˆ¼l]#ºK¼kqæb­˜KÏ&ù÷ŒÓ”E hÃi½Ê ÓíÄÊD¥2í†–6¤ôÍ¥Ø'(Å¿A„EøÃZs!2¨1wq×<|ãei +¿Š¿´a’6ËSuÇP·ú]‡$ú>QQØ™ttó½(lau¥Wàx±ëcüAcã¢1ÄjVğ¾®-ÊìXá×0	ƒ89ï=,hÏj!İWR;¼(/B‹-À¼¾”Ê… œ–¢J»ÏÏİX<aØ´…¥çØ}ğ9î­ı„’‚•†¶Â4E’œ€”›£ú»RPb5¢„¿Ä¨ÊkÓ)];_éí¡í±¥Cqv­$•áìó-ü¤÷ôî~¾,¸*‡Ñ@=‘Œ©4¾4~õVK9PæhÔçQyÏ¾D©ÿ¥Y}bxÂ›±A´ŠØ¼ë·ü‘ĞIÁpËÔàD‹t»&¬§r®úÔLAŞ+Tb~$um/ËµÑMıi¦Y­Œè3n—Hnœ‘Ñ~r]Ãˆ|EòÍdøú<LBCïÒŒèù—:XF¾ı“ƒ#½Lÿÿ¯!m1$ì(wK(b¤ƒû×ïÀTQÓ6C	›O¸Eºdî£9Şhtakú¿Ç›€/4î\[àš1—bjÎ
h†³¥¶)n&Y¿w'ƒ-Ã›¬ÔóğĞç0é9eMjhú¸DÃî%gˆr÷Ì±šŸ®°6üjRÙoæ?@ŠQRt%o>]9‡B´éÎoîÊşf³µ Ä	o	¨­ú3Õ\ Ìı[;nÂÈ G!·œY¿Ò†|&]¾RôÕLÊ6Í©¸]ÏÃr>hó¸Ê9ÑÉÒGÀë(/¡S“ É½Ñ<6ònG îÒ½CI„mipl4 ı0œw¥¡ÕóØzÖ2“6H*Rüj@%Ä¶„{††ûcdËH³ÇíhI¸fÏ4Ã¤¬a–4núü÷ªôùbŒ4 ´Uè·£§&ÇAyÙ Ÿ½æ-/ÿNÇ»T±ÇêÌ
(\¬^%¤Ã.ªLÅt	T{xÉ$á:şÇ†´Í¼TšË½ÚgR›Pë:U>Õ{Â±½•R,5"EX5ÖD*¼pI‚¼Î-áöøİÁKòĞÏQ7CãBe7{¯›7
Ñëæü U€:ĞÚn…ØñyLo¥K”>Ç—/ ¯Xûy³ÕçÈ#«@œŒeÙP˜ÏÇÌ=ãû{-¤NÀ=o—ÈMÖ9½õâPa4<õœM:Jıï¬…'¦6}t[v™6_²˜
b*(»qa’mé†Î#´T„'ô›–ô*/c“ñ¤
¯Ïl}”éG1	D%`è00æŞ\¨’ÍnkVÜÔ¡®©Ó¤{ÊòÈËaUde¿üØ•…¶‡^É]°dn{XWÏMAÕµÒ¥Ã;æúÜS7)‘ ±ğ<¡öı3h´`˜6³ß¯ÄK±µ†4LHAé/İ›Ê¿È0ô5h F	Şä+»&ÒWbÆkHõŒ‡læßêÁ×R²§3Î—9:L`k‡Ö«g
SÍ~Eçä’ÑUWâáÀ -ÏÆxK° Ÿ4H¹F¾ÔCÉÚc`ÅƒÉË[
2zõ€£p8ûo.-±›8mğ¹ÃWÖÖÑ» 1œÔ‡u›Ôª`‡œ‹­â‚bıf° /ğÖ¶|c×1Y¼Œ$»òÒjyDö4B|ø(åŞ¦.\h€êí9Ñ¶Ër*î"q†:¥ Ë@¯ve&o#HÆıÂÅÍ•^‡ã4Üäÿô]\İúf(/¯IÀÂÁ$ú×Äõ3P¥ñ„î"
º¥%Ğ`‡GëàÅİ¿•úhP†ŞF¹Ş™){dy,ˆ±‰•¨ñyœãÈñŞH¥>pÔÜ2*KJ„"Àä‚ÚÄr¶`Åf ­õbıÉïŠÓÓÌÊËObÕ¯äüÙ	Ü¼İVW¶Z8Js{hR| %Lã6eÿ=fÔ?gOé+ ğĞîbÏ‡‡â¡i~	€µ ‘«6°=X,Dò·fU×{ö±î‹X-#9AòÔ1®}`(,Át³pÉ‚ªäBN¹¢œ‹M÷ÖpŸ!Âú/3XÙÜ%f^ä'^le6#Üm“{x¼ĞÂ }F7Æÿx¸ ¤š€ ­İƒÄ±Ägû    YZ