#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1558297302"
MD5="0b81472c6d82fb5c129148952124c0cf"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26004"
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
	echo Date of packaging: Tue Jan 25 21:10:04 -03 2022
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
ı7zXZ  æÖ´F !   ÏXÌâÿeT] ¼}•À1Dd]‡Á›PætİFĞ"y/j±g:¢uéİ&BÄØQ ‚àªÃ›ƒ8ÿ2ìéŠÆêÚù€-~¾1Ì^ï’òãwtD´Î›Åv?€äÁLŞío<s«S•PÑ÷´²UàVÃ0o;´
;!q>nè*1)xMx	éÎTïF~‹R]ÒvÄ¶\ˆiÓÂ_¹ËZ]ìÚ+³LC²Î%p@„ÕNùÙË„ÂÙ ß*mŠx*?’•ÚÜı½T±õø»ª9o®”ÅøK„jÀ††‘”0ãŸöNÖå1/Lrfğ²×Ğqıx£ËçÿÊsÄ}óÉ;OqãõöÀIëµ9Ä@ËŸ)Ó©²¼rrÁ²ØQ-ez\µĞ“½¥*3¨^)xüª>pÛ«Ş³Áá”;y‰S1u2.h¸Œ‚`Õ`TI%‹,bøÕNÈ8èÁRŠŸ€ş§‰MÆĞ£`"ÈwÅc§ÿG’ƒu€Ö°,ı?;;™é”ÃnnÒæ6Y´“iQGÚqò“šçoéÃË¡1Û»NÎ¼Õzã &A€öÎ2e¾8öäíƒ¼êc
ÜÚàcŠ.3ú}³ƒĞıÃ¡e´°/JtBÚÁ2Ùİèõhà0ã‰†,i:qÁRü*–ÇpóßÖöà^}å~G1×í<Ú	ä›ÓF°7ÀZ:D/5°eÕäüqVEf¨‘mÀZ¼Sÿíõ›uuÏÔ‘Ú»×é8LÄÑáÀÎG‚	‰Z•TŞÛƒåÃ##ˆıËIñÅ‡ªã¦¿&Ëb72³9tüøBÚÔB¡©Qïæ!†iAö¬hÀÅ²ŞûÓ÷ñ¥Ÿ$(ƒNY‡+ÇLdö­ÉTİ‰ë5’vç=Áî s¶t8‹Ã3#€YxşÎ9mnYj²1ZÏÈÚy¸\TFÊh½Bc}öıÛĞ±”©	èE †FázÊ³©U¥÷?ÃpÙğ	b_ãÍÜ_T(Ê9Pß–ÿûfii•Ì!æµ´&µÆr=Ôtbúúåm|n36Ò)ŒG1YÚ#ñthö8ÅSYqµDp’YlX§»)f]%P•‚ßC¬QDÛ¬ÎÂÃ£Uƒ('èöç¢Î¼É¢Åò\I– cö2ğèÌDÁ–_¯[Å7)ÛåóºÛgœ"m(ÜRNT¸)ÎœäİşëÏ¶;õı‹c•–ğ3§0¥‰T¤>eáÜ;RNw=+¡K?‘¨lx-ğ5İlºŠÇiÎÈô~gÎQœ?›à©ò è¿W^bÎë‘KuOµ¹Ç‘Û¼ßjË“¦<C¾4)Yzå/Ño¨ı¼®w[‡…ø Ô	z¡5‹Á4½gkO¤æêƒß²zÊd×ÄôÊvuœÜnšU%íD!êÛ4ËGÓ×ÖÙmİ×®±V÷[©ç¶´ˆæÏÍ~šuôçeÓue J•…_ëÊ£,õ¨÷ÿ‘$åeÿ)Âyã·—«pAÖ«	€MC%&òp£€¾Ÿ-HÁ#§Ï[%÷v€”Ö¨OÀïtÖÌ]±¬Bõy­Õg °£¤©Ù1ÀœöœÄ»CÓ£{V€å[qÃÅÜíq«A¤€¢ŸŠ^ªD/šÃ6K.»£*_$WqGøˆïn.ÉlæwoŠ} ªa•jRÈKWP¥YÜ(@İ&ga°C =VÒüÀ1—ŠPw“ø%ELœ)ÅzSÒbäàÂîW:u	ø.1~“T@Û£/˜4ùÚ¼åkhtîÿÿ*(ƒzXÎC'%®1•&)‰Í’IM°w¡WMq6Ï¯@¾ÖÅ¶Ì¹¦}”gqdAˆ	â#.¯lO'Ç¬` ’ŒnyÂ¹LzûÇšÄ7¼¿˜‡ÑV0ÚmC×¿c_U9¯ÃÕ –¦HJ˜•-9µ¿Ó¡’ >mlA•{jg[®m;€]WÁÙªJÇ½êK³Î(â=óX	M½²L-
Õ°*ÔJns×Eh,¼­ò¥àû1¼ÍÙñ1‚wÿŒ…:`Ü©áÁg•vR`&òş÷)[²¿eoq*ã4ûûİ"Šª0ñU~@ó†VÙ¨/=]üÂïCŸ«×~Îê¸èş:E¾àÈ·º´§I4%âñ¹%e\µ§ê×Ú}òä„ ïÆğ9Œ¤ºì	¨ê$%÷Ô°\âÉfÓ‚ƒK’,voQ+ïï¢èŸìßâş²$®ö'òêåãDÒ}ïo‘mQ¨œ¦D|‘®˜%hR/Ì•‚¼®Â16¥¼)£ÈåØ¨™‹R“Wå"cÿËİã»><`YoZĞÍÙf_ '*GÜÚìu3%V<mçmÚ¸)eÚg`YÄÙ ÿ¨Ã“AD-Wœ),†ñ¹°‡@“ø$ æ%+tHùo[ÓSÅ	îË‚nøÉh¸S8sİÿlá(vş¨&=<¦£tŒw„%Œ	Bu§šc“H§™×û^Œh`¦¾ÊZ~¿¨Ê²\‰Æ	ÍàõºŞì*®_6zÄ‰£:{Ûyu_¾¹Â‰ŠvS„ìÒˆ©^º ÇÊE<IŒ¤’xW^G…umŒ[s÷Êø›ÓMşî¸R}Ä Øólµje<ÜB¬t"¿‚fŞNu®©¬÷×”‡Iu ŠOømª‹!~s½ù7ô³¸‹~—[^s—@h·›òÌØ¤Ú1d÷¼Äph~ïúŠSc›Üªp]fî¸ÿP[säæÊ¼d±ä6Ú/bµ3İ¾Š¯ØÒ©œÀ«5Ğ)Š'AhõÈ_-…§ŸÀ.ÎÅ”¥*ªt%æªûI–wxCr°B{c¹šo½ÄbÜ©
/ç›ò©Pî~DûÌ.9›yHj»6‡lçx¦|^R¦MÙ•ÑÆı¡]`æéfäÉ\HM=l®f­=ã¨ï£cCWAÍèÅpx».y)zÔ‹œnˆúš
øMõÜ™Z-¿»İ“µıQZ’É¯ö(ñÇšƒùLWAÌÍêjÂ. 'µ¾bLš¡”2);„ÒÜ(Ç†c„8……h!¨ÓJáü ZI¨‚ú’xeß(7
MÚ³-`ŒÚz/ÆœÁ=³°¦gXĞâLá}³LîÂ(Z¦¢»yøÿ°¬7Ús5…¹“âr>ãÒú= Õ—ªxEOPÜ9öıyÏÙ}.CKB?3ÈûZ°.èÇ¬O4-B;·jÕ†„:ƒèi5ÓP)Í\ƒTÄeØÒ²kd\ák9ŸßØJ6w82ID1‚æ’Ğ3Èœz´5ÁÎ˜EjRu.#¼Æª¤xŠAg¥7!_´íÒTñ~7ñŒË\ [LßÎrûôJ¤õôiÊÒÖ‡ñ`§Jø¾Ï~
‘‡ğÄäÀËè^;Ô3MC§:%uÅõÂå6ÔxS¡[”ö¬­ƒf¹ÊúÕü<w²ëïW÷z²Ì­rËw'UÛÄÏô”§eÅÓµ}Ä¸®ªËÏyó=sƒ ô3–ËÉâm¼åîª‰øe&¾”-Ù4˜”‘¨à·Ê­›»(>VA±éËÿó1±ú¨´néÓk“¶´ØJ•²p^¸¹>{B@¯õ†ÙªX¾ÕX_ÍÔ?ï÷ôß0Q65Vh’ºéÁC¨o ûøÎğ7í]~r jéb»s-Qêr +XW±ŒÑoq§òPiÓëŠúj"ÚÿİùSë†}°æR§|š_ò“©iQ’à•)ÆáÑµ'5?'kíÈ;ÌŒµj‚9kÖã¨	”¡DÈ &Rôõ>Ò,b!†è­UcŒ­UÏåy×ì(×²hµñ+…‹IÍ‘ãğkãkùs¨<ª)øK{ğóÀ¦³$Õ!ğ„Ç­ñ>h'ü­Üı%‘u|Š12^wåm	eö*£òcc<kÎ»Cà<|$ )­œ¯ï=ıØÈCÍĞ«µ*¬€ÒG”G™üõÚ{€†7_Âšñ¤šƒ™u‚j
cÉ¡”ôD‡iKuÉ|–tò/?ª,£ø-ò–±óp²Å+½0·ZŠBøÎ{ìRñr[L £ÁJg4AÌy†‹%îØD”‘ÿÆºQ{K3Ğı»¸+Å ¼­ÉöT¸F`¼˜øŸá!æ²‰V|;¶âp/³}m¶N_šry&]¹îd¡mÊÛÜ*c„öàŠ“ù|9* ¢»ç¡yx¡²ÉšËE¹CÄ43GƒeË¬#‰vo·dZ£ŒÅÃ‰dwz„¼
IA7µ=Kúw(Jçïª<xß‚Û`‘æF%ó²‡"Púß”9½–‘®Õ—,ÿ¢÷´¹ˆ)ê£>âz{ï¸äÉª´2–¸ÛS`Í‡*bèú5N*Æ‚÷]]á³§dı)ú)În6+L?r<SE9¦Dİ8°8~Ûî/%’}a6ßìØ1Z"~¦ä!á…}œa¥Ëw¨í'lÖTuGïjVòÈªXXED„/ıb	ÕÅøï~˜[—Îf{Şj|€‹.Û„oõ}Òùó>)^«¯ş÷ÅeÓËf³
¸æ³Aÿö÷gÍ$ ™Ò¸!3ı8Ä)-6çz,i9XÖõMOmğFûûÎSY.ØlÒrÌvÖOEµºUæ0M=Jç€‚LbcÓ1ğ,qê½:Ì„0/zú…•±òÕî+•æW6;É;´dç 6E’×s(ùy%†_Ïıª"7©Îr sÁöQÛtå
– wƒùéHÉ
¯»Û€/ñ—^£ÙQãBµTÏ£Êì½+X\¸Bô) ĞÀWUQß‰ù)ƒA•ÖÙ‡r
uzY§T|¸±á{°f-ğÒ:yÅ/ÔNİ3o%I\Ÿjè×_s²1
œ‘QØ|@“ºäÁCï™è$L\}CÚwMØ0ò©cMÒrÅ,ÚÕ§çö™‹(,ZŒÄB>ğ‘šÀœGâ€}5 Ö)«(I‰÷Ç È_ÇS]%@´U±l4Ş´mÛË	&ks¹ƒ´‡iQ¼ØrŞC¶Ä—+oÿT³)È{Ë“j÷bk¾“ö¨›$&ª7%@“O`ÙşØz'pÿ ‘>©ü£"~ì³¶Í,}3Şï¤æèD°½Wòõ§£™GD½ìà;¢%‰ïœÀíß‡BèeK\Áugr¢°!ÓjTÎ'×'ÏÕ˜f[Äîg©÷ª¨öOğ–71m(­á•Ë‹ÁEÇ"ƒ)µ‹¯ÿR]özÎ"%T¨s©@›Ùş’À¹õ&¼D—1MƒüõÀúuå´x6y)EÙ¦<?5‘¸n9y+~‘l­dÄ&ğÌ¨ğ‘;¾ˆKg<—^yùAŸëÃ†Ùô74k‹nÂ›÷¯&	£a/ê ‹7*ñ—b¨+-&Ÿ)xÉÏ%dš[¤¸ßéŒ[¸ëÜRPC¤t0oš®Ì]:$äÊÁu›§ûĞÄ: IÍ)4Ò,¶ôTîúw94Ö”S¸»©?²ğ/Ë{Î_“Àû`€”OôO!VB+,Ôy/Ïâ´c‡o"‰=ÂrpÙ*ımšCíIÍ8Áş¶¤åÏRõäç|ÏÂ¤û¸X'Ø™Ùõ±ŒËôXBó«h+­ÑK:x™.GÚ±	F	:ÿ›ß«€ 7fÊ^y?üO-½rÔS‡üUòƒÏÚÆ>ğEøíù7€˜^Ÿo® bY:T5ÎÈ°Ş )Rû™~XPˆÖefŸÇ({¸¢¤^Æçuüüè&†QH!—Ns³ëË!Í4ğ"ŸµçÂ©C^ß08æˆ°Ö^©Í¡ÙŞ6®ÇÛ¥¡YÖ´Á9´v1\×~—Ü.1ì&‡*ü½¼]EQw—¶PR¨Şuä•øÆÚÕ
'Œ(-)¶[Üÿ½Ár/\ S;y¹RQÎ,Xº—)„>i÷–÷ûûEAéæU‚èk{É]õæh|ŠÍ”EoÛù{œ bn¼³Bs¨ØNŠUÎ´xK?Ì7r‹=ßñQôÏo­œ’F×"…Æ^[M%lœ–x¬%*ÚúöBSŒ2µ³£É}_>ßŒğH¯²)MND:dØ?Á´
;—=ª†M5Ô^6"uT6û5j¬t ‘†êå"&ğx(îHbè	ëGå²ÏÈ€‹´×î÷€!Ñc©e¶ûŠ¤´º±jíÔÒÂ‰Œe—{2çuJŞXóÑ5,¨ç£—Y<!½˜ğ'–§A xìuĞö$wJ…nb¸X’^l ?Çl˜ïÅÆİâÄ§*×=w¼îàeQêCÆno½b†ô%©;
•¸bÉ™+Úìâ¤7{;ÅKX˜t`<ÿ†÷‡0¬Dà?aå†|·vsBZ¨ëèl:î%æâØP"xĞ`ŞLáô¥òYl&†|ÀiÔaÙŸ•è£ÒÂ 7	Åã5å“ıü(÷œ©ËUˆÃv¾?(lúk>W „W¿äæ\ùz¢r³«H®Æ”ÌŠpˆûè2.›IÄ{ÚŠ‹_mšh|™9“š	€b¡€aá5=%#×}VoÔ!êİå‡!¬Mçå9É.wC'lÊĞ ›/:•®Bi++A˜v¿ÅÀ
29ª&\¸Ê¬MÖÃîÏØd÷‚ã–“®Ë"“yGgıı©õhJ:Ë˜´Ì.·Ü~Ü%q^–˜÷:§@ÓÆVµAû%"rÖ€ÜVĞË£¢›nûó˜ªy‚+rD€œø¸²ÍòÃ# ÖsºªXóFÌV±Öi×•x'îh.Z{]wà0’Ø «Cg›³
"ñµUŠÜó fşÜ©Š‘Ñº:nŸß¾R%æçM×³ƒÃ*Ãº¼ğãC³»³ˆàÈ
ss®8Š¯Á½f(9c´ğÜ`B­uê7_ZÁdĞW–gq%*«7«»Î0™°GHFvÁªb²AË×´û<é˜Ş7,.Ú°DÂäƒãä¢ç<-±bèà"¾aÄÂØ9×dÓ@W.u‹®ÙâÃ•ŸşB2„nÉsfú©}¡)9+,¹œŒÿ"ø×±FšQùÏ9ü©ÉèSïQ¡îün„³sH´+ûîœÂK¹.ıU±Ê›¼(·m"Û˜S¦àçÍb/¾Yˆ$ŠÁ3]WñY#_î!uˆ! ìM>òÂÛUIîcE†ĞÃ,¡Üüíô‘kˆ¦DK:)¬j0Àè2âN7Ì²³<e!§{Eëb"®%Î„(ÙcÏØ»
İl~8—« â&YPTd}%–ÈT¸!¤K+šç|ÛGÿSbµÁ['zÀ=GZ“X›µÿÆ|¿Rˆ†ìæPVŸdïrF§Å¦¤VX0
êíú¡ºè‰˜aøãK.>gb†8ü•À Nÿ;B“öU2"ì¹™Û'}İÔú(à½è‹ˆc}¡ó¾T /„Ùd7º*]šOJÙ‹Ş=7gOµZ{yâÛşD–©˜Rè;,&Á•ÁÇIŒ|ãŒf»&år?è¿•ß>ÀqšÚ8Nœ|¾L–ã¼?	§®ÒpÌy~ß²·:ßÀnÃ$ùWÇÍOÈºŞÌ`Úbƒ,Ä–X«ËéÑ¹xQŒ‡t§ø'H¤G°+ê`ä
ª¨ù<àÌÍl(»²Zü­YXuËî( æ,ÿËÖ¼* İ§½çàC—œ—6‡µX,şF~“WI3ÁÔXÖ|»¤ÈwD’–ã3ÙÿŠu—U‡ÉW‘?×ú¸§İgÈp´?É€5ûÂm6Û¥L€rh<W5‡HÂËeì‰ã¢ó!€¯‚6C{ÒZ«­
¯µ•±×=’aîBnÃƒ,¥ôÌDôí ‡¾Ëj3®*ÿÀ¦ÈYMÒ…œPr¹”­ÈxÄK¿å§yŒ+®!®ÌŞU¶ìÑ’=À˜A¥ÎYåÕn®”›ùêà‡•àRœZío@†¤A/¨rGíNÔãŞ¶@@Œ™>	/¼*<Œ?ÈèÉhJÀÄrnÇ¡©e 8rG—ëòİšFÚ<¼‡óæ´
ã¶;/Âëq¶µA+JöŠ®O­v®Öæ^H÷'?ğC‹¦iì…Zˆ«ì1ãcB>îò)MÍæÓéòkL€§o>ÈÏyÓï¤-©Áp†›ıOš¨?@Å—$~ºYÀ`buÆÇlÿí‹r0GëÏÓô4V¨|±µ¯yÂ³œ^\±d/-0Z%bô¿ÔZ‘²l%Ø»‰—»9~º˜±Ğ˜éwiÓ‚sŠº¨Xîu÷æ>¨Ì ¶h8…°Ww„2õ¶lŞ€AÕcœcì;Òÿ‰6è*üIÒM=ÜYX¾_ˆòt/[wiŞò§‘mHRû4ÄL-JÃUØö}ñ=ZÂK™SüæRä–€}éRå3m¿š ˜†İI+ @¤ºÿ¥¤O>Ìå%ˆL³§*=1i(E{-iSBş¿rêcF* ,€õ³F¿‚æ+ßx³nòÏ¸ÜüÜî	VŞ8k¾7·†¥šıÅáË‹=, ÀÿQ³éğŞéÍÅÌ¥¶ª÷’âŞ‰Û3šW…†oPK°Öscx"YXJÒ¦ÿÂUJ}1¡Åe]Ê~Çÿ§}MLâ*RğO«ig~äÊü^sıO¶6%úC©¯õ O^DÑ[H»NÁfq…´ØX· îÎ³f´0f!ÿ–»k¸6¤ö¾ÿ@ÃÉìËµà¸ÑoçŒ˜}ñ+•WƒwšHşºqk®éû6™UvŠ°)C*$€t¢ái¡öCÄO(VØú'´'KšÔ÷dèÁCò7F‡Eˆç4	˜`TAT 3Øğ@İ<ÿ‘Éµ9[ºtÑE´¾ ëí¹Ê@üZÂzp–X×Óè¡¶“Ä¾$áÉÌ&!×Ô¿¸Mú1F‡›ó å1¡¹zŠİ:FÕC’“pEËÊ*ª° °"Ñãû#R û¦0ã‚>xUqšçõ¶Óe·"İ‘@X)ğ4V¨­‘¨~'©|`6„‰I¹Ë3<Ôª!¸8à»¶jŸ·1]øü´mËû¸¾­è’ ±âÃ‹©X¥µËÓDtÍã›®tîÏ4Ì³õ‚±Ö:_ÄrÎT”¨4y¥W¢¼ïwIà´^?ó¬eÚâB5ˆR#¶İ¦JZÁêşGˆšŠS›+¤è‰”:ª»Ú­Oóşfg]yD¿ãäÛq:rßºÍb¡<•3^óOTÿ’•[{©î-·˜À¨1·üT|Æó•
> ìÆ–v_*Óqõ”õ–ëŸÑªÒˆedÎè‹”cxõwË™Aú6éœn<ì>1¤Ö—]3$¹úæˆ:¦ÛÏêÔ
còkTš>aÂM²¿JŒÊ 5~ŞO]x/%ıÇA1oÀ"gC0òáòÇ¶ØÃO—OÊ“ùÒ™gç(f.ìWk›o×,Yú6g¬s!-j3Ü¥Ô¾»ü <ç
”%¤ Ì8—®{Œ+fèlÕè"ÿµVPö½r¯¾šM–R(œ„ƒ¡FĞˆh9ÅÀpêuñôkHyâĞ ™˜[‡Òò(à/ş²hHägåã5ªEİ¿NÉTE%ÒkÆ—9—4¡¾ÏÃlÉF7@ŞçL;o›zkˆĞ1Üş'ŸÑ
è)°^Z ‡¦M¦¥(&T$ÎDg,ÇdêÖ6wšGk«Ñú€®–›z	fé§²}"g¸˜½üv2úSfœ1ˆ…ryĞ†Šr'™®0”Ó<šDNrÎJğÖ¨Ó¹3~}ûµŸNZ=©l \ı­ã¨|À‹ô&¹WV»Œ äœZV\3¨­upÄn%Dª5O²) ¨;)íeì‰6n—Ó>÷¼ç,Aj9Z#0Ù}Á£M@¡:Xë Åq"A…·±.­µõ¹}n}¹åœ¼0í…ö#$w?™ÒÎòå7>ÉekRçØŠTûYG}ãÕÂs^LúÖMƒ'«šƒó¶Ü0#¦È¡ò)v-áLjû²áxXè¶‘LÃ£³í|ú gšK>ò—ß1ÑB™ş-Ñß$2?us²­>\ógUpp­SÀ»‡J8˜g·pÃ õˆíA¡Hf²H´œtÕ%İ¢½Bë_\U·àÈÏ]]ÙV­ÒJéúw”!?±•—%_ÈV©¢HNœM;û6ØkŞkBıìlß±Lqı•¼FO²|VÉÑ|÷Õòh,L~w§QaU#Lº½Gµ4¾É€jP‰Û.’Äğ¹[qƒ…Õ½3J·aTSFûHb'%™Õv<B†ĞÊ^P	ÄÆè>/>Ë~Ç}5Šá€{Rú°Dq
¯¸@–­Yà6hZ°BÓÛ`ìÌŸ÷–üÓ7™D´íÉşÑN‘3£Rˆë2| gßtmşç\¯ŞK·À]Zâí˜Ø×ñƒ–‰éüÕ´|¾¯ï®›‘¹1µ
bÇë/As\F'‹t–¢rKÑ®Pq#_ Öir©#cm.9Š‘5£ZÔG+ø*ó§´ìä`4ıá]@a‚›z À¬T¶ù¼lGÙõÚr¹YÆ&[ì˜òXoqªxÌ–R·’/JüšqüŠ¸$I;frryr4Dà›j&‰TòÜc#¨©Í03ŠĞm·ÈÛG²y¬Ùîİğìòi¿Ğ£ËòQŞİ›KÊÛÜ|Ø9ßß»›£o$v*ÁÛFÕúáRi•8kÚÅdšéÑkÊ%x7ğOPêÎJùZØ%w˜™ÌÍĞ×6BKÁ†ûÓG¾&Ò-½ª°°Yf:ÅÆ“]BWüÂøúW¾rù_•—¶@­¢CJJæ`4?¨Æ`~^„'ß
Tò£	Rn§È­¥C…Y6ZÏ²{9è-òîYŞC!SÑŸı–…Ä­«[óF6wB‚åH`‡´!Ó?mÁJö“Ò	ˆìs=W÷ó•QÑj"ıŒ£ƒÄ'Q(ƒ¿J‡ï3Äûnwé¾Ï2|#êÃ:2 ‰ƒ¤Ü°7 ò1#LëÖS4+æn±îB]¯­~~Å;ôéÛ‡JË
lvç<åôÜ»İœ6·áK~Oëuä&Lkêñ¢²:n'GÑÇØ1m„×-1~ÿï\#€s`„nºµ÷eú1&«JöÅ:;L‹:Eâ†·õÜ×C®î5ªgQ„ÒÔ~8ÌóK[s 0æ]NT.PAü_ÊRŒáëäA“y
Å˜ÃèNrÔ²gù–Î&²ér+”V§Vt>‰8ü#Ô,ÒCz^-‚Y·«˜“*/Y„‹İ=Ç>:C-5UK*ï^rÎ&ÓW¥Z…P–ƒ]¿tå
Æ­ªXñƒ4Ş	lòTQËpk•÷A»¢ÖŞ ^rÒ@ ôèR*ÉË²êåÂŸ’;”d	]şê¯Iå€ÿüİd[D)2šşVğZ‚r•gš+Ÿ9<h~•<µO
•ò¼9$¤JiYÉ¹¨ŒÕµa?´§8j1Šıl|É÷z‡Ñó¿Fñ·%îïë_Y‹Kf´¸ò·×ˆ«^û½-;K¹{¢¨Õ}F»©GW©ˆpaäöò}´Fû
7# acõ¬°‚K@x!ÜÖ¥NÂşÉ~xb4t_ˆ¼I1§ïaï úxÇ†LÅ¦WB†áW†^&Ï¡“Ê»–sĞ£„wNÒ	^£ëV¼¯´ÓPˆºÖã1`„’§áp Iı`	^]·Û!ÜYñ('şT$Išl$\ågğywÆy„¥"oXŞAˆ¦í‹“f`mW5U\´Z7¸ø'}¹X×púW‚¸`‹ëñúÄ­¹g–/~Ã‘~°]Ÿ<,°Ê¯tp6nÚˆmf…]€ŸŒ²æ•º•)ÿîwôŠÚ	wåwn´šX˜ZO
Gâ“Å(!½¾7ÏØë9IÌ!ÀéTG¶(?™“Œ*$ÄuğSŸùWß)gÙtİà±“üß7àÓ$éã ®%`WØ_[nˆQ K~î|}J’2—“B'»%ÎBî¨DxdÜ—¤âX7ïÁƒ²›äù*ï›ZªxAS	65égŠ?=¾Ì"Å¶¶õ‚ „vhù€4˜Ë™ÄaFÿ€~ÊK>b×º‰ÜäMñ”£q æFß}OÀÆ—©l´!¢õ‹ö°¼4J\¨:šC«T‚Îâ¼¥`5i+ù(3¶|¦–¨"Ñ!Üï-˜C,c.mğª30¡ÂË•ú*M=áLí0é6Ÿè NÇ/ çR1>¥ñ›B"ÜÀÈà.h×¶´è^¸»,V¤İÙ¡óá´8‚X§,Òó §¬)–“eÕåjO2F\¿â»`¦‚%U8¡ş*7À-ŠQí’ÁÉx%eš€Qe]¶Êúö?dšç&±S“ç¶şnS±×/|\ş+GFñöãF”UAŠZÙğú*ÚÃàÓå]0ÃaÈ¶ÿÇ!ÁŞ=O\bb´ÎkçñGNè¤¯ú…ğM¢ÒWOldÓü—@ˆakCÉ–btJªb—Âm‰5Xê5®Y³B¬õ0°å	8»ıˆJhS¼q´Ã^æl)ÓfİXG{XG”µIäAÈó2½ÿı[”ìĞ2Ô?ÖîÇŞÁ7E76íŸÂı¦lé®§ “u²K·hÚ ŠÂjùLíÃ#5xË¹1çpb¤JÆÿD±9vÚFİº!(ÍuèJKgØäÁc¢Ò­¬xè GZVˆâLêÍÃ¤d–S•ÃÙHQóFd?„!á†ˆ~ågZ=í”0*<(TO>ÇÍë¯÷ùÕî$ºú/ƒ¼U¤òGß¾+ï/QˆY^.\|”ò’p1“èò²¹c¯¤®Í¥y á:b&:åĞ½‰wrÇ’XpOõğòpVÌÍeñY¥ ‰g¡’ª:ª`³ìƒœˆùVê¢¸œoˆ­9A³?>aôUÏaF4î!M˜±Ìq‹Êb–JW\z˜{í¹Í|}·6î¿"UĞì©ş`™TâÛ&¨(ÇHOİ)°£Ä:¬ÚÉªA\¦~WmïzlŠf\·M§êt»œÀ·u,L¸dÌŒ°ñ¶j
İ†Y²•™t_ÙU}5k_ôÚÃ]ÊpÁÍ…„$ë{…šœ;ÂÙ“tÅ8k5³>®ŞÈ?˜Œ>›ß—z´9ÿòh7J\cTi‹,6CĞ‰´Rn»#%á“uÜTê!`D9ˆe¡ÓH½¼àI*«ŞÂÃj¦8ÄÙğ~ıeŞï¨B*µØîn»hI	uOS±ş#I;jiÄ1£èwd(Ó=ÌEö·ŸIë2øÛ¸å³!ºšÀÅ\œ›¶ĞpU‘ƒ\¤z9õ=
KšÌgÈ´íåëÕh†p=—ºçĞrB6^ÏÊÑ†µO8|ƒ?¹¿õÄwG;k1¢XQŒ8üşŸk[£¾.ûmpğ¥ÃiO|21öíªòEk‚²Xo!ƒWU½ €
g´F/ö°zåôf[Ï=Êj4”@åH—@h~Óû$6eÎÂvU¯ì xü‰xgÀIN›šèk4.¾5Hzœà.Œ4(â4ÅµÃâ;]¤îÍD„ S¤ò£ÃÆ_³ºß³Ğy3œ¼‚!nckÙş• <AFÌÎ_+u§¡c Ë1¢VdÄŒ%²+s!r²ä®{""¶Ãª´+ë½4pJbi€4Kv¥SQ”êŸÔ©1Àõ=k]4»³†ó%jŸØnf©É‚È%‹Û‰È“öşXÄòokg`Ş¡˜ƒËÚ­ÛÓtm_S*êÌHVÒ>õnÆÒ‰»Øy¬}‡+Ö³¾Ä;¿ì³£fĞJP‚­Ğp§Q©Èö"R!P3Ñ2Ì¾™)¼Ş4¯Dl_T}ş3L¦)Ú¡¸­zÁ‰«‘ÉôÎ169&Ã¸Øÿ'ŞÖÇ¬Šmj¤¨ŠHÆBóÃ8AÁ	ßí&EıgÃÈ´ÊUŸÓ/‚Vbª‚]İ#¸ğ Á^İÉ4pÔÚ²dáÇÚä+ÄïÉ –µr€¼«t“,ÊzXÕ¹fDUOPX“quLµõ`Zûª+¸ãx_sLƒ«e1íÊ1WºJbÑ^Í‹@a}#wßá%/{\[§5mOàÍ‚´İ‘;«$=ÒŞ\^5î‡0D\Ã`¤¿“ƒ“àêG×l  ƒSƒ¥Ä	|›ƒ¦êLÃtÜîx!-Ì¹-ÅÂ~C7î…KH#š]ş½¶Ü|Z+WĞ8 ?òjÛ”Du’÷­KGí1¨Pó¯ŞSö¡éiè¼ÜvÁŸğ¦9-F ‘4ğ.]|xdîˆ¶Ä’\×øpu¥ı×;G¸—@¼æÏ`•nxPƒP×™Øgèş7ç«Òõïò©Ãù‚Ò§œ<wœó}yNb{çëã4\Õ¤áÌ€íò A5Ãuä”X ˆhsúm¹cÉ_I ¼Õzê‚†ÒƒkõE×ãöyêöuw^T[Ãvtı]Vq¡óI˜eékÊùu¾~dç`/âT´*CÎàš÷Š­¥4ÊL>¬ubÌ¨É=½¯ó¹¹ö²¶C>¶%XX%méô˜.F°Ê¸…OØ wy ú…GÓwŠ—Ì¡Ù±aìÏx§j0ß,îzÍ¦”YºÈ€ÒyAf‡î[ArÄlMıÑ*Ì€4;¢\ËaÑL©†NÒ7ÅÂêÄ¢"auÂÎ•ºÖ´ºûšIÍ{Ø`Y&5æKámø·„ô¢ğ¤4¢û z|}X:5Ïàí®=NsS
ˆfåtwh²”ŒÊq"é—XÀ‚3Ó»íÆo”ï}¤ÀTÔ(E`ê9ïÈ<ì¹ÃªDS*©¢™±Ìú@±øíu=ÔÛÙ.EÅNòêÏc¡=‰íQ‰ì¿Ş¬ë|&cJg‚à¿3U#ªx|%åüÚørâ‘=Ô,FSi!¥f€ˆ8ÒÁxš+E&‘¿ÏÁ/<)Õ*ï	¶ÎÙ}aÓ(´ëó÷æ´*Ùš¬'=Œ	íø5Zº%|ÔYõz»Ø2ş³ñh6õW)ACÿ ¯jø@+"øŒRˆiPVôØy?­¿Óí<bx9ï7°¬Wfvâ5Ùá¼5v•UÉ&ãã–¢,Ú`´/W 1£$÷7Ï=Öû»Ö6¼}yùÑ¨²lf¾¹é9hÿí®VJÑ, ûµwùğE®AMèœâ¯«³èœØÊÆ«á“›ŒÏ‚5ÖóùïmVêª©Ã@ 
õç=Øò)ò€Ûà—ä¢™P5‰5À:¤È[GëŠü$3Ys’Ş½ã<÷qZøv±ÀaRQ½åü–6íó}œº=ı5½Hû,`p(^“ïG©Œ!E,N7i9á izùP…£u¹&!o‹˜È§ó„ARˆÂƒ¨Ã¶-P¿>›\ŸX%¶ó oGÁ"9ªº#Ñ¢Lòâ
j“CI¸‹ıOé]ÿ ú ÚLU˜öøøu©+Ám–ó/­	±†÷Ô<ÆÄßŸÓı`÷6ìEuc9 ğ®~á]pâÈv“‹ÒQÄ|\R›_˜úSÜ‡„İIs,%O–ó8QÅ˜¹ZÏ¿ªUƒFŠ^bİƒg2¯•T„#U„ëÊÔ+œšÒÿ¡¨Ğ¶—K§¦p@ˆ¿ç©ú28?5X  £•cVpÑÎr×§ÈF¸gf£"íûÜÀN}83.‰¼á^¹}Ë5‡åm0'·”¸€Ó¨ğOİ¡ı67‘„íIôÇ@Ég9$–Ä‘IàIkø%9ÈÆÎrfZVtn›(V¤UA\ªgÍ\8gıëgÇo8cYFXN «·lû,;læ½>¬l!ä—ËM·%Òç{â§$ÚFƒÈ×W<–8s¡KT^3ÔÌ+²efÿÂ^õı¸RüìTùs÷°ú1ö(Ÿ@¢ˆâø[Á6Î^e„»˜ó´ü&·€,¡½çÊ&ú	Œ“{TïŠL!û¡¿eIôa“†v^"­_÷HÉao~è:µƒ‹òN±pöö“?e×R	zi€Eİ_—œï‘×Ô7l2œZ›í@ÿ”¶7.$.åM:û§ÂjŸÑØÑÇ&Ô+X|O5En²bş
ºÕqˆ^÷'wŒÈ³¦Ğ°š_Æqù^a‡rğLÑ–Ùª{bàÖRˆëXş„K}Y:¨iCz¿-¸†Ä*™ãœW
]•”x¡Z}H"ë…*ñ®3m°qg/Xp-ƒVÿ‡´z3ŒãÛ×0o{§şªŞKM*æÜàûfo%óPàhq°-‚†ƒ‹ù·Öoô¥”ğˆ•ùİg¦àÜÄ¡zmÇò	4Pá©´âT¿ß@øÔS¦©šøxÙİšÖ&pûÖ§ì·ãiÓÈQ¾b<—ƒ“å”Åa¯1\¯Œ¹§¬‹ŒêGÌ=ÂµöáPÍÚÜ¼–¶® ²)[;bÎä™B38È”Ò•cH\¦½¶R˜Eaš%9
‘—vVmóÔ,«®1†Ñ¬Qß¿Ù›t§ı.œYsÙ;$nwˆ9¸¯-C0AÂE±ö®íÂ‡ôìKªC
]ş–\éññu6qğù¦#¾„ÿF¾´^º²+ŞCûÏn´ây7¤¼ümì0 z”vúÆßúódi"ê¶^SáUá3)]¥İvGüdGZ3Ót©Ø“.8‹=ûÒ’Õ8˜ @Ã+’¸›UB‡¿$H²¶ gò+öjÊÎ@Ç¶?$UµfÂb4¦»ãa+·=E&’[¤k>HéŸ£5¬ØñEÙuI¾AG•µ=L¬Byzfß		$ºVÖ¿V‚q±'ÔQrµæRÏÿô
o<gE»'¼´ícYd/V5UÖâ\™^7‹ä¡ø«x¥šÔèäƒö¿Š6-ÉçôºQiİŒ’I®{`ó1à“I31^\"×Ë –°´§»Ñé5¤XK›”øËôu›"H¹ß)nK"ÌZBMÇÍ`Í¸r(…(^ïÎo›¼÷[âŠÌŸÚk%6wk§Ï…ã†»n¯1\äõ¤D,ê‰*•ê„¡^%B©
ÍÀ‘'	£æúYç‘njHÉ€k-»İg'˜XüqÖ÷®‚‘[k`D@×vg÷âQ}ˆI6†lèá¦H‰»úÃdP–6{È	ßğI}Æ(—}0Ïµÿq¿¶úBİyÄˆQ™S¾½’3k	ÍıñB<¤nWĞ²6íKÚ|€.±KˆÅnĞ€Ûº ówÊ˜¾ÎV³cÊØ©:¢ÖÿÈS‰è¡ÔÆ©¬›j”cR¿k‡‹¹ºÁƒ—¾Á•ğ+ºOlºD
úMhXïqæàæ¤ Òöf6nzoæ¥ÁêŸ{ôĞï3¶<uÒM¿r¤L®%0.nt¼ÍVIZî—3r>‹ÎE[@É&\A:ü$á’²&‘—’hC”=–\Éxœ±*±"!wº9¨ğ²¿æÉ¢¾Y¹V,¯WU³O+Š}ãéÉÚííÁKN-‡©Sl¾Kæ"`œ®Àü“V§&GK"x0;ßSË¨=øØÑß¢›÷¹ºæ1%@Ò¶”b YfÁ¥Ù®vFùFO
”z©E¤ˆ>D³m)¥EQÂ~Yg¦w…ñx©ÒGUÏÉ×lUÃ˜|`V¤oYÌGûµw<d/Ú¼W!!7±nñÁ3rö[gC…XSG2dê|¥I(=-Ôœ„AëÒ Û"¾éÍ¯i·¶†Û˜Á§…JCëw¸İW5Ù!Ğ IÉß°¦YûM½Ê ÌÁ¾Ó;qG¦ÑÔ™eyöÍg[ÿ»ÃWĞº”5Š¤àõiŸÒĞZS¨öuz7›’£6uÀ§"§ÿÒBˆú.Ö…Íª¯¤xtõÕñÃZ~¥‚¾FñƒHüi‚«î "˜wyßdIYpêá`ûÌ¢HÓB’^2à§ò‡¢µ§ö.BòÓãâ+s\i[†„Ìv.úD5‘(öÅ«wîı;s1BçyèDØşõ$ê©náZ/Ê¨7Ş •¿kI×FÖì’ä“Îõğ=³€H³Ê'¬pÑ¬Pt}í{’ü]µcZ÷½KÒºG‰å1Şœ@&¢ó_PÙĞÃÔÜ2t«â±¸fƒÍÙøB—7|ôWNPş+D·ÊÙ+Ş‹¹,¢Á£0şóˆ_.ó(a›Jrh=‚,>ÁôH°ønAÆf:@öÔ(¡0P¹/ÅwuÛq99·rmMªŠ†æÎI2Æ‘KOŸŸš‚Û ‚í×4Ç÷Y¬éğI{Ğ%ı
Y4K.9
]?Ü{RÓT;Œ çš®-Š¾ôn˜TÍ™~{XĞ÷˜z„n×â_l1õ3ıû…%ÛÂµ	"Ä½˜4ŞWqîbKıŸe9¥YŒp¹>š°Æ_YSµÎ.D¬,c‚n‘Î$yÎ«6bg¹ü™4€»¢ÌÌÌ­ÿóÛgí3¬ªç Cgü;SË¬ldÎ6ãW4[ÂàT¥sù0‹Ààä*'Ì7:ÖpäIösÎ·¯K$Måft·İ€BB¦ „ÈS.#ÕS:ÇšÈÌ}l3NˆÙ²P =ø\‚¨áI7\ÀÂìxPş½”CPTIƒ‡Cs)êDı“ë˜ôïîóÁ\Á~YMo¸‰®Å×	ÓàJoKbõö|ø9D¿FÛÍ;a»Êâ–A5p(DÆäå&k7ÿõ#¤hjKô»ªÀ‹BË+–±ıN¤Ù¯W/ÈsfôÍ …Ù ÿJìÜQ£™„9½aöK2}r•mC;¨Ã)Ë¥Œêr¹5L´8¿ñ)z”BÚàdrö‹•*Ö‰å]‰©=Ëíû>Õ5Ÿ‰üŒgc½hW¦ç^QHR—ÉÿÑ9–n+¯kJÓŒÌ
ï‘õcË†/Şi«(Ri³B¡Çø+}ÌóüV å÷À©ÙÏƒŒÕ!Äãcã§%%J%“*Ğh÷TªÆ\ó…²ûòæˆTŒKªH‹²oOó¦»L<3µ­øJ~@¿®WO´?¦¶q,ú»3DÊ7öAikvK¾ê„(ê5Â<^uMøõÃºfÆùÚ9ß©µ3¸d>LÑÈ)§_„cçó€ÈÚÅ„„ÿïUg2ŸÌÄîq²¼ gòÂ·ts»³FÚj‘Ó¤ã[Ê§táÑÖ±ô¨í6ÑÅU¥­T»uÙ*ÀÇØ‚m4†
ÏÃZƒ–³`4'‘£Ôu{#ì"¦Ôgÿ¬	Ô(ôÄgùÄ…G‰úÏASA—/NÆ3?ÉçÁ³¹q(®½¡Ôÿ¤¬WéH´Œ´ª¶¥®º’ÄõSÓ™ ³i- õqØùÎ£™ ©5â=¶¶rèUŞ7ÛÍYš4X|kÛ¶g‡Ã\,52œÆ¾×“v ‡…8R	$1Ô¹íò	°5¨‘è»ÿ¶3.ˆYú¥oWüµn„6”h0Óø#K?*è€iE>°¡ä{]W%h`˜¯´e¿ĞÙÔ:Ç‚6&’²WãM+N‡Şõ®¡i5Ñ=ıÿ6PóIjw©6ruÚj2]+—ú–İ§BˆF­ùÆj¢`†:À¢?êœyİ­Á|³8f9TCX”ÌÉuâ-I§ -ı]öwÄq$ÍgÕÛCwlŒr–Jã!"…ˆJ$sGÜ-† ³éòLÂÖ¡ü²[clRº°Éª@¾¦HÄ¢¿ào"—yT°æ3úògËué*Rö—Ù‘(¦¤A½¤‡'¥o¬ëØ •Ù¾½L@ÉÖ7‡ê™á¥ş0n/É%]+¹{6w tc ÛX“½UV4Õ‡ƒaßéŸÜJú³µÌ~‚ús¶úÙÄ€Rá”¤9C¬ê$Tƒ!±Â‡QD5O¹{RÆ¹H÷ŸxÁ]YöT8aTù¹ƒãwÆu*SY‹†ÂĞ®èá¶2ÿş_uÏ¹úòÍ¾Pøú8`ñœ´¿ª“Z%æ<@`-tşt%ÎÄTYIß/Ì™7s#Ì—NC·05Ç øZû³ÃBÉÅQ`K˜­¶6òšeaï@ƒ'Z$İŞw´®›ËÕqÁ`M?Z,Ã·°W>ç¥4§¿2gXwÑ–bå¶ë¶Ú2Öò'šë‚y¨Çéí1Ch;gGW%=7Ğç2T^şdñfŸÌ†SÊ§»óğb/âugø/ÒEÌÏ½4ŸJ#Ñ‰Ê·zq@ÅîE+ÿ|á‡ŸB}èOIá7Œ'¬ĞI‡ŠÈ‘É ÿWöø§E„ îó`&·fªœnDŞ°û—xª³8Q³j@5„êµZ®]üô¼\äÒ˜&AD
¹µ®ìŞqüf^Sñå@ìE\y)˜Î@0¤Îvõ	İÇ²NMÎ_»lf\.õßÛtz{ğ÷ÍÜAÙ	7@l
ôÊğı+kö×ñ~}Š ¨+RöÑÿàí$K„}µ·ZÑhõh©ıß!Â–M‰|Ì+D
›Òr¼aPşŠLbèñ­ØŒº¹­óòëĞI*ÏOÈ+1÷àçà¨ÁÄîùYèy€b«Pi»Å¥6Ø´T‹TR~ÒbBLª>a~šÄáeÓ1Dæ6¿îj$õ„µ”oÈş»-'–V­E!/ÕH
/££¹Õ7ÄBÓ4X¬šÆÌd;³S~%|¢ÚB.ÍåŒû®ÙVCWï¢lŞ‚f æá£Å»¡ÅÃNK”.t²ß¯DİÁ;·_œ¿AJóí/ƒÉÃ³pB²‰×Õœ|ß(Ç[ÇCºŒj‹«´¬¹Ù(Š' í¼úUMu``Wt!Fi…O&¹xlÍÿ¼,6Õ(Ounšüò½ù
3ì8šÃË•ÕfK±?>øëVÓä’ã£ÛF|?€Ó¡‰€PnL—Ë)’â˜yº dbş¯J=™_óİG“ÎÓL)1sñ Ü”uXúpñµ4”>p¯uëÏ:Ğ4	^\…B¯œ	¯‚  lêpK\ÿ:Ëã¹\Ç)yy®V½Ô€YMøSÛı"Åğ½IîŒYĞZ aQ­ş.Ï [©®N V1WİÁ¨§)4æÔ¿ŠÁ¶£"¤7!6¿ôö-şBıâò`Ó‰,ÁöÂ•W›_
‰R}MT¢4Ï QX.ªSŸp˜¯Sth`eÍ¯ç|îûÌ[pÁsæ–bšõ­¸0ü@Æ˜b¬Æ'ªòDü6‚­Zëx’Ò˜G¢İåéÛÑ)@2ŸqöÌñö­EŸÅ¿Í	+cˆÀ£î®=»Ct*Ò:@—íiÉ$[b™ÅÆÍüç;ÃÑ5‰F­®slÿf¨WiXªYöóÌGó«„Š6Ø«ˆOI\sÓ^ØŠ^4Û]Ğ| ù07ÏşR?v[4­¢ş“¿sï•ÈÛøİ1 ïÆÀt>è_ÒLFÁ:^İÂïŒó›ó—/PDTG”x¼“”6°Bz-Z2İì# Io1l¥;~¸tLTû›¥z&Wáî¥±$#WÃñ¯:ğl»AŠ€ôíâ²Ñ„+$ıK™¼çƒÛş¸ç7¾l´¹ÄÕÒZÄàµÖ}¸†­‘Ù÷‹?à|#}¤>¦îßS±ïÙÓš¾”4 … ±€8¹q¥±R÷3jT´ŸxÔ×·§9»m³á2—ß#ge˜…p$Ë(Û8i<„R€”ğˆÒ£ºrûHÏ¶ÿXŞè»ÙX °“İÁd«HÙ7“¤kzÜu·Á¢OÔbb±ØY5Á2­­ÀŸPò?å¸“V%QsGT0NÍÚ–b
-IÛl¥FK³Öè£‡0[šd‚U,çY¨VÙpAYÑøtQÉºÍÂŠÁãüØnWŒŞĞ£ BÂğÒ| UÄ)ñ"]·­æc×;ÀÖŒ•ÀÜ«ësüş`ğO‘àlĞ9¢ÍHT?AÂrÂ1e¸ı¤Oc™ç)içRĞ=
«Û) °Ú9Ú5´3™¾ˆÎ³£F¿Â}ÇiüçnÔu6«m`&®›ÕQräÌ Œá²rà¶Í™…`\|n·¢¦ñïıÄ?y’×øÛ¤”xíOæ¥ˆ±yLÇë@‚ª1Óo’Ğ-¢7eìDÜ{ŠHÛHk÷IšYù:åZÓ¹&tÕd‘–şÓæ%ÇN8}a@·O	c/´QËñFìØ“ş¡W!½QˆJF9M=«“³nFå=«¡b$öÖñà•Ö¬(×·
ùc‹Ø-¾` ^êXª×à¶^“o¼E4jN%Œ®´“.8K—&kşaÓ¡Eş¸Ş{ÆøAõA»lâ[õHOHúÇ©`©)]X@ø®4AÚxåºóØÅ%‚“S”eRV•­¬aÕ|ªŒ¡QÑ×Ã8İŒ~f«Å“4˜aµ«4ÿ+êƒ”|êd· íç¾şOCF›î8†á^jÅiqe€Ÿ1”Ùë±¤’Œ[YD†~e;UÖÅb—½Që0htVg.Y„8ÒôÍœÀp¤¹ô ğ@¸ZÌ
ÿv"¥oÌ9°¤Ïñÿk¡Yÿ,­Aà@n ×Ï9^B<T@Îö!ilÓCÓ†¢“èÔVIxØìÇë•jÇ‘ŠÚ¡ ÓùÔä‰<Ø²horZ\lÙû	Æ`lÕäá;ß
ÍU‚CM¯QŠß>ı´M[d!æşƒGaX´ q X‚¶p7€\í4×ãÜ ‰ŒïÍ‹ş¹[0¯Š 2ÚEß^„–ª+2ùñ{ûÿå¸Ï
ü3gäYŠyáô!‰5*Õ|™‰&¨Şº2üçŞ“€µTu‰(ßz#d¶ZÑ×J‰é‰:S¾ræç®¶»Œ #Ä›S—Õoä¤„CL¾H3üM%T,øƒˆÔ/:ÿpé¶öÌÑàL,û¼&oÈ9,‘ıºæêû»¹*‚Œƒğè åêAŒÂ™lm]HÙÍ˜û*°†°û¢ÉcÅ^ÍRg¶]6•+=ØÀÎ9r(Ow¹pb•èàÚ'åõì¯Û’LwKGÖŸ:X:#)¿!“1R˜*C%$¨ˆõÃ¤e•åíÈ¥É#üE±­¨á0 4MM“æU.u¸dŸ…‰Á
åº`+—JŒdF~Vg¤ ûâŞ˜[4€%ÛÎ]Q¾JøJ NºânfO…y™Ş|€î—IÎDÚa“T}N“Ur––ÿrXˆ5Yª'üÄŸš‹fÓÖì¾É3‰¨¹·±¶k¿×æO__ƒ¾HeÄ(ö×F«ŒM™L(\’p’	¿‚ôôè×Me"T"¸ŞulcşÃHûiœ™]T%Çø1›xÔ}o; ±ÆbĞrE­JÅU­µW±6,(ÊogsD•±m{g~šÊ:¿0hUÿoÚ£ÖÊ)ë­!Fä‰åv^¶Ó*Ø…°ñ$h¿Q¬e©;WõdÂ¨WrpƒWÊØÇ—,k xîe5ËQÌ»^è1Oué1»‘x²‡ğRv\ŠVîsV~76?mpäY‹o¡+$‰òe­q¥Ì"Ø{£é8ÚÈ×J¦f|†·B°O‡›H.«EO1â¹Ä”'Ø™ÀÚ2ÉxÏ1R!ÇÚØkö‘Jeıœüƒ›7Ô»gİ±Ù|×í¤ã»S[ŞëDæÌCIf-š^nåÍñÓ£ÿâ‡ÑtWP»i,É´YÃ¦Â¶±„hÇâ}ÙW›¾şzÒÓİú]Íõ.~ØûvC· „‡Ÿ•àd+ÛÍ¹Öù^èßd ömö—Ûxü;ùVèe·g|"ıglì™¤q¸›YÈÑ®ç¡_kië?è²Í¡Ï·YÈ?ÉOê_ñU:ô<’†-º¿(ûêÉUöK
pï~®°º–\íî*¬¬2ŞËÊÊı‚dÆ-¸óM|M®gR[ÊK"s=zç¼ŸªŸ›©Áš¿uF»µÖ²¡íYA'eŒ¦Nx'rÛàû’¨³ğ‚ F	²,‰£Šæ¹…z®,¤+¯ˆ,¬BdÖMU}kgåÅü5ê–í/Ò7V“¥OÃ0úâşå:TLÊÑ:/' •ñ-õ£ßô<®nÀ>™mò¯fêÎ% 8&5â±¡êØté˜l6(?J]¤&™s¢Ç–Ó\Allò÷¤Z	½4ˆs/\ÌæT6²fKëÉbÀõ6p
¶k[|Jzéävšğò
 ’[Cõ‹×lHX¡`Â[5Ğ}3Š‡‚á§Àiª}É¡İÃ*Èn¦1]¦şêê3ck¸I£Õ§ÌÂ"äÓdCtú=³ÑÙ¹ş¶[ŠCK™dÓù¶1Á À)3zµÕ#1•Š~%ù‡|LÅç€y?uQ³¹èz^·rı0Ÿ«!<ô¿/Ü¨ùµq½môäEÒ,Â¯‹€Àgš"SÖ»€ñ±»«NÑK7Û?c%-Ş é¨}BÊ	5n÷Õ&tgOµC+êÚ;]HQ¾•ú óÒ¥e†ù¾kŒqdæZ[<ŠAÊä•Ö^g²o²Ê^|ÆIÔ…æm?¶	Š*`OÔÆ5†&òƒ½úüÿ—7
›8äŠ>ZæâmØâº©ÖÆTÙºÓ÷u`¡Şöˆ$¶b^'T²ÕÌr[óİ©ÜÊµ€ÖM³Z*;‡Dy4<vô7Õ?A¸³¡ÚE±¸/a³ ì!0»§P!îà%¸š³]î³t|R“M=ğ^¦-…´1æúü¶BC-6/²c-™ÓZeœmÑ5; eŸı÷¦Ã¬Üj¹@Q¶¿"Bk{³ì‹õÑëÀY¼iöÚB“¯b[ÎÈ€Ó6#Ğ2m+äß„³/8íÇyÜ4/v¼E»	ïÎP™>¶/6N#åßÒŠ >ƒPrü¿1ÀX4,Øï=>cƒiõ§ßÓ5TµÓM(Ò²jAÀáş&Óp¦]©²¶‚g»aŞ±	B/re–=nİÔB›$íĞÌ. áì}Af„Ô 	)ù/ç Wƒ”¿Clô¨°ÊèNßËÎ&ï°Ò®Ì mÃHî¥pÀ_	0!JvâÇ¯ÓpMX‹c3;?óøÉ†N€7G º:ÊĞ¾2È(š~Î^T!æš{‹Àäxx¥Ÿ »ŞŒá”»ãÕ0™kÃ‹P¯ñ	ûÎî–ëı¤ÿºıŠwƒÒÀHÚ„¸‰h0¹}&mB½U¶™Wç„ê€ô?ÈYsáø—ù£{l4ƒ¦Sæ&ú,ŸæŒÒÁÒÛ€ûüÙAûûÆåK¨Şå[¡­PôzD~šb”lh  ¤¡“Nc5æf3(X"<AëÜ“¬‚êğ’ªZš»˜{¨Q©³áÇ3À+FS³zÿv\ÛåŞ‚b~¥b¥ÃpPÑ,  eBdYénõÉM*iÆ@Uí¹å¶ÃúÛ[¿óì>™bJ¤t“WÒ][•l²åúÒú¿õ»÷,l1Üˆi.şŸ0¬ˆ?'ÁSî!ºB{¼¢ÒŞ·Ö(Åe
YgšêêÇş÷˜'lÏJÅX´ÈN8lU‚È
Ğè{îÓ¬GÛ¤ø†g„%ÂY€OÇ`!E%&Ù
FÚÜ2Ö'ö: pÖ[ıFñ‰ôÙÂ§ßzfÃ{_ûaò	ÇDœ¯›p‚{UŠ˜¼ä$[3!LFa8ê\­) µ%}à`k¼èãhBL»ıyÕ7ZQQqÕ¸©.{OÓA?;A¤Ix¡†ãA6»Ë‡ æõ‘œÚÙAnGGyÑ!Yy#:úëé”u/Hàµlú×V‹/0 -8‰!èôõ‰`”Én@²·}º³]•fv9TÔøJo²; ò#Âö¥©¦˜ç{7ºí00İîŒN®›Ş˜k–ÀJñ©Ie£·İ¼Ù‹.LZ›¤]¼îöo µ¨XØaÄ"<VÀíøz¥‚Ö§€}çIE`tpbc ›ÕÄçxáÊ½$	qŠµÇgísİi[ğ@‡1Qa—À=¡bK$eI2™:aıFÔSXå4Gù-@ÓjŞ•¸íùü˜†©‡µuBÒ“¯7>«ù´`oi&T*sleamôhE6iá6gî«1x™caŞŒ\¾<²¸·\là’%!û8~³Ô?²›²Pëy±¸ş‚:ŞT´Ö±8há8ª:+ ê"‡õ¤â¶ÉÉRİØ[š¢íİØÓàÙYU¨£\M‘B4.ìá'“³XúËÛ¢Ûü¦T«õ/Z¹½‘£E%3BHxcó6swÑ=q<òi)&PgjÈID%¾}¬#Îc_\ek…¬¼\S‰kWØ%Ûü\ôÑ#
g¯Šääwd€Í¯ñæLŒˆ6ï˜/^#ºYq«‰7_†ê¼X˜i¤»‹s…Áâsw¬wo•;áŒ:
Ô«>ÜQŠÑàHôi˜ÓÔ.ß99n?Õ4Ü¾%^‚óíd“ŸÑ-X	W›;KœêO†äqÎİÙà«ûİ‰ºÕèû|%_U¤üÔ?Å~)e÷C¡¤ú	fm2•/îyïÄaÆ¯×Š²‚ï0¬ê5j¼F €¼èÈ™C}•¨`æm{›Ş»Š–H¤Ç›!fî|¥ ]ÍÉg­6£à1ºƒª*îP*Ä\0‹¼'Ş§­`÷D3Xë„¨ÎV4­òiKóÎ÷x;ÛÑF”•ÇƒÁçœ/S@ú—™iê$ÄJ7Á ¤4Â‰/µŠwâµø•ø‘ƒÙ~,ñ4üåÍe‘}¤UôLGşù—¥ L—ş>±Æ1?psBWçªı‹ŞzP2¸Ã(‹ÈQ)~ ¼´C#'Ó-8K n0‘›±[etÈº•ñ×{1S+‡D]á†é¶—pñK¤ï©OÌî-i+:¿Ëì¥‘û»Ôs¦å÷ˆìmbÜ5wö'¤øŒNŠ4d AÜb? s‚Ñh‡œâÑÊ<q H“÷qœéã„ÜD|q™À¤t›w#Æ÷lÁzà·®aıá_GYêÑVæ°Ó\Xì#ùıı’]\éô÷÷Fé—Ò+@cHÒ£`¼ËÉ•Ú˜çí]‰îS ú®d%x=Fc×Œá¢$fb‡6„lZNgŸ~'ª‡îºĞCş³·İZøS¾ş,K 2áŠz˜òaYÈî’ÍDê#†&ØÀÎ¬Å5\ŞrÇ ¤3<P±VÏ¦•ê…Oãï±æu¬üUÊDbLöo¿‰F Í„p¥	;Û/gú²Ë`Æ¸ˆÌæ÷—WR-Wª•—¤İaš&Œ{e+À|mvÂ€9,ú'P@ùlö*D‡®(I E¨Î?yNğùI75«İÍü_×Û\¢ÜüzÈ¨.)^ñÌA‹/åt¡óx³¶ƒŒV-X‡rêöºu38º¾É[jè´›—(·Ê4·ÒQÏ¡LXµ‹È]‘{Ìº~·&;ÔÛüy‡å§*‘‘qvEâñMã^f`?JiÊÊ«ıóòó&Šİ¡»&?y|Fƒ«”†Ï³Q	Ÿ}V×©IÏdÈ‚Ø`_=ô(t·Q¾;÷úïfQ°Àw¯ .Çe*hîJá‹Í‘ÇU™#Á;IÈ‹÷i%«[™G‰¥I1¿Î«#@U»K5j‚Ék¤(ÒH4vO;n˜Ñ÷†mšU­©LÛ§¸ìÎÍI´ ÷­1tC¹§#>(ğî3'+Ê:>Š dæ:äğ-ìd†•¡ƒvÔ»ù(¾ˆF›ÛÄšõ·ì­İD‘íÙ*–‘ìR¢¼|B%á’œÌ‰nÖóàÈ	—° £EøŒ,òkgøz°-xÌóÅƒÜ})–”bXÉ‚…•V#QCÏZ^vğ¥[ß½ìXğ}jôP~ÒÇA64´>Ù_u¼[€• *½ëˆO‰xõd=‡Î]Bà—ªPAÂnÈ=íÜ‡¬Œ+9:3hÁ¦šúE]‹Õm †ı±'ådIÑÆ‰îÎ	‚lm˜¢ƒ˜.ÑuôD>ÇFÍldâPìŞš—ïWòíÅ–ªšd´`¤{Á™µ*IuàjÅÛDşâ¤æ-`†-Ñ1¾™ŠQuÕÜ’ö,÷¹z]ò¹›€¦›8.ÿ:¬—;»f·Ådv|:³ïéúúnÒÎû1¸:‘q™ø3·E	¯ò¯Tú_¢ÂXøhı÷s=Â¤=.îp •BĞ0ÈÆ§àï€=f²Ô¿¿É2èÏ /š™’Õå[»‚E¨÷½ƒ¸ç©JfêıÎaƒ&n¿ıs$*@V4–:X%7ŒjÙ&='~^Ş(øÑÕIp*$ñ¿ó^«t§$Éí%GÒ1Š±föüSe§`îÈfP)k¹ºLü]İ<µ±K¾Ã¢^]uhy¹Å¡–¶à=e†&«CÉN]1ŒÈšÛ$^¯¹“ò ëÔë?Ÿî…Ö¾Ë?C-µØIÒÈè0åØi®o)çTry)…f½5ğÊ%Y_˜[HŠ¦ÆÇ™mÕ…àEåQ¿p"ĞäÍ‚ºø’Ç'_AYtW$œèÄj7ß…,}äëá~T7´¢W(ãM”2°n}Åö¥MCé¢£Ô5”;%öõ¿Mmè…s&…ûØµìi³‰¹ôu£%Öì Æ¿‘œ¯2áñİ­:*¢¯a*¢İw+ñ>‰CD¶q+Y17¢ áÄg‡úPæ1£¤*(úqÿóÌï‘¼ ¶Pôãˆú3ïÂ/Šô³SB#]Ša,‰5ˆñ<®f·8„Kn«OWó7Ä.‘Õ“P¬›Ö#Š ¤Ğ%d {/¦L>¨ş)c÷#¿* '©ï@ÊØ|å3â,j±ªCw,Gí§mBÜ/Eas¨ßÔ"Ó³WĞ¡s)…SmÂÔò&›ó$ë’˜­z:¶ D‹ÏÓ)ø^¼dœîStU²Ã”şGß›Ö0«‡o1€]¢Å.Ö©?’S1×4ÚwòlŒ±uLç­Î)ŒæåX|Ğ¸CÅj ï´}©0±í¾ğ2 l*³%ˆ'QT2úßHSq¡–êeMaï3TóLÚÎˆá¾o‰ä?W?iLõåeš2¨ ~zÑğ¼BúñÂ¶/¬ğãó¯Oô*ÿ¯¾—‡Í}áã¡>GY²Ş”˜ÕB4À§×¹ÿ†jAJš‰qóøˆ¶QOLxš"¢ÉçÆ$À¦œûVôĞ4€X;j‡¼o‹X7ôsW©¥IÓga‡Ó1[5Ø-“÷›10Âïş´óßÉü˜/ÛT§sŠµú‹¨š!h@Ë|1…ÃbÁ¤õ*…ç—Ê—/Š{’ªä)OZlùä4˜]Öná¾Rg²¥ÇÑ‘Êë½M- Ô#n'1úçÑm)è?„ßÄ~QÔ½,r;>ÔUÕcS£Æ	$Iø&,\:¿WÔJuv%zR¡øôhdÎÙdIù”u`BúT>Üç‰o‘Ê{I™à=Ê¨p#ĞMÃDùŞ@@åo)ML  ˆÚjmY8÷Ì1ÖA"ÔYè™™îÅğŸØ]ŞÕ28fnTOÁHÇÂˆÒTİùúº4>Èÿw#«Dûm}…Û#˜Aÿá²úÆäá‡SÿzböV!Ó•š¦fpU„c–ğ[û½+›˜¦s8Ó°1‰’<!qÆë‚,ÿÆcl!¼zlúÙÿUûZ$â‹kñµõ1 ºiÜ•æÕBM=Tş‡êò0ê'¹ş$;Ejëåÿ”|ò8	&ˆÖ±1ºgÆ6€m¾§òË`œ(Ûç®ø[ØèéîÂ•O‡ı‰ªœ;@¼Æ¨+\r?oTU=GÜ·Cˆ¬LæÎXVÔ˜ççqê^œa.N»ê³5C`°ç”c¾xâ}C™dÁ&£MÃÆû•¿¯ÎÉƒ8sX!©ìøÑ¢“ÂuWHDY¿)2Ã-Ú1ª1¶îÛs’Xù“ìéè\×•cx œ§óEóùú×ƒ”#Á§ALAWÈ‚è±=xİØF@°Ã¨–/”¼^h/û)$`ŒO¸PÑ“pÿœªÁÅñ2}?Óä,Î&`3»ñªb({˜sb´˜Sÿ]çÿjÓHr©	ERZå’¬¨hŠ”Cøü„B5ª›™Fÿ‡`4”÷!xj6—¿SSf‰´½ÆF70îÊ9@…·ˆ}!b\OŠyç©a@Ú,™Xı|G	ÑvÒ‚şÉeâĞÄ8‘†ôß¶4)hªûÿş³`Oîpj8â55é’Ø¹âôáõ#ÃaÛD§[µ{HïsÒæá.ÂÊ@8‘>10T0PºD8æRœøËğgJ{R×PàÁ‘éìı ]~á ÷†‚N¾Îx¨ŞšC´rtåµº¸c¤
f}Uî§*S„];˜Kªt¤$O2ÚU0pQ†/ô½óíô€fJ‰=Â]”!íXLÜ0õ÷€@¤ãÿbY0Xbx<®ªå§µ>ğÙ^CvÖò›áÁqX†/óF÷;kë+˜ğU¢º*~È,G“™Ğlod½Ô¼˜ÉyİCæ|ºŒ1{ôå“ÒŠÆ{QbïĞ3ó¡{x›ØÜíşC©¡ÀK˜(ßK*¦Óë!ºÖıU‹IŸ½®SaÛ
Õƒ÷0¸¸ãtùX“³sŠ¬ÄÛ~«yü»ÉhC\‚®\`+˜$³K.jŸã@gÏÚ„›\Ñ¯¯Qæ¨éûú
Í’H€hMV^-'‚m¤„‰Øa +ûK=v ïyà¢úp”µŞ´´h²À_+V§hñ	ÔÊÂWS;gzY#†ÿ×rˆQµY§Oáª)1µ—Ô+WàÁÕÑHójB!Ğ>Ù¹¡µĞŒCÏFpöªÙnè‰u,jP‚ëä½WÜÎ ¿€¾¢zšÜàr¿ëÍ]O„Ó»«kvşB<˜ã×Õ3î>)£P+!…»¹úÏÜ&âv¥ï4YU’ˆW[Ód#¦¶¼HÃLÛ°ÿ 6(³Qê.ú¿%‹9×<0x¦+YÑV³oäStÄ™„"É§'ôâ…ö¡#\à`.t—ØG'hFÃ‰¸¬‡Ba ¾Õù4:ş²ëÖ2v¤õ´«Ù†P[~#&Œ”Pß¶ûi
˜r`N¦@A¯6­}§Bƒ"TàÙ$~ÁD@Jïä@Û´î¹35wM±ˆgN’.JM"–U„Z©ÖªOD*€éü5®±q÷T^4ıoáÖO[L¸"Kqójñ<ÌÓF†S@ğ@…cô`à÷ÕŠñßæú¶ï°…[™Ü(`Z‹£À=ÏO!È ?²LcÑP©*©~ó0 '¨GÃc‹fOŸƒS¯9ÌÃåx	:.ö±Ò—À?ş´Ú‡AİAûÊCİ9sìz¥’½c*]ÓÏøÓè!twiÊwhëk.!Ûâêİï¤Cc^bÃ"ü'p€¦)¿’ Éş§‡YJ¡|ôºH #Ãù\"„˜Nò…ÍË¥Š	h¸µÂ§ã²å®Q5T„)ÏCj¦ ÿù¥0‚ÄÏø†üŠJ±H ÎĞ1]²İû}W€«eæa”öi¨íş MDLÆU+ç…h,‰z:wW¹(÷cªĞß2ƒWz£m]t=µ[xe3dj.¢ÓRh\àw\•EPó`¾ÆÑ;ƒ!”“º6ŞV4=>“z7‰˜;ÜÚÓ”½ Kˆ–³²Ş*÷U£~ma¬Ó‹V¸ÔíŠwŠKŸ²a™äÿ×Š{ô«ï?–u¾è0]>÷)UâdÚÕV°Ã‘Ïö¹.ãÉ¦Ü5;£à|¤®›·…VŠÆ"‚şú e>|Ş{64×R¼® ‘Ô‡ĞáŠÍÿæñ¯~a£B1[y<\3†Ç«N;X«ÊÅJ’œwè'ù:^MRïBUÆâÜÖxÖ)”x‚ÎrF‡JLW”,Ú·¶š¸Npj¡"0R¦õ„µŠåè1P2šX‚ü¤9ÅZ™Ë¢ûã •AXAORzµz‘ÉqôEx Åä6'+ZëĞŠÀº¯
LAÃª ŸûrıI>½èßµ-:—ùƒ¼ ë#:‚¡¸_Úq×Peÿ‚3‰K£N¾ì2J7#ØË¾Ù [ö`{yâ>ºLA	ó¼šLÔ¤ÌÌ*+/h$fğÈĞ6¹¹2Öl‚E ×Í†Òl3¸Bku‰ğÂC ÕÆE¢Qü¾PÇŞd›ğ™ü
¬}[¾ß¨,Œ‘á¿w6†É+â8rnG—„y¯¾B\áG«JG7Èn¨Y¬)³Iˆaµ*T<àı·¢U:æ3/©›$Aút3åu[	°mû1f¸4Äõ,á•òyVìdŠpÿ…”uû	m{£
ó,5YïPzÈôb%À7Ø¼0›æÁUÇ!FÙŠ Ù.z³'”}Ì­AVtÄ‡Ê@}{÷`•9•4¯ÔT¾fĞôÀ®hÁû_L·l×CğÅÉ¿äo"H&êß¿~õsO•~˜à—¸HüÄ‡å1ÒÆdîyEî¦ªJ²„@Hz&ØÙ‹ÿ^ ıõ|õ^}%ø2"PœkYÏj1¸ÉıÂâÂ%QšÀ'&{¶×kÈÒ¬!©—ŞxfàòĞµ„ãú¨ Ø7yX¦³›ÿ70Ss_uv4|F3(éãË¸êÍ·¤¬»°ËWÕ:ª²
ö$™zp>Ù5z›…„BWT	üæÿ4$¸(n0ÿ  »q4–È7áÆšĞHQ¥Î 
A°ÉÑdÀzQûÏ.:Ì!	GUPYj52V—üŠ²Ğ­¼Ö.}±KÅ?ÛŠÒ?¶2‹Z3ìª56=yí)sı¬ºŠœy¢[ä¨·d©ë_»ŸõM¯Ÿ6*ÃUã“ìM*h!A¡9:}(Ï)rJ‚@ ]ïËn
÷ÁÃ„÷ŠîÜŞË^büÇxcĞõ=7ù—B¯)v×JZ'ç™²»jb8+3	=Ã£¢w›’ş7´Æ·”‚
Q!æò>'ÜâÔX>¦?Ñ)v.{ÌÜÄ ÷wvC05İr-sWZ¹¸j®¨çS`¨`[}óA,®ëÄ¶²ÆQ :Z ì~=RB(__–qêÆÖ{†Må!B›êètbAæóÒ«xG±8	³_§K<Ú(êÚ˜1C–MUåN_|„sh.Î‡ş\ –a–`×ÿ‡±·‘aâ&¿Â/pYMy‹7_gVÄ\ñ€‹áÃØ”“ÀÛÖå|çrY,#ÿ_x#‚\¬§½$ÓÎ] ×©ğ´?êĞûïú'İğãx@dŠ$³&Ş®ºyß+ªYâ£€)±'>Xâ½Œ|%©´Lí,¾UÊRº‹K3á¢$êÇSeÆ7‚ÊıÀÔÀ›RÂõÜúƒĞVÊ£ ´A½PÆˆ…k_ÖŠ6¾n¢^ŸÖ:J`<Ñ
â‚Dvî° Zø5•¬ñTw
Ü©ßø`¬áÛ„ôSøÂÖ)å>İïMË|e•§!®İ
´ºZ¡»*bù+“Ä½t2›!,bße6KÏÆ¬¯-83Y À¯ó>ÿ,fje\™]÷¦x±M kBÕAëå°õ•_/øBØ_†Ù¸°ğé¿àtF¨dÓFÕv½ÊÚàĞER²Ê‹C©;½u:•Ş, Gi£HíÉÊÀ?9-Pnêhíú¹!`.yÆn¡£IDiÙG±¶½•˜9~ìeÚ74XWşğ|'¢2îjô÷p¥{F*´D…c©rÇq×÷¸„æ+­f˜ª;Â«h•Ş©ŞÏòâFÃSPtäfñ)İŠb¹×®	¦#¶÷‘#$MCóFIy›ÎNd1?~¸sÇdÍ^­¬4>ê}©2ªivÍ’¢ï*s•¤FS³Bu© U¯xT‘pÀ)½SŠ ôrD ˜ŒÕ0*ètTŒJ‘†Z‰ª=}Ş¦¨œH›(ê‰º ±ï,‘«÷¨ÜŒ	ç©œºÂN ‰å×ÈTÉæ ğÊ€sCqS±Ägû    YZ