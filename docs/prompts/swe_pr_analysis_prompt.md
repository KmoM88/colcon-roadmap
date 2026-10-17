# Reusable Prompt: Software Engineering Analysis of Pull Requests & Features

**Location**: `docs/prompts/swe_pr_analysis_prompt.md`  
**Purpose**: Use this prompt template to request a comprehensive, structured Software Engineering & Manager-level analysis for any Pull Request, branch, or feature implementation.

---

## Prompt Template

```markdown
Por favor, realiza un análisis integral de Software Engineering y evaluación técnica sobre [PR / Branch / Feature], cubriendo los siguientes niveles y guardando el resultado en un archivo Markdown bajo `docs/analysis/`:

### 1. Resumen Ejecutivo (Nivel Manager / Leadership)
- **Problema de Negocio / Técnico**: ¿Qué dolor, obsolescencia, vulnerabilidad o limitación resuelve?
- **Solución Propuesta**: Descripción de alto nivel de lo que se implementa.
- **Impacto y ROI**: Beneficios directos en performance, mantenimiento o compatibilidad futura.
- **Evaluación de Riesgo y Retrocompatibilidad**: ¿Qué precauciones se tomaron para garantizar cero regresiones en los flujos existentes?

### 2. Definiciones y Glosario Técnico
- Lista tabular de todos los estándares (PEPs, RFCs), interfaces clave, patrones y terminología específica que fundamentan la solución.

### 3. Deep Dive de Software Engineering y Arquitectura
- **Diagrama de Flujo / Secuencia (Mermaid)**: Visualización clara del flujo de ejecución de datos o control.
- **Patrones de Diseño Aplicados**: (p. ej. Extension Point, Priority Ladder, Factory, Observer, Decorator).
- **Análisis de Trade-offs**: ¿Qué alternativas se descartaron (p. ej., in-process vs subprocess, static vs dynamic) y por qué?
- **Resiliencia y Casos Borde**: Manejo de errores específicos (sistemas de archivos, bloqueos en Windows/Linux, concurrencia, datos faltantes).

### 4. Pasos de Implementación y "Gotchas" (Puntos Críticos)
- Lista secuencial de tareas técnicas necesarias para llevar el feature a producción/upstream.
- "Gotchas" o trampas conocidas descubiertas durante la revisión del código o testing (como incompatibilidades en harnesses de test, dependencias ocultas o variables de entorno).

### 5. Plan de Testing y Verificación
- **Unit Testing**: Tests unitarios requeridos o existentes con cobertura esperada.
- **Integration Testing**: Casos de prueba con escenarios reales (fixtures, paquetes muestra, CLI flags).
- **Validación Estática**: Linters, formato de docstrings y tipado.

### 6. Consideraciones Abiertas y Próximos Pasos
- Brechas técnicas no resueltas o dependencias externas que requieren seguimiento.
- Próxima acción inmediata recomendada.
```

---

## How to Use
1. Copy the block above into your prompt or command.
2. Replace `[PR / Branch / Feature]` with the target PR number, branch name, or feature description.
3. Specify the destination filename under `docs/analysis/swe_analysis_<target>.md`.
