#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2028677705"
MD5="9321ffed83f06e4dbe3737769a6050b2"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25984"
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
	echo Uncompressed size: 192 KB
	echo Compression: xz
	echo Date of packaging: Fri Dec 31 21:59:40 -03 2021
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
	echo OLDUSIZE=192
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
	MS_Printf "About to extract 192 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 192; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (192 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌâÿe=] ¼}•À1Dd]‡Á›PætİDõ#ãìIygO{t;n`ë©¥oÉ¢À‰gúµt<ñ{ê#·:VØ¯ì_ÛæÀxo¿Ğg:S¹9¾Íçí™ùV"«UæÄ º-“'K)š„œ‚2ÿÕÛ³†Ë-ğ'¨ú¡•¥âÛş‡ìaxãô‚ÊúO‰Íç13MNšé/È}îXÿ<³ˆ!í‘¬ğšQ¯AÚŞ¨'<H¦·ĞAíç”5•€\wM.è“>'m4´À6IÅ¸Ò
¼ƒ~[!FHDÄm¸FƒIàÔ;É†dœøÂÀ_dKÚPò’‘½Ú²óØEÇÖyq:¸@Èg¼Ú£qlL(llTñÓÀô‹MÙ÷™GÃü)yYûùUÕ‡ÁQVPu“:+j¨0J•²õeN…ÅkƒíV{¹su}¨^`=M9mtdàá ŞŒÁ«œaçc/ñÁ¼¨?± éœÇnêæøb ÊÖR<}E§Ì::‰p„¢…L¸àHøƒ\şõXåªÒ °œ­³l„j¥ÁÍ^?ö#ÌÃD°=Plöäñ+=’¼ TUÚ„ÖMQsÆÕM„2uß$"ÔîÜ‰u	ã»…çãu&„%ED*Z…™6f¤.¢È»ƒ±À5cLQB·¢X0,M·ª[k2ƒV´$·¿à>æ³j"ÑÙ¯nĞ‡@4>ÆnzÛ„ÚU m Qmx°ŸÖçøqè€ùR>¾6Buoi‡-s›uN¡ñ<dtBÉ ™H«Ò1İ¡àP]e_¹`GüB?¢P×wÑ	Y³ áL) cÒ¸&ãœéÍ¯áA®F¹§[Å{;Õ²?p~Sr
W"•‹,·]õ¼«ş<ÖØòˆÏíâşp°ëÕgÊ*"XRÜ\‘ÌNf3™µàq,"h²…ìVË2Ì.¡“Å)kpc<9ÌX´ ß`’:šŸ0´¦\Á–Söãu£Á¤CƒLIñõÿÃmDşw™©¹X°`ŠÒ3²P\;ìåğ`‚J&A´Sù&/êB [ì”ic¿î²yÌĞ?Ä…AÈê…×ôXZ¿¬Bª‹¸úÓ Á§ã¬˜œ^øŞ\±÷S>ı±”rPR*d"ª¥Ôé‘,­÷8SDÃTã<	N\ïíĞ'y ¶Y¬ÉÍîÅ«¯ÌùîÿÁãpÎØ û¿;_3}£m&aäC(I½‚é7ÀùA2û†Ôû"¼2yŒ?“}Ì%oëƒ Ë×+Ù<¸jzó1}ŠPuùsÆVºùFødÀw×á¡l»w!AHõÉÇüí~¨¸ yaĞÎÅ9¨;Œ²9ĞŸ(ªM9ûÂé•ü€ØÑ'¹×ÏÎºin~!bÅğ£PæÅÒE¸}Yçí{d²qO
Y	<®0äÙáp†ü\`ÒE’ş}©MÓNà°÷Î&ò®fÑhèréFÖ$WŸTkW.¥Ì¯:ü#Rkazˆò˜\—¡Ù¹B0ÚÆµSÁ¤âÒï‰8µÜúdè1ˆb\‘S=!¦‰ãäÆö%ó®CŠ(ëŒÆ´Ò¢|ÌÈ<ÈÌR¤B™>:Ê•i­Ÿúk')¦úÃ:ÆĞõ¬mâ(Æ?Å›¥>Ù›ü;t´Ú5Áºiøæ™ûÎİOŒóØ¬£‹‚şE«ÉŞ±Kñ•…Æ@Ê	EOëı;p7ÁäÆâK&Ç¸í™Müîá½Ã^éÚ¶¦p*Îp¸{™;ïÛÔjÇï¤,7T¾Y•A*g¯ÂaÅüıØîc8XÛ4[º5²Ö+à]½Õ@Ñƒ¿nJË5œªÒkÃÒ¤+Í·µ%Ç‚È{ÏBDšƒ1
ş
rbÖ˜s»&—$Zó~ßg\93ËL,7vy¿>¦G¤1‡c8ÔWªx¢†maÛ„@µA+Õˆ¼*±¬øÕC"r¸6RÖFGÊdôÄ
nkpæ ‚î`bE$½÷ÖL]zFİÌh¹„Wã4F1_EîşÚ•Ò&{u
¿h¶°%“Ä
2~{¸›d³÷ß…#E<h%¢›Ğ >6î[í~™©İ»}™ØD<}[G÷+¡‘»¬Òú;IğP|ôôøzK&[™_™Šíd‘†<’ªm$0` WÆß8òwïÕÜÀ–e+ÎÔBcôºwm.M(ŠyËnœn´)¿“ˆ~ì³ò-•‚*öwÌ¯(ÓkØ¤g3æG‚TÓQùóÖÒØz3|v‹Íœå1ä*ªù&Š ÖàÓ(ø•ßÈß ùD‚œe^£@ÿI¾ÌËN‰ß² ".0½Ôè‚Ì-ÜNçß…¹í5ójõï›ËBĞa&=_,€µ¸i .5Ò@S.rĞn={Å)T#`mwí¨.«Ôºç4È:AÔïD,Ù@‚ƒíW³,:½>•9.CÀçb‰ãáèä(¦BP"$ ¤E„ÌjlíC,İÖ¸BĞT¤çÅ©İÙß3$–fäBé¨}í’ô~Ñ–#2>Q)÷<äõĞºû“ŞÇúbı£ğLùmàV[v&¢=pV'ô¼´Š ù70–`åß"`N¤Á Æ¦’EØÏå¹°ì®K©ìÛj€séÆú!k!T+:§’h4yó°|é×#öÖ7¼ö7‡p{ ¿T´:|Û²Ÿä bñ6½DI¦¦¬R8tÆ”\TeÊçÓªÆ'© }YÄ7ô´¯mø?â÷D5>a'rıùÙ§_€vïp{)ÊÑÓ¼BpÆèŠÛ™{KW‘Dm\È#¾c€`ûËxÄQ¾ :2 ™ƒÚƒè«p‡ëÜ]ÆW¢Ô%¹÷àú+Æ¬‚÷¨¤ ÜëQ[UÔßºPeì·Í×,'æ‡ú€Uîò(c,—Í“•F¥`¹‚û"¦óóe\Zl¥ö(Ÿ0¹¡A27<ÊŸ O·Ï†ÛFa×³Ë ö9^GÙzVSÀ¯³@M]°ù§•’¿x$Ú»mMö¼Æ5æ„ÁC®{uW)î¦÷ÓKªŞúæHÏÁ‘a¼àæ ‚ ­Ë©‡£×¨/—kŒ‚%XÆˆ|Wò¦!Œ„ºâOÖœğ€>/øbùŞ¨Ú™ådG§d'¶÷¾ğ0ÿæûçö¢¸rƒ7Uí¨Ş™Ü˜KIut„(Ó{Yâìãu¼Ä'd4v« §¼“>lŠicuD2/õ.Ú	¦>R^Måü;®wVµ¿‰Wï_–¥yKìQü¾(ih”ı
Ü7‰ºû¢òë¿^q>wWÇö›huj}Gµªm ‘Î¡OR>©Ó5˜,L·Û>R°ûà;Lïê2tCPİ»*ç<pt6‰CÄø«®÷s­©7)]¯¨HOx3º³
T©¾¦gqøaá 6³¨‚†d:¿Û!I0ÂQJ 1d¶TÑı)Ò?i•&oÒ,ÁïHÁR¡ CŞe½ø>ò§r¼?.ü,5Ÿ¸N…­³Y7vVoŸáÀÜ—@qH££U¤§>{%ì£ÀV"Ë}õ`2÷‰S1šÉW‡­ç±;ôDUNRáBMÆ.âä&ÁTÅ¶úfWŠõÓHC¹É”´İ—(UñòRO\}åS 2Š\ %š•Akl~Êİ6Öè`	?¢æDwŒÉ|Pºqä©ë²\/=¢¬‡q‰5r¾2oƒM 	lÖí‹@†X-•¦˜nfü–øick™È¾†x?P%=³
ãÌ7â&1²/x‰Ä &õÅn5q@ÅÆü¾+Ê;Tn ®*£¸&ãSr½Dó½tAzZ[Ã²¨b!X×]£ó€Ğ
‰ÈtR%¤ÁUÃñ£0"Í·„$P±üúæıO(6´ğ …¶{Â™Ìßôúr°¯¥Û3/”
á©sçÿÍ#KáO.İo¾s`ú0ƒ(Äá"dUî]'Öƒ:3Úöû˜HÈzw¡K?úÈPÔ‘ÿ	«Ç3ªd2§ˆb·fJpGì²3óE„!Ãh÷ŞşÍ”²'æ)l¿©È”z;÷KRÂ÷ƒ÷¯9¶Bµ}šÑ)5<­@·È‚>ÓñÊã)rhÆ8*|ÈL(µù½£„e®ßR£ş ²>ƒ~[_Ê£8!ŒòRjX=ÕF¬=“³Š÷t_£Oóx×Æ -Vr”®eX´ñ¼pbI/Æ|ğÊ{“ÀøÅmñÊöä´	s*)ü+-Ç É‘6s†#ÖDE¬Kee[Š¼-eÇê•§S¢û(»°üµŒCU‹á±+ñGkB^ë¶‚³ûµbC\9ŞË2k#@ØE÷IO.‡’“ŒŞ)[¾ËKí®Z åå+{ ™¶·³*ìëk¡°NÓ€÷nÓ
œ²®‹Ü'!·²‡xõå)h[-åV‰_}`B)&7{êiV—$'Œ	«x¹àÚÃg÷×¬%€ß‘)æóyt_2{Í+Ã&P?Ñ4Ø¥k‰èòøÕ»Ì³:i‰ÅfW8şÃÎ3se¦Eí6ïy¡g„¸‰]Ñ½ÁÛ‘`OG›&X†Ú­½úQOe9q•¾)qQ^3|€bïY@W–r¡¬"7ìcvoÑµéš@ãêrCì©E“·AŒÚgÉsJª–ñ¦šdÄà[4‰U¤o£5I‹ZlÜi’Ö(ë÷³ˆvÀ†\A‘UR9k…€Ì£ëjo@e|:öBx;a‰ÎšcûhE‡úMc3*ÈHşL×¨ÇA9°Øÿ¾öW ¥›S+¢%çnÎJÌí9f‹¯Kw9qüË"yÎ2ıêåëŸ#’ÇŒšÒÀ"êØ“Mø{
*D4Ba­JÈn+êÉ+Úƒbï2 M*QkÏ]~|¦Şã
ˆ„óc(2©²Ó½úà”Ä™”Ø«&XïÇ*Ğú¨}ü«&¢G¥õú¦ö‚¿XıŠ õÉ½İ®aÌîaÛƒš„¦ºbjæ[ºE»Ïî@C"K¶šÛY]JÆûPÇ7P’àë¤T„ºaÓK3q7î”=`)K³\G-}…Á¡SL–Ğ"»h‡°ÏóQĞÆ…fy¤ ÷š-Ä.ğÆò±Öù#ÂÕ«¹Z›ZÛ?EÚœõC¼™3ÓlŞAªÙíMÏQ©0T5²˜ÄÏŒ\á$Ñ.y³Ô–¡ªUñ#Øv$ë{–Îì€óÉ¢•Gåkñƒ¢?¼Ã]ºk[ƒåë2?š””×ñ	M']7ÂÙ)ü>%	,&El¤ÑiC2Ö„„gb·!
ë”JOÉ
(–Ñz	Ãóe†\¬!]&€a_n×®D°N¿3QĞœ”Ï“0°ÜeÚø«?J\‚_â»Œß=<±,ß…ë)Oõ(…b×l|­*·ºè²¿€Í|ìyaãö-!%aÄ§o¹×-Vbİ0‚6!Ş¾M"ÀÏ²^´ñ;ã¯²EhÀ©B=†Ñ[ßJ{—œ]·9Œåh±klx6@‚ÏxªÏ(ZçµÉ!Ô@C¨Ş÷7îô•LòÔ¸šoK‘ôPéšnÜÍ+
ÿagà‚3< Ç8Ñğ”£¡³Sp$teœ|!d‰§~E4‹@ms·‘«9;[^®S`»mš¤ÇF…ø¨İo*‹…—<øğæ9äD«`"œ–Eƒ¢Q¿†u`ÂCRF(Á9¯Gè?Yª>¦óáå×´Q’úµô6B‘ÇÕ[P¬(2s•u£~`ûnÆ‘m—†¸PÍá“²Ë{¦â3	Â ìÓO¿ˆ­Örçƒ£p`ÁÅæÖ¯ÿ©²ĞìÍ‡õ´æ€3Ùè‚Ò“¥ŸZ¹—Å$İò,z“ËÒSMm”L¼Ğ!|BÜ^ØÖåš\›ßÿ?±Y‚TV!Ò\¨¨–âàõZU
kj—,GöĞœÒ 4œşİÔ}ğ^øŸ3øï÷¡êœÈñR|Cë„ós5† jæ9œ[F0Ú3!şÆó´#•Ïö¸½¥B”qÁòû\·œşud¬Xš#€+KœS1{B‘®AøSoF‰»æ|½YêÆdéGÅø¯6”YÊ2¡ì·:1N»ö’²+wW°Å”³‹©À½~JnSce§bĞ~2Ã3ŠŠor±Yì‚@-”7nddÛi½Xƒ{QTÍó>ğœL{ì~{èb-ƒo‚ª,%‰j'ÆŠQó“oNŠršzı´gşõrì|\KBôµ¸Ãq€ƒceR ¦À1ıë[×%aV9GÙÓª‚7Ë9ûFló<á¦,ù|T¸V~húãeö¶ô±7)İÊkË—eÒ½’¯
NSÿT\d:Ö‚RúVÎ€tMdA|àÄMŸHy}ä€¦Xâˆgğ¬M|g6ú¡SWæÕˆ•Sƒ›gÃÓœNgìÏœ¯ı¹Ô­¶í<Ïprlg8Ò±Yêğ¥ïúÅ*‰$‘+§Ø Œßn5WK»­7ª Jå,¡¯GY ã+İÇTVøc5Ó­¸èÒ—>Òûìºú[ÈhÃÃ³K+z!èİÂ“IÄºtiQÈƒóı	&óå¬D-äÆT\Yıw¥÷ùj¦&]öä$|#±ä‘*²l@˜'ÎÄ…r†TCyW½‡e.Ò/P·M½1^/O
™sUàš¸’ö–^kà:Ç’ú?à&HÚ¡•£ó±ÇíÜ\UÖĞbÏ3“Ÿ¤¹9$lµ‰ ²UT¾a½•#§’ui¶£npîÙÜ|Ä˜KKñìrF6šdÒÇ8ı:9ÉóŠÈ#eÜå„– %ç+OœÏv.¾:Á}?äkà™<v¥÷^õ¼†±õññØË*è²FÎ:»Ã½}xahiã,åúf&Šzo²ÅW‘‰Ñ†2Ë,C)¾Hg¢	Ã“À@«Ğf|ä‹i±²TU†ò©õ½ßN<o­û„3:Í&Ö7øÃ¹3‡†ı`mÙÌ3‘N
Y±AÂìì~ÒòUt4Õ—'V/{>HsÈ˜W7ˆ@a }­ˆÉCîö'ˆ¾&Ä«<¼-ƒ’{Ü˜à¥ÅÇ(T×.ãùN™Î¦)$m‚³ü#ËÁªV-3% _|üR\ÙòCä‚4sqX ©©yƒvy¨rziÇª^±OŒI*EL±pì“¨‹Uâ¦OK®‹Ö‹Z'®3F+ÂTXW©ÊÍÍL“'ÂÉ’wû)Óˆğ¥b8Ä§å“!'ø¾à·˜t~`ÿ6˜m
,ÈÜDöÖšÌâüK3úÿ³„†B>×›00TZ(]idŸšk¯}éßŒõ+ò„şr}‘Ù±ùs¶rb©€,¤ô‹ôøXJÂğ^I‰×ğ!E5èË`Íê+iEp;špN á.ë¿˜rbĞ¥OI°Ÿ{*ü÷Óƒä•è@¡ñyYS?»A	@²®ÉbÛodDY%Y_RJfÉŒ(İm¾Ú&îŠGP~*ÒĞ|÷ËŠAeöÄ²E©:jYëzâI¾ÀIîÔGYrß±èÄ[Š’²¦[:htLı€CX`Õ_V¸%˜û;Ü2tŸ«äÎœøıcšépşÊì;-Œ–)ãÚ§r«u{Á¥PCïh¶°[è»R×Ì²ààœVxî2ôÔ üIÔ©t…XP6ÍúCAšúµx\9èqî¼_¦]Ÿ†ÂÉ0—Uõ|"2½:KµÇÎÿ/^¦^V-W¬ö× ŞÊØ¸®‚˜çHÇÔ„9¹jY›úòøÍpqãğùt`°+Sÿ3ÑŒIGêø|—ê>&hùÍJÜ&»ê?QÖ<ÖP†àh;ª© œ‰”4Œçë7áÂãÈ‰‡l¬F{]p~m¨OtÕ„ıÆEÍúU€ê“Ø&³wmœ¦¹¤ËÃŞ<AõÅÖ÷ú8üO©t1†}F.*PD%šÜI³$²0O\#£bª«j†[´í q[ú”*Qqš TÂb;éáÕ±
“ÜC‹eúki¸"ğå,¬!^«»›ı4§)I´4jXÇJK1Š•ºÑ»Lwm=Ü²s˜Äèªçé3…–±ˆeı•Ülf.m¢£ÉÙD$Cj€ëßOˆ}oÖöŠÊöÜ…>–™¶ígûÇ9YUå…UØáÓ¹5L18Ÿ»xï5€¥g½Úq rÿØg‡H	ª>â=ÏÏi	»€¡{µ€\ŞGÉáè€‰YdA+ƒğ‹>¨jvğhÊZ]/§±İÙ Í¹ÿİ_í³«¯ÿ]n­ìØêu× UÆ)öş?3ÁñN°Ş—a ´ÆNLƒ­8ôÙÖ»›jì)6œÓ1Ğcªx›ÂVæ"ÏLç˜×QŸ}¹:X=R¸Ü—±g
Éïñ„§Ë²È-3*ù‰*®`	‡p…À;y,xèãRgG‹î)luâßPõ +Š4©”~ÿõT³9ºgï“¹™”¬n…
\‘'oà‰e†Â2L'Ô÷ÚîÄ‰ol·ûğµş eú£åô6¢(’ıhU-Mè9úPß8>T*5rÃ¦E³À²P„Ù$4€_ö	â…Õ8x
ã7Yê‡Pî‚à!èa%1`°ã†‘E(¯HB ŸÿeßÕ„‡‡gïàÂ~ïWº`+„s~B)(ÍY“ü0"Nx®ĞÚé»ÒÈ6;¢ğ ¢%ŠXO/™¡é9“Šô; ó(F&gn*¥b„ãío‹ü×‰ ŠWñ)-×¹…)™U­›Q./›+¯Œ	IÊ[XüŒãÖ[¯EÙ¤`¹A7ÓÓÇ.
Ÿ¡»­ĞÑr6*6=jàl“D=kû²Û§U.ZfhDhz#¡„Šå‰Y{š¬ö9l¥»wgQ¯Z^
n/†æÉÃ§¹q^Fıo§‚U\°»1f:xRME•[ÎÌ‡xçwã3À…¡ÂicâåzKÒÈ‡2£ª–¿±ZÁ}^*,±àSç€ö‚ß‡ù.ö÷Ñk¹Ú%ÿ\–NÄ…<KÄ^qíF?fşÂÓ9©nÚ ÍÈÏ{!ÃÃ€¤- Û,+Tµ ÕJqš§ŸGíâ;ËEìÃE= K¤:ê“<.è²Uû¨†¢HƒŠîE¼Í
b*°Œm?6şüÜØ!ıHfùÈ¸ıóØ)v{¨Z‰­Ø(‡{éÜzJ?ÊÛD5BFğÇ˜hà“ğŠŸ-¨F’®n©¤@4Ã«¾v•>@¹BrTædg¶ÒsÜòO\çLŒ»ÙÍ´¿ ÿ:—¶ÿ Â Á*ls“ ?«e3q¥œ/ŠÀ›hUå3„>Ë”ì°njQ§Q}À­Qşrûú4ÍNvy5I0³SÁ2+Xb¯B¶6ç0ºÏrr\Õ¥â›Õ*Ë!˜¡İHSSÌ$òË6ó»àZŠlŸMÇd°ÿÅ+XZ½F7íkÃ·şÔÙáyÍ‰n„Ëj\gU"ÉA*4Ãÿ×¨"E¹î½sÚm•p÷È”Ïór	äã#î(Rrmåa8ƒ¢¤gLÏèƒhA&ÇT›]*â	R8—AÙL!‚÷a‹G‡º­eM–¾àÃâäÎÌB›„©Å\Ï•¼0±°ğòS˜Ú©8y°Í«f
±äï—weE³oï"GÌŠƒSš”Í€ŞöE§¨""Éº•Üõ‚,t’êOŠÉqò i,¼Sdá- ¬83ÄÎ‘gºÒnıÑ¿+FaX(*tÄ‚6cÌŒ¤DÓª„Ùn(NŞ
)~”‹{ÛO@…¹ÿ÷2†òàY|Ñ³Ğt,úƒ-Ğu)×ªbBvšâ®Í6İøÜÒóL|U4|ƒÇ…)f©ÊøUÙ^a÷¡³o<"pÓ
 Db‡(NqĞP¹*[aâáHµ^aœÊOñÄDUaX¾§Ò÷«(œ~)º™ğCşÈ(Kjï7 ®%ÆÀ¾Ëƒ¼?±)jFfÌÒŒì­ù‚¯%qËl v T:h%ãñÆÃrÜ×‰fJâÀãá»ä	Kò6xG ØŒiu3³0$=ôM#ùÃbEù‚kJ¯+EgÍS·2-NÂ5äıJİ§i…¨¶_ÄO TNí‚vÜ·^+D
y¤jMDŠ;»>6`´’T’B±Î’T†û 1]BË’û}‚ÊôR»ÕuªÍ],â£Ú»ÂXƒq+O¸ğÕî‹¥o–eú9ËfIL§äåŠ×s×ô~ái÷p÷?SHL5$-Q—½ÄXÔØ NêìNÛ]ºGã?±À9*(™dÁ99àSáù\xØ–õÔ¢+>öÙl[ZÁd«¢÷×ÅÎ÷Osúj_]²)gMı	ğ•¨|ŒèM«aÎ´0Ku4}x´^Ít¤¦ğù\ØWs8¦ SÕŒf¾ş+²‹0jªºÓDğC;×ÌQÉ4È™Îwöï2@HàŠ> ì”İ2å`şÃBı8o³$òß—?ñYœb˜“_—í›A´‹¾¥²A4÷ÙHcLN¨”—ç^§$ Ğˆ§PAØ¶9nÍ{FtˆX=óL%9O¤ò¯Qö÷CŸáU=,e°ÆùssøÅ¼ŒÍció¦·Â*±%…]e¦ï·ƒâ‚’?b „¬ÄÂa›­0¯WÜÖ?L5œ]oÁMÑãÍ”Îá¦§cüÑğŞéÉ:¨m²›@àøÉéëÍïR(´Ïwà®…
‡êı÷°;óq%Ì£^ŠA~‘Êm×–Â*”ÍT™ƒ°àjuÍcÙqSXµOK¤-OŠóİª1„õé“QúMyÛL×Ï%©¬+Í` 9Õö0ãÖ©Âù6nÍjx)Iı¾ÍsVş{5Å(å¹×ğ€5_ ¸5gı€^àÆ…ƒ—ì:2€ÉÛÕd¾0	xD2#‡ú`Y"ÇX(Ú_\™Ê7ÒVMmX—FY„û¸İE®ßpG\º`Æ¿â¥Ÿö¦E¸Í¬ $o8TñÜqøÙÿ=˜äÙ˜®Ú¹±šz*ÓÏu)Æ‹Q0˜¢¢•ÚRp)±@æÎ½X‹œ†İ¼cO£4Öâ'ïŞ¼¶ƒ7!·æö‰(št`ò#Æ?„1uí8ù¬„ì
y“ü‚„Dlâ…©ÙQ¡[a¾‹Í4³Üí&Im8\6‰v aq|Jì^ûBKÆ‚Böÿ„tdÒ¾ãö¶šUË›Áš¥¡ºªz˜YÙJÕ%”*5ïÇÀìLêÉîÓš´©mãz=ûö®0üW¿GD‚„rR]·ş3CíOÅçëTºÂ™áé rl;ÿÇ:åØ…W£:édŠï\‹óã¤f>o_¤©Zà2Uã©]Òëû^ÑY0|ÛGñœ=¼´ p1{Ù?İÖ×¿¼cÄÅ•¡S"Àšê^Lµ4Œ¶,‚H¯ªSĞœ¼h2I}ºüòóì…|¡
³´ã8®„˜Ú•fq¤¦Ø|	k~ô[Û™ÆáÃtĞãËxÌgß€ˆ÷†L03ZHç½3ôp¸xXšÛTMé`ó!g«gÊw¶AEˆ|(“[æ$Wh”ò×1¬İS3Yïh[`İ‹ĞÈÎO„¦‹‡Mx ~ÿ>,SOIS×PÓÖ†cC¿4â“9o äÃ«âŒLC„-´\/àpÒÛn'lm?sH&oòğ›µ¨ÒÂŒ=…{©Æú¦‡Í…Ğå{\Ê>÷¡«y½^2ãG[¼BSn×¿8•À•—¬şÍCİ•}.>œY€ ‡±QV³mºñ§+I¥;o·§Ÿûğè¨y@d w¿İ44_e …8¤F4ûÑWĞoœ`ïÚs·ö
aÈÏÖ!ªIõèó\­† €j¹É4'ú<Á…TËó‹O}`š+—c.”Ú¾Ğ¦àë[¤À›ı2Äİ8&êÊtá>=ï(ÂUÁZrˆï„Oµœp±à~IŞÜ&¯¡¨K´"Óİ÷i$iU]Ì-EeÑ«QpËêè,{7¿9ˆQı»ƒ±Fµ]•1òJÁ÷æÔT%È¶áµÑE(—¤ö@Ğ“HCÃ&ğ1ôSŞ¦³°öSïèpıå«LÌ6Ê-á@3à#¸«¦7%OC«L´7ãZ¶Õˆ¤İ¥±kDÂ…>Om_2±u5_M`QI¹içò'sÔ¿}ECÕfÖ Õ1¿:{ó¦©³Rö¸7‰`îUS^ÓQö7Šb_8E&Æ	&øåß2ğœË×{-Ø›:ªîİ÷²!jvïà[Tƒıˆ‹ÃœË3£rùV»sÛ|èÅš¼.nv÷,§KwªÜO³(pæ˜Á}øÏÃI`ø÷+Ùìq½tÍğé¶›`Ê_¿†QZZ±¸Ô~ÉÎcv³í„ó|ôÏÀ´@ç³ä]õ˜
hõŞÛˆ“B,z}·^É­¤ƒ4?>‡Ü\+EÄíÕU8‹¢[¦¹«·ÅÕ¨IÓ­BH=€ZõÀ&?ØV°!š‘—U9eÑˆöÀ@™¬¸õ³£±³ /ö®÷‰Ë<€›Îg¶,¤`†óíÓŞ
óFY¥ò±&«4>}%LÜï Œ©Ôh—Äè¦ÙĞĞ‡*mıßqÎ€«ı~	®Y8Ïnù‚æ×ü«|’ï±½°_/æt0Ğ¹é'Qd2°6Z&Ï§v¦öåıì>æ2ŞiİsÉyXXPÓ¿fõÎ`¼w
ÕÂ’cüü ïÂQ‚Úƒ	ºm<¥IEÅƒ×.D¾‚DGà½#µV#Q:0‘³åv±_«îÁâ[-½Ğ!Ï8xE÷i3+©51Ö9 «,qğ.há.î.^…¼â¾ŸV»:LÜ~]…‹¤}~×]/cc»‰Šw»ÉÓU'ÚH¥ÑkáRÌ{<VælI1µĞ/ #´üÒ«oş¦v«Ó“‰Tòóşã}ÖDÍNÕ
ë¯­Eâæz³Æ–HT)¬7:8Ú‚g~ê;i5R_ìa»^Šio£BÁĞ×êaë‡r2ß‡šüÉS¶	+yíW
!YşÍŠ r~f5»z¶z¤ó7Keä%²(zñHb„@\Tôsn*œK.Ôjù,O™w—è
¯<°*+—8v©¥XØ[L«ù•&V±>œç®ïH‹³»È!ùuI¨¾út{>rBØÚ¨/ÿcÁÃŠ/t®DAN}Şf-H¦0|ÌJ&¢]f“lhÔ™ûĞ+à„É€BÂoÁÎÔj´H`‚t5±UhÈ‡RxcŸ'ánSàwÎjNÿ
¿›ôôqG’åDÄV Ïu5p!ÖÜÅÃjBª$¬ât¦&L;°dªÈW½‰½¡ıY~^OŠ|­®ò~Ò¼FL	™!oSMß›s¡5ô*—ÅXN…wÓÆ¨ê¹ú¯¦%°z“f5lİU¼.4ÏÍ%êVVı»,#	\°ŞE3©±:!!P„Ò"rA:oòÉ£÷ñë¾ëRÉ³ñáÏÎ¾~i†øØ:‰Lƒ¥¨ëÃ/öJÎT„î‡Ïıôe¸æm*¾ÒÇıQˆ¥\pE8øÇÜîÍÜ|šQ6ğ¢d5#°‚äı}qa~'ú{…ä§Õ#Õ¿å%¢§Ş1ÑhÅ]Ó"†PUÒ»ùfNˆĞ…¥¶ö>K\ZE^ET-OšïÜê_ùµee¨~HÇ¾Å"e3^¥ê§ZõîË—ßÄT‹Q%âÀ·$ör¾)Ó 1‚¯ğ¾×¶òi2ı€Ÿ§áRU™L¢ÂÃw?ê²Á?øz²lR/•xDnBBÉ.ÿf÷‘QîÍ\“¯$æ:*ë´!bœap¹à\q¡K’EV¥ÖäøYoF–;#Z9I çeÜ÷RF?6º:7[w’=jÌåš±ô+Ï_ı·Ş^‹ş¹áéú¢I$ª(8ñ¯pv£—R<¡(I‡	+ieÃ‰ÅÏ B!4ñ/ÈoX¶óáËXê`’?—ÿV$CÇ"É·»®§Ñ"°XŒeA
ÅVà5ŠË.–GßŒi«%/1 Ñß(ïp0taN¯çfxÛ@Ş>Î9cI×õCJóä§
XØ&Õ+9¹d€B0äñş:¿ğ–o¥úI«	+Cä›ïò·«âßCïOûêÍ	n+Bœ¥°ÄóP>õñP®Æq©*Ñ¦ŞIz=Ygp‡X­'X=CÀ,Cyä­Y»¤lÛËÍJã)èÑHŠîš¿¢:‰Ÿ©UXm¬kéŞµ­S#Ë¾È˜%‰ŒëµìÔ–%¢÷nˆ-ækZz?Âœ\ÍWE{xœiØkOÏXÊV'h‡ç´Áé)a¤[w/|¨•'H9–ø¹7iæõGq„úh@ 4l2`&˜À€×³àö´Ş‹Ç³"‹‰ ·YÅ(0hß°Ÿ[I)-v¬Æxêy²·íól·^ŠóaÁ4Å–¡îSÕ*H´pùüÚğ1÷šñiôÒ×Á‡Ã>w.°Ğ Üjh&${aUÊ6Şuò2`ìQ}x^«cÖ˜jïÜ8(I/bS£Ñ€ĞPa–0#Çtv£î•äé'n3±m7Ópz	²u(- <|ÎÏ]×æ8›FÊÑ»Õˆw´côe¬k¤ñ°ƒËJóêjº=î¦
-ÆOÓİ¥ŸÙ_JDJãåZjøèG+®n\§€Šİş;”G¸MìÀwèÇuz@¥ŞñTáˆ 4QQ®Ó7d'±â‰ì‡Ô­ÒÏ²®:3€Ø}ã×íYj0qÑe†N#ÿ‰¾¹÷ÿ§ªT³á…éEçÁJ†9J9åcøÃä—JñÖ4ôez a¾ÏğXgÂÊÚĞ÷‘)Kş+ş~ ú¬W£ÌûÁ;4§âq-8·=ê§) QØÈC˜¯®²QIôş­ÀˆhQ¬´!Ë[ô·‰IZ™×uô ‹(´Ç‡æÏ8œê6ëswåD t‰‘®ÆU)™æjÏöˆFãÎ‹ÊÍŠ‚È{–÷A·‰hµA÷­@åù*÷è*¯*^òæ{¡'ıê¨ a]®Tk¢Ä@˜]ùy§å”JÑoT‘¼,L@¦Z•RÈ’1ï†yÇ£=ú£-tJB pMoeQxŒ5°&ùŸ¹	l¸#¼°ıh`ÖåÿV|Òp1DİóVi ªE·iî´Ša%ç·ñó„k¢’EH§fn©Î»mÈv@V Ú½»Uİö•'>ø¿X*§~y?-¦Qèl2íÂƒDµ,zÕ¾½…#Ê‹4•\:¹îõoSèwâ×ŞÄòË5ÜëÙ%ägû%¦:Ş’I§Á08oAs-¥ZËñidHDrÄú/cÍÚ¾o¿'lØÅÂ‡õ‡~òİİ¾¨Q½èKÒnìÿl6+—2¯æ.oKTĞvã®ÏoÂa&˜˜5âXWPF”L9W:£S_3±°¾Sİ)¢%&Š»1ÊvÅ¾A_¢vMåå»÷ÜßÕ£OšÀ˜2ıñ‡4@bmHácæ]°ÛIQ¦C¦ÕH'kşËğø%êfí´´ŸŸÉ@Ÿº›37±_7&4Ècé4¹òÂ¹ëiÜÈ»™ñÊJBkÊÄbªv5t8—lé#ğIÛô8ï"~<•Œ;8<’·Ø8õZ˜DØRZ s÷ˆëüPâFCVë÷jvÔ„wªcOù‡ò+9ÔÙÅâ"òrŞ‰7>ât½¸œ|@	*:/´õ8ÏhÉìéô”ÔéRƒõ©‚¬âøOÙ$Óû!/#'Ùş-ÏÅ¯(CÆ>“ö4gå~:ëXl”˜9\;’äœ7&<TIºbä3¾Ÿ/YR%‰WÜdWp­øX!ù*wÄ_H³È
íöXúÉé¦á?4ƒ'€æêyíÆ?üøL¼Ş„—W€ hwv4]•ræ®/ä±ã5¼İ8ís‘kÙÍŸç,'M¬¡Óı-¶ˆéó`ÌİÃû]«w™Gò¯lcºôÎ.ê_=ìoÚ¢ıBÏ’»ŞçÑF³Pb°ÔdI5
 àÚ¼lhujñÒÃàD¿…¼Eä.ÉÑet(CÃ ÿ£êÈ‰uö4F.IYÃÔµ)˜´FÇm|MuŞ~½¸fs:šºq³‹Ö&¨‰)9‡Ì2R5fDgÜø*{lÆYªâ™ÿX _{6D×<nú¦îı¡ÃT19{U[ù‹@5Ô3ª®.IîC0óš2üRŠ‡ÛyH`MQ0àÙBQ^Ómen>–ü¬í½æ"†ÃbúàÊ‘ÍÀkÚ
Åš@j*_ü”D–¯µÃ¾ÂïDL@ãÃË@±Çoì7RÉ—oûÿSÃUE!*ª$EÄåèş5§®ó·2e˜¶³^§}y¹ÎÅ¾6`ÃÌöÊd‰·Ø3PÍ«•i¼+!¹×ÒKşu5Íº~c@¤váÑ7ÔPµ€JbUı§nÍÀ1(ß+}Vã¶ÈÓ«ˆ’ôpèŸ®7}EKêÑ˜°ç#êIo
ĞÅÌ[|˜+Küâ·ÂÊ4A«3èÜ@ÈHÃ¥’ı÷‰?‘nĞÛ*ÇdXîu):³•y\¾ª)Çıı×º#jÂC­Æ¤@ˆô ",IqÌ™Ö«#P7ÓçÅ$(7—[ü¤®#t` ÎÇb8h-ÒçL¹Ü²¤!Å .Uc×‰?İ$™£8ˆÜkú…­:kt½Æİ¼û:OÛc–ß7qÑéœŞdøæ¼NZ„öş¥"xq]lN1¸òóÈ¶š¸Y¯³èÒ.÷V®À#[p³«r¸¿ˆ t/™>Õÿ=iCW "µ*¡Ñmô ÑHpçã°:ÂŞ¢ŞTpÎzŸ~s6NÈëC½p‹;…xÓz"ŞD$Jg¶ß-S h“Ò…Ü±Ïµ	qvÏ†Èo+Æ™§ô
8yÁÅøOôpx½Ï[—!T¶Ìë*}QŸˆ‘ÎÜÅü©róz“ÁåjwHö¥MÚiƒ"E$÷¿‰o•òÊËäGuR¿"˜ºfp¶’ ç=Oû½ÀêÚ®Bêr 1ûºÏl–.	P«Wôrb
v#û¬o…¨¶O ÈÂ,ˆv¾u!zÄk•šíRù–T'<:y—ú6•Øõ¡Ğ¨øî÷[òøáD‡`.íyÚ‘¡Ë“‡ş¸{j³´pU¥™³|5	´›I8À/põYÔÂ,ı‡U@üTÓßvúf”½kllXYQqKzx±RÃ‰ly*ãrO=[NÆÜ²a¢n*}×æé½=0Î$I>l^y8õóŠñßdœ\ŞXŸêPÁ¡>ØŒb+ğ:RP™“U8®¶vÉ^|ª23×_Smğ¬Ôè¨±;ˆü*ÉG)ƒÆÜ'§•ƒé=ÜñèJäiÂ3>54ÏÓ–Ü´2œËIE¤*Ì~‘áyKAï‡mb­H‚!Ü’Ga.œÖY—½ğ2Ó
SÌ27âw/¾7LùS¦¼‹ƒrëØ}HÉQü5§›‹Â„@¦èkk‚ßH”umõçCDµ>Ş¤¡“{Êñ¹„G&Ş¤%Şn£:)îøwíÙ¾¹—¹zõWdĞ!kHZ¡Û€·R8ÓÏRo4PØÓô–õ4)!ÓŒš¶0@ìø¦uÓºtLK)nÖÂjƒL.~®„‘zĞ`”¸:Ö6ğœ-£Ù„Za(C° Õé@ëDÆc$¼ãûÍgBÙézyxzç‰÷+ÎäŠ&Õê 	ª„x	6Âà¢~RÔ’ñ³C•@mŒ™,H3PÆ	jP	‹rù(Y¢‰'ôÓ6ƒËúİ“‘ú£g©¿`ŸÕ¦å@-óÆÔãÛ6C g`Çğ’Æ Ø›•Qš®Qix6¦Âáş³&sËâa!®˜qÜ`2¬-kÑ{›@;y-Q|9oU^	*K.î~JÏaà&COÉ~%Xsq¡|†p€¹nƒ,|Ì²	¡şõZaş,,cí¨ ÍÏşƒÿ„?éŞ­¸¿øP=cÒ…•%ıØÛyŠC¦u6ŒôuşÅ øĞkµgõÃT±pà¥”Ÿç3Ÿ¯ÃÖgL™Ğ3A”ˆz€W=â¨.}f‘“)
¨cıè:½ôÿJÔĞñåÏO`¾åhvIÔíâx<…›£êXˆn¾;hı¨ıÊGÒ~óµu¼:õ-WDYU×q+]Á™.`#2ñÃ(ÆÎ IcZê¸åø¿5…(‡ø¤V!çL«œÒ»TãŸßıÆ#6=4´K¶T[µ„Iqßê[âÚ—ªÉ(ê¤¾ûa5‹Qpì<ÓiUÂ0ˆÎ5>ıÇñâX5¼1^·÷Jˆİ2[´¼³“¾öÆ|aJøé™´!õ5n”sb`Ç¾ÍC’1°°Væ)jZN™?g€ci)”8_@¨W	b?roëQO
&fBÛ¸‡ºGfÆ†ôÄfß1CS“.ÔÑ“)b$õDF-É¹ôı¯}‡ÑôMKo
­ñu¨j„äi)(\ùü»õÍSøT>hf©öĞçG=;4†&úRØékr(®Ôtƒø…(‰$ÙN[7XëÅ7Ù÷K³„5NÎ|\Ë|Ëë5VoàeYÊo=ròUˆ^”
Š®Õ‘3?oÑº|üó^@£Vİ`
íÍ°dªæ½Å9İ’Ó€m{Lhj&é„‚[±3–Î­€\#§#L—íW¾Á£±ÙiøÉ%mÃ4¶Oadã#š]ÜcG€`2ö^ÌÓgµ6ğÂi	¥=ôvÍø±±Y4„Ú{mâfÜ4V&ox›xä¾¶KFı™•ÁûßöŠR„Èâ+÷½øwlqĞeŠpixetÜÃr˜—göíŠ›Laù…T×{B	–˜Ê‘†ïPtÀ¨ô¨›ƒÆÖö¥îĞ‚â(ü¡æ7¤u;úûé¼&Ç¼˜~€¢“êí¿êL!·%=)Äºâİ»c<‘òAæyla%JÚó°C}¼F†á©ĞÅœŠÅ~£,Y¼£õ¯+§aÁü5g'f}N“
÷‘SÈ¥i³¦Ìjòı©SÓìÊZ÷˜uÉ¶ÌL"ëgib¯½t¶÷ÆúËìikÑ3Êş“©y¡ŒgcÑ–ŒÓ	mÇá¢:èrÕGõğ|}Ùœïş1NSíÙä©‹‚S|9¡›íĞb±x}ìVQ
Ş÷²2èylú‰½tiûeÅîM5¤·Sw¯à	â£R å»¿Ì¡áiN±Ú Ú	28ÃA%˜¢åš¤
”Š(aÃp?ªQ¼m[u6È]«7Šj\ÙËjOB(j[ûîˆ¹]µô0·„Ê½LÔS¥ŞĞ&²“¸¡?¯gnÀœ\’!ÄÕvVÒ6‹©õn™ ä:$¿!‰mÊÈµ<7™¨‘ÖrªÚÍ8Ïc”ùÆ{•%±wOó_³ Z^Hb¢´ªˆ×›
ûiÂ€Õºÿ.1”şQ‰¨•§ˆWÄL}á#Cd—ùPI+<÷>Öb0Ø/ÔğË"}vèn[ªK^É‹‰î×‘S Ú‹ŞÓÎw£î»9’éQxÓ¡Ç†æá9×Q+ş$ß™)¬Odí2{\–i©æ³´:+Š13Ú©¯nIYxã˜Ü«¡[Ï<İQ™ÁCRrIù}<K}½‡Z¼%ö À^õã«$Ë^Tñò8»`ç×”]ğ_‹š¨¼ ‘ÓíØÎÿÄSLX…òÚ\Kë~=İi¤”äï¶qãİÌPÜPÕöw™³úõ£Å®%dë«ú\`¨¼İGÈÔÂ‹*ÍĞ“¨v“ŒC®Çü´Ä­ :à™lj&è…{=GUå*œ5ãaö’ÏEnÛb'İQ-´:¹£ ğBÌS)æü¥ã‚›=­{_
 Šòø7àÈŸ}èĞìÀ…âO1¸ü‹#Ó5æY—i‡Òy¹°A‘uòÀ`”s„í“ÓAoÏv#;Ôà¬rs¤;3ö¼†•^ÁvU¡ÄÚ´Nf»§·"ic‘İ}Gà½>ÖĞ›Dc0ÇœöñÊqA
Ó…²1Š,IZÁ„Ù¹ÓGiâ)¢s ¾ò_ü{ÒÜ6ñÈ=H¿2Yãmø0*²ò°bràµëÖ­8úYQ§8«	U‚ª$öMcí·÷)•"ï°Î:o[Uó'ı/ñ\'Ï¬"àc—†ğRN{6C{“ï´˜¾àV8¡® WP½&‰zˆïÈ.n?eû8ı[,-¬"%ô;÷/>®°ŸXäÁP`Á^xñ©JQüu ®iš;ÖrGFº£Îº‰$î?Ùš$QƒÌÀÖ&TîQîÁßbËjêv |£¬^K³Î=ü—§4)vfÖå2´½~.pOxı,…SS|Iá"Í=^=VºB±|+Ö±¦vğuÊÊ9¸˜M,l7øœRÓ=0jhºàù‰8XMe	[Iõ¶¡®2Æ3ø%éTŞEâ~Ñİö`ú»\,
9÷²™Dõãº‹‡Ù˜‚‡J*q¢Ï€Â‰Ú9Ù—OÊ³l›ZˆSªg,id)òTâGáßé\Òhåşø6[ÆVÖ„ÎA›óbf˜JNŒ…bó}Õºj‡ÈO3ß-7”¯Wú€#¹€±ivÅ×ŠaÍ‰ÅVTÎ(˜ĞÄîø_Y±Ö¨¿ìE:ÆØeíO
O{.òqì)$Ùı¯.ïÂh‡¿š¹éoæ‰Á~Ul¸ÜÚBúT;¯ã1|Z|mÙ#'â)Ü†ÖP·ıû?p”³ÈE‡4»ìqËPiO„äã@òskÛ)wéK«xJ¾›Ö¨¨§ìT0îíIåŞ±ˆ‰Æ6b-hU§pV8­ª;ß»fí"•ˆ÷A=rÜ¯Ú‘º^l÷ì(Vb Ğ=ïü¹Í~déS7JšÇƒqI1 Ï”7+7~æ’;0ª»KU}¼ ÄßµÒEä²:‰ª»êr­¯‡7YŠXNä%¦¼D#®u0×ĞEá>'ñ ¸<bï<}cZ[•éM‘‚Z"ú†—¥ÜöÊÖŸ_Àt©ç¹~öÕË½İW½+âãr¸¯Qo…S7Ùsv>CÇLÍõøğê Q·µgkqøhŠŒşûØZbÀn÷kr¦É¤K!‹ºªp:ÓW¡³–S®9ûdîjğ ÒsË
Q.ïx<>ì®ıæò'ø%(OÌHáqO+7Ú½+ßMë&e´X·GÃÿ(c¶:¹µâ“hKyh&½Úmõ8gV…ßUÏ|¿ª S°¦‰ÔÌ8ê[Š0$/­Ú~¹öWŒü]¢Ù³ò2W<Êÿâä¼NTZn[ÖR¹yå¤uß|~¨†Vóß)>:Ö³?mœŠ¤uİ"mœpîgö2ªßÃ _’r‘yI‚U]ö‹÷É\~µÙ;Ë«ÄµEl×úd§úıñË[,¤ş«		fWèÀ¨6§åJH*>ÊD”Ÿ¦ŸœÇ¢.äº¬!Wx9¤ù§Ûçtd¼-"™ˆR‚Í†AàBßÈj§¾€d^ó„ÔT Éíy–PjXD¡çGcšRVëTYlŒıßZ†²ºÓKàVV D>2ª“šš:!>‘ô0åŒ®‡hõİZÎD8èö~•j1‘˜	ˆğÙs2–c=ÈİSêax±O+¾ ‘s¤5H½$á=¢æ;¡üÅæøs¶‡aáL®Â>.†¨Îá<1.,v=
S*ä;
ÆSåö˜¯eäÒÇ¯Ş;6a;×-hpq’¹-¿Â«5;‹	DT`  ùê~(£Bß ßMPãıãB‘¿¿¶–œÔP…òSœXhÇĞÑ’× ¼Å›"îàòÉffcWPÜ‘Û¢èòø7+›Z8Qar9­PIaO·¯ü¥]-D@RIú^ØÛs˜”úã•²ø¯>C¹ß.·ªæÁÄ17$‹Wô°º¸ëH²2: ä6»uy°Ÿ9VÄ<­7ÓŸ1†ú¨§Wï%-{ƒ¿×äG©}€"€¸W‡H·‘ü¬É‹;å÷¹ÇTÄô
Ÿ}Êì×½çßië ¨Š ßÌ«»(#Ú2=bUpMiP+ştyug[™Ç²ãiõ”áşÆıå·øÉğ+>Â>œyƒI‹X:6Ì]Ç×(ñL	.6fA‡(<Ì[ºjÄuî¥X	ËKb[Äì"kgi`ÇÆ?S#-ı¶Æ¬
a;5G'Œ^ÙAK‡Klv.‰Í´û»8˜Ò»íöÛC¤X!òÒ©3ä,›ú®l0‹w»ù	ºP=¬KÌ SáF]zÏxCÒê–¾CŠ•lğ¨tv o£ºQ*4wÚÏ
töäIX3lÚLŸt¦i¢è^5«kıæ{ñJ÷o±[a·™ËÒ{™!”áÒŞŠ?sàù4Ü ÂPãù?¤7‡Ö·Š|ÅæFÅ0@ôsªRgyØ4û 887ò¥¦­
Ç ³‰Ûb'İ—ì¾úÄ&D­;!j‘úÅm"¸%Ãb"Ir~ë™%¦mµ•Ÿ4*{ÜğÊ*\¥s‹ –g,ßğˆ9\<<ï]QÊ§MXÇÙBl×˜Œı™<ê( n}Â—^n£9U†{èó|½µ«¬ø³éò]I\rÆ-ÏËÆ2ĞvIt÷¦—Şı„˜+ zÍó‰'Ó"°4®m`ÛœDŠ%M¹˜aÔÀ­!c´Üò]óáK.1´Ã§_ö”¿×4I ıÜ9U¿ç{õøyåNZûñâ‡ÀÁsã»!ñÖÜZ¨_QT3yìË'âc{ó­ƒBb'zÿ¨LpØ~ÅŞnügşØVg [ nNQ‚¸¦UJ…ó¿}[0Ò<àÔŒŒtßîÂR©S[B@4±u/JE–Àµ:GÉB1x¸%…§¥ÔÕ:ÒkfzGĞ×gò'7cÇæ£µd ó·±oÙ=í~&ç‘ß-:GCV„föî§š­¡»ì.AÂÖJ8ò¼5’m’ObfÌ·çƒ‡«KÕ"âo‘i)VY·‹ÀÀ‰4Ò	M8[âMçj‘+£Ğ]+ßR_õ“5.Ò£¶T?Q[±ß‡³{ò|áíP*4_ÀÔø
‡:h·ál¼[TD˜)	Û~€š[ ‘¹ÖM(ÊÁà‚@åª¢éõS¨>Ì„kĞ•McÍù’Šöî›óM¹ÌÌ#ÚìîûùØÓ½Üº-²Y„¹Â¹ßó5;	z·qøş±¹%¤M=¦±C°ò¯Â—ÏP€Zƒ3—uBØîDÜ±DfLrtM]	‡¢aGZÚúï¢ïM€9á)jÑÒÉ—8šåª›§
4÷ÌersÉ(Yš8=ŸîxÑ;Øx‹lJ•š¸¥!QG¹œæÁaª	*¯æå›şØ>¸=İ)µuâ:oYª_F°çó`B%t—º0¾õT-	ïÒ,ããdeü\u…\­ö»¶Øid
Fº½V‰î[û|,î¤¿Ï)v-ıCÒ¬‚Ë(à’oR^Û‘ÃCLá?Î¡/&é‚ë‰¦¤_ì¤çQSçX‰üãx9^9<J%ü)‚P¶¯Uò,÷¯e2ù°/’|¦®³=‹_òø÷j—m›Uı‘×ğnçş$hÆ
®-E²qTãÑß		sğşAï.t~¨Ëƒk‚ÅëÀóï¶~T:ÕDZ¡¸Ğè&õlğ&‡º¶YY8Ç«k0ºE,Øª0š¢./0Ûœî‡•Ñ[ñMB®:M¢SÇƒ­5² QÑ`³‡è¥»zĞb1=×öÊ!üwzbuÌŞ,°8Wï;„eÄ«éé™<Šøö{TWû8+==ıàOb=<î"Wªô_eähyòÜ{A2¢ê}gSn:u€¥‘Ìöy™™ÉÃ°Páˆüğ½„ŸŸß”O7 ÊJ+³ä—h>âc:È‘a‚HnáÖîX²—â»'M”B½Ï‡®¶€ŞOo°“€ÄúU‰‡x£ƒ±ôg~€<< d¾!ÓdcSšœ0<úöãìm(÷ôÿï"2 ¤TÄ;ÓP¯ğù­<M{«tÈ©ë¡»eÅ½§~P”‹ì<Ÿƒòœ›‰·AŠLëÕ³‹__W¬°óÕ9¢Ux‰T&<ùa»İjÃX0Ì`dµÄI'õü&Ç®¨!)‘Û‹Š2Nğİ³ÌÆúgR}vÛj¦ĞÑÜœ¢ƒÖÇ¡VÉÌP”ÅÛ‹&oº±VK}uAJ²·Cw–ÍÕh—~6Qx]ü±õ[y@8T‚ÏNpÚR±`7´‘÷`e‹qø¶¨÷¸¾5‹†("ú]sš¯ÓhòñO{Â'˜-Æm³Ğ®·†Ä.\¹RÒÔtP›ğ3o<h_f——Y˜¦™‰Wì¤1»øÛ@Ç™¥ÒÀiŸsæeS]Ü ìî²‹ıß;³àRQß9óE]r¾?åø"cèÿª_)¾3C×€ñ;":8Êøîì”p\´ŒM™tşmÛMË†¥[­ùÒ ~h)XJªx²yü%Å–E¾P›µÓéz\”FT+	¸hÜÑ×oÑÖû©;²C€‘ó°HpCß‘ÌÉp=÷*‚$Gù"mnxì%OE¨„­™QIhyE^»úÛÁP	„°15Â-E¼ßM#ÃÿOUIâ4d5ö(‹c‹LfXŒ½Lùí²³ôÖ.âöİK“İîÍ-[î3ä¯š ‘îéUàtÿ'`kIXTÿÇlÄ7HûJ×8¿kÑßV!hgW¯wC'Wı’>á”u?éŒQâ”[¬yRl€@e®S¡œ)²‘!hÜ»³Šú
Ø¼ÒÑòiNû¾ë›İ%DåĞâFN‘äMšöÈÿ`‡ŞUÇ=IDön‘É¿.Gü¢ò¦Qƒ[ê<{b)P|çQkJşÓ;ßßê…­GÆ"K¹AÅ„#ò„×Âjv®Ğ÷ïC©«ôŸĞY,carP&›Ï7Œ'x´ïÍ÷¹ØPc^°jã®¶:{b±ëwµ<%áƒl“Eè64ÜUh¼Ê›S7á	(¸œùéÑtµÄ	—Ây¦BÖƒQ<g5®B}yÓˆŸüå˜!F—¢—ôß×j#Ü„$ÑËû¾õâê`Vb×èeR.lE©oUºÑÑtŠ%A%Bªbı¶’°ÇQ“$İñ
¸s^a³7³-¾e £Mî¢œQäûAñšŸ8·.h(‚;y#ÛğÚİœåTı¡!/†*—è•zÕÏ†×¥óÀ"f!ß´jAí!ÂÓUğœnC!à ;öÕ?-ş»%bK=YiESçí”P‚"äsB¦E—ğöØşSÈôF`†8¹EàğƒWÂ¼É_–BïlÖåèÓuB¹]W’{~ß&SÅÓô0b¹¶$ßìo")Å
ÛjãúYI+¡r¿R£ÍÊÿü¢H·J23%&=&ÉCÁç„ñ·R­Ï[I’ã½ƒJ8÷Sßûè™ô‡A†w„6Úl X±ùw¤Æ%^Ú²xáÍt>Sü§ºÉ¨›È››ÓÂşF2éIlåÒZÚªÄ×î©&îMfAØ|‹(ê¨ãôîùl…(Ò"‘Ÿ¥Şıû=_Ú%qè¥·ëAgf1ê%¤?&Uİy˜…´&»í†TİºäøÍ»®ŞÚèÛnÚ:8s…Å+›J÷UHc?Ê%?)	º—S96±fOBKÿát‚Ê¢¡İUD>ÚÂä­Ä_°û{ª®€iQ%Ñ‹°sÌİ_Àğ
ìĞØÓ÷ÓÕY_jíãœÅ‚¿Qƒ«vˆíº 0ü½|âÍg¼Ç=&™-EÚÁØ„kü“ÿ5oekø
Uƒ¸¤Ñå]:¼I§ß¡?*öÉß¦+«‡8ô™¬%™èŞ²÷d[» 10Úa–?ò#ù¥7‚rÖ§¿ô»ìÒß;w4ĞÙ~’J¥;`=zfÓ€f—‰+’\†ã_
›Ìşan‹Ï:Ùè};~üq£®Fæ#ÑŒX^4"Ò„ZE÷#ïÂéß¬àÒdäİ²ŞûÎzj&]"«@Îtxl…CpËğ_Y/r‹ñ ×lÉÁ¶â¶£Åú-‹Íğ§j p|Rº<dú´é…iîä]¿e£\/rCíĞ?ÙiÌl”|Õp}‚.§ßº¥wäÓ˜Ç³Ò7GzÅã¸i3d·x‚«0ƒ}7Ä_0±Õ¼¯Ñ‰„D8>w¶g‹²±+ÁzËóõôMej¾Ûª¯8ø€¸?Âv‰M÷Ô…¼¶+€¤¨è(†ø3±ÛoÄuO–W7Io­>\Í‚),¡)FqÃöN-0Ì¦§;KE 3?™ut 6QÂAp”½é«#P<!ß÷œï{«€ŸæÑ¿
ël›!®–:×Ã³²@Zì9Ó¬%¼ÌßÆà®7ÎZ—Q{×#" õœŠf6Ú]ìós~=”Ø}ş¯OTßúË`>eºÖfG(Õ&‹ŞeŠš±(ÇYfê:Éìiœ TjF»«7Ípµ™º/ê/÷Ìşm›hw‘íä{Z{úİ`gaD€«†?H.x ¤‘ípR*ë#’…ÄÇUcE49W¼T:Ÿ…Õ¿ö{ÍŞ,fÔÌ&66ÔËÇŞ(C£Ú÷^7ŠÄÔÆ¿a†Ò	-Vô’vPÛ‰np«´ö	UºjX“÷”ä!Óª¥Ã+8ÿ²*GOó‡lUD\íaÊjgğ‚®„ù‡6¬áRB£:•\ıÈÇÙäiúvÕÎ,ÜúÈ«ºcTéúŞ6tGû+¦Ë)Y3B²“PøM'Šæ;~Èù·ì&d6˜€åPÇ¤‘ò¯¿ Ñk—}gQy–äÔ4‚"[_òÒ>slœ¦ŸÎš ™I‹‹‹\S÷!QDB`;Ğ¦sKGÜ a¿ÑO¹½ÛÜLºH½Â/7‘;X'íŸåĞ¯Ş0_-õ,¿b‡ÿ{ÅÅ¢u12Î.s.úö¬±ÈèûßFV§w¬0,—OéèhÑËlZÄX÷ô û«ôˆÀè	Îz]¦ãéFtıÑPˆ9ÒjLTÓù»—¨ÕõcHiÏA$İ°4ZÅ‹4÷{ÔFÒ3İU@;DğÿZs£\avœ1ÎI¿4äÀètª‡¿Tª”yv~¨s÷ÍGk	u9|Ìq.Ş:Áë¡=få<³	@Í^EB‹çULÀ…DÙıpmĞGìç­¸m¸}U¬²ÀSKŸPĞè™<K'%ŒàLâ‹y»LøøîĞ‘Zhâ”¬buNãoq;Ñái^ùô_ 4q§L:T5 «ªş§œ>L˜Ãºq
‚UÆ
¶ÕˆªıêÊĞµC°`b-aÒû©¢ëö§å÷E¼(´æß¨æZ–é@ºîú¡èH[`è\á€Ğç¶_Mîè¦7ªRÿìHz63·I&ÙÆ®â0½9¥ æjb·+ŸÄŠçŸ¸ç(Ö¿]î ÷ñ! ê¦ÜXB3AWİÛCıJ>·H&v„änñ»_¤²P>aÚŞœf*Í‹q+ßÆ×¬k
‡ôÜÜR8¤/ÜG³Ú0B®ZœDóÖŒPëô¶™ãw¡ª„+ÛO=¤ä1HÛ¹© ê‹®³ÓV7-Õüs€TñO+f"€pœ›õdôcşØTHÊQ~ñ3ÑcK’8àÌ1üŒó§†zô›Sîkô€P}"ivfåá)Y	_â¡tØã²?ğ?áæ•)ÁİXLÌ›æ½ˆÒïŸ³	[Âì-Ù Ã¹ÈE#ä¤Èˆ–0ë¬éBSÔ×.Ü»ØÕºsŞ¶d‘ÁßÄ
¯1˜6Ï°g;ÿ¿V&„âÑ’ÄÒÌ‚§Z6ğ“¥å]TZ‚„Ò¢MCã°JõßŸ!êE‰üeŞß³ÀlnÑ0Šwdš³Q4N(hvClºÕÔQuÆ‰~àkæ˜#¼ZÆò3œ§´Rp/Iàş\è16#å °›~¬æ’KÅâÌ×1Å	&-ådìÇiÜRLÉ£†öá’6¯éÂ}E‡m?€à’\ĞX_v/b‚)‹×WÎy~#!à¾ JªmĞƒ H{¦óÔĞ®mƒ‡„ñ]| uÁH#êKeæíìœÚÉÇjÌ^>©UØ`}«\7-C÷Lå‚Â—T:Ş;7ÃÛñ	…‹ó”úB²Äß]5)ÿ­ÖôQ<}¸Îíbª˜
¥ ë´®ùÉıNØ¤Ô´"~õ„ÚWff¹i>Âú¼Ô¬RÍ_ö²ÚÒòp[¿}<ç áU48ÆÓò7|0·M=Uˆ¹nûÕ·UH°ë’ÍsNv3}Í{Ò©£„ÊÁZåÏÍµäZ?^ä&g5ÎÀìRéwÜ º’ı¾ºÁ/\óíğFr{Îå˜úíá×Q¸õ¾r ]uûW	šÇ*çƒÉ¥¹dH¯qÚç·Tp‹C_Ğ´àHÙ¼†„²‹*©9—hYûV¢|oªƒ)sä–@Ñêi.—ldVş*VÀSİÁ
˜Œ;åD‚"K?l°±£fŠF)ùäZhš[æ‡öT‚àv€zN´Ğ^º¯çŸß qyÌ}8âåµÕt‹Ÿ½t®s“aÒf âP^A×FÎìB»;‚œf-@´lÈîël#W$NsKÆ*Šº ‘”Ä²º{Ó]0£ë¸ÈA/)G	~L8Ú6´ywZ?¤éMí-Øókƒè§ªº…æ÷§®IìÅÇ—L±/­øÁ¼?Øš‘sKƒĞÈ¨F°±[DH°<y‚çØÍÃ4%ÕD<vñçÌ…{§i¸“ë
¬äÖïVäÆ‹¿¥ÓïEµªøTQº¯ í¤çc%ßñQ_(|+cìCzÊG^îWŠrÖvÖåÕ¢~°—UxûAMÃˆ~5¥ä³Ş}°ğTÉñvpCM‰"¿RÚ{&;¡	w®ñvóBp%—+açtVQpømP‘ÀÓ&/õ°‹lâ&mË3Xp€·#mı°€Út	`äõ_ô€ıy»åO Ñ÷·|X»gÃ—L˜6÷ı¬@ÆÓj±Ÿ›á¢‰GqÕ²¬ÒOÏ™9Nfrµy"ôÓyÄ»tbKá<‹at>;n4$­§ˆMv«Ø‹{ï7±²çğKFÅCê¹«·|p•„Iï£[„r…w,v“°¾¾;[&p7–ÀœÖ¢±á\ñàÿtQÒjÈ¯ ©û^¤å@-ûë~æĞ7Å](\ğá ¶ª&*!ÍŠëRXĞ+ú°c%]zÅXš´ëÁrpW„x–¸ø~«<H7E¿ğ>™‚ƒÃçèd¨dçWc%»V
ŒxÄO“èæ.™u–ÉĞÏà1Zá•yÆj§;À„ş|óÀË^Ô0‚´ÎÅÎ´Bf*(€‹Ù©¿;Ñö†*eO-ı¨³—€Ê×A‡Qæ¶òV´R¾ š®Ùíõ’IÓ7äw,A¬ÛØÏ®CüW’‘çÏçìì;W¬í‚>Ìñ²ŞÉX?˜‹·d*!”œW^†0ƒ¤|¨Üô¸‹":ë	ÅæšNÂ\TEÙ8*9¾Ò¥8î"?#iòÁñ¯ÜÒR§…6Ñ¤Ÿy®Ü•h^I3È#hk/ùorÌ:zÅ„˜c¬²›FútÀ]Áí o¯+—ÏK«µ\.!cM:	¸øcêœ2m–gæ*vô¯‡NÒŸï¬YuëÃLnĞ,)–pOĞãFì=¡û(	ÅNH¸ûÆÊc¶lÅ­Æ'\EÈxßn»eÛ‚áƒsÏ„±†VËw,¼¾°‰Ïc\iŒæYS+s³5Är$ñ0²¸hN”‡ì@3ÔıFLTñ×,Ñ/Öç…¼¼®ö(îİ<ïH7`»obugxñFoûĞÙ-°JA2–÷ÎÔ=ıAY,ty“¬c‰­tH@ÑDG<ì•Œ‰ô‚$½MYc;39buˆb!ÑÌa³êIÄ]æüËöÓ‰8-É”¹Ï_¥œßÅw?¥ë)½…‡\(¦MWXK¹ˆRMÛÚóáú"‚È‰Qõìä¯WTŒÁ é<ı2=â»Çƒ~Ù“±^*—ŞıœËºš›•­—’)¤öÙMfY|i‹úïwíê©Pj4uÄ =¿‹À(&Âç—CÀµZéçût”@ŸiîNge¿Ä&k_‚Y!cè&XDı*=ÜVRªÒ‰
Áã±”1ı^I<¦A·ú¾À´ôKÚlÅ]XOCêú›òVIG? «v˜æê2
¬Ànûğ¸í’Cµ;Å÷ªÔf³C±@>ß–;)wE£7jSMÅƒ6e3èUâ´Ñ¿”oX¯-«¿·ö6b&Ç!¯ù–»àĞö·/_(êmà´´Øf1½z"¥ Õ¿äiï]véÇD=æÓG†Ñ’cP(;…«3¯ß—ËiÎÒÛú£ôµf)m¡EííFw“Rœ\5tm£9}Ïì`W1ıCñ*|ñÏÒÁ	åwm<1òÁt×îà“ï%Óøª	CÔ£v:³Ã„ï ]€IÍ[vWT$ô;¶À³+µæzÀ>ôÕŠú0cT³ƒûèò¬£Á<ô¨H^r¼ì†ii©aµˆÓºx¯h”Ê?]Ñ|Œ¨ºÑ2-ÛøW:xNYB©]Ãf¡½è|…Îâ‘MÕ“g/›)ÈÌIYÂÍ‡K;?„gs(ñ'
4’»wÌØŒÜ¢ÉÍ<·\®Çà!Ã®¶Ü®¼­šUõÍ„ºˆ=G÷¬K©4½†¸ÉÜ˜;6D¥kL&«ø&*ããa°X$É•Ğîš/¿&¥ìØğıÕ£/<ºm*}ªós×	œXM[`âz&Sa³£ı°K}è¥¤tˆ¦†tG«eÚ±#|T§liºÛÕqÓ	õ†—i;m
öt«:¨8#Z—¢Šjü(ÃÄ.øÂùø¸plk¬ÛºEP÷íRv1’˜O‡$Öûf,¼¹…l4õ§Á[™
âQ©z$”Å ùÇDÿXjlIç,ÃyN¬–>"Ğ+l#{÷ª÷(¢Í3Áøi%#•cÒ.¢¿^¨–=Oô¸é3¥µ¼l±;Œ{%}h»'I„DëÀ‡rˆvF¤Gä*ˆC˜g2˜rnù[K˜ÌåÎYòšÊÍŸo¶¤º5vv™‰šVsÙZ^ó¬ä¶ãŠÇíÁº.;`>ÔX¬g3Ïz"}XlèKi•ªGî6•iĞ8Bj‹•*Ëã¦’€İ/.C[(!ùTˆ²Ípßè}nk¹Z.™†¼Qp?ûÌÙQùŠÒÒÒnh×İi±É$·«ZÅ8—šØÇ‚ø7¢c”< /H„5·Ôó–Ç‰:Óé×'Om>HÜzØÈÎZ„ôé[˜¢_jˆvE¢ĞÅ´V8Twşïìñ:Ë“°-b‡ I|ß/x[C-D©ùHMnÏ¼”€£[±ç[â®ª‰oÜ öÑqRªÄ|5på È‡!éiˆe-}«<4axÂ^¿ªVq¤—­P‚¼ÑŠ´¨cÙœğ‘v~¹şøÏìŸ‘¦äéchÆí\Ÿ\ÃŒ—b†J¿êÓ,i…˜¾X& ş	C’ï¯øqR“½š<xM{Ë%øuïE‡­¯ñ4Lºˆ$ ¯´ Œ%$ÖÇşÊ´3·î
~„ûBa=è0£É*K±„‡3š*j¤V4¼Ö’”7¬Cüm†ñ†O³"„5 ‹ôR$,?ğ<¡6dhœr‰ı¶ÑÈC=½ÀÁµ†%Œª×j$3Â•¾—`^Lvõf‚9}çŠîäôÕ„ÊÀÍµ
CEÂwû£™ó6ä.ulÒ«rÁ&—«!ÓÕÉÇ_¼l~ßË¦‰>ÿUOhìŒı£ iyN¾¥UvY«ïG7™"L¯qöbj(/ùûş>•©êÜ.¡–å£À;æ¢6aà€lêÎï…Mrq¨™’·õ¬KyM Ë¶ÿÒg,¬g˜3vÈQrrÓdI£¬dìYÌ@ÄšÜín{É –wO¢hì'•cÖ<+õJw„F“ÀceŸÈxäÜ¬¾4(òHlƒbJ3;—Ì:îŠƒ¾lRwxIµËP~¤ÊËƒ6öt†IæÂæ4ºÍ%nÕ†|B‘xzœÖW Z“˜!Ş—–t›D¦dï\Jéùğ©–½xÁ‡u¤ÌS\xq„ı€t‘‰ñ.fºTnŒ•_:ñIÃÙ®$IÌC˜zOŸ Á
ZŠd½­‹=£ÿílŒú¦Æ<’ıDf<_ëÕïÏ»¡
Ÿø²¡¾G´–ş—i«×Š"2ÜÏ”	µ†¨ä\ù5/ÌŒnùPoukÎ%œb?ãìrîhYŠ%¬p?ç„ßÇØè½_Ñƒ“»`.fˆ_æôğı¦[õRÍ³ÜD3 t7âr	’HÓì0”õ£9ÿ¶FÕé[”›ç=€±ÂˆÜı$ÖTäzk2IFBùôclYs¦¬pÌëŒº, Hciæáünè8üÕdH9ç~´a§!t‚oMt¯‰Û»?~s†özr9«¨hrvñÆôÅilnªû‹B>]nÎ.ã×WmÎ÷šsF¹¬J½<¡€óGqŠ6à¨W½ïC<ao\ÿÜ­€w¯³9Êƒ[Lù(7n÷¤QxeO°ØèÍ¨«só¥¸õ¸5¸|ÜèµòÈag—`1Ûícû‹XPeÏE[#ÖêÁã¾$>ú·Ê"•Sò«Oöããs8~’U!ÛÎ#íQ©š@+Œ ÈFäxŸŸx>×då½öûhôkA¹Q~Æäe ãÃÛRkÓƒ¶ûêÎ¬S²º0p$ü,Ëšv¢eZ=€UƒhT<Œ>¾'í;ÌˆF×|5ae_zã
.“´k^4@®€È€¦ËØ’öœ‡k ¡.PiT &ıPkÜ-ş5øÄÜ„‰¼K¼vc’SÇÉõ2=Rî±>›,‡œ7Ñî¼ÀY¸Ù[ÍÉ5’(ÕUƒ|9®¤Œ­n"
H=j-oØB5Ñ2·¤È/·æ¹¦ÖÓYÌ:`ı›ëğÚøcT™Çµ‰áºÓjíÅğàO±=Äfğe
»íˆëh¯ÛôœAÅ®2N§Êèö>ÛEhõ7:ê°ºFºÇÀMø§Ì"w4øUôÅCkmİg‚ÿªYVnrˆÓí¤:T¿êÖaÈûd¼:È®É~ÜF„–D¢yÑ£ áœGñDÔß@wUˆñáv×nMj§wÇKOVu»¬V"L…›Ù"Şú$§½D}ı>‹mngĞ!ó	‡R)àvç¶l@//¿øa@näD—h‘Rº<fëØõW@Î³ÅZ×"Tn c £V@ZĞ1—N=®POêw/ëo3qşjp­¶+ÖÏz¶êbĞ–ÌïKxœÖñ/ÆLC6õ>´eod‹—ı€.‰ú{`ÜøsĞX¥×„L^Œe³ÔOã¾zP¼%à##@c™=²h8¨`¡?ÊRİäOıÙ2ÈÌ»±:ÎáÎÂºåI\}¯sDtÿ§Rieˆ=VsR•œrG>á	½˜<»êÃÑï±\ÆV’ÿ/—dÃ¡6NÉ°j™—Æ‚ò……—ltJìB8†ó‰²kØ?ÉÌ¶|Ü‡·â$TvëØJ$    ‚Òş:vû· ÙÊ€Òs±Ägû    YZ