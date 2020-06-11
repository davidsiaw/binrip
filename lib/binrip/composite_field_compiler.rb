# frozen_string_literal: true

require 'binrip/base_field_compiler'

module Binrip
  # compiles custom fields
  class CompositeFieldCompiler < BaseFieldCompiler
    def read_func
      @read_func ||= [
        *save_context,
        # call the reader of the type
        { 'call' => ["alloc_and_read_#{@field_info['type']}"] },
        { 'set' => %w[reg_b reg_a] }, # put the pointer to read data in B
        *load_context,
        { 'index' => ["#{format_name}.#{@field_info['name']}", 'reg_a', 'reg_e'] },
        { 'set' => %w[reg_dev reg_b] } # write the pointer to the field
      ]
    end

    def write_func
      @write_func ||= [
        *save_context,
        { 'index' => ["#{format_name}.#{@field_info['name']}", 'reg_a', 'reg_e'] },
        { 'set' => %w[reg_a reg_dev] }, # set the current struct to the inner
        { 'call' => ["write_#{@field_info['type']}"] }, # write the type
        *load_context
      ]
    end

    def init_instrs
      @init_instrs ||= [
        { 'index' => ["#{format_name}.#{@field_info['name']}", 'reg_a', 'reg_e'] },
        { 'set' => ['reg_dev', 0] }
      ]
    end

    private

    def save_context
      %i[a c d e].map { |x| { 'push' => ["reg_#{x}"] } }
    end

    def load_context
      %i[e d c a].map { |x| { 'pop' => ["reg_#{x}"] } }
    end
  end
end
