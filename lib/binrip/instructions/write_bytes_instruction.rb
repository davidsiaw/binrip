# frozen_string_literal: true

module Binrip
  module Instructions
    # write instruction
    class WriteBytesInstruction < Instruction
      include RegisterManipulation

      def run!
        num = src_value
        @params[0].times do |_x|
          @machine.device.write_byte(num & 0xff)
          num >>= 8
        end
      end
    end
  end
end
