#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3016456309"
MD5="6053ae71560b215b2718ed225c68f8bd"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="24328"
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
	echo Uncompressed size: 140 KB
	echo Compression: xz
	echo Date of packaging: Sat Jun 11 19:40:49 -03 2022
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
	echo OLDUSIZE=140
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
	MS_Printf "About to extract 140 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 140; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (140 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ^È] ¼}•À1Dd]‡Á›PætİDøP:˜.ñk;ı.=úm	5w”­0D‘_©›j¤ÎŞÃÀï½ö
Šï€ça5tşk±†z”(Ÿ¾èìÖ©şˆSÖ`ªù
rbÊ9À9r’™vòWW²–h¶.æ ¼!~½2$!­óIÒÿèÁào¸/£ôà˜CÑl~Ó©Ü¤ÌwfoæpT—<É€?Ä÷H—·°B·"”‡½9™¶‡Fƒ7~%öi\ôÇ4êá¸F"F¢àMAkÒê/ÍÖ½œÔX( „<_XLğ-Öz¦>°„‰D\]zk2ˆÔyşĞg%g§ˆ#F@´	zÇ‹Z°)©œÑ}CƒÍzÄ?`Tc?`ı¸|ÃqYÎïeä/3F0¸ä3lWëñë9ş_¿~Ü»²¿ŸG4,‘¯zHe2T5	z•yÌÉ…t”‚ Ä¬úXk$v~TjÈ‹œı¹Re ;ÿ|H&¡×&¯¼O,Ü¶_›mĞVW\ôØ[dô3x#Ã8ãÎ>Iõéö”©Éø½¿Ÿ¦	rÔO"4¸ğ28Í½œ7JY‹¦ğNo‹íÀ··O§ÚHIoìŠCŞÎâ¬Â.èx%{SÍÿ9g¸³uâÃKH…šm·&?d
Ş~r¤¯dDœŠâç® ÉTkA’æ#§¨5Óèb­×lâtÂõ­Tå¬Dúd=õ „éCşªs'juHã@h^TuO¶T~kD¾‡ò÷WRêb1l3µX~¡}ææBÓN”Û>µU6	sks5+ÚôÙSÎ+ÜfĞù,iC×/w˜[âãCì7roÎ%ÒÓø NÄ€l4}Ğ‘íÊácx³màæ…ö¸9û‹E‹‹3-ª$—0¤êÚíÜºüñŒX>Šâ"j¡l’‰ğ¼åhœ­NĞ–³ôºy· ›šßaœ‚*À*¾.«î}˜d-èctùzö!SºZåÙšşæ‰¤}Î‹fÂçÚMT¤­(&àrWõu³Ñà¯ÄĞ)§PI*,$•Ò®H§è1åâÙNß‘—‚ÉJpü*CgŞ•Šu"P½´ñ0ŞøëE®€®¥Ü¯¥5²şì}g ®¸„K,Ğom•mÃNEğ¬"Š3¡ĞÀ…7[^ïl¨•ık-ihKäfúS×ÔèÔó§ªÕTb7é¯: éæçÀ€@ËGÇlíŸÅÜÚ‡zÃØh5ÙÁ´ Ò8×»tøˆŠÍïn¶Ë'ä¦­Y^ÔvÍO6‡†HFÌÏP¸rñ¥w¨Û;Çïå³w¶úÅ‚Œ‚Ì©Ûïúo‡µ¿l¨íÃlÔáˆP ÄX68?õÆÊ]”ÿ´2^œ+æ£kZÇŞ›­$}ı¢¦Ôõ)Ñ\=&ÅR´Qèœ»D«„c™è¦óîÓE ¼o#ĞÒÌqÑFË+ê5ßóÑßÆ)§?XTÀkdÓX"N¨ÓôJRQ„<Œ­EŞ/°¼$œÎ³s¿Ä\Æ¦O{:y>àW¯Æ&øX#¤ ÷â„ıˆ€_İjNÔ¨&aŠ}„n ºHüÂ?\Ú¾ßÙM\’^riÏ‡Óxšº²  [ÒÇ3oƒñy¸·'º.'ÂÖœiCâøÍ!Rç¼‹ïQ¿tájJ *S=9&õgËy’öº]ü0ÁÊ#-‘§ÙÆyÙ@ZK¡ò'¨ô³.Ô4ÖígÔ”‡óİ7ŸW_{ku_¼öÜáÁºŸ]ÏúÎèğ¡û/,q¯„Ÿfø R?iãÑøË£Œpš;^£Lƒ:ıÀYÌ€¸Qª•.5ƒEÖ¡!£Sûs°Öy%!ê\J+Hâ[¹ù@yoşD~ÖÈ-Ö‘9áu^˜'X‚Ğu},pÛÅ
Ã’”.‚z}ÙğÉü¬Šg0Sl(*eHmö–ló\n¶ š€kqµ‘JÉÜE°c&ê^•úXæƒwÚhMucoKâ-;°ƒ|–Î)@ˆt:P¡¶®ğç›/K„z’ÒÈ‡îğ äÚT ‰ó¡çîMVÑÃX ·ÂÛ£âB…<ùæñ~7 İÌ<oÚBæŠ
áõö‡ğX4¶™¦¹oDrİé¶†»ùÁ%2®©2°Ê^vq¡É†-şR„OÑ¦:³L¡±æû‹ï%-Ÿ‚4kvƒ*İ¹ì&„äwù‘[Î€ğ’o{ÙéàÙ¡émGı3€~.¤zÀ‚æ—ìJ÷Sœº¤é’ò¿“Ñ1¶—m×O0-ÒHn¬¼®ŞàÃ0ÃRƒV·;i#9tñãRùE¹õü=ôuì·VíãÇÃë¸ó+¾&]{+lÖ‰šaâTV;ñ­èoÒ˜4ì'qB7çikTÚ"ú€ÓŞ–ÃvtNI’ÕÚ\ /a7¯’"§éÏŒÌJW;ó1IdÜe+’=·u´œ}iùÃJ^Öü+µw`«Êx
ÕtÜPgB_Úl"‚‘¯L¼  †dP¬ñ±9™BC¨R
€/˜¯×ÿË‹y-ìúK?ÿ]¹œ´Û"z=±¶c8¶ÆÓ²İüŞ½	‚÷P¤vï|Ow'*óS~¢“ÜK‘	p›b"ş«“b¿õÑiXv‘kºş­ótHã9Œ|á;¢õ,J´Â·)ÁÜIíçÚ:Å
$'döÓÉá{´¢Ù&4È5úGAø‘.FqW[¢^+ˆC:Z”ky^Á¨_È§2Gò¥}©‚H Û#ûŞñTxgëGc„0åeø0¶Ytû<ö`ÏøÂÁ{˜²riÆ	*»ı–„¸7ú¯1$İãp~8‘PçĞB&ı71¶c³ÙÖš•m¿²ƒMİøÔï0cøE^Ë¡×:.]â@eú%3«ÊÈ'Šç²=E÷\Œô|yq˜¨›w5Š
5ubc’>§b°‡î4Ôš‰Í„­ÃÀ‘^Õ{J…õÕC?¸´¿ÔRM±ãâ°IJÈ Ç»ª(Ã½ÿòp?åp^ƒ ÊßXI‰†d’÷ŠO9ÜŞ·6Ş·rûPœÅë8Uºƒ¤å/JKºåå ¦[V
 .{+-õ$4jN”2bl¸ŞD5E"Ê=ÿÓ5ºF	¬Dlûš®Ò[‡xÓ‰&h‰DUù…$ô¨fZSÀËîi§WÃ³£
MÍ»«¿®¹I)a€ÏÆºÚÕ[^8±ÔX ‚¡åÌ½ BëEœ _C8OWIQà÷_İ¸0:‰çQó‡JôãYàòÜÃ}©¶Ø<‚¤¥wÛ@!ˆèª À„­ñŒÒ>‘‡¯Üğ~ú`Ö±>.(³'y¬°+¾´ô\9­ŒäEŠ 09IÏ&Ë	FÚ§,+€Ùw-(óg8àK|É—V†Ûüz˜ºas»9FKubècCSêÇeyåCU.¥ÿ½óN]jFmŒ±c^Å«ç“&ó£TU@_£ ¸5"\=¬$ ÎëìcÏá>
Gµïw³îı±kMŠj¿tó!¡(u‘‹D:(ÄvÅÒŠ!oT•ËdKå˜§bÖ×$cÊ‘ .6_§·æT¾>àˆŞí'`ªõ\*€Æ­‘Ü²4°1÷øƒæ4)ÕZ]A4‚(O¾@6By )wê`£H'_¥ìc\›1ş*'ó t"Ï]0öĞXâ÷00Œ×õ"½ì[±S<¨˜Øt®ê‰S½naHttİyæ*å˜ªÔwâ´5Y¼Ÿ{4/
™Ù7Ğ¦Üw-RØùçä±äAàï+›©j&Dæ"Ê'7••€ôBaÏ¡¼.ç®/²SŠ‘¥™1Ó˜†6WÈ
L/î—‚Ä%¼´:éºÁíeƒ`>ŸbY?G¸_€&Å6öß]Î.Ş³¸—ºæŠx«tÕÍã¢XuXï„ÊRƒÇ	?ë2äÿõşÉµÉ2®:…q£µö6-`Tu¼Sí×û¢ªS
V<X·iˆšß÷W“…jukÌâŠVêëKTk¤G5
¿QÆ ª|€iŒÂ ƒ›WÈ›'Óîˆ…û’yl-ïr2£©ØiêıLGõ#´Sw7"tÃ×Ü ‹\R_+jÒÎ0]_Í\³—¢Í^ü~]ÚHLå(y9†·¦ R>$^„æÉ’‰»€bln*Z9B›È¦&ovKF¸I¡?Î‹ ï§¸»À^›7LV)ºòT»~¿¬¦?ü-EtR¿OÙÇ[@#iÖ:c2çÀ+õ²ìÎNœØ*°6­Öå‰ÊÅ$Ù}dô4E¯ì‰D¡ßUİPîD	ìÓ¹¼ÖŞuôwÜ†¿ò¶Èõ}j·íäŸ:Rìš]¥(B]åØxüæ;@?t¸éâ¸tS‹NÜ¸n9ÆóÒ[İÎ¢?×ÚîÕ'ÄÖš "Ú9ÉG“šÅ2•|eª‡‰ZÜw&•$øXŸ™pFAÈ¤ŒOVWÛˆ{ˆ‚®óÊªa/BÎš­mÁÑ&WÆú¹¬÷FÓ\Á˜Ú¡¢Œ‹³e6ŸîÅÛg¤‘_ïE€­õë)¢Š×Q‡‹ÁèÓJ"ôü¾VAuc¬Ş§j[ŸŒg|‡©ÄÎN˜›æ€úkh×+·Ú,ı°ó7a^k;òM¶ZKv‘]Ó±­›v–â
~YÌi¢KÁKH„“Hº&(õ£»í¹F6›Z©mıÂB‰Xôv™Æ†W•Iœãö Û NFT5­ îù{²;Dsê:yüéõò«q‰ÚN©M¾;$W¦»p.bv¨0y¬ºÄ÷èú†$€îĞfyJ ‰@`ÃæÜ\ÈµµNpVÔöÕÏz_şé…3ÛZds;nRUyô=vÈØ$I<óu§ˆg{Aî tÿ²²aÕH"Ç´
¯ "bJf`zKˆ”`£CaD!PXbE®¿D,!¨uawÓÄ¡ñ#n>í!¹A3¸„
Y=©{8šÏp3ƒ¬9»×
Ë*€èÏ1¿	9’¯Æ	—?Şq¸ç.u(©üùÕšÙ‹1ËVyÁôyÿb¸
İø{)hÌ£›ÒæÒäÕcß­»ïKTD›Âúà³TIå¿úEV ã257©¼é¬"“ÊŒóÁ˜¶or–49ä³Œäˆ„Ri“÷^( º±D;™0ÊceO¥Xíª‡o¥*ï¤àÿ%H`¢µŠÃØdb{<œzF”ñ!¨Ø†J'e0½NS;M ³µÛ@zó} ©s½-†e”ƒ›ÚEm¿–¬Š$Œi
»K'‡bPídô&=¤Ğ£RZŠ`ÅJóu»ß•$8,é{çè¹'Ö·/m’ÖC	Å«İ×~ææ¥IÃb™ÄÇ8„•?¼hÂÌmŒl#]€ç7ÔÆbYÿ5Ñ#ÂÂÙŞİ“ğøA(!s8~Y—lzí!%ì05C0áÃÃ™K¢1®›lO7k^¨FÂùx¶AH¡péqu™¬‹ß/©SZ\U˜vÇL `E{!:xÆQ°²½û†í[g3–¨9‰š«ôÑ—Šbï‹“½Ÿ{Š•şÌ×Sé0F£êªCoİˆ[ÎgéÈ½ò¬E62İÏ’ÖXÏiô,Æ¾İŒSz#Dr"ŠéÙ\º¼a°µ³©Ò±¿8äPêx'ÅÓºEm
rW [ªÇI²¤ F6’†}¥©íE`3Ùº(é
µ¹Ñ&ÅêêŞJ}`éÌ$I„UmbOÚ0òÀö­‘è¸Õ€Biw;0¾wÊ`O¨Kb¾c@eøß¾%‚¼½åDª›#%KæX	)‰*8´G3X X<x³ÕØ¬Uä;uá÷û¶äÉg)Äº ü)CßÛD¬mã¹ŒJ(
òc
Xä'®öƒ<ü­07¡E/\Ë€eDUápßşÚ}_ßòûûš¿ïoTÌ7Ss"Ø¦¨ë.¥±B!võÎC>:™Oƒåğ„`\;Pù¬.‰S©ik‘™µMò°ÆêDŞÇ—K¤Šu ©ŠÆc“šÀuJEe(ğ)PìÖ(må—¯àqêß˜×ˆa Ó|À
¿ò°ŠhÀÉE¬MdâÉÄ€+ÔzprjdõáŸ ™20™Å¬z{84áêÏWÚì†5ãÍ™Ç£Tfñ.ä°vQòıH±²7 `,ù ŸB;6"Ğy‡ëyt´¹¨æ¦Q¨è÷ß»ÛgÉğ?¬Ò¯šØ¤f®CÄ?øóÎVŸÛE·½Ev´:tÙ©î“?#f6“V2òšK8|Ò
‡Y<+qŠŸˆÁç'eJ[pÁÏÈ¢(B–±7%òäıìîÖèšæâá}!ÑœÅ52¶İË ‡(;Á{`˜ÌUĞÓ†V.c7•îD£ø>³Âò‘ø£’È2¡ó¾B^ŒOST¯–Ü´nì€ëÀ½á·¾r-(k6!¼d¤ÖüÆm`{&éZ_´hé$Tp–Ì4¾[Vfqmzq÷Jù_µ‡4šÂëş8].}Y,Ìumjø£IéÊ®^k…Á¥Wƒmzä…UØÀ0Ø”gµ½.ÙææÔV³r HÊk¨3ïKôó#®DÚ¶¹Ş\ÕááÓ5aíÃò æVÿGC| Â%¤`ÖÍM#ÃwôŠº°hë„3†7ôi„Aõ¹ÎÛîÍHĞdŠ·ÆÁFuBEô÷~bëÉø:DP	Üó şD\Ô6è¸õÎZM"©‡Á%Q“¿tOYqhEõËÁ}ı3[½I8ÆÎf÷­–ñQªÊZ?¦¸};²Ní¼±P½ÃR&SÙŸÏí İb‘íÛ1•ş8z™µÄÖ¹5¶çk€a¨fJ„¨t0“|ìwùî­]n@ô±½Õá—t§§_6½ÅÁ*–M·/ÙSlyÛTãxÁPòp  z—¹è«,ş‰vµ7:«~´+?:4›³{&_×éZÀ@¢wC1ÕMõ¤‹Äöz‡‘ñœ¬Ùi¢q°QÀ	:å~9Å"o¥Í[Šm‹ø¶£BŸ¾{Ò,nÂñÊáı—Ş–/ígô˜Õ‹{Yé Ï˜Şªt6R|ØO4æÿ/ÄÄÀù>çH¡>”iK*Y‘FnN·hlÂ>i(~cû¤U˜Mşí’ı+
Sè–¦œ’~Ä³“štØ^ì0W/hYÁ¨ÈúL?è{Ş€ğj¢îÕÆjNŒQMEsrV-Šô,±¼ß‰ƒ¯‘P‡$ì2‘Ê5Òø¸|ïoOîî f¡ª‰j‡¬Ã^w%ROs8˜ÖÔ”M;Ò$½ÒGî/µ.w,ñ„Ù”-z{pŒí½´kg`•‹kïÒİD¹ÙégZĞû0Â¨
5ºÃ_]B…§po3æ§ƒ‚…æ[ëhÆ±8ï5ÑFğ(-Õù=½V×î‚ÉE¹Q’qT$bµe»†È0AÍ‰s1µŠ/vô»TŸŠÔtÀÍ¶Õ<Sù%‡Q‹ÈkûpÚUÊıY ±JpÖ¦«ÿŸïzØ~|8ÀPè
õ`GI…»çƒ/4<˜´W`¤Ö¹¦)Ä×g/zâê‹ê¾7Ğ;¥ÁyƒŒm«g“ï‚Ìî]î‡“éDU~1d‘«Çô»|ÍJ[|
'Ô\®y3ş¿;¿ç¶ “†ˆ¢*·õÕ·¯7eçÇ¦£^¢ˆæ%W/IñyÛ€ÑÏæ‡ú¿.»^`¹ ªîUğaÑBiÒù3¹çP˜ Èïç#9X©Õl¤F&Šl±%63–b›ŒE0÷H†ƒj1«"§™Åt˜ÓÍ®.¼&ÊPÿ?ĞyŠ·Ò
FÀ8ÒŞ…dC—dC«AK¡Ğ–œ¡TÁ¤<?^½-[“£†ÌñêæÑ/Ôä¦ËãLş]3q
?:t(?å‡Äc8-	^néDÍ“ 7ô‘nÓ¹ãR/9¢ş}‹FŞ€a]|¢W™:wZÔó0sâÓt!™ujÉ#À!d$ Œ {çÉş*"¼+oR£©Øš­º§ÑjÙ[7–s¾yôT\Á]ã™±EÀ§Šj]SQ£¢÷ª9pÕü…™	‚˜è{³°zİ¼Ïé%2b/oäyB}ÖÙWåÜVcé+ªZ¥è¯ÜãBIªÜ_õ"JCY7£1;|Pj„Sá—n:w<È+Ïõ…VÀÿQwiÒQŸ_	İK,ßÃo‰eP«î^BœPóiâ8<e ­İu'ÖOKD `[áéÒø7¿ ~Ú‡å$ĞI¶š<·DÆFC§Ô:9Ÿœ%x’îH$È˜&x6ßâÔ÷ÜßR#N1ê5'â.`/ï5VÌ°Xú†k{y,BÙÇ3me>Xˆàä‡tYŠ—ÔôwS¸‹q±Û10óä¾xh’~b4Ä"V©øBbÚÜ@5²ñ15C`Ow$dÇĞàw@.fU^z
©üHÏ·ÿÔ‘`Àûå¯}‡øø(±¾
X×G®Ú¬Ÿ¡·ÃĞR@%o+$¤µ,½ É?²35¤€f [/T "™µ>nê™%òmùğ»d¶kBî- €fN;D5›ç)pp÷?fêƒ}GûŞ0@_±V1ƒyÚF4v÷Ÿ+ ¹4L@º)L*êM“55ÀŸfÄÎlgÌÀ¯*ZÔæ« ñ[ÏîëºiUˆ7RØ…0YŸĞşÚÖ¾A=ú¬PÖ¥
µECÈH’ØïØ"‚a©e~Ü›/$V´°0<°í*hÂ"­¢ùÊ¨ùaŒĞŸÛê”CöåD‘kµš ±bhj=jİn¡g¿ll|øÈŞ­¡wäj áPDä/KâíÚôÕ¦¬N¯k ÖaÿµB<Y“–¹ü¹/bÜ†¯¡H¾Ê“x–ĞB/û²³°SíãW˜²ªu“	£ÓZšâŠûŠvwmm6ù§[éõ?Œkœø¯ ¢I<ˆº°ê©ñrg<„±äˆ®£8Ff˜Ø?ASö¸úı¤HÉ©™}¾¯‰)ñ¶	bI#û4”FÜT9i¬œç÷óşv¬»à_ø0¬løK îËJá®jmäÔ	 D˜(t	Ôx5	‰ä+ö B&“$3Á½Éz`+ÖU¶sxœW3©™£NÂ|$“µŸÇxa®½àú\8ˆ>ôƒ`éş¿ ÉºÿD¡ FFØ¬şQÒæD´Æ°Ó»(½¼RN²xQ€L&œØ=^lbú¸»šß›n¤îW•¼kKkÍfK	0şT½=×H
#˜ŸQfæG‘=öŸNymŒó'KL'^Bñ¬ßrÓ7·ÿ|Ó‹éÑ~)÷H±’¦[
`ü¦îNÕ=ª°Cq¯,
5td4÷‡É…J"ëüÒ³Ï\†vhJ€ıûÚóœı!Á;3ûrD*Ä‚àÕKdEC÷#
àuÔö æ¡Ã[ ¿ä™>µ0¢ø  °	Ë5é`^v“ËÈOxP…7ÔI„)%o=©Y5|ñ'ĞĞÔ2Çõ¢HxUèF
c+Ñ._µKŒtğ\6Oµö¤Ù0=pcF!Ó^3øï$9á›Q)âÅ;æHÕ’ÛùPÊo¸ËÇ’ôÍ¡Œ—á˜J#²M¤ØGoÿˆÙÙ}“k H{›¸§öó|(lıv­å ÒĞü“{Òb™•å­‰Q˜ò+ãn-´XEĞn'íM2”*N`¸º^¥øÉ¢B«ëx×Uxµıº(\Şimê½ñ|®Ij[ˆKªÈİQI“WóÿºÄŸ´İ€‰¶’.¾İïŞ¤FeÓûB§'”İÚVªTZşƒŒ
¥……é~–sÑšæŞï)í¨¡D&ÇxqVvõÊÛb‰¥õ‘ìî/„óWÁËYTñdi²)˜7ùåNuÈ‘…şc-kaÃÿ6ŸİıÕe3Ó P–•Lç÷xìÒğEê¬ÒzÙÒÖ§É¼°òË2mçd8ÇgYÒUËÛ°aïw±ÊùR¿ì\
ÿ4˜=<“i³á”v>·•åínôñ2‰„+]2ùœ` =ËÑ?¾¬~˜Ô~==7ïúÄÇãRNRä¾÷&ÉÑ@dƒ»"æ—ñT¥h‹·É¤„jë!ŞÖ®¤	aÚ©¤ä„(ÉL@È'Uu°(wm1–A,Y·a e7ïÃ®|w'É2âë>gõHê–!àŒùŒ,<UßãhóàÎH—Ì˜:kÂ;6È,:ñú¾Ñ2¼…(£·,+JùÔÎ”$eÒœÀvŸsÊ9£Ñàm'6MH€ÏÕCÀ/é»&Ó—¡úª•Üö{"#äÉÖ!hBj¡6ÓTµ»c~ØMóƒ»îßGMàU7ş¶‘#o0?Z2;ràbUªíâñøºÕ{v´R“ìEfNµ½eÆÀz,ü´:+Û5İ)%¥˜—Ã–û¨zâ­ş¢oWg»h•=”ìmÿ{„ÍòĞ(ÉÀ·Ñ›ˆ1‚ìPC&4÷T4™2øSÿ{MÜœÎXÌÌ‘¹äƒ`‹­nD/ÉTKÁÚ…3Æ‰ÆÈÎõKyŸè²½º%· g7b}F^	•‡ºjb˜“µÅ5S%™g‰~bØA¹…’i-ã3û“Ôé:‚Üd‹Âh…öaS¾x¨%Şß¬ˆLíícùŞôüè$ÊŒ¬á³Ú8OÖ{ZZ†ÖÖ€óĞ Nm¿c±oÏÈJó:4¿Ç2yXŞu+__´Ô@4:Z`9š>ø
²|ë É3Í>I¯#D÷3Úèïmuä6Ñ¦ˆ†
¬ªU¼	UwmaÉëøN2³`\EºÙÁ²U…ŠíÈÏ¬k–5wi¾]P˜èà+¡!)‰i¶rS6%Y>u‡V3nŞFYØ>ôÍê„Ç\¦ ^
~ó‘mÔÁPê¼3rRÇ&CæÈøª?XËƒG÷¤vÙ6Ì¢4¸Œ­î)¸0Lõr|	.á-¶·! A†h~ÄN¤Ÿ ep €Ûæ+¾‡»³"±]GlÆ&¶èp¸n,Êrõ=÷@ÕçT•|ÆÿPWL¸MU×ñMÍ)èæ§{“¹#FÜàÊˆ€KüĞ§¬H×ÔnU*·}ğ¬JH8…Ş¨9ı‡®&¤¨?#ÀAÌØİ'Hâß.ÅNLù[h*ö‡¤ƒ¯aLÊ½^âÌIïÄ	r8s÷r¬8+,4Ò½O`Dƒ>øîù¼rîÈ1W L{oÇ‰êš¹§£ËÂ/]=jÛÒB;½™`.¹qLğiúƒ[Àh¾ªZñ ¼-hTgmì¢ÀìêQxuûY¿Ë`sÛ‰ÏDi€íÂ¥æôHn’÷Á¼»™'C×©•ª©Õ©†ÓÑ¼˜ää4)óİL|Ò²¡ó±È±á0ÂÀ‹ögZK½øÒ Y`9Íß¹ìE38\ÛÀËÄfØ¯Ç¯ á™Ãià¨KİÂLp$E(g 
yÆkø4'â¬%cæŒıü_(.	³ŒÈtD”¢oëc—	oV}FÄ']ì&­®ï¾.ZO¤.…ò;á­Ö•ñ(ÒŠÓUêÎ?4¦="Mè`¥A`tô6~nëfâ€Æ~]â¬ËÁ§îx-ÍÓ…<ˆ]ıv–»nT:©+Âı‘aÇ›ìVä,ÈMTV“¸šUVfç¨[]|ÙßjC­ë4a_ãàğãğ€àæ¤ÂñÃãi–xñöñK½®MYC”~Ã]x_ÃøQ-?Ğ¾pSUÒ¨Ğ‰‹,€fÓOsrfH‰¿Uét½ ê ¨¬iEaU²P4í¶–4êôÖS=’nÇ…yzÁ/í¶Ê‡wÆ¦j÷4MQÙEæU°$¾Ë¼ğì	œ ´ÛÁy5í´„£»5²Áı@¹?_›%k¿+kXMŞ`|9Gt;Ì«Ù-grÚ‚aÌêÀ,í~ö‰¬á¤ôƒ aıdöX@Ó>7}>™ÏŒœÁW¶‰.$G¢$J§TÈÕ=¹ ùş,­qfšã
øõ–³"*9dçôúe ³x„ÜåìpÙŞärŸ9]ÂÊoHøY»TK|÷ÑlOh²Œá‡ò“¢ßÍúVl¾ÈVhd»
,¸†ÉÈTéòµsâ0Æc%SFëıé©ûn»Ä’ÊU$áŸ†‹KùWsÏù-'‰â*£W);¯ª9;à»ë¤„ŞT†awE|°…Ø6âô?ÎÀFgÅ<ìe×^¨èWdøša>¼ÕdA[€FP+d|FÜ}®^ôÒ¡t¥²FÚ£¸ÿÁœÛª¯yFP™A4»³Vö‰V5Ü37ç [	?iquÅP3¢¤ğ@ÉEŞ‰óÎ¾µş-Ğ»?OS>ã\Ú–„*õÀîó0öƒÇÖ¹œ€ƒÈSÏ «P­!Oµ!ÔƒøE:Ê»©˜Û7¼†¡ò^7,|æÉİDƒ‚R{ÉS“ªâ|0ª¸¯ø9ùt`jyÇ
 Ë­dc!	eç‚š)@¹j,ïÜò×§Âx÷I¼ÊÎ’.Ud3hTRA y%g­Û)31$–L¥fX,^W­('tD~”Ê¸P'E×l‘.‘ˆ¨ÕüâÈıª­r]_ØŞÒà¾vU§»MSë±i2éz(£J07ùxfiG…Tû€Ó}ÔT_Ã­l] –õ*eÙ7ª«Lék­‘_ö¶h›"Õmä8‚±8¿š/å]ÈQhå€F†KzÌ™ÃXAÎTÖh™P‚±õµÜ‡\fšÛ‰Ãyü¨vD~‹±îĞ-À£¬g²Ùf@¦Wû‰H®Ÿñél¼Ÿ¦ba…8?}Ÿÿ	•7ñíQÇƒ^¨ú7µwË½×%	‚=²Ü»—õğiIL”/N¥ìV"ÇP
2¼r$X¥> `ïŸáLğ\²Æ°È3üBxÚ`àç¢¥“áUğ<zß(ûß¨ùóoºšg#’VÆE~F]õG‘šØ+Nšì¸¿»ı}5‹)qı£ø4‡†s)´ñÍ"wQ§¬\|ƒ¶p[¹–ef}—v	|DlÓlH*áqŞÑˆ°'gV(GTÙ¦S¸Kó£Z§»c	s#·ìá>Ãr‡²Î6@é%éŒ6Ø­¼èĞÂ³ˆı‘ö**U¿çêN$÷ â?löêÌ”ëvŠnli×ùÈ]°/$ÌQb|¦µ»•ø‡Ÿ^Í5Ê™Bf‹fÀ}
œïĞ¬0Àdõ‰„uFlágØ×6'+¯x¦°5±.%€·ÅO@;³?l*s|~¢euR€wÜ‹]´ÓãSEĞÓª4ŠÌnóğ€ù»jFıdœå6$ª„‡¸´xe\¯E÷›ÌİòÒ:}şÍ‘{f¶'…á áPÅ‰ûD*sğê›äÚWñîar\ïO•uW¬°d6ƒ51­ë–ÚJ¨ÆËş¿®kü£¡˜›àAP®¶‹`û ÷-òõÕ™&q®®pöÛŠ±µ!ÓÄ‚'f²B
ŠÚQ•meQ TŒK/Ã’†'Fğ®
€ê`ñ´Ë? >Oœ‡övMQ›^TÓÒR?áK4”•ı«ôPâß-ÉÛFõ—lé}§[bşàH< ¡f©Çf ÔœH‰Ä„¹R‚C\Ñ–¬¿´Î-Û;{5•S~¯¡§»öù=ƒB€î¬=”Ğ2·r†ºæKÖÓ(EÆäB¿5×sº4ÈKvZñÎm~¸M®×ŒäbZãÈÛYµ8ÄR4C-ÏŠq‚lä€g¿!ŸD*†e€¶XKï,?L+‚—9ŒS¶a=Ô=’³ÈS*öe|~±KûåW…ë+Šúe\ªc²:z7¦
¥aNÃm¸Õ"áu$}ü±1Sb12¢şÙyíYä,—ãp¦ÙHZcÉ‚ÈkTYØt£îØÑMê¢²Kx6œP<”ß%y0ÿìeklã\{?ì}ã|Á&
‡Îæ4¼w–>­¡ñj“äó—YædX±cÕ‚îûŠ4WœBÈE fF²ƒ9ê†	]D•Åeï¥öëyŠírÂøËªA{Ü
°Ü’ÿæÀ°Cùz(,«¨31—0AlL‰íåÇ­z¯ë²8÷’‘HµíÙˆ~I2=
£ç´ˆ®0«î*·ép:ksFSH†¢‡ô_xÃ+Ë5"–yâˆÌ„YÌS»èøµ9À.³<~Y9C‘\kå~.‹]`&‘¡(â¥2äxOd_¯ˆÙíË%
W†©'‹~äÖl¹G¥=—ùC F((>§Q¼¡Ê™)Ùm‰*UÓÔø¡%`ÓáôMÈŸMñêI£|VMÕ`±"±¥ªôV%‰7üyŒ“Ÿ\ş\‡óïêUmŒl§
bÃÛ¶1êçŸMàó‰Ëíáq6"ÓÛææ¹¥©\MDÄc\}¯ı/şŒ)½{f+- ‡Èû˜aŠÊÔx³ò[±õ }–¶ÏCÂ¬ĞR®q‚Ò‡¦ŒÍ¾Œº¬÷“‘å×‡É–”av~}.<¤<³ æÚd¤’/ÂÍ`&œàÎn•µóÓgÚmÀN–z¯ŒŞ•Øq	Iğ‘Qx„YjÀEZv‹O¦ ïK‰¶»-QBô2‘ÁqÖJâ†ˆÀ\î”ky°¥íyK²Tÿ\öÙMQ|nh¼-:º[½pÖUKÅÕdÍôK»è|­;z«€QD-‚—€³#@ü/–ıøa¥Kfó8úE‡ë…B‹ƒÿ¥våı‘XL²¡³›‡³²-f;§·¶„;˜øüZ‡§ÙŒJh¶çüX{NìƒÜİEÏÖß±]šT	#ë`¾lò*Ñå&Ô‡@ÂvQöÖê™z–ò1G‡zœ¢ü¾çuùğV÷Å´•WdÌw àjmz”Å Ş&ğ²< c#xÒ!¯Ş5Ãô³{ñ@³oô Q[Éfï ªT¥ê­>g ‹Db¬­‡'ú%5^ŸÂ0Ô¶$ÄQxjRUø§§›µ—V&ÈÕåIyÃıv“İ‹™:·ü‘Ã7~EègF”¥
À„GjgW|ñ§ÙÙ¾î»­ÕÜ7ÔcpÆÌ\¥ÊBı}çjş
py qÆjšÁÖ7øæo¡Şà\/˜ÑO®mg»Ú\¹xL&Ÿ‡¹ò¶
j}a’î&U/Ì-ŒÈ/ôsÍäÔ@»b«M²6ëH$Á56¬Úb)½ªÖU¦®ça5,(k¶qÓšÙ§e£eHÇ±JÏ§ßŸ®Í9ÄeÏFğ×Xjê8ı]»÷¦³è:û§¶Yœ	lX{§*™iª©£ãwê“’ågìDÒß>§V¥ãÄ—D»…K,©„×á{ø):z5‹”#—á†OZ!¢½¨‡©˜K·º«kåÚæbfNùĞ¨ÍæãªÊ´šä¨üGô54–¯ù«õğWú’£l¾uˆJ%Ÿš¡ñnåBı])š/wä&*]ı x´˜Ì¡¹süŠGxU-´ÈØ:Ã?’ÇI;ª­•
Ç I…¨!‰(–¸ğıZ™ÌàÛ!åZ_â“ô×RDÅI2UytS¼ÿ • QÕ¬»pÔ4ÄEê"‘ÀˆfkqœHÉHXCsóaR¿"½ó¹ãÜÆF	|#Kºğ“Ci¯mX,ÁÆ„Íêî2¶ñ×ü#¨ĞB6sJ0íTĞİVÉŸ‘îöGKû¸±ß„¦Ù<ß‚eªwßt)CM`¶‡€JŞ#®¡äj.ç–µ^¥Wû¢äÜpÈNcÈØru¢ÆPµáÆIvX’„8üŠîoUÛ«¯¡EèÇ@š'É›²r.º,RÏ!šŠÀÄ"–b:³Z´,Üëq6zÑ|²¹•« yåmQ0ÆRÙ ·ÑOôÉ íˆ“q)2s÷+ÎMxDÿÂÍÍ~ÊNQí»’ï8ª/q•+~&‘ÆÌ›Ş(áÄCØ@Ş_jêˆåBøÇMŞ èî—Î¥ˆ%e`„ºS­zú$î±ÂSˆúd5*¸ÓÄVóP.â™=•M=¾Æœå¾:¾qG»Ğ‚„ËÚ„@Ã¿ó…5¦µªB³ƒ%€v7ÇÌüÜu±nƒÒóÖŞ ö—ÁRD÷“7lRş4u;¯¸·Pgø±ıŠ¼îƒ_|†’µNw]}·›êp$@*8š!|}kµùğá#‹Ô21Ò¥ÄÅ\p¥•›¾1Ï5LàZ¡ŠÉ£¸qi£¯“4˜“ [şQRf›=H}Ş/ß6ÀwÑ/Lzz‘˜Çë+)áŒ³JƒT›É¨bPòxÇRÚ»ÂmQ£3-à<^îùvjÑ•ßE#*àì€[õÿ£Å¡e)Å9xçìVµJ< D˜E¯³´×ÀCû·zÍ]pÖÑw+%*‡"€Õ9¥Åí¤<óO’®Õ;]6æé»ë­Ùé¼Tñ¾hŸş¿ öÄ>¸]şZo­{„ô½$j’@'‡/¤F~å :îYƒã~I›6İ·v{9œt Ë¤0±è{m±Íj¸à%ú‡ìÌ{‰ÈmW"Ø£y¿<ĞMòÜ°™KµLqR#3PÕ@Q”œ8¢`^\İßG„ÉŠr5ê‰-<A¨Lí)mAÎ,ÚèË9G"›,­Utş’J¸'…CÕShxÒÏÆA“ç^F·º…º›uùHƒºgY^“(q°÷_uN¤ÒDyE ´Œşç@*<×JP¬úÉ~0 C:.@¶t
ÂYŠ™µOÍ¥L.õ¬­ßpØ¨ú%ïDd dPFùë :Û-´öîıo<pùÁ`8>ZxjyÖLQÍhieX44ÛìË]‰"öyÜã,ËÈGl-ëhš=±W³ROÓró5²k®„%„zwÍ¾¿ZNÈ°pf6ÅZÇYëĞ[RŠ]êÑ´£ì+_‘˜sÍ¹¤?/~'ôFsó¦&¯&WZŞÁ-à•rÛƒ9R¿¯ò|¶s„tæ<vÆ-˜zP@{º+S&öX¸W°÷eÄãâ*!›]^Âè¯„0|Tá¼WÕ\ 6sÁhÑìÓJ…ZÇªbŠ­LÃqşv™!t!vq¤’x	7äç­÷“TJl1§¯Óù¹®Ÿ^HÒ@ö£–¡Z¯A°RlØX#é0Lw~=ŠÚ*–Ó³Í ÿ7']W”viœ·§[eŠ¦ç iA {ÇX§”]Y8ZÀ°«ëpĞk½ßÓ¦*Çê}st?8Ÿşê9ÄŠN7×“ü·V±£/çéBïœr=!Û+‡WXKë²%Ù@‡(ÖHÎ[Hâœ
âEë—ÅØ´cH€x,½od@4	ÚÍ²ìµ7PxÀ
(^fàëF@Ù.ç‰ZÎ¿ğ=%íŠ+|©Æ¢ëşS³8É×=¿™¨@ß—gZ
ı<ˆièƒPøÕ&_½O¢*Ì‚ÁËøßb3BÁè„…ï×ÍBvC/YùPÜÁOé£¨~†DTÿì<×—ú³º ãX4}®şélØÂ¦JäPşg ‡¶gGï;A»Ü8›^±egüe
^ÙÛ\-1y¤kÒœŞrô’jS.gQ¬›Á€ÂC±·•Cu‘/Ä¡Âê•¹A¸ Q¿¼Mç*Sí"Â!Ğ=gFU.¯Yºr½ÏìDx¡a0ˆ¹Å‚UŞ<Ğ®™T_ğt|Æì9ió÷Ï÷SªV¤ø9r½gp¶<™î[¥[şb	3¯Øv‚J;O‹§ÿ}*„±©™á‘ìÍ9ÂÃP9¥+ĞsÑ	<“Ù-}'AßQÚÌxgK$Š€ ´Á(F‡½<Ö´Êfóí/NH9j4Põsú1i³pof¾x-q8¹‚ÇWôÈ>Ö¿~e)4›8¢Ö{ÇnpPŠG­ù´gÙ6ÔÄÇr¯rÌàú"»¿ÇÍĞn…½ø5X£U³·Ò‰ê6AÍIÍĞ*ïef'¬ªc¶ŸÅ4å[ÑØ¥R¤÷0¼å[DóéS_®—ïÖî¼«¢EùDIÛıM/ô™Å1ái³M°Ò{©Ã\°©2ÓÛg)0´6DqÏ³x	å¿ç\MÈµl$T¬¿=9ÌÃÉ4ñÔû½Ş‚Ïƒ…5(.lÆ.$XˆÑ²»°Â‚ÔŒ„lîÉb7Ÿø­9İiŞÌÄäIjØÒq×½„4T„ ¸a_D¶¹ÅÔå~©ó€4K«`#–^G.ğrìÌY‘<ON,P­éœ€å†sú8 è¢İeş¦“]‡FÊjÄ*A¯0q!NªIÜ_ø•]TŸ “ïNÏû‹–y·Üş^¼r…©ç‘Ooã3ÑÃÙÕe@æ}ß-T• ÍEÖiRØÂÊ¶Éß\ÜÇİß#VÛ$IƒåAMcÓİ’À"SDldrp@Q>,•·ìÿxÕó	N´¯<~,’ÊÇua{®×Ï°_ªÂ¬Œ=ˆEo)Æ@·ï§$·Aø`¥DM)–ísZâ$ä‡ê8Ú±€‚B¤t?Uì<“LõÊÚxKğ˜0«+Å?äiäk{Éş:Ç_ù®=Å:G`Ò‹BxDP²ß;²ÊO·Òe
Œ`¯ø>²o@£Ïv{Ìğ¤šË›‹ÇÉ•……ù.†oŒ»)éŒB?íz£{Ë<¾ù G“!ë\	7ò¾ŸDİL©Ü«1I­SiKò€T¨†ó¼üşŸºóØ‹1F7{õ“Q²>Õ°Õ0¯Eÿ×g‹Ğê‡4Ÿ”ş&»Ò!·-öWµJ	ê÷}ìß¡ºøùşPê¤Ş8c»ËÓ>]•u=ª˜£íŒê6‘ëvƒÍB*É)¡œ¥å¼ß9ĞyË‡îÙî MPĞH}Â5Dâ]ÆÃ˜LÖ¥7_Cw[”
Ç\úè¶±í&¿-Ä‰°
%úøàf>sërÉ‡ı1E­¹}·[„è"®´„øª¢ŠÛ”m¡¾êƒİ ~şÜéuØÏW¡„f¢h8ˆ;+©¿iÕìj²^,¬DÓ-Ò…x3ÙÄ_Ê‡ß'º$ÙËîª¸„	O0JØˆ˜ê7æ»cşµ}Ñş„5)rº‰1?h‡-}LŒ$³™Ø–äÅzVrŸ7¿í‚®róD ¥ş×É™³#§à…'mríHõµzO¸z+œ$ğfSCñÕp½‹Å­ö\(ÈNõËóAd]( ´Æ•XáÍl9Y÷CÓ'$'pº:Òzè®& §ÔÚ6òX[€ «’ıåm[Šÿ¹Í”À°°9"'İ<…³b®’¦‹Ÿ˜×áJVt÷ÄXİ¦gg>÷›ôKÃ¬åøä¸­«§h¶±aKá6ïÒÒ~p¡®O5ÅÓk?ÏÊé2{(–Ñš™÷sÎOÕÍÏÉ{\?¿ÿ9Au\,O†‹Ÿ´ü÷=g&|’ï‚Ÿá…º ”³ŒåÉóG¯ÿ’…¢çõè„vI(Ôš”ØCwXêÀU¹(f9Kì/,o–xoBŠbR°ìw_Rè}gÉğTş¨q¬­ö3¹ûä‚vÏŞ5Ø5lüôV™è¨·ÔÀ†öèá€‘Š0Ò,•›şVÛğænjc€ì%•³µ½"½]\w8‹r/¹Ù¾¸˜6¹”«@5õ0›k3kKÓ]9ø55â³A^­ëLa/|›Xó”ÙCËRôÕ2%Âq¹½\@‘_B¼ÛÓíX‘´øMlÒ4RúYC!>ˆC­ì@¨)zy¦	î²‘ŸÒ–%ùÉ¹ç(’Œ€böÆûÒæ©yÓ/‘Ë$ÖÁÔi”£(5£’1_AšRt+ínp*:~XDğ•ædh«ç,¿»ôÎï4EõUÆğ_#Ë½}ú~›s]:ÛõŠGƒ0„d­ƒ ÄØë³Ösú|†|<ş5™vØ7hî %®Éª9˜ùo!*ãf#Ã?gÅš:ÕW*×‹ô3F$R€!Ëõ¤4¼ñV<rú2LÁ‘JÙ‘­ø£š}[%&qPËrúÜ‹R¸ÏHGl8e×ŸÂÑp=Œ2êc¸ır!‘eè`Âğ¯DòyéŒ%pÙ^Ü/ö‰H¯OY‰o­sdÏ•Ûy§‡PÒVóşx}|c){èFî—lì «8ÃÇïíéé”ŒcCâDY¥l(W»ñªÙöÁ^afº u–Æµ’	™ÛQÍUÍªQ
*[†æJ„	H‚p¤”X Û$Ïoä’àu2Ğğ«bpÀÁ&Ôí|±Lêˆ‡|j+º“±ú¾IªÍïêH•Í iš„'	Öà¿û°µ2†^î(ZMŸ¸*"³^Àozw‘äïØ÷BóGì² ²GDRŸãJ Xæ÷Ğã‡T„í¤€¾I$)Pg¼»¤Â] À?\F|<;c;T”T´'6qL¾©z{b;è–ÏµÏ ZCn÷Ê
ñK,È÷©·ñMn[Á•®!ØÚQWZH°‘wÍåÂäJ¦¨fŸ½ÆIÔ:ÿ¿QNÔ¯|šDÇ—œT.í[ûs>Å}y ;ö@5™hIDóU†H]/º*£~„Ş¡+šY®MôµµJŸ%…¤»…F”,}h¦³=OwxugNšø»E«C|òq¨›åG4¼ÂZ§Í©bˆšô®Ufi¿TŒµ˜ul«/²J9dw„šó=~ÿö	÷/ñ
Ğx—6í•ˆIÈuµ~ô…/³ü÷ãªº¼T‰P¼âŞ16µI¿„ö³	¸RT<¨
›vZvI-y	åh©E¯üŒ:ÅlhÄ.¸Ñ[ˆ%‘Ú‘àr'B,µqz†³æD’¼‚ô`–$÷š½püêÛ:/gıÇ‡8.ßz™o£ãí<%òoœªOèÕmZ¥i@`¥;ªJÎ¼€¹6Íô[EsZbK7[
gCÎ©‰¦üh|Ç'ç$cÏ?£%I*
;Ç7‘vşC!=ˆ¥L!0	À¼Ìp< ÓØÇ ¯2F%?ÍvÕ1ÚxDáK†©#$´=Z‡GÜ%4}á$êE®6“_¾ò”†FÆ%-y'?&o`»B+¶*)3Ú¸+aÏ•GUp
[Z¦~Px‡«è-ÔÈ ŒıÊhT„ ¶Ù]Q?F\œZGoëÛµs<Bz¸‹BÌ,0qŒp!*Ü£İqÓ®f’ù³eGHÛ‰ƒr‹ò—ltu>nÔ‡<›şŞ³A8HÇ­ Jà–¸Iy{?awx£+ÚŸ¤„Ÿ[?4¶wvQÓ´¡×£<PHVÚ,MîMßò—^àõéi Ò3÷'”NM}e‡µIÚ²lávxÊ&\ƒ€×F•_~?3ŒùäP–e š\rÀ®”îºQ¾>ÙL´€©%… Û®BjRÙ F_hQš`€ƒ-ª¬âj7ÿˆbMnØÏ'“~$±Œrˆ¿J‘»‰æ+L'ôctªä+Ñï@¿,èåËşuµŠÉûgºÓ>àüüúã‡œÄÃõVµ\Ì7À(ÊœJ¼Uc:kšk±t/—?8" Éì‚ğÄÇzÖÛŞIM0a¤y•% kšÖÊxLol[,ÍœyşÂØ„’ş–~%¾Få"üãÜf@ş(ãÑ‡õ4JÑè xïT²x³"R8î+k»ÊË{ócÑ¤=K4nöa¸"?§"ÿÀÓşÉD@zWÿ-8ÕĞ¯ROÿ€q}RÈuZ( (t•çV—[á&×q|{BÙ±¤ğú¼Rpã˜9¿Å°ØÅ9÷®ô¸í–·2wcÊE"Õ38ÓĞù6±†I1\ªËã¿[»D	Åª2òÛîõÔ‹4Tê:fıÈš$ß†lÙ¨’T°hÓ¶!ş÷ıU¬7°ÀN qîT˜ µWÛÚ§ ¼tE“"QuIc¡ŠÃ±5Jé!ôà@–eQãpÉ‡Ï¸ëˆÅ j%ZÛã.AĞànfªíA*­<.Äºî¤ƒIdØ¸|y>ÖÎ|ÀGR}‡Qm]ïñ{3XJŠ·åTÍÅM!ãÔ*ª‡[’TÂÇL¸¦ØY…n ( Uÿ,ï²SÄ
gĞv¬ì¥)1_›_¬È‹Úí—ã38Ä¾‡ıïÙÀ>æd=³ËPEÀÀ-lïCt§úâL®õ”Ü˜x83Á—6#*!l$! —ŸnXqMw`@ÿ9§ù551åi¦ìâ+ç¾ÁÃWåF…Vı“Iš4náŠœ0ãôê¬hèfÜº4®Æ›´Ê4HEöŞÌ»Ä?'Ù2¥çÛÑ¥&-y:®jğpiD2Ğ5•"SH&[Ğ}(ùa³ÕÂB¡å<uÿŒÅZ"Xô€ûT;wˆKœßvËÊèÙ¦k0‚•£[ÙÓ«‹ÀÃİ–¸‘}méÖËa”ã‡P¢<.•è[4ãfP?…íİ¡²„ƒÅAÄ»Á“Äœ®^C#–LnîødÃ7UYCåÑ6©/¯İÛq˜"¢ÇS^>˜ÒÇµ­íi\€W=ÎPĞtàÿ”ºÿÏ^ìTÃhİ8ÆìĞ=Vp à¨œ'óq«ñµ¨S„OĞÌì)¸JPÅåsTyíàèwG€Ã}8¶/¿íi®à$óJ( Rö×@IZ5E9æÔĞ\ŸçÓy‡ïÑß Sà†óü3ß]¥„¯HÉ½(›yı¨ ‘Q£§¯XuŸoK—é	HÍtë×HÓfa6r@ÜIZ$§Î“vS€.tœ˜åRW#¤ÊP_åâ8œ»pº*Šóyã+È52¥Ü@uÌéâ¿ĞoãuASA¼”ëÂ¦;³!…¤‡£`(”9wÏËˆßµ]7	™6;ıi¥ËÖ—?zbşãşä Í¦İ¿‡€À­ €—ÎÀàÚåÅâ¨°FÚ˜›iwáÄ]j?4e%1¡)¾şÜÖs×&Ió³›ˆÊ^ŸçfŒái¸ĞšŞN_SİÈH¨¥áNBì1£oúïÆ—şe‰Êvy¶*îoæRä®t…v¿Î3A|ÎØHuäãEô$¢¶ûßçeİ›)©MI§Š¥é‰Uª¨^b¨z7Ú—	áÑÎ5F¤oÊİKL2%z:¨G.ŠÔäöûµğôşšÛœÅÒæG7p*ÁD`Wá¤iwOk¯°]°O²ÿ²ØË³œK‚éË>à+Z£f1OD„V§ıóv«EšÔGoğ^kò`Êq!ßVˆVa# ¹‚ÛYÿŒ'£ãN»’×ZÓªKÓG¸¸­ÿÉ¾Á6®¶fî‰@¤F‰Ì³Œ•êXNÇ®Äcò‡ã<gßF„èRì0µ^§‡i¿ğò©ªw\ÉÓlÁŒ^ÆÆ’gï‘?ÈH¿yüø_÷d‹¯9Ê¤Šá®CD  MmÀ"±/<ã´"kq@¸)ğJ_]…á´S=mn¹ík-P«ÆºaìèÔıÎP‰6«Õ÷I æ‰¬Pb	-3+/îÂ«…¬<ÂPøK;ìá``4!®8¯ÀÕní#“J1=š—¿Î ÌSÃŞ1•¡ÑËU×®ûÏ Õ÷€ƒøŒ]°ÍDr¶{hmñI1¸/°åtÔÑÏHB!&H×™ŒK‡•|ãİ@ÍÁVH¶—™	ë„Ğa÷®m±ÏèWşÂDË+²Mzı|¤N©ÖWÈ«j½{l8ĞÃš¼#Ş[rB§ùÓ|¿+¹)I°,(_fÿ("hI®¥EÁÇAã¾©˜–LK3ó°íÎá/ b`b*H¼cêY!bÔAşA.ò28"7Àšt¦¢Ó+Ù±Ú¬xG!~¸şæv€^ òìZ¯À‹u“}6·ója‡)Ìå(Vyªƒ$ç‚>aÏ(2-Ä4f\ú?¢Mg¢uÓ>U÷˜uşZqGÜ€4-.9µ?¢kræ ì!åpÔÑmK¨f`¶7½í`ÌÏ–p ß)8)sb5ü0š€¹êk·.&tÁºWGæü´BOnT6e
¸ˆØÓşF¤ÜÌë&ØG<;š®¹¦$i‡è—Šmİ@]œÂ³¯.ef?Ë”³<ÿ¥õ »FE ”ÍtÛS¶úÑS :!üÒs1KB9ıÜù¹Ÿ·VBNJ[”LW( µ®Æ/C…“„ôv	äNn/œà •Î{'<ZpÎiårÉh-²ğFuíE|ß¼Çº
ÇWŠ2ş ‰]*æ 4õ™0èYêkû¬(4Oğ¨³ÆPí{PYµşÃJ…œ=|Öü‹A“>¹Û{ì¹v"Nü9™Å"bjbX‰WA	j1³ĞtÆÇìé"4˜öãã…Ã¦š·|Ì"o?xüTïÑ;o™•n‹óöóV„rÊ)DI’X!òsó»x+Gh+È/¿VD—WF´-›ÑJüªZ{¿»¨™[dÇ7i{PB&Ïò­«ˆT‚Ù>ÛZù3Ã$FJãÌ6´‡XWuÜQ°0[¢áF?Ã¥ÜQè@ß;¢°ú¸Jç!ÜµóÊJáH_RıHÒ‹Ê˜Aôr˜7˜œ®AgîJ©w«¶ùKË©-Ÿÿöb8â™¢ Q³ºæ›Mìˆ3Ã—¸Ù,ş t·ElÂşxG6Ù*îÔH5+Ë’í$…’üC ÚÇÑap­g ŸŸec6n¬ø§üW—P½–<„äÑ!'\«{Ç¦ç…bÛˆiNú†U*wªfvlÚ%bî—(Â¯Qiÿh^ı¥°Z«&‰Oûq3ó‡3«JpÙ,° ­f6òÕgSy
¯ÿ¬ö8,ˆï¢§ŸQ$ß&Ô™“šä`*ş7SE)øÕCÉ·\n³àü]"T™4…e­ìOSN¤‘ûtûnŞ~+W–ìù*:,Ğf×ÒÇî§Û=ëC
è‹ììÛO•*cÑõ=î`'Õ(šËû9ıÍ9¦)$ßf±Û9±#áiºYì`×B¡ÚS*yŒ›Ã2>V I
µ˜«ÆO‘Dî<¾äe'á¹Qdü41êÿzD–ÎÄí&±ï±Åo¾-,œQ
5Dè(l ÇÄ¤U¶£³øÒ‚wõóKíj4)M`†Ç(K›vÁR_g•~|ô°æ¯Xƒ—‰ÃÑ­	Ú{Üh±8ïVLÀ¨¡}å/SJÒ6ìL‘<R³ç~ç‚i¹Ğ¾š«¼‹˜½Ûë®ŸÂ÷°Ïnğ› Eu#kNÛİÕã¦›Ìù`zYÖ¦/Y7mòŒ-cƒ0ı>48áêùkdß{¢E:In9ÈS»…).&DÓ{ŞÂ¿¤ÉœœhG[·¿I^¿•4 ~ko÷ƒpqœMªFB¶‚ßó¾¤EªB-éĞ|çS$û,_j•«;äI@óØ2òÕÖìoI}†x9(¥àØŸZë,4vòcvĞpûOİÆQ" iùe‡›ß9b0ÒMñ¶Æ|”óQ-ÈcÓjm.¥kY(›â¨×*9ıér°% Q<z ¶y'CÂ%Iñ¡øÿ¼Ğxë ¤aø+uĞAÛ•	 ÆDRó›AÑ}íuIÅÑV”ıÎšßû%¤‰0d¬ß Ö^;•0öéVMNÕd!+én»¼	ÙGpõ¢´²&–^íó¾¸KŸ&Yù¿ió7Š¬ò^—-ª
’ĞéšmãË{íı™%¸In¿B.z5Ø(ëô=9¿ÒqĞõ‚j¬í–eÜÕ::3i?P?ç*—c“è2	—6†¡¹ñp§A@K%ÒÚ—;BeñÒÓÆ8zÀé]÷av6L{QÈYñ	ËÇÜÇ,xrš¬óç¦êãSXÉSXİ¡ÑşP©ÙIÜA©°o½¼Lz÷×†È|MuBÖs¼7¾:9ke°Õš€{flz#PèüâåBâ¾U»¦Ò³‡»ÌÚI[U<‰ë,$6kbş…fÊÅv¸“ŒgişmjGu@V<îÌ…‚D,G…Å=Kp=0Êõ_ôô×º¶pËåÖ¤È—§1˜·»lL¥¹…i¯ÁÔ!\E–áå,®-–°úÉ;wŠí{@ÕÓ°D|ç‰[ø[¨w”q@˜‹Íëî³å’”Ò»‘G½yŸ¸â4$~sY8wqÙò\taSİ`÷UY&f·•Ş±YÖó.«­ÀçÅÒÚ»Ÿ%ôR·ÄİÉ°{$"ªİ¡œÌ„8ËÀI,ÉÇHEÁ¦ÆRÓº²z©wz Gå-ŸÖ™Îk~8#Å|7i¨4,[2#Ì«däçNÎk\úÓ¡Ï‚š*¼Ék(dK§w]¨émâM&¹×ô5Í]¯‚+Q+ü= £ˆ{ çS~ÚÙ´k÷2‡gÅú;Ñ>~R¢ó¥ öu[l-÷Ÿ.Í‡‰Å˜WhäfÌ€}NJƒòç}?3òäş^¬Ê3ò¤ÜPPëùÒÁßúÖs±1“*j]æò>[”ıfbí|?A¾É
V_¨Í—é=sâ±ÓåxeÙÅäÙu)âÃ-/6Àj1ÂíÌó{0¹ÂDøwŞ/ı`~ õ“üåïA¯]è„›xòH¹öŞšF­úqı°.}¾£T¬½)Ùˆ_vLš³‰*í½ÅùONqxÄ¥YÑ K±¼J\pÿ® Å‰‰}q£äŠìõXÒ{ÆÒà„›•òõÎ‘&§Kaí\€_«öß8Æ%4—(ÿà3ëûˆ£şà“ÿŸ’œuˆ_ms0ÛÇv6éœb6öÌ]Í8Ucí×aŞíSc.*Ö[í#ĞÆÊªkl¨_îXmëú¤	Û°jEcDÆ!mÁ«–0ÖŒ$q-æåÒÒïÂ”&BsÉ»jÒU?y#Ü—é-POk:¾÷4¶(¡GĞmßv¹ÎDÀßg¸z3].78²
°t÷2óA'(uj4ª&ásp_ü1@=ıT‚‚´wÀö]ç.Z;işU\»KAV=Îá<íèƒ ÑTå-9®·Ë(>Š2Ô5¹‹ŸÍz„,‹Æ*èå0úòtÙ,]¼0P%Õ·GyVZ]ÒÜ³Üi+Ô<qæ£}Ù;ÒÊHş—½Yj,šâù†$g :<&4Ô)?Ç?Ìøé¢hh+$O>ÆI\7dccÆ=YB÷¼,çJÌS…ó_ìá/æé€L«´µ@¡3 ‡Ú gsÕÍÓ¼ÍâIßq¦r»t…Á¥»L‡R¡Uº»pwkÈWOÖ>6bõ¥E[¢*Æ—Ò×êğ~“ónÙ€={Ÿ–…30é«ém£—G¶|Œ™„‰t×y_{¯øi[KH£€Tús¶P7íIv’şg:aÆåL ıø„:—Äu"à/(#_$)y?‹àã¸-—“À!ßÚ¢d$-!Sâ >mßy§ÓoŒŒNt((Èa‰ÌÅ²Iğ#ß^š?{yø^¡˜<›¤¹ÆWNÏ¹GbˆDôÈÇAÿFÅPnXur±TÊ¡m³Ÿ®Ûğ#âPÜ•âÛ0$î‡Ø¤Z#ÿq(ÏŠ-À5*][°U`Ğ<Å3"fuçuyá°İH­uè>PJ‰CDg‘Õ¢o:ùú9MOZ9¯bZ§¶Ğ³mi’e¾B;8L/ŞQ‡€šÜ³ên'b	Ÿ@CÆküO‘/.¹XlzåÉ°ì¼>ƒ¼>Ù’n±ßóŒvı‹\¸J¦&r²`îKÉd>„¬;q¥U	‹íYT‡$hµ•¥Ñ}×£©ï´aÂ~áç fµ×Jµ]í¨£«Œş–U€eìQ¾¨‡FéåÀô:ú¶
©¹Ç)W‹™§îzqïïM üB'¥ïÔÄ-ğá¢/~â—³=2YGo-ßïÛ7ØV\UFë!À\a*ó@á™.i|…GÛÍKC‹«gßØ4¬hÒ‰ó²(¼|×Ù-CcY¦¹°½@8!m`bO´¢]êßRBR÷‚ªê€÷ıØ ",Ó&ëÒÊ](ŠŒÑn°³<jd	®Ÿ@2xZÉâI-evÏ|gâ#áÕJ¯r°}¶îÏ‰¹ğáWâµ´@”{ò^üPßeÇŸµ‰ãªÿÚŒÆ¸Ü2#¶0Ÿgma™úl	£ãá€@qPÓãŒà‹îYĞ ¡î+ºóÃ‚Õ¡¹Š†xl½-¤İI–ƒŠ)¹¨¶@¹ÛST~2××<íW7Qvvö_ ÌŞHä7yÅlæV¤ïşWWì”î¨ŒeîÖ¤(m£‡™ÃyöåÜ{b;HRqäs€ß—O$A¨wÕRXd,ÁnÖûïı3Öwúou¨¯ªœ’µù+c¼Ê@›~Çä	®óÓ1*©²ãş‘RV·§ãø‹-¸wĞpö›1ìŸP÷Çz$4¼]”Ğ‚ºÿDL»gš|ŸÆí;õ¦´¬“©&§W|„D`„’é¸­|e¥»Ën¸w¸æ"1Fƒµ¡9ª„ÜVXLÂd¶'³_îÎ~æó¨}íq¦ÌˆoÄ9Õäôõğy#IJËÏ'/AÜ©ÿ„ô‹ŠÓ:×ËÜÌş&éï Å@'N‹ß©?=ÜœM¯ÒØ¶¨ŒpéçB|àì£xw(A°{ÄêQ_N¢s9~ïù[QDìÖÂøpí¡Œ.å)û¼áV5ï}ïzUºØ¥¬Š§ì²¦=û0ßµ”¹M4½Å>¸†èwl²f;¬‰'ÁW_bú`î­lœƒ•çó´gÙcÙá¾ôá¼´n×ÿtõ`ŒÛ¶@|„lÀ‡*”FJ¬0÷nÊü VZ`ûTh MÒ»ÓY°‰ÉÚã`¹m|AÿÜKH¦3Œ*j&Lù5^Cp¿?¹hÇÛGºN.Ÿ©º“J
Şi³ƒ¥”¥ŸôwZï°#~.èÙ#§Ğ³p›a>A£¤eØŠ€‡o¦j–ß®$g± r—*'Øæ_ŸnS&P¤MÚ£dä¼knp€ŒWÛÍ»’k>’Iî
5$m:dGc«iëìQ8Ø9gPµj¿µ]Mˆí,•Ò”£æÊ„úôz–»×ñA©[N=†(µ×[¡(é 	õyó…”f¾	ñÛhe××©#í×g¿Væ—¡´îÄ­©¢2O/ÁSx4Õ¨+Æ5UXş{Á¸íäc%½Ã]àf¬  ¼µB§oü˜j3¿^#
-Pq4#Mj1Ï›»q¦”©„¥Á²Bè4¢?…4{æ
7<GyQ!êÙ•e¬^Ğ¾|C¶Ğ··]ùôK¨ÿ¥äÅESÿÇ”Gı}Ü]ÕPÙqø€ºê¨ú,¨ğÜœîhÛoH;êb¤6ªpÍò@×À;¬CtÖ´ùø|“TfVì6å+â<©0(ªä&ï5Öä6¡iÈ³kfœàjÆÇiİa•±ÑÖg‹ê «lÏÙ¨÷)‰†Ò^ŸÓLu=‘µÇgı;¢s¡>ëå—/9îuL}ßU¶­£]Ìdë¸Ôkù—0W¤?
ñ­V–mw¬˜İPI—~æ”Ü£Í(Ùú&Îß’Ê&@g3¶æu|2]b¹®)É›Ò/“«Â©ÌÓš¸dyİMû¦."ÌS ã¤cÖcŸM÷­„r˜-ô>%½–ó4K‡wm…`«’!ùÆÑì‡CŸ	IØølN¡=‘›ÛoÿÇyo8Qf #÷¯Ñ$Ä{£6¡‹-r¯`+1&j=ı|uqíÖo9Ñõ)á-±\·={(Z».6¦hÜáh•LtÛXïpétàKhmÓpKšîæıÚÍìÜP¯˜ÃPå\­[¿ä<ÁÁaiÒÖÂéÛ‘Òıí6°—.ºúÎ—O?HaõÎ-t¬÷øİh<#ªËpHIL[Œ‘çõÇ§U,EË^àŸUòĞÉ@9}İş»|XUJ Ù¨Á›6¡î•âÉ“õ³†@Î!®?!{±ò!½RºKBéAïnmyº%Dîb„kUVædrôù¹­ı-RßªËÁéd`šUbÏºÙ‰lıZ V±$›¤³EëŠz'gÌ·D¡”!›+CLÌVÏ¦ËnKXàõ;ôm¶)Z"!v²aï¤3Ñ‡×Dóv
ª1O]s±.*Åæ³Ôá±¾í39ê¶û³TÏÎªœ)€ŠŒÏ
Ğwn kíÙxg>İìl¸(´p.UˆoZ{8|³ÂÖŒÀ`g+›¡Ëã×zÆlA\Õ şb\á%7z~-ŒyÚÍæ5<hÏÍhœÛ<Œ;~pô/g^÷ƒájÑÏ9Ç!È¼Š±èn6Êâ¨¯ÊtB
¥€§rxWØşß»ğ™öká*ê)ÜnexÏôúÆ‘¢Óäµ­dF|ï2VÿIR˜ÒÈİÄ®ö’.@«‰4Luü«5ª(È”ê‚H!‹¡\­§C®(åĞ?ˆMÜşÊìîşqƒÓ›(Å–¬QÔ>#-„Ó½i4óná..8¤¶m£H´ô?šÕZInºß¹¶àn‹şey…ø'NVØŒŒ64Åºº¥/)a\i¯ÄF–Z”–;±H1áÂLÂ_Ã³{£•(«ë»F–¢ù¿l2Ô~ë=KÓLü^ÔŠ¾'šòóéŸkW¼{8¾#BqaDÑ.`û›”ŞbofU–Ûa¬rÆ+åÜ7ô…*Ú>á¦…»~oç _fğS¦³\šãoó61Ö2å&Ìq±ÿÂİæ¢iãšPÎ‘ÊØøæ£{-,À­Ó™ÇGŠH34‰pÏA,F“ğkŒ·ÈÎåUj=£~Ç<kyC ¿×ølúu0Â£:n¦iÈ=M¤6Š‚¨V Ï>¡	’VE¯øÈ²Uçyz’²#"°.ŒBg*öuE–	.ÈJ'2ÏyPƒ1²y5'®[j¨„ŞIØ.Õ²­a`^âØXîtƒ™u)ø"ÃH^íıì¾RÂT…)c«QØœ’d·uwµÿàş®·¶¹›ÁaåT©gÆ§%ó;VY¥Dîz‘ Åà$NÙËodå"Ö£&>8›N«i¼^— ˜š‹®+ëòk€©]gÃ*Ô–Š’Á÷Æ…çGSÁgOR=6/¹	5V¨q¡šÒß@ßŒCˆ¯|z¡ÖQ1â¨2y½–èË` èA¯Äc3€ÜZt:Ò^¼½æ)¾^?!@!Gt‹JR:1K£Ó¢Äìtï›8äšxìR¿
U«K J°^ÂB“H_ªYù;ãQ×"L,£/oºÆIÔª7YÓb>õ¼Zñ “yv¿étIúéL?˜¾ kr›ÉÔ
~[
™]Gûïì„F=¤ÀÍN&…2˜ˆ F…d{ª·ËÉ¿Äœ"ë²	ù?Pë˜ÀW¢	Sõ |Y¦çHÅ†"8ùùçW›çòl9ÍG$+Ø'´q…Å nãÏ,të[|.éî‹²A³™öL0Ê½]Ë{iîÜ¹Xó€è*P[ğÊ—&¬dµ‘Ğ=DŠ³ØÄ‡i6ÙPÈf~ÓÿXæNÇşî9V5©Î[ø1I›9qîHŒ‹0šã”½hokgixq„¸%ğ'¹dA p1÷ä½HÂ]…âğÍvÓPúšƒ¼…õûË]üû"Nó«R¸ù«u+Ò/L´×W¬ZUäè™Éõ~ÉsñÈ=Ôİ âä»Ôæ7•fşW<‡k+²ó`9ş)—-%œÈÚwS6úŠ˜:;³ª+7ğnè	İ—­»U¶‡½ÕøÎ3gğÕ!xÏİ‰AÄPHSûZ’	c»+,¨O˜Öp‚Îë5IIìøô´o7
¬‰ˆbæV÷f+ãuÿ  z¾ïgN‰ ä½€ÀäÀª±Ägû    YZ