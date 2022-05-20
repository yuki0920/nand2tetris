class JackTokenizer
  TOKEN_TYPES = {
    'KEYWORD' => 'keyword',
    'SYMBOL' => 'symbol',
    'IDENTIFIER' => 'identifier',
    'INT_CONST' => 'integerConstant',
    'STRING_CONST' => 'stringConstant'
  }.freeze

  KEYWORDS = {
    'class' => 'CLASS',
    'method' => 'METHOD',
    'function' => 'FUNCTION',
    'constructor' => 'CONSTRUCTOR',
    'int' => 'INT',
    'boolean' => 'BOOLEAN',
    'char' => 'CHAR',
    'void' => 'VOID',
    'var' => 'VAR',
    'static' => 'STATIC',
    'field' => 'FIELD',
    'let' => 'LET',
    'do' => 'DO',
    'if' => 'IF',
    'else' => 'ELSE',
    'while' => 'WHILE',
    'return' => 'RETURN',
    'true' => 'TRUE',
    'false' => 'FALSE',
    'null' => 'NULL',
    'this' => 'THIS'
  }.freeze

  SYMBOLS = [
    '{',
    '}',
    '(',
    ')',
    '[',
    ']',
    '.',
    ',',
    ';',
    '+',
    '-',
    '*',
    '/',
    '&',
    '|',
    '<',
    '>',
    '=',
    '~',
    '<',
    '>',
    '&'
  ].freeze

  ESCAPED_SYMBOLS = {
    '<' => '&lt;',
    '>' => '&gt;',
    '&' => '&amp;'
  }

  attr_reader :token, :remained_tokens

  def initialize(file)
    @file = file
    @token = nil
    @tokens = []
    @token_type = nil
    @commented = false
    @row = nil
    @remained_tokens = []
  end

  def execute(output_file)
    output_file.puts('<tokens>')
    _execute(output_file)
    output_file.puts('</tokens>')
  end

  def _execute(output_file)
    return if read_finished?

    @token = next_token

    unless @token.nil?
      @remained_tokens << @token
      output_file.puts("<#{tag}> #{excaped_token} </#{tag}>")
    end

    _execute(output_file)
  end

  def has_more_tokens?
    !@remained_tokens.empty?
  end

  def advance
    @token = @remained_tokens.shift
  end

  def see_next_token(index = 0)
    @remained_tokens[index]
  end

  def see_next_token_type(index = 0)
    token_type(see_next_token(index))
  end

  def token_type(token = @token)
    if KEYWORDS.keys.include?(token)
      'KEYWORD'
    elsif SYMBOLS.include?(token)
      'SYMBOL'
    elsif token =~ /^[0-9]+$/
      'INT_CONST'
    elsif token =~ /^".*"$/
      'STRING_CONST'
    else
      'IDENTIFIER'
    end
  end

  def tag
    TOKEN_TYPES[token_type]
  end

  def excaped_token
    case token_type
    when 'STRING_CONST'
      escaped_string_val
    when 'SYMBOL'
      escaped_symbol
    else
      @token
    end
  end

  def keyword
    raise "Token: #{@token}, type must be KEYWORD" unless token_type == 'KEYWORD'

    @token
  end

  def symbol
    raise "Token: #{@token}, type must be SYMBOL" unless token_type == 'SYMBOL'

    @token
  end

  def escaped_symbol
    ESCAPED_SYMBOLS[symbol] || symbol
  end

  def identifier
    raise "Token: #{@token}, type must be IDENTIFIER" unless token_type == 'IDENTIFIER'

    @token
  end

  def int_val
    raise "Token: #{@token}, type must be INT_CONST" unless token_type == 'INT_CONST'

    @token
  end

  def string_val
    raise "Token: #{@token}, type must be STRING_CONST" unless token_type == 'STRING_CONST'

    @token
  end

  def escaped_string_val
    string_val.gsub(/"/, '')
  end

  private

  def read_finished?
    @file.eof
  end

  def next_token
    @token = nil
    @token_type = nil

    if @tokens.empty?
      @row = @file.readline.gsub(%r|\s*//.+|, '').strip.chomp # 空行とコメントを除去
      @tokens = @row.split(/\s+/) # 空白削除
        .flat_map {|str| str.split(/([();.,~\[\]+\-])/) } # シンボルを分離
        .reject(&:empty?)
    end

    @commented = true if @row.start_with?('/**')
    @tokens = [] if @commented
    @commented = false if @row.end_with?('*/')

    token = @tokens.shift

    if token.nil?
      @token = nil
      return
    end
    # TODO: "Test 1: expected result: 5; actual result: "を出力するようにする
    # ;が悪さしている?
    @token = if token.start_with?('"') # 空白で区切られた文字列を結合
               str = token
               until str.end_with?('"')
                 next_token = @tokens.shift
                 next_str = next_token == ';' ? next_token : " #{next_token}"
                 str += next_str
               end
               str
             else
               token
             end
  end
end
