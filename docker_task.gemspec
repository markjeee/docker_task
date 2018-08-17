# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'docker_task/version'

Gem::Specification.new do |spec|
  spec.name          = "docker_task"
  spec.version       = ENV['BUILD_VERSION'] || DockerTask::VERSION
  spec.authors       = ["Mark John Buenconsejo"]
  spec.email         = ["mark@nlevel.io"]

  spec.summary       = %q{A rake helper in working with Docker containers.}
  spec.description   = %q{A rake helper of common tasks for use when working with Docker containers.}
  spec.homepage      = "https://github.com/nlevel/docker_task"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = [ 'lib' ]

  spec.add_dependency 'rake'

  spec.add_development_dependency 'bundler', '~> 1.14'
  spec.add_development_dependency 'minitest', '~> 5.0'
end
