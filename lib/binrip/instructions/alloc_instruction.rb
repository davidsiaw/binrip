# frozen_string_literal: true

module Binrip
  module Instructions
    # allocate structure instruction
    class AllocInstruction < Instruction
      include RegisterManipulation

      def run!
        dst_assign @machine.device.alloc(@params[1])
      end
    end
  end
end
