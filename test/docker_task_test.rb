require 'test_helper'

class DockerTaskTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::DockerTask::VERSION
  end

  def test_it_does_something_useful
    assert defined?(::DockerTask)
  end

  def test_task_loads_ok
    assert defined?(::DockerTask::Task)
    assert_includes(::DockerTask::Task.ancestors, Rake::TaskLib)
  end
end
