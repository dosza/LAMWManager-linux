#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2762384278"
MD5="82587a958d42e41556c258f78ea1fbc2"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22864"
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
	echo Date of packaging: Sat Jun 19 16:52:55 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿY] ¼}•À1Dd]‡Á›PætİDñröoPguÀb–$÷d$a
a>NÄ}šãRß`¤_AI¸Ç­2€³ñõ’zeØ–‹â¨|ÒíÏ®ñ§,o] @šöÙ+	@12o¨Ö·tà{É"<‡œi"„µ·OÀ§‰õí™Q€×ñòTŞ„³ö‘o"9ĞÌzŸ³–¼(Ë-Zq»‹äÅÃ*FéZcˆÒ—ê¾‡àH'ijR§eDnõ¸ŠÕ¥„zêƒóZÌá‘şÚµ}C–ElÆïJ81ûÍ} Q âW®>ĞÁ)D|—v_Ÿí¹Èÿ92Ş™=€|T~úãy…µŸ!Y1€£}(#Ôèu^Û ©©®3V!£kÓ¥å$êéò{0–Èí¾ààvTé{( Ïvë†[²-å?3"¾ °A®#òÆˆ)ÊÂe¼C©æœwè/æ b ª@HïÀ<¯-†@-Ñ÷±¶urqA8moœxÕgDÎ½Å*UL¬qô[ca”¾ÆÌ·(o‘P¥ m6DmÑSÇN´Ô:•ŞïSäÇ¤¤êí½]ş¦™ÎâŒ¦¿>Å5H¶¹Ìã¹¡	\d Ï?|ÇgdÆ‰{Iy-{Ç˜PØÇÎL(¼aÓN<ş£ì^n¢‹õxNx}&\Ôú$·Ör¯«“Ÿş…¸Æ”RüŠY¹HÎ}¤†††Ö4 +i‘¬#¼¬òò¦a{!jßipg½ C€®bËG‚ Ò°ñşL!*¡JO9 ÑEÿ£94Ì—Û¥äƒ¹”†ßy}u<äPe{Òæıë L¥ä3G	ÙF”Ôè÷eÀENâ}O¹ÿ?U“¿ò¢Ê¦c8˜§b!)<t(ˆŸvCÑ'y‡}¥à£§¦°:%*oÆé3{ºUåÏ_-áˆÂ+¿Oß¥ÿªlÂFL4Î©7»ÎtKõ„°}÷n`º*”y‡ƒ::YêK³ĞxÊVúß?â©üğ0±S¯ñ’¸Uzêişs(VAõCTË¬­–H!éîÈ£í«¸uPfõÓÆÁ8l>!|2&=×0qYÍ·ÒÀIìêrˆwd»™§–H2HÉl÷Í>îõMkµ«ïÕÌùèû¶ü¨­]VÃrŠ.•ChqtûâĞ€°vç3¢“ÁòF½{•­çBè$üM8
ÚÂM¬ÍF'=¢‘+l#Â,ªf˜Û%üÊP(,SˆŠQth-„%÷G·U¥‹M û{ûQL?šúUÖÛ„ëBşØ”­ü^Ï}¸à€»º]«¸º¿o\­o·x
€òÉP^U.`£k>UñŞÚ	ºz‰qL=Û+s—Õ6˜	(ŸL‘Ê†ŒŞşB‡,à¢Wèä†—¸ßSÁeyËàk@µÖÀGñõğ{‰õ³zÀšÕÍOç„¡)®¾l#±("êä”‡_ÂÑË¾/fìfXã[T û)4œåİBŠ#ÅØ=Å8[o~TS!VêG\¸”‹àXñè¢õï·¦ûpšîf{ú£Ö«m ƒƒêßn#AÉÂ ºkŸÿÌZnÛ²Ë›ÿóh˜ñtäğ] +ü«:£ÁûaâC 2éüè3¨lıË<¿K_^8’V'ÉI^M½«Rô”Ìº¹µÈè…´f'`ş[º¥ÍÌ+ïQ´mm:9/ÆßgÎ+t§èOMcí¸Ö€ìäƒ£Íõ8{[˜”vâ>Nÿ½N`fY[—Ë“ÓêÁ(•ÂÎE“3
Lk	äİ˜æ¸^!…—€‚)æ•@¹—oMs›(W\œ 2–bÍyêå"Dî€¸ŞA?‹ÎHQé–WX»„„Z¡JÚæ2ñ;øêÄ ÃØ4;…ëãÈ²UUÀÁoVB°éÏÂäİÓÖµ¸q©W¡„ØÀÜïóDZıáöºŞÈ>—_ëĞúÿæié\”faø“[úƒÂ\¿¹©«ÎS‹ÅÖ¥ßmşQ¿‹2_Ñ}é®¸…
…2³hLÊ'÷sqŠÌÚë)Ğ°ĞUtİš‚'G‘›ÛZØ!\Höì•x<íáfÄô·BÖª¯|··6{×ŒÀƒ»¤{N:£KûŠàäX­f4òÆ÷×yógÆÃÀ¶ÖéV¿XÈŸ><×lß4 f¤vÉ Q?°‡¢À–*1äWbO9Í>%_úµßX»ûl›­8¶İÜ$\9€-·‘%.Hª+öù'*wR"P¾ª˜KF·2øÅ°'òºÆŒÔÏ4¤Úû#§™ÑÊ¤.Ä—i[åt5+¶œ„€ZfUxX†´İ¯ÁóÆĞ,XÚÈÒÇúïğ)™gÅf‹ç$öİıY¸tP7qĞU\¤€)“Š"#ÌÈ¥º˜2'¶4ƒª54¶ïlÊŠ‰]3F&ö¹ş©]®11ÅÈNi¡¾ÉÜ}õ	$WÎ«ÓR¨,egŠ ¬ïšp‘Ü7bíÄŠ›N/é,0-À ö×XËö‰«Ğ‚»/¾ÙÅeLŒ#‹âº$ÊâF(ŒˆiÄø˜^&°\$°alM£¥ò$´™/‚ê-1³k8½µIoY‘[rÃ5ş :xOKú£É('ág¶£Šß„%»…dšXŞË×Laº’4Ø®£=Àl¯îùds,oBés%(i!V¨|#rŸ2ÚLú§ªq)ZĞQ>dÖˆ7+§İw†tæ¡;†WH÷ã–	ÛĞl6IFf˜ÿ‡ñ]¨¶õí-¨’¤xÈ¼©èè¹S¯ló J 'Hä¥ŞtºGš.zÖüÄL›< ®ÕöÑgBöyõíâ±*ešcW^‡"dWæD¾ÉYîœ5óŞoYMY±ÇÍíÏéE«pˆøGÆ7VK¸Xå\b¦?$šæw/#Éšî1¶]>¸"•¿ô¸6D˜¿OÎ‡4r4³„øõhTâ¦axúh'_qZî¯êÙÄ ó@ŒWõ
ÍI“C™:2¢5µà˜L+¼È>7¼ÙS‘ÕX¯@İÔ¡N·n²ëŞÅ8Ô‚î|cş	$ş‰Üˆôa…ÄØv|lªÿ8‡&Xh4¶o5fQıïûîppííb¯Q#òAHú TÑÑsZËŞÿä&0Ø	‚X£íB1Ä±U Œ@¿£¾ë ¸÷i=í°x¤êF}ˆDí²*’íÙÏ%Šü»@ßÛÄª½‚ş³ÛÒ@æ„wÛ|ç¨ìèÓJ;t˜)l¯¥ª|ë…5Î|ø6÷Ä=1o‚Ş7‹¼€Ôf,bLBiYXN}‹‡¶—çæCàyS!$ØúšªWip\µs×Ø½:=éTÈ #5ù³1Î¢ÒG§a®ö9òasËı1ã#•
w+ò‡Òob1oaı&iÕ“;]kG?ï+¼âÚ Šà§’0ã¨Àt[Æ‹n¡û|ñ:L¯!ŠïÛoP6´Ç7kUìE¨™U#>œÖ1«B½—‚3ó=Õ©<²¬E÷­¢ç{-Ï§p[¾´ ¶æçŒH„éd•-ùBöˆŒ[é>_àÃ˜â·îa(A3 Íã®:Lî XİãW ‡6R,ì6¬RËäÛ÷„Õ`Tm”eáZäŞ#§së'l	èÔ’™¡(öL™£Ö¤úÀpºG¹úA×w|_a=ÀÌMI[úÆ#`pÔÄêöJœë^ÓmÂ»õŠ=3e;C-X+G³Öwaaş›r-w¾Ö´d6Ù4º!=¤èƒ;&ŞĞ'"Økßy‚cMd^Ös\¢m1HYåbGŒè
J83¸ùæ¹ßVÉ@ÃÑã>È_=ˆçrX—ÈRL•> ]¬›®e|¢Gõ%íÌ²Â2H»‹§‘!ZrÚHO•rB¯šá0 $ŠD&ÇÊŞQPQÈ)·èo©‚+¨—DÃ¥PC¦|½WY]eV›Vmr‚Ø°±\O#tMâDÔñ—Ut•ß›$y³¥‰R™X/Z˜UïM^Ğ¤Œ»„P3ŞW¯qÏ7÷–Ã}öC€qAåˆ=>÷µˆï{ßŠ’µLŠ;(:ëeÄÑáğÉÀwªÏê«RØîu±»lÙ ³™+;L_lN€R!p"òÔÀ\•ÉùAÓ"†Cé{¢Y»;Ã	z»wvÔ÷; |­CÜÓáÚ%ƒô%’¬tôŸ-8üujÈÎd^¥“Ä¤ÑóÙrîÎš×ßé2|ı¦	ôşfÃCYèe…›Ø+ìâ Ÿ!DnÓæŠº.Â¿€`DÑ {±ƒ¾›€¤f„„X{D²ÙYa[·<H1í’"-1Ìp$^<ßLi/Î˜¬ìá´Mü`c ş:»F%;bÜHe½ey~†ñ14.‘¶/ªÃ¤¼wà÷úv§tW“w˜.ŠO+{‰ùäîûcVŸ}–Òö.Eˆ^ziêõî\$ˆ—”l\?©JjÏœoùÔPœ¢ìeGê@¡ëë{cÓœúÏNëTi›/€´ßİ­	ğqåë8…‘Rø#¸n÷øh‘¨8ÄÉ}–0(ß@TÒ…ì–8;:0¯ÓÓ…ËŒ™‘jàcO¯ø¥­HÙ¨Ùg£²òè%"xNCmc²‹ó.¢/Æ•Õ¯hØCÉó{AzÜ9©Ñ'=é¾E)0T%÷Dø/ÈÜm=¢q@í2»îÉ¥ó°§a—òâÚÈÙÊCÃ
Ñö¸FK-EÛ<¡%Â¨?d&ä™1SsòÉ¾Yf'†Ä7-úox ê·§‚Ú‹ PŠ£ú/‹	%½úî¡]v©mİf>Q–g‘¶˜©¦^Ş{İ
«`æéuí%ND<¹^1YØ™4ø³ÚKk\×4kƒ ¦¤ƒ¡0PB¥·{mMí€ÄVr ô°YugsÀëm„ßšáÚ]{¤û¼?10IÄ¡İ’iÇ71”Æİ,ñIZsµg®4ÖJa‘ĞQG•2P\HøÍ1—ó“û™XâU-Ì~u¤¢rƒY‰Êæ“Xá~yãtb.)ikNSî¼Ì,(åDdË†hè€|æè^cºD>8Z²†5Bö&Ì”·%¥o¾dƒ° y0ŠŞé½`Ÿ:§bşÉ¡gu$0+,Ñl$1>SÎ)–¥­ÛÔoW&‹Œ’Â3˜÷?JÇ¯2™"Å/æxlàB/Å V©ş!]ÿš¶}Û¡ò Üàé[pq¹D|ş8Àp›)SóL£LÛ®#?µc•ÂSM)„×kş%v&pc:§Y¯}ìyYFWƒˆ¾8f“ØÍBªP€á²RƒlˆÇRãÔ`5‘çÀIC†­7]ÃÕl‘ÒQg³ÖĞ­Ë1åû‰„ııayÈœKTşƒ3X¬€A‚@_ÉãÇB¨õQÏ¬›LçBzN®Èœ sy¸ÀB´ƒRA¼rÅšµå~a{™ï²5²©O2‰ÎbéÙ÷Š1qŸLÂêíœå|ñ¤İ.®S Òbùo¤³h?¥©TDíoI^s·X×”¤´ºJäHîJÚÖÇ¯†0!‘{ºÌb¦âOwcFfœ¹²sìöfÉ>:ÑFù¥yäá‹÷Ô”Q;³£îK–„u§‘a^ƒG‚Ó•à¥¼ñµ:ŠX	0ŞÁÜ\#dbqfmBVoQÚƒ¯¦5í¿vîwtì&èÖ2oÔ&|CÒ0áˆ5Ç€RÇÎà)Ÿ}w+ERµFÂïPúcQÅO»„YT®–´cÜiáİíåáµ×ŠÈ0³/,!õDHP§ğC‘‚ç˜Ë§½Ç-ĞkYÉı½üáîY2¢×+ªâò¹÷­Xßz–aÖøœµş‡l vÊ…y%5¦·\»0äG›%™$€c1ş¾˜±ßf1ÀHĞR½-[Úb6É“»u`öäëóyV

