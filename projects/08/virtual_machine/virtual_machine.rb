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
      output_path = "#{dir}/#{File.basename(dir)}.asm"
      code_writer = CodeWriter.new(output_path)

      if Dir.entries(dir).any? {|file| File.basename(file) == 'Sys.vm' }
        code_writer.write_init
      end

      Dir.foreach(dir) do |file_name|
        next unless File.extname(file_name) == '.vm'

        file_path = "#{dir}/#{file_name}"
        translate_file(file_path, code_writer)
      end
    end

    code_writer.close
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
      when 'C_LABEL'
        code_writer.write_label(parser.arg1)
      when 'C_GOTO'
        code_writer.write_goto(parser.arg1)
      when 'C_IF'
        code_writer.write_if(parser.arg1)
      when 'C_FUNCTION'
        code_writer.write_function(parser.arg1, parser.arg2)
      when 'C_RETURN'
        code_writer.write_return
      when 'C_CALL'
        code_writer.write_call(parser.arg1, parser.arg2)
      end
    end

    parser.close
  end
end

VirtualMachine.new.execute
