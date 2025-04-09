#!/bin/bash

echo "🧰 Actualizando sistema..."
sudo apt update && sudo apt upgrade -y

echo "🔧 Instalando herramientas necesarias..."
sudo apt install -y git curl apt-transport-https ca-certificates gnupg lsb-release

echo "🐳 Instalando Docker..."
# Agrega la clave GPG oficial de Docker
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Configura el repositorio estable
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Instala Docker Engine
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "⚙️ Habilitando Docker para uso sin sudo..."
# Crea el grupo docker si no existe
sudo groupadd docker 2>/dev/null
# Agrega el usuario actual al grupo
sudo usermod -aG docker $USER

echo "✅ Docker instalado. Probando con hello-world..."
# Este paso sólo funcionará después de reiniciar sesión si es sin sudo
if docker run hello-world > /dev/null 2>&1; then
    echo "✅ Docker está funcionando correctamente (sin sudo)."
else
    echo "⚠️ Docker instalado, pero aún necesitas reiniciar sesión para usarlo sin sudo."
    echo "   Podés probar con: sudo docker run hello-world"
fi

echo "📦 Instalando Docker Compose v2 (si no está incluida)..."
DOCKER_COMPOSE_BIN="/usr/local/bin/docker-compose"
if ! command -v docker-compose &>/dev/null; then
  sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
    -o "$DOCKER_COMPOSE_BIN"
  sudo chmod +x "$DOCKER_COMPOSE_BIN"
  echo "✅ Docker Compose instalado manualmente en $DOCKER_COMPOSE_BIN"
else
  echo "✅ Docker Compose ya está disponible."
fi

echo "📁 Verificando versiones:"
docker --version
docker-compose --version
git --version

echo "🚀 Todo listo. Cerrá y volvé a iniciar sesión para aplicar los permisos de Docker sin sudo."

