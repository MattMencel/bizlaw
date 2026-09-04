CREATE TABLE IF NOT EXISTS "schema_migrations" ("version" varchar NOT NULL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS "ar_internal_metadata" ("key" varchar NOT NULL PRIMARY KEY, "value" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE TABLE IF NOT EXISTS "cases" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "identifier" varchar NOT NULL, "name" varchar NOT NULL, "licence" varchar NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE UNIQUE INDEX "index_cases_on_identifier" ON "cases" ("identifier") /*application='Bizlaw'*/;
CREATE TABLE IF NOT EXISTS "case_calendar_days" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "case_version_id" integer NOT NULL, "ordinal" integer NOT NULL, "in_fiction_date" date NOT NULL, CONSTRAINT "fk_rails_1bdb15c9d8"
FOREIGN KEY ("case_version_id")
  REFERENCES "case_versions" ("id")
, CONSTRAINT case_calendar_days_ordinal_positive CHECK (ordinal >= 1));
CREATE INDEX "index_case_calendar_days_on_case_version_id" ON "case_calendar_days" ("case_version_id") /*application='Bizlaw'*/;
CREATE UNIQUE INDEX "index_case_calendar_days_on_case_version_id_and_ordinal" ON "case_calendar_days" ("case_version_id", "ordinal") /*application='Bizlaw'*/;
CREATE UNIQUE INDEX "idx_on_case_version_id_in_fiction_date_eb4cd06798" ON "case_calendar_days" ("case_version_id", "in_fiction_date") /*application='Bizlaw'*/;
CREATE TABLE IF NOT EXISTS "organizations" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE TABLE IF NOT EXISTS "sections" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "organization_id" integer NOT NULL, "name" varchar NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "budget_per_day" integer /*application='Bizlaw'*/, CONSTRAINT "fk_rails_ac0b9e937d"
FOREIGN KEY ("organization_id")
  REFERENCES "organizations" ("id")
);
CREATE INDEX "index_sections_on_organization_id" ON "sections" ("organization_id") /*application='Bizlaw'*/;
CREATE UNIQUE INDEX "index_sections_on_id_and_organization_id" ON "sections" ("id", "organization_id") /*application='Bizlaw'*/;
CREATE TABLE IF NOT EXISTS "simulations" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "organization_id" bigint NOT NULL, "section_id" bigint NOT NULL, "case_version_id" integer NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_83b86dc775"
FOREIGN KEY ("case_version_id")
  REFERENCES "case_versions" ("id")
, CONSTRAINT "fk_rails_5a9f88e258"
FOREIGN KEY ("section_id", "organization_id")
  REFERENCES "sections" ("id", "organization_id")
);
CREATE INDEX "index_simulations_on_case_version_id" ON "simulations" ("case_version_id") /*application='Bizlaw'*/;
CREATE INDEX "index_simulations_on_section_id_and_organization_id" ON "simulations" ("section_id", "organization_id") /*application='Bizlaw'*/;
CREATE UNIQUE INDEX "index_simulations_on_id_and_organization_id" ON "simulations" ("id", "organization_id") /*application='Bizlaw'*/;
CREATE TABLE IF NOT EXISTS "sides" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "organization_id" bigint NOT NULL, "simulation_id" bigint NOT NULL, "role" varchar NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_8844f48244"
FOREIGN KEY ("simulation_id", "organization_id")
  REFERENCES "simulations" ("id", "organization_id")
, CONSTRAINT sides_role_known CHECK (role IN ('plaintiff', 'defendant')));
CREATE UNIQUE INDEX "index_sides_on_simulation_id_and_role" ON "sides" ("simulation_id", "role") /*application='Bizlaw'*/;
CREATE UNIQUE INDEX "index_sides_on_id_and_organization_id" ON "sides" ("id", "organization_id") /*application='Bizlaw'*/;
CREATE TABLE IF NOT EXISTS "days" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "organization_id" bigint NOT NULL, "simulation_id" bigint NOT NULL, "ordinal" integer NOT NULL, "in_fiction_date" date NOT NULL, "closed_at" datetime(6), "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_56a62740e3"
FOREIGN KEY ("simulation_id", "organization_id")
  REFERENCES "simulations" ("id", "organization_id")
