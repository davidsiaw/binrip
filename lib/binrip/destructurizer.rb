# frozen_string_literal: true

module Binrip
  # destructurizer
  class Destructurizer
    def initialize(desc, struct_name, hash)
      @desc = YAML.safe_load(desc)['formats']
      @hash = hash
      @struct_name = struct_name
    end

    def fields_for(format)
      format['fields'].map do |field_info|
        name = field_info['name']
        [name, { vals: [@hash[name]] }]
      end.to_h
    end

    def structs(result = [])
      format = @desc[@struct_name]

      destruct = {
        type: @struct_name,
        fields: fields_for(format)
      }

      result << destruct

      result
    end
  end
end
