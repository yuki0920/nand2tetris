require_relative './code.rb'
require_relative './parser.rb'
require_relative './symbol_table.rb'
require 'byebug'


class Assembler
  def execute(file_name)
    input_file_name = file_name
    dir_name = File.dirname(file_name)
    file_name = File.basename(file_name, '.asm') + '1'
    output_file_name = File.join(dir_name, "#{file_name}"'.hack')

    File.open(output_file_name, 'w') do |hack|
      File.open(input_file_name) do |asm|
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
