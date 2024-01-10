require 'fileutils'
require 'json'
require 'rubygems/package'
require 'tmpdir'

gemspec_path = '{gemspec}'
packaged_gem_path = File.expand_path('{gem_filename}', '{bazel_out_dir}')
inputs = JSON.parse('{inputs_manifest}')
version_path = '{version_file}'

# We need to check if there are inputs which are directories.
# For such cases, we are going to check the contents of the directories
# and add the file to the inputs manifest.
inputs.dup.each do |src, dst|
  next unless File.directory?(src)

  inputs.delete(src)
  Dir.chdir(src) do
    Dir['**/*'].each do |file|
      inputs[File.join(src, file)] = File.join(dst, file)
    end
  end
end

gemspec_dst_path = gemspec_path
version_dst_path = version_path

Dir.mktmpdir do |tmpdir|
  inputs.each do |src, dst|
    if src == gemspec_path or src == version_path or src.end_with?('_gem_builder.rb')
      target = File.join(tmpdir, dst)
      if src == gemspec_path
        gemspec_dst_path = dst
      elsif src == version_path
        version_dst_path = dst
      end
    else
      target = File.join(tmpdir, 'lib', dst)
    end
    FileUtils.mkdir_p(File.dirname(target))
    FileUtils.cp(src, target)
  end

  Dir.chdir(tmpdir) do
    gemspec_dir = File.dirname(gemspec_dst_path)
    gemspec_file = File.basename(gemspec_dst_path)
    gemspec_code = File.read(gemspec_dst_path)
    version = File.read(version_dst_path)

    Dir.chdir(gemspec_dir) do
      spec = binding.eval(gemspec_code, gemspec_file, __LINE__)
      spec.version = version
      file = Gem::Package.build(spec)
      FileUtils.mv(file, packaged_gem_path)
    end
  end
end

# vim: ft=ruby
