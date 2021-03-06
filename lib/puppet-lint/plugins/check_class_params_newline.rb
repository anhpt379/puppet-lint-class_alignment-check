PuppetLint.new_check(:class_params_newline) do
  def check
    (class_indexes + defined_type_indexes).each do |item|
      tokens = item[:param_tokens]
      next if tokens.nil?

      # Skip if line length < 80 chars
      first_paren = tokens[0]&.prev_token_of(:LPAREN)
      last_paren = tokens[-1]&.next_token_of(:RPAREN)
      next if first_paren.nil?
      next if last_paren.nil?
      next if first_paren.line == last_paren.line && last_paren.column < 80

      tokens.each do |token|
        if token == tokens[-1]
          rparen = token.next_token_of(:RPAREN)

          last_code_token = token
          while last_code_token&.prev_token
            break unless %i[WHITESPACE INDENT NEWLINE].include?(last_code_token.type)

            last_code_token = last_code_token.prev_token
          end

          next if rparen.line != last_code_token.line

          notify(
            :warning,
            message: "`)` should be in a new line (expected in line #{token.line + 1}, but found it in line #{token.line})",
            line: rparen.line,
            column: rparen.column,
            token: rparen,
            newline: true,
            newline_indent: item[:tokens][0].column - 1
          )
        end

        next unless a_param?(token)

        if get_param_start_token(token)&.prev_code_token.type == :LPAREN
          next if token.line != get_param_start_token(token).prev_code_token.line
        elsif token.line != get_prev_param_token(token)&.line
          next
        end

        notify(
          :warning,
          message: "`#{token.to_manifest}` should be in a new line (expected in line #{token.line + 1}, but found it in line #{token.line})",
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
    token = get_param_start_token(token) if token.type == :VARIABLE

    last_non_whitespace_token = token.prev_token
    while last_non_whitespace_token&.prev_token
      break unless %i[WHITESPACE INDENT NEWLINE].include?(last_non_whitespace_token.type)

      last_non_whitespace_token = last_non_whitespace_token.prev_token
    end

    index = tokens.index(last_non_whitespace_token) + 1
    tokens.insert(index, PuppetLint::Lexer::Token.new(:NEWLINE, "\n", 0, 0))

    # When there's no space at the beginning of the param
    # e.g.  class foo($bar="aaa") {}
    if token.prev_code_token.next_token == token
      tokens.insert(index + 1, PuppetLint::Lexer::Token.new(:INDENT, ' ' * problem[:newline_indent], 0, 0))

    elsif %i[WHITESPACE INDENT].include?(token.prev_token.type)
      token.prev_token.value = ' ' * problem[:newline_indent]
    end
  end
end
