class RegisterSet
  def initialize(size)
    @registers = Array.new(size, 0)
    @access_stats = Array.new(size, 0)
  end

  def get(index)
    track_access(index)
    @registers[index]
  end

  def set(index, value)
    track_access(index)
    @registers[index] = value
  end

  def track_access(index)
    @access_stats[index] += 1
  end

  def stats
    @access_stats
  end

  def print_registers
    puts "Registers state:"
    @registers.each_with_index do |value, index|
      puts "R#{index}: #{value}"
    end
  end
end

class MemoryBank
  def initialize(size)
    @memory = Array.new(size, 0)
  end

  def read(addr, length = 4)
    validate(addr, length)
    @memory[addr, length].reverse.reduce(0) { |acc, byte| (acc << 8) | byte }
  end

  def write(addr, value, length = 4)
    validate(addr, length)
    length.times { |i| @memory[addr + i] = (value >> (8 * i)) & 0xFF }
  end

  def validate(addr, length)
    raise "Out of bounds: address=#{addr}, size=#{length}" if addr < 0 || addr + length > @memory.size
  end

  def print_memory(range = 64)
    puts "Memory content (first #{range} bytes):"
    @memory[0, range].each_with_index do |byte, index|
      printf "Address 0x%04X: 0x%02X\n", index, byte
    end
  end
end

