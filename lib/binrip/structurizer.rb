# frozen_string_literal: true

module Binrip
  # structurizer
  class Structurizer
    def initialize(structs, idx, desc)
      @structs = structs
      @idx = idx
      @rawdesc = desc
      @desc = YAML.safe_load(desc)['formats']
    end

    def value_for(struct, field_info, index)
      name = field_info['name']
      vals = struct[:fields][name][:vals]
      if @desc.key? field_info['type']
        str = Structurizer.new(@structs, vals[index], @rawdesc)
        str.structure
      else
        vals[index]
      end
    end

    def array_value_for(struct, field_info)
      return value_for(struct, field_info, 0) unless field_info.key?('size')

      result = []
      name = field_info['name']
      struct[:fields][name][:vals].length.times do |idx|
        result << value_for(struct, field_info, idx)
      end
      result
    end

    def structure
      result = {}
      struct = @structs[@idx]
      format = @desc[struct[:type]]
      format['fields'].each do |field_info|
        name = field_info['name']
        result[name] = array_value_for(struct, field_info)
      end
      result
    end
  end
end
