module DockerTask
  class Run
    DEFAULT_OPTIONS = {
      :envs => { }
    }

    attr_reader :dexec
    attr_reader :options
    attr_reader :exposed_volume
    attr_reader :exposed_port

    def initialize(dexec, opts = { })
      @dexec = dexec
      @options = DEFAULT_OPTIONS.merge(opts)

      @configure_run_opts = nil
      @exposed_volume = nil
      @exposed_port = nil
    end

    def set_configure_run_opts(&block)
      @configure_run_opts = block
    end

    def set_exposed_volume(vol)
      @exposed_volume = vol
    end

    def set_exposed_port(port)
      @exposed_port = port
    end

    def envs
      @options[:envs]
    end

    def configure(run_opts = { })
      if !@configure_run_opts.nil?
        @configure_run_opts.call(self, run_opts)
      else
        configure_run_opts(run_opts)
      end
    end

    def configure_run_opts(run_opts)
      unless exposed_volume.nil?
        run_opts = configure_volume_opts(@options, run_opts, exposed_volume)
      end

      unless exposed_port.nil?
        run_opts = configure_port_opts(@options, run_opts, exposed_port)
      end

      unless envs.empty?
        run_opts = configure_envs(@options, run_opts, envs)
      end

      run_opts = configure_exec_opts(@options, run_opts)

      run_opts
    end

    def configure_port_opts(opts, run_opts, exp_port = nil)
      unless exp_port.nil?
        run_opts.concat(DockerTask::Helper.format_port_maps(exp_port, opts))
      end

      run_opts
    end

    def configure_envs(opts, run_opts, use_envs = nil)
      unless use_envs.empty?
        run_opts.concat(DockerTask::Helper.format_env_params(use_envs))
      end

      run_opts
    end

    def configure_exec_opts(opts, run_opts)
      unless opts[:opts].nil? || opts[:opts].empty?
        run_opts << nil
        run_opts << opts[:opts]
      end

      run_opts
    end

    def configure_volume_opts(opts, run_opts, exp_vol = nil)
      unless exp_vol.nil?
        if opts.is_a?(Hash) && !opts[:var].nil? && !opts[:var].empty?
          run_opts.concat(DockerTask::Helper.format_volume_mounts(opts[:var] => exp_vol))
        elsif opts.is_a?(String) && !opts.empty?
          run_opts.concat(DockerTask::Helper.format_volume_mounts(opts => exp_vol))
        end
      end

      run_opts
    end
  end
end
