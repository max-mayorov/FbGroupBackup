import urllib.request, json


def getFeed(url, i):
    print(i)
    with urllib.request.urlopen(url) as response:
        data = json.loads(response.read().decode("utf-8"))
    
    print(url)
    #print(data)
    print(i)

    dict = data["data"]
    print(len(dict))
    if len(dict)==0:
        return dict

    #prev = data["paging"]["previous"]
    #if prev:
    #    dict.extend(getFeed(prev, i-1))
    
    next = data["paging"]["next"]
    if next:
        dict.extend(getFeed(next, i+1))
    
    return dict


token = "EAAYKEFkRUekBALvUVuZAiF9gXpFBxj3G7MEcr07lUl1qdi1Y8EvF3ku78x54oKE9O3SsuZANI4ZBXFMYcbw0F15OpaIIP1ZAQeBxZACe7TyC9b3tZBFWr9SUovLAWs69gtLBrErrn3oMIOmpRBCw9GZBd3rYP7DJpoZD"
feed = getFeed("https://graph.facebook.com/v2.8/484923048324193/feed?child_attachments%2Ccaption%2Cdescription%2Cfrom%2Cfull_picture%2Cmessage%2Cpicture%2Ctype%2Cpermalink_url%7D&access_token=" + token, 0) 

for post in feed:
    print(post["id"]+" "+post["message"].encode("cp866", "replace").decode("cp866"))




