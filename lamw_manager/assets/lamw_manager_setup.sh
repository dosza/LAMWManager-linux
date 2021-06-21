#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3454078269"
MD5="0429db9c7c3421b851e89616a430edf0"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22928"
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
	echo Date of packaging: Sun Jun 20 22:30:37 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿYP] ¼}•À1Dd]‡Á›PætİDñrüî@D·Ó—€©Í1°®Ò^½í[ŸŞcâ½%äk*ZÒ¨œ½ı› qOyÕ5‰%Â†HyÄQ	 A×Mbü:“°?£ú“¹e»8ÀOëË¹o	›yb€3Æ¨ãŠQr.‡İ¸X„œ0¥¿y.m4Ì\9&TA«•GşI˜µÿñ¢ˆ‹¹ÒÒ}ñ’7`MÇê{N.‰N5™÷ÜÜœq®÷ûhEjùå¬—×¾MŠß‰”ğµ–§©‘Cä¤¹ ${Ê&Ìê§uêÔS/–ŸşÍŠ	”Óò£Ày!eH1aüÒ¢¶ÅÜÇ¹È»8PÔÆšfô„¬Äë{¯;ˆ"=×usy>h¨Ó,‰éøÈDËãñ>8Á®–À„Ò=óü<î—õá>}s”Wb]¥¨*´üSd Íâc÷g#™Ğƒ<]4µä±…6^@‚[àš"ÿ`í	Ú7üÜİ²kã>3û}u.
