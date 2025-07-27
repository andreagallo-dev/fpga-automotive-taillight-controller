# FPGA-Based Automotive Tail Light Controller

An implementation of a comprehensive automotive tail light controller on a Xilinx Artix-7 FPGA. The system, described in Verilog, replicates all standard vehicle signaling functions (turn signals, brakes, reverse, hazards) and introduces an enhanced emergency mode featuring a timer displayed on a 7-segment display.

![FPGA in Emergency mode(waveform_fsm_emergency.jpg)

### Key Features

*   **Finite State Machine (FSM) Control:** The system's core is a robust FSM that manages all operational states and correctly handles concurrent operations (e.g., braking while a turn signal is active) with the proper signal priority.
*   **Enhanced Emergency Mode:** A custom feature that activates hazard lights and steady brake lights while starting an MM:SS timer on the 7-segment display to track the event's duration.
*   **Signal Integrity:** Implementation of **debouncing** modules for all physical inputs (buttons and switches) to ensure reliable operation and prevent erroneous state transitions.
*   **Clock Management:** A clock divider module generates the required 1 Hz (for blinking) and 1 kHz (for display refresh) signals from the 100 MHz main system clock.
*   **Full Verification Cycle:** The design was thoroughly validated through extensive simulations with a custom testbench prior to hardware implementation.

### Technology Stack

*   **HDL Language:** `Verilog`
*   **Target Platform:** `FPGA (Xilinx Artix-7)`
*   **Development Tools:** `Xilinx Vivado`
*   **Key Concepts:** `Finite State Machine (FSM)`, `Digital Logic Design`, `Debouncing`, `Clock Division`, `7-Segment Display Driving`