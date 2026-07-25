# AGENTS.md

## Propósito

Este archivo define las reglas de trabajo para agentes de IA que modifiquen el repositorio `bash_scripts`.

El objetivo es mantener scripts Bash simples, legibles, modulares y consistentes entre sí. Antes de crear, modificar o refactorizar código, el agente debe revisar este documento y respetar sus convenciones.

---

## 1. Objetivo del repositorio

`bash_scripts` reúne herramientas de consola para Linux, entre ellas:

- automatización de tareas frecuentes;
- administración básica de sistemas;
- descargas y procesamiento de archivos;
- scraping y análisis de recursos web;
- utilidades de red;
- instalación y configuración de entornos;
- comandos reutilizables para terminal;
- scripts auxiliares para servidores y equipos personales.

Los scripts deben poder utilizarse de forma independiente siempre que sea razonable.

---

## 2. Principios generales

El código debe priorizar:

1. claridad;
2. mantenibilidad;
3. comportamiento predecible;
4. dependencias mínimas;
5. compatibilidad con Bash;
6. modularidad sin fragmentación innecesaria;
7. mensajes de consola claros;
8. recuperación segura ante errores;
9. posibilidad de ampliar el script en futuras versiones.

No se debe agregar complejidad sin una necesidad concreta.

---

## 3. Entorno objetivo

Salvo indicación contraria:

- shell: Bash;
- plataforma principal: Linux;
- codificación: UTF-8;
- idioma de interfaz y comentarios: español;
- ejecución interactiva desde terminal;
- ruta de instalación variable;
- el repositorio no debe depender de estar ubicado en una ruta fija.

El encabezado recomendado es:

```bash
#!/usr/bin/env bash
```

Para scripts nuevos, usar por defecto:

```bash
set -o errexit
set -o pipefail
set -o nounset
```

Estas opciones pueden omitirse únicamente cuando exista una razón técnica documentada.

---

## 4. Estructura del repositorio

La estructura general esperada es similar a:

```text
bash_scripts/
├── AGENTS.md
├── README.md
├── .lib/
│   ├── colores.sh
│   ├── comunes.sh
│   └── banner.sh
├── scrapping/
├── sistema/
├── redes/
├── multimedia/
└── otros-directorios/
```

### `.lib/`

El directorio `.lib/` contiene funciones realmente compartidas por varios scripts.

Ejemplos válidos:

- colores;
- banners;
- tablas;
- pausas;
- validaciones genéricas;
- detección de comandos;
- utilidades comunes de interfaz.

No mover funciones a `.lib/` solo para reducir el tamaño de un script.

Una función específica de una herramienta debe permanecer en el archivo de esa herramienta.

---

## 5. Organización interna de los scripts

Los scripts deben organizarse en bloques claramente identificables.

Orden recomendado:

```text
1. Encabezado
2. Opciones estrictas de Bash
3. Configuración
4. Configuración de interfaz o tablas
5. Carga de librerías
6. Variables globales
7. Funciones de interfaz
8. Funciones auxiliares
9. Funciones principales por dominio
10. Funciones generales
11. main
12. Inicio
```

Separar bloques con encabezados como:

```bash
########################################
# FUNCIONES DE DESCARGA
########################################
```

Evitar mezclar código ejecutable con definiciones de funciones, excepto la llamada final a `main`.

---

## 6. Función `main`

Todo script no trivial debe tener una función `main`.

Ejemplo:

```bash
main() {
    preparar_entorno
    ejecutar_flujo
}

main "$@"
```

No distribuir el flujo principal por todo el archivo.

Las funciones deben realizar tareas concretas y tener nombres descriptivos.

---

## 7. Convenciones de nombres

### Constantes y configuración global

Usar mayúsculas:

```bash
APP_NAME="wp-scrapper"
VERSION="0.1.0"
TIMEOUT=10
MAX_RETRIES=3
```

### Variables locales

Usar minúsculas y declararlas con `local`:

```bash
local archivo
local destino
local intento
```

### Funciones

Usar minúsculas y guion bajo:

```bash
scan_analizar
filter_aplicar
descarga_ejecutar
```

Cuando ayude a organizar el código, usar prefijos por dominio:

```text
ui_
tmp_
cache_
scan_
filter_
descarga_
red_
sistema_
```

No usar nombres ambiguos como `hacer`, `procesar`, `funcion1`, `dato` o `temp` salvo que el contexto sea completamente evidente.

---

## 8. Convención de navegación

Los scripts interactivos deben utilizar una interfaz consistente.

### Teclas reservadas

```text
0   Salir del programa o cancelar definitivamente
1-9 Seleccionar acciones
*   Volver al paso anterior
?   Mostrar ayuda contextual
ENTER Aceptar el valor predeterminado, cuando exista
```

### Reglas

- `0` siempre debe significar salir, no volver.
- `*` debe utilizarse para volver o subir un nivel.
- Las opciones principales deben ser números enteros.
- Evitar opciones basadas en letras como `S/N`, `D`, `R` o `V`.
- No crear un menú principal cuando el flujo puede comenzar directamente con una pregunta.
- Los scripts deben poder manejarse, tanto como sea posible, con el teclado numérico.

