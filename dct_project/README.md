# 8×8 Discrete Cosine Transform (DCT) Using Verilog HDL

A Verilog HDL implementation of an **8×8 Forward Two-Dimensional Discrete Cosine Transform (2D DCT)** using a separable architecture.

The design performs an 8-point 1D DCT on each row of an 8×8 input block, stores and transposes the intermediate results, and performs another 1D DCT to obtain the final 8×8 frequency-coefficient matrix.

This repository includes the RTL implementation, simulation testbenches, test vectors, GNU Octave reference scripts, and simulation instructions.

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [What Is DCT?](#2-what-is-dct)
3. [Project Objectives](#3-project-objectives)
4. [System Architecture](#4-system-architecture)
5. [How the Design Works](#5-how-the-design-works)
6. [Project Directory Structure](#6-project-directory-structure)
7. [Technologies and Dependencies](#7-technologies-and-dependencies)
8. [Installation Guide](#8-installation-guide)
9. [Clone the Repository](#9-clone-the-repository)
10. [Running the Project](#10-running-the-project)
11. [Understanding the Simulation](#11-understanding-the-simulation)
12. [Understanding the Output](#12-understanding-the-output)
13. [Verification and Test Results](#13-verification-and-test-results)
14. [Fixed-Point Implementation](#14-fixed-point-implementation)
15. [Important Design Details and Limitations](#15-important-design-details-and-limitations)
16. [Team Contributions](#16-team-contributions)
17. [Troubleshooting](#17-troubleshooting)
18. [References](#18-references)

---

# 1. Project Overview

**Project Title:** Implementation of 8×8 Discrete Cosine Transform Using Verilog HDL

**Domain:** Digital Design / Digital Signal Processing / Hardware Description Languages

**Language:** Verilog HDL

**Transform:** Forward 2D Discrete Cosine Transform (DCT-II)

**Input Size:** 8×8 matrix (64 input values)

**Output Size:** 8×8 matrix (64 DCT coefficients)

### Problem Statement

To implement an 8×8 two-dimensional Discrete Cosine Transform using Verilog HDL.

### What does this project do?

Digital images contain pixel-intensity information. The Discrete Cosine Transform converts spatial-domain pixel values into frequency-domain coefficients.

Instead of implementing a complete image-processing application, this project focuses on designing the **DCT processing hardware**.

The hardware receives numerical input values representing an 8×8 pixel block and generates the corresponding 8×8 DCT coefficient matrix.

The implementation uses a separable architecture:

- First, an 8-point 1D DCT is applied to each row.
- The intermediate matrix is stored and transposed.
- Then, an 8-point 1D DCT is applied to each column.
- The final 8×8 DCT coefficient matrix is produced.

The design is simulated and verified using Icarus Verilog, GTKWave, and GNU Octave.

---

# 2. What Is DCT?

DCT stands for **Discrete Cosine Transform**.

It is a mathematical transformation that converts spatial-domain information into frequency-domain information.

For an image:

- Spatial-domain information represents pixel intensities.
- Frequency-domain information represents the spatial patterns and variations present in those pixels.

DCT is widely used in image and video processing. One well-known application is JPEG image compression.

### DC and AC Coefficients

The DCT output contains two types of information:

**DC coefficient:**

- Represents the average intensity component of the input block, with the appropriate normalization.
- For an 8-point orthonormal 1D DCT, the DC coefficient is the sum of the eight input values divided by √8.

**AC coefficients:**

- Represent the remaining spatial-frequency components.
- Describe variations and patterns in the input data.

The output coefficients indicate the contribution of different cosine basis patterns to the original signal.

---

# 3. Project Objectives

The main objectives are:

1. Implement an 8-point one-dimensional DCT using Verilog HDL.
2. Implement an 8×8 two-dimensional DCT using a separable architecture.
3. Design a transpose buffer for intermediate data storage and rearrangement.
4. Implement a top-level controller to coordinate the complete operation.
5. Develop testbenches to verify individual modules and the integrated design.
6. Compare simulated hardware results with an independent mathematical reference.
7. Verify the numerical accuracy of the fixed-point implementation.

---

# 4. System Architecture

The project consists of three main RTL modules.

```text
                8 × 8 INPUT MATRIX
                         |
                         |
                         v
              +--------------------+
              |                    |
              |   ROW-WISE 1D DCT  |
              |                    |
              +--------------------+
                         |
                         |
                         v
              +--------------------+
              |                    |
              |  TRANSPOSE BUFFER  |
              |                    |
              +--------------------+
                         |
                         |
                         v
              +--------------------+
              |                    |
              | COLUMN-WISE 1D DCT |
              |                    |
              +--------------------+
                         |
                         |
                         v
                8 × 8 OUTPUT MATRIX
                 DCT COEFFICIENTS
```

## 4.1 One-Dimensional DCT — `dct_1d_8pt.v`

This module implements an 8-point one-dimensional DCT.

**Input:** Eight signed input samples.

**Output:** Eight signed DCT coefficients.

The module performs:

- Cosine coefficient multiplication.
- Accumulation of multiplication results.
- Fixed-point rounding.
- Output-width saturation.

The implementation uses precomputed cosine coefficients represented in Q14 fixed-point format.

## 4.2 Transpose Buffer — `transpose_buffer.v`

The transpose buffer stores the intermediate results generated by the first DCT stage.

It contains storage for 64 values, corresponding to an 8×8 matrix.

Its responsibilities include:

- Storing the intermediate matrix.
- Writing the row-wise DCT results.
- Reading the stored values in transposed order.
- Providing the data required for the second DCT stage.

Mathematically, transposition converts rows into columns and columns into rows.

This allows the same 1D DCT module to be reused for the second dimension.

## 4.3 Top-Level Module — `dct2d_top.v`

This module integrates the complete 2D DCT architecture.

It coordinates:

- Input loading.
- Row-wise DCT processing.
- Intermediate matrix storage.
- Transpose-buffer access.
- Column-wise DCT processing.
- Output generation.

It also manages the control signals, including:

- Clock (`clk`)
- Reset (`rst`)
- Input valid (`in_valid`)
- Input ready (`in_ready`)
- Output valid (`out_valid`)
- Output index (`out_idx`)
- Output last (`out_last`)

The design uses a finite state machine (FSM) to coordinate the processing stages.

---

# 5. How the Design Works

The complete processing operation consists of the following stages.

### Stage 1: Input Loading

The design receives an 8×8 matrix of numerical input samples.

The testbench supplies the input values to the hardware.

Each input row contains eight values.

### Stage 2: Row-Wise DCT

The 1D DCT module processes each row independently.

Eight rows are processed to generate an intermediate 8×8 matrix.

### Stage 3: Intermediate Storage and Transposition

The transpose buffer stores the intermediate matrix.

The stored values are accessed in transposed order so that the original column data can be processed using the same 1D DCT module.

### Stage 4: Column-Wise DCT

The 1D DCT module is applied again to the transposed data.

This produces the second dimension of the transformation.

### Stage 5: Output Generation

The final 8×8 matrix contains the two-dimensional DCT coefficients.

The top-level module outputs the results using its output interface.

The output interface includes an output index and a final-output indicator (`out_last`).

---

# 6. Project Directory Structure

The repository is organized into the following main directories:

```text
dct_project/
│
├── rtl/
│   ├── dct_1d_8pt.v
│   ├── transpose_buffer.v
│   └── dct2d_top.v
│
├── tb/
│   ├── tb_dct_1d_8pt.v
│   ├── tb_transpose_buffer.v
│   └── tb_dct2d_top.v
│
├── octave/
│   ├── gen_vectors.m
│   ├── compare_results.m
│   └── reference scripts
│
├── vectors/
│   ├── input test vectors
│   └── expected output vectors
│
├── sim/
│   ├── simulation output files
│   └── waveform files
│
├── run_sim.bat
├── README.md
└── .gitignore
```

*Note: Generated simulation files and exact filenames may vary depending on the scripts included in the repository.*

### Directory Description

| Directory/File | Purpose |
|---|---|
| `rtl/` | Contains the actual Verilog hardware implementation. |
| `tb/` | Contains simulation testbenches. |
| `octave/` | Contains mathematical reference and test-vector generation scripts. |
| `vectors/` | Contains input and expected-output data files. |
| `sim/` | Contains generated simulation results and waveform files. |
| `run_sim.bat` | Windows simulation automation script. |
| `README.md` | Project documentation. |

### Important distinction

The `rtl/` directory contains the hardware design.

The `tb/` directory contains code used to test the hardware. Testbenches are simulation-only and are not part of the synthesized hardware.

The current project does not contain a JPEG/PNG image reader. It receives numerical 8×8 input blocks through its simulation testbench.

---

# 7. Technologies and Dependencies

The project uses the following applications and tools.

| Tool | Purpose | Version information |
|---|---|---|
| Verilog HDL | Hardware description language | Verilog constructs used by the RTL |
| Icarus Verilog | Compilation and simulation | 12.0 — used during project verification |
| GTKWave | Waveform visualization | Compatible version; exact installed version not recorded |
| GNU Octave | Reference calculations and comparison | 11.3.0 — used during project verification |
| Visual Studio Code | Source-code editor | Any compatible recent version |
| Git | Version control | Any recent version |

**Important:** The versions above distinguish the versions actually recorded during development from general compatible-version recommendations. The Windows development environment was used for the reported simulation results. macOS and Linux setup instructions are provided below, but should be independently verified on those operating systems.

## Official Download Websites

| Application | Official website |
|---|---|
| Icarus Verilog | https://steveicarus.github.io/iverilog/ |
| Icarus Verilog source/releases | https://github.com/steveicarus/iverilog |
| GTKWave | https://gtkwave.sourceforge.net/ |
| GTKWave source | https://github.com/gtkwave/gtkwave |
| GNU Octave | https://www.octave.org/ |
| Visual Studio Code | https://code.visualstudio.com/ |
| Git | https://git-scm.com/ |

---

# 8. Installation Guide

## 8.1 Windows

The project was developed and simulated in a Windows environment.

### Step 1: Install Visual Studio Code

Download:

https://code.visualstudio.com/

Install VS Code and open the cloned project folder.

### Step 2: Install Icarus Verilog

Download the Windows installer or binaries from:

https://github.com/steveicarus/iverilog

Install Icarus Verilog and ensure that its `bin` directory is added to the system PATH.

For example, the development environment used:

```text
C:\iverilog\bin
```

Verify the installation in Command Prompt or PowerShell:

```bash
iverilog -V
```

Also verify:

```bash
vvp -V
```

The project was tested with Icarus Verilog 12.

### Step 3: Install GTKWave

Download GTKWave from:

https://gtkwave.sourceforge.net/

Install it and ensure that the application is accessible.

The development environment used:

```text
C:\iverilog\gtkwave\bin\gtkwave.exe
```

GTKWave is used to inspect simulation waveforms.

### Step 4: Install GNU Octave

Download GNU Octave from:

https://www.octave.org/download

Install Octave.

The version used during project verification was:

```text
GNU Octave 11.3.0
```

Open Octave and navigate to the project directory:

```matlab
cd('C:/path/to/dct_project')
```

The actual path should be replaced with the location where the repository was cloned.

---

## 8.2 macOS

The following instructions use Homebrew.

### Step 1: Install Homebrew

If Homebrew is not installed, follow:

https://brew.sh/

### Step 2: Install Icarus Verilog

```bash
brew install icarus-verilog
```

Verify:

```bash
iverilog -V
vvp -V
```

### Step 3: Install GTKWave

```bash
brew install --cask gtkwave
```

If the cask is unavailable for your macOS version or hardware, consult the official GTKWave download instructions.

### Step 4: Install GNU Octave

```bash
brew install octave
```

Verify:

```bash
octave --version
```

### Step 5: Install Visual Studio Code

Download:

https://code.visualstudio.com/

Alternatively:

```bash
brew install --cask visual-studio-code
```

### Step 6: Verify Git

```bash
git --version
```

macOS may prompt you to install Apple's command-line developer tools if Git is not already available.

---

## 8.3 Linux (Ubuntu/Debian)

Open a terminal.

### Step 1: Update package information

```bash
sudo apt update
```

### Step 2: Install Icarus Verilog

```bash
sudo apt install iverilog
```

Verify:

```bash
iverilog -V
vvp -V
```

### Step 3: Install GTKWave

```bash
sudo apt install gtkwave
```

Verify:

```bash
gtkwave --version
```

If the installed package does not support this version option, launch GTKWave directly.

### Step 4: Install GNU Octave

```bash
sudo apt install octave
```

Verify:

```bash
octave --version
```

### Step 5: Install Git

```bash
sudo apt install git
```

Verify:

```bash
git --version
```

### Step 6: Install Visual Studio Code

Download the appropriate Linux package from:

https://code.visualstudio.com/

Follow the official installation instructions for your Linux distribution.

**Note:** Package versions available through Homebrew or APT can differ from the versions used in the original Windows development environment. These commands install compatible tools; they do not guarantee identical version numbers.

---

# 9. Clone the Repository

Once Git is installed, open a terminal.

Clone the repository:

```bash
git clone <YOUR_GITHUB_REPOSITORY_URL>
```

Navigate into the project directory:

```bash
cd dct_project
```

Open the project in Visual Studio Code:

```bash
code .
```

Replace `<YOUR_GITHUB_REPOSITORY_URL>` with the actual GitHub repository URL.

---

# 10. Running the Project

## 10.1 Windows — Recommended Execution Method

The repository includes a Windows simulation script:

```text
run_sim.bat
```

### Steps

1. Open the cloned project folder.
2. Confirm that Icarus Verilog is installed and available in PATH.
3. Open Command Prompt or the VS Code terminal.
4. Navigate to the project root directory.
5. Execute:

```bash
run_sim.bat
```

The script automates the compilation and simulation steps defined in the batch file.

The testbenches execute the individual module tests and the integrated 2D DCT test.

Check the terminal output for PASS or FAIL messages.

## 10.2 Manual Simulation Using Icarus Verilog

Icarus Verilog provides two important commands:

**`iverilog`**

Compiles Verilog source files and generates a simulation executable.

**`vvp`**

Runs the compiled simulation.

A typical compilation command has the following form:

```bash
iverilog -g2012 -o simulation.vvp \
rtl/dct_1d_8pt.v \
rtl/transpose_buffer.v \
rtl/dct2d_top.v \
tb/tb_dct2d_top.v
```

Run the simulation:

```bash
vvp simulation.vvp
```

This is an illustrative manual command. Use the exact source-file lists and compiler flags from `run_sim.bat` when reproducing the verified project workflow. Testbench dependencies and relative file paths must also be preserved.

For individual modules, compile the corresponding RTL and testbench together.

For example:

```bash
iverilog -g2012 -o dct1d.vvp \
rtl/dct_1d_8pt.v \
tb/tb_dct_1d_8pt.v
```

Then:

```bash
vvp dct1d.vvp
```

Repeat with the transpose-buffer and top-level testbenches, using their required RTL dependencies.

## 10.3 macOS and Linux

The same Icarus Verilog commands can be used in the terminal.

First, navigate to the project root:

```bash
cd path/to/dct_project
```

Compile the design using the source files required by the relevant testbench:

```bash
iverilog -g2012 -o simulation.vvp \
rtl/dct_1d_8pt.v \
rtl/transpose_buffer.v \
rtl/dct2d_top.v \
tb/tb_dct2d_top.v
```

Execute:

```bash
vvp simulation.vvp
```

**Important:** The manual command above illustrates the compilation workflow. Before relying on it for the full test suite, check `run_sim.bat` for the exact file lists, working directory, output filenames, and any additional simulation options. The Windows batch file itself is not directly executable on macOS or Linux.

---

# 11. Understanding the Simulation

The testbenches provide the input data and verify the behaviour of the RTL modules.

There are three major testbenches.

### 11.1 `tb_dct_1d_8pt.v`

Tests the one-dimensional DCT module.

It checks whether the generated coefficients match the expected reference values within the specified tolerance.

### 11.2 `tb_transpose_buffer.v`

Tests the transpose buffer.

It checks whether values are stored and retrieved in the expected transposed order.

### 11.3 `tb_dct2d_top.v`

Tests the complete two-dimensional DCT design.

It supplies 8×8 input blocks and checks the resulting output coefficients.

It also includes basic output protocol checks, such as:

- Output index sequence.
- Correct assertion of the final-output indicator.
- Input-ready behaviour during output generation.

---

# 12. Understanding the Output

There are two different kinds of simulation output.

## 12.1 Console Output

After simulation, Icarus Verilog prints test results in the terminal.

Successful execution produces PASS messages.

The final integrated test reports:

```text
TB_DCT2D: PASS (all 8 blocks, protocol checks passed)
```

The 1D DCT test reports:

```text
TB_DCT_1D: PASS (all outputs within +/-1 of reference)
```

The transpose-buffer test reports:

```text
TB_TRANSPOSE: PASS
```

## 12.2 Numerical DCT Coefficients

The testbench captures the numerical coefficients generated by the simulated hardware.

The output data is written to simulation output text files, such as:

```text
sim/out_N.txt
```

The exact filenames should be checked in the testbench and simulation script.

For the 2D design, the output interface transmits the results in columns.

The relevant signals include:

| Signal | Description |
|---|---|
| `out_data` | Numerical DCT coefficient data |
| `out_valid` | Indicates whether output data is valid |
| `out_idx` | Identifies the output column |
| `out_last` | Indicates the final output column |

Read `out_data` when `out_valid` is asserted, and use `out_idx` to identify the output position.

## 12.3 Waveform Visualization Using GTKWave

GTKWave is used to inspect the timing and behaviour of the simulated hardware.

It displays signals such as:

- Clock.
- Reset.
- Input data.
- Input-valid and input-ready signals.
- Output data.
- Output-valid signal.
- Output index.
- FSM state, if included in the waveform dump.

The waveform allows us to understand when input data is accepted, when processing occurs, and when output coefficients become available.

GTKWave is a waveform viewer; it does not calculate the DCT.

To open a generated waveform:

```bash
gtkwave <waveform_file>
```

Replace `<waveform_file>` with the actual waveform file generated by the simulation.

---

# 13. Verification and Test Results

The design was verified using simulation and independent mathematical reference calculations.

### 13.1 Test Coverage

Eight input blocks were tested in the integrated 2D DCT testbench.

The test set includes different input patterns and an extreme-value test containing all positive maximum input samples.

The final testbench also checks selected output-protocol conditions.

### 13.2 Reported Simulation Results

| Test | Result |
|---|---|
| Transpose buffer | PASS |
| 1D DCT | PASS |
| 2D DCT | PASS |
| Output protocol checks | PASS |

The final integrated test result was:

```text
TB_DCT2D: PASS (all 8 blocks, protocol checks passed)
```

### 13.3 Numerical Reference Comparison

GNU Octave was used to calculate reference DCT results.

The simulated hardware outputs were compared against the mathematical reference.

Reported maximum absolute errors:

| Block | Maximum absolute error | Result |
|---|---:|---|
| 0 | 0.0000 | PASS |
| 1 | 0.0000 | PASS |
| 2 | 0.4341 | PASS |
| 3 | 0.4987 | PASS |
| 4 | 0.0000 | PASS |
| 5 | 0.2681 | PASS |
| 6 | 0.4674 | PASS |
| 7 | 0.0000 | PASS |

All eight tested blocks were within one least significant bit (1 LSB) of the double-precision reference.

**Maximum reported error: 0.4987 LSB.**

These are the results from the completed development and verification runs.

They demonstrate correctness for the tested input vectors. They do not constitute exhaustive verification of every possible input combination or every reset and handshake corner case.

---

# 14. Fixed-Point Implementation

The design uses fixed-point arithmetic instead of floating-point arithmetic.

This is useful in digital hardware because fixed-point arithmetic can be implemented efficiently using integer arithmetic.

The cosine coefficients are represented using Q14 scaling.

A Q14 coefficient is represented as:

```text
Actual coefficient × 2^14
```

Since:

```text
2^14 = 16384
```

the stored integer represents the actual coefficient multiplied by 16384.

During calculation, the products are accumulated, rounded, and shifted to obtain the output value.

The implementation also includes output saturation to keep results within the representable signed output range.

The main arithmetic operations are:

1. Multiplication of input samples by cosine coefficients.
2. Accumulation of multiplication results.
3. Fixed-point rounding.
4. Arithmetic shifting.
5. Output saturation.

This provides a hardware-oriented implementation of the DCT calculation.

---

# 15. Important Design Details and Limitations

Please understand the scope of this project before extending it.

### What is implemented?

- 8-point one-dimensional forward DCT.
- 8×8 two-dimensional forward DCT.
- Row-wise processing.
- Intermediate transpose buffer.
- Column-wise processing.
- Fixed-point Q14 cosine coefficients.
- Rounding and saturation.
- Simulation testbenches.
- Numerical reference comparison.

### What is not implemented?

The current project does not include:

- JPEG or PNG image-file reading.
- Automatic image-to-pixel conversion.
- A graphical image-processing interface.
- JPEG encoding or decoding.
- Inverse DCT (IDCT).
- Physical FPGA deployment.
- ASIC implementation.

The input is supplied as numerical test data representing an 8×8 pixel block.

The project focuses specifically on the DCT hardware implementation, not on a complete image-compression application.

### Verification limitations

The reported results cover the test vectors and protocol checks included in the testbenches.

They do not prove correctness for every possible input value, all reset sequences, or every possible handshake condition.

---

# 16. Team Contributions

This is a two-member academic project.

Both members should understand the complete architecture and simulation flow.

Suggested responsibility division:

### Member 1 — DCT Computation

- DCT mathematical fundamentals.
- One-dimensional DCT implementation.
- Cosine coefficients.
- Fixed-point arithmetic.
- Rounding and saturation.
- 1D DCT verification.

### Member 2 — Architecture and Integration

- Two-dimensional DCT architecture.
- Transpose buffer.
- Top-level controller.
- Clock, reset, and FSM.
- Input/output control signals.
- Integrated simulation and waveform analysis.

### Shared Responsibilities

Both members should be able to explain:

- Overall project objective.
- DCT theory and applications.
- Complete architecture.
- Testbench methodology.
- Octave reference comparison.
- Simulation results and limitations.

---

# 17. Troubleshooting

### Problem 1: `iverilog` is not recognized

**Reason:** Icarus Verilog is not installed or its executable directory is not in PATH.

**Solution:**

Check the installation and add the Icarus Verilog `bin` directory to PATH.

Restart the terminal and execute:

```bash
iverilog -V
```

### Problem 2: `vvp` is not recognized

**Reason:** The Icarus Verilog runtime is not available in PATH.

**Solution:**

Check that the Icarus Verilog installation includes `vvp` and that its directory is accessible.

### Problem 3: GTKWave does not open a waveform

**Reason:** The waveform file may not have been generated, or the filename/path may be incorrect.

**Solution:**

Check the simulation output directory and verify the waveform filename before opening it.

### Problem 4: Test vectors cannot be found

**Reason:** The simulation may be running from the wrong working directory.

**Solution:**

Run the simulation from the project root or use the working directory expected by the testbench.

Check the `$readmemh` file paths in the testbench.

### Problem 5: Octave cannot find a script

**Reason:** Octave is running from a different directory.

**Solution:**

Navigate to the project directory using:

```matlab
cd('path/to/dct_project')
```

Then execute the required script.

### Problem 6: Different package versions

**Reason:** macOS, Linux, and Windows may provide different versions of Icarus Verilog, GTKWave, and GNU Octave.

**Solution:**

Check the installed versions and use compatible releases. If a simulation behaves differently, compare the compiler command, source-file list, working directory, and test-vector files.

---

# 18. References

The following resources are useful for understanding the tools and mathematical concepts used in this project.

### Verilog HDL and Simulation

- Icarus Verilog: https://steveicarus.github.io/iverilog/
- Icarus Verilog GitHub: https://github.com/steveicarus/iverilog
- GTKWave: https://gtkwave.sourceforge.net/

### Mathematical Computing

- GNU Octave: https://www.octave.org/
- GNU Octave Documentation: https://docs.octave.org/

### Development Tools

- Visual Studio Code: https://code.visualstudio.com/
- Git: https://git-scm.com/

### DCT Background

- Discrete Cosine Transform overview: https://en.wikipedia.org/wiki/Discrete_cosine_transform

---

## Final Note

This project demonstrates the implementation and simulation of an 8×8 forward two-dimensional Discrete Cosine Transform using Verilog HDL.

The design reuses an 8-point 1D DCT module for both dimensions, with a transpose buffer connecting the two processing stages.

The implementation was tested using Icarus Verilog, inspected using GTKWave, and numerically compared against GNU Octave reference results.

**The goal of this repository is to provide a clear, reproducible implementation that can be understood, simulated, and studied by students learning digital design, Verilog HDL, and Discrete Cosine Transform fundamentals.**
