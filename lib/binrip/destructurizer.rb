# frozen_string_literal: true

module Binrip
  class Destructurizer
    def initialize(desc, struct_name, hash)
      @desc = YAML.load(desc)['formats']
      @hash = hash
      @struct_name = struct_name
    end

    def structs(result = [])
      format = @desc[@struct_name]

      fields = {}

      format['fields'].each do |field_info|
        name = field_info['name']
        fields[name] = {
          vals: [ @hash[name] ]
        }
      end

      destruct = {
        type: @struct_name,
        fields: fields
      }

      result << destruct

      result
    end
  end
end
