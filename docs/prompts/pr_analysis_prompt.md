# Plantilla Genérica: Análisis de Software Engineering de Pull Requests

**Ubicación**: `docs/prompts/pr_analysis_prompt.md`  
**Propósito**: Plantilla reutilizable y agnóstica para realizar análisis integrales de Software Engineering, evaluación arquitectónica y dictamen técnico de cualquier Pull Request (abierto, cerrado o en borrador), organizando los resultados en la estructura canónica `docs/analysis/<org>/<repo>/pr/<numero>/swe_analysis.md`.

---

## Prompt Reutilizable para Análisis de PR

```markdown
Por favor, realiza un análisis integral de Software Engineering y evaluación técnica sobre el Pull Request:
- Organización: <org> (ej. colcon)
- Repositorio: <repo> (ej. colcon-core)
- Número de PR / Identificador: <numero> (ej. 741 o branch-name)

Guarda el informe en la ruta canónica organizada:
`docs/analysis/<org>/<repo>/pr/<numero>/swe_analysis.md`

El informe debe cubrir estrictamente la siguiente estructura:

### 1. Resumen Ejecutivo (Nivel Manager / Leadership)
- **Problema de Negocio / Técnico**: Justificación del cambio, obsolescencia, vulnerabilidad o limitación que se aborda.
- **Solución Implementada**: Descripción de alto nivel de los cambios y arquitectura introducida.
- **Impacto y ROI**: Beneficios tangibles en rendimiento, mantenibilidad, estándares de la industria y desacoplamiento.
- **Evaluación de Riesgo y Retrocompatibilidad**: Medidas tomadas para garantizar estabilidad y evitar regresiones en workspaces existentes.

### 2. Definición de Veredicto y Criterio de Revisión
Dictamen explícito de revisión clasificado en una de las tres categorías:
- **APROBADO (Approved)**: Cumple estándares, sin riesgos de regresión, tests unitarios completos y arquitectura sólida.
- **PEDIR CAMBIOS (Changes Requested)**: La dirección técnica es correcta pero existen bloqueantes (tests fallidos, falta de cobertura, lints, inconsistencias de convención o fallos de retrocompatibilidad). Se deben listar los cambios mandatorios.
- **DESAPROBADO (Rejected)**: Enfoque fundamentalmente incompatible, duplicación innecesaria, regresión crítica o violación arquitectónica severa.
- **Justificación del Veredicto**: Argumentación técnica fundamentada del estado asignado.

### 3. Glosario de Estándares y Definiciones Clave
- Tabla con estándares de la industria (PEPs, RFCs), interfaces centrales, módulos involucrados y terminología clave utilizada en el PR.

### 4. Deep Dive de Software Engineering y Arquitectura
- **Diagrama de Flujo / Secuencia (Mermaid)**: Visualización del flujo de control y datos modificado o añadido.
- **Patrones de Diseño y Principios SOLID**: Patrones aplicados (Extension Point, Factory, Decorator, Priority Ladder, etc.).
- **Análisis de Trade-offs**: Alternativas consideradas vs implementadas (p. ej., in-process vs subproceso, estático vs dinámico).
- **Resiliencia y Casos Borde**: Manejo de errores específicos (sistemas de archivos, bloqueos en Windows/Linux, concurrencia, datos faltantes).

### 5. Pasos de Implementación y "Gotchas" (Puntos Críticos)
- Lista secuencial de tareas técnicas aplicadas (o pendientes si es WIP).
- "Gotchas" técnicos o trampas descubiertas durante la revisión del código o testing (como dependencias no declaradas, harnesses incompatibles o variables de entorno).

### 6. Plan de Testing y Verificación
- **Unit Testing**: Cobertura actual y tests unitarios requeridos.
- **Integration Testing**: Escenarios reales de validación (paquetes muestra, backends diversos, flags CLI).
- **Validación Estática**: Cumplimiento de linters (`flake8`, `pep257`), tipos y docstrings.

### 7. Conclusiones y Próximos Pasos de Acción
- Tareas concretas inmediatas para el autor del PR, revisor o integrador.
```

---

## Convención de Organización de Salida

Todos los reportes generados a partir de esta plantilla deben respetar la jerarquía de directorios:
```
docs/
└── analysis/
    └── <org>/
        └── <repo>/
            └── pr/
                └── <numero>/
                    └── swe_analysis.md
```
Ejemplos:
* `docs/analysis/colcon/colcon-core/pr/741/swe_analysis.md`
* `docs/analysis/colcon/colcon-core/pr/pep621/swe_analysis.md`
* `docs/analysis/colcon/colcon-clean/pr/15/swe_analysis.md`
