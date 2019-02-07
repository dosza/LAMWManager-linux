#!/bin/bash
#Universidade federal de Mato Grosso
#Curso ciencia da computação
#Versao PST: 2.0-rc10
#Versão  módulo bridge-root.sh: 0.0.1
#Descrição: Este script faz um bridge(ponte) para um terminal  usuário sem poderes administrativos, terem poderes administrativos

echo "Welcome to Bridge Root , exec: $*"
pkexec env DISPLAY=$DISPLAY XAUTHORITY=$XAUTHORITY $*
exit $?
