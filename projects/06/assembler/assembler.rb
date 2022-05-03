require_relative './code.rb'
require_relative './parser.rb'
require_relative './symbol_table.rb'
require 'byebug'


class Assembler
  def initialize(file_name)
    @file_name = file_name
  end

  def execute
    File.open('./projects/06/add/Add1.hack', 'w') do |hack|
      File.open('./projects/06/add/Add.asm') do |asm|
        parser = Parser.new(asm)
        while parser.has_more_commands?
          parser.advance

          next if parser.command.empty?

          command = if parser.command_type == 'C_COMMAND'
            parser.extract_controle_bit

            code = Code.new(parser)
            code.execute
          elsif parser.command_type == 'A_COMMAND'
            parser.symbol.to_i.to_s(2).rjust(16, '0')
          else
            parser.command
          end

          hack.write("#{command}\n")
        end
      end
    end
  end
end

assembler = Assembler.new('dummy')
assembler.execute
