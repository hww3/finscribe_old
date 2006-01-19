<?xml version="1.0" encoding="iso-8859-1"?>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:widget="http://thedogstar.org/projects/Fins/Widget">

  <xsl:output
    indent="yes"
    version="1.0"
    media-type="text/html"
    method="xml"
    doctype-system="http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd"
    doctype-public="-//W3C//DTD XHTML 1.1//EN"
    encoding="iso-8859-1" />

    <!--
  <xsl:comment>
    This XSL stylesheet translates widgets into XHTML/1.1 for sending to a client.
    Yippie :)
  </xsl:comment>
  -->

  <xsl:template match="/widget:page">
    <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
      <head>
	<xsl:if test="widget:profile">
	  <xsl:attribute name="widget:profile">
	    <xsl:value-of select="widget:profile/@uri" />
	  </xsl:attribute>
	</xsl:if>
	<xsl:if test="@title">
	  <title><xsl:value-of select="@title" /></title>
	</xsl:if>
      </head>
      <body>
	<xsl:apply-templates />
      </body>
    </html>
  </xsl:template>

  <xsl:template match="widget:a">
    <a xmlns="http://www.w3.org/1999/xhtml">
      <!-- can't think of a way to copy recursively because <xsl:attribute name= must be a string constant? -->
      <xsl:if test="@charset">
	<xsl:attribute name="charset">
	  <xsl:value-of select="@charset" />
	</xsl:attribute>
      </xsl:if>
      <xsl:if test="@coords">
	<xsl:attribute name="coords">
	  <xsl:value-of select="@coords" />
	</xsl:attribute>
      </xsl:if>
      <xsl:if test="@href">
	<xsl:attribute name="href">
	  <xsl:value-of select="@href" />
	</xsl:attribute>
      </xsl:if>
      <xsl:if test="@hreflang">
	<xsl:attribute name="hreflang">
	  <xsl:value-of select="@hreflang" />
	</xsl:attribute>
      </xsl:if>
      <xsl:if test="@name">
	<xsl:attribute name="name">
	  <xsl:value-of select="@name" />
	</xsl:attribute>
      </xsl:if>
      <xsl:if test="@rel">
	<xsl:attribute name="rel">
	  <xsl:value-of select="@rel" />
	</xsl:attribute>
      </xsl:if>
      <xsl:if test="@rev">
	<xsl:attribute name="rev">
	  <xsl:value-of select="@rev" />
	</xsl:attribute>
      </xsl:if>
      <xsl:if test="@shape">
	<xsl:attribute name="shape">
	  <xsl:value-of select="@shape" />
	</xsl:attribute>
      </xsl:if>
      <xsl:if test="@target">
	<xsl:attribute name="target">
	  <xsl:value-of select="@target" />
	</xsl:attribute>
      </xsl:if>
      <xsl:if test="@type">
	<xsl:attribute name="type">
	  <xsl:value-of select="@type" />
	</xsl:attribute>
      </xsl:if>
      <xsl:apply-templates />
    </a>
  </xsl:template>

  <xsl:template match="widget:br">
    <br xmlns="http://www.w3.org/1999/xhtml" />
  </xsl:template>

  <xsl:template match="widget:hr">
    <hr xmlns="http://www.w3.org/1999/xhtml" />
  </xsl:template>

  <xsl:template match="widget:p">
    <p xmlns="http://www.w3.org/1999/xhtml">
      <xsl:apply-templates />
    </p>
  </xsl:template>

  <xsl:template match="widget:text">
    <xsl:value-of select="." />
  </xsl:template>

</xsl:stylesheet>