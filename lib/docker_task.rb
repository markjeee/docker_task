require 'docker_task/version'

module DockerTask
  autoload :Task, 'docker_task/task'
  autoload :DockerExec, 'docker_task/docker_exec'
  autoload :Containers, 'docker_task/containers'
  autoload :Helper, 'docker_task/helper'

  def self.include_tasks(options = { })
    Task.new(options).define!
  end

  def self.containers
    if defined?(@@containers)
      @@containers
    else
      @@containers = Containers.new
    end
  end

  def self.create(opts = nil, &block)
    containers.create(opts, &block)
  end

  def self.create!(opts = nil, &block)
    if opts.nil?
      opts = { :force => true }
    else
      opts = { :force => true}.merge(opts)
    end

    containers.create(opts, &block)
  end
end
