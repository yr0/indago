require 'fileutils'

# Allows stubbing data and index directories within spec/tmp
shared_context :tmp_dirs do |dir_prefix|
  def random_dirname(dir_prefix)
    "#{dir_prefix}-#{SecureRandom.uuid}"
  end

  before(:each) do
    dir_path = WITHIN_TEST_DIR.call(['tmp', random_dirname(dir_prefix)])
    const_name = "#{dir_prefix&.upcase}_DIR_PATH"
    unless Indago.const_defined?(const_name)
      raise "You provided #{dir_prefix} to tmp_dirs context, "\
            "however Indago::#{const_name} constant does not exist"
    end
    stub_const "Indago::#{const_name}", dir_path
    # set variable to be accessible within tests and :after block, e.g. @indexes_tmp_dir_path
    instance_variable_set("@#{dir_prefix}_tmp_dir_path", dir_path)
    Dir.mkdir(dir_path)
  end

  after(:each) do
    dir_path = instance_variable_get("@#{dir_prefix}_tmp_dir_path")
    tmp_from_current_file = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'tmp'))
    unless File.expand_path(File.join(dir_path, '..')) == tmp_from_current_file
      raise "FATAL: one of your tmp dirs is #{dir_path}, which is outside of test tmp directory. "\
            'Therefore, it will not be removed.'
    end
    FileUtils.rm_rf(dir_path, secure: true)
  end
end
