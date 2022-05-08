require_relative './code'
require_relative './parser'
require_relative './symbol_table'
require 'byebug'

class Assembler
  def initialize
    @current_address = 0
    @variable_current_address = 16
    @symbol_table = SymbolTable.new
  end

  def execute(file)
    File.open(file) do |asm|
      first_pass(asm)

      asm.seek(0, IO::SEEK_SET)

      dir_name = File.dirname(file)
      file_name = "#{File.basename(file, '.asm')}"
      output_file_name = File.join(dir_name, "#{file_name}"'.hack')
      second_pass(asm, output_file_name)
    end
  end

  private

  def first_pass(file)
    parser = Parser.new(file)
    while parser.has_more_commands?
      parser.advance

      next if parser.command.empty?

      case parser.command_type
      when 'A_COMMAND', 'C_COMMAND'
        increment_current_address
      when 'L_COMMAND'
        @symbol_table.add_entry(parser.symbol, @current_address)
      end
    end
  end

  def second_pass(file, output_file_name)
    File.open(output_file_name, 'w') do |hack|
      parser = Parser.new(file)
      while parser.has_more_commands?
        parser.advance

        next if parser.command.empty?

        row =
          case parser.command_type
          when 'A_COMMAND'
            generate_address_command(parser)
          when 'C_COMMAND'
            generate_compute_command(parser)
          end

        next if row.nil?

        hack.write("#{row}\n")
      end
    end
  end

  def generate_address_command(parser)
    symbol =
      if @symbol_table.contains?(parser.symbol)
        @symbol_table.get_address(parser.symbol)
      elsif parser.symbol.to_i.to_s == parser.symbol
        parser.symbol
      else
        @symbol_table.add_entry(parser.symbol, @variable_current_address)
        increment_variable_current_address
        @symbol_table.get_address(parser.symbol)
      end

    symbol.to_i.to_s(2).rjust(16, '0')
  end

  def generate_compute_command(parser)
    parser.extract_controle_bit
    Code.new(parser).generate_compute_command
  end

  def increment_current_address
    @current_address += 1
  end

  def increment_variable_current_address
    @variable_current_address += 1
  end
end
