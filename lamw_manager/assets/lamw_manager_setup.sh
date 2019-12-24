#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1632426362"
MD5="6e44396fdb9962851f753711cf7541ca"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20364"
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
	echo Uncompressed size: 136 KB
	echo Compression: xz
	echo Date of packaging: Tue Dec 24 15:18:26 -03 2019
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
	echo OLDUSIZE=136
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
	MS_Printf "About to extract 136 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 136; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (136 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáÿOI] ¼}•ÀJFœÄÿ.»á_jØ {—™©D÷Ñ—rF~<¶JoSø‰¿ËG8N|ç(~Uçú‘i²#K;è=€1›×{?k†zX3´ÇòÃü{>³aÂ,óÍ‰Ÿ é1è
{o%ÍdÍ‹Ê—¼š° Ÿ”éı–ÍBÃßIŸÁîBh,WA,e(›1Ÿ³s<öŸa`<šñQª°şb’”†„=û†PDßVı¿O©õDe?:É/‡Qhjê¶)+ì©äÕd³ H¶™?w.Áx}uq›ÊN8Au^¥†I±‹ë“Z”P~=\Õï8~<‘L1¥EQ¯wD-5çİÆ:›î ¹ÔåëÛ\êQŞ2?6Hh™føê #^[ğÁ<Ôå7<	…xv5–;F¿Š_¿•ÑôŞù¾¿¦ÄsfÁÁ
¹rúZ¾ëi¢É È®;ŸAÊœüZm¶Á+ş©ÍôÕ¯ñ½ø¯FœKıÚ¿§#‘-Wø@Å8€ÅXºæH¦û$™¡‚èöH­)PC1\¹yıÙX¹@b#Æk§™ Œ±G2ã38ğµzlÇÑÃ&®­x€ƒy¨EáábH`N‹héÒõ„q£«¡×ô^ÖŸş~¿v¤8—)”¶äª6‡ÅTFŞ×¥]A'è‘"¤W¬Ê7Aÿì£ ZÖ-ÆI_MNåpå=4Áâ¶š™æ©0—Ièá®ôv	€égÚ­şf";mÓÍ–ë«=+`Ğ·§düJ:Éb­	öàävîIæÇ^÷¶P‰Ëƒ×êÃ¥r³ècè¶DaÏò]K§ÔI‘?dà$Ø-fÜ d3`V–n8Hô%_‚3¸ÏÿµhİÉ-½ücÙXîşkÉR÷†·'; É¼*W×D>á/­ı·ıd;Â„b<‹NŞŸéC4"…ê8CÜÉYb`mÍ¯„²k—ÍK ë%bpïhÇ‚ßÕ‹§\}! °áòµôëeuHç¯#Ñ%ˆi«å¤Ô›ÑûD¯l'ìP4/á³¦pN0ØÏS0åÍ&Ê9/®ë+sÃõÒµÚ‹M*àGÔª`V ã ¢+£_Y–ÁúÛMİ¼!ˆBşãİñS(±È_`Aõ¯Ñ"’z\ÒIÄ}W‡Œ“‡”&pç5Ge…sêà^*88Tå—½:9²F¨ßqÏÆğ§•¸µ´sc$?HÑÌ‰Bó$`ı§¯±{ÿÂ.y*(¯ê™¿1P’2šÕ½ŠÍÊB° ù	Zµá¼K¿X·UG5%5ˆºQ…‹;à·Ğ©;?h6£'…o/¯_@‡È!ªÆèFwxÛLª#côR¼zÁ÷ÏÊéájyü*dD;:Œ|]J¾´›`^ö`õÅOt_5à9@€İ;e‡QÜkà`müû´V½ák*¢ø%ÈáÃ‹¡·º½Ø®ıµô€uY¥¶oÅ:‚pš›VÆÄ“æˆQ{IY áëat]Dì˜]›éÅÿáËF¢îÀù|„_ês¸0éú|½ÅÄñÂŒ$“=“ÎŞT‡»ó$y46j—Û§°:ğïõ½ŠxÖ"Óäem5‚¾— ¤ëÕáW"1È¾çgÏğÁV”à¯˜™NP²y`Ó`;†ÿ;A×;¦ıt]ü7Ÿ²ªtƒŒóI¦K#^Óoê2YL–mhâœ¥Âˆ´+ûÒ,T/J*±G_>‡2TóêÇ¥IV\r0‘bê×¬¨û~ëO‘Å“êùKF²ÏñÕZÁÔTÙãR²ÃbÎ¶€HD:¤ê…Ù²ßÙ§¿’óÃ)«KßÌ€Îë¿<4Œ¿úiRi«
…“ÍÒšV<Š3œğ˜“°®
ï;(k‡1ã0Æ%üìı|ƒa8W!,”AÚí)Ãi8q.ØÀ"#_1±1ÔMkÀ>ëÈÉV†HÑ.ëM¬^¦ÆW•Á$˜=¿`dJŸ"ØLD(µºóx>£Áç†M*r¾$ºÂ6Í 
1BÔÃÑzÂwÓ%9Ø+Ù;B«»ÊíC—ĞÂ™.¸£†šì^~b©@ü"	üªûÊğç€hÀÇâ?$£DŸÜ
²ù Qc|~2`Õ½Ì7UOı?ŞoŸbTY÷]à*è%è[+œb±Ôé‹{$Á>§$¼ª§ü^:ãªœ¹6}qbˆ8hK‘w¿8ÒVÅ%Q¾`¤ÇB+™5vªêÕÕ„@O‹n<ÍÚ[Ñ¶HJcÂv¦«½‘V¦0,Ó°¨³@3L˜jv¾¨êC Ö Å¿pW?Ì]všÁ?m«{¬ùË5fèş6çsoËŞGÚíÙ²f×Ê)ØİPÁô’pË<ş0‘B¢õ°æ±£A7éËÓF^Š•rş$ì‡$—K3öå°Öl«~Á…¨_ùòäÛPÖÚ€™Xú‘†ıÊ¢Tx g½+ú•øRs9™Ã¿oã2Œ¹W¾{òh%ÿ4ÉófıXbÆÆâ=Èj^Ë[´wŞò.ìiµÚïjSfìcŸÛ—¬ùgÆ©¶ñâòÎd¸pÔ G€·GŸŞé¸ u­˜à<c‰Ğ‡ò°ÖÎŒÅ€jß$2ºo	ğ£‚İ%Õ$‘ÕÏöºòÔv4Àƒ4ğ¹Š£ı7C€¸Ûvƒd¤'Ì[ˆ¯Ü*±¦-vÁâ>^t&ïlÂ£OºBŸ’ç†ëË–ĞúçÃeİœßÖ|J,\ÈZ
;¨ºïNœá…Í…I…’<ù_eD1zìKÃ!<çEyê¡a½#‚ãß|^e~§/E­){Şså¤dV(Nı«|ÛD8—îÏ£Ê×+¤ûï|<3ŒøCÑ…°ĞÉyOi}·`7Êÿ” ğëzf}R¾]ôÒÎj %Lê O¶Q>s*FPºê2"g±ŠìPa?U¥Ğ}›jK&Lí&7–ğĞÌgú<¬*[ú.KsÁCSâ…yÇ7¡ïÄ†M²ÛM[}©™Ç§;²>‘FTB/>´ÎÑï+X½«”fÄUÙ¯Ğ6;óZ5]e’ó™p‘?"ü@
Ó¯­eOkç…t^³Y])àbÆ5öbPµí’Ÿ#UªŸN˜aL;¢¨–Ğy±Qt¼Û^ğ­ñ¨æPE{ (Ê\x‘O&Îf’ââÔU/5l$Hxë1W<¥”¼şüÚØÚ¤¿URSa e÷Œ÷İO^qÛƒ’Ïc›Ú–uù.¡=èäß¼¬éº±šDÚ”/	•=1Ãä5mÔ ÑHã)Fyè”b¢ÉºÖ'èŞF}˜šSÏZÊÑìûMÛqpæëtŞ±Ë÷{Œo˜‚ÕÆåQ¾:ïÏvóÕƒ?X5Ñ«6¡ú…h@ÿ¸-—œ³:TG0ÑÆúXcQL—h§™•5L7Ú¸¯{G§˜
ÇmMÂDW]Q~‘Üm¶´í},w‰Sek Iôr!;\¸F…Q ÷¿ŒĞ5½ÕïßŸÏtD.%Ê1ká¦ÖÁ‰ñq}¾ú‰ƒµÒ~dË¥
2,EÑ—œCNâÜ€~?ÉówÒƒüPò·\OŒ<ÔÇğmöÁE8/êê!‹È¾H>wmŸÇÒïz¡ºóõ1?•†›l¥=¾–=? äÕÇÎ™>Ä¨–¶I^šù/Éşc§ŒTöı6«Ör Q‡òN¥ŒVsV¥ï3ö;‚ËG*V¢1qWŠKkÅŠõõV³l	M¹ºË¹Õ¦yŠXCMï6K—³W5ŸÛw}Ó‘×LbV¼D"PÁfeımµôhÏ"<Rí¨îI$T<{\·Ä! 
PØâ ]ËréadO£Å£¼Ûş`Õ'Š‘¦?[_­‚ş·AıÔÔb:
ìË1#ò~Wğ¦ï±„Š€Ü±]ÃZÛëé{/zPnb ÂÈ-ÑY<mk‘® iÊ®\œõˆNïŠV½4OxÀe.'wºøz¹´Vï+BÓ_‡UH<gqåú	Ãİ^xæ%ªXfPR ‚$\—Ùq‡2ëã·,ÉŞƒÀÈœ¢Æî¥¦Õp1Ì¶àî¥«Ï)gB5R-“phDŒWu”ú¬XuÚ §Ÿ“Y•7f]ê)´«Q­ˆLô&#Ã¡5[&X8YøùTÑˆ Ûá]ÖÀF`èÄ`{lnö!YNÏ¢
şxZJPëÒ‘íöVÙC_·FXÖ´çerNi[B&J ˜?v@óŞ¾¿·¦,bgãéš‡G#~ûæşĞj.!n—ëC[7É¨Ü¸BPˆ,DYõó+ ÁıI?J‘RÍfØ£}ãŞ;H}¹‘Åùv3AæïwÅó<´
@A’5»ôî;¦¶òÇx‰O‘±@aLz^k¶kŸ
+g“.2AÕq‰S:W÷€>¯a³BÁ–¤!Âr1õ¦VÇ^ÏuØgîa¾ËAò™¹®İçeA6nNØ~>"ëM‚ôQ-Wìa¡ü—>k©Ş„~Ò#}†I¤ÔKZûHœ?cÄÇ™k½ªÂT©%NCn¼ë(­c“6ê$Mo+–bRäŞ»ÔŸj„9&$â½Î4ÓñKd£¾ÅËÑpCØ·Ü¾
ßiŒ'A’mÉÙ…¶(m»ƒ† ¿[‘lgÄ^İ1êÏ=ˆÔBŒû&ö“3¬Ä‘kè!Â˜ïC0£{A!€D6[éj:®i¶-7¹>˜ùØÕVòÁûvì éø1:ÉHCZUÄaî<Íëğuù•Ş¹§£°ÏÕ¨9¦ÄŸlÄq¹×ƒ2¸’hç`•ıŒ÷œÇ†‡x2ÃÈm Ü»âD¨''^¬Æûb¨¼uÑ*zûçŠßªU9oÜé6ÎïåM}ˆ¼*ü#!>ÛGOÌ3©ÃŸ¢
wn±Íû+Ø.1ş@*™°­ß0]´¡×^³ª›¿?€š”¥â»ãÉÄ³ú<"¯@>W04ÊÖ	ÀR×éMB[ç~o|ª³+ã×	Do”¡4¬Ó¿uYŠøïİKa‚¼P>·>{kõÄ-Š•®öïâåü¯	ñÿèÊ€oÇz‘gæƒ/ÖbJ;İ“Iº}ğµ”'/ÆşhHGáTÀêh÷ê‡·!ƒâq“ƒsšÅ9$?xÊå2juvdtãÉ@A÷4-¤›®ÜÎ4ïAŞgªºE°<ä~Ğ·íÿ©1é¯—_Ò}¹KuÌ€”†ºw¯N£'ïõàAèZrŠµ|ƒs´]"zï]·7
HªğÉU¶ã9@«J/4×ÂİAÍ°4ú¸Ş½cw’%1uUdŠy\áYb`çFÌ=hñæ‡ŞßBcÑ›Å6ä°–Ìo_È€m^Qä¢_´ånæà»|ƒ‘º½¢°ä!WX`,†İ–ê•Ù-LpeKS84OØM8ÀYiP-nØê$­eäÔÒËd}ƒ<Æ`_k±)ÇaÁÚæì½-`Ÿ«@Ù3ãÏ3‰Æóîµs± ß›VLwmJk£‘².ş#ZjØõ¹»Ü˜rè\É†šİ‚«Üª¥+ÖcúËÓ“º¾—	îyó:Œ·½‘ŸÆ)Ö}„a6«Šéßå/L5w¥[j±áore²Ögsşıÿâ\± 	waRµÒcÇ©û»ñOf+ğªw3Éà‡Y;ËUû¾L7‡±"<8ßNkc¦½Qà’Ê§&#y0‹MA<–pÌ¸ÖCTk™6S	ííx^í#U¯8•F‰õØÒğwÔò¯Ÿ±•ˆ85È“ŠÏPq/|¨S#‡ØöÃ¸è¶sòCHT9i¹a§©Ï&¡uR­Ğ6^ê„lÜÜ-_½cÿİíÜÀFmd`$“µwû®n»>jAxíÊ „ó›À1Hë…âãŒˆ("¿£½â¢Væá¤ğ/ß ¹óuR=éŞŞÈ%ÊiÀngEQ'fßY+½mÒ½ÁP!"IÜãƒí`á/?Å^‘Ö²˜^¾÷RFT8l…1™Äªgù8,¹°'lzò¬)–<Dégı,Wú(õ89âÊ BÕx×[,ÀØSbtV‚ùQ”1"æsõÑ#â…áÉ³íúÈ¾	1Ä6|MĞÁñgæn¿YT|oˆŠ‚ê‰u¥aƒ v‰hkc³ıøqhy8×Ä$i‚82³¡cD²·_øC×>3´˜şşŞğ·”ç†gš
Û8ia$™"RáºW  ôs²ïK™eDÊOÆB`Bø<*Wî:Q¨¨MopÉúŸªcƒViÛğĞÇ„x»y9¥’vŠÖû5‰Ói´fÃxø„y7áŒOÇ@xn4[*?[ãÇß>æ?õ}y™È=ªõv?ŠÄ£u¾äÀ­"âG9áßÿYX¼œÖ>ÓÁ^À ”İ²¤D¼=u—&ì¹×*mNØ$Â.7–ô"ù'»ßÌbÍ>p”÷J¦÷ã£íK	NOd·|™¦ æ$²¸“Ã¶Å_¯qS0¶¸B.ç‹c¦IÄl—ÿ£k!{"t 2üİ[vÑ¨ŒÃ=FÄ1'š˜)pŞw^ªKº»ìÛeûL¡:ehßb*‚+%Ws¾EO;ªªT/ÈRGrå…–Î1˜™c›wÇŞæÆ¯ıIî‹„òc‰ØúÉoøÇ8ßzk`ğQ1
âş@AI§8B+…Ác\½\÷Ø[Ø“¿Ï¡şG+›Ïw¦˜¯„7rakØXó‡ss<Ù3<qj¡S÷5-rßÿf3ÛF†-Íù]ííE'Õş+ŞN£, Aû€¸Á|KK<ÊçŒîµf¨CñéÍ&|ËpN§öµ&=q8¾<^Ù!whœ}
{6<…‡D@hzËÁ–ÕD©ŸÍ‚]±®À¾ØUmàH˜RÓZ˜SŒ(L_m¹¸^¯ÊÛ‡Ï~øR‘'XÈì#µe#'» 0”NËÿŒ¥¶&:È#ÛU4ı†Tg¨ßZ8ÕŒÈ­ÎõOcÆúUq£ØğR/í„nOEŞÊ´ø-'ëA¢Ñ²0…)ÂÔ†ü6Htõ¨4õ]|B£ğ÷ÔQÜ³÷†sï8ÖŸ·^Âä…ßL‹}İÔ0ùîZe/mÊÕÂ¼µô ößùÆ¢İáU¾m®Ó¸“ç•PŒú ¾ñİ/ÌÂ°TPÑÓğÏ°x‘s‡¹M§|(_ôX—‰Nj˜»À+ŠÁmUÃÁ~RSsÈ_sæ·ÚÂÊd]‘ñ>`ÑFŸ G1GyF|6€r<p÷ •’s	[›U!z‘Ènñ¾+£‡·ıä=¾ £¼E‡1ÙPt\™¨24=|ÉÂ¶µ!^XEcüÂS¯íÈF¦§6Ìt'ü(5|Â·à©vòâ NcE902qÉ*¢åU~Àâ?®wÙ'DNs8ığÊL¶p¦àŒÕÑó(.åÇwÆi|PÌ¨ÉÂ.@IòúìøŸ	ßÙÍñ©İmÏFZ˜=ğÚ´ViP-µ°,ÎB,‘òŒ°»ûåP+=?qAŠ-(ãF^tlz}¾I/0¢ßÂõ¤ u„ñ¯È°`ª´õIº<6±·²\ÃT`B@Mr$I8–‡¾‰ÅüôXƒ‚€QlİQäv /*Èl”âD ³J¤ÓİH+­¹ùê‹İŠDÍÂâ[İëİüÊÌ‡.•‰×¶k =Ú8Qò–9x±m¿A¼ÜÛ3ğ„Kw$ázÄ YD’ÈÓ/†‹O†°ñôI]›„¸Ió‹TÆN+ãëÙ¸Àˆ¼–ºem¢oĞgÑ^~#Q3Ë–·BBË%´.PÜ•:³8ªGe
¶‚æ¶kË.Ñ¶òä2ù¡bŠ°+’Åüf0’jr½êSr(p ?j{–şwE “m¾ßéñ,OQ²‡¾——9!Uu“ÒöWİ·WğÀ½ö?ãÅ¾jé¾ZÇÔÅ°ÚxÔs‘k}Üú¯îZw_Êªe~ &R[Òâ}#¦KD&`´¤Há|A$†P¯5jDü/ª_ûUhßˆ—½1ñVŠöÓgøø8åpnDn vQ±gßáTô‘3–q““øõ_$;wôu3\¸Ü"•ËzuUêNz“Õ•\wã®¿ı™±``kà5¦D›°Uë[kœ¦Ó{lkÚ6@ïËÀœ°ÒË‰˜ÀÓ[ÜD¶ra2¥R¡)”¹Æ–ˆğì<gÿ¤Ê¬‘ƒ}ŞÃ¯˜£+czå¸&è²·vdqLÜRÅ%ıForÒQÙ@«G½Âã)K1ÄT¶ylòqşı†ad‡d×¡E•.…°W›g”n‚)ñä*C-t`ˆz„WFTœŞp2 j©•ÊP¿1k)hTĞx‡px$½¹¡NvËÆ®?3ˆ«µİ¿çü"NVm}Ùc²Nª’©îòßš/ûè7(Ntë¯G¢FWìs³­h$›PHâ9§„KÚ >ı=xÕrJ½–e
|°ì¤n@Ò§Æhğ–†ñM(M^çlÓ@òfèeìÖÕöò¨Î¶>¥ŞvØ˜Ş¸ò+ë'«`üX%b(ëké!*3’ä™1Òœ¼7É“SÍÊZÑ*êèL=•ëlµ¹ku}Ëyfš÷‘œ„dMqÏ:±L³ĞÙœ* …Sı}şhƒ,¾È@!9o–ãˆÜØ 	PÁç‡3xÇt!Çº§q&ìP:%*“i–È#•|D+Ù…€ÈÉdªƒhùâj3©2Ü<ÓävÆ¹ª¼ÖiÉO—OêşÂ0 8X_¦7ş°-Tôók‰Û¨ªŞŠb‚×ÿQMü·ÿÄ½€ÚatÄ|Ö‘ngT@Í¥)[.'€+¢èÙ
ÍÍÑfuDbI#µ)_ñ›26æ9Õa“ì¿¿)$¼7
¾Âiı„Æ¤nåX>´íùW'1(st„ğ›O‚6áõZšñNÀÁUì.Ö~İ[TT»ŒÛ`o[e;eŒ½ŠÙ¹›à¦2ÌMG@­ó’[©ÖÙş‡ğ4:rI|ˆ"mµ6Ë"¯™È:g‘à\?_šÆÈ«¡«‰Â:ÖÚ:kXH§L Ú$—‹îÚëVôúZ2tˆQxâÎİC\Y¦ïî¹\å’Q/IQÄAÍ¡sá¾	8‰Æœò6 ^0±]¸ô*¸6ı™í™¬s!Ra²:EzCLô¢ã^@S­„qP í&M>Õ-xhæsÂäöÃêÃÙ‰Ğ&LæÅŒI.5¢èØšÄ’mj‘3 t>Ê$5p©~ÒkX®§uOLÙLèÃ¾»åÜ£¥ªc¢LÉ<˜Hõ:j—à’İÜ£fê×n­6´W¬3ìù´n¯ğÙ9ó*aúE¨4!|vÙÂÂªXVzö^~Z7¾™òÌğ„›ßÒ _£!´’c˜èó†Ãºb”'»ƒ%6Vg–bİPælbO®c&.G‰­ş0PY)ºÈ%Î><ÎúØóğáZÂåáé;ëû¼1Ğ6´1¯K“~ÿÀƒááÔf›f,×S«ŒJ'Û&@öú0æ*SÛª·&AefdBõĞÉìÄñ¾ì¾]W™Üİ*kë]†ÅV¿¦¨µ±Š¤ÅC~¯»—¤o§ZpÜ–ø3ªÛfN”!ş•ÑĞ:Ic|Ö«ÕP!=ju¾Ów}P(z]>¬âå±]g1³Gşx‰{Šœœ²® ä²§İŞ!´9Pjr…=UÁ]aŸ3FæÂ¡Áœ²ÿ‚lp.»fpÖ×ú„+_?°`%.M)»şQ÷[Õ&<B^üS£G&7Ñ‚¸˜şÕ!—uœk”+³“T½¦â=§z X€F+²©vFĞqˆ«‹Drôù‘5wEUB-qóŞg¸·%Ínø´çï8*@¦^–.0¡&ÑÂ¥¨—Ãb»ËB3!.{™VŠ=/AŸ@×„«¼‚]×)1ş¤"^í56O„ğs“Ú>[ÃNSyÒXßaß÷ÆïCi,œ¶ìâ\çYê	·¸+ËñåÁWüZº%Ñ%Ë{}æ·Xn×en+ôÍPÊÖ²Ö5bæãyÈt`Ø%YdfÆNâ0ø…M!X Æá@å}k9S–§iÁ‚9$‡qÊti$M¨bš™´Å3ùÕf’¨Dı£/rÂqSgkH‡;ø#^œ—{¹¿ş9CmGÇÕ]NÃøÜc9tãÜr4“aõîwı§ã¾¤É~ğsÕ>1[»Dès$ùà–ÁsÌ1M3_X¾ûúæäe–mB†h úædÅ¤k˜9¼2Í3/”±VØ¯j©¬•1 éğ³#ğWº`{UÙM5ÄÆr‘èºøÿ*’åxÆj`#§^ĞúTX`¤÷ßã%‘<yÅ,öY|Ac/­_ÓêbÃ™µ4sŠîa`ÛŸ_eSÖ(]ıšÜyP³åğ±yŞñjŠ´Xp1àx;¥UÀ¼nå…©×–j†9h€t\g?¢Ç¯vFÓïVVÂëô)Tåj?7|†TæËÜ•~C•Å5¢Oı!nàé½~}*vcÍ5©…9¤Ãñ}UG9Ïäº5”õÇÇî™p%ey‹^Íd£¦¨‚ßù¡âP/sT^•’2ŒMš¬áA…âßËìlÇzÊâ‡N#A­óµ
Nôš'÷~Î ©¿˜îh*ß$v6…#È?Ÿ3±°SŠëBÇÕ¸?cË ûTêDã%£A~
¬"»4ïtNd‡Q¦kì<×…Æ]5yt {O@ı‚¼®8öyiªÉ ¯('87oyd?ØU,°UµùÎ­ybâX[ˆdT&‘ú_	ºˆ–P˜]–b¯¦4væ_î<\!Ë æ´êÏ¬i»j'/0÷+÷š¨¼…^TÕ·ï‡–Òvh"‹)fÜ*EG96‡µc9ò|£ïèb3Æ	:‰FiµçS@mtÄ0êÍC—X#¿6’0½ìYo¡>,	Œÿrz`_.§ÖÓJÔóŠœò¨º‹”ëê·™'Ğı4Á!f€¼7<ã.ª*i\A½õ*ÌÑ/ \A¬²Î6Ì~2è¶á”µ8üô 6Ò~¬ü1ıÌ/ÏDÙ+ÒW‚|Ñle˜/$–kĞ6NétQúƒÜæ89™ïs¶rÏ4s^Î@ç&}y²¸ÅÆº€Æ!]Å3ÿŒj6	Iwçñ£AûSŞÍ³%aûã×¬rn­z«^6d>Iç2±¿QlTı{¯Nä¾Wt›)“_íãk¸»[£øv­p=(ê”`“ñ–ïŞ¾XöÖŞ‘'ğ5ğˆO67™¸:ô$Œ©ëòòaa¨.È%by;£Xø©ÊaŞMş¶tçc¶.»«lÄ](ä;ãï5¸uN¼£UIÜŞÆj'œé™–„%w»„Xã
ÛK ×b+:8%3½í1Ê‰İÂ^‹±Óà™ò éêNEÆëí¿ı8ê‹ÏØ3¸Mz0Ò˜8ÑÇ‹TàK›Ÿü0F&ä†3¥M{Ê­+'8ıd–‚Fƒõ‚²à‘äı©®K%½Ş¤.S<ñ£M˜|j2ükè†r”X~:`a½·lSj¼!í$i|ÆÛ¹,×sĞÔ—nv1Kù|¨=Xi¨Ël¬ëŒJœ¦ÙSaØ¨ÿ Éa}ü£3 ƒ…Â‡×§fÂ¹³álñ¹ÁJèêĞğa…¤ .~U6‰Ÿ_ÙìCšÿÖ¿°bøxy¯Æâá¬ +ˆ}Ãç{ÈÃÚm´€ïá­í8Ö“k®§š ›±z•Ü´Ït*‚…]ş”ç–ß QªŠãÉ[E?økéŸíEAÍrı1¬Mv6ûÔ’šÚˆşVr‹4.Ó†ÕM7Ìİ—Eeg£DKî&yµ)Eïø’§Râ%¥ÖS@éÒ~\¶ªaz“W}¥};=xœ±Ü[@–ZKşdÜKP8Æ†0yŠî±Àc®Zí­vİú²p¹¿G#ÏÕ31¯…cU¡ ià`:—Cü.=û)4¸(È*h14…èm$Ya‚[¾«¤–c t÷„|Îü\o—C51Â²Ì)L6³uı'ìJ’L	¸¡4÷a¡Š8)•ñE‹!x_ÜSueˆt)Ø¶d4 i`uPıûC6ÅaZ)tPØÁóûÆú¸kùn`©p’÷Mnu8uùëcÂj@ÇÔ§–kêñMşWò}Ğt­JlOà0NæM^WŸ.…MK6P¾æ{šÏI[nû#ç/%?ÃqG|j¿İ)h ¢æü&Erynî€§xÄ6s°HXV¾¾‰¼íĞ•Xš ×ÛPTì•§Gğ£/kªûQJlaÑ0Xpu=éÃQ“D¬Ãå™¾—~Œ§ÚÖß]ÑßÔ@‘Hü¨Âµ‡¨¹wA`©•ÅëÇíŸû™#„}§O8]ÿvğ›7Š®Kb0¢qµì&VíË(éÁYŒ‚¨à¼wé÷òª|˜›ßĞ§Œ‘«¦ÁCí|ÜcÕc³iÍYšëj]Œ?íè×•Üæ€‰©|Æ¨•÷›[=e¶§8q\0×<š¦V©qœc£M­ÿ©+:[s+fSª–[r_M
cµB±¹î¤–u}TŸEò=âí‰kğ ¥‹~3ubw|áÉ„ ÷Ò§‘>„.:@12í&ªKvş®l}	1	Î È•™„ÕùŒ~GÅ…ğµ–Ÿ¹ºD¾j"›ùş³£B`kñèö^ZÙM¼e¦ÎZ=î£ú÷ÎÙ[‰Éë[1+Õİıš ãÿ‘u /N2™Êü Â×m åÖüDÔ#àxk[‰+õ±ûŸÒ´òOÖpÕ~Yë;2gÛY’§‚£*O>:‹Zc¶P R§JKºáVıàD¹/¡C÷^Œà¦ø¡Ì$ğŸxtÉ:ŞÌuw3è±ç‰Õ8óH;ñ×K½š”}ˆøÒ'BmÒÿ™·…,rú{Ll„Rğ>Í­Ds¶“#·"ë÷‚@gT¨ÉÈÀ5š,ª|±õ¸×R‡T–¼ğnvÆ÷p€F>Ç¢qÎsõ×ôÕve¸YŞÊ7d¾<`:¯ß
êÂ>ÖìÛúĞ}JŠ,4câengT]Ÿp´É¦”ÖÓ6¢›Ÿ§ÌDxÖç1‚jx—ğ“²!@Œë!Ç •Ã8‡[¹ê™l,rØy± O~ıìZæq§3¬Î§p<Liq¡Ÿ˜hÚŞÉgzA`ıD9_>YaXŠF'¨]nâJÊ^µö¦©ĞFóz3E#ØÕ,©&é0Išß¼ÇÛº"RàT³DùqÒÀ)×¥pÃ÷üxA_¾¸†#¢V†rŸÔùÛÎpE‹n°‡IØİTi’E>º¢É*õDï’Bp;?}9}¨6œñ šV²>ú†vİ(ZØ¹]sV¨søm«‡ü¾OIíÅâb@ÄnFûP%w /'â´|ßÿŒVAYÿ‚£÷ö×Ã:‡l»ıî$İİSš@^ß˜uv²ƒ”5Aïg¬lcŞm¸´ ¢€)ƒ´N”DFæã–é3
ë9†ÏËñ|L³á]4YàÇVé7MèŸ¶;E.¶ÊìYnZü‹sHé(K‡('»hÕXx?zÖ‹\~¹P]>špØHâXÑ˜Ã³ÂîÓ†&ÏÈkd-·À]tø\+×ÚøEš9„Q×À>ï8,|½ş(<¼¼ËØìÈ´Ü"V_ãÎøÆtfhVÿF´16ì®Ú@õEŠ) ãĞ•¢œ£7¹ooúHKüİ?¡%×øDÂëMóc»ÄÑú1ÉÉ-¿È3’µà°¯ +sßù¶:ÓåËÌâk¶á&zÅ£~E"‚»Y»¿«H»\EÌblK †XË	?úù‹¶ÀLÃ:^K”ÊùÏD[4še”ĞÀ ¥ú=ØNmØ|˜gIğ>[9ñBc¡^S=*6•ƒ®tŠW4ño³TQQğ´SI”Ë…À¶y4Ël±ˆşŸÏTo’7Ä˜$İÉ#ê[’Ë¤Ñ–O2/Xj#¿fÑØ©  Æš¤nÄòıÄéšZÃ«¨é¾1UoS]=n±‡¤>HSë)‰]6RxŸÁÈ˜“@Š$ŠŸ›x'Ê‡²Š@ ”OÀpu}³•¡ù8L4×tŞÇú5ögj3U#_ĞWGÖ¸¥¾I5ìšaòæª'–îmô›GÄİÜ¹3¢f˜_Š®/¼ªOù‡+$7»)JŸß:)m¶h’ÿˆ«ü_À„š>ÀÂ4€™İ©y˜‡Ñ,Çª8Ö½æ‰ÑÌV+=™—²†}°©#”Yöe ;)ÇYÂM.LäE&Û,îfHaÃdÖìÇ¯òÍ>·eBXóà'Àü_«p–r†°û2EÒ«n©^—3ëæ“>°7f†S\Àiìz:İì¬9ø_^m>›á’u{âv· øy#Âò‡ö»®²€BÅÑİ"şb:ØZÎJÎ`/Â}væ÷Ë¤}8”©£xC_±PrQµ7¼-lòo¹]óS£ÙÛZ7 ¶„Cbüæ©Nn@§{=ÄìøA‰kìTş?^ÿ‘”<´c®Íf˜Wç²%Ä‘ö:E˜›ü+İ1³Ÿ5,_"ÖèCru8àuĞšôäÌçÌ2Ò•‘ BFg3jÿœ!¿ö5ÿØ—K5ÏÿvŸzYÿÄ½â·¹¯Í
ÄEÖÚo[]t¨°^œËgfŞ	 •æ|Ì§›IÕ œ}xXì9éã§Q“¸¡–¤-BŒ¡MøíØ…·ÙÙJV‹e‰ÍîÛÙ¸„§í
‚EÇ0WáxO	èvFúH¹¶t^Ìÿ9P³¡uc.@ÌÿîcHêğ18Ì0,´Ê…††èEÚíf+«Èúë‹®äÇï>;^˜å5½µVgÍ*
?_˜z[@Jû‘£©q]aœUEû6©·€(#Õn_Œ¯}xŒÇŞÛ6·)!øïPøÛÚƒVKuNK$XÛio¯…¤{^aÑ4íu5£3¨r~ŒÆ@t,•	(g’"£ÙÁô‘Ü«MWÑ («á™º{!ÌHÅÿ‚*Á¸??ÈĞ ó`'•ïZ<Áßğ¡['åæB):ıü©?±=~ß°Ï;áƒK²qePKkü~\œÑBZe3<Ï[ßÆÏs83;KHŞ? hk;zLÍ_Ä9ë£kh.Ûri„Ó‘úÀ3›åÙÉ”Ã©Ø( ¸<Å Õuõ “¢G‡à­†T¼ÜœNçã‰±ŞÆù“{Â¡RÌKNñ‘òôTşù¯¾UOüÖI0ë°·ëÇŠ)sÄåfáfj	;ğRâ·¸‰^>šy²—È2¼>Ó'Ÿá|0l§áãÀ˜Ü‘|N Ãy^—–‹^Ë&:ÑÃ›UT¬•ÄFÃĞƒîø<ª½A—õ©™2LëÃiü‹39ìş9èÿSx:)Š›ÜÔƒ¼ŠU®ÌbÜÜõï[,ÿCrèÃIÇ±îë³BŠÍÃñf¤Ì©Š£le~ˆPá™©ØÔş^+ª3·‰_r9ÌÀ§^wî•ı «Ø4‡}Ëöö'õáÕ4å¤Bö	QĞ8;ªdó†Û÷OÑ«áè¶—ş;b÷yó§f¶7K($ùGí“1ŸMê×Ä³T–ØjbIÖÁ(ø!\2ğúæM#”FG)y´tª^^9œÂÓı°·p²°J,…]í*êaÍ¡¡ª4­œ‹Î‡?m6¼Ä·¬syÃùaŒ¼•‡ˆ/Æf0‹ÿ™mA_IÎ·û°(çî²AaPØPbº ¢ûÏ§ÑDpóA¯Rkî„±›No'a)e]Á‘œKÕŸxöİ0AÛîœOòiáÄÁ”£³ zM&Bu¡úT?4BtŸ°ó-±…;!Íw¶ËuşÏ0{”«L¦…ıÚXv.]åÿÜA—4jN×•ÉÇÑìĞ\şr$Kj™¢‘œ/½ó•	ˆ”Íár!
R“—¡g§V½¨üúã:Ş]¹Ô¨ø#ìù¼ëAxÃúxÎ9|ÙÎnï·Ì‡?!Îó@°—ÄŠÚFîü™Toëøxaêî.`dÅr;!«í™é<›Uëkê.ßÎ;0ı/§–å”§e­×Æ
’ÚT\PıçÖÈ\]«ÍâŠ¸	ß{²Eóºëš7ÛÀ°ø¨c7] ¤Izw+f©>ï–¦uÅÔ~ºmÉà’ò]È2s+)ÎrÓY²úÓ|¤6É9gŸ‰ÇÔ?>×!ÚëSêõÖx}ÇãÂÄ¨>uQ|†¢úÈ:dùÆyót Ì©à”r¢ , "©È-D{,/DiìÔİyë>úI¼0–Ù+ÛcI}«Œrñx6b¿ HÍf‘'òõ÷bg‰Äüíô¤aKÏ¤õºØCSì¦*ª7!SW8İiLìóŞ„6ÔdlÊXÿ­ùKâ½©Îz»RiBäÕ_fæÓ¿Éë™f»W+÷ÓZá;ÄÕòÓËzc÷Å×n?²Q^ı<î´İ“fn­;}I>–©ùím\D,Ãüb¾•ch±êƒ¤¾êùÍÚæò.µ†›—…#¼Êgx}kz“DGY†Ç3w¨Çp%ÚP&2¼’æĞ[Ìş¹:ÇV/::o¿÷#1ñ«ºD=âğìË¿ıˆÁ¹ªøíÀºøƒ‰li@üß£®Çğü a°–}‹’Ò‘[şi¸˜5·°ó¶ÿi^Œ1°W–Hª¡ç^û×6÷\!ØÕ\2Ú‡Ä]„9©Şº¬]UnãHói2¤va‡uäïö¤¹‘·b	tßíZfc•P€˜“Šh·óÕøŞ²Šƒ‘²ä/é7‘\U	3õºI;€âŞö‹u§<B|Æ$^QÛä¬&© Â–äy¶ü;¼\íXï'ã~i¾|G`#ˆo‚¸²w`„d%Œ-É=ìs›¼=EÉJ¹Â=C‰ïññ]%ş%j¼‹ò¡¶äÈê}z~Y5·¯bõŒÿ$¡S0ú°l…‹0ğq'm¢;°³±F}È–¼õù~'ºÔÙ_æ¢ù¤qÅ u±ÁxÓ!öüĞ¾ÙRó5HE´ÊÜ‹¢v:ÉŸÔâ[¡º*i2Y­´³ª’D»Gİ†FqĞÈ½¼SC5¼ø×=js¡¹g+sæ.11ªâ\×!Ë9ş:Ïöé™,baUÀUqpõLç%£Èå¿IL’!±)rô=¢çÒ¯Yµá¹t·ŸÖ¢M²y3 fİ
ÉIï˜õ´éıµ‹z­p3<îúuĞX\ÇR9á%‡Ì„\*( @ğ>JRsc«‡>¬#oÔœ õ0ò¢±D!oWÌş¡äÿ/š}³ ğ«\›¬ZZc‚ÛšEÚ¦_ÑÍT-·ªÄà×üÄ}îã±mØÑ8E·)H2›hàè¹ß×DpU(ÚâˆÃ5MòÏ)ƒ6ş´¥Õ·M\-=É–$µ :ÙP jçF0tn¹Ğ‚?Ê ÏûGbú¶z¦”’Q’‘Í‚à¨¦4à§"3séŞWä}åÉ¿\Å%âÙÇû%uVW‹º‹“şÈégYsi£YÖğ³G{™«fNÙ•J]O€’³Ü °§8’5N‘™•»g°ÌI	Ñá5kšˆ¯ä2°´fTÉ'ï‰2Äè>Ò(T^³£~Ì¶•ëÆˆ™ôlò‚ÿ²ÊÒÓ	Š£_ŠP¿ÒaÿóŸ¼k¯Ú ÒÖ=—	£\ì9UÃ›á@ı°q½kFÎ—{œäF&vŸ96v„œD4a“˜@u÷¹‡¿ÑCÑ`K”¶vÒ™÷àqÇtícŞg÷O ®Ş5£É´ñ×kZ)Ä<¾Öğ&	pËñäp+—aK_vZæß,®jê¾ÑI \(Ôwo”9êËYrG½8¤bÂ}E¦fØ`Ğ¯`e¡·]mZì‘(.Kµã–)®÷·Î¯Àğ 0Á5éÛMF†pÿVfà s~JîÛf« †º!v*æFM‰:]hıI¦-íÀa=ï1æ5/ÊÒ4ÚÅÓ£¿Rúö)–g°ş¢cv|…³½aœö	æÔÃ 67Ş6Ê|®ÓÿŞÅZÓÉ§{-Às†ŞÖû¬ùßüKÊFH€	†¾BëÜ;÷¯İŠX78s2<Æœ´èNX8eÈ”èò˜Šï—s×ís…¿VuÉ¦ÀİDŞ:bº¯Uğ+õdf„jü Ì¤mãÂ‘Hš)Ş§.¼ù¨Íœk»ÊsÎÙL’å®»¿,Š.¯R.uåŸæÕ."•±FÑoşl*:ì®H¨–èÔ¿*#¼E"Û{çW
«™˜šD…Û•ØND’f‹„qªEïş;±Ê’À1mR«	8“£şãê=ËŒ#œĞŠcâ7Æ­ÕÉHLè¿h_‹ÁşÃ”¡ß]Aw¥}ä^¤{õ™€i‰¶|XúñÚ¬\ï¨èÉê\`ß4¹! ßnvN½®B3ü/˜Äù¬¾œ„X±»ŠpüìÑ_?CÙìı‚»ƒ#á3{TÇ4RTà¸4ÉW¡÷ú80sèÑÙå%ƒëZ‡ÿ|MÆğbR!®GÈ[Ğ9XG›ÎÅºÓöø˜_FmåF’æædÍÅµ,oƒ)şë,eË”¿gw6•¦>e®Ìpßo¢8 …şe?=“
©Åÿö4è±ùb_,#xPãÄûh<®üı:ë>M~p§­´€ÓõíâîŒØ £Èæ	eÎRz¿­g~åe¿ç¡#o6LYÿkœJ@R6ÃhÒó¥†À/¤…()X‰š‘©=Y/ÂË‘¹Õv%:]qvµ ˜@™ö 3IØg€D=Ét^~P¿-Q\­)¤ŞÖJeSYæ#ì–d,HPÈ€gÒõjæ 1vÛ‚á}l'm„…‚Û#rÿ&èM¥Ràwpœo‘M®Ù_ä¨Ø¢‘T´!ºÉ Î§ÆyĞ•(e´#Ş¿z*b›!’u%J¿wfŞ“}Ä|pDağU¹†|¤µ„áù(v5±ÿj´"¼™Ùí$höôX×Ø¤i’k†‡lãùqwĞµ©L³[œ°ÈgÚÚø×’]Ìçg%ú‘É;©ğ7@Û¦ø„µ‹ê2\Óˆxò”~ˆyı•y—CÕ²çI\³‡‡¶®KY z¤õß?‰?°?»}Ş))I»f÷oŞğˆvènÄ["ïÿ³iæk:şG°ì…iqÓ¤ìS¨MŒ£\¬7|¬÷ìtOpùµqV‚¡¿bs0cNm)1ÇI ·¨®K\€“Ÿmğì&:K`”¦á|…¦—Îl<÷² ïZáÃÕ­X§ÿUüë$çç<Vìbëmä&Sñå¸$*KìOË÷È×ïZVÃmœ%uï—'=a?0¿/ Mnï«já¨ø¸1Æ23¯ØosÛñË~‘µ©YlÿfRÍVz¢à0kVëSË«ÓQ`$6c@>ÍÍÈıK”!{~(õãl#“!½î“dæ
”åØCYÇ8ïëb(ÁdÛ6¾§²¸dBc¡ÿ²f×ÆaÒ„ÿ(S@ø[Q[Ã
öiŸÜÏµäå×Ä}²ß€ş†lA>ÑÌ¿¦„$3U“/OË0}Î†^ˆ‹}Ms°ƒh<KĞ¿€G!H¡œ,¾=³mÅ¡ÅÈú1Åp Ğ¨0ûåõõc")JÏ·‘0Æ›qÁ<Cnæä‹ì—{pé ¥f†ÛÃ/}lØ &€óÔ¥9ÒÔ½,°µ2Vİ#àvBEèáysP†
¤5ás¥tÊòaY¯×ó,Wän	H)J#Í–ÔpŒR>U,­Ú©¨Iää-G—‹‡¤oQºv'­ô)fã0€†˜ø	‚ è)[Z©²pZ‘Öu^”YC§üÖaØ\Õ,]—Z)™n+¢”s0•ıØr„ j¥ÆÎı¨ü£A²Ğjbi±|…j_m¹V¼¤¨ÒhƒË±ø*™(Š£.¹ÌŒcjçŸ\Õ	çš.ÖÓ
Á>7ê‘Ì=Ûpz/•l†oÔ3½çùa{Hæ€Ö/fÁ¶FĞ”åWë²;\ÙÔ„Æ	6†±Â	R°ìWi÷.Q‘XM
!ÇR@¿WMgÚí…dH±şh‹h¶cs®DÒĞ5ã¡]ƒ¢¾² =İ²¦|Í?|Ùü»ƒgN‹!Šc©lÈi¥`ñ#§æDÅeJİ¦#"8~‹ÚlöAM0Ìì *ÌN|Wø¦U…‡Ÿöcb9©ÜƒGrê"IŞR’u>Œ–{%·D€Âv«PŠ<~©y}¥íFmáX`G˜Õ‡e™…E&ÆŸ
¾¡ôwÛ°œAS¿åvôdm2QQ\”Y¿\J9“ÕvÚÆ
Yº±]xÔÇ¦qÿAWßµÂg*˜’€MíÇFÍìDÊÍ˜‡6Ê ‡¬!Ÿä³Â{­é›9¯0¹ÇÌ13€4È {Q1Ïºp¤4Ğ[À -°6^2W‚9Y`‹")èW—°Ÿï¤y=Wo×TÌ¯èS¥Á‡ù•&‚[¿S¯jSÒRÀL›'L_)8Uêx|åª Œ¯J¡i¦±ŸúDwãÃÓU#S¶÷MR¾Uİ85/,âÄÆ-6ç÷v—Ç ‹È¯`eYGcgc3èOiı\ë2(ük‡Œ›«?º±b™™ã¥S÷X«UpEbE#4¿›Ûı©2’¥Ôjy"´ÚŸ,-Âú¨¯jø»gkı	ëpµ0ÒÚ¸ì“¹P
HK3Q:T—ô3e..È¼Pä(XƒûïWˆ3I|ë9€Çı°‡Û¿Õ ‰}Ò3¾Êjä$ô5‚­ªÆ 8“êÉöÚN8ƒè‚1¼Ì€ ­ER¶…©yÅß>µˆ lZ‰ÄÌqT\ågÿö01°‘m³à¡Y¾˜ndã|(‚˜øed0½\Ü(Ä1QÄ1şUœèQ	¢0jN«3†aÒ ©¯`iøùªsŞÒwg™è¥ædú„U¤9EûŸƒ_Ü¶¹L@Óì!ñ2¦¦’~HI‡ı¨?Œ×Øã£U˜*%7Äªßüè
J<°‡x+"²‘gJÕEäıKöAo¨é>§ÀüdEa4¬Ê‡¤åÂouë	ä¤¨7acØ¶@.òoas6êgYİß‡¹Ä±7‹©?ÈKP	İ&ğ>^›ÌégÌÈÔåYôáB[lEa'Qã¡¼õJ¤^šñ“j}"İid£™"TàÍ–4¯S.	( ÑŠM–KÑÎ—lEpÚgs·:İ(Ê¿ø^ÔQİä6Œ àåWˆº‚ºÈ\š+•EEê6¦¾>H]ğ²şy¸F5šğm=ß¦ä(Š)õƒ7.d³¥°WT«Œ±¥»ªS¾˜ïãØüLU6‘˜w@ ™“Å¢1K 1cÔ8®h^a‰ -àõÉ§ÄcĞ€—pÁ“øˆ/?nøb®^¬yşX×¦ç]iò—²–¼.!E¶¸Á¬K—-ñ,©*#ér=,1ìİ[cYwæ³æl–å™¿W3Tf‚nÛ0d–uGÍL6ßR­V¬5€cäS!ì™C„Ã’oñ–6<Wc¶LíXÎ18ÛmùMOh÷53ç•d4_Ô	¾éã­ïÍÅ|K´á¦2t,ÀÕ½UMT¾Õ’$CÇ5û¹Ö Ş<b˜1âs½—èç©F2õ72¡œT‘ ezç4ŸŠšßĞbhÆonbÙEğ¿ú=½›¬·ºa¡ã€‚ÌÎ§Rº†²Ô,…ß*«eı«EÜßÁÕ““>©ØFƒ-
§Õ‹OF~Ië(:NÜ¤!YE~Ó˜Nc`5÷ßqIß€†Åwª¦-÷}ğf‡-Gûˆ/Kş¦LíOa¾?1¥Hêvcç+.¿Ú¢³®òÿ–&d?ÏxL¥pjËL*¢lC@h3%–w%+Ä’{<æü¬„`Ïÿb#r¯-2İ8ÇÏˆQxà0ŸÎ…öBf˜Hbneh…»‡—¨ß9gÑØ…^ÿzäHİËuÂ/N ĞS>ô	t&Tp©Ëcö«›£="ÅP0QŒ¾0ÖF–œÄWèğ;MƒMÂÍş—p"¦7İ‘ç:œ)t¿™z¡[>#p7™ö±ÑY¡>å_¡,Ldg†CûÃõ:õ²¢ø˜Ûõó2Âc>U×å¡‘Ä4â+éQFôL2H}±QN§.µÚ†8¨lrßĞ‰éÏÃzuŒ$ºGc¿†h¶8Œ%ãvRúÛ´Ægc8ÅK%¶œLÅ²ì	â/ô®©®Çí£Ñ+ kbø–»ui"Ç’Ï‰b6&¢EfºZ(6æÜ™‡
«ÿTò$	PHYÛ¤IÄ¯kYëX ‘p„2‹‘,EğcòCŸF-Œ*ºY£©ÕÚËÛX¿<¹ÑŒ-Be…Û&\ÆöUdGíÿÊŞûX5°€ó]ä¾Í P-¾›Ø© „ÿì¤,Í|Õ¼ZA½™cRÍ„–ìñ¼KöÏ}êğ°¨Ó½W¦ÆÑJœƒï]üe2ÚìIF±è
Á3®¼½p¯Ût¨õjÎ¦9úúìNìóúE Æ±›=šíÍ+D D,H.ŞÏË\³5IRó2”­ßŒSÓ‡÷ûRë½ÚÁ{´.n¦‡'ó™c–Ûšå™9pq,²]÷z¶»}‰ÑA‹İ¶0’ŒuIh7h¶r‚7ğÆ™1H~ü5½êÖ6_:IöÕnWäñ >xqZQÕ@  ™›£EÜ'ª³Ç$lì†Â	t4F˜›ÙqÃ \›K¾6üxp².—Àf÷]°KaÄK'ä>ƒo1ú:¤–±jPR»p}ÚÁ~Êÿö²F_·´w%øA1RGãTµ?Ø7P;V¡Ùœ
\KINÇ²ğO÷,!ês¦ôgXaÏæ“´€êÄlUCBvFZ·8íÚ-o”MnBëšÂV§¦‘õiîûD0|Ë.?XÆVşVàÎ¥¤E£™Ñ$¨Sp&¯ù÷Y¥ìsR‡y€~?œ2(¿è=s&˜ñ,İŞhŠ§6ûg‡Î+MtPYÌ­\2¯XE÷ByjÌ&°ü3#{…“z¥åÍ¹To¯PÍ>F0*µ„_]ü;EM[{C‚ˆ%æ„ÆÙµ¼T°ğ~x? {.øª¸‡XO¸‹.“K£ü§†Œ'ïSõre\ÀÖş»{ª–Š-ÿüa7‹%0	*Tıˆb®É>!—OIšˆÆç=W>Zz–CMâÚ>ÒQ`·ƒ”(±nZnTáDï=§ÁpßøÌµø%£xÄÍ	Jt‡r\;J$X†!ƒãõZ²æ cs~°k‡ÒmkÀ[rĞ‚½Äù*„¢b{%°ABºËpˆSqeJmÎÇ:‰î%ç7õ§uâeyñn8|:K6F.HLœüme)ñ‡]Ğ„¼¸£ŸE0%>ÌJM!6j™~ì
\ˆœØ´Nh¼_úÙ¦Ú££.(pÇcí¯uG9¬‘ì«GÁàæºjçœÙÍ¦ØFHPMe,Ø7ù?ñPÁ½¯U5vYÄQ¹)‹äCºîÕ:ë¡GÓçÊñ©Ç°¸6™†:ğò¡SúFI«#8£Ï«pûr¿9gì7ß~Ià[‘ßqgF…µ¼¸ úf
Éöê¥BsFQMJ±ØEà¢§ÆØ^´µ‰‰xeE'évƒ²³˜r"¥E9Ï—©q1ç’NXïãgjºğıÁ¥™n­LiO•Æ¿!nœªTmÊ;]¿ãr4%¥;je‘ƒ&İİ®Yüz´7¾„Óã™
é2|›:O<ËÖÂb|{ Õ÷ÌYĞU¾I%ÄT–nĞEâ—×ŸO.¸D¼ığš Î¥\Í"ø#)g(Úº¢æ±¼0±ÏÌøÿ¿§ ¶	ç\És…YÛµ*â…ô|Ú›…Vİº¿ :òÏQíÜùúÄÚ:¨®pgüŒ­Ï+½hªøC0?©hüäá”GÏ
ùS¥•}"í±ÛÕ™è^b½×Ònñšèßã(<²µµIõşQ‘e3a¯O]ÿB=…ŞÌ*|ŠŠîeWàİãCéìÖï	®€·…8A­t,rÈ1WX÷[·§ÔœiB"ß{IÚm2¹YX¢şêÛ¸Ğ¦÷Û^ºğ" ŸŒC×ºïà³-Á€¨u¡õæ]Ìğ-{à$S¥gA	¡´ÅıXIÀ³ òTéM¬p€Ò/Ë0+¤…#A‚(ÕbFi¬øˆbC¨A°¡o/!@ğIë§[YÈKÖÃŞH£M²/¿À=ú‘XÓRÔ)şmpîZ>Cèƒ¤”ı8«¹ŠºYPanfmÙ$jŠá‡â>Å|"0XDFŸ¡İHšwùd¢”XF@ƒ­ö¦æ¸!T³‰øàëŒÀÚn…ÄŠ/:ÙŒºZ÷›^>r
XXdcåûèÇ¹Çş>áÆ±Ç½Òú¢4Ãº†…¤çf´‚Z¢)îé‡»­ûß®1³`Š(zÔb%ÎÆ,ÔşÏtnAxğÍiò1Ä}¤Gléˆ
$Nì·ä„#ÈtºãëÍ@Ã‚3÷QL¶ÍlòCşY;¤š"Mİ“Àz×Æ?.úVm`ùäŞô”mõ­áÖò3”¿ŒÚ›wxÿ9Ra;ş£ì×ÆãÀ²WdbpxÂ”’×‘¾•¸Ö…Öl÷b¢€9r_şW:ÑU”sÏvf „è|ì‚DÉSPÆX~ò–¨ŠÉm‡]ÇJCm£ŞxÂa#÷E`W„¬©ñ†ßŠ‹/çí—'2>P¸„ß“F3,<Øº9=/'ÛÚGó÷[ÅºĞà~øŠP@õ§Ù&6ı5QÃŠ¬©\+åÊUtaDD°*4Afà´,,ÎV‹s<dÂµÙÏ¡ºr)”Üéuo »@$d]–X’·Ş¦Àş;Ë7ÑcÏŸŸùœƒ¿Š­tÛ»ºddÈØÆƒd» olƒåN¬LWÜ&€‰Ú‡Ö?¸[àó<
o³ùf?7o<ó53]µ‹‡ÉkÏ6l£?°ªòå¨Ş\úAŒ4PRúø‚ákãœ“Zn{‹—2c¶µ)I.8ñ‰ş;Ô‚œ5<ÔOÒêT½µËÙÄo1¢™RÿA úÏµ.*î¯tY„=	%ÎÏ&R È˜Ğ,ÇŒY¥Œş/6vnF:÷±ıñãÈ¥L
8¨
K™í_œ‰Ó`(†ò™ƒ¾Ğ™;9Nßâ©-™7ĞRßı3|as¬¼ËÈçø©é9kyûâ"9ğ*9=ú‡
ƒ'ÿ\“F_óôßt=#ı<0ê}êxo†TáOâà¨Ç÷à†„•Ù%Àu|ù©^±Œn—¦Oy²ßÁN9ı˜†yÈ…åfa,Å ¼3‚áæ4lAÏ!»ó’ û ëv5ÄÉ;^º”‹íİ™Œ»hó=¨A(Äå-{jiöÜ«Ãr…Çæ÷àVv‚£ìš¾Xµ½:Šü­‘Û¨ÏV—³xŒÎúÔ V^Ä/˜wE÷©ìÒD@zÇÂ-Ä²'"@/JSdc
u,ËÛjº,°#ø@)H!“V
CÌ¤Ö‘Æzxú¾g0º¬şÛIM¶êëTÏ`n7fWƒIÍ¡ƒsŸ toJĞ²Êjç×O`E<]÷ÌârØ‡›mmÖu¨â9çµğêƒeO“å_ßâ½1Zæ¶é.õW«|~]ˆ>5×	%{Ù›>ZO˜Ò~sÙ;NŠGÁ+™ãßHK ıFqƒ?bh.TtBØ©uª-6jÅ6ÜÇÂ6àUJÎÇÌñğ­ûR
ÆMà/£ë“Aâ}» >3¾×C)d=â‡²×7Êğ…ıbk‰‘WLÆÉÂ¦¡1oÙ’Ñ‡]÷ô¨°$0• ±5àÇSGÔ¾·C-÷c¥_÷Õõ(±@1Ñ‡¥ eì”/ô3á;
Vÿ‹%âBß­‚·•¤®wå½¸í‹_·z‚ˆ=ƒ°E'çMÔôù¦z»¾‘i³L&1€;{§«.»¿¿Qk§­5,#yQ©õÇã´eVŸàí½ĞÇ(Ú[UjWu1÷sergGJ8?È 7Ò¸ßì äÖ¿I(83j¼Z/{ëÏ²5£¨? '´æzë†ùp³èÕç,.wYEÕ°ZÚp)êéûrÁ‚ô!áÖRÂRìuúrrÈæÈT7­HVîrv³cO¦Z[/j9tZ(Ö\Æv¤ëˆû_Â”Âuy74¬_CÄ
Æº{K7SÒÿÍ¸!Lµ
LîxÛpÁq©q`v.^M„^´Ëéd¤†‘¶T½íÏÖëãÑD À/ÁıG-“Sj1Œ-SEÔ'E4|üÛJş4‚c7Ñ'&ÌßãN–â·²Lº~³–Ë9ÁE^ô·v’rOÓ°ŞNº‰yÜ]}² ‚·6D8ûãÙ{ï ebf=ûÆî¹U¼É¦é%çUP… Ú.¶®­x°ªIFEE -±]_O_À    ¨Øqê  å€ ¤¢õ±Ägû    YZ