#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1809683372"
MD5="1259ba295273d3e7a70a9e676a1d8f88"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23580"
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
	echo Uncompressed size: 164 KB
	echo Compression: xz
	echo Date of packaging: Fri Aug 20 11:49:22 -03 2021
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
	echo OLDUSIZE=164
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
	MS_Printf "About to extract 164 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 164; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (164 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ[Ú] ¼}•À1Dd]‡Á›PætİDöoÙ~tğp•¤¤ù[ˆY»Ÿ‡€7*	ø ‰G$¤*½uŸSxÇLJJ3Û†æ5¥f•È†iS­–Œ«<šüeÂˆ±ci¼2ÒQµ7mP÷fæó_@Ù»–Üê­£õÔÈ´lA(ŞÏ§x¦·…o#î²Ì³ÓÄ1`¢•n\eÛ']hÿ‘İE2Øå$Åˆ\Ÿ¶	ñƒÅåÏ¥)K0±­3×Ó×·¿„ƒ€÷ŞæÄY‡Q]Á¨rË@é$ëêiuk]Î Ïğè`S/É–Gå}gÛĞzo#Ü«EÖI3Ö÷ÚmïˆÆ±L<P\Vcõ\Á½;Pe¿ì	ş¬ÓnövM/<ÅÉ7Ö‹çØ²…,¥<Ä‚=ˆJîBp…!È¡Æíqf	NB‡÷KS¶ÇW_>›-š"hÿ€wPYaÎhş<–³¥—[ßîÌ6xú|M±š™•£ã€¡’˜nˆwAßRè
m˜ò}ŒúÄ«e¾<à4{8«ñ>îU""Å‹€tg3ÀÉ|¿çJ]É0ö7¬[—¨G‘OeĞÇè­PÔYy^!şö©GF—‘:<¡íß²"©ë1ï¿çÙúwyüÅq¼>n…ïJx2©UVGê_àa>7o73ŠŒğè;§ËJ´+øı>ÉSSx÷^¼’İnmzPC_¶¹uQµ}¿$í6|¿ÃÍ)ŒÙrÜßuà¬¯œ·~un¾0L|4nvÔş‘¿&¸×æµˆ›x~È«EµÛğ“CŞ¿L; ó¾ÇB‚m†Ú8yJÈ¸öz}¶İF(	¹Yx4è
òO‘9~@ëf8ÈÆVİ7Š[åÄÒóéÇÿ‹#?|r¯îw¿I{³UT3ƒk'|Éx{²Î½9@vÿ6acš¸qSd’Á½ôj½÷±`^¦ ²÷\_ÃöÆÓK¿HùTÁu{qÈ¿æ|e¶”ıEÿÙfgâ6ÒVŸc¥¾¥8×g£ r*µ²cTmMî3‹Zaì“nPˆ4>O	q¥x¿¼¡bŸçHà¢
Á¯®›¿1ÄùÌ¿1°…©ÇP×âW€O}¢_XÚ¬lŠG?U(•^ÚZ¡D*SvJ ¤|mJ¸°ïñMn¤>÷9Úwáq¢S„hËoÄ@S ˜Ü…ìù•<Áó–y—ßCaŞz>­ùJì¨âÛÉÂ'R4Œ††ÊFˆÖBRÖU­5j¤
»ï÷€Œß:¾­a¬X&ìçMÌÆí1Ğâ÷ó?é.-aÃªz®àaá47 ij+è‘¸Ó‹°S8œÅlá’5p	Ø½şÃvŞRûbD¹Ú¯! œs-?‚³;îÍ1È¿M–´Qm7óxS7\+	ñá¶×ó+K5¶êŸRnJ¯0Z›fJğrÑø‡†Âé4wo6¤ÁŠ;0$#›p[s7…§— „=ÖêgÓwñú‰f™öbï‹@ğÏ[a ÎåV
zÂÉRC³ûhûtB¥McD·o•ln¡uÊÃÚ/B¢ÍûKZP?Ôš»Åôøƒçù‹ $4A¿
¸ö³Rsá Ïv ÑÒ68åãªQ~›œ3q(ÜÎõUo£»m‡ÛÉìëKHl±W¥úµECrÅ*NÅEKcÅq¦zÏ0Ğ–—Â|ÇZ=!ˆAé‘‚ÿÙµ8·âmÂ"Åöêçe¦Ú‚)Š‚>÷×ŸƒÌ¨<ÍŒ)ö\Ê#?Â¾­'·«.#,ˆyÄ;7üÛçJj+wšÅ«F"Ã©;}›lÛŞ9ˆ+†>6
*›Ï™ï~>Ôğ¥E³³º8äêÄÔeÉ×ËwÏ¥ ğ2q„Îª/= ÄH‰’6‡Ìi×Ci3TôÙUR}šĞíÉ_éµ°}ğÓf\‘[Ï\L<Ÿ¡ñ¾!M•~ÔÁAj•êÃ;‚œ¾ªeıÇù>@^°XSJ©‹JŸ/ÉÄL¿n:J<M5Ã5[‘Ôò@Xhàæ;ÁÖòŒs¢Ğ©jsjèÄá)J±…6.„dv¡Ø™Ée¼øÙ¹çÈáğ*æÚ¶h×tÓ4ÄÂ¢}sáŸlÇãÅ5“¾Å°³i'¶iâŞnã¨“@mĞ§:4/³•02è.—Äì*g…?xŸ™¥1‘ë7µ•èòÍk÷"ü7@ãØ|­F	cG
3]%gşN€ˆW<Aè9»¸×Ê•¸ïÄ…‡uŠuÁ–/:óÕÆà	rq%f¼6´d>}YŠRm¶R`¬½Èİ\ÓiôÄ=9R_[›³@Ü–qetz×tªn+n3ì/†^Ğ_ğğ®‘`.	äèÍùD¦óÆœšê=>¬²€p
:¼ƒ† İ¹oØ
A/Rµv aå~#dßa‘÷§8ãóqÖ`@Ÿ×F²#íÑ©DU´ës[~ó#üß,D_"o&èÇœÁÉç¶D"ÃÈ.&êœÔR*†u|V®ÆuÕp4òx¶Õ“¥( xZ[dêïU›åSZRÉ¯T?Ya¥Vö±qÁ_+Ÿ–$yVÚˆ	[‚ƒ¾µÖ¯µÑüO>‡ªÉŠkpêlÉ(,.43¦,4ÇÖU4Iì)à|`×!Æìî?¢×Pæ7Íß9ˆdÄt¡¿³ÂQ¡§;ËËÃ‘1¬	;ê7Å ††é-OæwpŞ!°Ì×p!H0>çXÙ²
*VeFôŸD0LÀ”w‘X!@+,[îÿ`dxN¡ue*Èô¤ÎñJ›ö÷¢YØã¼Y‰Úh­¿Y÷z	FSŒÖöj÷*Ñ Ùş›FîïÈÉçÓÃ{–…Ÿ|œÆh~¯B—s`ò+V#/å	ÍÛäãätˆ–ğ°~loèÌÂ†ÈZºqdz?
]¯£•ù£Rª*ìX6œ×à
]“©3¸ŠĞ&‘OœJYüšÅ®¤ÙmŞ[<!¬KşŸ„÷–`Nì°_\ÖInU3ÈA —0Ç_}šËîq³€ñ„ŞÄµÉR/
<È»Ù'´Æ]ë*=éã-H¦5yªlÃaÊ$Ş(œTšÎ>q
/)Íªa6cÚ:8öH`‘‘Mş›ö5ÂÀ—{ÂÉ3öb†B\&«ñ«,œQ—½ó*´WV´>ïd¡ZKšı9CI$3„mÆ
!$
ñb!Æ&{ö
Ÿc¨?µ»­ıR=t§Èû>8y@æ2õ‚¼@Å…¬¶¼Mµ!ë:W¿Ï  «Cßó´DœÚµí,V4X„¬·Y@~¿ M+£(ğM‰+öƒl¼±]yl>ı$˜ÚÙKƒe²şOº5x$J¨ÌT_™Ø¡şÛ
Í†~€~Ñ1Ê‹/¸·4Í3Ë–ìWcT=öû…•é4 æ¡Š‰õH×é¸ÒB'ìè$?È4)Oêz8Cı­çÅ¥lÇgÄa½ÄÜ ©ø—èU6]­ƒ?ùß(GDüã¹Dt 3Bnã6–Xæ-yÍb“ìUÃH)M„5ÆWÕ¯W&¹Ï‚oàÇ¾#û7RÖÚ“ßv–.¨Ÿı
í„<î–Z€Tl¯° \hºÇ`X>A>H”>×ƒËÛ2ñ>Ó¯'¡o£ˆ5’Øe!C$¨8µ>,‡ôz¤¬±–fı|[‘Óg%3"7öNÒ¿ÖJ—£A‚©ó*MiV‹ØZ–£˜™¡ÊˆYÿ`×"w")/cuÓÙt€¹6àƒÓŞmpõ¼Ù@`4àÎeïÜW@àß@g’£PyÔ;2÷¬ÜèHÆo,¿“!â˜í0aÛ½‡ÑªCQŞ9z¡¢NÉÍĞö°Õû]±÷<¼j©\™rzÖRN0îì6ñ… ²ã«ƒ®‘…m1ÄÇQ/İ4Ñ;‹z«¢÷á ïª5ŸçÆvUR¤¯úşÿŠı¨‰²’á•›Gvfå™+n„*Ö9ıBÊÅgûY“°C/•z[À™µk'¹>¦mæ“
[IúKjãÁ¾tìÛ¾¹¸"‹ä”ÔY†êóŞîšÃœ›—n¨%>G´ªşyÜıQÿÕ3p2#el4-ÈÔ]ÛZÃŸ şÒX<İ‚ÏùWŒÀ Ñºé=~]Ta«‘ªåx\ËO ÌÉ/¶-…£¦EËXb„G2ÂÄi~œú=2
Øé8…¼Úâuoöx|™9ƒ™½MÕ›@­!i&çÏe¹„“&E­&X%Äã¤ì'Øïä»r|î€%mÌ	õŒ¸âÇ[Çï„ÅBÃ	Êù³êS±íïùr„‘¦Ÿ¾Ğ×“6úïñI~*e1Ïí,nmgŠpşAºOg2æYS‹¸¤\MOÊZsÓÅvûpşuÎW)¼ 'TP“K«o&k'¸Á<hWTî²>@ Î¢m#Z|?°ZlVU}‡¶6^>l#:qŸ…ÃQEKñA´ÑY˜@¹Éoxî¸œFƒTf‘±3MÌø¶?}‘r€[ÆÚZ¥Ä½“±TicHK¥^Õ?5‘U#ôGÛv±•¼ú<´y`¬K}l¸<œüÚ.³›rßBh~Ÿù‰+MJèà5à/ğŠÂN9—¾ã°¼wŸuÈÀÔOË”ïŸ¥”ZŸ?à´‰®¿taR_`_®yOÜòñ,R39Çş|¥–#!ó¦‚ã¬[ZÅÍHÏßÒ*l¬C_çH€¬“1Uçà0Övb½%€í¯U÷¡ßâ*7 <âC¸¿&-ôÆfÌ~İ)ş!èkÊÁ	7·ö{^ÿ‰zşF†æk®®ØTN	¶H¸é:©dœ:òºYÜùb»ŞÄq’1•uérÙ‰ßÀÊ¯yˆì :AAÖÈJÄ™İñØçÌ°àõçäÚC€²¸|Î9"Qã Np7	G BÕõoËôr²ÇşÅıië#kûæÀØzÁ~ÉRi[¥³ O0²¶š…ô\G|Û†2¾Øv.ØçCñ«a\EœŠø—|ƒº •jÃ˜úó-àr4Í‡ÂÚè©â6ß%4Wïg@˜¸ãÉuT$ü‚&Šñ.æĞ£®B‰?ˆ™>oÉí°Ö¯ÿÉ7§<6u¾ˆò~Å'UÃ‰%êXÖ3BÊç$œcOŠ—ùh']LÀZóÛÙ’b…ö`4hº‚,QOpâkd™\Ôb‚(á³;÷%	
ËÚ‰İÌÊ-ÎÆKjPáaA
¶úAxvîï¥M(®×,é.ë"tW}‰bMz™F-úW4†üãmCÚ‹Ç@ûyªÄá{É39…¯;‹Nî/iİ¿êà¢ÊOÑ´~ÊÄİ® İŒ¯úŒa°CÃúP„gŒhÙl%‘Ô+ë¿Õa±FĞO$–›%ô>A–¼tÊƒĞº¹‚%ZèBNày¦´*éõ» .©g»ÏHOh{Ò–>ÕP:I4’úSÍLTò2é)<xG¢kX~ 2‘¥stF3Ş8Eó9™Tøîû®òÃ*È©éYYQ'¾Z`aÚS	iu
Æ ğë¸^ôç´ÃU‰"Õ§+¸æBY#å‚hf¤Ç—uÏŸâ~XSâŸÆ¿……3{p°ÖÚ-+æÎÓ®Ïl¹;õ”R×¡üd:9•U®oKıK]İ} óiÏÕX7Ö;ìCÉ«RÀ‹Ô5‚)ütõm×ÁCqûSxÆ£‘œ˜¼Ç¹H¬Ùrá
•z”ÁŠ¿[Ú~à P¤GÌ#Ny”	‡2»Ñ¦ıŸhWkÉX5CÑW¶¼Ì²Šë§f÷%u£ŠÅL
„ht
Ñù¡üz’!e¥)ğî¬~ ×Q´>@Q;Yš—°/:’2Áâ¬?§ói§‰˜óçƒw«·KØeX#€([eù\£¦şH³&zÁø½XxPÔ
Cïíßä'Èœ¬G|5L`=e=:†Ş²øq•Éãlë–ø
p-o¡õaCJ{cÈƒşR<ev8¥7##=¶Ğnµ°fEÆ¤à¥)woï«ûcL57èp¾Õ»¤f3†Øh›Ù7<D6…ŞDm|àœKe‡˜2Éå¦RWM~m²ÖYIë‘vC™d—‹ƒá°ÅÌÁÖ˜ÏëœØŸE HdìLŠÿpázl˜V¦<aéBn»¾h’zµa±xŠ“Ì¤Ñ’êœ"ÒÏ­ê´2”_µâñW‰Z³{ïûW^& ?9!ù¤ìõY€DëğeªíÄìfš ŠH2AØÊ¸^ »r6¨!m>ÌŠİ¶fŸD#ğÖÎƒÒ“ú.S¨öíRÙ†Wm¿hŸ¥ÂWa&÷­Ó“#À¦óûAíÏ8a«À“ÆoiŠû)ÿWÔÎÖ/Õ³5§'óÔ€
IºÒ	T^bN¦qğö·öS(2h	¢
¥‡ûSíKnŸ+ÇL9! Y¢à‡A	±Hc„òã¹ {…kºdİW=Ø”ìÊüVaµâuà=™¨ÍÔ†IqêbtOA‹¹ş|‹{28gÃàw?±'zWÙÑTá[JŸü~¯gúC»–÷z‹9%	j`3ê!Úáq5ñ»!ÒâCá¡q\JK«6ÿ¬À¾Rú¡÷ŸìNÒølàl²v¼\k„_…›NÚT˜)¶ßÔ›ÁÖ`y­ÉõuXÓˆecj )ÂGÆ†jî†4­‹ë£Îñúr9úcr¹Ìn·$À&Qï8‹Öj€ÅL¬©~İ#¤pa#„"Eó Ü‚*u°WáV&~Ë´ûFë¡åÑéW«–nüqŸ'
şD!çµˆ§pBtàm®>)‰[HÜ¼aP¨€„w%&0ÉşÚ¿”°qwÈpIH¡ÖFnFd‡sX¨À¯îxx÷™i2S`•ÆŞÄ(ªRLã|È ¶(ï»Å†»‡İ;fÊ½²7Ğ™ÁŸÖ3±Êi.Ğ‚6áÄÿ§v™K3o±s–±5“Ôo™vkáˆ[ë Æ;³f¼-ìªD}[ Ê;ÀhËFéIìbŠí(œA‡Íö}šÛ4#kŒÁ”;//DXÛ	®Ğœ\;Ş©wËõÌí£,¿	ì<I¥
º¢¦˜W%»9>…AAÍ ÊˆrÊ$åû] âc‹ñğä‰øîÙ3ˆ‡O)¯|‘a†Â ÌÖõúİò	u#¾¼…ÈA™ÉısÈºPøg*æ’JÉ3dıêÚA	“´y¤Şø×Ê‚ñ›ç?,?¢î²„î”HĞ_g—™…Ùæİ°Æ¿…c¡ŸEv_Èj÷dº+>Ğsí<“¹!p¾ë´l ‘½«{É’ÔAOmcnñä¸/€¤VóöX&‡B¾›AïqZ`¼’Õ‚ê½maŠÅßBÛãâà'è­“$EÀ–Ç$¹_üÜÀHBË)ewŠxævSòÄ’Õ½VhR¿:R—s†¾üæÁáÆ¬km«o¦@®D®´väpMPÎ¹Ü-ò“#3~ÍïW’‚D··Ó§w®,åï{ºøS!&‹Ø/Êá«Ÿ×²FÃĞ²K[´8¹µË½{|A™ïÏ7ëìÆ®;k™¿†,Vš¹ŒySÛfV£˜§<®½Ökïr·TPˆM×óÏ¦æº2ADÈ¬h´zv„˜YOíC‡õ`ô²½¹Û…FËÃèÂÜ¡ô³¤…>}‚•sÆM`IS•l ŸÌ‹÷:Œ["ñ”–pSAƒÖ<^.Œ±IöŞˆÎ"ƒB9“ŒºyjØ`©½ğÎ“_xØ]×Qi* –Q×÷(Î_+Õ®Åé2J¸f.Î4U!ñJÍPq¢#¡¯áÎ—ı´VedVİ	ĞÅ¢DÂ"º ş›Ø}{ËuÇWìÒÑ£Œym‰Ué)UäÏ§AbÕù^7Ç:#[í=`Ã€îìÂ
Ó‹îXÄüwÎ$Ç*}¯xqo7eG²ø#;Zhñz¥óè°;rÎÚ¼ŸYÍ«JIÔ—³«À¶ ñ!z´½”Èe3¯F’ÿ†gõÙŞ—3-³ö{ÒoFÕX,Û÷šü[@&™˜ÛÜ?ÿõú¢™¤û
á—YÎÑGJßè{fdÑ»§S*„0O|‹®o8îÌMÊƒ;òÍœNŸ	¬¥Në[ğ”£üş× í,ĞƒAc8’¶²gsd·ØrFªÅLnåÂ¦²á’_k¡ÕHÎÖ ¿îÁ‹ Ş S½t6õ‡¥$õÔiÎâw¾à\Ï¤7d¤.A*¥H¹<WµàAsv
è5Vü¤?A;¾Mih±³šîË&Oõtf²st*[×¾ùCÇöŠŞÉJƒ¤_Àóô¢ïæímB[d™ŠªˆÃ× §™(†r¾Nİ`àÅ©šyB‡O‚Ä ˆãòüŸL;ò³%ê,¬ä·±4gVÎ°•š‹m:åsæ=OE^?(]¶œ‰Ğ¢‚®é—ÃtNkŸ5EĞé„xU9˜5QInÊavcg`êæm¿7(<9U‹Vëÿ#˜^áE+¦ê¯}#~ÓN1ëÍmE•1„ÂDùœÄìcÌ{uàw˜iÉ!§ÓÎ ƒG©áéÈË£õ{3°FB{•3»2”“qäC"3ãP>Ænğ‰Iå5µ›n¼P¼™lwØ™úmfaÖN•-AJd(Û I‹^ŸXŸ;;§¸¶ÄÏëM+fÇÙúÛp2„M›µÑÍªR{í§$xƒî1iªËmèêÁ|ùáıfËË@r Áv:!(æyÓŒÈE!bsH·ŸNÿ/ªËµz¢G[åÍç]Õ—?6õ2B>	†&E
wªÌùcÈÁ_ÈNÏÖ>GI)ÍXÕh,·7ù¯0ÉQ:Â¤ÙTóşÉˆ3¡,d3r‹)³ÊI ­‰!Y½\PñßÖ?#.*pÆÈ®QÚaÓî¥h±£/+¥rĞ*ºZãy~º1›~Ç•»²<†”Ís#¹¯;/Àœ‡ÛÃú“PÖ£@m@”CJé]­UÁ“%Üçx„ÁÅI¤C˜yn¦j’G±$mÁkVóÛDOVşËïÆ¦\¶£øí¬ÇÎ¯xÕX§‹wÉ*éò£l~Q#@kv$oN\÷Úü	LN …¯†”Ñé¾Á×q¢–U±g3ç	Q_*•0ôPÇg—5ÅÇmM|Tt4øÜüágÏæÖkÎ$u…»‘¿t~æ (åÌ¡~€õâÍ€F“³A©£—`ö×j6ïbµÖ!¨¨Â`UáÕ%Ën•õ%î!Oaµ>XÃ–4©®î§c¦¡Zt£øº:7:7/èŒ»P…÷yR#„Ÿ¿+ ®M{,÷Æ¸A !‰ÆkD2ç_Kó¢ƒèV9–×“»ş†ª¸>"Úº)
´`X€™J~b?4
Bmü‚vbÿ—Qq³©:©öqáy$+¢ìÍûH0/yâªJ.:¡Xæ†xúÒàbå÷i›Nu`ÃiÃÑ½Âõ	ò3å¨«VĞÚg‹÷3‡¶£Ñ©â§ 6Ë&aÍ-h•EÒe¬@uÜ:‚ÊIb0İ÷él¬yRÅ‘ÏkËéÛĞ†áoªCµ0"şTÑDz†ËøAmú_ofçî¯–ª‘Xt¦[{¶Q@“°QlO`ooèÒ*º5t¬"PQ.t¸í/>Œ‚^:ê	ü<>Òvœ¡ƒZB«%QnÙW+ÏjÄçƒf= X•ÜÈ%'Ô¥„ 	ã÷ÊÚ¸è©'V+ÿµê9GTí!zèÜ„ŸG¶ñå½ÄC–4Û—•èÙÅ6SX9¾õt|v2¶>V¿×;­0Î_”%õ·ÿû@âèàãÿ¡«Ñ}×Q.†(£Âl«“Â»<•—2’!‹-û-ZÊ=_+I<×åşİ8ZH^Ó÷'_¬¤MLjì£n‹‰\‘Ø€¾6óÿ?*FAâN3ü¥çw$‹KtbïB]^!±Q8Ø2uPßñä¤~·Ğ6«"wBdËâ8á¾B*­ Èçï«’jšúùF‚òw…h*¬Õ„AŒÄ 9p!¤ !×[cÄÅ6dÿm³Ü¢aßã~ 2HŠ3KJ±Äµbşsx3¶1½®NQŞeÄ=løW €¡£FÉéâ\‡V3—³ßZSO6Á‡T3ej„äÒÓ
z<5£¸?O0îÑ…]â„İ=`AâŸx°ë?Rk–ßö †v+"óİï´¶=òšÁ½˜élÎ©hS+òœñØ×Üd ßØä|]¯lºxŞ¾vÛp[šdìq/ziæ=ÉôòË¤WêÙÿûJ·}›ÚœÂKX«hËYåí
Â¶¬ë“Š‹°Ì8Ö¿^}›}+¶\:s¤¸–Õ7âÈyÈÈ«?¼Éì6£‹T¡ÓKúŠ¢¥Ê’£ˆ &5†·L¼(²šöÊºà¡´â§©«©VU½º“õ¸­Sí!*ï›K?QùäĞšâ1 P$]h7§õ%<ÈóEúúwù©DQ¤]Ñ›de;M	à‡µ¯$·AEJº±PÆ‚H[uÆÜK	GÉ&BTU÷Ä…B½a¯¹Ş€‘¿±7­ËÙ=—´¶0%ÔWˆRÜ4ßsúadıU Î~¦wh6ß ™&¸2x¡®¾vSºI²wVƒ¶]/<„·¡70¦’â“ cÆ˜ ç ËjßÃ¤LY‰jš¨›­æMšŞ«h·¼ßÁG¨’Õ´c8t$Z‡û¦Cû„ßj„¿Š­eÒo gJ4@HÄká­Ë|?˜ì»ùPn×ùÓ¹Új°ó?K‹.ÛÔ€l	.C;àx­¹å–²Úœ<÷@ÏÎMÜ¯¥¢O’ó©3ÀOCGb©†é€’ìRÓ ÍHq÷ì<}¼(ìi¦h>`*‰xZgòB®–i›FûJ7†tğØñ,UL'‘¾Ë 01àQúm† ±kAùµ@šY¶73¦ò ‘ÅcäOHHœ'Õ;•]\şÙá;G&”‡q1øG5°‘ìĞ/£Ã1Ï'lŠ¶šÂ¦o^÷?Á?ªQ(4öE\›çu ãÂêQ¼hY ô (L, é%¥˜W\vkº~û#lİ`ÈãÀ½%L=ó~»¦OeN†ù˜R«*äâÏ=ô\‘‰=!ır:§hIËÊĞ5ŞtÊlÇ¿ÇZÄî„ñ¤I«425$T?åä›Šq {:°ŸßÛÖ}%ÄºMŸÊ:€¬{ù¼€¶j¢)¾¦š/
ß‡Şqÿ¦Ë+öï¯¨ÇcÂd9/FŸg¾±mº¡Ş&ŸD;g(<èá„hÀµXdÊ.…]e¬Tœ)êWĞÏkvTNßG}#bÙ>üO4ëYuŒ½jmKNœr7ìƒm9‚y-8ä°sPpõß-7sÅ?>º¾?) ÎU‰Š—·­†kZ¿œIñ0ŠLB¾šf”óÀ@õèUh±Nj”“-¼zIË¸)uozõ*ÓBîqë{Û¨"ê‘ÄúŞ^éQ.iL¶%htgiäe-üyÀÒ¿Á×"·´ŸoUÎäé§INO/m{ÌŸ:Ïê`NQ§F_05kÇrê\S óşéEÕÀå”æ§h`*”Ô’qo½*Ù)É¥³€ "EÈâíüíË!«ÄÌíÂÇ/_t¤#7,ã6,Û?ãû=ôíÉl±?uä‰âëŸËß¡.0zc#·0Â3—M³Œ˜~ö¨M£n6íC&DU¾ÙdñäÀÅíİ-Õ‡‘$eé®Ñlû÷a÷¾Ø$w˜ÅQíZÏŒ3sILÉ*âî„˜,<¿8\Zor*hÑ¦,(jM`íĞïÍMYØ!¤ø°íˆvĞñª
İšé×.«WXQp3”LòÛ¤¡O¯ğá,×„awìÓ´pñÔÄ2­¿Æ4úêFA
4í­ø&½ÓÃ†¦†ŠTÔìÌßšZÚ°&Wa¢†&ªÔŞ¾
oºº.X¼—X¾ˆ…o8 &mò¤ˆî¦=;î7HOÂÍŒuòæöÕfñ°>gp o<÷Z 3‰¯d§¢).)œœäïñÂl°ÛÇ÷F¹!´ÙáYñêòîXä¹„1İ=W…m¿‰úÀ®ş÷Èùÿµ$Ì*­+Hˆ»VnÀ9x›;!©Pè•¬çY2kßÿOÂi$¢Ö/µµ<ßTÕöSüÏ‹9uÇ;éŒáŞ3í;(ZQŒ|$Z ˜ 5ÖÀDJ§Æ—“‹‹ê$vù½§9lNÃ[Şk­º>y½_ô¨ãïoEKÒ-“òSSØÓóPÍ·Ù²x)øšÙzL³T0ˆØÎb‚‘á$é÷Õç8†©Òè¶İîˆşÎãq˜Ò+JAG<Ã­ï@¶bâ}İ<Ñ˜T¹”Ùe6ĞÌJv£’DjåäCjXc3´·bÌpÙïÂÙ<°Ijfµ©¸«ÏŸÙ
‘Ïè?7U!ŠáËnÁĞ­šêpşÚvÓ&&µ‰ûÈ}6'}Çîƒz®jü–uªnVœf†{ïA_êFòC60FF‹Zsu¨_¼”¼”ò:vxİ&wy©<ìd¥ÿNs1E-£îZÆ&p÷h%QÉ/9ÇÜ¯^;ôw€ã¹:œáºİD~Y(Pâ#‡54Wÿ"wêuAû€ëã<´Ã¤K{%8“—´h†™J‡.„äB±®ù;i:SL^ÿ3î,ó>©Ü`9ºp–Z8°›eÕÔ³Q¡o¯hY˜Lå{xÊ1(3§H˜ƒ?æ?$Ç–ïÙ.¥Ì¢ìÉzæ “ªèEI§Çß¼”î9f®ávr›×[.]Y}øo	jö£qU€¿âÏy.®ş¢‹ÈâI+rçQJŞ™èòd$^±EÊàïN‘·7<Üì®=* 1LøÚŠsce/íL…ˆÉWÈW>µûÆÂx…*Ş±&í‡µU8;yK^5ÿE®˜;Ë¿v€§´ø¸mé#ä…N3…öXjÀÓ§„½Â°Ê˜Ç5Ñ®+qquDX³ĞÇSò³ñíNh4X¦âò…>8b j^ù†ãR¡H¦œ^0ïjŒƒò—@¯'v»–‡Õ>¹FfÑİ}#Pø·Z¢Œ†bO<+§H~œ5Ø
Z0`)‚è–Ÿ¯;/Ğo£}¬ÎLîÌ9úÛè> ÇÓ±¨ÉùÂ¶&
W ÃoœãBÿîƒbãÕ¢û5èÈ]ÇÎ°RãEèoè÷»Xı¼=ìy‡0®©vş¡ÔÈ¬§˜)Šûm«u®Wò¶7wÿ¤t"nÉ×fÛ~ÆÀƒâ%$Ú/Ï_µ§X3Vg|f¿¦(½
Sãa» [İÿ9¥hBÃ3­güG`5´Ó¥ùLÒíÕ§|	5ª‰Óx.êËÖ+	°7(ŒdÀ0‡SûMÎC4åíı$¹¸3AiT˜„%tür­øW‹)ÔÌ>yUíOD¯ƒß°Êà
ËP*™9àYBN1MËN³WXVÏ¿škS
ç(´oÀõu¼dúG\‰
ì	ÕÛOK_ß+®dŠ{O›fİŸÿ;xi²?a-`ä'¿øjœÙù¹ó§dÌİÖLG×_ë;êAªá™îµ×½#uF”_SvAå½Â,	á©TBW|B¶Ãğ372oh¾²F%Ğ0ğ=\Q%{±:2aÖùK}©„	×v`gû.ËvÍñ…ã²ÕàG«ò>¿ÔŸ±ó!”İŞ>WzGÃ¬Ïˆ5{ÿ-ø<J  §>kFÓ-ÀXuß:pòK¡CNHÆDåÑ8Ò(Ÿù·ÔY©ÜÈ;ÖuB2Q=œ<¥©¾çUÅ²“Ğ–\dÅ„Š>e¯õÉ§iØÀh7åjãƒ’%0uËù‰¢©&­
1N š·Æ@Úaevï—›KN´›™¹Ï8ó¤`sX¾ºŞ|é»QRÑŠÓç¬%©8h¹úQÇ!›•Â› ß9LéÚÈ,“¹°"€‡WZ¥Ò2ì¨² ¤ì£_Rò1Ù[
…ş·0r\\’h³ÖO&FqĞ˜L¢¡4iOöúqå!_V.^c8&·ˆz¤‡yßÛŸ7SmìNì.oDûÆæ0ée{¸1öj*n
ÁKêàÙ,ñX‡Y$"'E}í5ú`ï¸¨*Òrê¹—›za7@ÿÀ^²~/LONIo/×UošşHÓE­~.éöBc‘LiÔévõ4p^¼P3ç¯	a˜ETÔ¯™® ö^ÑJBÛ†ÀX¥8¢QhÀÒ›nmo"m;«IJ¹¶í%:5dŒb˜dÃQ® %²À%P¶){ÈÙ¼'æ«v–aufÜ4EÈæxv³c˜0Ö2‘ì00‹6‡ 3QŠ41Ü˜	”0³µ8Ó(¤×0˜3@[æ|ÑGŠ^&™‰•Áw|LÂ¿¡¦ÓTçLÌ&Q¼ÿÇÉN|Wf×àQ£ éMçú'"gIe!£]Bˆ¾(?—‡.\Õ5~@Ÿ-k"G·çôvÏI‚gó%LS¨Ù)J¾ê+‹Ñí«ÒÁû¢ç–íÒàğ´Šú÷;u[Maïÿ’^2¿ƒ
ºàœÊ $ÜĞÀR•0°€è\wÍ™®˜ã³1)RĞÈ—Í®;¸x¿è’÷…ÆÖêe¶&§ìãwó«€ÓÃ§w€”›îæ'_`ß@+€Cfø¾˜b!×\šù—@íSÈ äø,Fó7Ñgš–ŠWÖtsÖx•Æ{>0µ]r?	LEA±¸í ŒM›/0Î&\®<Q05LºAË›ÆfEv÷Ô©ÕC†cµ!î »Ó¾Š/­2xk«+SN¼ ™gb~ÈÔ£Ö‚×U¢§öZ¬ôë¤%Bûßcï†ó{´ì$ƒ`HÿTëíbn¹J3	\7?"ì¹Ã—¢UèIù³A FlİˆF’ŞgRu1—_s×x˜¹|¦¡²aQÖïÓö!Fy[Õò2¨ymä¯ìUl‚#cºÈe§|I\˜Gl]Îv2şğvå^Ï(\LWØ& ıµ‡8¥éƒ‰>]cP•8ĞŒ®}=9Y¡$kÌ|¼9éjqqéV{õ@åÈƒ×—½1ñ·Nâ
p
êì]¯şK.²8IéxX-L¡²ŸÀá;n”3(şÊşh#æŸ»zô&2gÃ˜ Œs-‹Òˆz1^Ñ·O7ù©å–àîıb4°Á)É-ƒHÅ{Ğ+ãîˆX±DŸ”]› ö#=t;ˆï=,2Œ·	n!zDçÒèş¹®5G\Ø.z²ª–F”óíŸµ4Õè‹¥ Æ\AÍe©O1tïÎ‘€…¨»’TâÜYs«¯P Ù£O,àÒ5Ê¹¦õad²„b4¿·ù½ÂtªÀ¦Z»§÷$B5ìÓNÜ“‡[Ü0p‡÷¨ôõ=éÓêà…ñê5±dZkÖà(Dò;ëùçÒ+ÿ9öË„[èUï>¢r{ù¢,ÎâtğÈìü¿§ƒv°Øê4=®:T˜*ËK¦Q³R{‰:…gJXÂ|¤)úx{–…0ù£ciğÕb›MjEÑu©išıË®QÜú6èÁ©Ú­:b‰S7@æ>j¤ÊÒ$o]qwHT§î¤vïJ8hœo9zb¶\¦;»¥B"LvrŸæÙü<Æe–ùå•£ˆUôZ}öibk·Œ3h€ºr£É€\•úâÑß¯hƒù[‘1Ë¬hÆÛDyr·ŠWÂaî<„öÂ¶y­a90ûñÃ”zÆˆNµ0ëW®£´"ÚhqıMf²Ú¤™N>Ÿç>¹¨E¿ZĞe²ø` ½0°ø~n¿ßàIËñ½V®ûª¦¢yGABf$±AüÛ,0Ê5Ø¬Ç¶ÉÉ âÏªÿ«tªç"Ä¬¾›"<‰ß^#¾¡hfA±³ß~İ¨A\fĞe_‘µk4K4Ş¡„S¡”Ã®Ä.Î—Mjø.0™¯u|}(9ˆÂÌ96ğ¨!ÄçM’õªóSùË‘n™Í	K|¼„]yQAÍC/2 p‰/"ƒolØi¶
$å³µi\>Q˜Úh——á@ÒB»LÕ r”„l©µ2ˆ	8Ö&ì$ÃY6Ö=?Ò)Œ%®Ÿ~.yqÊ«×§*‚Çé±xû°áy$’ÈO?D™Tâ
0jóÚ˜ÁuŠàKïKcÓNI¼ç$ªÎôlWÛşrXUüèø¤É vQ0†ê’NÖˆ\ÃÌ³\â`MzhWVh.«Ö1ÿ˜-\aåá¡ßÇßGıAè^WRMYbw8ºõ“ñÔo/»
B×óÎ¨G£Ÿ‹@_[°«ÂúÂx±ÊS.ëş2×zª–„=Š¬*¨0e¦zÃ4 ©Ã¤Ñofeíª(-jî0jsùNşç˜;	a%æ™ÅWùÄ)dêœ%´Ô„2–ù™BÖ«‡ZÒ›îÒi6ÊDQÒz¨~AC_™M×Ğ·@Œ«Á’F†»šù”ULû_±ûOzIÑª~„W‚å2£‹*â0dZHÔ‚vé:ß@®¸‘“P’¿]k¹øÕÊçcZô<ôY ;
Nó‘Ã1…RšÙq†U(»<¤ ¶ü¶Êf{1Q€d:<86YlQÙfœô7áÚLy2;Læx¸Ühr4%ÄÈM¤ruZÀ$ºÄ‹o¦Ÿº¯Ş^ŠÏú‘ÖQ–k‹ºdÁC…U¿ÑHÏÁ
(nÉo)¼¯O»(ı]LE‘ÁG_3îj§+ŸCî-©°Ù;RÜºL±ñ•EÇŠÖ×¸ÚcØi
OåoP!ÊİûL¶Ûàx ñ`füíb8²–/fîäPZ	Cˆ	ÎUÆC®œ4wÕ|oé‘Ràl£¥ÈİH-{°í09æf–ŠazD-¤÷SWàÎh¶
$„ub‚uqÄ4Ómm¶–¿‘Ç³lÌpÆã‡²“‰‚¨ü­ıÍİDÑ¯GÎ$që|ø›nmú’{,Øp¦jûO‹§Í5°’Ñ,%_š|®†s÷Bú:kx…­×|¬S9³K‚6„ñe|lÜøÄ\âÃÒ×öâOû¿­	HgPhá ƒ™î«2¤o‹T‡ár_¢s™(ÇswÆâ^+Ìí˜âú–”úo«4şZR×}0ŸMœ=´Òûöƒ©Î¿CïL¸X‚ÙÃ2Ü“hSŒZ‹ÿ©}áĞ|¼+´éähİXr/”Ñïôˆ«öW:ßSÍA‚¦&§ul±ü€ü£ø)Îş.“ï´Š#x|zˆ\XjµòŠÜœ7ºÄ3ÖË]sk†M±^}ºu²ÑôÜìo©¨õÑ‰JÂğlÑ¿m-ŠæÎ¢™wØˆ­Ğ¢²jOêÄÀ¾ägÉ”ÒÊû’ÆDú8Ël|€±gÖ·ËòZwÜVÆô\=¢ı,„Z~O@Y~e*ûÀŞÖêçÛs‚œ$hY«Ë­a;8óé—ÍeK„ËÅL÷>×Béæ‚{OO#¡šÄÉ›q
ËRíYˆ“ˆ[1ÆÆ“†¡lçÍµ÷b/B¿åZ=‚õñ³Á•‹z€Í›êaÜñî×ÆZÕıª—l·bQ–] 7Ã5†áäZËp¯Ğ38vV|aFşuY…™óE¶ì<Ò @"ˆ©íSu‹©	¢2³õ@…¬CE`Ú4Ö‘,À•@—î²­–DP‘ÈÇİ¾ğhâĞş„õÓÌ„±Ÿ´ûø~çwù˜Ñ‘Ë»8RSõ*OìêÙ1!F!á[ƒ ŸDhrëØÉ<Õ3ë÷™‘J[/~}=Gh÷(ßŞ¾jCŞZÚÉçõ`iŠwuà¡ÍkĞdß”prİv÷Ü€Hr[şqÈF¦ÈoúGTÂ6ëx OËÅ=oF#j×z‰?lw¯âÊünŸ127TópßŸÛDdÅ0Ê¶z)Ù	^4 +x”¯Ø}r¿{…ÔÇÓÅs8MæÕ<¼/ûÙ_6š7Ó‘œóÖÇ<¼şmŒ¿é¥è´
9U¸şÓßy©“MfâvjĞp(¤ìµÓ«ÁuÅƒ/Äú{\„†ø¶ho}?§÷´æj.öV\PıÑL^èğ×D9šYåìåJÌ^¯FG´Ö{(“Á,,N¿6İyÿÒìz¼
¶r‘À²¯Şãy¦øå»EFFÅx¦í94L]:šFWÇ|•»ˆf5İAMwk7ÊMêŠÂ§ú‚â·¢Ê_w3»×Û¾=]ª}e¥?q:U¢“K}¸%¨ÑNä!u>KnHa*Á¼<ÉLH-›M<¡©üó¥31E‚–È°‘4•±7Æ;¬»5•O9ñÎÁ xŠ".En5_To<g,_DY¥¤ÀÃµ„©Ì0¤q-ŠtÃ}‚	å³ïCU‚l.¨bËå¸qnw'Ó¡
oWf†FÃcKtóü“Îçz+€‹ÅÃ0£AÄW{­µOº•Áöâ¥n‰,0_–=²>;cO_Ìî¿tÑˆ•Sx»ùff©¦Eğ1‘JhšCR ¶¸Áı´G Ë$ÅËÎ/K¡Š¬áFøµ%PÅı!™ÉÑGüOú×’Å >ÿ¨û ÖÌÏ«£‰¿>z[K]]¼ÇÉØb5Ì¶­ç!è3DkXa9`¢EÈêÔù„ª¿ÂO¾µNÎ„6»GşÒ¹áØ•ÙÌ½	
É9PG–ÃË]qSâ?%µ¶76á³”Oë3Z¹99¼ˆİI6·ŸyàûÎ¨z¬3Ãcó#1;¨âÑH¿ÍX|Ø_ìmÓ¦¡ĞSI“k¸JO©ü¸,Z“E‹}@±ÜtEW¦Ÿ6ö¢¸ãzj7ò$£€­WIVê½ã®A±™²Ü¨¯ãfo–çN÷!µ‘F¨ÏèÿÆ/y®™™„şŞüä²Å:Ğ$½>~6‡Ô·QIï6aF/ı´Ñ/1Eş|ñQq<«›éö’¦ÊË”¿Ì3eİ,/¡Ê'+(,:/zÕ“€­–¶eıÂGhßqIÑÍ W‰æLÔó>ûGÍ‹Ìƒo"1zI§*vÔ@§|3‡Ô¤µéåE)ö‰¹ÌkËâkTÈ=x…'î(ÏUh¼CEµÃ©F!Êº r!™t#JšKÖúÖ»ˆ†§œ‰‰rY¥ò,	±uÒ¡ÎUQ[»¥ ñ·u:>G±˜]A/ÛQ²` âX­6}bAAn±4~¬óqìÓÜÛ²œ‘ä¯†µNöSÇŞ´IèÊ…¹‰…€ƒş±Vø_¹öWXzw 4·;SÂbFZùAŞJ²u™È"™tÇÇ{ˆ»“U â<[ıÁ˜&¨ÜÍc¶Ì¼y÷>:òƒ­µqMËAf½ôçŞ¹¿|è X¶¶4A×°lŠYB©[Í9]B÷(å~ólİ("ğ"`¿C»"‚Á•y€p«Uˆ=7P»£	Uür˜ÿ£—ëmmt#-d/@‘chÒÓXå÷+jÂHk^Äßğ*şùÒÌìö‹XÅ-Ôf_vMz–j¨Ö—ëm¥ı˜áƒ¸R‚ˆs÷İ­I,—z`ê›Ø5õnİùô=(y¨esÊœœl]¹0M8±—D¾{d¬Ócó‰fcB¸ÛÂy’XƒÅ•æ–P¢$¤)_Åñ=Ï‡yAˆT[Mœ*N0²wŒl‚»%êa>ŒË“eÏ©rÅï.imÏêÊkwÎªâ5Ğfws´© ~pÚ­“+D½®+I¬æa	²W¿šUÉ©ıh&E¸N)DDöNnoa·ğQÎÀş+ ÷ÂÌÌÙ×°šVŞ+¿·…¼ÈŸ½QŸÃÖü FÎ´¢â…Ù@e™ßbÜı¶ô‘¥I'÷›ßVˆ}8¹©J‚à:H±WË¯”ß­ÛF‰$æª¤ˆE!Ea³C+~·òÀ#¤Ò¬ ²Zİ*U4è–ü"ö ‹Èê¨pş-°"\Ò¥İÅ.éc²±pşJ¹Qó’

ú¹+—òS½îea±ã>Ñ©Ä<G—T@s¬!¦gôê™ÖlFİ,ÿM|œMÑÂë5OÙœŒæÎæe9ıcQ¬j+8ˆCal9Q¨$€œúÎÈ~Yº6fàH•îº=ªˆÉ		Ág®O‹9·CİZ_®>ò“ß€Çà¢e¿0Å>&<DÉ^Š_
ÑBÃıãOüæ|İXµC×6~/:NŠ!Fòè·I1¸­™>9+Zhñúğt²Oà8~ü_àÆğE†«9ÁMr9áÍ®yù/±±¿)®Û `t[}QNş÷¤ÉÇea¾ZM\ËÑ(U$”3Rúy”©L¶Æª‹°üe†=W+YsIxÔáánùcÜ¸ú|ØHh*-å‡ñWÁ£!İƒôQKB•815#§v1ßmÿ‡ó°&;å/¢XdüïQæ šõ¸Ã1Ö¯\ÙÄ{´/ìÙŠ‰$1ÕW§™lÖÎ]¡ -g6¾Šÿ4µf¼¤?.¨‹ùPu–öå—`5ÅMÅ\§NB¢ÉÓøìÖë½Dq»rq
6hé\ôŠÆÁ÷íÿ+3HDD˜ùòŸïi\„&åÇ®³ØJÙ÷ã}è—Ş°°¥„¦†^ÓÂ²Øù©O^FàUÃÌ0¾¬’4Ÿ£ø;_—§?Q–7ÑÙkEÏêMkŠt÷ã·Ò{vfwÓê+0mDÊí|õ^ ¶ò?r’[F›Ó«./J1ï›ÊáÏêJ„Ì›†¯¯÷õ?äjÀÌå5c¯¡êwÍ†zdeDE¸ÛåòòÏ_ÿŸèØš9i:“òıé8$~1ÕVgı~ÜórëÙşÛW“d¾¹ó‡ş.€:­eloÒ˜YbwafkÖé¥;`^›9¤àÒŠ9ø—Y–dôjSşÓXPùÛPõğV\«½>o—[s ÷¿)Ğs åÎ’Óé/J¤°4­u[(F¿?Á·B{O¦¨°±
Svp¤`bmN– Ó~:\›h’U·¦A¥pKIû
ğu}ó6oL[nÔ2™ËÆH8õù2V˜pQ–ı›MQUb†NnLš-,“ñÀ ¦Hñ’ÔÎwm³]Šm¾ò@Àí+Ô’ è%ùø\ÌçSİ—ƒr5GÍÑÃ2jf&dÎ£”!¤ÉCMD5ôÇ½Û«ã´Š†D³eb¯‡»9¼‹nun¶¥Gú¸ïN&i¯I’wË¿Wr¾J©Ø~4w*äÅ+‘zú‰@‹£·Y°t¨Ÿ[¦lpÇI‚¨_Ø3—5ÆÉµ2Áua|hé± ı›
4§¯† »;ÉMÄ³{ñ1õ¬ßiì}wÑæ)à_F–ûPğVğu#>NôÕ;ÿë6›ğj	Íí#Nî$yÁş2cb%µ…{ç&L4•`ÈÆ®Á »(XïËÿ·Õ””ØÏc ¿â¡ÅçHÍèş’"Æf`||ìtñzªåu™<üèE Q ³v¬£’q3ó²—èè×¤õcèÏ¼òÌ7Šª/}² =D·Y)UwY,‘•5¢)l¡ a‘Ë–ƒÖ²beA*6j˜àú—¼XOfµnï¯3Ó»‘,ñá#4ÚK©œd½®81$81'	:ş‹#»>FÄ1(¦°8ƒªš[ŒšI
Mì_m„CµáO[ ªD½M¹•Kàaşf†Zkº³±`qªï~jÎc@ ŒG–D÷e
5¼­êÿTĞ¯iÄ8XpĞS©ãSéRSr±}ØñÓ»âu¤—Ëºìwğ(—ÅèYæy.š¸ü>9Çò3¶,0×ì B3BzsòUTjR¢‘eOJÔ›ğ(`8[êÂİ…gŸ•3tõkA«Ö}Ş/Ş^Ÿ“¨
Oƒ	äÚP(Jdï‘€áÛå.çíâ–S ©:†ËXX´üª¸{à*+¿«ïÆ³Ôº_¾òMò;9ËÑü.v†E»šäõH92o\`D~…:ú‰,V‰ûÕ•CÌ£Æ¯d*q2£¤·YÒ™ĞMn›¯Ø¬.Í×gÍ]iïò±5’èÔù9\®Äf?]èáf¡.yG-%çg+Ş˜i™p1Ù‹xPÚO¢“;ó£`Åø’	²`šGN[ÌÑÃğY€&¹íó¤2˜eƒÑXåÅ»+ä¹Ş‹ˆÈ ×£©.†Ì«?^¢N3}bj•mĞm
‹l– „àjU¨nFaú¹^Ëupjçˆí7œËGıîE  šÊRÉV×:«(Íİ¸¨,é˜äê{öjôÀ_œÁtG'šñ²‹fAæÂ–F<¦dT,+[ëib !ŠkyĞŠ(›Õçœ¸|õ.!ú”­‡)f˜"x%º]sÏ¹0öÕD„GUj«ó<åí†L`‘­Ú¸Ås3Şr«y.åÎ© ß¤7¨Àº‹Fïœj)ı¢Ä"¤ÄdË7¿~N/sÖŒÃtäb.!ğI³¼{áM^ç!n¬bã½Q›Ww­{@Ò›ƒ1NiåAfğoÑ^EŒi31;1ó¾XÄÄíÿÁ§×uã|¤ÙØ0Ò¾ï@‹n/vSúWJiˆ#û&mú<Sëß2Ù~Ù·9İp¨ºCøZ·ÆfHÍMó‚XlÄìñIlhaB²ŞVáD‚ú) —èwJàê®c¡(İÅèrEÇØFâ³h£‚ƒßó£¿TĞq²MÏƒí;æéF¹ÿˆÚÄ	¤ö/s{…•³õ€Í%?fÌü‡ä¹F98\Ó&•ü¶¸AÆËwÚßŠÀ e¥{É:¸½µ)í·7÷È{Çïüš,©m%5éEi'¼‰‘Ã`4
ì-ĞÌì5êÂ9bêÈğX¨ù³ª/}‹¶¼%1.‚l†kÓ!ÆÁ§m3G?ÿÓd¥î&—lE¿3È…‚scéõlş‡)	X5á¥eM$[ö° ÌJx yä¥À¡ø1à]0˜Œ×{83t/)7:úBE«Gş“ĞïeFˆ F‚E@Ó›ô^ƒCË‚ÑTƒWHK Ï:jîP¶ÉÌúóú¥‡,=¿æ5ØÃ|—ÃsÑÏE¾#ÓKù½!Ë)lnèƒ±d~Ãƒ<÷"óÓ{v_åº%÷0ãi>U¾Æ
dÂ6E>Ç“sÎâH<&ÃõìïÚãßaguQßz±	Rq—–ò$4q)³XsèĞQãS{zS 5*Û™v²$a0VÆf\O¥V¹v÷wÛâh'K±KëÁŸ5±İprª²èp~Ê‹ºvxÓ	—–Æj“Á¾ÁCÁ|sR°lc1ı«Èö€ÿ;og†\·[ªŒöøÕíbŒ¥ïD¾ó‡7èVµÌ†r?-GİQ!wƒ£[«Æñ†Æ2)G	‘*&²ƒøŞ]dµMYÚ¨ã¥"åZ¯”™cÚZúSj&İ´fx//šÜ}ıæÆf®<˜%\èÙY¢7R9$rpg7Ñ‘x2·†„òl#ÈT#æÙÌÍ9ˆşB€HI¯ä-òvá¡à=® KzC”¶é4nuÑL9øÃ·òCBßeìØ¬6·!ññı­s16Ì%qUŞ;8à»[](½àIşMsş·/·÷›—AL/
[´@‡i­98¾=¹¾óL‰gñÿ&«8µ#RÉ¡SNk©€ë,Í¥¸aê…qe(™1Rğõ)mà¸Í;ŸJvÓ7tüìÅ”^¡†t5üâöæ×˜¬!7yiÕTsuÎÑ|ÃûßÔ¬ÜDĞll•ˆº©„È p‰2ÿxG¨PE¸Ä}ÒHíõãy ™K%ö¹û''nãv5§‡–@K¼'²QŒZ‚Á"E}FpW´–|0é´ò­ëÓ¥p]?ümà;ş9´\;/.;cÍé*Kt	wè_¸Ë,·Åj
kc`‚*Ü€i™.Ã•¹$¤æ‘J»Çâdö	~.¥ï´j …®Æ7{Ñ/ÙQQ©Œr[ø¶
só?®ƒ¡](1ƒ¡²Èk…¹	Ò«*WÇ¬³´’Ò¸qhu%Û…eÊ¢Ê­+ŠÕ\éMQ	,êù(¯à}cÆÂd¬ém¨¦›=¿ N2OÔY11²w"})Öpèâšc:KEÓT£x¬‘ÀmüÊY#k^=%ñ—ÕQäyDº{İuØ)t0HİÄS´€:_ƒ¶‘mğ{1Âxeb’yl°cV”òë¦mxæ¼*g+öˆÇìŒioZx«¸ùÏK¼—­; •.}6`õ¨µ–z‹lv36Åct%Vb©ŒTÄ&q´'š’ÆÁ6ÍÎòK›-íK%Ë³ nIŞËïR¨ótykÿ«—5»Ãö½Ùæ «£K Ò­¨¥`~úÏno/Vs1»÷·©¢Y$î35ŸÑÂµÿúz°ø1ã>*	œ]5”ÏÑá	Ğ”Gæ"ğ‰­@¸™’MŞÚ~ô4É²dğÔ	}Uˆ[³‚ÙÖxğ#ÇË`tÇbDNù?VƒdÁvJÑ·¬çh«	£Äe[G¤3úÑ9}9}1§3Rô¦[Å·‘Rø"–É6}%Ï0&FXX"Â%sÜÉ"ğ‡#îí¾Ä@RdO(,¥0ÖiK}J6v¹]úâ³ë¦`¨¼»„â}9nLŠ}{<‰wÒÇ~^Š†·Do’ÓŸu÷TFGäTh‚âÜY¨¢µøÂƒ;åx¼p•&áµ™=Vf{rh÷ïŞËÉÈ¨üøø£I!8«ƒC9å¨k İ)¤$şõm„o|ÆÛ,Ìjz1LsàiÏæì’zù|#‚Æ?ÿ­ƒek¿Ì[pjÃoCîŸiJ*Ú”R+p×s …Fx=6
ÊgXØ­	Òè“±qÿ3;K¸ñcà\õµ{Ôä»…¡W _^íËêË“ş&yï­|üÚ±õ]ıÌ€^¨lŞÊ?DÉ¯ÏÑáaÿ úŸ² $‹p«zÜªBŒ³×YxÂ¸x¶id<z—±7í×—ü>”±™}ZÄ©¦¶,Pí4c[#wğ~6İüÆhj\ÏÊR¢eQW$Öô5)Xƒ>æG5¢PO&:Uäº“Û$e'¸q“QEù(ãâ—ùİŒÀêšÂÜû_±4‹€B¥`A©í¿CmABàl¯‚bõM¥ªâ]]œg÷jüÉ’XDÉ<¢cÒy^—­¯a#Ù‹Hõ¶§Kë‹N‹{[¬4óÿ¢«eÊÀ©ºÎ¶­º[~ÏOfZëñÌ_ÁXŒapZË5ÛL>Rû¬›Û„íÑŠJt:e¦@æ{UM%úSR_÷……^Ó“>8ªé."­éùŠ{ŸİÉ[çËãz0R?ÖÔ–Ù<·şDe{ßúwÔå2ƒ«t%‘]ÚŠçÇß!º4½g<¹}Ä¥N‰·Œ!p»4Oõñ¨ª‘Ù)€¼‹)9/üÄ4†ãÙÑ³Nf1°eTo¨¹’¸ˆcaXéê½/‹;¶Å/rËyåùUSªXc˜[9[è	Œ¾äƒµyqß0%×–¦©Iğ±Ú7AºáûÚà¢Ÿ«şœ™– t×Lñ>ì”©áò”íÜF5€†k\÷YZĞM|´‰A9p~T¬SWÄı”ğîåÖƒÙÿ¨Ü?ôFµM÷L¾ÇU¸]‘ßrj¯O¼'px#vX"¡›”ö?Ò†•eâ5ş—˜ITh“¥j¢8÷í\E„“`œÂ
à±F÷
ÉŒŒ|H×’áó=·çgikJKáéâ¥év+êœ‹†&ñç)%ß9,¦ª^ğ4õ÷92Œ8œ¨§F¥Ë.ÿ ôo0Z*ÌŒ{GÖW„JøaábcóYºÈ?LNH÷ìñz.'±HhâÓ.9#´|p†rŒ”˜[Ğ}p'¯€ q³|çÒ—Î7æ,/:^„XËëôK[4¨p~´¤4ki]ªØÏ7£=¿×Mb’ÙËBÊiî±V(Û¾¢«øO"İJ @Àß¾ÊşÆàé45ù<r	?‹¢qKÅ*ØÇ¹AÇİdZcQãâ¤ÍzPj@F`4Ú`ç¿é	æß%
Úäâ”äÜùnW6úSëËD%”bt&A!¿åjÓæyJ7U²ctÊ¼AòåÇÙÜ6;ëC$šTš`È{ Q‘7c,9cªQ
²åÍüšr9š€‰­[İßp28èoßÎ¢¦)Ów€ä%b/ E¬°ã[a°™g°·T^]lv$é³4 Ï§Ö´3ì`ÔNî"Ôí	2™o=¹x^wyÑÖYc&IúkGÁ¾nNê¶ÿß»¬œÅ.×ÁY[£°I£øv•†Aïq‘"Êì;‹ç6'¶úl§ÜkÊ
d}59æ[ïLÿh¹éú¡zWàop3÷¶KÛÆ1Û”ÅQÈ“Ô®Hã0ş¼„³|z@Âw^zA»}f0©ÃQÌ†ó¯ ÀZeû~ïâö°ÛúñB¿QAôzü:µP‡E<¯§G3ÁÅnq€?ópşÜŠ\,ßì ñô>äÌˆ7`¢ã²Å7¶-±%3ú;l_Œøº¸ğE+¾=«Eun›×æsbMŒPú/Šxbõ1÷ˆÊëŠ³ÉüÛ=n²•9ë­eH" LŞ@EÓÛ½¥Õ¯Ã(ÙöÆ»–º‘Iš‰kÖ‹Ø±ËÖ¨=Ex?î;öƒà7ø|Ş¾«zóè‘AÏ˜˜
³ÅZÓ=Õğ 3a„LÃâ“1sKÊ¸BÎ"ü]»‰ )IÅêc¬	dÒŒ‹æÛöRi®†Å$é[µıOÆ&3W{ıÄŞ‰;µÇN¦š¥"¡ÿY¯†v¬ÕnÛÏY¢QÒIQhHy•AÜº÷c1¾%WÖ=,ùCõ0V‚ˆ‘z{L´x¶pgG>ºâÚ€Ê!u1wĞ\|j?¦?i¥Ä•èñ`şùºÒRY 9¹îlf¦OäÂ1‰8®‰(r$È{¥İëŸzÀ9ÆÖL@”å¡’NYÈPY”šåiÍïC}ØCãJÏ¶Wß ­*ÆA{$¼¬{"YÉ|å«W}Pú;ûÉ²£š3RÚœ¹(Üc«­5ŠQmİà™İƒ»BuüÍşi$q½Ç"ÿ Êx=ÿıâ]*A†’]¢úÑDƒcYğV÷]x+£†¾úŞF.Ñ¬ƒHQˆ<ÚmSkÃ&ZœL`©$ˆO¬H®Lµœ¥¸YÑ»öN-f’’R)D~
|8qi
õ¬@ó4^û‹áåà&~ë­_“‡öòœ"ÈµŸ³Vb™I14ID˜,ü¹'rÏ¯ùÎÔ&ª"kã5…P[fãç+f ßär1‚®:…Ï°ºé’4µ ÀÈ
b–„õ4€ŠuÚşğë®#0wà¤6Š ši¤¬DçÀl[ZÔËY{°ÎeëŸº¤ª<xGRúı?bù^‚êªëYÀşgÊ“ìú})$ÿüôDwXá,Ä˜}>À0é“™×–Ñı@¾9k‚·èC\¶:(ªº@Ò—÷Ş¹*¥°ø1 úpçN´ü¢Ëã—Ë?üÈÍÄaóÓ.ì€
ĞÉQ€§9‚ªÖ ÚĞ[Ğ13Æ\‚wh¢;äŸÑ´PÀ¬‹Å^,Ñæî2~úR[UÿjŸÊ/|c^J¡–;¶—éğu‚/ƒ“0XP«Å¥(†r£VxÊwÿ3
}OšK‰¶'9Öl'B­hÈÒMi8\u{´í§'ïÂ¹
ZK®vnJP09Àƒæ*Î$ß³‚)ÀØD†P¶Ü–ƒrö(	9l¯ªİàV€P8¹Sq…!Î¡Qñ]×,Ÿ§!	ÈãÀÙv[:ÒkA†‡nÍ¸m@‘Š|úÑ‹ô¨ù¶N}je˜Ø¢rŠ(¢RÄÏ8õW›t­+üz¯ÔMs,A= •ò®ûu
•¨gM1ÇÜµt¦iP<	¸œ…9]zXoÆ°§21Óù¯5qfnOr‹tÀlÎ)æåÿ¡z:J*I?ó8m_Tí-Ñ
šó¹“¶áPÉ:w„}Ğ!ì[R£üCOCº¾Aéš‘õöoKWv¤H·ƒmàªÒp´oÍyºùué•İfŒOã¯«¨#LÀ‚ı­tªË).’1{bƒ#^ ñ•´qÑ^
ÿ´ğg@Ò•Ú§¸è*­3r²:eJÆ»©Õç(WhtR`Q'½-ªEN§7 ¬3'L€â,>eä1Rè¬>g•M²Ã·¤ÜO{Ã—ê…k¥ÌÑ±qµ0ªÍN{5®x:U{RFæÄ›ƒç€Ü9-gÉó¨éu£;`ÉŞÆëN”³µƒ
sâ„å;Täİ>ú	hÖÀmVû¢9ª}\Ï¶à„ÛÛ“Ñ¼|=æçsxù-]k—0ã$^] LH=tH‰àTÅx&‹H\¥Ê~ÛúG¿òpvñ²¼ßÈd[³Æ0e,i’bEAlı>¯J%¾áßù Ï|,”·3&…¤d¬@û´€ê³‘uÃà×kvî\93&dç¯ÔĞıæÖŞİ€ tHgc7	)Y^Ø§×¥TÂ¾m?ªà`”RŠ@Ğk‘ 3·Vœ:ß<ê•|pWÚwÑP$„€¬ØàWnıÙÏ÷½S–dÄ¹ñ•üéŸ¶l¨œA\¸"Ö~ûÈ€&¢W–]U\òXZĞH…FGÂ>,¨«4L“g·ç¬´—Ò{N?ê­_	?•ï!óı–ªl0l=%™ox^1³wvyqgFó$„_Şê®ÕYÚ—)àFf*áş&¿~©¥*«a;š­&VšêØ¦AÊô÷ºphîû¤Gòz¡L'·–Hn·ˆİ¡ùŒXpìÚóM‘¼Ûñ`#ˆ_Å#Óô®[›Ó0VÉ“îè3’<³r‹§ÎÜ“‹ì/x«³Ê´×:R±ä]k?ûË÷¤š[2kÙu2™}!.è†sFªøW>ãèbş«8Ãµë°=èã›0­—)V”ïĞ˜…+ı•é m‘0÷½Œ=µ“'!U-Ã°¯AjØ}ïöuò¼Ín’Wg#_®¹=ğ¦ÌWùH®í*_Õö×üÆ@ôÉ®Aú&.|¯$k*Ÿ# o¦6¡äG ³­·l%ÁF£“-‚NãıQ¼//¡·š>3qÍ¶jNEár-¬ÑkèQ¨fqƒ0x„î<Ü"SµØbJvæ•B'¤p‰àíŸÔC›¨J—Qg«`ó:ıp“AÈÃcÄt¸  äêğu›7”´® µÑèZNÚ)ÌP6pUîåy¡ô¹L–_,J~Cjº¯×Ó£ÎE”¾Kz« Ç)r˜ŸÑêïÛëÅ	%qBËË×›‡Ğá¦³Ö–rÏ±n*EFY~bÉ¦£($Nû¸)¦ÎEx÷³Ãeö3yµŸ”Í¶¢}ºÛ²äºe‘Õ†g>ÊæØ© ³…Oÿ R³¥À)KÌÂ‘ëEæ=ÍI]ÃôÂ
)ÈÛŒ8®÷M„yÀ‰”,2	p¹Hl¡S¦µâñŞ4ø`$·qR€×»ïÁYù$Ğ¼Ëˆ?…(y`Ñ6½â¹¨ëK£1ÓqÓ3É3ˆ§¤öjôƒoÜÅğ'«cyb ÔáÅi¸­/	E‰êÓ5¯ÊìÈ‰ò‘79O<¡×¤\¯¥‡@r©—­¬†Ä×3Îù¢ĞûñCf³'œ¨×x–|Àe’Å¨"ßT!ãÌ…ÒVëT£¥h %³¤¤ùœ˜ƒ†bá¤ìÙ³›':ÃøÏ1»õQ.¡Z!Qö ú¤MÍå=…¦šr±xJÁöE¡Ô0/Š'ºÃëP½QÊªq-9j¥İà4òÃ˜†I;ßQ‡%	“¥ÈtöhÅUºX¬ò*3c˜ßÆ¦VùVÑ”¥EâšÅèI—
;	_Ús§f#s Æn‰$]YTÅ[º2ù§ƒeiP¹^m4Gl•h¯ü‡GÇ_.ÕnÌ;#*H€1Ù“d®-¬ˆYû‡yå¹å*“xXQr"ÿˆÔh&Ïé›f¥ƒPüL¸+]Wü-ÜÇªùÚlTã²LµtÎ¶ÊŒ	“o58Å¢¯YupŞ¬…XÉgŞ’ÜÇw‚?8Ÿ³¨Üºşòvi;EqÅov‹*Ğà ªÛ4+²ÆDW¸ó_ƒà.YĞK†Õô“?UQ™Ïk»¿y› f&R[İJk›íàîf³¿¾  a>2H+6Xş‚/ØË7âßš_„×ß*à‰ù«¾‡Ó©õTÅœÔ3%ªÀB&Uf°‹…ºØuIÇìA†‚¸ßªü1ìG¡¡˜ÌåÉ*2¯gÆ)‚”Êø°CÙ¾’¸Wôdü×>¯Û‚À;z~Ú•ÉæÀÊš9Å¹n« Óe&¹"í9MÉÎ7uñ{ßaQˆJ\²VÇĞÆ_ª75õÎ
©Ì÷2²İ,LI¥±Õfİ‡ˆÁÒ&Õ‡ö™ºGÃíŸĞäâÄƒ@€ó¯ökA·«­¶Ògéü‘SKôĞ@§ÆÃ1åÜĞ    Pê‹ë]É ö·€ÀÕÄn®±Ägû    YZ