require_relative 'parser'
require_relative 'code_writer'
require 'byebug'

# ruby ./projects/07/virtual_machine/virtual_machine.rb  ./projects/07/StackArithmetic/SimpleAdd/SimpleAdd.vm
class VirtualMachine
  def execute
    path = ARGV[0]
    if path.end_with?('.vm')
      code_writer = CodeWriter.new(path.gsub(/\.vm$/, '.asm'))
      translate_file(path, code_writer)
    else
      dir = path.end_with?('/') ? path[..-2] : path
      code_writer = CodeWriter.new("#{dir}.asm")
      Dir.foreach(dir) do |file_name|
        translate_file(file_name, code_writer)
      end
    end
  end

  private

  def translate_file(file_name, code_writer)
    code_writer.set_file_name(file_name)
    parser = Parser.new(file_name)
    while parser.has_more_commands?
      parser.advance

      next if parser.current_command.empty?

      case parser.command_type
      when 'C_ARITHMETIC'
        code_writer.write_aristhmetic(parser.arg1)
      when 'C_PUSH'
        code_writer.write_push('C_PUSH', parser.arg1, parser.arg2)
      when 'C_POP'
        code_writer.write_pop('C_POP', parser.arg1, parser.arg2)
      end
    end
  end
end

VirtualMachine.new.execute
