#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2110468072"
MD5="5b968731913f881a81df63f2a2542ed9"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="24536"
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
	echo Uncompressed size: 176 KB
	echo Compression: xz
	echo Date of packaging: Sun Nov 14 19:18:58 -03 2021
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
	echo OLDUSIZE=176
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
	MS_Printf "About to extract 176 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 176; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (176 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ_–] ¼}•À1Dd]‡Á›PætİFÎU_6¼SxúQÿTÌ\ôí_¶×ÛwÌâ˜³lW÷]şê@µ>â­ŸçœŠ×!WMĞ~çÂË|±_¸S“×^ƒPK¢ Bh_³ÌH!“â4Ø;ß3_uÑÔœê`¿ïn¥"I€ååİ(óiªè¦8iğwºsŞ|GÊ2„úrœ!Øe+§¿ªîÂi¥Óİ£hòÛÀrm4<Uîá¬úÕ­kÛC?.IuU»OMUºàë
ò"\=û›Ãã=`ã¥Ûozp°î_•7Ã‚Û7fºúuÒN}Q|N³å'ÀOŸHœÿ›©–•,ôŠŒÛ6U<§±\Ã`ÒofbŒØúÔêsÛ–ƒıbÌ7öc¸¦Ë°êãOî¡"},%²
¨ù6µs^–ı$	èÎá$wp‡} {µÎ¨gI°{E)Uİ§WÁÀS*{ç9âv{^~Vtt¸œÚCÓÔL±X8ô¥9]?H±(iº ‘b½;­°¤Æ¨İ7áÏ@å-2{ÖŸ³(]…ïélª²B«x¿…ç ª iE™à¤¯ÂÆÅÍ¨c²ÊŸàN`6€§2ÇÄSò_{r \“{9,Øâ›3Ñv)şTñ~‹pœ:.y¹ÉµÌ°éÈÍV¨…Gön¨êAb›©‰¥¸_ª¡&‘©*	RÕ/D¯>~Bê*_¢ú+H3EÇˆOÎÕuÖîˆ{Æ¯ë–’um5*áX¦Ñ\´Z4Œw„”¢¤HííûŞ3Æç°¤íÌÁ8’M7Nx»g—…ÌŞÈÊ¢#ëé˜æbåkÃL§YdWrô-*[IÉY\TÅZV’°û‡ì:ëôì‹²šUPgãfÚTá™¬ZULV½U‰Õ/!şÛ' WS‡:Fîî˜9“”Z×‘^¬/}ã¤ÒEšâÌş…“b¬Œ†êƒ×g(d2”+PÙç‡É¢İöK…¹'jœ=†œ‡û(tFoØÌmÖ—=e${½;ª±åœÑ±ô©>é­bLâ_©¹ÖBôÄp­(Z÷øÙYBËhÍF5+º~ÀiÁµV%€¯k¤¶É–Ì¶î…Í€8ÄºÏP˜«x lúNıà‚ÄN{úÖWsI:ôoP\‡Ï5&.£uš†ÒÙ½jì×úGÁâ†Ïí¿œ(üËÈà(ÊÎ&û00ˆ…nZ|Ö Seúà£?ícê¦CÕ|ît50I
ÄÏ~î‚tå²”èèœ‚2Ê¦iÅ\àI»œ¢’âàJúêWjÁĞuÒyeüñ20}÷¹i7©¦Ò1ÃÔt”Ú²~SvÆ³‰/\eú°F¬Ú«€‘ãdîªé»äÒì—´^ããßA©à*ç¿˜õşì›ê¾Œ,LÄ’3H¯¢E}m8V¾ßÆşè6m{ÉêÅULUjç&èäöx›<¡J œAWÙÉƒTñˆ;‘ t(v31HOOm…»iGƒ ¯¿™¾^åaØ5 ¢¦Ì»˜"PREQ‹9üEÁ¤÷XÜyC%e—|Ä<²[r˜P œò)Áğéä àÜwı¤o“kšÙ¿±R“lNç]9íjßd¹Có¥…©Mˆ€ıV7Ğ6éÁÍ>Nf¬o“#·Çøˆ]µ&öò(¼•ò‰§+ Ò”îµ¬@ÌI<z\ÀÏ‰•wa'ÎiĞl>×Ë4Š™ı0p1ß£3u‚ã.Ærƒcœ]}¹3ÙĞÓ1mNÁ¤ihÀüŠ
¸AJË§îú8{ş.Bàè¯gÀ)¼ª£F$ò­ÕŞØ\î—@ÕÛ´Ò5X¿Jô'}­·«ï4,C¦òDíµ»­g†"Ø¸yJ/wp”§4‚9pÍÓ2yš•* A_/q ˆ–'|1ÜA²êw/çß¨ïUØ¦p¥¸%Ëä‰ŸQW/¸:ZÙ­œ7È„Š.¸ÿv¤™Äù“×Ø=#ÊnmÇ¼jQéÙF¥?]«¸§>ó¡ö½§³DÀƒo4†(ÖâÏ€d]Å	C¨]›¥ˆ§½mä68—½p*©Bƒš÷jç=•í-TÊøI ÎÛ„A!n|ÖPã-ÌLR¸õ'¹ÍWf¹ìdŞïktÕ°Qò ô‡åÍ•°S°k±?
4H·oG+Ì}äVÑİæı=^n‹~ƒVÉD†&ÊAš#e£;3ãOû%Om _z¯m›×¦Æà|m95’óCåµEœuã&yÃuudÜıCL¾!|w—­Á[°òPtÁ+È9†ÑMäîıIÿÈïß|³ûçœ-2Üÿ©ŞÂÍïtÅM]¨,9ZEÏ†êır¾½à¡†H}W±PöGQqï— 
,!òç%n`q©G©ïcl>ÄÿÎ—ñš×,‰
Kt 8Ì&×¨-0éQ©’‚4·Vy“^aGË­6bMb"\YŞªw[~7ˆƒ_ô6™/p.µ	h{2¼$Ó;ŒVCš'yMÇ˜Ñ.a@Âhš9”Áv,Åmo‚eÆÉ?ËªEØUãÇu*äY¥İ¨ï+[ìïäŸ·Á âBÅ)	2œWYéVŸ…ªÖãU ªW»nà
R°4Q”ğ3Éƒ%ÏLk¾0~°|)g…Ü=¬¦JĞÖZ½í÷áËk<ŠÑÀÓT<nˆò#æ)ÿòà¾ÂÙÀ6Õ(uIÿ¥“m·QgLD*+yÉe¾°º6ŞéD>8Kh^Êüı‹÷ñNç.Òõ=qKœqI+¬æg7Ü˜²~şşØh,‚Ğ!#4ÂIÌy‡ÙÕª’šÎæ*S ¤ÅƒçïlØb§ÏôOG›ßÀE×/‘NœüËBè“ĞøqowrDjçƒ\< ’D½¨~@8éˆugãVÏŸ%Ö)+ài Ùc¿åpáõûó Yj\ò„ÕÇ8ZaßFvê@"‘DEdWêM¬ÿI‹`ø)8ï‘ÅSÿf%›@¡ 2xz—6Aï ¥ÕGmµç¯FØİq wú#«E‰–¯<ĞvIPrñÊŒÔ½ÜÁ·[hÍËü£ÙÙáØçÊÉ‡Ñ~ŠÊ¬¬92)x"ãôD’â
`_ÌD¶½§§›ìG“¡e!.EPQ·0À+9ª?•JÁ¸í˜ğ,ÔÑ±îâ+Õ¿Óá©DSÇºA-}.`)é%üÑR–e^`¸æ]»‚&Øe‰Â®l½¾/ˆä©_ !¬p:J°
8IÏ¡zY&GÀĞ0÷%E§Wó‡—€$+°ûƒt5•§†¨ü»dôÕe5pzúî“>&­ÁyŒ?¶h³¢šÿ2ß… œ(z•É?µÄ.óíQCI_eÊ¸;!´€OÊ+u0A?Ë&Ÿ	Z¢¯|` Áö8á$¯zg­m¹ÛÙ‡“¨ZñöQåc	 ×äÉÆ’BRSÔ›2uí©-¹z.3ôGúıéûı@É‡u1Ã:à(3üQBÆ›†$~ÇÜµŠ¾3ÑšÊFkXwàˆù–À*ë‡MqSùé%ñ¿š:É :åšSö…ß Àt	– -°çˆ(q,É‹+é†ƒ9h	Ñ0=]}û‚bãÑ!	÷¥&Ç¨eĞ\0†ß³DCÁÄp`—›6½Ho:è“wÙm%¿ŒMOcÊ4ÄÎ$Q*õLáóy\– GârÍ›iQH·=uƒ1ü0UFÓª(Y`*Ñ®R_xfRµs™t
)RH£ù^"§µä›ã·”CvıRŠˆ+ZXáøL>  ºÆşaË69TT¨3›Ï‡rœ[Â gNÓTdïİ«ü2õ<Ì÷Àªÿ/l2fF‡µ™*†hë·ı¸{ã
Ijâ½²•qƒØÕÙ#‘fX+ãÂ•÷‚Ÿˆt_‹ößœÈyœ*£ù>dÀ[vaiM†Œ‚»V>ÙhN¨ÕhWã?‘ú	‘) Äâ%ÅCßi€¸EéÆX½_jhë‘² Ï2Èôƒ¿@U*šG–‡Vâ‘2{Ö¸s‘v>¦"A¶|±Ï¤ÎK½¼ŒÕ2È¯1ã?Ğ™O€•Ä#~õÿ“nXôLÎ}dã‘ä'*0¿÷$ÉwOó³©J‡.&Ó\æ†Bô²xŞîÉ•=†öø9?»l¹(9eòè$ÖøÍ«À?À>¢\¼˜º`DãJâÕã@²îäÄÄòNäÛŒê5µ‘&ów—V-Š&Ü(¹EK/‡µØ0dN¥ gÛZ½Àº”Ü¹7E@óëR6ıŞtÁs¢d,ÂÇ*Ÿ6‡e‰1Pl™4h“ŸÊ}±Ï\½{1ÖUMÜìà„¥¦£Y$ö§np‹µû\‡ƒçh¨Àhu³ynròyƒdg|j†B–y@”K§Äàîf; Ÿ2õ\¦ñ@ nb´íµ„‚ Û,ü¾w»kËCÿHÚĞ¹œ%«o¢K§BÜ€6³I±-*\P¿×âü ìÈËÀ+BcóÏéšzÔğiÈm{6[’"HF=U )’şOÖ‰B”.‡d€Ÿ¡ƒ¡ÊØ#Mö¢ñ]ÅÊpMO0S
ÿÔœ08Üç	rØu,ò¼œÊsÚÕ!7k™‘ò@Qê³ï‘+Ö!Ál:Ëÿ¦’%1ŒŞØ]EEöE7Ñ"¬…ó¾2ş#è¸1À†è*ìÑ±Äc’7cn½˜úŠß,ÖS¾VÅˆï7³3UÖ`+4 NM#²è¢œ²d€PJÒË‚ëÔOŠòrVÅ™ÿ
lö¤‹)ögÔNhjïm¡ûÅW3Ã{“šF`ŞÜÃó`z²ª†ˆø‹8Ş2-ƒ9\’“gÂysvNDâ/’Ê‹·+Húî

»foÑ¤ÈxSqnÅ(*—­*“)g–½Íu›w8k
Y˜R=ÄB÷"Ñ¥ŞÌÎe×Õ Ä‡¨ƒ°Ü²k‹‡B›Ym¾ÒXR(‘XÍÀBfZÃ44Ô"|šlÍ\!ÉÈ±{Ê“³mğ"€-¹Ì!+ßwÑõÊ¥-8œmæ¨–X÷zÓÃƒqÉy¼ãƒ6±z”v<æ®‡’ïì<ÂŒl_s,öÓæcù¿ ˆ_üãÙJ¶9ºù+Œü,ŞâŒH˜[æ%Ò÷ÔÆµ„^PgÂ¾Ûçx¢RÂYèÁ´½À»^¸ôä½¢o†h*:IšÈÍÄÊPğch´¥†5I~ş øºODÀ9ö@læº¥ÎîùÂÄ¹œ'‰HüÏ/ÉZ ß
Ğ€Ùøöæ¯e	ÃÇ38g2ÓÒóºÑş Ï#N_‘¶Ó¤7zN’VZUˆ›jâ?Œqÿ ‘;qù(“-øÒaë‰»ä§4uîXO#,ÂühY±°3ÎHA¦Â?NPc©³jé¿üsä5`·%ªåb
aƒ.FIÌûº»q‹Šrï‰¾mÄè•§Õ[ê;ôıL]ê—U¥”íŸDm¤ö{pk]8íìÌ²°ºÊUsunŠìXÚ´õpcjòğVM¡k?p’Ë>‰å·àxLº ‡0~˜cñ]ÆGçÛ
ÀÔìáÛø
·’!ùd^)µB=…gwPPŞ*^¥Ñ¹˜.„Õ…{Gh¯ûiµ/iÚŸ™ÉwSÛºFïÄK,¬&„"1×[ÊG¾HyÆ¤T/ 'æ
àièP¿šƒ8Ëh E2nUà„cÜİhNrŠ¬¿…“uòò%6bA°<`e ÊãÙÂÏÇVı12Ki•›m}²"Yël5tX5yÚ5Jët‚£òÄ±m_!Ø“F§nSËÒtµTY²–>(Àvğ_ÀGmï¤u
°Ù5î"\¿¦N¾&ê·+ì¼oØ2±Æ+€'JÿÃšOÈAÏ:$Q½½¡Šo0HÛÑñyÂéµ]é"Ç ±Ög˜fi„#çcÇ *®|À% É±WCüAÓÿÄ:¡‚&t/£šWèõ†Õ@ĞÂ¡­ô6Š´< ¡´w–Ü5<4»|w5ÿoQnr[LxöÏmœXMå °¯*ƒÕV¹z‹$¡9L&Á³Ï}Ë{c?W\?kp1[‘¾,&²Díˆú­¼l`Áç÷õßHŠ×´ú=°àD^ÏdéyQ R»z)œ´ šî>œ°Ú|™ÛøŸÿÚÈ!”Ÿ´0"5ßæK‡ø#¥¼E–ãÂ±&A<ÏŞ§Yn
²ÈßE³	N´bè·ïWıM+ï ~–/ÈÎñHîZF!Úÿç±çÏ±_D®ozuYWÜJˆß¾”ŠòÉ8ö?ä¼ş£ŒQø¹0ßæôœéŸó[Ì·ª¤6óâ˜~ûtê&™•¢@ÑVò4õqgúÓ?­»D@‚Óu¼¼J>ç?Â9"Â #êş·jéí_Ëq£o§#¡€f»YbÎõ©[6—WâKÓt3µQ²ù
GéŒõÊ;|#©Qß	º­„àZ¿Éªñ:{‹SÓRzŸ»%l/Tƒ4Ù‘üGŸLky]‡Ê¹k÷+rf©S»üä	z ¬ kµD7¤¸Ë8=K#‡w|´¹—”Y‡taİ{Ûqb‘şâŞ£´{Âe©İ¥«)a$ûãw "ôÂ:İÃZjĞ*LÓ.ÛQ;<EØÉ<O„ãd”Tö’.¦¦sgŒXLUñëoS\Ötüe_7WZÖè·?~Áx'@À|SE:ƒ#ôlÙÏë}ÎZ¸e¦ÄY}ïÀÁ°Šïk"Ø-çRoz¶¬öO°uƒÄ—ö÷Í¾ûĞõfw_Ôe]Y[²óòä¿/ù±h4\ú’MóÌ'õ2¢¥H% 0°ã®¨¤gÊhnL—/^Úäã Ø…6D¯p¢pÌW¨êkÚâ ÜÿBÖ+Ë­	{ÂŞÀ]rWğ¤##À8×YÊî}Ù÷¿=8ƒĞ”3AÁåÀCĞŠªM	a6y‘6ÿ7¬€ÎÃ6ÒíG<ŠÊ%vë0&U0ä;úÒmÕÆO&‹²ÌK–º‚8ÏÕ6÷CHæ{Ø9û›cÆæFü´×øk™ÃŒ¶0¥@qª6'ÿ4ã "ÌfºÂT š¦² ‹y10şÄ‰=İÇÉñØ¸Ïeİ
b@J c£xL§@^oñÜèlòQJÙ¯nQ%;|”éZIÿ BAàÏ-Ÿêx-üªÏ²n·×†yy`L±n‰µóĞTi¡ÖĞ$	6œv'mŠ
Dw^‡«`	øRä9¹sOÛ×‰¥on”-„43ÇÀ²­½vô ™"Íİa t| ßïšûOËÅßDÍË{cüUböşÏúz§OO¥é»¬
óšõS”Şb|¡£A£4Ò~yâ¥ı„NHi›ÂÒ/ƒ¸Æ8ÇLÈ†æ]\şÆQ\…-;Ğ‹÷ w“Ùl¿;'ŞÃÊ×ˆŞŒ¸†âî<+’±µ‚÷{,t* -hÏÄÈ®Çix¾pÌşÂµ³ºäg‹@ÍZ%4š„Š¸…„p
øÁÍúŠZUƒ—ã‡WÊZnß¤İÇî¨â=u
•àtí`1¯_Ó½uj 3)=#F1]âòû•WÍûAe.¥İ±Sv%e,F:ÓøÛÆd’yÑöÃú’•c§ºÛMJÀjœ;" ±ª­ˆ±aÏ3Ë[.…s%V©fUÊ!*‹Ùò¨.ê9æŠú¶_w8ëIL$³?©¿±Ç¯î3µÒÅšLÉœ/¼xÈA²ÕîWèMÓËAJ··Ä¿#k^¸<~D2’NhI‡¶€%“Ù,›Aú«²¹*¸^²ñ	ÉYrv™‰ı6r¥7|"®Ï³ıÑÁùÜ¡;âcùBt’y?æ_ãoŞs;wR÷•<•»™Ì‚(8yK{â-¶ªUd¨¢h;Ş?ŠC! |ÕDºÕ¸ãå%¥d–£vŞÖQêå=÷råUÊî{jiFĞĞf·§œ£LàVõ€ıh\tÜä0˜à0zàfë]£G®^'ŠrùOòOÅ&ó÷ßü¤Ë/ğ3`t»}vÕC¨,epÊ­;ÓÙE±}·ÃBÈñÄnÔBj—Šåñ±nÆ»nw¿iDØ«¨^t442ïÌ¼(Ë+J«âÁÁÅÜPèË")nç’šIJ¢@ô<]~{ÕïŠƒ	ß²¨MĞ77_Ä‰@Yy!o~!Ÿş{/6c¹s´ôé‚Ù”	-*=XĞáƒ1ÔøÂğ`7Åıİ:‚(Ssƒÿ·Ìsä¶6Ë—u¶o0ó:åb:Ö°+,«tpğÕC;£ap‹"æ7"ØŞ„LêŠ¤Œ~’½Û'ˆuA}eÀêC¸=(¨¯˜ßRÜ³®aj³¿Y¤›d†¬9xß&•9¹:¢dxôZ<éî@ŞüÎEG³ƒ}²MYúP6FÌ„wÌ¾C@,š®•[â² †
Aåu^•²rJV	[œÍœa*«D|B\t^
NÓz÷|®Rí.ª–àOWNZfR¨âa„~K9í•ôùI¡ŸÈ5¾ÕÀ÷Àa µ4Ã3&÷ôyjªíítAJ%Õ˜!uÚ£l¬ „Ø×ı´'‚òÇäeªB2ıMÉÀ3]ìã¯v €Ü· ÕÏlø8™Ç«ı§bTT|E_ÊöEˆS°ÚÄèÉ=ù,ëSò›â×‡Î4ªÊø‘ñ³( kÜ‚ ¯Ü6»’M©£ãk]Î£ï)«tólYJ* ¥€§‰X‰£Y_üf²Œ ÕbGjë$éŸ€äæ9#8ù…èÓşĞbş<¶ê¿·AWD(yàEM?&ç^ÕÉ!NÌq¼÷á^á¹wõzşÈˆãU¶yëß -tÖ¡ñ×»Ä ö=êÈ!®ß4Héö§ã6›vÈ=X\œ3Œ~3 aAü”„ÿşTwÙ
çÆ•šÌ™šâmh|ÈĞúx2Ò†ûÿ®}G>[m‹­(ìX-)óİ„Òê‘H!cŒ[Úmm®F“C€)Ú¿ßüÙ¦øı<a-b_¸[üÖçä Ôw¦©“ƒDÑ”Aæ›~ğªO(ZFsÁq6ŒïŒk!G!ó¤˜•3%Â¯·ì[Y,íJ³Ş(;/zyl=Ä*¼S—Ãí£à2?'©\x™s•ÆÚéÊŞeÈ¦L×ìô“Õ	zNs!£ÚOQËÉZ²¶!é÷)TZs@Û&®bá[DN_µ0ÓfW7ÛÏü¨B¹ªm7axÖ½9ve^«
3#™P#Eÿ)!Ğ~jõ}‹pø·aıĞ$ğÄÌ@”’:0	H-ÛÜÀo®i‹öT©5æ3p}2¾ªl•¶…›øvFÊ”;Ï·¤½i“~DLğñN3]¤Š„Qfºh?GB„	ábkVó`ü÷W§"ÀÄÂÀWEw1*V¦½€TÚÕ>êÊë‘ÜPÙû<ˆJ¤—áÜ¡#¡õIuœ‰¨›.²L¿‰#Ä‚'º¤slÒëş2¶ƒípÂ¹‹şl<²Àºø‘”~®`à	Íôdn0|ğtóBùáˆ‚54\ÜÒ&)™kKIktßCxÙœ“ˆ;»'½Ëª>é™éãl{ÌM+ÑÈ:²ÛÎ;T¥Z§»vlS[ &Â˜s}`»$Ù€{TğõSuc+‡¿Sëú#ôç.pË©<€TbúDâÅ¯H“}T\ ÷ÖU?<‹.m%QædWøà_úI+ íLä#9’&Ó:}j‹™Ğ ×W±ÌŠ`¸)‘K@æV’Ø{6ËÊV&Á„1GÏy7ŸUÌÿ’<U/3§¹9m[@Ü-º¶…2ËøûÇĞËo~œŠCş1TãÅØŒù ;ğªX2’M…H©É|¾Ûj3³àÆun¦zj¼vdwxÌy4b#ÅçUúâ¢|!õ_o9ÛfµšĞşü˜OÂİ»¿é|æ’z–K7Kù_WEÑÿƒÔÊ ^Ò¬Rºf* †ş¦L`´õ@\{#ğ˜fÍŒdQûós½___w>B˜ÉRplø¹(&B¶Ã	‚™ajà[İTòNó˜4;AË@„ƒÖuaá³Ò'Ü-ÕzØ+şßkg³£QúAµ4'²ˆvãk¼0İ[uŠš]²bZáeH:6Ynz’·VZ¥¥]V£b7ğ‹Á ¥PP§Q¤în”e ¯ˆšMT…â<Å]QŞO'Y†éwŒ\¹üÔenÑU÷êĞÊØÌ¥¯QT"_X#"ÄıVûLåÖß„ù#"Y^VPFRÁ‹|ÄIDwJÒTAñwæÁÑŸ£BØ54ƒ} µÔA¡µºêù†@Ï¸|z#£¯Œ©ùµy¼ıh/	6Â‚-IŞ‚‡öş7£ØNßÖ»	Ï*íñ+ÒßÉ’ıJ½DÉt…üyİâ/¨£I+†g”RŸñ+â<*Ì_/ct™ÒW‡…ÿ½4Ï³°ïV°~fR¾¸®ª‹R•7~«Ë 5ëñî¥™ğxÊÎòÂŠ¢ñûî‹Ò)§›ÂşW,O,vÃÏQ¹FeDPµóìëş¿ûdÅ’Z(¿.w@€çÈ‰¼¬‘­}l/ì
y¥Ä[b¶ÿÁsöñ„B°]'Ì&7ò"O)şïÌ40'	„_6İv´b0°gÀ‡b"RNM·ÛZ'QÙ–‡M¤ßî×âÃYÖáÍSÍªnRò˜Ú‹€¥ÆNoÓén’şÔı¯“FS5‹ ÿn£ÔÖ¦¶´÷¼µîß›\}>û€c<ò!Y%Çw´®çW p^m{ñ”İ*–¶Ë÷‡<•å²[3H_ÑÛ!Óı¶±	Ô‘€ãáêç³EkGäàä†W´I»éx3)™á·Á½rz½­¬–~ÖäçóSˆ:ø±Åš_ù±a« ìÕ
EEñ…ÆC2Ä.È‘S1üO©"˜Xjb–’	;*ìdŸ—„¯vdº	Ÿ³vbğ&á]%ÁQyùjÂÚ…Oñ”™+íQÌY¸ÓXDxß~ä©‘5^ûcS+uo`‡}õš’jÚ—p­±¾Ó‰4™˜ªı®6è²]EÌËşhè"½×pXÔ=ÛAGøä\¯ßÿ‡á_Påº[ÖfçIßÔˆ-òà@!‰G±)ÌŞ‰7•ŞW­ÊÖ•é•‰Gi'’¡·t²Ñ-º¼“:¡aœ&7Š½ñbÂõQ…úÏ |44­}mfk?K(‚å6Š_ŞĞ€Lh/š Ï`Î+“/x<^K«Ík%‚V–ìÒÁ;Š“NØR.'Ä[À€G›ôó±Ríª}uÂ5á‘–BËÚûhå4#Ñ¿ÀŸÿ¤ÀsBùµÀï“(
²y~3ÖĞÇÓ³×şeµ²Ë?·XükJÁ×Õ(œÔà¦…tÈ;
¼ÉÆÉH){„Ü)€/"Ü.IÏÙİ[…Í›‡%_Å®’‹tß\hT§Úª”×p¡t}Â)¬®ËÏƒÃs…D,…¯æÆ
hÏ¥¬—³Û-ZÃ-óv¤3îğµ@‰ü.JzdOÎ«àn2A€«³nŒe¨X Gª=ŸsÑÕö¦AÑƒ£Ö­/ü%?Æ7şVï<U&³qL\\0`¡fGG¤/n]–°8¿^çÓ·Îå•Ô¡z¼€Z_Fÿ.6K£;äFm½¸Ë4ªÛx†~û†“O¦½Ó²Àj=ñ¼1öÈª)*ùyŸqxF²æ™à¤C¿!­©V|`psÚ9ÚnÒì` ¬Ñ­éÛ9ÀŸ¯\Úd¦Šah²{¦œéc|¢×`|av¦ğ¡‘E¶’'>ĞÓ5#WâóK@¹¢uõı±q#[^riÏ-E—_wTä¨«ÆàÌMÑ\„‘=øëÏlÔô<I	Ò°5ìÙYÛ2½øO­>
æWeªZÇô³”-“7	•4ÆªtbC{i ı´GrÌÄoL€4ØxÌç£áK²!*X §=çû§4!Íq6X%X•¨yG»tUßñ]àØ`‘¿D™¡X'wÏcyµauÂêÂHrgëÂ‰’$büèávs{$ø†n°ŸVªŞ´å>
WÕ°!_FÍ"Ve‚Lf”uD¨bïÛÎû1îh#çÕºmZú£àq¸DÙ*zIÓZÃÉ·kÅişë6¸#TZµzµ5-V³†[…	İzZd1…¯ßi´ejšqaI²Øˆä¬ÚØ¬ÎO8ÁäÎ˜¦¬	¡Brx”«Ú¨•]ÀœÔpZÌ‰¼¬ÓïÈU@á–1. ¥Í25^x‹Ñì$„êø¬Ú<Á–—h"8Xÿìs7©	ËrÔi@.¸®«m¸^b>Ä‡š-øõN¹	û6ydÙtêÙO¶v.€ä±µª¦¨¶‚h¾ì‰ìŠ‹=•(5Ç“ìWágR<{$È8Û¾è|U0Ä?ÊYÛÍ‹²l£¯3òZŞU"—ópzk£…ÏÏ_šáj-²_zx©¯²T×1e	´÷}úªµ†yLw5×´JÉÅTæÁØÇëI¶YbPÉE©­ë=º®`èŸ——VÂ›ÿ§rŒùû;íÌ¹~€nÄ_öùM_ñ‹òæ¦×Õ†cñ³—›<Ï}¿=msÚ F
4Ï¹ÁGaJ¹bùÄ¶2*6wŠ"½è›ªû{’4|ôËé4[T
°{0 ô°·V\ÈGÿ±ïxS|ÎªpïÎ€eêòMnkG^#½ïNi6l$Y3¥ƒLŒßİ¥UínqüéÜ†3MÍdó:­+Íq¥Ÿu`/g¯~òëä³ô÷h¾ŸOÿ´gr7zv¡ŒßhÑ“Fs¨J_¯	/"~À%şÜ¸äêuê—å¦ßÙñfçĞÁ‘Ìƒ•ıÁ­bóFZù
ôÛ´CŠÄQò¿©¤Ï³ƒï¨æLOúXûMõ€S

#I×­‡3…ÀSè‹(¾óI-ñşõœ‡t8Ç8Dœâ(›/ôr·í_Î3'·È èK_‘£fÛqMV<¤ *5´Ê¦ÿşÎÓÁYŸÀÉsÆ¦å¿‰¤ş£Í½P#Èó³U¿›Âõ$iÕÂíXÜØr9|ıH¸İ³Ñ²ï­¶¸^íZ6Ü[ÉÒñÊy­iÿU©¸1Ô±V/´'¹‘÷fZy"­t*ÖzsiÓæjP&ºI”äõ¡6@DædxàúõOŠ–>1'‚l\TíBøÁhİ~ùğ´D,[8^ÑÓÿR0WkWôØXûF¦oĞˆ
—%0HO?ä˜Ñi‘1şr|Ì`ê.ºâ¶[;­êÚQ6Êº†¦q“,š­0*õûİD”$æ;[·LXj	.æ†Õâ#‡÷£;¼Ge$Au\%PUÊ¼ö†Ú¥÷Ì–5rÇ<]Ôçf‡Båù#óíİ©&"×',±l»[J:á>ş"»Jr'&W@˜p^=JÉ7#y_ÂÌEj3xÔİÄ3BuwŒ%Ğ`b¹uRŠ¹-…9BŒ(éğvp€£=ÇÎâzêgÓ ]Ò…†ê¹9Ö¶@\XËtÌPM¡Ô Óåñğ}XÛóùmş”âÅ‘ºÕøàº›·‹æmyÏ]QN4QTiäcRx†DUİ0ßµà}7FhŠÂU‘KV¾kÕ­»ìÒKÆÔçÓi±¦rxp¯¨ÍDyiT$&°Øı	É"à¤öÒï¼«NNz=…ş¤ûî,` A"ƒaF3¶ä™…<Ûó[ŠÆñ@e`]íul1r“¶ë*d³wŸeƒ—ë+ÒaÑF«µ S+¹EÕ}‹Û#j›—TıB7ÉÛöéÔX‚x˜%Û¹@>ß¢/dÓè„x,ô;¨Û™wSÙD¶Î‡9¥"T&À+ Ùe5Ñò*vgZ´¥¢{`ÑE•"Âş´û÷-P†¶z;ûmh8 ¨@¬*ëIÄ&œ¸™jù.Chéî ëB”©¼VÙĞşcëBO29¦P(¢
n®YŸ™oYi5±µeä£úS¸ißqn¹Ü±TÒf@K~B]â/—Š(Xx=½U=õ0Õı¯8„Enşÿ”]üŒxœÖ°ºÛ¢F­Iak'PÆÿôK­Mèİ³IQ¼#8Ód¶NÏ8òé¬Òp„\ >Öe$ zQ7lS‡)¨îwf>çkl‘+Û=xv]Ãe”ã¯gkÒºé‘œúO¹åÒìv%„o kF}Ká£Ç†?p‚-–…zgÔO´ŒK_PìîI“—¥ÆÔbÑ˜,†øpZ…¸0,2¸"™QoK”úÜÆ;JgÍ\± ?}¿RB„Óï„h·û/xSó^e?ZVÕW¬\ò3şGcsôpŞ`ªó•³+‹cµ0¿›3«½Pc*²åy=»¡LåÌkE¯1ğ!`Š˜Ód0µBõ	_VŞÓøœ…¹m°Ê¾µ§ˆ'LA©¦ˆóJÇ2¿JªòÀQya·ôb~2û…Wq¦š6›¨DT‹;İÃ7—Lèòo÷“¿~ğ™V‰ stÄÆ_–clí«¸º¢úz9¿h›ú1õ	”§Y¹‘TötYe¼Î±E¤Ø¿Ê
¶T&Ôs‹'Q¡ÿ‚L‡¯Ì|•ECË„j‘iªåŸÙV£åxÑÈ@‡ÃÒâ41)4íùiU£qzIÇK“¤›˜Kœ›¤x€MábÒVûËŸZÁSQ*-Ùy	’w­%^Z¡BÃ·›>”’ÁÂˆ‘Î9•©3f.–èş ±nN®eËLT3)°’Îì7…Qú2´0ÁïÂcø:Ãç²ÜìÖæOàèj¤ÁdŒî³NçŠû€­7‰‰ê0£÷kÒ?•GK(ß{İMZÃö;OÇ¦X ÿ[ÉyÔIpÆ¯Á…=VKH[Í-rÚÿ2ñ®IİÇ^üôRËáÊƒ“;û&:ŸÀu¶h~{˜$ÚìÙZkç¤ì+/D–-Jï‰øº¸ÄS‰cæÛVL¾Ï»EÂ~ÍC{¹tİºŠZ›qÙg±* úCG¹åà´Ü}…š¾sğŞÊÔ9¤,aÃoÍFÇ_‘_$“«.+´¼1QÓ€ƒ©c0†Âumª	zœO»*¶]„ğ¨ñ^[^ïÇİTF%IUïunõß×aC`‡çO!Ã/uıbLn¤É–#°O=NXåXu¥ë‘™şjş …¡A¤åU½ %ÿ
„ío‰Ñ'ß ëL¿&àJô¦£0	¢m*FèrNàlëÃqÊ§©‚|ß`‚5ÒÍUh3±ï½Ùx?nı]f¨±±l}Š‘Ûq _@e‹¿‰nãrI §ùM§}Ëa=G4µG]• ¼à°©¦¹6Ùªx^wó	u[¦ÌbİÇ‘^~q7« Iİşñ¬á‚Í‚–BÔŞXóƒU;!ÇóTjïËÀmótù¢“Ä5Ö*^ˆºİCîû´Á™· m*œ|ª[¸: ²ª‰e³°}Æøñ¿;O&Ï] Š@Óíä2ÉA&¤_–A@™›:‚h]ÒîıÂ+«ïÇ)Ä§¤ç¨’ùFãÊ¾&F“3‰Ì,70Ë®Cß&_íİõ¶å|³o	s‰Çœ¯«<á% ;–*¬_Ù’£Œù{÷áAÄûœJA¦¦{KÅßâà:uì¦¥úsııôş{B¤ÖstÌˆí@³ÍabXe™vš›şÍşÈ06D#ÕF¾fâ#Ò^SG!Aâ(}bÃƒ²æa…!eQ ß¬aé7ƒfÂaŠdôB
'®*`“Ÿ;lB(C>­µqYŞOm.©'y5âgFõ¹ş.Sâ‰<Jµ_çÛÆr×ö%ìSÁã‘• _Îkn7ÁÿU îIA€Go0e ½Ş)p¡`sÀ‘hDNB˜	Nğ4 pŞñbwŞ/ö&€ÔÉ’9é©?ªõ¹ªÍMdÀí«™8>,Ì]*ù2Ôß©|×´h¨¥Î¿HİQ¤ÇÏ‘ÍävıjxÊ2˜¾)ÛËRs6øÃ„Ç`ï/¾­|r.·lş;î8áÖ=ŞwÿwÈÆµ¦,û+Nø¡»’¡µ(tiÉå6µÑ:ã+/Ø6Úµ 9Ë¶©§ÕÎ‚p³ùÇŠë ‡ sÄƒ”ÿd[gÒWè²À×G¢À"Ã#:É/F°y”MôcëöOtD#ğû#84Í óè(ı–[II+ùëBæ¤óÏ<œò)	²xI%*G&åÑËw:†NVıÍís!Â¾yQ sÂN£ÏªkØRÈ:Q[^‘õÂxuÿ´¯µmÓ–Öª‘ø´loë{Â€ó˜oõå¤‰¸
šÓçÙÊ-¨”Kâ»ŸPµqüá,	~‡ÜİŸBÑLT7•‹„•”ÉEÛÚ˜¥İh[Œv4°áK@®3ÔÄ¾ša@ˆ¶£U'i…®ˆñ³mÖ“i{É†’}A_4ÜìŞÄCíõİK–ô5ú‘å¡N›InKü‚€8WŠÓBYŠÍÚæÑÂ™ÙnÜH~QvHcJ½ÇÒz½MëfH?Îbueà.‘ª²X®IEÏ´T¥Óñêò7ë2+ó(0«÷ìËçQÍF*g|À°Ì«¤&?×JŒ_aDx>©:«.ã;Øâ£›õ+÷õ•!Ïá†'Ò¬³ Áë!écÊ«‘É©°4È©o†ÜI†cGÁêY@»ô]X—OÎõ®7÷Îì0TóècZLdò†…9b·,-é—¾g¿Î/Óü	¶]q}ôºƒ®?J}À“&Î°í¬Ã9P`ÛñÚÊ†gxA	úªBÁÖÄ¤Ôu‘ (ÿ1Î¢/Û°|£¯ ğùsi¡äg™F§
n*)õ*m¼WÃ>«’“Í{Î±ë»|ÜPÃÔ•I±W¶ó‡}YY¶‰ª”Ø0Uâx¤«`JZ›J8#Ø…av0÷#¨	‚v]iÓËYu¬.“¢‚‡gÜAøFæJÏUYéx@ù¾õüòş¸©b>- ‹Douœ¬İêşTM"GcÓ«Oæ´¡—cTV¾‚Æ´ı`›@Ós.ÕU àµ´H!I&õÁn!õüßNÒïAçıä˜^¤ÔÂ¶ÓßÑMˆAÿ,õ®£5QÇš/lÉ+üÜÌ0pm4&Sªé•%'eÃ¦)øb{HÖ!)ó_®‘ü|ûùÁÊ-«<ó§ÚË ¹ä æœ>ø…f;Õ–s®ÌhøõoÙušz{HTeå·÷‰„r[EÖaá5p®â;q	SˆìÆùÈåUZ‡L£_b®=…ÆfsµbTJ®ì]†Ç«’Ş=&v$`š]2¯ôí{¾‰«,Gä²èêËà8?(¼> 6xD|Ğ(BÜn&R~†ÑJQô6Iåj ¥ ¨2§ğDç!Xøş¡Ù,ê(íËÊV=7
ö»1=ƒ’µõÒÊx0q@IH®¬”`‡`_òul$:/À mV“©ÑL%:çmÓ8Cïïê÷ÏLš­|& ö¼÷‚;JÏ'–Å®& æ¡ÙÛ¤øŸƒŒ&¤Q^x™áK­#NKÚçrà%ãšÊB^ûògËdmÊ»¶qøÏ–ûá]iªHI#–µ @"fÓªßUƒñ;!–õÅ5Pöœ6EÔvŞ<Â˜_¸+Ûu(4GÒ‹÷øá´âCååqfí¬†ù‘Œ­!*›î–‘VlÁ$Pü)‘ÇÅÒìÀ”yî“ŒF…ïi²øƒNŒhm¯5¸Çåàİ.(™ÜüĞ ÈŒQ`4úEİ¬t3¼¤-8l!•ƒ%aè—"[O‚à¤f„~µÿ³±6{û?±&ş€€;ÖémK^¥ÇÑò§ıôQ¼TÈöd
gµæç.s/šíáé¢’X>ãBù	bšÆğÕ?¤üAKĞ{w`Ï0²6±ãIU4…ûOœ²H¤1ÉİÔ$´¥¤˜4ë²ğ«"!ú3o«°€@ğÁrÆ‚•cƒÆ_¦Í$ÅVaw!®6+/‚šƒrwºµcÓ&}±KÚ¾õ~¸èc®“¸xœşæÎo—ğ³L”\Pÿ¨p#—°¯ÎÀè¬@i–s(ÍåBÚ«~Ú®ãß‹ÖW–´Şäó,t¤}0âE'&g~ùÙÍVİd‚ÁöIà¹{Ğ»ùğªŠsn@3´eº9t>{ßŞW>Ï-0_Ìn€¿	çÛ•8ĞÚ÷Ë­<…èkÑ_·š‹Ô±¤	Çë´ñàCµÖÊ³§âQÿ´7:İ;r XF¢Q­/Y —ni–Ô ¾IóÇŠ t¢a­»ÖpÂXó=ª»ojqûurAú†÷_ É]Ø­×&cÎïVèÓ±bï¶è"=û‰ç–¶`œJï§ÓòÆ$ó¦ºBJh<Å4M¤Øi(àî.d@ <ù‡ıÖzpzêõ>4*?qıáößÜW&kŞ9È»ıqj]\u<ÔÔºş^ú 3‚R«Åõ:¼ü…GâƒçÚ÷<„]é¹hùel¤½3"d”ô¿ìÛrP›ğÿ†‡—Ùš Zõ¢>î‚( —ˆÎ_¨bv¨ÛsK°Ø/ä®MÅÍ.óó…×RœoLÌ´À%³âùÿ/ú`PáŸp4åığ¯W·‹ °4M¿Àïú$C!6¹Y¹ˆ;±åíÁïcVóèûë'(¤´Î€fÓh¼rugUd·²ì:(}ôrÎ°w|íF.¹yâ=À@hú-¹KÀ³(ğÕQ¹Ê–(ìĞ°×Å•“vÌéË©ÆıXá3Öw\ÈÜTÄÄ¾-ı*lJcî›7ßï•¨É@>{Ì/°¦Ğ^
†pÌÓ¹ŸnFJ~JJŒï®+ş¿D·—#(É‘:Âœ§GÀ†'2İT\â¶tRã‚$Õ<ôÜ,Œ¢|Á§ú±B³÷‹½]!Ååÿ‘H—”«Ñ*10£ZJ`ëÇÉ{ƒT,¿?¿FuKx¢èõc—¨öî-¸ÊÕ¡°Px©XBsÄÎªˆÛ¶İ@/ê’}¯sı…ıµï#…ÈÁ&µ$ç>¹Ï8K]×õàPÛêîèùíŒÆÏ¯ŞD´`{b€¥)ùšV§‘Ë½¦ßÆœ¡–$Åù;Æß°uSeZËaÉûê’¾÷Öv~ú³•$Ğæ#UFÃˆYÔ+¦¶ûl3om•1‹öıËÅêâ}y‹qÆ™mVNgºsÒ¹L™óÎĞ¾±ÇuY…mo}ZYnù ›O…D(—…r(ÂÍ}}	å»èuéq i´ÿû‹!ñ§*0Ó[ò%ì’ÒÀ5¹à!Íf©x¡@:ÇX”Œk¤-G.XÇöìhH†•#¼¤`÷¿‚ìKA<0÷ ­}%¼$‡„Ä›,ÚÀ3M=~hx”–Äf%Œ5Gtšã˜¥zìÀs å«nZ«ö;»MrLşŒK‰§È,«‹‚"ÕzcIS£ÈŠÔ`çK9x$V*[Ï±À¹&m•Ó!¨¾[”„ &ñ"gWd_ÑMåBËh@kJüÒÛ}¡±º5jh¼µ6 ¿gQ|É™;-[Xö(Œê¢áO 6®7E¤]Ü£¨&{¦ïÎÀ	ğ@o¢àsŸãZVËù»óÎß ,E1şj$WŠ‡«¶Å§Ìà¼Ï:dş©³C4ıw5/İh,î†^»<†Ï®JÊ/âmÂ¥&lò«­ğz"Ï\;Ebt´'‘ºÁˆü–9ãæÂÖnÛÃ9êéEãªm‰§†Šm¤òüi	Q/uÔoäŞ*Õ¼Î8İŠäÊwIŠ:Ğ4¯~ÂW¼%Ê
½Ê¯wÒ^QŒkÊÇÑú‡Ã„8>ËÁ^EäKŒVâÃlù*ÒÀšQ72Ê¤!öÁ¸š)ºî=ôGŒİ•<ïË7S!ôØø;÷" ”lN[ŸzÄÛÎµ¡Æ‹]h:P¦¶}¢§ûvr3Iúá+Æç~;wä Å´aÙ'šò—ÅlUş°=h7öh:ŒŒ¢å:¼F@aÒ÷î’Ê·qõÊaL©‡W`‘Ôaş€[‰—”ØÎ³°ÁàI8áOz¿ˆ`a·IãOÜç¢¨ÕìmİAF5f_2pW^ò¥â"$++˜üxúõ%‘“·"DÍyÿ+oòTN"«Úæ9	¿Qê“L®–‘­G¥Š>ú´çÛï÷î$9eœÎ÷Œ«ŸF¶2xû¤/Â«[)^òOk2ÚkU%—Øk_Å¦ [Ïø:}ôéâå·Tb§‚ÛÌ§öâa©d”Œm¥òĞË¼ìœ}$gã—gYbµ€_éºœêğoC”º“W”G×… å½Ì°¥|æAŠ¢ôJ'ô’ñ¦¼×ı¼˜¦”Jf  ¤Æ0û!îÛå¹ˆy\;$ó„dÏ µê•%ÆVæZšµXœ—Ì%`>­$Éççó¾Ti_µL1ÁH‰p>ûËt'z·=­Èw9´‹Œ::¾G¥“xV”ã2àÍ„AÂh j{XA‹e…BÄà~ABC<Óö²R\»hf’à@¬ul6A>?>ü;#Æ`? ŸÙh]oşşöGh4ƒ4€ë»ü!¯·ã	7ö;âòc—óÌPÛßØT`Y4T¬¿ +DëDËË( Õ3><CXÆˆÑÑâvÄ:sµq`¦ †7	’xã,NÜ§£Ïê¼Ü±+OÁ9ú~©qÿeQ9 æFïNèø¶¯¶ÙLÅÂ–¿SÀ»N)âr‰ómİíXåóÎtÜÔ[u'O­ÓeƒSëí_<CÓx¼îL@ÏáÛüB.ŞoZOè+ /á‘=³šÈƒBo`©ê,¿†î‹ÜK{¸ı±z.]¶hl™‡%¡º–gø›PQH©ï5ÄîÚ–d^ƒDÔ
ÆMÇ'e_òú&uZÎyY±pâü*¸$%ù5È°M+½È(ûnNå,Ø#hÖÁX·|¬ıP-äØ¶ûôS>7·u)Ë±ÏpmylFŒd<¹ïo…¹o·Ãªì2Ãœ¢ê¥‹¯Ä0*hŞ"6…ºš+ÌĞ?J‘QD~ÁÂù…eÔMë7£bÜ”¶Í';¥Föyb²1AGŸt„ğ‡ÓÇŒ¢œî#qPÿÛñÅ›sƒ¢Óx¢-ƒÚóÏ­#ø½C]vğZÕ”²–/uBïşZ<ÿàË)XºRğƒØÜ;9‹>2¦1ãîXªÌ×wÈÁt¡m¼Ù@÷¯~“à`1el÷‡õfú¸-	Î¨„æpSºØ§¦Û^Œ$Q(Há+ñä%%ä(tçiª·Ô;ØL&xÔMZÜ*‘4ÊyëîÔjàçÌµà–1Æÿ>n‘‡ÕÙÖÄr0±]5£lR§…Ä`(HöÿÛ]Š¼±Ç{‰Ï‹GwÃÿŸ”‹=‹<7úÅÌhÁK=Ì×Aà¾Œ{ıh¾9“…í=MpØˆ æn9&¡ÈmıxhQLMÃ"m†…õ¸Ã?`2n?¬Ğ:Ò$v³Ğ+8Êœ-G‰ìí2Üîø!”L BKaN÷Y&Áò"¨Ïá…(ûüIéh‰cŒu.>§œÿ÷¬Ã\RòÂ1ñ ÈS8¾ä€Ø#È”?‚/ß÷tÈ]Œz·ßêYi8ù—2lÅ¾•¼rFdªß@É `{uü¶îâŸ‹’üXdU’!%r…î”_ıÒe íÑ‘–¢\%@h5Ø^*Â­pÃãaÁòÍõæÓ‹'äzò? œNMuJåÏiA–}¡5Te´¸aÉ@æ¬~ö©iÿ‹´ãjò—k”ÇSÀ"b³é[$êêç­;º†€IDü2Êa³œÓõôçæ  äyŸÏTøuQRfºòâÇíò”!Ûæ´Ñ˜õã]L#Ù¹bêÈã}„{G€,_"¦G5µalé(Ã~ù$±©Ÿ:ş,iì*•v&Ò2¯İ¤÷^¼ïí¨ [ ŒÀ}’.N;~†]4Í™€µ7Ö±ÄWo±û iˆ¡ äñï^xÛ³^ıÆO–:ıƒ¥Ÿ¢˜‡Ñ­rq;º¦nÍŒ­[eßıÿÙĞ–¹5ğ)'2IÎÜŞ]‘¿uzŠÄ f-B1C>Ø¨ ¿»`•£rÔyü÷ë»'Ø|OšJY&2PêÆÊ1ü±R‡PœœRÊ\ñ‡„şw{Wó¡Ï”8Ê]»{+ĞV(ñõÜaÒ;6“­ŞcG@S—sIOG,’.ÅÊÖßŒËç¥–ıU¹gD¢ğÛtL’Ú´mã¶,w­Ôë“3ezÑaF5¥e¾æJ¯$­sÑÔú•gŞÀ¤È}±êNpR7tW¢Ó¬0Úà€Ïıélo+ıòÏ¡	ô¹¬:^b!ƒ3ÇC¥Â–µğ# ºR Ar×ùB²JÈÅ
u³çñ ã{½ï6qn"»ÙÅ‘®Ã!O¬ËÈ™£ŸÖoÉE™!ÇV\³6=ğÜé¦“jFŠò–ù£c®#™WRÚÖ* ì'ßQ‹£9ÜãÒSçs·aíy1;õ—*ÎqJ'¤¹öMÈËéèØ8*İ‚,±¥ü£ñ*Ş!c†G€kÒŒ°4YëE	èğâY;ÍeJj…KÆqh6M{Ó*¤İmt´6èu—1&/üìg7V «ğŸ"E¡?û:(2öÈïG\Çg@à‡ƒ”ÄRâ8¹òÅ3fAºë‡#ncøä—7ê¦§¿˜x^Ï!£e³ãpeJ¸ş ÆÅ8,Ûçt(!~)¢ËÁù	ÅÚ®¾„:+è©Fc!WpåM‰—İæàxá],ösº%ôU§?òÔYùËıt8äj6pULdñÚ1{ÖZKŒ¸‚èãª×š8m+8vô¦¥F`Bt¦óÊĞ|ÑŸàkkAlÉë”²x±G‘‰ÛğÖ!72ª
fSÙƒâË•n¹'Ì(BGÕÒ_¦*ùÄ…¼÷å*{GÑ´¸áƒCpvôÉö¬‡ğÜ°”¤wQÔSí; aqğâ¯ëÈ}D¢´ı€$¸2–—gËEËŠ´B=!Dqä”îÁ.gYÿoºÁ|(³ÔØ'öÌ¯¹Êï;™ªáx3|n¦û»“œ³¦û¦Ç€ˆ¼h‡vÇ€? kªÇ¶CL(ÈaÏ1[ß[jEEåz¥ˆƒQúfğ‹y»Ì2ÿìsNËÌ^ˆ¯’™xM]¼Œ¯²Ã”ƒ­Oa®«Sà¤›Æÿ‰ŒwbUmÄw8—£cïİÁ3
²[ª5tÅYd¡NÓ2kæ/Î’¶ji
„÷n’²âœL–7GĞİäó¹°CL5ø´Ñ|ìi>]¡[R?—Îr«•åÎn«ß—îŠU}ê8kÆªÚÖƒ¬®Oœ \ÿşBEèyÎÅE<a°×b˜â/â0|ı3ªî<>^§ÔÿÕÍÿtñÈ®KAAí_ÚµAã´“ì}v‹k¡ñ™›HnQP¬™(IŸ¾à}\ÛWß73Œl|i³Lù@ª„	~à÷íüÉ v·;9\ÏìÂG±Æ‹~ÓØ}ˆÆËQ¬pRá`_ãÂ!q¯²	Árı Çg»ö#®°O@eJ†5zØÇ½ŒÀi»jÆ½#ùôf³K ©OÅ¶&-¿¼„vğ¢z¨³íÍDÆæÜøeiè%¯/xäfcO¦Ù’¶™Úü¯õ<VváÿvzŠ×ÛŠy™a†À˜)¿
æA‹T´Ù¼ó^zo>ª˜Î”°‘§Y\¶ÏÜ’úw¬…*NmÃ„„—–¿áPg!Ô¶Xq)_êF—4ÆtmR¹¬dªXxŒ™4k§gtg0’¨´«½¯ªŠ¶¤´¼ìÏC¥ñpº¶imå·ØNdi{ö¦6ÿ®·ÚCOhı ­ÿûà©=g“(m<sèé¬3œ–™ª#÷,ï:R‡{&ZE€·Ğ„a¹VœqˆÙş£è™Á"¨%A—€ÂGDãtP}¦1Õ#ù%›v%à’Uœß
î™Í!µø|€Ò`ï“ÿš,èíJC"^œ
ÆŠ‘nÓØã)˜ğtk³o¯÷VR¶§UL à¡mO‡=¦z†ôqØÈ_¤»N¡kÁòitYcE“¬â].Q˜iª ë÷5é‹ÁIº+øhÃîˆua@êŸ	¬PhòÒ¨0XÖ!lÒ	W$Ex5ÕŒ ¨œ)ÆèÎ)õa¯ÏÆ›sêpw­é*b\û²D-ê}/ØOwĞ¨ò©	ŸÀ)Í]Ä¾q¾Æ[Qú}ë½l¼ãÈ{
ù™`G4s3›é’œœîQPEnœtiˆ· `õìå¬iŒ¾+f»‘":/t=8ü¤”]»>å°´¼"HÈÿø°uß)Úù~sq[§±¥uÜâ=(Ë¹6Wûëû0ÌĞì“]Š ô>lbœIuìÍtà9ÄÅããjmqM	\²uØ?ËøwcÀ­Î`ÒÃåU3´}"fªê” ™'Yùi¨
‡sÉnSö“ZìÄd¡É…îÇõH[•q‡³Ø¢óRéXòâNÜKh.„9Íï2²@XŠ1Kjø®ŒVé´h³5ÜÃç=“†î]Ñöï 	Ë{˜äÎÑİ¥bÿBÃCƒ«³pí_6êTó’	„Ì>m±È§ö‰:À<læ2î‚¿†Ô°lª:@3£ËÙ8™®QGÆánÔ|Y)_p‚·ÿ"`äÕ3Zq?¢Ô!×‰ô²¦ÔéçjÈ½‘²°7ümıÆ—üã®Èä<¶ğ¼lbŒà€¹´n§KLü›ók.¬Ÿ“7Ş#Ââsÿ]`;Í„í $€œwç4'ú6E‹P¬×D‡‡”²[÷ŸİN\À(ÛWƒôù%šª›­-§bO¢‰
sºŸ_ªXÅA½ÛSïJsö¥š…İQIÁ`Ü5V“Ê;üÍ·Z7]X£ëD5S.˜"\,ĞL/èn–—d$%.í·ª¶Ì„Œ`BÀÿ ¶Pù¯Œl¾71TÈM«ÒA±9¹¦·$JH»eâÖiò’¡…²±ªVs:…~UX-´@Õ¤óiŠÅ}æV¶¼Iå'Ÿ[påDÒ?w|ı!MÔ˜—3 i+ûÄû+oQ¨t>nÆ¾{újÀ3b(¬ÕDj7ôˆ¸>õ d³s|ß£FfÉP+¶Qsº × ìd|î-7©TÅƒí|Ér…í¥—œ-¹
Óãy?Ğ¹Ôé¿iHàq¿~Çúeˆ,;¸5vÕÌ~¬öZ/;95“Õ¦ô•—áñ£†î#d"°œB4áÓşömÈíÃOMŠ½,÷’ò,9…&jã‡æÕ«~_Q¦Öc<íëIHUM€±şâF–qâ>ƒÇä&³‘ĞÇõ¨ß¢*Ør©©ÔÑ{_Ã]ü±4nÈ¿W0€˜¡6´‰û{{Gt'ÔŞêQu@Bç,İøhx@Ân‚¦x_t˜ŒXÚ’'÷#D.åjÍ5o÷èÌäÛwI’- ëq$c¤y<­t)İÑÒÅÓ€ªŒyª‚‹^[•sm½†÷˜ûû ,‚EÎ‘÷}(ñ×wØlK1\bw
P4Ş6Âí_VÈ´G92†Ñ4µ[ı@-O÷ÂÚ¬‡X (ùIï˜€_ùÛ’¿™bE‚·İNÔ†©s!±®¹+[â¾§JRW·‹B@\G¹ĞW8r¶^ˆ?©Øór©;|]K8êXvï	î"/@s£cƒá•¿ÖEtùãåxâ–]}ÂşŞè®<Eåy´Á°±y2ÙÆg|TeĞ–î-ÓŞC
R=›E}Í¾^Åx•ò®£¿åµûğT’=	ŠK„Ö/_Küb.‘#À¢R=t2NvğµÜª¬´²›‚ıŒ/4³Â*®ÑvgÉ¤¢ÈóãæÖï#õ~Šq«>v§ÜA$1qú8zr›£AÊ9“EB„·JwæÈÂ+¤.5ÆÀ-u^­¨(UÊmq?™À/]œî´7®ÖbÁí	ñl ³=[ÃEûC åQašÁ÷“?fÔ!9Õ K}vüÎoš°×ØrG‡LÜ•õÁa’±F,7Õ8´.0ÓËK‹“æoŞ°«İ&ôuí:`=Ö¾I~Èo{¡e°.™ù-HŸîÄ¯0ñ©\U_%¨»ÔaokI|öndİl<æE7¹í‡1ûSæ0Y
w~ğGtë2ÓF™îoN«.sOÃîù˜c(¸AëH]ÇêÙb’Fm
ã]Ÿ 0ÏRïBñ¤^<®A\ÁrA'.ï’Qo-A«8ï 1Ø&nˆjäz5ZZK½Æä‰VC*’ìüK¦{i·úgAÊ)\ôyÍ&ö¹q„¯J=Œ˜ŸØéFvÕb^Áò5ÀœUŒn{Ë¢ƒ\ÒS"?áX?§ù6Úiğ¾4ağı(Ô%ŸSşµzSÒ.ìùl&L~fRØ‰$ó9ÊãĞêIhL
¥wòW'8±XSoµ3u–:Oà´æàŒ¬€¯ş£ƒWÜ‰Ú-•ªu*¼ô¸)(_­Ğ2]\J¸SÇÕ×ÃÁ=½Â=Y;Š™¶zx6FÂ,viñïÁûü	7O­È\:»Ü(]ˆvÅÄå‚¤WOûê?ñ²—<Oé€)ípA[¬R%Ò÷ßyWKoi+>‘©¬JA	ŸÓ  †L1‚d)ÿ.7Á3„ÛbÃÀİä`H"úÎAja.&sÚÅNIh×!‚_à”•ó¶¤¼³^t»T83â$Ä+1  …[‰q•¢1–˜4
ğW™}ĞeÆ—$1h²	Hş-5ÍWkKÄVSgÿ<°åIP§tâ§öÕ¾ÈK)JÖew—1ÃÄæz,ÛÃ}j‰ô]gÚÑw±hyêcyYáUŞÓV[çWDã ‡¾HPÚÇF—Ö:Ï7š©eObnò{wÖYC®Ës'xc°5Ô	¿®İ¸‚âÒO¶)–_¿½«ğWƒq§fXÙ›±D½ÇRø¶Ù„<– ™%ÿ›ÊÒN²Â¯ñ«¹­l·?ŒA8ÔØy:7(Oq#_¬Pü bó‰áLe­2j“Jl4$Ûe÷½’Ôœr"Ì+|tÜ‡îQï5‹“n‚¯ €‹ìµ·ßH{}cÇkêL8Õu~f×Ìzš’íöıÀÆeËç‰JB3ÌÄX®w††¤ö¢‚’æ_âşe ]­v¬+1:Ú´Â-?²FĞùwö—nñ,S:*LÂ.¼†ïlèyÆ·ŠHŒ!p¯‰S?§f}¾\áåf‚(úM§y(à½Ã„G	TÎó$",hÄëvEç[Í7†vyÂØ5½„^ª-}/ c)B.3üÇˆ.;!ˆÜ«`É/rÇì·(Õ¦™x»ØyBb™,âA9K×ò¢šQ#q—Ä®®1/-ˆ˜hÄ£rmQÏU¾›“lTık„Œ˜LW4¯9ãœ>èwå~¼yÌ[®O&6PÕ3¾ğ±õE½kæé¾yÓ‚+ï²ºv×]ø¶¼ØÌËÀ¥CMè4<«RZ¤8Šî\»… ¹m.Îèyz{i•¦IuN§Ôı‹f\Qz¼\Á¨ØÒIàK:ilöË’XÎ ,-BŞ< '™ÄA¥t=FB,CDä¢Ÿ¼;‚~”¨1¶q™!É>¤W¸¦âá™P‡­3dtÆ‰«x’¼*évß·›ùŒIßÁ:Ô’†!œĞjlû%²]î…Ey>hãL¦ÉïDDĞ’¡oÊÁË‘ÄıT‘şq…JmtdçyuÂ CP#µş¹(Ü¶ ˜E7±[íşrèÅñËcÒù4¿BÖş¼v‘6Åº—š:TîBşjnve9DJ*ÏcB¬ 1¿êËXôİé5µù]|¯Îëà"IQß&,º
e}Ë>E™½ßJ³8«î®9\ÊàÕ×Úà+Ö½z±(A'È¤5
Æ]Ïû#K~r •4ïôÌ†Jr@»ÖásÊ ºRÀ3‹w!ªIÑ°«cŞtİœ ó <½„¦zoÔë­ÿ}k§8PSÈ}ÑÂFv¸1ûS’ğ[Ëïg˜ëòO9€Ÿâ.Éæ•p"°?½NÂÁ°0¢SgK6•Ï"Ô#ÿ¨h¥3¦)ªÔ¥¯”(6É­¾|é¬%/"ncï×OË²Ñ!àdÄItüm­é'?5Ë—˜|ï€*;;–ÇáüÇ[DÄØ§¨p?÷¬rR¼ø|Ó/Æë!0GËw½\“Æ³5dïÌ(Ğõ ‘µwv‡‚‹õ×y»”ê„;câÌIWWA»ÙZ‡½ 	Ê&û@$á­V~%:û{ğş€_E‡Ãìİ›OÖÉXÓ‹œÂÖdÑ(Øİr¯…iï'Zš;ß,îŒ½ãz|şfÀô)¾ Š()lÙ„¼OS¨‰­¿ãĞåAô9ã¶-énºQÂô¬]fÓñ(Œ¿z]ÇÔúßQÃWÓ­ù<’Û}c˜GşÅ¡`ış.1JjÚ™5âB§À¨:Ü!uÓ0Ö“‡«®:¾ı´_Ê²ÖÑ1oºÛ[*l}#0k0¶µùsÄtr½2¦ÿa.yc‡j‚;™Ë¥ YÙÕ‰¯û—cv4®Õ¦,[ *æ_¶%º™‰ÿ¸&(hİq<TÇ"•®oÈ® fm·}ĞğË/å:_zŒÀˆTPğÉBù§zô~ú÷µ]a½ÛÓz¸ó¨Wò^ÈÃvÔë­“WZ?›Gs{:GÓ"Áø¾{ğ/
‘&C<±’™pr#ÁÍrnaª•˜g˜¾aÄ³m+2%†Ï*1®æ,åeó±WLÔˆé¤!ªC³-œ¡’Ã`ç†Í¡R¼2Íœ>yNI(¹iÕ9ìVPá¯	¡Ó%Ñùæ-õSë;
Ì?0ZFj¿5ÅMçÎNáH‰ x>‘À>õ¥ºhåÌøBEÁkı·Bş¢9®zC6"“±ûÜ¶rÒpl‚hÕ¦¡f5Ó„L8S¶¢(!†Wezx¾*Šì4…¿|w­$*c(‹l
üR<Aj…Ã„å¶zı©ftººtŸ+6Í`ÿïÎƒ0Şd0SPÈÈH‘¸¸0fE´¨;S]ÂôWTEØ(ÖB%Ò`é,iÕõŞ…û÷˜jÅª#b=¼s±¢+Ráû|^Ê³éÁŒTòK÷ÂÔ½döyäÍ6Ä‰•I´‡%¤3ì›uiš,5EÙ7º»/Xxô{¶BÏØÀûÈöğÀ,Ğfb·Üüê
í†WÆÉ÷æ¼Ş–xÒ®“®‡$lñç4*Éèf
ÄÆ¢÷Zö*ñ'„›ç¬ç‰YlJXâQB}Cı¿X–/Yîy¤Âº0	N·“û_n1˜!°ŒÀ…³¹f7½ÙœmKt'`¤y¦€CÏÒfç7j}¹Ÿxe:ÓƒŠÚ{ Ÿ†²ËØH5ÈFÀ˜†±L%C®@3l„û!º%d©FŞÁêiØ\^xŞ ãÚÜ‘v„Êë³B¼´k”ÊÈc“ÉŒdc#0ĞS¸0$ «Úà½"×›ş`ï…(J(Gpi´1}©¹T@İÉHÒä‚AkŠiçæèÕ8Ê¿*ƒVT®q´`/)ŒÚ Î\fMœôZÏÑá4aÑ7¡.¥õ€º3QÈlå6"v£ñù¦tŠÓÑíÌ“MQ8)3$¹(”]3VWOk×HªM}a¡}"TÌ*¥ï¢ç0$\LÔÚX!×s_­šÚâÔipÜ©çHCEÛÚ5…Ü‡P/
°Ş¼$›•Ü½zéF+¹şO»#9v/HÚ$ad—WârU_²ñ1»~Wú`Lc!^`jß¨ hŞà2.{À®Ó¹½¾¹œAğ JFSi“ÈÈ¼
÷@ÿNŠ­])pt´Ä§$pZpÏ×Û–NLhßşe/E•2)¼Eâ°	Ä5…íÖ½šò&(Ï­£ê”îg¼Í@+wNXŒ4Oë$éJ üøêj³f'Ë3[û´«‚Uë­p¼¤
$­C†ßdÚ}°ŠsIz£ĞB©Ã°5‰vº‰€¡´ÒŒö°ùÙÅéWT·Ì{^wqRœâÙªÖö{Sk¥xh-IúH¡»ä”onövYS|½•éfÇØiî/ÕNìdâû%ŠÆ¬+ÓŸ¥½óŒ‰è4P»7›2	BÜPZHşK1_ô5!Üôêvá»îİgª
ÑËXkNuöÕBÍÙğ8¦­—6ïšQh‡ãåéqği‘ÆÜkÒYˆ°zÍ¦Îëi,B…?®˜d¹UÁ”¸Ö#v—!ˆXm˜€EëyŒèO`¢t‰ƒÒK,ïÑ~1ˆ,òÚLl ¼„HE«+ÜpİzWÄ 9Ë£:Ó}½›ûy˜±7µ6ã½í
#Ã¡á“õÃÎçáe1ûj£•&IEÛğú.CŒŠxjÊë£Í_UÉ_ºÌ¥®k²&*úvË……Ç>”h&Jù×È1
ÙÉ¯În×ô?–“?ª$®3¢ş|·­O	:hl€Ö…ÔbİËvæÎ³øÌK¦Ù?ø(ùCÌØ
çYÂ
áÁ™å_Lı6?|E‰R‰gd@mAOA|™á9~Pq‡ü­4J§UÑêÕĞ%‹m!Ğnì-¹4Ô¡Œ‚s~ò³ò¢{ÖRñÇ8Èã' wV 8°¼ne´„ ­ÆY|Ú›ï:G\ce”Œ^²d Xnpô‹Ï&â°cvë:ª}³À;ªÉ*Æ&kNã&è&>†dà' òÍ€ô @îr?¤®ŒQ.DoöéÑi¤ƒ4×S½ÍQĞnjuáÅª0êÔÛµn¾/yüáĞ»tù¹³hİ½È¤Bëtô¬%îîÙ~MÎP+µüë‘w;oN+]Dç¿ï+Ş™¸ª¤Sf-E„¯M=SÉNqÆ×º\;w*±Şoéğès	>Ë¶ 0ñÓlÚñ¼÷íÆ3P$_!LÕøİ•¹Ñ¶-p=ô–¿z@°†©rqœÏœq“PŒef¯PWù“Áq]‚Jç±V+d­CSÔdöğn\Cˆ+-~ËÏ¸øû<Äa"~ğÀäÚ	Å®*<g¨ÀH¹ëG¿‰¸Dª‡‡ëe<ÛvŒİ .ŞuRå™ŸËô½lz`UJ,Hèa1óˆô9±EkÎ@/’‰%ro8”jg6…R\ËGj™«g°¾@Ùßÿ(œ¯ñ€Ãg¡&È³tığÂk–Ú2ÀŞåGº+hïªA¬ƒ›"şˆ¥‹óØ“û*y„c%ûú²’-¦7,ÂSÉ›Ü1î¯îG£ÓÕkµ6÷Î¶ÃWQ*ôÍ|æj6Ã¢ËÜÑòÑ§t€Å¯íÁê)åwµ3‘ÉÃ.€^t<Š£îı•})ÉÈıëT~¯	&r×§-Ùı‡o¤;Qr¶à41›ÌZê{6ì/~mz 2½P4U™­UƒèwÏgÌJ×‡Uëİ‚:Ë”¥r×^Éª¸Ü"'1å”Å“Xq\g-ğÄ¢«D8ÿâ÷B9$²íûˆ[J'©TÄ½ÚHOE&Œ§ø|Û)U˜Sa~¾’ø¶'Rw’ª¼-¯–ÿ²¡œ:¿ @9aÙ±¢;ğ€9Íw¢BêÒ¥àpÔ`%íÑ¬ÍËv4¶¶9zéåc‡Y>…t`:İmc%@¿E©¸¤Z&âòùA¹qPaÚÚÏ/¾ÿOÌ|XOûĞ‰´6…›:èÈ±÷jûD×àÈ¨|Úç‹WıD­u\`u€dv’S´0ğs6÷ÎÿÂÈgAÊ¸¾=İl)Ú©gDWa+éÄ]]Leh§Ù)oİ¤óKO& AhP8Ó)3ğ|qN¸ ¸±càQO­   öß‡GdíÅ2 ²¿€ÀnÇ×
±Ägû    YZ