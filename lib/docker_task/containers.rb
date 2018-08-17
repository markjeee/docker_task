module DockerTask
  class Containers
    attr_reader :set

    def initialize
      @set = Hash.new
    end

    def create(opts = nil)
      if block_given?
        opts = yield(opts || Hash.new)
      end

      de = DockerExec.new(opts)
      if @set.include?(de.container_name)
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
  end
end
