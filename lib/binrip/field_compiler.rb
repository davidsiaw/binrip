# frozen_string_literal: true

require 'binrip/basic_field_compiler'
require 'binrip/composite_field_compiler'

module Binrip
  # compiles fields
  class SimpleFieldCompiler
    attr_reader :format_name

    def initialize(format_name, field_info)
      @format_name = format_name
      @field_info = field_info
    end

    def delegate_class
      return BasicFieldCompiler if BasicFieldCompiler::BYTE_LENGTHS.key?(@field_info['type'])

      CompositeFieldCompiler
    end

    def delegate
      @delegate ||= delegate_class.new(@format_name, @field_info)
    end

    INTERFACE = %i[
      read_func_name
      read_func
      write_func_name
      write_func
      init_instrs
    ].freeze

    INTERFACE.each do |fun|
      define_method fun do
        delegate.send(fun)
      end
    end
  end

  # compiles fields (Every field is just an array)
  class FieldCompiler
    def initialize(format_name, field_info)
      @format_name = format_name
      @field_info = field_info
    end

    def inner_compiler
      @inner_compiler = SimpleFieldCompiler.new(@format_name, @field_info)
    end

    def array_size
      @field_info['size'] ||= 1
    end

    def loop_header
      return [] if array_size == 1

      [
        { 'set' => ['reg_e', 0] },
        { 'set' => ['reg_d', 'reg_pc'] },
        { 'set' => ['reg_c', -array_size] },
        { 'inc' => ['reg_c', 'reg_e'] },
        { 'jnz' => ['finish', 'reg_c'] }
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
