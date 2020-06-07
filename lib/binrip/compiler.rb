# frozen_string_literal: true

module Binrip
  # compiles individual fields
  class FieldCompiler
    attr_reader :format_name

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

    def initialize(format_name, field_info)
      @format_name = format_name
      @field_info = field_info
    end

    def byte_length
      len = BYTE_LENGTHS[@field_info['type']]
      raise "Unknown type '#{@field_info['type']}'" if len.nil?

      len
    end

    def read_func_name
      @read_func_name ||= "read_#{format_name}_#{@field_info['name']}"
    end

    def read_func
      @read_func ||= [
        { 'index' => ["#{format_name}.#{@field_info['name']}", 'reg_a', 0] },
        { 'read_bytes' => ['reg_dev', byte_length] }
      ]
    end

    def write_func_name
      @write_func_name ||= "write_#{format_name}_#{@field_info['name']}"
    end

    def write_func
      @write_func ||= [
        { 'index' => ["#{format_name}.#{@field_info['name']}", 'reg_a', 0] },
        { 'write_bytes' => [byte_length, 'reg_dev'] }
      ]
    end

    def init_instrs
      @init_instrs ||= begin
        [
          { 'index' => ["#{format_name}.#{@field_info['name']}", 'reg_a', 0] },
          { 'set' => ['reg_dev', 0] }
        ]
      end
    end
  end

  # compiles a format entry
  class FormatCompiler
    attr_reader :format_name

    FUNCS = %i[
      alloc_and_read_funcs
      alloc_funcs
      read_funcs
      write_funcs
      format_funcs
    ].freeze

    def initialize(format_name, format_info)
      @format_name = format_name
      @format_info = format_info
    end

    def field_compilers
      @field_compilers ||= @format_info['fields'].map do |field_info|
        FieldCompiler.new(format_name, field_info)
      end
    end

    def init_instrs
      @init_instrs = field_compilers.flat_map do |fc|
        fc.init_instrs
      end
    end

    def read_funcs
      @read_funcs ||= field_compilers.map do |fc|
        [fc.read_func_name, fc.read_func]
      end.to_h
    end

    def write_funcs
      @write_funcs ||= field_compilers.map do |fc|
        [fc.write_func_name, fc.write_func]
      end.to_h
    end

    def read_instrs
      @read_instrs ||= read_funcs.map do |name, _func|
        { 'call' => [name] }
      end
    end

    def write_instrs
      @write_instrs ||= write_funcs.map do |name, _func|
        { 'call' => [name] }
      end
    end

    def alloc_funcs
      {
        "alloc_#{format_name}" => [
          { 'alloc' => ['reg_a', format_name] }
        ]
      }
    end

    def alloc_and_read_funcs
      {
        "alloc_and_read_#{format_name}" => [
          { 'call' => ["alloc_#{format_name}"] },
          { 'call' => ["init_#{format_name}"] },
          { 'call' => ["read_#{format_name}"] }
        ]
      }
    end

    def format_funcs
      {
        "init_#{format_name}" => init_instrs,
        "read_#{format_name}" => read_instrs,
        "write_#{format_name}" => write_instrs
      }
    end

    def output
      result = {}

      FUNCS.each do |fun|
        result.merge! send(fun)
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
        forcom = FormatCompiler.new(name, info)
        result.merge!(forcom.output)
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
