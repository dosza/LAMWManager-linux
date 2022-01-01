#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="618544940"
MD5="be576f100478d40aa52d35025b276be6"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26020"
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
	echo Uncompressed size: 192 KB
	echo Compression: xz
	echo Date of packaging: Fri Dec 31 22:24:58 -03 2021
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
	echo OLDUSIZE=192
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
	MS_Printf "About to extract 192 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 192; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (192 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌâÿec] ¼}•À1Dd]‡Á›PætİDõ#ãìI„Èa)H›ûïA,—VÛŒn¥®=ï ƒ&ıX8´µ$ŞI¥œ*«›TíNÍ×uáX]£Ä6¡b2)Ô´Lâä©ÂÄ€Qı…6q0c|rÙÍOéŒIÂäÁAÖo…!T5ªì›ÜÒµ¢È"F¤Ë^/	ºĞÈÓéçÙ$o~L“Îsmî’Õã¦ÏŒV•ëÎ2‘œQM|´c@5¿xHM³*~ÛÑÇssª¨G¡·’âÌJ5tÛÛTYiÜOu=ˆsòœÄc{¼D5)AU^
4©ºm¨Qãcïİ Ÿ‰í]U>†'¹[çIWm÷‚N±2æŠÍ3³À3DéTd…ïbgxÕ­e
…7!İEîæ#Š5èOSH•¦œ’ßİÊ‘cûÅpÓù7ÈÅéc<LÑ‡À‰ˆÒãi‰'èw.š$OşšT.”qÊ©şŞªK-ßSc“²!ó(#ª%n¯‚%‰`˜d„L±(÷Nû£“z…Ì—Æ1zÈ ËHd†Á`1ìnğnÇWs9éı¦jŒÜ?}ãKbvÕÈ÷DR~©B{ Í(}‰‚SH6œÉÛ¥ÀA“H=×Û˜Çr#®ßÎiÓ\÷èÅ™Œy×Ë_u°ñŞJWî£åP•ÃƒŞLÃÃãµ9¶ï-P(ÔÎéA÷a/f“Hò6Á&/]x´Õ(Kã2?DËU¿¸hİßóÚšOtm©›sû/¥(®î¶œ²w¶gLæË©˜MJŞã«ı&4œ²Q®NÁdìQ\‘ígª×õa7ƒ}(˜#=?õqÃDde Ò§üâO³²"úÌĞ'»G€øáÎ€|‚chóaeÙàYÀİ=™WìYSÏ]"¬¼|Oİ€I7¤?ûY|õNršœÂÃá¸^‹º¼I¼8Ì$M(§±îEV'áÒsl+ı{¸ÆåQ¦¼%^6R,Dü…«®q,El/Q“ùFµ€X3AVj>XRH>zUï€/e˜ÆÅ³O©¡MP8w;±§=™ğÃÁJ
!o´i}ÕØHyÀ	ÊZ\|_Ø^@_™öï/ÙvSàÖ£xƒn®@0òböİûä{­kÔ!OA‘yşdÌŸA™¥dØû£·hï¸ Cêã„(3ÑvÏ­ÚhÛíÖÒ'İ$a°À¿?$÷ß×Ê%’rµ›Æ	ÿ©=á9Wû»a{y·¢[Ô|u“ü\ñ²¯ Õb[J6FO—FÚëŸ0YòÔî“ïWkÌ^ŸK`jZ¸U,âİ²C· ÷ n;hxQY­³şğ+…ŠËÃ´é9Œï/È¡¯Ìá]ä©¢®S%ÿutTn“Ÿç²ó¨€8ïˆ-8ÅªHÏ"²]ä¨	vC¯µVíG»ÌÅ±•T]%¼:@½RŠ_t&¾±ä]?I|cş}1S,§;ovŒ£‘'ÔË=S”+X‹¶/Z7ó ì¶ ËS¾)"ñ—SÄ«e¼frFIÃ¹±	<‹Là7‘”aP`¡ïX«¬D"êêS˜µş³$Ø¿>XëEœbCŸw§íšÁä;²q‚³}MiÎ5Ç’±äÉö–Pf*”ÄİÒoGsOD>ë ã{86éWÚ3q3 7Íî9ôÉÊ	ë ,£ú]¿ÓØMG3 šÃ~EÊöãq]çÍØ²vØ%€=KSK±ÓÀ¥²ù‰í¨e2ÿÎp”lsmÂA9Äô£–¢LIİú$·©WNJWËünğ´’ÿ¡.N x¦¢w-œÎV7v2}ÜrèËa¶:O«U[[K²äçfƒ¦‰ŞkB*ó¢¿Ó’/b/k‡Ã¥MŒ8XS­GytC	3@©ì”n2<êš.Ô…ÿıT	{ö©°šÔ|Â¼M«­\atQ·IÊ”O–û`.„áY,ä8°´`ùÄèi"ñ‘P¹ÄßXÏùqÕÌFA¾ÿêmxŒ‘ª—NhĞ%ˆı~óG#Î­¢Õs¡Qe±“¬&ˆ›ˆ+s™$‹³ÿk&	jt—5*OÔ:láéœ0ØÃ}²=pµÎ9SœH¢İ9­ûÖ¬èZ¬2‘€ÇÎÖgÍó¥o»[²ĞËB„“Ñ¿ª‰ñSŠ†Z`1Ér¶s½à—Ê‚º ´Ï6jl‰ú—Ó‹ŸKiÇãÂÒA‰*‚×5M>ë†ÆìbŞbà¼ª³;Z5ÙŠ1Ÿ×¹=o83ï,Ê›S¥\å/6ÑCÑ½÷õ0ä4(K¼\â
–.ŠtmÂ¿‹®+$û›ËÍèf5O™£o§"Åçg9Í0Ê2z³Û#hµXö¶CÒÓår½öĞfHì1¨ïÇÂÊ0¤½˜b¨Ü]]‹Bt¹±¢îq¨X`kWC ¸ -yªC[=Äk{ˆ7x…xRæÌ§Œ~ ¥°=$¹=ÒÔKaTC‘‚Ræ’fº·'x¸¢l÷Û–º.LCÅi+ªFÿ—í)üšÍ´¿>˜µ©Ç`Œ!œ¤Vi=wÑ ?lp1S°ğ‘‰êOÇap-‡ÿİZ'®¸=‘×ŠfÆ0L5Èbê·aàùÁîk¿Ù:®%Æ…?õÏU—0·ïÛhGİP¾œY< zŒaòÚ”6§F¬ˆ/ª× |ş ½MÓ¹>ÊìğÜ´	W	úeò–Wm!Œ7ÒF’š	¾áÒ‰¯= Œt‰æÄ½5¹^-»ì^9¤Øùx%)Ô<÷o¨=³–(«&¢°Í‰ÂÁ>Ó:5İåÖÆÌ–u*çäw{Ëo
¹Ï^&Êœk5Q[‰‚7YşxJÈJ´ÍI¾Éõ"EñTK×Ómƒ¥Ôä|›[?R¼ ?ÕÓ‘Ø3ıŞSğ „Õk¶–ÓGËÁJë÷©(…qÚÿ­1G£_ò¶ÓëSÊòQK)]ÄF	£†Ü„(ĞR¯	<Z<¾â2%º°×E²—İÖ¾´ª &ª¼¨mÖC°ûd}P[Ç¾ğ¿›£”ŞŒØ›U5º;pt¡f÷£Ş¨+îÓyÂM¨%Yaõ »÷¥?‹%¾B¢d0K4°Õ¾ h–gÿ‹>û5İAXp«Ï°iÙª{û–€O¾
Ù—4ÈiMßRª&Ë½½}Qo'?ıXY£@#›z+Ë¬è	E(¯íwtüwÙ¼Òvå1|å/Í)„e]¸ÊÒ-PwL>‘¼î?Ğü¥}G p¨¹+È• ë-ñåúœ#¤-g¬ˆÊ@MˆI	Û|M6™<íd®Zã&Û]:]øáĞÉ`/3Èb¦O·’ˆ½ˆÖšú[ˆÓÂi¶#Ç“-%5Š/ìı½€‚/ü?ııˆw…ñDµã”ŞÊsxÇÎ¬Êœhx—°1 Öm~<â,ïˆ3¿/·ÃæŞIšjúÍEÊÏf§šß&İÉ3Ú1$	=ƒƒ¯k‡ŞDê—½3$[Oÿ§p\b'#§ŸC@;€–÷;¾j5ÌÍöM8º‡M*ş7‘j Ädi 6kÌïw3­xÈH÷é@°Âåö÷vĞôOG~X2h¦9t
ÓNÍ7¤OşÑ—Mâ¯Œjğ% ¸ï¶pã‘G©süCêŒF‘,“¹áÂ”è+{‚¾â€Ïã&½ª¶ı±
«€íÅûe,ÿ"KV˜Kè­0]Á®ß!`¤a—+êoµRÈzBG\*B1%Dîì>„wíóïè›)oô‰+ÈÔZ]–¹}Í—TÔàò_åC¨=èH­˜òiŞ¹eóöitdœ¯–Ã_{.ıÜ	2´8&²Rxf5{ß"‚=nïmEabÜŞ£¡Àõj‘˜ LP$v,»t#àüúsŞ/!uWÔüÁ
ÓyCº oâNóG^àWTH…Ô0y)×Öšk½Q–DR¬ø¡dªäÓ#$C0Ûí´¸ZAíûnõ6‡&ˆvÕ:ş`E7»˜v³vH_Óãÿgí%_I¶xÈl‰•‹p	Aî¶`ˆõQPÖíF©ñ.µ9ïïmTu­(Ÿ«[úòÁb|ïO¥_]ËgÊ¥†¼fí¥¬(4eY2h XF‹“â[æ–ø˜LšK†…{ ’ÀÃ¦ÁÒÄÕQT[=ş®Ğ,h:p†Êr$Ø/""ÎåŒ0Ÿ	¼Íj<³Ä’—ı	¥ÎíÈöç‚íB!ÂJr™+“íSdÇnŠöPQıO§¤Ğ”yØcŒßVÎÔŒ¸&‘U9òBÌÜ÷Ö÷™UyÓş`­Õ½À…‡úú¿‚›MJ¿bµ±FDo7G„i_1zDYh$ê÷ê¼°éŸ½çş Ï;˜¯E_¨İ¤~nÂp3ú^“—&‘Ø=náìû¶3|ÒÌ¤Û“H½ÏV6UµÂÛøA/K¦ùË&ÁÂ
©ÜsXkÔ¦HFT7ƒˆò{—ÍèêLâ²"]²Šº¹©"^[mB¨?î€–ÄCËÉXODñÅé™EVü)çé)¿¾ö¼yÆø]M¸ÈBI‰¦N °È,L–ñú÷„ş%Ğø”å³ñú~ƒŞ2ı‰áÒšëBaéØƒàá|w~8Z=€"É15ÿ€ç_4=90oèÆÆdÊöxÆ„cöV¼ «8kÔ®éŠ7®:¸±+¦(Ãû8'o’óí)~=òQ~7¡¯Ø1>&ĞÕ1V³[¾ããùã´S"vu¥&ÔNªÆ˜Ÿiq†ìëÚKŸn´k±Ä|?ÚÁÈâAÈ¼½(òR°Û§æ»¼©›¸ §x‡>N[fUäƒºu7x\Ø7ŒšNœ€œ²ì;‚ÎVşEa?ô=@ºê7…\ sƒè—YuâRBQfóäÔÆ-ùôOû|–
®7e<W$şgÓ|úyğÌ!Œ¾‚Ãh=n;ù@FJYp©cÛëé)è‡•À,8ÚË—„7ÿ_ÀB,I¯ì7ñ“^UeüzGEHù`›“#è=¤Ô¯Ç‚Ê şª:m›èSYğTê6Ñëşã{q}»påµò²ÖˆPèÑ˜¤ƒXv©-²ïo"¸¼wùK? ƒø+î“³Í¹¿ŞAö˜6Ğ¸’ƒK'LE0Ø‹UxLåzp7t(Û$\Lfa`DgÏH~åß3lÓ7³ÎŠ}¶š?ËÊ)up<Ã28üÙïjËrİ¾ş@má·9¹Ğ9º'ŒGlVòk`ñMG=ôÖ7*pÀtCEŞæ°÷DÌ…˜4TÃ2ˆFD´(müˆ°i½ö™‰déÄîe>o¨}-MİÕEÎF„aVÎ<òùg&–PŞ×ªôl¤m`Yél,V@+ƒxRXÛ‡%ÌkÃ#¢û†ûšÒI÷¢ÑXğÓ/dş¹›ÿßp l"*9œb¹Ó	)[Èƒ`š¢2œ¨™OPD	ï(½Hü_ººPôàÚÌ5&XßLÚØ)c¦ì¤ph¨¿ø£©oÍFŞreìà‰™ƒáƒ“P«"ø=(ñndî:µr5‚é„MöÇQgWjÄ÷Ìp²©Yg-M%¥GU>†Àÿü¦˜uRDê{C§ç­}îœ‡˜çÙî¾û;«àpGx†tw£Ü­Œ6à †°Ê©ÖñÉ÷ú´w·×5h>.ÆÀÊ^Á2Ãğ÷!ã×W×ÅYŠ	\î!C‹'<Cºæ[¹BXƒ):ûä°‹&§Sà‡t&ÏÚ* ÂuŒ/håQ™¡î˜ó‹;©‡[›*¼óšM­ƒ&®G‰¬ŞÖåaï×|~M)ä‚eº•%
÷Ã,ãùıäL>¼÷´Tˆâ‰£r­|â½QS‰UÁÊKÑ­í!"ôÛê¾ÈÒÒ_à„2†§~É·Rì—Cn¸õê cŒD²q<›åı?ÁÎÊ>×„Z!–¤So·“˜,4
‚Õi/>~YÙİØ6;Â½æ‚šjåà<‘HL¹Ûu=ÍÂ;áı‚U¸âæ#+Â%æ>tôLŸáJ€È63nÈÅÙ ÈlÉ–KL0W»c\°úi³²¬İó)B¬1toàT§>ˆ%ÅBâº!y2L®*ø¢Éâe¼A.ù¢½³4Ó-pd¸ˆv™à›÷Í[Ê;Ğ„¿ilzb,ÅÎ¨ÿ2°´z<„c9©]G£¼¢A¢G¤GsWNÆÚ.v˜‰Æ0ò¡(±OËÿÒÛ®»ášìÊõ³Æ*–‘æ‡µFËc9 /6ßò d[İ»ëU}BmÉU÷_‡–¥Ó„©m]BÅïãöì[tv·ÿ!Æ&®mæ)ô®8ZĞwv#[í2œHyQ‚·]Ã)ãˆó.g)PWû®bMü}'ˆ|· ¶báß€qr3²i¤ğmß¢ øÃ|
Õ`±ñ¶‰Oxë—àh?ôl%Æ²ª:®(B›3Lâ±,{íéôï‘¿×6eCŸ²=¹´d–0¥¦r,¹¾%ê­´¬vC‹FP\5$„‹;Â£øj7Œ‰Bâº‰	±¤j^ÙXñĞ8.ˆì<„]íÇÇ#¢xSrùúù¼7{‹ÚBÙÑ–~ğ³ºåwÑşºvŸII­ÌüQê&³õ@Äsı¨'1
²±ßÌå\³»ˆ5«öHC¨%„\‚ÎÚ³[çdß	$ƒ>¼E»S¦S»Ï,rÍU¢~UOô¨f5h<œÈ3pË{Íy§¢Ïuœ#µRCº?C,ºö^ê8í¦ĞEßñ6*Òh÷ûµ
–i@:"]aZ)ƒqÎòÂ‚ä*Pe~I€AÜêxàı,¦¸kòõ˜ì[B’pVB2zË¥zà€LF¶FrPÆä%Ÿ­…¡sh³–ßâPƒ©ªåãôÿÎ€-{ŞªJGğ8¤si³Ô$É~Å›mşÎ¶û‰w¥Ö%Áêó:Záí?õ<€{ñg	£I›ÊF½‚şÙ7>nÿ–¢	ã]©Mİ¨»¬ÜŒõ˜œƒm·¥6,M¬Ûù_mÉVÖm‚PF&Çeuùñ}ZªxZè•†şr·“Zª–CY{¸€%şÛIÿ)`ï_¯ë-‡ì8|¾Y€sRŞp7úãü®çÈ-ÊP8œ7ıÉRZ‰Š¼¶Ì-õ/{WÆiÁÁµ”	ìşcë½³CÚb‡°£oq¡–ÖÅª…u³«Ü÷"ÁècáHeDXÑ¯ô}è ¾jq´íŒË…Â±Ì‡¤–km˜j¼Ùzíoô»
²p@CNø¶Óÿ¯;ï~<È¨İ"l„š?'
“•m!W¤N9q_öÆ…ò
ËBX—GX¤LÄnã#âÖœİIæÊíz?<œÛ	l1#3˜Û# "›<H¨rg{§(ŠXI%®¯¦ÛÆ±J•±¶úµÔxÒ«|~í;«ˆ—ñÊX'ëKš€|f=ÖÏ…!hÔuÆ`ü„¬ŒEjduj[èö©øU‰ˆ‹kƒéßè5¤â¹Î=á3.x9›Y1É*„İŠôın_ôØ]áªüä`j÷´¶1k×>Ö/ø€'ui|»)Ì4L}Æc…Eæş‡£y²_ºà²ü¾>SÇ/Ì1*®ûíSo;g–z¥•9P—nkOCÃyxõµ-¨MÄëÛò21ï¤å"õ‹Òî{—y{oİ(t^ë÷…ÉòØ½õk#¿˜âÕÚÂDš]ZcÈCK÷}’ù95S‡·_ïwÛ­1L¾P8}Ü» ¿'9—›˜\•£_,ifCïZT<¨å
ÂÏÂ—Ã•âQ­ï
º‡åA\@è1¢sØazFğ‹²Ì´aD ‰¾½ŸìÑè)*%İ»üÊº…ËØ1*‹æ?I'mÒ¬HRg ²Ùo®<£¼xv­Pş«OhVÂR]¥«hÆ-—laş££A’Oá«¡Tä^Xz¢p¼°PÕwDÑ
%Í©U¦R¢ú§Ûkk(–«hr
Ñ“L%5hİÄêZÑAÙ•LD²²Áè`^ı¸_.Ùèİ»ê}£nmËÆOúr|B·Öş"h ‰Ğä²/a:şàÂ=º´ËK}dl®ˆYM8àe’xM)·,ğ3)š°5˜à÷K0İéßÈgWÙLçr2ÌO‚ÊîÀTmïøìñ ‰¬w–!ª²¢´0N+ÖÃÙaá¨ªá¿”âf0s©ÄÿºàR|×¶ÎJjS,æ!ûÇÏƒx$feŒ!ÁËåk lâ1P­§ÎÙæ?‰BW•ëÂÛçR
æ=„ä¡÷Üü…vWßòD¼¸gv9oní0û8åËhuB„[K§î®FsUË14j¯Ÿß³ ²“Eä¾
cª„ƒöø?¯Î½õxYq=åuè|êÖÿ’ëRµóíƒòúAX†ìĞªEs~)¥KRHqÊJ}TrW£±P8MB¤­µd‹c{óøò!ÿ@OGŸÜÓÁŠO,îY%™A¶Á=2¦züÓéqa€JªòôÆÿÆŸ'y¤°¯÷ÁOƒ	äÎ¿Ox	òçz[k/#ëğÅŞá3ï‰¥İwF¤“K]Ä½ùYe!ò¥µvkèâpSõ^ £DE5ò4bM@Ÿíu¢‡ÖƒÌ‡)‚÷Üú?&+Ó®¨3Ş+¼»ÒáÌâ{<7Ë
9‚rÈ4Ëøn`ÿ†5êU-¿œµ¿ªQëoO8âSä
ä1ä‰ycÉB¬jM×²ˆ$rá>%ä½ú5Â½^–—¼ø‘óšºÑJN'€w-ŠoMªàÂåëeŞìxèäU4Í|šŞŸ¹ÑÅĞQÆåqoÛËHĞó™uÃx&üìr„ô/c¢ÃÜ¸Ì×± ¢àµûÇÔváÑe™;ÆÆ&.YB,´‰$[ñ™Œ£IÌkÙ@†CÀğÚº!HYéÑó½å"´c‡İh[T3® £y´Åå"ŒŞzb/æHØ 9±›³€¬ßÄÌÅ³t+[£3’û’!—‡­Q;Lßù.¦W÷Ã	çI¤Ì¶¦†­÷ñ\TëLøR~DÈ ô­‡«ìĞ¶‘àğáœl]Ôi«İ9
Cdì"iû=W÷ŒÌå¿@`ø[Ğš»Gö½YN¾’™¡'…Ro¦ÏÓÃUÔ‹¾àíìÔ’È%]0åôÒgŞ&‰Û‚«V¡n7çÃ…aN^Îú+D¢Ş?™Ûÿë·ÓGPV“ëúqäùP'¤eqŠ7ã ß@Å|êç ^¼D!×H|.|	’	NÔ—ªÔ«¯ÔÜ8»d¨yš?ØšÀ1 ˜MA«¾!Í{+™$Î*ıcµì}ãûæ’6°ÊÑNÆÑfƒP½R_'*Õ/QAUÛCĞ5åË›+[Nèñ	ìDÃ5Ô›¶3]àP¹¥aM@ªÛy‰qxÙ%ìaä[,ó®¡3”c5)ÄÅ¤§È×NH•M\[g
¢ÓG¬ÉŠCw’v :í¹&ÿ8ÇRûA6Z9ëàÉ¼NØ²‹ùÂèÂÂqP7—$m¡e-¯3PÈ­„™;*äØ3~O pó$ˆöîfå¸šÎ\^2'¨RÒ3GTDypĞ{mäŒ0d’U_[Y-&üEz5Í„ƒˆ {é2‹ìƒAƒ#óœ	GK?§‘h$\m¯ihËæD[Â®¦	‰PÒ©çÁ;¾"CµEË@µ—Ï¹$ŒxÄŒş[èù»¨¶°{1@ø·×S©&´‘r9İ=¾œš\}¸º’¡.‚œã¡.LÀ‡ëxItM<Ã00º‘>ló?36Ô.êl-a’ã¬4ûrZÛk«*ÙÜë€€ 8=|MêŒ?m5/$ÁºO§ú-Hè¿4â(	¹J9‘¡ÆÀtF¤@"ëbI’\„»(±]9†éôFUóÑî«íÑXZ‚i¶+6…ÁJ€ú%vÁYãÖâ‚']AÇ% ;ññ¢ÏB[æ…ÈÆ=‰ªìĞTñ/¹E°¡kñUÓÔ•ÄtÿîĞq°*A²ãˆê¹Gö¸ÂµOxÅ.iÆ0ŸI¨ĞDI7 ^ÿêFÂ‹T„"•¯	:‡µ{MİÁw8ÕoÖÓŒÍf³*ic
”(9ø<Ø0£g¸:¹óä:o‹Á‰Â’õ21òb[&M´¾ş½D›ù1H-Ñòs¿ÏğİF Ö‚;>‹¼ÒbùQn›Ü÷Ò×tsÔûy`6iØKÉ²´²¾‘@dé×½ÔÜÃ‚Çó„EzaôœcuWtu]*Ÿ‰^/Ï±µjÎá®W©¤AT×v9&vV(Ç6?,Ÿp †Ñ°æ)©ø±±£ä”Ñ«Ø,caÔá$ü¯Š€Kq¢ëØ×+^b·´å`ëYEkÉÁN;éb:;›a•ZO¶4Öäms8¹lEZmæ*:üÄëmÅYâKLêi^ŠÿÖ]çı0{¥ğeŞ2¡‹ÅLİumJQ|Å§ëŞBbf%@Í–übşçŞmY—}ôİm)ø’¨t¶ñ&>b]5'#µ¡ğÚÊ†qUI&öxŒ*¶û×mo>¢i¼Õ·ÎÇ­æ¨)›ÚOş[š?¾îİÿ®A¶»+“‰jæĞ¶t5WfÚóø,r…oøºo‘H{(}Êƒ§qıæÂ¥è^$6z4›iì_Eß§’
ëò¤¶çz §-×©<ÌÚoûPˆ6hÂ…må|¸Ú÷—âpÍìO`bı¼Šad²çK‹ÿ°6“)÷²ã»E™ê±Ü(5ê6ió¨±ü€é,ÇQEêÇî,œš¶54q`L…È¶/$B¬F‰ymnF$h>@BFié3£h£”8ødìÅyrûåk•3#m7…Ä3/™ÜæoŸ÷“«TfSWy¢İşL¾{ihĞ¼‡ü¿iB{š’]ÿ]èwMí"ÀÎ†’VíG½8>»ƒ¼‡9TóÃÇBh OÔ:Ú¡S&…şv™Õ¾÷B†Îé¤‡@)qnŒçÀúJqÌıd-€÷‹‚Xlï=ïª×3–Jhw²Ü¶úádgÑ„¬+_Ï¼
Ç5óÀ ™\ƒ·‡ı5¤õ:O7u-XãQÒà.á8šsVÇ¯„œDç»³¡©Ş¥1±'ûFB½WIJ”M÷ÿøƒcw$ğó›¨Ñ ëÔp!¹Ù”EƒœSÈtP1	"ËïÒ³¤ŸßfºE[fDÜ¸*’’vœÅ8-Hr™
4÷‚7Y¨™7Ú#t„ÖùŸl#Ë@õx],¾RvVÈ˜¨ÚH‚Ğ	Çk»’ÈhQÿA¤p^öW|ıl3ŠÃûÀ*ÄiM ı>] ƒÒ”F˜AÚj€As)?ÃVÛ%±	.?ÕñF„üÒøH ÕŞªfçŠ`ü†‰¬Xàí¸ÆÑY’×*Y¬ãF„´ş®ã¾Î
sƒÆ%6Ë¡_È>í°QŸyJÕ¦môÚO)¯kñ0È¯Ì‚¢r— pÔN¸¿şAV3ª*¶o±… ôPB±C‚‹‚ËJ4É¹7Ë†üåfVö,·½hò}QáÄçI?ÁĞÑ§’u˜eœï!†‹ıÔæPËMîÍ6sbş 1Ï3İôüÓs¹ ¨ã «v¥ùN(Ró}Rñb4;Wò›â#!×ÈM4SnŒ)©s—(“ç¡Tª¼eÓD§Ï»‰ğKµ'ÙP¢åó€Vˆ”şH>À=ö˜I-‡Üõ	›¶kó)/>«zö=µı*°(Yhxèƒñõ7à±Ës26äbÅ9!óöŠ7ğsÃe–×±mÅæç‚©)¶ùn
)óóÛê¥sÌ·¯×aH¤8äZa;ı?÷øD¿ëÛMçXâ\ÖN_0¼HÒo´Ğ® H©MšüÁ.êA©*èå³òS¦ûÀ¿.Iãp1˜ÿ0,ª ,¸aƒw$ Ï £2Üİ Ø (0Â3ÖÁ¹`¥KJu)š¯„Äniú¤ÿÉ_ÓÕ(ÉÅ:†$ş÷_d%4r~ïéÍQ’Yù{¿İ`4k4™…qîl3³/öEe¨‡é©…ş«Ûs„îw×Bb`Ş&.å#±eÊÙ~$n!Hö€yt	ÇmÛ–x³ÍRó!Péı]ª´¯Ğmª'ò?Ï”gË£ÎÂ ­§¹YÃ*uağhÌ—@Ãï¤™ò[D­E V`:ï$Öt˜`Ç¡Ñ¢ñÄ<L#	ä; ååÓ*
ÊçŒawe.Ë*ùÇå»8mez“âöãc¼Ô>ül&iÚÌŸ
¿|bíu{fV\§"ù‡¦uËĞ‘ZFI–È°á,#`'Å÷œ}Ãdü9ıã9#ùÎĞ Ÿúr×~‚U£F”TäP£Ú82kiûöÍX­CY?çe‰vã Ş“bO˜WBÿÍ¡ÛL®š‡|Ù'Ì&=k®(ààL×uëŸøÿ_9º¥Êõ–ícE½3>;ˆ™H¾`±ÔXæ?±(Ï¤ò{ôÜ'H7ÈüÃÙ/åÖ¤õZ1´ê/1j+G3¸ñuïa÷o¨÷r&¦9Êê;åK57TŠS.¾¸¸â'#n;‹„¼°á‡Líáx}|ª^ÍOá¶THe•T<÷¤$Ô]Ÿã#\Á‰ïûÍ«ÈğšCgşß/¸²§+›nJÚ¤’ÁK@€‚¤ÿøí)™•&ÁˆØ¿Zî(ªµÈL¡÷ÿMÔÔÒC| c¸:µxŠĞPD*t }ğßÕpRÑÓÜx½L¬Y ,éÙa½½@m•'qÀc×G¿°¯E_¡Ü¹‹£
LSFÔ	¾‡G´¢/6ÜîW³ê°rÿî±’.ß°é,UÇ¿o˜È {${CR[BşÃV ·åÇ_°ÚÇĞke#Ÿ›¿ 	1|¦Â£]#¾|¼(ú”O¾c€+	ô§XmZ„:Ù•åéu;€ùg$Óìş(t6U¬l^!ØrRÅ—yÂ,É¥Ê³H’ÿbĞcÊrIDìds¥Må^¥w-«ªÆËª{¦<Ù 1]nÈæˆô	}R`ºgpD«v$vÿ•¬Rü®´ÈX}»şõúwT×ÁÎ­é,$YŞ}=^j˜m5íU1rõ¿^EfÁæzÉ‰Ã6Óv<PŸu÷(¹#iüş ÕÑf1¤İÏßt˜(ÃÖíœÑE½“ühZöûš	Ñ48)0hA³Òi«Ñ™¡lâF’Hâhı!VÚ6í~ØßnıTNü—\‘Ê'¨qtĞ5q`–{:ÀµvÍ5õk3T,İb(ºTÀëOöDZœXN5òbÂ4#søtlÔ)~ô‰S±+ÍÄŒ¼ÄÇğå9H-ä}HÏ‘|«ÿ/øòdªê	t%z˜)OèÈÚ4,g­J×£7}üÆ1Tüétß¯µ¢åa¨#šğfS×<Éß4ê½´îSÂÃ§­Î’¬¸™ìõµµW )Ü(a~\·õ3,Ì¢Z×ıçã1·õ$IB2ä.vÅp`õˆ¿Ö$Å»vD‚ıo&ı¡#âäTˆÆ7s §™RõÉ›n¯«8 Yéa`İvÑ\¸UÛ!ˆ˜Ò&÷¶}÷ÓcykS.^çd¶şíé!Qø‚ü§.¾Q´3˜¨Rôµ¾DÄåk`ßtw¥g6Šs|Z«b=CÿsÃÌ*ï‘DlcÈŒ:©ĞÜ	Á•`ÙV‰_®bÎ÷SÇ¥’,@,¥(¼y% şJÛXçq*Ek–V”Æ£¼sÌä.MØà„!ûÉp+|–Tè¾Ñ# a-g¸ğğq‘© 	1ğßUŞ}l"i,†Ï `à5àsáÕI@†à¦Ğ æÁ­bQï5˜ææ¼”]oN"Æİ\NÊİM[õH©}säM)QÖŠ˜‹µK UW¬è;
ß0µ'YN$ÂàÚü)¸Ìo\å0U;'f¡©­2¶õC%ßHğ*ÒË¡…‘ì˜‰P	ìögp3ÌiÜ²Ó'òÜË…üÙ2j!#ËîT…”xŠš.=éĞcÂæömN¼ôQ¤4UË/>]<Fz­>¾í4ìô~óÜ49ƒ©äbMRé3 ¸(ko°‡[„DJ%Ê^
q»DBã†İBïä1Ä¨Ü	EC·ï€ã{4áİµaÔƒûJÖÉõs†cä\NÍ1DBHwµäÜA¢äñ_{Q¢{§Xã¨˜ïiªÈÅ˜JöÖ+Àf”pªç õ'Ë:k6™çÅ>V.h+3ªS˜/üıEÊí%Ó`Î;QzG[%æ.KæØHJâ‡Á®jÙğĞæq²^lÏgš;7*¼
ÎVn>l¢ØÇÈÏöÂÄšêéu,Ö­}»ÄBÿøÙ˜ŒŞ:N‹ÖŠf•T£ªĞ‚Cğb? Ó4Cà:Pƒ=„LVïf˜n¤*,Eƒ!äHæ,¯œDÈ‘"7mÌ€5“YßDR;±Y1²ÌhŞâá!s%m¦Cê•»ÎN½¥ıÑÒƒ…š(/Q÷ê¢t>üL2íÿJ "|"ZeOF4+°S.4öõz;ÙÕ:IªE¹e´o
[ĞC¡ı\NÍ·‚—(tüYaëñ<Íò,Sï%­ËYkô©ë4U¢É¡G¡\j¸ğ^Ë+U¼PjğÕ4_]UÕùÇ:µ¬Û´NƒkŒ.ĞÎ¢…òº&ŠÓ´Úq´ÏZ€ÿä)†¯È~„E”Šè…ê›ü}oô7²Å\XãUG¬J[*æ[×ÌÔƒ
òéÙ\oÚø,/KMœîbîµÍŒ©{ötn²ehÌ‰Ï}¥š•ÔÔ¼FÜ„9³~´(°R¾Õÿ°à…ÑK¶Ç÷fH¿$š´•bƒØ+¥<tj)L´¢`ã—[ƒH	d¯;·rç-áRâ4cÏÏüO"ûeñ~àö?Ù{£«Íà›`‘ÖÅMA»Å,C˜ågX‡Œ^Xâ¸Æpaõ‘¶)2ÔÙ™©ÀlEÅNÃ¤Ş,2P K%ÅØ[ÚÂ‡éØÕÆ­s‚°úÄ©Í$´ô{?İHùu¨t:cZÃ7)â>kOØLt±Ô,oä.réÔËOR4#ºÔâ@‡ÜÂI8n.Sråëşõ‚jÈ­°ˆ Cë¹r<dğšÁ4ebX§Œî]Zï¸Ûû§˜Ø[v‚{£·Š÷÷^=¼ ı;¬éÎòËÅ1u­n‹)êbRUìŠtY³Ê·Úï*“%nE‚¶ı·ìt÷ËÏ~ê&rL2V,P­İµÙ)…çû,ó‰ˆqYRZwF«&ÿ¦§$ÕéYÙ11ë÷–ÌRØRÿ÷¥â)Hî'ŸÙ½ç¯p¹<ê¨bG3®Ô­‘rL„)ì/Í"ÔÕëÚ>^+¶s´°õŸM—h÷2õRıE«VÓÉø>î’£ LèÖ÷zJõ†ïµüj[J	5?79jf4 ¯s&JÛ
\“Åã0ßğ©EAE'£(—'·+ZV¨ î”¯®ñ¶zû†ZGŞİ{ÿsƒÑ(¬-{>4ŸM}ÖøÑQF´>Å%ıŒaç9ˆ4bİpœÒİ] =î¾&¾bJ©÷çÌ>KñòÚ	GqX´õF‘kC¨Zp¢t3T'R"gşeÕ'U'×í!‚	uV| ¸O•…i·€è\“NÊ{Û~»ÄAT\­IRÆÿ)¼¯uöÌ-@ñU–-’O3÷‰CóÂ·ÚIOyÚI;Yo"\Á½Ú”İ°>rd5350Ø¼*‚Ğsv®„gr'¬À3m³1šèÄ"ö-¡wi’¯8)ıˆM±òiRóÉÇşdæQ…th‘˜É¯Fè°PZ~
ÃF€’÷YK…UB}úí¦8"ùeç×c"FÛ»ÄZ:/z¼z½ßÁœ=dÆ5dı'O;\€-IÌNï³¹0š¦/ÉN	/+c2ÚJÀk%'"¨‹cfBi£xË–.ƒ~çxuíß“ªŠ2Ê'Y:  óœˆè€ú#ÙoÅ]Pæ‹Y&Åd§™/ÚŠ_Ò×¸1D¼$ş±[u~¾6Ç²H÷.ı‹ú±t)=3·°(k–˜?±‹1ûTñw.‚
Œ$úïYÜS>bÁÖë0ş/OàåÀ¯œjíh ñ§DÈÖGTµ]¡IÄ:ĞĞ*§q¹ëkıb%s&],÷Ã3Ö–ü ³^ zõ1ÂMWœ|Şİ|€¯—Fı¬¿’t EcÂ-°´Gœsó÷S=3äm“dÓøûÌ+r¿]^i5ft6U†Ä]’KÉZ~’3ÁÈšuÜ°CpR*¨„§Àxà°YÆvÈSPH“ÁÒ&S"?»Ğîàı1>8—ƒ^\ÕÉ!YrfS•2 :yiN°+Kì¶†ÈŒ­] {+¬`qsæDq‹¶JKcC_Ç¬U÷kB¤â›0VP=Æ°²‚µñİÆéTÜ¿±¡pÇÖ3¾YÖÜèaØëÌ¾?´ÜAı8öh&i`YÈiİ|ÓCâ¯½j¡v·Ë© r{{æ9ù­µ1)Jº9%¨gª°¶.zÄ¡Â¨ìï‡QŠºÄqm&Şt´¡n9\YòËåY÷ ú«-ãåŠã¿¿‹ "DVÓCŞås%'A¨-{¯Nñ¥’ÁïÄÕ°Óòîk†šps•N´iâ×Õtä,”J_ã…”ª
ôıÜqÅ°b;;wR 2+C{†ˆD½ú\@%¥,ş5<KgĞøtÂ‰V~ºû9^¢jhçTŞny>+0ïôÿ·|¸òÚLÜúÇ" ßPìµ"Ï—ÿgq[´÷¤S#¸µ€"±öDqÉ)by£G7ıø0U—9‘¥–Ç²Ò`TxG
#øtJŒ
ñUIª x£?’ñot"[ò‘À8:Dš¸‘9ğHàÑ0[Ç0z4e‹¢åàùªœQí>¥jß:æYDÑ7"ºşsZà$`¨’KÚß¥†úd,Ñß™8t¦v8ú%€¤9ö 6¤{Ì ùRÜë‰py¡ñ®gè*(«é/Æ:9g<ÉS•Ü{Şöô¢Cü$Œ,?Êú–ÔWF=X?
UN·¼È!.“$ÜPXõ…ñ¦ùTY½4¹ÂÏªTu:!FK09ú ~A»‹§=]Cl³)zmXÂï€ìªÙÜA]üGõO“r¯§÷–Ñ6ãÈZydìv8T¼â®µFöæx1÷ä ½/ã5şê«¯¨ˆ«¿Ì–¹r!æÛM.kÀªõÔe;‡R±¿q-P³ÒÿšŸšâò½™Hf9;TüƒG”QÎUw¶Ø69wîp-îŞ­%©#Çsİ;„(ò%¯Í¥É"Œh(‹Ù^­¼9S¡ÆÜ°BÊÌÉ5´µ%\q?İşC\Tr:‰à¹Ï`ğ‚ºĞh¥ã°ˆûVkBÛ@	5„“¤3ÓIÜ÷¥¾¶Fc}W1ğÎV²°=GÎCÈÀÍgİ—«†ÖÍşMdL™s“‡ïÄ$ÃVÈD£ËŞ<Í±ˆ(¶òıÃ
öîãÓ*¿è;ÁE˜@øwM·Îïz¿q×æ@yO´Ÿoä”\øq®İòúÀ'{æ›?®ÆCò_I2‹q|™;ífü‰}Ï9ïiîöóZ¨‘^òKìYªj ™ÓÑÙŞİrh­úšWtbD¦%­¶Isš<_0JîÖeTi9™wXPz	q·DÁ,„@ğv3ñtÆo¨-ûí,·mÈÍ¡0yàùl]"X=7Yœg»Š$ÌTÑ2¼\«¬ó6%Æµ‡úÙkKW©b
Ãí‘´Rˆ/¸,Mÿ÷§î€HÌÉAXÂ0DztVàÆLâ¥t¦}ˆÙ/¶o½g<’*²­›ZK!ƒ
ğLÜÌÎ†–_<ºèIp~2Ók®:>Ã"š!Ë.~q Ç¤] t²ÜÇ[¢ğFş÷æ>}<ÂÿïÏN£…‘OÓøİé_HRhbë›!.Â÷EV¹J9ÖlO*ÆRê‘Z9	"ıïbMêœAˆìÇ(¸ÃULñˆ¹×¶‹ê‹ˆœ‹b!v±’±Š
}çˆÓİ!Ü N´@ä<|R4Qï³È=ì;ÙÕÖ|nœ¢Pu6Ì~!ÿÂÎæHQÇ•yÿğ-»Öôgµ¢ëSØœm©N9+ûë‡R
÷O1A¶†©7Öb2ØuoŒì±TãOÇ ıØ¸)]z7ˆİ¾‰&m±ô“?HÿŞbÎ	^8ÄE 4¿IXŸ	;2:Ì7º&Qàü/ºÏ×l#Ÿ…ğhLK\^ûíË|Qn-›Jj)CSdç<bÉ»ûlŸ°:…Ïˆ¡CºÜQºV¦¡²k–’œA°[7Àp'Ÿ‚QÄäTŸ¼Å'â2Ô7¿[òz¢D=±‡F÷ÀŒÉ±JoÕ	^pQÁŞ«89/F"úâ¬à]*Ã;İk‹;;w•<%B3V_ª×´a²HÍi2dJm„–¥)Y³yÔ¯A¯ø¥å`Û>Öe	ˆÇ;…y9I¤4ó2ÇÎEéd7j¸?¦Ò~©á¬Ç§IÎ*§Å“gA¶š}\œûtÎùËØİÿØÉ³Ë* &1?¬é´ö¼6mËI8ÙâS’”WØGMÕàlºC°¨Gg9ƒ)Îuú“Ñœ_ägó&3D±ä¶Êä¬%­ËÇÎ“jc'cn¯±[¢#şŸXï>@ÖŠsúĞMßE‰º/}ö	]Ñä.	³ƒüÿ²±d½Šér“ùÿ?@×Ş­&p³ø±ë<‹úomb±jèPƒµ1)*jïû"Ép.Ø†÷²Bæ€1íX¿„5±	î,<á>{‡g¡ïT#©¶9%§‰`èŒëù7VR$-;ˆÇ}*ˆ¥˜&ô•-*®ƒ¢éíÄ?m¶vïlÇ`üúø~ÏŞkg½¥š‘!!¡±·öÛªåá)iw@¥‚@X	hAW×€(5IØXl\VF(:ã2çuù"v§Xçö‰;úŠ·ˆnÀHö=@†¤Ë½¹‡öÖ«*òºç?@d²6*9”Z6DN ¯-œk 'Ñò”îl•-°0‡põÀgDñ®®$,hÜÒ¨)¦¾"Ë ‰ÍV Yd}døÇgm>ıŒC38ÇKªV¶¦’]¶YO PXft[ûfm:_øx83ÑT&Ôuïâ•3´¾SíQßBüw®ºQÌÜcPÏê{Ÿ˜÷;ÓŞ3Î…@@W©éf\y‡/\æé1©Å­îÑbyíÄ[Áìf‡°¶$È†ÓÇ5c®9*(àÌ½UÅ0ä ñœ>üO- `88€Y¥+ù|‰q8^Øc1·êô©“^j‰ßÓ¦KÒ¬åWªM#Ö-Ndê‚´Z§¼oW¢Ê7â‘¢’"‘”a\JñSqˆ÷1f^¾öv34‚Õš	²¶©ú®”î¦7=2P~ŞF/±Ø ‡î˜ğpDşÀÈe}u—áÂŸ(VæAã
w’Sù)Ú¡³‰’vş!§aßƒEİ^,‰Oå›~É˜ƒ»¾/û´=kÚüìMqBÊH†ÁGåX…ğ8ûPùÆMlŸİ¨Î[b`‘â€r×	ƒøİC¦è0.*Çïg*5SxÆS[s²_ 9“¬wÁF”çn­}à‚*É’±Ô×¼i3ÿqÙÁ|Ÿ|+Ï! )_Xr(„aW®İğÌùôÍàĞ¢ı—ƒRèÒ˜ÚìÜWy›U»áéGREÂ¬Ñ˜ .køõfIß  ”Ôu…‹ÉNò°*äÀ†™'B–Ü6
Æ·×.RMXÎö…ÿÂ®UÎÙmrHÈ~kTmWpC©¸
Åğ+ÿÍ@kŞ~°QVwåâ±Å±¶MkYAîE~œ]÷·Tl0B™© oKdy;Àç…ƒæh–\÷k=âò”3À›İ7õ5:…¸5•Ó¸÷Ã|®* ­N
¬Í¡¢	4¹_;BnXœ+'Ø˜0G
÷Ütô¨¨ÎùAF!#G_É6úkÇ¾;Ÿú
|2=<,ê	Ê•^0uß ˆZ’c‚¤ë…1<ÿxêÏøÄŸ‹RĞ|x"òÛ¢‰yªÀf]'õ‰Â©Æ…«&ö‰q5âj!hèÿiE/c“ç"V?_.¯ÔãE!²uô6¨ş9n?¾î·tàÒUf]¾„W¢¥A¶?°›}ö5E®x%Vp *ĞĞÓH·À|ËXzââ*FbpÙøÒ|­l †"ÈÁõæ­›š¤l›¥Ò÷2Eæ†ÙC(
&4ŞƒˆÃYâĞ®=•¼™¦ê;’Ñ½[«‹³öo.©*.½³¼~EüJî³ÆuašÖ³UMÎ´dğ}¬V”P±|w‚[äè8}X
”ÌíÔùSÔ&£ŸVŞoÙKÄÿ´5!k~p5"ÏOËêß*àòKjcKpwq7{¸¯„ŠT‡ıÂ0c)üûª«^aÊ©õ 'ºn7…ôsJHÖ±%PN@?f¡'O²Ór€oDÓİÑÛ.â¥z«_¼y)¡½v[£^PÄ1±ú·¢Öİù\ä,9x<?Ä‹ŞŠğÎ´Ée<Ò­UÙ¢w›Ù¿óB¢ÛÆ³8Kó,=™%^´˜ÀçGõ‘QdÅgJßâŸÍp„ÿŒc„†|—ÓoÖ¸Ş^¿ÁÄÑç©š†rDÆĞH´B5L„’ÁÿÓòµ÷c–5*ŞŞº¨Ù³«;”½Dö³?¶øËÀu^73|~¢	ı´ª‚* ùí™wå6àÄyp¨rqQ¤¯ëeÏÓø§Ñ–ğ>¨W:øjÊâ\­÷i¿;u™Kà_7ï9ˆ1¤¸È>Ì¯h”Èf3/e}
[ŒN¶[&“±Eñ¤H(uú3Xä;À|mî"3İZìùñlaóÑÄégC¿ÿ¯ Ár£¿2bOL\fÕMf¦¬”¡Nã:aèÆÑ?	DÎ/#”Ò	ãP·©°ªTÈrg$g…XŒX¥ËtÃWø¯k•¾{Õtb%•F?ÏUÛÊËdfúXèSƒQëM~òeLT:µÉåÎüé
r†é$Ò™8ÔÁ0àÅuªUU2¯s²Ê.H(ƒá §i˜ŸÈ÷G‰¾^pÆèÍ2-ZœÁœÃ b²­ë¢äæQn*åŞœ­p.£o&àÀdÅ‘.ÑçÀ²’£TpÆ tAÒ›?¢¯G&‰ùzûŒîS®)2É“†ÙtS®Ás•†İæEbásF®{2‡<ÿÒÇÙ•a0ÛÍünfÉ¹&“›üÅ…;^´ğªæLZKo@ïì'?ûÇ®“òb'h¨³‹g@Ÿ?^)3›'4Ú˜I’w¯6
Ô·Á–ÿ^\êîCA7â“á‡Îy‹à>Ä\Ş­Êşš‰á‚]Ğ\ãÃn*IÅ\"ì ‡Í“Y.ÛÙC¬;½3ØÅËEMNÒÿh„æüÓ¬‘}:¹? Ÿ4×,q)øùğ
ğëÃE,Iİ{?x'øc6!ŠŒ<‰-]r‘{•ıƒ¯IPÅhP­Ù"¶O=Ò7s:…[m
…¼ÊLhÉ1gDßâ”s8–lİç¢!eéT€ö™‘ìmâRºRëáAnà&EìÅÙé‘ĞZTË«¬èkW©ë™üË¼Ó?µ Ä³Âw±OCÁøìI|¸şÌèeË/Ûn¿z…BÍlÃíp-Ó6q.
–g·ÑßÎ™Q)\xšñ[’J©1¾º´fƒ¨]ŞöR¡P»î%½ÿÀ–™.‡ÎğÛZ™\²kíî¹Ÿœ)eRÄt4³˜íŞ(àĞ*”Ö×Á¿^O;(aÅÍbóv!õkÇ’·:l<Æ"§Oõ„ëä
sDIx°ìh‚@_t!tÎä>ı‘ôa·ÑBáÖ‚QÆiœÖ:†MÎ>À”]fÜ“U£B<|èÃ`_,Ôà¼™…İ$HÕ£É:ÜKª(zä7Ó×+Vû™ˆmœ÷„#Úÿ…°Wü¢RÁÚ‘—‡|'²ºbx=×V.jè±´åRØ°‡@ÛòÊ¶y\w;=ğ†¬Îv“õ‘h›¢wç'µl ×@sÁ;v38² 1­HÙ×–SµêIÌøZåªk1µ*VÃœ²˜õŸSE-aµÛÛ"q¡zÀéW·¤ŒğÚş¤ş\Øl”ĞøÑ³ gA‚ÂÇ'øùFg‘¶]q´$¢ë{@ïs~Å!LˆFbİËyÎe2
ëñú¹~‹…qCÎ¹{M¸‡\%…rs7Ÿ¨ÊcCuo=ë±ì7‹[w÷KĞT'©¦×¸\³,±+Ãp/§ ‚ KÎrº'qOÌ
µ»³©à`Œõ³~Qµv¼+ö¡õ×Ì+œ‚¯J¨îúß.ºÕ±‡iŒ°å'‰n†}ğÊÒ©Ş‡@[#¦gfo“Lğû0>È·ØLNªZ"wˆµZÌÔÜ•-GØ¼72†–×cC™İ­)ª“Æ]€¤V'‹ğ<MÄS6 /«dş¢Rªÿg®0«mååæ_éêVcÚFx  ¨ªÖc@—"·ù
=sE:,!’ÙÉ¡9ÇæXÕ¹»cö‹@şLkÀ}÷LÑ?ûüóüyd‡sk'ĞÑáİĞØúşY¿•WFhx~ÚÑéQ% hù“´:ëÅü-ÖÈÜŠË¤Aó¢f#^ŒÈ¿9
Û®¼$”I,Ö°qÖNçÿt® YXĞ}ÙymĞ~I{.#ÎeYyU€¡µtÊTLLÄ—å‡c¦IŞQ«›ÿ 4ªLÏ”Mk)fKÆ³{˜Í-Ñ”]®Af²@^”|æ01±¿N` ä0áTòåvÑ½½#ûÅ ïu{ËZ¸I3v?ù)G3
¢IÄr}'*ÄŸŠL¼bÖÓ)­¹ùŒÄÀ½²Şk/ƒ“ÄF$·?üeN/:pB!Oáv~e«Y«lö5UĞt™Ì)@:â1ïÈ©¨¡»C^ÙØùÙ›©u»h†Ğú&ö½9.N‹(eÒÍê3çªÁy&¾põVÕF±ù!®;*ÊŠó?VˆM’€Äç‚‹/GºÁNßbòÖ–pòıæ’ø‰'w2T†JæôfşÓÌCİğ@ A@> .˜!ƒí©6ŒÑp,»ltVK«”‘~Ïêÿ­)Ê“ìC¥ƒy_M¥R
ªç«ñw]ÉšTF}ıÎ*™ZÈù°%'´õ,éËä§xµ±›ÃÊÌ-ó"o7ÕòÑ$¶½(DqıÔï\p}8Cå¶êš¤$À_=ù¯9YØÏ5Ü,Ö‹xŞº®Š]fr6¡ïñòÅÂçXEıüî=×ÓŠLGö¢Ş’ğ†Ñ§cŸ¸ïëb8]d*wµîÔòè¯¨´p1Âç\7nÀZPL÷Ã~Ã±f¸\¦|35#„¿ût;dËT_†ÿ(ìö9İ—Qßˆdı³ŠÉ¼FÜ“7¼3ş”Ùü5kÆş}{,\ìSò¸IBcÆÆ½¶­H”ı6àäĞ~>Ã˜m&ªpÓÇ“	bï-ØõV#´0ëjSQÿÎ)ÉuhJ °‘8—´å$IB†™Ú*¸ç"…>qâÄ&ÚR`Àß	ÜQ™ao,¨ŞıZğhñÔÑ;ŸÈj¦Q“Ø³ê×(Æ}`¶½z”
Z·¥x3AH>òJ^ÚìC%Y)Jú=İwd]`É‘Q['óÉ3şÛ¼ß˜÷—Rº»‰nÙs!£ Õ]·"¿\›ïVxÎÉ­º9lµİ0¹¬p
Ô">ì‚ÒÖH¦¾ê-nIƒ/È§-ı&kÇ·Üh…Ø4ÜÃ‹L›iVw#Bb <`\Áò”Õ²f¡˜À$öß]Ã@U‘2Ï
¡ÏŸ/ÍYÍgù¿­ú1«‘PIáì`#°£Ñ©¹d>ºLäÿËa·8/)D­p‘¤şs1_
u´"ìƒ*İÇ<cøÛñ¼šşhæ¢ÌxÊó#–™º†>vôúµK!¶÷†Şic£%µÀÁ}!6)‚5[x"İıÖrŠ#›2Şû‹ğ6Z×_^V\¨ÊGÓEdWFÚ™À§f§»AÑ˜š‘$ÑMëC0^¬s$WkİĞmvÏx¼ê£TzùÄNPëUväÙx·Ú-/æ«jˆ²ˆ–Á>_U³…Ô¢c4àé[@Ûªù‘|ëT2;2øÏTí%a›0Ò«İbÇšûâBÒˆ¸à½µêÙ˜½	÷ç&^˜
ú·rt4gÌv©ätÃçe–µ“X£ˆ”@Ş½Z 1h‘Kõ¤mš¶È%îÂ==ª~ñ¬@—¥RFƒ¹g¶)dç›„mÅó9âò]ç ¹šÕ†«Å9ú
ˆXJ¡ÍèŞ±–ràE$t
Á`U\Ww_âéäêÕ<=AıÏAU%]<V¼êÖ#•·h÷6ãŠ6GRŞŸQmÂŸçv%¿R“j6;ú‡ì.u-—@FÎä¶V%ÕH#Ñp“÷Ú^÷5CER<lw§²Êğ ı:b—=¤[N .^FişfŸÂ˜ŸaÆİ»škYíúN”Yğ~™íœ}ÄRÍ*î¨ÖããŸnmI©ÂeAm03	»£üÃD"ASŞxÅæåÂT185ËmsÚÚÎşwká'J%­–Y±±F÷ÍƒP>Ei²ñIölğ1¦ì×qõŠSÖ‰m‘³n6%OQsïnp›=5Ë¡ïCm½XGDcH"Ù7ÙÕõkwî3ˆö(X„a•o8JˆFú¿ä‚UdÕKSŸeb?€@*ğxTÇœŠ”›ª¢´u¦Ë#˜3Äh‹vl+±»²5jT]hQ•`C~gLÎŠ+v	Šsx:/”\\!çÛç<ïû&˜_¿Ü¡Si¿¨çêëg2OÑÁ¾éYÜıT$ø°ğ
6@1¬/V	ºôZ wÜïx:LgÉå5ÔÊ~cQ§û‰)n’’f¦]»%¾ûAkJoHO5ÕdO¤™T„›òwmW‹¢OÂÇœŸõ‰·YZÄşç¸¥}nh…Ú O›æ¿ö~ŸÈnÃ9=dûaT„ìSf„§Ø$Ah=şø¤$t

