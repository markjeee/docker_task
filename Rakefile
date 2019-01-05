$:.push File.expand_path('../lib', __FILE__)
require 'docker_task/version'

require 'bundler/gem_tasks'
require 'rake/testtask'
require 'gemfury/tasks'

Rake::TestTask.new do |t|
  t.libs << %w(test lib)
  t.pattern = 'test/**/*_test.rb'
end

task :default => :test

desc "Perform gem build and push to Gemfury as 'nlevel'"
task :release_fury do
  ENV['RUBYGEMS_HOST'] = 'https://push.fury.io/nlevel'

  cmd = "fury yank docker_task --as=nlevel --version=%s" % DockerTask::VERSION
  puts cmd; system(cmd)

  Rake::Task["release"].invoke
end
