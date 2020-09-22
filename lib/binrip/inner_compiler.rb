# frozen_string_literal: true

require 'binrip/basic_field_compiler'
require 'binrip/composite_field_compiler'

module Binrip
  # compiles instructions to read and write each element of an array
  class InnerCompiler
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
end
