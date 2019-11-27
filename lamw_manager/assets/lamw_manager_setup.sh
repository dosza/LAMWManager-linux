#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3085507347"
MD5="875da8d5b52293e4e5e2b46ddecb959d"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21126"
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
	echo Compression: gzip
	echo Date of packaging: Tue Nov 26 22:06:17 -03 2019
	echo Built with Makeself version 2.4.0 on 
	echo Build command was: "/usr/bin/makeself \\
    \"--quiet\" \\
    \"--gzip\" \\
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
	echo COMPRESS=gzip
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | UnTAR t
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | tar "$arg1" - "$@"
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
    if MS_dd_Progress "$0" $offset $s | eval "gzip -cd" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
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
‹ 	Ìİ]ì<ÛvÛ8’y¿M©OâtS”|K·=ìYE–ulK+ÉIz’J„dÆÉ!HÙn÷_öìÃ|À|B~l« ^@Š²twfv6z°D P(êĞuıÑşiÀçÙÎ~7Ÿí4äïäó¨¹µ³ûlk{·Ñl>j4››;ÈÎ£/ğ‰Xh„<²L×½¾î¾şÿ£Ÿºî˜‹ËñÂtÍ9ş)û¿½µ½SØÿÍİæÖ#Òøºÿø§ú>±]}b²s¥ªıÑŸªR=sí%˜m™%3jÑÀtü<1CcyÒr&¶Ğ`C©¶½(`t§6u§”´½…A—R}…ˆ<w4ê[õ-¥z #öH³¡7wôÍFóGh¡lØ~ˆP£sJTYÚUb3â›AH¼	¡wê·N^Ãô¨NFç &Ğà “\¦ïÓ€Ì¼€¨8†ëf» JN«_„“
½ò= ı óüìÈh$­ÁÑĞPkOÕ¤3>9Œ»§ÃQëøØX!YĞ\o÷CMÛÏ†qÿeçM§ÍÕ9uãQoÜyÓeÍm˜eü¼5|a¨(W)
„£³! +Õ#
ÔÛ†^p]ä;ls@{FŞö­Ö} ×ŠkQÉû}Ü9W©”“Ã`~‡Ñ5µÆº›Üó·9;ùô–(3[YÏâZnp	á
©a. ò­™z‹…çjìœò­QPŒÂ7Ìİ	l‹2šFtáÚeO6nˆRIx¥‡_ÏC×§;^!«H°X²«º…	ÛçtzA cö} ÄE–Gt1ÍQ8À£A—¡(P*S3$:§ú<ğ"ŸüÌê‹añoí'¢[t©»‘ãÄT×şL¾1H#ÙMXLeUìšJEPÇç>tÌ9ãÓºô²$ ³ñùM@áç¡íZFmvxzî¡n¨	-j-QË)*'(¦™µq«İà—®§hõ[Rğ°˜„eñ`‡0c6ü«'”7]YÆwŞA2Ÿ¦(s>ujŸğe2œAš™&TVÕ°–ş&Ú•šÎ6ˆÜ¼ÎQ|»XtfFN¸¡ H+ÛaŞ©ÙDÂ§–(eíiªT²Î×ş¼vÖ¾çØ /íPÌÏvÈçô/èê.ÉAwØ?nıbÔâäMëlô¢7è -ûM>Ÿ>ÁURËY¶"{¹0ùe¨G»Kè•’z½®îÔ´R¿N\EäNÑ	!hqı¸b¾ÒXJQG¸H®QR¥’IB"™šˆ•¸)–ÍMa%İVŞ»0m7¥TÁ'NV—¡</,¸O¥’ib,°j,Ğù>‰:5Qæ<Dß*Ì`2;£ å„+²R‘M ,€“Ëá[Q“6–<úúYÿƒmwN†‡Ôª‡Wáÿïno¯Íÿ67Ÿâÿ­g;Ï¾Æÿ_âóÂ»D›1š³I{J¥Iz>x> Íy„&+¿¢TF‰ãG>ô{nØ0v1]ÆWò©¥ùÄè ÿú$/…şª˜_Lÿë¨ áøäş=ùsss» ÿÛg_õÿß3ÿ¯VÉèEwH»ÇßµõNZ£.Fl¿vïô°{t6èÉu>J‚‘^Dæ5·1x/
!Ì±y\O&ğlºIBì…gÙ3rf7¡ÄñXXÏ—Vó{ß˜ˆêd¥Cùõ r•ª<$ğ‰¦‰Ñuì…a!£€ÉäÎua^PF1ƒy„Ä32¼P tM'FÆ :¦³=r†>ÛÓõdXİöô/STP²úœÕ¼ÓŞiÏ±rdù•oºŒG´çfÂÆ«(3;`°9ÓiÄ3
œ©“wÁaØ¼7}^gÑ”¼Õ»¯VùKÚ^rø«ÿ7›;_ëÿ_rÿ§XxÕ&‘íX4¨³ó/ÿÃfo¯øÿÍİ¯şÿkıÿ3ëÿM}sk]ı¿(è<È	SÏMH}GÑˆo;8dN]ğ°ƒ¢Ø.øE<*hN–ÏˆNZ­AûÅî¶FZ®x¶õ…»RµhH§¡	1
îÀÇÿñˆå‘™?Ó8Ó2‰ë‘~›`½ÑÄ²Üòã¶¹´)/Vš‹‰/…H‡ı6Ö+JÅñ¦¸‡6Ç3à€Q{’V‚mÆ"Zwi¸åa†…üXÏ«OÕ³Iä†işPWŸ`ZÁÄòçØ¥—ãˆŒñ²ëş>vl»Ñ9Š4|øHÊÌ©’’ÓÌÈØª7ê<³Áñj¨IDÆ–n}Pˆì Šqê^0Ç&¸¨‡æœéu( oã†*a,ããîóq¿5za¨zÄİ±'8CU%°öáQ†<“VŸÎæE”ƒÎq§5ìê¿ê†İŞ©/ñAdé5i¤šqQlÿ\Ú~Ğ’¶ï\ôbwz’,ãê‡İ1hšƒ‚¢Íİhe]i¿ÊÅ$† 4såEÍ°Òã)ÄW‡sS T†~pÑ¥äuì{âM{n†ÿ…@‡E—<eH´ @ğaöbòñ=õøÜ‚'7ZÆ{f6ÿ"K4v÷âWº$5ä~¯c¯XÀgL¯ÿ•tWÂtòÕ¥ó¦fçòÜ#· *šŒm#®”«µÜ •DUWÏNÊ19ª­›êas=lˆ×/ŠôJ•g¼éy÷d\T!ß¥B~z¡¬Âá	¡€“ÅéFƒ³Ó—$5ä#…Åşk9¬h›õ†6× ¦`ãU¸ÚÍJÛ·ï´§·9ÔñQLö—n?>2İ>î½¿èt¸`°s¢SX@:$ÌÃW§£ÖÑ-7%3ŞÖå½ªƒ>Öç¿ª%«K±túT.oVz[‚6b¹.Å¡Q=%¬[iÊ“œ9†Úê
ĞØCÄCú8„TÖh.V /^,L „bÂÃå96µ1ÎiqÊ{nºsšÛ¯,Tì)”¬»RÁÚ™‚…Gï+p,'óIm™´ûgãQkpÔ&XÀ^d¨š…¸€ÄÎ±JzÃ´_DT¤=è‡°íÔ«g-¢µg¯û¯¶T’_Ğ9ì¾1pg*‚U¾Ü˜\)”IÜ’ªH%»“ ‰cïlĞîJ^äÀš!z­(Øhü$!~µı„%j¿/d%İ{ßŸ^írYvÎm8\¼Á¦½èİš€‹t‚ÀöÈ! eÒşk²úÔnN{ƒ“Öñ­J„Õ²!àŠ­RÉK_MMk¥Ú¯bhNSûõj9[UIÖ—±H>³¯€¼¬ƒË™Õê¡t@+Ø Âu¨$`—u¡LÏw·Kõá!†¬d»¥İ~€˜|şÉÏkÇ‹Ãi/£î.Z{?ãòT4)IÆ£ÇÍKÉÄ
7å^füÑ6áS¹Tı´íC’ïÙ:\DädÏÍËíÑßFøİ6‘;†dQAÖnafÓØâ¹ç…Ã00}®lÉ:@†ìy ¤··¥6éªËáqëh|ØC£Ù:=ôºãX
wdœÂˆ'!kn¶Dõ%jPÃg—P“¸Şş9ää<<¯˜’Ò—ó¶$¦°*_Iˆ•ØÕÏ²q¥2¤(&}szaÎ©ğ¸ÃÖÙñ¾QjÛ/“„İv-zÅ/½$a ©İ Àğm÷½¿ıäµæÊ„Ã_«ìÿòõ_~Íˆ‰› L£–®ìw+ß]ÿİŞ]­ÿïì<ûzÿûÿqıw¥_ÍtæïXÿ%ép->o,‘øÖƒ”ùËì‰Cym—#ÄƒŞÜÅF]<&^'.+áuµzıËp»¤XÀÀğÛ¡gÎaMC©Æ•,“ßµ¤Kêx>?hÿFÁ!ƒ^o4ÆşÌ	~ƒx-q	Ãƒ—rp±¸ ÌDós Ü'ğÑép~?/=Š¨¥ÄC™W˜Ö¦Şš\¥Ô÷î²÷(góŒ$„Sr÷ü¸’<D%?óıót‡Ô5AlZÏCïÌ¢KÎMBüÀvÃy<<{>üe8êœ†±‰ú=iFƒÛzE]Ën¡ùO¯:§½ÁOĞwÒ;èjcww½³¾¡úN4¼ê;÷1!ƒRQŒğs¡øYúNS‹)­ó&¤Ñ`‰×p¼ŒÅÓb<VåB±´iì¥‡œŠùÇ¿ËuÏÆ$+AÉ]QIU?¹2"g¼ùêÑ,Vúfxn¬/Xj^! ªr9©]‹$by +ŸÙ¢jœ®Æ°õcĞ4ã	Ò¤V»‡°vk„*·A‚ !µhJS”ä1ÎSÄÓ+ù±ß"®GÆ»IÍ‰­Åİ‡N-UZİµ.tß1C0W¦ÇĞZt2Y¼Û¤Æ„=	šcøm9uæñ†¸ñ €;ô<raÈwôr¢¶ë?ê~@Ñ…ºèU†¸,V©<Ö£üÖÀŸ¥0òz&ˆñË9òıégŒ	Bç±Ø%Pºî¡Zø½¡(Y¼ Š$¶…¤
š…7ÄÁˆ$':Â"T*ŒëÆ±íRÛÅ‹Ì˜œIBô¶ñ'Z‰xá)WÜ:“ÔäÌúšÙ™šàb…æ‚âÂ†á¹j,(<ı`fzl‰ƒ‡$®…Ä9n\MIèS‰*Q§’ëãjuË²@Àú s,ôú‡Î›± _´ÄÇ†EËAI0UäÅ&P‹™Ñ(â©}Æã¤Êk»øw¯v4hwr¹ÇÀ¯®6/„˜ä¯}î˜îîDòÎ€DJ<úğ‚xÀ‹HÀPYİmµ&³@•Ó¥Äï²–Îw[Úë\¯xu…óüäm•Ø#FM~/ö!k÷!Fâ¦!³–#¹GÙîÈ„ AÑRƒòø31÷ûN4ÜÈ— É¹Œ¦RØÂ„¼ºĞ/Ê#0tÍ°ÕÄ—<FĞCºÜqŠçØ“2B!0aãş5>s ø?fôŠ‹Qª½,Í3éXd¶G@TÁ5-½©‘ü¥FòdøVf6QÉì]º4h9Né‰£QÏu®ãëÛbH¤¯Z¨ ÄÊŠAî6æÒŸ¨NEy
Ù…FDXS‰Çùkì2aÉ¥ı«ÄŞN¬¶{3ÿÒœñ%çÇaŒ“BÊZ*Ò©bœ9k&MSªûe½©—uÆkYÓË‰•aõ^CxÎËáèÑâ
İ„¼#NHD’¨ïnà{I yÊ“'¶ÑØ·ÿT»©JÌyûôıí¾ıİwÀ@nô‡¡—f¿¿•,Ş(	á^ö“hƒÕ±qÅÄbYë2°C¼‘;ç™¾K ğvÄtìÍ»¢QrèobgmÈ‘Û'—ªVåŞ”Ø"ˆI¹Ê ¥i §‰K>B/ÓÓ…ô ¯¬•Ÿ¨]wæíáª¢\‹qĞ^±t›ö“K/¸`¾9¥1s_÷/‡w2¸¸KÀÑÊæŠYbÆ¤ÿ4ßæì{^Ş¡9ËÅqöÆRÖfÔ
bâÓQ¶béwÆÓşü3ÁĞsÔë3¨•&xz ‘J¼S¾R“65æ¡°ÒÆÈF#‡(“ñğ¬ßïFÆ¢¤Šä²©¡IÜ«=Á¯èÀˆğ5Šp†LÅÂ|îİk+5~±.–05½«pÚu!Ü7¾)\!(Bø{çŞ!_¢3.²GÊÄë»^¶²¾ÊÌÙ;Ú»Ÿ©3âß²œœ½WÍS ÆâŞ¹üå[°Ù<6€è˜dËÂlrAİˆ`ÔŒÍ¡ÇßÉ;¶bÉåW¢›¾ï¤ï=¤Q`uÊdğ¹Ş#ìa`ä J9§Á÷øş±Qd,,dùRÎC'Né/ìÕ}Q`¥u—óæì¶EÙEèù<ÂÎøÛÑL:øòÈ{‘»¨§æ‚Ù–¨©©·§Å.ÂGT;Wtš;z-¹›¦/ÌàZ•Æ“rÏ'ÏPeQ¯Áà2¶” î]V&‚Õë6t1E{tuhäãF4XØ®é34L4]ûÔheû³¡’2ç±ƒ!Õ÷a¶ıUi8‡G^îu×ö¸¸/ì>®)ò_Ÿ´“±"»O`;9Y!½
õ+MÜ!ÜçOñÂ€±ŞaMü…ò>ÛÅJ‡ +€Íù–€–""UÚˆå‹|ÏÔ³(Lê˜×b•/é5Ø‹¢¶¼ßë@”Æà°öwöóLzÙ²™æõŞŞíåAG;…¥,iç*¤ü½›÷Ùşıç0Ä7¼2ˆu`|£‰»µ¾åÔj¾&m$:qo+MØz·5>éœ»£ÎI’ğ—êæ¹ç²“ï®HÙ8èöK;`ô9\ˆÇáËQ¯ÏÏÓA
H‡7µMQ½è,}/êœ:~}îzÊï–šÈµÎ®YHĞæ‘mQÔ‰#,„«`—"ZI|ı<\8u44)m™:	›n.b¨_-œO²Dq¶Äg‡_&–	y ŠthÌælô'ØßdvğŒ{^¿„TTœ¤î {Úå‰RvOø}#QI FYXÖä!ú, ˆ”(™Òö=Š{)J÷kœw·†z¿KVW<FÑP¦ş,*P“kûˆj•ÙË,KÊ¢r¯–‡Y%1u`%È†}0—f¹2ãIv-öÃr¡c§V»éõ;§?CôÏo50îëB3Ä¤äÓÙ[?ìª¹ù¹ƒRÕ¤-4$Š9ÒŞşä€Uè}œÒ	%‚™î9/ø/)X:’Œ7İP äÉAZ©dí7ÉÏouøõ0'i*±±ˆµ_Â	€¥Ÿ’R%ÇæÇ¿{¢Ä’ÿ?•€dsçØÚMúB›­º& %ûrâŠ·ù tAî9şeÁ¾ÿxŠ&E §ô²/œ•0æX&y¯SY›ñ	ÀŸ`üÿè13î-¢$%ÿqüÈ 4	­Øçpi)àşó¾”CRgŸb.4^…æaX&|¾¨–Ô%Blc%/í‹ó«7üehÈg"t ×Öó¶´ÃkKD~9NÌfÂ¥¹[ ,á†ÆfœH‡ñ!ÏRÇ-”“ì~|€b4’üÊÎ	ø~ğ©“hä«Æ´š!²:qï¿q§¸«N,ºââôøñ'W?’¡êJSü{ x†Bø™
ïcéŞ ¨k®×
œ)µxrñğCgòßU^›u ul¬ƒ‚µÌ©¤Zı¬Ã‰ZÂUò9än¹KÂ¹ÀiİˆÄªqÇ£&×ÉW	“Ì›x!äş¥¬E–İ‘U*«I)F\İ(è×ÕµøQK˜SÃølåŸj¡|6b˜pë¿ôúÿ¶÷mÍm#Yšû*üŠ4È)I^“)ùÒ’éÙ’]êÒ-D©ª»Kˆ„d”I‚C’UnïÙ§‰}Ø—™Ø‡ÙÇ®?¶ç’™È$¥’İ5³d„-ÈëÉÛÉsùN2¹PJ8ÔCÃWó$Å	Û,¯Œƒ¨'*uwúUÁŸ’JÕQ²<Î¯ÿ·7†ù„~5ïSm­5f4)µ|Ekîà¸’	G uxÙ’~ı_â:ø%
HO†œ‚c-—ƒóå‚•‚nÔ˜èB‚ø¯¾Ñ*­DS,)"‘ÅM4~/€Ê~jÔ\q…ŞVŞCaÑıeB'ß’Ô+wcœà*†NNçÊÓX©\õâØ3Ğb¦
/¸½²1g'û¢Dû^şö¨uºIµ°‚ÛU¦½[1¬ÂaáŒ…_Ë3Õº~aŸ\9SªlOËêêF¥2 óE•i­®Û«Ê\0IåÚ(¡»¥ùÎ[ÒİX®ÿˆUŸÿTë.çÍÊ‰qæÔ–óoP»y$Vß°êl(›1PU‡
iDéê˜0'”3ª&êQŸˆB[xĞÿ€5²70T-2İŒTÆõêzµ.Ï	8À=ˆÑšT²%R6’ùH3™ÁE*/ƒÊè2ŸÈâÓÂŒæá¦‹#9ıÙ°Ó÷‡ŠH>¤kÄ?Ã^§E§ßå/½ÿöº#F,Á<<%ñ÷uÒ‰«ãî%ïF——é¯ÉP~Çëe#tğ+ìÜ¨Õï6XîB~ú¯Ö÷óÿ?Bù¥8¸3?«£äg~„Öñòº´_Ó4º8XZÉØøª“tc®zøKudË8ÁÕ°æª:ó4å?FÁEûº“ô=Tİ~}T‡X]ûcîãÏI<)‡åCØ3¾ÊJû‚gQ¾¢|¿Âß Û¥¯À òS(«sV~û™˜ú¦^NÆú‹,~Øñ€ÂÎu³ŞÀoÃn8¤¿“î¤/¿Ñ,á¯Ã‚ß€pYçîÇñPşQÅŞìâ¨O“gÊ(ÁÕ}~“IÇCƒb@R<Úij!yq>_e–”ğ7áEÔíÉÑZxÖÏ-½”Åmú™Ã&1iÖHÅèK_òWä4K¶©´YHìË’ç¥öÌÀ¨íße-ñwÿb‚l^ÓD‚²ÎÊ¹\›aq®îç¶9nÑE¥‹Òy@DìNí^õ]Ñ•¬²Q­ŸÓ(@_¹;RÿÅZ/Ë_ºKsÂôBMË‘i…|ÎšôJô©¸×UÜ*uÒk†HOèTFWp.÷™€pvÍãY_¤’Ã¶OŠ›çHÙëÚ)á´äõİ|F€ã¹Å˜i³Ïİ6ˆÙÚTÉoâ6Š«Ì‘F§Ê6Æ¥ëÉ¨‰dŒ[Üò{z!g«%+y1|-mJU
¢rççÄçîü1Ñ¾É~äöZÖIS·gHŠf
Šå9¾ü</4€ñËŸ©ñÀ±@NŞó¦—nÔoÇÃqÒô{ôÓ[œXÓ
*Ël&w)/rg‘Sª•áâ/-€Š˜õ´ªÂ0‘$lVM ;b` 44!b$¿-ù|zxßkó6Ñœv­0Ïó‰ËR{î|ñ|£’%K¾gšB¡}t;EWòæcÉFé4¹˜ºlm†€åºadSğxúÖ3wz¹!ıîÊ/"Ò\6çV„1ø®°Ï8;iÓÜÍ·’—Y˜N}™?¸æHÙûçÕœé=°“gaÏ.æn#ˆe–0“e°‡2c.™[Àî3C®`)<AqbÚáÉá‚$¹—¹ÄÔ*vZ1K|H4:šâu¦v¾ÖîééŞá»VqJÏË¹XßÇ/h/Œ?ñ—ÇnœwæñL+R‚ÊiCá`ìÊî-åS­Ğ9[Î¾ÈİûIí¼VÎCÅÔjWxÿ-õ’|Ö-w‰ä¸¿í½“Û‘ÛëÈát”÷9²],#åp4İßèaÜ²ŞFğ{"ïûu>×üåY¾A÷ËÉ>B÷Ì+}…¼/ä¥İ2hØ¤š#åº‚ıÆ‘‚¶L«iv¶gv§ÿóM ÏòK¿®š&)wv»Ÿ§˜ÃEìÁ=Äæw£µa€™)†Şäæ¥¦]ÎjæíÕé§L´3Ì£sf‘àv¾È¥Ü«^wŞ:ˆ_º?¦V~kf”n·ıSş¤ülJl„CŒsßì˜æ‰Â…)¾ı¹_İÙ*bætÔ 1|ßú(É#Q€Ÿ!£y`8Œ¸—åH.bR[¥9VÙ/'aCÓœÚ‹«ØB£„Õ&X+c 2¾Ùª‚«³€û¼wÍ×ÉK¾m÷ğûæ¼¥’í³§òl’HÔ4*q¡õ¹eBºÈı|~²}ò—´`utm–Ó·XM‰¢ZõºZ¹¹lÔK ø+åÇ«Ë™ÅÈ— PTÌ²µ·`ÊÉéFÎ“.	fÛñ0Ÿ/¥ßòe„>®KËüÃ’©¾¥·JÔ9Ç’‚Çı¤Ò5#’mÀyAUı^rÑSèdK§~mm©Š¨$Şwf•&)í.¾!>¨ìÈ ¤/eU„0úòÏ?}^vÚ¬ByŒY«Ì4y.Îˆ›ÚÁ$¼ay\ÎVVYë‡ƒk‹m_~ùG´8V>j~½ºæÃ wa“iúg§o+/ü?¾¢^¾ä…È?–^î®£Q<@ü#?Ièœ¿/÷¹¶¯-ÆÏıÚû¸Öæ¦&Ó”ø×ü
	_ù²,)B$ò‚~¨Ë*Ú³ÒÌ/k6Ò«—5ÙÓÒ-K#¹5:M¼Â´à˜fÑóÆÅóÙÛ“ßÕ:²”Ï¬ŸõP…i“{P\—=TË+Ê³°…êºÎ	ã|ÆmŸ tW	ğ6µé™,ØÁóò
