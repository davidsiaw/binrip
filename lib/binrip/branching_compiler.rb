# frozen_string_literal: true

require 'binrip/basic_field_compiler'
require 'binrip/composite_field_compiler'

module Binrip
  # Decides on a compiler depending on the input
  class BranchingCompiler
    attr_reader :format_name

    def initialize(delegate_class, *args)
      @delegate_class = delegate_class
      @args = args
    end

    def delegate
      @delegate ||= @delegate_class.new(*@args)
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
