# frozen_string_literal: true

module Binrip
  module Instructions
    # call instruction
    class CallInstruction < Instruction
      def run!
        @machine.stack.push @machine.registers[:pc]
        @machine.registers[:pc] = @params[0]
      end
    end
  end
end
