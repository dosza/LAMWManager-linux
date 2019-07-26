#!/bin/bash
# export LAMW_ENV=/home/danny/LAMW/lamw4linux;export PATH=$LAMW_ENV/usr/bin:$LAMW_ENV/usr/lib/fpc/3.3.1:$PATH
# export LD_LIBRARY=$LAMW_ENV/usr/lib:$LD_LIBRARY
# #sudo ldconfig
# FPC_ARGS="$*"
# echo "$FPC_ARGS" >>  ~/analise-fpc.txt
# case "$FPC_ARGS" in
# 	*"arm"*)
# 		echo "$(date) none detected" >> ~/fpc-detected.txt
# 		echo "cmd-line:$FPC_ARGS" >> ~/fpc-detected.txt
# 		echo "" >> ~/fpc-detected.txt
# 		ppcarm $FPC_ARGS
# 	;;
# 	*"aarch64"* | *"arm64"* )
# 		echo "$(date) aarch64 detected" >> ~/fpc-detected.txt
# 		echo "cmd-line:$FPC_ARGS" >> ~/fpc-detected.txt
# 		echo "" >> ~/fpc-detected.txt
# 		ppca64 $FPC_ARGS
# 	;;
# 	*)
# 		echo "$(date) none detected" >> ~/fpc-detected.txt
# 		echo "cmd-line:$FPC_ARGS" >> ~/fpc-detected.txt
# 		echo "" >> ~/fpc-detected.txt
# 		ppcx64 $FPC_ARGS
# 	;;
# esac
export LAMW_ENV=/home/danny/LAMW/lamw4linux
export PATH=$LAMW_ENV/usr/bin:$LAMW_ENV/usr/lib/fpc/3.3.1:$PATH
export LD_LIBRARY=$LAMW_ENV/usr/lib:$LD_LIBRARY
#sudo ldconfig
export FPC_ARGS=($*)
export FPC_EXEC="ppcx64"
for((i=0;i<${#FPC_ARGS[*]};i++))
do
	case "${FPC_ARGS[i]}" in
		"-Parm")
			echo "$(date) arm detected" >> ~/fpc-detected.txt
 			echo "cmd-line:$FPC_ARGS" >> ~/fpc-detected.txt
 			echo "" >> ~/fpc-detected.txt
 			export FPC_EXEC="ppcarm"
			break
		;;

		"-Paarch64")
			echo "$(date) aarch64 detected" >> ~/fpc-detected.txt
			echo "cmd-line:$FPC_ARGS" >> ~/fpc-detected.txt
			echo "" >> ~/fpc-detected.txt
			export FPC_EXEC="ppca64"
			break
		;;
	esac
done

echo "$FPC_EXEC" >> ~/void-ptr.txt
$FPC_EXEC $*