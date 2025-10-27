El explorador de drones utiliza un algoritmo simple de exploración estocástica en la función `_explore_step()`:

1. **Procesamiento de la Celda Actual**:
   - Verifica el estado de la celda actual
   - Si contiene un mineral (`Cell.GOLD`, `Cell.SILVER` o `Cell.COPPER`), imprime un mensaje "MINERAL ENCONTRADO" incluyendo el tipo de mineral
   - Si no es un obstáculo, la marca como explorada (`Cell.EXPLORED`)

2. **Selección de Vecinos**:
   - Considera las celdas adyacentes en 4 direcciones (o 8 si se permiten diagonales)
   - Filtra las celdas que están fuera de límites o son obstáculos
   - Crea una lista de celdas candidatas válidas

3. **Toma de Decisiones**:
   - Ordena los candidatos por estado de celda en orden ascendente: DESCONOCIDO (0) -> EXPLORADO (1) -> casillas de mineral (2)
   - Esto prioriza áreas inexploradas mientras permite algo de aleatoriedad
   - Selecciona aleatoriamente un candidato de la lista ordenada

4. **Movimiento**:
   - Actualiza su posición a la celda seleccionada
   - Repite el proceso en cada tic del temporizador

Esto crea un comportamiento de caminata aleatoria que prefiere explorar territorio desconocido pero puede ocasionalmente revisitar áreas exploradas o acercarse a depósitos de mineral conocidos. El algoritmo es simple y eficiente para exploración básica de mapas sin búsqueda de caminos compleja.
