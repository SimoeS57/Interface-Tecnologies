# Interactive Art Installation: Forest of Pulsations

This project consists of an interactive and collaborative art installation developed for the Interface Technologies course within the Master's in Design and Multimedia at the Faculty of Sciences and Technology of the University of Coimbra. The system captures the heartbeats of users through biometric sensors, transforming these data into an organic cluster of lights visualized through strands of fiber optics placed over an LED matrix.

The installation also features a potentiometer that simulates ambient room temperature, allowing the color palette to shift between cool and warm tones.



## Main Features

**Standby Mode:** While there are no users interacting, the system generates a continuous cloud of fluid light based on computational noise, parameterized by the color selected on the potentiometer.

**Dynamic Individual Interaction:** When a sensor detects a touch, the standby animation is interrupted on the corresponding side, generating a wave of light whose speed and expansion react to the user's pulse.

**Collective Synchronization:** If multiple sensors are activated simultaneously, the algorithm calculates the spread of the waves towards the center of the grid. When they collide, the individual pulsations fuse, beating in a unified rhythm like a single heart.

**Biological Memory and Rest:** Upon removing a finger, the light fades out gradually (instead of turning off abruptly). If the installation is abandoned, the system enters an 8-second wait period in total darkness before slowly reactivating the standby mist.



## Hardware Requirements

The circuit relies on centralized communication between the following components:
* 1x **Arduino UNO** (central processing unit)
* 4x **MAX30102 / MAX30105 Heart Rate Sensors**
* 1x **TCA9548A I2C Multiplexer** (to manage sensor addresses)
* 1x **WS2812B (8x8) LED Matrix** (64 RGB LEDs)
* 1x **Potentiometer** (connected to analog pin A0)
* 1x **External Power Source (5V)** (with its ground shared with the Arduino)



## Software Requirements

Before running the application, make sure you have installed the following libraries in the **Arduino IDE**:
* `Wire.h` (native to Arduino)
* `Adafruit_NeoPixel` (for controlling the LED matrix)
* `SparkFun MAX3010x Pulse and Proximity Sensor Library` (for reading the biometric sensors)

In **Processing (version 4.x)**, the native library is used:
* `processing.serial.*`



## How to Run the Project

1. **Physical Assembly:** Set up the electrical connections according to the circuit diagram. Ensure that the LED matrix is powered by the external 5V power supply.
2. **Upload the code to the Arduino:**
   * Open the Arduino file in the Arduino IDE.
   * Connect the board to your computer, select the corresponding COM port, and click **Upload**.
3. **Run the simulation in Processing:**
   * Open the Processing file in the Processing IDE.
   * Confirm that the line `port = new Serial(this, "COM3", 115200);` is configured with the same COM port currently used by your Arduino.
   * Click **Run (Play)** to start the visual engine and the interaction.



## Authors
* Ana Beatriz André da Silva Rocha
* António Martinho Simões
* Salomé Simões Monteiro

Master's in Design and Multimedia — Faculty of Sciences and Technology of the University of Coimbra.
