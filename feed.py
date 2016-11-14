import urllib.request, json


def getFeed(url, i):
    
    with urllib.request.urlopen(url) as response:
        data = json.loads(response.read().decode("utf-8"))
    
    print(url)
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

def getMessage(post):
    if "message" in post:
        return post["message"]
    elif "story" in post:
        return post["story"]
    else:
        return ""


token = "EAAYKEFkRUekBALvUVuZAiF9gXpFBxj3G7MEcr07lUl1qdi1Y8EvF3ku78x54oKE9O3SsuZANI4ZBXFMYcbw0F15OpaIIP1ZAQeBxZACe7TyC9b3tZBFWr9SUovLAWs69gtLBrErrn3oMIOmpRBCw9GZBd3rYP7DJpoZD"
feed = getFeed("https://graph.facebook.com/v2.8/484923048324193/feed?fields=type,child_attachments,caption,description,from,full_picture,message,picture,permalink_url,story&access_token=" + token, 0) 

for post in feed:
    print(post["id"]+" "+post["type"]+" "+getMessage(post).encode("cp866", "replace").decode("cp866"))


    




