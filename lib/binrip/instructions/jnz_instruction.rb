# frozen_string_literal: true

module Binrip
  module Instructions
    # jump if not zero instruction
    class JnzInstruction < Instruction
      include RegisterManipulation

      def run!
        return if condition.zero?

        @machine.registers[:pc] = dest
      end

      private

      def condition
        src_value
      end

      def dest
        return @params[0] if @params[0].is_a? Integer

        dst_value
      end
    end
  end
end
