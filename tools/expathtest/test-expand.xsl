<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xpath-default-namespace="http://www.w3.org/2010/09/qt-fots-catalog"
    xmlns="http://www.w3.org/2010/09/qt-fots-catalog"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs" version="2.0" xmlns:doc="http://jwlresearch.net/2012/doc">

    <doc:doc title="qt3 Test Expander">
        <p>This stylesheet expands a set of qt3 tests in three principal ways:</p>
        <ul>
            <li>Expanding inclusions via either <code>include</code> elements, which is being
                deprecated, or a processing instruction named include.</li>
            <li>Applying common properties to a set of tests, gathered under an <code>expand</code>
                parent. This can also auto-name-number children.</li>
            <li>Replacing namespace prefixes with Clark notation in places where non-standard
                prefixes aren't bound, such as in assertions</li>
        </ul>
    </doc:doc>
    <xsl:output method="xml" indent="yes" encoding="US-ASCII"/>
    <xsl:template match="@*|*|text()|comment()|processing-instruction()" mode="#default common">
        <xsl:copy>
            <xsl:apply-templates select="@*|*|text()|comment()|processing-instruction()"
                mode="#current"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="processing-instruction(include)">
        <xsl:apply-templates select="doc(resolve-uri(.,base-uri(.)))/test-set/*">
            <xsl:with-param name="included" as="xs:boolean" select="true()" tunnel="yes"/>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="test-set">
        <xsl:param name="environments" as="element()*" tunnel="yes"/>
        <xsl:copy>
            <xsl:apply-templates select="@*|*|text()|comment()|processing-instruction()"
                mode="#current">
                <xsl:with-param name="environments" select="environment,$environments"
                    as="element()*" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="test-set/description">
        <xsl:param name="included" as="xs:boolean" select="false()" tunnel="yes"/>
        <xsl:if test="not($included)">
            <xsl:sequence select="."/>
        </xsl:if>
        <xsl:comment><xsl:value-of select="'Autogenerated from',base-uri(.),'at',current-dateTime()"/></xsl:comment>
    </xsl:template>
    <xsl:template match="include">
        <xsl:apply-templates select="doc(resolve-uri(@href,base-uri(.)))/test-set/*">
            <xsl:with-param name="included" as="xs:boolean" select="true()" tunnel="yes"/>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="environment">
        <xsl:apply-templates select="." mode="common"/>
    </xsl:template>

    <xsl:template match="expand">
        <xsl:param name="environments" as="element()*" tunnel="yes"/>
        <xsl:apply-templates select="test-case" mode="common">
            <xsl:with-param name="common" select="* except test-case" as="element()*" tunnel="yes"/>
            <xsl:with-param name="environments"
                select="($environments[@name=current()/environment/@ref])[1]" tunnel="yes"/>
        </xsl:apply-templates>
    </xsl:template>
    <xsl:template match="expand[@name]/test-case" mode="common">
        <xsl:param name="common" as="element()*" tunnel="yes"/>
        <xsl:copy>
            <xsl:attribute name="name" select="concat(../@name,format-number(position(),'-000'))"/>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:apply-templates select="description" mode="#current"/>
            <xsl:sequence select="$common[not(name() = current()/*/name())] | $common[self::modified]"/>
            <xsl:apply-templates select="* except description" mode="#current"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="assert-type/text()" mode="common">
        <xsl:call-template name="substitute-for-prefix"/>
    </xsl:template>
    <xsl:template match="param/@select|error/@code" mode="common">
        <xsl:attribute name="{name()}">
            <xsl:call-template name="substitute-for-prefix"/>
        </xsl:attribute>
    </xsl:template>

    <xsl:template name="substitute-for-prefix">
        <xsl:param name="environments" as="element()*" tunnel="yes"/>
        <xsl:analyze-string select="." regex="\i\c*:">
            <xsl:matching-substring>
                <xsl:variable name="namespace"
                    select="$environments/namespace[replace(@prefix,'REAL$','')=substring-before(current(),':')]/@uri"/>
                <xsl:value-of select="if($namespace) then concat('Q{',$namespace[1],'}') else ."/>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:value-of select="."/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:template>

</xsl:stylesheet>
