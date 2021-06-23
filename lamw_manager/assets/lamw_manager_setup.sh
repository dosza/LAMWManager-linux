#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3075945267"
MD5="af6bda62cf595ed96741e1ebcde8c33a"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22968"
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
	echo Date of packaging: Wed Jun 23 00:37:20 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿYu] ¼}•À1Dd]‡Á›PætİDñr„BÍ:íét%üÉbó1 Ò[)™ò„8éñ
‚ä+ÒlÙø(ŒiŒL7ÍBÉ- çüû)È!êrÔ€¡¬„\»ÌşÙyª ›+T©a4yòL¿«†Y€Ã«Rñµ
ò-‹<»5únîlx§é¼‘MšãÚ¥—M4K¹üg’»¤ë
êaÎñ´9~µŠ¯ßÔÚGÁmÙ uyuêø$Ç»(òc áö°­(0X²ü•ºG¾Üh# pA³\+~”Rî|†fÜ	ôÂ®ìLbÃ:sYM ’Èlş“£Y3ËÀ‚õpt°	fœGLîÒ ÷¼\š‰L€†äŸcˆ‰ï‰^r@9õVùœÖG}^
ıë@Œ¥‘1ßqGœ÷a3²ĞP./ô8­ "Æ¿j"Ì!Ú[~ÊQ3Ê#à[` I²ğ„YÙ××¿äkCoœ;CnQ·ÖÖ:;ö»bl*bÚP+O«(»h%ãDî-°ŞçëÇÎYãÔø=HìK	ÑÄİÆÒ3˜¶>;¨²Jh!ß·d7Æ U59å%î_B|—bGûù2ÓïçD«¶@~İ^g€¡ìNg(n™İ=èœŠ2Õ$æüU»:T2"Ÿ[nlÄ]AÍ¡dD—£ĞƒuË-w~ş›?7j–§Ë¸}“\èÙ)6¦4;ò¶÷Õ±¤2†*-«)ñÍnh·§Gş³ôÃÓö¶ÚÕ”¯¾]cÚ£>Iñø¢9¨î§&n,l©Ø§Zğ£ÖhY/­FÎ¨ó•í«ŒÔ	%ÆğñƒÓ¥2EA(…ú?5»‚¤ÁôŞepe
ÛøÔÆ—šÚàZŞ÷t|ÖPÒ›ÙŒàüq(Nõ§²‹æjD:–--ÏrêRÅú úØ.µóÀšıd?‹çfG&0Ó8ş#:³à©Ü
îbn‚U}à³Uø8’v"Ÿ$ë8v"ì`ñ¤BğÓù:ÈÒÈ‰U9Ød?Šğ•*aÚ;5ÚÛï‰^[ˆw=ÏEšÿõÊµ¬Œ, AX‹{‡"şóv1/=K@nÎì«9ÈŸtôfÏN(PİóVnó4Å÷ûÒ¶Ìzè€Š%f¥ã¿;/”•Á
’rü*YŸôX%Šñàî%v99Ã6Ã!BzŒ1¸¤gôóğ¶ ÀñÖ ĞÒÌtÔMºØçç9
ÓO¼öúQ)<*Ä³Ù„7­ü^ExëDÜ8ÅH˜	ñIá9ˆ³Ûûktñ2?“u&½yÏ#?)¶GsTê><ª®XJıœÈJßa¹  Q­D;C8M\@Ç>®»E|Ì³ãz'ÍIùdä¾	Ô-	2³¤³B…c^¢¤L{§‰ğO9÷­¡’”±sÛ£-(À)ÎJıA‹¨lPÃhÀhEÌÙïDUÔÃQ*”X±lñäIµ|ªƒÄ]Ñ4«‚¾œ>hæõnÍRª#jìH.hño¦-íÇ²LİÉÈsdbM:Eõ½¤¯Ìg	cˆ@§¼­ÖtØÈC	Ÿş™ÃeìRYûr“á=Âp_iˆt=GQFP9$¬8¬ROÍâõ=â=êf=Ûb¥páş (ÖÑíõúN‘›Æñ­%RhË²+PÊ†…•§4ò­Ø8}¤ZóAª„gèN¹¸c=•&Ã?ÉÇi™x)x°A-5‘¾Uy‘‘†zëkğ®G„òcXnˆ#E,r—A~ÖÆñ/É ¼Imn¾ñ¡Šm×½‘I*Êœü6İykZÑ©æ6ĞÑŞnÔ!Øg9Á¡¼N³¸÷âs‚±¢<vï‘¡GuclF‹á$g§P|[ø%q•Mkíb»gó+¼¦l7ZÆøsæMî‚ÄÜf¼æJ³=C*
UAvAcù«øgrøm9®‡­ cwßëkÄoåw©³È&¹†„Û,Ÿ›õ»z #4¬úv(?øDÊ•¢T(74şó³Ôv0dpĞ£9Íi“
‚rh6í~§…C;~Ö0Eê[={<ÇâÇHE…±«'Î-vçÇóé‚PeÄ‚x&±ÀSTß¥çÃ½A#…úâ¸ê¯š¯´ /nÙõ¶ ¼s:(<`Ö<½×Ö’AŠŒ!Á+…§¸„ÿ&©Š‘-[ëAåû%¯ä€_¥ıª‚òÓIuŸÊ÷w2N)#‰•,I©/iäïúëµ§M\xS"æÀ/‡„+áµÃæŞ¶€ çıb¦à©‰€h«2Ùª ;SÖ×ïıù†7Ç'b‰CQÈ=rbë•¨vİEâ™W;ëí%6sÇu‡¯“ŸëÃ”Sı€°,Y´Œ’"+@ ~:Á$¯Y/K`zÉµé_™p­€n¾+2Óf @Ó¡ö¡¢å¥Ãt4ùerÚÛÓUÂ†ş*Îõ×èIÛ"sötÜ«çatÓîZk\ÓƒcJÛ¤ÜcØÚ§ËQeòØN¹ú†Ë¹K§ô„B‡ˆ"K(ò]ğ¦mƒaÅçl›ªQõyZ¬Uki^Ä¹Á–óçì¹Ov‘}ì¨¯äT7áóÙöğyâYğÖmî—(Ï‚<j ˆeE}ª)(I?Â,º>h—6 \¨@Z´Ò|1œĞ _İ€´!Ilbü^ùH›N²é-I˜|–=÷‹—oH~‹œMoHƒomĞ<#¹İ^W7İ<â‡Jb'ÔÒ¾÷_´±¯ÃàÇ‰àÏ_ù=$àµ%¡ØÅc{âKŞLªÙQø?®ij5Œ˜äş½¯ùF_Ïx¿d*X°™5,
%îK4;hüHvv*Ú`£8!ˆ(ö‹ÿGĞ 6‰?§œubÛ†zó	àwâ¸ÆQ‹ì5PÍÅŒ,lß[Õ~M›Ğ<^•ëjÉÿc¥¶F~÷C:"´1‹N…üL¦¤J™µ«LE9o‚ÙßŸsÎù_;Çocê,é»\fÑ¶F#c€û+t¿%C¿‰\p" Pù>v©ü7–ç  ôµ1‹wµì`!ì,è KÜê“  µ(Aã·Ù¼8¢ˆ«¬DĞíı/†}šü”N¨†hæk¯r×¿+^äÈ£RÂîUûr—+J¿!¡;-Ï¸ÎBMÇn¥ÈWIm]¢›‰E÷œá¨2?şÇ5¢íº%Å€ìšİcLIÎ(²?öğF#‘hbâş`N_UO£ãFô'ñVó$õ#¢§äÃ^ÅşdaËNÏÄ«ñE×øD±µó¶½M^+ÍÚxM«áNks6†Ÿƒ8Ú(éˆvİl0û²nÁãÓÈgé¿‚05‹G€qÛâƒ	6OûÈ7Kâóı±ßN\.ôñãdøPxh¬T…?ş&P4ôåÙY5·1âÊó(š$áò©5â?Šn@:Õ f&2àPp>EdêñÂ–^'ä­EGujŸşw¯½Ÿ=|9‰–ou®¨¨Ì‡U}ÅîêIºËü\à5ßgød×ÿ5Ü-ÁÏ1ÀMÄXM(+À#/şRÃ”û&-lÖãºÍZdØîš—(ğtB*Vš‹ñJéÈ,jÜ	 °	_”[`M%±l‡q‰ëûoó`¤ÿ—4Oİ{KÕ/ƒæíNó>ò~Vú¦¢¯ÿ’A~`Xfoú«"S9™›Š’€`iÄœê¸ƒ,!¹ß¢‚*¸£]ĞÜ÷*‹+?LøÌĞYßhFW\üÖˆ”\´“çqò\Ë¥|-üéÌî+²‰Íøzy˜7´*æ¡ƒhñªéòOUZHˆ#ÙìÌ‹ïcÅìpëèv,ôUk9‡ß	dåÊ)µ½Ñ!3ç’PC?låÃ»F(,¤îpNenoæqÏÓIA«ª İ'ãd“û6¡ÚŞÿ¤q0]|@¥7«¨ê(Ó!Ş¯Ö	ÇI;RlÛõÚe4ÎYAÄSºnl‹‘Cõ„¡S½@Øp+Ã'ü!€!?‹8‚íbÖÁ3³Ây7V¡ı›]“õ¾5|ìnx#ãö	gÎø»Úb@M9ºtîÇ¯•®ã÷x–mÇêÄÀù»Px 7ØÓªû$pbùCªäS£Tóâ´/Dy¡µJéX+ªöNLCÇ½ªaå¹ª¾Ó[
ÈÖ,3 H=P:Øøpb};‰fÛ¼×ºY!©z´Y”éG{¿‚èÈï®µÓU&ıfwËĞ[İá‡ërv“¢8Ëó:™.Á@_¶yü8bkJõ—Bø}»V™LîÆ–‚’^ıÄGÈœöÓG†™ä›€Æ¤ıÎò¬h'Òö#q–¥İÂ:\Ô`
š-øZèÀu®Ñ]Ã³_ŒknÔĞ$˜|N,â+}Mh¾(‹Y6µ`ñcjrj<™ˆÎ†^¾v:ÊvDåêªEø}¶+Tï†“u·ÿşTòVÕ©ô_°ŸÉ4y½ùŒ@×..70“V¯¸=ÓšMú­ÆAó˜ ‘!%Ëâ=÷x¸¿êeˆü¹ejFĞ˜•z|2Ü‹}Œ  3Á¨zu ­—¢Íƒ
ôB	Y&pšƒê|œC!wÆ[ğéH^Ö°ğÓÅTI&€‚µtêfE6|áˆo€oMPôd’y/ºH„Õ3ô÷-Õ^y'
I¦ğÑà¶¨.û¾,Ã—ÅíN¿)1Uº”êJ»²DÀÑÓ/ïºŸğÅeã9ØÌ¶FUüö«CÙò|±v76ÿ?È9A…ÆSíq}%¶>h¢<º»ùÓ`;/¾`öCPÊÍÌ7“Òîìš,±ûFì¶´‹9)[`¢ÊlN
ôì{ºÑŠ÷VŸûÔíO(ĞÍç}f³¢/Å¼çd„ëæàŒ¢¶7 /È~iñ¤p ``Sv®¯íŞÂ‹ÁÕ¯ÂF!¤ú$RÀã\I«c²{èeª%c’…SçÏr¹ËÏ ´t,ĞZ¾üEoÃSCÿ=rIGöÒûßÓ¿VÅ:$'\ß]¯‹O¨(êÓ`ªUšháwËïİí=Ò"c^Ú¾d©üÊ€„ÕÑ-‹†UµW¥Tê3ÿ¶ƒ—!'µMÅWòûíÕbôr" š²ƒÄÚüİÎ¼½v¤ÿö¢éH¶S:,ºí:d´R80³R‹à”WÅuQ}5Ê<Ã™ßtmí%Œ­³ºå¬œyb†sxÇr±ºP1_ J/ª¼têÎn¤g¬Å¡Bõü>Í$j™4w¢=!&ÌËô„ç5îÉdz¥t¸xş&ŒµQîìğ¹j²*Ó	zÕ•,ªGf"µŒ²ñ/Í€Pmâ½U±Ñı¹ƒMD«~®0HËì'÷¦½Øãş7ÙÛ"&2¢äÑ-G‰G”mÀ«ìlòàC†):²ï^Ÿÿü+ò¥.™¯>cú‚G9U*©”LÆ¶eÖêv¤lá^4oå3¥•îÍìùÛßÖ­póEıêLlé2I&¬=úl›’m/*¹’	3Ï„¡™ù6]´—kÜ´€2H)ú3èú«eñ˜ÚèÄ— «ı§µ/ÀWHˆæßXê¼Bj=1•ëêÿH>©ï¶4?Ó•Ş˜Ú¿ÌñL…d4H™›mŸ¤rbŸV"¾&$ˆ<ñÁ­ª?5 ;SÕô =eÍïïÍò’nJ¢
¼’Á(yTVAÛ‡Ñ2æ£ñˆ]!íW‰("‡Æ?!œ=oËu†2Ê/µú„ßé¼]ë\»_lıøäL·Á¿ê=Öº˜ú°ô÷GXŸ5¼C$Í?û\£1í†üE†t¿H
	~›ßJ*yÇÄ5?bä«ZÑj›æpÅè
Ï|—Q!¯}“„ıoİqWÑoôL|ä,nñÌqóÖé™«vãÏ”§øªØ;·ÕvÁ~¬3Ú€vÛQš½ìÀîaÎó/«–ÊÜ‹)Àr8‰Ô!HJêÇ³T‚b³&¾ÓÀƒî®‚–-k½¶£_'›kõŠÎÓŞ<©$?ŠšÁ±‰{ò\@Ù·] ôÕ5oB7±˜*ù$lî?:k†sµ2EşùAüVØl°h{2‹àà=àX¹çP_MEá‰ÆT{U®T–mpİöX?ÚsÈB¿-ah4Ã­:û¦©UşHrá9Ê"òuå(†mLcîÇ™Px·µ}T&ÍğÍ«kç€½”/”rì¤fuÅzÓ£ñjl\`]‘ä1ıNÿÃ„ Í¢j”ïŒ’æ¼|Ég§Êkã/¡nše$íÑĞp¬U³Û×çáØPŒôX·wËÿ>ˆ©º¶âß®Å_f*áÀmÏÙ/1|Ÿ˜.sÊk^+;lfyè©õSÌ«=»K¿Š¼÷ï>ª4
	¬m‡æ`[ÄÄqQ£0ƒŒjO÷Ø×¯şÌhoÒÁßd:Óóõny¹ÑGl.à‚)U¾Ërw°z|ÁKúğÂ“Âëibkrœ5h¾]‹‘Ü‘	ÿk†'¼Ä›œPIÚlH³«ï¯v™!lÌ”cùGİš5ò|rÎL_JIÈIí¶„ãùu›wkÛ«š¬ö›¯êÓuÉF M7®<J)ƒ€V(…uÄ†ÏÙ—0ĞAh6ü_»ARŸ!ˆó½^bQ'tEÙh«c¶ßÕ\xa@©p, É'ÊôkË‚ôÄø2O=ê*´#è ÌNxÚ‘)Ì[º…HåÈ½×O/æ†nîebMŞoĞÑ›p­Ì¡(wò[İÚ©(PÅsË<.;œL	œ+tÿê¶Àr	6ŞH$/˜†¾]pˆ`ÔWÉ¿X4O» Ø¤•ÛèÁåò>T¬Ïe#bŞúrP3Óà1¥i²'—SŞ„Ì-‰µƒhK*ı\Ò²¶2ªÓ³—Õ\ö:ãwB½ª4é¼—’ÁQXÊ6ıê·İ‰î/-tãŞ;ÛßŞ ^`I§Ná¯º¤êP- ]ãK]È„3™W°´+™ğ©ªØJşLç5V«å?“İ¶H¡’O…Pñáüò›Œ¿³ß›©>TDªày>zs™;ÿxN|¾òï<|HóÊµj®Ô!xî­JƒİFZ±óP¸ÖX6ÒÚ*‡'§&ïp&ÇÇŠîNLö'7S¹fçz‰LUÄˆh^©ı}z!‘Yëc*z¤æÆhÙC¶z›Rx`—5†^ÿÔ6÷¯à×ı0zYü$P"@4Œ_Š“'é¸÷¾±¤ÿçÂn1*CŠ)M’Íİİy•!¢¢K…~whìmÑUŸÃàÌé¡ü.¿°c[]atö+æğ”AxÕ…Ÿf§öjùğ!úŒ`›ü„ça*[ İƒ†€MO]}RĞµ	÷Qv0—È9wÁN}$zÆ™yâƒºÉsBFè’9v¹Ÿ0p{”œ
÷åp•;˜Ş–Õ<á¶qêŠ”¬@;(W¾´B†„²tÌŠÍ{„l÷–i Ç§mt9„ÿ¡^Ò²¼G¿œk©áŒœ"ŠğóĞ¿~ÿÂ #Á%H>lrJ°SbÓ5ò*#Ñå½€Ïİì4WèW«
kJ¶X†â´€p œ¼´nÄ£æÍÓÄ¦ÇrzŒ3¼.l€bGVbÃrÇœÊZŞ¤ÊI¡íÙëeéh¸š¼[?ıG’fÓª1‡Ê±äŞÔRzwws`gİÓdóõ×ƒzü3z[Á9Ù«*¬w€½—·ùüŠj¿ú¬)H¹—NÄ†VwÏ1øy§`}/[¥û¿ !B¾$Pj4QËìeU†mØ
Ş¸ ³Ïü¾ø£‡âC“\¬ïû9ßó®Œ%«_¶/Ÿ»(<¡Gs×p|P^¥±áAvQeÌOŞõú
>Şï
µQØæhäFÃ›–ÀÅEw×ËA·8}L¼óóMğ`WaÚÉg{[W¿ÄÕ„ö×¶FÕ@q´/	÷ì‘ˆ2w€,(-yz6j«-}™¡Ş òã±‰ôĞ+¹1Y“-¶ãÌk|²Oª&a¨0~kU¾n+$‹BYÚšRzHaVë­ú7¢^ÙhšÅhUuzİšï¦73²ı–Yœ$å ’“O¤cÓÿºÒ÷Ğˆ€Ã” ¸×<Â[®˜¤¤wTHñ…zÀÊ1{‹ßòŒ¦,BCV.é403iÛGéÜ\ÏàÖ”šó–¹sŞ*„¾90ûÕåÎFÇZäU·mt§Bp;›:øâŞ40EõqëvÇòœ±ÖR£'®¥ºL1îãé9$!E†m¡¯ĞœâgºûtÀöŠ4jO“[{qpZ  Í$FŸ‰¸D°÷YæïåJ‘>&‹/'Ï˜ƒ;vp'5ÕÜğä¶„…ßå½ËQVªmjÙj/'øËTÂ¨ÛLzYq­Äxÿ¤ŞyTR¯J”E$ÎÑCZvR¾/¯ô?ã2Azäñİn.eşõé‰Ñ–ÃIêIür9Ô×Üˆ	sæC3WGmeÏ?í½:å§¸€™I)9¯ÊÉáo”Ëv*Î>Ù|Ä›Ùd ïÕIl/LÌ-f«6Û]ÚÄ$àÇBbi\NF)|\ó¸&½³SŞø*§0æ“Ùq4êg¾E·¿áÊ/Ü&ù$óAå ÃÁyà›œG‘â¸…Q•èéIÄøÅ™€›ÈÙ»AÔ3õª:ë¦šF­ZTÚò“.ÜÂ¬²3À­Tq›ÆÊ âYÚÄIŒI .;œ‹wj¸{¯~dTõxD_Ô1¦uCŸ Å]ÔH7V¯¹Ûzg75œL­Âá==ÓÏXÓJCúSŸ è¸°aÈC÷ÍÌæâ–Ò³[PÁÊ ›fˆÃæØ‡*ßG&­P—üÙ”.I’BI¶¼õ|ZjŒ³[Äš‰•¹p¢jvè(EÅBG-ŸC+E.(EGI[¤íJå†{*¯|Z üãzy¼¦0œ§=K,"~ak‘È(ÛÍ}7š¯LÊ ÷¿‘‰Bóü26>> ÏÕ¶òØ®¾#7ÖB_‰p!³y0mk„a°
îŒø½ôaEú\$¡Ğ&b#–ÇîXghUÛMü3ê–úÆ§¯'ñ=¦§«m­ŸJoOÆÂøÏÎ’¤Ö)ïoe ™>’éôŞ|××L!ğ\UÅÕJyy×•ß®‡ü¸G[Àg“¶Éh‘m$>4âºÄÂZ’2é´ëëLªÓ7hj(Ìí>ÊÅ¼‰ËÃ;^ƒJ×¬¹hÇRÚ‘ Á¤P=¤úäxÓ™M`^×q®:cWïov¼ij¯CÎ(|QŒ’zdü))ÊFkF±%b—ÍH*<ŒhÁb|ş ^ù0ÈW<€@yZ>£Î',}†ãô%vó07ùô¾ö/»¶W<!+…$ ‰È–Ë2ş›Iû­ÍG3É ”£‹õ’8ÄJE’¬èÅ­(wêsYĞ5æúzE¢£r÷'{lrß?í¾ŒˆXÁj¦jU?wÂFOà ƒRäİ‹»cİp›€l³ªŞ¿¾ÒPÂ„šnÌÖ;UØi.2$·L/í{‹¨·aØÏæ’†cÎ[’«àŠ0{“=|Ùƒ—N¬®Ö
––í‚}€ÿyd©ÍßÙ#bœ@eº¿¨ZLB–Ë×òÔù`9©“›ÍpS±)…Ãİ².„hBZÆ¦³ÂÁ6[	ˆf¬ßr(Hhwf˜˜(;~Ìÿ’P\•Öi®“bìÁzDÄ,;O8qü†€ƒÍ³úùàt¡Ä!bEğÊşâÔÆD
/¿¢•õˆ³Ñõ²± °ÎNRï’2¸ÿlxß¥9üèÕÈjW~±€ £ úºz++e®lo]QÜ|{¦1âtkÿëPŸçq€‰‡\‰–|·ÃâósÚ3G‘Ç’;	¶Êo"A5Gæ/Óë^î¹uxGHëÎµ÷›Ò1Õ:âÊÏEu',Ó„(i÷J‰§£&/£BN’»X4'
6ïá²¿#F9 ‹i*{9EŞ…ú²İ+YÉTÂ[²$f*|«>0½ft!Öº{ï]7‹ğ„ò™•Ïm>¿qqcDT™2¾¦‚Ù1Úæú:>|³o¾p”@²ÂqŒ3S:…ô3!²´ıp÷’wëXU¨K6¢Z¯voÂğ÷àéFQ“Jò5i}vµ^ZNåœËÇ&	Åî¾€D•¾­LXÓÉÂı~ÖC:¬Ûöª
ƒ„µÉe ”§6ûÂ=—x¦_a1-F¦¼Ô&ÉO¾”bdul;>u¬#mÖâs†}#
‰”äŸp›7ùÆ§ÇÑPI~8Çğ‘¹ÃuÿBù‹¦arğb‚õ—M’ÓY]Ì3¡«ÓaÈ{«iã=Ãö¬šk†Z´ø±ßH«iØx4û¯V â..‡²±J=—<5A.ğ‘üe½Tìb±xíUFxQµ†®U
iFÇøaşíÕ6Åçõ¾2‰rM„vLw˜F#!F¬8PC¾;ŞªŞ6¦6ğóÅeª³ËêQ*Ş.íµ~„N3çfÜ0´Àëwq€Š§å2i‘m™Œ İx±ìÒ_OD–Yüğ€å¦OÕW¸u®šæË]œ…BH°U0¶¥
f¾ºS}­­	u_Ä(PÓ[ÿr0]s`2å‰î‚f´3ŞEÓ‹*Nka±âöaÀsËõÏxú‹3H`õC‘õaVò2K¹Ìuó‡€#'8¿æI€V´7Úté4—eN@{
Eú¦¢|Å4ûÜcË3\©p¿Bù÷)7«Õ 2•§f6[¨»hŒ äø…lsÔj¿ä½wİÍÍ3ÖÁš;4/îD•–HXÈ4Bşÿ˜#Té¢'Ú€˜€ÙsQÌWÑë³-¨GÄÎ*¯»¹Ì£¢KšZ÷©89rr&›ĞƒrX†¡t0ËŸry¼Êô%I5’°¤ôü?ß>ÕÂ{Õ-¢Ï{ND) 
±]ãè qÊ¸7¯õ0ìÔr¿ß:(÷?@2+ŒŞO{ñFŒNëƒÜ³Z‡HÍuäuı­:¨æå—ômá`Q[¥ÒD®ÜÇc·şÔÆG¶¥ßÀß«¶œ²]ı6Ğ†jWNœÓr¢@Q¯´İ ók—w{P«Â|Ñ«AŸëÓËı‰qBãº5ãOø¶~ÑP¼Q:şë°7ÃHçyD‹Fúæ²}sNäœ\SX@	ÆÌÖ\:\Ëó¨ .´5+`á›íŠÙĞıC`5—Z”ßoÄ©®é0ıwÑwù#°`­Sˆù:$J`5 š:İÒ¿^€™#(ùá¡å\|±)ÉœĞzÁ%Œ|ãJÑ-£ôøËü™µn(c
Æ£?¿j­3nËOµ¤| ç6H\‰¢ÉÁ	çü3ïê Ùj¯WQ oƒ%F¡$CšöD§Ö¦Jİ»uÿR”ciIOe¿FY Ä£ibìG ²-ÄÃæ£¶5Çmñı°C¤¾Ã³,
 vÈi_`‰öÍeµ±[Ã´ìŞ`™1êÂÖİ\ éí­“kÊ3ÁA,Ï:¡÷§a”–õkÕÈC˜»"j^ ´·”¶7¿iıÁ„ ßÄÖ®²tîPo|‹}×Ä
è÷Z37[Ú"”=á“K<|mó»±! ?MÉk±)|·ÓLsÖ´–çFÔõÉ>]·F§ñ?ob„àÿK>ö=¦e4á‘ö‚ÆB›³thyBÕ-úXTósê¹ÖZÔl3Â~øW»ı¨ñ<¥¹ªMûêVà:™í0àèx¡óSy€·tÖ>bu0n•Ñì¹ß±aiR·LËGI	Ê^áÊQÊƒm-Şœôğ9^`3=HcñA¿#Å-¥2ëá+…ÊÌŠ¡“îücëˆÎZ÷"¿§2"¿ò½³³ğ´û˜öº•rw%e‘s=nÛîŞ!ÕàhºÏ¢w0‘c‘>ÔmLöÈÚ€¼eDCú­ÒjE”·›7 o;¤dèùÈ*¶51|ØÄh¼m4ôÏh;&î&iŠÃŠ+é'|bYŒÇÉÛ ¸tŒ–¢í£·éG°Aôh’A63‰YLø˜eğ?;Ìd’Ü«¤õoKqÏĞ|m¶ø”­Öº›õIaİÅpH—«çç@7wsûÁrå¯,\NÊ„Eö¾:µEØ
¢8ÚEm}Te2àZDdÜ™5Ñ}GÁ›ÃQ,Ú{˜w«ØVä©ˆUs¾A{\z~>/ŒsÃtHïæÖ—ï…‡ Ä„v)U(sİÄªL“§©N›=SQ#/~ÿ†Z-ïÙKÈŸÔO€å›±.÷U¡ÿÈ8‚V8ı&_P±®ÔØëCôÊ‹9E:^¹à©øWÚÆ4Àô}WÆ)‹8Ì}“MV«ŸÊrÑ¦i¸GA-ÉZHÇ½Û^[ImÆ‰G ï|Õ¡"iK^ÖÚ¹DÆÈ¾¸¡‚ÜN™÷+G§¸#ñ/áëMzÆNİA¤-mcm+†fÑÍoŠä¾ül~Åì…RmÜC´¦yâTù²)ô¸Ø•Æ UòİLõï³¦à§.îU¬Êáã=;˜€¬¦@–ÖpJ+–:=ìPÏB]äò_}—!s¬e˜,OPdgÒj8‰K,EMcKˆA“íÔ—Lf#ŠTrÛôsQ‡!{!k;ì™X}ÚÚ—¾S?N zÅéCÛ1òó–`ÙªòÜ¯zG–ÅF]Ğ`?[æ¹åÌM7×—ë\#“ûÑ+~//¥Qªxğë«Àgı¡lã ­k4Ü›aªõ1ø.±åR|ì:°–İ¬	>#ğ&è¾¾ŠŸá‚Ğ]‹­G-p¯8%2°©§b¤çşŸeC_“
 a‹ÁÈzôBÓ}bn±€=grEŸÂT×<o¸È İQl°Ò.£ó\X‹±Dé¶ëì7"©¸ ¬°+
èR‘·ãò¨k¢ÕÅ €·P47¿5(ŞaŞšB àô¨&8§ŸP†É£(„¾²ê¹„f;tCŸ=KÆ%Vô³Íe¼Ô¢mßöôù+Ë±±NÛ67Ï Îøt-ôİ„ÎÍ“@¨évám–I#qyPàÅ~~#|=+mCZú0”e4?ÂrfŒß¯<isôŞl@‡ÀŸº—»ûš:‡ú©~•÷§¢wÖ º#5%ôÎlë	µßäŞØv:’—²`Púÿ–”hÑÕQÑÁóâ/”ßåñJñù6³+ˆºÆÄÜü¢ÙFà›•§ÛX.Y UGxˆò]Zq«±ç[PëÑt4°¬Q ×.ƒp÷u¼‹²C°Œ:D#™=ä¡O=yl„O_ Liß½ªIxğË+rÇ\ŠV@b<¿×®NßBÏâv0ác)©ògk.´;»2¾±GÒ?î-øˆ½‰ıÁc9•ë:¦îÃ9äÊQ<¦*¬¿I‹õl€gBÌ«/M…ræ%ò”ûÀV'7ÕÏsœ‡´@ÓæĞ¤¾¢ÍS°Ô ÓYhÛù3ÎÅòİõ®ŸÁGQ ±Ó¯\&aÅñxÇeBruÖ£W	ìk
qŠ´?º%ùı[	İÂ)‚WhS3†â±n®DÖ:Mæ{³nuvñ5k¯B€NÎØ$ÚğwRO!BìfÜoYªü–Ş…ÀL<®¸c|µCâ÷¼6].¹-göÑù‡TØáõøÜ°¢*Ì6PíO*˜~z 6á~a	CKĞ¸*\—hI•÷ÑLçÚ¢¤GtNçqİ~èIs¾j[…ÍÈóoóÕ×7åÆ5X¾µ"94”ÛD£¾½`##gŞá"á}ØN3#òƒ„($]4ÖLãúòWV¼÷Z§k×DŞnïqÃbUÿÌWZÃÖŞáå¡Ìâãä…ˆnk‹àÉƒÍs¾ç’H=·i\¶?“³Bl8Ôb5ÚÚ¦µ·zo
FøÊu¸ÛRî˜ıí#… 2I‚ÛÏŸÚpë4'‡®GÄŒßĞîˆÅš3‘ªü‡º¤„Ûôw×8o*ğ:§«È“wF§PËdŠ ë{¾¬ÜQğiœA_¯•<1ş¾“¸=Ht— K¦¹[%˜†›ôv‰æGšK”Ã½š`„ã½Y9*Ç¸Wıò¬ú\Ÿ{W¤ŒluÕ‡­4xÕ­ú³uQ>cïkj@BÊWØ˜‰¯ŠrªÄWã5‹WŸ WÃÁ3
'"“MıvºwİıBû€Q¥ÆæGO®ÈNÕ€ËsFl·¿9şè*j	@¶áÁrıÏ
ÿ‹^$¢š“²Òoë¸0‹E_A°f)úwÎfŸMÏ?$ìÑÔyt$6ç$ƒnQålm»di~lM{ÔI°ç<Â¢˜;–àiEeg›úşüŠ‹æc­²
»H=…èòÄ¦Ê#‹¶'^DBôƒ¦	ƒíVºy-Ué	
‘uŸ>Ñ:¬Ö
°¸¶Æ_5¢$½âÚŠ_ƒÎ0ÿ§m:—¦¼¿~óĞ[5nìÜ\ÆGcõ8‘Á·Nşx/ {õö+ƒ£!ÚvÕ;sùßÿƒíhh9áG½ª zòduÌ¾Íû¾ª­q+8HÛÓFìñğÈ.¸âPå“İvıöUªVÒ%V¯ÊU¨ñ4šrMµ+c‚¥÷Ù>³’ŠMb¼Œœî³yz^ê0hLqjÊ aU§· ?»¡€ImÇfê÷4=e¨Sê	ü,Z+ù2‰±†¨Öşëôjv©_î·cv}Q€S*Yª“}<0â±FbÃ¨JªÊµÈù§4G‹_åYY4ŸŒ­VNñ©– GıÈ’Á}=3¸S3Gâé5¾Á9ÿeŞœÀ¿OM#¢:˜Õ—®NX?«’+tì~*á£‘ìÇ…ût9Xı½ÅÓèÂhìÕ½'y«ŒR°±îû¢şùi×WeÕ‡Oƒyg Ì­ÉW‚K×±ìi§lftˆ¸¶Ô}5*ÿĞÚp‡eÊÎ¿£—ôîv_Ó0Fö
.œâ\ ¢*´dPäì´Èm¼75Éßı\Ìtrxƒ¬u¸‚ü%÷ÛÂœÌˆ4‹qØéÿ¡ÅùÒÍ/ìKäyá¿«BßÁ—«‰S(”vŸl–İùPK¶¨ ªPìIGS±!†ÀÇ#åùıú'V›09ë£ğo¨™Ğß	FËÛ1PpÌœÇkÜhU@~“»1yñ¿ıŒ¾;í9RüçõÁ¸ õí‘¬N×ş$7*ó/½„Ã_Ón'Mœ¬y-X7Ü)´`º[Î±L~PÓd(Å@| °û„úäÕ9´'we4¶_\G¤-ı¶÷¹»rÙ¥Û¸—¥ô® zj® Xò™–+-œÓÒï@IA6Ó¶ÒükÊOšLjBuûµ8UœwôÍÈú>¯>?Y/´6;œ|¨=WÉQGo·óB‚ß…Á!İé•¯­1dÄt6d•%rE„«÷™ĞdÚ¦à¶OÄdko-\@åÒ_şbôe¿»üS8p1Ú0zK“:$6İ(eê%1´1­Ämªb\Zì‰k	(3Œp·Éà€s›ƒK—†.Ø>pª ­VEß'Ü³[íØ‚êg'D)íIĞcòïbëoÿbÜxƒ´Ş%”G¸JÈ…=ñëúª»ZèGœÒ_İÀ*2!àøÛxS=ï@ÕL&>˜'’9æCÑƒ¡q@BµÌÜµs.(•Í”gÑ¨I¨[d.I‚4ç:òy÷.lØì_ª–ªs+°¼
×¬‹çÔ-Ÿ©Ç¢Xïò^Ì£¶lfô@3÷+òèğ|éP”jQÔJH´12ô.4¡Á†B¡6Àeø•™Kê¤û5¤Ä5i&?ufÖ‰ÚbæÇ—U¬	N‹õêñK‚TÑ—ÀEì†¡·…Añ	|n²ø|*öÅOùm7nçdk34[´h¾V+IâşRXŒÌYÇsHš±|æ í”gò_ªê–ş­·PÙâ¾ŞÅíé_èg²E¾ÖhÑ]ğ·}ïE"3‚µ-‘Ñ{ğà÷OÔj™¬Æ¥{Ó(Áµ«CG°V)ÊM{¦`_ğ48ğ±’ó'Ì¡ğùD—wZóOí0BCù¬TH
½RgäcPDµ~€ò WïöÌÜ"±‚2DÍêtŞo(±%ó<<dP´"òû"~O /ÊîP‰jÕs\?»0äÎ:xm?1–
|Kİàø4*5¾+®Cö#2-ÆkÃ€±Ù¥Køq©]ã«¸-™éÅçä!ˆ»Ş6À{ıÕĞªš5/Käc˜òÙîÕ.ô&½¦wQ¨UË½JÊÚ–0ÅÁ´­[Ó¢“`u8£˜†› <H²s'üjYŞÈd{áìV™æFTK`ÃƒHŸ !ãlN4€ê™³nŒBmmÀ¤d4Ò8G@:%„XoiØ€.ÀúPj{§è],ªÔA+³.ªñ`4ƒÊßc•€€ êg
™7d+ßxSıë¨/M÷›ˆB%‚BÑ$à(IŸ:,Aàîó_š÷›ÅóÒ²
éåÜ³Eàj7PR$	­¨˜Ìù%ÔT;ËÁ5M˜¿}¢8×ihN…Ì·¾-j‘˜ëÚÌ8%q=z1İ„Mİó­òOX:¬¹ÿ#ğ\‘õ&Û¼$
×P)d¶f9½Kp¡?‰4£æ‰ø‡c©²HØ²Ò¥Áj¾@3&üMG1ÛXŸİ$é•Üşµg§üˆöªè°¼¡ô×HUø3TGë““Ì,ÆW¶·fÛpFu3°nMa­½1r³i…˜ÄsDƒ Ã†…kŒdâHğû©½ş¬Ïó>7ë˜°U<±ÚÃ®“Š¬®p+yšKØL(ğ‹I!?6ßcääş
§	;MÅ|æíêV^dY]¦·6pSB¤ÈGD_÷æ äG£hgÏ>R~"YV+üæD’"c]rNK^Î¶Ÿİù‘Hä 	óÿ‹([»;ã|½ŒÓë{öå(´‘&Nâ,Á·¡Cçøâ6 äMÎ¶³ÎµV‘ØzX“h Âq hE”5&q•¤ Pf<Üûˆ^Ïİ( °1o[†èVåIˆßİU[1q>˜ŠêÉÅòæ:3jÒ@{ºÛ\¤°3@>Ô½åGÜ~aQOëtÎÙ=HD<ZãkšQ¤?!ºì“ÿk·EÂ%[®1„ÊÒ€@…¥SÌŸD4¤ş4gn‘ußdÔßB&‡õêIü:Újı²KÅ4KŒ¾5ªæa	`¨ëRØo¼:à»­Óam†Êì5¯Ñy"åÕ°Ù5"x8M39*ÈİŸÊşRY¾ráOë0í3&µ’ƒîgˆÌï§ôíI^30¥µ¶…‚;ÑšÇPš‡ÍÓ#kŒZ«UsxïÕÛ¥…l“¿Ü~A±O›—ú	$®‹iĞRWö€•3ÔÿRÊ˜ân‡qX›fV:obşB:RaLŠEõÿì‡°.Æ´b  U» ¥¶ûà€R‡hÌÔ
+,ÓoÉøv À‚``¶
mUngN’	N×¶”ƒCJ“äu¡P¨bCJ-ÌL®ü¤ÌY»+% lµ¥‰dôöØÅâNá1Ó_enLğì<JÒyİÊCÙ*„Gµ ^¾ıÏŠ>Z“^`ÈÒÇ<fíùBÄD^ár°kxíˆÿAR!†zd;=ğ"¸M¤‰.õ€x©c;!…lòmZ–óqS£œ	³Öú„ ÷Úk¨{7­çÉaai|M6Êj3“f/½Å®‹$I¦•!-K€ag†ó~ğ…ÔH³şB·¿h6™| ß\ÏcS‘<šU€Š£›&ù›`J©w6~–Lı]©¶Ã”£2+sÖ”wl83z©y–øÙexg%¥Ğ<-­;rÛç·ğõWe-\Ê¦çİf{Âãs‹PêYÿÇ³oÕÂ~¾E/pÂ[ÍŒ·ÄÏÄº57¨?•®z½Æ`¶
µ&.«t¢g²£‡ğä^Eàõó.2=ç´S˜Ô¾´Áõ&-ÒjoÁ–İ‚x\¢õ‹İ¯!S¿ñ°N!¹eÚÏ’¼È*Û¡Ãş@V
CÖqò égÿi»ªò•4¥oì¨3ö?;=ÌÃts¨ `‰ˆtÃ‹/“û›z¸˜Êºğ÷kÍƒLM.'míâú ½ï€o<©®f1Î5säó<fê•Cj¡Ğ¦u¥çŠ"Ü7‘6ÎNíu]æ1©mS‰,€N©!Š ºµ%}+l—e™€²´1‰bŒÙu>-•›ĞùL ğ÷I¯>ŸÉ¨¹Ù³ªÄ,oşkAÈ­mP*Õ`Ğn0·Å¤ß-¥#3åëx‡¸¬«Ã{xkŒ—W"E S–}ˆà–Œí}Ì»CoYœéVl¹uåc.Èì©HşH	8naÄš	¨øà5¦Ëg|9‡]©=Áj×%Éê®y’íCÉ¿JF™Æö‘7€rÖÌ‚öÊÇÏ¾¶÷Ö·h±}¤ø [çõ+{é#™œÕÏÈ4hÈÅ8ÌeKè£¶lëoQ'rƒfŠ—7²ÕWÔ°Ù1ÿîøßãÏ†ÊTQÛ0rx¼†~â9Ò™šé–^ÿË*”Ó•îëŠ	–+¤y¼ TH¡
¢Ù•ız3ºÅ=–kË£_»¨ÈîçOVHØ‘åÙ#ê•ªÆIÚLq€a‡ r´/™5"=@’_ômºíã±·’öË³#bôû§&×–Upú¦m²¨/ÌåO12²¤¸BMËı“Ã~Rë8Kš]®=‘^" lù°áf¬uÑAù‹è{Ìè591Ÿ¼DÂR.N8E ó«¸7ô…FÎtG>ÙrÆ`.º ¨CôĞ—ºãBAkå‹¼Jœ‘ È'ÁPê‰ØcÄÃ„HÅğQšŒ‡‘Í{K”•è°¸umqÃ+Í‚ˆé¨@N½Ë Öúü$¡³g
ÌR/Û•²BE`töÉo¤#C†ñ¥/cÄKã~cI¸uîKØS/Ok% ˜-.VF^ó*ì%LİcO	¡8«<5,ÿéLH¿·~µâÔ£ø¾jÿfï«
ÖìÚãœÅ@v×ÑÀ•˜óçÀnğÁƒÏVFJ„tNoJşÛç­×ğÑ÷[uñÀt13æIà¿µ¥ŠÇ• Î¸/ĞÃVBü†­ƒ"÷;’£‡äKÈº›/aK{Ã3¹„ ;‰­øuo|àS/ï-ß0	#Q?~Í—m¬8Ëo|3b0KTK)zv¡p®	ø2ûVcó¤xã@½v?°³2 XşQ˜XÍø¦ó*×…ı½¥Hğl
¹4>pöXÀNI6ç˜»(tø¯„şJö«›á«»Û<ÊŠñÀœDB}¦4h+BÜ›ä`	ÙŸ>†o±@4P¿fßC€Z—õDoB	ª´#RX9a<pšÿ€ª€`¼–$zÎc×h´ö%Ç]H&:«­N·¾1nòÌ‘ky6"Ç«Á­t~ñØ–U
rRû2W4ãlÀÿ±ƒØc¾ÌÏ•ÍÀƒÁª6^Øôl˜¤TÄIİ !Ğ¶ÏV§ÇŞwöŸ±WÀ[Ì–:áÑW¡‚PìĞù£ó"YqÖº]³d/Xí\Ì5Vf”·5¸Äı÷ÏÌãq†§êÆİæ(™ÓÙqh.tÙÌë&\s\ZãöÈTP¥?
.¤@²[®Îùêà·ƒĞ[ŒrÍğ âäd•¡s‰>‰Sÿ~]Öo²_-Ex-¼ªóÂAt¸X|µJ%}õ¡BE¼HÎzw9E¾'úïôÙ?¤Hjç÷Çª™Ñ\/:ª.º£Ó¸–’Z¢ëˆÌ{w:±ÈVZ’ÏgÄg~F»‰¹)W¹háÈéjnÃ“4`1‡Ìøò#OÉh„vÙAqV=Ø±Ğ¯*(‰i.¯9Ñ€ßUyŞº¶2§]nf6âUÿ‘c$¤Ãÿ3¹söœ²¯p§îTDõfñ3Qiæl	’ø‘¬`í’"›YÕ¶¿G*ê¹—T…lìÒ,Ñ÷9áŞ]=jPR¾êE×£Í®wre*›¯ã²k"^g¡»&ÊÀ×ñŸ:­Ï¸°‡¤¸©Å2SYõÅGLOô{(§m«åÊâ³D˜›É6E:=È€ÙVùÄü¤âgi\è÷Üj¬7{IgÊŠEÍ+?Ò/Ğ1ëğW»IË‘„¤cÏÏrIh¸oÔ=¡xÇ¨Bn@¢¡Z®GëŠ$¤CVÂó©Œí¦McÑ É®Ğï­Š–ßXU/ÑJS÷½ßáj6@nõ¿–ÅA)æ7Púi+¯ñEÜpæÖS¢ó@ÂR$–Ê^hc«¨²úê¦ÖEğA–WÈ„x—m#Ğ6SvÑ-¼Çr:;ÌqåÌ8¹ŒD;[,mj0`i…D¼&mB¤I“B^qct®ùÊ²Æ»ıüY*]ÆóI~Pqš:3¦VÍ'h5sóí]Ç—ÿí6¼íŠZÅÜ¼GP¤¬(±xå(ˆ,¿…^NâóF¡r@±ÑÄûÒ¡¶ıãbâÓgf›áZÉÜE`?YoÜ-¯ü`Hæ©ÇOEVÚå "îö4\Õ«rÜ©XY²X Rëb7×Çâ!µP©Tµ`ãÁ[Â2ïmÍ-)7şç›|£ñÑ§×rÄÃ9îŠ{zÙ‹*XåğrÄ[¥ˆRÔFµSs¸Øß”·ÆèT!eÇ6è'Í4°É¶e|ÛâáŸGlÂ:)Ø	úº&ÙûT*lÔÈÔk•QBĞh“’²`,‚½f*(trlÚœ)ùqzÙ¸ã¯ŠüT€|¤¯˜ÔføµîÒg¬‘Í±°@B*HçîÃr?³6dü
»½÷Ô£† f° $3¼À×"Î“Ê°}UîR½íiÙ	M—FBöG(xjã>·ıg»ÒÆÏ½eD%İï*©âÿ„ŠYGÜR-vÍ'¯¢“>a ı%gšøÖöÖ^åjm¿KÎØZbçRûX™ÿÌH’ZA‡ı_­Ô„
²2|ŒHáÀ‰V+ìKÂ¹ÛsÕt°½f»“™¶@»¡íiË$ÆHQ¿©ŒDïFÍƒ¡¹—ğe)u:î/™t×õä0¨èæËª»”6±Ş›'ãµL†å+Në)ò±1Š7Yºô øµİ C®¶ÂâXºœğ§Ú„ìl;	UO¨øÏÂu‰úR/Ù×İdd+hã­	‰¼hj¢!„ÀoO‚}±^“x½x|÷k¨cyI£İ~T>§÷Ö†RWôùI}Rr2…}nä“¢h”0ñŒm€œ¾È§ ?÷¥È.Õ-†æ^Œ2ym÷Œ"‘ò£ÒèÕ8^ó·FÃãÁŞÇ¾‰
[;ŞY‡MñÌ
|Ná"&/’²*$%¼9<ÛÅš-Øs^.ÓN¬z“ã_ $”=â"yeª`vàTh7ÂRzëólˆWaSFƒé†.PdÁtßCo‡@‰k^MÔ|UvÎ„‚—àÌØà.1x€å¬+İ×N”ƒ2Ñ‰&“ğ.;a¨øCˆ¿ÿÃªÔ2^·ÀeŸƒ'"øK5 ‹¶!Ãÿkj 
àÕcrrÍúê…tĞ^oÄcìÒê´ø¹TØ˜±^çyŸŸ ‚¹æSÚÿ©«TljaAã1_Ş•mLp±y ò¶?ÈÄ$!*Ì'8ƒô#Á\w|Èä˜E@Û`¬Ùs%”7Š)qU’÷&C4TÑ\PkÅî ıü~Á°"^ÿğ®ë­Ø#Ê)øLÃçR*®.¥%RšÅH´]£”Ïv
«ckµsUaÊ‘¨‘ºkÒ¦m ¶®ÈI'–šm>jµZ N®ƒJ„á †E3£¬ö²p^¬Õ`W¥¿l_×5¡š[=‰ÂÒÓœ%>dt	ÿYö ½«’×”Ğÿ<ÌoÍÏıı2+d ´!Ä¨´áF¬`¥£s-Ï27qn›QŞ¸I0=Æšnl
‡¬hÅ‡²ö÷ô[2à.k
"
¥"õ#ôéÁ:4”%e«ÇŸ¼¼q>IÛ–±	h ±·Ã‚…ÛÂåú$Q93¥TŒCÉé¢&ÎK$+ÒŠÁ 3ë„•GĞ«Ç'µ§«-€‡¦Ï9DUd;>›önİ)«d‚åSm"xé—Æò¬›§•XÚÿ8|F|ÃŒ[¤•ÂÜÌušõº{ ÙU1ôEG+µ[¡—h*Ñc$÷mZàA‘OŞQ¾JXçòX‘f@·`¿ÜÉæÑø|V10uNÎ\ÏsêıeÑ€[”RÃ'GÎOQà‚Ù”È1PQĞ’o!ÉxJ?ÓõÑ—È°ÔØ½4ïİ|ÿŞRú	Ñ.”êKŒ¼„§_ş‰O÷š0å&G)Kñ ›¯ÆÀ“OW0ãYË ÑR0QêY½¢³Çé÷Ä·sôİ F= èyÕÄÚSÀºx)qìÈÎJxE/¬Lê‰o´¤ğe°«ºĞÒxé`…BÏxiá®5\7oÀºdéøĞ_À†‰;x¹Ä{”–¿oÌ.a«î¸ä?5é]H!3h½ı²Sˆ©™5Ôv*ï¦Æš˜kóœ3Íòí°óeÍé=ûùô€¦Ğµòzˆ-S-:õ?3Œ}Ê ˆùÀÿÔD´ ÇXbÂ"®<c#÷£~Éÿq–÷í³poÀ}şªk'¡ü‡äA²W°‘ÑŒE¹ê]ÒÒ¥Š’ÍúÉÃN%Š»c¯"k\ÑWäTŠ{ÓÒ$„BœGï¤<ôI¤˜Á	õ)°5ÕËúñ6†wÎPé Oš¾³ĞXgøèŒš( +6é[Ö(÷Ft—ÕH‰¼•©0¥… ·¹íÉĞ	?«æê69pî4;· [v<±7Ä?²í×kïjèDÏR! ³ÜIh W
Ì«R¤æÀVcgÂ©sÈàø±"%¯YÍ•{Ca(â©İŒ ò)²¯ÿ;x©\ÓµĞÊ¬°§µì±óağ–K5,ñºV²N\½	 r)UšÀê>B£æ&Ë:¾²Á©®yƒJ2Øw*´ë‹…ŞÃ×ºïQ±{@löèn¥ºĞ¢]m™x°mÀ"î`sÑlˆ¦¯û_Êq©‚Rm­ÏÈ[ÆÌS%vŞ±Ë¾ªB«Òè—-ùAbØE"õß	àãï–€aØ~§¬INÒ›Ô¡ˆ(†âYŸD1öz¢f¯ûè\ò”ğ^şÒòºz˜ÂFn€ş38ÓøLº­N§×S£¢:T‘ìÂÔö‚–§Qà½3.‘3§D`4WÙTC›ã©_)UÔN…¥emJØ©£\¤æˆf¼:¯’WĞW|}v·Ş+’´ßZoâˆìãN²P&$·)t…šÚª…DùA¾şZeËuÿTû¶n÷JÄ1Îªœİa@»ÂŸÏ¸„–jrÎ„qÚÁ&uô±â1*¾Æ¶Åtê€t‡–Æ»Úòï'Ó5éì|šä‡®íg°Éñ1|æªr Õ¿ÚLGIj+8[š¸^\/JR¿ùaôéNs=`å‹Æ´ÙCá¯’£+ê³H±yä‹N¡Rñù¼Ú°<>£uå'ŸÊİa4Kj5µıfNÜMÛ# îT†Ì]fdvXÜdÒƒ5wØx	é}íğã,E¥{Ü^ü»ßª‹~ùŸ6¸ä:™ØŸ¸ÃI´ƒ"`†
­óÎ¯óŠ{OıÕ¹ÉP¦³ÔıY_@³¨SÉò%_‡5cg±-…P~&øŠıISÒüZ¹;yT„\;‡-e•Æ×ÊêÑ‡³nz6²M{Š.Õz¦ë…ñ%uòøt-qCÓv-‰ó6ªèÂi3k–´’¢rZZâúå3yÀõ8w&À$“ÒéçÈaÍ¡²Ÿ¥0kƒPæ—ÆN¤â cb­êì%Ï—ªèŒÀ÷³‰ êë'QÖ jäÅ©‰	’Ÿ‚“c:¸N…s-¾ -5l¾t‰[LDtöÇp¿yÂ=«ê¥›¢™•©å¢‰eßN"2Û“45Ü¢yN§Ÿ zd¹+¿•H£¡S5)—…®µÈY8ñ‘j~r¾ÈÂÔ4ÊS´„RzyZæ˜_:¤—1Æ©%&eQÛc±‰†é~~4£l(@ñµŞÅ^D‘,>úÌğ•‡È•Úö6öÊX¸ê:ò+¾>=£Ü7—I/©Î*¿Œ~ØÏm„k~o@sÆ¢à´iëmÉÄQTW^„e ^N¥£½BqØ?¯ùË->HêŠ>oıø]ı!N…fybú¤¾ƒ†Ò…„&6¸Â ‡~4Hÿøö<éõ‹¯EŒ(Ø*ß“î/š$C*ÇÏ()rûùİiÄ“ÍÔÅ%­-eÇ	Ae`Ÿy_ÜSõsÎ|Ù.Êe« ½²Í!N{Sƒ~ŒVÃ´å‡iS"é¾¤ÄÄüL¦£}´¤‹›à‡àš´=«ŠôTAò¥Ş^³$i.%ã+yÕ8LXÜ—x¾êo] Ø÷L#85Î¼t§Ao•Óå1‘˜¹Êm“`šÆƒ)væ±Š;{:ö‘U¼VŠîÓŒÌËpÿyIKÔ÷ß fNÁØÎY«HRkPÆ(¸ûPØôà\Hw´%PZ¹Ü2w±hı±Yc¤Øü@¹P=Ïº-dëq.Ûı(<\Ğ·,u¼/–Ë-†"®I0Â#œÌ5èqşLlsv%O­%	eLeìß Ş@‘O6 D"H\~>±#|jÎ:ñÁy{ï¬6Ï®SÜ¬#ìaÀÕRÖ¯²s÷äü¿°{––(3úê lkgˆk&;}ª_‘cÏBÖüåÚÏ¸Äú Ìs#Z…Ô6¼I$SZ0šDİP¿¦!Hk5òßÚ`ı]º—/²‹«påÿÛµÈİG±K”ÚÆ {i¯8èÇÀÙçK¶	ë‹*cú§³8%¬ûdTÎ‰P‰ÌIB¨½%gˆ%
'³ùˆ¢O²„§ïR¨²ª§Ü{¯N5îÖV\¾x"¬~ğ(d?IàÏ˜‹j¤_÷¤ã$xŒÚà¬&uş?)îêÅÒ’£*€PA¡›}@E¾6Ù5aİ*:¿”+ñLÔ•¶9§î–Í<²HD‡
¢á¨c®Ûâ¹şq¯-¥¯g
´ıï+´‹Gv*¬½vrŞ¦LªnĞYĞTægoÊj4}sÇèL6çN];•Õ*B»hSåäMb0,HÕÀŸù=Q¬Ù¿ƒ6ÓÆkÊ¬¨‘`ÄïPÒ
H&à÷×xt^ –Z”¶Ôò€j«^ïäNŸàÌ‡z|ïQ«Â®ŞÂŸ”q¨5öŸï|òhˆYà«ó^û2¼)ó*qF‡yQ±«zÔõóVjp½‹üê¼û-c‚~ÔØs(#XHMápPJ¾riEb_qLÿÅ·C`?(räÈ“ƒÚê g:]ábƒoÇ
ï¤ñhàP_*øÊÕ¢C]¡ñÕyO
>º>$'ñ!Š…oòôÔòâµí‰¦Ïª,Ë‰QÃM¹¬DpËËˆ°­Q¸C
³¡¥íŒ'íG¶_d`€7 Ãç+!¿V‰T€a§š% óˆ˜uSBÆ:lV{Œ/ƒ6?¢U—z«
Š6˜ı ^wƒ°´ğÃÕXñ‡™3Àà„‡5“gvåİ|A[Õ'5Ô~ ‘ä—mËğ"çWôÒAVM»ï½ÊOr	QÒ1Ã&2;Í8	S‘H0z'ÄoŸƒÏîŞ„'âÈ9,énL1Qu'3ùJ×çl³E4"#ÇÔİ|C6ÛpÑ½Kj&–fjŠ»Ğ‡ï,S20ŸîGí©®Ií–ğV³7´Ïg[Ë5Út­P€°4›$tÚM¥=Q[­Ğ¶]KÇ´#Ú~F+…í­ãy
Œ|~°j|]®„Åõ¹2E;Ñ÷¬àª’ànŸÙKWÛ‰Ä…Ç$F°vÕÏ…®®˜Ë:®ıìò€­v‘í¡W	z<•BeÍñöÇxt…A¾Q™itıv¤mê¹	Ò¸Ny@j„Tøì‡ŒÆÙköW&%úÁtNe+yDªXÔÅ&ÃM®Û§:­k<±†=$¬N²"dgMÄç8M¶	ŠèPÆœ|BÙxq¶ˆè\ª‰é´°ˆê#ë<)7Ì÷æÛşŞqÛåK›Õ•b\£
r8Kšm ’îùtê6É#f³å¼5h\¸ËbQäÙ›~“…Å7/Á¯6r.†£m(jC˜ôÅ¬»0)«ÚSëzV…à <hwşÉ­šı{3õè&øñ,õ†`áO®G«L‘|7J‚Á›mÒp0Êg—¥L"¦†Ü7A›LèÎq“WˆIu—GHqíQrßóÅ>3§ıììà$¾Ì µÄÆ?ŒoTv?p]açÃLmTĞAÛçú§ÚJ•¡^{’íÏ+F/Í	ÛÁ+½³ÿLèĞ(PÌQ†‚k¤½V–‰`½Å”ºñVë+äÇu.Àc”©Dìa¶§Ù4:o
{ló’%@vÈ?z»Ö±%ùc^ñ-eeˆ˜æÄivDQúE I§Ù4jö³7Sµ~'Üİ›æ†<èÂâÍ›E¥/º$P,ko¶G¸ÙÁ`½õéL'şëc#Î/¼­‹~)nD÷ubìrª‰4Ÿ7IG©µNkÒœ:ğ_»*ŠÆ=_L3-È“Š=²ŠZKè¹%-ÚY¬ tÿšT½²Û€g©eKdR|İÇ_xzØjiæ™ZÛäD-üú¯+ºãÊú2¾W+¤¬-ƒGœÑ.UÔ(‹‹;ƒ] »ÄÅ}µšxÌÂH6Üô&?ßÂKÂsä«ãlãruj¤ôf"Ç²²‹ÆÅ»àHšİ(¦áèÆåûÉÔåYÓè<ÚW.hÚóéQœHiö5eÜ´.Ê[Nú¬â€Ÿ¸ÆD]„¬Òİfñ——À-DÙÊdı]š‚ñ*åØ"^^£ åkî=üà^º|1hİN¯fñ¿>Ù…èŠ[aìVµñÆôhÌ‰÷Àãlg}yØ‡02£‚Ö&¶xQÀĞË‹1[F¨>x[ç«ˆ`¯QW¯¦¿6·*y-XcŞNKv¤"ğB"!Ú¨ßE•®n_¬ò¦ÏªÂİ,Á´Ø=`¾m;6ÚpßB¹/º-üöú5¾Uq0ó&hïN–TR8ğÁOuŸ,ÒÂÁ3Sü]şü×™õµ´tØel'ş¦´‘TØŒ{µ{]yX /İv;\4„—Å†×ÈuÉy¼ßBâ&énåv*m…QÚ˜å{`U%‹àÁøÚëÿvSíÌ˜„×;3—6äó­Ôï‰ï†dŞn*ßÁ	…Ç¬_´óŞ•ù`¾6“e[Şç§ÚòÁºÍ~¸í3CùSª“l9{ÃGí¯øƒÃ°¸"«şLËpåyÆ¡¨Ñ´N6PæOÉ	II3ŞR–äÎæ‘—X2âî$D¢¡sRA]N·x‘ŠˆÊÚ”ºV?¦;®ˆ:üˆn›}J_ÃÂDß‹P¾=g¬³sèeÍG¶(‚±8|›V :ª¯šâT`­™E‘+BE ¯çCy:õ2²ü„ÎKÕıßC\120c]†|©8fâªÃ9^r!•|¾—HDôO_‰ÂÀ–}2BÄıø	ß†6ÎF‰#û.ÊaÑÂvŞ§òÚ$-Ô	W›¡5ÈÃª¶XVäcÖ”ZÙ¼uFÌÅœ‘†àü¬5^®“ú(Jƒz·&¿SÕJàró‹NBaa/M9‚îxDwã~òvê­e].ßB²ğÙ¬0c *¼[”:I/W,4€„2Å³±i:WèøœŸ¯öÇ“~Åb
a6Ù¢¿aŸÅZhñWuÏû!(?H)¤ö®Œ{d;&k-ƒşÖmqQ;ª‚s2Ìñ]”´Nx­‡Q»ß·‘Œìá)}	Mè$4Òş°î>ŸÅõÄy yId¹uS¶ãÌÖæ¨™Ærç7h÷m6Àşd§ãMzf8ÙõíU +iYÁ>~ YÆø6%n]N?$ÒYãqá~(øı|Øç|EkÜq,\Js!¤®¤K£±W2X^Ş™Šp¥dşÂ	ó‡¯/é¾Å°Ë­ÕÍf/!§zKH
QjØ(M®¸É'ñà\V?Õ¬ê¢½>Îª±öÍ]I!¿Nù8&àRB>,àŞ~ñ!óÛ§s"s¢‰#GÏôÛçIÔíâ@ğ¶Ÿ<Eİ‚ƒDó7ş”¾”ŞªÔøì‡ÆÚ¼î´	•£P~x¼®ĞÉ[iœóú¨®ãìĞåA\Ë¥à.½‡kä5ßi¬6Ø„:›¾eÌ~p3CRKÚÆ¯ïÛNôÜÄá#/Êö¾Ï,c—›F;Ï©<Xí™–6ëC×Ó®ìqìåLxMc2Aœ…H®K$+)¯	K&~„?Ÿ(äæËâH1Ç¬ÁkRñúqWÉ<ºz9Y[2ê!KÀ)h6NQ•Æ{ÚÍëîØô¦¼).Ac-ğgægùîö|@3âŒ~ìÏÃx{´/xd",ğQTğ±‚íÓmÌ‘‡/Âäà´àÿ¶ğ§.®òñOmÇJfw7_2kayd—|jfr›îú+„¹Bö·&‡XwI…`¼^’,¢+ä§ó5ßµÀRhìpĞÍº¬„#G%†–ïœXXOÓÒÅø¹E¶£1Qö†}}<öPûí†Kæ‰8¢™ŞÉe' ²0{Øq“ÆÊ$IJ´D,ã_á0{&ĞCëØ c°\±Ÿ7ï×&°*7¡?{ˆÀ_R§bˆB³h,G½¼ô3iÃ-ÜòÃ€÷6wZÄ˜±y;7ŞËğÌÑ‚ÑŠïfì³ív‰©û@^*“LªuP¶|B6Ró–k¿!ºGÙï]»iI€–	!Æ9N3­ş—JQW:€NK/Lßdß­á«`ç<ï£ İÎhR«Š¨ ËùÈı¢¿ĞpæñªıÅÔ”‹MÍs7•QdSaîÌà©8*²1PïSåku_ßëàEª¼8ºœ¯”“²	.­È#ø‡”dL·
§§,Y	nÆŸyDöËn°Šš«Š?éıq]—µÌi}sàaÍ×ú]½•N-p~‘æ},ºtğõ$K}hop^A\ÆMp€¦GŸqûfí¾ªO²jìª#œ”ü>qÖÈM#Óˆ3Ùn/¿<ÏÀH
À}“@Ôfş+Æûà<ZÒÁÁÂ§ÛO•ÒŠbj8a4…×Ü§íXˆÄÃe‹ed’nåıªÁBşŞlå	’ÆÙŒ­P×=l¨EvèôñIqpÈêaWËW$ø¾Yù49)´Kığª!êÚ…’WÀÏCĞ«¿ ¥½oÏÎÄ
g‘8Ã»5QÇÛ†q N#	hM,-,ØOÀ}9;k¼¤(’Ã»b:(5ù#2ä©úAŸH¼ï.‚Q`û¬51tzAÿ5«³˜²9ªÈÀ²àCêÓ¬4ŒyÓsšUe
 ó·P]¢„ÊVümyÔ„àÙ‘º2¯“‡–j”{Ánææçt(ğ¹wı}tU%Îu¡¥ÆYn…—8Ã´4èfa`	‹¥•aºwiîÜLô%4EÓ$ïQº·(‚ı£œF»\ú 	#ş9µ"AÃ`Zª#k—@©•ôÒìFEvºŒ"‘ù¥çV‘›onË¥?-8t$â¨Xëf÷Y›ùÏgv 5{dfÂo“Y™OŠ1óìB>’Ã'ö=Ô’æJ>Í«Ú?]·¼e&ıÄlI6WO'°özôÚYNôWº…Ş<Æv4X°ßâ(Ì?É     „¡5 †¹ ‘³€À÷]N±Ägû    YZ