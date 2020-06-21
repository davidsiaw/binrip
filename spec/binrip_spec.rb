RSpec.describe Binrip do
  it 'has a version number' do
    expect(Binrip::VERSION).not_to be nil
  end

  it 'reads a field based on another field' do
    format_desc = <<~YAML
      formats:
        someobject:
          fields:
            - name: data
              type: int8
            - name: copieddata
              type: int8
              read: data
    YAML

    ripper = Binrip::Ripper.new(format_desc)

    expect(ripper.read('someobject', [4])).to eq(
      'data' => 4,
      'copieddata' => 4
    )
  end

  it 'reads a field based on a def' do
    format_desc = <<~YAML
      formats:
        someobject:
          fields:
            - name: data
              type: int8
              read: three
          defs:
            - name: three
            - expr: 3
    YAML

    ripper = Binrip::Ripper.new(format_desc)

    expect(ripper.read('someobject', [])).to eq(
      'data' => 3
    )
  end

  it 'writes a field based on a def' do
    format_desc = <<~YAML
      formats:
        someobject:
          fields:
            - name: data
              type: int8
              write: two
          defs:
            - name: two
            - expr: 2
    YAML

    ripper = Binrip::Ripper.new(format_desc)

    expect(ripper.write('someobject', {
      'data' => 100
    })).to eq(
      [2]
    )
  end

  it 'reads an array with variable size' do
    format_desc = <<~YAML
      formats:
        aoc:
          fields:
          - name: count
            type: int8
          - name: nums
            type: int8
            size: count
    YAML

    ripper = Binrip::Ripper.new(format_desc)

    expect(ripper.read('aoc', [3, 5, 6, 7, 8, 9])).to eq(
      'count' => 3,
      'nums' => [5, 6, 7]
    )
  end

  it 'writes an array with variable size' do
    format_desc = <<~YAML
      formats:
        aoc:
          fields:
          - name: count
            type: int8
          - name: nums
            type: int8
            size: count
    YAML

    ripper = Binrip::Ripper.new(format_desc)

    expect(ripper.write('aoc', {
      'count' => 4,
      'nums' => [1, 2, 3, 4]
    })).to eq(
      [4, 1, 2, 3, 4]
    )
  end

  it 'reads an array of composites' do
    format_desc = <<~YAML
      formats:
        aoc:
          fields:
          - name: data
            type: datum
            size: 4
        datum:
          fields:
          - name: num
            type: int16
    YAML

    ripper = Binrip::Ripper.new(format_desc)

    expect(ripper.read('aoc', [3, 0, 6, 0, 9, 0, 12, 0])).to eq(
      'data' => [
        { 'num' => 3 },
        { 'num' => 6 },
        { 'num' => 9 },
        { 'num' => 12 }
      ]
    )
  end

  it 'writes an array of composites' do
    format_desc = <<~YAML
      formats:
        aoc:
          fields:
          - name: data
            type: datum
            size: 4
        datum:
          fields:
          - name: num
            type: int16
    YAML

    ripper = Binrip::Ripper.new(format_desc)

    expect(ripper.write('aoc', {'data' => [
      { 'num' => 5 },
      { 'num' => 10 },
      { 'num' => 15 },
    ]})).to eq(
      [5, 0, 10, 0, 15, 0]
    )
  end

  it 'reads a struct with array' do
    format_desc = <<~YAML
      formats:
        somenums:
          fields:
          - name: nums
            type: int8
            size: 4
    YAML

    ripper = Binrip::Ripper.new(format_desc)

    expect(ripper.read('somenums', [2, 4, 6, 8])).to eq(
      'nums' => [2, 4, 6, 8]
    )
  end

  it 'writes a struct with array' do
    format_desc = <<~YAML
      formats:
        somenums:
          fields:
          - name: nums
            type: int8
            size: 3
    YAML

    ripper = Binrip::Ripper.new(format_desc)

    expect(ripper.write('somenums', {'nums' => [2, 3, 4]})).to eq(
      [2, 3, 4]
    )
  end

  it 'reads a composite struct' do
    format_desc = <<~YAML
      formats:
        composite:
          fields:
          - name: num
            type: int8
          - name: data
            type: simple
        simple:
          fields:
          - name: number
            type: int8
          - name: another_number
            type: int16
    YAML

    ripper = Binrip::Ripper.new(format_desc)

    expect(ripper.read('composite', [5, 100, 200, 1])).to eq(
      'num' => 5,
      'data' => {
        'number' => 100,
        'another_number' => 456
      }
    )
  end

  it 'writes a composite struct' do
    format_desc = <<~YAML
      formats:
        composite:
          fields:
          - name: num
            type: int8
          - name: data
            type: simple
        simple:
          fields:
          - name: number
            type: int8
          - name: another_number
            type: int16
    YAML

    ripper = Binrip::Ripper.new(format_desc)

    expect(ripper.write('composite',
                        'num' => 7,
                        'data' => {
                          'number' => 111,
                          'another_number' => 478
                        })).to eq [7, 111, 222, 1]
  end

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