, CONSTRAINT days_ordinal_positive CHECK (ordinal >= 1));
CREATE UNIQUE INDEX "index_days_on_simulation_id_and_ordinal" ON "days" ("simulation_id", "ordinal") /*application='Bizlaw'*/;
CREATE UNIQUE INDEX "index_days_on_simulation_id_and_in_fiction_date" ON "days" ("simulation_id", "in_fiction_date") /*application='Bizlaw'*/;
CREATE UNIQUE INDEX "index_days_on_id_and_organization_id" ON "days" ("id", "organization_id") /*application='Bizlaw'*/;
CREATE TABLE IF NOT EXISTS "case_versions" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "case_id" integer NOT NULL, "version" varchar NOT NULL, "published_at" datetime(6), "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "budget_per_day" integer NOT NULL, "exchange_pool" integer NOT NULL, "closing_knee" decimal(3,2) NOT NULL, "closing_preparation" integer NOT NULL, "closing_exchange" integer NOT NULL, CONSTRAINT "fk_rails_607cd4326b"
FOREIGN KEY ("case_id")
  REFERENCES "cases" ("id")
, CONSTRAINT case_versions_exchange_pool_plays_an_offer CHECK (exchange_pool >= 2), CONSTRAINT case_versions_closing_exchange_plays_an_offer CHECK (closing_exchange >= 2));
CREATE INDEX "index_case_versions_on_case_id" ON "case_versions" ("case_id") /*application='Bizlaw'*/;
CREATE UNIQUE INDEX "index_case_versions_on_case_id_and_version" ON "case_versions" ("case_id", "version") /*application='Bizlaw'*/;
CREATE UNIQUE INDEX "index_sides_on_id_and_simulation_id_and_organization_id" ON "sides" ("id", "simulation_id", "organization_id") /*application='Bizlaw'*/;
CREATE UNIQUE INDEX "index_days_on_id_and_simulation_id_and_organization_id" ON "days" ("id", "simulation_id", "organization_id") /*application='Bizlaw'*/;
CREATE TABLE IF NOT EXISTS "day_budgets" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "organization_id" bigint NOT NULL, "simulation_id" bigint NOT NULL, "side_id" bigint NOT NULL, "day_id" bigint NOT NULL, "preparation_budget" integer NOT NULL, "preparation_spent" integer DEFAULT 0 NOT NULL, "exchange_budget" integer NOT NULL, "exchange_spent" integer DEFAULT 0 NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_69c54af8ae"
FOREIGN KEY ("side_id", "simulation_id", "organization_id")
  REFERENCES "sides" ("id", "simulation_id", "organization_id")
, CONSTRAINT "fk_rails_5e18d1d234"
FOREIGN KEY ("day_id", "simulation_id", "organization_id")
  REFERENCES "days" ("id", "simulation_id", "organization_id")
, CONSTRAINT day_budgets_preparation_within_budget CHECK (preparation_spent <= preparation_budget), CONSTRAINT day_budgets_exchange_within_budget CHECK (exchange_spent <= exchange_budget), CONSTRAINT day_budgets_preparation_budget_non_negative CHECK (preparation_budget >= 0), CONSTRAINT day_budgets_exchange_budget_plays_an_offer CHECK (exchange_budget >= 2));
CREATE UNIQUE INDEX "index_day_budgets_on_side_id_and_day_id" ON "day_budgets" ("side_id", "day_id") /*application='Bizlaw'*/;
CREATE INDEX "index_day_budgets_on_day_id" ON "day_budgets" ("day_id") /*application='Bizlaw'*/;
CREATE TABLE IF NOT EXISTS "users" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "organization_id" integer NOT NULL, "name" varchar NOT NULL, "email" varchar NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_d7b9ff90af"
FOREIGN KEY ("organization_id")
  REFERENCES "organizations" ("id")
);
CREATE INDEX "index_users_on_organization_id" ON "users" ("organization_id") /*application='Bizlaw'*/;
CREATE UNIQUE INDEX "index_users_on_organization_id_and_email" ON "users" ("organization_id", "email") /*application='Bizlaw'*/;
CREATE UNIQUE INDEX "index_users_on_id_and_organization_id" ON "users" ("id", "organization_id") /*application='Bizlaw'*/;
CREATE TABLE IF NOT EXISTS "case_actions" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "case_version_id" integer NOT NULL, "kind" varchar NOT NULL, "cost" integer NOT NULL, "lead_time_days" integer NOT NULL, "half" varchar NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_b1790da577"
FOREIGN KEY ("case_version_id")
  REFERENCES "case_versions" ("id")
