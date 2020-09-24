# frozen_string_literal: true

require 'binrip/branching_compiler'

module Binrip
  # compiles field readers and writers (Every field is just an array)
  class ArrayCompiler
    def initialize(format_name, field_info)
      @format_name = format_name
      @field_info = field_info
    end

    def delegate_class
      return BasicFieldCompiler if BasicFieldCompiler::BYTE_LENGTHS.key?(@field_info['type'])

      CompositeFieldCompiler
    end

    def inner_compiler
      @inner_compiler ||= BranchingCompiler.new(delegate_class, @format_name, @field_info)
    end

    def array_size
      @field_info['size'] ||= 1
    end

    def load_referenced_number(symbol, register_name:)
      [
        { 'index' => ["#{@format_name}.#{symbol}", 'reg_a', 0] },
        { 'set' => [register_name, 'reg_dev'] }
      ]
    end

    def array_size_instructions(array_size)
      return ['set' => ['reg_c', array_size]] if array_size.is_a? Integer

      load_referenced_number(array_size, register_name: 'reg_c')
    end

    def loop_header
      return [{ 'set' => ['reg_e', 0] }] if array_size == 1

      [
        { 'set' => ['reg_e', 0] },
        { 'set' => ['reg_d', 'reg_pc'] },
        *array_size_instructions(array_size),
        { 'dec' => ['reg_c', 'reg_e'] },
        { 'jnz' => ['continue', 'reg_c'] },
        { 'jnz' => ['finish', 1] },
        { 'label' => ['continue'] }
      ]
    end

    def loop_footer
      return [] if array_size == 1

      [
        { 'inc' => ['reg_e', 1] },
        { 'jnz' => ['reg_d', 1] },
        { 'label' => ['finish'] }
      ]
    end

    def read_func_name
      inner_compiler.read_func_name
    end

    def write_func_name
      inner_compiler.write_func_name
    end

    def read_func
      @read_func ||= [
        *loop_header,
        *inner_compiler.read_func,
        *loop_footer
      ]
    end

    def write_func
      @write_func ||= [
        *loop_header,
        *inner_compiler.write_func,
        *loop_footer
      ]
    end

    def init_instrs
      @init_instrs ||= [
        *loop_header,
        *inner_compiler.init_instrs,
        *loop_footer
      ]
    end
  end
end
