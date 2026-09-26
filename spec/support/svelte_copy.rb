# frozen_string_literal: true

# Finds the words in a `.svelte` file that a reader could see.
#
# A component arranges copy and never holds it, so this reads a component the
# way a reader meets it: text between tags, the four attributes a screen reader
# or a browser shows (`aria-label`, `placeholder`, `title`, `alt`), and string
# literals in expressions and scripts. Punctuation and glyphs stay in
# components, so only text with a letter in it counts.
#
# A literal outside those four attributes counts only when it reads like
# words — it has a space, or opens on a capital — because a component is full
# of identifiers that are strings (`"back"`, `"term-sheet"`, `"@inertiajs/svelte"`)
# and none of them is copy. A lowercase single word in a script slips past; that
# is the price of not flagging every element id.
#
# It is a scanner, not a parser. It knows enough Svelte and JavaScript to skip
# comments, styles, quoted attribute values and regular expressions, and no
# more.
class SvelteCopy
  CHECKED_ATTRIBUTES = %w[aria-label placeholder title alt].freeze

  LETTER = /\p{L}/

  def self.words_in(source) = new(source).words

  def initialize(source)
    @source = source
  end

  def words
    @words = []
    markup = @source.gsub(/<!--.*?-->/m, "").gsub(%r{<style[\s>].*?</style>}m, "")
    markup = markup.gsub(%r{<script[\s>].*?</script>}m) do |block|
      literals(block.sub(/\A<script[^>]*>/, "").delete_suffix("</script>"), :wordy)
      ""
    end
    scan_markup(markup)
    @words
  end

  private

  def found(text) = @words << text.gsub(/\s+/, " ").strip

  def wordy?(text) = text.match?(LETTER) && (text.match?(/\s/) || text.match?(/\A\p{Lu}/))

  def scan_markup(markup)
    text = +""
    i = 0
    while i < markup.length
      case markup[i]
      when "{"
        close = matching(markup, i)
        expression = markup[(i + 1)...close]
        literals(expression, :wordy) unless expression.start_with?("@html")
        i = close + 1
      when "<"
        found(text) if text.match?(LETTER)
        text = +""
        i = scan_tag(markup, i)
      else
        text << markup[i]
        i += 1
      end
    end
    found(text) if text.match?(LETTER)
  end

  # A tag and its attributes, returning the index past its `>`.
  def scan_tag(markup, start)
    i = start + 1
    while i < markup.length && markup[i] != ">"
      if markup[i].match?(/\s/) || markup[i] == "/"
        i += 1
      elsif markup[i] == "{"
        close = matching(markup, i)
        literals(markup[(i + 1)...close], :wordy)
        i = close + 1
      else
        name_end = i
        name_end += 1 while name_end < markup.length && !markup[name_end].match?(%r{[\s=>/]})
        name = markup[i...name_end]
        i = name_end
        next unless markup[i] == "="

        i += 1
        i = attribute_value(markup, i, CHECKED_ATTRIBUTES.include?(name))
      end
    end
    i + 1
  end

  def attribute_value(markup, i, checked)
    quote = markup[i]
    if quote == "{"
      close = matching(markup, i)
      literals(markup[(i + 1)...close], checked ? :any : :wordy)
      return close + 1
    end

    return attribute_value_bare(markup, i, checked) unless ['"', "'"].include?(quote)

    close = markup.index(quote, i + 1)
    value = markup[(i + 1)...close]
    value.split(/(\{[^}]*\})/).each do |part|
      if part.start_with?("{")
        literals(part[1..-2], checked ? :any : :wordy)
      elsif checked && part.match?(LETTER)
        found(part)
      end
    end
    close + 1
  end

  def attribute_value_bare(markup, i, checked)
    close = i
    close += 1 while close < markup.length && !markup[close].match?(/[\s>]/)
    found(markup[i...close]) if checked && markup[i...close].match?(LETTER)
    close
  end

  # The index of the `}` closing the `{` at `open`, stepping over strings.
  def matching(text, open)
    depth = 0
    i = open
    while i < text.length
      case text[i]
      when '"', "'", "`" then i = skip_string(text, i)
      when "{" then depth += 1
      when "}"
        depth -= 1
        return i if depth.zero?
      end
      i += 1
    end
    raise ArgumentError, "unclosed { at #{open}"
  end

  def skip_string(text, open)
    quote = text[open]
    i = open + 1
    i += (text[i] == "\\") ? 2 : 1 while i < text.length && text[i] != quote
    i
  end

  # Every string literal in a piece of JavaScript, and the static parts of every
  # template literal. `:any` counts any letter; `:wordy` only words.
  def literals(js, mode)
    i = 0
    previous = nil
    while i < js.length
      char = js[i]
      if js[i, 2] == "//"
        i = js.index("\n", i) || js.length
      elsif js[i, 2] == "/*"
        i = (js.index("*/", i + 2) || js.length) + 2
      elsif char == "/" && (previous.nil? || "(,=:[!&|?{};".include?(previous))
        i = skip_regex(js, i)
        previous = "/"
      elsif ['"', "'"].include?(char)
        close = skip_string(js, i)
        literal(js[(i + 1)...close], mode)
        i = close + 1
        previous = char
      elsif char == "`"
        i = template(js, i, mode)
        previous = char
      else
        previous = char unless char.match?(/\s/)
        i += 1
      end
    end
  end

  def template(js, open, mode)
    i = open + 1
    static = +""
    while i < js.length && js[i] != "`"
      if js[i, 2] == "${"
        close = matching(js, i + 1)
        literals(js[(i + 2)...close], mode)
        i = close + 1
      else
        static << js[i]
        i += 1
      end
    end
    literal(static, mode)
    i + 1
  end

  def skip_regex(js, open)
    i = open + 1
    in_class = false
    while i < js.length
      case js[i]
      when "\\" then i += 1
      when "[" then in_class = true
      when "]" then in_class = false
      when "/" then break unless in_class
      end
      i += 1
    end
    i + 1
  end

  def literal(text, mode)
    counts = (mode == :any) ? text.match?(LETTER) : wordy?(text)
    found(text) if counts
  end
end
