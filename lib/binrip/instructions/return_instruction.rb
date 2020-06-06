# frozen_string_literal: true

module Binrip
  module Instructions
    # return from call instruction
    class ReturnInstruction < Instruction
      def run!
        return @machine.halt! if @machine.stack.length.zero?

        @machine.registers[:pc] = @machine.stack.pop
      end
    end
  end
end
