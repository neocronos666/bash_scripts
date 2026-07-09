# 🔰Bash Scripts🔰

## 🌟 Descripción 🌟
Bash Scripts es un **frontend minimalista** de línea de comandos para el shell, diseñado para proporcionar una interfaz rápida e interactiva para la ejecución de scripts y comandos en Linux. Su filosofía se basa en **usar solo Bash y comandos nativos en lo posible**, asegurando compatibilidad con cualquier terminal sin depender de software externo.

## 🛠️ Características 🛠️
- **Interfaz interactiva**: Permite navegar y ejecutar scripts desde un menú intuitivo.
- **Compatibilidad universal**: Funciona en cualquier terminal Linux sin necesidad de dependencias adicionales.
- **Flexibilidad**: Puede ser modificado y personalizado según las necesidades del usuario.
- **Soporte para scripts y directorios**: Permite acceder a scripts y directorios organizados por categorías.
- **Ejecución de comandos en vivo**: Se pueden ejecutar comandos directamente desde la interfaz sin salir de ella.

## 🛡️ Instalación 🛡️
1. Clona el repositorio en tu equipo:
```bash
git clone https://github.com/usuario/bash_scripts.git
```
2. Accede al directorio del proyecto:
```bash
cd bash_scripts
```
3. Asegúrate de que los scripts sean ejecutables:
```bash
chmod +x ayuda comandos-*.sh */*.sh
```
4. Agrega el directorio al `PATH` para poder ejecutarlo desde cualquier ubicación:
```bash
export PATH="$PWD:$PATH"
```
   Para hacerlo permanente, agrega la línea anterior a tu `~/.bashrc` o `~/.bash_profile`.


5. Editar el archivo `ayuda`para agregar la ruta absoluta de la ubicacion del directorio `bash_scripts`
```bash
nano ayuda
```
```bash
# Directorio base donde están los scripts
BASE_DIR="/home/tu-usuario/Documentos/bash_scripts"
```
6. Editar el archivo `ayuda.sh`para agregar la ruta absoluta de la ubicacion del archivo `README.md` (este archivo).
    ```bash
   nano ayuda.sh
   ```
```bash
# Archivo a mostrar
README_FILE="/home/neocronos/Documentos/bash_scripts/README.md
```

## 🎉 Uso 🎉
Para iniciar la interfaz, simplemente escribe en cualquier directorio:
```bash
ayuda
```
Aparecerá el siguiente menú interactivo:

NOTA:Al se rparte del prompts, puede ser accedido desde cualquier entorno y los comandos se ejecutan en ese entorno, muy util para conocer rapidamente los entornos de desarrollo presentes en terminales desconocidas.
```
🔰             
    ╭─────────────────────────────────────────────────────────────────╮
    │        🧃  COMANDOS INTERACTIVOS RAPIDOS               │
    ╰────────────────────────────────────────────────────────────────╯
📝 Scripts disponibles:
         [1] comandos-generales.sh
         [2] comandos-git.sh
         [3] comandos-server.sh
         [4] desinstalar-y-limpiar.sh
         [5] info-environment.sh
         [6] info-hardware.sh
         [7] info-ip.sh
         [8] info-terminal.sh

📁 Directorios disponibles:
         [d1]monitoreo/
         [d2]scrapping/
         [d3]setup/
         [d4]tweaks/

         [*] ⮩ volver
         [0] ⏿ Salir
```
Puedes:
- Seleccionar un script escribiendo su número.
- Abrir un directorio escribiendo `d` seguido del número.
- Escribir un comando directamente, el cual se ejecutará en la terminal sin salir de la interfaz.
- Presionar `0` para salir.

## 📃 Scripts disponibles 📃
Los scripts incluidos proporcionan diversas funcionalidades:

### 📊 Información del sistema 📊
- `info-environment.sh`: Muestra información sobre las variables de entorno.
- `info-hardware.sh`: Proporciona datos detallados sobre el hardware del sistema.
- `info-ip.sh`: Muestra información de red y direcciones IP.
- `info-terminal.sh`: Da detalles sobre la terminal en uso.

### 🛠️ Administración de sistemas 🛠️
- `comandos-generales.sh`: Colección de comandos útiles.
- `comandos-git.sh`: Atajos y comandos rápidos para trabajar con Git.
- `comandos-server.sh`: Comandos para administrar servidores.
- `desinstalar-y-limpiar.sh`: Facilita la eliminación de paquetes y la limpieza del sistema.

## 🎓 Contribuciones 🎓
Este proyecto está pensado como una base para que cada usuario lo modifique y personalice según sus necesidades. Se anima a los técnicos de reparación, desarrolladores, administradores de sistemas y diseñadores a forkarlo y adaptarlo a su flujo de trabajo.

Si quieres contribuir, puedes:
1. Hacer un fork del repositorio.
2. Crear una rama con tus modificaciones.
3. Enviar un pull request con mejoras o nuevas funcionalidades.
4. Puede que tu trabajo se incorpore a la rama principal y/o se cree una version exclusiva para tu gremio.

## 🎨 Personalización 🎨  
Esta aplicación está diseñada para ser **totalmente personalizable**. Por defecto, muestra automáticamente los archivos `.sh` en el directorio actual, lo que significa que puedes **agregar o quitar comandos simplemente creando o eliminando archivos `.sh` o directorios**. ¡Las posibilidades son infinitas! 🚀  

Los scripts que muestran variables tienen los comandos a mano y explicaciones sobre cómo editarlos para adaptarlos a tus necesidades.  

Además, es **muy fácil cambiar los colores** porque están **declarados al principio del código**. Si deseas agregar nuevas secciones, puedes **copiar los bloques de código UNICODE** utilizados y editarlos a tu gusto.  

Existe un **archivo de plantilla en desarrollo**, el cual contiene algunos ejemplos de la interfaz utilizada. Sin embargo, la **interfaz es completamente abierta**, por lo que puedes **reciclar fragmentos de código y adaptarlos** como prefieras.  

## 💡 Filosofía de la App 💡  
El objetivo principal de esta aplicación es proporcionar **una herramienta de línea de comandos ligera y accesible** que funcione de la manera más eficiente posible en equipos modernos y antiguos. Se busca que **no ocupe espacio innecesario**, sea fácil de transferir y mantener, y funcione **de manera limpia usando solo comandos nativos de Linux**.  


## 📚 Licencia 📚
Este proyecto está bajo una licencia que permite su uso y modificación con atribución, pero restringe su uso comercial. (Aún por definir, sugerencias bienvenidas).

## 👤 Autor 👤
Este proyecto fue desarrollado por [Sergio Silvestri](https://github.com/neocronos666).

Ojalá te sea útil!🔰


