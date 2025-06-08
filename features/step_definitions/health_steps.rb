When('I make a GET request to {string}') do |path|
  get path
end

Then('the response status should be {int}') do |status|
  expect(last_response.status).to eq(status)
end

Then('the response should include {string} with value {string}') do |key, value|
  json_response = JSON.parse(last_response.body)
  expect(json_response[key]).to eq(value)
end

Then('the response should include a {string}') do |key|
  json_response = JSON.parse(last_response.body)
  expect(json_response[key]).to be_present
end
