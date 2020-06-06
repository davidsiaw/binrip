# frozen_string_literal: true

module Binrip
  class Structurizer
    def initialize(structs, idx, desc)
      @structs = structs
      @idx = idx
      @desc = YAML.load(desc)['formats']
    end

    def structure
      result = {}
      struct = @structs[@idx]
      format = @desc[struct[:type]]
      format['fields'].each do |field_info|
        name = field_info['name']
        result[name] = struct[:fields][name][:vals][0]
      end
      result
    end
  end
end
