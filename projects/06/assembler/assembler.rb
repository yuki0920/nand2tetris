require_relative './code.rb'
require_relative './parser.rb'
require_relative './symbol_table.rb'
require 'byebug'


class Assembler
  def initialize
    @current_address = 0
    @variable_current_address = 16
  end

  def execute(file_name)
    input_file_name = file_name
    dir_name = File.dirname(file_name)
    file_name = File.basename(file_name, '.asm') + '1'
    output_file_name = File.join(dir_name, "#{file_name}"'.hack')
    symbol_table = SymbolTable.new

    File.open(input_file_name) do |asm|
      parser = Parser.new(asm)
      while parser.has_more_commands?
        parser.advance

        next if parser.command.empty?

        if parser.command_type == 'L_COMMAND'
          symbol_table.add_entry(parser.symbol, @current_address)
        elsif parser.command_type == 'A_COMMAND' || parser.command_type == 'C_COMMAND'
          increment_current_address
        end
      end

      asm.seek(0, IO::SEEK_SET)

      File.open(output_file_name, 'w') do |hack|
        parser = Parser.new(asm)
        while parser.has_more_commands?
          parser.advance

          next if parser.command.empty?

          command = if parser.command_type == 'C_COMMAND'
            parser.extract_controle_bit

            code = Code.new(parser)
            code.execute
          elsif parser.command_type == 'A_COMMAND'
            symbol = if symbol_table.contains?(parser.symbol)
              symbol_table.get_address(parser.symbol)
            elsif parser.symbol.to_i.to_s == parser.symbol
              parser.symbol
            else
              symbol_table.add_entry(parser.symbol, @variable_current_address)
              increment_variable_current_address
              symbol_table.get_address(parser.symbol)
            end

            symbol.to_i.to_s(2).rjust(16, '0')
          end

          next if command.nil?

          hack.write("#{command}\n")
        end
      end
    end
  end

  private

  def increment_current_address
    @current_address += 1
  end

  def increment_variable_current_address
    @variable_current_address += 1
  end
end
