#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="456374018"
MD5="1892a3a4cf17c4ed8bcd0fd95fa32a59"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23920"
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
	echo Date of packaging: Mon Dec 13 17:18:22 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ]/] ¼}•À1Dd]‡Á›PætİDõ"Û™~"TĞ^˜ë¦BÆ¤6£úGø‰cR¦š‹ÎÈ.„á‰8§"üT„Îh…Q}š6êøıÊ˜²¼uÈj‘²Mà8~² wÈ$û¤w\&{àzo¤UÏ¥*¯‡ØØC´hşxIlºdIA?DFÎp”­
İĞFæÂ€ö‘jŠò×ß¶_?şì†y!JtO\™¢¨¬ÄÌVº÷Ï/
5Çœ€»K©xêX»ER)Ëc²H×ÄñEåÉ8‚$²Åfú«·®4ëFK=U¸w°4¨¯\ëPÚ+?-^Gù_x[†E$‡ï×©·ø€ûz±¸úİš-öut“îoµR_ <`;G(D¯ïôkh_¸İ;ŞhôcB–BùğÛ_	2±Ê´ÈÌx )_hSOõ*¿yõ3B).&R„X‡ôwÍÍ2ÚMˆğ1Ñ@ãô0Âë9Àbƒhä‚R—*çgLA€ùÎ¾©ƒê[GÆû—3ìGË›ÁÄª´Ÿ>J+‚¦r›F„Ê\n§wÇóşPŠ-´òÈQbºĞ”6²v4y¯–œh–ß1X*Íİæ^Â^Jšc5ó¥è3qò7]bYfü9Ü!Yîı´µò—ú@ÊŠŒ‘^ø¢Üê(j~ãbE3O’5Âæ÷İ6æÔË<N ÅÕ·rŠz\üÉFTb¤£&‡Uº¢Mşö^´l*)®°r}Ö²2Û½k)İIJÛğíô½§`Åù’ga’°·vã2&¾ÑV$ø”·iú!œâ+ªïÏŞ.×¹Sù=£NU;s'‡™@VIæ-ĞÜoÒ‚ÿ¼Z,J;§N<ÎeVwléŠ=T	cÖœ,Œ; J°eÖÑ6Œƒ€Íjß£ÅS›gb/
sQ²u*FKêüm2#`Ÿ´MqÅƒğÎsÛ}Ò±Eã>"Ág{#t€Øº‹$D³Û!¹lÎ¤röiì¶4[~qB8:ÖÍ©fÜÄUĞ£Ÿ<…_BuHü@Slœ2œÿSkCŸà2rÂ§Bâ<ğõbn‚ÃñmFJ6dcÌÊ“°E(¾iHŸröŠ8:K1¤ƒôhèäA÷ÍÆ³· ¶‚£¼JÇÜÊAàı_+`?Œ Î‹‘u¬‡WJ’¯«²“¯à@`q=3euv·
/{¿-ÂšÍ¿S™x³\W `	ö]`=ò¹İ`éwÅÇöãî”:f‡IÜŠ7Ú1b˜ğZ”j¥5#ªs]©:3+¾•#±)›•uL¶ÿ}Öé«ÚÅÑ‚–Uh»åÂd‰†h°KŒæëôXÙ©pĞéô¿Ütw	ûòŸ{[DØ]LÜL¦Bó2«¯:ôÓaİÿ“ËiÍ”?'Ç¯×¾ÿ‹×`Qôškÿqİ²q,}·şGŞI|-3šĞ#-–'İû6.¬$RªYuÚç8¶‹«€pmEşÜ»&eÁ£Dªƒ°„NÇw“oâ¯Q+Óó±®¸08[<$zB£zˆ7KŸ··<¹`;¸
L¶#&–óŠ“™DÄ°¶¢SİO5"ëÜœ¡`@káWêg·Î;s'féjS½øTäø.<ŠğQ“»ñÈú-WˆîwOyZ¥ç÷4Ùl5oé™„:o´ŸI¹*ËèÂ©«Sá¦8í „MÑX°İæÍ Q{«hÔğ²XÛÆEVÌ8Æq½¢_ D@9›'j.’{­§GQiÂo i3¯î{`Ä@-(2÷şè¤€Rø×ù"$48on-d÷q f¾„7:.ëRp 1Ö£;Û6x´è¦äèÂâ‰(†zDh)P0j¶ÈgİÉO‹5$m*JêÑ¬Üø«»·±‹é·7íÍ•6Á‡f”Ø]ÍàïNoXÆŸÁ>"Ò^[ö¸0ÍÓe¿'èKfëÜ§m9ıW÷ùM€9L]¹H“ê”ƒ³||ÀkÀæDE„èCÔC×mqÍ=pH¦STNÖ¦ë¤°èjŒm| íäNxZ4.swnéR"–_‰ÕKßL­ì¦Ş$ŒÚs;—ı_{ïYíßJT¢:ª._@	bÚ@0ÁbªI|Y;‡Êx«˜[ÑdÄó,¾•‹ˆê¸m”t}M	¦õR*á~ô›İXÈÛnoÉ‡²qDÚ¤Š€1³›ÏŞ	?ÿƒq¤—àôZ¼ëM»‹œ‘T½ñqÜÚùÈl´I¦f#q‹Ö.z :•NxoY›ÈâæN3ŒàÃÕ	ÔıÊ/gdì-Lúî½ƒœPFÑ·¥…r²•g~÷bzwóÙíó-ß÷ûÊ{gÛë»ô³a|éÌæTTÌœ”?Ğ<ê¯’<noxş;0OeøŒ—¦`ùÃYEp3¢%Ú}“|#ë¨c?¾$]r|¡j–òÔ|D«­¡ğNşĞ‰¡îË1æ?ªfç ÓGı»Ø S1„¹tï‹„¾­]’WE¥`û¯³ÀÎùılƒË&ß%bKı¿	Râ''æK¨|JúúM6w -.8. vJ§C%†ßTÁ&õƒ¨Ïú'c5åE˜ \P¾–m‰ÄApÆPÈ–Y€]Šñ(D£‹4JÂˆSÑ*Î¾‡«Ëß ^Øî9PQBäVÒYóŞ“4£!ƒ–‘d*xG¾r¹€Ğ*ÑàÕe§|¸‰ 2Ãj~Ôôøe-Œ€}mOĞb©ºoyÀ¾Îljâl×BÆ~&¬d­„­·ILÖ~ãšéš:Ö©ã³sX³‡CÅìÄw©Šqæ×ø¿~ÑJÊ›Uè á8ÂòbóÑÀÁ` ÛñÇC'ÕiïÄ½ÏVy>cÚ]¾¢2¥Ó°l”ş)ÿöÿ1VÒ'âW‹¾D¤vŒ¢ÿqÓh*/ælK€L4ôÎ^™:ØéW|ÑÛÿ§nô±çêQôz`	Ù˜×;â6œğxúĞ	¯XL1œ}¸Ä—gáY²"
ulı‰¾$>rKEXù+ˆ9ğ‹ÂšòîÄ¾¥5ÿ"°oÛo¢AØÚd,ÙFi k÷âÁšRø˜AğŠZ_w&Æ’$E­¯C°™–ˆÖ»ÉPí‚ì‰1ã~ÇaSØc~T	®£’7—q$±¨³NHaæíjC"oêaòç…üö]HçS)™J±»~X3õ‰të]¶Vm‰ØA´ÅG9$ÒSÓ‚²Zë!ó)³Ø²‘Ü<v@ĞÅ5/Şk¿ZmùëŸ&=¬À-5”-oÃ•x…Œ­Cwì·}çûÇL¼²÷ˆµ‰ÇñÇü¥$®éC ™,ƒˆ·ÿş´jëù‚:¬qc‹±†5æåí$«½l•y¨±í³"V‹@D3zn(š²*rY¼qØÕıqs~ÔHÉOqK…º‘4‘»C^)«Eš­¹ªn‡Ê0=~%«ÖrİhÂEÍbÇPášd+N÷»…a½ˆKûAÁ¹ægs¡æŒÀ³µ8'ğ}ëê-o‘3`óòlª.xåê+§Tvu)ƒÇ#2&Ì¥j$è=W£71M‚ä4#ò¬=±æÃr—Ñ!t&&Ãh¤Ùì¿Ğ0gMí±f&´æÉüpúOğŸ1q‘=2×UL‰ûf4òly\¾İ(»:ğGõ¾‰H#ñ]aÕÏ¡¹$úø½éT;Å¯¼ËXãSTŸKmuO6ºÙYEâM›kı´Ô—r}ExRUlUĞm—î¿ö<EYÒ
y9‘ğ"mà"ŠB7Ğ?Ù±^rmÏ[}8ú¤êè˜~i;™C¿z¨©û_åG"•¤©1$k|"úŸ0E%õCñr¨ÉµÓ*¤P«xG%{t}Š¯ƒb)0‚d¬¨ÍOMjßå¹b;¥š;nV9×7¦ó“§«%ƒ[Üş+¦ZFœûo×³¿AùÊ£&Uº¢s\ÑªÔ9Ù˜k$Înâße1ß1ùQ{3=ò¥0ééÛaÚÓ+ŒÕ¼ªúğlƒKˆÖcâwÃtïú¬ëŸ­óx‡>Û}'ºl‚«7é‹Å+aÛ¦få0s3X5¼“l}úXS¯ü<3àÓ‹”mÕòI_£+âáËÊI,2_ñåæÁšZÑy÷×bµ“ÙÅ¾±´ü±ŸïH„…oÏğ®S¸äiİHÌa±zô²{©ZRg—ËÅc}êƒëu5gª ò`R½¥ºó3x¿sÌĞåçÇ 4–b7^ ßé­ÜÀ)×%E‚~XUñI6¼qºœk¯?j³|Ï-ªqõ•	TkM±ÙÑ²,~r¬°l¡uí›f\_Ğë—\¼ÎªuÉ’±FÙûJ¹¥o6=œòbˆAÿô…}¬Ãxz7‚qâ÷²“‘ÿÂm%bØöõhd¥i¥äÖCÊRÛÎV$Åá}°)Èï¯ë	kvæ0…µTîX½êf*…ƒzİNËˆÊïêD_Š¾“½g'îdp%P'Ğ¶¦‰5êWîiæ]¯Íßeó~ÔM}ÀÓkíBäxË45Æ^¬ŠmotÖcT‹ó@ŒÅæ+:zÊ0ïCR%ß©;œâjDóçôË•SÔIµP¶‰/kç%[½ı”eìN«ÙcósuŒvÙ,¥E™¿IúùRmù¹¼•I	€h[ËLŠ àmñÕ­7ğm¬%ÕÌ`¢¶dĞh‚¿²òmÄRıÛßñ™¨¡ùÌˆÍaİÈ¾\Æ3Ë?~TÓaÃ2œ+Ì$²&S7Âv± ş;>«è…H“µÒ|.A“ìJSÆqÈ;$ÑQÒ
W—7©¶Q£ÈVï£½Ø¡JQ´ïæˆîİAffFàÔĞ6}ø»	¶i­Õæ)­+·ß€±ô¹Lëù©ÅIUèflopÕ¶U~¹"AR—Õc3À¾¹6Íºx½°~®8G/bsDÖ¿7Àû0İuß}®Šù$ÿáë~:wØÙC:ôœÇ«Èò…#šÜÆ™ï¿Vh1¨â‘:¹òşÅ;éTTğß”Ruºv$£ı”òëRÇğ0W»:Ü:k)Ò[^gßCFVõ(‘OÇkÒm©Ú–‹?OêJ~›Î÷'[q
 H®3b~Ò
