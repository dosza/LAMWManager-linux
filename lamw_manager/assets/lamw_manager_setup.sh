#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3421236707"
MD5="036ca14e447b9e19222cc68ed8496956"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25556"
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
	echo Uncompressed size: 188 KB
	echo Compression: xz
	echo Date of packaging: Mon Dec 13 15:01:53 -03 2021
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
	echo OLDUSIZE=188
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
	MS_Printf "About to extract 188 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 188; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (188 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌâÿc”] ¼}•À1Dd]‡Á›PætİDõ"Û:ˆ–c´–3XCHÃÃ·ƒú36ÇéxM)òÚèúÍ¤ôSJ™’“ï¢x*ş.òu[dpœ$`¾ç™¿Òc neVõ“"õ‡X@ÿùËŞşğ;knf‘V›ÈÕ£=I`ÙÊD¨ÌŸ¦Cı5^dÙ±«ÈñÿRúêœ(ì)uS—¦™aÓÁˆ‹"s•‰Œ!JK#¨Çï «²!vçT1(N_ôv4(Ú“ ÓHÆgzßìïJ·•Ö ~âÆó¶1‡ÃQ;|Tìª€¡BNü>Um+iÁ·ÿ#P‹“uqiãe ¸íÚÎUNÈbÕ ì»ÇÉ×%÷Œ† ­Õm—Á'ÙA÷WFµ· äCLŠû)mÿÎ&Ç˜"˜*'ëmå)³}ÍRØ8²¹í\íE\‚\´ ^*íb9 ìG¢¤1¾ô¶¯æB$ôWÖöYÈ²lêŒG‡!×øòœQ¥m¢œe]|÷>p¢Ä‡P‰÷,­5ÔIzs–@~WÇÙ"?õùú“ïA¹Ö'Ûb£Áb|ğ3éŞ\éoBÛ+}½ëêYb{tì_ä:A¢%œ:¼5»9¿†¶†ÒéÑƒ¨ÙÂÂ ªnN~cö>eú *K¡É‘ıÕU	AGŸşÎv —€$ÉèkŠ°S …ÿ•Ñ¶İ_İ$v&ípµ‘üˆªz”Â~/0´šw¶€#T]ù( †Àı±ˆ’¿óĞ²ôíˆĞ}Ê<ß„»–m€ÿÀµa_´f×¡À1?ˆFšglÚ.ss¾oVt­Á¤·‘p˜©ø8^ìEª^I
ôoñtÉG±9A¯eT¥ÚF§%tÁ2Šn)xi†%f xŸÃS@‹"/Aëmj¦•IŠIÖï‰ğ£‚UÊAlcèùÎÌ3|äş…Ï‰øÔ–ÏÜ_óåĞ3>‹×œY|ÃÒˆŸ¥ù$îÕÔİSòtù'Ùn~$à€P¶²™6NeÒŞ®ÚYˆúêÈ¿S«©Èçûˆ³ÎŸNnr} §Á	VÉC¹pÑ.d3IÅ<h6€ˆq-¶ÀdíÄ…ûv+z^möş·ôc‰Y›”°âsLœ®\«£nG-¶Ò£+xvUØ€¹lP†D¬yS¥ÜÄÓ[$•F@ÔíêáÛÊÕ|QûáO½¿¿FÃ«÷nr&ŞI^6\ÎÀ˜eC÷ÜÏH™úÒ\@"™Í—é/êòªÆª¿…ÊÌCéä…]ê{Û<oˆ•ª5ò(|'$¡¯	æ«t 3=˜ıÆk†	m<ã¹ÕŠ}Üy.¶q‡-"Õìº°j¢zI›:ı<[+îPˆpe”õBÉBŒèŸÅ—dDâÄ3äáùHvo¹ÑT×Ù)ù_NÆM*}¶Ë¯İÊç¨–£\èf76ğYËSoÂ„^É2^ê’f×n3û=°ÕÏözW<õ+Ägò
)3ÍC§fîÉ}Q<}Ì®\Ùh“ä`š
!çÆ»´t–5û¢ÈÔêÛ½…Uœ$„–Â?<üØŒşÛÃj<a¹+1G§Ñ‰S/šÀŒ|ØF¾ÀTš.ŞBğ©ê”1°1¨d)!o2Ğ+q`e.®Dr<Ô¯¯8µÿxVösT\%¹g®¯/Ktz–KÕ[Ã¤93ù…¹1d\«Ã
oÆ—dÿ,@@	PŞ„•7à'5yÌ~¿PÜ¦Àë+¢5ùX9À|è~ÄÂ_âÔæÙ°!…aUl+s†áÂa¢‹š;÷ì=´¦ˆ-€ß?†¦mCgÀÎñq¤[RsÃ(÷¦˜Àf:@­ó@!/šòô%´ƒîw¤3Z(ÉG7!íøoÇL¿ŠâóˆNr³şŞbo{¬˜o²öÓ÷Œ.¼–ô™ó…Y«\3CHµTƒyò­„)4jèEòï™¬¨7áií"àÊùñŞğ•nıFÓÀ+¥–UEOvO†™¥ÙU*îş…`Ş
úcÜ0©ó]{£H'ùX{ë¿°7”=¿ƒ·N<‘'½4~ºOYxIƒäá„é”ş¦~ÁY½'I‡·‡¥ĞZõyÀ©ôâÁÔh4òa’ç.ÈÒiŠ‘õ ^€æ¾Àœb]µAê/IÁï)“‘Ê´ ¡Ê|,²`8ÍuÖ,D½²kØû+ßÏ¤–ó¹Z'xÁkFÎZ¯ûäU>‘”.IP¯4©´¿ÁxŸ.-æû¦Û»¸Ró‘ğÈ{ÁÍÏ<ªê?•i9&Áæ"ğ4î.Öw;¡íRÌnT+~ü±Š­±€†¢ì‚d}=Ym¿}7¼UòZA©‹];ôº ÒË>›¹ÿş9Ê+ÿt©ÕQ<±F^g >¨æÈ£XMWÁQ:Œç£ğèñ‚ª€É³Àçìı®ï¡ƒ2yî:KWŠÀªªÊ@„œ©±SŒDÜä&P[ö*·@ÖÚ¿µjı5B÷Gõ‡™ØIx6İÔ7£f9·õ<×x¿Ô+xÿ¶a³\ÙÚ±ôöRUïR—%b—Ü¡ø®ÛÜtøU2ÄJjå-×Vœn9·gQÒ™[zÇà™Eq-†±œbÈlÒ)s¿q¸`Dk¼¹“Œ)¬ï;Í¸Õy*âáJ¿> …›€S©«>>|IË’åÜX·RÁFãi&âî#ô·¡|Öe{Ò[&XÊUÔç7”ğ=PÓş*š]¹¤øibzXUË¡ƒK4¸ŠÙİÄ^oUYä$+¬‡R—·©?üMn'î{ƒˆ-e6 ôáèn:Õİ(`‹xv6naŠOØ>{+KfD“/5õsğ^nT.>Ò¬ßÅ¾ëö¡IhÎy@A(ºíQ´…áª³«m$A0g_°FÇ!Ï9?,t(ƒ¢p­«£ì”†-ãsŞm×<î(G²ĞB{)|"—ër¥†'É(”Æô ]¦ä~åÔH(Ş¾ Uö /;ÎmHõ8ÌfÇªØÌÓç”Ï`{û@Ü%?+Ş[ËÂ @èÔÇÃ«Û¤^…­–Égãñê©bPRVó,Ÿùã«–B¹oï¶˜8é0ØÆur*1
kBC!ù;^T‚º^€¥m|Ï—4+(±†@¹6MäKƒö•œ4Êl‹¼ŒrC1†¦|Ó	ÃdõÓ	"MÎéÜ+%ÇÛ¢·¡Èâ{´ÊµÁœqÿ¿KöSB|ì¶İÁ¬ÆX4W§ê–•p”ÛØD¿8™zGKÚâ~~Öb'¶¤./¿±b1ğ A‡RÏšYYH8t’–îó¿^ÙŒZ{-°eîÍÅîÎ–­+Yt#·lÊ¯(¤U(º)ã\çñ­k'–rÖ»»o‹Ú½}]Şy;óÙş$GyõOm1—ÕŒ¯ t½¤+Ã²~1ÄĞ,øQ0ë
åN•ÛÆÏ÷=ÕÚîº7gÚÿ¬äV/OV:WáUsk7Ùÿƒé?8‚ˆ´Ê=—âtF*¹&h„?4ò–,Ñï—éåƒz<N0z|‹ÙoÈP@Ä™íÊIÏ³Æ”£	¹Æ?	Â	ÙœrYxk¯µã­›bnÚ@³¤[?áã<ştgŠ¿ä>vß{õÇaˆ-I7†y\j®ô€¸©T0øñãPCQpÎ/áízÊ#¾°²ãÌIŠîºñş}è|éG{ĞS‡7p \NÁ7WT—óö3pñ°Z(ûÉwç¯`}Mr‡Ø˜¨»
à®w3l­4ø¥»
|×§ö}¨Åî¹ÿ˜U'¶»ík´Ë×q‘6Üí¹›ûO¸×eJ‡•…+-5˜oß·‡¼,˜LüÓ*v‚…â]LßÌo¨¥‰R¢¾’ k&DUYÓóÒÖš¶sÍ~0õŸ+´e’ºµ¸Nf¢ÃË/C0åªûŠÓı»”{><daä%1GĞ` iI—Œİ­%bMg0{Uñ—°-­­ú ¿ÈßK0™óhºWÅÄ·ê•Ñd¨íQğ …¯[Óbû†ë*‚KJôÑ]ÊU‘ÒÉÎvœ<£E}Ëºfš…èGˆA¨I%sPıv§ØËñ»ãĞT¤Ûoxm5t¸’ëû2b=¦Ìh„Ï€4V“*Iq¶œ9æ¼?´;'›.R–;±²S²ÇR*•Ôy2M;¸âèå†LŒ«ŒdÍîh’Û¯ŒysÕ?ŠIé‰gCiÇ¶v2ÑõÒ»‘ÔÓë¥È|ô3|z?:W”¸FMÓîx<Où‡tØ¤ÊÑÆ.	·¯yá†	¬éL ÄÏ’¥6Ú-à­4GèÍÎîÒq¹P—ä<ØÒ3ÎÜt%}mI©ŸK†–½xÊQ¿İh=ÊU&*1ìÒ´Fw²AOD²A€Ra?ä˜uQ~/ĞÅëm—2mq'¹s>O•ğÑy7‡Õ'3Ÿ×IN¾lMû­ª“SëFÒ	³7,ŠäG›Ïû¼ßËèHkÓÒràøòãğ¸¥×N*ØX<Ç!Àkwl–Ö•0¤—TxŒ„(±ñqvdí½ªêËŠzœÇÒÓÅ?|ÈãÇ4CÍŠâ	 $:KÂ:ˆN˜X¼î´Ë×?&,ÏBıdC Lâ8U`Uß2µø5œ4U§Œ#.¯@&XzÜ"áÔŠ#Ï’ÜáçŠ ‡J¡¸ï…²>\Ú`OÆ|÷?fï Lm÷—ÙèPeM´é9œnw=¹0¬v+ô(Óê¾×R·È¨åV|<’Fk•ü¾İpóÂ×vhì´ï´¡óÈBœ+,¯Ymá³sH%Ë	÷í%W ”z{šš¡±Q¤ Dtm´‡~ÛÔÄœß@‚£a–ùş-6§x|Ä}äUŞwŞ¦¬§ÓZ±©xüæ„liÖ6g–}öxvşñÌ’è„OS•1<ƒª¾áÏT&*ÔMŒNôUÊh¢æ¥„£À‚ÓÛÿ36ÔmÒ0M´fŸ<<€p—›u{Pû×5¸Åõ`¾ƒÕœŠÕ¢&bu+k‹†qÜ†q0 ¾£‰¢i€J»Ô¨ô:„‡)m²Baıá85`¶ˆqJjèi;®ó4Ø	'NÆ¥1
^ÒPN0_ÃR‡yw%Ï²ˆs sõèéÉ£2´O®€çQ3ŠD•Î;•ˆÊ^ØjuÖ>¹A‰œp1>]ıú„i]È¬ÓÀ"G	ø¡îD*W(‚…u3a~uı“(Õ»’›ƒ˜¼Ñ¿¶VcOJì,hyWÅë:ä\ª×4â5·ö¤O5_kUÿ¬ûÀ–åº”ïÈ°™ZewÂ™Üx±}mÛ 0ŸÏs…›Ô(wğÔşvã—@Ñ;×I+×4k”(ÍÛw?-¢Åì“ÃÙaŠîOès!d»ÉSŞ¶dtØ¾dõº(ë,Òİ0ëù`-ïuã&¤ÙI¦ÿï!¾ÙÙx9(9>¡Óˆ¦Üø¿õÒàXÔ]yêÙìéFHÛS#œ¡opâ1>T†¹˜
!€ğå½Éˆƒ¿©^#ÂZÏã±Ú19:¼/(; V¢ˆµ o%l«§·¦cÀºı1Ùp®O?"ex?—8ª«]Âu33I#p=EœÙgv8÷O¶8¡àŸ¨óKeÎ2´=?…t	ß™fÛûÔ˜ >~Ğ`‚S±ê;ö{!åÙ8	¿ø¯æM¬ki;¡d,ˆ°H€(¬åAU¿2D¶KTZxê ÓĞÒÚ}Î)´Í¼[$ÆÎÉ)-ä†¥E
+õùúÑí&7—&BøöFº}2Àÿu¡¡°ÁÛà'Rƒ£‰×|5^g­—Y• îÚZoïLáTfõ#ig|ê¡O‡G÷&*°ÌîN
š
T«b÷Ä´;ˆÍh‘¢çïÚÎÒ ìq*õ#Z#v1sø]9 óxS”8cÓO
[›Š×%İñ.mğoYøĞ?{EDşãƒBœw”Áí‘³º-^º‡åoë3=Ü¢q-GË‘øŒâ´ÈåäJwZéõÆŸè_ØvºOfàÖ vZY×Xíêúú·§²‚Â	F	_èeû\rê§¸f%ªøåÎ»!?±YmøÜÏ	^Lª€°CE*D]µÍ—9Wß·ª0ŸârRµY„Àœ oÊrdÇ„óµ·)áhéîâ¶#cáªş…d
~v£§EtA°q!Áÿt2ÛÎ~
ÌeÓÍ¼‰æRÚä‹Îæ/)!Î—ŸW^y!~ç8	VïÏèX×óªkƒ§PŠt©2V<jìàá&w¢j¡iìş÷v ±ñ_9yŸ#Ù}¤7ÊœHT9,,åø -¬SˆÙ$ø°Í4Oê»;Ás$ êp
˜ núE5Ñ”¿Œæ=ŸŞXPn{{î'nàè~Ób›¢9œYÑñrYcízùx‹–ŒWÉUA½§È•¶&Ë4ÁZğ·‚±H¦Šß"¤uØ£Û˜Ç%CİcH—®SA©£ĞX/ê0+ê‘ãÎ,:x#¹ÒºÚŒ“xõâùXÖ”èX±¼dÕNÉ ¢JàÎ%¡Ôi€›ÆÔ4WQ"=ÈMuNï>Ş\¸¨‚âÉï4 •Gc§X3ãèõx
øó¿³Dİ¾ñj9[ÿ÷gÉìèly¸ãúè¨@ÍÙÙ¾º(I¤In‚ÓÁ‰ô=ƒ…’ÍaâŸğØ›7+æÔGUéİD­ÄNùı‚¦™dî	<zè­H„Éx–XèôÈ!ŒIB1P¿–¸2KÂ`÷¿v¢yŸÔÛ/	êf©Ö4¾ìä:½Ÿ(©ñˆÈÄfíöR³‡Ë×¥€…öÅl8¿'¨üÙ¤]ôñÊÒ“CÙ(§Šõ”b¥ş0,VÑxØÎı‡£ÅZ½ñ›x…v“ÖC¹"kÄşryüûÌ©ÃO}Òqº6èkƒü@³f¨ŠÑÀ¶÷›nx?Ò“åÎ²ùo¿M‡¼šz€l‡/ğ® QhµzwŞ¬À4®
Ë$“¡‡,=‚˜­J‡Ë­kµĞ!ô,°o¤®çS¶0ÀÍÍîRèê‚Ì4¤İé¼TŞS-÷S·uAó} ÙÉÊ¨êÙr²4ØMÀqL ¿*OA¾TxjSÇƒ5&zO-gQÛšfa•eAÑ¾Ïˆ‚Æ œtçß_TÅ0È_§‰ÍÂÍfÛí¨yø/Ëb85áE›¼‚!¤6‡àg×
,óĞ‰—ù¢¾%´h“°\gãñC³Jğ<_şæÇ¸—x£¶Œ¯¹j%±'I`Y æ?aä[›Âe9T(ß±„Nqs¨­•‘T¯¡h¤ÒœÆ¬×ÂÖ”(p¥8şj¸É¹.!IoÛˆ„Õ5K»±#1úòš¯Éún# Ë…Ş€ªP3°m­ãZõøv†q"
˜©ÓB	£&)½è(šˆÍğàÈÿåƒ$ş¶ûíĞ?W´ñÜlÆ`µ?ëğ…ôzÑçê]Ÿ¡ÏÌ4ôâM_ÙgÎjiçT&{Ü­”,éáÒ†<cXéfµÛ·m*CXNıÇeÇœ¿¦ßÅ¯Û1f(ÜŸw	ñx(ìe­Æƒ;ÿoo7.=”›Ò6†_àÜ[q‰êıÙ’—¥­UŸ}Ï‘¾Õ ÅØ_ƒŸCK¦Êx“â*kTuè*Ì(¿«^	Öò;>ÅØ›™ŸßÙ‹M„mÅ ÷[ë5ù&4ù×•Xi¢OàòfÓL>¾™ÿLánC7³G)Éd’¡#ÖP^=òÑÍ\_aS¾*ZÑœÅ©aß‚M”Ã$,L¸bM<·hÊq›l<¸0-Í
Ÿ³ıõV	zM
³ÛÙêaÇµBÔnÓ¥4ÖÊ'Â80˜[Ú@jª\Wà~‚?îr;^¬F\C»uåøj-r­=İ½Ù4îù²·=İ„Iö?Ê“"57ò6²tQ.1…UG|Zú>ãö:ƒ¯cêFI{6Ê„ŞƒÂËFİÌã>ºQì7êH¸eóArücğ€”Œ½áEçÛ}ñ¼?y;›å;^(ø§¯Ğèìü… ”ç†Ã|oa« F£LÇŠK-ƒ5•ˆ*òó·×}»HÎ¾9ÈNîiuéUÌ¤Îe­ixLù²¤n>ë×äVt²ØÆŸÍRD_Â™&;G˜€ÖÊŠõ¨èñÜÿpG0’~›ëO^Ó|ÒMËöŒO/X>”àÛ=3MNş­µ°Á‰™µÑ²5ÖOºe-±uZqÏTaòøÆ$¾e®¨'
Ã^ğÍçIš w»a»¼:Ëv¹ùoÀ-‚3ÈÜ¹j]JC vÛwdâoàğ^J6§+Wßtşc9Äƒ‰£FŒl@ÈdE3Z¸P;ıG¢†^ÇÀr}ÖÒ81¡K¾ A k9c^ßŒdÒôÇWÀn*×üèÔÂ'5Qv(~PF20ƒ@³Ş|O8óYT—à¢tĞ?Ê@rıZoFvÿEA-Š9~ k5°|rpš¾–f =H<nš%×zšéásTÔ×–D'¬é »³Æ2ŸçO”eÇµK*=SoÔş_÷V"Çdÿ¹óÜÿiXÿ*µZO¨÷²RÛ­/œ¶w_Ü·I³¸=ñÈÏ‘®õájÂó ˜L¹ugÀ!gÁ¡†b%dºhØx¢m¥ï~àh7‰
!Á‹A®/>ğ†GxÀ.‡GÉ9¶?;®<ÊÉbB¡0Ò­w@àø¯Š…²ïædÂ»úö‹*z‚GÿY˜)˜
!o¾Õ<í9ü¨&ğ|NGáÏåêâ,²eqÔ[irÒ~6«r( ˜}&ò¼5ŠÃ ë÷^yäD];|îLè]ÃşÇpnÅd ­»ÒĞ}Ç‘TRK´Çšn<ÔK© ô–õş¥Á™MŠÎa~ ì½½œíİâzñ¹¢†mˆÚsçšD«3ep"sZÀôa ?ŒWIö¬ûÔ§Õº9™(1Ü·¹ñCÑÑ±?ùşt¦Á·}'í–½2zı;½#f%gî°ıÿs&LáüÊ×p…ÄùÃ¸\GÇBM]âe@•ªú"Y>4Áï
 `ºğJ²'¤<ì=ÄØâƒ'•ÇN dÌÄ¤,hØ_Æ;Rj9ãÕF’ådáàâø5¤DÿEçº§å‹«j 	œĞ _ø?«	)×)ÍîøÅö•4jc†€ã27*79Ÿ°fzæ2¨Ñ°¿@”Ü£Õİsá—)Fjwuñ…è‘Æ&?–©=ª¯à.¯ÔÙ¤y*V+ê’¦m˜Û£qÂ#Wß1çÜ©	ñ“qåéëC¾§fójP¿Û8ºØ´ÒªE“ğÍ=á”TÁ€H©ŠRÜwS"Óxç\UÈéx³”~$^@$O¢y¡’…R¦Z€86¹fí`Tqİşª
`f¿"s-9„,N¡­qß
Á}…BÃ†»õ›÷ïšŒÜØ£İ|œ='èâ¹#_Mk©VëÅö™"ßÄz¹{µñîÚ‡E¿ÍJëvÑk,û;Æ‹\æn›„ É ndµğIr²„* ”º¦o“¸­>f¼§û1úõ}IÈ®²ÚŠìîhõ®DĞ!Â;›ÊØ\]>«nì*Ğ [,á9¼‘f™3&í€D”¬ş„ä]R‚DfE;#-ÑAQ¡†È««cÀê,#fÄ0‚{$#¦Ôæ»ÑjA8ô<½z IšCüså”+×ˆA!J¼Õİ†Öû‰}]?Õ‰uÒC6aÁpê4òNlB))¤gË)ÅùQF¨k_,¾å0f… #î^ÃÒ]Ÿ¿‹œ!†"Ûœ­ğúo8Õ[FŒJÛ~¬û0&ÑÏèÜ]2Iš3?Íú •î>t‹çôI5UßáÀWy‡C/c¢‹DURn†şò¨ ‹%œ×|JS‹Øu.6ßXÀèÏ`““D›ÛáZ#kÿEß2™9\Z
FY	½7/ßgÄÔ¶ÖLñ¢97Qû¹Şè‰›À²­P&@\ŞwèÍó´Ø©¬ßœ•GÏŸÓíªaÖÕ‹Œ‹ª\Pû'ó–e)"0Ñ‚ªuhQ¹
Æw>+eÀÑ05æÀÏ'ÈP<¶øˆ5Ô‹¨¸<æL®ÑCr©CtîüŸg˜4X7É¡Úª\¸ù°Ğhœƒ/1è:f§;iò£Â>V¡UçŒÃ™rag—K€<³´u|Yr¥‚0
®C¤€–ÜıÊfM£abÁÅ4ñÏwò·fÌû÷à‘tvŞF>Î‘öêßúâ­ş“WvR·~‰Åñdñw—ß“ı__hÀ”r{WWÛ/ıˆv³—Ä
õ=İWTJÜ¾)	{3$¼¬x6Ñ‘7şô§¥®¨qB7º)q¿Eg1ŞÙàRK6/¾ù¦âpd4·QÆf~ËX¥Hk^#™wXfø¬Ñù|{UÅl(Şl¥N” Î¢Ñ®a_œI¤ËŠAƒIütSĞéú•¼dTW<C'“÷ÀÈbró~ãÍô~6ñ’m,7TîÅôoîÛo¦ËdU†Mb¬±ë­Ùşe'FÊÿh<Ê=½#Õv@,ÈEÿ˜ØÓş(£•™åÔ<}”ıuï·IxÂÂìàêîêöSnñ±I^½Í§•—€mÈ@#¯99îEEQ]SîÆ×ûx	k>¶ §FGÀÏô³’5e›xl‚ænP.«I!&S­ºÊ*Ÿµå•| øH×‡ô'ÆP4N2Ñ™ÆğFi›Ñ¿Ç‘›j‡(wß DÆ\Õìö€fØÑigqxÂKõ†˜·ŒĞ Ô8Á~…—©×7’éÙ¾"¢ä@–0~XÅˆÂ´OJ1ö:›iÿöK°Õã h×‘Yò/À‡¯WM‹¸ÍQ>|…-lÍi>¹Çı~{Õ[‡<6ë©<·†Mlù7½ìÙ=—ÖÕóávŸK¸·ƒ(ôH”$ŒêïeÃôı:—Æ{FO·±Ï?¯‡H9-+C¥^b¨`¨ñÓÿâY®äl²5›WDÅ¯¢cÄ[É±IŸÅùOØ^ğ‚ÑhP‚•kÚÊn¾È†2à‰p LS½i'Æz¤éÛp¼£º0ÚYT@QÙX@cÛYÙ]ÂK`µØ@• ‚ƒ†UÎŸ_óŠSv;Çu5ìO”şò„Ê›†À¢/åıhÏs‚¾R¸ú=9ƒZu> P[ñÏ$=Zjçö³ÉÜ%3»w›BØ!ë’~W­¦8H5“8}Rd0@À²ëúµé'*2¤¤ÈhÛDßKN{ÖÉ´aôûÃuÍ`cr­Ïİm²;æÙş1%ü‡ÑÚ­ŒÍï[U²°„ğèP’~µŸ«™èi©û|Â[Œ‘‰XÃ«şkyµ¢ â¦yÏ~bWş	#nh6Q>íÙX#[¬JÑúÍ"ÑÌÌLôäW»|nØv`Q±s°GıõGëa1n‰:‰‹l¡-Ÿåõ¦e"|—2ÁnšS<ï:P â6ˆ
~ÚaştKpHÀ­HË|à©‡FÆsßy"6öM s
‹;äÅ!«Ï8·‡ ƒ’èÁ¤#—¾c5z²Æı‹0¥“¥ÈÀA(gnoO:×ı½t€P­ Ğªò‹fEt=¥ˆ2O›Ş—8ËóüHˆ¾\†×ù²j·çæˆïg¬NKØyÅñY}£º’%RæMªm»¾m¾¨M~æÁ¹0üVà¸¾«ºËİbÄëYÁ*öØ§ÓïéLŞ¶¡İ±æÕ¯1
ƒ%Îı	Ş}P	28|aÛÎŞÅù”?"Ş¥zåš&»ğ±0ì&3ıIÄé
ç~—„!ğğšß§‡$„<Š“ÒáÀäI«±‘Q³Eˆ„G»ãZE^Ğ›òÓŞd¦,Ù½¦‹×®)äu<Væ«Ñzà€zØ·è…?UGôKàø®‰º¡+npáewŸ
Fúâ¯f¯[ñ-˜²¸ÛíèÄk‚Ç2ğYk—zø‡.Šİù+vóƒgîÎ:T2±aÕ“kDÒÑƒÕùãŞlÁŞ¡c»—;Äya4èKWßErûıÆ‹‹;:uz¥w÷=%™Óêã2Û2$ï «AúÜÓVÀÜî?=Å]  é‹"&½ÑTà0"[×kÀ5Ú´±Ê¦±}öWHj,zfLŸ±Õ6ÙÂâ¨K³"t â tÍkº²{ä—QÍ×Ù|€ÊŒn¥A]²¶í*îÑÊ±â•ró¹¡dwtœç³èWHA4"Ï´õÔ?Å _”øEÀZyíZ»ÆF6œjÌ¥¥¤ÕoÇÀõ‰r2ä®Ë9z#›à„L1WÓïÅ§­ü~/S‰èo^šr2í`;”/ò7.’üL;Ÿ ı¹‡7~?{ Ô¯§øóW)!>ÜK{Î+¸eúC1˜aD¹S(9ùìj™Íñã”œ8)ê,so›€¥ñ»f¶…aâŒn³*¶ímQÖœL/·‰ßÊ“ŒsÔÑ’ûDîhe©
5ï#~´|2Ú&q¯ÇÄ¡?Qé×¤ôì¤AyQ'ln¯è]îËx¹-A¼1zñ~ÈkĞ¤B:!“láç½5ÊgØJ¥İ”&P4ñW7ò®öúpü€2'`éşÃÏ×÷1Mà#(@và‘ì˜
œ7Q¼‚6³Ær_&‚ò‚C4\ûÊë31íaºc¯uï vÃf~f¥öí³ÉÙÿë”rù–À¤4™óÈq[Hº¿Ö“àÜ Ñeı®2|L÷TÄ¦Gw¡Şèçf”Q>p¯\­j^Œ?ô014¤÷2¯­ÒĞ‘eımß1xdšöŞfêº¾Xû”9ª¼ªNÓ°›Ørdôfõƒd4`T7ßÑ	J#£úU$Õ|²´7Ş«ÿš¨=jB¸W·)¢/eÄmµm£m¶Í}PÛVCÜ×±áïì…-úú·&wKÄİì’ÿx #&£,Ïg¶ÊµWlƒ80Éz?(ËE}¥ï*]]!¶kÕ4ìË¡5¸—{é¿tTrE€ÉR	 '
Å³Yr³ûáRJxt¦œBê±BÅ®dSØÛõƒ×n¦sà"ê´^s;2•}c2ÂT…ÅìİÃêÍWUQ-›f8ƒ³w!öÃPúE·û|B²ä7ÔÀÁtª(;!és¤AßÕ@U‡äg)~çòS¦Ñi¬ÁY]›+ïÎÁ+áİ=²ú

‘“xƒÈ:ğh„zqp@†F…×gJºmt¨ÿ ›“ôs9PK˜ \#şÙ¦3m~™õ½ï“…õX=XĞ§*á=OİŠ¨ÍHu€£ d&c[¶{…™ä_„Rf¢Rlòş”Ğ3©Ğ´ëú&Æ÷È“VğP=ßbÌ½f@öü¶ÊMüÁ
`ÍÖõ_åÊïÜ›rãH(ÔºÏõN˜/¶çÙ÷.wlsÓ¸ï=X
ÍH‚·ZL ¸µY€¯z`c]CHòÖ7(»Xñ›3øCd×Á|Áåßü›åôÓáiŸWIP{uÒç¢ÄAfFŞ³‹“ˆµ5Ã8U¦~ßÍİXÙQ¬vöL²E/}†q>•	OY²ËånË,€CxrçH£ÉºôınÉw+K-¦4-®î¥z}´6 €®ı½Ø;“¥ÄsQ¡l•Gxbö&ÅÚ/ª=¾ïKÙß¬Ïgñ¹Ø¦¥”ü<µÉ€Ëè8+UM¢ßî™LàšU Ò€ƒPÛÉÄMC=·„m^”ùã0\î£Y8œ®ŞÆ{L}lš*ıT›c–]ycè^Lğ]%JMˆ.ÉÁñ˜)¬'ªi ¶ÓGVFøzÇ
Çu©P9êÀÒSmw1LSeàDAî5>M8g»Nå ’} cŠ–˜MûéL7Ülk]æûÁ|¿cæ`+°nl3`)‡’!^‚„ËËİpÿuAÁ5¥¼FxQLã§ŞüÊ>6nõM"¸eºl¯€Q‡9¹E›ãƒ,	ÿÔórÅ~(]ÎÀï,Èmdª?ËøJô.(Ç±ÏİLÈÜŞêï‡ƒëÿ,!ı…á`H±×m¥}•˜eÉusEwxoò¼ê—zÀêj/¸-Ô!FÅyöjŠ¶6Ù9gÆÿO®#¿Ø›“FS7†5lÇµê4rúòµax¤³é£Úì«y™j«0qcõó“ñ^U ÖT s¯³İåÈÅD!ÅV€âj«@^ A#a–ƒ¯v¦™6t¡B¨ò(3Â˜ZûZ[âfzúTwqü).<YşEvF„ÉdÅÎsĞÜœ×¨º“	AzÌX:~J*yáŸ¦Á'LİÅ¿¿sFú8Ò›^6l¡g‹MI“íKŠdµ5ÊÌØ2¥v¿VŞ wûıÈÂÍ¥ĞßH4¢ü°ŸrYx‚·áøŞö¨¼áâ¼+7 †é”ål *ó>ı={¼Ô±Hù@€¡úÂ8¥šèÛï|=ÅÀÁ‘ÌC…&k8<;pcáì2QÖv¡ÜX[M4²7bšÖ­×\¬p"şHÎ\yß§Pî®*éİˆiÑF‘n-H&b›`K|ùƒXêqdNg¹o¦MiDb'ÎÆv=Å˜ğ™Ì
ÙN™Õ´•R„ÿ¯¯rÃJ¤ºÍr;<L×_üGüƒf‘®.£İ}GÁ?¼¦acn³yò_nyÅ€ñµ×óÔ;E_dz¹zÃP[ÏÂòèÛ„FùKaÎ1¤vj†@¦	Ğ ¸é^Â¢t»ä´[êv²¢zyv²½:Ètósä¿‹Î!ø¢ÔÄ>A”Ô´sÊo/	úÂÑ¨,´æyJól
ô5†›s¨XÁ<1:5ğO|¾†ò±õ†çguj”mk+'÷ä/é¯Ul…†½§‡¶öÈä®ÁF8eªÃäî²5‚òëü’ªWk\Õx#÷ÛK–û™lB8«‹ğeò2.5¸°Ùù[OT0²k–8ÌO?íÖœ›Å:‰eØà W;IM²3\Ùˆ>ÚH]Ø‡S9Q¯Tòàá¼~ãGâ¢¼s"ëA†:ÁZO¬D[Š¹&`Ã)dóê•Y9Ë·¡m7²=Ù.}ó+^ô²H*<™\ŸşßgÎiÓaıd¹\Ïù	8Óø´Põì¢ÌüèiZ¡ÉH7½Up*`#4)Ğ^öiQc%€zŠ2 ·ƒ¨Ô¾ÎLÚO¬¹¼ô—¹§ı<›+§ˆg†,>OXóDjö¦cÅ¶ŠPƒB`!²¢3]]ó@pB{¾S=L!‚Hƒ…Ih Ñ²~KãG_·¥²Vœ(©êt~ó¦äu½Hëp£Í	Ø¡â`?\Î2P5£Uí!”€£ıù¼éÄI,àS‚ı^¾Æ)Eú´/Ä&Se?Æ ]â“WPœõF§üèq­„E´ÀQáßOåœ÷+‘«›ÕŒíá ˆÁ•Í…›w
3i´µÄŒø­Î°`õåR© ØÒY†‡² ¡´Önÿş[±T“cbU(€gÇSV”öA‰ÿÍ6
¼(Â¶iƒ~‡„Xòß‹-# ²îÀiP£¯¹Õò¬e«ò/M?"ôe›~&’pÕŠ³1pîuLf7¤ÿ„sÑ¯1¢KébÙ½kéúÛ“	’ˆæµí÷Ø›¬´·¡H›A7\.	MÎM·±Ê¯‘gg˜«õ‡§àÂ½²ï»+akqÔÀLO¹‹2y/Hç:^QÇcß¡
Špô€¢ºm@´ôQù‘ˆz­vËAóÉú!ªÁ<¹-è¹(U5+»õ°eviv
óÁ%Õ³³H7I×¡çÇÇPÔ³Öø‰Æê\‚¡ÄíJ~pCÃV«H-m(M&E»êêÔºÑ¶—#XneŞOMòÁÍ\Æ7yˆ°‡KÍÎªˆYÊôÛ¸M’f–sæk.Y,ÃÍƒdrÑHoÖ€NJ°Ëšp°nıDrÚhüBŞŠ9'7o·©€¶“j‡DşrÆ]°nâÔ£ÓÅ\WndxŠˆ“Ô×Àç;N^8“¬¡2Ôû–Õ|¯XòXàSJ¶KÛÔôö9Šƒ±1+ ˜¶&d®ª˜¦Ôu;Ã9Í…©…É)ªB+ §W?uÒMü-LJÄ“K´­K!Ì!„3c(¶ö	`ß]2Ik`ÜµÈ Ò=á%Á-p¤¸~¤àÈ¯c51¶ß²­ÀFd¾Œ7Óœ¯ğzOI‘Šêøh¯5*1Âú„MÀ]·Rá€ˆ; o ğ Nœ÷-¬½yC}.ÕıAe'³Õ©
|OFƒzA‚IxmDIó„Ø‹\ÑûCJÒ3úv´Ò‘t§šı³=L©aïdù|Yq]¶#Ú.H´G´±ÃÂÕ`hüÆóÄU’poB*Cså«
fÎ¨9‰dÜ¤×zß}ªıHÚŞ,vAİŒhìeİ®†“]Bk#T¼7ËöÿLv¥â†Œ\Ã–D ©ğ%VªŠıIÇRB}Kzé¢¸Ái’LUøÖJÜ•¾ìüñ¬+k€¬ÕâÿĞh bşæÿ3Bk‘ÿÖ²^OgrfìÊQ»v'Ø
‚öŸ›ËÇqÙÖ&ïÏRhÍÊ×¶Û	Ö¾|ÙšI°x˜GTu$Ÿrõÿ?øşkò¾<acŸåï&û8]ˆİn`Ãç1!—R/‡Y €ÊN¿9¡f¾^!ŠıWJE°6Ógê~ …˜ˆşÈì¾–”èvŸæ|)OÈmØ*„Zš†õ7ùŸÊZ×B‡07ã—ÛÁµeµL´RõSÀâ"½éÎ)¨²ö·×4¯mè?$"5;G¹Åb k/nL´'ñ…Õ"D*k(¸oÚxPRxÕ¡%ššòŠ–¸Cw`÷ÜÄi‡¬«auˆQ”‚]­şDÈ-"Q6ùJ÷ÑnÛ°YÂ¸µÓ©
{ÂÇ#„œ””â´²vl"ghQ.YdK›8;áH·°­a`¾m%çÔV{SN6Ø·Êgx©—Áz¸8hÁ‡Ì¬ÁÊ‚ûw±¡§VPÍª‡=£¬€øÔ2àfeßÏÀøoËYVV%ìÚ´y¼N5†lsqfL xƒÁœ7ñu£ıÎŸÇÏ‹œ|ÙÒ7¿÷”È_@ˆ ½#C³ì~¯PŞ„Ç.ø+õ²±ÒïÌJn6@[HĞv’/8P¬£§æìB°ùäDlåÄµ“2$Ÿñoóã9 û2À¶$û—Ê.„$wœ4_Şó <²óBô˜G¥	ß¥%®ÌŸ,ƒ‰¡|´øg§ÿ±TN¨”f×û5ßJ†¬ ±§Ú‹L•Íc 89ûM/“|×cÿBw|j;1RzS‡r`,š)9ØÉÃ¯9KÒÂlKBGPv¸Wå3™|Xÿ«Ö«ú¥HÜlPç`Êô’½¼‘ sxTlı2Âù«á®Î’bÀå9j?OÕ ß!¼Â‹ºo.<¦§¥µÓZ/g@AÛã9 á¼ñŸC;`•ôq˜÷è«r‡	ä_N¶>Ôõşú4ıÀîˆÿùóxkcÄìÛnBæÁ•	Os¢K‡²¦kË¾×LBş ) Lğe™èˆA¥®‡# ½]wµO‰ØÇ­QƒI7z#şÕVKEzÛX£A\üAT8µ†L]é²š5°œğ9QLğgb¾8/Ë7#¼U!)?»4˜ú¶ë³BC(`ï¿À0€5™±€2¦;wO™pü¨L·E#İä£ù!EØ¸A±ÆS±ú¼Ê¶OÇã˜õ¤ÊˆN-Å›Ó¿™aP€ıÍì•ÙrĞ·2Œõ)\fÚù×4èkÿJÂ‚Óñ&“ÒÃà¢nšr™P»ÀÈ:†´nÒ~+ÉÁS%]dÔ^PfêÜƒ=^&œÙà•ŸmÍ=Òf"B¼ÍµÖDÍ^^´‰#'Ğˆğ<6Z¦3$¿øñ²gD¡CÚLùWPŞ+ğ§3˜#dÖ.WN¿¨¾UBˆ/dtœ,™\4°è|è“Ü”Ê|í)u÷lÎİqi¸ë¡ş jªOÄÂ_¤`7½tÿ·7 ŞAÔ9—Û“ä•m?¼…hi? ¨+vªwl¨Ñá%œÖï€AÉ-¥}g†mØµ¼o YÆòAÃôD·ø°·šê¦·Qá¡{ÉÛ±=|«;×Kb«Ì„v¤?7ùˆÇî’@j›ò^6ü¨yüéüÓ®«[IkôßeŞ•¸ëCØ7Åä•£!™íÃYSØ`a‚jÈ3úÏÀ¼2FÙ®eªl=aÉGèòS÷‹÷ËĞŠß9¢u'w5Ft:2 3‡…ÅS&‰:@7¿:xœ;Ä9“úKô€è#á¥;†ÿr³#Î2d¤¸å‘øÒ-À>üViã ˆ~TÅôM¹]%ÃÀ[ØÎ3ºKù6P#@%ï9 O‚ÙÇc0ÛâQ3Ø‘«üñÙ úhÆ»|7˜€]Ku‰Í*ó–.)[¹®Äíñ›û¡/Ó`B¶áİK|Ã1ê¾(ÈY^-‡AGnU‘6HEÿ“§Å¬[Œm efvºĞÚ]ÔjÛª&j˜šÜ~h‹‰ßåøáD`fËò(z¿&8Z–(G9x~µœ—Œ(–Ó§bzçŠœqº½J[Mvo¡ƒ/«¶®ŞuûÓÖTH+(7,kõğáËIÁu•üÉp¹35l"]€ÿ;ØnƒíP£zñ)$é·âŠ§ZôàU'Zeƒ˜¤ç£ÕÁR#¡ã†bVÇVqkï¯-Tr&Æ¯¸*9mIGR_Šz-ÿÿ“!®¸b‘d£3çpÓ`DÉÎˆ_ÄØYiŞ<ò­EÄ¡/¥¢ïÌÙÙ-2™^°.Æº;1m\<@|‹Ötü}Ìlt
~~Ëµ¿ºùPeÁ‚¨ÊŞ/“İxbãwËQ×yöêˆ20Ÿn3ªP9wˆ™'×ÙÆ|b£%™ÁsuÀNçï©ÍÚAó3Mz9›Õ¥]0(Ã½B0”ve;6Zø¿Æ-š46öX÷“wª-¾jÎòÔ·NÛáGsàÕKÃ„T"Tˆ,F²d"v~‰£"“XÏÑ%¸“Ó1´—dK‚§Jy’Ït.<«`Z"É€Ò‚öo8 Ó»Ëßdî´—çM)øâœ"ü§G¿å;DKwO[Ñç_Ôäp(©@Gè «ï^Ğ ÃïÔ>Wl–õ¡”Â?£
0µëƒc\+³ùîÈ†3iØ-r0±ÜuÉ¥éÆ¶÷\0×ñÔV²¢VÎ¬H«Mßßìêš‹[o'±?bğ±,¶™¿_9ÏYù¥/pQÃœí]º¢¸$‚*ëµÏvô;àò]UpS=\_ıwÃ0äÀy€-ïc´ş{st(*ŠíLÈênÄc{/ëŠö‘oØş[Š·,tÌ dÈÿ‹]èÈûŸ»BÍ;LUuO&øyõ­ˆhÎ-ÀÂˆüsãÔëÜ¨½&‚¹Qs•«õdS4\ÑmÑ«rÂİêøì¬i7­2ÉùI¼£<¾øŞOR:ªu‡±ìÌg‰c~3pƒVùĞ‡9+ÿ‹"u-"pÚŠúBX™	vúØbHóO€dŒQÔrVª±NE.ü ¥ÿ—ù ¨š¶s‘_ËŸéÎHÕg·”.¥
îz¥+ªÍDì™y±ª|nä~áó8“áêœ
ËÆ_$İd'æÌö%L÷1¶¹şrØèæHÄ:Ê8²q—Ç4SQŞRø/ƒî S´S&õb2%7G^iƒ­ë¤®¯T>íœân‰–áûş·Ğ‡=:ya;Ú`ÓÅÎ!5ğ¸´%}j*‚*JÖƒZóo"ôbÀD}eñ¾…õà‚l&MY–ˆjéÖ–@™–.?ŞD‚j#¹ƒ~[´½˜4{˜1á¡ŞôsUrÑDÎÔª½ã‡†üİ”øå"Myı"wH~*D¾ÀŒD‚õ_yù$mÉ 'fôB£5!0Ï¯ÒÉcÕÿÒÒgI|ıIúrÄş×åd{ƒ­5O¤ÙrÊê’†Iá\C r„kÄ‡ ¡Óp³ò–h¶´Ò§ŒˆlÆ¯U:RQU²®Ø×y÷ø£Q+~q×Ùáü]Éî„ãe‚˜(\Ø§XÍqW#öÌ'½vÀ|Š•ú,@Ä">r¸îÈî‚·“,á"v™ĞËà/’b»)Ùa#½É¥é¥ô­¢ó†–úº>Õˆ’(i§1ç|hı©£Ÿô…ƒG¶ñxq‰·T\¡õbó½Û±dEé3­ÚÒ.DuO L*¾¢	ü¡/KÚáÄØ}Å0Y¤âg€Ã¯û„ (ù/%¦éCÃN`òF+0l´ø²NÀMs$-fÛÆHÒîn!ùó P«Ké
^®ëŒDÄS×‹Xğ’˜x4rTïÊ‹ÙW€¨Œù*¶ák5/º¡Õö›oèàLxën‹N’3´Å‘%{Ks¶€â6æ´ëpvW×™ j±¶‡<¨Œª›ôŠ3T5=O‹-¿y)/2À–ÇÌ?hÂ*&cnéc*Ig¢æC=/Ò?‰f¢â‰‰ázT©¹O7Ñ f^ã½¬k»<î/Š~õqÓGÙÿº¦³Àd6ùDı"`™Ën[‚íhÒô	/‘4iØ!íúL¬NÛÏCÔûWí2^rş•Ğ»zàz¥c6#ƒŠíîõÀƒúbYêBğÿOØkÍ>>UZ’+	óy¤2é%™T)4Î=¶zÀSHĞêE®c˜;w‘’(î¹SÖ-Vuÿ+ºkíctôXº¢²kht©ÍkÔ)º%%ş|¹ëÏ iZfŠ	wÖíe-§¹vVól¼4Âù­®áSÂ5åô†\O¡­$é4íŸç-ÎÙ!=øâßFÉ
Lîòü¾2Æißº‘*n	;M‰RQ)Ñ8´!bómÓîGÉË8Á¼	ÏB'î‹1?£AHÏ‰82—<f`Fvé£p“€€’ãZÛ s£¥‰Î‘mš— NšL]€v„†¾ø*p¾Õqy-"pº…î·ú92ÁUã´™ò<79BÚ:PÒ’8®¹Sá³»÷¼7Ağ¢R.ÿn™ÃÓ‹UŒ¹!ş»D·Ğbñ¸(™ó¶|š^ÌWƒÕÿ«U;×šhôÊşÿÿ´qvUÜJy$Ná‘Ôºj8TjøTeÌ`¼ıMH–o½Ûqñ›•sM0Ë}`-[Q¨önÖÍ£¤¹A´Ò3¥<à ÇBjÖfßhÄmS'œ'à„åÅ®hM—©ŒhŸuõ®%@8Ü¦y‡³i&°¿ §›ëNl¦dßáFâúdìóY?€t_÷û,wS‰H¸Ì,¶2}ä“'.$¢±"¶²–ù\Ë:¾>fâğ¬a­·¶™º‰¿0W4¿´@$H+N
«”sØ;.ÈÍÃ°àQ>zœ[,G½g§¯Ú¹KG†°›ÎúfŠ\ó”Ûúv*T)f·‰Tÿ«É&1oD·½Ó
í,sîŸŒ&ƒÔœïÈß¥a¹>u«äÑTƒ<1²œ[¹(„±:LYëÌpÑ1×4m5êY4IÔ¢„ÇjXG/8ÜğÔÛírÍÒÕ‹øúWn×*¿/¶£Éëã!LÌ§\f{´×%©ßÉè¿-]Ë¸Hµ,jØö·Ö<>õŞ¡Ğßîíïÿ…>–Z3ŠjûÇ³f¢w(D{k¦Zİ[Ä¾ÉçO?ª«÷‡ĞğmI(áã4^¡˜1‚rA ½PMZ2S¦ÁªI¬d BZË­q,ÊÀàÌ…Ÿ°ûÏ¦¸?Y}'½g&¡rİ»u”Etñ_äq–ÁÎ9Kò¦cÔÃJlbgX*ÅšåÈå0%Œ€ª®ÖÍ"2à‡«ÿœAô(<CÜ•Rÿ*Å	Õïÿ~Ïg¤Ca!Ú\Î¨Vå÷¼’ìşŞ4—kJTVŠ·•ß”–ñ>'^à’²p±=-åy©s×ïÁ¯,0+ŒÓ}”cüçê 4UIúÉD°×ŠOr/6á[Ûšc},ÀÍUäPr kŞ-S—.¯=ùĞAÃ\xPq&	6pNa&@WÚê)mÃ{¶`5¾\¦dÛaJøÑqËçôbî@ò–÷ÆWÔøªşÁ uRõD1âgÃBPQ4pj @+Ë}(Ş9ÂQì^KÊÎ¦5Zß…#‚³ÛI•;Šã)ÎdIM»Ì¸(Émâ;ÉÌêöB"Ï\ÔÑÍÔé#¸ş2Şb²Êxİ4`ÕóVgö@¯,Ù‡ı9¼é”aş;+
œU›v4tßãlEÌë½¡^ìwAPìUÑ˜hµ¨Uhs1Ù¨pëµëb™b(†;Íìî™VM×ßÉZoõçZUk~’°êzDYÌOxÌD;MÔä—,	Öm¡ìÉèêã;­whwÿiE
ƒ_î¦³rÔºµˆ\ì)”·”.§é%$»Í$Sè6Lû)7’Ó–x)ÀûJ†ğ]÷¾’ÃGÙ	ğ?«²QVúè±H‡&zU9aĞ­G¸\Çˆ÷Œ[¦šeCB¿G÷.Ü´‡Rì¡q5}hö Ûéõ£2lãÀ
JO¯âÔÿˆ¹Ç6ó¶_Ü—·(Ÿ†æäümCÌ fÉ/í^Î›ôù±¹{îG
åÑ¥ç¦Øhş5Ô¾&³µÑc6À¾æ«ª_‰ş‡$SñC
(Í`¡pü;ãQÒDá­1çuWÌŒ¤õ(¬õ\äì°dê½YõÇ‡o›>ò}2Îîëji]zo#ob‘OH¿¨¥÷ßÖÀBVv &l¨YâV‚)£(»Ã§É•íËU”Ö@Õõ¢öôA!LVnÓÚäíõıu§º%¯æreãÀÛ8Û+ &väôo‡ÆåšÁ}Cè•†ÑõéOã/OQ¨û÷s”ªÜéôI#[Ò«KIºÍ,H­<Ãq;ôz®HÛ<X„ßcÁ ”Ó×¯TÈZOª—FEH)ş°|+MU±u"bÍ%»qŸ¿˜¦¥Å$¹›k£+e?³Ùèd·-–ôåämdZƒåW|f‘·Ë¨Úñx¹†ÍWÈÀl¦nÊ»Öïv‰}i^8á#…i^–m_¢¨†2Yà	Ã8“Uq—)Á{ÒS‘
®
tp[±¤(¢„%`£`Õ^ŠìcÎA“€âÙ!ç}^õWQ!*
¥í%×·İy¡ï™š^A Œ2FŒ-ß¡U™16ºÜÆÀå?óud#x¿Yî¡û.üØZ”K`'ãíàoQk¬ëñÚª”ˆü²àš„}Œs)t’áC…ø+åÉrRíHÄ_.´¡ê‘LàõÄ5Ê…:]n!‘^z|Ä7]Ù§ ?ƒÑ¶O İ(íŠ¯$§6;N¯~Ø÷²J‚0vÍ/İ«™d0›¹•ÈÑÓRP
TÃ)°§‰ÅAG…Ô,øâ;ƒO;GHµ+r2$|P¤§’âšÔá¯çIî>Tj“}J="­„h…£¦•2¤W ~å¬`C=¨Åáë³ô½c·ï2ıÖqÇ\ñBüq-NÌm4Œj‡Ó†-WöÇÉ7+Z%çmI.ªK=•PXŞå0»:bè#ÖÉÈïòØù"¢.V¡'da)ƒû/;á}ÎãÊn–vI‰aä ìá›¾âX6ıUs+\â6¢Ï?ùäírBUØ„,}¬ä©#ãÎ5ôJ<±Óèâ«ƒ÷ıÆÉ‚Y,
-F:©ÒPh»Üì-o¦6Q/rÔº¶¯*Œ~ "1¢l1,§Ê„1ÌÃĞ6)[wØ¤²M5wå#æõÛîoì2˜®{˜	!ı¾4ÇW¯Æ#/M½‚y‰ï©Õ—U×*¡‚.ñ„ ‹„ÓF<õLÖÜ‚Íiˆ¹².›2ãb¿­óeš$é{|
,ŞŒ[¨`Æûô±ĞÊwr)½Ãp	ÖÖbBÏJ1!}ôsûéÅúÕyÉ`~ı¯İ ¶b:K$¯T„õŸ™F4b¡I±êµÔVXzcšËP8˜QÀ¢•ŒÕñN.¨‚Ïûq‰›ÙÍÿ0
Ş·æqgÛªa¯ò.3+\`›hìÀ\ìaÄ¼Ë[ËGŞLq¢1‡†¨Œ´Y»*Ã“l´(ÓIö„ìl%@Ÿ,`ÇZß»òÿqÙQ´
ñX}8W´ˆõTÙêa¥tqqS3z¿-Gª~Û T$îY|ı­W!‰DŠ¦¼³£³ƒëéâFŞu«_È`ÿ¬hóyh‚T>‰Ü¿$ÆY—JÈŞi¶„Å¤”¨ñ­íqeh×õ› w3î¨²+T,î’…,Àíô2>æ®ŸŞ,ùŞf ”FNÌùY¶·ıdı?+ŞNß%;Ü±’²ä–=×eßŒàü¯HltRÎ‡`èSµ)+ÊcÓõı}¹Q3@Nà›Hß~8$}–“WÁÙñš {¢+YÓÖ-Tíó‘wLÅ%œÖßŸ¶O…9M:š	XY®Ù?2EÌj8á+Üı?Ú°ÄrŞ$j™|AÀİ\XF?‡ñ>—?ÂúïĞÒa+à€Ú˜x³œØ¿ã±‰Ğ“E;ÀLnoà¯ÆfÏ`roWµdåTà´¡Sxr·ã»<«*ÊßC£r72ÊÉT!¸?¾84pJÔ¡§ñh\í¦ÔÆï]İ‹µ¤ ‚îx»QÂ‘{£a•éb×ó.±+£¡ÈkX¢;‘nîÆÆ‡Ø©I¢<zƒ¶QÛÊÇşš‡0%<ô‚|¤-ÛöÌäŠÑií›à(?zC|Ú^>lYÂ+ØPÜø¬¯tY×¿gx³#áŒ«¶%ø­âõÈO'–ù÷5‹n2¶JÊ…rˆ]9ïWÑo¶‡F×÷²blÉP?[úŠB[u{dT
êÙCHGüaêJğ"XƒâíòÙT˜JHt§ìß'Âg‚Q”æğíeú!Qw<kK–Á ELì»€”ÿuW‚½ĞUãµåõÈ“ÙWÚ:6dpßÓµ’{fËM¡JDzJáAx¥úM\€1Ğó°Ò=éaq}Ğ÷bu'Í;Ó•Y³e%b¼ì—‰~áKqT—ÙZëlß¥¸œâdùjƒ Dö:[#Šó $\…,R lKúÇC2RnË¼=†å¨~»5{Ó8¼ÒçÏ“{oŒ†õ3|hÈU+Ø¸Ø4d`œ–™­«}Â“×"y^¶;´»BŞ£¦­ğjbo	Atpc³«¬Zµ<Í¨lçˆg·¢Ô‚Õpó	t_ÿ":gÙøS*aÄüİ|™0³Ö˜MÖ³iôXÊ¤¬ôŒ˜åix†4“ÏNeŒ\ĞÂsu¶‘š¦[/ÿæ¿Éİ,á†—(
'¡‚§Æ™»êÎpRñòöí§ÌÇüIb¼–‡ ¯GJë}¸Ö˜Ò§k mÂîÁ'„#‚¬döéeÅçã'·Y#+Gk˜K9 MŸè—£A´}¿X Sßä æöâuGÌ%!Ç]M4-SŒÿvRwŠ>Z.¨Ñ ¦Hğm@ä)õ&xÂ€×–¾ÿ†l½,ıW{BÀ±§*ËÌ‘8¦ ’nl²$±
Rl¿¶ıèJöeõíH<c˜‡K”{írN˜öh¼¢“†s‡ Şi]û–”œ†bÚÁ–´ƒCå›ÌöD±CiUmµE°vn•\’“ˆ²a¹%i¹™BVd¨ è(Õf[.¶"„@ÂêšØó¯¶óL|Ó!s«`k\Û¥<”Å‹ŒŸí\_}©éê³eÒr~K(/n÷ ö¼’â*ˆõ-ÖÑ_U2G|®´Š»¡AİÓa‹å\ËÜßÜ×“¡œÄìkªÎyù³èˆ™§
WÏLˆ­È°Ïf¼õAOûçøJ¤=©W*xXÜÓ YºLëL\—Êœë¿{»Qÿ:v+ú•y¾ªQyòïa•æ÷€¨²­…s^ˆº® Dç¸VìÉ¨Ó¶Éõá8/“}İû?ò¢ï‰èR[{…±]wXEğœ£#&Î¢ó#É™ß˜n0ı½O•lPäìl¤[ÁQº'­sÒu]¼™¿CÎéòÄ\ÄXâ ÀÓ÷n<ªXí·ó šƒfnadW‘é¼ÓvÊ¾tLBEïµ?Œ’ê
Ôr®IÑn§U§Ó•ÒN9át9Ö9‹;º¾­C l]Æzé åyAuat³&åQáte%°%¸ÚíJ\XnâÄ‚ÇVzàQy+"{¹Š¿”†&À–e®‹Ÿ¯=‡]IÙFqÕVêÆaKGô¦MĞ¦«V i+}.I“û„~nxt7DáN€È3%º)Æ8/X9Û'Q¼}oĞ´IK
yÀÖ•š+º¾ò°Eß‰w:x:Úİ‘âD¿Ã½I”'šŠö‹[Ü+ÿfíqƒÉ0òÀ‚¨€:Á²,_|G±hMÖ3ctS%º<}‚y]µúb°[Uø18zı@ÌUß­gJÅF¡ÕÀÛ&,„yn×»”‚µko€l˜ä‹[£¶ò»ûdv¿Ø½Õîz©‚¢ÑL$aæØÜåšSrzV64~ ô/Ö-øìÀ Ë!OÏÓ
¡|+…ø>İMş ‡í)µŒt÷ˆõ1L*”Á&‘Dl2˜Sò²¾\@äÆ­ÂÚôi£|úv €(0D¥IóÛlX•¹kI‘-tñ*CE5’bJäëMcÊÜò¨èÓ9Ş‚šÃÆ?Ë›=Ú÷±3Bÿ‚Œ™a‘xI<N±Ã~šs1åIRM¥—¹ ÆTZ‹–:´vj¨İ§†„[BİÓ½ç*.åÛ«èŸXH’ÚAûÑ|nCØg…„ë“ĞIšÒªèw}k9eÀ«*”‹JÕâøD
®Æ¢ß›ÅZ¡Zwc™Mo^Ş]ˆ™ÅoisáÒ½!± `ÂN±ësÛâSê3Á…w»Ó®rDLQÏ–ôåî|‰ßö «*¡rM»"´|<UNtÏSñØê^ÒõïÁ3¬°í—ñ›²Ö5ˆ[¶‹şöğA¿ÍkŒ@¡:ÔBå«Ã!øiJ½7yp—’ÈŞ†:œì	ª×ÉVŞCVì,İÙëYZ¶™[òTÊ„|İˆÆ2b•“y+‰v+.i¯]¶©Î7RİâgÜ°8ØJ®‘XÇzym™ré\Dîd©Âq6z,«bó€‘4ÙC·×^éEõª0j¦g€òQÑİú‹‡åO:#U)®d–x³!çÆ®ıçu§]6bõ™fµSìA•?öDv›gq™oéåM	Ø1ææé"©œ»eË)Â›Ë¨E.ëFşFëWV˜µö¾s™<¹­Ï?g6ûnb¡oJ.G¾‘iu¢¹Ïº”fU/fÜ¦c€&ñaL½á¨wˆ^¹–Ş’b=§N¥™Z9ï›%}rŒ Mt´øÕNdAfµ$:#Ç—ä$ä!BéäH=}{®/Ñû·Ü9å¶#¶zï¯5y²£É„ŸÏçšN¹sù·¡·® {ârNihlq¸¯ï’¡†µ°gÛàGƒ‹³X<«ÿç¥=™AHUIxÓµ„â
Ò›óÌç&áaVÈÎ*<i¸+M÷=â+uÉÊ\6¢25ğÁeÒ‡™É:µÒİç©ìÔ³$¸ãöb›˜’·8‰÷åy¨áÇÓií1‹A¬/øëúG5?)"H„ãşx˜ğ¹Ş6$Ø(xTnq-½Ë÷='{ZŒöq]iºéµ-@DW›ù$¤=œƒ!­µj‘ Æ8‡C“³|Ò‘²æe:;^GÖ6Tí1¹’ÓG£ª·„®ÕUnÆÆt‡$P}µ&Ë÷?Lv«A0Pr¨(Gbğ±˜;ú#\}Yó ú§İ[Sê€¿#ö(’OÁÿ{(p¿ôlH3o¸ÙJ9 ”ó¬æa…Â¼o¼«Nµµ—¦¾VœLY: +?­£›fônÆE:ë‹§á¯Ò[¡şÜ¥ıôi03ÁŞâ–Ò“%P?©í>UOî,ãIƒÜO¸MaûŠ±±V§×|Ìã\šÃú‹ó?Ö¢M9Mdx¤Ç®4iÃÜ'éƒßÍ> ’C2bnš¥¥!H#ò`~”	µqÿYåİUÒ9A<ƒ³yö°Ã^ëf
u¿$!ç%¬Ü†Ã`û¹úA_ª]Â3˜cTQ¦(4íÖ)Où	5ÂŠœ½Æ.P~+y2DcBE
cRq½,ıh„^ş#5¡ÿj:yÛ|)dŸhÙÅ÷ºœ¾Ú#¹øÆïêË·ï&i…©rÇ=t¶}]¡nÍûšŠE™úãÁ}L YA	ƒÑÜ¼VÆ%õç¬B/œ^o¡ø”[`…õ¨ç8&v)Ã¾3Tz‡úx>.¦êóÒÕq!ñœíŸú'ßW¡BvªXˆI=~ré¹íÀûá­¯P4W8ü~Éœ§HÀŒúÕò8±çE#Ôp4¡¸ÜÈüÀye ºGáu…iC_LÛ@_ûïƒ¤Dª‚KÇ#C”&5ç(`Í6­P>¶›_°P¤ÎUzÂÂ‰Ñû›M#–(oìH£®yßZ¿¨‘RìR‡cöp£îÑÁt09Ÿcişu1ú0¥ì×+örVòÊa‘Ôc8º$<ø™£ —–s³¥ÎO‡]I*)iXbbˆsYÿ›°ÇÖÈ’–‹çSÃJ^óû‘şêxƒjÁ`qåpC«Ş ÃgÖ`qzq0ãö&ÎdïGø<ø!f`“w(šZ"Ó(ÚBGWïŠ%± 	É“¢ƒ:ÂºèÌğ™Uâ¾¿ª­’vø°…bşIÁuZSÕˆ0tƒ4N5&³	…Ä€_›‰V*Œ¤m“4O5 ©˜#€K™!§”‚ñZ/Í¶½ƒê¤’3ú	şV¹n£úşzÖ˜ífDd›2¨	TüÑE”ÀhÄÎÏB9/íœcÛ‘iVUİ‹cR­ş×Um¡I/Eì»’¨€Ú8\F4u÷'' ¸YØ–LOµŸONÁÑSoË™«­°“–L~.\/P¿2-ıE°;÷ fs-‡ü;*N°°m¸;¾ß¥5Éšû»´	Y¼&KzO´úD´?Ás†Œò{SÉÄÍ'%kÅHJÀøÿ¢z–‰-MX‹R÷§“ÚÉV¯øœyĞåw’"º™®ë¹
Õ¾	¨İkPE›IOhÖ%d3;7^uttV™&ğP#JQƒ ¡n¤ôÑOÖ†ákÖ­GÖ£³á{@bi_<%Ë¬äR•OWøÆ3X&´dÜ¾€İ™Ï¹5şüé.LÃû>«®0ãùcıûÿ^4PÿĞşğtëˆÕ8ÍÔ|îÊ÷h9ts«ªûÎ9ß¼I1NÒß­<¶ó=ğ…	õ=û)X‚HÓê‘Ïì>œ‘ƒ±Ô{ó2ÆÉOêcµŸŸ}(nÁ¡´#%[/'Ùú‰LßLR{ã¬ÚàVú(V¤VY@óZ¦Vuãèm~úsß”óf”ı'pOêo¯ğ'p*¨ÀŒAyVîR	iØ6+»BZvİçVnêĞJËdÖ4µ]©íØ¾:ƒ ‰÷×ülÆ"ô5kÃ'CÁïyÄ„'o›«Ë ÕUÑµu^’¹üqsM½…æ®|;=Êä®ñ/ Üs¤á‰ş¡ß$ãÕnÑ|‘ß½®;ìB>¦|Â¥®Á‹ı-£ÍØ¹¡ŠPgçb;G*æ¥Y0 G–î[F_Æ¿‰\÷QÿÄ…ùF:tÜ?ÁRÓc~œÛÆPxë—æ?Ò*p;ñ‡±Ïü‚@—Ö¿Ë±ÚÔcô‡]ø±ä÷V}g‡¢9`=©p…Øk,Ó»7JO*T£´‘±d_–şN³U*ÔkŸmá«zÆç¸'m~‘E}é)MêõlÀEZšØN)f³8c²ør¥Š\Ïç‹Aví¤µıX-NÅã~OªíùEIY{]fkşl"-[	«u0^Ÿbî¨­ñ ;Ó®ê»EO'b=ÉW¨±uß^
Š,¨
Gá9¼0û«}dØ‰Eš¶˜öÊ1x©p£¸²2ÄŞl‰Ô¯áF¼oQ_¼(=SÃã×]òfpªÏˆÅJ2¡â—0m(tGâÛy° àH[j:˜`<Ù°Kw}£§2éÎPgÛÔ?,	P—m45±dAÜG¡[”e‚ë¶œôÉ!sln"ƒ0©½ØU‘)õª]âùNojQíÀ€¥7·ËI">7`'Ô ]»W½®vPoÅ6k7'+VĞ‰WÒ^¾QìÒC×ù—ëaË èş™u¿R4hŞ6Vˆ,×ãH˜„(<æNm™.‚TÁ‹4´˜îS×2ó×&˜"Î0¥Ÿ–*…ÉÃÑä¨„ë×6œÑ=ĞÜ[¯.€*OæÀègY¹<‰şÎ;¶b4˜Ó˜˜šÂÃ³”'£›Ş§ô¢\ıqâÛM7KıG0 45'+Äáµ®ìÕz!=Täú¾ãµÊ§†ñHgöÏ<çÉY‘ÃÙòbõû¶ˆ½³İ§îØI?ëŞó=‘s ÓÓ€a”òÏÁãejYwÍ½É·¼N­bz\ 3#o)ü	´ÜX~œ¬Zs2A't5Ñß
1„:lÍ{9¯¢$,¦.„ùxÙiçwõ7«³ò÷¼HÑXõ•ÔvT‘-œ“ÌÜ+¸š—.ş.ÇğsÈ»Û¥2B~Á³"çÃ”|œòe’W[§HôZdÒ«·’ë.!Ïã1O´ls}b%œºÕwÀN’ıÃ:-ì½ÁS£L 06€¤ó´²S¢Tû#ÅyµÊßÊğ°@£ú¨şÅ9…Ü•ú8·‚Ô%ÍÎõ¡m-0Ÿ çO‰†¦¢-~·©@E½òívå÷„(pİqFJCéåŞ³$#ŠÔ;?ğ*:­¥æ]1ÒÄ¥jGİÖAáTIè¸¨Ş®Ûu„4÷»ÉŞSg
êßzáunİÉ»¦¾Ü`Îu‘>©à¨ª±n¿gpƒjoÚı–T IzÔ~IK
’¡Ä:58J{
º¿æËñŠ	İ®®»•®F\&(!Tƒl½üqWì¾æ–¾f.™†”É CdP¾dwéiToÿä*Õş¶bÈ=ì”¸I˜Ù¡ğ%ıÖ•éò¸o^Zì^*¯Ä¶ÛœàªN(ˆ„óÆØŞ™Ì/·_¥($›w&şã#ó6Rh7F±f§À,éânf9µ6™&h×İ¼·NÊR—OlF›[CAÍ’là©šºATÑ²³•©…«Ô¥´826˜şQAÕš²õöï;8Dw`IİÉ/ø}àûÕÂÄ¯±»R¹UÿÉå,—»Së@¤ºÂ…1SJ¶`À„Îà“FÓÅ$è$6|ŠÆ_æ§–_ˆ´E (ÿ°~ŠßáaÉ¢2çõ4L:nâ¼æMNdŸ7OëåÅMnI3PÙc§”{#Òı¸\×õ…ÃŒmÙ€c.^éè
±[1±‚dİv.qz†Ò(gÏ£÷‚Ót±È7L®²l}Şh2ôİ¼QhÆIç	{½‘óÈ(µ w´i|œ;…½6ZÆúæ¡ÌÉÕy®§Ñm;/œÛ/(˜pe {8ŞmaM$<C‡£ dïÉKe²¸ÅsPWä:ØdŞW{»"Jli_¨ƒR]GËµ;X
}ÏB—’IéÙx3 üûÁ~ı¹õ§ôÛ$Z9Bºp¼0L¯œõÖB•¢R ¿	¬H(C&‰aÙ"(oæĞAIl'k²ÕRÍ¥Kòc¸ÈÒ„`m·J8$›œ¯¶üB÷gÑ´dgÂ®‘áÓ…
na’ànE„µŠÕL‘èª±ô=€‰ğ4l_TĞ'ä
¶Ÿ~tQï¶&†îÈş<I&P‹ñ¼EjìJ2k!éyÔlŠx¶Å
Ÿ:¬+7|ú[á§ Ştî`
_ÛEIK	€ı=M¥©emÙÊ••~^¼«Û!:û–n·*VM‚9ÎGîõ6»ÚŞ$·{!6Mƒ`A{õ#X¥G Bèî2wÕI
æŸ4èåD^ìuœÂg­yË!ØQn\1S}–Ø½²9¾«Ã&cu«æOÂæ%~şİMy;ı‘Heş?ªèÇÊä›ïÜİæF®É@¯§İkNk)´
âøU¸uÃV :¤€Ûf¼wØp=>øéœcŸ“Ÿ`çáL€¢nIs¾üÌÔÕ´‰g`NVíÏa$=Æ?!åÖN¹™“Ã£Õ0¬x2«À›û +9!If1—?Ú›8âø(Î¤^Ï{ŸÖåËÍ-ì§Š\‰ºzÚ½-7Á†e*˜ÿie}ÙJ;udÛ[HÏ.}Ëİ:‘S¨ğ}^úÒŞìšú[Èš¯|3¯ª …—WZG­šËÀ§bâ¯ŒmÛƒî·Kƒ~~ÍËp˜§™2ÄÚ²5Rš æ¥=Nå\¶|Ïf¬¦TòšŞ{’òß´7˜ægmvJ4	|	yÊûÎ±P9Éq D€?‰£Gu|Ãàÿåµ³õ- îî!>–jç KÿèÍÈa¯lW7µÀá1˜:‚¬;Î‡ Ü§^q*šN×«Ö!«Pˆ/I5UéQ|ÀôXñw×¼8BÂf,š`Š#‚ØÉFµÙ(P°1÷›ØÉ4š,	‚‰A›«0”š¢©~‰%¥MÖ°ƒG¼¥‰T²rU¸ZáPäÔß°äü«„Ê Ûtı±c³G`eÌŒÎ¦Eu¬ÌĞ®RlK¾üğ¨›tÉåàœ´	7?ŸT;·-öÉI<¾5%,İZæÚ'1W'³=äŸ…nkÙÌ•ÊôÊGúÖÁ™×Å¬‰ˆëvmá	•g…›@Ëƒ
@&ùé	ı.Ëßèv¾‹9ópìÅ¹ÔEb¦V³3ÀƒZ3bK%fÙÕğ°A¸ S×ç‡Æn3¸:yIõ´@…ìúOöÃM¾f:›½ª³8~İ·ºŠ/Q"ŒA0ïp]¤S[!QR:á–¦¦´Éãicêgå×}”hÌ'%eF/ÍÈ0ÿäŞnğ0Œ…Æ#ÙÙ07$£91À­T¹†YîÌ·ëFšª
j0$ûägF÷BAi¹vZGš—€™lVœİ")!áfd¶ 
• nyİ½I”ÔvòÖ@Ñ¦éµmyİkªç†$¸¦q9¤¸¸sÌÆ÷Šœ`» «d‰·j`Ñ3HÕjhá#x(ø0)Ùz¹àòßUÉ9VíµV÷XñŞÉøOåà² ÆR—Cã_ù /T¦¶#Áo °Ç€®¹¤±Ägû    YZ