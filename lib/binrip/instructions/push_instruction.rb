# frozen_string_literal: true

module Binrip
  module Instructions
    # set instrcution
    class PushInstruction < Instruction
      include RegisterManipulation

      def run!
        @machine.stack.push dst_value
      end
    end
  end
end
