RSpec::Matchers.define :classify do |user_agent_string|
  match do
    (@actual_classification = WurflDevice::UserAgent.classify(user_agent_string)).casecmp(@classification) == 0
  end

  chain :as do |c|
    @classification = c
  end

  failure_message_for_should do |user_agent|
    "expected classification of #{user_agent.inspect} as '#{@classification}', got #{@actual_classification.inspect}"
  end

  description do
    "#{user_agent_string.inspect} be classified as #{@classification.inspect}"
  end
end

RSpec::Matchers.define :encoded do |user_agent|
  match do
    (@actual_encoding = WurflDevice::UserAgent.new(user_agent).encoding.name) == @encoding
  end

  chain :as do |e|
    @encoding = e
  end

  failure_message_for_should do
    "expected encoding of #{user_agent.inspect} is '#{@encoding}', got #{@actual_encoding.inspect}"
  end

  description do
    "#{user_agent.inspect} be encoded as #{@encoding.inspect}"
  end
end

RSpec::Matchers.define :platform do |user_agent|
  match do
    @actual_platform == @platform
  end

  chain :is_desktop do
    platform_check('desktop', user_agent)
  end

  chain :is_mobile do
    platform_check('mobile', user_agent)
  end

  chain :is_robot do
    platform_check('robot', user_agent)
  end

  def platform_check(platform, user_agent)
    @platform = platform
    @user_agent = WurflDevice::UserAgent.new(user_agent)
    @actual_platform = case
    when @user_agent.is_desktop_browser?
      'desktop'
    when @user_agent.is_mobile_browser?
      'mobile'
    when @user_agent.is_robot?
      'robot'
    else
      'unknown'
    end
  end

  failure_message_for_should do
    "expected platform of #{user_agent.inspect} is '#{@platform}', got #{@actual_platform.inspect}"
  end

  description do
    "#{user_agent.inspect} platform is #{@platform.inspect}"
  end
end

