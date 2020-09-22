# frozen_string_literal: true

require 'binrip/format_compiler'

module Binrip
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
