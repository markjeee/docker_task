require 'rake'
require 'rake/task'
require 'rake/tasklib'

module DockerTask
  class Task < Rake::TaskLib
    DEFAULT_OPTIONS = {
      :namespace => :docker
    }

    attr_reader :options

    def initialize(options = { })
      options = DockerTask::Helper.symbolize_keys(options)
      @options = DEFAULT_OPTIONS.merge(options)

      yield(self) if block_given?

      @docker_exec = nil
      if @options[:use]
        @docker_exec = DockerTask.containers[@options[:use]]
      end

      if @docker_exec.nil?
        @docker_exec = DockerExec.new({ task: self }.merge(@options))
      end
    end

    def task_namespace
      @options[:namespace]
    end
    alias :ns :task_namespace

    def define!
      namespace task_namespace do
        desc 'Perform whole cycle of destroy (if any), build, and run'
        task :reset do
          @docker_exec.reset
        end

        desc 'Build a new docker image based on the Dockerfile'
        task :build do
          @docker_exec.build
        end

        desc 'Rebuild the docker image'
        task :rebuild do
          @docker_exec.rebuild
        end

        desc 'Show help, and how to use this docker tool'
        task :help do
          puts <<-HELP
This is a set of Rake tasks that you can include in your own Rakefile, to aid in managing docker images and containers.
HELP
        end

        desc 'Run the latest docker image'
        task :run do
          @docker_exec.run(:exec => ENV['EXEC'])
        end

        desc 'Run docker in interactive mode (with bash shell)'
        task :runi do
          @docker_exec.run(:interactive => true)
        end

        task :bash do
          @docker_exec.bash
        end

        desc 'Run docker container'
        task :start do
          @docker_exec.start
        end

        desc 'Stop docker container'
        task :stop do
          @docker_exec.stop
        end

        desc 'Restart docker container'
        task :restart do
          @docker_exec.restart
        end

        desc 'Delete container, and create a new one'
        task :reload do
          @docker_exec.reload
        end

        desc 'Push latest built image to repo'
        task :push do
          @docker_exec.push(:push_mirror => ENV['PUSH_MIRROR'])
        end

        desc 'Pull from registry based on remote_repo options'
        task :pull do
          @docker_exec.pull
        end

        desc 'Re-tag a local copy from latest remote (will not pull)'
        task :retag do
          @docker_exec.retag
        end

        desc 'Destroy container and delete image'
        task :destroy do
          @docker_exec.destroy
        end

        desc 'Stop and remove container'
        task :remove do
          @docker_exec.remove
        end
      end
    end

    def invoke_task(tname)
      Rake::Task['%s:%s' % [ task_namespace, tname ]].invoke
    end
  end
end
