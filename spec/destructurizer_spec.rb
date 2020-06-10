RSpec.describe Binrip::Destructurizer do
  it 'destructures a composite hash' do
    format_desc = <<~YAML
      formats:
        stuff:
          fields:
          - name: somedata
            type: smpl
          - name: num
            type: int8
        smpl:
          fields:
          - name: xnum
            type: int8
    YAML

    hash = {
      'somedata' => {
        'xnum' => 220
      },
      'num' => 111
    }

    str = Binrip::Destructurizer.new(format_desc, 'stuff', hash)
    expect(str.structs).to eq([
      {
        type: 'stuff',
        fields: {
          'somedata' => { vals: [1] },
          'num' => { vals: [111] }
        }
      },
      {
        type: 'smpl',
        fields: {
          'xnum' => { vals: [220] }
        }
      }
    ])
  end

  it 'destructures a hash with an array' do
    format_desc = <<~YAML
      formats:
        smpl:
          fields:
          - name: nums
            type: int8
            size: 5
    YAML

    hash = {
      'nums' => [1, 2, 3, 4, 5]
    }

    str = Binrip::Destructurizer.new(format_desc, 'smpl', hash)
    expect(str.structs).to eq([
      {
        type: 'smpl',
        fields: {
          'nums' => { vals: [1, 2, 3, 4, 5] }
        }
      }
    ])
  end

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
