consolidate_node do |node,defaults|
  %w[home].each {|k| node.attributes[k] = Pathname(node.attributes[k])}
end

act 'yesmaster/prepare_app' do
  dir(node.home+'bin')
  dir(node.home+'scripts')

  git(node.home+'scripts/integrity-build-wrapper', :repo => 'git://github.com/plustwo/integrity-build-wrapper.git')
  symlink(node.home+'bin/plus2build', :to => node.home+'scripts/integrity-build-wrapper/integrity_build_wrapper.rb')
end

act 'yesmaster/before_restart' do
  rake 'db', :rails_env => node.rails_env, :rails_root => node.current_path
end
