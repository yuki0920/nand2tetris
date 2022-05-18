require_relative './jack_tokenizer'
require_relative './compilation_engine'
require 'byebug'

class JackAnalyzer
  def initialize(target)
    @target = target
  end

  def execute
    if File.extname(@target) == '.jack'
      compile_file(@target)
    else # directory
      Dir.open(@target).each_child do |file|
        next unless File.extname(file) == '.jack'

        path = File.join(@target, file)
        compile_file(path)
      end
    end
  end

  private

  def tokenize_file(input_file)
    output_file = input_file.gsub(/\.jack$/, 'T.xml')
    File.open(output_file, 'w') do |o|
      o.puts('<tokens>')
      File.open(input_file, 'r') do |i|
        JackTokenizer.new(i).execute(o)
      end
      o.puts('</tokens>')
    end
  end

  def compile_file(input_file)
    puts "Compiling #{input_file}"

    output_token_xml_file = input_file.gsub(/\.jack$/, 'T.xml')
    output_xml_file = input_file.gsub(/\.jack$/, '.xml')
    File.open(input_file, 'r') do |i|
      tokenizer = JackTokenizer.new(i)
      File.open(output_token_xml_file, 'w') do |o|
        tokenizer.execute(o)
      end
      File.open(output_xml_file, 'w') do |o|
        CompilationEngine.new(tokenizer, o).execute
      end
    end
  end
end

JackAnalyzer.new(ARGV[0]).execute
