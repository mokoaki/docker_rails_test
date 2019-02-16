# frozen_string_literal: true

begin
  require 'fileutils'

  # 環境次第で権限が心配だったので一応touchしてチェックする
  tmp_directory_path = Rails.root.join('tmp')
  history_file_path = tmp_directory_path.join('.irb_history')
  FileUtils.mkdir_p(tmp_directory_path)
  FileUtils.touch(history_file_path)

  # IRB.conf[:AUTO_INDENT] = true
  IRB.conf[:HISTORY_FILE] = history_file_path
  IRB.conf[:SAVE_HISTORY] = 100
rescue StandardError => e
  puts "#{e} #{__FILE__}:#{__LINE__}"
end
