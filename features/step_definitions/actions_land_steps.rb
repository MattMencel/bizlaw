# frozen_string_literal: true

# The Case File is read back the way a student reads it: by title, and by
# whether the document is one they may put in front of the other Side.
module CaseFileReads
  def case_file(role) = @simulation.sides.find_by!(role: role).case_file_documents.reload

  def a_filed_document(role, title)
    case_file(role).find { |filed| filed.title == title } ||
      raise("the #{role} Case File holds no #{title.inspect}")
  end

  def bound_consumed(role) = @simulation.sides.find_by!(role: role).bound_consumed
end
World(CaseFileReads)

Given("Sam is on the defendant Side") do
  @sam = User.create!(organization: @section.organization, name: "Sam", email: "sam@wiu.edu")
end

When("Sam spends a {word} on Day {int}") do |kind, ordinal|
  Days::Command.apply(
    act: :spend,
    side: @simulation.defendant_side,
    day: @simulation.days.find_by!(ordinal: ordinal),
    by: @sam,
    kind: kind
  )
end

Then("the {word} Case File is empty") do |role|
  expect(case_file(role)).to be_empty
end

Then("the {word} Case File holds {string}") do |role, title|
  expect(case_file(role).map(&:title)).to include(title)
end

Then("the {word} may play {string}") do |role, title|
  expect(a_filed_document(role, title)).to be_playable
end

Then("the {word} may not play {string}") do |role, title|
  expect(a_filed_document(role, title)).not_to be_playable
end

Then("the {word} Client has moved none of its bound") do |role|
  expect(bound_consumed(role)).to be_zero
end

Then("the {word} Client has moved {float} of its bound") do |role, fraction|
  expect(bound_consumed(role)).to eq(fraction)
end