Ejemplo correcto:

```text
URL (0=Salir):
```

Ejemplo de acciones:

```text
1) Descargar
2) Refinar filtros
*) Nueva URL
0) Salir
?) Ayuda
```

Ejemplo de descargas pendientes:

```text
1) Reanudar
2) Ignorar
0) Salir
?) Ayuda
```

La ayuda con `?` puede quedar reservada en versiones tempranas, pero no debe asignarse a otra acción.

---

## 9. Entrada del usuario

Usar `read -r` para evitar que las barras invertidas sean interpretadas.

Ejemplo:

```bash
read -rp "URL (0=Salir): " URL
```

Validar toda entrada que controle el flujo.

Ejemplo:

```bash
case "$opcion" in
    1)
        ejecutar_accion
        ;;
    0)
        exit 0
        ;;
    \*)
        volver
        ;;
    \?)
        mostrar_ayuda
        ;;
    *)
        ui_error "Opción inválida."
        ;;
esac
```

No asumir que el usuario introducirá un valor válido.

---

## 10. Salida de consola

La interfaz debe ser clara, compacta y coherente.

Preferir:

```bash
printf '%s\n' "Texto"
```

o:

```bash
echo "Texto"
```

No usar una cadena que comience con `-` como formato directo de `printf`.

Incorrecto:

```bash
printf "--------\n"
```

Correcto:

```bash
printf '%s\n' "--------"
```

o:

```bash
echo "--------"
```

Para datos variables, preferir formatos explícitos:

```bash
printf 'Resultados: %d\n' "$cantidad"
```

No usar `echo -e` salvo que sea estrictamente necesario.

---

## 11. Colores e interfaz compartida

Antes de utilizar una función de `.lib/`, revisar su firma real.

No inferir la API de una función por su nombre.

Las librerías pueden depender de variables globales de configuración, como:

```bash
ANCHO_ETIQUETA=22
ANCHO_VALOR=20
```

Cuando se utiliza `set -o nounset`, esas variables deben definirse antes de cargar o invocar la librería.

No duplicar colores ni funciones de interfaz que ya existan en `.lib/`.

---

## 12. Manejo de errores

Los errores esperables deben tratarse explícitamente.

Ejemplos:

- URL inaccesible;
- dependencia faltante;
- archivo inexistente;
- directorio sin permisos;
- fallo de red;
- descarga incompleta;
- entrada inválida;
- resultado vacío.

Un resultado vacío no siempre es un error fatal. El script debe ofrecer una salida clara.

Ejemplo:

```text
No se encontraron archivos.

1) Probar otra URL
0) Salir
?) Ayuda
```

No ocultar errores importantes con `|| true` de forma indiscriminada.

Usar `|| true` únicamente cuando el fallo sea esperado y no deba detener el flujo.

---

## 13. Archivos temporales y caché

Usar `mktemp` cuando sea posible.

Ejemplo:

```bash
archivo_tmp="$(mktemp "$CACHE_DIR/lista.XXXXXX")"
```

Eliminar temporales cuando ya no sean necesarios.

Para recursos pendientes o reanudables, utilizar archivos persistentes con una extensión y formato documentados.

En scripts de descarga, los archivos `.t` pueden representar colas pendientes.

El flujo recomendado es:

1. detectar pendientes al iniciar;
2. ofrecer reanudar, ignorar o salir;
3. preguntar la URL después de resolver los pendientes;
4. eliminar cada entrada completada;
5. eliminar el archivo `.t` cuando quede vacío.

---

## 14. Dependencias externas

Antes de utilizar una herramienta externa, comprobar que esté instalada.

Ejemplo:

```bash
command -v curl >/dev/null 2>&1 || {
    ui_error "Falta la dependencia: curl"
    exit 1
}
```

Evitar agregar dependencias cuando Bash, `sed`, `awk`, `grep`, `find` o herramientas GNU habituales sean suficientes.

Sin embargo, no implementar parsers complejos y frágiles solo para evitar una dependencia razonable.

Toda dependencia nueva debe:

- tener una función concreta;
- estar documentada;
- validarse al inicio;
- ofrecer un mensaje de instalación claro.

---

## 15. Red y descargas

Para operaciones de red:

- definir timeout;
- utilizar un User-Agent identificable;
- seguir redirecciones cuando corresponda;
- limitar reintentos;
- validar códigos HTTP;
- evitar bucles infinitos;
- no descargar contenido sin confirmación cuando el volumen pueda ser grande.

En scrapers recursivos, evitar:

- seguir enlaces externos accidentalmente;
- recorrer directorios padres;
- repetir URLs;
- generar recursión ilimitada;
- ignorar diferencias entre URLs absolutas y relativas.

---

## 16. Formatos de datos internos

Cuando una función produce datos que otra función consumirá, el formato debe ser estable y documentado.

Ejemplo de registro tabulado:

```text
nombre<TAB>tamaño<TAB>url
```

Lectura recomendada:

