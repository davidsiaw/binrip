# frozen_string_literal: true

module Binrip
  # structurizer
  class Structurizer
    def initialize(structs, idx, desc)
      @structs = structs
      @idx = idx
      @desc = YAML.safe_load(desc)['formats']
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
