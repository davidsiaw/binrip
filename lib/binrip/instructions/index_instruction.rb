# frozen_string_literal: true

module Binrip
  module Instructions
    # set index instruction
    class IndexInstruction < Instruction
      include RegisterManipulation

      def initialize(machine, params)
        @machine = machine
        @params = [params[1], params[2]]
        @member = params[0]
      end

      def run!
        @machine.device.index_struct_value(
          @member,
          dst_value,
          src_value
        )
      end
    end
  end
end
