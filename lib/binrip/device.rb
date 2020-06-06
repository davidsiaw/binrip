# frozen_string_literal: true

module Binrip
  # imaginary device that holds structs and bytes
  class Device
    attr_accessor :bytes, :position, :structs

    def initialize
      @bytes = []
      @position = 0
      @structs = []
      @struct_index = 0
      @struct_member = ''
    end

    def read_byte
      curpos = @position
      @position += 1
      @bytes[curpos]
    end

    def write_byte(byte)
      @bytes[@position] = byte
      @position += 1
    end

    def alloc(type)
      idx = @structs.length
      @structs << { type: type, fields: {} }
      idx
    end

    def read_struct_value
      validate_index!

      raise "no such member #{curr_member_name}" if @structs[@struct_index][:fields][curr_member_name].nil?
      raise 'no such index in member' if @structs[@struct_index][:fields][curr_member_name][:vals][@member_index].nil?

      @structs[@struct_index][:fields][curr_member_name][:vals][@member_index]
    end

    def write_struct_value(value)
      validate_index!

      if @structs[@struct_index][:fields][curr_member_name].nil?
        @structs[@struct_index][:fields][curr_member_name] = { vals: [] }
      end

      @structs[@struct_index][:fields][curr_member_name][:vals][@member_index] = value
    end

    def validate_index!
      raise 'no such struct' if @structs[@struct_index].nil?
      raise 'wrong type' if curr_struct_type != @structs[@struct_index][:type]
    end

    def curr_struct_type
      @struct_member.split('.')[0]
    end

    def curr_member_name
      @struct_member.split('.')[1]
    end

    def index_struct_value(struct_member, struct_index, member_index)
      @struct_index = struct_index
      @struct_member = struct_member
      @member_index = member_index
    end
  end
end
