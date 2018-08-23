module DockerTask
  module Helper
    def self.symbolize_keys(hash)
      hash.inject({ }) do |result, (key, value)|
        new_key = key.kind_of?(String) ? key.to_sym : key
        new_value = value.kind_of?(Hash) ? symbolize_keys(value) : value
        result[new_key] = new_value
        result
      end
    end

    def self.format_port_maps(exposed_port, config)
      config_key = 'listen_%s' % exposed_port

      if config.include?(config_key)
        listen_config = config[config_key]
      else
        listen_config = config['listen']
      end

      opts = [ ]

      unless listen_config.nil? || listen_config.empty?
        listen_config.each do |i|
          interface, port = i.split(/\:/, 2)
          port = config['port'] if port.nil? && !config['port'].nil? && !config['port'].empty?

          opts << '-p %s:%s:%s' % [ interface, port, exposed_port ]
        end
      end

      opts
    end

    def self.format_env_params(params)
      opts = [ ]

      params.each do |e, v|
        opts << '-e %s=%s' % [ e, v ]
      end

      opts
    end

    def self.format_volume_mounts(maps)
      opts = [ ]

      maps.each do |host_path, exp_vol|
        opts << '-v %s:%s' % [ host_path, exp_vol ]
      end

      opts
    end
  end
end
