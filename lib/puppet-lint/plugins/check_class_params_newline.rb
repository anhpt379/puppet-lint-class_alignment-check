def prev_param_token(token)
  while token&.prev_code_token
    token = token.prev_code_token
    break if a_param?(token)
  end
  token
end

PuppetLint.new_check(:class_params_newline) do
  def check
    (class_indexes + defined_type_indexes).each do |item|
      tokens = item[:param_tokens]

      first_param = tokens.index { |token| a_param?(token) }
      last_param = tokens.rindex { |token| a_param?(token) }
      next if first_param.nil?
      next if last_param.nil?

      # Skip if there's only 1 param
      next if tokens[first_param] == tokens[last_param]

      tokens.each do |token|
        next unless a_param?(token)

        if token.prev_code_token == :LPAREN
          next if token.line != token.prev_code_token.line
        elsif token.line != prev_param_token(token).line
          next
        end

        notify(
          :warning,
          message: "Parameter #{token.to_manifest} should have its own line (expected in line #{token.line + 1}, but found it in line #{token.line})",
          line: token.line,
          column: token.column,
          token: token,
          newline: true,
          newline_indent: item[:tokens][0].column + 1
        )
      end
    end
  end

  def fix(problem)
    token = problem[:token]
    case token&.prev_code_token&.type
    when :TYPE
      token = token.prev_code_token
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
      token = token.prev_code_token
    end

    index = tokens.index(token.prev_code_token.next_token)
    tokens.insert(index, PuppetLint::Lexer::Token.new(:NEWLINE, "\n", 0, 0))

    token.prev_token.value = ' ' * problem[:newline_indent] if %i[WHITESPACE INDENT].include?(token.prev_token.type)
  end
end
