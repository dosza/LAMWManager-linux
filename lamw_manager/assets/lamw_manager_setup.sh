#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2489963154"
MD5="5b26d4aa0606af535ae88b6d2e530ebf"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23904"
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
	echo Date of packaging: Thu Sep 30 18:28:22 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ]] ¼}•À1Dd]‡Á›PætİDõ}†ráÇgPŸ‹"|D”¸7É‰=¯®õtÜÍ›İV/îÌwØ£P›<¤ô:Å”qÌ‰;ú ƒ'Z–ŸtVòí§ò[yIğù*Ó%[]©à—€(A7ãÌ?ÀÌ´vUšØÈö¬uLIPU6z¾úÔcÕX„Ï;ŠŸığµÖé—PëâˆÙûEû~¶q†¡È¡]œs¬G(= ¡Lô7®bí¿ D·Ç§²ŠÙ)@)%9ÈÛóİÛP†Ù!·/¸¼"ì¹-8.ğqDÀÒ‚€Ğd|Õ ^E`j6J1*†+yêqêxTÉUñ†ZÚ Óºua“†J3ºßÖÕçu)µLÏãz1rŒ•M¤»—á{Pû¿@vºŸ	9[IZ¾˜%¬(Â¨ã[C‚¨Úİ&Ü‰y«İä+FKŠë²eÄˆj×$Â0}Ã™“âÇcÕ(ıú^Ô˜±µ³¸,å¤ÛËäÛçwo	Ø÷¼Æ	<%’ÈóWWáàØE¼ûÜ´M/qg/æšC‹yÎ§d3ª'5Æ£ä8°†B–•|±Ë˜~y©è–ß;Ïnõæ¼?ù]ãÑ}VP´ôù®2®$Y%iØ)ß$O1w§ÓÔâ‰š<),xJÚF0xg~Ç &¼¦Qãçğû;p–±ß'’ÏÇ½İxmF†8¯¬È¾’H›jnÓ ZŠÏ¬][*jwÕL3kÖšÏ˜ì„qÄ÷p;êÎªÓÓ!ÚÅcãk/ÃHP5)€3Ñ­€.$FÚĞ‡}6~#í¯–{ù5õ­ ƒóÊ¼îqš@© Ğu’ ›ç¶mÿHq_²u¶¯f‹«’ÎÎR¨j2’r¢JD¹Y.n°ö;·4*Î "Ã./¿ğûC‚Ü‘'r´Éı1ï(`ÆE…#¡ŸR†Ë®À€…tû†ÒÛã52´åf[§[ññ6	¥Íå~4] F´¾A”fé¹Mm×Hˆ¤¥—ú	óÓe*×i]JqxüXfú=À²‡ãº«Œä ¸Mœ9¦–s¿¡>vı„”ˆ¡ÒœÌıÃØeŠMW³­ïDH„ë6¶ªHı´÷Ï¬<aÂ½7\Ô£ í5Iİ<üÔ«ˆqQ1²°”åø@
