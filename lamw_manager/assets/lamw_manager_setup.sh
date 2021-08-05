#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3012940917"
MD5="cafd9fc3587871c9b07256f465718e4f"
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
	echo Date of packaging: Thu Aug  5 04:15:01 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ\] ¼}•À1Dd]‡Á›PætİDõå÷*¥Á‹hv&KĞ“A™fÍ¸){¡+D¾ÛÏš`ÌÚqÑĞ+’N ³|»ÉôÏ·Ôo$4Ş­ÉÆv±µED'È¨V¸HÍhÖö‘\~EÄWR!şµ>&JÎî	…a¨_}Yµzn=­Ò¼7Yéw‚÷…™UKàÀ`Û?Ã­!'©{üñ¡òÍ~‰’¹3çûáRAƒ¡‚ÜÜƒÁÖEÁKöÙò.çJoÄÚu‰‚{(L›Í¨×êëÊ´5·ñƒY;o—víy¢@–¾ÕÒ%qÙ(ã§™ğ‘È³^}‘ç´EVƒMHİ/t3Œ‰5$F[¨ƒÍá¸æ§¬Î“_Ü|òÁW &²P*ğ¥ódï’ßb¸Ø²·§ŞF	æoÍØ[Égi–Nz%mA†?‡«Tß
5\áfo @Ç_Ä?q2`nË¦*ŸTÑB$âÍoëÔ²µĞfÄ«Ê/È†BÒw[§_'[©âÆ×±ü[5Á!ñJ¸^ûHF<iT«Ì{ï"óNûö¯7¤T¢Ì¶6ÚÜ¹N%¼h“ôÖÆÅ'Ğxßƒ=…ß2F~8&ÊÜÛºcuÀ'¾tã®fÀWLÙ~À€uˆS®<ÒW_9í7ÀRa,úŸGe»ñÚsòx( a}ÔV“J©9oñ‰Ğš.‡¤'nÒúÛ±GÀ6·ĞWõaâ˜z ĞÄ¼Ï;ÆwşMìgCå`»ª
frşûèô7ÇÕ‘ÕåÓÎı0Š]Ğâ€¥şÿÜøÔàêGÈ½„ˆ¿×ïX¶Iùçş1BˆdîİšÔ¡ÅÊC˜·]W$Òàg ¿o’Îé¬#ÃH¨§±ÖÍäM×Æ(+õóÄÅ”äÂÌë# °ĞRŸ.åÇÒåÓFÜlkE³áF•Ğå ‰j ±#—z¨‰®Í¬¶fUÆ•“iı£@bĞé¯»ÿb÷½V QZ1ŠŒZè’ïùÇ=ôè‡õ	a¯LÔçcEoVn8F¼-E´t¨ş«}û…¢ü¶¿øÖLñ:ôa—îrBùÆÙ4aí‹ Æ¸—˜zîg÷¸ÂìV#·ö@aé"øˆøi‘í,éÊ<·s¶ö@˜h§bR÷Ê…ã»’Ç"Sp”˜Ê`ñ}2T¦ÊY•e“u¬•®µØ$Õî‹hğv<Dh2Wwem±äÿÂ`“ÜØB`)æ#´OŞ2í¨­ø„rXª7Us‚ŒOıš0í«FÑ‡šÌtOê•~Ú¿´² çndŒYv’ÕúH¹&°BiqoÈ¥Ù'ly|ê³J'çjÊé£ŸX¶æÛ
X{í‡UC•´ÎªÄ5›” ½1oŒ÷’L†]ZiˆÿF¯ŠÉìulŞ-¶*ãıoj¨Ôüy¯ùC!k£ÜğSUø¡´Ğ·~R—|»$+Vƒ™ôİZˆ ‚É=¡İ”Ì‹Å İ¡cCœN$~7"½Q…·j0¡#Ákª?‘ ñj¥'|nQ+ß–zxÇ(BóÊ¤ÊMIé©×èğRg…Úaü¢Pæú–¿QÇˆ^‹\m3€<úØ
:)åjÈânµ™ø9E£İq#6@ÔiÃV¸WˆcÓ "Å;ˆhµÁl±R!âç˜Jy ³qÁv“ÔÇÛíí†Ão,X°à …2!E$–ÿÌëCE ¡*3®œ•¹¯§ö63Øö²ZÒT|`Q·RáK
<½ú5r€ô¤±L!wßõ`¸6Ël›-!Ÿv©Qâ/«ä_D`hsˆ¬¹ÄX§ôû–g3e0?à¹mÆÊqé€İ´;æ¸?¤œÜh}ì¦ ñùÒ§Ÿß54ŸéL¯^£Å'íMµÇ7<Ó:.¬²Ü*R{Ê[2q->ª•ß#Â›£_Jıûµ÷Š47† ô‚(íªmêB›zCÙ¥I–f_z%Ÿ¸<›iŸrÊëšğ ÿ7a‡‡ŞfDÇY”ŠV€=ƒl.•`Fk!´uD2’!›R¨;7%TÿcJU8»&Ö«ºrüäx›ˆ?ì¬şŞ€>÷–KGBì7ƒT¡•?FBöË%^3»QUÉæe­[ŞÖåpÔ} ’ƒù#²¬š?‡Sù°Â]Úªïbúº=’É³Ä³Ndto~`FÅ[I3±™¾Ï–ùs¨ÚA@°LMÁ»Gõ)ªqçÿHn0[K˜“j–•h5EPo4€¢ˆ8+}´İ7ì÷ó¡¼êÈsøàŸwx…xøoLaÓÃdÙÌ,Ò‹{†¯üì›Ê†X£¸NáÛyÆgªè“fï”ÙäK~ÜÕÑ'-Ó™$¨£³œ:“Ë¦‡ÙÌivk±qq‹Sáar® á·¥K~Û­RO¯m*ŒŸ‘gÄç+‚v•õ·;$Ä3TGû'ì³D—­17õÍ1úärM—ÉŒšz·8~\«xKvÏµ¸ê r0÷w&ìÈÆBŞÄ»ÑR5FbÄ-ØË#iìê:^»^¨"ZÔ©¨b$_èT»‰TÇëp4¦«/*oÓu•^@6bÚîÀ·½ûÉØgp+AÏa@×!¹Æ9&É8Ñ,YªŸî»¼D˜‚<;Dœh6ÁiöR÷‚ÀóaA3Ñw K]$Sj†`÷c˜Óæ©vhìÁ 2Ğû¶ÿÏ¶à½JäAÁ—²b!Lº •d³—ÅßA98’G¦0Y}€Ó¯ê¼ ‰ìÉV<á«dÛÒûHù/üúÔ¸EAµ§Éß`‡³Á‘««#¼(kí;Ñş÷¹üì;s›*	&Âƒ˜6ì Vdúi–)ÂTçÕªNµ@¬ßL¢Œ‰¨«–ÎuQOÂİÓ]à,yİ²~‚›ucÁËnŞRbµ,ùo•*­¦/6ä†¢gRâäÁ@0©zÓüÿ‡5Æİ5|$}M˜µ¡*a\İ•,§ñ1ŠŠá|€i†ñ„¡²@ÜmÒœ-ëP²g7„|mäÃˆèØañ‚1Áo½<âQÄ{±KÛ7ëRPêı=C‰SáÌµ›!dÒP8Ì´¿E°wä¸ğ€ÒF;› ±À@lÖZ½ú§‡u3÷­N úW&ô§$ÙßùŠà¶‹Ğ­#BèŠ¬
ÅRiÏ94ƒéö¦ê:Cı›RöúZGI¥ás×y‹fŞğ}ÖÇn™—}8tÊwé®©xº%%ñmc‰3Ó¨9$YTæzè61°+CLpÿËÌ³Ä–Xœ–ıhEoºXi`¬$¯WŠN¹œl·>¤=+çZñÕr…«ÑgOÄqÄ§Xn‰¼°óæ®ªM­¼?Û5ÚÀÒ3±Q şìoÅ›b=Fø¯û`[~ïÃÓÕªg¼»¾Ê!gYÀa¿løûG:¹Ÿ¢ĞDEÃ¾8woI;ÖêÍí/0ÉPœø&+•)(Dw\ÆÛ|…Ì™!³¬»¡`!ı(@wcÑb„4ı<Hš!Ğ	t@ÂbeŠ>ãÄø5–yQ'#éÂêMhádOÚÊ |ÇwËv¯ã³9a}—sñÙ×Dãy8á#*åÕO¤ô’i&’×5jŸ/\ô5}|t_-ÛÑ$Ó˜=xÛüO93¸çe™9k.±e‚’öÀ(@#)ù!¿µÍÓ¨B%F¸Õ\ÎâÿÃ LcµÉw§7‹L¹{B: ™%TUÖã÷ÁPsª¬¾bÂÕõäƒûãF™\v™Ô1ñï»ù‰4AÙ)Ü‘n.˜KxÛ¨0ˆáÏ;O^|*?hI*CÉõÿU
™VÉ%ÉµÚW`ï˜¯˜zB§xúyq:/@[ÀæÙ¸dœs-	ø q¼Zü-†Í
±jæb]ã^îôzu…°„¬¼óX(Ò)a>öC‡±ñâÇÈÃ¢¿›G1ˆn3‹½‰¬RòÍğpè,¥ÛŠ) ÌmƒŠÙ;ìô•ñºU£ÔLs85FX¿¾ÿ×ˆba_ŠB§[.uìÕŸv‹›D0=•xI¥ 4Iºçoœ¨½Úw0“(£üúRãõê=†‡ÒXŠ¹6óêë]èÇzÉ’ÇUš¦ég³‹şøÈNúx1ÚL#Á¦RŸı’û¥äJû¾K"ã×íÛ)×İ‘ÀÆü´ŒajT0n!Ñc´é«©4rè<–Tåuï=”
â¬ °ÃXR“¦>q»%H×@0Šà(y¨% ‚ŠÔS;t°Ã“t†^A!Èùl˜ _ÿ`»éÙ6ïS\rœ!aU'´µ<T¡œÆ"£ğß€Ô«ùX0ÅšÅ±5"V—ïrTÉs ›x=ğê4Ü„å&@Ğ^/pthç×ò“}Â«e(¿8Öl×Áñ ˜D(áj“€éë‚ø.lU½µwqšüœş3À­htzvÍ4yzGzš"L¼¥•6bÛ“ !—»¯j•×‘ús‡µsçì)Ÿø…Ç¢ÑU6jv`N­“`XHt„¤JWåŠùG-ÌÌ=Ù„{nä¸?Lœµø¬¨å£²šŸóZ)¾ä·ÇÒİ8ÈüÏÍK–iñKE+ÏàñQ‡ãveOÍ5æşÔ{d(¹PCš‡¹*ßq¶Z¤Ÿç×~†Ì–6+Ó©Ã×Ø?ÛwÚ¬Ù—æ¤ÿÂóßÌİh‡š
wm¿méÑIhõCòÌìÉçœiÇà!eRU,–û~ŸÂÆmŒ·í0|ß÷ÏŠf’™ôt›#D1 Å–Ê1Â¦ÊRÕ1aZÎÁ—¶áø¯&–¸¡ÎŞØ€İU$u–0É!$
’Ê‡Ã¹rdšOë%Œ$Ä†¾¾~¦‘9”hë6L¡ÃU«÷»·jxÑ¶ÍMVr¯É«BbPÜª]ÀÏ“*ú®èÑJVM§ÍÂlûVº1×ŒTÊ÷l^‹í]3ËÓ”†pDÒhPU(Z¼_5¡'ï	<r‹õŞ:”{ë¿v^Ş‹‘şbVû”²:­j>˜ŞôI,à)ÜØ°=c;„ïÉbtÛ‹“Wél îÕŒ*IõíîKÑxR	õhR§Ş{6'é±…Á_¯{ÔË½¡É=Vàü3´Íö–âÓº	$$©wòE³Lô“)€–uˆ&¾ŒÎ.¹ Á®>É>½aá)_¶æÒ}j¥=íT.s…TÕ,8²lT£@GaÔ,oØpà“­œ×Í"=NÄş©ïH­õjútƒåÆz'Ğq}€z†`2¨ZlØ§Ú'ÈÉ}Èta™u9ïù×lX9éG`*<…itW±Gz6K^è¹w1>1WÇ¤…¬¤²üªôû›ÿCÖÙ—ğ4eˆ% oã(p-]“À¨iÇ){1t
$Jsªÿ‰âBĞ<± ×w”}¢Noq¥qëÓá}2ëù]ëí¥¡u¬ G£ócÎG•N/Eëd€iÈqÍ;Ì¥.$—¤AêtÙöA!š£óİFŞOTV=4Î”ÊğAwéÏ˜yÕ2sFÔnï²&oÈ¼¹®ãE#[L·*æJDQ[ÿ³4ÅŒ›â÷héJÂ:=pAŠîÛdhª ²5ßØ¾C™²ÛÇç¶›ì@À‘iˆE‹ñÙß}º|Ğ§Şó¥JIz=l…ã†¶·.òÕÅÎ ·^NJÎá¸ùCVN”_·»ç’iÂü^fğÅâWr¦×r¹\ĞnùR2:T;Ğµ}ï^0 »‹‰¿øˆœ ò¼$fó6ı§{ƒP¶„…ÿ>ü§qÎ~¹Š7›:]S2Ÿ„WÅøô`¹Ãü<İˆEr½>¹f|Ñ7c*ÎßÍSâ¼v^&…LF6/4ô~,8tâ-R€Á-â÷ö—x‹®F	®ºóüWkZ\5‹<í8¢ë Ê/ &-š°s9%n™añrÚ‚Yeğ—k`Ãû<-Z€`«I°.˜jzr¹¡,Dz$ÃŸ9¤?Ow‰EÿeSYu,)ÑÖhbŸğ”m˜œcô”JÈ+”ê6Œéâ`ËŠ×î-¾Pä¿Åf%YdPºâª6rĞËëZÎWû:®«_•ëï,í§9ï? %jJÄ©™µÔ°ĞÙŸ:ÈóJ9‹wÖvEc{İdÎB>¼œ Ã
ˆ|üü’nn"Qƒì!©dë7ó"ó¦Ù–ÔsÛooÜ¼¦;-ŒN“¦ORôV¹qX=\ñâz’·$$¨›…ªÿÜ3¶)ÌÅ—OS§4³˜1b°ƒ¼2)?ùĞ0\eÁO•·<]=&/uÆ5xÔÏ³¡tq5'[¿(ıKX­BwOPÕsö ¥•¬…MkÚ[*œ×"Subå»+¨ÿÁÀYè¥³Z>×åÄu‚7­.ßqAÅ‰Ü¯»
ÿ°ÚÙz,_7}x–êA•l·öI,´+C:Ä\ÖoAÄ¦ÖkÔ`óÑ¾<!jìN_çÖkÇK$è2¢ğ`gªc¦?ÎœÈ¡&¸m²/‡S·FÆ‚ÎõØŒC5Å	/Éa\õ*LæIÄyF»=2ëØò‰]1E7r-ğ¤=Ll½YÏ®*Sní“Şë0'¯Ï‘Js^nÀ+ìÈˆ4~Ø./»wÊ¹³ÿ2tşõ:jb`¢Ø÷í ÙASÊàÿj0K`—`*ÌœÁ!»6Ï^É}Aµˆ30@COäÄl¸7âc}Ğæ²ÿ§F]\w‡ö;äÇ_‹CŒı„k1”¢æ79¾,0?åX8?pË¾wCbıhÚ´'LÕS¨¢aKİ–Bv"Š÷sJ<¥Ñtÿ¹° ®‰dJ<:•vüŠZ^uÖãŞ®4Ÿè¦4IZôZ4u†<ŸŒıT¶6…Y²ï°i:]‡ìFÅ
ÔÑÙÜjJÎ~Ÿ§¡iˆZß%…ú(2ôFØˆ¹N¶ã3Nà|° GD¾.ü8 ôÍõ[áû'èbŞ±t{B{H+v¡E¤£Ã°Btİè'E»‚\OÕj÷sEFoàâ¼îRVÙ5ÑÜ^gœĞA÷Şî–êvctØ"Ó:WÕnôÉ"¯õ£â¦‘IÃ£gå‰4şŠ™/8Õ±`fïX=I(Ô‡ÿe+±ì0ûMN©åèRÇ ôg’j?ÍÙáG÷P	›¯4æïUöQ;_.dÆ>y^l‰ê¤‰)ñr©ğ/ûqÜ­¦ùHÈ•bäDvçÉëÚ¼€­–<Šæéviõ²ù£{LİÙ&‹kÅ³wHªş÷°„:v"5®˜Ç¦\ßã_øW¨Ó…]f‰×ÕˆŒŠ]?¾k-Û¨óQårßÂ³oÜl¾(áD”ıiÇ›Ú º›o4rÕ*CÙP%	ë)÷ùÚPz8A<ı¥Îs]€ğlØ%/+ÿ/tué—­EJôY¥ù´(ò1ø#slİ"#ÌÔÄP}—óL+˜íØ”I÷*ÑÜi×“œœeP-”p|^Â"Ò»?
ùPMœòjçrşªJÚ>/6.ÏMÑ
ıúQ¿)ÙÏn£#‚™´:ì2ØÔÜG@^{Ö()†?ßtl×8pjë(ôDÙ4<|ĞÑœ”¦Y}•ã(`ûáRxs	ıï–Ø¾‚9++‹iÌZ¥A‡•jÙLO`kÜ%ÎÕÛÛè€""òÓ„Šı(ƒœycâßµ*¡‹t‡FşİÅÈ?Ù­Ğ<3möaye³—JâÇ°r:å¾—Ê®¥€‰*
‚–|¯× óâØEã¦Aqï1–/Õnõr8Á2«'"8Ê‚,9­Û‰1gñK¯Ç£ê°ÆO}PM@ ú¹cøqÑ«|+–™pKÿ‡âRÖ†á™eƒüÏ©+D4 .Î¤ÕV0?26ÿoI_¤È*ãÏèe?ˆ©-Ì¡3mQ˜nöÒ'!bšvs/ÿcŒ|\C	sB”æèÓ/ó}2¡)Æ1\¾È•œÅÎC,MõÍ$^BPt¶cæV±è0Úccd³ d‚²)W0—¬Š«ñl’ÑîX=CoG<˜åšÀlÅab+C½—íë¤e6•Z·/†'‚Û€ğq"]œ=ÿ·°pO›×û´fô{Z^«[A˜İÒ–£ú¹3¼(¹lnGÄç09eqâÄeòÕ[µåS$t]š«ò7½i}2š¥ŸAaZ²éÅ(f­?	 · ªçİ5M–‰$¦r%'¨HuğEPNnõÖ×eã³­½ø(q~û¾*ñ¸	· B—@(V®ØõiÁRVJ˜°8š-.}Ö/Ã)¼ì:¶|×‚c#eÀî,7{åÈg7Pƒ*-õ#÷{áó£€Òw+Eª0àêY­éuI.Ê[ÚÅLşªĞ+¬|?å%wÜ³×¸~ª!qI£’ÂãBwÑ™ñ‹Gµoxí•-—˜!RĞ=…§TÙöOá•÷Q¤OoAV¥ÖeLŞ=ß} \›Õ8¿zSÉ[@ ÷*•u‚ä,ûÑOà_‰‰Ôcùö|1Çã³3ìKŠ.}§+%İõ½¿›Xuç{5'<Æ§;Ğüç×&ÊV£à]¦™Aµ)»?”¶NÜ+b®MŒÇØB§d¼kÃmô3&X^Àmà©ûÈÜö0êà~üˆ=lİ8™1³H)Øš-%Må¿üw“ æ±3İ?«9Ï U$f'`MöÅÓŠÛƒ·…jˆ4\Ú7à>3MYûp¬¶Û"akrRjÉŸö•oá2¼k]µÎÅHtÖI}EÅzé‚È±šËæ+4!ò]ÂÏJ)ñ¿)•7¼CàFÆä;ç!ÔÅ×w›f¾Ñwz;<{»‹êú¾ôó%‹†Ú8ù`ĞD2\ÌC*!¤¥B¼I™m^s'`ªœ¿£@ÊB$·®ºcÂL‚ŠwÒÍT_…Æoü/ó(é»S/E9ÌÕTThcÆwÔUL,8Gûmaƒ¨—|BWv4sàût0¼OwŞàC”C0‚tDBk‚ÄÁ-µ×­¡º¼Ÿ’yğì„¿ùİ[9ew»Xx±G¤¨àBO3<€š,k_5ØªF›Òµµ9°¢B‹BO'›Oo#]á«×sDà4ùpòp““¹©äˆ«ˆ*5jfz“Fm]Ş1Øëb-üĞKçs½)§*:&ç8dâ'ö~ŠuÍÎmz³Ûãİ•F' Ø@³j€òGF–¤>Àşlt•~œxøë”’©RbÑÍ½²Ô;ÕHÄ$¨Z|ü.ëuV[b§şñÜÓ_3ÎÄfgê>èÆ?÷Ş5uzDV¬0Ò¢ó'şá|{Ò¸Txäº‹æ×,>à«×—%zĞš¾k:¤eG7>iR"ºü½v¥rdÅ5=«Ix¬øıäÇVÈPF`$°„=’@
¥@IşƒÜŠÚP!	¼€ı=¶£° éªV¢í`ÍÅŒfRÉÒÎ¢Ö·ëøµ!TßÇšWk¼Ú;É%|$Ğ”jÅ%!òH¦^9ÌïìÜÕˆ¦¸…~¨®œ–òSıhDŸ•o+YØæU{RRâŞäÉå/Ì6¦‰@ïû9¢á†C—I))ŸèA¿ˆÓì“QMØe›úHL>UØ¾…š=X šçÂ“Å+’O::Ú¹Ç¨¡uÌpòâ°%­?ÃàæˆÕ%Æ[ğ§ŞW¦Ú×Ó÷î%òrl÷ê-DÔùY ®•„À3M 3kî$@[œÜGÈë¦`º ÏÛŞÉd0ï¿%Ÿ¦5Eg£ŒÅJ@…„¶çL~ {¢	 ]Šü:#”4ÛÖc½Ä,œÜÓeRa¬>=>YlÓTû&eük	
ÂC€n|óUHú‘^ÉMæäuM£EİÕ™®ÖÇv¶m—Ã˜©ût*ÙU±e¤–•V.¼[hsÄÚeU[æpWÒ0–›Ò“ æßl­p—¡‹ßy>Æ¬ìW}–@„„!`ù\v¢oóÍ £õŒn¥1–«K-}Y…ø\"xØ¡]
”&^€Ğqñ(åp™a.°ªMámŸöÇy›åa4â­ì(Î”íõ¤™xµ—M\n;{(;—QÉ7¾
©:ñÖŠ»Y¹³lt-ƒe’n?¸©Càá:Ì_÷736»(SAL$.·UÚQw´[Mïãù°odş˜ÀOSa~ÿ&U”f-ÒŞ+À€zƒV¿MnÅuëO5ŒÃâºÜüùiZå3À)wÚÅ/ÛZÇµ‰O,JÈä·>J£ê¤¾x¾Ş[+é²jJØ§$ûİÕÈn·äëaÖ‘eÓu‰@›İ±Ô03‹<{­`U©9ŸÚY©-šwR(ğ‹¦õµ@mH]¥ÌUåìOL,†±Á?™®&_-5›
–ô¼(¨ËHŸ]pÂ4ªiü8«j$ñ…íMtÂôğËÔÇ÷ãĞYs—ê7€Áº¦8ÑòğœÚD6Éùıî,ª
­sH+»µªàúuiö3Òèñk‹c!wµÆş¦u‹÷LÅô˜†…¦KóÒG#ƒ›D¸£J½ô†{0|íÃÊŠVfÒ¶ÃDÍõ|W‚Ì¹Õ—¡Ôøø# úèT*+s®å}Q“©mAâ¤sç¿a#Z Sæ˜­QRÜd	šrßr~8Ú[„+€u)!”
­"^¡)ıê,´rÕêßŠåºã³·ü‡œı?w©"âc(O:Aóñõÿ,`pyñæµ…Yu¤ã¾Ãà\{,ñ	Ksi+éŞƒ@¸ætNÅ¼^m.ö·ÿÛF#–Ü_/ï%âïÅFÁ£‘Uv?¢Øq¶”È€ó©¹UôuÅ9…óÏSVÏÙ¤"WĞDÅÇoıóƒ2ñ®|\¤¬¼xL¤ÄØfø²’]òÖÚCí|´º¼$t‹0‚GÏ‡PPNmRr\jeç¹²"ÇÁŠG3v™/”€Áá .ÙÊ°_£F7º)‹s*Nâ ÁÍ†E­ğC(Îª¢à,`rT)Zó/ñ+^ĞÕ+Bÿï~"¾™ñª<İòİM2°‚üd+]'d‘In
 ‡8Vw®Ró¹â¬÷€ªõ%l‹´Dß_DXø/)È`¿ûŠü8ô4A(gê ‘G£ËÜ!fS'/ùV»g‡ŠÄ*] 0¸6„‰YÄp_T´ù­¦ ê±b=MášòÎ›ftXTK%û6 &Wé®ä?öğ«¢z±QZÅffÑº’¿A"¦Xn.G­É/±üBã›ğùzïUô‰Óœñ;§Yw+H ”·p’<i9†úàw ¥zÒ8ó^4ã—1z‘¸7 \İŒŞ Æ-Á_m99	ãÀpºiy<rÕMùËÊMîÇ™†P½\•&ÓÊf¯8øPR³<œ}ÛŒ©í» İ…ûdl.Fë“¨LŒIê’µ£ósxÛgÿÇ»wîyNô|f¶œ]  ùm!?”úÑ§¯Ys>>%@®­´æÄ:Iº‚[Ã\mææ]¥+s¾Xğ›ĞÖyÉK–ëAè$ß¾}²ÀÚµ-é*Ãå_Ècx ÙyËå2U“sÇ¬©Ğ	ÙewsáöI¸¼¯ô*òÛB"–xı+Ç²©ı/Î€§%Â1)Ceø™/g.ğ™*iÉærCaòA _ñ¶UE¼BÏÂ€B'Ú<³:ì0"6^]˜pE,è2ã@´EŒş7ìª*2å…dJ¦BŞà¶¹VÄ<²:—·ñEÃ™eÇğ§Õš:şïà¯~P0Ò;#Chµç§SAœ^Ü.œÁ:«Q"d"ÙÇˆ¶]dµ«,t×‘*<¸u|ÍÅ?!üÈğ$¶³h´İí-t“ÿe¼„!AsA­¡²ÒİKNÑ;`…ëÉÍšdv
+|Íq*‘ÖƒFsVÆ!‘ã]Ù_/ºex»¹I(eUÙiºÅ|ğx*ÉÜ<TMáw,G²ïºŞÖWú7ŸÚ%¥ªÀ0 ì£HµÏ¨y
¬Í¶ÌYEõ]ÇÄÈ:œŠIÓY,ïÙöi<%şS—oÁæ‰é!€QæŸÒİÅn­³¢ìeJaîng?ô¦§ˆÍgM­® §½Ê=ı17@{—'<ºüßd§zµMhËjHk¹„«¨w®†ó%îzïpUÎW‚¯á¦¦—Ÿ‚ˆxF€œ`5“ê=Á8ÚWJ ºÉÔyXÀ¶=4{C<n,‘·Zx>’ï5¹Sƒ¥ü İ63‚6^”Úğ4¥EÃ˜NŞšÀ1÷l$½Í‘î†!¼?ÎD‡ÊÆ·ÏR¼ºí’¿0ìôÜ' aŸì¶ò«Â¤ÃËj½}„T¥30Jâ¨ÊÉ ™£<µn
PzJõÃŞª=ú	Û{UZ3ïIE­¡¢Osæ¶ËÕ9ãĞ=.­/¿àR‡.|FVcÃ#¼xæŸ<×¦«Ø4áôüƒ„FE±Âtõİ4¯\.”	ÔçˆHJ<"¡·P%"ª¯UµDÅò$©¿úèøF’s|TÂ'ræÂêÈ_;g·^Ÿı1hæ…"æ²C‘€ñ“Èë*Ì6I_Aø•N@…!UÇé;Äîíì™ŞÆ¨yFâúD‰ôòZx'+ĞX«®z…¯Mü3û•BñWÀcŞµ5ôyİÀğie‘w9Èø\”ÁXÃHoUCŞÄğW)Ùó'åuY}Âˆ#¬lRm;û—<
Z¯D±
Şw‘º25ŒwyÓ\¤"¬ÛjĞ…TGø)%YY;ğDà‘|OÔF-Ú„áğÙwÂbÍØì)öÓm’óvÎNxÀz  y|-ÍNEééxPOêöÅŒTrcôñG¾ˆêâë‹õêĞ°º#eÚƒTÏÂAĞ> îÃÒ½"wÇ`1;Íİ@èÍŞlÔ(jÒ~çá”=KuLXÿhug‡‘£hmÙï–éù-óÄŞ˜¯KåsEkh-÷Ã:ı(ï´©§!×DWÍ„OõFtN•Ñ§ìßÊØ
„4
üïìsßÅ)A[½}Ê…pÑ¸åÆF±´ïˆ_`ÏÌD_I¢İ„·\Á»‚ŸüÃbJ]Y§úÕâVƒæÑ¬d„z Fş&¡(–ğº­$ta¬º™Ğ‚éY]B õÎ`xZ÷4B<ÛÀ’û‘Úbé¾Ì>¤$¢rBUO¢ª”pEŒJV»ù^ –ÌµöóäôQ3Èßµì,^bQ+ˆŠÁMpeï«¬G¥·8$ì­¹2eh«Öv7æÖ§l³ßpÏÁüˆ1}£fq=ÕÈ
ı¥}R*ĞOùwğĞŞ#Öo¿>6;DõªNYç•'”¤Ú‡ZwHööbßO|>Ê¼ÀZt ~åù“ë&ÅĞ†Ğ5n[áÊeOÔ6t€“a²Hæ•¥)œçiğ”É¦®xmÂ)|™NšT²hñºweh4õĞwÃœ}{ÓMP=¹¾p ñ#	M“¸;µ»Óm[ùNÉŞÓ²iÃ¹:Œ?¥rüU¼÷2w×ù…­i°EÍO…?øƒì¬;•õAó<epK÷¨Áˆ>ø},È›èª=8ß¤WXÈÒ‘ÔcòÛk3»¦œ3ºœÙ*ú„D?r‘”º‰y‚:‚&±¿¥>l÷Ş;éh·­ãÊb!/ÜNÆG¡ñÜA/H_lÛOZ¯B3³Ô)ôb­øz¾K—¼ÃalÛO•<zA§IÈü²sŞs8Q‡9ãJÇ}³y»ä‘O­Üàcürk«0æyMÔAç³ É‚ª,û“×Ì¯‡ÉÌ3¹“è8ûÌ´İ\hdÖÂ2Æù…W‡ˆ»Ø’¹ÑÇ.ÿ3¬ŞµÖMÀÂ÷ óZ8{–òó>ìæíÔ"øª
'ŠŸ‹)[ë	ÛÎ_&¨ b’¹•ÇÊD€J!úŒe2œîœ7R_µƒ¢  h–™DT:>ëp¯ßJ—XzSo­˜n,mµ p†(ËU%&½`1Òµ p`áÀ¨™Oc—òP’_‘%Ÿ±œØv¬œJ€¿‹áëP¦:)şæ0s>ØÛ},Q)¿[Â“«´•/^ÛfíÏØNòùÎUsºèuU±9ÿ**q‘¬ú½½iÀ$ß®ÈV«ìó×B’iºzÆw#e—¸õ|Ä¤s Ğß‰ø¸á%¶¢™it6WQÑ!›èÍE çäjİ¯3["»xş²÷-Iów(kô÷tƒÅÕ^–Báã³¥øšÕŠ–Â3}¥)(×UCÑaÔ$*ı~òBxªN…ª¼C¼2VÉ‰ETŞz¸l›ıÑ/fëŞbEºüé&‡r¯ì±ğ­„ıöµËJFãæàŞ¾rşÊ.w?·_¡|˜÷NNÂEó3‰æ—(º~r,Îñqæµ€\²†ltÏ=ĞæÈi0 ´¤2ë»û™YÉ{Šq(Z¨Ç(õà6o{,ô;:Š¥!+á!ÛMãªõ.hü˜.oaMCœÚ™Ñ˜%VQsÙ}ezDf¬E?G×¾›5‰Õİ<Us!2ë^hŠzVï°Œ—Œy"Jµ’:=6¢ •a^F›ğŒP¥«&Eüƒs£²#Û/~6`b£˜
ob-®†Ö‰wÀâ ºoYÌâ+øÆO(l…äÖûèk~} X¦c®/fñÜŸ"øÅwn&|±%¾¯]ãD_{!FOÆşÂ‘…:öÑ)]Wˆ‰Ì¶¢`¯(ı¡-;~^ëFŒ”_ H;äàÖ‹€Aüo!‡S
ÏKé,«)ä›·^­ŞsÎ¤HÀ1F‰¼tíO#‚Hl·)ÅreÉá-ÔO^‰ùGíÌÎ+A–õ˜ªBT)ú”]~)ZÁ[Ü.È§YŒæœ{àœİ¢)³–²'d}çÓÔ~|é	ØEeÓ›ëL¢\ùÓ2}Ö(ãzª^U}Õ2â{¦›¯ˆGÿ½Ó#î7H7µÇ¿ø‚ÎYù;q‰³qfW(!rş{ş ğİhÒlÙÜúİÒ•½}Í"{<ÜôMVÙ`,Œ\“C¡…È#ÃUQ;˜Ñ2h¡#à3?üNB
ÛeÄ­M`Î	P °^Õ‘òäÖaæ8'/%OšıÙËjí­8Åh†›÷)´1¦!}tü¡”ÿsÜ…»î™3Fl¤ŒLğ%lØ$¢(:\S_SqÑºµ:J¿r¯uGŸÑÔ¯g³M‡Ú^Al\~AIò	z=›PÃ©€Ñ­E¶“ñ±UçlmªğHàH›?=6áÇÔtLr+Eÿœ§äŠ~Ÿf§ià7¸Û2ëİ…¢=øÏè=‰™÷8@ì=ÛÅz9';@ñ‡Vğ£S¨Ò ñî4µÕ¢TFÍÿšŒu “„é_Æ÷»Q5É	¿ÒÍDCiö!siŠ¹ËJË*×Ö™†ådôkecl+:y0¦¡â÷¢r|Jª')!ä-Uë6:En)Ç¹ş²ƒ/¤¼©‰WyK°‡U!±Ôfá’Ânë>ºV­;é$^¯‚Á\¡¾„ÑóğÄ"ª‹,fïİÇ• ®„rêÉ½šDíªa”÷şI‘u«d!*?É¢¢f4x/í»Ï‘ï­ôÅˆp#ã”ÒŞÕ-h×W,Î	§6ÆƒîÄzHÛ¢¨iôÄ×¥`™qÙ„Í€-“¸\wº=¤+$‘“3§@È.•Ë¬mñÖUZÑ›»Oa®½{"°ı—%­ô›¨®c{#E«j›µŸ(‡­Ëa‰r©rvi¶™ß×muå±y, D¹êv-­l•¬6Ï†Q(Î«sğ•Ò€ü‘{õq[µæ­æ–añÈ™®rI<ñÂ	£7«Z°<Îç’¡ôÛIbÕ¯M=z°‹m/‘˜ÍÕúÎ•YF¾¶Tiµî•«*vFx¥j¸hü»½A£®\šİô™f|¶£ÁD¸‚l9d}áGĞcòÊoÀšî›ÍvĞ‚~o‡ÔrŸïñEª©dF"ki…´<Øgª”?H{=‰ß°0áŞTM» IjA9•Şoºjj¶µ9ÈïÇŸû“}ø$5a0g!U
*XU‡·ÌãtTˆU¦ºÙ-­QİìŒ!©Š¡“77·t(EïÏOR´¢’üV¼­l¸Óµx¼­’Àx	ó¡d×]éç˜´}t·™b OCÔ",<ß¢‰p!µ°w²ÍC
…Còüˆ
9šC.nJî·f@Ë¦>/X•ÆBÉ¥Ñ«5¾ÎfÌ¸¬¦*-¬g–øÖ$«ğƒÙ~[ü÷xÕŸ¤ræ‹†#¢SàÔŒÔEb±:ÕÍ8µ8ÿì¨â8Cíº«ÿ¨„Ñ+yGŒ¤T#>²'†&ã¥2­G2/Ô¿NÅè_²Ÿ
ä.¶ã	S ?ÈûÏ}h§ĞÆI…šeójpÒkcX¼(CjzòÊ	¾ß£úb^µ‚Şfb_E×ÙNlÿôpµß‘–ái»ÍOÄ‡Imî$òÉZ¼vşƒoÖ‡[ª›ğ är|÷He¸;`I˜L ×_:{fÜÁ–ßtË«¥äAÉÜb†QĞDD¢Êâ'¡
5¿öÜPf_¿Ï“öˆ×Ã¶T-"—SMCg¦P®Á ‹LzúA˜Í°—‰{Iú¼%Ö¶¤{—Z4¨ãçòµ
Ç§‘!½Å!ŠR«NBE‰ß`|»„ûİçÌø\¡O_ñÇ)€!Ï
!p>¾âBğj¿Ñ#x·JıÃ$ÈzŞƒ'B£Ä6ıUI'°‘èãœ¾pœ–D€ÄP ›_ì IÛ€®ÓÉµn#ƒ“p4kÅ¾¢®^×È>áŒTëÖşOí?à½HL¡#\»pé¡"·(ptÖãß!"qÂg…=ÃUu€b„¹UE
BªF†8ŞñEihLj`ÜŸ1*eï$Ø‹F¢Ñ\®èuE¨kÍÓ-ÿªàÌ‘ÿd1Ä¹ëÇF×.£èæŒõ1vz]
ÉEƒíw³ÕİúáX™!x\\xØ‘º-áºÈcÕç4°~ Ï3¬B”Ã•}q˜NØlÏ‡·9¥?A~;Y¯»«²¾³c±=úr.Oãf5Zá·;D–HT­m…æÙÄïO'Í]ĞïósšªÌdsÀ¾+Z>äµdÜ
‚¦É”Êé@¶SV‹åÖàpô»Y£ï9˜¡«Zu(;¾kI,kY§š$f)ó‡›xliWOŞ9*¹™UÂr=Ş,:á -“â|Â,´†+_å³QC™kÑçßXes·Aîim®(D¸+lÚ:ÖÂÖ¥%RôDÂ;©ã‹a›
ó’â
2Í¿(‡³gÿªY›DË0FØv.û—ëÿ†M8QM•äòzrWW¯hİãv$ÏÿÆ\5³	DŸ×[èv	SKÛŸ“B÷@OólmGùå`Ó{âêígH;?)·îÎxÔ–ÁP plÊP©û69ÃÛóÒ0Ê]şåªjRDê%{sö³ÃK½l/½ŸT{7¼:Ö½ša½S’ØìWé†'Ì>[BâÄ¡n°…«ÍNŞ5àIªNÛ«%,hÑÚËq3‚Uxmş“»–e
´"ìu»‚¿¼·» c»å"-/Vâ´Om³ç[àı1p™şñ°›Gë¢†Ä0‡Ixi@$Xø„BK¥=+cÉx)Ë†*ø›> ]OeóºõŒİçp=vzú’?Oò’Ä§xğdŞOTÔØïf‡1lH¾p“Òsv8Dò3¹JÿIYÏÑmÚ¾µUğş)ÓÛí÷\!NDÌg§HgÀ Hç1: ¤˜9ÓÄsìCÿ8h÷»3à^så}Lİ`fu’*§°²NxeÊTkğÍ“€tRà(Ö÷)ûpŠ7;1e`¬EÖ­[ÆÀc”W<×t?ËßÆ›˜¢WZ¸?ùƒ™Â”ŸWÙ%:¾´)t¨£j.P±çı(Éƒ|¢X™©s­ÖŒ3ö.iogÀmšdÃîm<íôà¶5øç{»'â"P¼Å°rxçWJb-~nê#go*ĞĞz»¿İ lKp&‚’4U“ÆÑ•;TÔ¥wr¿åÁó"$½±+k†4Íqæ9ÒõÖ‚[ø*#šÌŸëEWödˆ~DCÈÌWg3]{É‘ú 	-›~H‡æYsµe×8ª,éìBÅN.ÌÈuS/Û‡õ\“UÆ|b¹ ©bT÷ZÌ(1u½Qc Ü¼Õ÷à'gš/„±ÍÜE\2—.•°œC±tRL'ow;(ş£Fkğàš\+Å-m…"ï\ìÄÂfŞ›C<ÉOÓ65XÊ3Qû‚¾éµmãOş0s%9tZ#¹µ´Ô²ıßĞÕÃgˆ½RÁ¦0{CúNxò
T,F&LZ€Bu&:Ğ»ºÙÜ«1ãù–W…·h¹ÿh–xÇÌ“®g‰‹FåÓuzš•U9rxÔÉ@Ïg[¤/¢ÔËô‚›‹aK²ss›A$ğÆÓb£P{ê“¶w¨.ãÄ½)'¸y¿w…T…	jfKĞa9ÏÛé®¸VS·ø|Ãçy‹Ø3`®bÁ±-š­-ÕC‚ÊÄœ‰˜ TÏ;ú\†<ğµé½F¿i›ÿPmÛæß…)|/ë*3M©#ŒfK¦œåC‚Åá–âk©T0ĞuGÍéFÈ2/{ƒ–^îà¬Õ]ÄZ€If?Il®}c2A{m|Vnï‰¹À†§sŸL'bdšíGvĞÅ|d£[ÈWpÒÉ˜/ÔÖ­±°@Œ£ÖÂ}¢€»1}a\ˆ„ãLœÿs[@ƒÉŞı«¡+}Ç^J8»e„š_-Qˆ7ÿˆÄa9ï.İÀËêZœ*ÙB0ÆÂí@PÀ-7œÇño$vêOÃa¾N±¾o?3®¤{8`lLÜ¾«1º`¶Ba´ŸM„®Å¯_‘LòÈ’´LíÁüÊ8B(ëéÔ…›½bÛ$êaªTû¥)÷]¿gpà½`ä8"×ôRŞV=[è‚'rÔ†´)¾&³òÊ¯7>Òš½}cøå‰±®pºB4Ôõ3O'4Cå±
†ùæiŠ`©˜8XG¶ˆW§®åio
úd©Ä\–&ë-$ù©?/@äz-\ä%ñ(bX«¯­¨a	ğ1/6Éî>¼<úş h­)©3/şŞı+‹Ğ¨Cº2&’4·“7Äñ§Z«ßÙbO6¤
=—f|ÖrhŸÛOhŞå÷yÙÕÀªVš=f“¡…jÖ®(vU•g&Æ Äõ2ÃÛÄW7àm•±Äüx¿a­±d½‘kËÂ,ZU±Ùga<óå§jÌ—iq¿ÏÌ]%0PÖù}˜evtp€ÓÚ¶Pº·ÕDO¸j¥C³
ßy«šË›V‹T¾“İ õ˜^
;~‹ë¶…¤„·qÚg—²ÿ€
Ãdå^÷BWşùöJ¹bÒ{íVT¯•‡de–(É+)‹æ[wËÆÕ1Ãuì~©æ+ê¹„w¤ÃÖí†“?ÙqdFKÊË}Ìï‡ıôº„aı_µQ_	ëı* ”1³‹œÆ$™Ÿhù­õÁCD´Cs;^oàé
½:ĞŸ™:ö(q/ğ‰7’Ö¤¡“J#º å:íU@;6×ÿş!	ş [7v–ˆ©îK×ÔD½Tt>
n¦Ö#o¡´UX-_İã(`–&fLÌgòctÈ‹û cíuäø“Á6Ë¦Í²AÅMl|¼x™À¿k»µ×	Khgö¾ìn	OÛë¶˜Û~[¼@h©è˜\Õ¶ìÜp]Pò(¯uŒxÜæR©V9—Æ?Ø8)¾­ÄaN£¢uOÉ½‹@Ú*ˆr­êC§Òƒ¬½Iôn)Qè[P“®‘Ë¶zYã„v|GHxİz.Dô½'ÛD®lV«÷v€Fˆƒf.‰VCZîÓ|ŸÑê¡rVê´ÁW±šù-İè>ÔÊ~MˆuCáÔ»ö,Ş¹Ë©@h,’ü–9áUÑ,úW|EÄkí§røËKA¾Ÿg`.&œNªQÑÎ8.KWºqï°
0&8˜Âg–$’2«h7µ;µ)®f—_°Ôîéßö_»½ú»ŠÿVzzl˜×åmôI·!´l%ŠJĞŞËY1¼6ÑÂFÜ-M(œÕRñ~´’¼m*vûSi…·|öq \¹½‚Qr¦ğª<ŒWBm…ÔšË~ZEg¨ë*î¾'×6Q§X™’îÓÚÎê¤VwçŒ¤§Ûº+µD´O½õİ†iöå,ãòékãÍÉ¢ˆ0˜¾Rò|ü³ <‚¶,iO\}—5ÃrwiczÙÕHO—à2ãT<1øŸ®?¾féŠ¶¬$'IbÄOsEúDÇ:ò›OHY?­¢8Ù£Şç™‘Óèòääÿw Ğgß#ççİñ‘î@Ñ©ˆCwN…bj°\FI™@k¤Â¨—mŸµÑï:¿ÿÆÖè´@²h  ‡Ğs	úÅîoM6}µ©TG¹,äxöD—éÕ¤°òÎ?4¨ÿ˜”m'ã#§ö(OBb-
)Œb«`#¬3:”=Ë|İzPnFğœ‡RØÛ=8„† ´ˆjÅ[‰«šõ7>cg$éæt-V²ÑLıŠ=6»dïãîí“í9Uh‹
¨’E@ôô™–IJ‡°#ûÕóeM&2Uı
BYâ+Ée4Š×ÙÑH}².ú·›IÖÄÁÉWçE’—=•5Òî¥ğ f>ŠéNÚ¥”®—ıë·u’_Óü¶¯»à·##CjµŠ¶Ûâ&‰ØĞ©5èŒM5xI²G(gó_3X¡|‰?Ô3…AÒ‘ûø,çÆ¯º…ÆãYÛïJœû¶;|€–å"Qté0½ï:Ašğ—Fô›ïs-Ô Û¸´.Ñiı¾ÿœğağ`.È‹­zoTq2:ø
åQtŸË:WÔ ¦‡c°,‡Á•·û¤Fß¸
Élz 9A(‹=+M{¯Q=ÿdNSí&«<9æ™P"w%[ënı»U{P}¤ÍzœYq°£=îPİ¦´öÌ?ÿğ!EI°³ºğœ—×bøØ:ys¼·ìòòä…ÇpEÄUÙy‰c‹¿Mrü¨!- Ùø¯ùÁÅK›hó=Ë-üN©ã¸ÍäŠì›E^¢\»\/ßé7ü¡“^yõ÷@Êr›ˆ1–{Ÿ9`v]ûçGTuµğB2ßÿ€fı¶MÏ1Ü¹Ñ+Ñl«tˆc1‰BL†\~ÅÚ¦s¾ê…Ş$¨“(+'¡ª&½‘» üûè¿îÆ)C4a`ş¹5‹Å©I¡¹ºÒAÅ%‡teh¿WÛæÈ Îtkhİ2äâ›PêıêmCgûª¥”J}Æ&.dIV½*˜^KDf+İ±5âC	¯ò¿¿şò
›MÎŠ¼'(”ÙßîFI¤ø¡Æß$4GBW·Ç­h:x{ì&´%§ï’_Úv?GZgÎÈ	¨EC Œõ™:´°çA‹ûÄê€R&µ —'$ "\µ™W.3b2»Fì}°‡~“ÃÂ|8Vìvˆ@9kd 5=ZœóZÌÕw]×š: ˜"g;³/ä„<’ò!»XT)5Æg’ßy©´ğÓÜ/Òíõ…N£Ø)%ät\˜EBÌ‰¾Üç_8ÇÜ	”ù‡ÄÅ|wˆï'Z}(Î‰µßGö|{JÙ"q®‚8&k
"ÔüŒ‹;€ím©—â]ºa
¶Ääø8(@@öfŒV÷``ßQ¨ƒĞZêª™;6¡©8„åêºF4íXØê:Rù¨Öò—™ã‚¸>/ÀÑ nÉ
¢o!¤syvlÖ¬’K™ÇÁsÙ|ãü•Æ6ìròCF+¥[­pñ‹.¢¹p˜µ¡–‡h:ÌbÓ^×nKgÎºË88P|_„ÈE„"xTh_z æºÙÉÇV IÔí­Ğ¦gğ—¢Òñ|yÑOÊ[Ğ!)ÃC®äR=„¨ëù*ãõÿ5§{õDeKv†šÖË»}Ğ\ÑøĞbö©ü9ÿ~z·ÇÜú³ÉS¼óùcUöc”ß«ûYÖt”¼¬QâĞ['ÃØĞ†¿ù#**	]­Ué0Ìp¡7(ÆŞñ	§Éµæ‚Hn-+£˜šG7%„Ÿ9YÀw %ufC½w2«$ãez @±ˆÌ·Bâdd íKñ9Í>îHÜİLoÓr|—-Œ^ÍÕÔ¶{„oÓ[f7ÍÆÇ½¯İ9=}˜Å,f;¬³Ñ'ÉÂœh>ó<%S®KPTgı>8™E´ 6Q§?š‰Vr»ëğŸróëAji*™AÛ­Ùçú­ºVùXÇ·"Ãœ¨µ¤JV\ô-P&ôèµ·ëÛë¼Àø÷~i~5 +3^-¿ÍP1ÉQ5«^Ÿ¼“Àâúº?w;ğ­°Û©u–§¬q¦å–™äŞ¯ ¥çáŠÉgÛPÙÁxÅ¬“ªÿíM-øŞ‹ÇV‡X}/”~ú[Ö½«™pûY×´&ˆŒMà3³êrPˆyÄND$[½0ŞˆüE¤ŠÕÖWÄ=Õú°|òş•ä…Èúú´ĞnÖAâ`ÖYFe¯Š®sZäÅ˜šÎÏŸqïÜ-5g^Í.ÆBÖKe]-®	2Ç‡#	ññ¸ó¿û½uœûa’Ÿo£ûOÆv|-Å…Ënğ‹ #ß’z‚Ûl}iµÁ,2I àÿ})k[Æ{{0•˜£*7/s»êØaêĞÉõİ.²\¥ ¿Ô@¤»Ñb¾Ô]›¡V6ï…Ğïtbù¢>bÎY¸ßKôÑmP99 N¹Ê«À½béÒ¨«Çæ•§†®no=ÂËx7˜€”Âƒ Í]ë_ÄøwÊe€´8^õt8«$)nO ódÃ8É¨í¥¼­øWA¿…@—%'~ôş¨.àTdÀèdQŒ|¤g†*S÷tÀê4€(¯Õ+‰Ë(ˆ/¬Ãiõ|Óõƒÿ‰³µ´á‰·%û†Ã¾¡H™}j˜¢Z?Í…r4ÉaöÅs¡'ÖæşB„VbßÉØŸ‰mˆ¢V´¬„\"ûRJ éĞ„›ó\ŸÒS#‰Mm2Îç§ü}>t„\LÑªa„kSí¦ëøGHdRj{Î#ch 67ØuI&)ÂwX”Êí-}a¦œ¸CÃ­}®*ßK›ßŠÅA¶v]”ˆıÆ.¾ı·îÌ”ÈE¼Ïj˜l~ö’&§÷$•ØKœŞC(ç›h†}ê7óÑ1¼HìáƒM!@$[æQ?ª)ÊùÖíS¦ªQÔ™Blò›/Æ-Ä°ü[‰f"³…^íµnäköRo§àx¡Éz(8(¸“²¼sx2Ôm;^:‰¼qÃš-„×fX½'H êå9ì9»ähì'õ`›0ä@XôíÏ%Õğ\à–÷ƒYf¾qâÃêÒÇÇÃpÃ9±´ÈAA.xµãÌì¡wEl#ìÏÃaÖ[ ™>>û¤EùĞï±U¶ºbnsbJß«ĞÕÇpÖÇ¹6Á©ös©1%óÂšÕ Å*ëé¢zÃÜŒ†Wğ²4YœºÜ*`zT–òåA+M›{ñcx‹ yP€R7ÒQâl4aÕ¿Ÿ±:ûö£.‰á©?¯Á—ÇÖH`Ë{FĞÌ‰ûc×ø€™ÉÊ³·šë1+Ú*1ÒDŸ•í t³Ã"~úRÿğÀº†ÀaôõM£cJ•°#È¾Şn;¢µø-çÑVÂŠµü¼|‹l±8ò8WNr•õ01Ğ†Á’?ˆËC…NèØWäÌò,ÑĞ~—¾Àëu ÁšÜ²“v"ƒë÷·äé¸* Q‚VÿÊ™ñ¢ÓïëšH¤bÕ!c¾û©ÂbA@§K´x7_åÔD8èÓÓW˜:vah+ÉûúÑ²ıùÿm¯Ş|m¼4ÊjÄ»dÉ»­•QwşOìÖÍ‰d]Ìî~Rí~ğ{Ğq¬+ı[^¾uwh`çÿšAŸ€#ÑÏ{ÿ<ºÎÇ¢©µËçü±ìs¹Î:L³£Ò8ÿšJÄšM‡Ïı¨
‰´±:éH[ğê(–r3N0G9‰ËQ7Û#3yiRÑD•Ÿ¾ §À\á¡3]PhQœ—Bç%ŸNÛfÇâäO¦‘ĞGŒ%Z*4VÓq[±ßÜZB€"B}Qî"‹±û%U‰q‹á±ßİ‘–fÿÆ¤×ØÛÉeo«"g–;4¹$¯@-‹w˜~QIşh_¢›7…sªó^éi» 8DÔ·1&/tÛ±¼PĞ:¥İº{<E1÷]†Ï‘_äVÀüäù¶u ÈxH>8ğ Éı¾p)cù+c`‘øGeK8ÛÎI+W«"¡¸¢lÛ¶¼Ù =¼h‹.3¬Šqh=>	Äë/m!›öˆ±–;s’bí!ßË#¯ñ²ôÜ/ó7‚@'àNV½ê¦¸b±ºÄêa“Ÿg÷'}­ı†^«n°¤“{›P!¸´NÜ6¯“š)Ø-©KÓô›¹,¯nrÓãu¿¯ÂC¦ŞåÖ<½9ª"ûü,X9Ë%FDNgo,¥¦ÜÚµ1¼âÀB±–F+Ykí¥NI–İ[\ßìƒã2ˆ´îƒ õ—¼İ÷¿XÎàÇâ·ö¦æÒSœÈõEçCA_	¸ÙK8hÑnÿH[R£ŠË‡¤°÷Â¼T—Ê	SJÍ#r¤¢°æ»‘/a9ÿ±È¼©o­»e@à»‚SSÑ5Ó¼Ïœ	%şğúã+DH…Œ‚ ’óDÊT#„xj|í«O{ş˜µl^EÙªªâ·”7]şƒÓÒ•Fâ<Ò¹é~‘ÔSmW<ı±Aª¬Ô;V{7ï­wj8g•uÕŒî¾än^`C¼œ@“ãc‚F,–´(³;§8G¥”EšèÒ¤-¤>3	$Y;¦‹AuX¥H‰w )–Ö™ıò´¢•,÷8"6ÎÈS‹v`cA‡ÎÓ!Î2kmö‚ à©"èÖ/{tÂ©h×NÊ?Â[—Ça»—f¦şa²
q0	°á¼ĞRáÊ@1–sßìt¹şÀñãƒ§gByôÌ§š—$šƒïJş‘ód%ß,+VÖLvË? W9Gcñ{Hz°3.kPş5JÚàp61ÕeœA¨é
j—Çf›‹:: ÆÊ	yE!ÿâÆº1·¦%JÈ–èÖ¢q)“†}gH[º$K×ñTÉ¬ÇS´p~¦!så?7:byà¦^	[6É×W–”ŞÆ}WRr~Æ]onv+Áò¢îş˜=Á:º:¦±iÑ÷&1Ü“@•í†ÑÃqû¿¹RPOó6(‡j.ƒB‰H¼üszáÿjÑ`µQ¸ë¦7‚<ŒkeÔ½ß^€‡ÒwÚ[ıŠ¸»>mixÆL´›è#Ó-–†n¼YÊÈÈÛ.åì óüµÃ¡!X;ú§×¶&^±jft/îÙ2~ŸWş&Zv™ÓÛI2à%åÿeB‹-ÖCÀ­Â6³™Ššá±vë²£(Ø>Ñ&<nıI:§öh½iƒĞúíF2!ø˜óï5ş©4„}‘lĞB2f[w	610ÑlÉÍ±ÕDcMqŠH@ñL½e´U’5£"|p*ğ8c©4|o½õB°.İîşk±õ={>¶3ÙJƒıM¡"·bfn0B¼+qGæ]™Œ4ó»ypªÈ%¼o¹õ®Š­îgàÜ ïX£u_ÇPÛš9ÆXE”V5Áë´„ßØ ^X-É_	õîöJÄ'9Agä<éİ5hKMÿäùUÜÀph°¹lÏR)0‚ÄZŒ“ùıl¦Ş!úb’ÓTï¯–í;`º†ñy/hëÖæ4GËˆîi1µè2Í¨n¥a?‰ˆ¡–_­ßşCCwEÒË<ºµ'?%»l©şÏUN¤ü?ò)ß"?˜*ñ6Ô»mh!çqâŞ–ìëô+¾j¥Ã½oÑÉ›1C4®‚ÈK6zˆY¡uB¸)DwL<8á• ¥Ğ›—Aìˆ®Ê:-–'Öt.¸bÉğRùŞ†£‰+‹×NÊ$Xæ,@~9`)}8ê/ø‘WÓ†pO	KX#µOÆİÆõ©ˆ ?oÆş²&àÅëUmÍôşriñ¡;)şç.`÷şşE-6hïŸvVÔ.Ú#‚“IO%%¶â¿¾Qw§FãÄõ?ñÊ¡Ás”HĞA½š²ü»¥Gâïê°…‚»‹$lUô®]îŸ!FyÀªà-2mÜ‘"úí7%ˆ5ÿş¡Ğn„zıŒ Ÿöì²e½fş¹bŠ3¶C‹2ûá[µªßñ±}Lr6±Ñ^å­“=<ô^cğ¿ÒŠ÷í£ÿDÌZdÆõõú~GÁ§Ğ¥
íøi;ŸV\  ‹n€¸]šŒCäÌTİ	%©‚¨Æ; 1-U˜‡!’´†ªr<°¯.JA-ß¸œpdÏóFkQXçÙ×íëÂµ•>‹rÉ&nÍäJ,~‡	©tÄ2ß;§ÓÂ¤`ØQ©9‰DÒßÁmÃ±4ŒåòQ§f6o½Ó&6Š“m,lÌIÍåšGi;àGuò™]ŞÅĞÄ>úúÌà™—éÔú)›	¢Ã™£ëÆœrbúe‘IA…t,ìÕÀèGÊ¤mÀMw1v[’,ø&`g™Fò}W‰ÕÖ2BşÒn<ÅÁÌèÂÀÇ­…÷Ÿ7}ñô]¾”>â‹s~dŒ©™öÃ WCÉQöˆh¿ÉÆD ö9x|Ègv~–‡¬¢3u’f¯ÔÙÒ U§Rwş÷u©!kAÆ­¯Ï~œ› ;Ãğ-âcH£-¶ÿ­àÃÿ¾>‚(]…ğWÂ4˜=¨ˆÃÂÊÚ¹âÄtUª5ÑÓ‘sçú=îôÊØ+ÆÕ˜<á¢ÁZ]¦f—h>Jó–âN¶ÏÏ*Ùã£ÅVæsšÌz
á\#î¹Æ#à5cÁÓÙî_Eoa>÷˜µùœŸ34:\
â<ÑNq„œöÒŠş–¾J!–âX¢˜˜:úr£Ÿ=Õß}€û¡hès‡İá­†³šÆJvmˆM£ÿ]ò©ë§Î8¿©™ÕpAûQ†Õ!@¤„Tçz)ÈpÈÜ
÷¯õ&~ş(Ë*”wE˜½ğJ¾Ná½©„»Ï|oÕ„VåC¢¤Ş²M³šÌ’]´ºS$}0ƒ0«V’k1²ÕËÁ¢ıp6=]Fö(6ı‰9½² ª³z±/lË$¥wÙº
—Øâï¹C¬Ô:í¢sg}İdĞàiª|²%`L
zo×&TŞfÙ¢áLÎF(12ËxªÈõ@)†ËÌ{ú'¼ò¬6e“l¶(Îw£éô4Ş8‡pZ&Òé|gg\ã¼·G4ªY¿ O³¨¯ËAìæóóÆuı|LM>øW2W1!%;Kª%)"ñÄ1ĞL§ègS­¸˜‡õ±¢–Q‹Ïİ'Ñ³+šEÿéiÁå®?İú¡bò•)M]V6L9!˜Ò`˜WN›ˆÄõŞ±{kKa)ëŠw®PM4øî»sĞa -Å&à–dùúJÙ¡8s£­Ç¿dóÑptƒú*€°üô6<:éâ‚1±kJ”Æ‰¸’Â'W¥‰ëúAKÊ‹ëƒê	ú?ÿóµ›:®$†®¹N\}ÜM7O¥Ï‡Ù›€-Ü«œÏí©èmÏHñƒxºÃğQew
V6à(HNuêG"'HNµ¤*À0—¬:Áù#“£»{EƒŒ5¹?ç€ÛŒF`=H‘w7Ë’5™e}ã"fg½lô'vT
#‰•½,\+Ğ AööSZ“G™Ñk(s/[©­·“gÌ?wÆÂ¤p[°…¨o´eñ-#óRˆÖ^–¥ºÛ` ¿Ğ1Vœ·<Å­T&[¸|s˜û Ãg À“Pù}D¦èP?/†ÂğÏnŞ6ËHí!E0V|º¡Ôñ£ŠõR,Ÿñ8^>½n‘ÓĞ¢şCöê5yr#\u\§G–ÿS&”±\Ä2¾NÓ¬ÜpPMoõËˆ+X4EY¿¾KgÃ1LsæEªiğÈrdÛº§üw¶¸<Q¡¯•–Òmìæ)4‡écEê˜[*"Ç´,?å”€o9:DcóhŸˆ0†Mà2„Ï¦çBï¦oí”ûÑb‚À71"$åßXhÕ•ÿiŠ*>ŸØ“"Z1°NYØËºãé%ôßÌıŞ1›l`sAã"q>…Šb<¦®ÜŞm cï7†—>õ·xµoK_µN‰=Ï!•¥{bğ:­ğUÅ?v¬ñ„j×9ê’Ø¸ê;tÒªÀNDd#6NPiÏ‰•ÓÿïŒæ½“u:Nqò&²Ôˆº.Åf‰ÚË¬qJh%İ	ùÕyñœFÍÏ®å%AÒÆLI7‚‹Ü>O¤‹Ô‰ù, Ë½t]şšf_«ÚK±Ÿi+Ò÷|%ğ‹iäÀµ¤çtÎ¶ÎâŠf²Ü9é«)Y{èdGÎı™ÕÜZs§À¸â—BUI$iÊ¸ªiı®<²bóQÊ\Ë|>†ü¹–$` gİú·1°Æs¿Ü†DûÌí¸¢ON³u:	©É¤İF§ö‚+Şc*oï>ÜÎÜ&äg¾ÕÆ(2Å–³/u¸‡!şdkR¥™\uÕ+ş{ËóI£û¹’‘ã–Uê¥DUÊêmçKX0Çàêó;%ş¶šè $'šC:îãÜRC€ÈüÕ!?Íğ``&„!SÀfÄĞ`k‡à¼:³°ëuDü,Æî²Ï†ÂIM®Ú‰kS:F1T™+‚šúÿƒg³ã7çæâz¦É`DœŠŸòØÜL:2¼1_ş³)kY‚²]ÔL}ú>…«E$×LQf`k/¹é¿ÁÏî_+uZnü²gõy1(1™0ùW0QäP´‡¨Åº¿üí«aû˜ÑtF!$± {¯¹ÀÜÏÎKÇ"ùÁ½§
ØJm$ÏµK­§B?hÖªzÍö †.w’“Âš1Æ›ª­‘zÿI-!Øly¤tõm¦	Àµ%•¼B©ìçıEP]ˆšø’ÒØ´•hŞ»Ò [ù÷—tˆŞI£òuv%CD‹1=†µSx*(¼İm%@=ËÈ#C­¼*™[­!Iyº2íz²> L9§àxÕŞ‡]ã³]¨£ê!©rÃŒ­îbÚ¤£«Ú™L˜ Kq¶ö%’I:DàDú¡h|»7ş‹ó¡s Áœ-uk7™M.×i1·»G«	œ|M æƒ4DTæàUœÊˆø­ÅqŞøá
5Ä]š8õíZóÑoîlÕ‹31\¨¶Ü4ß‰/D‡IÂğ@İ®¹öN±éÈ·¸b¨£˜œã¤kZGˆSÅÈ”à9rÁ'ˆåmÓWŒ´œïoœ,Óz!ª’¬¹(¼P@”;ÁÚCäÇqºBE‘»àƒí÷
ÉÑù ç-^‘¯ƒ¹`‰Zu£^¹NZÕµŒ‹ƒ—€×^;nÃ±¯rqts•¯¢‰şª<j+«I0èXÍˆ@‡¹å×%ìc!Ã@U®a5º2DÊ_1Öø‹2Hí7™sG.ŠÄ´Zb r…ÍüS°–cp~ÅCötæhÕ~såvñMD†'¹9pã5KìQ5étA¬‚ñrJ”NoıCÜ’÷ÃN¸Ùëí8í.üü`ŒvXÀr§FC-îâ„Ÿ»	™Ã1>ñT·àıUv™fmŸLœ`[Œ>–`5kéf’‡­3Nm“{v½;iS¹¸|R¿Ê˜4·úUÃ¸¢–†™¼¿÷bÑQ²ô»O½b³ôU$ÇÚEáúk‚	r«Ç6´†L1–'Ç.ù&0x°^ _ë¢3êD¦¬ê¥T†øcÈ&¬Ñ¸ÜäL³]R–e+Qñ8EÌãõ´Ôë7©Œ´ÊÏh¬T]xÒÙ>¤/¿^¨ÄíO¦»¦İv®nız"Ñr‹ş#ƒˆƒ{İ{	öwó{›Uâ’ˆÆ²á”­Å\•Éş9«^¶V·p­à}kªr®vDn^³5Çßë¾t“½«
Ñkçğúõu«TğÍTŸKŸîõ`¤ùÇ¶.r;Ò4n6¤TêÇÇ,‰ïââ4„Q’3
{Rt7)£ÍéÎ‚üV„/A»j’Ÿg Z÷£ó<çŞŠÍşÃZ“&cë¦²CoØH¢(”¨Ù/º¸^QÖß-HdSÃ5Q\1%#¥Y»0™º¡SÜœƒØº Jàê™ã‘ QÙáÓumyH¿ö°¦ªU˜<3†!Œ'€/RF )9şnÙåˆ¨'îÕ·—™’"%©P¹=ßƒ5îç°«ëL2‰{¨¤3XÕÓÔ0gW”³E×ğïêü@ôv\ªawÔ*L,ˆÀCø~äzÏœç‚,´â!x“¨.,?ƒ{MsX`×MŞw5l[ÕÃ¡îºƒÙ[¾gÿÁôß¹Á\ WÀÔív1Ñå„+n‡4t0Èf6Lu% l6«³øj=’ûêCZák8| ˜×kQºn¿XÁMÚÙŒfz¢Ë5ì‘¸Phhq&-ïdÿ‰hô}°Ñ3÷Æ?÷zEıû¾V%íşD8àT^îo>$ÆÏe2bQ½_tiêÀß25g  L_"ë'÷Ğ ´¸€Àcø®n±Ägû    YZ