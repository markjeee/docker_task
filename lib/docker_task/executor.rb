require 'open3'

module DockerTask
  class Executor
    def self.sys(cmd, opts = { })
      new(cmd, opts).sys
    end

    def self.pipe(cmd, opts = { })
      new(cmd, opts).pipe
    end

    def initialize(cmd, opts = { })
      @cmd = cmd
      @opts = opts
    end

    def sys
      system(@cmd)
    end

    def pipe
      executor = self

      out_buffer, err_buffer, exit_status = Open3.popen3(@cmd) do |i, o, e, t|
        out_reader = Thread.new { executor.io_reader(o, $stdout) }
        err_reader = Thread.new { executor.io_reader(e, $stderr) }

        [ out_reader.value, err_reader.value, t.value ]
      end

      [ out_buffer, err_buffer, exit_status ]
    end

    def io_reader(io, relay = nil)
      buffer = StringIO.new

      loop do
        buf = io.readpartial(512)

        unless @opts[:shhh]
          relay.write(buf)
        end

        if @opts[:capture]
          buffer.write(buf)
        end
      rescue EOFError
        break
      end

      buffer
    end
  end
end
