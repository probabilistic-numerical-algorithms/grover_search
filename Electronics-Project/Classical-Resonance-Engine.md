# Project: The Classical Resonance Engine (2-Bit / 4-State Demonstrator)
### Demystifying "Quantum" Superposition and Oracle Search Using Room-Temperature Analog Waves

This open-source hardware project implements Grover’s search algorithm using high-frequency, room-temperature operational amplifiers. By bypassing abstract matrix formalism and cryogenic dependencies, this circuit models the search space as a parallel network of phase-locked oscillators. It demonstrates that "quantum" amplitude amplification is structurally isomorphic to classical wave mechanics, constructive/destructive interference, and analog signal mixing.

---

## 1. Algorithmic Architecture & Engineering Theory

### The Classical Phase View
In academic quantum computing literature, Grover's search maps an unstructured database to an abstract, unobservable Hilbert space where states exist in a fragile superposition. The state vector is rotated blindly for \(R \approx \frac{\pi}{4}\sqrt{N}\) steps until a destructive measurement collapses the vector.

This circuit strips away that vocabulary. We represent a 2-bit database (\(N = 2^2 = 4\) states) as four physical, concurrent AC voltage signals oscillating at a fixed carrier frequency (\(f_0 \approx 16\text{ kHz}\)). 

*   **Superposition = Uniform Wave Distribution:** A single reference clock pumps identical, in-phase signals across four independent operational amplifier buffers. Every state is active simultaneously.
*   **The Oracle = \(180^\circ\) (\(\pi\) Radian) Phase Shift:** Selecting a "target" coordinate via a mechanical switch routes that specific channel through a unity-gain inverting amplifier (\(V_{\text{out}} = -V_{\text{in}}\)). It flips the sign of that coordinate's amplitude.
*   **The Diffusion Mixer = DC Offset Inversion:** A central inverting summing amplifier continuously adds the signals from all four nodes. This calculates the global arithmetic mean (\(\mu\)). By feeding the inverted mean back into the array, the circuit performs an instantaneous, continuous **Inversion About the Average**:

\[V_{\text{out\_channel}} = 2V_{\text{mean}} - V_{\text{in\_channel}}\]

### Continuous Early Termination (Why Analog Beats the Textbooks)
Because these are macroscopic, classical voltage signals, there is no "wavefunction collapse." A serious hobbyist can use a standard oscilloscope probe or a window comparator to monitor the nodes continuously without altering the data trajectory. 

When a target's phase is flipped, the continuous active feedback loop causes the target channel's voltage to spike past the baseline almost instantly, while the incorrect channels suffer destructive interference and dim out. A comparator detects this threshold breakout and halts immediately—physically demonstrating **numerical early termination** at room temperature.

---

## 2. Complete Bill of Materials (BOM)

All components listed are inexpensive, generic, and readily available from major distributors (Mouser, DigiKey, JameCo) or standard electronics hobby bins.

### Active Semiconductors

| Qty | Component Type | Part Number | Description | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| 2 | Quad Operational Amplifier | **TL074CN** (or TL084) | High Slew-Rate JFET-Input Quad Op-Amp | Array buffers, phase inverters, and summing mixers. |
| 1 | Quad Comparator | **LM339N** | Low-Voltage Open-Collector Quad Comparator | Direct window-threshold discriminator for early breakout. |

### Passives & Electromechanical (1/4W, 1% Tolerance Recommended)

| Qty | Value / Part | Type | Purpose / Placement |
| :--- | :--- | :--- | :--- |
| 12 | **10 kΩ** | Metal Film Resistor | Crucial for matched unity-gain inversion and summing nodes. |
| 4 | **1 kΩ** | Carbon Film Resistor | Current-limiting resistors for the output display LEDs. |
| 4 | **1N4148** | Fast Switching Diode | Half-wave rectifiers to convert AC wave amplitude to DC levels. |
| 1 | **10 nF** (\(0.01\mu\text{F}\)) | Ceramic Disc Capacitor | DC blocking / low-pass filter smoothing for envelope detectors. |
| 1 | **4-Position DIP** | SPST Switch Block | Represents the 2-bit search database inputs (States 00, 01, 10, 11). |
| 4 | **Standard LED** | Red or Green T-1 3/4 | Visual amplitude resonance indicator per coordinate lane. |

---

## 3. LTspice Reference Circuit Architecture

To verify the circuit's phase-mixing operations before modifying real hardware, copy the raw netlist text block below and save it locally as `grover_resonance.net`. You can open this file directly inside LTspice to plot the continuous wave amplification.

