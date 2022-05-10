require_relative './jack_tokenizer'
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

  def compile_file(input_file)
    output_file = input_file.gsub(/\.jack$/, 'T.xml')
    File.open(output_file, 'w') do |o|
      o.puts("<tokens>\n")

      File.open(input_file, 'r') do |i|
        tokenizer = JackTokenizer.new(i)
        while tokenizer.has_more_tokens?
          token = tokenizer.advance

          next if token.nil?
          # debugger
          o.puts("<#{tokenizer.tag}> #{token.gsub(/"/, '')} </#{tokenizer.tag}>")
        end
      end
      o.puts('</tokens>')
    end
  end
end

JackAnalyzer.new(ARGV[0]).execute
