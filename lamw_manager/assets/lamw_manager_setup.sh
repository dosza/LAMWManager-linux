#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="140931668"
MD5="97df49b0e338c771cfe41fa11b17973a"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20312"
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
	echo Uncompressed size: 128 KB
	echo Compression: gzip
	echo Date of packaging: Sun Nov 24 03:11:52 -03 2019
	echo Built with Makeself version 2.4.0 on 
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
	echo OLDUSIZE=128
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | UnTAR t
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
	MS_Printf "About to extract 128 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 128; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (128 KB)" >&2
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
    if MS_dd_Progress "$0" $offset $s | eval "gzip -cd" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
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
‹ (Ú]ì<ÛvÛF’~%¾¢2G’¢nN¤ ³IÉŒ)‘KR¶3¶H4)X¸Ğ%Í¿ÌÙ‡ù€yÛWÿØVuãNP–Ø3»+>ˆDwuuuuİ»¡ºúä‹6áólw¿Ïv7³ßñçIc{woo§ñlÛ›[Û[OÈî“¯ğ	Y û„<1tÇ¹¹îcıÿK?uÕÒí«‰­;ú‚úÿ’ıßÙŞÙ-ìÿÖŞÖæ²ù¸ÿ_üSıFš:ÕÙ¹TU¾ô§*UÏó’úÌ4tƒ’95¨¯[~èK}—1—¬7-[ÇêoHÕ–úŒî“ÑÌ¤ÎŒ’–k{!tIÕ—ˆÈuöÉf}»¾-UÛ0bŸ46ÕÆ®ºµÙøZ(›ù¦ Ôøœ9+í21ñt? îœĞ;s}Š¿{Í“W0=ª“ñ9€	48@'W¾îyÔ's×'2á:¤˜ˆ’UgçòWá¤D¯=howÏµÍø±9<irí©7àb&'ÇÃI÷t4nözÚÉ‚æ"x«?ìhrÒ~6êL/:¯;­t®Îé¸3œŒû“Îëî8mnÁ,“Ãæè¹&£\%(j4ŒÏF ,U)Poút¸şM‘ï°Í>•Ì9yCØ·ÚàU[­×"“w¸sT)'‡Áü£+ j›«:nsÏßæìäÓ;"ÍMi5‹k¹Á%„K¤„¹ È·fæÚ¶ë(ìœò­‘PŒ-Â7ÌİñMƒ2	šÆÔöL‹²õ["Ub^©í©yèúÌuæÀ+dñíÕ °ª;˜°uNg0Ö`ß‡BìYh¸Ä¦ö6Gâ gŒú]6‚v @ªÌô€¨4˜©ß=òW²ğ©'†E¿¶Ÿ‰jĞKÕ	-+¢ºö'òF6ãİ„ÅT–Å®!Uu|î#K_0>­C¯O|:ŸÌ¡˜ß~™¡Õ¶`‡gç.Èê†Ó"×b¹œ¢r‚’ii×¹Ú-~©j‚V½#U ·Å$pxÈˆ;ìƒ3á7X=¡¼ÉÊR¾ó‚¨ù4EZĞàÔ©uÒæËd
84RM¨,«a-ùM”k9™m:y¢øv­t®‡V°!H3İaŞ©˜$ƒO.QÊÚÓD©²:_ûÓÊY®e‚6¼01#<_˜ŸÓ» ×tF¨sIÚİÑ ×üU«E?ÈëæÙøyØC[ú›|>}‚«¤–³lEöraò|ÊPv—Ğk3 õz]>ğ©n$~»ŠĞ™¡BĞâúqÅ|¥‘”¢p‘\¡¤R%•„XR5)›á¦X67…•d[ycD¬­›NB©„Oœ¬.C=ºnPpŸR%ÕÄH`åH ó}êäX™óy~Ëü1…IíŒ„”®ÈR%kaœ|XßŠZfcÉ“ÇÏêø¼p`:2‚88 F=¸¾@ü¿·³³2ÿÛÚzVˆÿ·Ÿíí<Æÿ_ãóÜ½B›2š³IûR¥Aúx> -x„–U~IªŒ]Å|è÷Ü°aì¢;Œ¯äSK1 ôˆÑşÕI^
ı¨˜_Mÿë¨ Áärÿ#ùckk§ ÿ;ÍGıÿ¿™ÿW«dü¼;"Gİ^‡À7Dmı“æ¸‹Û¯¤Õ?=êŸ;m2½ÉGI0Ò‰­ßpqÃ Â“GaşÍ÷d
Ïº™$Ä>>±]Ãœ›“@0Ãø¸)%–Ë‚z¾,°œß{ºÏDT—UŠ	á¡W÷CGªf‡D>Q1Ú –i›2
˜tî\mı‚2jÍ‰î/B$‘¹ïÚ`@ĞÑ­ƒè˜Î÷Éyxl_UãauÓU¿NQAJëÙ¬æ­òV|†ˆ•#Ë¯=İa<¢=×c&0^E™›>ƒÍ™ÍBéPàL¼UÃ~à½îñ:‹"å­~Ø=Zå¯iÿyÉáß¬şßhì=Öÿ¿æşÏ°ğªLCÓ2¨_gç_1ş‡ÍŞYòÿ[Ïıÿcıÿ3ëÿuk{Uı¿(è<È	3×	tH}GÑˆgZ8ûdAêó°ƒø¢˜øE<*hO.Ÿ•4›ÃÖó½…4ÃwMã+9v©jĞ€ÎbÜÿåÃ%so¥qº¡Ç%ƒÁz£e¹Ë÷MıÒ¤¼X©ÛS^-¬;W¤ŠåÎpMLæÀ­¶T‚MÆBZwh°åa†…üXÏ«Oå³iè!iüP—Ÿ`RÁÄòçÄ¡W“L¬€ñ²ëÁÖ3ğšœ@E?>|$eúLJÈi¤dl×7ë›y<gÃŞªÉqDÆ.úÜ§ÙAcÕ]M*pQôS}jQ@<ÙlN6å&À2éu'ƒæø¹&«!óUËœâ@UÍ€µc0ä!€(œ´úl¾(¢vzæ¨£É÷Nü²3uû§Z´Ä‘¥Ö2#å”ëˆbçäÒÎƒ–´sï’ »“x×?ìM@Ó,eá„KëJ
üU. 1¥™+/j†‘O!ş¨:œ›¡R,ğC€‹.%¯cßwê›=øğOĞ(Ì 
8zÉSŸ„6‚/3íé‡ZæÌåsWÜ(~nï™›ü‹XQØı‹_üér×Kø½Š½bŸ1U´6ş7£»L'/P]:¯;`v®ÎÍÙ9rÛ¾ UQ²Ø6¢J¹\Ë’‰Fdyùì¤s‘£Êª©6×Ã–èpı¢H/UyÆ›œ'pOÆEò]Z!ä§Ò2 á
8Yœn<<;}AC>ÆQXìÏ±–em«¾©LÁ5È	Ød®v»Ôöí[åé]utı¹;ˆLwzİÓ³×“çı“v®Ct
Ëc>HGóèåé¸y|ÇcÉŒwõì^ÕAë‹ßä’Õ%‚X:}"—·Ë½+Á†G‘\—âƒPˆ¨ŠƒÖ-5åINCmyHhä!¢!Â*«G4+7& B1ááŠtˆM-Œsš¾-NyÏugAÓsû¥…Šİ"%ë.U°¶Af`áÑûŠœËÉüG\[&­ÁÙdÜwÆš°?k²b . ±Ó“I”ô‹ˆŠ´†ıÑH ¶<€zù¬I”ÖüåÑàå¶Lbá;Gİ×îLEp¡Ê—1€+…4Z©¤w2âØ?¶:‚£/r`ÅµVl4~!~3½˜%ò` d%Ù{Ï›]ïqYvÎm8\¼Á¦=ïßé€‹t|ßõ÷É e™ıW²êS»=íOš½;™«eBÀY¥’%–¾œ›ÖJµ_ÆĞ¦òÛõå|%T%^_Êşe ì™}äe\Î¬V2´‚"\‰Šö¬.4ıÙùŞN©><Ä•lwf· :Ÿ¿DòóÚñühIÚË¨»O VŞÏx€<MJœñ¨GSÁ’R±ÂMù(3¾´MøT.U?mûäl."Gr¼ç‚æËÑİFøÃ6‘;†xQAVnaf’ØâĞuƒQàëW¶ø Ãæ"ôRŠÚ[™¶ÌU—£^óxrÔG£Ù<mûİö$’£Â‡,NaÄã57[¬újPÃcgS»Şş9ää<</™’Ğ—ó¶$¢°š½<›a× ÍÆ¥Êˆ¢˜ôÙ…¾ Âã¶;GÍ³Ş¾Qj[/â„İtzÍ/½Äa ©İ"ÀèM÷½»ûäµæÊ˜ÃUöûú/¿fÄÄM¦PÃWö‡•ï¯ÿîìbÍ7_ÿİİk<Şÿş\ÿµ±ô«è–­ÿõ_’\ W¢óÆ‰`=xH™ç:ÌœZ”×v9B<èÍ]lTÅcìu¢²^W«×¿ÒqG›íÃÀ=3è%w„x¾és²6:;ı:wN4MÙTş4Çãá­i¼¤áúwĞüÓËÎi»?üúNúí&oîííÁÃñ°I»g…À+¿uÖù+„”ŠÂoˆ÷iı—j¨»%
rê¼	i`Ô¿Ä+ŸH|^2ÀYÌŠ¾¿ÊwƒbM÷ÿš—.JKÂÒÿÈÖØèÿ–à}°*|à7˜sÔ²Yx6»ÊWzˆbĞ(êéÁ¹¶º8¦¸y„€¨Š·Êá‹oÄ"‰ØC,eÏLQ¡LVHÿ',ğµu¤I®v`í$òØr¶‚QßDSÇQL,^ñˆ3ì¨öí&Õ§¦uYµa¿? Ä«q¡z–€jØL •Ú¨6TÜ&0Æì‰Ñôà·aÕ™Ë¢Ævwàºä][«åDíÔT=Ÿbè¨¢[d´Q	¦RYSÂüÖÀŸKaPÔĞ1Æ[@,4XûäêÓÏãÖšØ%Pºî‘\ø½!IiÍµ Š$
êI4o#›>‰O°*„¨×éPÓÁK³˜d„èÍæ;ÔÇâ…'*Q7êLRo¯e{0Ãh¤åp2ÓÁœÍÅ…Ã3&ÔXPxú^OõØEî&´ÄYN”¹ÇôÉDÎP'’†£ÊhÓ0@À s,p¾‹†–›± O´DGTüR8Ş´©R ?“²‹ 3m³ˆ¤Jôikq½×ñï~íxØl÷:9ˆÜğ«ë€ÍÀÿı%¤‡–î\àNÄ÷Ó3¤DÈ!ˆ‡<EFÒònËµ,äÌs²”è½‰ÂÒùngö:×+^“ Åœ2~3"ÊN­–}’ÉÏ?²ròh2ÜÔ²¬åH>‚£lw²„ AQƒ²ö™‹û}/näKäŒ\JS)laBÉvÀ‹ò’¿ºfAˆ¤ã‹'.#è!î8ÅsäI¡è0ŠqÿïŠ¨€}¼óÏ´Üâb¤j?Kó^ûCê¾éUpM—îÌIşYŸ>†U€ITÍúWõ›–…¸…·çÇp®cİDW…ÄK_µmFÊŠÕ6æÊ‰Ÿ¨„LD)Ù…FDXÓ-ı·ÈeØ®aÉ•ù›îGŞN¬¶ÛnÏFøBÁa¯#Œqœ´¯¤"™*Â™³f™iJu¿¬7Ñó²Îh-+z9‘¢
)”G…ÁmğĞo ?F‹+tb`ˆ™1èOIñ ¾P¯¯›ÚæùSí¶šaÎ›§ïîÌï¾Û r£;4½²`æ»»l€Å3B¸Ÿş$ÊpylTİ±§XB¹òÍ o.¸D&÷Ö%Ş˜zî¢+3.ıMä¬µläöÉe‘%D¹C)²bR®2@iÈÉÇâB‰ĞË¤’•µòJ½Üuæî>î©,JƒíË„I?¹rıæé31÷Uøbáp'…‹jmÖ\1ãBÌ÷ŸæûÁœ½uÁË[4g¹8Î~¯°ğjµBƒ˜øtœ®8óÀ;#ŒIş™ƒ`è9î÷{£j©‰¶3çq™Ş™½xPËljÄCa#2“59D‘˜LFgƒA8Öî%Yì$—MMâ~m¿6 #ÂÓş¸{ôëdabîüØqs~)®c€ª½BA÷“ÀªX*Î½Â'G¯zEr('§ç…Ùdør‡ÚE+¹¾uî‘AÑ™
 Ù'e"øÖY-ißeæìïœ‰²æß³œœMWŸ ÅâŞ:üeP°ë<~€š¤ËÂŒÓ¦NH0²ÆæÀåïˆ@[Zyñ=îFÕ=ÏJîá'‘buÆğÂ|öpaaC‘Ì9õ¿Ç÷aAš1«aC;c_À ¢xŸX8®Rl›6U=QC`Ù~Ø´¹ÑbŞœm7(»\Gá©‘ÓÍ¤ƒ/3¼ù|ªÛTK·DNÜ9+v>¢Ú¹¦³ÜQè Èï$ØÖıEd]
O^Êã >yŠ*„x—±c%ugèÖòp0¬^5¡‹ñHËÙÄõ1è«C#7¦¾m:º¥ÍuĞ0ÑtãQ­™î[Ä†HÊ‚Ç(µ\oPÀlË™á";âxüâàø¬¼6ÀÅápM¡÷ê¤eéŒÙ}ÛÉÉ
èu ^+âNÛŠŒußƒ+â¥şò>ÓÁjˆ +€ÍùŸ–""UÚˆ%‹|ÏÌ5(Ljé7b•/èØƒi¢Öy0ë@ù”FàÔwòLzµÙèÍşşkåE»£œÂR.iç: ü=wéşıç(À°7¼Ô­ju`|­ˆ»
¾u
Ô*m_ÛÕb¸À·g¦,rm%NkrÒ9=›tÇ“¸(PªS˜ŸCXO¾»&eã Û+í€iĞçp!´;£ãş€Ÿï‚wfê¢šìÓyòÎ9µ¼úÂqmÊï:êÈµÊnX@m…?(‹Ğ4(jÏÔB	€U°K!Ñ¶B¢_?l«†&¡-U'a³“ÍEõkÛú$KeT|vø¥c‰’ H†FlNG‚ıgïÁ¸·á5NHWÅÙfâº§]L¥§Ã„ßÕ`”¥OÆÏ}°è@‰”*íÀe8AÎDò®eLòîV“?î’å%Q4”‰?K¼C)Xà'µ»er²^æ² , *÷jy˜eV‚,fØ{ıR£[¦­§×4ß_Ú*v*µÛş súDÈQıNá¼7.İ6 n%Ÿ6ÈÜşaOŞÈÍÏ”,ÇmnkLæH{ó'V¡ôqF§”¸¦;çüPà’‚¥#ñxİ	J@$•“JÚ~ÿüV…_OsœÊ]ğõN ,…–ll*ééşáŠ2Hşÿ=|’ÎKrk·yêYnºê@˜‚–\d“[¼µÆßH 6ùÈ‰(¥^ğı73ÈD §ôj œ•0æXJ»¯Y™
À_€`üè1Ó>Zh‰&Ñ#ƒĞ$0"ŸÃ¥¥€ûÌe:£Øøûs¡ñ2Ì(Ã
0Á!ø¢Z,™.bkK¹ë@œ1ıÑ¯#-{Î BpmM0o—fpƒa‰È!CËŠØÌC¸$¿ó…%Ñ@ÛŠ’í :Èâ€àYê¸…ÙD|²h›ñ~…ä|?øÔi¸ˆsZm7³š²:vï¿s§ğæ}¢µzxÍåimí“K$ñPy©Ö)ş_M4C!şL¤w-sg(òŠ;°µBçJ-š\<üÎØ™¼Å—gWÅ/Ehë ˆ`.s:)—‡?+q"—°FÎ8r?‚Ü­Õ\ä´jDlÖ¸ç‘ãûÍË„eì›xCáãKY‰,½´)U–³R+¸¾QP°ëñ/‹.aN´¥ÿò„òÙ(ˆaÌ­¿©uNã“:<¬†ŸYWŠ«ÕÖİ´ˆÒ(‡ß âS¡lËßä|øo+ yÂ=ÎõìÙvr¬Æ…òÚû¶æ6dÍóÊş¥fHj€ ©Ëˆ¢æP",sÌ[ ¤íÓhMª- í(Ñíß9±û2û0¯ã?¶y©ª®ê®@šÒøÌ’¶u¯¬[VVæ—Z¼¢Ÿ÷à¼’É°úò%ıò¿ÅUğsĞc²JˆÖ´\N—KzT	úÑ9bª	b`À†F«ôK›R]gqê‰,ŞG“·¨ìgZÆÈ×(¶öz‹®sø=Š„:ß´ÑKwcœà*†;Çå¿Œ&Šk¬Õ.ñì¨ÂQ‡n¯lÌIgOT¨"àß«_vŸS-ü
î*ÓŞ¬~çaéŒ…ß(35ú~iŸ\93ªlÏÊêêF­6¡5ˆE•9i­®Û«Be.˜¤rmTĞşÏŒó–t7–§?`Õ§?6úË…DórbCœ9µ*÷k|=”Z”¯YWNuÖÜÌiLzökº©ÖK:¼ÉĞØĞúª,™’òÌ5ˆ‚€á;¼Ì‘Ş‚Òüµ+É™xÍÏoÜfÖÍú·¬¸™wa/SÈç¼tÿÃ­•S
OuãóŞdÈ×t¼U@ºV|öìøpæœûü1HñßA?a üÁãÈ_¥çq}Ò¿àï~tq‘ıšå7ŞR[Ñè?aÿG‚~‹Å7¤L@ÿ«£”Uøÿ?%¡üÂ s¸ÈNr?ëIú¡Ò·üBK-ã3K£‹ƒšNŒO¤sÕãw\Br.[Æ	.ÇXv—õñ„à@ÈIpÖ»:OúU·ßbÕ¿c,‹¤£	÷ñ§4É/ò.Ÿ²Òá»àÉFD”OÓñ'üôûô	|.‡BY-˜–òë'beèKEN'úC?„xÌaÿ{¿ŞÂ¯q?Ó¿Óşt(¿h–ğ'¢‹àîüÜıñ$ËT±×Á9v1Ò¤À™’¤¸G\e_2édlPHŠM-$/Î'ãSfÉÿ><‹ú""YçÅ‰ùÖiÎñìµsS°Š‹f”•é£^0¬}“e¤şŞ£‚ŒK#[P
Øt2Ó]ĞÜ…r+R­éõúzİäwhÙ_”¦T*ÜK—é–0_¥N%—¦ÇC<”ÊõòyMõÊ:/çrcRÇ©º³œÚªxr”•.*§ÛTğ4[ÕwIWÅÚF½yJÃ
5~áîH%‚ÏÖzYşÒM*Xxfjj½Ì*äSŞşU¢4Åƒ¾brğ±)»ıˆŒqÈd‡vA¾â ‚œ(á$ì«£oúÖ"Muz‰R¾@ÊAßN	ÌF Å
f1 pØ³İióánıÉ|íF*£s(‹TY N•oŒëª \S®à’SÌq¿+P„œmX¬–øŸYSêR@n”»ˆh¾ Öwç·ˆ‰ºYvÛºW'ÍÌƒ!)ªXä(†û$+ÎóRå¿úÑ‘O0Ë““÷Å¢éå‚K†½x<I·|8ªüì2
g×¬‚ª2›)-•÷Ë“‘‰\)Ÿ»wwÚR{©ìñ¯~B1Ô;	,šŸLº;ßVB(rDêqDteøï!?èñ6!ÍÂ·_Ã!/&ÅËtÑ‹ÅçlÕJ–¬w<#Pu»{q]òÖjËlé49›ú¬)‡ÀŞûºa¤ÒS<{ëY8½Ü~så—i!}ù;+Â|WÀªçì´Gs·0ŞJ_¦;3²xp-rğ+Ï«Ò[à0§O6Â]ÌÍFË(-a.Ë`eNÕ³°€İg†<4\3À>23şòÄ´Ã“±	˜/
‰©Tì¬b–ø¨5Ã:Kí|İöññîÁ›nyJÏ+˜"ßÆ¦i¤œİís$Çn\4DòLX‚”éAáhâÊî-S­Ğ9[ÍGˆ¿
äîı´qÚ¨!UK¼PWi1ë¦»D2pß„öŞÈdÊm1å0˜*ÚKÙæR–µ”2–šm+u7¦RyK)ø=•ƒ:Ÿşò<»¦Ûådû¦[æ•vNŞg²íÒ&S¹4ôiÍ‘r]Á~åHA[fÕ¬N;Û3¿Óÿı&€gY·eŸ«÷+ÌÜngåæ0o»së¶ÅÛhm _Š¡7¹y© g5óöêôSêå9æÑ9³H¼XäRnUÇ ¿hÄ/İ¾³+¿¶sJ·Ûş±xR~2%6Â!Æ¹mvÌ
óDá§”ßşÜQ7VÖ˜;5¸
ß·£!JòÂH”àLH¯9^	h#Óå9’³˜^ÓÇRM¬ê€a“ğšYNmV®8RÁjS¬•±òlUÁº†y`zŞ»ÆµÇäßtÖ>øvkZÜRÅ¶7Ty“HÔÔuq¡Ú¹eBºÈ½ïlwşœ¬®çÕ,«©÷§A_¿¹.õXüJõáêr.‚¼ıø(‰ŠY¶ööÁ L99İ¨ÀE²d¯µ”Å6š,æËè·|¡}îÒ2ÿ°d`ªoÙ-†õcÎ±¤`d?ê„tÍˆdğ„D^Ğ_U¿—\´Á:éø©_››ª"*‰÷y¥IJ»K£/ÄÑ”…ôQUE£/ÿùã§e§*SÉ*”Ç˜µÊLUìòŒ¸Y êLÂ÷,+èğ*+‚pte±íË/şˆšĞÊ¾ÎoÖ×|¸œÇ}Ød¶ü“ã¯jÏü?¾¤^¾à…È?–^´GWQĞ4à@BRŠó÷Å×–áº±&û©ßxÃÁÁ4¤ÒœÿšŸğ¥/Ë’"D"ß(†º¬²=+Ëü¢áh#E½hÈ¾ø†^Frktj…YÁ1Ì¢ç”Óy¶'¾«u¤Á_X?o]Ó& ¸>[×VW”UdŸëR8'Œó·}‚œ]%`\ØtÖfg²àùN«+0.ß†Éª¿´*¨œ¥Jsv–Şƒ¯j†|­Ò|%X´:|¡X// äĞ &dlÜ´œU«<f»gdNQOÇ9Ê½âré¤?ÅvÒëâ)Ïõe¶2‡Z©^ŠÓFùúhLdçañ,˜xƒ£Ö…{jÚ- ¢tÉ,§¸'ØÅ6©Ø…“?ß
FÚüÕ$§Iú¹(ßúP~ı³PYÙsü·œËÙ/éÿ¯¹ö¤ù´àÿëŞÿ÷=şÛ\ü·«ÿm­Ş´ñßèo–›¯C›LòØnÄ.»‰ğƒtÎ—¡$€]„\]Á]v²/íŞƒ—Ê›iÉj¾Æ[åÍŞá«í=ñívgº\íëx'hb«¼TÛîì´·ªË§áÍÍõÖpY»ßßî´÷9jâÖ³¸îÉ+`0¾ŞŞÁè|Ğ~ÓÙ=–YšYr$««qÄõ¬2)Ù†•pû/'{º€,œ‘fe3!ØKßã*Ğ¤€Ü‘õ{Á ‚ëXêÑ¿‚Co-÷Ãó°w¢—2é‡Š!íæe¯rŞ§ùˆµ*/–¤ãk2ä<Gu2?$w¿áù#|æî‹!F#
B@áå¡3[yò6bkô[:kaôû²ÖXšÇXóÔı8L»ø¾øı‹V û"$ˆy¹è
I*^Œ	TkğİÖ[µ‰İ&Ñ)šA@‹éÀf½4Ë©,QT²šL“ğÒ`ÿ"ú"NDS`ıô
í@òGm„Ø‚à­åƒÃƒö²ƒf6Éüj«CÏ‘{¡ÁìäªDŒe9!c5òmÚ±·º8>(XD1K²¯$&?ßôó
ù$x%H.SÁ¤ºªßDIò²ãèw¨6Q¡¹eÓ¶Øå¶Vª+]äV_¯â UµÁÕU/•Q¬‘‰ÖS0[¨Pú‚äu¶VV]ğ÷¿ÏÑ ñ¢²xîéÖ’'uíÅG…*÷9K~ƒ	­+­~„ÏFã´ÑŸVMz™¥Äè‘c™%ö(³Ta~T> b%wûCPûy»ö—µÚ6\µQÇ€şÓÂ8\†D0Ãœ'G3ßª¬ªuåí#TFÕNò@ÂÒÍÂŠ†AZ©’†iõtövÛ;½íNgûÏXªÊF•N~s0_×¡dõ.§3UÒ=Îê@k’\0ÿĞ§Òæ°a)Ëiç&“:TÒ¢ú$Ip“TÍDîÎ…U‚ô'Zè”Üù92hSÍ¾¹YIfƒÔÈ©³§“JnaQKq²à^†ğşAşTªWÁ¤ô)†À¢ËĞqâ¦vÿ!y´„RiQ
t€å¡…W†O¶´şÂº¶ªÍMı[¯`XQY(ŸV¸î·ªë:Töh*—-XË”M%u\ä„”5ĞÌZ/M+eÌ;O
™FÈL¢özàúh~äÒ5=N#×Ñ|Lyµô“4–ñì¹7G:w Ş0Â	Ç	Z»Éß46La«÷99¨^&v2àÚqlZ&$—¬Fms’ü\ou¶$˜cLm9_¹üHä°õ3À ßùr[ÁH>üE¡²¶O¥Y™
¹lÕ ­)qû­tştt«î»²Í'@…YqZÆÇ…äJ§V¶¨+)T|¸Æü!ÎHe3%Ìºz³i™=ÿşº‘ÑúSBÓÂ"ıÜ‘S¼ĞÍæšÚjó¬¨JäâH­Wlóùû®(`´ñv4¸á|ûÕDpBºŞè†`²i9#dŠÿMS‹nfclĞ*=buâx¢„Ãî#À]£Uâ–P¹ÇU2àrÂ‰‚ ¤±ºìJ)ŞÎ¦“ ê‡ƒ˜‘ML7éñDŞ¬ŞÓ‘ğúäò$™ÈÎ=3(j]Á_†éé¨×-Xßõz§ĞËß·€\øº3Ñ.Ô—rˆ˜œŒĞÉNú!Öi{Mùô¯’ÿIuø»÷ı;_ş÷xc­àÿwıq«u/ÿ»÷ÿ{§ş¥¬œå:zx­|ıZ®|eAÚáC?ƒ˜Æ³êòì[ÃÅ \Ó1šï…†%‘cdGnì·Hğ3_=¸õ>o¹D3{¬,½·$çüÚê{uÂê²eb9ûq8èù\/x¤Æ¸«¬Zr¡r\‚‚kEÛ(†luğ»&AøÅˆèQè\õ££8	â”ïlV-2ú`&á˜¬ïR‘„’ìşÚJ¿^ü^f‘Í‚í²4İ²ª
vdf}Ô~‡¥Y¡”<&O¡ht”q}Hiù7ñhÅ–	·5 Õ·±@õØJ•.gw ?ï@Y]>mÑ£¦x‰ûDË®¾¦åRš-Ëîi@f$3ĞÇ„g4¢Èoîª·çÖ‹ifW*SïvÀ^†“î$˜LSFC&«¸lc»éx›*x
=ş|Ò%	°–[³/²y¸êfupØ{s²Ë+^Æ(1É¦bj-5ÜzrCSƒÔÆŒCî5€ËãÏp¥6ô—ÿúåÿÂúLã³p¼©2C‘qpQ×"»D_›­Q]éß]ŠÚ@T›«bÕÜç¥¸=à°¨NÂ$!ä)r¥»ÇxRƒ!Ñ`êhZQCt˜U™—!õcêéjK¦¯óĞÅlË¾
Ñ4‚éH„Œø~§~«ûŞ’…İ­
SN~2h£\/=ıÃZP ”G÷õÛğü]›.~PJ4Âô4Ô2dv"À{ÉÛø=+4nï·;ÛÇ»ß¶µ—"½Ïh&‡/‹Œ•C{ÃĞ
Ì{?Ú*­ÑšôFïÖUû…zÓ1–l²: 5åı2°'¨|éR œD8¯œÄX³‰!æPã İŞéá¶Ö&wõÍÌûkôAì„gQ }_kÃÑŸv¾²³‚{/CŸ™$˜Ñj¡p-ŸÕàÿº|Ğ>Ïb—İã™÷Ô©.ªß	œß—ÏŸª¹ÏÔ³vÊ-ûÄ4¥SS4›´»NBşÖ[šÉ¹UU{Ç]E#6©:aS9ç¢#“ì/ ß-Nëh‰«?òyµ»}Ğ{ A«º¨#Uâ\¶¨7è¬ Ş'ßßg°‘b8Ğg¯ÚùÚ°«j·b3ì‚£dÇ¾¦S–úT–Õİ¼¢½Ù(œ-íˆgÑ š\?ÇÉµ@HÌäï%úu6'îèG©ƒÂÕiaØà.‹çãô¢q0°fÂğfçY½O«Ñ{üÙëc>@o³²z•ÛÒé(âƒ1;í‰é©8Äõ<ép¶D0ÍK˜Ó£ ‘‘è“o›_ş+ˆÕÄÉÍ[ÜvŒ™k.¹•™8¼lÙƒS‚¤î&i“RÎ	R«§Ée¨×îjáÀó6›éd”»MNşÔi?$eº¦ƒ‰‡A@ŠgAºÃ!_ˆÒ¥U0yÛÃQÂG>²÷Ìı+	Wµ†1=âgÈ¼|…Ê°qá×¥6¯Ê•øGï#8|³Uæõä£òû_“é1Ø‡J}ù$¬yÈ÷	+h>YÌsEmÔºç*‰0ùé¨;‰ÇcÜ¥ÊKéäkÖH+ß€yGüÓö·ÛlAáW³dºvY€„t WK¬9’ÂØ#`5±ªK14
6^ŞxPVj3ÕÇ©'ì„(8GÙGšsNÃNo&ÃñÖrş«/‹tĞvánboe›úÌ¦ÛÿŞöwû’óÍ_ı|ŒW~ÍÉM~hÃC¡— 3„*I0şÖ^#œ@±Õ«üm˜®	VŠDj¢ÛùÙsíŸİ‘$w›!8Œí¿ >»ÉnÊ'ƒ÷Ø“Ú¹´“ÈÒE)›°®ó‚º^síh$&Ğ&,ÑQMV8?è¥ú2ˆFêz>³œ ¼·:µÌsK‘ÜVŒ15o”·&³ùäBfD¼ËD¹dªUbaè´ÑìÌÆ gå6{«ˆ<Ë˜;ò<‘W¼árhIçF6Aü¾6Á²€'ôgãR)x¥ãÊ¼ˆ>Ô†º¦¿üÜÍR³‘‡‹­ö\[O¾ÛÕ½İW]u	'$Ö7l¼™qİ y<Gİ×•Yƒ!oŸä+õšï`æ7ë[UÃ²!¼Åæ”ÑJ[õ“à‡<k3ç dj¢Qtla?F üa8Iâ”ºø'ÜÛro¾ëÖK¦¥UC=›µŸuåé|Òm÷~—uõ”¡Ÿ2ÌïÄ:&CFİš|–“ÎŞ–†ğm=¯²ë[ÅRäŠ=Ù¥17¡A©¹º¹±ö·¶ß´;½×û;0Îíı6\’»Òg ÆØÔø†¬©w¼İyÓ>ö…•–0lRvİG`ô°©s¾:Ùİ“ÖÍv	œ‘¿H%?L’@·csØ‚ë\œ¢ÁîµLaU&±ÒöwÌú¨UµÚ(î‘«ÂQ‡QİÂ_‚ã( WÄ‰¶¢(ĞBš"•S´%I:‹‹Ğ±6ŸDªÚe_BùOJ½îI'×²PN¦Úc´XÌ¼è yNz(}”Jg;î$Áø]Ô£•£º\ïÊn}å\É1Á8—smö8×fóŞîëöA·İµ–L)&ñŞî‰6c’•O°ÕL>‚…ğv´•Á~ÛÑi1¾²d`Ñ+Aò¿Ñ&p“=€ÌMr¬İ¯İÏºvg/cÍ¬*qÍ›pb>âk‹6¤ã³»Àç\çÜßzKŠp%D·çÈ	¢ÊM–S/Ãk/2:ÎŞiïµ·»íFü>$ÙüÂŠFíewå¼wI9wÁcÿdQ;C
Ë(ê4Õu´$İİ,md%TÕO’ys`?O?ß.ÑŸEÇ™¥Ş	Çjƒ¡‘÷_ÂEÁâK{–$üw›í7„Dá†+ñü0î#<”¡"H0Êç6C8PÓ‹ƒ®	+J-Ql¼Rt0–©š»Tu&'¹õ¶œÔv;¯{{ß”<DöÏ}DôÏ™N”¥”xDr9)hNd(W‡š<3*Ÿ;{ŠEŞÑ:¬ÀÉÀ:=_á½_‰!ä+åmÎÂ]Fè*
"¶VüóA<BzŞe_Ğ&f–£ÒaqU)úñûÑ †K2ÙÀ²ğ‚ynšĞ†u]Z<«_ ñE"ô•¾pjj_á®í+ñ:…é­ì<k 9Dãé`à¯ª{-–_ı¨ãQÒW2ïŸöüœ¾Ğ´˜-Şª0hÊÓ§OE­sUB#SÕe-œËh^&%Âq’ª|•Ş®Q7i•”=Ş‰€ã“·=š'Ñ¥­(—SôÈ‹Èoúğ¢DF‘û‡P‚“ìõğª<¡+¢1š*Ja¥¼ÆúÂUÖKë´ªÔhÎ"”äD£	³@ä™Ô5™4
©Ş‚
çPÂ(ˆQÑ<â•‹õLı{ƒ/LD_;4EyûÛov_w¶vvÚßo­‰Š@¥Ê0A‰–ˆaBõa6ÔÕèµzòËß“(Fû`.è]#¢†!¬L»`ŒÚ£I<x-Š£´Ì[ —y‹,}ˆ6’±|
]Í¾ÿ¾NëÁ8€‡¼ÍâC,¾Nè¹Á‘p[™Ôª±©÷"OËO5HYŸIıÃÏ4„%ûü’áÙ›NÚµÈ¸àWrø°h¾ìçNaÅÚ¬¬e°İìÚÑÍ5²9ƒL/å“¨%*]œşÒÈb¡YB¸–ÒşêGƒ·»…E]‚AK¬ÀG4¢&ÓñdÕœS²MÙ=r²PÆ´*Ïâ“õÒ1™~ÆV)š²æˆäâsƒâÊÍãr°óÍbÛEîQÛ±ı¼CÄE´…BßYT9”š{ÃÚ:>¥/©êü37ÛL$S`h6fñæ çñ‰{…9°¹®É1q²¤_|‹x:o:bÛ`6©d5Ñİ}³{pg
?<ã~ŒK‹¥£&ù_ÆRvva#<€²„5š·‘5åGĞhâ0hI±!R$ÃÛ*ã¼?Æ³W§Ê£-…IUÒhbìY3ö³E˜œ
İb!Õ¼ÒÚ`_xKSHJ¢9’¯)-K?i=®·ê}W"ëPëê,øªc­ •™Y,aWë0ÜÎ’ö[~y†Üú1›9”™äÅH sèj%ÉÊ¦FHÛ´âdÛX€S°èµÈÒÌgøâôqùV#W¨5RòÈ‡e¹q"@"9éİ§u‘G>în”NôUBoé:La§®£ƒ„!ÛÇÀå¦DX:ãVí¼yIŸõ­Ö6h)—¯|2påGƒï¹ïƒhòHË"PùäÔ—İ*).B 5©œRf^Jªò2	Øƒuıdx+ î6O¾¼bY¢l¢óÕæ5/¢ÆsSCF™rÃ–øfí›İãßb_M7L¼ıì3„jĞöl|¿QõNù…1×¸ŒßıNäÎ–½ÙñÆKcÖûQ!#?–5ø$k8ß’È‰3—:ôòoG³ª(¼ÉÏLœuZ0CájµÊß£r¨ş.qËÇ-{î¯÷ÛôF8÷Ö³ğ"&+IÒÚLÙ¯¬U5Gàô3…(‹î©-'¾ ×ü†ÏÑ¾üã¬hÕFxKvn‚_Kƒ4'…©~t®2a8u½®åµuF†ŒIÑm¾FÈ!\äa½$zn¯M#ÒFBX1·s³S°B<&Qaü×7qVo©gi)Z*MËLãrI)H
ëİ¢ƒ(5Ç$wT’bónª7Pßs¾¥›Í¾§ÕpZ™Ki;”Ì4EÚ˜ˆíñîu´»Ü…j-Á"” a;Îe×dŠ-µâ1OÊY G*ómÊ’ÓÙ-ô°Àâ0%Î§	z(ÑÓËG	™^UŸrËŠ‹’>¦ôî•/$g¯Jwø|ËaşğûívæıÈxé}ŠZ§´›só•ø¶”’È]Ûı~Ÿó$ÊI/^„µ‡[<¢·[ë>¼°ØÈºS˜O¯ùÁ!óS¹ÆL|¶ 	û½„¢HnL€€}œ¯ã Al—Ùª¶Us˜ŸÚwp‘şòw…^"Â4%Óó€äâ1ùÓ¨U£0	crPó¤7k–Pâ©Dçoñ÷ª¨˜/]ƒåËŠ¯Â’DBb« tñ¨
bO$O²*…kgÀ4æIG^ÑàAyÙa·:Ø¬ Ö—Ü
B†‰Î™Î¨)˜Wê^ZL©ÛÑˆò›şİT½F×Ñ¯Ã]™/!ÛaÑIŠ¯ÜûGB ÷¢Ÿ9ÅT½•‚ç#®ÀRÌi»Xã½AÚİ+øC.7´g=ëVbƒ‰€<6d¿Œ¾.anÅ#öŠ‡&Ÿ@ô 4”	¥¥sŠsHPChdPR­Ãª:‚=	:VFõ^fşkÇ˜¿2¦J»pÏÌ ,oQ2ƒ-yÏ†øü—¿{ÿ®hi¶ƒ	¬)¤€ÙóGG!LO¸ À®ü› ^ÚIË^ÄS2Š@:=HBºü÷Ö{k½µ6AÖÕs‹
4'ksÂ
âífmÙÈµå†ÙPR]»QıL9fÎ¨vV¶2¶-‡¤&{U«HUbßæ5O¡¢3°ÚâDçWA£É ¡·qÔS:'çÉô¡9‰}?)ûó³:#>±µ’\‘Ä„(«{gz½äq­3¡©
(™Iw:œm’ú›B­éœ¾U	u™‚¶o8#Mş$ÁÿÊ}I/-½Böš"¶•ş"ğ)R•@'ê]»;¤æTæÁKY#mï¼šÄ'ığŠÄÂhH£¸_2÷1ÈìªßÂXteOUY„g³tÈ˜%¢Ì=©˜ÇHÚÎG—lïwÌu5oÌviåF¨pth:·‡—¢Í™è‹{Pñşí9Aä>,^ğÉÆêÒoÌ1eØÎ¬³›Á¹¿+™g¶JNnP‘»[îÊÒT«Äw>V›‡’»g%+áİdo/=Úîb³.9œgíß•¹¸,”ÒA,%õf²@Nà°5Ã#¶7-ª4»'Y[Y8Ó¤s53İIŞÁ‰ó9NÛqªìqq¿¡VwE>ğ™}§—¡ s°©¡B¢óÌ,Ÿ:v),šH’ÜµjQ5‰¾’«Zóç«¢ö‘…ì¦`|Væ¯jñ¦*4}‘KßL]¡tF˜Må2ööv_ï÷¶_£NÜşáN®à• öè p<óåZ©´ß?ÃÍ
·u½×°”ŒË›zšSãÚ,ŠJ|ÂN, Û~‚ûsŒ°ƒ$3²: Ç–ŠğrHdGn_ki¥¼Ü,õ“l?°UîQÉÂĞZÁ–ò–¹ tˆ
İ^]	õû6Î—²T™¶I¦ìJÚÔ¡–Ì®»a§X²k_Ÿğ$Y^Ÿ¼a¬ÍÅÖr1"d½CÖxÌ”zy¤Àd°/ıËjI2ÈRD¢°›VJP~<ŸVÉ	c]‚]QÙ	eI Y9êAódu¹“/ps30oàE•zsÎÄí>¶İæ¤“øHJ©gğ9Â+aœ¼IáÄ¥¾šíOGq:y-]øp×ñıoëûîşOã×	&ÅÎƒğ³øÿ{úøq	ş7~oüÿ­=¾Çÿ¾Çÿ¾)şw™¿¿s'Š7O÷‰Fñ–Ì’’Ë)9ø«{Àÿ_<7L/êWÑU³:)d¯Ÿ%>\¹]tûWãÚjŒ"ËG5ho\Ó^ƒä¡‚3òµzùÍÚ³²*´$í8×q^‰x<cæõáşQ§}´÷gò‘(ÉÅÀŞw‡îôù¿éB‰9KSÔáŞòk5 Ï±‡½´Z-	ÑØAş[‚q„ÀR?‡¸o	†Õ’+ÊH\¨òT,ÿGhë'±µ%jÅ†¼Ñ!ô4¸„+Aí;Ô[À–Á­ºV“Ù Vc*ÿQ’p¡¨}%ÊH*ÌğÅsÔn”£Ş¸y-œGÕ3cÿ§Ş†°&“ôûh­=Yoü?l¬ßïÿ÷ûÿİú8~¢³ùl¦/èÂy’X'ÆŞH€“N¿ŒË×ìŠH¨´Æ•75¸KsŸ]Œ•¡¨õU€€ÒåÍµg sQ’N2X*§Áæ¨ïÑ[ìi³¬)«}ã†äá¾¨ĞÅøe÷qÕÓù cÜÓÙ’³ÒÙŞı‹Ø9Ûû¯vÛÇmOÉ1¸GVÏ”t˜†ã¤ú™M9®ı~çMogûxMŠº[>Bú7Ò·A>§O:‹e@A<aDúS4æÓìÏE~×Ş{´Xñ–`è¥»ŞOö¤uÊÔìá®ø§“ÓÉQü>L’`'Eá@`GI€(?”Ò[õ¸,ìëQİ§“‡Xû”NoW4ŸÔ×6ÄŞq·ñ,ÁZû0“!ÒJ¥CÉ%ôWC˜$;[şåg¨h‰÷‚oaVº¦¨*Ÿ«PrğÖš™eo÷•D] üıoPxİş¾/ ·/_ŒÏ—Í.|uJÌÓÏYÊÚ+4X´oh†AÆî7Ç‡G°,?ô/‘İJj(a’Á«ŞöÑqïğèØhœ…ˆç“AÆ(œÔÏ§A}z1œ Sœ%5°òÖ›­gqÏ,î¹	Á•–ÆûÓT6 zu²Û—Á •ˆ±¯m¬¯¯?ıÃ¶S"ÏÌ˜íÚÖÎtLÎÔs+i>;3sİ¬-Ê’aDh‘F¹Ÿdã><{Ò{²Qh½İ6³¶tœU°ÛN¿'õf½é{9û»™4íšÄl=ã€2H´Uo&NØÌhQÇ‰œPXjÛ’ÀÙP]F“·Ó3§Ÿ†ãø’`&°	IØäî‡Ÿ¤ŠÇXİô“”{Ù²Mìt½İ¶J5Ã÷à£)0Sğ®–Jù$ ¯U.Wv«D£•;ášGIüSx>A»•Š.y”’¦ãà<4û [˜ÂÌ¶Z\ìË~ûà¤·{ÜŞ·Ò»O½F0Æ·3R–H¢êÀ`¼›Ä0¤Õ‰Qõæˆv¸|İZæèeÏ°â·(I¢m˜ıÎü°D…-¿‰¥=µuM·ì9PNÑ;Dr0`%ß4kóJĞÆóË=‘êLLßë´·÷¨TŞ$¬zêIta #”2’eiJ%ÑÙ”'Åœ£ÒÆ“C ®`ÑœxÜÊaõq[¸UÙ^V_«?ÉGoùÊ—Ÿ½ÎÛ9Óz£÷ITØĞ
ßİĞ	„JŸÄı8Ëõez˜ë=ñü<…ßgèªZD#`¸'p£!z¿0©ç†Ö2¨z5ª_$a8 Ï€ˆ
AÙÔÆ$¸LùæÂˆçİy9†ø|Ï²x™$Ïùú’:V™û°¢~1šŠÆ-©ôi´Ì€fï¦Xu”¤GKÄÁ¤’ğƒJhÖŸÕ)ç’çÙºÀ˜P+;‡İno»³¯™7ó¨Y&´dÖğFÅ úĞPŞ¯N¤eáj|võ/ùšHLX­OŒ_gÿë¯|Ñ=y…Z°Ö“áÕÓÀŠ—?ê´¿Úı~oËpƒ6š†é[¸mŒ_·PûJÚtgë@ùÔ¯ÕØŞÎ©-´ßê÷kc~Æ	¥§ŞÜ</açœ\Œe‡ô°¨ú`ü _£a\×ø¹³Æ \ç7J,å´xË>Öü»j²ü™¥â€[5øs¶½(JcMéS‘~ı¦Úxq>ĞSÀøîİ=1q¬tÚoÚß‹o·;»¸{t=ï»NÏb+|±„D×.Ú»G{»ÇÇíX0màS«iOlœ6âÓ*'ìgéèì1@æáh‰Î>4›µ~xüŞÙåälVúğàãèÃÙôÂ<¢$n©_°F.ãfûa’NÔw0ygÄ\¾=¯©šğÜ¸L'ëÙ…û^†y¿åÃÑE:=»bIïBÁÃ5Ú¨Œ1%A"Ô„ïAÿL\Âq5°o¹UÏåè‰¶‘Š`EB;D ³kB…¼sÚ2}Ñ‘jUÈx1ŠG5ì¯/«¡¥É›ô?üèy¥:UnÍ}vy1ÌEº•waŠ}·½{¼ÕB‹;z¦‰/¤ê3ë°¯3aÓëÑ$øğœå/ösÄ)\^O'ù°LğôC@xpé™q(	$wÚŸ~ˆÇ¹(® Ë|’Bq:ö¹’ÿd	ìz³*fşIõ ¢Ua_)Ç ãıÏ¨ZŠ}âf›OY¥5êèLGÚ"Z¤,îŸ›_ñ,VVßq,~š¦­™FÕ^(­±Bğ=(çF‹cH§VepD”_£÷X±«ó[COv³)­a¦;®­w©Q–ÏO‚eµtèõĞ´/Nñ~*‡Ë«P³fªáÎêtB§cz>_™ßz\Fs¦ab:tŸÿÃâs‹€aÓy­<Ï­•|[DaåÏı¨ª—ã×‡İc#µ|lÕÑ'û¯ÚübM|s„¥YhÉï¹pI^«7ŸÔ›ª2”ÊNGY_â	Ö¡ëæ®ÿóâÕµ¶Çé-Ç‹í+Şä—Ã§)½îŒµK’G"’=Q*´y9„NØì<F‹ô3Ñ ¨ıÏ¿‰İLÙ‚Ú]›Ùiâ{
Vj.wRS=cyuø«Ì]åš>ğ‚¡‡âuö%5p2Îßâ›U®	R'Ø08‹jõ?4ÆIˆ§2züËä„(†(yJ]º{r„'¯øºÍìtïä¹D–}».òõÄîæ¼.šÕ9×¤å/xORb¼WñÿÏ«NÒèö—jµgDf—T|Ö°0ÜçJ
ĞõÔYŒÎß"«} &{/Ú…ÂÜ¯WòPÂ‘íïÛ¯Ëc{«-§×l)>T†\ÅÈ0kË7Ú­°ĞVëY>²ˆ	„Òì:ÉeR7 ÎÖrëid%X—Ÿ¢ö€	k6-‘ç'¾‚ør£¾bùU›¥<Î§6d|$­|L»’ù”¥\ËaÎe='HuöæBX…X\,(Öò#ò¶ÖÚ©¿k­Ñ[üûO6à_àÜX’›5äÃU×š=J‹lõ²øU£ÁWİ2ªFÖ¼ö¯øû¢úŸ–YÆ—ÕÿDÍŸVAÿs}ã^ÿç^ÿgşÏ­€Œ©~; VÃO%ZÑU8ˆÇ¨Ü)ÂÑU”Ä#úFSR=ù"úü®&ŸAár²GÈ:¬ÍŠüX÷»ü®ğğ“çñî«¼¸²Yº„ş"Ğ™B<ª¥¨C‹#²HÅm'‹f ¾¤ŒÃ–ÖÂ>>·/š—˜<–JÊ
½JÏb‡»æıÄóLìÓÓş·lÔX	„»Tíß
‹—ÑyÁV58¢.*kB‡’Èri©Ò¤Ü3$m™áŒk.DeB­VCÚ< „=¦0©ˆ ¿ŸèßZ· BŸp˜ö©™ë9Ø¬5MCWi\z¯¢¶kõ³~ÿ`aãZùU3£_Ä¤˜õz]Øi¥}³¨%WvŒµJšp-Fª"Sª¯b˜G™i%Ñ’Ëtk¥Š^­mPAŒ( |Uš{p§´ŒSgŞÀMu¼t¤yò¦­ 2$'Õ9¬NÍ”„ä°P‘ÀËYQ7³‰ù.ì‘æ÷ŠF}\Üæ¶eÈ„[Ğ—äİ\äí­xÕx^VÈóª‚Ÿ0ÚOfÓşÑÑ–	é ŠúÔÏ?<‘36’R¯pÒnÙŠ»íTÀ~^°ìW#QK/ŠÆ´9/HÂ.CTHDéllôŞÆC™Ğò…p´"§Îa™ı›M1<xb¸²Ã>BÍàvp:	&q†ÆqL	·o9Ué7Ö‚º¥÷)eÄ8nrì¤‘AĞ
|Ï+SY¿-UhK'½†6'U&0µÖ)º¶w¼\¢“{kİ¢üëg.˜ŞÏ¢™0Ğf×Ë3Um$q<Ñïé¶ŸB°hWä±å¡Ş„Û“Èî`)—75Ìèsnn3»·ãËœÿGªåĞr‘ÊFT>NÑ2¬»¥ÃğšB5yíSP_ù`3k…KIH“Îè ½q¿üŸ~@¨8Ö²yNÓ ¼ÄOCæÄİ~©´Éîˆ87ÔâÁƒ™àRˆ—¿oiø#,
e“™¤SnÜ™VË,qQœÆ@{`B£r[¤8µá¤BLY]çÌ`–jµLëÔMÔAÁF½q¼Må	
 å$7;$éTE¶X1ôxÛ#‹/ôS¯¿DSßO… ^À>Yµ#h`øS~¼‹ÿƒ4êˆ€,œ0„:§K¥ıI›e{.ŒÍÌ(?ßA1¿‡™Ÿ:Ú®úíì.Z=Ôm¿u'Evb+(Œ‚eù¦îß	6QÜù›Œ¶iÙ^cX·~“’É'c."<Ù\«œÕ‡ÀfK»ƒ»¹w¡†|6>.|<…üÏP­'™ªÂ¶™)Ò«¦Ş¥ÚA2ˆĞ€oĞ)-¹s­Èçk©u±j@ğ¢>ZßØÇ<½Å]-D¼ìĞ~§Ã_ÿª~=Í(ÙÖ–Ãï»ØÌ9‡_—‰øÙÈâùdŠÇ2î`º†Ø³\Ñ‹jKT7DõIŞwÇNŒ]‚'éã0íNT«E	=0]LtóŸğş;	Fä@AJbô(†û‘GÉß}ôå0[À…&”NÅF[_Çl3™asX_¿eRM—€"÷S9Í÷nÌìÂ2Ûœe&d ¼…ÂîXòŞ2íÍõöE#¼DÅ~ï•D%WO5çêiLÇn§«ÈL~/un¦¥»©s;•{vsÓó$Ü-R[.."‹9mf ÿ”£ÒÌ;	³yFOÿÖJÈŠ|Ù“¶X|yY„#¡·—Û"ÿ³öBw‚õnO³Ï¼¤™Ş˜iv_ÔHWX,²s l{e‰.Xx—ëÂ/ê ´¬–RÓf-‘$œ µÍÕÕ?"ZÿÂKÄWº
°QÂ¦),¾zíIôû*ä”¤¤ò|¥±^õ™Q’T§DuU÷XTq¢}RÈiøĞŞˆ5—¿;‚FÃ¢ ¼b¡,f·œ?”¦Á¹÷[ÃÿèÇçiã³Ö1ÿÿrï?Íæ“ÖˆÇ÷ï?_jüá`oü–ÆÿéúãûñÿÂãoªm}Éñ__[oæß×›­û÷ß/2ş§>>rQ»¯-ÆHıøkà™ğñYUlO/Eó™/Èôîn>ñŒ*Õî—¡ïÕ»_‹ƒíı¶g«ê¤“8§¤JYº»‡Gİİ®g·æ,ñÌşÃéÅ+–^t~¤ŸpüÂÏ.şÆÂË§¸9Óp¹”&—ËOŞ ‡V–Uß²t«Nk§ÌC˜I´Â³›–l\L¬pÒ"¥® ívÚİ×]j¬g™û£ª¢ö[?ˆFìòÑ zŠí£ãG8ˆ\4Ä«R^‹ò‘~ôfq–¡´Œ1m&3§:kZ– ´÷ÉHC|ÇşÛ±¡’¾^^BröB*Ü¾§Ä’ú^”B,éäĞ"SİšÇIg¹fë›y%qUEJ»$/Ç`3™5d˜¶DÓÛÌÃãyªrı© ½­/r³”·‘©¼Mc±¼"›=C%åüë_	~ªIiX#^Û£ºFâ`İ`·
•*ÁÔ5©ìZ¬MàÚ"šÀrZó’')Ï8h„Ã6ú;ùÑB*£kAõRò›[¢+Œ¯\œÇS¸"ô«dêW¹õP÷*xî\ë
ÁÊj‹3¥İZ™:]o—UO ƒ`Šš•IÖLÔ=LJB^&6DŠàb×Ê¤@©éœˆ]ƒÀEŒVÛÉñ×‡/ß±Ò§€^ÜkşçÛxWÂZ¼¯zŞÜÿıÿÿHüŸr™-LëÃşÄÿZ[ÒZ+ğë÷ø_FÿÏ²êğ<hi‘z¤ôF¬¡†½ŠFè"P2gñt"Fá{qÒ‡ÃSø˜CÒ©®{Ş)æ?°‡Ã³0y$H/µı_Œ_zK/ÒI._´¿ë>Ñ¿ |:€ÿ/½D/wñ-ª?=GAg@Õiå/ñ\¼‡/-ø;ØX§ãzúöEb^4  YÎ¶ñº¬.šß¥StÂŞÂ®Š[fj¦ÿjJç+¹Æ^Nü“«GúIiİÌª¸R.¶Ú@êÖÀLª[×š‘ÒÕ;ãSX¹$q |DÒZ“Q/D#EÁ¯v¿oï”p?B#…Ë¼m=F‘‚RõÚ¤¿ä½hÀ0ñ8¶`;Mtd'4šâYÙxÎjA„“ÎŞÌêà¢,Qó·˜7èJ©¯•Ì†‹ÆÌ*_˜¢õÌ•ˆÕ¡ÈšG°Æ¿™êÏ?N1‡#¥ùe“«ÍÌÓ¥£Û` (5Î=ài†èğMhP2ñ<÷éÌÏPQ
#¸Øä'®ß¾µ€˜Xy¹¢JÄ[`™’(uö‘yÎÓ»8¢McDo= PÌ
µbÕlÈWÚLj¢¤BÚùì1qfd ¨íšò¼·İÙ¿zÚã}³|P›#Ÿ9ñZf__^ïíŠ}tês¦ùMén½(0ıå4 ‹[fhÙÑ†–ÖŒ¾ù”@jÍv3¥îğÓ°SvI$×Àr¸æÂŒĞ~p,¿1
'ü¢GmŒZm¬©›¶	1×°ĞãòÄİ†+¯à‡R­‰>¤Xì-è}'#}4ÉĞšSÅå.<³ùX2´j!âüëäwÍõ-Ìÿm¬?}šãÿZ­§÷ò¿/ò÷ğáïGgéxÓü¿Éí¬4W9P‚?QÌSü¿ÅW*‘à"E®ş‡=ïáC#ÂnÒHúÅ8	õùg_ÏgˆU*„÷¥‡•àq~E94æ²H’·¨İƒå.z÷ø1‹‘b˜,jfm·Î'²œZäf4Çˆ–Ç™SGQ±7¦ªHI	†$È]Ê×ŠİÊ—!ë´GLşİ¥ü3' ¥³ö×ˆ@U¤0nşŒ+9!,‰éw9*ÉI²xùÁ7Ó”[g”›)‹ 7”hÍ‹" B&›-+À15D‰Ä¶¬$×æ43Ä¸B¢pĞ”Q¢ÜRY®X-™ù–x÷¦»•p‹€Í®)Ñ¬Ñ1ƒ„$¬Í¢¤X8K€WìŒI²›¢¥Åv°’ÏÚHo-@6E¶Hv>ı”ĞYuQfÌHpÇòg÷”ë2Ê(;„–Èº¬'³s—ö_I´İ³eÜLä›º¥¤[ŠºçÉº¹FÜVIŞ•Ê9«Å½”[òÿ1qŸq<Ó
ùîğ:0‡ÿo­=Í¿ÿ?nİûøRòßÃ	­>z8•ÿç4LÈQM**ê>~–¼D¤4´9*½ø†xŞÃ×ãE<Äïñ¢›@i‘,¶-(
‹br=·ü]_]f‡ÄWÂv+ÄihõUH”NÂ>î/ñ6	/œxÍ¼ØÕZ§¥ŞÈ¶œš¾£7ÎñÜ}¡Ì¤Ñioïì·aÚû/Õ6ÇAz—{Ñ^’šw|qGPÄu¦xmÉ_K“œhM®YpG+ÌÕÉç:£¦L@”aA2B¢è¿
Rè?o;F1ª¦ç8ıiç›gbÛö:”­Fi‡„‡£ÅŒ(§ü©ÿ®ö¬ÿ×jÿV‘(ğ:bW—÷-«ÿùñÏ¿YÅ@D¶Yô$DqØúÄ€‡AOĞÃ$8‡š ‘•]'é5º-6OT:$ˆîÄ¤"zE4—¢(z¹w'Ë©u¤§ñ Ò1‰¸ìx“Ğ šOMö¸Vôƒ±Á7mS7P( ½“€IşÓ•’/|~‰ÑÕr&=7šzÕ2H=¡BòÒ \pÒ'Pƒ(1QôL}`Éu³BIØW–š[(ÏWqÿ>|ÿwÿwÿwÿwÿwÿwÿwÿwÿwÿ÷ßğïÿ¹6zÄ h 