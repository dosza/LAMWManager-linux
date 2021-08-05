#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1461941396"
MD5="fe8122586b262fad5301779bf912be94"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23740"
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
	echo Date of packaging: Thu Aug  5 14:33:52 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ\z] ¼}•À1Dd]‡Á›PætİDõè¾„:êêâNE§S)¢Ë*ŸÏş÷ç#îz@Ö#!
éİÂê„"lË×Şcş·ûÑæJNÄ¿§+•»P‘qf¬ªÂŞæñş‘ß§B¬´QÊg-T1á(âŞåqiSQSÃ¢øˆŠÆ‡ó6†fwe’údmHfYij¥a6BM‚K¥Ñiûh2«ãÊ†\õÈa>H:}ñ_8DºˆÄ¿Ïø$ôLÕ@sªÔ˜hEîmáÄ.Òæú{mÜË§ƒJ¥sF«ˆm_d?´sÓ_BNÃïÁi¨´“éĞÑìjP†ƒf˜n§§çUkÁ,e¾Z¨ÙíËkÆ¸FöäxşËSŠÿæØNêl"ùT7¹+øËA£#X˜}Yl³Ó.‡gBçö…;=1.êˆ<k
\¡öÔîÒ­®Ã`|óªº&›§á6ì«ÄtqvÙ’ª9Å—éÎš¦ÌJ¬I>>ĞıÛ¿}Ç]Ç‡P‰Up¿Eqè¶âÕ“Ø6Î¼‚‘
@¹?&£ÛF8‡<úøw»ˆé;œ‰¨Ü¯¶£Ğ¦Ì,ë6qçÅèÈ,S0¨¬‡¥”:u¦OÑûôuß9kÀÙªÙx4®¡™Ãºÿë„êá†•Rä
1ßõ[1ùÕhU%p*u£¯¶ç}H¥Ö˜o=¶=Ş2‰ï2ó7ÓëwZ	‡5ºßBiú$£ùN*5‘O\MÆ†6»Ùİ}Ío?ruT!æ´ª&çğOOÂÌ,s ´%~²×Ğ=µF}¾!O*ïÊVCc²¶ïá÷.½ç9…ê7gHó~y¹”^ÅÑÿ(b¾ëğ;ÒÇŸ7—Wlİ‚HîÕx~øüµø0~ïCÊ7ÅnUñ˜?-°EÛŠ Æ×õaaòg——q—Æ‚Ü•·İncP—s—O¡<ø0àEOí:êæêTf[:cåÃ3]‚¦á2»°7=œxæsáÇx¤W²9Ïì…à‚Cª;n‚U5â:4‹B +Ò¥‚Ùİ‘7‡÷é¢î€¤É8àMu°4?ñù³zbE	ŒÍKöê¦R—£„kh±U®¥m¬¼!"ÀÂ—ñŠAy0Ó›ƒ0Ü¤ÂMDñQcÿ¶'æáÒÔÅü¯ùÑïA&«œ,æ+h7ŸËbÔgsº	 ¨«ª¬åÚ¥¥r:PÅBû4ÊÆéó7÷P™M)ŠÜkîİ¥ ‹øhƒn	ëp,®)²6…:52< òÚTOü]FC¿"ˆ À°[DF<R?uX®‡_ßC¹b;Ú×idím¨]…ŞôÄıD7Ü|ûÇôA h:6Š¯"šºĞè{éo°|Ğ4ÓŞ,-^zxxıM0ª 9ø÷Í}ÇŠÆ±Ù ªàâ´ïÚæDëÎò‡’W©*àJL}öPv¹\’?Ôpˆ™æŒ“ÅP)Z#aå0~%X¢¤\[pEÖ‡òøU¬29i@b'wrw(³j‹ÃpT…›Ëj2œm}—ƒ–ø±!\P–fÖWï+ŞÉ®êÊ·49Zì!€xçßÓÇš¾yÂ&j¸ÈõO0fI<Ul<FR{¢ÿNŞæÖ­³Ï2óá`‚åM6EØü·D‘pìo_ñcÙià€´~igœ$c½VÕ­«Ÿm@C¼íå™†¦Å¥ùÿ[¤¥¥ ˆä»dll3–9†¤eU{v\]ÈÛN²èHµÚÔÒâ9ínÀ4¤½ô¶#+Ö-’=Ó•Ü¹FFåœ~êÔB«!~„T]ÈĞò.'ú(Ç|Õ,ïÖGwˆ#=É¶ùqÎí¤Ì$1¢¹F%,¯ÌkphÎ£—>yÇk.ÏKSËµ‹ñ)(›iÆ=êEÇšJ—Vş?±d|È·åà¹Í½S²_È/+&Ò#>RCíñß¾¶ÂÒ¡…û ˆ¶Èú6ƒqN«Ö¡òQ´şöäuìUT±ìIj³£  }Sk~Õ	£cY†ß£Ë¥±]~ßÎ¹#æJF!ù™™Åˆ$aƒÌk"šTûqkc§’<xK	PıÀ¨yîvPƒ–X"1x`¨èdèàcAjÑV+¹ºª$ŞÇK!%ämŞÈ.¶g†N#òÌğ…Ÿa6éó`}›šÖÌôßkT†£{yäÉ>-xK•’#„ß@4;:Ùı×iŒÛ»l¬"_Òñä^ÂëF®šä»o;“@†ºyÒ7-æÊz}®7åPe\:±°İıYÙ•sGû©°ñ‰K3“ë^ÈtŠØüéÚ"›E¼pc3€•ğl0?IeÚx–‰,£&]»¿UÓ‹”*…§ç—}¸¯A5{¿…À`ŞÛu	c¿p¨æÌ”ìÉâh/ûyĞæ9èÁc8âd× À–ºı›ïŒ¨-R¤ÿ’ää^é¡hUUî%ò9Í´39¿c/‰á4EHº„aÅï~(ùø÷BzÅÒGSu
''ğšy`ç¶[µ!ÜÊf®=s‡¼(”ÿãî'ÛÏÛ=uµ	°+¾–êÁó‚¥¶øbÙªv®”®‚ñ¸É™³%x!“|.Ìõ	gó„Ö‹Rd£6ÖFgµÿƒ*Ş²vĞx ÊÅàQÈü ’§”„‹o FW±Àç*ÍYìÁìBĞ\Bšy"?€ãnŸ‚\=ı+"—!ë~±;@‡>P¶P1K¢R¹»<&wV×½±_Ô&ãŠ2ö×Í½\jİ
NƒfñK¥[”Šª¢ÈŸ¶Äg3
(ˆÒñi-)vG“Háåjî²?MtÜ jÄÅ³ÒWIŞIç¬‡Œ-eĞ&šlu3c¯M·òl± 
Jk ğ«†{ªÙêêìğ –÷LÚM¨M«š;®ñ«‡†Ê[÷ê»l+•Œ*3ÊkÚP®¥¢³‰2ÁRM(KŞ/)|xæW´=²ù¹Ò2ÿÖŠ‰r•é¦îô¼]İç<,ÿm!˜vĞö%ùOÒ$é¤±ÈØ©¢Ø…`,Aë˜Ìf9I²ü~F
‘2ªæ¦D\!)È$×jdÒ¾ÂW]*QGóšLöuÉ1`là‚â 3bh«üÙ]íï?ˆ­¬
gÀ¾ë£ÙE	i×[æÚ’êôT,š¥İ k’
—»Òú”á	êËB«¥Õ=Çrj1µNÙI„¬fíÅûV“¬¼º‚Kh)52•³ª6†GvVà±	Ó&‚¿ùŸsíLø^³` ¼5#ä™¼œ¿Ìx²1¦Y¦•7™D…|ğ™0¨J¢^Ã¬•0<®¾¼FVú,É¥u^H'Ú	“w^ç¶'S\6­årkuE}Y	ò‰è&®6<	İWÚñÚ¿:ïP'\(R-ÇTŠÁUm_“
6ôXò§…wfh’õQ°µŒ„ìÑ&¢’‡ÚìïĞPä[±é§…pCÓºÀü…2àçî°·5Q€±6#¢ª(åWÛMotkYè Ùå´5Sr:åb¼ÏH¼L1;z/ÍÑ-/NjN"bÖ†ë’ş”LáwZŒq¸à 6pÖ‹?ß÷£fì>8ĞDˆÃu]£=ƒÓŸé3¤¥±Ÿ/IÎ`Ôˆ8Õ ÀÑ.¥A÷Îù­‚Z°}K]¶
CBÑëcµ‰‡?~”{ ÛA#õõzAç”Ù×¥üOË²ó1æ¾­ÅÈBïpz¡íBE‹¨—¨X›`µÃ¶e¹#şøäÛKWœÜ³˜Õ1æyO~ï¾;fÓL |=PoÖ{>ƒÎ§6°İ«$0¯ ²6Ñq”r5UM¸Ø¬K3Œ6TÙÇä>Khiz¨ÖNt³NşºQ¯ğfí¸…Ğ­WÂeãØÓQœ/Çÿ­Kk*$aWF½Òh~f?Â"ØêÀª>|øV¶@=ßŒ†Q#4‚·]Ag~7uÁÌœeqšú‘æp-Ó¦ˆŠ#ê«+ßvÛÙÜùœ©%‡'¸ÁµOÄô6ó k\AHäDí]FbÛ£ì½ëI\W«:D
Ç f[dòä¥i¨… NÀ>nz‘óÃ­)AØºâñBÄ@Õ&øÛAË‡ˆK„ê¸N½¤Œ‚ı›kÀ¼uVmã…‰¤ÿvEn©@\»®5± ßq*UËƒ½]CV B<m”Ã*<ã@7U², #RÊšn)6P¬.çYoôØ}p<àŠ	Eìû—||HĞCì¡“]v´:Ëì+¥vYÀ©ãš+áJX¨S£?º‹2óˆü—ü-[üM·“g•˜x/«+Zˆ!‚´ï… ÒSd*D–f@ê¹*LrjÚã‡/×gRÿ>MlIG·Z«*ƒØ>}-ºìy~*?†¤à¦ß@pcøt·ÂÎó*ÊªSÈïÅ)¹nÓ~Ğ_º‘ï]j{“BYò@±rh”°úA™5”)z;j³Äåè€ßt3Ä¯luN_EWÀä-‡ŠnèX :¯¯âL·:Ä=Â]=áÄ
WÃåâ>%iybçÒòÁ²Û–h†¿+/GQ0Rãµç@Y©û~†ı¼iÿS+ı( ªŒá*ZÄo2‘nD”Ï.²@’Œ„kKÓS\À|şRIæ„¹3Í^ÔßLG§€ÜsÒ=²CÎ1‰¡‰uòö’wt–#FD3Ãã4§Ò2ı…›½Cƒv¢°¸ÆÃDÓk4cm‡q–=óİM£ÚÙ™o—½úéÈàs‘F%ä¥‚Ô¬dağ÷ÿ0TPÉ–•‘«ò¦GiQéõdkn¤9Cn+œ¸ o÷Hgt˜ı_ri¯IgqDøzş7/<JŠÄÔf×ÅÅhÙ!G)0cøÊ
0êvZ*Q5–E;,•`ªl)ÑT_j×¾›¶ïÀ–š¤I­?Ì
à4ü8%R°Ø¿ÿ+“C÷ÄÃ2‚œ¶ßÑH@C›ÀvX}	vnZâğ&E`r}„L¥y/`ş>}.Äj1sSƒ$™ÒÚ1l¯À/OW`&…Zëƒ%W‘9²&m@“(™»yû­İ^«0ÅÛu}Qîö­uuÂciq·l’›™İ¤lúZÉˆbÄS*'ÚWtu	cµcc-‘GC4ŞıàñN±¯ÖŒÁFfNƒÿñğ	.z!c6¥ôÑc–$ˆ}¸ú:¦¬¬û½5DÀ~ PŞ›-öCøö&æCÍz†“²2gRå~ø}R,ŠÏPšz]¾ÓJ¨uØ°ù•:ÿF÷ƒËÃ}*œW·Ç³JjŠ 9K²¯0oÊ~ eÑchÚeÁ«½›¿ĞÄVÜ–AX>û­AñìĞË6ïx¼·Ûÿ¬œáÔEÜ8ClG’.^P³àx_C)vùİ—XİÃP~_[ÉÛrHÏm˜Î£J>’~&ˆLÈææãûÇ`{lŠJ©‘M^Hú9 lB–­Š¯ªBš8"…º2¹pèW9‚tAKËpğ2=î*Y¨Ÿ³%Kş”ú­«*ƒ:ÔĞ÷a:ävÒ€vÓ9.ô/ië!t8oàƒ§‰Àšõå0 °Â+E†ÃË6Qw­…ÈÖs$¤v£ñT£Û°K¢tLI¸%÷ùË×9Œ6çDo´raîÓc²âü¡v§ìeç=‚V·¡_Š=]A„Ó06º†975cM-™ùµÁ
³xá®ëåğ`ZÊ½òJH‘½¬IÇßÛb5‘“ëô‹7Äm1Ş¤¾¹¿R©–ó¹b"Ø^&5gT…½Õ±ïš–ô._Üöˆ´kàxâU5Ä?«|Â­*¥èøq§›ƒñ{ä†CX´ç¦—H]e·ÛÇxNäVGiˆO4Sìlş!æ€ã­ˆ°#ÒˆÛïvgÍn·ÑÆÁô~”ã˜hÃ`J„›³rZO‘fUÀø^-è¨èP”YJPµ(p¸ŒÿÁjıVI	1G]—®3‚™@&ÁkkÓI< ½>r•³Mz¿=dUÃHé«ç !äš5	-âz¿UË°òíá§¡uÒ£7r”*«ÿ6ô:Pî¹éEëøMì²»ÀÏ4ıøÚ`XõüWUñ™Ug °i?ÖC;Kèä‘·O§FáBÈpñ¤}°~–:$\ˆ÷¯—f´êØ™Dè‹Ô0c;=@|Hä€÷ÁTøuxqÀxeòı–#4"sèğ¤ßL€“kÛ´;úŠ¹]P¾nŒ&1x!É*%!¤V
EeÎ0õ€†­Ì¬ZkÕtéÛ@oJ@BšŸªâ”¥ğµ£ËÃ	c¢;K‚mpS/ÏöØ„À_8QƒK¡¼GÚ#mÈR(36ru@Ê\Eh`B„İÔkw­~'eÌ­‚ÿFe¥	ÚÌê`LÑ<"Hù[ş7l‡H9.Ï/‚=şk¸ˆçmxàJƒØF{GÊ'Y'®+l¾§ĞG6N]¬`k};Ë¿QPg˜ç8Ex£Ó¢”+Á‘˜a:’L`Ñ÷§yvoÖÉßtšËüØØ7M>
Ê_0yå}`Ö½º‹D;–ªôîT¦¶àkôªG–#ğ[?˜«µ]ê–qY  .X¤ò_ºSwh¬e@Z&hš'ï(y3ö3Ö°eEwOÏœQLÍØ*¬1híQV2iıgmà4 cmŞAi¥}õp°© RôØäª8¿·•Ü[VÕY·××†®8°¥2`¹ÇñÆm>[AcqUŞjÊ †ÈÚ|¡ÒÌ	½ì‡’]ãÖ)Kµ¨ËvStĞÌ+SÛNx“‘ßT’È|&GÖÃ…D¨p]¡ ­€¸ J -§Õ¨Ò¼½¦Êè†sO¤NK¢•.Ccõ Õ‚Ù™’Ş¼EnCğEÛho­ã>DÜ™8r§³<G*ëWl[$Â¤îDËSªİùÓ©SJ}}=Åt¯‹ˆ(	©ûxˆÊ@ñÑ/	^Û;ú;’íŠB#ì¤÷÷+ª»Yğ•¼±¬w²…K±	¡Î¯ÈY:X…KB‘ô÷áæJÆ“ø2š¢ÇÚ¸@U¾ÃÁ×¼m³3œKàõÚ4ä~}ğºñ†¢¸ÂŸ8Ù9vT¢õ“ûE“"TAÁf=0DUUÕÖ‰Òi¹ÇB)}›/që[ÇøÑ§şÆ’Ğ¸Åit"ë¼drôÊqÉkí3‚6_Õö*´ÔCÿ ZLa­çºb`ıkÉ¸t>z¸.§MzD¸ìBÃBì…Sqh;ú_º·®
RÄ-¥z[|àßúáPµ½’Å3Ct7;Íø©*±kiÕ¿<x‡áœ‹ÃíÎ,§ğ¾ÇÄS%ÑMñ(%VĞ’†ÜÏQæéƒI4‰¾ˆ`–†,¶ARÌ-×Ây÷ìHê9„R^ÇddJQÿÃ*ÕsÜ	wœò ÄåÛãí¶±@úñÊó(ÈÚY(ÖÀ«ö„ĞÌíÆ=´ZŠEµ|SÖE›­wGEîªgòªŒl-íÛö–¤i’U°tJÖ¨ìÒ£ıˆS|K˜*½Õ2Óús;2;„
·ß×‰şDŞåè†ï3\=0fşw+;`¿q)½|û„‚Yä6LğÔTq"†›É-6tŒıÉ¯
ï”8(æa3¾Y:mZ-~163k®E¦8M.W!éñ&‚?å‹!x¡ß…œDÛ¤›ïIèj¯á¨âØéÌËâ#¹F dm“Â×Ò3‰TÖ`çæÍæaèí8&º¨Oò1,µi<ìzîÁ¢ƒß)£¬0Qê}A¦©ºÌ¸Î*–Í<ä˜ƒû¯‰`X[Â¹|g½úÈ1K_EÅÓÛ–éÖìBå& >øí!KÌä¯/Ö|¾güdL`Ò•È\0î`›·€Rj˜ÂÂCK³ïpÑ_w‡^z¥û#n ‚ 6SÓ†¹öúäzı$ûÔã~…ÍX.IÚÓ–Üú€AeåĞûh»Ë¾»3ÀvcœÊ­´İCëÄ‘#ŒÒíd‘Š‹G ãršãúŞºÚzºÃ€¡f`f</Ì8Jí¡×‡`3”}	P?;—ÃíL‰ı¢XãæõğĞ¼Öà³¤¶o%	ı·]kkÛøX+7å¸¤ÿm1¾¿vÙ/ŒHØF|:>‡’'$¯2äŸG¹Êl…«mİ˜Ø04!†c]ÒQ^¸…á±¬­˜m)‹›ctq’£=Qˆ‡¬'ÙƒÔ °Ô‘št#Üt:¥°v5œVt•Uƒ¶G”aĞZÉ¼ğ’*ç3„á{#w8T„ø¥İzšoFˆdqşjIkÛi¯e3;ÃG`A´™ÜóW¤’¤= NŸaİ¤ı{lT’hBb|MÔ‰­oÿé1’„ÄD#èheü"½Åtªİû¦x_Yæ=ÆÉê!q¨ÿ40«3æÅjoáÉ¨…Z>ÍT.Øä?Á=õ:-SR×:™!QÆ¾ê+[FÉ3£µÈ§:9‰Ÿ®T©wæ×1öíëP¯9qšY1¨K\ÎCN‚ÿ¾^,Ö€ƒˆÂ3Ùkå'ş»äM;Òğ¡nÆ9NºôF€í"ÒsÒ~UÅum}d@ÃYñoS´@£[Ù–:è7h„HczèvƒL2À“uÌKÅNq¾İ¯CèB-%İ‹N&‡µ¨·É\Æ;®¸&F=¦x´7ÏôI@Hô†Ò.õ©VY˜”‡Òk‘ê‡¤hk`0Š^àì¾Şå¹­Ù‚€œ ıù‹Ç`ú‘’Ü7éğfXp(ã¾É¤+4M/Ÿk:2:Ô’ËáÃ0ÙŞM–v:¦eÊq9êKä6!²y%“}\SÖc\?pŠ¸UM…4\Å$–'sâQlC–`Şn?G^Â›¼'øHª­´ûUŠé}d@¿“×ÏÎ¹ÓöŒşkãÆÏV®ÈWœ&vºKÅpı¥m²Ö*Â§ıï½s8ŞÙ®Öœ—ÖÆRÄÊŒÖkoV$Â.«›Ë„Â~UÈÓ¡urÁCjW†‰MY¸St°ÊÙûJì·¬ÈäyHµİ®#:?»e2‡û¢'ßó™¹gwşiÂ)¡‡—éÓCÀ1²¿Ò«RŒ¼;-=Ëuñ§‘åœUIÑéWIQ"”ä^à³CR‡Y›Ç£…=#ÓÑØÙ²x@¿ë©•ô#ÿûUºD±+å8qa-ñc›C:{bn+	š¶½™×L?ÀÉ©9ÁbÚû³.‡Íò V &à¤¾—8Ÿš¸7Ğ£¡ås—MŒÛnö² dDÜŠŞ²ş5’dK³:R]c=^v^šô†£D]¯_µyW]Ó–nã¼±&ˆäfØ¸L‹Ç‡î©'«Îp‰ú™QüyÆ÷„-iĞp?–]áM<6¶sÇ5ôşácL}‡Bï l=læêÛ¸6¡¿É¨(Ô¨äZ”2X6ìGU—„ï˜‹3gáÀcŠk?wOÜx¾J¾È‹r¨ÍIàyhKuÃ»¿Â®:$	Š3&µ>6ê”öpÍæ EÁ>Ğx¤‰;9bª†M}h¡n‹¸ú)¬İîâÚ´
Sxa%¼|¥½ÑIWÏ£¼‡ıG}ŠaÄ¬~íÜÙpzpëµ“`ärtuı\»cçXûxW¾q+·'ÛÕÙÌé6·£QÎÖÛ,®Uày'ªcÌP1Aò8R¨†_u¼³Í#†ršùSõ˜»ŞO$%=ûŒ/f­`ƒÒáä©ÌÌÍ)•¢<[:±ısğ”%$á—µì}¬[Ÿ½w'%>¥LÛP¯¤Á¦ñÕúoŒqä´jp…L4l#®Êm'¡ÓÁ’eç‘5)ŒºÇO¨n¿$˜iBPD<pu‚~Y´™*ÿâ%œ$¹:¿0êhLh¦‘Â‚ç²õ|€	Ï—8ñÜhª®Rò‰Üî°ä]Ùù˜²^İİˆ+ b,‹d ü¨®ï´PRÂòueløœ‘úzZÄ=)î]'~dA†DçØQ<³áÁÏ¢w2ÊÄ”«ÿ+/×S8vËv¹÷y)?Vµ}öĞu´ëc)`‹ñi"We‹t y#f\IMr­œıÆÙvéµ(XX3e{õ¦A/E%;pújÉ„e²?©ªèü­gS®#?b)"ês qB1¾1lÍŸoş¶òÁ¶˜Ñ¬F½-T+µÖ^ëv%5‚{Ïµ¯ê¦#3³¢¶lN[9’@³&p"W;£vN¹?&oçÌ~Å
,Ğÿ•6Íc^K¾	Lt.KœÕöèÍæ7{*k|Z ğÃ”3‹Š.Zê™4¤Eñ*‘uİ0O››Ìz1ïY„BXÅ‘iÃ7`'ÌLæ5…¾M
Ì€Ö ¼”´¯*@†‰ÇÜ§íI8ëj}™şe?Gg=“7G¯;Iå“e÷Î«á^±ìÌÁjˆ)ZÛsÚ—íŸİÈe¾C­²³ıÂİ[6±à-£¡8ğ[úç»SÊ2ÚK¿üBÆRáNO™ÃÙàêO‘0»ã Uòˆ2ÇVÿB«˜{ö²İO= mò×¡!Ñ:-¦ÇÇ"´%ÎÛa…?€IÜÂÅ‘ÇjQæ]î;3R7Ò7€[@%¾úœLR_Å)\àë@«ÃšÅÚGó
;ê‡A/€ÂŒb/†ºõÌn‘Ç¹Üe"~ğja|]LçrÆË3“Ôä½6ÅÄNT&ñŞKÇhÕiÄ#}ªÄ3®Agï\1Şv0ú€áá²ı}îãh'7En^÷lÄï­èZ<7ø]Öó‹h€RåÅ%üTz‡¬a¨bïxne­(Š`Ápla{ÕÙÑ/¬šÖg«o‰f-ú“ßêãÏém	ŸšûQÿ`GÓ ªÛAªÊ†æú9³.*yr½ã¹NŞßRbäÂ˜„Áån*œà	Øßª¬v[ıSÂIéº¿±/(†RhE¹Í‘Z' !ª…cÑ`ç$ƒy»{Mx_\õI¢9«•[ñŠ§f0ù”¾“Jw¿D/â§éÜÎ‡ĞÅµïp1	‰Å‡µõ7`’Ë„¹'Í w`4EóÆ‹Ç‡;S/¥ğĞ}½CtPéy¸xè*Ø6b†l#ö¶+ò”ı±Tôªš’´±Õ¦áNO¶[İ™´a¼ıÔÎ¢€
1\±ê{"AöéJ*›Ùk.½JÎD ÑúùSOVòóXìC­IóÈŠÌ¢6Iö.6Çì1èÕûÆLgOeƒS²P^b½ß­óÛ àIa õ!ØàÍ/`’ÉĞî¹ßa¿p.CR<
à½Ø­NxĞ£áu;´ö4l?˜	ú£ÅêlÕ:ê•\œµjP¯F(¬«L,C¦õ¶5Î¿±ÙZxN–›eÆÌ`Pxí´‚Äo,lég85V….·šBç¥qØ­ ãhÁ0/§——°tı¿©&ğFóŠ«™ÈéÁ&Î¥¦5A'.V°Uë!ı‹Ç—¿
|ä¸\D›3_g€$ éJ‰µ·2/±D:(šG¼À­ÀğQ_ŠCÅPEA°5 s¡¾]½óÌÓm¡=½•„ßÅÉ»$PÌÿŠ‹Q/¸úÕ…ÊÛb#Äøù—‹úFÜŸiÛT6ˆ½Ëœ¼@,`èœÄ¡_6DÅ{çGœ+¥À!Òì´¸ŠCïÎc¿òÄ³6ø9ìîÓU‘ÑïØuüXes]$Âû»—%0Ó¦Ş¸ˆgŠ8Â5¾†Ï$¥lŠ’JoãŸh5=5É)²Åcô$Æ 98÷¿Aµp?IˆAøåJ ø’Â!ñ4 ÿüP¦•è€İãE¬lèÕz.0Ná×‹¼V[;Ê;À$G?s‹^b^¢¨7•b*úÌÑÛY1¢k-ôM@»q¦ôÍÇş" ¾ÆUšîÇ>¹+Èœ}} %Æç2²­ö‹jnueèy:Úe$üš2úUr5y`{éÉÇRpêí÷ëù;?
hŸé^+×«Á¥p%z6]Ö pã÷>:YpZK#Å?·²ëMÈ&ç¥µû»íÙLe!ä¸§¬:fdf<ß£“nIu–ì…É¦s× i¦T çKd-6í"L½c>ârf_gL5Lö„LW¼~~‡,pZ†HY‚Â¹•1?6oAÆĞ§›W3gƒû¯\»ù„åtƒ^ëUÑ^Y<±*Iss®­»àşÊeÚzDR>ÊLÈÆßÄ¤…ßËã†²ß¦‰y¯Mw§èÂ­¿PôßÉ?åhW&âÄ¯eg ßÊìç³¼Qä,_¾íû E¡'Ÿ€3l%ûŞÖı‰ˆ?°JÍcJ³®¼
î5k«dSó2Y€2-\©Á˜L;¼aİIaF"ºœE3‚µÁºô›[r]JÁR¼~mKêáß!zK¨E¹ó%m7T3zšY|"ë„÷±:è{ …—(ÉZc¶"¤-7Á‹œwËd-åQB…C¯Nwë0\®JB¤ş²›Ñ†^NÈsãHÂ¯#ĞëYë;Ç¡o.¸÷ã÷a<í1fõş0;ºÉ¦_ìàŞEı¯Èîª+·ûNÈ*¢¬7ÿ9àÀ£Èp[¦Gw	Â7%;:(@É§Ò$ı"ÀµALJ8•Eb@8kGØR&{«Á’Ÿ€,í´œ&c]%È¬…ús0ó7ûËˆ ZÜ£^B=Ò¹eŠÅëà¯ÿ[ùÛS+^"æ+úˆ2Ğ5MùÉüæh{•Š$å?¡Ÿ(UÛ ‚§´WÂhx_×çå ™Šª°ğ]±ìíRÎù³JZ76ßp–•?yö©<{Åò˜e8GÍ·(W"Ôrx9”NvÈt½9ŒÆ™k—Ç•C„ŠïW€¯K.·†w»‹«;wËã³3¥Š€×<,ÁJ“O	iGj‚±ÙÚjÎÎÇsabÚÔÏ ó4ôİ@o8ª™„$3sætÍzÌ
Á§ÌPU‡¿åM,)Š«®KÍ}\½ğ/£±jlP±ì}¹±8)jÒn’ ¡äG9FàS2AX’/c»
O‚ıÿ+'>àÑŸü¬BÕq…âvZ±¿9ÅÙ)ÛÑ5S?u¡°øı P÷•|úúæ™†¦±ß:İŒ»bÙ?şÊöZeÔ;²Ş]\œE3TZˆÿÃ2 &İÃÍ’~K©yb#L…YÓW±´¤rÀ—6Rˆİı¢şZ_}Fä'I`É}ŞÈ³K›mFoˆ¤ÊAâó¼y¶œùñğQñ*kzİáRÃB35GŸóÇÜÎÀf«ÍÙA~ÜD›WC¡X›/v(µ'–O”ÍÑ‹É“øw.iÀun8jß Ş,èİ‹‚+$Ü’¢Ûú¶;Z¸ÎÙ†KYÀòP[7«‰fùlO÷ãĞPËÉ6íjäáÒ<fN Z/©?=m³•}^ÕÂ—ø½†çWK7jÍè‘x—ızdjÈ³Åp¬ŸåĞ¿ƒ<€M­tÈd’¤´4¬}Ø_SŞ9^â@yïşPñÕ˜oã®
¨yÊP*İµ´V_½†;Ñ¦­¼ß¶ÊÆqy_i½Áb%¯õ”Oö¡$zé–•/Ö¶ßKÊôîùŒa‡¸¨ÏB:³¨Áú—Âòó¥Øz5Õ*6X¸üH|UÇ_Ùá/‹Ç¬İ¥J+góæuÙëW-cUöè‘÷ÔŞ#±ìé°»Eçõé“?¼@4=ÀHÓ<_šÓq±“˜îl”}L{òù‹Y°.zmĞ<ëÌu¢|;82ÖŠÀôñƒà£«_Ái’sùõ€#åWxï3òhØŠØfÚ–×±6^9ü"z]å/i¥%úøÚ~.Û\½
e=Æ“WşOGKşT‹‚®½Ûã·ó\8™ÙÇ€=0Xá’Ú/Ä¼‚‚ 
¤%isîÉrÖDßnqåPÎk:ïÿÍ5X
wĞ…
P-§ä=‹EÎŸO‹óöIJĞéÒÛE?	^f´æ\N¤ƒƒã.ı ¿ÄµF·¥ë«)Ùn…zxÆ£şQüg«Ïxæ¨	f	×š8 ¤È#èšz‰(äÛµ6èi´ˆm¬c)
H%½IsÍÍ±7)‡Ç›#}[˜M£\”n •·ò¥ô;Ù<bÍá¶p0k®å§6ûx»ƒ !¬ø†‡›,ğ¹“cªH¼F<zç'çµ†Åÿyá±å
ZTÀæĞ‹p¤X`9"ãÍ_.¦^Ò`–QôÍ”çV­8ê?ùËÛhè¸¹rlÙòêî.\U
œŒl¡ÖiºÙ¿²âš|y¸J¾ã6;8aöñWÜ,WÑQ*ò¹²bV©×;½ÓßWé!—ÜRşH%ÌÃu>»@K5E¨¾/Ê«&Ef½&äØ?‰[‘…(æHÌ±4—­Ê ¯óHLĞ —FXo¦mİ‰T«àÚdd4@ùÃ¹ßLY ö(—M¹rY ‘(=€™&8qü(PÅÌ}*²Œ¢RÕ^âHæğ†!FŒ•æƒò¹ëW¬|4¶p# ‘(À™åŠğq+xè‰¾İúÄİ)W8éoiª¢Ô©É-œ0¸&E¹†"˜ö!º%FçR˜iºıçÃ¼äX¼Ü‘µ¨Ö{
03¤;f1y(Ní:rO”ı“9¨°6]“ÁuvÓMÈ=ÇÄo³•Ò¨EÁ›ö_6ú¢İª·G9kfRlš8zIIAGì3&Pä­€,›k9+Û‚õj·|vù³¥±˜§ŠW?]ğÅÛvİÄ‹††ª	)¬ÌÎ™üæ2ö=ÒÿúØwí—ò.© eôë”¥h ¼Î S„­›Oü‡tÒ?ÒÜ+L¾è×İÒ^ök|EGQºŞñÂË‰^R†xS‰oî
¼òÅ»,/j£ZCïXZÄº¢X—8Sd¢±d2„”UMš9^jú¢ÎKšã5àÂCªßuÕ@v_×J­F­Êï"Î§µšŠ LŠ«ñnÛzëû&a’­i­â=À"Ë¦5K\Âš&È W¸ö¥L,¥mgQéqæ|5¿[`Y]vv×<%üBÍ?R×¨tEdúİYŒÍun]¡ôîoĞ¥±ªÒ*ïÏ¢]E£ô.¶hèJ$ŠøgädRö0gñ‘ §Mm y‰w3Z{­`ÆH³À…LãM"€±^HWİoÈ(WÑ­¼°’†’Ğà#˜% (›ÚÙc{>ûìV×?è¯´pzgè5NNn/Nàôà¶Ç4»#ïC6nE!­l‚ä£BËDJ]x÷MNÀ FÊF³CqˆÏ><ŞÃ¾Ê0¨‘ª¢÷„O‡í\J=^Wsõéù&ˆÉ‰QÅK÷pIÓî-ïdM2ØşVwsÏÉÓy¼y—F-¡°Heñ9ùˆ@~­ÊœYì= °K¸Úˆzm‹"±èT(Rn™Kškö·ØÌÓN2#î µäÔ,õ^J<f÷Ø›š¶;¥èœ×w`|ìçNƒ‰¯EÈİÈ€TÈ%îÊ
ˆ{~›)Ö¯É"Z1•dòúÑLŠ‚*Y«ÖÅîN³¶ÄøUGj¬„fD­>ƒQåTsR`èµñí;—û›Ş®ÎC:¤iı@Ø0”$Å8‡6„Ğ¿½ÿÕõÜ4 ‚‚_0Bk‰Œ|ú/÷úénU0`¼ü3 _2ÖıÖ„ÿ>+Ìû7Cß6WFD'ow=¢Ú®mÕ­(àRvŒõEil¸Y”@û2d“#L)N¿ºK› ¥ÈéÃØWÎ{{Ek\8 ò©aêmÛ-ü¿ù´@ –rÒ—Yß¼ˆ÷½HÆiyá}ÄïO*T=æñÏã”‰ÜGÛa¨k¦\4ŸEc|n@w™y@÷ÆM‹øë¸„Cp…4ßÅØÂš"Ÿ">Š›ö¼x«o—|bfíÂqØuïèpû[¾iNÙkz;(„÷ë8ÕòŸ2‡ïü³éz»×(nNSÍR*!JªqVğ¶‚L±J@ãLÌbrº›G¸ƒ´º»L5½wË!MÇõyc5Ü®Ætrø·3‰‘gåy¸³ArkÃQõÃofT›l@¤rĞBùWçÀ[up¾SÊyè4©`’1"‹U¯/~›o•ş=Fñ«œ†…XQör›B3y?Eâéœ	Ì¤pxÛ§²  o·»¨5Ô©KÊÎ#9áŒRş×5ÇÆj5ä&KóŞsBL9'Ú˜ªLö&–rxĞğ«ê5àL•?Ùkl‚ÖuqØL}ò¥Š¯b¶YY!–(m?ë¯Œì1À<€­#ƒ3-±ã1ÆtìpOí£¸´"ş»K×Ã/FŸº¡‰] Z~ÓŞ—Á\£µ\=ŞEóõ¨6EÛ»K¤óÓq‘ÙîôÒßh©SëgPt§¨ıÈÑÔ9gsÆ|‡¾ûï¡61[ãöŒÎÍ]Œf=‡rCóŞdhÛ¿lUås$ë•Ooí&Aé\ë]ä@vÄå|Ê‡l{Ï(/¸}B¿sáu[ßU7bpcA1 ­G‡÷§jìõ“€ıS±LÅ¢ã[a0âHr¬SàX^‹=Qúˆ>{Ä_Y‡QIÑî¯ËB_øì?$^£xØæ{…iI$·µ?{È„­ÌHîHàúsU‡dÀ¬O6G*>›—Å6†Çcç#ßB•>D,›tş&ÊLü£E‡$jc&±KÃx/…D1i¹ö¿VfbæAó3×u#©;ï¸sıç+”a« ÍvGqÑ…æÔİÀoœ©Ùq@ïYè$Bî•Û9İ»‚|[öš­kåb€J• ìÛkÑ½Kí©6ùBfåC—5äÛ
—¢ïĞ.]7ı©ĞÑäãXSŒ™–îwMm¯ñ” ßz{?•Q+Š“•ÊMKÅÂV]óGP0•¨F,Ê-¤÷âSdBş ¢Mìn¦ìxAï¼ç^S8ÿ}®àeÖ÷åÌÎ>jE9 O³î	Â9Ù!¿á¢U5EŒfz…²QÜ½(Y"Ì:üâù…=ü¬üÜ¸İåÇ opÜ'·Ùêª+f³BÕ•÷0m)ŸC´;Ükz æè CÇ»YÁÖºÙéŠ¥:§ÉH‘p ÙåW•)”SLó,B,Á}áÖõÅ!\ö—È5Ûe¼M¦ê²®rD‚qè³·kn»\e+~œP
‹'$‡ŞH[U^«ÿÙW0OçÆ>0Â˜=úd‡ãÃX&lˆj%ñw>kï‰J›Ší¹M²ç÷ª™0?á>¯g†Q*j¼¦|k0œqÖ ¬ñ˜=ù”àüÜwÜ¥Øw +å£ÎxuĞÛdo0µÃT-·0‡ïÁöš“6=

è&ˆO½ÑŠÉ¢Ë<Y{~Ò«ÃR¼ı{Esˆ9ÓØÈÀöK#bŞİš‰BVËIëœJŠ]dÔÅi_F9]'`hƒÂŒÒÍaç=ğ×'!óñ”â¯x=Ÿ2Û™LŠ'-İğMgÓXrö£ÃJvü–ó˜HéõãÉäéÒ‹1ê7h+™ÛèˆÎ™ÚèÃ”kñƒ«&h°Jy2\ÂÊ9ö2q«ÎG›øI£U¨`\2"zB&3‡C>®Gï•÷¿Ğ~ù×Mß	óe˜¿ÑîœT­±¯ZÄWë›p39ö?¸%¼·†{ğki›©œ~–ªç’šÅ°‡ ğf‰¯Ô"Â$¸öu>2İM‹]&¢„#r	¦ù‰€±A[NÛ:æ—2îì}ÒS0@0‘Iz %Ó(^ÿ¹¢ã¼.BƒQœ°ê†r°(H\2”bĞ˜¬÷¥.w¾!~ÿ—oİÏyÆç+%áx0¸É¯Iç™K‚Ğ	>áö¸]fkx:öE}U?g6ò˜Êz—¡¾¬By¢›¶{•+şãg¶Ë†ÒÔ‡ƒl‡“eeÿå'lÁdµ
lŸ¤~˜b½ˆƒ¬÷J€qBñsš…Ÿ†ÌHöÊ5ŞÖ¥‚
Ü‰×¼C‚tìc÷3‡¶€Ÿ.wäI­ÑAOIÅŠ«_àgîĞMºåºéPm¸Z>`‡½Påj/@ùğ•zº’f¿w¸Û…Q(Ş„W!åÂAùš(%ë<Â·$±c2ø„oŠGıÊşJwp¯ûç¯'€ªqîå•¦fã5°älzWá§Ä]÷šA3Ê*rÌÓUÿ•Ãöİ`
O†XŒ‰ X¾SšØš¿Ú­^wAÊcD¨[¢®ÈÓe—ß[	¸ÖÕ˜é§ü»C×’ï_åtbÌÈÄ;bpüŸ}Õn—®Ğ<ÊUñ?à" )à,Òğr'Ğ¹XÍ°5;°’Ê:Æ¿£Û‰¸_O«V’1	¡şÔ)*1û2« ò	}³Uè[&¨¿õéƒb/Œ…gàM³÷pÆAZ­š®Å›fÎ7+Uyì)Ù)'ÎÄÄ]¿yŸoTJñó
oNÙqÄS¦ZF²öo¢Ûzİ·kr 2V}ÿ YTaçgâ³ÿ³ô]…Òí/ƒ&¥òÌv×ƒÿRÛû%ä:¨ßd‘£g©„ı„á…ãòYÎ±Ö^©ó¬är;Œyï¡ôš`œy>^2™WT ÜJ‰l%µä˜,PMäâj˜wÅÌeÓÖÓæ”Î}+jà ‰ıPï Ù%¹¿–&­VJY¦×J¹TÌ€ıŒÒwl3uÙ[÷Âë”Ëıæ'EµŸá{şÅ“Ş½[ŒM­àÜ>+EçÎîirZ±Æ¨¶°×9ÓJÉ/6‡²²ü˜0•ç7¢ÇÕY?à\–tßŞv‡E[½2ı#°ñÀ#¶­¨'¶Ìz¯xhœÙ)8l jæïè$îÁGT±/©æä•NÑ¾¸ÈÃIäò7\©êaàª3	i®å»[«)úq-+%,Bvó7W	‰Ò<dC~%˜7ë+åsäØËÛ¶ƒÂ:OÿÏ¯'U›bŒ´Íyt3d›Â×†:¿`µ8œ}´u_|Ş,á5t¤g`å«çÿº4%Q¼
¼[nPÔ¶ÍL×ú„àò³j¾í‚Ç³äêGË,åy~Ö~#
–\Yhş¤™±.‚‹åü{jÓÍ¥•jÌ)[Ó¦9%´ğè³3µØ{W\,ÙãZguÆúÚ‘ô2$R¡>,ŒÎzí+ô„·\«SzáöÉ-’u)êÿÉY& ì^ºØšâ'íöÄCŒ^ÓÎ“°´ı…à7Œ û¿‡fêãXYH4öVÌoo@HxÅø>'ƒ1Ù‰×È§L%
DUz‹yëÆm£¶`ıãšHG67­F=kQ8xP‚w VÉÜÈâL±,€¯‘ŠÒÇw	Ãˆàu<IéªÇdÆ{Ñ](­’ŒíÓÎ
 ^q1üî:úG?ÆGgÆp± ¥áD9hs„šXe/M#³1¢V–ıu€ÇF ‹¸ªˆ3¬Ï…]U K‘uD	°ƒŠ‚bI§>î¥9»# µP ³fÍ9~®Fiå¸øàõ?3æ¦À½Ywˆ¹–SïMí“N“Á!àAVmz…C4¬£Å–)¬îÉÈrÛ@]B~{,Èmñ­hq„ÉÎÅ)U"ì}jË–šãíƒĞAfèQõ>ÉÍ
%HâÑ‡ğ®ÙšêLKà¡’é{|.ÊÇ…
QMî°Iƒ»G"„©ªñÃäÙQ„cx°­hª•êMœ™Œ¨ªù¸ÄØƒıÛƒÀ
}Š SİüŸ_%d‚zb’×ïÃOŒœş]ˆ¸GÉº¢şıYº§¸Ú9òN°ÂA‰‘ğÖÖøá®Aÿıl\½ ¿uíÕLmO–í°üßrÊ·!‡cq 8ü„å¡SÂì8…‡yú5¡EaäçàyZÌiÌ3¿Êâle ÀVy[è&còUŸÎÒÁK{ùà¶ÕUø†HÂÓ'gŒDÓÂú‚a¾Æ®\yb£æ/¾Üu•W“îHy4+oÛ¿S°FRæ}¦¾ÑóÄ¦Ù+Ñbds–W"@E&£LÌ¦^ÑgPäÔÉ’	‘0ÑöäÃ3ÿ—[š%OWÚ«,…«Ã5ˆ<Aëú7o'¬ˆĞ»†-ÁN+]—C%TËÌ$óÛ2öæDÈ>2ÙbØÜŠû¨ÕVåc²Ğ³¶}
ÿoÙ6téı	©ošn|Ö×Ş3ª‡©+ÅeÖ5-hŞpØ^°KFÜÆŸ$‡ïvàUß¸²$ƒ“ºGi3ãèËı•²³a-Ä·Áúæe?³B‡ÿÁ„ôğg‹ğCŒ ¦øâ«FÌFo€=•‡i6o˜:¯Ê9º¶Ú°µ2LQƒM¥®+k7­¼½FOªÿ…Pof\MõB’zömk…Ä!áTaºpb¨’SL‡İĞ9¤$¤X8?·"F÷m&H¨—¬Yh†l|˜ †n˜•Ş|q{[=ÀğÏwLª×·Áğ‹“{}ˆµFº?c×¹¬Î3‡Ç]­K)z4…–ÏóVi"9OšTqGl©pš£Pø?µ¯µegxU[b¤‰Fˆ‰Âò!›NÍûd«›×xQ±‚+~†õyXÇí½c…-§éØPÁŠ¥”tö–´£¯Ç‘ÓbÊ,)µå¾jIUJi½c¤NÒÎ³Ô¶_ˆ2ß~şAf÷ğ“WœL]2g7¨ÊÁã}$cÆôa)"¹°¹¬,P1WÀ.PŸW_[aƒ«ÔRæõ»üÖ- 6„_í˜¯a€éoıC=øñşjÄDå.§¾’Öæ¥»G{ÄäxSü&•;B£c¶pSJò„´xkrÉ,dfz3Îıj|'›qÀöÂ8ô	a«,v"Íú\.´¥1BtşÜWÔFMüÈ`_¥ßsdÃ™Ü¾·!¦xLŸı/«M2™%“÷ã•wÒ%t5Ûl¯Á;aU5ì‚ÏÜ’¥°ìk3Ø2—îÇn 8úQkã;Q>›¹t3	Òx«åq#¡tXRVDu^9Ü®ÍÖõÍpï‹nšaŒé™Y%Ô;ª3">Ú»Ïr«KÁ¾k»~¶şt¥P“ôâª}U= —ËGC)D—ŸŒ¤ÓKŠW¤l¼RH6_3¢ªîã~àéšİÿnC>VJÁ‹ÒÛOyg·	‚~àHÕ(Z<¹€»ÖÖÄ˜ŒqÜş©o`!˜¯*«x ? , ÁX/ˆ×ê’gå_ÄÀˆõÚÎû>ÆšÕsêZºw"òl.â2<Ìš*á\Z,=døRı$«*øl¡Ğ©Ç+ôuF±¤³xª@÷Şï,è­şÀà¯À=Fn9Øíñ;;¤şG=4ô—Uñ¤{‡S†Rz=Óh
$‡müˆ‚”#´»~sj£Ög[øœ‡Jÿ“¶yïK6G´Ñ,Oô×n‚ùéx3Ênşëg	p5=–RmòÉjÄë­øõ
û[HH½i
aÒ§§í•†_Õ|ºÎ¼ÇÍYÎæcW&–•zk<ƒ¥9Ú	o{PAÎ‘Ff¡p"13C±;±Ì ºÜÌ#í1hÃ\«¸s”i?»i"uı#ü ¯]™…şv×ùã2ö×\Òâ‰£Úğ¦iÇjÌ'Œrïæ%'âÔJ”ı)¸‚îÀF.şòbãRDˆ5ü ¯8ş2?s?SÊYöîu¯îcC.³|ôì…Ø9af¸…ÁxzWÕ±•: ;×ÿ†Òkàm½gtDËŸmìÕÎ7¿mxqÖ.RGXÊˆÉ @« z½>cåW•wùÁÒÙlpR f¢®­Šc£o­Ù:duÈ˜Jù£”ÔˆºAŠì¹é±F÷Zı	?p}¥Ádõ+äãó——OáhŸÆèÖsé4«s1ošÇl{áûå¡\•†f€yH„B¬ö\¹xÇä6½$”‹YY<Æ±}Ä«o¡;.8¢ò“_(Ç¾Î@A¾‰`Õí®ÒPF´·Ñ}hÎËp¡4f«Ù¤ÛgëğõÑÓë¢ˆ?4xåÃ˜‘6 0¥¥7òÃ?4“Dw‰õo2@èâs,²¨èpY¸û¿<ª‚õ	%\ß–†û¿¡µÕC„®VŒ/
Ádx»Ï³¬9hêËq«Rœ]ò8ómPî¡ bæÖ‘QaÂÔèPæA@u@k†eà%³î·£èB%!äxUŠT»ó N›•"Û÷®ïc¾òâ´¢¦E‰ ‡R¾Ağ"¹]YĞ«xÑ%¤ı ¼E&z1ÕÇâÇ#Æ+XåA§À•3¥ŠØÖÔÓÍE¸¸àCLcÿ÷a#KÑ™Gø¨pğ—0ÿ«‰ÃG„“”*Û=€Æ[y¹/äZÏR:÷ÎÏ³ÍìşÌK8-ûº§½É‚ıìÁÆdyY¾ÚÃ<À+~‚lNøİ¤/~v§¨
M"Î•EëÊŒâi-ËñhËamq=où0³¸ [^µúÜ
{üw#z.Gä´
eÚŠ-qEÖê8
ƒävxç2‹")½OL8ûÈFŠYzß+ÒÜ•şİÑ
p Ö—(ü] ôi
Âtb‚š4ÔµcÃpØ|(Ò±îbÒ -dOYûn¿¾5Z“¡EMk[Ôdç¬tî»ÁEÁ%0µaúÛ‘"\-¸cÖè½×œFq•ı4ê0YŸÚ=K¦W˜ŸtÆ×Î—Xß6§@·u:ÀpĞÏ\=¿ŸŞãG¶€½=O¢›¬ıäØ–ò8M½º€Ö'‚ØÁWòl\W&y±²«Kş¬q“@¶£ÑZŸÕ”ºN Ãéór›ıST½b'€g†Mv¹çfL.7½«Üë‘ağ·ç+‘ë 2H>Ówı<[Ù'qLbªD¨!ê¸\ÒNµhR¢ÚV‰±¤{Ğ¶{Z˜Ë y‹a¿¦¡PïÚ«Bœã«Î³’gÇBü~+S!Ÿc4½öãƒ=F·Q‚ÅñC±ô#tş>‡Ï÷ÎŸ)Òaúç*MQ¸Ç²Ëã÷=‘té*Eš š6»­]í+„*†±‚gB¦Æ¿³õ‘Áàã`“Ğ-,ßŸg6çëI>­œ§JX©{Òİ£Z¤/7ˆ9½ˆ›ÖÚÇJLi¢[òÓŞ—áBte	@ò³ÙïõÓãğ¨"¿ ı²
~1o¿Jëµ4Ì[%¦ÏE«W¿Ñ¤2^Sqµ+ \!ìëİ[Ù8:ğL}°A…U? ãëZöÀiÓZ¬oÚm7”-ê½v„­ŒËJ=¹Ài»ûråı’«0éR^„Rşº¯ ¡CR^óÔ§‹¯bPàA4"HŸ—P’õJˆDºyä-wÕ=â,_ûfí£Âòò•ĞÖê»±1P÷¡2ĞÄH¯Íù,U°<‚¸vàCH„:Xºµ'àİ)‰œ¢0ƒÖ<Eø¦‡B4¡VRAœç´èTNÖ—šğ‘[UÏyæÕ®¶;j{öízƒ:zk¹ªWŞudÇ·ä‡¬òJÉeÃ—Û!Û#zøêíe!Ä¹èäËäû¬prİ€iWx—IbÄSëïÉ«^œÍÿnºØ…Òš†ëV˜N×Z)vf­{S—ªo¹'Ç|İÍjSDìŸÂ¥B¾(%g¿uı8Opm{<L·<É0;p/:ÌOm±©è“Ûoıÿ‚´€iB¼–:Ö¦Ém~ö8¯‰‚wº´ì8,7S‡Rà…Š@»mSJVø5Ş²`„`@ÄÌ]^ŠQ¡íjz›ü3zb¤T1+x<û5V8ïğ¯	·‚›&€ûÎ™Í”šZ\.T"@ûõ”t ëÇé­2äÅcpb`æf“[Ã&ëÁî×ü0÷S_8Ÿ+i{›»AI»mw¬gäqjTã}Á%œRqtäã:ûYügº&JOÌ~%6ŞüÇ•$¶v×í/K³›M+noÂkÂh*÷ê?0€!2Ûo¹D×ÖäâT]„Æ,Wc[¡îI‰³·@^×Ÿ?ï'=`Xæ­¥?õ²|\‘Í„ÉßŞN>ÆÉêŸL¤@˜(ıEôRI2?Êú•í«‹©(µ‰æÚ¸ŞHOê“ù‘Õf­ÁCïæÙÁ@µS?5¯Ù~¨ı-q¶e©™ĞHiŞˆQbCq`™S»˜ˆ>Rñä¯FœÕ¤tèƒÓ»Dõ„yŞCèö6| ¢Šo'b°gMìETÄExQêl9QƒµóAaÒD’YÃbØãÚ–P©ı…J?M–<Ù¦x1TŠ-Ê-;2j2IbQïÙ›²^Zwˆu»MÑ¬2„4¹qÒ¿—7[ó¤ï]Öä,¦Ã3KÉº”\¨_²f¯Ó`A=BÀ×Åoß²É¹7Ûcl8ÄbåK›Ã£Õfî4N9ã9Èœ©|¨¨‡”¥´UíÓiâ¥”d\ş!¡ß7Ç@g)Wnx¦K`YO¢8]ısŒ#/DBfzx¯;JFL¢ñ©Œ§]¶_ÈÌì´”¶¯T»,‰.Ÿ¬3+£P#Îu®Ğ¾ığ‹Yåıqë<m¨"€;7‰5u .ƒjğxr4ñÈ^{û‰´†;æÛ\
ÃÕ	ij<™Ty½=S¨
2¹ş7m¬ù¡úaIK[áÂ'æÛ,>	°¯ià&nÑøL2E#1»!¿âÔ²Á:(OòÔÚ‘eÛaO=!Éo^˜rµ¤¦sõŠmÌõ°/ãá¡	è,8b°XÃt[àÁ[¼ÒpsU ‘1D¦Î*­	0ûAÙF¢.YçÊ|Ş`k´—ĞQeNÔco°ºŸè8ª%¤Î8›››ü1èku‰~¦	¥q.Ú}$¥h%y1P¿SƒE ë «MÓîÃTr¨4hN4ËˆÄœk´/·øú'ü˜svsâ
¯@DÎL —Æˆ©Àª¬|¿Î)Ë4ŠÄ:£^´zbÜ”OW1±:£Jé¯™­:‡¹†0Ãí`wpF8¹Še½'‰7ÆØÙ¢Ô¾.MÙ50X³zAô³°.<s8y M­K²v¥òÇjôÆR¤Ï¶3ÖÓ*=Ùl§öøóºJ·+çïzÆ‘*@KhEºCĞ]'ù†É™fAÈ ÍLIc¤®ô­@¥`£k†`71JVn¡J¿A¸³ä*ÑÓf£ÿTôLx£,n=#\€iõ<µÛí³c%ik„µ¯Ò‰bõ— –n¥/š_Òí7r2<İïía¶.tdÕNzTÿ*ô£8¤~ö~Ü—ı‡œmm·Vs‹½ğ#q¼ĞÖ›w–ì'G(ó{{H 1'e°dÇG€ÿ\ß˜Ûñ3¤ã¼K9‰òĞÕšaù³"öª@(ñ]½À—«ùË~{î·Ø^+©NPáıÄÄa—_¨J;´^=wîg8am¢³°~,Zàå»)©1©~¿°vB<›ØÂÀ{µ>°è»6XK·g şC]ka†AlöMv€ß\”Ñ.Q.·ü˜ßÀÍ†œÁ£?Æ1k-ÇëøöÉË°*]¾ğÅ	Ÿ£ßÙç¸rçz0a»š}K‘›¤ölDVÚ×äA¬ì ñ2	Fzºåzo|ûOë+Ğ±1vö*%%Â*ØwÁ`œF·P¿qöÚÊ?ËÎ©ÊÁ]©2o†‚ÁfO÷©¥öG«’Ó[gEó¢Êu¦dmÚzbİ^,_oéœaÛ\BDTçb¾$Nàø5ö~ÂÂ³š¨ß
5Ä½|—©à^u,‹ªõ>*N7©şæè‰ê£>¾0˜ŠIïÍqì´ö$ç£6Ş¿Ggª*Ü+"üoh<×ï]vAN¤»',GC¸¸`®lïù‹Ô7î©2¬–¿zŸ
Õºz7Û´¦‰-éq±^*µ)´(ç_Ó±€]”È‹Õhà+£Bä‰+”R|ô¹ 
ˆ2çl@@F^èIê19†¼'Ä}º’ ¡‹ôU•:¢À˜õ½™¬íÅïÖ!n¡”‚~P0¸J/µ²Ùvúhé„3½AR«²"ºÈÂ
G×†"ônn¥­„ØEa¡ñà‡+Ò±/K{·ì—1kñ`ê¢2~hÁ¿ù§Xõ8?$}ğvÂš§ÕRö™¦ù?‹«ŞŸmûëÿ&«ŸÁÔ™_ŒL–V4±R?¤%&
½^[=ã…«+dScRe`é <ÛLÁéZCÁà]ybi¯¡‚¢º;òÀqV(U.üXÉÀ J•‚ª—Tæ¬Á³è˜İEš×G/Bİ¬]Õ1d|›¸¶¼D¶É Ê‘‚1Q‰YAEBY÷^Kç)¯¬8MŞclşõ³w£rüÚ^JË§±Í¢`êI[C¼Xt¸Ä<ŸM!DèjßQ¿qè÷æ5¨C-òƒ4ñnÒÈ÷’OrçÉBóˆ•?4Ë5œêè¨)¨÷¹İd3»ÛF§pß›ŒÇì½~¡IMU]^£“œ÷“Åâ;Š¼XÂ²Éç¹YJ‹CìÊ£±mÖƒ2~µÓs|šò@B™#)±“¬s‘M‰—\=#0Ÿ-ÔáºçÕ@ƒ{Ú2Ğ9d´P3üËsÚß;tVy(å(N½¶Ç¦”}É-æ6ôµãÑùìåŞ?Öu E‘2ÚSÛ˜^~şÑ4:L”„qµIĞƒ¾™ïXx&™Óœü>qNæfQ6y_U¬èÊCT
=“
ãzÙBÈ«<äú*ÁÛ‹ &}kyh¹î\§ÍsÖ{5}åê)Í%Î ÂnX¥Gµ,_r^ë:1¡h#Û^Ok¯V°‚–@0[¥•9á`-c+k£ ²‹ƒL¹Îh\Æ—7—]{«ÕÆcÀ`°—Í²÷âã6Õã!Tçí·jÛ”¹”qà¿–Å’ÀÔ£Çml*··¥‹‚Vf4 °l[‡’ÍÅ…‚ÍÕæÈ‹ïúÛ-è­Ğ7Ó³É%åXuÚ÷2ÊÒ~4ğÅâãÄİìÆºÃcËÂ@¥JC]©yÙ­É	é©EH;¡ĞÃ8kr«€°—z­Åx›«VÉ7Iİ*¥#?Ù)åÎñyi	á{§şÚ&ŠîPèLS ¬Ğ¶ØŞõÑİ"‹Ôx
:¸?jÜ=‹í¯øs6ã©ˆ¬mŒ¨<,:ŞBXİÄ¥ë4&ûÙ9í>°s‘-Eœ"ƒVÙ:Í–²&7TSI;ƒví:h0&tÕÃI^håò†ŸjS# FeÚó’§ÁÚò$ÎVXí¹ÍšuÛfY `N—"2	G.µb¸ÛQx(7”´åû#(ÊË#¦,P3Da±jĞ¿s:óôÌ¯ğt)Óş]ùónæıüvÔ…â^¿áeMXÌi4©L:~RaÀøú.š@Jö˜$? éşHxgGg&Z:ö%üñO7š®Ü}œüR¹lòÅÖE©bc±ùyO‹hÄ=õ-¤fC´åaşÏÜà~At]•>$i-Ò,Sà $è†êI»†•Ãp»ÏŸª(C‘ïxGÁ~Ç ¡ä*FÎD?ÎNy×ÿ¥B£dãç(M)AV×X?zKS¾“f]T¢#âä
®Øò&µ(…hrÌkU– $wu÷ƒg|*Ê£d"x#øˆæø­Ì¬‡jªË“öiöÿ‘;dìãÂ°w@§µ.Ú€fâ,{Q±'ıære¢Â®â¦E×I…ÈT›ÃĞ/Á©^ã„xÃW+NˆÙ”2‡…ñÀ'°bUÃrªlSúiˆ~ß
ÑnIòA`—jÚø6SÀı{_¾œj Eµ€˜ÕÄ0)ˆík:µÙÔıFâxY¶Æ3ZÚÎÜ‚ª„|œ²–,İ>fTèËs«^f’bL—ˆ6óıàK‚í‰ı;ÃıÁ¾Bti8W÷?…†wzS¬ó½ZÛGLü)¸3ú³Î†'ùWİèˆ7ë(™ê°¥úz[_à”5x ÂÑ ûJêZØIâÈzÙJÜF-¦xù¡†¨¤™Éï6ûršz™}sò
¾»2Ğ.İÖÌ&a•Ê8›*GÀQŞÛ¾X¾N\xZ\âä˜ĞÿĞÀê±”Ç^½ü G,‘¢ú*ŞÍ•d«2x¸:òÌÃ‡¡Ã´‹¾jÃ…$ß,ø'åµÊÒ{–[¸¶*c¦ÖÀÿ¦Ëwª,ºÓ;êúé"s"üN|9)J¥†frèøhˆD¶÷<ƒ
X®1€ò7£ÁÙß~IsC;d;È LD+üåq~»ç,A€ZM#ÖŠ¹ ¹}„«™çÌ—Î9*¯ÀPF¬HÆÀ¼õÊ©khµ:jëYwªëî²­_÷T½(7¼ÆGnlg[¨^¤1·
M¤HÂ Ìªvœ&_…šı¥EnÂâz™W9H3|qûA)Ï±lÈª°ü‡ü56ÑS’#,Çfw³Ç¢"j¹U\ó
Ù1j~‰„m
Ş‹ £¨m‡%1m…PêĞã‚Ş&'™ˆë”b2éßÄË+’7Kn¶BsÆ~"ÉyX&/dšn.¬€øûÆåëuhºáìquq„æª¸o ò1AÂ÷äi33ùÖñÄiÿ 'l{ƒ¢S6Ó>‰2^…tb' sĞ+&íuAÈßÑYDEy¶Ë]X["Úã 6÷
ğ1Uá”øŞ53XexE$k`Zi°‘Ü³ã™õ\¤³Ôæğ$ò¤úäî2°œZ(ÃH[|_êš1ú}Î›ë<+Ö=Dmìµ0f	ĞLdpªÔö¬•Ú^ß7»øR±PLİ®ÅĞg÷Ÿï‘¿O³ØO€öZ\E¨¨ôö~™¯ƒ³ ê?»×“$®DP¤hG¾ß41Œt™FÂÍŒ!àøëu¡|–x³b·­˜ÀÅù¿q•NŠàæhâ¢ŠtSÀ0O<whÛšÚÏÂâ5ŒÙ™i–2B6¸E8ÆQñÚç™!~ŠxC‹:i#'HAìÒƒ0/kS=§íÁ,vc¢{‡ò ƒX*ÂÜ}—éB»!é¸VÖ2ĞŞ.êDşÌ/±nÂ|®zMu±(¼ÚÑ¡4'·ùé0“ºZ0uµ¢"ÜBëâYTº,lDß·ˆ”³b¨èŸ¿˜_i!o¹? 4*CÛãàô¢ÙW4»øóÃÑ|®M˜Rñ;§Åœêfmï7tbÛØíBe/×ºN¾ËÎõnEœ¡çæ`Ì;ÁnÂ^µCÆ£@ÆÊ7T'|²©¡S…>âšnNoÓEL­áè¿®6I^ì-‰øç”Û‡p,·hW‘øÏ®ÁÒïÜ¿¯Âê’\lw+Ç•ê’÷ˆOâ“ ¸™6í]¼øò=ÚÙ«¹P^áãï¯ku<ì_$K["Ç,}t`)$ßÀü`‹g]#èQŒÑ‹‚³ÖM}`(Ú&{ÇÆZjJ©B„|@m•(1Lë Â9Ãğ<¥>Z ñkÏyT’¨öi~#SÿÍ~	«ÓÊäa«¯)?¡>‚Ï—úPxW{âš‚©£ŠÍ=¾GÃÄ­šfîÊï:JXÄ¡ÿ=(šÔ¢;Yú@Æ¢‹HÊô…;Ò•ùYyï•8 ÔIè4÷Hs õaKv¢yç' Ÿ <
Ã˜Èjö¨JŞ‚bî•”öên’rMŒªu•È”¸¾Î5,"Ø—ws0à·¬í_i»”	úfüÀ­örø%¢SŞmÿë,h¾©ØO'}~ú=Ÿ7€@ÌªâÑÓ)‚¥R‘«Y´Ñ€gÍû¥6õñˆ_qòÏ¼¥¼[+>pİpÕ·ÙÆ¹ÖZ;Å ù×Ô5«ù]Ô1Ã­¥…±ŒL½H'ª_T(xn—15üß~èËÊïE=İgºè`W£C/¸æ.EpªÑA1w¿v†Üğ¯5¡béši–xÎ‡ğ¨ï®¿–|ŒzòÑ-Å9^…¢$˜ŸÓv[œåÂ“FÖÄFa~Ç$ ‰Ùû¯ º÷	œ˜­R5@€šú­ÅÆÛÒ‘Ïı«\wuaòŠ;=»,HÊEgL=ÖGÓĞ,$ß«CW'jJ"é·¢|šÙ'şùŸãWÅ´Ïà³¡Ú1ÂæœÔQ†»8övÙÙ¦{×ìîM\¼™£LzØëÏ¥É¸˜oË{éJW­üÀ*Ê²IÉ‡Äà°‰‘{Åª*À´îËg6¬.làGï·µ¸zœqªûO×WGgÜ<C+˜
Î[­v$Ç5“å›;÷¾]P×´û›ZÙu0Ã¨ú+uğhÙC …‰À;"”©ŠêØ$ªøÄ!Ìàå¨Y¾y^HÍeq´hG-I%Í	ñzìÌîçêoZegøN·y<'ú}Nœk_‡´$—¹]Xƒ1‚Á}ê”ğ«²+Í %Æw)Ëå3_|QòOË°{Aé0Üç,­ğöõ{ü›R¸Œ!gšm¸å2°ÜéÓµİ5e³Hå…Œ4ø¤\Ÿ%¥Õ"+w#ø6Æ¨…m.Qdè|*m¬Z%RX8¨…mCTÎBº_dL!¹ÿùŞ¶-Aø¾»’ÁÃ™©ËäbúÜ’oúuóNƒL<¶»šÔ¯×P!øè¤úd…£’›c¨‘}A÷•?×â*´]sJ…K2­Ùº™RK/ÿ"EUK_i5ÊßğHz”mÃM#}‘¢ê	€¹^?¦Ìy3 öÔÀ#•+³¨tòù”_~‡9¾ÿ½¢¶ ø:e y¡`K*1r,=’
»ìKOp0Sã'ëYg@Ãdâ¶ï5wBNt±‰±:P¥k}ë»ñå‚?ôÚU¸x\DB¤¬úq«TRUœúÃc)EÁ-›œ8 ‚ÿf;óÚl’:ÉŠ$…“}¥¿M8ø®3'Pxkùj8ä‹öü/TtìAO¿ìPÜ´'ª–˜i½†,­¬    :~xÉÉ˜P –¹€Àîuª±Ägû    YZ