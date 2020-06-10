RSpec.describe Binrip::Compiler do

  it 'compiles a description to read and write an array' do

    yaml = <<~YAML
      formats:
        simple:
          fields:
          - name: numbers
            type: int8
            size: 4
    YAML
    compiler = Binrip::Compiler.new(YAML.load(yaml))
    expect(compiler.output.to_yaml).to eq YAML.load(<<~YAML).to_yaml
      functions:
        alloc_and_read_simple:
        - call: [alloc_simple]
        - call: [init_simple]
        - call: [read_simple]

        alloc_simple:
        - alloc: [reg_a, simple]

        read_simple_numbers:
        - set: [reg_e, 0]
        - set: [reg_d, reg_pc]
        - set: [reg_c, -4]
        - inc: [reg_c, reg_e]
        - jnz: [finish, reg_c]
        - index: [simple.numbers, reg_a, reg_e]
        - read_bytes: [reg_dev, 1]
        - inc: [reg_e, 1]
        - jnz: [reg_d, 1]
        - label: [finish]

        write_simple_numbers:
        - set: [reg_e, 0]
        - set: [reg_d, reg_pc]
        - set: [reg_c, -4]
        - inc: [reg_c, reg_e]
        - jnz: [finish, reg_c]
        - index: [simple.numbers, reg_a, reg_e]
        - write_bytes: [1, reg_dev]
        - inc: [reg_e, 1]
        - jnz: [reg_d, 1]
        - label: [finish]

        init_simple:
        - set: [reg_e, 0]
        - set: [reg_d, reg_pc]
        - set: [reg_c, -4]
        - inc: [reg_c, reg_e]
        - jnz: [finish, reg_c]
        - index: [simple.numbers, reg_a, reg_e]
        - set: [reg_dev, 0]
        - inc: [reg_e, 1]
        - jnz: [reg_d, 1]
        - label: [finish]

        read_simple:
        - call: [read_simple_numbers]

        write_simple:
        - call: [write_simple_numbers]
    YAML
  end

  it 'compiles a description to read and write composite format' do

    yaml = <<~YAML
      formats:
        composite:
          fields:
          - name: data
            type: simple
          - name: num
            type: int8
        simple:
          fields:
          - name: number
            type: int16
    YAML
    compiler = Binrip::Compiler.new(YAML.load(yaml))
    expect(compiler.output.to_yaml).to eq YAML.load(<<~YAML).to_yaml
      functions:
        alloc_and_read_composite:
        - call: [alloc_composite]
        - call: [init_composite]
        - call: [read_composite]

        alloc_composite:
        - alloc: [reg_a, composite]

        read_composite_data:
        - push: [reg_a]
        - call: [alloc_and_read_simple]
        - set: [reg_b, reg_a]
        - pop: [reg_a]
        - index: [composite.data, reg_a, 0]
        - set: [reg_dev, reg_b]

        read_composite_num:
        - index: [composite.num, reg_a, 0]
        - read_bytes: [reg_dev, 1]

        write_composite_data:
        - push: [reg_a]
        - index: [composite.data, reg_a, 0]
        - set: [reg_a, reg_dev]
        - call: [write_simple]
        - pop: [reg_a]

        write_composite_num:
        - index: [composite.num, reg_a, 0]
        - write_bytes: [1, reg_dev]

        init_composite:
        - index: [composite.data, reg_a, 0]
        - set: [reg_dev, 0]
        - index: [composite.num, reg_a, 0]
        - set: [reg_dev, 0]

        read_composite:
        - call: [read_composite_data]
        - call: [read_composite_num]

        write_composite:
        - call: [write_composite_data]
        - call: [write_composite_num]

        alloc_and_read_simple:
        - call: [alloc_simple]
        - call: [init_simple]
        - call: [read_simple]

        alloc_simple:
        - alloc: [reg_a, simple]

        read_simple_number:
        - index: [simple.number, reg_a, 0]
        - read_bytes: [reg_dev, 2]

        write_simple_number:
        - index: [simple.number, reg_a, 0]
        - write_bytes: [2, reg_dev]

        init_simple:
        - index: [simple.number, reg_a, 0]
        - set: [reg_dev, 0]

        read_simple:
        - call: [read_simple_number]

        write_simple:
        - call: [write_simple_number]
    YAML
  end

  it 'compiles a description to read and write two bytes' do

    yaml = <<~YAML
      formats:
        simple:
          fields:
          - name: number
            type: int16
    YAML
    compiler = Binrip::Compiler.new(YAML.load(yaml))
    expect(compiler.output.to_yaml).to eq YAML.load(<<~YAML).to_yaml
      functions:
        alloc_and_read_simple:
        - call: [alloc_simple]
        - call: [init_simple]
        - call: [read_simple]

        alloc_simple:
        - alloc: [reg_a, simple]

        read_simple_number:
        - index: [simple.number, reg_a, 0]
        - read_bytes: [reg_dev, 2]

        write_simple_number:
        - index: [simple.number, reg_a, 0]
        - write_bytes: [2, reg_dev]

        init_simple:
        - index: [simple.number, reg_a, 0]
        - set: [reg_dev, 0]

        read_simple:
        - call: [read_simple_number]

        write_simple:
        - call: [write_simple_number]
    YAML
  end

  it 'compiles a description to read and write' do

    yaml = <<~YAML
      formats:
        simple:
          fields:
          - name: number
            type: int8
    YAML
    compiler = Binrip::Compiler.new(YAML.load(yaml))
    expect(compiler.output.to_yaml).to eq YAML.load(<<~YAML).to_yaml
      functions:
        alloc_and_read_simple:
        - call: [alloc_simple]
        - call: [init_simple]
        - call: [read_simple]

        alloc_simple:
        - alloc: [reg_a, simple]

        read_simple_number:
        - index: [simple.number, reg_a, 0]
        - read_bytes: [reg_dev, 1]

        write_simple_number:
        - index: [simple.number, reg_a, 0]
        - write_bytes: [1, reg_dev]

        init_simple:
        - index: [simple.number, reg_a, 0]
        - set: [reg_dev, 0]

        read_simple:
        - call: [read_simple_number]

        write_simple:
        - call: [write_simple_number]
    YAML
  end
end
