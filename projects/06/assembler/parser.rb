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
    @command = @file.readline.gsub(%r|\s*//.+|, '').strip.chomp

    return if @command.empty?

    set_command_type
  end

  def symbol
    case @command_type
    when 'A_COMMAND'
      @command[1..]
    when 'L_COMMAND'
      @command[1..-2]
    else
      raise 'Not A_COMMAND or L_COMMAND'
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
      raise 'Not C_COMMAND'
    end
  end

  private

  def set_command_type
    @command_type =
      if @command[0] == '@'
        'A_COMMAND'
      elsif @command.include?('=') || @command.include?(';')
        'C_COMMAND'
      else
        'L_COMMAND'
      end
  end
end
