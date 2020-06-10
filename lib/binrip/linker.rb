# frozen_string_literal: true

module Binrip
  # linker
  class Linker
    def initialize(asm)
      @asm = asm
    end

    def collapsed
      @collapsed ||= @asm.map do |fname, fdef|
        listing = []
        labels = {}
        fdef.each do |instr|
          if instr.keys[0] == 'label'
            labels[instr.values[0][0]] = listing.length
          else
            listing << instr
          end
        end
        listing << { 'return' => [] }
        [fname, {
          listing: listing,
          labels: labels
        }]
      end.to_h
    end

    def positions
      pos = {}
      count = 0
      collapsed.each do |fname, info|
        pos[fname] = count
        count += info[:listing].length
      end
      pos
    end

    def output
      result = []
      collapsed.each do |fname, info|
        info[:listing].each do |instr|
          result << process_instruction(instr, fname, info)
        end
      end
      result
    end

    def process_instruction(instr, fname, info)
      params = instr.values[0]
      if instr.keys[0] == 'call'
        raise "Label '#{params[0]}' not found" if positions[params[0]].nil?

        { 'call' => [positions[params[0]]] }

      elsif instr.keys[0] == 'jnz' && !params[0].start_with?('reg_')
        raise "Label '#{params[0]}' not found" if info[:labels][params[0]].nil?

        dest = info[:labels][params[0]] + positions[fname]
        { 'jnz' => [dest, params[1]]}

      else
        instr
      end
    end
  end
end
