#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3538122710"
MD5="7c2e64070ba580b994682193139a2668"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22300"
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
	echo Date of packaging: Mon Jun 14 23:46:26 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿVÜ] ¼}•À1Dd]‡Á›PætİDñr\:ö[7Õr×
ZØÔtÈˆ;€dab×}ìUºD¶M6Ìlñtöf‡
OfƒØSÒíğ£C³rl,Aõl“Bƒ,ÕˆÚÔjå|·Fû‡j”ıÂzûWã©}ÖO}·ùß@a¼qÊ”çf(üwgŞºñÍ»cºì“A¾g[ê –©¥Tê<âÍÃp|¨eÂÿ‘$Â†tÈËNáûæ@²>él!£ÓÀÕ±¼UU€Ğ«¹ëy[åñT•4Ó10ï$À÷‚h¬g¶ÏğÏ!ÁB¢7¸ëI‰pMFö`EÕjçĞ¾Kmÿj°éGÜ_ Làä’y¥ßíMm2ÚÉş0yTZĞì›‡5Zûkúú¨Á2N¥ÛD¿³Ü 	€¢F]‹@<õz^~E›>8÷úüÊÆØV-0Æ)Í%W	–íÜ…J¤äb’ŞÑ¬)QO™äÓ&Èæ5%/;×c\Æö ««™(~4
e|l£ÀÆ‡C#ÃÌ$å™úÔÈöY¼EË«­$4Î·ÖNÿ,jÇ—Ø7©Õ³úfBJØCÖáj˜ +»#IGè“‡“8_Ã@B¬ö7WôR5;Ùà,{ñ³WÎX‘:¿øMOÓé:§Â(–(±$R¿$êîk¯IÆ§¤;! æ±j¡¹Â	†#=ÀPGÿ.’rIùû¢¢~°;\·Ê·NˆµQ¡ ·4íIlCAMjÙÿ¾G=½Í^=Ò¨L{bÇB®n5ÄIIËÃüMø²#ïüi„§İyRf¤[|V_	ZüêğDT4h‚T?à«êúø–º|÷Œµ3y‡B— p’õAœºæ¸¾FªJø©m= ¶§îÚËƒùÍ€JXæ1l„JxUÂS¸É)d§i§mî¶‡š0¾¯êÜ…¡ÁR’V±v®h2Uªë™Ø‚oo$y. |‘Pl%p‘óE
–Ë³èÄ?L‹+±ŸÁ50Ô‚4ÿ<<)=Ve-¸M_)b\Õ°ù-"oáæĞ*W;dZÂ( ÖÎ¢4,JÄ§‰ğ‰%Ë^Ñò˜¦@L¸z=G®y¹íşùu…ç7”qé2a‡X2U5t–ëúºpSƒ°MB¦B„eºj1‹ğµ	Á¼¸¼EˆjG,Û`Ú¶wÃa“8C&Txª1ŸšÑn6‹šs?nxà¬ªCJÉ9¨èÓ}Ry7•§_&¡¨r´ZÆrZÌŸª±• Ö$ôm9Iç€=&¬æözá2h6@³Yo~iåî
8ºi9/µƒì•JãPSÊ²yÏ0÷.hìëgÓ²z]´ğÿ¸½Q?ÚèèJ¢PëÀ^ôOL³ciİAe·¾xBÎDnQmÁaÜì]½|¦Ã«
””«¿`÷Ö±¼O5H*lâ\O—FÍ¡B3jZ}Ë®[–¿!}²Ò<À¯
wuec¿U¨Š}ïÑµ¯#uñ·Û¤	à}³D¸óCĞFM†ÅĞ‰È”1é “TAÄİ˜*LF(¡É×Nµ‹M´Ì(‰î¼FPö—NLlÕBx}ûïáƒâ_=ÚBu]9ó¤0 Ç4RH—B°Ã¨0ˆãşÊ~DßÚ[ÓXe>ŠdRåbMàÏY®Ôíeµ³ÜS?U%T55ÑxÊ3„^Î‚ódî2¶­ø¥ú›rİÅøİ)ìnáfÒ,ÜRä	¨ó¨=-¬‡³ëf6eÖ9öø.ºšï	Z¥ü|›bmu+¹YÙIÙ#âê¡#³û±$vÈ’ˆ‹x°Î1Ln×ğÖ¼B€v¯Ë,N×j~{Ô™EµsßÁÜE˜UrOt(&ÁñvÈœ
½ëOï:ŞøBlcm$~èb
5­Gç–RS•³ƒ»7îbº@¦¼ğÁe#¢Êó‚½¨‚L†óÃRO§‹ê¶/I*İ,>ùS™qÎ®<±ĞèäŠ<Ìpî{|Ô—Ä?uG5^*Ö×B~tŸc°yÑ¶ûˆÏpÈÄ ½[0ÍFë (\1ˆæ….–§—ËD	ãA-npïkíê¶ÊtPöêaCÙlºyÔÓ¾æXµ‹¶H=Y›!i‚¡òw#§’GÛT®aÂ…†2šº<éá°n&ÕF,ÉOd;øMŞÅØK7ëšB?ÁÂ‰ÿå¿k*P<('C ³ÙåÑîGî-‹¿s@Şşß/
¼¼ãŒk5ˆ£ÈZ7”ÏT/ıõê¨˜ m[ŸB6±^#£Ë%(ªhZvÁB£ö×~„¤6\nà~‰ÉÃš,Ø¦´Ş¢d°$”T€.•ÛB,s†D™¥zS”ˆ5Ï\&rVŒ¶v:rç¼ ˜PÀÜop“+;º5fó”’7c®@Ëkü§—€~„ÑúRP$#ÒZik±@ÑÙ~&ªºÁU\kxk²ÚQÅìø Üû4Êã}ßc‚Ë?±†”{PødEB?-Ëš‡©‚ÔgØƒ‰ò£xÂ×ödJGMDwÖÑ¿jƒæÎ}‘ĞÂš;- Æ‘İM_;”/ñÂ0¼º+İˆ“6.œFé9¨…,Ü¾‘sQ4•jNk·Eê¸\‰n9û Pø
†”ÔIaQQ¡c%:2$è‹ëÖïçg¡¦¯'<]©£^iÍu“éÂvJWéäÇ*ô¿@ÂS7ì*ˆã Ÿq%‹§­5u"¶ƒ¥6£:æÖ&Ú=0Ÿ¥ˆ/Ò	ƒ i†î}"Û¾0^S%o¤#?¦€<¿»lÑhlï0¢¦×±Ô*ƒ‘İ°šOÕo²•ú®¯é Gÿše`úu‚’ÍjüF C¥¦„nŒ ÚçâÆU™ùXÓµ¤öázãM ˜i¬1Âh72©î†û‰›pó’¢Æ›#Ì_Œ½8¤Šäñ˜ `œãÌaíØ¦´óäO&òşâ´õM½…ãÃ©¥Ä8‘ËŠ7˜ËWPé°Õ§\$ÏÓ~í¹;îá2µ/‡E}})/bÓ7ÂÂê/¥†ømId€€\~vk'¸z³üC.cÓe8ÿ°+Ê8äi©Gl¿¼¸/‚¢èU_€p!gÕë™zt{ âCÄØ‡±MÅ1_.ûãÉ¶ ‹ã•Ó¦céIÿ5–{É=ëFõ{ÂÊÂ23¨•£;k¨x§^
è”%!’A"¿á¤V~)KK$æâ²Y È(­MÛ€+;Îó¦KP:­¨çS´£†½¯~Õ|7u°J§Û ƒ¯$hêŸ-òÜ:)p¿Áã:ùÎF^uU!>9%‘õ¡/%õw²s.V=´°¬±õØşë7‘ÈƒäşÍ8æ!„™¬ı`™“æ[^–5‘ ¾‹MşdB´Wãå5ùÍªÃÿÂ’>!cPÈ¥÷!ô½‘ÄYBPƒúğ˜WqŞĞ”øŒj
£(cBÊ¼Ô{3Ÿ:ˆÖ£7ƒßë¦ÉNz,íˆ ’wHUÕä^®«`ûXGxP/™õ¼"ñd:9…tª¬cr%¹Ú­$—)òkµ;õ¡æİ«ùî‹>Î;DO/»ØO‚}Ïğ·mgiK Ô¼ÊÆ¼ËUWü‰eû`øH#Iö¿8”Î_i­,;‡Aê”5«ğ¥9¦¨MöÊkƒmš&¸&}ú7ÿ\¤ºâ±§©-³Esf®dz@!dR"ÆÅöÿõÆÅ¹éŸ×£NQË6Ù%æ#Û+æÂP[I ™~— ZğşÅü±ªºiîsb='ñUbÆíg,q„%–•2›ş@XÛ'²Ø¨xšş•wşÊÔeµĞ·'ü½*;0Ñ'E£+iåÇõ	›êŠ­W÷PôA^6p¨æDäõA²ïâ3ñ"ì‹ßÛ;7ËÓÓÚ¨=:øO·î¶­íŒpbÔŞİkÍXÃWYË«¶µ]Sş<Z3šS»õ€w¡q•üô`SH?ÎX‰H.ùÕ5ËµUP× Aã ¹ ™bDf%•È¶ÂCT2ºÃèêßkg”t…½C×ÀxóÙj€XbNCeãiVRoş¨l†u¶qG¾¦ÚCíEr%»%×¿r+$¯3¼ô½_NtàÁş›1B,ÌI¢ÇaµğÑz®ë:<îÛõ¶ø™†)ˆ‰BÅ²âæ’ãq,±«î÷TPØ¾÷`œ vV%§eÆÄ¢¨õ){ÀED‰ˆ! ˜nL>p"j¬˜*½)ªQ;N$FÉ´Î¶L‹Ì(ËŠÜ>â‚M}|«ŠÈl°âtq®ôê
0}‡¥'áaO	ìä}ıWûÌÆ¨oùùö«ÂğÏ<3ÃÆ÷ä}s~~´FI)w¡ÜÚî½·X6ˆ(Ğˆ"*yM­æ$“¶Å¼GË4ó•ã=XŞ.Jâ>İÙ{SUJ{mm3„Òö@©qw2ËTJgŸñ5æ\è˜Ú,.’çÍÌØ£¼
3Æ<
 ¿ˆ_…<§ìÌpNVwŠÅ$WX¥1+·¨Zü¿‚È	$ÚÇÕ¯ E‰Q7¶Ö>Ùé¹ñ´>'Ë-UY¥ºÁŠ
éÆ}µ Ğ'§Ög¿ºooP½&X@-µƒÁ,¬^ŒöŒ6JI«FOæ±ĞrìöUnÙªô/aøŠdÿŸ!Ñ}È dGQáÂ÷Ù­DxÑ9k{•{š®8™L·RÃx/×v¹oË4.£Yñ=ŠÂŠ©çF¢½æÀÕœ†
¢5lEÍ1;Î«%àL¼t~ê-;s@a‰Ùºg´çRÅ>×¤}ß@w¤Ğ:Ğfa—ëuŒ7-¯ÖÎ£sÓén*t$æ5Õ“ÃuP‚Ü·Jâ€d­%vbWxº™D`V[ißíKş€^ƒ¾¢l·RXÕâÀ/'GÇ{œ"´B¶@c äÍßÎÁ ï(Zª‹6f¢Àşs±3,¡şÓUCRˆ{ôµo>o p}h2¯i-ü”_y„ù$ÎyÉ‚$Ÿïs ¢‰Ÿ#Ï—XÇÓÂŠÿDºâ³v!Sqûu*WQŞ»]›÷8Ú¡,¬1$)4§á’ÙÊ.@üQ¼ÿØÊ„÷Y1É§xÁOIÙ¨&òş:`.»­¯l²‘TÎU¶R¾ÍFÈ28>¾šZ<8ÚlacF!3ˆrĞPW.íÕÀá¨íŞxuÛÿr§Î«Â#Ä€X¾®¿½ÈÌ©8oÅ|ÓÀÿ22õË18q°çDYêßV%¸VËiLYËÙí—}ïy_
áKÌqÏlºï­Ç2È_‘³I®¯bJïùMc&¾>©²!»"xéŞrÅbÇVŞGsBM™âtàjı$8÷ó<©£¢%—¼¬>VöÅò±L{uÂÒğ²vĞ@áìÌ†mæ0d~8JŸ)Õ¿!5È½İÂ0×úLXhû;çÑòuöIJc±¥CÆ¦ã-!vëFp]BğÀZv­¹ŒkŠáôa­A'b$Ê]^„½‰Çş@’Æï°&u`Í‹bÕ“‘ ²f‘YFâm‚—¦Ë;Ü"ò?€¿Ÿ‹+¼!Y¢9{ci…9—œ^ÖĞ•mm:Z7²‹¹pMLõô¿-ÇãäĞƒGj¯‘Ú¦ÒYôFÍıœÌÅàæ*íÑ }ypÒTNÏ3Ì,b­æ	$öuöÉä-şĞ¡1=5biaÉ7•"ët¸Íå¬:@‘r¼pS“_hÕZA
µÓ¿qÿ=şhÚÜ6á†ùbzîî8Ù$’;0ŸÏ~Nén?±ßÍÁÄº~Ã (Y3Ó¤kRÑ9%®šîôÑÛ}±°¶ÑÍ·¬§àõ$ağ)ÍŞ•Ìà,¹òµm…Ÿà²Gôw'æ+ŒÃNŸ¡ªs«|ÿ	‚™Òr¤(‹™86AËÃßPÊ/âï™šé´¨ÃFõ¥{iJcå Œ›Œyò3Ğ•=PãÄ šÃÃ,ªá#FÊV…S–(deJq£–ûÌßvÛ<Ş¾í]Q=2óSµydÜéÑ”/lnC÷ôÃ6kWâßÎS÷·Ö^™Üoß,Ñ‹›&,bŞw@Ôz{lüRäÙ'û@FtaaŒM;^ø½•¦‘¾ìyhNPMÉÛ(²×§eí»,zaÁİ(„H²Û·Ñ/3İ›4œiİ_zle×ò=OZA:_8ò°CÙéÑrÔŒ–şÅ¼6Äì!Êjéi*(HŸÜKø+ÿ©¹Nm|-äPX¥.Xèë.VwäçŠ\‘áÊZŞ¾‘Ôı­šÔ&„÷‡kÍI·›•çg¼Y£¦d5î
èUKÉĞ\¥÷ÑÅp€Ó(.œ}TyÉ%Ç(</^Äìç”Â¬YØûŞ M€Í†2:¶ğ`/ÆÑ—¥z ãÀpiŸ)Z™*¦ßßypğcBòiKhóö°¾oPğ¶î‚q¯™èÉîcH?Pãó¡>^É3RsÇ.ìá™Î:äŠ‰JWÚª]Ú?wÀi½Rt…œîbŸÖrBñ’Á‰8DH?şHM§t$d´ÿ‹`õë4|÷©~USzğP83Éû¬Üˆ®}HÙ9^(İQ ¸Ê¿VgÖ—YÅg ´Û“Ú]gGyîó· õ#É?C”[½¿¹„É§¶B*34oĞBİ°dR´Cêß“Ë„ B‰V‘~ûC™æ=Ñcæ­DØ’S¶(¡û.æ‡’şßyó<áp¿U·-„nÑ·M%{ËÁ„Ø·GnDcOãKÊËŒ•7âØıàZP¥âæÙğIPPÂ) “Æ£H›±J0µASoU"ÄL0`ä8ÙEÚ	6QËcé°âĞÛÒ£rû©;÷Å‡H¸œïÏ¡ÿ?«“	ò h¹Œü«v{;¸øv·ò\&×¹”
û	„™ıw‹ı³6^à­Ú¦ e„û³ÅDş¬•ni.ÜT!üPÖÅ@%ãrÒ=WñK¤øärV$2îCOzÿŠıID’„µ5$ğµ,’¡²m-Ú¾^rÈößÀ] ø¦É%æ² „
¥eÃÏÓƒóSpf¡è	ÚñÂÆú·´˜:eÂX­‘¤ÀÕ¬ÜªkÉóã(³bQ(\ba×æ'ÚXªaGÒ—¹,u4Ä"U>‚’S·»ä¤ªŠ2üÛK´ˆËPÉòê©§ÌçÊ$éİàò¸-È[™ñ½/¨¢¡°ÄÈ…~1v¼Õ‰À3YƒØLĞÌA;‰6HzIhËÕ±†'§TQÖÇ£—d†¬zç¯¼)áNìÍ[\"©Ügõ.e§­àR“l;<'Ù•Ş°U!Û>Y&#³ù ”©¬0J…	Étı£„/ny”wŸcå=òûÈëßš;<@ùÊyIõİw¬'êç}'ÜÔ‡#£êœK5¨±'×ÏhŸ8ò8é‘ì$´oòxç0ï‚ùêjŞ¥ÛäpÚ=™M‹¸*×h¿$û½Àk)¦g±ŸK°İ†œš
ÿhä,HÙºra«ÛK{¾OIøQU‰ –›oè+L‚P-1à;°ç*<ÈY‹äpôÍH°Å ™59 ËeqÊXì°Å’Ò÷µ£a9!é“õF§9h“táŸR Ô),pë1ù”ˆUç`¤ÕL4MàÌq^T”Ål‘Ş¥WÛ&£Zº]È¤‡¢HŞXmÅJŸKvS«úôPÁ€Ò´™vºw2>âPè#P¶ŸB€İÉ‡ÊB—„i)ä8½Ôëõ‚´„^c`ËÌM\ÍhÚüğñÀg…º~BfÓg3l/‰òÁÓ÷Óõì¶Û†/îÀn³â2n²¯º/İg»Şİ2Â¶¯¸Õíş»Œp'w/¿˜å Â02ó}u©zŸ¼ËŞĞ±~@IêïõÒ0©{C§K}?,xFáÉ¥ÅzƒL[åÉç‚J!İÊë×tÂìÎÔàl#f4.¶¯ºØ½üf7E¬¶Öp¤Æ0ê4m¯\:Ï¡#Ï*œKı&<§ºÊ²«YâDÎt‚`Şy¼×fë(­^âÕ€E±|ÕhnÎÿ\½Vy²/ù”Ú<€4£È0y*_Kş6ä¶„ª—¼iÙmê“R«{­´VBùœùÂ±ÎÜ9šWhT£»'NxQZîEB©’/ªGĞ}ïPÀNÌ	^e¡_?3~Váâ‹­ÈÜìÒ™Ô¸æ$ÉZ°#˜ÅW÷PÊÙ²í h®X¶w‰|«ÿÉBdß{;ØO>Î:yß½š-·<pR„¯¿ùYHÆ^ÆNhæ™}³+Fø4Yú§ªÁ¸rw¬‹Oc 'mÏ™±íe÷y¢óYç­8ØáQssã·à4Ú>={©»Şá‹L"æ}€XÈıÍî¬Ü>‚€0hr"4ó vŒ˜„¢Jæ¼rÈ7¨“ú‹mÊ%ÿ¤İ7'óÌXM…
a½ ­`~{Ñ’C‘ÔMÇÅ\<x¦=1À‰-=ºoÿrNu¡8t?3A‹½©®TWìÚİK.}œ_¡*YW=Û¶H áÁ–õ‘¹–@bLŠÃ•f—:O\ğ©Ë¶L7\åŒå´ÛÛ5Â,‚hK ¥Ítë$ÂÈÒ¹[lÇS“ÊÛEí‘÷*z x¡ÅHİ"ûø¸œ/é™¥`Ê¨\é›»„¸ª›m¥‰òœ‡&“"ª_øˆ`»â<êÛ ·õŒ¦"÷Şœ¼TC«˜6Mğ}jùİ›Å¥C*¯ñ2¶JªâƒëÖeê-†pGHnÉCDg:»€âÑÉc|<6îQÈ¹##ê‹[ïsè—
öO]"å—o&¦‘5; ã:4ë“˜Ş½Ç­SšèßMê¹¹«V@|	Éa?Û#ö+	Á8?óı;`CTb,lg‡ÉÜÄ†@‹.ì£Rfè²oq$cA«ˆ+¼¹&§x_Al˜ôé€ù0HÜ	5­Ø²Ø¤n!“lÇØN^4z.ÑíŸ"«y©›Î›•O§SêõmÑğAûKõ("ğú;o½½ÙÖÌÇ[æğŞu“.e£1XiEDIpàä•ÂÒ!½´G·sœ½âi½j÷ÁD;°#ÍüZN/qÚJ9…Á,jUxDÕPiÊZ¨sqRâ`uôüeqC•-É'!R-òzïÂAƒ%	Ù-*ıŸ½íë/³Mä7nÒoàQq,®2ø¦W;c5d5„³KGas¶:i[C€{1´ËØñ„"±9~vœ¡’¥¤O#‰¤’¢ˆpå¦ÄwF"Híÿ¼éD/:œRÒ´3h×0/,•UúHâÍ\i„M«ùão9\¥¨¤–2Û†Ã£9şÊz«Nò J¤2W¶HUçx]M¥8àŸUh]I£¬9&İ”úS¡Xô7K,r§Ô¹Ú^ÉQ>t*À­,i†¶}$­Ùï'j2Ä|Èº1ì%©ö‰7RÅK«éCÕrdçÏ×ŞŠšúR³ïóär\£'rT;Ù¯¨âÀ¢ËuíÍ—Ã§8±¡bæpL•ªµ:&•70°#ƒäO¾[rÈÆ.u˜<š¾zµîºëŸ¤ù£ùìÉKx¿d§uY0âÙ·@Wz°÷1¸*.G¨‹1‡ĞSŸ&ãhò¦¦0ÍÙ¤Ù
ãGû z`yÊjĞğâ‘±x×Ã}‘óÑ‘ÈË¤Æù:®€W~¹îÉ¥ó $•ï^¾Î8cş“/ï°ƒ¿\–]˜éæøzfËr­);¶´	V6Œ±¬X³vÌª#cBè¦¡E2%7__]u"–ø¹oıKE¸Zê=:¨ÂîRbâ¬^ÍĞú­rÕnDo[æ%.2ÓŞH.~“Û%SP-kò|ÙI™,~(%¤ÄĞÅm`Õ<ŞñÈí”ôyW¬~	ÑeÖôh,²ddš¥€ß•qW¡µË‰›jÍÆºœRö?&`ît!©˜D[Ùİ‹¼~1jâÎ|F¶Ä_y–ÊÁŞàŞú,Ë©¹«Ó
!zékˆË‘³k“ÿ<G ‹ò¿Ì'²s`éRH¹í5ndáM°”8ß‰\e<@©D óEbè_×Ò¿©ãÛ„÷”wR¨¢³Æ¤j ÂmäíŸY; Z´q¬ûn8ÇÇH2ÀVİ^rê”
Ugsçb…#†x³}ÏU7÷Eè&óPK¾wïå×—U5ëIAÊDzlp\AâœK§ˆgî”Û°ûHlR'ššrù;R+EYWìÖıÅ~_37àk^è3 \HÂÿyu9«H/†ª#ÿ¡•ºuÕ!AKĞÑ##æËÉƒòÍøşpOî¢^bøB’¦D®øF*®ÍŠßQÑaäbôHÚãÄû7Ø›£~jz2º27¯{ùŞ6EPÑô?c´bd•ö3·o¯ˆ_~©7%[«_ªÀ’‚Ëf²Ã%5Ö‹§°'o(Æa5ÅSgÂ LĞ#UÖ¯L`µÀî¶Óè>ĞãÉBÁqBÍ”éÇûöj²Çàã[%WÊÍªıš¤öKDÊpì$íEĞ:¦Cùû§Ánõ:¶üÑ©xƒ3?@açç%ORÅoŸ·à¦¶\â~Í²ôáø¼oEùMÀÌ<o[ÀaVò¸'	/–ôõ­í3ä6eæâí…cjWŒ¿÷¬[d±ìÙ.Ä½²dÈÁÓ.1ê<yTRR~Ë{Ûi!€1$èã°~}zŸá•0ûDoÁ>î/×“Ù'<Ë‰8_—ŞZ„|b¦r¬h¶Ç³Wbd¥ùn«|]ï|dÈHY_¾êÏv½SF3µbóc‚€Ô o–ˆÌşOùÃªôì‡;ô/Ç§‰òR"à\<KH‹óÓøi ğf}jÇ›«¿.½3~H¬‡ÙÅP¢F'Mù…ùìeí°Guù7¤Á«^©.ÌÆ» ´W3\ÉÆ‰?÷;EK	+Dö&·ñùâÓÆ¡İKÛĞƒâ4gã…]ÿÊP»Qú7÷}ìå‹%sœñZğòò›35IdRe×âóèú^QíÔÈ™îKîH¢ßAE¼ÇS³xí¿í‰Ş/Â39¨2•´Š´ú¶íUãn<rÍ‡7[‡l…8?@KÉ¿í°
LZ»èÒÒ½"bÜUs¨?ÈÎ›Ït"ÉêÑdV`ößØ¯èj•ƒ£IZ•2ä¸!"ïo{FíûFßâ©i,K±[Á§Ïe%©­íì|sëMÄÅ»}ØgëÂ'ôù‰gXUn¿Ô”õºON3Å­Ô’Åú8Œ§u !=›ÆHÃçUK‚qn/è4nÒ4{Òi´Ò”"u@B)œÍÊŸ-í¹
KÉMíÉ¿O'ëÙğÛ3¸ÁÒW+Ôrv^Ôóƒ¸³sKÇR“Æ¥oÒŞ©"i3Ê[Ùbh¿hó!ßA¸´>X{y«¡øøvAG|_\Úöô2{t:\5x„ËäQœóªGb/
xÀ ˆLŞ°ˆuä‰O¦†÷ÓÅáh1(j»­¼X¾LV½C!¨÷4ˆ¤’•±ûY\ìBylù¿½ØãIÕà³;â‹˜Y`wéU‰gNbŞGèDp~åãàl…ÚÒâ´4'ª{ññşLÓ^¢’JMeq
ãE`Šì¦7§»°sw´$	İ®0‰IP¼Ã»¥`šâš›­$l<§¬ª”ôŸª	<BWUkk:ŠgÃ„y`ÁUø!ŒìjeÃæ@ÍÆœÎâÙ•*Öã,E¯(²ªRR¸×şa“è!Ÿ2R>qlÙŠ Òph•Š2¾ ?½xHÓnùúO;z˜ŒTy!åÏåº–µ/‡ÚÔ²!è“¨'õ{ä¢ğ×ía˜wÛl˜—ÿI4ät‡S!ÛÍŒÿ0„ò²‘n
¡¿Lyßé2§°:©r?3¾ÀBí»³ªÄÊ2ô×!ñ $½)}¢ª­3¾“O]¬~¤æ¢êØÎ’g{ÿL›vIîìJˆe|×HI¹zUû/‰
OG—ß"Ë3Ä<Ölè_\%
yÊô<ıåedïà
éx¤é\º¡hUú\Û²êŠ¢,`øñÎÛ­Qü@3›Kó¯Ÿ]gËxÅ¶Ï'úÒ ÁªgÒÅÌ7"'*4£®è±o‡ÕxAû@‹ÁëÏ;1áš¨4ã:7E÷İ%Xä€ô‡VhØVÆ$c%"!I¾€œşÊ6S¹¨ör)bÕ‘èQ<Å´Ï˜Ìî/ê%äª`=jë<ì‹@ÛˆúJ±ï/kËDÆıÿÁrŸ¬§Gdˆ>>’NÈBİ´2ÉTÃD¬S)Ê@œ:ÔD5ºŞéD©¦lB^Ë@h1"…Ú´ï›¡;'1§J_¶¯í¾=Èï’'8Mh¡‰NFé=Åƒ
NQGßuø~éÛZ×‹ô³àL";…›ü¦Qz|j„gİ%¹Ún†¹@M/¯³l$q ï}¬’¾æ?>øÃ‰¯#C_<Šh‚Í]I—£òŸ/IëöµÁ,rkeç,Æ‚.Ûö
-e¶p‡¼_t<sù&Ñ€¸ˆšÆXÌîèŸ££O³Š.ıñÛ5İ}É N :äıa*¡á‚Æ»ı„´=Ô a<¬œ¥nû·³›	wK¬{-ô±¹LÙÜ×Ò@J¦»Œãi†šŞŠâ¨µ“A³dÉ'ÿ\0^ˆ)h%U¾ÉB¯·ßjî¹É€n„ÿDáÆq ©Ğİ±{ ”ÙƒúL™¦OÃ~t³äy“àeÜ)¿”Îİ·7_J¨xe\«³0Ï¥~fèÊPgç’‹1±×R=—i‘­HPPup>Èæa­ÃÏ¯šBß[,&BndvÙ#¤Æ‡*v!­ôü2ı…£ı)…Ô=Ş“ÁI¯CåÛ|“•IŒ*%‰øØLÆE1š¥İ±7h’Ö#¸£@Ité¸/ÅşvŸ¶!Œz
•˜@İµõö?@J ¨x¾Â¿+¯hĞ"Ò7şÜŒ+òµ¬ÉßÏ Ÿê².Ÿ'Ê÷i­ù›Á%lôô}EôÖ OX#»‰i@A‡€ua0ê‡,©t@ÂX"Ï´g’²´XËë`!zéLŒŸàÕÉ¦º‹~»PÿØü Ñ‰˜A/Kp—ü={©ï¾9Ã`î«“¸ù¸º_?£Mßº,C$7¬ÈŞŸk–ŞÔcS€‘Ï¯¨$ÿ¼¯"»·–”„uv›Şç†?}Ú:VÚ"W‘—‘!+Se·€%Ë

6 JïÏ®¼ÛYŸ
D{)C,\éWß?,äQl‚©ø!÷M”ùÕˆÂ÷3h‘ˆXŒ
>õØŒ±µ¡©^,M¬ºg-q\»©âö0ÉVtš%!µ×“KVG›2×˜fóq3Š .›Bƒpì°Ë!ô†UBŠA}IÌĞŸÉ+õ“'­Kšè|¾i$ §sŒßÛ9$ä*œ‰T?Z‚Ş¶yqäŞ¶b¨‰¡!¸n§}PA/›N)mÿO@içøŒÖP+Óââ¾‘ØÿGdÃlfç«ÌQff™Ä¬<B—ĞF˜{±{Ò"9æ}ü±?y4(pÌÂ„¨FÂÅà˜GÂ±üsx«^æVu ºÌ§
cû{i†'^d\Ñş¦=äd”LFo†BY§ûsIÔMÂ¨Xq†«g'¶ÿe*ÉrşŞäÆh­¼|}Æ5ù}úíô"€êpJ=¼::R†‘ßæwP¸ñ/cĞy>+¯ˆz¤î….úÔÊcıÇƒLËYMVÖô7dÉ5ÿ1GàÅşš_ä/Å¬}y/.ùÛRÈ$f‘ìt„Dÿû17lÈœŞB›9¤*é5-‹ãÃ·¢/VãM±«0kìŸSßIõp–1ñ§²Â”£t>ĞŠã XøÈqÅ³µ‰…p/ï÷Òbb\6±ê1M´®cú|‰,ë‘­/ÿ,å^„6ûï\>}t@ÏnKR7ÅÉ®²%Ğ6¸B3>ù7!9,’Œ·X„|ü¹­š!	s¾ »1âS~9¶.Ç0ØŒC£@WT3»æ‡tEèñ’9½‚Äp%s}yap·¶äÿ´VA®ì EqZØ|äĞ€}€–ÑÀ>ñğ¾Ú»á¢n	f®it¤şÕü<‰Næ„°Í²ÛV—•áéÄÙu°`ğ 5H]E Ôbí}a„’}n~ıK2’"Üßq,°ŸG|Ô'ë_7$pşEÀ’T3@¿fŠWï¼ÃIâ¶ñyİl‚0–‚çä®WÜ–ézP•¼°ÅáX¨w—ƒë¾>-,éÅ`£ÁÜ„-V £G°¾*ÅCÔ±¼(+=*Ëd†Õ»öĞ¦]…×wòÅÅ$Q¢Gsš£ŠÓyxã¥.ÀEàº	ÿ>•@2V7¡é“uµ~¯)ÚútñnaçÎ}5_(y-áFüçy\JÁ~S¨´ûìÓ•­ĞÜ›Rş_¼Fï©Æµ¹2^¬kŠõ?FåĞ)ÉŒÌ‚®4ñÛÂç{Ü·+èü_{%Š3!Iÿ[‡@qC¤Ù^2øE°,4(RÓ¢^½š×äâÍ£­º´ÿ$xc„¯{ÚîFğÇĞ—`LdR2®t~ÈB_Åª;#W_¹a2¬iÕÙp(}Èa¦Òßœ5ÁZ5§«ZÊ¤ËàF@r…()ƒ¿Kß1¯?ò/+»ñõHç¶`>©‚'DÈBJl…ëÀÛÖm~¸ĞzÃ_“†¨U†s®€ßZ¡¡}	¸cÃgòÂ¨%a–(NÇÖ 'dEŞ?NU4L]YÀ©LÎ0N¤ÁFî)‚ ê¶xX_›LØ6A.t•ènùO¼ÇU»’z„Òõ>İ÷ÿ/yz£=øâŒ—¶¡kØÖ zÿuKK+X*²ìçá}ê¹,gJÌÕ£3P–¾„·ËÄEíÆV²˜R8†ËAŠêà»ï(D.ùmf¥oVbı$îú]Öw•Ï|BDX!’q•Ó-¬Í‰á™hrÕ•_­¸ãrRØ!Ÿ‰ÙM)h@$;eqÒÿ´†,Ç%×r•h—£§#Û5jNÜ“\İ&%¼¶Ùåzµ"ßòÍõôu.xî.ÓÀ°`Ê?"8ó¤õÎê0p&·Ú½Tc­ú¯mù¦ú8¸lÅı,
ä=/ ÖB3¢G/ÂuˆóèÑ×ï/_ì‚ªÜÄM¸Jy¬f*úâ‘¾œÓÊºWR[¸ ëî\o*êóVs8CÁõ>ÔúxDèNŒ‡È6%ë„æ(«zÎçÒ<©ÍêÃkÕ’sDªV^åÙH´6½æ-E28î­ŒÑã­ÈuÕ©ì½G¦™É¬…cJ¨³äÄXº#kõ²£XoL¤”%.ÂÎu{!-ÛKo);¢µ|HG†Óe¢Zu-ªwèøô‰;ıö­Õå†ÈñeİÖÜ­*´¢´œÛç™öh…O@òœH²ÆƒÀ
–NÑÔwá#9¿_Ô[›É0•#Uìù_3¼%ú/·*ŞJhs<¯¥,2”Û<Ö¡IØUÒî ˆ¯ÚÇFÇÙ€J"ÜúàÅnÑD£÷âÁÑk¦¥J%ò®¾¸l
æ¤~ØÇ[bôk…ëú¾š—[·óÑ@ŞVÏ=Gr<ÖUÜS
îÜÚï”wã¤öóÛFùiV
Ëù2;dC¯OÃ¸Èe.çÙxKÎŞÜl´J†f„8ç@=ˆ­¯¢lyTÅ%ÓÒ~KuC±¬Ûÿ“ÿÒgËökœí>*2‰>ØkRRI¾µ+SZÁrLş-İU…Y]ˆÓe`O$Æ‰ŞÈYXV•uç8õa6Œy¶ıjÜ®”­nPä
§g?hgÀ7§zbT30(-¤RÊ¡í´ÑPË­PNø “1sZÁ@ŞÒ{ãã‡EšAß˜VØ®EZÑè_xzí2z•îø`ÕûÜäÊ8°´§G"”[¡˜ø£¹£K —
ı~>¢-ì©*lÈr¥ŒaZì£5JÌİ¸íÀ¶‹M¹š¹@Å\!elóÁ^0«nZŸzzdÕfRî´qk”²)”€1•>ÑŸ0ÛİøµĞƒ´òµÙ¨Z{ğ'şXá>]É­’­/d÷˜W«Ö¶7³ğ=ğË¢?­¤B1k‡¢˜Mhó ûa:©0"‹ÎHAyá't0d ¬~JÙŠPOj3ëŠŒÕx—dkÌSsP÷‹,W'ÄæëJğ›^q16YÄâ¥F‡Ök<ÙD„öt-zå¯n¾o0İ/Ûí£œ^b—èó¦pKŒØ¿Åüå§î%ÆÓ§…íFª¸Åòjò¿Ì ¨¡(}Å½-èk†<…}…İ)ÏÈ²?)"è
êˆ5_˜ª’uG õ:-2ås¼ÈàKUæÑÉ¯ìŸ-o4ğ@¬h‡Ò
\Õéd<ÆŒ$‘ÎÁO*¨f ïr—Òy¸6N¨ßê¼Ã}-³œ¿ı~]ÅA§£u¼š]ûÄ¸­¶#¤Hûâeß®äérĞrş“d/-Ê…áè>K6Ÿ¸
‹¥¹	©CÈOéù6?D…ÚÏğìºğ”ş†ƒ1Nú›'åµJè'a[øw®GÚIë N«ÃÏc£zCiE®øà2IåÖä‡TÔ0„XaTc|µüÂKØbşp* ^İ‡«İ„#ÕK	èŸ½'Õv™¦¡€ÑúÅ˜kQÆfDäXü€Èª2—Ö j9ÄŸ<é®('Nk¶ã’rk6æî‚·S“V}‹n¡?SÎÑó(q?9¢¶P
¡>@y…(ZâNåpÛRæ¥ãšó£a˜!YĞyİİ×LÓW+5F7û*¶ˆ2^è™Vµ‘Ü4(¹ĞPŠúİìgd@‚­&ŞoX«%*€QŠW6Te=&v¬šÚrè½¨Íã¢§²œ~÷:ŞcQÓF¢Ğ…RR¯OÀ„AØ{ÎXí8ÜgÎiM½p<òüwG;ºùT>èRåë¯ø#ÊgtIüœ†åM¡^G|R|q]MÖûÚ?£‰;m¸#&¦Ñ•ÚÍ‘Òiqö„ıw=¯å-Ü¬†p
Ä"~cñMdµ6ŸÆZŒzİlÉ™­eóÇõ®Œšç,¥(–ïmc»¾*ÚÛHã9o¿SªÙ"ÆÌ¸d$Éæ9»&v¬énop #•·-Ïb=ıUyg¥¼Ÿ0.è	“KÒ) 	;!åÊDÓØÄâe¥d@à^+b‹?›[¤{V1ş=Ug¶z—Ç&gõ7.•y»/A;“QäŸ_èîûİ¾2î;òdîô›Pç’uæcKÈàk<ú;áıÏÊì)DÛw•Ït£}2­Ü$B'WÑ%¿Úwˆñx–\Ò’»4˜–í§·Õ|‘Ñáš®:ªÆ§æ/#çº„ÿn…E&ÿ¯ƒîµŞWü°–'G<Å”¼ú©ak°í!;ğQs[Åº²:ÉW W?U&4[_hl°ŠûP£&]Rå%ép9¯w³b}¿£ñ:Ç`EM9Uq‹©	Ä4šb(G™¡§û`«ğ0¼„kéˆãíÙ; F*æÀ·±l¼GÄnwJqßĞøp³Ã¼ñEésRš Ok1GtŠéfj‰ğsÈ˜‡Q2"Ç„ÎŠ(%ÉæPL]ÿĞÙ†a˜Š Û2o`Ö¿&S²ÿÃAJ“;j§k%aòÊÇ•:A¾wö]ÿ„
—2®³Z5¤_ÃQôÛ ?"Rn™°z³î'Ø1ü¼^é²ƒlíªôR.pè;ø!Š©‚æX{Y+3mRåa@[¼
—9ã™£º\Ğ¼ûÉ>~·V¡gÙ,}ï"¿‘¡Ä˜pìNŞ†‹ôvZdÁC.•%;ã{Œã*¬ºŒƒÇ¶g¥2Û¥GåØÇWHŠHy8G¶‘jÓŠîTcg%N~E´zB<C ÌÛñàÔU˜ş§²^¡X¼ò#â™Ñ(»ßĞ„Ö“dfò­¥–²@p¡¤}Gü–›ÓšIŒ¢Rñ¾&ÔW7à±õôm¶4	‡°°¡Š ôêÉı25}çqLLwª·èN‹yg(Æ6xè?Ù5˜’ïl9–¨Ø(ZtÓNY¥Ëy½‡¸‚FÖcÆ“ƒXú7»4æa÷kâ˜HXCŒ×ìN XÎB DKíÓB8*IkµîV§aÈ¾Ò"Pÿs–€Ä#çqÚkÃAËÍnûd±[P}Pğ½Ì‘
şLÅSŸêÌ9Öuï|ü°ÕqTÚy¢]R=#2şô÷“W›µ‹oÃşìÉAı]˜ö=?´ÿñ]0†ğC`ø&‹(èàÑæ8•ÙyĞÈ¼[|‚ì;¹›MoVwYbí”'
Fë…¬LWÍìşôøÏÄ
Àk™Ï=Ï„Z:´uŠò·sdzxQ}uL¸*®ÇcK¼äPºUÀmqwßúêš­esÍï¬5-÷dÀ„>¬ğÎ§lÀÍ„ÎÿàA^WO3³fòÃ~ÙådCË8bw‰<œPÕy=Ï­/»°s÷;¨ª%ÖãáŠsp†`¯4™¬:ê% Óuññ…ÂÏŒZNr{ÒgÃaİÆXœğoÊE±nv•j©uphÂ­+=ö8Q××íÏ]Ã‰àŒp<ˆ²ËİkPÆ#=L1ïµ(,S«Zùzçnµ¢M‹sô7›2¶Se¢a´8vgM¾)í•ãû@â/ğ\xÀ7åtzÕİp3J LÆ êô˜*«•’ÌÔ3…œMƒS¦ãƒU,Yq1*_ ›3ö³)0L‘'_³ŞDÜ8¿ÖÑœÙ‚!üÛ\%^µF±üm4°ˆ2Ş˜¦¨ÚĞ|zİ4kÈŞPG‘W¾;E Â’,è…5¤ô!ìQEñ(‘!ŠÎòpIiš¨’ÕCèÄÁœËd™å»àı”a\á®@¡46ş&êûZ :İ¤Æ%qæã»ıîş­ÌeíjÉ"‚f¤©¾˜ª‹™uBçÉîmtü ğ&]¼!Ü•ÇäÁs€7Bª'gÕ›WFWå«/™ö_ğ{y†'>`°®×:/úÖWÏ3.æ4ƒ‘:<¾3ıŠõä1ˆ‰k§¯5µâ„eŞT*MíFfT…½İç»ÅO;ƒèDC3Ô¹Ğ­•öK2¨@İ¸*ê²çáO…%±*…eJ]–t‚¼†}tï,ÂŸ‘„]ßø)ŠÖ˜œœæë2;Ÿ}JA«¹‡¤¯‚OÜ$İP“r}|ñãÅ$Àâ"$Óõbe’<o½ÙX’¢oce#)Æ¦x8Œ_äuN·øF…J‘	34r¸N²‰Â ®tUÔ~«³U-ø9ĞÃªˆŸ	n ¦İ•R0.(¿Øã{e£xc’8ÉO½l\ÚóŒ›aL d×Ù±ÿÎ§ŸG:áGä”ì©eıc3D3¸5î1ÊÁ†ß’K7Æ™sS#sV  mı @-¿_Cø‡·dŒGÖ³¡!J:ˆ5.
†=gX8İ·M¹äÇ.Öƒ£ŠKŸ±}‹Í3SÌ%Uß(jëÅ<½«!öæ:y·zbRX8şÕFmV°!4Gî¦Ş‹Ã‡üW‰¯h¯xCË²†¾•‘¨œ?ñ+÷b`zÎp·.ès¼ögJ¦;Ì7Ñ{#óìË¼-/Ó»’ßÏu|Ã_	ÂÛu¨™jş9T F8èxâ~<¶:U‚ÅxÿãF$˜táNûÁK&°ØÆEE«£ˆrf­¿–ç¨¾¦ÈWFPz®œ¥ôfN¤6ïôê*vå1ÉİDğ»è=§|8ªw]/`ŒFº“ƒïjÛ®é± -Û£”k”?óM/‹OôCöSQÖÃ²ú5ÎíO2j-ç·QK¯ˆnÎ::[§ ¾P°@ı7<Qİ|Ñ5G{©W˜‡ºàÿÉÚ.‘ÛŞÉ
w1’;„'*?çmU%XØ!5„w¼B0byîGEÚÛe£lbj\é2X1Ÿ…¥€õ."ì)Í˜‚œI/¹1ÏTÖw>¹¡‚H€äUäìÀ½?¬-o;}fWÏ³^„Oó/Õ×¢èczÁ$Ò¾[" äêµwªç©Ä¹-‘««÷eÏË½²ŒC"øI³¬—Vãè3”ı­®í· ß
èÓ¶sEµ×u›bewä&DÅÈªıÛÄøõÚW4Q-Ü–13ö:¬—åZfóßVp²W¢Çmfµáç”19ø®ßöÁ'öÀÄtùÙoMbûñLâ¥dŞ–Õ™¬„~†WÌµ¸ÎE][”–z~€d·«^†2f‚Ág:ŒH]¬4‰Øò249¸³çØÆ·Ùd‰ÀÑ‰q¬UÌ¾—¢\O`;Îp}ş^`çIMÀ¦NâYKkĞü8iØôuNöXÕÏaÆ\q_c†ómºƒñïm­·°z]‡ºÆg«¶)sÕxgLG’/ó#Yå2î7Š›®æ± Ï»+çQ ¾˜>à4Zr†İNÒ¨âË’'1›3ÂOnE	ÚĞn¶¾ »×öÄÂU%…âPA'›Ovg85<J,}™äö°VÆï-®XBöÇ¨tÀû#DùLaÿ¤ƒù;ÒiQË–rnë÷{™’mGt” ªMçÊpiz%8ãLìúf`a>”.™9¿Ka‘ñ~‹kÚ"aıgúø
7Öğ•¼™ù8òÒv´ûàrnõ‡<0ø•ÆÒAÉ§Ì¤^ÀC»w^äIN9~µb°N âtBì@Ô1»Ê£H¡—¨>Şµµ?Ù«ßûfp©¸/, ê°U²ü³8EagÕM$ƒ²oğü5- —MœsXhõéò;·¸¢!.Ø”<w<9Î˜5Ğ‹v¢Ì¸™FWÜ½,V’ıİäçß‘¦+1‡Åè°Sg^¦eQ
-’ß…Ï©&ı ï¢As—ğ\a˜«ÈÕ(Ôrß	NrHVŒ=-‰¬Ç}72«ÿa1’º!â£CE¢â¯B¼a+T^Ôp’ªüÍª…ša„Ö™NĞ„ªtJĞéb{â}Äæ7®×ƒYß¿¼u¥´ÁL¾__ªú ÅÏ«ĞÍ#OŠGiwÒ*	l}ÁºyóÕÈ¢óv›ùóİ!m“,ª%ğf8(õqc¯âÆdåv)–fŞÆa›>×}¡Ï«°1 [mÓµ¹ˆ7µ3f‘Z=¯(\`Ú±†%¦^â0ˆQÑ}­œâ§¶ˆîÊ†ÔÅn)„vuX?Ûí>í–0_.ÃC¥M<9ÚÀ\¿+wËĞ«Â”®Btƒ‡4b‚…bØó@ÑÀVÄ‰>Ã+·9¢iw°!Pw6š%§}ÿ y{vtØdyhq¿öC¼¦·±2lOıqèå ò–ştÌŸ¸¥ë9QFfMtZô…îKu³(æ¢~÷_– 5nA"êÙMz¸DD¨ü_ü_{M<ÁA{$æ=7íÅºSJ…çTiâŞ*píçiåÃÇ{k2˜yô²=Öæv
¡0Û%ƒTGÿ^Ø'§\€EÕ‰İ†T©@ˆÚôç]%D,Ü€Fjæ œ»<B~˜°*Á—vÇÎ°»YÚõxbiK±£qj„îd)!‚“í}„’(R{6œî„)÷Ab—ù8Á%+§ùî»JÇ¨yi £ì±ÎâK1Ä	sU:Ö°Á7½Ô- ,½ã5„×s2ú)‡0ƒç˜oàˆ·ÿødô.óüê°9r,Oµä>¤ Ÿù}µ7IÛfÎHóò^;”êÕXï²W±¿RLÒ)ä²ì&Š&òË· øÒ@Ï§›ˆoƒ»µ@%ÃĞËz$TtÓŒ÷†³©îïX¦™ ‹v¿4­Ï7’Yâkg›é>3iI¼InSéäB”½ğÂt®Õb(¥®¥E=E,"öàT´¼EÑ÷Òæä(lx.› Ûb59•šıE‰ª6-}¼àßöò†_¹úşn,qÉRÈé¤Á4rhH…~ß~âÔ¯šYñê»Guƒ¶Q0àâ\;T)© TÁ^è8¥Û•¾Í›‚_³½ °XI³îPª›¿d7iÃ€Â©º;¾°­EúÓÔ°ìt•óØ‚ÙÎ×aJ˜>QşNÅø¥½P<(6OÛrÍ¨µj÷5;ê˜ÃIzê¥_€C„€ÌìÕ×°ˆnÃß|³®şı‡ÉFAcÇ!"É!¦çömdQ7–yáßÁJ×fûçq”ùLƒ-¹‚Ëèİs­ß:’Ğ¦ƒO£Ÿù†êyáZ[@¡\áŠĞ¿Ò¥‚<"s~'óÉÛ'j~=OÿÜéRÒ)ßTÜdÖL÷ÄûÊ!eú½fqzÍ¬Â?‘±})€†¦‹áúÏ¡^v×ÓGM¤YÄG¡šZ­°ï-á˜á3°«£Ä>Ah˜g(¿„\É	%uRíóÁ¿Ut2:›<Áç¤ÌƒÓÒŒĞdÿWÎÁ¶LKX]FÁk¡ÙÎñJ°´]WàXÀ5¹÷ï¹\İ‚£Áµ›Ÿ}ãø„Ñ²à«»!ıoN½.Ú!@oe»4ş­ğ*y£X¢¡—;Én^¡Éİõ‰…<:¶UÍ–n¤ã:YüTÆñ•RcÙ1ä9oÖ5e—z¢’ÍÅk2R@V[:èW_ó½ÿ…I¿~i½Ux·=ï¡Ò˜:“Ñ¼DdII8ª—àë©¾¾ÏÇx1—ÄüÆ©‰pšıŞ—P†¸!jC¦ğBLÙ*¦õ `u¥t¨wÉ1hØ*æ‚†Öü	˜nÖc1&á„a"Á³ìãàñºf¼L_…SM ç)$¢›¾‡7Eñk%ò¼HI7,”ì®<LL­DÜ<j0úôíßC·ïÒÈ©1š7O]6ql âhâšÃ‘Œ÷Æ•fúP©ƒÏàã
¦Aıfˆ<~ƒ}£ÿòh¡Şä×E_Ùñ›{áx›&Ú7
1Ìw‚¶˜nì2ú'Î?ëq§4„}«0a~8ó¦ÍÅİ–nÃQJóÔîQûç åj2ïõàÚÅ·¿™²ôPŠn­°Ü#Üc_U„/Û0eVÀ4WÆØÑüÌ\Z4Hh·™ä¬-Ñ±_ª¨MZÔ=‹N#¬GA=‰nó1N—L ÖèıÏ« Ám¯á½×7=TAÃÉ4Jç¥—å*ÇÙ"™rtÃ¯=áĞË4·WL®-åtpĞcê>„ŸK.\o}ccrñ¨ÕQ*S'µyÑ˜×®Ìú{ÓÚ°œ©A™½J8y’uiL³ÜíÇ>
Îô\e|ÖMF[˜·M]¯®¼¤-ÆÂ¦Ğ‹îMVÒOjã]!n™ó»ânµ
ª¼Ç®WW…I'µUçôjª8ŠâoG²Ô~T•-Îª¾lGã„Ä‡wGÈiÂ&ıFs½¶Š§ª%ÄU¡´”7Yk=QÍ­ËÓQ‚óƒŒPK_ÉÏ¸Äoü HòçãØ§r°®)÷ı€ÃM’ˆìı‰ıÓ;$ß©™;4²¢WY}ÜÕ\ßUÇ&Ó¨<İCYÚB©^„Šop¡uD.Ìf †œİ¥Ø9²Å !'ßìãŸ[³÷&u—Ïİ`E°v#ºÓ?‡ \©îåÖÑ«|nOÛã7›ƒºœ¡éwô·‹è†²16™d¦sBD¬ÑnÚÁ5v€ÿ“‰h»d—™‰Âv´½¨p¼šÀº`²áFDïÉÕÑ1ÄWpåx_×ÿëşª9],RíS)ÔÏ^©jÉprU+İ~x[í½ƒÓ×Y0	¹@~­]¤Sı„X£mpXşn•ö)Ü©ˆ¤']¦©d¬ú!O¤WÉg™ğ!‹¦IÀ¸êÔ5ÅS^
EÃ°é¬(næ6‡¬Ï”&ƒ¬6vÎ[ø$=T—êRŸ¬?†ñ¤u¡74Ö¾ÏfÏ3òÕç4²oûÍN²†IS$rlu²ÿ)G¢×FY{(‰‡@«md‹FÖ‹¶%¥£	 ¯ñ(ÎÑ£˜uÔŞPá½v¾ =Oİƒ¿êaPoP?»&’J‚NÚPØUä-â­åH8qqšİPØx+G'P*ÿ¬ˆ´òqï@Ÿêğ6[ò¬t6+Íğ{­l»U8ò¹cÓ~[âp(¡˜ÑrNNs6’ò¹áá0nëz¼¸R/¬üÉ*2şI…1•ìQ 4¤N‘í‘¢8B*–<»¹YÓ”+l ÷^Ú† ]m¶2¦GÆeŞ[­R¥RØuÕ¡:ì%ÀÏ%ÿù$	[wÚĞNÓ¹×€õÎ6éyü²*±ïq²r'1"UX\aú9W±¬€Á;-çV±
îÀ^rjşı¹8g¥óäT±„¡g\½bnõ+peŒ“T®ÅV)0å6ND?XÖbğu»Ë¯0sgò#ØC¡åğÃ3ZjãÍPDû¤µHRAWËQ/İÓÉ¾CÊp(™V1VJ\N¨½äiZØèÓT®`±¥©”8¨	äè4Í4µ°d‹Õ<ûóU°İ;âÑâÑ5f…V ‘ÆYı_í¤5g³áµÄ–ş?¶®$ Î°$—ç-NØ„È³wX n}µÎ®Îµ#wÁO}çÃ;bİœ†T7º—W((Ñ*„ƒÀ±]šöo+ö”Fz¬s‡'#N4k¤–µã\‚-hBN¸8¾D„3üŠğêîõ*AÌ¦§³ñÙŠ%êRo'Àú*Ò}®©ü±~1[ÕéŞûqİ¦YÍ­F‡Yİ¸ùÖµãşL¢T5<Ed82- xz;q˜Ä€åL™Èº>/?ô3öcÚ96F-×EeşÇ¹÷ı¼:İølc
ö™gŸØfzƒİa€èø%İEŸó,»Ë?"cñVQ'ƒMw ¶¼'Ç¨”«Â¼¡Çšp¶@vò8©JŞòÔÂÔÑ<=mgíˆ*„hİõGz¼½YŸ ÚR7µRö}ÁŒ‰¬x•øj{î F,³eJ"\ıNjVÆ‘´_ÜuXÙ¸j]ífzšfú&²ßk"LÙ3+Ú6mÂÖ;håİ‚éÇË5<{L¼î9f‹ñ¥DI{`5¾p='p8qI1S6ew‹ìè-å¬’˜ú²nÎ±€PæÈ¸=_ù]ã:9[@İø³ê‚r; œ@;å7öÃäœ•LTÍÕx]72 şVtIRu>/DBí(ÖÓËÔïŠî7ÿÌœRÒ±…öÏ¤MzŠ‹Û:õEÂ®%|6‡¿c5ƒ4ı{Š´JP:ÚKRz2„Ä‡:%Qavš+<ÊJ7¢È[œjÅª´ñİ1`ÚÿdûÊêVo@«b®ùÁ>Å;ÖİeÆVX|¦´Ÿjl?š`íBÿ
‰J.0ÇûüãHàDŸÓpÖë• ïÎıf'R“;£Ğ‹áìÒ†…XÀEölŠQ€…ñÅšV‹õ‘˜±FI4\è@x>`{ñ§}OÃ÷á<oe8îó¶Í-˜ÇŸK½5#—Ì[?£«‹AeÀª\e.{ÂÇ
]ü£^)¤¬‚D€—*HitÿÓ\`(.È}ÅcfAô7)ñV	pG°dß¹DLO!H…==ÉWˆ aÉ{ê4¦0Q¤Ş«ÕìºW>æ iì,ú3èàãÜeòcG½¿½#A.ÎÚÒ¹&9Ê¼ıGµ\l<3iÛh²h~o°ö[û	9‹ª~Ôb¨²â]xûzkgTçåH3©ûş!aáŒ;œ}ªS¥¬èÒª°àô¦Ï8vn•S/ÅE^¢Uïü^êm,µB$#óLãsÀ1)Ç{•B%Ë§ú„eŠÌ•\lDE"®:á%õı——@-×‡<ë|C(÷ÌùÅc[m„ö^^<ı-"Qçƒl¬f½s£Øü}‰b àH–‹›˜Q­/vŸ­=ÙªÚÆ÷ÿ˜ØØw‡`/såj¢ş¹½<7Tö-©æ¦Ğœ³
MOÅÕÜ´íbö§%”ïéâEl®Øîcí~­}’áÿNkñ´s ™
ÌøfDáT¹ä‰¶Yùa¦zQ©½/Ü;xb€´¿[µÙÏöºçİ1UBìÎ‹»ŞÇ uòqß¤áŞˆúŞ[ v!ûáú>å È]S1Ğå@4Dt*Û·³¾/õ³Õ–ÚúÃîŸĞyª¨w#²şı7ˆŸÁªÎL¬Ùjj”£–‰<»i¹%!ÓòJwı'ÒÆUD•²u“İyc22æ'v-:ƒŸn$İ¯öxHÍŸ/ÉívÙ's“!ºÈƒS¸è’_ÊeX¹3€Ğ€Ò•Ó;G¨ØğÒh.Õ“iük¶d&£
°¹Ò~#£+»ˆ;U¬˜nÛ”ååˆ+>T.ƒˆÁ¬wµÔâ"™"–8†–íLH:Y_Ûk›ÿ½"'^¶i½ ™4ØãõŠf½.is¸Zï#?4¥õùĞåcQJ×M.n/„&xj’…
Ò¹sR]!ñìBä2E8µ¢+qeå))zófKua—:@AëìİäñskÿîuÀeôkÕ²t_\¨å—Fä‡¶_· ³ÒbŒßY44TNmJú·¤M#ÉmÑ„=)%Hşj ’Ë$¬ô7T~høBRß­:-—Äœz« Jİ\%Sáš’¾c±æg"X³qÇÂO–•c“r¬?ü®ˆÅñÌŞÃû.é¤Ğ¤ÌĞ(rÍ»QVªˆiV‰ü„-Wéõ¯¿Q‚$íf&Q‰ELd‚JC¢/–1R,K¨nÂ”Q!<÷Ñàæb÷G’Ù¯t>~eûŸXVöÁx’RVL £fZwìè	„Z^‡½t§[÷0¥^ŸS%LêúÚë`‘?PuWT§_ù7À_Ûr8(ßiC
L fµBSŠ]¯!t\™Ñ(àVe¦æ(gXIÀãrrÃ}fHØ
Î±C‰¦“³$+µ©e˜	°v*gáPîãŒ¿RQc‡ÒZa!Êëñ7¤@Î· AûBú Dówò­©·d~Èa*:›Ì).ÜÚë¦eùnøH‡Áx3z½#(½dİ…dyÕ×Ö:¹©ãgÖm§–EîÃÅ5Ş{mÚ¥™«Ô4Á@mŠDséƒ\LŠü|]o5
Ûzù½¨€fVö´¶¸?53éâ‘ì¿ÿK:”Z„\…º¶A]h)@¼²~HÍâçv,^Ô±ÓSˆÒk.?z1Ç³¯’óŒS³QjS¼¿´öt÷ÙsF¹Ÿ»'òe–Oj÷ö‹gq!O{cJE}º1ì{LÎ°ú{ÅI¢»ùÈP€³¨05°ä°p¯²…¼4ZËÒÿ<Ke‹µMæµç'‰ƒ™UK{O°öD@DŠ¾ˆÍÆâ‰ëßÚyGâq´ŸõÌ6N·vb‘fWjPzÑõ-aù£¦ír§ Äç‚YƒÄ—IŠ´…ú {¡Î”æ¢e8l]	Ÿ
ïàòü–M¸\˜}àK/Vkb>kqçp´aQšÍ~î|o®¯Y¥SËµjİP5Lbù2Â¾Üÿè¡5Š\Ÿ[jÛ-1K6Î”LfOBØÄ
×«›¼xD‰ùV.=ø±É^'–à¢,Î#$PÓ =[œÑãÍÓ’¨\dè¤aU½Ï¼yƒ÷T÷ûX #gùŒ¿PPze7Dö?è"EŠÏÊsÚ9•$B@V‹×&.7ÜëŒ}57Ñö¨‡{9¢qÜ„`Eó•áÿ(Q"ñ[98±,Ñª¡ÎÓ/eÿa®"jüM|„q”Ç†â½†p»åŠ¸6Ó§w-QH4è¦“F›ù{ÜBïA/—ÎzéáFæe¨}@@Øœ³åò‰5™ÕŒ:K&é@íá3û4°›6UBQâ ² §ívíƒ;šÆçV(L¬ld•ø÷Yè´ó¼øŠL¾X!w²ñÙâª«WQÓô5hÒĞ¯§^ù&eõÇä¾»	iôFQ*p`šOöKÚzá:LCV>Şâ™&b¨]İËÒÅ¬ËD‹òÄ8ŸŠÕ¹T„İİûL4ù±üøÎœÁ ÷r€¾cmëO{Ù¦Y=zká-¤áy@|³üPĞ¹(¹L÷ó°>–Ë¸£´¡õkX³VNhúü¥Çé
Ş§°ñŠ¬¤æ%	XŸÑĞà
Òy&Sòr§€¡ÿ”5$Ü(&+ˆC_åGõ)šdˆÚZKM÷Ãé8¾V0,ûã;›Œò	€hZ~‘‚‡¶ÈŠAÂÁua¹°€ñèU²V¨'Q¤¸‡÷1§ú™û”M2İÁtãµ£0-x™İáúIC{‡ q×JxÏø»Òk"T½¿ımÆy ’18dæÉ*ú[&†R=Ô±Ñ¢1ö´<RL¯’¬ğn2»ĞÊ%nĞLZY'²à%XXnÒŞèÇn½ÂÓÜ¬ÛÓºXü¥Û~d õ‹ı2£üÇi³`±‰Q¯#_¹¥P[LŞ&ù°ôÖøŒé	õe½® ¼œ$«úÓ$3şÉÖ4ãûR)ì}q%D»ö^v—d.?Úä&™ù¶ñSEãOß(³­~´”®²æÿ©M0´Ğı¸˜}¨O»!-ıbÑVİÈ­œ—ë€ä#9˜sÓÌ!ÿ²(Ä¤öØÔ‘lØ„LWzp©L+ÒÛıZg…o,ÎbÈ¾ÚZh(Ü“¦äËİsÙUå%±IÇÓ1È_ğtDqôâ…L–Y—3ö—­f›M_8ñÉÌ’¶3|…Â€|ƒO4¨¦^Æ‘9´¥Û‚DMÓ¼÷Î'4OTãø*OÀVú‡Œ²ÿ\ş÷Æ¡öktOí§İge“ßÕU7ŠT0`ªõ¹qˆiÌ‘ØßÅØâ+Ë°Èyâî
ûZsª'¥wÌRddŞyöiÛÛŞU&ŠJ†Êıø¸°5Ğózˆ@kÃ•üb¯KÌâçÈë6ägáB—çJÕÜ\‚¿å*ÉüO=Ôú."D¥„Ó-e;U"¥ŒVkÌÆÆÊ~ykjé_  qÊâõ–ÆÑ] ø­€ğã,u±Ägû    YZ