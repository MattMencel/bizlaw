# frozen_string_literal: true

require "rails_helper"
require "sqlite3"
require "tmpdir"

# ADR 0002 makes `day_budgets.spent` the schema's one materialized value and
# maintains it with an AFTER INSERT trigger on `docket_entries`. Triggers do not
# survive a `schema.rb` dump, which is the whole reason the repo tracks
# `structure.sql`.
#
# This spec proves the format actually holds a trigger, rather than asserting
# that a setting is set. It builds a throwaway SQLite database, puts a trigger in
# it, dumps and reloads it through the same `ActiveRecord::Tasks` path
# `db:schema:dump` and `db:schema:load` use, and then checks the trigger still
# fires. It leaves no migration and no table behind, and never touches the
# application's own connection.
RSpec.describe "structure.sql schema format" do
  it "is configured as :sql" do
    expect(Rails.application.config.active_record.schema_format).to eq(:sql)
  end

  describe "a round trip through structure.sql" do
    around do |example|
      Dir.mktmpdir("schema-format") do |dir|
        @dir = dir
        example.run
      end
    end

    let(:database) { File.join(@dir, "round_trip.sqlite3") }
    let(:structure) { File.join(@dir, "structure.sql") }

    # The same task object `db:schema:dump` and `db:schema:load` run under.
    let(:tasks) do
      ActiveRecord::Tasks::SQLiteDatabaseTasks.new(
        ActiveRecord::DatabaseConfigurations::HashConfig.new(
          "test", "round_trip", {adapter: "sqlite3", database: database}
        ),
        @dir
      )
    end

    it "carries an AFTER INSERT trigger through dump and load, still firing" do
      SQLite3::Database.new(database) do |db|
        db.execute_batch(<<~SQL)
          CREATE TABLE counters (name TEXT PRIMARY KEY, total INTEGER NOT NULL DEFAULT 0);
          CREATE TABLE entries (id INTEGER PRIMARY KEY, amount INTEGER NOT NULL);
          CREATE TRIGGER entries_refold_total AFTER INSERT ON entries
          BEGIN
            INSERT INTO counters (name, total) VALUES ('entries', 0)
              ON CONFLICT (name) DO NOTHING;
            UPDATE counters SET total = (SELECT COALESCE(SUM(amount), 0) FROM entries)
              WHERE name = 'entries';
          END;
        SQL
      end

      tasks.structure_dump(structure, nil)

      # The dump has to carry the trigger, or nothing downstream can.
      expect(File.read(structure)).to include("CREATE TRIGGER entries_refold_total")

      # Discard the database entirely and rebuild it from the dumped file alone.
      FileUtils.rm_f(database)
      tasks.structure_load(structure, nil)

      SQLite3::Database.new(database) do |db|
        expect(db.execute("SELECT name FROM sqlite_master WHERE type = 'trigger'").flatten)
          .to include("entries_refold_total")

        db.execute("INSERT INTO entries (amount) VALUES (7)")
        db.execute("INSERT INTO entries (amount) VALUES (5)")

        # The trigger re-folds the sum rather than incrementing it, per ADR 0002.
        expect(db.get_first_value("SELECT total FROM counters WHERE name = 'entries'")).to eq(12)
      end
    end
  end
end