/”“Ô¯]ñ-<»?Q˜hÂ®´Ò›¯ññŞÊ [¦a¨Á«zlt?rÿt¬šÔ»‡©˜ÊV	8¯™”LX/|wÁ¯Ë¿Î ÚÂxĞşÙUôï£ËôOXxŸ@Ò‰'€¸ÚÚ®ÆñËÊF©SXùØıŞ°GÊ{‘kDtcUt&Ÿ…1¢çëahÜBîjâ÷İß¤v"ï‹¶U Àd^duÉš³²†&Áê"¬¬«S ¢)QgyY‘Œ†½ƒ*|f	ú×ÖHyÒ=b•C/®éç‘ŸÚ•ëÀĞ{e}fNQ
æ"lúQ#[9Ùç/™8Á¿-5óéÀôT\(»äÚ˜/=HîàswooO¦Ÿ¯Œ~]àÉ”uu7¦äÉä´ºùØ¾£P>–[ÓMn§\³a±ûœÇÊ«Ì`=F}°i²ÍÆºäxïÄ·¼øjÈ`ó¥j¯¢k{ëDÔC¶kQÄ¸m‹¾HG$i
nj2®XÆØ‹œÌaÉi¨gBĞ©„ Òæ«¡Dz§Édë!Æ­ÚGãï‘¾ïn”ù”ã­etö•faõ÷Ngó+?áf’&¿è9&¨v¨;„ÜÓøíOpºÅÑzÆ¯ŒÕ\¾<VÖ¬yLÙ
¼™bîğÒ¨PŸMM·1òÚ¿eÔö#ñâÊñ‰èˆP"³}Û¨ë³¢œqL[6¬"30TH¤så;>…6µ†Ğ7V£z¥¡zúñ¾^ï;oM5[?5.GvÏXöé 8f3Ü À)d'#ILp„}İèFÏ)h)Æ$On7Í¿‚%4-EÙÀÎ¯Êbó»ƒÃĞ»;-7…âôêöàÜzrdÆË{Ñkòµ¬É§¢óÙÀcg~<0{È•å „ÊÖ>©EÂı rnªvïßOè1)PÊ©Ç^*e\õu<º°Í£G*ocĞ™fNL‘&bPªÄºÂ»3;ôÔRjÙÄğc¦ï=LÇÌ;ú;F{;álTå¿ç)y‚øQş¼77<P¢,ÓA¿¨qrPQÇ49f,²H9ŸÍÚÚ"õù‘&u¥(ZO*œH&vˆtÊ6µqo!sà…¶²-.¶_üÜòâ™Ù·&$ºcQ©1ÈÕYu)×	´D,7§y •»ÆaöÿgíğT–I”È½}kÙ!]ØwJnÙ„X;EìI0ı‡)H^¾6¤ÃhëU`+°g©ï 5T
bØ ,X‡š·`VŸ™)àèôpU”ƒ–'âãˆª dÇû)úJ!Aî·Æì:L²`†$‹Kj ~)YR']·lüj„ +ıô5]ö4¶§^ÍZ>”B‹Õ2br&ƒ¨ô¥®–"TÊ]ÙŠpÜmá¸šêÜ3Tu¿-é8ü2Ÿk RI:¾÷Ì;<óê`.?âo&ÇuŒ}¤2¨éó*£çVÕ»ùo©õm{ıü «htÏìş÷úp¤§Xã"Ãä°œĞ`¶*PÔG&mJFôúS~r>Yp±ıŸ©OI¨Æ4i	Óë2gâ<vÑï¾ÒpëÖ<Š,CÂM¢“f|sSütNqÈ‹@Otb›DŠÚ¿´©ºĞR§#ğ´€éğá(Çš·Îhz=*Ş½Ï62«°Ù,ßNëÿLĞTu¼6ˆ*{®Î­±·=fË¥Wa8ÓD/,p0?¶Ì[â‚ğ©,~lù·¯ÚYnvk*éZ³o”ñ$]ù 2ŒBw¡0ª(Öğg½nŠo/Í©ÔgŞĞèM|”rˆbX¼ù=N–;àÉ„}ñ† &b„É9*&qıS 4ƒyàÿèÆ‚ıÿÔq¶š³UnU•ìY‡&5}äßWC>u\sWÑÑ’{u¹GÛë•l]î €/ôqÃúŠF ucGìó3Êf×ƒŞB(8ŞÑ{}ÃOÆêÙÎÕOUM'ÈÍs Äè“êN|ü~ƒî°»ŸGcÏTî-Ÿ·¤Ÿ=ù$öÑG÷À§éj±²ƒÒ„}¼öç´`òëÜ[{ÇÁ»²ÁoëÖùY0Õp}sÕŒ6·p6nœü)Œ/£ìT[å“f¯z½÷.]t‘Î L·§´ÍOå–f{“E!í*Œ{·š¸şÿĞO)kigÈ´+œ-ıÀƒ?UÈÊ’dØÒ{‚Eµ(ÍöI«HCÇ²/)Åxóä;‚¿xÎAÁ@€Jï”@Eñ4’†»Ådü¨fq·tt·P½Õó^9LDOÄéùcñ×¥8ÊjNI ïËhWZßûœU£*wñGN\Ü¾rš˜&2ê*%(Éî!òÿşc‹¯şã’4tÕ?öx9pzíAl&@¬=L0–·jÁe®ƒ¾jS›Ô¨ÕánÙÖõ$LvL%Õº±ñxß²Z‚`Ç†¼AÊÒó)³cµ‚Wg\eôÍ|}xMØ D‘øóô-èn¸|ÜÕ¨ûàTŸw˜Èñû q^Špu1ó…ËYs®!7Á-ªˆV…¦’= 9WÑÎê#™Äú+øºûÃİ®”Û‚dEé¢W¥Ô'o´_lè¡¾)##2ÑšcNrp§ô*•¡¼‹ISWJÅè`mısõùo¾uzb#NU‹1I`d${À§Ù(Å™ïeÖŠ7Í_Ø¡._ö=1³r.ø€ ¡áÚÙ Xİ/†Ë~ğ	™óZµ†Å˜ëÑÄc¾C[§Bf'­ÊÃ1—Œ£”K5[Ês"ÌI–WÌõ¾™íZ\]v*V>pê§$¯âòÙÔŞ:Sış-Úáò\À›åqU¾Z¼wŒUsX¼{ºcuªë~‡ÄìC&ÎúÌ”o Ì~•ş‘o<¡E*t-x˜·ŒZâP×¼`åqòQn
Y#s.ü	 šÓ`Ï·P»Ìb´©Ó	‹Sµ?t öWÛ´Gœ3ÌÑóÒª÷ˆïÃÑnT3ôã-hwÑØMÀ`šIbïoç~˜ı¸ÅİGÎ.ü9·f-ï/ÕÃ~c·™â‘J‡Ø;á§'i DSDèíÆMkõôK®¬»™èè²`\	¨œpA 0ê”oc¶H¤`¦t~·rkØ9ö¶íWg2º,¬=­ªmD† ë&+b½Šh¬ÚkA/F‚¨Ö‹EÂ%½÷U-}WWyRnğ¸.®ÑÊctTHó>j¬ûĞÔÜ ¼Ç¥±õ HMê3¼ÚçZ¥Uï›¶Mzy {œÔ›øESÍ'UÅ¡ÊÉİÉæ¡ga:–å%ËÛöè
ıÀß–÷-<,†Aü#ÆÂÔ*±3Wv%Ò-Ö¶r5ÌD{>¦=;¯5{]¹bÒ*vY–Hİ°óîÙĞMtm~‚üièãA·˜É yW¬âat^b1‹U–lY¹¨Î¦rZˆ´Aq—Ãu¯XåĞ¢ÿ3ÚÎ»
¨)u/± ã£Á9×­v½0éÕ‡5?m³eyÉÕ‡&ü;—ñŒ©¥HìÄ·Ø9ŞÚGå«ØUÈ,˜ä¬zÀ™BúPË9lìÚ-oñAº¶B¹
øÉFƒ‡0C¡pày%Àrv½[®–Iß—Ô\qæÊnhbÍŠíVêù=ôäÎöÿeÆ²2	lÿŒ ğJõ€Põê{û@üŠJ¨¨¡Eı}'ok2H1€²æ>ŒH·aÍƒ¤CEñ4ìy V€viâb±…Ö&&‹ ~RZ‘4¹İĞ…©şírL~bŸ0ò­PMT¨ëtbÅ}VİÀ~“IŞ_ƒîÓoƒ7`À8öÎ†-ùn§øøÇİeç¼Y&6Ëá¼P­%ìx¡Ó“Ié™jKì„7á‡úZ7àW•(åBÑŸknBo9ãLÉ¼yYEF¶'&Şö@Í7›ŠÁ-ÁœsğDtM>bwé”£·©%›+Õ…W3òHÛ3xëõu3 ôäbtë<¶“¶e˜Â6»âX.‰¤zÊ~´­G¹Ìk…¬hr|àš%½ÎÈÜ™§_h½¼E‘ùLSÖe}Y<ñkDŠ*ÊÂãzgl÷Õîş·©ªìã^·÷öë–'ë9súçL½¤*Ö	éo"_{Z§Ì¬xµF—
şfnı8W¶,Óì&iä×2À~ë f¬h#‹¯=”°L‹q#âz€/Ñø‹(	‚ĞØêÊnRÏAï­B'ºça€×3WÔ|,@ŸÜÔ+q—âÔê€ŞØXšÛ3€³ñBş=U:³q&ìLS€÷KeuÎ¸HìÓ´:Vè&Ÿmv¼¶ÁùKØ6nFÉ_¬KÌ
¬x0¬X\`“÷µÉ·°2™¿wáL°q‚wé-5İCè‡:2Ó§€üÕH±/Õú~Mï[†""An T‚Ïm%Û ÚRĞëv‹kÖ	°&ÀÖvş¿9¤€S,ûšÂ¤géÕuDVmC­¤I‡Œ]qü#Ã¦JJ1=›ø{d3¦ú
w$ƒÁğÈP0–È¥­ñœÖÎ­m&¯¢Å±û¶fğ¢Íi˜FGV7NöII
ÖßğúÜ•Dû3·mùäŠ¼P”Eò™ŠÕTzgØwb?î‚<á}”7’zNoòîtræ‰xZİB×iš§„RğIø1Á{&l§1>úK¶øÿ“Ü—Êd¦@¡
ƒd=«i9“ô	zM@4':2blõ•—Psm`	Ó€<èYJ­²i	Ä†:J^ßÃ¯acîò#íöqhœßŠ@º\ç°ËU˜É=`v”Ûd¶Î7®±â÷òs*o|×şÈlÆü¢XôÉc¢¬¨œì¶%‚'i&Äi×ùG“áÆŒV+Al‚Àâ¤š\WıUò%±.[zh™§~±¤ÆÉâI~d„™	³=†TuGš³Â8Ó«õ¼ÜÕcÓì;úh­^bˆœ…R>´ğX‡Fcùóò³‚]j%~¾œ÷ªñ·'ğXê;r÷9èÁPM†ªğ„^ûÂ}~LRİîĞœã$	E-Stğ²ğ)@~É*ü¬ÎÍ€æsĞÉ˜Ê´q’›C(üU‚Ís–—;W/ÕHøø6Î¬Ùİß³ëAúd“ [!¦p:=.»õÉÜ_ºYHÂÜgJîÎ¨CM†yq"¡îJ¼&³ƒÉ…bHO™ŞËyÄæ¯r’ñF¨³®8y:L¥ô&Û‚Ë£!É}
o%ölş:«Øâ°2GüÆŞš%JŸ—•Öš«átıä’!	šõ.IÅÅ“³ÚŞ¡ú~Úw„õRÙ‰/_I¿,ê]Û’´œÍ8#ÄÕ"Æ|Ñx03â…ÒÛ(®Ÿ%®<ÍšFì~Y×„ Oşã•AÕ_Ì°~ÇË)Ôä°’ª¶ŸP9Ù0s$lû•U>Kºš/=Pı©o„ÑÆ_î18ÊEw²0@¬ìBl-–>ÜZœ÷‘¢HÇzl€ËÔ?¹hj@ñİc€Ö5¯Í~šªÄ|)â,	û­&kh%÷¤¢­./º´pÇQTwÚ—õ¬Ò"ÉfÀ¯W»d$PAP±¢şkîàIÅgjíà˜Q8[İ)e@˜“4œ»N4 Íı× }=:˜wÛwşY^Ú/2	òÏ (¯$İÜBm-³’¢ôş«g…ñï,8­*§¶û0ş‡'şw	Cßğ¿Ä~‡Šj¯°ÙÓÅúöİåNR{Ú—C=¡rágiÇeö­é©\.™/®zğsˆgáïcF&ãiê9WŠÂkÇùŸµTãnØVéîĞ¸œëh_2†Ğ}4’ñ(Il.‘£ÈrëÏAÇûN¾ÃÎÑ*Í˜‹	“ù¯¬J•LÅİI
 _†DHä>¶*âî¤íWy~ë&"‡ßèí¯ì¬•ø¡ûŸsr½Í4_¨	”-º”¯^ØÌ&€Û­ÿ©@Eûñ®Š·÷GÂÉÍQÅ¨WLnDQi155Ï“?™ZúI‚w–•kÊ,ÿ•XE¡NI’×¥NMë­ÿ †övMRg–lgæLÀÏçQÇ„³‡¡Â¦Î …àåo ØÀÛ%4ê…¾?=µßx]TkÇ†mÚJÈóÚšù5å¢¯à/«yø]WËqEÁ<¶èXáØô—@àïy~+Ûq îDáNı>hy…ƒVÂ»OD‡~+µÔá¿å&‚b‘Ú}b¢4BÖ™MšB›Fzh?ÿç ægÅ#fÍœÎkVPŠ•3§Ë(:&EòöäŞpå.mƒ_«g%ª.ÕB i\'¾T{¸‘bÌÌzRãI’œ fÆ:§şBçoÛ%)Ò¯®BH nÃŒŸıá@ƒ+‚òÚ™îö‘Ÿ ê°}>y4g•j,ÈÆzsû9ş…ípŸYx
