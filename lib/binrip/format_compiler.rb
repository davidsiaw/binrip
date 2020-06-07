# frozen_string_literal: true

module Binrip
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
      @init_instrs = field_compilers.flat_map(&:init_instrs)
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
end
