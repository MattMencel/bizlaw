class AddCoursesCountToTerms < ActiveRecord::Migration[8.0]
  def change
    add_column :terms, :courses_count, :integer, default: 0, null: false
    
    # Backfill existing data
    reversible do |dir|
      dir.up do
        Term.find_each do |term|
          Term.reset_counters(term.id, :courses)
        end
      end
    end
  end
end
