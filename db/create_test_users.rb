$LOAD_PATH.unshift File.join(File.expand_path(File.dirname(__FILE__)), '../lib')
$LOAD_PATH.unshift File.join(File.expand_path(File.dirname(__FILE__)), '../app')

require 'models'
@testers = [
  { :email=>"tester01@chikaku.co.jp", :password=>"47zN4YIx7zQidn3b" }, # anai
  { :email=>"tester02@chikaku.co.jp", :password=>"gedmzwfiHWLPkwi7" }, # ohyama
  { :email=>"tester03@chikaku.co.jp", :password=>"7KDEmSmuV8b4Mzwc" }, # ono
  { :email=>"tester04@chikaku.co.jp", :password=>"CVDyAdautvSbOhwi" }, # kajiken
  { :email=>"tester05@chikaku.co.jp", :password=>"3YrkJnZyZqojrDw9" }, # kita
  { :email=>"tester06@chikaku.co.jp", :password=>"0lfkjGsVGnN9Ze51" }, # koiso
  { :email=>"tester07@chikaku.co.jp", :password=>"upbJ2HatFJd4tk2k" }, # maimai
  { :email=>"tester08@chikaku.co.jp", :password=>"8FsUmTNtBahumQmK" }, # niiyama
  { :email=>"tester09@chikaku.co.jp", :password=>"g1Zh533kc8XKBjOp" }, # reserved1
  { :email=>"tester10@chikaku.co.jp", :password=>"Yz0FFntCxiVO0luo" }, # reserved2
]

def create_single_tester(u)
  begin
    name = u[:email].split('@')[0]
    user = User.create(:email=>u[:email], :name=>name, :password=>u[:password], :role=>User::ROLE[:common])
    client = Client.create()
    viewer = user.create_viewer(name + "_viewer", client)
    group = user.create_group(name + "_group")
    group.add_viewer(viewer)
  rescue
    p "error while creating user: #{u.to_s}"
  end
end

def create_testers
    p "number of testers=#{@testers.size}" 
    @testers.each do |tester|
      create_single_tester(tester)
    end
end

puts "creating test user accounts"
create_testers
