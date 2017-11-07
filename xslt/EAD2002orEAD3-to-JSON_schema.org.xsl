<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:ead3="http://ead3.archivists.org/schema/"
    xmlns:ead="urn:isbn:1-931666-22-9" xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns:j="http://www.w3.org/2005/xpath-functions" version="3.0">
    <!-- author(s): Mark Custer... you?  and you??? anyone else who wants to help! -->
    <!-- requires XSLT 3.0 -->
    <!-- tested with Saxon-HE 9.7.0.15 -->
    <xsl:output method="text" encoding="UTF-8"/>
    
    <!-- data mapping:
        https://docs.google.com/spreadsheets/d/1jsPRML3BCkF4EdWTR4r2ooAw2iTndErLZlse0cs3Osk/edit#gid=0
        https://github.com/schemaorg/schemaorg/issues/1758
        https://github.com/schemaorg/schemaorg/issues/1759
    -->
    
    <!-- to do:
        a lot!
        
        so far, just the generic framework is provided 
        (but need to continue to make sure ead3 files can work w/o any other changes / right now, i'm focusing on EAD2002).
        
        also need to make the first attempt at adding:
            isPartOf (and that's why i've added the isPartOf-URI-prefix parameter)
            start and end dates
            extents
            etc.
            
        to have useful links and the like, the ASpace EAD exporter would need to be updated.
        but a few of those things could be mapped here (e.g. eng -> http://id.loc.gov/vocabulary/languages/eng), as well.
    -->
    
    <!-- 1) global parameters and variables -->
    <xsl:param name="output-directory">
        <xsl:value-of select="concat('json-', $collection-ID-text, '/')"/>
    </xsl:param>
    <!-- change this to true to create one json file for each archival component, including the archdesc;
        when set to false, each EAD file produces a single json file for the archdesc-->
    <xsl:param name="include-dsc-in-transformation" select="false()"/>
    <xsl:param name="include-jeckyll-in-output" select="true()"/>
    <xsl:param name="jeckyll-title"/>
    <xsl:param name="jeckyll-source"/>
    <xsl:param name="jeckyll-description"/>
    <xsl:param name="isPartOf-URI-prefix"/>
    
    <xsl:variable name="collection-ID" select="ead:ead/ead:eadheader/ead:eadid, ead3:ead/ead3:control/ead3:recordid"/>
    <xsl:variable name="collection-ID-text" select="$collection-ID/normalize-space()"/>
    <xsl:variable name="collection-URL" select="$collection-ID/@url/normalize-space(), $collection-ID/@instanceurl/normalize-space()"/>
    <!-- consider changing to archdesc/did/repository, since the corpname element could actually have an @authfilenumber attribute available there.  the publisher element, on the other hand, could only have an id attribute.-->
    <xsl:variable name="repository-name" select="ead:ead/ead:eadheader/ead:filedesc/ead:publicationstmt/ead:publisher[1]/normalize-space(), ead3:ead/ead3:control/ead3:filedesc/ead3:publicationstmt/ead3:publisher[1]/normalize-space()"/>

    <!-- 2) primary template section -->
    <xsl:template match="ead:ead | ead3:ead">
        <xsl:apply-templates select="*:archdesc[not(@audience='internal')]"/>
    </xsl:template>

    <!-- all components, including the archdesc, processed here -->
    <xsl:template match="*:archdesc | ead:*[ead:did and ancestor::ead:dsc] | ead3:*[ead3:did and ancestor::ead3:dsc]">
        <xsl:param name="archdesc-level" select="if (local-name() eq 'archdesc') then true() else false()"/>
        <xsl:variable name="component-ID" select="if (@id) 
            then $collection-ID-text || '-' || @id => normalize-space() => replace('aspace_', '')
            else $collection-ID-text || '-' || generate-id(.)"/>
        <xsl:variable name="component-name">
            <xsl:sequence select="ead:did/ead:unittitle[not(@audience='internal')]/string-join(., '; '), ead3:did/ead3:unittitle[not(@audience='internal')]/string-join(., '; ')"/>
        </xsl:variable>
        <xsl:variable name="filename">
            <xsl:choose>
                <xsl:when test="$archdesc-level eq true()">
                    <xsl:value-of select="$output-directory || $collection-ID-text || '.json'"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$output-directory || $collection-ID-text || '-' || $component-ID || '.json'"/>         
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:result-document href="{$filename}">
            <xsl:if test="$include-jeckyll-in-output eq true()">
                <xsl:variable name="preceding-text">
                    <xsl:call-template name="create-preceding-text-for-jeckyll">
                        <xsl:with-param name="archdesc-level" select="$archdesc-level"/>
                        <xsl:with-param name="component-name" select="$component-name"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:value-of select="$preceding-text"/>
            </xsl:if>
            
            <xsl:variable name="xml">
                <xsl:call-template name="create-xml">
                    <xsl:with-param name="archdesc-level" select="$archdesc-level"/>
                    <xsl:with-param name="component-name" select="$component-name"/>
                    <xsl:with-param name="component-ID" select="$component-ID"/>
                </xsl:call-template>
            </xsl:variable>
            
            <xsl:sequence select="$xml => xml-to-json() => parse-json() => serialize(map{'method':'json', 'indent': true(), 'use-character-maps': map{'\': ''}})"/>
            
            <!-- when the include-dsc-in-transformation value is set to true, then all of the component templates will be processed by this same template recursively.
            by default this is turned off for testing purposes
            -->
            <xsl:if test="$include-dsc-in-transformation eq true()">
                <!-- update this to go through everything, not just top-level components -->
                <xsl:apply-templates select="ead:dsc/ead:*[ead:did][not(@audience='internal')] | ead3:dsc/ead3:*[ead3:did][not(@audience='internal')]
                    | ead:*[ead:did][not(@audience='internal')]
                    | ead3:*[ead3:did][not(@audience='internal')]
                    "/>
            </xsl:if>
        </xsl:result-document>
    </xsl:template>

    <!-- here's where we combine the jeckyll text info before the json document
            (the funky whitespace is important within this template for formatting reasons, so keep as is)-->
    <xsl:template name="create-preceding-text-for-jeckyll">
        <xsl:param name="component-name"/>
        <xsl:param name="archdesc-level"/>---
