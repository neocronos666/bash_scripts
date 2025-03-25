#!/bin/bash

# Actualiza la lista de paquetes
sudo apt-get update

# Instala dependencias
sudo apt-get install -y software-properties-common apt-transport-https

# Añade el repositorio de Microsoft para Visual Studio Code
sudo apt-get install -y wget
wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | sudo apt-key add -
sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'

# Actualiza la lista de paquetes e instala Visual Studio Code
sudo apt-get update
sudo apt-get install -y code

