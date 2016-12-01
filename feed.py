"""Retrieves facebook group feed and saves all posts to XML"""

import urllib.request
import json
import xml.etree.ElementTree as ET
import os
import re
import sys
import logging
import datetime
import time

os.makedirs("log", 0o766, True)
logging.basicConfig(
    filename="log/feed-{}.log".format(datetime.datetime.now().strftime('%Y%m%d-%H%M%S.%f')),
    level=logging.INFO, format='%(asctime)s %(message)s')


with open('settings.json') as settings_file:
    SETTINGS = json.load(settings_file)

TOKEN = SETTINGS["token"]
GROUP_ID = SETTINGS["group_id"]
GRAPH_API = "https://graph.facebook.com/v2.8/"

def get_graph_url(endpoint, fields):
    """Generates Graph API url for endpoint and fields"""
    return "{}{}?fields={}&access_token={}".format(GRAPH_API, endpoint, fields, TOKEN)

def get_feed(url, i, last_timestamp=None):
    """Retrieves feed from FB group"""
    if last_timestamp:
        url += "&since=" + str(last_timestamp)

    with urllib.request.urlopen(url) as response:
        data = json.loads(response.read().decode("utf-8"))

    logging.info("Downloading: %s", url)
    logging.info("Page %s", i)

    fbfeed = list(reversed(data["data"]))
    logging.info("Retrieved %s items", len(fbfeed))
    if len(fbfeed) == 0:
        return fbfeed

    # indexes = dict((d["id"], dict(d, index=index)) for (index, d) in enumerate(fbfeed))

    # if lastid in indexes:
    #     idx = indexes[lastid]["index"] + 1
    #     return fbfeed[idx:]

    nextpage = data["paging"]["next"]
    if nextpage:
        new_feed = get_feed(nextpage, i+1)
        if new_feed:
            new_feed.extend(fbfeed)
            return new_feed

    return fbfeed

def get_group_meta():
    """Retrieves meta information for the group"""
    with urllib.request.urlopen(get_graph_url(GROUP_ID, "name,description")) as response:
        data = json.loads(response.read().decode("utf-8"))
    return data

def get_message(fbpost):
    """Retrieves message from a fb post"""
    if "message" in fbpost:
        message = fbpost["message"]
    elif "story" in fbpost:
        message = fbpost["story"]
    else:
        message = ""

    if fbpost["type"] == "status" \
        and "attachments" in fbpost \
        and len(fbpost["attachments"]["data"]) == 1 \
        and "description" in fbpost["attachments"]["data"][0]:
        message += "\n\r" + fbpost["attachments"]["data"][0]["description"]

    return message

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
    folder = "data/" + folder
    os.makedirs(folder, 0o777, True)
    filename = url.split("?")[0].split("/")[-1]
    logging.info("Downloading %s", url)

    req = urllib.request.Request(url, method='HEAD')
    try:
        head = urllib.request.urlopen(req)
    except:
        logging.error("Unexpected error downloading %s: %s", url, sys.exc_info()[0])
        return url
    else:
        c_fn = head.info().get_filename()
        if c_fn:
            filename = c_fn

    path = folder + "/" + id + "-" + filename
    if not os.path.isfile(path):
        try:
            urllib.request.urlretrieve(url, path)
        except:
            logging.error("Unexpected error downloading %s: %s", url, sys.exc_info()[0])
            return url
    else:
        logging.info("File %s exists, skipping download", path)

    return path

def get_thumbnail(fbpost):
    """Downloads thumbnail for the post"""
    url = None
    if "full_picture" in fbpost:
        url = fbpost["full_picture"]
    elif fbpost["type"] == "status" \
        and "attachments" in fbpost \
        and len(fbpost["attachments"]["data"]) \
        and "media" in fbpost["attachments"]["data"][0] \
        and "image" in fbpost["attachments"]["data"][0]["media"]:
        url = fbpost["attachments"]["data"][0]["media"]["image"]["src"]

    if url:
        return download_file(url, fbpost["id"], "thumbnails")
    else:
        return ""

def get_data(fbpost):
    if "object_id" in fbpost and fbpost["type"] == "photo":
        return get_data_photo(fbpost)
    if "object_id" in fbpost and fbpost["type"] == "video":
        return get_data_video(fbpost)
    if "link" in fbpost and fbpost["type"] == "link":
        return get_data_link(fbpost)
    if fbpost["type"] == "status" and "attachments" in fbpost \
        and len(fbpost["attachments"]["data"]) > 0:
        return get_data_first_attachment(fbpost)
    logging.warning("Unable to determine post data, postid=%s", fbpost["id"])
    return ""

def get_data_first_attachment(fbpost):
    if "media" in fbpost["attachments"]["data"][0] \
        and "image" in fbpost["attachments"]["data"][0]["media"]:
        return download_file(fbpost["attachments"]["data"][0]["media"]["image"]["src"],
                             fbpost["id"], "attachment")
    return ""

