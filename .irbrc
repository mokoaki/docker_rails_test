# frozen_string_literal: true

begin
  tmp_directory_path = File.expand_path('./tmp', __dir__)
  history_file_path = File.join(tmp_directory_path, '.irb_history')
  FileUtils.mkdir_p(tmp_directory_path)

  # IRB.conf[:AUTO_INDENT] = true
  IRB.conf[:HISTORY_FILE] = history_file_path
  IRB.conf[:SAVE_HISTORY] = 1000
rescue StandardError => e
  puts "Error #{e} #{__FILE__}:#{__LINE__}"
end
