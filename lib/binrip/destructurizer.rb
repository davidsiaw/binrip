# frozen_string_literal: true

module Binrip
  # destructurizer
  class Destructurizer
    def initialize(desc, struct_name, hash)
      @rawdesc = desc
      @desc = YAML.safe_load(desc)['formats']
      @hash = hash
      @struct_name = struct_name
    end

    def fields_for(format, result)
      format['fields'].map do |field_info|
        name = field_info['name']
        type = field_info['type']
        value = @hash[name]
        if @desc.key? type
          destr = Destructurizer.new(@rawdesc, type, @hash[name])
          value = result.count
          destr.structs(result)
        end

        [name, { vals: [value] }]
      end.to_h
    end

    def structs(result = [])
      format = @desc[@struct_name]

      destruct = {
        type: @struct_name,
        fields: nil
      }
      result << destruct
      destruct[:fields] = fields_for(format, result)

      result
    end
  end
end
