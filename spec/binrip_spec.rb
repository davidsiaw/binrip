# frozen_string_literal: true

# Main module
module Binrip
  class Device
    def index(something)
    end
  end

  class SetInstruction
    def initialize(machine, params)
      @machine = machine
      @params = params
    end

    def run!
      @machine.registers[dst_register_name] = src_value
    end

    def src_value
      return @params[1] if @params[1].is_a? Integer

      @machine.registers[src_register_name]
    end

    def src_register_name
      name_of @params[1]
    end

    def dst_register_name
      name_of @params[0]
    end

    def name_of(thing)
      thing.to_s.sub(/^reg_/, '').to_sym
    end
  end

  # interpreter
  class Interpreter
    attr_reader :error, :memory, :device, :rom, :registers

    # a, b, c, d, e, f, g, h -> general purpose registers
    # pc -> register with address of next operation
    # mr -> register with address of memory being used
    # err -> error register
    # mem -> setting this register outputs to memory
    #        reading this register inputs from memory
    # dev -> setting this register outputs to device
    #        reading this register inputs from device
    REGISTER_NAMES = %i[a b c d e f g h pc mr err mem dev].freeze

    def initialize(rom, device)
      @rom = rom
      @memory = {}
      @stack = []
      @halted = false
      @device = device
      @registers = REGISTER_NAMES.map { |x| [x, 0] }.to_h
    end

    def step!
      return if halted? # no need to run if halted

      execute!

    rescue => e
      @error = e
      set_register(:err, 1)

    ensure
      increment(:pc)
      @halted = true if register_value(:pc) >= @rom.length
    end

    def execute!
      instruction = @rom[register_value(:pc)]
      params = instruction.values[0]

      case instruction.keys[0]
      when 'set'
        SetInstruction.new(self, params).run!
      end
    end

    def register_value(register)
      @registers[register]
    end

    def set_register(register, value)
      @registers[register] = value
    end

    def increment(register)
      @registers[register] += 1
    end

    def halted?
      @halted
    end
  end

  # linker
  class Linker
    def initialize(asm)
      @asm = asm
      p @asm
    end

    def positions
      pos = {}
      count = 0
      @asm.each do |fname, fdef|
        pos[fname] = count
        count += fdef.length + 1
      end
      pos
    end

    def output
      result = []
      @asm.each do |fname, fdef|
        fdef.each do |instr|
          params = instr.values[0]
          if instr.keys[0] == 'call'
            result << { 'call' => [ positions[params[0]] ] }
          else
            result << instr
          end
        end
        result << { 'return' => [] }
      end
      result
    end
  end

  # compiler
  class Compiler
    def initialize(desc)
      @desc = desc
    end

    def functions
      result = {}
      @desc['formats'].each do |name, info|
        result["alloc_#{name}"] = [
          { 'alloc' => [name, 'reg_a'] }
        ]

        init_instrs = []
        read_instrs = []
        write_instrs = []

        info['fields'].each do |field_info|
          read_func = "read_#{name}_#{field_info['name']}"
          write_func = "write_#{name}_#{field_info['name']}"

          result[read_func] = [            
            { 'index' => ['reg_a', 'simple.number', 1] },
            { 'read_bytes' => [1, 'reg_dev'] }
          ]

          result[write_func] = [            
            { 'index' => ['reg_a', 'simple.number', 1] },
            { 'write_bytes' => [1, 'reg_dev'] }
          ]

          init_instrs += [
            { 'index' => ['reg_a', 'simple.number', 1] },
            { 'set' => ['reg_dev', 0] }
          ]

          read_instrs << { 'call' => [read_func] }
          write_instrs << { 'call' => [write_func] }
        end

        result["init_#{name}"] = init_instrs
        result["read_#{name}"] = read_instrs
        result["write_#{name}"] = write_instrs
      end
      result
    end

    def output
      {
        'functions' => functions
      }
    end
  end
end

RSpec.describe Binrip do
  it 'has a version number' do
    expect(Binrip::VERSION).not_to be nil
  end
end

RSpec.describe Binrip::Compiler do
  it 'compiles a description to read and write' do

    yaml = <<~YAML
      formats:
        simple:
          fields:
          - name: count
            type: int8
    YAML
    compiler = Binrip::Compiler.new(YAML.load(yaml))
    expect(compiler.output).to eq YAML.load(<<~YAML)
      functions:
        alloc_simple:
        - alloc: [simple, reg_a]

        init_simple:
        - index: [reg_a, simple.number, 1]
        - set: [reg_dev, 0]

        read_simple:
        - call: [read_simple_count]

        read_simple_count:
        - index: [reg_a, simple.number, 1]
        - read_bytes: [1, reg_dev]

        write_simple:
        - call: [write_simple_count]
        
        write_simple_count:
        - index: [reg_a, simple.number, 1]
        - write_bytes: [1, reg_dev]
    YAML
  end
end

RSpec.describe Binrip::Linker do
  it 'assembles compiler output to a string of instructions' do
    compiler_output = YAML.load(<<~YAML)
      ---
      main:
        - set: [reg_a, 2]
        - call: [a_function]
        - inc: [reg_a, 3]

      a_function:
        - inc: [reg_a, 1]
    YAML

    linker = Binrip::Linker.new(compiler_output)

    expect(linker.output).to eq YAML.load(<<~YAML)
      - set: [reg_a, 2]  # 0 main
      - call: [4]        # 1 call a_function
      - inc: [reg_a, 3]  # 2
      - return: []       # 3
      - inc: [reg_a, 1]  # 4 a_function
      - return: []       # 5 ret
    YAML
  end
end

RSpec.describe Binrip::Interpreter do
  it 'interprets a simple set of instructions' do
    instructions = YAML.load(<<~YAML)
      - set: [reg_a, 2]
      - set: [reg_b, 3]
      - set: [reg_c, 4]
    YAML

    d = Binrip::Device.new

    machine = Binrip::Interpreter.new(instructions, d)

    loop do
      machine.step!
      break if machine.halted?
    end

    expect(machine.error).to be_nil
    expect(machine.register_value(:a)).to eq 2
    expect(machine.register_value(:b)).to eq 3
    expect(machine.register_value(:c)).to eq 4
  end
end