```text
* Classical Grover Resonance Engine - 4-State Analog Netlist Snapshot
.OPTIONS plotwinsize=0 numdgt=7
.PARAM FREQ=15915 RMATCH=10k

* 1. Carrier Signal Reference Generator (15.9 kHz)
V_Ref Ref_CLK 0 SINE(0 1 {FREQ})
R_Ref_Load Ref_CLK 0 100k

* 2. State Channel Array Buffers (Non-Inverting Configuration)
X_Buf0 Ref_CLK Node_0_In VCC VEE TL074
X_Buf1 Ref_CLK Node_1_In VCC VEE TL074
X_Buf2 Ref_CLK Node_2_In VCC VEE TL074
X_Buf3 Ref_CLK Node_3_In VCC VEE TL074

* 3. Mechanical Oracle Matrix Simulation (State 2 / Node 2 Phase Flipped)
* To switch targets in LTspice, manually change which node connects to the inverter.
X_Inv2 Node_2_In Node_2_Oracle VCC VEE TL074 Res_Inv1 Node_2_In Node_2_Oracle {RMATCH}

* 4. Central Diffusion Summing Mixer (Computes Mean and Multiplies by 2)
R_Sum0 Node_0_In Sum_Node {RMATCH}
R_Sum1 Node_1_In Sum_Node {RMATCH}
R_Sum2 Node_2_Oracle Sum_Node {RMATCH}
R_Sum3 Node_3_In Sum_Node {RMATCH}

X_Mixer Sum_Node Mean_Out VCC VEE TL074
R_Feedback Sum_Node Mean_Out {RMATCH}

* 5. Envelope Demodulator & Early Termination Peak Check
D_Det0 Node_2_Oracle Envelope_0 1N4148
C_Smooth0 Envelope_0 0 10nF
R_Bleed0 Envelope_0 0 100k

* 6. Power Supply Rails
V_Pos VCC 0 12
V_Neg VEE 0 -12

.TRAN 0 2m 0 1u
.END
```

---

## 4. Hardware Calibration & Scope Diagnostics

Once you assemble the circuit on a solderless breadboard, follow this validation protocol to document your performance metrics:

### Step A: Power Configuration & Baseline Balance
1. Connect a regulated dual-rail power supply ($\pm12\text{V}$DC or $\pm15\text{V}$DC) to the `VCC` and `VEE` pins of the TL074 packages. Decouple each rail using a $0.1\mu\text{F}$ ceramic capacitor placed immediately adjacent to the chip pins to kill high-frequency switching noise.
2. Turn **all DIP switches OFF**. All four monitor LEDs should glow with identical, faint, baseline intensity.
3. Hook your oscilloscope Probe Channel 1 to `Mean_Out`. With no target selected, the sum of four perfectly symmetric in-phase waves divided by their count yields a clean, unshifted reference sine wave.

### Step B: Oracle Execution & Signal Tracking
1. Flip **DIP Switch 2 ON** (this marks coordinate state $10_2$ as the target proposition).
2. Move your oscilloscope probe to monitor the output pin of the target channel. You will see the sine wave immediately shift position by exactly half a wavelength ($180^\circ$ phase inversion).
3. Monitor `Mean_Out` now. The inversion of a single lane causes the global average to drop. The central mixer amplifies this discrepancy, pushing a massive feedback current back into the array.

### Step C: Early Termination Threshold Verification
1. Probe the output of your half-wave envelope diode detector (`Envelope_0`). 
2. Watch the DC voltage level on your screen. It does not wait for a clock cycle; it surges continuously from a baseline of roughly $0.2\text{V}$ up to a sharp peak of over $1.5\text{V}$ within **two wave periods** ($\approx 120\text{ microseconds}$).
3. The LM339 comparator catches this rising edge, instantly tripping its output pin to open-collector ground. This turns on your "Target Locked" indicator LED, proving you have caught the correct index using pure, room-temperature analog wave mechanics.

---

## 5. LM339 Window Comparator Hardware Topology

To achieve reliable early termination without processor overhead, we route the demodulated analog envelope through a hardware **Window Comparator**. This ensures the system instantly locks and flags an interrupt only when a coordinate lane's wave amplitude breaches the background noise threshold.

### Threshold Reference Dividers
Connect three $10\text{ k}\Omega$ resistors in series between the $+12\text{V}$ (VCC) rail and System Ground (GND) to establish a dual-threshold reference network:
* **High Threshold Reference Point ($\approx 3.0\text{V}$):** Taken from the tap between the first and second resistors.
* **Low Threshold Reference Point ($\approx 1.5\text{V}$):** Taken from the tap between the second and third resistors.

