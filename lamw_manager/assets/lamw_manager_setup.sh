#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3730462219"
MD5="07b6e6a37e308fead057ccf8ca787b76"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23076"
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
	echo Date of packaging: Sat Jul 31 17:14:49 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿYâ] ¼}•À1Dd]‡Á›PætİDö`Û'åç³İÀóØ~fÛ§&/¸ÀkÖH\¨±´XÅvFá(C|T\ğ5Ö`›½_ÃØ•9V6ú²fÚ_Û€S2­ŞêÔt"‰æº¯";På„±[o“sòD	Å²áÉèÎg3ˆÚ¿öeŸÈ›K	IfuK*òz<¬”$ }®a&9Q€`Rû=¾”˜MKßi#"ÃãÊĞj‚Ãô½JÆDf›r+öä7¯Bi³0”=éä…ÓbK§q‰ï¯,ÊºÏĞ*XÕ³eˆÙGÕZ(—İäğ¢WWøk ©Ôÿ—y^¬l"†‡@¥_Wã+6Q<‘:Ê0Gº8aƒ’¾	{bÓ“šúFŸ£êÏç…oÙ>Gº˜LVñ|TLS` èâÃÆ~òıwˆËO‰÷Ù„ğÙ°§bOl•c!åÆ°D5Åó¬'¦2FJ>ËÜ»JN´·Z²¦ÄH(“°êêÛõËãS?óÙ8vB7ÏVÌM©³öq&