class VMCore
  INSTRUCTION_SIZE = 4
  FLAG_POSITIVE = 1
  FLAG_ZERO = 2
  FLAG_NEGATIVE = 4

  def initialize(memory_size, register_count)
    @memory = MemoryBank.new(memory_size)
    @registers = RegisterSet.new(register_count)
    @running = true
    @flags = 0
  end

  def load_program(program)
    program.each_with_index { |instr, i| @memory.write(i * INSTRUCTION_SIZE, instr) }
  end

  def fetch_instruction(pc)
    @memory.read(pc, INSTRUCTION_SIZE)
  end

  def set_flag(value)
    @flags =
      if value > 0
        FLAG_POSITIVE
      elsif value == 0
        FLAG_ZERO
      else
        FLAG_NEGATIVE
      end
  end

  def execute
    pc = 0
    while @running
      instr = fetch_instruction(pc)
      pc += INSTRUCTION_SIZE
      decode_and_execute(instr, pc)
    end
    puts "Execution finished."
    print_registers_and_memory
  end

  def decode_and_execute(instr, pc)
    opcode = (instr >> 27) & 0x1F
    r1 = (instr >> 22) & 0x1F
    r2 = (instr >> 17) & 0x1F
    imm = instr & 0xFFFF

    case opcode
    when 0x01 then perform_add(r1, r2, imm)
    when 0x02 then perform_subtract(r1, r2, imm)
    when 0x03 then perform_multiply(r1, r2, imm)
    when 0x04 then perform_divide(r1, r2, imm)
    when 0x05 then perform_and(r1, r2, imm)
    when 0x06 then perform_or(r1, r2, imm)
    when 0x07 then perform_xor(r1, r2, imm)
    when 0x08 then perform_not(r1, r2)
    when 0x09 then perform_shl(r1, r2, imm)
    when 0x0A then perform_shr(r1, r2, imm)
    when 0x0B then perform_cmp_eq(r1, r2)
    when 0x0C then perform_cmp_neq(r1, r2)
    when 0x0D then perform_cmp_gt(r1, r2)
    when 0x0E then perform_cmp_lt(r1, r2)
    when 0x0F then perform_load(r1, imm)
    when 0x10 then perform_store(r1, imm)
    when 0x11 then perform_load_indirect(r1, imm)
    when 0x12 then perform_store_indirect(r1, imm)
    when 0x13 then perform_effective_address(r1, imm)
    when 0x14 then perform_jump_abs(imm)
    when 0x15 then perform_jump_rel(imm)
    when 0x18 then trap_operation(imm)
    when 0x1F then halt
    else
      puts "Invalid opcode: #{opcode}"
      @running = false
    end
  end

  def perform_add(r1, r2, imm)
    result = @registers.get(r2) + imm
    @registers.set(r1, result)
    set_flag(result)
  end

  def perform_subtract(r1, r2, imm)
    result = @registers.get(r2) - imm
    @registers.set(r1, result)
    set_flag(result)
  end

  def perform_multiply(r1, r2, imm)
    result = @registers.get(r2) * imm
    @registers.set(r1, result)
    set_flag(result)
  end

  def perform_divide(r1, r2, imm)
    if imm.zero?
      puts "Division by zero!"
      @running = false
    else
      result = @registers.get(r2) / imm
      remainder = @registers.get(r2) % imm
      @registers.set(r1, result)
      @registers.set(17, remainder) # REM register
      set_flag(result)
    end
  end
  def perform_and(r1, r2, imm)
    result = @registers.get(r2) & imm
    @registers.set(r1, result)
    set_flag(result)
  end

  def perform_or(r1, r2, imm)
    result = @registers.get(r2) | imm
    @registers.set(r1, result)
    set_flag(result)
  end

  def perform_xor(r1, r2, imm)
    result = @registers.get(r2) ^ imm
    @registers.set(r1, result)
    set_flag(result)
  end

  def perform_not(r1, r2)
    result = ~@registers.get(r2)
    @registers.set(r1, result)
    set_flag(result)
  end

  def perform_shl(r1, r2, imm)
    result = @registers.get(r2) << imm
    @registers.set(r1, result)
    set_flag(result)
  end

  def perform_shr(r1, r2, imm)
    result = @registers.get(r2) >> imm
    @registers.set(r1, result)
    set_flag(result)
  end
  
  def perform_cmp_eq(r1, r2)
    @flags = (@registers.get(r1) == @registers.get(r2)) ? FLAG_ZERO : FLAG_POSITIVE
  end

  def perform_cmp_neq(r1, r2)
    @flags = (@registers.get(r1) != @registers.get(r2)) ? FLAG_ZERO : FLAG_POSITIVE
  end

  def perform_cmp_gt(r1, r2)
    @flags = (@registers.get(r1) > @registers.get(r2)) ? FLAG_POSITIVE : FLAG_NEGATIVE
  end

  def perform_cmp_lt(r1, r2)
    @flags = (@registers.get(r1) < @registers.get(r2)) ? FLAG_POSITIVE : FLAG_NEGATIVE
  end

  # Реалізація операцій пам'яті та адрес
  def perform_load_indirect(r1, imm)
    effective_address = @memory.read(@registers.get(16) + imm)
    value = @memory.read(effective_address)
    @registers.set(r1, value)
    set_flag(value)
  end

  def perform_store_indirect(r1, imm)
    effective_address = @memory.read(@registers.get(16) + imm)
    @memory.write(effective_address, @registers.get(r1))
  end

  def perform_effective_address(r1, imm)
    effective_address = @registers.get(16) + imm
    @registers.set(r1, effective_address)
    set_flag(effective_address)
  end
  def perform_load(r1, imm)
    @registers.set(r1, imm)
  end

  def perform_store(r1, imm)
    @memory.write(imm, @registers.get(r1))
  end

  def perform_jump_abs(imm)
    @registers.set(16, imm) # PC
  end

  def perform_jump_rel(imm)
    pc = @registers.get(16)
    @registers.set(16, pc + imm)
  end

  def trap_operation(vector)
    case vector
    when 0x20
      print "Enter a character: "
      @registers.set(0, gets.chomp.ord)
    when 0x21
      print @registers.get(0).chr
    when 0x25
      halt
    else
      puts "Unknown TRAP vector: #{vector}"
    end
  end

  def halt
    @running = false
    puts "Program halted."
  end

  def print_registers_and_memory
    @registers.print_registers
    @memory.print_memory
  end
end

# Test program
program = [
  (0x0F << 27) | (1 << 22) | 0x05, # LOAD R1, #5
  (0x0F << 27) | (2 << 22) | 0x03, # LOAD R2, #3
  (0x01 << 27) | (0 << 22) | (1 << 17) | 0x04, # ADD R0, R1, #4
  (0x02 << 27) | (3 << 22) | (1 << 17) | 0x02, # SUB R3, R1, #2
  (0x03 << 27) | (4 << 22) | (1 << 17) | 0x02, # MUL R4, R1, #2
  (0x04 << 27) | (5 << 22) | (2 << 17) | 0x03, # DIV R5, R2, #3
  (0x05 << 27) | (6 << 22) | (1 << 17) | 0x03, # AND R6, R1, #3
  (0x07 << 27) | (7 << 22) | (2 << 17) | 0x01, # XOR R7, R2, #1
  (0x08 << 27) | (8 << 22) | (6 << 17),       # NOT R8, R6
  (0x1F << 27)                                # HALT
]

vm = VMCore.new(128 * 1024, 20)
vm.load_program(program)
vm.execute