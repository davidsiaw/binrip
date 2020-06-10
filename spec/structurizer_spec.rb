RSpec.describe Binrip::Structurizer do
  it 'structurizes a composite structlist' do
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

    structlist = [
      nil,
      {
        type: 'stuff',
        fields: {
          'somedata' => { vals: [2] },
          'num' => { vals: [111] }
        }
      },
      {
        type: 'smpl',
        fields: {
          'xnum' => { vals: [110] }
        }
      }
    ]

    str = Binrip::Structurizer.new(structlist, 1, format_desc)
    expect(str.structure).to eq(
      'somedata' => {
        'xnum' => 110
      },
      'num' => 111
    )
  end

  it 'structurizes a structlist' do
    format_desc = <<~YAML
      formats:
        smpl:
          fields:
          - name: anum
            type: int8
          - name: bnum
            type: int8
    YAML

    structlist = [
      {
        type: 'smpl',
        fields: {
          'anum' => { vals: [110] },
          'bnum' => { vals: [220] }
        }
      }
    ]

    str = Binrip::Structurizer.new(structlist, 0, format_desc)
    expect(str.structure).to eq(
      'anum' => 110,
      'bnum' => 220)
  end

  it 'structurizes a structlist with an array' do
    format_desc = <<~YAML
      formats:
        smpl:
          fields:
          - name: nums
            type: int8
            size: 4
    YAML

    structlist = [
      {
        type: 'smpl',
        fields: {
          'nums' => { vals: [2, 3, 4, 5] }
        }
      }
    ]

    str = Binrip::Structurizer.new(structlist, 0, format_desc)
    expect(str.structure).to eq(
      'nums' => [2, 3, 4, 5])
  end
end
