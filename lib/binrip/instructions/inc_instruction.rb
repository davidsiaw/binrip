# frozen_string_literal: true

module Binrip
  module Instructions
    # increment instruction
    class IncInstruction < Instruction
      include RegisterManipulation

      def run!
        dst_assign(src_value + dst_value)
      end
    end
  end
end
