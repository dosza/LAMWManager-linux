#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3576195583"
MD5="00c43c917ba67ec54bce32b4f245ea10"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="16944"
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
	echo Uncompressed size: 100 KB
	echo Compression: xz
	echo Date of packaging: Tue Dec  3 14:42:35 -03 2019
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
	echo OLDUSIZE=100
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
	MS_Printf "About to extract 100 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 100; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (100 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌá?ÿAî] ¼}•ÀJFœÄÿ.»á_jg\/Ä`PÒ´Ù®TiªŠˆD	R¥T†‡S¡Šã÷‹%ÄGØD¨äUÍöö—ñ>{` À_@íış¬ˆ,Köç$+% LaOñä|*´ÊÉøéîY•Ì3V;›ÃŞ=~­³q—ß(ÍtÆ¼¼LşÕt¸êC·'íÀS?Dà~B¸~‡?ı_–€Š^È8íæŸ|¬%ìèôTƒwm§ıŠnÅ½ÊG­¸PÈÙœPH!Í}IîŸƒ~ÊÉŸ0é†ˆq«<"RÕ¹úJ$ÎN>dî)l^Jb>äĞ	èDÁd\¯@x«%ˆ€4†Dø»]+5/‚ÓQ·*!CjÜ’Hºµ,ØöMğî»r