ıáôÅüæpz†ñ)ã¬d+"Šì$1«‚óo-Y^pÙ^C¢éuäGÔúw’Ú-Æë3xzJF±CØ`¶.ÀÆ‚O|…ÄçXvn6y…ßLnd;P}§¶söıPÿs¢İzWñFNv‚NèÃ«[Â¢Ònª¹¸ß—Ô
·yòkäp/ƒ; Õõ~Ej3^¾Š~²Iün&ÍŸÖ]y4»j…‹!Ñú"=8vá“ˆ}M˜“€Q.é¹
½q4@»Ñ?ÚmìSx¡e0~g³`¡İË üxıÕp]ãÜc3ªlŸÄïSOÏLKd<©W]¨»l¯¯»˜XpëXTéÍË¸]Â#aQMá/¸†:üÈN~PàO¸Ã–/Cß€ŠÎÇ÷¼	İl‰I+Š“a’¤KjŸû\"P†Æ„iF­_ÏWRh"ªNğÅdÁr3ŒkP‹jR·-t ³Uª9±d nx}‹{ÏÃòV¡‹ŠLcÙŸNÈ 4ºæ²Ö„5²_É1x‡-‚	£è1>§¸%LÙrG‚`)>#»üˆLOcçì¤‰FUÄ“s.æy•½ ¼œzŞ $ÈÈùãÉÎ+¡	õ¹*®àqëÖÅRlõ”ñ ı²í§İøÌÚÁ™…•r7ËÓ£ÙJë5ëYĞT™+-¸ ™X G´Û„{™}Û¿NüÔ±²z¨s×¶^>¨ÕwÜMÚZÉóÄ&hÀ„o{ôO[¤´<ş—D BD† /¡`İ?Íf}Ş!OWH‹¼™öZ¸¬Èàœ¯AqáRÕRmº›Ab%Svú"R,¤–Âh—ó¤óôœ	U1®Ë¼©ri€m˜ç¬$Y}sÉè¬QK?ƒ¾ïºDÖ™õ§$Ë¦²ş³_iÈwƒd¶Î÷–c¯C¢v?í‹HƒdÃã… ~Èö¤’`«¯¼ks¨’Çµ·N#JÃOÂ²±F™úÛjœ{¾e|*æwOYñdëÎQŞ yÎÒ«ßŞÂçp‰SnZNÅJQI¼Loû#4·IÃeº&pm^:K%½ju7[‚™ÙÏ3%3ìß¤7ïÜ&²‹ÀLrëí4Dú˜•trfEVaw"ˆ<F­+Â·GT¤°¦ô‹È³aóŠ1Ûˆ]Ù=îû€ ¹* ?ŸÍbc}<âÛªqy•Â>‰kŞ† ıNG×óÔXá²·Ş'=“÷×µ½—Ü6q¢nyTÄÛæë£¹ßĞÉøÅp,@••ÇOíd3“	…>Yı<æêğT¿Ôî–—j7|Ğı“gÚ‡ıƒşkÑ¿_`‚.¾µ(pgÅ])Št	ï‡ö •iVéáç`–œY¾#Öşãª(APœ'Æ¿vœˆ=ÊğpŸlÊ5×³­UÆçr{l¡gÎŸ_1ÿeV…´6's§uÁf‘H9êoí,®÷
u_P9¾¤a®‹l!™şëIèZtêğùgfâ­œz‹^Ã?DGÚãD$WÑ­HÀ>âã ^şª;Ş~‘*[–®sa%ê¯øğ”"#pdÚ6ÕeÁÓÙ3¦âÅ©+0£wQE‘<Åí×Û4‘a,}1FMk‘|X"ŠMŠî PöèşìFö§s@¶âuB!ì3–wÖyípºP–]•±í ów‰¯Ñóç—y­·õÁoßÉ­İ²•¸o¶y(Ö–Ş¥Ÿ}UËÈ/¢ˆ¦bµåüÈòÁíÍ'O>R%L£sAYŞ±ÆwÃUa*o’«u‹©j¹[õÅ¯ÈÁ>8üj’Ç)Â¦uO¨]¬Al-~0~Ó‚?¥á
½u¹9\‰’»¥ê^[¢0º×º„Ë«M(ÿğ íL'ş.³<wX©ëEØ~êËßÒâ_şÃòg,ä1ş„Y‰½Ó$íài š%i]ÇL.«ü™+Ë¯Ïòû	U"ŞK`õ¡ÚÏ¹9[ä^(,J_ïÛR`…Ï(FÌ{í&¦íG) x¸¢¡¡6I•£oà4úa˜µ/¤µB£6¤yíLÕ/Eîy=İJãšÜÂ÷NË"yô
É2±iTÉ¼€î3_uXMWBíû%[»eæÍŒ±í>sC`CŠ#¾¯•êİ[öÊéÃ”N ùÊ‚òt~Tçñ^ùŠ;€ÏçyçY4£E9ı¸Õ³‹ÂÄ#¢òÜ(æ¢„L’ÆVékÛk<R)´Ÿå)
ÂëŞ³™Š4C,µ¸h2şÅTcWv	2ç&©î +¨T
µû›LDPXp«“YuÊ¹×¥Bæ,âNÌß™J˜—É%\p¤Kè½úæb\“U¼	ö/<FØ`obš<¯
·¶<•YöÆ©ä½“
I¯-ºÊ›SP†Ï”Æï½«’ó7Yš;n'l˜ëãûS`C)âDw>³R„êJ‚/§`Ø˜§¯UÚiåûTc˜ëOñçñ¦g'ÓJ%úîLG;.BÓôGLBáŠy ­.­eqÁøÛi©»2+g‹Ôê~®=iQÃ1\ÇÙ~ÏìE™W- )Æ·°Ö§‚5ogRö@í¢ŞÍ¤r™¦˜ òE»Ø¬$§ÚJÜÜ} jWğ†ô¸3üËuõé~7ë€’‘t«»ş|;[#ohá[@u@¢¶¾ÒÏ\ ULÆA5Ä¥+û¯ˆ1Ël”ÿ&ÌXÏÿ²D[šÑÄ5Wş,º]`:òS*÷4&VF8d’£½IO6†rO!U—€|Ò§JVvú;—ş:WÚ²)À š‚Û¬q¯ç«ÌÉyI†¼á’ˆBºÀcñğD·‰2“–„ç"¢ßÕ« óR.enˆqc/:GÌïé˜s‘€`OHÁSüş1qvG;½Z°w†U{VSsIõëæéÈó3¹â¢»‘ëÇEå•¨«²6ƒçtÒ·ˆvãF…Âu”´Ñ»hÆîÂÇ†, $úœØV&˜Tàš›„‘´'ØúybÈZé’zHKË/İ5;BÍ‰ÊïµÏşHŸÊÌè¥n`Y¡vn0ëgøéox6£Ê×>8‡‰Fi¿¼•èÊ…Ú!²Éoñ…š—‘Ù®æ6~†9“è¯7ªk øÉÔ+m1W¥¨·şW,
ŒÔ}`)ôn½—=¡béßJF±²>¤Nôá‰”=y]{°§¤ØÖSÊ·|ñ2¸™…xWúEÖÂ8´€ ´ÆB#6Òãa„U‹+KÀZ”³óísMf!Ä{fêç¤LèI P!>Â´×æÆ†e­ƒèm‘ŞF ²MßÃ|zÁã?ôÛNÈÒ³ı"ğ
=õ¬U’.*lwS˜ÕÃªAGœiËğ|¥kÇ­ÅH«ç¨jsÏ{Ê$.—Ï²"Pãéü˜p.Ä"!šfÁ6…á‹Á]’wìé#*ÄEÇĞ%eH3œµ’Ä™B0bÀ«<¢™È¨ÓX|õÍ%Œ1*‡ú‰×Û¤] ‚l$úä@u ^cR(jş§ŸÎÙÀ¥@ï&¹$HÎÔím5=¿M¼UÄWòŸ†n*ĞcA0‹cÿªÏû´	33«é2HPaá	~¦`vşt2‚ À©¿	-¸£®°r8Ó.–½Ì­Qô‘„N¢W¢Šù)«îˆûbzeÙ¤ø–_â§ÿÓB5£/t­eÀ2QP ‘è¦¹÷Ê"»€!¢C§èòÙ~bÏÍä”éö®…ªºp¼}àá‰.¾`a®ª‹).•òP$0t¾Çh—a‚ßÍ)É—ÓîõI|© ×†/ ŠhÚ„oÇ"!ğ¼œCrÑ8ÅñôÁ·™¾¥}Q•¼.sÌQ¢ö³Ìúd†6Æ™’–Œ¨ y¡€¿ß“kEÇJHl}KºØ«/ODÄfCPj¹,¹IĞAaº^v?§ë+“AHñØ(ÖMú9,U7Ã,9ÕBkïHŞë4=Re¥xLks(›Àâ±iøt¦¹ài©	¨hU¤ìM©…yh4¤H[—xçäğüú¸še¨‹;x£Î•üê¿mwKĞ5QY÷6Š-Õ`_ñ¸€p[ÖVÌºxÊÔÚ@K ¼Ëc®œOÉ2Ó¬‰%ÁÛdÖl—Éû)ñTÃ„]
*˜Øûgç•$
±[øÿu"yMéõâ?qŞüz©Ãêµ×İ‘ym66„ 
!/Üö5²(@Ê¥»D:®uu¼ëZyĞABš4¤Ã¿#É9ıÇCí‘gåš|§eÊ÷]¹=>øÀ¢ºMØÀ wÖAC¾TğºÂëN"(]qK/.ïèO_NiÖY¼•^Ä¬oùµ0[õƒ#Ìä¡Å\\‡458Fw„bîàÑã‹g5òBrk­UxÖÈ¨Ä CWJÙz*òzˆs!ÍK‹®İã)‹3î9R¾ã¹´†$ÖmcrFE$İ¾yšÔí¡m|o*¡Š¡ñùKO¤ÀHÕ¨	Ë^e×¢?Óõ–Š®}ÙÏ9ÄğÜ™-^‹oW£
p¥1}µ!®¡òSã8áé’OF¦ùl€âÂŸD†›¡¯4hğT:ªwÓ#£$æ¶ôûPêºcjœ÷ùqK¨v‘-æGé3ÌOµ‡]Ç@[Ë[$|g¡Ú>¾õ¤©7ÎÀ^z’Ü&'=İe 	˜²Š¯#tŒ¿… Œ¹²[soÑå:ËØ[-ãƒu±(yé´½°éß›øÙÿŞÑ‘Ã~'áê2‘=ºoÏ¹ıŸA$1–ëPv!ïb>Ìn ÉïN«±.öEe›_~Aÿ‚vågÌáïJ3XáÊáá°õ/›Oƒ J˜ë7ŠÄ«‘ÿÜÈ§üâİa£¼ r›ıF–6&6JœV_¹?¦\6ƒ“ÑZñY Ÿ¨õmÔı%^Ÿä‹¾GqVy Œ1½:Õï×ÆkÚèŸâD®ÌàZM“İî@uWw4h0¦”Zg]á{œÌ!9ÙÊ ®ÇQíÜ*B%½ìCiÍéïH:”åÌÓúæ‡óMp Iï•Ç#>¬Cæıgğh¶}B™Åx£%·‰@íÙ<çâ¬ÑÙ›oNÄLG–œ7ÈU¶B;IàÃœy•Ë+–¨fÊ»¹ô—¾?· 3$õ¼Œé¥£Báß9^D!´4iÄÎ0XGvê§oc\œlÚjAs3—ÍY3\˜>{)BÁ3İÿ½àóÓÂ¯^“Ô©æœcı‘êãøõA•Ñò•uÒo1ü†.¹±N!–;¬7ô/ByDfN1®İºÖMpÁ OËÕÊ&ÇÍçU5J±gzlÉJ†„ê~FI¥ùHÃ·´3WYŠ©H(ñí³4÷›¿E3¸¢³†à%%Š~$¯ƒ{¤mLuÁsi³!2—4úãaªÆª1s[êsjÿ:‡X­"„¸>0ú“zéôwÉêÈ©5Ì]ñïûÅ5±†1@›W¿™œøLşÂ‚9G^²ö%ØÈÉN7Q8L
o¡¤ •Î§ş3\½ t©ˆ¨ŸĞqß-ËâZŠ!lk¦RDS,áE^~*Äã_·ïˆN÷¾“è —,2&Œ³^Ëâ,ÜlKBÍ)ãÊûvüm
oF)£¯øojà…XAñÉ~Ú^b}*¬0÷ØòaŞÈ|º;¢÷gŠå"| ¯+qÇ"ì‚®åcyÀšAûı‡Ñ}E¼|±Ğ€Øà¤=ßzj =MÛ÷;~ ÷˜jW>;fÕ+íßs2D°*\ÄóŠ›zÖyòı]©§ÛÖÀI^‘5NÑ\6åØP7İ¶Ç5‡JüÏÉş%ÚòmÃLrßw¶ù–C±øâ»–åîz›Íg¯^j9_t»¨b]Ş|	(Eƒo
Dneqs:–çje¦åš‡§z¾”&¶röš­cöŸó¼ì*T+40í®…-™¬F=6|b,,9Á{N<,O”ê¿÷Á?ÒVVœ®LCÍ?æ)Õ;8®@œaNlÏîiŠÃøÈ6åä>`\;i—}¢Å‚óŒ€è¢Új€ehhV‰°¼ÈåËj+“h¥Äaó±õ!Ô©\ãƒiF«&Ä_ÄgYY™Å0/´§ûÉHº*öä;7Ò¡ Æw<fÒJ›Ò?==>Ú«‘pJÛ›…“P)=çˆS«“Ö’ØVøJ@Qœøî™5gÊéŸz_/Q™çbÂ.Cqg»9±Ô*Á¡æğvHÜjÂÃTìl¯»ëW!‰àg@›€î‹V©ª)äXN´bO²œ0àV0‹o„lÒò2ãÉ|y8ë—ä½ÿD¿ê‡+©OÊ…»D@"×Jâøác5–~)àÏÀÚc|H(ÔMz(Öt H/bÏ´­™‘}ÌI1¸®—”Í5§Uw•IùøÖØŞŸ"ñÏ€tê•M<˜é©À¦±h±PÇã×ú‹†Bàğåµ©ÉuÈGj‚¤ËuD®ZÁi6º™Ög{}KeàŒ®1Ş·“İ{9Àş0gW2D›_†¯ìbØ¡7eáÎ|ÕÌcºKìŞ	
¹ÈÈw<ªcÃ¨Û
ºeäÇz¤wyího<?ùdÏç‘0ÎËsjHcã$eÊnŠRÚ„>»`sHše}Úåí˜ê"…Dæú“˜"JŠ¼.Zã¸Ş´Q$xD\MË/\WR°j<ÂU˜ˆşÇ–Y¿ŒAÎá¶äİï2ØĞ4XÍÄóxTiö#ùºñÿ\zVH}Òæñ=sˆÈœ21Å†vy—Ï¥Ò8ch ZwkÉ&³f0jn‡±Ó‹ÎîuñÆlŒ‚ÊÃZ©6œÿ²ĞöQ úk@L5("O9øÚ£!ÅØ®Û_'ª¡‹šb`~¯åğQ’v<m:Mğ'HŞ„¬`¦¢Ÿ<ãB©x>=˜®¥yU¹Á‡´”ÿø¶èR"—ì$İ·ÆÓoÖ%ƒ-Ò6\C=Ë¥ßƒé£d„à¬¤éh<‡ÿÀï¬av dJÙ\?ÿe{%½gº:n;ÍgsÔf0ë©'Â6 ™¼1!9z—<ù!3MŠ–T»æV^P)à")¢?U²‘mï1VòºNq× Ä”ÇM(=jJğˆ½àôeÔ•/z>o°ó…d	–‹ØİÒâåâ5ZP¶¹+Iö6æcì–àö6›øî•çâD³Â8šk$« 6Ã[B£ÕfØÉ]Ä›ÒğrIr`¦ÚÕ¡·ˆÈ^×‘x˜>eâYy€GÖ)ªd¨ŒCØ…Õ³Bkáïˆ=^'®'vWòw÷ó:w^Vàø2TmÑéÑşLÜ™u:M€‚İéCä·…‹ØY§®ÌÛÚvİ¡³ÂMØL¼ãÔÚ”÷`„*m»R&šKôaØ2Ú 7æD’tïèğÒÑúÅ²á1Hj¦Y
+-åÔâò×Ä3ş€€™5k	ùh„@·<|•	 ‘Á¿vú¸®ÛÚH‚p }éšn)¢(ßë;°‰5í:hXZ÷ZQGI°ï˜ÛkÖ;¿)Œ‡¿ŞAí °ƒY¢Òå=ƒÏ"·oÊ‹Í|
ÏÙö¬Í¡Êğëzm ˜qzÒ<Cÿ„Óîë¯8x‰áÅøIåÑ‘lƒÂÑÔ2¸Ï¢ã
£ëA—ñÇ™†ß–‰x6ää«‰Ç²ı1Ãdhø>tlvÉEóˆ¬ÏË[Nì_@²¤m¦ª9(ÃXF9õÅï3Iô_°–¡ŒÂI¥R]²pa¯cÓÈˆx+5íéw£:(é¦”D192Ö8B®©Na½Këê¸°	'”;Ä°,1=Á<ü·s½F(V¹*Ô‡'¨°ÿ·fŸc-ßc\† 5r£\Ë¿äÅ$É/æNùû#Q®fÉÂÏ2JùwØŒ¨ùûÕ)ä^CúJ%Ê‡ØÆî6W¤†Ge•Ğ|Î”|ºŒ×òn¤×Ò¨v$ãø_ó[¿óŸ÷´U-€å5¸½È?¦£º–Ïª9Ş`a/Äÿ!è-N‚ıö»Ö²J´jš@ô2>är·rZì· &0×53_™ºlŒÛåI*Í‚2¶!RòJŠFXQ(­sø_Ô¬¼ç•
6ÿ=Óåäã¬_v<v[Ãt§Át…›QbÔ¶Uéø^
ä«ÑbŠõP¡^ıW]RWÆ6Û©×¯x^ËH¯:©Ãæ¥üs-‚"½ëuÈ!l"IjtcATm§İÑ”î¡ü]û^pZF
OVÖ×Lıó*UÒÁI!™Ú%hŒ¼ÈçŸ«}É„ñùYƒ*íréº—ŠíŒ¬ÊæãÌ:˜féæÀ…¼E„éã0™«å8š°—$h	Ù¡³µZ1Ç©/“Çd‹uµ4Ô‹RìEäºh¡İ!˜«H§bC&Ìôÿƒ­YÙc@< ¨ºÙÈŒÎÃGËäØ†	Ö©û2 R/”fMtÜÿøí0˜P3…hg
y*üqQÑ¦‚“uÜŒÕ‰+Á²HÁm3›‹šè"üªy±_1{K2÷WY‰lÓŒŒ„€NìãEèób*İ\q€Bú;Rv5ôÿC¼†İCù,ıã}QP½"Múö‰vù-sÛ×Èqÿ®5âç=½ÌMèÈ§ºAmËÁÛfÕü+ï–‹½Q]b»èªÕ€¾ZÄgÎ:«œ­}tÎ“oÌü3—\ 	É×€ÓxâêH†ypÌHèñ“¹­Êl\1wmÆÍ¬ÛmÅa.ÃŒ Ñ^ëœ>àİˆ= áíõî	R_6ñÁmvhuÁú.½¢HŒ‹"ÁÙÌv$!môı÷^Å=ÌèİYwö«lŠĞÿÒhe•¡®öÓÜ’	…dˆŠsí   `ÕOÏDú ! ÿÊ€¦ñ'¢±Ägû    YZ