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

    def structure
      result = {}
      struct = @structs[@idx]
      format = @desc[struct[:type]]
      format['fields'].each do |field_info|
        name = field_info['name']
        vals = struct[:fields][name][:vals]
        if @desc.key? field_info['type']
          str = Structurizer.new(@structs, vals[0], @rawdesc)
          result[name] = str.structure
        else
          result[name] = vals[0]
        end
      end
      result
    end
  end
end
