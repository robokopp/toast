#!/usr/bin/env ruby

case RUBY_VERSION
when "1.8.7"
  RAILS_VERSIONS=%w(3.0.0 3.1.0 3.2.0) 
when "1.9.3"
  RAILS_VERSIONS=%w(3.0.0 3.1.0 3.2.0)
else
  puts "Warning: Toast is currently only tested against Ruby 1.8.7 and 1.9.3, you have #{RUBY_VERSION}"
end

for rails_version in RAILS_VERSIONS
  
  ENV["TOAST_TEST_RAILS_VERSION"] = rails_version
  puts `bundle install`

  puts "="*60
  puts "Running test suite with Ruby #{RUBY_VERSION} and Rails #{`bundle show rails`.split('-').last}"
  puts "="*60

  unless $?.success?
    puts
    puts "FAILED: Installing rails version #{rails_version} failed"
    puts
    next
  end
    
  puts `bundle exec rake test` 

  unless $?.success?
    puts
    puts "FAILED: Test suite failed for rails version #{rails_version}"
    puts
  end

end
