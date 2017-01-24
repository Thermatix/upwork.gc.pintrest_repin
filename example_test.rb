require_relative 'lib/pin_repin_client.rb'

client = Pin::Client.login('testusername@host.com','testpassword')


# single repin
client.repin('board_id','pin_url')

# multi_rpin
client.repin_multi('board_id',['pin_url','pin_url','pin_url'])
client.repin_multi([['board_id','pin_url'],['board_id','pin_url']])
client.repin_multi({'board_id' => ['pin_url','pin_url'],'board_id2' => ['pin_url','pin_url']})
