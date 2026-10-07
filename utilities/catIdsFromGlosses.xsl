<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    exclude-result-prefixes="#all"
    xmlns="http://www.tei-c.org/ns/1.0"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Sep 25, 2026</xd:p>
            <xd:p><xd:b>Author:</xd:b> mholmes</xd:p>
            <xd:p>This is a utility to create ids for category elements based on their glosses.</xd:p>
        </xd:desc>
    </xd:doc>
    
    <xsl:output method="xml" indent="yes" encoding="UTF-8" exclude-result-prefixes="#all"/>
    
    <xsl:mode on-no-match="shallow-copy"/>
    
    <xsl:template match="category[matches(@xml:id, '^[a-z]{1,4}$')][@xml:id=following-sibling::category/@xml:id or @xml:id=preceding-sibling::category/@xml:id]/@xml:id">
        <xsl:attribute name="xml:id" select=". || replace(replace(normalize-space(parent::category/child::gloss/text()), '[^a-zA-Z0-9\-]+', '_'), '(^_|_$)', '')"/>
    </xsl:template>
    
    <!-- @#*&(*%^^ default attributes begone. -->
    <xsl:template match="@part"/>
    
</xsl:stylesheet>