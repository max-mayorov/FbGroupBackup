"""Retrieves facebook group feed and saves all posts to XML"""

import urllib.request
import json
import xml.etree.ElementTree as ET
import os
import re

pat = re.compile('.+[\/\?#=]([\w-]+\.[\w-]+(?:\.[\w-]+)?$)')
def get_url_filename(url):
    return url.split("?")[0].split("/")[-1]

def get_feed(url, i, lastid):
    """Retrieves feed from FB group"""
    with urllib.request.urlopen(url) as response:
        data = json.loads(response.read().decode("utf-8"))

    print(url)
    print(i)

    fbfeed = list(reversed(data["data"]))
    print(len(fbfeed))
    if len(fbfeed) == 0:
        return fbfeed

    indexes = dict((d["id"], dict(d, index=index)) for (index, d) in enumerate(fbfeed))

    if lastid in indexes:
        idx = indexes[lastid]["index"] + 1
        return fbfeed[idx:]

    #nextpage = data["paging"]["next"]
    #if nextpage:
    #    return get_feed(nextpage, i+1, lastid).extend(fbfeed)

    return fbfeed

def get_message(fbpost):
    """Retrieves message from a fb post"""
    if "message" in fbpost:
        return fbpost["message"]
    elif "story" in fbpost:
        return fbpost["story"]
    else:
        return ""

def indent(elem, level=0):
    '''Indents XML documnet'''
    i = "\n" + level*"  "
    if len(elem):
        if not elem.text or not elem.text.strip():
            elem.text = i + "  "
        if not elem.tail or not elem.tail.strip():
            elem.tail = i
        for elem in elem:
            indent(elem, level+1)
        if not elem.tail or not elem.tail.strip():
            elem.tail = i
    else:
        if level and (not elem.tail or not elem.tail.strip()):
            elem.tail = i

def download_file(url, id, folder):
    os.makedirs(folder, 0o666, True)
    path = folder + "/" + id + "-" + get_url_filename(url)
    print("Downloading "+url+" into "+path)
    if not os.path.isfile(path):
        urllib.request.urlretrieve(url, path)
    return path

def get_thumbnail(fbpost):
    if not "full_picture" in fbpost:
        return ""
    url = fbpost["full_picture"]
    return download_file(url, fbpost["id"], "thumbnails")

def get_data(fbpost):
    if "object_id" in fbpost and "photo" == fbpost["type"]:
        return get_data_photo(fbpost)
    if "object_id" in fbpost and "video" == fbpost["type"]:
        return get_data_video(fbpost)
    if "link" in fbpost and "link" == fbpost["type"]:
        return get_data_link(fbpost)
    return ""

def get_data_photo(fbpost):
    url = graph_api + fbpost["object_id"] + "?fields=images&access_token=" + token
    print(url)
    with urllib.request.urlopen(url) as response:
        data = json.loads(response.read().decode("utf-8"))
    images = data["images"]
    sorted(images, key=lambda k: k['width']*k['height'], reverse=True)
    return download_file(images[0]["source"],  fbpost["id"], "photos")

def get_data_video(fbpost):
    url = graph_api + fbpost["object_id"] + "?fields=source&access_token=" + token
    print(url)
    with urllib.request.urlopen(url) as response:
        data = json.loads(response.read().decode("utf-8"))
    return download_file(data["source"],  fbpost["id"], "videos")

def get_data_link(fbpost):
    return ""

def get_xmlelement(fbpost):
    """Retrieves XML element for a post"""
    el = ET.Element("post")
    ET.SubElement(el, "id").text = fbpost["id"]
    ET.SubElement(el, "type").text = fbpost["type"]
    ET.SubElement(el, "permalink").text = fbpost["permalink_url"]
    ET.SubElement(el, "author").text = fbpost["from"]["name"]
    ET.SubElement(el, "timestamp").text = fbpost["updated_time"]
    ET.SubElement(el, "text").text = get_message(fbpost)
    ET.SubElement(el, "thumbnail").text = get_thumbnail(fbpost)
    ET.SubElement(el, "data").text = get_data(fbpost)
    return el

tree = ET.parse('feed.xml')
root = tree.getroot()
ids = root.findall("./post/id")
if len(ids) > 0:
    last_id = ids[0].text
else:
    last_id = ""

token = "EAAYKEFkRUekBALvUVuZAiF9gXpFBxj3G7MEcr07lUl1qdi1Y8EvF3ku78x54oKE9O3SsuZANI4ZBXFMYcbw0F15OpaIIP1ZAQeBxZACe7TyC9b3tZBFWr9SUovLAWs69gtLBrErrn3oMIOmpRBCw9GZBd3rYP7DJpoZD"
group_id = "484923048324193"
graph_api = "https://graph.facebook.com/v2.8/"
feed = get_feed(graph_api+group_id+"/feed?fields=updated_time,type,link,child_attachments,caption,description,object_id,from,full_picture,message,picture,permalink_url,story&access_token=" + token, 0, last_id) 


for post in feed:
    print(post["id"]+" "+post["type"]+" "+get_message(post))
    root.insert(0, get_xmlelement(post))

indent(root)
tree = ET.ElementTree(root)
tree.write('feed.xml')

print ("Done")





