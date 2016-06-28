require 'pathname'
require 'tmpdir'

def serverspec_version
  lock = File.read(File.expand_path("../Gemfile.lock", __FILE__))
  lock[/serverspec \(([0-9.]+)\)/, 1]
end

def exec(cmd)
  puts "+ #{cmd}"
  system cmd
end

def commit_push(dir)
  exec("cd #{dir} &&
       git diff --exit-code > /dev/null ||
       git add .
       git commit -m 'Update Serverspec to #{serverspec_version}' &&
       git push")
end

exec('bundle exec ruby lib/serverspec_info.rb > serverspec_info.json')

dir = Pathname.new Dir.mktmpdir('serverspec-snippets-generator')


vim_root_dir = dir.join('serverspec.vim')
exec("git clone https://github.com/pocke/serverspec.vim #{vim_root_dir} --depth 1")
exec("cp serverspec_info.json #{vim_root_dir.join 'autoload/serverspec_info.json'}")
exec("bundle exec ruby lib/generator/vim.rb > #{vim_root_dir.join 'neosnippets/ruby.serverspec.snip'}")

commit_push(vim_root_dir)


intellij_root_dir = dir.join('intellij-serverspec-live-templates')
exec("git clone https://github.com/pocke/intellij-serverspec-live-templates #{intellij_root_dir} --depth 1")
exec("bundle exec ruby lib/generator/intellij.rb > #{intellij_root_dir.join 'Serverspec.xml'}")

commit_push(intellij_root_dir)


exec("rm -rf #{dir}")
