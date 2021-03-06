def a_param?(token)
  if token&.prev_code_token&.type == :EQUALS
    false
  elsif token&.prev_code_token&.type == :FARROW
    false
  elsif %i[DQPRE DQMID].include?(token&.prev_code_token&.type)
    false
  elsif token&.type == :VARIABLE
    # first var in the class
    return true if token&.prev_token_of(:CLASS)&.next_token_of(:LPAREN)&.next_token_of(:VARIABLE) == token
    return true if token&.prev_token_of(:DEFINE)&.next_token_of(:LPAREN)&.next_token_of(:VARIABLE) == token

    count = 0
    saw_a_comma = false
    while token&.prev_token
      token = token.prev_token

      saw_a_comma = true if token.type == :COMMA

      return false if token.type == :EQUALS && count == 0 && saw_a_comma == false

      if %i[RPAREN RBRACK RBRACE].include?(token.type)
        count -= 1
      elsif %i[LPAREN LBRACK LBRACE].include?(token.type)
        count += 1
      end

      break if %i[CLASS DEFINE].include?(token.type)
    end

    true if count == 1
  end
end

def first_on_the_line?(token, type)
  origin = token
  while token&.prev_token
    token = token.prev_token

    break if token.type == :NEWLINE
  end

  while token&.next_token
    token = token.next_token

    break if token.type == type
  end

  origin == token
end

def the_one?(token, character)
  case character
  when '='
    true if token.type == :EQUALS && first_on_the_line?(token, :EQUALS)
  when '$'
    true if a_param?(token) && first_on_the_line?(token, :VARIABLE)
  end
end

def get_the_first_param(token)
  while token&.prev_code_token
    token = token.prev_code_token
    break if token.type == :CLASS
  end

  while token&.next_code_token
    token = token.next_code_token
    return token if token.type == :VARIABLE
  end
end

def get_prev_code_token(token, character)
  case character
  when '='
    token.prev_code_token
  when '$'
    if token.prev_code_token
      if %i[CLASSREF RBRACK].include?(token.prev_code_token.type)
        token.prev_code_token
      elsif token.prev_code_token.type == :LPAREN
        token
      elsif token.prev_code_token.type == :COMMA
        get_the_first_param(token)
      end
    end
  end
end

def get_param_start_token(token)
  return nil unless a_param?(token)

  case token&.prev_code_token&.type

  # Integer $db_port
  when :TYPE
    token.prev_code_token

  when :CLASSREF
    token.prev_code_token

  # Variant[Undef, Enum['UNSET'], Stdlib::Port] $db_port
  when :RBRACK
    count = 0
    while token&.prev_code_token
      token = token.prev_code_token
      case token.type
      when :RBRACK
        count += 1
      when :LBRACK
        count -= 1
      end

      break if count.zero?
    end
    token.prev_code_token

  else
    token
  end
end

def get_prev_param_token(token)
  while token&.prev_code_token
    token = token.prev_code_token
    return token if a_param?(token)
  end
end
