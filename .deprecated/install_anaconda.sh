#!/bin/bash

# Descarga el instalador de Anaconda
wget https://repo.anaconda.com/archive/Anaconda3-2023.11-Linux-x86_64.sh

# Da permisos de ejecución al instalador
chmod +x Anaconda3-2023.11-Linux-x86_64.sh

# Ejecuta el instalador
./Anaconda3-2023.11-Linux-x86_64.sh -b -p $HOME/anaconda3

# Agrega Anaconda al PATH
echo 'export PATH="$HOME/anaconda3/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Actualiza con conda
conda update -n base -c defaults conda

