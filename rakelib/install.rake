require 'rake'
require 'fileutils'
require 'rbconfig'

case RbConfig::CONFIG['host_os']
when /darwin|mac os/
  MANAGER = 'brew'
  MANAGER_GUI = 'brew cask'
  ELEVATE = false
  ACTION = 'install'
when /linux/
  ELEVATE = true
  ACTION = 'install y'

  run %{which apt-get}
  if $?.success?
    MANAGER = 'apt-get'
    MANAGER_GUI = 'apt-get'
  else
    run %{which yum}
    if $?.success?
      MANAGER = 'yum'
      MANAGER_GUI = 'yum'
    end
  end
else
 fail "Your platform is not supported yet by this script. Please download ChefDK from https://downloads.chef.io/chef-dk/ and manually install."
end

desc "Install ChefDK and Cheftasks gems"
task :install do
  sh 'which chef'
  unless $?.success?
    if MANAGER == 'brew'
      sh 'which brew'
      unless $?.success?
        puts "Installing Homebrew, the OSX package manager."
        sh 'ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"'
      end

      install_app('caskroom/cask/brew-cask')

      sh 'brew update'
    end

    install_app('chef', MANAGER_GUI)
  end

  puts 'ChefDK is installed and ready to go'

  puts 'Installing support libraries'
  BREW_LIBS.each do |lib|
    install_app lib
  end

  puts 'Installing support gems'
  CHEF_GEMS.each do |gem|
    install_gem gem
  end
end

task :update do
  sh 'git pull --rebase'

  if $?.success?
    Rake::Task["install"].execute
  else
    puts "Pulling from remote failed. Status of repository is:"
    sh 'git status'
  end
end

private
def install_app(name, pkg_mgr=MANAGER, action=ACTION, elevate=ELEVATE)
  puts "Installing #{name}"

  cmd = (elevate)? "sudo #{pkg_mgr}": pkg_mgr
  cmd += " #{action} #{name}"
  sh cmd
end

def install_gem(name, elevate=ELEVATE)
  puts "Installing #{name}"

  cmd = (elevate)? "sudo chef": 'chef'
  cmd += " gem install --no-ri --no-rdoc #{name}"
  sh cmd
end
