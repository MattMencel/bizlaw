# frozen_string_literal: true

namespace :case do
  desc "Import a Case from authored data (defaults to the reference Case)"
  task :import, [:path] => :environment do |_task, args|
    path = args[:path] || Rails.root.join("db/cases/reference.yml")
    begin
      version = Cases::Import.call(path)
    rescue Cases::Import::InvalidCase, Cases::Import::PublishedVersionExists => e
      abort e.message
    end
    puts "Imported #{version.case.identifier} #{version.version} " \
         "(#{version.published? ? "published" : "draft"}, #{version.day_count} Days)"
  end
end
