CREATE TABLE IF NOT EXISTS "schema_migrations" ("version" varchar NOT NULL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS "ar_internal_metadata" ("key" varchar NOT NULL PRIMARY KEY, "value" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE TABLE IF NOT EXISTS "cases" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "identifier" varchar NOT NULL, "name" varchar NOT NULL, "licence" varchar NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE UNIQUE INDEX "index_cases_on_identifier" ON "cases" ("identifier") /*application='Bizlaw'*/;
CREATE TABLE IF NOT EXISTS "case_versions" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "case_id" integer NOT NULL, "version" varchar NOT NULL, "published_at" datetime(6), "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_607cd4326b"
FOREIGN KEY ("case_id")
  REFERENCES "cases" ("id")
);
CREATE INDEX "index_case_versions_on_case_id" ON "case_versions" ("case_id") /*application='Bizlaw'*/;
CREATE UNIQUE INDEX "index_case_versions_on_case_id_and_version" ON "case_versions" ("case_id", "version") /*application='Bizlaw'*/;
CREATE TABLE IF NOT EXISTS "case_calendar_days" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "case_version_id" integer NOT NULL, "ordinal" integer NOT NULL, "in_fiction_date" date NOT NULL, CONSTRAINT "fk_rails_1bdb15c9d8"
FOREIGN KEY ("case_version_id")
  REFERENCES "case_versions" ("id")
, CONSTRAINT case_calendar_days_ordinal_positive CHECK (ordinal >= 1));
CREATE INDEX "index_case_calendar_days_on_case_version_id" ON "case_calendar_days" ("case_version_id") /*application='Bizlaw'*/;
CREATE UNIQUE INDEX "index_case_calendar_days_on_case_version_id_and_ordinal" ON "case_calendar_days" ("case_version_id", "ordinal") /*application='Bizlaw'*/;
CREATE UNIQUE INDEX "idx_on_case_version_id_in_fiction_date_eb4cd06798" ON "case_calendar_days" ("case_version_id", "in_fiction_date") /*application='Bizlaw'*/;
CREATE TABLE IF NOT EXISTS "organizations" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE TABLE IF NOT EXISTS "sections" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "organization_id" integer NOT NULL, "name" varchar NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_ac0b9e937d"
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
INSERT INTO "schema_migrations" (version) VALUES
('20260901120100'),
('20260901120000');
