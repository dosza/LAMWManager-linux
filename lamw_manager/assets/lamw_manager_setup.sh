#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2662007672"
MD5="98357ed45f0ddf9c83b8b07b54182183"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23640"
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
	echo Uncompressed size: 168 KB
	echo Compression: xz
	echo Date of packaging: Fri Aug 20 00:39:54 -03 2021
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
	echo OLDUSIZE=168
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
	MS_Printf "About to extract 168 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 168; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (168 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ\] ¼}•À1Dd]‡Á›PætİDöaqı³Çu8NZ¾™F²ˆ}Ğ3Y³ñ$å{™l2t]KœÃ-’ûÀx¼ Có/æ£ø·ëúO—}uÿ†Äå¼¢6Rºb/SŸÓÆfëÈ˜…]©`¯dBÈU¦kGõÉ—º!Æ›Ç<¸9ßlS¼ø<|º:Ö`É°ÚÈQ	ø …
:ã{§‘¨19=í†4cÚæ@¾I®K™ßŞA—•éŠÒ>¨ñìûÌÖ’3?Ÿ½ÂeXzñ‘R‚ÈqûÃàÅV*P.c=³¡3¸=£Ö$VA^LMŞ±¾±ù+Ûn³)3¶CàS}UÚ´R/l¡Çÿ®7’yÇBæçîa‹»Ø§	ŸÑÓ(°qêÂN
eÑÔ/W±»r€'ğ8¾jîLN< ê°ŠÜ[³¼ı>vºŒ nĞŸ¦ìsÅğâÜ»;6Æ"ÌŞó‰C–ñ¿49t×Qj	rµ}j`U%8tœ¿VÍô	ínÄm×-æe+){a¢ø»ås—öÌiög»|8ÂC@HCˆZ#³ŸdGYïg0K|SÊ×¢OR	¬[E×¼€isë(øıÃ˜™·¹â¯èÖ‚CZöjí(Ğ‰hÄáN,æev©âŞ.ÍÑ†zê-ùÁë‚B>Ç¢m3ÇÒ'WÀõ—Ôò7 o#HÚÂğ1ÅyÎ‚DøõØh¤‘Æ¸Ô~ª•ş÷å0Ë‚ÃE²;¯Œ,ü›€Ğ›KİI"‰k-5 üÂ¦–¿€H '®WÙ(‘ÂWò-Ûxgœ7åT¢Uö¤!l¶¢Fİù´Â,|ÉŠ1˜Åh/+zj£7bQ'øúÃäëã4Ë[MÂ§%r^DÀB ¯©y©n’ı§¢h‹•?í¦_ˆTıÊÄİÔãÕúB¬2¬nC¢ÿçµêÅ	Ûæ]µ±öú˜\±˜Ñ¯æIm”%uİ¶=œeçê”êè?Fô…hlÖu	sz.¥4f³’‘ÑÅÿS]37íøƒÚ&ò2WĞ\Ó
Tc	ŞÒ€=nˆ b¨GøØçä²äòJ_½b2E´ h~
ô–û‰è^ù(*ÛÕ†¾$tXòUµC/:—ä¸‰bšatY\êÌ»îı*“_È<<²ãuÚèˆw´‡.$µõuoĞ>„vøİ}â!©TPìjù@}E*Ç÷p¾©»kÇ—1!%:%.é5<¦ÿ6NU¥'[öØLÚNÿK ]‘<>CÅ÷C, ÂŞÓ‡UutK?g$Ïä‰ÍG™Æâ9p}ß¼q|FÖ\,‰q­ØÙšo=ë¬›ñ¯Î@ÕìæIÓmıÏê–î:¨nMÓÃj /£ú5`Ái-»=¸Ô%½µ˜~(]h-+ÃğOğö~³n*Fè:´}_ÿl_1KE]ã&Z³
Ÿo} uÎ*œºÑò §Q øï»)ã‚U?ŒÍûšÒ¢9	CbÑ_kRç¥Î—u¥>¹pü‰_!éù(n@°ˆ»ºÁVèù¨¬RıŠ!wWŠú¬Şğ.©¸}£{ú«‹6ÀôÍfÔgŠõ+ÌÜ€›W	›ÔM÷·VS™u`ìl~%±Da›V
Ç¿İ´ç–yWqyV¢¼€ä¹»OkÇ ÁPI!ã÷
OÏ5+VsÚñSÌ\‘uœä¬ƒY7.úĞM¥‰&4F4[µ~å8ÁßÂ Rô©R$Ù+2U‚yR—gÈ÷ÍKóÀâH}­H¥ÖÆ]Z$ú
™~±||¼ã2¸¶øS\hÊ¾ÄY 5m«Æ‹œÄı5@×`‘­*Øp|R	«e©ë	üMÃH0÷È†ùv[Æ&gs-üO>*HzÍ¼Î=f#„·O‘Ûy,E?Ö@Hş0Î0W“¤ù’òœÜ~RºrÆõD7aÆí
Ú®C :W˜íq:Šog’”npMø“Íh<#ğTÔ¿ÍLõöÖ	—ôœİš¢3Fç«ŸÑX=mËxİÍ3h€B§Rä]‚»)‡Ö:Ép›¨Ö,6g#"7go‚Ÿœ3èF‡D–„Aekv£ÁæÍ¬íñyı3¶M‡½6EõtEìhY`¦x±CÚd!á¼Bı™T_¬YDXE-/ìÁ_ÓÛåˆ÷è `[KyÃW.vU/$Ò\fÒ?äD]‰Ö•±UÒ İ ¡Ù¤¢©CfCUg©ÉM®\€- 6xíŒ@~;5Ã °¿>s€êµ3ÒI„’Â˜¥´{æÜ”+¡5Ä$;Ó¨”½S®NËÙå•Á:²î8ÍObÙkµÕü;Ëêuë Ìş-2¢¾Ñ
ŒS|ìtÅ}¹âQÕµu,#nÄMì1‘r¨"îšª(â}‹î¬Sv>‡c£9âUK¼‹CôÜZå$‹R§kÌ‰<în#"×Ãí¢KÄıÚÌ+ĞNùì`ÍÀ¡
¡\Í(ë#š¸7<°Ÿk¡…¥ ·&mh[híºP8İúş†±brì´†1“d‰oÎt{´5G¦9ø6°yÄ	=ª#µ Õ#éçög`Ìå®#]¼.0¨m$:À2´ÿ@‰nêá9‹_¼=I:¢ô¼çYá4ª•ö-{jóîSDùKfİ¶Wlıš’u½Éµ<ñ\g$«2‹>[åºYİói+Ğ[œ5m}[Ñ@¨×)a„YûÅ€šòğÄP½5^ûô	ÎJiü“µBèvwZèÆ´‚©ê¼À¯€ls±(ÀĞ/şT&§åm=í°¶Ô4¸ğd[`5üW‰À?iANNNcÃ‰GNVpÌ`£-ÄFÜÖWHÁ›1"g:MEğõVåFÚM†4…#Wİ6'æ1}ßåz8¨ıîæqñ·¨x¢Ôt¥JRKSZ/f+õƒÆÖ{,Ê¥çyàÅ§Ğ-åîâÂ›L1·.h pbÎˆIêÃ3ª¼T70ï¾j$¤ùí1ò7Õ¾ãbÜÇ0à†±a‡¸ìI?ºçÓÍ¾À[‹Ğ®!ZÚkö·µµ“1D"{zÔ€lsĞ;%Ğ¥½¨PjUB¾b:VrßÏùÓT?@ã@ÚnÑş»­‘J{ÄŠeòK9‡šqy[â’˜¨Äƒ.>Ñ#÷y*ê§™Ï0ñ((Ïà‚‰R(A0›ºSiå=\IÒ;÷ÜY´œ“ó/ ²‚_|Ã«}6¨ó€NgúvÜ†,è^šx‰Ì˜ÆÃÌµÚ	w+ ËŸn4ş<¨ ÜœyW8Ç‰#F‡hÌCSTFÍ9ÜÎyl˜µÈ(ë+ŠQWÌkêù*áŒNÑ‰oÍXP83}ã4ÃŒ§3w\›2Š]•ûaƒ^¦}GÑB¨3ÑÖ£lÉş'ît:€="s!ß_ÛqMEÓ6ìy Õ©ƒvÏtè“ƒòÙ{I8G—OÔY<·©~Æ$Æù¹ô±%&ò½Ø°@a4âVÈ6î7š]±¬TØo…Ô…ç}åÜ]ì=TWâ—Â™“ ’J“9šH‚­êo†*ˆ†wGEÉ|:j‘á&ı~Í/wêš_À¡«œå¯©ËN ‰aä]>vŸQ6üğüm¿â¼õ=Q	nëb,@}Ÿcß‹P	r]N‚ãià…ıäX1˜¯¸úáÃàÈç™B#’x{œBï÷İ	ük-ÁòhbÙfeÄ‰@¶ço=NøöMÉp'Æ9jåZ©5[fæŸ8Êom}ë·ü¢#¦múŞa¿öC™)i‘÷]âŞ?´P`~-4à¯¬êŠÚ}ègôgƒÖ ä{Ğõ°d$[„õT·À#Š¿Ü±¼á9›»Ë-³
;à;ŠzÃnq¿jÚ+’ºâãSqÃäÔ©“G¬aéjß`¯¬½xíÆkQBl‡…¥¼0:ãµß¾ô#§¢•÷È2Œ:†²·ñûmß 2¦Ÿ?æÌ¶wkÜ.êÚ$¢üÚP°4Ÿ‹Mkó[å”ç*„Ü˜a~Q~¯ô@"F9.H® ¢¿ ¿S¾³êôÆÛ‘9»Ù}ÎÀd´Ä•+ m‹AØ§÷hŸ—]ê¥yD+Nâ®Ç‹‰™	{–KéôæúÃ%Mò
ûo@%{‘Æ•\‰1ªšş‘;2Läİñ;ó€uàè„Aæ	Ll‚9ñ•hï;“d
#¸·`ñø”(–ÈJošÖÉ-GhŒ¤Ÿ¨]€<é°‚hò†4^ÜÉ^åş(lÎ=G…Èï¨´=}´Ñ>j"ªˆ®	a€Qgg4®õ×²%™éÔ;÷Tx9M]^›ñ†N…¾t-Âİ÷©ó|tP³ éŸa™ÌT©à{}/Ã6“¬ÄQä1Œ4¹rö;€…5pVÒ×íV¢1½40üçûFâC?0i,n-öÂ¦Ö3„}ÿÔjNBÔÀ&T¨¸ó`B~Á>µP†şvL¾}jãK4¼>ìm5m[‡ôÛèÛ1ìï;‘¨òZ‹S—ü†M~Ø«ì6ê`27¶ç¬`m^¶M¨JĞqœŸ9	bş%{”g'IaI<hëº=O‚°ÎvsÎå2À€,·Rr A£€†ŸÎô	DĞhØŠ¦¦D1±¶kÀ÷C‚ÊWàí»4 MÃÓF"\©9€Tı…¥ —*)¤	¼”ëª8ÂÍïáöI5ağôz¹Ë£‡òf¿OMƒòÑÄà¨ä×Q“'Ák³ú­öOôM”ÇM}%§ËJì	t0LI7=5ûL±Pcwıc˜ö4id³NX/“Q{”Ä!L>óHè??«05Ih™BÉ4E‡Áw…“W…®ÆsjŸ:¨€…5¶qmDvn˜Âhª%XN%X‘ŒR¾‚m÷¸×5eäÊ,çû½IÍîr­µë.ù1÷§•£ÃüEÕhÍŸö.Ÿ?Ê(Ü4ÎÎ"ìmM*ğ˜ú«#GëpâÿMX/%@]~hÙŠ2­Ç®šˆV}ì°ZÄvùàg¹IeV„İÁ¤.£Áœ”ÍÄä3°‰±:aÖõQî]ñ+lf—4r:
ø¨¼ÇÄÇêxQ‚ú¹#ÖÙËß˜0TßÆ<ëcí‹ÒÍ“+59&m?""¨Êw'ÔĞv*#t‡¬Û¿)9›"]ø.ôˆ|‘àVÈq×Û¿ş£:D>|Æto»px§ÔÉ¿Åã>øuœÆ+Œáh?A ZZŒ÷· ÒmÔ!'!* 9pmn.oÔåæSY‚~Êb3½Møg¸€¯ñ2ˆÄˆVîì‡dó¡¨J'™®ñéuìã¤Z1â6v7uPŠÂ|¨ˆŞ3&_F¤ÇÎD¶¡3 "Î`>…PJïIõu‰h¶pY0yı°ñ¡ÕŠŞW§/~øFÎw*Ök}ue¸ìVí[¨nAj‹­	ÎM™O”„b~5L€|Cş,œ
ÖÚµq¦Ì½j
ÎX"²¤aBGÎàå†1Éfs4N“Téôğf…ö-ğ¦IwıXN}€ÉÎatz¤˜.…®Ôúã2ƒN„Ö‘Ôné¢nã‚	Ô* mYÊ*VVR.E}ì§‘´+Gu×úR`K‘_|ÉDÜÕ~µ ÌÎí¾ÚâóEå ;è “èÕñr—‰s––óH»Ì¨£^"¶Ê‹ë}ıŸÂÿø«§GÁÄl¤ü×I?‚€8Çê°c=´†êº:è0íæê3	!Ø‡µå3(æhÆS'W ’V‹—@¤q­ ğdÖƒ~o"ê:}ûnCš‹R&ã=r\
,`“QeükØSßø‹Œı;hfüwneŠŸùù)_ÏÖçÇÍÑğSø77oÎÖa¿Ü“x•ºÕ<%¾ûJ9bŠ—Š#è2Ï°’hR¼€L‘/¡›Ò{L[k 
,„é§Tš¾ÄÆu¾ı:ÁMğÌ‰é„Õó˜OwªÈˆ×ıËÜ@ÏÂ§Ö¾Ô_§h-×W¶%¼ÄÆQ×7Dóß3wˆ>§%dz"^œèçqÓèq¦Ö&Ã‡78Ó;){…*ß™3©=èàÈÎ­³?T6¾‡N¯_ü÷|b¢m¡ÀßÂ9MËÊån*îÛÊÙzkB×D«m¨¾«_uoI;ãC”®6åYÜˆ^Á}œ‚óA³œ-Öo™‚ïe©ÁpøÆËQ9æõ±XÿÎ’µ~_DŸo2!{æ'(™µŒÆË†ø˜Qh¡É+.`§¸\j›…”15å‘–±¬ÑÀ“:nœ¤ 1ìÁKN
Å3©’õÃƒVËIjßİ¥­N¦³‰2xp0ì+iøË´ Úyåiå¼€ò+"jŒX¼›ªâfóscZá‘ù×­‚!›è‚é+µYô_s–L‹ Ün{ìAé>¡qÍÅEk3_<2ı$ïÈÛlu‚bNõêÖaÔEÈ>¥,‹5ŸÔO‰RıÓmÿl".C}y‹œ‡>à·„±±FtëË]Wîİ…ù,NPÊkÑºˆÛ—Ç•¿{b>Kw¼¦´»˜Gÿ>iN¤èÍŠ¡·óM|\ñ¹¸ ©ËÁÿ †ØDüÊ,xåë„/ã$Æ/	±KE
¸o¾xcO…	­ó†{Û¸ÌU1"?¬pº‰Á“¢­!§´>ò¹UÎíĞªà·ı{ğå¡OWÄíVéõuÃı)¿`°Æá;|¡6ªğˆNLP*¨#vş4·ñ¥4ÏÇ?Á'¿ãáÂE…Ñ ×c?¶ª-U=_JCóß:X2¨:6NMÚ£ı ò¸¢tg•NHCø?Š¸hğó àr®FİJâü¼“`—²ÎqÀnÏµ^Á—ÖÆKVÓÈ0¸@ªsH:Læ3x•¿(nWå`›D)*1¬ 7°ùrrsQ¨ç”âW85g-ûiæ_>+UõV³xHq9”Ä8„´òÁ¾áÌŞTq$n"¥ğŠ<ıÍ'ÿúßİ/¸¬÷Õ#¯wè{x²"§·›y¬2”7f´œg=¡Æ
@Ap‘´2P%ÌRVÊæÅÀ-ºBÉ›áfİ&W‹ûÎVxøöŒØ‚z>ï¸c†QYVí]<øCd Ğl¼ÍÔ×ÒVóre4×&‰ôv7‡è0xŸµÚ¹É{Ví™½Ü¢wÙb>¸C%¶b_ŠI@KÙCÎËøA˜#Œø—ˆÚsØÒ¬+Å+ËrÄ¥£Råè@P1ÄfË­nö]!w–!²xÙ¢?6Û^×_NµñM
²ô,H÷lÚoV"]Y\«òò´mra§ıÆYb‚Á§dƒòåLŒMê½«\0ÏŞ1\­ØŞöj®•[WñÚn,÷’¼^C¾ÿ¶Ğ©k#Ñè¢HŠ4Àæ“©™ûØdëmÖ 6ÍÂ2vÆ×È•sİ)Íèyr¼Ó«¿¾Yó×†ğ†¿åóB”xŠ³JQ¡¯6Íã,L£‡Š/@ÅÓgâN’Ùv®t(m8pÂwÜBœŠ9¦ô#n%ºªƒvû=¡Ô[Õ¿ÿaŞ¯¨f}A=Ÿô¬è„Sù¤L3]KÖ¤&Hü2­U{ãàX2~œlÀÙŸÓÁ°Ká­´W¹õÈª‘çh˜_¿“¢ÀN<Å¤Âàø'ÎUKzRÚk…J¯Ãœ—o§½íN997±ÕĞâ=¥¬	ÚÉW$5²êç¼Ö¤‹Í•®WLõ
jÖÕ^2dpF¤»
=ğqÉ!“1–cÒÅ0ÈCÊ»{1bQ cØ.È™YxV­MÅ·_a›Î–Ü!ncYX:é0f§ì9k‹ú[ğÀkc¦{tI³ ßtJ:{¿İt‹`&ÔÑ"2#ıĞ:à~“›ÔP!Û’¶¦Zã¶0ª²úhYN#!ÓìœézEo¦Uô£/4ßà–9uäRU„CåÖáù¡m´-ëë4Óqïe¼aÛbB&»‡Õ-é,¹,,½°Lç1-·®ˆø¯’ŒèK&˜$ô9óË×ì×Ø¿æ
³4‚İ¥qûÁa_*e.\ƒÏJúÉUmş®J€™¾ôãZ‡Ş Šb¤ı	âAù—#¤«ßWdò1,kZ'êıJ>Œ±ÿ$vR‚ëÇ8³…STÑmÈŸÿ‘¿½¶ïÌyóFY]]“ä`–Œƒ‚Šëül4üáe'”LÑMÓe>°0ÜäRÌ$xMÀJ‚a7#P¬ÎØ¡ŠZH Gï[•æl‡`-±ªje{	qe!ô)Š}Âñ¼kù]¯læ•Mˆ‡C{¤AYg­œÎİHe±Æ-Ö q„lKo8ä9¯E­m¤µÇãuÖ†¯‰dwÑ‚×óCàFi¡êPÍ{+JPÂš=d,)¾OŒ¬B£] ¬TlŠMb®j÷ ÷r*êò´W¿‚SôùÁè „ßÍîƒs_Ó°¡R$ÒÓÊJ4ApZÍÂBpÁÈVÑ‰ü
óâ…E¶´™Stvò¶Z«D¾ıT½«¯öÒ—r}[¹­fi@"î5$¼6D›°ÙÎ@/«2¨†É=_úW“Ãé1›ùü#ËÉş)ÃÄ—\œMÍ)ZCH´†'ïÃ¡Êİ
xe>´»hm
Äª×èJ^Rìb*À0ÍÇ¨K|QW¾Ÿ/ÒãP[{cë«Áf“´(sŸ…r,€wahJOË.Œ-/ë‘ëbàrø®šÓÖ&×!ZÖ¥]j½yï¡•©½„ì‰m…qLêhº^÷&¼ØùéæA­÷‚ğëtÛîö©ìğ˜p½¦Ğ*¬—‡ö=¿¾ß‹ãV(BáCşú`@ömİßÃ&¿ìwœş²Ù<1¦ı Ëù1Z‘Õñ¶‰^VxAoÙ,?Ï>Ée9I§û/=g³Çß2B	@T)1Ô’/6O"ïÉ¤ZÇ÷ËeíJÂHèEõ¸æ SCîÎÓ<©ûºãàÊ“±Ù®JÇ{ÒUJò¸TgÍ·#¬‘›f[ı÷Y»pB€P&u™9Çu+Va8X. {qx¤îE],³Út6İe\—:’6Îiá^µ€n?2üöp±"şU± OİûŒ@Y˜Xzk§¯Ğ?»ú7_r7µÓ
c¨-lË–}ı«8lhK¾qÅî“ŸëË€/“õ7`5>Œ'¿n—-çÍg-’Lwj9ËdÄ ™Ôœ úJ_ÓÖQØĞ÷áÊU€¨ ¤¡vé†õÈRıÉ}G]6dğì´Ä¹±Kô6Ÿg](¶	¨ 3Ü´T®I˜"´:eMôøW_z2èºéÚ=VÙø¤>Rı+ß? +Öve¡İÎ‰W†]³çğ÷{x	mrxå Û×'×ÊÊnaosÁğwvhp²!/&»¶Â¶^d5¸Ü_>sòÃÙl¯(¯ó•ñ"8É;EIÔÑÃÜáŸ½]‘†·H2[üÏ µhèRbÊñOB~W9ùÕ~ÎC¾DcçÓ?¥%¼Üü ³9æmø¸rÚŒB©¬IU+ÏsÀƒbcÂk¬ÌDıaV€X¿b†ÛQÜåN%JŒ |©úÈA“9ÀJËEÁ3j×0Å*™¦L•Ãi¶8tD<¡a9Ø•J¦îöêPsR
îTõ*H˜Úõ••'€Nì/Äk*t0ß›wN ^ò±­›$Õw™_ô’‚á]=ôğ&Üô)Îª{z¢+Y:Œó‡'q€œ®5ŠzÕª/«äóº}úÖıã$ÏÉ{Oˆ;œl'±ìèZ¾s£ë%Æ -R•u"Ô`UßP=½ƒ§m¥(ïsÒ›Ş…¤(êáü6Üó¡x\Ì˜h=¶Œ„b>Tÿh
0b‘õ«0ìPÙo[(Vh(æ7a[r|fö?•Ø1-n+£ú®Ğ}ã\)@ãXƒäZ—4mÚš…E›%qT“O³0wÿÚ¦öò{=Dü°ë¬IJ¿§e=^âEE#vdí¹ú’Ú÷°ã[şdc×Zñ~ø‚ ;âºA¥Ö~ÙY¶d¤¨:#B/.üJ f–ï¯ş2<à;é?ÌĞà#KáØ¯	‚ÙŸ`‡[a÷ò…ŞDå¹c¸D"O«P7uÌ®KÓqm>¨xø[jÄ½ä¹xƒ	©“~ÕÌı4Ğ;ÅÉ$X'.ºOM‹¯ÎxMRƒŸtŸ-äK!ûYë€Ù„`ûD»wdÖ	=â=u¾¼“öc8 Œ¯²‘Ê¥OPr¡]BXJN³ ¿‚ŒJ½T««uóïãÛk(V°`}DJéŞíz vĞ¢1£z+áğ±UıHî ã^Ôº×œBòÑ`	î8q™…áİÆ¸E· øö-;d”_Ú…c`¥”\Cv%æ¨kšqÄesBj)éÿÉ›R«IŠë.CôXˆ Z0BëÅÚ‰ÌJ¾Œ«y©¨ÖÒ¸º0Re¯l÷Ô÷ÈlewòŞ“¶iUÿù™Pİ3Ãév5Ò1wÈV•_4‰ĞwµƒŠ×Á–<¶œ³º±¼Ú£ŠL¨½:É~MãBİ.I<Jİß1Í}m.ÖA[_H¾Çù2[ª˜ò‰‡3UJÅ®»C”î@e±”,Ée@Kha«Dz'¸¥´-ö–ÇÈ7ŠaXö_Z™‹9’ék:¯Â‰xff­ÑOÉCÁh¿öè©©yâSK¸'=Œİªö‰‹ı2n®A%ğà°@‡pT2y'Œñ^¡]>·î¨0cZ½dº‘Kş¨ş#&~ÊáÍìİO›?KtßŠ4î1r)JqÕ˜#
ßÎª@ˆß|ŒŒxıVlˆla±Ä ¿S|sÀîä×b **§
­Ò1Øqj\bN…­å9öÂx¥¸0Vw>x<òIƒ&åèi‰Àr*–&³n%öâô¨%„—$@QÑ<-}ç³·µ‹6ˆç¼ª©“ÇàZ4O³_<gi«	%4;öcŠ’A¦{­õŠè·Í ’‡Fî;Œ%
`cùËÉ'edÿ¬Cd‹­K¢œ®ÖVdñÙv ] ¡$Ä#3yRÈÜ}Q$Å¼ø)ÈıœÊƒZN¼¿­}/kDóz–Š–.|ju	“‚yUAÂÈ}Š…ÃÁ¦{uJ“9Ÿf	¯ÉºÙ¹à*À4íÌWšG}çNP.(ÁÂƒ!D­vT/ÔªW+Ìı“jœ›HäF nâ´H”lc»w¡d”¼Øm~Òº2Tkû1b—~ƒz«ò'(àñz¡Od§\}—•W"f÷ßü²À¸Äp“¦F‹z
¬L:¶™œ·¦Z&œˆ^[ş:å¶İUåq›÷Gç²_Hš‹ÏÚLè õÿ¦/Îş[vŞq LŞÕ->¬ÃD­”3Ğ8ú9/úg£]f6_àÌmOP‡‡À ‹ â’bw×ÁŞ&¤£ßbRCoë‰¥°%=Éë{6Ü¢¤L
UIAğÎæo‹Çä•Ä ™üvâ}NÕ_¿vß…Ê
ŞEV»%¢ØBĞa¿¶÷%¦tTöÚâGŞï”ò'9å_
ÛŸağï:J b¤¿²H9ÎÉÅ—•°ºgş’ZÈîš0Zpªİ¶Ãa
„
VNÕÉi±+V k6Uv'¯8S=Òhs¾ı ÃcV›˜ŒCÖ©OiswLæö TÂÇø­±®é?†¤ÿE,nU‚úcÀ”<
İVW©“‡Üÿîš!øoW„êÙ¼‚úÊ¼Ó5œTK}­‡*É˜YÈÕµş’Ó97£Í“ÖŠQ¬ÄËüo1Z0x«ŠOÅN>¸»lV%‚I½LğzR;ãA+ø]ÉHEèK”"Ê,uSıh#‹eñß/Gp±í÷·#Š»=$âŠ¿¡‡Ó½î«°ªstÅı<2ul>Üé‚ÄÔ,Ì:ñÌQ2o.»*€\:(}ıPâèº]wÉG·ºÓ
²‰W‘¡—Š1Ğ¢©‚‰>_P­~»äV‡!J¡|ÃØâîMÂƒtÊĞ•ì¤ñ+~_÷i ÂòÁĞÄ'A½‡hûâƒÿËİi~³í{X³“ˆì¸År¨^Áƒ•:ÈÂÊ÷×Éû'ÉÃ2Óå	—P“)*ˆi¡X¶hÚ•ôÁœÇìf×>~¦£›çğ¤ñ%” ¼j‘ŸV=ĞÆï@ˆ»Î‹ÁxÊHi6ô½99w£Ó°-™«óÄş^—’H†‚Á²˜û6†ê¤*wu
YÎ¥FÎ™ü‚cÓ?Ø²¼\RBÕßsõô‚r£S'Bj¢M/WšUÙ¨‚•tˆ|_•Hº.-b¤fCYC8v9Fáf×™CÀñ"–Jg~‹ ´å;kë©Æ÷¦Vi»¡`Ş
üyzGéóá–¦Ì¶¼h¬8áG®é:æO?¹îpèg¸ËMËÉ .N¿AZŞ©’°³ç;áØ'_Ô<Ã“·è“Ò¾ağ]A€0‰æmÁôY*ßIÂşò:äA˜óy3NÅ(‘5Ì^m]ƒrJì:P³âÂ:áRa{lõï9ù1Æfgkx^xœˆäAèsMßñÏ¸Àq½dtÿ™ÓlZ4£Ÿ…â^ÜQÊ ô±ã¤Ì&ï!#…‘	v4>ê‰éj3Z»£Ç)¼£ä“ÈuCfiZñçÜİ'ÎzS~Œ0ÙİQ¢âd…öz3c.F:cÚø§ôáŒ†AÒtgº¯t.Òo7ô <|…ƒ¸@›	FË'²:­‚FĞoDKÈŒK×düå@4-=}hâl#be››Ä–’T[£ƒ òÆ-ô×v?az#Jâgzi…¿%é®ÇK*ş#´‘x„ÀÉŞ¿æ÷½¡ğ@Û\šrÀ
äÇKT0ŸI$nO™”ÄXÅFkæï:|4üqÚZô<¢åÂ œ‚ŒÈ,ø=b;»ãV½v¨mUU&Y#úßì`Uícö¶ú4ŸS®‘{Æs×ûGÁlH¹å³>gk 1#F_ÉËlÄ½írÏnmlé©R»¼#ğÏ¬Fı¬"ÊaÔÿb(yÇåe›w°Â…l’Ú÷—cùŸ”xìÏQ…aøƒ]•åßÑJüik ±´T¬/Rïõ¾ë¾à%uşç:à–Á	¬gJÎÉ°Ì–ÈŸ†½}óÙó¸ sÄç¨‚
<2æsˆ›Ä q 0Dº
ºİw-0¿Q…¶]ÆÀkVÔIÊáó²©F^]†Å]DgÈÇ¼ç<¬[—•MÂ]`ßOSŒMu¾ óEí¦€¨Mä†áÆTÅüŒèİ+2ê¦TÉBv' ˆLb¡B}Oí´ãwM¥AĞ8÷/ï)¼¸òÂ_³Ñb<@5£õ‘ˆq›³ûH1ÚşŞĞ•üğJ­6Û‰ğõ2Ëh¡ÈÁ3¬XçÌkê‰Wz—ùûnBˆ¹[N¯%‡è< È{İ©|vA¡`{Íªcá+ÆãSn5 /¶`½u«ÔÂõÈä’‡ãõ=EV-•v"AZO·êú®¯Ø†Øªî›YÈ~ZÕ5A]Q-á;]"jö«NZäšüâ(Ÿã)×íj\ğ-ªe…$?Ğf[¿f8Â.bø¬ñ4şGõõW¥­~Uã!eëvª/æ€)í$Ä&%® ñ&"v©=W*A‹À@eC
	½ƒˆ½²›t‘õù¤Ê¨W °P¡ü¤o¶‰bNL¢‰‡·¡”É€„i70]bÿ«‰Æ-%ÊµÊh¹K ªtÊ
ËÁíßdãDÍtRgâQœ„	ìô¿2æì /«0i“ËÉá  n‰”2cƒZ“ªáó¥Ï˜Z°˜brğ)BÃ ÜÒ-]òª¬u¬ŸByzÕéTËha‚TF‚°E€Vø>†3.Ñ°÷Ñ`æ¦µ`L
³c¶ø.@ÈNëÓK¼áæ>\Ë¹î¦w’İÃ…ÃdË|_¸õ<z´Ï¥‚lèµF^}9Î$÷™C¦Ášwp'“¸5…úÉ"3ìmÕûÖë±‡úåÑ rãG¨×A´W¨Uÿ»5,³÷!Ù)™²mÊ_‡`¥ë("mÑI^»d*ı¸Nkõ,±{ğ«”ğ7HÉ¥Ê]I~™Ôy<n?iúµ¤²‹¯5x%æ#ÌæÔ}’x¿ìnow¤} õ’¿¸®ÎıÉá§Fê¥è»ĞÃxÑÓB¿4uÑœÉ3cöév·£jKÂÚ¦êQûU7Ò¸n†¤£Hn_Ğ^|p×F8€f9™´:8Şùì5îlİ!`Q£X‡,€ûb‰¹œÁ¨I©é9»«–úÑX
«Å)*,CúĞâğù£T½xÖÜLO>øõGrnıwÓcÊŒ8ö]“UÿWnõ.±P¬¹õé^^·îœYMGÂü!‡/‹ÚL¢Z	i³¸X¤ÅÅ[ìfÖÎc‡Ò{Ü?£PÌyÎ»îUç%ï9û¹…UmQµö3Êdèãó¼‡dµ_c)˜!ÄJ\$¶D`±%A™–ôP¾A”L3ñÊñ‚s¶’æÔ3UÔîŒ	šÜ’,1´¦&÷¡×ë•G¨%ä`«¡D‚´1.b™ÎØ?†.¬wâ–‚`Y ‘‡]È*Ë]À8¶@î¢Ãuî*zq5†N)¹íî€ûa³cÂÇ"¿Ô‘äÂŠ'‰Ü†¸•7¸cÛ	T±XÊœiá¥7„*€ã&áº‘½±I 2Y‡-ÿ4›™EG>w,^ïú]Ïá~[Œ’Ûqdÿ7ò#c}dì©³¶ì%p0áI:¶oZÀiÌ© Êà™É˜fÓVÈ¤¸"³€ÕİsÙí¢83¸Õú^ïh
ş¼Ş©ì=ÔkÅ°²‡_QªÑSÙZş>-#]ÆònÏïSàòşGôË2½|ÎÛo«ğ(5êmuá¡İÙé×­¹ 5FÏşÿ:ïA†;é¦IAöR'%ó—î›~-ı¥uye)E–ıqíÙZì†b_ÆŸ™ÃpqÆ¤;{ã‹*wıÊ¿qRë54xãVıu™÷‘½+û‘³cŸì,¯ÂcD!¥®“'ä|XAÛëX®³aVtz"> KªBZ|@ka¸¿¥Ë”\e ä³ZH)‰«ªâİõE[>îI3dQ} iËªóF^ä6>¯õ¥ŸûCM	oí[k€ê\YËÀÛŞã¯lè«EôhTÊbï¦¥:¨?32cßœòYh,$
Í‘òD; œ>ÜÀÈ|gwâÊ’C×,¬O “°åğr{’‡ô™ğË>{-ö¥O8„%‘—ûı\P¶ê"5Ë!Eï~Ô°'^.5ÃÚ·ºcJs²ı˜;öM”Í5ş¼¼d Æß†¨“ni¸0ÃúxÎO+J±QÑú™¥¼MQk¦öcĞ5bWş 9W\V,‰’Úl0ƒÇí®ñc€ÇuúFˆ?Hå{é§™U*Z¤@=a'{Gœ|$Él©~ÁÀ¬Ş/VŠ¼¹D†÷<ÌnßJì_2€ ¬-üLœˆÏtf%7Æ¸ôHCXQ@İY)yøë±^?P¼V.ª¹ñäMƒ NÃLy¶›Eˆ“6ÒQ;m!sw­â¯$z_×5ÈâÁéùÎÚ;™’ áŠ"t‰œ¢ûÖ"aõ˜Ì&¦Á+#•¥Ü#épI¹[{}›$<èÛæ‹Õ(Ô§ÃÍÃlú°ó}÷( K“Ğ3Ğfˆ÷ÅUWĞ#äu×€V&Ïhj$µMÇ‚ƒñüe>ÿŒ¢æsõßî¦Ï)@1=£L’Dôd?z}¦a&Š!Işîº&;ÿ¨P$D0†š¢4 Æ9Ukx—rLsÿ7ÁÎ‰ô©eØ#ğôLYÄ¼~yû~ˆe/)$Q8®°ÕoUT¥7fW? 7²İy´±<
qÏWAó+Ğ%_Úxé÷]®q`éÛU\—¿4c±«®Û¦'ŠB-ÇY÷ãš§åmÀ§ÎtN¯[u;3Ğé©4“hË€ 
BÕ}š®T8s‚+8ˆĞ[t ı…JÉÿMã£M[‡8à€w¼í8©Œï6 ã¤]íĞVÔõ_ê•Ã¥@¼Ó<ÉÉ •à‰¬Âgî@Ü¡t 1|ôZF².¶àèè=³3Çš•NâàÃU+<[ÑŸYfNp÷¤awsk÷ À˜¦R9¢1ş½Ô-ï²•¡¯ğòí³X"b¨#8j>NHôf%Ä²mÔd8ïfîjhu‹©…/X%½]&^½y“!·ÚBÆœ’m„”ùqk#ÉqØÈ;×§ªQÊ˜,gÒ/÷¨t‚XÕnü.LûxäJÀmÜ`îÄ2Hè”( \‹ D¦ÀAy,:mCíĞö8|Rğ	axK k«Liª\o­wê)”^šñÌPÇ–:É=ó–ßË5Ô–uÒIew²‚ì¼bÓ7^Õ
ı;ñŸÒh9jş~' \ n®Io%s9Ù!ÅDlL¾ºşóÆšÛ{®hPõF]ğÑëÜqÙ‘ô”Õ®„:¾|(aÁ$¶è3SRÿ«d·‚s—¿
§ˆH»^’â-<íÌ5Úy?^ÑáğlxN~ëôÏÀ‡Ç{º€‹Ï³ï}vl­ÜRom1_8úW5ğFy6ç‰ ˜§WÀRœVÒaê%Bh	aâ·«/7¹“dµ6]ÚIï½©Üõ=›¹°ÔÑZİÕÓ¬dQXä4ôRï®,ù&¥/½İ‚*z-¦)Uó)*z!ä3Áó“W^„i|:ãÅ—*°à“»Ä'`Má°T¹ø—ÄVh­–*ÑBğr•÷÷¨ş©I½ÆÈ%¼]VÉş	şA,-QÜÿï)¯$)CŒgy±DÀd÷¥©dî~eÑ¦ñ¥«¶Ù#¶*è©²–·~¨õ™çsUƒI·œ·½{h<*ÓÌ´cåS&`TN :.c„†lf†p~ùÀ¼Õ<BJi%™ØXKìI¸¦*%*1ğ…¦–†nøYıøÎD[¦“ï»äL»gô¦ªnÚÜŸGã¸Œ*·ØÂ$ù#Œş±ÃK¢é¹|½{èú/:,IŒÛ] _Ws×¹Eâz°n|™œáp$3¦Ã”<[Cîr•À¥ı™Gİ™ÕÛŞD{uleÍ†¨Åªùô›uü«MĞ¢M;jŞcc$ğ',%«ª5õWN°İÈ/“ß¼âû·.‘Ë©z#/ÕÆ¹—>œ‘^Æò[Ÿ#óƒ{Ê¿Ñò¬¯3SÃ`Â[3vÚ¤šä#'õ‡ÁåŠ±ıï¡{r­Åfë*„À6~ê¶¨´ìø^Û·¼f7²Z£uÑæßÃvñn¾·Óï6îWïK§-,ÓûA¦Ÿ^Y’u	âï)häµTSÅÃTHoë:²gÄÔh7A6em«,³wP™Må¥¸»[#F°åyÑÁ²ó\8ÄX=¬R–º ÂÏõ±ëÌ°0&ø>Èt9ßîŞâÜÎ™Öâß»”£üåÙ¶¥AºQ‡Cì.|	{ìÇ‹#—A1ë–œS;*á'Î-õ›§²:-Š'nPiºyªû£¾—Ù1bV²øh¶³e™í\5‘7”g8xzIŒ)ÑÒúc§<Š
¢$™Yíø”Ïô‰xËÎŞq_9†‘µ½h*²E—H¦ø_Æ(Fvn©ah;ûâÛ¦)cí}î÷êÚ}µTBhdÀF<Ì
#B1¸Å}§6U…Şf™Í˜€~ÂmdÀE·B«UC&ãá¹‹«¿îèĞ–ÑäR°İ=@ò:Áº“`oÍŠGÜí…%B_Æğ¶t{§PmßwõÛ#öîØH~SŠi;x!YgÇ\/âVTàD˜Dî¿{¤Ã~×½(ñÉ¶ÉŞ²H–c ú‹´¯mï‚ËÖe­Ô·'¡È±ËbENÖ³:ú#'å)× ¹ë¹F¥3è iñzÕ(ïóèpšÒvC‚~ LKÆ?n¹4gş²mìoK)İXÂ@]::?«ã}k‡:)w,LŒÇaS ügl»(I<Îİ˜	u¶‹P†ı´ïõõİ®Ò¾}W7+–Æ“Ä6Ó‘”óá–ßĞ-õùQ–8oŠÜuå%ráz—FöA†w‰gFg½Y²“ı¨[ Ãaô
°ıï†ç¶Ü(¹m¬/ğfë”À2 {pÑ&‚²AaA¦¤Õ<Ş >¸Ô>0ºÁoèW‹{åägI\~÷ÖGK!Øh7¨NÙØÈVò:(D(Û¥Iéy¥Zc¬säBu³JÔôï«¿ğıjÎ£ÓuÜäeµ÷ŠxtBœÊÀ“\+vJØ/–Wp˜«E‹W…€¤œ‹şllœ%Å‰©Ï`½4÷Kµyï ªî('5X
ƒğ)B‡d1#Ÿ9%2=\5:öíQK6F$—Ñ(G’˜H®– cäbê;ó÷vp$«
ÆD“Yh„û’Õ0q´Şñ‚wÂÈ„6³8T~|j¨<Ef$©zËÚÀşí¬@ÅFæ_«¾µªüåãÔÈ4);3•ò£RoÙÑµ
±¾o~Ù¥¼ã€m2üïo™5Ä/?á,ìÉ
Zü»ŸÖ"Ókğ¡Î>Šˆâ°"à©¦ªÒL·1ÿXã¡œhqW
¯fÈò°®<­*ç¨ò3XÔ¯ùâz«1„©nuôÖwéÃ´›:¢N÷z8÷!g½¸ııÿü& à¡ÿWÒŠ¡Kß:,éa
dm›lÕW#¢¤dç6á‚U¾èËHM‹ Ë	´oAÛ¯Ç~ÕtŒ"YTñ–üuMyÛAzH¦4è|9d×7dÂ ıäÒ×FZNôµ4Lè}æ×tZİY0C]Îî*—ğü±›…Î_™}wLöv)EĞ¡•û‰§'Jo·!µÊôGXLŒ8Ğ %›28Y¼Wô¥2-óÁÀÀéñ3‡ÙŒB}©\¼ìÂ$ñc'ìÃìá!#m|v^ãQ
ëË¦´È}¦í& df%™Ói2cvÁ¶œDR#ÓÇó 0.wpµàî!FÅß\øÄ¡R}¾—«Œsî<Á©X?S¿PŒÇtp2û•jPËß³ 9’b(É;ÅJßnü¦?³ø?ÕÃZ”Ã2;m®µ*ô¡$.Ô›ñéNjÎ”gW4×W(™Öê³ê4¼	îÑÚŸÃ5Oè6âkI
>Xdˆ\‰@–U†¾úûs2¡šç+JÎÆPOï
©Æ»¥zŸ)ó‘İñ:=ğ&’®®½Bøœ8`¸@–x®aT,nXáÈ=v®û˜}\Æp¹eVâtó†’&&ÃİGqÛ=R€finú£ã-äã%†Ú«:°YŸß¿e§É‡Tá+¥EßU-Ä~p5ˆTÍ²ÙŞ,|§B]f í"Ğ÷N7Ş¡6té¨Jî3hI@²ùQ/ıŞ‚¥X-ï{®z;ÑbmŠ™+qv!ÕAÀ ™#”a…8ÒùÆ+*„•|»os/8kl‡Yøç!ƒºŠI`22ªJ4Ì'sâ*èXĞ ¶%~#Q½ø¦óY„3š}ËÂ± D)TIÌA¨¦yöJöèøG¯6›ˆöA÷/n66à»Ïö 7pzÏ‚ãwkŞ<‡'’ †%,Z>Ê¼Ésé•½R’ÃÁ«Òz½‹ğ+‹ª¦5«Q"µ²Ÿ?ğ–³SC&ŒşnKˆWc>3`0
İl{¸ÔÕ``nù-ú(Sµtrï
!»lš?ë^‰ä!o<QÃÇ5½à!îX¬â¶ôDêË0-3nT¨à={â˜R¥?ó>ó‚G-øP/
·‹Ÿ_á&°à¢Aˆ\~òà¹öCÜ=©ß4’š÷U£VÚê÷³«Šîóƒ²óºÓMR|òÈ¿XV:­,IK'­³hq¦wœÂXen&á–	šJê0´Ø'®²aâçÛ`%\'3ıtt~>^rö!Â
*/ßÏà–®º*0n`ü|·
îìæ7­ê–ä#ˆR²Ÿ‹—» 1¤¨7ÛÃƒÔÍÖ*Šİ!_ş•Áüa/V±~¬,bcúğÑñW:°R-¥DÆæÍ5îz«Íë	ˆ€¬%KÚT#ì2Öıu­šßŒëI—“ïü`t(Õ‡QÄBFk¤¶"q*Şvl#¤Š®%VqÚwÜo®ü;¯ô¶ÜG²Â£Œnã%4^»_ {6Ï#,,!i1~Ÿ–ÌíóşX|*f¨Akøà±•İah¼hÅ@à.Ù.i«sÒIY/'q×0Şt +ätÅiœ>;§Ù)ªkS7;~2gH}ÎšQsŒMş]R\_°ú˜£WË©ç×ëşCÒr"F’ÿrãÒ?EÅ¿u‘İÚ±úfçá‹•×NÇ 	kÒNÌ"[Òmê—ß¹=@¤V>ıÛY÷¹±öúø8|QÛ8MA™l¤]‚]SÓ²x÷Ù¤Èú”ÔaaZ%À]j¯Ştò›ÏVFÏá1P7xÜğ°4u»^?JCŸLöŒ+ºe7ççj‰¯>$SïI<ôVq@=
v¦‹]
æ iğöT‹™Åa¦ÒXÉ‹Y‹ İöX¤§;åßs<¤\_Ü1óa´„vö„õäşL÷—ÌòöZ<,ë	¡İTm|¦ãÀ k6 ¿©r…¥Î1ù,½qîà5Jp9+C¼Èu•¥¢&wÌÖœÍ½KGˆ`àÄhufâÙ`Z ò¯-úd·ÆP	Uµ*,ÛàĞ”ûÚx—&.Pjÿ¨HïzŞ”œÒh»jüŸMÃÛÆ;|j =¼õ'¹òİ`ÓLóI7²ÛXÏP¨T©¿3ØÍl>¹µ£O²½_‹[z±ØîJãN°ˆ;ÇùxDmşPweå#¤Š_<EŠÄê‹mÆfÕ«ÒoŞW¯8"ÑÂáò£ÚØcØšcˆI0`„%Ú“rï£Î,Òê›î"Ûµ—íËĞ¶ÁYx'.˜Éí)2Æ³-Ô^@n‘Æûb>º“ Ûæ”ö%§0ÿ&Æã%M,Œ0D1T¹º4yÑ® <9Ö•x[«16—uPG¿RÑ~røÔ_<9Ú-² ;êDz*c;"QÔ¯ÊÊ»™ªZ‚~ñ‰ÜyO.áYôªiw–FÈÇ•ÖÌP¯¤3z¶K¯Qô€%ôôÏß„AUš»ƒ‰~G$Zó³ş%Ï‘Ú<kïÂ=h?ŸOÁ§?ÈÍ?7x/\ò~RO÷Ä_à¹h•øÇ·7¬§‘x`¿®2ZSàÕ2Yç	O+>òc?N4÷ôÏÛ( äj¿×O? r>Å@¸
J×QÄ$oËØDApa`öR„Ö/Ñâ£-nLbvÛ:ww<NÊÈ#:Cí–W ârHå(ü	aQ³Cxğ«JU„SH"2š:wYÏÈŞKJ<”‰}YŒb‡ı¸„S[­çïçªq #<ãûú½Óü*Ä°ûøœÉ]å3£;¦PÎT».öÚİ5Ì`Ò÷éjßúX­¦…–3v÷ÁÇãò´©ñ W·¨bÍ-Lê{Æ¦K‡pAn‚•~lcFY)_L»haÀ”§åm63UøãÃï>fÓäkæ&~Ô×DC\ˆQû^å:KõœƒŒ=O—™ÛmÈ÷r†´­'ğ6Šë›Ã¤C½$Î‰å¿^gSgN[jÕmÍf™¨²¿U‹ê7ú»Ğ—lŞiJg)!ü;~ˆmˆ6í`V
êëôM+“ÆË„È°çĞ*íg ma1ß‘ÉÙ“×j†¾ÕR¨¼8–
 x;çNAX"4dÔ__Z;å-ÓTy4	THMÔ®sC„Iôç’–qÖéY×üloŸÚf(¯<eö_d¬Û4fÓé-ó®5ºOÇ²tH}+ÊÓÊ,å°è	Í‹¡<n(|íGÈ);C›…}JÖú…jW9ùI—‡ª-‹X	m×ë	i•ú€#mÚWàƒ¹™EÚ
+)De)I­T±%A×'M›E£*Êê,§%^µœ\^"Z¼{BŞ"xòİ¥dh<Y•
•iPr½öº`au]Ÿ\Õ‡.×Ùøp×”ÎŞdLGVlÔT'¥v¦ÿ@(¾`¤—2LH…¼YEòDf2ÃèóÑ(mîöâ¡Ï{Y”ø`H)l	yˆ¢ZŠ¦£î½×Š©~ZL[™ƒ4Ìˆºå †¹Òwä45Š!yi¯C|¥Ù)İäÔÖ)AL9z²«R±ğA—!âëıàÓ‰Vóy`\P´UO%á=¾M‡êà3ŠÕH:õ>ò9C›ü{@î>º ¼¼sÒKÏ1ÊÄ¨«p!Ÿö™1¾*äS2Y ûéh·xb×³JÔòº«¦Âàü9À0f^ŠËÏàÜŠ]}>?~Gˆ‰’q|”eHª®BëÇÒ¿P
[º`äå—œ*ºk›`ãwi;nK¦40I¶Ÿ²±¡í*ócˆ×j‡Ñò2ÔaY»…èUW!~ï·‚Ë[ÙÿÔä[YKMŸúJRÖ”Z_0Ì‰¡¤Ôıåy%9ÍÜKRÏ–,aæZGsiÿ¿Nù÷ŸÌµŒ;™>H`o§1ta¶¡„w€ûV:}$‘™lşğ¸üC[Ê6sµó_zµw}„ÕÄC,LÿYQĞ´¼ÿË/ÀE¨Îï{úR«—Í}}B¢Ä$ãE_®Ë;{Nù¤a(,ıgz‚Óö”í÷ïoE¨œ˜wÛ†Ğ”hyïäÂ¸X 2ÄA¨f©eD¢™ñöfŸ?;![ı~DaU§7ª0é%m²¼jæu@g$õ½û‡âš 7"¯¾È>ñt«W=úŞ_ ~4ü÷=±hSÜ~€‹.`"kÛFÁ”ø´C±aÆÜ7—JŒ’ù¡#NÆ@¤9ÊÉïõ¼n&°ÖÌ-Ã©~U°ÓTøãhò¨«.ğb’@ÂÌ±Ò®EtÒšG…{ô
Ä)ÉZõ2ãZxƒÙ¢¹Ø!Üö\0E ãëA6h¥u¥Çú–1ôë¿õF–E4âÙgAÈé¶Ï7£?K{tó~yªÑğvÚl
şI#	ıïeSı¥K³KÈ»Ò+ÂVµê0aôQ@©†J./TCÆ8DNT»Hã´ı13Üx3àüMÏÄÖ^³BhFdÁÍù[«cÛ¦ü\À&¤-8<_^mµ(	ÈŠ‡ó´ï1¨Í
`©¸`Ü¹t3YşŸû£Æ¶+T€äã5„˜§9tŒÿ©~ë;Å‡ñÚlø2ŠJÆÀ4´êlèh|‰/bä³_.Ò‰#ã³‰p/‚Mc¢²•Û\]ÿ\?b®v%ádõWo§[Šp•˜I?›kĞWÅwàb ĞÂŒ-¨òßXf&‡—*Å^”¨·pÕt|%ıd€sWŠq­¨º6ÏÈU„Âb‹ñ]£@BÎEMV±ºÂõ]Š_,ÌÕÒD¤¶ÕDûüG VìÌ­Ø–n1?«´‡’xì…Ñ73N›äâ‰Æ|TK-ô*í•eèè·×Ö?•Rh¯İ>Ê}&*‡``Ô#‘¸U-}I[æw4—z{^7W*1äÉzóøËf§r»q®¸¡ZB»ÁT’£š¼2àëĞíÏ˜P±ı4pòl¥_-_Ğ33»Õ¹œß ê)å¶øVÊc^}1+u¬ØæÕÁå¡âºj«Ù«W¾‚-ò›ì[à_‰IÂWô(¥˜;OØ\‚‹K‹ry/Z+àg“í{Äò»Ã–
Ñ#6šÃUğsej¶áÍíµJ˜/@;ÆrCaùÇÆ™ü—¸òiC­†oWÀÑ‰ŠÅnêÅ¿Ô‚Ñ+ô#é¢@xfK"ÿO‹r›¹÷µ®fVq½¦9ãª×ß¿ğGÊğß¬ø>/à?wÊİO®oOƒ¢9Ã¿(´—éÚ’ÎˆFÆNyéDæÌÒ…ğÍú®6qotÌAÊGH«•£B5nù…÷ö…s¯sÀ¯¼ÕOÄ³ ï®Ÿä×3Ø3şsEKKQÍ:İJX×ZxİÎk(bÒ$'›÷Ïıƒ;›¹—N”áÌ3.uÿ¢LŒc—EdÛÖë1ßŞ‚öv<¸Û(-ş¹{¼­b¤dØlÁÌ8²ã;CUõë¸1À›ŒæıÏ÷‘¶»ÑƒÇgÇB?ã#Á¬ËÙNt-9Í|šI†_ÌvtdV€s4W:Á…¤\cG]î1Ğ—-4ú’;¸¬çÒ]šø?ÈªïC²@
H~a^#Ù¤Eç¶)iIƒ}ÜÀC´j¿9K¸ÚäOÌ3; —L“ì¬L.E1×ZáH›øzÇ‹QâÎÓ@ şiç!ÃIñÅzî3Æœâ)şXáÁ½%_$cÊT5ª(ÕÙÉávx@aA§‡¯`ÔDÂ,É|§’BŞ¢…bæ¹ä=ëoÉaÖe#c½aàºM¶†"/œ•-V4ğ®ÑhÙ¶ 	0ï2&I„oŸÃ"|Ú‚°ğ+O#şPf·êxf­
×, Ş©9Í!|Ç2ÑÑçVâÒYÖ!°¶œ›ıœÈ-tFWéÆDóé`
„öÑ³!
ˆÎUœ±.BÂ—‡ö™×…€5¥\M¡°ƒ\¨•ô¹dO¸Îßq†j)õŠÆ)mØxÊ/õ“~«²ÑØ»8)SŒi2¾I.ù¥KšfâR.ÀÿA:Ù	™ì@Qõukdâô]íqı‰QÜÚwXçĞó0p·X3hwèêy|ôéPÏì/ÿM²ÕÈ³z¢Êæ~¬Q¢„¦º"v`ùJÜ s`âÑÂ@»ypğòâ7K\!^Ñ]wM¯~ÏÌcIã)-÷Š„¡êbZ:¡"öäR¾}Àbê«((5¸–ˆşÏîT6Ê[°Ñ7a(€Y9Ä¼ÁıËĞmFèŞ@™3ŸÃÂÒ˜˜Šy"Ğxä.h±¥¢1ŸGéÊÌ­®T¹á:£PaÆM?šıól$%Ìe%eŠ5Îîİ ş'›h·óV®
¨}o’+¯Î Ô—xGì,üni¯	)ã'›ïRAú}©Vû_(›ƒãf5_9PQÔTÇ01ò1Ÿãì I÷O=€n`ÒÛè†3'ºÛ.dçì\%‡î¡ „bŠæ¶<âÊ¬¤ñ90–Dûïœº$¦åh0Cşl¼]Õ4#Fxg¶‡$±¬¥”îÛu~àt?ó.‡TRğ!÷Ú©Ì¼f±ÌÂ\M‰©VkòeÀúæ}Øˆ?„{©‰émªŠ£ñù	gŞóE©Q/¥Ìş-[ºTÇÛ	ƒ›$\r9áı½'¸F:ÑTv³UÕÖè5«E{İ4J=9"àµv˜hûiÉ}É8§`N§aN‹2ŞÄjÚÒ€9@Üs»Å¢>šcì^2“~ÖÈ~GPof5Ëo™¿öóWo²ÕëòÎ´ü¥‚Ì<4„Ä’Øù­nñƒy–3¾»ÅcŒ'­Ø.Îlç›ïŒòa–D’ºhI&»µNQSÇL.-æA‘YÂß¬ıñífLÁOiè3|õ¾µ5õ^^Ô«ú‚P<CD²%ÕßûÎ«bŠ#¢û¨üÆ`¤¤ÒJ6£1Çbğù\%‚ÅÅH í¿dç`œô‚‚ì[®ZáÔ¼ËÀœCUt™Óİ¶='GìP°m.çeÚóÓÛ¯SCÑ¸f·æ§Pª@+øR@Şáôk™ØÓm£àI@kL
jCÑ‡Ks"Û2gÑí‘C°eiïOÏ…?úGú)»ØÍ:¡2ÕwÒjüK€1¡Çód»ŸÀÇ×à*$Ï&rv²v«áDM/À¹<ÍÇØË'¤5tı:e(
³[zìÎl%—TségIIä¨`v[0;¦müü°!åØô¨ÌM‰ƒŒ=sÖ“>Ê÷™–°,"DàãÙTp1­ÀŒxü“!© ¬Ëm½ë>D!±(
%m2×óDüVÌ|YÓ¬4{ï«Åg‹\6–ÂÕ¿¿é¯D3nGåĞµv§¶…½ÆTÈû’oFdÅX¥l,DJyàD`Ú9[½=;5äß{1ÀøivòŠ97T7Ø/ŠsãÅ¼gºó‚ú°HAB*ÄVò[h,¡•äbF°+x“~C
*]©ˆa¢Ho–D•@Ec} Õ;Ôm=™zøËzTÿ×”€hK Óèu@Ç+TÏq2šwÍíè’ ¶N»OC)ºtÜî¶ÓÈ9Éı¬}Ÿ,(QÈ\ûRdH~”Ùn4¹‘ª²êD_ât©×³NÏ,?Ş‘Œæéè¿ê·ÚDè¿NÖh­ò7ŒàÎÂmàk5­ûŒÌÉÍŒ…)º1û2åi$.è*Çs…|“i:èOâĞÂ†Yº›Ìá[İØR¡`fú”v¹›p¡»ªs²ma şªªä—cÌPCîÍf1¥ÜysÓñM-,œDXÌJE„„’uŸF1ò#vóæC‹O	ÙújêWlşÛ×7ÉS8ø—*œ1/Æ³w&ztY‰&k¢ÚÏîÏêÛ|U’²‚0)/kquôÙ>ôzL&EÖ!ı=èÜ…Õ¯©[«)kóÜù"%Ú‰}5 YŞ6°Ë’ı;Ío§#W;W²7ÈO>8ÇbÑ}À	ÇD\Y\AO–.)ÿÔQ;½õ–"Û’_—Ğ?Nˆ3€¼ÿÛÉzYûF‚œn0-ğP¸aéÉÁ\¥eè»d—«¡­Ü ÕÕÏÆÄÜëÊ¥S«&rıía}¾¹#'ÃdKxj£ŸóFH!vPÙ©ôE)Vî²X“¼Z–B[Pç®šl<vÉšù«k)iÎ¯ïòïx:4%\Ó®ö•i}<ƒ]aêpUÊó†¶\G8çmäÊ¥D$œµjòW‘é™eÜ)äPßIkˆµDëæYMÕ·
}ÛÁş*´KƒÀÃ”şûÑL† ,*µzöd8ÍK1@ÜR‡Îq’ä>Å©òp›2ˆ'KDJÚu¶ßJt¦ÌŸ>ùv®6_×¯í%ÎĞøØ8+2]Áøi…–hàÔşÜ·İ¶çh|7VrÎÌ:Ò±Œq-1agÈ'>¡Èùw/8š%èpä'‚»w¤ßûHSx>¬şbq·Åùw§·™$wsA˜z'É†’šÔ,ø¥áÂçZÖŒûØƒ@[Ê<Ş
ıÜ÷£–€T¿°®HXq¹¼§ø¯’>n›„êÁƒÃˆ44d†,Ò%uÂBÖá×Z\³i-¥RPc+¡1öèUæÆ³Ç 8‡³v!±R¯ñNYÁURLéœíÁˆiƒW¥"NéÓâü¤×ù2ÁÆ»¨ãº,ÌLtó6ù.é‚åµµNşÏ·6¢ÈÏLc‚@ä)‡´g©»‹¹ {„4ë›ãâÂŞ-û¤Êu Mÿt"•ÎDÔân™L´DÈºÊ/[/£ÈÂ‚ş*9w±—Šíò$¡—2£´ M<JãT²b¥H>J¨Ş®¹‡úª÷.ØwpÄŠ™L¢aÉ u)½VÓ¶ÅûB¹“[¨Ñ2cg¤Ÿ'eês=1“ÃA´ròÁšë*ãb¢Éã ·9Èh—V‡‘ˆ­Èìsòe¾Ó¹òï;yûD{˜d*(T>GÇ¹û °ìmÔR”ĞxYş“äş"b®¹LımA~Cä‰¥>Sª:^Âå*õ	Å/ïA6ğ‡OV‡ò¹c-fâÒë<€g‹:SB¸ø†²ªèßĞÃqå>PuÒ&4/ŞğÇŞÛ‚4™<ù-[¤ä›Ñpü%1XâS•"!Ãi¶’3å­¹ "T0¾Kªa£Ó¦‘£ÓN³&4Qã08X×~b£Ó¡y°ríQœ(×²Â\Ú‘ËmÑ5'e@ó«Ésñ MÚ(#œ1§&µªtù¤HJ>•ˆ³Qº¼9ZI(ãû¿ƒ#´ÉØ¸Ş”–€qRu;ñIG™*…W·@ëòfÕä¼(®ğ5ÀïpÑ9®Æbîåäy?0Uã:ÜıÿÇªÓÙ¿8 Æ²	/-)Jç‡FŸÜÒgşæ&L$0*ğ|ö£5—@Ç98š—3Lš½’wA3øw£ur­Ò\b¨“^’cƒc£ô¾œ„OömÜ¦f…_`ÙdJ@i€Ù×V‡EèG[hò¡º§Ç÷Êk3‘~Ÿ<pÁòÁtS €„ì…şê{«7ÌoùbyH*¸œ¨/'aMrgpxPˆÿì1M1+%G^ì ¡ófí@~Vw€w'{“wÙ"ÛÍ¶­GĞrîgsJ¨KÁU[¶ÒZ0Ù2<iŸt°•fFA‘qaP‘”Ì2†1`vÇÌOAHÃ+"J\™Öò¥è¿¤·x÷Ô ‘¤Æ<Xeš<Ï‚n4µÜÊ Ş (ÛnõÒ	ÒÉ¤¾©…%j»™ÂÍŞÁpÓóhòˆÈ:DÖt.æ*iz‹6ğÖ}çB°Ü†YĞ! xo’ÿµ;õŸ* ğ¨ñU´ß¥ó8FğÒ§FË"Ğ#òIÚ?-5ë”¼EpÀÊ‰ÑI““¬³éœ|²vqEê›?1Ø¸Rî £³I¡œ5ñ¬ ¨3~öY¢¦Re›8ô‚,.áŒ™‚ï=(ZmÀkié!<cõ%Zxáy‹Ø•…úËKÆŸ.Sƒ>‹ÅÀ¶îqz5\ÕŞŒfÀ ±³ˆ$ŒRRb÷i§MëGjÔ¢wí9àíÔe,êI»AÙn”!£²ã[–ø¹0¦›)·†Îe^(óÎ¦ïeÉÔşlİ(qäúà/ÀR·?R¦dvİÇ;sL†ı÷â4·tSäyû¢Gæu:™T¸Å*prÛZ‹ÄAêŸ¢y)ñÎÑíõ°;Ê|•êĞò™Ÿó±uÃíW	6•ğR"VI£²6h‡È¹İæÉ÷m7ÃYé5?¦vÂı*I:,€Hö`jÇ3Øİ¬¨…dÑë¥l›ÿí×\ë"şB½YS{ç´3¤j`Üî×„Yy)×wÖÏ|@®‡êÁ)ˆ5ÙË«[¹2úD+åÇJ»™E”ÏŒZ~uTï[°òÇëòUÏ“ô EMVênB^ô2ñƒùÎ*"z“aºÂTK:ïİa?ŸMLûñ±ØÚr×ª<ğŸjéK)æ w‰šÔgahşÑäÄõ•ş²±êOáM5ÙôØQ-$nÙIÓs#0¢1ÖĞò‘‚UHJr~W  `\azj'-K_@ñ¥©ª]’ÓÄÁó”ìjSd½óø5`Ò¦c&šÅ/ıÅš¶+"Í ™¤Ê›/è@¼·¼ƒÛ
}çÿ—Ú®¢Ü€tÚ;mÚêµTß„ù'[–ÕÔIH²ú»E,7hğ?ÒÒsĞ<Aø«oçl#cŠÖèÈ7´
a’å(i»„¿Y„z|å«+eÑÇF•Øü†¥´xõùduQÄw»OÙ!n×TÃı<8Zœ¡i©¯ÒD˜5Úğà-¶¤=ú[Dïğ:'ÀÚ"°Ì@¬¯á¼HânÕâÿæ‹^è8ü6Ay‹ÚšF%9åJÖ kØ¼áÆ-cËÏR<t‚oèq_7!Fo<»üÌf•+ã<n³]JãŒïõÎb£TëºèF‡f¨¾wt¹nà"Ö	¯Á¨,¸—yÈõ,|öªèvuÊuòc{Óşú“X{ó{ìıQÙeHbÁ³%.àt8K!„$ÖÚL<×±WÒÁ'ls‰€Øïc¿jT9Öš´Ä§üñH™èÆG¸YøYPS¶chY$q4Rœ‚ˆb”
içÄEmà$SÎí6P?ÔŞÙ»‡qŠ`ãğá‰ws[úÕcŞs4S}ÆÚ(Ÿ0#ÛÆÓ$5
ÁišJ©Œc¼eG:ƒ}·,'Ÿ+Ÿ#êÃ]<›œÿVšˆMÚNhÒa¥Í£^Şšt6ïá¥âÊ¯Å¦ß³…;‰N9—ÇÑ„¦	I0mv#º8x.{H
B€,^*äoà},Só•/ã‘]ñ:`êõ:ş¨÷‰lŸv§}  Øcî¤yà‚à²7NLz
Aà%6[	È›òË…¨~&4aæBsÉÖ¯Íğ2µˆŸï¥áı³ô£”5ø}Cší×‰£†ê´ËQ±é;ïD
ÊG·ÛĞHy÷µÓ”ƒl×Z‰ÊÉ-'B½|¦»§Ü¸8ˆŸ®Wôæ˜³²Jê©CnOk02wQM¸^J2šÛÕ¼9à€Œ#@ï]eú™üFlœ-È‰ĞÀU¡2=4º„îçÌ¼/N'a­«oÓ™‹¨»‹d®0b	–”Ä:(&éqıFëÈ’îQë†ÕP±Íg®â(¦ŒKÙe\/‡¶!Pİ\Ä*øñßÑÇ‡]wş x!¤Ë8‘E7{ÑTc,ıxŞw£îq9Ÿ4nÜ_ùhvÊ>"çó£ Ë¼;Ï³Jğ£1¡1Ê¶Ûh´_]ëßI-Á7zf+<Ö;ÜşÒ"T·I9úÒúCY7ª1„Aş{ê}*hıà6³aÎ`f>[`"×óˆ_EÚz´`ET¿ü†_32Àüa›é%}zˆóÙ”ê'SËsx"7rÕóR¨ª{›İèŠˆ¾M†»œ¯xü<‡÷•Ú6ò‹d!W9opØ»x¯0pøğB0úï@Òª7Q7¼ª„Ä¤BÙ±˜CUî}¬­ëÄç¶©ÀT    ®„j5ÕÌ ²¸€À~÷¸±Ägû    YZ