# VGA & Sensor Integration Project

Phased implementation of a VGA controller (starting from 640x480), resolution expansion, image display, and external sensor integration.

---

## Implementation Plan

### 🔹 Phase 1 — Project Documentation
* **Objective:** Establish the technical foundation and project structure.

### 🔹 Phase 2 — VGA Simulation (640×480)
* **Objective:** Validate synchronization signals in the simulator.
* **Steps:**
  1. Run the behavioral simulation in Vivado on the `vga_controller.v` testbench.
  2. Verify the timing parameters for the `640×480 60Hz` standard.
  3. Ensure that the `HSYNC`, `VSYNC` signals and *blanking* periods are correct.

### 🔹 Phase 3 — Hardware Implementation
* **Objective:** Synthesis, pin mapping, and FPGA programming.
* **Steps:**
  1. Add pin and clock constraints to the `.xdc` file.
  2. Run **Synthesis** & **Implementation**.
  3. Generate the bitstream, load it onto the board, and physically verify signals on the pins (using an oscilloscope/logic analyzer).

### 🔹 Phase 4 — Shape Drawing
* **Objective:** Generate and display simple geometric shapes directly on the screen using hardware logic.
* **Steps:**

  1. Draw static elements (e.g., a solid square, a rectangle, or a crosshair) by altering color outputs within specific coordinate ranges.
  2. Verify color integrity and alignment directly on the physical monitor.

### 🔹 Phase 5 — Image Display & Animations
* **Objective:** Display static and dynamic data using internal memory.
* **Steps:**
  1. Convert an image into raw format (e.g., **RGB565**) and generate the `.coe` file.
  2. Instantiate a memory block (**BRAM**) in Vivado pre-loaded with the `.coe` file.
  3. Connect the BRAM read logic to the VGA controller. For animations, dynamically modify the frame's start address.

### 🔹 Phase 6 — Resolution Expansion
* **Objective:** Adapt the design for higher resolutions (e.g., 800×600, 1024×768).
* **Steps:**
  1. Update timing constants in the RTL code.
  2. Generate the new pixel clock using a **PLL**.
  3. Fix any potential timing errors during implementation.

### 🔹 Phase 7 — External Sensor Integration
* **Objective:** Acquire environmental data and display it in real time on the screen.
* **Steps:**
  1. Implement the protocol driver for the sensor.
  2. Create the processing module that transforms the data into visual elements (text or graphics).
  3. Overlay the graphics onto the VGA signal and test the complete system on hardware.