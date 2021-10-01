#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3553240463"
MD5="a5db82ee3d9733e1ea8c79d47c71d064"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23648"
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
	echo Date of packaging: Fri Oct  1 17:39:49 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ\] ¼}•À1Dd]‡Á›PætİDõ‚_ï)ƒO{ü·|•HX>CSÚ¨#.ù§¯Ûf•ÆIMò}Ë'Ë+„¬ç®Ÿ=ÅTÈÊWŒ‚4Ãü 9ç°AâåïØ;àë‚½@0å„Şşƒ“§„Q‹ü¿¬¬®ZÑÃ 0«	}~øàX©&†”•·p³t²¦Ç¶C»UîËIºÿwˆ×™É.Ê¯·‘·OUíÂáƒ_B£Zß]r¬ØîŒ|P“ñÎì•F»NŒ¢îäÂ®¼Ÿ³¶Ì„“ìáßµË”'qç°WD)ªMwiH&íµ»”ÕÃ×P|E;ı7±j)0,r‘Ô!æÔ¼7{æ³*ÁJÃ·œU:2³&gÑ¢ †ƒ©Ç&Œ¹ÏºÆQò- ëYÛuƒ)¼½üîòa€¹Ì…»Àç751t•¢"{‘…¬S+Œümdfı{V6ÚÜ‘2º¤¦µL:¼cE)pY`î/òŠÜ©(ç¤¡èŞŸJå*ğ^-G?Û‰_vJ’öÊAV¢$rygä4dÃ$:€	ßrù~3œ•x£|/t´½£Œ]]'J¬ªÎ¶a·ß{ôu€NZÁ³7û8¡0ûŠöï¡àI+zHSãÕò63È«Jóº”üÃB"É‰Ø)M-D{îïVF©£D<šâEá¹ne¹2–%‘Ù&
Ì®³)±ÌŞKÏêHØ]\÷\RåĞbÌ¤ò@HIo@ø'÷}> ó‡À<q¼Vd!±4Ù…;[×œo~Û9ÍFÂNa·A
¿2ı ÚÏI—I½EfqDŒ}Ñ8vú\Œ	:E|Úø!»¸}|è:€NÅ±•½`İJVq¢+ÉA}½ƒCÏc 6ê·7;ÊQ 74[mpVQÏºL>ÍÙuÅpŠ‹ÚĞTs1%:q6Vzí1¤&Øü­ÿäğnWø·ü \Š¢ös%¯mOjGşD2’üæàeº]ˆ;¨Mû({WµÈ¤µhûoı=ÀŒX‰¡ÿ©Ğ¼€ß•VJ\ïÎ»,­££ôŞ/œ¿ìa’\_ÌÒ|âî•™Ïƒsîšœ½nNL”,ÚbéÛ‹	âÃpÄ}¿İq![wn@Ó§d¢?;<¡Œuu KÛçîR	Şì8^¼`PkôáXj^û¸\÷id«²êÓ‹lr]_"]ûÚ«¼¨ïTx9e2¤Ê¸ò,69ÄfÙZR8 ùİúqRÜgN­|Qz¢#ÅêÚÌqŠ$r+}«"<ö3k=iàª/*“ùB»ƒbeä<c§nÛYt"$IFc40–ú9%†à¢ÑÒ±D'¹…ø¨)Ç–¿)cSHè~ÔÎ3Q‰F}Pø¼ãØ’€h†ìà‚Í×q¹ùKÕû>1¢³ìİNËøŞØ‹´.'y‚úZJcedşˆ:u¥İ‹Ôãlªh9ÁÁ÷Òûí6–AÊ)·äÔ‰Æ*Q2àÅi½6œxş B1%sNWS[°Zÿ­”Âç„“@!‰ë‹¦K×?BË›dNI©Ñ%43Å®{AçåÖÌÇã?G4·y\Ú–\İ20lª*è€Dğ
ï,<a´³ŞµO›ÔZXÇg $Ñ!YUaŠ'ÕTFH­Üû”'Ô_PMÚ»C[ün–"ªú›Ïäï*òd›S±;J,H×¸-ãJÛWÛx÷ÏÜ7õ«·Iªå`ƒ(‡óÉsª?ÖSì@+ÊÉ`½n2yŒmGiKX¿ò<°Ì%Vkõ~ò)YSï“mË:îvaôZLÑpÒ€‘(gq£+æh\IÌ¦•äÛÍÑ±qß)‹•ìUgÜûG±2;~»ŠßùÂÇóMDê¯C‘Üè·É¦«	?°,=BeOå.Ò>ªçÈoF·¨¸BêØ˜òÔÀûÙò!‡íŞÅÏYdKîp~YîŞå*™xæ5ÕUâ±qÛÊÈ’Œ&Š%9—şØ½š/gÉC*@09[Š~‡£bwšuoÕÕ¨ˆ«Ñ?<›ñPQ¤º¢ÍÙl¨ûïìasF:„r5@úÀÏ£i¾îl`Xl…È?}GvŸ!¶nºë ‰ñ0•|š"Æ5`hôğo‹h—_[8ˆ„jJANÛa?<iÌí“c4>g…YÑ¦·É”…FòÁKşş:
ŞÖo²¦© ƒ	¯³Á`”†¤k†QùÜ³
Wƒ{Ïûä#{f£}ÕâÂ^’úk³àê\a@ ÑÆ“ÙOÀ÷à]—Ã¡ÒÜÕÜãùwO¤æó’É)]È9šÁÃ4ä¦” öDs·«;ô°Äö¾QO‚‡×Ó±Ÿ#Hk>Å7Ÿ°©¤‚ˆ7)AXYkB>ijmFakEuÉWÑ‘ì!€fí‡8U~¬LL¿Ê )¨Ÿ	´=”ñdK‹v4]„²6Pèïs‹Ö ÓÊQ¾ïë60ÛlØˆÊ-jèA½Û*ûJû&Ñ;USvğAHS9@ªÍ#¦ÿã%gæÉ 1JX©qñŒØïoî`F·¾”ş’îÃS¤¾Øí[>?X¢è`œ’å¶ã‘·,ë#Õ™2ìÚaY±“¯´à¼Å?ánéÉ¸Œ¦³î¨[¦€DÔA4¿ÎôŸXÔ$¤/´Ê¦ãÜü}!4‹¸'.!è’ÆÏ°P`-ÂïHoÈ$Ñ|«“” xf÷šuî~zpÚ´U
Q^şXói•¢û‰ª§ÑÚ¹óRÛK1µdy»¿"‹-Çî5=ºdÕä(_$8!YÙ†‰j3c"ObV8Z~Ûî×h k²-@ÃB5Q/ÛÒ¬5jnW©b=ˆmu[¨÷˜¢éî¢‡j~mì«Q'M£A0]ƒ+ÀGb%‘äMr‘oi’fâÜwt Ë{uõ’\OğU}e%e†/s9ÇÇÜù…œnxÂDî$ÇpŞªo†”ï›Â5ímık‚×Qm¨Æ5ËÚ6gÙY&“ñûv•µÌ\-dƒ¦Á÷¬şl»á²²ğ6qbÒFU¤w§)ş!GS–knÑÅ”0GFÑ¬V³ ‹s:Ù›…RP‚'%0E¾ï(™¦î¾Qÿì«VÚ8¹×­ó³ß®cf¾˜ŸqË)[—§óFEï˜”Åò±SqUK•¾p×Û—` ©{yp­Í…ÒKÑRë¤¢N@¶P<1ò †´ñŠy
ÚÜş3OƒMA¤'3_!Ÿ¸C
½QÕ“xæâú¿tÂ{º½—†'-ğLÇš…sµÀs+f~Ø´d…Œ.n)­)ùuov×õ)õ¶
#c¤’ŒìÕ£ÊxÁ`üb¶–-Jı˜Ï-ô'¢?]*ÑJ\Duvµé#Å?MÊ®»WüÁ"“²%+à]i±'x¤|ù(Ì„¶6cØÆkŞúîVËcéµoé şEŸ!„‹®n)s‡à3 ’Ÿ¤#{ öEW³#.auTÊ@Àó_›R‰e®C°¼òtæ·µ»z§N§ôEiÀ‚HJ:,§š€Ô}^wRÌk´11j-ÌíÀ*%Ncn	p£\Ùsñ;2`ÑÀ­/pøä’ÉusÌcü'n’1®EÚIÖß½Š­yx8ˆ7j#½&”´s'ß(S…®Ô¼ö}£êé8z‰ô—úRØt´÷Ü.ôíÎ^¯åN¬·+ªOJ¥‡Úÿ †5¥põâ½„\IĞ²úÒ¯É1Ó“úY¹•£Ú`¶} @K(‰Fª°ÀÅ	–>˜lÌH7ö(#6şÚ±!¥‚[ÅLÇ ƒI+7ÇìY¤DÁÅÈù«ÅÅtÏŠ½Œe¯€³Æ£OÇ³JµÄè²y ™­óã¾U˜‚3zåEd§Øå4Ôry^½1!aâ°Sö‡ˆ¿ÉD¢GÏFàº­u§êÏcœ€l³|{ ¹®ê%z½´¶õ(ë«ˆf.˜5àÉp&KV/õ|Éõ
xˆÍ‰JËp)2òµ¢__ÉL÷á'Tv*ASŒšíÄ†r »ÇQd5Ô°Nù"<î¾îÂT—E(XO­í· 2ñ'„¡táiæ,k²şò^­Zš^³DoŒbJ	¬ouï¨õ²ŒWk¦*ŒçEzï¢ğÜÊÎç™ÃˆéùÌŸÀ‹¿jæ­áâBŞµ:ºá/J¼bÆ…NØW%.ÏíæÒœ‰ÏÑíîk6aN$¦ÏÉI¦8Œ©ôyjbÆÕmá1È÷1—Šâ¦IË†Ş± GYÖá\j’$·~˜ˆ©[üÿİBšüËIûßˆ"0@&n6˜YÛş×åĞt¨ï/í&Ieîš‡„Ñ!å|•ìïàÑÔyå?§¬1kæ¶ 8q·¸F¡`áL5Íú"9oğ87ëx»òÒV¨U‚ib Aèh¼ÙçWÂ"œ¶µcÓªGï}ıÈHİ3§´®d—wÿ¬ı¤–$`=24Ádg¯"m°©®‡¨ícšÌ‡VJlkH™Cx|•z2k[ ¹Û…7¼œCFJsı†Ûê“”œµ}XH½>Ñ"q${¹§°ş¡dCB\õ_ù²ğ.¢‰×^H@núİ¦½Ş–.’©Y²Û¬SôZ
„{¤³P¢†7‰Ô¦÷1gôE$ğñ­GÅùş§3mïä²ÑØEkM“yšpøÛÍ‘8Úc§¬³cÏD±Õ·¶øŸzTv©cj°ëºi*êjµ¼®çUä¡óUÔ[È‚×p³pIƒè¥´j{§v”HÒäÌà€º£Y4|nFpóc¶ŠÅO9£v"ÍA•`Ø!ê—Ô#ZXÄEdàçğëùåÿª[eN€‘Èsä¾™)P‡BÇœY¡=t m²Ù†ª
``Cu•ñ¦"áê5]È”_qØÚjLD\¯m…Ö°3‡Ìƒ’A
<ì¬Í¶ş“gU”ê}ÙF¬©®?Á õgŸo…
ß±›6×
² eÈ’™Z†3·$Go2ç+—2¦ŸÁE“¾ I\[f`©ß‘'!g32yõ»ë>>sBƒŒ8ŞjèİYo`7d×vmÿ“‘Ğ&¶û2¿ÒjĞÉ¾YÍô`dä)~bßmğ„ëË‡ZfnvÉÔ&BÚºÕÌ×bûŠ8‡D¹çÿrÄ½y¦È‰×·şN~±b+ßË<ñ$[äÎ úôô“L' w22Ç{üfòcqû¨‡Î²\Ë"1çî3úš;f§¬’@åxbÆ>b¼MœÑíy³Ø—D×ÑñBÂó¶]½šmeaê¤Ìz—1ëõMPjÉFì Ú¯ ˆ}4@|æ}$ñü\“@§´ş/È É›mJ5£[çÔÄËIŞgtú‚Yã^œ¯	Jt™ÁXAÇô6K	¤âklâ¶—Rô	Ÿåg¾f7ßêCÄÌ¢ı“²t×Ø5OHªrÌ:(HY[îƒçÖ¾Ã»¹£ú·Ü^XĞN4ğëVZš][å
9³€.]Û1¢ KèØ 7Wd×1kWØõ4Æúe´6ÙRÖ‘œ¢ÔøÙÌ!ÛÎªT—kj~„q_Xì%8 çe!4Œ¤‹“\Tİ@Fu¯VÅ6yUîOåSÊ2˜==^VÓ	©ªaÈ+TO­Á•˜İçK‹‰ÏëÒN¦7Æ†È!¨F¼cÌHnÃëJ@ø}*ä*e©ò;¸Lš¬{íhÉµV¯(ã×¢ék@™÷ ¦ëéÓĞ3Õ-ÏäAÎ§Ü÷üÄ’Åã] PïqaãTEı\tÎ¶à™ŒûäÔò[–ÎöÙš:íßTáû7·D<ßş˜ÿ ‚IZÊÑ1’
NãÕÁÉ8ÂÑøÆòçRöG¹ôi?$–;….ş±Ìòß¿`ñ~‰¯…:D+™ğ®©³øo¼ÆP¨šD¾GôW[îˆœâÂ^v›©n>ŠéÎ£p
ºQŠÿ ‰	5wBŒÒ®0¸CàjóŸÎİZ‡›Y›×mÃH¡·fõŠ ËÜ“+;ÕNn!İbĞF•üÊqtÄıSõ8ÿ»ÔÀYÿB@JûÑ™ÛÑ‹+P“'1mT Óğ„ÔÊûÙşÏg'ø;ëœ6Q¯¼­{ò”,	NïĞn¡¯ÇØi <gï-&  õª£ë˜‰ÂÕ9'‰ùğáb|˜şqÊÑ»Ø¡oVf´EÜò Ø§Äù _şã>O”7«ÙÆÛA@šçñGâİäû:b~é€€…~è]ÃÏ ‚JüB<EkE® ‘ò9±Ï(ù@Ğ£)ÖŠ|¼]FX ÛqEÏ­ùQõ~ÔÍj«ÀGdb#Ù¡0¼¸d»á@i?·q½—O&N—çm]~Q £µ0	£ç1n²É“3æö¶®x5ÖÚ¶|×z	w’µÄÚpü”'`ÑM—¼Jd:”÷ ¬[GV±´ÉH{¥š3­C`àKc2Ì¾÷^ÿ*É’*aÈ¯*æÙeŠßãfvÑğ$@–µÿ(µ¦Œ>?İxœ„áı”÷æŠÌ\ Ú™@È×ÊB…3ÁôÉ<€Fújiù–Û}éüÖ³eä5!º$5&yËc¡§(İU‰!n„éZ7®[˜‹g«Uä3:¼ ¦¹s´bw=3L=îÒ?àjPN
ªœ«„ó|¢›Ü‰$¢v5öÜˆ‘_q•ş1öwŞ—sqvœımPÿî"/WZ§ëç
OºBV4ŒÑy{ŸÕ¦!§˜®İ™ä`"-˜¹Hö&éò$…ÕGNÁ‡9Yg#r¾[Å‘õ+š\‹ej<1h÷ûŸ±§Ã`¦$çÍÀF`¯>éšeÍ$xw5¡ğ=+ÓKì»ş57İ]Á2C¶è
„ÅUYüåtŒÑİÎ·áÜ2ğ@±C3:b.YVeöÇfñ®·áİf¸6AVísıæ(*ú°14ª¢}Ô2Ş£ÉjîÅ”¦m"Õ¦Cı¢ë!¤…¡¡xì ƒšÅ¿LĞbÁá™¸âe¦¶[ÛS6ÖÕD-îİŸ¹­ŞóÉÉüÒÍKçT;ıá9üì!>òNB"ÔÄàJ›*#¶rI¡Ù>>ÇäBlrz,GØG
&´§àzÃÙq¦¥ë¤Où$‹XDZâu:•†¤ WT#/ûÄÍ«!KÓr+‘—xÖê¯Àt—6Ø*Ô°€&åöYá¿;Ø˜÷{š€š	¦&e8j€ÎúÖ2	¸vÕ€¤kZk°Áº(g6š «Ì'è/»ô+#%íêñŠÂp×EûÃe‚ƒ‰h6TlV3ÀÉÏ§] LR´Çuy ä ¾iz{÷ífcî©ÒŒà¢cp@^"üı`ÖÔ6K‚Ü—¬±ëè>f¤ô¿Ùs• ¬»¯'„`»Á Mgü¿OÓÄ­İÇV¸‚ÔfbĞÇŸJfYÂı­Ú-P‰Ö§Á$9Ä€µ9¸xáR*v—€¶zz ù<ÏĞÍËŠÀÙZ~ÒÀ™ñv“cA
´ ºTX»Wğ5\¤Ø-c£BŠÂûN*ˆŸÇeÍ·B"'hu
ÊÑ	ß-JÊ|PÀüÿ¿â²>1¸ÛaéØ\iÃÅ4áÜÕ`¹Wùíd7½°DÕé¾t®€íW%LÏnÄD|Bh¡d‡SãÀM¸A7ÃÉ¶DO=×ÍÏmøaZG{Ük‡µ6iÀÔ¹_Û‰‹D¿*×'›>p$Oâ¹2İÛ	îP¡wÿ@Ú­QoYñ®•¦YO~X‡îûP5Éx{N0£ºîTÖ#tõthèúğx ¡hÕ5ÖôDTDÊ—ªOÊY¯™¢th^|5;[/oŞ5¦öÄ)¸Ş¡Æ²ê3~9ø$¬˜”TÏY¨AéwwûD½
é†øª,/
è'
.O¼¹¡´§{¸´ıvç%ÌS0éƒJBÛ‚ªmFÂTrlJòÁç²B•Ïˆˆ 9öQ8kœôÀÿ¥ûuYª¼ò'j'¥d8œge¾%·?°±ë³İjîÙ2é`0Z\Q\O;L8öP´û‹UûPnr©òuwb@ÏB·÷ÍÄÅóš?;»nªÙğ½ ïz€¹ İ&(OM“+'EuÆgûĞwô¯6·C=©Mº%oÂ+±è³“`aa@O½%&™¬ñCî<5`y¤şü)8ÜgO—Ä»œÿ…eÊ›«îjQ_f¿8në%½GE®T„IÄFàSØú-Ì¿=İVk£…™QP*€Xš9ğ¦È¶?)×Ùò…?ıòÈ(’Ø&nÖÂï…—[˜#¬˜úöYtŠÿğèzš–8¹Ho_3Ó¯¢CÂŸÕÛV?
Ã´İ Ä*ËteısãÉXåC´fùÒ¬`ÑÔz„3±şgÊBWéy=É(Ö£¶T Úü"k.ĞOüéşsæ8ØéklÅ</\<+<Ò¨0CÀ¹^©ÁF¾5@_º+æég;MŸÊfNwq©Í«½+yX ùO’}$"‰ûúCë±èÀ	¹« ¥Glë¾ë c?ôö…À1Z"²Ş—TKBV_ª8ö7#Ëtš6D $%xŠ9šWçhgTö0k¬V‘ÈU~>Xl±£„2<”º™õ&–ôÈ¥[ËNoZô?Óàl	ÔW"8Õ+Â%kX$m®ÅÉo”`™?ªó9JÑ&ô
¸AéŠÇ+ «ÌéWí·¾‚“pc&‡gh›X" ÕØK.|_ñpS#=.©iİ‚¸z>ÃM³Ê‡'qşé;©wYß2·N6ç‡á}4ğó(°Ôáï6ÆÌ×‚ÆXøFµä»L¶r0i=+>ÉÍ>[…hÌÌ˜¬SÛJAËŒTµş¢œİºÙä%·¤'P>oY²Ñ3 0”¦)`¼lSê¢£Ç`¤Çit&gİ§
´‡;§ûë`÷×‹8F¶*Õ1]5½´f]Pı–æ³)"ŞšÅ<ğ`g6‚nYr	<s¢“ÿÆ_è[Ã/
ÌŒÄSš03üY_ò°QßÏY=¬p#Úõ}4Ã«¤¯5Uw«oÄ+lÎıáÀÈ!Î·!ÒÊsŠÔt§`ÿg*Ñ®µŸ©L¬ª¹â^X=B%âÙìã¤&Çš7…°Élª7oRO%ßşq”çŠ¿ÿdc4+$bÇŞŸ|òoZê`î»±Â/’ a¤'KêeÑS›¡Ğ˜F|æD•¨Tg‡x’%	·—E]Lkrş9gu„®%£sGÎVÅ&­ï)”¨²öqa—NÖÉƒZ¡Z›€{İÁÔàë¿E·Òş-‹ZÄãy"rÉÍEà·QPlé%¦#Hlò!3V,òóò#Ì¾ÖÉúhêG¹¶íËÏ<JÂƒ4äÜ~gCô8¸2Ë(&œ«d5É¿ÌGLì‚«ø4µ Ä„õ¦ÔøÖMd6êù÷.b*Ó|#[èà¦q·UÎÒ”Ha}¥5BÑÎ×÷ENP6p™†4oeÃî=hùôŠ~zÈ(tÛË`ı÷$K„d øÑõ ÇÇğ(¯„÷ÜŸ‰ÏÃP_I±ÛÉ|FÑ»ø£ğÃ™ºª»m@Q|İg6lÊ½Og²œvÚ®˜" ~ÊÏoöXdP˜Ê$£Bu2:·ó¼4]í’\m_ EˆêHhLæ½hEP7­Eµs¦Mn™ª¬·Ôå, ğ~mKş¦\Ìº¼âPû{¤vËxÕ…²3±Á}›ŒT¸š7Îì—’Ôú]•^U«ÜïLTÿ‘†O€Ib¯Õñmk("æ	ÄÛ´ e7‚“IËä4”øpë¬k¤»~+“WÃjd¾~Ü# ÍôtjÍ€°P<¼™[Pnå ™†ÔK¬Ö)H -[ğ¿¶2–·‹dx‰H Û™R9[hjòD454Šµ3[ÈğÛ(ÖÑ‰Î]=Ëü6%_Ñ¥YcßÙ×ºC¹´`\dËôyplïR‹ÙÜ³á?Ófˆô	4¦$Ûä€kW¤j…]°zoTŒõ‚WuÛ^‘ô‹×<Ÿ†Ùów	İ®^‘ıü.ç¶7;5:Ú5âõªo[÷×gïE½_=}µü¾&ùğ ¸Ü=ĞÖKt`~m+RÂfÂïæÁ«~*!ßÈ›úe·]·KID¥§ãó@àôË"GÀ4„!LbĞ<”*ÃÕïówm0ŞÎ|Ó“U§|í¾\Q,¯M9
¾F××Æª¹Åv41šÂ
;èæ>ƒgCÃ!—‹òı`òî·¾•ÿÁ3¡&3µçx´n®Œ2°€ÁïALKZ­“æ0WÂÚ~Èã÷!cãÏâú~Oà!‚M,…æ^_1Æe~g´4+³ôI°VÌ¢Sg»Õ(t&ŞƒW¯-ÿB¾D@~¹Ãsîë)“3–aÃòâO€†Œw61'¥h O´Èú¶D"|~¬wRş*§¯—â“6yP*#ÚÄ­ˆ´Ò.§ØhÃ»ìe™ÙšAb‡‰ßfÃµ+@)còåöV~Pja¥XÏu»È,Jo¨û(øİ¢+­r¾ÿ*Kh_•w=“rdä-ßD(i±#3Ö~‰[MÔ©óÿŞ°çG^<×x¬ú/*eäš×>(›,©}zSÅ7Ó¼$WÊÂ×ägë§	óÂ«-{‡Æ‰XÚ^@@“‚ù«[’$=dÇ?,uRŒ}uÅ~SüçìJÔ¸æıÑËzá4X=DFÖ¿­„×·Ñ³ŠíÚ‡øÕX˜·æı¡ÿKâ‡!şÌ4Iğ#¯<›¿Âş´—çsäïÀKàíò¤5—ÅmévŸãlèE<°gÏø›«¨°)Â4SBjÌ8o*}ÓOdÛ\%ù\ÏQ£w¶œSB‚ßG•ùX-Ùc¢Ê?Än©-zRâëñ…)	] 2Å(µŞi®o)x&”âÄ­ĞqØ!HJ¼¹•nÍÉ`|ÅÑr~Ê±Î'ÑÕ¯·÷\ãlœWQDå?ªU; KaÌûwTÒ²şB†cşı×ÔsH@jİR¤lf:Á`…ú?[ãA.Â™z‹Şùæ[gü|ŞX³@ëâ#ƒaÎÛäÆÑÌh…Q­5ùƒ 8r™ˆÊw2c&Ëúw”ZàÁ”øõ¹ÉÈø‘í+ ùì  H´½«œo'Lìëh€¨B!(z/nxÂ-çÀª-ãŠ+»%–òºœ~>‹¤û¢Õ7£ûúe9WíÔ@>æÉ+¹‚xùE5ÿ‡VGö†ìÄ½8P†eYqd»/f·Ü(BiŞË\!Î&Q[äP_Êàg#Ÿ¦½­²…Œ*kM;é~ØùzøÓ?q %iMĞã«”Ã¥‰•â„r­WlñTRıÖìûó	Ø¬^6Û‹xŸUÚ«3•>…„ÂàD>õ6Cû¹C—¼U:i]zš¹Açq$ÿ·2˜¥‹’uqóJıĞúg§½'
µ3zE’º½ª#i:d øæ¡Ó”]ĞYÙCôª…Dó³ncqRÈƒÆ¡4LÃWX<~ƒcwş‰åÍŒ>V¾2(£$
D‰  ‡Uï †6«¬Xí2ƒú^ÏôD€İeÁ€ğ½^ÿ hG9Ÿ †úá5â¤ƒ'Pi¸òŠI1‚N‚ıŒ¥[B+“kS©áô@.¤G‡û2ûo¿@L
2 :P–àjlÆ;ºî&Á7³¼êD?›Ìfi[`T{_ÆZS¡FiØ#%rBï‚¯lbST=q{1šHìc'N7væÂ”¸ÚJ¶*%rñBÑ¡ÅAG»Œäí:»t?v‚,Q3‹ÆBş 4Æ;Ô±`LfuJif?áÜ×b(i Šèä};+®GûUM2ãOI(]tq`qsÔé%ßvHm›Oƒeù”íX!¬T’°W.ª) C@r¾8³ïúˆ8$óW£Òi°6ÍûnPª61`îlf¢»$½¾ÌIY¿Fö[Û>=ÎØ>³rãª	$ªÍ=Gä°¸eÑ¼O-¼z¹Ú_Cwà¨ÕñˆÒpâËWFn¦~¨“’{%u Š	ÕüĞNŒ]«€YvÅEYûWbœ¨³<Hİ1`Ê»T—¹³Å‰xYŸ®şS­	ÿ+fÕ2şFÌoŒ8Öd+é? Ñ_Qï0I‹œKËB`ı
¶{H0”¶¤íh*2c-¾tòÍT†S'V-’óäf‘™‡$tp~bÏÈ²2É¹^4HŠ%_áUoŞ˜œ€Ìı.¤MöŞWO[<ŞmºÑ8êØ•Jz”p´§á9ÈÉI’
´Ñ™¬T¿R¡2Aİˆ~XN{Y>İ.¶O+å
$‘¯äğõ®>\"] ”/=°ô@†ú¦Jlğh1©¯FQxª¥b¨ß8°Å–‚ê«y¢x&­³HózˆópÆkö©ğ¯’„ÔvŒ@e”9¯=®ÏE®r(‰Ó·xÎW*0Åën‰Õ¶cÇöµ9À¢~ñ<ïÅNp*â’Œv>×z*Ô³èD—Ğíõ§à*„rÎ:FhÊ*»½°ÓÈ¬…' [›OÚÕOb4õÈs¼êC^²!x4…¸šˆê:56j&b=’aZDÖH/¼yFl‹ê|óT[—€Ü"²Ïíıš7n™OÊıÄáÓU‚,ü+séîïkˆŸgfoÍš18Q4vãREşss˜ Ÿ‚WœMègÈÏÙæÀ´§®w2¯¤¢ˆãÏgø,Ğğç "ÅçK¯;ûX©¥’•Òp‹*µ!ŞÓH0ªdøu<jÉŠ#0B$²Tÿ·R—W`Uyi‡¿¹GkIf¸gLW?XlÕ[TgR@À—‡†¾Û„‘È|¢‚0 dâ¶±ÍqìD–¬«yÄ8UFø!ÚÆf{¢ª×0ÍoK>´î¼ä#Ö`XÕp2e%2Võ"¹¦3xÄ0Hd¾€5CàºÈP´½Mæ-W\T„Ì5¢b< ¯ğ	O—­Sæ¹+’ù	kƒáØ^±Öôñ¬.#ã´ß
oß2¥¶j*KIK(UÖT¤pŠ(ôG]†¢N×İAr5sàÒ"aîÂB­ÊØğ½9\OõóOqcê<Ob…‚eO‚’hcIƒ
†]5ŒY´—œÂıJ«Áå±br{l8ZjÇş{¿xÁül–µUÒ!Í)ní9Z×Ï‰„½1¿dwªíÄmƒ¸¢óõÄŸ-ÚöOV“› ìÚQcè›Ã¸şç§Šˆ!j9“†c9W©oÈ³ˆSåãvÇG¸Ñ.@áö­ e­=ƒaõFFP¡ğËEşsOÑ{g·êEJáôr Cì
?6FÕšáK`ö·zSmJpı9àÈ¶€mâ"š³®r¸É!äPëéI\_vÊür¬ëJ„Íƒ¼½awğ»Í:ªcĞôRÄ©¼['ÖŠCî‡ñ/àôš§ézÓœÌŠ4CÏƒ)v¢ş/Sûš÷ÜaSK8·m¶ñ^ÚyÅÇP/{Ç	0¨ Xâè¯äí2»%
7ÛKÆ©&Ü4.u‡‚P N¸û3q¡¯¦‘5³z±ÒHÑ.’ÅÉ‡Jí¿r"x0Pr PJº—±DPvEö¿îıvñ'
×$Ò+¨ÌÈwY¦ œÇHE†%	¸¸GJãÅ¤mX’Té¯'‘æm¥)j ÍTØ¿ÜIP,\ˆRwğOgÓ11°Fù}p-qø\æÓ„è8(îvyi»¡Â¿¥CEÌàˆÒÿ&,‹Qœ…ùpS0ÛUq¡”rgôÕ•ZuXQWûÖ;úŸèâ-"$Çë™.’í×+º0ìÃ_*:x¨’ßÑQÁ(‘µí³*Å÷ãHz>8-ê§K²AAêÿ##¹SËKôtV Œ•óÉ‘s×CS{Ã§ÈbÑëÂÈöÄÔkÅ¨“£§AÚ7ÈGİ3;M¸‡–Ÿëë8ô†	DGiœÓğ§d—ÄÖZ­§•q™iâşÀœv˜T|zí¡Ú;íÂµ!}K,b‡'Ôá% _ÂÅì·ÄİJÓŞÏÚ$ŠCš¶·»p/V[ÛKzùò”„”»wÍÚÌ\µü(Ô¤ 3™÷@Ú4şïÛ+|o8YñjÔ{Ua·şõtfwæcÔ6J¼aRËÔ>µ:í:YèÃl«{ötÃ—<Ôô¾ëïÊĞa@¶Œ\6h”Ğ[3Š‘Öõ÷“8f^2\÷¹sph Ie_éZ=‹µ×
çiév
§¹xV`ú5«d#ß$¬ÊÉR!´¯“Ä´nÖ÷G0s‚ÜyÌ«•sAµÓ³oÖSß¾~ÈåÊÏ<0L0¼Ã-Öö¨Ô/õ³Ñ±îkßN$Š†¤²=Qª÷õƒbd€ÂÇ]/®DÚ)xA¥xXc\ÀÛQkr×FÖÚ VG“ìû«çı„€d`ø£ìÜ¤ m¨p||läœÕ~D‡Ÿû‚z.]·~ ‹b¡ÈñßfMÁ@·f`U)\Ñ[&ïØŞ0iæKr-Ëøëg×Ğ´àÖnmä¶.VŒq;»åc2vÓÍPÖâë±5YŒ¸Œ!,s6
ÒL­<xÜ 8G
 Líîí=ĞXÃ&t¼$¼²&¶„*Ñ[–nït$“âbYöx"_V~cî>ÃênXOvaøDï3}YÃ0¦ğAëfÃ/xq!Øu®Œs[¤kD51ù;V•-{·½¶]x,‘dI(àIú!‚³YOÑmÅ¨…Ò3ï”h÷`}R!&±ÍÏyE ô)“ƒ»¦#ÈÆ]ôÚŠùœÀhbÃÑÌuî•Ÿ3•f²%soây‚QÏí.Fï£d7ê‘D1Ê³=èñê]²]\øE6+> aP/Í:jp®ÒI9¤{00©@zhZZãßp”Ûg:jç²Îù.IûÕ5)‰ö‡¿×Gg¨,J®ãüº˜jQ¦Jˆ/´br]›ÌórèáQô·7µÂ½K] õ…‚Ô°Ü¯sİ×Q.\€héŒì=ÛÌôSÔ:Ú©§Ï¸}\j¯h¥ÜTMü«¼M"ğ–†là€»’s˜ˆljã^YÀgj,•ŞpÌúëŠÚ›1¬ä‚"Bˆİ„å•Ë}eá…vĞŞ‘±>¹;ç¸Ç7MGÄÅK‘±®ol¬W²2m¿o†»u¿ö`Ÿ|¹¶éØ)ĞAGääıÍßX[Ù¦ÄíWP©q9ÅI½=EáÄ¹ÌéÈ¸öí	Âÿ˜2¸~¡×VNÈ‡ŞƒºB¿,ôùĞ*ÚaĞß‘3ª’ÉØH~,•|sòYÜõjªşW,˜‡à2½S™àÎÊ¼îˆÊ0[@¸k8n ×¶`ü¡j1¹~­ÄúÈê{RvvŠG˜†¡ïÿÕ –\@8©qNFå5_z¿\:'Cm\ÂDvÛ[[³V<ÜMw·|mw„àã$mÑ3îŠáâmhPÄMX¼ :¾W²RE'VÑ¹	y{„ñÿ–«@re¶-‰¤»eëf0{÷ÇÃhØ‡$E$ ÜMÀkI"?QÜÎpq,ÙE…¤Ñ¿ó(Ó®l3ÄxŠªLcOX×P ÛLm¶é`†´óhHèªÌıÚivÚã…UUÌ§*¹0ÇÄŸ½ÿ@Íÿ¹ÊÆ¾bÔÆC¬O“l"	9W­{Qñ£Ş˜>‘Ş’ÏÃ­³½âÖ<şçQ:y! ğÒA\6%İvÔí<Ï^aÕ7˜å]Ô¼íO]ÁjßâŸDÕÖ9bØ2àº‘ÛNûË®>``jVäg–/iXó.½^Ó<_LQğµnwÈS&4¿uìr[ 7‹n“FÌ9+±A67íË™\‘Tb´xh¬ˆ3‡$Å¢@ó½K>\o¨ñÉîÕ+¿G#ÈQ0=Á¦˜~o+Œ‹$®gƒ Ã˜ÆDü•SĞ`ß8r2¤«^&1Üˆ˜~¯kpÖ÷^šú’Y!éÅ½G!ÏŠ„øb30`µiª°­°´i¥œ5ã™ÔÜ<|VÜp,î~ş\yNX”üÓƒFªˆ$)¿Ôï÷ít*l¹-`Ì'öVn‚›° ğMÕ9GVáŠmŠöuÙ•å’#…¡îb5•ÄÁN1
‡5gŸ3‘#}ê¹èÈå1¬)À;w[ƒoT¥¶tÏoÌ»Q§8ÁÆbßãÕê¥Ò€NG9‘‡9»åc©ô3ÈA¯5¹BáœË1Hî,­MZq~Òää-ò².Ÿ¹ªí˜	wÕ‡Í"7 XŸå§äë›Kè%;ĞP.sŸ[Y_M.øÇPYvÛ²*aï	‚ûzè¸ƒEøúó"ô(îyõ4Şå}•‰Ì˜¶T)Å7À€zÆ]
 ±Y5’G)—lóÚÙi¹2Ì…ŒL¸Ötã}îv -É÷k]2›É­Yóí\³h$´4èÇ¿@À
)è¦Ë*’½ Ğ`¾ºYrÔ ¦fû·-°¯¸½ˆ5 ­Ş¾È?/ ­ÕMyß.ipRÒ0î,˜Âš\ñÙFo^[Ëdáû
åQ~ÑP™Ú™íÂ…€¢1·bXÀç˜õ¤ñ„4×öö´R|uÜ_ÏXL©¡ÌI5òŒ‰–5¾ò€¾Ì.ı²y Bn~Î'ø~Âq$‡_@øMç"8†èÁp\Çß_O$ÈœáÀƒâ1×îÄë÷CÅõR9ÕgBÌÃ5:·Ù”<ä®õ€ø„¢ ÎÅ"kÁ@v…LœÍ¸¨a¦	ŠíQ¶f…N½úôı¢TâuüV£?ƒH³ÈÂ&x«ªz ÿñÙå¾œÌ+Ôµ~µº­Uk®rSæŠh=¼ŞéˆÑ‚¶º¶z®1Ì¬¥‹® »œ11×£_Kø3ë×]AU•~¥PÿÈIiaÎ
İNøèòâÜ%†Ş]zióÂ¯q•-2dLY¹[,§î¯¡eŸb Ù.Ş JëH*ÅÒáäÉªKÍWl³ÒBdzq‚[ÓÚ¤UDÊ@V!T|úw„KëŒv€¬!ël¼YËVÙö¥©nP…°æş/¶q,€ÏÅ5LÚœÚÈKáŸŞ4Ü8KOPR]ıîw4i*szk±
=n† —!,«{}ò
MJdÂy´ÈØ:oE9ıGu´{n]ıQËÖó–qì©75,{O?uî^*óÁáù[—FdÛ…c†™Š”iÆhS¹÷rjò:1–u~|Åä¯;ÃE7ª‰PÙ\œ¶œ\ -m æU{L÷ãËätşÌ5Ü‹‡Ev~–htVmbJË—qÎ¿‰Ç+|MP­K÷f†LÂ‚(fµÄ…›ZÛh®®Æƒ<®O˜+»˜ÃÀÂŞ»~öe}1¸.eŠüÎ…|üÓÇ +Lz®{Dš9O Œ6 ­ÆF¡È.Ñ¼RÇÂÄ§¼0gÁîs°ÔÖ\ÿyjl Z@-•ı‰Ê",
] nşô¸p ±'|Ò™pD“„»yÔ/¿îáÚß8‰?öSæd5ÚU(p¹“lâ’ù¥/t@±œc¶£Ó¬[K—¼Š)ë%ü[lˆ’KÙÚ±"cA_ŞL+aÏÕvùÑ_úàÓŞ˜ßĞ‚\»BÃ·¢DM!å³Ï.#İD†OÃ7lºÉä2•Éû³½ÇÂ¯jÚ!Üjnbro®XÚğyĞF Ûeo$Kón«bäÓİn zË6=‰˜@jìæË.‡1ÉmWøSOY¦;²´íx¡Õ¹šû±=Ú‘)ã”•v0»ÄÌ«°¬<^Å–”P¨‡,SÙt@ÄçAÂ±y$™³;7wXI®ØšğUïr ëÍ2
„Éœæ’ògOäoY–KWµ¢œ
ĞzÎ@À0y&®äÆ¯W[+Ùôd¶
ƒ‡Pìï	Oã¡F×Õ”SºT¡¬‹!ßÀñä;ûÔd4@ò–{¯Œ3j«›¸ „½ïÍüÁ.PÁQ¨ãyíZòL”`Ş5yyˆğ€àë‡/ê³Å¾ÅL%y°­mûñIæ¡bñTSæ$ÔÎfy4vôÕ“ynH:ÁévãEÕHz
İ¡Òè„bé
]œc?$è®&w ÆÊÅĞ²ù“F<2¡UŠ0.>oÅDãhn&aZ*­¹Ê<4ù“è,ní-şBÜOsÅÅç *¬Ş0²6F„”zNdÖ…ÖFMÚ?ÀÍ´é:¨„H*lC}GH”Zú±=Ğ¶ˆ°uk®–â&°ñÃQ9êç¥zˆ2ÌPh™Xõ¥!ÄEÅk™VéÇT—VkBŸ¢LmxÀ—x'‰Ï½7ÜW2ÅoĞõ.°ú…ÙW³õÎ‘Ñ½TYø2))‰¶ÕTëœ’{aZ”v.›¾±Z^B¿AjyÃá
=!×š_Ãúd+˜7_UÛ7Ô^…ZNÃ¾’2Qgµw²Ïô’"<ù(tµH!?8ÄÀ£çÆrá|ÛçšPPbF.ÆCJ÷ƒ||–h¥N²íÏidä£ÓüÅGb<İLÒİÎ“ÑıpŞ…ŸS!×ÕYIşToUQE2I´<EùLŸ•z(ªÄvÃT r*OMg»3LD·ZêŸ®·‹yC;ñl	X“Ô”teìPi5Û+F$¬¸Yj\ïkñDU7ú`…²øïa{Qü_5–4âYYıˆÇ+Sæ0fÆÃ³Â@\géëú¢ ĞØ¥Vºy¦
ä¦£KUs˜=Ğx Õ¬h]¤XFòĞÀúÄ""—8ÊpHè­* ÏA³ Kı¬J6	LÛ¼Ã–¡Xw`-]ƒ~<±X	nèæP`Ë@"ì£¦ØH2z×Ñ’¯•¬v±únQİ<çÜÊ(?:UÏ¡I™ñÔu!V
2™/äY+°/·›ş³É¤m£FYË½Æ!àò—íNúiÉÿÌ$ÂØïRçRÕ™H~¯èsÆñ—ìåâ‘–ôD¨°J5`»=6õ¿ªfp»Öy<¦^ó“gŞ×vŠéŞ‘™%ÿº^aéèÌ9üŸ>”û^oŠ#¯ËÓT(];hög©]ëÔÙS„ËÏ–$áõnì‚Ø”Í.£¯ğûEÜiJÚÀ4vm…ñ8ÏP•Q®¨àöÎO—ï‘÷ª/ËúrU4ŒÂû/Ñ*~H9í|›)—S½˜_î¸ÿ
P23?c9İ/fŠ1Ãz ¥…9†„©‚vœ™uãÁ:m´/åw‘÷?nÎ¥<ÈRP”4úËW‡,	5ÚóDŞ(º¥'Şi©ö_éìJ1äŒ­Is0òï-pmèÖbÃâ…"Á4¾Úû9³ù¥AŞ“ól}3)P‘ Êw._OŸá@¥P`#.„¹Şåp–$ñé*nx¥ş@èü\jíòyY‰5=»ËÚQ'’É0}Rzd"Š”!Ùİª v/qI®ÆGÙ÷w¢4µ&Ö"èí)Ğ«·@ÓÓÍ¹‹ƒ¦#<,X6âMGyçÍ‰Vèl5ÙH°q8ªÀOã¿êÏ%FMª‡oåD”ìŞ£%™«™Ê §/.ò­CO³&‚`FhğLó”@Qq†³ät8ü¼ºÃ¿0Ù; ×{Ø/‘]é±ë†8)¯§Kı
¿KrEN¹´Ò|VĞÅ'?‡e»ëèƒÊ
ó†Şèö¶ş‚†,l¾1£zÌX’Ù§#V±nEÁgZªGW¬›BÜÓÿj¦mßˆKËúÂ’?ö•ÿ«ÄÔnÂJ?¥S{Ùû|L­ Ê]>‘ä`%ëÒ?ëNS:ˆjÂ=áıŠYMÜ2aOtn³úà‡iKÛÖ›^mj_ç¤Z£#¯Õ^«ÁÙÈşğêòªeb‘í=›"]WÔ\_Åÿ»îÛí34n:¤“'ã@kõZ"~S§ñ’™ı
C}¯iØÛ$ÏåÛËCh(BŒÖ’vÆ˜ Aàè?¢N¨D½AyÉİ²Ÿ¼ÿ³Iÿÿ³bü·z5rÊÑYu#ì¬Ì¨Öú†²E§ğ=Á×!VÂtÑ7-¿‘ììñp›>$¡Ëh‘/{¥èÉÀÖ½œ‡cD‘|>Ù«GØHñµİÖ@w‰› ±@ñj',1…¿¸6†ã3wéÎd}ÏdÈ
›Ÿï˜$dBK\ÇıÕµ™p6ihÑ„ï=vk@h0Ê×[·ƒÙÚL%ËcÅzçõÊyğÒØ¥2 Äì!+qÙw5Ûä)GˆL”6Ä¯áÖó”BØPLÚéìE¦n ¬Ğ17ßØ–´ïX‹KĞ-}İØy0¦¤7VëîğÃµß5S/tª—«P(-D §a]·K}gI~&‘w—ÍÇJØşÒá0a=vß¤?¦ µ:¨}² gRXàCV‘yeê"ÙÉ=ìÑ.¿nùÇ> s‚³³^Ş*ï¿7jˆëÒõÓŸ€ûNÊ²Ñ1İİõî<Ø†Òş½qôËJ³h[Xl‚×Î§€§Oí@oY©úQùö¢‹b(rj9”ö|0iÛNº¼HÉ´éİIã»3â‰¦ÅÛI–Æ‡Á³½ˆ(„l	°Õş“À-k=›Ú8$[Ä*~ó,@Y¶:ËÖë'á[j·+f¸ò‘ÑI"62²‡)ºD“WbŒMè±Éä”£Ñµ­8<h;"ßÑ•mxN“Ô††–^‡UéMYŒo»%bŠlŠÎ™’—GıÎ!sl833¾Hÿvy¾¤I(¦PQÎ]X¼÷1P¼¼+ª†s–ÈœÅğ‡ ½GL\}rvƒvıÏbşâ'y¶7‹2iºÔ©2=Â#ƒÜU"¬‰¶†fIF‡qh”ymQ¢ pôĞ7^F¾»–ÊÛ’»qƒam(‚ÌıF½ü†ë³Šw°ƒ­Tœ`áğ6ã©—mQ¡¼Ï#ux¥ÉüÑ¯¦®¦fš÷ƒ( ÎSêl•AoÚ#9™‰õ=Ëô+§•m¸ô”œ°]­:ª<r{»Ò±^lî§èãîå¤Ã{l>Ò5f
Ÿ¸Xà¶ AK\”äW‚q*_/M¾ø½¾4®­šÀD­Øˆ(˜Ç1›H œ‡9ªM|ÕûMcé”Ô€Y‘ÑhÒPb¾
‡*‰q7›3¬?ø„İò@nf-á2¿]Zænmã~É…yÿ|ócÙâfXU]Ä—%’ãÅØáj?«êœ(6òZ›µePÄ\NCÁÓ6Ğÿ7/l‡©_gˆRx›ãÆ¤Fã¸Âf™â£¾|¿è½oÃ7;÷E <
“”(Ñ9øR8ı°·bÏ:DÇÇeÂ»M¹ÔÉ˜»råî¾â
íÁ‹"cÉ-İp ÚKÕ˜ıù%@Ğô´æä¥Åà ‹Æ5ºÈàúÈÁ	 :ÂDs5úø÷‘iäKw´ãŞª§Š‘Ò|°Iv8ê÷áü¬6wqöœËÚæÈ‡¡òOú°òšôÑ¶+çĞ(©sßt:.’”
uÎƒÃh
•×XÄOI:´®ÇÚÌ½Ÿé`ğ{‚? ¯Şc¡ÁÌ³Œ¢/¬ÆÍÇ\¾1ô<qÿØXàÎ ?Ë»/#¬8°=8‡ò~‚øx»!GÑ”—}ë[‰yÃdBÀşŒN@¬M€ÃYÚÔ…Oƒåb¹mµmp¾Ãñ)­‘Ì\[§@½8:ÓÂú4Cş;gö;º¯ƒ¹˜ioÆU¢kõ8tÌihÅ;5ä%M×á>A%û&İrƒ”\€ì!=ŸÌ
ÌttÌÃS™ôI-Âµìãé–¬‚#´saBÖ0ÑtİßÆVh,7„eU8÷Pö–®x³Åë×MvÉb´øåR:J÷ ¨Ğ.—ˆ¯¸‘3²ã,ùµÕ×Ö…³¡ëÚ®\jÀ1{vËd“¹£‹²ˆğ¿VJ9ø5?<cåw"É"$;ÛjŠĞì˜PNJ2öı´X÷$3tZ¬Q?ı¤úĞ´PĞß÷Ëù»—2‰–b¾×Â‚Ò=R¬çÈ1äd@åhNš<Z.ö5n~úÃ´@å)LİˆšŸæ’¿MZ@…¢æ{.$xNs`!.wuy`ËÄK+\áã×°tşÿ‡óaµ8»Ñ°‰Š\ß„¿I¨g.ºG×sá˜ÄÛy"·T™$Xº/Ã÷Æ Z½Ór«ƒk¯ıÜzñûÆp(KªWÙu‚…ÀÇT_ìıWìÌú>@À›	À"¡_Á²8´Kªóßÿ[Á<ô2M'1sUXXÙúö—ìÌÊøöQ½öuXh#+“ìüÌvZ¤¯¦óŸÈpßQ“ØŒĞ9 ¯M°ÀÚüSë*]Û­ÏQ'5u¼VÒë+÷q’,kzá}õ_ßhÆ4Öœƒ•ızĞœ“«.pwğ0ò8¹#O§«¿ÛÚCZaøqıôJ×T>J"í)}°Ô ²ãUM^LÜ@,X3Dµ°´ïşÓFZĞÇVMv'¥”!¨/7‚¹|ÑT²
š×¥´®(jBqi¥€Ëú×@D¸0&Õi§|y-‰z
Ì³›:À¦Ã$Èæ,Ïªï|²Ÿ¥8VŒQ›LşâYrFÆïv5p\±,3Ùgu–;gåÒI§*Ê—µ#Ò‘9WƒAÁø5±ìEi?gò9yEŒÄ8—¥v­ÌÂûtİ7]~Ø?Àæ±¬¡ó7ãK]ÚÄªR¡ëEIµ[yÎXÇİç>v3OĞMÎ×€ÏS¢“f€ehU©ñÚ–¹ÀY$´ÿƒÛu·Ë§‰şòExÏzÀ£°É¦¼^|By±İúÔ9M=@Ã!ßÏ4ïÒ5JÍ~8½,Hÿ. ´¨WbøcçĞ*'³BÑÒÊO”ƒ\f¥âŞcÑ£ê2ı¦LG›UIÅ@¦‚]{/D`Öü]æœ)Íi<OâŒØ
Ã'±”Øêñ_Ø˜FPÅÔC;:zâ…Ù	¹.döºÒ.OaGº\HÌZ
w ò1‡Št°öçG ˜É€îGòÃ1ÏùJşÂ·ÜgÁoD(#‹u =qutì%Ï×GC¶ÕÇ(x°£ø¹ ºò>ã@Júô=ã¿ßïü	-¹4L?Ø­ê×<O\C¯èK=ë0ô;†““³¿3+7$ DT]Ú§ŠÍ{¬}Ê÷kÊh“(·dYGŠc­| hñ…1r3È”YZ%RÁáIál´|ğí‰+õÂÕò4lÕÁÒs±ŒH$|Ø¿ú{İ³ôWšEKli¢D
À¼MŸÃuU¢É‰&ğ­İôLÓjr,ìz±zXE£¸õê÷T–¯,	Ô‘³ù¢,¥8¨Ímraõğ÷úrë¦IÕôs`$F²réô*½]_‘ü~ˆAŠmÑa7?ÓµLo1&×qö)›û‰tÃp„}9ìgÁq]¦4ne4çïôùòu¤¹++µÔ¶7%à…	Ê‚·í¦‰˜RØ&{ØÌª<‚Çº,1ÕŠÕ¹éAÊjÄVhÕÄ˜8Ëa§¨~b›‚ÌÅäT—Ñ¥œVZç±N‚Â¿vî	‡óÕ‘²¨èÉP`~º™óHTœ–  d€„Ï¿oœù¬80GG@é#éDKI „Q'&e™–]Ğ&QaŠ}¥9jæˆêÑÄúƒÖóı÷ áštIAªU gm_½uI;ö(v¦ë•øøÖ­X[µ”L©=¨+‰#U—ıå»Â?†ÚÏWšL,İï»fn!¶hBßÊ‚ùh¡D=ë›.nËƒK=ws6iEåÎ83fQ²hÁH˜H†#*µÌßN´kJ^µ‘=,‹xqÃ¯0iè’.Ö!Š‚uûÎÓTó(*|+ŠcÚ¼JA p=TÑ\³­Ğ)à(-ÁÖj¨˜YÓêñJsıÙéQ\Õ0•Ë”zu4+‘`»Ø¹s$Fòç‘­åŒ(¹”\,•Go¸ş^·~%¦ãÈÂ2¸×“Ø&[Ğ $³»'™ ã·˜A‘>‡B²¿}ÒõŒÎ2Ë.I½i-4z«wqmŸ2@†}äã(j+øZúgf@:Ì¯ÿ Ù»ÄÔ¨S¸C0EK,C†Î	a3iGCÏ“UÀ:‚ë)]Æ¹½rA^@U	h:xëñlu¤~4vi:ƒòFáË²(Mä~+äå³©ê<!¸L†c=GRÿ*; "BZ
ĞÅxÃ¾!læÄ¥`ÛAÒÑJ²<"S_$¥cR« cºÎÖ·~ö¹ÏÚ•JıÛFĞeo¢£OªM8Áa¼¯~ër¯z5}cÕÅY]a¸ ËüÑÁğŠÁêÑewé¹À/Ø‡ ó¢Eë“¹1Íéè¹½Â‡¯IA‘’wNb©ò<xk“Sôí¾­ïŸŸi¼I˜À€Y@—â²–ô£ [úGy°`d·ÿÒÓf00òè)>¢if:g
ÆÛEB»³xaƒ Š4ôô9:/½{™>¯"JmYúÕzÏF‘ÔÄ:¼´Bá5‚Œd6ÕF’áÆYÛ:+ìíçTCßƒv,‘ àér7ãy(N%%ÎÑz4v‹ò«qÜ'”‚_b`q]!-å FvšÁîÜG¢Ø>6Ã¿“‚|Fè/·„;õô>X0•¼<{túî7=òKz•ô ¹j×$aİıëåÂØ Gæ±ùr’ºuƒyKÅ³µ4#?ÔlÃû`Y¤£‡¹š²‰à8©íå4Ï=ª“âp|É+ÑAÈRvmcèy¦g^fâ_iß*Í‚£7ÔH.Ê´W–õX@\Iåÿ8”À“âäí8øç/M>'èív”$œ©Bw€†t”A™¨(	”¬NøÈzóèXšXÁP-»Ü¸„Kìµ¤ù´Ršj[W5_ÇüÎ„İ»úÌŞÎ¯»§2Ã8~À¾ÆÛˆırÌíŒƒ´¹È Bş¬Ú0è=ZßŞ+VS¹{ïÅÖÎ
iø˜â FÆ3îl"ÏWS}ªz°¼Lº¦a¾d¬x€Yˆ (‚ILÄ“Ò…ÍÁõ „Y2Dõâã™Çš”àºı1zâà:yÊÙÀÑ¦ë±p3Òá×áz¯Ò‡ÍahÌ÷Ş‰2š‘´˜8ÑŞäşŞH#¥SÕ³„‡5@»"%ÂÅÏ”ÇãY&:˜Ò3+'×ÚŸËÓ§Ìç€Pç¯*}Å‚â¼kL£Ÿ)¾P3´_òÙV]"P™Q’ÿ¤ï¡©Xnšª×FZ¶ßDâj00’«l
÷¦,½r%ŞQG¶úü>)@2õaÃõ­
Ñ¡p$7²5ù4Gë&S¬£âÏ(ÿıŒßRpÙ4•ZSâd‚½WàU~K¥Ä²<‰¨‰jL¯Ø‘æË–nó\¯Špr:•UùŒ÷÷I%¢ÌÄË]¦¬s:ñbİUŒæXÔpXáö±(¸GLµ¹e(¯n*@ÖûvÏÅ–iˆ»ØØLúßÚÍÃˆ«®*…<å§ftc]ùj!êÜ¿=2X‹å¢Ø½È·Úñ9–­Šˆşü,°]û0gı´pC¾=ñG&ÈğmTØÂygw\eô#úfj³0dùVß”[›YË—°Ÿ9ùóhs©Úª¾‚DÓtñş1$òDŞ:UÔîø7(y¯¡&ÅqƒştÇÑ²tJÚº°kùËnCÙ7uè­oì‡­pTd–h¤Ÿ±¸È‡çµÄ7úüµûU9ğ~°rƒäÃ@’w}½é¶bbÉ»ºĞH(3"u'^	·{dk,I2V¤Cz>‡n$¬]ó¬l@ûŒoÅÉ[V¶bö\šĞ´éº‚\¡Àß§:ÖnO>±.‡¶”‡Ö)€µÌ³™·&<[ï'¨º_àU11&h¨OßéÒp²ºAït(A–À4ûxó
PziVü!õâWÛÚˆå1zUc¿;£I†G5@ÏrµÓĞU}á!x¨dDT‰‰£Qò^”9ñ<T	–¸šèˆziŠœŠùS- Àı˜{A$±ÁÆÑ£]C	Û	q.Ùu;A–Ğ¿­¢¦ëröÁp Ö­àY›Ğ8§±Øããö1Fºüt ¼ıÀNªv~}5qÅÙÛs¹CØŠÑöé¾=Wé¸z½U\ä5#ºç¶¤ª(ëdr#V¹˜ÓVkš<­Ş€“î]Bkx÷6&¤ab‹$²!r0ÿ±’>ÆVâúü·KŒÎˆYÀ‰©İÔ«}qhƒiª
$U°©˜)¼š(?¦¿ºÃ˜û+œœ¥‰)åà-<9Éæ#;ñâZÓ“7PÜ€ªk—ö‰š\—De²ÄÉ“ï¥'v©ìN†?\‚s{×yEÔõÇtîºV	˜…&·†!aZàí»ï>]%‰½ŒI[¿^+7âñ†9øjfÎv“Íš¨5ĞÃrı5X†jMÉÇ}ë—†7½±yäœåJß˜û$‘š(úZÀdAEHÜ,¹ ËÜv_]âjŞ:Rû¡¢`ÓŒ·>C!ŞóÙÉLy‰Ù¢v1’Ğ3@¹\±gIŠä ²¤)é÷…ÖÚ´4Ò¯£µˆ-0à¦ 9ªmw¸ĞzÂÃ'šgµÚ)kU_¼Ğ{©
ñqY.ÅÔ¹Ï—0
ß€™ÚKàÛŠ0 §’’Œ¢\rÎgB\£§ŠQŸôµÇ"mÏ¶dü«ï5…Õdbòí¢ßƒ>‘2%Ñ
ÉqP…«¯°1˜PÁT;kÌeÈ[7R[h®}¢Š÷˜8Æ™´ın` ;'f âsr˜&äÖŒ³–bÇdGøÃc›$nÌ>¸åAìêâÕ>p×8·¸ş:æü»N5‘GÔ;vwu5¶¦ú]MëbSWi#®†ß©nÜiâõòAß
?¹›Vz¬¥ED^H*’—ÑT¨6?K$¿Kò4UªöÕˆë3Õ…ı•JZãHºGoùñŞµÉ·®«–×ORdÍß>ÊLSÆ³ÇúmK(ˆ¿—¥Äf:s1‡*¤ Sğ 	F>È¼úÇ4©#41ØyÈ±T*Av.½ÔaËÿîˆùÔÍ©j\›|òµˆİ‹ì•y°gÈéš½L$@q¸Ákø(í·àŞH;VóÌæX°«=¶ë
Û³•Œ*^Ë>×á#¡IrÑ&¡‰²ƒ x)IÂÁ°W²¬.5°W
ìPœÛö½5¡ğĞÎ­Ä` T‘˜äPz$Ç4Ì(?´|û«¡k9°ê·ÙàyªLÚcÂW}AèÍˆõÁ/—Å[s2ÒûnkHçè(ãšZ‚™2í5©x6P\æ‰g?ah‘0æC^8ßéµ¢‰Ôb—ØÏ°C)ìÕ!îÇ»Y›Sõãf oØkrXl“ïNÑ¦U›ÖUxow<ïÍN¶³Q<ÉcÜP.µÊ×! >ÑmÇ¶‚Kÿf>¸Aô©f) Û5¨Ô1ÀYş$Ï“'DåĞÅ]Èû	¢vï	å L¸¡k0°ğôÛCçèkËM::D şaÜx—]àzR²¹Ÿ›«óÑ§úøÕ4›>•±Óª1ÏM"ÅÂZgI1)Ä™Ÿ•²’N´’34oÁŠ…îË!Q)}„Ùş Ğ,BLB‹½&+¡¨Ï`½¢øşÎô‚ÚrìÏÈ*ï¥['‘}ş³VÜåœ4øjï|Áü°AÈM

wrŒÔ«ıHrA[íıâaÃgSŸQá?Œk¢ˆ—%“º5Ûœ¸Ú|ÙW!.U$qÏ˜“RGÏHBJyŞ)—c*–`‡ßåDMä~‚M
>†H@"JÚ›D®àhù«1^Ë1b ²ëœ…¶Ô•pñç÷|Û,ZU1ûŸ`ÄÅZ£ÂÅ‡rÂ-^ü'\™¸çû“PÜlFÌ@Q'ì5ˆ+sâÁ©µ"ä‹×´†Ğ•æqí,$öº=â³L—ª´€(uèH¢ÈĞ»$®¾èØş¶K˜âˆL&ani)¨Ãâ^Yi¿šBZê+p+-–ßÚ‰ç¹	ÕƒÕ÷Ï—êcG¤æFb˜Ù¶½Ç²YhG×SU$Ş–sÈgE÷ã#õe Ö´µ?;˜›xJğÊJâj¿À_údğ(kÑ8¨SóE í3SE›*·]`›?A||'½"CWi5iğ¿dçl¹«^Y7e[ĞÜ²-ç}T0éá²\‚ÃÊ “ıR©œ{¯ªE$?©´ö‘¡NxÔ»‚ÕğÖ3æñ…§ÌkJ¬öê•š²!’ÛsÏ	¨+ƒÁ:îÕ¾Ì(È´õ1’ƒØV
j|©.-Ásò’=@/°vä¤WÓÄbÒømû,ú¶µ,õvu/)¤ğ6«Lˆ¥9¹Â^ï«Ò“åy˜§1äEÒf–^X$ìÄÚºYİëw¾"À…aOè¨¾z)öÉH„8C™!ùså»¿¸#K?Vaó“²¢YøK»7d¡ ˜ÄŸ)ñ±õô\»KÄ¡ÌJöwE˜©ê q”·Xl¨Ó·ÀÀ€äs’Â¼mñ‘:ˆŸTÌÌĞû+9ÿe¼›Ùã²m*¼qÒt¢Ej¤èYÕß¦ñIr~ÇU¬àriú‹Ki»g¤{OhwEx|G{–ü¥E&Í#µ	‰×æ„rŠy­gÑ'‘##Š!hÀ
üŞK+•8Ùàn„?N°!´GßªzA¹tÎ&Ñ²HÀ°{q°Ì™8q\™‹şÑ»Ù˜zGf3k¶3Ší?û©³Ì'î…™¬g£Òš1•X&‹hœ½ä	3f%
[Ò»oª¢2Æ’ˆª	ùØ±¹‚yQ÷~eŸÉ71ÌÜS~l3_—q_{(*¸-Îgyƒ…WËyør}ùJş.ynMßuÎÑ}ŞU'PÛFÔEt…åï£b>|×N‹CØ¢;‹\"Ô ı”€}NÂ‹üÆ®›-ÚäÑÇ™&q¥7€¼„ñü2ÈR_1¸ôÇï³*çï?f7Ò×9Ks¹3j*ê>ø,úƒ‰»½‡·ÆI“AÖMš-|ÑHÀsm€ìÛ,T,ä+‰éWV’ü4‰já·p[M‘û–iá»#²¥®ÙDÓ„ÃÉ"HŞ˜Ià­~M¬¦¹7mDĞ`ÂmïnÊ«B~Xı*Ê¾ŞÅ¦Ê'FüjÓL‰<ä9åvŠµYtÜâ×—Ô¿òètÿ÷{c³²Ùì>HĞ%6ìÒ*0óğ’©KGkeæ­ùú›§5ãxk÷*|H2)lÚî¨–ÙŒVİNÕ3“¤àöíõ”-¯Œ-ÎÒã•ù‘Ö‰Ü0“bX>Ôä}¥XA”’¶Š–3{`È)ƒ'PSjò'ÈQkºIP	2ŸˆÖJ¢ö×Ú®'²Éï†İ$g‡×6kqÄê'Ií¡¥8¸+OûUtÄ?“OW5åYL! ¯aı`|à½Î'4l~Ş÷ù×©Õ2ëªä‡>Ãâ°š`¾Áşk×ƒìgE` ÓBè"$Ÿ¶ğS7‹-‰À·ê¾lgÛ†Äñk6â´·y8ù" Ù©œ©Ì¾ëİ\Œô±óû¸2›D==«Î+®iæe¥t¹sZÔÂ¯.DHr%¸FX ŞŒ¥L¨Ø±Íœö˜ä«£eÛ“Àp?$‚4œ€{4«8&¶æU”äÂï»Ó~=pêŒ×­èÚ’&SiÍ’óEé‡ï!‘9f‹ÔŞ‰©Hz€ÛÍ§×¨¶EâğÇ"°03“âmĞ…¨è„ÌÓB@+ì7`4ŠÀ´lÏ´©óÖèÔè$‚]ğ…‘ü	Œ“Ê ±gìgëì‚œÖ•ú5j÷Õ?±/.f¼+$s¸É<Ù)Q™PË¹…ü¿ˆå
«²°ûÇØğY‡r´“ÈìÒ´Áä)eV‚`2Ü3e«ÛêR&¼½ô1Ùõdœş?µNwÔuàOçÚ÷ÁüÒóÌMü/ 
hHW÷“aËˆ9ŸW\s£y Ï`vhùÄµ_œ’ _ªÇÏKeş¢Ü05C#\põ ò!‘[”‡€­š¹ˆ•'’û†„Nàbìêı1%µ;˜BÌôhë¹Æj¿ İjëjêŸ Ä0¤ê%÷{–ïòÅZOc”®!EÕ›ğú‡U…ö,şi-
M(†£ºETé€[ïqiõ´>
)BÍnØ‰àá´~jCÀÃ	·ÖÇá˜4î–ÃÈLÆ‚ï¬±#uı'ëÇÑ4r«¦~¢iŠGX^€ØQÍÒ±%"—ÍáÆ«Ùáa8KWA[K$±!ÿ5‰˜!O#>_Œ&çØû)A—ÕÈ`T'—ñ$ËÑE¨kã6LŠ°GÌ·®ìà´ŠU™ c±°m§Ì?KrşH»µJúKòD;ºô*¤ç,v@m@›<Tb2ä©%aš%îã«ÃøÂ	m¸ÕµPIùÉJšõi/ı~éi[´M]HÛì±G[·ôNFP“Áà+§¢„&–ˆ“KÁ°¼aD¸¬­ïÕæTèDÅ¨ÿ3¯^‘{ñ¦|âbT+ÂfMô[Ğ°ıšÓTÚµC˜\Ò)<½Õ	¯>ßa”5oF@ôÀƒà|¹æÏÒ_û‘p—È=àgÍ¼m¬²Š¹44[.‡B³4bÒOd8tWêØİ™Ã![ošÃdîª<ª±ãbëîF   ÊŸ÷S•I »¸€À¶JøŸ±Ägû    YZ