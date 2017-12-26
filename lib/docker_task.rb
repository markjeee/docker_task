require "docker_task/version"

module DockerTask
  autoload :Task, 'docker_task/task'
  autoload :Helper, 'docker_task/helper'

  def self.include_tasks(options = { })
    Task.new(options).define!
  end
end
