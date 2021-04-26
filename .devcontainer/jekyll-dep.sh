echo '# Install Ruby Gems to ~/gems' >> ~/.bashrc
echo 'export GEM_HOME="$HOME/gems"' >> ~/.bashrc
echo 'export PATH="$HOME/gems/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Ruby Prereqs
apt-get install -y software-properties-common  build-essential zlib1g-dev
apt-add-repository -y ppa:brightbox/ruby-ng
apt update
apt install -y ruby2.7-dev ruby-switch
ruby-switch --set ruby2.7

# Install Jekyll
gem install jekyll bundler jekyll-redirect-from
# Nice to have
apt install -y vim

echo "done" >> /root/workspace/jekyll-dep.log
