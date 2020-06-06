# frozen_string_literal: true

require 'binrip/version'
require 'yaml'
require 'active_support/inflector'

# Main module
module Binrip
  class Ripper
    def initialize(desc)
      @desc = desc
    end

    def compiler
      fmt = YAML.load(@desc)
      Binrip::Compiler.new(fmt)
    end

    def compiled
      @compiled ||= compiler.output['functions']
    end

    def read(typename, bytes)
      lnk = Binrip::Linker.new({
        'main' => [
          { 'call' => ["alloc_#{typename}"] },
          { 'call' => ["init_#{typename}"] },
          { 'call' => ["read_#{typename}"] }
        ]}.merge(compiled))

      dev = Binrip::Device.new
      dev.bytes = bytes

      int = Binrip::Interpreter.new(lnk.output, dev)
      int.run!

      str = Binrip::Structurizer.new(dev.structs, 0, @desc)
      str.structure
    end

    def write(typename, hash)
      lnk = Binrip::Linker.new({
        'main' => [
          { 'call' => ["write_#{typename}"] }
        ]}.merge(compiled))

      dev = Binrip::Device.new
      des = Binrip::Destructurizer.new(@desc, typename, hash)
      dev.structs = des.structs

      int = Binrip::Interpreter.new(lnk.output, dev)
      int.run!

      dev.bytes
    end
  end

  class Structurizer
    def initialize(structs, idx, desc)
      @structs = structs
      @idx = idx
      @desc = YAML.load(desc)['formats']
    end

    def structure
      result = {}
      struct = @structs[@idx]
      format = @desc[struct[:type]]
      format['fields'].each do |field_info|
        name = field_info['name']
        result[name] = struct[:fields][name][:vals][0]
      end
      result
    end
  end

  class Destructurizer
    def initialize(desc, struct_name, hash)
      @desc = YAML.load(desc)['formats']
      @hash = hash
      @struct_name = struct_name
    end

    def structs(result = [])
      format = @desc[@struct_name]

      fields = {}

      format['fields'].each do |field_info|
        name = field_info['name']
        fields[name] = {
          vals: [ @hash[name] ]
        }
      end

      destruct = {
        type: @struct_name,
        fields: fields
      }

      result << destruct

      result
    end
  end
  
  class Device
    attr_accessor :bytes, :position, :structs

    def initialize
      @bytes = []
      @position = 0
      @structs = []
      @struct_index = 0
      @struct_member = ''
    end

    def read_byte
      curpos = @position
      @position += 1
      @bytes[curpos]
    end

    def write_byte(byte)
      @bytes[@position] = byte
      @position += 1
    end

    def alloc(type)
      idx = @structs.length
      @structs << { type: type, fields: {} }
      idx
    end

    def read_struct_value
      validate_index!

      if @structs[@struct_index][:fields][curr_member_name].nil?
        raise "no such member #{curr_member_name}"
      end

      if @structs[@struct_index][:fields][curr_member_name][:vals][@member_index].nil?
        raise 'no such index in member'
      end

      @structs[@struct_index][:fields][curr_member_name][:vals][@member_index]
    end

    def write_struct_value(value)
      validate_index!

      if @structs[@struct_index][:fields][curr_member_name].nil?
        @structs[@struct_index][:fields][curr_member_name] = { vals: [] }
      end

      @structs[@struct_index][:fields][curr_member_name][:vals][@member_index] = value
    end

    def validate_index!
      raise 'no such struct' if @structs[@struct_index].nil?
      raise 'wrong type' if curr_struct_type != @structs[@struct_index][:type]

    end

    def curr_struct_type
      @struct_member.split('.')[0]
    end

    def curr_member_name
      @struct_member.split('.')[1]
    end

    def index_struct_value(struct_member, struct_index, member_index)
      @struct_index = struct_index
      @struct_member = struct_member
      @member_index = member_index
    end
  end

  module Instructions
    class Instruction
      def initialize(machine, params)
        @machine = machine
        @params = params
      end

      def run!; end
    end

    module RegisterManipulation
      def dst_value
        register_retrieve dst_register_name
      end

      def dst_register_name
        register_name 0
      end

      def dst_assign(value)
        return memory_assign(value) if dst_register_name == :mem
        return device_assign(value) if dst_register_name == :dev

        @machine.registers[dst_register_name] = value
      end

      def src_value
        return @params[1] if @params[1].is_a? Integer

        register_retrieve src_register_name
      end

      def register_retrieve(register_name)
        return memory_retrieve if register_name == :mem
        return device_retrieve if register_name == :dev

        @machine.registers[register_name]
      end

      def src_register_name
        register_name 1
      end

      def memory_assign(value)
        @machine.memory[@machine.registers[:mr]] = value
      end

      def memory_retrieve
        @machine.memory[@machine.registers[:mr]]
      end

      def device_assign(value)
        @machine.device.write_struct_value(value)
      end

      def device_retrieve
        @machine.device.read_struct_value
      end

      def name_of(thing)
        thing.to_s.sub(/^reg_/, '').to_sym
      end

      def register_name(param_idx)
        val = name_of @params[param_idx]
        unless Interpreter::REGISTER_NAMES.include?(val)
          raise "invalid register #{val}"
        end

        name_of val
      end
    end

    class SetInstruction < Instruction
      include RegisterManipulation

      def run!
        dst_assign(src_value)
      end
    end

    class CallInstruction < Instruction
      def run!
        @machine.stack.push @machine.registers[:pc]
        @machine.registers[:pc] = @params[0]
      end
    end

    class ReturnInstruction < Instruction
      def run!
        return @machine.halt! if @machine.stack.length.zero?

        @machine.registers[:pc] = @machine.stack.pop
      end
    end

    class IncInstruction < Instruction
      include RegisterManipulation

      def run!
        dst_assign(src_value + dst_value)
      end
    end

    class ReadBytesInstruction < Instruction
      include RegisterManipulation

      def run!
        num = 0
        digit = 0
        src_value.times do |x|
          num += @machine.device.read_byte << digit
          digit += 8
        end
        
        dst_assign(num)
      end
    end

    class WriteBytesInstruction < Instruction
      include RegisterManipulation

      def run!
        num = src_value
        @params[0].times do |x|
          @machine.device.write_byte(num & 0xff)
          num >>= 8
        end
      end
    end

    class AllocInstruction < Instruction
      include RegisterManipulation

      def run!
        dst_assign @machine.device.alloc(@params[1])
      end
    end

    class IndexInstruction < Instruction
      include RegisterManipulation

      def initialize(machine, params)
        @machine = machine
        @params = [params[1], params[2]]
        @member = params[0]
      end

      def run!
        @machine.device.index_struct_value(
          @member,
          dst_value,
          src_value)
      end
    end
  end

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
        break if halted?
      end
    end

    def step!
      return if halted? # no need to run if halted

      idx = register_value(:pc)
      increment(:pc)
      execute!(idx)

    rescue => e
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

      cls = Instructions.const_get "#{instr_class}"
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

  # linker
  class Linker
    def initialize(asm)
      @asm = asm
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
          { 'alloc' => ['reg_a', name] }
        ]

        init_instrs = []
        read_instrs = []
        write_instrs = []

        info['fields'].each do |field_info|
          read_func = "read_#{name}_#{field_info['name']}"
          write_func = "write_#{name}_#{field_info['name']}"

          result[read_func] = [            
            { 'index' => [ "#{name}.#{field_info['name']}", 'reg_a', 0] },
            { 'read_bytes' => ['reg_dev', 1] }
          ]

          result[write_func] = [            
            { 'index' => [ "#{name}.#{field_info['name']}", 'reg_a', 0] },
            { 'write_bytes' => [1, 'reg_dev'] }
          ]

          init_instrs += [
            { 'index' => [ "#{name}.#{field_info['name']}", 'reg_a', 0] },
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
