#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2928402216"
MD5="202568a941504de22bed6b6f50d20a29"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26140"
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
	echo Date of packaging: Thu Feb 10 17:47:59 -03 2022
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
ı7zXZ  æÖ´F !   ÏXÌâÿeÛ] ¼}•À1Dd]‡Á›PætİDùÓf*ÿ ’×
šEXxÿæwgäRg¬ZŒ>Ö¦ğ¨E!Šìxv$îM/Q}zÊ>*ÓË3HwX2?š=1vğö$ øIXèÂ{›fá@ú±P´v”²’;-š¬!K  ª[Ì,€¥%åÉSÇæ5gÍH§-¢Ô°­§i}ÑO í+‘Î ‡d¬¼°¯UF¥â€½A™úº¯4¯)ÉÁ•Y¥ÓN/¸WoıÉêEâÙo¥ó¦û.Øî¹u›“…yX6¤{bG»Ö³”Ÿ+}Q!ÚfgùÚmyï˜e-Àö"ûğÉjòó†ÊR*/öJÃ!jAè2t$’*Õr¸¿?=Õ‚8³´ÛÆFß<·šªÆ®Q³R4IÎ¤@¿ÈÒ`?&58k‡¸mp™ùÆ€j=fœU¦²? D_+9İÚ?:ÒlŠëVÉ$Q"j¡]ú1¬ù;[sY­øşjÈSTg¶#È ÛğHšWq‡Ñ.m†«á¦Ä9äÿ’sA[Ld3°oµIœCİ«©Vcİ€ÄŞ©¥‹)Š)™J©Å‚yÒ*dŠta.½®×½ñ€©±$"M1l½Å1
l¦öJ>İXŠ&{Şª¨b¨´Ü…A$,&{ÏĞ’·BÿŸ®ğ0”øb÷òWiDŸÂú”fycã»0¤„æşg¼<0·%Ø¿öò¯GĞÄI».=Á—ã@üuµ°zé&É-«NpÅ6cÑFÆRÎ]¦âp¬f¤ÁWôHüÁd&È§êÓÃ<µÊƒ¬m š•X¥™^µò5x¯j@GÒ„©äÜ]5Ì"Ç·Ó`/_ëü]ñãŞp:4²G]”‡ıI§[ÑŸ£äkQGL±Öx¸™ûÙàP{ŸmûZ	Oş±µô;Œ>¬¾óÄüD€Š7×µñR•HÇşõJ7³‡ÉöhK‚epÆlšœz>EmÄbåç¶ñõÜpF™ Dm±wr?ù#Œ‚£ §b­F×ğ/ÍLU*Émd…ÄÁPâ·Y¾Ô¤“Ë€Óøråá+ËşKÁ6É"N÷b59á/6ìô°ÒzÀé%‘<.Hü=†}fô‚§ÓÿÅ:!µ
=?™“ê±µm«i:”%«WĞåt 0ã°õÜ›ò|òIÂè!ÛœWA¹y¿¨ãØ‰ Õİ:ÀzLŞ–´³ĞšÎÏR–Ê³Äpfm Õ¾Íü7ƒXZ"é+}9š´ğ	sQ7ñ—ş7HLhC8¹}Ou ÒKı+›YÒ9Pä¦jûvyÿÄL_'UUe#ğ5œºópÆm×üçï;&ÕÔ|êzKˆ‚(,'ıyíä}ú_œ HÑ}9ù`8Vjvíg½ÕúèKFı_%!Ü—±9`gÙ9)á“D;Où)ú³ÓÃr‚c­=ÿ Ÿ—a™±Ì}xîÖ„XùùŠÄI}¾QÛÅT’×Ã>Ès4(uˆçc{L{ë7ø- œqôïÜ_3hşÏ43ì5 ¨ğ„Tì|€0omUOñÓ ‡X.<PŠ(ìèk`k(\7†8›#<…wÓàwg³^+4j½ú'!Û4Ùl9cgHö=Ğ]Åãú/™¶‡šĞoÒ€¹ª1rÎJÕ*7«ÏÃD]A»æAï³şÚŠî°ßVo°HµÆ)&6cê€T—h‹ˆ<ò3âÖñ¨*^;Êœb8Ğe®j9CXØw†ÇÏ†CnlH\Czê‹ì·ÉI|Á&’Ğş›§Ul…ùİKÁF‹£ˆîhÙÈ£fÓ|ìß3Ğ_t›=ıšcøÁ—VºÔ2ù&Ê‡¿!°ä5š¾§ ToPBK.ïú©Â‘Ä Jäíw/c¾yÊ$YÚ¦Úì†¶øÄ®¡]?ãá¬½&okS;/d€Ä¥|ãMã´E ³ŠÂ“p$]OúnLpõ·ä—)g­€´•¹}J‡ÛÛ´NfÎîHäf¾ı)¼¾ã’(À_Ê¤»Ïõ;ÖJ/¡Tá
 h¿\Æ‹Ëz ¯ÿ.¤¾â±Qg„)™'_X³Õ³Éª•ò®YŠQ1œ¤Yœq?(tágË‘îø< çÆ%À=TÉ´á}•t³shFmŸF„Ì~i¯àçRèç•5D8Ä0û±Ès™­2İ·P­Ë04Ú®¾ÄiÈª¡çë1	É"œèÃÚ[DP¦ûi •3w…+øOÕ‘ÃÒ½îú
