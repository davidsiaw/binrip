# frozen_string_literal: true

require 'binrip/base_field_compiler'

module Binrip
  # compiles basic typed fields
  class BasicFieldCompiler < BaseFieldCompiler
    BYTE_LENGTHS = {
      'int8' => 1,
      'int16' => 2,
      'int32' => 4,
      'int64' => 8,
      'uint8' => 1,
      'uint16' => 2,
      'uint32' => 4,
      'uint64' => 8
    }.freeze

    def byte_length
      len = BYTE_LENGTHS[@field_info['type']]
      raise "Unknown type '#{@field_info['type']}'" if len.nil?

      len
    end

    def read_func
      @read_func ||= [
        { 'index' => ["#{format_name}.#{@field_info['name']}", 'reg_a', 'reg_e'] },
        { 'read_bytes' => ['reg_dev', byte_length] }
      ]
    end

    def write_func
      @write_func ||= [
        { 'index' => ["#{format_name}.#{@field_info['name']}", 'reg_a', 'reg_e'] },
        { 'write_bytes' => [byte_length, 'reg_dev'] }
      ]
    end

    def init_instrs
      @init_instrs ||= [
        { 'index' => ["#{format_name}.#{@field_info['name']}", 'reg_a', 'reg_e'] },
        { 'set' => ['reg_dev', 0] }
      ]
    end
  end
end
