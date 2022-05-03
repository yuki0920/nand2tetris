class Parser
  attr_reader :command, :command_type, :dest, :comp, :jump

  def initialize(file)
    @file = file
    @command = nil
  end

  def has_more_commands?
    !@file.eof?
  end

  def advance
    @command = @file.readline.gsub(%r|\s*//.+|, '').chomp

    return if @command.empty?

    extract_command_type
  end

  def symbol
    if @command_type == 'A_COMMAND'
      @command[1..-1]
    elsif @command_type == 'L_COMMAND'
      @command[1..-2]
    else
      raise
    end
  end

  def extract_controle_bit
    @dest = nil
    @comp = nil
    @jump = nil

    if @command.include?('=')
      @dest, @comp = @command.split('=')
    elsif @command.include?(';')
      @comp, @jump = @command.split(';')
    else
      raise
    end
  end

  private

  def extract_command_type
    @command_type = if @command[0] == '@'
      'A_COMMAND'
    elsif @command.include?('=') || @command.include?(';')
      'C_COMMAND'
    else
      'L_COMMAND'
    end
  end
end
