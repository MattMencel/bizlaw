ALTER TABLE "courses" DISABLE ROW LEVEL SECURITY;--> statement-breakpoint
ALTER TABLE "enrollments" DISABLE ROW LEVEL SECURITY;--> statement-breakpoint
ALTER TABLE "invitations" DISABLE ROW LEVEL SECURITY;--> statement-breakpoint
DROP TABLE "courses" CASCADE;--> statement-breakpoint
DROP TABLE "enrollments" CASCADE;--> statement-breakpoint
DROP TABLE "invitations" CASCADE;--> statement-breakpoint
ALTER TABLE "cases" DROP CONSTRAINT "cases_course_id_courses_id_fk";
--> statement-breakpoint
ALTER TABLE "cases" DROP COLUMN "course_id";
