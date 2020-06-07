# frozen_string_literal: true

module Binrip
  # base field compiler class
  class BaseFieldCompiler
    attr_reader :format_name

    def initialize(format_name, field_info)
      @format_name = format_name
      @field_info = field_info
    end

    def read_func_name
      @read_func_name ||= "read_#{format_name}_#{@field_info['name']}"
    end

    def write_func_name
      @write_func_name ||= "write_#{format_name}_#{@field_info['name']}"
    end
  end
end
