#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1930224086"
MD5="dce32910a0ed8ab80e6b6ef625898d82"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21164"
keep="y"
nooverwrite="n"
quiet="n"

print_cmd_arg=""
if type printf > /dev/null; then
    print_cmd="printf"
elif test -x /usr/ucb/echo; then
    print_cmd="/usr/ucb/echo"
else
    print_cmd="echo"
fi

unset CDPATH

MS_Printf()
{
    $print_cmd $print_cmd_arg "$1"
}

MS_PrintLicense()
{
  if test x"$licensetxt" != x; then
    echo "$licensetxt"
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
}

MS_diskspace()
{
	(
	if test -d /usr/xpg4/bin; then
		PATH=/usr/xpg4/bin:$PATH
	fi
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
${helpheader}Makeself version 2.3.0
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
  --noexec              Do not run embedded script
  --keep                Do not erase target directory after running
			the embedded script
  --noprogress          Do not show the progress during the decompression
  --nox11               Do not spawn an xterm
  --nochown             Do not give the extracted files to the current user
  --target dir          Extract directly to a target directory
                        directory path can be either absolute or relative
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

    if test x"$quiet" = xn; then
		MS_Printf "Verifying archive integrity..."
    fi
    offset=`head -n 526 "$1" | wc -c | tr -d " "`
    verb=$2
    i=1
    for s in $filesizes
    do
		crc=`echo $CRCsum | cut -d" " -f$i`
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
		tar $1vf - 2>&1 || { echo Extraction failed. > /dev/tty; kill -15 $$; }
    else

		tar $1f - 2>&1 || { echo Extraction failed. > /dev/tty; kill -15 $$; }
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
    --info)
	echo Identification: "$label"
	echo Target directory: "$targetdir"
	echo Uncompressed size: 144 KB
	echo Compression: xz
	echo Date of packaging: Mon May 18 17:57:32 -03 2020
	echo Built with Makeself version 2.3.0 on 
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
	echo OLDUSIZE=144
	echo OLDSKIP=527
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
	offset=`head -n 526 "$0" | wc -c | tr -d " "`
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | eval "xz -d" | UnTAR t
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
	--tar)
	offset=`head -n 526 "$0" | wc -c | tr -d " "`
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
	targetdir=${2:-.}
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
    tmpdir=$TMPROOT/makeself.$RANDOM.`date +"%y%m%d%H%M%S"`.$$
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
    mkdir $dashp $tmpdir || {
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
offset=`head -n 526 "$0" | wc -c | tr -d " "`

if test x"$verbose" = xy; then
	MS_Printf "About to extract 144 KB in $tmpdir ... Proceed ? [Y/n] "
	read yn
	if test x"$yn" = xn; then
		eval $finish; exit 1
	fi
fi

if test x"$quiet" = xn; then
	MS_Printf "Uncompressing $label"
fi
res=3
if test x"$keep" = xn; then
    trap 'echo Signal caught, cleaning up >&2; cd $TMPROOT; /bin/rm -rf $tmpdir; eval $finish; exit 15' 1 2 3 15
fi

leftspace=`MS_diskspace $tmpdir`
if test -n "$leftspace"; then
    if test "$leftspace" -lt 144; then
        echo
        echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (144 KB)" >&2
        if test x"$keep" = xn; then
            echo "Consider setting TMPDIR to a directory with more free space."
        fi
        eval $finish; exit 1
    fi
fi

for s in $filesizes
do
    if MS_dd_Progress "$0" $offset $s | eval "xz -d" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
		if test x"$ownership" = xy; then
			(PATH=/usr/xpg4/bin:$PATH; cd "$tmpdir"; chown -R `id -u` .;  chgrp -R `id -g` .)
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
    cd $TMPROOT
    /bin/rm -rf $tmpdir
fi
eval $finish; exit $res
ı7zXZ  æÖ´F !   ÏXÌá·ÿRi] ¼}•ÀJFœÄÿ.»á_jÏñÒ¡v‚Ã­è&×LàÉa#ê‹,ª@ı	rü¯@û2ÜçŞš}Ş}\Ë™ÊÜÕ)F—ÎU®`ôš³M$R0‘„TvS¬`×5	:½œSûfa¼.“S-/]O±ß5ko¢İ‡‘QMçÊü¡`ÆîÀd‚œ²³$‘]Ï0º<Ÿ:­ªŞN¬å( a¶î¥v Ü×ØF¨ı,´­«#~ëé¼W²/âO¡ûXZ
¶ÂÄ:xµ¸(4*•««èÄd¼Á£|İk.*×ˆ}˜ÈèÂ½GÏ·Äp"ti÷ı»]wÌíù«¹ç{³Ï¢¿;"ô­ G¡+¾7\f_ŞÂwÜ­Éóòµ‘D?$Z2£TÊ»÷V¸'×¥r¢»àŞ±9k ½f†}*oL%·mïqäšWlSÆöš©÷BâÛËéaÊ!Gp–à[÷ëõ«Êñ@¤ZK»­éFÓdk›sËÏıjqd+ŞœİØ¯üë=6ƒÄš:üØuy÷¹`Çº€š*%B%âX¡xdÇDt|‹îì!Œs@¤ÑJâ±Êğ……£YÒ÷BšöC’„±pïä(HzcEÜÎ'ê³Öª¤º¯OíK
òPD’Û‘ö„InÎw[•¿·7ÕFÍßà"”v/. C,”š3Ôó¯œÜHéÈ%Ô?¤K©ö¾‰ÙG6uk#í†ğ·8ÉöügÁ¦ÉYämìøñ-ëªi2.SE»ëLîdï;ŸÎ™tFUÀ¶všçŞÃf{$]ŸEeßÔÕŠÉ)¶ÂD†–Ì.½—û/‚,õ8¶7·ãó^‚Ggbå·<éF\ZˆP°ğÔ]ò*xM]Òw¢RM6Û,J€„_ò<híq¹Â“WTŸ÷T™ôAeï\ƒÎ'™S80l›w
v1oÿbxøoOVÈ:ŠÍ'’åyØ“–‘²ç>esW¤Õ<­Añ_›Ù‹Ë(Ìj¡sşlJ¥¦F›|îOƒ7ø9¿éÑ7(­!ê¨†¾ıcHêÜ”¯pAm]kÌ™4c×C·!ã—Ê psaT5Ò¨ITÙÒÃ¢t2e¡àÿÚ ;lú²šàª™¦‹ºd8ÿÒø¢"T‘0½í	vŠ›,ü²{¿(Ü”;¹Zàv{4_Ûıà@¢†«;héE¶4çÚ&«(Ò¹ßUH÷ÂæÑ8¨I·kfÉ/-*õ¢†\!@º¬gÇæêâ7¿eêJŸ\sßµ2ã[†	—,ÆWîN!Òs¯c³C†lPQPp¸Ák±Í™*åqÂ%ç–%æ.ƒ!Ø!¹X€óÀ×`Íƒì”Pú´J<Ğ$˜¾¬ƒ#«Ss¼•ü:«+ÃyÂØUÃ«I6Ô%ÆÕÂ£b#Ø©à‚giMSóÁÂYZ„AX[q(¸­ûW6ñ¨RÁ¢UZÄÿ{l$É+ÍŞnó¢©ŠxBIU†L„0@uÚõõáı™5íœ¥ù¶xD› ®½[ñÎƒJ),4•ÈÍë—G´#Tf'î÷~ˆe9°È:­½y™rM{/#Åo©¡R/ÛºãØRx¶3˜²yy¾,6õò/c¿ïY\µdq0ÉT>á4çW&ŒåŠüÒÁ©Òg÷ğC"/¹º¤¤ş·ğ ãÊÊ´WèNL`‚š†|hÙ7@½‚$âïZÒ	.‚vç[(¡Î¾Ç]õ¿1úMÚÆ³ëè®î5 ÃÚKìFqMÑÃyÂı ˜PƒC}g“ Ùş4¾TÛ=zë1­/Ù0½ª”úæğÑú­°¸ËÀ`n˜[ÎI:9')Ü¹>¯
U+Á½:$…ÿ•FZØí¼çAº‡’3ükš€õ:Å~Å×U¤ÏØÍRã–{Eèt!GœL‘*G6îä•^Y2Ã:Œ$Ú:ªiÚÏ:ÓmäMÉ À®0B£¾à€ ‹jıAÍgÀìóCÉãVI[„xªàe¿} -Úƒ‘Ça ¯œõûnŠ!şõöõ…ßßgoİË6BTÍ‘xi»ŠÄîH£x#½‚M!ğLWlÆ±Äõì{H®n¾û†pG<MÉÉé»zF´œk@ÚN¶Û™Öu#oƒ2­ZiZ©¦w£6c™–¶|¨‡ïÓû8æup|æµçŠ™öO9}ÇŒ+QX+-•“\;3¢ Á‹5Å Vq¿iP±ÙCÜ2hc½=ûùşêø?rÅö!Ğ„…)*§° €ôVm"µ:Ê·(m—s¸š@°÷¾•ù‡Õ‚pHB,ráÎ€ó„D:5Ë“	Ÿã?‡mLÄ •üq•„p”÷¶ÇM4™z^÷³FN¯vÈõ…áiE¾;´vŸÅFñáVÜâX 1OZ&ãc6½^bû*ÙôfOÛÄKT•%¿G¿&Ø»÷ßz"C‚°×1&`ÊXnàu¶l7õ /“y»0´/mèzI9õ¾kâEÉVAJõ›¿Jq­¸ÿĞ|íÓ³ãSßĞ]ş•}‘»]õ/6ˆŠœú›­4µ-C{nPì~ÜC£~§¦ŠUö³/¢…ÕõçîhA İ@ù¾Ô–í‹+ô‡Ñ;”zgP"œ…/%öD¦`w(A/ÂÅN˜ÇÀÅÖÔ±;§)1Ûf¾‚‹{7>®˜*ğ¼G46)óÜÛÃŒ3Óah‘Uâ½õ¶$„)o7÷ôUœ]	CD»?v$ÈXôğ¢@z !‚–1ºÔ{L>¶ø€"óXã(	urê±_‡l;r*aÖ‘YŒË»©‰Ó¢W²½/1Üê¸¥À:'Ğšalƒ«70ÈDî± QŠ‡T¦TtéR÷Öİ‚XKÍ´g¯5h,ÒzŞSĞ¿l—](µh+çQäWX®ûrßİõihš´âùD;ìd.'GázÏÙ«]sÅg¹ÓY"Ğ:%¨¶ÜÊXÕšÚ~(åúÂ¹TüM¼C¨Tx‚ë;/‹ÙN	õ{óN‹wŠh0e8,É¹t’ˆT\
JK‚Qâîó€ı‹C^û˜—½–¦ì~f™kvEªB›2btß¡á3ò=¨Ë²â0,Tjmg­rû·k’¦8şVYc5ÛÑ:3ò™¹K.ëxğ²ão¤õ4û~»\'³Ó¶2à†z¦à[õ@gÕjD”6É±@K³­ğVF÷2EG°š:Ã«?½=Æ_á‘€?
¼±‹ÏºÄÛPØHœ¾K×ö>ë•Èı§áÃúÀ§üÔıxñ(·£´¶:8ãe	OÃüñv´Ğ*Ç,\Ÿ#,UŸè½Ğš¶9ÑAâÈú	ğ9Å³í¥CÈxª@^i“¨´DUzxD—„sûœÛË]˜¢t‘&[Ş‘Ğ*š2Æ†‹0š•ÆQPÖ33+‚Nx}Ü<1¡‹çC}ÈìUlÖ;şîâbùÙ¹³›lÖ`^gİ‰ë[8Ğ$g!ã‹?øSz$0°'ÑıÌ¦Dö9`=q²*Åñ¡ ¢³
ÕrE¶#ø›6);è}>ßÑÕè1á’±{£¶¿5Ë¡×{“²Eç	>ác3n-y0IÎ
=UlÅ00ğEpÃ	ú³ã~Ñ´ˆíljCy×7a¢{È>ÎN{ømÚ½cWøJk"°"¨íd;<GŸĞ`KFØ¬¬?ĞgÖã¿½´)&¹_Sovµü8ÄÁù–„'9Ğ4ƒ²ÒæòÒO_;h
ˆbšÍƒ„-şx©wä×»K2…z
p¬µD8¬2;"úˆ"Z¾8; *†ÒürÜ±¨ P´¥&ÏıàS±o·oN²Q­L6«ío5Ìo¢ü‡
²JÄõ•UdsdjÔ1ŸÁñ-ƒ;~ñßš²Ø\3X†ÅË¤Ü‘ä¬nªúE”m+ Î7)úó’@õ+àka _`ÒOWŒ´ 73»­HËVm—ÈÖü2$AõØ5±ßô»éå˜fÀ®5½Û“Âp¨¥ËZ~Ùã`’à{eK¸yZ#³9«Ÿè!Zè»gy±¢‹£­[¡ ·€ØSÓï¼¸ˆV_›™W¼Bm“1
ğà¾æ½¸:ö/¦…V<¾¾èâ‡û±ä9EA<¯<9ßz~ˆJˆ3N²àXÏ³@¢Ç³qí5\tXúQÌ<<;$*?°Òöºş–®,àµMyƒkR«º[Q{U±m—ËìÓ2Aê- Ô××gLÊÅ‰¯šµ‘ÁıU¨Şá[IN6&Àâ5ØîuCxùS©æPh2Ê3âFB ôSçËD„%# <²á1Ç:ğ¥æK¾Ò’@´aæÀõšòÑ¨:–ÕTábq=§÷†?9Šñ%@xÛ‡t¶ò5=ÅX×>½zX]&ÍßV>Ï{’=WL&x+-ºó†J©‹ê`Ú…u¡Ú0Ñİ•½ĞB[‡ÜlÀ]US¹U*ªBºß€ÕM–.ÑıÏö¢şÅ¦kĞd,ûÁsfÕ:»qÑÛÍİÁÎ#1(I”?#Vı[ñš@¦“ÌóöôªÎ;	WÜO·G…ä·ypÿ8Ìş EYçîH¿®Sì‹ÁùõÙ}ñ”›SÔ/a¹ŒßxeDf½(–Š½ê”•™ód¥Lª, ûyÂş'ñÏÔsEú©Œß–,OÎl ÁM9úÄØ§V]ÛfÄ`–¶Ût)=\ySØKAk·¿õg?Ú(­ì`Mõö–Ée³µWqN)Jİÿ<#3	ÙÛ<Ø×@îgøYÍX„ëÀø+Ã3ê«‰’ïVà•uÎ2ƒØèğT‚¬¨‚Œ%ÜjçâíÍ¦&ò˜°¾î'`2 ”[@fªÜj|š›”g]ºşlåftú¿) ŞâËúğÛ&|æºušÓøèÇŞÈoŒ<ö+\ôwßÊƒ$nWéªÜø9UT“Ø½êó\ö`GT,š0hzìÎYÙÉgîAü›İ¹×ËR&µ=ò^DQ9,Ï’3jümsõéKŠ>õC‹ÙŞöXf–İúc3×°;_˜€FöÌŞ	E9pÍ-+-ÿë;èY·6ñ)¤ØÃb’°U6ÅŞuÁFqè3Ÿ[V­	‘ìyß½[2ImHõ]îä×fñ²ßàĞ¸]|±ùçÖ„öœC!)¿7…°vø"¥!İú=š­±¹ïõÇÏ·µ‡lŠBUG²N»ønî†”aö%Z>y·ÖW«ãYÈ³®ÿápDÛG_Æ#åaøü<¹¾Á{%¡Vu`å3?»¶ºÈ ıi/ãl÷“]äğÙ¬†ŸªŞĞ`®ÓKFoNÄùŠtÿòc)¦Qñ«:Ş"°ş‡;y„wM¤:yŒòpÓí,C QÅÇyÑ¸ ¥-?‹k«£ìİ·oş»hbq†õ.u ö'TúW_¦\™]Ù% œ˜Ø„
Õ­Ö–4pßU!àX77Çš­‰Ù'‡`Ëù¢Ú›Å*mzbs_LÀ‰ İ-©vüwKírhäÉ~k´Äiœ¼váñ¯¹ÿœÍz*Œ{	FÔS+"Ià½&İ Fÿíø6î/ã’)İ*øÍ¢”=©ÂyŒ†QfZ3â-qŸ2Şñ#úõšk›A%ıLŸE\¿ßô“½„A9­‚¸?-Òéœ¡Z§Ëª9n<dR*òv±ƒ¥ÀˆìOÓ‡ãY8äî,wıDv  '!¨û0×éFeLZ½.ÎNõÔƒ*9öó¶z§~ŒëîNŒÍà)|Z3à}ÒÒ|)¹±¾õùí’5éĞ0¿ò]bô`k£CC(üåc›9±şj#woWex<‰ÀØK©ûÛfÏ÷VÙ¯Ş³UÍß¹„*4êîĞxß4ø¥yvCNBJ¯Qì¢š=Ô°¤hÇ~Ø9Ş>Ø>/?=2ÖQ†Nkµ‰é©G½š3µÅMîßc”{ÆU×Ö“/GfW§ôã8c~T/¢²ŠqPÜøÀÓS7×íÓ¦¶6­»zÅÚ¶U$æÑ7¶‰ë‰$(t£ø½y)=®@×X§Ú_¿" 	õw‰‚L@µ‘g"x^»8¦›åï˜?à$)Xkï+Ê??7ıJÌãü“^«,K.+èsšŞMc›À‡¡•A
!¯Ãb-¨jW”«¡	’…ùÇøebu›Â5QÌ~´õB˜ŒxŞ«_kaöl"·¶\³ÊqZ¢äEPsäÁ£0Où—'UÖK²3şÕ	1©SôA’«¬SÜ`”¥öÁ5® Í¼Ésû&E{~ç'Õp‹Ø‡Å=>pŒEI§„Ú‰%Ee‡ËZˆ¬yáS6[A©‘!-J‹†¼´Ë?.¦72z7PF‚_€LTşù}´ŞÀâ]Ë‰œ5Nú2œû5(Õ[šÕ“nİ´#sD¡§7Õ«x\Œ‚G vĞN`9dŒHQ*¦W.5ÿ*³7ƒe]šö*€hN "™RÑÁxUf¶¡¬PÄCBòò8ùYD6@²¶Z4ï)œ{Sÿ¡¥çßÇ`İşzkd0Â{â´`øşzËAÂîğŠ¦•NFà,„áÜUqK§&õèÓO`“­ Wú£Š‚&õSR±¼‡;šG‹‹dvØ¨P"|JĞíÉŒ†ùœÄ±Ğ¬`ô³[q‚¾EÃzKoœÃ¼ÎğÔjU~ßWŞ 	¨|$—ZèR—ªm6 ñËd­."TÏZò‰rPÙB<÷#Üq¾ÆíC©Éq	®?,™IêÓµûÚ:h<‘Uªªún,æ.ÊA÷ÙÈ#)yxOª¡µf
ãÕ^ñ*”˜VÆÁÔ¶95ÑìŞ€Šê™¡ßo‘s*æÕÓj:;U¡ şFİÏ™0:¾ÎĞ)Ö'.Pµ¤GŠt1Ó¾Ú¿ËÎ†Kêç ât…d0…(t,½Ëµıu²Z\h¸W’‡{öâùWC¿(@NFòû‘3ä”˜#1>”¦sŸ›S±nPD¼3D‘ÀÆ%Eˆ4!I:d<*QŞ’d¢ì3£üíÎommr›Ì î´¶YÏKW’Å
RÍŒÑ¶Ï™#ïÃOi“9Øõ{¢.²&ÒíoƒEQnğüìOŞ3Z~Çš
JöS*<ÌŒŸ(RnÇŒU\É¤6¥5•9Ú>f™J®)ïpı\,î’s<0P‰s)	ö¢­Ö•~é[¦ma2ÿvZÇ›8O:‡§&À€<‡Vyßê«=Õ‚ö‚½Ì|ÌM\=­ˆ£O•é¢xmË`ÉĞ1°›Làÿ<LêüğC>è!h Â–D}Ê £=Ä9¶ş?v€ân~ˆÙî\(®Ë
AlƒûîŸ®‡°•I;X,ıñÕárîW*¾ÎŠµ÷°×£p]~}H²ìyšyšÁDÿ´g0»şĞœ±ûÎ…fu¯¦O½¥„+*ğ}+Hœ¯Û^Òü+ªL8^$” Üç`0×,u]¡x‡È­kLõ	3Ò¶Cçï'¢ëŸgfßÿ¶Ú³Š	Ş‰åílYTrµ‘9šÅ a¢éåyÑ1½«LNå1rš¢ÉËªc—€âLï‚)âF·÷7öšG®jQ×¸R!°=»ÎÁ÷¯¾ÙœX“ÄÖõtR¶1úEP2Ù&vœ{ ¯µ~&à8ßŸr°kRÅîâğ¶hzDy¨±¿Z¡£ÁV")sÉ	‚Ş
«¥ {»p»‰Åƒş­i“VY±wŠ5ŸFKC¦,N‚>"*æ@yÑîÏ°Ş^FEÃQ:’G^¦%.­ŞŒşÌ"$aB?Ó	7£ç{5GSÑéjF|YE[ÁÕÈ0 ãı¥¼Hfyi¨P‘ê”Å ÅªHÙxoÁòÏ6Ï-iLS,Á: æíÏnY÷Æ‚Š[[C¾¹*Öä_¾× §÷©É’º‡õÏ¶V,.ü.Ç „÷¾‹g+€IsË¹sjwÿõº%o¸ş¡PÉšoMøˆ•}kn‹«]‚ÒE4;F‹Ìy‡1ßˆóÎç_~móÍ€*±¹ÆÉ
ùQl“2¸f*ƒ-¹Y­ßZıú§hUéåòæ^ßxÛ'Qp××¬ê$?T+À™NcXO}—[õ¼¯m5½)¸ä9élîÓ‰ÉC¬yU­—-"„–ÁÓŞÑÀcYhEë‚åÏ[è§0°=
Ò‰r÷“OyS³£÷ ³—:x5djª‡'èF1!Wb¤U4µË»ÀĞoÖD¯Ü=ÕÆŠ“Ï¹PTh@Ne¿PõNR×º¥‚¢.F§Taô9H”ÑNÒÿ´ ÀpÁ İÉt6ŠKóßIë™
’?3TÏ™mÔ¸A$÷ÃË£œåÀÿ‘ZÑ“W'ızg÷šÓöÌ…4¡Ú9êN†­İøÿ®ÀÃ^•<œídtC—Òœ¨Õ'•<º7TâÌI|—Ñ+¼ç/„™óÜ¶À:º‰I]ozH‡-ö®öøª÷î.Şc/ùI=-kù!gIİF@’¹ïk¿l şˆ&	•ìÈú”Ã±­í9zaé´È/Á:¡“—ëdîù›¹wB‡¡[€¬¤«<ë÷Í^8—™  üx=âu;W@’yyE0–şHK„dg±:®0cmÒí´²	Ü£3 ¯ü¢!Ndš£ù{c„„ô1T¯Ç†(Zµ2?cö¬-aX²÷–¹£ §øÅµ£øVò‘ˆMçS²Şƒ\A° €¯QuDI›Šz-¾-»L Ïj»–brİµø¶¢ıHUf‚ôú‘8ÇHª\~…d÷ı% 1ß”){uºÎÁ`ã¼İ+AÕ	ÕÖ}ˆúpåw'oEƒô£‹¦/,<.ôŞú.,p™O¼#E–ÿéşrå5ptÈW×P–|µ wù  y±oÖÚˆVÉà3ßÄdöØŞ>ƒëlv©§”¥Çí¹`ØA5BfÀ¹¶ü§`Ul$³ßÎºHb)LÂN×E®)ÍÖ“¬Â¥î?ÒëûY TÌÍ\¹è¹‰MAz9mÎ•§-F"@ÆdÄ¬Çÿy2ÕNµW×Ò3V=eÿµşİ‹R
*2İKÒg"ŸÑê§S†¢"Îš ê§âæfæ2¶îœI±Ö4Ù&`".¥´0„#×‘¨öSxƒç(è¤^Q>Ì,4LW=8:?æœŸVÀŠ»ZLvö‘æXeztÛ•:ôé“cŠ°–Eİz,¦É
èZ×/>¹Xï£÷¬ì³lï›ê!¶Mfèc?>ó)Ûó´N0YAùíŠcqXûm»Ñí|îu¬ÄXÁ>ŒY¸ê_ 4¨ù€Ô™" ÀªNéõ=ïÅå:W€NdíFKùæá´aTğ8v#â[;Å$Z„9{®„«áNTÏ:A|Ÿäƒ‘“ÆoHùjo6HC¾érÎ¿öÜìõ¨ÿÆ8ÊSnÅ‘µT?Ş2-0f‹Ü‹?áâ`¼×ŞJ§¿Îbõ. J]ş·%öu«•"~K8­c¨°hsRF;±¡+F­oäSíV ¬´.|ëu"B kÀL†vÊJ\wpïâ„ÁÔšZt~§R§-oç'¿4æÈÑ‹ñê´à<ì»ï‡;ÁİƒÊ[šã?8¡ƒÉ”—_yÆY+ã¬uÒ˜pp(Ù–jÓ@D±7`I‡p5`»s!Ú‹µ7@ªãDVğ’õ®€³—¥XæRó;1Å›¸í_xVîíh³>¬á+	öK}<µ¨@ãÍ]×\Š™©\quâCÒ„Êÿò#“3Ä¦§Uv¢S:ø÷xybĞoöÊ3•*ãŒYZÜ\§™€‚ayI¤Ğà»Õóu7~ôİô˜ÄùóëO6•ƒf—¯¢|5³Z¥fv
*¢³oÆ¾ijÑP¼ÜDä5²/—ÊUÎ­í#ÃDc©7qÅd_cnM‰Å9UB‘)ş†„[CXĞ^/ÆäO’yCÏ\$Q„F'÷gcÃòÃa#^Gj…¢ë4[qù	«<íUûÑaÁ³V96ª‘ä)Û£´ÔÓ	?ázR:®,vŠdÉ9Ø‹Íiÿ@2 ¤0çà˜)ˆË(å«ğsp€VHøŞéõ$Ç=›krF$Ò¼Ñ ‰(UÀ/ƒ}Ãv_4cçíJ¯`a–ÂÀ_€qGœ5ïUH$¹úÏ&­Ú‰
ƒ_ÁìDÔì,Î¡8PÈ<º€º¬›ËEG
z(C·=Å+M¾‚ÇcÛòÅ±(†ÍÈG§2)Ø&R ÷£†âì-ø‡ï?ãlĞf€tÄµ‹µ$€µ1oìXX·«“‘Jëøe6ã­ì…ÂA	„R•{+°ƒŞæ
4o™ÔÔpyétÕ¬Üà÷¢^§rµE«ØuüÈb¥Àÿåk{‡6swÆgá¾ê’K~%àZ±ÃÂ¢ùı—ÂÖüñ¥ôV•ëøa§4q>˜'Î(x•Éü§¾Ü¥‹'½‰´[‚å7gDbz&>–â]—~AdM×/$ßª×j^«ËÁÈĞ)0kÀßÖz2fu÷ò>0	DàÔœ‰¾SãÖTó¯ä•‘šğÚUd6W~ø“†Êˆïn<ø‡£#,$¨¥U‹Ûµr/_vd¼5\DPÃ÷RÏµq3,Lß‚ıdØ÷i#%ğYÍÚ÷ßxãc{?([É¢§­íM“v. HıõÁßİBß!ä°e{ÊJhq¬úËiïvÚRêÑ¯–@Æ¬š[—|bk†~dF¬›{tÖï9zº¹§GY,¿Vû™xÂgY_€|™Mz9ÊxuÔ}m­Ñ²»ZZÒÑsi›5*'%y@Ş(alc®% ´ÆKÕ«‚ğg¼èW«P&´:A‚:_ƒuğH üû¦=z>lO°BªÒyT„iî¶”2él2‚ÃÒŒV!~øwnPí¾‘´)ÉÁÅ¾Ç3›`2è?½‘Tpæ{´f}/Ùı!-yÕA/å¬[|J˜Øá!1Õ‚i×ê¦$xT^Ë)Íåtß!¢ “¼pQ1˜úz<Ü%hÎÚ `¦ùç¶KüOg5rã>…Ó}]®şD¿ÁU5AÚÛmû®&#SMRowÀEr™{«¶R«oj‹³·Pr¯+ˆ¡#wß¼c¶DÊÅV×Ğ¡´yY b Ó;é‚® eéİ+yi+RÁ‡†RfÇfİDâìe¼Aø¡ú>à‘ç™³Y¨ixlŠ$ŞË…=É¦%@÷W»1õºµÁH¼&r;²ùI–ä(³:7.Cb–°3z;S±¡z¹½Šce‰ñá–{$6!¦Æã†Çİ3"odzb5ÒEÛkf!+õ'ä®OIÛ8Xh§š´Y”¬®1'ıØ£OŞ ¬lÜn,gÑO5v#rEÊµÕ)eH^eü@f¿Vf¤/šaVŠÕK‚pJu5*‘£AÔe}w<dVdŒ´AoX4W6=Î{ï¡²U‘+¦„`Fg,EÎ–¤­'BhU2Ær”qœØ!KR[…Ìq´¤”Pe¥Vá¢f®Ô½%FZ0O<†Â™n¦¬C„œèu­p‡ˆƒàZ$2Ü’[Ş\y‹j ˜şV]4—fËôİ$şóL…ÊHMt½ñ(îÇšëÜ-vº>¤ÿ×úÚëƒö—!eiéà·lYˆ¡¼Âí½íï*Å˜\Ky2Ûã±ËRòTÒ0GÍIìáº\ì²çÓ|™g‚Ê¬ÀqÕ®BàgÔÀd¹!™¶–“¶‡% »–Û§néû‹PØÇT­Zã’Ù©§¼³(—åãiæP—«éÒ™qHÿ$ô~­)§çsØ0Ô½1ö=‰çùv®oFy¡ùdÏŠ8Ÿx›‰DıYzü>[»öÉ‘/¤å'üJr’®ïí& ùš!µ íf¥Îò[îø~ƒ‹ˆ®¼§ÇL¸ÚqÁ|é¨ÉŸµWD+ğ7s¡vñ×T¹÷bö`i†#*9§3×f'ì^óäN\]o^±–NŒ3¢¯•ŠGWu‘·4İù+pöİÛÆ°÷æd¤¸aƒú£ÌY3i‘~Ú)?Üå²ôåÁcHq¢”›C@$Dò-ğQ»É,Û$¦íQè÷n,MK
ü¯l~€kï‰‡ÙdY±»haÍDè¡¸¹¨¬ø-÷ú°ë¥ÚAûõ z]ò‚Ï¢ÿ+2Ü=‚ˆŠ¼Î°QáIˆŠİ2ô:N¨ßpùºÀïÛ›±ó/ìàân@­%4³LšcÆó:é“L3ßÌ6Ø´•ãinÔu!í,ŒO¨Ä
TÅ‰UfS( Xì°›õäÔĞæ+ş`…@óÓSîF3a¬ßÎÏ¤@qJ¡Ú}r:³h'•@˜À1;‘«YÆ‹îrŸ7 2edTĞJ›®ı°{eíÒ£ŠªoÖóì'x	‘¡D¨
6ı­I|^ÅuA(e)›
(½sØh¾;
ì[s·è*Eõ	+	ÿ‹4U®ìö5Ñ/s8Ò¼$¿®¯&â×Xë–Ï9S
mqÜ6Y:İ]déoYx$×nzY÷G n›«—2„Ó¹|bMs·äæWŞÌÌg_Ï¨l;Y\€|o£hFã«<Ø«5éxc‚À"ØÛ4ÓlgHRRGòŒØtÿÉà@0”ÁåË*1lÚó$ÆyÊvDÄçºµH½qÙ>]D[íX8²N>kÖÆ*ºp¢Õr˜Ä.ğ£Dé%îQæ`Ğ½Ó…ã‡pğ¾¾Ç'÷¦bñÙ S›à]ÃQ›½ş‘Ot–5èİ@y÷ŸQ6bg’ÒÓ½+i‡À
‚wX)LÓ %ÿ¯#×Úû$eşÍÜ§¨Ğ£ü¢ÔŠÆ¨X> *>p„¨şeÒ<œˆ=Ógví.äA¦„iªä¨ıÔ‰*íİÔŒä¾ŠÃíQ­½~‹Jç6Ì—â¦¸ÍNT‰5İµNâ˜Á ¹4,Ì2W(Ñ6‰B0gFær+:ë QL{x“}ÄÉì¹3ßIV"ñB`g"(™}Õ×ÑÖ^}NUx¼7©öHÔ¢¸‘—2ÄÊ®}sFyöN/¼wóâˆıüÄ·4Ù•‹Be¢ÍîˆPqâv:ˆÈªµ_@@MÉ®®9¯u4d;Äi3J}g¼^‚cw*«<jf3šŠ÷ºI›…7tM½å¦5şWÑ³K€£Fç±á]ó
µ”pª™§nìÃ†¬jdHI‚ÖŒ>9Ò·Ó)EXê¿±pù'míÜE±O/sö¢Ø¯›LÇ&òTçªT{x\=[+¶ñÔP“QSôS‘ÀmÏ\’âŒ”tv+ İ/nÁÀf£×â	nÊô¬‡ëéÈíá¹›)Ù˜(µğñéùDìi€HK&!9˜Ø ”ÍhÒ¼ÀbUŒm‘C§ÿ™ƒ×şõã‘“Jœ*‚Rv¬DNöêï*Ä“8Vq¦ÔL»q5ªk¸%üMÅ‡ş¤;F2
%áú4eèQÁƒn8óøÜPëDÖošó¬GUõ÷¹y…»¬®£5=x§Hd	»üsrv/ä¡y¨«åÙóëóe/Ÿñ¨Y®kW×Ü.bëübèlÌ¸8”ÇyŒP-RÌÄè!,~„^+³©ç6Cx,º1Í¼-ÿ­®9‹J|ÓúµÌ.FªˆOÌû­ö€‡AğåèÀ‹¬ÓU°wu¸F=Ã¦ßQõ[Äj{úèqüŸ¿Š˜ùaJ²”¸­ÉøÌh²V%õ¢4Xş+ Võ¤ êÄYd»˜¹Ëk%øt{¬0”à‹ø²Ø—Á§®–ÑçŠñ§ãÃUä(!3,â£¨ÏÁƒ¾±²Ú+‡‰K~æşÿ–âúeÉûŞ" !˜/Gk[~:û/w9º8èGæ
õã` èËÀR¤¥Ší»·B`ğkšÛ [[™Â@H7Î7Ä¹Ÿa®şQyü-QÕiŒ m…ß¥±{U )%1Ìg—”IS–âÔÎ@l£STØ¬átš›‰–p–î/š®}UÂDyö³3·çùg©:"3ü:Ì>ÂĞ…±&+¢Cç`i¹š“—Ù±{ºS«?Ú)J+„w§öØwBAu8ñÌ²>+©Ov–&(6w[İö€³ÄA`BÂÊ¼¸=%ñÈŞBÍÇ.‡'fÀ_÷•ØŞ´C®R¥Jì1Ò1‘D¿0Ÿ}¾#O9,_ï”àæ,¥'‘–ù8¥¶ÜØ_E`=ã©%šDÁmŞRHgYtğ9¢”a×à&O=ßæ°{m?àX¢$æØA,cv7ªmpµÑz±Ç„…©ÅôÊ¯ìSñE£w%4&Iô¹äÛU ´ßG» Ë“†­Îø†:Ö\ˆ6¿PÉZjÆşAœŸc‡¥Ê~qºÑâmÁÑZá…Ë·!QÿGşá>’‘Hh²xLÉ„àôIe2ã@§’3ì
æHı$E=“IˆSÀ‚d‡|,•póñ¸r\Øó/÷k[z¶ĞTî€Ö½aü¼/G”@‹ØöB{Õ.f"wãH¡û}åÉà?Š4È'­àÉØ)„›–êšíÿ»nÃÄáí&T:Ñ®%«#¼ïá@#õ« =Eƒö%¬"os_SsŠÊ¢%ù‘ş.qS<z¢¯ŠW=Í¯À"Z¾!›Èä(ŒËÓÚZÛÏï(Ú•€ÈÄõóÎçÛW“Ø*Q­¦æÉŞÓÚMÙ:£å#Óï’Z¬Ãj„[_qôÁóØã1ÓÎ5ê;BL¤‚ÉX~ö&	Ä‡eÂÃù€ö)”º&Ó•FŒ	&¤Ë•ãR.Œ#>dâDğÑH5ïßÔˆ>=Ë%	˜Î«‰,
ìTòÂ¸Ği­›}‘€ü<k‘Œƒ-]¨ÎJév&x¨§BÆz¹-±>xM±js?µ÷ú§Ù´á^c™âÎæ^W£Ù½#Â¡]5¡¸ºé”­X’„Ó9ï#˜kæ?â¶aâ6¶+M,PÙâZúo¥°××Ê É¶{("xË…G§Ğä£©jL2ŞıJª^MoÙµÉ>”¸µp/èŸl1oKšé\]÷oÂk¨ÒK¡´ğqÆÈÉCón“N?	ãEÌ‚˜óc4ñA’ „tÊéc|˜±›M¾ÁèËKIŸÛôƒ<â…uı~¸ı„€_d2ñ#16ù6L©ú£Öøïé}Ä¿qí!ˆaÿƒ®ŞiÍnÕUô—´iA=R[Î¯Ê¾ÉËë\ı!Ù–&áDÙÈ™í	´M`T$‡K¥	r H<ÑÍo•ê£ÇsP~¾úÑ¢ß(9æÇæø*kÖÎ==èÖ¾d~¾o‰Õğîğ¸zÊ·Ô^îDö_/:F:b*Ût8²í@I«y,UÏñPjœON`ïMTj^tvY¯±èó|å+ĞÇaß¿ØáÄ}›¿Ùq³éhÆq&¡>üÏ'­qÊqÕñU¨-+C2U¥ä~¨ˆ\äOĞ¯@—cÒ®9¾	AáfA=Âu<¹K¶Ÿ¦©˜’!]ş åĞ9ÌG¤Æ{æü£@›ÊÛ«
² (¥öI á‡a½ ˜ËªWºØF i-§¨L ¼Ù¡~Ş<ˆöS€ÅŒO–Mù;9üĞ=ù
	.¢+ak®É39÷É¶¸Qˆ¢¨7š½a„Ç¼%Ñyîƒ)JvÃ­´·\ÆJï§
lÎÜ#/n~âR‹Ûóëq‘×dI‚wDFğu-š¯úºk³ÿ1“^•¹ÓµËs-3ë‹$mùóctÅû[ç_×,P'1„ºÆLldx*`‘e›=³¨SZ ç±Ÿxñ!éê2`­¬ÊJæ¡ŒŸ)ï	„AƒùÏ3÷eõö»z<]ĞmÁ#xãÎïı
Òª S…9;­I U° Ï“—uÃ–’•¯&ƒ““‚û· ¤häª‰Õ©[Š¨ë$!ƒ+9íûşk´˜|±ãôIMd>øõ5aY¶ÓU"şHÒs€ekçÁ•îĞò/˜cvèßÁ"­ŞkŸ°…Úmá¬Ş$Ÿvˆx½Ãaİ°ò«üâWÁ©<ÄŞÔQìq†Ğ±Råv'  ’‡×ób¾Ë7,ş.¤…]í¢gı†“r^PñU9ÉäZ#‹Ãjğ^±ş{-˜’iç+Ü¾<¡‚©×
x4¿°ºf&Ò6¼@`'½®?•²4Os"ºvæÓíßNÿ
F²sÄqçò7—‘XõÊ³FwKb('÷4(<êa± bĞ!~E¿ıŠÀãs¤ë}¬[Ö½ú4<ÎUÖå½8û#Ü]Ù‰¸-íéwàJ{*˜+Ü†qL¤`%4À_­ûà$ºx‡³Œ·9ƒ]ß@¶R^n§"q—ĞàÉ†kÄ±M¾Û	ÀY;s!9Û"Yíy |È;­†=wÃûŠø[/1éßƒ*Ö)‡?M÷%£°Ë-7$ñI·`ôšÈ8Únœp„Î{)öÏCËQ~nó¬ç³Î;Ï]Ó{<ª‘ãu&=8“*Ñ§‚¤ÕÈ(œO(Ú>Ï;èËP´ù‹ËúX¯ÿè%†·8F»"™¹`D l}g!H³œ²í`:ÅÄœo°kìÚÕz;- “æ‹UÈÏ%‰¬€³²~˜’úv½Q;øé¯TÂZ„ZFxN526ÎNğ½7Ò§«<´afÚ¼UaµñÅÔÑèx:¾	GIi¢fºlyR"`9ñİ?aßšIPğN(9ñ|ùtDfZ­Ï†¹Ï†·”Â¨jğ6¬·Q™ñş5ÕÆ|½ÌULdø2w°N¾·‘yşo9xşÁÖ ËŸvk}t›Õ›NÌF´ü"£ İ­yhŒx‡E/eª®JÂ¢‚óCl>,>œtÃÅ‘¦à^>şà'¶İïºR¶¯ıGŞ°½Îêbº–×£‚‹/[{²7âçZ•øQŒkŠˆ¡œs_øÜÕ‚İíŠÕ?©ø¹RœˆˆÜâ‘Ûë%ÿÜ±4Cö–ÌÑ“]n¬êU#¸§\\i|P¥|ÄçÁ„…8½ãü]CÛz†>¿€À¥•Û·F4	ÛŠ}]›rCªpu©şô‚¬7Â¹l'9oı9Åş6Â
ÉhÂ%@ï¬C$â‹.Ú@JA”ÓÃÆ@¤±“b¦zÁ>ğ€îùÜÉBd$ÚÑô~Õ¥wt@È2ow\é 8ûÿOvæ½¦Ò½Áfy1àœ³îÍ[mnŒü	fñ5,¸¢ğç -8ë
nyG¯}”æÃe/ğ_ÚÃw‚SaúÚ~çÌ€Çµâ²¾œrÂ%¯ó9yq¥ıøH"ßŸ½Šá&y‘{Æ ¹|ŞiQJ)—õ0d,8át×qa©õˆwg¾ßZ©•™ó(u/-§„›0°ØSqÎH‚€!aŠ3TÄa{„Û†ÀKıR¯‘ƒfè©¢ØÔw±Bƒº<Ó1¤‡[ßHR‰hë;¢CİrRÃ­ƒ\¨£Ç7ÖmÉ"aø“e×<œ˜š8:Âpèg¨Æ
şO.à6‚ç‹9KÕÌíÊ7H œõ—:ò{ù2$R´Á¬Œ÷ÂÑ•¢¡¼Ë­È"ÓT.ÂÊÏQØejñ5£Or@.[#úe“¬æNT”‰ŒXëÓ¨ºTj¯ç—‹…8§¾¾§Úã?¥Ëqzë9ötr°ûæ%q›ådÚj¤[Àûh€èù0ø^.ı”Ğ ¦[î¿qõÁØ1ê0ãÍæäËrÍ¥“æÚ¬»‹Ã{h£2Âì'æµŞ¦£Iˆ=­¿˜z!jª§™J#Û×ÖJµŞ[ˆ‘/›„·íAÃÈO
Ü9µ/ªA£CÍoñß„ŒmÚAÈB£Ò¶É¹8æà5æiÆ{D|¢Ÿ<B£Æ‡~P¦ò9R&WS&SÑ¾bdx:şe½†Qö“Ñ¬Œæk’IıAFÑ”Ã#Â…h'…ä§l+µƒÏJ
K^c?÷µßsĞÃÚ{ÙŞSŞ
ïW  Š«^Œm¹ò9ÍlX ê†£?Ó²/OóµO(»ZOC<Ršõ™~;&İ-œ–L®Ö…J»K*ğœZ4\HX&®xâGİldZíh£'\îF`.áÛÕ<‡M-î‘ˆ0 <¾İ$ì}
³(ä q±Á§Û›ĞXg”È ®ñYÚ‹æ—íšûÕFŒªïd$×äÑ'Ù]Ò:BÅ£!û†³ŸG	nçŒxÇM…»[)‡F9åÔ³Á€ş\_Ê˜8…ÙŞ=ı(óæfÀŠÓ"¦wcçÿ 
§ËMÈ/øïCYSás‰=ÿù¾Æ®3¥v\òWî‚§ÔZÁE ‰‰{"­ş’2ŸÍø¼Ié`>ª¯°Ğ&"akI± ‹jş#4ÃÇBúF\+.3Œh¬¡gÖ ™˜¹uĞ•–Ö®ùD‘æe=0®	N€#¼AuÜéƒ…ÉÜĞQ¥ooıwÂbÇj¤Ns=ú¥šğ/^M(zeßZ$¸oÊo«/Y	°rìİåì/Ş_qö®Œ©èAˆğ'”KØMù¹jİy“úÉşÄ„¯W‡-<9LvÈ¦H	û˜Û©Ê-±§ş€©È4`'¶zÈxS>
:J1÷Û:2f½šú,êÏn§D˜Ø$¹,T@Ø×¾iDà†`Ös™éÄ VÃªz‹÷úâÒÂ«8gvËv¡™ÂuÆ=gõÙQ$IQ0bÒ_Â{ÒÛŒfšLÂœ^/yÈ³‚`ÛNhª«§Â¤XÁ"9ô_²òË”o|òL»éV¹VX’¡V-‡û‘.Æ3Ì¶¥/Ê‘ÃÁ·rmAQÕ¦gPü©¤ºŒÚ°ªŞÊ´ï¸€Ø0Õ`?‘»Y&ÈqT¬á5İ•ªËÒvÎüù£˜àhŠ¡Mä=Ñ¦¯¤üUÂií«FİiKtÃ±0ú:Ââ ÄÊsSËÚÖvYq-@é0îÏ·¸4`ªLs)úäÕ}»MZ¡u$³<óËuîÕ‚É nuÈµPË€J?Ú1“ö&ş;şôí¹^L’}¯¾ÃA92îÚƒl¹à)§ã³¢'ÁÕÒ$Ì»ÅT2×LÛT‹¡KRN°BÖ„×L*ÊRtVñÕi+Í„ÜÃy?ÁõÓwÆÈ°]˜^U<Ïd4G'"Éz®û^Ñu×”¡µW™swµµF¯mzV”•Üˆµà¿µÂ]ã}Wí’2æ"ƒ¹JA§ô'"tfâ2GåRLì;L¯›À ¢òªUÈ#”’e¥ü¡³ú&Ò´ò?¹¨4DU7£›9Oz:3İ¤¹?AŠ©b„MÆŞƒõJZÎ…Îÿ>¤êøa‡H;£Îp'Ü#éß ³UR]şeÖ5%+SºŸ_î‹t©6n½î‘ú“@–›y«5l²n°Ñû3|÷ƒz">@`ÈÖÆhü®Œƒân1™HÀGMV³?Ó[4jÂL3'B˜TÔ'N^ıä©
5'mĞ6Œ°.šñ‚>HéŠçæş»]YÆj‘¯{‘w=ØŒË®ÛGó™w}¬Æ„´{"¤àŠ‰î§ç\¹f¾nà‹yZ8Ø£º¥U+ÒO»hZJwm)Ô°b|`âUu ·µİ}fİØ‰ªù,–ºˆ÷½-§ŠU9qòyà¸xÌ‰ !4<Â­¤V?2<åÅû†ö=¹_µ6Åî•şòvÇ
l@J™õFF@ZŠ‡i[† Ò^Äx>	â®*è'|™äŠ[§)SŒâ™Ús‡)cÅüV[ÃÍb×"¦·ÁU;ùÏßÿÄÉÃ´5X“ü™*ÓFDÖ7D§dv¾£\l¨“!<æÉ¿ëÚyòh1¬´œË‚pqÆ«ÅzuzUØæÍ›Ot_gC$%V%¸|’JŒaòèÌ¢ éœ$pY ‹‚<s"â”k¼“;Jm—¦yr{m¬d¯gïº¸¾às½§¼Š_œËÚîíë«3ÆÕ"ädDcµK¢t7Gh°cl –A>p·ce¹ybaª#…ğyÁ^˜Ä—şCU• KvœEoG~v÷–èKOXÃ†t¯³˜¨Âœ%t"gÕ„ïtšÖ–¬¶¶)§÷hÚ—ˆTT~x?dE‰“H¤F˜Ä#RM;;ˆMÛ€oıH¥MãxçgÇïO|°âócúCæ&÷Ò¢
Ú ôvñ1zu’	„Ú’Á²½ÄÚX,¿°Ï‹; ¢f~ë6‚ÓvXÆºikQµ?¹ßLsfğæ¸¹Èõ¾¨Y”­Œ,BˆZÔŠ˜Ò ~æzòy Ávù)ºİø`È—œSiúøúd²äfv>‹h½ò²)jùhÜ¨Tš¹ç™	6PKÜÇMcâ˜x‹ºáŒ~ŞÇ°(>úkãSí—İ(Gjxpô=½n²¿£¸($YÕLÄJg¿O(H†ZoIı7áŸÇÿŞ+ışäYa!…‰»²4xUtCõQÅ˜ÍóçœQßŠ¥«k	ØÅ¿$¢ó›§áAÓ—ÊXå‡ŞÉ·ìÈfAiÈû.7YåkĞNùXœúJ¸³Úö›h`¥Y\ÒÆÚpB˜à~¸`9U°Ñ`Äe7îC¹Ò¸ä_`¼(ù(‚ñ$H®‚[Ú™ó‡Gn¡{]Ñ&iM6vÜˆ}æ3.ÔÚò4|uÙE«%7/t.8‡ç‰O£EÄïş›Q
¡\%B=  =÷Ó8¦¹ÛÇ`ñÄP·\óÄŒ|#©\/ `Aõ]4q0Æ™tŒË¹Ñî)´'
·ÍAÛ§Ğùk…é/ÿfªÁóÎs“K"+ˆØÊ3¡†,ßqËW+h?ËÛ ‘û1T!c†õÒÉÜ„ÌËÕ¼ùós*‘úrï›İ ‰AR¶¤O–pfŞşWÀKÁ©ğâöÎo!“æ_’f=˜
vt°âÄ¹©–iLRPtó½]â›ymg7Ÿ!ØñµÖ§=>[s°ÆéJL³¸	\¹¹H2	•Á„ÁBÍ7(
µç?ëEb~Íg¥ºußR7ºÏi­‘O“G±;sFEş<mXDoårÎıÑbÛí©¥!¨¹şdÒ½——ôÄàBóğ"
}[F_AŸÍ¨½âÀ@œCøÿ<óšğ+ãˆ}mL~æ.NL?¤­_Z'“arïÙdÄe—ˆğ½“ëkÈÕ¯Y…úã2óÄ-Óˆ¨àşl1¯Ï0+>tfd·P=á*¬¦ÌßÀz ¤{ZyCó,®"ßûEÿ°˜N!Zxi	X$Wñ£Q D’†Z÷'ş>½$Fµ9
'¹_/ö"²àHwÇQ:F<úÛiD*ö şÆÖiD·’yúˆ†INkÅÑK5ˆKÿGc ³Wµì ¦Ê—Œx)Ï(>b6ÊFwòñ³÷ÓXP9Ñœ„§>h©–í`öŞ£ô¶Bğa> ~XJp4Ë¶È‰E+³—M5nº·êµÎíÒ?¥‹ØÏùÿ¢alM—º©&½Ö)×Íg¸P[Î´²èÌhÈÿâ¶ü ™:k  Ìi…èkğÄÜèä™Ù3/nB~&‹#Ûù´¼£€Ùöør~†§’«V¯aôUcŸj{èQæûò`Ä±<.ê!ˆiÂ@>‘Ë4›£ùFƒ‘ŠGï†v¸Ôëó¼L“)¬lrÆ«ÑQZœ^P}˜È»a·¾ŠdOÖƒ|quóÒ+ÇÎ;QYäUvĞ^å`@èQÅ'n$OTó
®¢¢šš§u6®;ñ²¶I¤•2H2îô¢½^á[íÓÓ¸—ó$ÌüY¼`’&ù"TUÈKi·Š
/i/€ªYBr(IØ¼ïx~—.Ú›eM«Ãv^±§ªriÚd#²Dó'î”‚ì}işô.=ó!{=µe§æ¡Š7@Ø°"Ä-Ã	X!²¨™RÔ=¶Õ†*Ñní÷Tæë~M­J2ÏY±GFö"wŠm:0àJÛ¶AK8ê¦RÿyÚ v°H˜;Ç9ÉŞj@Ş)¯ê3‘S{)ÏjZÂã™úia‹À£¼ÁC·øj
ªåÕL$X[+Ç§~ùµ]BÛ¹›Z5JU–ÇM úDLärúvX¡®äÕŒı˜ğuàOë‘œœ6‡ZÆ›”°tGtoˆ8Ğšb¦û,W»,OµC´0Õ÷pÌ!·f äáŸ©@MsjÖ9“;wvZím½ìCËe†¸Íç˜õLÌ¼>„^npˆµ…Åû$Fña÷bèpÚ+nßûCÊ3Š”³ŒJÀØİUŸe˜_óæíÄá7K™ÈQB†Y'<ïd©’%÷·X¬Ç#cşCÖÒrZ.½á‰æJáÔL5‚BËíÑ}iQÔÃÿçåI1›äŒ”–Üx5!M-k£/C#óWŒÂ¡·Æ
cûY¢»V[I½y¸g«z;±:%vø’ëNñF‘ïvôÓ30ó"~Ìödb{Íq´»Óï…Z>:ôŠÏÄØÏYˆT»2N½Œ¥o\ó÷Ğü‚`şÄfÔø)+g^’„ôL2mÙgÆÅ¾¢ªMÓfQÿÏUƒhèp)™E.›¹®~ĞŒ[<mÅŠå´Œ²M‰éØ¬“à”¶îk”=nIŞûc©Ì…ö\Òºf¬ğàPPÔÆÖ*¹’|\ÀÜi‡êçHõÅ¬Ï/4ò!«ÓQøêù‚Ö$Ãÿ¼¹èAì´_~CÁú6‰
É
¨Ôûõ÷‘û”gq†j_`e)»Âô±‹şŠVŸ¸…iFv"µ;Ñd‘òıQ@»É_¼µÛ·gwgp9@ûVÒ©KÌ¤XÓèeõoş{e ¦OóO³ÖĞOÍ œWö»IC 
-#råíùj„ç¤çÑ2Æ¾ï¾ıGúåˆÕ§N”™|6çG¥ıÂ,1NO8…aíb©Î2ñ§«ü=ñFd)ç¼ãW?ÁÓIä/O¹ê™¦y	.hføP„ízä%((h.¬İ®¦…>úJ ‰‚ÿ±m\C(¸º“"œb_˜Â Ì:·¼˜&½ö•+lÊX@Ü¼½ĞN¶mÜú…*Ø?ˆ‰h'İ†Ğ@ÌC!ÀÚè‹pÚ ¦â¬´¿¢ s]y¯XóË?MÅØÙzc¡cQ© Å¢=†Rt.z-|¾L¶˜0èKAì’í£GßÈLß^J-ìn²¿d"Fÿ9óc‰äa½¼ÖóqÇ_É¬;Ãã$ş[#Æ‚EÎiBI–]Úë¿qAIú¢—£”\Ğ™3Kñ49 \$Ÿñ<x[š.Z‘ Fæ²Õ…FúÕÍYh¾Áâlü›)ÁI‘H2œõ*C²Bw;m¬0i¾m*Ã±‡§AóİÊ?*P('}s¬§=ğü;†Z„!Ï6>{££¨G#$,c˜‚´?x¸¸´„¬g8‡¿22|"%^v
÷ziN«\"å1uÔQ¹ñDıı«óÓ@ôœ%ï’_>qü	s¥myyĞ6ĞÍt‚é÷˜ø”SPÁì)2´Ş†›´"íòøòT"bXXC‚Ìù9DÀ›ª	yıw3ûù“//Vİr² nuºQ¾Èwu–ŸM	Cnì åÕO;]Øx>¼u`JDÕæB)9Pß MìÏÅı0CZâJ¤zøtÎMôüOV9*~ƒºæò‘‘o!rDêD¤±Ì	ˆÁ,F}P÷Ä»ÌıÄj
İÍô\$CfN•¦SF»xS£sÎ#ææLª"CyudUĞDÎ×4Şæeqn¦oge½4ÒÚt±Æ%'L¾ÄO4áöV*‚{ê)7Œ;ÂºğdmŠ»Ë%´Í¥n\-H7<sÈD¹â'TtğS_c5jÎ>²àşâú(ƒ¦ú&WÖƒ+ wx}2pn=áø å'íçğU‰V?µÙ:_ô(R˜œ	±ÑãAvÎécµJÖ¹9RÌ˜DDÔbØ¬^×Úoù8š,MÃ|)ÉxÖ5¨‡”utìéèƒ¶¢=Wıİ¹˜,öÅº<;‰8ÅQ• ·[`u>úÁd}$?ßLp—qÜ‡iÅ×z=Í³6<ù{»d ®¤G–şK™Ê1‹†…L†©#Ö›Ï,wáıC"Œjp¼¼Zë÷¶­~yµ4v{\0(yôtÙ¦§0bQåã‰ï¸Ï±F*Rb{(<U‘|äAŞ¸Üa›0íò¶ª½‘³)öX¿AT^/·%Óbß¿ä©Àìi|»e2Ó'Škuo9y¾Ø-ğƒÉ¢§F1ÓÏœswVbGÈ’DC8ÑåîR§X§¦ö%úÇ¯˜Ë©”:ğÀM`î'Óª’XC>/Ú¾˜+q¾Øî_YY·²(CöÇ•šîåp¢/@Ÿâo]Œ1øjvuuÅkÆ=éJn+ì!Ô³Óæª_™î¢‚.¸­eÂ‹K‰õâ"Ï?^€ï÷á±caĞq#¤ï$÷Cà—²z€Ñ¡xŒ Ÿ”ªXbñµÀ%
âJíHåcNÒåG¡íy|óÃŒÕXã3‹ï: ¾‡î´¨æç™5I5‚‰>Ğƒ:ÌõïKõnf‡4h­É#ñ]¤¹µ/P­PjweÜ˜™ø´qT=:ÁhZŠLm9°åN'ˆ>g>»%i²{H†¶Ác8'
k/ô»5»ês/–>õ¥#;€ïu’÷+Ó…)0èOGéUÔaÌŞ³ÃPÒAğ1I¯Y‡uähòÙ†£€	 jƒG²ú£ldéÿ³¡zÿ£[ÀnÅÙlwkÀ:³ò5–‰ˆEÑ/Yä<~ò¸¬•ìÊğdõËÇ«É·x5ƒïnÂ¢Š/œŠö‹ùROæxëÔEo8z¹d†ÒÊâ*HßÆîR‡-Xáê}ÓaI|ƒó®ëáĞt·ºÂ’²Â5¨Í°®…v¸½×ÔşFïzoUÃ=ÖB¤³øHŞ˜j[Ÿæû‡}+µëpÚÇEâ)Ûì^îŠi—*B(ªåNş®Nƒjóuœ&È`5ÏFÑâôm[z&ö›f?
s)_‡ĞU·¦_±Ï}Ş‰g¥˜vA,^½âó¼°|ASŞó	áˆ+jw"#3”r†2b;ix"mC;y’R}ìy<éUøäã7cp-(Z^/<ÂcÔ}»dÚT¨5±Ï³äÄı`ÍWšÓŸ£—0$/ÕlË¥Ú#:ñ½6²²âşn4mà_L§,õò0<óÕüû‡Ô|èg›Î€·¹nÆ?¾NšWOÙ­#åÑ–5rĞ[
á ÍA¥E—~ëÂÊFìOóù°¨şÙˆ)¥,tƒÏ2u€ÎƒHJÈL$:ÖÍÒ ıØÀxD_jhƒİo‚[ŠH•UİË«!€Íò~©&XÏ~2Z%‡£O¥àaò$‘}O—šÈÕ’5ô6å¶ö>›È(‰€JíÁ9Üó¶îKMÕ‘ŒÙRù7ûÖüÇ‰!‡G$D®nAõîÁöÆr [×QıºFŸ ¶Eh†‹FN…5¥M±[†¿ò¸©ÈÈòsÃ´-—óÅæxÌ«Ù—xìòI›S¹®‰ol6¬ `OŒÑ¿n¦¡.j¬|pŠPçòf¸Tyõ—Yto}TAjÚKv¥—T™l:Ús¦ü4y×D½Æi>dØ"×ÚÎ¶yG»fêk°b3 úWL[kÍíòõeš¡³š˜®~°ß¾¢C IÀ|*GÏ„)RÆÛK¬â=øó$Û+±³ñVPS¬îa´c+Í8s}z-~¯ğÔ úÜ9öD=/òê4.ª|Z²æÙ¦ı²ÿğë†ùtŞ¬„”Û#!Fñ …Üô#%‡—2á6Wf®
6EéÒ	Ì(¹¡É¹Ñ×Øı
k¢x·¥2Í±Âæ‰Å±®à¡.e·CT¥–Ì(‘k›c#cDÿ«­ÿ ë+ÄE{Ó&/AVw·ÀUy²¤ê:Ö]C(T¨“¤UK›nĞL^Óí ’Š‘Ô‡ÚyXÉ<80`öRGá.ˆ«ï~ìM‘¡NBËe–¸Éq	GÛ4M¬ÊÉ§«_1ÓA'P” ±Ğ=ˆZN¿˜yëüòÆÎñmÒt<Às¦Ñ&ò)ÀÖ¬÷ÌÀ¿ÂÙPÓ&şıšçûdNí–zZM-«
,òk§»^W‘`âçLõ•<§ñTM.A‰ß(Ÿ¤6ì½èH¬ 86a”°áS2.¬F.&‘½àÙ{_~CÂşQ÷>UÎn»;£Šºÿ}…şÄäB,:|‹$°gôT¼ÕúJ)†°CÜ÷W~Œ²uêVƒ_3ŞŒ^DZöSA*è«™õ gÈˆDa?€ÀÔ³ºÜa tÛ!z«áÌp~ÔÖ¤ğ*ßF³¨‚ÕÔ:zT§j{µ}§@ş¤9áhSÒdœ©ıë'àqşR_ÓĞıjÍ¨8 ¶g*i±µK^ÆEÜ€`îF;Arã.GÊ˜Ÿ—¢N¸X³Ka{]\¶Ê¯Œ°é¤î²kéÕÉw›R5Æÿg$¯xPéú—©ôJi(‚»ö×t|í7qJYŠ[Î;}<á;ºÒpt—Ã ‹ïè‘{ÀŸıà1>¿ÊÏ¢·ãgÿú,„ª%ò?&!Ó¢—’$·Î,vc:RNËSÒ-9!>¥füC)>¶¼ Ñs¨+‘ƒ+vá[Õf}¹ÜB".¾š“¦lù½ÅFk½®aûe¿¬øõ–êF{éx¦€4güHïmCer§Æ×!:¯<²ÃçÆgŞ©çÔ¤Ÿ	¡-Û§1‘¡[Ö““få¢µCëŸNCÎtDT8ZnµËµôm”“zÛ®hE<z†é^°ïÕâo«#¸==—S[¨®‡££¿_ù_zSüÇvşÆà›âMV?9e×x¬CÇÑR0*$¢—Bß70[q ã£[:[…r{Í×f¯g' Õ‡Ôçíe²—}c§@oÚÆSğÌêJ†v«öÍñ]ÍÆƒÉ?×O¨0J(~ú{Ğwr0BilÓãp;¶şN;µ„¡Ø¾´i%»]&(§2_ümØZƒÛh7°n—ü’<Ì~tŠP$mĞ¬Ew8Ù	ÁnWUo.’‘†_ÖBzé\øÏ4ìR¥F$"óş¾#ëªõÚÿ'äóPHù„l… Ë?ò9eòÅü–{øuªÌ‰á·£š	ÈUüÊz‹ŒQÊ±2°¤T'-ü?y÷²ÕtŸ•8Ÿ˜¯zcÆøK6é\As”Ùòa|ø8şÓ/17ä½	ª~êé6¡YÓ±H)$-1³Ÿ›í¼ªÑ»ÑVú©Ûİ”å8êw%ƒ‚o.3$SJä™ò m—PÃ~¼<ŸâÇÀ#) sÖ(ıæŠ`ô>£Ú0İxëOò¿ÛIQaĞ4FÓrğ·Ù³Yüà¸}UìG$p·îf-ÈiW"6Â;•×£Ë“­„HÂ¥=Ú¯Æ‰KIe\†     Å+xİ¨üƒİ …¥€ğ=y¹‘±Ägû    YZ