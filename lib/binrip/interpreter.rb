# frozen_string_literal: true

module Binrip
  # interpreter
  class Interpreter
    attr_reader :error, :memory, :device, :stack, :rom, :registers

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

    def run!
      loop do
        step!
        # p @rom[registers[:pc]]
        # puts registers
        break if halted?
      end
    end

    def step!
      return if halted? # no need to run if halted

      idx = register_value(:pc)
      increment(:pc)
      execute!(idx)
    rescue StandardError => e
      @error = e
      set_register(:err, 1)
    ensure
      @halted = true if register_value(:pc) >= @rom.length
    end

    def halt!
      @halted = true
    end

    def execute!(index)
      instruction = @rom[index]
      params = instruction.values[0]

      instr_class = "#{instruction.keys[0].camelize}Instruction"

      cls = Instructions.const_get instr_class.to_s
      cls.new(self, params).run!
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
end
