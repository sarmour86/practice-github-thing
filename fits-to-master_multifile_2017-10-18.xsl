<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
	xmlns:premis="http://www.loc.gov/premis/v3"
	xmlns:dc="http://purl.org/dc/terms/"
	xmlns:fits="http://hul.harvard.edu/ois/xml/ns/fits/fits_output"
	exclude-result-prefixes="fits">
	<xsl:output method="xml" indent="yes"/>
	
	<!--for when there is more than one file in the aip-->
	<!--overall structure of master.xml file and inserts values for rights and objectCategory that rarely change-->
	<xsl:template match="/">
		<master>
			<xsl:call-template name="aip-title"/>
			<dc:rights><xsl:text>http://rightsstatements.org/vocab/InC/1.0/</xsl:text></dc:rights>
			<aip>
				<premis:object>
					<xsl:call-template name="aip-id"/>
					<xsl:call-template name="aip-version"/>
					<premis:objectCategory><xsl:text>representation</xsl:text></premis:objectCategory>
					<premis:objectCharacteristics>
						<xsl:call-template name="aip-size"/>
						<xsl:call-template name="aip-unique-formats-list"/>
						<xsl:call-template name="aip-unique-creating-application-list"/>
						<xsl:call-template name="aip-unique-inhibitors-list"/>
					</premis:objectCharacteristics>
					<xsl:call-template name="relationship-collection"/>
				</premis:object>
			</aip>
			<filelist>
				<xsl:for-each select="//fits:fits">
					<premis:object>
						<xsl:call-template name="file-id"/>
						<premis:objectCategory><xsl:text>file</xsl:text></premis:objectCategory>
						<premis:objectCharacteristics>
							<xsl:call-template name="file-md5"/>
							<xsl:call-template name="file-size"/>
							<xsl:call-template name="file-format"/>
							<xsl:call-template name="file-creating-applications"/>
							<xsl:call-template name="file-inhibitors"/>
						</premis:objectCharacteristics>
						<xsl:call-template name="relationship-aip"/>
					</premis:object>
				</xsl:for-each>
			</filelist>
		</master>
	</xsl:template>
	
	<!--aip title: gets from the first fits/fileinfo/filepath in the FITS XML (required)-->
	<xsl:template name="aip-title">
		<dc:title><xsl:call-template name="get-aip-title"/></dc:title>
	</xsl:template>
	
	<!--aip-id: identifier type is the Hargrett Library group uri and identifier value is the aip-id from the first instance of fits/fileinfo/filepath in the FITS XML - PREMIS 1.1 (required)-->
	<xsl:template name="aip-id">
		<premis:objectIdentifier>
			<premis:objectIdentifierType><xsl:text>http://archive.libs.uga.edu/hargrett</xsl:text></premis:objectIdentifierType>
			<premis:objectIdentifierValue><xsl:call-template name="get-aip-id"/></premis:objectIdentifierValue>
		</premis:objectIdentifier>
	</xsl:template>
	
	<!--aip version: identifier type is the aip uri and identifier value is 1 (required) - PREMIS 1.1-->
	<xsl:template name="aip-version">
		<premis:objectIdentifier>
			<premis:objectIdentifierType><xsl:text>http://archive.libs.uga.edu/hargrett/</xsl:text><xsl:call-template name="get-aip-id"/></premis:objectIdentifierType>
			<premis:objectIdentifierValue>1</premis:objectIdentifierValue>
		</premis:objectIdentifier>
	</xsl:template>
	
	<!--aip size: gets every file size from fits/fileinfo/size in the FITS XML and adds the values to give the total size of the aip in bytes - PREMIS 1.5.3 (optional)-->
	<xsl:template name="aip-size">
		<premis:size><xsl:value-of select="format-number(sum(//fits:fileinfo/fits:size),'#')"/></premis:size>
	</xsl:template>
	
	<!--aip format list: gets a unique list of file formats in the aip based on file name and version from fits/identification/identity - PREMIS 1.5.4 (required)-->
	<xsl:template name="aip-unique-formats-list">
		<xsl:for-each select="//fits:identification/fits:identity">
			<xsl:sort select="@format"/>
			<xsl:sort select="version"/>
			<xsl:choose>
				<!--some formats have more than one version within the same identity section so select everything based on the version to capture every format-version combination-->
				<xsl:when test="fits:version">
					<xsl:for-each select="fits:version">
						<xsl:variable name="dedup">
							<!--explanation of concat: variable is a combination of the version (.) and the @format of version's parent, which is identity (../@format)-->
							<xsl:value-of select="concat(.,../@format)"/>		
						</xsl:variable>
						<!--if test removes duplicates by only acting on a format-version combination if it is not equal to a later format-version combination in the FITS XML-->
						<xsl:if test="not(following::fits:version[concat(.,../@format)=$dedup])">
							<premis:format>
								<premis:formatDesignation>
									<premis:formatName><xsl:value-of select="../@format"/></premis:formatName>
									<premis:formatVersion><xsl:value-of select="."/></premis:formatVersion>
								</premis:formatDesignation>
								<xsl:if test="following-sibling::fits:externalIdentifier[@type='puid']">
									<premis:formatRegistry>
										<premis:formatRegistryName><xsl:text>https://www.nationalarchives.gov.uk/PRONOM</xsl:text></premis:formatRegistryName>
										<premis:formatRegistryKey><xsl:value-of select="following-sibling::fits:externalIdentifier"/></premis:formatRegistryKey>
										<premis:formatRegistryRole><xsl:text>specification</xsl:text></premis:formatRegistryRole>
									</premis:formatRegistry>
								</xsl:if>
								<xsl:for-each select="preceding-sibling::fits:tool">
									<premis:formatNote><xsl:text>Format identified by </xsl:text><xsl:value-of select="@toolname"/><xsl:text> version </xsl:text><xsl:value-of select="@toolversion"/></premis:formatNote>
								</xsl:for-each>
							</premis:format>
						</xsl:if>	
					</xsl:for-each>	
				</xsl:when>
				<!--some formats only have a name and no version-->
				<xsl:otherwise>
					<!--if test removes duplicates by only acting on a format without a version if it is not equal to a later format without a version in the FITS XML-->
					<xsl:if test="not(@format=following::fits:identity[not(fits:version)]/@format)">
						<premis:format>
							<premis:formatDesignation>
								<premis:formatName><xsl:value-of select="@format"/></premis:formatName>
							</premis:formatDesignation>
							<xsl:if test="fits:externalIdentifier[@type='puid']">
								<premis:formatRegistry>
									<premis:formatRegistryName><xsl:text>https://www.nationalarchives.gov.uk/PRONOM</xsl:text></premis:formatRegistryName>
									<premis:formatRegistryKey><xsl:value-of select="fits:externalIdentifier"/></premis:formatRegistryKey>
									<premis:formatRegistryRole><xsl:text>specification</xsl:text></premis:formatRegistryRole>
								</premis:formatRegistry>
							</xsl:if>
							<xsl:for-each select="fits:tool">
								<premis:formatNote><xsl:text>Format identified by </xsl:text><xsl:value-of select="@toolname"/><xsl:text> version </xsl:text><xsl:value-of select="@toolversion"/>	</premis:formatNote>
							</xsl:for-each>
						</premis:format>
					</xsl:if>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
	</xsl:template>
	
	<!--aip creating application list: gets a unique list of creating applications in the aip based on application name, and version if present, from fits/fileinfo in FITS XML - PREMIS 1.5.5 (optional)-->
	<!--known issue: if the same creating application name (and if applicable version) are identified by different tools, it will display once for each tool-->
	<xsl:template name="aip-unique-creating-application-list">
		<xsl:if test="//fits:fileinfo/fits:creatingApplicationName">	
			<xsl:for-each select="//fits:fileinfo/fits:creatingApplicationName">
				<xsl:sort select="."/>
				<xsl:variable name="idtool" select="@toolname"/>
				<!--deduplication variable has to match each name to its version using the tool that identified it because if tools have a conflict there will be more than one name and version in a single fileinfo section-->
				<!--not all names have versions, so the variable is a combination of name and version if both are present or just the name if no version is present-->
				<xsl:variable name="dedup">
					<xsl:choose>
						<xsl:when test="following-sibling::fits:creatingApplicationVersion">
							<xsl:value-of select="concat(.[@toolname=$idtool],following-sibling::fits:creatingApplicationVersion[@toolname=$idtool])"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="."/>
						</xsl:otherwise>
					</xsl:choose>			
				</xsl:variable>
				<!--if test removes duplicates by only acting on a name-version combination if it is not equal to a later name-version combination in the FITS XML-->
				<!--if there is no creating application name identified by a tool, any version information identified by that tool will not be included in the master.xml-->
				<xsl:if test="not(following::fits:creatingApplicationName[concat(.[@toolname=$idtool],following-sibling::fits:creatingApplicationVersion[@toolname=$idtool])=$dedup])">
					<premis:creatingApplication>
						<premis:creatingApplicationName><xsl:value-of select=".[@toolname=$idtool]"/></premis:creatingApplicationName>
						<xsl:if test="following-sibling::fits:creatingApplicationVersion[@toolname=$idtool]">
							<premis:creatingApplicationVersion><xsl:value-of select="following-sibling::fits:creatingApplicationVersion[@toolname=$idtool]"/></premis:creatingApplicationVersion>
						</xsl:if>
					</premis:creatingApplication>		
				</xsl:if>
			</xsl:for-each>
		</xsl:if>
	</xsl:template>
						
	<!--aip inhibitors list: gets a unique list of inhibitors in the aip based on inhibitor type, and inhibitor target if present, from fits/fileinfo in FITS XML - PREMIS 1.5.6 (required if applicable)-->
	<!--known issue: if the same inhibitor type (and if applicable inhibitor target) are identified by different tools, it will display once for each tool-->
	<xsl:template name="aip-unique-inhibitors-list">
		<xsl:if test="//fits:fileinfo/fits:inhibitorType">	
			<xsl:for-each select="//fits:fileinfo/fits:inhibitorType">
				<xsl:sort select="."/>
				<xsl:variable name="idtool" select="@toolname"/>
				<!--deduplication variable has to match each inhibitor type to its target using the tool that identified it because if tools have a conflict there will be more than one type and target in a single fileinfo section-->
				<!--not all types have targets, so the variable is a combination of type and target if both are present or just the type if no target is present-->
				<xsl:variable name="dedup">
					<xsl:choose>
						<xsl:when test="following-sibling::fits:inhibitorTarget">
							<xsl:value-of select="concat(.[@toolname=$idtool],following-sibling::fits:inhibitorTarget[@toolname=$idtool])"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="."/>
						</xsl:otherwise>
					</xsl:choose>			
				</xsl:variable>
				<!--if test removes duplicates by only acting on a type-target combination if it is not equal to a later type-target combination in the FITS XML-->
				<!--if there is no inhibitor type identified by a tool, any target information identified by that tool will not be included in the master.xml-->
				<xsl:if test="not(following::fits:inhibitorType[concat(.[@toolname=$idtool],following-sibling::fits:inhibitorTarget[@toolname=$idtool])=$dedup])">
					<premis:inhibitors>
						<premis:inhibitorType><xsl:value-of select=".[@toolname=$idtool]"/></premis:inhibitorType>
						<xsl:if test="following-sibling::fits:inhibitorTarget[@toolname=$idtool]">
							<premis:inhibitorTarget><xsl:value-of select="following-sibling::fits:inhibitorTarget[@toolname=$idtool]"/></premis:inhibitorTarget>
						</xsl:if>
					</premis:inhibitors>		
				</xsl:if>
			</xsl:for-each>
		</xsl:if>
	</xsl:template>
	
	<!--aip relationship to collection: identifier type is Hargrett Library group uri and identifier value is the collection-id from the first instance of fits/fileinfo/filepath in the FITS XML - PREMIS 1.13 (required if applicable)-->
	<xsl:template name="relationship-collection">
		<premis:relationship>
			<premis:relationshipType><xsl:text>structural</xsl:text></premis:relationshipType>
			<premis:relationshipSubType><xsl:text>Is Member Of</xsl:text></premis:relationshipSubType>
			<premis:relatedObjectIdentifier>
				<premis:relatedObjectIdentifierType>	<xsl:text>http://archive.libs.uga.edu/hargrett</xsl:text></premis:relatedObjectIdentifierType>
				<premis:relatedObjectIdentifierValue><xsl:call-template name="get-collection-id"/></premis:relatedObjectIdentifierValue>
			</premis:relatedObjectIdentifier>
		</premis:relationship>
	</xsl:template>
	
	<!--file id: identifier type is aip uri and identifier value is the relative file path from fits/fileinfo/filepath in the FITS XML - PREMIS 1.1 (required)-->
	<xsl:template name="file-id">
		<premis:objectIdentifier>
			<premis:objectIdentifierType><xsl:text>http://archive.libs.uga.edu/hargrett/</xsl:text><xsl:call-template name="get-aip-id"/></premis:objectIdentifierType>
			<premis:objectIdentifierValue><xsl:call-template name="get-file-id"/></premis:objectIdentifierValue>
		</premis:objectIdentifier>
	</xsl:template>
	

	<!--file MD5: gets MD5 checksum from fits/fileinfo/md5checksum in the FITS XML - PREMIS 1.5.2 (optional in master.xml)-->
	<xsl:template name="file-md5">
		<premis:fixity>
			<premis:messageDigestAlgorithm><xsl:text>MD5</xsl:text></premis:messageDigestAlgorithm>
			<premis:messageDigest><xsl:value-of select="fits:fileinfo/fits:md5checksum"/></premis:messageDigest>
			<premis:messageDigestOriginator><xsl:value-of select="fits:fileinfo/fits:md5checksum/@toolname"/></premis:messageDigestOriginator>
		</premis:fixity>
	</xsl:template>
	
	<!--file size: gets file size from fits/fileinfo/size in the FITS XML - PREMIS 1.5.3 (optional)-->
	<xsl:template name="file-size">
		<premis:size><xsl:value-of select="fits:fileinfo/fits:size"/></premis:size>
	</xsl:template>
	
	<!--file format list: gets file format information for each possible format - PREMIS 1.5.4 (required)-->
	<xsl:template name="file-format">
		<xsl:for-each select="fits:identification/fits:identity">
			<xsl:choose>
				<!--if more than one version number, repeat format information with each possible version for that format-->
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
						<xsl:if test="../following-sibling::fits:filestatus/fits:valid">	
   							<premis:formatNote>
        						    	<xsl:text>Format identified as </xsl:text>
     		       				<xsl:if test="../following-sibling::fits:filestatus/fits:valid = 'true'">valid</xsl:if>
         		      				<xsl:if test="../following-sibling::fits:filestatus/fits:valid = 'false'">not valid</xsl:if>
         		      				<xsl:text> by </xsl:text> 
	    	    	   					<xsl:value-of select="../following-sibling::fits:filestatus/fits:valid/@toolname"/>
	    	    	   					<xsl:text> version </xsl:text> 
	    	    	   					<xsl:value-of select="../following-sibling::fits:filestatus/fits:valid/@toolversion"/>
     						</premis:formatNote>
     					</xsl:if>
     					<xsl:if test="../following-sibling::fits:filestatus/fits:well-formed">	
   							<premis:formatNote>
        						    	<xsl:text>Format identified as </xsl:text>
         						    	<xsl:if test="../following-sibling::fits:filestatus/fits:well-formed = 'true'">well-formed</xsl:if>
         		    					<xsl:if test="../following-sibling::fits:filestatus/fits:well-formed = 'false'">not well-formed</xsl:if>
         		      				<xsl:text> by </xsl:text> 
	    	    	   					<xsl:value-of select="../following-sibling::fits:filestatus/fits:well-formed/@toolname"/>
	    	    	   					<xsl:text> version </xsl:text> 
	    	    	   					<xsl:value-of select="../following-sibling::fits:filestatus/fits:well-formed/@toolversion"/>
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
	
	<!--file creating applications: gets creating application values from fits/fileinfo in FITS XML if present, and reformats the date - PREMIS 1.5.5 (optional)-->
	<xsl:template name="file-creating-applications">
		<xsl:if test="fits:fileinfo/fits:creatingApplicationName">
			<xsl:choose>
				<!--if there are 2+ names, versions, and/or dates for a single file it makes one premis:creatingApplication element for each name and also includes the version and/or date identified by the same tool as the name-->
				<!--if there is no name identified by a tool, any version or date information identified by that tool will not be included in the master.xml-->
				<xsl:when test="fits:fileinfo/fits:creatingApplicationName[@status='CONFLICT'] or fits:fileinfo/fits:creatingApplicationVersion[@status='CONFLICT'] or fits:fileinfo/fits:created[@status='CONFLICT']">
					<xsl:for-each select="fits:fileinfo/fits:creatingApplicationName">
						<xsl:sort select="."/>
						<xsl:variable name="ap-toolname" select="@toolname"/>
						<premis:creatingApplication>
							<premis:creatingApplicationName><xsl:value-of select=".[@toolname=$ap-toolname]"/></premis:creatingApplicationName>
							<xsl:if test="following-sibling::fits:creatingApplicationVersion[@toolname=$ap-toolname]">
								<premis:creatingApplicationVersion><xsl:value-of select="following-sibling::fits:creatingApplicationVersion[@toolname=$ap-toolname]"/></premis:creatingApplicationVersion>
							</xsl:if>
							<xsl:if test="following-sibling::fits:created[@toolname=$ap-toolname]">
								<!--Reformats date to required format, from YYYY:MM:DD HH:MM:SS to YYYY-MM-DD, by first getting everything before the space and then replacing : with - -->
								<premis:dateCreatedByApplication>
									<xsl:variable name="dateString"><xsl:value-of select="substring-before((following-sibling::fits:created[@toolname=$ap-toolname]),' ')"/></xsl:variable>
									<xsl:value-of select="replace($dateString, ':', '-')"/>
								</premis:dateCreatedByApplication>
							</xsl:if>
						</premis:creatingApplication>
					</xsl:for-each>		
				</xsl:when>
				<!--if these is 0 or 1 name, version, and date for a single file it combines the results into a premis:creatingApplication element even if the results are from different tools-->
				<xsl:otherwise>
					<premis:creatingApplication>
						<premis:creatingApplicationName><xsl:value-of select="fits:fileinfo/fits:creatingApplicationName"/></premis:creatingApplicationName>
						<xsl:if test="fits:fileinfo/fits:creatingApplicationVersion">
							<premis:creatingApplicationVersion><xsl:value-of select="fits:fileinfo/fits:creatingApplicationVersion"/></premis:creatingApplicationVersion>
						</xsl:if>
						<xsl:if test="fits:fileinfo/fits:created">
							<!--Reformats date to required format, from YYYY:MM:DD HH:MM:SS to YYYY-MM-DD, by first getting everything before the space and then replacing : with - -->
							<premis:dateCreatedByApplication>
								<xsl:variable name="dateString"><xsl:value-of select="substring-before((./fits:fileinfo/fits:created),' ')"/></xsl:variable>
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
	<xsl:template name="file-inhibitors">
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
	
	<!--file relationship to aip: identifier type is Hargrett Library group uri and identifier value is aip-id from the from fits/fileinfo/filepath in the FITS XML - PREMIS 1.13 (required if applicable)-->
	<xsl:template name="relationship-aip">
		<premis:relationship>
			<premis:relationshipType><xsl:text>structural</xsl:text></premis:relationshipType>
			<premis:relationshipSubType><xsl:text>Is Member Of</xsl:text></premis:relationshipSubType>
			<premis:relatedObjectIdentifier>
				<premis:relatedObjectIdentifierType>	<xsl:text>http://archive.libs.uga.edu/hargrett</xsl:text></premis:relatedObjectIdentifierType>
				<premis:relatedObjectIdentifierValue><xsl:call-template name="get-aip-id"/></premis:relatedObjectIdentifierValue>
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
	
	<!--file-id: gets relative file path (everything beginning with aip-id) from the first instance of fits/fileinfo/filepath in the FITS XML-->
	<!--aip-id may be formatted harg-ms####er####,  harg-ua####er####, or harg-ua##-####er####-->
	<xsl:template name="get-file-id">
		<xsl:analyze-string select="fits:fileinfo/fits:filepath" regex="harg-[mu][sa]\d{{2,4}}-?\d{{0,4}}er\d{{4}}.*">
			<xsl:matching-substring><xsl:sequence select="."/></xsl:matching-substring>
		</xsl:analyze-string>
	</xsl:template>

</xsl:stylesheet>
