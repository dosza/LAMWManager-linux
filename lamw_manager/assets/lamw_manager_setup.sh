#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="16269480"
MD5="0ddf2e38487077c123b6c0fe1230e802"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26644"
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
	echo Date of packaging: Fri Feb 18 19:24:58 -03 2022
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
ı7zXZ  æÖ´F !   ÏXÌâÿgÒ] ¼}•À1Dd]‡Á›PætİDø’0Ä$ug½‡(l@€÷ìB»,•`{$ÄŒcù€ƒ·Q9Îs½ğ´Ì+Ùé²ò–Ç¶
tÈ ½ié_¬cÓ›z•-–oo•µ*¥Z &bêe•Ô˜_½OK­èOê<à†ö÷
'<;TÇuÄ'–ª/`š6Òca~1!eZ,V¥,•4“«ÍïyEZ–<FÌã‚È08µ0ˆäñ9T
¬xù¬ÀLû!v¾Rğà%€Íz]şÜ‘d™¼#°¿,å{ƒ;²55 ‹×N8ªY*˜™Gùc=‰‡HKLøúO2ŞWë3Ì‡0G Ñ¡b
Ò<‰QÅÈMÇ2 ¤ó¥=Iª\h…ğ’ÎáóÈÇ'ípm„µw§Ä²K\¬ŒX±eCêDÿ—/ÿ°3³=÷Ä_º6ÏøÑèÈ®Ru$÷bÚ†ñWéFîÌÂÂè›5—"a¦l*)®µ¶ë~—ó¼É(ï@\52yÊÎÆs˜Jãê¶ìGµ=×ú=%LUšëĞIú0(,SRº
Z"´lÉqğ¯£ş¨ĞøRğ¢EÁÑó¤„WmÄ¼3Èkü¦Ø}õ }&9ÃQ†Áv¤ïg šK]•“¤‡~Úd/ò]š:ª™ß£Xi•‚NmÊuƒ=qğ.q³ 3/Ğ 7hÕ§¯®§Ö¾ 1ÇÁ†‰ÓXsK«ma1–35§IŠkHZ9ãNqPÛC0Pç!f4İ[z¦Å80~Nb•ÍÜ`(/CÚÓq©¶j&©&VzeipÅô]G~êsøR3A2‚è³júŠTj?°©Ø”	{ª~î§¼\†ˆÁX<ş™^ÄÅ;[îØæ¡ò%ÑºÛâ‚X(X©¯—LÅpGıtE‰’7øŞÒÓ¯IëßÍ2å0{œ>–ËÂh¤®W;bÔúàtÅş«§µÊkğG3ú­ãôEÿòÖYÓÒñ©‘IŸËD3WY*s§C±I*¦¼ğa®¿$è
Cšà«zÖ—#á]M7K…¬Ãj§›nÿ“lë­•Û}ß:í,LÂ¸\Üº,†ÅfÚEI%Ğ4LÚÑê_õ,ïXõfÚ†ñ^U‚Û* éY§­ÂyNX´+
’ÍÌËIAúíõĞÌgñ¬dìQá¯ ŸkmâN›¡Òéó]Íë&®ğ§R7§—T¾µ<åìRTp'ƒùÍ“<"Tß‹ÉĞºh2z‘h‡ ÂÜñ8"”ë¶>#áè	=j¹ş®… ^sÇxÈ±Hwà6dñÁ*³ÈÂoMåøCDG(ï1ÕYBç[Qcïğ;ø6¯tñOÉÑ“ºHórÖ.eaf©¤Šİİu»?x;BœxNwU=ô´şn2Û”ı¢ØŞW{hÕb(ş	S¥§ìÇë-ï,*\Cª¶NAãtXA²ˆ'dS*“nåV<4‡8dÈœµ¬YsäR)„U»Zí?ºøæè¡ğêB¦t+îånwë§Ú$Gà~eĞZnkí\s{(±ì£Ÿúwr§†ëhºKcù+qgë¡úÛûŸì!mv'¡àmûKa½WTS@@µ)*<ÌHÒªÑÒ^w[uƒ(ÕHï—d7°~îÑ±mz\òG(P³P(:ù©Z·?¡| |	‘&±hU2EÒûf¨	“ê04c«¥ú&#‡Ô³û€ë]ÛmW2Ç|ËŠˆİæ™rğAÎ8èÒø˜~LPOs¾
BÃï$'Räw­‘ÒKx^pd{—*ß(f™Tfñ¾½ÔñÁğÏÅğÒGÔ…Ø“T<F	ˆÓœb™Õn÷¢eù‹@(°™=-x“vûëµEe™3g8bü EßÉy-7äçæhT¬Zæ½­Ô8åxMm`8‚à; ô¹¦Ûg€Éò~ıAûüÕä  ¸Õ(·±¨ƒîGS%äxT-:406¨v¨Ñµ_á©L´ì`'#eÃ)!´»B²–úÚæÏ»Pggp
`Ä#ï;‰`T´´OÅÖg x]Ä?ÛÊ‚»3ÏÂ	!½—rwíÒ³-o«V(J¯`k6ˆrT£“·ü¢<a;¡@Í©=´JQ@y³»Í‰¯PìW8¡ãïÔù{İ;é‡ÄhÌ”[©·¼£…{
âZì`;ŸÇÍX—¦riÎ1¾Ü•?¾3=ï…¢™f]5Šnë… +¢òâæ±w¢îhJê€(ïàQhI³.oîš$|%jbjF«ğÀµBB²VÆñèÊ¸ô0ı‘Dt¤pá0>’U`7‹fæèrû:dq\q>¦‡ÙPŞä“Ø†˜]ÏòSu÷)ì
9uÿ¾G5XñîFG!Ìp{H»è”ÇH¼DŸ¹—Â(µ—äçKkÓâÚ÷hö¿ÁOËo,´¹€ê8U@5–À oµ‹tÏÑ’¾÷èİr>+iÍR•£„¡-§ˆ"P¥;‚~;´.»'^(|µjj0á¸"1XBÑ´«ğZ^±úÉ)vä‚ûšq%Ç=ìr‹¿„(-»W=÷ı­òS($Ñu¹-Ğ"F9¯cÎ¶‘Ãcg“Üï¬˜âùŸ›ÄÖy÷ùñ*.®K1(øæÓæÅÛeJ—µİ Â¯WvÑ(D«7ø×hWçqVãT²Uy$©ã	ÎJe[šåz²Ş2É!=§¿¥İt¥rr®„Á¸µ¯ì‹ß1EY UˆHË`pNè½~w
X=^!ŞJ¨tƒAä*R-!Â‘}j˜gíÃáñş—mû$b×)YCw	Èã\æ°{²Âè¸ÏœìJ¤YiM–‘:<„Şó-X­O©¤âE“[Aj…TyBïP×ÌVúM­œÙÈTñly¬*œxe€Ññäb p¸(ÑƒôØìk™4½å®¨0B;miéUêú¢$Îç“Sİj<àÚ½‘MJäY¸˜“nTÑ‘±vJ¸ê2+0¨}6ö£4]²gĞL\3Møx^ıiJâÚÎÕÈ…‰ÊUÈI“§ciRœ–œ•½1şzKÚ}?êq~‚]&ï)™µæ€dæ¬¾:Æ³ñ«· õ£—uXõöM/#Á~pŞĞëCI€Ö¦îáÇÁ8lœ=pŠráVD:>PÈ7Ü?çÍ`[#¡‰´ïö,ötiFŠÙá#IøH4Éu™¸¥îJGk'(}ÓŸ÷<
lkû.]¦ÿ=A9{ïuh­<pİ§pËÓ›‰íNy$(«úgüñŒ±¸ï;ØßBà¸pStÔ·SŞI9§u¿Ã3VÓª³‘DËºe†º9ğ:ğ·—É…lÛ¦µ»õÅ_èBQp¶^Î_Vofö¹aß8:r ”®µu1wiJšfvùÁ¨Ø@¸VìFgØVjš<ÌüI@Ÿíå(?0 ·ÙŠ7%Ì˜¸xAşQ±$ıCğ¥!¢'Œ3T} Ss¤Á©Eéİ+¹UÉ…¡>„Ön|¹PÓŞHDsVÿ†*`¥yzÉÔïÇ33k£zàÓ”t¹{ÀaoŒÕ®½İê^"ôá?\+ğ_FášàlÇÙV8şê`ª]æ<\\ô)ÁÔV¹J/ÁôÅVõf´ì46iüÖˆFuÙÑfK$‰	Ø^ˆb?_¥ “åÕh‡ãq¸`yotˆ"Ü%é¾@Ì’a§¤J+2f‹İ®_Ï—N ‹h¢¡ÀyŞ¯Drßº†ÓªhösK ±ÖZØğò½•¡ç0}aÜ5‘{g¸˜pGyã»ÂËPfğ?Ö£pó& }‹IXô,ùÚY_²lÚ:ª¤”wÙ>ù‘…ÂEhgƒ¶òÆí»YJvXk<t‡’|†·\½©'ÈT‰õu¥2,e†=hûèá•ø©Êf@ZĞ_Ã´Ç]üM,ãÖñIQ¥®lÑE…éu˜²¸äu}´*o"œÂ£S¹LÍ£dÉY^Zr$)XFĞêÉk·e´Ú2Dßö¬mŠ-ëê˜Úšîà'JòŠæç•ä3>şºû[¼qÅi§«˜M^;{//&Rr´ÿ,í$ú€{íµÕ»5à¥áHW.I³ÉÜ.Š‰­ûê_¹gß_£ßê[¦æ!°kc­]ïBŠø7ĞŞë_R’yƒÒÖ~ıÕ“ñÉhÇSş)º„ëm6ÜxÎĞ4sí$ù·ı(-›É–©£RşÛ'·ÿÅ…%µWˆè—ìr^Ş¢’!,ùåÀXZÍ  ªæÛ3ŒÎ [ªè*ÿ³&HB3_ªj`I6*Ò?—ä˜ÿ'ué%úi©:QŠ£]=(šê ?#v÷ebƒïıÀ7dgzU³Và÷	·zéwJ¹“Â¢˜n~SSç4»¹ä€ÃGÑQáUà
“­°R	ò77c/,Zü®X>˜7È`¢@sà’fÒ˜Û'[Q¬ÕS Óz~äWÃß#¶›÷÷AİÅmvÚõ;ËÈÉ†q2óÈ„Å®¾˜ÅíÑ=|R(ŠéØ“kW_‘­Hég˜1¯ÍÒ°(}fu°zùƒ¾'*Ÿ]&j¾ZÁLø%'Â}hGÏ/¡šÅe{éG V‚3Û©uEZ¾W×KÜİ}‹Æ	DAË\Vú çŸ€ZÆí«J%d‰œÚëO	zç¹U8ùy'>ñyÂ«ŞVVÕ,ŠR—ÕÈ3a‡`Á2$9%«a„b¬Dà=á6lëÎk”XÑŸkĞ:_Xß»Á‡joÁ(Õ`‚åäWaÎcYâ“ÃQÆ×¬Œ\@ˆí=ê{zõØ IÎSëŒ»àdÈªL!§¶»ô=*Y§g~Û±jX³G„Vb:}î£êa´!™«b>j1a<_jWáòŸv+uÀZô-PÏHA‹jö°.8_T}ä§(ßwe)@‡¡8ôğàÍıÍº!Éô³ıB[s(º4l5ïÅt³CDÂ¶.“nbÎú—a>™$µ%üímämQÓMû˜øšåKË®å”OAkA¶ıÖ‰FäÔ¢ªZ«Q==`ç›wûG¸x‚l«eöB‹Ï/ÂÊ²½E½Ìe'òróè}ŠOÁ“‹"üÜĞ••×j¨oØ‡aóÕÛÿaS³áèpO”§Š#M&°Ñ€y:M%ÅaŸ}g.
6ÙÖ‚agÄ‹¼ŠoÄZ¦AOyšp¾Ú$§ZçJtc¹ğM§ó˜~w|¶®Ì§]'J“Áú}tQ¡`©Ş\˜âmA©ˆ v/à½.|^æÀ”¼¾;.wé…SÈMnwZ5 _Ø*+ÚûD~µÚiNL)„y"R¯H"HVM¢æ¤Ü.<+ğ2ØbVÍ(D}Íç¿£ŠÛøR„u1œ÷æ£Øİâ–?§ƒÛa\’]3Şl¬èG6Áá¢72ä¤WşÜÅMµä=^va<‡İ\7ÒB¼xYkÏ{@¼Ì«ÉMËáæ¨p&ÕXÛ€¨§ÓÿÈT™Ô(3ÚdûÁ¨Ù”Š•eZKß~àÇî›û¦ÀRš”ŒâğŠ8ÿŒ‚GI—–R^ı•÷äÒ7@Õiiô‰‡Ù5ÙáòùcÎßâ}Ó’cïDÏ¬eØ{\œú´¬jæOóç³ÔaÉ0:ŠÎä?Æ|÷(üĞïUñ0° ªÆ
ÅUÑ~$ÍÖ\?H›§¥o<%‘˜ûJ¦òÎÚht•ÇØì†ôI9é*&àK	]plï$™ë,×«ÜqëMÃŒ[€	,–o7ï$¢E
0_ÕÀ
íÖÛzÎ¦ò5> ÃØã»_éùs`VŒËcC_ƒƒ)4Ö,8ê³^õ=RÆå¼êÕXX²Àí|ì`›2ªSştÙGúIK #®{=0İ,¯+áÿÆÿ‰Ìê©Å½R`Û7^ ,ÇÂ„
.îG|yd¦Ğ)PETª	? {>qšR¯ÿ6Òd¢1~	çfê§§ßÈÛ›IšnRÕ…®¦‡¼eôÅ[¦Y7üË¯–|^öeeEù†âQ”4 $Õ‚É òÍs3\†á›†r×ÙÕ	ÜÍö$§w¼øÂSğ3•R¢.¸]Îbë3áÅP)Èî×6¹0Qä,¼t¿Ëi÷r¦Û/,©/°·0õ²Ã\(‡	ì$=ÍÏ<À’ôÿé=Y?Şğ¥2ÅbÊèı¡èx×ş‰‘üL›?Z‰‘C¯—CäÙ¸b£ílâ6_Ìï|-ZújæÃ tÉö=ÂZåŠµê®ìÈ™¦¾$›©=Æ;?Ì[ûÓNåŸ_Ê ‰Îà²°™îèG¯5ˆDRå:^ˆ’5÷‡|Rª¡'OëKgÖµ² šPZÎ¯óYVÈß|Üğ¦s^%èêø‚†É[cµÊà–F9Ú y/ÃÓº»ù;CÒÚ/¹9®gEÏ)mj™ñÎkaK‰'òzQ‘yÍ|#I+æ‘H7šaè”?˜ˆT5â†.§¡fB¯i» æıã*ğ­	­ôº‡³gÓ(²ä/˜×·Óì¼ûÖgw˜ÍÄÎæ®ş17ÅŞgç—)iLB Œ;Ã–=çU."JØƒ¯º@pv{İÀCi®gºZ=<ò
ÔØæ‰“ØÙƒdİÁj*àñ(±£™€OV¢Àøé™İ.èƒTR¢/K¨-(6-;n‡øç™¹õfj	‡İŠ'Mob™Ã–1?Õ-<ç²°ÏU¿ãÎ•[ü{•.‚o1¶µ‰ãK%<LÏ4¬’u§\ÅÉyáEe})¾Ò1´MÕÛ`Ö&íí—$g¤,×Ç
 ¤å£áÄYı;î* û¯¥Æ+ã]"æ­f0³-6TxÓy[p…‡Lè`ä•öáàO6ZéaØnC¾cQnØCï’&¾Ï,ğÅ=EÚ:Ïé?´¿uÿÌ2Óƒs¼kµ *ş¯­f–dÿN‡ BŒøßJ§±€)MØ€6™Ô…d©
lnÑjæg^ào$6lûó?“ŒÇğÕy†Ôß(îW3Çôèå>P{ÅœzìyR\ML	¾.¨R„X)®tIÖ#Q]§m§({gàÕz{Š'Š­.(îuŒ:ûHî&É!‘ì9ëh¦üú†6¸[
¢/Ç¸÷¬Ä:tdïúÇC¾“üya²l)MÂCZ°öª
.&ëÒt¶çcù»÷+ñ9†ot«S©™‡…!QËív%D®ñP¡Şªäò£ 3«Ìˆ”æ_ƒ "A%{­µäÔÃJ¼_V5N)eèê¾ôP)²îRÖ¤Î€t®Cj|óÌåäó†|í-¥J2”}rª"‘Êqªdû™›ìÉÑ	«Ï
¿Üõ—/Åø5G3hş}ì<¼œ&½ÅÓÎ·fäbà3Øß/‹É´::ş;§·*_†º’g:t“£g~¦~R×;a-Xñ ÊY~Û÷†X ˜Wc+GÚŞwxPñµĞ´F¹«"oÂ(MÕK^Ä9Ğ|I×¯œïäwÖ¿v”â¥q…Æ¢y/ş¬ùìß´ù8üÎÿÍxG¯rawĞìºä—ÓiàY_Y³'Ô~aÔ¹Ö)ŒTUjÎ·3ÒMaç'}Â]§°Òi4	”¤B!'ó;³×çİ+¿/ÿ&b€'a®Ö ,Ç#®µ€À2 ²f2÷œSçÎ¤åqX`xÒàÇUcÄLôÒAqî|´CC‚›PÈZ~!`¾ş
xo€ÊôZ#Şƒ³¥/³šq·‹s¸ÕÎï„^§",ë¹	S|pV‘¶Zf€x-D`E–»~‰­£ÿ[L3µÖµ;Øç7ÖáøoÌspV†k2Q_W4z„Ğ¯ÎÙS‘µLT°¤8vÏGJeØ@Tû÷–ï¤¶¾á°Êª±ÕR€tÕóoµ‡"‘'2½ ÔòAp^ïKW$dµá¬‡}ñ;U©õ"ŒçE;f@aqÆt¸{1z «ĞàK	îĞ*IøÊVÃÚ](/ìXx%mR¯É;€}ö—›Æ¶‰	øg8Æ²Cô¦v^Ùh†bI¥TÁBP'P¸M¤lÑ¥“ÉüÑîÄÙã^’]¸W€o›™Ï|ÚÁ2Í¼Õ~)‹nş…DâÜñhÚJÏíkH½«Ï–gÊş©Mªs	…„D:VĞ?Ù¤õîg€1˜nmïA¶Ñ²vg H¹ƒûùgõ.u6>L¦›û»ÀêZø0a DèxÜı[×Š)BÚ~qöRºÇ\`Oê)~Ë²§y7Npe§? £´=AnŠñî¾!ÆÕ™³wrÙa±Ê×ˆ*#¤ú_2O«X†µk~äYã¸WÕ¸¯]CA±¨Ğ\k®©¢ÙÜÍí¢j…|;HÿÆà2"9)Oğï‡ˆ&T{§ÛpôÓŠ" ¹½LÄcÀj\¸"Ny	ó$eSTJô˜‘qù4îG/ªú`Awb¹lDöîû±OG´N]æWLÚNp‚k?µşuûM$ºÊĞÇìÎGÄÍ…Ï	…ä€‡aã“Î
î "DÓò®cRd’—]Ï$?¾…Ô½•ñ³G>“+h]x7®Ô²¡Ï]ºF[ÔF[ÒêYj8˜êš+»'¶’Ÿiÿºf·ÖÒ?ˆÑØŸß&ˆ'§pî²="ñL]Î|¶%3ª	ÁŞ—¿Ÿ^p«‡‡Dä÷ïDt@½êÜ0?£/9Ã)ûÕû\) ˆşú¥õçŸ{º¤cbİwo.¬oMØ´{F*Íb0ĞÎCMZëÆÏ3P¶}¾ëd/Ä¶ŒP½4§` 	æN8cT¦¾?uıõ5)(œ|´lö~V£Cğë<­00®¦Õ%…@Ş}æ{’2mñéT‚LFó³ÂøÈ Fw1‰	] ïÖŠçêusØÓÚ¦åÂÜ¤ï±8U¾	¹¤`Ca-°oªX™*§½
‡£ï®Oó¹›ÊM.ğŠ†Kp¦…Áãÿlì3òõãr·¦?!Âøkš‰ºŒí½°œDD9;@öî›^Û C|-‘‚Ó™öT'ıyx¡<4¥ÕMrQry,ÅÄº÷Á=¹şbÿÈ}<‚ıºF½S°ú´_ˆ´‘^‰T9bÿ}29:¢ÆO""œ„´°EzAìPú~ñ_k–Ïn—„Ñ³pæZp¼œRó§V\zÆT)Š0ŠñIİğ}˜8l[ºÜ6«Kù*k_±T9=¢ãÂÎ3¶^£³B.€İ‹x”Kó=Ó"öcÓUQã,ò¼²ã•©=yÂÊ(9lÕYUwÇÍSÄö0Écm¦ÉÒa»dªö9’Ny®ıË©Ãî˜Á,ÿ7QlMCVGÁrÚaŞ3‹hƒMb¶6—†ÆŠkdj&Q¯_Ôüğï"öò•R³}ÆPb9Üï¤‚ü8*Ü|O–b~~¶Öâ±4ªœÃ¢¡›hŸÑˆ‹˜²|y"ñÇ¢‰¦{Â7ÚTí7§2ª@:c\bNÿfn¸ùıl1¨jşA?­\5Æ e| †íZhñ\*5ç ”Û
2S|Ôêü^$ª°?i8#¥i‡ôB>C\Ö¶Ãè=gÉPúLfJã·Ğ€Nâÿà\É²<ï ş3àçu@ gşÖ4îJ€ ¾UåK”=:eæ0
â}ûâ+æ™&xêõ&«Ác×KvñK™/x)Ë´ãˆj¢ç“	•€EŒ^5DæRxØİ&uøOÀã×x‹§Zß‰Ñª„?ÎÅ"åæ›Ê¹ã~w‰–OÄv²Ì“´ùäÕeæzia>À½(Ÿ…ñpˆ4ä;¨«±Ò€kq”ZÆ‰ª×Âëê­|·½ßÆpP‚’iºıÜj…fÚ§GŒ *#dûéº·*t×ìu;¼½–? ¾å®”ò‹;èçşƒ_-M<cÄj¼@J$ËG¹u¢©8ù½u61‡ÌÄ1-#Mó2”XùÛ8•†¹Æ‹,~ıàBÙº«6ëj2)Û.Ş–dÈOï¤a£~šÓøzÊŸ;pÙ§ç
oºè@ˆÅ‰ìšãŒÿ/nÈ •jª,ß"&`;ò%w>Ï0*dB\ÕŸ–öÎ÷ncÕ¥^ßE¬B5¾l ËÒ‹ãÜhë;¼VvˆMyåùXßxæØ.‰mÚ®i0tx‹n7::¹LÑÑŞl™jØ<·Ûâ±3Ö›0àR˜%ã#Ğ˜éVË¬Xƒ0!˜Š$c‚m+İw¢\œ>¬¨TÓ¨­E•´µé.rrqx~¦xŸ>O0>ğuE0^÷yñQæpˆE^Ì#^à$a Bp‡‘ºG!Eg‡JrÎôyÔ=£âêU	®Ë]/vÓå9tÕÛ®¾¦PZL';½àÖ*%Şæ"çh¤—²õÁ*Àı¸y*Ó2œãğı¶ÑB‘êb•<§[ÃRÓkaÕa˜ş>;¿a¾O¸‰ãÅ²¦î­õ^o˜p™UN-ZgoÏ £‘æÕ¿èÙ÷VG·ûéø!NÓÄ7¼,³’V7¾FˆŒx¥¹2õÁ×S@ÊdĞTß±:f‘\H—í,–§$?'òp¯Ş7kÒ3™«ÓE…BZ0?ïN4{còIä¡b]´EW˜@Ùí¨·Ÿñ6P'k©…0Ü:óp P¦ò’ev½ª|'F©DŠ†±ıùØÁd¼I`œqhc.wÌ;¼üâyÏùm÷*ø=ƒ,.9°eÖ°´ÃZ‹³z|[íR/[Q=wj»“nzÇĞÀÂH%©ÎÏmæ$¢@è—ÄïZHÍ°~·úÅô4>W™lge,9>—S&ØÉ¤YZ¯²Œ]Lá&èç+c8P—ürX7‚ÊÀw8¾´Æ¹oÑ&ğŸŒÊk
Ë€ğİí"®Ô_·R?*lÔT¡YVÀO†p-ˆÉ²lgw¶ß^ñ¯ˆ–ÖÄ4ºçK¬eE"„LÛÅÂ¦w ;³ƒÉSnI¸ÛÆú“²Cwáºu®!Åû¸À/°LÇïµk„×@}—
Ú­{\ÔI	İnİMV×@n_P‰3²‡àÒ-{Bß¨›„Š7°o$)€Ó Ş¡’)Ô&ße»ï~[¯8õq\Ğ2¨|§VZ5'Ñ7ïcy|­{à,×ÇB#eğI¹ ¡Î\vh|şdş°Zñç²ãw¢­ÿ…íqrÌ¿Î"è=oƒÿtŞèD\p¶”ôp^Ğß;tÑ6I¾S*ÇïÈ›³Ï+NÜ~„®9¨°Y•YÏ²*¯ÀR=!rE]”Xd¹Ÿ§<ºtI5ÀŠÁ<i5jQ©÷ÊÙC?I)îCbm¡=ÁcDô ñÇ—#ğ0pÁ*/Ó"G¹¯1İ´	
#‰o+5”ÛÎ=(‡°ŒØÌ~¬)j7a¼‡û:öïvE	À¡}^Op'ÓÔp.ñ*`/Gğ²¼_·ºz¨ù»İœ}Ôa7@àôgä&ÍÛ¶­ß7œ8Ée‚÷í9êf\ãC†‚æI²Ì…mKàğp-5®9Å('¯ìñ²LÇi_æÀâw,C8§B_Í«ï¿–÷IÖÒF^Èî²ÑÃıˆ‚šÅÿ×4¨oLø,¼.í`è˜$àe\éœúˆF¸[)O·ú’³~HÊ]¸ò´e´`¦n(ªE~›.Ù"û*qòkÕèGÆr~gy¾²ÆÌ[WLXkõ3•ù–€0=®i6­ê³Ô.) ÿèfà\ªğ>¥Œ˜ò]hé±Ù]*IY	’ºLµğg¥ŒÊñ/°" Ô‹­½S]\$ö‚Øcôš±×S)(Üduî›“Âû¼”FŞ¸Ï-¤ö7ş~†K¯j®F3àÙK$û4ÄÔ#
,	›ºV³­u7VpxX
a3²åÿìù¯ˆ[òÚ!^ÉŒÓˆ¨†9QgØ\HW ëW0‚k-¶…k	Øl¼‰Œüè/âğePçdƒÑc|fŸ——´°hciV¡ç-Îê€Š|C5§“O‰Z¢˜ùöqôËs"G®s–¼›\bïet{‹{¬¨0"Ám})Y¤klÖ©v
Ñ†ï6nRÖL¬-É)Y‡¥ÁÑÒ`-#;nĞ¿–baÜrAÿ‹7iÄ‡×hH¹×h*­ö:_BœñÕzv›ø*¼lEeØz şw¯uhÿq™lD)ÇñCN)%ÛäÑÇ‚ĞÉ¨¦ÀB:¹ñ£ì¼’uİ×4®lÆ’ @áÙtâ^K|ß}$f®•C«8gx%+›Òwó¤åQ°vì¢
@95o{4¬VÁ'‰Jî¢"v’íI[£v4’|SïÿoUÚì-|¢ÜùJšãâ^FZ%çÆ5n¦])ğ—S]nv¼+h	`Vzo…ÄQ»tYN:Vº)ŠC ‹ÁÇÂÌÖjpŠ¢µaIü)Œ,#|ü‰-c8jõMQ§‚Oƒ†Éz-WšrxÿÀB,½d®.äòïÄšM«IÛC	MFó"Ì·DŞ“ôBDÆCõ˜¡ˆ½3ĞneF\ÓGìBÆ’à¶ë<v1‚¾Š×;şK\rX°RÕø¾·*€¶7M„³„÷Œô¬d–¬°g&w@·¢ŠôMøÅ¹&Ì*Ó4Qç¤!çdQÈ&u)³õ6j&Hÿ„ø8	­:SE«ÂçOë¹½İA÷2"HsŒ^aİ6{Ò—Ğ‡ÍÉŞ’0½RşY-§=éÄw¦Å–J¤-+fµÃƒ¨ˆç?ß5]ŒuØhN‹óu÷§ïáä¢cQÛãEû-HÙ¥ÑÉ@ğÇ|ÇRî[àœ,+¶op¾dÖ¼T)çxq0ßUQD«û¡­¦¾L‰·çwX!Öa–4ÙåQ¦/^—‰ô80YLkóU,ŸCüæ¢O+‡àÄŞ!¥sÓ*ëù/nõÛ:>Å2€à5=üäb¼“âÜ„*¨4H«_vÎ½“åk©O™§ëÜÄÏğİwƒYÔ?§û¼W„8üüğş™!@ĞMİ $Ò¦D{Ó°£é%hŸ2‹ºÛØîv°z)–¤)7‰İy
òˆ#og”0PÁë£y!ï çÑ<(9p¾İî8ºW°—ÉR lÎ%0)Æ`êôåêÖ=°’ıçÇâ”Ó].DÄZ¡Øüº~ì!X½KÎ¡S1-gV¿Lø˜}†™=Óòhˆ¥c„‹ °D·íğÿãLÔ	Ji‰gâù øˆÙÆ9Ï.½¦†X¸mŞ_â
>=Qê¬c´ D˜H‰Ng®Ï4“úkõ«N¿í>ÓÊlğˆşSÑáFáê9MILiö¤šƒ®
gŠ,¯µéÅ§6EÜÅğ
dÊ¯…»ñ!‘àNÁ7¡
¡>ñ„
½ëÒSI¥Õ°©n²Ì‡yüônù5Ê…²åş$“ß¦šázMe>«Á”_ªGf2£?Ş­ı_šn¸’5¹"0Eœ|«‡¼œ¿ğæ3§‡følÿ¤+ã„X]Wa÷Óû™Ô“’!+/írlo“¨Ó¼yÛ‘Iq­×çœ¨)éëáéÂ~@ÈúZØ“mwøª&™…àĞû:	³×nùÛÈ!!B®Ş›ßNî€˜ö9ÌÏJ¦’NÄØ<à\âxpÿ¬XãnÄØQRp=ğ§‘rV
SƒéßÉ5][qxrÊ:reµ·şd|Å8.”åÀPn–‘Vß`m«	^2ÑÎÙ?+Ÿ ‚½¼°ò4™¦o4§íKô_[u‚ã> ¬Ñåuót_ê@dm“¼Å²nÈLQÉæ¤IÓşŠôÿşï%…ÿIP	ş+ƒiX~¤¬»'²3!«¨­;šæ&y´R+¦öSp›(ø<®Klè†¨zFK$Aß±•Q)nnÉK3ÚĞÈš
|¤WkåFóÖ}yCÅ2ôYã¾Z®óßkfvw,Çfò —ùO~›9»#ï3Jt ‘3r3ôÆ¹3¶~÷7g~§éqÂ½èyM1A™ˆoÃîVÎ˜â Ğ>¦Y‹´ œb	1‰¤Û/5}¤¤Ù^)ój}=ş}(ïÛ£†I–èÕÔSU²C&E…×·âÀ©ã÷ (¾‡ÿ ”?¥°TWéµ
­2Ó±S½ÿ/üêJâGcaŠÜ#ÕMÙz¸÷ÁYïŞ[êFôhµ}Aò|Ô/reuÅ¬PNt¶c:°ó?~€–æ“íw?®ÄµSoº?ªä†xğÈHÕ{*Oa\pïÃR®c{Æ†óo²Ã.	­:·m¦2è ÖrR^oùÎ¿[%ÓÖëÔ(ïÎ¥•;,eñ2Ûv;i ˆQ'ÓM„ĞcNåÈõÎV•*ß’â¤&o*&€Qn¹8Ç›()5­«£à
Ò•Õ³ L¦Kıo^ouPW»àÉ°ÿe]§?Ô=yk!)ŠÊœáÊş©Ì9ßOlniKÙAAùºÈ
Èáséõy“Û§Ÿ,ÿ!ÃeÜ¸ÃTâ
–åm½è ùbÎ3ŞiÒ³9()ÄıÃÛ†BFù«&Ÿkgô¸°òoRº»Y¶²Õ…Ø€i[»/wÎ%0Ûì9Hnút¸®úI;Î„ù”ş^ı–^¯•y^ë1ŠÊ£óÓñWM™¤€ÒÅÜ‘ÑR+  oS©0£ vFtíÜ†ã¦¨À8
7/–ßÃ ¸=WUóVÅq¥@©²€ny²èø<{Î‰ÿŞ½kˆ>Ñêhk[Çú¼¿cÊå>ÏìŒÇÛ ş’Ç²M@oõÒe0l:pßàjÓ²;ra‚³çßpÊÃU…!QÒ'Ë—Şâ[Ô.\YîQnU%;ÖşD3>ÆZ+oG;|GL¬¹?WQKøê±fâ}Á½5İİC‰|~°t(“úÒ×'kö
 Å-¢SAE©§0gÏŞMûz$-g…Ş@V§òÌ‘Ü×x†¾&A÷à>ØÄ	Œ{‹M æ&ËğĞ5Îh¿†‰¦ÖA¬­ôe]i(ã4<ÛbÈÁô@­§í[çÂ‰è²úÿêq®+ü”ïdÈP¼O¤åGÇšHƒ¦™æ8¥ÓŠ¦ö:7©ÿ—9+È×‰dÒ½7#¡JÑ²›ùS):&vV!P$ Õ€(lŒ'ĞyÑ`‡m³tŞäŠ_Y
®´I¹Ë_êÜY÷ `²§»dÅÑ˜·ìûhaŞrJe-ÇßVICW|dŒ—­+·É ÒïÜ3–Ş™Œ§Ñ½ˆ©”V1×%ZÈÙë
ÁôoH!àaëÖ¥âY¿‡6µºxŒ/n2÷³à£W®\[z†÷Â`=Úß¬UÚ.g%ò'‹”“—çahÉ½Ëî{‘ÌË}óäØBAó?º ¼àI\ö·õãkÁ¡-ºâô#ó<p š½†d*ğ‘»´<v †ï,İ_ÅÚ€ır¦Ú„GİßpŒHÎhVˆ7ÃÃ]tqº0&.àáH¶Üš®„ì£ğ;ï»wÅè¨MîàÂœRDM¯ù.ÿ
÷[ÛĞ­÷FÃôã! ¤Ò¦Î™sÍ(…§?MCZ¬±œö-¿$+Ã‡°Xÿ”‹Í=bÁëG?¥áæiûUèü³ç.:ñ_æÅüÈd/Vq˜Ò=Ut)½Rc¥¶şé5î¸¹JÕIëàœ`˜‘/Sˆo25KO»÷ÇÄë4+ºö|u‰üPñÿdÍÙè'œ,¶7Dµ5c¢ëäd&rß˜õºá%¾T¾Xñ×•²lµ—,E?G¯âH‘œKaìF2
27ÃîÒµš›ufAß“‚“ºp†ošŠ¶İìnq¹îÿ’ÀRú[>¥ rÈ)&uI`,XäéåM]Ü–0è× bvNJªÅÍcÔü1‡-Š_§aw”ÇMôîˆ} ö)Â¨•…6Æ?†ıßŸ¯$RÍMõ
³Ëñ‰8Ò\mªå’ßNj&&CÒ ãsÖ¡á"FZ AèyÑ0Béw–ª—Æ©lw„·!uƒBkå…Êè°™J'Õ–K"aÖQrb³êÅ=ÔJ6‡“§OS’ûH¬Xffê[¸œÂX–"ƒğ0ıö\µI3M·ØpËé¡l¬¼™–véÇ¦¿ÄP&å
¹^‹,np´ÔMCR] LâÔ§„
Ø'@Có8VÀ`üVdÛ›gÌd¥ÆëÖ{4æÒA¶øvÕÿ;B`¨öl\ÓªÁÄCº3f†”«u}X6+³zìf=Äã¨íî‘Ü%¿/Û$j4ùûÌ¦‘VƒÈØ|n”ı%qBiİƒá±š#4ô¢LÔš^"	,œOjv©©Š015‰î\ ñ¿°/A<ç`¸díRÇ¸şËÁ ·ÖŸ-]¯*OÙ„O-ƒè¢Yut”YÑÂ¡ó÷"sZ>k*Št©åtïúAø«NøbyşñÎŸ\MGÉ.U¾F¨ªµìoÈ2¸½Ìrn¨J0ò¸“(nãk(<l¨¤¥çŞíŞAÏVK|1ÎÜÙ¤µ`5<Ïÿpt–2WÎ_Ò¸SæêDø†ƒ°Š÷C2-ÿyç6aµØ{Ñ3Û¼jÕ8{>"‚jó{ªóHÖê´ü¾”yÚÅ{ÿ/¥Œ„ßÎ‚§Â Ñk¨-Áÿ/‰SïZ¥Ë˜°p9Jv)ÉÉE¥¤Ğæµú"r&sxÖu&Û»N/•: G®ÛSTÙ™ú/ÕÉŒaÛnÇ;ÌVşĞÈôÍˆ»ãÊ¿kƒÚwDtO&´‘µèm¡G²óuˆwÛbblÛn_fkù
Õ5â'cgÛÌj4Ëwøx„ “ïŞMLÁwÇo3 b áÊ–‡ŒuÖéš’‰Òlş%C†‹%í~ú/–¹öÃĞÅîŞäGydápQç„ü­$õ"ŸÕuSp¡ƒ<+ÒbN2šb‘ÉyKyOùéµÜ¿8¥lØ‡±Ï]<p"g¥ôÎpz+`—¶	&öÑS85å­#‹rÛ&CÛ!ŒÑ„588o;W4<€õM¾õŠz•dn7qG¯ëdU·
¿À•Ç†7¨©Ò¥7³‰©IM²c4Ÿ‘*QƒÊ#³:¿u}«ıoYçV5OÊKö—ÀÌLqGÄ”¯‰µîiOÍˆ(Æ7k©Ş{µ,´ÿA\Î|&}7•a1'>ÎÒ­¹“×¬J­…¤¯½åäçd®±Ñ­¥»wÚ‡ç–òÕÕJvĞµ‡Ø|ÃÏRÑÕL“¡¹ÒÉ±Ş ß†ü>öf(ÀûUk½¸N¶KéÒ·ŞUşhTÄ>ø¹Mkécî/Áì³=¹LWîÎ{ÅÄÁ—)ÿ o-ˆyR=˜lí¢B{¬O×W–…î»ÖË¿Í¦õ“_Œ‡3ƒ£«Ù"/÷oÅë©Ÿöï“yÃş¯¹Ûµ¯}w†å2ŸÛãâvV-é=WÁnr=Fé2› Zoúvñ#ÊAm+‘=™§ø*fU/é­Õçˆ»”FàÌ_¬Àò”ùÄòçt
ô}¦–Ó¤²¾ë´¸¿Y²–÷¤§gwV|Åxd9ké(Qbõ¨	zÕŠ$=L¢½ÄÉP™qWœ‚;ÁCZğĞMd¢¹b™SªÕó‡ŸÃH`Û^-¿óñ\œı±â—¶›çvRïoSÆft—]	é½(ªÙ|Û¼ÿâÅAõR¥n1ŠËıëf}:ÖŒÔümò?wÔñÄ(¦÷Ãû±­]5ôé »Håìu4-TÊ¡.=5º;	ìÛ éDÌú(/ettıRübTÍ3‚4Q-Å#£sxd¤%ËVêf“)îÛøµŞ\Âƒ‰Zşêë@­ì¯fÂ€‹şÅ53àæ¨i~h`Ñaà
—®RˆçŞš¡ŞD/K5ŒãMÿëe¦Q˜V±ù„íGÑ(İÉt>{Uy#ñOö°=*{€0"Ò\M¸¨66ªÄÓcV½£³!-‚Kl*äÀ=ÙRƒy?0 “LkH\œOç%	<
§tÖ\^³5…â åÊí^tòçLpUD²S@iPêf*Z@J³ÈÒQQl%\³C+³Ô†ßÑA¦ãåÓ2å+GeåL%Bè ±ËÑúm’”¼´£LéûYêûèûO‚Ûb>ª#›>‚ø|ù"{göp1CzÕÜ?áL±ô8¿¤-¶¥5¥†I;·½’w­¼™ÔÓf†æ„
ÉÜÊ–CF•Ş•!&¡:(é¨(>2K³½q3b)²vä»×óNõVÇhNÌOòrBaclì¶¾óœà[JfŠŞ'ˆ®}¤o‘^¡«ĞY÷hòoîí¬"Ÿ/7˜Ô¢û’ú”–†B¦ñÇŠfqüªú•ıöÇpNØƒ1ªabÈ˜hØ_!V8)Ì†OıbïÉoªÿRºWá‡ {éœU` HJRıl†ëáòaÕÜëìTåğßæô½.C¶ùÛ)An‘åş¬É\±ô×9}É¸ExzbR¾DĞiO¶ ºo§ùæ,SfÏr81œş°¾§-çéÔ«ã~I÷•±4<Îàcå=áÁg=ókç==L’#ù!U{‡ÃÔ€ùiƒoÖ—$\ıò», İ§£¯eÜ'·zÂùTƒT…A´İN«mhç³ ;G³“dÀÜ¹f&tq%ÉÛ¬¶{4À*ueúÊä¬ÂĞDï
Ô»=ËNp‚Šˆ‚ä› !”ö»ü 'ÑÛKä7]É±J#¯8Ğ{?^µ“Í¤ğ}l_Ñh¯+"çh€†$f%) Q6‰õÏÎ8§½,ÑE‚Ò*™I"‡ëĞÅ!!]0‡šo]a*q¦ÕÌIY¸nöàáÆ¸`™ÈğõŒ—§ƒ"•Å'7:D…ÇÄhÎ8²8ß²*2öY¿Ëİ@8ÜVç¼óƒvEÁÈ ã#­«¶p÷«m”JVÚ®¢Ì1rB¹o¨Ù‡ÎÎ¦*O{ÂßïÚ/`Mø¾â¼!k¸çAî,ÜmLƒ¨¶³†ÿ¡“Á[(h‘–Fã“ßdWg¥µèF×¦ÙùQ6ã‚È†·\'á™iNµar†1F	XÖ¿qÌÓºc&ìS‰k™BN&Cf³ÜàØ=lÕÎiçWXæ°¯Šæ•”K^-*·¨3«ñ¸1õRÇºóˆ!Áƒ*Š¨äì^ÚN¬Ûº–Ñğ6aNá÷+­İ·ë_‰úòÒZ>©å
rü}/µ¥æ¸ÔiêÊ5\ŠÿÃÉ
@p²ıÂ 'U§;MÕPí@‹¿UÃ¥ <=ÉĞó‹	”	õ=Õ´ß ¨oEì|_ íâ/`•ùd9ÏpÊ« 3±[9ÖQFÙïà¿ĞYoÖ­«Òá>:«Cp

MÍ	€/’+‰]9l/Ì¨ÕyšêèÇû.t…¼
'OïI'Gz¥/ƒI‰’Jw¢ƒ¿*I¯ İd«ËñîZ°ıDp¿hù‘¯X?Ÿ1<´YÔ àÍiû²BŸˆìY 99úÓÕñšP­"ÇÔ'‘¼–Ï$re(6ğY+™Ò\ ÷*Ü5êWU5¾{äû†ë ²1kc}ŒBİ÷’ŸŒÄGiK„K\®’M÷¼dÕ÷ÃßT`Tc`Ñ¼0¢a‹óäl.£ÏÎV·ˆÃÚ;ÛüÀ¶k8'MU•™˜/Ù=«)—ËÖj¦ØşÆ¹k2 §r¼àÂóaµ>tY´Èm ñ¤î ûã•§SÏ°ÂKÙÑC,PXm– NÆ5à´¥x%N'Ì„ øª9©jyóıë”Wqı?ær¨×À3YÛd&JÅÊ¬ JQ¨X¡VÍÃGŞ?ÿP¹ª2‘ñù¢)hßTÓz‚Á%xœi‚¥Ş•Š–zç|_¸tqğÎz¦ ?ŠM;H<'‚ù¸O•J	p-İD !â‚n`}B‹‡O"¢Óş-T¼„g„ÎèÕ`~¢ñW­dÛU}GjèÖ`|sÒ=Šs!Ê6úJÉìHfEåzıSLùŒ¦†ü¼V$‡O¯—İËé"Ñ¸ò3üÛœ*³
wú‰åxïôÆG¼î×Ú4é]ÔTOA·oŒ_]!ìîsÏîıÀısg+j"5J½ò†QwzQÿé"œ§šŞÊæ“ú@í]èøşˆá_T~ìÿN‚HÌĞJÀU3"^"txä3„•Ø¾VØx­Pê0ßtQèm›†»u¤ù^¦cNFd’HÜvÊ2şö¥zÎİÁ—ıäøo~ğ)òøÆ0Úeï2ÀŠ:UŒ‡5Ä©ùÆ­ePMNÜ©Å-”cÖz6İ„ìhşø:å¼aáól¢¿è"3`
ş%K_•È*3êzö†„ûúŒí¦-[`ZÏíîü¯ïF$KdÁÌs½Õkê„™À[ó­ö*«ˆJÏÓx{§mNë“¸Mğî-Ù!Bwí˜H‰$%Êj5};K8„¿3~6 	AÖJJËñÙJÛÚ±Í$³‹FŞ)®HíÃhñ_Q9#`¨Gà0!s˜öxÙÚ:àê/¾7[:ş;¦b·×Nßv-6‚¡äŠ„ n¶ç¢Ñ48Ö óƒm¹™›Sˆ‹!8¼Ú‹‰®V1Q 9µf“¬VoIp=>çBŠúl«Û2âÛ•ëßáo¨±D]Õ@Ğı9ÜŞVÀ¹„˜ı\`‡GÊ“ô;%ØW,Ñ[QœXL®İ <ıQú÷•¥dc½IÒÎa_ãÂE7:¬ÁB(Ìß)­nÖ$HÇS¨NU¦ÇÚ|³Lœ
İ­î¯ÊyRË^:)½èå_@òòjãJ ğ“¡UôX«÷æ\·“wkÎ®ûÅİùDûî•ĞBá&£K$uÊ]’Ğ*ÂÊ»€¤úÇ?-O|K?)•ZxÆ“>˜`öÔx¬#2©O6ÚéÕæÊ¼‹™åì/‹ö$È˜
Ç€»ş eÄq:BVW·$ø¼yP¨Õo†¹¼0ûÀA*şeI‰)‰{2”[Œp-Š|Ş¥İ½•äD—¤i-’°¥äYOÅ=¼¡]ôŠ¥ï<mxÚ2"Ó¸±hLqÚEâş^sFKß¾ğ{éAşz/F5å½P„ø
«Ã¼¸Øf4Y¥³ıhäk0tÎSÛ€²ò”#¿'h	häªNÈ¤&Fó‹|=Øú;MÜM|×—dCn„7Ş´Á0³C
\tW«Ş‹fu€ç­ëz1?ÀİqúØ¯½«8°ÎÚÉr„/ 6ÌeÔ‘/ÃbŞz›Ê–ùÀØfg‡9F>’$äÜÛ·€êS[Ï%•wËÆéäS“ şÉ]ÿæåmµ¾ç.›½½Uµ*ÄoP£µ2s„i·’ö¼QA¶ÿç¹à½¤šÜsÈ‰çV±òJ»‚ó8)7p	³ÌêüºJ84iäÙ6„Œ)ÿù·š¥*Ò#^¥1OA .H@6F‰Ğ_†èê‹@JS(•°HóøÛ}S\¥Œ•ü×"’3öiĞ%c´š$ãßß)éÊ†$w ©›œºJ@4¯£rcêÍCS/†{ûry?PÍ¹VÖ3„÷Z™¿@ZMÕ{ssÈ‘tÜ%Öì™½N;âHô 0Ñ%£‹Š ÿÅå²RVH;İ¹¢#Î‰m:w‘55‚/¾Ã/MuŒxC×yº4$6™}Ÿ¤èı¯ I¼ŒEñÙ¦	ï/‡KCš²™Äac¸Ç–ô¿mÎUlÅöxÂ,óÂoP¢È•te™Xœ·D¶öÚNÏ¼xÛÅ•í2¸mİÙ‘ûc‹_–5OšÓ9\EfÚD0V`Q÷üSüÎçsS/7Ïex
WãDáöˆäÎÔjáÆEœ^ŸƒÑá4¤ü¹ÎGùÇ¸Ö[q•3HÒC!ÜãxózK—\­ûœ}¼ö7blGÛØ·“ºŒtjWğ#÷MG[ş²c^:]X= zà‰v82qo¬z'ôÆJAWlníŞ‰Š øA·6Ê¯ìÈÍeu¸ÎØdŒ6h­ÎnZiˆÂ˜³œÜ8h—şf£]jâVwùcXlìĞø\ÖFø'QnİMSŸbùbãY’Á<ØÁ¨`+¬6D«¹Ğ£²Ë³P"‘ìnbg¯:Ì‡Èl†ƒ4q×«î&‰ğÖ/”V¡êïä{¨k‹J|?F”;LX
0†	gáÆú¬tí.å“M$(bjûŠŞU@ÀeäL}€!ÆÑÌ2‰Õz2Óµ½’ıró‡hwº~Zı²J(‹ÜÙ
„ó›CV51áwı%–§¤„ğ$˜2^ùêóŒØægØuÕ{IšÍ$ë®ÂòæÀ*÷~Rc)“àw4 YC¿gÉòşRP	¨wĞ®‘b
9ç5¸NÃ$ª?d;FŒ«ÊĞRÇ§!šg1ĞO¤9Éìšyâ[×â~9Åm:¦qd­,È›‚¡c}MoäFèózÖ7Åå/¼$o¡{Âvb²©Ä÷Œq¶mm3e_h*÷”š© Ùd¿e{	-¬&ß%’íÉaÊéd%kÂÓÄû)Tø‹T:NÆ”g/w=Ö}o8“ïa4?NÀSQIñ½àqÙPh/$«R%jo•ŠÈâAĞ¥¥üWZSPòv«U¿lÆ;Y†÷­u±fa˜5f®iŒ|ìµ!¯"§P<Ü‘À·S7%~&qe‚šT‡%Š(ÈŠhB“ˆª8Pâ§ğŠº*ÅŸ¹{	|
Åú©o	ïn¿°{7XïN»®¾·cq] Rã,¶ì±îŸHKİ-EAƒØw~ã›‚üU4ïÈVv¾ÇãfÕ
iÜ~[#_ÄMq›³4PsÖ»†Òi¬üÕÈ«é_ş”p´OïahŠw_
ñYiJÃÓ»õTï»^Nüz“b/$™”I£aû~_!&àş®œ‹	Õ5æJX¶bÑYÒíİb­v®·0'½¿´ ·‚XR.…‡
éTÊzñÅò·Õï:äÿ<
QtÖš(zË2f@µømîÛ8|	AFÅˆÙÕÉ\¤å—–¡ÃÇP….½û‡„º@`²ˆŒ‘j©—m$`+^©tÒGİ²µFt¦®:/vè%œ¯(›Œv~{¦byrúF´P&ÄLìPílY¯œ¯…»"BrŞĞ\ÿœ6’Å@ZD‰Ğ76¡ÒŒwcÂX!T¼˜ø*ruöAëUÿˆÓa§Qo.i4ÃE‰C¨4§
oKğ%zÑ$zcr™¼ã‘H«¿@lk|Ë=.j£‘G¡ãw¢etÑüh¥Ñ¢8@d%®ê¦ÑXi0Öš@B!©ü²Ü|"ãéçi;=Dl(–²ÇŞ²B;–ÔoxØqu>¶¯¯®yç[–^#õØĞ.>§ÿâ©	“{©„´É­/õÖî2Ÿ8¿Ô!á·cqéĞı{f¶]jµ:mcbà”u½Œ$iØbu´û/fHšQ^pò#-]¸IÕ™è…êÂÅFÛ¹øÑŸrç¢ş:lŠŒQËúz›*V¬5h!”öÕôx¬d•e’rxãì‚©³|"nt°;Hî8£ãV³0X¾Ì®•Ç²­'†›|sïã¿ o‹İëb.˜óõ=TcŞ„ÊÀÏ&ÃÓöÀÂF“hÃí²Q‡Æz7Z4/øƒ0ëk²l…xY›™àT}rp‚6
ö˜¦ˆXÕãVÙš!é(níÔ´M‹+X]å do„9ç>Ë¥öLÂŒ¸ÖËÙÖ_–'<hP-±ÒèJ°”í{ÿq\oLƒGôÅCÇ¢ÖèoÀ’¶J:»t«@ÿåÂªÇªÿœo>Á'§¿€a/cİÊ¦ÊÖ~Èœü‘_İ

×£e’n4{ ¦ïìU'R£ïñ‘³áGz_¤ÁRà’[Ê¨ŞÉ„’êaßá*¯Q,
½œ"È‡û6ÄµÔ¡¤"s<èÍJ-†g½_yÖˆ!)l™v§;iû›7«VÕB–”kÕ×gÿN>İÊÈúŞ®ÄölôBz9L´!¾æ¨×pğhµö-Rô$ÎÉhT2®Ÿh:u9çÒÜUQÑŸ¦‚è£×_y¾´%¿L¸Ï†Ïnğ¡fúË¨²	iš¸U{¨dqE¬3²„mÃ=“'9$öëÛzJ =? 3q‚%xÏµô52ñ…™¿×‘)zÂù§u<z&¡†ûAš	›«$7Îââİ“Pğëœî'ëÛMYï3`¼«‚öLãÑ«â¹`jë”¶P«n°Hà3)5ÁãõPfšÂÅ=ªa}X…•rYÛn&¡62ÑËàÛµöƒÓˆ\Ë¯Ø‘·Mo F|Ò$ª@)³ú‰9©¥aHXøª€Bó—«+’“Ëë¬f¸ø“õÎäÍVËIïåØ'[RfØáx§ÃÑVãkmÇÈ™\aç™Îÿí—ÇaÖî©?¾#Ø.À0ÅÑ+áQbâX 4:K€ü¶ÿEÏ®>=ó_7¨™ßÜà#7íOWßÛ`t‘Š?ó FŠüziù nÅ#fSû³ôOO€ÊglšŒ¡x”¾øÙÂûÍšÖÂÁVì+°¡
İW 8î•B’1vKòKŠ?DÄY‹}Ñƒ±75tMÇìâÓÕâ6+®Ã”´"`Î¼q_D(Ë@‘	]éUs­Ù!A²	CL?ƒ§òõŠ±şÆ|3 Í0‡Úğ¿¹°ªÍR¾•Îp{ï‡”î-ÀôMz¢_»Eã`¦‘uT6-W™àÍcKªçÓDn©ÄÑû‡¬^¯Ì!Ü‹>C°ßË^{ƒØ;/·ÔŸ‰Õ5Œ²Öğ9IõåİØR(„*Pu‹¤½¨3ÿ¾r„#“ŸÑ	V 3òÜGg¼òÏ•Š'[,!(¢¿÷hcØ×:v!¼´uÿó/Z1·ø~×¬ èävtn$õ\m‡¢í{Ş	Î}*×™{¡Ãˆø}t	Z [{8ûT‰óP±V´ßt¾.àKå²Eÿ+şl3I¨² ”¾êWãÇOé*—(t¤wXCÛ<nfÒ¦İñ¦ó‡jºq!:1}Ê·å€µ ]³%+<Ò!™¼›g9­¢]Ê`}T ]×¾ş¶r—I—±%H™`y^t÷.ekÉA‘¦NG8eq¾d½ë×ï¸åví|JVê…á:Mµál‘Œ„YÕ¥¹Ú"õ%Ô>=®ºBÉ9Â…ÖË”4!Äa•û]ú„*’8–½f2Å>“kŒkpGP8!¾=íû–®‹ªå‰9èèSô‹ÍÄ4®šÂwÚ5¦R^KÚQ“*ø%ğ¾óƒ‹g¿ÿ­‚•~«yßDšURY	«otÓhÏW²ÿèÛbñÅ¶EÜ%Uk;Ò.D;şQxdV©±€4	^òt€H´5¨®‰ÜÙùÀ=÷BòRTãÁYPeïâ]C^ç@ CÕ3ŠÏ6êP‘J¼é×0-økµ|Ù^4«Zá)±yõÿœ™Šû‰OÃ´í1¹„‚)ÓŸ ìZ“¬–f#l-…u„—®˜d2z­ö#„;ÌR±Â+¡b2‰6äKÚl•¯óFœµ¾÷×mÄÆVÓ•q¤¶½•n|ô:ü¼øB†&eäŞBNíJË7x©Y†nwƒp˜öÙhO´=­‡~•“Œ¿ºz¡8ó¿ ƒVN¢Ã„	ğÙég6RC ‹V+‰&¶ÍÖJ}ïï\|¡PúòÉ±ä$²Ë`=xöZ4«ey½*hÑÊ*Ñ ¢À’;‘“«&e¹ég(±âÍˆ´«ÑÌ	.f9+ éøqÌ,Zå3ôxó¬" é{ >·¹2‚§[ºï¤Oåß"ƒÍ…t'S–ä›l”|½iìéŸñ›ÄuÑÜ§Š â™,Ã¨\Ìl"sä¡ŸJ×¤dšD€YÒğJã
|Ç8²cÛÀ¼ v‡–OŠ]Ê¬¿Á6ƒ¼†z›£›Áo”_igú·æå¸]ì¢ªqGrOõ.¦e…ù¸B_dHÏj¯ü¡¹áÜ<cMér`ig‘İJãÀ“]SÖÄyPÌÓ¨3ÜyZéêQÎCA«çÉ «HYvÛÖqnsfîNË}³Áèû¦KmPÊ°;ÂHéÖjªSö£{Ë³™­á¤ñietº”Ë„R²íÌµ½$Íïë’Hù%Â‘‰Î<T’»DzÒEo¢Ãw¾ÕîÛÃLärâº 5%yïÄ¯¯ÒÙ2BîôøoÆld8j=Ä«j’¸²SqYWhgƒ‘†Ø.Xõ¤Û©?[ª ˆ}ÈMªÒ2)M²
8Dßò$?}5³!:WPiÔBï 8³ñX¾He´EW$Ì¢]_gtï­gèlŒ\—s9‡hÁOMÍPÃşÜá%Ø„W›ü¡¢%EÆÎü’øéñz•¢O·íŒ¶ŞM>™¸-	¹Ô¼Û­ûjZŸ>¦/ò©W¤Í‰Ä—µùï©>\»hÆUğ n_ïß
HçğçTìï.Ü3<V¾
¬áÙjv÷ÆÙ™n{,áM›Úéká*f~êªÒ.p…–±tIÿ¢6Qµ´<†;wş´—mn.søÁŒNÑÄ¬ç$g€^…ˆçòeô2­¤«û1‰’p©…–:¥CÏìÂÇÒª#ÉRğ¥÷9A@'8ÍgF8ÙşK‘kiÒ--Ö¹ÒëªàSœ™¦™-ô`$& oAz¨6ª5ˆ~µŸ}Sü
ÌÛX~›Ãók¤d'÷‹À}÷ğ²/A·l;ªFÖ‰àfvëY¬9‚Õö|ääa ‰·D#”;(w®Çõ6Àƒ ÜámÏà‰¶’¿çŠ&XsVş+àŞ¯ÄsD9&İëâˆÚİD“cAFx$@ÂÚƒäè6Xû
DP!ö!¼}.ò™”xËÍ÷CA]­fÔ¡¥ÃÁ,K/§ö+êôQ#şï|ûyÛr,1ó%grl D(Ë²¹Ç„l5dP{‡òkªs5e±™QĞÔ$mAƒ¨Œ÷CBør"àiÏ¨¶İÇZÙS„<ŠĞŸ²WhcåPR9Ğƒß¹Çºüƒ¯….€˜z)³éà+‡0W™Ä™è–1ót¡E‡˜§s‡.ÃiÈÈí TAÃaC„ô†Å/6D¼7³Š0‰t:côŒâTqïª(íLÄdú²{=¦
úBN†O]-_Df_Ÿ²üX(ºp@æ·®…ŞŒ4BOZ°ú20`Ç£7Ë«Í{Püu~%Ë9/„%÷6Ğ×ç,ë¶O-Hb—RC±ãlEª·–nÍc²í‘ÊUæ ¨×bŒ{*AûuÅÉª`±0çßP=°/ıû†¹Ÿqo¼Ax~Tm9U%“PNi0™H‹Ëîè’JªL¬u`AŠ{\­‘§2L÷ Pµ\‘[^ì>xU[Jú	>‘àğ^ˆÇTp.E"G!a~´¿ôÏ&Keø˜RA¬×Á©É\›™ĞQq5ºT‚`ºA‰Ÿsf8D°¤í3Òf÷ğÊ•½gÜè,:—‚¸jG€nèïå£²€Ç™şp‡l6f/cBœF†Ìï}xåªîñÈ593'«s«ÈäE‡¥¶¾C#ü¥<"ÙòeBgÑT³¬h$éÖ+­ ûfşiw‚ò]›€‡·ĞKTk|~øŠ'É®¼èXãægQ!ğÕğØ	ëåZÀ¾ŸÔ‡REøÑ{O¢+'/¯‰â¤R{i•şü]ôÎéê×¼|
9¥Ó®ìIºãŸO…k†6h`W>xÛ×áÔbiï0s±´ÕÆ²,°rA!ÇŒµş~?/Ç¥Q’ÖÓÏĞ8hˆïÂB&RsGc/¿˜”q¸›]…òiìSÙC.Ğîdš29I¤XåÓÑ^„mf™\ˆI’İíÏ$'ìëEÜi¸–‡âíÂç-Ó&íÉij¹oûcfüñ6%rWNÒDæ8êg¹Ç‹ëvI¯:dv6§Î©PB§;×Ô"•Àh?„#<bîf/eg}#Ÿ×Uá‡Ã¾úWÎ´`…J5ÚÎÑŞ£’]1O¨:Ğ'Ä<õrwÔ}Àµk—5n.$\¨§é_)µjXxbì€¬Çfèä©”jl¥hbŸ‹Â/®˜’¨®uß;9ëÈ’g¾2¸Ş'Ø˜’a}q+„3H7ºsñlw1*zéE*°]I°jP¥ÄÑ}¨$ò<Ëºì‚Ã‘¨‹m‘& àÔGJŠ6¶é†ähn^7?}¤0†¦ÚæŠ²½„e1(Zg€¨'‹™vŠè$şÅÄ^UAŠ³­ex./HP3hY¹¢“(¿>‡¤_ÈÙ¹ï2v
İW~+y'k‹Ù‘u¬¥÷èÖ…°:pyCH&Hš±šK™¬°ú’ª¡ØpÜ6;"ºİƒj-—ñş­õæK]XÄzéúñåoò€ğf'éÈfÀC«Do‰jm´/Hsİ44WğtE–2ƒ+NÔïçLKŠ‚_ğÎˆàÎ£zLæ^÷6m¡Ñâ¾‰yáÒVĞ;‡Ç+ÓÀˆçÓ,ÙwêıFS¼¼Q6ğî*qmnšŠ˜(ñÓÄËŒ½ÔÁğîÄ%ªA=wî‚
@¦ÌÍÙ“å[õ7ü ñ’Ñ&ØF
,^Ã”MÓ'1|â±şÚ»ïh†³ªÂÍ†q—AAæX0Â„^Å™‘s¤K ›€‚¶ßD2d-†¤@ÜM úà”ıCf‹Ÿœš–!µÈ `–aîÖN×Mü¾õ5…Ñ3/ëŠÈ=kWcSJƒï7Ì’²TáÚ‘å³R„¯€ EO4ê)g/HùS¥EƒôİĞ­bí)ã ÀÀÆqæı½8ÖÑ¢4Šì¿Ä›Æ÷×!*àşPÌre-‹.ÅÙı¸Jj
8NjH 6GŒdŒ¶ öô]Àì{vÒ÷Ì(TØ®ïôVÈ¬íS]oe#²HûªÀ}«·ó¹éT Ä¼Ä¼$¹#f¹TJ€#Û´\óõ
\Š»¦ı„®(†q_‡.¢-{¥fpK†3ãè¨~ôyl~eê6ÿ–°3™ú^&@Ãr½|2îøàë_Î‰V ƒ	ˆ(ùT=[µJ!âÎ´YlTV Í¼wNÃ„IMòû-[hñ+ßWİjÚÈ)‚ão•7ïËBàÃW¡; œ	-Ú’Í6ú†‰ùøıiPÄ¼r]Î>ÚŞ¼;¯;…*CÑ¢öş7—H×Á¦~²Á’»G^Æğ[–±FêÎ/ÏÚ£]rD^ı¯ßk4ÌFœÅŞĞy¿áØÄëô{Àé­Xø{2?ª÷ËKè¹å7ƒH_;Œ„›ô‡t˜CJñÓ‰"vÏ_¸ø)¨’¸Ê<½‹<wÅØM úÜÄÏÅ¡¨$(p^~*é7â³Œ" Ÿ@ÌA$/ËaZr¦´8Äoş>ã®öM–TÁCÃ0¿3Ô¡`eŒX ¿dÃ|™(xgÒHvB h£Õ8ÿc™Dhe}Uƒ4»šÇ·Q ÊÄ›•«~SGÃ`5‹/©[vû°âÙImE'EÓ^‡Ù6œ€£épNÅ¿¬V½Ş²¾CÅr¾“ÂNÿ6¯Ak‰{–E:ª:xT|Ñ°"/:8Æœ Çõİ¬A “Ìå³=¿pí_Ã·2bbdûœ¯a–oc›öËÆí¯|+ú	Kí{:?—yÕL+d9]mîº»`ò‡ö#ç£LĞÀ 7i¦¹†+µÒ>vâªÖ(¬-ÌşÎ›{ÒR[}(ù9¯dŞq«Fe ç
Ÿ}iÈÂG
HÒ½áÏíæÚrx„ ÄâáVxÊ®a‚„ZjXLx4©è£NWU6l¯‰OÉÿ.sià I´=¾#ôv/ì!qèçš€æü·ŸŸ~>t´¥5µPø8ü8à4ıĞ¼šD·7Ë ¾ÚÅÏ[èJ»8 wèÁ\>aŒû¥È¥["¼|è1¨6å‘hó:î¿!‘…À¹ç÷/©çnO€¼ùjàÊ Ma™‰‘şN8(›<ØÃÌC`ÎÑ§Ïÿ7ÚaFf·¤´ ÊâÄV¢XîY>öRÍ~¾8úÇrÉ˜1>"ß0pØ|8Ñ¾Ìæ£¹0:AfDu{Öc™d9®«ğö»“•yâê³EßìËMNv2× í}ë]ÈŞ5PóTçÕÖ#ç‘÷Gù$€Vßè˜ºÈ«£ÒºbùŒ¹|Êif2~ØˆøA'f§/÷-é‘tß"µ—ªÉ¸€1}‡ÁÿÿjÁğ£R`OV»¹-ù	cdíº„ÊËxº°*¼Ã'£«+x\ÿ ³ÔqÒNjìOÈİgJtlR{(üÜ^Ø«ÇMp~Ô%qÉWª-dMçÆıÃ_x¦$@‡ƒìN~XHºË÷ÇzøC?©R8U6P*çî¶ÑU‚zÿû°ÖÓ ß‡‰°'QÚ†VdºaÿÔwı*FPÁ4¶u8°³j'=:(èpúïZ‘óJ2Ú‘™ÅÎS7ü}pRlÅ‘«-ç~Ï_R’9¤+núÁ)êrsŸ)iÑ€‘]ë³×æ:{vó¹ÅQ*È¨>ËO}œyÆg›&Ì¿÷\Ãç(¶öè1«j  ¥7/Tƒ;Qî²UAÇ[’ÖGôBÀZÍŒ»ïb·ŒF<Ä*	¸êğB‹*KŠæª‚˜>5›HfÒ’•®ÕbŞÁğÃ,ãÃuZëb.¬–ÍÂ)¾Z.×D/Ê> Ó1P¡ÙPß°CN« åAb÷GdBô¤ÕHÅä¤ecM&³¡ßèeTqÕ§«rıIDÆëÄ
î3==ç©š¸` „Q×—êçF¾7˜­‡­§Œç–Á	ìæîsA t	(½¤Å§¸U,{Ó´âÌ?µØ+šÿÍÊ.Õ¢0ÍÌHP÷àNÆÀõvbpPŸ%UşvÛÃ¡¶$`ZÆù½ö•ác£ÔFuƒ°|Nã2ŞKCÅI³9aàv;¹¢ƒ¯/ª ÈcËC[Xg©NÌãÃMè¤1„¸Tvlz$1SÔ÷¸ÌGq’œâ¢hÊêıÀ:pæø=C¼¦ê~2Z`/í%¸ÔÜ`#MElhCö¹7¨W/Q~ÃJ¡Œ¨ÒSÎ(•óİL+Wz¥M !£ú×e©qY™?ûİ¿Yï½U½èQÅÊ`îé5ôü…ïåù¦ SÜ/YsßË Ìà»JC¥•£™	¬-7bleÀ	P¸zßußàŸîFô:)½A^oŞI6’IşŒ)Uìó(ìî±eêÉ±ŠVÎ0¹18y•³¼v¾'‘ï„rKĞˆH˜°eáıñËæbVµyNWö)ğV$eP0Ù£Æ#'Åµ¸R‰Pu­Ö³ä6ºš%ö—ÎéN_X!ˆÖ/“îpê"síûšÃ®3¶Gqo÷F».™¡è¾Ñ¹œàˆÊk_Â¦\,†qÂ¦°ËŸÇR«Şæ	?+tÙ8Õ§ø¯á}ì°¿$+ØÃ%Öøc ÙCiïµå‘¹è>è£Àw¿Y½ßN$ÿ°âÇ{D r \›%üV:0cõÛDïnÃ<( ßwõ±Q2»±x°3Ü-\åÉ®ÜA—	Ê¨+•Z4a
}DŒDCÇÃÈºT×£á¡<Êÿ©ìÀ&÷Íÿ"$ª­ü@í!AÔ{€k„&b½rpäz”…6+A˜v¬Ò¬ˆ`A,D½vWAZY\JeìóŒ÷àÊ/«B6
tt(y÷gÊÛ¦{áÌ½ÁPW/'¾£çà¨æ³¬ÔnŒı~g½˜%n^	–]É»«µT¨Q°q“™UU[ÉÙİÅÃNénN XÆn<ºª®éd#ÓÇAf+Î³ÁË´ÄÒ±»âÎ0Ç:Úm›Îù—‚ñ’Ô©"‰ùùc3\U¬®3Aàvrö!Áyoe‡u|C@25?±Õ$z‰eã‡’©*®¹‰;xsøGPñYCıU-Ä÷ÔôøXííâ’'íl¸{¨#¦@ÂWëšNïÊêœÀÀò+¦õl9j*Âg—Y¯Ì
¥öù K×âz†ÛÈÓ,9ñ*aÃÛ]’åÃ¼¦z±©ê.¼ØN-öuêÄ¦q­Ü¤ÜDj–í´§8•ş¬àeşl—ğe^WX(Ì,”¿Ë™¡«íÈÜEÃ}ñ|€S¬kŸÃÙ¦İÎ<ÔÎLnŸ!›s%TÒÚõˆ3úZö=»¤óåF˜y½Ë¨ç”N¯Zípâ‚uGl½zUËÍ¢¨£9uCwİ>÷¡…½ù l{
Ä‚‚Ù—|UÿónŒÒu0áæ76Mï<-ÜSås*oûq°QñšÌÇz7Àÿx4ø®øáÚ*÷y'¤g€Â»´=(Ñoğ%ì¤ü}vm (gòÏyaŞ>œìw·v~…´ƒhA®Ù> è|îÑq(±"ßÍ€-QÓw9cF_>²²¯ç’ˆ¸È0±Û6(Ä(NjV¡TqIM‰j³î°Ì×ãÍ†­CÄHRQO5Ø•Ù2ï.Ã_hÂ?jèMÊêL/ìÇ7%0ÓYK~©&MŞÎ9YÂ6ºbB]¢g=a™QóIúß½;è0D™FÒ#ƒÕ}!K0¯óyº>t¡÷}¢3ùÑç¸J˜C|Ê5{çÊğıÒåìÜ†İt"÷ŠöU.Ú·V‚µu2ü9¡~ğ]A0 u)\nô{×«°¬ĞêÆyÖTêô®N>
Œ&	sÇøÕ¬šö 5gÒô×}²ùÀA‹­ÂYgrô/x/vÀöqXô@×’:QÕ½ïXÂ^"•&J¿õ*;mµhĞÑhz¡ì°«ºÿ¹Õ~€øæf³Ö—r¬s -ŸóKaóµíx©+¹#7Ü© S´,ÏĞ)ÅrT÷çÒ§×4%ıxÂ¨oÁ!â9z>CçÎ#e›<p¨ånxj¯Ä |ªÒ6¸è®C%ï²†•ÃM—‡{.¤VnÕ7L‹H°¡ÔÄ#Í­¹²ÏuÅ64+qxÙèÆ{"Ke™<ˆw²àiöÒ¥ßòa{,ïPtÊõÏÁÙŠ”i‚àYÓFIƒ9˜šLæ_gÓğ½ò³K³ã[nH±›ÒaÜÀF÷yı¹Íh[xˆÍõ“µñ¢µu
 =k3ÑÈ!¿6¿¦{7
¬„Õ¿/º²a¹ ÕÚşGØ˜Š¤L_ÈT.×wñ8²)¡6pc@Mú­¡ÚÀ×42l‚åuZ»´é9xÛ6]éB†:Şúú÷ŞË¼0¨,&šZ×{ª¥«ûk$i>¯',à\É:q¨ŠÕ>}(Rl¯éÉMM©˜çËé"¼†eh&|ë‚qøìw‡O_ùŠH‚ß¼²‚¨Ğ´—Q–´îfÇ9ÙGª±t˜É¢T“–„)¡¸$O/s†ğ§IH{©ş^3¹ı¿`%†d\¥½W%ĞoÛƒz«¾ˆ)âo	{S.×qºvaÆ}5 }3¾ÑIW^	:µ#ê
qÉÌøéå+”^¯{+iGâ±’<c@­‚h¬F,×5z,î›1Ma#G•îZ9$¬D®X#Ã}`JÆüó'‡b2a˜B8¾VılèµZNâM28yjêz\ÇÀ¥ÆŒeL:{Æ”åeGé±×¼<Ø/màZ?
ØA¸&j[U †nm¦6wŞ¶ÇÖ¯A2àÅ©a1‰²¨0¹;¬0
XmâAaU­Û­qüÿë0¤%‡Çj!Ö™°=·)üû[Ïûw­4€RWd·ò4}¼à0ñ›ÆRÃv|`ú[ÿ ÒÍ§˜ôÂğkc+XPöeä(7#"™YşĞùânı¶q["/ôé8èğPĞ¼İÉIh{%ğw£¯¶Ú¾úÆüà›ƒĞWY˜q²?+@·¨a¤‡=âûw¸?u‡ß¹Ëˆ’Ï«ûs:ÙìT§ƒ¼Ú^âûXÒ±†6“,Aı¸5o‰É”’FÈSÀÆeº5àc…­0œÎ3Wìkè×ÿµp…Tc¦¦m°½~€àÒàç¢Û	 –>ÔtLA¾Wè?_±09·`á7¤Ô{;	%Ì¤†S¿‘s‹«‚û¬c€º`:Í¥î¾Q/š½ÏƒK¥C[¯ÈnW,ÜbéœÚRİdíæ¿¥µ•«¦½mí¥ ÃCç k-ôê³ÇÆ]IºÛLÙøñ¦&x‡8` Ç(á›NÎ´æGU`…%Ìò%èNã4•üz¡•.\„I¿ÇC
Œù%¨Bú®åÍ_bĞ3(ÿÏ8óé¤=Šè[©Ù6‹X1A€)Ã*°+Ê¸I”l’jñ¯ÿKûT~ô€¿çûßZO˜‹Ğ °
©yï–)* ·	GåT9ÛEAµ†Wûè~Ÿ€h¼AT	=ÏÚå£ŸCÓ˜'ü ‘ï3ñúÖ\˜\İš×¥§HÓêğ‚Ë|òät•ªtû‡Í=-œ—„ eû9 ´ÙZ|&e‘\ELë´¼¯šGù0s‘RèAÕqıjëbbÎ>\ÒCg°³\›£ÌX±vSñ†xæÉiä-7´{ãğÙ‚—{îºa˜aŠ/ÔÁ3m›»ŸĞŒ6k¼¬¢ˆ4z–9lx'ÛIãÀŒNbÔH‘g9½.ñáNÆ=úÂ5A=è«aÔ1?î|d38v7kôW›°n‘÷‹‚^Ã&Ÿi6    ªö¼wDj îÏ€è¯M¢±Ägû    YZ