# Plantilla Genérica: Análisis de Software Engineering de Ramas (Branches)

**Ubicación**: `docs/prompts/branch_analysis_prompt.md`  
**Propósito**: Plantilla reutilizable y agnóstica para realizar análisis integrales de Software Engineering, evaluación arquitectónica y dictamen técnico de cualquier rama Git (WIP, experimental, feature o release candidate), organizando los resultados bajo la convención canónica:
`docs/analysis/<org>/<repo>/branch/<branch-name>/swe_analysis.md`.

---

## Prompt Reutilizable para Análisis de Ramas

```markdown
Por favor, realiza un análisis integral de Software Engineering y evaluación técnica sobre la rama Git:
- Organización: <org> (ej. colcon)
- Repositorio: <repo> (ej. colcon-core)
- Nombre de Rama: <branch-name> (ej. cottsay/pep621)
- Commit Base / HEAD evaluado: <commit-hash> (ej. 80acf29)

Guarda el informe en la ruta canónica organizada:
`docs/analysis/<org>/<repo>/branch/<branch-name>/swe_analysis.md`

El informe debe cubrir estrictamente la siguiente estructura:

### 1. Resumen Ejecutivo (Nivel Manager / Leadership)
- **Problema de Negocio / Técnico**: Motivación de la rama, deuda técnica, limitación o requerimiento que aborda.
- **Solución Propuesta en la Rama**: Descripción de alto nivel de los módulos introducidos o modificados.
- **Impacto y ROI**: Beneficios en desacoplamiento, performance, estándares de la industria y mantenibilidad.
- **Evaluación de Riesgo y Retrocompatibilidad**: Salvaguardas para garantizar que la rama no rompa flujos existentes al ser integrada.

### 2. Definición de Veredicto y Criterio de Madurez
Dictamen explícito sobre el estado de madurez de la rama:
- **APROBADO (Ready for PR / Ready to Merge)**: Código maduro, cumple estándares de linting, retrocompatible y con tests completos y pasando al 100%.
- **PEDIR CAMBIOS (Changes Requested / In Progress)**: La dirección arquitectónica es correcta pero existen bloqueantes para mergear (tests fallidos, falta de cobertura, regresiones de linter o gotchas técnicos). Se deben listar los cambios mandatorios.
- **DESAPROBADO (Abandoned / Rejected Approach)**: Enfoque inviable, introduce regresiones críticas o ha sido superado por una estrategia superior.
- **Justificación del Veredicto**: Argumentación fundamentada del estado técnico actual.

### 3. Glosario de Estándares y Definiciones Clave
- Tabla con especificaciones (PEPs, RFCs), interfaces centrales, clases clave y conceptos involucrados en la rama.

### 4. Deep Dive de Software Engineering y Arquitectura
- **Diagrama de Flujo / Secuencia (Mermaid)**: Visualización de los componentes modificados o agregados.
- **Patrones de Diseño y Principios SOLID**: Patrones aplicados (Extension Point, Priority Ladder, Factory, Fallback, etc.).
- **Análisis de Trade-offs**: Decisiones técnicas tomadas frente a posibles alternativas.
- **Resiliencia y Casos Borde**: Manejo de excepciones, fallos de entorno, soporte multiplataforma.

### 5. Pasos de Implementación y "Gotchas" (Puntos Críticos)
- Tareas completadas en la rama y tareas pendientes antes de abrir/completar un PR formal.
- "Gotchas" técnicos descubiertos (como dependencias no declaradas en testing, variables de entorno o incompatibilidades de runner).

### 6. Plan de Testing y Estado de Verificación
- **Unit Testing**: Tests unitarios existentes en la rama y estado de aprobación.
- **Integration Testing**: Escenarios reales requeridos para validar la rama en un entorno productivo.
- **Validación Estática**: Cobertura de linters (`flake8`, `pep257`), tipado y docstrings.

### 7. Conclusiones y Próximos Pasos de Acción
- Plan de acción concreto para llevar la rama a estado "Aprobado" y preparar la propuesta de PR.
```

---

## Convención de Organización de Salida

Todos los reportes generados a partir de esta plantilla deben respetar la jerarquía:
```
docs/
└── analysis/
    └── <org>/
        └── <repo>/
            └── branch/
                └── <branch-name>/
                    └── swe_analysis.md
```
Ejemplos:
* `docs/analysis/colcon/colcon-core/branch/cottsay/pep621/swe_analysis.md`
* `docs/analysis/colcon/colcon-cargo/branch/cottsay/colcon-cargo-merge/swe_analysis.md`
