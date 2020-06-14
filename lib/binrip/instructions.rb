# frozen_string_literal: true

module Binrip
  module Instructions
    # base class for instructions
    class Instruction
      def initialize(machine, params)
        @machine = machine
        @params = params
      end

      def run!; end
    end
  end
end

require 'binrip/instructions/register_manipulation'
require 'binrip/instructions/alloc_instruction'
require 'binrip/instructions/call_instruction'
require 'binrip/instructions/inc_instruction'
require 'binrip/instructions/dec_instruction'
require 'binrip/instructions/index_instruction'
require 'binrip/instructions/read_bytes_instruction'
require 'binrip/instructions/return_instruction'
require 'binrip/instructions/set_instruction'
require 'binrip/instructions/write_bytes_instruction'
require 'binrip/instructions/push_instruction'
require 'binrip/instructions/pop_instruction'
require 'binrip/instructions/jnz_instruction'
