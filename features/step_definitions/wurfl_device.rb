Given /^WurflDevice cached is initialized$/ do
  steps %Q{
    When I successfully run `rake wurfl:init`
  }
end
