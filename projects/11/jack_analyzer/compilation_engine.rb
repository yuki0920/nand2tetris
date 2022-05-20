require_relative './vm_writer'
require_relative './symbol_table'

class CompilationEngine
  OPERATORS = %w(+ - * / & | < > =).freeze
  UNARY_OPERATORS = {
    '~' => 'not',
    '-' => 'neg'
  }.freeze
  KEYWORD_CONSTANTS = %w(true false null this).freeze

  def initialize(tokenizer, output_file)
    @tokenizer = tokenizer
    @output_file = output_file
    vm_file = File.path(output_file).gsub(/\.xml$/, '.vm')
    @vm_writer = VMWriter.new(vm_file)
    @symbol_table = SymbolTable.new
    @compiled_class_name = nil
    @label_num = 0
  end

  def execute
    compile_class
  end

  private

  def get_new_label
    @label_num += 1
    "LABEL_#{@label_num}"
  end

  def compile_class
    @output_file.puts '<class>'
    compile_keyword('class')
    @compiled_class_name = compile_class_name
    compile_symbol('{')

    compile_class_var_dec while next_class_val_dec?

    compile_subroutine_dec while next_subroutine?

    compile_symbol('}')
    @output_file.puts '</class>'
    @vm_writer.close
  end

  def next_class_val_dec?
    next_token?(%w(static field))
  end

  def compile_class_var_dec
    @output_file.puts '<classVarDec>'

    keyword = compile_keyword('static', 'field')
    type = compile_type

    compile_var_name(declaration: true, type: type, kind: keyword)

    while next_token?(',')
      compile_symbol(',')
      compile_var_name(declaration: true, type: type, kind: keyword)
    end

    compile_symbol(';')
    @output_file.puts '</classVarDec>'
  end

  def next_subroutine?
    next_token?(%w(constructor function method))
  end

  def compile_subroutine_dec
    @symbol_table.start_subroutine

    @output_file.puts '<subroutineDec>'
    keyword = compile_keyword('constructor', 'function', 'method')

    if keyword == 'method' # メソッドの最初の引数はthisオブジェクト
      @symbol_table.define(name: '$this', type: @compiled_class_name, kind: 'arg')
    end

    if @tokenizer.see_next_token == 'void'
      compile_keyword('void')
    else
      compile_type
    end

    subroutine_name = compile_subroutine_name
    compile_symbol('(')

    compile_parameter_list

    compile_symbol(')')
    compile_subroutine_body(subroutine_name, keyword)
    @output_file.puts '</subroutineDec>'
  end

  def compile_parameter_list
    @output_file.puts '<parameterList>'
    if next_token?(%w(int char boolean)) || @tokenizer.see_next_token_type == 'IDENTIFIER'
      type = compile_type
      compile_var_name(declaration: true, type: type, kind: 'arg')
      while next_token?(',')
        compile_symbol(',')
        compile_type
        compile_var_name(declaration: true, type: type, kind: 'arg')
      end
    end
    @output_file.puts '</parameterList>'
  end

  def compile_subroutine_body(subroutine_name, subroutine_dec_token)
    unless %w(constructor function method).include?(subroutine_dec_token)
      raise "Invalid #{subroutine_dec_token}"
    end

    @output_file.puts '<subroutineBody>'
    compile_symbol('{')

    number_of_locals = 0
    while next_var_dec?
      number_of_vars = compile_var_dec
      number_of_locals += number_of_vars
    end

    @vm_writer.write_function("#{@compiled_class_name}.#{subroutine_name}", number_of_locals)

    case subroutine_dec_token
    when 'method' # これ何?
      @vm_writer.write_push('argument', 0)
      @vm_writer.write_pop('pointer', 0)
    when 'constructor'
      @vm_writer.write_push('constant', @symbol_table.var_count('field'))
      @vm_writer.write_call('Memory.alloc', 1)
      @vm_writer.write_pop('pointer', 0)
    when 'function'
      # noop
    end

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
    type = compile_type
    compile_var_name(declaration: true, type: type, kind: 'var')

    number_of_vars = 1
    while next_token?(',')
      compile_symbol(',')
      compile_var_name(declaration: true, type: type, kind: 'var')
      number_of_vars += 1
    end

    compile_symbol(';')
    @output_file.puts '</varDec>'

    number_of_vars
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
    var_name = compile_var_name(let: true)

    if next_token?('[') # array
      compile_symbol('[')
      compile_expression
      compile_symbol(']')
      compile_symbol('=')

      case @symbol_table.kind_of(var_name)
      when 'static'
        @vm_writer.write_push('static', @symbol_table.index_of(var_name))
      when 'field'
        @vm_writer.write_push('this', @symbol_table.index_of(var_name))
      when 'arg'
        @vm_writer.write_push('argument', @symbol_table.index_of(var_name))
      when 'var'
        @vm_writer.write_push('local', @symbol_table.index_of(var_name))
      end

      @vm_writer.write_arithmetic('add')
      @vm_writer.write_pop('temp', 2)

      compile_expression

      @vm_writer.write_push('temp', 2)
      @vm_writer.write_pop('pointer', 1)
      @vm_writer.write_pop('that', 0)

      compile_symbol(';')
    else
      compile_symbol('=')
      compile_expression
      compile_symbol(';')

      case @symbol_table.kind_of(var_name)
      when 'static'
        @vm_writer.write_pop('static', @symbol_table.index_of(var_name))
      when 'field'
        @vm_writer.write_pop('this', @symbol_table.index_of(var_name))
      when 'arg'
        @vm_writer.write_pop('argument', @symbol_table.index_of(var_name))
      when 'var'
        @vm_writer.write_pop('local', @symbol_table.index_of(var_name))
      else
        raise "Invalid kind: #{@symbol_table.kind_of(var_name)}"
      end
    end

    @output_file.puts '</letStatement>'
  end

  def compile_if_statement
    @output_file.puts '<ifStatement>'
    compile_keyword('if')
    compile_symbol('(')
    compile_expression
    compile_symbol(')')
    label_1 = get_new_label
    label_2 = get_new_label
    @vm_writer.write_arithmetic('not')
    @vm_writer.write_if(label_1)
    compile_symbol('{')
    compile_statements
    compile_symbol('}')
    @vm_writer.write_goto(label_2)
    @vm_writer.write_label(label_1)
    if next_token?('else')
      compile_keyword('else')
      compile_symbol('{')
      compile_statements
      compile_symbol('}')
    end
    @vm_writer.write_label(label_2)
    @output_file.puts '</ifStatement>'
  end

  def compile_while_statement
    @output_file.puts '<whileStatement>'
    label_1 = get_new_label
    label_2 = get_new_label
    compile_keyword('while')
    @vm_writer.write_label(label_1)
    compile_symbol('(')
    compile_expression
    compile_symbol(')')
    @vm_writer.write_arithmetic('not')
    @vm_writer.write_if(label_2)
    compile_symbol('{')
    compile_statements
    compile_symbol('}')
    @vm_writer.write_goto(label_1)
    @vm_writer.write_label(label_2)
    @output_file.puts '</whileStatement>'
  end

  def compile_do_statement
    @output_file.puts '<doStatement>'
    compile_keyword('do')
    compile_subroutine_call
    compile_symbol(';')
    @output_file.puts '</doStatement>'
    @vm_writer.write_pop('temp', 0)
  end

  def compile_return_statement
    @output_file.puts '<returnStatement>'
    compile_keyword('return')
    if !next_token?(';')
      compile_expression
    else
      @vm_writer.write_push('constant', 0)
    end
    compile_symbol(';')
    @output_file.puts '</returnStatement>'

    @vm_writer.write_return
  end

  def compile_subroutine_call
    if next_token?('(', 1) # method call
      subroutine_name = compile_subroutine_name
      compile_symbol('(')
      @vm_writer.write_push('pointer', 0) # push this
      number_of_args = compile_expression_list
      compile_symbol(')')
      @vm_writer.write_call("#{@compiled_class_name}.#{subroutine_name}", number_of_args + 1)
    elsif @symbol_table.kind_of(@tokenizer.see_next_token) # instance_name.method_name
      instance_name = compile_class_name
      compile_symbol('.')
      subroutine_name = compile_subroutine_name
      compile_symbol('(')

      case @symbol_table.kind_of(instance_name)
      when 'static'
        @vm_writer.write_push('static', @symbol_table.index_of(instance_name))
      when 'field'
        @vm_writer.write_push('this', @symbol_table.index_of(instance_name))
      when 'arg'
        @vm_writer.write_push('argument', @symbol_table.index_of(instance_name))
      when 'var'
        @vm_writer.write_push('local', @symbol_table.index_of(instance_name))
      else
        raise "Invalid kind: #{@symbol_table.kind_of(instance_name)}"
      end

      number_of_args = compile_expression_list
      compile_symbol(')')

      @vm_writer.write_call("#{@symbol_table.type_of(instance_name)}.#{subroutine_name}", number_of_args + 1)
    else # class_name.method_name
      class_name = compile_class_name # compile class_name or var_name
      compile_symbol('.')
      subroutine_name = compile_subroutine_name
      compile_symbol('(')
      number_of_args = compile_expression_list
      compile_symbol(')')

      @vm_writer.write_call("#{class_name}.#{subroutine_name}", number_of_args)
    end
  end

  def compile_expression_list
    @output_file.puts '<expressionList>'
    number_of_args = 0
    unless next_token?(')')
      compile_expression
      number_of_args += 1
      while next_token?(',')
        compile_symbol(',')
        compile_expression
        number_of_args += 1
      end
    end

    @output_file.puts '</expressionList>'

    number_of_args
  end

  def compile_expression
    @output_file.puts '<expression>'
    compile_term
    while next_token?(OPERATORS)
      operator = compile_symbol(*OPERATORS)
      compile_term

      case operator
      when '+'
        @vm_writer.write_arithmetic('add')
      when '-'
        @vm_writer.write_arithmetic('sub')
      when '*'
        @vm_writer.write_call('Math.multiply', 2)
      when '/'
        @vm_writer.write_call('Math.divide', 2)
      when '&'
        @vm_writer.write_arithmetic('and')
      when '|'
        @vm_writer.write_arithmetic('or')
      when '>'
        @vm_writer.write_arithmetic('gt')
      when '<'
        @vm_writer.write_arithmetic('lt')
      when '='
        @vm_writer.write_arithmetic('eq')
      end
    end
    @output_file.puts '</expression>'
  end

  def compile_term
    @output_file.puts '<term>'
    case @tokenizer.see_next_token_type
    when 'INT_CONST'
      compile_integer_constant
      @vm_writer.write_push('constant', @tokenizer.int_val)
    when 'STRING_CONST'
      compile_string_constant
    when 'KEYWORD'
      case @tokenizer.see_next_token
      when 'null'
        compile_keyword('null')
        @vm_writer.write_push('constant', 0)
      when 'this'
        compile_keyword('this')
        @vm_writer.write_push('pointer', 0)
      when 'true'
        compile_keyword('true')
        @vm_writer.write_push('constant', 0)
        @vm_writer.write_arithmetic('not')
      when 'false'
        compile_keyword('false')
        @vm_writer.write_push('constant', 0)
      end
    when 'SYMBOL'
      if next_token?('(')
        compile_symbol('(')
        compile_expression
        compile_symbol(')')
      elsif next_token?(UNARY_OPERATORS.keys)
        symbol = compile_symbol(*UNARY_OPERATORS.keys)
        compile_term
        @vm_writer.write_arithmetic(UNARY_OPERATORS[symbol])
      else
        raise 'Invalid term'
      end
    when 'IDENTIFIER'
      # NOTE: identifierは先読みする
      if next_token?(['(', '.'], 1)
        compile_subroutine_call
      elsif next_token?('[', 1) # var_name[]
        compile_var_name
        compile_symbol('[')
        compile_expression

        @vm_writer.write_arithmetic('add')
        @vm_writer.write_pop('pointer', 1)
        @vm_writer.write_push('that', 0)

        compile_symbol(']')
      else
        compile_var_name # var_name
      end
    end
    @output_file.puts '</term>'
  end

  def compile_type
    if next_token?(%w(int char boolean))
      compile_keyword('int', 'char', 'boolean')
    elsif @tokenizer.see_next_token_type == 'IDENTIFIER'
      compile_class_name
    end
  end

  def compile_keyword(*tokens)
    @tokenizer.advance

    unless tokens.include?(@tokenizer.keyword)
      raise "Invalid keyword: \nparameter: #{tokens}\ntoken:#{@tokenizer.keyword}"
    end

    write_element('keyword', @tokenizer.keyword)

    @tokenizer.keyword
  end

  def compile_symbol(*tokens)
    @tokenizer.advance

    unless tokens.include?(@tokenizer.token)
      raise "Invalid symbol: \nparameter: #{tokens}\ntoken: #{@tokenizer.symbol}"
    end

    write_element('symbol', @tokenizer.escaped_symbol)

    @tokenizer.symbol
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

    @vm_writer.write_push('constant', @tokenizer.escaped_string_val.length)
    @vm_writer.write_call('String.new', 1)
    @tokenizer.escaped_string_val.each_char do |char|
      @vm_writer.write_push('constant', char.ord)
      @vm_writer.write_call('String.appendChar', 2)
    end
  end

  def compile_identifier
    @tokenizer.advance

    write_element('identifier', @tokenizer.identifier)

    @tokenizer.identifier
  end

  def compile_class_name
    write_identifier_info('category: class')
    compile_identifier
  end

  def compile_subroutine_name
    write_identifier_info('category: subroutine')
    compile_identifier
  end

  def compile_var_name(declaration: false, type: nil, kind: nil, let: false, call: false)
    if declaration # 変数の定義
      @symbol_table.define(name: @tokenizer.see_next_token, type: type,  kind: kind)
    elsif let || call
      # noop
    else # 変数の呼び出し
      kind = @symbol_table.kind_of(@tokenizer.see_next_token)
      case kind
      when 'static'
        @vm_writer.write_push('static', @symbol_table.index_of(@tokenizer.see_next_token))
      when 'field'
        @vm_writer.write_push('this', @symbol_table.index_of(@tokenizer.see_next_token))
      when 'arg'
        @vm_writer.write_push('argument', @symbol_table.index_of(@tokenizer.see_next_token))
      when 'var'
        @vm_writer.write_push('local', @symbol_table.index_of(@tokenizer.see_next_token))
      end
    end

    kind = @symbol_table.kind_of(@tokenizer.see_next_token)
    index = @symbol_table.index_of(@tokenizer.see_next_token)
    write_identifier_info("declaration: #{declaration}, kind: #{kind}, index: #{index}")
    compile_identifier
  end

  def write_identifier_info(value)
    write_element('IdentifierInfo', value)
  end

  def write_element(element, value)
    @output_file.puts("<#{element}> #{value} </#{element}>")
  end

  def next_token?(tokens, index = 0)
    [*tokens].include?(@tokenizer.see_next_token(index))
  end
end
