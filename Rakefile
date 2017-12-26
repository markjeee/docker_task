require 'bundler/gem_tasks'
require 'rake/testtask'
require 'gemfury/tasks'

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList['test/**/*_test.rb']
end

task :default => :test

desc "Perform gem build and push to Gemfury as 'nlevel'"
task :fury_release do
  Rake::Task['fury:release'].invoke(nil, 'nlevel')
end
