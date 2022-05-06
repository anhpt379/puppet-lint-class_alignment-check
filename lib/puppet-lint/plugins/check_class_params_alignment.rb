# Parameters to classes or defined types must be uniformly indented in two
# spaces from the title. The equals sign should be aligned.
#
# https://puppet.com/docs/puppet/7/style_guide.html#style_guide_classes-param-indentation-alignment

require 'debug'

def a_param?(token)
  if token.prev_code_token.type == :EQUALS
    false
  elsif token.prev_code_token.type == :FARROW
    false
  elsif token.type == :VARIABLE and not [:DQPRE, :DQMID].include?(token.prev_code_token.type)
    true
  end
end

def first_param_on_the_line?(token)
  origin = token
  while token and token.prev_token
    token = token.prev_token

    break if token.type == :NEWLINE
  end

  while token and token.next_token
    token = token.next_token

    if token.type == :VARIABLE
      break
    end
  end

  if origin == token
    true
  else
    false
  end
end

def the_one?(token, character)
  if character == '='
    true if token.type == :EQUALS
  elsif character == '$'
    true if token.type == :VARIABLE and a_param?(token) and first_param_on_the_line?(token)
  end
end

def get_prev_code_token(token, character)
  if character == '='
    token.prev_code_token
  elsif character == '$'
    if token.prev_code_token
      if [:CLASSREF, :RBRACK].include?(token.prev_code_token.type)
        token.prev_code_token
      elsif token.prev_code_token.type == :LPAREN
        token
      elsif token.prev_code_token.type == :COMMA
        origin = token
        while token.prev_code_token
          token = token.prev_code_token
          return token if token.prev_code_token.type == :LPAREN
        end
        origin
      end
    end
  end
end

# This function is copied & modified from puppet-lint arrow_alignment check
# https://github.com/puppetlabs/puppet-lint/blob/020143b705b023946739eb44e7c7d99fcd087527/lib/puppet-lint/plugins/check_whitespace/arrow_alignment.rb#L8
def _check(character)
  # I intentionally didn't rename `arrow` to another name, to keep the code as
  # similar as the original one, to easier to update in the future.
  (class_indexes + defined_type_indexes).each do |res_idx|
    arrow_column = [0]
    level_idx = 0
    level_tokens = []
    param_column = [nil]
    resource_tokens = res_idx[:param_tokens]
    next if resource_tokens.nil?

    resource_tokens.reject! do |token|
      COMMENT_TYPES.include?(token.type)
    end

    # If this is a single line resource, skip it
    first_arrow = resource_tokens.index { |r| the_one?(r, character) }
    last_arrow = resource_tokens.rindex { |r| the_one?(r, character) }
    next if first_arrow.nil?
    next if last_arrow.nil?
    next if resource_tokens[first_arrow].line == resource_tokens[last_arrow].line

    resource_tokens.each do |token|
      if the_one?(token, character)
        param_token = get_prev_code_token(token, character)

        param_length = param_token.to_manifest.length

        if param_column[level_idx].nil?
          param_column[level_idx] = param_token.column
        end

        if (level_tokens[level_idx] ||= []).any? { |t| t.line == token.line }
          this_arrow_column = param_column[level_idx] + param_length + 1
        else
          if character == '$' and param_token.type == :VARIABLE
            this_arrow_column = param_token.column
          else
            this_arrow_column = param_token.column + param_token.to_manifest.length
            if param_token.type != :INDENT
              this_arrow_column += 1
            end
          end
        end

        if arrow_column[level_idx] < this_arrow_column
          arrow_column[level_idx] = this_arrow_column
        end

        (level_tokens[level_idx] ||= []) << token
      elsif token.prev_token.type == :LPAREN
        level_idx += 1
        arrow_column << 0
        level_tokens[level_idx] ||= []
        param_column << nil
      elsif token.next_token.type == :RPAREN
        if (level_tokens[level_idx] ||= []).map(&:line).uniq.length > 1
          level_tokens[level_idx].each do |arrow_tok|
            next if arrow_tok.column == arrow_column[level_idx] || level_tokens[level_idx].size == 1

            arrows_on_line = level_tokens[level_idx].select { |t| t.line == arrow_tok.line }
            notify(
              :warning,
              :message        => "indentation of #{character} is not properly aligned (expected in column #{arrow_column[level_idx]}, but found it in column #{arrow_tok.column})",
              :line           => arrow_tok.line,
              :column         => arrow_tok.column,
              :token          => arrow_tok,
              :arrow_column   => arrow_column[level_idx],
              :newline        => arrows_on_line.index(arrow_tok) != 0,
              :newline_indent => param_column[level_idx] - 1
            )
          end
        end
        arrow_column[level_idx] = 0
        level_tokens[level_idx].clear
        param_column[level_idx] = nil
        level_idx -= 1
      end
    end
  end
end

# This function is copied & modified from puppet-lint arrow_alignment fix
# https://github.com/puppetlabs/puppet-lint/blob/020143b705b023946739eb44e7c7d99fcd087527/lib/puppet-lint/plugins/check_whitespace/arrow_alignment.rb#L94
def _fix(problem)
  if problem[:newline]
    index = tokens.index(problem[:token].prev_code_token.prev_token)

    # insert newline
    tokens.insert(index, PuppetLint::Lexer::Token.new(:NEWLINE, "\n", 0, 0))

    # indent the parameter to the correct depth
    problem[:token].prev_code_token.prev_token.type = :INDENT
    problem[:token].prev_code_token.prev_token.value = ' ' * problem[:newline_indent]

    end_param_idx = tokens.index(problem[:token].prev_code_token)
    start_param_idx = tokens.index(problem[:token].prev_token_of([:INDENT, :NEWLINE]))
    param_length = tokens[start_param_idx..end_param_idx].map { |r| r.to_manifest.length }.reduce(0) { |sum, x| sum + x } + 1
    new_ws_len = problem[:arrow_column] - param_length
  else
    new_ws_len = if problem[:token].prev_token.type == :WHITESPACE
                    problem[:token].prev_token.to_manifest.length
                  else
                    0
                  end
    new_ws_len += (problem[:arrow_column] - problem[:token].column)
  end

  if new_ws_len < 0
    if problem[:token].prev_token.type == :INDENT
      new_ws = problem[:token].prev_token.to_manifest[0...new_ws_len]
      problem[:token].prev_token.value = new_ws
    else
      raise PuppetLint::NoFix
    end
  else
    new_ws = ' ' * new_ws_len

    if problem[:token].prev_token.type == :WHITESPACE
      problem[:token].prev_token.value = new_ws
    else
      index = tokens.index(problem[:token].prev_token)
      tokens.insert(index + 1, PuppetLint::Lexer::Token.new(:WHITESPACE, new_ws, 0, 0))
    end
  end
end

PuppetLint.new_check(:class_params_alignment) do
  def check
    _check('$')
  end

  def fix(problem)
    _fix(problem)
  end
end

PuppetLint.new_check(:class_equals_alignment) do
  def check
    _check('=')
  end

  def fix(problem)
    _fix(problem)
  end
end
