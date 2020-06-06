# frozen_string_literal: true

module Binrip
end

RSpec.describe Binrip::Destructurizer do
  it 'destructures a hash' do
    format_desc = <<~YAML
      formats:
        smpl:
          fields:
          - name: anum
            type: int8
          - name: bnum
            type: int8
    YAML

    hash = {
      'anum' => 110,
      'bnum' => 220
    }

    str = Binrip::Destructurizer.new(format_desc, 'smpl', hash)
    expect(str.structs).to eq([
      {
        type: 'smpl',
        fields: {
          'anum' => { vals: [110] },
          'bnum' => { vals: [220] }
        }
      }
    ])
  end
end

RSpec.describe Binrip do
  it 'has a version number' do
    expect(Binrip::VERSION).not_to be nil
  end

  # struct Something {
  #   int number;
  #   int count;
  #   int some_numbers[count];
  # }

  it 'reads a struct' do
    format_desc = <<~YAML
      formats:
        simple:
          fields:
          - name: number
            type: int8
          - name: another_number
            type: int8
    YAML

    ripper = Binrip::Ripper.new(format_desc)

    expect(ripper.read('simple', [100, 200])).to eq(
      'number' => 100,
      'another_number' => 200
    )
  end

  it 'writes a struct' do
    format_desc = <<~YAML
      formats:
        simple:
          fields:
          - name: number
            type: int8
          - name: another_number
            type: int8
    YAML

    ripper = Binrip::Ripper.new(format_desc)

    expect(ripper.write('simple',
                        'number' => 111,
                        'another_number' => 222)).to eq [111, 222]
  end

  it 'test reading a struct' do
    format_desc = <<~YAML
      formats:
        simple:
          fields:
          - name: number
            type: int8
          - name: another_number
            type: int8
    YAML

    fmt = YAML.load(format_desc)
    brc = Binrip::Compiler.new(fmt)

    lnk = Binrip::Linker.new({
      'main' => [
        { 'call' => ['alloc_simple'] },
        { 'call' => ['init_simple'] },
        { 'call' => ['read_simple'] }

      ]}.merge(brc.output['functions']))

    dev = Binrip::Device.new
    dev.bytes = [100, 200]

    int = Binrip::Interpreter.new(lnk.output, dev)
    int.run!

    expect(int.error).to be_nil

    expect(dev.structs[0]).to eq({
      type: 'simple',
      fields: {
        'number' => { vals: [100] },
        'another_number' => { vals: [200] }
      }
    })

    str = Binrip::Structurizer.new(dev.structs, 0, format_desc)
    expect(str.structure).to eq('number' => 100, 'another_number' => 200)
  end
end

RSpec.describe Binrip::Compiler do
  it 'compiles a description to read and write' do

    yaml = <<~YAML
      formats:
        simple:
          fields:
          - name: number
            type: int8
    YAML
    compiler = Binrip::Compiler.new(YAML.load(yaml))
    expect(compiler.output).to eq YAML.load(<<~YAML)
      functions:
        alloc_simple:
        - alloc: [reg_a, simple]

        init_simple:
        - index: [simple.number, reg_a, 0]
        - set: [reg_dev, 0]

        read_simple:
        - call: [read_simple_number]

        read_simple_number:
        - index: [simple.number, reg_a, 0]
        - read_bytes: [reg_dev, 1]

        write_simple:
        - call: [write_simple_number]
        
        write_simple_number:
        - index: [simple.number, reg_a, 0]
        - write_bytes: [1, reg_dev]
    YAML
  end
end

RSpec.describe Binrip::Linker do
  it 'assembles compiler output to a string of instructions' do
    compiler_output = YAML.load(<<~YAML)
      ---
      main:
        - set: [reg_a, 2]
        - call: [a_function]
        - inc: [reg_a, 3]

      a_function:
        - inc: [reg_a, 1]
    YAML

    linker = Binrip::Linker.new(compiler_output)

    expect(linker.output).to eq YAML.load(<<~YAML)
      - set: [reg_a, 2]  # 0 main
      - call: [4]        # 1 call a_function
      - inc: [reg_a, 3]  # 2
      - return: []       # 3
      - inc: [reg_a, 1]  # 4 a_function
      - return: []       # 5 ret
    YAML
  end
end

