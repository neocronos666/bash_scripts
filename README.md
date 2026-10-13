# 🔰Bash Scripts🔰

## 🌟 Descripción 🌟
Bash Scripts es un **frontend minimalista** de línea de comandos para el shell, diseñado para proporcionar una interfaz rápida e interactiva para la ejecución de scripts y comandos en Linux. Su filosofía se basa en **usar solo Bash y comandos nativos en lo posible**, asegurando compatibilidad con cualquier terminal sin depender de software externo.

## 🛠️ Características 🛠️
- **Interfaz interactiva**: Permite navegar y ejecutar scripts desde un menú intuitivo.
- **Compatibilidad universal**: Funciona en cualquier terminal Linux sin necesidad de dependencias adicionales.
- **Flexibilidad**: Puede ser modificado y personalizado según las necesidades del usuario.
- **Soporte para scripts y directorios**: Permite acceder a scripts y directorios organizados por categorías.
- **Directorios ejecutables**: Los directorios que contienen un `MAIN.sh` se abren como herramientas independientes desde el navegador.
- **Ejecución de comandos en vivo**: Se pueden ejecutar comandos directamente desde la interfaz sin salir de ella.
- **Gestión de kernels**: Incluye caminos automático y manual para descargar, configurar, compilar, instalar y mantener kernels Linux.

## 🛡️ Instalación 🛡️
1. Clona el repositorio en tu equipo:
```bash
git clone https://github.com/neocronos666/bash_scripts.git
```
2. Accede al directorio del proyecto:
```bash
cd bash_scripts
```
3. Asegúrate de que los scripts y tableros `MAIN.sh` sean ejecutables:
```bash
find . -type f \( -name '*.sh' -o -name ayuda \) -exec chmod +x {} +
```
4. Agrega el directorio al `PATH` para poder ejecutarlo desde cualquier ubicación:
```bash
export PATH="$PWD:$PATH"
```
   Para hacerlo permanente, agrega la línea anterior a tu `~/.bashrc` o `~/.bash_profile`.


La ruta se detecta automáticamente. Opcionalmente puede definirse
`BASH_SCRIPTS_HOME` para iniciar el navegador en otro directorio y
`BASH_SCRIPTS_README` para usar otro archivo de ayuda.

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
         [-1]monitoreo/
         [-2]scrapping/
         [-3]setup/
         [-4]tweaks/

         [*] ⮩ volver
         [0] ⏿ Salir
```
Puedes:
- Seleccionar un script escribiendo su número.
- Seleccionar un directorio escribiendo `-` seguido de su número; por ejemplo, `-4` abre `tweaks/`.
- Escribir un comando directamente, el cual se ejecutará en la terminal sin salir de la interfaz.
- Escribir `**` para consultar la información del clima.
- Presionar `0` para salir.

### Navegación por directorios

`ayuda` muestra los scripts con números positivos (`1`, `2`, `3`...) y los
directorios con números precedidos por un guion (`-1`, `-2`, `-3`...). El
guion permite distinguir visualmente una acción ejecutable de un cambio de
directorio y mantiene la selección cómoda desde el teclado numérico.

Los directorios se muestran de dos formas:

- **Directorio navegable**: no contiene `MAIN.sh`. Al seleccionarlo con `-N`,
  `ayuda` entra en él y vuelve a construir la lista de scripts y
  subdirectorios disponibles. En el menú se muestra en rojo.
- **Directorio ejecutable**: contiene un archivo `MAIN.sh`. Al seleccionarlo
  con `-N`, `ayuda` ejecuta su `MAIN.sh` desde ese mismo directorio. Cuando el
  tablero termina, se regresa al navegador sin cambiar el directorio que se
  estaba explorando. En el menú se muestra en verde.

Actualmente `tweaks/linux-kernel/` es un directorio ejecutable. Esta
convención permite que un conjunto relacionado de scripts conserve sus
rutas relativas y tenga su propio menú, sin incorporar su lógica dentro de
`ayuda`.

La opción `*` puede seguir subiendo más allá del repositorio. Es una función
intencional para usar `ayuda` como navegador de scripts del sistema.

Cuando una entrada no coincide con el menú se ejecuta como una línea de Bash.
Esto permite argumentos, pipes y redirecciones, pero también puede modificar o
eliminar datos: revise el comando antes de confirmarlo.

## Compatibilidad y dependencias

El launcher requiere Bash y utilidades GNU habituales (`find`, `sort` y
`mapfile`). Los módulos de administración están orientados a Linux; los
instaladores actuales apuntan principalmente a Debian/Ubuntu.

Cada herramienta adicional se comprueba en el script que la necesita cuando
es posible. Entre las dependencias opcionales están `curl`, `wget`, `pandoc`,
`yt-dlp`, `ffmpeg`, `git`, `systemd`, Docker y las herramientas de Proxmox.

Los scripts de `seguridad/`, `setup/` y `tweaks/` pueden utilizar `sudo` o
realizar cambios importantes. Lea su contenido y la confirmación mostrada
antes de ejecutarlos.

## Desarrollo y validación

```bash
make check
```

La validación comprueba la sintaxis de todos los scripts vigentes y ejecuta
ShellCheck cuando está instalado. `.deprecated` se conserva como archivo
histórico y no forma parte de estas comprobaciones.

## 📃 Scripts disponibles 📃
Los scripts incluidos proporcionan diversas funcionalidades:

### 🐧 Gestión de kernels Linux

El directorio ejecutable `tweaks/linux-kernel/` contiene un tablero para dos
formas de trabajo:

- **Actualización automática**: consulta kernels binarios de Ubuntu
  Noble/Linux Mint disponibles mediante APT, muestra los paquetes y permite
  instalarlos sin eliminar kernels anteriores, reiniciar ni cambiar el
  kernel predeterminado de GRUB.
- **Flujo manual**: enlaza los scripts para descargar fuentes oficiales,
  administrar árboles dentro de `.kernels/`, guardar configuraciones y
  compilaciones en `.cfgs/`, compilar paquetes `.deb` e instalar el resultado.
- **Mantenimiento**: permite limpiar descargas locales, auditar el sistema y
  desinstalar kernels instalados con protecciones para el kernel activo, el
  predeterminado y el último kernel arrancable.
- **Gestión de GRUB**: permite elegir el kernel predeterminado después de
  probarlo manualmente, ajustar el timeout y la visibilidad del menú,
  conservar la detección de otros sistemas y regenerar la configuración.

Para abrirlo desde `ayuda`, se selecciona el número con guion asignado a
`tweaks/linux-kernel/`. También puede ejecutarse directamente:

```bash
./tweaks/linux-kernel/MAIN.sh
```

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

La licencia todavía debe ser elegida por el autor. Hasta que exista un archivo
`LICENSE`, el repositorio no concede automáticamente permisos de copia,
redistribución o modificación fuera de lo permitido por la legislación
aplicable.

## 👤 Autor 👤
Este proyecto fue desarrollado por [Sergio Silvestri](https://github.com/neocronos666).

Ojalá te sea útil!🔰
