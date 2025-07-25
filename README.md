# Posit Arithmetic Unit (PAU)

This repository provides a parameterized hardware implementation of a Posit Arithmetic Unit (PAU) written in Verilog. It supports addition, subtraction, multiplication, and division over configurable posit formats, and includes a full verification framework using a C++ golden reference model.

The PAU is designed with a pipelined architecture, modular datapath components, and flexible configuration via the `nbits` and `es` parameters. All testbenches are self-checking and automatically compare results against the reference output.

---

##  Key Features

-  Parameterized Verilog design: Supports `posit<nbits, es>` formats  
-  Arithmetic operations: Add, Sub, Mul, Div  
-  Modular architecture: extraction, scalar control, operator, encoder  
-  Pipeline support: 3-cycle latency for add/sub/mul, variable for div  
-  C++ golden reference (based on [libcg/bfp](https://github.com/libcg/bfp))  
-  SystemVerilog testbenches with automatic pass/fail reporting  
-  CSV-based test automation from random sample generation  

---

##  Architecture Overview

The PAU consists of the following hardware modules:

- **Posit Extraction**  
  Parses the posit input into sign, regime, exponent, and fraction components. Computes initial scaling factor and sets flags for special cases (zero, NaR).

- **Scalar Processing**  
  Computes effective scale factors based on operation type (e.g., exponent sum for multiplication, difference for division). Handles special cases and scale clamping.

- **Arithmetic Operator**  
  Performs fraction-level arithmetic with extended precision. Includes logic for rounding (round-to-nearest-even), normalization, and sticky bit handling.

- **CLZ (Leading One Detector)**  
  Returns the index of the most significant 1 in the post-operation result. Used to calculate normalization shift.

- **Encoder**  
  Reconstructs the final posit value from normalized data. Handles rounding overflow and regime encoding. Outputs NaR or zero where appropriate.

- **Control Logic**  
  Manages valid/enable/done signals to coordinate pipelined flow. Division operations are handled with handshake protocol to accommodate variable latency.

---

##  Verification Methodology

All operations are verified against a C++ golden reference. The flow is as follows:

### 1. Generate Random Posit Samples (C++)

```bash
g++ sample_extraction.cpp -o sample_gen
./sample_gen > sample.csv
```

- Outputs 500 randomized posit operand pairs and expected results  
- Format: `a, b, expected_result`

### 2. Run Verilog/SystemVerilog Testbench

```bash
# Example: addition
vsim -c -do "run -all" testbenches/posit_testbench.sv
```

- Loads `sample.csv` and applies inputs to hardware model  
- Waits for done signal (especially for division)  
- Compares hardware output to golden reference

### 3. Console Log Output

```text
Pass at cycle 8: a = 11000011, b = 00001110, result = 11110011
Mismatch at cycle 177: a = 01000000, b = 11000000, expected = 01010000, got = 00000000
```

Self-checking logic reports pass/fail per cycle, including binary-level mismatch information.

---

##  Current Status

| Operation      | Status     | Match Rate  |
|----------------|------------|-------------|
| Addition       | ✅ Verified | 100% (500/500) |
| Subtraction    | ✅ Verified | 100% (500/500) |
| Multiplication | ✅ Verified | 100% (500/500) |
| Division       | ⚠️ In Progress | ~70.8%      |

Tested on `posit<8,1>`. Other formats (e.g., `posit<8,3>`, `posit<16,1>`) have not yet been fully verified.

---

## Limitations & Future Work

- Division operation is not yet fully validated under all edge cases  
- Only `posit<8,1>` configuration has been tested end-to-end  
- No synthesis or hardware deployment (FPGA/ASIC) has been performed  
- No resource/timing/power analysis yet

### Potential Extensions

- Verify across more posit formats (`posit<8,3>`, `posit<16,1>`, etc.)
- Compare PAU with IEEE 754 FP in terms of area, power, and error bounds  
- Extend pipelining for higher throughput (e.g., 4 or 5 stages)  
- Integrate with system-level ML inference pipelines

---


## License

This project is licensed under the MIT License.  
Golden reference model is based on [libcg/bfp](https://github.com/libcg/bfp).