title: <xsl:value-of select="if ($jeckyll-title) then $jeckyll-title else $component-name"/>
source: <xsl:value-of select="if ($jeckyll-source) then $jeckyll-source else $repository-name"/>
        <xsl:if test="$jeckyll-description and $archdesc-level eq true()">
description: <xsl:value-of select="$jeckyll-description"/>  
        </xsl:if>
---
</xsl:template>
    
    <!-- here's where we create the XML document in order to convert it to JSON.
    will eventually shorten this template by adding others, most likely.-->
    <xsl:template name="create-xml">
        <xsl:param name="component-name"/>
        <xsl:param name="archdesc-level"/>
        <xsl:param name="component-ID"/>
        <!-- check to see if this works for EAD3, too (as i still need to do everywhere else) -->
        <xsl:variable name="level-of-description" select="@level => lower-case() => normalize-space()"/>
        <xsl:variable name="EAD-unitid">
            <xsl:sequence select="ead:did/ead:unitid[not(@audience='internal')]/string-join(., '; '), ead3:did/ead3:unittid[not(@audience='internal')]/string-join(., '; ')"/>
        </xsl:variable>
            <j:map>
                <j:string key="@context">http://schema.org/</j:string>
                <xsl:choose>
                    <xsl:when test="$level-of-description = ('collection', 'fonds', 'recordgrp')">
                        <j:array key="@type">
                            <j:string>Collection</j:string>
                            <j:string>ArchiveComponent</j:string>
                        </j:array>
                    </xsl:when>
                    <xsl:otherwise>
                        <j:string key="@type">ArchiveComponent</j:string>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:choose>
                    <xsl:when test="$collection-URL">
                        <j:string key="@id">
                            <xsl:value-of select="$collection-URL"/>
                        </j:string>
                    </xsl:when>
                    <xsl:otherwise>
                        <j:string key="@id">
                            <xsl:value-of select="$component-ID"/>
                        </j:string>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:choose>
                    <xsl:when test="$component-name">
                        <j:string key="name">
                            <xsl:value-of select="$component-name"/>
                        </j:string>
                    </xsl:when>
                    <xsl:otherwise>
                        <j:null key="name"/>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:choose>
                    <xsl:when test="$EAD-unitid">
                        <j:string key="identifier">
                            <xsl:value-of select="$EAD-unitid"/>
                        </j:string>
                    </xsl:when>
                    <xsl:otherwise>
                        <j:null key="identifier"/>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:choose>
                    <xsl:when test="$repository-name">
                        <j:map key="holdingArchive">
                            <j:array key="@type">
                                <j:string>Archive</j:string>
                                <j:string>LocalBusiness</j:string>
                            </j:array>
                            <j:string key="name">
                                <xsl:value-of select="$repository-name"/>
                            </j:string>
                            <!-- add id via authfilenumber after updating the repository-name variable -->
                        </j:map>
                    </xsl:when>
                    <xsl:otherwise>
                        <j:null key="holdingArchive"/>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:choose>
                    <xsl:when test="not(ead:scopecontent[normalize-space()]) and ead:abstract[normalize-space()][not(@audience='internal')][2]">
                        <j:array key="description">
                            <xsl:apply-templates select="ead:did/ead:abstract[not(@audience='internal')]" mode="string"/>
                        </j:array>
                    </xsl:when>
                    <xsl:when test="not(ead:scopecontent[normalize-space()]) and ead:abstract[normalize-space()][not(@audience='internal')]">
                        <j:string key="description">
                            <xsl:apply-templates select="ead:did/ead:abstract[not(@audience='internal')]"/>
                        </j:string>
                    </xsl:when>
                    <xsl:when test="ead:scopecontent[normalize-space()][not(@audience='internal')][2]">
                        <j:array key="description">
                            <xsl:apply-templates select="ead:scopecontent[not(@audience='internal')]" mode="string"/>
                        </j:array>
                    </xsl:when>
                    <xsl:when test="ead:scopecontent[normalize-space()][not(@audience='internal')]">
                        <j:string key="description">
                            <xsl:apply-templates select="ead:scopecontent[not(@audience='internal')]"/>
                        </j:string>
                    </xsl:when>
                    <xsl:otherwise>
                        <j:null key="description"/>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:choose>
                    <xsl:when test="ead:accessrestrict[normalize-space()][not(@audience='internal')][2]">
                        <j:array key="accessConditions">
                            <xsl:apply-templates select="ead:accessrestrict[not(@audience='internal')]" mode="string"/>
                        </j:array>
                    </xsl:when>
                    <xsl:when test="ead:accessrestrict[normalize-space()][not(@audience='internal')]">
                        <j:string key="accessConditions">
                            <xsl:apply-templates select="ead:accessrestrict[not(@audience='internal')]"/>
                        </j:string>
                    </xsl:when>
                    <xsl:otherwise>
                        <j:null key="accessConditions"/>
                    </xsl:otherwise>
                </xsl:choose>
                <!-- update to map language codes to URIs-->
                <xsl:choose>
                    <xsl:when test="ead:did/ead:langmaterial[normalize-space()][not(@audience='internal')][2]">
                        <j:array key="language">
                            <xsl:apply-templates select="ead:did/ead:langmaterial[not(@audience='internal')]" mode="string"/>
                        </j:array>
                    </xsl:when>
                    <xsl:when test="ead:did/ead:langmaterial[normalize-space()][not(@audience='internal')]">
                        <j:string key="language">
                            <xsl:apply-templates select="ead:did/ead:langmaterial[not(@audience='internal')]"/>
                        </j:string>
                    </xsl:when>
                    <xsl:otherwise>
                        <j:null key="language"/>
                    </xsl:otherwise>
                </xsl:choose>
                <!-- update the origination and controlaccess sections to use authfilenumber attribute-->
                <xsl:if test="ead:did/ead:origination[not(@audience='internal')]">
                    <j:array key="creator">
                        <!-- process any persname, corpname, famname, or name elements as a map.-->
                        <xsl:apply-templates select="ead:did/ead:origination[not(@audience='internal')]/*" mode="map"/>
                        <!-- process text-only origination elements as a string-->
                        <xsl:apply-templates select="ead:did/ead:origination[not(@audience='internal')][not(*)]" mode="string"/>
                    </j:array>
                </xsl:if>
                <!-- this doesn't expect nested control access statements right now, although EAD can have those (but ASpace-produced EAD files never will) -->
                <xsl:if test="ead:controlaccess[not(@audience='internal')]/*[local-name() = ('persname', 'corpname', 'famname', 'name', 'function', 'geogname', 'occupation', 'subject', 'title')]">
                       <j:array key="about">
                           <xsl:apply-templates select="ead:controlaccess[not(@audience='internal')]/*[local-name() = ('persname', 'corpname', 'famname', 'name', 'function', 'geogname', 'occupation', 'subject', 'title')]" mode="map"/>
                       </j:array>
                </xsl:if>
                <!-- not sure how best to handle the genreform elements right now, so at this point i'm just putting them as text in a "genre" array -->
                <xsl:if test="ead:controlaccess[not(@audience='internal')]/*[local-name() = ('genreform')]">
                    <j:array key="genre">
                         <xsl:apply-templates select="ead:controlaccess[not(@audience='internal')]/*[local-name() eq 'genreform']" mode="map"/>
                    </j:array>
                </xsl:if>
                
                <!-- dateCreated, first pass -->
                <xsl:if test="ead:did/ead:unitdate[not(@type='bulk')]">
                    <xsl:choose>
                        <xsl:when test="ead:did/ead:unitdate[not(@type='bulk')][2]">
                            <j:array key="dateCreated">
                                <xsl:apply-templates select="ead:did/ead:unitdate[not(@type='bulk')]" mode="string"/>
                            </j:array>
                        </xsl:when>
                        <xsl:otherwise>
                            <j:string key="dateCreated">
                                <xsl:apply-templates select="ead:did/ead:unitdate[not(@type='bulk')]"/>
                            </j:string>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:if>
                
                <!-- for startDate and endDate, I'll need to create a function to find the value that should be used,
                    since multiple inclusive date ranges might be use unitText and type when the info is properly encoded
                -->
                
                <!-- extent, first pass.
                    still need to add an option to use more precision
                     e.g. 
                
                input (ead2002):  <extent unit="letters">14</extent>
                
                output:
                 "materialExtent": {
                    "@type": "QuantitativeValue",
                    "unitText": "letters",
                    "value": "14"
                    }
                -->
                <xsl:if test="ead:did/ead:physdesc[not(ead:extent/@unit)]">
                    <xsl:choose>
                        <xsl:when test="ead:did/ead:physdesc[not(ead:extent/@unit)][2]">
                            <j:array key="materialExtent">
                                <xsl:apply-templates select="ead:did/ead:physdesc[not(ead:extent/@unit)]" mode="string"/>
                            </j:array>
                        </xsl:when>
                        <xsl:otherwise>
                            <j:string key="materialExtent">
                                <xsl:apply-templates select="ead:did/ead:physdesc[not(ead:extent/@unit)]"/>
                            </j:string>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:if>
                

                <!-- and go on like this for everything else -->
            </j:map>
    </xsl:template>
    
    
