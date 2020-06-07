# frozen_string_literal: true

module Binrip
  module Instructions
    # set instrcution
    class PopInstruction < Instruction
      include RegisterManipulation

      def run!
        dst_assign(@machine.stack.pop)
      end
    end
  end
end
