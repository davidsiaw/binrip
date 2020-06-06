# frozen_string_literal: true

module Binrip
  module Instructions
    class WriteBytesInstruction < Instruction
      include RegisterManipulation

      def run!
        num = src_value
        @params[0].times do |x|
          @machine.device.write_byte(num & 0xff)
          num >>= 8
        end
      end
    end
  end
end
