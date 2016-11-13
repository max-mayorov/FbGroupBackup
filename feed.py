import urllib.request, json
token = "EAAYKEFkRUekBALvUVuZAiF9gXpFBxj3G7MEcr07lUl1qdi1Y8EvF3ku78x54oKE9O3SsuZANI4ZBXFMYcbw0F15OpaIIP1ZAQeBxZACe7TyC9b3tZBFWr9SUovLAWs69gtLBrErrn3oMIOmpRBCw9GZBd3rYP7DJpoZD"
url = "https://graph.facebook.com/v2.8/484923048324193?fields=feed%7Bchild_attachments%2Ccaption%2Cdescription%2Cfrom%2Cfull_picture%2Cmessage%2Cpicture%2Ctype%2Cpermalink_url%7D&access_token=" + token
with urllib.request.urlopen(url) as response:
    data = json.loads(response.read())
print(data)