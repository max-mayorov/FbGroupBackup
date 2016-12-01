<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:template name="insertBreaks">
  <xsl:param name="pText" select="."/>

  <xsl:choose>
    <xsl:when test="not(contains($pText, '&#xA;'))">
      <xsl:copy-of select="$pText"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="substring-before($pText, '&#xA;')"/>
      <br />
      <xsl:call-template name="insertBreaks">
        <xsl:with-param name="pText" select=
          "substring-after($pText, '&#xA;')"/>
      </xsl:call-template>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="/">
<html>
<head>
  <link rel="stylesheet" href="feed.css"/>
  <title><xsl:value-of select="/feed/@name" /></title>
</head> 
<body>
  <div class="title">
    <h2><xsl:value-of select="/feed/@name" /></h2>
    <h3><xsl:value-of select="/feed/@description" /></h3>
  </div>
  <div class="container">
    <div class="spacer"></div>
    <xsl:for-each select="feed/post">
      <div class="item">
        <div class="image">
          <a href="{data}">
            <img src="{thumbnail}"/>
          </a>
        </div>
        <div class="metadata">
          <img src="img/{type}.png"/>
          <span class="postid"><xsl:value-of select="id"/></span>
          <span class="type"><a href="{permalink}"><xsl:value-of select="type"/></a></span>
          <span class="author"><xsl:value-of select="author"/></span>
          <span class="timestamp"><xsl:value-of select="timestamp"/></span>
        </div>  
        <div class="text">
          <xsl:call-template name="insertBreaks" >
            <xsl:with-param name="pText" select="text" />
          </xsl:call-template>
        </div>
      </div>
      <div class="spacer"></div>
    </xsl:for-each>
  </div>
  <div class="creds">Icons made by <a href="http://www.flaticon.com/authors/madebyoliver" title="Madebyoliver">Madebyoliver</a> from <a href="http://www.flaticon.com" title="Flaticon">www.flaticon.com</a> is licensed by <a href="http://creativecommons.org/licenses/by/3.0/" title="Creative Commons BY 3.0" target="_blank">CC 3.0 BY</a></div>
</body>
</html>
</xsl:template>
</xsl:stylesheet>

