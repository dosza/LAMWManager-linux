#!/bin/bash
#-------------------------------------------------------------------------------------------------#
#Universidade federal de Mato Grosso (Alma Mater)
#Course: Science Computer
#Version: 0.4.0
#Date: 06/12/2021
#Description: The ".init_lamw_manager.sh" is part of the core of LAMW Manager. This script check conditions to init LAMW Manager
#-------------------------------------------------------------------------------------------------#

# Verifica condicoes de inicializacao
if [ ! -e /tmp/lamw-overrides.conf ]; then
	printf "${VERMELHO}Fatal Error: you need run lamw_manager first! ${NORMAL}\n"
	exit 1
fi

ps ax | grep $PPID | grep 'lamw_manager' > /dev/null
if [ $? != 0 ]; then
	echo "${VERMELHO}Fatal Error: you need run lamw_manager first! ${NORMAL}"
	exit 1
fi
