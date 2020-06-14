# frozen_string_literal: true

module Binrip
  module Instructions
    # decrement instruction
    class DecInstruction < Instruction
      include RegisterManipulation

      def run!
        dst_assign(dst_value - src_value)
      end
    end
  end
end
