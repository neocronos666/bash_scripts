#!/bin/bash

cabecera(){

linea

echo " Host..... $(hostname)"
echo " Usuario.. $USER"
echo " Kernel... $(uname -r)"
echo " IP....... $(hostname -I | awk '{print $1}')"

if [[ -n "$SSH_CONNECTION" ]]
then
    echo " Sesión... SSH"
else
    echo " Sesión... Local"
fi

linea

}
