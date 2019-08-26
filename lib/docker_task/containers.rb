module DockerTask
  class Containers
    attr_reader :set

    def initialize
      @set = Hash.new
    end

    def load(path = nil)
      if path.nil?
        path = File.expand_path('./Containers')
      end

      if File.exist?(path)
        ContainersFile.load(self, path)
      else
        nil
      end
    end

    def create(opts = nil)
      if block_given?
        opts = yield(opts || Hash.new)
      end

      de = DockerExec.new(opts)
      if !opts[:force] && @set.include?(de.container_name)
        raise 'Container with name %s already exist' % de.container_name
      else
        @set[de.container_name] = de
      end

      de
    end

    def [](k)
      @set[k]
    end

    def include?(k)
      @set.include?(k)
    end

    def one_and_only
      @set.values.first
    end

    def one_only?
      @set.count == 1
    end

    class ContainersFile
      def self.load(containers, path)
        self.new(containers, path).load
      end

      def initialize(containers, path)
        @containers = containers
        @path = path
        @common_opts = { }
      end

      def load
        Object.send(:const_set, :DT, self)
        Kernel.load(@path)
        Object.send(:remove_const, :DT)

        self
      end

      def common_options
        @common_opts = yield(@common_opts)
      end

      def create(opts)
        @containers.create(@common_opts.merge(opts))
      end
    end
  end
end
