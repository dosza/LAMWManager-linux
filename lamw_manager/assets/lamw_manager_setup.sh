#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="694619747"
MD5="8b32dcfd9a89854d5c7e50d7d2cfdfe5"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26044"
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
	echo Date of packaging: Mon Feb  7 05:39:13 -03 2022
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
ı7zXZ  æÖ´F !   ÏXÌâÿe{] ¼}•À1Dd]‡Á›PætİDùáyñôÖÍ4S.Ñ0¤m]Y€¬Í&cŸqõ Ø¦UGIà*Ô}×»ÑÊz3‰€ş"};å¶íQë­ç•@qÙc	¼Ë	;6Êé‘hZŠ'¦x2>Ày=ÛÕ‘¹l,Ëº:l–ş5‚ÿÜ~Ø®töR¼ÒL†ŸsesòL<İQ¦(É2µ%Ÿp~ªúQ~¢Ê¨Éb8Sé@zE5õ1?¶½4QÒèÃà%|?µQ…eèP‰í…?½ÿì/İ3´1 Â7} #zÂÇ‰ñÆöÖlJ(l>µùØ‘°'ïÕó.,¬µY;mAkÇ«1“VûÌ˜…ºı¶Ççá¥ƒ?vûWéVUÓzœ\2"Q–ğ$2KY{¾i¸*ÏÃqq @ïzN(˜Şÿ¸À“¿Ë˜ÿ1©Çàå²ê¡ñ¤5Ã©n&]È€°>=ÄÏ{¯/~ñr'’Tç~Ëa§_L•‹cÒ_ëb.À_Ğ^…aˆÒ_uC—Ïõ½Ôó‡‰w{oDs‰i~¯I…Ü7ŒÚ¶5d×Ã¤g[ˆ“ığ=›\øÄB’i ñ Sÿ.Š|ÛTÏŞÇ"#ÿÃ(#K.öPMÎååušºdŸè2¯JÍºËeás½Å0Âæa %%.]ì+ n2	vb@×CCtST‰Wê9ô¥d;ª\<üej’4F}(èÔ»ì¹æ^X#ª%XAà>y×ª‘FGx€h3îò;†o"¾d–Øsk
í!«‰”Ú3ÑµŠuŒÜ€Ôr®¥¡¿€Ûìd¾ñ\â„ì¡*iÓÎÜMCø÷¯ù‚Gîy–HP7õAöXQÃÏ¨<ğ#«-.-š]>ó¢¿˜ŞrT¤–u$Ei½”hæ‰YÛÜaösa©›)ÀFrZÍ¥A’·Üz‰†|ä8øò±Ê[-•çª:$+<çâGÁ€Òß³M´Wå<Ö´<J¥Û
œ´…Ö¶fªJ,zUM6˜$ádMÊ˜Ôk(]w’O’õ®HØ:í	š‹¬²Äìİ“’‡²>¼˜N²ï@	öÁ„\áµ{D™”ÂıSÿÆ÷_éc”¸@Í@œÒ»ÇQ¬×–“wóçjöy6ôı4Y¦¹²`
Y·Ôû½Y—\Å³è)F¥]<0àXö†Ê©ûF;ş6š9”×‚Ê)\ó¯ÜX¤±C+†9=Šú %ÈâzğI6ƒä‹Á-»Rˆ#Õ­ïµqñµ^ş¿ŠøsÄŞ?8XEÛÈä#Õ1#¸_¶4´8Ã+£ğŞåÖÊ´uÀ¬  œ  /´±µ…•¤w×*´`W°Õº×C‰w¥^¢_ìiNn\Ë£ÒÁVöª}bó“1T¥¤’İ<Çá¤o×q'mˆŞ£6@gøçÒÙ{6¡NUT…6˜Ï”ŸãûÅíÚùk1ÕrèÊEŒ¶-ÄNï,É>ø˜ŞXÇ%z–FšÖ‘6|ÎrÀÍ P¼< ‹º.h°?ñ‡>Ü§~ªß~`M»ÄW€9vÇ$Ò¯…Á?e;	¾!,¶3êY¥U"qX'åz·äÓ‡BÍ¶üÃ )q•¤sÁ(†d>ê÷;hrà
DeEİš£—?¿rjjÿ¯ÚLOA§Mó„²Úw…;£z=ß©Á(~şFıè×­­İŞ‡©<û¥å.˜‹z‚æ‰‹7×¨M¼Ôò›°r
»=.I'Bp´å<êáSğô	<pZ¶˜iæÆTm`Ø||†µ½W:•ÁÄÖÒúæ¹ÇÃV9Ö¶&t×a’»áÆ¦ÑN'½Òğºfj‚\_\4Ëçxó*àüDLS6’¡úÈø+®ÉX~˜àäc²IÃxBµ|ï,ô~²D­F„û€ğzjÕvßR¾b-‘=dÔ’¦	>nŸF7h™ªKŒ‹C
?OÜsA@Ô+eŸ-©Qï Z7IõPØYxÜœØ+ƒŞØ¯E@‘Ó[ô–ÓVNX>W6ğP¨ó^rËğ„ˆöZÎß˜İHr{ìß]^·i‚sÿµYBœ?|§h{­’•1àeÑ#\zÏoNÒæÕ™@rPšj•¦Š´‰İ-‚‰”ş­Pnè~ÀÁgNø|›uKR5S+]¼ìüĞ¯W¬‰˜s2Í+®œÀî_+{smê—O}{ZyD`K¶ÏŠ}j ü‹•zñWXô—é}8‘•ÓtõŞR]¶ÕŸì	è'ÅpÎ³/ƒ İüğfçÍsRƒı¤~MÆø¡làˆe»×«*…ÆJÜƒ;şáLÓOf›p¡	Úm[pàŸr~Äêª&Ôw´'!UZ_ùª0W5…`v<V¸êêJ|k¨Œô›JI"æ.ãÛ4]æbÉKe·(5[æ.ªÜu4.m€Òâ² ö
Ï:–$q’
©ÀeHĞÛ]×Ø†5ÉD¨+¾îá·ŠZ|>U¼’Û{—2V«íû«æã„l—Ãõ Çïˆ×û
¸+å‹aŞ)¬ÙË+dÁñÈc)â ı±(:ÏÖƒÚc‚©c¯Ün§wtDÇÅçÕºFŠÀIK˜â"Ï¸X~ú°f‰ÃÜYJä°Jk^ÄÆ#Lh9Ûa
ÔÇ×WqWRRË<“zÁá6®HO6‹9”Üúş!Á2¢
ŒÑn#›/eY$9Õ	8‰Ò„Ùë’"Ó 0ÇCå¹Î¸ÀKì¡ê–¹ãî²AƒŞ±®sgÛ0J6<ø){›®çã7´vœÙ ’„É!¾èµsOÌòÍ»&ùz1Ú®õòRH×âÿ’ş/+¸zËÈ`#–	q9SvI“Ó@af| òˆ+®8¬·¸Bmd¶I|„TËÎ²¡CwaœÏß²ÚXÁçB¸7ÚÌFP©3ªŞ#IÄ:Ø±-pdÒÿ¿^¥ì&|¼/\>&GøP~*Ğ!ÛªWœ;Ap==E.‰@MC}P`c`Œ¢i%ÉÁ?E`kl¼\
‹/Ëˆ»cpïGe­õè€$±;l`è±kA«ŒùóK:VÇ…[ç]ùA
Şu>^¡µe1W÷›áÜKüfc]l¿ÙZqù;rËny&$®×wRl»ÊW”¹%ZùN"ûš†p‰‹2 ¶å4`n¤`J¦N·õ‹‘OFô–e‚Ÿšü¶Ï€úÄ‹§K¬-ù›˜Êí%‰SÉ_n=&{œº£æ
y,Ws!:k”‘w?DÅ°±GH'ö}ò\Ès$cçx'»°‡P½7Óë'§#mïæF©å
ZHR°ÜB¥©ºš}i4X·Eb¹Jgµˆ‰«b*%e¸c‚§ÜûGj-ÅÕ7€ŒÇç—‚:Õ3GdX@î-=F"åF;Z*2“ÛB;›¾?ÿo…0²QÛãÚŒgÛ“@YyÌ‰öšá*Sª	Ñ;İ÷ãŒRû-To£ú4)ŞF½ş¥GwïĞ¼cÌ§>qóÃJs´‚`AørmşÁ†çEL;ßB¾E­š šé“³ÖdõãÂKÛûÈM#±›‰qÁ\dÉ¢Íz©ÒÒ_ÂŸìNĞ2ûÕ²äA« .å ®Áéa 2:ÏV£Qªs—5¶Î/k9¡çLø	É¥ûu2Èãß7ÃÍ¹¯„É²lŞ-Ÿ—VI«xqº˜:­LÉ¿oK,›áür)èĞÿÈ+éÊZ›¿DÎ†½\qÖ¾-›¤ç¿û|ŒÄ„ hŒßm4Ó^ßC®ôÈHYöMÁ—«—)ùò¯Et@äŞ«Jİ³¨‹ã2ÛÒ‹ÊADâZurP-Ô¶VF<Å	@İˆ´t! Ÿ„nM·²ö%´ï‡ÖÎú à+•ÛJæÕy¢7„`×P´_Á¶&Õ…Pˆ~Ó%†;&.ŸS^÷Y”Ø]O~®ã mğZ¹m5q7EE‚FüÜ‡ª3ºw×õÍ;²Iú'Éj óª¿™
ùà°ñŠÛ¼vJ?OÆV~tg¯¶úÉÎÁvt×"€æ-E“Í«ò¨´òØèŠf¸­S¤Šª¨fík¦Àe6`_1*nßlwœ|<~ß‰N÷Gïïú¦@!±ùh831A¦Y£?”ŸŒäˆåñkyï÷=´áB×L³nÍç8ü‘C·êœDŠ÷ïAÖ†¼ëE›oû¦¼¸8Ğ\Ã‚C¶|<4.¿wÔ“çyìÒwÕ74Pêo$rm4ÓÅ@b¬è—h¥Æ½³Æ¯¯|ÄTÂÜè5ç òhU‡×Ÿ_Ö9xC«®…,ÿ‘Fy_@÷jjÚ`òzrBğæ=ì‡|ÈâÏ"Ÿzo”RÉz~‡@çıJSü”‡o¹Ôœ)ÿdĞe@°ĞãŸâ±¤û¼º…±å`vß‰Ç›a—õoı¶j¢›ÓÚö=W=kK\h?´Óœ
¶‰€yÚ/ãïãœ)ÍÓ‰£ú%µYÚ½0Zåç¼AI8!Èÿ‡ Ÿ@İóœ´ÖìhÌ*™×æ~r4â”Ä*öšó¼ìGêZŒ;4\¦¢0y©EÍ!ú–]‘çŞÄAşâyö;À7-ÚŞpl¡Ùç3`‹¤:l‰ö¿!Âb1¾ °%ğ y’Ú7ĞÆPó›#Äš#NÀ7}¥giÁ¾Ã0s‹ß‘|g»=1Åò™ªí…›úû$¼êÔ!ihâ·¹ky³¾zˆ&ŸÜÒbœ˜„wÂ’Uôh€ƒ5
\»6i‡ÇÅäµØ1û¦;DÒ»Ô¢"ß-³§9‹j»<-Œ3oB¹c”%™Â›	`Ø³’¬jŒ¾ôX¸¾}éIWfyÅ| ‰ ä/7!Ù—W$^Ï?7L$šüöû1/“›V•ìf;†âÎ=4–ívÛxeÔ º¨ÚÌ$'> Ì1¥KÏ6BÚ	=£š ¢ŸÂçm,âÙÅ–ˆ+&ÓÂŠŸ(
ÖÖ~-¿sÊ,W_ôgFc%ÓköÃî·%;ˆœ²İ	Lj†?MK¸”…fù§RIgô™\LÊêCwpkú´a¶è|ŸÑ3m‹b
eHG¼4-z†Ó‚O˜œ.W1Yh‘Şè´g´d¦.m‹Oy¸¶NŸ›f!&Ø*³KCÀ©åó0zâï"%pY©B®8*€y¥ÚO}ß¶é£—v€­"ù¸ˆ¦ÚZ)—áòÆ¯TƒÓÍk.¶zU ^g‹P–°­¡pK÷>bák‰Š‚Î8P-µĞ–Vf¥åU%'ğ*ÚúZU6øón¥×ÈB&%‹%™ÿ'úƒ®hk²``Ä¦Ë‹»?)<¥4—Ì‹Îã€,êç˜XéÎ}ÛD¡§ø¸şCË¨šÕz„lO =hú^ß?«:a¥Ù¬šJ¸ëêiËœà©5¬8|SĞeä@Ÿ[şÙaN‹Ê?…Åän rlÙ½vï‰ÿ«ñ€§L½	3+Üx^=ö à~KºúÅ‰Û™(ÏN‹­Ô*ƒñå·¦ø¤°Œo‘xĞOO„ìz.2¼—wVsİ"¥IGÓÎ†¤Ğøv	=ë•çOÏ‚­¾ÈT€=bÈk0o¶[•ê¹zT}I²UóÂ»ZµUu+¯·;Š°ÜV¹FT ›«ÈqR’Âpõ½!úÜ4Ô­X'’´*†‹´ˆâ5{Ç…Â-ÙS˜¼*@1ß8+Ëáœfƒ´ÇÄ³ªwOİ7U0ûsH/š-y£DB<úUW	NĞjiåBq»YË°-°x:×‹3ÅÊb%Ğ_"O‘]ß™½ò=İŞ£\%”ãH‡Ò{óÎ˜5„ˆØ7t$ôBóìÏ[œÉ%6B©ã2¶<à#Tâg]ŠëN®õ‘ò¬¹Çø]¸H‡çT ÓoòkşĞ›‰M·º”}û;æ-ånŠİìZ]âãa%ù1Æş¼Øñ^—-­/É$ E9"ğç}j¾ÕÌ‹Fœ4•x] ä@‘±@ks#–.ÎéÜ%ÇNAµ‚º(€0û’¿ë­Tå\Š£ú	‹Ş<Ù°	
Me…ª<rî#¦Å/˜d/ÏC@ğTêcŠú˜ÍÇÂaã,ÈµL<üé‰Ì€á8H‘Ûbµ•ŠJÓû[³{6›l{¯©tyf‹“Xß4`¥è%)íWŞ~À*t\;%Ö¿PMŠs7÷5î?VeªHYàŠâú2¬Nß-©|+`'ÈŞX /üD'ÍN3¯ø=ÙÃoÈ-T\Ø3”F0T8¾§Áïfš[å“ó/Xıo®‘*Éy¢ñ…xccVŸõ’™LïñøÕ‘ì·#ÊoIÿ ñ"¦sh‘Àò:ôÏünúVäıçÂc¼c˜Q ñL¿—öÑ“®~„N†¿å.ÖaQE_†RdôN‡:Ò$°³¼ÿ~ı3D™¶Å5év¤õ˜ìÙ¢·_†ÏËQò©¡’„‡¢Qá}Ö@½’âÊn}‰İ?Éºé¯<¯åÚ€G%ÛÚYqÉ¸ßSç‰TÕ8ÀntÿCyh*3©Æfu©œé¢4R•¼ÖIyÄÄ)7Jzı³@Ås½nÿÏ}…†r`	n+ŠŸ.Æzß–«ºàøK«³@îê’¯V ÷ftX¶J‡nç×5: ü™*²©
›IUlØ/¨ÍeU§–' wâÃ•HZò@tE-jZU£],…='²¯¯´3óávRGxåÔoA<… ±øDPŒ"Èm}ÎZo«mû&4 é•dšbEAÄ¼ô£»ÏššÇˆ¢ÊM±|4Ïl!vYÕ1hGU÷F™v‚`æÏ½+‰:à#2:İ4~gã¹£X‚r’ÖI;û°òH5ÖHS™	‚H#»Ú	ß=ò˜“Áp&|¼+çœuyxN©}aÑ,ó?ÅÉ“õ#­%„DíÍfüÒ‡Eê¢ŒEãIß§k}¿Íˆ|Ôˆ{ÖM¨iâyw-1)Áİ$©. rPKÿÔŸÅ—ò¶n•}Tğ	èğò u¶‰eî­¦0±(fyaÚ46Ğ [±–
ŒaJÊx`ûÏô,ü[g‡xş:ıhU[Ófæ17cZ¥ŠÓìa8dâÓYgİ8e®ôéY5¦vbÈ25U³šÀªâ¢´íùŠGV‹ÿ¦ ÕP%‰b9k•¡FèkÊÆL†çn~ğ¨İÔ¨íŞ}=ÌŠIÜ„éŠÉ­h"ì¤_k DÔ˜İóë¿'g}ªìÿ¡:$Ÿ¤,4a´ŒZæ<ÎŸï‰û÷wj‘@®Q<ıOPGö€‹T>“¢—”Ä$2 ö	-ÿ­°Âs¿R§–GŠ™û•ß;LBƒwÁ{UÉ(	¼®ÉD °¹¡J«C‰¶Gà–µğlx î¶t¯°’ĞyñHÒ3èMç‚öv½ÿˆ/•*’¶e{½û«ÜO]<*ñÓ¤ë.Ü¬Fvg$-TOg1µ`¤ÈX*Â®5g‰l=/Í=Ec/d5<=êÓ’ÍZ´RBğÍ¿¸°9Ğp$F¿ÿ´A4Èîi£1ğzĞ·‹¸D(ñ¾-æ~<!ûgµŸo(¦)ê	‡¿â¯k1‰§œ&AEÍåª3Ô3í9MOAfd[bJPÎÔå1’å©³î–‚@Ép•{ÊÙ€_¯XÇ"î€ÙËX/£ŒVéÅÆâI@²Æ{Øo®’ÂëÏ—ÖÇ)ç9ü)Ô·+?ÿ»ñš?+¥Ã¸!È4i¹;>:U¥õ{ŠAöËÂ3CsÙ!ÌVŸêŒHJÉŠ6ñğBPB¤ÔÊIÙ¿½ÊŒ—ì·,sïš'Dl`,˜a·@’İÍ÷Êâ0çÕÍªjÀBXæÂm¨S*Ç¿.W¬5j7¬|R0y¥AìÃ8ÖàíB€Ó®ÑñÍjd¼Ô²¼èjØ#uÓÅ¦‚øš„9{æGL¾2záMbÇ,}§™úQ0ßbéĞhŠ6À@Z`Ê—Mª‹Ê|í‚öñÃ™Æ8¹MQ&—ûco b+ımÁÄDGÑ?-·® ¾RTŞ1ÿ¥ãdUÛÀáîµÈ"ËVpÍÚ8ÛEÍw·JÁˆ±JÌ²E ‹tßdË]Y°6ı¨æøaÍ©®5t”]s(ëÁ x7¦Ğão°dÌšÿ˜õOE1‚\Eï› ¶¹`/ÿ5r¢Áƒ
sk{nÓ¢ëÆŞ¯¥Vğ-ÙÅ\{õÙ)…OrGUõj1*7Ãšz‰ ÌgiÊ.ó’Èv´´õÏ×éy4ñ5ƒ„Àj}GôÉmª€½óµº<]„§‰y¨Bì÷ã£á½r£©”ŸÕ¹ÛVJŒçÉ.ã¢t`%V‘ã'}”C‡ amsWÛD EFNÓ	!ÇÁöí©\nës¼ŸO¦;é—f>i]º:¯ ½¤†«H˜à†Pùî¢ë—á@œ7Ö:éğ­Ä­¢3~ºƒõ"46î
Zo8uÓ@/jŠM
µå–Ÿß%Lt5²/¼sOÂïÒä'î~]İ4==…8´å†))…ÎSl‹h“kİÊ@y‰Dö×CBFÏ}umk{7«%ï}ãÖûë>*nÆ©Ò6’Òõ
™;’a-)1¼_©t9?7çª.qòóã¦¿:üjF× Eıš‚½:oÉ‘™ÄaSËØCßQïÒ›;$á”±ZõÕ°3#l•¦ä÷¡wÊ£.@˜Å¼d‚|)å³~¼Q@,û9£4ú}”¢§Ş”şµõpÌ/§ùøq+©8Qe~ò¶X¿]Sp®ñÕ"Ù¤t°Ó•!8®çf3ÊÙ­F'¸+UWÚ(ù¹+îMZL,©°¯°­mGUIq×;ÈŒ-në@®ú[ş÷|<ÿ)…^®4ñõ[¢4‹q>=¿ùâÇ«ğùò¤¡t½à|â;?JKÏ[¢Ëìğâ(Mœ#BF\U¨h¹=”ìÊesB
af.óâŸ9ŞújÒ$¾6Z¯Rö"Ã
õ¸†{¾6mÍºÕ+Ïà÷ì(`¢M×r²!wuKÂò×à$t¬5n8rkíbãûD#€‚Ì¦;¦»èfÌ%\W*•Í£Å^¨'øO¥•qåÅoãƒ¤”ê6]nŒ_Õu9È~uÈTÅ6”˜?€ıÊuĞeEHF•ö89)_i~œE˜ÃSsf”ï®ÖWî>ç;Ç{}Gmœ`šôÊ¤ÚøÏ]ËĞ‡SÆñdğ`õavŞ”&×¯BUº!¤G]Š@£óå>x‚|ÄbBş¼œ&)Á¢¯´¡4˜=¾¼ö‹åÚÌÓ¼(ê|Ø¹ôÊ‡‹¤°ã9°ÑêxÃ"VR‘Ç0”‹VÆZ¶ö°„|õ‰şFW•]/ñ«q¨>Z¸Êêo"×ë^Ê‡sÑRÙ
¡8ŞËöpb\ÁÊò"³Uô[ 0ÅÀ[I)ˆKêÌaLã…U[%>ˆ)j8.=Ğˆ­.s€Y¿¥|ndZÛ‹ØdGyköLóç„%
vïmK"(·pÕ øšÍâ`•Ä21u–w¶¨:¹{¯BöµFÿ92 ê-Ğ"l\çy%’µ„n–§zÔÈöÆ0—R‰Z7¨´–«™w=Ø"r5ãÚò ü½Ö?ë0ç²|edZU9-:,ºCO:‚m¿İvT—.1#rmjj2À¥‚9±lºZµ=o%âûµÕ½/¦vqgõ9fC"…Ø>ª3²F#û¸{rD:((İ
Ñj#ğ¡sÎ×ÅğÊOzúï’­u•UMO³6ôLu½ëßø,RéÃ	]ë+üş- @}Ãq¯%‘˜Úciòzy¸0yõˆ'vF•üƒĞöÕÎ~`qïÔ²]€İ‚‘Mäúçv£Eùw".#Ö”èb7!ı+M<³ö`}
İ8¤±B¸®¼l¸Hg.²œD£¾ğ¹^šbPš¤ÉÁ¯Šè-åµöœıÙ,ó÷®Ü†3ıtºí#ÅvÈfç ïü9›à:lVo±±×$×§wº†èà4]L’Ğ)à`Îj;yé|‚9xıç>. a+>I)3ç¥½'’gf{jyòõü¦6¾Êÿ_k<»½Hô”¡Œ(ö½vIÉMXêtÿW|M¦ — ¯-û]ïE)áï¹e„QÆ“™ÃÆÎ’ÈÔŠëÆ?{TÀ¸s½L¿êô„—XWç¬ºÚ$Œ2ÓØ©CŞ]C,ÿ˜|¨¶øÖˆp‹Ö
×[ÌFã¶#	ÎIeDd…fÄSŠ^ü ChéÆWõçSÜ<<Ü<XìŞå©ìrùë$ZÙp’A´•9ïµ‹—¨=nj«Q¼Zæ£Sƒ†xMGŠ™‚°JÊÍ@o…8q'tÀ£œ>Û}Üñ+¸û\ÃAâç)ï,vÜ<I¢$ù"oôô0Ğa
Q9x¦6PQLöcŞÓvI
{É\Íêá³–4$âs_¶¼?ìµ7-¡wú“8BûË¹€B…öW©&4±»Ö”,úxxT½0edÈ¥|ßŞÌŠs» Øş-	İâêäS.i]ÀÇ3ğÈ1VŠÑsFR®HÊ1ô|z3¡E¼$Y©©S ÷Ó6’ûU–‡SB·ëùæAÅiBOi«rôáíEÍ_‚²wá–è`À¼âÿíôı’L[ì‰²è£Vp	S()fò:ª€š®Å=6·³G˜ìıXgœÕTa¿ÃxİÛi½%NòÛkÕäÉ“qÒ1–Á¹\c›S$?=%´ÿ´ÈX¶œĞ‚+Œ¸~‹±,Pæ»h\ÓÒPP*ıä~pá6À¹nèâ<¹ïÆºüUqÇOqñÏ+78iÜ<‰HÙàL!Ğ`ôFšh$(Ç¢îBE¨`¿y¡qÿÈá‰xøÿ]¶>ú<ÜS7_˜Â°ıth>ævháÙşC!-/‚J/3}İAgµALbòzï
·n÷í,¶›Ù}˜'?SÅÅ6<çFcn¡ã ~ƒKè}0ÌZ‹0CP¨GÏPÁHK$óêÁ¤V€.™†¢cÀİ›`AÈkÃuù6ñÿg•ëÕ_Ê÷è¢!ÿ6i?ÂÔ`n°ûœ.Uø÷ °S–1øøä¤|9v£•&îz¿GğgÕ¬v šçšX—P¸\í UóÕˆåÉbò"ıˆFï¼ú‘ßèveˆ•;Äf¤#HôŸå(ÔñçRWÊT›·'IïÉzP}U',„9ªw'{YŞ"A,7víVtÄIKŞS‚‹?,Ïmc—¼ìÀ‡—^B>§(F7Q˜‹>©úg3:FLèÕÆV*oß“Ît9:yá‹8¥ÚZ‹7§ka¶¬ k7Æ 	›.…W­ZĞS4á½hâÈ²<"Š²D’OÈëèçeŞq´ïõ“1G[Ã—ÑZù´Øñ_‰˜ZLŸ >¡Ñ blÙƒ˜"Î'äN±­a„Íxn!ÙÛ£\ı-WE<ÎÚÁkiT‘ŸŠ¬Óé>İu•TàĞ“a)tî2‡O =…ïÍ^ç7–læ;Éª >Ï±s6ÆY>rD­,xu8Ã$‡%#ä¤"sv@»3¤ÉFt\é¦©yÑ ¨@P‡?Ç—›eŞS>ÿç
ì#ª®íG3œÚİ¢b*Ì²„µeóÖ¯ytâ¹ëÆß¹©åºù¾àkÍ‡’ğ²îcÁ`±b	`z“Á
«Úía\Ín"!éÇ(ß&™[lñ»aEŠñ–jB	xè‹úeø8+…çúv}R
ÓÂP¥æ Xâ¡^œîË±Á…eµ±>g
¥½>{Vˆ3¡H»²•ïAª(…¡mzµ‹‰Q€G&i‡üVnó®k1ÆlúµáR©ø<Bƒ İP]Ô
–3„µ(e:‚©JV`qˆ›ùy ‹Z=³PJj™ Ù)£…Ñ»‰‘ª^Ó˜=Ë©í¨Hëÿ vŞ’«Ê^Qª¢	aô¦‘@ vÓZ‰j­€÷×[8^\º}eã:8“ÑIYä=›;?;IÔ˜ù¢!Äˆ‡1r[`]”¢WA±#ïpLX»CÂóÎ"óİ¢¡¢åÎÆ÷ ½A0ç,ü-¬Å+„kKâÔ0^SÎÌ8J¼ïícg´ŒÎ[§¢&	uú++†ŞÈ¢}‹xV€“)0ßß¡ù
œía4TwmvØlnŞ'ÆBdíUºKû›ºEB#V¢´8=Õ&*¿¹ç]Íg±«öRË÷‡Í¡zvä"1]ªº‹Ä#pB\.ï×½"-o
ğ¶íüœ¾ŸÑ52c4lY †m­ÀŒ,À¬ÏÔï°Ã_·¼x]#Ú+Nƒ£ K²L¸ú`“²dHstó°wæø·ûhqêÀ-İ_8GG¢Óı FvqŠÿ›æß7T…ßj¹j¾ ¼•Ò ÷Ì8ĞöT
ºoÜğ‡ò^©q3—c1zì+E,ñagÃTÛ˜9C	:"®z¬ÆÖO®Ç‹c>Ÿš6ò?‚ÉÖBT”+a(ã_]EwgiãßÊdb0Ó?dw€8\¿l¹x®Ù8ÃvwWÃ›bßT«I‡Íc™“|Æ–]xq~QIËl?İuÌx‚›7p>6·rÙ‰(Ár£{àÇåâWäh5°†u§EÙoˆ`ÖĞ4)GÖëàrrbJ«¼¬³ìXvÑïñ·0ãıçy·¸ñ˜¸¨0Lx^ÙÛ~d(n*³•úb¬lIyİêë€Ga[FE°Ñ[#Ù½[CÛ»>…1rÉã{Dsíôbz2'³Ô«Î,2Vİ8¼ àDB6W_dT ÇmI²ë—Œ':ESµ2ZÂÌøLBŞºÜˆ°s4¿%J>·šì3_“†àdıÜO:Á"ÓC‚?,«¸T‰/rÄüRèºMŒxH³?/²+UètÍÙ<8kí·öÚu‹jÁxÌ?¢¬S%$HSäüJ"xZj¼ngeè¦Ÿ âóXÎmJ½yÙ"×¨ß&É³½³öä‘-a~ÂŒÎdÚÕ†ş,3<'I¸¹™à!¡”xN€ıª÷Âøz\Ü˜ùûøéHw×D4ØIK!úÕãƒ.=hœÙPT£ã²@º>ï<E_hœÀœPk˜6˜M;‰9n’Ì8]‡Í]Z¢kî Up…0§†Á`Q$80¹ ]!Ô,< ådY¹â°ª‚>÷·{¦D2Ğ™ÿ oI‚ yŸ MÉâ€ÀÁÇ'Ä/SšÄÅô5,ïO0ÉÓ9ƒ€\8{ç=N`ã_ÀES'ğºîìàÀBR“'\KP—¡r¥%¢ËlÓëêCT©SqLÑ™>a³
38=˜ÆÕº²<æ”«W^,Òü=¯§§üÊdTTYÜO˜Ì³b~@'x9_~B¹²ö,Ks’ 3&Œ´…|àêY‘ûVv83Ãõ’KúW5¸'N·ùª€3wÚØ=hÓt;øûÌ# ’¬O8…ï0‡Pš:Z÷y$ÒÅ’ÍqÔ²j ŠzÌìØ©’’T#•™›¦ ±"¸ƒrjé¬ÿA<5¦rĞ
W°<: zã`¬`´Ê‘©@¢–Æ#ZmsÈLºÌcég"8)İhØÉâş£¸Õl‘Bh% şX¨y“xøõ¡L¼¶C¾ Â/óßJºÅ®ªhÈÔZ¡Ğv¹íóc›n<ŞNê¼GaìÉ³)„Nä ÁDk•ykNsçaxnm¾¤T€$¥VRÃz€=-ÈÌ¦ÓÅ®;dL–ê$ƒîºíS’q$h>¥Š_ c“òY¿N·%Ä³BÛÌÎ^5wxaäó5m€±úÜ£+D$ƒj±­²ÃP&æ©e’ı¾€IqV°ìĞÆşJ'jL¿H4¤¦%ÇfÀŠDLüòÎïŒ÷ÂèõÍÃÖŒ?¡ƒ¬‹ cm+Éu—¦#7”ÚS…/®ÎEİüŠ¹_.±òÆ^ß’>'(k'£z'ÒÄı¿Ökzòˆ@Oõ¾ĞcÇx§•‹–%Ók*şš‘…YÄóİÊø·Ô$Ş75”œË›6C¾*Ğ'Sq‡U˜t–HşlOnúMË {?ÑµñÂ‚è5Q”z*q'›:j@xLŞ‹Òü±hL¨AZã„XÔKÁKª»#Qs ÕĞâzÕşÅ2,mĞLşŸòÔùçÏæ)¼7c<TéîSĞÍVtÑ\¡Cö„*öò…aÓñPùÉ‹ûe0Š©ı2‡ã[¶qÍ8¼TüºÜé6™w’å“õì‡$gLŞ{@…‘ë³GÛ‚ÜßÇåNÇO”•n”´×ÄÍ”´‰°±*p»&LÑÒüè¯ËvØXö’[\ñTQuZÒÜe9É0}[ŒÃcNµ¢ù*ŸâAù•ìsRÎÊeÍ¶Ë?|m~Y<ÀPy‰kÃà¢ùI×0³˜W©-7Ø¸ …Ë¼:Ã²ZRä”\½®<Ô¡ÓÜÆCd|Ê!~(m˜«7”Æ1¤×a×ï¯qÎ&C×P£
ƒ¥oÊ„×æ kÛpÙ°ˆµßšxYF¤„xDfıî-ÅÖh„2ó¨Ü”Âq9cÜÊ­œ9 cÙJÉLb@ä'ÕºôA†qŒä±Huæ…üŸW[³¨ÊäİÀ«—ŞÌ):ô/˜‘5)¡#z£ßşLëÈÂi’MEÊ¿n­ïRûÛàfÊ“9}ÿ„UYô yÓÃRLeĞ7©3Lˆ§—ãc66®Yøxì$}¿Uê­î»·/¡ñq¬2¡²iÊpº°F7ÆÒ;øòA‹€uûˆğÿ¥i$•T….!è2ÕşjŒñÍ=å?Àp‡˜$ñgı‰7¤¿¦ZÜdœ_*HOÄ3Ï#ÉÌ=ï¤ïrÃĞÙ˜™RÅNdô—Cu¡ñdk½Q4JFÏ[MÓÎóCtAfyúólÆÃ­$‡X“Ÿ>I?`gÅ—ñp¸æ=kôÎ6|P&=î÷¹êšr+øÍö•’½uRµ's Ãj=™Ã«N˜-Pï7hm¼Š°r×XndË’á"B×wR== Bä—
Â‘vsà(0)ÁXò#•N’Ñ¼bû¾ÒÇª¨qÙ fBª…}AòO®f³ÔëÚ€‘
zØQêû£¤‰Ä¬7€}¢ÔQÓ@"O¿ps¸Õ°]z¯gñwSØî[‚›-n=ø[²¯YØF<"
s´§	¤Ì>ãĞsu9óĞ@ØÑàöUúqŞ!a£x9L¶8m¶!u¤Xò•gÈKì‰f`ŞCá­!”¥¹J£Ê†cKDÖØGGÒ†D3×Æüö+ñ¥®˜&±íÇA``l[÷9n­{uƒæÎNX$	c’f0Ğİ—¤¤ä…¬&ú"º0pácB„Û0	¼>ô sé×
@5kßQ¢MÀ¹¥a_O{ş@/&f=‚jËšZLĞ|¹»ãû}v~N¨¢³uR÷Â€RÜâ!cˆ•,¸lïÕHù¤šßŒfÔªGÍÙü†’K¨dñOFƒ”£Çt!ÙQñ„×Aµ±ØÇc]¼ÔıÀ’t¤-\“véŒô^©€»ú…@5)ÿ@÷g‰Š«p‘3WÍ[&>i_€¼ı	‚T“-/›ä~“ÆàÄ«¥ÚÛEIºßÀßÀFÒ£Œnñm$\ÙãÙ¸QT¥BÒ.-¡Òû‘Ä×zk}ÿ©3†z¥ux¦@ˆ®^Àq4¼ÈˆÆ“¨ÕÄøAî!¿lÀónÖMµ
¯Ÿ'$ÏØÅÂÍZQñZª÷¦ ®ú“[Şc{2ìú•Æ9wÍ{tœ¥_X›Fğ°æNÚ'ÁÕòGC>ş½w'Š	‹³9ÚKÜ˜P5o#1eì¬W¸°µ×å$ğ‡Ê#@İãÒŒğ†ÇgšUã¡Û™öˆ†]s%‡3³7ú6‹¨ZM×!zè8bİÎã*RY‡m³Á„OmeÏàUqÅ´»·ÿ‚‹WJã<:ÚëßbX	 z0—sœy°YéH%sísS°wh©äµh1~ü=%œÃÏŠ¯C×ŸõOf&Ø‹Àõ}àmhÌïó¦rÉÑ^>e©¥xôRk† Y[èÖgŠÜf"h“à{ëóOÒ_Ù!ÙõÃ°ó1‚í«*ÖÉ+R‹;øæ.åŒ2XˆæÀ[0iÔ’æ0,ö ¢SºiYg÷5|W†µh“®cšÊ=yhj’U’ŠTØì®°7{øÁ¨œ[ùisgÎQ­3K!”›RÉ™|¦Ã|’ƒiŸaÕôû}Ùa‚Û¯D¡ù¯c+à¸ ûW88ZRI¡{,¦„1X(g'v¯‚S‚Æ;’¼ÑSÁÙú3£a¸ÍgUÿkA”v†@µÇ`9º§7j(ınšİ¡¤õi–Ië&Iô"´F1!°í×â¡ ÆJ¸€gÍªˆOÎ5•ÆK)Ú{4ßLZøçşë€ïìå×®W~,Û¬‡†I•€ñ}tîbæ 5yñòzHIRÜ—l¤„|›Í‚c0ÉcÙjSBú4}±/Ÿ2Ÿ»×ÁTDsÎûJ‡fğw!ŒÖxü“é¾.×]pámÖ§êõß®t×HbÊú”ñM›©~+4ûM9yÇD¥¨^,ç¢¶És<¿DoŒekê¢¾Ÿš‘åC]js¯{Â±+)Å_ÆÒŒõj{u¬´Pm±&×±h:KÎ‹Ğü¡Ú€lW	ÇM¹ñ¨$$Gíı~í ³Y‘”C²/¼Ç×ÉÎ%ş0UŒõá;‰Â©³J¥ŞÈKFíkÛ°fÔÜŸft©Ğf,1³1˜uµÓåëM÷TœÙ0+sÒG4İBüaˆ€æ”¤$u½u?AóºEtG™sÆK±†¨úü—Öcá@?c˜ã(ÉÍU¤¶µ¾ O!±P1õ·ô‰9Ğ‰7?8¶—¡™Lu‰%×.ø›õ›~Á!'L±ÒÀdÂªB·‚nÓ8È×°¼-Viµ
0dcšä]!ÿ„%óH³é8ç‡aT…va¤Á”š`“¾ÿmnû‰‰-Píg~Å³¾!>ÖÍ»Äõ"n¬ì7qXTwõÖìH/8±’D³C˜å@M;ñuÃÔwÏì Q¾›ÂıÌÌ¬ş®ˆÃb·auQIKx¨ÍÈ{¿vŞ€{¼>1öGünšÏï‰Ï'ï^$‡¦‡C£vú§ƒSró‘k|Ç¼‰×Şì®mnj‹)7œàÚ%#«ú¦£~•¹.nföİWKë¯€§´6B°©ÏĞŠ0ïÆ»,åKkÃ64?ò8YçJ Uä‡.s„BÄ/Ùi›Çş½Õå»\çBóhŠœ,bK³ÕYÕ`+¶Ç¥—º—Oœ–¨s™ë—@Ïp€íJX=ãŞ­OwÊ´JĞÃ {½/rA§ú^­Gğòÿ"O5‡Joê¦®xøŒKoâğRõ:iùWû“ªƒXÏÌ¦Ê>*Ôîğ<â¦¡UWºí}¢yU	”j´Š“í>e‘¾Pd:loÍ^ŸRÎm½Ç¥ó5èIP¾ÔQ¡EéVÔ•Ø>LôD±óâªFö`Ä­ğõë³ÅçLFÌm½^ôŒı3õS›´-ÁĞ›ÀŞe|[ØnìyöŠ}Ö4$OóÆÀ§øÚ¾W`¶ûñJ«ÓOàYÕœEoL—3&¸„¯Sı²˜gÂï¾ó®j©7ÕÒıhµÉ¨Ågx	j×Ñe]KPŞ‡Cğ–ìá¨øHí´î1¸¯ß¦á©ø=:ŞG5ä*…êÊ¿Ù¸ ééŸ‹‰×5/ÿèb{oŞ÷è•tÂiU½'Ä¹ÂÉÌ~z;vş5DEi$W”;ëù®)ƒÈßùv¡7Å—ôôî|‹ ‘Ë¬3õÇb«\“zfQò—·5ùÙ ÍÑ!Qºç–Ø,&§5ÛÆ3ù·ÙÊË«?ºçy¤cĞiÁÁNAt†¥FQJª|&$Úl«ìŞ2hŸÌy6!_Uı‚©íèEVïÕò ¡P7Ÿî:yAh¨ÔÃ`×ø(sË’‘Z¹Ê·$ÄiÈĞÂ@¯OÕKè‹±ÏÒè£ÔñÚ+Òy	#n{½T¥ûC`ƒ;:3†£²9É=ìº¡±¦é„,pfP1$zÓo!&Kƒúgm`»®*„şˆİ\¸–f·¥ov‡éuş•R ¢ÇáŠÅî#tçS?`K:Ü5È7§»/9…<Şü¤õ”Å÷sJx—ÓÑ#Ï	5Ùzù4œÉ/Ï	Xú "”/é9QÇUlmúÚÓ1éÆt®=ÿ'»—$,^‡Gmì(Ú>°_ÃŞZOu|¦ê‘ªWÑÚ4
eêÀÇ‡¤Ås»)AJCUå‘¹;é1ü›b`‘@Ú^ëJ%}½Ç´LnÏ:¥ÉcGÈÏÕ^O^¿°Æ;ƒò™Ñ3Oö6™5„b¹ /r}oçÜQº¯ûÌ&ÜN>«i)z7QšÍY~m¸\š»˜(&×‰ºÅ¯£ì2ŞËš&¯kÈ‘Õ9ûÜYæıO¼–û.ñwe8‹_È¤»QßVMË5å3¡øboÉÊ³ñØ:w2Å&¾@cê¬7á¬²ç¼_·aÂ‘­»Y£7…» j&Óï4s.™6)@U—²YqIÛ©Å÷tÀÒÍuJ€Ği2–kÖ2{aûjó|¶O]lèéÖÁ`¢Ğ¿nK•ÔîËüèİ.2£ù×ÌÚW8‚>R€£J¾Ïô%¿–dş†˜ğÖß¹T‘›®T%³-ı§‡\—‰#¡1š³¤cêïVU¤~î¼[6“5`/£2S=Ô^¹´0w²€h¨¨9ŒJù4°ÊhÛx#şõÌ¹»‰‰K%I1Nã(¸ôÛWğ¬,#¬{¦—ÿíÁVƒ˜Œb¥•d’–ÁD…XU`ƒÁ¶ú4Bô¡ÓA¶öÊi_`œÀ]@Š¦ó°í]sIpX´s„+µÏ·%«‹©Æß}S¸l	¼ß(´µ”qb¦ĞËGÚeò$U@İé#<,dİØc(¼º¡VÚ÷›.B8
E&çÈ»­¶“n¨èsÄj\¹œeh aùçÛz‹Ològ¥–ø®ÿ´ÜGÏ«é¯H6æ¤x÷û5Ô6Öİø!0—¬mXquHS†Ëf°¦§B+„GÊ-Suo|öáƒïƒB'oÚ`ãEˆm~LCrOkÔ8n<VŠÅÈ¥4&]X Ñ­hÏP'€lç3gBó*…P†Sdö‹óèÚµÊ(í—[kç()<l°J÷¸kï•."Ê®éˆÍ~&‡|*rîè©JÕSç²ul_Æ/÷¬j›KC—ûÿp²ÍÀUìöz?Aÿ‹%Ë‚ı3"ÉnWÓCQ õ&®Ê<áÇ…¯làPQ*@û¾5ùj1x…k¨ıT¤sq‡´Z‚¿{ºÁ»¾É×ÍñWˆõãX)ÛöœärC¡<zÛc	`Pû¨è_P3Éüa
O«|€K[!¿ÚH)£áÛõØ×ˆœ\<Í\¾ ±F<ãÅv¾,4ÖÍj]Wê`É:·Æ™7ÕÜæ.Àª³Xö~¼• Ğ—²œH³ÉÇ+@Ü[_ÌAêí{pÉ^bä¹¡lƒáö1v´±8ÙT°Î&ã4O–6Ê£.+ı
!.AÑÏ~O+à²CÏ_8eê
Ik&Hî)¾Ûpp=ÃÿK—¹+4„[‚Ì4ìæfF?+ìw¥»®ÃÓ®¤9wìTè»7)ÂîÌ¹cQoYÌ
¹Â¸fÖj­4¼üSÎ®Oİ}©¾3…V(ßÂèdr 2p„˜´¥“åS&ÌŠ²^BÂä€PDE	ÈRÿ~˜B—vmX«ª„ëÀ­—3qæúg~ÄMº;z!Ö>ŠReYê{Û@¦â,SaL˜¨şûçËåÈ(Xf°<oh©Q£Ñ%¡2òßÁlD®ÏıY®u"@Sù¹ÇfØ.SÔ{.SâçŒ›@È]Z¹ï6^.ƒy,İf¤áµâÿ`‚d²şüzùêÓä"Ø ¹ö"µİ·`õ¨÷¥-)íe²^÷(ÄQİfş•°‚´»ûı€è; ¡=İK¹ç#m$›dÉƒ•…Û7ôDõ=‘ÓO/{ã+5~qECp)öõ´×ï3œS†|µ;*kûRŒ4jàís
±a›«…ßZÁ–ñlĞQ±E%ãLGß)9öÈ†X”‘Êß,³íTöÔ?{7”1ƒ-Åí‡ä)…fr	×=Ò¹–%˜Ø@wîµì™Í_£ËnµÜØQQ-"²ç¯ÿ¦Ä>~áw-&÷PC¨ÓšÑ«]•A’¹;Ùç·´ÄÚsÀŞKj˜UrÊ°¥älrM x¯NæˆÏ°WÔf$ıä,ÛUı»PIp¦ÈYv]\@)
ˆRµ­ìß‚¨nÄ#ò]üÒšIÍ¹KŠ” ¹†LIÊ([Úq*It‹˜)|@L*–!æ¤Njöıé^æ×äC%î$Dtñ»$«ËÖÄ”DE-¦‰Ò:ö}qqÙQ;œáı@ğ6Äq«Ùj0êğÇ/`Ò0™–¥˜±Õöó69s=!È„cwA'®w2=ˆšÀ@ë!mgGûRl³—
n}nBÖ.SMüO2Ñ3o½"EoY6ù>šdá7ş\‡«Fu*J”ÍÄN­MÖ ŠŠ¢Øî.Í¸i©
ÿ—µŠ›R7C*uİ¨0/_N¼ÉòÛéK»-'ÔO’”Ø¦ş¦Û)Ä«Vvš¢Ì&ËĞ›µ9:c1¿T÷S—­X&‰hÍ´ ½?¡nt["óå¯èŒä'«¹¶Ëú¸{[Ö¹CŠC#ç&ªô{™ôC#Jú¿ãÛ—@:¿õ@V!}WqTvWˆãÅGCM…F·AùÀ{ÈĞWı¦Ï¢Ş°ßá*:`:>œ§#]€Ó·ˆ¤¯xtˆĞàëZai“sù„}1Ooz¥¨ú7<ÑxøÙêœ#$òÕ|uŠ¯™àRâ€ƒ”q&´É	¶¥²4,Ÿ/¨§ä¦„ô Ì.UnHc¶‘`ÔWŠ©Y`?O^¿$ïÒõcã·Põ8ÚYí±û‹7û¶Q·nH¥^\®¯º/åP›Y'ùè6ÃC‰ï9Äg~Ú7qØ::"iÑc‰×ÂG‹äğfõ­óaæ`o©„0É£×z\©WğœN¿©…Aqêc#ğE‚“Èí™¯ƒ"¦xx>™½ á·Äf­-4<¥ÌLëÿŞ.ğŒ’?ÃèìÌËf/$HîÑ.>èßóö4|dıŠÊøJâj%µ÷3t*/qºHÕòyçqî
œS‡®$SÂÉ„À¥j"Ú/ÍKê>Es¤&”™j¦î(l¿^1M»VÕFF…åïíQ9¼pvºÚ ‘½»–rP]„ò6mqá†ãUtg,tŸ6(».ø^£ó¤ä}_{âhâ}ÄÇ6*Ñ‰[>ë¤)ÃØ›ÍJ!¸&ÕØE†.é'Ì¾‡~ae|ßÆúC^€Ô ±‡?Äëy (×ñ‡ÆsÂs¾zçj`:¡€z%¬®Yn(ñ‹â‡B+q T¼ÛGI€j$0WÒHÛ÷G•Å"y¥áÈÕ>EñPNˆvwÜÖE`ÛCü;c,·#)Çñ¨UƒYÏ€*Cß%íÓ´»N.åYxÎİ ½äm”¥œwº¢U’Æ°Ùqş‹Ó
ÒÍ•¯7z…Fu%-€LX©îSjÄÙ]KÑÍÌÚèx-Òmßy`­²áÓU”ìùÒrB‰¡›Û_Fv¹ŠüÚ19=Áz.Ú…†kVÎ¶ÖÎ[¯FnpNºÕ¨×¸C£çğ«Y‰_G„Â§‰­F?=²Ôö¾H•“Úpù=5“*¶m˜£×dCÕotÄp×—âûQnHNú]N®Vğ@ı×[ C´ô£w L_—v´RF¼áaîAC:§#ı¢Åk;ğ)~•¿ª»),ô’8æ*U'Oäİ&ª2œçKŒUœÓàrÈHì?éprsş.d§~[üMöâÀvëøªEš]7ö½¿+y”gøX8Üo]ÂB„ìè>?šÓ ïdJ}uå¯¦9xt! $3Z[WÒw:bØèÀhÛW‰'ÿ6ã`ô/“Ç†˜ë~Xo?¥Ù!¢65c¸q'p»V”ªFÔ8À‹-T|Ì_&ØüÜ°ßh~™ò}jÒ¶UuÙ7˜É$ùšÁŠ‰r 
/Ê?‹¿xs6Xe0îÕûIà ´sWGútXB±ÒÅfé×]IIİÓ2k!SÁ@…^àÎ“&ŞÜ~1âD2¬‘jeûœŠ£È¼i~%–<Ş½:_‚ ¢Ô^Ê¸^K&à½¿¿¦¶š'%yVóŒ¶ĞWV§ç¥ê`*gk@~ôkÚmµã¬Él¡cÜtÁ>Ä;µmÈT†[qíè=åò@¼­Üjå…²²m³úv¼¦‘âa—HhLKnÿ Õ5R²”Î¸G«ûJ¾¥ıõĞL?'øÛ#™â%ØWTuV‚|›i6uVqüéş?¨ÊEd6wbg¨adÏÕ:ãÂü—ü[İN|Ç4d½0Ñ\'È&e_ùAcQ$•Î‚t¼¾LbÃ%Ã…7/Xo¤ùfí&®Âxø[Íä¨™ÉâÆóæxQÔ&H'6üPšY¶É´$jñÆLAµªşx¨9u^WËeÄ¤*„98eF­KÂÀÖ’ÙS|ÁpUßj!ñ™«_ü6szÑ¹Â<Päô›†$¬H¬’6|Ñ2¤/èoGÌ›ÿ‰Š0„wÛ†;>Ë/ ––3­ ?ÿ9¤ù˜Âı©F¦z‚=¿<`X«¾,œ>¿í×¬uíÛñ;¹á"Pz¾.vŞä»	| +$Ó—bêèxä•ÙÕUøç¼¦Ì¤µo¡dï%Ó˜¥°+XIò9¼{ÿŒs†‰6m!˜v°;-‡Ô-ã\J—4‚.0½n a¿UKØ¤¸9QkŒZÄ³±ıŞ.Oñ„6Ÿ¢E·>Î˜yÌb±hwpÌ¤š1R«\}‚	v/÷Š B*)#ØÄFçÉ0)öELÖ®\âK:4$È5’s3¹ş—…ºz/`-:ø"}–öœëE¹™è¨cPs\³e ¤Z¯j(îy|"òÔÈ5qÇKI_@r‘joçZ"Ë	„6ÑbÔû¼ö{T(±îK¸3uHfŠÉBˆÛ¥ï}üÛmÙü·Ğ^ı$ƒ¶àÍ.«‚³˜ï‰¼qù¯	@#İ*‡ÿ<³Ş8Ù­ÔR¾Ó/Lø¾5´Õ2‘X»öK¬ğUr­‹¨âô—
_ŒJÖT£L…bÃrª† ^¢]ÄÅµğÉ{ı£’UÈç ´_Lygeê£ Byywûø0·[ämFùqğÚuÅñŒˆ–Š\¿C%ÿ"f@x‰ßwÉŒsörqCÚƒÉ‘FŒ	¦@øvÙ‚¼äOÓ“K&~
6°ºÔ¦°ƒ×šT@ÚÉš9¢I¨9Ò=è¢ÕeUHt¦Å©õÔa™±Ä®Ã-ì8¾Ø”‡ÑÅy…ìr‹”˜³Şêº²«7Dç“”b÷Bô–bÅnˆ`õdXqF³ş%:À¥Åñ»Y†^–ºÙì‘ì]ß·‡¿¿¶‘Ÿ‡>ÒWµXÃGUaf£g§4a@¤Ñ•<e‰v(,ÌŸ€na“gu­‘k•w¥Í×,îço|5µø®AV<ç^Ï¤Pê?üÅ†62Pn_ø`çâcØ—ˆh÷×èÇ
JÑóóŸû`b¶è‰âåf’HÀ­p}ò®«{¤Í˜íœˆK¹£#aW(vO¡ÙæãÜ¢z#Üs"ı²Á*Røš@T£”(Pİì\^²!dÃ¶òä Í;¨jRE(Ùİ!Šÿæô„—ÄİE€îu‘3|'©ÛX†.Kcêd
 ø<ïè›…Æ$ŸÙ/´MBŠBİs‚€¯ªOÍlÂto-ÀÒ¶¨ÃøÀ°Uı „¨«…¼0ÏIÚõSF×™ÊBì/Ø)s~&w»|é@.ò¥gVnì÷êOûwâ‰²'f1=<	y
éÀ®ŸM¿‚4ÁjÔ>J¢^®Aî$ÚV‚BÔ|yV‘•k5KĞ<…ØáÑÆÕ#²Ú(çf‰¨ü	¯"ÈZÍ3b˜ì—2`E½í]9ß½"9j$Ø§ÌË#ƒlşY¥°–ˆbñ‡¡8| >GA’á›qşgx­]À„áQV¤úw"›Ö‘À½ –zğæ­­g8Š”"F8Ú<F}7â.ˆkò^>™aôrcò²÷§D
³(Zü”ƒJĞ/ÔaGÆ&ºg@Ëø“)v¬Ñ{…½]—çåÅQg]á =ÂšYe½ùm<¢ôV'¹:Ø%ZÏ¬Z<·“ÄS(ÃsƒL|QËsWÅ(BdÙÚ¸ÊE‘¡yC¢MyQÓ?èØö8/¾øÈ½ú˜²/Ø_4Uly¸cz}*¥áàˆNÔ(:ß{ë$ªÉ
®	>RRæ“`;YséçcÂı¯Fjw=¤ecÆLºî´ 	háãn§|Ú‘«¼ÎÉ¬šõ8k	ÛôİwZëfÈfáàr²«ÊJâ¢8W¢ÙåL„q9ãàZŠí´¤ªû=n]õôÓÃ¦K9ÆÍÄ!¶’D˜ßãÂ¿L©÷ó‘uŞğØSŒ2Lùëİ#§Z?
êì‚DÇ¦èE¹v~  ÿ÷R/]+Å  )JêuÄ4Éİ@÷#*§GiÑ +Â¬üv9«­œXOìÕ£’(_µFŸ…qq½y‘+/³±İXKŠ-åˆ¡ª…¢H¾$M»d[W!»­Bp’¹ÃXj9­jQ¸ØcfG°)"b	Òò›p´ƒpFÄJò+O`óH*Gı‚O­êä;šTæQ‡P›`âiÒ°ÕşCÃàö"¡LµQ³¥Ø8zÜÙì$ˆË÷Q+¿c ^Ïô‹aåÁq+Òî›õ!·µß(¨ıÌkØ².ÊĞ‘]ÒBñ‡*yğo ŸzcWÔ0'¼2ÀJ6x‘—·f6}!RNÕÈ‘Ÿò ´v››¬»Pc{v³å"kkï¨J¹Kizşiö©»#~ı‰Ò¢«¤9áIÊvYŸ=ZOÓõ‰ÅgC‹W¬l7ÉHc„÷*Gw³Úûušÿn6­û d™¶>šßÛ-,µ²>â …P†N)3İcº¯®5=*¬¾¸d!?M¡ä W
˜³ğš{Un’—@$îş=b¾†±å­Àß‹söhO&sf™z&İô³TBJïx‚åtˆ=€‹›Èú°~Íâú†;Ì2›ÔÅ¹šÎ+„Ï0QN-õÁ}íA˜%¨÷ ’Ö5@ğ$³o·_6 —âtÄ9ä¿1Lnw ¿m/Hn%‰«"œı\T+ZA)V~üİ¬WÓ|ğÍƒÎ2ÓĞ£@†Ñ]5–~¢Å¢Ó¯²ü+şú¤¨òNhÇÿtªzU‡ùéúzKó¾ì»²•³ZRâÂ÷²õşŞKgL·ßôªJ0“åxşí:+–dr¢ô†öÃè"@`2ÓP~Ê Ohâv–åæîd½t+¼ò²”MöAâ=".K®újÑ±pÿ| qÀ‰ƒË…EL"³£ë3ÿ›Ø$·
‰2îWnî%6Ì‚Ï'.»ÑÅÄî|†Ò¿íø	şİ‰à³^óé×2&ßµš^’}§5Ù5³ÑfşrÒxĞwÛ#	 i%åE÷® Np¢¢¶çí]n´ZßDüu›hñ¹ñãß¥Í¥pn[.{ïû@Š‹÷ÌÂÑ×Ä«Ó¿y€Ê-ÂûW~ñ/JÁ«Ô¦½ì;Øíµë'"ò´“»óÙÚ6Ú$Ld~õœ¤Üæ®YtÈÊ„WĞ²ˆ™»d’W@k/—'VÎú{[÷Í?*&
Æ¡<İØœHmP]Ğe0Tß÷a·Ãc6ù3	µùo•}çËM$CàÇëñ#ôxE-ê|òÃv‰»âxŒÒœ,*‚ûf@­á@ş©ğ°Å<õÂ¾Dä‰gÔ¸ù„	œ}qñ¯PHÒ=ú ¨¶lNåó%,$M¶Úı!7k1¬3yâ£èËVû3:üoGí¡r=õ%IóÍ3òB§¼ Ş<=U-KéU(K“!vÒmÖnšËJ(öOü9­õ
ƒ¡Ÿ†xûé»¬°¢Ìnã¹©ecÅ”[«bd¥$q*™$.`'êÓq–Ø¡ÿÇmhÛö`ùI0Dü¨ìñŠ–;wå¥Ûß|İø)ïJæ''€p„”y¬£l¡äÈøŒŞ„ õÀŞh
.ö†Gm² `K"æ½š…¸v?øMĞIÏĞI³FR"F›%ÕØ° ~ŞÊ=Ü[J±Â<ƒv™í¢¾íKsQ==-ExPµŞúfÓv¤¶©Pú­å7¡¬åè†quBÏ„ûi¤üè¬ì†ÉqŸFr”çÔ8’Mø†ôó$Pÿ¸^}O#3À¿pV¨¨¿U B]ÏËrlajàŞÏ24²±ù&\Nì$Ò8lGW_F3¬m°©[6>¤0kC³]ãAô­+ú wÇ³âDø„S½Z¯5±Nõ©²ÍÏIDäjÂ)_­“c?"^]×\Kªø€ëßÃ›‡¾ñéàukklp[g•rÑêĞ)ˆÛ"Pn*	¾•\Ñî0vÜòRĞğQ}©)Xi(òI>D½¦£+“Œº Ÿ0éTé`–-Gq9Ü¨•~Xş#--2ÂQ}@(‹%dH¦İ†´ Ü}¨q¬?Å#'£ƒ‘t8º”Z«]Ñ‘¦rôŞÄšÆº’M´vâ¡¨¸:§«¡Ú‰Ê‰×xæeN~µ;Ûl¨²Š§ó×_=Ê;|*Ì¶°PuÓÎ^¬Öê¦ne£Zç@¥4ü:OnqU,eñu_ÕºÄˆÌB3è¸Bíºl©’Òš!1
¤-ëÆ­Á·ÎrØŸbbßƒ
úAøáÍ–e»¡Q»ÅkŞ«—íøt¦²úÓL{»3ÀÅëÕ~.´Ô g5~ì£úş¹K‚À8çzVxWÓ'ÒŠ;w´²uvf‚/9J#;'ÆĞÂJa)q®l2Es}pFe*.'´Õ¨ÿ'²NPEÚ‡`œ³¬ÏÂ$„;jñ8;iÓ÷ÕËKó¼·Sz„¨•Ö€k=„-BhØG3ÏDïZ¢sç†gh¦O’(ÏÁ®KÆI‚õ´#‡¢ğQìb¹§(‹Ê#şG"6a¾=-ÌkÕ7U›³¡\¢˜xÉ»&£Ÿİ±r¹UvÄguÓyû‘ckW=iCZ¥µo	³v'ğ*w°C_/hÏFÏÅKßê,À=bKù/Y;€ó p&:|h\È(ı³~«­	êV[Qş\aù²ã•_îÃŸ³¹HÊıÍ!Ãâq-‘‰P†°³`ïÆ¢LÎÏKY¹@ƒØnÈ°wqr†5ÚÇ ÉÁ-¥4%z¼Vº!ı^~ªy¦•0øêª”¾m«çüĞ/ÿ¼„óğ$¹¨Ğúî]×bLµ®Hz61G™ŸÛ"‘×Ê„LAóCÄ%Ç÷Õˆæ˜›wÍÓûwò
ºÔU0ø1@<b4$VA¤
¹“e·S‹åi9‚¾…§kJ4‡Á0ß«79çÁ·ûEÎ×»¹Î¥ßèÅ.Qf¿!¹¢ŞÌk.@ÕßŠı$u/„ş"a0vË›ë»€ÙJ»wû\æ‚[_2i@ŸäV–H_t5|§V/@#×º!tš`i[I·»KĞ|¶jÖå³¯¸<$ Ùª2
ë_©ÓÌ¡—ëùà@){Ö`#û86 yQ8
ùU(#4ïËg,rNÖ¥Ø»ˆìoºNº—÷ãmlû–§M38'QERİ¨ÚN†üfÕ€HaêüöhçÅv™ú€*V‰¶®{´y—çœ©ºÔ×üt_ıƒ[O¬s{Kî2ëö¤DÛğ§šÃ°¬úŸ6*F[íÆô6? íŠûi”û•˜@ÿk>bUø(şîFR^ëSb3;í´ı²¸Ã!én7·Ñ~u)ˆõVäW°‡ù˜îò*Eù©%ä©¬ñR¥tVg¹ïM _ğÓÚñ¥bıºÿú,ßêÚ-5+œ<Ÿb†C`ak¸s5–~ywëC˜~rÆ¢%,g÷Ãà½‹1ltÃÙØÌ²˜ûğÉ˜Ïµu:ÿº(Öå[QÌBÏZ|Wi	#¯“Î•rhBÛEûä¥Å\zİ4 ,›]û}9ÏM‡•2%b$A8/µr5êp<ëY²”R’ú)—Z»ÃéÎŸşª§ë@ö	¢tÇâLr\êg¯Ò„½@–l¸—ÔÃÖ6_ùê•¬Â:!âb‰"4-Õó¾\Â²‰9õ?{©Û=SÃfZˆ¹æ‰¦±v%á‡á½½ÍbÛ'ÕZÔı•_Äyabô€óÿáyÙƒ¡Ğ‘—1À€Ò'Œ; %¾†syÒÆ”IÛÁï‰.ªšÂÿU[¤o«ŒşM[µ2“-â¥y(Cÿ¼uwzQæòÕu²‘å8AvQ˜jÛ
äíØz&Æû®´Zw	æ€ÈKÒ? ô“¦¤S«U}tP(¸¯nâ~h½£Ï-9’W¤U	jÖ/2­%4/~ymàÛy<ÉŞïrÿDHîsn"¦¾·_^vw2µİâ°ÙS27?gC ÈXİf1×Ùš3)™Hßjô,üş==²sË‹Mw*œÕ¥OG¢¿¢6‰ÎıİÙÓçuŸŠĞ‰íZgóy?¿XŸ—Ì’±ñnÄ9'@âuş¡Ğ‡§O1İÉ­Íê²0=²°"„}¬ñSÂ"(^j 5ºÿöz˜€Ñí‚Ğe} Ã6¦2îñF7èEÙëÁ'ÔWk^*€~ú–ğ¤tã’¤NÕG’TÁ¯3o>	lä™Â¹	öÕn‚‡ñìè¤p‰ßæõ¯NQ‚0™Å‚NŞ{ÛÉ@f÷ĞYi%Eè¬ËL»,¶NA›>øêêtßÌçÄ4Ç#šªÑƒ¶Øíüô†±¨s0ís£¶€T¼”C	†Í¦%ôæ%WK_.y™îGúx&ù!ß›ê	LH$“«öÒÎòË3ÀfÜÒtg¨0ä@9\è\†ÎÄãën¿­Ì -^]6Âš)¡P¹zÌM=È¶·¶&ô›H6m¥Bó#S_Í œ€;Hóî5bãe| ‡k]>•|1:ÿt,+Æc‘PàôöZw)çš¹ùYÙös?{n”/áÛ/è\ı6L²õó;Š”Qe"ô(¹»SğV¤_ÁÆd™öò>ŸÇ¯á˜ºÆ¹¸¤êo”»ov;y4“’-†xR˜eÃè u’Jô;Š ÄMI0=øy´ğÓØÉÑÀ¸jÂ_„ËgËÂeyN¤4—:AC‹íÈ8t–mô6k‰”ô«ö²>ÜsáwÒãxÂ&79½¨RúŸŠ§Ux«øøWNÖîµS.#û†Òmêy·Kóì_Xf+ z'•ÓEfxûì¥èğËÎ”Êê÷şßÈiSKCŠù ÍÔöéoKp•@;\z«YFçq •˜³Ê>>ô»„A[8›E¶7ò?D: äúï;;r`®lˆüëWªkÅ…©ÓÌ4+ØÙ>¼=+èãfBğ	ÀPîÉ“G¾µD¼ò©¸–¢À4½0¾÷ü5B}*qø†“ğı÷*´Jkéº%×:ÈÅ²İıl¡?$)uÙr:œG®yDœ’@+°]e˜´=ŞèX´–Ë	"Mğ=9kÅ;İ„¹ëMH'#ÔWisıúX]_ÍJ ëåSa*¤	±&'²:±X¡JlCÉGyØ”å·Ì-ZÇs¼İ–¹Tˆ…AÆ†x§T…a4ì<Nõ²Ç6cÏ¶‡€2	f-ÿß«çJë"miéB¿+l6 ·´î
=·ß´äøÔ.a¼Ë]<‰aŸÄ"§wFÏ2¨wnı:-÷Ô@ÛcÁäwTtù½ş¾dLË°Ú:?ÆÎá¥&ã&Bq8`•Ü 	äj‹&?ï‚]…s£¿[¹^ h`jµê™¯:§‰	QY<š_üiø<"fWûû"7¢š~çM6e¹D™~d,@K1JU‰ØA½(föÚ{ì¹µ+s>*_JtrZÑ‡'ƒ…ŞÒ¬D3=üãÜ&^ÎVYEÛÁƒ5‰ú/x.Ïù°!Ãw’Ú‚„¾ınSü­	¡ãş<ìMRÔ1÷×ıÊX§&÷lY´i‰ü1äŸ È*#+a^ğ®põÕ«W´wÒân¾ÜûøwîngG­Å‡äì·Ä‡xzŠóå´¥xì•½ƒúYø'< ‹‘—`ÙŸ“àò{S#YÜãVUëëÙ„;æfBáÑôºC=Šv~=jùõÙÔ[Rã{»š
Nñqx€A?K‡ÕÚ%»k¼¿@FSİzªíşlï!³Ç¾f§‰0ÂÕNI4q7¹üâØÕËºh,ğëâáhuù£òÇ5„oM
%;Û®ÌçÂZ@W×Ö/…R-ılÓÛò`4ˆÀ¥õ3šxË©²˜"¢?ƒ$¡CÄ¤·ŒÉôYÿò€[üoİºñ‘q»*Í’\BŠyÿçóY'S€&Ì.óû3±|ek=b‹f´‰äLW
—‚û‡L8æ1~ Ø,]{Út¬Eæ3H%r0î–$.DõåÔ€¡¯À&™œ‘,ß?%'Ä:v5
ºĞ\Ë)[ºÀé¥2‡o„_Ğ/Ô¹@¿¿ÆÈK)QåĞ{|0T“tÚ §Ë$8O3"QIçÎg±½vR°£gW`’
¦A\m>|*¹K6ä0æRÉÅ=#ßDô?îÅ™‰ß¸tÁ¶Š¨¦_%T»[éáŞã3â/vè*¡·ƒèä²”ZƒQ08ÜÀçÊ nÚÏŒñúY'Şg9÷‘7Ù¢c·u0ÄÜéÌ³or)Úx}Û”ı
…ö`qwõqˆÊˆ…ºÖ<Ò§?Ñİ±KØµ8ıû÷ç°[käBT”—çèø—ìFöF Í²wqh·»>kç½Óã=F¢½İò.@½á‘Õr
‚‘¨A}=,‘óú5¥6e½ı}·BaFELœªî’ºÇù üy„g“¸Ú”Jv‰ÈéÅu|-@Õ÷m;µb‚T~ÕaÅÄº—¸cPúUC¼ )c|ĞîŸñó:ÒQI_/v=`Èhjî%ªC©´ñØIUŸ¶UˆÊ…|QŞCŞôcIw“³òm
"“»Ö	Ûê¡ªnšHw&+QcÕËg1_‚•D‰ãEü%\¿d¤|ZóçøÕÀ87BÂäUÉ¤w@i³j‹ğ¸ô1ÆÂ+ÉşÆQmÅDjH®¤NŒ“ÍF¾&³Ó”WmÅÊŠÑ.	¬‡ ±–ßÏşú4«Å@Z‚¶±`qÍ|saŸb’´]äê¦I¦‹ÎÙ«#YëF)UäâM˜¥¸Çü°§Ù„)Ñqy
] WÓÕ"ğ BªNÿövÑúCŒº%ÂŞÀg„°,óÀ²İ~ TuœĞâÀó'Gí¢!r-…p®â'HPï/éÑ´äµùK¿æ\¿şü ºçiáŠ‹L2àdØØœM†$‚Š/Yw†z$šƒÁ{‰¿LÕÇ‰AîµÛ9MY­j³5h?î#ê®â½Ø@©’Ğ¾aşæí?¡ßcçT^*br"¯°¹#ñ-¯"£
,PÍƒ©ÉKÏÅf³fêM”Ò©ê *¹d3h¤íKùğ–£O¹\yö?fëîB.Í 	¢
QÇN;ÑveBe‚~Í*qmÏa ;	±w­âoúÓ~D²ògşT¿éRMÏ\c,ÅñàöGó¾Ä2k-€'VéÄÂ£¢ÿæ~¨\ú+£Ó@Jü
ßáL[ ÚYG²erÂ9hCvë¯¹İõÊU€1=»î%oÿ"º8óß˜”5<v´èc“üd	»İßU†`_şè8:Æ\ ÷ö»'Aƒ†õ ˆö&\koŠp;"¸’_ÜØsø#ç]VûÜ†¾)<p£¸QÒû/c•ğŒTwõ¾lâ<(b¢Êâ¦Ğ°w%á{ñ,dé©ByŞåšö£jooÀ7ŸÂ²ÑI·¥¬Z&ÀÁ¥çTKt—Ël’wÇ˜›ğJ¾-çqË4‡â?Óóz#Ê-.°¥¾púT£-×¹ÂéS|1^/Â2f\ó+8¡	Tn­Ó«ûe¡N³t‡—eŠ:£ëENoÀ‹™$¹Z·ZL€â¿¹Ò"PØıkó¥x  ¬š„ÿ€RSúeÜ¦í‚uãÛÕ	Î]“,ŒÊúr°™…Û®-•ğ/ğË¿Ó;2k!â'5ó÷ıEo#İIêÿa³æ/ƒ˜²Óµ# ‚+—ÿîÕN€ÇŸeÒ›U’3~ÒbÍı¡U"©ãlÓ“òİ4NŸYÜ[†qÍ€Ëë ®?KÆŸÛ	¹»N:äí¤2èµóÆ)Ó˜ Y¡øÛõÉo]¼ÀLórï™Ñ3¸c¹Õ·*™j¶(>†ÌÛ8Ô3ºV.KÕ›Ğñ;cX´hûv3;{Ğ²­'.6FİN€D®A3Ü²YÖc]æ$™ÎÒq)r…ô£Ú-œ^G$ÓNK	$.îŸ»>àñùó:YKÓûTt‡šÙ¯3ğ5hvûEù‚œ4‡d}iXãêhçİ¶J¸«şã1²	2Ş¯I‘w2^ÆÊe²,¾[|éÂÈvåQ†}¯Ø­$šf.ú ¦vÜı,a*{Ş8ÊQÉâZš_ôä£X9'èâlÃæøQ½èğ‡OmGlèj@ªÕÌ¦+—HÑ~3¶à“ d'–Lmé«ÓäÎ`çé´Åî§2Z”_Ø“sÛX'¿3ˆhÛ´-4ÎKG@X'ì¢-¥Ô1q>æÈÕå¢¯ë…jŞx—´*ŠL÷îG`s ·ÜÓŠï'R¢"÷ÆTŞÊ4æ:0‡íí‹Ú2;•:ˆïè˜r;çà›JÇ÷®O©‘´öh)µ8l1Şôî²—3ê¹Öémâ¨ÀÂ”è±N±´›HˆTİ/)qB4W‹kµmÙ(ÚìmàòbE6ÜQ-nŠ™a)uøÜ¥©òìNª\h«Tšõ×®Ò!ƒA)±B²tGWîºÓ^Î^}J€*„=dAó”àse(r¶×š{€Ø7õS9ˆõ„ƒ&ä?±ŞsF­İ¢flíŠ 7B®‰vZĞHšx9=¶",t'Ï8k ‰„=,¶âc¾r#›¦1QërQ Ú9”†‘a}Ù“g#[ü.“ûîLöÍäÅıüt¾ó%‚Ÿ]òÉï-Óy
ü~·kĞÜq¤ôZü‘#ÃoêÀ!o¬_D®)Yx,4I|q>FšªğÁ•SRlAOpH_àÂéˆNF‰+Àü›TµëŞå+` Z
‚­Rtƒ‚£’õ­EıÊ†wWØç#Ô˜İmŸ“;§ÛÒúûù¦©Œõ¬:“*F®ä‚§ô>"e¥ÒjÓıÜLøÏeßhÆÂ˜Â3‰ }GP>×S¥Üñ	¸ÈásÇ\ıÉñ‰U]ÌÃ±A@R»®‰a«šPÇÍhÙ¹p›ê=Xú-È³½7´Ú­ÛãY˜4‡Òi¨:¬  mÙî±ãÜü& —Ë€!Uà{±Ägû    YZ