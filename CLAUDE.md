# gaga-cotizador — Portal Flotilla GAGA (Henry's Diagnostics)

## Qué es esto
Portal HTML/CSS/JS vanilla + Supabase para administrar el mantenimiento de la flotilla de GAGA (138 vehículos), operado por Henry's Diagnostics. **Ubicación real de Henry's Diagnostics: Colima, Colima** (nunca Chihuahua — hubo un error de este tipo el 2026-07-07, ya corregido).

Repo: https://github.com/efigueroaesqueda-cell/gaga-cotizador
Live: https://efigueroaesqueda-cell.github.io/gaga-cotizador/

## Archivos
- `bienvenida.html` — landing, elige módulo (flotilla/proyección/cotizador)
- `flotilla.html` — tabla de unidades con KM actual/último servicio, semáforo, ficha lateral por unidad
- `proyeccion.html` — proyección de inversión en mantenimiento por período (hoy/7/15/30/60 días)
- `index.html` — cotizador (NO tiene modo demo, trae datos reales de cotizaciones — no tocar sin avisar)

## Modo demo (implementado 2026-07-06/07)
- `flotilla.html` y `proyeccion.html`: demo ON por default en cualquier liga compartida. Agregar `?real=1` para ver datos reales (uso interno).
- `bienvenida.html` propaga `?real=1` a los 3 módulos si está presente en su propia URL.
- `index.html` (cotizador) NO tiene esta lógica — es intencional, trae datos reales de cotizaciones.

## ⚠️ Gotcha crítico: git + OneDrive
Este repo vive dentro de una carpeta sincronizada por OneDrive. Si **GitHub Desktop está abierto** mientras se hacen operaciones de git desde otra herramienta (terminal, otro editor), se generan archivos `.lock` fantasma en `.git/` que bloquean cualquier commit/checkout con el error "Unable to create .git/index.lock: File exists" — incluso después de borrar el lock a mano. La única solución confiable encontrada: **cerrar GitHub Desktop por completo** antes de operar el repo desde otro lado. Ya pasó 2 veces (2026-07-06 noche, 2026-07-07 mañana) y causó corrupción de archivos (contenido cortado a la mitad) durante la pelea de locks — si eso vuelve a pasar, comparar contra el blob del último commit bueno (`git show HEAD:archivo`) antes de asumir que el bug es de código.

## Pendiente / ideas abiertas
- **Coach marks / tutorial**: Enrique pidió tooltips que resalten 2-4 botones clave la primera vez que se entra a cada módulo (ej. en flotilla: campo KM, "Ver cotización →", Modo Demo). Aprobó el alcance el 2026-07-06, no se ha construido.
- **Claridad de los totales en proyeccion.html**: las 3 tarjetas de arriba clasifican por KM restante (vencidas/urgentes/próximas/al día) y las 5 de abajo por días estimados — ambas suman 98 (de 138 unidades, 40 sin KM registrado) pero usan criterios distintos y pueden confundir visualmente al traslaparse. Posible mejora: aclarar con texto que son dos vistas distintas del mismo dato.
- Plan a futuro: este portal + HenryLeads (ver `../leads-portal/CLAUDE.md`) eventualmente se integran al sistema propio que construye Ricardo (Next.js/Prisma/Postgres/Railway) — confirmar con él su schema antes de migrar esquemas de datos.
