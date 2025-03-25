#!/bin/bash

# Colores para una salida más elegante
RED="\e[31m"
GREEN="\e[32m"
CYAN="\e[36m"
YELLOW="\e[33m"
NC="\e[0m"

# Función para mostrar el menú principal
mostrar_menu() {
    clear
    echo -e "🔰              "
    echo -e "${CYAN}    ___________ 🖳 ${NC} GIT - HITHUB 🖧${CYAN}___________\n"
    #echo -e "${GREEN}    📂 Directorio: ${NC}/home/neocronos/Documentos/\n"
    #echo -e "${CYAN}    _________________________________________________\n"
    
    # Listar los comandos disponibles
    echo -e "    ${NC}📝 Comandos de Git:"
    echo -e "         ${YELLOW}[1]${RED} git init ${NC} - ${GREEN}Inicializa un nuevo repositorio Git"
    echo -e "         ${YELLOW}[2]${RED} git clone [url] ${NC} - ${GREEN}Clona un repositorio"
    echo -e "         ${YELLOW}[3]${RED} git add [archivo] ${NC} - ${GREEN}Añade archivos al índice"
    echo -e "         ${YELLOW}[4]${RED} git commit -m '[mensaje]' ${NC} - ${GREEN}Realiza un commit con un mensaje"
    echo -e "         ${YELLOW}[5]${RED} git status ${NC} - ${GREEN}Muestra el estado del repositorio"
    echo -e "         ${YELLOW}[6]${RED} git log ${NC} - ${GREEN}Muestra el historial de commits"
    echo -e "         ${YELLOW}[7]${RED} git diff ${NC} - ${GREEN}Muestra diferencias entre commits"
    echo -e "         ${YELLOW}[8]${RED} git checkout [rama] ${NC} - ${GREEN}Cambia de rama"
    echo -e "         ${YELLOW}[9]${RED} git branch ${NC} - ${GREEN}Muestra las ramas"
    echo -e "         ${YELLOW}[10]${RED} git merge [rama] ${NC} - ${GREEN}Fusiona una rama"
    echo -e "         ${YELLOW}[11]${RED} git remote ${NC} - ${GREEN}Muestra los repositorios remotos"
    echo -e "         ${YELLOW}[12]${RED} git fetch ${NC} - ${GREEN}Descarga objetos y referencias desde otro repositorio"
    echo -e "         ${YELLOW}[13]${RED} git pull ${NC} - ${GREEN}Actualiza el repositorio local con cambios del remoto"
    echo -e "         ${YELLOW}[14]${RED} git push ${NC} - ${GREEN}Sube cambios al repositorio remoto"
    echo -e "         ${YELLOW}[15]${RED} git reset [archivo] ${NC} - ${GREEN}Resetea el índice"
    echo -e "         ${YELLOW}[16]${RED} git rm [archivo] ${NC} - ${GREEN}Elimina archivos del índice y del directorio de trabajo"
    echo -e "         ${YELLOW}[17]${RED} git mv [origen] [destino] ${NC} - ${GREEN}Mueve o renombra un archivo"
    echo -e "         ${YELLOW}[18]${RED} git show [commit] ${NC} - ${GREEN}Muestra información sobre un commit"
    echo -e "         ${YELLOW}[19]${RED} git tag [nombre] ${NC} - ${GREEN}Crea una nueva etiqueta"
    echo -e "         ${YELLOW}[20]${RED} git stash ${NC} - ${GREEN}Guarda cambios temporales"
    echo -e "         ${RED}-------HASTA ACA HAY COMANDOS --------(CONTINUARÁ!))"
    echo -e "         ${YELLOW}[21]${RED} git stash pop ${NC} - ${GREEN}Aplica cambios guardados en stash"
    echo -e "         ${YELLOW}[22]${RED} git stash list ${NC} - ${GREEN}Lista los stashes"
    echo -e "         ${YELLOW}[23]${RED} git stash drop ${NC} - ${GREEN}Elimina un stash"
    echo -e "         ${YELLOW}[24]${RED} git blame [archivo] ${NC} - ${GREEN}Muestra quién cambió cada línea de un archivo"
    echo -e "         ${YELLOW}[25]${RED} git clean -f ${NC} - ${GREEN}Elimina archivos no rastreados"
    echo -e "         ${YELLOW}[26]${RED} git reflog ${NC} - ${GREEN}Muestra el historial de referencias"
    echo -e "         ${YELLOW}[27]${RED} git shortlog ${NC} - ${GREEN}Muestra un resumen de commits"
    echo -e "         ${YELLOW}[28]${RED} git describe ${NC} - ${GREEN}Describe el estado del repositorio"
    echo -e "         ${YELLOW}[29]${RED} git grep [expresión] ${NC} - ${GREEN}Busca una expresión en el repositorio"
    echo -e "         ${YELLOW}[30]${RED} git archive ${NC} - ${GREEN}Crea un archivo tar o zip de los archivos del repositorio"
    echo -e "         ${YELLOW}[31]${RED} git bisect ${NC} - ${GREEN}Usa la búsqueda binaria para encontrar el commit que introdujo un bug"
    echo -e "         ${YELLOW}[32]${RED} git cherry-pick [commit] ${NC} - ${GREEN}Aplica cambios de un commit específico"
    echo -e "         ${YELLOW}[33]${RED} git rebase [rama] ${NC} - ${GREEN}Reaplica commits sobre otra base"
    echo -e "         ${YELLOW}[34]${RED} git revert [commit] ${NC} - ${GREEN}Revierte un commit"
    echo -e "         ${YELLOW}[35]${RED} git tag -d [nombre] ${NC} - ${GREEN}Elimina una etiqueta"
    echo -e "         ${YELLOW}[36]${RED} git log --oneline ${NC} - ${GREEN}Muestra el historial de commits en una línea"
    echo -e "         ${YELLOW}[37]${RED} git log --graph ${NC} - ${GREEN}Muestra el historial de commits como un gráfico"
    echo -e "         ${YELLOW}[38]${RED} git config --global ${NC} - ${GREEN}Configura opciones globales"
    echo -e "         ${YELLOW}[39]${RED} git config --local ${NC} - ${GREEN}Configura opciones locales"
    echo -e "         ${YELLOW}[40]${RED} git config --list ${NC} - ${GREEN}Lista todas las configuraciones"
    echo -e "         ${YELLOW}[41]${RED} git remote add [nombre] [url] ${NC} - ${GREEN}Añade un repositorio remoto"
    echo -e "         ${YELLOW}[42]${RED} git remote remove [nombre] ${NC} - ${GREEN}Elimina un repositorio remoto"
    echo -e "         ${YELLOW}[43]${RED} git fetch --all ${NC} - ${GREEN}Descarga todos los objetos y referencias"
    echo -e "         ${YELLOW}[44]${RED} git pull --rebase ${NC} - ${GREEN}Actualiza el repositorio local con rebase"
    echo -e "         ${YELLOW}[45]${RED} git push origin [rama] ${NC} - ${GREEN}Sube cambios a una rama específica"
    echo -e "         ${YELLOW}[46]${RED} git pull origin [rama] ${NC} - ${GREEN}Actualiza el repositorio local desde una rama específica"
    echo -e "         ${YELLOW}[47]${RED} git submodule add [url] [ruta] ${NC} - ${GREEN}Añade un submódulo"
    echo -e "         ${YELLOW}[48]${RED} git submodule update ${NC} - ${GREEN}Actualiza los submódulos"
    echo -e "         ${YELLOW}[49]${RED} git submodule init ${NC} - ${GREEN}Inicializa los submódulos"
    echo -e "         ${YELLOW}[50]${RED} git cherry [rama] [upstream] ${NC} - ${GREEN}Muestra commits que no han sido aplicados"
    echo -e "         ${YELLOW}[51]${RED} git diff --staged ${NC} - ${GREEN}Muestra diferencias entre el índice y el último commit"
    echo -e "         ${YELLOW}[52]${RED} git diff [commit] [commit] ${NC} - ${GREEN}Muestra diferencias entre dos commits"
    echo -e "         ${YELLOW}[53]${RED} git commit --amend ${NC} - ${GREEN}Modifica el último commit"
    echo -e "         ${YELLOW}[54]${RED} git log -p ${NC} - ${GREEN}Muestra el historial con parches"
    echo -e "         ${YELLOW}[55]${RED} git reflog expire ${NC} - ${GREEN}Elimina entradas obsoletas en el reflog"
    echo -e "         ${YELLOW}[56]${RED} git reset --hard ${NC} - ${GREEN}Descarta cambios no confirmados"
    echo -e "         ${YELLOW}[57]${RED} git pull --no-ff ${NC} - ${GREEN}Realiza un merge sin fast-forward"
    echo -e "         ${YELLOW}[58]${RED} git push --force ${NC} - ${GREEN}Sube los cambios forzados"
    echo -e "         ${YELLOW}[59]${RED} git diff --name-only ${NC} - ${GREEN}Muestra solo los nombres de los archivos modificados"
    echo -e "         ${YELLOW}[60]${RED} git gc ${NC} - ${GREEN}Realiza una recolección de basura"
    
    # Opciones del menú
    echo -e "\n    ${YELLOW}[0] ⮹ Volver\n"
}

