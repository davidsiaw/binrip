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
            type: int16
    YAML

    ripper = Binrip::Ripper.new(format_desc)

    expect(ripper.read('simple', [100, 200, 1])).to eq(
      'number' => 100,
      'another_number' => 456
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
            type: int16
    YAML

    ripper = Binrip::Ripper.new(format_desc)

    expect(ripper.write('simple',
                        'number' => 111,
                        'another_number' => 478)).to eq [111, 222, 1]
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
        { 'call' => ['alloc_and_read_simple'] }

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
