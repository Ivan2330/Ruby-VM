## Overview

This project implements a **32-bit Virtual Machine (VM)** in Ruby. The VM serves as a simplified CPU emulator, capable of executing basic instructions for arithmetic, logical, bitwise, and memory operations. It is designed to demonstrate the principles of instruction decoding, register manipulation, and memory addressing.

---

## Features

- **Register Set Management:**
  - Supports any number of registers (defined at initialization).
  - Tracks access statistics for optimization or debugging.

- **Memory Bank:**
  - Simulates memory using an array.
  - Read and write operations with bounds validation.
  - Supports multi-byte reads and writes (default: 4 bytes).

- **Instruction Set:**
  - Arithmetic: ADD, SUB, MUL, DIV.
  - Logical: AND, OR, XOR, NOT.
  - Bitwise: SHL, SHR.
  - Comparison: CMP_EQ, CMP_NEQ, CMP_GT, CMP_LT.
  - Memory: LOAD, STORE, INDIRECT LOAD/STORE.
  - Control Flow: JUMP (absolute and relative).
  - Trap Operations for I/O: GETC, OUT.
  - HALT for program termination.

- **Execution Flow:**
  - Fetch, decode, and execute instructions.
  - Dynamic flag management for positive, zero, and negative results.

- **User Feedback:**
  - Prints register and memory states after execution.

---

## Instruction Format

Each instruction is a 32-bit value with the following structure:
```
[ OPCODE (5 bits) | R1 (5 bits) | R2 (5 bits) | Immediate (16 bits) ]
```

- **OPCODE:** Defines the operation to perform (e.g., ADD, SUB, etc.).
- **R1, R2:** Registers involved in the operation.
- **Immediate:** Additional data or address offset.

---

## Quick Start

### Prerequisites
- Ruby installed (version >= 2.7).

### Running the Program
1. Clone the repository:
   ```bash
   git clone https://github.com/Ivan2330/32-bit-virtual-machine.git
   cd 32-bit-virtual-machine
   ```
2. Run the virtual machine with the example program:
   ```bash
   ruby Ruby_VM.rb
   ```

---

## Example Program

This example program demonstrates basic arithmetic and logical operations:
```ruby
program = [
  (0x0F << 27) | (1 << 22) | 0x05, # LOAD R1, #5
  (0x0F << 27) | (2 << 22) | 0x03, # LOAD R2, #3
  (0x01 << 27) | (0 << 22) | (1 << 17) | 0x04, # ADD R0, R1, #4
  (0x02 << 27) | (3 << 22) | (1 << 17) | 0x02, # SUB R3, R1, #2
  (0x03 << 27) | (4 << 22) | (1 << 17) | 0x02, # MUL R4, R1, #2
  (0x04 << 27) | (5 << 22) | (2 << 17) | 0x03, # DIV R5, R2, #3
  (0x1F << 27)                                # HALT
]
```

### Output Example
```
Execution finished.
Registers state:
R0: 9
R1: 5
R2: 3
R3: 3
R4: 10
R5: 1
Memory content (first 64 bytes):
Address 0x0000: 0x1E
Address 0x0001: 0x00
...
```

---

## Customization

- **Memory Size:** Adjustable in the `VMCore` initialization.
- **Register Count:** Specify the number of registers at VM initialization.
- **Instruction Set:** Extend the `decode_and_execute` method to add new instructions.

---

## Future Improvements

- Add support for floating-point arithmetic.
- Implement stack-based operations (PUSH/POP).
- Develop a higher-level assembler for easier program creation.

---

## License

This project is licensed under the MIT License. See `LICENSE` for details.


---
