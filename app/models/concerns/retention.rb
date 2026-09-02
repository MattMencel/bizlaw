# frozen_string_literal: true

# Every table declares what kind of data it holds, so the purge can read the
# declaration rather than a maintained list. `:prose` is Student Prose,
# `:skeleton` is the graded shape of a run, `:authored` is the professor's work.
#
# A row is often prose and skeleton at once, so a declaration also names which
# of the table's columns are the prose — the earlier purge empties those where
# they sit and leaves the row behind as a tombstone.
#
# Reading a tier that was never declared raises. That is the whole mechanism:
# a prose-bearing table added without a declaration breaks rather than quietly
# retaining student writing forever.
module Retention
  extend ActiveSupport::Concern

  TIERS = %i[prose skeleton authored].freeze

  UndeclaredTier = Class.new(StandardError)

  class_methods do
    def retention(tier, prose: [])
      raise ArgumentError, "unknown Retention tier #{tier.inspect}" unless TIERS.include?(tier)

      @retention_tier = tier
      @prose_columns = prose.map(&:to_s).freeze
    end

    def retention_tier
      @retention_tier || raise(UndeclaredTier, "#{name} declares no Retention tier")
    end

    def prose_columns
      retention_tier
      @prose_columns
    end
  end
end
