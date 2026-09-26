# frozen_string_literal: true

require "ripper"

# The Symbol literals in refusal position in one parsed file.
class RefusalSymbols
  REFUSING_CALLS = %w[refusal refuse].freeze

  attr_reader :symbols

  def initialize(tree)
    @symbols = []
    walk(tree)
    @symbols.uniq!
  end

  private

  def walk(node)
    return unless node.is_a?(Array)

    case node.first
    when :def then refusing_method(node) if name_of(node[1]).to_s.include?("refus")
    when :method_add_arg, :command then refusing_call(node)
    end

    node.each { |child| walk(child) }
  end

  def refusing_method(node)
    body = node.last
    returns(body)
    statements = (body.first == :bodystmt) ? body[1] : [body]
    literal(statements.last)
  end

  def returns(node)
    return unless node.is_a?(Array)
    return node[1..].each { |argument| each_literal(argument) } if node.first == :return

    node.each { |child| returns(child) }
  end

  def refusing_call(node)
    callee = (node.first == :command) ? node[1] : node[1][1]
    return unless REFUSING_CALLS.include?(callee.is_a?(Array) ? callee[1] : nil)

    arguments = (node.first == :command) ? node[2] : node[2][1]
    Array(arguments && arguments[1]).each { |argument| literal(argument) }
  end

  def each_literal(node)
    return unless node.is_a?(Array)

    literal(node)
    node.each { |child| each_literal(child) }
  end

  def literal(node)
    return unless node.is_a?(Array) && node.first == :symbol_literal

    @symbols << node.dig(1, 1, 1).to_sym
  end

  def name_of(node) = node.is_a?(Array) ? node[1] : node
end
