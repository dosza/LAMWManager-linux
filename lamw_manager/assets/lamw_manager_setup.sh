#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2939993549"
MD5="6ba7d055577d75d5057f70c9adf0276b"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="24844"
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
	echo Uncompressed size: 180 KB
	echo Compression: xz
	echo Date of packaging: Mon Nov 15 02:44:58 -03 2021
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
	echo OLDUSIZE=180
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
	MS_Printf "About to extract 180 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 180; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (180 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ`Ì] ¼}•À1Dd]‡Á›PætİFÎU`7Yˆ¢À%ñ™î¾OUq—WAjí¦*5ÙI‘‹İnœ/›}Şu£ß”Ü0ÉÕCmS^Wb%öèé{J@ëŸ6aínN:ÍˆâešÔÕäPP–%šİAIäı·zw»‰ÒM1âõ¨à/5•'hå{˜ åtz”'İà>/E/5!Æ\Ä’?%# *åNóW|è­2…G²,v0ƒw¶&··®ÇªL!•·£eÂJA¾¦Æªjv;xf~[½UZDÿç$ƒ˜'˜ìƒ!:ş
¥½VFLÓíÆaAóó»mõUTÏy_<bPZzé‡p©?‰Ù]è½ÆŞ Gš{ß‰Ê€(UA#Ór•ıI$ÒHÑ…ï*) ”k`ÎñTˆÉ£è¼ëãı‰bgU>Rµ-ıÕLÀòzÕØËµr?£;Åä¨ó:—$*a!VƒŸ¶{óU©Ú~Z“s¶Aü_ÈXÇK¹7«‘,ª›İèFğşU1r„|`¹¬›U¢ô_¸£µã†$Qçì73
K2Œ²¶9ãxMr·‡ŠÉõ˜æ%©‹™„»¿ÂŠ
 ~ôU[ùNë®‚fû)ËZY^eT¥iÉe*«ÙÒá¹›,ñËÇ“‹ [r=»6`N¯àY ç#ßtOš§›ÊŒ]«+€JÔÑnÁ6jj5TŸ}À?x’;.L;üQş:	:`q2Â·!…üÔIdš'²dW‡3d•Â<)j·Q‰A°7¦õaƒµÇÍôã |’Ÿ·rZ¥Ox„-It‘ƒ]*hé¨ìÿ‡ª- Eúø¸¿®³lúk»[Ş$ıa/¦»Ödaójóü}>;0ÌÊè2 ?N-,„ mL=ÓÿM"é‹Iƒv¶úíâz`%7e'ÆÖä_¸ÙûÏ»>Ê)­±yàî¿T8°Y+ì9GĞsÃ[DyRIîlá‘-1G"?|ğ@
¤[&I!b¼UeéÈŸbV'»Dâ‹Â½¯\ÕYå"ß"i™8àÆ‘YOáJ³cXÖ kx”ø¬ZbX¸¦íFJ:}ÔËM(E ïzèÕ]ûÿ¾ğ(1n€9¸Ç82ò ½¨ K9oR½Õ(è;ƒ4œº?t;AM€o®c¨åŞÀÓ”È€játdñÚ ŠÜ-êà‹’)¿‚‚À4`ğáÌÒ„™Â>Ö*¥…Úøğ™ş(Û¶r?àƒşmÀæ·¢tÃİ²ŠÜE…ÓÁ¼ ãbÂO)ÿ¿/h¼%ÏÜ½´Nb2O|ùµBr"Å)ˆ$:õ%©tj{ßÈYRe…¶õkˆ”´•‡pÕa]å¿7eœ#Z°xÆzãh«»wfº†’Ü·Y)x„¸gÎ®iŒü÷¥kf‹Ìù&?×¨iÔ7g¿pÑı™Œµ¦¥…“Ì´_ø?a6’¢‡ÿf&á8GOº¾`Ş@uWğ90—ë)¿wlgò@šaú‹axş÷(’¼ájwğÎo¥i§sh±TÚ3cg‡ >ó$ĞŸ,¨Ûê‚ÙŸK§óS%ê×û5	U®ïÆ]±…z&Ø5òë`Ws^e6¦Ç(so·)OÀ‹hâ Ëš~±DT½•±Æ0¿©”–ğx5WS­æ¥Éîƒç­ªv` FJO:¥B;>ëåñå¿j"4}íxy÷¯<É’®Ì3µ|À
óD_OñtÂ¹`¾¨¢SÇ”|îáˆ¡Ëá¹•š: rR‚ìÉ |¶;(9úï.Ä—­q'%)ÁT_D©@OÕó=ÁÌã¤&L8njGƒ)şÁ¿ªâ_ir©è$½J˜ô?“HFTrªjÕw–óÿÁÿ8U“è¾H¾÷8QNØßàÏñ5¦Š¬pÖF-k%*Ä3ş!˜Ğ|{ªns¢îz¡¦>lÌ©î0À'\ †%‚Ö\Îº@$‹»XØ®LpÌd¦“Şlá™,½·¨°ñ xåÈÔDÂë]Œr<[1°Ø£ÇÖ‚ß:MŸê6 S§î‡i”vgš¶F‹mvªÃ®Åù²âYY¹œùªäĞ\1-j?5\œıÇX!ƒgñ—HpÌš$š>›éŞï¼Ëà¼kÒêŞÎ*:~]ô‡¦\ª]Ï'_ØEĞ@sĞükG3c
À£Ùõhy/Š¦Èr±¡æ¶‰6g¡`½Yn4ÅrŞ[‘Ô ;ê³ªµÇOHZ‚DÎ2÷µL}PÌd‡öüŸ>Z]ÍĞôõ.K=“w)Øé‹"íšQú_KÒ¨=37ÒnNvöîKWM
-gÏÇB‘Õ>¶ÈÔáûÊ•dûç1Q=/réŠ>–8w•dhS¤¿½ÔcöG”d7÷å×yLU¢ïš><”‡üÄè‡¸ˆ+¿·IĞˆÀïë-ª	ÄêÉ{Ñ)Qı5[ì3ß´ºF$î¥3§8d¹€j¹ ºó.óñLEPë£%°2êöeRæsÀà¸¾ìÿ›§”ïHó
„ó6¿±“°R²Š˜%ú½P€œ-÷ı$qîHß\ÚSX·¨±sÄdkäh#´¨QŸrW&¨;UØ€­îb Üã
¿¾F–½™sH,)\)ÒHÂ|1p©q£ï‡™“Úºhrä§xúä?¦äxš`æ¦?®ù5âÜ_kú!ÒµqØa+û£Š§co±SØ[Ÿ¯F@­#×Ë›y‹êq³@ÖÑçW\%IO>™@;FfñÌ'”@fğ\7zµ=ç‹„û¤¡ù–"y4·Cêƒ3/õ¢1ã'µÎESÅ³İYü”¨Ô‰LÆ‘†üU{˜Xç–~ÚuâÇãéìá.zrÕ æÍÒµĞæåDõ¸hl>™$ì§9”]d%Œ•TÕÜ7¡#:„h«áêı˜MÔWtãX·˜í×¾üBgR‘Q—+4ÉğQOgÚmÛğ¦Y11ìNîØÏï¨¼´n™Z\šÄ~æ©ªÖ6åÎ¸c³ n£àsšoA®¬o>(æÎğ/¡¨>s»¯ûòµ
°ïxn®6æd!W!õÖ¨İ§ø3¢NT‰'ÊV+¯§agèkéclqÈ9’„ƒÆ¨y~3FãôDİØœ=w‘<“iã4Ì’áÌ`‡'}á%¥ÒoÛ©ÌÚ‡’ø"Mº‚æ½ôİ¿¹¼n»F®ğ«¾ät[N®Õm€½)Q[öm5	ÒûBçÆíiÛ½.á^ßªB5©©•oÜIÁG½éQ)r·ı€ÊWy‚ÚT2_¿_ÖÂ’”WÚ÷ğÖ×ª: ö¹CAÄóPú~_i¾,.˜ÂVkÚ›ƒz1Ô8ÜPE2 ¾}ÃÿóßS¼vIâç³	õ^Sõı¤Æ÷õ{ÿ„T&¡üy·ş&Ì$‡§ˆd`;ïÁÃï‰;8_äÅ¬x˜Œ¿—ñ×AjDàù&¦é¿E’›"‘´IÖŸEËç6ÍÀ~é}.ŸÒeÉ4	ËËn4—”ˆ±âgß(ìù\(±sçãco´3á[“µ·Ó8¥•åÖf7.·ÂÔíqÈµ3à’Kê|%‘ó²äõ“ß”4¸Ş‰I·ÏóàïXø»œB«°%ºÒ,=‡f4{šI}?Ïİª:€r‘(po»“¹xoÍ€Dú‹ûŠ@êëÕ7œhL7uóKqMy±5—Îë3£ôuËúY‰ïC…<á>È@!»µ°}úAÂ^7†¾f5¿ã;—‘Ì4Ş8~ŸÚNçÔ“ÅŒ‹‘.Ôš]¸áè¨ô¤‘<9	`½ÊøY§Ê/ºhı-ìSpmA_mNÊ³‡ÔsŞ u†Ä/í’Hnğ‚1ëFë÷‹l=’îßì”“ş¢;IìrAòO†ÎˆŠë#Wš„£û¡ãğ]ÊPÙIµİuÔnEŠPû¨rÔší¯esş;s0Q8äùº`3°QƒÓmüæêŞN-V,ØŒåòÊûásšm›–™ÃôîÄÁôà\¹X’Rèr—"·‹¦Ğ¢%°Ocày~JòŞˆ‡€8t™dQ8\µıÊ¬Jr(8|*,\©Ã96ø%+ØŒ1OUOØ;ğƒ¨N[³Zéê­aF@|ÈB‘Ô_dFEÕ!‘T«évè®{†°µ4¶­YN`•É7|ˆ¨kÀg³*[JqN;õç¢:«Q$àÚµd&‡ƒu³j]ÄÎÅğO—ó0ïíùR·3~\—Å¶qPyp'"ÄN>=)]Û06jk÷bÚÛôÉÚ•íg¡4şx•7Ó2Yô“Õ”MékÊE‘ğ_É®§:¦-™ªñÓe¯éò€Ëøğg½ú÷“‡Uæ¦z©,w >Ì^«Úæ:ªPFZLcZî‘)=3*cóğïğ AA€XW©E.P;¸«·èF¬Âl) ±ûïâÇûòEô¯Û-ëZÂ?Ÿ>}3İ/H½»Å6½§#ÙDÏY,¼ÛÁñ¸Ò`Q—0&<’İ×a'§ï @ë/˜tŞBbìóIb#ˆwfz¦Îhwá!,É€±I8ÿGüÙ¾÷gæıH_KÓsäñ¶X>$äÁÎ.Lm«L•İ^vÕñzø„yÕkÍº/§ŒÍ±tVaWİğAA¥ šş3©æ ßÓ%¿‘äÃcS„}.¼m•QLÉG¥»vDî4ˆLûbøYPÄYh?k/µ6%Ş,ÄÅõCß@€£l]â¾”š²á®Ü{q
xæ}ù¡KIÄO1—CèÇ¥mØ8‡¬¥v!î’µ¹º7!Éó^íkZíb„šİHà‹9†vwÚ˜¸.MpİÎºÃN:>äHÙ«<´eD®?ÂGY[Óä	D­=ÙrXdY‰‹¨{Îœ«aÊØÈ÷uO£¢»êËmçïPğ˜.”N6’©’ãTöT
¨9ÎçDÁo%ŞÖéâ‡nG„Ô²º˜LnX<5«0
×õ„¡î7éMıŸÈ3ôSàrdbÔíÑ^¸İ9Fõ5G¯.u_FÈ9pOä04â>[K‹3 rúÉ]Ñ],?¡¨ĞÜŠ:—ÂôâÎ	ÑjütlSG%£ğÌ¾iv—>":Ş±ÍAá¥¦Öw
'ã@‘Wl¬‰8°l¾ÅÇ°™TN"F“ÚQû™hQFÜ†K<óõgYZ’)]Ì©ÚáıV¦â¦T@ÿ2J¸¦º-º2-ÈUYƒëÏø³CÀVY -Ü0a‚õaœÊ,ÂÄ|Ÿ§¥1?ğ¼/´§ÙZN¨6Ì@ºJ„7êc³ÆÅ$vÍÁÿË`Ìºl+dYF1xÄû„«4U(’ù¬ÒÎfÑQo•ƒËa¶*çpá‰s¥7?€ËÆ¦[IÇ¼R\Sâj?‹ÒN<Ê·İV»?ïkÌeîúŞã²ƒò×Ÿ€:Ó¦SùQøH¹‚©ÿQík––nq{	uê}Ÿg‰¬7B&ÑÒæ¾Z·ËÖšëí-¤•pVıneALetË#wHpÒ’búgäoâÆşµ“£ĞÆ:·vhñpÒÜ³áõe[oYd9[IØÑğÄ´@©½xêŒ5ì8y÷„°…¼xDL¢2bw®pÚr1&C!ÿ–j‡š”¨(?|dw²Èl=‹m)OÅRÌõpëû¡)À>1›3Âºù,ğ9,äõ77ş´²Ò©Àf¶Rã™Õ¨Š°¸‚œ—
q%šSä…ÿÑ¿~)0LÜ„+…TîŞÂ÷Hq3]ï2ÖûÌ¤Ä!»Œ\’Áùñ•@†=l€ñ’Ö¡CãÒ˜Ï·R?±æ7®»)Î|˜HÜ½ÜÀ/›—e\ş;_İt›7çb)áõ¼>/¢ñàcZ*ğÔî~^sù^~™'¿-0è—p˜îû }İ˜•X!O«_K¨¡q!à`…k•.M5TUb“HœéÅät++AB®{k ÒXèQÁÌËYşLÈ%‰¬&Æ4C¼°ï>m’p¹ı¦X¨;ı2Ë´† 1ÂÌ_>|×ó»Í¼Ôà¡{I#ÄÁºWò©gİßâuúá& :.€œ aou³ÚÎ“‘%UşÑ4Œ1kãzl¸ß%¹Ïvs”ÿóÂÈ±“­3¤ğQ™>‹K®5Wıa7‹‡1·Á™_Ï»™´òåÃ+‘r•GüüUwí+é ä3Ùà8®sğÚ©%Ø>ÃTæ7‹ŠøğcO,ŞUwË8c5z‡Ÿ©¸oÆµ€;_ğÄíFU™©î—9ëŠŒSÇ¦¥F%./ô[¸Ø„×
~,´÷Ú™‹x:2°¢!ÿ©F»†%–X]¶àdm»ÊŒ–ëR§Â<òï›|\áÅ±xR§ÆòÃµ‘¶›fåæ+BV+ÖèOåh·z)kÃ{'B¡Á^üÔ?j‚£ª½jq¦ç(<YqC5Ùø#<çzœîÌ1ÇdRÛríi¨>uÉ™hÃOÃ
mßÕRçãçÙQÅâ˜¡ãÖLò]Ã†Ùš4şÎ•v»©Y[ª$:ÀÊÿÅUJ®@&ÅšQj”§Eø"Óâ|µP×…i3Öx®{´„BPì”À°K#h›QN…ãu #ûbg’ª_Ùõa 6´z:†,uWz#k78„ÀÎ —'oA‹#wH£höG¨×y›•¹ƒS¡nÑe’ç FÜlK
ò[›?$y}Q]V@%T¨†
¨Kş4ö¯ÅTm8S ¦p¢¾VŠa9É"”á§şğLbw®”qSóoŸÚ’@8`)‹ÉµT/çª%ÈJäy-(Fº"Z)†M³!âÓUJµ^>›ƒOJ×3$QÜ¼Ô•¿¦e-õ»¯W=ğëâDWğòÍdå3»œ÷Åtú÷G¥˜s"ˆ°‚ËJaiğ¸v<’¶LH<ÙåŠ‰›Ú«€éÃ˜S²gÇíî”TëmüYtñ­å[Èºd6î½¨+³á(JŠ] ÆdÜİ¥kİ.ºV°”:b}uæ¡ÈŒŒÆSü}#z${Çàp&õéHáÇZ˜òsÓaCó©‹±ôålà .8‚ú¹’v_tÁ[‘·âm‘»t¦dªd6fo›Ÿşm]ã—¥ã(£	àh
³©ŞøR`J}VİÄ‰§)š5¡|‡Án V-„ÚN„÷äßA­ïŸ¿)v&€ekÉQUfˆÓË7î›…Vù‡9¢¯t‹ÖMük n6”
í-¢ú _Å-äÉ½sbÑİ×#¢ªVQK3Ûª†;ßLT€08á!ú¶%K	‚v‰´'•–ëİF(ÌßûÙJÚÑ×›U˜÷³6²Ø7ËÂİÉÈš
¥ ’Vİ
ªºú4™Fš–&yÆŸ°¾ÿò Pİl4[¢²·o=OmàOûQu)e¹4qƒ«à &NÆ‹àÜÂ”RªêNâ>Ì&è7ïS ¬]fPu€Ïâ;KxzªTçfçÀİ?Ú#ŠÄñ›hø<È64—j·lĞ®_EQg®qÎ5ó#QòÙ¨W¬ÔËÂÛsåFeµaËË€ıLû†5—:ÿÜ ƒÎº…‡ætãtÂÿöa—Hjú‰¨GŠC!È(Ó¥Ä®ºOd»}"¡÷õTåß{±®“†ñs³“ƒùˆKjãP„ˆğ{€Ã€dTËÙ	Êˆ®û@¥ér¤›$lE­3Ø²PUôez;æ°,í@—|*A	¸Èİ¯ÙİRÜ8šÔ5Ô.ûvÁ ¾Iåˆ#*«†Ï8ó­¿«ÂƒMtnô*»Ÿ	Çİ[S<…‘ä<	@ØÛRÍõ´`·e<ûGI©­·Ó¤óÍ\QYA¯|²ütSi0ÍÃv­“Kßˆvšj­;t‡4
C"…©´Æ$ªÊ˜ô!…OQıP›§ëüó„_ìM!æGïÀ€lõİÛN‹Ó+w-¨§XlÛõÉÄÜfXRí5\CÓ/ÿfÀ'ò½–ûV	yëÌºª‹}LãtiMÕ!‹Œß·é»}úÉ­ê9¨>©½{•ìçµ‚µµ9ûm@±¤/¹*@¬¸ÛU+ˆ8ÚæuB¢+–½ö$˜D"û\…Ñ!G…3ıyüÜ˜¿k9öãeˆ2><&Â-Ğçâ>[r@©Õ¹NÛ£³¾-r8N7ş¢†¢ j5mæBÁÛ2é5@ıuJW•ÉñgÚ³õ”­6L]´!fTx(Øfi[ju(öÓÏÑû_İ#Œ%Ü†"xL÷òq3BÒ&f”ºÿ‹Ş1Jè4R òÅHåk‡=vQìÕ[ %zaÀÛ	”Æ´ÄnWÃZ'éÊq}¬õâÙ;>ìPj°Öe=Èê£'X=78ğµbo™®ı30àêÅ¨_É¼e´'l2å§â|´Ë\}@¤GÙ5^°ZÄç›ƒ'‚˜o¿]çá×û—ß:êÃfâ:˜D1
Z5’³Û1šéÀµ}“*™À’í€A·•›Å%Å’Œ”S	àom÷)À(i+kˆ¦Èÿ?!« aWš—æ+ õ!AR¶©h‘‹¹ <5#YT ¯ÈæRÜ`wiÅr[ï}º(H+³[äØz}dêXÁW&0ºÍØ]`{ñ>Ã*­kk)gR§Q}¢ÇE6ªìx+A"™BÖ0¾ìŸ Ñ§vâzöäèjæjÎ˜ŒF=¡ÛdoDƒÍö¼y¤ÁhÉ*gğf0ï†t´ÿÊ~¨¦dN÷Ä:™ÔàtëbÃ~ñ+üƒ{»Ì0zGrB˜\şå3ø±aÊm[§Œ'×¶Ëü±Ow}ò<As»ï*¾Òâ©Çr!Öğû¤×Hwo‰¥21«Ú°Ã8¬Ã‹› âo¨gÀ\-p å€ğb-:(¬?5D¦Íj	´µç.ÜıÆ<–B¥t+-ˆPC ½*\e 4^¬[—WK=İ‹Ä1ézŒÆ²ÖÈ>œ92åÿÄD˜I\î¨_= ¿dºæ¤áZJÙà'ZPÁt­)$Áuõ…
î…´ÿYí|'»x!üªÕ”÷^ÑÛ½-âº†’Ø0æwîqeˆ¥”ç†.£ı5jıà§gUÙ'bZ@úîìsú±O|#)²}š9]bƒÄ ç9w©*L~…ço@Ò,™ÎzP ùàávºí‚|Ë§´nÆ
["pÅêu|èØ°7Aß^òéMĞ€n„rİfë[¸±0`­Ğ¢OãÁ‘¦v“¾W—hO;bş.ì­>ç8¶ñèòĞ¦?…*ã1p/pˆÇÕİ¦]áù•‚:p-õ‡K	ucËw®WŠI'¡Ç5ÕöGéåm•ÿR:ú2˜.N
MÅÎf|Cb¡[8ÁX…ˆò°XQ,¶êæW0g--Íş%Oıõ¹~É„[&íóˆT\1Û@dºÚVğ uW…>Ñ1ğu8Ç	ZÉİÔP±«G3g“(÷-a½õ:{Ú+:©ì‡õ‚û2šÆ¢mîR‚”m•æ%c1ˆFåEIÌßL­zWAkÊ3ş›VÚv…§EØIœHqZœã4‚¬¨‡¥k‚§áÎEãËœ
ˆK;IæGóüH<¶¥7ÏTn¦bo£KÃh(šjf2IC±Z,¯ã_ôWáË¡ÍFÑùÆd¤Èèê< „rc\L²‚`Î@ŞÓí±:Fy\Î'ò«œ«n0§UÂ,dg¢îX:-Š›S.]>ä×‰ÿ·LWhû¶ƒ0ÃªàláŠIEfZLm¹³
XXâC“Bo‚Ñ=ÀQ$Ô–)ˆq³åKêÉÑ#.È&‡áÉDY„§Óö>á“ˆb¤Û¬^¸ÍAâ–ÖJVïğ­Èù¯ÛRdJÖ0Š~ÁE¼r%K«~ñÄ}|
*rì“Æn7Œ027^9ZL÷»¼ú»ö#ÛD–¹E @aò—`ÖsoF'Pùãü˜âŠÿNÕ ßŞ€Å78°ÍH ­ğÂsV—Ë.U$ÈÀîMßD>i¸˜8W'ú•ÎoOt¸.P Cl‚#˜[äıxÊ•äk+ú«½©óˆèÅ]¹x‹u\iîF½â »?ôòÓ”õ5`İ¸ĞÆ³Ó\çıı:ÑA(BXBª¬_ÂzĞrT$)ßÒ>%ù:3b~W™½³QRÓîoÂímÏWéK¶	r™¼A_uÅ/Zwî”ZFç9ÁàŞ7¾Ç|(¤Ò=óÑ¼ùqíìÆ!x©$ëèìhZ^ŞÉs¦ñÍÑÇ'PqÛÑ@e\Ö¼<|4—D1>:3‘9KOE?&D];„îk±RO£­~IuÊ¾áè÷àåîÔ(O_õ)%œÈ<ú’R#Å?bVÂ½Ó56,>yôŞ‚ÿ+ËCq)1ô9PF›±‹Æ\d‹œçQ³uQêÎ³3¡ÕS*è4zM$+«	Ô%A'õÜ3¹ÏF‡ùøÒ‡TnöäØ
ÿLsMø¤uÖ(G¼Íá¬KáÃwßÎ“–Òg°«ù²;¢7°FİBMYFèÌ6êšhìáç„yªW]ó…A$?Å„²`Fóy'gKcu,l<ë¸i‘YdRÈ£[äŸ3Ü{¿T§4ŸsBCt¶æé)iÎ†3jßŸnz£ˆ
q6ÌõŠ¶W<F8Lû¼×°Ñ}q/nkVùÓÀñÆ±€]Ì«`Ïb-–?/–²Ò’ÑŸÃÂ”Ÿ=¾W±³ÅaH÷ƒ¿ê~&\—¬ª¿1¡‰!€°åX=Œz^B6ÃšQ…Òxû½ê‡5­1yWÄ?…œKyÖ^¨ŠŞ„÷~ºÄx!y¡ßŒkRzÇİïmZÒ'.è-jÑÜ×™Î<Ps›º÷Gı¨F¼ôÍ”	]§—Ö5»Uê÷AµÔ	bU¿ŞO7C‰(@Ê³Òß*íš{bœı¶%/¥‰ÇÃ¢,;ÏÊ¯ê8yõ\”áı KôŸ™ßŸu”®ÖË¬›Ş+ÒÒMùCHˆy[eÍiQ¯vœËxSzñ¨ÑÜªAµ@¡=¬hHğ¯f  „úÕs.bÉ	6@#8"©3?	-Ï˜?ğ<ÒoÎ‡ïŸµæ@Z#ÚRğÌUM/ìjºìS[…|cÖÏ›Şe'ÒsÚ?}ßkp%yã,›§ë¶òyR)àÑdtß– ¸iQŸ
ƒÔ*³ß;U}ï˜º2óÂÿTL¨
-#vÑ¥E{QwíĞµ¦x…Ú' Ì©À®Üš)“TÜ‡ÒËÄ‘w‡M“"N?sß½%š[?OÁ“²şG[î µÏL ;éW„ø ¦Ó9yÊ›Ôn¯ Ø¦®G~ı”&ø—ª©ÅŠÜ„å“vÑŠ‹=Wj¦H§î§¼DÊ^ü5QÏëÅ±óExC—o@Ï¤ac‡Âu‡Æcr7YÔÛy“NpÒJxÌ=Ù¼‰´iAïf”V§™K;)½#ñì²:É®n09æëpëósÛái¿'uÂ4=G*vT”ûÃùÚÀHzïzî¦ûçg'kœSAíÁõ^V¨-Âf7Ö{tä¨Ê}\SšQª„1¹**å‹QÍœ]<ÑÂ˜ş…ÅzO|ÆÔ2ªkİ~#©¯*Ò/,áTx•HYÛØÒùù˜p9ju3—ÜÂ]q¦Ÿè‹÷ÈKuGÎ\]é>NBAb.eå½~9V=P·õìEğşå={¡Ÿh„)zSÀ˜å{stx!5Èï.!Ê‰Ëñ*ğ”ƒ‘ÙƒÕ|F1* Ñ™:nç3×IàŸ®zà¨ñu óãd ½r;Âä–=ô•8«Ñşİ~šÃ›#Í\
®]4?ÄŸ@S}2ÎçùÍÂ¾*è¦Ü1¿æë~K^e’mn"µ‘)î]Gı »lC¹÷9ttŞ‘ÇÅ‰-‹õÏkF¼âÁ¹ú¶;ŸãÖˆºÜ¥›öôùøIfÿÔ3—ß´C0M*ö•+Ox7ÈïxÁ¢ÉÛ•2ó¥NHTÁjæÔ™i1:§r
¢7ˆP’ıå«à$ )aœŒŞ]­ye?$é|mÉ?u3öb¸°’+g]=®ùÈoa(k‚°î»O9¶S[C*xÃP´c—dİëÃ¡Õ"Ëşñ+W!}g¾“¶aƒ±}Üõ³Ô‹xoV?yƒ²¦5( {A¸"ëœñs?'°ËWïSƒ‰2Á úNMzfš-ÛKÁ4 1+ô%ÚNi`9hX|Ø/›Ï{Üğù+HK &¬üªÈlb«J»‚äšúá¹óÿXcYéæó˜€Ş¿/]Ø­Æ‚šĞ¡9èû]ÙA¶QgÄxcé
æ_é}qã Èd¦-ı g³ë‘ÛòZì4T 6æZ_© ÑóiiZM÷oïÆAË]0µø«y4Q‰!J3ó¤„¼(¯^­èTù I`,/GE×« ûµŞIË£àÁÛñSGÊôxtè;½N–—LÎ"Ö@PíÇö û*&Î…Ó“¯âÂoX%WeR^S¢é½<ü€\CTt©ÅÍ“‘ÒÙ‚ET'¶¢ƒ,>¨İw"‰;ÚHÖ´¶yå[õìlÿzHUÇ¾ö+S}Ó`´ñ¿Cî•p‹ZQ…Ú'Ğ-JöI@›Öôên·1²±s€|ÄõRL½¼Åy¸­±‰.¥V6»ßGÏKØÁÃôÎAè«R–œó,]_iv\CPrá`­XœìªÎ}Î[[ï Ï¬§ôv†ØPÅòên^MÁà‡r
"RàMHÿ{ª^fø8=€Š—ÑÓ±Í[ÜËOé"óôÄw`^t1_¸”åFÈo[}Š9ßÜ™e7ÜºI»ÃŸãCG(Ê÷…ÓT:‰ºıˆn¢à„¡ê“`É,<‡Æ1Î\ù®5'9vë£ŠŒŠbİ²Ã“ñøg¢xŞÀlr*œM$Í[ NÖéşPú¥ŒU›D"˜8cÖø´³t³)¨†üŠTËšªóñ~:;şŒ‚ØÊZ\b7³W¢ãéÄË‰@èp@?tœZxeÒ¹™öpÍ™F¸ÌÓˆÖäÿ
ømÿ·€L½«=7Cº«ïÏ–Z×ßhQß>Ê«­åwh1.íQ+eq|@kÖº9d šõ¾—¥¾ĞdjÍÆ]«3H.Dz\N´h·lÄáĞ\ÊH›¯nmãKu8±ä˜hG‡3³X×ˆı®6WæúÀ°Ğ"Ã§¢ÔY×Ğîì6à#l^í3RV+§"Ò$¯JÆÖX®Ê	×µ³— ¨ü£Á±±“‡VÒÉÏÈ,-ÃòŠ£R±ôğ=jª¯¬Î¾= à.jÚÉ¶£‘Ì°(0>“Æ‹­ç¿['EñÁğ~q«ÙsÅÇÒåç¡£UÚc]‘‰ı›á
V;F[-ƒ%ù¥²¥ÑkÄÓ¾–·ÈŒ…iÆziÛP,yI—h\vÑ8èMš		±†²İXèAL®í\¦.ík}#†õ>—êêÑê"Ë"¿!çÆòÿb¢qµ­ 3¬–åOg´!€lkTŒsyÖÁÖ¦x!Şà®îã¼ÿ=Ë9"lêZg²·e(W¿“0„°7®kä/{†c{*]nhp°ª¿^7 ŸßNM1}‚òèµ‹uÄâmn€ù”1Üƒ§Ğ\ú'æ[TÇ£s›ÊÊa1^RõCÒ6!A¤zOS9¬!‰L¶¸Å;«r@fÚş#ÏéÜxÚ» B¨íıñÅ4,¿(+¯b4ÌÌw¢-än^7NLTá¥ô`ç¢gåÿë´ƒÍtmH/é¶àƒ8ÿı#cÌ‚½%–À‹Ë'õñ²†¼krö­C¯ÃĞòÕç]±İ-®§Ù5½‰Y3KTi½UxR2(J[eîD23 j|’`òüÖZÕV4°ñŞßŠÍğË€’¹ˆY°‚Å³g5ÂãPï¾‡TññëŞ#N^„¢ÈâL£,lÍ´À-_øï¾|;Ro \_¼s*·¦s<£Yó—ğ!Ò˜EC`Ê8¿Sø]¾†Æ'èJdş5„©ÑÒØâMa-xT©“FÕlÛ÷æAš˜¨Õ«Ïñ\³r[Ua–Š¾ØÊ|¥éìª[ì–ëéæÈ?¸g2I€iÃÒ¨Ì=„aÀöVïŸ3µï#gj‚Úsƒ-p†^<|l9Û®™á	"ZËÆ«…ô¤Lş”å1å»²Š!H·ât]ÆFöi× †¦¼¶ƒg5cà_ÃtÜ@s‚İû+Dõ™"}\×aÛË\têªxğû§(Ô›+VHï››WËGL9ûq¸'=f’¥êvâ$†o©Àøç"·ÿàÏ]ıøÔ‹èmÙáyêÿKqÀÛ1[ûÀ6:^Ìk÷	DPúÕÌèíË;3:ı(c‰u„¶ë®w ©`¦'1ûê€N`>£Xòmë¶ƒ+ëÍêñª¤ußoK_&Wø[xRCÒˆ§ÉfÿcGq şÿÄ»z…4b	ÕAè:İÅj0şüe9§™–ËÅëœz»ó"3Oœ40â¨:0ş¦³R¡Úg½èÃ›¹kÎØdşáL™ ä¶.m%œ azÂ·E2‹ªàv¤Ÿ‰~R@®Ë”Â»}¡gB8l%á{`E-‹ÖˆÈî4ûïY+{Œ<šÉ×ÙÑãwä=å‹!ÌºÌ“4Ú39IñÓä3:¶x4‘C,˜UÍ°0€”»µ~|^~{Ğ¹Ë‡2Ãf8Ş[=¬‚9àtu!Çè/JúÖ¥I.‡# ío¹pHÜáX…7	ec›DÛPhÁÏºr‡JºØ–¥m]^W:äØ!7¨9%1›+rÍjF–„yï·)’8]{
cvÏ	V_=:Ëx%Ü©×¹Â]Ö­w„€ágzüÆtJ{Øí£fï¿£LÍkn„ô?oÚÑ›kÔ7åRÎİ}dá,Õ\YÄ£I½X(Wç°Ğ„"én|ëŸÁ35ºÒ6VĞİséõmXŠF·]ìÎ&B²8Bûı´b¶
¿Gl™`‰b7ïv'5õVq9ofiˆç…¡ »[±kábkÂ¬ÿŸ'@ ôP”å,ó,>íššçŸ†±éF¤µ1+)t‹Ñ-¬B	|Ğ;¤ú}ÑM,\à|²-=‡Æ0‘ö»rdÌÅ’s,ÃUW˜ÈÛğqo(©y8cõw	ÿBØ¸˜PXóŞq-˜Çvñİ0/MFSáÑóMruì˜åÑY‘´dOÙ‚{ìİß–˜G“§õŸ)cå–!ûämıÛ{¼¦ú&
Lãc”/-qófÕpö¶*¬pb›­ŒB4Âm¿5Q«.b>N?ÊZá8}Ü{ÁRÃq1˜¤œs¶X»õ#QªÄƒ}ÌZ=Ì=õÊÓI(åæNêÓ€†<ù{@%DF¤ãæ(¿Z•°Áïx†(…¯÷a×ÓUnÅ~Cë)ˆ^Dd9m±ËçUi´Û¶l²è§ß[“¸&©‰%À#)gàÂ¥KÕ¢ap›MsòD¹ì^ÎÒAŸBõoÙ°Är¼R=·*»»U.×“Úò°‹Ãâ“v‚¥0KYLºgÃÀ¶õÇ™À†>’Ñ›ìÒä£•‘?â»ØĞ“‚>SÅ!	«†)Ö(ôú!=Íe¹¡˜IâU·ì…ÊÑ7]Ÿ¤pUÓËÿ›EX|WÍ*õT	i!‹Fg7V“·0ÒsGfI|„ÃxVDw§9/\ğ[§6sQ
\µØš°˜‹ÃÑãİ[^ˆ$išö²¹	ÕœŞ¾/uœb
J×‹ñåEĞJC†ÊäËªt Ã>—i^ §A™'¸l.ïª}v›8E–É5¼WwSWSØß69ê!õxğr8™÷ˆn 9}dôb‘%ê,ıôÆÖÄÜo\KÃÍòäŒÙ,AŒ>A.ÿ\|Âp‰õ)ğÆĞr„#İw9ı#™Êºk©gVÑ¾ÒqV‰SùñÅñ/	²´GAö[´`õ•=c2iøXşÄú…¢¢ŞK	æšxg¢ıÑBVûnr‡ª‡Æä-¿ZÎ°£ö™Ø,â:ÁÄ Œ$p„w·µJ™æ©¯m,¤;Ø¤£ıZ×0W¡ØŞlË;u–\şhUˆˆh\¢VÔ·†ŠTÜî/ÙÎÅÎ¸Ø·„c ‚şñWÆ:7_¸atá&¸: C}º¤DçÀ{.‘àôF¾€6c.4<ß¢Ğ>|\$,bT0iey@Ì‚”š;oÒ©Í{Ş¨Z»B‹Ä(Gœzâ}Ì™hU¸õS³Yÿ˜mc…¨]uaÖ'äû šHòWd¶ü(òI!VˆèH_SI˜[gŞ1Æ£ƒèFÄÉë*¼î'Ë>ª.»:ßP–	;µĞ°EÇ|§FÊj ÓĞş.•uÓ¼Á¦Fw¨Ÿ§ä›×/©¬°]`e·"
Zºi7¦ÛÍpï~ìı¾G]€Ô[ñc¯h‡œQÊªÀhbó¥LåØî³‰lÿç¹=oÃD…f¯”ƒuª]¹©+K5eˆƒàß¤o$±ªÔÔ€ê[{ˆóİÑ?¿µİ‡lå™qÖ`â+b˜_}„'ä‡¨c(¡­ÚTÉ?4‚ñÈ¯Ç¯İwÒ ÎLÂU¨„ g=y\·°¡$®Â"³1m¸Á»æ[œ¿{àæ;ÌFóÓŸğ`¹‡ÌÉ"ëÔh¤áèrÄ¯_úÑcòèıwx¸ùú”é….ëë"²ğüU‰¾,\Í€Dyä6½Úôß-ø+§÷‡PNÅæDE²kpWõ·‚0ëAÂ2X<qàX’¦94AÔRC« K²ä²¨Óşúlüª52…JËĞZvÊìz{=
èË»˜wïb¾öË<>Üúáƒ×HNĞ ÕÔäRŞ³“Ôù=æ+šy«zŸaö13«Vïñ½ÓTUºPŠïû:tU ª,Š“!úNPZz²ª¨4–AZö“å3K)÷ª©üe*&t7è®`¶^Àëça&ÎŸê¯è¨Ú-O-Mßôzu ]›*%(U 0 ¸ß‹´°Å”7—‘€ãt/Ü¨íé"§Y­jÖ†œ¥1OòóÔùoÊ}‘…#•dTsYõÇ¢{$U/€É6<SÕcÄÀ^·±õ<XÚx5Hc°h<âìíÿ¯Œ­++[ šhEâÖ†ğ”´S¾·<é‡ÖL4¥3ÑDl`—xˆzä…t™ròC¹Ö’“–ƒCcg1xAš¼-V?¿<I¯®ÄÍœ|?×M¸³Àƒj@3çQê"¾”¡`Bı‰Í†—kÊY/0$due µêoàÔ‚UîE[¶FÛö¢ƒ&±'U¿ÖÚƒLÄ3“—]¸ìö_—;­%_	¢÷ÎF´á|¢·@C¾¸OFìˆ¸PÄ˜aÅaçš‚·UB÷ï×¼—›®‚¾„ñËå ÖDx -oÒ×Ôİs.\);]^«ÌŒX‡Ëhmu°s¹%Nß©Úş{2yAY‹ê°LI,'ˆ’ºÂ xnÕòÄj#év1­[T_Öut7Íq(lNšŒûñ©ì/‡)ÖR"EY‘/\jbq^*Ù“XkCšEÍí¿Q‡‹ëÚ-ºĞØÑTú,oÿt'•¢Kk»’Û©*PÉíV`¯ºİ^&@ê3asø¬v×ù¶„?;!
×åzwßÑœİÒ™MSú0¥p²?2‰B€Ê°´ŞÈ…é2
|frAkÍø²Yàn$×ë¤æ)&öz
áéSblh1¯W1§%÷;A…ÿ_ÏoŠc.ÀR_}\´~ü“½<°ö¡¿„ÊnªÒ4µ‰Mü~Ÿ„ŒT|¦Ìâ&ë‚="p¦ê$ñ$„K ùÌÑŒ)˜Ï¸KçÇ‹ÛIùçşÁ…Øò›Z™mÑøWHå€ÖÛ©Ù	ex+VÜ­=®£˜µñ-›ˆf[«®%éÊõâ6U SàkÂÛN³›CJa”­íByÜH¯ƒ=’Ò‘Ğ¹ÑŠ/;Â£œÑ˜«ùyÚÏE#b=a×Í|$zº©R“›Pò›ÑÁÖÀğ|ğË±>	nÀ3Ü.>”ĞGe„a˜ëâRkâ ~åÖÔ™ ÷1g¥ÇÏäÒ$ÌÕë \2¾še?Y"Q„ôQjGÃÏ5v ?“üG
ğs*w¢?N>Ú+,à]fæß½Ø/½ôR±mQ6hJÿ X‰ÊŠ(ğöïoF33ŞAÅ>~û¼Ğ?üºh|Šæ}«yÕN7I¼•¿yCVbrvo©ô'¶Áíi?¡Ù%˜<äå4iŒDHæ'hùÌ-§Íñr©GıuEìz›©{PÌ“8˜ğ 0’ö³íicm`ƒRÓïQê[â¶Ç´œÈº}¹”
ÚšùÙ§Zv¶T¥[‘Y•ÒG0ª!*®¡w ÓgÛÀç8'Ş[¹è¦=íÈï`üÅœ¼’ìL¦°"‚HÉƒã–- ©@)Ótyİöñ8¦#7ş'¶È£Ğë„šˆ¬×GÕÌc–‹=¥M¹‹Îç;ÓØŸğ‚âÔ’z¥KfÅ"è¦!ğÕ~¾Ÿõh•!´Pbd›á­ªg­@’›¶dHÆ%Y,^ù&5@YH/Z„÷İz­yÑªœQ¤#Ñë Ş´aÍÌÆUipt„Ê	i‹¿¢=1Gb_ü~¬(Ô¾ß%ï›L\RËÍ”Ÿ)[¬FÄ6ynŒÒ®ú]‹ùl«mÍ>SÂóHõ×¿iŒg’Õ$ˆÄù“#2»@¤D>N—Bã7¨tŒÌĞÕíB­n~¨K—å´ñ{-*íÛœÀ@{á´º·Í4T·ûš7úQ1<ôñ3Åë›õ¦ËíÔşç’7á+¹­êÄ2™Ÿ;
kÚÜ‰›'µ•MÅ|Ês¡^‰š53ÔnÿL*ïoà {j±Ğ[Q2»ì"0^‘ê…_qîNÂ"‚Õ7]ÚoI>è—úò‰ımÛı¹›8wÑg?±Nz’;ù×aVR]§Š=-PåúàbÄ©I‡Q3Z—ÍSó ä:Åó†GâØİ¼š¯±+Ìé“àO°jÅ®Z q…eªÔMT~éyVõW_ı4¡óÈÄª†ÄG'ŒGOìp†äÄ~ÄgMN—¸œnÁcÏ#ş9Nğ¹íaWgæ=Êş¹Dá¨Hå$_¦^]ákdi¢Ïäü—a^²ë!ÊZñ¡«úAÇŸá	Ìx?¬Ç¢ı„4Š…z %şróÌQmÇCÙ`/“—QÛV·OƒNàÉeMæ&G.='9á÷Â@llÅ®ıèd{åM7 POÍ¾C³†1 *­|>5’Ú¡qL¡%ÖŞZı”T˜NÖÿlaM„—m¨Ÿ1o¯”Š?·:¹¯‘³_îsY RLMS8À’ #‹KÕT\’W†3Ãq£Š_NH#şı8ë£[kæ¢ØXã*VµÚ‹w‰ÎÇ’ÆÚ`…s/°xÁ^İdLö¬†3•¡Í§
!V‹¢F\‘ÏFåäŒY>Üú ^—œ’ŒrÓOÊM©;1¶;»VÚÕh(dŠåÙw0àÌ2Û"ö>Âè³mÄ5ú™N5Ê÷QvP ÿXãw‡ŸÕÉãq"°gÇóß‹yñéœh)ød¶Ô~pIå‚a,ŸŠáÜÂ†	[+F³èQ­V;H!²“ïı‡=”|±}Æ»{c+0 ±äZ-%êFx°Û•È‚¿±ë§°›”³åásZ&J÷  Ô?1uœ »À˜+éêik\ÊWüév ¿^p³ßt¶¬FA+qÉ2>¨(=–EQo$ví¹}ögP&¬"xO²zx*¿6_Œ™¨Ğ‹ÌŠ
j?Óó1™™#îUNáiæ¼ŒCGŒKÇSCÜ72Z’ÛJI%!+…‡R„CØzq¤'ˆÁÇ4x ~ú”K%Ü-áSñ iGtÎŸ( 6Ç‹­ª-ï†Ÿ€İWboM&@ÏÏ€ùæĞ÷·V}aŒ=€vVÑ\™gGŠØ0åGOrxM7êG¨)ºâÕ4# Ÿ2~ø1eÊÊÑÎ?"Jrm¨»Q«¨º ^,1õG[Yï‚0pxÍ½×Kò|MK=ëÄ^.Vú’7LÔ¿qè«RN™×#f?*˜êS«|ü
Šãˆ4Ûlµ +¯y‹…Àç.
*[7mÇô(ñ/¨‡¼ùàdÙ‘¤K×é
÷dÌ µPi÷£ÀãÎÌMüÍ}¯äÍ*á†bÙà`D‘—y5
‚ñ3àm¿Á uœº¹‰®&Øâ°Ò ^ĞÑrû¡›)nÒMVxu” ©«X0n  …uŒUK“5–k@T!øFEÁ>wxjó¼U}öÚêRë~ÅÖÒN÷ìÊìmR»Ü_#±cl?HÓ{­åù‘½[B²uZ¨Ûvßê$@o‰¦ £ğÁxl>Î”-»Y±|_æà²vv…³îŠßşÕZX'J<ås<‰Bœ¸L³Öuó¨¶—2Ÿò0áwşÓØ…7²¥°úÄ[CRØ¨Í]×ùCƒ™=¬¯ù ›Óµ•¦’âÎ½…EDó†^£Vçq¦QQÊÓV¤ìş "M®A\‹@ğèM7¾!–­T|¿r~ø»N¶PQĞÒtkúŠÄ´ôVÇS§Ğ\7TA^1@ù8ƒ5ÔŸN¸v”FÙiLIÈÙïÒôĞ‰¾/UMÜ(]ÿWY|4z“?‹ŞŠªÕÏ_PÇÅ{Eu!˜/ädn AÚé£Š•£
v‡2h>µY¬»J¬µÀp_àÿyõÿŠ”Gíøp[P¹?ªH3óĞ»	¿ïÈ¨Eøâ¸ÕªKZFÿ1ÀAïöÂ¤Ú±ªØm\õçÔ?Î0ï@ÕÚ8¿¿s{{×w>%dzN%ä(làQfƒš=£P­¢#í(›v¶¼¾ğC5WH$ «iiBP¢=lxÚÏ-Çáø•ë²Éï$ÀÄ¶oQ`‹ó@ÓèÏ±HÌÄé»SÎ÷NËœSoÙ½–9‰hÖZ»•ÍÒµc=úºT¸c“Üö¯‡Ñ§Jóy¥ïl˜ÕøÏc®³­•H'>¸»_/í¾Vfô=GÔÜä”WÏİw3î»}{ù‡m¶æâñ‚6ŠwKt@Ÿ¬Ú!F«{·¹ô«ùÌ<áv9&]!`ZLRÜ¼ äH’‰mOÕ}PXQŞZx©a¨‘
Ù°ä+Dæí·à3İB">Ì“Œ˜›%´\LìÒ~¢cÎ\ã62‰É`‹Û¨ºÅÉ7ùù>‹D™„fÚ7¡‚_	ì‚WÙÂÚcµm¨hÎeô²Räş-dŠ É à°iÌÚÕÌ–q+ÏTûÌµÌaôÓ Ì‹¯—İñ,ƒóÿUN)€ÒÂ°=ÿÿº{êUùõ–Õ7!!P|µÎÛf9v ŞT&ñAÇÖ·yõ÷”9ú¹™A¦Âò~Rõúß!xÜ•o„gÍ·ÑEßÎsØÄÔ”\Ä†JñÖ¥ËG†PµÅ4
v*®ÅEÖÂÊãƒùT›İ (nĞZ­Ì# ßw6ıH¿{ö­š—zÒ©–2Ò²¿?eBÔÎ×Æ"ÃğJ?Â-œ	õMï›°… B+¿šF'pîPÂÑĞ‰Ş•Ä¿SŠ	HË¼¦ıÇ'g.ıæ³JÌÓ-öO:ñ²'VR-
»-„0·Î“Ã])öF§üäİ%@$4Ü[ê¿D9"ªQø!y9´J2¹,$İö\ø à"´Jo‹UÎ/üÙ?EÛn9cIÕ¤%Ï|7>o!bê±´}M&x™™·½İX”¥ñ•_çƒ,È&{,îî–åûpyÍaOvÑ /óB9ñè)ˆ¶!ç¢vVï³)Ø3?¨G½kıCşPıœ•¸
üœïeGº´D7,!$ÜÍ˜Co ’â¿<Óá· qú‘ªNkpv$Çÿ¹Ñ¦b
~ÕR8(t?õÎ@î¨9»½·Ä ³¤€ô@©q>á¥ã$¤)QYB‰Ğ´ê• ½ìÙ21‹_ôoû©¥LuäÈrcJ&ÈÖâŸÒ*Sï)2ï,yH
¸Ş¡I}€îÎŒÉIl’³	ĞˆÏÙ2àN|+›®ˆ1‚Üğ¡^”2@¬›ù‹åôpş#ÈF<™òI!ºÊa\\z!û¨ÍÊÁù…«+²4~šˆ2bWøüÕ›ÄÒÛœ!$ „/»ƒ½kÚ‘dGpµ£ü·¦%vk5`òâx¯C´,eo<9ì¨ÂÏÏ|©®K;Pñ»jt¦şú_ç¬Ÿ|ÒnŒ«Ô8Ÿ[Cû$ON±¹ä<«b(e¾¶6
vÂxzI/„²l@|ÆÏ­äë­›Èªº¸‡€aê´-Ñào÷,&CV®NÃ&/yĞåYt[Hjæ
;8û)ôÒô3fŸ®Ü_ôœAó®°±e\qç	Q	ß¶—ræF6ê
ş~¼[ÁfxBŒM³‹öô‹Ì5£¶ë.j©{Ñ½ y#;èô}O¨WÒÿÅ¦=HÜàš6È&×¥{lœ3ëw“¿cğÎpeã{†Qğ™Ç¾­µ³Xß½àõZUÔ*îß9¼ƒ¦›èøi'ƒFhGëm2–L:TB^%$«­¦øğl£˜“{¼Û‰Mì÷´uü3tªU¦_q—…NVò¨‘—Db¯dˆ©%AOK¿ˆ‰2„Üş3Ştú¬æm˜‰ Ç~˜è0QáÊ®MæÕDOùc[ò<Ü‹$8@|›÷6D÷gH¼¡%WIö±v+5öØò5Ñ%6ûaGÉÅŠÍ¼¡¤«YQwæ.§L0ş*ÙWmrU´íxÆÂ•w‰/ó)à…W«§™¶™YËmÁæs¨.G%EQ‰èÇRMEŠ¡2@…wQˆá/Ñİû5¬B3|sk}íãëXN€¯ÁZ±GÓ3ıNŞS2ª@|Í;IB«š»*ì¹Ár8™\¥<—.F±ÒG.ãùP™ÛQğ®R ³
ŒA'Ğ»ÆüFà¬Oì¼#ƒ\½òc7-Ôw¶
|PĞÂp÷ÀŠsLba…sâYªêd—4Ôj7Áª^’<èâ9Qj‹ûG	Aˆå²tÌú¶H.¿‚àœß¢ÖËÊM³:dM$Mx‚²W×±W–Ÿï'ª]-¨kï'»yf{©Œt«0BÊ=Õñ2vœ·¹ ˆ<—)Ùöí¥o…ÔÄÊ"8DÂ@CØ–:áëÁÖ@Íâ¾q±dİ	G¸×È¹¾›‘2@ÊŞ‘Úï&ú@Å-/½‰‰ƒ¯Öd,Í¦%N mƒ÷àw3k‡€ €SóÎ4::MitÖg•³ğ¦âÀ“_Í¢éÓ² ò1@¯öĞâøà<q™[œ8*)3‡=£EIíòğ~Š½•(Æ#©®’´Ô–µ2„®B(W<÷€Aİf‹è+¶˜qå)Ã«Ül‹øùuwe’Ş*1ª©ÅŠà€ëJsû ~­şÓxA:şİ ×¯RÑ,\*MÆi<cÇçJ@£g¸}6órÒ-ÿú7ú&ì.¦ä²ò€~âç’]‘9¾&’1; —àÍ7İŒ,«yı½o¶"… =v’±Càäâ³ŞÜmëäVS´£±ÖØkÅÙÃÂeÎİ†·G”.£àÿ[©÷vK 	Äõš²^\€@8¼è8=\`5í%u;Õr~çÁü=4k†¸‡9ğ|A[‰ÂıTQ¬Ç¥i"|“ç„ÉÒztû³ºì’ıÚÁ!£ëÅY°úRï¸fá“"ëDMâ‚G’?èÔ&xah-#O_X~5Ïªc‰:Ò—8øF€—	°+š¶¨&B1½ ôVZ¼Mº+Y¦ZQ¥àGÏó
ÌG çöv=	~=	aW´½(“xwA,¼?ıÒãÇñ|Ğ€×¢éé³,ƒpŒÇı3şIüíÚ.Óšq©‹)¦yo.qfÈ°Zs[àM’Dó/`×¼ïãÀÂ* „óšÁòVWfG†¬Ô§äòı“ou¤­ãÄ¿ÈŞgô×ğ*ri ¦hõ,¦W‹ƒƒ0Ü$ÉJøF8‹¡;®¶¿Ü¶¼lç¥eõ˜2Ş‚H¼‰…QĞ—$6~ıYĞ(UNUbáswh›opı¡?{"GÓ6x¢‰Õ•‹!û÷uVz¼
Ñ@Íò*=Òíû¹Ò}*äLÎB“_oªÂ3Ÿ’xÊX¬bO±~ı	çécˆ­ÔÓØfRzÎ¥N›
è™ìûyxŞù´ívCµÜª=ÿÔÑ¬¹<µ´& g|œÿ™ÀûK|uáw¼ê_¹MT{—,³ö'şá[h­ïfX¿0Fª½äNnm6üfEPsi•ì[•Òcn$ƒ,°‹› ]í 0ù^§FÎ§z¶ÌŒ±@C]«¾*ëx‹`í¶k´,b§²¡È;
¾<ûòH®ÇO†¯Î\ºÅ`”ÍúwavÆ<C@¿tMc!„ îŞÔX‰Şlg“+N#±ãèh•${Í¢Nœ7«§ĞkñitFÆbí(ÉöÊãHı%ÉeÛûJüît'dhTãÚÆ+Â+êˆ«©W‚}IVSïZMÅĞÒÜ‚‘‰ae—+ØşwFDL›+­3{ÿ©XØ“$`Ç€ëèŠ¤üN‡«´½-Ø§lQÍWè<jÿ±|TÅÄ±‡s7‘ßí}?!Å½\Øp®CÌ»A˜zØñ_Ëôg.zŸÜÕéQÏáEÒÕU¥K‹‡’íÃ4óxoŒáÖ'Vÿ@â ÿkŞÁšG¬!­Ãï”ı‰[ŒÚ¸GPM`©ÿ;X@•…‰	9ƒV<cf-ÎWåªFùğ‹ş¶3‰“UŞÙ&ìÍ´JGI­’Ÿ«Vt¿Á®ñq#OÙëiñv½c´¤ÚØ[k™l<.€å WbíÎÃ©ìÖŠ’Q„WQmü~ûQ§Î—{0ñıªLÏ×¤(fëSÎ¯!ÉëBAå˜äŒ'4¼Jª`Hƒ4Ÿõ„Ãre¯u&a¡e”•vWmM-Ç'¿ğÎïã?lpßs³,„êÅ$(—B¶ş¥¨Ê{üîoŠ2 +ô‡ĞäÆ¹§Ewr~âpè>…ZmæÿT{×ªi½0!Í–F2ÔX÷‹r¿eÉ$Áô‹ö¥ŒJ¬İaÆÏ?ìOàÿÀ*É2¦ß…Ó£6×Ğ¹dœ£!ÈMî“÷¤j²“¬Ø¡üò––•• ,ÉìäUâaëWÜPz¦ñzúgÁ¿/ù×»¤«€‡õ$?uÉú¨8ÊÅà+5{AÕ¨»ä4§¸‹š İUÃvÍ;pÒÒ¤0Ñ>±B7,ïr<ÚOùÏI`ì>BÀ+ùuJşîú´oÇ£ölg–â·K~Ãê5ö6şÉÕjy0¯òGÓ.éÊhƒf9_õı ·zñäÉk  …WıÁ¶Cqâ·ùĞR,xN ­õÔB´Eë¬ı¿†¡LKªü±Hc…2IçUòmĞ˜§pƒ3–æ‘MX¨½İÍÀYvS‰!³Xæz´<R\UeÿĞ¢\6´/¨1š^ıû~~Ì	t€FŒ4'§Gd·Kí’^_Û¹*äYD[,Z4MU˜aˆI×h”,lÈ*£gÎ§‚Â‹äcjşB=t1†‹ùœÂjûË=±×ÑxÏ2"‰CœoAu|¼äÇÆto$[¤»P]‡ô1úİúùaD”ïIİ*û¢êËŠ@5^¢”(°éôÿm¡bÄô—±Y®è†µ‰\†m§çƒÄR¢GªjIí¸ä†ªà<ï›sÆÔº¨C¦VŠíš¸Ş5zå‘2, 	‰æÇÙœ¶Öƒ=>Œø$ıd–@ï<Ú“‹#sŒ¯ùgı¸ÏİY¢ UØîÁ;' ¤Í•\2+â”#€u_±-%#X!èà´µ?&0  6b—ŒCT-g©‚…£~}ÃFj*%·Øu¢¯öÃ?ªä^³2‚°KçCÁ¸:sÇ*<üùÖÒ	K)AY—§Óñ¶ø8Úó¿Ì0¯8¶W¹,Ön¥`Ws;ä<±v1‡(Œ'ñlAÇ¤Ç^r0©G˜Å¥ã«*?Ÿ5ö¥ñ¼Ôƒ«İl‘ZésiiùY¡)›lnÈíûk®Kü­R‡Ì‡®?Âq
£ÉÃ’“ô£rµÎ'Ş
Ğtw}càzÚò½’ ŸxTá¡Á§ÖugJD£-C§ô iİ}5ÛñEıß–oh>PÁş9iìC$P7n‰ÚFF ùbÚÑ˜•1;äöYŸğ­×®VÓèªà®ïÒ~•’à½âø)šåÜô¯‹kãzÓ¿ÆJ(rø¶at’:]zÜr¼™¢û¹åbÒŒ‘vn‰Íş±•1El×»	 sv«Iu|™sËÂFÁæ ÔTÅ„†İ¢àwÿ˜jj	×Yã‘ËpÊ;Ê×¶+É¼)·Ÿ‹ä+‡dŞ×õrŸb\µ†IÄæXµĞpâ³Ó^¿sİ^Mv¯6?48rŒK£%zìOgsğ|ÖÈA;Ñæ\1äjœ¼• >ÇQ1!Q—‘¨pdw‘<»-òİ:ˆ%ğ¨1%wSùS·fŠÃålv­$ÖÔ~+¤—&[
Ë—õ¸üÙXŠÍûå¥ÑY?vãÓ÷Ş u¢sF«§&œ-J°$cüíĞ†~´¢¶‘&“°PoìD#‘ëŒ€«]–Î+éÕ€
¹]/½."†B}úèQH‘.xû4JÄõÔjø*Ğºhab(ÏGe+ŠÑò›~¡›`_y®}àBÔ­3’cÕ¢mÑâ®ˆ”|‡§Œ‘&Gt90¬œÜ} ä¦}¥Â§ÓZ%yy¬CÎë¬]¼{Ê÷Á‹Óe¡DÃ‘â€½Á­ÃÁâr,G£uÛ|g£1SºÓ>An$c<%¿\şAOze½ÃN¬®s]ÇP*:\à]¬¢ØyÍBKR’Æä·W•ßÑ„š?ºs€ÕŠO_ÇÄ†cUÛ´<	â8’…ÖÛ³Ç}—‡b+aP
¦"Õ”ÒMÎXRaLxÕËô½1Á%b4¡–ù°{¬t¬8N°Ùîº?1ö†œÔ¹©~©!©VMÏÛîwšw4: İ¶à12½Y‹çĞT(Íç- s'šlÚòâ])`Tÿr´]“‹Ë”“šÛlü¾©FÕ…)œŠõy7­0¤<ë³qãB5è¸ƒ:L·—w¨­tÜŞˆ£ª¨ éÑç«×'©+ÕEòãévfs¢!Ò R³Í°„õ‰Æ]İ[#à’—
eÓq,Šùßß…áu˜—ÉèùF*½s°>ğüp¨Öö>ÎeE§ÈQÆCÕd‰)xàÿ½OœpìÅº2}Ñàı2Éšà”~¦z†1•Û`À(8·×¿lJ 8G[G4\ ?’ş“¯ÿíM0'²ëXTè(ä|hß%â7”µ;Gğ5¹ÄúÙ-r—hŒBY2áõıyÑ¨häÄİl"NC|lP ŠJtÏh'6ËbäHßf9T§ªH0~ù‹B_©Ÿ½T+ó:}>rû71/Qƒ)¨¶‡q<Ü»À *…Wt•î-W¨znæ²¯o.’nÄ Ï–-û­‚R¥4ŸÁ–{ùõ_’_i*ğ .ùhI[€³~¡Ì>VÇ¾†gvŞä?
µ)$p,ñ;ú˜ó†Şš^a–…±|5)B¦[Á1¼q(å>kh+‡t¿ê2»õ£	V ,”w@¶šhÃ.F§Puavl^r pÎé7„5z»øÀ1—#õ×OĞìÿ[Ö(ï-@¯¥\M„zx˜uèAT@Nı#”Ò7À´ÉìP”R…»‹áÀ˜§·ƒ*à¼¢:ş€‘à¯¥•—/…†~@L«÷îğT3¡Sà‡|85×ÇnÑ«¥£R	56­ÛÿÇ“j ¢ÍM‰§ÑM$l¥Zw„è-9 šsëwğá‚Ì¤“hÿÑeœ{k*œo¬"7p8×Ï µM¾8ÿ´¢Ì¡tË`»¿(óidş åŸ4!»û-ƒ=š­}‰¦ÿğ„\£•,ô«ĞÔ¦NU«`˜§!İ°Íp(:ĞÙ-,úÉÜşëˆ«‹,§kS+j?°ş+\âˆÂ™Fs{wuò“©­dFÒ-‰¡ß6¿{a¸(~¿/ü¬wÍîşÊ½ü¿–HZÕ"?ÿß#qår×2KMJÆ¾¤²Î°V¼Uù
»™D‘’ÏïÂyŠR®¹¶8éS{ıé:µ¡pUƒ=# uÿ×T’Â"¬O`DÈŞ¦¶%w›÷UtS ”µ¥öX¼9—7åWÔêñı ±ïãì?2o(›'•!ŞôGÚ§«°¨Á•ú “0úúØÃ›¬„gÀC•”—	Ì•[8oÿÎ\^»©DÒ©¬›-²†„‰Z:¦YÁû@8gó.R
¾‹N€PRHøÆÌœY’ˆtVBi‹–SªcJÎIbòËıtÂ„Êç¸F÷CkXÄ¢¹2*dûKò¯§æ ¸ŒÆ_+]ªúªTÂ×Iñ¬¹]eÔ(^³ô£hB	®îô©ès.Ï:Šò–a`ÄQmc€ÓÍg1—ø¨ã¥sËF@ÈfÂDÎ>»pÁB£X{Û,FÓì"v.9.&ê•
‘±(Ø÷£+Ö'3p(ÕÇä°dğk:>E¶Û
÷ØË'd'yGÙ(ƒô¸‹Vzt,i.œ
xs2É¯NVrôš©›d¿ËOyÄ9dGh±ÿGñâ$#ÿñHÕmZ€UØeVôë?b¬€…7ünŠ­ëHÊ©çß9Ôd6Âpô¹zCMÿ‹,àc¿ÙMş÷q½š5¸é"ÿ§ÉX¡·pwá[)gèì"]1æIığ9š”†½¿ñæ×É|6î¾YÅf—·´ş1š9¨œk|o&Å_¡ù8Û+Ñ§-ÔUÄ¾ô‹¾(÷*ŒöÍÙ&ùöò"½6 yå
O.á!M¡’G(ûŞ¢¸Ô¥\Éjæ"¼fñnÛpU`uğ]ëTC&èÏ¼“ŸŞ,=&ö'H³åÈ>zìîûÁX*äÖE{ïqkW«ŸS4z ¶…µuÍ€—Mùˆù¦dl$–8ôÔUZm%D•èÓ8WE}WzÁ4²XÍ;¾š¥TaÁåqÛÚÒV]1~v£zöWZßÔ‰‰ø..˜
4µ{)¤Tø±- ÍÓåõµSwQŞ&ßB/j?a[’äD¬yj×&]¶(0v³Ûê#TÁ‰
ª±À;¬e¦ÁÕRöj:_Lß)¥Ó+>éSU¸W7Î9÷£2RË]”âªàµÁë9ş4]‚~Y¨q
{GõášOx§Œz"{¨¡Æ!ß8GüHšv…érÄá§Y[ì“RÛå™pÿ•ÀĞ!ôî‰+y>r@¯w¿†^G7	|`†ù©ÓZˆâ0®ÿÏ†Q|(ı˜súxÑˆ€)_ó¿İ­Â¨Èø›Ş›ø4èüÈH›¦è‘Bºg(aƒuXgi~*ïßüí¥Ói<Ã‚p÷+í^®9ÚUKµÆ>vëX2/ˆÀØæği=8ös•E&©¹f>©'½{k+bB÷ÉYIxÁÈ¶ d+ÕŞèÚ„Ã¿}YL Ğ¥«Û´R½‡Ç¤Şç_5æ.í­²GÏ±‘±†'„% P ZÉs®•¤ĞP‹æÎÜ¶èJ!Äkõ…Æ™`aáŸÓæ_y¦v&\ãb#ŞX0›Î ½æ‰õ«¨‘I˜f˜şi³'ñÄiRX—„Ç±Aöõ/à”k¸Œ/Æ9é	‘ÒËyô›öW¬Ä¬y0’…„C‡ñÀ‡xI¥û3‹D“ªSK^^ó´F‘“¼|ëôbÜv¸ÂÖµ/¨û¥4BåF-‘Å¶›Ìë¦¢Væ‹g&Œ‹Ï¢ú¥ïºŠ~’í<cÈ…îBÿ-Xz7ø[+ƒÖ'‡+£Fš;>Œz½8DæÇ¹å=éŸ„/9›6[Ó1ëø$èú_ˆá] ­ ”Î‰gõIœ}W«–Üg_A­NôWtœ‚ ˜5C¸ŸğQcò…ß¡¶óøÀĞ ôxiÍ8­5-œÍñ
8R½ô¸¤.«'k(iîfÚçÓK¯ÕX í[;×ü‚ûvØnxİ)±Í¡;ùê¬ÅƒÃßœÄ,4;X‚efÊ«ÑóŞ’p\H˜ö~.ö3›+ênÚÿì2o¡î
Ä 2LåÒœÛ‚x_ê§İÑÔé`bšì5óÍ=ej‹Gş=…SÔ¹|”–vØÎÒ*ÀG‹#ÿƒ–s²Š†i5à%îP,eªÉwª—–Ù‡
ğLŒÂ0Õ;ÙC&<ErvËßM€QågÖıÄ~@È}@N ¸ç`ç6ê¬ˆ¼,Yôø“k1Ôò¶àÊ[à²7ÖBèTs’>ÁÒ+hY´aL3O%^×ˆœ-ëé÷§uŒ1ìŞ§v?²Æco‘¸°M=Ï‘õòÎ7ÌîW!'érµ¢ïßnÂÚsT%D4×f(C—.-hß¡‹æĞ® u4 "Œ”=n™5¿1P}cÂù°ßê§A‰7÷e”*­©ş/A’ë,áQr æG	Ê­cŒnÑ&%&Ë$ËÑ¾zGxt«‡ÍÆz|ïÅlĞáhÇ¡İµĞÓì2sŒw)_S1½º‘¸|ä×.]6`6ÑŠ#
òNıFåzOC0#]Ñú'º¡vê¥qd™ Ä!{ñm÷Ã­ `U/ú@~³WÂb%§N‹ÛÊ ÍàÆ€è¸ƒ$Òè—‹òÉÆí=²jf’×â}‹Gú ñM£dáC'Ø¢‰a˜7 $Ş¯:6¾“4O<ûóûÑ° obj9=ì;Vê¨Áo‹¦ÌeK}*A¸Sûæ¢?´1
X-"r]>J-•N¡ÔÍĞä¡J¶™ Ó ÷p·BeT?½š´ğ¾iÊ0—qÏ›Š¢'‘tVÈ˜ÊŞ¦ÍÛUVÊULZ"æïY™@ÊNæ¢ôm@>ñ«È'b€¨°caª\>=†<¶Ÿº´†X”‰lõÄèŸûŞj"ÈD>PuA­†8' iÆ 1	4Rx£ÏÒg›²“9NÁí I¯Ø®è¸îÑvšÛ²—(Ğ¯­.xûrôlL60µ™âŠ „-Ï¬ òÕ”­-Ü±™qAø¼TÈÊÛ²Š$Éó8H~½oØN}n™¡-¹€õ3q+öÏ[²ì§(İk¤8ag¿ ÈÆ#ë‰W€Z(]E¶öõO6B|¥yèhÈÔAÇŒ‰®ôå‹+9]  uöd²öŸlïÄ>fZÛüò&pû)ŞŞ¤ö_šÌ.ÆK§¡¨¦+ğ‘{@ø{®;œ¡j§›4£qfœÔ^GÈ8ÿ3¸ )ò/áE,Öt¢’ £-‹“šm÷Ù¬4»>{¾¨¼…ÓôäGß©]nH¢=ê×£”iM{8vÑKÿV°ïš1÷Í4±·”Œıª)M‹µ;xª]Z\b´î°a„£¾ö‘ÛÚ_ î}‚¬ ´1ûyíaa¼ Ø>~uY?ÅI‰é‰ç£”Ú’£÷ÄŞ‚xüÔRTşPnºÍÕ.Ã•¬ğ_”N¾î‘Š…}ã]ùıS³¿õ>{çÑYÜv·ãés:T<—U^B-ÒRö-Áíè¢€í<šl¤¦u•9]ÅJÕQÊÊ»	kW0¥d?÷¤0ùmK(à?\ëO°Úna¼8kRÍE¼sš©ç»Š¸ÿ¶`”Ç±o‰·]”ÿcÃwk#Æöák_#ş4¼„YDH`~¶ yäÕà¢µVjóµOváF` ómùy"\Ì–lŸÖ¿ù¬0VIÄ¶Z‘)t|¶-¢°¨ù¹Ş£8-—Gœ4€”ã[&LrN^Ö3¸K€ròÅ›x°b{˜Áz6c
mU‹ü]¦Ñ¹5‡ ú$î®‰3ş`4—vÏVyQÛˆW€Ò »ÇKW6…€Báò.jm¤˜õ¼ }ÆvûAAD¯süÖ8˜yÿÇ0öèüŠ¸sz óÒ·¥L·%G»A§DHè£@ÃÃ~EÅµùZÒÀªc–ğÅjô—“sŞF¸áa7! VMÛ½x,AcÒ©£™¸ÿ Ò)X:ÚïgAä·Ù,UÁ:²w8€Bºå8 ’½)Õ£Ğ¬ èÁ€ÀQ² á±Ägû    YZ