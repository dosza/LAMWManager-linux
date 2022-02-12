#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2540381825"
MD5="3268690a76abb77b4c3847b2fe6a0b1b"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26556"
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
	echo Date of packaging: Sat Feb 12 02:50:28 -03 2022
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
ı7zXZ  æÖ´F !   ÏXÌâÿgy] ¼}•À1Dd]‡Á›PætİDùÓfD¼™°Ó¹J%Úa^²|ö!bÂyú%)•»µÍTPL¤÷wKü{az›?îpsÑ?áä7À±Úş[—ñaĞÏ°U	¨¦B\šj$—…—ÎI$G^èãB=ÖŸõCÓ[ÄÍÊÛë(J7½¾	­ù²¨^”³§s	û:’+1-^È°'1€0WşEæ—(ÇØÌbùÑ–bš?@ÅdÌ£?Û;Ê}¹×I-&»)+¿v¤ÒNjöÜé‰§§•j¨Ä‹ìØ¼sŒ{QÒµ&ÂH	a~ÄJ–›ûü³ßëája®ƒÊOÓÉª… ÅÀd>a=Î­9>'§ñ•†›?O£§r-hM³±˜{}/m"áu]?ëgÓñ…o—»òÚÔ»A‡+äì¯m}ñd_êïªøM˜=)<SÔegw;ı\h‹ô"x(^³°SÏwú•è¦’5?WÄ_ğnnÉ%WwÖî
@q¯ë£%ıMØ¥¸İ©›E_ºÑeÓ‚MGÑ°Q•‡IşÄÀ¹ş0™»‹²¥Á8kä«¥®!±hh'ú2#]øRŠ:º5;ÄÃz¯ºKÁ;¿A›ıLizõÊjë~ø{Ã³^£°?yÂÅ…³ÈcoŠ{ºÑi…CMË²^FÕ<„ hÔË^š’iø&›çH‰¼šÖX"Æ†²N*Äò>ï®¥*Kğd“,…ŞàĞ"õ¥³øÉÂq@|+	V²ˆ~¸0¼—œ™Ù=´htá°Rcõ„:ZBNè}3*ÌôÛi2i¸Ùò(t4„¨#Å„_Ç””‹¶§æ?CÒáòÊ…ŒÅD»•díÜñš{¥Èú6Ál—Ä™‘N›l¥ï—²§âQ©xâ„~w¶ÎÆŠ¥¿w$¼ÎL—S#ÀÿŠA‡s°eİš&9’o,/Ğ
ÔlPºZ¯Ï`­ÓûSk{¶<w,ş¥Õ\ƒ×1ëé„‘Ø¦a³ŒĞÊ#Ïä…¬ˆyÆÌ7Í?æÎ	Ï [0bÌe7PÎÔÆ4pMqfù@#±¸~#Î¹ ‹ÈDønÿ'_j¸»ÔYKá_&Î=êgŒö¯_ä#:dİ¦a”Èñ«—‘Œ@ó³‰€¼ºº»ª^H1A şo°neSÿäcåvõŠ³*.4åLÈ!å„gS«Bz+É®øúnü°/‹ U]uÿ&•éj²L^äeäıÂ;İ0¸•Ùåe‰·ÿÒaKÃØ»HÓšc~)8o”p“ıÓÚPë@&‹Œ¾‡9·V˜ş
<¨I­9s8KÈ]OAW|á™Óv6 v2jÂ~ÉÌÛ·àS»Kë	Z~-Åİ``"aì$W;ÊP »ø	J§Š: o;E’äşŒÈ.üJĞ©y’<¸5ˆ6ÇA>%,)şLÙ:+2l¥9qSã`ˆíUY°ş
İ ,ÜŸ>töÆ€Øh	M[í•»¯Â,»ö|ªtåY´g›”èÅnyiœ‰1—¯“*ë©iß1\×u–Cáp«ëhŒ!5Ä˜VV’º–³>š÷ká†vŸu¿•_jöDŞ;-şZr©­ìC÷ë„ÖÙ~†A·¬ÜGå™Kªğ„-AĞ÷‚Àÿ¯®öd‚·k²ôÀ¶K(­òbÚ§—»õ8®ØGÇ„áMrT³Ìæì÷Ş¼‚Ê…"¿%ê¯Œf):ÖRZ³~W¶6Ä«ĞmúñLnFkÄøFhQeP!AÕ_kÎÈi5+®T»Lb2Úõ‹¿ÂŠçcˆj;ÀBæ‚’ÉBÕ ¼	ä‰y´®S	.®§Q‡›»ÓœŞÆƒ¼P1ÀëRëY)¡¬5‰;ä¼<7Mód6mYßGB(À|m=§!B–8ğ9&±0#ZØ–à¥oaSâÏÈÁy›¨	”|­Çvš´<$İQî‹+4“¬Iîd‰6PÕ¨9‡(y"ä(¹¯@à\É­³ßşBrpH˜ƒÓÓûi©uRM™+äÍ4¶ˆœ?OıÊt°¿İC
mB›ynXBõY]­V±LeÙëñhœ²eCt}VfŠÿñ¹˜ÑÅò¨ñòéúÔÌB¥Æˆ‘Œ¡Ş©\|HŒ¶¶óP ê[VF—ûtå²ËÀâñœ@òß&U’FPİTÁpôO‹İÉø5fíg²NÂaŸ¾Á
G±bGª˜¬ÇYüc»ŒÎPäë'äaÆ°Şçhöõß¿¶×›·6õûÑ!¾òxÔG$÷ 	£–:[¸¹# Wp>mğÊRcê½n4åë,£~VQ-§äÆåpàWsH–k‡|=ÔG¦¸a‹Öãoë)l{ìHûÏÕÍó€±[i[Uy¥öğs] E^IÜŸ¿Iq­–
æ‰®¸$Ó.8w{Vm¦).~×ZóªÊÉ:H@r/—;A¾ÖM:`É×Özó¯Âb±,²Åq[È€½b"ÂÕ:éG:)ïREY£Ô\ö2CW?»Û4ˆ #ùq™‘àÒ8è,:fúØ(;Ê€7î1ãï5ŠºÀgä­Ğ®Ã(óÇŞ]ÍîuìL<Bäu²+¼Óº‘ÊD×wë;X²%+ÂAhšøˆ¼ÃâcŞNs˜×ğ&Pï«jß ¨€Œa‘vLcÜ™ÓörN=8WŸ—Æ0ÁÈÚDÙ–ª½½l,QŸ· Òla´)©M™ßZ»¾füZÍ.È¤”„¼ «ú#ÚËçT(œ‘âØ÷ÀC3hİu)'fÌLyÇêytl`ˆj•ópâLÖU*¼Dñí?Üdû@ô)L×¸p@•2ljW"8ŸìÌËÑ®&9Åhô’ÈĞóé(¹'İfbâõ5CõŸ{¿Ò´u—æ´Âk8o¿ ŒU@üúÒS›¹BÒ>:E² ô¬ş´¥ƒ„úö»ã»F¯ÜÅ:„ºHÜ-è¾Òœ®°TW3>´sîºg¤sÔlHİoA>Ÿ˜eùj8‘W¥uËƒ~xš·,LÖ–Z#Î<Xî(¨‰y£D«\ y@aI3½0›¡˜3•-~îş ëfœ9ÏDåIkêaox~=§\ñKG•#ªŒı.»O!·ÔúõÿJ½ÓÙ€\¥¯—¡M‹ş`w.tNÅÄš_rBÏFÌ	¾F†¬Şœ®èÌVZ³ƒÃtT¹@d\†jPkìZPÍÍ²œØµßÉq·Tû]Ö
şA…ˆÏV\6¸´mE™æÓ"ÛE²2¾‘Õ&»,'¬¥ÏáşÍñdİ5tròTwŞäzcî}§'v¶ôÁäÏşùı€ÚMJ%ÿ?_ŒBí<§åŞŠáš®ÛúEÇ¿=>Ã×È‰_ú23ŞJ›É_ƒ?+`¦’”u†(yÚ‚fäŸZGè1Ö»†¯æ¿¯«½5øæë6şloÑØZH¨ïœÚ±xÃtcË‘â™Â›V–ÛLØ>>‡‘ˆ×¼”„Øù¾FÚ£V=ş…eZÚ…vŒ^_èß3èØt„Éòƒâ‰:šsäBW¾(×{.Şú&†~¼vDÀóºWo&¦ñÂö<)ObUø,N…t"&rF8>ë^w²#\ünÎO–V8R¢±Ì‹“ÜõÁ.÷h½i6µ‚b'eğ¡İì¿7L	wKí«¯aú2˜îÕÔL©›Ø²uy;˜•àÄr?ßì/ßë¾B«:1ÿXTÈOn2‡êŒ•£)†“4¨Xòş?‚¾tsË¸ùÔY+?®pWµ)°}¶ú¯¿B§|G»ÈiØ›ÌU[/cR%=n¯,LØx[ç—ÚŠ9™óÖ¥É«N- ƒQZW^Z"Ï0udW)ke#¡Bohå&Îxçb”‰çã3Cãô İ¾QÜ§ñ~‡O€ì.—WiÎ¤“ÈÕùJ±ñŞ€îu|®‰ `†sm&Èû1cî)|<_©ŠstmsŸâ)ÒâÀ› ÈGïh¿AÇ®úçùcTTY
@bºÎlŸ]ô•.²ÙÛs¡‚6ÿ¸Ê\ZQ2´YØfæÙÓ9š>î.…)íC{rÂı}<M,-ä´SºaC¨ÍñÈë»[Œ`Š¡Ö‘ÅyÍŠcÚ–}uPà3ä@`Ådùè²9«‡XZ9¬¢Ú³—}UH+à]iH¡V¶Q›ÈRµ9Ù¼xßº~ßÃ¤ÉèÛLëAzÊx!ËËäP8\wÂğGú¸ôI{ş¿ª’m¥^(ra4ıæ|Øµ#FĞú±a¶kºJ†ˆİ¹µwòò)µ(ÕfcNçã/2jø7S«º-¶aŠ/{¼–›jç ˜ì;„ÂÆ70”(Üæ~ Û)‘#<û©\ö”ÑÜÀt´3JMgáî™tÕ“B)†™êè?ÌzÔä%;å¤4:c¼A#Î¨›g˜q…á¬µ¦he…€~™‰ûÊ–•Ì'öÔê]_ş³‚ÅK×›Âj‰“ú†böØ}|şâŒ¶Ûy÷x¬õ1í¯ñ!ùVĞS3ÅôÍÿHv	;l£ŒZÒÎ˜úÒ|u°mÁssV¡Iœ8»lÚÙrÚ|”†&à0êkns^[?BŠö¾†]û§£™(?w†I§‚è+r÷-^HA ”úVHÄDBƒÑí%ı?ûTÊp‹êÆ+RxJÂ2nëzvrm²8G3AUÌ`˜Ïª±—–1=*v E«‡é”cé¦
ü4÷t’Ñ•ÏYğå•sSÈô%’…¢pS‰E«¦åø,(è¤ŞİÓF°B±·W[J®Xc.U©1;§İ:¿†ì	ÕŞ‰ùì[×:mb 6RCh¬;ÁœÅf‡aØl¢yÄu¨›·İêê°ïO¡ ¦ÕŒsë‡@qË³²Ï&äf1ßh`ÏB”-: Î…wR:yØŒaíq—Ap¤ÑX‚gGUlã©’.üÙ Áì•óòÁâk±º0\Œ6Ùfî«P& Ğp†ÚÌ€YÑb¥ä{ºN|)ÁÖ8ì:ã¹ô£z-6ÃJ1‘Í˜ÅZ»ÍÍû&#H-%_%ÛÙ©-Éğ¬$–{ŸNZèÓ©³ÒK†®_öI/Ü¿L…ÿO’¥_P-"ÒêXCccæ²ç×|íÆSŸ„òÏ7¸™-*íäi¢s„×î»±$CŠr0¥Ô ¢6…«ZmuÛÓZíŠ/d‡Tå|ŠÇEy`¶ÚCF™Yky
‰¬“.´€.5|@-|­9ö,—]˜3™{%I¸Np5/0©Ğ±˜¿NJ‡Ÿ?‡ñKËIsr€äH{g:kiÔµw2ÓÜ>1‘yç¬°´ègØÈoêEôå‡¾KØnéX4 ÿÉØØÙ>æ-Îè‰9\…ãV•}ÔRY_c'e²Ï¿@5%Z‰Q¤ÁL¦àÎ‰©ø)¦ù´æ¸$†!,QÕŒ©ršŠş½$Ğ…”¡«ÌO¾¹V6è¬ˆ¾¾©”šÂwå²*<Ş ©}rÛÙŠ	ÊMF¬àé~¬ Ü-E`ã4y3øTëkÚÉ˜¸Iìå(Mÿ,{
lÆ¿€+æ{tkÈĞL£å¾`u{rïb}Ñ…`"Ş“ˆ>az –Ìt¢…æ|¡š N‡áœd-Yôÿ‰4`›fíÉbc\÷¨[Ô…å"û¯Î±Ú„tnü(VUƒ>ã(á‹lˆy×ä®eVÚNÍ 
Ö¿”w3ìº öş6<ş<í;ğûÒØqÍıb™€7·ºäÙ¬O`;ìíåm#0ü†;MèšÚ˜3j`I"È‹oŞF
`ŠQ¡šghÓ`•WcÓ%Õ Ö•$~ìÅÌáÑ;¶U¯¡È cnŒşchYUl„»øúøs.ˆ$îì5"†ğ‡
3`ˆh±¤?rIÎn¶Ölô±×£Ê‹¾F]ŠÍwmµbĞlòa}—şÛó,4Ã³÷oÿÈ?é"œ€t(±ªÜÖAQÂ#Í¥wÙÂ¹®a$µ¤nÕRtÁ§Laº–ds­=W¡x;k,]j5Oòô§[Ò«h¿Ü[Ì$OmxL™LCÜ–¥0]=CC‹#æøÄ8·w²·¨ü>ÌÊ·Z ²oêb¥‘~êô‡)Î',®Ú‘]†È”C@}½K˜ïêNY¡ã{s[·?Ï’ä[Emä9ÔÑmò¸“¾ÚQ¶ Í¨Çæš{(º– ‚‡ø¹á¯sÆ&—Í‚.Ü2Ì¨8}RZ1êĞ½²WD×¥ÑƒŒìä#\OQMÚ L3WïóŠ„?½Ä[òkicöi÷›»jñ!/tTÆ.¨)O¿bš)„†İB}‘Úşñ|¹¼$¶h.5Ï¼…$Úûnªòå¹ÖÊ¶­ê5±¡Còg@oÕá…Ân]l|¥çÜ7ËŒÛí„+#H«ûo¹2Ş¾~¼c¹‡í‹¥T­î`Â›Õ¢]© ´ãÊ_²kş%‡’¢2¯-ù@=;pw e	ğ¡•Ñ "sšr•zà‰‘YD¸Á¿İL#ö¸©üå
û?$7j¿èî“ÎcDo
xŒs¥™P¶×=¢Å>_¶æ£}@7Ë$ceSµñ©q—²®Ä±“ô.‹(9]“6}»ŒVL|€ zßéÍ…:S 3yàfÀî¨%ø6æµîµ%Zä4RSF«Q	=¦_:Û˜D4¢¯’ÀÿÖÖˆ‹eöÏÇ)ƒéÛ5½VkkZL°G~ğ:ş7ÂàÃN¯#iP¤ävD»ÁšMìÊß¬ô	ç2„”³°²µÍŒ„&Eş1ï‰/h/ö1d–$±½Zvù;t¼»Ş®ÊÓn[é¯·ÿ³Ùï´©/{tÃİ—a‹6{Ÿ´£
·–‡‚±Ÿ Sg@/ˆ‡\Œ$©ÍÀà‘¥5Íß¿À×â/mÀÙjL õKšÁl^sÍWVì6ÄÊ1`cÖì30§k™o%c6>@Ğ.;ö„5˜bé‚‚4"&h–&œàYöˆhå˜¥öP³şÖ©òilÂEşäH[Ç¯¥ ¶mr‰ßÓáŸIñÌSjãŠÍtü	9IvePk,* è©-IÜj³‚? èáPkø
Ìªj³&¿ğ†±cµ0PO¨Ó‚)"èêº·»Qy*'iÒÖ¤ÚùúÜêæâã]b·¤yÄín„%ÄX±¬y3³Õ—¼N´`vª.üœ”W’qOL?¾”oÙGôÚs¿¶¸CÙSHğßæßr6Ít†„  P¹9¦¸ ín"w¯P!bÜgÑ;BÚíb&k Ğa!eêrñ|ónÚäGëÑ3ÑÙ}^g¿°í¢ş2€´¹§4Å¹¶‡uš’•'\NO‘ÜŒxX,%Ô‹XÑÉIÂÖè4\.7ãF‡U±vÜ©…>xß¥VxJ†±cø¯Œ²LeZ¢æDÈ¶+ ²¼ ş-ÿAYp¡¯ï:3¾3µî B<–Ñ'ùO¥…R»«‰ûa9v(ö´=B'´(Í³H¥pÖ³›w½Æ=ò:m›ĞÙ hˆõuÅ+6Ğ}Šúó}on–Êäô§™înèÜÄ³¬…ŞÉcß $‰“*ñ©*Mö×nˆyš” ~…¾¿5(ÇöÉ‘Sµ K×ñˆH–”í€_}P-‰Ã“˜Ìjp‚qºl8ƒ5ÆuŸ*Âã<9¬Û%ß“¿ÁÌ·Awª	¯úˆRrŠ¯€õ•;%4ñ<o¬­Ú÷÷ÇyĞ4¢NX!O¥õ’¢ƒI(›K~‡ÁÆ*¯æ8¯h÷{/Ğ’0üÃÊ‰÷¸~´î?ÈÀG×ß‘«Øøîn!WäÖ¥ŠƒòlWÖp²²ƒ ¥Ë€÷åi‘JŞVö®&câx„¬û*­zÅm¥n¨A_È¼ò	VÈI¶ñ)îYOQÓZdû‰Î€5‰¥U`äóúŸÓ¥ªÏnÃ·g½Ñµ»ZAV|Á+Üh@kâÕbG‚Hê+Ca¶0³ÊşÙ[Àòxöæ_Ÿ ën*ÕÌ÷@L]põİº×0ÍÈHr„P)4¾[t‘çQ\ÓÃ‰/à¡A´È|©J!ºDôM Ê¦š…àuœŒ¤Ø…ÓÎsà¥+m†`L©m_ j€—}*e-¾HÁĞG:ÿƒ¦‡@®0=Jê ^ìş'FW¤èÅ¶?¦c»Ğ¨C‘¶²r-@6²'(Øw;Ášé
²–ÿ7^(ú”c÷:­“7ò9§t¯Ş¤céáÁ5oÍzh5üñë“Ù:§ïÙšœ^XÓ!YS³`
‚·­§x¾G|t?3MİPÀÂ¬y6(Ö­—qâ„–g§elÌoíKt»®l«<‘“ \I® ÂÏ'³E=M…æaƒ¹a Ù*ØwáõÈŠı¦î€ÿÌtqq³\¢_lMºs	Öó‚”Ÿp¯»óíàˆØø°íûKQßO´¬Y|óÀƒ¹I«v	•ßaÕñÆ„¥ôEaú>sÚCKßšiøÊidj„{ÎgÎµÚÍj6J³ÊfW½4´=S´œÇh>c}û°¡JÇõĞW¹”DŞLÃyÈæ¦”Ái÷âQ¥‰Ìæ3S®Ï­,Ë
ló£íî‘\S¸t+º»³_–”Ò=hÇ/0{’­>8RÚ#°¥Ùı¶…ª *f<<ºdêƒJ–%muêÈ—W¹2İ[¢FËŒ —›ĞŞÙ“DkÓ~¹Îúúf8ÎÉk7Ó Ö~oíà*â‡Zë/ø6z÷æÚD©#*Ê™´[…µ²¸
ñç]ÈQËs&ešrDÒEb{EB¡\î¦fÊ‡%À…Ò}d5”²Ê¤Nˆ@q9º¸h5 X¿ÿ´EâŠ´*‹d¸¡§¶§½€Qşù3÷ÊÁÄiÎƒ…(‘™$hŒÚ¸V.G_cÌğiú#¸K>Õ^¶©aÕ{<†ı	Q~ÑËCL?]_6™í0Cá¡Z5ò„ì¾)éä~ı-‰§ç¨-0f|p1áâ÷LÃm·I[Ü,¿T‘4*ó½ÔÜoŸ#hÑUy°”€ôğßìa¥Ë[ÄğDÁb
‡%qše±vZ?y«$j ûw·ÄIJ…s¹â-³KĞ¿”\z÷Vàœ±T ,Q	Ë²s0kmE.Añ@Í‡røÃ˜‰ÿ/ó¢mûğø&Oxz¨ºşÕÿrqP^×L5ÕqşfÍT>Mâ–ĞEäù,Â' M&À¨ÛfÿI-ã¨İ3ÀÁµºuÛÎo™=Ucx/§ôå²ø9mˆ™Ş«Î9Áb—®Ó7‡½—V³·³Ñv“Û'H‡Jš*™™'Ç`~ã{İ‹vCIM‘zAaÌ²Sú×›Hª)î<öKØ£È¡gŸ’¦µÛX£Û8¾Çğ¥³R àZtºjå42`Uª¦gm[S¯°Ã¥Ak0ÅSiåW`T«„öCä:4Kq´8´,CªÔ“'£QÀÛ‘Ù³ØwĞrÖ¿a|˜ÔlèZq1Ö
L˜:™%Õ6c§oQ¬É¬a“@6:*è]8+ŞÒTò¦´]ÉíÀXÊ~)Ã®ıxÎˆI­#_3V™•PÙ«	«S¯¹0n*¾©½ş¡èí{ÊKB²ç`Ü­³•nÄ×…bhàŒ[2¡â‡e_’ãÅ(Ç¯×§;‰èĞÂ÷l½KW¿?.ËÀûÊ¥ÚTßöID#Q­pÚ«9ŞÔ"ÿ¼tªm—0—ŠY²poòÖ‘zÅÎø£xGÛÚ†ÙÍ\6lxXfaWÃiÔáÁÅñX[úÌ"î²nrúßqH¼%fó1ÿ&cÂ‘rì£K5àb<3aÁ©ÿâW´
n—•ƒ<N$–'"=åƒºŠ2¬8³«­…¬Ánü­RöT+ìÅBâ®0l i2(eáÈ…KÖèˆD/—ºİÑùÑ"5W÷À;˜”0* Â5ã»¼=“>E¦¦§*o)Œö¿˜4NÛOw ~ó#‰)ÿÌ›Œ/€|„´k¶*!7{KÏ¥ó=çX?ß½²)(o(.¸¢©º)àeŒ…¿4àÉí<5ß¥ë”?g4Ê%ØªóçW‘z@?e—Ÿƒâ”?ÕÕ¿®™7ôTygL|i–aèàx|ee$òR6A vz¬<¹Ä[]şšÍÍÿŞÙ _/‚ et'óíßTëçr9Ÿy˜û¯#—aB|Ó§èŞA/r.¸‡ƒ¸”îîpäñ~zÍ™:|p?Q³\ï|ëÃKnáïR´ú¬_­şb\VêšmcHÜşFR¤Ô1*›Õ›n½)J:G?IrDIœç~6Õˆ¯‚îh3K¶¹÷5ÒŞ[Fn=L¯ñ½QmKQboôOÛ†Üåsœ[²|Îñp—|%Y:¶6%…¬¥yçÒT€1‹\(0İçaVr¼Åó.$:RsáéIÅ4U²0ÚË—wU¡’Ÿ3ç¼‚ZIQ\1RÎèâˆašC}­$ôuKpuºáùm‰Ï‹u”Ø“'„q(µ»v|¢şÎ‰@øf_¸÷`¥p%¸&÷µ³¶3˜ÕZ­§XºØ~[œŸø:cd%‘?3H¿¿¾z*W2›–÷å¾Tm™·/JcSKcX»ĞE{»Ï†\—'2ÙÄb¬±ë+6‰VlãQ©âDãZ(¾h‹Xoë[JÜSTÙƒBIÙràÀşı£¿oÇEVcÎåCÑ2Í<»,S3Ü¡‘ïW<ÛB¢ÁÎ8T¼5~“‡À
úGàı&d­>YÙ1Ïàc´Ò$¯¡‘¸	Ïæ˜Lq´-ZÀµ†%QøÉÜÄ¤äSÛÈñåÇİş´îƒOÑ,×ï„el½Ïã´"±;­x ŸDu„‘:EsOpB#UÕëId˜ÉØ‹ÏÍjç±ËÊúzƒíÈûø5ã+ÔäW[É¡×##!@åÈææåÙ‡‰ÿø{'½ÍûÔvèk-+E»L6¡jï(–¹áÿåL'ÃAÇ¢ø‚_lZ¯ô·qš<íu)|Ø÷{…©9_½”œæàÈ‡›æ"ÒÉBì×Q¤âVß'x ülñH=êØo¯
ómÑÓ€Á/­Ş‡.z©Ä-{/&—Dùk6ØÍ!8
Â?m•EÊîHåˆBş÷YPévİ–‰ü×{+¾z½Ò¨ŒbÀ|ZE ºä~*.ˆ¾®ÍóûeZ¨x@v;zÜ¶¿YÊiØ}¯xŸ‘öq·é C~Á6[ÆÇ¾ãÁ·VË$ÁßÈ¦Ä+Üå°-¦˜7Q_vô61Ãş+–jÊ:ÿ8¥Ò ¯îWØ”éì¾46¥ä®|[×†Œ€LÊœ@½Z.ÅOYÑ¥:ÊAĞO*&°°¸¸ı/›¦İn´#´ ‹âÉc“@©a	é¬æ¹Å›ä8CO)Év:ü;Yæx/¦˜s%ríƒ”ôtÇÊåö/Ÿİ—·ã˜»ßœ†e¾9lÛLg[VĞà©¸¬)õN)•jåÏz'T˜À¡À²Ğ8œ,Ê*ÍÀ-Õj	C`èE,,¼(¾4’nP	.FëY$äZˆ:=³šk´¡ê#	Aäöğ–"×*À)ã5ç7ÍÍL&œM>ö¬ÿ®¼½ÿÜ)ŸO ™ãúÇrft#†ízÁ•É¹Y/şú¥ö-ºÔöâíËFÀtQª‡\¹"–áEî÷ì†mâö‘|Tîƒ	¶3Ä¹7gÊ +ïFMáôÅ/oÉø>¸®À¯Ç	'‹ÕUÏ@ÔÁtgñ¬ü\J`UY§oüXÊêÙÅ­HØª­›ï×l’wÜ®¦2Éôañ#iÏ -~YõmïpŒÊ7œŠ›Ş}–y=#¾>XVqŞ©øÉÛ„§öiçt7ÓŞb_ß"Íä‰ j“co­Vj¼"E&»µ—uö¦¨°ß]'|™PÁgÓïî[5cZ,Z!vÖ¢X!©R¸â^>Êç‰#ßÿt†
¥@“™·ñRíÔÀ8¥{!_ÿÆöú\`¢®VY.ıAô‡¸@áAô‘³rDØĞˆ]ê_†;Ğ¡Cš÷°÷¶u‡çíù|ÏÉƒsí+OİÈå>Ãò¯ù0Šk¯®º@¾b~åxy~O‹ ˜ø;º[Şq¬}úÓVƒŞèsd)ÖÓM¥Î¯eáØRNø½ş<Ÿrr¤ƒäzÓ¶aÛ5Û¯ìíœñÃ‰5´GÊ,‹’Ì
czk±•œ,ßáY){·¤*Í
²î·¨G¶¥2* ÚÑQÚ’¯tğ
kHr×)ÓÃˆ*u!ñí’Íí·(2Wm†/Ÿ¤©ŒêSÙg<%Õ±‰–İëY~«Ó»—©„³k-£H$–¾Äüğ‚eT]sXsIµVé•Şgç`AYÖ:Ñ›¯˜"0øSÚ` RÌ°;	‡ÀbĞ˜ûõÌŠåaKĞF–…"wOÏà%çøøâR…ÿ^øSş€£ÕÄ"œo6No/åÏøçØ „ì-IL÷-{¡]mÿûÀ„ò<´ææ±
ìB§pÒ-ßRN…w•åí\ü½‡Á­ĞilU…ŞNÁºİ,ÌÌœ{3˜XqÔæühCïıå¶ˆàQñb¼=Jùˆ0!o/_ÅJiîüĞã°z¬ß›L3á€–kArCG¼ı¦¥çUè)ºdïä®`Ç@ƒ[¾l–â|\ğ<æd|¹Ğú^^ÿ!H{¾M7ÄˆÜ`?dÓ:ízp‹Ğ~ñ©4Òx_sãVc}(º)©Jx²ıÄ.Ô–ó}ë„Ş ò‰Pç©>›.Ìâ<2ä×Bªéz'×Ñ©›¡~Ø‡ ¿Ô“À¨<ÍQÅ~6ËW Äèo5ü]¸®º¾•´• ]ªz%*ªöAvqšg£7ø;š†aßYc¦æÁû †I9#s…+*İ¾3(ÅL¢{‚Ù”Jlx± *ÔXVúòƒ°E†8¿,æˆ+'e! [j:'éÖ½ÇÛ : Ãâ>¢ı¹©}ü˜ûR¼v©&‹Š4tê
ÉzÈØ´R$ò÷DƒKÁ$¯{ye®«Â}ôêjÂte'í][„¤«mfjF#+_ßøG"Î¤Ã˜®]\à,"‡+ÛTaúÌ@^§saY®f›GË·Œ Æl¾7w¼ÃÄ+Œ‚¼çlı)a¬?‚~ÚË¢aWá2eÕ9BT¯+¾’”a}â«’û …ã2¼l¬Ã˜­s$PĞ82Zô%»„“­™ê8…fY=Ú$ÓÊAŠıb×&¯şfùVmP(§.­IŞÖR›	<ÆuA Á;5úÀäğÒ:£ÄŞTÈáğÚbS¹˜GCb”œ„[Ïôğ_£ÚMÎ8Ô.NµS¦=azsó¿BöPwvŞ¤w
l‡Î9×É·~2¾E¾ôŠ	©
¢½·—,Q–cA##ªƒï»$Æy¿v(¾]’ |r'‘ĞB¥T§sr¿,Ÿë7ÿh±•:ˆjçi“§šcƒ29M{\qó.ƒ9h²Ëß¼ßKˆç¤,µ0÷Eá¨“ø÷6›sêƒrdvÅÊnw° 4¡€
Åâİ™a^|P£d¾³¡,–Ndú–, fN±jx>÷èlº3’ è¦¡¡]“l¥¨¤ãy#ò(ÓE$J”ÇCÜæjh‚ßÛ9pï•:VÒº–ÖÏ4G"·ˆ“ˆ&	YŸSëS:Uá‚/-¿ÎÄÅşr°[TÎEûÁTˆvËÚA-0¥·!1ÆãÖ^ı«Æ×Cı15¥÷ö¦¼Û¼îÑœ0;i5¿¡´9¿6#¤¹yƒİSc·^óá¼íz§†Šşu\Û³‰ÎÑî\lX4œø¿ÛfG1°ÆÁVÆh»X ã½R#(aWsÌçŞ#\ëƒSX5—aC)öU¼È½hCrü§Zğ¶­môMAú<8pF,ğĞã¹µ §‰Ï´k«Ãµ,oBùù›ét^şXa¬Hü)ı€~î½éˆh	T ¸„BÄ™8€v°©Ïë/vÂ`LËñE»'Êì*‘o‡ğnænø2¼9L›.’¶¨¨‘1a—=î·~U¹²>£G‰Q&÷ÁÄGveG&>1s†öšó2ã	·iNöÓ'c(†É™Ğ_·Ãc°)DšF¼Nd²]}3AmR¹ß[ÓİJc‚+‰Ç•à8“ñ]…«‡lànÑB(ÒMøç˜ˆåZ
_I=~-jÆoò¾†TSvÍƒtº<äË‡ùú ‹?ã%Äö5j)K~è=Ã7Ãìâüã#Ş³(02‘İ‡kó]›‚Š½àgG¬\‡l£IF'ò&^9´úKíÕcYfîAn=ıyó&½à¸O[‚xÑ 5A`÷BªªéªpÄÊ½_H£i{x8¼9º3ı@ÿ¤]_(Â1ÁàÈ‰÷¢¸6@Nşr"Õ·´/ îÚåñN½‚ók­ÊbÑxµN©põ‚{JsTÛ¶Q#O§ÉçPşƒİháºF•˜`Óå’]zÂî#ñ½¶++öşp|+¾B™x÷	L|+IGô‚ehı¢“F™Êäˆ–»|r›FmKİëÕØEÏÊÜÒ5¬´XáW7abï`üƒ1CDó®áäs{9÷bKvºÚléêAÑÓqkPo¾ø<BÒÁfã	=èÒÄ<ş(]ÙçïœØ›¡º4y®–øÑ<Ï-rİşQšó))Ã±g	²lÀü‹‰'`àØ½QÉ’Ä…]õ–}¿æéï+!oêÁ­5ÛãòMbH9%¼j½ëôÕ¾ç{âŒIÍSŠq,ÿ¢•ß—5Àp¨ JØ¿Nƒ"ú­ı~@WeÜ.•Â—€i[ñ]¼6$ãû>“j‰û(÷îÃ‡ª@ÌbŞ*Œüø¿Š·íÓ}% ÑE*gÏûH=¹ĞĞ³ærè<©Åáè)€%r ;dJÓ0àj«{…#Í°àè¤tV…'½!@Îùkîz›‡—Ià$¶³¬-#çTŸÅ3i§BÌ¼»®ú¶ZxH63òö5÷u³ª…ñ'İÍĞ"¯Ô!•TôE“½R¦ä¤ZSƒÈ‚i)Îä SYıPªúóá¾/i<ŸßÕ<1e¨»{À|óUVEM.aêı²˜äPÇgÏ»Û‹3ü&ƒôç‡Y¯ÿ9T¿´`šî ’Á¢J××yÒŠ(Ñ:x#*&?~?™¤İ—ù¹ŠÁ›XEğíÒÏl}w&è`îæ¢2-­hû¬ô?÷­‹ã¾3n²2UğÕ|€x˜8ñ@ƒKD›ò…şkE¶8¿šB{·]QpV¿€ÈÜ›£}mÀ9ùM6y•‚»Æ|şŞÇ¼¦¤mK7¸Õ*„UàÎÕ+.ˆº*Mú’AısiŒĞFõÉ7_ï+÷^­F’õÛßùMìèÏØ »sÕ¦T²pz¯'ĞÎ@ÌĞÒ_1Îvp!ùœö£ÎŒìºÖ‘Ùı‰U âœ¾YÒ’sê¬ìoèíÑèå·wW¸Yco“05Ow’„_§óş·JÛ fw³›ƒò¶ğIH™?#NÔ–= ±ÊÜÃÈÛíXV~V+zœ~ñ×½¸s^:$òb¶ô¡µ€£[^»fãœXPè´D†¾Úxkû;š ZXø,j¥Wõ¾ÈvuAŠBÍ!–ú¡1ÅŠXƒkgP—LöDÖPü˜úŠUH/ÁàXŞIäÑqÏÈ|8¥¯«æ|>x,~Ğ£^¬¯Úù¯¯§hªå§ÓÃÌí®h2ï†håÁ„>iPv¨eíoµ³ÈÕ¸&9oî\¡¢`ÑZÁpYÇ±ºÓÏÙ	!Ç'§Ù‚¥¢—2Ìğmz¨½Ø]½€Ğnğ³Ü>;aì,³®x¾,<`Uåq(ìE6ix_­#ß8¯\÷çşÛ¶Â±Ù®Ö(Z³Í"!Ã’à’ø‚ÚÈ¾ÎµzóøÈ5Q”U“ç$d.£…•‘! ºuEèw62øÜdÊcºMô¯­Lpâ_¬fs&!Nqš5éÍr[éZÁ[
—@$@XZrÅ
Ó”ftîM’sç…–„te Ÿù
ëË¹¶3\&JG.óVş9CÄyé¡dVÙêzpÉëê‘0vÂb¢F‚‡_’pÒ7Xÿ(Àä:¯ ÑÀ½†V3~ÏĞ øSR¢OMKr|ÑxË8˜Åö•Š¯•³ö“%)cß«!NöKÔ&=cç‘>põt4ONºK†ÅÈ³^ÁÑàÇ¹%w|CwT=¼’Ê% ^l:ˆ«Ã‘2U.ı—d=K&ê(
Ù¬½«ìèÏVÁõ8*»\Õ)N¶²ëòæO‰Ó¥€ò™Ôæ€>-Ë×Âú#¼óWZ:å)èr}VdPĞVfoÄÎ0:ÍæxŠ®Ù×õUõz¤'ó~ZwEu`sù]µÏ»qf—=×ê#»z¨»ˆ~ºòå-Ë|ğ&¸`=#jnö•òìÒàÃÈO®‡›®õ”hŒ?Z¢mŞ}ÌñÛ1ÕV°¶ÿ¤Ïe"/ÏCÏŞÀ}@Jd‹!ì7SŠ°)Ô,ùŞKÉ	ÍáïÇÛş•™3ò‡>'E*»…ı'úOÂg^ç|K>„õÄke‹`PùØ$¼#ß%ç~Ş!XÀCÎ¸`¶ê7òIŸ`Ÿ4
yŠº›šİÕ Æ9!ÓÙ_Ø’ Şiû¤‚·FšÚ11ûM;Y-òWâ™5lgš+ŸµFv<ºı¬tŒåƒ.GMéÌ†ŸÛ»"äè¢ô×Ä{<ip§Ù“Qï=G"uƒÒˆ|råÅŞ‘²ß›XQ£LxÄíümÆğ³ÄÏ˜ºM4f–2FÒ§Ha~R[¬ÿC|;K-®ÿôE×{Võò%|‡‹›uçÇ»M{ìŞ]VoŠt[%ÓÙJó×&ÇïĞjÛ¬›Pué^¨=
¸Hz)î6WM¹Ú;ô ¾õxmËm´-s'n)`×‘Ó2|à’âƒ#?Ì&ĞÆua:é¬X¥Ã3:å³®¡(xŸ´ÃY’÷‹b;°Ÿ¹s¦ÁÎ…ÖŒ.™¸îL{LRË:¦ê÷—%—û.¡[§ÖpŞò¬4Ü>–‡î]eu©FXñå?«{^7Ğ‰-,ÜÇ?CÎä¦ùP¿tS-Ÿ›À£
~Œñ¸§`4ÅÁ<©ji|äª4Ä¨à‡nğ‘D”–ô0¹İ Ğ b?-× &^òÇÖfuZâ¥µB’MNë¯^s'çÍÀ]ì»±g‹ÎŞ—í,‚øŒÌhïöP9 Å–>¬
P0jwwz5ïèà»à•Ä
Ã-un¹ş[¼3·òä"Áÿˆv|
&†Öù3\ÊÂaµ¦ş$Õ)ÿ.nW)¥ó`_CªGõô¥"¥üâYSCıË>£ì¾¨jôüEñ\»§Eª£SÉzò1Ì³Åª<`„Dì}æÁ'£/¦¾U$Ëâcx×©Åe¹í0iÓHãBP‡óÍ6mŸÖB ÌëXgl2åÖe'€X|Z³R“Ş—¯V-3)‡Ş†Y–óu9ÓÇ@¢ú$µù²RóJş	åÆ*Z‹>æf¾Ñô«Ö«¥acœ	è³ãñXÊ¯>ÿh%I¯õßØx©£X…ßDGféÅ.0B»s„jÄ¸cÁyZ_Rá"0$:IĞ4R©·»LX€µâZŒé¸)Şö¬Í­¤†ºM¯ùşGÑMúªSeó_nY4ô©„'°I7ü›D7¬³<‰QôíÊß%fË#İÅ„KÖ¡-µ¾(bª@ò_Å¿ÀëŒ€k£‡±g¼†™)ËÄÚí¡ q!¦bE;sJÌ½8O‚iJ|kw»|4†øÁ…˜·`bxUz0¸Şİ}ä8q›)X—ˆS8ğd¹Ll©Fª8¤—™émŞ|×;ºiñÌãÂ˜ğlzÒá‡¯0\ƒz÷ùz>ìÄ‹õ›½j±syığµúD¼jU™1ÁÌ÷¯ö™-‘F"‹Ä{à<%ÿÅ–ûxÃ™ûwš6j;f–‘>Ñ@‘ˆ¦ ‚İ&€1Ç…sày-2¥kü~â pFÉÇz‹m\qo³küÄ}‘! X0>KrHdAµú@¨“ü’<,h³¨™KæUS¦4L! „÷‰	4"$ÀïMµIè»îrén­ñØJNß¿rÖbA,%Ø¸;&˜Å`±”(™ŸÈ÷KëØ:VZ¼û Åp	Mç…å=gnb­¡®¾eß	/cèÌ%Üs»%Í ØIìï©“»Æ7—o	yVàõ¸_¿¦ÿ»ó‹Î é3•óQ¿¯UÄ-l÷¡9Ûœ€™•Ü2l``ÑV¤‰½{0^\jia(ÀÆµ!D4¹æPŠªQú‹±?1ªû$%5„òçt¹Ú_;ûFü^FÜJeÕ ^ˆQcz¾õpÎÁ†tá×ğ9“ĞE59òŸ}Ş\¼L²(É?[W&Àª%Ú€o<S…ÔLV¤Œi´$€ÒèÙƒ8v‹‚@tá¡0p…§mÚÔÚ!ÓmpŞË'Æ°À äó¼«…Ú¾¢Ã•¤®%å¡(8@5F#­û¸¼Ú6¹pÓîM°4ë/µ
,kœ+Ç… »DÊBkQÚÁt0Íò’ì­…‡Ú¼›Uøg½ô$ÿ¤İéşÖB;R°#,ğfŠ²-uk.Z<CâüÚDcP6­yİ½míq
­d`©°æ$9’/üL/_ÌO,Ô(åVA ĞšjÚBY«=$,ÂÃöl2ÂëöFä3ªp‘Nd¼X¬f9ëTRÁiDÀˆK;±'OŒ_5y1ÊL‡ ;B[T½µF¿•¾ù·ÕGˆbRuÀÒ=`ŞŒú¾ô-øa²Ñ­Ì¨¶_?ab™3¬ãI£ÚÙÍ¡÷dAÏ\0dZ¾-‡HÓ'ÖÅ›Ã.eÔÂÇ©ëO#•|gYÁMAìü×´‡p§Œ…œõOp&Ä§ö8!ŸÄ™‘Œ}…c¡3ZÃWèûùéÇ*Í[jJİµ%«z`¨òRC¬û¹ƒ¹¯Øö=SO>cV‚m™ÿJ:ñG×WİªY…¯UV¢ûºÌ."P«T#!à¼ÿ^†Î²™±]kµùÌ•VÖ›†óá†Íá:/¿r•Ú[—NùVJ3ÎJl6`imFËZæ³N%=€İ”èğøiê„Ô!Äø€äíZuñ¶jÄ%İËùwçHUÓ*…êøi‡TzwhJW×°R|»kÓ¸ûIİ±İ QşƒÃ-Båé0Qp2»	Å(W–ØŞd
WŞOÔ8Ÿ^æÁ].»lbÜ˜—-–670</‰j À®ìÙ}é©,µ)”æœº÷!RN61>®†ŒëiÀŞ/˜â"Ó[‡[óŞ´ô{ıÄp&ˆ†ò6•™²©¬ûEö`BaÌ¤¶\i{FÏİ&'Y¿æ˜N!i•œÿİwSÔ³ÉÚê”"ù‚-³à/ƒk£Òı½Æt+GŠ^lVfõø#å÷ş <W0E_4^JwÒ¦Q„õû©%ÂÂ¥PKâá­ÉJ&·EU­ØıÄìî	‡zÎñA¸û¾±½K¶æ0ÿ|ë¹ò•D) ×g5"Öağ ?KàÎY±è¯œ8ŒBÆCÊÔr£€İÖÿ»å3×·?ÿÓÁİUéë¿˜BM<? ‚ i ?FPÜ²_ÖtÉÄh¼&^ Fò
C©§)ÑÀ­:€Ç¯ğv¼èšF:”ïW
ÓÜ0ß‹XŒã –ŒÚj(2ó)ÀZ íú¥–åyš `J‰İ-“=\ÊÖó2HCÃc`Š°W­İˆõœşß{èB¤&km,ÆŒÌgê‚“•¦Ÿcù¶gõEW™|xÉËªçË-åÛİ%˜{Şæ6~ylb½Œ»‘ÅÇ¨ŒÏn4%ƒúœ[1_ÃéĞŞeFÅ—í[LA´-ÙFÅ/Cq*v¿¥,.ãXw[Ö@"Mú~“Z{6úœI¯'ÅôÛ—®_Ä"á·-EJ×­)b±Ë1gÜıÍä@[ú~lI&Z~vn%¦/£?Sæ—³*G¢
‹Of™}ÆßLVIÀ(N°;¥ƒ‰<çuÑÀtÕ/…’ÅÔÎ#Xå$ÁçÆì´ï½%Õ« {Ó7´ìwñÏ6
š©¼Bƒ¾ÈX}ôáÅ@uœ:Gâ9¶[x›œy[,\²¶„ÑšÑÇªÄƒ¯@v)—å1ğHœJÖš•B>2B™ü¾;Ÿ¼rrbÙT/¤b§2~ú¼æVmÑøê"Z¿^ÿãÕJ{©wÛDc]¶-/`FvN2º¢•‡P³*"Óvà£ä,wŞfÕöÈúˆ†”P€íÁ‰­ù™k¾}Ù£ MÑ€Ba/PûM¬×NÇ©ˆLÛÍàsZ	UŸ:‚MôdÉ?eºS7oã»|Ë{„	Rœ‡.ópæÈ–í°Ù&‚~Á–âAø¾/P¯öÂ¥QØN ¦ÇØ-G>48 úœ‹Fáİ²ïıPJ'=éÁK{kîaÔÊSª6¨ÍX„G©>£HÚÄù%\ba‚êBàvíN\¯÷Œ Í~ŒŞ¥ÓìÕÆÎ'uÒ[K;R>Ut ´SúÅLü@]«W»l¤Z¾Á"÷lÊw÷s×n“í½("Ç.t ÏhÒ¹0Ïò6Œ¢¥ÏìR|¡4ì[U)Ûe[‡å—n*ß‰·&#yy•‘èÁãÏZ3\`—HJ
·íSé‘™^Òbñë„„ÙÀ2ÁŞ¯wYùpg5v¿y¹.ˆ'“cN€œ%V±pß”†Â…Ç+´éR=J?Ô:[;ù[]ÿÕ—n¶@9ø¨•ÆS»Í_-|©³ù%¶§4"#ßóP»ÕÅW±ÛDeò¹×å[`øD{IuhÂoÛ,LË@^öÖ¬`†XëW+ñ[f søÌAùÃ=SªÇkôáÚn]I—ô!6™%2s…2¹¦ıÔ"_Å&™š¸®L“Û¾‹9:ÿô
Ì"6>yp0–Ã¬èÄP\õ~eí°¯°ïâ8ë]}~äåó?î`_Yi<±æÛÃs7Ë_ââÜ¶Í‘éÜÒx`
GÃy×¥OÈq°î6‡íó‡Ó§Opm™»ö$ù»®õÍDN¬Aê¿1ø)M3‡â‹J]§Ó
y¼hQŒ.SiÇÑ@¸í2ªù³„Vßü#p¯mI ‚¾Ô™ŸhP«±Ãú-\jïµ-H_ğêVı§‚ ¿¶|$j‹”ïÏÕ01]9ü¯#,•iFbv—3—Şv¬gC"l@îªÄŞ0H
µ;Ó¡î^_Ûöos2”Eğ¡U”ªN_q•
9I_”:˜rØ!M1f3!ˆ«có¾µâÉğlŞ©Dşãîà€­vÿÁÙ{s*0Ôö`kãÎCÃ¢lv~*Bä9Ş»5Š”²âr…ú¼A¸\\snaˆÈ bSÏ'ŠUÉ×ò
ÜN®rƒQì•§Üî8¶+v‡Z&"ù¥qcLÂ(úÎ‹ÀÅä
vdÀÉ½1€å7oÏ\(,ŞŞÇC¿]=¬\#Ë/¡/8ÆİnµmG1§òá/Và¼‘Ì¹Ñİ47kÔ	‡L°¼ÈÚ\HÃWº™l˜ ZØíS7öİE É‡3šf÷:"ÊÅÖQšÌô€|zñC»xÿ·øŠÒbà¶Am]uD:Çx®G‡PØóˆÑeZm"kD„²­R?—û8.…Å©õgQ–²©/Ÿ´·œ<­ñhÎà˜ök¥‹;´tYCÅêÁømcÙ‰‡–ríIÖ­ïC¶»ÏğÃ!:¾€UµÔ¾t÷¬rÄÕ.Êã°)â5=sPÇîc>[U3N´‡²Ó^s=„Jd9T†9]K•®_[ \‘¸ğêı ”—ee½S0ú˜§ò@Y“ïi­C•ç«92ğ„±wéÚ yé_ Ó0×x‹\ºKs)„$W—ü@°úXß3à5‰¶Š0¡Ó¯[±y3½0´›ëh	¹à¹ñ•Û¢õŠ;h©g¯V)¢•š’á®q»»˜N”—¬ò¢7ø•ìï2Ê:/›vğ½h]0Z	¿ÿ7Œà¢6¬)ÄÈ«Y
vá¹a¦-JBq¿Ñ\?®OÂ™‚EØˆËe¼Uï/Ùë.•Çâ³>x,~Û|Rís£ˆHïoÙ)=RÜ€¹ÅZØ\2©ı¼ÿõÈÀ=ŸMgïáŸ:î3Õ‚–•¢ıtºÔ^îíré} Áe­”©n®jêhC$Oğ·±„aò——h‰¾óØÅ°Yì.ñè§—'Ì`„U×îÓk«H½je<^HØöYz»Åc5Í|{³#\‹©Æä¦èîxÙ±¼Kİsñ_œ’Î³¸Âÿ—ËÕÀŒ»y"¼Mİ®½äÆç—‡÷O%´Œ§çM’1Ï<öb\wZ2œ¶øKò}¹tì\ê‰-QÏqa¼R¿…ô“ïoÒ,¿yñjuĞÔøÔÍé˜Co	7W~…]”äß¤Ü‚V8ª:]yÎ½@¤æ%€~&GÈ–ûÕ:ÍŞ)v[í©Õİˆ cÆùk±ÂıóÖ§
^ÂOMã‡„XèˆÕ¯y%êÇ%aC‚P~¹ùG—úäx_É³=-‰E5 p²c…ø»ñcªˆk~ùÜT‚“2Œ/"„ñS çÕäş—m‹ıŞDûFV:)&fl§å¸ìTfd‚ˆZSJBšt¢¥Ìºi¾e™%®İ·—ZpXg|Ú±C£}¬»{tª –8=Q“2Cr™FÂ(›>·1iïĞi>ºÔQP
élóÏ2h$ëx­Î9—õg7p»AJ’[G•Šs+è´w<¼i´lÁ÷ìÎÉ]æK¤¶\6j¨½I£—8¿®x¼-´˜9Ã¬<Æ*¿Í<€Ğ^½æP7½Ë# š»¾p>Våˆ9•Â«Ì\G5Œ¹§ş<h~Â,¢®zİz[ƒîu:¤4ƒ%£÷À¶‚$-Ã—,ë+{¡&fäM ß†=¿‡ŠeN— ğ”gQŞìÃÁ×îLáÿR¬“ÆĞ‹\fAÜY¨,qÎWa:À^½E.¯q±ğ‰gjZ¡D5ô­b¼û½2šéŞ{O)z×‰Ô¿ò¹½`Gz”?ëÚZèGnJJBıû‡Ó3Ã¾¨ïôûq†{’Z?g~ #úa=rFî‰ÊÁud£8*®ài(J«Œ´€ºWÏbgğ@D¢ãRîü"ş±YKš Opñ|›/aZ#ø*“½	Oi}/¢P+Ñ-®…œúLèdŸ¥ª»5¢\ß~ò×#(5˜–ÚÓxFèıâÕÃ Ù‰ÚÇJ5ãEì‡lÍi6‡ï_Æèçg‚Åw!ÄŒ@şÆìù-™MœÛöôùËe·ôuU‰|ëTñŒùâ¾İ—×Ø:lmÇv¿Š1zÀ-Jİ,8^G}";Å¢WGAò¬Îoê µÿà=î³¡ÚÉxë‡‚¦.ÚA¨õIÑ%€¶ş	OçQtÀ8:Gœä8c~Æ°­iË¨”è3,ÿua m†,×DÉ²ìãŒ52!ígˆÏ €€æ˜Ó¶¶¼£’bäÿNƒ¸_~r[ìRƒÄ3§àÔõÀÌR·™gpBáH÷¨4%„mªÑØ >!Ú²ˆ±§ıÜgzği²^q¥é¦ƒµ7ek`Ü’û¦ğÏÉ%“óÍß!ÕÕä‘*K·-VpVÏ9Ê¾-â»^»=%b,­©Ò’zXÛ=û×R
}A¶xeÌßÑó-8OüWã^½¾¯Ç¼WC_á0˜: ã”Í·ËXÙ',óœÌşéxĞè– Bş‰&¸~´”¢0pÅÉ3Ã”µÈm„2PÑ!ÚOŞßø:­a•š`½“Æ™Ê:Içkl*BA”Æ³("7º”í3-r	—0ÛPM›Ö#¿•rÿÕYbl®&óaP
 kbñµ°)«<u•©È±åÑ¼Ã)_uíOøäõe[8Î²[D3gòŞ»Ïı•iàó¢Œ{jÉ(Û–¼¤°ûtsX¹%5ªs.¼ãu~k®èk¸#;ëÒ0¶³‚Ø>”;‰^Œ=¶†#ÂoXÒ<şõ%]3Jû—Ùzöh;df•‘FPºªÃN!Í©ÔÙ2µÂõÌ¿[şÓ¸fZé¦;²p< 38#=ªèçù÷eØo¬¬n³H4É¡½&¬€5u¦J“Z•Gƒêe:2ƒI×Œ¨Eù3ş†c/Œ·fSìÚÜû#ó9òø»bÛ„¨^ÈÑ6vx…‰Ì†ß;¨P)Æ
ItıP={"Î÷¿£ñne±*md‚ŒQÃêÅ |EœMäãçÂĞJñL€Œ„Ìİ®ÚŸäÕ"Q€íÛÇ:JP–`ûë°jR|¤8môòëØ[…$d•Š'äÈÂ{ËÇù<xQ›H	&2LĞ”ÿÆr#Ìv5İYr<Zü‹‰4{|§÷j	YéØG¢$”uà6qª¹­{¢LÿM…
®ô¿ÒVÜ{KEºá–‚+¥Ÿ°D¯§ÅÀ73•,¦`Ş°öq(­	'óÿbW„øMWû·€Q×ŞTÛ?ŒAºQ†À:<ªT,v„,0/‰<z©Ğë7®‰¹.|B gêM67a'“CèƒİÒñNq*Áfß¡t{–Ô4^ÀJr˜½±_{?mB¾v‘“‡–^Ÿ€ÇÈ§
: Ÿ:ôty>¾âêú²rFéDà°^É„’^%éJNüğ®îuİ_Ì ò*¼Í· R.
ºQ,ê·&®.˜–8Œ¡àãu	»™¨ª×»q6à6 '?oéÉ´‰?’p>k³Ó•ºµºëgKjÄ9´œ/5=ô9bo±Q­±Øl‰¿…9+0y €ÎJä‡§íÙ’Ë(ğdƒ­§§«û6ßû5Úäµ­æ‹Çäd*N& (Ôã‹™®`£†`‚ñ€ÂĞ…4œrÓ@ìè]sí”w.è$³7\˜ëaRˆß™)ut–©¿;M=¹æ _$Dl¤.5œñq˜áÿ$Ë(J»­†SLY9Ò-„ÊCüš¿fªy»p®dwtöšİwãİòĞvx¦@ÈNR* ¡SC`c5Å"ÊÁæã 8BußºovŞLf›J©(¥¯ú¨ú[ÁsãÇñÔıŞ¢È¬uQÎo¨Öş1‡’Ã	T<qÙrß<•ƒ†¼ KÁ«Ô‹!ËT"™wôÉí]‰aõV %Q+Åş³¿Ô¾ŞÎícQ!õÃ67Ï(pÄì7İZ¯PòFxTa8Ó©Ju L%x”ÿš³]S}j0ê¿ıÇÑ©¬rw(ŒjüÊ/ŸY^ıÃ;gp9İL@^YJ/X½ í"n–¼‹%qk9°PvëA¸»P~{èÜëğÂ
ïk-„µ—VÙOËmQ˜)¶1s·>ì[*Pf~ğÎ¿;¼:MÏü1U÷|ÌS'pş¸}ç„.€³Â¶|‚5¿¯4j›Ëğ‹>¡›‡yÃœ§ı‰áQÑ‘Û¸Q¯ã$\ÅéJÑŠh˜BöRÎ§ÙÒ2^dE%:À¤‹FjuÿÛÂå>E¿Êí®š†óŒ©¿qØò™?R}·V<‡{1Óª\mï”².¿a…zµ‚lÓÅ¼ƒ(‹h=—qÃ4["lZÊ™ŞıŞ˜­‡k8x
.Ë ×-ÇÎ™Ih
BÖºúúBÁş{I—g*&b¥ÔÇâòg¡®ÉØE%Rw½¯š3r:¥WôŸınVVØzÿ&ß:¹áŠ Ò÷=Y¸Âüåã6“vÉSnõ S5-Ñ>Ï%EşƒÌi¾ô ‘ş#£9¿ê›!£¿'Œà$ûu1‘A6Z¸±í­ÃUëYK’‹>~ê0¾hÍ…B›9JÈ4‡–%İwÆF+7.¶Ô—á¸	{9:lù”Cx@ø^0SCx¸ëã(oqë 
Ÿ!zV1-ˆ–ÃıŒ¬Ì‰˜TÌ/²ƒôXæXÕ†f¿ĞÿĞ‹¾ª™ê©oa4#!¯N3UR$mØ— >v%4³tluEâû•+ƒ.•©Û D;Ej:
Ôá–œJÚìQ½fßßh
šöš;’DdìBl¶ÌùÎÛºÄ"#‘-(@|
ijÂY;…#ëò‹—ùmåuê @9©9Ò
Ÿˆ‰¼ŞoõŒŒÀiºbÌ2ê_Ò±z¶œ`S:h'µtU*ì¹TD–$ùj·É•9°°(²~&‡•ï§ªŠó†Ã¼ÙEÜ&#D'ÛK¨‹·®ØUXìĞI2ŠÛó¶£!eÏíëíÜÅ/‹ˆ,"Õ^W¦
w±¥n°ëËü¿»‰ÂŠ‚E„3àC/XlÇWñºê_ ÿµê.¥ vÓôIBL²3½I;™§…qêD{eÚhsÒ¶„o´„#ŠóºÉñ¾MĞØŸ`‚ïê$²è¸Óşr´]hª¡P=Áè26Ì&Ú`'ã†RÌàİn2+Õ8R}P¥‘÷"fOÉ'–xÚ!¹@|Jh[Á<šKN<dÌa5«ÊeWıû‰³`	ñ±²%”Ÿ¾"\A‹ Õj¥ÇSÑ`å8JM“¢§òyFâ·ï>3Ó‚-¨l“)>tÏ†”4à
\ñÙFğ›×âKZôìû±OYyO†çykÒ<™ÂøByq5zPÊ€ºÙ÷%¿q?2¡Döîm
¤°Ç(LG¢Ï :RR¦ôÑÏ CMá>Fàn3ÅÇÌÓã7 úÒ1zH0×UÍh‘¯à‚û.Á¬iPeÃ*ob)Qócú|\hÆº“Ï€`Wƒå#ÎçcšeŸyNc6{Hë¥”«2ÇÏº!;´$~Z±GÕ5 b½³{ÓØ¯»y§L,°kÕàåÓ!o`Q~i”Ky÷:tDgpßU/yz%†~LåD3,	½L>-rQn6ü¤¹·Râğ"·b<rŠá“?Ìº·“#kÛ%¯%‚F@ìxDêÀ?Vh;HÈ&JõªAÏswQ¬–T^ÇAÁÂà@ŒWã‘ºÇ:æñ…İ1Øy„#Ô!o‰x)ğ·GxÅÛ
››&«SÑQ}÷İĞ˜+6ÿ95ŸŸ"ƒHêérÃ6<xâ2³b´#ô1zÙ€c5>[)¨Ø,:çjŒ(| €ÒQˆê-»ŠìºøÁÆ)Â;pÖ±¨Wùmu£S+ÁŠ Ã·×t{ânä8C|’‘Z·‹‡Âæè²ÈşŒjaE`1“Y&Ã,<	çX'±Ö«(Å*™Têî› 2b.5óAÕÌO-Ø§ÙZgÏœĞpGw;¼–Ê_:›YEqÚëˆ¼Iì“_°,º±çJtM[G/:Cæê~­×} 
‡`¶`>Ô„tp¦ÿ+·z'@ájkcxS´œp7gAò~÷0Ó56@`ÒøjE|Ü’+rs1ÿ‚÷
ùTï½áâ8üwŞ/pfUE±‰T#Šîüøõé#ìŠ[‡(T¢ ‡-ØşĞç›xZUÉT˜=ê>³2];”'–¡ºyH"«ğ·1ÒÌ±:Ò†)‚Û”ö!V³IÑ0H ç&Ô×:Q°pbeh×ĞM¸cSXy¯•O×ôœœU˜1Æò ÆJ0Ğœ[¼œÊÙì±F­İÆ8+ákûe‡·¾· ÂÂò3”éÏ%tHèVíBš`Ø;ÌÖvJÀXwo?ÍŸ×$¾zÆĞ´W’85l»ÏUĞeØ¿Öªô³álöq‹²ë=½½İğÜOHİöãÉ2?Ev!^ Óòî×ˆI­ÁaÊNpáÁñJ‚c¢ALF}`÷¥iÖè“\ÇÍñ[«AèÒ7!s˜¤¼„$J¬éœr`É·¸IT»å@÷ãÍ¨Ã4€Ï.Í.6şœJP¦õ+äá/Ù±å°½¯–Ğ}rfâiUªo‚÷N1–XLmòÉ5lç×„ÇË2™î6ÂR²ÑwÿØÚ½Ä•8Æw"Ë–IãÚåX“ç`#ùÒØ2²¹E¼,ee±@å|1}¬ßUdşs®V)·šD-±b_ÜGòÉÙÜà5şØöªbm’X6BŞ2{ŒkÛ€txs-W GÈÂ”?`ê&Íz»İ{İÊÒ`ULÂxaT	µj æ6Ûã¦)2*V0Í’ußsí°¦ˆõª¢¡)v@ÁËâ…ÄÑëÈÀeBÙ×"+ !F¤…îî‰ÆQJ<Å4Èüv3p.L°Gâ¯lc­):RÀaÎ¡ŞsZ|1TĞ[Ar&ØÇhÁhAPù=†àd½•„ZÔ;»ê–X¨$2Ÿ`$İe3Dí<K3R'€ÎEÆi&ºAE–„nâgøœ‡(³áT<¨Ï³[BËŞ25{¿ù|Å-IÅÈ.¥n³áRôÏSdASt£âx›‹F®QTì˜ìdîô¿3J#­·™OEI'IÀÁAâ[cÄ‰Jø†7MşV‘«^1‰–Kd·ÛtŠ¨MeÎç·ÎF²ê,ğÎÛ™Ùş÷\Íã VêK6ís¤POwÆŸ jBX¥}WH-x7S4İüğwÔ‚Uã}2L²<ı…p.æ»§W†e1Ÿfœ.¥-3çÈ¹•M}âÔ}¹†Œpº]±İ”ı˜ÚÔ¿ƒ½¸ıÖÌÙêÓ`|ª–mğãfUƒÏ¶¹bÉ0¸$dæÛŸGƒ"u3åhÀDÿy)Õ¹uOü¸~KØêÓ¶¨£ê!µiÿ§ßÄbıĞKLÛhaÑÆL˜CË¤˜Á²!¨ü	–ÎgıÏ^¸Ü =*Á*J
‰w¾ä¦ÒšßH‚ó6d&×Ä’ŸÁ*—„T—aK+¤µ‘Œô®ÕœúöfIƒeEvSÊáö¨Ÿ£Nÿ€|¥àlºœVĞÙñbiµ_gqwn1¥RÚı=Ò2~7Š¶KÖ¡ÓƒŞÿ‡/‰0`fc«ûêqHb§yıîfkÁFùHÙ$®ì9,ßù×bU#è§0oñ¨Å¡Ætt“•<š:A÷\˜ÑÜ¶áÊôæµ3Ú‚¦Ó©MæÑò(~‡¶7
ŠŒ7·MxŠE#ç˜p³R2h]ŠêF“©	ÏXÈ^¿6Ş>ò£¹°/ÂéV²­bã.š;~~KÑåó®øÜ–"Œ´ÍE %‹ş¦]´}s0¢’Jq\”Àk á»vyùÈCêAáXjÔ'8¥9««Zy`Öª®9VÙ©^`j–ºJ©›ø•™…HeÜŸ¿"ù’4'JtH€çZa0#ûæ÷SiG^)²cÆôào‡ÄÀÚ^hòšÙç@±Z_Œßøºİ¤A(¤§ŒPUÆ…6«C L5z#&¨8ø©XDYüË±œzá(NáXÃÀ0jÏl›Áÿ½Ê£’éÀG¸ÿ&Q‘ÍV’>¥]h5ş[ãWH‰]ißt›SÜjlsÎé|ŠWt:İKÜÍI`Šµ˜p)ŒC÷pôC4ãƒ*í`L€È©¾Ñãæ˜êC#œiU¶1 ›mÜ'"ÔÁ2ÎÌròvÆš³aUÈà¡tÎM¢Šè×\Ï/‚Øÿ~A<0ÁÏª Ãâ¹b›öü¯Q€6)zåÍ{‡¤G‚ªºÌÑ‘ìÙ]Ko#…×È©e&÷L}Í?îïˆÚ A@ÃÖˆwµ8ğà]ß#Şì™Oê·…8_^ÏåZ;>k|w£v ¤ÌPU@ÒŸÒŠ@cã:ƒÎ2·5îa>Âù.!O‹Œnß_…ÚÙÆk,™-)’¸ò.ô
ıêfr\Ğàµ—É4ù›‚ŒŠešK˜*áñÔb¾mU£â£Ğ]Š—öX–==°?å@rˆü4QuHĞdæ$J”[í™à¢”`œé414ÁG0)—.ûWp9°(a³‹ã“Šß»£¾BÙïë‚šS¦|ú|^÷Îˆxe‹Â³Êğ	¥¡I
øIéùô¸®İÚbš‹6$õî$9¤?ødİ·‰§šªßN	kdéƒkÎOÒğGŞ¯÷âÑbªk>$’ä¬¸7Ùg². 4³h¥·¿··(ƒNlzD
ç¥ğİ¦xõXØR4fÀ 2ÏH"@‚Yò×­Ïx²¶ş2¨»[Ü@r!TçíkÜ{Šxµ»qê6Ö¬¤JÙûÏôŞÔd	jÁŠ§ÆÚC*ÀæCwÄ;ğ%*°tp[kô7-s?,ÆzñÏs{A]¬B'3FùuÏ’3ÿ}™–»à¬®gÓ¼„ÄA¨Ú²‚q¥•-BºıâÄk§¬Xµ§ÈOS¬½=ünèö¾ÒÑQáéæ[¦ÆP]‡Ïı$¦¿+Üqø-7.=íHË8_tO'|;á¶F0Ö090ég¥?IÎI!¸ğcJoÜÎö‘s¤hšq:È†‡6¤dó"°+·áwûAùõ)N²4;ªãô´`„¢X^å³u×6”mÓœ€s½ù¸Q=0ÖZQbèzô¬mVıwìK0ÜõfU•ì3¯Øš à<0°ÀvˆI+ÌW"ÀÔü+ ø#ãõÁÂ¬âráÑÓÔ“äø%ŞÏV/b¡&Y˜
µ­i¼æbš·Rœ\1@R¹ÿ,©2ØZ]ò¶~ºA²5¶ïu]æ²TÁT~Tz*ç*_Ö¥’±CéÂ!ÛÁ,eó÷&U\Ê“çÖ¯#õÅ”×`©»İÂ[Xö¥.”Uk¸…ÇI!‚ŒÏô«—é³†­½•¡˜ËYc^BÍ…)ŠÔ™3Úñ$ÊñÌ‰IL©<¼Q˜Éæå)ş”à6Š…Ë2EÈS™8¬Ç•it‚3ó‡bª.Ã•t’ÓN•°AŠÚ ìÍ­ZˆXU“õ©¢ØøÅR;Áš¿‹‡A3»1ä(??|¢P±+¹fä{8F*ı¤à„9W_¾?eIzïê,…À±äß¡oùzl¦Õ±íyQîĞq~’=™¿À3åˆ©UÍ‰Ÿ¥»İñƒÂ±F0†¸mŒ(AÒÊ©Ï2z6­ô¨N éş÷Oç7Ç6ùõ£aÎ{íª;Ğº‹h8ô¦]…šìÂY7d{É¡·/Æ_°ëÆ‹‚,]a‡g
¾”püÿs›îVïèô·¥jáìÓÒi7_/ƒğ}GÒ\0úÃç‚æĞR 4ä&§·§Y¦¬uä†=L…ßèÙ\³	×¥Ô)Ë/ıBävÍeR·.Ãû=dü@Õôp}o¼c® åÂR Òç™Åù[–[Çõt…éÅì,TÇ	/PhşÎè—Ád¡Ø3œ	E1T¾b)9
9â¾sÛŸ€Š]]³]úô& sç$Às< –ÓYB6Ò›R…ÅËı@^FdDL£t³m%xá’wÈ§\‰R>;ét )•*0\…W0êz÷ÔXĞ'‘˜?È€k­lÖé6oµd‹qXw7s «#·EpëØU·É³»ŠğMä“Ó !»¸>ë¾Y™OŠ‘ '+ÿ,´/ïº.9=O8xóaàÒÒ@OÄ•™ö
àb‹©ŸsÇ2ûkAúìOYQ{-toî®ñÊõRq¶‹ØşÅ5?ßàvBşõ ª¾$…¶‘Bd¤ìÖz¿TMä#4œ•œælıŞÃÏ¡zµL6o-xr÷¨§&“ újF¼ÅıĞ|._îÌİ­ê]åV­1»÷¡(„E
šKKdKïa˜^ü_KºãÖ¬´`~rıyseæ)…;î zŞ®[1[í†şºçwè):nõÒ/Rcavß¼<Ö´æÌ¦©¦¼ÍXá,Ÿbëá‡•DsWx	ëídO§†h–Áìî²\]£mÙMÕ8g’ä‹ ø$"úF/yX#´%iÉp*øó(>ıh2®iOY>]_Ço!§BŒå—½ô¯Zä­i?Cò44:Ô³®(:@™e@	åfQŸ1ÂáŞ?WÈm*7ˆª¯ğa–ë3¶ªfÁ;xÆ¤ƒI¡‚“ÇìoèF\ñ9“=äHÏÜwD])Õf ÎcA»—¿u¤k0lö³è¨8`×‚T¿ÃxÒ˜Ùirn@oÍ’.s>Ğ”Ò{Ç¬NnbàåJU9Ğ÷ÖÊÅUGQğân*Ç-%ª©Ù¨½ÿU]œe1ú‹Ğ÷r¦ö6Ìrõ6Ğ
¯ªgŸ÷.>êŞ¸I„q…x‹TO´#¿ãDŠãQDàÏe’U¯øó’HQ~ZØE¿?¨G;`İ\hÿ®0UÖ¡VÂ?·ú×üƒØ¤j‰î„" ‰6ú"‚mÒ9<\°;7ay#ÏM&2É^n?A&\w&qó>Å¶]ó›‹eòN¦”ä“ZÚ^eéÑÆJ »ÅX98	‘Ü†µ/XéPeƒöA†ımÌJÀüsŠÜZéSL†€"Qš+61LS·ø*éëğ ¦°E.ÈÓ@sÚRkfÚj¯x;¼œ’½OŠh÷NeÎ‘ )Á²Ğ‹š³’_ Ô‡O°˜!±º%vÃYÒt6%¥ã·V‘ 
‰Po‰÷…ño2àìTûÌäoùã"„…JÂ³vb’ä]“`ıv_ëDZO
áúÕ˜b-AãÄv^Æ…Ôš½^1†¼¡½d†¹)RY¦I»XÃ¿b1í$~kÌöÆô¹²Ó8OKÚJFÍ4&Áù{ô<z¬TDåãÑÕë/$»¢óqŸ¸Ÿ¯p–YÄ¥3Ùô8ESY×i~ŸŸ¼'X‹¾¥ÿÖã©Y¹­‡e„\fİ>£	_pÅYlSé‰^·À|í>ƒúöÔ•41oDC7Ø{8¡¿»¼HO»a+ûyâ‰ª07Y·ikŞ$<òVBï½lÑÍDPZ¥¬©JXÂİ^h¹¬§¤­?†®ãI’Qå/)—”7…?ÈBƒ6:ØX"[Öş!-† <Ÿ=¯dRç—¡'ß ¸ †hQÖæãÈÅUr$¡QÏ]¥Zµ0àÁÈaµ°D8
›pĞãUFÌ—á©íL6?{z$¯fİe Ó˜³•eÆ9U‰Øë¨äšZn¶ù‰ù{¹éÀ—öù®onĞœ"@–jñk½7—Ğƒq»qİÉóÚ'–ªtîú=TŸf%aj+U©¹ÛDO>¬‹ûÂ?Ö}(X}Í¹ÎÉ›ÓóÔa'íëÃZá'âq¼t *‡ñm\yoAL+õ!]ĞMfÕVÇo£P¾{>z s2œğ3í•ë¢µÑ©Œ³ Ú ¥YYÔÿíôÅ~-…(Ÿëå7x,Ê÷DÙ'ÕV\âkŞ—8–“ÁyıF£X¸ğü÷-”ì!êû6É±o¦‰s­=¥b9¨f¹¤2–ÄÕÛIQ)`>•xË§F3óo^Ìx‰S©Bó±@ù™íâ3†`O®G¥5Õ9ù'z²úõÒæ½pHê=bxæ0I2¡¼ªù/OF!&??j;¬¤]SB(í‹õS!UçtV4!ee…yÊşSòMõv„ñË&Ge›÷2{ÉQĞÍ¶w|xj} Ş¹ŠıWøe¥œN”ÔÛğv6ñÓLĞj;$Œ50ûrÌA˜>æ×ÙÀ™[Bœ€‘Í?à§¦…K\;f qS =ûpÄ}¤4Ãa6)ÿ~r¹×6Í1O„æ‡¨Oø¿ı6Ü)ô…</Rï›½.ŸáÏk~,_‡²rvıeË}Ú
Hğâ35Å#˜qµ²%ä'?_N¸SÚ‡E*/´ä ó2¡4¥Ş(ë4—Bàh¸¾ôê)C!ìÍR~sws	àbR’à×¢ü»YÂù¨;$ªöVñd€>'^8İc!5R<e¾¯¨ØæÖLÀ%à¤°{Æ#õºÊ×gŸâ®DoóAÊûÕÌNµ1TêqV41ûõº†2ğ@ÚñhWƒ~ ‡÷Ù( pEøÂPH‚ 6.^åtqD¬€„e¥‡VÒÜ<x;Ÿ[EŸŞÂOònìİûÔŒ´×M„n*Œ‰×½0Áxj(nÇÏ›«ËOz6V…Ş%·+|d¤£t¨K¯û±Ï­\2Ğéf§¸‹T)an°?J­^ùGÕ’ÔF¸ZÜvïÈÜ½j1ØhnIVõCt5öÿŞg.åj½
& ¡}xNo}-Ì~k‰Ó·
?ôˆ‚F[Óâš>å=?Qè/†  ºöCN‰jö–r…´!MôÍ ˜^¼í[»L	ëª±;E7L$—0%¤5Ú€ÙºúÁ3+Alh|¢W3¶Å›TórØhtğı
euXIä    qª+,fŞH² •Ï€êR¨Ã±Ägû    YZ