fğÒˆõ'æó É{8ºõ5ºtƒgñkÑÅŸµŞëª/ä%£…QÓÿUùµ¾ÉÚÂè9^]ÍÈğÊ/µ|h5'‘rc"g×pÁ#±Æ7Ó!ÛH×nİõ§X¢^ˆ²Ïà}oı ×S¶-%ç¤Hˆù»ïœá:§_£óf?,ÑŞ–hªtuÆ}!’WIï<fÔ"æìK¦,T7”X¥1	&ù»fUäŸ‰õ“&¡M­©‰1Àmq´³p¬î+  ñb¿$§ÜÑÏŠÓÕÑ>‰¸s“aªÏ!T£/=_”³h>r§®º­kÍ"‰˜\ø2ÿ âç‚Åİ… š©¤ùŸÎı.§Îlö¬¯Uâ™	ÿ¾Ñ0ÕÊ’“È8Šˆeÿ„Ô+ÉØÆş¨Ò‹ß^º¶Ïå9K‡P¹¨s³…Åjí<ysy›ºU+Ôa°£	TäS/˜•H­Úı²[‘¥ÄrQ(„ƒ+èšn>ÃG,d^ˆM+¿¦ód®šàÚ£;ël!gw†U¨BŠ$93+•ÄœV:ãÍÑ¾(qƒ>Ez;5l<½•V;â{v!×@¡t®H×ù1t‰!·oßÚ°h«ñ/¥GIa/—„Ùm¢P€JÊ}ÑˆMG‹ëÊüµİÕçÊ¼ÊÑ@\ vë2øë³]ÁšmÉ«¯w ¥n•Ìù­ˆT‰…µÆşÇšf(–~¬àIŠñcH¯¸ƒÈYë­„´å‘™ò8uâa·é¡î¾|:jBâ)^*]èÇ&LÌN[G]Wµf}`HËÕªp~YÛ!,[èêÜf¼Áâ€z0jas» ¨Í ì³‚Ï±'®K÷ó~]£ÀÖ¶+*$«ñÿãÚ°ìú= åÎexŞÑF}±£páMßÿÂé¯·öçQméù,Á,_úçàqÿ'ú·ÃŸæ}3#hÆOŸüá•ê:_eRí İs½½rÕZg&Ô‰ãüĞÒg#½íÛŞ1#PjÌ/ßİTùº³”?£··É¢&Ñó1d{,v‘>™ğÂ§‰ˆ¥J7ù^ˆ}ƒ¢lÁrŠôqÊt6Û\¹ö©½æÔüvOü`gï\êBvNZ~%Ó ¥0çË!ª2!ù@­Å=©ğãƒËc·Õ–ßŠ´éNë	Ù}p¥‘>r>UšõÉMÖ/ÇÌ‰y 9ÕıÔ“G½A¡š{ÎŸ{8³•ğÙûßıæmÁOSÉaËÓ‘EÊ1Ùo½ÇK–H­+×ÜeâVg_`3‚\ß“¤%+íÅè!]°ˆFò¢¶ã¨ì·7‡¨a¬‰À‘Yª†“rÃ®şb.EÀ7wÄ:AàÀ¨vï¡z§ €ÿëµqmÒC:Ê!È£eŸ=£õuíLn?ChG%=±#rïGšßV5]Gä¹/—HrË}Ç¯¦S|7…ë*Y\ı
¯±¯à0ŒÜ2‚¡3yZ…¬<¥9ıçİàJaÂWV|¹rqyuÅŸ*vS±š™äú÷”Y¬™`PL¡eí´îÀó›<"şfJgêAr©?l„Ñî~Çwá½(©ú]KñKd7ÉiQáQ½#|qìKéèYsóİŠˆÌ'nwIÚh¿ _¶÷n7àèö¤Y×Ãæú÷Sƒ¾r%ğ©ùâÈ/¦€³ i¾»~vd9ßÓ8\Ú#Ù:^¥í}¾X—únfAìÓíPm»Ô-s^p2ËätGÁNEof:²qY¸ƒQóŸ›4Ôxo¸e¿œMò/ÕuøXÇº`NÁ<Tlê«húö‰XÏ¹4†{E öõ¶Dèåj²‹ªmIVÁV©9Ãm°F··, ¡G¢·ØUë—¸¤ŠÊ·È\U‡ìÇFu€*rŞ¨á‘Â2£ºÍ­Ï+:j…Ï‰îÔÕ±HV,ù;è³‰!ïZÁ­œ’RƒÒ]À¬Ân“Ÿ(´üÓ¬!LÓÚ‚o4`ö[ù¥ŒeËÓ‚c²’áZòÅF…".»|ÒqêGâõ”U¯P.{!É„ÙpYjKñN¡z#¥QÃƒ@l
¬‡Ä³Œ&4
qYjÉš¦F†°
PA#µW)š:†'¡ŠGÅô}ğ½­•ø&ÉÓ„:âÙ 8˜]0VY˜İÏ9)QéRbá$b{O˜<·#åó—®òV;óïÅß?dø·¼+4–#_È©¯éfNÈØÆİÜÔHg{Æ…ke¨ÎæàæÕ“&¯óš0€ÊŸcÇ°”}«5Oy2Ó¸nEÆïXf8“½ºÅ'dFzúÂB_Kjâ%œJ7º‚{ÚÕ
%Ä_ßòÊaÒÃ"'3Œ<Vz%TWZ†=Ó~.š>~ÜÌjß+“(½óéÜ«£÷æ7›–,¾Ó$_ÄqÃñ(X°"Ì”•Fûø¤¡~7Ä0Í!‘ÓÛ…±r€âÍVÈEÉsŸ§M‡
hıjÖ,—Ó#ÛŒRÅáa+(Ã>ûÇ!îó¯:ŸàsdP)ìZ• I‘Au£ÑŞ×2Ó¦HÂWVòPÑ3”tÄà$O:§œ×î„Ò”bd~¤¹qbnšTê3Èî§=M*íG¢6ıA¢bÚL5‘Ï-îãÚŠ×‡ûº¼?Ó±§¶ITé¡aT‹Är”ïÌM™îKÊ…, +¨wŠš-e¬Ì·NÄLÍdªÆûû7-.®©AŸ	e8ŠL·>O>Dèv°¼À£L)¤†
¬¶Ò<	(ü÷aÌ/cä
×öÔ¦¼sÆ@$’Ò»yËÑÿÍ³y‘¥ĞÏo3	6¦êÕcÊº‘¬ cóÊT.6"ëbÙÔyyµ~\²~›˜˜r'ˆvÌ©öYƒ¿ˆ@¸–:„ÃÖèÇ¼.êß¤qS_YØ6U.»Uù	ÁÄ’4ø'|1Ó.T¿#ŒYhÕpZæzìúAÆlãŸfVÛ„0Ïüél1l~gÑ(J'Ëây#!ô'ÓÜìú¸bÒVXiŸ¥—ƒ’Ã„Ş&²”ìÓÓ¦´Œz¦¯²¾ûCï–%èš‘“eRVÎ4Œ2e…¿mÖ¬Fa<3â„!ü=ØÚ4<~£o¨ÛU·káec0˜¼Ëx£¯
Dø’`¤äKWâ¤¥é{†ÚÌÎÆhŠx¸ÂNKvÜÅ%‰Q9êrå¾‘]ãN9í*Ïâ›€ÚˆM•ÃæÊ&¿ÌdÓÙ2Õğ·âúÉ¾ã~~@]tq}?•I/Z± ßJ¼/±ı:Óıg«)»ÓUdãwÂKÄh±Õúó-Õéğyñg~µ;%_HbA5ßŸ’>‹»Öå.u;}Mç‹(ä3‹h`èÁ<h'g‰…»Fû¿>0=}4ãWĞ)ôªÎ\{T*ßªƒCÉxŒoúÅ|ÔÜx(|œ«k"÷b‡¤×§9"rÆ·õeÿôë4g‘©X”­œ”ÿV¬­€ÆI=ª`»<ÍÄJÔÀ*+ãØ Fğr-¸ÏÒAJ€•›
l:Ë(0?FÒd†6‘ç®Û‘ú;Ú3Ê“Ò'ÿHjvÙÛÆ0JÃE\[Y	ØËÈ”pr{…s² ÈvV?¬"Âe—¡óD>ÆZÖç£Q\±ÇX\#‚˜úÅº­š}/š,:ô{ „Ûqô†DıBiXûp5ßa²ÑÚ½@!±à3™?¸üO`ÂÜ5OR—Zø°£°@ÂĞé­öÎx=2à›ì{øˆğèjÆhœKWù"çFœ¡áA¢‚Uä+20›Iû•ış¼±| <Šo^¡¤ŸâKÍ&œsKÀR¶õ§×ƒÇ‹ÅßtĞŞAÛfS³Y”[#RÁa¹µ
ÙÌĞà¨${)‰Ã­4ª‡f+@ìì»§ùƒº»\¯{.;Nz{šŞCøÌù$=Ï6†„®JÔkÎ¼O#İÅ»¡±{‚)÷OE”¼ŒÓäH¤½ÜğbÃx­¨}ëüwôŒäúmdÁ£qÍ‚İNz4ÏËò‘'@,³dæõÄæB£ĞnØ¬:dJóûıüÏ´P†­ÉM|ÌŞ}}Ô×ù8ü8¸7°Èü—ª‡\yì(?–¤Dùäæ¹LNûÿ6W!ùsµ½î/´Osã~x#PÆ“…íBösyK©^ïY°!Hv¯–FşKÒËİ!óbV¤S#™¯¡`¢…EÖ}ÁÑsõ)QY«s¨ˆ–ØaGYz"ÇWb´ø‘X8¼OÖ£JJ<îÄáè¥Ër„¦àŠBµ0œ\  Ûñ×FùÈÿŸ/Ä²h®g$“c’c—lfèvç©ËÿË‘Ñ»ÒŞªÌÙàåW¢íYÛâ¼8µQ‹"8ß#¯vß|x¨â÷â{Ï^´˜êLùäšˆV7·”,_,øæşAJyòËYÅÖŞşYZ~Uü²«	îdğM’ëlX¦jG¾é£æ×à0çP;',ĞDEş‘NÏ	5wAzz(ÆNƒ_u¬=¢¢ôı‘8KjÊA´h,mw„ª«ª¯£DïÛ=Ïáì¸Åİ¡Ç‘¿kÊø$Æ”ö@s}ëh§/º¤¶ãÿ<
1B°P¬*GâÔcãîGc€4ü¥ºkó[º#Šˆ¡²óo'	x-
<aİ›•½—(¾RU:Ÿ°(m<š¬#µ}:%şËáÂI›4™‚ù\÷¡Æ¯åÜÿFwv >ú	íƒûÛ4÷Ü	È¨¤WÒ™(&„¸áão«wRtœf¯$`ä…–²ŸuÜŞœs¯\ÊÔŞŸÒrFıÚMªü'+rÿ®êêpúÔ"Ò'EôâĞ;=ŠV<âA}÷Ô6€ÎÏ08Bi ¢Øë+iëdˆÔĞÄà™'NÏqş¿Â´Oj˜¸tò,ÁEˆ¯ö@‘W« à˜<ÉÆ¹y­¹}5h†æğ0[…y™Ë<ªA³58L(ôuº^Ò}Ës;T,0Äÿb›WXª'˜ƒÌ²$ê1YòôŸĞ§¤ı*óÄ´øW&´ÿ;ñ¯’èËJğ2<;¾£šõŞ—{.ÉÅ­ƒ®*]S`Á˜|]°+Ü³ÎôQ}ŸÖ¸|¡û ¾D~Œ¦â£}³²t	e/‘vôÜB&3|hÏ4³ìµ² 2	ÅÕì¸öñX:‰ßhú„‡šî5ˆ]Ö&’’‘Ò|äˆÉE’”nö‰¾\éèMX¯˜e ×ùq]EÌve:P|÷µdçœÉl0 †¯L©Óc,¶¯İã¼Kä¢³[6<_8ÒÏç÷V¥-Ïáã¿Œezó€¶–m¯¨ñNÕÊ†Ìí©„j¬zGmñ§Ö{Á2ªÅ·­±ıÜvõ¬lUbvWheµ4Z®P”‡†MãÄ”®Ïïèœhó};0ÂE¢”~)®IRŞ¾Ç|Ğ&±h,3ót v™éªà_s…TL@˜³õµË6q¢CBQ.Ï‹E_Ï¸Lüç#4ÜeØ ü»î7¹‡sëâ½#4f©"gF†íĞ[–PêköioğFÚ„²¯½Sôõ/]Ìsî¹P–;òâ@Jzğò×Ê^$íDÁ±Ü€^àX®‰é¡šNûÍ|Bå^öË†Gu9D|–w`'È¥é#'ŠóÆ	<vø·<Ê	¨àO½Qğ ŞiÄu¹!dÒƒLL{l/ ”`¾ôbò&Y=Í–‹/íş!ğq©FXJ[7Îxorf9\¦˜äU¦Hï5úåÜP$ğİø—Ã«$BäØ¢Ñ‘&’¡ìĞ±†å'ªi!î–BuÔc9ƒè85û´½ÄB­#÷JJ’ærSø3ğÙ´°Ù‹o±½ÃQ¨©è±UŸáç<mÙGV<ñø&½&†Dqô3æF¶µòÓ•±ËÆ®±U·z+cXÁŞ*˜µz®<‹^@»üƒ~9÷•iü1É$>û±ü¤)ó…pváş&Z`(n	û¾Qİ‚Fú;™ «béy}èª‰ÆLÄğ€K¯[¼ê¥¸Äˆ@ŞıñX¦/Á¦ÿ‰Áê´&ÌÊÍOÇ3Ô1{6Qµæ+µ*r.3[ÔÄºf“*·7zÀ±ÆØ>=<J´¿‚#¯˜F–À½£‹ŞXÒ&~ç)Ô_¦ (!ıï`8wrÉŸ¶ïÑ_å]hğF°HµdÁÍ]ÎÔ!-÷‹;`ŞëU¡BSQÁ'ToH¿oÎjòU®¸çş$é®iÈÎœ]ıY2åmx}—ó
{úÖaÙJÔ“Äi§@¡›{eéw½–7ç11OPŸ—ß©SÇÑá¸éƒ*÷¹Ü¢Ö:½a· W¼l”¯u 3ñ ãêÎWi¨v¦Ñp4/õ¹¥+œÖIR @¬>˜y-C’Go$ˆ2>¬™Õ†i û}q¨¬¼ oRE[Ó<N¼ğTãD»Zñ·,ÕÅ‰]ÔFD”y¼"*pÀä Sä‘*^	
†@Q¿¯•tÉ¿Zp°ª–!û8aŞD¬ĞâN¸§sËX'Nì°v÷…yÅğº.’#ğ+\ŞeƒƒŠ¶cmÔXÁ²ÅKZÄºWbèt·İŒÃ¬(>¢>W;(ş(­©ŞîdğÉĞ†s!z%²²7ÒgŒÑ/5q™áûá%Üôİ?„.ŸÁ40*¤Ä~³&ÊqõuÂğÁïrÊÃyù›p$’…Ò‰ä¼<ÇLy›Á)W‡4H€BÊ2ú/%	KÔS[4:öo¹Mî *5lãƒ³vòÜIôs·ãnŠ/N„(Dx Ğ¢ÿèÎÈKæËSÊÍ†•Ô;ft÷
ì#s”±â¼–¬M½¨KŸ]ÂCdİó!ÍqÊTÍnº¯7\ks6 ¦æ†gùƒœì;‹")óy¿Ğ^I„ğ/8Ì	Ç¶8lğ²Á˜ŠõÚrŞÛ¥\´­VÒfÚ™gãö‘½(Ø/TŞy1[wz½a6ÑFó0³÷Iº´£n,‡Æ9€¬àS !í×ÚœHòG8Ï’Û ãey*€lìéÓxòø1¸["OÀ×”´Îºê„KÉşğ›ÂÏ‰ËXÄUr®’ºA"	Í½°5µ®1Ğ£5ıÖÕÈ6ÀMôQ—;ÃƒEê’˜".'P{ç\ĞÒÏPo%“5NÀşA¹]ç4£¯Aqš¨wòÓ?51Á¦ÌÂDx	ªå_·oÂ5ñyàGÉİpDvv}KİKşór#ÜDèÆıÓÅ]ùœQ•ŞÕ@©Ê}tTj[|}y9QØKûºô9–v7†JT:'Êİáî®Ñ.µŞ>çÓ@Œ«/n¼dÏõ=…ô$Ç*ª	ù¢Vû"î<0*Åã–@?EùâY¢á]üTI…YÖ÷¿¢Ó¬uNâİaş`‡P™.ş_@’’Í¡a?‚¥ÄwK;şöÛáõ_R™³á#ççïN±äÙ©¼A¢I•Öš$Øe×Œ
ùVT‡e<î¥²…ÄJë©¶°Ÿ$~ğ_xÄ) ƒPŸ…\Äach¹¹4å‘Úœ«¼uÚaèw2OÃÜW¥ 7°‘ŒæN‹á¯c¬õ9ğªC¹×É­t~ù-,i^GtQ—i¸A“AY —ùœ³‡ºÃI½–YÈŒ °ÉhÌf'ÌëŸ^Xœ†ÿfÇ#Ö'*\òøLŒ5é‹ 3<eÅFOÔAM?ÿì®wÂ!—xcêPjÊAÕŠlÛÅr±Zé9	øòÛFªàe:Ğc-ŸP6D0ª*Éd"Kj©qı7´°—ñÂ tZëé€[™&‰~İEÏd²Js‡q@¥“!¼ÏD–´î¯â·m[#CA~Q¤å²£'¦WÒV}„"Ú´şÕ£†Ã?..DÂ	%\`ŠX0İjK½àQıJ¾¿cPgbQº¾u<tG”˜T¢ .½c„6ÕQ„Äƒ£RxŠ¼ª˜ãŸxšç[N]šküäj0?øDmLåûğË‰îİÀ&ãıkåøö»zS¼20ñ‡aÕóûÿ^Ö^Aë†•O¯È\¿Êò.ĞèáXS;âHÜ¬†#Ûz
ë7yD£^ÄùøQ¯¬Ò„‡Åâè¯ŞD¸µ{ ÏyCšo[çwú-©ß””!ˆ®À &öÂßŒ=ºüeÀ¾‡yä¡(ªE¥Pñr³ÿÙ<'Â.gMMN–x¬³¢–®o|Ş'º9áêPá¥xæâ ğùÂò]ÜŠ¥Â;ÓÂ—9m=¬Ïê ˆŸY,/Æ„eY•¬=ØÊ_
¥™HÈFe”ôòTi²û`I°Âº¯@Æ{lã¼5ÿ¢¹ÀB¡äµÏŠwÈWIäı ûbèô	gÁ¨%‹Fw„^Ã‡72²{]“ÚµÖÀäKÂÿ)¿¼È’”|/ø^{%<^2¦Ä`"—@Ë…¯Ğhed^&¹JË"Ÿ<=®àãU{^½ƒ0k·ßæ¾!ŠêE3C"
šïÎãzŠ&£”ˆ¨OÌûªà}SAR-ô!®'6)5İg=ñp3a½1DßRMXïªŞV_ºóát÷óÒPÁé«¯XN
°çGx#µê°G®ï™ëú ipóËP¬w2O¬D“³ô	¸s_Ê)zÓ	QÛ/%Ú®±x-c\xL§683ÿUv´ø7„¾p7Nñá¯E¦T¤bÆ¨n™¡n÷(äÏ…:qöo©îÏöÙg|zì†µ+,ïéZ{Ñe¨elïš$9¯“Œév2%ê™Mi†ÿ˜iüw2-fdEœ©ß×7Š)!~ÎÃà•p#õ€i¬es¥a_èÖ­J‡|ZYİË`pçÅÕän²[•(ÑĞ,NL)¿(
Ù0K/E—€Bl[İèş¼n8ÖæDŠ»ReÁ	ôô6éTLr×(^k>‘‡P™
¦Aß¡*úVLßşRTéNYFüÙêÃí¹—ùHĞ.
åBKä¨­ïŸ1<Ş‰Õ	×a¬üÁBPr#‰&=xL9İ>©8O+>:FLJHÄìÕæT{¶|¿Õ ë	ÔÚu/¾,ÎÄ-4"MÅÕ18ü°DV[ZĞÑM »v²sÁÕ‰b'ª±8­3†lşv…î%¹#,1Ì¿"‘‰ó.åõ……&ÜOÀ×Açé$İs&´Qİ/øŞM“‘ŸâiÁÙj(ú¯µJSÆ[nŞŞáfşFU–÷]-ÙQÙ_÷°t®µvjJ…p¬%y·3½©ê×ıÑn~Èdñ‚á¹ê>ÿqıç"$è¬Ğ‚XXŠİßî2ñz<°4>LN‡RÄ–7í5UJœ§Âºàfİµ[½³ç®ûŠ¦øñlB½ÖJZô3í½÷Û `µ[…º^R–Ù1ú•zW¨ä 'g€JGvõJ€°·ÛòŞ¨DmA
ët²&*™Ğ]£uÔï¶Ê#éıD°ÒÇïÙf÷ıÄ+ŞÀîgğk+—Ö[<I¬!Näµ, ÿ¿FæˆŞ*Æı<I½Õß[qĞl]˜hĞA«	2Z0M³ôÍºk®Fc¾½J¦X¹vlA0VëeÊI-â‘.¯fQÊQ_ìı‰&Tœ>>¼ÈÛ¿„7ó'â>µcÁ'¹—ïºG{C®Nµ:òãzÙ•ZÃzSr
·Á›eòÁæD`2#úm.Âkİ<¾|Èåô-ë·÷K¬'Õk©K&Q·^çxâXa³]o
{ÃçHî:È¬ÜÜµ‡_Û¸­Àš 7ÔÚî¬9êEváM6pù\‡ÉÿcKAC%.ş?”†õÓå„ACs¯R( ûüZ•_“_„3Ùî[,T¥8ëè›uó“,À±T5ª7½ØB	Í]#¡Îİû ÛG*\¡… j|¸ßíP=Ùl?1L÷—Çİ%‰dDCw¯Ïôàîè7œq§GK±ål‘ËKî±úÕƒû¤(ŞŠ©…ÆKÍO4Õ‚¶ğæ] \À£ê/Y˜EÆo5ÜŞå+Éóë Qd„6<!¾PJDÖDÅVïMV·ê÷¤úlûVşƒh^Ä`HÇ÷¬Îœîñ¢FgŞ°Kµ*WŞ:·srÀOjƒ)—ÈŸ¬Û›mØT[¼YÙÑÅ®ö8”†| ë£f|ˆù<¦´y º˜°Av®!›HëQÙWd—§~¿ZsbÄıb1d”œşd‡ˆh«nyïÑı³hèEócöEpû¶1];e³?bVàßl,a£»[;ç2‡ß`N_K‚¢ğ äîj¦ñÃJŒşÒ¥éËÒwÍç² ·—‡ur^>™ùh`‰?rYÌ*ÇıôZLiædö·ı3'à\ç\ IµP@Cz>¹ ½VàÅ(=d{i•ù)Jxöñ÷)Y{Éˆ°K»>K .74‘Ö®°Ïšíxy°ûÏ
Ö²— 2Ğ T5lÂÑ±f0‡ûPOzhõ±.ûp€üàòŞµ¿‡rH‘ø¡Fé.£Np4QØÌµ¾‹¹Bì‡yW;+§Ôî%Ti¾ É²n¬Eñx¶Ö§ÍüY¼L™S‘õ¸û¾CMP«È¿şäğã²¬éq€¨¤‹IÃ¯+ú9¢ÓTñp@"b]OÜ”9.’`CfÛ²:^ØIq¼øO¢8™Mµ¬¿©õçĞS˜³Š¼ŒašÎ¤ã.£§ùHÜÛPUÈ‰& V¢&úN!£öGkñ@€Œ,o‘®NÏ/ínÆM¦è®Ï¹\†p]f3[—ÜV¢Ù?UUøhŞc$,˜Ñ¸±r#äHgÏ«Lûì›¾cş Ğéß¨\$ĞhbL.|9ÖM:Ë
pl#àa¯\îß»j&¬dùÑ	áÃ£o³Ğh<”'ÂEBnà'á&ä•Ÿ!+WA€÷qN¤pmâãşÖL¤¤\~SP#2—‘B°ìïï†Ê9;Éh\U‚±a”öÑÿ3=ÿ&‚j†0Ğ1^·w{˜¼[ÚH7³4MDÄëÚ\©—*åguBEî%ıYTí¹&ZzŞ§Q%^r®UOg‘B ¹j›zb­½Ü!#ùşx¹9ÿ-03˜y7r	jö8 «‡8´#—Ñ¦+ƒŒ×c)o@êo²s˜=	oÁï¹D­|ğƒÒ’Ş†0—½Æ÷	ŸN‹Z¤xÈÈŠŒ˜gÀx¤»í@ò^?.&Q˜Ä»ÿ!ª“Ån[}¸¹Õˆëã>…ˆ_5åË{cÜœL'ÄõÌ¸jF1xJÆTï9õóby1€'?ûFJvúD©L1@¯FM«TFŠ^„·2á£»šî)Fò*S¬„_cY”‚rvWe)“—’ÃÒ7²šL™È Eé‘P(˜c9Eïtfï–Ë“7„šw´ÏnÖœ$bÇj /Ü[’t°6_`rf1…òa5R‡Î˜]”°C¤¦øÀè+ÕäÄ£†œ:’n¾¹*»û¢;vfMW/½Ğ(ğ¬ßbëV±Ğ2àm}¡¢¾–[x³»ñåò§ÿ”©xéIû\ßHı‰zõù o:72† <2Q¥ú›Â†^ŒV\"„!ãÖ|otQêŞø.¡dËÓjŸxonDÀû™õ3!,ıÎbHP1Õ#çš¯#¹È–ëG×]#º²Æma¾—î[c9«ı¶3Nß#H¥}|ºt'ì¦®_N=g7/m‰n¡¬ u|8GºÔVÔÈİWòÇúÓÒl_àü/3‘ÔñìJa«=Ë¥Ğä×¥HíY{º?í‹°IÆ0:·(ÿe®A°!Ì›Ú,êz>W& `4ƒ>i JST$ˆÖ/êc”‘ÿ­^ l¾_cp¸Xh›æôF­ú]bÄş}Ü—ÿx°7»;ñÜf±1/°ª=	( dĞŞL®Ë{*·şÅk[ogI´®òªŸÒ |“nÆÆˆòú´Ö›ÎÎŸÃè£óx ¢èr5ªµ·~£›Öæö®ÉÃàë¥`äÅƒĞ!~Ş%ğX½â5»{H„dv¼b g@Ã"™y‘oIÈ£yùû&-<Vb>Î ]§ëßË­C‘åıñv}Ï…íß¯ïÈ
ôå‚íß¿ğ•*˜Y-Øj”Û²³OÃ»:‰µ©ú&@t4õKêõ÷|xDûQÆüq÷”QWyê¦CÈè%ÙïÅ%3ğhQ×-”ÿIÕ¿‘g,€|pÿ™üG’*q¢ÊîÙLƒƒºöe[Ñnsœ(_~ôªs<ÅÏTBÑ6Ş&ºŞ(…ê–¨-Lv1Hj‡öÍéº jgúVsûÑó„ùÎFZS#t&˜Èâ¦Û4ŞÈÎí[$ÑAÃl}ÀèÊPÑö#sÄW¹S ˜1Ïšrİ7jŸ!&aù(,.À²Óøk$UV¥ŞE™Ç•§ë0ã:Ç<6°»‘¡¢˜¸n¼jPÈóöËĞÛ|»WâTffÊ
K€SS÷ïg
‰İ“B;œ8âŠSZÔ iƒ.cMßı-n|x³Nö¢oƒMÄn‚Ù~®†Ã¾jW½KÖ+”¯Úv…ûÇ†ÿ¸u+zş+£Ş†€èí°o‚èXd*'¸;oyìdö&X* ÂHˆ¤R”âÅódƒç1†=ß†ˆvÇ*¼œÚ"M¹ÍÒÁªV³fƒ^8îØa:t¥“È˜â"o	93³Ì«öÑÈƒ´“™oEK>å!©+I¯‡ú²)ôåäO]ã¦óóï5ËÌÒ8Ú©5ÀÜ¯Û˜ËØy	ÅÖ[,ì2¿/ãÁGMô«ÖöpúkİÁØŸŸĞZ0ÈY4ü—,p/ßL{Õ£z›¨ŠÖ`9™>@ÌÑPØ¦ñïŠk5•C xXYÀ2ód´,1[ATÎÙ¡í!ù½Ş`ïŠm»ÙæËíc5_¬>´~‰ë˜ºŠâ…ùø8j²À‘ÄDŠn³õ×A³]uÃ¸*ÃTd÷YÚWÿÊ&İû§R/BĞv²€tß±
KåĞšìT" ²3Ğúh¤MÕå ²\OKh/¯WİB&)`(æ@Õ@[É¯‡Ÿj*·ˆ¤Á>¢óÓË{ïÃÁ½è­î_7.Ì…ë=ü'¸i»šÙH:–¬¹¯¢šºoÛŞ¦CñÉƒß9Ûdì_=0%şn3Â&–‘î‰fWFíîD¾›† ”u{ç%³pÔÖÃFMçXĞÇoÆp	tTÚô©5v`ÊTNfû
Óm1¤|Š¾¶ArÆ¿….¹Ç÷kõ—‹m½}såPBB×˜úÆàN	ûø>}í·Ôw»ïdK'È+Ğ†…‘”*b Óh“]©xr´M7íi[BÛ32ßş¡ÛPnm¶QÕ?Iƒ^ Ï¹®s_c%¼o:?
ÍH!`ö¶E'æ­Áeàz)No©Dª^Íy+ÙVL¦%fnçdMc"±€¯—5•ÂÔ£º\´™íáĞé’w—ÇûNQ¼ÕšBj(knŒïÆ7ÖÏ'ÀRŠj!r7AÉÚ.œHkë0HìÚ)¿E?qŸbc«/4©·¶ yÈ
áùXMõ~9K=Ÿ‘O%>æKFèRz$,éVÕàèÉ¦Foú±5ÿ¬ª‡ŸÖÂ®ÂIÇ»şrMúıM™N·’Ÿƒs¾²å¹]­j÷gqÜn‘GM±\B®¼“z¯4.š¦¬N"BÈÒ¢˜Xº÷kpñİ"]“€Üß`÷ëë1³‡ç³¡ºdNÛ?r–füëğg¨@%'ÓŒ¦«»ÑxqIi¾TfœÏü<°ç÷¤ØgÑª½k‹ÛÁùû‚f‰úƒÜZ“G–1ñ#ÑÏ79Ë¾¥àcá#¥R‚#&znŒû;õ +“Š3u~5ÀQX©!sFŞ.ñ=ø¢Bc\¼ş· 2[Ğ!
Ç%¦Å
Ö4İ;’¸D]2ÉX *qÉùáhÔ˜O…¬O'ÂG_YkÑZ('sdè'‚¶rO¥„aÌµs	e Açç’Ù¸?ŸBöß}[ÒÖT—PQ|LO8Yï#ë‰$lÚ(«ÑXh¸ÊÑ‘_$(nº+„Á¸ÅÓPíéµ…gİ2`ÿXkM9©èÑî
yœÆ¾±5­—G³ˆ–d*¼*fÅYÃ±Æ«¥ÇÂZò‚!A0¥Ïş¼‚dêÖÖ»ÛİÒÆziœæÓƒëş”ğP¸÷™Œö÷mkì€Ò’ G¿RY˜Áû°blêZFyh@+6QÔèäÓ°ærœ1êV>Dñ‰Z¦»g±Ù=Ñ<µìˆC][ıõ¡”B¡|¾rš²ì¦µß‘ëDXïíùûi±8÷Ë›/1 åĞP¯ëÀ'.NVİüY»¼€isò×nªĞ—nåÿB¿÷OÒq#êº|Y¯4B\ÿÑ™Áfÿ_¶ŠpíxG•–ÕĞê)#•búüXÑş&çó·Ø†:nÏ[ÆŠİ8?Ên-ÈpåÁ¬®…Üumœ+4*ß<ä¬'7·X¢72afÜáÚŞY\Ğ¢ô+ø±R~rêoF9º¿¼€»ÿY«¤kbÓèxa¾¬¥´×FÓ1ZôBYLHşö)ôÃ£FY¬ÙñîAKrˆ	,áÁôos¡p~¨âá†²œ>æß>kôŒsnÆöKœËŞáıè^äH”*mp`Ñ“¦=‹Ë/íb‡z¯:;²gØØT©ãn´ƒD[º…*òEIÌ×´5Ê¾8)üR€8¼;´=f@Ü(9ë´-œRˆ¬ù"Exno¤ìº.,º/èí¥³R]m¡ÊXçbWì¦¼§Üç F1CmÛ»({­G‡ú+
t'lIöpÂ*d ›ú\(cT6^Eê©™‘š|ì°c¤Î	VÒŠ) }¬ìcW&˜)¹}áÎQf‹Ez|&Í´xw‹òh=Fµ®™.¢–[€”ä½Äh>ˆ„0QÂ·²ô¥/”Ë“WÈJ#7ŠC±yMylÎNãÔ Æ§uW ’ÌeØy³gã^œ?‘5ë’VB±YâóxÕÑ¨a0ÊOÕk˜Ş!ÿÓŠ6Û("cŸÏ}Àˆ@úVqÈù±à[ËIº“}›§ıOÿ6ˆÎ”¿ğOÎ2Jè
-DàušEPÕÂü\Ç¤pd¥6Vlj—çb5„üÀİÄ`aHVŒ;&¯u[´v¼èéSX?ÿG¹ıìn+‹'†jñY	ùÑ;.EÊ%|ıéãÄynáh+…*Ñ;Ì˜¶KŒF*79y³…ÚïFd«õÓ#°ïŸ¨h¶]‚•¡èzë¢p¯Kß2\ô2Èœ ?&wqèÿÿù¦cyå€XUŞÆ13¬n†ïâñÉ”|æÒq­‘=¬ÜÉU2°¦á©ŒBÊ£;håÅŒsÒ,Ëœ*p2 ®ëk PşÄ…“ô3K¬ğı©rõ'Ø£“¬ª¯Á±±o‹ï(i©§«PŠëÌJÍåY/hµîõ·ÿá„¯—PHª÷„°Nµ­Hğ]F	TNÓdt¸IñdÃá|€£Å!«ó—şãÊ˜G3ÂCKv€„5Å:ã2'}WÆ´bÇü»è=o¦0`å\^ÆÄ2Gw&íÔZüc;qf¼w¡ìÕ,,%
{?¸ø¸š FdÍsğöéİã÷kìÀµPÍÃNĞ½*TQ¨ÁcH%DT"9ÇCù{R	ß™¸ÙÑ—Ó.Kù–?)\9û¦–ƒê>¾ÒR2ó™7áƒ³°vÁïAnY"xı7~Å:F{87¤”ê§ˆ1¸6Çd‘-'«ñØ¬Şˆ^ydbà½g‚:d€+üŒê‹b'	Í*§å\ù½ç•(Vs®^;ö8r—HNæÎúû«aÅ/;PŒ«pª’°«¢]c(ÕO@œ«B\-Ü+­ëËŸİg@ºj),cpQñ"wæjs§«¢~ƒL˜il­ñdû„)›³P0/“-‘;>ÌÓvã†.v+®Şí3+ééÁ¾s$Õ“˜J9$[èpúµæŒŸd»áCÁrò@'n‘7 £ú4+î”Tlëö18¡™Õ½'NØ£î¿ÍŸgD†®©Í&~kvØ÷02<•™&¾˜† ‰4‘_ÑË6“jØbR$j‚E[•ù½Ÿ“UıM*Wêşhİ…·Ø2»ÕË¢—5›·Æí\¾Œİ5í„mĞàë`2±Ê÷e€kâ¡"Ú›”(9øEî§uşÏólm¨a‚¬š …Å®]9™¯|y£Úš[eÙÊ~û”'ğò®a€	€|â-oÄf›]lµí‘Y P[úUË†EiaåŒƒ¦¯léÑ''YŸò¸Ÿ;¾#	‚|0‹±¤cæÃê—ş†¶_ñ×s§¥Ú‘Fã:­•á»Õ¯@t²ÍX,˜ƒİŞ¸w mrğÈí¯@ùv/H×y39X F‹}Íé.hqi£<mÂŒ‚A¾Øo?6o[Ÿ4r Áº= #ÄBUk*Ë«ı”ïÁ'Ñ¹*iº¢FöHWX@îó+TŠ~W­Oùšú$Ñ­ënéö's¬.ÊÇ[âbœ¦wv9Aœ36óí* ¸¥‘¶)*,!ùÇ+"¯S¿ÑcîìUcZí®g¨ôàÅÎ¯ úº’¡ÒöSÕC§©ì™Şß‡ı°}Dã‡]–g@|ŞêZ.è…×o~’üŸAªf|¡]Æ¹…Í'|K˜÷æ_-ËÍ&­šéÏMš:_7§Cÿ”Táâ„A›lM¬Z×ÙÁƒêégCĞ$†ù…&D—I`‘~U&Õê?H~$KöZºv9«â˜N&.'-Ë½b^déÀš^¾€=ğ•&¤d?lÄáˆ“‘ë×M?„zh4G'/Î}í†ğ^>3FãÁ‚æp‚YTzÛH²cKøG<”˜¾Ü×Ï«àİ&œí¸šÊÚ`|h»ÒŠgØáÛÔ¹´)Ùêz˜1ŒÙ B›şÿ•¶xÄ÷€I.İå÷9jéû¤ÄLºfã‘É›³×yïÏDhQİ¾Ó!Ÿ=¤‡ÕÌ¡œ@Bü”Ş8ïdİÃ{íÃ¥î.£³§ÅœxÈÁù@˜f1ğÙ6åµY™Çmã/óõ4)Ñcú›õ2½_ÃO6€Ìî‡Ïn4cşôˆJ«Hx\|ÂA5TÚy´LşS4Ò3>£`†¹Ì0'éSÛ<l˜¬V³Í“O¦L2 ”I1– ¶`“/wçi0wÊ³ªœµ¾ôğKÅİa^³šûúU}`È^6ÓıƒPÀÊmfXÂqûDÜx2ê™Îãáõ|ÁS,åó…‰ h®Ø»w£|E×
˜ó6ó¿ s:C4h[*—C–9£Àµo‚ÕäŠà7©ü×¶z›)'*8Deò˜‡¡-('§Ïb!•õşY˜á¤L­‡_&‹)gçÕâ?h/<äIoü„r”?ŠØ`Zÿè H±Õ§Ã ·İ‚a˜ËwëÚ<Ğ©Ğ‹úZ!Ï‡²H•„T‘€éáòğ¾éH¡K¡ª’`~gğ}êq‘71*ÕüªeîASı"×eX}t8¶$Ê~Ü“"ZŞXAkİ6|I3qÍ_S;cL¹ÛİîI/<øwiãµ;è½°¶Mètfú²~Å>¼Ä–\*ŒÂ€ÒÄ^oö€DĞÒ,Áb‹!²¥ÉaÔÿv[„¬ğµ‡0è*Ñä1É˜ª…üÊ1ˆ¦…ıhÍjl5[4É"AÀ,…K®m]k˜k¿’g?éà4µØÙ
}OZIm6 «jÊÍ½!(WüqÍ™Î5Ä[€¦UO.®\¾.ÄtoÌu•í‚è0ü@Ö/PÃ¹â±”Ş}:9·á7È.jíÖ[;¬¨	·»÷Qİƒ8–ÊYÑ"Õ327Ñk³QÔººğ‚ƒ–—0Şıb'ÉÒ0—ªket¬<ø#J5?ü>iÆâ‰õÈÑ)ƒ€5Œ{O¿7hù1«ÿíXÊoùb8¨_é¼n´…6º‡`Ö{²8ù†\›Y–¹¶AM/OD`ÇÉ‡à],:„EHâÑ>fà5#ï€š0´/>ğ{x•MøEµºn<¢ïºÖ·¬™“÷UÊ3É<>Ruëtß¢o«KWµm
ğau6ÙxX
@]Å€¿[&…	¯Q¥D ->QÊ
™u‹¶âáJÁæ,•èğƒ³+±ø©-§Õo Ó ¬Ä¼Ş7 ‡»şRkTÎ¥åzáır… e*5Õ´Jòv(¿«@@Š£SØ¼ô ûÚ°Ë£1+­ÖŒVâíe#Ñ•Á«¾†º¥BWŞ÷½æø\ğŞóÃÁ’CZy¬‹F: 1òÂnşzQëºÄ¿¶ÍP|fK(Ö6Upr9—ŒÛëé»MrY“=S oöj§ƒ)†UV4h›šÚUºO4ÅƒÎ7®*ÙAñİÆ¾94£¢q  è×òñÊJÔjdû{³ûÒy†’­²Ó`á\ °„
wÏKQu¸¶üT‡9q>˜â¡yFiĞÜ5z»ır+Œˆyõm-îíªS™Ù6¤ÀèŒ-‘>D2fô2 ¿>í©}&?æx‹Ù£Á2f"ªĞö§éšºØéÔB]ÿùšå·ø¡“mïlæujë/Oïˆï‹Ì¤’‡K\ !×ÂşU1]³z·‚~ñ¡âC©DµÕÍ(JƒY¨c†w4H;fæ¸Î¾©Ë2LÇ]‘åç\t7Xâ>{ß¸è÷M¤†ï+‰q£ÿFg£IV:€“ÌÌ»ª‘?mÕ®½U˜Y*…)˜c
s½Û¶<Â1õX‚iğˆ+§n®ßÆ !÷İ'ƒ­é	¹6h$ß“áSÒï÷ûz2A-ÚíJÂf&Ì|×j·$C F°Ù8<Eæ‘#:ĞòG¥¾i·Ë³šU¨Ep2'³E)4.K&KÈkÀÖİÉÒ}÷w<y¸âÆ³}n|œq£ìQáçÅTÙ¹hÛ¡‚>,!Ïj;ÃÖ•fLj´A”ğêµ©,Œ‰	ªbŒÄ_L‘®ÌŸD©\ÜRÙèÂ´p#)
yÆ±BxØ&aqx>¥òã<'påğ!=ı!ØUR`WqFB‹¨myÓZtÊ©İç“&]„÷T¤0¾ïËà•Fë°ª¢–ÉŠ©O¹("äûØé*1âAYù;ô4yÃCÿÌ¡åO÷™Q¿Mö¿9Kúùã©
4ÖKDx)wÀM¹ñ#+'á…§QÚ¬Õíöß[É,®¯!ÇoP‰úN„3»ÙÓú?0÷u+Åö·t½ÖÒƒô>=©GùHéTÓTkW¡œ01ExàfS9’,Ğ+ÓÀ~#8ş¶4ª§Q7t,&òû¬/jz·YuMlOv¦0Òc¸²ÕTt¢İFª ;J†õ†¶¢0qQ¸ó—¢×WöêtĞÇ*\L¹Ñ,s÷„§Ê„TìØÀÿ#@NLBáğsP+øÃ±~ÉáÁ;—İé®ãmôd/K7ËN¼’¡âWà]²_ª6(åÊ“?G—Õ„¾ÚX\M=ø	³LÂH÷?pQÜ¡>\0Pef{]Të{Z˜úÍ
æµ„½QÂè‚¤&1ÿ-”›åêhÙõ-å0ê¿áºC%^ºyöŸÖY‚äV»’rÛ‹5ÅŸM˜Ïé
ù>¤·É^¸5|Ä—ĞD>á«“ˆƒ‡^ÖâÃmaúY¼‘xëÆq©dÉá†M¦ë÷<'Æ* J=$5¾ËkYówØÖÏÀÈ‘§J‚p¶Í!0'³Fğî“n0iê·ğ='ÈdBã¥:wC¥c×Õò‘U÷#€¸!úÉD00zK £ŒÄªÛ<í¢îh)Ûô‚2`bÁÂ«ÊÛCò‚ĞàiY…s+ôÓjy$~ç6ÜmM9f÷\ˆ¢Yon}¥{
Ÿïé²Ñ ’"“òZÑækÔxv»ò¡‹ğCÎàR	[«]s":m‰¡¥pª‚A{5‚C_SæÚ—‚OÒ’§*Šóxªƒß„E7³ƒÉ÷»~9pæ×„8Ì÷ÿ°¯ûAßlq´? ¹[§¬‡?»®òq{B¥€Q7éc‰B¼¨²åÏô=u¸ƒw? Ç}»±ü±æß¶‚goøfù>1X±÷Äås®F5×]`g}»ÇØbÑ§Z‰w¸áèl4÷ÑÅšB_rA¥ê×ìƒ­Û¶–×ãÉı¥W+m© ;k$J´Qk]·¦[R<´­{å£ÖoC=Õ†/
|FçÌºŠF”QÊ¯;…Æ“ØÀN1™2 “‚¥yÂèİİäjÂ™ßµ#}¸×IãOz»5´ˆkÈí|Îõ]¸”ô“ûµ áˆ×JÎá$Ï¾¿È€]×F£´^ø'0;!·Ùªº›í¶Ş[tò«® Í†¬×¡âO“EõeQ&z«è ›Õkz!IMË¹Ü¯=İ1}zl[Ü‰§]VXŠˆo *¢°Ö–—¶™ä¿\™Ğ³"‰öü„cŸğ’ÁĞv+ğÆ—Ç‘ò$+gF(¤ÄMëéyºî(ñ¡±~Ë¶$r˜µhş‚…-à¨÷åPINÂŒoÿØ.ç=¢ˆ Ìˆ[;æ¸Ëbû‡bÒÎ…¾äš}³?IA,©!$¤—›º-z%xÖÍ/ƒ@Cysõ\¢ª0Ë¾ŒJåUœ=áù¶J“‡cxÚÎ“]Jse$Íîê­¼dÎU; ´v+«{kÖÿ^éÈ¹c9QYq <tá¼X‹”0T§fêÃ¨Vh¯ºÑ;•W˜´`×Òí\7¨C|Ê~ i<µ€{·,‡Ô(o¹õVRóä°Z	»æ¬½_õÃÑ\£ùÍ*jC›$}†=ğT¹}zUªùZ¡×íåGHqh73£e5‡*z¸´•Ê(£HÚ é€²6?ùşÅbÂŸšğÌèXbÄH‡¦Øj1¤G’‹$K‘ToĞ'Ùíú×ÍìM}-EÅxÙ”‚»møB?ôí‚½åÒÃZ ÇQÉ «A10£ıáZ¿áú¡Gµß…5†"òmÏ³óJ3ìëìhBÜÉ‘Š` fó{>€j™¨”ú˜áÙ‘&ê3)ôğJñ`˜KhĞŞ££}¨Ê/ }€rOŠY8ˆı‘2cTåcó¿z•Lz˜¡¡™ğoÛ¸ˆÍ-xL(\“Oùéd*
È·\qÛ¶)EŒâSÕpİ/óŸ|à'w{$ÖëùN6q$/Œ|—
]‹åvQ&  qÃYãº< ŒÓY¾‰é‚o›>?}0”µõÛe;—=;ñWÇ‰xoCQ­ry0SjIY’âZ7êP~
ˆUNÉíH·ú§‚–aµ]«ˆpçÜşÍPs°Ùèz8gšã*2ıîÈÚÓA Ø0adîÓ³Ş”:~`,²51üÌlµ³_Ä@Íƒ;‚ë`®c‚¾?-G³¹ÌşÓG‚»÷»şö÷ñ6WëeºY¿Ë,UJ‡bÆÜ‘3…XÉÔ„ï3Å2eİÅ¤j×    7<5Ì»› Š„€€åx*±Ägû    YZ