```bash
while IFS=$'\t' read -r nombre tamano url
do
    ...
done < "$archivo"
```

No mezclar mensajes de interfaz con datos enviados por `stdout`.

Cuando una función se utiliza en un pipeline:

- datos por `stdout`;
- mensajes informativos por `stderr`, o fuera del pipeline.

---

## 17. Comentarios

Los comentarios deben explicar:

- por qué se tomó una decisión;
- qué formato se espera;
- qué riesgo se evita;
- qué comportamiento no es evidente.

No comentar instrucciones obvias.

---

## 18. Refactorización

Antes de refactorizar:

1. comprender el flujo actual;
2. identificar funciones y contratos;
3. mantener el comportamiento observable;
4. evitar cambiar interfaz y lógica al mismo tiempo;
5. realizar cambios pequeños y verificables.

No reescribir un script completo si basta con sustituir bloques concretos.

Una reescritura amplia debe justificarse por alguno de estos motivos:

- lógica irrecuperablemente acoplada;
- múltiples errores estructurales;
- requisitos nuevos incompatibles;
- imposibilidad de probar partes de forma aislada;
- riesgo mayor al mantener el diseño actual.

---

## 19. Pruebas mínimas

Todo cambio relevante debe validarse al menos con:

```bash
bash -n ruta/al/script.sh
```

Cuando `shellcheck` esté disponible:

```bash
shellcheck ruta/al/script.sh
```

También deben probarse manualmente los caminos principales:

- entrada válida;
- entrada vacía;
- `0`;
- `*`, cuando corresponda;
- `?`, cuando esté implementado;
- dependencia faltante;
- red inaccesible;
- cero resultados;
- uno o más resultados;
- error durante una descarga;
- reanudación de pendientes.

No afirmar que un script funciona sin haber realizado al menos validación sintáctica.

---

## 20. Compatibilidad y seguridad

Siempre citar variables:

```bash
rm -f "$archivo"
```

Evitar:

```bash
rm -f $archivo
```

No utilizar `eval` salvo que sea absolutamente inevitable y esté justificado.

No construir comandos concatenando entrada del usuario.

Evitar escrituras destructivas sin validación.

No solicitar ni almacenar credenciales en texto plano.

---

## 21. Versionado

Los scripts deben incluir una versión visible:

```bash
VERSION="0.1.0"
```

Usar versionado semántico como referencia:

```text
MAJOR.MINOR.PATCH
```

- `PATCH`: corrección sin cambio funcional significativo;
- `MINOR`: función nueva compatible;
- `MAJOR`: cambio incompatible de interfaz o comportamiento.

Actualizar la versión solo cuando el cambio esté listo para integrarse.

---

## 22. Cambios realizados por agentes

Cuando un agente modifique código debe informar:

1. qué archivos cambió;
2. qué comportamiento alteró;
3. qué errores corrigió;
4. qué validaciones ejecutó;
5. qué limitaciones permanecen.

No presentar como completado algo que no fue probado.

No eliminar código existente sin explicar el motivo.

No modificar archivos ajenos a la tarea salvo que sea imprescindible.

---

## 23. Flujo recomendado para Codex

Antes de editar:

1. leer `AGENTS.md`;
2. inspeccionar la estructura del repositorio;
3. abrir las librerías utilizadas por el script;
4. revisar firmas reales de funciones compartidas;
5. ejecutar `git status`;
6. identificar el alcance exacto del cambio;
7. realizar una modificación pequeña;
8. validar con `bash -n`;
9. ejecutar `shellcheck` si está disponible;
10. mostrar el diff resultante.

Antes de crear funciones nuevas, buscar si ya existe una utilidad equivalente.

---

## 24. Acciones prohibidas sin autorización explícita

Un agente no debe:

- cambiar la convención `0`, `*`, `?`;
- introducir un menú principal innecesario;
- mover funciones específicas a `.lib/` sin justificación;
- reemplazar Bash por otro lenguaje;
- instalar dependencias;
- ejecutar comandos destructivos;
- borrar archivos del usuario;
- alterar configuraciones del sistema;
- realizar commits;
- hacer push;
- reescribir el historial Git;
- cambiar permisos masivamente;
- modificar secretos o credenciales;
- descargar grandes cantidades de datos;
- cambiar la estructura completa del repositorio.

Estas acciones requieren autorización explícita.

---

## 25. Criterio para considerar terminado un cambio

Un cambio está terminado cuando:

- cumple el requisito solicitado;
- respeta este documento;
- mantiene el estilo del archivo;
- no introduce errores sintácticos;
- maneja entradas inválidas;
- conserva rutas y variables citadas;
- no rompe funciones compartidas;
- fue validado;
- el agente puede explicar claramente el resultado.

---

## 26. Convención específica de interfaz

La navegación estándar del repositorio queda definida así:

```text
0   salir
1-9 seleccionar acciones
*   volver
?   ayuda
ENTER aceptar valor predeterminado
```

Esta convención debe considerarse parte de la interfaz pública de los scripts.

Cualquier excepción debe estar documentada dentro del script y justificada por una limitación técnica real.
