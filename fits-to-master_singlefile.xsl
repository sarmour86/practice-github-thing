<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
	xmlns:premis="http://www.loc.gov/premis/v3"
	xmlns:dc="http://purl.org/dc/terms/"
	xmlns:fits="http://hul.harvard.edu/ois/xml/ns/fits/fits_output"
	exclude-result-prefixes="fits">
	<xsl:output method="xml" indent="yes"/>
	
	<!--this stylesheet transforms FITS output into master.xml when there is only one file in the aip-->
	<!--see the UGA Libraries AIP Definition for details on the master.xml file-->
	
	<!--the optional filelist section is not included because it would just repeat the information in the aip section, other than including the MD5-->
	<!--fields in FITS are not always in the same order within a section, so variables are used to allow an field to be a preceding or a following sibling-->
	<!--if FITs generates an empty field, it is not included in the master.xml if it is for an optional field but is included in the master.xml as an empty field if it is required so that the master.xml will not pass the valid test and staff know to check it-->
	
	<!--template order in this stylesheet: 1. master template, 2. templates for the aip section, and 3. templates that use regular expressions (title and identifiers)-->
	<!--the regular expression templates are at the end because they are used by filelist templates-->
	
<!--  ........................................................................................................................................................................................................................................................................................................................-->
<!-- MASTER TEMPLATE-->
<!--  ........................................................................................................................................................................................................................................................................................................................-->
	
	
	<!--creates the overall structure of the master.xml file and inserts the values for rights (in copyright) and objectCategory (file) since they rarely change-->
	
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
	
	<!--aip title: Dublin Core (required)-->
	<!--gets the aip-title from the get-aip-title template at the end of this document-->
	
	<xsl:template name="aip-title">
		<dc:title><xsl:call-template name="get-aip-title"/></dc:title>
	</xsl:template>
	
		