qPİ.è€–åçò¹G úó¡¿ßA‚:ü/Úcûãx7‘3ÿ$ÏŞ5ÈH-2xhïœ²3¬R1¤Ã‘Ö¢¥¼£iÖ÷•“wwû­öÛN5fXá@NQé—=–FÂ™@çäét@^R~"³\aëñØ0êwÆ¿ÓÆ+äbÇ›ÕÁ±ü+÷ôw¡rä*q™ŒÀ‚MÍÀ`Kƒ`E©;N1ß%˜ó¿$Z0Ò‚_åCdBô÷ä,/1%U¤Kv÷/YÔ2ÜI»×O‹A¨_ç‘’ôò"7zÜ¸™˜ìøÜ-féœ5êl‰Êo®B½Ïz¥GŒÈ¹§šş	º ı‹e?6
U‹pB ¿ŞÊ~şÓE(bJ^ B®õô€¼'9á¾ê,Hfñæ¥BmÄÜíó
ÕÈ-ş]½Ÿ~Åé2Yìˆ·\½2E9¿‚?$½è.©||‹ñ)Õ‘t…¶I	dŠÚ~{k‘÷j;â®é¾É@ÅkÌ9¨pÅ¾Çfštm¬HŒäÒ2»¾u¾‘Õ;}Ñ&SÈ’X “²×JQ"Û¶ ›Šl–… è0÷G€%Ûsî\.Àéîí*Í¯PÊß1Í™Ãdò8e÷¯¹N-¢ mîª(T¬W-s¿Æÿæ­Î
Ğü¡ˆtôFgƒy‹1¾Fo?Àhƒöª O2Èã®ó`_è>·kœw€´BÍıx$¬ú´5i³hù	õEÃ®?åJ–¨Î‚À¤šÊÛ0oAÀ¯6BÕµëMZ1‘sì­•^CÈ£A_8F˜Õ€(í1Ş„]^;^coqí“’­E÷¬C¬P:ÙÕ"Äc/QñÂ;Ÿ¹#¡q"öZÜl›Ú_a$û/Ú`@`hi”i@úª>‡'BÍà;gœW²•ìïR)[}€ŒzÉÌ©÷*Âá~!t—s(– ½‰¶1E¶©_¬³ Ji´ö+S¡THÈqYx(¾úìYŞï‹òJÑµËåí¾'}Ë¦—<ô-*84•;N)ÿÜ‘GßAÓtAƒ´†…	fê,¯…Ì:ó	ÙÈS-_EÒªÜuQßZo~Æ­ˆÖG½Ö‚Ğ¸*wMHÙ£²Q`°)“G:‰åJ®ù°º,é¢36µR÷6öÍBÅj]¹ZKn]TU&Û‡~DIúø+‚!cÈ£P–­¨HéÏB¥€¸[ÒÃ|iÖ eä–Ò¦ë§	ŸÄ}1”5ÃéŸü|Ã‚„Ó€N³ñÑBkèB™^í‰ñÂªéÌ<ƒ¡Ãë ñü0QæP% E\ÎSe‡¢q—æÒGáƒO&¥ˆEÜÔşUø
½À…»Æ,'ÂaZ{y®oûÓ
;Ã[øá„ó[“‰¾(ÜüdÛ3©ö¡T=f>qLÍÇ?!ä …Šíñgò3İ°¹é2Ç& ÈÎÈÃr¹K¤iµ’á–CšÁÆ&¤ƒåü.¤UC!ı$m@XÖr.J?‚o .(´àÒg0:°ŸG ç5Ş7'iw®ô]>(ƒ€š{oœNÖ*ôĞ&?Z:™,8ÔL[À	ã!_×{bñR7»Ê\ê]‚ÀPA`¼¦ÄWBY°’ô¸ä¶ Ää"7?»M¿¿œ1’îÙ”ÿÍR1uôqçl5Æ/\sû&W¶a…J´ß„‰G_TÑ,=¤DjŞÀêã~ Aìè1¥%&¥Míˆ'íºÛàv|?xÏÎq Ôö'vÍmĞ59 Ë­4	²E´C‹ÀWó²Í—0³—~‚ŒRä¨øéë`P[®}7RŞ´·cXİ«	÷`«6À_´Év£-àÎJæ«ıŒ¨é¸öW„æ°¢Yy:ÁJ	>YÕòd7Ú… {áõ¡ÛÉ˜½‰'‘ï~ÏæË(§Ò`Ì±[8ÄaÁk
.,ãœK»lG{ÂIŠ¥eHü	2ËFırXÇÍüˆ~£ËÕ/!Ÿ¦4»Ö·Dëâ@Õ8°Ÿ$õÉ2Üoƒ±…jk‹°‚ÕĞÑÇP·âÉ¨j6_ ñ|ø?óiJ=WH®êRa„>[ëáE5{£"›oº¦ËèfóC _šùd4LbçÈä­®ÆkôqŸqxƒ1ï[íJNÖ ÌŠX)dú•ÔüX#&ZNqêhÁµå¸À™ç‰óÂì‡1ıÃø& ÿ¡ß=}§ÿ.DÛâøØ#‹8ík©9³±Àçà­\èzu€³V1è…ã> ¬Üø¶»XN‘™È„w½Sk IûÑ@âÚ‹¯’m
\ğbËÜƒe¸òL:Sl`3„mÜÆ[;}4	‰eIkãpä¡„‹²½Ÿ	ìcò|ÇÁ¤DëL`¥2‰A¢XšNÈ´çrwô 1éAŠæ6ÅŸ8MUy ‹™ZÚ×,ğF(ƒÕ§ı1)©"FÆ_½2uÙ¹ºY@òìaÈk ór2dMÚ êœAŞblèÕK	Ãã£ ¹O¡X‚Jşm¸ÅIKÈ'¬ { ‹P‹ŸfN-¡Å”~D]?¨’„–U½Œ2ğÊ5¬—¤vñ+|Šø¾ÄŠ†»¢öb¯¦ „?BBwƒiÁÔŸÊZçUú—_/®	r•n	6}ª%ºnåT€„ÆÃ_Ÿ¿wg´6í[TAªØÇ~è®*ßç«Ìò8ŞáˆWşí@pğ÷]£Ê¿ß²Gå.ÇÌ®B³ü¤ËYÓ–‹»2{Ó• ²ÀŸ"ÎÉöÏI€T´qì‰vsAeèŸ]iBx	ÊÏÎ[ô/ŒÖÑtŞ8òËq}Qwû¦dÏIÄÂŞ³59‚•ÖÙ9šÚ"á§ğ¡Ÿo†¤1?;W\4¼•0,á!âDz=bÓ(Şøÿj8´ØÍ¨Ãè¢È2¸oÌhÿˆsM¦–ñ|màå;”¶‰ÿDÂ9W¨ĞU`ßRT»zÒĞ~f~’à<=e! 4	.çÍûf]î† 7Ì³‚ÂYZøfÓÎ›öÓ(,DÓ¸
ËböÀèœõ (‘Ğvn¿!4›şuûİ>*ì»‹˜^é¨©–óÊ§„jÁ#"Fd»tıÁ!;Z@X"¾Ài[;¥ÎG«ARÄšÙ œÇÊÏt–H¤AF/¥ĞÍa°B”u-H5©öFwc·ˆ&-Õè{wòU§,ÁÂÌÕ!Lr]Z#ğ_yI!Cë¢›:›¤˜¸õkÀá#EÅ›hÕbc|ù5âéGäÙÙH<4Z~ÌôV]l¶'órÎN„£ÌÌ©+b}¨lÅŞ4ö\PnhØ•Ó• X,¾ÉKš}HOÇ¤o»óÒ3‘½{‰.\Å×Úï¼	8óıÔƒÎO8Ä ã!L<
˜6Œ‘)7¿ÒèJÓ——Yü!1ÛàÓÆ#7Ò|Œ•`+nLdÚr×»bI,šO?EkR“cáVjó%KÎ5&i‘¸3ş]Ñ*Ò]óº3è*Üõ¨ïüëşTõvú“l:Â•q;ÔZN±…9­åC€P¤¶ƒmÖÈ»LÁ
2ÜA7¢×ö8¯ƒœo¡&Ú,?²‡y
ôZª‹ùx>£õ7µ€ì01bËÛXÖ÷x¶áB›Gí8T(Û!lÈC~Ì¹+t}š¹¥ˆÃØlŞÔa´b]¦Ï°˜r¬^zšËš’%#“ií «{N@	S\Éµ?tId.Ö„GÈJÊÎEEÙû	F^³V³¸.Ã¯¸ÂµµEL1ìe(R^]¥Ek+‚[¬`¿¡•ôÜŸtÁ½IkLY3Y†Ù•‹hO8s50·^³Zó¦yxYædøı?Æ\Äœ)yG†F{Ì%x{Ä\ıæ3U6_"ÓhÒt&ÛF0ş•,È]Ç¡ˆ)c‹/^K'Àİ)!h$š‹G6ØèŒÜÅÉ§^"Cj¿Yw£;!ªP&UITkä˜ÇÁ]^Âÿ&HÀ¬EæÒ`_¿Ûa]Ë5T,g“á:`/¶ò´ëÇê?‡Šøƒuœ®”¼Fj£§Ï4{DuF“”Ÿ„Ë]öù×Äİ/ëGz„mGCà^TŞ-Q9hÌóê‰åKHŒ5Ä’z‡Og¢†–¾ı÷y®V÷)ll›Ó¢²"tÖ´ån¸éHrô^..PP<W–µxİDÒ[>Xj½ ‡“~@¡ë·˜R%ÖGu'÷¾¼e—£¤÷Õ¨S–WØİÍóÀÛ\½_ü(PB‡ßòZÄbq
-ÔÎãDİÔ£™•íM¥,ƒ¸7u›g<ÉïäÙÜ'õXÄ'1ï_²ÉT€åŞu¶»&>ƒ;ªZ¥zËM„Lb¥	ëK"E>B®'Dn"°Erç@KâÆx€J*ü8\™/’™*!¸¹ûûØ8‡”®)~…•òõÌ¾—çjqíp€Ú3
²G"çå¡Ù'6tìnJi^?)Ge‡ò>Kß”èÚ*yügö&²R²«U^¸ßş‰3@ğ»x'¤¢ó‰Õn–„ı‡ ?·{ÛØBó{®¹g¹!œ#1¢zJ>†·Õn!v¼íP@{3SN?‘ÊôÄgüŸÒj®£Ù„M2Ãç@1ÔÚVîã¤.ûIÚÁ»›Ô¤™›û„C|àºO"zYÉ¾îE¯®-İ zGêmš{*ÃÂ<2êŞ]£Z¥=\¶^ûµ”µÓÁïüzŸÊØàRyÂ\—•}‹Ç¶üTKÓ Š›ñü@¯ñú áÚ¼ëÊ¼ ªµÆRìµïWúê\­µ#K•†„¸¡Q`:ÙO>°Æ3©nà2#û/ÔO¨Ö@ONPm¶ºUË/Û(œƒLzÉ‰YÔÖ¶ßË4ÚPÜ4ïD!çáõÁ"æ¦Ãé”U&‚{ŠàhA×5Sj¯‡™±ŞÌŸÕqÍ¾_ÒIï°¿Ö¯óID#tXPâ¨_C'ìç¹<zİ¯ÿ~‚U$îÈRåd–K^¸v¡Q%4ñê“¼»¨ŸËÖò%yáº×ëªñB†+ ™ïü÷îíÔŠÜÜD,ÓD‚Â±~5ëµã‚$b¥¹E@¬OäÏ²q|¥àî|_=|‰>~¥R€pì›tİ«d-£~~‘á+i€ŒqKI*a„‘‚€=ß”ÈµÜ<ùNUÅê•T¹AúÑ(?{PmOó²,_–²åZ‡S’Pİã.5Òëhl¿©EY%!S'«Q
˜d–Òó`•ô¾0eû2¹WÍZ«}ÍN~òï½òÀéØ
›8‹}êŸò~ÿl,”qp1…y”{Šİ(ÚË;—ô9`¡z{Ç6KŒŠUhkï/ó÷çÕ³˜Ğc\·SÈúyî†˜5§Ë$nª(+¾S	bå6À¤0°£ ·@ÍY6Ûë‡İå6°ŞtVMv½"”’¶vÅû‡phyN¬rÀ]`H¹À®9ß·ÁÌ«Ÿ1•ubjAø‘8i= ·Sj·nÖnp¡|)”Rö„ÖÀ[®D»2g±ÆĞ¿ÊÎDãÿl6Ç³	GN=À*/sŒ°oI>Õ/ñgXIç¤4®Ó®"ƒíì6É™ÿê ¬ÁÛ€q0ıZçY-¾„¨{â†pí¶r³µãŸ€×/0`æƒ¼µ\Ü¥{O$}|Äa¤oÑ+ÛµëNnˆ“ÜY³XóÛ´ó¦ª$îï•’Á˜—¿¬¡¿F¡IúÍÈ~íãxr>(„6UŠkë¡—ƒdkà€/•ç#‚ß… ]Şåô×ıÖuBè”Áº~y4€u‘· o™|÷9$?ü;×øHÎ05\=}ñóç€m|é‰ì,@%î’YÜZ@ü¢^Zº¶Á‹ë¶¿û„¡XÉÂÇ4“tQ\ª`sin[>Õ‰ØıeA¡ èpÔQÁ¯™¼ªõp;ğ:
kİ·@d%q¾3ĞëØgU<Á[1Eñª•)wtz¤­bu}ƒ‹¬¤õá€
p}¦è¬„HÛ!ÀØú2H‘å´.¢rB]™p”9Øksş”0rÓT‘~…ÑW¨à÷5”0äâ>İ^Ö€Û¡)g¡š×½¡¯­kªu2#@l‘GÚF'¦Ç“«.Û ª2Î¤â`Ò²»/|îLí§2>gşfN¶^çLÕ~5	˜Ğ+Q¤ifZV´ÿ³Ê;âD²ò,ú§ê|D#Ñ¦\óºPåHbÚ¯c¿©ş–ks_C)ñù÷33 ÿ±—´Tç÷È}zç¼Áwæ€Á‘~ælSIÄ4UÑm•WÖk¢?[mBçM,$«È¦òåbÆ.Ù_K±ˆŠ¬.‹y¡­viĞ–`±§™Yï+µÃ%…?Åˆ³Õs4vGŞ-½”XÚ†<CQá1¡®JL0şRgh’ì-Ñ`é¢K­/¼ĞúwOô)—J˜î]ÎÎAÃAïs­ËNHÌşnˆö±N€Rım›€`˜N+Wct†ï	 ^ÖÔf®§¥[Q¹—ºìGJäˆÑx0ÌôÕh‹æÕ.6Å·?ŸàZ÷cR;²Aû05~Kz‰FßØ.òmr><(ÄmôŸ©–Ù¬Ÿ*'\m‚%ó[*xü°ï»ŞÙÉ•–¾í'•§a¼BIşí*VÙ.ù\>ş@ö‚üığ/¡G»é–æ5B&ùg†øâb²ÔhØâ-QZEóéãÕÁãG‘VO¤Wê!j'ëÏÈİºVA>œ|J,·7Æp†q81î#5ğcf#­ÙÜà®1î‰kPvO9zøÜ4ø~QNt¾ Äp­¢È‰„™tÜÔ½×xôı_cŸé­jr<Ò¯N"»®PÆÓéS»€êß‹e×@ÕŠi2yWóP½¶¾êF™„ZVçÉVÓ£ÃW–?”³”/N3¡^Ëv©©ï'ƒ å¥ÀÜ‘›”÷ñ:›¯£·¶HI+/“¨Fñ Î`ÆqÁ]È}¤ûPøyQä™¾·mt¯TH9ßÀ•g*Le˜3ˆƒÎ/dŞ¸t1¨Ü½Î`émô'38qÌT_B*Û=×JÇNÍ,Æ­ÇJÊHEzªíÃÍŸJcNò­ğHµ[Ï!Cè§2©Y¨§#}À^2ÿ¯…ûM¸f;›F³ãuH#¦¿KÿæÖ¼ØWÉ0A´$¬Ë¤kË~Ø˜Ku£vsN¦ùÛ›ıÌå˜øÖšÅ¨Ëöf’'Uè+ë?’Ò’şlÇÁv°;¬Ô¦×ĞÅ8´Àu†ˆÅØİ{ÆÈî¼<íW®]KÂ7G.¹½+ñŸ
ÎÄÀb[y¹+»©mL‘hU=Ì?¦sÖşmCk0¾½™½2)íş§€B³ê»f'q¾,4fo‰°ç¬KéB¿útòd£|Â†ØÓ#²T»8B×^QÉxHTnùœÒQíEj‡î‹"j½†êÀ2ÈÙq¡õäË`ØˆÍô;$À ‘Æm|¸6ËËMo$à¿*ª_õ
#òº­};pØ¹l®!0d$Îßö8}}’òsüÎğİÖ^ëèvŞÄøsy·Ÿ@ÿÂB¡'éıÓèËl*Ì½u#¤ÕÚ iLÎôêœ>á»á¥ÖU,#ğ\"‘×Šj±Ú:{ñ’âuÅkML˜ª/»@ûAât* ,Åm ú±,ØxùS“­İë;ÛÜ}£9è¾NsM!I4À?;1Tï.QßÅ‡ª½lø%‹8ÊPú?€4Ş–¾²l'_ŒB>C2Y ½‚ªßm¤‹m=>g/^´+ciK–5Í¨ù”›×ºãå`'UtóN\ÚÕ”á}	fÕøH_¥9ë¨&É™FQQËÒÆO6Şè`wr÷:_cf(xÁğîÚÁ~Ît<ñG)²^ïÅf*Ä øn”«èğ
HûõZH[T}Õ?QyY§dÊL•hyx¢rÔ÷Ï“[éIû¼ÓiÚ»u(Àêšnf‹‰H¼8©ó¤ôÇã-¾è‰x¾Şı31A‹~ÓÄÁñÌ~ÊYşG—»ìêÙTóoo(Vrâ©ø†bŸß2uq¾®¬5è
ËÒq¼4°lÉlü%Óğšê‹Àaç û‘gš_X¿;:<ûöMë=(3rKà«fô6¡Ác:äR9›ñöšwxÓb ËMÀfd’-œn‹î‚àIƒíİçq´ÀHèşV2 Ïì¤©¸ÇŒ‹r¬¶£ Û³,Ğ‘^K¼l(I€(bêËì`E\õQP²Ğx¶ú&0ÉñfÈ=ÃW%"½oyŒ(¢v;•u¿#Õ,¸ßZJ´Õ»ãË!¶ºàmWB2R?xQ(Zö¢âj’àDÁÒ»È|tæ:|§»/_æ?ç š³›<z~Ûæ>ûMâÔ¬ª\‹úOÂëk¸ì‘lxHe­a·Æ=n¼ìlPÿLş¿ı
¯ÒF¸wM`(úIå
ô½”Şæ³í Hq'À,XtÿÁœÉ5 ş÷!†>æU€UÏëg&?eëŒ:BVoƒ¨_Ó¬B!¹^c>Q|ÚØÄ¾ë²T `2“–L´uj_7Ñ«Û·gá¿Şh“D0XV;ùâåô$IºŠUÉÛW‹åB;ÿU^e•¦má5ô°}¤$—™*àpÉÏTD˜Õ•“-xß}d4vK^S9n¹Ô»¼%	nRÂV‰&MY=ï®ñô?Ioï “O=ƒ`ÀT©–·5Ææ×Pjb¦1şL~i¿urÜx,âöà ì¡¼
)ñÀZ!ñYé·`1ĞÄ˜]œŸC6£¥Elí†‹É’â*L7š}|>÷hŒ0Zq³[1‘|V¶Â8oSş¬ìæ3›L/aCÛb»Ï\âwé<Îåœà¹_äÂøfÖ¿ Eú\¢` oò«‚RÙ„ ñÖ‡ˆÑ-Ë¨ä
dÿ«‚ĞÒ*®÷öÿù²®\úÃ?f&˜£«IHàÄyàÖN&§“Ğ.1Í¤VÎĞÀ¿YêÅ «ÔGJwíz™5yHµmöØå8®ï0vp4l:x4·_»šÎ²Õ‹å%¡2¯5”-ÌH	ŠN¿6!¾/²ˆ¹ÄkuAÉÿ%’Ğµ¨#€åæLoÄä—ü,™{‘CÛ”8…ËWWå¬<Ç$Ke‡‘±ï@Ğ1l›ab¬êSöEO»Ò>ğåâ`Læ{ˆ\Á3õê2£^åTKôKr×U¥,(¡N¬\>ó=†¸ïÛ‰›óéœõÁct³N&ÍD)
êi¡†ß°²*Ï¤ƒy¢uôM€è‰|	 ‹÷Ä4«@Æa¢ĞŞ®k
5[è„†8“Z1§Ö‘Làm%–6ç,şÍ)=JÖˆ_QøwU˜"u´öeæÑŒ„k­Í6µÉg)½aG7ı 3\·ùQZ:.>74?ª÷}vâ9Ê4£ŞÂJ3$ã­'p|•t¤ºN9¥ÊÀúB2û	cõÊ9+´YÅ ”t¯Åµ\kĞQnBèÛqf~™ÇÇ·=<¦šq‡1i‰¼'«ã<©FS~¡â)Ô!¹uÃİşòXÖ¿ƒÈ½Çà?pñ|‚–xåÍ$)F9gÙs¥Úœ,bÛfD: S±)ª×ra®† û–ÆgùB}‰`‘ÿ…/#ß†³/_éĞœÔ|IIaÔmùÂ›.k_Ã-¶+I¢àèÏÕjnÊdçšZ1LBJ	§AKd\qmÃ-Ì~¨éª0]“VZ¸°1Äšë!ÎG]¦¹1•ü°etŒ!•biaw%äç—8í"µôU¼QÍØ…‰IÔEá/0¡Yàxk.½õç-ƒ™âàBõ¢’³›æ¤“owdÀ=Xç$˜[-¶ÁÔ‡¹ĞT–>JØúŒûÁÀ*êùì­oÀª”ÌŠ™¡©t>nçrãe%Œ<§DÊëŸç4¨ı\À›üLŠÚ^„7‚jGòs'’ÂP7¨èéQ.¼Ú¬äV'ËmÇ¡(
€›¾:ˆ«Í‚8bá²‡&a¿,McZ¢hû,œ•‹ªÉÍ®6‹:Ä÷§í–A·tñ¼‡xKÔŒÂ›&8ëd”&>tü™Ù†ñxYÚÖ¥n¾ıA#ºXÛÏÑÔ]±:¤á> 5©áäMJª¶x;HëoI@_ŞÒ¯Q’ÑIÿêWâú®˜—OÛtçÅ¤Îgºu—ãåqüËô×O)PøZvì°I¹¼]o-ˆŞÂ]ïWi ƒÃ`l{ñ<Š=Hd›–úàœ|‘®ª	6çÕ)^-¢„ŸB·ßç. 7‘Íüd›Àñ6•¼HÏ÷–-Ó‡Ûê¨|ŸdŞ!o ıCNsV*}3wG
 ŠÏiïŞ«õ*(mæ‹–uVÕ/ŞËxÛƒÁqªŸ˜y.S}—Õì hÁd(‰C¶Q,~^oûªĞûkÍY»!¡îy/)j
JèN#ƒc¤aÜñë›‡Í'Oó¾åÌ1&+"%æâ]¡š5d!‡ùHÂ¡µ\lIH¸Ì„
ùhxpÑîLqÁ´\‚=™„úˆ£.Îu;ô×’t,V¸s9òÒXŠ*ª.³?À4ˆN)¿•s]®‚ĞÖÍŒşªËôh“V.\’¼evŒ@ëpQCÓ†=õ°™¶´õœ$•¬Îèn$úé ´dhÉšÔªfè¿*áõFw@²n¨šq­vÚ„—t+o8id'è¦8å»œ†çZ"‰ò/n”!²JŸlæÅ ˜À,8¦Rß¥ü½å|–Ÿäwü<ç:«³é/DÚapËFRúñçsXÃPìû)1fljs«lt.YÊŸ2F¶†É"*Å>%”D?êÙM`—¤A(>Ó*.Ï Ø­ßL.–í{¤™K¸©×Â_‚†<	Şî€€¨ª?¬<BÑG‹p|7W*&›qŸ|ıä±#„¼SñĞÄRÄ©
¥xíööFÉSºLïDgÃæâ`ÙiŠâÜ·TDµ§˜`,È„#ïù,J‚ú•ŒÈNÖ +ê`o¨¸ª|™gk£ßÇë€ïPd˜s|Ş\ñÅiM9ù™y–âÀ‡ttˆ\h¢9¹4K6$7¥»·/şh+Ü7¶²{u@Ic¶¦‰i“q)¶§Ö(*7Ş| âGÖÌÒ“?¿÷{õ^ƒÉBæ¶%N½ÏC0æŠf,OUËè‘¿¦÷¼^áì8ùR¿q.B¢õtT_ñ¼Éwùmôn)ğ;ÔÈ›$S8ß›ælÏêvLRoµŒ±,«áXÉå±[zĞ‡„@ÙÙû€ı@)Hú»PÉ÷ÄNäÑÁ)›²Í-4âÇ|ö”’±uóu=¤:ÿÃEL­zZ%b†ês8şc…(@*?Ñœ­ãñ3J±B¾¯#‘õw¿èˆJè:EÑúå)b¡üHÕW„`Y¾¥ØK©ô
*õ‡›çàªôèØé¬HvÌ9·ÏîÉ¤ ¨{àe'~ˆâW¼g È$ÍSP#âõ´{÷7ğ#xd _&8>µÜ)}]ªÙÖ'Ú©Ë£®iz.ŸctHÉÛ»A”Nc%½Işg3pk“q©÷à»ñaBÙi,¸sÕk™óSåŒd«ç/ù¨¬Ù·\T	‚tóÜ)ªwöšäÈ]R2¥ÄÛÖ·;—BUè]Î¦	m'ÅX`ÊÛ>ÕóÖÏ–µ>MU<~¶¦ìÆÿúˆ¨ÔäzÇ/Ü\¾éZÍ˜"¦<«œ³a-U„óGT*óèÔÑôG"O¯(@êŒşßVèwåcÓÈ¡è×C+”Vœ±u'iÛ‡’Ş¦—Óvårk	Ö^bµÉE¢bæ0—¹>šCø‰z5CËZD"TŠxïM°¿œÕ¦‡çNwy“¾"éU~1ù~›.…ıd‚fò™Póân]ª9h|”^Oî®°^Z+ÜcœÍM/ùÄè-C™dU%{wÓ`áQy…ı/×¿Mê
`Fzg…‘ï|®†"QD‘0áiõîñ.U2èöÀ›®/KQ•E$ŠTí^,hAœâ]1õ•Í±Ä)æ\eíDZ™Qü»µé3hş­265¾I!“ù¾¢¸´˜OP†5æÔs‹¤Ck×¼ ¾B¦ÁÓ8'=Dì<²‘9[ rJ±áÏÉ,Ş`údG¶maÛv—L7‡Ôí‘©¡hÒA'êÈKÎ]få$´Í§/¨¨Òf%%şàÌ×Y0ÙÒŞ®P`
õ"?ë«—LY±` P—ì†Rÿ‹Vaâ“İ¤ˆÑ…İ¨è¢ßõ´-êŞe„«5ïöœ“®„¸
`ÒC-|gË%ìëÖú‘ö›wùàğ‘_Äø?uãå0—hÎ	èŸãÖÒ3pÄ·ó§‡’DIİE÷è-¾DÍ2u÷ïV.Iñ(ìÕÕŸyÚº…Rg>:H%\T -ÇÈÚsÜ˜LâM¡ÒGËõ¿ŸúôV7ğ¡»ëb£ÖdQİ¢íªcÅ…¾cËY¸ÉşÇPóVĞ}«bìÔ¸ø$îH%]†ôe±)ÚO)|gİØ;Ñ1^ñ6ıƒvø‚m›{ñ™gIwŒq:›7Y÷¿+~óÆnjšµyvÙ,‡t	ödrW<MüR/m‡t1¹¢]_Å_=ÛšÂ>UUrï‚^ÏŠûvêş²“7‘dçµ3Æ4!«BØGÚÔ8á]=Şæâ%$‡VŞ- Éªí‘H¨&Z9ÛAJwÕnÑÆ5Aå•8õó²êBâ®Aş|P%µtôÍ„e4®—'Kö–†Æ†§é¥|ShuB‹Ôî–}´½¼üLEcAÁ{w­ÊŒ®Å[CYš‡»•ıÕîù§¥ŒÔw cÕÓó^zRı{Z[êß‡ÀI'3{¤@5.g/Tû-İ‰Ä/,%®Ì,úwp¨èıWø:óš>ÁÀàÆû	|¤v[Ãñâ”ù 
×ÓüĞ4Å”(ø°Z…z…5JÖ|)x­g1ö]zıÕ;¯ödİ,¨Õû)*¶ãœ,®Ğ9=Õ(»­.F¦«/>|ûÊCZK]£^°¦8cX™º§­şl¿ó£3•Gíl)F¨TYnÜ1–E<HæhıLO`¸%[Šg©±ø•[ó±ÏXó€oBşfkótS‘½VÏ%…‰!.!J¬*íyEŞ~=ªpLã÷mEç•<aJ< >I•œ›!ZxøX›)ÎrHûó˜\¯n0$¥¡ü0ÌLª|uíè®œ0ÓÙ3Ø‰ƒ¡n°¾)61ønw> EQÕœ8Ş{³ÑMQ»˜¦×CLDÕÓÈ˜öÛtƒ‘5m ï[’!+‚¾REò+Ò^%ù@&W+Om7³‹äß¥Â©UDqÁ,ÚqDa7
Ğìîµ"\ÏëjĞâìÀ‡KKÉfãR"Û=½õrÆG,º©müÖ¨Oº/ ¨>ğõÌM×çÔug¯ƒ2»w¾cú·y›DgTÊÙVáB¼ÀD4BQ³ˆ>’¨[· lœã;‰Î];‘ƒŠ®Y;õ/hpã)”ymÈ?ÆÍ©"İgmõ¸KÑ6íùÿu±jø[Ïü-Œ¢ºƒ¢a€fù¯ƒƒõĞÜà§]Cv§=éT²51ã]¼Ñ,ó™Ål9Œ*³/NÂÒğs«Ğ ³¾£º('v€HËbWôÆÛBˆõG]BÌBÛSº¹_V ÀÎhµÅ²ÅÁ¿²VÎ
Şz1T~­$üHuÀÿÁêBB`«õ1lcD?ë€³â›‰.ß)å73 
Õç“Rîl*|Ë›è¬5VƒègDR¼/‹–“&Y)éÖWcˆE‰wQôÄöLªÔG’Ù/°÷6òÔP¨¨zm&ª‰ÄzÍP~ÃçŞ•(bxkP¾½ìå¦ Ìo\fúj!«†Rê<¥¨'JD±æ€™äNÕ" K—q¦N~¶À5ÎN}adUÏş=ºœW’?±¼1TóŞ¼m7#§€lupssÿ¢“ÛìÉ¼e÷’Ä§9Ìİ66	"bË›¶ŸSµ8›Ó8c4ÿ™¦Ç×İíóŒ¥^rú¡–QBÖf¹E³q­ß=İ:OxçŞKS±”Q³ï¨|~Ùt&N)³|¸,`[{ş­µ©AÏ­ˆ5…İ>âaø2…t·¢˜èNçêğ¨ ¶*ğğƒ|“\<|}ıÃK'¹jê­ñÈ™ÍA¨ßãåï6ìÁ‰Ô‹Í~šøõ!ÈŒC¨÷Ûºãºüºƒìáq0"É‰GŠÃA&·ŞXœ`W]Íÿ¥ó¿‹ïè	,ô?[BÅhß€C68ˆ×;„!Í_1HR	çòœôñ`‹¢öÚŸúñ»]¼nq[Öø*­=lc:¤… vgôÍÏ¢"NIìŒìè¢¸Ày Q©ğ{.lif:;>Ó>§3Ö'Ë¸­ÑÓÚ™ñìÓ3ˆ85Ÿ_ıu'ùÓ>‘	…¦´÷ß›°}pŸŞ•Ô¿¼ªæÔR§İf<ÙLV‚Áäv÷6§{œÙ3Z×›Æ‡¼`Ä­¶’­ùùQN&3Hóè–+zQZçøèÑ›iÂ'ÏíTèùDPCåp¦Pºuõó/¨åU+o,…ùUÙ't©Çİ«şmº3-îg†Šz…štæt†s
Å´o3xHúd½„½QÑ…ûôÃf¦ú	?xİòö/Ì{¥‚{ˆ½|ejÊW#ˆÂqfİ^^ÆüîRX8p<yI<qîC"½ò'Ê'h€VÉÁ\yö#3é„,Èæd$ò?7!IVÄª7—	t¡XÆµ7¾–ÿVÏ)\p<&ùj”5\ãb ¨©ÅoÛXÕ¿õ5PG,¶ùÿ:škù†á‡ ×y·›ú•aŒ½«x¼$Ê0›¤ÿyÙòC’JT'Á\š¨àW¶€?N™µNKöõ‚	6rÉÄ³®½2Ò”?†wËà8ç+É(;CÙó.¶$ósÇM
Ä‹mOì¥+Æváµ³“û`¸ìcƒÛä~ézÒÒ¶¼©ß$Önv^•¹” ¥~üQNCøƒ¢Ø{¡4vÒÑBB>6 xm¯§!ŒÍS§C?Z£t	{>{HæP_:zQä‘&‚¥¿4ä‰”Â.?Õş˜w×†¿Î8èĞ ã©×Òªô£Ğ´,îå­	D‘uÔp‚Ş<Åp¯MátÈŞŠÿÊ l-¼»Zˆ(§ğ³‘?{r+!—)ilGô`næ3Æ#«æ(•1ók?f§4,é#„Ÿg._kó”ºZ´«Kr/«©¨N;ƒv‹q•˜ö¨ fíŠË}stZÇ $MjŞùÒ6¯‹²Ra¶¯É<Pİ»Ö3rD^‘=?0ö‚‰Ñšï{?d÷R<}“ÀÍ.V!Xì’T=æç¿á…˜&äCq?ô^£n^«‚¤¡Gåòf˜Ì«fJ{œttây˜Q†ô‡“ŠEdA¬àå½¾½$#	¥Ğ¯¿+iœ”[ÀGÙ8Ê·‡^Ë®Ø%o‡ÊD½€"àƒ$·£ÎM_ ñ«|WhI.'oim˜¹â¯j—P°‘1İKÚ	bWë5?¨‹IFøÒ¢M€ı=Ö2~®Na+-šû|í™ÈBàø>‘Â3€†7Ë|{2jœşÓ';×µRÍp?Ïõ:|ğ°ÎTù ¹E¼æÎ=\ĞCú6MDLOéP¨²_é¬PjQ{ÚÈÁ°¸Ÿ9Ú¤šÄLl‘óëámÕCÖ; éD†Íl:WÒÇşø:ÚœŠ¼òc(ç2å²"ôòœèìñ ³¦’w/x@†
??ÁÓ9¡Ÿ„yErjZR!L‰g­«2v½­Œ‘ye‘øÿøbj>tÕÕ¶8Ì± °ÿûÅ&(·8½©Ú68[ºëÿ&ökíG]Â^¶²åöº²™ïtJ“cxyûˆG÷yûÏé‹îéÍà"…èØÿArÉ`2kVjxlÔŠ‘pÚŠg,Ñg¾óöÌGj1æìàgédy1¸r`A;ó¨S<×ZgeÚ#88p¾ã7å¡ÆW×ôœIIqÙºMëYr{:b¤_`Sİ€h	•Lp’dâ“:[‡æ5A¢Æ/M“øÛòND±®úÜØÁE=xç½AqÀßŞKŸâan[Ò‡Z;Æ3O¥€Õ–IüÌŒ‹|µÉ‚YŸÍK|„ªwwIá[à*rg@¦_c•¶~4öÀm¿Ú¹íäÏ”KÒ¿”ndÀÉŸâÃ’l;-0YîRñ~$‘Áq8·)ÃaB¶¾åº(/óÜCåówÆ6n}x«„F-»²ÉZÁEÊ'Á_}^j›ì³ÊÆ»„m0a­:àÇR×_újŸœ;DBŠ4å/¾KğÏäl èöùœµÖœœõ5é4¹Tw~î-È¢bÉ8Á¬ÌUa1EÙŒ½»7®¨‰øU2ƒœ¿?è€Àˆû€®ÑnªiYŠ16„ M{ãæÙUÁ©%ga@8¡Ç¾¼ßƒzæPN8dç¶úô*Mù7Yî;1Öx«ñH«ØxÒ	5‡Áè¹ÁÅ¿Õ‹×ì ‘‰Y¹S()?*År{—¥ğÒ¨Éæ÷›û«¤$='Igë.ô}¹Ú^O,<GøÅŸ:<@öx´—Ú˜İkzúB°m¡}²¡'R\<†4PkÖ)ÇIAÖ›„qÉ2yËm·œ·yí±¨-:sQ%ÿ6{¥mÙ 7Ù˜-±wöÂhŸ9ã„R™ôfNéÉuÁÑ§š™šBmĞeÌŠ«ÔJÃlK¯ƒÕìø99*“oÅcR!.ZåÜ¦j‚GŞ€d!µüôQ_7y¼Ì:…Æ¶›Åt½ÅÃYiŸã	@$Ú£¢ó!’ÅÛ(#ïph`LË;2-CiEc’6= &P/=˜‹‹Ù§áGuèôtşúÒ¸èëU3^ÚÒ…ª¥GÑÉŒYï5 0(¼WpKì¨Æyìh¢$Py›Î„ãÕÎæCm®Ç¤`h[7zäY¢ñªkk,ZâŞNk??aµ Fà´¤² GPx¥òÒ0êˆŸ¤)ª#¹!9Ğû=ÊÖK`jM”®À¯œgİN·JIÈpÛItıHç‘AizÈëŞ³pğb´>³Q¥zO‘9‰¥Uª>põ¤O­ïÂç_Œ—'«Š9ôeÚ‹¶Çä¦—J¥Å•Upû€Wq±º%·:ñK›¥/ùvÒÅÜ+³€;„fÿ²ĞÂ*Õ°‰ –uğ„F?`¾Q<TK~;zæ‘6Íd‘{õB‘ˆÀŠ épÌME;]¤å§¨H·Ğ˜xáOäDàXyr6´š¹Ş~âx˜1øl"îôı×ŠmÒQß;|š+
Œ'ÛPÄo·'ö½ĞÌÜáOs¢¶Å{R.½Ø]¥˜¡—e¬uX¢vßØØÌ†¤‰òHı€â?D±;ô†Âñù—*=`_¨§
q‚	µ‡!Ôv­]òƒ&öb”ÅGPÿíG÷È¯Æ=
Di.ÚA#Ñ²¸Y[\d×†£rBqÊš ¢«ıº®õˆ±™5 ¿&z³!Ã²÷áƒ[” a·×ƒj¶Û&„\@Şt ¢*¹RÉbß˜N.›dâlGÜ~~·¨Š–öáÀ´¬ªİÕD9ñÀÖmZ:0õyÉ¥¶šŠkêëñ0$İ˜+v)Fm}ì8
4˜¼ñkÙy±ÕÆj’™qşÃÁPÒşlúãÊ7œËx˜Y’¶P kƒ­¬ *çs?Mnñ.Ò.6§ÔnúŸEwp=¶àÊ^‘©(!g¢Ù%äd§™Ç4Ì0«ûƒ›´$ğÌiÛø¸,h[îUeˆÿÿq\•ºù×Cıñãœ†I8PE²¥ŠûÜ4Ní}¡QEè¡!Q/T&íÃash³¸6ö«“JAw+pUÜ	¸7¼!?0(0÷İIB–&±g¡O^ª"!Ñ‚XCæ-ÆšuU¿' ×zqwgÜ'!¦—zâ&½0õNxm´­§®Ÿ;:dİ‰!:ÿøbÌêíÜ’TµÄmSİİdgŞP—‰¥„x­R	HìA¤³ Œn;§xÛğöE)·os„/›Gã½˜sTGÏáKõOÂİ'8E,Zú~·L££¤“¾…ûE^ÿ ›¡.f1Íü+sÂzÛá ]q¬ß›í ­m»²­ıeû.Âi«»q#wÊ›šÎÏŠÅ/^üvÖú–ÎÑ¤æ'Ïæ†:xø©½vT®<5™¹/GTLì½Éq¶¥Å4ÓO/è…fQT¨„\¬ è)_‘ˆe}3ÿS°g„“{£¥nÿ¬ÏŸş¤H†kÎö_1Kí¿X`Â&8ş„µ¸Äb†=*¾+M\¤î'¦2È„[Òwó¶jL€¤Õjz:ËU1YvWƒ°­v‡#D
¤†èÏ®öP¼šAÓÖQS]©úÃÂ”‰«ª¹p~ùÚ|¨_šÛ{Ó;Â~9qšY½[×‰Ç ¾£+U¤"¶Jäºc×o|6›{µ ä._}$Á».Gİ)1“èÆ¤]şı+1¶·˜Pšˆ‹ñ*ªwÆ—0 H:½J½7ñOÀ*Õ&ªô¶å•P8JqÆC‚z¦qi½A¤şƒ®	…•k–c˜Á¹Ái³­#¼\İ?ÑÖ…¸„Y'¹­	pŒwRû´ğYQl×¹©Ùú¬a×]”1Æ-piMoÊãšY“¸-‰¤î«kÆüTíÀˆÜÉŸh
Ï¯ ?¥½o”âóì°‡pCœ®×U]÷®üû’Ôq}ğ!ú*PH;ş¢1£‹F…LÑ’¸—DÎ5®ÄŒ
Ná¾}×2îÆ@2Ù|Ş€uÁ^²\?5¥WÃR.9çc‹~Y·cù¹ÄV	|L(e`Ê„Î'r$Z¶*ER°~IsŒ6‰‹™Hc¶ŞüÊ÷Âáh¨FÓA?Z­°>¬æRŸ×—?Ş¯ş4Æ/dIõZ$¦ûØ@Ü² AõG¨?“¹ö?h«ÔÄ¯'K¹\US›b÷U˜»ë©Ù\ 1ó lÙ	€I^hº/¹ÚßÒ›ÁavQ3ØMñ8Z¾N—Ñh.›-Ô~-cšãg¼ÃŞ¥ü®-ŒMG'Üv·Å¾Ò7…™Å0ÀûM¡dãHxÎî¢ Ï«'$V,9¾T%Ä¾å:Ä'*ÚÔ‡wùP´åœPW(æêòÈ™Y–ö,d¹%Ê˜ºÔˆiBÆSÑUy‘Wş‡{|qNÌHY€Ÿj “ “±ı¸àUCÇ]°9œmáqİ!Ï¼íë©±PP·„±Tyß‰ì8Á¼6ı‡V*·t—5Á‹¨hëS–¯õIôÏb@O/ˆH¨Dá½İ7kï\§›\œi£õÃöÛÿFU÷µ9š_÷¡º×¹¶eéïIÓ1d½éa|S‘‘EK–~³NÿH>q…Aû†j.Øôı|íí¹“ğaÁ0¨ˆwıü†}Ÿ²?Äf_ş4´$0ÿh0U7°˜Æ™1å™ıNñxÓšaI.m²R0İ(  Š°˜aª6ò2û¶¼å?s$?(]3—ÿ>Éø`Ä4ˆÇõF»ús!/q> À	8d!0zÓEJ*yÂTıb]¼vÁS3­;^YûÈ“G?û?ÙÎ±øùu/¢Àã7§ä‰b…7áe¾r„cÓ6-ğTUÌ¨¾XmQÚ-ş ×e÷Dæö®ck+¨25	šÆÿoq¯2R]àù©bÒşÜí0)_S£é®Ã$ùI¾}Œ™è+p@{>Èy?çZKt‰èÜL˜é’zät0v+w¢Xh"-ÕDŞZº³­_DŞçG3{	œ“Ó·f÷J÷÷éX'xY³RCfšê•Ò¤Y;ËÅ£"3W1¨ wB<£K¨'öK°çj[™¤FLœú¶óBµcÆv÷äàWåeã¸´é)ÖŸ>›.51!À™À2`ÛĞjsøgÔRc·8ÁÑ¾ˆ˜lÖ¿>r >ø§[‚Á¾Qœ¨”±p‚¾ˆIÃPV\÷´ƒ#¢Ôë©ŒˆqâéÑ±z°Á<(ú$Ü€æNˆÂÒÎØhE¾×"ÄˆqM~ÇA8ƒ>ì+•ïÆgßÔd„GÅÑS¾G—=£°“,ÜZExäô{
ÑÜG¿ÏëœN¹÷ÒÀ6Å¼P
ÎG„3Kp¿Tùƒkº£FHO÷®ÙjP]œÜ,T_Å~zkrlÌfdéªºìíÃç”şì+ÍöywfIÜ^À,-:9á4¢2ôÄ2d`z‚ÔU_åï)‹Ò~qff«KQúîèX|™gy¨TµÌà˜½”ş±azuèqØ.FÑ†}1×}«ÍbâDf
gjRH6"_Äæ:á·dÊ4ıUuŞLb-“o²~‘(yş? e?²Ê‡”©®á	mÌ+‚x&d3|ébïâc¢JF¤ñîZõ~¥¨Â‚[Av›ùä³ ğÃë\ _rÔÖD&ÏßO…,ã¬	ÌÀ1êºÆ)£ò#t±xI§Ö´ô™]cg™7³Šh¡-FğQ¾—°İCQ[+Š=‡5›Ë–Òe¢½h|¹hc%¸Kéà’ö©Áñk×÷HYÜhîÍ™ÃQéÌRê”ló-æXéà”Té”g[Æ	’u0Ğpş}9v'Üq°v®q?¸dí¼ÁN	/–FÉ¶´>ND­L¤¯3m`¬#+rØck¨V.Åó“!©‘åÏş·Ù­@3"â„t·ŠJË®¼ˆ³%;ØÌ¹ÎTÑNœãšºM…<ˆ‘jmé5E5^ùİé”µ´?ò7ªá¤gˆî¿šïÆ–Ÿk·±—0-Zá½uD•–Òœ†lÑ0iq… 
¡L?æĞ"^ÕîòåbÅ¥±6wRgÕ<Uö‹6dSËYtàkÂ1UîNhë1ÖjıXân\ÛÁí6·ùO[PkáøhM©¥Â3ıªnPÕôš¨µªz\¢ô8bÿ»®—™^2 ¤Äú-r&Ô¹›é…å7A¬\Fz˜¨:Œ•@_BiíIÉ#¼˜h‡é‡ºAyºş}œ°†2â`	e“é(¨&ğ–ù9œJJºÉÂ<²ñÆ­a]•:€æw¡Z÷ó³³qi%CrİAÆ'áwü›fû‰˜¢¥Î9B„n·§ª±ç‡9b$û/`“Ã9ÔXAJáÑO•ŒÇoÓD)İùì­\>lr"àÂÅÉ9öxdC’™X	Ú^éIx·SfS`/S™yAíœÒ€Ÿ *vŞTÈŠ†D©vüJ}:—*‡
’ü9ß%ğÂ¨»¥0àš\2æ<‚ûƒj¾Å±‰j_Œ 7‡fy®–¥ĞoÜÊ“B~±Š¯Cr^A*â¨ù êàÈ²¹~Üp†±j
€œ[œDHO¼ó>Ø¡+g÷G;U'ug0ºóduñBüüúrµ§Íâ¬üJ½ÑÔø·ù‰Ÿlåû­1gßhÀ¶ÕÎL÷Ü#Î¬Üe,9nF+C§ëKöó¶Ü»#îmRfilêÙµå5­‘K‡ò;•}˜‘Š×´bqZ!QÿÙ—Û1«òGA1¬	®Š
’˜XÜÆMrQº˜ ÅMuWÈˆŸ°GûNHùÚêS1O) kÍìòı’pË9æÌ.–¥9Ä¦.ü+ñ¿éÆ¨‘XŠ÷›³käGÜö
¤dÁÆf°â].bëwGşV‘P­Hàj4Oôñš†(\8¾Ğ5]Å¢],÷÷‡	ş½˜®µ œ™ ÏVŠ Ê4DÊ1¿Ú<ÇşM˜‚ğ(B‘€`(úµw"ûƒbÜŠèA³Œ;khUôÛULèôÅˆdcö³_ºğ#­e ˜<FîN¸¢ÙO—´<BÑee~9Ğ9İêÙOöÃÓ„QÂ¦Z*44!Ï„/J(\$«úÊŒ¼öPS—ÖnØäÂQXù¸Mt·a.ƒÄ”F²ÊG^À«³àÚØƒsÀ}Is‰8ttóŠÏSOÈìèa‡hµÇÈ¶ì…á)øFçŞq;]	J¶h£ºCtM|ê5]ZEN·şï:à¢i¬şÅƒ7¿É®'ó„0ıªs
 “ş$UàR•ßÎä'´éŒ¢'#‰¸RdâøÀÖO@ÚI^Æ_€ä©®U©Ài·Có»…+Ğj8w1¤T|Í†r‚=¦§Í9bUáë÷Øuo;O=û;EùIÈ‘_¶Å5?^´ín‘¶n›GzéöÅÇ¾üŞN WÑÃè!÷giÉ$·¡À x‘`³&«ÏõQa5N°Ã6@=ÖJ*8Îeı%MŒ,g£èo^=e™9æú‰Nº|m¤ZQ2l‰|=z–5¨,€¢&\³r\j”˜uRŞ<«JIA-ˆé¿ı1…CÔMuH.Ì9\~ßO²¨ƒSÎX\gk7’YƒYQóî…ÑMNòPJ‹¼F@“…Ë‹?nÍ#»ÄawlTZ¬l×¾äOa½=°Í#‘Ëû¾;/‡LpÉD}Dá_µáMÒõÏÿÆî•ª‹ñûTù‹ßrR‚Ù~¡'l…*¾Dn¢ÛÖM~4åæöLÆËÅçñ7,Ã"•ø§P†fa1Cäo—.òùIIÓÊpÏ9µÎ9 0aC[{c½QE÷,ñılYC ~İ¯sn¹©cy®|Â¶X©ÒeÕŸëE.[¯Sş‹“ÁMi7"§²Év•â £}›œaË¹º ×¯¦œåb*¿tè¨·-{×êlú2`†ôÏ“B•_k²Àá¥*8añ5gS6.Ë\@Åƒ«M6Oá¢bG˜àéÜÑº†Y\~8æŠd¹Œëg©õğQ‡:%ÄY­‚M7œHyÖEYv‘\šoâ25$¤*¾ÂC³ÖJ|ƒtìAe¸ˆ¨¹¡_¦ñÍ&Ã{KÉ!ÖZNÖGÀ¥ÿtİ,ßÿf±møSœşZÏ(w&Î´²öµ620ñ'bi1I›Å>¶ïæD§ıVA±iAuÈ¢~ûq¨y×á¸5ÑoîËâ™•¼rŠè=yR“ì¨ÿ¥Zù–Sy†×’1}¼X•İ¢T“µˆŞ» N_Gs˜ŒÆ?-zE¡DLPà©v‰¦»Ó}”ãêuìªÜ_cÕ}%f¯Uwß¶V€şÉ2ö	êjğg=²KÛsfÄØ,xø¨çœt¢å}v©ÙÇçşg%lLY dí•!¨Ü&î…².N…l«¿
£‹éE&1F×ÛÇg+@Qe"lMIg4"ã7D¡ë ñ3HR¶¢ºåİ±Æ Bœ½w¸&§ *Ä@¹ÜÛlı.9£®´ç=‹O•C¸–{b£ı§˜ƒCtö)ªßz#Aœd¬U‡OVªùŞ	w7èMğá=İ«µ1Ş"[I›ëÍ×L-¯è³ûq°¶l´M²pY×ZíÇctÎ}„»(	
íŞ§lÍ.ØsBS=7Ô<{	ï¬'PÊŞ
¹ÿ|Â“.FF6Ñİ_‡ë@Ç²® HMÉ†M·Ú('‚JÆr«İbT|á«F+µ>³ Äo5íG™\f¡^Z£Q{6—ˆ9`ªæTt³®çêŠ¢è=üÌm	pEa¥à3D}†Mÿ]
Ñ>†;5¸@ŒÉ¾ JòGb«bSr YÊi9Ÿrä‰‰–f/ƒÌ‰Û&³¦á\B¾}7æÕ3K6ĞgCûO"ü£EğbÉ@åcI¼”úZë‹-11VÍfÎTxwAŸ Jv	Ç©®ÁÆÕ;Wõ]”å³)£-ù`¥@xtâÏê¼¼ÆHöhz´u¸F«w3/è>,¬â!ì´`gó÷)éP{i›ÎçjY!îÎ(ê
|àQ·Ë¬Â eÌúqµçâ´pGšÑ»ˆòpç©fšIŸó*bÒ¨´î¦}ÁÇßiõ?ûÆR&"yvî IÏ'‚S±¾Á«ş%ÍS} %<iéêO?×á)“‰ª£KÄˆÁK¬àğÔGj¡v7ƒ 3ØL¹)BDå<ĞèåŠÍÜE¡õâ½^µ36ÖÛü¢ğå–CD¾RÒ{ëš;ñ¥—>±ŞƒÂœÔĞ˜Õ|BG§cswÒ^” xiÃˆˆ‹¢¸×#xàï6Sñá]-¸;O,”M¾
¡˜úóV6@¹ò†pGoqë0tÙÔ¿!PMÜv#î½²÷13Â^>ålóI÷Ø÷æjöÚ”ôèÛPBùkÔÍVÁßèŒp[ ñ’å
‹°9™t´ÍÜ>ûìã6ÛSnŒoE"AwJ$~: añJÙHHç-a¾õæ	WÓrtßŒ>ˆû( ”gªÒ"Gc^ëù€ƒàolJ¿f™pœAËW¼^A]t»„õ¾}Zç”gPU/ÿvÛ\ŞšaóM‰/Ëœ$„¢Oë—¼ÿæ†I‚p6–Ã)Wªw¹t”S.£«B)O¤;ô™ˆ;’šãºœKç­îQSÎÊ3Ú ¸å…Ã’nõzˆdˆŞy¡3]¦À(ô)ŸèæªüÖI…$?õõ¨C
”õzEŠìT)¢ù-	HÇWc#â˜ãªía8•Ÿ@+w?øÈ9*ÓIøA?Øóäî”€ï³Fuí„¾¶®Hj'‚$}ı#[Ü ^-¯ÚiÚ=­nÉLJXÏ·h xÿ¢6gÄíTY—$""Ï‹etÿxdˆySƒ‡X{"§Cê¿xR²ËŠ8¾aóèSß†zÿ( kÃUm¦Š½–›ÓÆ!©¡¯!ùì¹Ù”o—ŸòI½pKnÊ7(â,89±Æ•>ğf¿ª+ó8c¤/Nğâ›Ê1Äç¦;Ù¶ïi§iìÍs‰X\¿…Zæôª''1ö€›ÚÉDSœ¢‚
‡†›4XgÏrS$6|S»AÂcyTÒ“êãÛ}xG'¬IH7.½îrá¥}ÊXñİMıÂÎ$„N1uyk£Dz†â­ªxæ—L¶oæ>œƒ¶-j
8Sìp#nŠ¨	‰ím8¾©ûÄÙÔd½aÏ€¢;L"²b‚
ç.H§›¯óEú¨†uDw‘RIL`Ûãú3Ùj”,)—jQ)7V,—AÄ=z#reldSÇRÇ²æñµáÜ¥k~~”™£*U“MG«ª/Æ=.¢îà2Øu˜›]<|Ó$Ë._Ñã‘ZzhÍm´ó€âû“¾Û%ã¾$Šr_{TºÇo8ı!Æ¡}©v#»ĞJ{½êF7´¬_lêŠ­)­}àûÚË<0`_¨W[í\gğB¬'µ¨{­™lkù¢
¸é}=  |*Ï]úÂĞÄºÆ@Á¿Vê!J›†Sà­Z)ò,Z,a: MK×ş9öë²I.ôjiÜ–ó÷%ÍÀ=÷l65„ÌOcS„Šá¥ğPªãï!+:ê,½¡÷|úÒÎ»îøš ÖŠOåÜ&á.úï‘Ìû!‡ARŞi¹q†€=L^—Éü‚Ö5J{£€Jİ±k:/ ıYú
r×óé±U¸ü¸1w&	ÅÚ’¬RZÉşèÛÍjànoív«Ç~}3 µ#Ú›7œ»ŠqÃ|K-d—
HÇßĞ•:GğÀ­Š¹;âZs´ï ¹¾ní]jxÜ›‰£ ªh¼ËÓÿøjhaèÑJkyP†¤bmğó¤íéH×h,éĞH
'–Ü ÕşéG³‹ÄÈ³]áy¡µuD„¥œcÕ°hÊÚ£Íî}\G’½ô±z}²Ûô_ı‚•\¢¤€Oø¦ò]hˆİÑ*‰ãñàò,<8¨R–½ñ°C7ı®   Œqº9—7‹  Ëº€Àî±Ägû    YZ