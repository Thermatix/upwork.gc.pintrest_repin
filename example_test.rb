require_relative 'lib/pin_repin_client.rb'

#new login
client = Pin::Client.login('testusername','testpassword')
#store these values (in cookies, session, etc) for use in later requests
# login_cookies = client.login_cookies
# username = client.username
#restore previous login
# client = Pin::Client.new(username,login_cookies)

#25 most recent pins
puts client.get_recent_pins('-cool-guitars')[2]
puts client.get_recent_pins('-cool-guitars','upworktest1')[2]

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
