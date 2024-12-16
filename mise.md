mise plugin add erlang https://github.com/asdf-vm/asdf-erlang.git 
mise plugin install elixir https://github.com/mise-plugins/mise-elixir.git
mise install erlang 27.1.3
mise install elixir@1.17.3-otp-27
mise use --global elixir@1.17.3-otp-27
mise use --global erlang@27.1.3
mise current
mise ls