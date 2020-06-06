# frozen_string_literal: true

module Binrip
  # compiler
  class Compiler
    def initialize(desc)
      @desc = desc
    end

    def functions
      result = {}
      @desc['formats'].each do |name, info|
        result["alloc_#{name}"] = [
          { 'alloc' => ['reg_a', name] }
        ]

        init_instrs = []
        read_instrs = []
        write_instrs = []

        info['fields'].each do |field_info|
          read_func = "read_#{name}_#{field_info['name']}"
          write_func = "write_#{name}_#{field_info['name']}"

          result[read_func] = [
            { 'index' => ["#{name}.#{field_info['name']}", 'reg_a', 0] },
            { 'read_bytes' => ['reg_dev', 1] }
          ]

          result[write_func] = [
            { 'index' => ["#{name}.#{field_info['name']}", 'reg_a', 0] },
            { 'write_bytes' => [1, 'reg_dev'] }
          ]

          init_instrs += [
            { 'index' => ["#{name}.#{field_info['name']}", 'reg_a', 0] },
            { 'set' => ['reg_dev', 0] }
          ]

          read_instrs << { 'call' => [read_func] }
          write_instrs << { 'call' => [write_func] }
        end

        result["init_#{name}"] = init_instrs
        result["read_#{name}"] = read_instrs
        result["write_#{name}"] = write_instrs
      end
      result
    end

    def output
      {
        'functions' => functions
      }
    end
  end
end
