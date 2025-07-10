#!/bin/bash

# Actualiza la lista de paquetes
sudo apt-get update

# Instala Python y paquetes básicos
sudo apt-get install -y python3 python3-pip python3-venv build-essential libssl-dev libffi-dev python3-dev
pip3 install numpy pandas scipy matplotlib seaborn scikit-learn

# Instala Git
sudo apt-get install -y git

# Descarga e instala Anaconda
wget https://repo.anaconda.com/archive/Anaconda3-2023.11-Linux-x86_64.sh
chmod +x Anaconda3-2023.11-Linux-x86_64.sh
./Anaconda3-2023.11-Linux-x86_64.sh -b -p $HOME/anaconda3

# Agrega Anaconda al PATH
echo 'export PATH="$HOME/anaconda3/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Actualiza con conda
conda update -n base -c defaults conda

# Crea un entorno Conda para TensorFlow
#conda create -n tensorflow_env python=3.8 -y

# Activa el entorno
#source ~/.bashrc
#conda activate tensorflow_env

# Instala TensorFlow en el entorno
#pip install tensorflow

# Instala Visual Studio Code
sudo apt-get install -y software-properties-common apt-transport-https
wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | sudo apt-key add -
sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
sudo apt-get update
sudo apt-get install -y code

# -----Paquetes Necesarios

#Para Bajar youtube y reproducir video
sudo apt install -y yt-dlp ffmpeg
    #Necesario para leer las cookies 
pip install --upgrade browser-cookie3




















