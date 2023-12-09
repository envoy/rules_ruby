# frozen_string_literal: true

require 'fileutils'

vendor_path = '{vendor_path}'
bundle_path = File.join(vendor_path, 'bundle', 'ruby', RbConfig::CONFIG['ruby_version'])
cache_path = File.join(vendor_path, 'cache')

FileUtils.mkdir_p(bundle_path)
FileUtils.mkdir_p(cache_path)

args = ARGV.each_slice(2).to_a
args.each do |(gem, dir)|
  FileUtils.cp(gem, cache_path)
  FileUtils.cp_r(File.join(dir, '.'), bundle_path, remove_destination: true)
end

# vim: ft=ruby
