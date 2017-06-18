require_relative 'lib/pin_repin_client.rb'

def pbcopy(input)
  str = input.to_s
  IO.popen('pbcopy', 'w') { |f| f << str }
  str
end
#new login
client = Pin::Client.login('username','password')
client = Pin::Client.login('username','password',nil,"123.123.123.123:800","123.123.123.123:800")
client = Pin::Client.login('username','password',nil,["123.123.123.123:800","123.123.123.123:800"])
#store these values (in cookies, session, etc) for use in later requests
# login_cookies = client.login_cookies
# username = client.username
#restore previous login
# client = Pin::Client.new(username,login_cookies)
# client.follow_user('sqearlworld', '796081809040378011')
# client.unfollow_user('sqearlworld', '796081809040378011')
# client.follow_board('sqearlworld','chairs', '796081740320928279')
# client.unfollow_board('sqearlworld','chairs', '796081740320928279')
# client.followers('aureliencassegr').to_json
#most recent pins
# puts client.get_recent_pins('-cool-guitars')[2]
# puts client.get_recent_pins('-cool-guitars','otherusername')[2]

#detailed infomation on a single pin
# puts client.get_pin('pin_id')

#create new board
# client.create_board(
#   "testytestytestytesty",
#   "public",
#   description: "this is just a test board"
# )

#retrive all boards for logged in user
# puts client.get_boards

# single repin
# client.repin('board_id','pin_url')

# multi_rpin
# client.repin_multi('board_id',['pin_url','pin_url','pin_url'])
# client.repin_multi([['board_id','pin_url'],['board_id','pin_url']])
# client.repin_multi({'board_id' => ['pin_url','pin_url'],'board_id2' => ['pin_url','pin_url']})
