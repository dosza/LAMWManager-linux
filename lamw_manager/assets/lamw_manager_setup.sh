#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2867317462"
MD5="95ee1cf5148f42100f32362856e137c7"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20748"
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
	echo Date of packaging: Fri Mar  6 04:50:46 -03 2020
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
ı7zXZ  æÖ´F !   ÏXÌáÿPÉ] ¼}•ÀJFœÄÿ.»á_j©\.?Zúqc·ÇÃr Çnß´KEøäFXÕ½yåÖârøT(¾EqTq­aÃ‚:«‘Á(%È8qFk±¾ÿ¤,q¸A:¦’ÔP|ö#Rµ ÂâìTCJrìë~wfrÆª?ÿóT¢ª´öG©Y’ÎtQrÂ¶w¥J<p9àÄ0O­ıTë0ò6J¼Oa\bqÕØÆjWø…Ê§†¶«G’%<òrí"Zç§¤»Q,›¯ıx}QüKÊx]0ÔüNS;gÛkåJ~Æ!+¶ªC~‚È6 Ç¡ßIÒ%¶ª;û¿º †Wİõª½"ÿıI˜–>k•CT]É»Ä÷Ö×qH¢–^[ô¹_›fËĞìjLJ1Èš1¥ô/­B/÷µğEB(y¹tÁ½´XV¤—¤Ö¿Şzyåk¯:)dÈüo¯Ñ:ˆ±TS9pnŞ|î±1²Í
Ü«ÜD=*xâÑ%¥Z‰ß2äì®ØÁ;ÈyÎP—b¿ xœ-ª‚mäYş…vÛÓë++UøÂ¦+eâ%MÔu¾Æ)VÊÿvğy† ”ı.,ûÒ$&OTdª=X
QtD=T93=. «×}@áVPõi}ÂP]g&Tdğğñò^¥me•ù®»µ¤¾şHÒÜ[ÕÎôO:e¹<DO:„šØ‘™ök*›«‘:ù‹×”Í”S‹lÌ1_¾×!ÎŠÑ»7à–y‡vNûĞ¤Ö^Êñ½OÒè…"Ï&á@™_òîçı·>§5uË£yn…:üëH¢É•èMÑkØÎ	ÅGª4a->î)+ÒéÜá£²Jcğ¥Ê›%>°¡µ`FçËc-/×M§‡Sãf8H“h,ïÜö¤sºóprûüÖ3+Ôî¢îÁä! ò%
¯ßÜîáêÄmÎË–yÉ3†ñÀ¥[>bCíß‹ùŠ­
†®~moˆwÇL¨öJoX„óÿo1ıôŠS6Äµ^—]…Ç&Bôpîò;=!Qçj"'òHFıİÂûÇ\—ß‡šf;t8l¡-Ù
l~;İA	H÷,†±¾éÿkP†³ÅSCa24&©­C/¡	·êTÖŞäõÄŸ!/Vü£Ò_ˆ™„ííĞ2LV‘ØÁéù?cÌ^
L[•{Óh#÷”6¡½¸$Ÿ;´GßÔˆÕ13z(xÂ…6ñŒÕ5•œr¿qÜ‘j8°]åeGYHªg[˜üšJÿË‹¨şhR]jd\É³	ñ‘¯pXDà˜?ß`˜ƒ"+w*sä”5]ı`~U´-(!IXÒqÅn¸÷œ*¾"^÷øµïéY²Íö>(q¥.§™ıòï=Ãƒ?‰ü'oG›V†Í¾½ndŒ>hìÍé
ğ®»}«JøÕæÙTmõN~kçEûÈZ‹¥Ö[äñ‚¸a±™ãÈ6–!rú¢d§ÙÓÊŠmQ¬4şS2à\šñÑ“Êxg3Ò¬ØZÆ;¿@pQÏ~¹(îÖÛm*§#ÎF‹ô²f`›`\YU-_–½>©*„;ö¬Õñ¤lkF¼à	É~Ú.+íKØîêqB¢œ”²Ç¬ñ=¡Vìd±•äİ¶{È]À.T†°(ùüÆ–¢›WXHÛô»öÂ—Lñ)è—}e÷rs
;ysèûs„àPz¯F+¹W=D0–ÏËŞ«l-İ¨ñ<"ş+c‘"nm¸åâŞ÷"25ø-‡R¨³îV–štA¬Gâ†îS¥æşóÈÑ·èï=Ï‡S0¨y5ª¤/·şR;¡âñÃº"VùLÑ©†]²HÛı÷Sßœ‹Äi4&må®é¬«¿‹&¶æ[ì¯ÉŒ Ğw‡°|Iïı„«Û'9z”†&†ò¤Ø¡9ûÉ`êüÓÇ]A õ{zí0°¨Z‚ÚÃ´3ë ³@¤§x–ÇòÑê~}z{la„–íÌ­¡±îQ`¨Ü9Í¤	R“®oÄî¼à5q?~­Š>Úiê’ıJàK(Q|ùKÃé‹EMxİK—HŞ‘|a£¨`L.Œ]^¨ªŸ G’0¤Â~a@Œ;â!:ÒôÛLÅÊâ©C4İÚ`jAN{|¼•ŸÂä.
ÚDi´Ö±ªŒäzèM-ı}H†ŸU+ˆ iÍ:Ş,çˆb¸‘ÓøŸÔ)©§Ñ›ˆ!®IâO¶W†RæÁiÃ¢ &m ó~ìı;Úšv¬¤_êşP„òº6¾$ß»úŒ¯Ö‰@|ĞkéõæÕÕ‘?4Z¦^)(…@œl)¡=&Â^oSı4/°<ÉŞ8…ŠÈGù+Íqˆê+—P¯„ø4ÆÔ’2qzd‰ôW¢ÁgxP skvæ‡t7Mc˜wx3ş"ø/ÍıIHaeÒÉÆnñ³lZÁÑT§†ñ3df
…‘š8|5w‰a3oTbÚ¡ß/*']×È)!M<zÓş‡`CÛíÊÀ°œ«*·‹ë¢0ÊD¹+}öÁ19ë[Qí{“²[00×^~l‰Şê"“©JÜ¨µåbdçW~sl·—Ge-ÿ35~ƒxìí×]¿‚µ;@v æ
nÁuŒ¡‹±~R¥D;²Eè)ß—¹È»:'ŸQy`aIİ2‰J½˜™`~Q!áÜU2ÍBe¶ûØÇÒĞ(dÚ›˜\¢fÒb7ñ¨Zärœ•Âêb»Iôò¬ĞJı”'ø~‰İygµåÀ4şÆí&v˜½Äk­²é|tŞÖEOq!Í^§„W’! &¡]P±Ò§i#GøÏÕóW>AÍsY¢4…—ºkÇ>¨É¹`ØrÀHXèİN6RÑ®Şíd.ùÓ	9~òWÌ 0=HÅ4PMÀJè—ñæüÂ„‰2IØ3 2Š[å”ŒÎN-£²
(8»vÈO:Èû™Aø;Æ£G72ë>½µ‹ö0_ü"•ñ È©a”ÖRW+/op DŠ•ZÇXĞ"NÒ·æ6¼yIhàö®³˜óG¨@­MF¨Y $Ä kNP@â 	`í$³…ş;‡¢™Æ›|Ù/U÷¹ßëùgxIfÜM5«¾ 	şFĞŒá`½òØ”hĞá3af@Œ[ì—CkÔ'9¡ıHK³¼ÎÇó ı^†Ş' öjËtº¥ƒ°¾­¬¢KÅy|‘¿Í‘NLã%YÛÖRàÈ`EŸğ*F+†RÉŞ~©?Üğoı©uÁ˜=ş9®WE±îá}Õ_6ü¥Áîsùuá ºÁÃ'şı·¼xßsE˜›«¤¨ˆø/v Ğ$q¸dhœõW‹:†ÜzâÔàkñ,ÆŸ~~ê–¾? zd¿Å)'‰…·ÙG›“oº™Ï-ÆØ‹+#Ş$ü$$„.xXà°øpFH0Rëhu;½ªÅ¾Óõ0¦[›êàœhí;Mm8öÛK‰Ñ¿[")@ÀøPÔDìà°Šé¼=]¾ºƒ»I´0I¼àä?İ™*ØIÿzRV×WŞIP…Ymöñï›ÍÙÿÑíXé	N¡Ñóa©kód¢Û¯Épfrifm}±8øO°ÈË=TßGÂòş´¬ÁQ˜Q&¾˜¯~/ÆiT ª?zvÆ·½"t¥â÷ÅnÙñOØ4îïPuÌŠH¡@->­±)ëÂcñx2Èn¶27T_“ ”ş¹qFçíçÂqÓ&Xã¢¯®…Ù]X+}%vÔõ<ÙQÙÃSÈÀéV®<Bæ¹áÆ˜äLnLU¯Ü;w7jiivô¸ZHóD5„ıº ‚ŠĞw§FÇ¢Â	 ëêø¶tòÈôÛ,@9‡¦‰ÕSÂ>ÎÓ£'9ägßøÃ»ş1CôB?({W§æ@~·i0¤¨òB Ş´ qºËÏ]‰K3úËùvâZ©Èø¼¥ERÛìJ¦Œ˜¸¨4¼@ŠF#.r>ÒçÎr!ªü<ÿ0šü]Ÿ$“Õ«×¶h°­àvZP™É¶@*¶Ú‡1gJŞjÒiV^ZNÉ÷MJÜAIn¼¼-¸£ÅÎL–£`‡^D[Š©öSõ'¾~Âè*è–’TOÕ–›âÉ|Ñ`Å¼ZªÆw1ÅÓ—Ê_ë—ŠhËö&„7{ƒªºÛş$îàà¿u?‡ØO¡'%î!hZúˆìú!Ûy=ME²u¹rğ½!ğŞ!´rä{c@¸üÎ RÈÎcaF3œ§pA8Üpù–%6eF€M½Ş¸40Hl¬1ƒœ1œwwUû\ÄoåÊ:ä¶‘9×ŠæS³TæÄZˆ¶(½W¶*›/5Ù0{°¤²=&şì"‘]¶KûÂA{ÂõâtÒdfûİş9T´;'=Êˆòy$;Ómİúïjô;$&á’Ä
ªÇ«ZRã1…ÑF <‰)•:êÉkùaÍ™BÄ€ŠÑŸNŠ¬FÎ¬zõæ!ŸÛ	LgP:úú3Çéçî¶ÿæ÷nä•'5İ“âút'\—°úóZ¯Ï\ˆo$%e¡œóFGø–„gøf±ÍÎÎ“ÔŞI !j’LR{ÀÓƒÃy7C‘ƒtªŠ¸2ªŸ‚v÷šæŞÍR[í$™^Ü#RT˜%Ú¡?l¯Õ³A–¢XüPIK¿„o¡½0ì¿«ık9¯¹ÊŞÿR Yµ»Aè¿š>OFzpÁç™¶>Öö×Œ÷{	=™u6‹ÏtlØŒA3C1>ä£ä?ºB"™R)Ï„œ±ÂŠQ3èàéõ¶ æp”–ûÕ|¹©a·ğşzÉkoÔle@:mhÌåºaU¯õk>®Ñ»OÇr»Ææv×`oÊÄ©É*ÕB&4\‹Q¸:³„R„ËdÓ•5PäƒO?E8ƒZ<×Â_©0²™ÏA„¿„÷­Ÿó–Ú›ÌÒœ?ZO¥;•&ÏEéÍõNÍx²ÃÌ‚VCb«‚”—k“¨h·ó„•7¤\™Ù>ò:©$,Å¯!zañÕ,¸Š÷·#Ñ±AîÊ%q¶TøDú§ ;ÂNßi·¢ ¬Èß>Iú©âùBè%LSaVğ œèÍoN[,‹Ü€óÎk€î‚×$åÖ‹åå]õÇy	dcI.cúİnÇ`NÌ<åàAzœëŠ](ue‰‹Ø½ÁûÕÙnËƒielô®Ÿ‡Aâls»'s§MïÜg¶–Ûü·$|Âó6M¢ÎZ”å9ëÆNbÄ{|y½÷ùëìŸK÷#ûzĞ¹7ÂduÍA0é	$b<úùîM)[%e;0¥D±šÂÀÎº}Å£íTwôat,ÁI›¬Œ>mû^«®ÁPöŠV³4åÕw0ôı¦]‘åÎ´Óz—IŒJpBHÀzY›5Ã$uÑ¢èµ¯Uñöù¿SRÇFí²Hna` ğ¹êü¢c88•™>ò˜§èî7ÈÛKLíù5Å×ñ>LËìÉt­D„\TÈÙ#d	İ(˜¹­™|—® ¯I)­ 2ËŒvşŸDÂ£”Uâ›ÖÖENƒü~)Å³ ˆ¶«Ï‹QÿêgVêtáæ–êX`îÙ:¿ã{}­€v­s–ùœjpÄ5¬Ì’9ÒîÖ÷£ÁÌ³Lû’P 5¿bSgCÚÀà(_jïé ør+ö9Ädkò\ÿÌ@E Ê{úøõ1­z7]Í­v•¯?iòOİ˜œCCÉØ<4ÀüoE¦Kz´Rx%°êáÅ Çoæp[‡<%ã?NiØ´§8Í+S9€Í–¤3¹ğ{ÖAMÜz_Y7±ğö„!ºK#yØá…]¯KNÓË<GƒaVJmCËZ¥%¼)ß‡yü˜":±Û—¸„L6!ğPÉS½÷:tæŞUã5näî»ºomÒ ‹8Í×¨†Ï­ËO+(	ÓİÍ çó:¦ÌV¶@R&¥‹G­
ÚÅ§Ø¶Æ‘×şäÁ ‚şšŠ©†r/;ÙÌ¹€“dŸùC€Îo ¦zGÒx*Ù–î9‹¹yvY°õS¦@„$O²S0Ÿ÷ŸhÂÙÖ¹#•È6áŞ*"Z%äÉÕõvºÉäQæåA=­›¢2(8ïïœÊÏåõ‘MDÿrAŸÇ8›¯¿éè­gÀI¼ªb¤†zT¬çøJ“#z½´ÇĞ@c´¢Š€?ïé) D¦áà1şü+Jğ(•¾±[ÿj¸JÃTÕÆ>æ·ÖŞ2Sõê¾­w3¸!FªÂÎéŸÑU8zŞ"ˆá"¶°[˜ß]¨5 ?;j ½ù‘¢ü*×óèh“Y&~k^cNqªğ¦3ğşiP¼*ˆ;¶Eİ¬xL;îàqÏıgUÃ;
R\éŞ?ö¢áã¥{X™ˆv˜‘¾ÀşüI(sõP©êÛÉxOŞË”24Ó‹9ª«9áşXîª‰’Ô_©6ègÒU-z¾‡ÂŞd=Üú”LÏ…×Mcç vt—š¥”YÏkúl†á “¹¯!6c¤©ø,¬òPÕj³²ÏEàÈ„ £$1ÛNl{ SbfX!ªšÒSJ%Ë™¢µ]ôÕ¹3½LèÖ¼´çùáîvxÊêËÙ´lšDİû¢'he½
}÷ß_WAyfş8{™‹¶Îv³E•
0¶ ‚jæ!2µÛ¿/­ÓCw"ağÊ¢ÊÌ¹E4`«¯¶ôä¢Ö˜Ş•™%'f˜; pA¨ìœĞ“k½ã@ÛÇÒô),?ûöm–y\¿V&B8“õWAÓÍW2ÑÖQ—_H5¦“NcÃè¤›ĞƒÃ®*Œ	w=nWsÜˆÛK[µœµÄ ÇbMRÖIÁ[ÄrkJè|]¼Ñ¬..NR A7Ø€õ¤›â—™²<øb®[è$Chİ¿$À‘:ÄRˆÉF…ÉNÁM’"H$SrWF3ìHªŸ¥‰X–ÁH+ÑZTü8ÿ_D4¹Ò® cë¥¡!Ï8ıàuƒëî€nÀ\ıPêuE4I5;ÔÃv“œÉ»—ÚûÓH“T”ütG
}\
Ùdn‹Ñ0øïsÑléúğT®x~Ğ¸ Õ„<¼&a¤eD+6Y%fq­ví¶ä£AÑ÷AßON:Úû‹änQ]qy©Kí¢ vºXK¾sx,:­®«/Å_;ŸÖfbCÚ§
Æx>ùûÀGvTH[4µå–œå„£S¹5
~w±ûBIbßDd5Ïk¥0İ*şÈWñQasøxËê´ëDB”Å¾€Á±§&– ¦™”ZûÓ•üo]§¤ÃÊçO²n^,æ'.îáÀÆC…ù]2ô
zæl/j=qÿ"5vÛN<#‰Û­9‡û 1RRÎjb5Ÿ®Àú%Oß¨NUV~áÀÛ-Óixø×Kt¡;h‹jËS=¢Õ ê$t&kg—·«Õ«{ªÍ”jX])‚­Ê¤©…‹…1(3LINË”[ÉúAÇÕ‚nm¾u`zµëï•Ê]ÄÈÇ“gÖ#ÏŒMÔ¾À0˜»A¸f(]3®Ö”xWqp/ğ™	–…K¦}bL¬¡*ğ'k	'Ü>6=6ÜÍÂA3ÒÒ‘aŸğf.üÁuû5˜ÕÕûæuXÿC5z¼õÅ/º»I—šç:ºÓˆØêÌ_÷:ë8èQ˜M‰Æ§I¶@ÚV+P©»„‚î€´g‹`KfKê?­=´¦0§šé]ùŠ4F„Ú4ÃÑ(¾KÙrÆT˜lì$G¹¯9N.è>(Ğ{4àDƒ·85Æ$şV€—¯º*ó v\…
V°-×bš%3WT²¿d˜Ò…9Yª®D"!ƒøË¢ÿxh[ì LH×_´z±’µ–y¥úbRÓ+(~céÍ’…òzB+’L|Ò]WßÃï hüY›ö™¯×¾T¦ÿù9œ­úT0ƒ –´îİ«İ>D{ëJÙô„Sç}GCšÓ¶Äa‡HKYÁFoâ°QŸQİ`¶ÑsUJIH|”l^Év°´Õÿó†Ü¤4ö=?6l!D
ö´¯#ŒÏïûµ·PZ«Ÿèõ"4sùj¾¸¯fbÓËgb§æòƒÂ^š^1˜©iÁç)Hoƒò‹Ú*ç´P„Dµ_DMj£ŒeÄÈ(òuÊ‘T m¢°UĞæ®­õ[ÖÁ¥œc*»Ø_n2&®³A$ó¨¢`ÛAÌîüæd÷ş\Î³›I“Õë1©Q;Ô÷=éQj5»î´´Ğïõ(™ D¤ ¿Eø8¨Œx ™óuûğäqeHHÌ«‚¼P+¬æò`#OnÚÌ‰ÚñBÚ·=´“–şOßzuİ¤#¸%ˆ¢ëòt*¢-@æËE9i•ç6æuĞÉıR˜.v{K«zöüxl¡Á¦î'ˆQæÀÑİ"=ªÀI‘ˆjlyÅl~áó±ª&q ÓfÎ+Äœ¹d»P×Z¹¢Óí*ÂàÓwCğà·†9zÜŒÌúûªÓ×¢vö/w6„68üçæ…wƒ¹_rø–<5³Q<™÷$·ÜØÆ§n]K¥(iG¹>;t"j9ü†ø/$	ûĞÒúşéÀüÕĞ³(5—n±¨¶š ·G¨§Nôd?·êÖZ.c"` ùÕ=Ø”¿ì…1¿¿›NE- Ÿ|GÀ®B·0”º=¸\jšÍÜQmye^¡âŸ\·k…^IŸMìÚvS"fDôØê+ècqWƒ%Í./ûhhä`EnÎƒ¥+R¡w2Oui¯ÖŠíDû@ Ğ¹hÚŠ4!ñ?ÏmŠÌßl"‹=İ
MÏZçAæÏ$†íğàBS3ê6v# HğŒ­Â~~TŞ½/±sâ£ØQ…#/AWÒH™D£r„_ø¨¬DTUyåd•IÖ™Aøœcs~Ãäğ¶B«DíSÄH§u@ÌÑ?F8ç»ÂïOlZú*@›„XŞ®0H›`åSyQË¸ã@ùªA÷ÓÍ}¼uêkõ„>Š!/,Bh¬Wç 3YĞ—<zÚäØ¶g=O>L‰/,íJYÅâ"Ÿİ;pd];;©%»µyfFâ0uŒqŠ;Èºë±àÛş±¿§Ê™U©7SúuÉM_,Œ¬ôh¥Oî¶Û4½º‡˜Ò‡ÖO[í{ÌsŞa÷ûÇ›eQ¢á”ŸÅ9C6%W¥¦·ÁøñÎ³ø	øÏÿ;;ßÂcí’mlß:	=»LpYäQØ —ïôª5Q¦:V‡?if?‡ò×´øW±êO‹rŒ­õ¤Äwƒíe$«::6mT©ÿáy# ¦ËğRªÂVUêÉMÑsbûE&Í/Ö™äÅux¤¥uu†‰IYùqHeVdï01ò„)_ÿez²äÇ7ÍÕR®+í[±ë§§¥C'‰¤£¡4Œä€xâ£1ûĞÒÚ/ÿŠîÅ\ÇaÚ½œ;‹»
?ØX2¾D53»{7v÷ålSCg6D ¼á£?7œéÅ9õf¨“:¾„
EÏ¤RvÄL_ôHde–:ÀK±I³ÓK%,ù™éRê¾Zv$İÇ¾Mc‰Ô–Ûœ-²Uˆâˆ–j=¹+(ˆ””„Õ‰Ş°ÑÑ¡ëáNeèGC`ÖOPM·ò§1Ó>ïxm6i;}ˆ[!nt¨ ¸4Ëƒlüº¿I·šwãPµ.Õ‰=ˆØ:ÂNkÁ B‚HÚÊ#ôq¦—YÖ¡½Ây	úÔØh¤OæõëĞÅ¾	7öIŒNÚ§ç¡£·¹ZÇyÎÀ´H¶ßB­PA*‡ô¿2Ì˜PjÎwïUr³?Jÿ°öAÊ“a;.@T£båşi$Ü]¼Õì}?¹éƒ=o!ênó„qBç!!”(6rÆ¼èºØuŒ‡µ2‡’%câ‹ dæ‡2j±ôW-ı$¦üÜÇ÷fÎáÜ.²?Î'İNÑ2ãa^Ø¯Ût-Æ
ÄA¹mö'Hª`6DP‘°™£ì^øŸó„a»n~­n²]%~„QğB‹¨¤_—ß˜Æ¨ÿ·1`°,+ø6ÕJa‘€6ªÆŠ±àù°ºÚ$î
Ë–ÑvóyÈ>•ÈÑTW96Ùt;/wl²4üÇs3æêcá®Š.c*ûVäb÷(´¥‹ò’nª6|k]7G 3¾×€V’*»VüU¨¤N/7ĞL…Y~”¹hö}*ô×÷™ÏÏğ³J¢ÿüF˜˜eøĞ
>íûÉÛ@ıÔI2{@X¬ÕMlÅ1¤ß4¾ÖYµt¬Yç¸'¶¯Ó¬p"'‡sĞo_+sÍäÍIßÂD‘a˜—†“4ül•¡;ÂÎ³DÃW{°.K£Âkù:i¦qGm‰Y¹´új\¶— ä”M[1aR»|o(@¶ÀdY¼#mé¶wS³|åš›ùx“ë)"4çƒøõkp{Ïi×˜èRh î*£,ûI$GG ÓY‚(œ½|}"áˆ]õ¿ZAæçÃÜ¬¨"|e…»ëKeB„š6A
òÓ:ä(¹Œ¾këš¢¼’
Ì'á†Ñ5ò¡¡ŞÂÚ÷ÑÇ¾Æ>èGî¿=mkŸ 8ñ¸»÷`ìP›_†/²èõœá.R5Ë@òÆ"ì’C¦vC}×ÓWĞšI¿“†0ƒ„ÑìÿË˜Sû^•<úIpt…ÜËÄ½\ä®vú¬vbïw:_}·OÒXrÜccö?ÈA¾‹ƒyƒ^šQÃş›®\pº?€X¥—uàgOE°—²È¯—ñ—Ñ‡ª]àK±©U9Plpï¡/ŒCŠEDSc!ÒzŸcú^#Dk9ğÆ"®ÿLFÎ*ãœ«¡P')¾çËÀ¨:ÊWŞ1ÅY(šŒ:Œ@Ò¿$Şr“czËàWõéóôZı¡Ñ¬³-U®¹(€fı»¢u=Ábë-™°]«ë@°i)bÕ¼äÓó–_şÁ*qı\ÖÂ£Î|t ÖZ¼½zóŞI+òA>ïQ€ÿÛX“?ÒyNĞUœlrHò ›Î¬¯çSigÏL«æÈ£”Ï÷KŸÍ~¼§b\Óâ‡ŠaïkbbÌB%!³ş”‡y£h›âÔªäÇ™y„/¬ßÌoMÒQ¾p¤Òvu·Ï¤)*İúFy“ˆPßRzeÂ„bîLìÚ?ÅúxÎ«¨²Å«èU9Ş£K*`=3Ù-TGøïóª$Ñ¸ŸLÔ5Ê ºğI#3lT²rGò¿ÚŞóUWq0@†ú„"¡÷z¶tâw,+šÉæGêÁ:‹`¢Asæÿg(=ìiBàÉ”™w]‘‰¸€êø~ÈØdŒŠ¾RWÔåƒBQò¿® š«8MFĞZlspÀÕ	#0¾—¢Tz‡ØtƒOïÈÚ°;Î÷OŒIb}ì4èbÃ´I—CR/.¢›”yºs–»ŸWGºó ÛÀ¦v½YQ×«ëåp3X9ù¤ù‘¢Eô2¾/ùó+±ÿÄälÎ—¿¡èsR¤‘ÿøÚÇ˜+ĞsOÌ2æßØÏ1^="=¸çÄRUkw™vÃ¤NH§!‹()ç¤1IåA"d6ÂrôzMó²Š,}·0ÃsÃšşød‹¡LÆ=J«–Ul¾9êçŞÕ\eVôh ,Ïñ–MoÛ`47æUû§¶9&HlÊ=i½iTµé£/4G‰ÕÓ¡ò0!B1Eòšù÷
L˜]•‹]›Ø!j4
-âzÌ
âÚAş®HÍÛ"µ@ãKª,d“¬ôMé‘!ö@­(Y#İO­PÄÉË§r[ öiİæI‹l”Zd&¶®ë\dX¦"PÇîÚëhNâën<ÍÑVˆZÉXpõFïş¥²„ÿ>ÈªÊé@U2Ög>CŞ³E)¥„~ˆ[‹xİìšä³Ö}­¯1#4§¦¡ÔT]É|Ÿ©/d4´d:]ìJ*Ïô‚ Ÿa2ÇGŞ=Ğ¹g
[0=³Tc:@Ylº1@É2sÕëù
89Œ\x[™!ŞÚƒp4~Ñî¢âŒò,Ä¶–4ç©Tl±6µ3K,;;ía¯Ë*#'jŞ»ºÜ@P‘®)£ï!Ñv xkN*‘S&™UU)LT§İ»Î2ÈŒÑæŒ)s³¢9Ì~îç“¡×“‘ÿ®Pó|#i;^V™†[²ÕĞ$ÂÕ¶}J>¼ë›Ø×yoà›õ‡M¯gÒì‚'ÉoÈ!ÏdyQâ(Ø½<À|—xk6\¡¯èJÖ3}Bpg¨qØõÇÌ‚Ô­QˆUDkÁwP4ÙÉÊ*S\VªÒ¯ÿGf¿I››<+1Ğ€éWEŒ÷„¦¹¤Ëlz˜wºà Ú…j™mãÙÈÄe\ÆŠ}b¡Ñ
âĞÎp7Cy+¿·aÕ#;ø=Gm=Áu©NÂÓ[]ÙkÌí{*U¿iŒ!;#Šd`7É!2,û©A‰Ê†újsó'çÅÇËş¼e’zËÈŞ(¦¼¤eÎÃ…3|½„sÃ“ ~J µƒ’v~<twîÙ”ÌèóÏ2Ü4FÅß=›63± ÂAşu0Ür‡€¸=X îí^§Iyèƒ:WÚòªùN)É	E`S‹§±°6mœ¬“{SŞe+*Ãı—§Yyx2GZDs;ü¤HÄƒÓÆSC=?ßù”)îKNmèNÄ·¯0wÇ=oÊªr¯ÁãÙqãj2¤íÏ¿U-!š3!R9˜‰ ‘IËÕ/Îá÷,TæD!"
#1c1€JëÂĞPS”Û)Yšñ§ŞpŞ¥qıbË”J€—´äR¹ª‚EK÷dì›úŠ	ÜöéÌ¼¾úñ7dóÖbà:,Éƒüh˜PƒYZ“ì”•,œ Ò~»dŸAQÛL¼ñ}ÈHEtqß”$û‚r?D°—Å÷²§ŒD‡x×ÄdÓ¦…¿QdP™rBùä¶D”¢OåB½Ê®(QR·4a* ºè_Á~á­ÉÆç*`êÔuÁ,óW2 ãoHƒ	Ø-Àü†{%`‘¥}-0˜ú‹éåfÍ$U¼öq¤ªøQ˜]î©í)Çšq¶5†½ÑàFş£X{È¾»ğ&£eİ9¹zxXë‰îÈtç¤Ø±2á!wf•…&i"¡İØ•BªØÀ{W’Ù_¾"³Á¯P9S˜awZìÀ®íaƒÉú{XvØ-™×T³3¡¶°êê[‰Q:êXş0ëGvo¥§²?hC‹Ÿ9‡Ü/´n¾•Š;´d¼´w‡i¯³A[Ä™ÍOvá¹CØ™¨-[¸?­‘H0…£!cøÛ‘³d—AoğıDÜyÎØ hiÓ£mÄ^æM˜’(¯Ÿr§Zjeú©zƒÛ.‡3K7}'GŒs3DhvbÅ$±‹¦ğÃyŸ\×‚z»«1‚ÉO<yÍVOş.}¼¼¾ £[AP\ëçÌé“h>ï¤üÈsT>$ˆé…¾ğ;à‰DÎí(,!˜ïj]¡^mC»¯ÕÇ9ºœ¹ÌJèoqdis“FÒÙ©£ïoºDØU.*1Ë<ô~ŞEY»w0ÁÄx„y/X‡IÖf‡jæšCÓ]Õ¶pÊn”ÙnlYfn•ÂÖ§·T@y5~DXô¸©#‡?éşÅÁ§½’(Í«ND<gß^UãÚÌ‰SÈ?´Ö\¯\ìä§v’=Ã.¬yE(‹ŠØuU0	k+{“ºD#¦L l¾—€ækv¥¡¼ØhÑ¾š5
{3H¥:r¸?·Ù„?ê<lèİbA0ÊâÔ|yÅ,ƒü¡^ÙÇ!W¤ õôh–­ŒıQÃtŠæ‡W6Jb÷X$ŸAæûÛÓB»ÔçšÖìóqœ{ÓÇ&w÷Ä€~J‡1I–êTvş2a2×ô“CmdÏ…r—ˆ‘vCõÄ%0™–o sç€A0¶3V!Ş{G(9ßl¤”¯¶æBú]øª$mµf"G®çÂ¶‹ä3°ıxD—<+K(Œ‚å?Jò:‹EïLlcÜÒ‰ú%_;çCè©GÎFğ¡†aóŒ›»Ëûs”ÕS]8#Â;Ê‡M$º8Zù“ÚÄÆ¢PŠ4=_å±RMI¢ûù”ˆÖ¹ÙÁ9İšá/§é½ôø)şT«tåÀƒN wDúoˆ D+Õ…ó_Ü=ìèaâ¾‡¤\7¯Z¸Ö"B„,ÂâÔLü°s”7S„ãÙ3Lk%Vó<'qõ@ş+Ì¦ì•¨Ä½÷EŞàGÂ¹2à8×µÙ;Äğ[WfÊgm~I?„EÓ<6DÚšœq8W|	W`PÓı 3“–ä‚ääÃÈãV ÿãõ
“b|ÚmØÂŒ*o:>mÚ¸Ä-Ç†Ò‡h•0G¬E²;„‘ OBNúõc:YBsĞÿ`Å$6XÕĞP7möT/ÔVº0ñ HR¡÷ô°½Î<i`ÖtçÀ_ğF*V.ÍMà'8`­­t€§ö£)ÿ‡[]™Û
?¿ûÇUG¬ü$4›„OMæ;eãN­KFæÓ¢oÕtG’'…fœ!
 À â_ëRFßî^dŠ|L|}³_Í!­èÍ»ËäÈfƒö8ú…ùŒŒì(¤7•mÑ»[„ò¨3"H´ÜAg¤òµÀsú†5:²½Sv@ˆµƒÁğ=ù»°ÔœBèŒ¤Ômç÷Ï\J²‹;O%—Œ+ú©={Ğky%”Z3óG• gMİæ¶ì2G|Z¡{K†x(š1!‚PöŠ‘êê¢Ù¤¬Ïİ„¿h:ï–îô®üÍûc¿=¿H)ú÷Ì Ş<·Cß}*ùzŠôfîîŞ(ö`DÑy¸xn  ª¸s-ËÃäBÊ™ uµ¿|©÷›7HtÁ”7/ÃSÅİƒø6P#ZTHÈ¶;ÈÃhp4šP™ÃB-™Veø4M¢Ö7«ïà›Â‰/V½óï!MdpU+êùƒËá
&LÙ†‚¾İ˜=óf„;ÇÃ2_…†¤[ĞPSÎÉ‡’|ÖOä’Á5}À!´¸¼øZóóØ(˜Â¨ê¼à¯¾§Óì»Õ4—êúI¤)GeH­úñ¸`¢íÕ2œX‡î*©íÇ	ÍXœ¨øª¥€Ù–±ŒËÍ4BØÒ Æ ‰˜¶²T¦¦ÍŸfQ€m iš üE*¤‡o´í’¯ùôFÍDb—X<×ªåmq‚Ê»bÄwæà´ŸGQûbº_K4zsÇ$Ğ‰–†İv0K,2—ŸwÅóuŞÑ’Ë6uLsŞe
¡h«èW¶wD­\Ÿ‡£]ñÊd½ÎXğìZŠ¿ÇUñdE—$T¥ÁL;4Œ°ÚzøŞ¹ûş¬ãËÚ-_XiÊÚ­_âNG÷Y_ó‡wø+¼ØDåi¡5yÜ$|7Ió‚5!ºÔŠ?iØo˜f!àŸ7‰Ä5…ß`xÆv@–Ú+k}ØâÙşJ—é÷l»zÃ¯q…m÷ZæÙ;€¤ ïe8ÖC¸¸„o®\M+ :ûZcÄ<JxìX¯¡
bzÌÒVÓlø|©å-5ñî³Ë=T&+6¦*–;³%déIˆŸ1>[š¿Ü¯êû» Xı£ÒŸ\È½¦ĞQÒ³›âº%e×
êØ;ä…æœ"¤+çF‹İ†Á¹øX—ñCz?ñzÚ|â½±×¦g5©yV/‡,.N®BŸ>ó€æYB;öSPO{éº@VVşT®_ S)à1ÈóŒ©Ú]J`túšHâ96Ç€“Ø]rÁz¦:à7á"°ŠÑ?Ü3Íûİœ°&6ØšBÒ˜ UÆiã€æ3uP2"øo"yêÍÌŒ:û” ïûA•^Bâ4`àíöW£)ğ%|¯š6w <WE¯¸ò5¸Ô~…4Ía§„»õ hÍ1â-°Ú):›OÀ‡ıw™’ue­F¡=¦·X“|‡¯$
š§ÔÚ]s|ïºJİf¸H+êI¢hov jfn*0à?”/cŸ©a)¹‰ˆ!)¼–y|›}©©ì-‘×Ñ>ãŸ1æİÊvs¢cêø·Úzù™õ™Ë¶K„(ÎRó¯5ÿ’|‹X"H›ã/[«CÒhy:$ÆË”Í1E®«ô.­3äÄh°+W–‹¬–l"'R­”{­"D7ô¹C3ÔÄÕ‡ö%^â'wUæT9ñœVQê!˜Nsxwj¥¦Mcfûq”ºkÓvˆ¼¬ê.ÓÒ™¡×ÂQ#a`,ÚÒL4Eåß³SPãÃ‰)8›Pr]¨öDC~Uı">`(U…mzKbºÏÏY~C™ÄÃ¦xÏ[ h3Œ4¯÷f6gdş—Zò=÷ãA^Ë¢ÜœÀÚÇñ>ÙôñåJÉãŞPÉÍb™8„qßÿ'œ†L‚ÜÍ«¯6ßMyy;!·™Q±Ğ£ıËy.WRãfç”à.Ïc=í8ğ0"'{Z¯Í¸Ã@© .h?Ïiùã/ÍUas*v^î	şj‰Å¡Ó¨½Q6jïu$nÑTa ¯îfmª÷µöP2­j¶nsm55Âá¡•U¶–ÎÀùFe(’ÖºBK»6^Áì8Û’ß¯Æäß«;I×Ö(x›hßÏÆ~ ÛÁ®.Ã*7J>–Y7¿¨êndsÓT¹eºò©=¡ïÏãÅk”>ûAÉŞÂ¤Ü\ç;ô”Hİ+t#Ká½Ô7eW³‹İÿP³§»ğµîù/œèYdóú´ÛıAySE;ŞrşX×ºlnŸ/51Ú)Ğvã÷Ï¾@‰Á9ér°ÔùBz¡±˜ÈLrÕN¢J¯‡*cFC<—éCÿCŸÈèBƒ'¬™õ¨ru¤B²ùŠòÖ7ÜÆŠ‹‹Á:{>WştÌµÒvËcN~X'z*°«+ØgâyE£Vædè¶?ª©tY>×ÙXB”Ó6.ë|ûŒ)àVÖÛÉ3ù|æ…IÜ>îpêURëÆŠ¬\×)K%QÔP¾Ìc‚Ìd¬a×ÙWÚö3İNP’Æõ½#æéå¥©^BšªÌŞvŒÉÒédx“çò+™ÄÑëXñ_çÓÅ/Ë!Wv‹'¡UOCAÑIÓ¥tô :B'ª7ôòl}Ë9x±L{²@o¨;g0¼l$¶Ô Ÿ#U`Ö}ôÇë2ÚÏ7¦¾¹”Lé/_{ÓÚ”ì¼€BÄh¨İ“ÌaAQ‘–7¦B[TQ1~‹QÓ½w9ÕŸZ³¤$&]Ì©¨i£u%‰Şş˜‹8m$×1Ü|ûõEÎœ(·}ysÔ`¢$ì|èRş&êaB¢p]w\wY·ªğÿH0Ëöç“ö_36DĞM”m°cçü–ıôÅğúæÅ™Å3c5ÒÔÚs¢£˜¾è¤N#æ’ˆRÇÒª4b=SM4'¿•|a’ÛôojÜl3~tº|ì¥4 sv]òöO·Rxª/¾œ´ËA—Kµ_Uv5W0µ–Ä¢ØãIsßù§ò*â [DÒuà¶4Ê¡ÍeQ„ÙÚÅ\Ø“6Óì¡yÒ ÿWs/e?	AÉb½r•Bí-ÅU_+&B5!QÈZ©NN.#ÇRl*Û,Wf¯'@Ißò•$Öû¾éSl)*H°Ù÷T›otúÎ'4M¾^wö˜_g®ËwA[Ñ¶“ÿ§»Îw~âşÃodv°vxøÇ§²2Øà)8ŞË[Äªÿ:Ğ¯àÎ¹é§^”Ğ¥€buùŞdüRš|.Õû 6J
×è‚u#‹z¾#Š’‹ÙJÌóK4(
ó	?ŠZ‰­’î¸íBv‘8şräq?Í× ,‚$²Y&ŒiW3˜"ğ6ìêæ¡ªZ`g°èÑÃp??&Ö€@âµ,	/Y89ú¿P(ğ:â—ÕRSùú¿6ºŠ OÅ–)¼éW~*@˜j‚‚ {Tv‹‚ñé\OŞD€Æ#¼Üéş9Îp±LCıœ~»tU³YbÔÛ[	–=ÑşkZaÄª§ç„yÈ
aáX;"6Í¬áÎG¦3erüû³Zy¤V¹ÿQ2¡ki1Üªê6k¼ïÛ”)›Dİá!ôÎsk€ñâß‘ä/M)‡±À¼	Ñ	‡ëµzı„LŠXqäñmÈ•5ÁĞM˜ÇÏ¤'cHÒ_úgoV‰ßôKi™ÉÁ”¨>M® ¹)ÜG@<Ø Ùµİ6V]€ÜÜgâmıE}4l†®y6`ê@9±‘çÇô¢„yF^¦xSe1q¦†L)R5#Dş²X+òÀ°*\ı'W23›úsì©ğĞW«îsbPüH{ğÿ%(LWn çXìëç3ìØ‰ÌÉyµ wªM¿Z¦°/qşxÒ]Ô4¼@’V¹i]ãäˆÍ
Äµv«
S-ó¬¸·[¹¸<Ÿğ‘ø²[?ÎÃ$îÀ©æ’\ÂZaçÜY¾ğ¥”ÖX8h@k"êóÔ5ã™”6V!”Ú`\óº8@a}æ®DÙú[À° èJ]ĞËGÅ¢¨”pã%íÊ[¸Ö¢4õô*uìøZöh¡
W5Náø˜dÄˆENÑÈÒ¯,İÅâìşw¯FŞÙ£yù‰7VÜõ†ZœP2V…zU†*8½çĞVæ¸òµN3Ä<Pzf¬ßE;ÁzAN‹&Uá'±&	>²Œş‘V0³%	ü«|™ÎíNüåcàÊ¯`–T®ÄÄ³İ–±Ä²BÊÄq0ìz± %ùY‰¨ß°k¾‹G$"zOè¼p¦‘d˜¼uİ4J×±cX7Lº6ÎÆÌO°,«=ßï©ssŸ ZKââ°£ÎEÁÔ^_Ïb†£°R3^©&½ÑoÁ]¨)8CN»xí¥unÇ!üìí†§òjÑ*ö?ï›Š
µ¯¾öÆ+xÿÑç)îñ’,o”ıHºµ:J<‘|’O	T¼Í`oôúÅq«Ì»¥÷/¶ü{ØÓ{Š;¯İIjÆkË°H8á9vk õ'ûm#Ñm¯D'Ÿ³RıÖ¢	dÇZ»ºL/oã¤Íë¼dĞûö±3ãƒn9?;ÆÍã4éî?4_£‡ß½w}öUÁÌNgi :Zdœí-·–P®4¥…šL9	0 ŸQÓ^µ+AèÖ=ê0Ş=­d‰¬„¶¬_ä½7ı¢ëPÄ2Ğ—òz?¿9O_"ï^uÉmG>A€¿N:·«§ èø„û‰š"UU{ñ!ôßÃúâZK(6:Ë<©”üŞA¿4íx„´[©19M„‡ÏkŞëÔ1ÚÙ¨è½(DğíŠ:Å@¡£Ôƒd&˜…ï9a÷ÆâkaHÎDŞ<U.Ú›ÿŠ
ì,CöÁåt[È€èS‹µXÒ»b‚”³«›ô×›m¹Æ¢›‘º\Õên‚‚w"u<Ü&&öÒ8…SmGÄwbÔW³«¦QÚ‰ÇòYP.¥ÕåÇ]óda™W,¼§Uz•Ìp†°ùÂÖŒêúKi¸c´ÒÒñàS9³W0*3¢À7ÅY›½˜üş¥C=Ş­DŞ‰^Æßƒú¢ú× «
H²AóKzøÓâ4ãŞÀJ.ÊR“öğÀèBFõˆ;«0s`Ğé«ëÁ5¸İ2ßİJşØz–œ"2Ş³¿÷Â¿şàØUcW»É•N*}]³œ¡¼¥e¡‘G6ä#üİŠ‡l€¢ÔoÎkˆ>Q·y]Â³ç?µu¬ìsóƒÊÈl´%	{ˆ5sh#İV6g1.iêi€Bî_“G=MÏPè¼PIÆóË-†Â}©<üš¤dĞêÏÉQAbÀI–Jùsna&õ0<+e7÷ùüz{Èêşaœğ._›VË({uš©h´>bSˆ˜ûìgQçt R`nA€v#IĞßàH·0'¿%eÍnŒö-rTœ³ó[ºTe!“åWN;ÂµAÆgµ“®~û3Zyfø@¾ÑŸ,L(¿Ê—ÿ¸C&¨@b!NVˆÍPiğôÌĞ'ıÅ
Bã†eó²á{şYw®íZğm©2İ¶6‹¨yqë†™Yœ¨u‰jÊ‰vÍà’¸ÊÛÙ	Z¤Jƒ´âïİtŠÎ}—ïÓY>úZ¸ïˆ”ıÿ*OE¬±¨4AÂQm%&ØÛÜuZÊ¼›VeÄ•À‡U½l2®ºåeß\¨SÅ1†L™&ã0«hê/0©*3¤L(”h€c¤N¼øCï	ÁÑ.à\DEfãÇ…Á2š¡†/ÀŸĞË{İ Å´±Ù("]İÊ¬¼ŞÂúV¸ç²œ°4z³ß°7j“Œ»×$Ì@}1­FE‹ûTœÖ¬cV±@@MÉ!PÜL>¸³Ç½‰+U…‚å¼ïÖş`ò‘Ùğ÷ ì¦>ˆ*¸–²Â³B6¤‡œ~Vù¨l¸wAy[S[WhQ_Ş\½À™åMÍO$Ni¥èùëwáµƒçCJK®Æ#}°ïï@^‘IĞùÉ÷€Âñîû‚ıx±,Xe_	ì‰>o>8Ñ=lC&LÔı“1£âÑ0*†ªYt05•ó šÌ—Q{G}B‚6Şcù0UZœÕ@?×E#z$.ç½àWÂ1ƒ*ôjMÇˆZƒ^¦´Ô:¹c‚ó›Oõp•x ¼[CúiMİß³Tƒ9½L` úš¾B—5-ÓîçVM}'T«ÛÜ
AYe²õšŠ/õE®k0ôíÅaJÕEì2œï˜tK ÚbÆ·+Œàsü "ÿi‘à¼<à˜}ıç}“rs2¡eÀÌ·xÄ=(¦‘vt°wDTa¢€‚¥aâ[^ºïl%?7öĞˆ…#Ÿüáô˜ê;"RŸ†-—!³ÕP4şpMŞ|Š?øLá™r~sÿ‡m«*=ÛšÁÀs*[ıW»Zùw+ µX—‰vÇ)HV9’2¹z´m=R„‚zt¥’ÈÖ÷­#›ŞÁÕ>–•  yäíÔı€fÿ˜bº^Ä-Êl!ö2¹i=)L!Y P5uƒíÙtÁWÁüíwàÑÿô›åFƒëc+´ç,p˜@xˆË*UÉ¤W> Ùp¬¾ı¼nHKFwİ<Ğ/ÿ?ŞgŞ²†ˆQ÷ü*5ÚÂ3x>Ï!õvŞÙäƒ©¶g¸ÙÀMº¬H‹ˆ%;“`~+|C&ÖãùZ!ñûÃ	ÄIšÌL¾Ï#M-¶Yá/(+¿y7]BÁÓ^)’Wä·9a3éi*£L*Ş%UEÕ%¾ú+±	â¡Ç›Ò¢BÁÃ&—Æ¿OÄe„Ò›0ÖåÖ€w*-l*÷‘ Q?ô@-¾wÓIf®Áüß±eeçL£‹[Tjàğˆ=ò.² <‹s˜=ğgëå€Z=-“ÃE2ßğØ˜s¥aÒWD`j–®'t7“­ZGoÖ”ƒG®d]8É#A3*¾¾>ØMK«šã­Ş•2õ„ê°SÃÀÑQõ”T¨muôv­És±–ç¿Ìã_¹ØG¦‡ŞñİË,)æõ%ŸM ş'$£òV=Z¡6oÒ©M8İEÄ‹9«IãÒ1ÙAˆ„ª5}¤WÍïÎd+	q&Bµ}BNöÒî6ñ>Ş 49€œ ëÎlÏ&‡©6ã”78:½ ¦¤½ô²ÌjÉWû*f;~r{h»³—Ëàc+:«	¤€#cc…3‹AX½ƒmÀl>Ó<jäÏPN#V^oŒ;<üçlÆš5µv¤ÈuÌ´õ/¼rùÌ\•íÖ˜lj¼\„«Ò[ÄDø8Ö<üüË3ƒ×O*_mı T´¥÷î±Xc£`P´Ğ=óI¶¾JÅ2ù,m3Rİ–zd*>å)	ˆ3dòÕ„‡…œ÷ñR_¶¶K‚ŸdÃwô;  öD¡RQ_ÑŸ"¢ƒê4´dxËæœ!EV>ùÿÌG¸˜H½æ½á)ó:ò¸¢Ó>_¼6/¯Ë²G­ ¸Í¥+›ô‚ğ|áÀÚšt,ûÓcr©g­ÿfØ;š÷*wgfU(pj(ã¿X›ÆZL*»*şñÍ*âsâ	â¡³UP"ƒ…ÛÊÆ
^B±!¿zÎ'‹J#8ŠGE¶h; <“³r—~ÓÒŠå˜5ip	¹Ã¬Î¡İÂ>( P’,ş³ÁÍÿ”x‘ØçÆG‚A»¾Ø]¶ÀiØCC~½í‚'Ó$¹DPGp0/“ÏÛ6ÌÎâVUöè½xŠkAv1[‘K’D07ş½C-ß]d5êz^¿¸B˜-Á&w\îİ9Åaüš=•¾ı ‡¯o}Ï^¢]w’>ò4¬‚§æ—!Bë3ãB‹0›Í“ÿºŠ7ú—ûFb#-Kßv
@ÙÒ€‡T|ÊàœÁSïq­B—Çq÷Ñ"lyÖaY,º?}É9ıZuÎÂ8zE4…öš±HºÍN-[Î¬×C»jfîü×väCqÉe€˜…ñOMÄ¸iĞ9Yc g—v#9êÑ³öXÅŞÕ—mà"Ô‰?ø…xñ6SsEuIö}c™U|ÀEK\S“FÈã€adrÈ1–tí£ƒæ"Ù¦7DpA’3_il’&ôÉ}ÂTKÜêŸCKzÊ.Vµ}_Ü£‡ëº¿a«ÜrˆÛ)k×‘IÄêM†«áXb,ë@ñyÂ+Gª‹ODÑ”•MğkšÃŞ-R0—@v‡‹ç¾£gÚŞ\M:şšş	õlëÊq’	…6¬Ì;yèßıŸ¥“¸Â+R'ow#®cÑ×CÜåu"pâ,Õâ–Ér Cnß»Œ#‚š$Ì‡–¯Âm
¹¯[­]«œ¶×HªaC-³|)\æ±¥¿I±F$ššÿoÆ#nH$ùS¹tmâÙè	ıgÒ•d,x%âIgÕ>ò/ÈlOJD*ßö&X¸s2ú£äCU­˜Çñj1L½Ñ'ÇXy²ÈBª1§³5˜LÊq<j³š+ÓA“
äIæVÀ{òGHÒ?zY‡;¢2"üMıÆBCâmªnY~ìå;Ä¯_	İ23€Kï$Í‡‚4‰š(‹Â£ğz†ZŒ¡F}À¨ò²]ÑíqĞ İ¾íX4cê£]üÀG\<"”ÙÏ@6‹ Vt¢‚O‚šp
÷ï,ÚçÜ9V#nR“æãO¶R…óÜCiZb;œÆÿó-A!³h¨
i_ØÆ–à<‚ó?y.U±İÃìë7,Ë¢5ÌĞ QCñÍ<ï%UÂf§HöµåÕÃpŒC¥eôQ_âİú™ÃÆE™õÀ[­+±Äb&µ;Ë¬@ì=#«íÕu…_vxÒqŸSÛµƒò= €Y.æ,ÌÂ×z]vÔŸÇàzÚO`jô·ô"\åüU®ı¬L8è”ÃØ‡‹‚,EÍØÈ:t–”Sx”BBß¹+aY½ã¬˜Ÿgvò«{!ovÚ¨¿¢Xrlù#¢#“Z¿ë8ˆæù"ù÷"=ï9t¼)cN72Ò¡ôÿÕ(=ˆ–‚riHÍº¼—ºèîDä­§@0 …÷k¸:A—„ë)ÒÖñ÷Çè|X3·l óbÙ¾$Y×š™ıP’ñ‰|®‡GGŸ¶"Ã­(ı‰\@.¤Ïëv×Cšòg·K«+ÏÕ1õQÚv~O>Ït1;7„"Ô£Š0î6Ù†¬eğ.ÔéB€Æ)ú$N‚²±âj<İ¿ài(eîèÜ¥,Íæxø >9­î¾3fW¦£³`òyl¸*ÊÓ™FMƒ¤æ8e7f\n3ËX­çkç4@AÄÍ#²ŒÌêògJõÄ§ùû;#Õò½\Ø‹;LÎ+p±šàbüsæY[­/ÿ!Ïüf" àíñéVlNöÉU†¯Èî_´ÜÅ·ÈpÓm±5ØQoıLÚ¡åT½¦nŞ38•nú– kyèş.ûä”]¦Øî-%ŒDü5!©CAN´>Ö”*Ì#$¯¼±¿µ0ÉRb‰€£îvH¸ş¨øú¦ı``Y¨¢§ÁQ|”ğà!¦¾†*o¡$õaMjCLmœÒ¿âÙUı>ú{úê"µòÏ¸ïQF@‰Ìc>RûíÂ4X¥`î¡tz«%úC¼\Ãy™õ LÌåïö›@ë¤OòÑ…_¼´ÿS&ŠGbØLëú–×ˆ©óæqV£ T =7[ì9êÑ(sîë¢€]¨÷©›
eJ\}bGÏü¾1¿ûùõ*E“Ó_€së¡Ê†rÅlhËJ$¬ëñÙôÕGYîËiÑÊã˜Ä4®<n[¥Âvcüû«ºÉÁêİì«x¼¦“é£°ßÕE½!>g1AVÀ´zÅ»®òq¸‹Q½á.óô’g^Sòs¹aû‘±,_a3ÄÄœkc^çÜã‰lÈíÍWsŸÉ«}¾4-íÆ
¤Ïœ¥#eê¶wˆ9È
Ò¶„Ã¬e,ßÖ­×èaòùÎ_`[k†ƒZITÀW&'=·¯0“É2Š¨ÓdûG7sñ€¼Üå§Ë	eºèƒÒ~Æœw[^P¸ÆnX¸Ò—ÈÊ <ãLÉ§ØD:ëÇ/ğ¤l±ĞÆD¼S†'r4Àåºç™Óz 6ß#×!“qc¯Ìóœë+¡†£á©0¤Ç´%³w†¹„ìEóƒ!+ÏÃ:$”‰áª?ÊA{WI“Î‘O’Šœ~rV€¡4Ëì;§ÚEs–j+Ü[5Ë¥a’1²š«+‘îì_ï‰dß1È§—Mø)“.“-vKœE7&€OÀBdülÊ)Ç¶:†	Tù(J¡XÏ¦1àÅd=Ø×"èPÙY¬`˜7?0µ«œ¦»Ñ¼ûŠËG[bC‘*fÜ3¢¿Ôúø`æò©®cC_å‰£†ª¸à€: È$¬U—½¨,ˆIF‘ò<øˆa§ıŞ·yîg4`|V¹¬ÀiácO?oËÚ…éXcn¦èòuû„ô{ÃÌxÉtÅ‰¯wßq1s×JAÒggî²‹	Ñ<v6XY/‚9ŞµJ»p|z7]=7ÑtÅr
İEËè®½	dá,mwîÓ˜ø®2?.kTì#;_È-ER5+TÆ0(lxĞøpŸ§#­´!ÕRé“~Ğ–©ìzÛQïïüå&¸eÏÈ7|e¶?—a]*¢èF›o®M+²­}ŠyÚ&{ÿ»ebßßö=kqÎ€ÿŞ€å(G!Ãïj5€…³Yæ(ZÅ| A\öI&o!-fõvîy‡p+cÕS›×.ôÿ„: èÉ·*x48íWW|­ÑÛHÏëŸº¹ \óÜùzbÿïº1˜.÷~>u>åD<–BÙå˜ÅÙ· ¬<’ö¦L°iE–ÛÒ¶òß9Ùw=õ=ÛrÆ-ØYÈìx
]‰u>ÊøZß`òñÿöË¥ ÚşkwW\nVí)jKo2òŠyß
g/oV¥…şìÀõ29*j%…	áe3ë¨7İ¯„Y:Òeï¸×?´à mÀNîº!šw÷n´OEP«ÚÓt~)PÉ&Ë—ÃÔĞóh×lcéQšP(èöÜTşşm~8xòIŞ²ÜÅ¸ h£E=më/±±İsÏáÍ­(¢Š×áXˆe™ ×gĞ-B\Û
|AM¡<Óƒ)Íjë™°­€ë>Áú©@ìooÅo©èGT	B¿Ş«º²lC‰Šô·à/cÏ™m™ib‡HĞ!N^¹ßÑ¿˜¹¥_zÎsW\ó·D²™e°ÚC¬u2¶ãŸæ»N½_7İé<¨Úî½Bqü~1í™ÖocÀ··Q}$M˜(xÀ‹º¥X~ªCÓ_¹T¶‹˜‰Vƒ/ZÒ-è_îySaÀ¸@P7w±e=¤·ÀÍœn^–—ÊpÌ(‘™‰º«ğz^_¤$#\{’§ßş\Ôê$/İu½Ïê&ÜY×ªzID®â<š¹@¨`„JÕ:ÄU¿îdQwÀ,;¨1LõÊ,‰Eí j;Ë\M!ï‘0®HØDÀY>>U	1²7ş;œ™^ûS“øáF˜·kR´MüP½Ø×0§[xc…ª…ïşwª? úÚ­iÖqÚúø¨9ˆCq	­I!5™îÒ	ñtJG:M+0¥Ã®S!“$']×âå½õP±ä?GÌÎÖª`^m+-¡ÒFhg
ÒÉÔö¢,ØÙoì
S7œâ¹ş ğ+XøÜgØ şPÃó5#ÏÃST&âs§Uş—.s'Ë^\vd§0ÜGl‚Óê‚¡í]’Àu‘¿$^Ò@RHnl_)ì^æxJ·*ãà¹CdJT9Ü£Ñyÿ0¿zÏ2S

Ái¼ÜLÌ·;&™…I¶_ÔğÌ‰$7\^füqè1´Uj‹…‘·ü»=â<‡rº‚ºú`ß¿)ĞòDËÏ683‡İ ùOÀIyÎ—’V	jÚã©±¨ù‹”¥Gq13!"á€×¶1òY×„P âg}bPÁ+_…ã;U/F i™r£¡óÚÌºMä>Å£K¶•†#¤iôn;"	áIæ‘Åß»½Ş V‚¥ÔâŒÔ!‚¯ÜÆ»‡YOêÎö~†4ùX"ÜÇeèeH¸P‰£ƒ$%q «3ÿ¯S3ÏÛ12âb vŞÖëP{P‡aë¶4ĞğÂ]ÔQôŠ~’ Õ¶}„$/¶P@±tÚ¬Lm™Îœ]†‰³ş8IÛò?sTØİø	Ú‘_¥J¨cóë¤\
Vtn–";ñşI_$uÔğ¯G/ÿÊUô›³D¾éV9]>¯œ6g]}Á€]{JËIBb³O9Cpâ@ç8yß²]İÜ†Â2C#Xš    Ş°4Â¼¯pW å¡€ óvÖ±Ägû    YZ