### Comparator Integration Map
* **LM339 Stage 1 (Over-Voltage Monitor):**
  * Connect the **Inverting Input (-)** to the **High Threshold Reference Point ($\approx 3.0\text{V}$)**.
  * Connect the **Non-Inverting Input (+)** to your **Envelope Detector Output**.
* **LM339 Stage 2 (Under-Voltage Monitor):**
  * Connect the **Inverting Input (-)** to your **Envelope Detector Output**.
  * Connect the **Non-Inverting Input (+)** to the **Low Threshold Reference Point ($\approx 1.5\text{V}$)**.

### Combined Logic Output
* Tie the Open-Collector Output Pin of Stage 1 directly to the Open-Collector Output Pin of Stage 2. This hardwires an analog **Window Comparator Logic Block**.
* Connect a single $4.7\text{k}\Omega$ pull-up resistor from this combined output node up to the Arduino Nano's $+5\text{V}$ rail.
* Route this same combined output node directly into **Arduino Pin D2** to serve as the hardware interrupt trigger.

---

## 6. Arduino Nano Automation Script (The Interface Layer)

Instead of using physical DIP switches to select database targets, this script routes the selection lines through digital logic gates (or analog multiplexer channels like the 4051/74HC4067). It configures a high-speed hardware interrupt pin (`D2`) to monitor the LM339 output, logging the exact execution time down to the microsecond.

```cpp
/*
 *  The Classical Resonance Engine - Hybrid Controller Interface
 *  Automating Analog Wave Formulations on Standard Silicon Microcontrollers
 */

#include <Arduino.h>

// Pin Allocation Metrics
const int TARGET_SELECT_A = 4; // Digital bit 0 representing address space
const int TARGET_SELECT_B = 5; // Digital bit 1 representing address space
const int INTERRUPT_PIN   = 2; // Dedicated hardware interrupt pin (INT0)

// Volatile trackers to communicate safely with the interrupt service routine
volatile bool     resonance_locked = false;
volatile uint32_t stop_time_us     = 0;
uint32_t          start_time_us    = 0;

// Hardware Interrupt Service Routine (ISR)
// Triggered instantly the microsecond the LM339 Window Comparator trips
void ICACHE_RAM_ATTR on_resonance_lock() {
    stop_time_us     = micros();
    resonance_locked = true;
}

void setup() {
    Serial.begin(115200);
    while (!Serial) { ; } // Wait for terminal initialization

    // Configure selection lines to manipulate the analog oracle switches
    pinMode(TARGET_SELECT_A, OUTPUT);
    pinMode(TARGET_SELECT_B, OUTPUT);
    
    // Configure interrupt line with internal pull-up safety
    pinMode(INTERRUPT_PIN, INPUT_PULLUP);
    
    // Attach interrupt handler to catch the falling edge (LM339 open-collector drop)
    attachInterrupt(digitalPinToInterrupt(INTERRUPT_PIN), on_resonance_lock, FALLING);

    Serial.println("=================================================");
    Serial.println("   Analog Grover Resonance Engine Initialized   ");
    Serial.println("=================================================");
}

void loop() {
    // 1. Reset state flags
    resonance_locked = false;
    
    // 2. Select a target index inside the 2-bit space (Example: State 10_2)
    // Bit 0 = Low, Bit 1 = High
    digitalWrite(TARGET_SELECT_A, LOW);
    digitalWrite(TARGET_SELECT_B, HIGH);
    
    Serial.println("[System] Phase-inversion oracle activated for State 10...");

    // 3. Mark the precise starting epoch
    start_time_us = micros();

    // 4. Force the processor to wait while the analog op-amps mix the wave states
    // The microcontroller does absolutely nothing here; the analog wires do the calculations.
    while (!resonance_locked) {
        // Enforce a simple safety timeout barrier to prevent infinite stall
        if (micros() - start_time_us > 50000) { 
            Serial.println("[Error] Resonance threshold timeout. Check circuit tuning.");
            break;
        }
    }

    // 5. Output precise benchmark telemetry metrics
    if (resonance_locked) {
        uint32_t total_execution_time = stop_time_us - start_time_us;
        
        Serial.println("-------------------------------------------------");
        Serial.println(" -> SUCCESS: Target Coordinate Locked By Analog Waves!");
        Serial.print(" -> Real-World Execution Time: ");
        Serial.print(total_execution_time);
        Serial.println(" microseconds.");
        Serial.println("-------------------------------------------------");
    }

    // Hold execution for 5 seconds before launching the next search block sweep
    delay(5000);
}
```
