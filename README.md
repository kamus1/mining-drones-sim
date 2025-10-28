# Mining Drones Simulation

![Mining drones simulation](https://raw.githubusercontent.com/kamus1/mining-drones-sim/main/docs/dron-square.gif)

## Descripción

Este proyecto es una simulación de drones mineros desarrollada en Godot Engine. Los drones exploradores recorren un mapa generado aleatoriamente en busca de minerales (oro, plata y cobre), mientras que los drones recolectores transportan los recursos encontrados a los centros de control dependiendo del tipo de mineral. La comunicación entre los drones y el centro de control se realiza mediante RabbitMQ.

## Características

- **Drones Exploradores**: Se mueven por el mapa, exploran celdas desconocidas y reportan minerales encontrados.
- **Drones Recolectores**: Recogen minerales y los transportan al centro de control.
- **Mapa Procedural**: Generación aleatoria de mapas con obstáculos y depósitos de minerales.
- **Comunicación Asíncrona**: Uso de RabbitMQ para el envío de mensajes entre componentes.
- **Interfaz Visual**: Representación gráfica de los drones, mapa y recursos.

## Tecnologías Utilizadas

- **Godot Engine**: Motor de juego para el desarrollo de la simulación.
- **GDScript**: Lenguaje de scripting utilizado.
- **RabbitMQ**: Sistema de mensajería para la comunicación.
- **Addon Rabbit-GD**: Plugin de Godot para integración con RabbitMQ.

## Instalación

1. Clonar el repositorio:
   ```
   git clone https://github.com/kamus1/mining-drones-sim.git
   ```

2. Abrir el proyecto en Godot Engine.

3. Ejecutar `docker compose up` en carpeta /backend (RabbitMQ debe estar ejecutándose en localhost:5672).

4. Ejecuta la escena principal (`Main.tscn`).


## Estructura del Proyecto

- `mining-drones-sim/`: Proyecto principal en Godot.
- `backend/`: Configuración del servidor RabbitMQ (usando Docker Compose).
- `docs/`: Documentación y recursos multimedia.
