<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
	xmlns:premis="http://www.loc.gov/premis/v3"
	xmlns:dc="http://purl.org/dc/terms/"
	xmlns:fits="http://hul.harvard.edu/ois/xml/ns/fits/fits_output"
	exclude-result-prefixes="fits">
	<xsl:output method="xml" indent="yes"/>
	
	<!--for when there is one file in the aip-->
	<!--overall structure of master.xml file and inserts values for rights and objectCategory that rarely change-->
	<xsl:template match="/">
		<master>
			<xsl:call-template name="aip-title"/>
			<dc:rights><xsl:text>http://rightsstatements.org/vocab/InC/1.0/</xsl:text></dc:rights>
			<aip>
				<premis:object>
					<xsl:call-template name="aip-id"/>
					<xsl:call-template name="aip-version"/>
					<premis:objectCategory><xsl:text>file</xsl:text></premis:objectCategory>
					<premis:objectCharacteristics>
						<xsl:call-template name="aip-size"/>
						<xsl:call-template name="aip-formats-list"/>
						<xsl:call-template name="aip-creating-applications-list"/>
						<xsl:call-template name="aip-inhibitors-list"/>
					</premis:objectCharacteristics>
					<xsl:call-template name="relationship-collection"/>
				</premis:object>
			</aip>
		</master>
	</xsl:template>
	
	<!--aip title: gets from the first fits/fileinfo/filepath in the FITS XML (required)-->
	<xsl:template name="aip-title">
		<dc:title><xsl:call-template name="get-aip-title"/></dc:title>
	</xsl:template>
	
	<!--aip-id: type is the Hargrett Library group uri and value is aip-id from fits/fileinfo/filepath in the FITS XML - PREMIS 1.1 (required)-->
	<xsl:template name="aip-id">
		<premis:objectIdentifier>
			<premis:objectIdentifierType><xsl:text>http://archive.libs.uga.edu/hargrett</xsl:text></premis:objectIdentifierType>
			<premis:objectIdentifierValue><xsl:call-template name="get-aip-id"/></premis:objectIdentifierValue>
		</premis:objectIdentifier>
	</xsl:template>
	
	<!--aip version: type is aip uri and value is 1 - PREMIS 1.1 (required)-->
	<xsl:template name="aip-version">
		<premis:objectIdentifier>
			<premis:objectIdentifierType><xsl:text>http://archive.libs.uga.edu/hargrett/</xsl:text><xsl:call-template name="get-aip-id"/></premis:objectIdentifierType>
			<premis:objectIdentifierValue>1</premis:objectIdentifierValue>
		</premis:objectIdentifier>
	</xsl:template>
	
	<!--aip size: gets file size from fits/fileinfo/size in the FITS XML - PREMIS 1.5.3 (optional)-->
	<xsl:template name="aip-size">
		<premis:size><xsl:value-of select="//fits:fileinfo/fits:size"/></premis:size>
	</xsl:template>
	
	<!--aip format list: gets file format information for each possible format - PREMIS 1.5.4 (required)-->
	<xsl:template name="aip-formats-list">
		<xsl:for-each select="//fits:identification/fits:identity">
			<xsl:choose>
				<!--if more than one version number, repeat format info with each possible version for that format-->
				<xsl:when test="fits:version[@status='CONFLICT']">
					<xsl:for-each select="fits:version">
						<premis:format>
							<premis:formatDesignation>
								<premis:formatName><xsl:value-of select="../@format"/></premis:formatName>
								<premis:formatVersion><xsl:value-of select="."/></premis:formatVersion>
							</premis:formatDesignation>
							<xsl:if test="following-sibling::fits:externalIdentifier[@type = 'puid']">
								<premis:formatRegistry>
									<premis:formatRegistryName><xsl:text>https://www.nationalarchives.gov.uk/PRONOM</xsl:text></premis:formatRegistryName>
									<premis:formatRegistryKey><xsl:value-of select="following-sibling::fits:externalIdentifier"/></premis:formatRegistryKey>
									<premis:formatRegistryRole><xsl:text>specification</xsl:text></premis:formatRegistryRole>
								</premis:formatRegistry>
							</xsl:if>
							<xsl:if test="//fits:filestatus/fits:valid">	
    								<premis:formatNote>
          						    	<xsl:text>Format identified as </xsl:text> 
	     		       				<xsl:if test="//fits:filestatus/fits:valid = 'true'">valid</xsl:if>
          		      				<xsl:if test="//fits:filestatus/fits:valid = 'false'">not valid</xsl:if>
          		      				<xsl:text> by </xsl:text> 
	     	    	   					<xsl:value-of select="//fits:filestatus/fits:valid/@toolname"/>
	     	    	   					<xsl:text> version </xsl:text> 
	     	    	   					<xsl:value-of select="//fits:filestatus/fits:valid/@toolversion"/>
       							</premis:formatNote>
       						</xsl:if>
       						<xsl:if test="//fits:filestatus/fits:well-formed">	
    								<premis:formatNote>
          						    	<xsl:text>Format identified as </xsl:text>
          						    	<xsl:if test="//fits:filestatus/fits:well-formed = 'true'">well-formed</xsl:if>
          		    					<xsl:if test="//fits:filestatus/fits:well-formed = 'false'">not well-formed</xsl:if>
          		      				<xsl:text> by </xsl:text> 
	     	    	   					<xsl:value-of select="//fits:filestatus/fits:well-formed/@toolname"/>
	     	    	   					<xsl:text> version </xsl:text> 
	     	    	   					<xsl:value-of select="//fits:filestatus/fits:well-formed/@toolversion"/>
       							</premis:formatNote>
       						</xsl:if>
       						<xsl:for-each select="preceding-sibling::fits:tool">
								<premis:formatNote><xsl:text>Format identified by </xsl:text><xsl:value-of select="@toolname"/><xsl:text> version </xsl:text><xsl:value-of select="@toolversion"/></premis:formatNote>
							</xsl:for-each>	
						</premis:format>
					</xsl:for-each>
				</xsl:when>
				<xsl:otherwise>
					<premis:format>
						<premis:formatDesignation>
							<premis:formatName><xsl:value-of select="@format"/></premis:formatName>
							<xsl:if test="fits:version">
								<premis:formatVersion><xsl:value-of select="fits:version"/></premis:formatVersion>	
							</xsl:if>
						</premis:formatDesignation>
						<xsl:if test="fits:externalIdentifier[@type = 'puid']">
							<premis:formatRegistry>
								<premis:formatRegistryName><xsl:text>https://www.nationalarchives.gov.uk/PRONOM</xsl:text></premis:formatRegistryName>
								<premis:formatRegistryKey><xsl:value-of select="fits:externalIdentifier"/></premis:formatRegistryKey>
								<premis:formatRegistryRole><xsl:text>specification</xsl:text></premis:formatRegistryRole>
							</premis:formatRegistry>
						</xsl:if>
						<xsl:if test="//fits:filestatus/fits:valid">	
   							<premis:formatNote>
        						    	<xsl:text>Format identified as </xsl:text> 
     		       				<xsl:if test="//fits:filestatus/fits:valid = 'true'">valid</xsl:if>
         		      				<xsl:if test="//fits:filestatus/fits:valid = 'false'">not valid</xsl:if>
         		      				<xsl:text> by </xsl:text> 
	    	    	   					<xsl:value-of select="//fits:filestatus/fits:valid/@toolname"/>
	    	    	   					<xsl:text> version </xsl:text> 
	    	    	   					<xsl:value-of select="//fits:filestatus/fits:valid/@toolversion"/>
     						</premis:formatNote>
     					</xsl:if>
     					<xsl:if test="//fits:filestatus/fits:well-formed">	
   							<premis:formatNote>
        						    	<xsl:text>Format identified as </xsl:text>
         						    	<xsl:if test="//fits:filestatus/fits:well-formed = 'true'">well-formed</xsl:if>
         		    					<xsl:if test="//fits:filestatus/fits:well-formed = 'false'">not well-formed</xsl:if>
         		      				<xsl:text> by </xsl:text> 
	    	    	   					<xsl:value-of select="//fits:filestatus/fits:well-formed/@toolname"/>
	    	    	   					<xsl:text> version </xsl:text> 
	    	    	   					<xsl:value-of select="//fits:filestatus/fits:well-formed/@toolversion"/>
     						</premis:formatNote>
     					</xsl:if>
     					<xsl:for-each select="fits:tool">
							<premis:formatNote><xsl:text>Format identified by </xsl:text><xsl:value-of select="@toolname"/><xsl:text> version </xsl:text><xsl:value-of select="@toolversion"/></premis:formatNote>
						</xsl:for-each>	
					</premis:format>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
	</xsl:template>
	
	<!--file creating applications: gets creating application values from fits/fileinfo in FITS XML if present and reformat the date - PREMIS 1.5.5 (optional)-->
	<xsl:template name="aip-creating-applications-list">
		<xsl:if test="//fits:fileinfo/fits:creatingApplicationName">
			<xsl:choose>
				<!--if there are 2+ names, versions, and/or dates for a single file it makes one premis:creatingApplication element for each name and also includes the version and/or date identified by the same tool as the name-->
				<!--if there is no name identified by a tool, any version or date information identified by that tool will not be included-->
				<xsl:when test="//fits:fileinfo/fits:creatingApplicationName[@status='CONFLICT'] or //fits:fileinfo/fits:creatingApplicationVersion[@status='CONFLICT'] or //fits:fileinfo/fits:created[@status='CONFLICT']">
					<xsl:for-each select="//fits:fileinfo/fits:creatingApplicationName">
						<xsl:sort select="."/>
						<xsl:variable name="ap-toolname" select="@toolname"/>
						<premis:creatingApplication>
							<premis:creatingApplicationName><xsl:value-of select=".[@toolname=$ap-toolname]"/></premis:creatingApplicationName>
							<xsl:if test="following-sibling::fits:creatingApplicationVersion[@toolname=$ap-toolname]">
								<premis:creatingApplicationVersion><xsl:value-of select="following-sibling::fits:creatingApplicationVersion[@toolname=$ap-toolname]"/></premis:creatingApplicationVersion>
							</xsl:if>
							<xsl:if test="following-sibling::fits:created[@toolname=$ap-toolname]">
								<premis:dateCreatedByApplication>
									<xsl:variable name="dateString"><xsl:value-of select="substring-before((following-sibling::fits:created[@toolname=$ap-toolname]),' ')"/></xsl:variable>
									<xsl:value-of select="replace($dateString, ':', '-')"/>
								</premis:dateCreatedByApplication>
							</xsl:if>
						</premis:creatingApplication>
					</xsl:for-each>		
				</xsl:when>
				<!--if there is 1 name, and 0 or 1 version and date, for a single file it combines the results into a premis:creatingApplication element even if the results are from different tools-->
				<xsl:otherwise>
					<premis:creatingApplication>
						<premis:creatingApplicationName><xsl:value-of select="//fits:fileinfo/fits:creatingApplicationName"/></premis:creatingApplicationName>
						<xsl:if test="//fits:fileinfo/fits:creatingApplicationVersion">
							<premis:creatingApplicationVersion><xsl:value-of select="//fits:fileinfo/fits:creatingApplicationVersion"/></premis:creatingApplicationVersion>
						</xsl:if>
						<xsl:if test="//fits:fileinfo/fits:created">
							<premis:dateCreatedByApplication>
								<xsl:variable name="dateString"><xsl:value-of select="substring-before((//fits:fileinfo/fits:created),' ')"/></xsl:variable>
								<xsl:value-of select="replace($dateString, ':', '-')"/>
							</premis:dateCreatedByApplication>
						</xsl:if>
					</premis:creatingApplication>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>
	</xsl:template>
						
	<!--file inhibitors: gets inhibitor type(s) from fits/fileinfo in FITS XML if present and also includes inhibitor target if identified by the same tool as the type - PREMIS 1.5.6 (required if applicable)-->
	<!--if there is a target that was identified by a tool that did not identify a type, the value of the target will not be displayed-->
	<xsl:template name="aip-inhibitors-list">
		<xsl:if test="//fits:fileinfo/fits:inhibitorType">
			<xsl:for-each select="//fits:fileinfo/fits:inhibitorType">
				<xsl:sort select="."/>
				<xsl:variable name="typetoolname" select="@toolname"/>
				<premis:inhibitors>
					<premis:inhibitorType><xsl:value-of select=".[@toolname=$typetoolname]"/></premis:inhibitorType>
					<xsl:if test="following-sibling::fits:inhibitorTarget[@toolname=$typetoolname]">
						<premis:inhibitorTarget><xsl:value-of select="following-sibling::fits:inhibitorTarget[@toolname=$typetoolname]"/></premis:inhibitorTarget>
					</xsl:if>
				</premis:inhibitors>
			</xsl:for-each>
		</xsl:if>
	</xsl:template>
	
	<!--aip relationship to collection: identifier type is Hargrett Library group uri and value is collection-id from the first instance of fits/fileinfo/filepath in the FITS XML - PREMIS 1.13 (required if applicable)-->
	<xsl:template name="relationship-collection">
		<premis:relationship>
			<premis:relationshipType><xsl:text>structural</xsl:text></premis:relationshipType>
			<premis:relationshipSubType><xsl:text>Is Member Of</xsl:text></premis:relationshipSubType>
			<premis:relatedObjectIdentifier>
				<premis:relatedObjectIdentifierType><xsl:text>http://archive.libs.uga.edu/hargrett</xsl:text></premis:relatedObjectIdentifierType>
				<premis:relatedObjectIdentifierValue><xsl:call-template name="get-collection-id"/></premis:relatedObjectIdentifierValue>
			</premis:relatedObjectIdentifier>
		</premis:relationship>
	</xsl:template>
		
	<!--collection-id: gets collection-id from the first instance of fits/fileinfo/filepath in the FITS XML-->
	<!--collection-id may be formatted harg-ms####, harg-ua####, or harg-ua##-####-->
	<xsl:template name="get-collection-id">
		<xsl:analyze-string select="(//fits:fileinfo/fits:filepath)[1]" regex="harg-[mu][sa]\d{{2,4}}-?\d{{0,4}}">
			<xsl:matching-substring><xsl:sequence select="."/></xsl:matching-substring>
		</xsl:analyze-string>
	</xsl:template>
	
	<!--aip-id: gets aip-id from the first instance of fits/fileinfo/filepath in the FITS XML--> 
	<!--aip-id may be formatted harg-ms####er####,  harg-ua####er####, or harg-ua##-####er####-->
	<xsl:template name="get-aip-id">
		<xsl:analyze-string select="(//fits:fileinfo/fits:filepath)[1]" regex="harg-[mu][sa]\d{{2,4}}-?\d{{0,4}}er\d{{4}}">
			<xsl:matching-substring><xsl:sequence select="."/></xsl:matching-substring>
		</xsl:analyze-string>
	</xsl:template>
	
	<!--aip title: gets aip title from the first instance of fits/fileinfo/filepath in the FITS XML-->
	<!--filpath may be formatted any/thing/harg-ms####er####_AIP Title/anything/else.ext,  any/thing/harg-ua####er####_AIP Title/anything/else.ext, or any/thing/harg-ua##-####er####_AIP Title/anything/else.ext-->
	<xsl:template name="get-aip-title">
		<xsl:analyze-string select="(//fits:fileinfo/fits:filepath)[1]" regex="harg-[mu][sa]\d{{2,4}}-?\d{{0,4}}er\d{{4}}_(.*?)/">
			<xsl:matching-substring><xsl:value-of select="regex-group(1)"/></xsl:matching-substring>
		</xsl:analyze-string>
	</xsl:template>
	
</xsl:stylesheet>