<!-- another section to document (but so far i don't have/need much here; could be need to add an 'array' or other generic mode types, though) -->
    
    <xsl:template match="ead:*" mode="string">
        <j:string>
            <xsl:apply-templates/>
        </j:string>
    </xsl:template>
    
    <!--optimized for what ASpace can output (up to 2 extents only).  If these templates are not used with AS-produced EAD, they
    will definitely need to change!-->
    <xsl:template match="ead:extent[1][matches(., '^\d')]">
           <!--ASpace doesn't force the extent number to be a number, so we'll need to validate and test this on our own-->
            <xsl:variable name="extent-number" select="number(substring-before(normalize-space(.), ' '))"/>
            <xsl:variable name="extent-type" select="lower-case(substring-after(normalize-space(.), ' '))"/>
            <xsl:value-of select="format-number($extent-number, '#,###')"/>
            <xsl:text> </xsl:text>
            <xsl:choose>
                <!--changes feet to foot for singular extents-->
                <xsl:when test="$extent-number eq 1 and contains($extent-type, ' feet')">
                    <xsl:value-of select="replace($extent-type, ' feet', ' foot')"/>
                </xsl:when>
                <!--changes boxes to box for singular extents-->
                <xsl:when test="$extent-number eq 1 and contains($extent-type, ' Boxes')">
                    <xsl:value-of select="replace($extent-type, ' Boxes', ' Box')"/>
                </xsl:when>
                <!--changes works to work for the "Works of art" extent type, if this is used-->
                <xsl:when test="$extent-number eq 1 and contains($extent-type, ' Works of art')">
                    <xsl:value-of select="replace($extent-type, ' Works', ' Work')"/>
                </xsl:when>
                <!--chops off the trailing 's' for singular extents-->
                <xsl:when test="$extent-number eq 1 and ends-with($extent-type, 's')">
                    <xsl:variable name="sl" select="string-length($extent-type)"/>
                    <xsl:value-of select="substring($extent-type, 1, $sl - 1)"/>
                </xsl:when>
                <!--chops off the trailing 's' for singular extents that are in AAT form, with a paranthetical qualifer-->
                <xsl:when test="$extent-number eq 1 and ends-with($extent-type, ')')">
                    <xsl:value-of select="replace($extent-type, 's \(', ' (')"/>
                </xsl:when>
                <!--any other irregular singluar/plural extent type names???-->
                
                <!--otherwise, just print out the childless text node as is-->
                <xsl:otherwise>
                    <xsl:value-of select="$extent-type"/>
                </xsl:otherwise>
                
            </xsl:choose>
            
            <!--provide a separator before the next extent value, if present-->
            <xsl:choose>
                <!-- if there's a second extent, and that value starts with an open parenthesis character, then add a space-->
                <xsl:when test="starts-with(following-sibling::ead:extent[1], '(')">
                    <xsl:text> </xsl:text>
                </xsl:when>
                <!--otherwise, if there's a second extent value, add a comma and a space-->
                <xsl:when test="following-sibling::ead:extent[1]">
                    <xsl:text>, </xsl:text>
                </xsl:when>
            </xsl:choose>
    </xsl:template>
    
    <xsl:template match="ead:physfacet">
            <xsl:choose>
                <xsl:when test="preceding-sibling::ead:extent">
                    <xsl:text> : </xsl:text>
                    <xsl:apply-templates/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
    </xsl:template>
    <xsl:template match="ead:dimensions">
            <xsl:choose>
                <xsl:when test="preceding-sibling::ead:extent | preceding-sibling::ead:physfacet">
                    <xsl:text> ; </xsl:text>
                    <xsl:apply-templates/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
    </xsl:template>

    <xsl:template match="ead:head">
        <xsl:apply-templates/>
        <xsl:if test="not(ends-with(normalize-space(.), ':'))">
            <xsl:text>: </xsl:text>
        </xsl:if>
    </xsl:template>
    
    <!-- not using schema.genre since ead:genreform will contain terms that don't fit the genre definition (unsure how to handle these, though, so right now they're only added as text)
    should "function" be mapped to schema.BusinessFunction?
    title removed for now.
    added the "map" mode so that these elements won't be processed when encountered as mixed-content elsewhere, e.g. scopeconent/p/persname.
    however, since this can still produce a string output, I'm not really happy with the mode name. should update that at some point
    to be more clear.
    -->
    <xsl:template match="ead:persname | ead:corpname | ead:famname | ead:name |
         ead:function | ead:geogname | ead:occupation | ead:subject | ead:genreform | ead:title" mode="map">
        <xsl:choose>
            <xsl:when test="self::*/local-name() = ('famname', 'name', 'function', 'genreform')">
                <xsl:choose>
                    <xsl:when test="starts-with(@authfilenumber, 'http')">
                        <j:map>
                            <j:string key="name">
                                <xsl:value-of select="normalize-space()"/>
                            </j:string>
                            <j:string key="@id">
                                <xsl:value-of select="normalize-space(@authfilenumber)"/>
                            </j:string>
                        </j:map>
                    </xsl:when>
                    <xsl:otherwise>
                        <j:string>
                            <xsl:apply-templates/>
                        </j:string>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <j:map>
                    <xsl:choose>
                        <xsl:when test="local-name(.) eq 'persname'">
                            <j:string key="@type">Person</j:string>
                        </xsl:when>
                        <xsl:when test="local-name(.) eq 'corpname'">
                            <j:string key="@type">Organization</j:string>
                        </xsl:when>
                        <xsl:when test="local-name(.) eq 'geogname'">
                            <j:string key="@type">Place</j:string>
                        </xsl:when>
                        <xsl:when test="local-name(.) eq 'title'">
                            <j:string key="@type">CreativeWork</j:string>
                        </xsl:when>
                        <xsl:when test="local-name(.) = ('subject', 'occupation')">
                            <j:string key="@type">Intangible</j:string>
                        </xsl:when>
                    </xsl:choose>
                    <j:string key="name">
                        <xsl:value-of select="normalize-space()"/>
                    </j:string>
                    <xsl:if test="starts-with(normalize-space(@authfilenumber), 'http')">
                        <j:string key="@id">
                            <xsl:value-of select="normalize-space(@authfilenumber)"/>
                        </j:string>
                    </xsl:if>
                </j:map>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    
    <xsl:template match="text()">
        <xsl:value-of select="normalize-space()"/>
    </xsl:template>
    
</xsl:stylesheet>