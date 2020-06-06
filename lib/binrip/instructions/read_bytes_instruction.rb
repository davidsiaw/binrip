# frozen_string_literal: true

module Binrip
  module Instructions
    # read bytes instruction
    class ReadBytesInstruction < Instruction
      include RegisterManipulation

      def run!
        num = 0
        digit = 0
        src_value.times do |_x|
          num += @machine.device.read_byte << digit
          digit += 8
        end

        dst_assign(num)
      end
    end
  end
end
