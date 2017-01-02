scope(env: 'dev', component: 'vpc') do
  stack('dev', 'eu-west-1', 'vpc') do
    inc { 'vpc.rb' }
  end
end