ÕphWz÷ß‰P±Ä-ê•Çœ“œfÎŠiÕ¥Ãù@ôğ!.Ú7W­ …ˆE§’<&Oê×ßXØ3òñ”)‰§Ñ&³bGâî(Å½IŠKJjP{¤Ë€%N{%^ËÄ}P’·ç£‹½õZXµÎ†ŠŒ³»tù2Æ†pjµg|ŞqgÁ4ºïÃ±‰şÄúL9P\,Àì·ÏéJ^TÍÛŸºU@¦ûŸZÜØŠşï‘y‡B5{{ZâI¼äÒ l~Öh¦9ıĞ
Z4Û>DûÆMÍ>]H˜õ×¹;(dŠFà±R‘23ìËYiM ?L_à„I;3jAS ÉqŒéŞbÓŸ{ÒIÖ‚¸¥O­Ğ&HÒËIÚXn€Û”l¦Ã5ÅeİÅÃ3\>êï°)Gª
*»C<È³(<–>‡.ÊQ¾Úc"ğa-äğ„®_ WIáv¶Ë(0 Sî†¿ü‰‹fàˆI¼Şë{¢Ú3N£À÷09äÖqnà~^rA…æÍşº"ğñlşp~©]&Ê¦İ/z2qZüÜ ı‡'z)â¯â-Œv‘ \s Pbìç× K€9Â¿Õ;±•2\8èÓ`äˆ¢(ì€ŠóùFö«„wg‰|ªàŞ'ğfâk‡¯èñõàÂ–ñçÜÌ[‘xß¦MÉûúOég.ÚT¹÷M—Us ¸æ7¤ù"_Ñ—dN>._ª¿’“™¡í„ê²ïˆ©1ùŒİ+ıa16¯,0Áhßmùn®ÊZ{×è©Ã´}8óÕ¦üÿ{u|+j¯Éz¾éÃã;çtM¹¤•LÉ5–ÍùùyÒËÌ8÷–í6“õ ‡ä;‰`8r"cƒ5hÏ‹¬š³Cp\Üw^øõkŸjæ¶Rçüæ¹ ¬EÎbã5ío±®ıŞ|N£UDğRšEMc#•}ÑÓšl¦mSíÜyËB|ûÖÛ,oA¢øİ”ºØPÑô• /l÷4û ×ÊOYX˜bQÑ32kÏ4×=¿36…ÕøŞû³@pÜO&“L{°ğm.Ÿü6yÄÑÍÛŠÔÑ“‡Dı8¼ÓÅ§Êc*S(!r%¢‹Œ
µÒ´íëŒ¹ÓêA´	rŞj’¥ú%òUL¨Òµ,õ§í€^,TÕæ³ÒçpFœsEò|‘ÿ½¥š&Ğš‰CéKm #’^óZJğà’§#aÇPhZ?ó¡ƒdé~ôÜf×µ¾Nfn0X/áƒôó#µ‘(_òÙıh”:Ò¿N"	ÛVc?-SŞJş]±kÿeO©ıºOQnU®mJhîñ±¿éˆ²smKMÔ€­bÈ“Ë;¿yÏçwƒÄ1Ï™ˆçTC‡­×n›¡ğ ¡À%øoÆÍ]~İÄ×"9È´ºCj‘
 ä3ë®a’i‰Î0œ³+–c’P/æ†zSüYWR2} qTÌL4İk’^ Sƒ+=<ğÿu×8‹’¿±™ phQÕõ3¥šR‡Ú;ì6ûÍ‘JÇ¤³âßHÜZtX—¦g«G.MìKsòùCa*Õunó×ñÊñFd?àrqu*€çjÓQ"û¯¿ñ{á™óu­0M_5gjs‘R»FjŞ˜u åÙûŞÅŠE"kZ¹Áîo*âg%nj"”â©¼ë˜ŠË>`t?Í9=n8”û³Ğ¯‡Ïœçyòz‡&:Or Wi|Rö2Únˆ›üÅ\^œÃùÂûç¢ócÖ\½ôJx­zµ}á¬Sµ×Lœ+–£Î;Í>8¹-Ç!TÌVüW™1á|‡€VÏº§Én¦>oaĞs	‹>¨€ˆŞ%¤pÇ·>§Ë˜§ 7¾µP{&Iöe?&eöŠ¸*ì—DRHÎ»8Áa>ÿGÙ©‚)D^u9Üºùàè2ú#´ ;Lïn(C1ÿ"óvímú†“Th´7mBß$öx8‰ê§ G÷Ã¾—>ÿTÆkæç»7YCá42&?\JÌÌ!ö ÃÀñõãl*ğí<;Â<Ş®TcšŠÖkæ§*èÎì™H“t	ø¢µÈ¼aç‹óä~ÎİD"‹Ó:™©¢ÍbjŒ°ºŸds|ü¤ø.·½úÇb¹±¥¦Ä¿‡qŞ‚£ÊşcfËWZ Ë`Y_±³™uJÒ”ízÏóWBÄlL¬NòÊü=_GÁwòˆ9ÚæL¿Uy,òrYèitis¾ ‡ÌyÔêì€+f}'Ä7û ®é_·J¥Ã¯Æ'±gØS(!Õ|NÊs,%h-`ÊI{¢ÄnAˆÍR—«@çã­òlı.ë7Òcü.¬õN‘ƒOàaG]Éj€÷1LsäßÇ·ÄlµD³+iL÷üøm†æõ4$Îï(B¯»ÛµÖceĞÿÉüF¨4FTµº=–Ûdg†fÀÓf%7Ã"æy.ğƒ
ãïÇ/8ãâoY'°EÀá®|æ‹NßXlúÎÁ™lÆF8©º¸é¤HkKµïAjÎ³µ_<)gÀ®SvÜbI ¦/¦éyâ Å8Ôo˜PÁ©Ë©*©>ÌY”…&zå ‚‰'†¨/ÖØö­uš¼°f™¹-ğëOöğÖáÊæ¼œëÈ->·SØÊJ"Á?#°‚1B%!&l“ƒnÁ£¢ÜëKgã(½N=EXÏ©iUD¹)á{ÜI[6«İ(qäæÎ§×90‡<æÿ—¼LYFŞ!#˜s¿É“ø·LÉŠ²Â
Q1ÛÏb»Ì°ğ9#´İê½‰%	oô^ÑÏ3k¹sĞÎ·`ƒ<‚CíœA-Z³­~MŸB=ÈùĞßyİÇ?ñ}Øûøx»×Á¿×Gu2öè*ñ›7òˆú_WjCÚ!øÌÛš;±k)ğª1Æ;… íÑ–™Á&Ë6u}ñù‹Å¢æÄ“µôóJõù1avàóuÖ‹8öJNpNX&PuC&Y=däKŞL~bÚ†]øÊ©e±Ø/÷QiÌ®¶ö!(ZäµîIe €úä«ô‹ZcÿG^P)Z¶°æKŸWÛµ2§N·myMä Ü}JdoghÓÕ"-(¡í¾¡7¢¶ìwç'£GÇ"í´#òúşÉáŠ_„ñ‹,\zĞêwz¹ñWö©Ò¢@g0.?¥w#·‡ö0n,IÛ~ªÑp5ºaI0"Õuù×:8‰:·9äÖÚsjç­íÂ¾¢"vqP
‰òò0kü}ğx<¦Óë³Ö½ïúè¶É{Ø-önÌß¾Æ_0_¨ğæƒS¥ö+ĞV¼r¤CQÁË¬z¿¡Ÿ-~ŞĞÂ0}õÿQ™
pny,#®¦RX‡‘DVæÇ¶¢zî@L@ıã+I'ä[-c˜¿+L|´@~J¿ÖŸ8à!"k&ë –œçŒ(¥¼âW%›¦—M]zônæÁ°¿‘1ÓJ5“t¶eL—Èa‰ ‘İJØ–™p>4¸±9K$±ãC#lÍ¥f€¥Û—Åu úóUÀQ;¬„Ì5³±Ã4—ANàs{·è”˜ŞÒQgNg.‰ŞIä–²Ò)ü#ÚbjrôófÙb†ƒz8LíkëZÆ{í<%¯º™×xGÀ¤^¯ä~
ÑÀšˆøç¬ònUpäºÒMZ–øÍ#´„W¢_rÚñÕnú EDƒ£?Km¼åÙ^*O–h'ÒL–Óf“˜½ÆO£Ü$€œù(ÊŠ3şÉy·º·£¶ÃVşÃM±Rp‡ê4!Á¯Ş8¶ŞL¡ÇĞä€®7G¬ß¬±¸àbÏi¡Ñg¼€*v;"b÷P×ÆúøƒLXr9õf«Jf+­P0	U³ñÜ€ùí7%WgHA½»_4A]äWÓNíÂ~®¿¿vŞ¹î¾ùÍàÉÄ,*&p¢­:İxY„–*åÃ’9î4ƒ¼ÔK,â|Ä½¼„	…›•sÛºÆ°]Y u 0fKFii äyXQĞoVTk9ˆa9¹ÊTZ=ü’Å=ç·¥3×E}a_xW9Ô9Ùe“lÉMøî€À2Jşg«Ÿ©Ü7#œê-{Ow¥O¦œÈ6oâ<ÿ4Ø•L«;nM!Î ôÒé÷X}Â|ØWñ'2º©X§°dÁÈ*ñ±).éAñÑŸI¢l8êŒËRÅà`~(w.kˆ5õÇw4T×Ø¢‘ä÷¯ì ±ıö2Ÿ÷šbìK£“ğó¿Ş,7ŸˆqÅŠngÌ%¬c¸å¼Ñ?”ŸãÆZÎpAl‰QW0¸û<¤6ÅøŠ}ÃÏÌ³ÊğÕAA.*{éÄEñuGA—¢Ï„z|Ï49ø)x÷ò£]xÉ9ñkçü|t>ÊjÙlA0üOX~—_Q}\­·¥,ÆBÕ¬hğİ˜«¶‘š)Î–JEGj¬pêA®}p<Üé3Œ{‚à/tƒÜÁ*-ªÄ¡pÂgßÙp;Ï¦+wv©ÁvÛµ‹:ô/|R¢ÿ¿êKµß»vır]¨°ÕEÉƒ½ìß”Hßç1Ü„…Ïkë
Í†PŞVmƒ?híTšÊ–Ú´î GÊ÷ôaùš¸™ZoÅô3R›ÖT•@§ÊÚSh)K©õĞ,â†Õ¢I„ü¤ & ¦Z-uîÎ~óŠØ›Å¶n’ÄÚ9Û5ÚE‹?ô5h^Î Ã§…^1°±|G ‰Õi…«ß~Ù;ljûqµt5'D´˜ÒÁ‚½Ë\øÂ‡µ}~8°ÿ	Û5sÚ¸Ÿ³MùêŸÎC4
È#ëÇü”H¸\0ÜYÂÛ†É^¨¡0ïíš•fğøÙùÊŒ4÷åVqJI!6ƒi(Ìğş°TĞàÆÄü£=æ¶Vø&€|ä³×æ´âĞdØ?İG.©Hºøn0Ïd‰Àš‘½«cªué{@éQÑw|à½¡¡1wßƒå2øÇÒjÚØÔçÏ1³ÔùÄ—3Zu¾d:ÍYèÈĞ»]ìÕYáÏîö­j;Ò¼¢Ô‰G^*>×ì¾P¥†{uëä n^Iá¡£9gÙ‹ç@zk°Ğ¥,!„wõøCœÒÿ>¿ôL¾¾tµ>hliİyÑ¥ÖöL—7òa·$JÌKıÌÑc?>Lºvëó»o>ª^ôÏX¤7¨Şuß¶µ­"”¶oÁÍtI™x`ù]ô‚‚#ÑP„‡ù#Şµ'Ä$¬aš‹§vxü8ÒñKaº•âç«X³ö;‚±ù;ò¼qĞ7-ªÉ÷õ>¸iÔú´I«Q Çµù2«Ã‹’Ö]£ &¢!DåM¿2´´l•BÆÁŒ'Äåë¯6¼È ö4Y¶›Şü„fíì?tÏ†6\¦q)ËÒùÓÖ¨[=í³áûËú+Ç®§ã×èIÇ„îÅ£µ·*¾QW¡\ùµOLç¡jÚ»´Bht@é&Ë7™}H(œ ûTì‚õiİtH]\›ÍxßŞÊ‚A‰í^Òˆ'0r—>GDóB”3,=R…i\œ±|o3ùØÁ£™s6#=ü:z”sıÖP Ğ¿X²»&ª¥†/`ºO6§‰–÷Ù5¥(æ9‘d¬óxîyB	û¬Îkß5åÛÿE<3ø öºqhÑx¢C|%U’MÔ€û$Ÿ¯ÉšuNâåêÔ]È!ì(:Y}Ì/Á[R·fƒzúWîf7éEº—›]Ó3¹3¬šÜXä_ó½Ù»êJK²ò)êÃö,±“¶	ÆpsÃ–*§|p[îğVFNTI`ş}`zµy§¬²xĞç9I£™rùtêh©¯Á.CÚŞŸã¡	. ¿\ØA¦ÎĞ(K`ov$Dôi(L=ÌÖ@„{™Ä©Ã_¬ÎÈo®ÄºR‰ †òÓ<àëÙ¹°Õ¼5jqğº-å>_–v Y4lªXíyö;«ø¹‘ºfwÿÖ½{ÁÎ½.N¦+9òÊG¡±C—2w¼C|®ZînÑ“ÅjÉ2›¢•‡ÁGÀyø“Zİ^5‡$	[|¥ŞÁ*tÀ"ôo:^G–[t73ªÊ©q™ÅÜ”lÀ©Ùüq~É5¶g‡}­Îg¾9]Z`yx>QI¨‚ô´+—9­>p³c!H6£ñrÛú×]íéøÁÌİuNz0‘uP´J{®zİC©¨ˆÕ+À¥ídfÆR"UÒÇB\Põ0R›QÔg@Û°t‚¯¦yE¦©“æ´éN¦š[c'š‘¦c"îzµ”ì,áöäªÖÆú·QBõg‡RÂ¬3[s#ªèêø-5¢üŸX˜+,ó&ßà,d^©Ù$ƒ¤û"ÛWÊP±5®¸ôMºå®õgRüÃš\†‚m¨Ü×W6£½*[—g€<Apõ§®û
A´ÒZKè½õ8ûobSÇ ÎkJÈÅ¯©vDÜçEâØwÎ{k3ôˆhF+XZcb5Ï(Û“°‘Xfq††ãŞŒÉW}½Ogµ¦¤7ê­1nş!öŠ¯0$¸úö‰‘áï%ğ¯µ•›#Uš”×—±9ed²PCbË¸A”‘íV×tx:TU¡Â” ¦èòµ­µÔ¯0?õ"öÔU‹¸¾–Kë
}
…<¤Aéu¯}»¦˜\À\Ewr}>C‘‡²Ë)³¦+AÔ„(,qfbOëOˆ İ°LïqV•[İğU¹Â&¬úv!ü·oÿ·8¶LÕãk2§P+BÖ[û·!#]¹fº’°€¹æVdK×OÛÊq+ûG1ŠfpÙxJ9iï}8êû`½UB3]÷şÑ?æ|ËŒ„ÊWR…Ô”µé]?Ø÷=	ğÚËæ0eÚ9Ëò¹Ãá1oB„Ên‰§aß£¾d9ûùÌ0NÀ	À•Ì™=×SX«ïìXÜr…ÖD¬,şUÎ-Af‡¯dbW³U¢4"3uj…ÒˆÖ)’ûL£T¸ÿWr×ç¨;é¤HØánb (W?n‹Å+kb”‚WäT`ˆy~uoL%±8'¸§asÁ©Ú?!êôIsÎ HŒ·*¬pñ‡ên—~ZÚZmsĞè±¥V'2O@Xf¹Yj¾èû<¤¾-à¡ıÌ®
çt¹Ÿü[j äóÙtCÀÿ|PÍï6Ÿ9¸c})euj¨b”‹Ğ…êÔŞödÏs/!H]¯íbÂ=äØ(†à'L÷‡1ëà‚ß¾r¿¡ÅR.øgÛ:¹1Ï¯£±Cµ&”8ÇµêE@- ŒÙLd×âŠ¥sk*8Ócâğ¨˜›­Óİ¤U‹ÓÇ 0—¼ïˆ–°`('‘‘•ÿv‡¯OOµ©¶t¹rÌçÎ"Gn’YWh§uÏ•L5sæ·£ùQ?»ïìC…Z.>·Œuäşj¬¥-õİñ¡î“@yÄ÷a¡mã »øBÄ8W]ñz×Øy™z† ^Øë›íK3D«{RåfÚíºàüÔİ
cwÕ­;×^AĞª*lu’ëa"£
¤+}?†…Yd¢…<Ã¯ŸÊW¾0Ùê¨ñ&sép rW	©(FğeA|£ı,#a•H=ƒâEÂ )u0™máX*›<ş•šr‡UÙqa¿A]È|P4mÂ¤•±©b'áq¡heaÍ¸ùÊ6F‹¬d-»â;[¯ş®ÚÜFEX¬¯êüqü‡¯¡…=snb§Æ›LÿL¡½Qï£•‹¬=­¶ƒyœe‹LĞ6K]ú#P²}ğp¤7ÿ’"ÌN™,›eå d›ã¯µPà$ª¦E•ÆLG¨è+ÙRæVæ‡ñùÉÛsÈÃÆİi0tÌ|VËãí06QX*»Û0·	*İ;éÀ}âFùòr`–&õıÜ¸GWïWêfgÊËy­…Ù!oQnásº”RóLi_—!5EèŒ¶,hÃ’MÃİRc†m·arØÃ¥5»¡!ø¤öê•êêÖ\Só ¼ª¯ayİ†FÿsU~¨ö©In^ñM¦aN ¸}U"!mñÓÚTD>lß÷´A¼;ÃZ¶0ûãßÕK] ŠÓ [Á‚­Jó®ßé„ò†kkìŞOÈ®ü™vÃzŒİ¡ $ªõÎS| ÄßĞâ×TMÈ7kàŒe6/œ?è‘J­DjxŠ¬]qä—ÍšzÓ˜S‹U`Do09otò“x×çÑ˜gk”Ò©¨´E(˜õÛ…O¹ö¿N¹_YíÅK÷kAUô)?1e$»‡òpİ÷Fišƒ
ÍnP*p›Ì^mc‰3ÆlY§%ÅÎwM¾9¬Õ‘uøË(…flîâ	²_F9ÀÁjWtßî÷ÏótOß3Ç¨úYè*ÜâÂ»ÀŞ(ô‘Œ·Â4Çí,ç°;¡V:»"Vfn],c•%«†™HÑ÷ú×ÓáF:ğlÂ€éX‚vo)P÷R‹•¯¹ÌÙhà+ÚPÃg®š(mu°a9N[áÌ¹O·^(¸ ¬dàO.ÎùıËâu`ÀÈ^zÓÂ:<üåÃ¤ü÷œĞ>‰)Gº±¢ï±¿lŞF9Y—=kb¿µnÍ½ =ˆÍ©ËÛfRØ8f‹\@[È½ Ò.Ô°Èøz™·+¢‹QÍ©%ÄF›)¬DsÚ¼=-ÕşUÇ¨w¸…Ç¢nz”»¥·^ëµˆd;cóó7Ë¬²‹eşn1 HŸîÌ]
>O$‘ÃÍÂ‚XšRş—¹:2¡™?r×‡9ÄÕjTĞ'–Íüb¨ã§lag‡Ù;•ÖÈH·lû@’Ûó$KûNKœ½”ÿ+öŞòæà¤ğTÓ€[=òj¶ÔvAŸë¯/Ù¼=»¥Y©!•Bu2œ·3Q¬ë%u8?mÎû³†xÅzÎƒ‘é=ˆ SºQì< 0¨–d‚±dÊD%¹úe)WË•š¶ô K Ã·‚jô¥àNt½ü©{Á¢ëôpc‚ÂrõÏ ¿€„ù„têïyhğõ“Ë«}¾ló<ôqïÊ,ªøT˜S{7¢À,6\Úã=…Tùœù¶+ÿ·@ÖW,?û8lŸƒG
	®D
V3›V·ÇÀµƒ–5>æøBç.àº	æÍÊèa·”ã[ñ¯DŞ$@7Ëf¤vˆ“C:›ªó{^bªuÈõãÃÕ8î$İ©õ-ı0(	wÙŒå‚Ô2™¦˜®F#H*Ğ'7¼\RN5ÆÍ°¸(\ÇÅ‹µ¦ˆCù·öÿØ‡uKt'ûWmÛxH!ˆC²¿]•ßª¡¡Ñeû`‹ŸkÌùÒ\ÑÛò¬èGºÁç
'„v°|S$L-à†îò"¨Éò¼Ì¼›œ™Gì‚°çyšÖAYğ\rÓ½=™ö½º~54ÁY¸Á<PıE~Ú¼åÿI½øwX#¿G¸Òåig{0`•nPç+—,~®:’¾óß|Ë5}a
ömÉ»}fğºê¼VÉ°LàÃÃ¤_Š#×AáIôˆÃCEœIV¾ÆYğ¿ô#g@ùD©Öà+O-NÕpäÂ[ùB™CÕæ•FnL2İÜ,qb¼„€#1êRâ®Áµ‰¯Á,ÓW† j«E)[$Ë¶Põi+1[ÜÔ0w¯Ü-âŠÌ_Ã év)ş=«P
hW­;Z;Z&lÕûİ3©hE¤ŸîâEÀ¿µjÁ/È„êËì¬/ƒ«;µ~±Í­ªA€ˆÃâñt"ék0+Û£ãèñöà´‚S
Èµ¤ôT…Gû|¶Ê*)ÃOg"«Å%b(ãçÉ»Yo1W‘”_ºş‚™‘Wo¡İæ4Ã¿h·Âà+rlÎµÄ½1ıÏ`Q´	ÈL!ÀàÃ…õŸ}6>äfÎà‹Ñîò³e¼Ôv* „kşÜÊĞôrkÁÀÚ:îŒ«“üØÀ_Ü«H)İŞlê}ŒädñèbaÒ-ñÿ)«Ä'ø{ïï¯ÙÉ†&ºÈ¢(È}˜å–83ÚÉYfãD­“Bh¨nÜ˜¯şùvSşš~‡ñ`\Êw0Ñ6yoğÔ­ûşÎş$°ROÏ`éŠ­íıœ,èíkÿ”7T;ŸèÂôKX_OiºÂ“.ÚJcë:­Şk‹¯õï¾ËÃ1úMÂûˆSĞ…_4vÃ$Ñ©…Jù¥ò€u|[ÊÏŸ»/EîıhÑ3Š™H·dpT½aà‘™qñÁù@yŠ‰Z_x¡×ªŞİ^²ˆ*Åÿß†_¿²4Ş1ôş=¹->D½ÎÚ²üÛÀ!ò1–‚“I:Y"4Pù	ßĞó¯ÿäà‰>Œv…]ìşURÙe}ŒÊã¸DºÑ'¸´Ë;¿8¤Ö#¯ªkBo
”‘<ñ*X7ØwaÈÖÿÔ“Í…±â¢V;¹ğùzŠli9Á®Œ»«ìæºÎOR Nå l\Ó%çT$ØBS7Åa½á]ƒâ¯ñ•SìÃ¿í—u‰ 4Ò^m³»á€h3#§7+˜œ€~#CóU,±ÏØxµ*û:.LÃõêÎ1×ŸİÒ¼›7ä†BôRƒã”ãÌ{M×OSÑ1¯Bƒ¹¹¯8à”&h,õ(U–÷¸ì¸e‹fñ@@å#Â‡€:`àÎ@Ã×Ò\!)ÚhEå22‘uûÁÒb;	uí÷õ-°•r¿Y”Ë©~yWŸÃç |3 ë§;™^‹o_*ëÜã™?Š”˜'7>Ú	F›ÿñhŸ”oZ(“ğ…3ğÖ·÷ÉÔdà“H ØÑ+0¡úzG°_åååwÖk€E×˜äŞ÷âªI ¶÷}4åÎ±¯î<j«éTœ½a®T´R>Ï»tŸ½Û+ğ‡ÀûÇãLTÉƒ²:€ÕBEıW¸fà4›ş*é
îÅÛæC±æ®äÈöñá1ñ¼rì,èŸç*„®‰^|@œ½Íëš*G—G|ÃBŠ6H5»—l½¶úVx8(T£HN©ôÙÜÆÊ¯AJ¨ß2wÒˆ].Jˆì!˜Ğáqgå±![]<ŠD€ëx7ûî$G
5ùº™{dºû°ï{>ó•I]êq­E‡FÁ¿)o|òíŒ¬'‡fedhE•åb?ÿÇˆ´F…Üí1ˆ‹¯°’.Ÿe“ƒ’N:µŒ÷)¶³l›óoc¥Rszææ-hS¥Õ]úKtŒ)Ş$Írh}©E½}+?ı6»=¥Ü¥]vPÎ¶îyñİ¿¤6«SÔMµ÷"ˆ®QÂ\Mòc>|Mô(»ÔQZ°İu±I±Q"3bQÎK„ŒÜ ±/#ËV±ğq"(üLçJ<ŞBœ©o#ê2ÛËB¢Rß2Ì2nt‰D'W†¦ì ;íkàˆÂ	‚æÔDC×¤0Yêñ\3Ziş'¯ğ²ë =c¯(çÔQ…iƒØu](NÚÿ)¨¡Ò~¬£€B_»ièöe¬}¥VA#“²T7ck&ÛBOÕ’
aâ„D(I\ví…;ğ6Ï€¡ j.—>á”…5€Ÿ2º‡ÈÛl]‘R•éĞşd²¹ô¯Dñ‡óQÁú‹S~i-¹Î}Œµjÿ‹–ğ¼êû€ùD®å‚ÑoŸ›Óåvó½uQ”‡ÆnÕÄĞ^jõë4Iè‘®?²²@Unİ•ıHcô©.‘]¼uk[yH#cC&?”ÎÁ¾Qf×\ÔRÕØ÷)ï¤v3­Ã˜vÓC…Š¯œ¾NXœf‚™ÑÈ9Q rÜ3|O;¨.j>Áâ³33»/KìÉ»Ê„Lúw36»‹H¥Õlé‹LXÁÌ¬CSõÛje4/€ØSÆh{4_ãï6zs½»Æ1]À'£¸47€Xÿ&Ö‘ù#3z6÷åDAÙ0­:Í¨ÃBø&µÅ(ĞÓAÏ¥ïSx,C‘¬ñT9ö3»cj7!Ã8Â"Xbx¥asR¦‚«æ?,)(ÑI‹8ãÜ2$käs‹r\YøÄN¼]µŸ|]W¨ÒRÂÈ
QPvûİc!ÁŞpWNátgó)å“;än]S]B„‚3Â®On¸œzQĞeøGOFu\ÅmƒÕë¨>\}pf°”åì	H"ÅÂ¡¯í¦ngãôáPlûÎõ_0z)»LGÌíqyåŸ4òFÑ´Ğˆ­rü´ÉÀŸ>½dà»“Œ­èß@Rb¨n¬!Ö“­¾+u=¸ËğŞ3+ªP*¤ª–>¶Ã’R¥F‘¼¸¹å&w gAÂÕS˜1f3HA1Kë4Ìò¡è\u=Y1ç€X_ã2ÉÊxzyI­IÍ™´ğĞ‰;ıàt˜ü•,•)¿©Ë¬Ô×$ûÖ¶ççıÔÁX¿%êØ‹\wk…É)öÕ ±ù2~Ùİ«uÜ¾…'ñ×§ÚRÁÇ{¯àÀ«¼]C­™e?Ÿ&°¹zå[0qß)fœ÷¯eÉ³ë‰^‹ $enì–Ú”´÷ñL½x>tJû•Ú±P¨Ù—-ÛáApÑôüÄÅ*úª‘†ˆXpÇ¥b–ömJyLn†¡
ë§Ë/ñÿAÜ¶D*rXA”ËyG)†¸*hUÑ/h®ñË«-äãHáÎÎ©RÃ)Z&‘|Ùò¹µ[ó ô2V–Ã;PÃ57öªÏ‡•ôâ¾l:XÛÙa”]½tj@1K
hoï7´äV}áÀG|hø‚r ¶I.ó.PpV‘uõ=p‡˜wğügÊû¶©,x,lBÚé/ ª…ı04E ºwUÜEx¹R LFCĞµ‡Ìı\´~Ãƒh÷ú;ó±ùÓn@È;âHRJÒYÅ[cˆ`½şÍĞå¹7`÷*Å	©[ÑÁÂ ı˜¼8F®¸7ëgŸ&Rü’¨ÑîWÅó)U_ºBÒ‘o0J®Ü‡ÇO;ü²àü‡ğºYå§¬Ë9şYàA_Íõv(É0¹bid|?5N˜£´§zZ­ğŒiqWÃ¤,›~×İ! ìUòİjôC»iğM6ö1	aºså3ÏŞÛŠH¢¦R­¿Ö  PN{§*ÓûN¦L{'üïf¤êqWai^¾ï7bÎ³Éğóz!öì5q,]-e4ß‡AÅµO›õ?0¼À=›2o%ÃŠa/¿Pì-ò¯|EÃ‚lÜgøËT|$>ùO›}8nª#[x†#åĞ¦Ã¨¨KO[ûmaõÂ¢švfÁjc	6}ºÏMi†6´Ï×KZÍç†kG .,?´MqWnhİÖ„„ø›4)”±!g#¨N_ñ11…Ê)?‚ÉL××;.Ö9;ud*÷È³'S%[V/:6<Üx<Äşèıà×¦ÕXFzâ'£å‚‰n^ëÂÿ]StùÓ#ôÇŠ	Ş(ùAZsèn	õK½€Ù›Ò~/C¤ŸwÛ &z«H|/ä¬eé\•ñ1óŞ•}Bôbä¥\`bjšà{Ô$“Ûn@kÌP‘ûkcBR£¥ôÆßtç:)‚1zª,Ä5à_GGJ‡Û[Nbğ‡6:1J>ı¬j<-i¬ä‚†\!5yb³‘rà#Ğ&Ğ¿¨®%Õ¼ra¤$sp½j)˜E“rDÖ]f¯)¿´ôÜn«t0ªwZ¢óÊ6õ –xµ) ç „#Û ¬Å,RvßÕü¹›n‚NDÜ>Ã¬¿–^şÒI	ßñY[‰æÃ°ˆ:ò½†Ùë¤$Ç>³eyã¢h¡³/<v2«?FÈ¼ ä¼òÒ­*%$0ËeæĞÍÿr‹¾¹ş;4ú×ÅÌ‰¶© ~»uıoÔ‡ÆºäD¾äÇ ö”NÑƒ–¢±hr3,ù~ûöB|í°Ç_côX¼@VÛ›Eİj7,ğP‡È [nXßAÂ”8Œ'‹Jƒb¹dË’C^÷;ŞaÈ‹V(ñ$n_ùÇ“N@˜İ_€zÓ‚±Š0ï¢ÃÔ¥ª`\*Û¯©‹ß§î;7sléV›ÛÜê{ÿîŞñµ0ÀN';—NmÔ±8Y[·ÑÂ;'µG•£„jù¦î3¨uôİFUob”I¤‹ÿXe@W‘ü€xâŒà›–üÛª½pA–3‡$½R‹8†å+‹^÷K]¥ˆÊ[Ó»¸ÚôëÔ.Î½f^¡!JWëÔæ?ÒÏIdœr¯^NTkŒÈ ŸÒ í²F;Ê?u‰øéÿsy¼o*`¼.rëÜ+a· ­±v«™òZ˜†@Ûx6 *(«>«­¿nºt#Í	c/n p «üòÊH=M„ù²õˆÆ¨—âkõÃxÀ¿á@‡«£Ás“Ö¦(¿{¥4tˆÇ“<)Ş'ËfÓ¿h4âPHçjBüz> c”É^yîáR¨SwO–ø¥m×JJ}ÆÙMf) 8%!‚-+úô1¹‰‡ÓoİÍt¿q¨İlW¹uSáÙÎQ@kÌÂ¦0dW“½Ú€¥i)éÉP[——X[sË;5#
È¹Ä½£×·Õ„œÃ\nÚúrÃ‹K€}!¨2NQ@%ûÙÉ‹œ¦/\p¸2cpús{k˜Ì}İÃ6Vb1çz O#0ô‰>úßÂ{[ŠÍû€a™>¯úiaôÀ-ÚÑcÁ!aR>SFˆ1İ¿Ä'eŸæÉSlY«ÄB
q»_ªRè¼cÑ
„âboŠ]áŠ"õÉéUY¢¡VÂIh>÷ûÉ¿§Ğ'±7‰òäÛ
Ø>H)5x¯5•A·"¿aŞOAÑŒ”‰Ä:úx¸‘`_Ï]}GÛ	/#PÔûœ¡#lº5¢féãìó„m¿!_xOh5İôYºug:¤× öcû<DL/äú…”8[Ü^Ïkh<ÅxÍÌ¦°lyfliÁñÚ›|A¹áøJØĞŠ/“•¿îÎt»@9ùÕ«xvËò¯ÂüAö1C5|•ìG)²j)>½Ù}àa'H=…Lï í¤¼[2a3î¿ZgÒ&e•¨Ûß¬‚3#(û™ûÑ¨$ÈVh²–ó†§ƒÒD±Z>R6LãĞ»áªŞtÅ\‹İó75UÁEr…<‡Ó1-¿¬lFÆ®$ÑRGZXóÀ¾N³aIñÖ¿v£*æ¹}<ÔA˜V(ÖşÙ"˜3ñ+Ë1à¦İÔK–B‹™r)tí‡±£î‡«TG]jÃ4ãu&(úœÚÙYå~™êo`{^šnXSç:€g§9…µ(@aFÿ¯tN`I³àÌ…ËĞBa•dËŒ	Œ	ƒC&"Œ1ô¡Õµ<å=n ¨€^EÑÖÄô“Â“Ù4¤x{™“—İ+‘ø5©Æ+’½q”ÖKñHĞC”9ûpÜrH_M•ÛlmB-Oûö6QNUk+ÇĞ²ds©&´Õb5´Óªâ
_<Ÿ.:ÖŒ«R'üÓ‹äŞ®7½ç°-¯@òÜ7­ís–â¨—¢}¯<cÑB½M‰3+‡{5˜
ÏBÒ-ju¡NëÙòâÒº†ÄGÂNK…Ã.aLæäëÜ.9–ŠÔ9nˆº°•õ¡fƒÖZË†"J[›İ§A´Sy¯NºÚç$å¥Q)ÿ'8YĞ´Téî•F‰æÑÆdí¬æy?Õ†61U*Ò¾ì d™Õ®Ñ_ÊPÒI5ß°ëY¦¶åeˆ¡\›ÕÕ¹ŒÏ»8È”Ê!‘dø6ÍŸ(ˆ›Â (~Úş`;Dö=g¦°¢Âïİ‹o+%Ag©  -*×?®Ü¬{ÔshÙ8üeÜÍ‰¯ĞG®»Ó…yğ ¤ğÏzù³äÚEFCá$‰V3`B*şFkT{=]êGÎ«¤œó4‡FuOøŞÑªÊLks_3D«1G[ŸS`¨³ØÂK`vm2øÎÏ~ŸpçÓIÚBÈU¦£¼›"—ä²‹Kåˆ…T¹½›Œ9cÍ¶}u`/9ÑĞœúN(€«½Šô`ÄaÒ(ß!	?œú†cÉã–|~‹½Z”%ù•ïÏ|¿–,F7(¼iN(¶qbáğ×-sõá]ô3B=ñlÕÄºP»ÔïBãË‘_ìVh÷¤¸ _0á²9‚›,9î/fFÏ@ÄĞR‚3#s¼Ï5D)ªïùÅD–D7ä<„¨‡ptÇÄ¿™OŠö=Äšn‡ƒB0‚çfï1Ox<=:ûŒ3$ÔG–!“•dß¬ü°§FÂö>ï—Q]	XND<ÕÔs£4ˆS«5eöE5d’aL±Ù¥ÛTVD§j.{„íÌFg6ÇºGU
Bâ¢ŠñüÒ"ÚşşÅ­Há+F¯¿‘Œî™Ô6³%¡¼ÔMï]şì	Fâ/=òÖo9P-Ì|Iú,Y>…¹£—CÈŞ†”ñ3¥ÁkS›…eİ“v¥:vì¡&)Z¨(ntcófm¦ô
,sÎ¼Ã¶êÓ©!È¦&øLÆ?.Ö¢ª2ıæÅ	;|ë8 Ó0¢{Î42_RúJ­¯Qk“LèÑ¸¢G˜¹âL7'ì™0êÇÇ5ÌØKø:¢` aXõdÎñ3-¶J;·ã-~•Ù¥t†Ûù«²K'âİîj¸ûVluéºQVœ›cÜS&À¤œæ†"Llúë”WÀ,ğf›¥Ñå¹šüc«qİlZWì}‰w÷£wV¾&o3XúUœx¶ 9*Oı6jË`ã}pe< XÍÿRóñ*¡ÎAëóÏ¿:mB¼ˆ4e¶Ú¤­ËÕr+’ğ¦eÒG7ï•ìÑ½›Pà{³"·ÇÄOJ4ÍP&¤24€ce†C3ÇP¼m¡a[QH²FºU
õÚ±#yOU¥&™×üUQi…©·to1c+xº+j£iİÿ½'ÅJ¨rô"¼ë†Óö°K—µs“sy]åË%$v:_T`­Í—TR2ºk«gOö¡	{Œ3I( °5DO_¢)kŒ—Õ#pkŒMoVYC
!ô½h…JÁtëÔ±— ˆJ MZ&İé ç©³™zyí%íÂÚŸzg¢ı—|nÌò8Ÿù€@¯ç¼Wmà*WšuÊ¤§‰µoŞ©ã˜Pã¥&ŸÈz²!ß?BÕ9~%^š èWôğÿZñb·{!+"7êê`©¥¹s¸	û_^¸K;y/¹‘òßŠà’ŞÃZ¡÷6±u~û¥aik	ß ĞGú¼vpMbqrÁE7+‡ƒ%ºÚHSØwéşan=mNP9¢¬>İÑÖœÉ ^RœzĞT¾¬,
Ã›Hã«FúO:®FÁi« ·óJy:"E>¼Lã ÿtAÓú¯?Uä¤Äh¦À‡Lm¨ğ0¾Àl6Nb$¿£`ò–hÏE$¯geçjÒ-&äĞYºİ%ÙèRíØ²ú«õªûÆğ0Kƒ}rÇÿ„‚WzLÂı›=b‹âl%kD8~'íyÇtB÷ş0-Ü¯[®o|Ä|Ì¦0£•Óäb£é¤íÚºÑ·+Bx23QBù}À
TÏcz+l&…İ?øÓJÉ9v×MävâdÌÑö}u-©zÃ%²ÇD¨şEÔ]Æt¬áÔL¥Ç°~ïÙYK-P êú†˜ç$öŸyF-­¦«@ŒænŸSí¤ĞU2!wêÛR³¸Ù Üzïurhhn·EÆæ™²1ÂODà(èÅ›Pm¸½&Ò?o»Şo¹ê°’ìßeg[eï;h5çäH5Çk€Û¾¡^Æº¯´Ùzùÿ±½6&#¤»{úöì åŸºkiXg¢µ–„r¢ßl{‰q
ªé‰OÛ…SØi€³ë6åˆ˜ª“ôXeÜe³Ü3„å?$w8iTˆ¢‚90”È'üÛ‰1J›DÒá
˜’JŒY™RaÜ*H0' _ÅÚnÁşà (_í¦î‰‚ô-`!º.îıÄ|Ä{I iêÂz¿ß‹ÔiF…÷§¾g/İIÇJ,Èã
|¸• XøA"^.f} /PŠpëæ dZÎDĞ	Xq?ÏÑ²U	Jò ¼ÿóü²õwV—Vƒ'™9#û±‚ªUñl’Á†hôqJü¢d©[¼½X
oB`”¶üW5x³tÿ"†0…h%nàˆf¥eóá{Ú¸™Bj»×Ìç‚hçÚ}ˆÅ©ğQk8Ö¥ñ>¢„¸ºÃ`Ò¼ö[ì:wG¯+g¾@c=(h4UKûv¾¿9±Ô×cDìÅ™•B^sÕj¶ ù Í¦»O{·ä˜gét´'Şfs³$‡}ı¢™0‚¶Ù YFõé×(.`ª!<#ĞÄ*B Æ+_¶şY›ü¾MáL-öqº„çv8IA}è=;@oĞ:ÁĞ'
Ú?ByKh	Wõß³{™'.‰%ß»€Cµ³|öG°':ªi Ûï³ü&ª"ßú7¡õSpÆ£œˆpd£Ù†|ıaCF'BÆYMİ`Y²h%Né¯¢É,Ğa:k,â0±èZøƒò„FÑÌK,çpA–®øe­`”’<™#µßÄ¸îy »;)G²İnMRĞWâDÜÇŸG	>¿O=İëJÌùÚ~Ìmô£’â¦	ŞöÃ²?º½j5à|Âsşˆ0Øæ"öH¨ğ˜˜0 7×Ò†ºÀÌ/¢®[ZÑ£>óàQ<&¨Qhœ}ŞTj.O¤ÜÚyş;ßyëİªü/÷>€˜	FyÃúJëkuø¥¶†ôŸWƒ¦uòÈ°>\¬á^)‰ès•% ÙP`%åãÈëH²³?¨xêÆ†h=•çiŸæ¢6qü…ßÁï¡D ]L‡¤f!ï‘©.­ìİ†üÔ®¾VAòıØ€úñz,™îÔp¹­y¯E¦©² p=2TõÁæÁ†y´b_›”¤Õ®U0Wè%hò
„,¯<é2Ê]¸èÍ±Û8˜§÷&MµT"
p+÷Ù¸ÊÂäÊ±eL«ø^(ÿ…ó´jĞLQ|ãõ0Ò·o—âú3&Ï¢–¹¦åÏÀÌçAÈ]„Ô€¶Pìµ{@áêÅ¿Ëslíå¬'¯¬86Ğö­È‚(Úa"MÔA
· ‘G6z"TÄ.¦Ñ[3#Ò¨Ó·û+ÃƒÖ,Gœş|»zµ8jx:Ú9R©Pj_§òrc²L~†ÙUa5ÉËz—N¶ğ¾çÆ4Ş
èY‰Iê²¾|Äf?Â9Wu„°ƒ /Ç€ëëee§lX–yüÙQ—a2ÃJD±Å¹Ç£[‹+×]C@m¶¥JLMÛıÜN¬„òª}KÎëÊyG’àl¾«zëİµë÷6ÃÆá„ô¯­,«®Qµ–Ê0#°²%ÅV°Š¤ò†XIÛ=V®qL ò-±ıN¬§ùKÏı	³¦ú5Ä•í,[Ÿ…LÚ€³uãT˜‡l~p•Åß?`ÿ“N4{ôb%×wŒ\¯<åvXå Â99FWÚZ)F*¹Yß+Oü«O£Çªµ	¥ä‹‡:q½­îBU­PÏ~`Cw™2IÓ¹µªıÿÏŞk²%Ï7å©‚T&p$¶Ã(ÍŸÛ<'<”R(VÍo{qB¹$Ì±F†2Œæ‚Ii>Xx‘5µyÃo"¼r{Á†gly]Ï‚ùz
‡¤òTPÔ¸…iáæ*pœ+UØ?äŒzC~eº¦Zí6© Y×1mİ«5töœ|ælLìóU˜Œ-ˆ“Ö¿ˆ€Ñôüm·\¼bN_ÔQwÑ07Tç¾éß¡Â@ª†šÌ½V«?0ÒöBá„h¡Kê¼cN µO"Ë$±OúşÔ¥aõ(9FZfŸÒPË¦CŒì&B¹eSû´e<qãH„¬¤e*¹òr™ñË,ÚbôKÎÔİkä¡nt±Ü*Èİ~06/[+äa}­`r!0‚ñÒjî{˜Ø_O7<¥“)zlúQC}ù"¯ˆÌK àŸ6üsäI¦À'Å:X.!ĞÒ–¸/‘æLbs¡	|¿1ÎDûø=<×Øhz·ˆÑ˜ëë•H£h…x/‘Â"Ó¾ŒnóABŠ\’¹æê†l-wª3á·MƒM[oÙ®›‰ù	ß«‘dç¨aU¥6®­“pÅ49UX—cÈÜğíÂÅõñ­¥ÿz·eŒQÉ•‡ØqÉÇÍ6¶ˆ¯XJNy.ß¬4p×\ ŞJ=uŸZ÷*)¬j…ˆÀ‰Í/ÙñÃ^'EÃPÈ¬û‚Ñóş'nb½«õUÒuŒbDèkSëV†ßÑ{v!´Kâù@åÔö`=â?Eš@^Y/¦A)•³…ÒÑwøDQB)Õ7$lW@÷˜	Uu’÷oñÁ½ş)2ü&"©ãAÛy•QËCÎÕ‹säšƒ%æµìø[²évg¶ÃB¿è2Dª†Q¡öÄ½
û„f™Å,EØ]ÅW@w·µ­r)g699ñ˜3ÎªU½›Ï[í
Fš¸X¯8Ò©­“ÖGø(ˆ°L%şĞ£ú€ş»•M ,¢Mq„ÏL²+:8¶<h1 «Ë‹›¬ÏFş;xpÂâ±w›úÄgñ.TW<Â•çu¯§ı¦ÕüÚÜĞtš]RúÆ,yÌ0¢ºR%ìÈÿh$ËÓğË%ş.¢QĞÔ|)O\è‘Šº=“5vù®]º•I}‡¯¦"[°u¤º¨(‘p ã ¤ñ$0ÜŒ	ÜµàÃú[åEˆ›dv'ÄÖ¹*—@È¨ºÕéiÏsËu\½e7)†äå>Ç>&4›'/äULÿñ,z@ÌgÍÙ~©Ã$xÊ½­¼òPÏ½ö&ÆXÚ1ÁZJ n<QÊœÃuKºCxuŒšÀò«XM_yÑ²íÚuSşkw\%”èî^Zğ‹›Ã <÷l’é¬µÁàÃñçŠ–ÃÆyß»+­G¥LkJŠ±AÎw–!Júi¶¹¿ƒWcƒ?.
È&³_ÔÖ²šu¡ú„ø oê±RY¦êòN’ĞXø¨l1º„+p€/ó‹õÌøNŞäDv‚Å`ÃÏ‹8êÚ‰ˆ……Ëçiü6àå^êÄÊ½@({ÛŠ –¢ 8Ä¦ÑÑ<o®KÖì,îG.Bh5³ªwËÕƒæ+€”ù‹x*P­Æ­ÆÁŞä”âöAtİ)ŞËíw+½²ùÄ&`Èuá²@×=î,ÿ0iBùò•C´Eçš˜…'ñ@Šk[e´²”ñy_>Ÿ…ï)ù«ú¸Ç˜&FŸ¼Òù±æ}YôR=xB‰”ƒÏõ4+×4dSB¾?5•Ivg[C2ïh¬²K°¢»c’¦ó9¡¢xÍ©/ÜÃÍQÓFDD ßÏÉ€0Õ©4ü@òdr’Ÿw‡l›t·‘—=OHtÓTaÍRìÚ·%“u*–8Âm÷}|9ÊË h7ÔIsO‚XKæó\¨rDPú'7ËXÓ!tA‘B¯mäáp,ÂŸ…}BwE.RÇg\VN“¦º †z‡
Ò	õ™gözÚ—^Np€>+)#·I?î
îÆMaŒ­¸aHÅZ—zmF9Úp}>×	mc+³¥Œ@¸Æ¯œê}]{=ÜõhKaº¿³ç¸Bë\£p «t¢¢€ä© /v,5)ˆƒ~lz‘ù%O¯h´9WkÏ‚P`Ôú¸é2JeŞğX<nü²9ÓPĞÅj3 PšMŠ}Ê´ü0ou§c£a9¡¾Alsq§›Úxf$âÓ«h}'ŸşĞuûD|è@İO ápd9ÒÿÛØ;?Áœ€
KÙş#È‹rW†Çà«+€”‡ XÉ¶PS}¯…—Š8:$â>0TÃúõn¹©İoVh¡{¨·ALö’”U„=‹¹ôn“ËIy7ß`f™å‘U¡0ŠPÿ‘Ğ£éê¤ÌWßŒI7õ¼†ĞŸ:jØB>bWßåe5~=g¡‹ÿÓzMj*„xcÉûÂ¡);°³¦4¨ÓªÚá¢ñyEøÙ¶¬‡N ®<>O.²@[w]®Ñ>a¯{|Òqÿµ™ƒâÊ¥@²¯Îb İ|]²u¸ÓOB;T6ÆX™r=¨¢eSRµğôu³ÕğY,+)`È€ïÑ†E‰…7‰Ìä@(ª¾dŒ‡]÷PÍ
áŠ¶Ì#v}/Í†YkÄ£ªéZa•|
±›kô£¥(zŠ•|RÖ‰8°š2@_RN€lÌ)Ù„ñäö ’ÄCŸÙéÿ†TÇá®L(1<l_|Op±bõ?µ¼ {m«¢ß¹í
L6X!©í˜šçuw{R–ájŸ0¯­ìñq8¹Æ¾`>Å”ü)]ˆ“Ó›î,iE£ó*‡>ËTİö|ğœÎ&ïyoõ[«;Îî÷Öí?++Y‹¥ãÔş¦òœCA½Æ;©4$#4:}­+7Ö\Ü‘3qhÊ¹Çx¼ ‹oÚyş{Ê°>¡. ‘f@¥uêÔ¡Enî5É”ÃëÀä·õšáûvÑ£¯j{ôãßzeH±Íğsa§xÇÄ¥ùï™"™L#ÂäŠ¤†É×|kÄÊ!ş\\È‘²7mµªwºKòó†%(%Nâ²ÎO‰æ†Áğ±ßxƒ,¿Š9¡§½#r
ªêşåRRÎÌWĞûøzõû˜Ëµ"<&å5ñqUS<Ô;ä.¦âpC²`J¼ö¦~‚^”	#¹¬ëzY×~(7r¶Õ;ÃdŞ„»z9–÷Ë…æ6ImÊÓ˜+EõU'M&öÌÍË!¿ö$¿<7ØSCv…$K–Œ\vl?K7,æS[&pÊñ ’NE¦¶éqE‡ôì5”|87›.ş`¿zHÑúZ~ã´±mLîg·¤[w(Óò˜ˆcm~Ô7€±ÍĞJÌv…‡nÂñjØø`Óè#Ky‰t:ù½ˆÆñüŠN§W¶I˜ûz–ßxÅ;[÷WÊ7Sã^¿p÷ 8€¡BdM£[óg¶)›AÒ™NqÆŸÊ¹ÕPë¹i““knK<¦×ê´…FÚ¨kÒï·:7îN[|ÃÏ¯0s£oI)9usŸŞçÒ„ƒèó­k¶æ0İ!(ó÷¸V!›1s¦ê®Wí#GõFb 9ò“V(³ƒÑ*–¥¬Ù}ÈöLİ(²­¤‡Ãà~«Ã8¯„æi ¥~d‚·ó•«XÀ¤iûS6u@'XâÌ7²‚…¾Ä­?F+¥”ê”l´k0*}X&†«ŞlFI÷÷»	D<Po‰‰‰ƒŒË„5u“6
uxŒšÅÌ„ÿ>Óó‘ra%Ù@ù®FYÃÜky Š˜ i<M‘ø 'Dˆ·Â\…¯«³Rçã$æFvÏAI‚ÉV¼á—ıàëë$G¤qRŠèTIï)ûl=³¡Äá@æÒ'eâB¤~®iÂG£·…@usÓáÿ¯}Œëª0ÍéÓ,<€cªXLæ9& uj˜½GÅ:†$¬‘jãR“	İ²fcjé¤€Ñî}*\ÀÜd± ŒµMíŸÙ¬GríAÉı°+ò‚0eºÖNrfJìÒ›}Îe®ß"ˆ˜[-$f%(Ó"uØÕs±ÀÎÀ:EåË©[÷Îä‡…y™|©vÑÙ@S˜®ªÃÌé.®´İ|tL7„-U6ƒD“"&ğ8…^[bÇtîyÂÉ~P\ÉiÒ;ÃtTi=%”Î·ìÏW•ù½ÿúå1-Î t˜ñag,ƒ?`"ÛnJöãYÀ¹ù8€…    §¦Â™»Ób? ª²€ğL…ƒµ±Ägû    YZ