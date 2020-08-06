#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2079389286"
MD5="bdcf53aa01ac933376d8b5d9b5ce5ae9"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20820"
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
	echo Uncompressed size: 160 KB
	echo Compression: xz
	echo Date of packaging: Thu Aug  6 19:14:35 -03 2020
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
	echo OLDUSIZE=160
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
	MS_Printf "About to extract 160 KB in $tmpdir ... Proceed ? [Y/n] "
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
    if test "$leftspace" -lt 160; then
        echo
        echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (160 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáÿQ] ¼}•ÀJFœÄÿ.»á_k £ÖÍ¶ã(¦4NÊ™¸ÿÉö=Š§«åØMìFl,ÇêPâ+‚bÀU+›Òsù¦ûüé|‡ß âºÚÆ…mŞğéİM°]¯Y|é×í¢sn¤øS}½:+vX1O¼KM.£•„ğLë“i8¹BıÄ`;ÇÊ‘.qNá	ÜZïÈdÎÈÇıK¶šˆóùõèêEãÊ;È8A×H1ÉÖ¿ƒú8é‡Àw;§tí ÁMîô9ÜÀQt´öÿP­yİfhzÂŒÓõåß„Ï\Ş•Ø WÍ<+KÆ2ôƒv	…–pU™(Ù”yí<’^l»t]ù}]H=^¿aH!j+òÚ£ÎxœG1µw;_QÁñ¢Ç=Ø_Àg}[Ûs&ëfıo@ny¤}6ÈJå•œı ×ÂteWÂùc{)¿–R‘–ôhLf´YY; ¶GrìEVøûÅT}ß82ÔŠT¶Ú¸$=ßVOãÏK9¨±Ö˜àù”«¸r•+o9Ö6²¹1
¾Ê‡2qçX¬ù´ûB.¿à¹§k§8±ŞLÙ"Ka©h\{#+g”¡in‰0ŒPTø³SSÅ@RÑ/CZ~íÑX`äğ¤³½Sz¬XpXRc-¬ ‚‹RVh×é+ßl$.y²ÆiªdSÙhµí f±ƒÑ&²“/WXM6Ac›ZĞ'üÒ1É'|şmâgòıRˆ½öÛ`5înï9Ô¦® .§•å—«ãÿ¿Ræ(³@ëŸÿ¸	3ªüeÄçö»~çpoú éhTğoÖÄª¥.æ8°‹C¡;  ‘ğ«ş×½mŞ§ÌVu'P£s)4QÅƒtù9S\İòS”lÌ‹É’q|t) ¢w4Ö€‚ŒkÇèPiÌ» è#‹b"†–&Äg%,6!ÂÍ66ÌÊto˜8™Á:–oÂ¨çUÈïï~mìè°=U¹o†Æxï–Õ¬È”"<Å^Å!È«ûŞö6F¶­»áNólÄé»ğ«ZÖ\e3z³©S˜á>İù­¾TŒœ#²kªÂ] -’)’+ÀÀ(?%­Ù'#%u»hÍ; [½wB“­äf/­£õ`S-ï£“{ÓRó¢Œ²óeT=‡oI¨t÷d2šA<A†·¯7W‰ÜIa
8˜í°y×¡(Sg˜©*È²F2¹Êğİ½]òòºgósñƒ×Qt{ı*p"ÙFl'Höa&Ë™1Ëà.»?,—?îZB¦ì
ËL™Hš<íTM"8X¯³²Òrhˆèİ.>ÙH\„vòÆ7İ3©r¯(ZÍü§ÕãcÙi‹=YwÎîÀÏşã>œa¾ÊÊ±fÕşĞhy1Ót„‚)=m4êfåkÏşİ4±3…ãe¤_ç±¼±ˆ.œ­o;åÇ³f“š	F)|f˜e§>¯á
çæ¤¿=1Y~g”(Ö±±İ·”ÙòÉS "	™„çøCáu½%sP¢Ò§Ş¢BMœ&…SOñ‹Ğ/‡øïĞ+ñä×Ş?İ7ÏDì·ùK®Nš6­ÉxVz“LÒe¢öïâ¡_ìN»‰ºÉ˜îÊ´²­¡Z½÷|*,E,%kèö€Ş¹ò.nÉ›Ó<,Û+D•Â«Cvú<#N™dê	âåÕÖ&µ™A
&Rk?Å²ßÆ¤n+ PŸ…>NÊ¥o´ö@²Âp~Ò™‹”¥+“Îf‘nš/ŠÏZ ŠİıVM¶Í7¶cûƒ€ ë®¯Êàï@/(¬ŸôÜbIx·]A{U£¼5(±œoåw+Q"Ùrs4©Ò¼Ñ©­†Ivû‰a'–¹ìCœ
(¡ªSDºj(L¥Àyà^8p/T×xduşëÁÂ÷á/sº@}af&k±ºpV„Q„†Ho©gºÓµh+ù‚H÷¼ÎQOmŠmì4„ÈJÛøßhÈöâì/å´V»1÷ôâGÛ’Æ¤%ë|[áÍä’‰”©»$']	íÇÿã'è5ùº™y|î“ø•Õõ23¨qqæ˜Ÿ$óîÙè®sv£!lu<ıêú*siK!gıè˜Ğöà ¿PéşIÅ#wA–7›¨F·ZÔèpP…¤ÌCôÚ@õb(#7´$_sğÍY¤³™v/¸@a÷\¶O¼‰»tGÕF!i{Áz*«v™:•/Õ’Ü†¦İUÖš+a	²P©êøãø8Œ|FŒÔêÕ¡ñÄ$¨E,ß›’¬Å™<Ã"¶ŞÍoòèÊpmûNÔi[Ï;eÑg¬ûìv›’YÛ]rÓß4ÂW¿!åøİ bÙÉß¼BòbÉŸÏ	Êêñ–¹–ÃÂï­ö„YV¥#Dªÿ'Ş˜–¡n–@FÊ .'š‚©¶SÍPY®ÎÏTb(dÅªÅ_ou0áÇ õÑ2²˜ÒéŠØùŞ¥šŒòsÉ0~á~ˆ  gÂVˆK¯ˆÛÙ¡6?5,ÛKÔM½Ù&VÃÃ™n¯kSsî1ÏK‡)Ù‰à©"™¨°I·<uœ	qÃ€”_6Ï…Š‘ (wÓ~F7Ëwp9®“ ŸÂøîGĞ¾ï=dI¹=„"Ò«ø6ÈÕrƒTf¡n«XÎÖZKSıÇ7¤¨î`”R{,™ƒlK¯He¹ğ Å–,Iœ™Uuİğ
é*š“aÿ)w€ènè_ô+Â]õYÖÃ¶iKS÷kğâ=óÙhcx7_‰rè‚Î÷¡~£#H"Q[múßH÷Ù½ø5‘
öì¾·JÁ¾ÿº3%çTÆ…ğê¨ÈG	8óõšé~ğ,ı#RÂ¹!~Ò‰WĞî0khè#~ÆeDæxâ.wS×éŒg!M±Ÿ…Ø‘à—Ä÷93Ú•¶#«uøAwzïåé€°îÍ#®nÃáTpÔ>ÌsúIœ¶wôXÙº`¿Gí§äşç5èrLçÃ0ŸŸÁƒ*wœ8h‚ ‡…§)¢ôy/xIWü0H)´î´KÅaaÕ'ÒÖ@æé'Ì«:	>àqÔô‘Ñ¥Ş™£şä$×w.G:Æ‚¢
GmoZ—á—MH4Æ²DørNÉ?œÂ J¦XÏŒÿíòÇR¶¢Ì,w‰ {œëƒô«q§ğ›òàs—®G´+£Ôeš™ùN'Tuö·Hóòš8%Ê6Ò ˜Ç‚óƒTeå¶.‰A•ğÔı"Ú¢œº9<U¨ÊP§àlş½¶†0m»q••Ù“4YF
ä#N1˜¤–:!›1†ôo€MİÜ÷‚ÇãÈ|rŞZº:N,}•]%¦å1H4¡¢ı»]Y;˜4HÑÂâMÚÁ“N	›õfî2à¨ò—8¥<Ä%v˜·~¢™p‹+*‰ªXZ§¯œìŸ’$bƒÒ¨@F=ÉêÓ/ò&`©ı´ö6‡»G[¢n—ssÏ–"[ÌóÂ,ï”™;°şY=]™õ‘V¥A>÷3·?A®KnˆÍŞ…V´Koı(yÅåzã‚ètÎ¨£îTÉT‹ŸR!ˆ5/×8ö÷$¦Y¤ƒPıèú%WŒpÖ`ÅjÉÚA%ÿñoÿåÌéÂêYÃ8¿ñi`#Ÿ^}ÏŠ{'qî˜L-„6Áá8sO)5Vb»<zJ”¼!—:şô¹ÕWÊå]÷ik7o^
+ğ©çÿ“Æ»§ê{uæg®‘ïU“Ôæ"ğF?•3¯”¬=${?ÄŠØ€eª…Ì‘ˆñŒ@€%›&6Z³ØV‘SñşUê&S]ÉÉo{şwö6ïæa5¥~êDâqzìØğ×r5L¢îğSš|7%ËBÕ„Ï¿&@àÕŸB˜³ŒÃ]G¨VV«R»+F%«Ê²`	¸O	L,+şˆª˜8Îè_nMzÎˆ¶QııÜşúdªÌ½ràáúHÉÀ‚‘ğj¡1ùbFJjÁrMøœ5½éA†g›‰ïê[´CÑ¤üNi“#†cğdÀ?ø7^å•cç°1d$¦œ½Í<4E{Ñ^Gße—s˜„ıCiÑmäsË®f`^Ğvü¯V¦³LfsÅ–Toñ«£(¿
Ìõœc0-)*aŞváùÊ$ı>]\·ûºî2E¶W]èzfCgé$¾úL)¤‚/x ¼-¢ïGŠÁK€¡êÛ?î|Dä#HÙËMÖhw$ûÄ~gØ$1,êLe¨HÕwŒúy—„ÔùõC.³ßÒ°XµlòÖ²7çNâÚ5	=¤*7ŸØÕıw²qYît³40¦ø#n+rpLØ®3HPm¿ğY£Hx}XG*=¨IŞXÑcÏÚ ŞCJÔïlq½¬$·óLk¢¯í',Ùf£€˜SÉeÙXUÄ?…«zç‚§-'$¤iÉ0ÊÔxêôDs&êë¯íÒ µ'QÚ³1Z#6Sê¡“4Jìst™äa;Œ.'5˜˜ÖĞ İ:©˜ğHW;	çĞ¥»%Yˆ°¸âşû†RGt§Šp Ö[±”ÔY»†ì¯]Z «9 }q17:Æ(zdtLÜ@®¬i;íe=Ó“Y¹1¡ùÃ_GruÍì^êÚÖ6ü{ÆŞñ²vÙï×Ë[À›ÈgÇ5Iq[`#  p¼?‚ta9Ş,Sç•ÊbÈºØ#¦T¿QÅ$ó±HŠšB/ÜÅˆÖYA¨Š¹
œ£g#Ì]ã¦ ¾0é>-¬×Ã÷äHÎ!I$;-¶»;âÌÏä$_®/JÑ0'4Ş8²
“o xhf(òx®¸ûT˜l4N nºØ¾½Å„7øŞ U<A)±œS™ê†L§Âã İ—ÿäÁ	×°_Z¾r…NA"ü…C[XE¹æù‹¿{MA9·i›útüÉ[Òè©gÈq‚öC!6Ä8ÒmSköÙp¾Dõ\Ózxa€mı‚ªŠ—|A
R¹Ãv,µ4Š3…2hŸå„UüaÚüjo2Ü¦°Úë¸Hà5pb>ˆ›Å`İd ×¨¹øig[„3ªÇ0/òQ.KÓ½ç¼âò•Ã7®"«‰,ß¢Š9Œû¯Ö¹- Éx}TrÇ[¸±Ÿ¶M{	â1ıô5[e­¤¹á¾¼»È"‹¼‹7«Y‹Óÿ&É9C‹3¢õ‚3•[ƒà
WµGäE>îÒQbuØŸ‘w$ˆÄ¨Í0®–±p“Šn½K+ìLG([u`SE¯ÇM%nY?Öb‹‡xÌ±”òËºuSœ¸Ù†›Ù¥Ôàˆtşç§1î'SúıÓ×¤Ô|ÕÅÔLƒ…e‘ÌçJcĞ¼«óÕ	ÈÂ…”ö4/•)Âî¡÷M=
y:EÌ:Oç ækš¯´Yı§`!»ò}L©ÃÄó•ılß,`SÄSÇtş¿[_ßÊ?4‡Œ›ORóöøÆObV—š³€%àëtˆıu°ïÌX•¸_÷Q~İI¶‘±yĞ`sıT·v&#6‚³	·ğ©ÛTÆõpòk;û„œ¡6 •	¼'  —ãéu–šZğáÀ‹Ò¦şñH ±™ô¤¢Wµ¶nĞbªÏ…¦Pvn3M¸c`‚óÉ´R!ÔK.j¼\è(Õ·7’õu$<OOil±z±’„e]¨ÍËC<û…ÔDe‹§Ô˜úWu8a	i3õ:ğ:		»YêAìùœºk@¢ş!œ~{Œxâ¶n½¢L¤m\ï",è2Åºdçã”ZÁX¤V whÊ —WÜ³ÁÉ{¡¹J4›àIïï<Nrsdøÿæ…ÒAçò
0Ï÷²‰AA¯#s[‘c®ğ[ËTC5´Ù?ÈˆÖĞÿü‚@—Å"Ø–zş[ú%,AFµcğŠ&3ó©$Àb¾ƒG`…­5ÙvL63©«ûµÃ lìÛrŸ+¯YÑt`h›W3éö¾®WŠCsæ#Xö|p[‘Â°„-_ÏdË®Îözë]„J`^îİƒÿ¾#åzùf@’/Ÿš19vßhéå5²åeş¹¼Å­ñóa~¦-Yø6nûjô¿Ô§{²^ÁØÂ[5Ø^ÑÎ*?ìt¬ÒÄ£Ú›ƒe=i–¡
,ÏAÄgD D¿Àr9_¹uØW‹} ‰@œFs»êşİ¡…Å<XyšZ—»l;$T‡‹ŒúC´„ìèÇr‘Şá–¬†˜bqÚYı×1wƒuˆÀr£2ÔhåÙQÖ¶é·…›@~~æôåv@£~zd¼Sˆ#¢ŠrœCÇ%¨¾ .”a'î¦›PBi0júWù‰:'-õÀö*çT$’(,tf„a]ıjO‡Iq£›2Ä4)[rRófÆ¦ì#u4;Sû`hN²a¨ˆJÊ’_¬8F+:\µ7£bşR .D„+tfG´ZbYıµïy.b¯¹¡ÒM÷i©LL£–QÕËEyñ§@˜ûj¤í>åÉ2:$Eh¬÷<íşÀ{¼¼ô‘rX}gb;û³È2F}í‰Vdpkk»²úªŠõRõìQ€µ±¦ŸVIÖÚÆDá†…§•‰Ouu%ê£Ó(„±œĞµ±ÊŸlµÍ%ZóN'¼a¿,tÿ°MµHfKæfÚÍQİk/`ĞíÉø/…è\–ÿcD³÷	ocåŞUÀÚ¬.ªb.`³D÷·}íàMaöG5_Üg¼„´`dÌnZ±€êéñ”ñ¾Xõôy¨ç9øß?DuiAğíµ˜¿$÷¤ßŒ¼ÁK†gê¼¹å]3ª‚²”åD<Ğı4	ÖrÁ»×H3h„!6lü£ó”õ]ÔnøıJ¿Åy•–´ê‹ßf^{+ü[G->DõØŸÇÑ|UöŒ$VòkM!™†F—@£@°<jÓJŒ{Ğ”)°
ñ
O}5²µ¼í†Ú)À@§#Ê}G;C—‰oAeJ€½*¼PÃ0÷ù"àO•
@')O¹§ËZ£Ú‘¦A2”¡9O@ ‘]!@y¬Û=b"Èx¦ô±Eûô*½‚ŠÃ RåwÅ†amÇ£İ
®ı¨¦ç1w´Ìğ§<³‰±"w½zÔÛ1D™ë»Z­‡îö«‰"â¨¡ÅaĞ@4ô N9ô{€:Êâÿ¤œÒ m'aeğĞYòĞ]t
Ê¢ËPÑ”¶¸‚ç·ÀÈŞhâ¡ˆÿÔM\æw~ñf®İv1ÑŠ	6axT{ª=X]¦©ÜĞx
•xì-¹‘àÕ9iZy—ÜX·!Ó`f§yËh:
Èùª½P¾jZÉsUÌ. ïlu¾îÈFŒ†ªÆ„ñüK/‡AÙN
@öp]x’(í|	á\+Çø†FÎvÿ­å¹IS{şĞG@¶x“r‘p±KL  ¸W¿]b.î,İÿ…)PÜ¸Tc¼ÎNÔ<ş¨…w½JB?:³×[Z “ã\Òä@yFvÜ)_åz0vşN ‚½jWÚÛ•"l
k‚PYêR4af“8ƒJ½™3 ğ÷oXè•×ÔàÌiaÈİ{,¿ÚK¤­m)”t]ÛÜ¸ÜèFs˜lò©Ñçß4.È•²ÄÄJvŒo‹‡É²Ó¥%”ÌjIïç;>qe‰AŞ£:ü‹z>ó³Ä)xşûaªc7[íêÜ6ŞøÆş«\eFt¹°.Ë/tğ6‡cƒÓ§hPÉ¸/CüåÃ‘'ŒšÌÇaéƒí¢:ÈxŞòıí@ZŞH 5º›’j”SqV|›h›z	4šÂóÁõëÙşş¦ô¥7À!b¾ßk±Í[oÊÖ.Hò4ŸácŠ;ØQ‰İÎGÈ~ÇÆ)™‚kÜÈ¤Õİ&–ênÉj%éÓLË‡!ğËİ@|í—~¡9|Çûîï¼Ù&©$öÂÔåÉÌ ÃB#}f†!´ÒÄ_Î–ïv?Ó@ÕñŸÛ¤]TC™Œd	¶”ƒ4WYGi•ŒŠ—ê)
Ó7^Q€ì@CmË‹í˜c·<#/Mó )Rj¶¿Íåòé–5ø¸ §ÑéüõfQİTl|İg…zœá7/v¶æ,~8d”0fÁ ³¿­4Š×î>¦XË&K1Ele÷nT°h'·Êûî¡ücvÔXòâ=ˆ÷™LT;¢¬®©¡SÕµ>ÔıŞgãğH#ˆLJÊû‘ZšÎÕÜÈáb£[íüôß®f¶ ŸEDJ¶Åq\V‰.Íâ*;Å¬¤È&/‰. d^€èÚü'-íƒÿ›}dKÏl¢´e:'ªN’âØq³T“"ˆº¦µçúÍre}ÚÍÜxD"ú¥@¦Î¿»ïÍ~á¹b§î~+¹™ã3ÓÔõˆÅî\s¾öêK³ğ­?¶ÊKL’Z·>£5jÉ•2çô®‰ê¡ômÀÜÚÁÒVê¨I¸MtB­aÁÎeW!qQ›`'IàáışWrÌö¯?3x‹¬!‡æ flÃªdÁ‡ÀíånW®¯˜³µaÌ ÄºTvik®ú¦€PûÚÙÔF2¯’SDÈ¾œDÂ~£q™ÕM2€©Àw/¤D°ôÉÕa:—‹ÛÎ-N9¤Q‡Şú“V}Aô€;¶ã*b~©LzÃSN˜k¼ËÇÆ
êà#Â‰Ršµ§ÔÍZ}¤’¿Îe–_+LğÔ…Z@ÈÊsòƒ*ñ¶–ä¨÷æ´@¡¿‰å^è…¡¥}ÑÉY¿ÌPœÁ¼œµbô£Ÿßè¤WĞÌÏ6ûöÄÅ+xÊVBœb/ŠÁÕksÛ˜Å0†DŞúØF3rX„d*c¦Çd“œªñqHß%:ì€;_u›É¸¸ÄE5¯C–÷IŸoìÊ:¹NÈ_8©á9|åí8PÉ0/SP˜×Í$6&q•AjPgd×>Ó5&<y¦€gïÖ9~DJb…İŸ°š%àìÂ9péx‘æl•è)1ö·Uò˜;¥‚œSv×y÷èÇ¡«ÌYø½8®È{ŞŸdÓ^óËŠ†üI-D!ÊCù¡ã~½ÓGçmør5¸¯Â*L7õ'Ä° \pŠt™—öº ÎNp¯ø¨·Ö\œëÉÀsŸ.õQòƒÚê…Øq#?‘ç@VBjü…ÉËP¾ÏçÈÛßrp¨J²ãHĞÌIde]0d‰{ü‚±ÉÏPvÓõ?À
„`úÌ¿–øZˆğ)“˜¾ÀàŠlJğ¢"ÜÒ/#Šsó&Æ–råêcÔ¸lª¶ƒØµÆIb-.¤Øºw`4ƒ IjF]±©ï,”ø³Áøñ·‘8·‹pö·ƒoš|†œŒãhÆgwWÎ8‘TG½w|
T·Tx%òn QPWnuq–N‹áÅd^-·’ò1àãnÑ¦zÍ	Ãvõ£>˜hÒ;ÒæÃ¯ÀüğÍFéÍ‘w¸zí|œ[qBª¨§ãÖ×ôIğÿÿkÂë Evª‚> ØW
÷9ÌQQÿÇ&°˜c¥õ/Tw¾Lö×¤P°şºäñÍyN[quDæijR;Ø,üY}Š^6€çû†¡å;Ò†¨JI3PZë$Õ
ZÍJq”ı›…½‚FL=r!@F*ƒ¸~ë[»iï[aÅ? °…j÷ƒ/–Ei×VHqˆoÚª©XøWZx6íRŒ:š§èeU¸ÉìÀ•
~ºûµRNµîÄ\D’0†—°7nô|…@I^³½òOq/íé‡Ñ®âRMø¦×Ij¿é`ìÓğ¾øX]÷z.‹}Ímg>Jé½ÑÌğ.ÓPleC½Ş)™·EX£
 ®Ñ`~ùAUvH¨ÊóàP§ˆ‹09¤r>š­}3äÊ¶©by,Q¡QÚ7*7g]2’É¡<”‡ Îk¹÷¶*»jÔü§›¥Ç¢áGÁ^íÈşÈ•pú$RÀ¨ÆÉJ„B@~)ğŒ“í0«]Æ™zÏœñ©ÄÃg`hf°.®~!:›òÔJ‹ldN¹bÄâş€7…Î"‚;sï·GÜëTõ»ªÃr^¹ÄÅ ›C‰He»È®ÓB‡îd-‰[²ñ¤€ÙIæ€RæIhâòx¢%ÑV¦L;:HşÂˆ·yn~•»½mö1Ë¦ÓDh ^Ş€HÎ×@~}/?u–×bÑïuKš%C'w]f0J¡“ò833?:Ôœ­¬)îŒi50®+jŠQÚÁP7ÅT0¹6–.—É”¥&æ,.¢øvµç£äqà«yò8Hö.¡z±ÜàSDZÀ-
Cá•¥QñÒ„ÄsuZ£’Èb Zq°.‰A˜y¯D}X1¥ËJ“u#•ÕUªU¾?·,,„^Šw5õëûKĞí»™üyñåÕoTUİpdñ¥U³@- İ-\O¬JiÙºs§ÓÀÔz×Yv€œñ´òz…Å…íàÕhG±‰C²wX-Æ-u¡Z®9Wèÿ!E[Åj·bƒZøùå¹JU$´_6ë ½êÌÔÄ´ïpEVöó¥w9,Ô“âÜ³|¶Ì=<c¥Tò+U	QÛd	±A· YD‘ºFø{|1åœß)V^*÷1^„°İõùg(x…¥ıTëV	{3Ò^]‹zµö@‘‹ypõ#”Q.(îÉ¦çE<Eñ5?M-?-»_\d‰J¼ÎM‘Gİ¦-‰{Ş¤ÄzC•1"µòØİæM«øÇöoÓşT+îşF ,Îï8&²MrJšbŞ,şöŠùSô}¦¾¦<“d¼¡]½	Ù€Å¸7ç‰,Ä­:Ì§ıÿ’‹»¢˜È‘§Ù?0ŒNh<½ˆ6!²‘Én$ğE†,¯gı´G9 :ˆêTc%äé[gFDÕ¾wÇFŠ3Kş½‘ÁÕåOÕ!ÔUì·:Ï}ßÒöÛîvBx!CÖşŸ”‰°a3â*óP8µ…D.Dü"áÇ’Ù‚Mİ€\L¥èYZw:`wöİ·ì<&D4/oS€ÆÖhd	ÖĞÙ?eíÅ•µ%ê~uà/9’œ„Õ9Ş7^l’­R^Ïi³v¸Ø¬v`„U¬µÈ©îM{
Zö1çïHâmÄ†=6|Jÿ‚é3ÅR;tinC0å×&§%ÖåÕ8z ÉÉ»'Ù°Jöÿ€áù7¾Nô·Üêæ{ş†Ì-¶6ÌöÆN°vw÷ßß+Eä¿C‚+•?_’(ú=,é6S ”Ä‘9^í;¨ùQL+ehiW/»Š€¢Œ}x[¬ƒ]_ d	Â»Â~P«^QÏÔ6]ïº¬”MG’ªC¯ìDÜ6$Mä;›k~bÒZNšÑ•ÙÓõcŸh…5Ş¤¦k6—Ïr+— 99ª°b3õeã8vŸ´û¹Åİ¾r ã>áv/áÄ[è¿°™9EI3·rCÓSJëJèÓ’Ê<Ôj± ¥«óÁ/!¡¶}Æ‘ıpZƒ
„ÀÂ>WO;K}.ÕWÒ¿w$õ ßòÄöU±œ7ì©dûå 7áÅ†ç/’Î›Âë4lÒ–‘wœ“nŸH';g4‘-Ô ÓÂ
3åç¬lf¸µÅëMÓøêm·QvóÌ’yo{®<µN2:ÙÇ–ß%0;ƒĞBm8‘g[°±¥C¨$nB í_ä•ÅŸ'OwôV¡Ù-%h$j¦íËíáåŒXĞP¶0c…§’²nÓ•zğæ8o5#ÍYÌwĞ@Q õÙlåg'˜¬§”dÖ„İÁB±³±SÅ{§RÛ¤p\O“BdBIËh^Hº+ÆÉ•AzÉ;4·×úÃ÷"]±(EÛã^àÓS€5:ºëådYã~²iåí¡ŒyËQ4Õ=”ı-B¼s…d®õs#ı	šVæûıT¾ğ©”òÎï#¥@Ll
Í…(nZçšâˆ“½9â\RÔ½{²ûQö;U¡å¨5“Äb¡pŠ#.+™=e¯Ç‹Rúê­=‡Øâ(\ø¢»÷Ü*’¤ïó:Y¾d”WôdRz8E8yüğäÊ_ˆgX§<®Ş0H×‘å$Ò˜ù:GÕbyÌ¤q×AêXŒ&Î:Ìë¤OØ+]=~Ú?è×C
~ÁÆÀ¢Pö½œèïR&Däó#¬W¡Æïƒ’}^ç×Ä´µšJ¥b	¸}¦¦mº‰Kë L¤”Ê«Ü(­´šÿ?,sÜ­jT
À‚X}Îlr«^Ì8£®‰Ê¨ŠÛjƒpy€Úõ_”¶óÎë³-#Aıı9¹÷Ş'ŒEUÌŸ3–<Lööáš×Èî6'˜ìuŒ[ä©CE_ª¢Èõ4±•Bú6/’[Ø?Tó|k1ëâÇGÄP;Åë‰[n˜)é¥53‡®"~eÅÌ™^>gC·±’ÂòÔ~Ê¤¯5|ßŠ¿_ kYÃäZüÒş91ïlÎKC{ìKAv!ØÒh˜œÇRêáS¬µ
JH®’X¯Hæ¸”¦·rú”-–>Ë2¨x;:}oİâAùÙ´wZGø3«ÏVM»._N‰¹!7>ç>¥È§ÿWË†#,1C)é_of†É¨Ş£¬pÜ‚7›ÿxœ×"şÏµè[#ÈÒÁ¼pó©†ÊÛ~Ç”ğf@ÍÜôÓéâ¹ò/‘VÑìÍ
eˆÚ/°=têøıRÓE+™–£ãQSI	*M§Â²TãÒW¥ïÓ"ƒÓ&ÔÿGÓ¯Ra•5O÷9ñU«éØ±&¢!Ës]$ÜÛ©*Â[ÛT¹ó÷QQ#¦ç3Hê=ŠdNÆ%©¶ˆ‚'wı È¡·NÀr}†/UÒO„¢R½õ0°ÎÑ>Í?¿[LŸŠ…/âN\ğO¬_ª9ò”…Šqæ%  *E¿ã†×~Jš»±è
´GPo·eÏÍ€U¡b²ïƒÖÃNA²m¡^l¨E‘G¥:5‡kåÀj«
õ‘™vo±ñç¨°å¬	P¥~»Ú"ÿ.ìTe7å²ØóÙVPÚÔÌÔÓ³|U}¦åšr¨qÓ°Ä„¼4¤)0éœ”9KÔ\m÷f¸mhp{˜ª*z/r~½‚OX6"fUĞó­€˜y©)@ùa"x85úçnæ¥Œ™´áT2³ºƒŞ/µdT–„tÆƒô±ÅãR¢‹™/Ùü=ı	şA%nß‚8gB¨LëŒ`ğáß–°kzpÆ„§éôÁh!H@ánà´ÿxQz»›åİöês´‚©Ã3z]‰±
‹ÒWßÖ—Èû<UJÎÆ!c§ıx€‹kJµ$ÄÎÉ†±mƒÃaQÃhUJC,fôVÂšÄşçÍä‰ˆ,LaZ¨Ì{kïâSdOMú2[˜f%£áó%¯!„gº!Z¯GN v¼l \rV6Q0Òr•çf¸¢@Ão²P6o¤ì%P(9ÌA UL;‹!.–Ÿ‡#¨ix¿9K¡|±ş8CãRÿŞ’(/‚H|Äß›O•Ó— Ù¹¾¼;Ç ¥bÃ ),ea£ltàø£®Æ0/ÊMD¼[ã:°då¾ró ¼Ë_µ“é_û^Lõ¯‘¢6’şĞ¬Ú³G¶ìOÛÉ>÷ÃQàlÑ$ıbb¯ÌÂ_;¢îÙëx9D,OßvÚîHÕ½¬ãwŞ›ÌKD–\Ñ¦å
-©âsjRXˆÆ+Æ„ÌŞ(¼\OÏÍÕyá–AhOÜåÔqè±dÈ£¢:ˆ\¬ş_¾aoÀNĞÙ	EÁ÷UÂÏ¾Õ³øÊh*–Ëû)"YP·+EI,L€?å¯û?V‰m²ã_Ñ„€ Í5ËöğüB Gæ‡%!ßxú.3Ÿ×ü;H Á!òçƒøù Ñà-zL5âÔrñºŞxA¢]Ã!–:©©ÍXïy*,§ûN;ëkféŠÅ³g=4¯‘±`è°Øéüj×O:>Ì q}ÃqÂg¯¿;‡*šª,s¥[¸/µ¹¥Tvë{šg¿Qèt@¬XgLÎÙ„K	d,é¦HÀJÆ{2›¶¶êƒ ­x_ {ïb.Cg c¦'àºNÎX_ÕËÇ:ìSŸÀÕÇöİıÿš’¼¤Z›3ë’¾ºŠ´·#£$a¦¹uÅlfò;Zÿ(­‹Çt™ìùÅ;,ÃìSÕjCòÛkİêîÿ‚ÆÜ’][ú lH²OqmÖIs»‹:f¡ïu	¾Ãrgü**±
BÉ¾Ó,Ó½Êp¨ïV.ç
EV7‰æ+Ö\ãhSnÖÀ ‹ftSsŸ‰t~ƒò…·Sñ­OÕNêI˜fÆ‹}úÜè…Ëµá€ßoü±Ï«FLGÓ4†œ—œï2]ìYÑÎhãüsS²‰QÂ+“·`Ów"A"Ÿæ ,-F qâqÍèÏy7üy¨ÈµËâ<ğó™»ÏqÄem˜OvAv@×WŒÄdÏÚy€ßÄ%4ÕP*Œ÷«-™+Å¶xzÎdŠ†œ®xU•Úôñylvı¯šş&ùè×â4Åµã5Gì¡ÄX¼”ªĞio’P+×n0ñ?/•“#˜Ä‹®ÛB2: ³ĞéßB]O@şTSJnÒä˜ªH¨XsC2ïFä—Åàıúª“«ó6¯àIB=­<æ©«*ò¥µã\SgÂ!±Gå0Ğb6Hªnd¢~æÜäODÛ¯†ÉØßLÍ6.x–9#ƒT¬…];ho-
ÔK†È¬’,NhÍ®¡>(.2™IhaøùW~Ã ‘÷¨––Xöâ©¤¼.tîµ=ÕËlÖtóåÎˆ%7_¸»*“Èï·¬~ÕE+¬Æ¸ö­*—ë:¡«õ0ÍoÍ3?©Áy2
\s¯Ueë(t”D%ÿØ<JßCOÄ³Û¬gÀ<tH™ª14º?¹-KøDwˆÕzšÎœ{ªë7‘I#£í|}ÁP¤úyÎûŒJ´í	r½¸06®7Ú’ÄÍ¾OŞáù{§ƒÄ;šG1™6?r4kCïq»uÂ(C‰wåI´—FËEà"0¡
…s-ÛÂlõB¨ËtqØQõ¤ ô^Ù–$ ˜Ÿ$Œ®ÕÛâ9+%­iÅ†…N Õz@XşR«}) û¶Ì;<e¶aoçÖ‰`€¥ÌT4NûS«ÆlxB(ˆ..Ûÿ#—é\7XH7SÚ'HäÚVT¨½¹$#ëîø¢$@¿_òŞ±	î£™¾·ún½«”wÃæË£c_)‚¤U² ÿƒá7ºc•‹7‹Õ”è+½—ZænÌuı+ÁûyuZ!M¶ây«Ùt˜sCÛ%!12â¢¬Ğ¦•­©¹.½&–B¢¦Tó¸;{?Û]op]<çÁ¡âªAxm1>ò:æËÑøl’œå/flã²øwç~TxjÜÖk$š&
tW³lÎ_jŒ†^Š¸zÑdo k} ½ßa<Èu¦6ZGv;Át7¹ÅíûQy+àÒtşæ\£Ër`ø;QÔ-äX±ø¸t‰­¼ÄÄG5B¤QÚğ4¨~çudğìò’Ô;dföË^9yî›ºãöˆP”iY÷uĞO‘E¡°Ù¬YY¥ß‹4‚¸i¨l—²ê	Æ%â8€T2WMØò3:´ecgºKy[FÙü¾*ê°º±¹O¸—Õ™ŠàFWã`>˜Š`"xˆ’i£ƒs› >ÁdŠƒ!¼â!P¿ i7œ¿|Mò¬ÈÊ³?÷{ ªŒÙÙ„ƒ‘ÈS8‡­;Š-ş=Ûcû”M^İÑXWÚ„«ëFç¹Y’Ï£MƒÀ¼[÷CB‹›3-Ñˆ–#1TI’V´›4«¿U¶)ÅïŒ{pá\âõ^9’3njozeağ|u†,Ü¾vŒ’8}—%g5Ç»WÊşu&ôôü&ˆ\…]ø’şN@5ÁÆä…äÒ«·²ÏÇ$â;å™G%i 24À+ĞÉyqŒÕÎ	q;¬"âEĞUÃÆ&\àL0'3i_‡ˆÙ±ÊYq	á25_ß–ğ#ºr#±½™3 ö“¢ì„9ìkkw G„ç¾Éü×´ò^wÂF3B™£íÁ~w©ï•J‹ÖQ	ÑE¬tÙÀØöaÒÑEÔ>‚Fja}†ZDKdîÛÈ°P¯S<‹É¦Ãtæceãæ”;A"Ñ~ÎW?{mñ”éNó§Lü
eû·É=.]p2¶SrÉüŞá©£èW9!ÆøpGG&$¯H—o‚*YjÚ]Ã¹e‚[¶x6¬òuIÔM©›	èœğùĞúØ¤ê!âÙæaèÄšZ½<Nå«ñÎzôX’Ú’Œxš‹–Ã=Å·—+±Œ¡<CÅ²}HöRèƒïf²G6Vúm#ÚˆasÏ¸Ìâªã|Éf^«˜ónL"§ê( ¹w- „7hT÷©òµTÃAŒzåû˜^§†uº°øg5/Š-U>ìFÈuØ[†JaÍ‰‘ ¬Ûd…!è[öšİBEõ"öTz'i¼¿2M©á™ßí>UH6*\(Îùºã“PîŠ0¤6èä$ïôú?ò¹™Êé¤ùÿ§_yÊüd7yİõæÏ^°±úÿ—ülúáí é‰İ¢"âë„-e¡´ô*·bI¸…™/ºùË	M¶©µÌ±ŠÓ±S”Úm/vjJˆK‰d÷?:X‡îkWOàÄ‡‚Õxv8^ë€ççùnáÅv8ÆÊõâè¥'ÊSkQ×°kVº1ÜG2ƒ}àÀŒSÈ./«®ßA`,—ßU>ôƒ5p!¬+M”\ñòË»^RLOşmpÎ°ƒÒ¢©fÖ<Ö¤GÑº~ãË_@~òbGñÁM7z)!ó$Lé/äÒWqÔÒd˜ùßÉƒ=Sõ–oû~QS@,‡2'Iqo5C$r[¼ú–SiK¯¤Ÿµd>ˆÜNÒÚß[4P
H¿Ó¢å$£Ücª¾«MÕ^ij¦[<º	ïM=Ş†g!şãìC…ŞÜ’¼p•lzĞrÛÓM.Ê)B@JûgKqh>±Cl ş%¬%¢¹HèÛWÚ';èx<XRMA(ŒlÏâÄñ’ºø ^	¬s¨Z~¼(œ–U±Û}[ÿ"YYHŸŸMW”Z$LR8%7õDQ¸P®IMá-R#cİW´–‘pæÇïÔ]²]B®JzvúzIãÒêĞVF£‡¿v«b?á:zÍƒÿŠæ-¬:ˆU–¦®Ôjn*áÿ¥ Z\_"
D¯¢İé×¾có§ƒúÖóÕ!UÙÊÕxN 0JYÊ2¤§!Ş†0t±°]p²ç>³¦ísLæökÂ`Û¡òa|xKÎÊó–Ã@yú]3:5‡¹CÆg;hÅŒ5‚aô•·ÂŒ@&÷¨d­à˜Ù+J\æ×ŞŞ ÚV}Ø+Şµó²İ"Ñ¨¦ü©–O–ğØ,€ŞÒCÔõ>$’Hq … ş¿W¬·é.Ò ğD›ùİ=8‚¶¹dcÇÊ!¼„€íèÇ¸ŸSRWrLc¡»UŠ85._¢œ‚ˆ=ã@¢<1D$IIx¥ú’3Û'd†jg£€)+Ø[-¨	ÎoøÒ7À[ÿ*Ø=ñfº%®Æ”Lg*HIV9—*&áÍ¡¤mW$…ûèÉ_i·“+Iû‡WU°¬ÕÛÅÈ!½6óË_ò{†Ÿt½ót}nh”Å˜Ş?9Ú¿¿‡R WÿŸ\uıçÍ*-'=–ºÄ~wÿ@°©³­gN˜oÊtcj«óXyÎEåél°ù@“Vsnê½/×cìZ¿V…Ä[%y n~a½	mÂÖe4ÌFÆëõ©nÃ.pß3>ªÉ=Z$®Ä “ÔøœC[ ß¹G†ø[ÃÂıQ•F&TK®
Å6¸†¶À<ÉùèeÒY/ •Èõ-U—TJgôYğ¿Ÿ0W¸×5­FRK‹Ïn#{Ç?>›Š"¸ª Âb¯$§¢â}‡a$£«À¥UgÆnûu¶§ã(¥qÚmÃf(Xó×ØÁ~uH›PÔ$;;hğ²nO3
~ô“ÅœïáÕã‘o($pºˆÈ´,–YB
Ãm+×åN6Ìïºë]iRG­{˜1Ò`uLŞÑÛ”ûm9íÿ=ê'tøUke9ñ?Í6)#a4wû¾-dM	´ViR E½ÑŞÀÁ\NóŒŞZÊöÆT¨ˆ_÷tF+®Ş¤ù:•-î¶ü™ÔÀ¦éJ¬ïGbáUª[]r¡³ÔXÃõÃ›jOÃŞ…É“w²ìÀï.£Ÿ·J$;¾³2š
£f|ë½UÒˆŞ$y9lrÎ¹c˜ú¦ÉÑË`ˆÀé‹C¨ºKcú5¶¿Ç.¨Áäxˆ²ÃeAG4¤MÆ§Ü'‹¶³HBá7Ï	Å±ıŠ’Æi6@Ş€ç?æÈàé­°$­GÆ6í:.SBÊX‹˜ãsÎ3„œ^/‡¬ÿdñ~Ÿ½¹ˆ×+X©Ô:\m?ˆâ D’6îª^Uqş|9[À¾k“ïÓÂİÉ‘×CÏj¦Ú	ùıú¹dÇ?î‘J}[zKõPÈV_8‡­ü‚§İ/€ÄıÂˆAÌ˜ÿ„¼” ¿ìWÌäê®U±ø¹ı*e	ú­~ouh9»á4E•çh„zx€Ô™qÙ ûùîJ…ÿÜ^ğH™L¤Ç¼ğSD:ÉL-ñú¹uù+Ó Ã¿7!ÆŞœ·8w:œö?à`<ˆGšli¤JÔ¥Š½ãK%«çÏßÄÁt–Û''È~«óİğ0ÓÏƒëïø@óÈ¨ÔŒÓvË‰@nÎdÑt.P#µMG7Ö?Ä¿Ê¨Âé?‡òEú,²ıÏ€¹<&•nˆ[ßÇÔ‡#Ùo2³$×Ô¸‘ /^şÛZêcÌã¶ìªWØà˜‰‘Ònuñ~ñô:5±ƒÄ­Zëx	„éÆk¥
eÙ
Ô³6ñİc–èkõËa´Ë=AE-®Oª‘s¬&áQ UeY¸ºà
ëêKR¤!Æ™ÀLk™AÃ&ÉÅ…šÆ{÷ğ;Á˜™/,êOÁ-ĞMîk ?U¾èŸ0ñâ„¬€Y{F™gE§ıVœ…A±|½6,á“ò/»)6·/Æ!¡­\éå¯w²N:àŞ=TĞT	¦®4š!r›â²lµ701Äj’-r:6ıK¸cL‹ô†¥	a¥GQô e›È˜‘è°ê"¹ÏcÜ”œ(³ÙÔ„WP¥	•ÌğÑjšÙ·LN¹}PÂ’ñ$gf”¯Ù§M«[7ĞÆZHh„RÇ‘,°o½){ÈsË"è×ù\VğõÁX`‚ –8²67GâmîË×­©—¹‡Ùx4h×(²0«NDæ_¾Šw}ÛFµ8Ì«T¶ú@?½²fpâ;éŞM»ì)¿}ùğËD Èjçaælk…Oøà€íJÒ0Ÿ¿òÕjcı¶>LUØpÊe©‚ªRurg÷N ÉK¼5?2s_så{ßî@ÿUÇÓ-ÎB/F½ì*¦âC«Úù4úĞï?%°1äáûşdÊ„¦íCÕŠéáDM§ü«™¬‘ŸäJ·÷ˆ™‘Ã˜lkŒô¢û,bè,ß ÌMÏÑ»£^á,P6zÆ.ÕtãJhÅJ1â>Iî\±UçS SÙàéÀ[qM·rïG3,» l˜-@š§ó‘(áuˆ"ãÑ!©Ö_İ³8VWT˜k1Z”@Ï–:"(	ËQn‡Œí ‚Ì½DDÖ½õ"Ábü
ñÿáD^Ó¬íæU>ív>Ê‹÷)Øx±Éív|™¯rA&Ox…ĞÂ àr¡Õî´Q§mÌÕ¦á1?‘NÁt›Ç³ØÊÒ­1-fŸW‘dFöªa¡|ã!A¤N¸ÇÑAä7.Àã,o‡YU¥–«€Ì£†°³„ı{ß#!¡¿ÕfÓğ…ğÓãœŠ•{a:¿œŠj}ì¡8Š(#Ë}{ìúÒrÚ&/şğÆ¿{F)&Û»õ¶Óaö9°ºúœT±¼zuRë:t˜´(çìmwV$$©t‰kG‰b›M¢®É¬«¹ÔbÆ¿_Â¶9_!Œ6HèĞ®Ği9J!'ù¾¾÷Y[rƒSí(Ç}=¸·<ûœ¹·œf›Wnn—‡CCÉ°ñï³QšfÌÁƒ»º)(hŸàÅå Õe˜#(F÷Æ§d7ÕxÙêiÂ¡ıûWJ%k¥ÿÑ¹¹áÜ1Z¯³š^˜êí÷µ’öì†÷H[İ\â¶ë–RıÅ¬U¶ÂòÁSø púgü CU5¥QÄ3µ¼3¨âĞ˜
b&å‘:ÔP^:%ù­_•¢;Ó‚.¾7Oø²Ç¨ì	òäëj¼c\Â*Ì=4Õ"¯PHA½¡õPdğÄò €Äõ±
EÏûW˜!Õ5»ï.ğNÈ`Ğ¿fsËü]Ã¬ÈNC ß±Œ "éu~ÇÃüçôŒíjS¬vJ¶ôñ´ÿ.–$4s¦„·ÍX7ÎÍvæu…”¬Lûò-.½¬o²iA]:ÿËdXš¸”É¿÷ä%[lİIÌ5x–Ä)w»M(œö¼(¿jÍé°©Ğèò¼{_t¦…T.ußuyEÏ”ÖÇ$ÜÈy“öaçÊå,AOEXİÑJ¥KdÓ©ÁèV£ëjŠ1Ëbw£ëm¨´­—*ä.Ü¶«»€Û:²m]4G
ìm~^AşØè=_ë\õQÇ¦øêƒÜÑh3ÏüäøÛ”Í²}I@ e¥ÄŠ“8ûÓE‡gÔ\ïsÅõafî&p¤¥Apâá7kÖtëÀ°Å§³ëPZœsÓç‹¥Ø)Î\2}È=ÔdäåC"}÷B,[Ëˆƒ¨V˜H;¥áx\°ö–ù«¬rå_J«,ö¤D ×Ïo÷×.>—]ë¼N§ë¢ä·Ê8™œä:E²ÇƒŞz¯W*ŞMC°ª–™Ô ¦Ïe:‰‰dUÖŒ^:
ïb9%ßWÍ—8Mıvß—˜F.d äxí{!…*¡OÇ¿Z”p{¦ô‡Ü‘Ù÷¸–TYÁª.`äåéz™øÏ¿ùRG 3€®Hô”‘º;x¹©é’UÎ@²¸¼tB}ÆíöL´S•§ôN»=zú	æÛÛÄÂ£‰…¯ğG˜
¾¼¯AÚ$#,/ÀG­Ò®°amäš0âIš©·5ãDi,ñòc¯£äˆb~›òğ9#>jõjşV7UÚ:à‰AÂŞ”„|ùğ±O3:œÑ(fÍKcŠ’˜ØjD!ó±›¡|ËÂÍq«GPH*wÔ@ø0#»Êó~i‡k6G, 9?’€à(¸Ä,,F!lûuÕ÷æÓhÄ<± vÜøË\"ãúîPÛ“4Â–ÏY–ã¸ zØM°„nÎÊ]bf
˜Zú·‰%ĞŞ|û³Şdâ¾¡š/òCBtZ:…Pğ«K®­ŞJÅËy\¯ÑÎ!Îøq¨%VuP{œ`ÁÎ-Å)æT`Î‹û«U)1ˆ RiVáÆÑùYÖ Ôéz	pômA#$¾ ŒÅçÿo¿9Ukq!D›Òz«™OÑí*]Yl­<6çÜ–Ÿ¥a2RyØHÓò¶"‚e(É¯#«BÂgM1úxM7nÀ5:³ı:® İ~ü¢“ôÍKÂyGòº³]|ï£§´úÚ#="N¦dúçm*bæ±¬ñóØ¶»öÇ:Èf˜¿.æñ±Ğ™±N»¸“$ªÓ w)€+ë¿$ç•ª‹6”µ’³‰ìE·ĞœøLU® [<ÆŸ”y}‘FÅhÑQÁ•x SnAWêŸ»Ñ§•M#ôĞÑ3Zt–µbî]Ú3£`Îû-¡¸t©œÂáYÛwÄP=JË'ànüÅ)K´èÄÔøÆ;ĞYD\Iç ªşe”C‡Ùq
|46Œp8qè?cË©FƒìªÚ”Î ÏÕğÂî1¡Ó;}¶‡Aµ‹5Ê“XƒÛæšPFI‘ÔYÃ—|7ÕÉGÆ²¯£İäÆ ¢Ä®¨`ò¾Ü´ş²ü97‰t]˜çac¥òõwJwş”‹o4İ0yuyª1(²°ûÜœ
ÆÅ-tÇ¸Â@za7,4^¶gO,Fà9ˆÌ…•fg(w©¢mÄÚs3¾n)¹t®8>9äJ˜Î@m«ÌnìŒi/Ô=6[œâãs
š!?gÿŒäúº`d"0ÜÑg6U{ÅV ñ”¸µzü·Ğ«KhIìÀ%ıøÊ¥jZÇû`uïµ±Z	±Ğ°ã‡ªÆòÄÃYü/m=å3m¤'Mà.äûÄ9³"í.¦˜£›4Gæ[BÓTƒ©m ÇÑ~q›HÓÑ÷%]v†*<íÀkçÀú/ÆÎP—õGÆyËÆs«5î¤å‘ó"rÆ†Õ‚˜ßÁŸ§°„Šy=`×÷q¡µÊ›jT«éıdÇ×_òT…/œ4dr®Pôİ„ì("ÕŠ}«Æpı,êhfRHçğ5´ 8¿ñØ!©6Z:	5!&AFŠ[#ƒæ¸z
i/m©ûø´µªå¹H³5yÕŠòæøM
ÑBT¸4ë¿:XJ/gÀ¦`ù’ù¹Å_¸a‚É‹Rª.òÎ-4—â¸]wJÛæˆ¸Êãİ€ë}çÛÊXê·öF¸fb‡SULğÂ›-+èú.¼u+—0VüA$X´Ÿ´ÛÃG°87sW\V€ZØˆÅÌ%LAò)KŞ–5mÚ¼Z¸•uq¹BMfàu®ò(fyìò´áh<I*Õåk1¸hªÔæØY[™¬•Ú‡…A}‰zÿORŠqêL„±8"P&T²–ixâióÆVœ²‰ÅŠ¦D¦ù«{Ş	»öÉ÷Ü’VâyK¹ºÆ}ÔåuW‰â¬4k{gûäƒ
WÁTa»†ôş6n[$<Wñ#0T9›;ßÍ	|¡0äÚ¸Ï¾GI)Öõ’Ì­ÕOk>#òe•z$ufƒg¾„Á*3NÆÓâ¤UyĞmˆ.:­ªù­(ß‰bcÌ¤)a¨2¿zô’TWÖ‚¬Â¾…"å NxV]nÈ„Nî“¢‰^~Ü´!ÜÕ{äÀœæ>Ã£áæòE‘_	ïá·Gİ9BljìêÚî²CcRbü•ü^Ğğ™§ûU9å§Áğ›6y«õ9'Hg¾²5ÿÑ‘¿³ãXıöşÙÿI±A‹8hìãîå@‹ÓÈ#Ù&Ğj#Ôzdæ9Íjä<7C™)ÖûIğ\‡ø!ˆ‹÷ºF DÒœÎŠ€nRêâ8ªMª5Lq’«…Eìê]=Õ“üj*|¦¯hnbû¥C9Úw¦gÔE––\ÏÊêPAñ€©»w“´Úîüõİhz<C¿	o»vèö²¦4z˜aQ•ğ/<­p¤Dr‘À¯ÑÊD0‘Ácª’/„ÿÄ©MÑHœ	ğIcÊƒóİ…›Évcm-eïN*J
óÎZx…aTE%üëºjø$ŒpßÖ#è€Ü’£ü~{N‹şêW_»  ÀË!Á¦¡ğ¨‘‹DÂø#Ài¡s~Œ=?š•lä"8ŠçJgp¥ÉŞ|mâs»7n8C•ÌòTeõEPw¼ƒêUú¦:+.R³Â“{'İN/¤ã‹x¥Ï»C¬g§³z0¥J}b€o[.mˆ—ÎlF!ŠÍ¿àÆ@¸¢¼Ëê–Qd£‘5T_ìÄÔßlD2,œ÷|üJ]ÙøœÅubI¬t%ş•çÌû³¥–x1ä¹Nd·¦Í…ÈñÑ+¤rÜ”	Üv&¬‰ß\ì×Õû„'TÂœSC°xá1Š½Ò”ìëc¸9´®SB]
/î&3ªòaóêY7´ÆmCñf¸m´)-ƒæ€/AŠÚ“–‹:ŞcbcÆ;'{Õd3 „ÌËº<ì•å¦ÔÂ¬`qR*–0™_¶Í¢9B‘?Tÿºí5üë÷,"7Àª¼ğÅÚ·â„¥ÎÏŸ¼™ƒ‹»æ|¾†±ï"d¸i3‚'WHµŠ]şóçûo; k×ÇVzdîÌønVì‰Á#}±kËoVÕR²ãƒOŒ„x›¡Ú_?[}Ë>,½n«­¹¢ùsur§«©f‹?U9¨€Jtg±¸ÍÏ!&KZ¼‘«œÑ-X¦ü4yàA })øà-b›§$úƒ0òÿ¶©Waî%’§ùåîÅÁ3¢¾3ä£;…ÓÑvePì
(kQ4‰‘Î¸CÃRKw‘,]Ó395©ğÃÅ'ıôi…{#c,Ç™"Š=ıÆö®ü‡‚W‰ï-ú¸ÄŸqúê¬Ñ›eĞ3Î{Û7R;4s¦Ô""ühr£3¥a’ßõ|;™œ5•mä¶˜:Ä”ê­…ûÀxÌÑ•›µ‘R²ÿ_›,Ó´ŒÖ^êq"×¸ynÖ:6Íi4d50¡ô%L(å Ó@RYÇnbì”DÕÊR7ÿíïÉ9{\á„õœCuQÔUPR‹ÔW/å=T0§®Öé†EÜ>êßhŞşÙàƒÍm
Ù÷º½şt;ÆSÊ£A.‘D÷i|Úª$ÿıáµu©Â¥>°£¯õO&’î£Í!¾mÿø1xftšEéíW¥5ÍóF¨wÓÃ‡j|»ElrN2°[·19Î,pØĞ±I=ĞÔ=¼Tğ·É•QxÀêæ€Ó0¯¥'|o¿Ùsôšy´Ò~â´Í¢ÂßOÅıM„ô¾V4Òˆ–Gğ•ºY¨VJŒ“Ôuº˜DIà¯–4Àª§C°ÙCóŒÓ; kë+*w-ß¥ó©æê |@X¤€Ø;‘lı.›À`4MÜÊt@ş£Ì–‰ı	{æ@£¾6Îå¯u—• (·«DU«×¥ˆ4q†:7òñ±ü™¯å¾bzX&{”y2âÄ\fº}ÚmyeÃ]¹»X#_œë¬F³YDùUzk³ÜY× êC/¹bCEhƒR›úPvnùníÜÄ	9• æãc…H1‹pıİiSvy—ƒjø>Ğ…ù’ÄTJv*O9ªE·ãSòƒ%×ê›	{¤†pfjm¬Åfó³ıqØjĞ¤ZãZâc‚·9Í
É;ÿ×‰,G­O#‚³•sXK3\ÉGÓ{F¨İ6*CAµôİ®é*‘@æ’ÎL“/!´üQ©æSmXA‰ª…·ÅAÉ&1Í?Ûµùc‡³€şäÕÔÿù©5ç³1ìı`Óu˜q¡Ûº2Sô>#Eş^,ï3j›G‹MsejAøèÀXé6ÚHCZÀîUS°‰âï³pµÕpÄ¤{ËªgDÃëf ê­ö·ßóËÛË¡Š©¯µÙ‰ŞSfÇ
«™ĞÈ^=u¦.„n§º¥Oéê¡znğ@ZOTë`(ßQøIIí«’»ˆ;¾%']nV¬Q÷l{6ä ·Ód\ÿM¹é?Ú,T¾m´#yˆãİÆ,»03æñh‰X¥_ühv¶}}·ÿÒ+¨’•ÇÌzS…‹D3ÊèqNQø‰_¼—ù¯"È}GÃÖ™z•mt¢\~Z/Y«lµŠ£#¥Éh½˜ÃÀ¾@K\?¶¦Ëøö¢­Ô¸j¥¢§ĞC¡~r#aæúã±˜‘ñ“Tó>Ë?‘.½×ıy´µÃ™&?+lÊæ¾W Ú¨‘b]iûlÏ{5@ƒıÙÿlƒÑû±fĞNø?
\Ş´ÿ—a™¤^™HùÔ¹·Dy ÷'x7HîáJtåùHs¦U>Ã’•‚²Cœî½_ûM·ÿÎ°‚!+åí®€Ï4Y»FĞlº•X4 :t‰Î@.Í½Hğ!@‹'Óß \3;”¾™rÅz/÷ÊÓá¡O„§İD»UÖu³åŠ-×¹øç(îx†\v-«×„zRQğß›”C2(¢C©LéŠFXóïÂ³°X§ËÉğ8JÛ×Ÿ—¢Dên?©…ö}!NZ„9k•ı)ŸŠÅmæ¢FXêõÛ¼ÆkÉôàY6_ÕÈµ›İüÖéÀ’õÍRd0Î¤¯mLµ‹«å‰qU—˜f9ìïĞ!Î@Õ°Ì-ì•œ)õ±ş%md°‰1¼‰Ô® ª
Túß Û´:?Mç ûÄI*¡G;äÑFçç\×U*ª²âÃPgDZN'¦Ms‡[{¥A^'aõúYâ´¢lÀğõ¦u»CËÜ,9 W¾ Ö[¼^Œ¶ãèmÄ”•ÒµW8ÈŞ6º‹‰ò¡ Ebã¾PPÍU…ÆÆõÕÊ{ ªLTÁöğ_şeÑ"=úÜ£~LIx/hÒ%m¿0s_ì39ĞcÅöSš|…ÁQ^#Crä¯Â³+ÜÁô`ršøÈoæ¤ı–BÒ¾”Œ¥ åöIÜšÏ#ğÚé¶ï”¾K<¿r‘¦rF¶1œİ£ÿ#Ã{VÌhÛÚt £p Fi1AÆNˆF¨µ,½S–OH6Çrêà;0ı Î§Ğü6†î¼si+ÚWœ$Ş„Sv¥+îYõuLø€˜â®O‹õ°/}çMãÆšI¥òÛøsrªÎks_æ-fı]%™|
cUG$ìd\?àŒFmëù÷®­Û¸
ş™Ô—w=éa„ÀÜãı¤)É7se~ßÁ*XxÍU+0gÇlnâ|&2zy²<JÒ–ÛZn¾%GJ7ÕP¶ÑÄğ¢›Ÿ „s¥€¡	ÊŠúË‰:ª.° ¥ŠİKnçuofDğSZŞ°İE2`íÔ¨‰§@%xK](DÚØ#])(¶]¦-Ëøç0Ÿ9vPb«O¢eÌgYÃÍi›~
Ñ	©áEÏoL²»¯2ˆeJBš4cS'nÆzQdjTÇH	g‹;"‘i·ÔF‘ªŒƒ^üÄ²hMëb/ü¯ã%n{Ä|¨`B`}6À\ršõGµ$.?yˆ^³êG\bûr˜m¾7±’ó¿ã¯4.zÃ,c8¦+ˆãbˆ   Zj9kÎ¥ç ®¢€ ŒIô±Ägû    YZ