RSpec.describe Binrip::Interpreter do
  it 'interprets a simple set of instructions' do
    instructions = YAML.load(<<~YAML)
      - set: [reg_a, 2]
      - set: [reg_b, 3]
      - set: [reg_c, 4]
    YAML

    d = Binrip::Device.new

    machine = Binrip::Interpreter.new(instructions, d)

    loop do
      machine.step!
      break if machine.halted?
    end

    expect(machine.error).to be_nil
    expect(machine.register_value(:a)).to eq 2
    expect(machine.register_value(:b)).to eq 3
    expect(machine.register_value(:c)).to eq 4
  end

  it 'interprets a bunch of jumps' do
    instructions = YAML.load(<<~YAML)
      - set: [reg_a, 2]  # 0 main
      - call: [4]        # 1 call a_function
      - inc: [reg_a, 3]  # 2
      - return: []       # 3
      - inc: [reg_a, 1]  # 4 a_function
      - return: []       # 5 ret
    YAML

    d = Binrip::Device.new

    machine = Binrip::Interpreter.new(instructions, d)

    loop do
      machine.step!
      break if machine.halted?
    end

    expect(machine.error).to be_nil
    expect(machine.register_value(:a)).to eq 6
  end

  it 'interprets memory set' do
    instructions = YAML.load(<<~YAML)
      - set: [reg_mr, 1]
      - set: [reg_mem, 10]
    YAML

    d = Binrip::Device.new

    machine = Binrip::Interpreter.new(instructions, d)

    loop do
      machine.step!
      break if machine.halted?
    end

    expect(machine.error).to be_nil
    expect(machine.memory[1]).to eq 10
  end

  it 'interprets memory get' do
    instructions = YAML.load(<<~YAML)
      - set: [reg_mr, 2]
      - set: [reg_b, reg_mem]
    YAML

    d = Binrip::Device.new

    machine = Binrip::Interpreter.new(instructions, d)

    machine.memory[2] = 12

    loop do
      machine.step!
      break if machine.halted?
    end

    expect(machine.error).to be_nil
    expect(machine.registers[:b]).to eq 12
  end

  it 'interprets device int8 read' do
    instructions = YAML.load(<<~YAML)
      - read_bytes: [reg_b, 1]
    YAML

    d = Binrip::Device.new
    d.bytes = [22]

    machine = Binrip::Interpreter.new(instructions, d)

    loop do
      machine.step!
      break if machine.halted?
    end

    expect(machine.error).to be_nil
    expect(machine.registers[:b]).to eq 22
  end

  it 'interprets device int16 read' do
    instructions = YAML.load(<<~YAML)
      - read_bytes: [reg_b, 2]
    YAML

    d = Binrip::Device.new
    d.bytes = [1, 1]

    machine = Binrip::Interpreter.new(instructions, d)

    loop do
      machine.step!
      break if machine.halted?
    end

    expect(machine.error).to be_nil
    expect(machine.registers[:b]).to eq 257
  end

  it 'interprets device int8 write' do
    instructions = YAML.load(<<~YAML)
      - set: [reg_b, 5]
      - write_bytes: [1, reg_b]
    YAML

    d = Binrip::Device.new

    machine = Binrip::Interpreter.new(instructions, d)

    loop do
      machine.step!
      break if machine.halted?
    end

    expect(machine.error).to be_nil
    expect(d.bytes).to eq [5]
  end

  it 'interprets device int16 write' do
    instructions = YAML.load(<<~YAML)
      - set: [reg_b, 258]
      - write_bytes: [2, reg_b]
    YAML

    d = Binrip::Device.new

    machine = Binrip::Interpreter.new(instructions, d)

    loop do
      machine.step!
      break if machine.halted?
    end

    expect(machine.error).to be_nil
    expect(d.bytes).to eq [2, 1]
  end

  it 'interprets device alloc' do
    instructions = YAML.load(<<~YAML)
      - alloc: [reg_a, woof]
      - alloc: [reg_a, meow]
    YAML

    d = Binrip::Device.new

    machine = Binrip::Interpreter.new(instructions, d)

    loop do
      machine.step!
      break if machine.halted?
    end

    expect(machine.error).to be_nil
    expect(machine.registers[:a]).to eq 1
    expect(d.structs[0]).to eq({type: 'woof', fields: {}})
    expect(d.structs[1]).to eq({type: 'meow', fields: {}})
  end

  it 'interprets device read' do
    instructions = YAML.load(<<~YAML)
      - set: [reg_a, 2]
      - index: [simple.number, reg_a, 0]
      - set: [reg_b, reg_dev]
    YAML

    d = Binrip::Device.new
    d.structs[0] = {
      type: 'simple',
      fields: {
        'number' => { vals: [15] }
      }
    }
    d.structs[2] = {
      type: 'simple',
      fields: {
        'number' => { vals: [5] }
      }
    }

    machine = Binrip::Interpreter.new(instructions, d)

    loop do
      machine.step!
      break if machine.halted?
    end

    #p machine.error&.backtrace
    expect(machine.error).to be_nil
    expect(machine.registers[:b]).to eq 5
  end

  it 'interprets device write' do
    instructions = YAML.load(<<~YAML)
      - set: [reg_a, 4]
      - index: [simple.number, reg_a, 0]
      - set: [reg_dev, 20]
    YAML

    d = Binrip::Device.new
    d.structs[4] = {
      type: 'simple',
      fields: {
        'number' => { vals: [5] }
      }
    }

    machine = Binrip::Interpreter.new(instructions, d)

    loop do
      machine.step!
      break if machine.halted?
    end

    #p machine.error&.backtrace
    expect(machine.error).to be_nil
    expect(d.structs[4]).to eq({
      type: 'simple',
      fields: {
        'number' => { vals: [20] }
      }
    })
  end
end
