# frozen_string_literal: true

module Binrip
  module Instructions
    # module for register manipulation
    module RegisterManipulation
      def dst_value
        register_retrieve dst_register_name
      end

      def dst_register_name
        register_name 0
      end

      def dst_assign(value)
        return memory_assign(value) if dst_register_name == :mem
        return device_assign(value) if dst_register_name == :dev

        @machine.registers[dst_register_name] = value
      end

      def src_value
        return @params[1] if @params[1].is_a? Integer

        register_retrieve src_register_name
      end

      def register_retrieve(register_name)
        return memory_retrieve if register_name == :mem
        return device_retrieve if register_name == :dev

        @machine.registers[register_name]
      end

      def src_register_name
        register_name 1
      end

      def memory_assign(value)
        @machine.memory[@machine.registers[:mr]] = value
      end

      def memory_retrieve
        @machine.memory[@machine.registers[:mr]]
      end

      def device_assign(value)
        @machine.device.write_struct_value(value)
      end

      def device_retrieve
        @machine.device.read_struct_value
      end

      def name_of(thing)
        thing.to_s.sub(/^reg_/, '').to_sym
      end

      def register_name(param_idx)
        val = name_of @params[param_idx]
        raise "invalid register #{val}" unless Interpreter::REGISTER_NAMES.include?(val)

        name_of val
      end
    end
  end
end
