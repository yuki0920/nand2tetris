class CompilationEngine
  OPERATORS = %w( + - * / & | < > =).freeze
  UNARY_OPERATORS = %w(~ -).freeze
  KEYWORD_CONSTANTS = %w(true false null this).freeze

  def initialize(tokenizer, output_file)
    @tokenizer = tokenizer
    @output_file = output_file
  end

  def execute
    compile_class
  end

  private

  def compile_class
    @output_file.puts '<class>'
    compile_keyword('class')
    compile_class_name
    compile_symbol('{')

    compile_class_var_dec while next_class_val_dec?

    compile_subroutine while next_subroutine?

    compile_symbol('}')
    @output_file.puts '</class>'
  end

  def next_class_val_dec?
    next_token?(%w(static field))
  end

  def compile_class_var_dec
    @output_file.puts '<classVarDec>'
    compile_keyword('static', 'field')
    compile_type
    compile_var_name

    while next_token?(',')
      compile_symbol(',')
      compile_var_name
    end

    compile_symbol(';')
    @output_file.puts '</classVarDec>'
  end

  def next_subroutine?
    next_token?(%w(constructor function method))
  end

  def compile_subroutine
    @output_file.puts '<subroutineDec>'
    compile_keyword('constructor', 'function', 'method')
    if @tokenizer.see_next_token == 'void'
      compile_keyword('void')
    else
      compile_type
    end
    compile_subroutine_name
    compile_symbol('(')
    compile_parameter_list
    compile_symbol(')')
    compile_subroutine_body
    @output_file.puts '</subroutineDec>'
  end

  def compile_parameter_list
    @output_file.puts '<parameterList>'
    if next_token?(%w(int char boolean)) || @tokenizer.see_next_token_type == 'IDENTIFIER'
      compile_type
      compile_var_name
      while next_token?(',')
        compile_symbol(',')
        compile_type
        compile_var_name
      end
    end
    @output_file.puts '</parameterList>'
  end

  def compile_subroutine_body
    @output_file.puts '<subroutineBody>'
    compile_symbol('{')
    compile_var_dec while next_var_dec?
    compile_statements
    compile_symbol('}')
    @output_file.puts '</subroutineBody>'
  end

  def next_var_dec?
    next_token?('var')
  end

  def compile_var_dec
    @output_file.puts '<varDec>'
    compile_keyword('var')
    compile_type
    compile_var_name

    while next_token?(',')
      compile_symbol(',')
      compile_var_name
    end

    compile_symbol(';')

    @output_file.puts '</varDec>'
  end

  def compile_statements
    @output_file.puts '<statements>'
    compile_statement while next_statement?
    @output_file.puts '</statements>'
  end

  def next_statement?
    next_token?(%w(let if while do return))
  end

  def compile_statement
    case @tokenizer.see_next_token
    when 'let'
      compile_let_statement
    when 'if'
      compile_if_statement
    when 'while'
      compile_while_statement
    when 'do'
      compile_do_statement
    when 'return'
      compile_return_statement
    end
  end

  def compile_let_statement
    @output_file.puts '<letStatement>'
    compile_keyword('let')
    compile_var_name
    if next_token?('[')
      compile_symbol('[')
      compile_expression
      compile_symbol(']')
    end
    compile_symbol('=')
    compile_expression
    compile_symbol(';')
    @output_file.puts '</letStatement>'
  end

  def compile_if_statement
    @output_file.puts '<ifStatement>'
    compile_keyword('if')
    compile_symbol('(')
    compile_expression
    compile_symbol(')')
    compile_symbol('{')
    compile_statements
    compile_symbol('}')
    if next_token?('else')
      compile_keyword('else')
      compile_symbol('{')
      compile_statements
      compile_symbol('}')
    end
    @output_file.puts '</ifStatement>'
  end

  def compile_while_statement
    @output_file.puts '<whileStatement>'
    compile_keyword('while')
    compile_symbol('(')
    compile_expression
    compile_symbol(')')
    compile_symbol('{')
    compile_statements
    compile_symbol('}')
    @output_file.puts '</whileStatement>'
  end

  def compile_do_statement
    @output_file.puts '<doStatement>'
    compile_keyword('do')
    compile_subroutine_call
    compile_symbol(';')
    @output_file.puts '</doStatement>'
  end

  def compile_return_statement
    @output_file.puts '<returnStatement>'
    compile_keyword('return')
    unless next_token?(';')
      compile_expression
    end
    compile_symbol(';')
    @output_file.puts '</returnStatement>'
  end

  def compile_subroutine_call
    if next_token?('(', 1)
      compile_subroutine_name
      compile_symbol('(')
      compile_expression_list
      compile_symbol(')')
    else # class_name or var_name
      compile_identifier # compile class_name or var_name
      compile_symbol('.')
      compile_subroutine_name
      compile_symbol('(')
      compile_expression_list
      compile_symbol(')')
    end
  end

  def compile_expression_list
    @output_file.puts '<expressionList>'

    unless next_token?(')')
      compile_expression
      while next_token?(',')
        compile_symbol(',')
        compile_expression
      end
    end

    @output_file.puts '</expressionList>'
  end

  def compile_expression
    @output_file.puts '<expression>'
    compile_term
    while next_token?(OPERATORS)
      compile_symbol(*OPERATORS)
      compile_term
    end
    @output_file.puts '</expression>'
  end

  def compile_term
    @output_file.puts '<term>'
    case @tokenizer.see_next_token_type
    when 'INT_CONST'
      compile_integer_constant
    when 'STRING_CONST'
      compile_string_constant
    when 'KEYWORD'
      compile_keyword(*KEYWORD_CONSTANTS)
    when 'SYMBOL'
      if next_token?('(')
        compile_symbol('(')
        compile_expression
        compile_symbol(')')
      elsif next_token?(UNARY_OPERATORS)
        compile_symbol(*UNARY_OPERATORS)
        compile_term
      else
        railse 'Invalid term'
      end
    when 'IDENTIFIER'
      # NOTE: identifierは先読みする
      if next_token?(['(', '.'], 1)
        compile_subroutine_call
      elsif next_token?('[', 1) # var_name[]
        compile_identifier
        compile_symbol('[')
        compile_expression
        compile_symbol(']')
      else
        compile_identifier # var_name
      end
    end
    @output_file.puts '</term>'
  end

  def compile_type
    if next_token?(%w(int char boolean))
      compile_keyword('int', 'char', 'boolean')
    elsif @tokenizer.see_next_token_type == 'IDENTIFIER'
      compile_identifier
    end
  end

  def compile_keyword(*tokens)
    @tokenizer.advance

    unless tokens.include?(@tokenizer.keyword)
      raise "Invalid keyword: \nparameter: #{tokens}\ntoken:#{@tokenizer.keyword}"
    end

    write_element('keyword', @tokenizer.keyword)
  end

  def compile_symbol(*tokens)
    @tokenizer.advance

    unless tokens.include?(@tokenizer.token)
      raise "Invalid symbol: \nparameter: #{tokens}\ntoken: #{@tokenizer.token}"
    end

    write_element('symbol', @tokenizer.escaped_symbol)
  end

  def compile_integer_constant
    @tokenizer.advance

    raise "Invalid integer constant: #{@tokenizer.token}" unless @tokenizer.token =~ /^\d+$/

    write_element('integerConstant', @tokenizer.int_val)
  end

  def compile_string_constant
    @tokenizer.advance

    raise "Invalid string constant: #{@tokenizer.token}" unless @tokenizer.token =~ /^".*"$/

    write_element('stringConstant', @tokenizer.escaped_string_val)
  end

  def compile_identifier
    @tokenizer.advance

    write_element('identifier', @tokenizer.identifier)
  end

  def compile_class_name
    compile_identifier
  end

  def compile_subroutine_name
    compile_identifier
  end

  def compile_var_name
    compile_identifier
  end

  def write_element(element, value)
    @output_file.puts("<#{element}> #{value} </#{element}>")
  end

  def next_token?(tokens, index = 0)
    [*tokens].include?(@tokenizer.see_next_token(index))
  end
end