hMX>ÿò•æ‡3Öapü3Î¢s“ª«ñ¢¢mIê°bâ’«ŒÊ-„´(à±KbÕ‡iŒG?
oÌAEÍ}d¿‰4·	éÉÀ{›t¡ki}˜aåğÇ‰™7+#Gb*=ŠUMN[À!Í	gicæfÛpLO™~ì…ƒ<³mÚB«ßÚ˜f¶q„u cbTÉøëƒı'¨/ó;îxô_r‘·)Y9`ÿŠZ–†É2³ù?~êúûã•‡mÜ'ü¢Åì‹.nızV„Ujp_B äZ×…‡Œõ>ğa‚Şnb"«¶øÜvô&V¨ çš4Ø¨ş¤û> +æôcewƒ* 7å«\„ç¨ëÔ3—§ì'¼­,ªÏ^QÜ:Q4r]='É?Ã	«ÖtƒœY„Ìr¸ˆÊbBË1×¿¿AÒªzIağ-”Tq S9›vƒ9²)tŸGÑu~Ûü…]ö
ï²ÜNb'Bû‘/:~ıã%¼Ül
•eÙüw¦Ìí¦x	\Ä(WAíX$òÕõN!dáïT<Ø–ËxÜ¸r¾IºmhøeÆÿ€*Ä'9n!©ªƒÌ[ß»|‡Q#üEjf7WM‰bŸC%±ƒÇH¶ì˜Rµ0¹/Ã9“AeóW£Öİ­>tõ	D›¦óg¸š8ÂRéıqL0g2CP-fÔ¯n@»©İÿvêsï+uD1 ÌºåŸŸXxËõ=wq[#-z°„vø$’ÓÍ³–Œ\wæ‹>É™¥‹¤QªŠ
Dœg§¬4vT‹î'M»$@Üjm™j‹6¨zupv€XÙ±~A[³èqÀiÁ ^tŞS1 ÎÊõ`2õêVÜıu{@“Ar•Í%•® ÁDšCV]‡Q<jvš3ı0X³­«T“Ÿú#k"é?y²~Áâ‘Y Î&E¼;ÓıÑÿ§ÿ¯®]ƒ!o¥öÆ¸´Ï¬)YÅ¸,¹Ñ‰e9üš[Kñ¿­.ï•ÁR:„%WÎÈÍDCË?¾ğ0ƒ€M{yV(á-Ág¬È`b|/qBtugs–Û7˜¼ç›,ä[Cúåq@ÑvÃFü°&ZGA~4û"“WŸšïbDïêUS+•ˆ&vëtTl)¾V8Hü|©æ­7LL_Àb”0gÈİêóâÅ±°šœ`ü ¾\`åø‰4K£Nyş˜>bN¶Éf@;Äõ@XâŠäN‘¢ğ§ÌòoÖôœ*-Œ8®ùï)"ÖÒ¥üç~‹«}^Íò6UÌÏMd¯õ”¿è}G7äU¼¼»qÉ’dÆÕ’>Š¼#\VT”ÖwzdÔTc“mü
”@ıbéS;ÃŠ{l]u¶åaÀğz‹Mâ0Ôªö8;À¶»¾–N¿ìñš·L+œª˜¿dW|MH—M¬])œ›ıV1\èƒªs×ÙXÁ1á49¨SäH.-˜¤ÁF>G¨ØGÍè<Á&‡éhqÚ²ĞsæŠÜ3›KYCD{Lì·<eìŒTòvOA
[âô2ª@†ãÙ#ïìc»	à¤î¡¥ùĞ˜ğ¤c¼q•/çóeE‘œ‚Fr&Ä>†”C#Ÿ½DŠø}*f( +Y&ş²t…ëYÑ\[õjˆ¥©.ÏßôB Oœ³D˜Së¡²ÛK–æËø- xıÃ¥êß@³²ïä’ê£˜D‹ï§}±¹¨mİûöü¢âvNÔªíe€TÁ*NIè©á@aA±}—Ú¸ê®ó¤l(­¹@"Ï€ïëÆuG@®ãQİÙ}‘ƒ
€„Y~Ñää¦Ü=%Ë´¨6HquÙ%uœ]îÏsPã•Q»8;/0v*Î&[Z0#û¡Õ}oÓ™=¢€ÎC¾¥•ÔWè¬2É‘wŞ/¯šj€HE¨oàĞÌ‡K€İG)3}ÕU¯¨76Xk»Kb™ùsğæ|öñ!œhÀG4g6¿²Ò÷:3’™FzÇwx:˜š‰‰ıd¥BSç¼µ¼:$Ê¥¾Hf2ÇÔNëñí–{
3n“Àª\‰¼ãáŒ[w˜"ptòM:ZLÖ;Şf°\Àı*z. ¹O Åö…+ğ\Ò²«Äÿğl‡XÏi/º/HKõ\ãÃ»¿”¨)®1ób©o÷Iåàx:T=Áéjé¿®8Äi¹àµtQ›añÂş@÷@@µõ—’OY“É}¹©Æ,m‚ğƒã*R¸.9³\Äu?@{İüSıO0v¢HÎ › VÇª(ògdÌrèpc­vĞVI]6íSy@jû®:½š¡Îˆ‡nVV£í×rôZkx˜ÍxÌºñSŒ1Ê±´®¯©Â©4dL+—WÈDl»UÁú3Ä-¨´s`­&9ı„Ïb¶v•·Hnš4½’Ï`üW_²l¹s!·2MCê/¤4™ÆFåsd7˜/ú˜RdŒA	ö[ôàÀÎ·È…9U;tWa£Âè{_÷åsÁk­İ]U®c®¼McdO@÷Zdæ‘8„Û¹<Jù=YûCŞŠÔaFl%=z¦.r'qI[cå9gèJ(¦Én‰çq=†P<}~{À›bë“Û±â‘oí8×]£¡\'9•ëäæÂıètäèIfäÈ€Òh—Š30È£C…§›†ê1„Y7-!şœå]ÁŸ	ÉWŸX¢ñVìtsYÁî£éÌàd`…zP«Bƒ Ò°Uíà‹yX–ÜñÂI],ÀğøÒ¬IòÍôNGp©©üí¡f¶šìW*Æ/<R†£N/6uiÛÅ ‘RzÊ“(ÚÁ~79_	¬§Ï¨nË44L oÇ}‡‘…*?¨K×}àÍ¸ FÙ|´Gv¡2vı{/\/)»—¶r"›Æ¨düÏ‹q¥²:-(‘œêq`¶HÛL·	°±Qµ;òb%¼„ŸêvÒ;”—‘@ox¾-7©'l8rõr¡ÂåâES¹«˜7Ÿ-¸ÆõzZØıE¡¯q•/–¸ûPÂf¦a—ÀÿÜ•{Â‡Œé…İ\”ôBuO¨øøpwoê˜ÿ|âÑEsÉj!>ÔóÜŞÁwâ…ÍŞ^Ö]5w:k\7OôtÿìŞğªÙæ&³çP%¤„·sìı|¦oAÛIaÍnÔqº]qÑîm1ú5LÏ•má=mC<åÌ-P’¨L#3FuL]º\è‚¬s¥[~á5v½ŠFUÑ°?&r‡Gşâáìºb'ÁÏZíñ*¶áëÏ®#µ—"«ê9isr-?¦L‚;¿XxıÔMEÓFQBËK¤œc«†û<h‚¢h•2ä—ÅH3^K˜»øÜóvnŞ"(‡•ó¯áÙb}cî¸×â+tJÀÔ™±z&Y+k«ÌFR™j=£
³"3—)‘*âØûåXÆ}*Š6-ƒEÊøUÂ¬ı˜`ø[çÅ–%p‰Â¡\ïäĞô…¶#˜ªÑƒVÎT¥ã¦Jş¨	=1ãwrR,|í´jØ§t{»A ‚»
­ğ]°Ê(ü9ƒv
n“_±·ËX×tºxß–§©œÓ˜´§ÓÉUÃ hÅâÅ«ßL½ÎebâéhaEbö:ËÒï–oÌØ¹XlÂÀukîIùòÎ
SÃ§%°ı[fc¯™—7EÏì=ãĞAq“È#z,E*ar‰¡3O"©¢»mÀ‹îÄ6{j~(¢–ÎÀ•q`–ËŒ“Ó<ıˆ´(Íí@~¨T¤Ìç>İøõxY©²G™[>6Š³B\gƒÊÁæ`åÓ†Û07í4’âË¹FÛˆú¥å9
îP¿šêth*õm¢hä¨m…È¶,,é•Õ”¾tµr“…³—Ç;Ã0ÒGvLk¯%j”0A—zbBŞÛTšÓ™KÉÑ‡r÷-ñ $pZYğ<d·r½7®+†0B8)lNœ„p*æG±’vğšûÀ‹Ïİ)AÎ,ü2FçË‘t”Òb}º˜¾İ¶ÊÃ	ñm¼Š.ä$…óú5öOİ3¸ó±h6jÆ(ïÉ]ÕwºÒ¤µaeõl6$kÊYî­tÎ @!ÇïTh„TsÉüÔ¡ã1•ãüà®{Âì´=X#Ã*t¼ò«ƒÙeÖ†GÁ‰ üíİËZ7=Ñ`bÚÏ˜%G1 ­Í›Ô500Ôˆmy:”…÷‹ğ_Ïd%‰»el55"d†Ü(“h~_V~ˆ:ÆjsÿÚYà#‚«FLPùÉZGÃkå2€*‘Ñh.ì~¿:/¹%cş\Éã!)*LÕ~_ËBÀa“f:ÎìOjMiëä±§—^ë|Tæa­ü|èBñ©²D §aÚØjdÕÔ·ñ>°[²È±Ûù¢
Tó¾Ìû0%ã%‚,ğÖVˆe Ïû‹Á–q8$…IÅÔİäu­ß}K€#î]ç±}f¯Ê‰)‰cÈù¸edÈ•4¼g†uó”IRÄ„mÜ9ºÁZ]<†©l˜|fÈ”¦¦}6_8ÀÓÎöåÏ°Ê×O É UäüÖ›£1‹]ï§œÃJ¦£™(™7AŒ³àoÍ	rÙÆ #â:4^ev›JcŒ»ŠmaK|…(9Ş#˜Æ‡z6fJ#Çc®âÀ[l'9e¹cß?©>P¿ßvIçGx\Az%„¥á™†¿tx>r6m+æN}™^BÙœëıˆú1xQğkQçc­_28*ÁÀR#dy¤%ğ²gÏàXPŠ&[F3
8¡_íß5‡mâÇ+S÷´*şÜº(Ï«á/T9{êX×ıÛqõËÛ2¦õNUfIçŸøt«,!å´Âc|k£o!Ar†-yˆcöÎ ]5ùv]Nõ~ÜC`/DI²'Â$j‡\È„•
æ=äK¶AÈnàm$ç¬c¡À¬Ğ?9?kOuRj³$ØÑÕBoĞîŞŞ²«.=yÉ5Ñ’^%¡+òí³7lb(<åØíõ,Ô«ÕMc$¯âEŞÖ›zKàF•PlÚÚK‡7°óøÃZØa›ö«H#‡ëed-èr<âJà ªÂ–zß(½¢®¬ÃUÍHŠ$Ùş]µ×ÿ	‡¦íëıN†ko®í'õé6[½=ßÓšÚuJœâì_Ã~®Ÿ”<&/î¼Ù;ér×«Ša‰üë'D9vŠ$™¶	åÔvª¿à¿Î¶f.<ğ+Ø½H¾£ƒÎŞ•¶,J:¡¹Ğ¾÷Ky¡J£Hûı²ıU”1cµ\ñškZ½~&æÖeë©ã±é
%Oßd¾ê8-øhA=Ç@%EtY¨È	ñÊáŒ2"Ô€·f/–Zı¾zYƒ…ŸÒ°HğÍu9À+R]´ì²ßMßsÈŠ@	R½ƒ2ätW5Š7ãÈOáæÌK_ÖÜfÌõiîfÌ[
ª|¡­ßÙ¯JDĞÖ^ÈÅ8|÷(¸ªËÍLCø’ÈÈ·ÄåĞAğ‡R¯™º^5@7ø•Í1ñ¶U²Ÿ¢`+ï×î0â]ü\«^Úl‘%z"OÒH†,¢ãš?9Uİu%Ağ†„ŠØ£Õ4Uáİ¶Õ×´G†ç½—Ísq™RÿıB ç½%=ÃQÍ}°³W«#Zàÿu(WWd›ş_EyØ«J*ôywæHCW8ÀfÚ¥µjV&S¹Ó¶çÏÉÕç„byZŸÈ˜\®-¦~íè#rRˆæïä›®ûX#K /úgjíÆ=oó;X
àŒ‰b0½ˆVÇJFŞõ™¼`§aH{zâ£{?+ĞÆ¶rZ´½vïoci:0PqY k‹,"á.1ş÷¤_şª%Æ Î#¹•­@€÷ø§Î{bTâÛ
Ï¤şf~M²æİø[·£Àãö"HuÌ¹Ñ©İ>jñ²õçZŞ_AÛØ!ïŞz£âóp;ı½ÇÔN¦.+–äamHF(Ô¦ü¬v’ík©kpö5<MuCÂÿ<‹
_WšĞ@Ê{{ğË¦âuX”!Xß+<Şu5(©æà:À˜ğ‡œñ-ÓıM¬_$H¢üjèóqÏ@¹à»^¨ØhH»ıºíÚ•€+ô<ŠCç»T(äsuT•[¯¦—Bç·UrŠùÜt½•Ë¤Mäø¯w6=¶Zq~š(*(á
0®¤ƒå°_šhÉ±"b?»öÿ-{í{ß\´ÖÎä1“ö`Xïãg]Å›6o«1”%“dÓ.²Hl<@
ôMñÌH©¬¾âş	×Ä6ì®-wWC]‡pëiÙà’uœ”ÊŒMTPyp-ašZü®ìç„Ê¶ÑYØŒÄ¸ Ü·™u/…¹˜Š
”ĞÃÜ±T7$Ô.<¬¨™"+SĞ‰”Ï&Çøn¨@‰­ÜË¨Ò1'ãşØG5ó3¶µù±ï¿Pmiâl±ŞîL$ú	›„éi Ğ1X6g¹+»©¡2†z»˜·d:~›H_(mâ¡išğç*b¼;Krµ7˜ø[ÎÅ-º{ÁR²pòEÄ,W´"c.©•)Pk”-:ÒX£xIù]RÊi1T¥iÃ9¶pÎ‰p¶Ğ1mæöõ?§%‰¸ÆsâjYĞ)	öß‚Ä!÷ÒM§tPTÓİZŸ|ÎÅ®Ñ™>¡¬…
à5CßııÍè#™d(WÆvÏû&¦a8AW”ÆÖ¨YìR„˜åûŸm–5õ ¯ÆI2+¶(7¼ºBÁe`éMH<€Îsø†Úï|ëR*t:Õ LÏL4& 'È}Ü˜µ.›I,Ó=±ûØcs,Öûš)Š°-V;f'R´(,SiT}Íš{&	ZZo«åyzÂ¶£4?£ËW- —)¨
–°Xñé/“ñŒiÖˆ<ÿ-fÃ¹ÑG)ã„‡Ñ`]¹şª4çÄP©Ÿ‘v;ä¯ÇÉkëm ó: @,/`¶Çzµ#¤‹¾;Œ._®eqyŸh×q5
+@æ÷(vé¶˜¶uµÀä]òÄSµ“.§ë-NCíyçK@´ÜÎÁÅPtIı›ˆ~è­hEË€£‹¼Œ»¹ó}Â(üÑ5Bá¬YAdû4½­¿Ä³_Å>¢RéƒöJq²ò­d”rğÄêÜí„4œGÜ3À¦[±·~éëh„;Í=¬¸õúed‘ë1Ù†`IZ£ïwÚ„¡1iT´ş‚è•Ç“§Z‹å:’'ã£4Ğ‰å&C4.¡¥ˆÕY‘Št}ÿièë.‹a·ºö+Æ‚9ŸÆXˆQGn—	t–pn öÒZíí÷áq0¥6G»|:a^i™ì)ƒ7ÙÄp¥Ğ`KêŒŸqŞ,¦„­î¹?†›ÚG'¢_ü²Ä¬zSu”t[%õÚGşJ¶§1V³“î4•j†Ø!¤ÙxçÛËÌµfÒH¯ùÜWSäfJ(a&/(Ê —ÜöëÒ¯G“åğÄÏ'/.šv‘‹ÌÊQ¬®tÀuc´^Û¢^C…wa’YüJ {İş	•:şCXŠ @bš±¶!—We8}ì‰ù¨÷úÅ¨d¹Yp€•Bï:ÅŠ°l–Çêâ6Ì PpŒÈ/¼ßÖ,8áS3 ‡pš‘Um€
ZĞ=¨İØi`r“¿|ˆ¯M’ğĞÆaÚ•2±)A)fwŠg|ğ²4‚AÉş7õxğg9Lª4Ê šÜ6YY|ˆ†	||@­-¬yì€	ff¹ˆòs]ÿåJ¥eøó¡œ4-I¦H.@7F¶Sñ"(ñNñ‚à Ãúù>ŸÛx3XÎœĞö ~j‚CX)\İrE™müb“uZ¤Æ˜¨?™ƒsO2 èú-$y8p]-õYÃÀfSK÷µÑLèl«È@À]çóé²óàhÁŒš‹føM^›[±3‹Bs‚AÛ¯ZXWiå¬¹à¹'ØK€gèOÿú”˜jí‡çß îƒn#¬HÃÍŞ:U›oğWïz¡êÜ¿;³,[w|€AÃ~ku#B«Cpœ»‚° [½Á¥eÛFûõW?7©åï_3k6¥xAWz¶”‚&¿‚ÀÉ¤kZÆËš€0SNBRIZfkbÔG Ó­õ¡\Ô®7 /íàu®AòÃbš‹ RK1BĞ=§Ê‘Œ–ÃúÉüZÃN‚–X¨NŠÔÉ~y5±Á¶7R÷½€2¥fq7°À„ÃÃ1yZ€™z*,~˜XT	™}„‰ù¾C¹i8İ§É7ã¨âı¨ˆÊŠt00à/òdÅÌ#`jA¬(èĞ+<<É¢V™9—]ÚçÜ!1m™Àà0KZ{V©5wQÅûpmåŸº|h•„—zl'ƒpí—!+¸Ü*µ¶¤¦†Ğu³'¿­ÁFÔmà¹)0,ªéÂ€"^ƒqÕ ‘hæ+ó5¥ó!Ô%´š<¹Õ#õØ$ªi¼8XE‘Ë,À*©…û—hY…,0‹DÈaWÚä8$v!
°Åñ4Í8ıÚF½rş§Ä†ómµÎgœFE.¤»–
œFÓNnqÏ±&úÅ<]P^»˜´…Py¬1óö*˜@–p‡‡ŒM)¬ª|HT‡3gpŠQş•·^À´Ë‡˜aîÌ·÷ïKú2Öµ}ö÷.×/‹ÛpùÌs÷ïÓÖ±¨‡fŠ1¨°ÕpÉC¤©ĞB/[–;Aï;az50xĞw3LÓ’OÂÊ·…2]ŠcğÄ®âÊ;mJíé9ÆS=.dcß19N%¤ˆÚˆM‹Ëõ˜j>û2ØœRHm-üX<ôú}9+}˜Ò3#z
¸+b8T]Gô¹ë˜ºáÁĞkK+²ì82ë9-„EáëÛtøßÜI5¡rîã¯¦!pŠ3ì±ÒI¦a%öAG×‚ıl/¥{zÕuŠ¬ÆõŒ?H°ê|‚Eñ‰ÁÅ¯¢?È:lzÉqn«Ò]ÿdÅf}}­`ø¥ã*µWg >Vª}Å¬ÆHGõU±[àqyªATó½fuiGÛf335åJ«Gâ%côl«á=–ü£?Ñ9ªGoaãÖ6ùBßë7½nÿ‰yÚëÒ®â›ÕB³‚¯Æ®ÁÍ½†Nuş@ÔPˆ®°„åñs3l;§PóIBgR¸êÏ´ngR–æÇĞáfŒ¼Ødåá‰*ª¼Î˜NZ»yE’—é‡Ó9™Ü+ìú!©8½è~{CãÈàE®Aî`°ÇòGÆò_¿\íH‡€„9ôxcØ«`}x½·U>Ûä,ˆÖLÚ·}^
¬†…
Î¯¬\‹gŒ•?€’d²şj¦øÔØ…ÂWøø%Ï_ƒUÅ: ^Ûğ{şÊe-æ¨ ¢ëÄåf	Eö«éYtÛXĞ‚ì#ÅXII
ÏB:Ø)a´õ,°'jï­Òš¶p¹§wØxfkE®CQ¾£·ğo¯ş«¼d£½
¯5æ)®à‚–×=˜öÍ÷¸‡®Z,!øĞÈ4­±è^?w½ƒ®‘ƒßñš¹6àĞÍ?Œa,Óş~Èì*këTëÀëÅN¬cë„Ïs	\ŸËKœ0%äg^©À^Àae	\xx¬9ˆÀÊ†ËÍiÑÎ0â²FæC¶÷Lre@ÁíZ§²íD)nj_ø'M0Ó  ULzF™Ç£eÒb
øK§ÔĞ3Gíñ\;ÎP«±çÆZ6€¡ü½å£ÅéøÛöƒ‰‰•°ö°œ¬ÁGÀIÛ$ˆoè¼Ã
·f6t¡Şj¾ÿšÑùÈÍ‘ŒÊ´â¹Fë”ˆvß`QèıqUm"Âu¦÷æy×>Ğa¾éğğ_¤\T×@´b3mq`Ô”}d±2D¶1æ“¿&SÖ(ïÛ¸[õ‡ _Ú/	Ñi°‹Có¬Ú9NA˜q:¥ÃÂ	cîÁaÂº¦åJxèÂÏ ›r2¶	#	CS£²Ÿ©@§Õå§ŸqÍŞbà]oJ¦r_ÑŸ@³h~ÆùxrÕ£Ç¸_a•51‹Ä“X)ÂmÓn"ÒHªicîóO;Wì8?ìO®²á×º.‚–"ä"NäÚºµÈ<Šğ°ü‡S°¹kªîÌ“¿M¾Z¨Vµ©Ò3Üqh
ïØâQî¥¢ ûªäN«¨J@î¼W¦spo2Å¦µ˜ñ¼2dµ¼jâ-r·¢·¿-Ä€_=‘»tˆWû–qQ|ù“\)’0À.¤M»ºGÊ!,k-ÖîX¨g W´ÑÏZª¶Sâ£âES–{%i°o;¨ıººÒ=Äİ¿3	÷Ø'Qµ^“ÛÊ}[Û]»#¢J8Bœƒİ§Œ+¾y×+)‚îVYåOÚ\v7Ø}yk†|UGşÈŠÒBãs’7“w$5¢:Ût»XLs€±kùµQÎpÚ=7–¥£uiD¿“<³XñËÒÌr¯W-^@Fºü`å‰‡ò¼ÖE“³ıO»·qöù;Nş,+Ÿ@ÖàWáÿ#”ÛkGâÉª9øxÊLŞÉÈóª]½¢7İuæë‡±!»g¯uU4ø]ÖÀ¼“P4…7b_”9 ëÃÄÍ}€ÓÃi—œâÊé—/à­_ËÃ5˜øÎÓ§ÿ‹Á|‰Å*[×««èUñ õÚã §Õ¦=ª¼T‰•µŒ2ôë£' |VÓ/Kœº2Ì³ŞK6Ã
ÑùëvÃ›àÂÖæÉ~?–a¹‘pdSxéT¹pÍò"ìâŠí²¸nnı¿ü!Ô2{È°ÀJï&UWè—ªõAÊß:k½í¡éh½òjmI`EŒÒ°ÉéàyÌ@_£Ç=£heä,»­Dˆ.Ò)S2®jDÒ„9è–~éñQîœ-£Y’ù…Ú»Ü·9Paóå­2|ßŞº2<ùÇ¼€9k¬WµÄ&YÆâ ˆuÄ¶h³İk'ú…ğ»^R¤„ »u}JymĞVsñU"zî,EÆu Vævªg¬ éK«ıã}¬$•z9[Ã>:¶Õqè@ØÂ=(2ß‘Ğä,àø?ÁÂäè#Ø
áò€˜Ëş}õW	`ùiKr«/ì5Çöİ=Š¿R_dıN /o	çõ0Êæt¹\J¾åy¹)û6hõÌ¨£U†µ_t*"1àLªÕ@„¾¤tiÓ:/WJGCIÖ_j˜ûáÜÙlt×ÍV-#})LüUw¥&¼İ“´áDa¦‚S®{ì…j3N‹#­ }n«Ú&2ğÑ-ÍÖŒĞÅGó†Ñ¾«d#’<›W“Ø·GAÎ¨ŸÏêÀ€Â	Ò66Š05ÕÛ…I{ºç˜ŒG¬ßÆ‘èv=âwÒóìæÜĞ†ehåAjŞmµ»“'Niêí#€ˆÍĞ6”MC3¨37/C&9EkËÌÀW2»GĞ¯p:Ñ‹béâaÁäuô;*qµsh×`Òæ»”'À§^…=w½ ÏŸï½#×yDÊÂˆ)ÕŠ)pô9¨D­÷‚Y©Úõ•Ûy-gÖtºÖFğdáã=½ÙÔQcìêƒõšÚë	º\ßÒ…n™o§ÏaÕÈÇARsæù›*ü½Cû·Ì¡‰ù}ğ=,§ß5šÁôCôr|4 o²d¤›_Q]H¼r\6ü“é¸jÏ‚Œ#Şg¼ÂğëçÉŸ0.@¶‘ ^ßÆ-ëK‘tîµ4tÛÕË†¹=”¨T«›ÇºJ»XÏ¸øiÅİº5Çö±GüÎÅh¤3¡Ì’`l/8[³Ş­şaU^­>>}í/íÿ£÷Öñ¹sšè~½<#öêÜÓ¬ïC4Y³«?‰µª¬ß¡r£v« Ó¼h¿Ë.ôª¼—t˜2©ZGÊ¡4×G›¤•6]	ïˆ¼*“¥ÎL†ÜB¤ÀP•	3˜ùFÉh	‹ÂFwzc 6a1Zò]İj?ÔÏ:ø?ó|IUµäš.vpÅÖ1*ÄÒ¾G’›Z’•‹	ŞS÷³ütÎæ6Åz.áy	åÔ{FÜ¼ñãşÎ…À7`hË¤²ÕEÁO¸¥×»Mÿãäû¼‘mƒ1à;PñM©ùÄÍ" Š`çŒ2˜Ós”Ş†ÀŒßºW EVæaësDÙ#UZã<0I™š;Ğò¿ŞM·i!‹0#î0ğn:…mîsßö95hĞ¡P¯¸LD]ØE(hN¦Œñl·íz$ +…ı¸ïà!–{ğZD1ğğ¿CKM Ğáğw[³ıÅşı£ˆxÙ½–+ÙÛĞËîÁ´Ÿ‡£ìÎ8pUYÚƒ}fùĞÍ;ñ˜Âùî`2;3X•oÒ¦VYş¦¥Té‚4‰zn«‘(
†2b\ƒ˜òğ‰ÅR¿`Š:2/M€ØÖ;™kWë)7±nsôF™«ı“31e·<·ª{›¥™M:fæ–,Ğá„‚Å¯·^,‘sjæ©«”À…zæ ÍUÌr\ÍG„^ªŠT3ÿfoÙİ”HÚSé}<7$&{&ÃUf)NëÈïÁßOıÏ˜œ1-©¾VCpë£)õ;k€pAOuÏD”J=ù:ñ‘kÕM¬rÆÍ†pÕlpCÔÈÒÑQP®Ÿ¸g¬íÎ‚®è…d?ÒEÁîXP¯f[Õß6iUzk¸›»#š‘ı2YntêDŠ`-„+z*ì>4‘>ÊÍ Ç
àÏ÷ ş}‹,VAÒy¸ÏdÓ%K =plÕİ¦Í7rº¦ŒåæQp<¸”µ;ø{,_²aå…*«js^(–ŸÂrÒîÈPıÃÔï´[Gº‰¢U,ÈFßÙò› dê(zæıqx£ÈZä‚ËLØ~WË­¤§aã>ÏØ´:šñöKµ:áƒµg*ç™æî}‘|@L-9Íf-¨aû4vìÆcA°r#·›Ø””Œ‡‰aç»ëRÔéİ•å¶	P¨!KVWÈÏ+1ËE^`kÊÿ^Ûc˜[Ş#kï’^­/–qEãÌ°¾Kÿ×Ğ›E6£=ÛC¬Ğˆl¿@yDEš¤'N¤F½giö»Q sû)pëòï;íéeÄP@ÙV‰v¢rŞÆáÍ«t3'_ÁàR_EÁ±ÄÅÅäa•º(Ncú™†¹]§šÆrLÎöb@£®rWµ‰æoì>ùT®Vogy116¨b¾ÎF¸1ää%Óä3÷iÍ&ç(9O§†Å°lI%e`r¸Bi=„4Ü_ÿìY€gª‘¿0^¡·²»œĞ}¸ŞR±`Š+¢BÚ"‰<Ë*öføEóğÍÜF¾SnÆ#rAíÎı×µ;õ¹›KvTk¡@šİªõÉqş…×ğºækyª7üQÓeœzA˜öemÌšb]†©ïØ;O%ÃËKióU#¥	€?+ªÓÚ"ÖB)ş0©.ùÅ–ÙäÙXš:aàş©hç2jéK¤õŠ†^Í”¹¼É¦­­‚â«vĞ€¯ŠRé®ÌbGfUX{r=…W¿ÅyUı=Äò“KÅÈ¾4­Q·sºf6òš­ÚßÇIæÔ+'òŠ¯üçƒ-û5cÿ·ÎvËëïäBµ7¦CZÈH7@)?¡@é—lÊX
†;è£­µ6 Ï v¸ú,k”‰Ç%ôeµ†µ‰‰äq	+Ï@w¸õı¸h@ ?æÉYÌÄÀ‚Um4²À”õW&â©5Ô‹†òÇ±°0a»œŒnr, ÍSNåƒ43à>.Ø›ç¼l˜G^nYHA•¢yèñ²CŠşñÃK­öHn¨Ä$ŞpKŸ}®¾ïl3Ëª|H=L•MjfW“ÄzWgË¶ÍrEÚ¶Ì÷Z×ç3á"û˜åûÙÎ‚\ó…ù†GœÎ NòÓÑÀ³vÈ¤HZ±åÀ&…á°³2¦{<¬kŞ1PÅÚbÕ%fTœ¤ã+¿¡@¤ç¾ÛN@[‰`Iœ'¾î+4™šöêš3ŸùG5©Ñ‚¦dÔIğŞæOw
öÉdş•¯ÉK}lr°dn’n)3(fQ@ÂhÉŠa·^Ó^âã‘ö°ÆXàÀ0Ï!!P˜Ê;Xe3JVBÁ«¶!Ïs–šp~·õßĞX#t(½ÆîUi)WÿB¡àßöEd.
.ñÏ+şQÃš„ ßªá†lšÎ§²J)òı–ğ&Zë·†ŞHLßş®ğm„²S¶~‡­ü1Ó½³²CXÒ­r ƒXC#VÖÑØNtrq§ ÈI›±(wV¸ùğÏ™)°|qyqÊ2£»ë?ßuHôÀsNÂ!µ<Ê]Ş7;°¶nÔ73âq!!Ê‚òèÇ¶Tğùzt†
Á|ÊóñI@¼ëà`ÿœh,æ\´¸2w¢À7<§²çÇİj‚ôÚği²FnbĞ'wÜ«×íé¿f2L,9ÿì?dŞ\‘OæF
œ7¯³5ì³TÂ¨âÍp›¯àµ‚&¿Š[†ˆÙÊn·´ªî!áææ<Nq˜Iü­é™(f:qY¥lşÒQ&|¿ì”Ç»©0½?…?Áàt‘tÇï<½fiSbZ.ÜÆ­:f­¬… sI³sclhä­aÇÑ½¼¥§Y*Újæ(&{êQ6×Õ }°Fg“Ÿ|D¤UİêÙÆêüšO'’ÒäïÃ×äC”·Â)Âƒ:=bºÃeûDë·ï¶·l™ö^ôzXºt•N¸İcr<7e/_`ul5¢yŞzDÇC_ÿGl¤"µèØ%E,L^Vgíe±`>‚ø Â Ä¦ªD}šğ¹’Ê¤ÚAq†aÄ 4±³híl¥+‘\@[ÇZ-Î±— ŒR©Ôá=$>œ‚ vàd¸mÈ;Ù—İ&B7OõX“‰û½á`@ÂVü˜<	VòÀŠ¶ €‘<%1ÌŞ;R§ö[¶ä÷cSkÿ®>Œìu±‰Âp™Í”ºmiJi´C1ª£ÿKÇ±øÒGKM:ğ·7vBğ{S™55—À®D n=sCnê¡+6Àm5ZDKş‡7àŠ7Énö,gö"
 ò‹i¦Ê/q!êP¦Îå…ñèÂe¿å×ú"Š˜8å+Œô <úÆX]¼œÓÜ+«+	.j#ÌœQ¢¯}É2ĞšÛYÔ©• iu‚.£p bejp¡Kª÷t"!	‰….%cViåjëùª  bvv_wÿæ`‘ß·¤÷`xúT»dgç$QLoBAD5ë›ƒxµ±ß™™JI)±«RJl¤¾Î.`@Â\ø(ZkTeGoˆóÚ–3æ“ÀW»ÿ<e1s™(or)ê#é›µ{Å|v{ëLëéL©ÌÄRó=V{¾x´ Hûõér— Ò·SûÌé m-Ïô¤Züè¤¼N0qÊVeHuB^óôyõæ)é¿¯=æÆÒ<A{ÎòÒ£­¬v¸‘¯Q“i:üc–J_Ée	.…mƒ”òQÃ&£Ì‚rğmÆI8IqN ÌiA„İœÕFb7$²G{Õ}O~ò|µ¨E/—³şà‡VÎ)×÷®jt2>p‰¡ß¢6Å‰-†Î‹7yë˜ÃhÏ.('aYË¦WN×_¼¢cûYâˆÌÙ„‚L@WNÜ€€ëöÍö…iÔÛ<ı”lb)ódv¶^4%N›´‘7·~æ§ÿßûèTFå¦¼­êãëÀó±ËlÌ¹gÿ7â…Şæ*¹eŸŒ®E&rRHËî|ú}U6SŸ¦Ñxf=Ì7Î(ÒH¸·×ú$k_j·ğÿa‹ÃHcJËh¯R¦¿B}_õñDÈåpúĞ(DG¬ìÚê~[9ıóË¤$+bÆğôÁ¼=G°ŠÙRL¾ÈúÆHGTÌ
r˜­èœè‘«HKä†“]C}Ym>MhÚÿW‚J{Q§ş)#‡~u²W(~KfŞ=İ:‰7ëä8•’“æíÕ<¥àğşäÁùÎ'£Ø4–°3ÔƒciFì‡fè°¿œçØ–=ä‘hšBÌòâhCˆÎ‰”ÄHTön9¬¹6w©¯^,–Í›ùÈ)|l×7^£êU?=Ú¡c1¼ks›g‹Áæ>#)¼âøCKnw
V¢Xï¼›Àûò§‹(s êÏcˆtTş×¿ÃRF–'¶Juß}ü—Qo8X)'ÜXÅOÛ1ãcÛ»NñœÄ(ÅÖŒ¬îvxS&\)é •ÍÄ?Úû–~ ¾u2£Ê€EÑñsÃÑ§óÍÒZ¬f…“äøÒ¬b#?ÀŞ¼ÄèœOdÂù8›¦›ñÑÇ¾¿ßÏ35<^•ùñağRƒé¶ßÖ’1T'1™&•ÓsŞ»O¢˜J5ô!ù] ªœF’ÔG¤øÚ ®£»«QQdY®TÁ– ç³Û2/™Fbÿ‚1¥Ò\0#ÂçÉò`Ç«BX…ê¸G¦Tæ
[&ld"G¯Ó_ÈKmO}[í@7+#1¾®
úGÎvÊİxx¹
6‘¨É©ØİmR.š^ïk‡>(ıÀé	ÏÙ;¡»à  c­nĞî¨0İ^¹¼;§dğêås¿qY­4ŠBµÔı gê“«b\=Ü}¯<…ñr(€[Ú´—úübÊäÏÊ|iR|ÑÂ*XÊ÷]ƒS	üà^éÊ”ô«å²p»Š·»ÈÅ¹RS””éiÆ0dFvø	ªªzJé^y ¤1±<¶äX5‰yÌ©Ö¯w†`f’ãeEhWz²sdã
LGçĞæ“ğµIèIàãY%®ˆÑ5O‹R6~1i'´ÚŠµwén>]ÑĞ6(Òòwò	«]T«jÏ=‹H3ÚËÈªôŸ‡D¦è‘Qc6Ë®ŞÛb6şBı	ÿ0]Æ5ìß8ËIœ/¤ì~ÍÜ	»š½^æHf§ ıcô>GÂ|kz ˆ†¬Óú³ñ×çÉßÉ7Ë`Â°MôM&ğ°I½< 5ÖJZ>0­’™Y³¢Ñå’æ¸Ê¢§#9ømqß“'‘Ñ’UËİ¤­Òìx(udŒ—.ò.ëú}–oÆhÇæİæñN¬?§|“¥ùÊÏÍğn+”v.ÜªE2Ş­›ÇÔ»} aK*I;•ß,íïH¯+aåI»„FCÚªuÑ@ÉLól-ÏÁ“Koû]UßÛƒâÌœÇü„×¦]wûüîz@ø Á`)›ÇÀì'NöúŸà°¯£^Ã”ËpšeßÙµ¸*ã+Õ¢pw…¨Õçç¬b ›Uy¸ÇÏqE7É ƒs½¼Zé¾]¡ÓF¯ª£à&›SÊ{VLo¾<Õ;ê“÷İè×¯(pº±İæ2ø-"?-Ã_¸¢s µ§~e:^²\l¾-0×”qg%4—rswNö ¶ÕÏóH®sád±Ü¢<ö¬'T^|vb²ĞÍ“É“Ï]X=Ø@…Œ
š¾àår[|Ï¤¯ûŠÈ”Qì^[ã¼¾^3ÎI$ÍpÜ
A'š¸aãì£€«?zÈÂVÂ(÷Ğ-×¥Ãü”láß>bÑ÷õPºöšä¶µõ¶¥Œ°‡©#€¿ŒÓP°a”C|A,N¹eõˆĞêßŒFÉºÏu½‘" P@i”ƒÅTí×U®K”t[¾äÈW,ÀU¼§<@÷š~iås2ƒ2ÂS<ÙQWn…hËá=hÿ¢Ì;—l€gÏ­ı©Ec’Şû7Ì|e5Ë4Ëü¤äEVïL&'U¥Æ€;Ö­0bVê@¢†ŞlïÔcÎ$›
h~„œ à…¬.à«WÁÀÇ*‘Â€xM<@ÔWVËÅNÿº¾fÑ?ç"ÂVE[ˆÈ©ÌNæı—RO¡¬	|ÿîÖ|C¥Ğ¼ò>ÆOüWVnF«Zí$¦G¯Æ@v“í–-âŠÃV|FG˜ßôBÛíş8N!D9 do]Ğ[c÷Tõ¤ïY´òºT£í÷ Gnè±ÚS14ñã®f+kœE×ªÕ³h2sÕğ7XyY€à~F×Ûƒ›Hï!¥/ÓQ‘;JòZŠn°¹`™oËÊºâ²¹-Øi^´ËbJÇ¶ÿbyº‡[¤|’ôìñA+²¨‰öŠõÈĞv`A…µÂñã({î ;nÆ¯*‰}X²Íìawz és;¥¾Æ–ğìF&6“÷ÏqÒyönÃo–è~<Pªcì9**y€Ä…éøHı_¤ˆ2J+cJ¢p¯=çŸıÂ”7ˆĞ,!.èıËtÒ™ıw>-´–ìhÛº<Å~sR>^ö¦YM®¯¹äÌÉÏì…°3ôø9ş	bIdERñ~8^ë×[µ]´Oz"kô—‹~¬€b  ÄğbJ„ûXFx§nùóà9ª©X´êå×e“[¸Â’Ùª7	&¯Ó\h>/²FÌHNâì&§X×i"¼_¦–†‰èƒÊÌ†½¡½[6„0Ñ4ÕîÅÊ`Ñå¬y™zë#ì¹Nl_á#|¹Ë yİôÌºV%2ùáâA_W{ü¾ œ9°“&õğÓ/Ä“u/M¹ğ¾wëÛgŸÜôwÖZj—ƒDîÉ¿VaœLUŞf]d€É6ĞòP‚28Ãz@ôóÓ£§gîç;µÏ\’ëö@/;údaWá…aá6ÍO··¿ œÀÀ{ê8X"ÛËÙ
×B£iilua±DØ?µ§›|åbt—ØUzW–ê1Åv‘,Ml×ú¥ÁenØõj²Ÿi®R&	Ü°ÑÃ‚‡¦"¹‡OXH¶—Š:øvíëDâ1Ô¾ü˜=Ë§u{‚ j­¦ˆ3nÙfØ6k¥Ã3± ë2Uå˜¨lfæg¤s`µô£™»
">@±ˆ†Œñïp‚Èÿ~®¨ªO­A´y_“,G	-2Ÿ¿kYÁÉ0ä»‘¼9‡Êì¨!iãâşæ¬…a)eŒı©ĞùuŸ(w“v(Í¹¸3¢BƒUŞ9uùa¼mÃ:-Ç0AxmÊà6ä'|ÿˆõNâ³Î®VT¾	‚…„FµæOA#zb.mZ{¨€©â@qò	Äë'}K-Äâ'L®c¶6POç4éä¸]:”Ùõ/ğL8#7\|Ş¥_]<â0›[lŒvâkL¯\–R¬PPr fkQ`ÿW“vóŞ~6şyê>€ÿœç¸÷ŞÛL^+jÁ¡Ğ†úˆ~,ôKuaßĞø¡Ói”e5Ï¬ „Các>ç7FKç[¦(±¡a^â×	ìXÉÇb^¡ëô¾Ğã5SÈ‹>Uu³EŸMòVqµİ™¤ge×ŞÈ„œÚ4“r©ö3™;lë	bñW·ã•×fàLt–M±oá’°:k–3»üÚ²B8%cHH0Di•î¡—°°F×)ïÓÆı äØ´üÈ½nÔR‚¥ßpBÂ¯LÀ¢49$| )¥ë/àù/¤bRDÆVH—›¸DÑğI1Ì’ ¥V•ğy½	y\¦U‘¶T­EòÁştoI3ÒVyHº Ô—&ã7Û™1´“€t¸z1şß4e†%”>p`€W¡å÷¿ÓÌ¿+ì'	’cäìÖœYı=p&Ô¤pwwbŸ_é8§ïwp¢ÎĞ
Ş&n‚PLô¸Õ/ò[J¥’yº½È‹)6&SBàDåÍ\EÕR—ìù‚®^ç£ªÕùVP9Ãë¯«£8<ï2;àú?lXÊ”JDåöÉ‹™Æ-:K6R«_€ùÏØ·\V¥ÒöCbnÍ†Tò)u19Äï@ÆL
€ö6•E¤İ{ƒ¥‹%	Zœ-p*ğ7VQË”ÇÃÜbƒm"ú°—èz=>›tlåcİX÷’uvL‘¬(·ı‹<{ZŸ“`
wÙ7"&Œ¤”óÖv‹PÖğÅb+Ÿk7Éè»IK×´C9l Æ+İJ`„³pİ—~|ßğ»™/­K™y´zåf¡w¡¥ÌKİØVŸ<WıKÌƒOP“Øî˜Ã¿ÉúTÍƒ:q¼Ï¦îıå¹‚¨È (TÓ[g m+ùé+=°Ì ©l™¹¶O°ñ¯)CÀôÿ¾‘€÷mT{bÿ2PRç»¥«ãdˆÂFSßï/Š|%Wnûnœ¿âiPŒ#™ÎãÎk#‡óè¶.å™n¦ƒºˆnßÆû^’—Ìac/³˜Åì8ü4+Ä™mIªö—€Œ¡öö0ó§Â¼_%ê]Ó/6d¢[¡K¨Õs´:Ò›§ËhèÄ¦4Üj6dâè98êrïj<wğ4§©,ÇT>M¶è¡v`ò5PÈ­§Ãb…¶éAYë~ğaîgœXEÆ$HùbFH`ÊLC4±¬kË4»+>tSbş¶’”j„?Ğ¿Õ'“ÅØö+¦¨®ÏşˆR”Ch%œp£ê¨…Vum—-L&™FonîÒf×42X6†µÖÓ„3ÀMb­2¿çşd^áJ‹À†™{6ãØÛçi-JêU¬ç¢)t3)òÀ:!mØ,Ÿ~"C„`âSëyôğP?1	\´BöÁJ—’4İ„œ¨Dñà¯ÜğıîäƒĞÎĞ†î^)ùİ¤bÑcxº£"¾hU{¢YÁ€ÆÜí²¹œĞ9ÔP$2¼ÏÇÅAU!³ß~ñÀQÄº&\bí[xá™lIÑê¸À"×nıÌ ôóƒ´¢qQ4ñ}Ö‡ÁÒı:öĞxò’9p0Š½¿lµ\¯óTŠà Ğ3aC±øruª¾ÂÂu/n³ñß!ÜüEˆcˆe»VmkTÕ®VŞ,ÂdÖz»İhägAà@FÛJNÛQ•™RÎÉF£"Q%=€1ÃÁ/ˆÜüâs'mP$k›POÇÚf6å/+6Í+k[xî­"¹]
;	']­cQPxß—ÒOÛÄ§pVœÚMÌx0øô@’ÈĞA®íı7®@u
«£rğ.K!-ç*†ĞµP˜{¿´‰¹û0ÿV	†±'o¤ÀŒé²C§b15}t¼Ãœ˜ÕêÚƒì”l7ú7­ØpH¥jÍ£ëÊŠÜ3ÿè!DŸ\ª×®)í˜® g¼….²”væVnéÄø²úl«q[Påvä™+'ˆË´Ô«é´ë[ò±‰…¨º·:Ïlíºû–â(eøcæÕ¥(•e&ÊóXtì'z]SÔœ‘L¢îoë¼Á_,·93};òĞ‚§İIô©¦”OˆÜ=ê€·ïäY† ³‡Œ7,¹ªMjAª€Ïİ~Ñ%ærdnØ‡i«f.0†g[ó#İmOİ6º[‹g‡1†Ï2U;8òş¤y×á®Ğ.mÎT^1úò]ø8Yÿñè¯}¢$Y™8Xº?/Ê;Úñ,˜p>uG3ş£–ÔNö2Æb~/ÒíI‡…F a´x§¹u¼Õ:ÿ|Z/áŞr¿£@Ô²°eÀ?ßÏ	5ÇF>xô&	Š\oTº$Ş—´¨IFùº Å-c¢&\¹Ñ—º¾—ÒG&Û+@1©²¾&€9®d¡!…×d/ûCí£„€¢6¬Zä¾ˆ#Š-áˆL?!Ñ<¢òMN/fDTŞ3ôÀDU¹Òr!N%Uéêä¯jÚ¤E‘-n;ğÉÍv]BQ¬›áÙÔ‚­µÍñO
ƒ	ü¤éıg¹Ğ¡†¸ê„©@)oOP=T©Ğ#Ş`£ÚCÑ”±ÂĞPèÓĞSÇö¾s@Vé‡êƒÉÖ­*Cµ¬‚œaá'Wİs¿zb‰›¸õuK{¥­Ó’,!Á¤^–´Tıà|x¿‘³DÕ„ ¯ÆÕtè¬ì˜Óàr™ŠcÜ(eØvı]¯0ş‚;tƒİÅ£˜¼Ô§\äüÆÏËİ9ü'aÔ:u½ÌwåGZ¼3ÛtTMŞİZ­E”\2dŠS4"âlÁ<C$õÊÛ°yŞùT2ğöñ!WhA¼›W>ìQÖ•T×¨·cÒ×$*‡º’ØQ€#éÿüÍ[¼ÈàÔiÜ:ıï0–/‹úto¹ WÊ©(q_xt4ìï÷„ËHWêd™‡2ĞeŸZÁŠ,ı?!¦	‡Xe£•Ì¯*Æ‚¿vwcµ¯¹òè¶£F’Ï¼´!JØyòkÆOnTø®KetÚ<¼F)ÚøÑZ¼<,Ş•@Ù~êAI±šé³Äëú#f\‹“v’Ì1\ìw1Dßfrro´6†úOöKÇ³ö/W×´0–yÌ‰Ê]Æ?E>_ÇWš.7àÄ&^$Àxãm­Í`u“G´«Ô4FÑBg…“ZmyV:ŸÛ³³\¨K_©lY–°.±ÛÙNÙü®¹õÆ$uF¸uÇ>+t5wc!˜$ÉKy~ˆÁW¹UÌÿ >SÍ¤’šÃaWcô#f÷‘¶N™TÀÌÄœßc¨´è½äÏ$ÆBÛKô¢ææúÄ):=AÈÙO›Ã [QT]×Õ1Î!{Ÿz
ª£„Sƒò„‘Àì;¾¸pLÓa.mõŠ7µ›İ5×?8MSét©B¥8q	¶†I¯ºà;“Ş öwjæıùÛ[Øt:Aš—Ü¯¶Ÿê¦û‘ÅÇËÇJ¼¶PÏR[ô3§–?Óè&1WkÁˆú@ÑT3o¾‘”=”%Ø’Dâ%Á—³Ù&ÁœG=ôÛÁÒfÏó¿!FrØ‘	¾ùÉ
![–«cöoÕ Ñ¼ I¿K	ŸÉOÆ£q~âh7§Z8ÉHS€œ›L´•–Â!ŞqØÌÎbÿ5ö4’hÍ2)˜ÕSgO4>q7³¯%ƒDqÓzi|DFg›{yDœsIÃ•ù³ú @÷^m˜•ŞF¾º¥ÀŠzV§m¼FãÔÏêll×cN?Òß[¼W×1tFBŞ4dî˜‡X}ÛU¡.9Şä{í1['6d§§€æªÎò›sK(„àúo³BºqÒ/ØİB;³ÿËäÜåÙê´ß‡UD½?3\4QÀ¸¶"¤ç@2 Hoİ+É±ùA8ÜÏ¾A˜õ†µ~5ÊÓ÷ÂòSS·ˆ¡nÒzó¨.¬Õş÷ıÍZ|DbÀúÈß¤¶^8–ºQªˆ®C¥’ÁZ»¿øÌ¤~fQ lšï’¥x‘ös¥.”f‹´Õ³ªmÏ- üµBŞüßÿ:í×ÚaxsNw¼t&ñI}ÂcÒ,ƒà÷§Ş/5†"P«;‘DOøÌRZÆpï‡Ö-\©Ng°ëH,8!V´ÀúC«OØ±X†á?Éi©’° ú,÷ÕÓ¾’h¬¦³!ÚW*9 ‹‚9tKË…¼0”2»9«‡Á%İ°.XH‚QŒ/\2Uë5·\V¾ËƒiŠFIşV\š(œ´ë„¬?œ­Ğ7Ì9İ…+¸!H$Ô_Ì­È5L…rË'~­†Îû™ëLr‰3İ?,æêŸÌñ£¤¸1%UË¦
ÎÖ©ò<N}eÛK¦Ü¨€ {••Ğæ>> óx?qõÛˆøGŒg„áëlHW^jÛ>P…'OÑs>_ÓÊ¡Q*&ì‚å×å­$ğS4·C—ºB:­[ÖB7C/¦×e¿ó$Ik‹>=;¨ÒšÂ„Î˜ZK‹,«Kfôe©âê	cfh“(?$¶Ágœ©<c¥kŸÎ×rûf!6Tª÷û|æHFebäşA^ë›%©¦nHït.…ÒäÄôÅ¦@?§Ÿ¡‰¨ëÊqs ¡W.…ÛLÈ)}ÓñÓ§bP–í$¢ãòÑì7$‡:Cì~D›
ÚÆ¾ä.Î-fvÈDn>­P®iä±å+#êA~åkQÓûÛ<evvDHœÌe?‰vÕ»‹È´#‰Ç°Vğ.ËîÂ¦¥şÙÁc/IºˆJ§bBWhë/ŠÕİ&ÎGk†])iA­xŠI‚Ht÷¡¿oxñh.0©ˆÄZ”iÖÂ®Ìt:¤ğ?ëÿ/;!o[ÒxkãLúH3ä9­À[&Aì^8¡}‡‚FØ‰1hhñ¢¾†‚òTˆ¬úê(‰ı@É)®åî&²­¤û²Â	©:¤#ãlÒ•Ëé`\¬bò ™eÙ+~«Ë…wAÏíÓ76Mƒ*Èì?ÛˆÓHJS
"wO’ºxÏİvc‡h‚
v^|7ãpäØ·¬ËÏV¦BÂ´óºÕn%µ7bÖ$)éNÆHÊïåşãüyüÙÉ¾57\ÊH‹ŒÙÙ¶ö€©CJµÆø3w0ú‰ùYõ¥FE¾ªd¯nµ°Y©^/ˆ:˜/¯,‰£x/"™ëÈ§&ß=‹Å—ñÒT$Kİ+õ6æ/åS@Åú¬å‹ÊÕß ‚Åò|«·y2ÊL–g{W=¼cô›ºs {£éÁJDÊ,T@“U1ç©p	Å~Ñ‘¿n‘geGvÜzU6BÊ^ûµ>v÷YñâÆiÜ1]ˆMgä!L`Š†Û¨ğğŠEM£ÁIÁˆÃ¹Ç/ÕkÌî©–h9¥tß‘›³Å
ú“³À<>}|»¢ö±hçŞ/®¦˜ç‚ûsÃ«±®¬ã,ÙIäÕ©Şú$öÜp¦wŸ™8ëÂ”õ—‘º|I1‰—Ë8¥­ZŞWYf¶Ñ+XÍì€™•$uÁFKõaéüÅµB+p=õø<ş×.4å;îÀ½`*úÀ¶÷òÈU°§ø`F…6»Ï‰ ½„¿\XHÕU¬Ucßv…(BBéà+›æ ¹¯Ì¼²)gJn7´@ƒö[­qÆ¬–6rvÄÖ”¾Õ,ÇÂ×ƒDª:ä¾ìbå;ªÜZÄËj“ŒÓªP3mEb‘É’¿—Æ?‚a¿Ÿa¾xÎ o§[G|­òä}ŸÊ£Ù/Èïõh§Ì“+ö‚Ä~—¥Jc÷–µ¤ä]\>êRÂ¥ku>ò,ß¶z5.İÅ,IÈPélvæŸí±ú«Sî ªÿiw‡ÚBCÉ‚Óll£«YË5Ì0¿v8È°c°•—¸XÊ>¸	Ú ´4RJC·“~¿ÇÛQê !O–y«ßF|KhÍ	Î³¡èò'Âóéº³m©±ú'"0Ë+(®n7”pDöI5£¡ƒ’“Ñ7•_’1­£ĞLî—ysTgß¶İ†KTëJüÑ>‹NÔ±F†eâi1©Å[—½‹í›C~©'F{ªwü[i²$«ŞÂ´Õ—èçg=«¨–«lS”µBŞ sÃÎÄ©SLÑ°Ë­¿ÚW&KY_o—Wf‡	3N’Ñle„€§  “Ûs?¡ÂĞ]¹Œ“CeZÅ1µ¥¹½z–½»®ıIÜ×áÂ7¥éT.Ïã^á*Ùsò5/é[ş¼ ¹˜ÈfÍ Å9G·frVl‹ÙÅñV×^îè÷·=nÁÎºXˆ¸÷j)ÈgPãò<Î\*z‡µQ…·DsRÅ¤˜æX#äèÒEél_ÿ7ÌOJ˜³ÆèD¾­¼ÕåÙÌm«ÓTêæ‰ÔX´¢©DpL—gŒ9=ïëÕÜ…Ÿ²ığü¾~Œ·éP<0úva±ª»êùZ¬dM¼]pæ+÷á…©÷ßIMâõÆ‚x ÄXTbrZ}æ“lsºÿ+zÓmşLk<À8
¦ÙrÁùßfrx6'By[)€S2´vÛ
xId« Hˆƒú[åOçU[àhÁ0Û"iºzd!ÑCìŞª^ôY#uG ÖU!İ„#GÓHu‡+!²øo£Ú+u²aš:±TôĞ*i>¡HdÌN),B8§dûA.¹*¾ZTƒGòİÉÇq—ìƒ/åy~‘rVıP4°ŞÌõñ÷üFßœGuôw˜cªnªäç§hI‚º ¬Io:¸_zoX3Ó3Ö'g«óìÓ§zZLxb
C2ÃV®}İÊíR ?
¾‹Ñ`<ôpì…ä”N¯ÊrlZ!C½ÿåÊÁ½ö»b%VìÕÑ{¹H¡'¨×Â3ÅÓ‘P¾&d5ñwg¡s˜yy ¼!g-ïBìÂÔ"Û]•AG «°†áœ_„á,ùrÏQøp!²XÔ¹ÖŞ‹óèuj"ÚvÂú÷¨_‘}iJº5fîá}ƒ£dy¯x<´p}şYİ†œÿ†]Ò¼‰R ¼Øa§à½¥×*°tˆûc>uØÇQ<ältaì3Ú
!w¥èdA£X_rÓÔ"LYKNk¼¯üÃó5ÉÙAÕ¡c Â:Ûâ*Ô©ë”P»7%@M„¿‚¸Î@Pm‡µüÅ¶}bz.gÒ˜§u$„Íç>Xh}°*™3™(¸	h#M	è¥C0ôGSØí‡ñéÑxà» (®b™‰ôfA*²!˜Lhe”èG@‡N²úĞö‹Ò‡*ÀğíŒn¶“c™×ú—9Z óqÈ¯mˆü‰õXÁ.‰I{òbI}Úß1_W0„5hx°xYØ‰òWÓÄÉ³—±éş×›¤}!Çë¾ ZYKÌ‰Ç°öPğ”>àñÿä	mømÌ'²0Yè_ì4¦íßíÓ}‚–ªÕUg Ï&Ä6°a‹ı»êÂ‚÷ñLòÄ‡P†èÛ? &_EÁÄàß”GäNÌ¢Zl\ÿfÿÿ¥TÏhƒ±ªF(ëå®(\¥y3ø&›)Æ¢îj.—–‡MGŞ„½"“ğ—¸ëÍ³(™yólöè¡ç××ò½ S2hãö"+	4ë}»Óœ?á®râÂUËéÛhÄ«¨aÅBøs†òöô¬|>Za©´JXVsñcUJÊÔ]©2Ú á-z»u¨°@ì^].£Q…3ÇÓ“MÁÑ[³@,BË¿^•²ÊÊî.ì*h€+œ+áaÅõ:êg‘VmtÛ»Gé>Š|mQ<ËÈ†¹šU¢Ş¨¢…`6ö¸¸K„^Û)”ÔŒ;{øfğ5“‹°%qrÕ 1˜gŸ`Š—óûı¿NŠÑÔŒšÓ=H5(Óª—.¤˜g@§	|û¦?G‹?e×o\;ú–5à.¡gº¦ú¾{¹Èo3TŠ åš;h ³âËè+VmŠ´AñSŞ×*›ƒ&zƒIçiHıoOÌõ‚úgKÒ1ìï’Ö…n«']6£(ªx|­Õ˜†gÔUhÇ2h©£„—ç?9í-È2[²…ªĞÂ‹õç˜U¯\6.³ö“Lï	z‘_€QTä¦e°)ª!ŞÒÔxAWÀkÂÙÊLÑ¹iCOpùïÕM”0ù#Ài†Ôj`Ö®?¶î3@z “°\,$ ˆ œÆ?ægŒWüÃ†›:ØÇİì°º¸ç,;øÑ¡$û=0}L^!)×nŞ"|»çUµ …ê=°Ø•_›Ÿ«Q¡ÅÔiæq@?)ÚVÄ1MÌüHh2Pº{ r‚‡X^ZHÄİğğ~¹ˆh ÄôI×…; [ÅÃÂTxvÒÉRh‚¨àšêÂJ³TÑYÁâ-î¾Ó§¨Ú¢røFÔV4áè€1I¾1@Êâ
Nğ!üñÓ,îP5‚a•´ª×g×]”Ë²ªğ¥®'{ì—z_Ÿïÿ+À£©ÿôÂĞ¸"rõŞ;0‘NèLÓ){h…©Ä3ì×TPç,wK‘Í…ŞÈ}^·ª÷cb ­%‚Íı7(ìÍ¤÷©ÃU5ÏÏ†Tøc©Ñ«=g#°¾Bë4Wr2GÁfM	Og®p®Z8ğÇX.€ÂæÚk½IK‚
ÃHoÊ)¾7i€L®EO:
ÛÙ!)Ã?´ßî¢ÕñínqéH­£¦"°Üæ@ë@-÷ÁƒfHy…‹bç™/|éò»ËIä5<hPâ‹c$ÌùÎÒÅ¯aØÁwvV¤_BØŒ“ûõ“X*À"^#™IÒq!x$<‹˜Ã¤ı:<Ò+ÿ1‹N°‰ªš¬S'@Œ¼<;Úbš’¡Ù€ßø_$n5uúJ†Êëó,/
”´á’Ë²ºº—&Í¾’ø OBşŞÅùêËşãÕLö•az[ŠİoGƒj…ü”éfdDİ+ÀÌS¬êS_…ÜÀé%Â*“ˆ˜Pê 5F±®”¥ø2¡Î¾¾|–Îè3„"¼ElÆ,§Dü²Â³êí¨›‚ ¾Ô~ñsñÏû_ÒÏ§ã¹üÿì;y¨uòíÏÒ7†÷„Ã}gSÏàBãu«6³ì¿e]¸á…wC9OàĞÛ+âs ƒVÈk.~PeÑÔ ÎÒŸ£Y÷ÅÙB~Ú9Woµê§Ì¦£o."-»h‘’Óœ8vĞ@ş™¦‹Ş¹,¡Æ±ó'ÚÚö†{qá†"¹rD>ôˆ Œ¤¨Ã?â»ê#¿ÏÚïSî0H*h²^U¼ŞÊ{Òg$5
Ìå*»ïæN#ñÓğ¦£´vvÜÂ³ÑkÒƒ¿mV¿ÖˆÕ/÷õÓbŸ‡N°ˆ;I³k'õÜ»€RyDnºEê¢(õ	Ùn\ÙI‡õüÒÜà€ ÔÃ@c«dŠ’	S2…ëRqOß+ÓÇÉMEçúÊÙ#=8IãoÎ¶^òÆES“;¬È]öcOÒ‚å'H…W9Bæ¶©ÿœ/Ô;&™ègõ%í¦¨C4#î™çMù,iü—7vÄ$w³j^ë±tÒ/ò6;W™ŒëîK‹ŠĞŞ•vgY½dñheÃliƒşkå#]•ÉĞ33ºhä;äşâ,‡–$7?+Yu­‹&³Á†«ĞkåR¿Ìí«“¬}Œí$u *„!aHğÓı‰d'¾°§è–q•ïøáì­æ@r'•‚ø^Rî,×f
¶…#H½wŸzÔ5v\÷Œïåà%€Ó;Í5åvYèÃÄø%NÒh¬õª:®SÚxØg­eñĞåJf‹$ŠĞ‘¿âğXGô~Õ’ôò)}û–‡²êk“5hÜÌ
§jq!ªaGO‰6T¤È¹³N¤õÆ½û7„ËÚà›Uuô®Ê]ë+FÆk!vÍ1¨ìïƒHê÷¯ë{2Z*Ltê†ı¿ù0ó,27šÈÜ£İ2‹ÃÈ«|ãøğDm»ÃÅnØn#³ş½^Öëä2˜¬:dæ´Á¡†úÙ©ÛOQÌToÄïÜb£·œ«]Í¨œÁ#oW¹m‘Uòƒ Ÿd•­d úÙ1~ç³²:!ê¼4;†\K|Ê†}1¾óM®ü£ˆûMÍ>ş¾R3H3Ş£Àx”‘ÿ’éÁ€Ïä··›HÆ’½¶¸ÎheDguĞáõ|œÎÚ]«–'J‚û;Æúz”Ì&IŠPs„Ô.]ÿO{aıÿkr(“ãîœîÜL§Ó¬¹Æêˆ…”I§ıÑwÖĞñä ¼[èI2ïBV½÷í¶÷J;Ë.a™;k}D¡_Ş|•éde2Œ{Yâ¯{LòšWıé%W„:o8î2êöeéÈ¹q‚KmÔiÏU{ØŸ¬qlß°dƒ%,üev=òìp¨Ä=b¼Â? @„A€¶îÇ“fSöhÆÁ	ŒV4ÑÛ—äŸ–5BOãDÒâÓ@³ˆ°µpshĞ!ŞQoç	B:li“ÇA £Ô®á8Z „’"kæ¹—‡[ìG%­°î¾ù¡)ùÕ½:¾à1İ¡¬ñÖù½ÖQQA¼F*àï’r$ó¬ÔõÎ;Â¬:‹øàÛ'¶Éá3¥6ù6J•B¼Ë¯ ,,\T(å²i=çu0Yå<•Ën4›æ2òìğª‚¨I`üai~àIşiÏ‰kè‰±]8ù.›%1˜ü¡¨šòSÁÀöè‚ÌFkÜÕ.ÇËï¦îŸÆ)"½æK,J ¥Ú›îš¼ÍÓ©…ĞÉ.€“…Û¼Õ˜ØöDcàig5ÓyÙòÁk­PŸî^ú¶,£
œÇ°8r8²‹ÒÌ³ªKü©È|ÙùØ™óÛƒ¹ÈLÂf4–dõ
§TƒDÙ Ûf”Åî*Væ²¯¶¬|r×ºÅt<õz¸şdÍ.©)›µÈÂçH2ƒ25é0¥¬ãi^L’8dNé‚›0Ôï–§ºJaOfOüQäD+Úºõ¿UÚMO}It©¨‡ÊÛP±dÏXY°Góh"­¤¼ŒÁ wş2M*4TÄäTix€É‚Šü6+»‚š÷aò ~Í¸%Zn³ÂHØ±Iø>¥øUümªIeX¿"ë-ØÚC?’ı?„(:_Á]D_šC|Õ—£{‡—ö]H÷x˜p.Ó Ó°DÓş‹tÒp€üŞ.ˆè§Ù°)xËñì€w†Å#Uì¢™&óW-´¿Ó‹‰Ô>¢aR›_fç#¶´ú6ª3â¢€&el Ä´¬ï²ÂJÌ.ÒñèTxbû „d§ĞéÃš…ùlíœqõM†gÙ­ã´ir2œdOÓˆ¾gD‡™+æqÊ&¨hÆúx³"çÇ#c—§ /¯¼œá4l’9[!‘Š¸’PW™’­N¸è“ı	7Æ§¯D½BVäFäÕ‚‰SRˆÓu?!â[=4/ ÓÀNVŸ[×—§b— şà±:…
»öÇ^£så’Şöâ:ìmãÊDİiïWĞ“—·Æu*:|bUGÁÖ„ËpVû¡Û!î(›ƒ2V=*¶-­g*’A6óÃ\\[E#$fÄwé*Šu÷5ßó¹¼ÎE¨¤%qÇD{¿?Éx£oxy¸„{ù…XJô®ZZl*ö(“¢şêˆ*‚ñ‹r/„‘W¥÷"ĞŸDÎ5ê	İú¿rŒŒBÁrßÁêU)VSª×’¡¦øZ8É5SU)mèÙ=£vÑµ”’xªXËKÁF»%Ú‚m‘.LØŸ¤¦±"wídJã’<íÓ×ır¬ÒLu½¥–“½A\4%>ü! ğ¯EbÕ("5Ä–Ph![oéÜÜ4ÔZL=¤fËéaømP·ÌõK=½üÄUõÒşá$2óA#ïWÀ´t•C:C°VÉstÄEÆ>ap\±ÊßÙ%US†a§æi«]uøÜˆwØ‘`a”G‹NJjÿí0&EZ61¥©r¾'ß¹‡ÅÛ…ğ·û7ªÄ
u6bDxÕØQD7áY=RºH!ÌŞr²Ï©LÏPA¬Î×©±Ó­’:µÔ‘|‘c
›+ kB51ÕÎ6Ô¢a#ø"éE¨˜Èh%ÆODşUàs=¼şÔ†@Û|^xxŒb“RRˆáÉÖs)Y€-OØ2Q]6<ë0Ôor3´%§ıNK]‡ÑÁÍÚ)üƒtRd)e±æƒşó¤+Ça¥÷õr(¤-$@|ùõÄNy?H±Ş@
ÿöI `W»¬îZq.]"»§Ú¢?Ö£‰ªÓVÍ'˜(h€¯F5SI-:º¡™÷çY•ñ
şŞîÈN–çÎ '¶8)à_±g£ÏÒ‚ó„%Ì)ËÀìE‹/9şõ”~OÊ*
V”–ş/ Ñ9¹æã®ˆGo %aRÂ¡†zWãíàNréãn·§ÉL^³Æ^Ùx¯“¼ßÑ§ãaz`RÁR6¿f÷…@_~Â»oÉÎ%üëêú@­ÀY®S»ÚìîÊøJ»½KY2åGè%LÂªú«À²àSDÙ-èÚÌØÒiÅ“-†­U¼»qÌP÷
1²€Š³L\"aBI6ì¡yvH½Œû™lTGj®&U¶_p£?°B‘’ÉCÆ5¬—gŸ*uhÀÎh2EŠ  Ò—säí‚N ÷Ë€{Zs±Ägû    YZ