¦Æ³v«muATHô½n¸Šçî&7aS>xia‡ü¡$7OE^À/$6ìü-u44µŞîV­ÿª|å|/ìDD×'À=ğBû­ûx©4LSÑÙ×ÁÙƒµ²á&ìüSè;"N=o±›\4ˆ×p2ikãbtv_¹qaê‘ª”²°>jDĞ·Ğr[ÛÔ`ĞRw†òãäáCpPvà§)KAUÛf7òç™…oàŞ\¸ Â+½C‹¶ÅØ¨©ÕŸH;ê³é›ÿ!Ø{(ˆ®Ùqhã0!NÓ‚…tõˆà‹³r|ÿ3Ã·„Ğ"l«ßY#ÜF™¬‚E2jkÊå3ıD:‰&qo^”ÒşôÓb„/…$ì·ÙµŒÕ™ØÖ~©CoKj«¬ªRrB÷¤å½dõ¤I•ûíYV§ÓXkùÚ&Hòxï.‚L¼õÙD”-ûwÖ„ÿãŞ–‡¸Ô»s“–Åù÷X!6×†¥"ş¿‘uFÎŸÛ’òá.«æ%ÌÂ#Ä2}ô±'å’–Ş>+Åu†¿”xÀ4¸ßÀË9¯š¶i!ÄQWƒIËG‹bÉÌ¢~ècp9Öºq‚%)OóB |uÛÈÖâ®½ñt™ÂÎ°¡- Ï?Ÿ¼µWCs‚¿™+5şÈ”‘ì"ê©ûÑuóó![µY³µm#~•­ş%L_æN6bğy8Ù:ÈÀ<¯£³P 30TS(Åi§âbò®³$µ)„˜Ÿ!­ybY·‹ü¶™Éd½á
Ú¥Øøß——Z†ŠPÒö$(Íô=r>ù›Ë©êÿÖ«ÎÛ,0sÀeÚªÚ¬¨86ÔÂé~Ÿ“zëXAûÁ=ÅÅ»ÖëœcŞxTE@:“åÏb9~±jîBòÉ6üQ«~ÍP/î>ÿæ`"h;Ğ?O¡xMÔ×£4‹ÉQq&“JdáA«*A¨ØA[,'ÛŠ^	°.ùß¹—àÓ$xø•Ì“öBé0Êæ½ôôµÁ¨I*|xb=o‚Uà×•.J ^ß5Å8¥ÑŠÎ!»W—^5Ì†|€:ç¡£‰NÑOOí£Êm‹Ä³Â»åôŸh‰Ãgë7\ä–Î‰_è¯±¨q½×%aóİ²öü8İ"ÁÉˆ¥
nàëJmO"üƒ®üŒ¤”Yq!5Âºİ¹¬j0pXA $"½	:®3qÙ´St¦fòd¡^wX: 6ÁĞê2K®ø Šµ«©¿­·¹ìïö‡]­¾Ø€»AŒŒ°DÀå É«!• ZÄAlg¨ÙØy¹$65Qš>ÿ`ûRäë]ä@q‚˜õR·Ñ–:Å¾70€ØËåøÎX˜çEyí¡_\r
g%ìÖ)s”¤Ö@sè|!|÷!Çcytl¹^8t±‚Ìª%i¼ £W)Ì&Ğ¿—,ÇÎ#·Ø¢<ê}ğ4äX›£'G³H2‚×M¡NAÙÄ,€Së• ‘ ¼­5’íiOJ,û“¦Àø²øú “N¢¸¬«¥• Üº HY o	÷€¬ó	ïü»gû'}È:E(Ç‡ëx/L«¡õ®j·á‡£e¿Û¢ ñ5ÖDÒ¼Ìÿ¼*DıyrLûßR`;î¶f3ıjiÔõğ%‚—2kİçÔU±Rë*zú Âhz#ºŞè^qp£Ù¥ûY¬E2ŒoÜÎÒ<æ³+eUyQ"ìç4}1T$Ó½²OÇTŸ)êÂ–‰ÊÉk&»“vÏ®„Bæ6cDš†übí><}ş.ª9¤ÍñâpŸà YÜ¨ab@¬)Ÿ£ß9`î"ÃüöJ“Pãşë0›xÚ51~±‹®ùãûSÜíqÇySKwîÑÊë"t'ÙËáx1mÄıûúˆYÅè¬]Ó‘£ŒX•KRŸ÷Ï9Ò¶ÖSx3Å`ÏğHkÌ‘i73¯cİ1i]ÁÖˆxBÆƒ=iğrÃA8_ßx´XšQcğâ¹—-pÚ§L<Œ¦„ôÿ§ù>òOş)=Í‰s>® 5Í¹OâÜ„NI—Úr*otgrŒ}hk­ë™»HıŸÄâºj6vÆi1úTš)ğ ídC)ewÅí‘ch@”ùì ¬HùzŸ‚oiK3 ”eXU‡ ûzÂùì¥–hÚàVÎÂ
¾ezúDŞ¥¾*K4hÕKŠG·îhô¨Öìé.vŒµ nú}Ğ[zªÂV.ğwŞ{F¡Ñ,µ8eÁ2îÕä‚?ìØk àHó¹¼»sİ¶hÏºœE‰’‹6[°âv„	ò¹³Á[¡ –zB±‰¡ó]:ï0ºóÔ(2?}¸Î¶	F‡3ëu7Zn[İäHçUÈp!İVoôJ$Â”‡p…Wy ÏE4p*†¿à	²˜$ĞÂ^8eNCp‘äAÓì,/lÛ]\¾WÃèÎÎ“~íÖğİŒ‘îª,»
–YÈ´±ÁdDªÀÅºJÀ§4³ÌÊrÃSk•É`æõêòy¤¦^ XDyúØø	í7¶L©%ìÈ4´ôÁ—>‡“ø$œyƒÂkQ J=iàèôz\ÉÒW–‡¢:š>,"Ÿ~w…	‘a¿†
_Jvd±ÜÔËu İ>Óá@¼Ì [0•
ÁÕ×Ğp[—!H­€[ÔÎ­mÄ%½Äc€/•Ôß­‘²îˆËÄ—÷íÁAê[>¦ ùøÓÇ›$$…ïÁËÎW$iîô4;ÈÂàœ‚[A°¿Ä+É`ùÎæJW‰Ù2¤ß½]«£Ùç(…Ë<ıÚ4@Eí‹.\Ër“O,’IsŠ1Wšı¦ØÅ%òå/t+Ê¶ä[Éu¿p'òj!	ø†á eÂ_VD+lÅ§±®…›2îë¤V={…Œz±ÂÕGC÷j™ÀM<±ÇÚ(4¥>H>­[ Ùó«`÷®wô—ş­8áîî÷šÕÈÍÈòwN"Àú;ÅR»ÇÃôÎ‚i„©#–#ÌT'#Í“DÆÂœÜYÉé\~e@­ƒlXûhºo°2„r9!…¼µ?íLrJÏ•tŠŞ¾Ô2=:N§ĞSLèOvcé¬À ¦«º6^/£‡HZ-˜0„&ïÕaºuÇG_¨iÉ€êÖ„Ÿîä6+ï'ùM”ì»õÃiAWÜzdi2Vöêï ¬6ÎTÓŞñ™gtE®İ•àöÄç†„ôÍ<šnxO 2ÃÎnßr[×tlšbêLg¾Ş^†ïXvnÅ1Cè6$}˜Ä’™¦rJ/ıH³i‰®Ë9,ºĞzâ¦¾jè¿”D(™Gd6‡M¯j)÷(z_®Í Ñ0õ.Y‡¡œ;|›R›7Œ‹6\+P Myf!KÃÎä¸'3cÇ‚ÿd[.„{>›Ş
h”•ğaVĞv%6bØ¿2´ƒÉÙ\L&°)“uu|"}kFoÈFviß¹0ÏJP®Å“¦ïÑÏšY 3ëş‹W„ı4}Ù~ÃT?‰uÛ+.ñÃ=á‹”XyIiÖIùÚ[±×IöşÍWg56C¤tIQ½«4VÄiÀRSrÓÍ¥=xö$ô#BtdöÚ ¸ÔŞ\Dˆ94©|\Q%%®ĞÇ÷=V_†³ôªäáiÌÉ|EH ¯Ë7?ˆ&ÍÕ>€ 9w×¦—xKNÔ°®¯[{8†abg­+ÈåÂM»Õ—­†8sÑÜ‹LÓÛ]ä1›Ôt¡í,\%çRp.’ À*Iá÷jecöòJùBı§%¡şø1 oƒz£î¯DÏ»å:†§ğ$»
Î4Ó|ò'¥Ï—VÉ‡¤¥µhÔdNˆÜÃ~Ô"—tQ«[ĞÈiäÚFÍ˜Â¦LÒ8şàß–•ÑŠc›!ıoE…®V?·8:Œ3ƒá›¥m´d–ƒQAPÑ…µl•XwîÅïâîé²3ğÈ ™/u—=¯Ù2¶}¿…4-ô`¨
÷…)âşÄƒ;]S\Òåv€n™lHˆaø ‹
¿z¢Àğ‡*3e©RÏÓÅmÈbe¦øœP:<„¥·X1»‘	Ü|ÌÔóÂÖ6CÂ¤VÙÎµ©q7+-~ã©À@¼ªóE»?¦×V|¦ÙşÍ"vÌ(‡x`Rtˆ¡ÕE¡º¨HÇO…”å9€?nàÌóyäïÎ÷B¿İÙHH+W~4 ‡ ü¦šV¸AÙ†ø,ZòmèvÎ·TFxh:í‰zù¤€;|şŠ–ƒd$c%´P³·â§Ş®q×‡Rg@Jê‹¡ùO—…Ìó1¥HÁ*ïÑk{0\H‹kfÓhOXèY$l«I,¿ÏägRÖ<Ëóî/vŠû[ß}CÍ1ˆ‹?n”ÚwÈënX¤$°‚KŒ7¬¥¯!Ÿkö;
Ç+ŒX(8/tÙBİ†U@"!GĞÔ™®û.»tİ°V9Ëê__ä¢l-Â]Ô®_J˜R}“²ÀéµØe‘°Bœ{k	Èz²ğXß‹*ëdOkm¢}.BÆfVÚNG,‹O]X?y2B,¶îm è—”ô”Ù¯æä[çØiåUñIÇ(Ÿ5øøtÓã‚ro²Kç×&­ÉzU©ğÁük°÷W“æâÂÖ7ÑY®ìit'4Î¢E68å^v¿I±T¿5»*æXú9³ë¾äM–ü• Şdì˜µâûêI%¤(²ÉDè—•¸FU\‹Á"íôW¢n¤1¡s”¥¾4Ñ…8Pã, I€´	(­-Í,ß Jv¯Í6³44¤­=·êRLù­êùÂæ‚ÍBcŒÿ«l,öZ€$¢Ùâ!”¤#£i'2êJ<=Çƒ–_?mAÏ6v‚ÚÁZ–ö8ç´ %[ío6ø» >nEu¡Áßœ­,Ø¡{™H'{õÓ®DxÕ'Fä$º664o*@ùW wÊŞÓ(Ú­˜/H"pµúp«E«²"Şğ"WOÚgÁn_TÇ@Z2møé'%á”òÀ“‰ûŒü]ğ.¯óg=;Û,$cå&èvª$üœ[x}Åğáî³@»š¬^¾$BÓ¤Pú\—ŞÍ‘c=6
'öåËÑºƒY±
fŞ}ş§†'~›—ú_c`÷"Ît.ê1ãkeÃ ’ÃèÊ±»En¼¤ÖÕOJ´hË=óg:“•‡9šöñúEL©}åY2ĞP"ßGC)‘Ø..¶u¥ølò[ôNº¦uKFT5İÚÌ(âZğ^àt“ØáŠ]ÎqKå)@­Ó_:ûn¸}RãNOşÓÄ'ßU¨„¡š 6f&tÂ,©/Dx—d;!a>KM$bKÌªÂÓX§P¥'õÒSÁ¶Qå$ükÔù’¶_µŠ­ãê0‰O P«„¡Z»DšC^ÑôšR7¶C"³± …>}3[»|=SÀùh’´`ùr‚°l¤&ğhÊx§áĞã…µ¼Œ‹Ê>ît¹I	¡"ª¯e’´’Ì¬±Şg¦Éİ¤oÕ–tÒît@ûˆãQ:Ú©Ì'ATÊ›ı$ıÀÕ®H³\Lm9y™,œ'#˜	"è?Ô÷…Z¬Ÿı½­[lÖ—Í^ÒÅ7Ã İ-ÚQzNİEQ#Óî­®„”¶w~]/&oµ®¤¬³Ï¨“/;C[i3·à›²¨ë01l`Né¼J#kò~Ô‚géc"‘:o©¨©>¥5ä½(i,`yK„$2D\~âNµB5ì®õ>
µ z#™ŠäDÖEú>fãá¢½“O;7ÎGõÇ79•O2I#ŸÂß¢tOÚ±“ÚÄï™6y'şÍò¡[ª‹•ø/cß[4ª-ÔrœçXŸ­ˆ&©V/*AjœT•>Œ3Ö‚ö‘ı¨)¸˜Z×jîªÉ=©TÃóZ0C‹Û™AÉC:†—rBŒójRá‘\e`Q­ç;??½ÑƒÆ¹7¿Vp	DÏš¯·Å%€Á§Ô–
 ëb[r¾š1tbg±èCüms©~Ù²(ª¸cµh&ã!P+B¸psjÑEW†¸ñYjı zqÓ~›ã>ô8,©B¨ÉAT–FìO»J™x‘ü`ËÓĞÎ{R{‡ÿT;—ÉZ§ya¸ïÅM>¦"sëˆ–|Ót÷ä€d3œö–ÎÜ2Øt¼&üiæuş+û2Ãá±¿!\z½pÖÜ7G¹Cí¤¡R#¸hX:â#×ö0Æ3BW:hZØ/‰£X±\:¸x
³å•©ˆøù<{õlç3Ôléõóh¿!jÍÙ“¦oóİí>D“Ğ{ÅHŠk¿F	l“É1«ß­w³ˆ	;a“Ú	-ZÌß‰İ’üíöb‡9ˆ,ód³xˆ³á¢¨ÖğdÚöÇãĞ(Íºn[±®¹®Oa;mš1¬¤MŒI±§Mõ€Š‘÷@ûóäRjúÊà^Ê\461Å.¢}qøCã©¿ÚHyø†è¬#œ|‹³ÿ’Ük=› Ëşnş4ñœyu–¡–íxÉ`7–Fâ şŸ¹_í ‚I¢ì=
’6»ˆ§œe»ºS½i€Q÷ˆ2¢{Š·÷ÓK<¶À.Ù·zº3|–f¦gã€€&*5¢Î²—öl¯ô8Hu²ø!-,Ÿòµ‚sÃø(öeã™·[Ù©ÿˆ¿‚snBPºmğÒ$<ÜcŞ}u1AwJI÷˜'æˆŞkPè-Í“®¯'xøØ QF%a’CË5Ú‘C ¯Õx=zu'çpæ¥–ÑÁ“Döpà&GP«÷ÀÒte’9±	Qâˆd®«{ÈZKpxï†øu
¯¥şU!i£™ÈÈ@Ö`y¥†«¶Eiy$ä@ø’â`;«úŠGÄí•¢ÌÅsp[İ_J8ÏG"h³i;ñËº¥•¾ŠzD{EóY='ë º¶‡zS>?‘Œé¸ßzAs£dåW‰ÛñŸÊCåÙÇ(—>]cÆÃYM-€NÉÜÊU‡0›6gµ—Û¾ë¿WS©Tü¼)©ç!¶N‰
ÊfÙ9EA<%ğ*n@ù¦¸ı@¸ºDû6+5óœü©a’†Wö!Î?¾œêá;ŞCÃ!R“qîVÓj’.BÅÃíeë²Ï%3Îû¡{hÅ}"X^eàÖ\jk…aB²9îê)úat®©ãÎÁË‹ƒHds	Æ¿ÉYxÃªƒ‘_S·¶ƒ5˜!&$U±ùË_§;óty~¼–*˜)—lyˆ#Şæ¦Ï#rğE^—Å$ş³ÄÙ—¬Ü%ÏM])å`¡9p©gZ-ÎúdÌ¦.^÷åíJB­¿%˜ÓZó¶Ã·ıíl´#^Qåâİô”	ù£0Ø:†_n“˜Â‹îV½	ø¢ît½Õ´Â¼ª4k¥œzb—LÖö{Lô+Ñ}}hE¾àı‚k8ÿoìÀ
¨)¯üàÃ×‹S]Â-™(¦ê‚Ù1COÙ}öèí§Z3w²Oo÷©Ü"ÿÆsl"Ok&Mx$ğóR¢½X:ÙÕïíZT™Ï=bV`Ócöà¬ô~ÈkŠ!_ã{§£H! 9•çá¨CÜ"©çJøâvEcRÎİğÉÿçèEr½|rÉ5Ûy³È%Ï«¡ûömAîvÃÙWú ö2ÑpÂ~£’»	DêñÓ6Ê3oJ’ã2ú„ˆQ
®!²p		Öp¯Œø’ñÀo2¯|ºîÄ`6Ào½à¥±&Ğ“Áğhë7ÏÆyzA4ºØÙ24§§kñBDcR0Î¢|Ø,Ò«µ8-N@(¦ƒ÷c‹e².NÔ$ı“öôDçIåäyt©y»×N;2J»>LsÊQM×’ˆ÷¾C[(«&©øÜxÃ ·×ÅKåWëb10Ä“G[ß/¥ïßÔoÁ‰?v!°T¼\
<a·‚æ€á¼Å?|<SÑÜÙÒs+û=d ¥u.æèÏö°­• £íñŠ),Di@8^
»e¾ê‘9áŸß‚úÜBÎÜ·Ù+}àÂ&öTóàúG2û¡Õb#Í$©æüì'{ó¹6¸Š3’ußo4˜EÍ‡„ùãaNIšÿ’'
!\Ù¹\Š–¥%ëşÜˆ	ó‰Ö«šjvÑØbj…šulj€ÖâXxÀÕÅ?×ìo›Sòû¹Ø@˜‰ÇEˆ÷¬nB>åÕî‰t—İµäŒÜ~ƒWk¿ímƒ‰d:~‰OvµsœŠŸ¸Á’'+›ÊË(Ésµ ùE¸ŸëåµÉv
 ®"–HâA;u»kBæô›k8´÷eC Zõ½‰á,•uí“#ŠÛåN÷.v2XqËÿ^d…ƒ®Eçâˆ€Eï^ßÔcÄS‹°ÿô7;kÑğ…ç²ëD á+4´SæÖğßp¨®ïÅà¤êÅ÷UëèıÍ@ğÊlDñ^à¹ñ¾ë?(ĞUÇáNê%°É%YêÚs9ÿN (
0¿óí&ú$*w\§¶×!Ü<u’R‰¨ö›m÷ß\-´g0®Ö:dŒ~iT¸³‘Î0Edà
¶Ö­«Ìfø: ¬ÃçÍ~GÍÃ3Ğ-Õ>€8Ø:tWEÃöxßÓòæiŞ5YFÏ¸åòZZº#:˜:QHxÇœÔ9Ùã±ugÆ‘üîJA¹²Ğ$«Qö¼_iÌ£m@ÇóƒøÖ>ÑtFé¢ˆ0çĞ¬ÑØËmíFÜ’Dœø÷ìo¹S¶ÎW©á30è_â	9À#”Ü/^7“Ò5bAV1ÌÔóÕšVMµØ–=M±Útu—·®>y³Kïf¨k±µSU8:›…9TmQ¡W	k04ÿd®j`2råâBŠzã0+b’ŒWŞ_©õ`±çß8¡ 4/;®Ê£°¨dƒKŞœØë3xÿœsAp™¹Óµ!?s²ìW)ÓÁ1uéÙ0·–¹m¸´ÅEÓJğZÔ€Êÿé~ÁÃi®µ'Tóœç¡/êkÈXË÷KåUlíi˜Øëoªq–ÅsR¥m+’ÈÕûòX†%‰<Æ“vE¹æ×øÂYa|h+›WcDçmøÜ¸¯œ¨­^€hr¼Ô3ÕhYè‡t!D{UKgåM"™’O.ù¦‚KQÚTÎŠ„Å–gZ¯Ïcÿ-DŸìõÉÂø1èLtT'ªò•s/²]Gãd&üğ)g¢4i²Vjx ZtÙ4“6ÀpJ+òR¢@€»t™="zÔÙÕtI¼>*wÕ€7³¯›™ï¬©}ñz³u£¸®Jº Rô»!“ğèC°[‘f\±)°øUf‚$;	¸±õ÷™³)ZVÕ±À­õÌ“—¡£Ü\ê¸- ˆ@Ì S6s)-}ÅqÉ¿ÏhPÿ=­— š8¿Œ1P¶>V¹JQÖi[-å/Ì°JKˆÅı=úuèa8æ—Â”c§rÇ@cÁøq Ñ9•Š~‡ü¬4å¶ç jiè^ÛÚÀ­ë•z'r¼QàHF¦ú8‚å÷y®ƒdGXZŞ'_­ÔûOŸ€Ì%à›–HŠxÜˆ$tõäßôuU1÷š*–÷…óîDµ—ÍQGU–ÈË'vºÜ›–ëİ_Se&ÑMƒYU}ÍÌ …Ç#a,ÌL™8º$pG¿QYÀÜÍ(O ÃE©ßJ
Ù‰«/òµù8ûÅ\ıoï™¢è5ÉòÜ!ŸjL›)ƒ “#œ4ØúäOóL9¡Ì¶İz–ªnÇièïMf*1Á;du ò¨ÔÆu#1)[Y#ÔÒ@tNi¾1–¤­øÄ#dÒ[_Ëûà–3E¼W;é<7ÅIbÉëö¹	ÇĞ½Ùvã#ÿ¤¸ItÚ Q,†šeÃœªŠñ9årš0a²ÅYŞa„…-ÄíˆŸbñ÷~
µ2#ı¹3XRI¼E9Sw˜Ù_*_{Å^Qt’’šĞ˜'f¡2*Y"Kû_™›ƒîê¶³…7[Ô¬‡ÔİÃÀNğ‰Â56]ÈdÑQC’D?şlAóİ ×o’À8"½À,Gõxí:u­BV ĞñßlAW!;õ©D"…sM†`ÛÔ4µ*«ds"À¥ŒÅ ı(É'³Z2E3…R´û}*…^Î…:¤ğ—à÷)<\ÂÌ©şûøÄ¤J6ç#%é&( ~8šps]…ˆ ÇÒ#£Œh´óCrªÉaZ^M˜D5&U½°xµÊô½&«@ß¶˜#…yºDUçúª³¦ÔÊ§¾ä. VÛ}ˆ¶ëâ½&Ùÿ®í&2P²G©5V´Ë`’Ø×’s½d… öÃtİÁjF,•Y29£S^ t„YÌ³—(×Æ	¿àg BªÖÌTÆ…ÀNç…_äôueõÔxrB‡ÇQ…5ÜÑY)ùœ&+ka­YN”¦6E'ÚP!’‡w¾Á=Gu—ö÷]‚ç¡¢ç3§Ä’³ æĞ"°ÿ2¿Ü­åŠË•N-u†’qvT¥ĞvaÁæ‚@ş±©ÓUoà7huZ
ëWÃÉ¦Éö\!'^ë Ş3áÍƒ™FÌ÷%ûd&´ßÚzjî K,[k™mmjæÇµB\i/hûòüT"Í®èç?Áïc\jºNà¦º»\-˜­q¡±©Õ6?œèƒüèai
‹ì£ÉUúL¯_ûº81JÃôy Rñ—³ôÎ×,9/HÚT¨&d¹ww/U­IcFsußñR±şö#Ò¥jÀzQTs¦‡°Éã\q	®ig“tnyÁ›ê«_EÕK´®I-ö:4¿îÆ¡Y(	}ºÚ‰<#c)2r‚>…‰÷“lxC+j¿À™|e)ŠE	ÙÈGjNpA›¬ÕÖ›/}‡cå} Òñ[
Œ]²0AË"7ûš³¨şáü!/åÅˆ´•ƒØ›qQ:{>DfŠ8hçÆz|…`d7²
Æ4¹ÉM	3ÒÎ	ñ°*MŞ~‰hníşJ–²JÑ^QÄM#M1k5ÉÑ×GW§Å³ó6g:3
©•5%ÁÀ™¿mô}ªj=FOşCÎ	«[¸
R—[¨mù|¾uÖ5¢?ÇÚƒê5ğ4†(×¢œbË PIá-u¼Ö¿°}1‚Ìö^@arši»Ô¥6Ô‹ÔèMo»4<*Ÿñ²¹_¯'R˜økèèG*¨ZĞB¼!Zˆî¸`³‹¥dÇVô¿€®*¡êvk|´ği	,ÜİY©©MitÏZ¤[½<ÖGÆ×İR¹%:-¯8ÕYışª­å%!,4,Ø€[UîñF™æî“ÜCU¨æŸ³÷C˜+aÁ˜ü¥šPÈ7İ:ı+½¨©åf•¦Ì-+‡VuıK•'zß$:#çE¤İ1Z<³ÿvô®“F0‘1l¹Y€óè@ñô\³àÖÎ­U-Z£Ô¾Ànnw—VÜgt¦z±cQl}Ü`Ïe*·şÍ º]«ØB&k ®²C87í°Àõ‰E›»ÖäŠ±’}¡M)Íöºàh“x©£pñe@şÃæÒÄH‚ğWMëê]P#zépl§ı­Sóq´[šöÂMq•'ş‚ËŒş¥p:êÙ¡i¨$nşQ$´¹›xp~ÙœÚlçÀJ÷ÙAÄ¾RÅ(l¿¿›v¤@bŞÂ8<ÒÃÚ€RÏv.Ş6b–ò]öË?¦y!s­¹­¤ú¢gÚÚ'I¯ì)…àçÍåÇªÊİH¯_İ”À1?%öº„($(N§¸ƒÂÕØâÄ#ó<âˆû8¤$œ#™WÇnı«p¾IkŞméÚ¼µ%Ğ…µÏu÷o|DìÊä.$-â4s&H[êuÎ3ÙÍİ7“Œ$áş¿p(!8D°Äyw ØÕo ±ôDÔüĞÆòÆw½>±èezÇŞ ±vÄl‰?(£³eÑÓ¶]Ev¯tWÀÛĞ½æÏc¥ÒSŒ3 ­~²Ü“»‘ÊRûÂdÚE‰Ñ¥`Eå[Ç@hÿZc¸f¼ĞÅqï	†½¹7§ ìœ4bÂµ{Hb´}!9‚Ìò5 _6§"^dmÃ´@/œâNR’Ãşªç}7ÏÀdÃ2ë7hIB”;2¹ƒ>²­\6\c¶3iyı‘Uù­˜ÅÄ€J§xiEK[q"^}bïĞSÎB¼§š±±™1ÆÑ#ŠAhì¡7L_«Rèq’4)tæŠ'á%ğù¶~ş‡ñ;ÊI´u]¾®=HSZ?yôúÂ×XÃ:?ü
·¡ÖîLLÜéxùr7³ÇP]üz¥¿r‡n³<üáæNÿ–gÃÖQªàƒØø‡W€Ã÷ «û¦8Ã‚D1¯aÁä¨Ğ¯Cçuuf¶{RÆôâñ•ÿ“ïBDcb)wAÆÏwªÙŠYu±Û÷Ùàõ»é ¢h’5ãB™¦ Ö¾ˆOö{3Q«•ù%»Wæë	Ù¿Óú£¿øû¹&¶”'³	^a%ŠR+aTSA#¸¹5pÂúÅùôß&ÜH*¨£gÃ^,tH5¬û¿8ÇeÏ ah¬òÔøÈ€ÙÔâtA6&Àêœ/ÑY³Å‡F;8§ÂÌBø]Ì¦¶DRÙP`–d­…Jì/3ÉÓŒ¬^™Ò½ÖzÈ/µMÏÀ] 	ä€qlÔœ;Õ4çc[¬şøÌòÛVbÆŞzs]bÜ&"ï–¶^Ğ¬İ
)Æl4`®nÅ™‰—*…XI‘CÂŒC´oøÓE—Ÿ‘zÏ£UçƒˆÎÓF¢ÜÑÑ;<>&sW´5€ÛK¼;İaJæ.=ÑvÈ_à~¢E`)÷àm!!÷^p³µ(X‡(f˜ŞèµZ_ã¤n`ğÓµ§jÜ(Å§*ñ‚~ô LiGz–l8üußDø;.ùàqò
õ+ˆâŠI83¶PLP4j4¤µÎ¢ÕR+ÛÆ¥ÊjäûmÜô[ÙÒß
£Á
eÌC6Êö\58Nğ™Z`#Ğš[H*)äª³/Úô äX~èïŠËÙ–Ôv@ó½#·ŒxVúdºRyè¶ÁÄ¾4¯tGŒSq*±’;Ñ1S)páØ•-Y¹-<½Ù@9'¾`Hôõ6â¶©âiÀÖEµe1 {/ÿb+ 2P†oˆ„iVëÀcœ¯âÔbéK<ã“åÖ.„­VÊ·J{dŞ‰Np[3“’iéçæ7¯~#h¡ŒU¾«»Y8Âh\OHø¸°¶
‘Vÿ©ñïQaÎêË£I|2X”årŠbw¬ÖÊ3IAş¸zâ…‚_ƒĞuQ‡Óñ 
U¹O°‹…›t‰˜&…VÀ÷iö–*TyêDd¯ë‚ÒÉ’áO5QiÛ3³!pg—>˜„ÒG¤óTCï’å¾«`üúŸù$`ß§Å váKùFèøDn	¼äĞ“â¡À(ÊT¬‚±í#œøÇ`"F>dE­¸š‚R×!›_M3–.‡‘IS×·y*Õø{Ll4 pş¯—kûøJdî>^€„ä34œèQ@÷mÇvV©O•n¿¬»¦ëßø;gW’àñÔÌâÌù–3AƒË×…ÛŞçµñ\»7ïóg²uãD–eÊmôü…œ3şP&åÊq	³.+’^ä}dî7=×ã1Ë›¢™Áìè`ÂÆk9	ºâùŒ”æò»«:Cµ6:kg‰ôSíxzâô£i¤?i‰.ä}İ>ÑPçÄ@
h;çåÈ›±¾ğü×BsJXYsÿŞr•'¦Y)×Ã-`ƒöÛ/]¥ßòº3ï‹ªK&Z×iU-ä¹4-MÅUŒ¨X·^híš?tcÊbX¢QÛ4’"”^¼*W>×;|'Û ƒÄa€¸J†j*æ ¡úÒãÉcµ÷X9>	
 çœÈ($”z¥F»æ2£´7¹d±ú˜¤Å©‡ãYît/¨É4„P¹İœ
¹=DÓ`?Şc‚À¥ Ü.MZ·X° *xmÀ&jmÏ¨Õ§E™Š±kM¨>WEÀ{&âó0fQcî9¿©ö×YrnæÈázw­wçóY"¬îõ?5Ä×W}H“Ê¡$â!!šŞ²¡5`däj˜´´ğóÀ]Òz€™|Ø=Ş1–£ò$šú³L)]ÜˆmÕÍíß‘Z›Óû%Ã¶¦óTLŸNõìô“¾š?%ÉŸ¨ƒpº]®ƒtçı=¸&_ñ»ÓÑP˜üş;~®Õ^›®¨#9/ËâeS-JNı ™ûî€Úi-ÒÂÿBì"RncÚÓÆÌàıB`_Š&!/˜‰àÂ±­m0Š—“VBğºßG{ğBšZp«íÂ­nÀQ|ø ÇŒ©îK…Şóª%¸ö§AŠé£¡[ØÎ±¶4©%@Uÿt¼m`¸IÑÏ8ÏúøÀïºeÕÏºğõ¬'ÒÌt¦‡ìÉ3»»èÚ‘…½löUQ!iˆ4Â+(ÆÇ>ò@Ø»…]}¹Çœp™è§aØ­6oø#0ëºØÆjoıáÙá¬=d_	RˆË;wg9_ş›´.#³‘÷%öC6€Ds½ÊR[l@#ÙW0ÀW—n ²c<·¬÷ÒlS%’ò:
Öƒ	‡B™„q5]Wm¾°‘n¨x,+59”+¾­«eE«¿İ7«˜å4€°¬¯ìáNK(ÜïX‚”UTÙcò9B6¦Y‘V'“º}³+äôøÈÎÎ0#Ì˜˜=]©¡ÑS{,¥"ŒŞFaöÉ/HÆŸ¢bŞ0)zmˆ¬j@KÁ#ûÓÃ-\ó™GÙÒXRmTdÁ¢y(7ÜôƒVÃ¨©Ğgœ´lÅ4‚¸î!Ø!á@…S'6é58ÀëzÆÇb[_ÀÒ­kZü¿âŸÔé Ú»‹ñ´®·z2KS]ÛüEî$]vhø¯†ñ½¤3›Ãº00hå´s àwM9¢Tœ~ßãU…+¸º0¸/((cı@Ş÷ÂU ùçõ±H¾´ö"hMöoaù.È.Ã¿d]| 9w¯„ÚüP´*&äÙ†?º„.•â5&9Zpš¬Nuc~uÒO]úb¿İ³^ZIwæü^sÿv®¾âFJşBB3lô@]Kv®ğ~B÷©—D\£ñÉİìàC¬Z-™oõ•`A6ô$v&Osã)ÊY÷Ûrö@% 1ê°¤ÎZVdÌ7dª«d
0×İ7ı	qrû>Fì«‘!`¡N_ğ¬RÕ-C=ql]de°Æ ,Û" z3u†,ÿÏ¸v>®>#¨uzí¯Ù:
,˜İ}~ÚÈò–ØÏ`Ø´÷ 
’¡Á´µ&Ó@Ü^—2Û]Ön@[ ‹´µ­öYæ˜á¢‚‹64ÜxL%ÅUK¨Ò­yÙdÓ»ï¿ş,2bb:ÌùLæ5CwıÄm«ùYy&¸(J¡Ô!Ë*ÆöÙ¸¥·ş1/1é,8zÔ|´¹5LJ”Á®#EîE¦ÿpOrp)Z5ö_ô	#Ö²¢²Xê™D÷ˆ‰2!¸™H»‡"œ1—B³LyCšÄ(ß¸+¡™Zp>³Ï¤‰ºCğ‹p’ –ŸX(Ñ¢gÙ4M…–òÈ=C¦ª‹N<X_€ö9°Æ÷ÎÎ««i—æ×"òl,4É/R«”´m0S5Ëè¤†çjv¾p¶¦’¹:§´·×/&önî{úi5Ğ"W>	Î ·¸d’€µQøaÚ¨g¼oñ;Uğk^ AwûšiÀˆhTM-?È{CÕ,rÉuCü¹A^}AûÚ…Ğ¥"°Ï³SPAşnYÖ¹Axï+Ÿ)K_KkÓÕñ3Xª¹O=_-ˆß$ÅÌsbÆ»ué:äÌŠ8ÜË,‘Œëz;9JDğƒN;+)ÙäÏùäØ~_@naù”ş0ŠİQİ,­ÃèFÿÚ;İÁñ“ûQ9X$•và.¼7nmu]”q†°Í\uİ×uxìcñ#¸ÁÔ»²¶AQj™xŸ|Î‘;yOAè ñ›CòI³®RĞwLãf''h© @Xtİ{_9ê÷ş4r–Ó 0S%±ÕµÚƒ·`ÕS&;ä¨ñtó(R™º~5p‘Ø¼ÅJ±Ê[ÍAÆ†Azr7ÖõÜ·ŠOš`ãÒ©=ÜkQÍ©î@Î'M>'ŸIÑFÂ­Œ…K'aªãÜ¸	ıc'Ø&]ß84ŸŠ[òTç÷³­şšëFÈı@›ÑÃ²+‹\#åJŠGëOì·Gº,Vºãu]{İãÊ[ÎÙ°ì¬H©9cG¢x4qlÎKŒ÷ØÔ±‘Ø¦gIµª“â³d¡:=ºë“ù4JyæåÉyB! !õ–kû¼È›ÿı«÷®Šµ2Ÿ78èyª¨Ç9yioĞÀZKµ¯µrš»û7PºîÕÃ¥¯GƒtÁ‚0—n†…é°œXUÏŒ¼…·¯òñÕx³RK¨€ ÷0ØÏÇ¨ùë‡V3âÔQµ95U?«:ÁÍ^ê‰‹Ø·àZ?¯f¸Ø§À¸áÎ<Ñ©ÀØƒ7b7ñ§¥Ç¡Ó¡4ùšCPt£ÙÃ¦(`™ùú¨oû8'O¸mv^cûT#
ZÊğÏI°aMa—S¯'0Ÿù pÊ¯oJË;êx®8
PŠÍld,6ê°€õ|[€ù{ø"
=E4¸E´œ2Y^lëíÙŞMfì‡½¨eDšŠ¾I‘K£´›bºMŒ6—äÌÉS¥©4)j{–sG·B·æhWÃYî?e.Ä7{Xd‡ËJNv*¸rêX´æ¤aDÿ»Ô_JöfoÏH„ÜİsgÛñ‡ÿPƒ•ÛWüÜqÃİNÈ4høvÁ·sö›m0[ƒÒîã·¿NĞ%ÍÆ±°¥Ï>›çÜ†E„# Š|÷>ó<Ø¯,kòœÎoo ¾å±8êDUÓÅ;b% CôÂøNNd_ÒG3d÷‹Kÿ‘¨ù¡¹!^’Í¦…On¾rÓäÃ“p¸×ÇñÊäÇ­q/¤ˆ6Î˜î{â,)ÇÀ<EËO\-?–»sªsÊ¦ãşåºé]¡+ï{¨7¥¯—p³FƒÑ5ß@ÀDòF7àb:iÌ´¬w…¸¦R®Š!:æ6&+Ëjã9X”<7/5·3Y`öbŞª³%Š®ç™’×ÑL¾Üğ-1|ÛÛ?kÖ™‰š”ëÈv!³J·¸5(=´˜ù 5~¦m²-›¯Ól¼SÎÑql5ÕZ^¿ÈNRŞ"l52NÀrr,YyQuÃ+±~Ã|ıŞ ãXÒÑ$N’£áRÀÃª¤ûÒ_9ş&zŞ$i¨–@|ï²ùdPêÈ1@W*»rû¢/zÓàhcYyæmÊC¾< TŞ|­*Ê8z%t‡s‰£E¦¨Ñ˜q$Ä ?JJˆí¡ıÌ·,óÉˆW+ƒ8 ‡Ì½‘\¾‰ê.Öì<üX·¸jEPír“Ğ-£.vE3¶Hëßæ+r‹Rtâ^q•W‚f÷ò&¾ìmîzQ/¼ªÙã?›z½½'³¸ÕäÂù Vi":è]ã&œ
öfs–JÙÇW?'™'n×1SÅ€L¯øÄP\ Ïõ²ib&L¥.˜ –F¿¢­‘v°¨JCÔ¥·•$£Œ&‚zÉÆĞk)/coäÂ±~L½o(®ÅQƒìyE²“»<‰Ùg–óaj”!íZ®fa$1![yøÈ7­Ø&Íiw}NQ`½úÎË5–X«1½ÏÀ<ƒhÌÄ™<X÷°KP#5§ùq-ŞÉˆ15ÎıáÕh_Euˆ&·ådS²VmĞ.b6|ÔOÇ³œë4p2£uĞáÆ©m®±´/XØşµm•Èƒ³#$
²’›ÆÕ÷ã¦Åúwƒ«ÿ 06USõ¨jĞZ«êã1~P¼¶DRü«Öş‘c˜âş&¼¹´2¿/¡DƒÑÍé¸Å©ÀsG*Ò6`\Û-?ëÂ6ğs)-øAç{„í/í)şŞÔáf5JøT`å¼¯éÕr…Â’ïF7Ì0fY	ğ‹Eúb«¾ƒF¦0b±T5OïH6»fû¨3Øœxáç"’<qğû	u?X÷iw¡´ã0¼
€áˆùA	iïŠrşË½«kè ÔPîf‘?1G‡¦ƒ3óCß£ëÅºm:`à(iÖı³³|nX=¤^°±3×èô˜3/ô·A6“ÑIR'mLÁ«-Ÿé“z‘«ç ex_ßà7×©~„¸†^8ªç/)ÍnÖj,÷)Q?©ÍÿTßsIÏ\p	áşkÙFÄºvFç±¹ÍdêQƒœøJÅV!ù¨!v}B²ê±ˆItØ¯å{v¶Û¼yã£Á¶Ü‡õ4po¿m€’ïºÒa†ÿÓé-ÆÚc–µßEä¶'?5şğæse×—6İÖgC?Xq²²²šcaƒ MeÛ©Nui4Øşà$Ãøò,Õ†á½–Ú×>3¤“\*J·–u!öÄ´^ŒÜXü’¦×¥µys¬Šó2ü€Ã6òkäQ`{ ÌŞíÒ¬&Á²Ó+ÀÛ'Œ=jOÍ¤ûŞËíx¾üÌöx1¡#-ì"§ ’«ôn"§!,$-	.¾ÔU{G$şâ¡b~˜ùŒË8v/m‘–¤ğ†$¢„ÊÏpäç6ÎHŞô)ú$DC‡ª¸’º¶¹ÖÈù  ;úl‰üœî`…àõelüº¨å½“¯éu²Ró§åcGS9ğ„[¬Ì°ZM‹øª±XÃaŒ¨±f `3Ûf¬GÁTO¹ö–¾7"º"G<?ƒ¨ûr˜§ùç?Çà¶åõíÂ] _Cd Æí·ÚZQ€v0¥õ7cá7÷uíôºVù>U^Tt¦ÉÅ ÿî#›õê8‘ºø¹…ı‚kÅÈ rl˜ïU{ß–»÷î,˜ø±H‘ :W.ÈÇ5ªÆM^/ cı—íş»7ËXşgÏ ÏƒÇÛt<>|ò[k"“E]Â@Ş¤O‹7°ò;u ¬#İÙéÎ¤K)nú¶L]g&ÕlmòsªßO\ç=nuÕÕÈŸË ş;¡ñ}÷{âšG¬ªõ¨>?ÑÓík¯wôO«htäŸ¶¯­2,0Ò{ô$9x“VF™R£)\¾ômœöYVÚÖ‰sË|FşE[WÛBğ‹şÊ‚@ƒóÖ"Ê^o x Å/w±Å7"Á§ü9<†‘"1Ö8¯3"˜f&HİıÒ|ËŠÚF,á÷÷ÓÙ.Z6Iì{l _4Š¤{Ô2)~‰kjpãâs·	A©ã¿"¸`-Q^ıá¾54Bï™Nôœ/ƒíluN†£*@¢}´Ò0GæRI%«	Ù x”Â§yBÛt#¦ĞQ£S
ÔÂšçÿ¤ˆ¨jlÆ»¾n9X)JWtBì†Oq¬¼ÓsJHâ)=Ql`¬ô¤aÂ;Ò•»¦ğò@.NªÅ8ÈÜ3°™m§ej	Úº(×lg:»YÁ	3\ÂKúŞË%-ïsİŞ°Kâkf0²øë«'©Şö'Û"vß-É»±ŒQà>rßzå×{<>MP—ÜÏ5§¡DµvP¤ÑïĞh8L„Q1m“Š¹@4B‘çá´mùŠÚ¿Ú~9VÊ«ò;`¯–ÌßQtMóšJ›ÂKöA4¦†Qü•ƒˆŸe©E¥%:*¯11ún¿9öofdºG}ˆ,ÇIyÊ%^Fç!‚ì2¬ÿ6ø)·Ë¬>w³ôç@øO-q!•4q0kGÖ´ C#DGÃ´­â©Cef4\’$ŸV§jJ&gÎİœ§Ì’¢€jVÍM¾I !ŞÍ’'kZgØÉ@>ß×k1ßİ…0ığuûtçY_œAºWâŞŠB¦íµl+ñec³Bî™DÚîVr{Zó¬ß¹W
à‹KÀzøÂÙüV ÔüÆ4íÁ|„ˆÇpcèß¦sJÇ<„-zñ6ÚÜÌd”õ¸.î6i9…Â¥ÅĞıPÕ=ÌI}¸†‚»yGÁØÿC©ÔÅp¸Hr3-	u´öº9zW•3’¢¼Éà—d„¼N¼½¼0¯E‚}f»K9^Ï
†©úGİe‡¶èè©K»Õ~L›u¤uoA¥j3ÀÓ¨ÌS&.|ùn¼èúÓ,9W†vÕÑr*?cóS«9s“@Ş÷}.wè’ßb«°÷ŸŞIÉåJÈJÔÿ|Sò‰ä²ùy[ÑŒÎkÈTl°U—Æã‚$^ôÏõçLâÔİ¨ò ¥^ú²¬ºò–“œj„dd×£ŠƒeÃK§´3NìöØıF*f/äÓ?ÅCCÓ©³ü)ã¤gAö’¾fÊ4Ÿ•ş1ğÆ˜9{›j—ˆXU*zÖMÿq–Ñ¡”*!­ÏPÍôÚ×ªGnü@W_GÌz’ÈK:)†(‘¢!iëŸø½NmgY±#¤ıØÕb=Ä¬–Gİ¿
÷¿õæ<|SŒÌòúÜ¢•Yzš	AÚÎ0‰ç„ô^	,Ö@1äçhu˜±!ŞQCò€çĞ'}$[üÛ¤óq..;…æÙ‡};q®ƒ’™!ì“ÌCÀ:i¼\Ìö
‡-mñ"¶¿ƒ;ëà¤å¬9ãt1X7GÍqdetÁlnítÑ`'@èê[õ~¦Ç[3Ö»KX2í¬³­(b”A%Ósu[“æ&¿ÁĞ-Å_µ'óPğ0ˆJàßwS¸ëºÄd›Eö^£?<¾JWl+Áßèb,
|ºî†Îw?C¸^)Â–:äúŞâç­ ú”èM‡OËVÂÕIî*Á‡fØ5A˜9~ ö
Í¯Uë!(ÒÒuMÜ‹Ò2kï0®(yæ”>İãëcù©¶Úv±Å€ÀÏ×âÎ`3Q £5J¹ÖÍv&Z›C…‚ë…ÌUÉl‰Å>Sy<“ AuéØlÌ”wa¶wÖ÷Jº¯ÑTd<|J½äÁ¸ÚfÌ©0wXï˜uã¿¨^w5àq÷ŒŒV8ÈäÂÖ·§WTOü¨¢
ùÅr$ìõ¶å6Ø1Šˆ+F,‡Ø˜F~ôréRV[tƒŒXo“ï*ÇÀÙù¶wFşµuÖë'hœéÊ:Ç˜pÔ|WÔ7Šv€Ö—4ğQPóóLòyxL8…ñsİ)F¿+™1g
åôÊc²¥Ñæ¦•S4ÿ—¤íL0Œ(°ÿ¾¡h´§ÇÆnúï¼¾&i¡	Ÿ¼ÂÜQ¡(ƒ¾~&4¢ 5mO“Î©¶Òâ–Š<vNBî‘mÑøÅUÎ¸LNü º4qb·ö7óZgct-²ƒUi›Ùæa½„p"ÉJĞÎ÷f¼ÍéV‰8t´%‰qæ_ğBÏmX0’Ò¡"š³Zç¯;àÁ¨°f…N”µU5ß0K@&;¡@ˆê â1‹µVe<Gb)Å®’Áß[{‹p„Xg-hrúq5Ö İú„‚lºY³/^EŠrÕ¯ÄTºÖlÏÊöKö"è¢Œ‡æõş—¾½W˜¾À¸F¤ŸÆKçL<cş¿°¨šò“§‹Ô*ºæ|}é˜xáĞp¥e•Á¡˜»Şø´0²²ÈY3k¨\øsèX 5.ç¦=ÓàäaKÜˆ±QÄ’BÌDµ¹’âš³«¨Ş%v–BS;f(XFç‚=@|È².ÏAÄéx£é<¦]XîàŠ±QçÂŒPÒ?ÿ+ÿ™2›wjö!ô‚½ĞW;l|ö:Â.cSŞŞãHò<!"\d¡×ğEvÏF8‘¢ÃÜQ:~Ãyy³ÜŒMObRÊ+¿ ™»fö‘pÉÙR’aWûs$bÏ[± ‚ë…Kl¨†¨R…I†uâ\c¬]Xò4ñA-£şœ‰²ºº)©Î:Å™€q-ÿófSıHU“,q8oáa&[2uK9·¶%v×qÁW†U5	#§í\O­‹”Ö{Æv:«™· èÔ€f¨f4c‹»\LÓn§¹ÒÕ»¾Wd;YBüí®IçÔ¸>»Ÿ·ÔZZÜõ’¸b´å"=¼Ê!q¤Â3lú¢Î»—§®†¬còCÃé’ck[ÖªRØÒJµ––ƒ^“P497Ò2Õ²4!®fmo zÃÈ‰Ec¤/½&hjÎê±ÆMå&ë·Xõ:ÓLì© (Îp~hïœ¡8)~èÁ¬ÆÉ•¢#¼Ó¤†Xg^¤šZåş•Öû¡ÿxà|œI-"Ò­¥}(|,”»n´°×™GÚŞpş&ë®td4/)‹b“Œ®<7²LÀ`ú#’:×!ğV€fqGl°C~‘–_¼tæ^ÏQÛÛÒm.İ›lë}\.3h¯8šÌ C{ªès‚oÇ7ÔãËÎNèrÏl
ÁIÙÕ%-ÍJ§jgÅû¼Tœ`„ÚÈl’ÄgŸÍıcƒ®ë{ûÃÛ´lÄ^‹OS~¥ÿ#ph…\&ÊòO”f‰tğ³M¨3/)kÁÍhqÇ8:|œ–\Åù8µp)Û\)sB
ÿ‚%­!ß¹%NrRçÅÌoÏ×s•IÚg“œiğ>ÃUZüR;Ùf)ÑáSlHpôAï¢‘‰ğ(ê.¡MS´û‘û+G>»j|˜ZÛ¸X3³œ¥„íÙÂİG–S¿x«¼)ıÜ£›ÑÇáö#Rrræó'\Y~ğ|Î{é•–±óäBâR”y¡¸"!á›%ÉÃAû¹?6)‰©æO€«h/sÉ¬3.ùò)ŸîJ¨{fwGËÆJÅ“Sı4vl±­b_“y3*äcÀ3šÿïrœá½8×® l®àÈÅ"¹z‘q¡m6¥á°ÀvíŞ÷
—ï{îLÂ½jd74³Ok ³ßK³-¨­õ‹§¤„ZiGhjĞé•Áí—JR$iÃ%:é6>@ ûœÎç[+LW’½@q_“sÛ Mu9çƒrÅsbƒ 'ÅIú÷î«o¬}‰«)i¢G"/“¯Óù@h5ÿ
‚y5¦M×sŞGµ‰UXK(<x“ŸÈ£éß]¦ßè·«í€äé%§õ%^.´Cævÿ¡3j’Çİ&öxÿ\Iª&Õi²E.3¹'¦‘CeŠ©¼º9hÄ†œ9é)ÖÃíŞ=uÄ‘4æšp…¤xÉ“g¶â‰˜Á¾k–¨O·íÙ—¿WgõúªË!#S½Un¥³š^ÿ0|BWHèš0ª®.qjS¼ˆÚì“†ı`–”İûÔáÛÇÔŒL‘5Ojã+&[ù¹Q y—Xfœˆ6ÎØâ)œ°¨lIvÆ‰=^ÆõB[@d´Ê.xou™·Ã´\¶,Æéá²vK#¦§åÇ5aÔz.Ğ*¯kãD~nİ~¯IÌO»Ûû¢?9øx^ıü^õÎ–œf˜`}œÕ1¡zl3‚H®†RÚ;şØ$t)p¤ûX-Õ48û    ©är+Ò¼Œ ¹º€Àİ¸ğ¨±Ägû    YZ