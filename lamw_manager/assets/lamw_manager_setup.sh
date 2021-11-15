#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="978864428"
MD5="1b9f4504cea0c0ebb2b6fc8e95ee548d"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25000"
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
	echo Date of packaging: Mon Nov 15 14:32:51 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿah] ¼}•À1Dd]‡Á›PætİFÎUÌò¡¥×±½ ø¾2k%ßD[`gc”1‰Á±< ¸%9£æ!f5’¹qg„Ø2LÎI6¶C
i~hÄİ@ôäw¶
g„êQ?‰%}×8²Qİ6:Ël	ŞÈàˆHKáÕ°HÃWR&<tšµy%=o›K·‹´±gùã¼ŠhTuP^¢‹{¥!9_Lôò
¡ÆÉÆbA³ËÈÚ!QËçË‡
vŞ™oš«
y¹îjËbl?F^Ø©üy!—Hæê÷‰JÎ†aö¡£N¡=°h58¸ÉêPZ1úÔTÕ‰'bçSº¶ƒ)J³ì°Æ™òlCãöê>Ä¢œ"}çô?sßà²tw7'a )öà–9-/°¯)	¾9ıRp	É9@è†âFê-ãQşM/öËØ|o/$n£PcëQÃ)îa\¸ÍO–üÿ}±BOx‹‘v«‘d<Q&¨ÿóÂˆzØÓøàBßó³\|@ı‡êÆ4qËãc'SĞ Ïïè†.)'¹)@@x-DŒ@{à˜J¦v¿ÏÚ‰+ëZòIÙ]s—ÙT¹€;¸ˆ7ÔX=ô'Äí{ÍVåå‚/Â°®W)Z[lúàPøİ¸•+tÄ"ôuwœéH–Ç©ß—åìğ@÷4Ë¯¦ cdºÚÅi¶j%è<Ş¥ıÁÜ/ªß·¸©âKéÓH%P†b_¨NÖñ…”§æçj±‹ª²6ÈÏy%óEšŞğ^ç„i¶étIÙá³åØT6µp0»Ë5hêßïİ }Zz6°İx›%Ã@ññ4;kL˜ˆ6Ce¤%†ÖûÜJÌò›œÅ£ëó†8«	yg·ìRÎ´ª"¹Sh¿òíÒûCÍšõşÂäÌ|ìYè%…¢Xáõ‘Oá¾9‹ğ;ÒÑ^•ã¸ª+6¾P;ŸÇ“"3ğ]øú©ß]ã±A ĞÙ¼E¸°ÌZÁN(½ùuêÉ\{«è»ñˆPNa!mê—©usP-#4QJTiu¿uHHç–˜ÏÎh=†ùE5ÊÌX£ğÿ˜¢è±IÂ~<-Sa@i8‰m^}ÅiüŒŒ}iŒèÓ¯‰a4gòÿ¹¥jCnCX¨kı{¹©>ËVƒ‡ 1¢ßPá’Û^J~;¬¨u'·mUŞ°" ¨œßë^réGft.]<)áÊ>ÒÑH–`>µÖÜ/)Ä2)ŠÔO]ôA©e×µÒ0¢†Zİ¼l°ø¸ÇÄÁš±ÕŠØ¼¹ÈGæÉ“†:‚Ë%¸‚‰¬å¤Ï=ik‘éƒ²—=ˆ"ïŒŸ¾Mâ,Ö‹‚+®÷²P5éöŸ³À¨>ÕÉÊE| +TdrèÉ‘ÕŸ¢¡"k{*•LÀgg‰@?Ô“X¦ó	;;Hsx[+µóäI€±ïˆ>VÅU”ç¼ò™Cï²Ôo;Gˆ¯’‡Ñv™ÃĞ•é)®* Ï
öş««®zôK7u@O§¨M8: „p–?rå¥Œs¡Á’²S Ì'
<[vNôß
vWmp“Te}±ô×xÏÁº«ÏÿoGÖ6`áöZ™[*¦Ş?¥AqáĞËÄŒ®äİ1’–­ívàˆ:‹£˜mb¼ïÿÑ•=NÚ2‰¯aÍÿáOäïÅO¥³veâRƒ¼Ğ­åÒ9¹„Ãùš±5‚Igo´ŠyEø·2]mí™–—¾Ùkñƒ«9,,GA•Üº„/0(Er£ÔY’ÜW•`V|¨.Æ`a\72¾øÄ7·€íÙ³z?4¤ôC(2”M›¼©4?á®A0SºÈïZI¾ÜnÊ¿ú½“qÎšl‡şÃôâË’Sñ†oLMén¢¦vòØ¡\²“á­¦Èx^ô1–~Š™B¬]'s6Z#*zL49ôÀG„<°âH½m8´Àæ¸¯Yc<ÈlhÂùÂ9¸8×¯  °K¦CzÎßSDíÆù"ıu ?»)É†xß•ËÅ¢/bËE¨İK‚-Pƒç«ì^Œ|Ä7ìösXàë9¤VY{Á(~¥5Xl×IîÕ£Œ(&­0G^«qÊw‰I˜v\J)ãø?äÓx;İyG¯€mSN*e«”¾âGZ¾·IØ¾U€›1‰F}H¸l_ùJ¼ğí0îÒœ¬ZO{Œ€Ú†Y=…ûÏºáeÿ ¨©L‘»GÒG4#j?;Š3Ğhg’O_µ$¤İBößä· öÓøV'Vô<8nÖ‚%ñm&»^+ÜqYå%ú}ª¾L×@Â·ÜDGtYäñø§†pæ^1P¬®±S5;Í“$ş¿1Šó["ÔItTóè´¢¨qé*“ÃœüK£†Óàñ@ñ@Ş,;V°
Ä„ü)A)dqˆ)É–—½1ÎW·ë3,$Ùë>4mğ;Û­™Ó4Bø$âƒ‘:¥ö_C1ªì€k8ş¶pøîÁ>fwP-BHÂL‰%Òe&®0ÖÛ®uñé¦Àƒ1ğ¦|Ü.SÜrPMQ¶ÇFN8WáÓj–>µò…êÉ¡4š*~C÷LX
 MPzÒ³÷_ÂlP(‡Ğ°Û$9Ø;Ã‘ÔŸFÔÔ±Æ?j«tk<E#=zèÕ(f”à×2duìw‚Éš¼%fÑ¦š `®qø"Jmİ­3DUaq:aR±)Õe®ÃneŠ«è„NÊ=~ùÙîÛÑt{ê‘ï6‚bIºÏ¥µØ²†¦‘CfÿJïÈ´T2/=ò~ëN°¬¶oCçÃMñ:–twâ¡ÊRß¤AWO™ËöØd±t:Pv€³ +ÅŠhcÃîk`…»z¡JüY!æC]èf3éZêU]†e~[¯–ºî}#[ROˆİ\Vu6íÊ<G]`|Sw¼ÑXËi…€¼˜|ØZÄò¼‚ã(,sf Ë-¸³ıS®èziér¢h†çöÏ+ßÙÊ*wsöa£©8 Ğ³N€9z¸…ıæĞÕÌİ><wI›ö‘qèDª'ĞÖí'NÑZµ*ïLİzğB¦RvIS«BñÃ£Øv÷øÜ¿øÖ@@=ê)Ä©ZÄ<ƒ‡à2ÊL
!àd=^y¾»Òßâëÿ5‘ÆiF!o:y+ĞLO]eP¬ºğVñáŠÚ± ÕlSµ´.Õ¼|î'Ü°«j/¯d¡SÚn¤\É‡7§¬4ê¨,&Œ6ô.u=æˆ­àaxLê95›ê±ˆÕ×ˆgšC…é…ï8Nç3ÎŸ	
œ,ÄI¾›ëğAÓ¥Ã”©€¢¸Í¦E[ÅpIÿ‚½ØüÍAêbqC‚ğÉÒÚ°Şk¹¸'¶²D½J4Ÿ£™q;º“øE!áçÜ©dù€\9P,Yxp·5–r7ÒÌKFp´eë …Œ¾vùnŞº¦ò­OÛÍÛÆ†öéx¡BöQèä'7¿U®ˆ1¢7ü±’şı¬ÊÊvøäV*nêWW0É8!–uzÃ†s[}¡¨çÙA7ÍÑiÓeßG–ƒ¶·.=Nß²³F°òŒù‚Á_²O,ûê‚ò"†JšşVKˆÙPêÓœúÏk%Ï|÷#¢B'Œàä©µ¤şpøuú’Ì!~ºJú"TæuúgO®Ç£ ñÚü3v$ØN
å|à–=’§¼ísÕÓT.ËeWáçöU×¿3à¤#[È,‘‰oÄéÏ_º9cîíà‡ÎİßîA0³•ccı²6_ì0¹"8—é$]¢3˜QP+Ôír¯à,XôX§ÒBüwU"¶Éå«íèÆ«²6J²è<- V? ­‘uşöëSt¦Ô7ŠTÛê0U·ˆ|:ÖŸ?gZZ\ì:C#ÁéM4<û}úp€4³€ruâ	ÏÎ Ôi€|²±˜D¥ê%*ÊyQ &H°×7uCâm÷ŸF6\4’Œc¨‰Oåp6?l/ÏyDzƒüî¸†Újh#f˜G7FíYÌ:ùm\ÑÁàá’‹@íğ÷8%æÅğPÅjWËĞMeÑ#Id*Ş@SÖIË¯	´{#	úÿ|ıâOKò5‚îõ0Ä
Ç4tu¸ã´³ŞTh„j‘ó„¢{«HÍè~›x™a¹rÉß	±1Ó"Ø-‹Ã.ù~g©‰Õ…œòİäuÊœV¬chîİÌƒ6¼çeoĞ–‹CE8õÚ5Ğ¤€€¥œÿ.Ê2W,iÃ]œÓaÎ9½hï×N;îŒÓQy˜õHK_ş¶šMàáiy¥ÍziG‰O…Z1 ùÚÆ8%Mİvı¾Z¥MŠ¨›åµÈymİ¼Ímœ¸d3Fø£õ¥rÔ¨b¯xx ‰Í³t1JÚbÃú%>»Â‹œYš dƒ”Ï]Ã"Ãÿ7,úŸJ!zn6Ë6U“”vu÷t¤…8˜9Êïœ.¯ÆX9H÷Ó¨e~™!½œÀPbRúçíY€±§¥[SIZÈSi…qÙ0	’rà¹Ÿ·  D#n÷b[¹eï¯ç
gıõ{ >l¸Ía 4¾ÑL²À|RZØÌÕ‰5ÌM%5ÇgGß$>BK¯ãâ/ àª¸qX»—]…™SÕh¹¿pÿß¿ai	«I¢Ë×Û›eŒğ~iüĞQ.MHÜ!eŸ×?‰åşSà’Í¸áC	²™†!W|Ò1ÿg¥û‘RÌ˜7¦‘O
ÉòJ~Î\Vj¨„|Ë‡Û5?¶?^ş¤zfrù»%„C&ï'Ê˜­áZòVB¹ºªá!‡ß`Yz…ŒÙ{1¥¥Ñ:)1aÓ½,lDÿh
5ÎïS³h… ßêçWéƒ+îlÈ806Êú#HAÓìŸ‡îã 7“ùFŒ°õœÀ§Ü‰ÆK>ÿYæ.h 6ÿc÷Õ×¨Ä‚ó‰“]É×Î÷¨IX±,šidfÎ¿¿LRè¤Šìãø(`ZMÈÊV»„$MørÚÎ³ ’bT+ÏÓA™`Ë^Ü*øĞ‡EiöÑp•È
•iœ5z):·Xë:0bc“œ)ÇZJ;±`õJÚç\Ô¤'íı×m2™)/{å6Õ@ù“(8 º¿~ææ_Œî–øo€vÌœzŒÇÜI3à3JªcäÛcÑ] ’„-ó† øÁVA’Ğ¹Úo…ÁS½®İ3NrF˜8VŞVWóŠ®Í"Ş™Q;ºA°™vôt‹õÎS@bˆÁäçF2!@¼™aÆô	ñL¢*’^^îiÈz8â
ïÏ õñPËÓ;F€s	–Í÷{’SÊÌõËÖ;4ö~}õ€Y,"Õ‡;û™LO,Ğ›Âº<á§†E{¼K€M¥@¾õ!ºævÌÿ™cA¹©¶ç!§”äávz^^‹1pDÑk&4Ï?ÍğÅÜœÚ5®×dÂ›vİ÷ Èà¥ëú±yVR•e”=ûİ­S€0	`³|^ğy±·Ìã ¢›\ÃÅx½“ÓXÜtù<#Üu^y)Í£³ã0Q•ŸÛó0¾öÌÏq0‡qİ7ÕİHˆ%2Üòëm Ø¦òøNÅÜxN9Ê NƒŠ·ãåş¬q‚ÂüÍ/"éÚÛCÈHŒ'áWs\ØÄº¿àu’ö™<Í?S?6A–As 1¡>Äi\hè¹QÚ+á[‘gëN)élë…ˆwÄ˜|õlÕ9ò)ò‚À,¾-«ÈäX9€0ÃkÿŸíCÙÁ.Vñ–šdätRhimmŒ²šl2L@i_¶Ï²Ÿ–5ºnªúF5Ò»•Õº?ÿÏÙª©/õúìE†ªZ§¬îíPIC<×y@àØ:«Òæß’:hSíf‰KêÙ œZ‘–³LX+ç’Æè´?+®;f3£pÊ9]Ã‡¥ÿŠE·g€ä>2Í£ı—]J¬2óôg¦JÎ(”öÄâ1áœö’f‹=Std»ä7œRé“ŸäsjíÀº…Q§‘[Ö†ô‚I	é¤c‹;ô¨OÇ}¾ïZW­E_Vt’1‘6(»ÖŸ\|¾âfÿãN˜Cuq]ìd?E¤BiÊã|Ÿ÷X¼
¾S`2@æ\UºÜù	ÎD]3ÿ_@G"dAøt¹ªD±—ËrÌ(k KŞ!Ø^œ9ıÅ¤£)k—¢¿Ú×†ƒº›“Y°{™<´ïÄÛ´ÜÑW›QïÎ‚eô}ù­H°©ÁE²O›\8C=À?I‰¬_7´¸|7aêt<0Ìàò/æ\ÜıBR2ÙPYÔ¡ıÉ3T	¾AÕĞ'àpòt1ïo?—Fu–ÅRXªã¿äIìV;â@x(¡$k¯
lâ,^Î›?ÔÈLìë¥‡¼ù÷J}×«z5äwÖ³AFR+¨¹zûÕ¡†ôÑYî›V­Õ°ÖÕi…àwÈûm‹yyè Ó^ÈÔ¨6ŠÖ!U.}¤{}mêHTT=wjÿFğUÑ&VÜxÄHŸhfb;Í|)»â®pšÖøåëÊoõ$ÊZ MT£ÜáiÅPm´4šÌÛyÍê©ShvÑéQç^=4^;ğ¸NTfòÜf<ÍëË—c¾Aøj]p0æ,eëêìİ®xAxÃÚíÓu_wâšúà#),o "ÄY%{öª2Û.¿ÉrBÉT?`‘EõAÁÛ‰ªÈ,p[®DÑh—ıç{Â“±£Ì>­;ï#7‡•ç¢‚1fÔËm…-:p<vOõ»9û\Ôäè 
¦ª»„•ïPOllnÆ¤ÀN¡›Ûx:ÕØ¹¶J”‘,C·O×µ\¤l®·´€’5•şxÀ‡¦Veog/ÅàŠ/
KU|âµw´1Lu]dÍ—Wµ[Œ9LOHB6åå—ôƒpÖ7¥•e´YÀ$Qyà2HoĞ€iâÑSšÅ€¸„±¼™•¥ßœh'R±ë¼
fA³>1H1¹ÉRî3¡½Gï_ Ã¼´5À×)YÃğ~K±YœÛ½3ß9¾äSƒp
ÏU_éE2—g6ğÂó—K…-÷3ø%¸;Ü´P¨ãÍVƒñ.wËêé9Ep0™(§áz5?`€].±Áì'¦úÅì”„UYŸA8¤¬¤­- áÓü‚”Î!!jGLmÀÒÒ×¸KÖÁŒ^2»ƒ–§·¶âin‰ù@¼@Ù!rT®ÁH´G‘pÆâĞ\J5rµ0¾Ø„õÜ’©¯vkn*,JYã”$'5O%BÚ¿q»ÓÏ’#>/äÙ?SÙÕ ÈUÇµ;!ëeé
ú0ZA:üÇœtï9êY³¬©©8uºï0«n¸bøpØË•ƒÇStïH+ä³„4Åº›xåcâC}‰9³pájéüeØQƒ]ÛïfÑó4¡y…sh˜|d¡I{Ê;N{ß³ş³-EÏ¸¡öEX¿}ŞÚ]lúrmm ˜+÷#.y¯¨_.daÜ]U—¿J7Ÿx'÷¤Kß×‹¿ª‹svÎ¯³ìwùn‚ì–Çj3†glãØL‰çÊŒäø§c's~û,}—ú#RGèÚk(±4ˆîŠá—èyÔ½Ü—qí:Ùà[(Äi¤A›=Ú›££ÜÃg“…«Îë¹  n3•ÈPÎPV7Í>\ÕÈªöÍ©ÃŞJ«xœ{úFË¯$Vó^§§¤næúÜxéÑòxÆ†|6¾ÿ’Sù9m9†ûx/a[š¿·ciè{Õå
bz©°ö_öÛ˜Ï£±†ÃÒÔ™*Zn¾ªkmĞ?âYYg‚·Q¹±
_RBÊ‰¬'¸U’6+…ğó
ªîÜâ`§l‡”‰˜cºŠàÕ¯ÛÕ´ëL¬çé¹·ÿõøÍ©=A[|¤L‹Å/Çì‘Ø
}9Ü&Ô°kvFÛi’½Ûo›K±Ä»qwÛ
H}>Ãtc„™g :ƒï–OL-?®eËİ#ÒQ—R6ÓNR¾)Të8H™ZwìÏgü‚Q1Ó°±ƒÅïéSü¼«»ë[Å„,Ñ‚¼¶!Ğ¦šbWŞ·ı³—à³« ¸äM³H¬:éÊ‚‘–gåäÈ~™Dró´‰V«ñ™ù– ñG¥zU–¦ï™&\+ğ|¡Pº¼9Í{õ½ÿŸAÂ‚
jµ†ş%y·Áíñæ¡?å!™!0¢Ú‘ÙQé*œ7~—¹åSÕ¿™CoXZë¡I‹^JÙ­ãlW
áƒM%ëVŞi
ÙˆhŠ;: f–)Eëâƒ·Ä’ø¸ŒVæ¿n°H¥Eaºû…š9-È‡…×¸G<ÔÚæÖàT×Ñ>~ĞÉká €g+ñ$`¾±IåëSÂFX&Øöı¨6Ï BÛH‹«Øµèv¢ÓshóôOøëNÅNßß^ÔMÂ’TvšËØ8e—ô$İägU©AğòNG87›
lÆŒ=¥Tï¸¼W/ÆwˆjüêWŸ*Ë·ltƒ2‰6aÊâŠ:`õ+nL#­Æ©+x È)¢ª°‡g¼Â5[£GÊX µQ~gêF\D»*GT–€—9ty¥óZËuªU: ÖÔ–‚™aUu¾…ƒÒ¹ÅHÄO@(ûV9O×é~à-¸xÜgn2ÆtzœMã5/~,ßóÄy[1ª†WP?ZÈÏùVÎÊ†ßZn£ıäbåïblvˆ}t¦B5Hß9Œ½"¾Ó[ÆäÍåNoê…¬$ñ",mí€Øğû )ı}BR£&Bÿ¡±4aG›ıÈ;Ì¡~À¬Ş¢©qñêcuW[:ôò×@CO…6>‰+hôr˜’(/FÎ"8Í0²Y7bnĞcÅ0T¾f•&Ohõ›$t­â„÷Â¦ÅU’\‘BB_{Wç}‰\Ÿ+÷£´¶š™"€	s&NL)"½äŠû§DìÄé›¦á¿íE¼(j;9âæ…‰ĞRÅåø4BÍÕ“;ø.ÍÍ—s‰
¢™èLR‚%"xF7‡UŞâ6âà®Gƒgìäñ¯æÖ÷2wÑ<œE‰ñér®h¤ @3˜­Å‚ÒşíÓ¨.ÊHİ ¨‰ØKH;rëê!	ç££LÕQ¨'åê&Fé-}òìÎÏ™eU¿» îòó‰_ Îáo¥Ãx!Ê€^ şxnYuÌK\«©ÇQøPº6‹¥–óYêòTeÍ×Ÿ‰2ç’C8O_V´oB@„}±½¬+`¡(ì,ñ¦¥^ªõå©¤Iîı{Òçêî/X:ö:YD®yƒò¤,°i¿+á“*ë{„?‹ˆÇÀËÅ}¨¯·±aöúóã]ãè¾Ùb¾m\GÊ-p¤	Ãn"À+ÊtÄÑ‡G1*„¾ÌØvÂÕ4`OÃŸ÷@ÿÁCĞ˜¸øŠŞˆ ’ó@Iş×¢„”—ÃT¬‹ø…dĞ¢l·ä) gtÊ0Ä	#"«©MŞà½èû
[˜Û‚Tä!n#ôŠV¢4ºiN<æ ItŒ¯tÈ`ñbõúŒOò,$Ãú¶säÙdÂFÛñImtè¥Ø@VIàE%YÏN!8»‡p9|ŸEúÜˆa©ÎJ{¥ãE¨)ÙWŞŠnÒs"ª_.¶S–n'ÅîPD»DvÊÄ›D÷íµÍæ¨òG•[ñe¬“›\TVÀ•‡«Qà?şğJAÌ7Ô‰”{‡ĞBø)³‰ŠÍ.‰íç×=ÈÍ·®",Ë’\Õ_Ê$¼ğUè¢×ÏéøìÔ¢}eê†B‰¼Ã<ÓtS_H6£*´Z‚ , &¹ûÛu\aPyÓ@ööûm°äXwúör*»©`É²ÿ!|ñÍşV¼ÿû-™ôd‚‹HñqoKcMn¤İ½Ø¹lÅZr4¥B¢ >â…ÚİÅp48/ÁØ„(€*)Q‘J7Nİƒ;Dë=åÂY§x4úóÓãp…­†˜ö@-¿wüU fƒ,#PZ=EÆ.4Ú;`ı+¢®N	S¦*õTöÀV®xTñê:UmÔlzËëŞšƒ;ö¡L1YCí>T§éŸ]7W0ø••Êº&S«š]ÒO.mq®Æw›¹&Á¬°u|±É¸óÆ÷†Z3åyÙ=ÅúĞP£•àeN!ù§ãUcª!U‹qÀLßú
t3c·8„¸ <Ò^öÔÖV“Í1¯ÿ·Édğh~ç§Es+×•ªj?3šØ#2å(?şuf€gmri,‹xqzü3¼ğıs¼WÂ£uj„À&±pÜ,ËÍ+M´#>{¦ )1.•Æ×öDc,«‹<Ê4,Öj©´:VkF~ºáz_gá¹{hÀêK±E½±YûdÙÚã'Åµ~<€Ç«HF‰ô¼,AÑØÌ²…/‚6#r$[OûA“²îXÔäÙ4[,ˆíDy+µ_ù¿ÿ‡rç^¡dğTŞ¦”&4yşì§Í[>e¥oºİ±Üf¿Âš!|]şîåEUûCo¨´×•÷çÃy…èŠ!Ïäcö$&ş]»Ïòë\u"G(ÈòêW0;/wë.26·™õÂÈ…”ˆÁÒŸQlĞ* =^{w”&O¦Èáã>èj‡6€Ìö9£ô|jd›Î÷3Ø'«šĞ}ä[(6yÌü¢¤	ù9ĞbJÅÛò‘' 2³à$JœâínD7%ê‡?¸ŸS‰k³BcãÈ ²]¼ê™@3q‚i@v{¥‰8÷zUkÕk{éä=OmÜìd®ÁÆÎ= VY•ÿåx±àûRÕµ­Ôà)mÒ‘@¢¬š¢-øÜwORbñwfÆë£ƒ«ä7j
cÄ“œ_¶u¢W·s{g	¶ÏX¸[„™{s.À5ª×”›Y;Û¹M–!~¾”¨ÃÁ)U·	^è°G°Ş<¥ŒüâÍögï‹Õ•·8•éÜÛÿv8mKéUTkxS®0®VRœ	ĞEº9|EşhN”›¢¯dZBûI6ıJE¹^d/<~ıÔŸ™÷­ŞÎi(}Ã×ù q®5Ñ)Ê¥wİT©ã³·×†ãÛÍ0`lì‘~¿mˆ°l”1ùİ–”ÚÅ—ñÓ‰öÀÂ†•ÚrÎ¿i‚ñ]B°„İ+q!Çâ@î±]q3=à(‘Ó`­¥ÿæ ;]´§wg:ÒœœI?ZQª»/Èı›^ó‰ÃÌw1ÖÍ‡_é|Şó@XQ›¤–”Ÿ³ÁÚ–Î<c˜nOÉöÒ¹…o
›3d­&‡P@İ®åõËcõVİ¯ÂÍy¯MÁ¨*×úk„H'¯¦Y ‡Ş¾F>©ñÄ—¡‡ò
ìfóº³Úfäğ^+RÄ‘Ç$ZçÅ>¡ †9šHg•7rÒ^+xYmÅ¢)Ê±—øêÛˆJã —
ß³‹²uvJ/|ãYZ$Zí¥†Í€ÔË¤ÚÚÏ4º *Ë°Ì3#»yF£Á• ˆÀ¥¼ÅH¸ÚŞ'efµ±¹¨ß£{zûBNœ^1›5Ò¯æY÷,Õj­İ’‹'ÇÈ0ğƒAHz¾;ó8MÕì‚]FH@U¸thú0Éœú_öy:e÷B“Kì7qÄöÌ•O!øÌãCßÇ¾e§¨S&KÅkñ^™´Ñò¼»œ‹üÏ²JFöéÛÍŞ³L]õGÒâ¶i$\™V*Ng™Oc¥C7fQ$û›¯—N¡å ×—4Yl>Ëîî@™İÉ¬	w¶5üõ£ÒN§é„„êå	Ù³û7›Óö¤ñX§ƒçµüˆ/=KubÚO¿şŒ6ªãÊÃU6÷:(ø¾ô]­aÜZK‡;VéU;Ë_ÚÜËÅ¿ÜôT3ü}æ°jà)>Õ7‡©ùš~F©Ò0•Ãlk>ÊÊökÃ·ëWélÕµ\ä·¹kÿ…qK“(¤ıt|K·êÖnn¼ıMQşCs½ğŸ=>Å£Ùo¼†„_g_şí¸4$ÎÊ@á¡Í£^£
óáçßÖ@¬ÖÖ? ØXDİ2èæ‰DV­„{WÚHóıv²-l¸ ‹±ÉóâÕÉ:ÿp4¬­÷	y¨©Æ5;Q†Ñébù®GOu:`| Ü®ŒL 4 Ş[ye’JL†çw)"BÊØC‰¡­Mw-É
lõVš­Ğ*Ó©³ãŠ9+K\’–42¹­~y‰Ã†|øÉßÃ›,o(ù­¼¸¯ŸÛÊLú=,Üm«qe#«½}èçHÀ×TCÄpn§õ‘?}Ï*9z,¸e“õº‚–•8#ãÜö©PÌ©h¶=±·Ã‚¶å´œnI,ºÜ>P±¾Àá1ëœ ]©bÒ{tê|x(µZ-°Í“:2ÊigõüşåùnYhà¦™-¿eàŠLÔò_…cuÈÄ¼[J~éµÑ,Ñ¼cBïV;L"y^=²	¤ˆ¢i`­C¯s,'Lî1æÀß¡YŠ,ŞL2Ì2;U5Á_›/öû¼-ÌÉ8ºi) _Y}Ğ±kêIÊrXÚÖ™dšwSzÑ~¼ÉÉÌPt¯|p·§!KÃ€DÙ*Bûºj‘
4¡qT@°mãQcÉŠ˜UpÀ²a:Š`¢‘æô%×†Şßız	å7Pšå ¯Ä­k/ÆÁ–åàõ	!ŠC¡¼ø°µtoúÑ¨ÖsQéÄÑÔt­`+ <¼¿°?`¹ÿTåqâæ÷ûõ"ÌIˆl»E .]$d79¡ß%F~;Ö"{š{½ÿÎüuL·r)eè×Æ£x_ "k5 ­ÄT1•PÀk¾ÂØ¢/Ö¬79`È¥ÂÀ˜°"É º˜•«X@R“>õ8V“ßä"fımÁÒ„I³‘sW“6]IåJfôku2QOFl6+)´ãcÄÆFYà­Zw†ê•"mé37m“R-"ÈSkû¹áŸ©E¤g‡Ö«û²½2lGmLAØt½õ…½edäg^ë 0,2‡n½· O»ˆí£œø£u2¹Í™ş(!Ô{XYz¤ï_/ÒûUuL“ô€†~»J¹î´â£=Do•{Dƒ{]9?”–5Ÿ_ò²áÑŠTœ†x•~]¯³Å/ûÊXKĞØá%İscÌCDèÀ"!–ó¬"v»O#x$jğNı¥°7,
.&¤=õŠú&l}ÛŞ(«ŠIÌú«pİÀ|ùõöíFùQ[ëÌÈ¡QÎC´(ñèk¯B4øÀ•ŸÛÙ5u[r…G©4ğÁäC«¹ÜÍ†­…;~½äñ0Àn%Çº5ËîÈmcæJüVÙÙs)pİâ™ä²!‡½^W¿¤'şZf¡ë¯mıòû|¶ÿâ8`|ïGyË;ZCs™‚iÂfÛV9(
QURÎ>š›ğQ"Ìå|Öç8âs2ævúÈMØ«X,×^¥4ıÂ#ÄÓ¸8·R.Zbên®Ücß1ü‘½¤zí©¨Ö»æ©•ÎşXôNÓÀæ"ìe]f»íT&@ªœL+T4«ìÔr^3³™#YBS×HìcÉºEgT«1ëø;õ ÛQŞâ¶ø^^ø/Cìû@²sTŠBPË†ö[ÙíŠ §Â0âßùÏäMªP´¨Œœv¹ÿÌœ¦à£´V~{ü@r!ßn&x,bK0ŒÏö~Ô‰ş¡&âçn¬·6eµ0JÑ!»~¿ß&‰@zs½*Ãn6ï	>#Ÿæ›w`ÀÏê£ß‡oR:Ç[Ğ­;Ò4ìõ'7š£í	8Jrƒ+cÊÂSåÊÿŠÂMJhP¾¦ª$ áŠãéhÜ+°Ğò,Á]õÙß¶!–ËÉÏGFªux€úÃ(øô†½hùèœ3Nãéë„„`,„µAÎ"ãİì6ÉpŠè®Åa#_õá0Î]°”ê…Î_“;hJ]q5]C™&š.aßÒ
¿+|B´ÙÌ›A–7£Ö[R°±Œ‰’ïØ‘='_)§µÒè§|’|ÅÌiP¡WˆÀü£HÅ/Ÿ0İÑò[ÖØéïí]ş›„eqVŞ„ïÔîJùs@Ô¼"ç;/¡ét›{¨òZÖmAGÒ#|–Cú¥@•»ØXÕ¾ıæ£õ–>”*<eìNl^ßèµ†ƒá½;SíÏ¶¬7ìEŒÛÌ%Ïvµ¨ıÚóxŞk‹¸š‹ë§@c‘¡`¡¯à­a¥ z€ 5tìÂa‘Ä’b¤¾ÀŞ— ‚7´íÿ½úˆø‡‡â[â Óá'ƒ¤Tøiİñ¢¶	\,µ_é÷˜ŒBIˆĞxç%|éošFJ:8×˜7S°ÑuÃ·iS{–‰¬ A¢+J‡,8ÃÁ£×
½Äñµ9 ÀøÑM‡2(É¦Á7{é^†·ô‚şœí2_–²ÜÅñÓ›ùê]X¢K]"Ô¨pc3åxînªo±˜wé
_mö,È—»a•Ò]!k_‘ıGø¨í¸ùu/USÖU’¡û†Eè7×30Õ0F›Íœ§}>=ÊO5¹™dŒ	õi^¤ßÕhƒæ›~r¡´ŸçT›¡ L`îz0²Az.Ğy
™o„µ«%ğš;ò
l^$–˜Hi3“ù®H­ÒuõP–zñ³ÎŸşÆáÔOgB
#ße}ö“0.²ä-–ù¨=ª‚ªğ’Lk\“#Z^—Æ¹Z_Á
ß‹ÓC9Ş}:çËÇÄ ¶÷Pvç¨_$»&d&GˆÛ.'òŸ²X7Şlİd;»‰ÎØœÌ¨¨üÕ›¡.W••ÿ/úŠ;‚!/•>Ô­ŞµU³g&- •…ë)SŠÒøQqˆú•úÄàóùt?o÷ÑRÁ?¦Ûz¼'•:1H«KØì{ÏˆØ+=i‡ë>&ß¥$¾Sfÿ—˜àù1/Uîô)AIôHÊ@"ÓéÒBCèµ×+Ëœ‚14ír7õ&¨üJ^-MÊ:•"/»ë> °ü@Ûƒ<‹ş¼Ò~”Æìp˜õsXu/÷—d?×‡nd€?
Mò‘Y†ğ/¥àj×µ"¬€¦ +n’,[M5+ÙiÌ[eÄÃî;$`ØÓ)§\Ù@dqw¶I½ñ¸t• ¢¾½t²}*Í/GYZ(=²~éšKnÒ{’ï
zçL[#ú:Lÿûî<
óç”û,…ÎòµŠ‚ı¯UÍ4xIQ×¬¶BúÄvûã‡´ïF[ŞñØ=³È‰¸Í@³’©r’€uIå‹¥Ç‚ÎÃ¦ì§&Şkµ¹ƒûïç6ÇÜúâDA~˜õ°óº›0g:¤/jŠ8“:bÎ‘E¦Fß+dõ©£<z0Ú]ã7â˜êeòÎ„{Œı#I5½n3v«…‹}'-Øë·Qªê/ÌCRf€`‘•1—(#ıºy:Šô¬é>ÛüÁÓÏœŒo¤Ãà,Ï"â$ãpN¾ao¬lü=²‘°¦9“.$WˆJÉXºo d
¡3æÔ™^›ÙæŠ¼¾£,Ow°Db6Yô^”Ç7XÇôôB®íVzìIôÕÉä*ÅÖ+
ëİ]É8….\Ğô?VĞ)Dû½3`×ç 4ïÚ ªöşÊF¸z Y%a¼(üˆüƒİr†GÂõrİİ Oéxìòzœ,s/Ğ–€f3UmŸ«»°¢Ùv"ÉÔDÈK3M¾p2;«‚ÑVÓñOPãcÁ=9¾ÁWÔœôàöÎü¿B–ÅùZ€ZËSX2ÍÔÒÏÎ™—wA^n(‹“ãàN§úÄjGNIC ¸ÙÖ:'äzÛÄÕ)n.f²Ïi±¹İç˜µîºëwhs»ÖWĞ»y__R=lN4·GGg\èJ ŠB	éX>¶6H”&‚ ›Ã}‹]ÈG4Py„òò~Â5‹á¥@¾ÄG½‘Ömé¼†æ±»ïã´A·–ó{ØÑgh™Eà2÷áM(â¹b¹X„M‚)n8Àò¦§ĞâÜYí¡Ùı¨ìeOÉµf#’şæ sgDó)ç&úRï%!åØ¯ÇyÁ½z:Ëe×û!éïÙŞ«B^ƒµö`æ¨$È¢c±ø·K}”1«ƒ’ëã4ùİ·¤ÆÙÍÅÊêa N‘.?ÛL#äyÌ†fœ¤th›H:0/ˆ(İ¨:qéG³@R²}3¶½òw_eWo®Œ¨„V$A•UŠ­µÊ0÷Òkh—û£¡TmkbÈTiqIôT“™G[á=Ã0xÄRê‡{>´D[|BG¼õ¨õ}¢4PÆí8O•<¿Ú…k=f†©FFA¾Ük.Ò¨§72Í”i™öíÖV£ï‘†H0¡U?«k©‘¨aJCœê`7[å^äÕ[ïıŒäŒQ´šåˆ4¶'z8iéI%eYfŒôr@«*S’>‡%EqPªÔCŠMüB³õPÀŠ¡Á@ôNcC¸L¦‘ìÿÑ7r©geİñ2xÏ·Í–%^LÛ|~ŞÅ
,‡²õ±ÜaAVnĞHŒ¤wÈ%¬@ãRe±x†ÉÀjóÜÒÿJ-5·ØÕÆr6Ñ’%é&+3ŒôgR\¤İX?ıZüî|Õ«Ìû:G‡Wµc®CÃ!r ƒùĞ&{Ãi*A2eWÃpÄ°•ªË»ëMÇ›Ä
ö­œ#]†q†óGÖÄx-’íØ–±¦Nˆ”ÇaJ™µ'Ğì‘˜Ï2QÌ]ĞpAM`-”§Ò@kÍ÷–Á+BvaŸ»T]Æ>›f³Ì‘Twû*Ï¼XÊ‘ïw«v³'‡/áñ„P,ìÛê|QÎpò]ú´#˜Ï^>à7:»ÇİI{éeŸ¦à:é­É·{óD_3€ñÄãB–ÚöÊiŒ‚>$hÆIü{ºXªßlÆ²ÎÔG›ZÅıj÷„¨ÄÈÂU¢¥¿ùÁäoÔÏîÁüã¼J<¹f·¿¤dpvÛ­st2©;×f-¨Šy¡PJä"	râáŸæù™AÔ‰$—?[,Bı`võ¸ıöïiÈ@^…ßÅÙ^ ÕÆ‹ ŸiqçĞAœÎD3—İß¾ÑÁ{åQ¤àEËtå\WkÙÃŠlÕw1<db5‰DèLÖ”x<–s–æ»±­Iê»¤9¡
wÎ?8Ñ3!.ÛŒ3*b ?Iæ/¾¥°Çòbïˆs¶¬‘œ¦§núp¬¦€½¦WšãHxEÀ(Dx“×øWPù(âP7FrCJ„ÿKû˜ ®yşmú€È¾Ñ¿£eŠˆ^’Ì¯Á¸¼JB±/_¯ij'Ñx44Eç%à$şkrkwÿC¸-…î[q˜¡ÒøtÏ8ÎŞ‚$ˆd0ˆ&@û‚IH™æ¼Ğu›M,çZ!Ã–Ì)NH%XWĞ![HÑÑŸj\*Xnt‚ÉÖä”‹æ‘1æÔğ¬ıdø–t°‹fÿëì‘@ËÔü› Ò°¢iB]P­ÉÍOònBDÙú¯ødiï‰)¢<B<ö€Ùß¥ŠI«ûA¨ÅàŠÒ=Öœ¿ÕVÓ+(‰¨1`R¹ÒÄ²¬á6|ëIŒ'îyˆ6Ğ}upVô¬ö»<ªQEekLš€öÙrç5­ƒmƒ0WG™j@bæÀ›;DNx×Zğ‹&”_Á­ËÂ?…ŠFˆCëØ›¨Ù«x}™•åÜŒë%Áz©^h¯:ş^9&^¢2X7<ı©5Û!Y®±àÁº€÷’uu†ÿÃe…|ƒwzëw‹
¥nŞs×_–ëó[ñ¥Ì¬¿`ÕpYÓ	lú äØÔg 6)0ƒ©c-?»¢ö„Ÿcá|uFkz¤÷”õFXÏu´Æµ¥nEÊ(“”êï×cú;ïŒå2ÁE½âöfÏà6È91ú;\fÅ¢şY#êÏjÛğÀ7Pzd»ÎYk´gåôó‘B·8‰^Rpâ=\&Êß(,î"w^tj]› :_XN3Ä:¤—¸3òÔêê\^¦U„l—åêÈ–·5[ÿ‘+zCÒî{a	S'`«mGyª-p~¶rwpé2¤{ğàØŸnxAMkèA: Ã‚Š’Y4_—Gµy6Xf‡BÅƒc¯I3ÕËƒlÊSH„<UnD—8×Ìë°íÒİ§íºj²X	€µÍÙ¿>&ùÁTI?é@Ç)O?M£™Ä«JĞ¦œ«ß,+œõŒÿbOa·‡ï=.„&èÊ¯ÄÑÛˆ-uÕZq¿,ülihÛöÔñl3ŒB Îş±//Ïy¿c™àÊR¬”Ì;¼ï]¸·İkçÜßÁ4›Q,“ˆXmèòÉÉ¾ZGï](„Ù¡²8ƒ¢È À»å-€èì†Âø_Ñ^B£ÜÙUÈ—çRf,ùd8DC7ÎÃ,ĞŠ‘ıaÜÃw~)¿QşJ‹Ó"7yTõú;ß¼„ã8êWpUÂ¦wïPl,)²ØÑè£ÚAq½Û:j‘·}pmî(¨E?¸C–PZ
Ùí¹2,³ù¡c*ı|Ò&Á´QÁòCEI0W ›™t=‡©™ûsõ‡:»	Äº–	OAø´×Ş<csu¯	b›[Æ¢Ï$Œª÷)òŞ+±sº´°ç±1&o:SÑ—k‘!|Ûuå±Õ¼·P{Ô#p.ÀÈG½MNÇb(?"Ï-˜î²Òïæ÷ıoÙ©‘S@ô&‘Ù—
3Hb¢†}`Q9ŠéÕ£Ÿı÷x÷úİ³ş‡úìª|áFJé¦¢8¸Œ³oUº¶›|Ú´e×œ_ö6¡§íæy–;¢“m°;i~º€lTujÉ×M’Fb«„J½¹_ËğjfÁP2)ıÍëüµ©KòğÒU–wî8ğõ=¬S|®7Tl¾|ÀEÈC:¦$'‹"Ùy©:uùæJT2*ác×—”‹"Ñdı“]‰å>®¿sV¼zÔnwimàä”]á¡YÍö‚G7æƒÅõõR–F|ıü{`Ô­nã/4›+ÛÇ.’ÆÚ.sÒâV`†¥M!_(øO›£DFƒ•[w]ÔÎ÷~ÁÄ6£~¥É‰Fíw¶|«bîs!¢8F €¼¥aáUë?X­ïsäO¥]Gñg‡?aàeÑéGğÔÎ>G¯›¼Si›ÿÜW£¼˜[±h)>HF1—¹4wS²ù‹(¸ÆOŠpã¼Ÿ9µE‹Áx¦gHÒGÏçj?G¨(æïUÎƒŞìŠ/xi‡/â#r2†˜ÄqTÌ¨İ¥ĞŠá:»A%Ú…weÏñÄ¼›N/…†i’šED|…	±IA‘k$`nœïÛQ-ûA…ìx!q¸™¿XÄhpiíeğÌœ5"¾ZVïã­˜}Ş÷Ú_líÌÊ’Ç¾Ğc NK\;ïlPÍüËğvV„Ïí•BzÔUéßi±'íü“è‡ßöy4%Aq;*[î€Mí‚øP^G7tæW&mî¶ş»[á©Ä@ŒÓ>/°N(ïÀkÊ—œ£¥.f~¥ÎFßl$ù—8;Ëâ‹3/ºI|&¤ ·¢ÿ&{E‡Æ÷:×jˆ:,R÷>Fà±UUŒÖIz#rF™irªŒ ó»×|OlÄGÖš*¯?ûáÖÖ=×ÊàH‡‚İ—‡ä¢(†[%Ù´ÓhN4T_Ü¬d'¹ÖUÒÑ—z×€_·`—ôŠ/z]ÌÂ² ’¾°“Ğû1›û–s  ¤¼J+_ËÉùŠ‡òMÎc=?bâzèŸ)·º0Qs9gC+4ĞFÓgm¿ÿgoÈw{™Tç}íÊé½.ÁŸ/w"Àï]z•áÃ‚¸p~³^­KL¸«àá‹êîò|äÕç´³JÑsÈƒQ^¿«0>#‰ä$P[4
—ìÛy+êÙç—Rˆù‚\_[wŒÙ„âÖ~MYSşÕ¨]³ñfÀ¹d¥ğ“iG*‰ø“@z±³pıa2×O×|Ğ‡¹İ*ng…t¦m\4İÔüyi=[CdÒîh	Ç+>üJc29ÏûÒ ¡•@¢SQÛQ>,8V!ÅdO«z@>RŒHÂ~¡è­ã 	ÅVËO-‰ø`ëhª‚›íÖÛøjº|™Ï”®¡	ÚÛ6ÕòÄš’f$o—4)”jÈğbÀ`9¸ñ2›Ó×áhY„Ì ÓÇÒ¢¹lânŸ;|®W&XºX›d®;ÁXÙø
ÍˆøCÃ1¨Ö>Ûà8RòvçÖk‚Ÿ•¤¥1³dımUô=4AâHeo¬³ìC°æ%ÀC¨›Bm	1K_Tt¦{æñ‚«ÉE¾w~`Q°#;ÚMó'm[‰bÌM· “6n®âyy¥f£Ã4k¤×äx~Ÿ¬˜¥èö<8×ÿÀy3Ë í–É	™OÑÉ˜.c·ı‡pŠ¿aÖmş|‡p>‚ö—ä¹nÏ‚Wa¥n©?,jü¼İû¦4aÌïwS»™íÑ u2[øa<î`j@ò…ìkJú	²™øzÙüÆÄ–R´Dƒ¨?Gk!i×ƒÿ0sfDŠç´C·3t^³åÃXõü8œ6Ş=úŸQ<ù˜*QÄ6K³8†iwXø¡ËóõAıl„èX«¢üévüØ^K[…mÆâ€ïlÅ.±Úet€Ol™b1%.Vf±ÈwlVêoÙ!–zP„õÍékyµ&x«ÀFªs:*ÉõFCûu8‡ ,Z3è|ÍÛ—6Îï¾îºJñİVø€Oä×hÖğª1ŞMÓ" à9×N¶d} é2I®ş¾'g	ÔjQÉâ··Øä…5ê©˜7˜ÈBïS¡Š7®4,~Ï,œğ–í…½e”¾[º‚	ûƒcÙ^pnÏ|~ñ>./'…,rZp€¶e"¤½_=²¤€¿)nÈî	\e—KåSÄ?7¼ÑY;‘e¤àq¬ó8Ï+6Pf‡¡®!‘s"ÍuPDÈ4"¤#ÀÇáÛh2”—ã'\6^ÙîA¶4ì*¢MB­ü —Ì[waĞ3ºˆ?MoYìiÒÓé½(2ÉëdºÇŒSLIõoË.Ù­÷ãd
ØP§ç ­Ò¸Œğ	haQ\ê‡ øıÃLÅP¯Ã´¦uè§K,ø‡D`,	Èè.û(pÖ‡¡õ“@ £öìøôÆhFEøgrôúåœ°09êëºFÛ’<-Ñf9+[Í¡Ğs™ÏH#&ïÊ@t—“o*v$L©›	ÆÃÜ€éÈøÚÄ¹ç]VœŸæ@GTEe0˜nöÍÄ§ÎøËMö6\Áz‚‹’ºĞÄ
%š€¨0ó/2“æû=ÛŠP[qßø¿C@Vy± Ô÷„¿‰4I/úKTı§DX¹Â©6<[V bb+‹cû&‰¶¸_rçFRZ(`4GT«çÉÿÆ‹ À8[½xè£Âğ€@:Èpí(^E7Yw¢õ_!+Ã~¥‰ÚxeR6,·7øÑ™Ã0}ŒÔáSÇëÂ^O„HŞ.´H{®±\o³~Ÿ×ªé±Í°©Â»µX¬e
È`A¬éš—ËqÔ±là•+»AH|…ANêIÇ‡EmÒ>YÆ>ŸI>êÜGŠ½6…‰EyÒ¯ ¹ûÖô5öã¢¯;eo‡‘P¿VÑf‘îC&Ê? sºqÂäŠ‘J5Ì[ãñHªÉP;Öÿëó#OhË¤)^§ö€^×‚d}bÄ:`
ÎA™>¨İâdœñDKñˆâõªÃmø{ìlŸ)Ê„QêGäky|”]Üfy~Ã†FjéÛuÍ‡*Q‚,C›¾Ïİ‹8V3ÚÔG/`
¶¯;ßRNŠËª°5Ô<BáÛˆ8Î K#Å V ŸC:˜¡‘HØî¯;0dÓ±yd5h~ÈFB¿ŒP¥ªfñ÷ÚìÉF¨¦âåj±˜ÿ>2|buÈkºùK!Õ¯Í˜¯ëÏá+İ1˜ô˜pÔ…+?³¦›ÕA !òBó–o¢F6¹LUG¢¦Æ(õHlÄÅ½WML™#›ÌÁòË¢16Ì§ÓÄğ®¨ù=qé`>×ÕdÊGş˜È dÃÿ¤ƒÃôÎôz¬øyãÔA£or”&”ñÍ`<Ù…emŠÏEA¯˜N>à„‚†ïíâq†TğçÓj?¬6ZæRÇƒŞ­7Ê+$¯ÃC2º©»È”ÓJÕ!ıEöølÑR¶KÜfïÈËwÛ>{8à>‘‚¾YÕ¥	•‘Ò±³2şj@.@¨Î9é¸¨äy½d³;¨ÒjkÅq££hÈÕşÄâèz ”™}ÍÅl­ÁÑ ¸Ğ4tdZÁFÀz3Ø|¯ÆÜL“_ŠÆÂHñâkWo¼'G<VŸ.<­-âAe#s(3B†fÿäPÙüş2 ,—Í›¼» _Åä`œhãà“¸uÿüàôBŞ!(o ~K((ËË¿ \Gi MVEÀ*ım	àH‰®Yö)ì¦)ˆ[pGVÓÓaÍıæƒ şÜÅu(üƒE¯Ã ceîıcr:¤˜Ô4©@ËÊ‰-'0ª©ªä^Ö¼¿"¥B·£Ò¹Ñgñ»ˆjğÖ]Š­!~(XMHF:Jøê¦ç.ºñŞ§” üdª@%‚$à|%ú’Í#*º¶(c=e5§ä’7-	–Aãu|ÉNn/dĞ™ş?œ·6ÃB^ÎcHªü{»u+QK ôvÖÉssRÑ–äJù.G,á±¼€-]d‡ò3İà2º¿;ÊMÆNŞNdƒø –Çwb|\L˜Ï	ªîÊ”N1Kšáÿ~UNıSš¾œ“(,"&¸qGÿã±ÛAï’'yZ{px\­>6Üƒ!Øû9ÚçZQ¾NP1pw_±/4Q¯°6D‰ˆÆJºãWTÜ$}“¥ïÔŞgøØ1ü4w/…9*¦ûãøv'Ã£}.Ê~NxU+Ïs7<Å¯Š´a‚%›ï•T"À¸’û#’^¦2àÑ#nÙÜ²3d÷©ï"g¡1R$C”£­EŒÌ¡NŸ^§8±hq2ø4­sMİÄBndb¤FMfÀPsL…İ²YığY}gW¾\ä*K—‚Ì†5€ô¬Áæfßd€ÊU˜’qjmÑQ¸X‰<[Àö'%Oö7×úĞİêºf‹a0ï”˜o[(4–b4…mı¥dâao)¿œÖ«ÔÈ ‰•l÷¤}î¤ÀlëİÀÖè2‰Ğ>²¸œ¡FVØ›ÚÑîùWO/‰g‘âîXdA,>³1³Î	,‘²µ?š^‡éà2YPÉhÜÑPEWÈky¾=8ö%û4%³rñwUŒÃOİ‘B¿¸Aq³õóg²ÕL"A×æÛ¾[Óë½U_¦`oˆcgıÑˆşƒ`wÅ¸C2ë•[K«òt–{ĞÓÛàøqáS#›ŸcâµÜ#!…ÎöBæ¢¯EZåó‡†š"òøÅïÍÃÓT2ør‡pÎoğ"0*RA¹üa€wËŞ×/ ñğï‡’Öª?ÚQ*íğdWRw°*rKà›DCçğÍãH€uÇMñ[©ÑT•RädaJ}àù²––å~Ç,j «±ª¦NõUu°’ûd‘n¨!+Æ'ßÆHoVªñVH”	¥õ(Şñè ¼$¢óğĞP¦Såi8Ù£IÕÛÁ<ùN„ƒaòÁßúx‡ä_W‰c¢È °+¯Wc¿’ÍøŠlÿ$›ââš¦W İß@@ä!t’B·ÊX<e»†_.™”õ"ÊXŠ<÷Ò|¼Ç¯úJo]ä)ä6çÉ©%e§~K¯İV ËHîÔŞ£¬›Ø*6zÿrË–6i°×Áfwrcè“7ÖĞOC’ƒrı‰‹WL°«¶,±'âO»—>Ù>äMPÚÍ{u’®n‘l)üÇ—DSB?oR‡ëÛû¶’'şıiæ$öàÁÜk‰÷îr©7UA‰oP>úéÜ´Óñô*šRkÀeç¶õk,½ğãÑ!—k{ş×Vh‹&‡yì·Ê—¢*n¢˜XmTÔlÃìtÂÁ¹ÌÜ»åyIûA™C1KµiöŠxòğ¬›Ğ îÌÖXÈ4I6”/½ÎÈ>wNe8‡|şæ0NXÙ]@6K/ mz6~$@fùô®ğµ}5†¾>Ê7u#de+™”äÙ4{±™DY[‹&&]í‡,ûYMÙ$Ö˜õşÄ«dü·€ÔÑÅ|TüÄ)ÅÉœÑ8ÚIÓÑ^ÕàM'¾%­ƒlxBÄÎÕ“åX5ù¤YO°¨vå›»ÿ|S©Ú	ùqùÀà•”òÇ/ã/<¨üíé÷+Û¡J¤RÊOâx3›ñÜ6Ø©‘µh¼s	+Øñ—yöâ	&{¦hz5lê¤gş%§Ön"e:2a&pä–fÔ]º>ëŠ¦ÁÇ—F’ig|Æª§SøĞ–´ÂzŸøˆ´‘Õ^‚ q÷8ğNßrMÈ¸KbIùÜ78†µZ!Õ:ˆ!8Ğp\Ï­$¸öC9u°j4·òÛ@ª¨ ±µ€š¯ ¬® è(BÈä½?¿ùÏsV$h:§¾Õ9¥,q†¬¥pÿ#ğ}[x±ÛG¸Hp°ÌWØLG|Æ¾2R(éq£fÆÛq³øÉ´¡Nk/‡Ãs¾§;IZ·8x+Ş5n2„ñ†•¹ëR‚n£kÑÀ\®ğTµ±ò€Fã“ƒ^÷	ÒÊğËàô}$€'¿†U˜
<İ†JI¶Èòô 1ª}ÅÛİAşKÃ;×*D:úüHu¦…I+´1·.Ùqsm^¢Švñ›ÂbZÅ‹f€­ËÛIv²lr’w)JZ´½µ#›w3¢Êˆì¹EOTo/‘>_(Ë}_yVÑê¬é
òÜgu·ŠDĞ”ªˆPƒÂ?ëú±ùûK5•ÇP}“j³>y™Æ8Ï×Ap`^kÄuÌ·âŞæ õ3­¿·ÜØ˜ÄKrèdá© †n†¤®. ß¦µİí‰€öÚÍˆ¢:9£»œé8R§|¬Ö5àõy„£\†4âÒ¬ÎŞ7N©Ş¥ÎaÉh@m]İw^ÎL5îxxûJiª£Ä7B\«àÊ¬œdº.·I=ÕUa3Ÿ[ËQCßá×ğF£şUÒx'Á°g[dªX
”ô×î•TïKÕşIƒŠî­@•Qãc‰Éğ \7u¾±Oí§o2"{|rÀmè6¸‡ë1÷§¯şº!êœø•p‰É>¦÷ö‰äYXJKÊô¢ rH­İ$AT¹çş" šÎíÿcïFcÓ£g°âš+uy÷>[Äz¡jyıZòÿµj˜ÈÕP'éZßµº^fSÇ™6×õî |š=8WµK'm:‚bsq°ÚD4£KûU&Á;SÈ—ƒŸNä;£q‰Cƒùƒµ©! øŠ[­«ù[¬Dˆ/ ¥o;ÇÉÀó?	V?2şj¿ŞŞÖuÈı“–²yJÄOwS[Ï¢TEdÔ¤_¯?ôúbS³(ÊÄÑªø«jlæYšäâMò²Fm>‚WÊn9·ğ‰AmHã¹¼¸qÈœƒ‡R•ãóË¸V®*ì»WL–j¥Jì7µƒ0¥Î=ó¼šÖş`Éàª÷y8ÿ÷|”¯ãUFÚW¼àæÅ=ºĞÏ0Há’nPÈ[OäÇFÍˆHïĞĞÒ³ø(ÈÍd-ê?Hô²²Ø!9ŞwğçÕ-ãÇÏ–Â„İ 558ÚºÇ“—›*‰gTR]ŠÚ§5µÏ# F\?cñaÏ¯ó{æº¹ dë2oH—`– Ãœñ6&z¢ÒÌcÃ‰®:†‘Ì)g%7bqR‰€`™äv¶ã²NŒÓô5= H3z¯|(CuŸ–J!ÔJ%Û¡ÆKxèÊ4vŒÚW9Ó|íÙë%°,O)rj]"•2¤rËquí=0ò!Ë­4J8‘ë÷H“œF\‘|ém)“½§
>ıeÜFÿ9±û™&pS—øL˜Ô7£‘ñÈÜ@®£çòl§r,õèJÑß7ê¹Æçê'=ÁgÔ'§¥sô×»~šõ°u"SjÒìÓ®@ŸVoTâ¬#Ô4ÿãpS¥><WÑ\"òRHø¡®«ïG@r¡âÂ5ãX,•MQ2İh„óIÛ*eØÓV #»Yh¹)œCsè‚Àãô?cU[Í«¿Uà®ıi£¤±vB.øÏdø‰ØXÔfáxášƒ~%ØŒT1®uZ2éëÕŠ;YÊ¼4[>–È–‹¸ÚT¾öCˆ¸Ë­}5ı š÷¦/8gzDzÕ*LD¢¦8‹ù†ÜÜÓ7¾pu#şO¼`zt2jÌñ&A)¹=ÂƒÁ*fÄØ_\yT/Mö©°¥âbfcaŸÙæLá÷SÃ¯ùW P„m"‡T3ş×£t®+Â«>ß·¢º±J&´$`2ÛGiÊb|­¿ÇFhÉ%¼ÇßåzXˆú  ?­¤T°—¶¸Š^wÚğš£ó¨ÿ´½ÿş¡qçÉğÆ¸N_/””7®E$@€ASîŸ(`šŸÖÎ¬V€ 0d–P;«ÉÕ¹ŞWK}°dÎ¡‰Î›Ê¬ğŸu}5IVŞ·8&ˆ¡Ísî»,æ••–,êµŞÂo†~;’Ê¦ì±Y"Kª>Š0•eÆY5à&1aGánÁ¦A”‚-‘l¨@‘ `çóıó›™bµ8¯ÑŒHw*—¾9¡›jŒVR>ú*³Ó(S²×ÜpÈ—SŒ«\oÃ)Ü¯?S&œ‘^ĞLùIæ˜zŠU…¦)Ì[Ÿ¨OÍlÙJàIKÜæ\—QDrkó–šsÓP'ŠLqŠ5›´Níëæ Îìo-Q~³ïqwjƒ©t–ğ®¤xÂµtâ‹ºu”ÆëÌV.âïšnÉÌ‹6Ø(û‹¡¿{µüUäÆX´±‡oæk®’+dxë‡ÏsĞî¾ø¹#%3Ü­c¡QMû<ó«ñ¾„RÜV,ùùZ|Ë¾=|ígäûˆÙà(F-ø—ø›HÎP•p§‚2‡ø\‘Õq¾nşµÓ)|Ê„Y/Æ4Ÿ0ƒ± T*Ô>,‡>â‰ÄØÇ®ĞÕÔ¤yyÒWÀÀ©ò¶HÜuÑß±Î^3¦´w*—Ò¾‘y«zçœ<ÚÂ¼–oKJõè‹…8ä»[ÚC=îÁ¤ÈÃ¯–aU#fÿ¨™…8ï¿Ê2aÀ]±,_ßTdœ~I`Ï/¥™qZíìı£Ã!zªVÙ	Ÿ—‘4‰»ƒQı·ÍÕÌ>çšø6¦c2±gN–ÙZü=.kn]¤ub?'K&åg’
ñ†«ÓúEtğÇcwŞ–Ãß2ö1‚ãXôfsI>¶µ	÷¤¨`Ôâz£”·û,Á —¡9ß>Á™LØ²0°ôÅ<3)qÀ'6"œzàÚV¼‹3y÷TtÃé?DEtz%ºİd¤Æ©Rí7e00¿I‘âÊŒ-ê94ì\ˆÓqÀ•’H…“3(©8'ÎñTÙn²Q
û_Ş§ˆœBjÜ\Zç*÷X+³Ô8˜ı~Œ5ßAX0!ªXQHré-PŞHlÆPÚ'Ùù‹P¢…u_0ùˆ·FnãÆÕ »¼¨FÙ¸œªjì8‹dü¦İÀçSY8Ê FŒ¼KJŞ‹Ee–Ñõ¡H8ä¿rg©Å–E¹|™®mŠZ=×qS(%À]ùRe„Ì#Rîº¡)–ë-š¥Œ'	İ¾Œ¾Bšd‰Û”Ö"S¢‰Oz°lí3Txqµdu¿ääìÌŞN5@äœTÓÒ–ĞWßOĞYÖôæÒ€^ı§¿J¨Øçœ—ƒš¿¾ûI•—ƒ<.©dÍÍ*®]¥u¨nÁšİ^§qØ@¼	0‚ïpŸBcëµÖl­Ïë³3øŸp­ÂDEúÄ^›áÎnL‹}2H=Z>ÊQ–.58±|@zYiw¬ )ŠIî&“ùÌÕ3îŠ/öùebó'¥ûÏ÷„Ãrú…±¦üõ³5Í 04öõpØ,r!6äŸç%ş †êk1‹ËÇVYÚe^ĞÎÄíœ†<ZáŠíàîÎïõY]{£ 5*<—¥5Õ(û!¡÷tŠDŠ|¼¹ê+³øö2¼[]Œ.2BQ°OË_¯˜„DB–ıRëDW	”¨ëm…µ0nºàt•/‹ç2oyÀjì-†7z÷ĞåÏŸ•dô(g/“mîx&r;¥Ñ+ìñcZ¤8Ê‹G>„ÖT~Í#"WIåElC$\vöJX5.q@¤¿	¾*dª
ëÿÈ‡v’E8¬ÆÜ(š0wt,™N˜ÑôT®¢Ê’»XöLTéhB+¥§jdaz§Ríœk,ˆBÎiL£A–yïÄ;¯|'Õv¼W<,Y^—¥ßDÄÀ%¾SÚ¦ÅxŞ#ÇVôöĞ9ÂvïOu´u5ÅI[µ<]»U„ŞQÈ‡šLªÌ¢
şT£¬©Õ•4Ç\H‰“·qÇİ<a¾`àª«¨\‚TãŠãÁÀ’ÚLÔŸmJ¤†[Wk‡ºI˜Úµ0ËRzz¥²ND#±¥2S¹Û¬s!€²—N› Õa,ÄÌ»qÿÙñB•UÈ¥íê‡•ùŒl1Òñ4(So7*Ëïíc”vì­ÉWv—ûºÍÇ1$¿ıšåWı2"õLÃ	t İ›£Bá,ş³j‘8€ëg[Y!©¬®?ÏW³ïşµúıj¶p²ïá;ñc©¡Æ=¼ê¿ÄÙs¢kù68<‹ü6XWª9€òÌ¸J%ôµÀòÇi_?+lFOöŠ×(`üb0HC™ÅÛrİ'îšäâÏ»÷8=¬I jÆÊfµFŞWb¤Â™»€ÉĞAûrQwÈ ÇØ<´Eº%Y·öE¥¦Ş"ŸR34Z)82AH%ª[
õÎ¸4™’3ÏƒÏÌ_¬¨ş¸"Yl]ÁœyLš\ñaVå7Z×'cı †6ÁÕéöö^uïO½Ï?zŸÔ«û£—ÂÑÏ*ÕMssäTQï¤qïcU$E8¼uP]dŠu&y½xqeµÕê373”÷ƒNüéÍŠo¦=Û/È:Ïüws91È| r±‡Ì¨oŸ
(9æšè¦)*xºñ>qb‡`¹rd	êÖSd[ƒ¢wÇslü­S²¯ĞËáªG`K., 'kùš)VtüŒ
 Î¶ŞodîPŸ†4ÌZlºëÂ—“5=š„?äŒQK)`\œcÿ%/'PRR¨»¡)C7(D_-şö+·:V¦‘7Fù¹/”;‹édòÔù{Õ{æ*gVG]DÖ¿á(_ÒC'ˆ®"Ê5üİW^ QFÕıgX„†/?=âÖkíÇ8Yîà ù^È?‚.À=Ù¬²L_`ÏÛ		ÊyF*v™ôy„JªÌ~mXùç¶–;Í
KµÄıŠ:6ZqÛA™]õŸ‘<•ååa	L¯{egÄi_ºæYÚ‚6ïóşX96˜CDycÑóÖF=şßXÀ±ğ…+{0+‚’§…zwgÖ°ÉæQrŠfúâ
$xÑÓáœ&-ó)C·ræİAãõ8AıÍûÂ¶.íF±ÎàOÆé¸ SW)=­¸JÄ\yMÊıt‚¨c'OQ6ä«(‘Â–{Š»<yÂƒßC4CÜÉ¿Òj`Aİ’¬1íi(/šÕğ¼wyŸ¤ÏqléM
6«t-ÛËaqsnûñ¤e¥‚Q4ÔÛAHˆG± ÄÏzt=²Ü§²D¢Oæ*„ºç@ô£ÿK“0«
?J3uÎ´èx%²€¾öm0èÇ&RaìÄ#7GeXì	ïì™ºR¢£’U6D‰u^_$şóæ1Ëx€¢{w]„è§Á2>?eôQØ¶š¬`Óç~ÛX'ıœh“.­ÔNU´”U”ğ…’¿ ÷{+f¤ôÌG¼åüIpÅXĞ®Wác¥|*Ê¢LÕ~]Î"XöxRy©R­¡ëÏ
«
ûr~ÒÕôLó¼3£ÜzDheùáíŞé;¡d Ôt%{ÄXaâß"ÀîL&.=K=¶…O]İ³Ë¿Ù^®ùÃ>Í§Å|ÄïÒh+
n¨ğ¹ø™ge{²¤Qã»'¼ŞpÓˆXÓïÒ£ø·U\…j†×Ä¯~Ÿàÿ“¸²ç¶¢‡Ÿ+@ÒµjÇ±ƒ[i{WÕË¼h7¹|{˜Á#®ozÃ³W@00â+$Ik:_‰`“ËÑJäÎ&ñNåë"8ÃæAúØtñ­LbLP÷Sâ¨gˆ­TzÉBN?°Ş¢™@TÛéôŒšè¤!ª¡4ó—Í(4w]’sŞbNT<‚5Î5ßîYìöÚØFlnå÷lº&8ERX­îyrŒ…tIÄ¬Š*AßÆµfpöJ”/=ˆÏ„$mŞsOc©€ ŞëöØòè^™Æ…g?÷»ì#‚Z·§ŞƒQ…¬.qúPí;ç	£í7A!ë¨ÚªíÜ×5`°Üä»š“æjDÖõDQÀQA´‹qï½¦¯n`2iœ‘ôùcÒº_Ò9ú0cbÏÇ§q ûB×‘şÿ¯—şæË¡9l”Ô}Lb&†/H ¦YDíEyg›òp|jÚ2~Õá—@+1
Õ¥ìkœL$Y#¿.Ga*D[Ğ¸îÄ{ÀFã¿0n²NÖÎi¼ŞE^78Áö€âì¨ÑIZÖÍƒèğr¢‰ëÔÁD¤;ØL¿;Çà±ÅÖµüñÜÏİòL¸€µ©ñl£éJbÖO£*ÌŒjÏÊv.CU¤$º¤¼~r¢9÷\LN×º@`ıº0ÄÎ«w­5îšLº“¨FXÙ_'r{Š½À‘¢ W«I`¯.Ó;Â¾Î\Ac¥M…¯Æ‚ç^à ±NfĞdàt×J‰¥ıp,Ö 5à£¢ùWÁ´š½ŸöãG"l$œ3ö/ÚvP@t–^ƒù‚èW²ÉÓF ÌÔD×µf³ÍÇ–‰ñ6Éje]øO¦Ú¦´j8®ÏÂÑ±¦“À.DÜ›ó˜°‰]¼¡AW¢ŸK°ç)©ªèQ	™¾ˆ :ßî>%]®tk+x™Ø•n'2mÈæ·e#‘1ª‰({…ni'ç$³ØJ‰8¾_§bX€g3 ğhØçíÍ#3íYm"³ÓÃq0'2yn¹û¤F•\5[}Æˆ ÷IËŠ®Uäg‰¶îŸy*ŞÚ b3ï.<U+£§Òà²S·Là\ó0s(«7L*Ò³wšk%Ùå™æÁm½³vtqônêv¬¶İaD1ï3©¯¨´)Ÿï²Ö&kCé¾«~0K¦m¿İóQÚ‚N™:nqĞHUvPœ9FÇ.˜À…Ì³şT¹Ü7½k*Ö)Õ”£ÚÇå¦-ùMÑ²ßö2U)r+äØåôÿ3§üDæäDi•e§ybá¹ˆªÖ6Oê8SVĞuöùó4föFxÜH¾£ ¢J~ãâúäŒ}{›ip²g+½\Qõ¶/#|ÔoSYP—Ï-¬Ú\æÖÅb>Ñùa‘Î†ÍÌšŠorõÖ¢G:›`‡®sÀ~[[~åªcÑíD $S˜¡/¸pï¯ã?UÈ}ì7PÙ¸8Ì³Íà)D0†ëæoˆ(d…ŒƒÇ<ztœ~Qì?ŠH<İ ñÈº{D2<îOéiZi°Y`C²‡ lÉ¤”Í<ç~8/¡ˆš	¬
	p“‰Îçs
0ÖüæŞäÃS—¬ÖÈ \ı5DNX]8½©ZKş‚%Ô©‘/N™…î	ñpƒQ Èq9ošÈ-;:›¢>÷	LÇE)u„Âª2‚Çë›ˆrYªğ[A×[»“ïwŒ1XÒMPKØ"D÷Ÿş:¦’@}œºhãñ–T2)àn‡·¹JÇèÎxõNPÛ–ÌÍQ<
N±`»ş=I«^~å…æğøë_yC•(î„>»sG—áÃìFQèºˆûvgl¹Â,@°hç¡”FÉÎAŸÊpQíœÃœ¦®@<¦FøÄl“­b¦oOâ×´dÜR,¼Ú=µgT¤i«êQÚÍ`»œÿ\`şmRz:²Ö¡ıÌr›wË›ótCJf‚Ò|ÆÁèi^ñVv‚£¡¢2—|f¸}³tlœë©_BŞipö ¡¡,R“à´3;ãf4î¾ö8Ô`³5íôïÛwÑÌÀÙ_êÍ5wHa-±nÊ’AÏËÒoãâ?ÿ?şª>JÄ$ÕE8³Âòì1÷É6‡Uç¾÷ñrˆÈ®å	A4½O_ĞÑµkE.{G/º|RÔÖTH³µˆ¬N=¬ëÿ_Ó_*iá÷Š…Lóşç˜*_k9ÍúÀ-Ä5+1Rê×^d)Ã1—I*àG*oaE\ÅLbŞ³÷™9`NÖÍ¾j‚u\s{]¯ÖHüˆôÄ8AEŸ‡ÛŒ?/~…g„,{ÈEp?·=íeEWù T“½ï`³»“8Ò²å-–Ï¾Ú­‚7ëÃ+o ‰@	°–­eŞ:sÔ6À-®¢È1$„˜5f­£ÆÇ{;ïóSÄ¼ô3\_“èûJÒ1d`œÌº:,².UyA¾›˜Ü%C¾D\ D°ìU „Ã€À.Öä±Ägû    YZ