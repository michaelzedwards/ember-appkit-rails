require 'test_helper'
require 'generators/ember/install_generator'
require 'vcr'

class InstallGeneratorTest < Rails::Generators::TestCase
  tests Ember::Generators::InstallGenerator
  destination File.join(Rails.root, "tmp", "generator_test_output")

  setup :prepare_destination, :set_test_environment

  def copy_directory(dir)
    source = Rails.root.join(dir)
    dest = Rails.root.join("tmp", "generator_test_output", File.dirname(dir))

    FileUtils.mkdir_p dest
    FileUtils.cp_r source, dest
  end

  def set_test_environment
    ENV['THOR_DEBUG'] = '1'
    VCR.configure do |c|
      c.cassette_library_dir = 'test/fixtures/vcr_cassettes'
      c.hook_into :webmock # or :fakeweb
      c.default_cassette_options = { :record => :new_episodes }
    end
  end

  def create_directory(dir)
    dest = Rails.root.join("tmp", "generator_test_output", dir)
    FileUtils.mkdir_p dest
  end

  test "without any options it load the release channel" do
    VCR.use_cassette('fetch_ember_release') do
      run_generator
      assert_all_ember_files
      # assert_all_ember_data_files TODO: Remove after ember data is released
    end
  end

  test "with options channel=release it should load the release ember-data & ember files" do
    VCR.use_cassette('fetch_ember_release') do
      run_generator ['--channel=release']
      assert_all_ember_files
      # assert_all_ember_data_files TODO: Remove after ember data is released
    end
  end

  test "with options channel=beta it should load the beta ember-data & ember files" do
    VCR.use_cassette('fetch_ember_beta') do
      run_generator ['--channel=beta']
      assert_all_ember_files
      assert_all_ember_data_files
    end
  end

  test "with options channel=canary it should load the beta ember-data & ember files" do
    VCR.use_cassette('fetch_ember_canary') do
      run_generator ['--channel=canary']
      assert_all_ember_files
      assert_all_ember_data_files
    end
  end

  test "with unknown channel option it should raise exception InvalidChannel" do
    assert_raise ::InvalidChannel do
      run_generator ['--channel=unkown'], debug: true
    end
    assert_no_ember_files
    assert_no_ember_data_files
  end

  test "with option ember_only it should only load ember" do
    VCR.use_cassette('fetch_ember_release') do
      run_generator ['--ember_only']
    end
    assert_all_ember_files
    assert_no_ember_data_files
  end

  test "option --ember aliases --ember_only" do
    VCR.use_cassette('fetch_ember_release') do
      run_generator ['--ember']
    end
    assert_all_ember_files
    assert_no_ember_data_files
  end

  test "with option ember-data_only it should only load ember" do
    VCR.use_cassette('fetch_ember_beta') do
      run_generator ['--ember_data_only', '--channel=beta']
    end
    assert_no_ember_files
    assert_all_ember_data_files
  end

  test "option --ember-data aliasses --ember_data_only" do
    VCR.use_cassette('fetch_ember_beta') do
      run_generator ['--ember-data', '--channel=beta']
    end
    assert_no_ember_files
    assert_all_ember_data_files
  end

  test "with options --tag=v1.0.0-beta.1 --ember-data" do
    VCR.use_cassette('fetch_ember_data_tagged') do
      run_generator ['--tag=v1.0.0-beta.1', '--ember-data']
    end
    assert_no_ember_files
    assert_all_ember_data_files
  end

  test "with option --tag=v1.2.0-beta.2 --ember" do
    VCR.use_cassette('fetch_ember_tagged') do
      run_generator ['--tag=v1.2.0-beta.2', '--ember']
    end
    assert_all_ember_files
    assert_no_ember_data_files
  end

  test "with options --channel set and options --tag it should raise exception ConflictingOptions" do
    assert_raise ::ConflictingOptions do
      run_generator ['--channel=canary', '--tag=v1.2.0-beta.2/ember'], debug: true
    end
    assert_no_ember_files
    assert_no_ember_data_files
  end

  test "with options --tag without --ember or --ember-data it should raise exception InsufficientOptions" do
    assert_raise ::InsufficientOptions do
      run_generator ['--tag=v1.2.0-beta.2'], debug: true
    end
    assert_no_ember_files
    assert_no_ember_data_files
  end

  private

  def assert_all_ember_files
    assert_file "vendor/assets/javascripts/ember.js"
    assert_file "vendor/assets/javascripts/ember.prod.js"
  end

  def assert_all_ember_data_files
    assert_file "vendor/assets/javascripts/ember-data.js"
    assert_file "vendor/assets/javascripts/ember-data.prod.js"
  end

  def assert_no_ember_files
    assert_no_file "vendor/assets/javascripts/ember.js"
    assert_no_file "vendor/assets/javascripts/ember.prod.js"
  end

  def assert_no_ember_data_files
    assert_no_file "vendor/assets/javascripts/ember-data.js"
    assert_no_file "vendor/assets/javascripts/ember-data.prod.js"
  end
end
