#!/bin/bash

# Pedir el mail al usuario
read -p "Ingrese el correo electrónico: " email
clear
# Ejecutar holehe con el mail ingresado
holehe "$email"

read
