#!/usr/bin/env bash
set -euo pipefail

# =========================
# Config
# =========================
CONDA_HOME="${HOME}/anaconda3"
LOG="${HOME}/anaconda_cleanup_$(date +%Y%m%d_%H%M%S).log"
PATTERNS_CONDA_REMOVE=("upbge" "blender")               # nombres de paquetes conda
PATTERNS_PIP_UNINSTALL=("frappe-bench" "honcho" "gunicorn" "bench")  # nombres pip
# Si tenés otra ruta para conda, cambiá CONDA_HOME arriba.

# =========================
# Helpers
# =========================
human() { numfmt --to=iec --suffix=B --padding=7 "$1" 2>/dev/null || echo "$1"; }
du_safe() {
  local path="$1"
  if [ -e "$path" ]; then du -sb "$path" 2>/dev/null | awk '{print $1}'; else echo 0; fi
}
info() { echo -e "[INFO] $*" | tee -a "$LOG"; }
warn() { echo -e "[WARN] $*" | tee -a "$LOG"; }
ok()   { echo -e "[ OK ] $*" | tee -a "$LOG"; }

# =========================
# Prechequeos
# =========================
if [ ! -d "$CONDA_HOME" ]; then
  warn "No existe ${CONDA_HOME}. ¿Es correcta la ruta de tu Anaconda?"
  exit 1
fi

# Intentar cargar conda (shell hook)
if command -v conda >/dev/null 2>&1; then
  eval "$(conda shell.bash hook)" || true
else
  # fallback: buscar binario de conda en CONDA_HOME
  if [ -x "${CONDA_HOME}/bin/conda" ]; then
    PATH="${CONDA_HOME}/bin:${PATH}"
    eval "$(${CONDA_HOME}/bin/conda shell.bash hook)" || true
  else
    warn "No encuentro 'conda' en PATH ni en ${CONDA_HOME}/bin. Abortando."
    exit 1
  fi
fi

# =========================
# Medición inicial
# =========================
SIZE_PKGS_BEFORE=$(du_safe "${CONDA_HOME}/pkgs")
SIZE_CACHE_PIP_BEFORE=$(du_safe "${HOME}/.cache/pip")
SIZE_CACHE_CONDA_BEFORE=$(du_safe "${HOME}/.conda/pkgs")

info "Log en: $LOG"
info "Espacio inicial:"
info "  anaconda3/pkgs        : $(human ${SIZE_PKGS_BEFORE})"
info "  ~/.cache/pip          : $(human ${SIZE_CACHE_PIP_BEFORE})"
info "  ~/.conda/pkgs         : $(human ${SIZE_CACHE_CONDA_BEFORE})"

# =========================
# 1) Limpieza conda: caches, tarballs, paquetes no usados
# =========================
info "Ejecutando 'conda clean' (tarballs, index, logs, paquetes-no-usados)..."
conda clean -y --tarballs --index-cache --logfiles --packages 2>&1 | tee -a "$LOG"
# Si querés limpieza total de TODO cache: usar --all (equivale a tarballs+index+packages+source)
# conda clean -y --all 2>&1 | tee -a "$LOG"

# =========================
# 2) Recorrer entornos y desinstalar lo que pediste
# =========================
info "Listando entornos conda..."
mapfile -t ENVS < <(conda env list | awk 'NR>2 && $1!~/^#|^\*$/ {print $1}')

# Asegurar incluir "base" aunque no aparezca bien parseado
if ! printf '%s\n' "${ENVS[@]}" | grep -qx "base"; then
  ENVS=("base" "${ENVS[@]}")
fi

for ENV in "${ENVS[@]}"; do
  info "---- Entorno: ${ENV} ----"
  conda activate "$ENV" 2>/dev/null || { warn "No pude activar $ENV"; continue; }

  # 2a) Intentar quitar conda packages específicos (si existieran)
  for PKG in "${PATTERNS_CONDA_REMOVE[@]}"; do
    if conda list | awk '{print $1}' | grep -E "^${PKG}$" >/dev/null 2>&1; then
      info "Eliminando conda pkg '${PKG}' de ${ENV} ..."
      conda remove -y "${PKG}" 2>&1 | tee -a "$LOG" || warn "Fallo conda remove ${PKG} en ${ENV}"
    else
      info "(no encontrado en conda) ${PKG} en ${ENV}"
    fi
  done

  # 2b) Intentar quitar pip packages (si existieran)
  if command -v pip >/dev/null 2>&1; then
    for PP in "${PATTERNS_PIP_UNINSTALL[@]}"; do
      if pip show "$PP" >/dev/null 2>&1; then
        info "Desinstalando pip pkg '${PP}' de ${ENV} ..."
        pip uninstall -y "$PP" 2>&1 | tee -a "$LOG" || warn "Fallo pip uninstall ${PP} en ${ENV}"
      else
        info "(no encontrado en pip) ${PP} en ${ENV}"
      fi
    done
  else
    warn "pip no disponible en ${ENV}"
  fi

  conda deactivate >/dev/null 2>&1 || true
done

# =========================
# 3) Limpiar cachés locales (pip / conda user cache)
# =========================
info "Limpiando caché de pip (~/.cache/pip)..."
rm -rf "${HOME}/.cache/pip" 2>/dev/null || true

info "Limpiando caché user de conda (~/.conda/pkgs NO es la del core)..."
rm -rf "${HOME}/.conda/pkgs" 2>/dev/null || true

# =========================
# Medición final
# =========================
SIZE_PKGS_AFTER=$(du_safe "${CONDA_HOME}/pkgs")
SIZE_CACHE_PIP_AFTER=$(du_safe "${HOME}/.cache/pip")
SIZE_CACHE_CONDA_AFTER=$(du_safe "${HOME}/.conda/pkgs")

FREED_PKGS=$(( SIZE_PKGS_BEFORE - SIZE_PKGS_AFTER ))
FREED_PIP=$(( SIZE_CACHE_PIP_BEFORE - SIZE_CACHE_PIP_AFTER ))
FREED_CONDA=$(( SIZE_CACHE_CONDA_BEFORE - SIZE_CACHE_CONDA_AFTER ))
FREED_TOTAL=$(( FREED_PKGS + FREED_PIP + FREED_CONDA ))

info "Espacio final:"
info "  anaconda3/pkgs        : $(human ${SIZE_PKGS_AFTER})"
info "  ~/.cache/pip          : $(human ${SIZE_CACHE_PIP_AFTER})"
info "  ~/.conda/pkgs         : $(human ${SIZE_CACHE_CONDA_AFTER})"

ok   "Liberado aprox: $(human ${FREED_TOTAL}) (detalles en $LOG)"
RecR
