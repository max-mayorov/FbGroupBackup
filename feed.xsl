<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:template match="/">
<!DOCTYPE html>
<html>
<head>
  <link rel="stylesheet" href="feed.css">
  <title><xsl:value-of select="feed/@name" /></title>
</head> 
<body>
  <h2>FB Group Feed</h2>
  <div class="container">
    <xsl:for-each select="feed/post">
      <div class="item">
        <div class="image">
          <a href="{data}">
            <img src="{thumbnail}"/>
          </a>
        </div>
        <div class="metadata">
          <a class="postid" href="{permalink}"><xsl:value-of select="id"/></a>
          <span class="type"><xsl:value-of select="type"/></span>
          <span class="author"><xsl:value-of select="author"/></span>
          <span class="timestamp"><xsl:value-of select="timestamp"/></span>
        </div>  
        <div class="text">
          <xsl:value-of select="text"/>
        </div>
      </div>
      <div class="spacer"></div>
    </xsl:for-each>
  </div>
</body>
</html>
</xsl:template>
</xsl:stylesheet>