, CONSTRAINT case_actions_cost_is_a_spend CHECK (cost >= 1), CONSTRAINT case_actions_lead_time_not_negative CHECK (lead_time_days >= 0), CONSTRAINT case_actions_half_known CHECK (half IN ('preparation', 'exchange')));
CREATE INDEX "index_case_actions_on_case_version_id" ON "case_actions" ("case_version_id") /*application='Bizlaw'*/;
CREATE UNIQUE INDEX "index_case_actions_on_case_version_id_and_kind" ON "case_actions" ("case_version_id", "kind") /*application='Bizlaw'*/;
CREATE TABLE IF NOT EXISTS "docket_entries" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "organization_id" bigint NOT NULL, "simulation_id" bigint NOT NULL, "side_id" bigint NOT NULL, "day_id" bigint NOT NULL, "lands_on_day_id" bigint NOT NULL, "spent_by_user_id" bigint NOT NULL, "case_action_id" integer NOT NULL, "cost" integer NOT NULL, "half" varchar NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_99019e6ee5"
FOREIGN KEY ("lands_on_day_id", "simulation_id", "organization_id")
  REFERENCES "days" ("id", "simulation_id", "organization_id")
, CONSTRAINT "fk_rails_830888c7e6"
FOREIGN KEY ("side_id", "simulation_id", "organization_id")
  REFERENCES "sides" ("id", "simulation_id", "organization_id")
, CONSTRAINT "fk_rails_a48ee3309b"
FOREIGN KEY ("case_action_id")
  REFERENCES "case_actions" ("id")
, CONSTRAINT "fk_rails_d35e422dac"
FOREIGN KEY ("day_id", "simulation_id", "organization_id")
  REFERENCES "days" ("id", "simulation_id", "organization_id")
, CONSTRAINT "fk_rails_1e692ded11"
FOREIGN KEY ("spent_by_user_id", "organization_id")
  REFERENCES "users" ("id", "organization_id")
, CONSTRAINT docket_entries_cost_is_a_spend CHECK (cost >= 1), CONSTRAINT docket_entries_half_known CHECK (half IN ('preparation', 'exchange')));
CREATE INDEX "index_docket_entries_on_case_action_id" ON "docket_entries" ("case_action_id") /*application='Bizlaw'*/;
CREATE INDEX "index_docket_entries_on_side_id_and_day_id" ON "docket_entries" ("side_id", "day_id") /*application='Bizlaw'*/;
CREATE INDEX "index_docket_entries_on_lands_on_day_id" ON "docket_entries" ("lands_on_day_id") /*application='Bizlaw'*/;
CREATE TRIGGER docket_entries_need_an_opened_day
BEFORE INSERT ON docket_entries
WHEN NOT EXISTS (
  SELECT 1 FROM day_budgets
  WHERE side_id = NEW.side_id AND day_id = NEW.day_id
)
BEGIN
  SELECT RAISE(ABORT, 'docket_entries_need_an_opened_day');
