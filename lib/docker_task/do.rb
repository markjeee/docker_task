module DockerTask
  module Do
    def self.pull(exec_p)
      de = DockerExec.new(exec_p)
      de.pull
    end

    module Methods
      def pull(exec_p)
        if exec_p.is_a?(String)
          repo, tag = exec_p.split(':', 2)
          DockerTask::Do.pull(:remote_repo => repo, :pull_tag => tag)
        else
          DockerTask::Do.pull(exec_p)
        end
      end
    end
  end
end
