# frozen_string_literal: true

ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" if File.exist?(ENV["BUNDLE_GEMFILE"])

begin
  require "simplecov"
  SimpleCov.start do
    add_filter ["/spec/"]
  end
rescue LoadError
end

Bundler.require(:default, :test)

require "dotenv/load"

require_relative "../lib/request_timeout"

ActiveRecord::Base.establish_connection("adapter" => "sqlite3", "database" => ":memory:")

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.order = :random

  config.around(:each) do |example|
    if example.metadata[:freeze_time]
      time = Time.at(Time.now.to_f.round(3))
      Timecop.freeze(time) { example.run }
    else
      example.run
    end
  end
end