class Parser
  attr_reader :current_command

  COMMAND_TYPE = {
    'push' => 'C_PUSH',
    'pop' => 'C_POP',
    'label' => 'C_LABEL',
    'goto' => 'C_GOTO',
    'if-goto' => 'C_IF',
    'function' => 'C_FUNCTION',
    'return' => 'C_RETURN',
    'call' => 'C_CALL'
  }.freeze

  def initialize(file)
    @file = File.open(file)
    @current_command = nil
  end

  def has_more_commands?
    !@file.eof
  end

  def advance
    @current_command = nil
    @argument1 = nil
    @argument2 = nil
    @command_type = nil

    @current_command = @file.readline.gsub(%r|\s*//.+|, '').strip.chomp

    return if @current_command.empty?

    @current_command, @argument1, @argument2 = @current_command.split(' ')
  end

  def command_type
    @command_type ||= (COMMAND_TYPE[@current_command] || 'C_ARITHMETIC')
  end

  def arg1
    return if command_type == 'C_RETURN'

    if command_type == 'C_ARITHMETIC'
      @current_command
    else
      @argument1
    end
  end

  def arg2
    return unless %w(C_PUSH C_POP C_FUNCTION C_CALL).include?(command_type)

    @argument2
  end

  def close
    @file.close
  end
end
