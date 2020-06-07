RSpec.describe Binrip::Linker do
  it 'throws error if called function not found' do
    co = YAML.load(<<~YAML)
      ---
      main:
        - call: [not_exist]
    YAML

    linker = Binrip::Linker.new(co)

    expect{ linker.output }.to raise_error RuntimeError, "Label 'not_exist' not found"
  end

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
