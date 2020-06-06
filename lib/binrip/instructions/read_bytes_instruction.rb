# frozen_string_literal: true

module Binrip
  module Instructions
    class ReadBytesInstruction < Instruction
      include RegisterManipulation

      def run!
        num = 0
        digit = 0
        src_value.times do |x|
          num += @machine.device.read_byte << digit
          digit += 8
        end
        
        dst_assign(num)
      end
    end
  end
end
