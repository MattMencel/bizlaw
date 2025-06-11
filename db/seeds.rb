# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "🌱 Seeding database..."

# Create Case Types
puts "Creating case types..."
case_type = CaseType.find_or_create_by!(title: "Sexual Harassment Matter") do |ct|
  ct.description = "Cases involving allegations of sexual harassment in the workplace or business environment."
end
puts "✅ Case type created: #{case_type.title}"

# Create Demo Organizations
puts "\nCreating demo organizations..."

demo_orgs = [
  {
    name: "University of Forgottonia",
    domain: "forgottonia.edu",
    slug: "university-forgottonia",
    active: true
  },
  {
    name: "Gotham Business College",
    domain: "gotham.edu",
    slug: "gotham-business",
    active: true
  },
  {
    name: "Atlantis Law Institute",
    domain: "atlantis.edu",
    slug: "atlantis-law",
    active: true
  }
]

demo_orgs.each do |org_attrs|
  org = Organization.find_or_create_by!(slug: org_attrs[:slug]) do |o|
    o.name = org_attrs[:name]
    o.domain = org_attrs[:domain]
    o.active = org_attrs[:active]
    o.created_at = Time.current
    o.updated_at = Time.current
  end
  puts "✅ Organization created: #{org.name}"
end

# Create Demo Users
puts "\nCreating demo users..."

# University of Forgottonia - Main demo org
forgottonia = Organization.find_by!(slug: "university-forgottonia")

forgottonia_users = [
  # Instructors
  { email: "margaret.thompson@forgottonia.edu", first_name: "Margaret", last_name: "Thompson", role: :instructor },
  { email: "david.rodriguez@forgottonia.edu", first_name: "David", last_name: "Rodriguez", role: :instructor },

  # Students
  { email: "emma.wilson@forgottonia.edu", first_name: "Emma", last_name: "Wilson", role: :student },
  { email: "liam.johnson@forgottonia.edu", first_name: "Liam", last_name: "Johnson", role: :student },
  { email: "sophia.martinez@forgottonia.edu", first_name: "Sophia", last_name: "Martinez", role: :student },
  { email: "noah.brown@forgottonia.edu", first_name: "Noah", last_name: "Brown", role: :student },
  { email: "olivia.davis@forgottonia.edu", first_name: "Olivia", last_name: "Davis", role: :student },
  { email: "ethan.miller@forgottonia.edu", first_name: "Ethan", last_name: "Miller", role: :student },
  { email: "ava.garcia@forgottonia.edu", first_name: "Ava", last_name: "Garcia", role: :student },
  { email: "mason.anderson@forgottonia.edu", first_name: "Mason", last_name: "Anderson", role: :student },
  { email: "isabella.lopez@forgottonia.edu", first_name: "Isabella", last_name: "Lopez", role: :student },
  { email: "lucas.white@forgottonia.edu", first_name: "Lucas", last_name: "White", role: :student },
  { email: "mia.taylor@forgottonia.edu", first_name: "Mia", last_name: "Taylor", role: :student },
  { email: "alexander.harris@forgottonia.edu", first_name: "Alexander", last_name: "Harris", role: :student }
]

# Generate demo password (can be updated later)
demo_password = ENV.fetch('DEMO_PASSWORD', 'Password123!')

forgottonia_users.each do |user_attrs|
  user = User.find_or_create_by!(email: user_attrs[:email]) do |u|
    u.first_name = user_attrs[:first_name]
    u.last_name = user_attrs[:last_name]
    u.role = user_attrs[:role]
    u.organization = forgottonia
    u.password = demo_password
    u.password_confirmation = demo_password
  end
  puts "✅ Forgottonia user: #{user.full_name} (#{user.role})"
end

# Gotham Business College - Batman themed
gotham = Organization.find_by!(slug: "gotham-business")

gotham_users = [
  # Instructor
  { email: "bruce.wayne@gotham.edu", first_name: "Bruce", last_name: "Wayne", role: :instructor },

  # Students
  { email: "dick.grayson@gotham.edu", first_name: "Dick", last_name: "Grayson", role: :student },
  { email: "barbara.gordon@gotham.edu", first_name: "Barbara", last_name: "Gordon", role: :student },
  { email: "tim.drake@gotham.edu", first_name: "Tim", last_name: "Drake", role: :student },
  { email: "selina.kyle@gotham.edu", first_name: "Selina", last_name: "Kyle", role: :student },
  { email: "harvey.dent@gotham.edu", first_name: "Harvey", last_name: "Dent", role: :student },
  { email: "clark.kent@gotham.edu", first_name: "Clark", last_name: "Kent", role: :student }
]

gotham_users.each do |user_attrs|
  user = User.find_or_create_by!(email: user_attrs[:email]) do |u|
    u.first_name = user_attrs[:first_name]
    u.last_name = user_attrs[:last_name]
    u.role = user_attrs[:role]
    u.organization = gotham
    u.password = demo_password
    u.password_confirmation = demo_password
  end
  puts "✅ Gotham user: #{user.full_name} (#{user.role})"
end

# Atlantis Law Institute - SpongeBob themed
atlantis = Organization.find_by!(slug: "atlantis-law")

atlantis_users = [
  # Instructor
  { email: "eugene.krabs@atlantis.edu", first_name: "Eugene", last_name: "Krabs", role: :instructor },

  # Students
  { email: "spongebob.squarepants@atlantis.edu", first_name: "SpongeBob", last_name: "SquarePants", role: :student },
  { email: "patrick.star@atlantis.edu", first_name: "Patrick", last_name: "Star", role: :student },
  { email: "squidward.tentacles@atlantis.edu", first_name: "Squidward", last_name: "Tentacles", role: :student },
  { email: "sandy.cheeks@atlantis.edu", first_name: "Sandy", last_name: "Cheeks", role: :student },
  { email: "gary.wilson@atlantis.edu", first_name: "Gary", last_name: "Wilson", role: :student },
  { email: "pearl.krabs@atlantis.edu", first_name: "Pearl", last_name: "Krabs", role: :student }
]

atlantis_users.each do |user_attrs|
  user = User.find_or_create_by!(email: user_attrs[:email]) do |u|
    u.first_name = user_attrs[:first_name]
    u.last_name = user_attrs[:last_name]
    u.role = user_attrs[:role]
    u.organization = atlantis
    u.password = demo_password
    u.password_confirmation = demo_password
  end
  puts "✅ Atlantis user: #{user.full_name} (#{user.role})"
end

puts "\n🎉 Seeding completed successfully!"
puts "\nDemo Organizations Created:"
puts "  • University of Forgottonia (2 instructors, 12 students)"
puts "  • Gotham Business College (1 instructor, 6 students)"
puts "  • Atlantis Law Institute (1 instructor, 6 students)"
puts "\nAll demo accounts use password: #{demo_password}"
puts "\nSample login credentials:"
puts "  Forgottonia Instructor: margaret.thompson@forgottonia.edu"
puts "  Gotham Instructor: bruce.wayne@gotham.edu"
puts "  Atlantis Instructor: eugene.krabs@atlantis.edu"
puts "\nTo set a custom demo password, use: DEMO_PASSWORD=your_password bin/rails db:seed"
