<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:template match="/">
<html> 
<body>
  <h2>FB Group Feed</h2>
  <table border="1">
    <tr bgcolor="#9acd32">
      <th style="text-align:left">id</th>
      <th style="text-align:left">type</th>
      <th style="text-align:left">author</th>
      <th style="text-align:left">timestamp</th>
      <th style="text-align:left">image</th>
      <th style="text-align:left">text</th>
    </tr>
    <xsl:for-each select="feed/post">
    <tr>
      <td><a href="{permalink}"><xsl:value-of select="id"/></a></td>
      <td><xsl:value-of select="type"/></td>
      <td><xsl:value-of select="author"/></td>
      <td><xsl:value-of select="timestamp"/></td>
      <td><a href="{data}"><img src="{thumbnail}"/></a></td>
      <td><xsl:value-of select="text"/></td>
    </tr>
    </xsl:for-each>
  </table>
</body>
</html>
</xsl:template>
</xsl:stylesheet>

