# RTL-to-GDSII-Viterbi-Decoder-ASIC

## Stage 3: Post-Synthesis Logical Equivalence Checking (LEC)

### Overview

This repository documents the **Post-Synthesis Logical Equivalence Checking (LEC)** stage of the ASIC implementation flow for a K=7 Convolutional Encoder and Viterbi Decoder.

The purpose of this stage is to formally verify that the synthesized gate-level netlist is functionally equivalent to the original RTL design. Logical Equivalence Checking ensures that synthesis optimizations, technology mapping, and logic transformations have not introduced any functional discrepancies between the RTL and the synthesized implementation.

By comparing the RTL (Golden Design) against the synthesized gate-level netlist (Revised Design), formal verification is performed without relying on simulation vectors, providing exhaustive proof of functional correctness.

---

## Objectives

* Verify RTL-to-Netlist equivalence.
* Validate synthesis optimizations.
* Detect unintended functional modifications.
* Ensure correctness before physical design stages.

---

## Inputs

* RTL Verilog Design
* Synthesized Gate-Level Netlist
* Standard Cell Library Models
* LEC Setup Scripts

---

## Verification Flow

1. Read Golden RTL Design.
2. Read Revised Synthesized Netlist.
3. Load Technology Libraries.
4. Match Design Hierarchy and Compare Points.
5. Perform Formal Equivalence Checking.
6. Generate Verification Reports.

---

## Results

* RTL successfully matched with synthesized netlist.
* All compare points verified.
* No functional mismatches detected.
* Formal equivalence established between RTL and gate-level netlist.

### Verification Status

| Check                    | Status |
| ------------------------ | ------ |
| RTL Read                 | ✅ Pass |
| Netlist Read             | ✅ Pass |
| Compare Point Matching   | ✅ Pass |
| Equivalence Verification | ✅ Pass |
| Final Verification       | ✅ Pass |

---

## Repository Structure

```text
├── RTL/
├── Netlist/
├── Scripts/
│   └── lec.tcl
├── Reports/
│   └── lec_report.rpt
├── Logs/
└── README.md
```

---

## Deliverables

* LEC TCL Script
* Equivalence Checking Report
* Verification Logs
* Compare Point Summary

---

## ASIC Flow Progress

```text
RTL Behavioral Simulation & Functional Verification   ✅ Completed
Logic Synthesis                                       ✅ Completed
Post-Synthesis LEC                                    ✅ Completed
Gate-Level Simulation                                 ⏳ Next Stage
Floorplanning                                         ⏳ Pending
Placement                                             ⏳ Pending
Clock Tree Synthesis (CTS)                            ⏳ Pending
Routing                                               ⏳ Pending
Static Timing Analysis (STA)                          ⏳ Pending
DRC/LVS Verification                                  ⏳ Pending
GDSII Generation                                      ⏳ Pending
```

### Status

**✅ Stage 3 Completed Successfully**

The synthesized gate-level netlist has been formally verified against the RTL design and is ready for Gate-Level Simulation and subsequent physical design stages.
