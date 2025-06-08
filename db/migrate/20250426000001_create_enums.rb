# frozen_string_literal: true

class CreateEnums < ActiveRecord::Migration[7.1]
  def up
    execute <<-SQL
      CREATE TYPE user_role AS ENUM ('student', 'instructor', 'admin');
      CREATE TYPE document_type AS ENUM ('template', 'submission', 'feedback', 'resource');
      CREATE TYPE document_status AS ENUM ('draft', 'final', 'archived');
      CREATE TYPE case_status AS ENUM ('not_started', 'in_progress', 'submitted', 'reviewed', 'completed');
      CREATE TYPE case_difficulty AS ENUM ('beginner', 'intermediate', 'advanced');
      CREATE TYPE case_type AS ENUM (
        'sexual_harassment',
        'discrimination',
        'wrongful_termination',
        'contract_dispute',
        'intellectual_property'
      );
      CREATE TYPE team_member_role AS ENUM ('member', 'manager');
    SQL
  end

  def down
    execute <<-SQL
      DROP TYPE IF EXISTS user_role;
      DROP TYPE IF EXISTS document_type;
      DROP TYPE IF EXISTS document_status;
      DROP TYPE IF EXISTS case_status;
      DROP TYPE IF EXISTS case_difficulty;
      DROP TYPE IF EXISTS case_type;
      DROP TYPE IF EXISTS team_member_role;
    SQL
  end
end
