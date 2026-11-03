# Estado de Android y alcance de las pruebas

**Revisado el 2 de noviembre de 2026.** Esta página separa el estado descrito por el proyecto oficial de las cifras aportadas por los archivos originales de esta guía.

## Estado indicado por el upstream

La documentación oficial consultada indica que Android requiere arm64, Android 13+ y un controlador Vulkan 1.3 con las funciones necesarias. El Android Emulator arm64 ha arrancado el juego y ejecutado el curso inicial. La documentación también indica que no se había probado la instalación y ejecución en un teléfono o tablet físico. El requisito de memoria señalado por upstream es 8 GB o más, dado que el juego usa aproximadamente 3.2 GB de heap.

Fuentes primarias:

- [README oficial](https://github.com/smm2recomp/smm2recomp): sección Status.
- [Guía oficial de build Android](https://github.com/smm2recomp/smm2recomp/blob/main/recomp/README.md): sección Building (Android).

## Cifras de POCO X6 incluidas en esta guía

`PROMPT.md`, `MODS.md` y `FAQ.md` contienen valores atribuidos a pruebas en un POCO X6 5G, por ejemplo FPS, tiempos de GPU y comparaciones entre flags. Esos valores provienen del material que acompañó este paquete. En esta preparación no se recibieron logs, grabaciones ni datos crudos para reproducirlos; por eso se conservan como **resultados reportados por la guía, sin verificación independiente**.

No describas el POCO X6 como mínimo oficialmente soportado o probado por upstream. No presentes esas mediciones como evidencia oficial, garantía, benchmark reproducible ni promesa de rendimiento. Quien reproduzca una prueba debería publicar dispositivo exacto, versión del upstream, versión del driver, escena, temperatura, ajustes y logs sin datos privados.

## Cómo usar las instrucciones de build

Los pasos heredados de esta guía pueden apuntar a una revisión anterior del proyecto. Antes de ejecutar una orden:

1. Abre la documentación upstream enlazada arriba.
2. Comprueba que el objetivo, los scripts y las rutas siguen existiendo en el checkout usado.
3. Identifica qué archivos va a leer, escribir o borrar el comando.
4. Si difiere de esta guía, detente y actualiza el procedimiento con evidencia del checkout actual.

Los comandos incluidos son material comunitario y se ofrecen como punto de partida, no como instrucciones garantizadas para todas las revisiones.
