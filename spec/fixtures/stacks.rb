scope(env: "dev", component: "vpc") do |s|
  stack(s[:env], :'eu-west-1', :vpc) do
    inc { 'vpc.rb' }
  end
end
