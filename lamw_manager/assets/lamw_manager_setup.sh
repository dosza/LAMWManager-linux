#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1427386955"
MD5="6d76c2a1d051172727659953aa1b7151"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26012"
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
	echo Date of packaging: Wed Jan 26 20:37:29 -03 2022
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
ı7zXZ  æÖ´F !   ÏXÌâÿe[] ¼}•À1Dd]‡Á›PætİFĞú§—TöVKïBX“8(Lo’æ±€b e~òø;Áû=y`>£mõOá6XjnT‚.´j_Ké&Ç7­’£¼ï¿»"ÏIB|háİ„y8‘xO#@íL½Z5îâ´şvcˆ¹ÊÊ˜q¡ñ”ü<g¦úoÏ	¿–:ÑÚÊ*7ì¡±¨VÃİ Õ7"14göXß«İ&N}> ¥Ùl³‰R½ÒÈq!sğMïr2KAçEûŠŞ\Gîöû–Rß&îmÑŞé2%{o'ü’yì&m‚õí:Í”ú^©ùÀì¾ÔtFˆ¤ÊÙ‹UGïoJ¬ÆÏÙ" ê¯ıÀw®$%©‡F¸ˆ™H&zÿ¤	óğV‚iâç¢cƒ§mŸ¸âpAiú*İ€#%ÃtÄÖ8n/â	±åáÏêĞ§W[z¾“Ü.tÛ-­¢;U±Å¹kÎ¿<ŒÌ*Ù¸p1M´Wš¼_Aš)oÌ4dYV(3øô2&šş5ÉQ;­àxŞá4úğÚ,ío!àt|5Â‚	ì,Î¦Z¡bb€Ø]+JóWEÙÈÅòyì=Z]÷Æ–îQgY`×÷/0èº%\ö60Ã­¶dk6.W¦AÍëTßhMÚ{^ä®³÷jdú8S}åv(“ÊÂj–ÆÌ=FhIõäÎÀîöt3x‹$Mv¿Kt¨}ÿ9óXïDAAó‚Á#-5.0uA²Ó·©ÊÆ#Ä µÇ×¢!áû) ïvÓ[£Ê¿d+òó’_¸3\@]*Ÿx`¤äYõ@%íeé¹“Hú/^…´>—áª”¢YëêÀC«c¿L©3B°éÈ¿fsŸ»Ë|“)$_5v1|§#¥”Rré†ÖÑŒk†¼ò —Ş”"$€à¿ÜTŸØ
"±~×
AcJËø:ù¨¨°‘«½­ õÑI#ØÛœÃ¿ŞÉ&µI™õt 0JîÿY¶6¡^×‚lñ[nXMZ“ÎŞ'Wš¡Ì¢6’A‰Ûï)Rn‘vÄÅ¦k¨ŞåÎÑé}
9ÑbgfN:²7`æÀJÚºßtøAôÿ[Åå¸Étkl)P½Ûg¤5ıNÇ§cÅü©ûsç}ı§%æ­m“WG+òq(Nz+se¡v‹‰Ñ;ÂÉîµ$³4¦ŠMñdòâ‡RW•båH}F&óôÑ@Æ²&Š‹ğõãcÀ†6c÷›µ„fÇ¬š;-şˆDKıQÒ×AbÄlw¬÷¬‡cı1D?õXX5-3²„´­ËXVõA qº›U»Ÿ¹õ©•òhej_ÃÿFO`„ª˜“`“\§Ú¯ÿNYA.çzdw¾A¹„»ìrQŸÜñOi5àÏ. åu6®«»˜h@zQÒPİ”ò,¸&šr+Ü€rd÷'Ÿ6rÇ&Àš Ÿ‘Z.òNŠ	‚÷ùíJlÖ¾!X‚89N<B¥'³8¦Qv%Ô”J¬<âšmÙÈÎ2{K^6wş{Î â~›šäÊùÄ°b¨lAbôoAŞÿ¢›D£U~„V»ÊQÃ`Ş¿±İ„#oä
<d_·ç¥½"íH³	^¥"Ü£úÏ7 r| ÍãôÆ¾õÂ	7´1›ò$)æF­ÕÒ%XUeëõü?@TatÑ¦˜¢£èTãiiÍ/{“
©©ë£ø&Šû³B_Ó oÓŠl+‹t1P4™úizu*‘üêScÙhL‡D:²Šâ½=oü f¬öËÖBÆ…1áßÜ[Åä™:›á²ÓëCŞèõ ®ÊÄ*y;4åO"bfÿ†lØ/-¹äÔtm«y"˜EñHÚ™Ü)¼ğXò†×/V{ûƒtšt×Îø_î:—°ïZ4–ãÃ—íAj(oİMO¨¡fÿ¡ÌÏˆãÙÿ•dh©?:µã'zŞUæ\_ùŞıÉ¼{Ó3æ/`¼œ8,
‹± cI{Hdş4¦wöS£H5xI5j’f¶y`E™à8~lø«>ÏDö6ëø”?‰ÜF¡ylÒÎ	ã	ö]Vb£±8U,ı9ÅWã«Ú‰+Ûü½HuêóQ³ÙúßO¶œ–qâÏÚ­ûEª=1y'º¤1Áñ'¨mŒÛ[yŠŞ4İÔ\˜0t‘NM.Q÷íI©­@Ãb»JªÕÅæ™yQÊ‚‘™q7ckY':½(qŸÆu"æîÎ'¬ğ ê)¡k5ş©Ğ~KU%§«6Ô«&fEV¨“~àšÉ±=ãÀ¹ofœgd·ğ¢½##¦ø§0Àà8ß…K¢¯W>ÖîËT“T#‚\€1%Ã‚èÙiO=È·²ŒâD|©ÁèÆğõ
Æºÿb=ÇçÌµËê/Šuäu—«ÏNş[ÒwHÅİn³JŞ¬½Ğ‡S¡Q(xÅ{²¯dÇÔ¢ÖÜ™S°ß Â½!¢­Æ:°ø1(/Æ¤d¿eBuÔGlå‰¥~µâ ½jÅB;HK	‚~†”®j¥Å)ãÌè£¾O,ádÒO¯ûX&CEòÔmçØ8Ò·ß¬ŸÕÚKµ`diÒÊ³MÛ­í
Qm¢‘¢`Ó7… †ÙKÍÆÃÂëÇ;´ãô¨XÃ¶î`mÑßÄüü|Év ÄDˆ%ÂEJíÜ;"7¨Âm%J&ñÀ²ó[Š¨»W‚¶¹*dJğÔgÚ)âq:4S\OÉ"9´Ò!ORû5£_OJÃV!-Íiñüóš9›ğÁø^\Œ»ténşènı=ë­=+Øô~›f0 ¡ìô7xÅ¡‰á°FØE¦áB%OŞNüò‹Êa©îA@=Ë¼Õ÷_š…Q¡÷zsÔÚñÀ°} ^uPt¦UßqÓåÏªº
îUÔœ6ôÈğŸR®'[ÙÃusÚ­¿šÛU¶wÙ¥…&ZƒôíÖ›”|"D<1ÎˆF YıĞš¢[q°gÏkÍ)®pÎíN¨DN2}t­ÜOËf\¬`3òşœsm=?	İáuºØ¨¢ÁbÏaNÚ1­QnÉ™ï³z(ßOI§”à‚¨•oNÔ?‡L”çA¯ZŸ<(ÏÚîÿŞÇÏÔøF•šB1¥õºÇ½ç;'<Äb]¢ÒèÒ©–f­ãäu\—â£vµiûyPCNÊ¹ş­`#¼~!É3¨˜åo ÏİĞÍr”º,5i}z_¹Zf€:*2'úßWA»¦p] #cV*}N?NÎÛ³öWñÍ‰Âğ—œ”$%(‡°@mçIs­ğ'·úášsÑÑøQlş˜®ï²7»vÄ\ïç`Ro°uõé\Ø¤ş±¾
İXÑªB ~cÅq9à¡Øİ(LxîÇ"Fa9İŠ9åñJÁÌö»ô<ŞSWåÙøÂ|ò5s»Îg"U¼á%£^`ÔYzİ'ÄYÔ/áÎ¸R\ô‹ØÑÙpñ‹€Â¨/ó°3Ü‹‘åöqv~¬=ã#•×N†ºó‘Ôõq(×YÑ\ÂìÓ©/tSô‡ã.às0;i×¸²^„ËŠ´j‹‰E+ê>àğ[ä	Ø7J¢0ôZg
]ò¢O	<‡ÀøSïÊ®o:Tæ*8yúùÉ‚T3ØŠrX¯YCı
†x­T@êœ-u¨aÀYGHOï‹Ì—ñÿ|ù¿¾ojÑ4©ív„K©¢'ßy€SRtúğ%è-•YH\%9ŸSÁÊi ¢yø]äîÅA‹ÍJ?¯òÛÑ}¨yè~=ÆÂÅ•5îb•ù†hè§±O¢ËÆ§óyõ4Ãë?¯?i} ’x}Çú“€ª°çÓ]êşº9u`O­™‡ÔæÅÍJ¢Ê…ÏLôY×û˜º¼”	™ÿÆŞoşÜ¥X<8ÕM¥¦€œLÖÏñÀÇ¶ŞäÅ=&[ÉRä/ñ0ÏõŞäÓM„W:Ÿh•#)¬hØƒ˜6ÑBV3¡r3ÎŸLæàîÜG­¶38@ş¨;¯Ë³×Ro2¿°ÆÈBleš‹Í`E©À¬¥bçÑçn©Åñ©ªÃëAÜX÷,¶¶5*9meuE/^Ûc’åc¨Nå!º¹aåD	¢Ş!ˆDêöĞBRöç«ïFo$VjÅwâ“XSşöĞ!F,õÓe •î¬­¢Æ;‹,]ÕCjÀhˆd®€¯7¿Pî¡EL#?q`Ëhôx¡yX#³‹lw•ëÁŒµ`1Uöµnü …ªvñ+s³S*’ÇÄk–çËïÀ²¤¶ß(ÌhÓú½ê?tÜ)¶x‹Õz_0"¸¿ş¿®ªÿD1†eë‹OÅ
²ĞÔ†¶á£Aâ9/Ú†
îİIÃÔúŠñwürŒdíIø¡«ˆÀH¾¥¿ö+)UGG.×âª©©F¶Cîğ
­‹Z¦”dï¬†³dõ+\?†9ùY¾¢ëé¶Öt,Ôù:ák(yqcI]É’»	¡
êeøœ”6‘
ş‘!ê4v‡…òïì>½mî"ò„…Üô¼u$‹hºÕøØfµp+n¸fNUR/èØh¤vwì=á“LıBUøò‚ŸîkšØ‡õÏ&£ÀC’w¸§ÈuiE¸ì~aój‚zèY¸çC~(LÅOôØ›DÖ“\Ç²ùÎ_‡£*ş²@ÅŞ·m[4y¤+Å«¹§5×+a‡Ó;ëBŸ|.49I/zp]¢:ÿPÓ(L’¹._Y¥™ß]fÑÃ+ èR$a¬[8¯cZ£d'OŸíu =o¡@ÄÆšg#‹w =éVì“8{ I)ìÚ•ŠJF-Rw+¶ûÅşÕ.=7-Âóİa7¬†¥·¸åë]ïHuf¡.Ş©3MÍ ç™\»}ÙNjd½‡ØKLY%øÛœÁÿ^4å¿BºæŞ¤!uÁH(ß1…—ˆ¢x=¼¾Oºñ¬uˆ#w™â\pìÚSS5<,ç/H1Óá]^4ÖCh:îáTpçŒ_ıÑ'ˆT›‡ƒX=Émn‘¤áá*»\Ú?E%+Êü†Vè¡¹ŸĞ6{„ËHFvëU¼g¸şÕ¶¸ˆ+Xk˜dİgZ«t`ÊÁ³k‘ŠDl¨®‹¯ÀÍ‹ñ’lpáÿ"Ÿ]åW³’Œè97İ©»|Ín™™Œî$«zùãOmVzôËÙÄ§4° Hk«”@rÜNr8—ü9]‰Ç‡b©BFïÖ/m¢€–³öDÛÃºhë&CiùcÅ+L–úAÉ44i&W÷K§¬œ©
fÉ¶¨;-ÖèmŒ§L•{ô³ÊQ6äBºnèê6 ÕèzqèÂ}÷äƒ‰#V©ZüN.¿¾Í]T« :ãô8ˆñ´<«îí§H~ ×,ö^O¿*ÍéÉüåjÅ3~©.áÆ$C9-7ÅÇdKt`Æöşg`'¼<ŒªZ=mİòí5/2¯åè?€G X¿L±ù'),£ÏN1X.““á°³²-µ©ì*³ÒGoTûÔÌ0âöIÁÉ7µs]&=i©·o óœ
Wíğéiç!
Pg½Í[~)©O”|g[İ†-ÙPºÔ¸etßgbœõ“’-7¤Á\éd·ï†¾EUà¸[tšõö¼@
Ë#Š
ß´Lpk PÚî‹œ©ñí€À±ç€¹U‚Yif#9"¬JâD¤_‘Ş$-gèÁ3MÖúÈî3Zü<>±’ûAí•°PÅõß˜ë¸$%WÉhsZW öÈşv*Z_~zŸØÅàÏ
ÒŒòõ/İ4À›±âÔ•?í½³gÚˆum ƒøıf°j9Úü7UzXNÙP|]Ò«½5‹da €–tº§	³¯ö^|ÁÁxo 		’eÄ¼@o)³øîKè¡LPÏV RTÙŠ»¿r<.|w‹÷ÚaüÜ
¨íŠL“·óD /‘b´ æì£kt£S¦“ùRT7JÕ|*ÒåÚ>Œ	J0úà$àH,`î8ouïÆ”w6aÛÔ®åõJ]ı+É.À_¬Ã™e—L¡{ñTyK9¶ï?"E'İÔàúf #'Z¾^@JZ ŠÚç÷tDâ3®õ²»­§äµ÷Ux%gmAwµ•nÑËè{‘…ŸÙ`ıUj¬vÔ5Kšš@E^k*JtêİâU#öÎxí˜Ã‹¤Äøˆz“%íqÄƒè6xf:÷¾ú5,xümzlq¿1#?WLãwbãô'r`Ş±²šáBìlê@ØªÏlæê­Üd ÖS>Ú_ÔC|”Ã¢Ù6”]–ı+.ğwü÷vD‚4Ê¨:D(€ÇWm'ªÓ_ìÆ9ZÆEŞzÉ§ÉÄ¤%=#€ˆ2ÙO‚Xâ6‘–MLâ–ÓA÷i¦Y“×/K‹^<³ÜÓş8hWBY¢÷Õ—÷ùr³!@e²Íñ!jn4šBà
Hò$tREAKŞ[|“ëlfH›ÎWåŞE¥­Ï%8•İµz›Wˆ¾E‚àğa¥İà8¸¬…L6‹ös³¨=ŸÔş SnTÑÑïºM2ÚŸÿ+kÊ¤Üûš·œäø	‹<}Æ	c;İ*g¥è6f;Í?½e‹Tıôí+½‰*ŞG…øû1I©(£“Ù Ø)‰dİÁ§hfÊ•ó±|½‚›Q­ƒĞ`0QİÇĞWí2†@µY|6¾`oÈçÂc%®gÓàoõW	"ÜéğyuVø9cÛ· ëôáe„ÂÛg3L–×sOÂ;Tn;”‹½ƒ
ŒSˆãuâ˜mÆ]D—×ä—°á­	÷–&é.ïá'jXÿ°TFWêá@:}ƒu>¹â=¼ºÙ§):Ä/7´³Ô½ VÔ¢b‡Ë=Ê¸>Äş² ñ6P?^SŒ€ÓDuóùp©éåçiÔƒ®^ Û2~l+*P[ÖÈS4Ê_±ßR“çVã»œ&•„òy’©\™w§ó<_Tû™ ÿ poÏ^2†²ƒ‚|ù|ÜsÖ2)ô¸H³Môë"PÈOÎïk=‘Ü»İŞ³ß_?—¥ÈÉ‘ÏØE±ËŠÿ`2ÖgØ‡`#E~—6FÉG
§PÁ³AUybƒm“ŞSÂ3Ğ‰–fK›ĞÊ«~ _»ŞÚ­ÎÛd¹£Ÿ\šJğ8«K,0%7­µ7l#Hyk‘w¦Štê2'F…¢¸6onÉ‹bÛE?û Tä¿Ø²áàr‚¹xlşmÕ5éÆ‹wu@ë¬,“|	rün1ª¢Bäü±O–°Ÿ¿<Ÿp¨ ú‘‘{w1ÔËäº×™‘Ğ>Ò°#Qù-"Gõ3†¿.Ìƒ•;jX…¥÷Ãrÿ›Æ¤ôló´N;˜¿J%ÊÑD‘°ŠÛ_:U
º½¹
Ü_3Ã`¶ömÄ§–d)w«`¡°aÚ</q}úÑ°oaPo¾èH÷x!&Ô`4$¬HıÍ1œ8cİC5øu%©
†|¹‚÷D+®ÁA$ñS`®¹]<Ä¢ª>G°ü ªu) $OêÇGë> ®Ûº‹,şº RÇÒwH™Å6k³zi’ .ÇT¡>X–ÿib›‡åQìí&d/WN5HŞœ6gl */NeôR¶k]‚Iœ4ªÇ2À°øÔÇ¨xH±õí`±`‘·ù–ŠSï´R3š’Ã‡3yÙg˜~&gÌäréqXLkF=ƒ$:{y9ó	¥˜A5¼ Iò¢‡%Ÿ­Ğ¸ã“Í&[vÏ¨2«şëÅ0°w…uÁ½4‚ÙV5êyÜ|A”¤Q×£b%w¢v•æÇ´p}0£gï„wì«Â„—‰¾†µm®¯tœˆ>—Y'ß¤uöIBj¯W†çkÎÏK/'P™¿2Çz‡DÎœ`¹>83|á'!vGÃÀ#á¬~E¾˜È±%RŸôó“³P¶iÏ” "èkø\YkWÅÜ^µ`¼ã½_¨¶µúÀí§R™¡İçÛ×a ‘9Ôú±-*Sì‡8×ï¢›©ÿid½şÂùt‡9£7Dafùæ‘2^*0¶‹"^À¢K`:öç  “Œ~#ä—bíhoâTásŠöô qè{£o+ü"šm–ÇƒqJìyOá‘~ÓTÇE= ¹¸$ik¼·×f‹ì\³v!îŸãv©©
'½]q‡ápÖ¥£}§«êÅdÛÃ¿°µ'®c·öA„gíİ½wÔG4,¶ü;{ùGÛgÜDæ¹K÷ft6£Ê 8c°=ûHU’ã›/ß—)ù¾üC¢ Æ$JÄÆ6‡¼ÛçI“¶BE§êƒkk–iÇ¥î u:}z·ZÎúÂêÛ<Æ-=%é)„”ŠşáŸ–Ö~Ï"a•`İÇ½‡£Ì ¸É²U–$(•…Õ‡¹âü¨µùàF.¡^#€4].Kd;È•/÷³ ½@J¼æÄBê»Á7qú´=“Jqk…éê¥ç¨Ñ»k<m0±U†R9àİ^—(õ×X€e¤#_²ø”óüP_<8‘©|Apd;'8‚Ñ.?êâ0&IüÎ;>¹äè:@ê¡0Q~Å8õ¸Ã°|í­²¢ât(MMËGnîçáæŸÇ¥Q¸¯İúËNòÂıŒ°ÔŸh5+R?ı^
êi
F9q„VŒùš±ˆÙ!¶îı‡cÄş‘+'3W_Ù„÷-Y*!¼¸Íxµ5ñA]g»Lìñ§PÓ¯;’bUqD®ıì“ÛÈVâ1Çˆ+,ÃŠwÙz„§'õ½ï}Oê.Š¶ØñÏù+¬:N¹+õù½®¿´$òğ,ÒüœöO’[À_.İoÌûë»ôëšü–½–f|k˜ƒ@%KÚdˆí—,ù¿Z@ÄìPÌ qÁƒ{ X5fì—Á0·*òòİXÖr|«"áÒ»ñI–»àîÏŞí8¹™	ª{‚™´Ä¦‰LS†5¢@ÎØZ¤ÌWØ¶6vŸ&'Öl¨ÑaÆ4üƒÁ$˜½<İª•â;{¿¢¯‡@y™“ƒy¿b3QyxwïO÷Ó[²3»w'BÊS‘/=_å˜´jİí*j…DÕPkß;÷pÒè>UZk°‹lq×º¢½=™X:¿LœŸ“Ïõwç‘Å=°e}Í¸ìyÍ_Dçí.}ºpiìE8¼êrä‡°†6Æ	*…ıIÁÛ(Òd¥,[:¨ t ’úGh§HSªz6óLu ÈÎ2Ô¾${.9F4uŠˆöÉ#¥1—bör³‡e3› k!ïï´Ñ3O¦ÈµwĞm&ıÿF®M0ö{:IçøÌt Bi¿]ª °Ë@¥•í·’íŒÃ?|½ÏobAËN’`Y¹d°DvŞÃ"ã¥+Ø§5
¢!ói«”ÛiŠ†ùŒ»·ƒF®´‡ƒĞáiü"_?üŒ«ÁÇ¬ô’îÀÁ3j3 åœÜÇ;Êénqb/'3Ş¦$âë’e*äã¯x N…T*â€×øÌHÿŸ?ê¿Ë´ºš™œmex *À½É@Ï´0ª¢+ì^ø!áÉÈKš9Õd F©vcêoó^E8ßXxÎeFc‚‹îá_‘ÿÃÜ}aQŸÇ®´:Po|L8ÆÓ;q’¦ï·¾X=ŒKCÉÂğ3mòŞ2
³İ$ÜAğİ	ì¦Uúö"Œ8tfÖåà4â¶‰ôV[c‡ãü·üEB©¾iÙ¿OiqĞN¨ô¬´©È:üç€+§~ı„ä]Š¬%È/Áàú¬¹â[ˆ)ÁnÒÈ£fƒrG=-~ÿ¡µ7?ÜÈÙQ·dJ²¯ğÜ@ã9™>ÁwÆYyy)D¹pr-®Õl˜äôw]Ş——~>}ŸL.R­-?iÎà'ÀHÜºóÎ×z+l•©™*L1â„ÉoxYÛáMüíXQ_µÈ[ŸÂ6®ß‡Ág|vœèÄ£OSêİ=ûvLU@šå¬UÁˆĞâ×ßi[~e0dèHä©ÇzX\JÄ¬w.³«-Èş¯Û®xk¯*d€3¾3õŠğ‡¯í å,W¤¢{1hÀüº³
=û€qœÀóüúf”ùÅvğì»€yÁmá÷´ãùÌ6ÜïC­ª+—;ú'Ùè#sg@ª¦4J¡N·¾HòÀ@2Ë¥Y¦”i0úùÙef¦8µ•"c²¾1¶„èŒ«~^ìL‘yú­H¡Yh ş¤Î¢crÎ‰˜:'ŸÁ]lîûÈ‡±Ú0Qj°_ALQsÒ»ò{Ú3?Í.\š™ğmæ´_¸aè8 ho²ó QâÉÕ¥r›S[¾¾ïìA˜œAŸ ÿ¯êUKØ1Å3õaàŠÔşßTîa·´÷Åé ‘—E“ŠŒ-’F0ÙØÏm°]4á&ı˜h|¦>²lwFulJ±^4>¯r4áO&(Ãã§Ç÷‡ÅbÇı(A¹lCû°å)8r1‡§pçÆ%Ğ7]çñ¼½w„,[:#P—Ói(F[3áBJ%Õiª0¦n0‹Ÿ®õG€5K\VÀ”Ÿk,œø
†¦¢0„ÚÓm£‰ú6lì—¢K†Åpi}e(ã“\ü{a7ıó0Îë¯s—·LJ6ºáä,0/L’ê¬üKï½®ÙATĞ ÷]†ÒŞ9¬ºã¡¤H§H½fçœ'”µß™iIï¢fê°döÍ((¡P:wEYgÂ+4™—wY.[eï4_Tğ¤†!Kù¾yÌŞö1"È9ÉD2û¥¸'_^.*ö9Kúë9
Åç©™Ş”©9¥÷ÏFßë[Ç4ˆ°¼Ád¼“ËtB‡Æ”ÅÂÙe/áê`»G5êû§ë|ö’âG]»yÌ÷¤·´8c-/1JÅ‹&.‰y+C½Xï¿ézºRM4Cµ3zŸg`g+	é«
ı`¸ (´ÁX?2­Í OÃ“Û‹Ùç‹‚(êUØ­7––ä§“P+š)F@1Á*iá¹sGÌÃõ¨ğôËã¼Íä«CüU$|Ôê#K°Ú/'œ<a‘r˜„ñsÆ”ü¼ÈÌn-Äî øYÛàõgê8IoÑÍ÷è‹a˜hnìŠät|QÆÃ¯-.¾µê0ß0;%)ŸF †]>ü´ã@¾ßÜ¯‘9AÙ‡ä/)WFÎY(¾z Ø$’‡ˆîô\N¼d®v•cÀyÜ‰•R_>‹’2OXbğ*áxß¼ùÎ÷->óŒaiÅw^‰²ÕàŠr?€S¹Ö#daSøcNË.ÁÈùM¬kbâéË¥X¹Ó/{1Š(K;«D'\yå2…]ƒbYÓUZ@S±„“óP¾"¨#E+£î¿¦Ææ±ÄTéxDšÂî“Ğ…3C¨»ä8T!…èé\PÆÕú¼ÍuMÙT¹
º×ª+)¡ìÇ	yªòyì1°¤ò>/ÏªŸŸH²IŒO2jRg"¡×ï$)yE)[¹¸Ê³¢¹­/o(;5È€õ*SÉ¨R?öºñûˆ.‡Vm9‰ÅRK8òPÑÌÜæBşÊÔ1
ê75Ô7“­CZØ;Œ1rá5Äµ=ˆ¬Jè:.çœÜÚ9Ãá“§î.Õ:ÍÈ½Pà{µÌdW=P³v’ÂNXÓ2Íw…dß{šÉ˜ñ¾ïY«×1º¿sn	’JzŞh@µOø9I+èˆ¢ók“ÂÒBV>>^¦Lkõû…ˆÒuË§çªï—.œ…kŠûñ“â#îØ®C®èıvŒM6Pü­ô}.ŒŒjltiMa·º“»šı„‡([ğùâ(ÂAaWÛ],…Å¶ÇáèKéK²‚Ş	B6êì^}JnY…­BÙ(I`ncÆ³°‘
ã+‡iÎ`®±çµğø>“¯´ŠáÛıƒaƒùuÄÕq}J€N¹z7’ˆÂû4&Lı"P¿„Á§°F°
´Ïv »v›Í >¡ªKd<bH¿—_<Ğé¥6×ÏE›Ò1Y¡Qa±ó-»S¥×Í[ñ¿u4}Qõ
5Ç«Á#ŞµöW²¢ï¡
­ïíìá¿ïˆ¹Qe¬™ú’e8aê,bæ¶åÉq.RL¨íKÀ(Ày²~æ_	ïªà®’ÿÖå.K‰>¬”J€Õœ4HtÖÆŸşıÁ£;—ñbK§¬§.‹u"è b!¼2É¡—Sú¸È~ê3†…°æèÌt^@òÒV­°®0’¤5w÷j)i´ä–:g¨õU[µĞSÙU¿ı¼p«:{6#Ÿ±(Ôæ¹G¿*é%ßl'Ó·½ç²Š.İ×ù]â°U ·z ‡')˜˜:Òé“¡¬LË¬]£…;ë	 vRËÛ•á€¹ysû¼ŒGÒf`aº¹ùÀ'îà[Öñ¬Z¥"JˆùOSkcd”_¢CY½‚mÖy’G(_·˜<â#UdRœ¸èëF[ß#·ˆ”uåÁ0¯lÖüh‡.ƒïµ¶ˆük³=ÖÅ,¯ˆÌŒ•¤F÷‘©ÚBÛD°Œj˜»·ig•f%İO¬u&ò·,‰mãcó:„Ì¢gÿ®urÎôã	èŞŸT@o³í~ôÇÛ:£Rùõİ6h¦ÔÕ—Ä¥È¢š»ß‘ûì\ß6^+¬KC#ÅÄK–Jur“×‡Ãç13'ò±Ç<ä?¡vó4-ö+º¨[û?œFç“aƒ†2âë,ˆŞ<C$6ˆ4ÕL~”!Ã¢–ì¸“M9qı¨ü€²"íß}™ø²ww=¹4¸SÄfe;Şâ<@ßLˆkXç¼WXe½_5Bè—G3LÜÍ°}-E%b,A¸·^ğzü¨Ëk!ª´‡·‰¸¶‘şşvŒT*Q]†W¬,Ù1a‘gÎ€¨^îûÓNHNªBwı‡CK¤CÅ×ÄÓA@¾`m)‡D k.:uê,µaP­6q4y’ÇËIQ2UƒpË?ÛòŒ•jûä0n(oïzœŠc¹ƒqÓ¡î§QLöİÕ°uÇ3«~´„¯	·«#Ãø/¢õÓ¡*^ÉjÄñ¥Á}Œnm Út°-.ñÏi¯<lİ¬ÇÀÚu§—`^Ç%/ÃâXœ|D‹²@F‡Œ¬ÓEBŸ±İ½]e³ÛÄÅ«[;”–%ìÚfâäTµÄ;\Pù„‹¦ÂMÇœiÛÎİMz¡¼&–E…–SıØéÓ68ÛáÂ…«‚9	”›iÌ™qìÅğRH´fa½1şãÒ¸„5Šfm•X³í¥Áá!Úóö©P]sñ–<åöfL¯ó¼ŠdJa_¾LµYTòš&“ŠHá%È¡d$“0áÎÎ´n‰;°ÉT ˜MÏO»R²
À¯lâè¦&lÊb1/ÌISïçöúc2tuÑz™h¶Œ†ğäuH!jÍWô›bßÂ°±*È-Ìëúİ“?†˜h;ÅZŒ„k!Î©&v\@¼ÿ3’ïìc„~O1
%³½î®„5ÖnèGÁİè ÍD;èİÃòÓõï¸â¸°Ghå°}úåÀ>ö·usßs¾^Ì<¯%Œ*R(ußAä»Š_Ã\ñ7¼j¹±TĞûP™kçâí€Øùì#ÃAU3X¯ˆNËŠa$I°¹¡w”
Í5*Ñuòs LÕßf¾ÌÕÛ¢Í±•¬7SNr7>6–fCI¡Ô Ò'{.hVIæ%Í6Ö1ûœÚvâr"^gºüèœäR]0Šü6?°q6Zgº1¿Ñ©ü·B´ÙzèAƒøñ8½³›¾&IK:2<ß•\ÅÌ¾6$Á8ÿkf)zª—^ú,¶h -ÃéäªN:şøq$}ğ"òàúš/Ì!ù/©vç6ÿäP$p<Ã…Rø$-Ò4óQKÚË°"¤?´[¥ùgv½ú’`v‚¢À{gÿö{@Î£˜&Æ±Nê÷†”i5…ò2‘EX)îãE”éG8ôŸpÛk{^Àõoª˜ÅìH«Xçj¤ëøÖ§«d«zl9$},ôËÑfÆ÷z™ŒÙ•„C§1<ü­Áé×20R .±†l‘gÏ×÷ç O’¬‰©aŒ}nCê'fÏQaİú~K³`ÃÁsfc‡p’ºÔ1¼v1ŒŞÈH,3ş„ÚTèÌŸs9:Pı *ás'•g€—´(÷
€8``–OZ¸9Úár±¾}õŒ~sËíÊF|Bzp¹¶ÌÖ3HPzÖ0­Pç¥ rÍÆUè¤’ÜÎİ5õ-l}7H×«ÈRBè>GmÛ±š$@Ú½0Üİ™Q*‹lç~<¾ø+yŒğ/Œ6ÿ àìî±V½+Ó¡¤Ög ùò Ÿ‹×’nı]ÍjêM8máİû;Îzí-®Æ»÷¾Æ&È½†x½(İ®+FÜØ¬!}9?YO>®R^Iåû )ĞÛöî×[{Ìßm&iÊÅ¿à'Ze¦¬lš49aÁŠ>ÑÜ/Ä£N7E}°¾° ~ùç¶˜äeöÒªNQ^Áu·ƒ®LŞÖ~¡……0"“¬	 å™¥­‰Á.‹Æ÷—\+j\¶ÆÃ]Ú‰µ´k­!ÏtK–ˆénO#˜Wèñö}“OÅ€Q¸F*—4Ùèã’i6u…"eÈº¼Š#÷½¢­ùŸ	²ÑºŞè­¸*<å™b7dŸÜ&Ÿêñ›=)À¹Î/|Š¤%·ˆ¼¡ğMÁ´›ØqzDlÒ&Ñİ¡(càÖ—çH·en}Ÿ³å#lŠD‡4ÄÄsšª5y'âŞØşZ(­¸ş1Td×;†D¢Ë‹¿İ«˜CÑöüE^O”<WDÂÂrıXø«ºTı(`¾9Ÿr«6Ô—Dr¬|M´~´w(ï8XRz(K=Î“?…~Gt4ÊÆÓ¢°Uÿj*Ë]-Úu+ı†Ş±ÓH£xxúØ—Q$ãÌãÂ à^°¨‘áº
oı—&îA€©¨ócË0ª,MÕÚúõˆQ®ş|;j;Ë~IÛÒû`‡Ê¡j36ÖS,ÌN|dQşVËƒ‰ç?$äÄé½G×ùP€›p6ÏÖ$5ø¦rò4ke¥×=[SÁ^÷•·ğĞSÄOoÊ±æp“õÀO¼r¦”™ìª—Ê”NèÎ<dùœÆ
qˆa¬ad³¾Ü='¾Z’8û0’ñö>ÄĞùltF1&T_İH‚7!„VtŒØ‚Øg%^~wø×Ó—<e¬8ã÷ŠÒáŞ^Ì¯`Wò'ÍUÀ†´<<G¯È3VÖo Áÿ¬ú'ïôEµ˜€ <A™‹>_	P>€T¾]áÁüÉÂ…Õjn§áÖ<Ø‚‚‚ü´ur…øj÷OC¥/š×–«hÉÈ¥ ‰O{íIı?soPßÙI×+8Ì5ç‡6ÿ+­šiÄS§%Õy$ Bô·-„0VBâ§Mh(<î²}¢M“Qé´ÊÔ‰ÃøßV;2ÄI¬äè:;§,Í+‡Ê„
ÕeÅ®›ùxk?b¶ŸOkªÖwqe4Ôà1²*A‹;ó4 é;I¹Ù>ìzl
U™ünCp-«”Ó ÏHB9”™2c?aJÙ|½ô&Ïbğ ¤ofŠ#s Ñî-rçM;ãö’ó~®6üÉ3K§ï›š–ÕIº<
?³ƒ\CË>Ÿ¼à¸h.J¿âÚ\uîêj[ÿÜ#·N&gşƒâ×ÄTQ9{¹}Xí¼ØåO‚=â¡@œõ/ÍKñúA:U'Èm6–NÆaëoÅsõøq¸Kä¶^Ú-9úõà ®Cì­»:•*f×†{N¼drvùáx…KˆµCËzaxı°²1úñåƒz.¶ÅÛõöaËğ˜ó)­Ôm½º^%#¤dKÀ90•¶İe{8¯¢ óv¬
_©ıò°‹éÓèÓ|õ¬âh¹ÏÃ"Ì,/¬æø¤›få6Û¹˜ur5R
Ëc$&º Ğ›ÅşõuŞñ¬”(Wùo”=İh}¿8ÖûÁîÛ‡|ñ€ÈiÇ©aF¾«•µ}w®$™Èb<ôûIp”TK#¤HÏln`¾°›,Ú1tÅÈû}ÖÏå5¨Á˜¢jH=èÕp¹:„w‡C]Ï÷(­ğGÜ»ïŸÔ#Ç #yul¸¯Ú1ú-J°ÔéİŸN©u/}EÂ¤ä$U}¢ó{v7u!,±Â^g{IGä¹8
ç²š-Lø]ÒtğHÀÂ¨R%$Ü'šË¶}åÅSIt¯œŞ°êÎ÷\-ë~~û`äŸ)JJzµ°VMn:·ğrŒ~åEv(PK‡ÀİB'ö3ØˆÕÄíŸü5†]µ¡—ŞÀiªG²p!ã'Ü©e§!ó=(Q,±è|Ã®ŠõØNYáô"u™}o6ÌçÕ4ıE-[‰Ùó˜›!ºÑBŒ“äD3±\`¾xËÍ^qÇÚÓfP@QİâÉËu<„Ï ‹“ú;¤9¢wğ…i_›<b5DÆ¨1}Ñæ©)é(ŞàÃ
æ	(_+FÜ·yá¤%]g®|ÒşŞÀ.:é³õk‹[uÜòk¿gcÃeÈsdZÇøªgs›ª{×:P!¥5Ï,k ÌäVíR^Nç0,L˜”S1d›YjºK,©t9ØJådfB¹c¾~mâ-Ûƒ•õ‡]´¼ÆÆòÊBÈ]Œ„`/$8 Ç²h@Æ)æ¶pÜp¸†Öhï9©äK=Î™ƒr÷l])‘MV¯VÛ§e]úóEGAŠ%Àõlå¼÷ÒÈ,çñÁ´3Cf!¯÷(îãrTùE¿Ã Kûğ¥½˜)ª7ÛÎ‚”|¨“ĞÊ¸Ÿ75Ç™Öjòè=(-áŒvƒ]$pÔTO’yª¦X,s¦‘²ÔÍLj#V½Î"Şüé=Üe•r&â× ‡µKÊnIŸöi£¯Å¾BÃµGƒ¢ Š€yıúëËuÜ”ãE=ÍAü[|#¡]Wt	[wêôÇ[£Ÿ%xĞ#ÿÀú^O^“şBÀ
Ì3ÀÖ;»=;-e¯
1(Jiùäõ:ÑÛ,Şp$Ğ6óKùÖ—*hF£E`¤ØÊYĞSpTUæiÑŸ•¦ş7ÒÒ½†™.w4ğu®éE5ñ©'ùgí'ZÓ‡D]ìÎÑÎì]„z¿+WcÑ5kûİÙ9ïäÂÈ»3»¤Hx(b¯ì­¥ó¬‘é»^½Exëš¿+i—4µ4÷æömû5wR›‡4)sÄØŠ•Œ`±PHÍO½üfö¯DeXE³ÆÊG.¤Œ†Õ”’P+Ë4©¡Ø·ÄıñÙÎ°xàbº‡¾RÒ=¾íÎòW†ôïR©O‡5ç{Nê7®KËÖ_ÍòÈ—%T
nOY¥qG×îó˜ä©ïºLx!E÷Ú³{,u¤KY…Cş½ç|$ÕG«?¶Ÿù¤û'y‹&š/‹ù«ˆ—!,RzoÏùLİŸjùõCXLrùË¨ë¯÷Y¯›ö3¥Å)™Ø{ëÍœŸí€}41ŠlrU ´Tèà_ïÃUÓÂ"Š-€u2ÉÎkSŠ|ºHP†t…_/mKãQÚG–1öYç\ÑÇ­ÁÍ|ìLN‡,Lú¼6ŸãCt”x1«üõ˜ƒQg¨ÔnX²ŒÆ¼?s`c»¢›ì©œ3‰];¨nSG$m:Ïæÿ8Ê±ÓYÖÔ{M]ã~ÈFûşìÜ·Óû7DœÍ¢.ıëÓ}Ü¦ìŒ®Š¢íüôŸ{,h²CN^¥[¹±æãe¢Æ¤ş4$ÿ«Yí‹µ‰*9‹ÒÈÎYk$ÜÓ04%Uo@Î!ëx„dî”¹"~ g©@’vºx˜íšP•ªˆÄ¤Ê6y,¹r–²ÁüôLÇ¿n`sak@¡—ÿ—:ûAs›Ü}g`)Ö×jD†…(¯€HºãJöUfÜÅ¿-è³
û³Å8Zê’Ö 5‰Qn·{‡Kf%]^«0F¯´˜˜úàşJ²uG9¯N ìÂÚ(gÁŒtş°Ï"­N*Í›[ëİšÎB
«ø§Í¤^U“¢“Ô˜§C¨cşa[x‰XnüÆ)„Œ*;Q`+^Hiy=æ„‡ïb%+ º!7Ê‘”%~íX:~ C‡†?nô İâÇÊ½ ¬MŠ#E6_rkrÎõŒ‘Ç¹m³8—´Wˆ¿ï¬ßEÉ»[i!±ÜP¸ßö1½át "ŒÉã6öÓBµì¡ïVãkøıcZ¯šœ 9ñ÷„~æåÚË¿H—ºÊ8jı¨òŸC³ƒ‰ß.S÷¹-ŠoêóÇèSXUHEG,k—Õ¥¶V½‚Æyû÷=nøö$¿âg½¦h_•QÖ¤nœãø¦mÙhº.ÇğPı>ˆó–B®Ç<#Jy:²È~Îö?®…‘JAÆÄ _–,KD  ú[–ËIëCá›ˆë?6ÆnæÎ™'rGè)HD™I=gWNÉÛ—Ï‡ê=J¨zş«/v6®:²q}›qšİä‚v¬ìüíÙ+U­”PE8ïÕáªß(¬~PŸ(E³ªLÙº®ÜÃ/}¹äùˆ˜}8v-#‘_©‘É)[,ÑáL¶ş/GMqÏ¼ÃVÖŒtÕ])—Ø‹~Ë0ÚxĞdÛà»(‰¡TP]z¶ıŞª‰Ü’õJ‰ıq?‚¯–¼f†‡ço¼Sœ?QÀ}«‡tI9^¿c–c‡óÛ¢|?şñ7‰sÒD¡(§=Ğ:wQÍ•Hty™,)§ eoYW®Zİü“ìÛéíÜÆçö–Ú]û§i˜À»«itÂuèıs‡B%f³‹![Â&°Ê LO‰o%‹ø;?æB…í§çÇË–õ	N%
øDmJ&«¸")ÛÑN1ÛÅéƒåCH*[ŒEÒèÜ?¹„İGhÚÿ›„,n•C6$|à-J:Vû¸¢Îï®¯şÏÙ*m{íq¨dÿ^´	„ü}ÈN"Q«CY¤µ&ô€‰±İÚbíÔÄ;ÿ¡V=Nuƒå¼„ƒëuÅ@M]ı¨1ÂâÎ÷Cdı ”„ëÎoçš‰êê˜·ˆ ÂJCøgwEzïsø’3(«<4vİóøá]¶Õ™%tó’sX••İFr4ç8Şn”&C¹k/Îš›ƒØôX?ïœôãikºwÀ2yğ¥øÈQ„Ö
1}p4Ìøí9^:v×À‚OƒOo‹ K±?šrVÈ™¾Ôq’[Ø.ŞFâŒ™¿îâ{SÈxúÕrz>ôrŞŒlÛğ¨Â©ÈY÷øEiÏı³Ş‘…PäUMH8—V7NE7êl8'¦ÕÀ¹¼Ù;=¶éæ×İ©-ıAT‚¡ákè‡/¿Æöã¾H€Ğ½™-×Zñ…z«Ùâ¶7;è-Ù‘KxÕy¥iG1Ë¼Õ}VÎáÇdñäzZı„bÇç¦õ6xï¹!$I¥9h¶¼~¦n‘]¥6ÏEbJû£è'ÃÔû9§ùÛÿ"4@ŠŒâHªƒ½×ô³Äø¶hVˆÂ!ÑßÊ='.µBÜ’ß°G‡Q¦¢òrµMı7¬R(iõÏ+BÆÆ)Ü¡:Ëñ?Õu†7ˆ›şkÔñëk¥WesyÒF-[ìë9_ï*H‡-1ÙÅ€$æO¼¶ØšŞ@ÊÆÔ^œş¥âŸäù²f²ëÄï™ŒEK€‚X]ÃSöÔ\OóÛø¦tèÓdèøUÒa `’*JÈXkØ•aø)WÃïß²ÕQüq¾âÛĞÈ¤®ŸàÔJ$FM@„ríıïc °Ø¼åQft¹²0¦½Ê®½ã&LÌlú’ınĞnU ÌxÃ „ü¡;«U%",yrtÒÿ™æbiÖH;ğÖôh$Ì©¾‰hø ]$!‘o¡¸gbÄ)ÄAµ~“Ë±X6‰-WÉ\±…„³
 ÓJ:KrX™´g`CZåQ:°Uğc¯Nï©eŒ]ÏÛ¼epcı‡jğûÍ9&ğÕÀÌù.¡5z~²ŸëX½ƒ^óÒÍ”ÆÙ9ùA<T‘¸E2y~8±ò{É3!Öº*_ ŒQpàÖÚ“=+‚6àbú•ô İ­Èë*ñ~Íıs£7÷Ø&B—àËœ-Ú&ë;g”{j¬VÈW9 L|cİ¢=‰ÍÌöäÃÅœDíÉÿ&;İ±Ã×{”v{=ş£"1ß¬­¦ŸëÅO¥p¤"Op7vsûô~i½b]a3cc™&ê‹&
§e(šH*)’›B" FÃ ½÷<ï¨W²vÆîaË
—Áú[|•ÿÎÎAÏ‰–ÕŒˆgÁšÒµåj§Ø‡¥5O{b¡>œÒsMl¢ù?ƒÅí…İê0ş£ïvF¾Ì·Tõ¾¶ÇŸğ}¨±µ'fæ-&’55maØ5Mœ_…p	65l¸52ËGó>öŞÑ[aØ_¡o[
µ³¥õ˜@5ylÎ;ñã¦¦R%G£ğfˆ•~bºÖûÈïØ^êçTÿğ&œTa¹ü¿Í¼=RFÆƒİYPt]œĞVy™ü,„ J¦æI4bÒÆ½	ÚRü[+U¨Õ‡ôõG€‡*ì>ı·_1*`[dOcR`ò¾¿ğmÇ84¿ë8/Œèè.ÿÄÏ¥õğ¤TŠ?˜šjş”S‚¾ÀQŒ„ÚäëT.²ÍHSFª.™Iı·ÕğGİx±=Å[ªÅd;ü=_ºƒõ/¡&.ì‹'&H¤H¼œ™şZIXÇ\…2»Ê*$nQÍ£p¿y‹-¥¡çÏÅ)óh¾gÎZÎß_D¿í\»b=–—ÖïAÕÎYTÆiî¸Yø éÆ«Í·ªİB¥oQ÷¹~¢1ÿ}À9—œ10¤÷4F‚€,õQ]:àè6Ïx;•ÄƒÅ,¦$”8³ÁÅØ¿)ß}|Í¹ûˆ‹kÃQ›ÒU×O§â\…ü%û>íƒ†&¼‹>YÚ©—¼Rƒ¾:Ÿ»fùF›ôı¡G¥@]€â?ì¢w5kLER*°'ÂÉ’I"9mÀ)úŒº	—m¹ü›ÛÚ­JzÚ;¾ßY..ißlƒFj^;ä€jnFÿ“7¼µ¯œ˜fàèêˆ<’lñßîL@Tí°u;¡+üÈa€ö¡/ Šˆ$É!ÎÖé‹4LÈiè|A¦pd= ±z!Õñ-Á™b!3».B¿äV.3 BM ÿGiè	'Ïì•2û!|´¤/£ÃÍ*‚1‘øÍ‚ùåW³_·sØŠİ8É–R)×e	²IO87Bÿ•º< 
â7Ô»Kƒbô‡‹•ŠqPö×hÜ*ÓÛêäºå5°Š| ƒ+8³æ8¿ëhö÷vM>{ä1xB·o Êı#ó a—ÜĞ…”*Ã{Æ“ôÁÖØ#äõç×-Ã¤»«MÛm&twÇ"jÓ•Ö”Ï#Ù3‘¤¹Îñ-åØ¾‘·jã’êë¾Û›œ`ù o>m„êoş¯˜±8TŒú“;ô;¼©w<xä›ÍI)·‡Ñv‡t[*êNÙ#“…ŠÇI£ø&EU¥R›÷8txíÚ¯EË»<EÚt•@†5#lıµ:Fƒ¹]jy01a<‡ªZã\ËT¢|İÜ[lve®9f–Ìk3;5_\âÍgÈYĞùÛŠ»Z•2[ »6ò}‘‘ióáÖT²Ûí$)“L×äÎ.]L,<šª
Ğ€òíœÄ ÊÅŠŠèU
a›m«±èğiJ]!V/ğ´VX»àıç,¹ƒåÏín Ê¶Ïyfµ˜ÆşÇM6k–™ù“ì_‡ñ”ÊQyÕjdàû4jZ¼a‘±LZW5ù™M¿çñ„1DGİYó¼9' UÁ³Q“Ü¿nÖÆşPÊY»X¥Úßš¼šü\G£²èÀÉo[`he9¯Â-¬C0³õËœ[eV|`‘,Õ‰Ö1Mµ­6Ğ+œ9›y˜
'şºÛÌ®Rìó\q•¬şÀàzÊû×¸ªöãö}””§Ş»]­ ãf«ß¬:ö{Ì¥;-ÜŠQ8(äiKrgmçso0" Lİy3‹¶Áûæ’p~5¥ŞœÓ¢?/’Š€ãlú—ú`æÜ.LÉ¨¾2ìŸ½#xr¼eî›ÆèTÅÔ³zŒa§aÂšjp'‘úDaË’¼G&Åeæ¬ëüV¾CC7„Rdá®V^\!WÎƒBáçb.»Ëç º€i²1!NºkçæRÍó|ÁĞRä0n(½ÄÿãÉ±¨=Suûİ£Y÷gD…‰œ)º4æ¶Ó>!·‚L’lĞ8Tãÿw³±ÂTnÂ6 ––ˆzºëâÃ¬®tı\ÁêİÜ¬AÍ`Ì]=wiéBvoÔ÷Š¡¾IÇPLH’úÅÛ¿˜AzT’ú¡‹5E	H½-”EhíWiVÈ^‡“Ša¨ÖÙ¡ˆ` xNjt.¨PŞ™l|]˜¨B³PöZ‡ø'Ta‡c6¸P†ÉM³|
BDÿÁ +£şˆ"ìyRµÏeé^ÉÚ†Æ”Í=§½‡¥ŞS{É]ÿ‹%³0Ğ@ƒÉø`)!öÛşA†èUxîİk†£‚aï9Üİ¼ì:o§[œ`ıå*£,İä2¦cÑ:ÊÔ5E)ßÙŞ_yÚ‹¶##¬|Â6qVHÏÍ¢g·™HR}»ËÙ1p$([Ö¾)Z»óXïc#ÁNs}šºğÈÉ÷§bÄ3K÷ÛâŸjÕ"$}¦¨TP}ûÎ’¢X.#DnjrÛp­±vš€dBhÑ1y¹Â‘y×®FÁ¶Riä2ÜEºÔÄé'KMË‹Õ¬q”]ôĞı¹#·¥.,ù¡µ-3Kdñ“0vi™óôä³Bµsî¶ÀiyøœW¸¸úÄt~ÒjÃ;6­64w]2“^#â aë Câ”Ä.QçUÜ§<£ÎÁ!c`÷ö6«£Íê_2Ÿ;hRƒoÌYöä¬Ï+„±YÜWø(TjyL\DğĞâï¦®à{ñ‰™şèˆ½ÌõNÖ$ù!é„G$µ	Ù¨ßÆŠè3ĞåQší½`UÿŒòìXÌ pìÔÉv4í?¸\@jÈ€EÄey"Ûa‰ƒF DjùÂ3ùübİº±ìæñb]gÛX¯Tšúš†oõaãzƒùİŠØÕXç7tËN'ü*&Ê’+4%â!øjˆÇW<I{Ÿ $ààiu{Í¼8¼Ûü:îÜ.OP›x\G¬Ğ´x!ºÀ3ƒÃëÁô3¾ügJÎÁ PoRƒä-ø-äö¨íô
ò¡>:ph W)¹ôXÄ>g!ë¦r»ë^fİ\QÉ =Á¶Ü¢ß0I£CüdÚÁÔLo¿ôáš-áußx*6¢ZTlŸr¿\ËÈvßUgÛ/–\JI##KhxAkÎšÚ-õƒ‚Êt¯,Ed•åßåAqÜ(èİ÷b/Ôªó¥­%Â¦ãïÄ·ĞsÆ†|Ş×”6òë-5É|e¡ÔÜr#yÊ¿X˜Ğòà@r/äšépŒıÚºÊÓÅ¥õccDp	’ºk„yCñƒ€ò£W™£ï·ïG ·ÛXgÃÁœ£ªŸµø½¯¥~ëÿ­óÀ´’¬ ş£ï´ÈCÿÄ!¿ø^/a»šît«R\ r†¢íšøšhñ²TB‰ë9¼±<Üı¾.î[Á`‹í*l5­ŒmãLnÌöµb¡N"õ«¼ıHÂ÷¸Iyë½2®¡ê(½¯÷Ï Œ{›¡f6?ûjPÃ–`eB1aæUœdA,ì`~ï¼Ü0Õ²ÙãbaÅ¾1—{8,\:Ê	¹{gõ¿®ÎUÌ…ïÿø;“7¢—¤_åÔ¹a¥<=øAl]ı¹7»¥˜aİ&gÈ|Á<•õ}'N³2í¶8gUHÁë¹öJ‹lë)¯ Mqg21)X@	¢‡ãƒkbÊ×)õ€ºB@~ ©ª¡­[Ã%eNxLßºõÄ×xı&z3Ç4„Ç•ãÜ™*ÄšVŸ÷æÁcæp˜Î‘sR¢Œ*èhÿ5€#R†zUö:·˜Ç]4cçªW^’¾CÄ©‚î.ìúsuxMR_ºÍ/Üœ¨U…ıù
´ûµÓõœ¿»•]´Ş¿h…¬Í¸™‰åw™‘{D·ÕNGYêåˆ–©á´Í:Úd/š¯…l÷àÃ*[ú»hE‹´+‚ÊÅĞØĞ…×Â_´¨”q+õø(¶2?àwÙj¢ÿõÕıHÀÙy5iĞ#wJ!?ü©)ØŒÌI¦Zµç‹ (õN3­j›E
Uñ‹{ågç—sjÏ­¶g=–›‘ğ ÿŞQÔÔ °¼€0¹ˆë´ÆN'ò¨ª-\öBdLkòğŸi÷µÈ–œÿ/]Ëùç…Ü“ÔÀU‹i)¹y„+Bì=é¹ÏlkóÃ0º/Ø›W¡Ù—_xÑa¨àÙÕ$¥ğr¯¢¤R¬5Q×·s=¤¨¼ÈÁ§B&ñTæ0ó‰ñÊX¼É´²Î×N,G*HÅPÏ&vcî­›‹tPpÏ¾=Ëô ¨ÈtB»GVeu æ‘ÿ,¹×º]d¹»i—¡Àß¿²ÍÎ{«‘!âò8
•OG¯:I`?õ~G3…ÙXv8ÉÊâO°ş¶’|i è¤`Œ¨³ÆÔd ´oa.’Ğ„º$ªùëD8Á<‘xÌŒí Iw(hh[÷z2W3¡u!äöNòğ°‹¨f ÉS	›¼İíÖ‰WÄ€iòÑéˆIİ^ÇoÃ–›cR?Í¥ü‡	•j@ôr0FSè!Q­‰øFQ÷ÈêxáQ#CåÇ€Ğ©2´i¹éu5Œ€1Òš¤<zÌ ­ôğ¯_FLTŠñSó,İ6Q%¢c
tÉ+•Ãy ‚GµqğÖÒä0f8Ãi#ÊqVÈ¥ëÖğ^ö <ÄkeŞøa£^´‰	¢¼Ìg3ÊÕæKgœwÃDì4½şEÅ„¯7RÎ«ÔšÕ¾hœ§±lªÆêaÎÂì–‚ŸLöøH4~n“ê7òI_¯h`w©bu¸m8n4x–ï³å‘G\¤«g`Ç³İıKŒ,šü3X«ÈwÄ2íº¢}ò†r5zAW÷ãA<Ç™($wãPp6jéËö Ù³§ÇĞ&›6­ûnZôq³ÅUÉØKmîE©eËŒ:Im¯8´›N·%}*?<ÈÀÆ[ØW°R™ò<Ë¿ë£Ë…^Ì´ƒSPÉÂ(Y{£%¯{núçySW6åå9öÖ­=|ä5ˆ{O¤Æ˜ˆJWX!ãéòáH ½W®	ó“©kdmııÅş´îPdîù±L|c	–ÈÓ”õº’RXyx€aêé=Jp^1Uj7–ñ£!wî{eG@²uü¼–çày“f6Ã°¾Iµ#œ!ş÷@ƒA)ğ?£ÿšnQb  (+à
°,Ôø‹ûpiNFöšt’Ñëï—Ãiı¶ğB0‚ñßÿ»
=;R3	Œt1Íc º.¯¡tsÔ5…a_øu~jÎãI„ª£ÍüDv…kPŒÚÇ­X¦’¦H×ªp!´Lÿ³»I-^`t’çµwã­”ÀS9ƒ…sPH$dÅRaŒ/Ò(:ö
îı¯>CyÆ¡%¢¹©ßB(|»ı,Ät‹
o¯tÄâ²{±îs†ĞüvÉfÿW½W#wÏ†³’ëåÃßs€›¦½ì©½Ì _´[ÈÅTŞ¤Â<L*4\+¬[_6†Ï©¹Û€ZíJşğH?·+Ll¸£—åru¯šg»ùàëâ›ùĞ£§•ÜË¾Vrš¦ãyàx‰@</â'O¼$±5+!"4TŒİ,-üdÂq«åØgÓtO-Q2Ö‘6ºÍzÚ¿ThÄ/\ ãÛ÷¨yúÙy{>.p¾?5•î`ßyAòcO'¼ZZ¿¥>u&®Bı«ï˜6@¨R%[=ÜäV%•£Vjw'ix´òL“Bºî^fö‰½ã*p„0‰ÚÁ&+Óó>ê¸z­H’´è…9i µŒ¹¼.'9œ>(½é·öşe,GCkmé¤Ê»9BêÏT;Î p©ù,"Ù`cDÏñ´ª‰ÏL@e&VTXÚHô#˜ÄªÕÈ´"‚	vkë‘ckÌfS1o7I|Kœş¿;AfWâSMnòmÉ†n§ÚÕ/r“R3>Ä.¨¥xÍ¿¡ \m!™â‰&Ix%û_:À~Îî¬À*!4ŠàMÊ<ˆËÏš‰}+5^oALÂdíÏX4:ŒøámÍ'ˆOjñØˆøğê› «Ù¾ló*Î%¾:ì^sH/_€4p,!êæyh®.Y‚~é¢Ÿ¹™º'Q H/^§Æ˜+ËœnßjdÀ²"P†mğ´&f5c*_Øº4Ò½]–—ÉÇ¶›n.˜¿jútªŸ#)@>Ì_)—«ÄöójÿÑÈ&ßâê§¢JÓ¾ÃP+»÷Ók—s£˜íèà×EºÓs…»™/a–…òàus¼&ıà ¥öõ±úÊ	ÍW¤B²rê>]j¬j€–ûoë‚K6S~á×ø¢Ô°®©0S_uÚ4³Mşñmüq† dş#}í”c1ÿ£µ'—H¾ÿNÛ¯É2k Ít¤ŸV®ìË±d‘½F}üf ^“—Oÿ Š%}¬Ñ’ö|Ä\½J—ÁK”úu`q•šsc[½Ó9ÌuÀáh4ÅpòÉ¬/å<°\G—åé¸Š]Ö¬°»›ƒ¢—PÀ£'ÇT±†ì‹¢ ]HíDúk1h›ó&k‰¹æuâÂ´u}r‘oàóˆ$é=}ÿ)4§‡;şfÛÉU¥ş?XÌ Ô2©JÚˆ™§e/ïÂº+Åjäfµ	IÏx·
»üµ"oÏà[/¥w>ˆ{¼$«—jş‘J8«©/Ì##wï7„Şc1sj`NÇ¾ù†YßUúâGÊdáæZÃCàR›+)EçåëfüxM4É\:æd^DC’¼Ãú—ls•”Ü®>3¯ÂÑ7©Ã¬¸ÌÜù¥ƒó»”‘"›*‡+í¿ÉŠÿyìmõ2n¢e±ÈÁ‚Ø%¶îŸ.TV–h9¾^à”.jit>"Å…QÏïÖ'¨£näó“ùñä°ydÑs¹ÂÆˆ
ì=ËıX JFÈx% adiè‰Ä|™‘Ú¸ÌÒüZu7¨‰¸€ÈºG°‹ôíz>€é–#‘ßŠ8t×ì‚C{¾ë?h?kö	=êıÄª‹ëõçcÁj‡á8¼Zqı|»:6r´*}b¼‹–2Ê¾­Æ4qÏ´GlLçxŒW–‹­VwN³(§H4w½4@ÍˆkT#%Š¹"uˆåÄ)ø{z»ˆ”-Şµw]#Ç5ŞÊ6>°Q°™ qéíìFl„QHv³´ùíCñóİ	Y ˜š,š_™´™§™Ğ±¬2-CuUG6¸Æâªd=½¿BNm
‘gsm2ïÌ=ZX|#vé«y$*ïÔàÖ§–®¯¥>à˜OÄ8~{OWƒÓãè%Ó[†Ag©t9Cë™¼›Úˆéº8ÖÜ^º13z]¾A	Sä7=ˆ–ò`Ëdg[1ƒm™Zl{U+gFeäÒ¼~¯ßã\äÈ:Äùç¢zû´T&s¢Y\Ş VŸK¹IiÈÕ6q¿ÒGxÖ”2Ì9ÂŠa¡5Òn—al8Ç}Ñ ´­ÛtrxÎ@}.T/›^°õÕ´¹k“q¿!î)ÅóÏ“3°ÂF’O‡è´?ŠNHëf‰¸ÖJ7LÌÁbë(ê‚hğQÉ)— ¦ø¡SÛZÂƒöıPõ§-ACI"F›îéœa®…	&ŞN>À4wÌT/»®›W´©Ë;¶g¼>Lyc÷ÆÍˆH×Øn—¬_8oÃ3êğTf?é-è÷ÎÀÊ©k:¦€Ç‡6 ’(³§[ŸÓ°ñÇ”*#’ˆXÃa•µK* ‡F«¿.®!Ê*èÓ@¯àEÄ=õcÀÔ‘†>²>öåJoAš«ºî^Òû/®p´÷ß•®‡A·¬ÀTz)èâ#Q¤Ğâz× Jˆ,ÌÂA}£¾+øŒ»RÛJÓÚ–³Úİsø±lSx¸#Ó&·	6¹ó®SÀÇ¸(*²â íUİı½½vEêß@~ZùSËœ3¹¿½Æ×mnÕÓ¥>	cØ‹er…Ùµìwìö}ÑOªU|4C{yğÒÙY¬£ıŞĞZyn‚ÏáU¨Ÿºô‡ÊÖºwG¿„¡~k',Ï]wá‘¶­¦â“ùI“z£÷½È‚‰!ß	U7G÷Fá4à+Á ²0êÿV™‚<ÏİòÙJNñÜ˜9IÍBş?òÇ…;+5ÍÕ7èKƒ¶Ëd±Ø~P»,UCÂ*å†ÏçÊÏĞš5€£+…=$kXñÀ ¹·/ë;Œ—ØßÃ/3p©Í˜°Ëd:AÇwä +QÈ\M‹iFmÚ·õC'¸Û˜•T–®şù&oŒOıŸÓ7k¼æ<vÖsµ˜qÈµ6ŠpÁ°h Í€ÙBÑa‡™¼fÂÎ4Ê	oRnåóf2!}î1I„ü°úfÚæ}\ßŒtå/hÈ`qF€@2[Á|›|¥r¿!…ò«©Aüê±,ÙÍö®µ;˜qNõÿ^ZÂÂJÃ4º’``M’JY½•òêÁˆ3W½½›æXE“U9©õ*ÃÕTP2Hß´²´‘*ï¹b{k†•¦d#†¿á‹«ÖñÏY‰:y	F?*ßãÃI/¢½wõŒö>cg§×
¨ÎlåzË*}ë3?ğà'GN+ƒ%zT›Pp_š©v-µ³è“ö³­¬G’èdKŸ‚ëz€$ã<†n¨•^fÚËOœü™}w*8µby)Z¨ŒX“ÈeSª}ópYV3¯ŒI¬N¼;' ÊnTKÃZÁ|	G¢"„ µŸ‚ß¯Hf©O¦FŒü,Á«TGu–pYÉHÖwVk¹‚İ+¦ø!‘;í S‹H(êîv.ÌäJÙ”Ñ:,v ³Üâè¨dA²;*Î<dWÊ ñU@©,«æ:`å{dã<{U7|Ÿº¡£õ‹^ ³Ã"Ò×eRsœ—±8Pzígİ«ò‘1—‰^Ù©x„‚B)ü•xt–Lz­'B…œn›y¢\JÑŞ|±âËP×KÅOã]!0.]GaÍ¢Dš|[@ƒ‹ ´bÏÁ°›]æÏ¾õöÙÄ(Æx}Çö9éymãüF.¾x—Q<²z”+ÒLƒb½0ª¯fI´<‰t„x$Ø<t–¯ÏÄt.EÒòıhËÔÁ–sÔÎ¿ZÉıZc²7Æf`ß÷>f?esÛ2&SYª¸À"ÜB³Á`V ¬Êí&!åóN-µØ‘çC[µ8B_$à=Få•	/È£ÀÎ•1’F•.>–ãÃû«”&@¤I ­:n%q²ÿ6j¼å["£pARÈ<)áğVêå¥ÊıÊıXCo7€„$ŒY~Ô£RK%ÈV}ı³çã5êm¶éÆyªãÁéô tİĞqÙ(íQc°¥Ê&[NŠ„d~¤	ôÕUğÁ‹¶—Ö¥àÆôêZZiÖ©±è½Š“ggçk÷BQGŞù•RãØ–„ÃÅ.iîZJåÛ!Yå‹‡ô?|[ÌÕĞN'j©HÆıP€ÀÓ@F`Ø)ÿÛ}ƒø®ÂpHì¹¸z­6C=à×9hCû~ú™;=]„‰•odÒ ß~Dÿª–~À.‘^0Å¢by/LkeÔ½—şÉoÛ	«*ì_Ål.Rb(°L²PuÔĞä6L;Kº÷à”VÜzv›J5Åb”BMšÖÇË-×<Åä›vƒ«€‘×‹ookÆ>®×9ª:„Ğí%À'Gp¸Pˆ.k¬QC–ğ{²?ï ¡õÅ·è….«†ØÉ,÷Ê9ç%¨•­oC‘±jœA>AûeUĞ‡’± ¦Î¶úv³G‘¡ĞÜØİÈÄ=Éçmúë.ˆÂúûŞòïâ<¯ê†¾ÉçôN ¤_Ò`Ã7Œ»'L“j£î8i05Ëh:ÑÁàå—â4„¯¶ùÀeŒãdågóÉÛ%5QÖ0a–«»¼âêrQ×HlU¿—”¨­-yeE*‰öfúû‹èäÀ]^›»ïUãËX¯Ï\ÛG\S´äœ†­M9{j»-ß7|Å@ÈIÉHóµu¥êê#9Şƒ ò „fü‘ªÆ‹şwÏôªBC BÂ£æşèÙDâ—°ç«ùC‡¹èÇ^ü.}ÖÔ¤e°,3owIb^kcçÂõèkã‚}A<Ò„ûWoãQ¸´€æ”d cşXà^Yè¹¤”½9U·ji=ø7Óÿ"ÆQ”å *4Asügo_]²]¨„±âc·Xéq]°K£ïcöÈ±/ÀJPñÌÇ&Š¨~QkI¶|Èø[Ë3j	ñsÄ‚æ•Ó2‡Dºğv(cN@€¸ÍDÉR¢Ì]"ÊSûySÌĞ—Ò#ŞUpö–‡ä–ürnxÃg#®è+ıßùÂXKïÒÃ“h•ÚĞnÃD[g²sÇJ	.<Y†A^kŸy8·†óe¦Å
R6«ÑKõàD©õñÔf4/b	$.ÌÔùJ÷_\ĞkëÍ×=]ÙŒ`»x"Vvz œ®4}¦=±¢»bc„6˜Ã?‚Ş¥€3ÈFoú%·ùÀ<¿Ã{åvÔÊÂè¾NbñÆEóßËèkS» ¤è† æ	©mâ­ı®÷Y÷@fæíº¸Cß`´.f¨çœh{y´ÜSzZÂ^şäÊÏJ†/»o’È/Ìú±¾ĞĞÌë>¼«®<‡‡©‚Y>|=3(£}æ†
OÀ36ª^iÕô‚&„EQ®şsÄÒë›ÿúTĞ‘4ÔqpÃõvJFx…1
4T`/İ/J¹ŞÑF“ã³HÌ„m›øí]K‚ Û(PİVÜÂ¸cmBÕ\Irø÷ÆöuÅt¡Åù#‡±°yzX™ ˆşÎm<Sûdÿ@–æFì@Ÿİ`$˜Óf…­ĞÊIkªüJ¡33'7)Ÿm@ä™Hí_+-§Pä¯r0Û‘oÑ©.O ïg‡ü¿i2Ò¼¾êvÊ˜#0"MÜı İò]¥]ESp¢MôWŒVJ]Ò(åÉqä¥§A|U¡3¡=Ÿ¡¿É¬úcÆü}ƒ÷FgÑöå­aÈY°e[ ÈÍØıõ|¦>‰z2‹D›€Te$Iõ¿sNë»¦œ’ª5Œ¢õ{)òûTbN€ËÌúÆ‹.¹t¶ÁhgXV@®õ;Ü?˜aáEÕŸònÚRsIÈÏÑ¿Œ‰ï°xË °^´ÂDŞ“¹Ì~í3jú¾7­ÅÏ¬H	F¼c[!juNøŸBñ”=:¼}u÷¢ŸT&¬jÅ†zŒ v¦ãcØAşÈ”v–©İ'zã³!m§nì‘‰—$eñŞhì0Zli@wÒe”ÓîhDˆ“×¥„¹uØvõÏL{ó†­³ÕÒ8ìI¯Ûè˜£–,Ÿ»r)Kg€…Ø­†3ys’™´ØÂ<À˜ù»ãĞE#åvq¤§píW>T=?F=m# Ëıÿ@ÎDÕÓByDÈå‡•Øü+¦ÛYÊbë€‰Ä–áãêÖĞ-Ç¨ÆL¼™¹kIæ{`>L·‡nCœy‰–ØXğÿù›7×Wçè&xL•]Àxm»ŸµR*À2ÆŸö4„9~á±IeßerGËM‹ œöRèÃ–<{¼Y#À\NìBÛ£Í,»ä.îöX+àı §p¯?”ÚrÑÓœ÷\¹=Âô'êuc wñÌ|n2i|a’AB İ÷ÏO¾˜¹%[¢
ª¢¡Bßü ò™@îŠ3b>ˆ'Ux°v>å©s£ª‹/8¸VÀú^^ ëPiµBâ˜<¦ßš—Nğõ«{½z©ØAñxaø³Æ7*í²BRUHğ*	ô$rQØò•ïM¤FÅ²²fË¬…K}EaEûŠãçÑ`3]ˆ£lƒîkaIÊ"ÇPvä‡œ­(x—›…™±4I«öÍµ±æ,²÷*†•ş¡Õ<mÆ(•/JTöÖàsNòú´rğ¤Ãp)—lS/hFİÇ%@ç©?¼ºêÇä—ÈÓnÉL¾™NÍó 2L)k¿‚ÛÜ
WqÌ”‹©0èk?
ô!É+Û‘;Ieëş@¿tÇdé’OQ„™ÒØdñà˜'Ü„(nÿ;6Pøæ/'Z³l%vBO±æ0c(uõ¯%[x|;ÈŠ/2oÇ(^Ï G&ãI8»û@5Ë3bœ˜ÊŒØ¦à4åack¯´~­Eé­u*}sıSçY)Û‰CÌo\8æ*¹n,ÑlÊàp˜{gè€º¡M‰’ËÄ?àVc½Ô
ÖVÕ>ÙóÈ‡ı}ˆ¡¶{§c‰[Ôê²ÙPŠ®½nÓ„\¾	üŸ@"˜RÆ‚Š¢ï:
›éŒçTö)ÊWÆûFpÉ¡–L4UC-òô‰I6-a§Ùi7xJûÉ­‰*}µİÑN‡ÄÉÄ_# Ğù´öù˜ŒëTÒ»ó§P"°bì¥è”{³ÁùLğºŒÔƒŒaã`¨IŠ·Ëá€gäuÏá§#
%G)›ºÏ€²–ÛhC³’b_­cŠÛdñ­¹y(cŒè÷98nS=€®rôª8”±lmúåÚbT?,B’/CÕ×²JHáÏwû{?cf%bÕsšÿšÌ÷Jv~SÑ@ùtãÂãXĞV3Å˜üúIóşc®.»	 ©nÂé‰–[…Ç,Ohvßæ9İ-	á’ÅNe(öto>Ìhö‚FF£'x¥=Hoajİ1vòæŸêÜH61önrju8Õ>b•o/ñ·ĞÑn$°ĞBş)yv{[¾âC:ßyCî—²$Wö4eøvÂ JdZÉ}m!udû9qÊ>ĞJÕic¨ˆûbl?ZfIÚ¬ş~UPçÛÕd¼¶›ãÛ½óÖæ'ªët_!ÁUÁQès£*V‚òĞ¼Å,8ÓtÖJÆ/õSÔÆuWÍ’óú4%ûÓÆ¥IvËÍôH,’P@,)Ğ¦OØìÏ$ıb…´«ÁèÅ¸âÉâ©¼SzÀK«ÉG_üô¤ÅÜh-d=v¥÷²1UšÖ˜D.:±?Öú’<Yß2Å¦P[ZËŸğg4eßv¤Œöî “uh××Ô©³H‚ÍİÇ‰¦9¡ É†øÊMO¥<Eë¶¬S‘¦çJ=…öÄÛ©¼ËöƒrŞGÔ§äûv öÒt·fi	²Õt¿@\¯­Û›å…› 	,B/ºà7‰ù’'Á«Š(ñ÷±AÔ£–—rà±J“±\_.9°D4Tw©+éWu‹áóE…0{$¸°Nÿi-c¬W™bİ8Ş#|™é°Y“§ü¡Ï*Ê9ó}q¢¶{Í$yFÌ¾kü±g¼@-±.›~	§D8ƒ|šÉ[kAz‹ãâ ´‡U~eKÍªëK§ş1§¢ºrPÀ:EêÜ`é'è‹èDÌßÍıÑ8Ã`¤›µºß=§IjgÙ±úÆÀÖ¡8F@62ë¥àóFò=·¢l	xÏ$  ®åœc—'C ÷Ê€ËstN±Ägû    YZ