# Llamada al menú principal

# Función para ejecutar el comando seleccionado
ejecutar_comando() {
    case $1 in
        0) exit 0 ;;
        1) git init ;;
        2) read -p "Ingrese la URL: " url; git clone $url ;;
        3) read -p "📝 Ingrese el archivo: " archivo; git add $archivo ;;
        4) read -p "Ingrese el mensaje: " mensaje; git commit -m "$mensaje" ;;
        5) git status ;;
        6) git log ;;
        7) git diff ;;
        8) read -p "Ingrese la rama: " rama; git checkout $rama ;;
        9) git branch ;;
        10) read -p "Ingrese la rama: " rama; git merge $rama ;;
        11) git remote ;;
        12) git fetch ;;
        13) git pull ;;
        14) git push ;;
        15) read -p "Ingrese el archivo: " archivo; git reset $archivo ;;
        16) read -p "Ingrese el archivo: " archivo; git rm $archivo ;;
        17) read -p "Ingrese el origen: " origen; read -p "Ingrese el destino: " destino; git mv $origen $destino ;;
        18) read -p "Ingrese el commit: " commit; git show $commit ;;
        19) read -p "Ingrese el nombre: " nombre; git tag $nombre ;;
        20) git stash ;;
        21) git stash pop ;;
        22) git stash list ;;
        23) git stash drop ;;
        24) read -p "Ingrese el archivo: " archivo; git blame $archivo ;;
        25) git clean -f ;;
        26) git reflog ;;
        27) git shortlog ;;
        28) git describe ;;
    esac
}
# Ciclo principal del script
while true; do
    mostrar_menu
    echo -n "⭕ Seleccione una opción (0-20): "
    read opcion
    ejecutar_comando $opcion
    echo -e "${YELLOW} ⏳ (continuar)"
    read
done