ÊçÇÄ:ËAFQ{ì–´ºœøã±E#lb6îä±•×ô2yú»£+ó°¢Ä%ı{Ô´E€*ÎŒµúBuÕ± ¨aÕ„TH‚:%ÍÎX$¯ÄŸz+d± d­Ï¤ŠòŞ_±ÉùšbH¤sÏHsA¯ÇÆ±óæ±ÔmíÆ˜DÍØËÇj@(…!qGiö-@X²xo¿Ë¼	™ñ¹àÍš¹Cñw(q»ƒöxôÎ;›¢²±T½eĞ«/ccúãí©Ïÿc~;)S¢á-Ëí¹)Êä½ƒ¶·‰©çë#"¥§€qyHX6ã’6çÀwúŒÙ&løp–G´“™0±ø=*©³!c•v&ñĞOüê›R‡ÊÎò]`tFEœÁ‡vôª]a¡i¶~º|GŠü1gp¤şşOU+[‡q(ø—U:@Õ{ìüôˆf×î)%¶ÌÿÑ“t‚kË”Ëç	ìÙ//©‡İò½‰¾{|™8Ï¬Ñµx^ôÁ—îcË“äMSÿ€çgæó’Ö…c;ßĞv˜ãØ£ ªÍ¼x.Jó®§•3q] µéGU¥ğ¡ Wf9®&,2°<ˆÌ ù×F!AÿÌBÊyÔ¦)ãŞ¼ Ğ¥ú¹káOıv•äÛ¾êóÅF8ÜT‹õ"¸'v\›,¸ûTâU¥Hå{¢ß¡BO…Fãt3¬ŠÏ%Ô¯Èl2ì!F@FÏ§ş.Ü7	fe-I|·ŒÅ§¼7˜a–ä—æ)SÊßLR[µdÁÃ)ÃeâGÛ·Şˆy§Ñ#i!l.nÇLH.UKj7îS×©›’TÍë‡†€‹<A™ØŠA³Ò|R3uLš”}îAgÕ¥yµù_dÚGÍôâLı‹â¡(•‘Û‡ ©i´=‘M³­ÈoÿH«H{ØåƒŞÑdKÄ áà™¶N”ş%‘ÉŠSÊ_Zó[g4"=§mìfÌ*hP9%,búö­!Ó»•m~
¬Ç>ˆ´ şfÀ\p¯šgÑDÀØõLAïF¸«LÉ»û4
©éT…h—;Çáÿf¨’åeÕCo5]kˆUÅñ¾Õ7oÛó¤Œyxì·ÛÙc£õLUXñ•âkfŒìßxÖş#o‡{Ï¬½E‘òÚî0ó?Ì­›“üÂñc^Ù†9«Ÿxè¯C¹phfûü-âüj"u£ï·kç2Š?A¦ÀØË—kk2ñçqğŸ7A=ïµCªZØnë•®ÍL¬£ÍŠéx¢?6z›´¿¾É°#ÜD˜dB16NdÇ¡!Å8E^7
¸…¼LÅ Í;’µ·‡ì<æ©`¹ËêŸIc‘æ yšhaaâ"å=ì±š,4Ì°–ô¦p
·EDGïL0v­_3
f6)ä
)I+½Ã!ÛA4C%'iÒ{Û†Fs”Ï¾)­K¤9ˆån•3ÛDJ¯Ê¢İVTä œ7Vë	L¿qQ…R5±t·ŸáuK^D”))Íb£“Rr_vKßĞç	gÖ±j=bù$$ÜY…ª:ÆRÄÿ³&˜XS3-3m;İ¿
jº	¥¸êZNëg¥-³….¢ÒƒüÇmŞUIÂB-û¿vÄñ+5ã¯…g¥°ÖÒo¥ŠB-b<"&<æ5(YP…†×IÙVp³Î”¤#4~úë#OÛÅ­úTxPô¥˜å=!ì†ÓÅh¶Áôi±¿JzsóYeÉ Ô—šîsãFï'q“%Ï?ï @în,†ñ”´¬I^ôşƒn!mİ¾2YfË)z`òWjÅlënÒ»-ŞÖî›C°›P Ûw¼À¯¨/cJaæ\µò’±Á7ÄG¥îQü±
*&§êİø#ì\âM‚løa<¸a!Èõ¡7İ{t[>AÙJÕ6“%<ó¬¢¹8Ëµá–4òÇ‡jÕaöÌıÕ/c2‚\IÍ#‘cÀ<ŞKH&òÉ4…Pà#ÍG¹=Œó@aJn·c02,Ó´l¾Úö‡Êã‹ÿÇA‡,œ›²rçÁ¬%€By¨ÿwÙ“ièwßà ÅÖœ`i;Øb:8Ç˜€~ët¨›×¡u
®€ĞœóF‹–‘wÇ¾Åü¡Â]$“/ÊlUÆ	ÉO˜G3>.M!B™+€KÈï—ŒESŸn‘û/Œ7ØÁ«Lê~9‡MJø,çzô	¿ô5ïÆæâXêRníyü¥Öøşy5å¡…â¤bZÂ},{§oÈUXûĞi+ùÒ·Ø1w*ßğÙÉ,Ñƒ„ıÜuF$ÂîmFZ8JÆGÌŠ"”nşqYÌL[æ»À6‹æ¬7aºrØí²Ê*¸$wD×à§W¶×åÀ"½Ü`"³)5ÁKäœUªäqœ| (Ÿ‰í1øéà†¸_Nùl“coÃt%RÆ-ôTï2¦o[WË¶"ü½N“ú¶şF.L!`eúFŠ‘,ã’G5tÕÆ·íæ
f™ò·N<'ëÑÖ-åõnº¾|54ÌD§-Š¶`•uªP¤w»“&}˜ì @{£à}õÖ¶Ñ¥5n
{SGyõZÏAÂÒvWu^µ!X
ä	‰E:£¡ôå‰‡6iêœ@(/h{ÜÆâÎ!ä

Hsš ×½ÑÚ§g²Áû|Ô›0$IlŒiƒ‘E_aòé8eY}	M`„÷V]ªHçso•äpàRÙÂœÌ1\¢#à‚c^CvşŒZè&C·,Âgú:æ&R»)é ‰øÂ”ÕD/MÔ|—KŞ_bªŞ6ÌB%6ó
”Ì^`şuY$€_&`¥<E1g±6ÇñÛ­sC‹"gVõ@MSÚL-ö`­ÎÕÉ£=ÁuKAóı›GpüœñyôÅ„ğ!³˜ÔØ	ßùu/3DòÎ¯	&Ò:şl:=Ëğ ‘bäFÊÅ¬”ßy3'ûqCœ{T€Y ½Õ«‡U©¶ÊÀ-Ù:W/‡íq¾.M¢9Ñ0NŒø/-°9iú©Î5çõ³˜r3uÌ§–…uÙ MUĞæ0ôI¿hW§è™îvAı†ªÚzLÃ_‰(†üÔ4që€PÈ¿°ÎuÀÓñ)%U—ybçk.¹?½#Õ6]Dx}Û´šY4.$¬8ò`Ç;Úç÷ÃîmØ×¯)vßt>¼ÆCõáIféÈÅÉNMBÓÆÁ™o©Õ–ôıx¬g™/yq¨¬
¸î¯Ÿ$Ôìœ\ß‹ŒõíßÖJ'¸ÂÀl±§Kºéîèn ^¿¤¬Í°.ÿøÙ±˜£W™ƒåÿµ[s&údˆ^àfF—®·  (±}lÄœ%>äRRø'ºßwea£¶èYŞË)¦H¼ØPx†äü¨ÉÓ.™ ÀáD«‹ğêY€†ã„¬DS/ÆÍèŒşeyPÀPñß”Ü„ûİx¸O²@“	 :kJr‚…xız6¾sX“WlT`÷Eæ,/ S²ÆíwE^yf,0v\5<xÒ vÙ©÷Â™ºnfbE<2ŞÅ0ÿ­eI‹”U©/°…KYyÃQA¯é¥ÔaöUxOƒ·§)Ş—vÒ#ÛIë–Š§–>l‰iÑc€¯3+:ÂŸ’ª¢E¿>QÁ`ˆXi€Ñˆ)iÇ‰?£«xx¤·-î>³¼Yì>{I™r@j|‹a’.ÕøÛ©Îów” î‡_E‡Xl^›•ô&ÿ«š{ªâ‘Pı>¯ml/4Îd9w×~ukª8b¤¦X~ÒDØ°#sGFÃ[8„öEşß*éw«>&³ R>Øgèäs«–‹•]1ÚÎ¸}}»,*¹õÇ–È•
½;Ë´2o-oOïd·µÜqŠIjÏşœCÂ³­9e}%àçÀ¬gpg‹ƒ\+·å4„Ú´(”ıJ)®b}¾«&@j§e[¼ÀSg§¯S©Ğní(Í´=‘á0ÇÏHm„şl2JxDèØ”OİœzŸ¦ŒÜÏU³=Ä®7¯œğuÔ«°+#Yy€a=¥ğsÂò(oÙb§ø‡·ÆwpÉÜ‘ÙQòVÎ†We<\ 7Tƒ—o`Í» ‹yåc4­§¤ö\Æ;y*¥“J½ZŠöã¡R/Å`—aÍTIe{ùE6cûsêàœƒQBxí!şqTêk­¨0äw™¥Çf¬TÛ9ÚÁÃD´Íù®Øè?…:éşiwCmƒ|`Ñİqä™dÉúöÑå)¦ êØ¶ÕË|–³°ÿ ˜”±= ı ¡µ­Jäf‡ÈÆ×SÓÒle›:¶} ¶‹ƒ”W‰/î‘­V%“ò¹
»Ìöµkê±…@ãøîèÁ…©¼,0aØ—É¥G ÉÍ43çèƒ¿EÍb€”¥ìvAóô aQÓ^ÍŸ~!è/i%“<Û~Öyæó8_Òê±IÈéšÆ”¡½Nñ‰ïØ#úë¢‘ûİsÀü¦Ñ‘KÈ«‡ šiH‰	—Fše§ À^Â£è“YtœÉ¾…÷Œ_½QïHéZ’R£*P8ÇgmOÂVô…2”Š+¡"x4oó^¦î„ù™´$:øµ˜êbÒğ^+J…VÜÁıÓ´ê¾ÉB°í:Ûá\£øCîÊó'%¿4™´ÓÔÎrJi‘² øB²X£ã2å¦r™ÕÊ‡7Õæ!ôps'ÛKC*EÎjåm vY$XfW6ûİ(šóVo\Û%œyîŸ+vÔhg®³‡zí¢ç4Ïğ	´:3k“˜–R˜€¢œ`‘ÁÈ°”¼ø	Øíx¼(EY=ù‡„¿Î”pİEleVXÓgğÒÒ,« >R ùLHj1Cìqƒ5NÜşÒ1¤dF5ØÇ¸.¡ïÃø‹HÅÖ§ã0ŒU!%ÅOÎœ`l¤õ„#’›Z–Ï¿t?ÆiĞ„Bô ¶J¥'U`œ°E.”†vN´]fİ”Ï¤ñ–M°í 
…³.6¦¥úçLíƒn…Í”Áˆ¬ãªh sº GSÖ„¼‡`IÇnËv>BÃ@Á[Vıâ4Ïã;°wzúMDX0Ãlr{e-{G‡[`Rn¶a¿É'B>éWš^Ræ5B,ycË\ş˜Ê²ñJåA˜îóWÎ¢¾âvRº\¤2¯gwÎu ]¬Ç¸e‹ä@ª=Ëzu®òìæy–Hı(£o'‹ÄìÇ““§mbN“•sYáx#YN}¶¦][V?¤Oñ@E&!£qU„WBô ‘çŞïíÚÅg|eF“#D¹aX{Då
«ûÁ–ëÂŞ
Gvé3V µ ò%Çm«Î|7ô€4ƒóM+òÍ^¤UÄŸH	¥&½Û›ªºITƒ,ù×¯ËßÉâ Ã$Ëh3IHÅíi‘Eº”Íîáá'l2q¹Ãt…ú¸úóˆÇÌ•P@i7SzAÿµ™4¤ô|:{ºLøn±j½$(WOşœ×'ØdhÁß&…‘N.€{€¿R	EÖª½fùk‹€l­{7;'*ÊÁÅ°·ıêBD=FĞ¶Æ¿³ÂäNe r¨0Yû8:+§/ƒE([äReF(hCzì§ûòõû>‡¬™İyHvP{røÒò•:qÈ¥ázK,ÄñÇßS·i¥!¾„K!ÚšXV%ıá¤f"Iğœ¼p(k@¹È>†İ{MÑİ«gó	èEG°f!ÉÀB1_qÆr ,Ã/‰5Ø)¾~tPg™"§LâÓCÛNÛUj´6Ùóê[û7°½Db+d5Ã 1Á§ÓXŒœK†¤#@ñ%{İûjÆŠd{ARœış:°#¢!‚ğë&!:Ë;ÙP­]Í«µH‰H¼Hw|n3?BMİÂíˆÏoàšç?’©4ıåÃYÕzÀ •ÄæıÄ,/@7ısG2#ßÏ•Ähı2``x43\êèñn| PıvN­·ˆM¬),¬Éi
?DwÃ³P¾[åïƒıyÔX1jÓ¬¬†Åiğ`ß«»/¶Ãn„BÌâ°ó;ø£È¹Ú cã›€³˜øÍàM±ŞE¶š«P5¹C­,èàó®ŠÚ¬<®İ³xÕµh£5„™¯•÷¿‚¼½´¿[InïØ2¶ÍğN¾÷²±°²[íb½’„Ò¾â	ó^8Ë—äØ«¾°Ç²µ½^Éêšvf×ji${»#Ëäİ,Õ†Óƒï¹¥W”E·2èÌ¬öq:Ş°¢Š¡8˜¤÷ı¢OÙ—<…‰K7È;?bµ]å¥\0+ògãà=íÂc¬ØÜegPÖ‹†‡ak¸}òÇ´Ú4©{‘ Êáø+ıOKÁVä.Ù¾La_§¥A9ÀÕÓöîƒ*®½5Ü*u¾½
k¬X™2BÄ=½îi`XAOï3ÍÄW|Aˆ„|?h~¦ßTf3ôßkÖéSV°VË
aä –˜!şñ6Àx^R
±ÁÉµ×îíù§*¢j=¥,ÿFÕË÷©Ì ¦«oÈºìåßùÇhC­}fÚGéÉÎÓü´\œV™œ`òéj¸—„2š'úÆ¿Ö]`]ï‹š¬2 ¸Atàs½ãAïW'¯xc°æPiúÛÜˆıd)¤ş&©íàQäÃÈ•v¤F•¾A|?P¹LFKÅª*dlêZ@8qóù†›$­
«ÊH ì6í_5{w0lÖ¡‚fÁ°ÕN¡¢fö™­•Ò!îAörĞ?2ä—ßü
s|n(‡€C¨êFt®ØóbŸ˜G	•ıDÓZïu‡[QòÄ_"şU­œ…˜ÿ»`!XÈ®¤”ÙÒse¿³gVH¢Uº¢[íéocä¤Ltæ¦®ÁŞ—îN@”e%kÙj%ÑZb°—pL|´İÌ\ê€T›¼“«L"Ìæ% uÄšäHó!ü`æùw Ò²u‡+Òóì…9µ;„;úvx¡vI*ÄÜÀò¯q&ŸOq¡İ<_°d0XÀ¶Q³( »h‹p3 cƒ$)N•¡UPš´+à·ÜGILJ– &âC†v4N7~$µNÓ1XP¬Õ­íÒ­”Îdö÷Öì;h|ê¬·ÁçÛJğkd=§Ú¾hwH7°:•!åıœÃ£)À‚bÕ¾÷Ëb[.]^Òe]YÈsòÚ?·®R¦*Y×ÆÎÇ0eù H÷¥°wôlN<$…ÎÓ^Aš['y‹¦lúhlØO3ƒT°eÿ@A_8Ì¦¯•‚ñàj&#GFø'ï¥º·%ªİríì´ëÀ_™.`$T7Ã.—Ü¸‰vliagı™H¢JsQ5j:ş#Gİ®¬OğãªS $-Vlj‹M“ûwèã•£Ø åÒ8
ïó:k¶¶Wd¿Ñ¸˜<0ÄóPT/De)‡- Ø[eá‡uÁÍ¬¾5¯·Àî‚ş\âèƒUú¹¯!4ÕõöàY%”ÏôÙáõó¯¯ø£¦`¢°‘æäßoìZÏ‰Sx„Üsíd  ö¼¥¥˜ããd4bèÇüa¿—&ì'Àˆ1¦>— (füúîö<¯XÁîjæİNâ(âe¾¥Q
@ïl°ô²‰sĞ³y…e«sS~K¬¼®YúòÜOn_œŒë0…Ìi?¿3âh3Qs²ÁÑ"â‹›ºôñ¿D
\¦°ò†kCÕÈqPTÂƒî¾Õa´&7t×°ƒ9Àaœ /_–“€cAaÊfı£ï0»-v´…(Ã…¾~ìÉıqm‰£ü ›s¯É¶p#ñÄ‰Íu›]áÊ0úş}ßùóœ×PçÜH–vfäZa]–ZC—h©ó6´¤ –³®%)0Êvñ¢“Üp:¾V¦ŒñnºÄ¼éƒšôÅ&Xİ× ŠèJ\ƒ½t!‡úH£©­íï~¤ÚˆÚ—hN„_Ò;èî2#ÍÔú§Sy~Ziÿ?)o„‹zZ¯fÏÇsKØğS/ªŒ÷­cVW¥k{•ğø1»åpR&‘œ™À.H±ó©†Öè:-œ¬C¤Ü[‚ö"1½W®ÂDêğ+3UX¾¶|Ë–ü¬9ÍÒqU+Û¢¢soPáDcÂÏ* 4‰u«¨õòuë¡—`A¶ı‚Æ²RQ¿8&¨z„É2ëº7÷(Ne×÷‰F$Ãm^ŒN e{W#‡à<b©÷c¤)µÿŞ½<¹(A¡‚S>ÖL‡°O?ß¤¢L¦‘R1‘>K*1Eµ÷ƒ+ÜOcÒ!Û'©sq0>èÆ[)G­PX¥%LÂ4ËñuîI¼ŸO‚ë]Kñi`¨f
×µ‚;AxDzÏe0*@	ÓVn'Ì‹\„¾öŠ˜Ô@nGMèdº¡t‡ı:¦b9u[#yøTêA†µƒÄ;ŠÙ:‚5 è0”Ë	<u¨„¤Pª*ƒ§ìîjZ_yqOJü$¶Bñf«Ğ³k©ÔŸÆí1DÒ·¯X>ï(ñ¢†J|ÎzlÀt£.$naZ%ˆR7ŞG—ƒ‹Ú™ì®bõ‚'àeƒÀtWU>0pqÌË:Ï®çÑb% ¯®eÛ:p™‚—Ïœ—`Ì.Ãã#Ü]Çã‚`’´Ñ:&·HÛ;ç#¶B¡±o<‹sd§‰|sËab5uÃ¥«U¿jwÆó<Ôæ«'Áp©:eÌx$j#
g¹Qïvã5Ã,	ê25¿¤ÒR3ÍŸÇ,qCogÂ6²V<¾„)«®Ü5õ-JİÍ+±Æé+zL¢j²â[€ÿd¥{øoø:­§->Û†7½ Kœ.~Zn~õiÊİõ3l x¹Øa›ò^í›ÂzÚ)N	ŒŞc¨9ñ~ØÏ…*4jØø0ÛOšı
C…Ø¥`.Æ‡nÓl©£ˆÙ:¼Ñ†”2^CÚár @À— C…¼İÏ…~D<$6ejôW%8óğĞ¾ëûôv'‡Íq¤´èp *ÅFÃü›Ïã=_B«äÖúH(—Á™ÂNß*½ñ.7/&µİô–ø¤éıÜvĞ „tôÅÁ*oXÂyŠY.¨<OK­áV”-Ú¬\åÅ§ë‹U$FnÂ§?ûUçæ:!ŸÙ`:
ÇõÈpRËd!%Ô-ƒ51zÍ÷áœƒnŒ|Ş``úMbJ'a•˜ZÚYèA£PIñjŸã%S[ƒªé–ÌsaŠò~]¼| ¡°eå^Øµ·ôn T{÷‰iTè¢qVUÓ)n_4›,àùngY*ôQ/ª
WAÆ…}2^[3
.ÁbÑ+N”ó.1ŠèµÑ|sÊ.â[bn¶ª*ë÷®fæŸ£¶GÙ¤K¹·\lM`;œrï•2~’‡)¡Ws(ø´«HÁD‚Oès¶lûMŒ?¬Ğß'¾‡ş"–ÉöÕx±—ˆùË5(Ô¢5‰UpV…†õáÛ‚¸alå˜@Ù*Òë†—ºPW=Á|·›?”^¹óúâT"lq·i“p}…´3ë}ëœ²ÿÁÃ98­Tèw¤í{pLÔ`}òo>}Óqìıç¥ªg
­ ˆï™b§¬ªüX¯˜¥ûeRZáyÛšpYyU¡0á”…*'Rzed…$2B>l.~E)§"D»ç«ƒ5pè­pyõõG>Ó7jïâÓş=9QJœtÑÓ!ß|wLDÂuÒ[–DûHìí©=E=–Zà+ô5û~ ™AÇ>"ÅZ!‰Ägş0£‹ï¼ÉÈk DŸNÉB”ßîÚéœüáÌûnMÓÁí§ÀãyÑÉë9§¾µfˆÿi3Zãf¨Ò'}B˜9´#>{¦©59ë{±»lOURÌ³bìÁ§=ÔŞ…ĞJd¹—C­ rUØ—íËôµÒ# ˜@rgl¹—Òz¯k8(Z7£o
~>aã\ï'“¹JÎ…„Öz˜Şÿ§Ztùkc ˆåpİÃp}ŞŸÀ‰ÉÉÈU;ŸÔüHÎvïªmÈ_ 5Mç[ŸŒoÈ¤Ñ·q»ïEvä„ì ¢Œ„¾9)â	”½ıµÉşZ9’ ûoÁ£r8ÕÌ•Ox<ÅB‰ÎyH/rÄV&zñ—±¿È"“mF`RXpéÏ,#Æ˜a‹i1ìëeè9[š“Q¡ÎaÄN×Óáj]P"V†çèÅ^«œ›á›F9G3˜kŠ¿ÎL¨úÄà“åğ-û«ì„±Ÿªpo…`²U•¤¬“ª6Ë?¶ò&ëÅ-½_§|¹á£R¾®vîÁz—6È)~içjã?>Ü² O%1ÆLT*bà£cçÏş½·M†­Cáç=Ş«TSß5J‰÷j}Ü]‡7C×4f\Ç ˜Ú±ZœFÇQ€üó|ØVM{õ²Ç@~Û´X³äú­êí(ÏöT-EÏªhI(‘ÍÇG!1è‘LIg®¨ò•Jƒmw™«oî£×a(›&¯»Æ„}—ˆu4Ùşo
xVA”˜^	™äî5Ş¥¼u–xº«âÑq,t†€éJ­JR¾ò}Càˆ:’#~“g“+éVqsÛŠ¤:|†Ób®üT$ø4ÃÛÛÔÆsË;õ'œ`ñ©¹Ja*–Œzª¨Îìt’TB¤Ş[¤â@`¼i_ #]¤OÈ1¤ª‰¨·êœNx?¦ßÍußJ’!4-¾Â•×‰ÍÿÓõ¥	uÎ ’.¹¿†KŸ¶¹‰¸BWF6«+ûo«ü·É¥LÉI³ùŸf°O^—îĞ¦2¡?ç†VÑ»e‰5ó:SÉoìxû³à´]âà/«s¾vêªg°1ò|A¾MÍ[èJı^ÍøFê½b©‡¤m]îù?üÌU/ì,>Æuü Ş¿+|<±~' kÖWÅé«8¥<“œİ5ÛãûkŞ.ƒ	D0“S‰kZF³ípóúø ¸Éãä²"=“ªjS2¦wû 3¯Q$}ŠÙ•‘zvvÖÉ ¸+¥öN1®
ğ
FÔ›(Øxº4ƒµy¦+÷¹“?OB/¥²h<uGc+»¤•ñõƒHH±Õ2¡„é›ß œU‰ÒU?”çı@ êÂüËCt
/R•M%€!erÖJuiq3ûp.şgáv^Z
ó„§÷§Üjgét1êèœØGO³q‰u´ÅªWLqêˆ÷mïøyÉsîƒ¡í_›zµMï€HÅã Í>ÑcB9£­³<Æ_˜™xQZ›€FÉ‘ÿú4ÏôôRôÆhañ®Ê£îÓÇ£ÙQ'||~ßâ}ÂF™m©¨ÌùÎıîÌWR°gÂµ äß™sBğÉÿ-Æ]/gÓßü¨a7°9×cg úpšÂÉ ‰>¡•Ş¦+üÃ¡75…9Fˆ£K‚OlWœè‡ôôŠô¹qµXÓêº?¥Ñ¿Àù…Ó)ş/·üÇp_Pªéa7Ø³¼?Òeğ§L\çê¶Šê£Óbœ(ÕÉ÷¼ı†h#i½ ¾ªÔı¼ei"Ú ê|F3ójb26ëôv(EÓ½®¤…?\´‚]¡3áRÈªaø~ÑHfëÕÂ.O?ùĞìÙãß•Hx'?kÀ+š™ºTFŞ!m~Cµ[+«‚dùLUÒ{2è¡ö´å«e»jÀw2^ëúÌc”u
æhiş/¿]XñÌ.ZÍq2¶‘ü†d@Q>bŸ"``¹zà2¶K
2îê­ŠO²ñ:{óoÛªãí¶ÏOj}ò}OS/•†¼ò,Ó#j4‡·‚Z¦PAPdÅ“Ÿ¦679t9m6	†zÔyşVb–8°ÑÍ£ë©^ò*ë às¼mÙÊƒV»ıS{â
Á}j*XóFİÉÎ†ğ¾@ëë÷’èº­±~ŸÂN&ÛGİÏrÑNÃ
¥³üŞÇ\8ÌÓä¾+Ÿ¯Wó>l«ã¸f]Ã­›EL•—CâfMí¨¢„„ÌA½Ò’@Î$“°tà}ÜÔ}ÿÏ¬Iu‹Ãtfîôß™êWt;4Ï`åòucK\ê­­È>Î­+ZTu%
ÔdpC3‘ëqŒ×Z#HÚkè½6ÛüX·à¶CÉ Å>q™œğUµá§HŠåùNàÃ‹İ(åÕ®ávG6$À›ÑâÍÆù„ï4+±ÆŞQ€B–[¾/»4oçÍŠ¨i’,‚ÚÅÕÁV“ŒQYç‹\z5¦ó•Å2¸åß¨éÌ®Ğëìã~ûğ{;äk#Ë^‰–ZU‰€F·OV8aŸ¬%2İ¨Ë"˜½=ÿá®Ğ@k«•Õ¨ªÊ±[u=™a¥äfƒesO~ÀÏi%ïÕáyÄÃà†l‡qæÖMz?~â…a÷ÏQ#|iKŸñ#ó5²ÌÕëYy“´é0úÒÌ3;RŠõn6´\/MãÕ“9®Ğïæ5ï°óêpX¾pÄnT inùKQ¹3½aiá}˜¸”ÌbÑòã´3›ïˆX{Œù)<u¶^İ\0Q#oLâ¯åš“0ú¡ÎœııVo§!G^¦${ XRèŠ9èó7ŠV¢°cdÿ?ºçjG1{ç’8VZšX5¨IŞÍÚ¡oNuy£¿7äÉ× —°4)Y7šëÎk¾n˜óšø¹ñp6+)·Š öË ²–×°˜úû‹«­İ/7©™I'·,~Z¢…w”¬·‚ô;æTˆ¦Y¼*”ÄâA€Ö“Sìâ‰¾´z±uÔ¨éß·vBÅÀ¸Ş‹ç½N`Ù£±æ"Ùoïa¤³0Ñ´_Äöµ"¸Í,»³[ÕéK½¾BÌ×oqºßs±Šù™Á¬’a¤‡k€ØtID†Në2¼®#ÂÛàŞyPÒsJ5ºLP<–ïX¸,*c³,£ı+GLuÛUEÕqm³Ë
P´(ÑÇŞĞ"£Äyöiõ&	]öR¤Î±W®˜òÎFD¤w G/CEïnÚåJ¿ûR—
_»2Uãº(Xï|N<¶Å#8v)_‘&ÄŞ%–wİ	~ß@ 2ãFß¢îê´tÿR2QÈa‰,¿7\¶…ŒuF‡_Pp»ÏR‹ÒænŞJ{÷§¡WKÏæId=Ô@Nÿœ×Ê‡;`¤$Õ÷YEIk[–îì0òg¹“â®d*
ÑÂåÌ@Ì††Hö
³O`¨½µnJ¬µ§Ò$`LLI”<-¡† Ò-©³NíiiQçôÃ Îw¡úZ—<t²‚õ/3ù‘= n:û™ÁÉÿBúÁzı uÏšPğô+&IÖáš÷†İË¼Í{5P½H1ir3O²ÿwz…,¥aF:’*¹jÃÀÈ„cùæĞõœ8ÃEò HV‰oW[\ùÈJeeˆw»„Ö^è§g·iùº¡3¶ÔÑ`DÀĞ_qšÁë,Ua_Oåa¤şâè®^uB/-·.çÆà)çõÏ
²+½:4ÕâróU0ÙµÜu]?&Ÿ…İ„ÈËƒEÆéÎbÖ‡ë 
9R{íäë}Æ±fö'ç´¾–úÈ
;Œïó¤´¤^b–½Ö´¦Tijs>Ğ&V`ñ’9„M¸Ñ(Q;ñt§İ&¿¨ºO’acĞ:¡	EÖ»zÜé$å´á¥oÍã«Ô³wfïç¹iúAPõ7ÒŸbÄ ;#¼ª_)Ì¼GoFz9d8Ë1D‡†ÍEŒ6æ)Ñ÷ëµ8h"·/Ş~ÏŸJŸr ˆ&åœÄø+¥k4á,¯‘8Ø@¦KŠ<¿°L	B8³ß¥º™İ=²<L2Ç5ö¥aMûŒh’µ	ø-ì–JÈqï¯&CªÓF€$’Œæ×»H–ƒ×9`ÈYªä¸p{’ÇÔƒf8•Ä³Ñ5Š“[Ã¼•Ì^(·=³xû{8Kv¥,UşYQiÁ0~@¾ëó¦Š”
·Bek8L0ÔÒ=œ¸½x0™±ÄÌºU¯^¨ï†‡ÑšôNdXƒİy=ô #ÖZÊ:óô o\¡u‡Ş•ÁtY†B-åj®O–¬ôxÈaÔÅß&9¯ŞZõ*â.®şL3™;~E× òÆc„ÃEÖ€´1òü®[^Ù>äŞlfXâ¡kÚ¸ş	b¼—äKûëˆÙ.Ã4ëu’©É „©úçÔ,ŞşOœÙ~£¾²wöş8}îë²«RJ¢!í¨5m·gÁé¶ÓƒvÛúø|BüWÑ9Óìå-à“ôêhÂ…ûiŸlV±A<7×pçÓ	‹Öt”>¾ŒÕÔts`pÂìûêöpˆ!²”I]Ô	lä¹·Z´É^Pu%›3J2lH·ˆF:<g„€[ÿK}…+kÓr>YeÌñ_@0§Æ¡4§¥J¿ÌOö÷+bsL»èe]?´ú?âXJMİKNºÖr@­ –Ò£tˆ»/`­;\“öÕ/´æÊ×ï®·ºR©JS[ã
ÿCzMèY)şËA®­ykÅS$hŒ$~_’6¯î$î\Œ¦*f5ÜäÂ¼ÕuÀ2s„V”rÇ÷pAö[‹¯ÀzIŒ¾«™İQH¨Ğæk:9ã"ø¹êÛM*1­½û…ÖÉá.¨†¡WÊ~¢3²A«<ÀØ4²@ˆÕZmıó¥¼|…i­hò9/rÆ6¶‹äTƒŸ¶b»?¤”!ïq6OKw4¢°ÅT kD­‹SÈeH’ÀZf \zqvÊRmoänÆb`ÿi‡{$?I×‰]ÿòÒ.Œ¿'ú{Êœ…Âº†» 8*,é&qòJ×½ñ”æÇ²IBgg¤›³@\ó+4¡7Vnz*n ~›9—ŸréÄDiF@V…R“ë2{X¨2ÃØšh2ögˆÌ?—ÙsëÑ½zr¬}(úûÚJ.\¤‘²\Î#’;×,;’‰Ø”õx£5+ñC4ƒ‚9øÍX£¾‘ôÇóìÛ…0†r  n¿úƒÎU¦íº±Ğ’yûŞU¯÷ˆÂ òş”otâÎÛÆ)\‰UNæiÉ<ƒÚ¤ä3©­ºˆGÀ¼Ti¬_yØ»š$šÃ£
ˆ2`5ñ,ãÕîŸ •Û¤‡"6:m}¬Z^op‚í›v˜×®{ä{pwßxbE€:–a‰«£S]ÄUô²nç†l…z›Óö¨±-uaõgìw#UG1E!¹Ô€oÄ‚’µ–l­Şê	ø=†à¢š vÏ©§äæñé£ÃªÀ:‚üiç€ƒ¥İş°9Íßkk9“U+®W™¶çÊhúˆÌH6+Ô¹ûVÅ„êÁÍ£A5ÄÒó„ ĞÄ°›9€d¼9å¢Y«)ü5°\ğÒ.8>~àŸè’ÎùD™Œ·½lƒŸöfpÿ¡àúòËìOä^ÒØ—•Ç=#Á*ö^Ì(2„­[õ5ää®Z¦
S$°ƒ ±vÍ]_&b+Ì³UOTæl	¸ØÊäaıªU¬áÿ+vG¾¦4q›Eñ²4Mäéßr0î¾%ºúàÁÂoE/š6ãó¸M¸møBiiëxÖUäIu{/,[¦$&Ëg¤ô^Œï\©bX¢Ô3Æ”*jÆld©l¿—w*iÕÛŠ»šìJ‹]Ô·OµˆÇø=_ˆN'NB‘é´ıÛ[Ò2„¯fƒÒ)ÈÙSÆÜ*)õ¦÷ƒÙ5úÚb.uÂVDü$ÙÈ(q¨‡VTƒr{ä‘²ô9ÍCß’ı]laƒ¬–|@oØV„¹º…°é#› 2(W¸êÖÈŠA›AĞ\xù¼1¡jô¿‡ë¥æådË£Ï¤K|s·ğà¶5ê*SïdB¸üÌ–L•©uÎ×½")ª-™¯#n.û„h_heÿ†Û+eö Ş“ş—B Ã. {ë‘6º¼Ãu­lNS\åÔ$=J™î¢ì­f`Û¦È1wöèØEŒ_ TêíO•Xµ6Ìh ‘b2gzíKˆÕÛ`Ö¦‘¼İ’y#¬ÊÄl­…ëumÆ‚İ|(VĞâWh™™ìæƒ¬Cm¦@£g8yŸØõ§%ÛGD BÈªï0ÌˆÒ}´+`£˜d0é!€*>®„<–ËF»"NzK^‚.§)}|_şVuow<Çå^´¶¶Iñû‡Õ°`õ„ù8‰,Jí<3Ì¢Ş§qnİÛRH£ãµñ^"èîMÔb&¸$¬›{$«kÔCÿœ#uı9U ì0­IæIÑÊ4m›•ik?…Œ¿+şJ°#Â@¹Ññ.[åÓ|N¦Óad)¥”æáItîYˆ¼‰Œñèœ-¾:Zp—MÒEQ0£(Cvübh&&ŒòdfÉÒìÎ]RµÂá¸@Ñ[¥´²T˜uGË£ƒíº³ßa!½ª™i*üœtC‹µq©fÛ! M£gÌğíä¦Ç´Y™vúPÏ^Î—Ô+¶Í„Do’—€æ¨ğ&x™Ï¬şÌ¶ºEˆƒ²Õ¨BÇÈPÆ_,ø¿%÷t.i‡{¨–T"œeûV-ìÌÇ;àäæxnÌ¦ï@Ïµ+—«İD.¶l?]'a:b‰ìÆäc”mÃµıƒ$xlÊNƒƒöxxññŞQ`şã‹
¸×y‚¢›¸|SVøXgæMR2–Qˆ`L{&—Í¹£…è~¼(T°¤ØŸ(Ş»]—çß¿$9Æé(„Âã/@7:ËE/ÆLPÕ&_ğ½ÅØ9Á»ÚŞOš¤;©ÅÎpÓXv+ÃˆË‘øF$çø¥î‡o8ÑB±íÔ%“Ş”£%•„ßä^Óœšøs“K÷°ªŠ‹FIl¿ƒ/>ÒCñÛG	)~“¬Ğ ˜}Ñ	|u{¬!»[öó÷-Ïx<(“ÄNÄ_˜· O\Ç ºPÓ¢\:Û4q•_àæÿšºeWœúÿ¬…ƒ„Vêúq~t˜½9I;îÅ‚ªÕ¡zaNN7ëî5&²ª¤zŒM{Š”évºÒ	õµ=4Ü-ædÛÊwvHè·ã®‘r•*#•±è8¤ºâ†°‘I«„£dD¥¸í3s¿ä1÷Ü4–N´u_@£šºR€ˆ)c«Ac¤[Z½
•´i,ö ¯S½Ê?T©š¤isÁáôyëGÁ2Éã¾4 «m¤ù7É¥óÚv=4~w{‹ÿî\u¤Ìg‚Ê{»/uÛÑ$Œ‡7æq§°€¦±ñ‘ğâo$w½ªšÂ:‡èÛ`«Á¶``3µ [ÃNËÕ•±è4ÄÆŠÿ²11JçÿÿÔÑWª'@Ë íN#yœf¥ŠŠ$ŒŠÑĞª£ñ è?wK?zC©ÿºÖ¥·ç[Z°Š¾++Ä“É7°2o#Å4ş5‹AƒFÒŞ˜£E5‚ñŸ ¬ıµ)ÿuK“ëéCü¿ôÿ—R‹ÊùTNÓâÔŞá¼zåö·º!Ëj‹3Àeşs
ùõ±¯{`*á‡Ø¾ì âËÛ¥È½~ÂßËÁFTØ7-?¡ÌÎPíÉrÖşL Eş5ŸĞkŞ6AT{©áİ8‚9%Û{@_M¨÷SˆÅ-€ÍÙ›)ıkSÃ.&|‘±óæO¢vıÉŸÈgAJğwál°; 4•D²,X?÷¶ mwX}B}¨ŸkQÌ¤EKVOc\ÃK€'ÜŒ3‘eñè¡]ù³Ë¯r¦ĞQkŠÚå6 òëmö<–*€²\ƒ]7}òl;*lÔv-šå àof7àĞXi’Kh·8( ÕNaÀáaî©Á*,—¶óû æõç]Œ„I´çµæŠ§'­şek}İÄÔ 4&×Dİhïvn,WcÓ$¾y¼%Ã<24ÊcúÜĞÕ¶¦_õÈü¿¬¯véò\7:TBİ¼íy]‰B›lKœò8°uŠÛ±m¾6Wx,š¥œJ*„è]¢R×ñ„MÄÌVò°å	|0ï‹†®O<ït¾-s÷ áÑˆ›qd+ô¥ï‰9 ·¦Í‘SG Ô]?¸s>ëĞª»”lÒÙRÅáb“òOEËK'lÑŒO\FÃºk“ágC»Û\½øWBR‘É…¹oÎ‘@nX5<è‘)ijkĞr‘ Ê¤B!8A&hˆ¦Øä„EìƒB¸£`çù¸úw*›Å®06>Q®1è4‚†ÕrãÆZô‘ÍcÆ¼*ÙÔe€Y²˜í½Üs×ï.ş¬mp#¾¶Wù!4/q·:Â9bL§“Ìé1Ÿ7n-kİ4B
f	`“]+ñ¦ËùDcju¦øp´áèx)?o¦`#´ÜôV]3Ûù“Î}ãö|‹ÎÛè½YŸnZƒšnÈ»6Úl ¡0¿Òud:µc8şÇØBÇ\*%äÅµğ€Ñ=0ñÆ$sÄĞ6Í¶¤,L³m‚!&š´²uÙğõæ/@|Ÿ•›ô,
X¾_â@7ÛñÄM`Î½ê;5"µb¯g7/äNI¾kÀ²•H›uÎß² {õ³Ÿ>İ·ènmÇ¿õãÒJ%PíæC†×uÉ}­b˜‰Ù­î[t¤e§–aX FW²`ÔCÕŸ€U_°z :®ÕoÉrBPYÚ=¥À¨€£&W§L7;n[­³«¡¼ĞaşĞÛ	Bên¼÷¥]u:…'k.qaÿ—^û˜1Íw[†EO­“FÁ‚çÄ>È´…ûµp‚ê÷Áï0jŠUköÚú·êÅ5u…èvJ 7k_İÅôË÷
R´´húÓaHÔ¥›O7‹° .şOñIºJyb›½bİ u»D'İ	H—‡Œâúw&"èÔøîêÓŠ=Í/`Ã<™“|ÿ™LyYĞáP‰9†óĞãüØ[ó­O`oDxùï°óÒvkûáŸ¼àHñ‡¢útª¾:,˜ÉÏ,Za<ğy©Áİfœµ+ÏVÇd¶{Ê¾ƒr¡ÖcTÍbûX¨XÜÚQ`3î£!OD4|û¿ƒP_±öZ¼ÁÎ„IjÉ)Û§Dôä:àßfÌIy–Ó. :]#¢(«?SK©XÜº»ª<“Ñù˜™Ím¢Át‚6Wî-5`;ŒrS%u‚Y-ìçÚJi»n¼pAĞ˜ŠüĞ³ïmKÍ·<Ìi0˜œü–ŠˆFÒƒ4Ëß29h	¿×î¯æÊzë±\†’Í8½N²%—æ¤jfLô»M[êÍf|ñ‡"{Vª_êPâLŠŠ‘ÇÄäÔá^Ü\»Ø4%^AQ=	íÃ’T+øìyã+—g«fœ»â=p]ñsm£È±˜2c8nøµşüU#³&åÍûøÈÔc+„_^‘\j(‘tÒ|½•T¤ì;ÓZün™¡àIŸòWÜ<‡[Uæ*üyU9\$FÂ"~\ãrÔOŞdwem4–ëÎ­7Æ=šˆ~ª3W¹ôpãcDã›‡_¼5#
•É“òÖèêZ{béÉ8.šŠ\]ÚVö-H",^ŸÔy-Ydb"Áº×Å¤Â$ÄÊnÆ8§zœÒl-Ej[&6k‹uÃ:z<'…)êœ~½ÛĞi§u­íuÌJ%Ï/ª¨ñ<UYw<5ã…2½-Ã6çP@ƒ—çĞ-F‚BX¶ePĞxæü¸ŸÛüıL9ób¥ŞuSCk^q7§õ.hìÉ£­X€!Š®êEÃpá±ø…tNæ¹iÆ¼,ÈmdY•X×J‰¡"Ò6¦Âí9Ó²Co”ÜÇBÇŸyÄ s°ªì$şÇÏ³<	ÈíÎÅ>©yzËgÃà!p^¢Î·ÎFÎÒóÙì"'î¥Ø˜Iå ÷ù.ej¯ö@hå
´¼¯.•CŒü¡klÆÙf}q!Ö¾·çï ãY/O¡7e(õDd½lËÂeÊ¬áœSª¥=‹±«^ˆ¿ù’Ùy·†Õ¼DçüÒ–½ëú¦òÂŸ|R;0yƒ	aUß—z.‹lnÓ2BiÌ5;'‚İYŠE#Ü¢X@-$Å©_õĞŒãDy)ÑKô23È¢‘)L¤eOÓ'+]ÜÍ¸oÿhü·´8¡ÄâQÏŠ/7%¨¡^fhÙ±ò•){Ù¾ˆÍĞF9J7¤»`…|šX¢E[¥.ƒ“=>¸İpGÌ.Kk¦çuóÛ¶¿x¿â%w"µxqÍÆ»Í¡M…äí0¶’~ ‹ 0SoÖòp#€`â`’Ù…ğE•»f‡¾³[«v™şÒiK p8äu¤í’€àäßnm"5ªÍİnÕqeÖøæßÓo¯ªŞìl{› Õºæ0Fè¡Š‡‹¼G…ØÂ°<;ó’A/‡µÃniÎ"Õ"ø	.CG<VÇò‡n ´ºAŸî®ğ4— Ù»¿òÿ1Í¬¦Q\´ğNß]¿¡DÎÒ/ÒŒP±G0“wS:ñÀæ+Ô	À+Œ.ˆôœ”¬h×z³g£Ñ>;±½ÀÔ+Ic|¹jZwœÍŒYù2ùI’k
îˆag¡M—ZÃhâ”R[İ->‰d”›í+&cŞŒ'¬³<ÚåqÏ.=ı¶| n’9›}âÈçĞğ{‡ğúIaßî|G´+ÄôãvAûoÈkkR+)¹µ
±ÑU´Jw@'y?ìQ%†ÜÀ´ª7şF¼=mu·Ã‡óï+xšC3¥g[eT’wáË;r)ÜA¿÷`Ü)	:8AÁ×û.½şh™Ï:ğUgÖ÷š?(`ëı¨šìh‡'E•¶>ù_ìíl.¹B™˜îÕñ™~¹éêŒ²:9V	7ğq<
S^„o¢ÀLÜ‚õŸ‘Î‚_.Ã»q%¨ÅU*ú™±`rĞãZ¨œãİ~5#ƒd§~"x7´ÊZhµŠĞ<õ*Š‰=ÒœŸa_kì™"a">Œv†'G$Ù§¤ ¾ü³Q˜@“(ó™3Ÿ½ğiÃğ©R¯Ú ˜Å¤Úÿ?84‹/òU‹îqQâú¶ø,âd£`¼:ÙGº6Û±{•Œ çìæ¯­'cş™:ÂOØ o7¨Ë4ßG-I,S—¦P\E5ÍˆåÎFU;ë«½èvò4@ğ%É¬ò}emkÖ÷w3"®‚Oã-kêÓğŒax`ôÊvlFNg(Şsx ’p÷|!í¨æb?pÙ{/¡|1Ø—tøCû?Ã·ë 4òR’ôWòø÷+?~~äúÎ $f¤U:WAÛ:*"L…sÍÉöÌ¬˜aÎåÔ¬|#.a1OîaÏÜ+Õ†7‰ƒêUÔnCØ‘ƒä™÷Š7Fôh]¨ÅöúáÉwPßİÂG%ÖªÀ²«;m»6øàm4¬œ×Ÿx´õ,Ş°÷xLDÓa–»¢€– Wå£ƒÛÕ¼OÄÙƒÎlQ.AıdW‹ŒX"”¸—#3u]5¦+ÿVT÷	ØŠ©zÇ¼\ÌFªÕÚÉG	aÂô’MÎ/I•.h}„€†…ĞKH–!Çø½JvªêTÒ¨Bû±Dâ/Öd[qïÉÈaÈeYæ)jUIçZÊG”Ê²¢B€½ã‡·£Š‘ƒâ0¡ó˜ß2Îœâ²´¤1Âñz<«òÌĞ¶ ;öæ/\òĞÀƒzÍjİ»æíÒ+æì¯§µ/â%OUU|v!É¦Ä}â›6lxK¬4aÏñ«„¥‚¼=Zà¯»5¢s,³'(èŠ}ª5…D4çûÂ¥¤½¢v•G¨øC=#¿ØV€OƒÉÒR­\vO$õóìÂ^,Â\¬*
ˆ!pƒ–™”»”­™†¦ h÷ ïvv¿Bb_°–6ß¾Ëy>¬óÁÎ“d™#–xp¤WtQ×øª`™y˜T”cŸUÛÌì[	õœ’ÈQ_Ùê{§¼4‹í÷¦«şm´ ,9Ê7¾«ƒÉœ‹Ræa®ñq6Û$xÜÒøÉ•qAoàu¶ò°qçıËÏ€Ü2dà€lîN'«ö¹Øg;Ua¢T7ãú=@4m£¶ˆ±.¸ä[N¹Ÿ\z>Í |¾Ä‘«öö>FŠà› ®ãKó÷¼Ø¹”Ö÷ñ…Bü@ìJcSyLÄ8Ğ¼}ZAxî-ÔëDRİ\rl±‰¨QKiG˜(Î´ûWèàº{6ÅåàFÆÏîcœÅ˜;Wq>œq&›@G4¹Ò±wëDõÙ"	˜š7]ZÕsÛZÆ¥:ñ¤h÷¡ï\ÔhcQŸû9!º­œÑÅ„Œ†¿ ¹æwIK4aš\!¡³¥¥úS³äQ3œDt!X¤?V+‘Ğ¯¼2
{ödw5g÷Š{&f‘A¬ò¯ğÚÍ‚ñ½ÀÅMÜŠ¼Bÿ¢ŒÄŠ'“(Šâº“‰ì-¨ÿ^í¿óò5´*¯¡$4IljP!¾Ä._ß!G¤kUòÜ/6EğwM£ÏßÀW<[\RÓì©”ıƒ‰ù£‘Syñ2o,½–”'|zIB %¬/ö=fÌ¦¨‡êlVå²·ÜãbŒ‰OÎ2¶÷ËCiË ‰Hñ0ú‚Ùø˜ì3ò'nuıÓå+øn_sòˆÁ¡b)Aä=wxÓ¤Åÿ&­FüM×­¸ùoP6¤uØ|\ÛTöøÇÊ¾ï<ş&
(hèwU…npg¦O
­n|Ÿ&IÙ1)Y·×¤ç\Æáà
&ZH†Ùà|·­ô*	Õ*,¿	Y<QÑxI{¤À³•Új­‡P
ò•YàÏ+e&U
FUÊº’;]ÿuä¸Â+ªİfÀ÷e˜†)Ï¤¹Š§UÑô¨²Ú£¹±µÔº4U6á©Ÿûğ$0[:¢ …åÎéN\sŒVÖŒTGl.]U¶¡+'ÂùÁ6°É#ÄJ÷_¥	™6‰@¿˜Ûœ^L}&mZ9 		—°ã«wˆR&<7ãsKN_dë½ì†ù|RRbÓ,ähvf¶&¶ä„¯¢\_´PP^²/°Nµnhw^3¸,1o—Là’ñu‡ ş?ê«y÷˜÷qÉ’S»?*;r¥æĞòá­v¬§öSúDòzålè£^LL‰Ú”´’–ĞtØFYLÁ*şA–Âˆk&H÷Ft ˆGÿ¸N¾‚Vb›ÜÀ Ï²aÜ,öàg.¸s¾´$å“³á3Ÿ­a×(ÂÍ×G=¯R¬Ã±ÜÚ¨ä(§}ôQ}!Å!ATúşNnM9gë†SÔ)Ú–rúF¨¿Ã›Ì2¼Ûk;¿ÙÓË…±&FtøA…SÏçƒ=xåìŠ)~g©“˜¡«á*‡ÄÅ¶môËMÚ$Æ
ITNÆÀ$G;¯Á}jrô8Üh¦/Ïtùd|ğ‡Ç[·è bÈåmGLÌgxøYÓ2ˆ\‹ ´IÇg=0šD8º§ê¥¹Å8N¨0q·¥“1’-èÚ$ØH7Ât–¶›¢.fıú’åßki0š1A$Gµ6#zHº…{¿Ì[°·¿Şß>ùãON›|Î÷òÄEø¬7Sx« hÊF`Ù!¨4š¢Áz-ÜĞì)Fåuo€L´›¡k‚fšûğW-$‚ïğñt0¢óµºø.>Ü²ïme­ËÊ¥”˜0Û&EgÙ/®XR¸dwÊºÇê¬É±‡«RkI	ÙÚa¡¾EWöÖ(Êü-]BºdÊ•ÃòF“G—¥şfëy÷ê`cè—n.6{!qöÓğÉ’3,éüMı ¨À36 Vxåæ(ØÂ`·_/å³!e½DÌCQpSÏõz\Z<±ùmU?eWõ<‰9ÿüT9,¹	ÀeGÛù?Óx#¨$ø5ˆhEw§Dç¢UÈ}Í»†ñİ¡†è}r…‚ÇƒœÀó)UmØeBrÃl€{hhô£\uP×iÂÍ ¸ X•Î˜q´¶Q0=l2æÅE1º ÌÚ´Œ ô°ã^2në,Ær¢i=qÉº¥¸amM>kÃ çc³I5¯—Ñø© P6Ûãe;½C‰˜òfA~İ¦¬ÄnÅJ`‹úF½‘
(Í	cª˜7ûn®Q’3”­oZíÙå2à ¯7%öQT‰aG«Q9øQ§k@bì’¬ vùË÷¥¡’õ9]à#µ…úªdÚ ]Ò,NaŸ{¦¦°7Å$èÙúTÛˆÄ+…æ±uZ2ê»<æR¥æÏ‰æ¶&>bpóVà^m1ˆ³=ÄÅÓEmçşVëm1É-³Æƒ;¿-†”†‘·’N=Ó€}^87f½uœ+ZŸ‹QáöFÊâu&ÍÄªÛ6­ .U áMÒA˜cêdB ƒ+1ÚNGDUW}î%ôœJÏ@É÷!@úÔ£¼o»N©î¦³˜ŸŸí•Õ\óûñ<ÂU^Hv…„QwØ·¿ğbuæí_„,,G¤M³ß»_’ª>w¢»”›Ìçá¦n¾k±‹;XÆ4X$P¯
êFLhWqİªc˜&ßgŠ'!¦dì¬UW	,Ş8í5İpé®YSÄfY/KUÙÄÄù˜Ç}à>uÏÅLšÜóı0ÃZ®Í¨¨9ˆ-ujÊÔ¨S¼ºx¦ïı?v£¾Ê8°%UØÄ!ĞOH82]„‡ŠRGdÓÌÇ¸iÊƒ©Qª4@¸£XYBÅF$L$©eæ)JEØóiÚíb{Şƒ¦¾A_àGş»H‚ÕÓuÑF¢ÄıG=„ÿ$jŞ „òû1Jš–ÚĞ<uA22´Ø-'ÍÉ‘\ˆ­Îğ,î™Ë
,fIÑ¬¾®şûw·Jœ¬´pDÛ}Î$=ó·/ÿÀ„´zõOc4süËó4ßlfŠ='Á‚©úçj¢mgÍ˜ƒ©µi@!r¡erÂ÷9©%¸»Ã;ÈÑOm&Du[ò‚nŠ­]Î‰Ö5;Š´›rî¼•á­c4)öÎüÜ—T¯kê:ãü¹ü«¤(põR/ÖÚ/îKèl–[é4’flˆ¸¿­éì[àØI ¾Yb¯øwËÌO1ü¦ÌFGªÓˆGĞÎdEÒÑ­şœÏÌypO»l_ÓóèŸBûeû°ãÌV"¡IºWæË=À~oú~º3^´RÇI!Ïì¿ö}?	Ë—“%oJ˜1uRÛ¤)âdp]•ïm·)Ò¸––˜B«~‡MPqÅR0çgöuÖ	ißswnñ˜ĞòQïğöÆqQKM¬¤ø „ğ0Ò\[Ù[TÚæd2Ûè™ıXº£½üÅšœ ”.T³”°n	{JS2hú–Ó}ŒÂUyĞÃŞŒi í6ÿ(£è.?µÀÙöÇ³NâLÃ$Í|–&WÙ8ñYğ0w‡ºÆ«//*V78İi˜Îèb†œ4FBQºÄ2¶N0Œd>Ä	iy„€®a‡[ÇüÏr¼pîõVZ6$±Åş	Ù'ıW¨l‚"Íÿ¹ì_tL“@zËèpeÜğ?{KÇ‹ó¤Ø0Xÿã¥u…!ÃÏôêd™)N
Ç!PµW½>çï’ÌHåşçšÄçÇš¶Şµ!hÈNæ²»yühğÜTµÿ^~Bÿ0 ‘S±å[l›Ÿü¦q”wü|Òµ'|bk_a;‰€òºÎ,6*îÂŠä~Ñ2›JNìw¶µ«¼Ø ®M4ÿ‡{ëò.4OV?wR=OøV ‘ƒQ´arŠà_ƒW!PsHÉ($ü«,]ùÚ`nÕ¾ì›Ÿ¯ı^O7õ4©¼Âä¡{)Ô34®
Ö‹äİK} o^Ñ×}œgÁ´€f¦ê–YVtè»sÎ!É{%”‰3òL‚‡S…%
†ddD~(Ş‡PŠ0«’í¦:F	±SÑJ6aDÅÜ ±ƒR~ïksùÏÕ§ØV9À&jo3R ùÏP·Ô`¼;(hTnNËË99•Mb¢íÜU$#¢@€èŠtËø6§û—™cã	h6„7%•Kş–(÷ÎÓÒÄ¢YOĞ–æÏm¥Ò3ÑQ}:b0¶yïv:pQÛN§“’Xâ±¬4`°ı¤©ÉcşÄ	Éüv]¿\ß—-Ãıÿx ĞøŞ¡IŠöÜeÎdYNº*rnj€”ğ…5Ëp„€‘ËHF9!:´ÔÂä+!œx&x*Y¼P'b›».³o5$©*Ú˜$3îiAÊß\ “0eµÍ	ğ÷&]fKdìi9rÃ6ÄâÓYswØ)„ğèñ¾Ùré]Àß2?áWt2õÁ³ìsÖğÍH}Hµ¶ñùíYÒ¹Ò‚?„Œ"k’¤3ùcØà3;gBÀÀ…lcÁ÷rGÑÇö¿y‰û„7ÙÈKEvÂ¦$C­ê¿¬0¶ÒµşìøNãÆ@;[%fQóS²ÌÜıµ\—‹­x2”úÒ¾i$ŒiŠÙûÑ®‡oM¶E…£¢á%«P%Ñ—ıEå¦"³-j:`^<´ µ(şš@BÃö
K$§İÀî(DÆt?œoZ=]¿šŒ‚PšL6@k<@†p¡]$’ª¯°3ú;NU‡#._ä½Êß÷‹)„½}ÁÇ;wÓáË‹!Wr¨Ir,O—§æ´	å*e$†ÙİbHêR°LLúBæ‚Ü |ıLì®[°¥{>-Ê¢¢#®Î+h/+KÏüµ;ZşÆºªcüÃ8@C´Õ4‚Ã6*"&ke7š¢Oü¦$Ù[uüGÈVğŞßëhôëÎÒÑ®»îOúŞhÂÏ‹éüâØB[¿½Cx~X.¿ı•Ã‚ïW#³L‹²—#ã[wLÂú<Ô2û~Rg•iÃMò gQáÁn‡vëš^‡…¿™gS^ì•2ÄLŠ 6¶”åµE°˜Ûü—ò¢3X–ìù£…‡Å³UÖáÀE52¬µrËrñyÜŞÂ£H‹¡ 4™Œˆ…Æ¿½cææ³ òµ)}úûœ­öGNOw"*^á¼ï^N./ŸçGÇ@¥¸^Êİ\+x©U¿ö
óí_o¥(Mo«Ş¥ºœOé¨Tx‘`ÉÇı}3ƒ+°ŠI9ĞşNÄ“IPë¹÷Xô¢”Çfxw¯MÀ‡”ÃÙ¶Áè`eÍt~ç2UA ûypíWvî3#–ø·i.ƒ^œœQF½ïãõ*ø„x3<T¶üï¼7Qj‚Øû3‡\ğè²[GÀôÊÚH.½êFäˆJrkêÊ%¡õƒé{ğÆÎzÙGPÿ ÒSRÍ Ì¹KÇs¨kÃğ&=9vs Îïìû\É„¨šûÈ†f]:–OEu‚ /2æ˜ğ#<-:Oz•²Ùğé<1ÂG€5öoÚ¦¢‰%yT;¼ÉrûŞòû
T,xá¤}gÀÀ‡«AäDû7Ú5İ¨8Í¹ëó&Ë©°(kª¨ùîÓø·%·)&PØi)¼âÌ®£5…XºTñê‡z°í!ÉPÌÊŠ½Œ'_zÜEòHSğµzWÏ÷l:‹¯Ïÿı¶Á®ÏQ;æŒ^ŸC{!ø¥ÇFª­9=†ñ›´]epŞÓß÷Rk¡æRä|5fb"Jë;Z°!mœ£AjÈOŞÈG$6Ô`òm;c\„XøÖñ¯|ì²ŞÚ\€¥±æO&íHİ•ùŸz +÷=gRÊùïì‘…pş‰1¿œ ÉÎÍN¡*ŸñÌ´hœ÷%QTrGêëˆ9*o¦À¨ÍRjZÛğ˜sZúşº1§æ½6]¢Ìûštxˆû·ê™ü*‰2}ÜÜ¸!§ã¤²ß‹O}SôY8V`HÚÀú?˜™€“x×FÂšÿŸäİ[ª»äI\)iQê¼cCû`ûhLÕCD"éó˜·¯o­m_…³›‡(=__6ĞœYùšÒ˜0;öY4Š“q…@œ¯¦õ:ÕÚ“ÊLé.k:oQ¦ä‹$ª6X¼ùî§˜øôª&Q!3Û(R3ÏËXÙC”©LÈÑ8±İÜ… ¦jºşMSîeÓ€DL3Ñ©ÙoQŞ‡‚9¼Ì§—SI×“O4ÕLBkç›M©’Âå‹ Í2ÃaMdT=ÍÄ+o=R!âÍNñ£÷3]G—`á¢bã$· ëº¢¨5ú¦Q=ä!PlÚDex7õU=³‚ë2úNÃï÷ )ŸB…7=ß^aO£§[·ñ ‹…I4j=c‹q7Â. }»¦<!%¤`æ'@Qá–8ÆıÅ[z©©q ¼2»±4wU3Uá®
º5úŸFÅ)  HŸm€.Â‹q»tÌ<õ‡ˆvf*õGüÜŸ˜Ÿ:ğ,9ıèÊ†j¸2g°14˜xÆ‰;åfÿĞÃÛ´³¥Ì)<#nÃ”7X‚ëŸ ²á»6ÌŸ—£h§!7T_<WZw)®5~Š¹E¡vHÄ_áêøM›«Ô¼E»ÜÎZù|sVÜ0¢4R¤›jí­^A˜¥)Gv$ˆ¢‚#Šcã^2¹ ÊlæU)¢Ò	Bì“äøü_¬Øğ~Æ@BíÊVìğÉÊ…Ÿ#×h5‹¢ÂJdBİØîR=;ë¯hèĞ-‰Ï™«ë*ƒzÿí¦!H:%f`]?z¢ÎêâƒØ0™F`›BçşÎ.pâ€FD%o-=n:÷•šâ?K·;Õ.½;á}ÙK½A-.ïÄº¥7M³ˆÿ:•Ê­T‹QæÖ½<Ë>¡Èn»ƒÁ+;`6«¸—âñ_¢©¹[âòñÛBÉ‰¤D¶–D½¶’ê¢Š'8»#EEW—}ÙÃ˜ÏÁßÂ ÔÒŒø^³¦Br8¥9ø‡H½KŠìõ'át3f²È5óc<-–¸¹M>259óÊ8µX4ÆÙÅ–ÆT÷
úUNúı%>¹xµo¦Gé£»MVQ¼ãn¶§Ù
xË›©ì" ‘pdHGŞhsÄÏOIù†¦pôp÷ÎÙ¤»£/ÎqšíÑfÄ\º
&U‚:­˜•æ¿9j"u Å¿tƒ<­Ò0‡¬5L·¿L4?ãƒ½ÿèÌÿ›é+{­<B'ğ…ã¸UşE—¹»ìçJ°šæ†Ÿm'àÁ«3ıpÂ!|œ"Âæ¡\®ÍÌ?ää+´…UÙ¤³÷
çÌØÍ<%°T/=È‰‹8¨ù ê	zx²j®¸>N6<‡¤ı±Çcxâ.”|úšL):Ô·ú	nÓbUPj“(¶Ù¾2ÅáC‰S¾†ÔNŞ#“&KñØoHÀ½ÿöq¾/Û;­û5¶­´oğbšöŞ¢n»;bÛ’§\Ï^üŞIÒ(Úõ‹H?K\yªZ.¨I¢éİAĞu¤}‰Yç°ìSB{ÇfƒTÌğ‘ğ9'ôúè~g‹êt˜6õkŠ¤Ş×†5oYs©ÿ¯¢«ATùôNf=YæâIQ/„UN^T,yá¨á8O“ñ«ù³ZóÉ3=Z4’q’Ğ9Òl À¹#xæ´Vm5¤yT9ì”Èõ (yË•pzô§(.WëmÙÒ7`Âá8[-6&cÃW T}ù}Ã™û»ÊNaû1È.Ğù
ÂÚÇ²»‡ÀêRÏ¨Ô¡û2¨û„ûÏŸãÁS«œ®–
Géåƒk%P³çHV†    ±á˜?^l ş³€Àxà½·±Ägû    YZ