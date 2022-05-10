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
    '&amp;',
    '|',
    '&lt;',
    '&gt;',
    '=',
    '~'
  ].freeze

  ESCAPED_SYMBOLS = {
    '<' => '&lt;',
    '>' => '&gt;',
    '&' => '&amp;',
  }

  def initialize(file)
    @file = file
    @token = nil
    @tokens = []
    @token_type = nil
    @commented = false
    @row = nil
  end

  def has_more_tokens?
    !@file.eof || !@tokens.empty?
  end

  def advance
    @token = nil
    @token_type = nil

    if @tokens.empty?
      @row = @file.readline.gsub(%r|\s*//.+|, '').strip.chomp # 空行とコメントを除去
      @tokens = @row.split(/\s+/). # 空白削除
        flat_map {|str| str.split(%r|([();.,~\[\]\+\-])|)}. # シンボルを分離
        reject(&:empty?)
    end

    @commented = true if @row.start_with?('/**')
    @tokens = [] if @commented
    @commented = false if @row.end_with?('*/')

    token = @tokens.shift

    return if token.nil?

    @token = if token.start_with?('"') # 空白で区切られた文字列を結合
      str = token
      while !str.end_with?('"') do
        next_token = @tokens.shift
        str += " #{next_token}"
      end
      str
    elsif ESCAPED_SYMBOLS.keys.include?(token)
      ESCAPED_SYMBOLS[token]
    else
      token
    end
  end

  def token_type
    @token_type =
      if KEYWORDS.keys.include?(@token)
        'KEYWORD'
      elsif SYMBOLS.include?(@token)
        'SYMBOL'
      elsif @token =~ /^[0-9]+$/
        'INT_CONST'
      elsif @token =~ /^".*"$/
        'STRING_CONST'
      else
        'IDENTIFIER'
      end
  end

  def tag
    TOKEN_TYPES[token_type]
  end

  def keyword
    raise 'Token type must be KEYWORD' unless @token_type == 'KEYWORD'

    @token
  end

  def symbol
    raise 'Token type must be SYMBOL' unless @token_type == 'SYMBOL'

    @token
  end

  def identifier
    raise 'Token type must be IDENTIFIER' unless @token_type == 'IDENTIFIER'

    @token
  end

  def int_val
    raise 'Token type must be INT_CONST' unless @token_type == 'INT_CONST'

    @token
  end

  def string_val
    raise 'Token type must be STRING_CONST' unless @token_type == 'STRING_CONST'

    @token
  end
end
