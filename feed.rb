require 'open-uri'
require 'json'

file = File.read('settings.json')
settings = JSON.parse(file)



JSON.load(open("https://graph.facebook.com/v2.8/484923048324193?fields=feed%7Bchild_attachments%2Ccaption%2Cdescription%2Cfrom%2Cfull_picture%2Cmessage%2Cpicture%2Ctype%2Cpermalink_url%7D&access_token="+settings["token"]))

