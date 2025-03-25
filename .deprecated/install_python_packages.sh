#!/bin/bash

# Actualiza la lista de paquetes
sudo apt-get update

# Instala Python y pip
sudo apt-get install -y python3 python3-pip python3-venv

# Instala herramientas de desarrollo básicas
sudo apt-get install -y build-essential libssl-dev libffi-dev python3-dev

# Instala paquetes de Python necesarios para ciencia de datos
pip3 install numpy pandas scipy matplotlib seaborn scikit-learn