&2G|õáÁ1ºï:Ä'G]ã'-q[œ¶‡æ'e{3«ï»0ërõ²Adğ^½§ï^7ìİáXYå/Ä¤YàÈÄÚ¥[É†$«¨ÑVdÄãÑeq^ú^…kĞç­\sÍZ"25-°û’”H…cµM(™x<Û•*5û
I.[e¯Kö_ØQÛœ~$³h§ìöµ-"eèø»0ät/Š\g|
®#m‚jŠMİFbJ²}û0Ì¸ÖÁb²`óî0§C†.¹g”½XÖ¯m¹Wû±ò°†÷SW/y!°f¸…AŸ<»aµè35óöï¦›#ÂÔı²ü½Û,š*(.şAW•„"åÎejßèÛµšeú¡Gz¾Ë¿~ùßÃõ}\€hñİ”"9h ’dœ¥…şÄzúš8½d–,v½Wß3VE”ÀİŒÔµ;@OôŞè_¶ù®øQ|EV·aa&öõréÁrìh,ô”2^p201a¦:{©ñÊ{ØÚyÔô¶ÁË…¾0ÖiWÇ«¯ãòçÉiL’MüˆüŞŸÊÿâ˜(ø?#úCd'9ò–ö&c;”şnEPÕŠ}•ok5!c{iõàcv½-â0uÉu_M6Gé&}JõŸ}píM&>?644ñ—ì<òS‰òk=SÊ^wm¾°ÚWGêqù==¿÷wÙq§ŠèÚçŒ‰%lª…²²Ïñ†ü|„µ8ªX¥ DDöB6ÇÿeëóÃ£Vw‹‚­É¡WëJkömjĞ).$ÊşQF‡Sı"Ö,Çãtƒ*’4ñ±X360m€—ú ùŒÕ"­¨íÚ ¢{lôA¾åS"Áïî rf§¼MšÒt&,iKıê²é<ŸÀ_{•ì`KŠı»¬»Î¼´*`×]w_£±Ó:HÔÇçÓlhx¹L0RİçPÖTCb{º¾A-rÉÇhYy`ª“³ûiÃ	®öúşXÅÓ>¸İ€¥ìë!„‰{™§¹¦ ®ø.şô!Díôß’u[/ÿ<IBÛı²réşED:Ğ^òct[¡É’Ü¸3;ÍÚàYl—4.*\jNİd¥œñO­F=³ŸÉ‚äµ¿z½˜”y0¡Vˆ]4Ñ£µÒÕîRÖÖBu®ùqòdvôàÈ-DKØ÷¢ô¦EH¦=•BHV´ÜĞ“±ö†€Ÿld{şIt—fu=”7¸bŠ*•ùØİ“İfFùì9!Ÿ»FyîSox›ZaGİ©Õ®ˆp²g®ÛM/åÑ!æ	DïFiË+
3[	ã¡÷š3”Uyêóğ%ÍPn¯p¯şŠ${SYŒH¦Pø-ç¢'3×³¹¾ê¢ÍÈ“Ö³ÑÇo—ã#†Iş÷ÇÆôs¯3_ünË[B,äôKäÄ_íY˜â Å’<÷³]„si|ıŠ¾ôQRWFÜ&¿çÕŸƒ¸ 1p¶ıqµßÖOT”Ûfsbhx¹Aò™«ö‡º?9x®4epT ÷7ÙÚJ[!ış­¾ã?ê¡&x¬'VR	¤F¶oÊM¨ œ¸—<Îâ0¬o!‰TıàZ¼h†d»ĞŠÅwTi»ÉÀèeãŞbŠİæŠ]¾ìY‘’°Í¶%'$[? år:aÙck¬+[†0-Kàà{€Á½Æ®4O©*ÜËaSrÃrÓtû_L*Kê‰èl×¬/Ì¡¶
	¦•®‡èmÆßµ¸—~á“˜fµÁtw*^[³·éæ|·›·`b_Í°™æ’/¥ò3Iğ†œ|$ˆ©©iı7»ÈGr;Œ×·nÆæğ›Æ«j’r’Mµ`äúÄ£7ÜK›Ãº¶ËšLë!TJø§ˆĞ×¶c¸Òß<ÄòNèOœìñ”ÏYé_ÍØ	T{B¡$y´Çx,Ù„³uA¤:«L;L©wª+¶ ç1ğïÀCq[…M]y†‚åé\'¦óB½ˆû&3²¶¢£‚¿mò y»uş^ğèî}!!®">
OïŸô[éñà66­2_À™s»ìX.5ä2vïU…t[&8U$¼d9(ùİÕÀ”M¾®$½53):Z*k¦³’NæÔ‡:ÈÜoLŠPåû—÷Ô×ü1BJñh‹˜²zwşé×4c¼í$Ä›@ÜzÖ¿ÑÈİ‘6|¥2ûa­SÀ#vDB~q AušïÖh=ƒA¥:ìH;E?	rÎVğşØ/­a—±0Q¤n÷¿ÂÿÆ¹°2LRâü¿–Ö©-U‰$M“=p°òÁqå –Eu3÷‰ ¥«ÏT¡Í®ï6Ã€¸=ñùÕŞÅ‰ƒ1L©BdšY`5Fæ-wÑâ‚(Õâ¤c¢šÏ :£©[ÙÁy‰ŞäEë!?r/™jC]wÛat|¸V¶`à;}ÅÑ8¸¨æpbCO±*Â,=Ù?‡›ˆ¾w@ø»Ù™²ZŸq© uLQU'6	Ş2À´?ô€½ÈC¦†Â Şq˜zĞ<ë¢ :<ú~EvèPå{ÿR‰$&ŠW³¾’"AÓ÷÷ûüw›[¸d|Q¦÷İ§Ÿ)ç[§x«ü· ‡ìÿ~|€—ïO·Ò³€AÚğ‹^ ŠEó’jUŠö(ÏÁü½Ãâğq¹#¿Îáµ‚•kCı9Kß¢…ÛO`•S0`œ¦)öªE§ïDö·»Ğ·ü.a„Ä’ÿ÷¨êæËPäTcYWSpÕ‘\Cğ„ê "¶bŒjîùü~ğáôŒC†Ævy €hÿ\ m©µ€¼óåŸ™3¯‡œšöO"§@ŸŸ ÓŠ­Çvô\
Ãá°ç8V‘óâ8||Yœ$¾U	6À,9N¯tT>øßŠzò°ãw.¦ÖoùFè¸ÿ/~Ú„·Í—^*Q=˜Å#¼A¥Ğí×Œ«ÛÀŠ;„…¶¨Q†`0öøA­º±TÇ!,ã›¯Tªs^ªƒ8+¯AzöŸ“2šî±7µŠèÚbzËƒ<>ëÛ÷f9n¤h[.ä@|ÛøªvÃNÓW†D¶S÷Ò=WIÔû¬§—,p7ú^ K·åàN7iB~›Ò´š¢¡yìe1‡ÎI˜õÏËéå,µkœ©öéû·}ünÚRà’åğ/¬ô-Á uÿ­.SÄ¼ÕíŒ–ì¯/KæíÙ½‹¹šWÄ—Š\ujûÂ€ˆŞ	èˆTJÈµ0Ø+Â5Ş¼R=ƒÚŸÈÃİvæ‡âwxk¶©Ğ P|‘NåÊùñş«¤Ğ&wô×!ÊİgœŞQ˜Úèõ~©í›ÕÎ¨+e¼3……Í\%ÛròÚ›Zç$ì¯èJüYMÃö$Vxwğ½cùë}€¿Oó`ÙÉ>^æÅ!.÷Œµ–7cºğu\ã)Î„è°É—¢`ñîúrïÅ÷˜§ £l÷&'Ó•—£ÄÁ^YüëÀÈÎĞY±­vµ[úÉ«†Ó2Eÿè½Ï^é¬‡7lü[ÜfY@ÇÏÊ­PœœjÇø‘Ÿ8¦çG6t±çÕ§wlÁõRÑuiU²èÛ¯¶(÷­1?æğˆ¥„1j†¹HI<_vwŸÑádF¢útÓMY3YTæŠÂÄ×»¶Ğ–çü­ìÙ~´@kàå.LÔŞ Ş0¤N_Èµ Ëæ¨Oö†$vé7œ/‹<{x¼®Àºß
`,o<C“áú†˜wßLèş—t½XUàÜ	Ä<UÀXÀÌz—Âkd vWy.",ê&ª“qd­¡ğ !1/Î¬ÓLúwİñêB*}BåM’^*ìB^!B³4u{{ÛŠÍ:ìq:º¥$iT'~Ï±²]í†œô<I”ë§@Ğzó¯%é}Vw½†àÄÍÇ›]»Å;"Ãßõmy¢'{Ó¹/şÅ˜üƒaÓ³ıËøA–Š›¿öš?7İ Ãû™ö—€Q}W®,/HëÅ2d‡ZCVF'sq¹#—+N 8Q2¿^@™­Ë€û¶ÏgÚ°Yˆ/áé9bÂˆô4ßÏ½Ÿ*üÀYY[Ë6RÇQ‘Wg£È}ƒ›NF¾Ä¯Íïöwø%¥ÉÿÍ!3=C[‰rüë®æp“­³Q‚däœ\ÓfH8Ñ_²]æ^y‘Aƒg…Ÿ	§5­j¬İ&jCAò!Š~¹í·©©ÍÁÜ”wè^ÕÌGôõíªæ°»pÖPz|sy|*´=.YoE7r0Rç¶øÏjg”b^ßY[¨’PN ÚM›³‰Ö§ –5:£5¾òSÅ¶'ÚÚÖ2‚•8ëÖ	³Í;  ­ÊÉxTŒ”¾ê
\Ğ¡{áÀu8Áøƒ"oÈkhçK'8}ó¦Ç§€¡sE«ú¸üxl¦éNÖ+ì¤°@áM£O¡0Ñ“Ù8C/ö†0éòL&ø%ôs¢Ø–cJµ‘YÏŒ<B¼2µçßßˆ+'E=g#ti°¼Ïâ£{×ú»†“½.ŞŠ¹+×YJÍõ$­š3Á`ƒC1`ü]”<gæ+q´²ÕDû¾
Çş¼ö\ÓĞŒ]Sr€JE´ÖúµZ®«TO \|sØI}õ°´'­!ŒX­N”ÂÍÜ-axbÒ Id«:¡vêŞ~ÕÜlX¾Îê_¡r‚wVŞ—·8.VpÚ¦–º¾Y“%jõ8^‰S{
G$qE››S°rÍYÍJ—¯ğƒİÅŞFqÑhbÇEQKK;–dQKZôtuØ>Íç%Q/˜F`†İc0x.RK?1êˆpc¨7‚*âÿu¸1Ëë º|HÈ8'÷¡íÂ¦©m¡_1Ø¯á°LAìRSœªY3ÿæ•ûùì·¾ºf Ì·ïõgxì¬“/è FŞGíï…ÍÀc
m,DºXI¢øeÄ½µ. Jç?ñs(Y€[à±VæïYf 	gš AïŒ‰Î¶R¯ ƒ3N¿‰É5ãß¸g­xÙºuuG‹3šú@Œ¥Â‘€©Ñt‘px\Ò‚y9Iì§}4îRa]ÉâÇîí+Y~'QÒvèÅü^@#?DfÀÌê¢:ÇĞ0’#úÛ;h}-}İzÙYøx ã¦jÄõr…"X÷Ÿ8p"85%q³é\i¡2ì"EâÊ{TZí9ré‚…Ù›Õ`¡Àä¼ò«¨D¨l0ãíµG£º¯@ç GmìYúa{å¾ÆFa	OÉ&5ìñ­™’VV'şügVMí!ßw½-î²Ÿ/&€m±µ—¸€ß—ë-½÷“P"”)–ŠeÁüîîQµÕ³Ò¡¶9ÎÙ`Ğ~…´ì7Ÿm!°«‹ŞÑˆ”ªü/Üæ@êñ{?gÌ¹Ğ;5¶^aÌ$ ÚÁ==15 âĞø»ß¥~§ş¦íLİIpj Ïåì4ú˜îfÍ¶{ØY/+ï“û8E‚OûÁâpG»~åz+>·ÂS3¿cZeó+AúÓ°‡-ûÎŞ-	.‚Ÿ%P¥‘_]¹†Ğk“ª÷]A0{ËÇ“:üJIÖçç6 öz^	Ÿ£˜b
ÔÿQêÂØdÜè:Í¡­õÏÔ:‰¶:?¯ˆj×šX‹>º¬§ç?´«å	÷kÒ)€IwÒM«ºû¾-ÁxÑ<!2ğÛ÷î>ÜßìrC¼1€_IËIğñjCYó;¶»èùù8vµŞŞ…±%SÚPíÀ‡hgdSHá­¸ğûÇx—aw92%ğ|¹×w{(/rØó/W^EaQÂ¨Õã‰ÑOµ!‰¶-»ğ.ÔYÕƒ*>¾Ò®8ÂÅGlÆŠ¶ö)/õ<ñGâÖçd_
–¾qåh)ƒÔ9cu¨ZSõ4€6.s›ºS7ÌuÓãOnSqrSmRàÄ9´¦ØE€~,ğ?9×ZeÂl1†ß¨^ÅŠ•eÿğ;ç†›şûÇÙ²vğa$á?šŒåUT»ß	µ¹“%Ü¨ãº¼Éßv‹™}CÌ°®os'#=®"ĞCïC*‡“ã4Š:¾T¯ı7”ºƒ°«·û¬®i¼6^ŞkPt0ø™õ‘øP­­K±ãøÏÌ§œp”²,!ì³VDü—@‹6¡'Ì-H«‰HßÅ'0h•Ä%¡ïm1Ø.­;£-y) ‚º`İyzàPºç¿dè‹á`ˆm"­L)é£Şh·ƒâ§²¡¦ )_£zÕ{‰²¿¯ÁÅşºÿÜT¾§R§ë`ó÷ÜzïÓ	mWÒìv?iÆ>ØáÇi›_–<å0NÏ™n¤Ò½fÃÅ)Ñ©q–°*›+=ä/å¥éå¢äÆŒ…éìÌ!t¥¯{  cŞÿqk@äåCBn¿èvyl¼ÅäbÁm©ÿ¶ç]øM& 19-‚ScÃ…æ	ˆË.NÅ êæUÊXŠºdĞ¸Ï¡J%¥Í5xë,p¶‚Ac†šFÕ•qqaßSæ.ĞÈ½3ÑåìMUA‡Ô:³\=Ÿzù­H±)+ÍíëLÿ¬<üÔd\*N‹øqÜ©ØË]œ$.ëöÚÄñ6cí~Œ(òÂ4Ÿ\MãÁDŞ$Äàó2”Î¢'¥©wùQÓy«†T³Ú¯ÌuŸŸ,² ±,cåO¿Ã#bô÷[ü¯æ·ÑÑïG>)µ«qeÈ©$×zÔ_åq–ƒ„’ÎNí ­?%h ^¢mLyï»mÆ«û®ZxËÃiLn´Ò´/ïĞ«!/€
ŒB»@dPU,W»&6¬qaOñ‚¬‡bÀ°7¿Oç5èDy$óÁs 9Ê€¯ÒùóY8ƒÊ˜}Â¶Îîşç§5*˜A’Ì¬´ß+ÛîQËÒ4ó8Ÿ›*ê½ûNŸ¬NÒà^ÿ®»Cl4è…tı&‘UXÅ) ®MHĞ©º)/•_iËg€UÚ,Çy%ZåÖãkÀSë;JnûÍ2Y'wÇÀóÿº%_·ÌîL·Ü66„H7)Xå2(]¸›]ü+½‹ZhïŒğ2‡á73‹´0É`¸õ7Jg`éT¸]Ç”ªv»§³áÎêyÚ‡ØÂ0úZ,×)ì¨wd}zúŒãÒ Ñ«DB¯øwQÅüÛìæ2üF”?Aïè‚^¼»á‡‡vdUÊñZêìÛ¿+?Øçşâ8Üq¯š¢fI=ğuÀİïÂÎÛ(eÅ‰Y¦ªˆ(Çó?ëıå'óR™(?ª4hè¸C
^Ë”®£ÌÌxŒ#”¿Êa?ô‘ÛëÚÕ‰…¸¤sw‹i<³áİìÔ»í©ªb®jE!a¥egŒƒ{€z?XĞ~tî§¨brLTâäGÍª
q3·t:Ø½¨Àrº‘•ƒ¸3˜ş¿¡èn~mâvî.‚ie×¹y8E;œôÿ¥wXk‹•¨èÕ¬G_|ç·ì?/İz˜]Çfâÿ&i0¼`ÌÌ?´/lØ bö¿ÏµA±A1¦–?Gq@OJ'ßwYyåöfêêqtæûÃ¹`iXjİ‚’ö¡„aÖF-Iè\–¿’1kÑ}ª®¯’ØnT°¬=Ğˆ^!õ´FÚš‰–Fcª·/¨ÔÂÄ'Û>}wúô ª.‡TBxŒx‡¢|Î9o@Í¬ÖÅ¶éÜÍËŠ†ıä«©x¤JØ‚–UÌx+n™öt×ŸÔÀíi~oéìWŠ'~=4kŠ°ğÕ—õ†w„…'C-£a¸ş¢$âòá­¶èíßÜÔi ¯aÔ_ÜOX®!·nµ&Ÿ0G×Â‘/ü,_‰ñrkUÚ‘ô`h‹¨M hB)ıXS:E¾€Ü¢ª©eGã÷Û½²÷X^œùŠ·TrŒáRÈÕ	-(ä-[p3[‡úŒq¶0ŸyÜg³úiÆ­Õí0G¿˜h<C†ñ£fèìà¼}¯2YïßÇ¾¡¬Ä7…6¡*˜aÎzˆ*çûšid‰òÌ~5½ŠyR¢Ó‘ÃŸ’ƒ+üŸì2ÛÛÇÆÌ7wœ=ùqÅCtKyX±3;Ã¿oñÊ/+ƒõŞ€ëAtc	6Ğ7yjS•Â_gÌ|Œ~[zsö³'3rÉµz¥øä>–Cy\4;—™&³ò"STcÑ€KÁÉåò,¼ùIGYl=Ï1s­­h‡/-9=NÖy´³Ë¡ĞÅô7áäé4 ‡è7ñÒAdö;1ŞƒÆ/Gş…ÅªÂV–jVæ˜±ûÃÈšßr-çtœxr O‡ŸA|šíq•^ğõgÛêSF>ñ©ûòÅûQÎ™ŒCx†Z	+˜İ½¹ö\Tå±ÔŞˆGáq³Şâ9:U™8f»¾’Ø:äj	ã«Aš×Gc`€ÉÈZÔ)ôÓ8¡Îp€~…j¬.…êÖwv>Ğ€L/§îß×6Z»x!tšÂ#Möõr9Ù!^XòQo:ËãÔoq«Åbq˜¬Á±ü†«ä¾[/ŒÎâ
µŒÚğ{ ›EW¢e²nùGRÿ*°
R}ğ1¿–Q_»§§Û<Îëé£(;0Î7 éiÒ“ yË‡-Œs{PdOéÜÅrMà»;[”ª;¿Çs4È¥š¿÷™ü¦‡øwÔ?Íg@(M.±½î~Bv,tÜL÷˜u‰§qYÍ‰÷f‹eä]æÁÇıÚîJNUp½˜¬-ÌFë1óŸJXxÿÔõ~;
ÿïş:EGÃ½  oŸ­‹İV’?†ü\È)eYØ‹Æa=Qêóğ
¨
QMŒÒÅÒHÄ–ì,C•Bõü%çâ5ÓÉWê $KCpfÂãyÖ&œÂ^®²g³\B¢mZ§¼A)Šñ }aÑ¦™V¥°×Î‘1®±?¬¢¼%ÀĞ^½¥Ç2‹"RƒÅ?±Š¢~×NÒ²QNš±ÉÃÚB8DŞœM&ÅeOx8-{éS_zÏœ‡ÇåDBd¯$»áæ4ÆIñ÷èx©/Ä…ÔQ\Ó@ ©óW”ó%!ÄÆ28;ÒT®ÒZ¼zpXaI#.~_vå3±„¬cD§0W|DV™% ±NÆl2Ò!³şäÚˆ‚œÉ‹Í³«é¼<ïÙğºƒì \AÚ3&+s”ª^ÍÜ¦&$Sòá“À‘gm‘*‚_×Ó¯”Úˆs€A†Šv*• 4LxQ8YÓº²Z\c2Â©-V{8èµÌl”VØbèJuS ¿dÊ|'+ûãJ/×tØ&7YÃ›F#I7ŠESÑ~¼+i[˜~jßq‘Î¾Œl\<³ö/¤¿XÈÒMë\ÁŸ‚”fµ6X±Ãf“N:n´ v>{R	1Î¥üR«¢¯MjBVs	¼úb@tA
'•¢UrûB¶çr/¸'¡s©rvF®´8‹z´ùæU_dHÑ WC&•ÖNÒ€$“?
´¥ÄCW;üæT†³·(ãÎ›¬Ç¡7/:[á%«I Ã# ü†NT"¤UêÕ¡R~÷c™•oµÎÒ%TPçºèqá„íÁA^Ri÷~ó+gì‹&UõkE¦Ô<#H3–T)çR#,‰ XôôûLç$N¥Ó…0¢j³S=¤Ár£GšLğ(yó›úAèæ_:šò“	i›ˆf IcËûÉŒ€š¸ªø=­h SÇgæşâ18Déí0ç.+mn}±Ôv?_›
Ôî¢Jæ$«É–’h3»Iµá»^k%\ıaÙŸ™Î›>ërŸ`kFÃÄ`±®äqßévÖduİ‰ÃÀìèAŸhh¹ğĞ{ÎéD
˜:ÂÚïSÈø/Rã˜ÛC¹å.±,Pö,v{±Ü]…ÇsUU®ËŒ‹_eô®=RŞu¼“Í\û¢Ê0Dî,¨+¨¸wgòŸæ0ıcLas8R®£ş“^—H%qª%áBy~OPú~02~†kòÿ[­J6ø§Õåû¬˜Õˆ£Ù>…ëá¾Ó`Pfdp¢‡ä0äî+ñÀ@ÜÁzòîşÎ5Î
$“ü.õµ±<=«ĞJ–~stxŒ®Ë;LTÊĞT‘»j1QS‚ÿãŸû]ÈFlCu£J‹y7ËB¡¤X»v:¤H·X¢ÔÊl!N€¼ ë+ØÈüúu=…¢RmÏ¦Ï¶Y:UW¦ˆœ·—ÕÊAî®TÙpüL¬ºÆ]{ÓĞOÂ µçÍgE}ãÀ[ä¤–lß;iä…m5Õ¯8—;'McGÖßR×“—f	:®‰š¼	Ç†–&Ç ¬È­‘îÒñéûg›ÍrÛ’ñ0ê|jr¨v×iÍJ©L8ÿGc9~>ˆzÊ®ƒ”§™n§Ôäjßå5§UŸ¦i¥7c!ªP¡÷bg”lıI \›Oß
:âÍŒ¥ù£µ9ã=ã·
ézurM7è‹¤œ6ŸóÅhcÀ‰¾Æğèµ°‘³J-2N	rºø°0ğªàæ«óèºÑu<ã3Zp8óá„)ó¾‡QÜùò»œšFÄ<XmÚ(Øu6ÓŠüI>UİTKVo@ü‚xİ(ú=@ëé/Ú[–1C‡Ò‰Àÿóf¶¦¼¶Õp6’ˆüÒGmÛTÂvI2N¯542¼¶&¶]O„Û-Éjß«o¤‡‹å“…pIšBHa<¿ØØçe“v¤P¦¿
4Ío¤rw>.…ïßÍKô‹åòX¦äì<J™QºĞlÆ3ã¸c|å£Öp dl@·qnwT¨q1Î©+?o2¸=©"§‘ÓóàñİvÆ©“ÎÅ2ÆÙr¶¾aDBHvÙïPË,Æu°k5ã;1O’ÆOoÉswyˆó<¹ ½ Ä¹Ü7Ş‹r¤˜q WN-!îK¬¹?&¯şw'²	ÓÚ?À2t¯ 5éÉVUÄÙ^aP÷Îj ÂÇ&¡}mzTTˆà(îØYg[›™è¨˜D¿ı…ópf>¦G
\	ç:Ú3ÿ¸ljÔß?a~Ù®5FĞ¡TtHúW6Ê0®óÚ§AnuõGn*Øzì[äcâ1Ùm‡•¶³êzSÏéÑ±•áizoiš¸³Ç\+³ªE•¤y†tşv~ë¿ä¯Ş<+$$²ŞXèHƒ”u&Fb·p{à>»!¾…¡H[ìˆc¿€?;‘S!ÀĞ<æ¶;ti+ÔsoA>Ø/y-ÿ%í©üûëÎ›àV__‹İƒÂd—ÅÆÇûdÃˆÜg˜¹0¡? 4šÊŒDNu"ru ¨˜”êtØBIê„B6SGÒÒ8)Új¤pì[Gn»z0à¿]™D	ğfåPF‡!Ã|sßMüTú_½ñèİ—0bs**7nßï»'3‚hÚ¬‹æ¹w<¨Ùm2hñÊ1d¦yQã×hdúûÀ5ôˆ]Dnb.´ĞzàŞyƒ½ğÓ”Ú#—·•]‚º±Ø’½Íµ÷
@aümak°k#mô”yíRf0°(‡ÿ¼ŠÛ åŠ;Ë¼ò_c¿evoL¿é0¥"éÙv›vĞÁÀEÇÎ´~û:©öÃùÔ%~tëÚîP—8ş:9©)
¬Øâ~ƒh«SÔ:V…Ê­´\Ë×gš'œU1‹êÏWt*nJÔ*ó¬ûxæàB‹_»Ô´)‰ö_	iÿ¤çRêì±8òĞ/jwIFg*¥ììÚ6‹Kb€w;Eg²êŸï—Zm‡ÿL?îRßÁç¢hqì{bù¾]æ?ş³Úàc£r»>Äßòo‰ Ç–æã%L·å¸ı¦å›ü‚iLœÖÆIxæ(ÂÆÅdíAc3ÿ½Ùeu:tV?¨ÁE’)-ÓšŒrmy®2^(·ï³K5…9òÏJ€J)u_‚ \}#v±:7ªÌÃšÏbW(Ï(ö…bˆ1k¿s¸¤„×¼JŸco‡´ùTs¡DŞM*µª¯æ{eS‘`Ëw÷Ğô©íkyI7ûØ¢Gs˜H¾C€èsƒÙphë«Ò˜ÉT;¾ŸÄĞ :ÆtıN¤£"G‚­	Ûü+êò3 KŸÀô6ƒe…z’¼_w:>ü
‹Øå¾jÊUfŸíøäÕÛÑXmKÏÒì¬ğúuÚ¤æ?Æø#qV¿d3^2pÎv4õ!‚n¢sª,4š!,á÷)’VrÊ[ĞbÇGOÜPÁ'4‚j³¦%eãYtInÓ¤’"×¿±…¥:½H/ñ+éÊÏPÑ6m®®Ã'ÄEP¾éß>¹5Û7yÂã=–½Ğfâ-Úd¦•æ#×z0h¶	–×)ª¤‘ŞW‹„™Ä~aÓ*İt¢%Ç]£B4÷™ãÎÛ[’ÇuÅ&]_\4“QíêGø¸][AM‰Õst®Y<ãø’é'!"ç¸zÍº‚EZL4q°PRjş|‘jŸWêXDgİ™oÒaIö‡‹¾ÎÃ¾ƒ~Iã‡/?òèòºÄx
ßjJhê×‡Œƒ=t7oÔéÿ±C[OŒ7¢µ;^ÁgŞtGƒlñŒ´º&±§løÆ¿è“¶/<ûX˜Şc\ï%'ƒXüCCæØgm5r‰d
Ö–È¬lA¹ØØJ+€‘´NŸV–¬é°£/IßÌ“íd¾yÛ1mgœ;)*®3hä•vÖs™E½§ÖD —}Õ¤õ2–ƒà†·OÉŞß Ó*|ü½uyu‘OGªpÎ´›4»i
õ%y¹…Nx:„úôØªª¯ëÃ¿Ug„˜«Wğª:Ï­á¢aïùKcò»ôn@ŸŒæ+w¶H‡ÆÊ}ÁÌ”#?©Ã[TÑÎx³y©\æ†|›Yœ‰±°öÈ=Sh`ù¿©îğĞâ²ãÚúÔè
Ø>'ÊíöØß±‹åÌÀaoÃ.œP5‹óäaw/nÌTbNÔ‹2İ."Æ´ueMa­Úö0ÒÌv
ûˆ)Œ~qÂƒúôRp$÷!7ÿìÍ¾êÌĞ×Ó!øµ¢Ñº0fh””*úPEOºÄëG?N™©Èb\pÙ’ğP·C>zÜÙèæÉ†÷Êö‡ã“G3'ìÁŞâ˜¯×è
ê9a*6Ö—y		AB'3†]O±ñIÇÖŒwÿÓ
F‘K
Ísõ¤V`R=ÕMÛüÅJKVB¤¦ª«$‰ŸU[\TˆQ÷[›Y(›¸ª&?©Él LŠkIªExÄ"Ó
¶á.Ú4;×Sp·X{~o³—¼ÊÌ’$-ØÙâ‚¼›÷¨2ù¥°ícdbg…3¹À‘‹C·Ÿè%P]›NB{™^/lÈJbdöúMmÅê5\ntœ^0ñ¤øÄ•ÈÒÊğá¿ñiYcŸm×M*ïÉ/|™%,¼æş<2“î5dŠfªòqc¦jÚ]_ğœİ¾û:?Gx]ŠKÌpïïuáÜ‘á­Ë[>ª‘Úqä-ëso]9Ko¦¬—*Ô,veo„ÓK5
[Ì:ã7K&úpgı±Ğ[uüĞs7cÈ+z^­æ"ıªaÇî°Á“=“]ä/ïîêhcÓLÜv÷;Ye»:²!û÷şFÀß6&"1U0œböö,=¤pQf^)‘ó[Mor‰IìñCº¯ uá
XT
r»¬õíåòÊú±xÉˆ)øIÚÃbÀ]ç:~ÉÅ¾vç ³c?´şdîOÂ›Ø>ªeTï’ÜÀ3v—<ñĞŸêºòƒÑ†$ögz·ßiK#ï5ô¹öóD„‚PkÎÈ1¾ÔurGS¡VZeI¢xËHoQd7f™Iû.Œ’…—}ËùYÛìA õç?×¶bË„ôEpü~4ŠÒÑ0}& ]"¢¢œ:OÏ ‘óöÈL
(gº"ÌSqáÊˆ@Ì¥Ï ÎõY³·•ç Sˆ> &òe2±­uÈ®€	¼bÔŸì¦®N[8°åêf‚Y÷#ï;·]HUÜÉŒPi}m9Ñ¦H¸õog™¥Ñïè+‚gMsàz&©Úuó^ğ€.ÀŒê€$œà
‘½ÕL¾ã0"ş±G†ïÚvÙçêÓÖ4R8Qİèk€|RÛÂx 9ÅnıÿÔu‘œsé«¨éñ%q´œ¤ ²Ì²S' T“[Lwâs|Ò<ÔFŠÕ–+OŠ2û’°=‡ÎyPµ±Ä¹±Ë0Ç6	h1réHèÅÅÂÔQ~JkğYh ¶o;Ó£uÍFlh(IÎâ¦™v¸ˆÒ)9á–~ï€¶Z'ˆØ^9raŸ)	Ê‰0f_ğn¦¬)V@¨ö·*>à°Äo	¾M4`…^ùß\&B œéùÆøÆ€xw–´I‚A+Øx>éù­:şC¿_˜*¬å¦¶EƒãıaMîºĞÛ°“ĞnB³Mtú«¶Rt G¦NƒÄ1F€l:)Ğ\™|½¤Rôy6ıÅÊ¡ùñ~x7‡¶›%õåó2–~W
dµˆNt^VŸuıS3¥g¸~ï¦ú4Úß‘V6ÔÈÑxpia;*wêç/Âåó÷@jŞƒæÛµ|÷+‡®—Å}x¤c0aŒ›İ•Í.¼Ä¹”`„¿–¼²YÄR›¹•áÅ¸W£Pİ–ı´¬úráQš(<Â1ÚBvBoUaÂmú»@ÌN½:”ı%)[|ßèë/_àïãÌAÜŠÌ2•H¨ÈŒ!ÉîRpI3!49Éşs(kQêL€ûÄjğ¾÷Góz	®K:ğ­²”EÅ¨~LÄŒL%NŞ°aØÖ§Ù„Ä‘—>åü¿ùî)O4r_ÃËXõfÎ-y1áUÌHï‹<7á&¹ÅVAì¢²v:—Uoïvç¡NON
 Jà¬^ùVç0Z\äÖc†/İ´:uy!7t'¡|	$±D‚å}"· îÍÕúÆ¯¼æ:W{„j‰›õŠ¹Ä…ù©©ÑÅÜ\¤{áXğ–ûÙwùÕú^;ï<TÛ•‰õœbµGl£‹èzsóÜ”8Y ËDl®õ`égş«LQk“A|ŠÍ,ı%Zóû¸úußhúk®<ƒ{İÄr`x˜“ş©g[éiçO°úùh£œ†ê»2"OİÏ¥oÕÉŠã¢:§bN#ƒ•zOuK¦’áà–¤GnåÀ@’‹2lé¡Y±ò—Õh”t›-ÍlOŞ ¹}®ø•%ÅÑr{xP\áĞØ vBlÄ¯i¤”‡şÌ;6F"ìåkkX¥VF•Vu{@å:é8‡
´.¡+šs(éÿ»+Z8!²{ÙizÓŞ×'?û"¦ÚÿäöÍ—é6Í-®ĞİÙN—ğ>ÁYÚû™…üCã²oi‹t—Éı2`À¢ê<wdĞÒ¨K‹üõz@´Ğ XS™¨¡U0ÇˆÄÔV ?<&%B¦#óYòxıˆdVê9‚ep†0¸[l¢Éå	?pÇÒ«^…ÈøŞ‘Z3~ÍXªuĞÀÕÉéëé®E
¤jBıÿC‚I	CÙĞâÒÉ*ö/¬Bl¬
˜Í]§êPŞÄí”nÀ½]x>§,ôcàº)¨åÛdÓĞz”(lL(#bsn6…¼ j8ÇŞ£í¿pyíqŠTª|‘wí#´¬y-bú`˜{f¾¿oƒ.
ú3m²³­ÑyÛŠ ¯-úi"Zg:šëá¿I…z8>,œ§G±ƒÄ“¸láœÙ$MğfŠ¶a(-ÊñI­)}¢€-ô rWß#£ÍduZ[;Åí‰¬kµ'ãZôB9T0G2;¯¦÷rqÚ¡ø…µ¼šÚ_Ÿˆ‡cÚV¼ø¿ÔÏ6D!Şí4WsZ}İÎ:ÙD"›šx?ËpJ m8r1Œÿ&VÓËöw=L‹T%Ñî‚æÒ
¢ø[Ôû-2Rúd„‚ÕDãs2	ûVŠ79,¤»o—¯(Z)îRNŞh|	Œe`)¾ñí6Áñ¾‡úÍ/ş”´¡Ğæ'«v+wn›LÇşg	k¨±O;Åâ¾Í·èOÒÊ…ÈÜgPh#9Tw—•İC?³Ö5ç£ÒUPùqó5ƒ~=Íµ´jöÓ|Ø	ªÛï±q«7»&Ú÷©mÀG2\6ñ
LBwíÏx€Uş;|4ü7,zrCôÕš¼g×…[óóªÕüIàx¯¦¯¶ù`ÿOÕÃÒGz±ÂŒ)ÍJŠW¼Â¹ùæxĞ ~«lßò­ÛÎ†2H5ãÍNd•í«Xä²z^¿ığàß½½tãÆ¹G“ÈStYj¬8,yŞøœÕ3uÚ©“IäCGf6SÏ7ƒGãº•rz– =C®-Mˆym"Lb©ËHùÜå×¶[¡j€Dİ?LbQûÙ@§kû?«¥½É©şûaãfÕ;7y¸p†á1ÒõÛ ºĞÑ["ºIb%öåÀ¤Lî“FèQpÅ ò8}2Né±V¨w]CÊy8ÆQ1¾1üÏ=Ø-nÇÃˆ§^]-DCŞR7b+µ*ßA^Àt}×*ô _ù¢ºC)›¤¨í²bø~ {Ë©‹³¶›€¬ÑÆ‡kæÈÀÊúİåùÄ¼x£—gè—ï‘ªˆ‹„3*×Ær ù‚‘Ş*­Œ:ß"¶ óğ¢*®ƒšÆ4zævSĞŸq¹àõÇò†r5·çR_7UÓd‘«ä$ÊœUÏaRÁ Ènk a™ÀÍ¾ïƒ¯.fËhW>‘±±aóâ¶Åä$é!3ÖÉUãŠx…!E9ˆíÿÚÑİŒ–qN9™ 9a£»a:]@“‡DéÑûsXââŸÓóø|-¦8SªËC¬$Æxş­Ñú\·„ıùÀGMlÕ¢™fx$äÿ·8¬Åâ.
)$ÔÁÛb–tÓğ•WGÖX6äPµÉ}¡aUq¼2gßÎ"cBhA€füyÔWãwz	ibpW1éıXR +ßxì)ß(åM4FUïWä ·Öjê+!×ÚpúÌM9ML‰Ú£‘ùÎ9V'´ç[½úCÆŸV´)4Ìÿ„5·–ˆ°8ó}Ñõ[w{ŠaËË HJú›¬]ªÁ‹\\¡kÃëoƒÅk‰0³‰æ…“—¾¤òu¿<ñµîU«> ËO¶CĞ+½ÿPc^®•C°VWôª0Aò¨kÑŸ¡$ÇBçÅ'‡Ùàşæ.VÉMêv8Œ“xVaµ«E±axÍNròï*_'íª°´ïi?oK+Æ®XîáüÈÍHíÌ÷o#Nû'¨Ã„ƒäxòÂÕ°ÇZgXÙSê‰'ÖùC/Á&ƒT˜ä/ø1á
‰ı‚¸1›_Ú++«k+¯÷OŞ1§HYcùpÛ—Ü=7a~`‹«˜l~{‹É#”:Å¦¢Í€Lš âkİú8GIñƒ¹cÁC¡öÑÿä¶z¸Ã!qŒ`Œ‡_ß+A³NÊªÂÓp˜Ğ‚N—¯BÃĞdß!¡j1ôóN>‘U©­lO2¯¬k2‰_fÅw6”Ÿ»Ô™î§-Ç[ëÁ|ò(b$féK{)tçƒTÀp%KÕ£ÛQz'Ö~$KÄà¤ÄxÏ¶Š§|ãİ]ÇQI´ m+Úüq™¯OIÍŠ›ãÉ^e-‘¾ò×ƒìMÁà”lXèà<õáê ( nöÇĞÊçå¹Ü_‡k’šÏ4Ê]‚Æë8‚~É±bp\FM˜Íòe±½ †ø˜/V((Êæ¿@ÅñşAÚÍ2Ÿö·d#‘İ›ıı¬8$úA'øúwvN³¬¤ÆZ”Ç&zl˜
…Ì…QÂÒ›¡ ÉD«>ôÿÅõ÷cßø:¹®^ÂS=rwß©¶eUSÌeF(WƒEü˜¶ãâ‡®é}³æ"N Gyã8hÀì³M1Ëz_W„	Z7öÏ6Py wúI‘§kİ’IÓû•TˆÛÔ‹­¬˜$ŸÑüsQ/ƒ
¡¢çãÏÙházÁÁB{
“Ñ–¸{ "ğı«u‡#ÓDWÖ»®.ş7á`YÌºCBCM[š½×°ê33Róm¦‘š¶îö¾Nªì¦k? 6]WƒˆƒÔú»b*‰5è ë ®ÂVã 7¾ êo™ígç›Òòä¥Wz,Ú¤KĞ¤
~£lŒŒÙ}ö–AlA‘X&ÚBI¸Tt;¿S¦¾`4`®ağ#˜ş‘ùAøõoÒ~«å„òXå‡äÃ¬ÜDcıä|9ú¨Û×_ió]Ì†#|æ
eY©nÇø³>)›'Òçí˜å
ºš1/¨¶U¦'ÃHíàM¥9À·Î_bï<Òª~Frïş—<è-ÄNş(òv¸•‚ÁÖÉiÂã@_à%`£ÈK­i ˜›§‰T+ñg¶X±‚TåSûZ}=:ßi-ƒ³™¨ƒˆ§bp"-8ªÉôToÒ@´Ï£;Ô]üŞ„@1<òiƒk„¨Ñ¹f±Nt¾0b„ê•á«SH7&	×°w*ÎŸxù©Èøi²«Ú(¦uëîCĞÜœcû–“ı	h˜3¸ĞUz}ÛÉƒÇOÍNåAÜb°?‡¹	o ­8Rç™owÚüd¾ë7Sï$>€«Qwfl–UqßÛÀ¿¾úLSÑiãé<‡®2¹R­ ˆ¢Òôéaf·=Q¨ÿuÌC~0Ş€<½s"2­~‹>zÛ”ÍşººğõÁè³i´ƒáíi:™‰İSršDÁW×¥lVŒ“w•	ìÖß}ÛTéjVp*=3¯GÑJ«-¤k0ƒ"4}‘‹`öFÉA8uñén³ Rzf¹¹&_Tœá
b‘Ë‡iªÜM€“`PÊF€ÕìPFÕËRúŠb‡+ÿ¯Å©ó¯4=|ıœüi7!«€n®;_8$› æÔx¶wıšä#ÓœÔ:&õÓ7;<àÆ6J#AÆ0¾‡ß¤hŸpï8nşŸõù:ù±ğ¥´éÈb‚š³{Í­Yt)»:/RÑ‹÷şÿ ÒTöNı[=™øOËê Ô+ù”:B7÷òĞ»÷6)^×A¥n4ŒÆÖ5yØó>ß·×¹<`“ÊŸ+xæ ó7S£ª0ïhí´ªæ|‹Üíõ.,àh™³ó…¦f-óÏ)ü[ WQæFrŠL×I!OLGñÁ„D”£3v1€ˆİEÿüi“Fí“²‹|ğ¸(‘}XmÆò3|x#KÑ÷<#3)]äzÙ[àQ+_ù]ı#1(Äß
ÇqıÚ.Ôıç=£JŒı›Kåƒ¯¿¢'ÙñÏ&¶¦bYœPûc¤ööºƒçËJ7›—:ÏPæB¹'Éía†¤5»4!((•†ÃÑü•7Põ¿»ã‹ÓK–å>$-àòOÅ¨[-nSUiı·™_ûµåš Š>Šïœ4§â›ªŸÅõ;Û47d“íøMÁÏ”AØ2‚ŞÊwÑ	gĞU×1>¬O™Çb0-<~X¯N-ŸZ&ÃşO±„
6‹gFQQdûsÓ+,,˜69p#`Ï‹|
·ŸöDÙºèÖi˜«ê'ÎHxïonÎöpSìZ,1Igã.ïZ}o\åQÌp–Ã‡<åzó›%•à¸sæy#oòPáŸ™kLùûYFõ¶ë¾ºÕMŒ ,Óôÿ# örĞ€üˆSùšU¢GËYİÔUš)’¡çagF»ÿ›(”^DÏÅ™²Z«n: ß?j­?šıq':œÈæ»¤ÖŞX0&Q¶ƒûó(‰”¿õıaúMƒRŸÆuí‘u¤Z v]»Æ<ÙŒoZV±]wQÍÕ'Ş=:³WQ¿àYFçù·±]¥¯XvR^æt±_?AïËç½agÏ+%ÙáKYÂEİ¤±lwºÎ;‰”/ +üÀ¼“{„Gı‡¡ĞeÜT7€ÄğÌÀTp
à®ì¤ƒ&<ºäÀ<OÔ]Õ¶¬ûƒ·ÿ £÷ÁÊ”Ã™½	Ùw¶“ıq-_ï©QT”g¥¥Ö0SŸg7ï®Ãæ˜†²œ­İ”QIS€•ıH9Ù0ŸÌÜy2¹º]ÊÒ	ó¬ç¥°ëöùô'­b•U»ÚˆÏ‚õ«EÒ½“†æ*»Ôö¤<oÀĞIG)g›/uĞXF
ë,—ıÜr~¡S§Ov4â|¼3¿‡ß‹ ª+§‰fp_\vmòãÍ`”L0F)¨§Yù‰t¸kQv=æz¹U¡ÆİXÁé´Mùjİ?¨ú½åR«Òy« }õ6aòjS,}—É”6Õsq¿jxì‰ĞsÔw¼ş3ÜRbß\üˆğ6oŠÔ?hï¯Ja@´ÑéTxlnv”§c—]h ¡f²M	¡%à^Óğiÿ/ùîŠ[YåÈ.Ì<}¸iåŠ¦Z‰_•ÓìÜ¨ìO‘µ\sùƒö– µÏ0{-Íöß§İ,‚€ªò5µ•i8÷·§®BÛİFã¹@ñ¸,yQŠ[[àM€)kQ8€BËt9ŠßáÖ‡TõÆAæ1£kšşIH=ïÀ½ÅÙÖ½/\vÛqò3­É„D÷*[¹Ô”·Bb~Ûîø×BÁ+„ÒÅtÆÉpi¡nÙ‚k; ÇÿäLšcGŠ^:@gUHÌÀS„Xz–•ÁFJóºPİV„ ”ÃHêÄÜ¶eĞŒAUN’²Øšƒ&œYgÌ%qq_à%†:¡ÄYWİ“1ØÁ°/Îõ•¡ÛbÉ§™1±œ `6A¦”ÜÎHÌºNEa3¾2ïtàå…2N!¯Åb43ŒæĞ OL¯Ã"a5Ù.Õ£SÚFFc‹P:+è„tàcWP
¦Á°BB¬Ÿ¿Eõc‰ §zv× V™ê eÃÜ¯Çv `HÜ±YG­jmc+ÿØcBK=f Ø¸ûqO”üİÿ#åìv¼kÃãù4™#*LÛJO8è×¤éTÂv£ìl‹«G„^”âæÈ8’&¾í ¢ê7êûB5øö0fâ!Ÿ@ÖGÛeNj„/~œ9ál…Äü¥Švµ~nËÎ»"ä4‘ö œ1
VÛ—˜{8\ÉF¥=¡ç3·v%Æ³5s×ÕÜ1_uet2°Ş„óV˜Àv´ewj*UîcãY”\€ÂÿÁC(ìş£¯Uñÿ‚Úñ<7¿I#ef^ÇHuı*/®"i,g÷v6$¥B‘¦µf†¾*|ÏÃŸZÁf<ä!ù ã¸,;ºšDPLÿ£Ò'^é­ìCÒã¬ä“á&"»™ÓË >›¬ûÆìÒ~ÿİ­'ÄGÎ{³×ál¹É“o›`Ş@Öò›İÂ¬‡](ğ}%ò9^\/hô×ÖCÙñH)mz¼|¾ÉÈ¹Òå İ¤æ€B ¥4êsYÖ+{v^õwFÔĞK4¢¸R­ÜÍèw¸ÍDõ„ÛŒi„ö’&´ÑYßvŞÕXĞÅn%ûÄw¥2r™‚"–Õ!äÒ8í-nïr«¯Â’º\&‰86A	ôo3cy¶¹µiJ’â@—dLÑ,¥šÒ.<y²‘M–’Ã‰§HmÍòú"‚„ášÿOJï¥ı ô‰ÔòÜç¦+3]‘šf9Û¿w¨‹u³€ m@4·<S‡?bµ—ŸXG…¿™`q²:Øù(è*K²Q¯Í<}Ë`MGntt4ê\¶°‹8±DBĞÛŸÛ‡h`0ÉX]Ü³iá8¼hö5¾XgïçĞF¼9¯øS˜c]A„u8û™i·.!wy>´Ép¶+§T¨\ğò¹{ÁASdS·ßîêh!@ó2Şñ+ÆºÊêPåc9r-ØçU'÷»/lŒH=gñaıÏ P¸€h¼ûÛÓŸÔ00°îje¤½ÎîlÊL:øãÔW´¯[Æ½á.s£NUĞg3jˆ„B”Ußù©ÇxÉ{Ó‚Ü{î&R‘–h-Û¾ÓÉZ9·ğÛ8û&~=vÕ‚Ì¤lVÇ‰qÄÎ–¡;5:j¹§›×½Ü?cª {ÀU¦ŠçŞ§Ğ2›®ÿh’½$¥SyŞhå4îùÜë2şi‘]£L{ÊR-ós¤ä¾2ræ±Ë~ä!¾ ğŸ@ /.äj6k4ÿÂ[ÿ°0´ÒH÷Î+¤.Ë¹×ëyLôó¦¸G~ÈÂZÎîFj’Ä°¶ô‚O‚™ÚÚMã’Úx¤x“ÉÙz–Ïèj2œö¹#\lPJ,£ğ/ëÇDëÓ/ªQGÚ¶›yÒ;0<ÂMS„-‡U®ÕØ?Ş™^ƒàè_ P9×î†E&°îMúI;:5ÍMTác'Ùşˆp}[R+ÙÖ­ók÷É~Æ#GzßVèú7+ÓÎ449mé$,YN?Œô«‘\±·şÉÙ#;cF)ÄÚ2çÎ >jş(THgƒ{w7‘²¸ñÀ„3=ÎåÖ«Ìvğ<¯J«_kÅÜìöíD†¢}ÙCWñÍLyßI}€0 aãË 4k©;‚fQÿ]õÇªñ¯‚–Ú[ç?iõÊ™0ğ¹—÷|{(qjúàË&1ãWR•Å¬ş@¿˜ß<¡{9WEKÈ¯ÓĞ¬Í‹IWF—éX¥ËBxµwTmµûò‘ÿñAT²8nKÿo7¨&Ïwà.ù‚©©‰ n£õ-O²ğúÈ¢Š%á›éEÃ“mÈSêE³]×PG»Œ¸áŞnô©ìÁ#Ä$|–Ê¨'Ö¾ìŒ7²³ÖåøÜZÇ=ÿ6¨µFÜE%Û“·‹YjHğgôNÃàÒœó¬¨êk«N¯A—ÂÛîpHœğîÓşaß
èèHÎÂxÎÅµ	û9Fw K`}xĞÁ«0Ï”N)Éh]}kƒ•që”0¤ ®D—´6:íhF­Šî³k¼Ô­)pF>?[í]z	&XPz³¡je›ÏlÎ×‰ı¢H Şöiáüûú®ÉïN ¯`ì3˜“O…Ö¶–Q€Ñ
‘M9Zâ0§åáL	Lº$ãˆc%j…v"˜|+Ò›İ´É’sŞÁ¶ğ‚Î¡’ó¡µnõ{†VOªj/ı^Ñx­Î'eŞ­#¹.‚çÄ)E4AÈ¡ğ1ïer»ß$”<Z^‚‚Rã”*y¹	»§¦¯E\ş|?}ºæ<::äÁğb$­»9s·óÂÉZ›Ú€Õ€¨{U2¡ÄIæ®OÓJOyÔ—ÂI4İ<æ†R¡j…Š†ğ±À@0Î¹2EÓÖşv®ì¼CÅ	PÓ¥ĞeW°	!©à¡mÔ§„u)×±Ñl„ù³û^àÖo¼(j{§æh<1/”şÆgä/!—±~–óÉT‰./›.$Ø	ª§#ûÂaLs1ZÂX±Q2
ø%Ó˜&×š¡8GÖ„{×^]²wö-ü(cì.\:êÈˆ})1È(=Õæ"L>ióß~QE¼÷Æ€Ne¶çÜ/Ÿ½S>¼5š,lĞr€Äªã±‹j-wı9U‘No4,Ô*éìPQSªÑõ(&MN¢xáJëÒn]Ù
ZA~Lò¿(/Ìû2ÏØó:oŒb8y·a§ê‚W´óQˆ(øAWìq©õ¼ô¿*ùÄM¡ê<Š>üŞ_àNË.÷¶Ë}Ğ_aÄŠÊÃœ”©æg€^èÅã†úâ4±^|”x;©Ü:û)v‘°…Røÿ£Ò
ı”Faè€»niÜ.Á»ì,Hœä£Yk‘¼YSŒvıx æÒÂ_53q ±_tO#ùÁt¨şzM?=ï6ÆOÜ¥w| —E3<xŠ¤<Ã`¡»s¸u»Ê¸ˆ£w4Æ•Uø©ë÷²WïAxK¼*‚ôpŸçÅÿ§Ä«˜Ó¤÷<-Ur ‘+<N³LZıÍî+¶&YÀX›û7€ZOijMëñ&m	xä–	,ğ£Ö"·«3`oGÒÏæuªê!©œS´ÚëÈÍkïã+Âù(í‹DÁyfŞ£§y>€ëÏî£ÆÏµ8Ã‚!ÏÖ”q›Ñà¼áõ]íğÆ¾hNPÈ²~'‚:*£'j¬ª|ÑQ|£9Á=«1›¾}NË,­“~…Ò\cA:í »Œìù‘ÃTƒ¢ ğ&K
_ a«­ı,ÍÔ‰vêœñQ„WÑ•ÒˆC!mI(°l8	:DN¸@Î@ŸÛ½JfÆJª=aœ±Å“ü»ÃAš\ƒ¦¥C0ÙèxÉgğ-·äVjM´}ŞJFË=+ Ò€“›ïVØ1\<L©§÷‚+Fp‘»à}Ü’×ŸÄŸUÔ¤gk’#ˆµ«¤µ—Nƒ|yK° ±Å‰KO>’>İèéìâJ’wâL
Hh5·UÆ,v<pÁ=W¼#Öîê`+í“÷ê’Ixa¾%2¾„ÿ¦¾~—mMóud\¸9O'GÇRkop/er×ñW?Û”:"á±ûHGqfÙm€u‘Š1 ØâÓVü=LzŸ›ÉÆÖnæ»’jXÄ>¨¤×¶ÊÚqÄu±!bÃ	ÎªØÈçtõ¯Ò­Ë ïûS®Ä`yóg>ÿ¨¬wG0‹5;ùY[’V|˜ñ„×>… i`ñ@év¸ Ø?r´TvŠˆ(0(÷Ãº¼_Ü´–Ÿ~júºUÊ¶­Ùä–’ÙÖ—Ğ3auzë…IÇ:u·Ê-ò2ó8´ÖY0Wzòµ±æ$ë¹Gq!oÏ:…y0šóÜ?!µ
»Qi¤ÁYv!f8åZæÑ’k)ääœsÚ¬€”XXûşRRÕjpŸ%8/<œJ ˆ¤ÑYƒ#÷¢¶‘áîn­5¨z}…¢eYx7áN>’ıñ?÷4# ü¯FËsºdÅí4ü BŒ/À_J¦”Y5ïb*yÔJĞ.éY*ÇetçA”#©¡wAÌ[üqâå*zİ/z«ä§ò”2Æ†¸ò‰6®1úÿ@yl‰&ßiö"|ñ}_…šÙ·0×îé·@˜bÒkCş5/ì8Ñ!Á!.<šşüa-¢& ´q'İÀásÃºº›Œ¨nønhy­™@€_¡~‘ÎaEï¤•#-"U°)ğÜj,`ÇTË7vhéŞC]¾‡XÊtybt‚jFŠôº…£~ç}8ƒBVñjKoïÿ\Æzc4.9²_ÃôŞÓµNä#¨‡­:*CUqÊkB{“—¼%ƒUÛ¸C»¹¦?rJ-hò“g‡¯»œ“’âìÜqÌ`4€f˜¦¾•{şÂü”mö•mN˜XGÿşãÛF#Kœì¡êwg¸ÀV?¯uï§êöÉ²6íëŸ´Ù`±z †´YÚ®mÃ¡¢œ¤6
8p˜¾Ó)lî&=3}hÒy°ôí[æš
á*u•Ûmïˆ»!áÊ{•Û%É´$Ó
êj±Âæ‰d~–æÏSJ»©ÆŞûæMé\ •=+€Ï/’r›ˆæù˜mİ'ùK3ğnøw„1şh¶ê)*ì´ÀŸ*«xï|z£{ëƒxØW_Çe—1¥ĞÈi,nxQŸ³N¾š5"ÿwˆämØ"*N?Ás5‹±ójì6Lb‰np*EGZ03ğ±+ ¬;@S%A³eœÀÙ Ë…;iQp HbaĞÇÁË9Ã`”T[G5/¿Û%Qàú«]˜)µÏk}„™»óQŞ_Ü¶³9éó»f>‚|Ïã6í¾iš‹†~ù§p×¹ñúÉd0‹[ø÷†cÜ3ÃVú{€yš3ò<¨g4ÇB¬»M,Ódis›±Ğ—ĞA
Q–/ç—Õ¸¢	kŸåp¸/LïeıƒGvC‰‹,sÈèîÎ{ÄM'Û‡wÓŠƒÛOªdûÅõÇE×b÷+,ˆ¹Jp¥1ïì©7œ\˜µxè´€9Ky4­,"¬"Ö'4>S:3½³ÙÔôQ…¢óŠÖóÌIÁğ~"¯Ô:õÉºŸ
rqB^ZC0ùÍ‹…¶cŠó}Ú+SEĞâ´”Á•ŞÉ¨› öşC }D-áÈõ6‘ë=ŸK‰ûEÇ¥¡wş¨Õ.Â';•ÜûEÿƒ€ÄX€•ia€Ø±ÀÃ#dÀé’TH`b«‚sj÷pĞ<œ¹€×Ÿâˆ¾¶ŒÏ/İvİñ[wm š†¤JŒ–'XX››ï¾Z‹©ĞW[$qÓŸ¯ÄÙe3±Eß$IÿbM“­Ÿö¦Í(X^y†ûevâ³«M‚ÜÌ!şÌÈ
”ih"	ø%€ûÀqïãZ=X_Á±lcDl`f…XÂƒ’vÒV€¡’
®Á@^¶ê'\Èr|I:nx!Íİ
ŸôÓ†ÌëâÀ•S—7—u:1¬§îˆ¨R6	³w§­t ¦3B»Jv?:„ë›æv$†]>Ø#)n†2‰Ö•Ğ^Mî™—&Ì”o0O×+ñ‘»s•$a~z9pn£ş {Èé˜Î5:šì!:S!¹†´\õ)Ÿ'—¥YbõxÚn “€¨ÇÙq<ÏVé^ĞŠå¿lF‰ÇáÖk6!"¸ŸWÃSY`ı¨1š¦qc›|µ;øæ´¯‘[†Èyºšˆæ<åËş‹>>2è†÷±"Ì$µˆeŠu 3g÷}^j<İõG¥Ò0S›ízÓ<›/fàbµ“`töşJÒÇ	ÑŒÚÛ>ÿ
®›ô¼+ä¢÷eÁÉ¾ ô²‹ç¹£Ä3=f¿©.aĞqt¢2°g_kF‚?
Ér$×€˜Ğ…#†g[³;ø‰º$®İ–Öb?u0Ãõk÷bÕ4ãGäé®F×¿öùí'”!B¦£Tk°­ê{ºòe<£JB(­XZ£µPo+Æs-s)@çÄ ´v£ö”¿ÿ	¯Ö_q‘‚¸İ‰£Læ·	¨°S<K ßñrå0·9®C>aÄ=µZğj–”Áì¸()¡¢}­÷‹÷b¤¶—‹¨`Ì£x)á‡V´Â7Ø‰Q\Ó;+läT¥Àşwøy0Qs@…‡®¥ ­6Â¾Şe\G%s™í_îìTŒÉÕ¬š˜oÑÄîÔ¡×f¾Ÿmk¦+Êë™fk™íªÄ«+jòuRš|H6§&.˜äK´Hb7yKT
%•ÉË¾h4'=} À‘ñ¸å4é`Xñ°øc0›ó¤³.
ëùK{OMİ}á‚I-*ÎØY‚:ŠÖ  ¤Ç–M§ßgîy­!<†ÎUÈ£ZîHpù¦]ºåGf¬H“ºL}l7wK¨ö‡?åĞhEğeå¿ òÖ}ÍºÈÛõËDŠPøş*¨{Gc±î¢•…ºcˆŠ:VáŠ4á»;ëêùN¿iwû,¸9ñYÀ>Û{§À(`Nb8úOûO©²¤×ÖB/Ñ¾E50ÓâênÊ–În§¬ª=
¯«Á5<¨›¡(yfV‰•û?•4ñ<Ş{şu	5ï§Œ“Ô1‹3¥ãƒ¶Såå¶p”tÛ-6ëšà¾kÁ“˜UØ$ciÒ©¨CrÑô}+i~1úKâ
¶F¥ˆ"3“‹éÛ†¸+hH~·x5	÷±ÿ¢ñyXSòZ>n˜ˆO˜äèª®FñĞ™ÿù¬	ø÷#ƒ‹ÈœuVêqFà®Ö];Ì¸¶RN—z)î&Yß¼Cñd¶–ïdMÍ†îm1rO¼ÒÅ§•Yrƒérâ|
bipÍ¤”}úü‡»Äy$ÿv®’¡|`‹P€böÓr£nåÔ”ÿªa³ı¦‡°hÎw×€?ÎRyA8Å¶*:ûtôô(qüÁxNyO;nã4ášûÔ¬ÑÄ*ô½‰åÔÑHú7ÌóïhIÍÎgŠîÀhª×ægÆ` É±~v(.â§ÛdZfµäû Û¿yêlú·É<mÉnšÍúŒÊ#ü~ìm:éÊ¼ı1hİ—ìºø‘g†®ù´8oÒ8ó6Š(Œ²2/ÅúÎQ­ëuû9\4ıâ;ƒON`œ¶tì¤Ùß¼¦@a˜Èx©„öwæô¯aÛµèÉÂ°¦‰ä¹*@Ø®3o{`ƒüT·Ò×D?WÖ<ÊâÇvµÆ#RÒ·p‘)ÉZ’%ˆ„¤†Ï†x&km1šÃ•¤‡ñKØÚC2> ®”M'³$F,e¦Š_Û~Z 	2à	A×pG\ıçDH{¤@_¹ÈÑ)çÒx×`j_„®¤tÿj`d8(·ËØ¯ÜYÀ8z™C¹€1R^4æD‹ÁŒ]è*Ÿµ¸¡eL6ÌÛÖÒNQî¸<%­ùö¯X[Æ`ašdp\% xIÚ¯!ÄRíàò¸ÄRmJ5{êD¦o_à¢<ºâÑ¨êÅe9ê.IWb±÷„pK³`Ë¢iÉC(né^Îo:3ÊşÓi6)ÕûZ;dVjX¡æd98Ş,$ÔÊ)„Öğ=ü£÷ß›qù„f#ºÖŒ¦$2¨3ñÙ:ë8áÛÙ¥˜¹mÉê‹m-šÄ#fï¨»tı¿çú=°0¸h9ıJ/í#PÂ`ÿãì¶cLAÎzõÌö^‡“ó&#:­.S¶ßàèZ¤Xx¹ ªè‚¡s¨b‘ÌrûÒmÓm“‹ºv@Î¥%.™X+![j€dU[QJ–téëcC£°i†Ê—ë€^‘îİK?§·ëN½EA;ªfäß.­+	#$ìçRLàw&›DıLÏ³ØÁ¼Å„¤q2¥SÉp“'ßå™‘ÆOpêÕ‹£•.BÄw
Ô—Ê_ IyGA?L\®aMÉ›½ïÈ‡Æu+¸SK–h~Ó
ù¤¦¨@–èpØÚÓÕ`_0™šÃ_”ó
?©Y]êûçD,î&Ó/hpfËPxs£o*aâ'¶cŸ+"Á‰Â)2fØÛ~¸¤®íAq£g¡ãş·Á¤ÑN› ƒSRYHÇ÷ëµwâ.rş,9ĞØ|Mr`ä!àZ›æú»§*£ô,¿à/ù•¶K¿FLÇÂøï„ŸN4éÙˆÔµ¤«ñÀÌñKg$º¼ÿÑ¬ U0=­2¡;¢ö,î»ŠqÅÏ”Ü³MÒ›’ad3ÜÆ8ºÙ3˜¤BÄÒ¢î‘SF­FĞQñkªùu‰TÖ,SÕ/ÆöÔqÇ0DúÅõà´ÓÙïZ0Ş«ÌåG›4K³ítª ^÷'Ã@”‘!i“yUPË9	¼]!0„‹'¸®‹š§—¬ÕİüR`Ö/E##Ï‰“_ “Ì²‰Æüu=Ã,x’û¦°ş:ÜÖŞ»(Õ‹µë¬bÿúæã2é3eJªôÏ”)¨¯4ÂÔ\¢ÖZ&ş?’vµ®¿tÕBéí2C»ä=_·:…T[ÿ¾™Ş	»ò	é îhÜOGlYîÀáB  ùÔ»Ãû®CÌ ì²€ÀXjÃÄ±Ägû    YZ