def get_data_photo(fbpost):
    url = get_graph_url(fbpost["object_id"], "images")
    logging.info("Downloading data photo: %s", url)
    with urllib.request.urlopen(url) as response:
        data = json.loads(response.read().decode("utf-8"))
    images = data["images"]
    sorted(images, key=lambda k: k['width']*k['height'], reverse=True)
    return download_file(images[0]["source"], fbpost["id"], "photos")

def get_data_video(fbpost):
    url = get_graph_url(fbpost["object_id"], "source")
    logging.info("Downloading data video: %s", url)
    with urllib.request.urlopen(url) as response:
        data = json.loads(response.read().decode("utf-8"))
    return download_file(data["source"], fbpost["id"], "videos")

def get_data_link(fbpost):
    if re.search("googleusercontent.com$", fbpost["caption"]):
        return get_data_link_google(fbpost)
    elif re.search("giphy.com$", fbpost["caption"]):
        return get_data_link_giphy(fbpost)

    logging.warning("Data link unknown: %s", fbpost["caption"])

    return fbpost["link"]

def get_data_link_giphy(fbpost):
    url = fbpost["link"]

    logging.info("Downloading from Giphy: %s", url)

    # retrieve final url/possible redirects
    req = urllib.request.Request(url, method='HEAD')
    try:
        head = urllib.request.urlopen(req)
    except:
        logging.error("Unexpected error downloading %s : %s", url, sys.exc_info()[0])
        return url

    url = head.geturl()

    match = re.search("[a-zA-Z0-9]+$", url)

    if match:
        return download_file("http://i.giphy.com/"+match.group()+".gif", fbpost["id"], "giphy")

    logging.warning("Giphy pattern doesn't match: %s", url)
    return url

def get_data_link_google(fbpost):
    logging.info("Downloading from google: %s", fbpost["link"])
    return download_file(fbpost["link"], fbpost["id"], "googleusercontent")

def get_xmlelement(fbpost):
    """Retrieves XML element for a post"""
    element = ET.Element("post")
    ET.SubElement(element, "id").text = fbpost["id"]
    ET.SubElement(element, "type").text = fbpost["type"]
    ET.SubElement(element, "permalink").text = fbpost["permalink_url"]
    ET.SubElement(element, "author").text = fbpost["from"]["name"]
    ET.SubElement(element, "updatedTime").text = fbpost["updated_time"]
    ET.SubElement(element, "createdTime").text = fbpost["created_time"]
    ET.SubElement(element, "timestamp").text = str(datetime_to_timestamp(fbpost["created_time"]))
    ET.SubElement(element, "text").text = get_message(fbpost)
    ET.SubElement(element, "thumbnail").text = get_thumbnail(fbpost)
    ET.SubElement(element, "data").text = get_data(fbpost)
    return element

def datetime_to_timestamp(xml_datetime):
    """Retrieves Unix time corresponding to an xml date time"""
    dt_ = time.strptime(xml_datetime, '%Y-%m-%dT%H:%M:%S+0000')
    return int(time.mktime(dt_))

def main():
    feedxml_file = 'feed-'+GROUP_ID+'.xml'

    logging.info(" ")
    logging.info("=====  START  %s  =====", GROUP_ID)

    if not os.path.isfile(feedxml_file):
        with open(feedxml_file, "w") as feed_file:
            feed_file.write('<?xml version="1.0" encoding="UTF-8"?>\n'
                            '<?xml-stylesheet type="text/xsl" href="feed.xsl" ?>\n<feed>\n</feed>')

    group_meta = get_group_meta()
    tree = ET.parse(feedxml_file)
    root = tree.getroot()
    root.set("name", group_meta["name"])
    root.set("description", group_meta["description"])
    timestamps = list(map(lambda p: int(p.text), root.findall("./post/timestamp")))
    ids = list(map(lambda p: p.text, root.findall("./post/id")))


    if len(timestamps) > 0:
        last_timestamp = max(timestamps)
        logging.info("Last downloaded timestamp: %s", last_timestamp)
    else:
        last_timestamp = None

    feed = get_feed(get_graph_url(GROUP_ID+"/feed",
                                  "updated_time,type,link,caption,created_time,description,"
                                  "story,from,full_picture,message,picture,permalink_url,"
                                  "object_id,attachments"),
                    0, last_timestamp)

    for post in feed:
        logging.info("GET POST %s OF TYPE %s", post["id"], post["type"])
        if post["id"] not in ids:
            root.insert(0, get_xmlelement(post))

    indent(root)

    fake_root = ET.Element(None)
    stylesheet = ET.PI("xml-stylesheet", 'type="text/xsl" href="feed.xsl"')
    stylesheet.tail = "\n"
    fake_root.append(stylesheet)

    # Add real root as last child of fake root
    fake_root.append(root)

    tree = ET.ElementTree(fake_root)

    tree.write(feedxml_file, encoding="UTF-8", xml_declaration=True)

    logging.info("Done")

if __name__ == "__main__":
    main()