ŒË÷áhÕ_ZTÎR©>½ ËLÁW5C¾Fa¾ŒKZ¾Ğ¬PphPÒ6îÚ~¬…•²ï02§hãO6r¹pÒŸc;I»xÎs}Ù€ãÌ q*MqR+^CŸŒÉì<,9oPb4’pOM»@”¹¿ä÷»Ø:;wò§³[Á¢¿™ä4I¿å¿Ê¯Ê#+[u†œıšñÿêëz6şG}mÿcÿ6ÿí:Å[«Ömü7ú›ækÀ0ã,¶Û#±ÇaÀ"ü(ƒsÁ¥aÀj£PWpçë…ÂK‡÷àåƒrYZA²š¯ƒñæ•Şí½ŞŞßoŸì¡S{‹«}÷âº|ª(Õßïìì6ËËçáõ­õFY‡?Ø>Ùİ?âWkğn=}×:{ñ·Û;øzC?>Ü}w²w*³ÔÓä
HVWãx×¶Ê¤dVÂí¿íë6ÒçŒ4+›	·OÛûGo¾k!ëä×®¶Üè?\á‘€êµôi0Dùb2NìW ó>¤—x©™ä³ê+—#tüt}oÕKŞw)ĞÀb¡uÛA/‚;SâÑ_ÁQ©›Ëİ°ÓLTàæTêtiŞb@Îœ*Zæ`›;¨¾'·;
+v Ú¹+úDèâ
/ƒ<úˆSTÛ”İ²i€·GWpÌlÙ¥p¬ÔÏ}ÑÃÄğä‹o^6r@àÜå—¶œr…$/‡OZ…ŠÇˆ;(`]—ëØme¢›<h0Ø•V•%òFOãÉh çºtT¿Œ'ƒ®ˆG¢.ğıôrí@òPän„‚ÇÍåÃ£ÃİeÍl’ùåFş©#vƒÙ)$ŠÍJsBÆräÛ‘0t qu‘5b]°=‡: —d_I^KñÄéç5ûHğR0ºJ“èª~%)aÈª? C‰æ–MKØÂ`7m®”WZÈ= ÿ\Æ*ë8†«0×å+¶D·!˜-T(}ƒ'È{4WV]ğ›o2D4€©¨,{ºµ±]GROU˜X—Lh]iù|­ÕÎk5ñyÕ„º—)ğ¶OŒ°YâÈ5K%æ¥B{,¹ÍƒÊ/Û•¿®Uş°õÓª¤ô‡\˜Æá*ü(‚ŞÖà¤ø <šÙV¥P­+n!ªvR¤–6æn84Ò;“,¶ÈÊ¦u¼¿wzº»ÓŞ>9Ùş–*G†²Ñ@¥ƒ“İLm7”¬Ûr:S%­Ó´f9÷˜qèSasØå¦3“I›&éÊ}F£à'©š‰Üœ«:€h¡SrçgtÊ M9ıÎİHK2¤FÎHª2J™…E-ÅÉ‚{†ºğOP©^	“ÒWÑC“ƒ7ı‹[ôt)r&”J‹R` -]›RÌ­õtô¤ÛÖÕ,×·ôo½‚aE¥Où`Âuß,¯ë§²g@S¹hÁZ>\*©ãb%ôKY	±¬%ñØ²RÆ¼óğ¤Ù`„Ì$j¯×á \ÍLººÇi$²;úMÅÀ&"`1é'YãÙs)ortî@½aĞ‡tó’¿il Ÿ1œÜ¯ä z©È€…Ç±i˜0S²µÍIòs¼ÕÙ’Y~cZ—ÈùÊåG"ƒáŸåüÓ…/·,€äµ¯P4)[`Çnš–)—Ë¶œÒš°ßKçÏ÷ê¾+Ûl”Xé‰Ó‚,0.%wT8µÒE]J êàã­0æqF*›É(aÖÕ»MËTûÛFFÛ3	M‹ô3GNñBw›kj«Í²¢*‘‹#µ´Ê¦:ú¡(`´ñ~4¸ã|ûÍDpÂ”Şé†`²iï[zÿ»ò¶¥İÍ¹Ö UrÄ:‰ã±"»Øâ ­·„Ææ8öl"õ‡!œ(¬+¡!oâíl2 ¾aØ‹­ÓÀ2“‘UäÍê1>Ù¯¿K¡UF“9øbdsúE×0äWar>Ø…ë¬ïjµŠSèÕ7 şOw&Ú…ºRŞS0:¹“q7Ä:íè,¸ƒ_…ccuÔsğhÊa*8ÏÃnB¬Ç.Ï†zaUÆ$UæìQ©ÀÀ…x¾¯¯!V¾e*ôŠBU¹’F°‘íb¤4„c¨!;ø‹˜§ÛGâtt+%côÈwÜ[i;ÿŞ˜w“¾ Hó‘	ÊšŒÑ &Av¸ˆØ::Gq'L’8y"hë‡9Š nIpöizÀÌúõâ½ˆĞŠ£C†&îR¯'ÉmfŸZËDštÊplY&çx$Õµ·ÄnÅøàÇµŸÔû~BWá›÷8u.	sJ˜Éù‰ÆËoê¢şe‚BºØ&Šó¥3UªØ3m‹=‚Š„{Ø~¢1ÅO(×ÙCai	[Uß²¡BE7	T˜Zs|†ANFàºGq_°a÷› ¡šC99W*·09áu|S™‚	¶hŒ®aw5›¸K2T.£•~„±œ®´WÁ8¥ÕÃ‰D…‰¨$»pŒAÅ¶—?i‰·+¸ØÅ"ı­œ<ÊqÄdc9‹Ü^ÿÈ›ëš¹¢gæ6~bÏ¹À%'»ÿ0O7‰@ÒŸ0*1?ú¼ôUâÿÈ9ñğ±ßçˆÿóôy#ÿgıiıÙBÿ³ˆÿ~ïøïO]ñ|s–ÏèçŠõn…r—é€?]#Xa~ò•"»—†£”áœ@7çÀù$’•ìÈãÖ	6‡È ùEİ°fBM7¦qê·šæ#½ô¨ãÈÁV)¾çY7\]¶®"ãçˆ# z]!Íš„b#È³ÆUVet© b2·7>¤íC˜aÍ:Ñ#×¹ò'GqT.ÛÙ´[M`ôÁLÂ=0EKyJ²û3hw$ã:²]E>D4±ËÒtK«ÊùÛšõQû¹¹R² a¹B(b2(°f	-ÿ:^yğKÃ„ÿ›Èl©Á‚±˜#‡2J¡J—SÙTC2zèŠ‰k«„4ÅÂçZ¡Ğõô5=ÔÒìÙ]$?# #YÇ&²É$²ç›»êíÃÓ™õbšé•Êy™°‚À¶ÆÁx’0‡MŞÃéÆv×ñ6M•R?üzÖ"Íœ–'“F¤²ĞøõôÕáQûİÙ¯xùF‰¯·ÔMÓ
†eXrà«
ä)1’%^ƒQ?ø%àÕ‡Ä|¿şë¯ÿVi_ŒP<‚rÄ^êVÇ—!—„'ñP$­æŠ(¯ V[TàP_«æn/•)sëŸÕ §8qš
1’enèˆVAĞª)U™Ó—>#}êj&’¯B‘Ø¬iªh2Á¤$BF,}S¿•4nÉŠ 
SaÅRÄµÌ+^€ZS›’Q*ZJŒcüæ}Øù°Kb9¨&gRÜ7Ì{5Ó%lş½½º{r¸}º÷ı®‹¦wø›ŠÌË"¯ç0v3Œ¨³×š…UZsßèŞ¢}aÇĞm2Ä’M®ÂQ´¦¸ci+¹|Å$G#¼'ïãšXŠšñ[¯®U×lbˆÔ8ÜİİiŸãî¶‹'S³>Šğ"
 ïkµ£a8øÓÎwBvVpïåÓ&	¦´Z(¸İø?N:o7Ó·ËîñÌŠ»”ñ‡`ÇøÕ¦ºY5÷…²nJ¸…a÷‰˜$tØsŠzı‘ÚL	ôÎfC7ËêÁşiKÑˆ=PÏ˜ÑTñ éä$w54¤a,õ¤ŠÖ6©6ñÏ×{Û‡í×0L¯…&¥~¡ 0cfí¬ ÚE>²rû)öúÂwÕ¦”µİ(qtBTóWcÎáşòqzá0Mê†Õ.M@Ä5oó×vß¡jjxŸ–Õ~¬DOo¾ˆÖk½§Ş!¢ïÙ@?gmŒë$p^¾‚i3ºI‰.E¬úõ_ƒXMfjàÊ6&‡9Cåna"p³¯!ªw'Fßî“,­<E$œQ¥2œŒ®B½<şPy‡Š˜°^L§\ĞI8şÓÉîAröË`Ò{øHñ"HvøÉW¢„TŒß·q”PíÍÛÿ¾¹EŒÂU-…$3¦“›/+)*6œ•º4BåVÙ@í&‚.MQf®JšÕÜDhOCæ0>TêK£Í­İD$ ùd±©%µQëà<j–#L~>hãá·i´Åz
iï”vÒJ+Ştş´ıı6ûtùå4™®] Af(€ÛÎ%0ö(Ô¦&–u)†MÕ–Á5&5Z¦¬8–n8L<ùc'Dİ!Š’LÌ)e5î›Ë5ø—5ŞËè0k¥øËt¯Şßşá`Cò”ÙKu7˜"bÍLv¨ò±ĞS™,SdšYœ@©Õ‰ì=“p+E
G$}aìüÿË²?t%ÉÜgû¯èQc2y[RIJÚ&>)ÒTêş!¯º¡y…³dç–yB]Ğ-[¸DøòA¾¼£L²Z9Ú2jvöX{»?©ì¿f-½“f™—Ì6š==tÎÖ
	„4Ë"ÈÉfÏC¹e¹øÏ5:Êû{¯[ê~D¨½ïØÿ8å„1	pã-ˆ,—jÔ“°#ê?â„¼êù'pƒÚº¥¾¶ÌŞ*ü£MĞº¶._nHg­İ6³¦ò¶4 •Ù8@¿I±’Ñ *›åìd¿©‹›eá«vÑL±ç»4Ş@•¶DuP·03úˆØ°¿÷f÷°µÛêlìãW°J¥uÂAB»æ nSBY*4ñ—úÑÎ#HëW9lhºÌa­Û‡ÛïvOÚovŒŠ„_Ğ&\¦?5ı‚Æø¿¹Ø¢¾<TÉ˜lojÑ9§V8±î÷2Û´V¦àw[	—–MÚ-§¾lrâSïÍEÛ~8Ş3kù.›B”Áh7$^t¹=1”4%/.(Â•Ñå;¸ÿ DšÙ¦İªàşP"ìWÜVNv÷w·[»µ*ÁÓ£1„P;±ñmMİ›”ó@f	µSœ¥”¢NGGAÒÙİMÑ( ªTf)ı,ı|»D§–ú ºfJŠâªÊ¯ìY.ğ?ğëÌl¿# „2sàÛz?î"¸”¡z8Kfp›à©éùA×¦ĞÖ+µD±ñJıa,SùhæR5Ö™œXØ
“Ù:ìğ»¹„àÁ—AÔÃ(‚ÉXùµˆ'bÕÈIAs"@™:Ôä™RùÌÙ“/ò¡ÌƒŞí²¦ï-2¢‡HOŞª˜XÆ}á*Â€6ğ¢¹âwzÀ=ú*‡ìz0Lã%K'ÌÊS•À«Şz1°fdËÂ34³‚É l¿ÅçÌŸÕÏÑør$æŒÖ<wjjŸgDµ¯ 6¦·$ÚY:Î×@sˆ†“^G„y,,¿üI¿7Ìj²3oşiÏçñ\Óbú£ÄÏŸ?•“ë™
°Y´p.£Y™”ç¶“TÅ«ô~ºK«äõ!XöÛƒñé(º²ÕçõOözW!‘±R	7±ØÆÜàşuqB×‹jÀöL¥ÉšZiuîZ«…ÕZµêm4ãÅGb‹Á˜[ õT›‡Mö…Tz¡‘0”0b4¼L&ÈĞ2(™©T˜²CøÂDñu :S9{°ıny’íãöŞáÎîŸ›k¢$Ğä"á•TÄ¨»ƒë•ad\Ã»ã_ÿ}ÅhµLÉf"j‚ÃÀô†h[2Š{o„Àû$?°§Û'’EÏU]'g'àı>^_Êæbjt±ô3û§°ŞÚœõÊ`69ìš›W0¶!“bf„¶iDkˆR‹lPÙ|.ªŞ˜´ İ¨÷>à 0ìÑÕ è5Ä
|{t8M†ãUMCÙ¤¿îK¾!×¼¦O¿DC+±&†IÄÌû]¹™”‡;ßÍ7£3’bÇlµã®ÛÆæQv²1¯m5×ˆ³në¦
Å•j£6÷ƒ§7wÆÓJß›zÜÜ€=sÎ†Ğc­…5³äÊü<mLƒåJ…ªwŠŠivö`	BJau@Ÿ`²œl÷òÕ9B­®ˆÖŞ»½ÃSØ½XH‹ûF ğ°ñ®¦È«7/HrÄisŠ»«Ü0U|EzÆSmU:eÏs˜•è¶)¨æ•Feƒcá†+ÕH$ÿQ@Ğsôiõº?j<­6ªO}W"-Ãp¾İ^õ*¯za8(…@Zƒ™'¤wË§J[–Çè„UOgÉ@ş¦_œæ_4ÌÙIÅH§â;7~zZZv%}šÎM«rÉ>KYc«Dr:¸wîüù|!÷JéÒpğŞÒ-\}ÿ&ª°İg»A`ï¦ÄŠõÔw/©HÜğ Ìœmè7E ˜ÅôæÊ{!rú7A4~¢oc¨ê:÷e·
Š‹ˆGÚÔy0’ª¸LrD—ÎM GDç l,Ì½Ÿ`YÂ´NË±ã÷©9Õ:Fê^ceŒVjâ&ß·»µoz}Í¸ºÀz>êuÓíİ+@ÛÛ²ñmüNºe\s;Àœ×È÷½Û=õ³Qì€$ÿïòËš~ñúlo_"Ì~„3©ñ/ÿ´¡¶Û6Æ©Î9ñ	ß™KıFzÌªÂJ+f%FÂq›$°¨çÍ?´	ù-‘fPK²‰{‡&Á²Ğ®{‹-Nnæö®7ÛQ87Ö‹ğ2&ÓqR°Ë ÍKÓÚÂIq6šWÊy·Ø†Ó=–ÛòtÑ=òÓ´h[Õ¶ÊK%ÆÊÇoK½$s!-r.² dt^½ÌåfJ†”Ğm¾EÄ»¨¢OJö3#[e	ô#Cû1³sÓS°&I)º§mQ¿›&Nkãı6Rk+U›©ş{-)Å½°¹'á0ˆF°Áfx¦üKb=Ş\õ~ê›¿ŒmÒXë>ãã~Áø¥ÊTÛé¥¦{ÒOl÷EÀñŞrmx„îıÊz+ìbÇ¹¬£Aï–<V¤IæI8ä…ÊË…²d0r=Ìq<2Dëd„€÷zú7¡ÆªúœYV\”Y¢÷³l!³~º+fÓXA­²gáï·;007Cõ¹™~•“ÂnÎÌW*MÅ”eà™ín·K‹yóoŒ:`"âu2Ëº8Î-°®¦.*;8d¥/×˜i>Åæa·=¢W$@#<«.Î×a0Bc—u¿¶åuXéÛ—U‘üúïÊù^„è-ŒrÆ€D„1Á³òTV|³19¨yÒÏ…,í«/(±‰8 Qç=ş^% €°|YñuØS"*Hl„ÃTAŒM—gi™"«òEe,K:ÚğòÆj*hGiÀf°¾äV2êhÆîQMÁ¬©ÑÒ|¦FF7Ø¤ê5º0ást]¤¡)ìø7Ds$)
‚¹÷O„ f.èE¿rŠ©zK¹@şLÁ˜4(ÖÆRÊØİË…×,öGbÃë’bc`ˆ€ Àrğ@èï+˜[B(ã(!A0 G_&”® 	NÌ>!e ù[AµJÜgØ.LåXå?éí7æ¯”©Ò|SV+øˆÌ y‘>Òùõßó½…?FdCšíı`k
)`öü‰EÅAˆ ,ŠËàØğOÆn$ ¼&§{lIíQH²€öz{­½–qáJ»:gnQ‚æ¤aNX!İ­-™¶Ü±1ê~ªk7ªŸŠçaæŒj§e+bÛè
÷a¯*;¾³uË…N¿N±ó;_9—ŸŞÆÑp£C±8ÙRsú~Vöggu¾øÌ&°rE¢Ü’œéõ’3ğí	MÛ(ÉLºÓ™ØBãÄßjMgP
¨Ë´Ci²'	ş+Mº´ôÙkz±­º€O‘ºU@Ú»ìíİGQ@e#»½ózŸuÃk&\4q÷ã+iÈšZûİÂ°èÊÊ·4ÏfÕ0=´]Q´;1‹‘´cÙ-ÙÁ”˜ëªß™í2ÒÊP¹Njf/tâ1Ñçä÷şËs‚È}X¼à³Õ¥ß/˜aÊ°i+¦7ƒsV2ËlœÜ <'ö°Ü•eN¥V‰ïTŠš‡’»g[%İeo/<Úb³.8œ§íß¥™¸,”ÒÁ[JêMeœø
kF€UoªS}avO²¶õdjZä8j¦F'{€çKœv>Ùãâ~G3×’<}àkú8½Ä—›&«ˆ£uRÇqÔ|ìÑ³ÈBğº—sÿ¼æÒ;5ëÓ¿æÏ6y0<=rÙMÁøØ€4üÉüMU`Ğ6p¾™ºÎÑa6•Ë88Şß{³wÚŞ~s
e´vvá
^
`Ç3_®å‘š«üÜ¬pQ×+qKÉ¸¼)MíŒ×¦‘P”â‹vbFâº#ÜŸcDg!q˜‘ÕÌ°”GÉ‘C";rÿZ+ååÖ¢5Ãm»×iH6õÇè£Áœ‘—=s'ÕÑ_6"‘,³zvˆ²»RŸ°çbJ‰ Kº(J@"(#E»S°4zG~‹‹0'÷‘åØˆ³f×PTÑÎ;ccŞîb;1ô@2¥¨tÊA–9Æ¼‚SËy@æiæué"9“ñ–0wŠ¸ÎÏ÷Ä«LÊÓzá‰ÿóüéÓü7ü¾‘ÿ³¶À[à¿İÿ­(ŞOÇ‰âÆÓ}¬QÜä)âuV=`l.7•™ÚÍÍMõ:ºb¶'ƒìÕ‹Q­w‰ZÃşT¸¶
ÁWÊ²ãAÚWtÔ `ô•PáùL©´Òö¬¬
-"èLÁ6¼ˆù	{ßÑÁñÉîñş_(’¼D>lÿpt²Óú‘¾¾ÁïÄ)cÎÂ†ö€À Ï}×û›
\JÑ¼Wş­Á0B?PiŠ@l…á¬Kşş£kÊHÇ«Šè¼Ì'hëgÑlŠÊcñ“aGjtã´ ®€×©ü€
Yl\*™¡‰4ØŠë 	ŠÊ[QDRa>Ÿ?GåN9ªµ»×ÂyT=Sö*à}kr”|eüÏFıùÆ³şçÆÓÅş¿Øÿïÿ¹îÂÿ<}bPÖt¦Ï‰ê<I¬ã¹\àÎ’¯ò-•	­qå$©âÅ ½¤*¤Ãåm€®§ŠşVİÓ{ŞÜGÄe4JÆ„%­n`s<<:İ{‹^ê‡;äWK4ñ8º¼­ Rúª§ÅM“UÔ^#%]€!yxòdºKşTŒá¯zšS–âhÃ>‚]zJ'Û{;GbûàõŞîáé.–§nq\#«gŞóL?B2‹ûB#«¢Ûıyç]{gût}ZM#|ï¦ˆ—äÌBŒ—¾çø´D2/Øİƒ´Àğy0ÌÓï³=³{N”üóñùø8¾	Gä¡º¢°'z°Ò£Q€NÉ¿”Ò[õ¸,êhSİçãÇví”œT”¨?«®mˆıÓVîÅ‹ìÖ	Àt‡—Î§T:4A‘\„½=9‚Ir¸Óô¯ˆ°ª^K÷ÔHzš¢ÖS©¬3:@¯škfÌ~ò¾CÑ®3ûy×oùrØY6S¸Ğ÷(pX¿,kZä‘‹ µÀÈ}GSr¶¾;=:†uù±{…LÙ¨‚òñ*Åb<:>5ZgA›ød>ÇÕÎ$¨N.ûc`Ó¤èÉz½ñÂs@§˜ÅmZ ^¸E“Ù —ÒÉîëƒ{ ›ø±;Iec}}ıù±[‰’ø¤>Sèş²v¡ßd<ªš£ú‹3×İÚ¢ìº§c”ûY6îã‹gíg¹¶‘oÌ}3kŸ¨iE SîôzV­Wë¾—qÓ™JÓ–IÌÆ_OÕ¼1{æLæeŞ0©®á&(“º­²›Ëç˜l™{2ÎeÕ+Dİ1@wV§•E[ ¶1İšf³/<‡ı©i~º5Í0ss&ü–:¶ÑO¶YUµoeÌíí:ŠÌÙ§v³Aıœî‘0½s•Y£>TxéTœ~:‘jG¶ŸVÓ_fı
dıìM!¥‰îWÑøıä‚6†ŸûC=LEV a¢<oq'DPqªšğíeDÓFT°Óµ÷vvUª)ğè1JJàñáÁ‡J"E±ø CóqYxÜ´à|²J4Z¹^Ÿv<Š;ct)éb‘uEp2:¡Ù84À Õâ|_vÏÚ{§»Vz7ŸU†¨«"ã„Ä(ª
,í‡qû—Z½…mTë´ûØÏ¥ò±¹Ì¯—=Ã¡Ú¢üIña»uæ‡}ºueu,í¹õP×Äï–=Ã×<_2r5bdd„!­!ş(ºôãM.:aRã—°ˆÆ4¤ÎVñ¹)«p¯®~üÅ÷L_s8:îš5GˆY%h
#ÇäHU&¦ïìnïS©rï7ë©Â §“Şä)¡Ô"ËÒ”E3FŒzJ']Æ‹øĞys"ƒ'‡ÕÇIlç¤‡'œgÏ²¯›¾
+à§Úp;g­v^­µ?‹ï_¨çBTr‰391ÜÓru™aí'"¾€Ÿçğû#›Šh W¼1F½
1Xj€I=7¶AÕëAõr†Ã òôˆ¨ğ¨&›ZWI-Û\ñl”ÇÇ[í\^YÜó’gBH›¦4ªAŞ€Î;Eã†4²´4ÌõöL±ê(I$–ˆƒI%á*¡^}Q¥œKgÛV 'L­<9jµÚÛ'úº`rËj‰-ªQO_”V^¼9>SüZXinJ9×_éÒUãäàÛ·>ÆŒG+Xë£şõóÀêöx|²ûvïÏM¼Ï.¯z%£i˜ŞÙ¸¹ÛÆ Zsµ¯ =@w>‚3¬Y¥Â'6œSMô—êv+CVÏÆ¤Qœzûbu¯`ç_å#~ÒÆ¢ª½á@Œ€g¸­°f·Âp¹®óérÚÀ%¬ikşC5YşLSñƒ{5øK¶ƒ»HEê…~ı®ÚxÙéé)`|o?<1q,ì¾Ûı³ø~ûdw–çıpÒ¶Ø
ŸXâ0xT“c™Ó¨B¬ç£ãÙcà¾ÂÑ]|¬×+İğø½‹«ñØ¬ô/¸x£“Kãa'ˆFqCı‚5r×Ó·ÇÉX}ÆŒ7Wï;UW½Éx=ıFÏ}/…¡múıp0A„6‘L.®Y€,úÁ‡PğğGƒ@P†f˜FÁH¨+sîA÷B\Á?ŠV	5p°‹UÏ<OÛHI0œ»ĞĞ»äõìÃS!…6ü{M¦ÏAöbèÃI¢×ƒxPÁşú²°
zv<P°IÿøãOWhÃä¶tÑòWp•ÌK·ÑÏéL±¶÷àfï¹àQŠb9¬¥B8íT[ó¼]Òı`@Ó‡sç=ÊõÿíKa„ï0¸ˆ*Õ?Ô†£§bõ§Rä‰DÃBÙÊµÎqˆow¡™'­‘Ë²ï×E>+ínÎê¢É5Í8³—¿â¡­¸3dÉÊøÿfÙIİşB“Æt6§Féy©®…h:“mEÄí‹Q0€û
ìûÑGØñ×‘ëËæúò»91¿„Ëí›â·†±}ÓYJŞe•¾ ²Êoúù¶gƒ…,¿XÎ¾Ú‡¯^·v>…Xá»ÚnT7PF¸jo7§ÙÔÆın²OéĞ3ë
;rê!"²Kš°:Ç0×Yˆ ï„Ç^“FZÿÔX#ÍüúİgğvuãmÑ‰¼ğ€nclšJ½Mùq.bùÒ´çÖ4ÒÖ,ãî^ùG|€C!søRÚ²ôÖ<Xr;7Y…c›=œcø—}–ê®~[0ù)õ®'ÅçÎîçãaæWf>Ã¨Íúí¦R!¥	ìzÓ*¦~2>©ÕĞ-»«;£0ùû¨Zò}âf›&3…5æê8™4¤ cJuŞßÿmvu†ùMQ}§±øy’Œµi/U{©,2Å
á„¡>! b³‚ë ê¡3 ¶:»5d4ÒĞ>p°ãş€5gùlzTTË	Y)™ 	
%úBqjÖLTÀÅiİ€NètLÏÍ•Ù­Çe4c¶0
¦Ã ñÙŸYdd,x­lfÖJ¶-"·òŒ…ç6ŞÒËñÛ£Ö©‘Zué×‡g¯wO²‹5	Ğ¶	–f®%sØÁY±V­?«ÖUe¨k”œÒ¾Æc¬C×Í]ÿûˆ×·t§·/vP»	(*>Ÿ$dE2ÔÑ)ˆH•D‰ĞøğtÌ¸1Bz\(î#Eí¿ÿ›Ø»ÄTŠ¾‡N˜·fvZ„h·•šËŒ»UÏàxœiÿkù|]ûßúúÓçyûßõÆÂşkaÿ5ÃşëŞ`ÆT¿Ÿ›ö'†Çü™LŒÉªè«Øû²Kj^á}¶Oêh¼­M{ù©ğİ?ew…ÇŸ=ùV…[îÊfÙ’úód@ØôxPIĞ†Gd<V(ïy[…ÃĞÜ;©„]TêÎ›—.°,ş“z¥¶uÕ?j¥¸ÖcÏ31B3øRŒLúK4lÚ £ÒÃ?'ì(gŸ(o.²\E6“j @Z”Ö„~JòÁ¥¥RdtN´a>g<g!JëôÔj9¤İÈâİÁ³§ôLš™Àïgú·¶§Ï	K©ÍõbÖVê¦§ô†Q»¢Ís­ÎÓÿ˜-ÄnòËfVGDlzÓ¢Z­
;­tà•ÑµıÆÀ%‹ÈC1‘›ÖÛæSêÃczzIwúÑUÒ\)cÌ=5_ä¬JN`“(-±Y±<Uœ\õ^Æ¼ºÄFùßE‡İyÇ©`·&6¥Ç.PBŞQQsïe<›¨›éäü¶É`EÎïTZ£câ	hŞt]äm./NÙ,*d³¬ğŒö“_°|Ü41TQŸkÃaçã3	¢bCµsBJµjÀaÛ€ê¶<ßrĞìD%¹Ì{‹fâ»Q"›e$±AaäSØ_‚ÂÑŠŒı„å×n6Å´¨à‰áÊ{	5ƒÛÁé$ZÂE/T”pG“R˜!Ş,hWàË[ 
q{cÇ(„2~Ú BïÁ^™Ê³n©D[;¢0Æ5İ!Ò­µN1ğ¦CUˆ!8­u‹÷“_¸`’Îä2DSaçÌ®—§ÀvÇc­À¶ëÉŞN cÜPt†‚~ˆ''!¾Á·(/ë‚jø‰gÒ¥ş7Û„Úà+e];ÖšO•£Ê	ä."­{fÄÌ–S¨"gÅ²ÍÌ%.OŒBšşpZ‰ øõwvÃ?"·ŞQ0#¾¶PğĞ54ğ¨ƒ2É‰89·áÑ£4 3œ±¯¾ih„,
oé]TnİéEYß*q!Ñ;íB?pE‹œÆÎ»pV!lª®sêpÏğáz<]Şüy'ØÅ¡Ê†ñÎBrKØô˜T¤SÙ÷tÅÚã½|ÿ0H¨Ö7‰$ö¾›AÜ€}¶ê¨Àú'¬/‹{ÿŒØˆĞ!o“^ˆ¸jºTÚ¡´Ó·çzØJıÎ³³{˜Æ¦¢K¼Nï¢ÕCİö{wR¤g¶B{Èù­oéşa•ë¥¿Å€’–g7>ËpÂ¯SÒ<ùäŒ º´Ä{Å¼˜(?†[:—<Ìİ ÒñqyYà9äj½y"§8´jêè]j7õ"ôôà»tBDî\+Rc,V”Y4ëû˜Ç³7¿£¯—ÛÏà|øÛßÔ¯çi%ãÚpi[™H®ë2ö,®O¦x*Sà¦K`9+n¬(7DyC”ŸeÃqwìÄØá)V'†Ik<B»«’Qd0"àå¤G2€É oÂã`@!¤!ÆèA¸y2"wrûr(Ø\J§bOÜ€òKÛ×FfØÚfÁ×ÒfªI£Kä^b*§©‘ÀÌ.¸®­Ùp]r@¦ [@ã%ïé-ÓŞ\ï_$±ÂKÔQì§!Q&*¹zªY8WO³x1v;]0pT²{©s3-ÜMÛ©Ü³ë[(#án‘ÚrqYYÌi3Û¦xeÖI˜Î3RÎX+!s*òAdO^Øbuòäfì„¬#6şí…îk˜îO³;Ï¼j—÷Ü˜iv_ÔH—X02ş=¶½´DW,¼ÍµàuZVI¨iÓ–È(£K'ÍÕGå?" ıbèÂ+„ºz°QÂ¦)ª½~ãI€÷2ä”¤¤ò|¥±^õ™QT§D…˜¿*ò{,*¡iŸr>¶7bÍåï Ñ°£(°ˆG¯˜+‹Ùm…Xå†IĞñ~òÿj­w’Ú­cş~2úŸz’‹§ıÏ×@ö«É°Úï~ü‡µFc#«ÿ{ºşt}¡ÿû*ú?È …Cïy/‡¯¼%Ô–½û¯s#yÿ²oH--à>Ù»¬ë[‡x´ÃH%{bE»g)]ı*	óE‡€¹øLV¡s_âı(¼L-ëP‡T£Ø¥~¼¬¯ªBx3št:ápœˆX „Äîx¹Éfâ´OÄÅdÌH/¸ò®^U*/kò+ŠÄ"<Ë‚^Õ{Yòx»ÉK´ä—£¸/;[õØk6›@ÜQøJx§±ˆ¦™mzKª!¨ı”I ñÅèÕ¬2µm*Y`8LC!]îK`”^Õá'üyYƒ*¦´*¥–üT*KHlóÂ@Äöd[-#"U¬mL”–‰%ÍoYDõÌjpŒiËÕ7î ßg'í’&P£ˆïØœ»Æ\EÄ½T¨”%u±µ;¯ÍW¨Ké,E¦Q'%Š£aOkEê"©ßN"¬Oa8IÚsFü\h°T¼ÿ¶ø|éóFûËñ€÷àÿ¯¯-ø¿¯<şæ²ÿšã¿¾¶^ÏÚ­¯-ğ¿¾ÎøŸûxæÑ…•Æ\õô[›q{!|4«Û“+QáBjÀ_:´Uª>IŒ¯Bß«¶¾‡Û»mªy®“ãŒñ0eií·öZİš‹‘g àaöÏ/_³¦èüòä'ú	—nøÙÂß˜Cxà<W"g.—Òd² nĞÙ»f½0«–­êVWÎù„Ì?aÑõ<e—¬Ç†8ÒzNÖ½Ô İÎnëÍÉ5Ö³X{âÕ›İ‹İøI/ú GïñéD®ì#Oµn}¢Ş˜ÉÅ2ã†iS]9ÕYÑu¨7¤øÜ!©¡’¾^†^BÊó„äPn(±¤¾—!¥K:9´È4ƒ§ÁqÒx–¥é6İf^I\AU‘15éÉñ±™Ì2L[`oæáñ<W
¹ş”³ª×âÛi¬o/2Y_"«ãÙì*)ÿÓßşö£Lğ“PMR<(¶GuxQ|À6Ûê9²ôTšjS×¤¶k±:,´+óXhËiÍKNœ%<ã ò¶ÂšP€H¤B0¸„Û"õ½™%ºÂAPTŒ›N<ŒEhQŞ*·jàŞ@›Îµ®L­¶8SÚ­•ù¨cğ°åí±é©ÚªLĞkl”6•u“’jW /ë‘ ¸ì-0öüPZ à^àáÕvvúíÑ‰—…f[éÒƒvÜ®ÿóûxÜ‡[BË¬z¦ûÿ+ş¿Ó`®t´±ïÃ	ÿæÿmäù¿§Ï6üß×‘ÿ½á¡zúø„ãû-
±$æ>Ù„U=²€'>Qc bÃåáğ´œĞÔqç½ pq*Ó± ,î¡È¡½ÊIût+ŞªÔNE’µtƒ¬hp…Xw˜öÂÅy%vâ›A/º()dn…<ùõ»‡QéOÑ½„%…Ü$| NøM$$®W¿± ìÉËI÷.Î‰U/c´O7ÒÃR8êc,LÿL²PÒœáeGeºT“Må“Í{Š1³ÕşãD—-±e~¿¡å\M½§x2Ã¤ü®$‘sõ{!t| ó_ÅF3LöôŸyşo¬åğßtqşÿô'<zÀ&®#? <§\Ä¤2»—a0&8\Ö“+AxUÏ»&Ç<`(vÂNØ¿GOùå!
 )Õr?Üı¡µi	äèSKô–(bêÊß¬â±`TCó%Ç=¬h¾PÂ	ÂÅ3_ì¡±kwÒ!-&õLÁbs†2Ôj–a@R5„ÔI&İX]8‰év–˜éßNè@à3ÂØ‘ITcDp ½iR5³JàìúîvƒøF´” XÁÕ¼IÛ?rÚù®^_}¤øƒQXÑÿíŞŸww
€âiÇTüÑå°Óÿ€ÎT8ÒE‚^ä(ñ6ú4T†éQ/ßº3Q_™Â–ÑzZ"ù«S³—¤
–fWf×Işk…Ã1Í1ñ¢h–Më¥1•ÎNöM*åªÛ\áRÿÃ=f3†¿„RªkErÃšH–„J¡ã
<Só‰Ø9‹N1ÁPÇfª¿`ü5œ 1r…
B•;
ƒ~`²ƒœ§EC,A©qšjR37šwÆA$ID
ŠjN‹;L¼æ"í*]kv1±:
*ÍÓè}@|}/èÀ
 9KïüˆÖ½÷€B1+ÔŠU³}<"o50ÔDI…DVÚgâLÉ@AÅ**ĞıöÉÁõóšï»åƒÚùÌ‰×0_°PõÍş8ÀºWa’İßŒE«L9Hœœ²z'šÕ³fôİ§R›èl´kœ)õ	›©¸ıQø nz}ÙŸG®¹°#tÜÂvjÌ„¹§Â[Scˆ;kêË†€ıİŒiP³Âd‰»÷eÁF›äæ}L°Ø{Ğöß³>ÅdÄAË·ıÁ¹®01vúV-Dœ…œì¿¾şÿ¡¹şùùÿõçÏ3ü£ñl¡ÿı*ŸÇ¿\$Ã-ó“]©¯òCa(~E>Oşë^¡TÂód™ú?ö¼ÇQßp+V" º§Û€F¶zfŠšY•Á—}>?VŠçÙe¢±½$}›–X‘ŞMïÓ?¥o¤.}5µ¶{çiN­r5šc¼Ö¢•ôeö:ôó½±EgÎM »Ô¯æ»•.C×m˜ü<¤ş;£ '®æ·¨ÀU¤2vöŒ+9!,ù*ÉI2ÙÁ7Ó(Û§”™)ó ªhÍ‹<ĞYª›/*À15Î[Æ¾¨$×æ4SÔøB¢ãÑ”QáB]¾X-˜ù–zÿ®»•p› ˜]S`£c	3"aiP Î4E[Ø•İÀ´ôŞÂ&¢H÷RÉÏ¦Ÿ2:P]”S<°ı{Êµ˜FE”EBËd¡¨'Ósö_Y4¸g+Ú80‘ïnè -¤©Ã,[®·U²w€Je‹œ1éÄâb#ùÿ‰İp<“

y¿¢ÿÏÚó¬şÿicıÙ‚ÿÿ:òÿ£1­>z8•ÿe(Pu"JJòÁŠ;Ä%±8*½øúxŞõÃ×ãeÜëÅ7(RAi‘,MëãßÃ¦¿ç+!ÅÂ_’ PXtÄ
q™`%(Ù†½áAL.zñ…´¨ìnïìÂ´÷_©m¥
e²% tÀË¨A·©»½%”“—wÓ
surSgÔ”	ˆ2,Rb‘QMH9ÿë şóÖ¹c£
Ñzÿ?í|÷Bl›æ#Ùj”+)³‡è¢Døçî‡Ê‹
ü¯Á¬"Q´xÌ¢Å»uÍYöå°£Küûˆ¿ÿ›Uì‰d{™d ‹Zÿ.1àaĞÅôht &Hde—ÇIr	ûæ‰J‡Ñ=‚7‰ˆDÍ¥(Š61÷Şx9±ô$î!¬E2„!‘—oR³à‰Éş ×ª^İ`hğÍFÛÔTJêA¯±1ŒüÓ’2FT¿ÁÄhi‰u½ji¯P!`.xÔ%PK4œˆ˜(z¦>²$èi!§$V-JÍ-”ç«XØ.>‹Ïâ³ø,>‹Ïâ³ø,>‹Ïâ³ø,>‹Ïâ³ø,>‹Ïâ³ø,>‹Ïâ³ø,>‹Ïâ³ø,>‹Ïâ³ø,>‹Ïâ³ø,>‹Ï?ğóÿ ¿´ı  