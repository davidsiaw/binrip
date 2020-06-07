# frozen_string_literal: true

require 'binrip/base_field_compiler'

module Binrip
  # compiles custom fields
  class CompositeFieldCompiler < BaseFieldCompiler
    def read_func
      @read_func ||= [
        { 'push' => ['reg_a'] }, # save the pointer to the current struct
        # call the reader of the type
        { 'call' => ["alloc_and_read_#{@field_info['type']}"] },
        { 'set' => %w[reg_b reg_a] }, # put the pointer to read data in B
        { 'pop' => ['reg_a'] }, # load back the current struct to A
        { 'index' => ["#{format_name}.#{@field_info['name']}", 'reg_a', 0] },
        { 'set' => %w[reg_dev reg_b] } # write the pointer to the field
      ]
    end

    def write_func
      @write_func ||= [
        { 'push' => ['reg_a'] }, # save the current struct pointer
        { 'index' => ["#{format_name}.#{@field_info['name']}", 'reg_a', 0] },
        { 'set' => %w[reg_a reg_dev] }, # set the current struct to the inner
        { 'call' => ["write_#{@field_info['type']}"] }, # write the type
        { 'pop' => ['reg_a'] } # restore context
      ]
    end

    def init_instrs
      @init_instrs ||= [
        { 'index' => ["#{format_name}.#{@field_info['name']}", 'reg_a', 0] },
        { 'set' => ['reg_dev', 0] }
      ]
    end
  end
end
