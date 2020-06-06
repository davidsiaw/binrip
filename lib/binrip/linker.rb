# frozen_string_literal: true

module Binrip
  # linker
  class Linker
    def initialize(asm)
      @asm = asm
    end

    def positions
      pos = {}
      count = 0
      @asm.each do |fname, fdef|
        pos[fname] = count
        count += fdef.length + 1
      end
      pos
    end

    def output
      result = []
      @asm.each do |fname, fdef|
        fdef.each do |instr|
          params = instr.values[0]
          if instr.keys[0] == 'call'
            result << { 'call' => [ positions[params[0]] ] }
          else
            result << instr
          end
        end
        result << { 'return' => [] }
      end
      result
    end
  end
end
