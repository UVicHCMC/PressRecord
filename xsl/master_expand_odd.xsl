<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:math="http://www.w3.org/2005/xpath-functions/math"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  xmlns:hcmc="http://hcmc.uvic.ca/ns"
  xmlns:pr="http://hcmc.uvic.ca/ns/PressRecord"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  xmlns:rng="http://relaxng.org/ns/structure/1.0"
  xmlns:sch="http://purl.oclc.org/dsdl/schematron"
  xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
  xmlns:xh="http://www.w3.org/1999/xhtml"
  xmlns="http://www.tei-c.org/ns/1.0"
  xpath-default-namespace="http://www.tei-c.org/ns/1.0"
  exclude-result-prefixes="#all"
  version="3.0">

  <xd:doc scope="stylesheet">
    <xd:desc>
      <xd:p><xd:b>Created on:</xd:b> October 13, 2026</xd:p>
      <xd:p><xd:b>Author:</xd:b> HCMC</xd:p>
      <xd:p>Builds the PressRecord ODD specifications and controlled-value
        datatypes from the local taxonomy and mapping files.</xd:p>
    </xd:desc>
  </xd:doc>

  <xsl:include href="module_globals.xsl"/>

  <xsl:output method="xml" encoding="UTF-8" normalization-form="NFC"
    indent="yes" exclude-result-prefixes="#all"/>

  <xsl:mode name="identity" on-no-match="shallow-copy" exclude-result-prefixes="#all"/>
  <!-- Taxonomies file -->
  <xsl:variable name="taxonomies" as="document-node()" select="doc($projDir || 'xml/taxonomies.xml')"/>
  <!-- Mapping file that captures each element's name as used in record files and their parent elements as per the taxonomy.  -->
  <xsl:variable name="mappingsDocument" as="document-node()" select="doc($projDir || 'sch/taxonomyMappings.xml')"/>

  <xd:doc>
    <xd:desc>We validate the mapping inputs before producing any output.</xd:desc>
  </xd:doc>
  <xsl:template match="/">
    <xsl:message>Validating taxonomy mappings and authored content models.</xsl:message>
    <xsl:call-template name="hcmc:validateInputs">
      <xsl:with-param name="sourceOdd" select="."/>
    </xsl:call-template>
    <xsl:call-template name="hcmc:generateTaxonomyODD"/>
  </xsl:template>

  <xd:doc>
    <xd:desc>This runs a bunch of validation checks on the input ODD document and fails immediately if any issues are detected.
    </xd:desc>
  </xd:doc>
  <xsl:template name="hcmc:validateInputs">
    <xsl:param name="sourceOdd" as="document-node()"/>
    <xsl:variable name="fields" as="element(pr:field)+"
      select="$mappingsDocument/pr:taxonomyMappings/pr:fields/pr:field"/>
    <xsl:variable name="taxonomiesInSource" as="element(tei:taxonomy)+"
      select="$taxonomies//tei:taxonomy[@xml:id]"/>
    <xsl:variable name="schema" as="element(tei:schemaSpec)?"
      select="$sourceOdd//tei:schemaSpec[@ident eq 'PressRecord']"/>
    <xsl:variable name="shared" as="element(pr:sharedVocabulary)+"
      select="$mappingsDocument/pr:taxonomyMappings/pr:sharedVocabularies/pr:sharedVocabulary"/>
    <xsl:variable name="newFields" as="element(pr:field)+"
      select="$fields[not(@existing eq 'true')]"/>
    <xsl:variable name="datatypeNames" as="xs:string*"
      select="$shared/@dataSpec/string()"/>
    <xsl:variable name="ids" as="xs:string*"
      select="$taxonomiesInSource/tei:category/@xml:id/string()"/>

    <xsl:if test="empty($schema)">
      <xsl:message terminate="yes">PROBLEM: schemaSpec PressRecord is missing.</xsl:message>
    </xsl:if>
    <xsl:if test="count($sourceOdd//tei:schemaSpec[@ident eq 'PressRecord']) ne 1">
      <xsl:message terminate="yes">PROBLEM: expected exactly one PressRecord schemaSpec.</xsl:message>
    </xsl:if>
    <xsl:if test="count($schema/tei:elementSpec[@ident eq 'gameplayRecord']) ne 1 or count($schema/tei:elementSpec[@ident eq 'platformEdition']) ne 1 or count($schema/tei:elementSpec[@ident eq 'title']) ne 1 or count($schema/tei:elementSpec[@ident eq 'release']) ne 1">
      <xsl:message terminate="yes">PROBLEM: a required hand-authored record elementSpec is missing or duplicated.</xsl:message>
    </xsl:if>
    <xsl:if test="count($schema/tei:moduleSpec[@ident eq 'PressRecord']) ne 1">
      <xsl:message terminate="yes">PROBLEM: expected exactly one PressRecord moduleSpec insertion point.</xsl:message>
    </xsl:if>
    <xsl:if test="count($schema/tei:elementSpec[@ident eq 'release']/tei:attList/tei:attDef[@ident eq 'year'][@usage eq 'req']) ne 1 or count($schema/tei:elementSpec[@ident eq 'release']/tei:attList/tei:attDef[@ident eq 'type'][@usage eq 'req']) ne 1">
      <xsl:message terminate="yes">PROBLEM: release must retain required @year and @type attributes.</xsl:message>
    </xsl:if>
    <xsl:if test="count($fields/@taxonomy) ne count(distinct-values($fields/@taxonomy))">
      <xsl:message terminate="yes">[mappings]: PROBLEM: taxonomy mappings contain duplicate taxonomy IDs.</xsl:message>
    </xsl:if>
    <xsl:if test="count($shared/@taxonomy) ne count(distinct-values($shared/@taxonomy)) or count($datatypeNames) ne count(distinct-values($datatypeNames))">
      <xsl:message terminate="yes">[mappings]: PROBLEM: shared vocabulary declarations contain duplicate IDs.</xsl:message>
    </xsl:if>
    <xsl:if test="count($fields[@existing eq 'true']) ne 1">
      <xsl:message terminate="yes">[mappings]: PROBLEM: exactly one existing vocabulary field is required.</xsl:message>
    </xsl:if>
    <xsl:if test="count($newFields/@element) ne count(distinct-values($newFields/@element))">
      <xsl:message terminate="yes">[mappings]: PROBLEM: taxonomy mappings contain duplicate element names.</xsl:message>
    </xsl:if>
    <xsl:if test="exists($fields[not(@taxonomy = $taxonomiesInSource/@xml:id)])">
      <xsl:message terminate="yes">[mappings]: PROBLEM: a field mapping references an unknown taxonomy.</xsl:message>
    </xsl:if>
    <xsl:if test="exists($taxonomiesInSource[not(@xml:id eq 'taxCountries')][not(@xml:id = $fields/@taxonomy)])">
      <xsl:message terminate="yes">[mappings]: PROBLEM: a field taxonomy has no mapping.</xsl:message>
    </xsl:if>
    <xsl:if test="exists($fields[not(@minOccurs castable as xs:integer) or not(@minOccurs = ('0', '1')) or not(@maxOccurs = ('1', 'unbounded'))])">
      <xsl:message terminate="yes">[mappings]: PROBLEM: occurrence limits must use minOccurs 0 or 1 and maxOccurs 1 or unbounded.</xsl:message>
    </xsl:if>
    <xsl:if test="exists($fields[not(@parent = ('platformEdition', 'gameplayFile', 'gameplaySettings', 'gameplayFootage', 'gameplayInstruction'))])">
      <xsl:message terminate="yes">[mappings]: PROBLEM: a field has an unsupported parent.</xsl:message>
    </xsl:if>
    <xsl:for-each select="$fields">
      <xsl:variable name="section" as="xs:string"
        select="substring(string($taxonomiesInSource[@xml:id eq current()/@taxonomy]/@n), 1, 1)"/>
      <xsl:variable name="expectedParent" as="xs:string?"
        select="('platformEdition', 'gameplayFile', 'gameplaySettings', 'gameplayFootage', 'gameplayInstruction')[position() eq xs:integer($section) - 2]"/>
      <xsl:if test="not(@parent eq $expectedParent)">
        <xsl:message terminate="yes">[mappings]: PROBLEM: field parents do not match their taxonomy section.</xsl:message>
      </xsl:if>
      <xsl:if test="count($schema/elementSpec[@ident eq current()/@parent]/content//elementRef[@key eq current()/@element]) ne 1">
        <xsl:message terminate="yes">[mappings]: PROBLEM: each mapped field must occur once in its authored parent content model.</xsl:message>
      </xsl:if>
    </xsl:for-each>
    <xsl:if test="exists($fields[@existing eq 'true'][not(@taxonomy eq 'taxReleaseType' and @element eq 'release' and @attribute eq 'type')])">
      <xsl:message terminate="yes">[mappings]: PROBLEM: the existing-field exception must map taxReleaseType to release/@type.</xsl:message>
    </xsl:if>
    <xsl:if test="exists($fields[not(@existing eq 'true')][@taxonomy eq 'taxReleaseType'])">
      <xsl:message terminate="yes">[mappings]: PROBLEM: taxReleaseType must use the existing release/@type attribute.</xsl:message>
    </xsl:if>
    <xsl:if test="exists($shared[not(@taxonomy = $taxonomiesInSource/@xml:id)])">
      <xsl:message terminate="yes">[mappings]: PROBLEM: a shared vocabulary reference is unresolved.</xsl:message>
    </xsl:if>
    <xsl:if test="exists($fields[@sharedVocabulary][not(@sharedVocabulary = $shared/@taxonomy)])">
      <xsl:message terminate="yes">[mappings]: PROBLEM: a field references an undeclared shared vocabulary.</xsl:message>
    </xsl:if>
    <xsl:if test="exists($schema/*[self::tei:dataSpec or self::tei:macroSpec][@ident = $datatypeNames][not(preceding-sibling::comment()[contains(., 'DO NOT EDIT THE VALUES HERE. THEY ARE GENERATED FROM THE TAXONOMIES.XML FILE')][1] and following-sibling::comment()[contains(., 'END OF SECTION GENERATED FROM TAXONOMIES.XML FILE')][1])])">
      <xsl:message terminate="yes">PROBLEM: a generated datatype name collides with an authored ODD declaration.</xsl:message>
    </xsl:if>
    <xsl:if test="count($ids) ne count(distinct-values($ids))">
      <xsl:message terminate="yes">[taxonomies]: PROBLEM: category IDs are not unique.</xsl:message>
    </xsl:if>
    <xsl:if test="exists($taxonomiesInSource/tei:category[not(@xml:id) or not(tei:gloss)])">
      <xsl:message terminate="yes">[taxonomies]: PROBLEM: each category must have an ID and gloss.</xsl:message>
    </xsl:if>
    <xsl:if test="exists($newFields[not(@taxonomy = $taxonomiesInSource/@xml:id)])">
      <xsl:message terminate="yes">[mappings]: PROBLEM: a generated field taxonomy is unresolved.</xsl:message>
    </xsl:if>
    <xsl:if test="exists($schema/tei:elementSpec[@ident = $newFields/@element][not(preceding-sibling::comment()[contains(., 'DO NOT EDIT THE VALUES HERE. THEY ARE GENERATED FROM THE TAXONOMIES.XML FILE')][1] and following-sibling::comment()[contains(., 'END OF SECTION GENERATED FROM TAXONOMIES.XML FILE')][1])])">
      <xsl:message terminate="yes">PROBLEM: a generated element name collides with a hand-authored elementSpec.</xsl:message>
    </xsl:if>
    <xsl:if test="count($schema/comment()[contains(., 'DO NOT EDIT THE VALUES HERE. THEY ARE GENERATED FROM THE TAXONOMIES.XML FILE')]) ne count($schema/comment()[contains(., 'END OF SECTION GENERATED FROM TAXONOMIES.XML FILE')]) or count($schema/comment()[contains(., 'DO NOT EDIT THE VALUES HERE. THEY ARE GENERATED FROM THE TAXONOMIES.XML FILE')]) gt 1">
      <xsl:message terminate="yes">PROBLEM: generated ODD region markers are unmatched or duplicated.</xsl:message>
    </xsl:if>
    <xsl:if test="exists($shared[not(@taxonomy = $taxonomies//tei:taxonomy[tei:category]/@xml:id)])">
      <xsl:message terminate="yes">[taxonomies]: PROBLEM: a shared vocabulary has no categories.</xsl:message>
    </xsl:if>
  </xsl:template>

  <xsl:template name="hcmc:generateTaxonomyODD">
    <xsl:message>[PressRecord]: Generating ODD specifications and datatypes from local taxonomy files.</xsl:message>
    <xsl:apply-templates select="." mode="identity"/>
  </xsl:template>

  <xd:doc>
    Inserts the managed region containing the generated dataSpec and elementSpec declarations into the pre-existing ODD file.
  </xd:doc>
  <xsl:template name="hcmc:generateManagedRegion">
    <xsl:comment> DO NOT EDIT THE VALUES HERE. THEY ARE GENERATED FROM THE TAXONOMIES.XML FILE </xsl:comment>
    <xsl:call-template name="hcmc:generateSharedDataSpecs"/>
    <xsl:call-template name="hcmc:generateElements"/>
    <xsl:comment> END OF SECTION GENERATED FROM TAXONOMIES.XML FILE </xsl:comment>
  </xsl:template>

  <xd:doc>
    Generates the shared data specifications for the ODD file based on the taxonomy mappings file.
  </xd:doc>
  <xsl:template name="hcmc:generateSharedDataSpecs">
    <xsl:for-each select="$mappingsDocument/pr:taxonomyMappings/pr:sharedVocabularies/pr:sharedVocabulary">
      <xsl:variable name="vocabulary" as="element(tei:taxonomy)"
        select="$taxonomies//tei:taxonomy[@xml:id eq current()/@taxonomy]"/>
      <dataSpec ident="{@dataSpec}" module="PressRecord">
        <xsl:sequence select="$vocabulary/tei:desc"/>
        <xsl:call-template name="hcmc:makeTextValList">
          <xsl:with-param name="categories" select="$vocabulary/tei:category"/>
        </xsl:call-template>
      </dataSpec>
    </xsl:for-each>
  </xsl:template>

  <xd:doc>
    <xd:desc>
      <xd:ref name="hcmc:generateElements" type="template">hcmc:generateElements</xd:ref>
    </xd:desc>
    <xd:return>Element specifications for mapped field taxonomies.</xd:return>
  </xd:doc>
  <xsl:template name="hcmc:generateElements">
    <xsl:for-each select="$mappingsDocument/pr:taxonomyMappings/pr:fields/pr:field[not(@existing eq 'true')]">
      <xsl:variable name="field" as="element(pr:field)" select="."/>
      <xsl:variable name="taxonomy" as="element(tei:taxonomy)"
        select="$taxonomies//tei:taxonomy[@xml:id eq $field/@taxonomy]"/>
      <elementSpec ident="{$field/@element}" module="PressRecord">
        <xsl:choose>
          <xsl:when test="$field/@element eq 'publisher'">
            <gloss>Publisher</gloss>
            <desc>The publisher name as free text, classified by the Publisher Class vocabulary in @type.</desc>
          </xsl:when>
          <xsl:otherwise>
            <xsl:sequence select="$taxonomy/gloss"/>
            <xsl:sequence select="$taxonomy/tei:desc"/>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:choose>
          <xsl:when test="$field/@attribute">
            <content><textNode/></content>
            <attList><attDef ident="{$field/@attribute}" usage="req">
              <gloss>Publisher class</gloss>
              <valList type="closed">
                <xsl:call-template name="hcmc:makeValItems">
                  <xsl:with-param name="categories" select="$taxonomy/category"/>
                </xsl:call-template>
              </valList>
            </attDef></attList>
          </xsl:when>
          <xsl:otherwise>
            <content>
              <xsl:choose>
                <xsl:when test="$field/@sharedVocabulary">
                  <rng:choice>
                    <rng:ref name="{$mappingsDocument/pr:taxonomyMappings/pr:sharedVocabularies/pr:sharedVocabulary[@taxonomy eq $field/@sharedVocabulary]/@dataSpec}"/>
                    <rng:choice>
                      <xsl:for-each select="$taxonomy/category">
                        <xsl:sort select="lower-case(normalize-space(string(gloss)))"/>
                        <rng:value><xsl:value-of select="normalize-space(string(tei:gloss))"/></rng:value>
                        <!-- If there is a desc element, include it for the OxygenXML editor popup -->
                        <xsl:if test="tei:desc[1]">
                          <xsl:element name="documentation" namespace="http://relaxng.org/ns/compatibility/annotations/1.0">
                            <xsl:sequence select="tei:desc[1]/node()"/>
                          </xsl:element>
                        </xsl:if>
                      </xsl:for-each>
                    </rng:choice>
                  </rng:choice>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:call-template name="hcmc:makeTextValList">
                    <xsl:with-param name="categories" select="$taxonomy/category"/>
                  </xsl:call-template>
                </xsl:otherwise>
              </xsl:choose>
            </content>
          </xsl:otherwise>
        </xsl:choose>
      </elementSpec>
    </xsl:for-each>
  </xsl:template>

  <xd:doc>
    <xd:desc>
      <xd:ref name="hcmc:makeValItems" type="template">hcmc:makeValItems</xd:ref>
    </xd:desc>
    <xd:param name="categories">Taxonomy categories to represent as valItems.</xd:param>
    <xd:return>Sorted valItem elements with taxonomy IDs and glosses.</xd:return>
  </xd:doc>
  <xsl:template name="hcmc:makeValItems">
    <xsl:param name="categories" as="element(tei:category)+"/>
    <xsl:for-each select="$categories">
      <xsl:sort select="lower-case(normalize-space(string(tei:gloss)))"/>
      <xsl:sort select="@xml:id"/>
      <valItem ident="{@xml:id}">
        <gloss><xsl:sequence select="tei:gloss/node()"/></gloss>
        <xsl:if test="tei:desc">
          <!-- Copy over any pre-existing desc element from the taxonomies.xml file -->
          <desc><xsl:sequence select="tei:desc[1]/node()"/></desc>
        </xsl:if>
      </valItem>
    </xsl:for-each>
  </xsl:template>

  <xd:doc>
    <xd:desc>We turn taxonomy categories into a closed ODD value list for controlled text content.</xd:desc>
    <xd:param name="categories">Taxonomy categories with glosses for the text.</xd:param>
    <xd:return>A closed value list whose values are normalized taxonomy glosses.</xd:return>
  </xd:doc>
  <xsl:template name="hcmc:makeTextValList">
    <xsl:param name="categories" as="element(tei:category)+"/>
    <valList type="closed">
      <xsl:for-each select="$categories">
        <xsl:sort select="lower-case(normalize-space(string(gloss)))"/>
        <valItem ident="{normalize-space(string(tei:gloss))}">
        <xsl:if test="tei:desc[1]">
            <!-- Copy over any pre-existing desc element from the taxonomies.xml file -->
            <desc><xsl:sequence select="tei:desc[1]/node()"/></desc>
        </xsl:if>
        </valItem>
      </xsl:for-each>
    </valList>
  </xsl:template>

  <xd:doc>
    <xd:desc>Identity transform to preserve content outside managed components.</xd:desc>
  </xd:doc>
  <xsl:template match="@*|node()" mode="identity">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" mode="identity"/>
    </xsl:copy>
  </xsl:template>

  <xd:doc>
    <xd:desc>Replaces the previously generated region or inserts it after the PressRecord module declaration.</xd:desc>
  </xd:doc>
  <xsl:template match="tei:schemaSpec[@ident eq 'PressRecord']" mode="identity">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="identity"/>
      <xsl:for-each select="node()">
        <xsl:choose>
          <xsl:when test="self::comment()[contains(., 'DO NOT EDIT THE VALUES HERE. THEY ARE GENERATED FROM THE TAXONOMIES.XML FILE') or contains(., 'END OF SECTION GENERATED FROM TAXONOMIES.XML FILE')]"/>
          <xsl:when test="self::elementSpec[preceding-sibling::comment()[contains(., 'DO NOT EDIT THE VALUES HERE. THEY ARE GENERATED FROM THE TAXONOMIES.XML FILE')][1] and following-sibling::comment()[contains(., 'END OF SECTION GENERATED FROM TAXONOMIES.XML FILE')][1]]"/>
          <xsl:when test="self::dataSpec[preceding-sibling::comment()[contains(., 'DO NOT EDIT THE VALUES HERE. THEY ARE GENERATED FROM THE TAXONOMIES.XML FILE')][1] and following-sibling::comment()[contains(., 'END OF SECTION GENERATED FROM TAXONOMIES.XML FILE')][1]]"/>
          <xsl:otherwise><xsl:apply-templates select="." mode="identity"/></xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </xsl:copy>
  </xsl:template>

  <xd:doc>
    <xd:desc>Emits a generated region after the project module declaration.</xd:desc>
  </xd:doc>
  <xsl:template match="tei:moduleSpec[@ident eq 'PressRecord']" mode="identity">
    <xsl:next-match/>
    <xsl:call-template name="hcmc:generateManagedRegion"/>
  </xsl:template>

  <xd:doc>
    <xd:desc>We add limits to controlled fields using the taxonomy mappings document.</xd:desc>
  </xd:doc>
  <xsl:template match="elementSpec/content//elementRef[@key = $mappingsDocument/pr:taxonomyMappings/pr:fields/pr:field/@element]" mode="identity">
    <xsl:variable name="field" as="element(pr:field)"
      select="$mappingsDocument/pr:taxonomyMappings/pr:fields/pr:field[@element eq current()/@key]"/>
    <xsl:copy>
      <xsl:apply-templates select="@* except (@minOccurs, @maxOccurs)" mode="identity"/>
      <xsl:attribute name="minOccurs" select="$field/@minOccurs"/>
      <xsl:attribute name="maxOccurs" select="$field/@maxOccurs"/>
      <xsl:apply-templates select="node()" mode="identity"/>
    </xsl:copy>
  </xsl:template>

  <xd:doc>
    <xd:desc>Special template for the release element because it combines two taxonomy fields: Release Type and Release Year.</xd:desc>
  </xd:doc>
  <xsl:template match="tei:elementSpec[@ident eq 'release']/tei:attList/tei:attDef[@ident eq 'type']/tei:valList" mode="identity">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="identity"/>
      <xsl:call-template name="hcmc:makeValItems">
        <xsl:with-param name="categories" select="$taxonomies//tei:taxonomy[@xml:id eq 'taxReleaseType']/tei:category"/>
      </xsl:call-template>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
