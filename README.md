# Kavach--tcas--core
RTL Design Functional Verification of Kavach (TCAS) Core using Verilog 

# RTL Design and Functional Verification of Kavach (TCAS) Core

## 1. Project Overview
This project presents the RTL design and functional verification of the **On-board Vehicle Computer (VC)** core for **Kavach** (Train Collision Avoidance System), India's native Automatic Train Protection (ATP) system. 

The hardware architecture is designed using synthesizable Verilog to process real-time sensor inputs (train speed, track-side RFID tags, wireless lineside signaling) and instantly execute deterministic safety overrides like multi-stage service braking or emergency braking to eliminate human errors.

## 2. Key Architecture & Features
*   **Dynamic Speed Ceilings:** Automatically configures internal `MAX_SPEED_LIMIT` registers based on the selected 3-bit train profile matrix (**Vande Bharat at 160 km/h** vs. **Goods Train at 75 km/h**).
*   **Overspeed Grace Loop:** Implemented a synchronous 10-clock cycle warning counter window before automatically engaging the Brake Interface Unit (BIU).
*   **Asynchronous Collision Interception:** Designed high-priority combinational paths to bypass regular clock tracking cycles and fire immediate emergency braking (`2'b10`) during active Signal Passing At Danger (SPAD) violations or head-on collision alerts.
*   **Automated Crossway Horn:** Triggers the physical horn line (`auto_whistle`) seamlessly upon detecting dedicated level-crossing track markers.

## 3. Hardware Component Block Diagram
```text
                   +--------------------------------------------+

                   |            KAVACH_CORE (DUT)               |
   clk ----------->|                                            |
   rst_n --------->|  +--------------------+                    |
   train_type ---->|  |  Overspeed Control |                    |
   current_speed ->|  +--------------------+                    |---> biu_brake_command [1:0]
   rfid_tag_data ->|  +--------------------+                    |---> dmi_display_alert [2:0]
   signal_aspect ->|  | Collision Avoidance|                    |---> auto_whistle
   opposing_train->|  +--------------------+                    |
   sos_trigger --->|                                            |
                   +--------------------------------------------+
```

## 4. Input / Output Signal Table

| Signal Name | Direction | Width | Description / Function |
| :--- | :--- | :--- | :--- |
| `clk` | Input | 1 bit | Master Clock Line |
| `rst_n` | Input | 1 bit | Asynchronous Active Low Reset |
| `train_type[2:0]` | Input | 3 bits | Train Profile (`000` = Vande Bharat, `100` = Goods Train) |
| `current_speed[7:0]` | Input | 8 bits | Live velocity tracker data from axle counters (km/h) |
| `rfid_tag_data[15:0]` | Input | 16 bits | 16-bit tracker code read from track-side structural RFID tags |
| `signal_aspect[1:0]` | Input | 2 bits | Wireless signal updates (`00`=RED, `01`=YELLOW, `10`=GREEN) |
| `opposing_train` | Input | 1 bit | Asynchronous flag indicating an oncoming train on the same line |
| `sos_trigger` | Input | 1 bit | Station master/Network manual emergency override switch |
| `biu_brake_command[1:0]`| Output | 2 bits | Brake Interface Unit lines (`00`=Release, `01`=Normal, `10`=Emergency) |
| `dmi_display_alert[2:0]`| Output | 3 bits | Driver Interface panel notifications (`001`=Overspeed, `010`=SPAD, `111`=Collision) |
| `auto_whistle` | Output | 1 bit | Hardware trigger pulse to blow track horn at crossing zones |

## 5. Verification Scenarios & Waveform Analysis
The design was compiled and verified using **Icarus Verilog** on **EDA Playground**. Digital trace changes were fully captured via VCD dump configurations.

### Key Verified Testcases (EPWave Simulation):
1. **Goods Train Profile Fault Test:** Validated that running a heavy Goods Train at 85 km/h (Ceiling: 75 km/h) triggers an overspeed warning sequence and drops steady service brakes after 10 clock intervals.
2. **Immediate Head-on Lockout Test:** Confirmed single-cycle deployment of emergency lockdown protocols (`biu_brake_command = 2'b10`) when the `opposing_train` sensor goes HIGH, ignoring ongoing speed grace periods.
