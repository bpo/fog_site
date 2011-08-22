# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "fog_site"
  gem.homepage = "http://github.com/bpo/fog_site"
  gem.license = "MIT"
  gem.summary = %Q{Deploys static sites to S3 using fog}
  gem.description = %Q{Simple utility gem for deploying static sites to S3 and CloudFront using fog.}
  gem.email = "bpo@somnambulance.net"
  gem.authors = ["Brian P O'Rourke"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new


