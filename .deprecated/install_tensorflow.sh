#!/bin/bash

# Asegúrate de que Anaconda esté en el PATH
source ~/.bashrc

# Crea un entorno Conda para TensorFlow
conda create -n tensorflow_env python=3.8 -y

# Activa el entorno
conda activate tensorflow_env

# Instala TensorFlow en el entorno
pip install tensorflow

