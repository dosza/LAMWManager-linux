#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1825335117"
MD5="96ce7f76f67e1d996848434afd59cae9"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21160"
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
	echo Date of packaging: Mon May 18 17:54:32 -03 2020
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿRf] ¼}•ÀJFœÄÿ.»á_jÏñÒ¡w‡(a:(°ëî	¾=ÑõÏ²=è†ù'›–ft­?z 15eÀë ÃÔßNèàkdV¾CŠ94llÕvif¨RAfa´r!’µö³.M½0î}üãCu
sÒB$|½¡ÏuCL§>Ğª¢ªÖ+3¡\À½æ°
š«U˜rÑNê³Ï•¤ÜÑÙs´7·Ş.&‘Ò°*BÑ¥œ9È7®w)=Ï7}Û&›pS=3æn	¶˜…]Ï†ñ$X¾"ÌU8(ÁœuÏXÎş2ˆl1ŸlœÇÍ¦¹ z{lË%lC3Ï7QebV–çC¦çëv(¯ÈóE›úÂy<€Fâ<b+ 4²¶0»4l-şËİ'U¼Âe.’XTÇÓŸÙsØøÊÛ±³×ã"Ú¥í7kÊeÁ"æVŒtíôfØÜ÷´Ÿô*–~âÍ¨¬_ô*-sÀôòîs$pÍuSÌÉ8ú…¡á ë~$^½Un%—nİI	/|ÿXµÉafTb”­rŠ@"!	MÒísá$OíºïN†ØxÏõ$~„ƒ…ïş&ia`Ê˜Ø£äe‰?ïºó$£¢ÄC|à.Á=Ö¼¦px\íÂÚ,Â\CÂíLJ?ŸØYvàşy&Ğ&’Ó?øâ%s%@!P™İ·^kŠZ½îÒ5¼é"\ÿQ¥Øyj)å\æSóøœ_‘éHï.Ø¡WöØî°@¿0
~T‘¼/…Tˆ£íÑLÒêR¹^ŒfAŸœEDİ¿ÕÏaÆıßâo[lÄ¥CóÕõEn|oˆ›yûù_IXT<ë1.P~0GlŞvyj‰‘ÃàÚÓ2_Øú³€Ñ„˜Œ›ë¿Ü‹‘ãyñ•8±ˆß¿ø¦qÖB}Û[*¢µc©5t4bôÃgG]D¿™ÜşKekyóR}¸G˜@ĞOA9¾@ïØo19maDD@co\,JÆûŠ}…ÆF¹¶Cğ¿¡O©A*°<2D¤Q5§u¿õíÈoä¯Ş³FûrÅš°æyÇë/ 7-‘á2- Ä*pÅ>phñ3l¨Ş¼Şkûu¼d ~˜Zî4;™º¢¢J—AØXJp™ŠG¤P 3`¹w$Ï7¿OØÅÏÁnÎ9ŸòQ0¬Ï_1Öó¨> $–XuØ„)CŠ˜úh`•¿ÆKPÙÖ¬7Zn7xŞ¨hpŸ°Ztç’‚@<Û» çi~X”M…(ş÷(æãÈÿ7<vtug1Ë|×l8cÑögÇëúğOË9­3&û-¥æ’Ûcˆ\è>óqb¿¤rÇ·šØ6…O|e•ºßËD|ÁJ ó\¥K%L	İìg6Ñr®&g\*œR#ÔqÍÖÆ‘NTTı¢-,¼~0ÀÖªÑìLŸVv¡Š:AŞ¡,+–ƒ3şN*
1å5òÈQˆlëÓ8õoæÂ*M#Õá®{ ÑNñOt—EK©†=zö!s&ŸÖp»Ë¥/'ÂÜà[Ï£ú+3OW:+b 6hDüÔ¹;mÑ	ø–«7*ŸÕş£~PDgf·5?f`›Õ¬	ÛÛÔÛ™Úö#:Ë˜²¹q0ƒ2šD]l vKT[a/	­y”dø|Ì'U‰ZkˆİSeğŠ\X³¨ŠV6£û_ŠU16¨`_r„e¨3uçğĞoO-‰t©Âîj˜¹ÖµÖé‰C|ò´µT,à’&Á‚Q5œÔ$p ÒN€±¸4F(¿G1›4ƒmü:AèæpÂEd¿½‡
Ù~É.ySPŞ°ºİ[1z%ÏH¥Ø7è°ºW:Jû	07šèXÕ3( •`LEëqÔdÏÏsö3egººeOZB¿Ÿ ıA©[èïPéğaQq¯âHÛT_­üú0„¿èÚQG†e0>tÏõ›rw0µ€±XøÆ-*èbıbYÖ`†´’¡_X;õ4PŒR(O¶“¤Á4ëŸp*fXŸŞ\‰ŞbÙ$ÚÏ/m´Z².C3ú£6ÙäÅùêÖî
ÈU…µb¯d~¡Ò-YmßIÜš£«qÃ·P%a³
åtò§Ğ@’:û,¢‘ÀZæ¼F•hàTèâ‰+¯Óª>v>È8•°¾H— KU‡ÙAxV„;Å¡äÌc^@?%ÑhpI&€†9K;Î»nAØfÛ&ğU]£oA«‡Rµ]dœì+±ğ³Lcù!©¤–Ï‚we‡äK"}ÊÈÊ«İNwlÊ4ÉÛ!„Çù=[Šn°\€Gš º ”÷î9ÿq¦§oH®®–ˆe_wîSièhÔ‘nüÛ
"Rbt,ğ,=Dşpæ^Ë]Ô•ç§¼×_ñûåÜê&İ‹ ÎzG²Îjw)÷ÕQÌ´İ
H {p\AE‰\©'°áêÀAÍëhªªh@ÛˆnÒ÷Ãµ~ĞÄ&WBùµµÚW¦U&´‹ÿ2&¢s3d’Œrj%d¥Ü´SÌ[ÏA-Xö9üÌÂš¸äÆ¦ó4l!@ó;Jì–Z€8ßÁHGö»²øÆd6[9$ÌÏnûEà©šíµSä‘&Fæ•;m~ûx$+ã’ÛKÆ¼h¯é2*NÑJşOjk :tt¿	Ã}µŠàûeôãG·+ã<BÖ`Ê«êZmR”ó ú?ˆF#Ú5vİZ›gºkj°<Ô~WÇÿ3°M$3‰C‰Š\’äÓ—bï­xÌáM
Ï£U—°z
YœÁ¼7ºş¥¢ÚAAä6ó—\ö'Ÿs×E¾¤¶}*û]‰3 asàR@“
ïkû#öh`‚sÏRİÔº¡TEL‡¨R5¶xKæøOƒi®QX\&ìe¡‘ƒQŞblEÄi*úÃôªkSâ}'eØŞn5àÆĞ'A…X”³15âx%3ÅÏdòü°jÄl5½ß3wîÖ1¡D¬&;ÈÑ|ÿÖAò&E­\)Õcåï¥üìÜÖ§§PvL ºx·6çj‘\¥ñÓ»#f×H•ŸB!ve<Ğè^`Å"J’WˆÃEQì
*"Ô$ ììÍ‘ÜÌy‚WƒŠ"*ë±’FzÃC3âŸMHuğ+Ø³#L*"*_šjİ tŠS‰ôÉœùk®©’±ày”xV*J]aÏúWÄÃR°ÿí€“¨Ñh	ÅÏ½¨òRÙ£»XC¤bF)¼|8’ZhFIrğÅáÓx3u,8ü/1:é°4ºiNDCö·,Bjí©d¬OÑlÿVûûç^µ•<”B£fÌæck}¡™|*úàb/óÅÕ‚óôç3Å•¾Ø\ú¥=ãJK„>¥,jóœyVà‡UıálGN¯5†[GyËå;A$£>CrFª—QÅ».vÛ #l ¬ è@Azsº1†<ş¡‘{ÄÅ}°ªKßFÊw¢A"TC™ r¢İs¨…vÎ6­=]à²{´ä"ôwÓz[d½ôNFfÀkvŸá&m­Ø*¹eBßÜ%ÿmÅÕ^¸\Œ˜lqî	É1h#Â(Sê˜ipá Àë¶W:g´bnœ"LÉšÿA¨'Æ?fŒ¼²pğÒîãgNÛ½É¡”ó‡,
×Å<Ù(­ ÑºÂÖ³Ì^6!† a¬ ”âKË‚@ŞäÅ~Íõ®›9¶ |ı’©7i¿|!¾ ø©×”>ÓºJTŞY“ëÆù[JF¥ùJõŞc(v•”™nZÑö«î×
6ëmÙ~±×;p–_©,fk–´NÔœ¬‚öx
îuÑÄ(öõ2‡ÔíJ4 ¨a?Õµ,(QylÕ/#˜6;¾ÁêÂF_JôåÀ²€”
İ‹DÖèå^czG>\¸û¾·Èï'²BQÛ®²Tˆ7ıw“&y&¶fûuZ¶æÙ×øã}Ósè¿¾QÊ…_¸%‘ìıa2A>ø¿ Ä~Ÿœ.Ú>OéF|@v`ü¹*µÓm=-¹‹Hê#"ú½(b1ÎñüèüshG+…ß•²w0|÷›¤ÀŠP£fjÑéÊ°3!Ú]É››P(4~*J*p.!ÛÄöõ” ¯ĞH5¸õ5‰ØeİÕÀì<KT•{¿O¹Éı¼¼(ø®­ºMÚî(@ıXBá}ÍßÊ~ÊÏ“A^é‰èÄ‚§Cœ:	õ¡Ù2ôgNöh]‹:Ü Ï±s¦”Œ©7Ü4ş;É:œI%-‘.W}*N”YĞ5T2—i×ŒVKÄJ²|nÃ®×d®ÕNuó–ú€œhXÛõe@»¢7èìıúmEÚŠ­i¡kˆ¢	Ê‘cNÏ7’¡4[!^L8÷äÌ:ÏE
i¿2ğº1æYò3y,!YÉIÎ`0M‚ß×·˜Ê|OkÊ?DCĞíN!ŸvM2ñÛ¥Oƒ‚¶š+•¼îœ¥ŞÙzš¯Ú‚³~3‰†QÓ­GÙ×*şìÙ§v'+2‡/)®š$ĞâµET.<1ç#ÈÁÌ¾rdôıßsW\Djó·1
8+Çh £QêV¨l`LÁi&.ãC¬Uï[=³Ã5‰ùÉÄ!lqà5Ü1/‘ÇË¦‹·LUôæÀ¿ŒQ±Ì/‡L²×q°´GjöÖÏhòFsáù^¡TŞµG9ó„LŸ7»¾Ï’Óe¶XÃ	à©öÑÁé|S%U-ºbc¥b,Ûàùcºl|Åò3K±R™°BYxzèµ€À”©™|» XPSWq~^ø\NêŞ%zÙ¥…
ç‹ÅxX¸\-+ñ¹yAjˆ4&ºê®Á½\¬`¶KˆÓdsöUpu?V'qY|D.BØ£8çMZ(	Å¡‹®—½
­sÿ°MySÇÇ’u¥²;g•ıåI¶âİ€ÊíHoäàÖ"'ğ å¶Ätˆ*.øÂPU›ÖP(½ZZ	MS’ÏşÇåŒUJGS9©­\ãoÁ3/kSvË¬©ØÇ3ã€Ñÿ½ Ã²œà©¼1Û¢˜àòğ Î’¢s$ÄÏa½èB8éŸøŸ(V}%£Oæiå›j'ğ±û‰¿Sï';Fˆ¹&‡]Wa`Ó'€,qÈGª,>§Í¾ç9³~ù\€CkøPg>Û§ŞLû#ó®';î´å¾¯moVquÜ‰/‚ÊI'^¢àò¡è¸«¾…:üÎŒ—uJÙøÁßŠıáÀıÅ°*K»ŸícG‚¯,”W‹vÊ|üÚh€ºï(¸³ÀcâÂÍ¼6íÆæ‰šéËSe®Wìt»: 9ıló˜E<Ós¸D²¿ŸÉÂ_õÓ#WÜÁY&$ıKù]ŠeÅô$QBI±'Œ¬œ! ‹ë¿lòâ“I¶BT©ôÄRÍœvSîzG½¸Ö†Úşí=ò\²FM«÷€İÜF;Üi†¬Ÿ¨AŠ“‘¦¸#Ÿª»³{¥U½µ@›p¸‹„úŠ0¯£-Ã!ë>‰‘$çß`ÕÆjJ¬¥Ø..yÃ´ŸÂv;í…	’)ş
ªXyXÅG0ÖZ5gÅM$eõŠ].ï •ĞS¡Jç [œU¼Õ‹œ}fL~Je§îàÿ&J7ULŠãŒ‚Ôøt3ë˜(0°ëÇé†r'jö	6¨oÎé¯ÓëR²b™¢JüÛI®áÑ6¤éæ*öæ±pı^@+á3ëæPŠÛ¢ÓàÕñ4Y‰í¿è?²«x¹’ßC§^ıl®(•İñu)øgAYûµQuß‘y}+á„=ŠÀ©¾0­À´g?)yZÕjr,uèöæ®š†™ŞûYMd³”FÙ#Õ»¦êBñ)H#ƒƒNêxl'÷u­v*Å¥ö4‹9cÍ@I¬RNxuÔi‚,Â•ØÏ-öšœßãĞğX›)QönîH¹_YiıÜ¼h°˜¯w¢ŠÌ«Ñ8o`‚,)nX!7%9‚Ô€–ˆÎÎ¬Ø8ÆÓQD²”@äcqa”aŸ!2¥Ù‡œ5eØVÀ(ÂüÒ(Õ§[¿TQ¢êšòë&í9sS·×óU”¶Îô[Uûİ}Äoã7çáb‹-Œt:HŠš#~qÒ×|Û^ò0Ã>W~"Pç‹^J¿À¡”æ60#€ÉåÛSò®çâJ®ŠW¥dÈâ1É†pab´A½Ó}hr
{"Ğ~¡ ¯)jjšÇ€7ö	'ñÓş/BÃ{×İä¾»JüV´LH‚éîWü'ĞnÍd9I4òÓ5ü‰l¬`®şœTsq¬ï]½Ê¹m'ûxI>¤zÕƒtª!¬AßDPô˜?r˜oëEæ4ùü4;©^|’yçä~š6#Zü;ÌˆûêNw*·ÓÁû¤ŒaÊÅ*¿—\LŸ ˜{Zäk¨Ô;ëØnÂ«Ú¶„®ÍyËAÙ—ÈéŞû[Üqa
cÌÿ…YğR€"áEóèyâîÃ1÷şWÅé~¡?°´ôéèş;á¿Ù<€f[j$¤‡É:Vª!Ha7 Æ`}°`0üĞ+·C;ê~¤+‘ş6,ƒõÿŠ§L±µpOûÎq7l¶]'J»ÌÜnùvà„\ÆReˆ¼ê&fÊyLô¦"¥Ö¢¼‡É£Y8+F0j›ˆˆ‘#O­ŞÀgtÑÀYƒqS òÃäó‹Fêÿ‚f°Ãy…ˆŞîÂL€G“oÍ•Dt÷Ÿòk‚”Ëâ¦ƒÅˆ½ug‘…A7—êI8”K({ü«xÛA6Ÿ[ô=|¡­w¤©ÃcUXÿ<µ{??6R	hLÎ	®£ŸŞÌCÇNLõ¬º%¤•S9äåÃ«j#Œ +o¾œèxéZr'ëèH~++ó»Lcr«¼0Nİ5Èy³İ¢õô¾ÕÕlº÷¾Õ¬‘ÁõJpñ=”’&6ø˜‘È¦ä£|QÚ®-‹Bù8Û¯d+2²ı,Zışÿ:š=E`óvÎĞ£Å‚ôj¿ÕDp¨Ïb‡wgÀlĞg‹–”>ËÙ½¥™Q×k4<r3À¸ñ¹n„¢çò~ş!+û˜2
k¼-8Ô[÷îõ÷ Ã£àŠhLéİ¾Ô~ŞÙMÂÜtíx”S²è!§KÜ†£BvÈ²$3…‰Y/èßÒ_‘)¿|×ç8\¿V¦(‚,C¡<à1LIñ@'%'à_Ät
æ¸¦Ôû õãk˜’,û26TªL\	SÃ‘5‰ÅğÓ­Ldáİ˜x:Uñ´#L§W%ÆYœ£ï ‹„0ùI¤Ñ¤Ä~Œ½Vùæ4WŒ‹&µĞ©ò¥ŞÌL$ô¥ÿ¥¬viÆ†JôÂÀË6İ zG†œÀÀÇ:{,¸ÔFí{¶/ê*¤çåA¦Æ5vu^åZÆ[è^æ¯åX·ƒ©¢- ÙORx3Vt^ç#ê£™j¿S»òDï‘¶¥˜aÆrËìİLÃ¢Ë¸Uµİ¢ÿôãòÃo(%™˜=È>à¹¸í/”Üáî3™"ˆM_ÙiiePkû2v­áÃ`®´>>z˜»)>0 „ît¦»ĞpëPŞ¿¥d&G‚5ùw2mn». ÁÔhÃŠô(ROTsY¥N…üDPâ¤¾‰pÓ°ºC©Ssœ—‡H ®	'
ØFØG¿!¨UT€j	–İu;ÂAÜš¤}ê–=WÊ~RÄÎr£ø—Ø­Œ 3ŸaëZG~¼(w[HORú\ûåÒ"jÅÀÄé]Ó¬ñ°vz]p*¡óv‘ó'5¦0<ìŸçü~w,
#&&‹ sKô,Î‹B–c#ó{>¿É&4¨¯K‹IXú.-1jÆÚ]!ïTeÌ¡Î)ğÜ³([ª‰T¢á°CVq0s,Ï?v—ãÃ›£vïP
X„T©NhØEËäN=k·zÂSæ{®õøK[š‹ğ$â¼–³1\šğd>¸ZvéÎ÷Wûpw 8Fáb}:ÿí¢—,8Diì R@x¸°€ê-b ÙÔMÎ}‘ŒMø~¼ù\†}~™²\z‘ÊËŠiÒ‘ #ã…ÚíiMÀD“æØÓgf¶üUÊã¡I‹ ˆjEÊQ /h…ÀY*şOsL'ˆ¡XÄı3[Ÿ!şX¹L’H[Û z(Ù[Î0š
ÎŠ`ÁÔÆTNvÆ5˜?¯?7Óş^ZÖWî¢;É®hò¨C£k/ïEE‘J¢Â"`Ï”÷9ù\¸81o:ïîTè0nXì[pÒ^ ÉıòI·c#°ôjó–'~‚M™¥æÿ>ÁÕ¼¨# ;‰:e›Ô²a¬Î/%i~«´6W^g¼~ìMMéø"¡…7Â€Ş×§çĞC¥i›XÑ5ÓÑœZÃâÙK™û6DîèI¾ıÉSj&:<µ	ˆ]P÷]
#‰_Ñì&œœalê£$OÁ¹iXœoã¿Ğ­Ó_q¾©{µ;ãÜ†ÎHøª æ;âL‡##L$ÓÎG‚„/RmŒ%E*w³×4›Õ¶"ŞæƒIÏ8ü(bîTJq+#9c;ÄLª+üö·6¤!JJ:òáhz)Vq8øˆiÌd;ŒS.äYRüßV“ïY è$µ‘G6weJö/	ôivüWw‚ÜˆBv³•Ê!¹‰Ík¹Ğ‹•@&´v›;Á´-tÑ6¥£¡KÒ„;ÒsiÛ¦lÑÉ*d:øR¦Z“¦yz›;xè°³Šw_Ş9{Ësô’éÑ¸sv‡Œ ©ˆÎãu SîœØ6	W7*¨©©Iÿ4Õ[cÉÄ~SBêÓÇu%ûÕ‚•f!ñ_1)-ÍÉcoGº#Ö@ gÜ(€çõøCC\pcQëI}ÕÖr"uÖ+ o³#Â†áÉiˆá$ç2lá­”R‘É®5Õ}˜ŒabğÓ½ó?*ö9ä”àÌÜFßW´³ôŸ³'O@ş«vø´vñ²tN‹ßT¼5ÈÎ¯qãmˆ±ê0ZÖ²\RÀÊcí½Ø)?ÍR—MXà£Ò!,½º7”êşÔhA":C
a¸F¬hûR^^c‰ÚL“nä%ş-}bF7£VLzºOTwªqw!¤×£a‡‚d‘^ä„W’oÆ­ù3âÚ³§ğb·5 ;k”üZ¹0ö,³b3VûáÂ6X§ı‰;AşµTÎ:çç&!¼©é İÚøû~G¶=ëçàÎZ?¯aÄğB;;}?¡m€ú‹¸;2wÕà^ëåIyNƒ¹İƒMxSœcúğ¯ám‹©ú×€‘)õ>‰"ùY  xıB9%î)úyiY«„¦à…åMqıá’Ò½4*Ñÿ]Ø~¿Lú^éÕ9—â¶c^ÌƒX,„÷ ‹]š<ÂËC³v12Nî›´UO.­GÊœˆ¼
GoÀÁŒõÆ‰”°W™½ÄÄ4Ï\g :ª6g/ìBVTò¿¶b1Ë£<l±À‡j)çte¯û©5Ææ-òóÍŸ³h™vÛ…í×ìÂFöÈê³Ú^ADÄØë½¸T Ë#V^y¼ÜÕ\äØ‚®Áze? ıv‡L$…§Æn—8?•¤\;¶h:_™ÁHñš‹Ú¥=Éa+ï’}ÒÇ±_ÿ1’¨ç¸Ş9	·®#Vô¶ÄòC‘„Ğ{x¦ZC÷|Šâ(ıùAŞ-K+QÅ°î,Ì×+İ¦‰ç˜â$D)‡ÿT/°¢^°Jøñ¨Ta'ó%@¿l¥Ëëk¡iç×kzM7Ò·cëå„¥‡¯p‹†k¸¨æ[ëÒ“îı§3¢XjZB\íEo1¹:ÑélZ­“²HC…zÀóNæ‡ ÄâÙt
[3m_*'!Å<k—¤g'ÏMËh-
E`§ño2?–Şò¸¨ßïv/$¨	BF`ÌªŞswvjSú °­½Œ„ã2+Ø*9hø¿ Úã}së·»ùa[ºaÀqñOĞg	V/®Ç{-,v ¬l¢{ïµ1eKJd¥–—Ø:D°É+Ã¥+åç7(!©ú_3KÅÌö7óeƒ¢é*Ês@÷(““JEé |İş´hˆ†¶kyq1?!I?³‰‹7í#†²”=Km$¶ 	
»á|ƒ½§}¹ÏÉ@%Õ›rºMıŒ|hœ*½Œ£ ÌRËìº>Ìš3[AK:Ë¦î$£ »Ñp¸Cn¿Ë–›èêè8€‘+‘±ƒ(ÛòÑy²ƒ÷³ÈdÃ¹ÔÅ–q˜¤ºĞó!ÄE
(ßFæçí]û–HF=âæz]Ò„m˜*Õ}â'ÃI
ü‘›ÉC“Cñ–¹Ø)öÍ“Ö2t®0ÿV‡;–~8Õ'MFü²6&æÖ·²?x º9£HÎ°õóˆºÑãi&ï!d)¯I‘¦ñL´¤3Ö¼{-0.ÇU4U%€=ÆåLNeß}Œ ,F©Ds—\dX“: 5€ëN‚[QÓ	¿ëñÊ“¯ñ0B
R ³´™ØlujIh¬˜¥‹Ÿ&ğ½~§(³42Y$v×D±1{:øz:&Ü’2s×ÂÏ½ù²İVØæøœ0ZO®÷'ƒ¶X3‡ÇK@{ZÕMÂ^yÅãf8P‚îN÷ĞîQ‹û—å~\‘xÊ·,ŞÃ®å÷Ø¹óÓàğê†z|_¹_È©´-5ìÓ,J~¸£ô·3pabw°(ŒDÙpƒ•’ä–•CsÚªúËotÓ˜nAG-àÕ:-ŠûAìÓÌ®/Ï;i·Ù€k+Úçİí"“#ølË„	y.pÄÂtô’É¾ÆÂwg#	!Œ»É7ÈnØ«ÁHÎÕéÉäYz«´¶±6Rú*¡¦W_‰qñÿYSß×W2FĞz®âMGÔ’?GèŠ‘bviG}f±r¼÷Gr½¾B!âº›4ò«•PÅç§ÈØ8ä<xdÒà·@	S¢Ó]±Z7)QWı$ÕßêåÈ¡è>YÌÏºâ-mg1ß|fy È}è„rvèóL-ı—¯xj^v±„yº·*;{PLşÜ ô¬FXh±ãÛHÏù[:¤Îï±şÙİŒœ‰÷gşöÈ—ÉúŒ¡¡\¶éSƒÁß3Æ3º¾™›Ş–£‹Q´N*!Jş’GŞrr§9Ü-€ÍÆjË.İŠ—
K0ø/â¼ÿU2Ä£ûr$0FYRYgò:õ¢ILãª	æÇv§¯_õEú¡“®‡r¡É¨	§üK°Y’¡–‘ó.>|ÂBuÓª{4øÛíˆùwşzª¨HÈélŒ4õ€nêH'“ng1.–44íŸë¸o¦t^7tÄI-L‚÷¡ò·;†–Næş¬„ŸÔn9õ3½j‚ÀSLäÈmæbÊ7âzÃW÷ŠüùƒÔd ¤·a7í6• İ…ûÄO­ë6HE0‡%°®Ïô»+"uûÆ7…îè*O<r5£@MØ:í Ñ®Zl…âÄ—AØñîêiõŒÒŒÿâ>«ÁÿÛØbß™ƒ·# PÕõg*+;	í†Mê2D•^kî-š('PªiûÇ¤B‚Ì^¯»sÇĞB|ê@¢	(¯üb„Cıyå4IÆÛŠ«Œ2ÂÛË[€À‘½ôvŞxÆ‡_ë 7—®ÁAÁ³‘?`ŸÁ'ød)—á"©É€AÎÿğ~ĞVŸ|Éù£HKúHÈ”„<ò»äV('Ï##g”$OÅíp¢áåÎUó±êP	:>ó®Ä$ÿ¿ÖCæø;K÷Á¢ÇAyLXsNÛv_»İøbnd¾PF,<×Kª½öRƒ’ewêrşß^D•°ÖF)Ç‹yœ®¬à21qO÷·:©œjœªÀ1¤MÈ˜P:İ|@±baØ—áN[®hZ™v^uVbÍbwİFök¦Bôã~$‘üÕEkèß:Õ±ÑğÇ›lòĞì2$}Û1óœZYêİ*V4-ıœÂ£„Ü.éa»“)Òÿ§9\øË|ƒEÎë»mÈ	I díªŠa†‘ümPšTÖ×‰=–A{×îšh¤ ı[2:6·}o”úK<šª8ò[ıh3a’xs¶yß¶¤ºÿŸÍÌ²é;Åá(à ‘õ¤kÄÇpN¦Ã­¨ã)Æ²VY›WåOè®÷[¡Wxğ:×‚Xg—šÎ“b(ß¹ÃºK·Ûò~’ŒÒH{¢h}-b”s ¿ô°°³"ŸÅ·ßü×9ÃªsÉ©Ïô"%,qÙÁñbyÍ¨>«‹7il'øhDìe??¢/şñ†Îÿ¼æŸÄß«·V0äûgş$021x8ıø×ˆ¶;ìa;ŠYíchÙPŞ´œ'K!xÌÅ".|÷bAm#[F†ú|Ù¥e€†·NˆF||ÔÔÿSÇçwŒÜgSZîmZË‰“†ªº ›±âßMÄ"™ÄöN†ø6?ã­AîbóËÁş¢«´÷’Ùh¬R1IFmÓy®rŒy~¿aÖîğY¡â‡Ø4«¹!ÄÕÃŒZÃë ª$÷”å£q÷©§ëCg Â?®GL_+”DşÛ‡ÒÛ2\@tkjo,ÉfÜäÂ)—è×ã° 7×%ú4®x„î(îÎı‡4¢ä<KcùÖIRf¬|Œíc7|‘Ï`‚û$Ûï¦CúÒÍÉš8J%k
ó×Ì²Wa]$Úl«»]ú	7{ç«©Ô½Ù—[l9E˜C1X	\ÉÏIêØ›¶‹hf6‰{iX°.‚¬kkøzÓ£Ç~	OÎûdà w1Á’/L¹µà	¦àM8ƒQ8ıA‚iÄ|w2”¦F)øö¦‡	&qØ—¾áX Ái¤ªº–i]_™Øu'ÄkR)xçºb'H…i¯Ÿ;˜¿ÔgQü‡n<½aK›^Zâ«‘ß×ÿÏùÊª0ílS&íÃ,Na„Ç=[XNwÓü£6o{üñOÀº(ÓßÉ$µ‘›öŞ)<‰Yf3IEF]LI÷f‚vRÂ^³	Ï³Ïëñö’´hó;Ïá@_ğª§í²-'°i÷ÛnSoŠW
A¯7¼‡ÇK‰ÉY¥ÀhyÅO`Ò[²o¤›Vw_´Ñ9Y"™?R¥à?*6"­•M¿pë¦	|OÔÉ_Â.æF§ÔIæuÔ…Æ» Ë0z€ìßrë€²ı9Aé¯2á+x+	©!ù›/Z–åßj6{Ãñl4­k³Ê%“ÑåŒÕŒÖ³{µüıO9ùaè”wêŠLHŸŒÇâ,XnÔë¸BÙ îB½_üúĞ6d\İ ÓZí×3Ä’`ì†zçı;'9ß…>œA{y»Byd¡h`×sK}b²³Æ›v)bå“•’¼e¸á¯‚hãyìM=_ÃÎlùy<c2Åcö? m[]ql¾$%âj%I@'-sl›2«ùÜbäê ĞXCiÙ,¡Ú5äˆ	*<<Ü™¿ËÇAıtı\3ÍÕ‡5G˜Jÿ|`„Œëj*Œ;X33mÎ†è”ê×0%>ëÇá/ÌbÇ+ç²(#C×¿$Ç}²“*E¦<[PÅß‰_jGe›-z‰˜…$ê]NÄNªìİ‹Ëªº7ÀÙ‰Ú›R"İsò k‰vÑ\bï"¢µ¶„ÁJ•HFç nÿİÃ5dw €ß˜M”™ñ”ƒ<ã)¾c»âèd¨Hæfà˜kº&üË„ÔH¸oY²5¾bráh¯òYaîifoRaä®®¸è(Â³®xÇÿwA¼U5Ù5ü”(™Ò %LwÜ\}A­Îab©Õp‚šo`è÷$c¦yÁÕ‚ê&ÄëP¤üİ5 5UVoŠûS\·¸GÑ-|-ÌÕ¥aT 
.¡Ï× ÛKÓãB¸q…I¡/$+PGpë¿±ëd
r”a£rkyÄ#Îq3ªín£èæC`Çk+P’Ïğ‡q8xÈ[^µoğF’%–ù›ŞPn—9[KØ—º¡ıíIGÃ¹Œİ•¦¯k"+«ó•Ë?L2Qlx¬Hë¹Ç'­¶[şï!__¹ú°´Í…—Ñ§_#¿1“d‚çXÑaf;Á“®üsÚL9m×D¦;K„¥¶mA¢lhzCnºwHÇÈësœŞ,İ2Ø×]…ÒPû;áA³˜i¶¨6xÚgEı+íæ~ë$K\9PV¬oÖàQ­mA»K·‘è†ç…%{nÒì`ŞÑ»`Mîz™®^wE!>Ú¾Äá83ı#p—G"‡é1À€:5?Mª—Šİ6EÁ4×SjüÛËÿH—`èÇÄsûšĞò,gæùõ—Æ±Š•DS¹j_øóÊv;%9/ı±ñDè9ËùÏm˜T*¦µˆHeê
"õÓşSC¯Ğ ®Û•æ1
ìŠ•åî
0ßç—_vH»©Ê?µt°É‹s#s¼l»ŸKØz‚
ıAR  ka«6×bönÑ|26«5§ì'nŸ/-ş6Q`îay“ ßrÀÅPs< ô*¦¹E7Y¹ßª,“T?bë:2òGÁ–Gêòõâ>å~Iæl öpWTëŸòÂPpG-Ôù>3e‘¤ô¨-;ñú½IKEê<^LùÖò'Z^¶íO p‹ÙŞv÷Òƒä\Ù£PÅÖƒki;³d³°W©ñTÛºÀ2Î§ òÜGÄˆğÁók¤±QrİE$¥»óÿ¨#úÔBµs|ãÔÊ¥F@}â7y¡3ÄÕÒæŞ¤µ¼ÌT;ìÕÖñi¿ÇÄ‹î?T¯î²µHx˜ã—I1ËØ€‹\&z{gš³øÜz@†v®¿·˜ÔniE–æˆ‚|õˆõo¤e¥uâ¢Fkı§-4¾%v\ÙÓ
ğd'{zÙ‘'Ì•±/¥ˆ¼w§e_Ä§r ˆÍŞE"«?½JfÀ»c„|Ş—*{¿ñD	94j= dIğb£¸iÑU}Cîí¼Ló9 Ğ«eè¯Ü½Îbb¤Æ÷G0u–ïYÀc‚h¥mûŒ³›^İ—Wå Ô¶š_¸Ú£Š<ı¼ƒ¡7YßPñ¥¦­š,R@Ñ¢®!­'‡¥‚^ÄdÑç\w½ùêÆE7¼Y^)šu»æG»¬‡ûÉ4 àİÏG¾Ù 4¸-öé»íbw‚‘Àú\’Ã+¦Ä[c;ËP;­İ¢G‚^	Ä«„H(¸–’†J«“Ö,£ldæGÈtôM”©sBhŠk¿?®ãÆÎĞ
š†İC‹ÑW£ÿº%§ş iH%ùü:``%C›mcì5Ö.]LÛzË-ìO~IôwTÒ‚¶ 7¡¤“3Q.öbÎZ‡r¯L¯Ç'?©ŞUqd9ŸÄgry°Å£Ci‚>ÁÈ4A
íøÉ ¶*p•á;9ø XĞÃë‡ºj×T«f\’ÏUu Ã£ÇE¢‚IîzHe²#|y4?xµ@.Xò:÷ÙğÉ¢pµT¼şµF ÌÁ^<Òä½&É"Ç°^›a·€& OtÿV.'Óâ½pO„ê»Úî
9U‘/p¯!e¬²³å«%$‰’jÜA¾c½Á/éÊsoo]ö™ŠùOÀùJd_ë~%Éû6½*_­‘P…y˜SL1Vy… ‹u*¦ y^EÛÖ$”v)?™¶>Â^­®é×ÁB} K~ÃX.Ÿ¿êÓÎB9=»m£&¾ŒªHp˜oÄ@&^§Pù*PN—7ŞÒ3‹iTiYA3Ë^i‘½f	×Ø˜-²w&k¸ÛY+ÊË£À¤©SÓäTÂaÿ}áuŸo#q•bÒ1VÛ…5,_ËÿÙƒrD/JDá€M¬i¥GsWCÎëf *­Äj—HÎÓ˜×·àÂ?ˆ`¸%ş0BÍm ?Pèã`üqRá—yÔÈE‰I2Ù´Gğ¯¾Ÿ‹Åç·ldjQõ‚=±U­áØ\p|}ìô—ˆN‰n@»uR‰8À
DIû¥¸
Õ“„^Í$½&aóO¸ˆÁ8v-İe«şÛC–é|dQ–"§\tsÚı·…­ãvö~v2Ç÷ª;77¬‹Ú)²LyÍ#VpIî×ïÀ$L¶!‰´I×ñµkê9‰IÜ¬n0\GIz”[ñV5!áªµK_K@³!ÓL¦LÀ³<_î9åÕ=
)Í¬÷0¾]—M¨ô*/ÿ	W|÷v2Æ„)•¦2¸†IpfºŠ°#Ÿƒ¸r¿[&³~ÿoL$Ì¹iLx—/Ğp‰ ß¡üj¥şùUt¤ÍRbC07x¶^øİ”:âq‹yÕ ˜®!,Ò;[$nùÉv® ên÷é|dÔ“);óGZgt¾”>mŸadı¬ÁH3‰Å]œl25Í~_R@£·Š¨—ßC£‡t;[9(¹ôÉ7|ÚÖFåk:{³ŸçP”áI¨ “ã3:3;®¦‹C\2ëèúW7·‚DÑõëÜ¢¬!5Æ^¸ÕR‹à6Åà~ãZ^æ.Héõí5¾vñQ%ÁKŠƒ%#^ØË=Øw»6Rk(‹ÓHVvâ¼ˆ oqvhR6(©Fÿ…ÀÉD„·Û¼bcáÏF¥)ĞcuQ¼,«!`çıSÜ¢Öb»‰yÕ™½Knxìsá¹\W.Ì İÍÿÅv	sÂ{ÕgÿYR9¾Ÿ`®Øµ?qÖ8ñ”êé°–„7ü}
¼wêcìJ«`²‹°0ë<ªÁcfd™ØmaBl«ÛÙĞ¼ƒ{dˆ§å” û!È[m’ØÁ•TK/P&xîåÿhbuš~FrTÌâç…éé,—ÊğÏÕÔj u|?¥è'Øà·üáÎc"k1¶7ñÁ†óÁ‚Î3£/‡9ìB4«Ø‚âAaO4Ëã˜¼ªPö&F2oØö’
y½&"Ã¾ŠXoÄßÜàè<Ã°u²´°à?ùft¨Ñ–35ĞiåIŞe——ü^p¤ùò&œË7ûöš:#W1è{Ë¯ğ=7ba¨şI£“TE¸í‹X³M{™È¤dfUË	‹y^s³ñÇŒ÷K{)¸®µåÀyûóæ{½şÊÍ79)îKÖ]ÅÕP-úÛz°G¶šKÛ¡üâ&Í˜$^b÷ùTáh¾€ëò<öo-Ö÷ˆ/®l³fCiI~{ŠÅâü&H¿İö‰´!ö3Ï¾C&÷jŠ<ßø›‹!5:æ¬D?ey	ºiÔ.·“„ÛşÎ–ÈÈ=ït5öŒ}ÿÎOÈá.,ğ®UÃ¦ÍQälŸGÆ)Éò´ëêËÁÖ;5Á€‹ø—?'Xõk£wDõø.tÇ*1êx7Ğ—º²uÍ#éÀ;673ûñÌÛüÜ;wiQË$HîC¬İof5Ÿøå\±"vC>—.>òİP¡2÷V»ÉÎæÂ$ÕÈn·)1ä4Öá1™(›¦ö›ÅZ@»ö¶MaŸ‡ĞCÌD“ŞÚ~½õO1ø‹Cß¡Lç!ş¯ÍíyìhùW­ÏæÍ(´Sy[rßØÛƒóDşø$Li¯ƒ_!@ËVwò (Ê2y­>ß:ñ–æÁ+¹ Ğ± *©fÊ-ØêhÑj‰ç?6•	=Ş[v'æÕOÍ˜¹Úû`§:ŒÃÊ)Nàlÿ¬kU¿Å|çÿkZáıÂÃñ3ßæsÃo€3›•_ãy8:t†’É·¶£¶ÌÒ“+g3guZŒé+Ç™Odƒ—OJ³¡š²	o„_íd«ÌÆ –T0¢í’Âº´ıpîJåËEpÊXva¦ĞKtú>©œ/ÇÉ"Õî}¹Ê2ŠÀœARøíCÛÙv={‹o&~˜¤@-(–X]ÆÃF0³vƒ²+ñAÕ
-âüWüùwıç}kEa!$ñ«…ŠB.³ˆ 1û>k	RfÆ¯æo¿™ı¥C,5…DêO 
0ïñ<4Åèqjı»Xİ:ê[ïï½Õ	ÄÀ<Ãg3œæ4gòeÅŒí­ö¦å­–´g	ùĞ¹,g/Üjî‰WB¿
<Ù¯9±òÿà w>%rŸôFXÆùøØÓ&	ğp‡9U>xÉq§R5]Íø¢ÁĞNï› ˆ)	|ÑÏ‚éô-ÓOk¥³²Œ¤ÕŒÇ#…íƒSz=W+ï.r]8¬Äw-$“8‘5Õ…jî«©“›¯iÈ¸2ãmVp#KahF;â’b
ÃÜŞPY½ÎU‹piÍá£zÑ&íNîvà:üC‡R…¯y‡¥)ç};Œ‹§{í’Öh8GDğ{×iÒÚºïo¿ßuëŸëâƒ†¤à1J\Hê9ş›LeşŠ¸u+NXt#	İÏ—¯lE×;’uè†N³+«¥ÃM.×gæfLóÓÙp¶Ùq/ÕêVFªm94?ŞTµ³``ât‹ƒ¼,ĞÌ‹»¼°PtQ¹‹Mh °¯7î²®ïë×g}nî«Å!ÆYÕái÷şá¡@ü£ï±×%%‰sÿDãÓŒÛ	¯æÔÓà4:şw;ğ¨ÚÕwL-9~g‘÷›ä’ZãŠÑJ“&#ø?¹²txY­‡“_’ùĞ‘öŠ.;$P0.HÓ-¿ÂµíÙŞÂÈ×éÖæ©C†F<}OæRauá@GÊÑxµ¥Ä&5®Ó1Ò³f{ö\œ‹:âÂ¬‡Yô{‡Ó˜°0¡—²Ë±aOY²°>‚©0ş ¸[i*p!aË’µxO2ÿjÈU¢à±çî·6PğAa-R¤bv¡ÅÍT__÷İYØşIŒ¾á×õDïX|,Bã}ªßúğT4Òùò³İlx*C³9xŞğÎbTş|kÍ›Õ:´‡ïıVœpâ‚£FtT>§<'‰qb¾œ^ù/AH[(»Fı ¡îLÎrñ“¸®’İYh`§É0OeÃBÕ2S½KweÔşî<Y8Ñ[¾@ÃÓÁ‹ÿ­2yÀ/ûA6ÔÂS	“¶ö/÷×¤u¨½bÚÿpp¿TGù<œB¤$#ú]€f¥ù¼”¸g‡55Š6§ZÖÆ“¤|ë–V¼ÏŠNÕÙC]ÕF—Ö±ò9U®ÄÆáT§¼)Ÿb‡Ğ=Ka++`{Ô¤Ú÷¼Øq\„2š^bRò–àj‰x‰_#'G÷Wm²•S~îôtM8t"†¾du¶_¯ód\RE¡—	Î”ì´U=ÁÌpİŞã—1ÿÇE›\åÚ@íëH–·‹½å¯¹itt$ô™—BŠßıÒ«P¨e†­)˜Üm¹8§'l£2­ÜÎpgáyÂÅ±×çÛDoäÅ¼°#¾ìÓ°$«®“â{–"ù–‹‘I	M7–a×½Ş°„ˆ¹ŸFÜ7İáÀnK×Øß¬íK¦bûÚŒ#B‰ã‚`Îùì22 ‚eÔCë{>+fNºÃŒÖ´s˜…} AiP¢ëTùåÉÿS“GGH(mÔş{sCamoQS‹b<‡àÍíëcL‰¿FP{š9îE!³VµÉ}ŠW¦XsäÃ8ĞgQk–4o37€Y¤Öå>Ÿ6[[9OhiFõ.¨ÙœÌ%!ÄÄNÎ¨ºF‡s4×dœ÷•q1YíyT_Í‰Àºië¡96½7½Y¬4B‰£Ú5çUeşNn¾\ÁõÜı#é¸	Gç¸;;ÏáÍ¶Ä^[#¶:™áu%{w¤PÔ<®=.’m9ğ`ËÆ2ltë¢•!KMDã±osåÉ@B+jXùNaf4NÈDŞá7íoÎã³wğ:ö,~Wğ4c®yB°[Ä»Á©/Ú‘´3±$³¥øŸËœ¯©Ø_‘¬Ëúæ­}rĞÃRI\‰+hÖÅo6ùÂ¾!¨jÚ20uM&	l¼ ¶aiR3âÔŠìb\Í3Iê:ã2àÉŒliÛGì­:ªı´Tf5eß|»Â+µhFm€Á­Ñ­`ÖJÂéèóâ([Q
Pë*üˆåê¾[U>Y[âpö3Ë@ÜĞ º÷Tußóõ9<lì£./Öóna½1Q¨{×L·¯­ŸE> áŸ¸=^™V&ñĞ¡‹~Í¢ú6²«'9„";¸º[B|/x.-%²Ár_û<-?ˆ˜€à·ğŸÂÌÙ·c¾µ¬×ŸM>[E`¨£`Ï“ú‰Ú¢4·öŠ«ÜÕ%kzG2c°ür“X¡ëØ•5“øÊ}OÙüºE¿üLX`ùÒ…¼¯›:HúñÅ…i®¨AO^uMdEÀ(ê®£ûqB0>.´„*ËÙ»QùF•Èn)Ğ*aõ6ìØ¿ST9MI9ÜMš”Û‹rkG$ÙWË PŠ™.>ûGzQùìLWq	„¸púëaµ»èÁ›}n}F™ø†‚rpšÅîoÅÑ<^ûğˆTNhÈËñœ.OÈgT<­_1F¯`…n5îÇDı#»ÜlÙ÷ãy*|“#¦e“ VÍeRA¥ŸÛâ|£Z¡å–œÅx££½ëà-¼x¦ÈÜÌÁÆ[q£;úXBàü•îŒÉÙËF(Ç_<ØN.‘eº¼<YçÙÜ¢ä¯Hİ W*JQr,Ù‚—µ%Ì£âÄôØëkÊÖn@µFèr€GßÙo[™™ª.Q¦MĞÂˆj­KFs|ë¨À(Ëéğ½ÁV+,^™=zKÂ¬œb.m:Êà+äV‹UQ¹à52F@P}²ğ‰®æwıYè4Òi‰µÖ#@lşpÙà0Šs8©£ıA‹ÉÃZ”fL
¾i®ÖOµhÕn(Á'_E*‘•ôKV¾0=´¼i>!qv|­=Cæ¢¦ë*Æµ]äò_”­
ñE{æó±¢¶+È¼´_{øq^Tè1ïM7¯Kã¸&ã+{×ô>üèœŠWåIÕ42–”¼à½fY°;vÄÃ†ğÀíÙPÓ½“İÄÛqa¿¤ª<¢š
æ(µ?”'|>’C±Öã»	¨³÷ã¸¹ôÑ:¤›¢èB‹ØéÉ–è¹.ÂãFÖ ->d»)Dwdl]uï©DÜÎìMàUÁL°^óL­)µÃtÚÃÁÙ4…$–)ÿ˜ÙÃ`wó ;¦?12ûè€&TZv0n†y~
>sú[~YT¦(·ä ªş¥†ÿ!ŞŒ¼…jÖ§TL‚ÈúÓ¯oÙ˜g9IUöÁÔ-ñ7\ “KÀ’%Ãşuç•²A+Ê@A}££g`÷ÿóªxµ,˜…S)†#„?}—i@k‘‹0V$;@‰–a½¾ó“DrV8ø¨°eóƒQwÏG™¤˜ŸB|t*u%¤4eÅ©‹Ÿw%’å|İO0[ğ4•5p™Šwq¯uà,´y²¬©cÄë¥[-3½‡"9'O¢sÀ’&¿+¶Ğ¯hmúÑ)?@[i–¥ˆRı©¾mWçÖ1ô­ŠC%À@~X±ÜR”îEªÖwÙ;æ..3µ¬+¼¾\²ä‚Ğ8Óm1šV‚ÿ!ƒ¢ª;ˆ9+_úFJœFö¡¾»•)WuÊ9ÆcğŸÉ$?ºòŞUï‘~Àş¼×u…î9¡û-+Âè£.jÛ.Öœ§löå{¬Á*ğfdpûò9û JQ_f…±I_ÃP¬£—Rd‘ü\é[päh(,‰ğc³Öa£m£øgnZNLëµ&2A·ø£¡{søP`Ğ³sÜOz,b»Œf‚¡š‹#j²hsy1nğçÈÙ|=Af¨M»#íˆò±É&m.g‚zÈÿ"ñLªÜN–½wÆBÒ’ÕkÈ?Bx³í[ãq;¼õÑ˜mIÓÉ‰£ï•™ö±c~¯m†*Ä¯¿ârõ+BøpŠuĞMÙ•&ñxËì¯âH:ş:_Ùš('¾JC{şh|G¼3eÄœ¦roÂˆ_£ÿ+Ï¾¯;sÊ%î®ù	µÿK·õGz­Ôì×|Â(á¾Ô=ç‘Lİ·îß^ßfC
4brÄWã`ãc¾åx›ÀÆğÇÀXş.ëQàøÎø5Œä’X¨gğ:3òdÔÅ²Ô2(MiÊ;h×fGŞÎPÿG'iuäÿHê&„ßAÑ rÛšIÃÃ‚øÓ˜Û®ÄO¦%l«¬#@S½Zmå{FM‚Xr©IĞÚ»ÊÉø±ñß"‰;EÙ&3ì-Äb­¾´2;HòQîŞ®’¬ÜuäFGc³×?Ü	3sQHŠ*¨ü•n°q;F9¾rÍ6­+ì\0áÿ÷!B—å(B9ùÇ¥¾-Óî¸«÷×rK2S‰œ#_—‰Tà0&Ş¼Â•ø÷…½V¬`°v1ÁĞ!1dÀw«;f:ËdÉwôb´·M¨şÉà¶ıÉ	¬6\Üô‰V¥›@>iÒ¶šQY/YÊÔï½S_FØ14³à)¼¤dô¿àpöíjãÉÈdoKªÂÖê×s-„Àù·k™CÆ›é}ØÆXïNw¥%»‡M·r._ÂÃ„r+ËM£Cp •o‘:e#-AÏs¿Dwî¯Š€R`Ù3¾“³CñEîT~%Lÿ‘y
xxì¨¶YHXkÁ×ŸPz¾©l~œõS é†´ûğê~ıÍZOS9\ï¥ë×ş9h‰#bj…Š·ıwF$™î]5Å£p·İfŒ>…×f"ã¨÷Y©œ‡ÁÛúpËKÁ,sqL¿/Ü¾	©- Ê0ÙòØ'´À–}‘äõÃ9xùZ¹pĞÌ²ìÉVõE!cô:jÿçÖ|æøW„Ô¶º3Í`İZŠ'¹%OÜ‡Á	¢ï‡/÷†Ø“RÒÒ!1gß¢^îh›UGrõçw¶ş®A­Dº$FÑŒ¯!Ç^æô =´˜Vü¢cŞ—2N¿JDùN5È¿á‚î>+éÉX‚‰®5è¿k âMs[5ÁğÊgôÒ±2xÌ¯H¹¾±N$ÓWå9¢3„*± üıkQ'Rò‘Y'o8ÃtÌ&Æ·¾D4=%©^‹‹­ì>j)ã¡?ÂÊ["+Ôjzƒ„Måÿ´³_ÂÉæ×Cc»õ°‡ÂŞİµwøÈK$xHcK‡'…É’Ç2N¥œ•&Š}ßGæ¾ôÍ´ª´ğãnõ×+—>ÿ8& Åè)pa4Iƒ8[b?’&øóË@ĞFìÍÑA`‡¹Ñ˜t0R[=ßHJæ­¤_WuÏbyîS¶>Î [ ı¢¯«
ËœÍnÂı¿Z!‡ô ©Dbn7‡Ÿ`nÜ\\Òã“ˆ{ŸŸ@¾ı˜—5’ÇÉó—–W¸oôèM*vfØ€q¼Ş‰ãÊÔFPä ÙÅ*“¬“{B ÿj€	UxjßfÚ^ZåîV|†+mİ1Í¦2Áš,ÖV]qæİ´ãDW½eV©ÄJ!ù~<+wà>ÒâHğò­ğ?±oü<ïÛç¬•Î‘·(váeå¹¢ƒgºtõİ®ïWšÄ½hß1(kd—ohàııeFõS£½8%„	ZÀ ^Œ²HO ¯cT:£w{ó‰kò»pÚlHwMû¡MUûBUxË‚İT‰Óªuâ}õ ÂWgi9KÑÈhëî&ôÂQXş¹™ŞW’DpÎØˆÂÌè—=V†&ÙKu1'Ÿë*>8q ˆ8½ïÆppoÚ­ĞJğW+­WÌò·l½e¸) „±W‘Mâğj¯´:gU^1H4Ø«œü‘Æ=RpSé¾X‚Õ¹§¶+É_w5gç7øÏ¬Å?ú¶0µáu äMš*{NOüwµj¡©h2›é=«²Ÿ:÷D{¶6öĞ”ÃR7²Üµšu‡cÖà.îNÉ-²ßò‹ìš‹×UÌ &  'p¦‚Éùõ/šF…s´Z3‹×~wu((ˆÏsŠÅ:=šHpJIÒóu¬I†6Ğµ\Ù?ƒàõnüi"5pD¶‰ã™°Nœğ!„ñZ´R›ò£Ÿ8ŒŒd‰…G®æn%	ıSÊ 0'lì+¿Ğö¢7t†´>^æ“t,–¢<àÈ}À‡7{SÒ†d ®Ï£WGÛOÃáÿ—ğÉ@<­¤*«[Çv=__f=õX]w ©ïİí\w`,"Èf¢/§ñ+8y½»¶HsCK/ÀNyÚØÕó=™]›’f– væ°®ƒlHØZÙ³2êòşëı»›:.úH`g×	K[˜ÊÉòş„Ç:nŞ-÷Û¹e6 ùërİÚJÃ6ÀŞ°ãı˜Åi¬ÀàÓ}æ¨Ö¶ÂƒwôÃ]ÊWØ\vĞc¶nëS™BİêÀë´PÓ×ú¤ÕR@QqE½'W¶*G®yŞ¢ş¯€‡&Ş”dd¢…Ü–¦Œ†ü¶û ¡;Õ‰«n©·ÄY‡“xLÒmtknĞÀ©k·³“	zóFôbœNa^$Ú¯10HÀºxMæÕ{÷Úu—H¾3iµiï)’{Ôà„€ 7|hCW·¶Ãı®òÁ~'ï3ë¯Pv¼ê‰±ğdAg3$ŠC¥Ey?’±ªd×p8ƒû¨WşÌ È^}´dú™Èà$+¤™ü§­y9’!öş,+½ø%)z[ˆ²ÈJ^…<îyaRÚ®¶Å Ë?ËÌ ôH (‡ot‹ö¥5]|–ÆåzPƒ´\¢r™àõ`„øº{:©şò…‘lx»ë“¯˜
­İ¢ÓFV´°•1•Š11ãíŒé¢XÇ0æå¦=L25¡ÓölxÉro/œÙÃeÀì—ÆÊ¾“wåÃ—“piSğ%@¸l?×	¥ò¨·4…(Â3š€îÒÂÊ`Âµg„e$—4Œ³?ıÌY?èmQ8¿ØvËIæ¨TUó’·áÈñ7[|o‘{ˆ0)Œñ¾,1·ŞëÓ)õ?½«{Ùİ!ãÑ©?o@€ÒÉ`~¿aB€¶ÚŠ	ûƒô·ˆ¦k šT·ĞLš¡ Ÿ¡}Ø«hì¤ Ût\y8Œ¾•wı.Ó‹égéÒ(&nLq$«AŸçTu:'w;÷Ñ©”š’ÌÇ÷û@}²Z+Q¶£ñ+FY/kOmÏ ¢d…˜ä0Åfq’wípx‹*8	E/Q!æGœ<n
k1Ğ¸+¶RÍ˜â¾Şaê½rç|`m`t`!„Øo«ËKÑ$;&"»óB¤#Áè‚QÓû¢(lKå­ÊÌ˜õÈÉRQ¨“ìßé!°vÓA¥ .ÓïãL ô7\ªECd¬1‰Ü}=L.¸ÉªO–u»®©…×o!ûlª,ú
\–mÑHa„´s©{óXq8Î`šjª'}¯rô¿*
VÏâö¥‹¿¯Õç4’;$Ó‡;AB·Ng1ÖØ(üÇå›‡	±Óîmfw:ªvº@İ5÷åÇù	ÎHò‡-ëÌ+ØÓÉ «K:‘Q¦ã)©-4ÍiºunÃm“jå"#—¬·xW¬®#¢Òº¸¯ëXÖ-óù‡i\ys‰bb”·Eâj-nŠbKü„S°ŠÒ©š?b»ìØuÜlAlİ:
ÍG9nÓ”íZ"m•?Óƒ¯é%ÒIŞ”bxGç§IÙÃİØÄ^ÉìÚ#gRÓ¾KUfp	Eƒ$·øa|ôÁ[I"ú¢ßM	gÂ‡4hÁŒÿÑØ'!:ÑHù:aÃó0Ş\7¿ºAÉú^u‘3Š‚üª1Í¥R(©
æ_cQàI·ÈœCÊ¢À]}¦œæıÊ¢R:¦i¥D%Á/Òn¸3¿æ$İ8|~ØÉÎ‚e*(~“àu¢“TŠ=÷æè²?–·S+çr6dÄ ı†3oåt„»>î b™§ˆ¯o1ÙŞÑ	­7$ê
Pë¿¡í/F„¼ÄŞhš û· #¤Dè¾a1%Ğ™iàb:¯7%âÛJ á-uïÆZ:é„ â®L×¦ğ°ÛşÜ?ÌüWŠT·ë³KB-h(ò²¼JºŠĞ
tä×JámÉ„ñ…QqVŒ ?P
3 œ#ÿ‘ÕO‡Én\|ƒ7ïuøä¦ßUò
'Nµ×bî²®Ÿ×»’°k,¯Ñ$Æ¸Ô±hnØ»Nƒ]E™ğ|l›íäW.(9¦¿¶øK·j/lØ-+ÈfUb^mbè
SêY¸›–˜¡64wmV¤ØèÎ
†©BuC™õq|ÔÍ†£õæXX¬,”`ú·èòósÒŠİË¡[¨“b851ƒå]üÍ9M2¤ îj¤Ã…ñ+RU‹‚ôm ˆú±¢ìo&éö©j<"Ã7Tm
P¡®”E.É²ˆˆaÚ‡ú2·ÇnoŞ(¨"Şš?ÈKQYÆiÑK(é$ ^œeíY‡W]S6ö×áÅ‰ë|ıŞ"zÆÂŸPöÛ%;WßÆ£Ê“ÔMê³gÇ`T²M;	íëL®TñMÍV¢+-,$„„ST¨İÓdâLG¥Òâîü ò* „¯=êŞ`—sãÓcˆ¾ÏTÑŞTù?ï|HO÷ø¸àÈâ®ği¤YäŞ¹¯„ºQÕRI½ã¬.9ª»Oaí?|§X¢ú—(ZÅ\óÿUÀ{ ^¾D°»Ö>§8Ÿ0X¨Ò+ÄXˆ*§hÌØäìEŠk	>ª˜ÚFüÓàÚ¡¨u‰»­.KNç¶ŒQÕ©¯1
ñFHZg‰_ˆÁr!s#¢¸Šˆ"¢¾ÀeôWçd¬˜68aßø8‚Oú¯€–ià´ß‚ÇŠM7bğ÷]à½‰ÓéN*=‹“{§]f·÷z'2>>ñ¿_¨Şb×FFàd¯×Çş*àu¶¡%æÌµ*Õ[o7£pÃĞ£-”u/Õó­Ş6YÇ]Ä†c†y^ÄEëİÎ®™ó{tÑî1,fA•~èâ[H³šïzÓ\P.M|X ¬{!iFõí"BqlLH¹aböŸ•IÏtwÅ¡{êšz}f° eí8Êõ[ë—>b`¥ü’×3©ÂôõšÆ-©£hwÚ•VËîæŞn¸Õ\¡0ê}s†0 [¦”€Ò#¹*j PFÑPçÎßôå,g=G“É”Äæ”quKòBå:´|†ùCC”dædŸ…Ìåô6ï[|Â&Ü|vÆ×,FFÎ”ñ÷
pµ°«ˆ!•u{„2ŸèBÓ¡œ·H€pT40de0ºÙK‚ìñ;1ÀÂî±†Œ¸ÁçÅaçí{Ã(yK0<%áòçSş]èØÁ7t:Ì*¿áx ÓGS2’3ÛBÕ×—ò8l1Ô.œ~«ª„ù;¨Q`JGH<4o@Õø»ÍŞ÷Y9¡ƒJ#­@)Åà÷0ë5»kd^¦ÁtĞ·÷´³7¥À:.Ä˜Î¹é”X?ÍÎ ¡áÉÖTÇßlp`¶´Êí—‚?İ{ÉÜÉzµ†@&ML[L—^qÏîÖ-ôûÎÿ×ƒ]*}–ÉUMHîœ‹2~¨š+~Ú v`0íCeV?a`> †8“º5m˜ Ÿ¼³¯ŸN‹$&ßAÕ–|cúyè   ½MÉ4Š‡d ‚¥€ğ…I¼Œ±Ägû    YZ