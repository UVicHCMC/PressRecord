<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    exclude-result-prefixes="#all"
    xmlns:pr="http://hcmc.uvic.ca/ns/PressRecord"
    xmlns:sch="http://purl.oclc.org/dsdl/schematron"
    xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns="http://www.tei-c.org/ns/1.0"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    xmlns:teix="http://www.tei-c.org/ns/Examples"
    version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Oct 6, 2026</xd:p>
            <xd:p><xd:b>Author:</xd:b> mholmes</xd:p>
            <xd:p>This populates such things as valLists in the PressRecord
            ODD file based on taxonomies maintained in its header.</xd:p>
        </xd:desc>
    </xd:doc>
    
    <xd:doc>
        <xd:desc>We'll include the global XSLT to get paths etc.</xd:desc>
    </xd:doc>
    <xsl:include href="module_globals.xsl"/>
    
    <xd:doc>
        <xd:desc>This is an identity transform, TEI in and TEI out.</xd:desc>
    </xd:doc>
    <xsl:output method="xml" encoding="UTF-8" normalization-form="NFC" exclude-result-prefixes="#all" indent="yes"/>
    <xsl:mode on-no-match="shallow-copy"/>
    
    <xd:doc>
        <xd:desc>The taxonomies file lives alongside the ODD file, and contains all the 
        categories we'll use to build out attribute valLists.</xd:desc>
    </xd:doc>
    <xsl:variable name="taxonomies" as="document-node()" select="doc($projDir || 'xml/taxonomies.xml')"/>
    
    <xd:doc>
        <xd:desc>The release/@type attribute gets its values from a taxonomy.</xd:desc>
    </xd:doc>
    <xsl:template match="elementSpec[@ident eq 'release']/attList/attDef[@ident eq 'type']/valList">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:for-each select="$taxonomies//taxonomy[@xml:id eq 'taxReleaseType']//category">
                <xsl:sort select="lower-case(child::gloss)"/>
                <valItem ident="{@xml:id}">
                    <xsl:apply-templates select="child::gloss"/>
                    <xsl:apply-templates select="child::desc"/>
                </valItem>
            </xsl:for-each>
        </xsl:copy>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Hereafter things to be thrown away, including 
        default attributes.</xd:desc>
    </xd:doc>
    <xsl:template match="@predeclare | @part | div/@org | attDef/@ns | attList/@org  | content/@autoPrefix"/>
    
</xsl:stylesheet>