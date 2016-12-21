# Facebook group backup

Downloads content of a Facebook group to a local drive, including attached to the post photos and videos.

## How to use:

Go to [dev.mayorov.photography](http://dev.mayorov.photography) to authenticate on Facebook and download installation package

## Prerequisites:
*   Python 3

## What is in the package
*   feed.py - main script, retrieves the backup of a facebook group
*   feed.xsl - transformation script for the XML created by feed.py
*   feed.css - css for the transformed XML
*   fbgroupbackup.sh - example of a bash script to retrieve a backup of a group
*   fbgroupbackupcron - example of a cron job to download daily backup of a group
*   fbgroupbackuphttpd - example of a http daemon to show the backed up group contents
*   index.html - example of a default index page which redirects to group backup xml

## How does it work
The python 3 script feed.py uses Facebook API to download contents of a group.  
Everytime script runs it retrieves all posts in the group since the last execution of the script.  
The posts are saved in an XML file named feed-<group_id>.xml.  
All content linked to a post, like attached photos, facebook videos as well as certain types of linked content is downloaded locally into data folder. If linked content is not supported, only thumbnail ttview is downloaded.

### Supported external content:
*   Giphy
*   Google Photos shared video or gifs (googleusercontent)

