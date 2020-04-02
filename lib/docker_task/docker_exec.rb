module DockerTask
  class DockerExec
    DEFAULT_OPTIONS = {
      :registry => nil,

      # pull options
      :remote_repo => nil,
      :pull_tag => nil,

      # local registry options
      :image_name => nil,

      # push options
      :push_repo => nil,
      :push_tag => nil,

      # run options
      :container_name => nil,
      :run_tag => nil,
      :run => nil,

      # build options
      :build_path => '.',
      :dockerfile => 'Dockerfile',

      # preference
      :show_commands => true,
      :shhh => false
    }

    DOCKER_CMD = 'docker'
    GCLOUD_DOCKER_CMD = 'gcloud docker'

    DEFAULT_TAG = 'latest'

    attr_reader :options

    def initialize(options)
      @options = DEFAULT_OPTIONS.merge(options)
      @shhh = @options[:shhh]
      @run = nil

      normalize_options!
    end

    def normalize_options!
      if @options[:remote_repo].nil?
        @options[:remote_repo] = @options[:push_repo]
      end

      if @options[:pull_tag].nil?
        @options[:pull_tag] = @options[:push_tag]
      end

      if @options[:image_name].nil?
        @options[:image_name] = '%s-%s' % [ @options[:remote_repo], @options[:pull_tag] || DEFAULT_TAG ]
      end

      if @options[:container_name].nil?
        @options[:container_name] = @options[:image_name]
      end

      if !@options[:build_path].nil?
        if @options[:dockerfile] == 'Dockerfile'
          @options[:dockerfile] = File.join(@options[:build_path], @options[:dockerfile])
        elsif @options[:dockerfile].nil?
          @options[:dockerfile] = File.join(@options[:build_path], 'Dockerfile')
        end

        if !@options[:pull_tag].nil? && @options[:push_tag].nil?
          @options[:push_tag] = @options[:pull_tag]
        end

        if !@options[:remote_repo].nil? && @options[:push_repo].nil?
          @options[:push_repo] = @options[:remote_repo]
        end
      end
    end

    def container_name
      @options[:container_name]
    end

    def image_name
      @options[:image_name]
    end

    def set_run(run)
      @run = run
    end

    def can_build?
      !@options[:build_path].nil?
    end

    def build(opts = { })

      if can_build?
        build_args = 'build -t %s -f %s' % [ image_name, @options[:dockerfile] ]

        if opts[:no_cache]
          build_args << ' --no-cache'
        end

        build_args << ' %s' % @options[:build_path]

        shhh(false) do
          docker_do(build_args)
        end
      else
        raise "Cant build. No :build_path specified."
      end
    end

    def shhh(override = nil)
      if override.nil?
        @shhh = true
      else
        @shhh = override
      end

      yield
    ensure
      @shhh = @options[:shhh]
    end

    def runi(opts = { })
      run({ :interactive => true }.merge(opts))
    end

    def run(opts = { })
      run_opts = [ ]
      end_opts = nil
      do_opts = { }.merge(opts[:do] || { })

      if !do_opts.include?(:capture) && opts.include?(:capture)
        do_opts[:capture] = opts[:capture]
      end

      if !@run.nil?
        run_opts = @run.configure(run_opts)
      elsif !@options[:run].nil?
        if @options[:run].is_a?(DockerTask::Run)
          run_opts = @options[:run].configure(run_opts)
        else
          run_opts = @options[:run].call(self, run_opts)
        end
      end

      if !opts[:env_file].nil?
        run_opts << '--env-file %s' % opts[:env_file]
      end

      if !opts[:su].nil? || !opts[:exec].nil?
        run_opts << '--rm -t'
      elsif opts[:interactive]
        run_opts << '--rm -t -i'
      else
        eof_item = run_opts.index(nil)
        unless eof_item.nil?
          end_opts = run_opts.slice!(eof_item..-1)
          end_opts.shift
        end

        run_opts << '-d'
        run_opts << '--name=%s' % container_name
      end

      run_opts << '%s:%s' % [ @options[:image_name], @options[:run_tag] || DEFAULT_TAG ]

      if !opts[:su].nil?
        docker_do('run %s /bin/su -l -c "%s" %s' % [ run_opts.join(' '), opts[:exec], opts[:su] ],
                  { :ignore_fail => false }.merge(do_opts))
      elsif !opts[:exec].nil?
        docker_do('run %s /bin/bash -l -c %s' % [ run_opts.join(' '), opts[:exec] ],
                  { :ignore_fail => false }.merge(do_opts))
      elsif opts[:interactive]
        docker_do('run %s %s' % [ run_opts.join(' '), '/bin/bash -l' ],
                  { :ignore_fail => false, :interactive => true }.merge(do_opts))
      elsif end_opts.nil?
        docker_do 'run %s' % run_opts.join(' ')
      else
        docker_do 'run %s %s' % [ run_opts.join(' '), end_opts.join(' ') ]
      end
    end

    def bash
      if @options.include?(:bash)
        exec_cmd = @options[:bash]
      else
        exec_cmd = 'bash -l'
      end

      docker_do('exec -it %s %s' % [ container_name, exec_cmd ], :ignore_fail => true)
    end

    def start
      docker_do 'start %s' % container_name
    end

    def stop
      docker_do 'stop %s; true' % container_name
    end

    def restart
      stop
      start
    end

    def reload
      docker_do 'kill %s; true' % container_name
      docker_do 'rm %s; true' % container_name
      run
    end

    def push(opts = { })
      require_remote_repo do
        if !opts[:push_mirror].nil? && !opts[:push_mirror].empty?
          mk = opts[:push_mirror]

          pm = @options[:push_mirrors]
          if !pm.nil? && !pm.empty?
            push_repo = pm[mk.to_sym]
          else
            push_repo = nil
          end

          if push_repo.nil? || push_repo.empty?
            raise "Mirror %s not found" % mk
          end
        else
          push_repo = repo_with_registry(@options[:push_repo], @options[:registry])
        end

        if @options[:push_tag].nil?
          docker_do 'tag %s %s' % [ @options[:image_name], push_repo ]
          docker_do 'push %s' % push_repo
        else
          docker_do 'tag %s %s:%s' % [ @options[:image_name], push_repo, @options[:push_tag] ]
          docker_do 'push %s:%s' % [ push_repo, @options[:push_tag] ]
        end
      end
    end

    def pull
      require_remote_repo do
        pull_repo = repo_with_registry(@options[:remote_repo], @options[:registry])

        if @options[:pull_tag].nil?
          docker_do 'pull %s' % pull_repo
          docker_do 'tag %s %s' % [ pull_repo, @options[:image_name] ]
        else
          docker_do 'pull %s:%s' % [ pull_repo, @options[:pull_tag] ]
          docker_do 'tag %s:%s %s' % [ pull_repo, @options[:pull_tag], @options[:image_name] ]
        end
      end
    end

    def retag
      require_remote_repo do
        pull_repo = repo_with_registry(@options[:remote_repo], @options[:registry])

        if @options[:pull_tag].nil?
          docker_do 'tag %s %s' % [ pull_repo, @options[:image_name] ]
        else
          docker_do 'tag %s:%s %s' % [ pull_repo, @options[:pull_tag], @options[:image_name] ]
        end
      end
    end

    def destroy
      remove
      docker_do 'rmi %s' % image_name, :ignore_fail => true
    end

    def remove
      docker_do 'kill %s' % container_name, :ignore_fail => true
      docker_do 'rm %s' % container_name, :ignore_fail => true
    end

    def rebuild
      destroy
      build
    end

    def reset
      destroy
      build
      run
    end

    def require_remote_repo
      if @options[:remote_repo]
        yield
      else
        raise 'Please specify a remote_repo for this docker context'
      end
    end

    def repo_with_registry(repo_name, registry = nil)
      if registry.nil?
        repo_name
      else
        '%s/%s' % [ registry, repo_name ]
      end
    end

    def docker_do(cmd, opts = { })
      unless opts.include?(:shhh)
        opts[:shhh] = @shhh
      end

      unless opts.include?(:show_commands)
        opts[:show_commands] = @options[:show_commands]
      end

      cmd = '%s %s' % [ docker_cmd, cmd ]
      if opts[:show_commands]
        puts(cmd)
      end

      if opts[:interactive]
        DockerTask::Executor.sys(cmd, opts)
      else
        out_buffer, err_buffer, exit_status = DockerTask::Executor.pipe(cmd, opts)

        if opts[:capture]
          [ out_buffer, err_buffer, exit_status ]
        else
          if opts[:ignore_fail]
            true
          else
            exit_status.success?
          end
        end
      end
    end

    def docker_cmd(registry = nil)
      if registry.nil?
        DOCKER_CMD
      elsif registry =~ /\.grc\.io/
        GCLOUD_DOCKER_CMD
      else
        DOCKER_CMD
      end
    end
  end
end