END;
CREATE TRIGGER docket_entries_refold_day_budget_spent
AFTER INSERT ON docket_entries
BEGIN
  UPDATE day_budgets
  SET preparation_spent = (
        SELECT COALESCE(SUM(cost), 0) FROM docket_entries
        WHERE side_id = NEW.side_id AND day_id = NEW.day_id
          AND half = 'preparation'),
      exchange_spent = (
        SELECT COALESCE(SUM(cost), 0) FROM docket_entries
        WHERE side_id = NEW.side_id AND day_id = NEW.day_id
          AND half = 'exchange')
  WHERE side_id = NEW.side_id AND day_id = NEW.day_id;
END;
CREATE TABLE IF NOT EXISTS "case_clients" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "case_version_id" integer NOT NULL, "role" varchar NOT NULL, "bound_cents" integer NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_15151301f5"
FOREIGN KEY ("case_version_id")
  REFERENCES "case_versions" ("id")
, CONSTRAINT case_clients_role_known CHECK (role IN ('plaintiff', 'defendant')), CONSTRAINT case_clients_bound_is_travel CHECK (bound_cents > 0));
CREATE INDEX "index_case_clients_on_case_version_id" ON "case_clients" ("case_version_id") /*application='Bizlaw'*/;
CREATE UNIQUE INDEX "index_case_clients_on_case_version_id_and_role" ON "case_clients" ("case_version_id", "role") /*application='Bizlaw'*/;
CREATE TABLE IF NOT EXISTS "case_terms" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "case_version_id" integer NOT NULL, "key" varchar NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_52eee3c7cb"
FOREIGN KEY ("case_version_id")
  REFERENCES "case_versions" ("id")
);
CREATE INDEX "index_case_terms_on_case_version_id" ON "case_terms" ("case_version_id") /*application='Bizlaw'*/;
CREATE UNIQUE INDEX "index_case_terms_on_case_version_id_and_key" ON "case_terms" ("case_version_id", "key") /*application='Bizlaw'*/;
CREATE UNIQUE INDEX "index_case_terms_on_id_and_case_version_id" ON "case_terms" ("id", "case_version_id") /*application='Bizlaw'*/;
CREATE UNIQUE INDEX "index_case_actions_on_id_and_case_version_id" ON "case_actions" ("id", "case_version_id") /*application='Bizlaw'*/;
CREATE TABLE IF NOT EXISTS "case_documents" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "case_version_id" bigint NOT NULL, "case_action_id" bigint NOT NULL, "identifier" varchar NOT NULL, "title" varchar NOT NULL, "body" text NOT NULL, "exhibit_target_role" varchar, "exhibit_shift_fraction" decimal(5,4), "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_4be829a175"
FOREIGN KEY ("case_version_id")
  REFERENCES "case_versions" ("id")
, CONSTRAINT "fk_rails_fd5d2e0c71"
FOREIGN KEY ("case_action_id", "case_version_id")
  REFERENCES "case_actions" ("id", "case_version_id")
, CONSTRAINT case_documents_exhibit_is_whole_or_absent CHECK ((exhibit_target_role IS NULL) = (exhibit_shift_fraction IS NULL)), CONSTRAINT case_documents_exhibit_target_known CHECK (exhibit_target_role IS NULL OR exhibit_target_role IN ('plaintiff', 'defendant')), CONSTRAINT case_documents_exhibit_shift_is_inward CHECK (exhibit_shift_fraction IS NULL OR (exhibit_shift_fraction > 0 AND exhibit_shift_fraction <= 1)));
CREATE UNIQUE INDEX "index_case_documents_on_case_version_id_and_identifier" ON "case_documents" ("case_version_id", "identifier") /*application='Bizlaw'*/;
CREATE INDEX "index_case_documents_on_case_action_id" ON "case_documents" ("case_action_id") /*application='Bizlaw'*/;
CREATE UNIQUE INDEX "index_case_documents_on_id_and_case_version_id" ON "case_documents" ("id", "case_version_id") /*application='Bizlaw'*/;
CREATE TABLE IF NOT EXISTS "case_document_terms" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "case_version_id" bigint NOT NULL, "case_document_id" bigint NOT NULL, "case_term_id" bigint NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_2095294cd9"
FOREIGN KEY ("case_document_id", "case_version_id")
  REFERENCES "case_documents" ("id", "case_version_id")
