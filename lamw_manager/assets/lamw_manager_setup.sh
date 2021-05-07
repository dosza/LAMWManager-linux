#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2576132398"
MD5="fbddfcd644680e975524b820e4347a63"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21192"
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
	echo Date of packaging: Thu May  6 21:54:15 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿRˆ] ¼}•À1Dd]‡Á›PætİDñl;¥÷”¶£Ò)Oø¨(¯çM%<~Lìk3š€œµÆ}¯3»½Âä|ÏÇplîI£•ÏĞ‚#˜áÜq~9ë;ÑXÍ8ÇáÏ‚]$ŞãRzÒsnó„©ûyæuÌƒ«ÂuÙš¸É¸ùáƒ¾_WóâÄó™Í¦a*Ö@Ø’ÅÖX¼rõG˜	QŒÿ^vşKÇH›o”FæCÀ_ÃíòûR}D Û]¤ƒÎ!¹S§°fÒB)DRÍî¢§heÄr/‘à¬Ê7!dKëÉ¯¯ST¸Å‘MwêÄ‹€O¶åÿÚ®ŒíÁ‹NÀ1¬/dYí0—qmù#G?ı®yĞ(0‰Y#ğ­ÑİY+O3˜˜§ÇÒÍéqoTËÃ³—³ ˜Ğòk×)Î˜ˆY‡¦‰şd™ÊÁ~ÛÌ.ë:‰
