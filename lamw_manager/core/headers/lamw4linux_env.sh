!/bin/bash
#-------------------------------------------------------------------------------------------------#
#Universidade federal de Mato Grosso (Alma Mater)
#Course: Science Computer
#Version: 0.4.0.3
#Date: 07/29/2021
#Description: The "lamw_headers" is part of the core of LAMW Manager. This script contains LAMW Manager variables.
#-------------------------------------------------------------------------------------------------#

LAMW_MANAGER_LOCAL_CONFIG_DIR="$LAMW_USER_HOME/.lamw_manager"
LAMW_MANAGER_LOCAL_CONFIG_PATH="$LAMW_MANAGER_LOCAL_CONFIG_DIR/local_lamw_manager.cfg"
DEFAULT_ROOT_LAMW="$LAMW_USER_HOME/LAMW"
SET_ROOT_LAMW #RAIZ DO AMBIENTE LAMW 
LAMW4_LINUX_PATH_CFG="$LAMW_USER_HOME/.lamw4linux"
LAMW4LINUX_HOME="$ROOT_LAMW/lamw4linux"
LAMW_IDE_HOME="$LAMW4LINUX_HOME/lamw4linux" # path to link-simbolic to ide 
LAMW_WORKSPACE_HOME="$LAMW_USER_HOME/Dev/LAMWProjects"  #path to lamw_workspace
LAMW4LINUX_EXE_PATH="$LAMW_IDE_HOME/lamw4linux"
LAMW_MENU_ITEM_PATH="$LAMW_USER_HOME/.local/share/applications/lamw4linux.desktop"

OLD_ANDROID_SDK=1
LAMW_INSTALL_STATUS=0
LAMW_IMPLICIT_ACTION_MODE=0
FLAG_FORCE_ANDROID_AARCH64=1

INDEX_FOUND_USE_PROXY=-1
CURRENT_OLD_LAMW_INSTALL_INDEX=-1
MAGIC_TRAP_INDEX=-1

USE_PROXY=0
TIME_WAIT=2