# frozen_string_literal: true

require 'binrip/array_compiler'

module Binrip
  # Used to generate expressions
  class ExpressionCompiler
    def initialize(format_info)
      @format_info = format_info
    end

    def generate_call(expr_tree)
    end
  end

  # Compiles a field that reads not from the file at that position but by
  # the value of another field or def
  class ReadCompiler < BaseFieldCompiler
    def initialize(format_name, format_summary, field_info)
      @format_name = format_name
      @format_summary = format_summary
      @field_info = field_info
    end

    def symbol
      @field_info['read']
    end

    def symbol_kind
      @format_summary[symbol][:kind]
    end

    def read_func
      if symbol_kind == :field
        [
          { 'index' => ["#{format_name}.#{symbol}", 'reg_a', 0] },
          { 'set' => ['reg_h', 'reg_dev'] },
          { 'index' => ["#{format_name}.#{@field_info['name']}", 'reg_a', 0] },
          { 'set' => ['reg_dev', 'reg_h'] }
        ]
      elsif symbol_kind == :def
        []
      else
        raise 'unknown field kind'
      end
    end
  end

  # Compiles a field that writes according to the contents of another field
  # or def
  class WriteCompiler < BaseFieldCompiler
    def initialize(format_name, format_summary, field_info)
      @format_name = format_name
      @format_summary = format_summary
      @field_info = field_info
    end

    def symbol
      @field_info['write']
    end

    def symbol_kind
      @format_summary[symbol][:kind]
    end

    def write_func
      if symbol_kind == :field
        ArrayCompiler.new(@format_name, @format_summary[symbol][:info]).write_func
      elsif symbol_kind == :def
        []
      else
        raise 'unknown field kind'
      end
    end
  end

  # Compiler used to compile a field that reads/writes from another
  # field or def
  class RefCompiler
    def initialize(format_name, format_info, field_info)
      @format_name = format_name
      @format_info = format_info
      @field_info = field_info
    end

    def format_summary
      fields = @format_info['fields'].map do |field_info|
        [field_info['name'], { kind: :field, info: field_info }]
      end.to_h

      defs = (@format_info['defs'] || {}).map do |def_info|
        [def_info['name'], { kind: :def, info: def_info }]
      end.to_h

      fields.merge defs
    end

    def inner_compiler
      @inner_compiler ||= ArrayCompiler.new(@format_name, @field_info)
    end

    def read_compiler
      @read_compiler ||= if @field_info.key? 'read'
                           ReadCompiler.new(@format_name, format_summary, @field_info)
                         else
                           inner_compiler
                         end
    end

    def write_compiler
      @write_compiler ||= if @field_info.key? 'write'
                            WriteCompiler.new(@format_name, format_summary, @field_info)
                          else
                            inner_compiler
                          end
    end

    def read_func_name
      read_compiler.read_func_name
    end

    def read_func
      read_compiler.read_func
    end

    def write_func_name
      write_compiler.write_func_name
    end

    def write_func
      write_compiler.write_func
    end

    def init_instrs
      inner_compiler.init_instrs
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
        RefCompiler.new(format_name, @format_info, field_info)
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
