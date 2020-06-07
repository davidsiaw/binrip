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