, CONSTRAINT "fk_rails_476585756c"
FOREIGN KEY ("case_term_id", "case_version_id")
  REFERENCES "case_terms" ("id", "case_version_id")
);
CREATE UNIQUE INDEX "index_case_document_terms_on_case_document_id_and_case_term_id" ON "case_document_terms" ("case_document_id", "case_term_id") /*application='Bizlaw'*/;
CREATE INDEX "index_case_document_terms_on_case_term_id" ON "case_document_terms" ("case_term_id") /*application='Bizlaw'*/;
CREATE UNIQUE INDEX "index_simulations_on_id_and_case_version_id" ON "simulations" ("id", "case_version_id") /*application='Bizlaw'*/;
CREATE TABLE IF NOT EXISTS "case_file_documents" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "organization_id" bigint NOT NULL, "simulation_id" bigint NOT NULL, "case_version_id" bigint NOT NULL, "side_id" bigint NOT NULL, "day_id" bigint NOT NULL, "case_document_id" bigint NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_35a3da4c80"
FOREIGN KEY ("case_document_id", "case_version_id")
  REFERENCES "case_documents" ("id", "case_version_id")
, CONSTRAINT "fk_rails_1e19db662b"
FOREIGN KEY ("side_id", "simulation_id", "organization_id")
  REFERENCES "sides" ("id", "simulation_id", "organization_id")
, CONSTRAINT "fk_rails_a76cc18798"
FOREIGN KEY ("day_id", "simulation_id", "organization_id")
  REFERENCES "days" ("id", "simulation_id", "organization_id")
, CONSTRAINT "fk_rails_f55f30e0e0"
FOREIGN KEY ("simulation_id", "case_version_id")
  REFERENCES "simulations" ("id", "case_version_id")
);
CREATE UNIQUE INDEX "index_case_file_documents_on_side_id_and_case_document_id" ON "case_file_documents" ("side_id", "case_document_id") /*application='Bizlaw'*/;
CREATE INDEX "index_case_file_documents_on_day_id" ON "case_file_documents" ("day_id") /*application='Bizlaw'*/;
CREATE INDEX "index_case_file_documents_on_case_document_id" ON "case_file_documents" ("case_document_id") /*application='Bizlaw'*/;
CREATE TABLE IF NOT EXISTS "client_shifts" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "organization_id" bigint NOT NULL, "simulation_id" bigint NOT NULL, "side_id" bigint NOT NULL, "day_id" bigint NOT NULL, "source_kind" varchar NOT NULL, "source_ref" bigint NOT NULL, "requested_fraction" decimal(5,4) NOT NULL, "applied_fraction" decimal(5,4) NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_a60751b1fb"
FOREIGN KEY ("side_id", "simulation_id", "organization_id")
  REFERENCES "sides" ("id", "simulation_id", "organization_id")
, CONSTRAINT "fk_rails_07f62ab2c4"
FOREIGN KEY ("day_id", "simulation_id", "organization_id")
  REFERENCES "days" ("id", "simulation_id", "organization_id")
, CONSTRAINT client_shifts_applied_within_requested CHECK (abs(applied_fraction) <= abs(requested_fraction)), CONSTRAINT client_shifts_requested_is_a_fraction_of_the_bound CHECK (requested_fraction != 0 AND abs(requested_fraction) <= 1), CONSTRAINT client_shifts_source_kind_known CHECK (source_kind IN ('unfavorable_discovery')));
CREATE UNIQUE INDEX "index_client_shifts_on_side_id_and_source_kind_and_source_ref" ON "client_shifts" ("side_id", "source_kind", "source_ref") /*application='Bizlaw'*/;
CREATE INDEX "index_client_shifts_on_day_id" ON "client_shifts" ("day_id") /*application='Bizlaw'*/;
INSERT INTO "schema_migrations" (version) VALUES
('20260903120000'),
('20260902130000'),
('20260902120000'),
('20260901120100'),
('20260901120000');