<!--  ........................................................................................................................................................................................................................................................................................................................-->
<!-- AIP SECTION TEMPLATES -->
<!--  ........................................................................................................................................................................................................................................................................................................................-->
	
	
	<!--aip-id: PREMIS 1.1 (required)-->
	<!--inserts the value for the identifier type (russell Library group uri) and gets the aip-id from the get-aip-id template at the end of this document-->
	
	<xsl:template name="aip-id">
		<premis:objectIdentifier>
			<premis:objectIdentifierType><xsl:text>http://archive.libs.uga.edu/russell</xsl:text></premis:objectIdentifierType>
			<premis:objectIdentifierValue><xsl:call-template name="get-aip-id"/></premis:objectIdentifierValue>
		</premis:objectIdentifier>
	</xsl:template>
	
	
	<!--aip version: PREMIS 1.1 (required)-->
	<!--inserts the value for the identifier type (the aip uri, which combines the russell Library group uri and the aip-id) and the identifier value (1)-->
	
	<xsl:template name="aip-version">
		<premis:objectIdentifier>
			<premis:objectIdentifierType><xsl:text>http://archive.libs.uga.edu/russell/</xsl:text><xsl:call-template name="get-aip-id"/></premis:objectIdentifierType>
			<premis:objectIdentifierValue>1</premis:objectIdentifierValue>
		</premis:objectIdentifier>
	</xsl:template>
	
	
	<!--aip size: PREMIS 1.5.3 (optional)-->
	<!--gets file size from fits/fileinfo/size, size is in bytes-->
	<xsl:template name="aip-size">
		<!--checks that at least one of the size fields has a value before putting premis:size in the master.xml-->
		<xsl:if test="//fits:fileinfo/fits:size/text()">
			<premis:size><xsl:value-of select="//fits:fileinfo/fits:size"/></premis:size>
		</xsl:if>
	</xsl:template>
	

	<!--aip formats list: PREMIS 1.5.4 (required)-->
	<!--gets file format information for every possible format the file might be from fits/identification/identity and fits/filestatus-->
	
	<xsl:template name="aip-formats-list">
		<xsl:for-each select="//fits:identification/fits:identity">
			<xsl:choose>
				
				<!--if there are two or more versions within the identity section, makes a premis:format section repeating the other format information with each version to capture every format-version combination-->
				<xsl:when test="fits:version[@status='CONFLICT']">
					<xsl:for-each select="fits:version">
						<!--checks that the version field has a value before putting premis:format in the master.xml-->
						<xsl:if test="./text()">
							<premis:format>
								
								<!--PREMIS 1.5.4.1 formatDesignation-->
								<!--gets format name and version from fits/identification/identity-->
								<premis:formatDesignation>
									<!--if the format in FITS has the literal value "empty", it produces an empty premis:formatName field so the master.xml does not validate and staff know to research the format-->
									<!--if the format in FITS is an empty field, it will also produce an empty premis:formatName field when its value is selected, causing the master.xml to not validate-->
									<xsl:choose>
										<xsl:when test="../@format='empty'">
												<premis:formatName/>
										</xsl:when>
										<xsl:otherwise>
											<premis:formatName><xsl:value-of select="../@format"/></premis:formatName>
										</xsl:otherwise>
									</xsl:choose>
									<premis:formatVersion><xsl:value-of select="."/></premis:formatVersion>
								</premis:formatDesignation>
								
								<!--PREMIS 1.5.4.2 formatRegistry-->
								<!--gets PUID from fits/identification/identity/externalIdentifier-->
								<!--checks that the externalIdentifier field has a value before putting premis:formatRegistry in the master.xml-->
								<xsl:if test="preceding-sibling::fits:externalIdentifier[@type = 'puid']/text() or following-sibling::fits:externalIdentifier[@type = 'puid']/text()">
									<xsl:variable name="puid">
										<xsl:if test="preceding-sibling::fits:externalIdentifier[@type = 'puid']"><xsl:value-of select="preceding-sibling::fits:externalIdentifier[@type = 'puid']"/></xsl:if>
										<xsl:if test="following-sibling::fits:externalIdentifier[@type = 'puid']"><xsl:value-of select="following-sibling::fits:externalIdentifier[@type = 'puid']"/></xsl:if>
									</xsl:variable>
									
									<premis:formatRegistry>
										<premis:formatRegistryName><xsl:text>https://www.nationalarchives.gov.uk/PRONOM</xsl:text></premis:formatRegistryName>
										<premis:formatRegistryKey><xsl:value-of select="$puid"/></premis:formatRegistryKey>
										<premis:formatRegistryRole><xsl:text>specification</xsl:text></premis:formatRegistryRole>
									</premis:formatRegistry>
								</xsl:if>
								
								<!--PREMIS 1.5.4.3 formatNote (result of format validation test)-->
								<!--gets information on if the format is valid or not from fits/filestatus/valid-->
								<!--checks that the valid field has a value before putting premis:formatNote in the master.xml-->
           						<xsl:if test="../../following-sibling::fits:filestatus/fits:valid/text()">
           							<!--if the valid field does not have the expected value (true or false) it produces an empty premis:formatName field so the master.xml does not validate and staff know to research-->
           							<xsl:choose>
           								<xsl:when test="../../following-sibling::fits:filestatus/fits:valid[.='true' or .='false']">
           									<premis:formatNote>
           										<xsl:text>Format identified as </xsl:text>
	    											<xsl:if test="../../following-sibling::fits:filestatus/fits:valid = 'true'">valid</xsl:if>
        											<xsl:if test="../../following-sibling::fits:filestatus/fits:valid = 'false'">not valid</xsl:if>
        											<xsl:text> by </xsl:text> 
	    											<xsl:value-of select="../../following-sibling::fits:filestatus/fits:valid/@toolname"/>
	    											<xsl:text> version </xsl:text> 
	    											<xsl:value-of select="../../following-sibling::fits:filestatus/fits:valid/@toolversion"/>
       										</premis:formatNote>
      									</xsl:when>
      									<xsl:otherwise>
      										<premis:formatNote/>
      									</xsl:otherwise>	
      								</xsl:choose>
      							</xsl:if>
      							
      							<!--PREMIS 1.5.4.3 formatNote (result of format well-formed test)-->
      							<!--gets information on if the format is well-formed or not from fits/filestatus/well-formed-->
      							<!--checks that the well-formed field has a value before putting premis:formatNote in the master.xml-->
      							<xsl:if test="../../following-sibling::fits:filestatus/fits:well-formed/text()">
      								<!--if the well-formed field does not have the expected value (true or false) it produces an empty premis:formatName field so the master.xml does not validate and staff know to research-->
      								<xsl:choose>
      									<xsl:when test="../../following-sibling::fits:filestatus/fits:well-formed[.='true' or .='false']">	
    											<premis:formatNote>
           										<xsl:text>Format identified as </xsl:text>
           										<xsl:if test="../../following-sibling::fits:filestatus/fits:well-formed = 'true'">well-formed</xsl:if>
        											<xsl:if test="../../following-sibling::fits:filestatus/fits:well-formed = 'false'">not well-formed</xsl:if>
        											<xsl:text> by </xsl:text> 
	    											<xsl:value-of select="../../following-sibling::fits:filestatus/fits:well-formed/@toolname"/>
	    											<xsl:text> version </xsl:text> 
	    											<xsl:value-of select="../../following-sibling::fits:filestatus/fits:well-formed/@toolversion"/>
       										</premis:formatNote>
      									</xsl:when>
      									<xsl:otherwise>
      										<premis:formatNote/>
      									</xsl:otherwise>
      								</xsl:choose>	
      							</xsl:if>   						
       							
       							<!--PREMIS 1.5.4.3 formatNote (list tool or tools that provided the information about the format)-->
								<!--gets the tool information from fits/identification/identity/tool fields that are before the version field-->
       							<xsl:for-each select="preceding-sibling::fits:tool">
       								<xsl:choose>
     									<!--if tool attribute is empty (string length is 0), it produces an empty premis:formatNotee field so the master.xml does not validate and staff know the required source of the format information is missing-->
     									<xsl:when test="@toolname[string-length(.)=0]">
											<premis:formatNote/>
										</xsl:when>
										<xsl:otherwise>
											<premis:formatNote>
												<xsl:text>Format identified by </xsl:text><xsl:value-of select="@toolname"/>
												<!--checks that the version field has a value before putting the version in the premis:formatNote in the master.xml-->
												<xsl:if test="@toolversion[not(string-length(.)=0)]">
													<xsl:text> version </xsl:text><xsl:value-of select="@toolversion"/>
												</xsl:if>	
											</premis:formatNote>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:for-each>	
								
								<!--PREMIS 1.5.4.3 formatNote (list tool or tools that provided the information about the format)-->
								<!--gets the tool information from fits/identification/identity/tool fields that are after the version field-->
								<xsl:for-each select="following-sibling::fits:tool">
									<xsl:choose>
     									<!--if tool attribute is empty (string length is 0), it produces an empty premis:formatNotee field so the master.xml does not validate and staff know the required source of the format information is missing-->
     									<xsl:when test="@toolname[string-length(.)=0]">
											<premis:formatNote/>
										</xsl:when>
										<xsl:otherwise>
											<premis:formatNote>
												<xsl:text>Format identified by </xsl:text><xsl:value-of select="@toolname"/>
												<!--checks that the version field has a value before putting the version in the premis:formatNote in the master.xml-->
												<xsl:if test="@toolversion[not(string-length(.)=0)]">
													<xsl:text> version </xsl:text><xsl:value-of select="@toolversion"/>
												</xsl:if>	
											</premis:formatNote>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:for-each>	
							</premis:format>
						</xsl:if>
					</xsl:for-each>
				</xsl:when>
				
				<!--if there is one or no version within a identity section, makes a premis:format section with the other format information-->
				<xsl:otherwise>
					<premis:format>
						
						<!--PREMIS 1.5.4.1 formatDesignation-->
						<!--gets the format name and version from fits/identification/identity-->
						<premis:formatDesignation>
							<xsl:choose>
								<!--if the format in FITS has the literal value "empty", it produces an empty premis:formatName field so the master.xml does not validate and staff know to research the format-->
								<!--if the format in FITS is an empty field, it will also produce an empty premis:formatName field when its value is selected, causing the master.xml to not validate-->
								<xsl:when test="@format='empty'">
										<premis:formatName/>
								</xsl:when>
								<xsl:otherwise>
										<premis:formatName><xsl:value-of select="@format"/></premis:formatName>
								</xsl:otherwise>
							</xsl:choose>
							<!--checks if version has a value before making premis:formatVersion in the master.xml-->
							<xsl:if test="fits:version/text()">
								<premis:formatVersion><xsl:value-of select="fits:version"/></premis:formatVersion>	
							</xsl:if>
						</premis:formatDesignation>
						
						<!--PREMIS 1.5.4.2 formatRegistry-->
						<!--gets the PUID from fits/identification/identity/externalIdentifier-->
						<!--checks that the externalIdentifier field has a value before putting premis:formatRegistry in the master.xml-->
						<xsl:if test="fits:externalIdentifier[@type = 'puid']/text()">
							<premis:formatRegistry>
								<premis:formatRegistryName><xsl:text>https://www.nationalarchives.gov.uk/PRONOM</xsl:text></premis:formatRegistryName>
								<premis:formatRegistryKey><xsl:value-of select="fits:externalIdentifier"/></premis:formatRegistryKey>
								<premis:formatRegistryRole><xsl:text>specification</xsl:text></premis:formatRegistryRole>
							</premis:formatRegistry>
						</xsl:if>
						
						<!--PREMIS 1.5.4.3 formatNote (result of format validation test)-->
						<!--checks that the valid field has a value before putting the version in the premis:formatNote in the master.xml-->
						<xsl:if test="../following-sibling::fits:filestatus/fits:valid/text()">
							<!--if the tool does not produce the expected result (true or false) it produces an empty premis:formatName field so the master.xml does not validate and staff know to research-->
							<xsl:choose>
								<xsl:when test="../following-sibling::fits:filestatus/fits:valid[.='true' or .='false']">	
   									<premis:formatNote>
        									<xsl:text>Format identified as </xsl:text>
     		       						<xsl:if test="../following-sibling::fits:filestatus/fits:valid = 'true'">valid</xsl:if>
         		      						<xsl:if test="../following-sibling::fits:filestatus/fits:valid = 'false'">not valid</xsl:if>
         		      						<xsl:text> by </xsl:text> 
	    	    	   							<xsl:value-of select="../following-sibling::fits:filestatus/fits:valid/@toolname"/>
	    	    	   							<xsl:text> version </xsl:text> 
	    	    	   							<xsl:value-of select="../following-sibling::fits:filestatus/fits:valid/@toolversion"/>
     								</premis:formatNote>
     							</xsl:when>
     							<xsl:otherwise>
     								<premis:formatNote/>
     							</xsl:otherwise>
     						</xsl:choose>	
  						</xsl:if>
     					
     					<!--PREMIS 1.5.4.3 formatNote (result of format well-formed test)-->
     					<!--checks that the well-formed field has a value before putting the version in the premis:formatNote in the master.xml-->
     					<xsl:if test="../following-sibling::fits:filestatus/fits:well-formed/text()">
     						<!--if the tool does not produce the expected result (true or false) it produces an empty premis:formatName field so the master.xml does not validate and staff know to research-->
     						<xsl:choose>
     							<xsl:when test="../following-sibling::fits:filestatus/fits:well-formed[.='true' or .='false']">	
   									<premis:formatNote>
        						    			<xsl:text>Format identified as </xsl:text>
         						    			<xsl:if test="../following-sibling::fits:filestatus/fits:well-formed = 'true'">well-formed</xsl:if>
         		    							<xsl:if test="../following-sibling::fits:filestatus/fits:well-formed = 'false'">not well-formed</xsl:if>
         		      						<xsl:text> by </xsl:text> 
	    	    	   							<xsl:value-of select="../following-sibling::fits:filestatus/fits:well-formed/@toolname"/>
	    	    	   							<xsl:text> version </xsl:text> 
	    	    	   							<xsl:value-of select="../following-sibling::fits:filestatus/fits:well-formed/@toolversion"/>
     								</premis:formatNote>
     							</xsl:when>
     							<xsl:otherwise>
     								<premis:formatNote/>
     							</xsl:otherwise>
     						</xsl:choose>	
     					</xsl:if>
     					
     					<!--PREMIS 1.5.4.3 formatNote (list tool or tools that provided the information about the format)-->
     					<!--gets the tool information from fits/identification/identity/tool-->
     					<xsl:for-each select="fits:tool">
     						<xsl:choose>
     							<!--if tool attribute is empty (string length is 0), it produces an empty premis:formatNotee field so the master.xml does not validate and staff know the required source of the format information is missing-->
     							<xsl:when test="@toolname[string-length(.)=0]">
									<premis:formatNote/>
								</xsl:when>
								<xsl:otherwise>
									<premis:formatNote>
										<xsl:text>Format identified by </xsl:text><xsl:value-of select="@toolname"/>
										<!--checks that the version field has a value before putting the version in the premis:formatNote in the master.xml-->
										<xsl:if test="@toolversion[not(string-length(.)=0)]">
											<xsl:text> version </xsl:text><xsl:value-of select="@toolversion"/>
										</xsl:if>	
									</premis:formatNote>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:for-each>	
					</premis:format>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
	</xsl:template>
	
	<!--aip creating applications list: PREMIS 1.5.5 (optional)-->
	<!--gets creating application values from fits/fileinfo and reformats the date to YYYY-MM-DD-->
	
	<xsl:template name="aip-creating-applications-list">
			<xsl:for-each select="//fits:fileinfo/fits:creatingApplicationName">
			<xsl:variable name="apname" select="."/>
			<xsl:variable name="aptool" select="@toolname"/>
			<!--checks that the creatingApplicationName has a value before putting premis:creatingApplication in the master.xml-->
			<xsl:if test="./text()">
				<xsl:choose>
					
					<!--if there are two or more names, versions, and/or dates for the file, makes a premis:creatingApplication section for each name and also includes the version and/or date identified by the same tool as the name-->
					<!--note: if there is no name identified by a tool, any version or date information identified by that tool will not be included in the master.xml-->
					<xsl:when test=".[@status='CONFLICT'] or preceding-sibling::fits:creatingApplicationVersion[@toolname=$aptool][@status='CONFLICT'] or following-sibling::fits:creatingApplicationVersion[@toolname=$aptool][@status='CONFLICT'] or preceding-sibling::fits:created[@toolname=$aptool][@status='CONFLICT'] or following-sibling::fits:created[@toolname=$aptool][@status='CONFLICT']">
						<xsl:variable name="apversion">
							<xsl:if test="preceding-sibling::fits:creatingApplicationVersion[@toolname=$aptool]"><xsl:value-of select="preceding-sibling::fits:creatingApplicationVersion[@toolname=$aptool]"/></xsl:if>
							<xsl:if test="following-sibling::fits:creatingApplicationVersion[@toolname=$aptool]"><xsl:value-of select="following-sibling::fits:creatingApplicationVersion[@toolname=$aptool]"/></xsl:if>
						</xsl:variable>
						
						<xsl:variable name="apdate">
							<xsl:if test="preceding-sibling::fits:created[@toolname=$aptool]"><xsl:value-of select="preceding-sibling::fits:created[@toolname=$aptool]"/></xsl:if>
							<xsl:if test="following-sibling::fits:created[@toolname=$aptool]"><xsl:value-of select="following-sibling::fits:created[@toolname=$aptool]"/></xsl:if>
						</xsl:variable>
						
						<premis:creatingApplication>
							<premis:creatingApplicationName><xsl:value-of select="$apname"/></premis:creatingApplicationName>
							<!--checks that the creatingApplicationVersion has a value before putting premis:creatingApplicationVersion in the master.xml-->
							<xsl:if test="preceding-sibling::fits:creatingApplicationVersion[@toolname=$aptool]/text() or following-sibling::fits:creatingApplicationVersion[@toolname=$aptool]/text()">
								<premis:creatingApplicationVersion><xsl:value-of select="$apversion"/></premis:creatingApplicationVersion>
							</xsl:if>
							
							<!--gets date created by application from fits/fileinfo/created and reformats the date to the required format YYYY-MM-DD for any of the date format variations observed in FITS output so far-->
							<!--typically works by identifying the day, month, and year using regular expression groups and then manipulating those as needed, i.e. changing months to two digit values-->
							<xsl:choose>
								
								<!--reformats date from YYYY:MM:DD HH:MM:SS or YYYY-MM-DD HH:MM:SS -->
								<!--already in the right order and right number of digits, so this one uses substring to select content before the space and then replaced the : with - for the required punctuation-->
								<xsl:when test="matches($apdate, '\d{4}:\d{2}:\d{2} ') or matches($apdate, '\d{4}-\d{2}-\d{2} ')">
									<premis:dateCreatedByApplication>
										<xsl:variable name="dateString"><xsl:value-of select="substring-before($apdate,' ')"/></xsl:variable>
										<xsl:value-of select="replace($dateString, ':', '-')"/>
									</premis:dateCreatedByApplication>
								</xsl:when>
								
								<!--reformats date from DayOfWeek, Month D, YYYY HH:MM:SS AM/PM -->
								<xsl:when test="matches($apdate, 'day')">
									<premis:dateCreatedByApplication>
										<xsl:analyze-string select="$apdate" regex="day, ([a-zA-Z]+) (\d{{1,2}}), (\d{{4}}) ">
											<xsl:matching-substring>
												<xsl:variable name="month"><xsl:sequence select="regex-group(1)"/></xsl:variable>
												<xsl:variable name='day'><xsl:sequence select="regex-group(2)"/></xsl:variable>
												<!--year: already 4 digits-->
												<xsl:sequence select="regex-group(3)"/>
												<xsl:text>-</xsl:text>
												<!--month: converts from words to two-digit number-->
												<xsl:if test="$month = 'January'"><xsl:text>01</xsl:text></xsl:if>
												<xsl:if test="$month = 'February'"><xsl:text>02</xsl:text></xsl:if>
												<xsl:if test="$month = 'March'"><xsl:text>03</xsl:text></xsl:if>
												<xsl:if test="$month = 'April'"><xsl:text>04</xsl:text></xsl:if>
												<xsl:if test="$month = 'May'"><xsl:text>05</xsl:text></xsl:if>
												<xsl:if test="$month = 'June'"><xsl:text>06</xsl:text></xsl:if>
												<xsl:if test="$month = 'July'"><xsl:text>07</xsl:text></xsl:if>
												<xsl:if test="$month = 'August'"><xsl:text>08</xsl:text></xsl:if>
												<xsl:if test="$month = 'September'"><xsl:text>09</xsl:text></xsl:if>
												<xsl:if test="$month = 'October'"><xsl:text>10</xsl:text></xsl:if>
												<xsl:if test="$month = 'November'"><xsl:text>11</xsl:text></xsl:if>
												<xsl:if test="$month = 'December'"><xsl:text>12</xsl:text></xsl:if>
												<xsl:text>-</xsl:text>
												<!--day: if it is a single digit, add a leading zero so the day is always a two-digit number-->
												<xsl:choose>
													<xsl:when test="$day &lt; 10">
														<xsl:text>0</xsl:text><xsl:value-of select="$day"/>
													</xsl:when>
													<xsl:otherwise>
														<xsl:value-of select="$day"/>
													</xsl:otherwise>	
												</xsl:choose>
											</xsl:matching-substring>
										</xsl:analyze-string>
									</premis:dateCreatedByApplication>
								</xsl:when>
								
								<!-- Reformats date from Day Month DD HH:MM:SS EST YYYY or Day Month DD HH:MM:SS YYYY --> 
								<xsl:when test="matches($apdate, '^[a-zA-Z]{3} [a-zA-Z]{3} ')">
									<premis:dateCreatedByApplication>
										<xsl:analyze-string select="$apdate" regex="[a-zA-Z]{{3}} ([a-zA-Z]{{3}}) (\d{{2}}) \d{{2}}:\d{{2}}:\d{{2}} [a-zA-Z ]{{0,4}}(\d{{4}})">
											<xsl:matching-substring>
												<xsl:variable name="month"><xsl:sequence select="regex-group(1)"/></xsl:variable>
												<!--year: already 4 digits-->
												<xsl:sequence select="regex-group(3)"/>
												<xsl:text>-</xsl:text>
												<!--month: converts from letter abbreviations to two-digit number-->
												<!--note: did not see all of these in the FITS output so it is possible some of these abbreviations are not correct-->
												<xsl:if test="$month = 'Jan'"><xsl:text>01</xsl:text></xsl:if>
												<xsl:if test="$month = 'Feb'"><xsl:text>02</xsl:text></xsl:if>
												<xsl:if test="$month = 'Mar'"><xsl:text>03</xsl:text></xsl:if>
												<xsl:if test="$month = 'Apr'"><xsl:text>04</xsl:text></xsl:if>
												<xsl:if test="$month = 'May'"><xsl:text>05</xsl:text></xsl:if>
												<xsl:if test="$month = 'Jun'"><xsl:text>06</xsl:text></xsl:if>
												<xsl:if test="$month = 'Jul'"><xsl:text>07</xsl:text></xsl:if>
												<xsl:if test="$month = 'Aug'"><xsl:text>08</xsl:text></xsl:if>
												<xsl:if test="$month = 'Sep'"><xsl:text>09</xsl:text></xsl:if>
												<xsl:if test="$month = 'Oct'"><xsl:text>10</xsl:text></xsl:if>
												<xsl:if test="$month = 'Nov'"><xsl:text>11</xsl:text></xsl:if>
												<xsl:if test="$month = 'Dec'"><xsl:text>12</xsl:text></xsl:if>
												<xsl:text>-</xsl:text>
												<!--day: already 2 digits-->
												<xsl:sequence select="regex-group(2)"/>
											</xsl:matching-substring>
										</xsl:analyze-string>
									</premis:dateCreatedByApplication>
								</xsl:when>
								
								<!--reformats date from MM/DD/YY HH:MM AM/PM -->
								<xsl:when test="matches($apdate, '\d{2}/\d{2}/\d{2} ')">
									<premis:dateCreatedByApplication>
										<xsl:analyze-string select="$apdate" regex="(\d{{2}})/(\d{{2}})/(\d{{2}}) ">
											<xsl:matching-substring>
												<xsl:variable name="year"><xsl:sequence select="regex-group(3)"/></xsl:variable>
												<!--year: converts from a two to four-digit year by adding a 20 for numbers less than 30 (since most like the 2000's) and a 19 for anything 30 or bigger (since most likely the 1900s')-->
												<xsl:choose>
													<xsl:when test="$year &lt; 30">
														<xsl:text>20</xsl:text><xsl:value-of select="$year"/>
													</xsl:when>
													<xsl:otherwise>
														<xsl:text>19</xsl:text><xsl:value-of select="$year"/>
													</xsl:otherwise>
												</xsl:choose>			
												<xsl:text>-</xsl:text>
												<!--month: already 2 digits-->
												<xsl:sequence select="regex-group(1)"/>
												<xsl:text>-</xsl:text>
												<!--day: already 2 digits-->
												<xsl:sequence select="regex-group(2)"/>
											</xsl:matching-substring>
										</xsl:analyze-string>
									</premis:dateCreatedByApplication>
								</xsl:when>
								
								<!--reformats date from M/D/YYYY H:M:SS (and sometimes ends in AM) -->
								<xsl:when test="matches($apdate, '\d{1,2}/\d{1,2}/\d{4} ')">
									<premis:dateCreatedByApplication>
										<xsl:analyze-string select="$apdate" regex="(\d{{1,2}})/(\d{{1,2}})/(\d{{4}}) ">
											<xsl:matching-substring>
												<xsl:variable name="month"><xsl:sequence select="regex-group(1)"/></xsl:variable>
												<xsl:variable name="day"><xsl:sequence select="regex-group(2)"/></xsl:variable>
												<!--year: already 4 digits-->
												<xsl:sequence select="regex-group(3)"/>	
												<xsl:text>-</xsl:text>
												<!--month: if it is a single digit, add a leading zero so the month is always a two-digit number-->
												<xsl:choose>
													<xsl:when test="$month &lt; 10">
															<xsl:text>0</xsl:text><xsl:value-of select="$month"/>
													</xsl:when>
													<xsl:otherwise>
															<xsl:value-of select="$month"/>
													</xsl:otherwise>	
												</xsl:choose>
												<xsl:text>-</xsl:text>
												<!--day: if it is a single digit, add a leading zero so the day is always a two-digit number-->
												<xsl:choose>
													<xsl:when test="$day &lt; 10">
														<xsl:text>0</xsl:text><xsl:value-of select="$day"/>
													</xsl:when>
													<xsl:otherwise>
														<xsl:value-of select="$day"/>
													</xsl:otherwise>	
												</xsl:choose>
											</xsl:matching-substring>
										</xsl:analyze-string>
									</premis:dateCreatedByApplication>
								</xsl:when>
								
								<!--if value of created is 0 in FITS, it will not create a premis:dateCreatedByApplication field-->
								<xsl:when test="$apdate='0'"/>
								
								<!--if created is an empty field in FITS, it will not create a premis:dateCreatedByApplication field-->
								<xsl:when test="$apdate=''"/>
								
								<!--if a date format is not yet accommodated in the stylesheet, it produces a premis:dateCreatedByApplication field that will cause the master.xml to not validate so staff know to add the new format-->
								<xsl:otherwise>
									<premis:dateCreatedByApplication><xsl:text>New Date Format Identified: Update Stylesheet</xsl:text></premis:dateCreatedByApplication>
								</xsl:otherwise>
								
							</xsl:choose>
						</premis:creatingApplication>
					</xsl:when>
					
					<!--if there is one name and zero or one version and date for a single file, makes a premis:creatingApplication section using the results from all three even if they were identified by different tools-->
					<xsl:otherwise>	
						<xsl:variable name="apversion">
							<xsl:if test="preceding-sibling::fits:creatingApplicationVersion"><xsl:value-of select="preceding-sibling::fits:creatingApplicationVersion"/></xsl:if>
							<xsl:if test="following-sibling::fits:creatingApplicationVersion"><xsl:value-of select="following-sibling::fits:creatingApplicationVersion"/></xsl:if>
						</xsl:variable>
						
						<xsl:variable name="apdate">
							<xsl:if test="preceding-sibling::fits:created"><xsl:value-of select="preceding-sibling::fits:created"/></xsl:if>
							<xsl:if test="following-sibling::fits:created"><xsl:value-of select="following-sibling::fits:created"/></xsl:if>
						</xsl:variable>
						
						<premis:creatingApplication>
							<premis:creatingApplicationName><xsl:value-of select="$apname"/></premis:creatingApplicationName>
							<!--checks that version has a value before putting premis:creatingApplicationVersion in the master.xml-->
							<xsl:if test="preceding-sibling::fits:creatingApplicationVersion/text() or preceding-sibling::fits:creatingApplicationVersion/text()">
								<premis:creatingApplicationVersion><xsl:value-of select="$apversion"/></premis:creatingApplicationVersion>
							</xsl:if>
							
							<!--gets date created by application from fits/fileinfo/created and reformats the date to the required format YYYY-MM-DD for any of the date format variations observed in FITS output so far-->
							<xsl:choose>
								
								<!--reformats date from YYYY:MM:DD HH:MM:SS or YYYY-MM-DD HH:MM:SS -->
								<!--already in the right order and right number of digits, so this one uses substring to select content before the space and then replaced the : with - for the required punctuation-->
								<xsl:when test="matches($apdate, '\d{4}:\d{2}:\d{2} ') or matches($apdate, '\d{4}-\d{2}-\d{2} ')">
									<premis:dateCreatedByApplication>
										<xsl:variable name="dateString"><xsl:value-of select="substring-before($apdate,' ')"/></xsl:variable>
										<xsl:value-of select="replace($dateString, ':', '-')"/>
									</premis:dateCreatedByApplication>
								</xsl:when>
								
								<!--reformats date from DayOfWeek, Month D, YYYY HH:MM:SS AM/PM -->
								<xsl:when test="matches($apdate, 'day')">
										<premis:dateCreatedByApplication>
											<xsl:analyze-string select="$apdate" regex="day, ([a-zA-Z]+) (\d{{1,2}}), (\d{{4}}) ">
												<xsl:matching-substring>
													<xsl:variable name="month"><xsl:sequence select="regex-group(1)"/></xsl:variable>
													<xsl:variable name='day'><xsl:sequence select="regex-group(2)"/></xsl:variable>
													<!--year: already 4 digits-->
													<xsl:sequence select="regex-group(3)"/>
													<xsl:text>-</xsl:text>
													<!--month: converts from words to two-digit number-->
													<xsl:if test="$month = 'January'"><xsl:text>01</xsl:text></xsl:if>
													<xsl:if test="$month = 'February'"><xsl:text>02</xsl:text></xsl:if>
													<xsl:if test="$month = 'March'"><xsl:text>03</xsl:text></xsl:if>
													<xsl:if test="$month = 'April'"><xsl:text>04</xsl:text></xsl:if>
													<xsl:if test="$month = 'May'"><xsl:text>05</xsl:text></xsl:if>
													<xsl:if test="$month = 'June'"><xsl:text>06</xsl:text></xsl:if>
													<xsl:if test="$month = 'July'"><xsl:text>07</xsl:text></xsl:if>
													<xsl:if test="$month = 'August'"><xsl:text>08</xsl:text></xsl:if>
													<xsl:if test="$month = 'September'"><xsl:text>09</xsl:text></xsl:if>
													<xsl:if test="$month = 'October'"><xsl:text>10</xsl:text></xsl:if>
													<xsl:if test="$month = 'November'"><xsl:text>11</xsl:text></xsl:if>
													<xsl:if test="$month = 'December'"><xsl:text>12</xsl:text></xsl:if>
													<xsl:text>-</xsl:text>
													<!--day: if it is a single digit, add a leading zero so the day is always a two-digit number-->
													<xsl:choose>
														<xsl:when test="$day &lt; 10">
															<xsl:text>0</xsl:text><xsl:value-of select="$day"/>
														</xsl:when>
														<xsl:otherwise>
															<xsl:value-of select="$day"/>
														</xsl:otherwise>	
													</xsl:choose>
												</xsl:matching-substring>
											</xsl:analyze-string>
										</premis:dateCreatedByApplication>
									</xsl:when>
									
									<!-- Reformats date from Day Month DD HH:MM:SS EST YYYY or Day Month DD HH:MM:SS YYYY --> 
									<xsl:when test="matches($apdate, '^[a-zA-Z]{3} [a-zA-Z]{3} ')">
										<premis:dateCreatedByApplication>
											<xsl:analyze-string select="$apdate" regex="[a-zA-Z]{{3}} ([a-zA-Z]{{3}}) (\d{{2}}) \d{{2}}:\d{{2}}:\d{{2}} [a-zA-Z ]{{0,4}}(\d{{4}})">
												<xsl:matching-substring>
													<xsl:variable name="month"><xsl:sequence select="regex-group(1)"/></xsl:variable>
													<!--year: already 4 digits-->
													<xsl:sequence select="regex-group(3)"/>
													<xsl:text>-</xsl:text>
													<!--month: converts from letter abbreviations to two-digit number-->
													<!--note: did not see all of these in the FITS output so it is possible some of these abbreviations are not correct-->
													<xsl:if test="$month = 'Jan'"><xsl:text>01</xsl:text></xsl:if>
													<xsl:if test="$month = 'Feb'"><xsl:text>02</xsl:text></xsl:if>
													<xsl:if test="$month = 'Mar'"><xsl:text>03</xsl:text></xsl:if>
													<xsl:if test="$month = 'Apr'"><xsl:text>04</xsl:text></xsl:if>
													<xsl:if test="$month = 'May'"><xsl:text>05</xsl:text></xsl:if>
													<xsl:if test="$month = 'Jun'"><xsl:text>06</xsl:text></xsl:if>
													<xsl:if test="$month = 'Jul'"><xsl:text>07</xsl:text></xsl:if>
													<xsl:if test="$month = 'Aug'"><xsl:text>08</xsl:text></xsl:if>
													<xsl:if test="$month = 'Sep'"><xsl:text>09</xsl:text></xsl:if>
													<xsl:if test="$month = 'Oct'"><xsl:text>10</xsl:text></xsl:if>
													<xsl:if test="$month = 'Nov'"><xsl:text>11</xsl:text></xsl:if>
													<xsl:if test="$month = 'Dec'"><xsl:text>12</xsl:text></xsl:if>
													<xsl:text>-</xsl:text>
													<!--day: already 2 digits-->
													<xsl:sequence select="regex-group(2)"/>
												</xsl:matching-substring>
											</xsl:analyze-string>
										</premis:dateCreatedByApplication>
									</xsl:when>
									
									<!--reformats date from MM/DD/YY HH:MM AM/PM -->
									<xsl:when test="matches($apdate, '\d{2}/\d{2}/\d{2} ')">
										<premis:dateCreatedByApplication>
											<xsl:analyze-string select="$apdate" regex="(\d{{2}})/(\d{{2}})/(\d{{2}}) ">
												<xsl:matching-substring>
													<xsl:variable name="year"><xsl:sequence select="regex-group(3)"/></xsl:variable>
													<!--year: converts from a two to four-digit year by adding a 20 for numbers less than 30 (since most like the 2000's) and a 19 for anything 30 or bigger (since most likely the 1900s')-->
													<xsl:choose>
														<xsl:when test="$year &lt; 30">
															<xsl:text>20</xsl:text><xsl:value-of select="$year"/>
														</xsl:when>
														<xsl:otherwise>
															<xsl:text>19</xsl:text><xsl:value-of select="$year"/>
														</xsl:otherwise>
													</xsl:choose>			
													<xsl:text>-</xsl:text>
													<!--month: already 2 digits-->
													<xsl:sequence select="regex-group(1)"/>
													<xsl:text>-</xsl:text>
													<!--day: already 2 digits-->
													<xsl:sequence select="regex-group(2)"/>
												</xsl:matching-substring>
											</xsl:analyze-string>
										</premis:dateCreatedByApplication>
									</xsl:when>
									
									<!--reformats date from M/D/YYYY H:M:SS (and sometimes ends in AM) -->
									<xsl:when test="matches($apdate, '\d{1,2}/\d{1,2}/\d{4} ')">
										<premis:dateCreatedByApplication>
											<xsl:analyze-string select="$apdate" regex="(\d{{1,2}})/(\d{{1,2}})/(\d{{4}})">
												<xsl:matching-substring>
													<xsl:variable name="month"><xsl:sequence select="regex-group(1)"/></xsl:variable>
													<xsl:variable name="day"><xsl:sequence select="regex-group(2)"/></xsl:variable>
													<!--year: already 4 digits-->
													<xsl:sequence select="regex-group(3)"/>	
													<xsl:text>-</xsl:text>
													<!--month: if it is a single digit, add a leading zero so the month is always a two-digit number-->
													<xsl:choose>
														<xsl:when test="$month &lt; 10">
																<xsl:text>0</xsl:text><xsl:value-of select="$month"/>
														</xsl:when>
														<xsl:otherwise>
																<xsl:value-of select="$month"/>
														</xsl:otherwise>	
													</xsl:choose>
													<xsl:text>-</xsl:text>
													<!--day: if it is a single digit, add a leading zero so the day is always a two-digit number-->
													<xsl:choose>
														<xsl:when test="$day &lt; 10">
															<xsl:text>0</xsl:text><xsl:value-of select="$day"/>
														</xsl:when>
														<xsl:otherwise>
															<xsl:value-of select="$day"/>
														</xsl:otherwise>	
													</xsl:choose>
												</xsl:matching-substring>
											</xsl:analyze-string>
										</premis:dateCreatedByApplication>
									</xsl:when>
									
									<!--if value of created is 0 in FITS, it will not create a premis:dateCreatedByApplication field-->
									<xsl:when test="$apdate='0'"/>
									
									<!--if created is an empty field in FITS, it will not create a premis:dateCreatedByApplication field-->
									<xsl:when test="$apdate=''"/>
									
									<!--if a date format is not yet accommodated in the stylesheet, it produces a premis:dateCreatedByApplication field that will cause the master.xml to not validate so staff know to add the new format-->
									<xsl:otherwise>
										<premis:dateCreatedByApplication><xsl:text>New Date Format Identified: Update Stylesheet</xsl:text></premis:dateCreatedByApplication>
									</xsl:otherwise>
									
								</xsl:choose>
						</premis:creatingApplication>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:if>
		</xsl:for-each>
	</xsl:template>
	
						
	<!--aip inhibitors list: PREMIS 1.5.6 (required if applicable)-->
	<!--gets inhibitors from fits/fileinfo-->
	<!--note: if there is a target that was identified by a tool that did not identify a type, the value of the target will not be included in the master.xml-->
	
	<xsl:template name="aip-inhibitors-list">
		<xsl:for-each select="//fits:fileinfo/fits:inhibitorType">
			<xsl:variable name="typetoolname" select="@toolname"/>
			<xsl:variable name="target">
				<xsl:if test="preceding-sibling::fits:inhibitorTarget[@toolname=$typetoolname]"><xsl:value-of select="preceding-sibling::fits:inhibitorTarget[@toolname=$typetoolname]"/></xsl:if>
				<xsl:if test="following-sibling::fits:inhibitorTarget[@toolname=$typetoolname]"><xsl:value-of select="following-sibling::fits:inhibitorTarget[@toolname=$typetoolname]"/></xsl:if>
			</xsl:variable>	
			
			<!--checks that the inhibitorTarget field has a value before putting premis:inhibitors in the master.xml-->
			<xsl:if test="./text()">
				<premis:inhibitors>
					<premis:inhibitorType><xsl:value-of select=".[@toolname=$typetoolname]"/></premis:inhibitorType>
					<xsl:if test="preceding-sibling::fits:inhibitorTarget[@toolname=$typetoolname] or following-sibling::fits:inhibitorTarget[@toolname=$typetoolname]">
						<premis:inhibitorTarget><xsl:value-of select="$target"/></premis:inhibitorTarget>
					</xsl:if>
				</premis:inhibitors>
			</xsl:if>
		</xsl:for-each>
	</xsl:template>	
	
	
	<!--aip relationship to collection: PREMIS 1.13 (required if applicable)-->
	<!--inserts the value for the identifier type (russell Library group uri) and gets the collection-id from the get-collection-id template at the end of this document-->
	
	<xsl:template name="relationship-collection">
		<premis:relationship>
			<premis:relationshipType><xsl:text>structural</xsl:text></premis:relationshipType>
			<premis:relationshipSubType><xsl:text>Is Member Of</xsl:text></premis:relationshipSubType>
			<premis:relatedObjectIdentifier>
				<premis:relatedObjectIdentifierType>	<xsl:text>http://archive.libs.uga.edu/russell</xsl:text></premis:relatedObjectIdentifierType>
				<premis:relatedObjectIdentifierValue><xsl:call-template name="get-collection-id"/></premis:relatedObjectIdentifierValue>
			</premis:relatedObjectIdentifier>
		</premis:relationship>
	</xsl:template>
		
		
	<!--  ........................................................................................................................................................................................................................................................................................................................-->
	<!-- TEMPLATES USING REGULAR EXPRESSIONS (used in the preceding aip and filelist templates) -->
	<!--  ........................................................................................................................................................................................................................................................................................................................-->
	
	
	<!--collection-id: gets collection-id from the first instance of fits/fileinfo/filepath in the FITS XML-->
	<!--collection-id may be formatted harg-ms####, harg-ua####, or harg-ua##-####-->
	<!--in the regular expression, selects the first time the match appears in the filepath in case the collection number is included in more than one place in the directory structure-->
	
	<xsl:template name="get-collection-id">
		<xsl:analyze-string select="(//fits:fileinfo/fits:filepath)[1]" regex="^.+?/(harg-[mu][sa]\d{{2,4}}-?\d{{0,4}})">
			<xsl:matching-substring><xsl:sequence select="regex-group(1)"/></xsl:matching-substring>
		</xsl:analyze-string>
	</xsl:template>
	
	
	<!--aip-id: gets aip-id from the first instance of fits/fileinfo/filepath in the FITS XML--> 
	<!--aip-id may be formatted harg-ms####er####,  harg-ua####er####, or harg-ua##-####er####-->
	<!--in the regular expression, selects the first time the match appears in the filepath in case the aip id is included in more than one place in the directory structure-->
	
	<xsl:template name="get-aip-id">
		<xsl:analyze-string select="(//fits:fileinfo/fits:filepath)[1]" regex="^.+?/(harg-[mu][sa]\d{{2,4}}-?\d{{0,4}}er\d{{4}})">
			<xsl:matching-substring><xsl:value-of select="regex-group(1)"/></xsl:matching-substring>
		</xsl:analyze-string>
	</xsl:template>
	
	
	<!--aip title: gets aip title from the first instance of fits/fileinfo/filepath in the FITS XML-->
	<!--filpath may be formatted any/thing/harg-ms####er####_AIP Title/anything/else.ext,  any/thing/harg-ua####er####_AIP Title/anything/else.ext, or any/thing/harg-ua##-####er####_AIP Title/anything/else.ext-->
	<!--in the regular expression, selects the first time the match appears in the filepath in case the aip title is included in more than one place in the directory structure-->
	
	<xsl:template name="get-aip-title">
		<xsl:analyze-string select="(//fits:fileinfo/fits:filepath)[1]" regex="^.+?/harg-[mu][sa]\d{{2,4}}-?\d{{0,4}}er\d{{4}}_(.*?)/">
			<xsl:matching-substring><xsl:value-of select="regex-group(1)"/></xsl:matching-substring>
		</xsl:analyze-string>
	</xsl:template>
	
</xsl:stylesheet>
