#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2806461575"
MD5="24df1a0a4e4aad35a874de39b02a33b4"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="19608"
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
	echo Uncompressed size: 112 KB
	echo Compression: gzip
	echo Date of packaging: Tue Nov  5 01:55:35 -03 2019
	echo Built with Makeself version 2.3.0 on 
	echo Build command was: "/usr/bin/makeself \\
    \"--quiet\" \\
    \"--gzip\" \\
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
	echo COMPRESS=gzip
	echo filesizes=\"$filesizes\"
	echo CRCsum=\"$CRCsum\"
	echo MD5sum=\"$MD5\"
	echo OLDUSIZE=112
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | UnTAR t
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | tar "$arg1" - "$@"
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
	MS_Printf "About to extract 112 KB in $tmpdir ... Proceed ? [Y/n] "
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
    if test "$leftspace" -lt 112; then
        echo
        echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (112 KB)" >&2
        if test x"$keep" = xn; then
            echo "Consider setting TMPDIR to a directory with more free space."
        fi
        eval $finish; exit 1
    fi
fi

for s in $filesizes
do
    if MS_dd_Progress "$0" $offset $s | eval "gzip -cd" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
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
‹ Ç Á]ì<ÛrÛÆ’~%¾¢âÄ’cğ"É–c…ÉÒå(¡D)ÙIljHID €€”l­>fkNíó©}ÙWÿØvÏ`páMRb«öb–-séééûô4T*?øâŸ
~vwŸÒïêîÓJö·ú<¨n?}VÙªT¶+»*ÕÊVõéxúà>Ó0bÀƒsİkÆİÔÿ¿ôS*÷½€—¿<ÿŸŞ…ÿÕêÎöWşß#ÿK›\X}oâ;¼ï•ÿø¼3ÇÿÊ³g ò•ÿ_üS|XîÙn¹ÇÂ±V4¿ô§¨Ï\{ÆƒĞ°‡!ğ€9€Ç,òàUà…¡ugÂ¨…›Zqß›!İ¾Íİ>‡}”Ò)viÅ×Ès_@¥´]ÚÖŠ<ì¶‰¶Ó±‚ü}Ï˜í†xÓÈvyC/ )îø}Íúñ\Ğe# FÓ	w£°¤;|øbE~ø¢\¾¸¸(ÍìóÛ^–pz©”vŸ•»cî8¦\ÍdÓÈS°=×D|=Ó¦¯”÷BgM³„JOä¬ŸM¸Ò
×Gº÷§øŸçG¡VØo·;vó·ÚÆ¦VÀÎšn\Q£õ¦Õ9è¾ûôüşZ×
4så³*ÆàšnšHÀ4ÃÁyŒ~	xÈ#õÛdÌG™æÔ çMBŸ¾…ÜòïòMæÁLLô½ ]Ó
öŞ¾ã
q½†ZÌÇğş=ìA4æ®VÈnŒ¢Áˆ»`¾Äš0»ÖX<}pÏ…€GÓÀ…ŠVÚÚ5’1&óV‘²í·ŸaŞiF©|÷UäµÎûs&(ª!‰ñ±ÿÏvvVØö¶vìÿîWûÿÿØşOÈô›½ÀZû?Kí¥TEûÓ^@µR®>-W¿[ãğÉõ"ğšo˜³şáHô3ø%®â"zİXğ­
Ã>eÉ3ŞDªà„ÅË”îÉÒ‡c´eh\CÄØgîÀbÍBjâ7¸ü¢µGŞwX€Ã}÷¸#z¦.ÚßGšVì]¸,B6‰}!À'‚ ~#>A¿á Zåm—_òş8ÀíØ®hœZÌÜ?°Ş¼àÃÆæ•4Øh}«:<¬®CÆX‹.“Ë^xŸ´+jÃGî„œZxìş[ßé0ğ¸d'¿´Ã(|¨Ã7ßo‰Q—vU|BSÿìyBÎ‚ş¸‰|³İCÛá‡GÍ<úO à1„Q€¾ hTiÛ4Ú,Bõ0¶$ºQ@1q[À­‘p§n_˜]åD ·Dˆ½©; Œ8ª@Mâ«¶€‘gè°QF¼öè¤uÒx´„fy’éÆÖbO›ø~¥–¦“+<ú™™‰;7µ Ñ¨Êçr÷\<	€ËšjÊa4Šjë3æL9¼ˆÁT’”HWõ]PÅÏ ”çè—QşH¶ò´DCm¯m]ß±#¤=Ä CÌ¶)DÜÔÂ¸KĞ{k:J‹ *°ÅÂ!"ªYÀo¾™#b,’€»°¤ì%ØÖ’®>jÎJZu¢5ÑG/KB'‹WøX.¿+—áz3•^ÑL#Şş‹ˆ”
…½=úùXŒ)¢Æ†,vü¯0
¸o™ù±nş^1¿Û{¿‰Ü«¤#ıqE>Œø%0ÇGÄ`6°û’›óX¥PØ­Æ¯P” ğä!ëÇAÒ+î¢x·Ï|*6DlR3®Š?µÖY·Ñ±ºíæÑéiãÀªw:õßjÌ1M0*eÎ¼q qŞØ°k•=û{„¼gûí&¡+ÅY,Ò=M×¨Mú»2îi%:6¡S(Jrß4Lê@lh,ØR%‰r$„eL‹d¤Üü›ÊĞÆHŸå6RHY„ç2£“8-_^±¦$,dËĞÈàPµ"0Á	zeHF¿÷ekÈrÅU(% ÃAÖ…¶ˆìÛN¹ñ‡”É¨î%ßFJ[¥»"½¯ÛIk¼3¤i¬Baá(ø¬ìN'*qøQª†ReÈ|pKà’U[ªÀ^n¤'-Šxr(;$90¨t4 ×ò17®ªÉ1Â]¸*xÆ6†@âë]ğ=ôà²	~×ål‚İ	'W,¿Ş êQJÆMòH2U{Cğ‚Ä·¤¼ÙÊX{µŒ2s1ùåÒÔ!`%¥Rˆ±çíã÷×sò*áÛyº“Ùğ›húßzzlV 
®üÓ…°1ÊÃ¯´0KØ%©’´éÖ÷Êæß¹jûË¦İL€bİ÷9)µ#Ò	­­T©‹!.ÍğÀ‘©iÙ@‰¦nŞM,%f],ÅD
!¡Eô7rNÅBw“5ejçCQ5hYDšÆKÈštÿU6S
dpüs4¸£¼ıe"á‘#ˆğ0ø÷)é0÷œá;²aZM/kÆFÄlÌªìßŒoQµN<Ü:8øô_NdOëÜ1C<ÑÑı}jÏ<ĞÒÀ.Äƒ_¡­¶‡vE/@úô÷~´™ (ùJ0mxd°w$FE6°ûèzL“9ÌCµšdH´9C«ğ‰Õñ¼HˆØ®cMìM-ØM¼˜ñŠGk@â‚§½!ÿƒ‰ÓÙ4b¸Ïhm[±¿^ğâ“Õ…8#†öÈ¥Í BS.ìhŒ~QNÅy3dùˆ‡ïÜ·P¿K¥‰Ğßl!¹è§83	+4ˆÏãEüÒs‡Ñ€ÓšZz\£M?øú¹×ûŸ>%^ÌŞÔvŸ;xSşïÙNu>ÿ·õôkşïëıÏï’ü_µ¼U™Ï ÑsÌºNæIåÑv©Ã|N°Ëo“0J·“q‹0’Ça‘Ê^7Õ;Ç³](C½ŞÙÿéÙ	uwxöà²„Zq€Çü~D8ğéß=r;C¿¸—ˆ9lÀĞ_C{Ojœ†…0ûôoÍf6'? lÒCD\Cz…ü°½OÇ¾‚V ·ÈÀ×d®©Ì£~ÙÃ)/¹<¢›¤8W¢Æ©\Écı¬7u£)TŸ—t™÷à—ân‡²I¸¦b€åD¡ÈG‰ÔÃc½IppŒ>ªßİ~¦ÈY$èTS4¶K•R%ç¬Ó´p‹5]İş…3·48ÇspŸ9%/QSéWØ(,ÜáØÚ¶*VEÏ@B(Vóè¥Õ®ŸşTÓËÓ0(;v&ŠQÅÌ°ıÃWjÑ‡˜µR8šÙi4õn£¦¯]øu£Ó=jÔâ-Ş
­²‘™©§T';Ÿ‘J;·ÚÒÎÚ-íĞ-`&Û¸|şÌB7µæÈ.ì+	“‹BPb€îD…Ú’NTÚÒ|)ä– Q)Ô	Œ®„3Ék×ğz=bÑ§¢.ÑÅÁƒĞj`„‡a!E…çÚ“Ş§:v?>Ÿ 0ƒÜ´LF¶ KÙÿµ›_œ|w9H§ô^EŞ8£x÷¥â½‰ŸİÍ@:ş…Ô¥ñk£F‘°İµ'ç¨*fZšóÍMR)ÆÍµç)j®Z*Î¶Í]#Äjâx"¤ÏµÅqtÎİEÇö´svò$æö”fÑ G1(«[¥ŠÙC®'Ã¬ÅqÆÕBÛßŞ™¯s Nº§õf3öûQÏ¢äwšG'g¿Z”$LÇcHÜ^ '3»¯ONë¯®…![²âu)K×êNiôQ_²»Dh–.ŸÈĞÕâF¯—@CÆîÇ2¸Dˆ„LëKH·Ğ”G95âÆâÑØšÇSÚ4¥urx´f“¸”UÂ„ƒHLDP¡½¤¦}ŠFêÁDçîŞ`a£’[°ddÆk…	;ÇĞ­1yJù…–¡{ñ C`¿}fÖ;¯§5†ÖªÕ>­éæ€`!Š¦­nÒ/ãØï´º]9pßÇQ¯wë`î_¶_oë „¯İiıZ#Î$Šb»1„Rh½¸%Q‘L® #­³Î~CR4£ùóX1¥lÌ6ªˆm_‘Do·¥¬$¼÷ışå3áÏTúa&_˜½BÁB¢ıÔº>dâcù!‚3ü7³êc\´:Çõæµ—ŸK¶¸Dğõôa©öë{â*# óãål¸rT!ÉA*»–H­Œé¶!‚³¢[úãg;KÅ÷6vg	w2Ì¹…Ø2±şAÍóO‡Â¹»uü_Æ~ĞnÇşy å˜¢©äs*7ãK«ğ]©T¼ûåXG›È¡¬x.qíÜ
ç=ªwøŒLv\1‘d%÷qå(	^z]52?¾Lb¾/îÒé€:´GÓ€Fjqû~¦-“u>lÖ_Y‡-²qõ“ƒNëèÀŠåã£jÖHfæK›«¢ÁÜj…äj+Á†4\ù&…²à¢ıÏ “3øø}ÁŒ@‚_Î9BŒaq˜±M
Ù¹ÚéW+tE©F›õÏÙˆƒˆŸmwÀ/kÆZAEg`\ù8"|kˆ>º–½ãrq¢äıäÿb…úü¹¿›óOñÿÖ\şo{g·ú5ÿ÷5ÿ÷Yó g¥ü–‰¿ı¥•ã1 ¤rœğçÓáÎovà¹ô|O™½¢pŸ*û¦ş(@²j„Sl­âÜÙÄ’#Ã3ÅÅö€[cOÜFÎ{Dêß!¨Ï@iaH¶d¬ŒÕtMËİæ-¬’¯ÿ“'¥:´Ğw6ÙGLC(•J"e€Ö}9,3Ê@xá>¿Yÿ½Ş9ëZ­æ…~ÿe³±än_‚kI,lË¸ZHVæ,l3…“/ºË`Ÿ"qÏ^ğ‰\¿j­8àè¢Fõyp¸Ì¬„béR´¹ì	7·ÀaÄ(sŞE óÅ¡}
e¯’Û¦‡­è¥’iÆû/9Ş(WTÊ"¸ÅŒ¸Úè‘XôQZéñãb¥GºÃeg«|B,¡øŠcX.ıE›ÃÇˆEÓğH¦ìåJ·ïJ„8A3’sş<=ëŠ”yR²$")H'—•íèü"Ç]'-ëÕÙ‘Tƒ¸GUHí©&NIìE4eâèâŒÓõ0]\c@Ï>r—¡µ5$Ÿşñé?QhC¯Ğİ;©8Ô(3­{y_V> ™ ã3ñ*ÈÀ?é€Q•¯}¤5z2†“õyò¦İÀ\%1˜™Èå
DrÏü@]«WI,ll€¬ÚÃßßC²îŠÂ"]Å–¢£–/€â‚6MĞĞ–Uê»ªò(dç	0§Tá£>×%E1© ÎW%¥¿b01vÌûç¸Rwê“0ÖŠrğ­LQÂ±w!H¦ô+qåââQ®²´eJ—‘¹FãÀ:k¿êÔâ6¢šf ìK8à=O´|îş|ğÄøD8n}~K¬ÁÃñÎÍç&şL6 mê‹´÷Q®8qåiQU^¼ašêÑ‹Ì¹Q¡û\”Ñ„=>xÓPXsÙ]­Î¥Š¶'Øi4ëgÍÓš¡š§]EÔ­ÃÏdĞ Î:Â.ŠÛ'Üq9”¢äØa”V^^‘²Z=”Z1|+_øZ‘ÙÊäèK(D¢8(uĞ—­F[U*(_[ÈªeÔcaäÊ\ì6}J2 qÀåÑ…œK5ïÙ}x§Áp(:}¨Ç7)q®m®rg`‡K(œÜÜšÑqÜ~å“IršDí!Êe¯$IJWtŠºtAR+®0NaYÕ¡yêÚÒÚıÁf,/•šêû»ÎÜ¤]l¹R©Ë$ÍtÓ!³ã9üÓ?˜§gNnQá³’›UœØúhÒªÊÙK.çÎØ‰İøÄ›qz—pà¡^©íwæc4ãp‹‘ÕêcağcKòèçNã9ˆ’©!›:‘FMHŒç,<-÷DŸEc‹8DµËÒ5³V+àäÄ[(¥÷2.&›qI1r‡ä©¾ı67÷@8¦[ø5ÂÑn|µ~aÓİºx›AÇåâ;ã4P»°Å©SHQ..**s(°{¸ˆMÃß¹İÈó}2{ñ;7²Ì,~]%İ
Í]9ş\]W÷*é°dõ@üÊ)sÄ_ôêS(^7¤ 	”Ì+1{™0-óF„p¨**.p?Ôâ/œ*?é+s^·K{ÉMœÎšõ7Ç;qX64[%œL?ğşàıH†$Éhz3ynF,Â…9ß¨Ô¼sÓ§y’1ËI’–îæŒ
š™HrÇ»0§.b† #İÚ’ÂJwù ÓkÈx0'6%’G÷á
 VÕeˆ¶°Gwh©”¶¼Y‘ç9aŒWsÖâZD'ëhG–?ÊH¹’=¡ÜÖ_Ç†y.¬¿»æŞüÚví>:¹G•é¥µåWŒ?çŠ±·s%Æ¹W“2¯¥çë­UYL·aµ;­_“/Ñ©›^j±ºFx²€;éiuN“í…)g¦¬°yQ.[/Œm±Ie*çÀ¾sóĞ¤•Œ	¡ö— 8§Îxf³ë'õWµ|€6¯S?nœâÁ¡¶!^nó‘Êt÷bi0ÌI0¾}‘7ÉXSˆŠÀYy{Ù°—Ì|yv„çÅÓV«ÙÍCå³‹R†^}@åc¢_FKğØ›lapê…6İÆ#r‹‘k6¬ã£“ìz+Ót=KT0‘Y$®ÖèÈ>Ñ`½0ªYZçº‰[ØRz7×Rt+&é:BŞ†æÍt¤2G7rxüËB¨,ú‹
vŸÇ@å0…O ‹`nêfÁ9,¡»¤à«‡0ÿÜ/.ÓpÉîV3îúÆ*¸1ÇbQt·ŠÏæz>›kùÜ<ÚoœtİœÚ HI"ˆ˜b¹ ­²Õ¶™öˆ4Gj6šŒ|w¸Ø_,Ôûë´ÅŸ×¨&fÿWŒÀ]lÀ&	E–•¯ºûEuw½ÒdtFÕ_ñ(›½¦\(Å«òÛê¢'ù/¥BµÂä|``ú«Ê¡n]7¥Â™}ŠŞè]#®ƒ]™ş(Rg¶²ª\" &½÷q28_xµjÕ‘ñ
8Ÿ)~ÊQ;-³J)º´fjEyÙ’qùí¦ƒ„![AÕ$‹¾¬0+PÏCÔ×Ñq-ÔÏAÍ¹‹şë\µÄ(/å@„#»ç¤ıÕñ7,˜Pš‘êPéÏ…ğÀ•ÊQ(P—%1õE¦'N"×¥T”W·r5›nTÕŒÅáQ‡¼Y“·jV·³o5O~Y‘P«¹‡ÌÆ³‰ÃÂHı	x.…‰¬êåQÒ³fõÅgäç:È k·Î‡tpyƒ ±E4Ìå$î´Z§KjOGvd‰ãPmCï;ËõøJJmTßLó•”Z2‚Â3uø…\”K$wË²X»—,\^#“·ÎbäOG—æ¿ hã*é§«’Bp{7?w!ÆZªŠı1îvwwÁìÌVP,{cye–JÖM“TÒa)ÅVîŸCê.XÅÙ²ÏaBÉÚäkçE~Ë„Á¬»Ñ* $RbÇÅë'§Âîdæ„ş»½oënÛHÖİ¯Â¯hƒš#ËÛ$E]ldzF¶h‡ërD*NÆòâ‚HHFL ”­8Şç¬óp^f?ÍyLşØ©ª¾ »Ñ )ÅöäÌˆY± ôı^U]õUÔïÂÖÛ·“¬‚`y°e¢ÅPá)šínFÈÎ#FcxØĞIØ‘Àõf‡*%I<|ÆŠ Şc½«}^ üå^z•¡EË­nŞ¿_§µ`ÀÄ&£å×¡;PÒ$Q˜Öy PˆYµQk¬Õ¶ªD:÷~¢>.©É—YİpvÖºÔ=æªÇ²Şäë¢ÂĞCMzÁÒ)ËI \©&UÊº$İâs‰¦2|¤o‹šüæøºÏÃê5)FÓfQ¥U$³
A|ú¤JfÖ¹7L”åZW L´H0SÍ‹‹pZÆÊWV¡]ÚÉ·òY{(_½ÖêlÄ´ƒ»€0ç_h	²
Yİ ²Á ¾rÅ­Şƒá:»Ñ&p2 -c¾LD¥şÚ>r’Úš-Oâšÿ¥ó:ş)š¹¨Y¼¤O+‚µœÉ+D¾Ü£Ùw}“ìüiCWylUİK™êÖ¥|>Uµ8®ƒSVVo.ZÖ{Ğê¢MüV²¡æ½M¼81Ô°“1$N	ë5¼ceû?ÒÜ9ä˜U›-wm¨2|È HÁs²Í‡|Pƒ0q°ÏÅJmëYô‡\<’¤Éë¯ìÃ’õ­ÚzmËwE2Î”Á°Æy}º­v‚«:U·'ò&\P]gÎd;6#A>ö8:ú`ˆ=ÄœKN›+Na:í”L¦jãú³iæ¹X¤<ÍSí4ÕõÅŸ,Ÿ ËÆP‰9YøÈõ—î÷\X7k-—u?¯êËƒ½oïx-ò?§ËÎİ¤¤;)i<:ë[tÉr¨²NûEû Ì-¿»Eê3`––öçè²P‚6:¹?·"r¡ªëš0‹´£Ø
.t‚I%(07å¥M>¾#!Å, ÅË­¸½¥«0e?³Z]C ^şX"€œÁ\B«®ŸÓ—¼Û´4šËeÖºr!‘C¼ğ#2µgïƒ(»¼Ìûñ0JÎÉS_4«$»èÍ§S_¨—ÁŸ•vUy„bÉµ[é0HÃ#&×ö|;Å¼æœá7(ù+mLÎº^ıf·ø÷ØV1MI)F,èÃá g©¸y•VS|F0¿jòå­®ês®]ÜÉò+3\»°¨Ïº)$äwOuN%ÕW3Œ•¥’•}3«ˆÂ÷ÌÈö%Î‚	
W:3z«üzÇ[ZÕ8rÇ.-9X}ÏßÜÕVcê™3ç¶zÇdCÊ]°8|¾ädÑ< 7±"y3® 8z¼ä‚Õ8õg­Ãu¾…*3Œ¥
–’^Ye	(V³ãÍœÔ:!•pa‘º¤S_ş¬5,ë|…ĞªŒ¹º‡«ğĞíuu‘âjÊ±¹›ƒßÏ‹rævô»©â¬:ŞlÓ4¶M…è"ÿGKn‘· Çá$ˆØK-úHoËóİöK±ª­Ó÷œ—Òú­-½ó­ÁÇe\4hÎuÕ…â9ÛjHGí•{¡rŞ,?¡°É<¯ÃñğŠŒî„ª,¦IyH‘„ÒP’è(ÉÖŠ¤èšş4IÂqÖƒi!ô[—?j+é“µ”x&·vP;–‰e¥D"o;~Ú-ÙGİï±!0ïÇšˆp;dÕãÒÎMW"sÔD¨´t³˜ÕĞ 5é“øµ6IbBAF_ºø4¤°ÚİçlA”Á<è÷–ö°D^¾¢
o†ƒ^B›k@“Àı gç$H+Ôe‹¥LU6U†o…¥¿ş·Dãdaš’öw?@Ÿ,&÷0•QÎ†‚*&ŒôHk{	m# i•Ut”R‚_Å<Ea—áPÊ89f$#•ÅdÒG,…Õ\éQR€L*vmcEmghn?Hc6Fò*À
Ëœá‚®¼œj¶^òÒbzÉJ”WØD0àåjM‡ŞX¤éL¶2f&2 õ6vé8­¿ÏĞdÁ0ú)J–[±ıB0®IŸÏaŠ€"ñB—’fó,„ƒY”$Hg3L\%	^?D0«b„8Ğ‚Ğ!Ş¿š ƒ)NÉåSV¬°7ÒõYcªóå:@eÀf†èo9‘L?ävKºéˆˆjJğóaíÿúßÅÂ^Â$¤>
2XGØj½µ÷‡0%”‡uüË9oRgñTrÏ6+À7&şŸI”äM]05«@uòÊpšV¢¾]¯.›V]®Y™MÉUªÒça:Õ	VÍ.U/vV²2ŒK‹ *¦E‹,ÄdÉ¥ ƒs÷*Å]ˆÎ¦‚ªÛ%ìÀ$…Ê\[ÑVÏ~’]ëÏJäøÄÛÄÊ#¢BZ‰:ã«¦]Ü9#êzq‚ tÇÓ!Ä³Ôßar[ÊG%=Ê{Í[2ÃTûÄÀÿŸ!ØĞ¡€‹yÆ÷ï§°Ób˜‰#ÃÁ¯ö¤¹ƒŠ tÚ{¤òÃ{€ÌèD£³xqØ%ŞQnÜpfwïiŸÂK’u£$ßËø‚ÓCN¤!W|ø~&@f‹›T5™Oƒ
U¼?”Y3nªoÌÜY™©DÇ)Æ„SQkQKlxû ] Íİ-8„sB—à·‘	=ô_ŠCÚÁ äl®.ı(9‹¤Âzæµ˜]úk‚6©T²ïó
é¨ÏK r5øN0ıxq·¬äháš×Ù±K©Ï±—³³våÊÜmÙ9æÍ$fœp.k\lf ¶¸1<J“{â7õaóKDÇ"{äK#_âL0	¨¦±××T\®ˆ3ó' Ùr\ü³®„ŒN£~nÀˆmúe¢Kn›‚	‹ Ç¸-eÍ7‘!JÀ-ÊÀVÖtaõ@.¨¹^U¥'7Fñ•®¯4†éUåyì½l?kw{»ÏºGoÿp¯t%€=:HÆœ5hÁÓÌÀ#á6"%vKIcÃîø•¸6«Y%>a'fí Áış”Q9æÍR‚ËTã¹y©¥…òå6
¢±6Ã=çùGvdçÄ)Ï>ù
g[QÒ”@>x. b‰ã\¢=V–CJ‡Ó­hªXD¿ûrì®¶r<dU¶ÎÙmwXKtšfñ‘RÎ8*6ô¤û(rz…³`–âW>óâ4ãyÅ£Áu0ÜºÚ¹õÿšGÂ—ğÿıpk«ÌÿÏÆæÃ5ÛÿO£±q‹ÿy‹ÿ9ÿs è– ”< YS}APËÿß¨Sq‡éÿ$ PÚ¿

(Q9ò&¨›“—¤‡†>Öf~,ûƒ½+Üò‚cNIÃ(W2JÕ{Âø&©¿Hî=½J®ÓqDIc@¹.Z+DôA½Œ´P‰fÑ´§QWééıÏ;¹!RæyºÒ'÷I=xÇSz?E“¦©1+„ª–ä²ù.…«ôµ‡:“JAJ3„a•5¦¾"­ïûÔ /–Ö?D]×¿Sdôp¸A_úBÜM[¾¡Z±?W">pE„ïI»@ÑX&TšjÃ·\böáäŠ­óÎxm&6¯À¹[J™Ğ’J!Üu!3ã
!0ú—fˆ¦IúëüR›ëç1L¨œ$ÓùMô~Ş¼»|oÕVÛÄ€Âı¿BÃÒt/ØòGŠËUW„şÇx‘P‘2\@Õœcu|gY„™â¼‹Ä{Tº¹Ó‰/Å¢AèY$*5»èÅ“,Ewë×föË/'u©®òàB^´Mã{[Ñ‘ÊvY&ÛËRš­ÕŸä5ä àc1«Oš;ˆe\Àö\.b8ä	Äs'@õ Å2Ôùfrít^dâ-ûbfæÁ*Ü“TÆ9èM6|Z¡›jG-DĞ7&8¯]UR]ÎWrØO¨¼<_ŸCÑnc:™¿Èd(¼ZWnbä¸¾–°ŠGÈş½çkQ²FKî~İnsK'4œK‘ë“q¤h®â¨éÑşÙZ¯5ì1É 	¢™Êà&Ïjs(ItÆZ¯	ßB¦½	)ÍÊ”œ,hûhù…Îß¥¡WÀ*†y¶˜@“ŞY R¹y‡RÆBV¡â³0•¼úG«+^•0º6¶Ğ°?Wx,	i¾“Ãİ€¥Á¯ÿg@Ş~¥ËY~{â€huùó•8w šÀöÈÉb8¸sçAB"™‰W™¨d¤ HóNËÓjH®]w—ãs"Æ1
”V5W?èaW©òOÓÏ„Ö‹ãv÷ğ“Øùól&éL¢ã«÷oÃ$TkÓ.ÈÙ§Ã:º¡œK˜Z”±š·hœèk[$ÕØü”“I	/¿µ“d;òt¤€Ùr·½ßê½ÚmwYé>H£ƒŞ<<šõ)¹øâí?û¸sÑ¯ğ&y_ä¹ÒV¤dnKÎ¾“‹ıì²ù-Ì±hg’:¯³›h´PÕıÆdùÑ,…í!âjß	VQ:G ¯Q¶nÇ+Üv0¿AQ‹İ'BÎ#<h‰™Af±å{@R3^‘ÏÃ]¡+¢||!ø«ÖËgpHáã‰by~Æ>r—+)i«Ä·şã}&½©>¨­m²—İÎ}¦;J}´ê-/šëûÊ™¨öºV£;¸„å–Òz+Ù:4m^Ükw4”j¾Šû¿‡ô@~Ü?€såçŸåÛÃ¼‚‚Ğ]w`1²°qCDB“ŒĞ„á1¶DìN•×î1à!Ùò:[ŞdËló6Ş326…yò>¥Ó&aÚÉ`ÙÀ©«eI^;Òğ|:$qÁtŒLs¼*sqC<î„=İq­·ä‹a X’…æçÎĞşTº„ „JzM”‘{Ê”Õjna„‰]š;ó5'DÿÎ0
1,3‚§6Tsë½y–D/QC±Âf‰Bê%WK%çj©}™gÖÓUí’ËŞi[mé^ëÜlå¾ã¸g–;oùÖK3ºFŸ:7ò1ï¬ÌçœQafLnëÜäG•9µØûH×âmÚ$5]ˆşm„jC5&Qzó.»öä³´*¶"Úd3Û¢šË9HûƒWX-² 1 ZÕ”ê5c‰`LˆK1t£¶âÔ&^UÅ|'ş*36=’9JÖ-İhİ3wFEh·Ç—Áö„ ¹˜¢¨öFò¶0Ò|	çû_ñş§(ı:şß6>´î¶¶nİŞÿüûŞÿŒğê§GÁçôÿ–_ÿÆu°ØuĞq˜N€ &6	7ÊP¹ƒ“¤z¿Êû"á\>†i­öun…, îu€‰-q¥sò´óC§ÛÚo6ıizæßg»İîñÇhğb3$ŸàóãïZ{‡ÇO ŒTfüµÀË‹ãÃ“£¦?N/ _ÿt¼ÂP(…_“)ŠU’)6uPßjH`Ú}Â:i†G vx»¾í¦´B£¡£¬álQ]ªü?Oú÷™ÓU§æ«s–³ÎŠ®éR‚ÃÃÒô!Ïª+'$­ãRwö¬t¦+Â¡™Àac+òßª[Ê¢BÁ·~Züp¥ı|¯õœ	RÂ×¿=;:Ù=ŞçŸ”o^ù*ôò·ïò“‘¸ÀãgQU?jãÁ;—=>š#Šf×q ª£ì™ÍKxkiìK­{ø¸gåÄ;ĞU@nÖİ•Ú¬ı±>IB—¢S›üÒI¸o_ZZ©>Ÿšƒÿ©LP–Ò˜x@º¬\;EıŞÒ$Ùp…,«ösßz^Õ=åY“)ˆS¡%|©)¡.ê^[¶cfÒu“˜DJ'•ÔrE ®Ë*J„ ¼ZW|FQ¸*lR ÔÂÓ,ü1È×¨0ß špå/›}­^¾0ò,6
|\šW´=[ÑşÓ,Ør«Rac £I‹ºòÌşµ¹b\ñ#í‚§Ö
ôP¤a’ÁIö·iøtŒßaËk­xQ€¿x
^aH SÛ‹@½Ù¾ö®šâ;Mc«¬jø¸Ë‘E—Hvë™_`óûª'O+í{3­7›æİó“'óòp^Ü8ªjãX¹aöxÏÌ†¶qG&Æf–×É×*.fZhW!IÈ+Q çÂ NÉ pLG gbÊB8ÖH•ÒI9:‹HRx§exı#­El°ÊÊáv”òá4ˆ`Š>£ñeÜ§B·'ÑeîA~)^¼¯zEî—ŸÛ$¬ŠÑĞ_¦è·yEpj ªcÈ(ySå^J+\‚QtøÙãwØ™¸¡\Ç¾İ•¾à±ôzx¸óŠ\¼×hc~¯›ãv\Óş«^¤&("ãbbæ û£ØÕ¦õ¿a! Cïª&~N;4G·÷â;°,ùÜbÁ‚s°|{š]JBvf1³1f–uİÕ¤—0ŒûÁ°¾w¿}™•[Şm{Ài,^„+¹nØR!mj†ö¤; LMZÖÜ(AZ&ú×Ô‘)ddhšxâT¢j§Ø…›Yw`Âöø<Ş&X˜üºmÛŞ`T8C™s
ìU(zôÕáñ·£İg­<ÄŠ¢N?,£‰éáf8¦§cÔlœ›”§-TµáAxÁİ¼ÅÚŠU¸ùNQŠˆªË…Oñ ç„šËÚÊBÚpŠ>äû´60†=#1Az“#tÔœ1‰|>’4«x o/ßÅ?«’ñ88ì¶Ÿ£ß¡ƒ=dn•é8Î¢ó«j
Äûªg:r]šBŸˆ¾º¼³JSîšÕ,·c ÷Bóğt<còÀ|²mæšƒ§ãò	˜‡-8ù ÌÃÛó{BµR"ıšcìJ\ãVEúg4®bğ‚ tÚGÅÈb6
ÇS†l~ÎâŠ{öá[®RäK×Îz0Á’¢¥:‡€>4õ¶øœQBIĞÒoÃä>ƒ‚œ@š¥&®ú¢s½²k<ŠFa]Üˆ§NŒì…SK}6ëA˜¾Ëâ	±ùşşzf­q–\½àƒÁ(læƒá«“ êÛA]¥Òúö›Nu>tF‚äªÊ™û*÷¹ê:Œù>g•+’¨´‡ªBí>ef<(Ú] (•Z†½8An£)]7Dw6Á°yÀÚâŸ®&as71ÑÏ`\=ÛÜËöw ´b-9ÅĞS¼è~»óâ¤}]@/îğcÛ4¼Ú6ÒÔîî}HªV~Èê ×Råz³”¾ª\İQÜÆ«eDÀÏæ—$tfÄ'“ó#ÊØŞ™!¨…ƒ+ŞÊoÃ+Øei“‹Ëwx;°‡'a(^á<Ûá½³cvÒë£u²«ííï«ßîµªäj·õ!	lòM>~ÿ³“%Âñ˜ÿ]0œ†ÍÚ$àÈtßW¹šKA¡¶Õ½¯0›rM¼„è­Ôç”ãª·ß:8éµ»­}){r®)Â7—ÿüÀ\é xâ@ÿÇ°“Ê­Ìuyp93˜q?
ø…D3	··šµ‹1¤!ÿÁ æu=½B,€*½T/¦Ñ ÄÕs6ä{C5ƒ®‚QšÓ6ÂÔ¤ö6k¸Å¨ºåË‰ïÖjp1‡Ú‡ÑğZ{`å©tx
PúÍØY¨¤¢CòÔ×Øyeépn¤¹ş*;ŸrÃu´ÚtÍB²t.\'a.æ‚ TİÖøuQÒñ„@æÛôçÃ~á”(ò;Ìå¤ÈÖŞM–‹ÕÑO–Kgä>ÉÌ8Å*ªCË‘™·„î²%1›6ïúJ2şãåˆnWU¥Ëà`4 ªÈ:g¤$è£h“ÍÌ"Úxô õ¨Xé•£æòÇŠQra^XtığqTà%¿¥Ë£Ë¶38‚q&ÜˆK’Èiß?ÊÇ? w{§Äudšót,GúKgö2øõÅ\¼û_?N’0ay©$WÃûÑ¬7ÚyhLkŞRGDO÷M«‰ÃB!]ÏpÄæ\¢q/ª³i¤ÅAø^(éñ]Eñİø•Z¥œˆÖàİp„7Fp¼Î‚É¥xMæÈâ0QÛµ¼ÿ‚üê-P»nP»Å83NjÅÉÂ!³,‡_âTs³ÀñÛ©Áaç‡NS¿¡â4œY¤eWHop¾p:Šn&ÚLñl	ßâ:aÖ\t&.9)"5RVÓ˜ç#q=×\“)HïÕ¢à°<›^H>µ¹¥µ¦ƒ]-Ïíß8Rˆ®´Ê‘œp&­¬\[Ô!“ú¹9wú´d“jÆ®hŠ+Ğ–g€2ÃÃƒçíÂşÑúÀ¯E±üå7Âìtù^91bÇ®ãÇ,>Ÿ«ıªuè»i™Rªšù®ñ/Y33ĞñNL2¨,…#Ä·mBÅ´İŒ,ŠhJifºAU‘¹DA³<á–˜èv•tÈLà.Œ^nXPöÖÕkéôLŞërebÓEÌ™æòİ,ˆ†¬ÚpÇ_eüW‘±F1^¢ Åòëÿf0ŸĞhëm ë:hzÊÁôƒ’’¨Ë`fbNÙ9ıú¿ÙeğSDH›KH÷°jÄV–ƒÓ•’U‚AÄMf¦*“ jj¤Õ*G,
ê\Ê­†HËzYó–Š4n©{mºùsVÆ™AÁöìôèQ€ÕêÅ0>†¤Òƒ^+y}s‡Ø¬B1¾üÍa§»M¥p	W6÷zÙğÛB.ÂÁ€±ğë…ÎÁDõ_Ú&WÊ¼Wvg%u5£ZÑšÑ+sâM7W	|©rMú
ÂéaŞ’jÆJıô5}ú¦>X)Dš—+âL©Äôeè,´¬Mİié‰†˜!|óAytvD³]²•êÁ‡Ñ;äÌHË¥x­ÃÔ^3½FØÏ,›k§Ü°àBbO@“*H-–˜9ÜºQ‰É¼ÃÈFœÛFFb¬Çg?Â^§M4àè÷İï	ém%øÂGPZsøıË´×²Á9DççùÛt"‘Ù\Æ}Ÿl½'¨n2XçRR=¡jÁ8åŠ(üß“P¼£L§ühf½Ö’ôGş	MOÅÓ»şù…ö˜ÇQÙÁÒL3íQEÄ¼èÉ;CÒ5ã.&CXpµIÆ_pÄKœõ.ûi@Ï¡lö[l£ü;Á¼H0ÎxLã±ˆõOß…CíQ:z<ØŒ¨gà¥müşƒ=UË¿B^ë0!ÅÓDÄĞ“œfêAd?¢©?:MÈŞo¬ãÓdNèït0‰'š%ü‰ğ	:XwŞü	JXø™íUĞÇ&&#š8S’w‡ËüIDÍ&ZA—"i@S»ç“ö(’äÿ><‹CêD2î6lú9÷ï0®%$Ô@6øÚRáZy2ço çâ¸á‡Fç1÷< í=Ö:”+y£¶Qk©—Å”öÂK—ë%qjJE.-¡{x•ßqÛiuÕ J:/åJ}BĞ©äNNM5</J¯î+§uFX/Á„ë7*ï‚˜Âêf­qJ»”ø•›£4¾PíEşK×)`áQ˜©®15+“‚ha÷Œhz‚HÁ›¢œçaiMä&JßòC7çXéöÁ¦Cƒ7^c	.˜È’.’j8ğu^eÁ²†­,»0-ìş›$Ú@1–"IÙÍô`ÓwÀ8ã™äYzj`ó2ÂXw­ãÌEq>+îîx¶ÿé¼oªËCƒĞÂ=|n«WüT×İdDÀ¹ã-J~1ÒtNCŒÙn87¾£qftì|MÇµ$S³Çh«(«0åøN¥7áS\_O%Z²4’ßÈUŞ¸¢°•V½úÅ;wrí½
+sò¡m>m
1`æc YıY\LLg¤+#M™ÜUÂ«`Îçİ›éêÚymg–.ÎìTKßM4ÁŠ`í>Å«¾z>ä5yûgM‘Å™%-~KW¼ástÊ2Bä7¿ ü7€æ`>!tçÙŠ’|TËcÚ;-Î±òa*#3œ™¦»o-wAªx¼8"¹v¿Êß„«{%Ms‚9ğ‚ò* ^]‰–o†ïk9°.¹˜O´.áT¥r—è/;å›w3õÜ›±o„ñ»•h÷x_İ1pï”vìœ"™®ôÈ™‘¡qîŞ$w$ÜÉHµ›Õ}î‘zãzÏ¥j¾hùÉ½àU“oV\ƒº ĞA Ş(-¥²`=õµËtÂ8w-dtç/˜Á(š¤6Ã¡™åğÏ¨Š»"ŸfYáÊiÒiu»íƒò˜a¶ÚEwR7±]]ÀUÚ¯RŞ,sT×yS0Dõ¸V:9ÀêAŞá8kºÏ B¬»Dv.Ûìg†œ»ŸÖOëÄzıeôúf'İqç¸Ãâz×3–µme¦²EKYÓPÖ°“•f²³­d?‘¬m#ïS!ÔúåSİ_™gÑz³”Ü²õ†i……«÷…¬z•±¬5€š»>R.ÙÆo)¨Ëì±šÕhg}æ7úÿ¿	àvÍùãj9¼€óÍì›æÍŸİºyqãfÓ_üé«Ó½BƒGÌj“
–&±äœYœ8](…Iæ]£N¢.’Â"ø®ÛÙËßÚ‚9¹›u/ƒV¢L‡Üò¦É1iîFiŸtMÕªR—Rsç£¢[Ë²è²\0§0beìÙ\,IÛ<ş³ƒÆÜ‰M¾Å¤33)ºú3A¡ye§\®VÁ¢R,	ˆ	„¡òWÙ…´–;»2P]ø~?Öı¦İa¦ÎàïîI÷p·Û~¶ûòåŒk”·ˆÒ¨øº+¢ÖÁwÍ‚ApŠmZ¥Ë4¡Z×e+Î"ñfd	¬9|?Ş=ş!ÏXgÛËyè
\OQ%t +Z¹»Ç/:d¾bà(4}MÙ¬Ìh³^NMÊp‘$¹6%™ı-ûoå<B‡¥şbÜÙÊ¶å×µióèQ‹0?ªˆ´‰:à©‰ô¡¿*ß—\}ƒ1TÒØ•o;;² Ê‰ïEór=íÎ³L4dÒÃ²Ì‚imùó›O+NUÅ’õ'6c•évå	qƒpAsó³Nû„ãKˆ_yü'”fJÓW¿Q[ó@×Šã‹¦Ò}^}äÿéÉ
Æä—·r¯‡„•b œÄb>ÎMNı:JgëúUê¯R@«?BÄ'>ÏJ\RŸƒQ¨²*Û¢TÚÇuG1äq]4ƒ§B·èŞQm5RÍIÌsD®ï-`”°˜M‚9C`¤]µ#ÛšÂXæ–äcr2ŒĞŸ!-ß-@¦jG3îëä(yÿa°·¬ÍNÄEÈÂòéò]‰ïÂdÕ_ZeÜÛ39Ç˜‘¡¾äË’!İziºÙ¾©Uå”œÜ×Ê`óº5p¹¿ÅÌÈ‘Ç*çÙÈ_ k$%ØúJé4?Åz’ºÀ)Ÿİ+å®¥êGZ/_5µÉ”<,—#oRdT¡rOJ³Ê{\q0³mP¶Gßš_‹ÜEãoêrš¤_ªç×=¿ñEz©Ô[ÿo9ş§ôÙôÙË˜ÿÙxØxğÀÂÿÜØÚØ¼Åÿ¼õÿ6ÇÿÛMİ¿)ïd7òı–¡(Ïú¼D¥gvùu`=©gñ0NĞ ŞLÁw­ã½Vsyå4|İØÙX­È€İıİãÖËC´ayXçä)ßìîağ¦ú,°ÿEnyt‰¡¬Šq„õŒ<)Ú¦q÷¯'/U›ùwÂ,ª	Ÿ½œV­g#®$Qaú$Ñ úSíj¤ˆóü<È`rµĞÙË6ºæ>ƒ3ÑÌÎ£$ÍîXAà3JS ¹|ë²ª¬z¦NŞ‘\Bù\ò_¹Æ¿ê)	qÑ’˜pÜYåx·ıW¶wc÷´İ:è¶ø„óL>GRO‡Àñm{Æ/4;å ~¿÷¢··Ûİííµ;MßÖ¨işa–Ò‡ï9Š|ZæV ğp€ìƒæ²â4;Í^…Ctl®Ôªd·™ğÈœ>æs¿“Šö‚qÙá¶°(	#?ÑYvÂ^ëi{÷ ÷üø†í`¯é“U¿/ƒO_â½Z*kÌ¼j£ñVmk·ÓÒ¾’Èz¾ïM	¡7ÌÊRK¢DA‹ä¯®õïE¯pk^Aa	&÷‡ÁT‘KÜku¾í­z»GİŞáQWËP7öjú°HÃdfµş4¨MÏGYí,É£æf]ÍÆú#OU5•M•İ¶a¦zXú¦Ê{æ/»ßíÚİ’ã6©üˆa0¬]ÄñÅ0„E=’WAu Äã%–W¸H#"âÍ‡|@ÎÕNy_/×ùõ¼Õp’+E¯ˆJå'ëjZCûkû¨éÏ¬}GÏzıÿ ]b>Û×‘¡w¿òĞõ9Áb|D¤—íg­ƒyÛÔ³ç½s“úàÛ¼+/¢ìíôŒúñÇğ¼i”'£Eß.lùEqÛ­éššnì£v<e·Út£aI-Ñ
ÁO'¼hü®ªôŸàz¡óôn˜	r-ÏÄ‚a•­ùà9Ì–›~ÁwŸÕSWÒÕK%ªyNFİ¢CïBe^°‰ÔB]óÅg‰À`¤ ioÃj0Îª0¹×j[<J«D¯¨ÆDa*ìÜ5	Á¬"ÔOgHıS,¡
A5àj~ÊóE©ÓŸ×Rut&ï}³3]`¤§"¢ªqMy¯ë=I…Ó2¶|½6}w4<8¦îŠ&Ê\S	îÖ{k½M;XÛ%jkµbpaÑ¦—ãÚy†ÜèZŸ¤†i=.Ò:9=Ôrùä{¶.¡£Åí°q®]#º`İİª†‘CŞ5HjÈŞiôaï,İµî{«„ªÓ0ƒFíQŠ„íÂm¯õ|÷äe/ªÉña§ÓCí8ñİØ$W¸L~!2ò©Š8[_´ºM¼-9ì¨7¡ÎJuuÀåÿûß<÷‘ÀK>˜ÛÉèòaà3I··¿'”û`Ê´ªa|gå®¿åX¨~%õqxË¤^®r¯ÍUØa›¬Z	wÅ‡¶8Õ¡³ó‰øÄ¿ô0«ÚpòîZpYÌ ›,Ì3ÿsUY¼æ±ø‡UøKÖõ„Ÿ.8¼ÔÛïªçı¡šÚsïów&ì•ãÖ‹Ö÷ì»İã6nÏ{uÜ3ÎQ¿l |Â¿|—ë½lw»­=X0Ç»@a-¤}¯~Z¯³O«<b§›ÇÃÔˆ—ÖM‡?:ûĞhTÑ/<^dï`‡Ro@=N¢gÓsíc?ˆ’x]¾Á¹ˆyè‡,Íäs½ÓB.Şö«²$<.†Ól#¢ï¾‡–¾|V4}B‘D?'ÈùæCô`8Î"à»áŒcÓ1ÿ7	&)lNıƒ3v1 Ú™ü€ ¹‰"dîÄ°wßğt Ğ~…	ß†ê3!úğ•	®k<?¤y|8©Ã¬ÿ¶ªÒ1Dªã~7£36ÇUl­/2«¦Iÿse[ôë×oOZt8æv7¦&‡[1;ĞáÎ¢(—¡Íu" adÉ<OùÖ¢M¯ÆYğa›³Úµº.”9¦è4³¿åşë€,:Ó7¹{[üìµ>½o,^>O|’Bv*t[²úy³Ü¼ˆ™¿¶f…“fê„…} +ù‡,¤Ø$^kİ·bi…"§c¦¡½J1Ç/Ÿ_œ†Ê_V^7f?NÓŒM'H@
IJ˜w— ^PnJ°^™­°à2ˆ†¤Ÿ“–êêüÚ£¼Ùµî¾¡áI¨›»-˜?wÄWVÊ1FQ½¹{Ô^I‘­„çÁt˜•!'ò«9«Ğˆ©a©Ç¶ïÎ¯=®¢9³°ó6~Ï0Ş)"Z?ÌŞZÜ·Ğ6Ø.ˆ½Ìº°ÂÂÓÖÓœ÷1éh5_g£Åæ~Vóàƒ“ı§­c{­¦Áh2aejbL\wÑÀ‰­ÕjYŠ’DÃÆèáO¶å Î°Í3-6ı—°§WrØiz>¦ßÀC¦ôımÃŞ¦üj§„0L£¥2U8€¯w‡Kî0ÎBácpGöö/gísŒÉ‚!êÃ]éÉi¢ØÕ—{2Ù2¢¼Qpõ»I0i“×«j¾Ó·€(89BZ¢EÈ5u:loš¿Ñ2c–:³SÍ”±2gß´ šÇÏ"•vê‚.ÚÄ›hlëœèiå+2I.xW×¨ú—ª’æôC®RR”Uça†¦D€öãgI€Hİ@gG€ÂŞ@Nº™[”m)Bº•ö•3TS•iºuptm"W¤SÓôµºç+,§½äğ­?²9Ëeµ"’¿şö²UšàöÛzìæÊúCŒ¦.ÒZ¢¤(aåQ!èe·Ól4¾Âu¥ë÷·¿ßşÇ î§õ/Zjy<ÜÚ*Ñÿ Ÿ¥ÿÑhlnüÛºÕÿøZãÔUm4ø‚ã_®ÿ³¶Yôÿ»¾¾µq«ÿó5~÷îıñY:ÙÑÿÕéí»Uş‘¡BÛ^°Æ#VLSü×¸v‡Ü€L¾IÈ¬òïİó¼{÷€d‚§Ç“'`j¦^ÄÏd˜|6Îä]UuÊş<ÁB:íƒÃ£N»3¿ “+)ÄÂ_?N³$_<á‚’Çuñú&B:yĞÌÒnœå)ªUG³h‡qfÚÕ]”Q’ƒÆÃ¹s@N¶Ø,k¸öZgÇmêsÄÄÏ˜‚ÈZ±~<¡ø ıd2$óï£wÀSuïã$	¦YŒ¾§\ß}fyq&!„Œ`ô\.BÅV™°-PÛ>	•Ù+îæO¶OŠf\ùÈŸÀå"B¤`õ’˜$‹—`¾ç™’Àè²¨ÙY3eiKi†Æ¼(
@ÈDã”fà˜šRşã–¥•æäšÃ<Î_
B³çjr©M)7ÓgÃHœ±Õ’™Oêlá‘µ÷×bÖ½ùùç×"“7FÓÒkÓºÄ,yñhÑPÁVU¤ÀÇú,>37R‡è§ºˆèGe*:‘åûÇÓ“ÍÆüş;Iù—M	ó.@µ,ÍG._1RìÁ1Ïíî¿K±q˜’7ª~<g,@_®S4ØY-™rŞGe=;¯…øŒ–diKf§.m¿È¶d¶Bd1IÛ\ÏVƒ(“Î¹òş@;×€ú‘ÖÁ¨1r »pA#¯¤Ãx)…KX¦¸‚x‰¸­t¿9<†BEœª{Ì»åÿıÿåxÀğnù¿¯<şúJÿšã¿±¶Ñ°Æsıá-ÿ÷uÆÿÔGBy3†~Œ®¦ÖıÆä¨1_c}FÙëÂU‰â¶$³ç{µÎ77Ï<ƒNg0f˜D²aY›3 Å,Öêôü)'eNÏßĞ« gğS0¯À<#9ã	ãXI˜8şJ“*]Õê´zÊOÈâNßsÕø¬Q?Æwºõ£¦@ßi<‘÷9ù“ıÁ<~óƒıëYıÅ––næ=E½ïY]ÉĞŒ·„%ÁÁqö3PKs¸-­è\FEY<†Í2Œ[ÆMhiøxÊ…T3‡Y—íÏ°Jf0æòsÿ²J’¤ÆúÈ¦i¡/¾#}M_%EM“D¨c±Ş˜|çÓš/9EŠC%Ä7¬Ãg¦¿©öPo°í\ë’˜6êâŒiÖVRËØ0¤½ë“ÅœüåDñš˜¯6¢‡=›¾; ½¸×øóÛ8ÑëW½[ÊøßŠşaÒ !òs)ù™ıŒ×säÿëkmúok}ıÖş÷ëØÿ²ÃŒ¶zvşm&!î‚)«x$Yz|–<A½¥Ô²¥SÍ­Qò½ç<ã÷Ñøv¤¿M#‘Ûöã:d™ÅC†~k›~Û‡×¥ÇÃèÉ!ªÅp†y»KÇºtqÉV!Ršqï­ö6	ÏfA|—“›±úõ|o•~ËÃ¤~6ŒÏ€÷<“úqkwo¿ÓŞ"Åü“’r<®Oà@Ÿó¨AW,NŞjP{\‡–ˆ¡‰2JgÑ0Ê„G4Za®Fn«„ªgêÊ‰û:fu¶Ç5@ŸˆŸÀÏˆ=-™	ïÏI8şËŞ·Ø®®ˆw(jƒ,­Îà(Lâ“îTUá_&4£W,sÿÎ¬CˆÍµue¿üƒıòw#Û“ç‰¨/’¨Iˆ$*ªMˆ ƒà‡ä–A$#¹87¹›dıD§‘ú=‚”E÷£ˆæREÛ˜º­¤†H/!8B'0$bàrñ–0W"øTİ(‚A0ÑäæZİ$£#ÊÕ ×ã!®
ñ§ÃS¢bNñª¯š†Z5Ï•M>¡B²S
5a{=ñNQ3õ>SµL÷¬46¯¡¯±[úà_ëüOB`¢Ò°7Æ‰÷¹5æœÿk[¶ügå·çÿ×8ÿ#ı˜ÏFGÀ$R°H&#!8‹§‡ïÙydSØ<i‹=›^0Ò«yŞ%™ì³*;ìgñY˜Ü'5•39i!¶ÊƒÖ«v±±ôx:”;T{Ó>•¦Îo¶Í‡£':§Õ¾j:©¥o×!Dßév¹«‘¤%á0ŒàÃ==5vÆ)±×œãÖX9Ÿ úCÀj›œªm’¿?~–uÂ	g(E+ë…çíï[{%İ°K¶¦lwLziKvq»Ó$È¼Ao# &äR[Ó»B
sÈTÑèSC€"”Ùú#W$ò>ÍU–WkÔcıOqLŞ1Â¤}3#‚ ~÷å­m†ıê\3ÅÆ‚5%5’/>c,×<ú\á¸ĞX¦£4éÆ‚ÎÄâû
ao¤q §úpTÀQ½¿‹#ÚĞFôÆ
ÙÜ¥Z¬êõã#¢‘ U•	eæ—¼sf$ hU‰¾¾{¼ù°.Æûzé 4G:}â­6Éü½l³ı0EkÔ^êØï–şö¿˜$íÌ­I•5‰1£¯?%°·©Ÿõv3Å>&_O¨G2ûØ šG¢=w\saFh?¸b5m&,<NHüFUAnŸxØd°Õ	^£ñ ¶&ÆíG°ß4Ù»;ÍWœ‰ğaâ§˜íú+úÀ”ç*µ¸é
Y„¢”x„õµ¸ÓŞ’q¿şûb×~‹ŞÿmnlÚôßúƒµÆ-ı÷Uè¿ü·şMÌöÀ¿Ñ%š€b'*ÒWğ‰B¬„ˆæ_.‡›:y‘Ûæ0·¿|Ï7Œu÷_KkŞf¡Ê¼Îvôg‡Çº1*}K˜Óª,Ä%;îu{­ïÛİü3B ÷îv¾iú8¯T+·%ö*/B¨½Âò´ú†9	½ÜÏŞÑ«½ú²İÍ±»ú˜Ê'´agŒåµ²€ÆûŒ}òŞ'†Èpå]¼l$vTÜK	Ê”YihFAæämHCãá42qÎƒOİp4AÒáÿ™æ×­*|[ ¨²(;ºÿÙÛ°ÿ—T€O{b–Fœ…ñ(Â	ğLí´ß	¶›ÀñĞaÇEO'¾–’‰gÛV„—õñt8ôNí¨½q§rCMe?Üï°„GYÄÖy/ö óˆşÏ£ñ ¹¼î	™Ë¸6|YYFñİ5rWHÓÈ¿Ñš[şˆêu•mı«HÃY<ÀÆ”Å0Â	lc<Ã®'¯5—ì~§ ~­‰»¬ï"ÌÂrz¶¿§¹{àñLÏÅe¸¬YU8"ÅÒğÚXsP)®»â"|Õƒ(»ùS`5bZ~¾cQ.ßS‹J_óË*-õ¡°Böm”ñáı]”Q™“wá‡°ÏÂñ%Ûkw^îşĞ\ì{~­ÙîÂ·ü™İ¼~Òkœ±³ÙİK“i¬E
µÊ¸ÁE¢«UîÍBöğ+yTHÔH7[íÇSKÅ,%ˆHœ’%‹Ô[Êg‚œù2±*«õ&o6^WÃJEe	KBÖÔÃ7ªV;Åu~Ç™u|zKùJÖÚÓjçËÅlÆ0ûÛ§×<N¾Ïx¤WAÙ[Ò·@h UšCC±¬,»%ógĞÿ5†ô¾ @ôÿÃRú¿—½–üwíÁÃ[úÿ_’ş_ÔoívSÆS6
®¿!ª}šqe,xI®î³3xGÕ~Õ:ŠÑ¹„'¤tgèV;ÍjXh‹¾''‹‰‚T4%ËÉtìUô$â„gÕ*O=‡Ñ]c0ôÄˆúrã(JÃá¹Ò1’M†
Ï,…Ó1<ßfòN[&«Eqıë0^Î?èTê{=ÃxË±Ë?L‚±²ø*Á)¡ÓŸ¥BÏÔØi•a2‡¾&ÄgU=f„6öÛ]ùkîÿ/¸G.FÂôpPË>d_`ÿŸqÿ·¶¾nÛÿn<ÜÜºİÿ¿ÆïTh-êöl{KRËàúqè†6¶·Ô™dtŸ[yÍ4¦e"K	¸(CtiİûvaŞşn·¿Ûßíïöwû»ıİşn·¿Ûßíïöwû»ı}¦ßÿ1ùt h 