# frozen_string_literal: true

module Portraits
  # Who the Client is, drawn from the seed: one part per identity group, fixed
  # for the whole of a Simulation and for every Case ever run off that Version.
  #
  # **Each group draws from its own salted hash.** Slicing one hash word with
  # shifts is the obvious implementation and is wrong — the prototype did it and
  # across six seeds drew the same hair three times and never once drew glasses
  # or facial hair, because the shifted bits of one FNV word stay correlated. A
  # group is an independent draw, so it gets an independent hash.
  #
  # Two identities are equal when they compose the same person. That is what
  # `Cases::Import` compares, and it is the only collision anyone can ever see:
  # Teams in different Simulations never meet, and a Team sees only its own
  # Client.
  class Identity
    # How much of the digest a draw reads. Four bytes is far more entropy than
    # any group has parts, and it keeps the draw a small integer.
    WORD = 8

    def self.for(seed, part_set: PartSet.default)
      new(part_set.identity_groups.keys.to_h do |group|
        names = part_set.parts(group)
        [group, names.fetch(draw(group, seed) % names.size)]
      end)
    end

    # The salt is the group's own name, so adding a group to a set never moves
    # the parts the other groups had already drawn.
    #
    # SHA-256 rather than the prototype's FNV-1a, and not for strength. A draw
    # is a **modulus** of this number, so what matters is the low bits, and
    # FNV-1a's low bits barely avalanche: bit 0 of the result is the parity of
    # bit 0 of every byte it ate, so two groups reading the same seed differ
    # there only by the parity of their own names. Salting the input is not
    # enough when the output is then taken modulo a small number — measured
    # across a 600-seed roster, salted FNV drew only 8 of the 32 hair-and-garment
    # pairs the set can make. SHA-256 draws all 32.
    #
    # It is also stable across Ruby versions, which `#hash` is not: a portrait
    # that reseated itself on an upgrade would change a Client's face
    # mid-Simulation.
    def self.draw(group, seed)
      Digest::SHA256.hexdigest("#{group}\0#{seed}")[0, WORD].to_i(16)
    end

    def initialize(parts)
      @parts = parts.freeze
    end

    attr_reader :parts

    def part(group) = parts.fetch(group)

    def ==(other) = other.is_a?(self.class) && parts == other.parts

    alias_method :eql?, :==

    def hash = parts.hash

    # What two Clients composing to the same person have in common, in words, so
    # a refusal at import can say which groups collided rather than only that
    # they did.
    def to_s = parts.map { |group, name| "#{group} #{name}" }.join(", ")
  end
end
