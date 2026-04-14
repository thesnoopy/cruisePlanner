require 'json'

project_root = File.expand_path('..', __dir__)
plugins_dependencies_path = File.join(project_root, '..', '.flutter-plugins-dependencies')
clean_registrant = ARGV.include?('--clean-registrant')

unless File.exist?(plugins_dependencies_path)
  exit 0
end

plugins_dependencies = JSON.parse(File.read(plugins_dependencies_path))
ios_plugins = plugins_dependencies.dig('plugins', 'ios')

if ios_plugins.is_a?(Array)
  filtered_ios_plugins = ios_plugins.reject { |plugin| plugin['name'] == 'receive_sharing_intent' }

  if filtered_ios_plugins.length != ios_plugins.length
    plugins_dependencies['plugins']['ios'] = filtered_ios_plugins
    File.write(plugins_dependencies_path, JSON.generate(plugins_dependencies))
  end
end

if clean_registrant
  registrant_paths = %w[
    Runner/GeneratedPluginRegistrant.h
    Runner/GeneratedPluginRegistrant.m
  ].map { |relative_path| File.join(project_root, relative_path) }

  registrant_paths.each do |path|
    next unless File.exist?(path)

    File.delete(path)
  end
end
