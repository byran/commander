require_relative 'lib_test_base'
require_relative '../../start_point_checker.rb'

class StartPointCheckerTest < LibTestBase

  def self.hex(suffix)
    '0C1' + suffix
  end

  test 'F2F',
  'test_data/languages master has no errors' do
    checker = StartPointChecker.new(start_points_path + '/languages')
    errors = checker.check
    assert_zero errors
    assert_equal 5, checker.manifests.size
  end

  test '112',
  'test_data/custom has no errors' do
    checker = StartPointChecker.new(start_points_path + '/custom')
    errors = checker.check
    assert_zero errors
    assert_equal 9, checker.manifests.size
  end

  test '270',
  'test_data/exercises has no errors' do
    checker = StartPointChecker.new(start_points_path + '/exercises')
    errors = checker.check
    assert_zero errors
    assert_equal 0, checker.manifests.size
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # setup.json
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '738',
  'setup.json missing is an error' do
    copy_good_master do |tmp_dir|
      setup_filename = "#{tmp_dir}/setup.json"
      shell "mv #{setup_filename} #{tmp_dir}/setup.json.missing"
      check
      assert_error setup_filename, 'is missing'
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '2DF',
  'setup.json with bad json is an error' do
    copy_good_master do |tmp_dir|
      setup_filename = "#{tmp_dir}/setup.json"
      IO.write(setup_filename, any_bad_json)
      check
      assert_error setup_filename, 'bad JSON'
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '99A',
  'setup.json with no type is an error' do
    copy_good_master do |tmp_dir|
      setup_filename = "#{tmp_dir}/setup.json"
      IO.write(setup_filename, '{}')
      check
      assert_error setup_filename, 'type: missing'
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '64D',
  'setup.json with bad type is an error' do
    copy_good_master do |tmp_dir|
      setup_filename = "#{tmp_dir}/setup.json"
      IO.write(setup_filename, JSON.unparse({ 'type' => 'salmon' }))
      check
      assert_error setup_filename, 'type: must be [languages|exercises|custom]'
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # instructions
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '73F',
  'exercises start-point with no instructions files is an error' do
    copy_good_master('exercises') do |tmp_dir|
      Dir.glob("#{tmp_dir}/**/instructions") { |filename| File.delete(filename) }
      check
      assert_error tmp_dir, 'no instructions files'
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # manifest.json
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '51C',
  'bad json in a manifest.json file is an error' do
    copy_good_master do |tmp_dir|
      junit_manifest_filename = "#{tmp_dir}/Java/JUnit/manifest.json"
      IO.write(junit_manifest_filename, any_bad_json)
      check
      assert_nil @checker.manifests[junit_manifest_filename]
      assert_error junit_manifest_filename, 'bad JSON'
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '32B',
  'languages/custom start-point with no manifest.json files is an error' do
    copy_good_master do |tmp_dir|
      Dir.glob("#{tmp_dir}/**/manifest.json") { |filename| File.delete(filename) }
      check
      assert_error tmp_dir, 'no manifest.json files'
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'CFC',
  'manifests with the same display_name is an error' do
    copy_good_master do |tmp_dir|
      junit_manifest_filename = "#{tmp_dir}/Java/JUnit/manifest.json"
      content = IO.read(junit_manifest_filename)
      junit_manifest = JSON.parse(content)
      key = 'display_name'
      junit_display_name = junit_manifest[key]
      cucumber_manifest_filename = "#{tmp_dir}/Java/Cucumber/manifest.json"
      content = IO.read(cucumber_manifest_filename)
      cucumber_manifest = JSON.parse(content)
      cucumber_manifest[key] = junit_display_name
      IO.write(cucumber_manifest_filename, JSON.unparse(cucumber_manifest))
      check
      assert_error junit_manifest_filename,    "#{key}: duplicate 'Java, JUnit'"
      assert_error cucumber_manifest_filename, "#{key}: duplicate 'Java, JUnit'"
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # unknown keys exist
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'CC7',
  'unknown key is an error' do
    @key = 'salmon'
    assert_key_error 1, 'unknown key'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # required keys do not exist
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '554',
  'missing required key is an error' do
    missing_require_key = lambda do |key|
      copy_good_master('languages', '243554_'+key+'_') do |tmp_dir|
        junit_manifest_filename = "#{tmp_dir}/Java/JUnit/manifest.json"
        content = IO.read(junit_manifest_filename)
        junit_manifest = JSON.parse(content)
        assert junit_manifest.keys.include? key
        junit_manifest.delete(key)
        IO.write(junit_manifest_filename, JSON.unparse(junit_manifest))
        check
        assert_error junit_manifest_filename, "#{key}: missing"
      end
    end
    required_keys = %w( display_name
                        image_name
                        red_amber_green
                        visible_filenames
                      )
    required_keys.each { |key| missing_require_key.call(key) }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # required-key: display_name
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '942',
  "display_name not in 'major,minor' format is an error" do
    @key = 'display_name'
    not_in_A_comma_B_format = "not in 'major,minor' format"
    assert_key_error 1               , must_be_a_String
    assert_key_error [ 1 ]           , must_be_a_String
    assert_key_error ''              , not_in_A_comma_B_format
    assert_key_error 'no comma'      , not_in_A_comma_B_format
    assert_key_error 'one,two,commas', not_in_A_comma_B_format
    assert_key_error ',right only'   , not_in_A_comma_B_format
    assert_key_error 'left only,'    , not_in_A_comma_B_format
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'D14',
  'display_name with hyphen in major part of name is an error' do
    @key = 'display_name'
    major_cannot_contain_hypens = "'major,minor' major cannot contain hyphens(-)"
    assert_key_error 'C-CppUTest, CircularBuffer',  major_cannot_contain_hypens
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # required-key: image_name
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '696',
  'invalid image_name not an error' do
    @key = 'image_name'
    assert_key_error 1    , must_be_a_String
    assert_key_error [ 1 ], must_be_a_String
    assert_key_error ''   , is_empty
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # required-key: red_amber_green
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'C2A',
  'invalid red_amber_green is an error' do
    @key = 'red_amber_green'
    not_lambda = ['o','k']
    assert_key_error 1     , must_be_an_Array_of_Strings
    assert_key_error [ 1 ] , must_be_an_Array_of_Strings
    assert_key_error not_lambda, "cannot create lambda from #{not_lambda}"
    bad_lambda = [
      "lambda { |output|",
      "  return :yellow",
      "}"
    ]
    assert_key_error bad_lambda, "lambda.call('sdsd') expecting one of :red,:amber,:green (got yellow)"
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # required-key: visible_filenames
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '4DE',
  'visible_filenames not an Array of Strings is an error' do
    @key = 'visible_filenames'
    assert_key_error 1     , must_be_an_Array_of_Strings
    assert_key_error [ 1 ] , must_be_an_Array_of_Strings
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'C31',
  'missing visible file is an error' do
    copy_good_master do |tmp_dir|
      junit_manifest_filename = "#{tmp_dir}/Java/JUnit/manifest.json"
      content = IO.read(junit_manifest_filename)
      junit_manifest = JSON.parse(content)
      missing_filename = junit_manifest['visible_filenames'][0]
      File.delete("#{tmp_dir}/Java/JUnit/#{missing_filename}")
      check
      assert_error junit_manifest_filename, "visible_filenames: missing '#{missing_filename}'"
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '935',
  'duplicate visible file is an error' do
    copy_good_master do |tmp_dir|
      junit_manifest_filename = "#{tmp_dir}/Java/JUnit/manifest.json"
      content = IO.read(junit_manifest_filename)
      junit_manifest = JSON.parse(content)
      visible_filenames = junit_manifest['visible_filenames']
      duplicate_filename = visible_filenames[0]
      visible_filenames << duplicate_filename
      junit_manifest['visible_filenames'] = visible_filenames
      IO.write(junit_manifest_filename, JSON.unparse(junit_manifest))
      check
      assert_error junit_manifest_filename, "visible_filenames: duplicate '#{duplicate_filename}'"
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'CF5',
  'no cyber-dojo.sh in visible_filenames is an error' do
    copy_good_master do |tmp_dir|
      junit_manifest_filename = "#{tmp_dir}/Java/JUnit/manifest.json"
      content = IO.read(junit_manifest_filename)
      junit_manifest = JSON.parse(content)
      visible_filenames = junit_manifest['visible_filenames']
      visible_filenames.delete('cyber-dojo.sh')
      junit_manifest['visible_filenames'] = visible_filenames
      IO.write(junit_manifest_filename, JSON.unparse(junit_manifest))
      File.delete(File.dirname(junit_manifest_filename) + '/cyber-dojo.sh')
      check
      assert_error junit_manifest_filename, "visible_filenames: must contain 'cyber-dojo.sh'"
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '7EA',
  'visible file not world-readable is an error' do
    copy_good_master do |tmp_dir|
      junit_manifest_filename = "#{tmp_dir}/Java/JUnit/manifest.json"
      cyber_dojo_sh = "#{tmp_dir}/Java/JUnit/cyber-dojo.sh"
      File.chmod(0111, cyber_dojo_sh)
      check
      assert_error junit_manifest_filename, "visible_filenames: 'cyber-dojo.sh' must be world-readable"
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # optional-key: progress_regexs
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '623',
  'invalid progress_regexs is an error' do
    @key = 'progress_regexs'
    bad_regex = '(\\'
    assert_key_error 1               , 'must be an Array of 2 Strings'
    assert_key_error []              , 'must be an Array of 2 Strings'
    assert_key_error [1,2]           , 'must be an Array of 2 Strings'
    assert_key_error [bad_regex,'ok'], "cannot create regex from #{bad_regex}"
    assert_key_error ['ok',bad_regex], "cannot create regex from #{bad_regex}"
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # optional-key: filename_extension
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '363',
  'invalid filename_extension is an error' do
    @key = 'filename_extension'
    assert_key_error 1    , must_be_a_String
    assert_key_error []   , must_be_a_String
    assert_key_error ''   , is_empty
    assert_key_error 'cs' , 'must start with a dot'
    assert_key_error '.'  , 'must be more than just a dot'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # optional-key: highlight_filenames
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '652',
  'highlight_filename not also a visible_filename is an error' do
    duplicated = [ 'cyber-dojo.sh', 'cyber-dojo.sh' ]
    @key = 'highlight_filenames'
    assert_key_error 1              , 'must be an Array of Strings'
    assert_key_error [ 1 ]          , 'must be an Array of Strings'
    assert_key_error [ 'wibble.txt'], "'wibble.txt' must be in visible_filenames"
    assert_key_error duplicated     , "duplicate 'cyber-dojo.sh'"
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # optional-key: tab-size:
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'BF3',
  'invalid tab_size is an error' do
    @key = 'tab_size'
    assert_key_error 's'   , 'must be an int'
    assert_key_error []    , 'must be an int'
    assert_key_error 0     , 'must be an int > 0'
    assert_key_error 9     , 'must be an int <= 8'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'E46',
  'bad shell command raises' do
    assert_raises(RuntimeError) { shell 'sdsdsdsd' }
  end

  private

  def assert_setup_key_error(bad, expected)
    ['exercises','languages'].each do |type|
      copy_good_master(type) do |tmp_dir|
        manifest_filename = "#{tmp_dir}/setup.json"
        content = IO.read(manifest_filename)
        manifest = JSON.parse(content)
        manifest[@key] = bad
        IO.write(manifest_filename, JSON.unparse(manifest))
        check
        assert_error manifest_filename, @key + ': ' + expected
      end
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_key_error(bad, expected)
    copy_good_master('languages') do |tmp_dir|
      junit_manifest_filename = "#{tmp_dir}/Java/JUnit/manifest.json"
      content = IO.read(junit_manifest_filename)
      junit_manifest = JSON.parse(content)
      junit_manifest[@key] = bad
      IO.write(junit_manifest_filename, JSON.unparse(junit_manifest))
      check
      assert_error junit_manifest_filename, @key + ': ' + expected
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def copy_good_master(type = 'languages', id = test_id)
    Dir.mktmpdir('cyber-dojo-' + id + '_') do |tmp_dir|
      shell "cp -r #{start_points_path}/#{type}/* #{tmp_dir}"
      @tmp_dir = tmp_dir
      yield tmp_dir
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def check
    @checker = StartPointChecker.new(@tmp_dir)
    @checker.check
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_error filename, expected
    messages = @checker.errors[filename]
    assert_equal 'Array', messages.class.name
    assert_equal [ expected ], messages
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_zero(errors)
    diagnostic = ''
    count = 0
    errors.each do |filename, messages|
      diagnostic += filename if messages.size != 0
      messages.each { |message| diagnostic += ("\t" + message + "\n") }
      count += messages.size
    end
    assert_equal 0, count, diagnostic
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def shell(command)
    `#{command}`
  rescue
    raise RuntimeError.new("#{command} returned non-zero (#{$?.exitstatus})")
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def any_bad_json
    'xxx'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def must_be_a_String
    'must be a String'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def must_be_an_Array_of_Strings
    'must be an Array of Strings'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def is_empty
    'is empty'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def start_points_path
    File.expand_path(File.dirname(__FILE__)) + '/example_start_points'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def test_id
    ENV['DIFFER_TEST_ID']
  end

end
