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
        so far, just the generic framework is provided (but need to continue to make sure ead3 files can work  w/o any other changes).
        also need to make the first attempt at adding:
            dates
            extents
            @authfileid
            isPartOf
            etc.
            
        to have useful links and the like, the ASpace EAD exporter would need to be updated.
        but a few things those could be mapped here (e.g. eng -> http://id.loc.gov/vocabulary/languages/eng), as well.
    -->
    
    <!-- 1) global parameters and variables -->
    <xsl:param name="output-directory">
        <xsl:value-of select="concat('json-', $collection-ID-text, '/')"/>
    </xsl:param>
    <!-- change this to true to create one json file for each archival component, including the archdesc;
        when set to false, each EAD file produces a single json file for the archdesc-->
    <xsl:param name="include-dsc-in-transformation" select="false()"/>
    <xsl:param name="jeckyll-title"/>
    <xsl:param name="jeckyll-source"/>
    <xsl:param name="jeckyll-description"/>
    
    <xsl:variable name="collection-ID" select="ead:ead/ead:eadheader/ead:eadid, ead3:ead/ead3:control/ead3:recordid"/>
    <xsl:variable name="collection-ID-text" select="$collection-ID/normalize-space()"/>
    <xsl:variable name="collection-URL" select="$collection-ID/@url/normalize-space(), $collection-ID/@instanceurl/normalize-space()"/>
    <xsl:variable name="repository-name" select="ead:ead/ead:eadheader/ead:filedesc/ead:publicationstmt/ead:publisher[1]/normalize-space(), ead3:ead/ead3:control/ead3:filedesc/ead3:publicationstmt/ead3:publisher[1]/normalize-space()"/>

    <!-- 2) primary template section -->
    <xsl:template match="ead:ead | ead3:ead">
        <xsl:apply-templates select="*:archdesc[not(@audience='internal')]"/>
    </xsl:template>

    <!-- all components, including the archdesc, processed here -->
    <xsl:template match="ead:archdesc | ead3:archdesc | ead:*[ead:did and ancestor::ead:dsc] | ead3:*[ead3:did and ancestor::ead3:dsc]">
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
            <xsl:variable name="preceding-text">
                <xsl:call-template name="create-preceding-text-for-jeckyll">
                    <xsl:with-param name="archdesc-level" select="$archdesc-level"/>
                    <xsl:with-param name="component-name" select="$component-name"/>
                </xsl:call-template>
            </xsl:variable>
            <xsl:variable name="xml">
                <xsl:call-template name="create-xml">
                    <xsl:with-param name="archdesc-level" select="$archdesc-level"/>
                    <xsl:with-param name="component-name" select="$component-name"/>
                    <xsl:with-param name="component-ID" select="$component-ID"/>
                </xsl:call-template>
            </xsl:variable>
            
            <xsl:value-of select="$preceding-text"/>
            
            <xsl:sequence select="$xml => xml-to-json() => parse-json() => serialize(map{'method':'json', 'indent': true(), 'use-character-maps': map{'\': ''}})"/>
            
            <!-- when the include-dsc-in-transformation value is set to true, then all of the component templates will be processed by this same template recursively.
            by default this is turned off for testing purposes
            -->
            <xsl:if test="$include-dsc-in-transformation eq true()">
                <xsl:apply-templates select="ead:dsc/ead:*[ead:did][not(@audience='internal')] | ead3:dsc/ead3:*[ead3:did][not(@audience='internal')]"/>
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
    
    <!-- here's where we create the XML document in order to convert it to JSON -->
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
                    <!-- to expand, see the following example:
                        {
    "@id": "http://id.loc.gov/authorities/names/no2015136078",
    "@type": ["Archive", "LocalBusiness"],
    "address": "232 Asbury Drive, Atlanta, Georgia 30032",
    "name": "Stuart A. Rose Manuscript, Archives, and Rare Book Library",
    "telephone": "404-727-6887",
    "url": "http://rose.library.emory.edu/"
  }
                    -->
                    <xsl:when test="$repository-name">
                        <j:string key="holdingArchive">
                            <xsl:value-of select="$repository-name"/>
                        </j:string>
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
                
                <xsl:if test="ead:did/ead:origination[not(@audience='internal')]">
                    <j:array key="creator">
                        <xsl:apply-templates select="ead:did/ead:origination[not(@audience='internal')]" mode="string"/>
                    </j:array>
                </xsl:if>
                
                <!-- only expects one control access section right now, although EAD can have more than that -->
                <xsl:if test="ead:controlaccess[not(@audience='internal')]/*[local-name() != ('head', 'genreform')]">
                       <j:array key="about">
                           <xsl:apply-templates select="ead:controlaccess[not(@audience='internal')]/*[local-name() != ('head', 'genreform')]" mode="string"/>
                       </j:array>
                </xsl:if>
                
                
                <xsl:if test="ead:controlaccess[not(@audience='internal')]/*[local-name() = ('genreform')]">
                    <j:array key="genre">
                        <xsl:apply-templates select="ead:controlaccess[not(@audience='internal')]/*[local-name() = ('genreform')]" mode="string"/>
                    </j:array>
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

    <xsl:template match="ead:head">
        <xsl:apply-templates/>
        <xsl:if test="not(ends-with(normalize-space(.), ':'))">
            <xsl:text>: </xsl:text>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="text()">
        <xsl:value-of select="normalize-space()"/>
    </xsl:template>
    
</xsl:stylesheet>