Æ€&ÄŒ­ieOñ~j/À	²ãtş÷O®·j*Å7ô[è4XÛnÌ¸aR[Ìg'¹ÿQM˜Yü®©çlˆ WêQd»Vw‹–ØR=~åµÜå6i;ÁYF|şÖœvÄŒıíQ«¶Rä5¸I<f¬k›š²¦.dGÒ¯‹ ÃG¶n6ÂÄÉr»ê2/¾‹úÚÚš	­ï©-\£ÄÇQ&GlµòâPÔóómjLÅ+ÚxŸ"s]çò½v‰¤Vöõfçø…Ú@wCª¼`Ía'#•'ãøèÚ88êv´ÇAˆáÁ=ŞS¼²—Ú¹¸©=k¹x!Ã`âÒĞŠ\©1¿A„Eûo±µÊòË‡+¦U~­<}A»[ö ²oé“¡ü:šğ8q^Ü„‘,WòtM£ñ8<a@šë¦mƒûUtVãÈ÷0w;Š‘r9¹º²ú¥Ìœ(xÌêÏş#n2H°ÆéøŸ8@©éÿ!“oTKl_©4D¹$	<’sÚ¼5Ÿr?Æ€ˆ”À^Z}ÄÇ¼“›qWÊe³T‹!­Ï:_)Š¼§
òäf#­(p·n†’y.¡ÈdäÖ:Û›_»K¸âGD¹6¦¬kÙ#©Êy‚›?Á¢;_¨^ŒjFohDQÁTyÉ_tU©Hò™|Q,ks!¾îÌ©aU;®b' À'©ÇO!N‰%·á”à±†=ÛnÁŒßY¬hY èyÆÚJ‘¯º9EB^Ã8,K}
tUâF‡ÔÕnwŞ+kkì±Íöø,MÙ>1RìKªb=êæåMlßú§‡·T•íE7ı­cÄÿD!›xÃøzĞû?­áëÜÁ—“#$&dÿÕN()âfU»Oúß‚hªò!?
µ† trG²zêf¾ZúgâÓÂ¶:Í­[ıÄû"nR¢!Lò¶yö)€Õ–	ˆãe³O‘X€¦ß°É^;-©#Pá¡Œ§şÊº‡«nnCâÍ\1ÈüFC‘ ä+òıçÒtL…FaHùÆx¦b‹$?‡¡ºí¢²â"-‡¡ŸÏ?ş?W´Së;ŸjèäÅï¨LŠŞü¢¨ü³nt¹ÎìÒxÈ\IÚl,jÑ[mëdİ	N¿Óµ¢¿_Å-3×Ş<ôh%†¡\­6?Õ	ƒVHÜ¨‘Qå3{§#‚\ÍÄÖzäÅRîË6n;yµÑÍÈãşƒ#ƒİ\·Tà«¯?şá1Ç_û½Ïì>¶
‡0ÀouUÓ¿ø*:}Ğ÷lY']¯4wğlöÛlf©ByûŞá¹Á“e°åÆÔVØÕ€:bGæ
7~üDãZûŞİKÈübw­-R¾¦%¯,¿"bŞÍìdÁÌ(JëÚ£ãÄçQŒÕ8¿¦›¬,	ĞÎ‘ì¯ANZÃh¥ésNãƒBŞÉ¾)gx¡èıİßğ÷³ÑÍ%4oÛYÊÿW°eÁš¡:óp_×ù®öÙÓú$„¡¶°Ş×m¡<ÛÎÆür‰½ºèî§ô.šCÜöò5AwãØr;ˆïpÛùÚû“?¬ÉdÚR-sa `Ò@µÃ@1ˆø#¤€
‘°R½Å^G;o ì!#C2Emâmxóå¯‰Ì=I¶»1W7‚:Ïé,4'¯šS{ Hëc„‹²	
AÁá@5$ò÷•ÔXîRW™­7f<%êµÑ¼ÓÇ‹È°u»ÃÁdÏ¥ë;È¶E\³Høí/-FO¥-0«Å­#Ç•+İ–ñ€…Î¾‡›$$¯ûïfâ`S+Š	 «†‘	›ÈËüşî”œ¯ÚhDe·ÃLk^Âm£÷	İ+šâ*—lô1Ş}y¨í&Ÿaîo\º/›†ÉFó¤Pî2¢ã3Ùmª‡¢0Å;mEöÁ@¼!Í`ø
~Ke˜/û™(¼A­}j÷^jO+•ŠÃ)-±à¬á2t#mp'saDœ(6²ydé	Ï>3$0^İïÕèFï¢ÀŠ&àq1#†«(çƒÖ„ lØ©ÚIOS	 \ƒjš„ª‰è„@dä½ ( wj –!ª›fâ7§q›ğüñS™³ú°»‚Š‚˜giˆ¼ç1s”
+ÃËÛeHUEß½Uırê„vV¤€4¨>ö§«—tT
>×¥$¥ÏvŞ±,”0_k²;ÕÙt¼«ÍìÑ–¥H>„ú§¸š$TöW"®Å6ÂXà—ÛÜÇ“ÓC=sıtl yQ}ã¨gÃH‰´‰‡•ÎÛº¨Ç¡ŒöÏåµ6ü&şâ$£[d/´ı^íıÏ±¬6#tD¡˜·íc'O>ı{©g”±Dš@,¹Ø5# ñMùIó¿ÍˆÇçö]Y8:Áˆ³ÿYÌ¨‹$øš‘E	„YÎqTVo°hËøQ´ë,ğ£%Ñ&8cÌ‚:öîºä)y¥Äá\í½}/ù÷oJ(7eSAT`\¶xÅ°d”Z”ü÷J“£q«/Öé,PŞDjÈ%h‡«&;ğhT“ÌÎŞ½É¥©¡ıb_;÷M›¸s˜µéyá¢Q&”¬¬â@cAÏ»¬Hdä|IHi‰±¾¸ªd®ñL%ÀlIHİÈÎ5‹-¿=˜…[1YXeq‹ì÷'ù!yÍ),^â£:Ä·Q9B]ô!'s7Vv iüúD¢f¨ÜÖ]û¾¬uìšô«ô[—Ş‡#”ğcüo…\. aÓ#.Â.âÅ¦+Ä/ØâŸûÌ•©ŸFÕI^OAH†Û´6*²ïğDûIîŠ¨9â«H’zæ|—6Zq{“İª5uïù.q‚e‚WUÆ„¤¢šgYÏêxwÁ} ñ¾*ªækª£Ã¹
Œe^zølÑP¬É
/ÑõSu;ò¤b˜şö(İ¥……{3ÅåÁPv|XÁâÎÔÂGnE±ÇIùçGİ‘2k¥CN™õì'Q^¾ñ<î“}GG¯:	.Ü˜åEÿ—,ƒœÆ} ChF!k]Ïâ
ÌËgW¡\‡5i	fŠØ_æDÇq'½¸ıÀî5}2Ks½i;€ÛğPÔ«-’Ë(ˆ­ác¤üÓ•®“k PFa)ãœÆ®óAÎàFã¿U¦XpÒû:ç×´R0”ÜmpƒDŒ SYæŒåäl‰#’³Ú+£vEı¿—¨{Ò‰ÓW²„èº¥ı€€½êÀ x/E±58•æEmÁºkéùôP]¦ˆ³uÎóh*~ù›w
¡nkO5œj}>ìŸİ;»lÅæi&üm^&|’¨?VèkZ†·zWr§âõé´ ®·dFèmÁF¬Ğ×*JÇ%Ûİ  ²¦-ôàØ%
Í¥/+9bt.Ó@¡‘«)ª1e5@LĞp@¦Ô¯Ü™TÕş™—öa7‡-aZ=¿1‡s†”¼V½Iúˆ®ÖijÍŞ–ı}Şn¿¢îâ¥@RÉg˜$!€zQYÇª2GrHòpMáµ<¨ˆ‚aÙ[EÊú ‘8RRf
2<§…Ø‹­jH
\÷
Òuş‹i0ó€)‹G¸“|o5)ú…‡›vf#Q¹Š1ÕTJ]È%üjÃYFÕ_ú†7YïøwíbójK·ZÒFçqk×ÄĞ¶–[|$G-vÉgO ÀL¬mÏ2ÂMğöví# Ç;¨ºúâGxCÔV°¶“(Ø¿8-Iê½BşJ‹uõ8\Ï+„R°÷ùf¯|€úØKJ_ë‡GJÓ§Áê¼tPw]r„@6‘ywXT¿õ„ÜàáéƒÔ°'r$¨ÿV*\ê˜å>ÄF	[:,’«É‹:ö‰?£×ÒW7«U¨ûªÀ÷µdëamšS344l°^mÇoâ‰£®&ŸCö(\ÒHS÷á8Nb-ö¿†ŒFsó²^ç“CIe¬°#›)ÆÒƒˆ+-‡ôX©¡ÀÆsàEøP^ûOW«O²vğñWtÉBP³Á:	 —Ñ¨ÜÇõ	8X`Kÿ!öwiú¬M¦	¨İµ©R_¡º·ót–UÙ™¬Ğ?& ¯y.Ù­ì;Õ”á ÕËx¤‰Ï3Á-•õ¾ìı{Õ8cd¯3%f²	h¹‰|ÔªÚ#„÷¼É¢é?¤ºT?®‘3±ßÿ5IŸW$»qêaÀGR “¡¥ÕÄ/A|ÜÄš/7†ÃÚà‡Fkä?«63àcÓÌn³M“Òş½"*5èÇÈıß1:d!œyt)6d¼	Ìb{]xiòÊ/„î`ü«ş Ğ¨€ĞBM$•©(rDÿ—ûşÿÓ(¢*hz`ã #¼“çSlm‘¨ğ²L™ß¾Î)ŠcN4C§Á²ë£sÿ³‹~|!şéØóTò3.ˆ­A×(Ûm«W£Tˆ7RÑPÃF’QíºÅGéq»ô¶”~¨ÅE„<Í4q<ë‚M$wmyƒó0>‰Ä—¢],‘ã‚xt-`ñH4sLLzM¶´n\¯gìn®rÕK7èÉ õí¶¥êÛÚ¨#b]63ÜâP42¿KŸäïKQ©œ©0ø—'?²ôœve~ØıhYF,©ÓşZ!™İŠDcÎŒl&(:‘Hù­8ÙáLEkåq7…ÑA*w²zö§îê{Óß>sW—AWœÛ†®3ôE÷îy—e_%h‘KSíø%iÌ`w¥¿#ç|rÛû\¼£›’ŞğóuÄ¦zC"xµÑgªæ[{–§œŸ‹ê£ÑúÒôû'V*ƒİ³™‚½ì˜CÒ»rƒÿüíB__úR(ë3¸h¡òÕ`dtn•Fœ{TZlŒ—LP²Ä^cî¹ğlÂ¼U<a“Ò3Á/\§‡U“ä6`¡ëaø7f8L³¤bÂ7°}Ÿ-Ğï	â<ä—tÉ”o¥U«ª)‰S5ıtğ\Æ¤œÌØı>«…Û1M$ó\rrÏQÊ±—ÒÌ}¹=/_P/‘ê#.åà—÷¡N}ªPáCQxìİ²”<æÇœÙËBNp{½•¾/¿Ü²Îu­bP\#—ˆ`÷¤àørkæÂ€ÕŸ-D=#–1]?ôÀ2>ä- §è:GõLşqÉÊh’y¥:½ÎôÏÎÁ>­Oc„wƒ©Ãìş’l7c¸—Æ¡]Hy(;jjM"Kº¢û-jZWÔ²ºdÔÌˆßİóo˜1U——èF.eŒ‹b#V*ƒÉYš6%´T§†
]O¯ˆ#¬¼!¿ÔJÏ"JI{ıt“cÉìg2ĞÔ‡ôQ¶²€ŒØWqÍ4°¥Sàq7ás^dG´ø«¯À¼¢-Ëèl‹p Qlô‡>P$‡myÄiÎ
ÃÄÚšÅ',Îçò™‚q}µ¶œ±ÃÏ=hjŸ((èÿ|¼2áĞéxÅ“Ò}Ørê$ººñ_®«k×ı·Ş¦æ)¤S(*T?K´µ2ÖÏÕ)Ì¶ıé Îƒö$ñ‹3.3ç<±â«Ù»È—bèÁ¢ÿ´á„h%§I#$~ÛŸµ³©.4^Ü‰„×¯J!¯,åÛKq0¹ÂŸ0ŒÑó	µºNá§M”ƒ5\W	Ëb;åëÁ+—*{fi„z­]æ.]^í× µ¦Ÿı¦`0x)ì=¼ñ’Z±İ57Cçöæ ~CİÉşÿénpç¬•È_×‡Òî yÚÔFE]­ÊÆ”ü¹>•6ªŒ¤æ6$í\òÁ¼ñQlÙÓS<ñ]ª¼n†sŞ  š®J%Ï;KÅÖÀ5â{¨VT¥çß3 OñYQy‚ÿDg%æapwbÁĞ|“ŞŠv\•¦èŒÌô¬Ú«#8—ãµ†ã^zİ©âØ†(¥zgË×˜Í Nh¡R¥
ÂwÍ½Å¹/ïÕãäL[NVÊ›'¡Nd1Ö›òı#|dT¨»om<>cTá©‘#”µlJsÊ”`'‡µ–í.Q7„f÷$;+~¯±¥çn º0‡ºµ§¤ÆHJx$ƒÜÿ^¿ßK,,'L<Zd¥5ÙKû×©ŠK0z„Ó\nâÂ‰ßÌpzí]JdÕšÛÁŠ
ÂM¥”¬'8F"+¯N¨$‚£¬Šæjq—±ä™U|2[<kê¦S	áSF´‘ó…o7>b”'«Æ­ó—|–Çø%{7uË#Iƒƒ…GºSp¤ Ü„Ó§‚ã÷—{pîáG¾ì~oçS_%&¾uÕn‘¥ÎßTU¼È0!bE[éGRKç»œdà›ñ5On]î”ñïì‡©¦Zòó^ÄÑŒIåP‚h C‡hßgäX«K%Ãş»Rj÷ÛĞ
ÀdişÀ3D(İ#â¢šÉï`&°¢Çßò¢ƒpr´iLqY1PMŒÃğ_G˜À¶Ì@,fêOìoÚü6xxç[ûFÍÒbÆ
ß‰““Yµ«\½ï%2l²ˆ9¼¿hZ‚¼î¾T šÄS½D+j©CÇÙ»ÃaS×tDìR¨4ˆ&‹3;‘zŒş×üL¾D-Í b¡ü<ç8>~-;Îm0Y0ªÑ1¸:½KX-1Ú¶û¡Ô¼63k*Á	Ï„Ûg"\|í½œ“¹¸s1ıMâÈG'[¢e¿Rg*]ô %µkç5ÚÃÆîqŒã’ê²ƒïÍŞ©BéDtêÉ’Iæ»×9nâI7´ğP[RÓ¡s1uğ]áPªS4K|ËæŸC¢Õ&ø#ÆxóDìòj‹È’˜ÍÓĞÊ½Òşs)[N&‡[½¯¨~Ğıi}.‰ìŠÖ5F  6CM^cÏÎ¡J¥OOÅ©Ïõçjô%şH:E¡ºs§Ó {HCµ³×Õà
Ì…²Ìn	hü²­bY˜Ëo÷ÏÛÇÀ¶Æ*è0 ¤ugñB¬8Jvº8"GÚ4—H>9‡Áåz;MÄÊGÚøn"Òí±7‰7ÓÎùÂß¿u‚²-İ-…äÁ
ÉÚƒúÄGŒi ­ğzÑìEa®{
w¶NƒoOÎ{hÙ—wO¯è!El”I¿Î>‹.Òí	¤sÔÕ¸)ûHƒé!7õ™Æ {Z–Ê0ºµk2ÚÂ`)
c@Ä4><^t,ô½'WĞU\Ÿ0œ§@CzBº+0+ÕÛlbgÿ.{%;z ,X€4è²47Ó7•ÙÃ‚8ö\zœ¥èöÑ¤»„°£–•ûQMâP,øxÛï°!¾¸´ƒõU_ŒSVäa'=#5¢W’êI³Êz^:·u+Oá"Oƒá?9…­˜ƒÉfp}Û4•o`Ü( Rlï%XTµöTåç[İŞIÑ¸Å…HâbBÙğ^­5!èHâXÏ†Îåñ­vË²­· {„ƒŸ¹QA"cTÇ
5Qì5ÉRE¢KåhÙq4±\AK7R`§0òí7à÷Ù‡Â|¼’;´gm¡Û@{·2pih²Ø†zÏ¥~«š¤ iµë¨àz g¯Işñˆ ŸôÈ0ú{Jˆjâ×íÏåé±„Qß¥Tºe)˜ÆBav‡Jè$ÿÛ³RK9ÔˆÕ'åF¦‡Ë’w@%‰pÅu†ÌÅıïÚ•ÅèôiE³éM±»|¶Ù^¨_fYİ»Ï]—1†?ã¶¯qQ
 |EëåÚbXTBqGb|Q)õQ·ÔĞ·¬}š7:´dX;48^§†´ºt:ŒÖT l¾2·LÎ–nAùxnlüÓ{Ûp †¾xÊô¢©rñ	§tDÒ¢— û„æ¯ –{YÖòÅtêPB¸nbó÷O*Iª?eÃ,& OÆêœ¡KL	!S§´Ç2ı)­¶\ ZpÁÕ§¾£ÙÈ‹€æAp`rÙ|> á·»W}•±®uúOê[‹JÕ€æzvÅô½;ò·»#£‰[JìH¾íT€ÚŒ”Œ¾Şz3ZÖøk«œÒ¨ïÒŸ8)Bp[s¹FÒƒ>Ç£ oÙãîØHÖF !å=g™oôy”ÓÛ…ÿ´»ûp¿¡Cs{RÀ?¦ğÈ*}{X¶*YRuŒT‹=EªÃm+EXÖã§W´ÁåM¬#Dºğt-l)aX¿òÊ‚‚è®•¾F¥Åøà„ºñÀdx©ÜùıEÜª_Å®Mj¹¦ü% <BFÌ&â½NØ~Î›^&XkÃeÌh#IÖ­…/Úe2@ÀŠvŒÛÁ·ˆß}dß›Û»­õ›ËG†`M¤ø“(âù*&	/:ïCÊ!{½ ı0şŒø‚Xo‹û®õ´£MQÍÑüD­7øÙH5ŠÊÈîñºÚZjÎ—Ö#Xàcì‹#X\¸GĞÎo_¹,Â»"+[^Şø©`ïoB4¨İuÁ·]è1¡2n4
,€ÈÈº›ºÒDÙ‡„ºÆ"%Öwè^—Ìÿò\áºSâå‹Qd…=²N1ª%Tò?í›+y¾ı"9¥…S\+æ9¹â Ú@o ]éK`‰ˆñz -—İôk%h‹+ÂÍ]iáÿä)‡ÓY5MÚÿsÆN¥Õ0¡‘¶IQ 01’ìé°Q„ì­ˆjHı8j¡3:¼´½>µ“‚Ù¢l-­6 Ê™¶yú¹…Ø³ƒòŞ"(ü
óÌ‰¤ëZ“ÅĞxìqÇë:g4qC¦è=Ì%ÃH­öyÂ¹{0Å·uıxå]&bx¸~İ†yjØ@(*vä|O†:/u(²óµÊ¸;LÌš7psgÁb{}Q/Ä¦+äÅ‡ÀLNÀÖÚ'µd6‘ÿ?Ñ•íS–9b ohyœ°š–`@mšÁ”fpU¬÷„é°Á"ğ1°z—,±¡_Ò$±µã¸—¨ÎÅÂ~hc mãrT¾MBß«8µ¿bÀ­:°Ñ§ô‹Ó’—Ş(œ2Óâ¡	¦,ÙÆ‰Pbä#êèúº—íp¼˜İ§¢ÒLÑPÚÜæá>Ü¬ÓÉvYq’áŞÜ0¤¨Û÷6SîkÑåÓÄu¡\€êl7?/F¹zt.¨%/5"ìüûNğÓñ{Ä%Xóqv)“*ú)îh¨jª
#5N\éìAæ#õ†¡â_¯tçæÛåS¥p›½ìdà¬a‘± wOc€~Š	,G½ä¿Ô¯²Û÷ìcnÅ^$›k9èS€9ú	°û²ô™Æ”'•º9öî]>†‹š¥¼Òa<-gİI…— «çĞj+´`˜!îÀÃkHUÄÓ÷‡İõ¹Œ FnÂûôB¤‰l• İËDW@ìcD sóÄÙ©‚Ï˜¤‡«Ì^Á9õ5RøÛ¤˜ŠÉªO4JˆŸA°ödx.Ó¥·b6ñÂh âîÄ´n÷SôÁjşÕ?d\mÙ^¼‡³H5{Qú1)båIÔÖÛß‰Óq\@z~ÌII"@YüÙì¶”j~ó©¾¹Åb'íøG.rë5Äo‹3ö¶1|>!Ù®oŞa/Çón+:‹%Ó†®‰læHXikT€¢á’ùÊEü5¿£ëüZ»²¬’ıÑ5 ¿§ø]{/Ú¾£·Jn¥îpö±FœîR³`iÉÚÅ®'”zªßx ÛÚĞ?;!XÁY”á÷&óiìMf¤‹1ÔWä¡9"‰`HØXI¬}ÂñãSù±5÷1jX¼â2öKjŸk©áû©!–ŸœuY(êZw.Q•ç½éhb—<8M¬¾£˜]Ô¾uf5	}6ßÖR˜‰áA\fï¦ü]Œ¸`C	ÀüèßGYhŒİzŠuü¢2¯ˆ\í‡˜vÒ{¬Ï9‡OÜa˜Y}ı;OÛLşF_lËFT(ÃíJÕÕ»S¡~W	Ô­-Î´w ³+µéXùƒ¿úsÖÔL²§ÖäüV<]k›Ù}qTÉ¿9V_À¬—„„¤GdÎ@1@w‡p‡²§ìóm2ÈzsÚXÔúÂ¸ %hˆ'’Ğã]Ù™#,y¶ŠeM^|LÌ/
D.=ŞMÔEWL%Ûa9Ü*g€ftûE}Ğsw&6CÎ
Nö@°îEIiàô©ûÁ \¨újĞÙ\éÏ‘ÛõÛg_$8.jÏ)4ğ“|¡CÜü?ÜÍ9|/é:İš¬ÜCDË#k*ÜÖÂ»å,[M«ù3;´•iN21ÂZ¶u Ó6Î²§óâ>{Ÿ!´²¤NÃyï‡SAê¸ñıƒÈÚ’Ê~•ø;ËÏDlÿ»:`ş·Ğfñ“’V{úòI•_ëÈˆ²ºšª\åXâ¿s5~¬¡ù;âœ³ºıAòs’” °Œ2>@	—}ÚéôàE‰¥<ñîRD{´´¿‡şµhc’a¿VüÚ«L_®µûâ™”:[ê‰èFò¤ÅÊ‚ëÀG¹N+9‰e^¼Ş±Ûó7Dßåm³å”/eÙ•ˆŞi’|äu¨âÊ†%ñ TyÉShÕÏï¸ê±™­“¥q•«ì.G6ÅC%ÚBTñC"úá=u`ãyLşÏ½5UóğAtÍ¥vBÓZ°†>Ù¡½)	Ä/â`õÕæ,J^Š@¾OÓªŠRécØŒâV QQW3Z¿oA†y"pÂ0öœ…Á‹]f½8H.Ûá•÷mÈ3¹ˆc@®R¹øËUª%Gğ£q—$
 rQeøÚ–ÙR=qñö³Y3~R|àOZÿÛı¿ÅæjuAƒ^²F|iÇÂ_öš”´I‚L™W:yj—d–§Â¡¹ï°Û{š¼„q2ã™!'óuxyh/Z˜»ZÍ¼:µZ˜8Ç¥œ’†“áaq1ã2Zt¸úg.ˆó“ßWÖ_—°i¾ÊÀ${vìl,Wkİ¬„åw@Ã‘ç€ç•ÍUD¯{$ë¢»	2Ê$†´ÊomÚCöÁ—ªH´›%®X
‰GºOÄvEn³p}E˜~…kG¶dvçË6/ğ­d11ì²vM†U9UàÌ~ş7Ù|×õ¨êª/åà	áFwR¼7£Ø2·òö!SIv«ueöSëµñ¸…h0ç
²Õ—mQk9(ÚÏM;
®y‡QrqœÙ¦Yƒ¥nƒô%8qÜ/ 9NÃˆ®´s»J£xÛ3ÓN¼–Ë`^I\'âµA¿•3˜ àæÚ²Mí~¸¿#²ë«U!D±/ôŸ­ği&e}jÎ	lî&ĞãÁ½/âà)©İ‰³Æw?kG ªÆŠÁ¡Sàx¿O1Éù°¨V*Ïc3nJ¿{åº19‚ßŒå{juIø0‡‹)ô°åŒ)‰Cş¤?¦¼d.ìÜk™wr\J2<ø>ßí‡È%kBƒ¶Ï™ôÈåR²ôO¾¨öx§-7ì«ıËØ¥ÛZé/>€Â›qÉèY×²‰î%†›5â2@vJü‰}E8.ß/ŠôO^ì‰|İ¶øÑb‡¶T±`pı9Ù:onæ1Ã›†„éD~iP”ò
g<Cbà¦c¡”>ÓŒçì}™ñn²)ÓM«^0oùS!öòT­ñÓNÏy$Ãä|BóB9½I5—³€	çº¨9Ãâ/»(™Ò’g÷¼1óµœ&¤Œ<÷ºO,’Õâ•øè¼ëÑšâØ˜ŠÊ$é£™ß.z0ED¹¼Â½‘ñ}ÿûÁÂ=˜ÿnß¢…z4?â
)cO¤pè»|[­É¶éõdGŒÛ³‡²óµF}İî‘¸aX€zûf¦şu–Ü©m’ÃCÆ®ˆì1j „¹®ºğS:]íF‘±#ü—d¤ÊRÚ¨­^(BÈ1E¯(AÍFí3øÇTç©N‰@il÷	R;Z9ª¥ú³ÉMåMÕUÏy'P4G;Q‡Pà`668âí6ØÔ—Æj´úîúZ­  ‘9ì_y·$fRcÀšàÅH£~MZí|¥@G¸¿Ê÷)?w—€ô™Ş"³?¼e›!ÄÒ2Î¨/¦òÒlVşàD‚W%–~ˆ¨ó‡'ò`Dÿ…¥FT´<Û~J„tÒìèÈ”<eö^p¦t ¿‹œœøl„¤ÑM^¤ëù+ó‡Í´§"ß\ä±<ÚÈòwÔJÚ>¿.Û£{…A0²Z©ª[…^©ŞMÈèEV~êÿ¤rŸ“	Z·öÉ³ªÖIĞ_ÔşE„ñgøÕI7Qü0UÂ½ÏQ²*xBªPBß±Ä}a
*h‡~®lúÎËZ¥Í_g<<ì‹ÃG±ÜÅV+-ëÉİ«ÛÍŞ¹Ù1€—NH“µÎ;¿ÌÚñ!ù¬âÄUİµgì$²)æYNÏd”ÿĞ& Â—ÿ±‰FvÆ9’¸ OÕ{ËäV%“m#Ô’Ûá"GÙëw~˜::)‡í€_®nw©çŸÃÖÇ¼]UéÛ%ËnS˜¸Ö¶âC–»î½¤«²8¬†Ip›çhõª‰Ly¤~W¢ÍÛ‹ôÚƒÉ¸Ÿ’y,Ø0}1^p¼£¦¢«Æzàó`×ó”óš“e6‹ªä|ÆRd èjŸ¼ £o*^‹’ØµFan‘dC®¬*«ETõ©LÜh~_z0<NS$5|ƒ	æÙLÃI«še:^°	UÄçHk®tH"Wxÿw4O Â‹K«kŸjÿeVáóà8Pm¼‰ÕzRB¦êyûçi%Ö×ÑWêÀ>Ìwì‘÷ÃsìÀ¶ó¥’xğ0‡2·ÔÉ€Ü×læ^¡]R+QÑ[wÏÑµ¢ÏårS³Tw	S{l^‹³ª˜`Ğü	>˜ÀÊÇ[Z"uZâ •«F0õ6`ĞŸ¿@•ÕÖòŸ›8÷×Øw”²®•9¬*¤Ÿ»?=¨¿üIíØ[G!Ìã6©êXDmmå0Fñ [(½hò‘‚zAW†®€!EW’é„úƒÎD…:>LFÎŠ
À{mt?öOìÆt›9mÏ/™Æ¨SëfH±aÖ:Ç8—
ıEæ²)?Ÿ{ßhî¡‡ğ.a'«Ö ms­«|]¨¦ÀaIe¨xclH¨¨­ˆï¼Nÿ<•.³£Í‚xü|Ná/¾ÑÄ¯$}I/µ¼j!s³ÑNÚÂGöŞô1™S¸Hêk]³¡£NÒìíxÈ€¦¯•©À”:EW…dòPfÒC»ÎL]Û  .„bÕò$Ã‡ìŒ¢©³9•où”yİe	CÚPÏ•íï<}SuÙ)ŠÆY!„Q“æ/cyÃ™®Ãğ*Ìö>ùãë›“ßÒÇzÅ”†Ó]Fˆ%GZ–…ŒüÃ^âqUòN` Æ¾¦­2)9â¸Z Ï~¥”ÇÙÎD]íÃ$p£—‘\RÉĞÑkæAÆ$DüØIq)±] !Eà3¸oÛìhknÛGÉ}wo²Á³¾(°v‹Ì©¹<p'É9HqSÂ™
ˆÓ·h6n©’Ë¤`ş€‚­¿»x?hâ›æÉ^+VXÓÇÁ¤øïƒMmÚY21äNæF7M¢Q=oïxAYçÎ‘Bu<²
HÛ¬CÂUGWØ^Ş‚%úÂºSS®ç„›[¼@¹¯(àöYåˆÃúmİ¡Á%÷|3m’ŸìI.qz‘<Ÿò1Qm´'¡*cG§ _M-¤2ùqQÀë‡ oe¢Aê£_‚G©âzLşÿA¹©Ğ=ĞáLR¹TTİŸİÖ#T8œtn÷séO/7Å®{û™ìúF	mİ„]Ñ.­p(,± Ní¤7òœz›=™™—`ïm>øÉÂFôË÷HLş·‹MëÙ ¼²&µhŠ&
WX¨u‚Áûßœáëï˜,fiáb&å§øö$øıÜœ-àBv¢¯—¢Ì(t¸ƒ¶…ÖÈH§8ù¼íLá}òíÎšÃ0ëéø%=¬&¿m£ú9±ã2|û€H±´êúuyÁFt@îØÇ±×ØtY¦6Ó9¤!‰™u;‘_ØùÛİÍãÜZ‚ÏZVzÎIâSZ†K$w]Ï _Šş©Ñx%É&IË?œ¦ôÈÎ™uÑAÉ#ŞµºÙ¿cÂ,Áë…)RÀ·ğùÅôØà<xLb…xlûdÇägıu­6g³Ìt;iÿÙB+œ]¨¢¸+Ù9í˜p¬®¯mÍ­4¹†WyBº,9»mõğ¢JµkåP]x6ls„?cğ3[Ößøù]moµ÷Ø±8}Z]µœI£¬kRÇ®ù!r=®¹Y‹56TüD@°õÜP!•Íe\óÕXôüwÑê&…´+/½
9¶ôŞ»Õ²<D8;')\†D	
›ºØáªÌ/^/ºMr‡5Õ
¹ë¥÷Vè.ûgjíõ…ëR"²êìö…‹4„s¾_2ó‹]û¨Ğ,ëœãfú—CNÙ¼öPÀ§=ÉÖ‡ã‰th+›Ê»PÔ€¯©4åÜ
 QÂú?ÿ¬À‘ßÂºö–¥Á‘†¶P ½Í;AµÄcÿìTüZ}”Ä¤Q®Üş©\j—¿ÕtÚÁ<3OXj³ œÂıo Á„Ÿ_¬EÂ+Å€VÃ.yÜ^êîu¥{,£İPrOÒÙ8®qì²R79Z.ˆ†91`8|5GÓyXSa­Ñ´™ˆÕ-°‚>ÔZ†–†¯ÃXKÇfµõuøL0ÍÈ•].7¢Ÿ4=Ä…¾Ö}€N¢S®%œşâÂW~Q6Éw0#|3%=ˆªÜx!ÛÚœÿ8˜×D±o@ò4ÙnƒQ<î³hõ–ï½`¯à`Ÿ›ew3ó©º~GëÛÆÛQfe,àCò÷· 7I…Ú‚ÃD8L}5…>¼f$ƒpcŸù)b3 €IE·ÙMòqä„ Æ,ÿ`R¨g2'
d£(Ln¬ı];n²^±%9ºùúiÉ0jC‹bhP½- "úú#kCB^$<åÊš.Áìß-?¹HÁ nÑ3PYÌ%œıû€Cbj³ò#ÇĞ¡tAû¡…^ù@uùÕ+6—ZÈnö·Á2ÙXºÅBkãQ'4iº|eO‹B˜(ªb öÅ–Ø#–ƒôñÉRj‰®]_§‰€ì_™g^éæ-YpÒW~ÛG³-­€2AnÁ/íƒ€­¾8kGaŒŞHÀüúÊÓ}3ÈÅ'NL9Øy¶ZX±@6D« şs<â9Ãy*—l‚J:ä[$Sx¼5Ì¤éŠZ¯>ºŠ!k @ã™IÛ&ÿ|³€ÙN^‘ìûäxB†=Íéf€:¤µ£Şc·¬e,Ä2_Ë5 ²ªÉ0é…€ªhÔ-²µæŠ…gØñå˜y4‹Î_±ô‡çˆÇÂúög©s#Š™9ƒür§™£R¾7f NÖ¥¿.P¥ø+]>"á¾³—ÍlÉŒR/Íô'£7íO¹9ùşÄ…Y&w‹¢,!Œ˜¬f1O‘…†Ûß~Ö|¾„õf;W7ª_ëBÍ†=Dr§48‰FÅ»›z¡‘êe~£¿â±pª8HŒŒipSÌ´D0õ»[Šw¡p©Ó=Rÿ¼­ÊSÎôq	
É Şa2>Íz‘è*¸Gß|÷±R4ZMö¹ÃT˜âUÆĞkÇ®Å9.Œ)\èºÑn}õâdYÙË†ø=Ææ0ÚíÎˆ! âP×dòå™¡Uõ'B7ÑUN‘—]Ê)WiLË¨Èk	“J
ÏÛ3Œ
LgB7Ô¡¼qÈBLJ¿^’#>lÛ¶ˆ'7K²€Û:ÓºYùø©ùG*¥	w/S|ş«À¥/wéRøz}màär§b›KYje”0Šk+ µx^Øö|R\5•ìC4)î½:ğÑ/oäáK6lõÎaÌ¼ycq4±Ÿ¹x=âóçy_Ä6ß^°/"2¯¼Ô1‘Ù«Æ#oT—åÇ†{–ñP®7ØPØş7Ám±@Œ’5ğØ§*ª¸°ÇzáXãQRsõ±ÓuíTs)jüÁŸú İ¥ŞÀr|¥i´ÒÉõ¢€·ßšú˜ËœzsA[ã8:õa÷êµzğd­ÿt»Ê¤gÖmy/¬€ü cÃN×·ßWD	ÆŠ¨ÎÓt^ÛÎ¾ùÃLaŠÖ:s'I{¿}#°ØÆ£&îXÿgåØÅöfĞ#Z/ø­8/n>8Ã.ZÌ¸½ƒGtÜ¼:)ïeşÌêùÒ+­bk£ yxv²8~¨l¢ä<óòò1ü¸°ı;úk*A1É@ltm[ sÜ>¶A¥ª×›¥Åş·bÔñ­F«h ó°!d|W°„?½iø%úG¿•Jf°PW¡”ÅÓ1ıø] n¡2Öƒ$W£7ÎûÇ¤Èœ„‹aİøÂÃî€Cª½úFèşÑŸñVäÖ¶d_(?íØ:&ä§{Ì•3Cââ½èeå©mu3úMİÊ—$­˜v|ÔøvË›@¬—,,7øÜó¸o”ëÀ‡È›{ÉÚ)åÔ?^‚‹ÍuÙ®`üéZ”
Ô/¡ùïğdkn—Ğ[Ó£fk’%'}%½¡3hòÓá®ï~æ$¦™ÙÖ¨Ù/·%¨´	è§J×Ğ%"®Ü_ÿ§"¡Ûg¸ÄM}–xí£ä¤XÎOá³wZÕ œĞ2	œñv;Õ
‚ë§Å¢şa”xŸOk…7¹‘˜%Ó3L…ç²YÜ¨¶Ó”Â¥Cş­ª0ŒYv-Ò_IËW.ÃÏÅFS€²=½1cº‹V®-k/y©@zÀYiùr6Yæ¼¨©ÉºB83ú#°²X‚mæÍåĞj/—o$öiÀ+í
­<§&`ê2øÉ;ÅıØÊÖX¥‘]â<³¿XÆÉ e–çYiÿÎ(YŒã­´¶õ<ãdÕ#Ó‡ÿ-+è4 Ù´YVPYsÜF;ÓÛvÁaP.êNÀ<EØ§GÕæÔÊ­ß¯¶+CÃ$h!…ÕËğª¦N®2Z¯\±?1º%Ec>Îü¢KÀ‡’Òfæ÷-ŠrëM³5Œ&Âgı(Š´ª^c~m&kkÏ‰*]‡vM¾qûö9í
Îc]#šèbdÑp„fU>;Lw•òú™;~ZK—ó^®·~mH©¶[„Zo,ãâ<Ju¯—.¸®Èê7ı¦hQà*ãÒ‰HsHEøojcÙµİf¤7•>±ò§ôï/!.GŠïOïğ)PÄÔ´û}Aö-‡ÇùQ7/ñ¹/6Gİô4Ç®»^öY9i< ˆÒğq
¨
0áÛxØÑXÇ];XGğkÑfd8¼#\"…Xb±P­^À¥Û2–›B˜%gåŸBPTtL/ş°æ‡O=@O)}e*GÂ²G¾ö\Ò­	.œ~¤şIêÌŠ­ªO­ë´°¤À<U‚üÀ(Uš’‘ß`yX
1¼“÷E–K/èæNõ|ÊD³HšÈ”¤«go¾Çláò`çtÜ­ÈòEÄ6@yÁ	À´š¯ç¢x`K;¤‡İş$qH9˜8ÿš¹Ğ§ p$“|…Á?ˆzœ¡„·}@åÓ=ütP ò}&>O¨bâ¥ bè57àÆ]Á˜ ôs ¼Î×JÏ1¤*ƒGÅWÀ|ã£æpµC6fõªˆ—½ÀEsíØX?rĞÑ°Q|¦Ø÷ÔY¦3©†Ë(¸ Æ¦…‡øÎKH¿· `;†Ê‡æ‡1TN‘Ãm²ç“°..|Í,Î3¡"R×¼“<©O®•4ãÑÔ~r±{7<ù©K°/n“JÕ#²+›cƒHÙ›7Dµ?€4]Í*æ¾uĞ×6„4LîŠË ±R¾xÎ/.„ÓÈ*{m^[»bá
ÿ(a#!Mak`gqÜ3>†:Zè¨(Å—j`öETÒ) ôàÛ[k?ÕAë¿ğHî©C²ì 3åAt’…&çªkş¶(¬LfŒ¨e}Bœ[¸ìA)Üî¼õ4âEV}{áy&åŞ–rşÿ9-L“,½EcÏ#³äÃJœÿpBîÓN1È~“?Öû,ˆ§ì%ÑtÚpn–š³õ‰ÇÃ¡ãØŞİ¦qá<ø1fF1”/I_‘ÚsxÌ”¢·«Ûò—EròL|k½Øb­³²Ô’ÿ/œ=ëpr¹«Ûø.ë€@Øk¡å¹b›Ë!ùó1¡ô¡÷ºğ—È´Ç˜»8Ÿ.\V$ÇtøúÓ W£IÔŠ~ûDaæ¶á[ğşC	éRQJŸl
©’ ï{—E\°‘ËËºÊ*±†b>íp±Œæ¾G¹åÕ^a.	L€ü£7\·=ËÀv¸pŸ¡yåß³äwwQ£Ø q/~Øáø?áÙõ/ÃRÓd@,§.›Ú•UAÎ+< üø÷'.[k#2ÍŞüÔ!ZDOæö¼î?0øöU9Ş¯´9ù1µHW@õ½uX{"ÿ‡hşVÑPÆ?Q.u`c©½ş”fmxø–óhó²t‹]"Å’;Tm¯†O¿ßš'ˆóÉer¹,¾$ª`ğ-#ŸM7±Flø…x¤„ Bf¼ÀİWçye&ê™Æ² Æ$ãjÙÜÃ®¾ù6i›÷,»ñ=G56İlƒWjzŠŒ‹›ƒ!áTkÿi¬/ÊM¢º¶ˆe^Dr¶Ÿ¢»wä°Ş@Í
Bx¦Ó0W±m41·ó	Z4/=O—ú³µcl´t§ÓdJ†3%§z&v„î¤4;sœBV;‹ğhm1²®€Ÿ^ÚÏ/TìO8y¯+"e[½x3Ö¨P¬1Yıúîû8h3ï¿BY02ö•ºkc±nÜÚÏd\F¸uv4#Û!BíÕ]©Qåü;¹'I¨ûæ‘á·P2Á=2ÿ +`ÄQô:îj†kğè¥ûtpzü& w?ÛŸpØvXqháÿe ö^¼ {øß}¹Pn0w9Gï%•7×k°¢vúÄŞ}Ç&’Úö˜rÀ‚fÏ™®ã<ÿx²ü5©"(+vÉ¢Q
èãİä9;É™ŠÒÿÏ'gåCFÃLeêüıh%(¢LCQÎÈ‰&@şGË]*q´Ş³:¥Z*ü4·Ì7oZ.»¢±
v*!JªÄ“0s{ZîÔXY3©§ö„ë3Z`v8†ØÀVÃ˜(ûÂ×¼¿;,À!°^A‡íV_aŞ'ÆI ¿+²M~ª>¤0;:ò-’í7 `ÄâĞãKs	p²AÌE+¹~ûÆz1ÔkíyğŠL›¿k‰ö*i¾qä_¾åFy( yív@?ñÊ%u¼UjR9(â ¿­û'Æ©”>$9ÅoÿÛ£/®Ñ2¤ÿË®C³Ë`8rşt#˜ñO#ãF/è‰²¾—ê/ÿÑ¿UW¼†Ş$’ÌKDà òúÙO6ùzgš[tßè_Øk-úGŒÿ—¿4@°»î‹Ú÷ÚøµãĞÅf¯Ìy¯€…˜r5^LCF³[ÜëÍğèiÙ=ƒkm_+’fÌ‚>Š4h«Fº…~à$øl7çÿ7Š¥hÑK­İåÔD ƒsP mÁ	!ÌÆA•'ZKô
‚¹ïg8šªjÁìEŒpö””z§Æ?X•·ØŒg=â1m2Ti÷İy\éB1ïşK^¨âVÕÑ÷èNèÙXÎÇ•#3/Â&BOıßGÓA~î©Mc¿Ğ>ñs°îz‘J³jà¹‹rãö5ò´bÓ´h]ßğ U—6>¼2©·#£åÁ%ˆCÃŸm8Ô®ı5Òû¥rtk :şZşGáÈZM=«Ü¸öÆ´ï˜5Økƒr¨µ!K÷<á]ÇgiVÜºO¾*g¨B Ëkrœ<­öz›°Åæ+KÌ:·>“c”Ù[O7fL´òfdnãÆ
Dü™hÎè’p¯•”ôz™²ğîf€‘êÊZÀã¾‰Åvš‚ÒSVÔ‰Õê³y"“d\RG,š[ØÌ0åÕùa 2QØ¿U²Í+oàÀp™¥² Ö{ùPIà|Š(tQŒaä«¥“zsrÁïª ÙmØÓV+±'È^;¼¿óS¶wbH®ã¶¾„%±´ Éñ]ÛP–@¦úØÔ•?oI•yŒ	ôŸkø´Ö…à´§(*3¥¬ÔZÃHõğVƒÌDlßŞ:ú.P%ìB42.‡†XödÄæ¿rT›—Áş…cu‚éW»¨v‚1¡yí® 8¶TE‹ÛÅ´,é, ü‘Ÿ{b‚¥xê-~™ºxöU%æûh5€á+·íåüh[% ¡”Ş•NÓÍİbı’!¡éÎ™š.®Šm]ŸHLÍêÙPÒƒ÷’M|€g’p†V)xñÇú¾—¡p½5U&‰ù–š?¦‰y‰EşÎ³Î)•­\Yy©í+Ü’• lôhå!„©¿¡Ÿg²)p>¹Zıx¾ºs®ÀæÈ¯6{µ
2Ü 2yÖÈØº¦HµnJÃˆQe¬õ‹¬&5 D`ıÛá©ñÆÃŒö"Rğ¥0ÃÀ8 ]Ed1W[$Q	ÆàLiğ6x9‘JßpÌÁƒom/—z—V6W·gŠvòPı¸s¯«gá$pçè÷KÑğ.ão¶£zÏ¬æ} „ü<õ;‰>f²\®q1¯p3½Ö6RtÒŒ(ÒüIg£H“<IÑœÈ6H­åÜv•Bƒ2ä2—ª¡UO89à“ê{['Ú†¤S'&•,Ü~~û}â/…¾ÒêÂš³•åšeÛó‰Cg'S¬7úéÔõ+8k€jË
ôKæ¨Zen|¡Û¬IÅÇÙÛ=ëWy ¥E»³®â0Šéi«4|‚çƒ>”HU@»şR\09.öÎº¯>Ú’¶n¼úxíoÇÂê}Æë—ã$}ÏF:}-™ÊÙ<Ú p;@ç$&<ÍÍ7eãßøšƒ‹£¯/M: ˜Ù“¢ÕvRt4·
ßÌ‹a2×µn—2Ó‘ôò$âÙÒœæb³óéÜb÷Äë¢¶ UÔä°æ(;àNŸj†á”j–ùÍ¬bôúM\%î%ŸùÏZ3rŸã rö¥Äæ×‡‚I¯)0ƒP#Ší¿kÁs°Ch¦ˆ4ùÖØ#£±ô6ÿ7ßwA;…¦¹mÛñQ½Üe¡]\º$JL× U¨b9¯`3Ë-êÔ4à?Æ÷•¼ÅPÃP/4W›»RôĞèz˜È8J; 7_è%g×Êx{¿cã£‰$Ö™*é2°vf¢e(ÕJcãx\C?{àJ‹¹x£a.j¶¸Â¶e<°Ã˜Äáo“éÔÎëŒQÍ4W>I9ë•ëõcÄJ—İuˆcf
ú/ş5ôÃŠ:˜ùm¡I7¤å pİ[°¦ç\X¦4AÛ—}ÃIÚà9œpqŠlã:4åú~îõ¶Ù·f²àÿ£ŞáÌ“Ã§¬mmV¼ÂB¼­À?ïnDì¤*~ é<ùYÁï2ÃK½7jİÈÂxU“Ê÷`ÍãX“ûg¼‡¾¡µşÏÕSÅŞr²O¶ÀªÚsiZòĞ^RéaÙ‹×¦ê·!ˆwVn)§¹¦o!Á
ÆçùxÂò.HÂO•²¥B4'>QjØ›jxÊhöF Bg3å*£gªccçœMß"ó%8>I–E¹3Ì¹eİ¦_‘áç+—}dHĞ1TcjÓY&‡ïåÖOÌn —C "}üË¡û¡™•ş_k~¯ğœAÓdÀ ³:”Aw„Ò¸ÕÔ°…5‰s>tn~‚ìçÖĞŒªëJô
¶59V¶I6°[L±){„Ş"dÆ?ƒ««Y5$Ğä?Ë}¶RœÅLu£QÃŸ!ŸÃ«.Ÿì‹KbuzsŸàkà¼—'\ µÊ¿÷È§ËA”ËÛ”,¼ÒÚ [YªVß¨!%E‚½?¥‰ögC2–²ıàG)ÛğÙt„-šûwÕP¼U6{«ÛyúªÂ¤¤,ßNpèq5ŠU0¾¨@£ûzd¹‡|ı´´ãôÿëI¹Aºg›wö!xH M~¯Ë) B¿k¨Ë“…¸—4’»'.˜ìÖí³S—±qúîz§ôäLÎ”3ù†İœ'‚Éj‘çå‹=|;61làø%_hŸ½¶«ÿª¯ÈR¹à¯1—|r±ívÎ#çÙís1*.hÇ½”hÇ»x!vv’…şBLğá±ˆšº4öÁ¿Á›^ÙK\­·¥Q§óÊÜvı©ÍÄ–FñÉÂ*1œeÍQã|.
B^ëğ¯µvbÕät_ë¾qçÜ4[ç<©÷ñ¶€@=8µLi3.Ù!I£‡ò²’rµ’?’ aÿ;%N91bƒ9TÖe¯ˆUÔ30µE¶>ğ§Ş×iÎš%fˆ4Tº+âeĞ–TÃÏVÂ£Î®¬¸J	CØ2u÷Ä­œs³ë‡uY{VßåÆ›p¦Î>;¾,PÀàP]6,šQ{ü¡ åãí‘=w•¿³.ÁAA4ópÓm³ §šQzÛ8Ş¥‹ƒşRDJê1¬õjıLEÕüI—Åï¦w_o_(…†•#Á¹ÔiAóH72”1îÂm÷BÖ‰Y#æDlÃÓˆø³Øucõˆ¡an„æµÕÅVı«©ßzKLš¨°éÌ9:A¡|î±$"!«zğÎÉ¦×iªèÄĞr¿IÜ‡+ñ¸]½èŸSèÄ-é³°C£‰¨aïU¶5òŠ¯ƒü»—[!K£VeûÌ ŞI1¦9]Ğùì¦ÛP€ÛÀ–«Ï¼)0ªÜùF2R–E	Ø~Sß<¸ÒÒ§¼â|à2œ²I3‘!l{º@@ç6úç-”71l’ ı¬¿4ÊX
Ø³¡€ë`Şr5•KÑ·.‘ƒ}­ùºFÏ.9òıí»šöŒ£|_CÄAˆ‚Œ×¯gR—O€ñR²	[%mëäÎ	] –ªÉ$JÑÂUaÖÎ<Qûñ®rú?Ö‰Ê1uïHa­¾í#b'Ó—•Ram†:Íko{…·ƒÛòí€ÍË[2&öœ÷EFu†ŠëEmÉÊõºÉŞ­qa_Ôqi`ŒÃ‹¤{;%Æ¾—(—â}ıñƒyáÄ`Ïƒ¬K?Å7š¹<ìü{ùœ<uÉSVP;dš×&¶)‹8ùİ[îdHõFˆËD
kÆl4B§õüµ*Lódp¶ÌÁ)ÛP_amàÀn±†1n.îRŠ«_¥øğ½Â°¢’F…×B_Ï¶¼°–÷cÿD¸Ü\Ï[nSË÷~­‚|cÊ	Ø02§!„æŒ"FIÚïqlå‡å¶oıyô8¦6IpŒH±YÈôrfçÜk˜_1æ¢¿GÓ^Œtw'è=ê…9¸²HAsîì^º™ğõ3—YlÆªrâéxú:à	·íÚ“pŸV§iM™äÇIÊ1ÚV3‘¦{0ÇééÇÖäõL^c‡†JLĞÉ‚½?ÔŞÉx¢”/‹šË–7Ê7`R)üI.,†vbİş\§oS¹$SÊgqôğæ‰™4‰áª~ÃÂ!ñôq’y²ëbÈ^·—ë½6	•e×[’ËN½6.;ßı.£@eĞUZ²±±M	õC¸‡9ÚöCGìÏ—gÉ¢ô7ÜÊ©äP¶ãÆ¥/–DĞè¦Á„©0šS‡áÃÅmËh“Éâ«^¸ˆ;Ÿl™Sÿ™XüŞl›=°‹8¤áÃ×AÆÿmBÕÄ(>à†¢¹O t!{@ ‚Î ·*«!(õD)CsĞİë¼.ºÈ¢ÜFk¤å-á½€êMañ¿võo"ÉûrÈÃ‚ˆØjx–ær5ÍV;ø‹Z»(jñäé[­ó1ƒ±Fo\ÇEZokŞ<ñÏ´°»ñ’¼Ä‰ifœg*›ÌşdP~ûƒÂõUŠJ©˜Ñîs
}[$.äFŠôâå³×8ÇÍRöf„ê°ütç=£Œ)±¼]ÙF³B)i4.¬èäşy»·€6u¡hnÖAtòÒLJ,ïÊÉHŞ*OÂ7B­¥ù3¢}EáNèŠu<˜ß ¬¸~p™\ĞöK©j/ö7øØ”el´´q ï–P›ÅyüZ«&ÿMTİ*èÔÃnGIf9û{rßàoV6pbÜİPm©È“Ğkpôí—‚ïûüGœ^
¾ı	œƒ…`)ù%z´,O1œ*gIiïHöÒ¸í[ïÃ3x&OÌ¦’.Ëµëå×LÆ³K2EĞ®4ô­f/°Úrs$l	ïtk'¨|©—nĞ`+?‡şİÆä.(¾‚Ù&R¬šjüÙÃÄıFÕ“™Fä<r,ï(‰Ä%£¿m4¼“â}L8{ıq‰/eöüBÁÈ¿Ä²Í^ÉÉHsp*Š1-#Øx#å0İ"î<;Å<¾oHŠ¶„ÒØ©s#¬åÊ¥_ÇxTe9@ì=Í8ğ{w4`ìü@ìÄQE‘<¾Æi[½…ıÁGÒåäˆµ 0Dç——!šïÙ¦ÿ1T¦¾­±ù ²´… Ö¸Á\^4bÚöTW¨~\‘œq4¾şá&Ô‡]¾¾^şp_·êØĞ¥Ëê°”+2’Jd/Õæw,m|¼JF|©š@Ìu ³²­Å tD›<|1ÑŸ|ûÈöÁ³ı+ØŸİ„0¢Í¬Ñ¦¦âê†¯…¬¤>Osì<¹‹ šH<WœûH+N«‰D-ÑÍrVx`F¦Gw¾UpË†ªôoßûMQGu/©`“õ»/(c{×d‚ò;€ŞzX¿“Œ¾ÙÓàÛÃõéal®VÈƒ AÀKĞºwÁá9bXF7ì+f	Cb‡‘	XQ_w“–Üwìlá?W[,!«OˆzêÛ´åHiŞ‰ù4j.·VÍ6²«ÙH©0ÒKkC#Fw&#‹IK“Á÷©Y]¡œ¶hÉO™øŞüg-şbæâÊ­Ì°	‡gPäwî•(Z4À>Ü^ø¶6î/.sŸ÷B!¬¨9¡:òà•#BÃ.W“[âú[eÅX"ñå"t	»«¯/ÛÚyŒl‰lï,*™”eUÂã1½Ê«‰Ûg£àEÛ;g}Ï‹‰Ê”«ègÀ‘»Š ­”AìÅ[ŞÅŒĞºËËPzÜF/„Eó´'gD—áÚ|2#IÒâfw-ß–õØÅ
ƒ¬ãâk H>u¨(ªƒ‹ìàDK‡TSÇlD˜s¡!RìĞïvY“,Ûÿ£#É¼”ØÅàafzÈlWº2Îx! ş—¼d¶ï TšÓ”á×vü³Vå¨u±æIäØDò ’D|:AéUsÂ??@b†¢ )z}Üs——^<ëÌ™…~ÑNØYV:åÏ¥]›çLQŞ¥(ğxÖö%'ƒï‡Æû&ˆ6Åz‹R4a‚tš©M,É£Ş–¿¼iÔ¿:ûïuqÎ†5\Ù)ÅÚj‚RÂã·Ëí»Q®\2µÎS€›lIŒ×‰‘
·â|Ú©xË–\SPê¼şßİôR­€ÿ}•xr°í?lÄ{Äıg¤%Ì3İá1‚^lïû
şÂ$ä•lA©:vºÆ¨«G¸¼aÑİb’…ºîôÇ&7d»JJdßËÄ½0§,Yj~b&‹>pHR¾wØ&Ê¢ÓqĞøÔç§èEN Ã:LŒÄÚl¾ÆÓhÎ€ûÛæÉ°4Ø!3›—Ãm¢mvÁmPƒPÚg7ÈG‹?‰G@Ó€4 •.w·xÉ£§FÀAH2‘‡¦/¼›yğBİU7¸æmŠ m&W6óĞBÂ8…™tŒB0|’’b‡@¦°ŞJE·$À^»“W_N!L7ÛÃT8Òmà¨¥ïâ¸ßG|×- ¥¨?¶ÍZõ«UûÑ)65˜V°ÖÊ.¿‡ïw¥(÷+^wçlÀ—÷"şÉĞó+øa €¿fí~ë%µ(E”µÙÓæ]&`8å‘¨î¹™˜éñ“)şŒYànü.§+Ş:C‡SË™ÊCeGÍ¾€îµ í~|P<¨N¢À]xC|jÊÖ±Nô”‚e»æÒàiÎ<Kƒ¢ÂhƒnKZp@Ğ€pıÆ¯9rŒµûÏôiK<³6|óy{&ÎËüw¼!xk?XH6ù…ÅN„ğ8l»ï¬åè¨J‡´&€q¿'^×!™ÕækJÀ&Ñø„&9È«KRù:bÙesÚéu˜IFQ
}è˜a2cÒ³ø[÷„CI2¹Û–Ä;Ä6t{sÇI¥ü£UcQB-—ï×PNß)ğÂØ‚“$({Z"úÚñ™÷$“3~|EÇÆã}Ì‚Q?³j÷u¢†¿hä»æQ7y¶°÷ÙKÖ=íğ¶„R%v‹«xjG‚öä¡0¹6l³nx?ˆ®WZ°`ÊÅxt8îòâÜTÍÏé@zğWæÅ—ù–h&ñÈÂÿÌáÖõÆ]U×ÒÇ<Qá<CúfàºOœ^ÕÈQ’3Z]¼bù[€´Û†ÃL?pWô·ÙŞtÖyÖªôîR#xœ(¸;ÏÕH¿é“…ßw-…ÂR8uo`½îÛo_,*Dî(«ç3Îbè‰±¬XÀ¾2Û8ìûBõñLg†Ò[]4«dÛf='ÂåŞÇù¡sÙ„M,–fzã‚Ğ	•â+ßuJ¤„ö^o0úKÊ]FŒØx ¢ìè¢]?ÒéC,mù°é'Ê™ß©=y“01UŞƒH?ˆøÎp®R¡Wh^+V›!»…Œµ}QºQF€ıônIÉB•A°Ôû‡¡¼‡=íÒ‡ß“ÓYDÿıFoÉBFœr¾¦:ÁÖüù]æÌÕ52»Ø‡Æiˆ~8Ùûájx¡ØŠc¹¤”1í.™äÜ¢ÓßzƒÆŸŸL"t› 8UI\el«4êœ8ÚgZ˜©¯ö&iÄR©ØwO%rÊ„İ”Ii_U%(ŠÑ•.èÊ$ eš¯ 4Ì+ü¾à›y4)Â]ScŸ‡ÌV½	ä/q¤&åÚQ!GAÌ§;/í¹ >u{–Ö5½ŠÉËyp/€š‰?Z¤¿~æ#ˆÈğ—}ÙT{Gy×’OVØVêîÃ¦ã)<ã–éx³Ï&lĞyuÀz6¿4gL/ıQÜ¾'T5åÑ­<3>û­ù>èe%6#†-@cÁ ¿â‰3ŞÍ ¤¥€ğ®¯I]±Ägû    YZ