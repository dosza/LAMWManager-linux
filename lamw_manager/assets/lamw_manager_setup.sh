#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3359045978"
MD5="a74b8ed1f7cbc686122968fc8001448c"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23976"
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
	echo Date of packaging: Thu Dec 23 19:29:25 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ]g] ¼}•À1Dd]‡Á›PætİDõ#à€§ùcöËKñ_Ğ—Ø™Ş€Ç‘­ÆõÔíŠh’V2{<M0fY³µ¬XÈ¹]¦Ì™2ñ2,ü‡ÂÀ óz#×s<•±úŠ y >,;ª¥úÅ<UJŒ°{±l,wä×Ù#eáËxBJ–´¥_GâÏ_Ù¾í|ŠßÄyåÈKx´êÕĞí‘ºèd(?Ä[ıiVÿ)ı¶9ğŠ*¡]™!åÚi0)ì…1@~æïÎ¿ªãY™J1Í^/¾?DÃ=ı,ÒšiN*Åaª]D±ÈFR½7¹cbÙíf•i.€~S?å¨rq²*E?ÜÒ!“:‹®$ƒõŞ·¯*äó­ÚÙ¸ó%,6Ò-+”ÿ¤ÆõÙhS~
;¿0ÙK&.‰ìkPvëmI½~¤½d?Ë§y·vÒÊÇÙ(¬X•Âf
E‡GãÀT™fÕ×ÑŸLŸÆ­âßT’ğè†8(§„vs7°9iz_å{ÿUá.#ZK9ª(¬Ç|İñ°ŠÈÕÄ³ñÂIØ’’ôú˜—Ìù!ŒÙ
ö$‚L	Š1>%+ÄxŒRÔ¹ê]Â{‡•İ	ÆA_sZxQ ·ŸğÎÔéˆ„	bÒ>œLÀ{x
Ûº˜3è¹í6’ZcË$?C¾ù-Ñ0â¿µÑ^“Qî52ßğ[ıs1ĞÂ™¯¥3É°"ùïxMÿ-ÀçÎÆòŠıàê)›¿6@!âLjcÈ1Åc
Q´W…s*‹óW#\Y¥wwt/!-5Ad¡2~&íÌ^@¥èE«{zUÑíÇ…¡¾‹K±ÿ¡øàˆ#›2‚$ÜšOc*Y[ n`ç«40e*òv¦©CøIa;éfuQ4‘@Fã:`gs6.{ZHò’”—q=œP©Ã‚ä! {­‹è× ‹ö?_–³µmU´QµQ&µ¿Ï¼ÎÕ“x:ï…ÇĞ:—d	X
ŒøÙ¯=D·!ÎÄh¿[¡t¿«ÛÄ¤Q÷ÍŸ)âCÅÃNŸ­K£Î1­ÍPš4ìAMÛPè_,è½ó¿Xó\ŸŠ—VXB3MBû«X{Ÿ>ÊF…Æù#Şör£¡ÎMò²»«_ÅĞíàï‹ğy;|½ÔÕ°<Â½Ó¢·áæªIBÎàYó5œLŸÿYÍ_Å<9„x]ëçôgç'=Yà™ÇQuŠ¼Ä
¾Ãœ
ôå«/ä¢L›Yê‹–tX4r±
—›°|·ïÆ¯ˆ¼sútÃKØî:zdÚ/a„ß{r›®3œZ€ÖĞĞU÷‹K±ĞĞòFeDZQòô™Ægb›k!^ÿŸp÷³í—äıAn%Z{NQıÒ¦“¤İí8"pn²yòÙ7öT¬”BÛeø(ó{è%éa„„âÁÃĞA¯à¸Zš”ˆs˜cÖø¼MÁ*RÆÃ’şìß¤”,Šeı8ïÀi&À88î),ßx
Ågù[€#Á Ÿ"ŒIˆ9€IüI*‹A˜Oş(\û¢7!ÇKçÙ¦Ü8’üä.Æ¿x±µ€»"E
™0ƒ¹øTr­±âÊ6ä£û9çlDOjA¨3ÿ1)şì.´É}ƒÚŠ÷ÏãGĞ1µbŞ´ı×­Ã‚Á'±õqñ	Õ«pÏ	ÔÜWúšÇŸïz ]ÀÁ5odş6mFh¿i¤ß—LÊl|ËÌ ÖĞ@`b37µ0«ØŸ;T±-)Y™¡•½%{ßM0ˆñ3f«ôÅktgºúê£p,[î-HKLë‹ ×%Ğ„EXüÇAvòŠús8ñ$ä#Ò~ˆ¡ûšÄûc€¹ÃÍ•³3Tït&ÀjºœixX:Ê²aàÎá	Ÿ”Ş¶e_"¥›Cu2 7¾øa“ÙvEjò t™œÄö>… ½45û¨ÄMÉÊìä\g›¡ïÑ¿	­œÆ z;ˆ$U[7û37•×Úä>«%v'Rø4˜³×ïİ"ÆÁ’e^òk-p„7-SÑ•Ãsÿ+´ÚaŞyk< 5“ée1†mõ»?Ê¹×MÎô\×^2V2G€™4Q;Àé~FÑïäG
Ò›‘£Íaõ»Êî‘Å1³\91H$ï"Ñ#¹G0škH`¡ÊÍWO·¡­ô5ŞìD¬ÂqûA^íR²Et22µ.3½©oE<o‰'«¬ØÆŒÈ¾ûÜr~€°wğY‰âuìIí79_)İ‹Ú—ºğF«£Ì#İŸ‘œDá"äÉŠ|#¿a>»l†qĞBk;ªÛÍlhôƒ@rÕòéj€uğgQ©»íFı>xÁ¼!uè¹áçàhÛÈi¨ıÂÑÌu`ïe™ëf®³9Ã¹Z_¼¸U´ñ7PÌ5º£ŞÌ¦¢;%úT’Ä…RÃ¦®(ªô\‚`ÑqÕyôbsç>u·feíÖ4&o,Î`ò€ò7ùtáÎYîPôVş3öçfìM…èWùÏÿåÒgîSƒóÛSRs0^x±”Úº¾^RmÊğJ®åDßë·`©„\æ­Æ#?E]$QºoP£ÈKÑ2ÔíÊ[lTk€Ÿá‹üÆ˜§¼Ó›Qo!Rª}¯ã£ÓË7:CÜùå0ËûÀH:_Sœ³&ğtúÁ.$Á3CÈí×©sRÀ*0˜‰±(sûÅ}·ødç?ÿ®ìœ…+—CG„ôÄÀùŞ…‚Mõ¯HÔcİİÅ‰c xÀÌ­Ù´â"SÿEnÒÖ*S~»ÖAn<â£1(,SÊ‡úÓP|z×)—ËÕÃ„<pÔ’4ùËˆ¨§(œËÌõgõ ¿²ÒëŠØFDâÿ=%ª	ãâ¥óô¼D¸E0»„2Lœìˆ`ß.«Ær#=NúÙy"/óöéª'b×{^µïê-ß•è[î€)L¤ûµ¨úó<[ÿ‹4]^ÁãlÛ^¾‚PòÚ‹IÀÜbA 0ôWR¶óÂ*|ğ÷‚7ÚCBD+‡&HÒPÏ¦fbä_Vğı‰'’Húì›è;«¤4Å•¨<¸ÿ$¬ %_:L
<Ü©ªá¸RíAëïü¶#ö%÷ª‹¿°ìË³*p}DOK/ò^ÀlîÅñ)rÅ—ŸUÀÿ¡NLõ`;¬^¸F‡<"í 2@9†Ä;Ùøl­pSÔp<“Ëöà&4K‡ÂƒÌ1 ß÷7›R Šò´µ˜²©›31~ØBªò"
s‚Sğ]K_³ã2:ïïÇ†÷A BœO»œ]êZdíöÔ%L±£FÇ½7Tn5üƒhĞ:ı§Šü/ˆ´|é’`ËnjÅÅåÏÑÏ{¢‘à80Qü’²ä\–G;çË§È‡\Jæëw åY)@ÿ9¾Ç,'mgáš„ÔÂ/MG›;ò™¼ğvFñn’
$/Äe'{'ö)l¯xJê6CtÎé5¦ÏuRV.î·~Œ,İ@n•Ô‘´_Áv€øQ¦8PÒ}#˜~5{°%r¼€‚Eè À){¨YkëV±ƒ›À†Ú÷Ôc-è?)Pd„¯ iâ2"Öú×2`›òoÂôÿ0İvBkúŸ°G¨QÜºŸ ı±öÃ#<R/ELnã£¥Y£Â¯R	_†ã™LÉÂ…Øk$\0˜Ã÷5ÖÉRâ€‡±­¬àsb¯Ö…C—xÛ·È˜ÕÕÈê-..çËì3‚?ü¸ƒ‘ÙúG¢U°~ÀÔÂ¶¿…€	 ‘Rô¹%2·ˆ±l¿3ü7Õuî·µÜ­êÇì"lU1:
í$³ÊT1ú6š_#šİ‡Û@sŸ†ıèñ–Ñæ¥§¾ŸI_ï–@’ÍbÌNg”ÌEVÂeÿ7èí^É¼î_×»½T2A0T8¥—iÿH7qƒ²è:rÊ3ÎØ1nÊ*öRĞJœœ˜’˜§Èñ?e|¯ê=¹[ÃµhÉ~¦çy­ü}0&)Çzö÷ÁÍÇÙy|Ñ Š†,ÉùC»~?>vf°[vS]5ÍçÙŒ[B:–’JEzx•† ½?\¶ÙcîÀ÷=ìyÑY
Í@ğ8t¬"£#P¡u›âß—9;4Ä`§“€BİN®Ë!9‡–Lhö:®ÑP–@û¡Z¶Tu—üÿÒd)Pbk“şîª²5hº)=—xäl	°Ybó‚_•icfA^¼ŠUfM3Ë–7¢¹—B¡;ïv«ªNÍt‹Ñ±	H5“Eşå;%^Şxû6Å§rŠ—O¯cÛä¨Z©màzH,av«×‘Â¢ÖÊO”áèÃíB3OÌq)\$­’n”®ëùˆ—•ßúc:ÒI	<ıUYIeû±!İtå¾™(Èw$D/5µŠ:¦}"AJÿ“|§6`à.ò×`]cÑ[wÿ€ñD÷;sŒ@-ÈÁ‘ÙĞİ=_—8³Nà~§¤@ê°”"zûB‡à×zÌƒ©¿h›^­QG`Påi’ÅÄµ`ÈaáÕÇ:ê‡¥(w|,<e¸Ï¸ã–fWÅ‰õ—$l%nY0D&$SŞJ½©‚³.’ Û†ÑSærwa\ôqù´LŸ‡@î#±‰9‹$¦$ÍC˜38·k‰LÂäR¦OCt·¿tÆ¶>ß-‘Ä¦çs®Ôï”(ÊPò:^6k®ñ®M¿‘|@ß®6–5¢ş:[éoêSWÈÁ÷ËäO— ÿ¦2å³
ßJ~%«*…LsXß­”kÏ¶ …ÿØÚ¦ìnŒÛ[7VÑ°IÙ”H~‹>	ˆ•êG¥M#7íË;7ÌŒú¦øPÛ0&íŒl#3=Ü`7Äæø†“^.x£&ûøÃ:¿4FJgğDşìÅ’‚`õ<[×§(êëJÍ¾è`	5Õâóq†Ú¨Ãfèõà7éD±A»‰•8Ò¨4B½ñ¤Îâ'%H—ãŒ	p0™Ä#ˆ4„¶ÄrùÚ~m,ÃV¼?¿‹Gb´äÌx-bÂğ	”Ùìr—j%ÀváKÅX[!ùµŞ¤0s}¶°m£-¡ıQw¨ƒ¥Àv{D@˜è´ ÎÈJçZ˜†ËÜ“6[¬uÏÁ?»mA®¿}MnŒ®C¥¢õ¤Ù<ëítiª~½WjæD´òüš?aB|:7Úß¡enH_ì@üÇâ.C Ä±0¡¤ã¼:põ”¿†€¨n£wİÚä¸j/5ÚDòeU:·4åãLá¾MàPâÜ
†>JÊl¤tBÈArèO´`èH!³³ø¿yš¦˜lÔÚ0ÉrMV [)AI”aá`œ‡û†\¡rùYzd,C{öõhÆ„išõ?“V‚ÙÕw_d³©Øi?³zÁªÚsÙÚ ¾Fìµ[©¹ízƒ¶B8ƒxöÛO- Ë^‚Mó²œå]iÀ§LŠUã=”I3™B¯€à¦BsÁÕ
90ùC˜HCù‘2CŒÎç`ôº””ş÷«p×v©aWç!píş3I¨z²îéºRLŸ9ôBˆŞrè_Àµ^¢.*¢è0èÊËšÿ^k°wXï}B0h‹/høxA•Ë[Šê`Â÷'µß]lSXÖ@<³ôMw ‘Û÷¸i/Õ¾÷½})!”ZRà;«ë¯­¿œ ùiÛã™r1 Û–áŒ°A4LœDÍÜ^^8Å$©öi¸kRXcÁœŒÍ4É,’5µÏ¨Ôl/=X£¶böh{
báMŞ‹Ò—Â•î7šmH´İ›»rpX—º°Î×Áÿ©ØOÿüxålíQ['ıÖ(	ğ4„%#' ]m#TåeŒÀK~‹"¤ç_âÕ·ö˜§Êé0ğ÷TLš÷¢;ğ~BËpHïÚ	œÂØ°;ï]7›$ôæg±»ºÃ„t%)ÅçÚsÀ‰#JïGÜ_Rı $'NÆÖ¾ÈÓC®ñÎí@J¿ZuXÔö9„ÓîöMÚ?à¦‡ØeêH_>ëıœéÃò”~[Ö‚ Ùñ'±˜â>íQ&V°g"!COrıÖ–o@vN'…ªOum„œ†NÔ·‘Ã~ˆ'‰ëÍOE‚ Q°¯è’Çı²`gë_ëõûÏş9—D,Ñ=Î·ùÜ@‚=ê×ö@u\ èŸàåt(mK4¥Ñ:UZ0uÏŞI©×ê²ó6íÌßOt~G¬;‰îİ\¨o'©XµØ!GI;8“fîEd½«<¥•…İ)²o;ßÕm,w8øR’P)¶EelDe'õ’rá[äc°ö^JG$‚2tÿ.±¯”§rGÖ¾rBÛUz€””·\…mïSºV¶¬y{Ì;‚Èˆ¦/‰z&˜UbŸÁ‡LKy°!ÄÄá¯ë×Ÿrë=(ñĞFÓër‡ÄÖàöœd¢ñ«»ë—p¸M…ÈÃxàÿåÊ\_¤®·8ÎDÑ{âUÙu!ƒÃ‘ğÁ˜«yjA§ylàL=Vàb•Î'ûÍ ƒÿÅ¨š5¿5k†ôCakh<¡“EúFV­ÁT"ô‰h<ğŠ:›Áå^‹8ç‰WˆMşFlïQÇÜtŠä~`XjC;ŞrVu<å~S«I¯]¢ğïu½‡“Zİh¦gÜ“îº4R+ıcŠ²H¤0ğ«
¸…†*rÍ%a7îKQö¤¨Â9`®*ÂÆ×DoğÂ“ú3SİöQS7Óh‚
7v~ÖDˆ%ÊÄùX€5Ü”·f^nVÊkœó4ë÷¾B§vÈ~Ù^1İ§ß&W¯íĞYOü)áÄ	–Š55¿à wÕâ]5lzH¦‡0±(¤«QşÛzÚ5ı·4Ÿä FRWM[gÎyİ‚
ÕJÙe^šäQŒˆ…²Øm|ä#eäO:‘áW[Qö•=ÒŸ§ —éóº”:zcAå’¿#¯èõS”Pá¶Géôå™:„Üµòt„.¥”’g@¾ª•àHàÈæn2çs¿p ßıJ°3Iá‰ [úÖ¯òëàƒ-}†•êğÊÊ`fÆ¤Ü-g,ë"+-9~fvM7àº0óœK kÛ¢ÈÒpS©[SØZfÉxÑ²x¿úüíc¬¯Ş~‘O:S;Ï¥Ğî«„gUÂAr‚w+È°ØNOS¿dpŠÄ¼ŸéİŸx7ÿ¶¾œiŒ\o ~¬ñM?˜i.<DLeâ‹‹ñ“ŸïÌ_‰İ›Á¯‡Œë6‚˜è‹ûÀ{ÙóÀOÕ®
†Êİû
¹)£ª·P·ì+‡>¿Â“%:$¿©’í+ÒuÇ«Š%M!¹§8Cº/¨±À6D ^yè^u×ø%Fqì
ò±%ÑOÜÎÁvtFi@ú.¶0šõ•ÕŠs¢u{»:²Wø$ô'¹˜AqHºb?¡¦4Á5A•èò¤Êõò:ã5`É´ÙºxÍ2S&ÛÛÅŒ
;lm-~Tj]Vs)±Â92)Zj\v¯ıß‰úN'ÕŠ
{fóœ¸Ş©ú=˜Ëˆ F_S~˜œ©ö¤:~`1d`ÛT<Áî«ùNï½NÖ¢¿îâ‹¡mÃ*HÇÛ€¿‚oÇË|BUvÀje‡¥#xãËÄ‚ã¯¢VÊ@ğl­Ûı®Úîµó´§Ø#j9Ä×ßzsH2ê™Z4aˆ¬´`²¦´<">‹|×ë¡,¿ò¥ŸsÄA’Ïºö¥ÅÕ¡áMî.IÙÒîú„õEh¦„aùŒ¯¹™ÅõÍ1¯Û¿'9ıµÅæ™ç€ ÖÈ¬âÙ?Kº(¹2(tN:–\ñ9PV94wÿŠB1bÿŒØQ"çñ®j¾zi‹®ò¥™e[¡!ÕñÇU_.ğ9nWÌ'xä#·¥_ãñÙè]ºC«Ğ”Åƒ%º‹l½QR¸TF(•¥°EªÄë,äë€£ª"›÷Q1ğº_	—¤×â—zßõd~Í¥#‚.}M¯É=’Ì‡£#÷ú“X¡{r‡·~¡‘Òî.İWÔV!¼£¨€&M»ùoa|ÔÊ,±0Cã›o+«okéeT,@”&çˆ™LØLø½A.ÓOı15 jñ•äN¤¤¡ü6-SYÖÛmq<¯E×GA-9 ÷lwr)Àš–‚d…JLU|”'…6ÛîaŸFN3øfòË5»!Øé¨A*™°xÉÄß:×"hb °öj­øz@Øe
KÕœˆšP8)»Éc0ï
Ä¦|Ç±DãAãˆòà7$aJÿeÚyŠ/5²£DFüÀ}{³™<ãåvÃœxŠvÀrì$ª	_ZuzF$êGK´»trH$·‰7´D]ù;2]úURš±A³¬kPİræØ”‚L¸öóÙ#¤oY]­+
Sâ ÊUOo}'V˜ï0à½zÉEï{Sİi=YEn«+É!æîŸ/èğŞâõØ¢¨Ù™¶˜äXA‚«zº'M~×¨ã€è.ıxyïiÚ©J´è£’$ñÒ'íûª$Ì7–ø2f1û«ÂÒRfÇ=FöKÙ=u?Y¢„¹[ŒXš¨;ËØW=KmÏÍ™CÂ+Á({ÂĞn
’BÑÍswÕ¾CÉmÃéÂ„Aîıã“2 z+Œ>õKWÚÿ}iï[J_{GÏÛP?ÑÇåBc<Y ›é×%DõµÍàYAi¹Ğ.õ	¾l|/tuĞ¡2õÒ¯RüÆnd‹’0…šÿ-ËJ=§˜¥½åº÷•ÊòÇ3bç‹ñéåƒ|„ïëzlG´…Øs/†a¿xÛ0ÎØe¯Îà*IôØ+Òƒ=²¤›ùöRË©
?ˆÎáİ'ô¡YfÀ~ì§g\…/¡Ò4bƒËS*Mó¶®©8ƒ®•¸–A½æOıW¦İ¯ŠË³Z•ZÜÕ÷R¤&t»‘İÚÛ©2’@U“•dÏG0ç:yv“Eäty@ÇôŠwd¹û˜ì(¢Ø6pÖ.]¿µdµ´†r8Ò¨†ÿí;Ëç<öi„$2#Zİ¿gj^››Uşÿï·×áıNí÷0’·¦)–£D©Êú4-îäLASE¢Á¿÷gwÃ“×wá'Ûë™´7n­mªæV@ĞÈ„´îÄE§¹>PÉqe
Ği)-‘á}a]Q‡B&I£Œ-¿–û¸åÜDNBl²|ÑıŒt/“¼%hØb…d¥şè§ATz,få–!Ü¨/(˜KWO°–x±’©Èúo¿dEó2gÆŒÎ|÷’ˆlŒ±‹¹l*Ç’ß­çVdh8¹ãîåÍÊ*Ò4£`š6§¬z<æ;éê‹*2eElw>J[˜Skı|•9I0ÓŸ–\K•næ#TOÈ9IG]-OË÷šZ¤óÔ2‘ähŸ¿WúÎîƒ…ûºTö˜&±F!wm6ÓÆyä™uê)éò.š"(v¬ĞVéïk2à²ˆëÄ+s…ê2hHš9¾¤ï'wÌwçÌ«‡§–'•²j¥SU0ûêîMÈ,üò÷tBƒga•®ˆ¤·Şxp~§E<¶—Ö{5`!ÿCácï¢Ã¬£ÔÅë0†øÌ9QÙ²;I/«ç³‰*n‚§@—°^%~kòRÑÔ¬^yŠ$Ú‚!oâèérj!NİºÍ |ìàÒÎd¶^|Ñ|åeÕWÕzïŠ=uå»Ğß®)fÈp|/5¿‚éN†¤NVÀq`Péå˜õ¿úNú÷s—ŠæpKÿÁNämÁg—ê²nÈkıYÌ‰•›ËZó&4`Z]_ëß‘Å‚‡TšéN®h30¡çûRTâÕ¸Ä~eÂÇ"ÀĞçœı•9‚v
§­ !Ã³_r™µZ;ˆ¼XÛò,CÀ¸:½T™6îˆ, ğeJa(dÁÿåV3ø¨fÆáMò}~¾uÆÔ'lĞWÔÓ0ÔğÊUïTg´¡*;‡Bãî~›{	sÚ™°|ÛT;ÕõÄÊ êe¯›ÎF˜vû$×õæ™‹YåØ» &Ó—'kïõ¶vÌ,{l¡Ÿ¨%×ì²İò	Oñ‚ÛûÊÂÆJø²âAl$ùŠN‡Åy–•":†áÌÖT²š¸Õ“¨—@°Š"£‡ÏÑ0t£5&}T7İ¬À+ª››ê÷û¶ös|…6'£oKßiÈì{?lGK"k‘ˆZP8í¬˜éñA*­8ƒrğíg+ŸûoÕªë$òµS¸È—têî*0a„jÍ¸ ‰œETÖoV[}·@ÕãR^æ74ŒOÑÜİ®¤ô·"=ÕÑ‚É¥ÇY™½êÙs‡Î#Hı*Ù`iİïĞy»®ÕN?ÍÆIvr%„e&Y[ı‹äÔay 7øË²Áœô·W2üp²ü›õãQmêÊÍ£P=(ÑZéb@Bws_ÖGf`•gc(‰NÙäz²Ho&•îåÚóKEºÃÌ˜…Î–h |K„^=ºÛØÍ 2SÖnÃ«^Ô'VWf1~Î˜wlZm¾Œ³D QÈk9†ş„°	 [bÇãqLã €I>z™Kö+¦·qÀ!¦V–®Hé™²Ø¿òc®}>°ÙO3ÏÓU."ú<h ç1TÚ<´Ì.ˆM•F• Ëî˜º[êo«bÎÎ:ÙP £ê%ˆzq¡Gr¶‡3¶Jô„NâÊìy°:Ù€z÷(é1Ùıˆ/;y¡14:°­8Z£>\
¤F”šc‰ZkØ	~Í­+ƒC,jàs†¸¿ãeÊìÖ¸İ1?òÔÚ1/’d– Béİü¥±¯ÌIë¥ p_—›‡vøöå¤ìÃ˜›üNÊ€m0’S$Ô©¥âÿV¼îÀÑò2Ó€T³lLSş)(º°ğì­„Ü–İOÀ3nóôrb_|l¥X(ßGìe§İ öì«zÖ>›Öš³±—ã…¼@•€Ë«+6…£í0¾Î*üUX'GCØ ~õLsè·J$ãáâûzÄ¶ıÛAúfX–vUƒ¿ÁWŸo6*:’zYox9éÑËØ>š3Ò•@”@¹(Y™~1S€YÁŞ¢Mğ×Úá)ÍWC©#ŸXµò{ÕºR_“YiyÖCÿo
äL7'Ğ„šr¼à2T¢zxlÕB¿j€Ï½Li1d-UZ5.Ô±±–MV¥ºƒŒñ£œxjÄ…"š-‘÷|Ê«)U Ì3lÉ"Y¿ù¶;»»cFÒ÷Ë&êeŸÿbÏ-tL+Ã¼ Ÿ§]y½ã)î
”ü~KvÛ|}-:A$.e7ô3Y¥™é±Òÿ“ÄÓKÆn®eƒ‹¹›Û@ëºÊÀRÂ½ó12¼³Æ’Ìl‚yYÊ^ŸÎ^6m]¢ÙAB­GäUÃ?A·”53šy¦ëfN#É_Õš¤0oAº‰XâèÓ…Øòõc{ğúÅ‹«È¼"Z-ûÿÂ¡äHvê/)¿Ê¥0¯Éî@ ¬íI“_DíS¬p†[k‘|„gñÿ@ŒGË£nYk,n(ëo\+ÓĞ1[fâªDô³Nıê¯z²•­z—4³x-§ÉcFX]aø>eùa«º>òUöµt½9$y~¡É'´Uy› ß¯y½Á8Hz%‰£1|Œæp/§ÿû4èuöyyD’…¥D½OæŞxw­P+­?ˆÉå”ü'JòX;M+¸5ËæÍ/3ÇY5sÈ\	cMæ§E_›æ ƒ9“Xw4âsà?ë è ØŞ¿»l'¨F3Ø3»øo*{+awã	(Qæ‰ÕÕMŒ»1Ÿ¯İ	ÎŞ¦V&ôgiÎ*³½b'ŞUÇeE*¹öünÀ‹Hoö_àe’ã‘M“‚Ù6ºWd4ÛÄ:UœA„ùª9q2d<5V{¹^*Ï_èÊŒhmıÿ¾3¯¶¼UA8;Wù~)kÛ¬¿‡0=^‘ç’2ÿmÿ]¦LÍÃ©6œËuœŠ/£¿r¿s]‘6«ÌÌ¹¿šƒ˜Ùé¼3ÓøE·?KÊˆş^aÛ¼9Æ\8Ççà¬~üaQŞÊğ®Fy‹İõ+$÷ÜÙ+P¯Á˜ĞÃùóÑ®¯öy¼SGe+ì¾K‰Œ¡Y"„tmK›s{İy¿_p7&¯@@8o»Y¾xA'›DuCQÑTÕV¡Û×|´ôVßù2±„¼nÿ“â«OzGÙ²;<}¶‚T4ÒÛà™¢'X®HxuÒïs¹©à¢Âñù°ÛGW.‚²Ñ5(¯ewnŒÂ§•9Æ8­càğáMkD5!e\g)gş£Zñd3ˆòãÉ)`À†ªDı\ğtF¨6ö~DÒm'4#<¥ÉèOÆ-wû¾AUÖÙÂ¹ˆcl™7”ó—°İmF‘vúgÖÙvyP±ö¦Ù’	Ú91ÊíÎè»}‘óøgToƒ¨F¥mœhÀx¡6R+Iî\üYªªIb;møË‡÷3I`(`i<N=<€Ú]ìæ<Ñçm9'îáåsÈQ÷ü~:şÅwëÍ»…s¿à×ÌN…@‘Ö«¹r¸'H,2KY¬†ÛaË„°ƒdBsÍ?İÌÒÑÖ½˜×—a“f6T8ÍĞ§şp”:!É‰‚†ìãñì9 2U8t”ù—WM÷AJéèÁªÓªgLX}ÈvàGví2¡À÷âIÇ²Ñ@üG¯ıÜbJ74½GŞÅTàVûí,‹Bö˜/Z.Â>ôÉ‘—¿™«p¤Æû‰Z§‡-&Iñ(N¬˜Û»Õ[µNómˆçoå]+ñdyÄş¥Æ#ë·3–§”Rz£W¯'ß 6GüHD"¡„ŞºzB„Ylü Z2Í¬7v<pêbÉ¯i’½Æ¾Œ+	Ió8……púk¤æíi†£…~œ;¾«”ã@¨DßjI.œÄçR¡çãà¢=ÃBÅIX_õæ°ñG~$)–1˜’JM(döã]ñ>- ¾Ú»}¼ÚyV~€%uF£ºÄ­.3oTwSßÛÄ—Úm|³†%Öìñ’~A±’b LHhKİİ¡l¤¡µšbIßQfÙå+4Íş˜RšíDÊ¹½í°a3áHm(.ßB4¢ê™ïÂ÷³åÇãórŒÖ9]bJf)òøÆ«’
·h)Eaóß³•´ì+´C!Ò#­¥Òıï æÄª$²S°£Ê@¾ìB!a-NÔÙÑp\ømÂ^ğ"ÜÅ#Å•F„àš½<?Ã‹a ôkâĞĞê¶ôys! çÈYíÍèm©„’¥Î¼“ğygÑ¤—²Ô.#ú’Ö-Ûq{¿K¨+Ø>Ë’®ĞßèlÜodB°ò`¿€ağêºÉ‡Â¼jæ™3¡â”ä+7ŒB©h5¾‚WK¸w©/«4ÀRzDë¨8$ÀéÂz,Ì²š¹m
ù™&ø™•ü×yÁCYİEvâÈ ^v¬¡4DãÓÜknÙnÔK™PëØäÿÌ§+FªŒi¿n½U_å‰%úQU÷ŠĞí›Ub`mÿ¸$ˆbS3,‰¦¬cEãO·}®Şg—(¸vP<F@¨|ş·v†Òà‹]#“UFÕz‚`ÄGD•›4²ƒì-â 	Mƒ(I¨›¶&ËêLD5E>[€|´!Ò$¦¢"-³AI ×{:’f«*ã?¦¡Ù¡ÃÉKOÖxÃû<Xa%¾rÖ	
 ª±ôhP7O’)…É-ÜVar›ËtbÆ4áôÛ"=ÚÈLÏõ°¢Şw¸ì²"yn”m–„ÀF³ŒG~€¦xÏP”³'sy®‚¸GE>Ö“¾wÊäÄ\útÎÆ—¯Öú1Dw§O;ÚëyÁN!İ,Ë#9Ñ¯ù5Jj¤I4°ˆ%x‡ùDg$Œ©Ù­^ûİ¹¨fcõ¦0Wè©(^¦¶­+²ÿs),‰—äBZ;tWzÇ0ÜûÙ_óÌ£:wÚçyz«»ÆçJ™×F–y‡OP}ëZ×†jÓB1Wzš¦Kğ=6—ÌšD‰º[&tH,‰=;‚ÃôUÇ@rDñÄU_twŠ0ñ­“>’Ø…„E¨¯°ÿ}ê„—õúèVO-!?8b©/l_
	–jL’ì`Ù9îŒÀ÷u©-Wÿtqğ0
PN½X“º!\É?6şvi#Œ y¹Á5WàC›’¬·ßíJm˜˜¤Gİ¦VÎ0ëËå¸µV±W‰ıaêŸWC_ÕÑµ)Jß);°¼|Î8ˆË¥Q]ü§ €˜2IjbÒr¯I¯Ê]ë§×~§CØ`<2¨ïCõÄ±™@ElŒøy:I“x¨Ë¬Õ+   ´{M CCj4:w~Êsqá`€¥‡«›¹višzAÁnKcpôjUœã÷	Ã>šfÄL‰¸BdT®»3ğ²IEzK×Kwô“
©˜á|a
ÿ äá‘çÕt5sqëÂ)Z”÷ŞÅıE'øŞĞ?E6!u…Øm"B»“Y·-Şh²dV?bÁzR¬4ÔÃ"ÔdÛYxÎ´ò¹	â÷µï•roP¡Í¾£én±¾‚à|ğÚå-ÏØbPÿ:Uˆ^-¶§óëE:SƒYÿh*´¹Cb—.âËÀŸ'ƒTÛŒ©ëˆËÁÚwj›X¡Oˆá½PHZAÂ:ğ¸³Uds¯:M”Ìsz#0>6ÔZƒL 'Ó	€0œµ_²Œh½HıtñÂ¤ÿHÏŠñÓ B\í&ÕPxÿP¸Í ¦ÿvÇ‹šŠÆ¦¶Œ†»şírÈÉ–QöÍõÛÌ“ìtÄ&‹L)ë7Ãş»Kô­d¾·§v/ç2_TÑ‘{ØâÚçº"eU…*%È©UÁlñÉM3¿C‡Ì?oIFˆ~8İMüÉã8bE¤ `³Şª.[[Òªâ)ĞË6™-3_€6é;«yfUÊVuNü6ù÷¥Fõq&Šó“ÅTbğk(Mt]™@oùPºÅI;åÓûSZÒ;®Ş2şeËµ4•r1‘—Í¨BÜ­¦Ù¶ Ëµæ¡m¡ü¦D&wıÏs¦XM°S2©ÿô¯r“;>`İ}Bì:Ò±òrşW6À¯ä”‚	´_Us’¸G½Ì†/=on†½>’Ø×yÛ½¨ÆÏŞŒM£M­,Î^8	sf‡eªÚhÆ{X‚šœv‹ƒİ¬òõ ­¦óÛªÚıh¦¼î}'X5Öì;çª¬É{q„ÊÃl·Iç6BrŞ#ò¡¤qkzìÚVßDH'B¡ñ©|÷,m'mu„Ú#r¤¦|„Oé……,Œ&ü8µù•L°Bcà„+tíÍ(±¤£Ö:´r"È8ÆÏ2Ë©‡FŞ°wçŞÕÃwÏã–>•ç-ÿÜtõÜÎ:q­¾µUs]¼U¦•[ˆôÒb‚”~Æf”˜úH´I|«fò¦şşïÒ8PAFáë2½ëgô¨}âÜ5ç§‚Õº…"¨µÇÁİÅ(f¨å.È%ÿùt@ñíQ_”ÃAæVF<Ìßú9óLU6ªüunJ&_Á)ªù)45?B%ïš×¢·V¼g¢hÑö:°D£E@,
ìfø“§ÛÛ‡,Ü?‹z“%»H?å¸¥æÉÌºP&º! øXÒÎ/]">äw<³¯Ù÷ ê“n‡ÑsƒDZøZ­Ñ,…±cr‹~’B…^¬7N*=ƒlrDeÓìã”KaQsû×=„ìT¦%ôp|i¢hP`Œ¾Ô`ëH’ù+3nv´H«†ÂTs|XÙû„·è2YãŸÈ)@_5r³ã´ÓhJ^d.ÔÍÖê­±2wH0®şk]Õô'KPîoJƒùüo«a<Çyáš1Ü‘»¼êEÑÖÏÚpMË"4Ç×[q?Ê÷@<"úæù®l©»ĞÈMûfİåSiVö\8tÓp˜î9Épİú÷±†úÛúÂ?šÅõøR°åÎ;›Rß&bq¾¤‹b“XJÏ¨«=‚9T•®IjãKúÏZ•¡ …íàƒ‚˜¬ ãT3ˆÛÏ2¾®Ó“Nös»Ë‹v“ã¹Q\’vü,zÌ²pI¸1Ü#SÅ5ôK¡zkÈ+úÃB
ê¬C}M~Dì‹ô¸x"V¥aYˆ9ï×ìP`ÔÔ–&‹ÿ>ÊÀ0=ûÛgô´@¼MWÃ™”–uÎôşÈ!l'ÛòÇúı]òl%PMÜş½Ø53W["×ÄE¼-Ùo÷ŒCç¼ô¬Š¨g±<Ğ—ş>åìĞÌöÇâÇgŠ ûp(Œ:Úh-ù\ù©ÈlF&aäFìùçëì£{Ql“Åªİ'Vû¡7¯LfY9¤ĞúM/§H‚âÉê}ÄãŸáÖÎÅ®î8œİ,d‰	z`?XvÏÍ8EÊU±„ÏŞtAÈ+³k×ÉéÍ•< C2ÜH¨!§w¹r×mßkªMZoÄÚ,€RÔKS‘´z<ÒÈø7@RØîÍZ­İƒ ±~¥àNıx8”ËÀ¡ïŞu=6Î†h4L0•¾Ó”^»×ÜÆÌ  ÃòhãeŠ iT-ŞğGÖg~)S©÷Xõ²	pş¿šçç£nb"$-­]x)±Ş¯kx%!‚Ûp•²ÂÊÁ}ÿ¡p­´2ñ
¢]ˆ+j&â{bg©İ•Èjw¶(ñUº4¯Ám,bï,ËóâıËsoEØ¥–ğ>â~+ú%Ã{œô„x–;ø/qqXg&ÒğÓíœÀÔ5Ú_ö­±ø£Â!¦Æßôt›—ÿ½y¡wD—ÄùIû­ïö.P…–?Û7s@2Å©+îk6ù¿¸æïúì^øJ¢3ÅÈ`¤,×
’]8†ù¤ë%ÄY¼"®wWœ@‹áWì»ú…ë)òôŞŒş‹PÎï Xï|En™Ğ(€ªL?:ïõšUUƒâDÈû^´Äª{°)ElJz^ÎÎJ0áŞXùt‹è k20¬P)¤›VCØ‹YÜ*ÈšÌ“BšÔ›oü¬‘03¬å:ÓÀ);1ÂzÚWíÏğZÅéaZÔÌãÅ}¨è_êqûh¾¤©Ô(?ğLi3ÕüL)^œÚ%¿\¥¿0màı;ìa+q¶³ÔÍïC;º?˜óK2ÙG´-¹oXeªN›`Cä@íèC#nV"…lÿ;0ç7å9(¨Ìß¡iï£ÖúãOöMÑÖl¼7Xæ È+kŞG^ËÁûøìE/L€qúâä\˜£I”ÇàDú~Ğ¢ï™rê©“…1¤ğô73z%ä\Ñi&ÑX–¹G{¢¯¯ğ®Ü@U¼»1R5ß^®ü€'ßx¯›ŸnIIÓ?XFÇ ÛÌšØï(ğùõ©SE:¢Işà×@ğ9ö¢l\ïÙşQÔ¿8.ÚËÑbˆµßêWÔšêÎì³ÓE*¯öUµØÂ¥–AóÕø‚4ş:ßQÿt·]cÉRyµCĞhÌíĞáÛ!–úá€dç!ØqY™‹ ğŸ)Á„ÔjºIÅl[­‘}uÆstŠÖ×QYÄÃ<±Ç´#²ë7&äÚ¦ÎÉt2¡—´ú¼ä%-Ct¯˜¶Ó=pˆ‹’»•ó§éÆá.à'¬ej“-‹ê×ãÇ‘Œ‘n´2†lÙŒùæÿİº*å Iÿ&963¤>Q2¹8‰ÏŞØ®Mu<™CMÆŒYÛ¦â¸Ğ±EÉH¤·c½!¾DİèDd¸äQsâOŠD|°•®÷ß/‹ÊdªVn §Q;áò¾ó«‰h»ûÙïK2kœ´	q–_Xbõ`…mÏQÈl<WÂµ\^°ø²¨[°h—‘F¸êsëN1YÛıŠ¼‘õÓĞI/ê†I£'ÿ+ƒ±!ÚRR¼Ü¡«„6²)™Mµ/ì~-rµèòÛğ
‚HŸ€#ªb\iü“‡çË«Gm}rßXu˜[c?ø4'â‰|?ÂJ6•†¼ìC›KÛbğØáşñô•if2bàN)EmÃ±œ†e}£Ä4lÆÿ7(bØÊò·`½–l>2øÒå[°Ÿfn;^lÎ˜‡ËÊW8rS‚lÇY”©Å|œ¬ƒÛ$t= Jxcc'j½ût*a˜ÈìŞ}(á²d„çk.ÂúD}¯ËO?_­eu‰]·®ÏÖ9ô›ø`£ÃfSE·–´ÆâÄKÅUew"ÉW’y{øñ©n#ë4G5Ÿá	_5ìY	îğ1ñkßEæ–Aë`hèÓÂê²e;'38?ZàÌOhLWDaêıK&ÎÓB!]‘Äš¼Ú£’vO`ÓşüW©Slµ3G]J{ÓºGp 3¡ÑL@Îø_Ä\ŒØ5y06‚¿èqÍÀtö ¤Š^F¼QØéÄ6ÏŠ†jÕÊ¡Ï®“‡z ]kcpÄõÄ¹Mš+f™EŠ*«Mö(á‚M„Ûı(™)e:Ÿ²|ì®}öŒ2.fÿï¥–1'ªŠ_rÕ,Hgôû*R`Pã=i¿c0èû›®›êÆh¼“Àµt
»™É4¾‹Â(–¿úÈ•±êpÙ¨3qmà‚s2àOUÔ,k9a©°§¢t–İÿa,t+10‘láü[’Çÿ½n¦õckâO¦Îœ|‘óÔÂŒ‡Â$§÷y€Â¼p1_2¹Y!§û¥ŸkˆJq¬ÉK¾1ÓçHËº¬RvBøVìéCïÌX·CÙ½P©’Õö™|’!Õ(÷x3~ñf02x‰ÈÍ¤‹ÿÆ~6çÂd1)o¨Úå^Zõ:®:®.@BøNÁê%ÄN#„nfÌßºƒèÊÈ<b‘tŒÁj“¥vzÅ´»¹4Rİ´H’¬à°`}MZQg•ñ+—5L—’8 gšd\İU–_şŒ–f¼Ì>Ùñ#˜Ã’ÑŒ§û¬Lu–x%ÅSLÂDŸ[mSI´YòP³ql´²+Ÿ6}ñpnlkß†İ`¡'0>êÙä¯E¬Ö»ëHYè(‰üÛ»#‘Â»+¤}l¶×p¬šBş 'Ïiv?‚+–£¦Í§83s1™bT“e–NL{)0ô<¨ÍÚ=Œ5ŸkÙ¸)
eÂqy†ˆ¥RCexy¸5 Ègî)Kym@zûÜRÅÑ1iãxGàÛ](“T€Y-'³ ©bº¤GùT¹T–òveWú“bÅM}É7®t×ÆBZ6ü— 	Áèşü´1^JÀÛ£NzÅI˜„ËÔV[0Ä!] }”.t[÷PöÊ¯~y8ĞDŒígKaíÚˆäã,·ä%Ğ	â,B%@œãé<–Ñd|ƒ¸¯‹ßåÑmj(ˆüêv Ú¸ê‰­Å{`¶œœ‰!×šqÿp6˜ôÂ°äkNøl¦ÎÀ0“CS2A	a….ú#…6úÓÀü¥4‘ƒØ‰’×›Ä™‡7c1l¶4…&œU]ƒÛ‚zmŠ•Õ¹¤’õU‹ø(ùÊ|ÙÒ9Ü œ…›É®ğßy÷ÿsyb‹ Û£6IâzQkK2ú5ñ³íwaR1­°^ÚâšŒbÚ½S;ğªØ¨¼‹;w1f£À×³ßµt«@ˆIZ÷ àNC;áKwq«ÖôÎfq|ÁP{ëªøpF²o³“cŞk•’{ãhIş=€Ï"Å¦æ¡gÀÈ ¾]‰o,€¦3^8k½AŒñÑCƒÆ4Ÿl.ÛñÔtFgJ]BÆ~ööˆ„FU¸³ÁKAñ!Ù´ ÿW ^OÃá¦íµÌèÛ€ôûBTXÆˆ-àˆ‰¦2®ÒsXŸ-ÏßfÁ’"SÓı¢s‰ÌO…æprQËop×Ö»f9U°Á¹û$,5u•Ç9ÓÅäbïä°‹ÕÛEPŞëÔYUÌjÓ{{ÈòWJu4EüñtÉî?S
i*>şJ1j.Âáã&†rb×R¯FhÃg?)åË¹äî$%Š¦ß
‹^8¨Vİkl%0¢ˆ-ˆp«ÒAïñÙktuK1î‘îs .\Ÿ^ËğGÍêR@Ó;í31ïê	¢)^dıàíÈÜçëQü¢LĞßÅşTôPï;­)®÷?ˆ+³¶‹rÃ‡	³Gß4CÿÕy~û¢a?PlUÁ«zÛä~ÔÊ+ÚL[¨‚ …˜I ¾J*af¤¤Vÿ4‘õƒ`ÌH²jøÕ7†õbFÿpßÛ’ŠŒö,CŞá(kp½H/?ûôÃÑrd”X7=D»´†RÛ¶EÈ;‚8\†¦B»•}ÆAë®Œ³Gì¢³ì0wK+·e’ıJ·4FŒˆ‡Ä0ÀŠ¢>†^u9ûóÅ'Sˆ4wŞUšBã\¹Š'gg9L¨Jj!9©ãôÍÌ¡g×œ/Ùç¢òíìêd‚€Õ[V-YÇUIîGô›Û›ù|-3e5`N¸n À<Î€ü¢@cößmÍ”Ùyˆp3ş:Á`ĞgG´ÉˆyÉàu•ÿO>J)ÚVn7wö¬¯ƒ&¦Gä«?+ ‰DuEfy€.]9GPkİƒNãN]PÄä?,BãÛ¬áa{çv‹\i9_ÍiVˆVY'¶™²/´œ?(CAL:^}$<ÀPÁ_÷r0"¨£Ågq2ÇĞÔÅ£o
‘J*X™ÔC9ŞÉ˜‰K“íP¯ŠŸ‘]Ş
ä–À¼D“:‰a$.š»:Wm—Ks#¢½^‡³—!E,ŞÕÜëX^ÁãÆã}³ì%³ÛD‘ÚsÁF¹²ôºMY¯E/Llkï©^àTÅp.Ib%’EÿÆªêò»ı×•÷4»(vlÈ)U¸Õü”–“ØÇ‰ƒ†høTT§d÷àÓÕ¥¨îÉÃ_àÀ,À9š4Ú•/½¡ê"•–öÍæ—DF*!ŞKæ.âîLL!;3·+QQJqÕ}ßòè¬µæØì™$ª€®Ó²D[-wÂ\ÈU*WİøWĞCs˜$•|ê¡°.ı„Ú¨/4<4ËÑÁmé«ê6}2nCï$Ëpÿ~	¼7sZ#ñr»‰^ŒW!Ê ‹z–a$ı18 NÜÛú?jzÜ¯Gsñ3İS§‘Şx”Ú 4aT€m÷MÙ¹ÊªD±ïÂÅ40+O{ó›äçå6'SªZÉÑã‘ôNEâÉZg?ñ·Çfè­·À·×|^-ïÕ*&§¸„H]à«İ †Ì]"FS†DQ1È-Ü÷2¿™Ua·è)yÙ±U±>èĞa3vÅÍƒ‡Uö›ùÍ¯Üòvİ3y5À2­üŸY|qı<™sñ–F1£/‘ä“—Jeéª£ pôÊAFÚŞ˜›Ìo¿OØ;«¾Fe]ÔípMüj¶U…ÀòÚB–X@—5‰¨t[²šƒYEœb÷õ†¹C¼è½M”„øß¤¨;2™ñÄ´s`ßxù@úÉëHŠt“èGe¦p§UwP§ŠærÛ¤ké,Øù1‘?E#Kòº‹E¿®èwåªr†ëÉt'\|—Qh°<¼IœÈßƒèÁZèƒ§ôïZ<o2Ô¼õf÷pQêÔ°óïád1¬ÜeˆÅšD ?•iêâ®¬†©\{ : >&ôô&:´{è¬^*ÑûL»şá¥	Ä(³¯ö{'Üªæg¤öy‹¦QõĞé¹O‚°
,ÿ	xv1Ã9=ó<ŞØùG	¾SŸÚ}æ‚Ü:¯Z8Ø‘u÷ŸQ& éàıAõ&®Ú¥WìÜ¯Z½túå5Ó­{A­%L¸‘¥“F¬ß%{Oßã˜3òIèp —¶“{ü_¢oÂÅ™crb})UYS¶ˆâVO¦ï“àY¶Ê†Çã×wbCî½x#Ÿ/ÔUã¯ØÑµ'0=„”ÂGùxCãzÙ×3ÈÜ8N)ÑlïÜñ]¬C½2"÷œf®âJ™G‘æ+hug
²¼,__kğFÓö‹«€¿¹3ÑØĞ°)½ÌC¨nÎ ¡t×şã…Lo©æë°l´M9XÕÇô´5Éìÿ•„Ú²a#}ÜAc¥Ãöå«Q´ãÌh4Şêº€ÑœëO½ç«¥ÑÉiç*Ó¶mùŸÈ¸œìâÉõæ¸°\ÿ‡NºğæÎ˜³º:Ï®8Ö/íÅ/h©÷ì&!³›õs—ÛÔ´á.Y¢#}	•ZyT’÷ÿ8ùJ€?‘4ºø5dĞñsà°“úø6KÀW,âv"ÿ	oEHjsÂGØˆ¼“˜J\PìÇ—ìÄAú²ÀnÇu@Ø—]ßOAEE¿³ÈQPßşòe8n
„L¸rcÉÌ¦ÂPÒ½í<»5&4M›6İ^‡|yJ² 2ãw®vBƒKúİëÛA+œ¬…¶»Ö,ô%·¯÷co2[&¯;‰‚(Ø¼×§S_½uö£Q¦ "[!bºâ¾æ„İê…ĞîˆLRË¹­OuËnºÛ@f;¢Ã÷°ï.õ­	uH[Õ†Ä `üÖ%Ü¾ÈA‚—ßÆºä
ÛÆOÒõmK’º÷	¨Ş²§–ş;{gƒ]©òö¿jÓ¦j¼e=°L©÷¨+Më)§l¡@Bö^3®»6×G)qê‰~úÊp¥ÅLk¼úÚÀpÛãzÁ ¡(}D¢àÅe¸ğX½¨‘|[vlªh&[c£¥SÅh 9÷1\I6›şõÊ0B£CgÃQÚï0h*<…ªI"gÒz
ÌS‡ïŒáVm ª4nlëÅÎÎ®:Ğúsn#¨
—„
w¥³Df°H“R¼¢’&'œÓ#}inx„£8Qnt†³óXÏ¼CUxDáîÀ>
)¥ÇjöÒÏc}gÄİ6¶—Pw[ÍTb$j†oeƒQŞŞ°¸{ZºÀ_#ÃĞ]ôÀ{q,¢PÃ¨tSbÚüa8kŠ€ôÑ·åÜ1{ß+Æ–=f‘£.£q«*Ì%¤ïÀ˜gh»ÕHËóŸr\/3Â†ğ’¦6‘­¥$Š?:JM~{ŒNn'
”5íûM­¤›…Úü¦›zÃ7ApãùqÓ&Éë3šMe·§D~PL‚–É¥¾O®ï@Ì/° AkœÔÙÆÅ·³MOà#q.º¡kÀ\@vïfb,æÛ5X¨–gÁ†{NToJÂ~„A”½¢€Ør 'nåáğä:®Ğ+Ú«İ6°K1ª‡7²wŠh NÿM?‹Axm¼{RÕÖëµíÍÑNo¹ÿÅ]¨*Ş­ï DÄİÏè½7 O*”FzOuzŞIìKéº–Æ¡¾ jIÅØÌ*¬çíĞêp†pxìt÷E%ª± iÀ…I°Ì®İ›7ÊŒ"ÁS<.€2$^¾ñ?¨fÒ¢hòïİãóÄ5#hk7Ír¹SÕÊAÒ–9âSò äVÔV¶Pî.*0%@}c»%%×ß§İâo±ÅZ$<YÆÌ7q–nOÆÓ8@¢¨I{‘G°`ğ_TÚæã®2J‹d;ÃL©QŒÚj¹Å"B‘Õ''HèeÖ*„YïÇD€qBÆİx’õ¦ß£pMŠ68'ØÉëD’®=>[G:áß¾^°VÑPÔ5¡¥Oç€İ:n!¹Á-=û@'º}aÏu:¼qüm$Í2y ¥p6.X?aöV$‰0BQ/%,L©TÊ°ºc¸S @™À°
]Êf uà÷¶1ä&ÇP£élâCKàVb¤fö,Š®,Kñ€Yõnéªoówdòˆ…Ï©º­ùU pÒ+4#½Ò€ÊÃ¿ŠŞêtÑØ–›Ú ³RÛÆ¶`û	ÿÒÊO8q§	ÙdÆü¥C ™ƒ”ÁÜòkÜi‰¶ÒW®`ˆ‚³}ü¸õv”È.o¢vkEE2Ö«7
.E,‘šŠ«£ò=JÜXµ$«ów¦vÁüâÜ“ÛÄäH™Şºo²Î$PVO}|7À+Øø¶úªÕ‰7gL0V:2¤ÔdsrÁA-0Nl9NÉâøÇlµ{uU|Ìy‹²²
1eq	–;æßI²®ïòZjŞoÅƒ¥4-’–¯ÛúT Gâê&.v@{ÿp0Ëuî»øè~‘.·nÆ})†¯¦qgëmL®	0uğ9ç¯;F«‰ÖÁ¨7íCxTb¡#ÙøY–@bpN é}!ø0mû]Š#/¤ÂàªOúËŠ‹”3_?P²SaD®7ÙWÆádº»ÉÈùc÷ú¬OÊ!ÕFÌ;®Eº‰ÿÔ‰][–Ì e€nÜÌ²®·¾&n4Æ£¨çÃFµ’¨‚ÏÅÁ©ÑŒcäQéJ‡4äûØ¹W€T–æî?qñmTUáU%+‡µ¼0¶·zå®áî® æ‰C‡ÄÅ$ª,¶+B°¨¤¡5.[×aT4CIëôˆÚ°æ/İÈy)“e¸@Áé'¶¿Z[ùÿ´·l$È1LeM¯æ3¿ÆJÒ¯‰ã‡Öû×µ$àìd›ädı ÕÆ+è¶–]¤nS«mÌCkÛ8
×—®eºmP®ş#q4Úh+Zc[-Û fŠ“Ãº;ÇÃVƒüò#IÄÏı"hĞœˆ_§¾”`Æ€k‡ã…~ıùÏ©¯~.7ZÈ	¤Ù2Aõ˜û˜²³½‘0ÌÎìÕ÷¢!Ç´øúÛ»‘Z`8«-Šµ¡bÅu9ŒĞ¬œs;A~&Ïö¬Ÿ¼UKTiÄ×ŞW:1®t6×}i»Ìlß„_4òó‚i5­)Ë»¬¼¦ R~™©#Ã_mÕWĞÇËç#„{ˆÊ‰Øn'3éÿûj(ªÓó„
w›Õa6,³ü5w:VœÆ«ı7›%IÚ÷bî$¬õŞ!×'—ä¨,{¨¨–fAfÏÛû‘Ùa¯8¾\>trzªó¥¼İõtZ]Ô÷Ìï]ÌÊ¢fQÒÓòl4 ŸÀ:Ê
†±Î«Wˆq…ˆ;;‰¾œ™ÆA5şjø¡Öû8kƒŞô?!F´Õ~XG“óÃHÂ3`ÈSÁ]µöÂ)x¦@½:‘Q5àò£"ĞÚöĞ«Ã…!ãX#«„y ¼–ùQ7N£ä“w°à©œ»TüœÑ^×‰™D%r”ÈPÖ]PÓÓØ>ËªÍ³u't"ÜÚïo½æÿ—ˆ›èŠşê¨ŞVªUZOıÅ*>8šg* ApÚfßò˜À	Z.ô‰gšˆÚUbpR0ğ¬P›Jˆsù_'ı”ö4pO ]£RåZn·ˆZ¿—Ö´’¨‰®şe²bG(ÜPt¨ßØ
¡@ó]Q¯Õz}C/N8U–Ÿ“ˆæ,I-y4iy3O‡>Z.š¬,Õ¡ÿ/Ìà¥èc÷~Á>š5É›=¼ßz¬Õ+nOBƒ|UfÎ‹÷%ÎÅÄ%õ$¼¿)7İNÌ/Ô€Ÿ¼Dñò°¨5$6e½ù¸Bÿë$b‚Ÿ­Ğ·sÉå(xÌq!.q7Ì-ka•k1şYbÍëÁ8ÑîğwûÂ¯Õ‹“gad|}¾gª\b*$˜Øbl¡ÓÊÜj˜tCeâ¸jNÔ~-^Ö¤«ÅÕ‡Éïi¶Ø€•ğ[j\Ñè“éé|Gò¿ÄC 8-~SOšÿyC´6Á_WÅJk{£œí1®â@n+Fİ`i2ºcWn›°)Øˆs†x£Ç%ıœŒõ¤¥xÖœfÎ½¦jõÃŠ~Â·¡y.]ıÆQº’x ,Âvß|Œ×Ÿ'›gØSI"=“îÓƒ^W«.	}§ÆJK§ïôk@Çk€åèÚ!$òÌ3ô;\ÓÙÄ<q\è2úè‰8æ×ÓOÄk'M5Õ^3‡€#Ï1»Ù„¢•C^¬õKegì¤eµEl.ÎÆ¹şEúÙE…\[ËFŸ ‰1SwÏ'Cû[¿&#1óÄ íj?2 :ûmØÛLJ 1ƒÛRê­J¸Å àÌ•ˆyİ>éÆ„É6CCÓ­§ıpı`aMÇ³,xZE–sâåÌ›k·ª-&Ünãøoh`ÓüT_·~?€s“­ªHöÇ¤û?ßOn–+u·QçäßP/iX°,Öã¬Á)î0|¦Õñøªp¶yb^;ÊÉZ×§Ö»6Q[¦è^•$ı¾LøS~ç€ŞÒê*ôİ^Ï´‡o›œÖ’;¦, Å„PÄ5‚òëĞCGè+?ä›!¢¢^dYÔ¤±¦znã³Z4S ì‡Pƒ˜B/Óß‚ÕìL¯»
åvyc´,§`°a€æ»¹ESpX®™ÃTû
Q8wŸc¾ğstU&PY(:@K!ÂIÁ§Ò‘ pÚwÿş®Hh4‡¿Ç›ò‘—êœ7¿÷ñ§Ø^ëi‚ÎÆ°+)~$–ª˜ı‚³[çŒÌÌÃ‹ÊĞ1#‰¨9YŒV›âEĞîMcuÌxU&‰©¹?Ø½¤ü„.]…KæixÏE;Ğ¨Gy°š¼ı£%_>ZËÀ—ã‚»wWMCó»‡„ÀÁ¿lE/×lY{wÁ7ÁĞê-•,,(•¢'>?}Ö½LM—˜ Ã,x]¹•€˜%Õ¹†PÛşÏ(¹„“”]ÑF·B#ô•ˆ…²Ó:Ù–)ôÃ*9ô—Ë¶(‰ddÅ¢°øû€sHA¡?o/Ô	ƒ£3øZapEãprt-&Õ(±ø’­¶K„Æ«y³\Öƒá"ÖË¯æ˜øxğ
şm!zG\\$Ê ®¿UAÈ¹m¾ŞŞ‰u,ƒ@áBUÒ/‘fÒ‹CËşØaHø*|îÓ£”A+ ³—4	lÓÊ[ä^x¯©?šDÄÿ€±êi“ÿ`´p…¾v¨SÃã 3FışÆêÂ²X*Ó<v½,ß ?å‰û«Wü¼úYmüá-gşôSZoëˆ¯t[uËÇìİê4Î*‡Dä­|³µ,¦òB!İ‚4
í®ìÇöÓŞMÇçÉZj¨Èp¨@é§„|‘%ÿ'–Ûº¾µ¨*r29ñ Ğ ¢ ‘IPÜåg6/Ç€y<êÄÅ÷I¿«hè0Ú›e&lÑÖfT(Öë¸#¶øéìEÁ¬%~¢ÛŸŞ~ˆ Eœø Q‡™Ë“'h°²oäK7Bµ#]¾JêBdı6MöòºSn	ç½ª$éÙX2‡ç2s«X:Õºî°¤«ë°}6Äì üztæ@­ÙV~%”ÔŞ7¹û¶eêè‹cŸû©‹wø•«ŒBƒ—(Up\¢bl9ÁÑôÉâ@R¡*•âwÓøs?ƒV»?¿µîC“]LªK;Æ6Ë¸6éêl$-[$®j³ø&öMÒiN“Ôü½».™üÃH ©(YW£l…ùÂêÒÑ)qëÙ%ŸùEgé^¡ã'•Ïå¶õ	ÒŞ£Š?Ò=ÜMÖc4]mêÙH‚È}eÅ2_u¼çXøŠÖ²r»öl{E‡Æ<ãÅ¼õîGµW|?×Şíí&(˜X~¢*Çc¤ºúŠnÄ}‚gjVVdÂÛgcvRP$Ãh?‘Q­¶yfnŠ¤Ã»#o¨[Â…>¦ÿÎG¸«\Å1‡ˆ2?êÎ 5ˆ.@g¦G×ÕÙŒZ¢	àğ˜™­«ûÇ·Å—¼²Á\ùÃïNYp7g:ÿ½¤š×î	údpuápœ¤ğ?U*?Œ‹ÁÒSô-Q ép±†j». =h}Ò(@ÜÕ·x d?½ÇH]›nÚ^wEæ
¿×ÏÅ4j=µ>*{Ê²óN§É™:-õûÛıT½û=3Q™qMÉoMù¯·ƒĞ¨?ëÖÆ…e(­¢6ÊÅ–:îÊrˆHjò±İëÀ…ªâÈ¿İNÖ*½k'¤CÎ—´±Î+ØË§ûÑé ´°ÉÜÅ}»ïvçDí—ÈšI›7í‚KÂ-+1oQÂ™Ngáå©¸{½°/ :p•=êïkh%ÊOÎTt“EĞ»ü¡×…tK²D°0Nw¤Ã?{#X‹Sÿ°ğÀ5Ô€½†7˜}«³ÓœÑ"ş¤	Õu¿»G_=5—w.æ`Ã)]Ú†ÙyÌş[{İş<ÀDÊGÀáÚ×bbÅ/²«²•Åş{:Jÿ3uIÉú¨ßmœR¨Ï%®iÍ#ÙŸ¸úøœššŞ‡hH,ËGĞ…ñ¬nét}cÔ&&]ÂÈü›NR”±8²Y`ÛçWEÑ¶ûÊ&N5¶)"Ä
~sPgåv2B“n´à€ã8¾<z·uF§p4£ş0ÃÚ5_°Z”:ÓÎpÇ¹~(9-ş.?XÄVÜT‚Ãt^§`Uñ&°j_
§ú\ï¼:f™ü"$5~	½ú9ş‰Ózo	tı¢Š…Çb¬WŒ–^Œ@=È$N®ıß«†›S¢8§aüíqaÜŒ,aA¡B¥¨á:'”¸ÍxïQÕ=–‚¡/³ÙeQìÚÂóIÙ Š
”
U».İ:f— ®ï~²¦wİ«“ñ"éa¸´DÖ¾$ ¯2mF‡úRCÇ-‹•¸B·N€»+­™ÍòqßdĞÜ1e1³›nmùcb¿¾~Ÿ^[L,ã¼9|²æood‘}4á½Õ8L­¸Ö×Q»¢’Ğ›ì9P«Oîiu3VÅÿ×€e %ö~2{‰‡(Û’8Vfa‹ù§Bi¤0ÌãÃÀë1’|½ñ™ø3X½wşºøNi³·®Ä–oÎ©@½	€o6ğ¾vŞ[Ì§¥$RíTé¤_,­Câ]·†PhÇ²"Vµr2À÷Ğ‚¨uô¯»$¨|î­í1>Ê}Q\r3/Âoé’³rEı’¥0I£Ó;Í`==QÉ»MûA]¼Ï>Yş}çõİıŸz]€^¨~o·¬l3³¬:‘)ev:®ÀŠVùøúİÊÊ%×ÄÛqà³N´£-2xmB:d¹z½L8=!(»ŒúÊÀ tDlR¶pª’%°Ğ4·e mø'ŒEáâ®±p·ü®h™e|‰÷¶£vçhjù8‹A·İ(fÆùj\··Z´G³èsx,-É›pŞÀF³6ºMñ€?¾èbX¸0’Ìû‰]¬ï½ê¾fÀÑ:šåã×ãÖŸßœ±3ÄtµD_ÿ£Pˆ%ô˜Ïìhß@ğŞgiÁ½–·Ç3a.2tç€à¦3ZA.£+\I<eR®•oiL6¥ É¹P6¦%Nåê?ß1ı®Bq÷ş1˜G”ÎØ(FÀÔK»î¹‹ûiJSzh-+ú?ê™<ØgqşÈ±{¢Óo~:’¨Èåà¸]ôIz)S±9Ú’0wş9[Èï6{Ã$R~ISÃ%òïLİ»R¾”Ò¡•ô-«yªô Ûaœ.¸–ƒUù#®z£fŞtŠ…ò~yÖmsäsİ–‰¤ŸR?Ùï<<{çõ bmQv¿ÔÜµ]?}«‚,sæ:º"Q½2Ü|9@ñ‹½(úôçŸOeèf–kŸZÅABöÓ€mÊœò0->jj¥Éƒ÷—€VC«’CéáMP[í³µ‘Œ£ ãHïJÿô6ÍhÍ”"cæ„9œ[=†>‹-‡ôÚ»t`Q™¤u9QØ[¼, ›ı¸kÓ.œhÇ¬¨ˆËCì¯àZôª9LÆ….£Rª1|Îü|L'¼w|·£½}…vCèOm= …•?,5YÙ3¬kb–;–ë&LE(åÌ…^`•dı|xa*•2wv‡ÉÏ„ïC.í÷}LÿÎöµ«¦GR%Œ%?”òeè+®	û°˜sİYªã-dwËˆw7Ò4hå…Â”´å‡}*^ê97AQmûÑ2°zÁ«>NMÍ?àûb%¦Æ=ù{•Åufz!ã8%‡fñó9“–¸1ç+ü¢du„(RŞÉiŒñKÍ|”B ¡ñsmy^ó£ìF5ov—§&ä8ğÙ8½µH)¦GùäEŠÊßPR?gÈ¸ßvÉÉáÚÍ¿¬VIÂ*Œğ˜øÛüd7fuĞ¾"Î!ÎÛMÖÎAÍı 1JLH£Ìê GìØşr÷^!#ı!Eÿoñ>Åe4³}p¹v7*ß®\°&5¨²
Û%¬äòğK.z¾Á*¼S	-¾Mı§@Fx/b|¿q9‡L;lLÀ†V”Mq’ö¢¯eeõ!Ó¤«ƒÄ«92¬
½xeYZV±òÄå$ØìÆ
úA‘TÉ^y½×¡ÃªÇf	PşÒbè_Aù“MTÁÍC¶Ju€xC3ı¿ê«îˆšÇÄ…;3_|[†dç]9Î 6¸>û¥æ“«(÷ŠIW½Q•B°ZÆÅ®“(¨ÌG×³uÇ\°¢f›îg5lø@áï¯@ş¨0O/Q£¸òÆ.v|]r–\“/oféˆ(WPV¯ln‘¹ú/òBq›bò`´qÔp©íTİ±¡éXşğù¸…XáÊ·zõ¢0$ Ì$Ùí:û#ñ†1…ÇîO¬
ãMÓÆ4öò8L:ª5UØAàæÂ6ÄxK¤åì“9TtwT]g…£rGñÿÀ¾ÅšÁÆJK9:
!ËîÊÍ5 t?DÓy‡oÔübjW‰32¥23|£zjy¼jqSòö÷-öS1./ÖŒO0CÛ=£kxUñU“b„±£¥õßSñ2ééÈ³İÿ²is(^bfp‘ho©“¦ ˜dÎÀ½øı~¹ÚÈı…¹¸‰~èQ±NÊsBwëk®ÿG°ãÃ±Õ¾Úvûîßş¹¾ä®°¢`Ô\¥reC½`ğğ/ÉÍ×]ö	ÆY2f]½ûR¢F	ªÌoK¨öåª&Ğ†øL§BªrkV‹ø6
.|Ê]z½\\¬çÃÇ>‘œçğz¢
h=zİ #³uÚa0U¨Ë!· µÊCd­ã$ŒXL«5=¤¿KM~¾bz
§›ëO«±Í“Û<şhâ£‰q<ù sTv]”Gh©˜@?7ãåÌc¯»‘fW:aµ“‡—õHı^@^²—NvÊÒ¸M½<	íšCªQ³Ã‹òKÎ3ÏâjˆîtĞOÁÇRSñƒê¯+w\h›)ĞÅâô1ÏY^í¶M-6®°fè zßf®™º2QÑeÂb%D·ÔAñdZGÏ‚NzµŞİ™9õÒ4‰¹	¬@§F@(rñF/†oıó{µ
¢­XJ!öİ‚òÔ €¬Yoc/gòR»ÆÛPDğ]Ü5»Döj—ğ   €·ÑOıİËT ƒ»€À¦µq0±Ägû    YZ