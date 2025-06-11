# This file creates demo data for the Legal Education Platform
# It can be run multiple times safely - it will remove existing demo data and recreate it
# Usage: bin/rails db:seed
# With custom password: DEMO_PASSWORD=yourpass bin/rails db:seed

require 'io/console'

puts "🌱 Legal Education Platform - Demo Data Seeder"
puts "=" * 60

# Function to get password securely
def get_demo_password
  if ENV['DEMO_PASSWORD']
    puts "Using password from DEMO_PASSWORD environment variable"
    return ENV['DEMO_PASSWORD']
  end

  if STDIN.tty?
    print "Enter demo user password (or press Enter for 'Password123!'): "
    password = STDIN.noecho(&:gets).chomp
    puts # New line after hidden input

    return 'Password123!' if password.empty?
    return password
  else
    puts "No TTY available and no DEMO_PASSWORD set, using default: Password123!"
    return 'Password123!'
  end
end

# Function to clean existing demo data
def clean_demo_data
  puts "\n🧹 Cleaning existing demo data..."

  demo_slugs = ['university-forgottonia', 'gotham-business', 'atlantis-law']
  demo_domains = ['forgottonia.edu', 'gotham.edu', 'atlantis.edu']

  # Clean by slug and domain to be thorough
  demo_orgs = Organization.where(slug: demo_slugs).or(Organization.where(domain: demo_domains))

  if demo_orgs.any?
    puts "Removing #{demo_orgs.count} demo organizations and their users..."

    # Remove users from demo orgs
    demo_orgs.each do |org|
      user_count = org.users.count
      org.users.destroy_all if user_count > 0
      puts "  Removed #{user_count} users from #{org.name}"
    end

    # Remove demo organizations
    demo_orgs.destroy_all
    puts "  Removed demo organizations"
  end

  puts "✅ Cleanup completed"
end

# Function to create case types
def create_case_types
  puts "\n📋 Creating case types..."

  case_type = CaseType.find_or_create_by!(title: "Sexual Harassment Matter") do |ct|
    ct.description = "Cases involving allegations of sexual harassment in the workplace or business environment."
  end

  puts "✅ Case type: #{case_type.title}"
end

# Function to create demo organizations
def create_demo_organizations
  puts "\n🏫 Creating demo organizations..."

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

  created_orgs = {}

  demo_orgs.each do |org_attrs|
    # Create organization with explicit timestamps to avoid HasTimestamps validation
    org_attrs[:created_at] = Time.current
    org_attrs[:updated_at] = Time.current

    org = Organization.create!(org_attrs)
    created_orgs[org.slug] = org
    puts "✅ #{org.name}"
  end

  created_orgs
end

# Function to create demo users
def create_demo_users(organizations, password)
  puts "\n👥 Creating demo users..."
  puts "Password for all accounts: #{password}"

  # University of Forgottonia - Main demo org
  forgottonia = organizations['university-forgottonia']

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

  puts "\nUniversity of Forgottonia:"
  forgottonia_users.each do |user_attrs|
    user = User.create!(
      email: user_attrs[:email],
      first_name: user_attrs[:first_name],
      last_name: user_attrs[:last_name],
      role: user_attrs[:role],
      organization: forgottonia,
      password: password,
      password_confirmation: password
    )
    puts "  ✅ #{user.full_name} (#{user.role})"
  end

  # Gotham Business College - Batman themed
  gotham = organizations['gotham-business']

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

  puts "\nGotham Business College:"
  gotham_users.each do |user_attrs|
    user = User.create!(
      email: user_attrs[:email],
      first_name: user_attrs[:first_name],
      last_name: user_attrs[:last_name],
      role: user_attrs[:role],
      organization: gotham,
      password: password,
      password_confirmation: password
    )
    puts "  ✅ #{user.full_name} (#{user.role})"
  end

  # Atlantis Law Institute - SpongeBob themed
  atlantis = organizations['atlantis-law']

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

  puts "\nAtlantis Law Institute:"
  atlantis_users.each do |user_attrs|
    user = User.create!(
      email: user_attrs[:email],
      first_name: user_attrs[:first_name],
      last_name: user_attrs[:last_name],
      role: user_attrs[:role],
      organization: atlantis,
      password: password,
      password_confirmation: password
    )
    puts "  ✅ #{user.full_name} (#{user.role})"
  end
end

# Main seeding process
begin
  demo_password = get_demo_password

  clean_demo_data
  create_case_types
  organizations = create_demo_organizations
  create_demo_users(organizations, demo_password)

  puts "\n🎉 Demo data seeding completed successfully!"
  puts "\nDemo Organizations Created:"
  puts "  • University of Forgottonia (2 instructors, 12 students)"
  puts "  • Gotham Business College (1 instructor, 6 students)"
  puts "  • Atlantis Law Institute (1 instructor, 6 students)"
  puts "\nSample login credentials:"
  puts "  Forgottonia Instructor: margaret.thompson@forgottonia.edu"
  puts "  Gotham Instructor: bruce.wayne@gotham.edu"
  puts "  Atlantis Instructor: eugene.krabs@atlantis.edu"
  puts "  Password: #{demo_password}"
  puts "\nTo run again: bin/rails db:seed"
  puts "With custom password: DEMO_PASSWORD=yourpass bin/rails db:seed"

rescue => e
  puts "\n❌ Error during seeding: #{e.message}"
  puts e.backtrace.first(5)
  exit 1
end
