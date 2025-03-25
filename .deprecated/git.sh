#!/bin/bash

# Función para mostrar el menú principal
mostrar_menu() {
    echo " -----------------------------------------------"
    echo "|  G I T - A s s i s t a n t  | by neocronos666 |"
    echo " -----------------------------------------------"    
    echo "Seleccione un comando de Git:"
    echo "0. Salir"
    echo "1. git init - Inicializa un nuevo repositorio Git"
    echo "2. git clone [url] - Clona un repositorio"
    echo "3. git add [archivo] - Añade archivos al índice"
    echo "4. git commit -m '[mensaje]' - Realiza un commit con un mensaje"
    echo "5. git status - Muestra el estado del repositorio"
    echo "6. git log - Muestra el historial de commits"
    echo "7. git diff - Muestra diferencias entre commits"
    echo "8. git checkout [rama] - Cambia de rama"
    echo "9. git branch - Muestra las ramas"
    echo "10. git merge [rama] - Fusiona una rama"
    echo "11. git remote - Muestra los repositorios remotos"
    echo "12. git fetch - Descarga objetos y referencias desde otro repositorio"
    echo "13. git pull - Actualiza el repositorio local con cambios del remoto"
    echo "14. git push - Sube cambios al repositorio remoto"
    echo "15. git reset [archivo] - Resetea el índice"
    echo "16. git rm [archivo] - Elimina archivos del índice y del directorio de trabajo"
    echo "17. git mv [origen] [destino] - Mueve o renombra un archivo"
    echo "18. git show [commit] - Muestra información sobre un commit"
    echo "19. git tag [nombre] - Crea una nueva etiqueta"
    echo "20. git stash - Guarda cambios temporales"
    echo "21. git stash pop - Aplica cambios guardados en stash"
    echo "22. git stash list - Lista los stashes"
    echo "23. git stash drop - Elimina un stash"
    echo "24. git blame [archivo] - Muestra quién cambió cada línea de un archivo"
    echo "25. git clean -f - Elimina archivos no rastreados"
    echo "26. git reflog - Muestra el historial de referencias"
    echo "27. git shortlog - Muestra un resumen de commits"
    echo "28. git describe - Describe el estado del repositorio"
    echo "-------HASTA ACA HAY COMANDOS --------(CONTINUARÁ!))"
    echo "29. git grep [expresión] - Busca una expresión en el repositorio"
    echo "30. git archive - Crea un archivo tar o zip de los archivos del repositorio"
    echo "31. git bisect - Usa la búsqueda binaria para encontrar el commit que introdujo un bug"
    echo "32. git cherry-pick [commit] - Aplica cambios de un commit específico"
    echo "33. git rebase [rama] - Reaplica commits sobre otra base"
    echo "34. git revert [commit] - Revierte un commit"
    echo "35. git tag -d [nombre] - Elimina una etiqueta"
    echo "36. git log --oneline - Muestra el historial de commits en una línea"
    echo "37. git log --graph - Muestra el historial de commits como un gráfico"
    echo "38. git config --global - Configura opciones globales"
    echo "39. git config --local - Configura opciones locales"
    echo "40. git config --list - Lista todas las configuraciones"
    echo "41. git remote add [nombre] [url] - Añade un repositorio remoto"
    echo "42. git remote remove [nombre] - Elimina un repositorio remoto"
    echo "43. git fetch --all - Descarga todos los objetos y referencias"
    echo "44. git pull --rebase - Actualiza el repositorio local con rebase"
    echo "45. git push origin [rama] - Sube cambios a una rama específica"
    echo "46. git pull origin [rama] - Actualiza el repositorio local desde una rama específica"
    echo "47. git submodule add [url] [ruta] - Añade un submódulo"
    echo "48. git submodule update - Actualiza los submódulos"
    echo "49. git submodule init - Inicializa los submódulos"
    echo "50. git cherry [rama] [upstream] - Muestra commits que no han sido aplicados"
    echo "51. git diff --staged - Muestra diferencias entre el índice y el último commit"
    echo "52. git diff [commit] [commit] - Muestra diferencias entre dos commits"
    echo "53. git commit --amend - Modifica el último commit"
    echo "54. git log -p - Muestra el historial de commits con diferencias"
    echo "55. git diff --cached - Muestra diferencias entre el índice y el último commit"
    echo "56. git log --stat - Muestra el historial de commits con estadísticas"
    echo "57. git gc - Realiza la recolección de basura"
    echo "58. git fsck - Verifica la integridad del sistema de archivos"
    echo "59. git branch -d [rama] - Elimina una rama"
    echo "60. git branch -D [rama] - Fuerza la eliminación de una rama"
    echo "61. git merge --no-ff [rama] - Fusiona una rama sin fast-forward"
    echo "62. git branch --merged - Muestra ramas fusionadas"
    echo "63. git branch --no-merged - Muestra ramas no fusionadas"
    echo "64. git log --author='[nombre]' - Muestra commits de un autor específico"
    echo "65. git log --since='YYYY-MM-DD' - Muestra commits desde una fecha específica"
    echo "66. git log --until='YYYY-MM-DD' - Muestra commits hasta una fecha específica"
    echo "67. git log --grep='[patrón]' - Muestra commits que coinciden con un patrón"
    echo "68. git shortlog -s -n - Muestra un resumen de commits por autor"
    echo "69. git show-branch - Muestra ramas y sus commits"
    echo "70. git format-patch - Crea parches de commits"
    echo "71. git apply [parche] - Aplica un parche"
    echo "72. git am [parche] - Aplica un parche y lo registra como un commit"
    echo "73. git send-email - Envía commits por correo electrónico"
    echo "74. git bundle - Crea un archivo bundle"
    echo "75. git whatchanged - Muestra el historial de cambios"
    echo "76. git instaweb - Inicia un servidor web para ver el repositorio"
    echo "77. git verify-commit - Verifica la integridad de un commit"
    echo "78. git verify-tag - Verifica la integridad de una etiqueta"
    echo "79. git rerere - Resuelve conflictos de merge automáticamente"
    echo "80. git filter-branch - Reescribe el historial de commits"
    echo "81. git replace - Reemplaza objetos en el repositorio"
    echo "82. git cherry - Muestra commits que no han sido aplicados"
    echo "83. git cat-file - Muestra información sobre objetos en el repositorio"
    echo "84. git hash-object - Crea un objeto en el repositorio"
    echo "85. git ls-tree - Muestra el contenido de un árbol"
}

# Función para ejecutar el comando seleccionado
ejecutar_comando() {
    case $1 in
        0) echo "Saliendo..."; exit 0 ;;
        1) git init ;;
        2) read -p "Ingrese la URL: " url; git clone $url ;;
        3) read -p "Ingrese el archivo: " archivo; git add $archivo ;;
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
    echo -n "Seleccione una opción (0-20): "
    read opcion
    ejecutar_comando $opcion
    echo "Presione Enter para continuar..."
    read
done
