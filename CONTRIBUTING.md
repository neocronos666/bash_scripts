# Contribuir

Los scripts deben ser compatibles con Bash y no deben modificar el sistema al
ser cargados con `source`.

Antes de enviar cambios:

```bash
make check
```

Las operaciones destructivas deben mostrar el objetivo, pedir una confirmación
explícita y, cuando sea viable, ofrecer una vista previa. Las rutas personales
no deben quedar codificadas: use `$HOME`, la ubicación del propio script,
argumentos o variables documentadas.

El directorio `.deprecated` es histórico y no forma parte de las validaciones.
