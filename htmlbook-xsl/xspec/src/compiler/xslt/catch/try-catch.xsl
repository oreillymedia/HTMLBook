<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/XSL/TransformAlias"
                xmlns:x="http://www.jenitennison.com/xslt/xspec"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="#all"
                version="3.0">

   <xsl:template name="x:try-catch" as="element(xsl:try)">
      <xsl:context-item use="absent" />

      <xsl:param name="instruction" as="element()" required="yes" />

      <try>
         <xsl:sequence select="$instruction" />
         <catch>
            <map>
               <map-entry key="'err'">
                  <map>
                     <!-- Variables available within xsl:catch:
                        https://www.w3.org/TR/xslt-30/#element-catch -->
                     <xsl:for-each
                        select="'code', 'description', 'value', 'module', 'line-number', 'column-number'">
                        <map-entry key="'{.}'" select="${x:known-UQName('err:' || .)}" />
                     </xsl:for-each>
                  </map>
               </map-entry>
            </map>
         </catch>
      </try>
   </xsl:template>

</xsl:stylesheet>