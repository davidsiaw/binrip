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
