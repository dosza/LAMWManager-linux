#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2963420601"
MD5="14fe3a90d715a686c08302def594ce3f"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22936"
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
	echo Uncompressed size: 160 KB
	echo Compression: xz
	echo Date of packaging: Tue Jul 27 04:43:15 -03 2021
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
	echo OLDUSIZE=160
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
	MS_Printf "About to extract 160 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 160; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (160 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿYW] ¼}•À1Dd]‡Á›PætİFĞ²´@¨&±’©s
`»¦¯¼2ä¸¢D€”İ-zºÔb{Wœæç Â—ú“@ e Òâ©¨…²…zÇfëüIùz?¬“oìy¶OÕÇaŞ¶@);w‚ wüÕTËYdñ+ºZ®OƒæG Ì
¼Z èº[mKxå±9æÌÈûFÛÄ‘xçEŸÔN¿´Z §âìÛ;5—€µ;o(ù-ò{¢*¥7kïê4ò´uÊ¢G(%¢à™€=
DCôÓã³·7Ñïà¶ ÿtw!¤9	³„ñ½ˆhûò£EÍì,62 àœ«‹¹AÊÏ¨wòG'óõ@Xı-c¼°-MÉ¹—iİÑæb}ênEá¬']¢f X)µ¶oulÌ†ßjñ9’ş½,½wÄ÷­–£8I­JH±àí&ñ¡± ¼Ğ¼æô¦î´êYhãx½f6½[ò_+Pb«b|Øû^|¸ĞôåxòÉôä?M?HººÚpeçÛ³V3Ğc‰AËpŞã7…İOèÑûÀ3@"xÉÚñ1ùŸ´Óa°q$1ÜnÛÁ¢k°‘ÍNÉ<˜†5ôÖïo«›PÃû¦e
ƒúh6àïÊÌM‹Ü4LCWá:ùg™ÊJ~ü’îqõì£Axw¤Ïî„!ıƒ‘|<†ãÊáı|m.ÀgnĞä#AÄXF_–„¨ÎÄ(Je–Aä7Ÿ®ÍwÙœè5ÀX[}úA—´ ÌöÁ(æ ‡ıä‡ık<¦ÔdŞÄİ˜}ÜımtgU·oiãË3a rr'ÁÑø-Aô™ä½_äÀ}™tœe»P¤ŸZÙz)ñÓÂvcxfdİÜ4[ZH"Ş	S1ğI…Û_cï´q&Å€ÖnúØ€?ÄA¸“Í^ŒHT(ì¶p½>)×¢ÚN¿y7€g)R^)Ï‹_-c­^TZ”ş›—;ï—ù†˜¯w¿•‚:8‚ø¸ü*Aóí"ÁcIwòœîğ—,0€	}»[†CÎ‹Ï›¬1!“Æ…²²sídË•R+¤…:`ÚW}‹
Ë=†"Í´#ı®="ï[fc”´ìTpJ^KÌ¹Zİ36hAÏˆÖ·¬$Uâb9¿CºÑS3k\2åIöÂè•yXÀ^ÁÄ­=£§=Îª%æU*s«Æv“ÏÜˆ~œàP®3€ñ+ÇËÑ?&qˆ–‚ì÷†a*H˜¬–‹@#
{š˜ÅV3ó¤ä¤•PhÄ”u±s`sa·ÂÈLlqV0Ç ÷[q‡rø,zŒ…¶,› Àã &+SkMÅ,n;ù~Tâ‚ü]ğÅõ”#Ì=M‹/ªr• .¶’g@£ÃdPnw³4Øñì;n+¯³øj§ÕÌO™D#gQmò€×êZ‡vz#Lëğ<XQ&/ÂûL·T0P·W©G-BÁíïİÅÍ;<«Á[¤eàz5`ƒO`ÃN
¡«æZåÜ›¡îx“–ğb;Å^wó°°V¬Bë®¬.àMnìîæ]æÂÑub—È…Ê)Ó$«Å' ¡1İ—ºux8.©C¶«£a)İ`÷Vû@c¨`Ë‰BÎ(Éˆ¤0Ödèú¨Ş>v—IÙ"¯ĞÎu·ç-¼Óëp-ÿğ5šS½6–‰X÷¬±í dæqÒY T<ÃD°+¹#5}è-É½Ö­?Ì/a/n8ùåŸÅt¬Á•í÷‰dJB0«0­ß M%Y¦ÃÌFã«ö"xÏ™Å¼½ šk;“ŞÎ´ˆˆC{áàá©uQq Ç-,=eº¿«²Ú@˜ÆÓ/V¤A“óÅ¨8­ÆÎ‚æ=@Wœ6¼ÔL.æâf	ÎØR¢¬2N’—4Ûu0h'+^,„æI¥{o1‰”¯—§x7¶	ø›l©‚–w›¹7gvnøû|XÎèÛü°'Ïâİ%Á'Lr3r<Q€2 ñ«#¨‹"Ô©5{œ6Jí$JÃ ìÍ{€u3Í‚·5»9æƒ°…_Qkà·^ùê'Ql™}dÔíÙ¢Ö:ÑşÉĞ$××<ïrªd>×‚“?msŒß›Š(™ÓØ.‰’q6ñù@(~©ğÆwšXhät}l¥26Ä£Ï%áÖ8:‰ñªâãí^G½`EF–F2 ­ ÍJÙWŞ¹ıÒrxQ"yâ1 òKgeC^'Ë5k/=fşË1¡yÆjTÃç‹Å]( »¡¥”¡È¶Ø2L6ä„¦¤ÙH‚É[j\ÒÛw-ÔxgøXÈôÈ;•<é„ó}2Âœd+p”í±êå¯ŒfrİÇ¿vU÷L	dÛ®Êòµ!¥ğÇğcÕ•÷V@§Ü<ŸV‰W9­¤©Èÿ‘û½¶õíà\º®æÍB.	ÆlMÉ/ùOì%Ô"êlf	àĞtÆ˜U­ğÅ€vÿ}È,>É¦5äfO,N`*3
Ü¬‹1ÍãnKVÄò¶à=±Td)ê››…”İ¬ÀàÊw£qÖaö>U}zjhJ%Ï˜=,ÛV¤v¢IÃòVë–‡`ùœ—}™ p²†·˜d+ø±?U#¤:ã±g2ôãõÆŒÒpl\İËŒ‘½ı€ZuÙóï!e)Q-‡Ù§¨(‡ ÿ&<@û0]™ÏßÏÏî{’âälĞâÈÈ ¦xSÎBËöğµr‚:,¿#ôA%Y£¸„
Ñ´%İÂt…?B,ÑV‡Õ’ı©Ñuî+É¥VyÊæßpP«/“´šp¸GYM‚İuÕ¬r{â:ºqFÓîŠMwm‰‘H(ˆütì –ÒŸÕBæRAÎ•—Å›GªË œÎˆå¾µVwö(2¼p!&f†çå÷¸{™9>d|ú÷Ë¥&'=èËƒ%jlBè’Ú½†ÿ7ÙÕ|Kg)úÆQ¬[¨–ıŸŠ”‰ä<N§ëŒ
†æCœ´¢I!5÷3ìäYÑGˆÕN”ºÔ„Èİ²™mn¿P‹ŒtÛñ'ERãİ€At GªAòhÂ¿”şºg…»Ëåû‹ÕóaÂ‘ÅòX(éóµCdFsÛnşŞ&r9XA¸KÊMW„Æ'îƒçMğûLJètWêlPÁ°³z–Ï?UŒû¤æ ú/FÂÌu;¼Ï'~qfÌß‚ºüòåsˆ9x c$Å›wîYë¿sÿ9Nc»3$Ø	¬¸º²qªäÊÑœ•¥0Øğ÷ S—¼ˆO6‚‹·Y@>äOÂKœ€ğ)¾[M;³±Ä“üÄ<§ÿ¸Òl	î†‹cƒô„Æ!"íÕÎ•Ÿlüš«ò®amwg#É¬ ú©?Y(6Ï*eœ½Ñ­éTÆî¼åÿ{_nëL714ìy­5^(VxGâoø¹}NĞ¸7DÌ+›tqºX¯ûá5UÙÀäÅ¶Ã	ÈÉªÔ{sUİõŸqŠU’œŠ˜‡û£1Â±¥šÑãÈd©Ò‰„Ç³/ãÆÆıœ3 dcFªxº¥n„çÃ£-ğRµşV'ªÉkBŸ «Š×/$ad¼[JRŞàv˜¥{±xgçä—gßŞOºL>§âj œÓ!m|^*ùäúvCÖôJ)VV€?' .õAû
^ QwNúŠìòn™1Só¨ù™®;ÊÁ*4ëvÆmÇqˆ¼ì‰q”k»Lƒƒ~Â“;T‘Áw•n¨åf/¿ÃÇ’8kÇŒ
äÑœ)Al¨âX×
Êœ¾k‰›O—ÄR`®œyYílT›9Ï/­ÍÆçş­)şÍeúÁ÷Tòø°­LÚ2ÜM5A¥ø…¯Í´¹•Q†*9¸<±(Uü[`ü2ºãÅ&¶@¤LĞÆ±l ¿–…ÀgÔãpˆƒ=!´FpÓñ—ÕèmƒG§òm‰	(¥	Sø®Qz¹Lfìä˜}}œÇ±Ê`4Vd²(¦]S¯…85{ªV)”9BmôZq 	‡n®u¼‰;Ã±|‹ñrüë±ª|R¯Ív0Îd±7ìŒÖN_½)û¶„î»ã  rwîYìYi8ó]Ï‡’X`ƒúˆwS]ïë‹¾8Ù•Ï—‡é¼Ø1œ	¤^j¨QÄJ;ëf›„—V4=~ÒÄ÷Øµj)é7'­âlèzI/=NFH¼kÕ´éï«•™+Ü-™9şSüLFÛ‡»E²ğO¶ë/’w°ü«â§ŠJ:£¢ÓŒec4²Zö&ÃıàxªÉ S÷á¼ÉÌòb¸[û(ì?s!¸¦s¹^ã§“3‚/¾=#àêïE¶“ø‡Oİqúğp†”1¤‚ÁcâGgË	 ÿ÷u^âª½%ÊçK°¾Hu—«°½{iŸÆG)Ó>SÒ ØTÃkØËúrÖk‡6£^}í›gGIŠö®€¤’¹å¬t}&—Ğ³ÈN «É\Í“ä°ºD$êè^KgQ…»/ş'ã$ÿÂ7dB€Qô™‚Ëö…~·Ó¸6ˆ¶$âr¢Ô…‡ÚQxjuC¢Ñ0y ‘—ö5`w·ëj!ç? W!DÍä$”è)0›N	È…gÙ2ƒˆ³T[s•êázĞĞñõ÷½õ$w>§óºÉ^r:A§
Ü’÷,¶.'´ŠC©9œAÂ¶ë¸İgø’æßÑ¤è°YhÇnÂŒİ{`\„.Î(‚³„¡2Ó]ãé©%©{è=T/mŸW¾$áG1´Á„¿ÖúN»Ùíæ­Ÿ™pÜ¼İyS¥eía.K®¯FŸâÑ¸’t‡2.KÒPuˆB®Å†,cjÚ©SÅ’¹ƒ$¼—wº…Wä+;³,X˜èL‘hfc3¾Ï¸0†y©;$lôB”û*ºJõ;¶^áàÕ 6LÈ‹ÍŞi‰X3³Ïü!ø¢ç€§'#„f£>”Å=‘ö;D¤—v*!ŸĞF@‡‘¶ê£AÑ¸”xTÆâca	,ûğ¯<yh1ŠŞÎ¸ÁÜŸs`)å¢Kb3ÊT‹h'‰İ©Ró{â§°pÙYtÖX±E†!É#<ÄĞ}”Úpï÷˜#8ÉrĞœ*¶Ö¨åÁª+¯ln½8ÛVKü×ÄßöëX®vc{ôâm.»ÁeÓqÛÚê+º¾! Ôl€"€=FLà[ytµ0²^ãÜHfN#|Rœª‚R*ØŞ+ıc‹±]}Üáqr+¹OD`Ï‹9êJ¸ç$Š “€iÖ5Õœú!$QŞC®ÆŠ5)H jÈs¸™ÊÓÅM! sé^ïşsj€¨>İ|PöÁöğò—·ĞŒ¸¦³ôôoŒc„-Hú‰Ùkj±¦ãC[­ì7ı[¬r1!à™
?€?Gô.7šnqÜ>R¿${ùı•VÊñŒ8€†Äƒ'xm=TweÎS~„ë	 ™ÁÅœÃÜÍ¨<Â²¿QË©VÓĞĞaY’“Ôvš8÷Ùi÷  f£³÷ˆÊ€Ï!t ?òÎÌğõ,|‘Ü“)æ÷1Õoß8R ½ ÃıTÑŸ&(z‡ü73ü2$uª°.íN¬fo© jãÕø4UÄ¶iwº_ 4ÌÀ˜öWìg"ßsËê¡C®n‰¬F(î;}Ùuk	xZ[Ÿ8èƒç®q—¶ÿêAŠŠ)ne; ùMGœ¢‹Ï<ã+èˆ;ãf­VÿÅ›ÅŸèWŠ¯¢<Hñ¹=‹ÂiL¶æò8£W–6@´	}yY­1Lhêêì‚bÕéÀf›#KÀ}…MØ¥˜Áx`å|}Tt}pˆY\1Š÷ó+ìKÓ>Sù®´˜ÛÀ*0eœ[?¸¬ØxGäŞµ€µ+àŞ‰ÎS*¦¤àûê/vÌú¢H‚¾9ÈÅ—FH£/äğJL¨¶xELt;{×ay†¸qvªl2@kIïDÏû4µJr”ˆ­‹;$gĞÓÛ|pzªä“pæµ‰àû#8­!ûÁ¼_É'Çnk.§#L.ê¿s4À Óã =ìÊojÈ¥«äK‰ñŒÇºkéñ!ë,€1JVŠï·×mŸš;û©ß€ e Ÿ‹iîènğ ûÒNo/2¿Í¥ŒäøLånxÏë‚üï%ZµÈ¹fâ+ƒ//]CªŸQ›Øh1ØG|;[®Z IŠ4û-%’$Z3WÏ(Äa{®—ù¡
šãú»†h ŠhÀ
»1WPF^oË¬ODÃ—HQ9rd ³ñêØ¯àvºs*‘‡o±z+o- ¼Ñë7"T¥«ıİşXÀè°: 1k½E§×…_øÕìfAh_š¨Ç
8òØJ°†IzÜÉ£P7¼ÉT4ß‡¹€m¼¹»”À²uâÖ‚¨™ÛB&ÁZÍ6“EF;~®[N¶~kÌœ$DÃöç@«ŸÑ»6K`Ò#ÓÉ²:£ÿFH#Âç¥zp¾×{Ü
Ùşì¶åk(û»¶Ãİ¨N,Fm±À-«©Üi<­RşœôÅ¿Ü %ô‰r•‰%…ÆşİÍĞ‡ÙvûŒ>FÎJ¿÷<õÅ3´Ë²åQ«®•»×T=G·Rc''7÷!ËÈ‹oÒ¸bàã+\ã9’yî3šÍÀ–:Ï0ŸëÆán§8Ú–jïèaü±5²šô™2æüK¾	IC‡«jårÏ&/±a¿JîÓ$<¤1YDıİRCã¡Öùìê)m£»Áy³.6· Å= É¾„@Ø"sÆbúğÛıoÑ·É\¸¥z¾€%ˆ#q î´-ZäÑoú• ÃäR³J\¸5.•c~G6¹1îšrêr•»ºbÊMMEĞ}eI?{ÌB¬'ïCò3”tıBNK‘V&€ñŒç½a˜ëiÇs°¦ÑñEš2pdŞw.¨r¹.gæı+…]'£Ii5ÙNu Ÿİï³0ºÂì‰ï¦ÖŠnKx“³ëÑÔl‹Ç:ÓC«p¼ò[Ô'%AÕÏ>{Úëñ±>*ÈÓ^„R¤I9‚B$;jÅAãXƒINçÚ5[!ıGµAtUmó+³¢}a!¹Z91$§×÷fÓøÿIûØuu®¶.<Ñl–¿ú$ä»›5>»DÆ¼N‚>¡£ê¬Áõ«9±¬œcñèpQßIàåËÁˆH–ìÎDÇPçŸ8‰øÕ›rÔ~
#X=|÷Ã@›ÒÉù3ÜÔ„òˆ tNq5r¦ûCi.4ó²;LÂ^¬án˜ÑĞ‚ªc—aÁÊ¥0ÑíÓÈ<Cö¹M†ë¾öÕ7‡×ëtÁ~¼~‹3¶h  òëSÈa‚xof¾lVr˜\¤İ¯WJeÁPø,p¤Ì2E1@¾½o¼XMŞ([[?BdîR²èãá–‚©p*ŒbcX[dmDÂ÷­%®LòV­#æø„ñFp»è	\ö•\†,<zGö‘šŸ~p’DR0‡†˜âæJ`ê60ïõÕt¦ú¨”ÄK Äâš(êG`ß˜1ä…Š¬…ëØİ<õæ­°9kn„ON)&ö‰·Úiùû©Ïìö¡»mGÑø?¬ı`x„ú;·8—dİ•l4,q)VU¾NĞq¶ß|°K^D2=ÄKËš.ÏˆõöÔŒÄ¿İêz=¢ÂdBp[¹‘!ë¥¬.±ÉŒ€ƒl©yTÔİKÜŒ ®ÇT¡$><ÿcÊéôkV1ï`;d^£2'RÔOŒUFdèºËL…}tµñçNö1#w˜¯á;0f°¤§%Àµ•ÛlÙD¥İ™8¬v½š!ŒYù¿+Q\Ëı™åËtO°±ŠÀ)Å¢Á€¡Ç7‚H4àry¦DcÀ¶_²ñö‡Sš9ñ™ĞÁ(G¯‡Ã .AÒ«¿'€–¾/-0Ç“UÇ‰D©ŠcxØ	¿¹lş ÚØì
ø*Ò"å­	Ô€3ïrà+©½Ø¦0B2PSA8¬Ş—÷ÙÚÛ8/))_»èXÄJ\?ˆ=¤‘CÔY„,Iø¨´âXİıì¯—•½2Ôoqºd¨E“»F¬.èÅşÃLò s ¹{.tèÆ±ßœ•Ê´'¨ztL®ÖF­şô 	7$º»3›=ÕNXâüCe®ÄíÜv"=³#Ú°ğ•Ç.Ù^?õşW¨G¥Ñ¡…Ëî„‡Úl+Üïjåà­ìfKCú•¢1"ö«ó×µ–PğQƒı^Û)céÄ·u»İBøH ¤¬ÛD†mfÌ«.€è£Ğ€æ“Ê*g¸;½ÃP#üÎ,Í…[†€‡YM<[X„Øú(`›±JÜñüòsu·­‡²Ÿ‘Â2µ‚ˆÅL{2OcÊ~‡äæ»„Ó}~Yl"~µ §åÉéò=lúøúÅ9†wñÆŒifñ03jït`‚°C: eÖòî&´i±§'jÅrò¬.÷zêY:\L¼çoÌI›
¶/ŠÓ¦‡…Èö ~=w56#…±­öå~(Sº’iºÇ*ú´^ãŠO¸4ù2LŸpÖd—øîÔ~[2S®_åíÎâƒ••Ï²èâZõÏˆ´„›§-¼Ò ÷Ud÷	î&¬tñWã¡ŒX]µ°¿²Áö€f>[”‚ŸË¦ÖçˆáÛ£¨h$CŞDy¯›&hcX0şÕo 	z¡l¯^R„üøfÔm&Ğ~ùcñ^ØFğı»Ì™T@Ò"BôÀ‰ĞŒeÛ¼î˜$4kû3òâJ³6Ç =f£¾Ú&ôlÛQ<4Ä¬¢ƒi0çœpyqa#ùÀö‰ruÔî‡†ØqÃ­38 Ä(Ïï„]òÓ(“!·¼ jU•K,&J•–ß{•g>qIÖú2uXù÷/×ÆKğ2­OEŠÚ'½”şpÒï‡Ø¢üpî	fI†µ?¬¬wdßQbo°¨9Üİ2Ø®"*ì#ÌxhñÕÒ2_ŠŠç¼[á)|ÊÉJ"è‹ŒãÚ)a*.•rq(¸‹p¿YÌpO´¾uæ¾˜ıøš)’q”A×“FˆºáÖ³E&uÒh6™9Lï`É‰)Ë˜~3r^A€.ˆÂüCvm­Ñq)³•n¾µD5VbæùÌÀ?¤ë\ôVÌŒ•ï¤Ò•\¥v)yğ‰2Ğ#¡ss~s*3²í±LÑA^DÏœİ»Qİ³S;/0è,I"92Rüã\_J/¤”Ÿ‹9ÛwˆŸÓ9.JƒBŞeĞlG7œÔmoê%kèh,höœÊô œ`ÅaTS¨™>&èb5Íg‹^›âpü„âÑ³V4v°|¡yo…)¦rN“QÆ #‘PF&ÒÏ˜ï–+a<RGWù×
&º|Ğ¯cêo÷u•àw)ğZ'şn!wÔß|½X¼ÂOóÅ‡2—_GÉÚ‚Ÿ	(oíÌ9:êÔ û§ÁêHH?Ç‹wµ¹À¸Ûf¨ÈLş¼–3¿G¨ N	CÀß©«¦x$ˆAÊ‡å#†£i3Òã-J!]2³±ŞSs<©ßZ(ŞĞ¤R™«³yQu¾tíàMöñD·;(fe&XÂ‚Ùš1Ê”…Z84Ş~O³p’/¥B=h[»ğ˜PØ-¡Ni‹ÆŸNZÖÍF¶³GNëXšE¹él(×kÓá/Ó7ûö$”İ`9Ş®Fá5A»ì»k•Ù>£µ×l4'®µf,]kŠhÕ™{Àm 
‘ÎïÍğ}+ 3²…síù²ïÉ’/WòLŞ|öjê{‡€“¢Â‚Ú\ØQõ/©Ş¡”áTU†+Ãc	ix8¶õâW·5åÖÚ2¦8:Ş„Æ£áVò…Q“íMút=¦l¯UÍÑó“È…Ò¤Š—r»†„;Bµü´Lı¬’Ÿã_²?	éÌë‰~êÎ9Ac[›<E;‰Tî rCjw¹ğæS@ÛuMuğïï8PÄ'ç"i§˜¦1‹º¯gœÀ½b‘)¹5õ¥7Öh_*GÓ[rpßOç`ÿH)oçîç­ga"«}‡]EÛû¸Îš¨2¸ÊëÅ¼oZ‰|@³Æ¤Ëü©bD•[´Ñ_|„¸áP®¾äÚ+AH9$f±Z<Ëv/x*uˆ,¤ıH­'ĞÛêì˜ü–ï„¿ÆóÊhöe¡ÆI¦’¶N~¼|Xõ>ÃÉ±HÑŠEÖPúŒ‰ĞNlrø@Ä³§pøáÆ_¶î±‚rE¨ò¬I0?WËè‘,C$Á,$"¡¬Gß!ÚdVÔ‚‚¢L ” ?v;·ƒ/}D­²N ?€q%Õâ¡BGHH ô÷„.<J™ó]«xg:J¢éÎŸ¨’-÷P^öu+DHƒUË0¬¤¦ŒÀ&Ä×‹	4ÏîÄÆyU8Â[¦^¤£j»&ÓˆJÌŒåI¢S40ãw;u-ª$óm!n
iO°a¥Ğsº(Áò
!ªšD¿-)îÕƒĞÈœP³’Hät%8ˆJsµİimNÍ¨e¦ß®Îä-?4j!(˜MÒ©£öƒI¨Ğ,“Zå‹öE»jJöº(.çÅ¨¥&(Á¬&^¥2é‚u¹ÎİäŠæşé­‹ÀÒÇ"ñW±‘ñu+=¯õ©+Ç+±ttğ\>Ô3¢%hKøçSÚŞä%xZä«.ì¿(|hoÖtoø-@©yHÎ/á`œ°¿F¦Æ}è	‘µ¬Wíİ¶ü$ßÀ±º¶øH^Ğ`m£H} æŒ>„¤Û¦èr› tvŠ°%ãr@+ÏOÕ*J(ˆ&[ö‘:²}Qş$Íâk&»71İ˜9ÏPt`ÒÜUT¢öŒ1ş¶¯iêüvW0ŞsİÛ–c—¤ño´QàÌ„mŠrW—ÜGü–Õàÿ1¸—¼¥¥™ƒ{ûÓÄ°ó ©®Ğë¹@i_­Q»Æt¡¾Ú-â0™OÜ# 4ç”Î`KwÓ‘ÅÁ¦G2>¿]PS^hÛ A—Dk„ PË	Û´.¤¾U*«.Ñ“J-ÖÔâ?ßl\úy\>úœ£©}p}R}7Kö¾
Rb¤"SqSºPóR	ngıåÿ"’‰7<6ÓÛI4»îƒîÄÿÂµzî™kM^ÍFU‚c`78’z?u#Ûg…²¹fÈˆqìÂÌ&vTöÙa‘±5àÛ© ˜?:hÓö3æfflmåÉÌêwªpéÍög-„ô.ˆÁ”ş“.	 ÁÓ©³?ñYMGPEfi•LK¡Ë8O7Æ©XÆüV+Ó‡²„´SÁßÔÉK*Ze¦D*à—ˆ‘ÀhmÌíÀOf¤ÆNEOãÚ¼ozĞ`ùƒd°¸¤iÑŠí¦'n8BÛúVcsÀÕt¢ëò¼j‘<é!¥îúWÎò(ƒÅÁaÏ=lGüÀâİ˜ˆÍçÚ¦2=z[v©©™İ³û0ùÕÄÈºÃhÙ¼.äE{s¾Ş¿°}Nğ_É%fœ ,^~â@G¸°6õªJszV6`Kéu|ŞNH-Â¹ğ9ùí3¸Ÿ9ÁS„ÑEÙÏ¿?ÊÅÙ›õ÷zåy†œ†ŒÏËÛîaRæ£“Ã·hV>ô}eÿn°÷ËgFÒ g	êı@‚ğ¤dŠ'‰?s£’ûĞØËó`9b[IÎEÊ„”¢\nD³È&:ğ’®U‰L¶±*ƒ"uØîò¯àˆIø^
D1[±×&Q’–®€Õ×øt`¡êµ½1)ÆX§_ÎH´¦ŸNT *´<qDU³Ì¨‹°ç Ù|æšŠİê£=Ba%´1DR£„ÛÜJi) †¥e;B92újmpP\kS‰-TÜ[gß#ıËİrªµ˜¾øÚí.áwLó{Õåø•·Û¸Úw®°•«+›’¼«¡ÊíéAQ´J„é6n}môœ}Ãİo{±Õù=WQÖ$e½sá.
ó’‡!{VÎ<ª;<5®ŞÛÔx#î¶Š>©Ê»]XQ/g9N²îkÙÂeçª	&COÅ´Ä4ê%ŸÂİÅPA®ÁôÙò­õP)ŸG’e æg§\ßÌè¢8qT“ó-†¹ãÈÓ¡.Ùº7O”æ?^˜†ú!Ä*“ÚĞy¢º«(Õ•úQŒ>›ò+k.*/?ú$–E‰ìßúÒ²)ÅEºY–mğ’æ=8®Q#¯¦è4==d'€ëŠA°˜v| ½lìL
9iÚ¿Ùişæ¢ÍQ3±ñß¤îíWpÇ’CĞ);g7Ë"±ä2Iï`f´ØŠ™AÜc	’ô¯`/ê"Éßà€ã/±òİíô°»™«dMşª«ôŒß·ÚäÕÄcÆ€Àm~4GZ€¦Y¨†õÌz=åæ»
Áı²Â-èüwÖjRMÒV&ÉÛ÷°9jcüqæ)c•°*r@…:L|dK{Ë-U¥ø^ŞèÜÃú¥‰’ÀÃNŠş€}Ï­yÉœ0tZİÅ{5LïêXò
Ay\İÍ‰Sw•óÏöÿÔÜ/\ÁÓìúCB†-)‘Ë”õúî-®Ï5¯£¢ù¨Ğç¸Ñsµwe#ü§ÚÚ¤çÙU¿Z´ñ œr2¼ì"=«lùgß] sª¯æU²ösléÑF2ö½ÊFŞŞn¤‰—D°¢Øjo¬eÂ¬câpk¿&1­['MĞºûŞmF=%œ­íMA£g	¡é™}n¨ä’ó/È/stÔå·óGİbS*‘rë`BôãàfÍİ•rúÎóâñ~Ç’gxÈ©$(İ@òÅÚ®ÓX&DK´Æ§8¨çÏİ§f‹„"HƒŸdö'm+ü¡,)¾TCBËÃr*zÜÅ\…ËæÏùg œZSúïz2³<bRu©ß¯oÚNğ¦I—(ıh—NZ>q0¹5‚«kÑÆƒ…­í°2ÁYu‰¨à”r5p¶=ƒ±ÂÁ¿”}æÀ¬B^9¥Ë#‚‘V<îÅ`„ª 1o°k8ÓëppÖ34 èSlL"h¶‡6®'¯y_´ÿ«ßŸs/˜¹VÃL8ËÜğ	r'Rã+«p£¶m5°ƒœºmµ’sJ;*¶ íÓÑ,~l&ë(õ«Ç¯ó°©Úz[ùÈà-ÛÃLIÿAFƒ×ÌM¼åÆæéüdîª¬GÁüi¬‡ö›ó{Äí´SelÒÏÍàõMeä·Ìí†Şµ"waM&	]®ó™´oÂáÕ”Jœm‰e-ì—¨†B–çÖ^¢:–aÎa{%ãh»»š BºgN¢÷±jXÄ%Ğ*C	 ìïâ1wy_ú¨VzÇG|Ü¦ÃÈ6½ûÖî±£ÁéP-Ãb0‘&V<BÎÊ*8Šcø“˜²«üòj8{Ã‘s‚=Z× >üÄ}ù¯éGJÔ“øË¿ Ë2:º£^A)Q×fÍ/d¥`·Ñ´fœŸÔàCQ{±Mê€×?¦µË³‹j‰³ÇşâğÜÍõ–-e|©~(i	”àÄ¹ãÖckR&Ëæ’ù×S¶¦êy¯fäÉë{[TäÎørzJ…a’³t¼òè2óÔŞ^ºõ+.ÙWv…ö›?Çø±Åóeá¿Ô÷‡ê#Öõœ;Ò¼‹ÑxU³ğïWü€«ğ“ß”jT$S§ü¤™¤còM\|ô”Õ©s>¿Üb…FB÷
éí¥ë'Ëğ½Bı«¢=È–‘Ejn23ê°ŸF#
_£	«¨š²¢€>ÏLCÆI!M¦ø%DÀı03z¸Y¾vlŞ1M^*?ƒ:Ì@ º0gã÷tóÜ÷”Ø‰¦¸i·YmnyÂ
z{Ad ü\0ORŸÊ¥u“É¿ÇóPá»¬ñ·¢HSıGé[~;8L|âz‹½Å¡V
gz³ôzûD¾à`…¥´pd6¼LY· cÇ™…²˜Wİn¬ë†Y3iNf²röòöŞ¥Ğ!Õy&o5T»CŞ5Êø.‹7óÖ1˜¶æ¿lòÃ‰“Æ¼»–/´£›‰Nº¢ÁOšåÂg·7f]ÇC	“}i›iì¸ƒ©™Ï¿Ê£¾	ÄAGZMWtÎcoMb”¦b¯f6#uzDg«Ê#)èCc#ë’§¨©g’Íš( £¸`]¬qÚq ıHşŒ'Ô•öx ™ùv 9¦ŠjåRÊÆWSz¹½_R«3##@áÆèĞ¿‡ *ÔÉ*“BÜ1.5”j?¹+8”ÌkS$VnZÖëÈ¬ªjAÕ‚‘(Æ=)¤$7RÛZ;BÒQÙ<Ş½²ø!”å~°î“Y.ì$ßM×\!™dÍ–Cc£ojk®ãÉLÆ½€R˜İ–ÎSúJÒ¹ü6uı¶“ìnB×ü_¶
Aèkr¾“<¯”U›iëÊæ¶.·m2^ª–4ôßN‰F˜ 5†ãø1+-!
¯àõNøHo7ì~_qI3)÷l	I¶‚Cç‰µµó€}Ññë!NêÒÿX†¬74ÃÀ0ÎÚ(Éû‘“¾æ÷÷¢ú²³"M4`À5-*ê“ˆ¯3o"˜W5[}yKµšQ,ó-İWl°G:â­ö›ù1ºÏ§ˆ¯ßùF‚í¾M]­–ÆM]İ~µĞ@N ¼Å¨m¿! f€¶ÿ óŠ‹":¤2Õ :"ª»j×zU%?OÕz»Áş™‘úãñ'ó9¾º˜(òÙåu,*÷(O=Op¹ÉÜHáËñÅã4¡–„¶‰ßÿFoQ¬©*ğîšˆËl{±K^QíÄq£øŒÑ­EÄ÷–†ÎV¨èq¤Á¶2Âk¾’4Ğ¾·bŞ‰€Tâ™5PAuc0WŞ³„Bà{ÆÆb&<fM}x¶•e)üE„.%÷¡ö°h0ÙÅJeì¹hd³rÊ=¢Dµ:]]cŒúì]ä 4¬HêcvW¥=‚?·ìÅ†z÷Œ‚÷b²ñR1“ÇãgğMºSmşÙñCøkÇd+`x“œ6û’6Ö‰OåÚÅö ¸ÛÇÎãºJÁÈ
í„#ïØœ6Ïú|¼‹T¸ii*o@?ƒWËÅ…ìÚÑ/¥H¤}eEß[Ù·¾‚ÌÑ"WE…ÿòŒe;!#NWE¸ñöo&X
×qzµek3(¤ÎŸ\#¿Ã,€1‹hê@©íV™f­tÖg´æêî[E‘7œò~Áì
q­¹`ÿ¤m(^ßï<ø¯w%µ©éyrIüB¸"ÊĞ.8¢;¯šÛ7l×ùê¤¬!&Ng(¿’ßOè½ëË¿te€¾å Az=Ñ„L7®…¹í¬‡<*•7Ó™¿îÚ@º1úDëQ3Pl¶ûçëC>Ë 6†˜£ª±=;"h	»ÚÀ’tåíÅG£(QMğı	7Kƒú¿ÛúY=Me: ¢t› ªÓîwNBñÔyÓÆÊÈÒ a³>GÂ¯İ_ˆáìOı]Q•²ëTöõâ…â¦ı§‡ğU÷†™—£;‚½âr­\	ƒÍ@W0á
%@zƒp#TÚL× ÓıÊvMC9È^Xh¥šR"b›»•y$’²3F`âğ>ıoéwXË’‡nÒÁ°i­BñÍß*V¨~|aN£Z­/Qƒ7‡˜j<&ÈuĞÛû¸‘Ô¢4Óá³îhÊñ€¨cp™'ŠÌ)	\¶.äö¢î{!¾ŞSf {íû%Òmsû­@d¼J²\mÜÌçi#Ù\k|¦9\ìkOç.¡1àür*¦oğ@m¨ÃWf†ÒMR¿ıš+#Ç3æŞèWÿÜºô*ôqòÆ¼ÂRsw»îÍÏZ`/ÜëÂdÈ‚¾ÙX±‡|[´şÉÌõnoq°–ˆ~t®Hq©Ğ$£[š@Ÿ$°×É7pqnÂd}Š§§ˆÉU<Kq?•îÂi¾>¬Ÿ¯3qAÅòå)K[½0ŠP÷Ç<µÑ»ƒ’‚">/2öÉ?Yô'¥$:7ªù¸&>š!ıH«''I9¬²œu·½ø&?ETÚì ØŠFĞdCöãÔ²_ÏºäíÄˆlKô(Ş•$QulÄÑVX¬·ó¨j›gõ¡/¡2FÉ!ÖGW6èĞô)ÿŸ²~z*¬G»ìé‰†Z8şV¨a hÿx¾¨æô¨N ÚÉŸºå~UÂ¥+€$E·<¡£·T«1èoˆÇóÕÂï©âbSıÁ{¸@_±ùëæ¤ºä¡Ô
R×9Jéh¾Ö°‡²CĞò¢×õŒo»X5r³s» $¨•h÷Ê_àœøloºIı&»´VIöYuósÕöZ—İ_§û€—1}Ì9Š
ü@vñ-Mñ*¾¼dF“Vb–”Æº1Fâşy¡âJÕÜx)~æzYãHâÍÖ˜Oß~ÇGäÊ]±ÄáÑB‹ˆ`#Âeã*™a¯éKc½	R¶ajÂ`ÁTã8-wëÜf-­·xË ;ê¾ØË$»ÍÊ{ÍğtÎ¼9Šæ8¡2ÚƒÊõ8Èˆ„]ş¦–*ºïL‘´ˆPäX-wÈhó“®J[©¸­¶«—XìÈvj¦:1jù³YYÇ_„åè¿ÁÄIX$ÈiÊA‹‡VÚÍ([€êêÈ°’vG+hù‘Í3Ì$6š òhÇÀ8øç7x–èŠòêzÀ‡”è-¸âÎå¯‡-x™ï0"ğoé½dš+&ğ¯pTã*áÄh6¼b¢Ãxo</›ŒñÂ­w²nLBã}KÅÓ×1¥êAAW p® 2Ìœæ{™«\/ùåÿT²B–]²X\íaÂíËÇ¨ZİñuîV”×g^q)lƒ½a52¹_1©ñ“ìq ÅÌs˜–>\¦…ï)öGL×¶Uo	WS5.ª¶*@zÿ M¡œàğÿ{ˆ"w”c®»3üØ3€Y)RÒV$%×š½ÅÅq[~ —n¬c¯¿_ªÄ'Gƒ‘\èNFƒV ö2°XèìÇÒ*ÿÀ:bı.%*ñ”]»;-S+ÈB¡òàÃ5£¸Á#Á¥Œ$Q3—A·Ö9O–lyÁÙ3@o%¦WŸf4ğ(ÚdûLÕIPùx‚DS¹„J­º@4’ªÁ¯q*|æ•ÕsÌç(|šŸO[qßŸ¹ÉU½¸a}ş»ÿ.â¢ı‰rUî+ïÙ»Õœa¡5Õ½ş´õBqRVÌˆ¶èHUZ1Ô!£û#¢À;GfŸ‰´4Já\f‚’>ò+punĞouæ÷ğÑ9òã€'8µáı/›m xI½Ô8‹—é*“Q2åZ
©¾ E ]—ıUIg&ø@kÈˆ™—d)î^2M(Ù;úå‹'ªwş1€€ÔëÙ™_@P#ºÕ œ©	­‘—¯x«Ìã*ë´ú¼É´ÂnhŒõ^Ò•tÑÛØûÁtvC¢ß—¨şñztŠ[vìùÊÃ@Uó‘Üİl½‘-u	)@2¼Ô´ >[H˜Ö«€ÒÀ?À§sbRbôrëÂ"Ç#•Çe$äWafz¿¹SÑ[p‡ÜúŸQo_Â˜±¯eª×#¤lÿƒ˜ì{vß ;|tÆˆÛü§	-‹¸Ëy2÷GM?~şaÅ»É‚LIâ_YUˆ8Ê\Ğ<"Z‡^S4ıï„•*ítuÎKSÇâ¥:ş¸1~©$Ùë0ğvlKZšƒ±’9Ï×¤Q9Œß	Nô‹A~«÷´´D|¢1rÉÑd#ÛøÚdR¹u˜ ş°°€”ë |Va9xwïG÷™¸ìUÆ˜Ò7ÛØe?ğ¸Ú#øZ"bFÒÛ†8x™âÜ‰0“ûU´«ı…'eÃµGîúŒhŒíÏå—Ä¨sî5xg1G=×å«g ş#¼ÅB`sùyğ3¨¡ê¹«3ôN;Õ¬dvKv["ÂúŠjDÒ°ùHKı ã/or@èóÁ×ô¤9şªg¾/ÔBÒ¥Gø%¸CÒ¶'<×T˜-ÑÄÃä/_dw½y²¿Ü¿¨iéHâö¼/„Aõ_ˆ]aàÜ÷gçÇ|ÆŒÿ•ó«åy¹ÁqÃ)Öwò{ì‘¦wz*Õ.à=–¹6V˜G—&ñ	óìıxˆ&ó4;ô½Y®µµ¤'‰::)v(Ú—Íïø£è×}=¿JÏä¥¢]á}OR	ŸËt©‡·Y	„œıÏyÄôU]j¨±&G5ÏÅ¦gã(Çğ:‚c¼¡ƒ×NVXà¬[I.ZûÔß!O;¢Ìp>Uİ´Kæ#€ôkdÓE‹; 4ò`jz‘J'Õ'ŞGØÎ@Î¼]¥_ ^¬tÌì©ĞQ&5xÖÅi
™'Òê1†UôéÉ•(„@gB|f©86Â8j'Vçd+ãFàö–ÚÓ§çĞ®*ZÜ|(TÛî<†Ùµ¨()môÿ…Z~!¬ìf#ëu'%CÌßÌR‘]#œ«Òèˆòx¡ü78oØ–1 ÷™ùÉ§{ŞChÚµS²ıÁ‹øìfÙA`‰ÏuÔÜNÁ?|)o¯àäÚ½%T¸2°2ƒ´ÇA¶põd@ıÍ«‚Ü¢£¿Ù&à‹‚Û4¼ÉF•YÎ”3}ôKÂ<ˆîbéÏêŸıHíƒdzàÓQ¢a>ZüiH¢øÒæ)½ä÷Â:w{©}¤"z¼WZ\ò¸ÀHï5{İßA™3<Ú3E{´l·¯†ùp&/¾Aq’uhññ”D’ÔÃaÎ½/+Nåt.€Ê2ÚJÖ¯õ¦ÈÉíø÷õ¦ê7­>(Éu›ÉVÿ"
]¡@ıÖS)¡îÚ†=ëA\ÛÜµšL›«C»H~¾0ïNïjäĞLš ƒğsş°*ÕíOl6”*ÏwÊ©¯JÑáG\Pøƒ¶«S…Ìã•®fl}\1C;‡ò5 —ŠmeÀ­zñ‰L¬ä2q…mò5YäX#†9•qõøõ)€íĞ<mş©eBÄº*ùM¦|¼ˆ/Iú¶Z}GÌ=(áEù72±
?w%½Çe½7Ô- ’Ìì^›bÁ5·`²?R¨#˜9¡ùœ72Qcrµ2.€i±ª †fDxšïZ%Œ«•»?D¿Ü¹B(mYÚçÖZpò—tÍŞ¾1*Ò8¡à¥tQÑ‚ü(N|ƒ¸çL=ZÃK¢­Ì}TqÆ¿²ÂŞÌÿSÓã-—ÎœÇ ¯¾}!ÆDx{IW:êm:¿á†_E»<Æ	´Ö!¬ù ÃÚÛÜ]2k…Pz¤xÏh¡æ€3ÍfNƒ&ƒÑşæâ‘&¥Dˆ¬F"$÷­™ÂÀäeTD!u§ıÚ¥íÒ:¦=œÃæ%µ¸Ä­g¨Œ~=Õj`ÔUêK#ÅMçÏh:zUú;5ZÿÀ”T$‹Mg²úî)ÄQ]k|Õ¡UÄÍ¶ÕÎu;…»í`§H}${éßµ‡IšêßÃ/’°ª²’8i=çÒ ıv¶£ÏÆ¸ŠL>7mš³‘É 1“È¨ÜEÄOMµº^º+ÁûÄK Ú?Í¨û^°é?HˆÚÖfuÃQ*ò´¹`#ÇØûBmcc4ñEO
ì0EHV@”æ[·üWµB…¼.ËlïàöÈ	xO¬•óÕ°‘JréB0QZúı¿¿*6¾şMÔèP÷ÚmGnGd
th9ò°8Ş=x•l3èæ“bÔm^¾ıS8•â”‚NåîºGñşÃvfˆİ^şÑ|Bâ4ª¤n¥‹'*’‡ì|âg`Q-e‹Ûÿ[ŞOÿRèŠ¹)R;GĞƒQSvƒ«PvòhÀeôÍ¡ÒZP
­Îv¸¦İ8T‹=-„8V‹_å9'Ë”
¡À]®Bğc°KùÜÆé‡‘I)&ïŸfğü˜PZÉÌçÓ¨Å"0¼Ë{Ñ)ö}^rk&•ËŞÕ}ÑTüßÉ÷9Ñ»€Çõ±ô·¦ŠPŸ|oh¶(,uE_(gZ‘rb°ôØµ#UÌ)E7…ˆ°w6Å‹˜‘Å¡‹ÔTÆØw[6•×Ì ñ¡ôÖv>Ñ¿ävˆ£vÙÃ_”][GºÙ2Xù@ºŒ¢³=˜ƒ‘) nr¦®Q¢s(¾ÔÙ—•!¹gõÄ!®îª[ô¨¥ëÙb«•&à§é›b>üÄ±üx=òc>—Î·ßFæów©n—„ŸpY5•¸Ç‰`Ô"ö†¨_ÍPkØ-Ü“~?¸TØM¸y^Í#1tˆ´£w¡ÆË2 «úRùÑå}õ!‰u¬ñ7€şçü<QFxxrUÊÅ9ÁÈÛ:…’sUœ×M§Hƒ{‰Znm(ÿ`áş)"WNVü¦>ÚFšP¶0“í²,òÂöïi'ÜÌˆQõÔ)ì_q¯™`x\•4kçƒ¬Ç¸‰c³ËÙÛ¬bÓ¸á»‹NĞ3r}i-r2TÒ=«YNşÓgzyJH+à ?f_ô:õŒ?ŞI©ŠsY,
‹ÍŞtÔ0Ã_ˆúöaÕÇo˜%æÿ8Tq’=ÒŠ6U ÇÀƒ`á…r s†Òf”u?ŸcµhbÃ#¢¾ÛL>4è£ãÈCUsÑóCC7§calaÄï‰FğC!xÕª?ı$‚sAuùÕdpÃ+ÔËº[ÛÏjÅá7Åœ%Aeø!pmY¼TY,¯xrûhêô‘GÁUeÖN‰Ë­2rÁ/ŠëWÄLîÅòeïÇJ1r¤Ä¬5‘œs>ÀoÁã¶›âóşÈäT¼-·ÃÂØşÔJkd+ø*|„,uÓJy‰Z™Mª±·RÔiÅwxŸg?"õ9Fj	Í” ·q™šG63õq£w†Á¯Ë{qjEÔ&†„Pş!L#²Â^‡Ó_~Òõógf64jh±È®FÉÊ(ñÿ6br½ÌmDÃH™³]sE0KÇ‘Vj4°–”	UsY€=jşûórçt}LÏ9ÉÅ¥¿ÄUí$Ç“æİ4U·A³¼ßõ·ªEl3AÒ‘§ætA* ¬ AW²©õÇFÖªxÚ›·À\
ùg¬á~áÊó°R¦÷˜ë8(ê@\ó}3`ğÈEÀ ôgRhº±H:-ÙbŞt÷¤JËÀIì!Â&˜11¡ÑCÌ)$Ä£‰PFáüŒ8û¿ähGù’JHÓLótcJ¾hµ£’_zz´•j‚ráæÕT¼¨9C±CôWv·L[˜xü:çí¼°P˜¾3lõÔÌé¯ÙwØ\C.g’1WšOÓş fQµä¶”4ñ"³ù]C™ín’jn:»¸¸Î.È’ïj˜·rësŒ1Gòø¢@ ¤ôoŠ$E&Qä6şêp–ı>FK¡•ŠË7š’¯ËÅiÚ:‘ KÑ'5OQEçbhÃÃ‹Àe?<^£cø¹…°8ğ>®2îmÑ?’÷Nm©=sâB•»©’™=j<ùæÀP©$æÙ†ª²½/9œi
3Œ¼õ^´ G³&Œ  ó« ÏUNuŞY±xpQlíº\LE"¢?Ÿ×sÅ<è¹)Tá¾:m!VXÙOg^ Æe²â>šÙbp‚\cûôj5²ë~œHc!šÿ3Û/1”=¦†ÀL¾Qn2Úµ}P.Î¤qÕ:Ã)Wr±É ş¯câ"î\¬h?áÆc‚i'-şÓ9Wo`]ŞaÖûØh&øË»3;°çƒóŒtîçX¢ì”9»Óÿ3åCƒ hN¬oÆÃI¥ğñ)ˆe¢¾E|ÍuÓ0/fBäŸ?z§h‹Y1û’¾À0Û‚'úyˆk'¬bi%ºNË^OÚx…Ù¢ÊÈŸØ|ù‘º4kØ4wØÍ{Ü0¨Ûlƒ“ÂİØ·×hQ¨ˆ¿Ê¹¦Å§÷¹ú3xÀ$#h!´·ØöoOx]È.!+-ÂÈÓoúìKœ­ŞÖ! ÇÛKExèô¾İv |!ôªÎraëŞõF|ûå'z±w¸‚ÊÿÀCáI 44º\z°İ¨ÏœV=t•<}—ö`vâœmì_ÿé—Û`Æèûm$Z0Ü‚š4|*]©”‡å— sD*Iˆ/0ñ¢"$Ú%6‡Êˆ£Xç*J]LeÛ ùKò&Êb ¨UŞƒ$:„Gv¯”hˆe¥'’ê ÀúÒ×õùæ^yp2¡Ğßpî*a¦så½Ã3	rCÅ
îwó¶RçeGG+Iœ®ˆê&âåÂµwgQ«ò†n¾&µ£9òv}¦S²Åz¡¤ÇR±i0šuÕ\¶œı¯_Búµˆ”=ÏòF¨4pÎt£Åv‰T£„q‡"ò¼îrûk¾|~ºa4’V°p-:mL°d ÷
×+‚&ĞVuh[}Ò‰ù©Jp,¢Ì°¤}ûğG”½P¯µ/è‘èÀ‹|³;^Ëê‚bGô¯eu"´zNe£®£®ÚµÚ!|Ï»ÍHnf`YFãÆ!.éÔ™c½ßé×#€ÀÖc“ ¶4ãY*ªìéK†.ì›œÊĞğn×³àı%E}Ì`Ÿ¯ÆK?ÆÑÏÑº/JËDÁÈU‘Rëñ®8“Rà¥«7ĞA'ñ>è£ı!´LTõ9ü£)liI¤!—j³®HE»Q) ğÃËhœj÷,Ú$ql²‚²ÿl­Â2óÁÓfÿµá[42tt'6Âú3¤µÙOàp
Œ£w³)äyb»FæŞóá'}ÌıãUFõ¶î|}äø8mÆs}™A@î/L°Á,D¼%—Å)F0vŒ½îDOsö°.GWÜÚix7Û¹ï%Vop³òs½(1[ô)°‡&ş§5”­[B³ÎÓwÛ)FÑ¢8L<M‡ ¥cS{
Œºg?û^høÖ´ØŞrÃ·Ìâ8¦ûRÑ¤>¿×7p4ÖBùÚ¤å¿`—#éc¶åáÚFjƒôPwÖ‡Î}<|rÄVùÃê‡úÆÀ{‘ïb‚k3«Ó&M–´ç¬ÇàèÍÂ†lîè#Ê:ˆ¤¼’âœxIR¶¥ìí qTÓº—ê‚sr¹Áğ ¡ë l#"íœh€¡.´ªGRP‡†´u"Òhˆw¼ÄtK½ÓEUú£ŸefÆL "w]óqj«ÿy¨èL ‘c˜/—©pé/‚|È%^›•iWx9Ã°/áÃnÀÃCşÜô/ªÀ>)~]ó^<«LÑJY`†äÄ”Pş|Ì¾×ç(#WÎÒ¼åsÔ§{¬šq¯d—_Éµû»›ÍGCy®r‡êƒÎXùw>5àôc´5ªF.±cŸ¡¦pÖÌİ	)?U}:/"Ó‡JK%Qjÿ¾¤ó5°İ”ü ¥´#C6Â	Ajò_ãNÒğ+ÙDØcWÁr0fäßîâR@‰œ€².ƒNõO[ÜH«XÀõõG.Ó’÷C³NI™¢¢n`¦°àKíà4ÆO³‚¸‰!?Oa£À2í½Â²±æ§óQV­ş£k˜1UiI²c†ûô§UÆº®K¥è—›™½¿LP3³¼V‘\â‡ÖÍkô¹%ºí[ËÆeÂt÷|öIo6Œ‚ÑŒªb¼´‹Ê‹`ñõò:_,˜3èïºÀLÄ¿îæ·Ï³œÑÃïLÃL7­7R”Gë-Á*—áÍò”uyØƒ±„B€4dÜuãëp |ŒÌrİnõŠÒLpJæ£@x»”¼Tn)LÚ®›aÚröİÔãyÓ~eŒk ¦I`inß?íÕë8A²1»—ÂÅœÆª6IUªÒ ÙcŠR× Õ1Oºaˆ\¹Ö‚‰Ù™£µw-øNë‡»Õ3Ó*Éïã{ÇÏs–æ ªüÒ6ç…Zs‘ş¿a|’ô¨¾¶—™á|÷Û(S´ÅÂù6J£ÚSõ84Ë0M$ˆÍ˜Õ¤Î©¡ûéæÚ*ÒRÍ@
Yr—£€Í7	¥™]F
q¼µ5¬S9æw	,G°¹é¿‚õÁ‚– 5?ğßÍš#™ñ.¬ö›O—YW–„¦CÖkØ8ş2^évfØˆ2ç_’©=—âáfQ‚óh>òr«µ€+¨MO8.ÛçÈRê­é=Œó°º§¹Ñ3á¡4VÕÂk9€{5A2 ÷“Î>Ş89ßıüÊ+:À‘®{q÷Ì¡}K	½ªµônöQr„;w®nĞv ±\²à	 -Ô6ÙïŞÚø:	Õ>nÍåX"ŠJíFˆ’¦
Ûˆ‚qF£L§…º¯~ '1ñl÷8(H€]ª>½¬ ¸ş|¡ßÔ°£PÙõ@|Öx¹°İÓï@±ì‡~—1½OVzCyL:~¶à[ÒGh•üV>,²\:sŞøj…¹hºÄC‚ıÂqL“½Û§L],/–L}7‚·0íäóûêldt÷Ü‹5ÑuŸj2}Øgğ:ËgSI¬ 2İ=Í¼„Ì_Ÿ…‹¾l†¾2—VíQÎR4!©àÍ¤ˆ÷Zö•ºÛ#‹Oóš^@˜mß{DÑå>EÙ°àwƒ*÷fèôÕËg¡3œZG	Ùš³+`;{ÜÊ²¼†É$BÇvõr{-šŠìf~vö©¶Án
ÛjPT`VÍ}ŸQÁz;
ÓÀ¸ç‰Ç0}ğŒÒ°õôd˜ ÷iÖWÙï_¤aEÂ•Ö*uØ üé8(X­ò%v7­:ì	V‡yV“[ŞÑŠSEé	cÉCŠnÚ/»6]œÊ0vûù¨ÄÉb­aÄFNÁóÛo_Ë¥ıf·Í¤'˜wT{]ó|9¡c®x°uKõŞh…+ö|ÒUÓDŸøÑûËı1Œ––	]ÒüÃâgÄæñ¦–¬Su²á¬ÍáÕKÄ£1ÙNb(½ÿ\‚dÿz6EQLT†‘y`yğ‘'Z0Ëë‚¼C0Ôé~.T<Şw,fŸ’ÔùÄút D¢ç'¯È”ı°3¬²m˜xéÍYCa3¯±ìÂ.5t±Û1NE(5,°¹Kœ‡e…<Aqª§óBîÎh×\&Î²Ì†´½bH”"qË’|ÙvC~TÖ/$Ë«÷G³
Rb·RıÚö>Hà÷ğ”²S„%½IRôÖñÆFŒXíjä :Wø„i<IuÀ¨VÊ?¦æ¼`pä=ï˜qt`†3[Òc›‘ç¼R%ä|ÍAL…%ä¼¶>—ç ¹m|á·Ò#}hO¨İ$bgÁUE}°†¯®,ÑÖ®7¸O†)Š#ÛG­¦-æ\}¦^ÀÒq7KŠã…Ë§2”îZU;¸¦]1h¾bĞcÍnçAs®½\òu$åä{¸™³†±Ì*2a[å$tBõ‰ÉlB»·ß£Ñ,ìÔØ7‚âğ†)*Ót+ö„_Îq;Y1 1†Ü€Ædh¿kdJ£åAœ]æMîg8]û¸BÙGÍvŒnš§m¶NĞ	©ÅnŠ´ŒêF]1Eø¡JÓî¾/¹ú	HÛ!LQ‚V/”¶ Õ^+ne/µW]/]µj}=sUsì ÇºêùõÜĞíí5/äˆIeªÒu ˜ê[¯0íù•»ÃMc!ÏÜ¤'z6u¹×$@Ö­{åÿÿİY‰¸QzŞU¶Eé½|y€@•¡ÕŒçòÈ¸*Wk‘eUzÄÃs\À
¦å fŞ<øM÷ÇåGd ÖNP¡.`ØQÌ$ú‡cÛAc‘ Ì½ÆO7Á>~)}æï‹$„’BéÃş»%cšNõİÛm­€¢$ûO/I®İkİÛû>£ˆH·®r¸«–‹¬ÔÚƒhÃş„2È|™İOzÁî‚ÓJ{tB>Êu­æñÁ¨Öğ1º³ÍÖ"­5õá”wK4mërO
EÎÛ [>¯–ÖtÊkÎµ€ÂŒ8°Û`‹›%,›s¡D÷ Wìtøù°Q—j 5„¼ñó[¹Èµì7!F¿=™º#46ÔÊ£İY§w80íŸnŠL‹ë›"ë‰Ö÷ËÍgÈl™¬–ÓÂŠ'íƒ şk‡ªM<iæ¥<@¾µ„ºIøönmúå}½ÑÖ«ı'Ïšø¥Ï£ŒO|MS:
È¡Œ=÷DUä÷PGÖ]iÚã“ÕU';EĞG`ã@b\´–ï°ÕR4yªğÎ-c¯0Éj9²º—†›^ 7Ìu4\êµÊ¾®º?æº[Í‘Z'.“Y˜&1ÅtXÛƒ¥jwãŠmh¢Æ+zÂïxD‚Ï³¸şØÉş[¸h•ç™üOêŠ`‡ÈØQ´­¤ßÏãğgÃE¸ŠKYÙPÈT\ğ%‹P»oNo2ŞU•µı;ã›HÇÉ‰í—Vº0äJ­
V…'ñËt°¥Ij<>È=r?®¬ó~ªn°ÄyÚx÷Óng3Şø'àÑqúªo®À­:©ş\6œ°l9°ãkvË1óYeòÄtŸ`ãá‚ıï½¿¦xÆ¾häNÈ9x”eº÷Ì~×úû3ÉgÀ:`8üƒè†ùºd#BÆºÊKIÆÿô•¦’kš	açPFº…i%{gT6Á®m?"Z¯óVâ½h>O–àÎÁ¨¾R)tŒ¥”|¡·†>­µíÈÛXùÜ¹§EŠ¾â‘[CÃÛ ,ñ&$sÔN]I_\U˜‰1ªúº#Cşù*Äê+mòxE^¨£:QbæãURfwC-'Á E5<Y¦]_=¡ÇuwºŒÿ¯öÊX*ï öş÷«ôè½û§÷ò³mğÚ.câ‚Œh·U;¦ÌƒB8ÎĞkö—mĞ€üğ0|V 5˜œ‹&®(ëÜHÑõÎ"-¨7Ì_î
ü4'½µ%‹m2ä•DnŠ+š`|dÈtÔx†Ûcm†I˜òuÎ-,Õn½4ZÍ,T‰™	€ê 4³¯ÇLIRßàm«Ò`ªóÄì|§]KR]ÿ^+=8P2}‚xW–Æ ÄÄ;)ı ªQ Ãå‚jÎ-Y1—¡\lªãEHfìû-*íO6­Ã¼ÎÕÍ‘ˆO¯û1®È6âOÈ¯–=¶\ÇÊi[şûú½¼EjÅN{ÙâÀ¦8.*ë’…‘ Â4¤u¹Dõ¡b“¡ˆyº£-Hˆ.ã|¡4Wïã™ğ‰ùòdÔ4H¦ğ&©ÈT?ı"2
'x|ç!†*”’‘ôW%8««U4Wµ_j¤‘Ò½Õn¸M1«}·Î3ú¾ïé;¡ÙQcw@ó¶*#ä£Çˆ÷Û"Ÿ"jß¸‹A
A	to™"PÂRèM.0…PA¹‹…l]ºö„l!sQ«†_ß’„øè{ô4ÂÆpú‡:v¡”\ÁsZè¤Í¯¼n]
äà(£;Dİ
%¿Ê¢J5Ç—È¼ÉÉ’×»UB®)†dëÖ+—‰(Åâİ·ús(ú"…b2V#ş ‡
DØ¬>©Ãæ Šÿ¬c6Cd= @}h8ªì‹9Ja,"’ùï¨ß¢KšÍ¼èùàm±	…¦ÉíÕ2»G}_Ğ@C›SH¥„%½$KÆMU9—\9f*¿%Ã1O4«a\ƒP¬Øİ@Æh¼7¤Ê¬§°‰òBR)ÊRï: ñU!WÄG#
=Kñ6ûµ˜ƒ&O€ø¥¬{™3÷>Úóó(ËŒëç=¡dÕşûİ2ûxöÈrÄœ‚¶ıÙ+_Æ¥‘&‡Ld­6‰…Ê$R‰WŠêÅƒH1!¦ŞıõP´
‡®¤Ñ8Ì¨^
ÉÔ—œÅPF”:ÃšdW—Ãåÿ0TµÉ8=¥í'`›´°—Şí˜OOÛß¡#ß¼Y&PÄO8¤F F+9!ÁØ­³ÄĞ1´ï–0‰Xæ8	>§¸Úº„•³Õ6RŒaÍİwòÂ~L!wv×Iªó±v(ı—›I›>éA{Y‚¬†¢5É+DgPTÎÏ(Ò‹§U~ÓûÓ}šlmE÷QØ¶ì÷\Ø ä.gæ¶Ñ	ójp#aW(¬$_ï07„Yúó‡‹’2gİH¥÷„ÍP¢0y˜å~AGà÷*Å–§¬­UUÜ×^!µ2õ±´§{ó˜2åÏï]„ØjÎš_ã(3 RyTy»ˆ‚j_ò¦ÙÈÀ©èY»]fk'˜Ÿ~*±Qœ7:ï«<ÕoöFñWñ_ælïÈ‘:È@e«€{ÂëÑ¯#×‘¼î¡ÒáK¬îD°ÿƒ(ÄÖeòˆµÈÂf¤3 ¯¡O˜tª\Õ0óYB}
L,õá™™~¬­¬ò'®¢ZqXïşMS­´?yz– éâò‰øÛ·¹N_a‘õ×=K¿’LÔ'k‡²·°]f'ıQÙDÿ0vq^ÌØ„öæ-Õ9J_M„ şê$hQ…È‚âŒlæİ`-ShÙfT¦mƒ%ÉºçgTé»MW_I9i[½Ù%t¤7×5ï+íóˆ&ã7ÁŞ¡ã:MKÓ§óMBœR±;¬Wæ~&õ$¤!d§§´¢lÖMU¤‹1M­0BÓ_Ô|‚Ê[OS¢Ñ‰m)ƒ‡M¬©CùÓÈÇ­´®úb´D"€33e6¥Ü²2ÅÊ°¿?ä”?&
=¿H?£÷»`hT¹œa•:Î¤Ô£¯ÒÂ•>İ'Ò¨;¦OY+¥Ä8™C”Ö¦˜~%LšóQW,F}!‘½µÛmmGQ‚ÏÙ*WˆŸÔcG\g?±^Ç4™µªô¦¶íë÷[Pî.¼)€÷è¥j–FhÇSà
­øŸk‰öF8™Zacô¸#¬–ĞuİáÓ“/#¦oØ‡Ä­˜ªSa¾ªÁH¤Ùıçã{äœ;ßGO%¤$Š1t–H½$%]Í÷vr¨’W|¢Ğ±!ÎØ¾öÛ¯á„G”üLŞ³¡ÓT&®àäù÷KRÊÌÇCÃ~aAòÁ„ú:ß%åò¢i‘«?GUMğ²Y¾ß£Hˆ¼ï?§S™Iù/œ¿ağ‡ \Qv‚Èr1˜Úä8ü	·j6ób°FM4õéÍK°Wùˆ_{QŞ$Î:×€-#«ê0;ªm‹—l:våõz©©*9Ôé>x
öëiÉ!åÅşN°vúJSÌ,–Æ›Ç9q0°ó(xšÅïì`W‹í¹¢“/şêpg‡s¶i•»J?Ìo¢wï&ª`KZ×dWéÍMÿèšQØDd¢WÈ·5'l¢9¨åÇzgÌ…D«fC®È‚ßß ¶¯~`îóç„Ñœ,
#‡sJç^#œ(Í9Şi°KÏ°û~vÀ’Økl0‚ìahmVÚÔ5T\\w¬¿ÀWö
œ›U5uãBãÓìKOÙØ ê:T¾ÅqÄˆãKHQûî~]rñ»yç*qñ”`‘
, Y§†
±ò=ö¤›@ÙwÁp9ñg‰BÓş•ÜèJ0oæ=„EÃÕÜ@T!iæ’ilßùN¯üµMıôˆ*›­¬e—ûÌÍûë.Î×Œ=M—3âìš¿#‚üa+@Çb9[£ÍÏá¤Ì3TX‚—±× k*Ïèx@Óß•µ˜0õ7´m0Â€0c^³uf°J`!gò¦=ü] û“BûVhLubJBìËlÑtŞ]
	o‰=e¨tâ®ÇQ ÛAüÇ:ˆé.’Øj†»Tu,5U6ÇeiÓ´ªt¾+ÃÙú03´O*íú9Äg¦zl—1;ù?kãÜNÙ¯³Ô¹k¥¦¾ètKdk¾e0CQƒØE·«$³U9Aíò“öOZÍ®‡ù á‘“tÈ‚¿áì°#¥ë‡ı9?BÇOY RßgzÒçª0Aş÷'—â˜…Y-ª~ë¨·½‘9]²K:n/½ùÄÈ)ì
>k¹§&|ƒ1¡¹¢ é®~qôx‹ÃÖ_ëwCì7ğ6º/¶" -èë¢^¯Y$ĞR¼@¾á”J-‹¤æ Y#iPË ÎÏ.U   h-ÄMŸ| ó²€ğsÜ±Ägû    YZ