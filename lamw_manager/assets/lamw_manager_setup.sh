#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="107455086"
MD5="84e37a7dff9febd86b501c03baf4b59b"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="19637"
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
	echo Date of packaging: Mon Nov 18 14:54:15 -03 2019
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
� ���]�<�v�F�~%��2ǖ�nN�Afi^dƒ�%)ۙ؇$�$,�
�������4���g�T�Qg���t������T��c^P���nP���u������wsɓ�e��B�-��vC��2��ԙS�vm/�.��
��i�w�;R�#H��6���F�Gh�l�^�P�%rV�eb2��~@�	�w����['�azT'��	48@'���y�'�'2��:����Ug+��pR�W��w��ώ�F���5��T�p1ӓ�Ѵ:�����5��E��`����lܝ_v�t��\��Iw4���7�I�܆Y��[���r��@�)�09�T=�@���y���E��6�T2�W���Ն�;j����;ĝs�J9�8�� Qkl�ɽ���Oo��0��,���.1�j� ߚ�kۮ���[#�[�o���e4M���L��'[7D�ļR�S�����,�W�*�ۛAaU�0a{E��0�`�GB�Yh�Ħ�6G� g��}6�v�@�����4��K�
�.�Wf@���|�S�H8�:v�3G'������J#)E�"�AI�J*	��jR 6�M�ln
+ɶ�ƈX[7��R	�8Y}�z>rݠ�>�J����ʑ@��2�ɱ2�!����k
��	)'\��J��8�����ƒG_?����,������*��������o{�Y!��y���5����%ڤ�ќM:�*M2���� m�#���KRe�(~�C��
L?#������ۻ��m6�������Z%��1�����!j��&}��~!��i�t6�v��:%�H7$�~�m^�
�� rA��uRA4���>YR��<� >�(�~�
Z���gD%�֨�bW!-��]��B�]�4��@�w����p�Gi�n��qɰM�ިcY�����~aR^��홉/�H�a���b�,�.`�Z�IR6iݡ����8`:/�>��f����C]~
�I��S�^NC0�����|ر�W��'����#)��RBN3%c�ި7�x�F�SX�&Ǳ�p��BL�Uw�%6��?5ЗL��E�tgژ6�&�2=�?�[�����W-s�9T5���`�C Q8i��bYD9�w[�&�9��h��j�D�Zˌ�S�#��?�K�Z��K�^�N�>�e\��?�PP����+)�W�8��@r ��Fr0����pn
�J�`��-:��v}Oܙo.���?@�0�/�0�O|�>'̴g�a�s��]!xf���a�ga�/b9Daw/~}���A\=.��&��|�T���ߌ�f0��Du��ٹ\��r�>UQ�ض��\�
�RZ!d���:���A�BD;���$����(,������J�]o(30�r6]��ݬ�}�Vyz�C�D`��������ٛ��I�o"[�C��;��<~u:i�rCV2�m=��:�N}��\��DhJ�Od�f}��%�� "��R|UqSº��<ɩ��� 	��y4d�Cx�c�(��b��F�@(&<���cS���o��ؕ�,iz���P�[�2c��
V ��1zJ��`ї?�`��M'��w'��j0�h�b . �{,��8�qi�� l{ ��Y�(�ū��ՎLb�����
6�����^�y8����ͯ��?+;��Vހ`�^n{:�"]�w���,��JV}j7���I��V&�a�I�]_b�����f�T�e��)�]],6BU��^��SP-b`�8
Ίn˟��wK��!v�dw2�� ����%����5�,����x���_� q�FM�@J� ��^f|n�X.U?n���{��#9�sA���h�����M�v<�DT��[؆��$x��8�u�+[|+
99��kf�$��#�(�fod��f�5LS\�2�(&C}~�/)�������3R�� ��Z�}�n?zM�8/�䗩��k&L�`
5L��X����^c��]����7v�������l,�)�e�`��$��輩D�XQ�3g�=��r�T�Ȩ��ו��/tG�с�V�y���[3B<�t�y<>{>�e<�h����=iM&��xE��o��O������'�;t�����߇�����A�
��W~�<&�o��(��S�!.�P��J��	i`Կ�+H|^8	��͋n��w�b1E���.JK���VZJMu�V�e���\�IC-��e��|
�PA��{=�QC�1[W9�e9Q�S&9C�LHR���i-� ������.Qq;X<G���/ޟ�zݚ?���1(j+��X�Ѫ=�k2�քjG�V�+�h=���^x������;�����qf�h��#�0�g=H�XZ�U��]��yO�"�.��mfgs���;)&2��(tE:�Z�M&?�D�F���d��eYˑ܃�lw����P���1��N4܌� ����R�<}�?�ea4˂`Gǟ����s��Od��[�a�2:�� �x{�Q���H�A���,�}�% ��|.ܹ��U(�d���[�(�.�,q�͏U\Ǻ�.}*�!��j�z�� 
�0*>}��G�U���Y�zd;k!yr>�92
��}K��F���(��er?+铣ߌE�('���d�.r��E�^��u�BљJ 9 e2���,�i����ω��F�߳��Uw�����:�W������5�.K6uB�i6.���	����oJ=]Ƈ���YɅ�$Q����޼����$0��y�@zE��� ͘<������aQ��O,bH�m�T�D1�ed�a��F�y#�nPv�O�R��kG4�.��H��SݦZ�r�	�y��������@�Dh�( ���_+"�Wx�\ꌅOQ%!��K}��]+!�?G_����`ݪ	]��~Ȧ���F��	�m��-m��n��k�j�t�"6�AF�<��@e��zx�f;\����G���Gg}൹.
��k
��'mKg����HNV@��J���[�0`���W����t��&��`s�ŧ���0�6b��<�3w
�Z��X�Kz
(�)ɻt��}`�^�VH�:0���QĥQ�
�*���:q�?��!,:�w5=鞞M���I\{*�),¬ 3#�]��q��v�4h��+צ1V~�
0�s�3�x�3]"p��Rҡ8�2�_�Z��J��Z`�.��C������gI��+7�����At���k�q���0:���~��:��Y��SUm/��1�:vݿs��z>h�^qIz�����Py�t.��M�O&�8s���
�e�]X����>�[7�1���>_�� )ֆ�?�^�M���/����1�r�A����"�+���Fgg��H~���Z4��W��Q㤻Ƃ�>�*� a]���8��Q�Ӂ+�8�'?r*��ohf|M���`i&c�N�rգ�\Bܑ-��,���h�?p�88m_t�����������"9�`�}�1d
�����������FD���(p��7�v�+p�
e�����~$&�����X�ŏz!�#��.���ۨ���;��o4K�+B��7 �޹�#��U�U��.�}�8S�w����L:�"k@Sɋ���*����O�n������n//G�խ�9\@�9�����[p#\Y��%���6��Ra%�4[$մ������R�����{�ޓY�j%�W�+&�C���0�RG_�T5��)u���QT�̝�kjQ�Y9��3t�N�����������tR%�M�SS�Q}�t),oTj'��A�w�����Z/�_�Ns���BM��i�|Κ�J��a��X|,J�<"eR	`�I(b)��Uzc�FF%V�x�%8g��Hp�\��o�U欫�5��V�N�;Scʥ}$�J�$�b�g�D1��t6{c���kFA��,J�L�/�;�;]fDDJ[��r�b��yV�L
�2}��u�ٞٝ�� �eڜ~])��a�|3g���8�o�LkC?O�G��&�+5x䬶�`e��a��3��ӹr�l�5�`u�����.���=�Q�����g�gK��[�4;f�y�����I�T�r��F�Gͷ!a�X0�Q~F� fH:��
��2݅N��33��E�]��hS�bŰV�`M�ɠ�+
�9�����lnWd�웾o�\�=�P�
R�´0��'�F�'}���̶*�j]q��V����/w��a�&�x}a%������Qc���ln�K�#C�h����nl`�2(��2���TI�(�M�2A�*C�
�ö�,����׀2�>q\�$U3�{�sa��f-tJ���N�YL�s7Ғ���3R�o��¢��d��=r]�_P�^	��W�	]玂7��+��ɳ+�J�R�#8�St��t���#�U_�m��zÊJC���u__\ס�g@S�h�Z��*���#t����I��x	lY)�����`��$j�ׁp����G&]��4�I�L���#`��')���s&�Yt�@�aЇ�4�ilЗ�16�~�z�x�x��Y3��d5j����
x��ţ�
G�|��#�q���]���/�,���/P>([`{��)�˶|Қ��?J�O7�+�l��5�)E�I�pj����@���+a��T6�Q¬+כ��;����-4-,��9�]o���6ˊ�D.��z�5߉o�FoF�kη�M' ��n&������?��=��z����c Vs8+����8��
qK���Kt[Q�K*\�	�y�.��񌷳�8��Faoȸ�$�tR$oV�tG$ �.y)�'2�sQBJ���y��p݂�]�Tp
��j
�hl�n���B7��fn���/�'	�Ϡځt8�oh�Ȳ�*+��ϙ�X�Q�s)�d�r�8𸤻���SB���~ɻ���Rl	����#�z��J�қ�7��^�C�oU[��)^���r�&n�����8O�&��tm_��J�~���[$��"��E�!��^K����=��e c��dK񳖏.n=y�*C�#""����'�M	{�����`�&��yo���R�QЁ;��� ���I}Y,.wG�E�'k+B�=H�c��C(GSΊ#�Ѹ��a��栌@HSj�;�Ɗ��-,��]]������iDÈou귺�-X��0��,E��D�T�/ �%���8��>����F?�d����5CN��ɇ�%�L�/}��WV+�K�dOx�j�5;��C��m��S����Ob'<���p�����B�Op�e�9[-��2��;�{�f���sz�U7��A[����7V5�]�n^�}$&	��]�e�����R�*`逸��4��4({�/��=��� �I�W�T�J�]"k��֘�rL�k㼪���J���)P�fkî�%��9��&0_6e�nyl���0Z
k�۹i�1̝;�D��^�π�0<�yyZa�"ڴ�n�P�
]A	\./p6�@�$�D��\��_�PM�̼�o�\���wӢ��9PN?!��vo�dT���-A���$>������q1G�Z�!m�r�I�񟚍g�D&g��7�0��,Hv8�h�Nm!|��3h�ܵ�z�N��/N��H��r�3��U��#*�"s��U�2��Pz���:_�ijF�2�['�"�/*��Z�)����Z��h�۞|sg1�|�N�i�#&����6����i2]�,@B
��5V}H`�搚��K1�ķ6�x�������(�䏝%�x�es
&S�v��4��,�R��F�q�u��O�N�Ek�������tOe���r��y��ov����F���?��%(�%)�=;-���jc�ʢ����#�|h G�K
�ٿ��`��y�ِ�`���:C��#������\��3&�H�õ�҉�J�-\���ETN����pa*��N�pB��_�}�u��E��&�C\�a/�+�e�i���'��VAq�Ie�"C�BR�I���L�A�1`0aX/��˚q�ߠ�;�.�abx��M������v^��nz͢5m����7��������Ζ�D��ƻMuګT.#?�U�K�:_��(ʥ��Դ*r/�Sg߲�̐{ٚB��W� v~�V�Ns����Vck��z�
!\�am'z�/O"�qB�B1�s�S���<!�nG�&Nk��6Mk�T��K���:AX�!�pD1��������=������o����i��gUFZ�?��*�b�g���.��e�z�����u��.sY���'J�b̓p��ʤ���x2�I=��5�I���m�
J�gc%}�,%.D���;V���=���i��n!{��;�q90Č��WQnvpf���� �G�ۥ�;
�E���+����%�5�����˃�|���KW��+k°ێ)��
<)A�uqv��Q\Vkڨ�a}&l?�oW�"Lғ���&�)/P'GY�7j�4g$�v�R��u>����(�xT�e��.�qBbYD�u�MZVR�SV��8�,�h��+��g�
��<d�ԌU��jY��T��(n���H�kt�\���H�kؾ{��H�A�z�H�ɂ^�S '����s��4~�oY�?���^��o��)��X�,��h���"╟ì�5Z�AХH_&�f�	N�>A��ä�j�e���#���W�`�/5��c�_)�L>�"���Ԗ���������1)��~0�u��6{�Ȣ� �)	�<���'X�x�&=z1�h�����;��^o��W3�iW��-JМ�1��*���e#Ӗk6fC�*u�F�S��3l�Q��lEK��{%����UX�::���Bt6�4��f�(a�KR�
eO�L���p�Lh�J�Н�['��P+8��U@Q����H�=1��B��Yd��V:��wH��@�|���S�/ic���r<<�$�FkR���9�=f��V|p9c`��K�����,�2��6 /��<�1��j��>1U�E�䆧P",v�n�{�z~?޿�����=�XY�#pr�
ۙ�bz38�]0�YV�`�������,x�|���y��{Vp����uv��C�6���cvڮ\��-�B)�RRo*3��Ye��m�F;)���C�VN�T�h�p�|�3��({`\����]�g
|M�ϖbs����p�Q'��ć�]
�ƒ$7�!�&s`�H`�,�̪ochy4)��Y5��S�kR,�7Ua^��9�^�
��3�l*�����j������h��4�]
`��1_������ܑpQ%qKɸ����5�N#�(
���rW�p�����O�k+��,{8(C{�e�5(���Q0��K;m��@���0Nt����ư��:�?l6��B�R %^�~{��i�����;�蘳0E�����_.}F��b(ޔ�6�
��o9F�K-�g
3|��k�T�_�Q�L����!��8�c������k9�g��������??v�?}�m:��Āv�$։q�|8p���|�J^
q�i\��%\x�����
i��-���i��^�Nq�=�%�d|2>^�1Y���(쉃�VQ T�O��V<nˉZ��T��������a�1�P�ړ���;j�"�e#�i|f2D:C�th�"�N��������L�7;u�|���*Z���Ӊ�7^S�
��F�O��jf��})��(�{�{6~0k�cB({ ��6������ҧ�9�q��v��W��ã���Q�u�:� W:��29돁cO� h뵵g�J�,n��VJ)���4e�I�즶cS��t�҈���4L��NM� ��9m�Tj��G�lS[�2�^{�E�R+�T����
�9фԢ��))ϣ��)����(�$�W��ӆ�p
��?��WL�	�s݆��ӵww*�Gh���Q�SA��r"�s���,��}�:�~e�h�r'��3��DQI����j2
:��X�
q�jq�/��7��ݣƾ��}&T�>JЛsbU�[����	�Ɇ��Q��	*S�y'�ҁ�3��t^30�>��px���*��OO+��;�{0+L�R�V�
�F�}ux,
�Mu{C�o���g��n��/�^t	$m��� ���j�Y�����}�Ą=��l|��A�y���[F���6��9�c�u鄠"���U��=��:�r�`Ұ�G��j�r7� N��|�v(���Q��trfv�(��_�F·�4��8�����s��SV5��pޛ���o�{)�u�	�!dT29�`q��C�C� "Z�-Ϳ�^}2��X�~3�tO�9�Ov�P��Y�\�-h+)	��T�!TȻ��á*�����Vp���pP�>���2���R��Q�{�^�L��y}mr�!�D�u�va����=�����5ϤF�G�*�C a�+tn��wk[�~W��q6,*�S+y�Zs��i����p���
���	�c7��>M`כV1�#ߦY8�&A]V^� s��?T%�.q����
sU4'm���R����fWg<��w4?��`��B՞)��L`;(�E�@H�epD=��
���`Wf�����Z�|v\[�Q��,����ji��i���J�W�&�D�w��
�d�'��/o�c����]���啶���-ǋu�/rI�ᓄ^(F�%�#t�M�%B��B��D�hAz��������=�T蟷��WfvZ�(*�J��N*M�g,��#�y�Zէ�1��@��������E{������/eI�
=���gR��:o^b�X�'+�Jm��<h���c�3��zaA��hT�q ��p��^�+�a
m#���2 �EiU�P��-,�j�y���kf8%�[[i�B��Bڍ,��!X�?�!Y���B�S��ў�2&�t�iI�V�n�j�]T<M����l���fF��t��yQ�T��V��r|a����)��P-d.�z*540����<�//>\ɂbDզ��i�[,�e@&��]E�x����;��d���=k��[h(����e/��8C?�Rܦ���7a+��0m�5W����k���y�͢B6����~�B��=�*�su4�|z"�lX�v����^��f��d޲�
����#1@j�c���yg���H*�\�O1�q%
��5
ֺ*��C���D��7�a�z����O� ����i�@ə�9<#�����u��V,�N�x,S�a�K`�)�Y�X\�b�Ie��c'ƮO���:�(LZc��pLE1=��Mzt���;��
;����L{s�y���.PG��ƋQ��Sͫ�z�����j�ΐ�K��i�n��N�!���GQ{k��JK�HcN�)�ň�N�t����2'#F�6R�#�(� �����N�>�#��Iv�ɗAr`�����=B�-����:E����:-+'Դi�$�h�D����7>}��\���I.�앰oJq/_y�yrJRR���X���(H�S�N��"�mV��V)�,|h�Ś�@�aSQ��v1W���%:5�&A��'y��;I���1�?���Z��ƿ����?w5�p�W�H��t��������*Ow9������z����n���G	����BcaLT���-��	�U���\Ԟ��,r�V�'�R��Vy�^���x����lu��t<�(xR����n˳[s{
fwr���I'g�������7�^8Õș�˥4�,hs{�-0nEY��K��|b>�yG+<��Y�ƕ�
'
�n��z�ܥ�zY�c�}>��{�{ԋ>�b����"�����@|��YІe(
Ωβ�2(��}�qo��16T����KH~_He�KJ,��eH)ĂN-2U�ip�t�k�ޭ�WWPU��JBs6�YC�i���<<�'j@!ןr�ϩ��)�Ͻ�T|&��l^�͞������L�^�&%a�Xll��	b0��jU8^f(T��Rפ�k�:�h��h��i�KN'<�2�@X��-���:K�pf�.3�����'pcD0E��p��
��j�3��Z��:�-o�UOt�^0A��8m&
�&%�@�G"Ap�+eR���E���p?��v|��A���,w)�=l����p7��:�x޿��g�����	�D�J�{��O��뫏s���=�����ُ�M����ވ5԰G� �aI&�t8�Ax)��`L�px
�sH��ϻ �<�:��i?������G/����8�_�i�mm>��_>����{ы]|��N:(
��l/����Z2AǪ�>l��c&f��:^��5�rb�T5�jAIEf}^Ŗ?�B��k��f
�wh��a����� L���lu��#Q���FXx(��j�B1sd<n��b���4��̕���|D�����/�K< �j8
�5=�r���GNQ3O��;�Ԥ�8b���k��\��|y��A�bH�s�p�!��Ӥ�ZS��Ց��D| >#�R���g����#z��b��+f�xD^k����
iX��ę��py��}�vs��iU����Am�|��[3#����+�ѓ�y�d�:�ݒ�3��4��Nj��Ԗ}֌���@j�́v�3�n�K��q�W��q���*��~p|�1�
��@FmBk��V_6lu&\U�B��w���	{zE���@o� 4T��m���C�+���N{��݂�ﶹ�������O3�����{�ߝ|>�jp����Mvg�����|���_�D��d��>���Q��p����Gq�ȏ}=�"fTeT��b>T���e�x�"Iޢ6B����}#�0i���n�O�9���h�-ON32�N�|oL%��I����廕.C�i���ܦ�3# %����@U�0n��+9!,�����$������i
��S�̔y�
��E� �����
��@b[T�ks�)b\!,h�(Qn�,W��|K�{��J�E�fהh��AB֦QR,�&�;v���M��b;Xɍ�m�7 ��"�?H$;�~J謺(3�$�e��{ʵ�FE��EBKd]ԓ���$��ي2n&���R�-Eݳd�\#n�$�Je��x���� ��!�uq<�2
�n�:0��_[}�}������������V
����� QC�8a��e�4���
$J�a�����gN�^^�j��R��[NY�����)�}�̸�ll��7`��/�6�Az�{^
surSgԔ	�2,�a�LUHp�A��s�(F����?�|�Ll��X��(��8�p��E�?v?����_m`���C�ݵ�xo޲?O���?į��=&َl/��q�,:B�u��.��qЁ� ��]'�:5OT:$���$"zE4��(��ܻ��:ғaM����x�� �OL��Vt���7mS7P(��:$Y��ӒB<|~����"3=7jz��T=�B�.8��A��gz�>�D�i!G$�,J�-�竸����?�������s�����?�������s��'���@�� h 