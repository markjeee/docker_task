require 'docker_task/version'

module DockerTask
  autoload :Containers, 'docker_task/containers'
  autoload :DockerExec, 'docker_task/docker_exec'
  autoload :Executor, 'docker_task/executor'
  autoload :Helper, 'docker_task/helper'

  autoload :Do, 'docker_task/do'

  autoload :Task, 'docker_task/task'
  autoload :Run, 'docker_task/run'

  def self.include_tasks(options = { })
    Task.new(options).define!
  end

  def self.load_containers(container_path = nil)
    containers.load(container_path)
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

  extend Do::Methods
end
