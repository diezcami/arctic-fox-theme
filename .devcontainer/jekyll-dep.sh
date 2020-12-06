echo '# Install Ruby Gems to ~/gems' >> ~/.bashrc
echo 'export GEM_HOME="$HOME/gems"' >> ~/.bashrc
echo 'export PATH="$HOME/gems/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

apt-get install -y software-properties-common  build-essential zlib1g-dev
apt-add-repository -y ppa:brightbox/ruby-ng
apt update
apt install -y ruby2.7 ruby-switch
ruby-switch --set ruby2.7


gem install jekyll bundler

