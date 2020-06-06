# frozen_string_literal: true

module Binrip
  module Instructions
    # set instrcution
    class SetInstruction < Instruction
      include RegisterManipulation

      def run!
        dst_assign(src_value)
      end
    end
  end
end
