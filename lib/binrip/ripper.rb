# frozen_string_literal: true

# Main module
module Binrip
  # entrypoint class
  class Ripper
    def initialize(desc)
      @desc = desc
    end

    def compiler
      fmt = YAML.safe_load(@desc)
      Binrip::Compiler.new(fmt)
    end

    def compiled
      @compiled ||= compiler.output['functions']
    end

    def read(typename, bytes)
      lnk = Binrip::Linker.new({
        'main' => [
          { 'call' => ["alloc_and_read_#{typename}"] }
        ]
      }.merge(compiled))

      dev = Binrip::Device.new
      dev.bytes = bytes

      int = Binrip::Interpreter.new(lnk.output, dev)
      int.run!

      str = Binrip::Structurizer.new(dev.structs, 0, @desc)
      str.structure
    end

    def write(typename, hash)
      lnk = Binrip::Linker.new({
        'main' => [
          { 'call' => ["write_#{typename}"] }
        ]
      }.merge(compiled))

      dev = Binrip::Device.new
      des = Binrip::Destructurizer.new(@desc, typename, hash)
      dev.structs = des.structs

      int = Binrip::Interpreter.new(lnk.output, dev)
      int.run!

      dev.bytes
    end
  end
end
