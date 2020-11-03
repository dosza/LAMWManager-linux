#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1402243797"
MD5="0a93bc706f9dd7f96514fbf64309c6ad"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20676"
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
	echo Date of packaging: Mon Nov  2 21:46:18 -03 2020
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
ı7zXZ  æÖ´F !   ÏXÌáÿP‚] ¼}•À1Dd]‡Á›PætİAêepúÄ â;”}÷Íh»9”ëA x‡A	khŸp	ÈÜŠÂà©;Ÿ`P8MÇí»0Ò‰vÊ G5ÄÿŒ_Jñ?  Œ¯‰^TrØ6)ql|kbûTUO¶å²i{•4‘6H€Œg)À^ó
+}Ûº5Î®5m±£Œp+êüÑÿ5±ìñ0ûx&Î€q%ImØj"´ˆĞ¨°}?—‘Šá2·yèñ„Ë•KÇ}7FmMû0Ksn»Nç­e#apõ[ TbiÄ¯	?]í5XÓb(|šñËT=öWÕÎ›Æ;ıh·‡à_mçˆÁ[Æ;XY¬ñì•+€¹;´ØÔ¦#4'7«—î¯iUb5cğhŠ/]XáCDèö•·1]²¤}T.Â£:ÛĞ•û.7…$ğ‹ÿ5¥¬Üª!òàïN_ªˆšbƒ"¥Û8b¤ÀW(Ó´„î@’aÆš´óÇeAı%è·ùDaá¹â&#áÔ®EXOuåÒMd ıÏÒCÑ‰“ı \q²’/Ç”ò[Ğ‘ü–>/äN¨3pW)MÎH{6ê(ûæ`p@„Ìş}„ã«†È;S0İ{Ø'GÅ
º„F3Ç¼{äd*¢p9*l ÉÜ,vh´ ;Ä›¦Ğ~X2äÒÄ ‘Ó°`¸Âalß°,†²©Q†oŞàà
ã‚Å)°w˜'”$RR§Aå³+f¤MßdfwV×?äyp"%°'2ĞIo=ãñ-±—I¢Lˆè§SŸSÇ:’#„ÍrçÂzp?F¯:Dƒlkš`µ2È>ğ=¥ÉÅHÈ·Şì³9.biÿùKâåßš^/»+/ş,¼OÃ·L…!+EZÊ¢H‰Tèóo›Eá˜Äö0gƒ¦¥æg€mÒçÂ5/[½‰C½ö¨èü·ÑŒn¡Ê<Ğòc™L€ŞñdøCYV˜sTº,½[AHuZªR¡Õ›2n« §Í"Ï¢Ş™ä&ÅB‘ó¨)‰É81 .–™ŞÆƒâ½ î~nœôÄ`‘ığ‚KÒqÉÏË„i3	`wî?ö‹}e=MnĞb¥ü¥Ù,*+IÃ•lvzı8ó×Ğ¼V0-u<^ÓjH([¿]½2¶DãÇ¦S:çˆwŒ@õó7Ã<ûmÔŠ£/AH4…„Øa…y^6~'ÁÀI§íx[Ò,Ç|\Á–Ä­?»qÎêWNt	´ĞmŞÜk,›€5_‡H‹Â‡Fß¡e'f¾øwŒ9jí	ağ^¬a•+½®¹|ˆÿÜVš0”™!ÆÀ‡pB H"Î«am+Ccl&bµeæ_-IP’Z/€úQDß¯ö¬¦jÑÏĞ_ÚÔmùe2.oj$©ß‘éÀ"È>Å¦Á™Abp.ì“6¿Îö4¼`Üá=>¯¢ôˆù­×Kkè÷0^&ŒXo\p}]~¹+99ı#0ô:	şËk÷§‹ÛÜ±Qç÷÷~c~¦=}pŠ}?îÖ¯›¶(T7‹¢[ 4Ï¼#^ª™uFŠKÀ¹gÃW÷x-MFÀıÎ9ä›rª6½¬UlWĞíAá÷Â¯Æ¢:ºÉnébÌ%~ıäıjümÉB •ó:›ÌLÃd%şª'¨ŞK­ƒA1
VA¾C.5”ûk›{sògQBşsÓfÈ~›T—¬ˆ‚vB0óó]4)áŒo5”¢ÕÅSÍ³Ãàš9ÒŸlÃB—NŸg,{–ij0/%¹ï†Wcœ9ŸˆVaH¶N§'2¡¯Ôî§«|­,vÙ0!M6O[ŞJQ•=yå»¢Ø…¯Xu‘–`íÑ¨Ş¢š¸ktè8™\ÖY’K#ğâí^À­ˆÉZ$¼ÃkfO‚>ëô™ÜıwHòºbhÊ“T;«HÂÅx1Íè¼jé,aI #\pOŒ¨­ e×`¯)ƒ+ĞøÎÃ„VÎÏá¹+xİc=Ô›TË­FéLË
£-ÀğAmúŞ*øs:½û¾à¹ğÖõD³Ş†/¶uµóın¢|][|°÷úXÅâ^]©0~ò¤ël²—U¶¼_[×0E€ßõªÔÖ8)6ÿ‹ñym¢yMÍÑaõBÛ×· IÓ…wâSg½¿ì-@á°|tH]¾3ÇnÔ÷"	 Û£E}Ö²˜ğ® *‚İ>jæOŞ!3ói#Ë¯¹Ü©åjb¶ •mrŒFrÌÕÄ®W[£*K™™#Nqİ ÛR³çúÖScñğXıãıY mªO‡VÅ†W9¡ŞqWÖ°m: ám ¡	æj§8ØHTıpÆ¯êáàÉ\ƒ+¥²tízfz=D¾lF ¸gÉÌØ`O µêÉ]7~WvCF~ç±qŠˆ;s° E~|ŠZ&W’™-h‡½X“MsÛdòøˆµšˆ‚èDø‘ÂqÕŠ›…”Cœ–lÖûû†>T34qã”q	Œm|²-•Èı#d:JÑ¡«/ìoà=)^A	0`¥e´¡µñ±=[Zx½#4+2îâ”ï¼íE½kÈs™ÒÍ¶çÁQÉæ±¨ïBØµüÌ{kVôa<Š5*<Ë‘%¤vö–ÁÏÅh=A0P2æÁ‹’”snå¶ê	zŞ¦í¤åÏ¿6jûÂÙòIbØÀXØUt¬a|»“éÇñuvH!N#Ò¿·ıe€kê—K¶Éé)kìÊü¡¾œtO*#vŒÍ˜°æökÇ¾ßÜÿ‘÷fõPƒÄQ09à2™Ûj,Ëøı${_İÑ¸/(Pz>í°ËŸ·Ä—}6-@, °:Z<+²~7ßõb‹Cc…<ÀchÇ–[#NöñU]ûŠ²´üóÀTv“·ıµ·’›>pçºã@ µŞ-†”¸ôÖ[rÅĞÖº·ÌïÍ8.‹‹jÃû>‡¿äø!BF-ZB G_šÜ»ö'ŸTcvĞÀnÛÖf¹bqx›Æ|7EÔ¡/€‚dy‹‰Î#) MtuÁ¬!CââËø=>ì¥‡ÿ±P½ñ«4µÄÈ\å¡j¯ÀÙke´C× —ãMĞÁkŒıNjhø€ß1Á_Cğ©K‰ô¦³ı<"íGàA‰˜ü²ËüihC®´Š–ÊÚßën _ôŞ#b)Q•*y9cøñš{:”€^¿±ÎX;eãÎ:y®©©ßQ^;´…C`8D»­ò§Ñ?Tà"¶İğR¶¾ˆVT7 ³Ñ²0é¤‚ãu )Ûê{'tt»ˆ8ÖWÅj=P¯¤\Ijhu½wWÿ&Y7kâí)q©¢¶²D(ç÷K”ƒáÄÈÿ÷Ê€™÷ÖœÌÓÿéuæ:…ğ×eIQÁ)Ş·¾ÕHŸ‰ŒÜ5*Wù$ÙØ6¹U²Ã™Ö!,šÀ"q4Ş½Ï$_öñ	®Ÿ¼fÿï»&EvşúS«Ş<Ã×\ı4¿ ¡!ÎÊ[ôpÒë¶ûó@'±*äÉ•rĞ>Ã~MšüC¼~cÕRŸ¨fÆÏíJ1³zdÇÔµ­"=öøjVºÁ/õw‚êo*±KĞdWŒÚLù3¥}|´WJN+\dÊ!xÁ['ş¿y@B&A+ùš¥c8&¾ ^m?gŸÉÙa½œ&Z4„8¾Q ©Ö«ÈÀ¬­œ	Ï:+Í5vÈ‰cvDLÚCU>“ c$`İÊ”ü»®7$æ—kÏ8¬»â	ûRù€£‚©üÜ/˜úIàMBÎ¬ÈtÆ/¶Ì”}´ªÛyY'û¥1ì(]–âùâ³ç²‹	K®û¯Çò„{…Gº‹{N`ÒéwxPz†«Ì&
öÄoùŠNá‚ÿˆsW“oƒGt¡wlÂ
®oäK©sQOµfÃ¨Üõæ¡‹»ÇïğÀq`3®oŠ,ü1®İQm#³ÕûN<^}Õ°¤×SÖşZùŒT?®îú—‹—~3ËÿU.	º§s/°VÕ)¿K¡ùR*Ïò÷b–¡ò
á”5Í>Á´…î%<Şù$T¶‚§]5ÊÉ±e(1È.¿ÒI¶YÈÁ¶˜XgÑ!FMZ²Lèº&$],föè¸	ˆ¼RAña:¤‹wpÎi»EÌ7(÷ÀS½U¶8A›bÛòÁµÎ÷`(¥X8o®¿ã¤
A•Bx’UäÍF›Ó¯1>«ˆÀ) Š¿¾â=BN¦²šÊÉÊC[¥¹u~gíw«n !zVè³ÜÈ"_JJÄ	v¹Vc:nš×ŸZ‚‚±°SƒÄ§ïˆwü ‹‡1VGÚ€e€]³“ƒxBCÕl„RhNãåG†,ä	w·ê5(Ç ¶ ğ=-oÜ÷YûZıf‚Ó]‰ËJ¨1šÿm8Æè,_ ¨É®9.qC]	f6æ½f´[N—ëÖ”Ó?İ~®ŸÊş/QÁwc¢bôÈ‹ŞHÇø-å—76t¤UŠtŒAQ	ö&îy¹sXW5íßm”­ÊúË¿Ú‰úÍ¨x0–Æş1ÑÁJ5æL1à_Ç¯òLĞÊƒdôµÖßCš¸Uf4½ä*ê3.òé£Ô9Ñ×‡M.ùÿGîªú“–6%|‘ÓİoçÓU9ïX?7±¢§‡ßíOo.3fCû“rªHéƒlXl)¨)‰×>©êŒ	êCÇi3ˆ?Èf€;ÍÆÑ—ø¼ïCİbÙbs°ˆMèp3ƒªÖDuÙÜvÍ–ÏJ›Ï.p0Â!ƒUvÇÍÃÇcëĞ>2âOÇëO]Ë7•Yy3pIr:gÌS±Cøü^C
¾=vÚşşB¨ìÃ1Êt­Ò•rš	šÃ¤/D&è–ôµ–êQäYµíC×“É6§8lJ#àQpò…á2Œ·ÅŸ–Ü~çi¡¬RÛÙœUZ¸ÅĞä¶œ\Öa²tÍÅ×İ¹W@èİÅ½ñ>ÚMåŒ…%ÖıY=Ù7™ûiŸÓq2îã£B u“ÜƒÍ¡"Äß½ˆ	!ígæZ³²šı9ÄãİüãVÓB7ó/5Xù ©Jù´£ô;½±PÃe
n_dU,áÁíîãte¶‡)ÈôÖJÅSK4Â ±'e·èñ©OH°¼×¯Ò›±Ï?U”çÄö”D^SB•ŒİAWL®œ°rqèÕyÂLG:ˆ•ïU¶¿—pè,³øé–meú±H«•ˆÿ„ıœå\g3°xéí=½›»ûjÒFä“Md¯äH>——Ûqœ
)hl,C*A{Dé°Ô-7.üoNZ
U5Õi;3)ÍFºNfüOÿ]X8¿À´b¤öŠ•Œcğ%¢)˜pH–Ì• 6Kî7ÉL†F&¼»­7QÒÛî KTdéÚ(iµ±Á 	£›p¹,Ã[m\’È3l›]¦“õú&ŸímLì¸ª9”º«O,-»ËTÙ¶Î/±Á N?S!¥ÒØ²¹š&¹–ÎÃ—Ôîşe[l½£‡IK¦³ü”'¢Š•Æ/'ÔîÙg6šÍ¼«Y;ªô÷2;¶R7·‘¹œ(ğaw$BJ¸ÇéôÚ/˜<ì¨ÂpÖèP‚6¼ßêµ_Ö_ÜEı^·ÓuæPçÜó^¯˜C.dÃWß­É>=ç“°»49{œ)‚˜BR•r¯’OqÂn7êdüùÓœXGä¢Ù•r[mâHND rP¹NÛ:°Ë¼VA”=pDì©W†Ëâ*
^zˆk0©ºîåû»ºßŸ¢YR ÷p?s“À-®Ó ¡ ©ôÿj»-ÕÉÍ·bvR‘öç'ºÛaÄ-·†ä„,,Oö¦88Æš"ì½oÏÛØİ…)4#Uºú‘ñ>ã:o$ı¹“@6¨ÉG¬lş:Š\r©À"Ğ ×»Æ‚óŒÛk”+º,\·nëomÙŸ×í=üqbñ©Ì¡×-”œzlkÃ^ÂEúkûX7:‚”ñ}ã™VçH6‚&´E¼“1Ã2Ş j)üu¸`Éäâ4ûêáÃ‹® y¶±ªY]óší•a8øPU]NáŞ”á¿¶è)p¢8ÂŞÿğî¿šô?å•ÎšFh¬
VB¯Ñ{*{¼"qÁ™ôé’¨mm€‘ğ–ä  LƒŞ%“¼ÚÊíí['9’?‡4ÛîhZ'U²öéE³}ò0ÎóöYÓÜühÙš‰‘éRxNkI± sç6‹;ì/ ô~8/f]š¬+ª±(î=ÍLå…éŠ~Qœ_%´+è£²LR¦÷å?‚s§LÂ‚RÙÚ¿áÔVu3b–Ÿ;Ù~ExOTUşÊ†¯:Oóx»)Ëâ©Şı®Úh»Nv”Aåi‹±¤ebG`ûBp8¶Ñ£EáÂv—&2'´qÃ–_e6¦h3æ±âDÆÇ£VŠ½6ÛRbÚ·Ñ~hç±ÓüÿXÄüì×ÕùÈÈ"R@mh\à'IkRf¥¯Ûm^†±ÀrÂ«‹‡ì;Û5„ã|½‹Ë!^-T¦;Ç³7±¹ğK{^kRí›èÍk³yL@Z¬ŞÚóóğš µ¢›ºôåš0;ä¤MjŞ ÇïKÍ#i`b¦$ğ¥j÷ÉõèÑò÷m»á£íÅÛŞ¤c7”ğ)²p¤¬!f<ÓÜÈsìüQ°ï›L^ÑÒ‰†{7­áË3×v¿äOÿ6m¤{ˆËs’éÙÛ‹\ğ£¯Å“â¯¼MMTŒ5ŞşÇÜ^&5ä›	áqÌñz cåPrôÿLOŠìV›¿ÿ¶}¬@íç‚çç%MttüUF˜Î\È”£]±Çdy¤§\x´zÕz¦=LıÁäû<=Í°¥K€¸½÷¡„^zÏ»”uÜ"[ÔP¡~0²47!Ó)Æ¤R5_Ş³©üh¬_v@aIqrkLŞ—D÷½FHQ‰÷ó	¬YKšÓÊ(LãW‚ì³ø™™(¥†HÉgî‹ïRæ® åğw<YÎŸ¶É[>BÖRˆ+î¥Y8„ønÙ½øÄ!©w”d$ "|J–ãÒİL²ñ‘)12D–9HO#fsj
‹\DT„‡û.•æ1Àç{¬„±È	Y?î×"u‹v\`ƒı¶jy ÔİIU³è™s§ ¼Ë¼€æ—Öâşúf+sÎFg
¦?…ùHÓ©D¬×©àD)~ÑQ’ìg‘âÔ-OnZVù!hŠíÄÇ3Qúnx\~™=Õ]Ï",üŸ¸{ø\Å¼ı£ÌàÛÛCÒ|3–„cŸ{F«Ë?Ãı¶4ĞH3·¤`•r¥‘kóz|¶/(W
?{T!ërªfVuëó˜h~®´ÊÚj V8İ~òÔòdîêÉ;ú¤•ÎîØÄ¶šƒ²œ9#š_{Ø7KA.c)»·ÌÂ0„ß‘m¦˜Å–†Xmdï/‹${ä¬Î±›½¨KOcéğ“;Ìœìô’LÛÜÅÒ€ÁİC6 Ö íµ@Ö¯Ê`?dL€ïæ!vq‘\.åÚvc­%B…5¶y'­RßI>äd1i7;Mäzéµ‚ëjzÀ¥²Ëğ»Cğ’£Á ¤£J:/––¾c„ÅÎbÜØOTØˆî1Yi{ª(R¡`¥—ÌíN”¹aÿgv	0¥™¢é³fiÄ<=(öDdŠqë5ñ4©³¥B)ğóbKy+çêhZE¥˜”e¦m'‚"‚Xã¤bpÀŸ›p¢›å]Óú0- äWÍàiºöñ¸>ã¥·ñwŸ`â·K›‹fp'˜¢#¦¨¤U%¤¬1UÂûpXòH]OÆZRyùÙXŠ´µ¦çùéª_ß 3Îø—}Ş2lk<–ÉâuÅ	°m¸´ÊÁ²–ˆî8“ç×?6ÿÇMtÿ?pØıP# w1ÕˆgfAòó„õÁ—Ò!u”3x`iÊUÿdEú»DV<¸têoff;•Öt~—ë«¡èHü½rú÷Ïi­7³ÄÍ±ö¢¬ €'Ù+Q7ı.¦çKixA¯ÓáZPk(=_·BvF­Îøú|’Ş­H³pú«`qˆA]“ƒ‘{)¢ÚRñWÖ…Ã[UV!géz(†HJ+–õ€·Aê€£f›WLˆš°ŞPÔ5vz&D€›8dô5hä·ÎÄ$€XÜğG­™ğbï¯öx¡ˆChFI¤KÉ}ö,¸4¦"›Ä)ëãPúŠÁàü´
l«bZh„å?%€(´qêu!„v¿M‹1F‹¬lQıçjë™*¿ˆ2RóÃJÚñbRı&ÛKoˆ¯â[·îõu‡¸lÔX²~´Ù6“fiK}ès^µ‡âJOjo e™«±%Çùçï«fğÙ¥… º6ñ Ú¥˜hD£6î“•k>”–jóµö@3ÚÒ$ W’ÿ?<S=Ú¾‡ÇvJ!M‡Ô…q_0¥Éü×ßò…U$ëdŞ0Ú3Ğ’¦#İ`‹Trù­7Å¶kqQ‡TñŸ¥t¢FƒSnÓŠˆl­Álj/3,7ŒÃ¦šâg¥±x]VkãXÈÕ oÆ—`ï©i¼eÏºœl26êX‡M.ôø˜å¤‹2Üøoû‡[ÆÊŸU*@H^?Å×•” £;V=#ºH pösáˆ¹Tq%D½æ°¢|‹õ·…ÄtÚç‡ú¡Bé€î;å:òôB ÊÅ¸¼Äc÷Œ‹…Â+'|ƒÆf²r÷zõ<+¥ÁçN"‚Z/©~Üc~<Á%Eà²Ç’~‚Å·´UÜJ$à7¬G0»´e`¢,íÕ¿î=¹6Ü&­`ß^m	ÚÑª €J©FÀÏõ0¡¦P†|«W!Úf×ÜÄò•B0-¸¨?å\oK¸ôÀbï¾òVC8~•Õ6eÆJD­J[o¡õÌiuº˜|˜„›\Iˆµºb9ûf¨Â&Hc°V|3èª´;œcGƒsÃ½õ?òˆKÃİ±!75WË‚¡—Q|dìºƒı?Ow˜Æ¶‘9YÔHãéOØ½}ø#‡·/D³.")á|J™2.7ÄFi~I_û#µ–<Õ½á öôŠn›¢uğM’>qéòjS×’1ûb;÷b&¶ŒIb¯ßn­éØïÙ.Ş»ì~$> ¤Ñ×æ)Í€äÖHçÖu—"‘¶<‡^û½ÃşG1öø*vò«/Ş,3}¢ae›'GdÔ@bƒÈÅn wÎRJv`Í7İdÕÊKŸ«?¨JâğûÌä7(!éø{eË¢wÔ-ÎØğ}b“ÕíwÇ”…µ7¦XÁbå éSåŠüP´1úwÑ©­
oÏ‰’´ÈáñßøzÑ›„Ü­šMõlµ‹]ú|L [×ñùrN8mİĞåûóQ†*UR¼q¨«µÊğœŸ#38¦d¿öv\<2d2‚ü€§N8õ÷Öº–lXİáÁ±ú¶ˆÛÀH¬06Ó:Æ$Ï0_‘İ‡æå¤°²Û
%Ôğ©ß— @cHí­šKA8YO¿z`jÖ‹EÕÑÄ<£I”L¦¬º÷6¿d¶›Ìc™¤dMõirE zyçL¦Ìbû`t
ÜLykÕyCÉ•²4•nB{ W0=ÅÏ×lV6Îyß
Ÿ,Q)Qg*=şÔ:®ãæ;Ø¡ßmR÷/KÕ’šaj"\Ï@f€–«ƒ*8O° fÎg$şiÅacÎæ–.kmd&´ö:©Q®Åej´Zµ¿ÿÈ 6gjK”™9ÔÓŸ´÷}L&æFnıæC]p²üE®©€.kNÿÄy“ğ¡JF£$–ÕRs²sBBŠy8ÄØ4zìr´î†4:ÖK¶„¢"=ºDÒ‡ëÄ6ÆGÜ<¦˜.ÅuûF¯}Ùk°ï…¢C3.ó¿²¼˜EaNö”¼h›L³Är9ûğ¾XŸ5g÷”×$—¢„±ŠP™6c3÷lê8´#™b-(œ›ßd9ñì2ÃCåp‡ÇZ*»Y†Aéè®WOĞ‡ÕDÊg´;‡^É×,¹·jï$üûã·ÊçÓãëÔ§|Şš0ô:ÎtĞÚ%áÕ·1¯°2¼¡ıLN0Ár›œmMW-ka ò#§'¥În­1½ÛR„€²z	¢ê‘;|&Y<|r·±•"™ñ¡p¸Ş=ã–“£×âÊl6ñãÔ‡°oñùdıàçÁ„ym. nC+D“€}²G=–^WÖÆ\§86Z/ÂÈ,÷èü+“6i½bŞ`8ë ê7X"‚ÑhóÚ(Ü±%ıYk»¼Æ•øŒŠÜ#·Ò¦ÉgÊäÆ€jˆ³”¬~ÑyÍ—wÑ
:“ÍôC>ã2Ù÷(A‡æ»°¿N
[üVOnÈ´l®]ñıl¶eh4o]‚HÈQwKHcm´;Ú¢§SDş8—)sHÎ]àö=9X‘4¹`}±Øwñóµ+’©³ŠÑâ|µQ_y]3Àğ¿xİè<¯ØæÀ\¾£ª‚‹×8¿µñ1{WğV©©§&ğŠ2¢$	NÅë>« ,¶´jó¢Cw®"Li['ácg³Aˆ´ıšÍG!È<>Ğ¤ùş(‘”öW®<¼Œ¿^ºœ^ÍµFnVÅ™ùE~Ow¬ç‡ŞÖiò4íòşt&W!ÙS–„Æ· °˜=qŠc¼zliŠPˆPòÁoŒ û¤PgÎM”IßPê ıi‰C…™ŒK:Ÿ'¹ŞÆ¼¨_üÁùFò0Áoz4åå‰WA¯‡©jmîlw¯ñ(®Pˆ.? ¡M"¶†E‘ü “˜æ–JäÒ÷Ê¡§k´éX+‘bq‚-Öß”‰Ğy^Á“`9B§÷¹Èa—¯4Y`
¢æ»³EÚô7¹Í€ºƒÿäKá±zO3qÔÌèÄ>ï¶U=»¨°BœÈ¦¤	D;{¬ÃmÉ«kU	"%mÈßÕçh‰áÆ±®MŞ+ç:Fböñ)h'îå(Ùs±ûÄiÚ›¥-Zæ[¡ÊFBèV—ï7Ü×z}Ÿçq7D™ÎÛ¸=T½c"«ÅJÍôé˜[ğzŸ}H\8*æèÈâ-ş]—ÊrÂoç
wíªÑ
`mø“äÑ²ÀQz±Å…uTZ¢ÑHF]6c÷)\U©	öüjb¥JS?ãüc¬3PÄ—ñ—V˜³|¦jä†ÖCO§¾ååäRtjÛè¼ÿE 2•Š”D°œö£/xôèÉB²ÉáHá6{L<E«ıDw>\CÚ:ìòk’ª2såƒg~ˆ»óVÄé‘ĞÖu°k‹ÖãCÔÙ§­@Àaö&‚v@)üö"ê;bø'"¨¬^Zİv—Õ¿š‹‡½©Y+báxÏñÖpÉ¾… \ãÂ.µ¨ó'&ˆGVâÛMw]MR“¡nWNIÆ‹ÒåĞ ]LŠ‰¦w8¡"•Vİ= ›
áí†/”cp7¸	„öL<oÚÈZ ßNi)^Ş
÷UÈ­Iˆ!"ñ>¤ÌôÄö¯™@Øí÷Tb-4©)d^&©ÏÓ¡™]·µ™9¬&yÄˆ4+xp¹ğ]gu—¸Z'æ‚
˜ÄHŞXp\ç-8AJŞ _l¡ô$B/ÇöÌ°ÔÏÔ_¢& (ï×™­¬ 1Kc>æ¥p_é/\#¾Œ	´£E'(Õæ’~wÁ_Y[Ù™çWnJõûŒSYV¯®´•#%jg´ĞÂ«¡“4¨ß¨¦dEÿ,I\~“Ğ–åÖºÇ‹–zdqÊŞaÁ?·–Ïë,qywcõ£óûjt‚>ÁŠ¦¥…İ±IWsı]v¯øò9 — ­_Iº|- 2¿›«£ûu5•e¾ëx,±¶‚‘o})Ì Üop°~rbm`ô{vers#„M2ê^Â2,ƒÅ¹Xıî\O‘É´‚6…&²F…UÄÂ¹Îæş"‚}yNœC¹—°œË]Ÿõm°€vTs¥@­ÖÌZB!?°5¤ß$yvVCéßYØœlãôÔßcİHÅÀ³Åi°Š³GÚ³F“@”9:ŒÓ²CHH•6ÏĞ™w›Èú"õË€ëz°)]û+Xt¯1,M-.ğ¿öøæ³LT	ø¿,¡ø––ª•ÚÄ¾Ô¼ˆT\ƒ¨}Å,j®‹¨~ínwÊû¸Ã¼™¨K>SÛA¾4¨òßö@(0§©+_,™úÊ R—¨–nª5ÊùStó‹â1gÀ‰'%æïƒcaµyõ*8”.—œk¿ox"ƒÜ–¥[N0‰õä¸®9î³Ê}Ü\H‡¤l³~ÅÖ‰7³³ÍÄ.S•ÏY—^l|SänáÁ4¹’]g÷d£6¨ëŞ…×K€GVª]ïãÂJè¹MXØ‘ıÒ7Ç’4ÒT’¸µe1ÒäâôıÇUù//f˜y¾£jæ…¢
,vfÙúÛĞ‡{ÑÃVT—¨jàHèaÁß¸<ÊÒ[M±İı5VÖìkÀi¹òXLL	;¶¹|$#QQR_zµòÙÑ‹ø5c¯•~ÀÆ¥îızæ³ä^/›U§f·„JbBÓ•ÈúW|«Íÿ=‰ş]p/ˆù½»ò ØÒõKd¢·Bç©ÜTkß&§aûé‘#«Ñ˜]#IıÏøı7£Õ‰g»iÓÚ¸Š|]$8íÃÑ~÷öSÎlY¾Û]ujÜÅèÔl¬±¯q²d’5mCüÍ§‘öï^ítM¤ÊNç#­ıú@`c¦+ş B	ªO¤¾e	E–ûbºwÜ°,°êÈ=¹†‚TÍúÑUÉ0än¯BÑ,¹‡w_¸=):pÈ“"S nš#©âêìPÌ¥…)Æ}Òí¶ÿİ^/¶yÖğc LµkÅs”íXÚêÖ@„ıÉ¢î’˜“ìZ]r%Ë°Ú‹ºô)®†X]]úù‚EùÇ«FQJ˜êä."Œõ¯·}yö’šoiˆ„c3mÉ«á1­|¦NŒÎB¼ú ıÇnÇŠËÄ\IFü‚Ğ®Ìµgå­¥ô#Ùªãµi°a7EEc^3è ŞÊ,…åk·ŒÙ–öh7â¤»{eç³Ç†¢ÑT„Ò†3p(ŠJ$öøjŒ°¤E¬‡åºav‹‘M}+{)·¥; ÔRÍ,5qg| 9ğdd0š¡g‡½Ú]J	v|±Í¬†F‘`Êì ©ØwAÍ@ğÆ¾cÿ“WÑ§¹qDZ<=ô€ƒyGš“·'§CfĞ—UThÃ«æ–Üö“€ó©è¢J­²
Åƒ˜Ï‚mšR¦ZÁÿÔö®w­ú 3¥‹1ÄİÍÇĞÿ\°˜ŠÖé8Ş£(Ğ8’ûË—÷¸VÙæ5Ã¦]Eû Şü(®…0¡Ñ9_RœDnŒLÂRİg‰w	+ÉÊì½¸÷Y¹J%œÏ4˜¨%ÄÌA ‘µx˜¶W©T¥?µû¨›}'I¬ìÖdjÈj¦P´”\–¹GX2«3L¼jZ'İ ]ü3&ükr¨Ä#ü+BÚ/¦»0Ê†'t2ßÆ×€1wá c;„uL‹ø=Ñô‹ôâáA”›n9£ñªß¡O*ã•QĞ3Åo#ş¶
¡ª¼òÓâí¾=Ì:¸êÆml+ŠÌrÉ*FÀÃ
®,µ‡'ë˜ÙNÆOÓOï><„×zås[‡¡ı_)U2E§ã‘L²IEp¿¶g>ıS¥mì! ´~·u—M=Qõ‚’/v=1P0Ta|ümÒÛ{ÆM£¸!UAvóBıU§˜_IÓuŞr£eñìŠV¬öUò‡ûÁ—×á·ËœòÒÅ›cˆË‹Ğçö©fV¥E¼3›O°AB¡ÛèGfâÃHv³rœxM.H;z´ÒÏZì}øÖXª?B„H‡VûİÀ¾°Ò›rÂÒİ®³ï“¬§ô¹4ñ–Ò9œXİÃ<iì4?~ØTŒM$5ó0äiuÓÒ„Â¼E»ÕJÜÿxñ2M%%L¤CZ´„MQw´‚+Xl…­¹SW‹õ;m¸s*x$•,Ú³ù²%ˆÃ<ùâ˜É­£7v”Hø¥T½Fø_iğCµ¸Èäª•³²h
Ë¦-Epî,tfèaOÿ´²j1ühî!Ô\W·‹_ß\ÕbŸtD»³ÉÀ©Ÿlø?qÅYóÓo1z5@áÌvT„"®±~a!]°™FöÙ±f öüJÜÅzF”bˆh…½ı+†íqqH´ü¾u|Tøğ6JØ,¬(%’7äwRÆ¨Šï!æ‡Í*$ÀÔ±u7+Å2®h_ÓdÇooCTíÊL­gˆh=£	\ËRÿªº7&AP$æ¡Aìëô! ×–Oà-ÿwü^şƒX¤õ[fÌ€ƒÎ ¿r|
ìwUíFdÀá¢Ö¢CPwÊèjÿÕl aèrıÃ.Ş9˜g›ş“…”ß›$bm,Dt&"$s´&’”ÛôÀ&µ6#a	—÷_İ€€Sh%8%ãZ#İÇ–·‚©~ÃV®8,ôÏî´Ã«¦äm@T õ–~‰„„œ[b[ç—Cßkñ†¸“Ëg38ÚĞ°R˜"Tû”w¹¡·	ŒïOB¨ÿähe¤â_œÎØ”òéÍ÷Áuº^tÇŸp4>/Ë²Tu•„Á"FhÒ®—ù_3(¹Ó¬Õ¢¿ôŸ&­oı
ÃÅ“æõ‹¾áƒ‘@Ñt4)®
êÄK×ÆÑI¥zéB¨2²¦]û´ƒÁñÆV²±¥x…n‡Äôx‹dÕøFàvE½”Qfü¨
Æ	²öò«µ—¢úrQ dwöÓ&0—d¶š~¶.wˆpÖ¼A,5áÒ)5ĞHaˆóÕÎ9MÙŞ$²=7M½K½¼(Ã1³püÖš,Pî†<ÿÎ‚¥Æ´ÄAñŠ‹}ÓÎş,F©êe–¸‚ê¨ÈÄlÈ6gt‹ŞG5Œ¢1¢Ì^¹=e	œ²zÒ#QrùHÛÿİ³gîNF£ö]y]&=© ôIn?1ég‘ü4èë†™Ìç=Ô¸2w•eÏm r"‰ˆá÷¦³h“æ0ÿOÃ/{4zöc,éÄ=…Y£ĞhRò€£ÇãVN,Ââ¼)„€›ôÑpn)j©A¼©Tõ0¹ˆÔ”[”ĞÔÖäş}ÄPœàÿ¬¬;×¥ÿ…ĞšØñXëB™ÀËëæ1)´»‡}çôy”E+ŞY·­’«¸ğyDx¾ L@6‡Œ>=:25WÖÓd:mh¤òâl'foÀp^öP’óíóÄüdÉxùñÿ‚ªåâ0eš•ĞğàÓFKÊØ-¾vÏÌ{â;íæt˜Y^öo	Hkì¦};'¶€Zâ£|¼et’Lç¾ şy@ kB\Ì[ì/&!îôÆHê©ç	*QŒë¯8¨ÖÏÔ^çóûãñgÑç#‡«Æ–º2„Õv!‹û€¶+Dï)<âïB­ÔÏ3{Hƒ:¶XVwSœNO]’U¤°+§=€IGcû°VFÚ5˜‘Á¢gPv b‰c*,
\¬.hF}à	NØ.­HĞÆˆk*5^g šI-Ì‰ä08Kr¿„Yär‰®ÚÛ5ªA’+›Dù7*—9¨GFé†°*‡kìL©Ç³¹ßkz™‹õ´ƒKÔ SÈ~uÊíëÏ÷ÁHÜş~×i´çäÄ©øşÄÿ-òº½"ÖÜ<ŞzèdÃ#³p÷Ü€±r,9…7â–ÉÊ,”l¬R¸SXÀ%Æñ™äßh@r‰å‚Şyg×6å(Õ‡ºô«GÃµÿ´¿ÎşÁJ:;WWƒfüã@š¬PYöô×ÑRÈÚn>Á´êiŒâ¦ùú'È‰y¥Ûã¡Ñß
´!ÆunŞ=AQrmÃ-Ê
 ¬ìsÓ=úÓt=³Wâ/Ôr½ø…‡Nö-¬ ƒÜ¢{j•Çg¢¿(u:„@ˆ6Á Ğ°sÄl^b;	€xÅû¼;c®¬¯ÍFo¿ôk–Åaº¹ò.?—m2òL^®£Ùğ“ìaB(“uzrRC„ÍÉ^Í"bå<Î‹ø—ĞWb¢'í¤úO¥®—.`f©lÎë@µ"+Ë0Ãí­îNRˆb`KŞá#áyTÒ½yÙläÃ-Şi6
ìeƒTşàb@0ÿÕ“L EŒÁÆâõ
PââLƒ•à˜Æš£ü°PİQ{s|0Ÿ!Aûfõ®YI ¿$Ër¦ÚˆI®£‡r!¸}}’Ü3änµ5/—myKOçpáÇ¹MèÁĞÖGşšQ&vò2–åW~#è—•$¦0‘ûM¾‰‰o+Ø»æšÂö+è#ŞMÅÆ-œÂIR«‹(U?—X66\L|upÃ"sÍ~*™(44åê!l©IâsøOıMÔ(²Ô-ã4î|’SOpÕıä}‘¹'é,òçóFš<‚ˆ§â?ıŸi
ğ“N·U
–7sÄCe´ƒ[ødäf}!ªsB‘êöEnó¸ò«Ş¼¬n˜IÒºÌ[F|`_ÕbYŸø™L0ìØmV´‡ö/rµ«"ûDª1„R3ö®:”Ø·%óD_%v·hğÌßœg3õ˜cŒ]mZ®©E™óÂòŸ£)Ä¯N_ùÕH—¯J£][vúàxğ\e",r#¦Oä4:f»€N'•vå´Ùç¢YV„g\µ_z÷O8NìóÂ€õÌƒ¾r‚¤hæ©Y}¹V>\ê´¾óq™ßúBip‹„èäÕÚƒ¢ˆŸNô½HıH8”Ñv˜[“E¸çÆº}ãAq/7heÖ¥ÀFÊ²¹5½ÃÎ8	¬	:Ìš
ï5 «±FŸ¹„–ˆß®!ŞKÓÔap2ù÷!‘Ø[>ë¹Ì\.8@½²SŸ§h}AÀ@F×ô	’ë²WXBŒÀªç
Ú7Öø-)â¨ÂzQ`Ó%•Èt#j÷ÚÃà*cÑ³[V™ªİÑù€.=vË+eRôP'o¦V4É)5— ÆóV®VL<ÄW„'Ée¼Àhğ[ÓB…¦â/ÁDHn,Ç!?£O½†y/ä@Ì`÷÷Ñ½\íAe­m·¹3]²sÕ6çãĞØcşÇñ?­ àUR`CtLódR&xèıAkšë7Hwÿ›Ÿ¯6ä¾
©ƒÔjæ¨• WCõ%í£»íŸC‡^ã¡×î·ó£Aùu†è¶q %w…ç5ÏãÈ‘ÍugşèZø7>IÈğ¹g> ğ=RÅ"¬Ôé4Ÿ Lç|‰EäÚ	o²Ü_¨Ñş&Ks”¯Ë[Ÿ>—}{çon©ßËñµ€IYı–.»„CÛ4Ô;x!W»Í•áHnù‹÷œ§:ÍßÜ‹Ä D@:Y»e%¨¦	ÈñU7ä¤«—&ø[Ş@YiÇ˜@9Á›;Xjµ’¢òX³Üîô4|TÓà^°ŒJØ¤Ã3(oœÊö™ğÓİD—³O¦jéæu…d“W<¢8TÖ||ı°÷½fDHÅ´¼îˆ.œÌw¯;Şë²;P~HÇd‹àà¢—µ(jUÜ×Èä[İn¹‹lG÷DQIWxß“‘»R=ñĞVg@@]¿07Ğ«ØãK‡ªĞŒ£  yåî·dÏxåé}£ó³ğKì‹¾ICe£,a™•u¶MÏ©€BÖKQtWA}‘'Ïå1c¨N í±£Û0á"‰·ø¦Àøvz¢ZŒ¿Ë–?44Z-ZÇ[3¼X‡eèíyôªˆÈv(«µ>Âí¼`Îü}Åø½4±àB"†Úòe³•…]Aeq³DÛCÑ^ÓĞÛtô9R}Ú•ı÷(ÀùQá¼Éro~”D•Õ÷Âí
²3léJcÜÉöåVâ÷»b Á| l¤ªSwcÄcñÁ…':8Üš¡”…[C"˜İâ‰ä<«ôŠÒ¡á°H¼Ğ£z©´(RÜK¹Rv¢®l?ğ^q ÁÓs@±Ù›\(îíxñ')4 ŠŞ¥°ŞÆÌy’©‡v(æ)ı#„{Ù%¾I¡ĞĞtû÷¶•%>]Zlÿk4§g–Â&ãTyhÕZv»‚·ˆİ¢ÄµæA=ŒK,E£U¸ıqÕE(§¼2›ÆìÊØûC
Œ·a„ÜoDfİËD&æ#iI[}Ã¡H…39íÉ,Í±-vv“¿h·{IªXA@ş—/Qş9e²ù¬ò-Øó
-ÁÆŠãä3¹xaôùÅ?îE%¾6oòŸ1ØJã¿hJÏş^ìøš>O›ØCú¬ÂX¾Ù º6q·ñªåxNŸíÀy¿§¢!´Š¨mÂKSÇööº’	ÔvĞº	JD¡†M²{Ò i|®%´j[Ğ.ıŠ?5©Nù§¡ÙpÌà‹[¼åº‘*J£àR‘û¸€3²Z\Û&ÅÕ2Õ´'¹‚–Ñ>ë•¨Šƒ{A¹\›–´¯:"
Cë³-V@J»÷^V˜eİÁô4ÿN¼ÓIôeşÕ¬=
‘ºF=¢âLJ‰§<õı¾”„AöÊø¾¿æ)|KÇN“™xïş¿ÃêéÂ?œT“Ãv‹ F¦ÕM»aÇJÖÏşTg
 4õ“k£éØ(/,å7ÂİÚêi#çtàNÍóÏèçĞ¦÷>»´ TJìGÈ¬*lú¬«¢AÈ58n;•|6Şˆİi™çó®®açàÚóz¼‰ßgo[ú«tùµìd9«»Šqú4…OıIq,q7` —oêÑ{Ş…~~™ì¹-›ã/ğä[N²àÅÆêTpÇ9\•#¾ˆŞ†`­ÁFÆOV›ñGŞ´õ“üUÆ÷¹éÆ»³ƒ‚‚OÂ,ìˆEÅ°R”ÿHœld^Ğª¬fH ë)S9K³è3WS>¯Ûµ¼Z¹>o¥r,Ì(CÛhÈ°^% Ôm}ˆ>\Á¿Ô*(©ïuûÖªyŒQßQ2‘lÿXsrH*V¸š"Ş¼ì4Í3÷P×#À[ÄA›i×Á«ŠÚ@Ägq‹ã+2(Sí( 	¿¡uì8çÜÿiÅæ?,p<|Š²Ç0(e³
÷.êVÎ±±+%x¶‡ïà‚ãAMDªĞìB`ÿñZ­8qÃ•!¨îoöc¼÷C\}Ó† ²O{Š½£Û\¹Æ¢À‰aJø›š³2øàêwñ‹M|Ù>ùs Í¡snHuPçòĞVğñ7†±Û¾‚ú/Sò‘YP²ëI5³E¤«Z2—²!Môs¦}U²ÅmÉ5­Qyì›‚Á8ıÌh	º±ğÇÑ¯Ÿ§TT‰¹¥Ûñ™áö@¹
1'
n28Úó*Çö¿Nôª%£zµM+†Út:lŸU…ŸŞˆ!cª­o~Ô+o~ä&œ“@~c´eğ$¼1ÙÚì]]K	¯ä±ÿò:ÄÂ…Ş_b)£w°’IığV¬îrPN‘ÄÆQ‘n½õÖºëÀûÈb "°³H…-‚9«å€”Pìªğºbïêp“Â–tl‚&|Rš¿«=nšz7[ãñ®j`9ßİlŞÛQÑ¤>hôû4'†VÁÑ‚áUR={cŸÌ›}0 ª…ı\µ•äå¯_J3	Ë91 `¨ÛpŒ^™¼µš¢ã6ûõ†8GP‚ˆÇ“û>ûÑD3’Ì{ƒÅª5I(I*Ö¢ºx„‹`!)x°ïqI‡V4KQË;œ6ûŸºMi¤€\ë¼%ú?pzd¾ÍÜçûÚ_%oÈtv–»Û]Vğm›Ò§µË±Ş_kq^”é³İ%%;7¿Ü6Ë†DFŠûf·Óùû¥H.ïÕJqbTjMóxôÚ'Z/Ç}—+:¨´ÀMsGË÷ÜáJ`¨ºŸìÀÒ‹Lo"1¹â‚Õu’ Ü}Œ#ú±9Şz‹šànƒç¼K–‚ªâœïV¨™ÚÈh$B©kÎ³öM-*XĞİ’öÌ‘Ÿ†ùwµ’)ÌŒpâ,»ü¹;Âe.]!Ç9sÀCZNïOİÅ·;É¨ä€¥Òùy´.QÏnójø&2¼j®¸%îÛ²ıA&Q5§¿N}vÅtE›-§T®	¸²nÃ9FQ½¡ìD‚'Òg’bGÄj%Z|ìz¢»’aë>’E,#§™ÑÄèÖ„Ş]*ô ~XO‚Í‹—Œ)#’?)§5V±áˆPü3N­ÿ§%„õ¡ ÅÎ¹óİŒîù–8X—€ÜSŸÿÑÇ9ßµ)”SPÇTÌêÜ<æ$kd  GÆÜïŸ9ê)ó½'j.„¨U—=~zîÊO¨ú9Ç©.åŸ¿X•ËŸÂ¯Âë-Gk¢À×õİX	‘n"ÈNl–Ë
ÍÇ©¢eóÎRÕ#“–>ö tşäé÷ ã{)ÁLı”n8@KÄ.¢BóéÕ¾äìĞ¶¹Ût\²š.@ÖÍH4˜ï¯ÕaÙ;°À­'i{)4kH”¤öP·‹ß>-ìÑ™7gÇS°lÉ,mÂÕo``ã·„bBIÁ¼ğ	Oå
g_Z©È†1Ü‚M†7‰³Ø¥É>M9×L;ÌúÄí‹ÅÜ­•ŒS¬+l~N?Jş0Uø½½ºh,}– 	ŒÀâNÑuïœCŠûA$ÊîĞ¼´ãÒÑÙ!~ßÃ¿z‘‰æÈLÅ4Ş±æÌ|€;/õ3íXrôËöd4êèŒêTZÔöMÄ%À:póo×¡DĞƒßsËç=ş^Sª6å«µİ2)= (*J§šxŠ¼×A :TZ÷¯Óò„ñâDµ?cL®¯C$ªê9m‡“j†ëR6Ï˜sşnæ8ww>0.XÒßÙ¤•a›ş…Ê PX¤õxÅÿÒáIİœ…ûVUú.¿mã#ç`²ê"ïO<àX·±tšãzëS066<ßPG!W¥òGj¸m·;ŒuYİË/ñ¬£F+µ¯à;_ltà',É/‹ãlè^jQ ÊàÌ®qÖ½#‡)¿
t{é‰sÃ¯€LšÓòêjİÃ™*NØ¤a¥„Ğşk¶ÚØ*Æ0üÒ3î“iåÆò¢2¡£¤¦BÅó@ƒò Ôr¼ñğ9{PÑõ€v*ÙfAUaÈ6ÍšÕfk‰ Òõ/š"î£-êú>· ×PŸâüvš´o'"‘kMBü£daé7£¡$M9I¾Ğ¦>cîçP_ÎVU³ÀÖu?åfH;·%ã4!R­0®¦ÄÆùºå°š¼ÏMÄdKÓx%ïŞXWt‰cØĞ‹ˆ½ªkÛÍÊuÒê˜êÜ—û¶İçÅ¦Noö+´ïÏáQ'3
‚3¬Û Ÿo¿/W¾ôoŠ–E@vÕ=\YD%W¥ 3õĞh‚ÓkÔøfÚa\àïÆ»êì1ürÏ¸ZQOİÊYì\7’\óÙşò’QrºÈpàläBhğ±Øäqc¨Zc»ğ®¤–ägÓ<2ßãT¿oîm*+a¬yÇ+¤‰Äü¥<#€ Ï×a}ºªC€ëÕ¼rläæRMİÜdİ‹ d.¯}³qÎ‘Ù®—]*ĞOõïr.ôphë¢)àŸÙß÷b…Xü‰SdBÕ!'^®Ù$nédÎnÍHublfÆv2Ù:Ï×À`„iˆêLÚjÅ•ŒõhCÃğIn×fnz‹)ô÷»#ò³°á¢yLÙ~Ñ‚‚_5»©ø‚¼pg¥uy“_f–iöÚÌÀºM« Î}/ğ’ÛpNx>5gõ=Œ)z=P¹²¢Áu—¾”>øv³ùŞ—‰ÏÅÜ«·¬äÑBhá¯aXÉüGavv¢&g×ªªÉ¯>Æ#+‘Æäá”×âÑjB©×!üfx~b°< ~.GÖª}–?†äƒCˆ„z›Gà3N¦ë}­¼ ›SÅ²f[¿JîT¯-îÁ{½ƒÿ…<óŸ8yd}xÏhŞqw4!Ÿmñ^Ó>Ï–¬…©2-5ü(‚;Éƒ÷ääPUÃdŠí\=g/25Ã÷‡›ï¯/ôqjkòâ¾(¥yï…{£ªiÁzìcâgº¹a6³+óòì r¢4mâÍ¶Ët¨¹ôíÜ_sXõ€eRWªı¶ë<TÛà¯ YB¶Áê@OË.½æ¿‰à“Œo_29},Êp1ÛõM À’KÉ|VuxkSPl¼D¡s|M+¨q¤#¿yâ“xÉäÃáõXë:cy	dQ<aVdºù‡­É€…m5íÌâiD¯cc3ğ’€ı æ‰£Àº*]@Ã™B4
9?;ï°Y}0›ª“‚&"ËYÿãÈíÀÔ|ê£M*‹»é‰+Õ­|Œø/l_l¾çõ‚DqáÜêáÌ¾Wë¥ßF‹ƒï™¥!ÌWí¬z¶$t~}ñ¾f~÷öUíÛ€EÚªo9Ëk€¥ Xü¾aÔ™?O~ãdØJÀœ)#QQ7—r¤™ãA-»$êÕ¾–Lõ‘àí5ñ™›5}Çàj{#´L.Ã¦fiÏdÑ–¿÷Õ"’ÍWrCí+ 8SÅ…I¡ô«äÌ çK–¹û(#/w(³scrÖry†>Ä]—xîğnÉœ:àî)$X:v:š™ JuªÄÅ3‘¤ngòõ1
úsã?ğó
q­ E‹vsbÖL/y¦FÒg˜{+ƒ•‚˜ñ Ù¡¹p@zm‘ÏçÂb×¾?ÃSaä“¨‰£vŞ×FAŞ"ò.|È8ãÂ[ıÈòõ]-úvH8CgdA¯fæá*Ø½
…Õ š?ê>ëqN¬fÅà6½Ë4g)æš$Wü‚kq
SP ukôöm÷JC–]K‹¾^8°#»yóÑnÓÇ³î	£MÕ.±1-ŞıÖÃö¶#P¡ß: Õ×üLê>Êv›\FM¾ĞXqjÍzc92u½UF°SS€öYşÊ(ƒX“ß%yä¹Âfİ6”….rtG¸:¿Á•VOË`ØDªíF£J®^>à^‹…ñÊĞ¿Öı}«Åà|c‚ßL,5Î2Á´€~óYğÚ=2\œÒ¼ñ]é‡‚4ŞòÏ¯~¬¸”Î’©Óï›±óm"%(?Üı¯Ş)nÛûØíó )zú!òRo˜mŒÅq‘ršğãàJo¹0Ú+|…Ã”¾b„®¦ä§±Ç…a}¼t¸şIÈı8Eò3Š?ä¤‚¥ĞO(‘Ö³¡7bQ­,2
­ÌU¥«’jmxÕ}¯À^Õê`zw;Ï»Ø|;%&re…?UA'm^r¾â·êofQ	Ddàk„|Šûs"'å¤7Ñşâ?”]š×U•TÄæAQ´g”®ú%rR¥f~Nt ßZŸÌp\h¿fCø.ÄxFLİ$¬vÕWGù ¿Û­;{#ı0[¦Wº$L¸·	ªÎb³^y—Ä'G–c!»ËFM4g¢½¸	;vø°‘gm´ªQGØQ3Jl+#µñØr[+­Xœ=™‹¢PÓ7°E™:`LÉkÔÃM©6;îueB²:-X‚ë9 ÿ`2èP^¨ˆ°—4“¤ˆˆ`â·gÉ˜Ô%§€qwVÚ< C=×ZpMò:\Ô¡¸Â)¬Ç_È¼`ÄïßläYeÔ9y¾+À!ç¯¢&TzÅrx×TtjD'–…6m)zâX£TI|„AğÁl¢ÌdKF`?˜9w7Ş*!syÆ“é³óHéÓR:³7®Q=\–~›eg¦¬Tjz;!) ¸Ô¶µà§×öx¡ìéô>Ë0Ù_É¡²@¨ñ'Öd±ÿmÚ‹)¨¨XŸYØ
ß{=æhø	GbA¬U…»Yš¼E£jT9:*[×t/)1E`Ìç¿{ïñTs8¢"~@v ª#cˆ·â°‹xÖÀ46/:LU… U¸‡¸¹ùÅ
óÌÉY«`TÏ:œ =Ã03°Kc-‚²ã¢Õ)x{/NC,ÏJ#‹éÛ§¦lXË™Ã&T\¤PZCõÔ£Ík­‡IàSÏ-ËydsòøŒ¢òñn¦+Ò@·3aYÂc|!–e±Jx­ÆíUO‚˜¾ÅëZ@6Y¶§:}ˆŞË=wºÇ~Š…\2ãzb²¥ûÅæƒ~4ÃÎ!µåÙÊ 2ÒEÔøiE¹?8É~]îñØù¿ï‹ûÎp‘U{Å³VÀÊÂ°ëÚ),ÓÊJ“õ¢µ_·vâú63Ó™Û1ğç…ÿƒ[’ÒVI“n(7ÒÖV‡ÈÂ¬nğ{mm„ê‘ÍßKêZ0ƒ?gŒ1}JBÍ’Ö´Ğ ãj×ÇıØpÌt-*^T€µ{Ç¹#¡ÆìpÛÈ~Óc—?]{ŸK	óyœÔ1¤Ò£ÂhÔJà‘êÛĞ „¢"ıƒfËq—ŠİÑ·Ÿ&[¦i-íŠKùdìç®«Ñáâò90h–ğçüÅ¾‹<äÊÒ^¯ü’Lí>¿øl“}g^ÎÃ+ç2oèûÕ,µE…å€ÆY}Âœ\cuÃym3«Ş¶kâŠóÂçKav¡³›b?no¬-§şWÓâ®ÖNGo„µŠ„ñpã˜ííaB+]7MR}@³1 u¬‚õequŞ›Â¼‚`ÊQ@zxç«>bDÃä—§úLf~ücG¹fÜT§l Vÿ€ÕŞïÓØÁô2&KWmÜÄş
©!Ğb½£x¤dfã"ã¸Üƒ:BŸ¤!Ê­±í-¾³ïV=vZ!›:ôƒåYÆ¬2ÓÃŠz­¶ç°Ä¢Øî'üe#va>ã¼#•í}¬”äL³}4“FâqÔ'Ò[’štr‹€•ÏRka2	lúE1’…ã“`fw0¶âÕ5Š[ïwßÅ©©{;eF¼–¹»ù‹5wµÂa¹_d,î¾7¯·ùƒ›OåĞi1[()[x9ï><a:ÑºŞ>~B4N[Á*€»n}ªNñÅD-Ù8^ÎÀ‹¶	}V¸ÖnÏÅ.-œ˜S)BƒãÛ²d×°¼Y¥‡gàÕÊTZãÒÆf$“CÀ‰â®x‡ØşNµC·ÜİkĞø”ØYf³D-@åC÷.;ŒÁS;òˆÔdÿºˆ;Zú£.fºSYHªĞƒn§¤9às¢úTIÇ+ ‹ŒêØ4èâÓ³‚~£†8¢ŒÓŒ)ü;r©ı‚ „¦\4¸Ü_Rø1‹,¥T
hõ È$ oY²µ
}Ç»«Ÿk21âÔÌ
Ín¥ÃS§q**›‘’¨ÔU¨ì{¼OÆò«­©Kg‹Şø”ï­„J¨9h‰ôE91éxqk’Ãûgéö“~9˜nC×²ä‘eªÊg:şÇúsştµÿİÏ˜=O‘ÂEImÔ^·WÈ‘œÀT(¼ƒ…ê¶cø5m¬@ô¬›z¾ÎæÍ u<T½ÅÕ^`eVAÃI•ÔGºÌùÚøu eœÔ^D®xgf™¬Ú4Aÿ`Åªrú/1úwx…½ño×„p‰ö™LP{æÌ+Wô½r[r |dòyQ­ŸÖ?‰¡UQÈ\UKòò—yßÒ¸°4ş€6"«\œäğÒ¶â›ş.¶ël!åÒ¼9E’l`AzJùàDîÌ½ÊV’û×ÅÅÛ¾¦_ˆµ¸ıö—&#bíP…avÖß_èÓúD))W‘ÒRíË:3—S¥‘0ğ¶:ûS˜ëÉƒ˜3±‹ä4¸dïfÿ?LÈILÜúÆ©‘]s^ˆÔÂ¡]¼€4¯nôvLm„1!FÂÄÁ¤ wæö¾}åAg±c˜ ¿P3ëñ6S°PWÚõW O.c©|s ÃkÌUHgH¥“V©\¨{»dşB›>¤T*…—7ªó–[ĞŒEÔ7xùÚM®âX¢ÿİqF§$–Òı£İŒ?£­­¸åü; Å+óJùÑN>QYVpœQ°¡\.™ÃOfw8ÁÌèıEü,N F
Á±BCÖ´+ËI™ik%$ª¯wÍòº&¸Ìõ½8"¥{û‹)z({”«ša4•IÉbhc«\ü¸‹“t×ª tà&L©”ûT}Ç’Ô½zV×¶9BIcâOµ¥ó\æonO8®¶«æ:áfTÔÜÅ6¬>– Mo§§‹ĞÛ^Ğ²äÎÛå’¿Ë *ƒ+lQUDè'O1À#Ê÷3|¿İìm5X¼šô¶~p(ŸÄ†,¯¤ 7
lùHÙV

:Û“ì|Øné*tŞ·D–ˆ|Ï`¶+~ëfğpT­h8ø3Y-ü1{“gÄfÀq¥ÂÙ„üqf.ÜñM¾	}ª¡‚i şÈê„prh8€*eóìOQ#xe%š4i¶»›D¸Rı–9–ü8>•¹pÁîá¸0ÖÏ]pŸåÔŠ–İÅÁ±5rMgWo!ùLg!›v‹*
"–jTñı×hdüğyÒi%#@Éqwï¸†“•V0QÿGi¿ÃğòrxÏl÷MXY2¸E]ù¾˜ |®ºìèŒ‚æ1 İ–tb¹ê 3•·»-ÏÒrûg)-QÔ^
‰ßƒö¨Q"Í.zÎÛ›¤–"ñ´7¤'-5¸æj­'ÀB6®/fC……y,–@Áúˆ?0XbÆ—°eQbûn6jk†îº,ÑcnÏø'IŞ«<ál^7.Ë¸]®GBf.ãqM•ÓØlßÚjôgòè›ŸäDk#V|ş†³´H    9u°ÛX	Õ¸ ¡€ ñp“·±Ägû    YZ