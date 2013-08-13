<?xml version="1.0" encoding="ASCII"?>
<!--This file was created automatically by html2xhtml-->
<!--from the HTML stylesheets.-->
<xsl:stylesheet version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
		xmlns:exslt="http://exslt.org/common"
		xmlns:h="http://www.w3.org/1999/xhtml"
		xmlns="http://www.w3.org/1999/xhtml" 
		extension-element-prefixes="exslt" 
		exclude-result-prefixes="exslt h">

<!-- Adapted from DocBook-XSL project index generation: xhtml/autoidx.xsl -->
<!-- At present, only supporting the "basic" method derived from Jeni Tennison's work. Not supporting "kosek" or "kimber" -->
<!-- ==================================================================== -->

<!-- ToDo: Enable support for @zones, @role, and @type by adding corresponding attribute support in HTMLBook spec, or otherwise, strip out related XSL -->
<!-- ToDo: EPUB 3 Index Spec conformant markup -->
<!-- Wishlist: Make sees and seealsos into real XREFs -->

  <xsl:output method="xml"
              encoding="UTF-8"/>

  <xsl:preserve-space elements="*"/>

  <xsl:variable name="index-letter-chars" select="'Aa&#192;&#224;&#193;&#225;&#194;&#226;&#195;&#227;&#196;&#228;&#197;&#229;&#256;&#257;&#258;&#259;&#260;&#261;&#461;&#462;&#478;&#479;&#480;&#481;&#506;&#507;&#512;&#513;&#514;&#515;&#550;&#551;&#7680;&#7681;&#7834;&#7840;&#7841;&#7842;&#7843;&#7844;&#7845;&#7846;&#7847;&#7848;&#7849;&#7850;&#7851;&#7852;&#7853;&#7854;&#7855;&#7856;&#7857;&#7858;&#7859;&#7860;&#7861;&#7862;&#7863;Bb&#384;&#385;&#595;&#386;&#387;&#7682;&#7683;&#7684;&#7685;&#7686;&#7687;Cc&#199;&#231;&#262;&#263;&#264;&#265;&#266;&#267;&#268;&#269;&#391;&#392;&#597;&#7688;&#7689;Dd&#270;&#271;&#272;&#273;&#394;&#599;&#395;&#396;&#453;&#498;&#545;&#598;&#7690;&#7691;&#7692;&#7693;&#7694;&#7695;&#7696;&#7697;&#7698;&#7699;Ee&#200;&#232;&#201;&#233;&#202;&#234;&#203;&#235;&#274;&#275;&#276;&#277;&#278;&#279;&#280;&#281;&#282;&#283;&#516;&#517;&#518;&#519;&#552;&#553;&#7700;&#7701;&#7702;&#7703;&#7704;&#7705;&#7706;&#7707;&#7708;&#7709;&#7864;&#7865;&#7866;&#7867;&#7868;&#7869;&#7870;&#7871;&#7872;&#7873;&#7874;&#7875;&#7876;&#7877;&#7878;&#7879;Ff&#401;&#402;&#7710;&#7711;Gg&#284;&#285;&#286;&#287;&#288;&#289;&#290;&#291;&#403;&#608;&#484;&#485;&#486;&#487;&#500;&#501;&#7712;&#7713;Hh&#292;&#293;&#294;&#295;&#542;&#543;&#614;&#7714;&#7715;&#7716;&#7717;&#7718;&#7719;&#7720;&#7721;&#7722;&#7723;&#7830;Ii&#204;&#236;&#205;&#237;&#206;&#238;&#207;&#239;&#296;&#297;&#298;&#299;&#300;&#301;&#302;&#303;&#304;&#407;&#616;&#463;&#464;&#520;&#521;&#522;&#523;&#7724;&#7725;&#7726;&#7727;&#7880;&#7881;&#7882;&#7883;Jj&#308;&#309;&#496;&#669;Kk&#310;&#311;&#408;&#409;&#488;&#489;&#7728;&#7729;&#7730;&#7731;&#7732;&#7733;Ll&#313;&#314;&#315;&#316;&#317;&#318;&#319;&#320;&#321;&#322;&#410;&#456;&#564;&#619;&#620;&#621;&#7734;&#7735;&#7736;&#7737;&#7738;&#7739;&#7740;&#7741;Mm&#625;&#7742;&#7743;&#7744;&#7745;&#7746;&#7747;Nn&#209;&#241;&#323;&#324;&#325;&#326;&#327;&#328;&#413;&#626;&#414;&#544;&#459;&#504;&#505;&#565;&#627;&#7748;&#7749;&#7750;&#7751;&#7752;&#7753;&#7754;&#7755;Oo&#210;&#242;&#211;&#243;&#212;&#244;&#213;&#245;&#214;&#246;&#216;&#248;&#332;&#333;&#334;&#335;&#336;&#337;&#415;&#416;&#417;&#465;&#466;&#490;&#491;&#492;&#493;&#510;&#511;&#524;&#525;&#526;&#527;&#554;&#555;&#556;&#557;&#558;&#559;&#560;&#561;&#7756;&#7757;&#7758;&#7759;&#7760;&#7761;&#7762;&#7763;&#7884;&#7885;&#7886;&#7887;&#7888;&#7889;&#7890;&#7891;&#7892;&#7893;&#7894;&#7895;&#7896;&#7897;&#7898;&#7899;&#7900;&#7901;&#7902;&#7903;&#7904;&#7905;&#7906;&#7907;Pp&#420;&#421;&#7764;&#7765;&#7766;&#7767;Qq&#672;Rr&#340;&#341;&#342;&#343;&#344;&#345;&#528;&#529;&#530;&#531;&#636;&#637;&#638;&#7768;&#7769;&#7770;&#7771;&#7772;&#7773;&#7774;&#7775;Ss&#346;&#347;&#348;&#349;&#350;&#351;&#352;&#353;&#536;&#537;&#642;&#7776;&#7777;&#7778;&#7779;&#7780;&#7781;&#7782;&#7783;&#7784;&#7785;Tt&#354;&#355;&#356;&#357;&#358;&#359;&#427;&#428;&#429;&#430;&#648;&#538;&#539;&#566;&#7786;&#7787;&#7788;&#7789;&#7790;&#7791;&#7792;&#7793;&#7831;Uu&#217;&#249;&#218;&#250;&#219;&#251;&#220;&#252;&#360;&#361;&#362;&#363;&#364;&#365;&#366;&#367;&#368;&#369;&#370;&#371;&#431;&#432;&#467;&#468;&#469;&#470;&#471;&#472;&#473;&#474;&#475;&#476;&#532;&#533;&#534;&#535;&#7794;&#7795;&#7796;&#7797;&#7798;&#7799;&#7800;&#7801;&#7802;&#7803;&#7908;&#7909;&#7910;&#7911;&#7912;&#7913;&#7914;&#7915;&#7916;&#7917;&#7918;&#7919;&#7920;&#7921;Vv&#434;&#651;&#7804;&#7805;&#7806;&#7807;Ww&#372;&#373;&#7808;&#7809;&#7810;&#7811;&#7812;&#7813;&#7814;&#7815;&#7816;&#7817;&#7832;Xx&#7818;&#7819;&#7820;&#7821;Yy&#221;&#253;&#255;&#376;&#374;&#375;&#435;&#436;&#562;&#563;&#7822;&#7823;&#7833;&#7922;&#7923;&#7924;&#7925;&#7926;&#7927;&#7928;&#7929;Zz&#377;&#378;&#379;&#380;&#381;&#382;&#437;&#438;&#548;&#549;&#656;&#657;&#7824;&#7825;&#7826;&#7827;&#7828;&#7829;&#7829;'"/>

<xsl:variable name="index-letter-chars-normalized" select="'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABBBBBBBBBBBBBCCCCCCCCCCCCCCCCCDDDDDDDDDDDDDDDDDDDDDDDDEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEFFFFFFGGGGGGGGGGGGGGGGGGGGHHHHHHHHHHHHHHHHHHHHIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIJJJJJJKKKKKKKKKKKKKKLLLLLLLLLLLLLLLLLLLLLLLLLLMMMMMMMMMNNNNNNNNNNNNNNNNNNNNNNNNNNNOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOPPPPPPPPQQQRRRRRRRRRRRRRRRRRRRRRRRSSSSSSSSSSSSSSSSSSSSSSSTTTTTTTTTTTTTTTTTTTTTTTTTUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUVVVVVVVVWWWWWWWWWWWWWWWXXXXXXYYYYYYYYYYYYYYYYYYYYYYYZZZZZZZZZZZZZZZZZZZZZ'"/>

<xsl:key name="letter" match="h:a[@data-type='indexterm']" use="translate(substring(normalize-space(concat(@data-primary-sortas, &quot; &quot;, @data-primary)), 1, 1),'Aa&#192;&#224;&#193;&#225;&#194;&#226;&#195;&#227;&#196;&#228;&#197;&#229;&#256;&#257;&#258;&#259;&#260;&#261;&#461;&#462;&#478;&#479;&#480;&#481;&#506;&#507;&#512;&#513;&#514;&#515;&#550;&#551;&#7680;&#7681;&#7834;&#7840;&#7841;&#7842;&#7843;&#7844;&#7845;&#7846;&#7847;&#7848;&#7849;&#7850;&#7851;&#7852;&#7853;&#7854;&#7855;&#7856;&#7857;&#7858;&#7859;&#7860;&#7861;&#7862;&#7863;Bb&#384;&#385;&#595;&#386;&#387;&#7682;&#7683;&#7684;&#7685;&#7686;&#7687;Cc&#199;&#231;&#262;&#263;&#264;&#265;&#266;&#267;&#268;&#269;&#391;&#392;&#597;&#7688;&#7689;Dd&#270;&#271;&#272;&#273;&#394;&#599;&#395;&#396;&#453;&#498;&#545;&#598;&#7690;&#7691;&#7692;&#7693;&#7694;&#7695;&#7696;&#7697;&#7698;&#7699;Ee&#200;&#232;&#201;&#233;&#202;&#234;&#203;&#235;&#274;&#275;&#276;&#277;&#278;&#279;&#280;&#281;&#282;&#283;&#516;&#517;&#518;&#519;&#552;&#553;&#7700;&#7701;&#7702;&#7703;&#7704;&#7705;&#7706;&#7707;&#7708;&#7709;&#7864;&#7865;&#7866;&#7867;&#7868;&#7869;&#7870;&#7871;&#7872;&#7873;&#7874;&#7875;&#7876;&#7877;&#7878;&#7879;Ff&#401;&#402;&#7710;&#7711;Gg&#284;&#285;&#286;&#287;&#288;&#289;&#290;&#291;&#403;&#608;&#484;&#485;&#486;&#487;&#500;&#501;&#7712;&#7713;Hh&#292;&#293;&#294;&#295;&#542;&#543;&#614;&#7714;&#7715;&#7716;&#7717;&#7718;&#7719;&#7720;&#7721;&#7722;&#7723;&#7830;Ii&#204;&#236;&#205;&#237;&#206;&#238;&#207;&#239;&#296;&#297;&#298;&#299;&#300;&#301;&#302;&#303;&#304;&#407;&#616;&#463;&#464;&#520;&#521;&#522;&#523;&#7724;&#7725;&#7726;&#7727;&#7880;&#7881;&#7882;&#7883;Jj&#308;&#309;&#496;&#669;Kk&#310;&#311;&#408;&#409;&#488;&#489;&#7728;&#7729;&#7730;&#7731;&#7732;&#7733;Ll&#313;&#314;&#315;&#316;&#317;&#318;&#319;&#320;&#321;&#322;&#410;&#456;&#564;&#619;&#620;&#621;&#7734;&#7735;&#7736;&#7737;&#7738;&#7739;&#7740;&#7741;Mm&#625;&#7742;&#7743;&#7744;&#7745;&#7746;&#7747;Nn&#209;&#241;&#323;&#324;&#325;&#326;&#327;&#328;&#413;&#626;&#414;&#544;&#459;&#504;&#505;&#565;&#627;&#7748;&#7749;&#7750;&#7751;&#7752;&#7753;&#7754;&#7755;Oo&#210;&#242;&#211;&#243;&#212;&#244;&#213;&#245;&#214;&#246;&#216;&#248;&#332;&#333;&#334;&#335;&#336;&#337;&#415;&#416;&#417;&#465;&#466;&#490;&#491;&#492;&#493;&#510;&#511;&#524;&#525;&#526;&#527;&#554;&#555;&#556;&#557;&#558;&#559;&#560;&#561;&#7756;&#7757;&#7758;&#7759;&#7760;&#7761;&#7762;&#7763;&#7884;&#7885;&#7886;&#7887;&#7888;&#7889;&#7890;&#7891;&#7892;&#7893;&#7894;&#7895;&#7896;&#7897;&#7898;&#7899;&#7900;&#7901;&#7902;&#7903;&#7904;&#7905;&#7906;&#7907;Pp&#420;&#421;&#7764;&#7765;&#7766;&#7767;Qq&#672;Rr&#340;&#341;&#342;&#343;&#344;&#345;&#528;&#529;&#530;&#531;&#636;&#637;&#638;&#7768;&#7769;&#7770;&#7771;&#7772;&#7773;&#7774;&#7775;Ss&#346;&#347;&#348;&#349;&#350;&#351;&#352;&#353;&#536;&#537;&#642;&#7776;&#7777;&#7778;&#7779;&#7780;&#7781;&#7782;&#7783;&#7784;&#7785;Tt&#354;&#355;&#356;&#357;&#358;&#359;&#427;&#428;&#429;&#430;&#648;&#538;&#539;&#566;&#7786;&#7787;&#7788;&#7789;&#7790;&#7791;&#7792;&#7793;&#7831;Uu&#217;&#249;&#218;&#250;&#219;&#251;&#220;&#252;&#360;&#361;&#362;&#363;&#364;&#365;&#366;&#367;&#368;&#369;&#370;&#371;&#431;&#432;&#467;&#468;&#469;&#470;&#471;&#472;&#473;&#474;&#475;&#476;&#532;&#533;&#534;&#535;&#7794;&#7795;&#7796;&#7797;&#7798;&#7799;&#7800;&#7801;&#7802;&#7803;&#7908;&#7909;&#7910;&#7911;&#7912;&#7913;&#7914;&#7915;&#7916;&#7917;&#7918;&#7919;&#7920;&#7921;Vv&#434;&#651;&#7804;&#7805;&#7806;&#7807;Ww&#372;&#373;&#7808;&#7809;&#7810;&#7811;&#7812;&#7813;&#7814;&#7815;&#7816;&#7817;&#7832;Xx&#7818;&#7819;&#7820;&#7821;Yy&#221;&#253;&#255;&#376;&#374;&#375;&#435;&#436;&#562;&#563;&#7822;&#7823;&#7833;&#7922;&#7923;&#7924;&#7925;&#7926;&#7927;&#7928;&#7929;Zz&#377;&#378;&#379;&#380;&#381;&#382;&#437;&#438;&#548;&#549;&#656;&#657;&#7824;&#7825;&#7826;&#7827;&#7828;&#7829;&#7829;','AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABBBBBBBBBBBBBCCCCCCCCCCCCCCCCCDDDDDDDDDDDDDDDDDDDDDDDDEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEFFFFFFGGGGGGGGGGGGGGGGGGGGHHHHHHHHHHHHHHHHHHHHIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIJJJJJJKKKKKKKKKKKKKKLLLLLLLLLLLLLLLLLLLLLLLLLLMMMMMMMMMNNNNNNNNNNNNNNNNNNNNNNNNNNNOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOPPPPPPPPQQQRRRRRRRRRRRRRRRRRRRRRRRSSSSSSSSSSSSSSSSSSSSSSSTTTTTTTTTTTTTTTTTTTTTTTTTUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUVVVVVVVVWWWWWWWWWWWWWWWXXXXXXYYYYYYYYYYYYYYYYYYYYYYYZZZZZZZZZZZZZZZZZZZZZ')"/>

<xsl:key name="primary" match="h:a[@data-type='indexterm']" use="normalize-space(concat(@data-primary-sortas, &quot; &quot;, @data-primary))"/>

<xsl:key name="secondary" match="h:a[@data-type='indexterm']" use="concat(normalize-space(concat(@data-primary-sortas, &quot; &quot;, @data-primary)), &quot; &quot;, normalize-space(concat(@data-secondary-sortas, &quot; &quot;, @data-secondary)))"/>

<xsl:key name="tertiary" match="h:a[@data-type='indexterm']" use="concat(normalize-space(concat(@data-primary-sortas, &quot; &quot;, @data-primary)), &quot; &quot;, normalize-space(concat(@data-secondary-sortas, &quot; &quot;, @data-secondary)), &quot; &quot;, normalize-space(concat(@data-tertiary-sortas, &quot; &quot;, @data-tertiary)))"/>

<xsl:key name="endofrange" match="h:a[@data-type='indexterm' and @data-startref]" use="@data-startref"/>

<xsl:key name="primary-section" match="h:a[@data-type='indexterm'][not(@data-secondary) and not(@data-see)]" use="concat(normalize-space(concat(@data-primary-sortas, &quot; &quot;, @data-primary)), &quot; &quot;, generate-id((ancestor-or-self::h:body|ancestor-or-self::h:nav|ancestor-or-self::h:div[@data-type='part']|ancestor-or-self::h:section)[last()]))"/>

<xsl:key name="secondary-section" match="h:a[@data-type='indexterm'][not(@data-tertiary) and not(@data-see)]" use="concat(normalize-space(concat(@data-primary-sortas, &quot; &quot;, @data-primary)), &quot; &quot;, normalize-space(concat(@data-secondary-sortas, &quot; &quot;, @data-secondary)), &quot; &quot;, generate-id((ancestor-or-self::h:body|ancestor-or-self::h:nav|ancestor-or-self::h:div[@data-type='part']|ancestor-or-self::h:section)[last()]))"/>

<xsl:key name="tertiary-section" match="h:a[@data-type='indexterm'][not(@data-see)]" use="concat(normalize-space(concat(@data-primary-sortas, &quot; &quot;, @data-primary)), &quot; &quot;, normalize-space(concat(@data-secondary-sortas, &quot; &quot;, @data-secondary)), &quot; &quot;, normalize-space(concat(@data-tertiary-sortas, &quot; &quot;, @data-tertiary)), &quot; &quot;, generate-id((ancestor-or-self::h:body|ancestor-or-self::h:nav|ancestor-or-self::h:div[@data-type='part']|ancestor-or-self::h:section)[last()]))"/>

<xsl:key name="see-also" match="h:a[@data-type='indexterm'][@data-seealso]" use="concat(normalize-space(concat(@data-primary-sortas, &quot; &quot;, @data-primary)), &quot; &quot;, normalize-space(concat(@data-secondary-sortas, &quot; &quot;, @data-secondary)), &quot; &quot;, normalize-space(concat(@data-tertiary-sortas, &quot; &quot;, @data-tertiary)), &quot; &quot;, @data-seealso)"/>

<xsl:key name="see" match="h:a[@data-type='indexterm'][@data-see]" use="concat(normalize-space(concat(@data-primary-sortas, &quot; &quot;, @data-primary)), &quot; &quot;, normalize-space(concat(@data-secondary-sortas, &quot; &quot;, @data-secondary)), &quot; &quot;, normalize-space(concat(@data-tertiary-sortas, &quot; &quot;, @data-tertiary)), &quot; &quot;, @data-see)"/>

<xsl:key name="sections" match="*[@id or @xml:id]" use="@id|@xml:id"/>

<xsl:template match="h:section[@data-type='index']">
  <xsl:variable name="output-element-name">
    <xsl:call-template name="html.output.element"/>
  </xsl:variable>
  <xsl:choose>
    <!-- If autogenerate-index is enabled, and it's the first index-placeholder-element, and it's either empty or overwrite-contents is specified, then
	 go ahead and generate the Index here -->
    <xsl:when test="($autogenerate-index = 1) and 
		    (not(preceding::h:section[@data-type='index'])) and
		    (not(node()) or $index-placeholder-overwrite-contents != 0)">
      <xsl:element name="{$output-element-name}" namespace="http://www.w3.org/1999/xhtml">
	<xsl:apply-templates select="@*[not(local-name() = 'id')]"/>
	<xsl:attribute name="id">
	  <xsl:call-template name="object.id"/>
	</xsl:attribute>
	<h1>
	  <xsl:call-template name="get-localization-value">
	    <xsl:with-param name="gentext-key" select="'index'"/>
	  </xsl:call-template>
	</h1>
	<xsl:call-template name="generate-index"/>
      </xsl:element>
    </xsl:when>
    <xsl:otherwise>
      <!-- Otherwise, just process as normal -->
      <!-- ToDo: Consider using <xsl:apply-imports> here, depending on how we decide to do stylesheet layering for packaging for EPUB, etc. -->
      <xsl:element name="{$output-element-name}" namespace="http://www.w3.org/1999/xhtml">
	<xsl:apply-templates select="@*[not(local-name() = 'id')]"/>
	<xsl:attribute name="id">
	  <xsl:call-template name="object.id"/>
	</xsl:attribute>
	<xsl:apply-templates/>
      </xsl:element>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template name="generate-index">
  <xsl:param name="scope" select="(ancestor::h:body[@data-type='book']|/)[last()]"/>

  <xsl:call-template name="generate-basic-index">
    <xsl:with-param name="scope" select="$scope"/>
  </xsl:call-template>

</xsl:template>
      
<xsl:template name="generate-basic-index">
  <xsl:param name="scope" select="NOTANODE"/>

  <xsl:variable name="role">
    <xsl:if test="$index.on.role != 0">
      <xsl:value-of select="@role"/>
    </xsl:if>
  </xsl:variable>

  <xsl:variable name="type">
    <xsl:if test="$index.on.type != 0">
      <xsl:value-of select="@type"/>
    </xsl:if>
  </xsl:variable>

  <xsl:variable name="terms" select="//h:a[@data-type='indexterm']                         [count(.|key('letter',                           translate(substring(normalize-space(concat(@data-primary-sortas, &quot; &quot;, @data-primary)), 1, 1),                              $index-letter-chars,                              $index-letter-chars-normalized))                           [count(ancestor::node()|$scope) = count(ancestor::node()) and ($role = @role or $type = @type or (string-length($role) = 0 and string-length($type) = 0))][1]) = 1                           and not(@data-startref)]"/>

  <xsl:variable name="alphabetical" select="$terms[contains(concat($index-letter-chars, $index-letter-chars-normalized),                                         substring(normalize-space(concat(@data-primary-sortas, &quot; &quot;, @data-primary)), 1, 1))]"/>

  <xsl:variable name="others" select="$terms[not(contains(concat($index-letter-chars,                                                  $index-letter-chars-normalized),                                              substring(normalize-space(concat(@data-primary-sortas, &quot; &quot;, @data-primary)), 1, 1)))]"/>
  <div data-type="index">
    <xsl:if test="$others">
      <xsl:choose>
        <xsl:when test="normalize-space($type) != '' and                          $others[@type = $type][count(.|key('primary', normalize-space(concat(@data-primary-sortas, &quot; &quot;, @data-primary)))[count(ancestor::node()|$scope) = count(ancestor::node()) and ($role = @role or $type = @type or (string-length($role) = 0 and string-length($type) = 0))][1]) = 1]">
          <div data-type="indexdiv">
            <h3>
	      <!-- data-gentext provided so that you can do a CSS override for localization, if desired -->
	      <span data-gentext="indexsymbols">
		<xsl:call-template name="get-localization-value">
		  <xsl:with-param name="gentext-key" select="'index symbols'"/>
		</xsl:call-template>
	      </span>
            </h3>
            <ul>
              <xsl:apply-templates select="$others[count(.|key('primary', normalize-space(concat(@data-primary-sortas, &quot; &quot;, @data-primary)))[count(ancestor::node()|$scope) = count(ancestor::node()) and ($role = @role or $type = @type or (string-length($role) = 0 and string-length($type) = 0))][1]) = 1]" mode="index-symbol-div">
                <xsl:with-param name="position" select="position()"/>                                
                <xsl:with-param name="scope" select="$scope"/>
                <xsl:with-param name="role" select="$role"/>
                <xsl:with-param name="type" select="$type"/>
                <xsl:sort select="translate(normalize-space(concat(@data-primary-sortas, &quot; &quot;, @data-primary)), $index-letter-chars, $index-letter-chars-normalized)"/>
              </xsl:apply-templates>
            </ul>
          </div>
        </xsl:when>
        <xsl:when test="normalize-space($type) != ''"> 
          <!-- Output nothing, as there isn't a match for $other using this $type -->
        </xsl:when>  
        <xsl:otherwise>
          <div data-type="indexdiv">
            <h3>
	      <!-- data-gentext provided so that you can do a CSS override for localization, if desired -->
	      <span data-gentext="indexsymbols">
		<xsl:call-template name="get-localization-value">
		  <xsl:with-param name="gentext-key" select="'index symbols'"/>
		</xsl:call-template>
	      </span>
            </h3>
            <ul>
              <xsl:apply-templates select="$others[count(.|key('primary',                                           normalize-space(concat(@data-primary-sortas, &quot; &quot;, @data-primary)))[count(ancestor::node()|$scope) = count(ancestor::node()) and ($role = @role or $type = @type or (string-length($role) = 0 and string-length($type) = 0))][1]) = 1]" mode="index-symbol-div">
                <xsl:with-param name="position" select="position()"/>                                
                <xsl:with-param name="scope" select="$scope"/>
                <xsl:with-param name="role" select="$role"/>
                <xsl:with-param name="type" select="$type"/>
                <xsl:sort select="translate(normalize-space(concat(@data-primary-sortas, &quot; &quot;, @data-primary)), $index-letter-chars, $index-letter-chars-normalized)"/>
              </xsl:apply-templates>
            </ul>
          </div>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>

    <xsl:apply-templates select="$alphabetical[count(.|key('letter',                                  translate(substring(normalize-space(concat(@data-primary-sortas, &quot; &quot;, @data-primary)), 1, 1),                                            $index-letter-chars,$index-letter-chars-normalized))[count(ancestor::node()|$scope) = count(ancestor::node()) and ($role = @role or $type = @type or (string-length($role) = 0 and string-length($type) = 0))][1]) = 1]" mode="index-div-basic">
      <xsl:with-param name="position" select="position()"/>
      <xsl:with-param name="scope" select="$scope"/>
      <xsl:with-param name="role" select="$role"/>
      <xsl:with-param name="type" select="$type"/>
      <xsl:sort select="translate(normalize-space(concat(@data-primary-sortas, &quot; &quot;, @data-primary)), $index-letter-chars, $index-letter-chars-normalized)"/>
    </xsl:apply-templates>
  </div>
</xsl:template>

<xsl:template match="h:a[@data-type='indexterm']" mode="index-div-basic">
  <xsl:param name="scope" select="."/>
  <xsl:param name="role" select="''"/>
  <xsl:param name="type" select="''"/>

  <xsl:variable name="key" select="translate(substring(normalize-space(concat(@data-primary-sortas, &quot; &quot;, @data-primary)), 1, 1),                          $index-letter-chars,$index-letter-chars-normalized)"/>

  <xsl:if test="key('letter', $key)[count(ancestor::node()|$scope) = count(ancestor::node()) and ($role = @role or $type = @type or (string-length($role) = 0 and string-length($type) = 0))]                 [count(.|key('primary', normalize-space(concat(@data-primary-sortas, &quot; &quot;, @data-primary)))[count(ancestor::node()|$scope) = count(ancestor::node()) and ($role = @role or $type = @type or (string-length($role) = 0 and string-length($type) = 0))][1]) = 1]">
    <div data-type="indexdiv">
      <xsl:if test="contains(concat($index-letter-chars, $index-letter-chars-normalized), $key)">
        <h3>
          <xsl:value-of select="translate($key, $index-letter-chars, $index-letter-chars-normalized)"/>
        </h3>
      </xsl:if>
      <ul>
        <xsl:apply-templates select="key('letter', $key)[count(ancestor::node()|$scope) = count(ancestor::node()) and ($role = @role or $type = @type or (string-length($role) = 0 and string-length($type) = 0))]                                      [count(.|key('primary', normalize-space(concat(@data-primary-sortas, &quot; &quot;, @data-primary)))                                      [count(ancestor::node()|$scope) = count(ancestor::node()) and ($role = @role or $type = @type or (string-length($role) = 0 and string-length($type) = 0))][1])=1]" mode="index-primary">
          <xsl:with-param name="position" select="position()"/>
          <xsl:with-param name="scope" select="$scope"/>
          <xsl:with-param name="role" select="$role"/>
          <xsl:with-param name="type" select="$type"/>
          <xsl:sort select="translate(normalize-space(concat(@data-primary-sortas, &quot; &quot;, @data-primary)), $index-letter-chars, $index-letter-chars-normalized)"/>
        </xsl:apply-templates>
      </ul>
    </div>
  </xsl:if>
</xsl:template>

<xsl:template match="h:a[@data-type='indexterm']" mode="index-symbol-div">
  <xsl:param name="scope" select="/"/>
  <xsl:param name="role" select="''"/>
  <xsl:param name="type" select="''"/>

  <xsl:variable name="key" select="translate(substring(normalize-space(concat(@data-primary-sortas, &quot; &quot;, @data-primary)), 1, 1),                                              $index-letter-chars,$index-letter-chars-normalized)"/>

  <xsl:apply-templates select="key('letter', $key)                                [count(ancestor::node()|$scope) = count(ancestor::node()) and ($role = @role or $type = @type or (string-length($role) = 0 and string-length($type) = 0))][count(.|key('primary', normalize-space(concat(@data-primary-sortas, &quot; &quot;, @data-primary)))[1]) = 1]" mode="index-primary">
    <xsl:with-param name="position" select="position()"/>
    <xsl:with-param name="scope" select="$scope"/>
    <xsl:with-param name="role" select="$role"/>
    <xsl:with-param name="type" select="$type"/>
    <xsl:sort select="translate(normalize-space(concat(@data-primary-sortas, &quot; &quot;, @data-primary)), $index-letter-chars, $index-letter-chars-normalized)"/>
  </xsl:apply-templates>
</xsl:template>

<xsl:template match="h:a[@data-type='indexterm']" mode="index-primary">
  <xsl:param name="scope" select="."/>
  <xsl:param name="role" select="''"/>
  <xsl:param name="type" select="''"/>

  <xsl:variable name="key" select="normalize-space(concat(@data-primary-sortas, &quot; &quot;, @data-primary))"/>
  <xsl:variable name="refs" select="key('primary', $key)[count(ancestor::node()|$scope) = count(ancestor::node()) and ($role = @role or $type = @type or (string-length($role) = 0 and string-length($type) = 0)) and not(@data-startref)]"/>
  <li>
    <xsl:value-of select="@data-primary"/>
    <xsl:choose>
      <xsl:when test="$index.links.to.section = 1">
        <xsl:for-each select="$refs[@zone != '' or generate-id() = generate-id(key('primary-section', concat($key, &quot; &quot;, generate-id((ancestor-or-self::h:body|ancestor-or-self::h:nav|ancestor-or-self::h:div[@data-type='part']|ancestor-or-self::h:section)[last()])))[count(ancestor::node()|$scope) = count(ancestor::node()) and ($role = @role or $type = @type or (string-length($role) = 0 and string-length($type) = 0))][1])]">
          <xsl:apply-templates select="." mode="reference">
            <xsl:with-param name="position" select="position()"/>
            <xsl:with-param name="scope" select="$scope"/>
            <xsl:with-param name="role" select="$role"/>
            <xsl:with-param name="type" select="$type"/>
          </xsl:apply-templates>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <xsl:for-each select="$refs[not(@data-see)                                and not(@data-secondary)][count(ancestor::node()|$scope) = count(ancestor::node()) and ($role = @role or $type = @type or (string-length($role) = 0 and string-length($type) = 0))]">
          <xsl:apply-templates select="." mode="reference">
            <xsl:with-param name="position" select="position()"/>
            <xsl:with-param name="scope" select="$scope"/>
            <xsl:with-param name="role" select="$role"/>
            <xsl:with-param name="type" select="$type"/>
          </xsl:apply-templates>
        </xsl:for-each>
      </xsl:otherwise>
    </xsl:choose>

    <xsl:if test="$refs[not(@data-secondary)]/@data-see">
      <xsl:apply-templates select="$refs[generate-id() = generate-id(key('see', concat(normalize-space(concat(@data-primary-sortas, &quot; &quot;, @data-primary)), &quot; &quot;, &quot; &quot;, &quot; &quot;, @data-see))[count(ancestor::node()|$scope) = count(ancestor::node()) and ($role = @role or $type = @type or (string-length($role) = 0 and string-length($type) = 0))][1])]" mode="index-see">
        <xsl:with-param name="position" select="position()"/>
        <xsl:with-param name="scope" select="$scope"/>
        <xsl:with-param name="role" select="$role"/>
        <xsl:with-param name="type" select="$type"/>
        <xsl:sort select="translate(@data-see, $index-letter-chars, $index-letter-chars-normalized)"/>
      </xsl:apply-templates>
    </xsl:if>
    <xsl:if test="$refs/@data-secondary or $refs[not(@data-secondary)]/@data-seealso">
      <ul>
        <xsl:apply-templates select="$refs[generate-id() = generate-id(key('see-also', concat(normalize-space(concat(@data-primary-sortas, &quot; &quot;, @data-primary)), &quot; &quot;, &quot; &quot;, &quot; &quot;, @data-seealso))[count(ancestor::node()|$scope) = count(ancestor::node()) and ($role = @role or $type = @type or (string-length($role) = 0 and string-length($type) = 0))][1])]" mode="index-seealso">
          <xsl:with-param name="position" select="position()"/>
          <xsl:with-param name="scope" select="$scope"/>
          <xsl:with-param name="role" select="$role"/>
          <xsl:with-param name="type" select="$type"/>
          <xsl:sort select="translate(@data-seealso, $index-letter-chars, $index-letter-chars-normalized)"/>
        </xsl:apply-templates>
        <xsl:apply-templates select="$refs[@data-secondary and count(.|key('secondary', concat($key, &quot; &quot;, normalize-space(concat(@data-secondary-sortas, &quot; &quot;, @data-secondary))))[count(ancestor::node()|$scope) = count(ancestor::node()) and ($role = @role or $type = @type or (string-length($role) = 0 and string-length($type) = 0))][1]) = 1]" mode="index-secondary">
          <xsl:with-param name="position" select="position()"/>
          <xsl:with-param name="scope" select="$scope"/>
          <xsl:with-param name="role" select="$role"/>
          <xsl:with-param name="type" select="$type"/>
          <xsl:sort select="translate(normalize-space(concat(@data-secondary-sortas, &quot; &quot;, @data-secondary)), $index-letter-chars, $index-letter-chars-normalized)"/>
        </xsl:apply-templates>
      </ul>
    </xsl:if>
  </li>
</xsl:template>

<xsl:template match="h:a[@data-type='indexterm']" mode="index-secondary">
  <xsl:param name="scope" select="."/>
  <xsl:param name="role" select="''"/>
  <xsl:param name="type" select="''"/>

  <xsl:variable name="key" select="concat(normalize-space(concat(@data-primary-sortas, &quot; &quot;, @data-primary)), &quot; &quot;, normalize-space(concat(@data-secondary-sortas, &quot; &quot;, @data-secondary)))"/>
  <xsl:variable name="refs" select="key('secondary', $key)[count(ancestor::node()|$scope) = count(ancestor::node()) and ($role = @role or $type = @type or (string-length($role) = 0 and string-length($type) = 0)) and not(@data-startref)]"/>
  <li>
    <xsl:value-of select="@data-secondary"/>
    <xsl:choose>
      <xsl:when test="$index.links.to.section = 1">
        <xsl:for-each select="$refs[@zone != '' or generate-id() = generate-id(key('secondary-section', concat($key, &quot; &quot;, generate-id((ancestor-or-self::h:body|ancestor-or-self::h:nav|ancestor-or-self::h:div[@data-type='part']|ancestor-or-self::h:section)[last()])))[count(ancestor::node()|$scope) = count(ancestor::node()) and ($role = @role or $type = @type or (string-length($role) = 0 and string-length($type) = 0))][1])]">
          <xsl:apply-templates select="." mode="reference">
            <xsl:with-param name="position" select="position()"/>
            <xsl:with-param name="scope" select="$scope"/>
            <xsl:with-param name="role" select="$role"/>
            <xsl:with-param name="type" select="$type"/>
          </xsl:apply-templates>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <xsl:for-each select="$refs[not(@data-see)                                  and not(@data-tertiary)][count(ancestor::node()|$scope) = count(ancestor::node()) and ($role = @role or $type = @type or (string-length($role) = 0 and string-length($type) = 0))]">
          <xsl:apply-templates select="." mode="reference">
            <xsl:with-param name="position" select="position()"/>
            <xsl:with-param name="scope" select="$scope"/>
            <xsl:with-param name="role" select="$role"/>
            <xsl:with-param name="type" select="$type"/>
          </xsl:apply-templates>
        </xsl:for-each>
      </xsl:otherwise>
    </xsl:choose>

    <xsl:if test="$refs[not(@data-tertiary)]/@data-see">
      <xsl:apply-templates select="$refs[generate-id() = generate-id(key('see', concat(normalize-space(concat(@data-primary-sortas, &quot; &quot;, @data-primary)), &quot; &quot;, normalize-space(concat(@data-secondary-sortas, &quot; &quot;, @data-secondary)), &quot; &quot;, &quot; &quot;, @data-see))[count(ancestor::node()|$scope) = count(ancestor::node()) and ($role = @role or $type = @type or (string-length($role) = 0 and string-length($type) = 0))][1])]" mode="index-see">
        <xsl:with-param name="position" select="position()"/>
        <xsl:with-param name="scope" select="$scope"/>
        <xsl:with-param name="role" select="$role"/>
        <xsl:with-param name="type" select="$type"/>
        <xsl:sort select="translate(@data-see, $index-letter-chars, $index-letter-chars-normalized)"/>
      </xsl:apply-templates>
    </xsl:if>
    <xsl:if test="$refs/@data-tertiary or $refs[not(@data-tertiary)]/@data-seealso">
      <ul>
        <xsl:apply-templates select="$refs[generate-id() = generate-id(key('see-also', concat(normalize-space(concat(@data-primary-sortas, &quot; &quot;, @data-primary)), &quot; &quot;, normalize-space(concat(@data-secondary-sortas, &quot; &quot;, @data-secondary)), &quot; &quot;, &quot; &quot;, @data-seealso))[count(ancestor::node()|$scope) = count(ancestor::node()) and ($role = @role or $type = @type or (string-length($role) = 0 and string-length($type) = 0))][1])]" mode="index-seealso">
          <xsl:with-param name="position" select="position()"/>
          <xsl:with-param name="scope" select="$scope"/>
          <xsl:with-param name="role" select="$role"/>
          <xsl:with-param name="type" select="$type"/>
          <xsl:sort select="translate(@data-seealso, $index-letter-chars, $index-letter-chars-normalized)"/>
        </xsl:apply-templates>
        <xsl:apply-templates select="$refs[@data-tertiary and count(.|key('tertiary', concat($key, &quot; &quot;, normalize-space(concat(@data-tertiary-sortas, &quot; &quot;, @data-tertiary))))[count(ancestor::node()|$scope) = count(ancestor::node()) and ($role = @role or $type = @type or (string-length($role) = 0 and string-length($type) = 0))][1]) = 1]" mode="index-tertiary">
          <xsl:with-param name="position" select="position()"/>
          <xsl:with-param name="scope" select="$scope"/>
          <xsl:with-param name="role" select="$role"/>
          <xsl:with-param name="type" select="$type"/>
          <xsl:sort select="translate(normalize-space(concat(@data-tertiary-sortas, &quot; &quot;, @data-tertiary)), $index-letter-chars, $index-letter-chars-normalized)"/>
        </xsl:apply-templates>
      </ul>
    </xsl:if>
  </li>
</xsl:template>

<xsl:template match="h:a[@data-type='indexterm']" mode="index-tertiary">
  <xsl:param name="scope" select="."/>
  <xsl:param name="role" select="''"/>
  <xsl:param name="type" select="''"/>

  <xsl:variable name="key" select="concat(normalize-space(concat(@data-primary-sortas, &quot; &quot;, @data-primary)), &quot; &quot;, normalize-space(concat(@data-secondary-sortas, &quot; &quot;, @data-secondary)), &quot; &quot;, normalize-space(concat(@data-tertiary-sortas, &quot; &quot;, @data-tertiary)))"/>
  <xsl:variable name="refs" select="key('tertiary', $key)[count(ancestor::node()|$scope) = count(ancestor::node()) and ($role = @role or $type = @type or (string-length($role) = 0 and string-length($type) = 0)) and not(@data-startref)]"/>
  <li>
    <xsl:value-of select="@data-tertiary"/>
    <xsl:choose>
      <xsl:when test="$index.links.to.section = 1">
        <xsl:for-each select="$refs[@zone != '' or generate-id() = generate-id(key('tertiary-section', concat($key, &quot; &quot;, generate-id((ancestor-or-self::h:body|ancestor-or-self::h:nav|ancestor-or-self::h:div[@data-type='part']|ancestor-or-self::h:section)[last()])))[count(ancestor::node()|$scope) = count(ancestor::node()) and ($role = @role or $type = @type or (string-length($role) = 0 and string-length($type) = 0))][1])]">
          <xsl:apply-templates select="." mode="reference">
            <xsl:with-param name="position" select="position()"/>
            <xsl:with-param name="scope" select="$scope"/>
            <xsl:with-param name="role" select="$role"/>
            <xsl:with-param name="type" select="$type"/>
          </xsl:apply-templates>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <xsl:for-each select="$refs[not(@data-see)][count(ancestor::node()|$scope) = count(ancestor::node()) and ($role = @role or $type = @type or (string-length($role) = 0 and string-length($type) = 0))]">
          <xsl:apply-templates select="." mode="reference">
            <xsl:with-param name="position" select="position()"/>
            <xsl:with-param name="scope" select="$scope"/>
            <xsl:with-param name="role" select="$role"/>
            <xsl:with-param name="type" select="$type"/>
          </xsl:apply-templates>
        </xsl:for-each>
      </xsl:otherwise>
    </xsl:choose>

    <xsl:if test="$refs/@data-see">
      <xsl:apply-templates select="$refs[generate-id() = generate-id(key('see', concat(normalize-space(concat(@data-primary-sortas, &quot; &quot;, @data-primary)), &quot; &quot;, normalize-space(concat(@data-secondary-sortas, &quot; &quot;, @data-secondary)), &quot; &quot;, normalize-space(concat(@data-tertiary-sortas, &quot; &quot;, @data-tertiary)), &quot; &quot;, @data-see))[count(ancestor::node()|$scope) = count(ancestor::node()) and ($role = @role or $type = @type or (string-length($role) = 0 and string-length($type) = 0))][1])]" mode="index-see">
        <xsl:with-param name="position" select="position()"/>
        <xsl:with-param name="scope" select="$scope"/>
        <xsl:with-param name="role" select="$role"/>
        <xsl:with-param name="type" select="$type"/>
        <xsl:sort select="translate(@data-see, $index-letter-chars, $index-letter-chars-normalized)"/>
      </xsl:apply-templates>
    </xsl:if>
    <xsl:if test="$refs/@data-seealso">
      <ul>
        <xsl:apply-templates select="$refs[generate-id() = generate-id(key('see-also', concat(normalize-space(concat(@data-primary-sortas, &quot; &quot;, @data-primary)), &quot; &quot;, normalize-space(concat(@data-secondary-sortas, &quot; &quot;, @data-secondary)), &quot; &quot;, normalize-space(concat(@data-tertiary-sortas, &quot; &quot;, @data-tertiary)), &quot; &quot;, @data-seealso))[count(ancestor::node()|$scope) = count(ancestor::node()) and ($role = @role or $type = @type or (string-length($role) = 0 and string-length($type) = 0))][1])]" mode="index-seealso">
          <xsl:with-param name="position" select="position()"/>
          <xsl:with-param name="scope" select="$scope"/>
          <xsl:with-param name="role" select="$role"/>
          <xsl:with-param name="type" select="$type"/>
          <xsl:sort select="translate(@data-seealso, $index-letter-chars, $index-letter-chars-normalized)"/>
        </xsl:apply-templates>
      </ul>
    </xsl:if>
  </li>
</xsl:template>

<!-- Fixing apparent bugs in indexterm template that are preventing range separators from being generated properly --> 
<xsl:template match="h:a[@data-type='indexterm']" mode="reference">
  <xsl:param name="scope" select="."/>
  <xsl:param name="role" select="''"/>
  <xsl:param name="type" select="''"/>
  <xsl:param name="position"/>
  <!-- BEGIN ORM OVERRIDE -->
  <!-- Adding back in separator param -->
  <xsl:param name="separator" select="''"/>
  <!-- END ORM OVERRIDE -->

  <xsl:variable name="term.separator">
    <xsl:call-template name="index.separator">
      <xsl:with-param name="key" select="'index.term.separator'"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="number.separator">
    <xsl:call-template name="index.separator">
      <xsl:with-param name="key" select="'index.number.separator'"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="range.separator">
    <xsl:call-template name="index.separator">
      <xsl:with-param name="key" select="'index.range.separator'"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:choose>
    <!-- BEGIN ORM OVERRIDE -->
    <!-- Use $separator param when supplied -->
    <xsl:when test="$separator != ''">
      <xsl:value-of select="$separator"/>
    </xsl:when>
    <!-- END ORM OVERRIDE -->
    <xsl:when test="$position = 1">
      <xsl:value-of select="$term.separator"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$number.separator"/>
    </xsl:otherwise>
  </xsl:choose>

  <xsl:choose>
    <xsl:when test="@zone and string(@zone)">
      <xsl:call-template name="reference">
        <xsl:with-param name="zones" select="normalize-space(@zone)"/>
        <xsl:with-param name="position" select="position()"/>
        <xsl:with-param name="scope" select="$scope"/>
        <xsl:with-param name="role" select="$role"/>
        <xsl:with-param name="type" select="$type"/>
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
      <a data-type="index:locator"> <!-- From EPUB Indexes Specification -->
        <xsl:variable name="title">
          <xsl:apply-templates select="(ancestor-or-self::h:nav|ancestor-or-self::h:div[@data-type='part']|ancestor-or-self::h:section)[last()]" mode="title.markup"/>
        </xsl:variable>

        <xsl:attribute name="href">
          <xsl:choose>
            <xsl:when test="$index.links.to.section = 1">
              <xsl:call-template name="href.target">
                <xsl:with-param name="object" select="(ancestor-or-self::h:nav|ancestor-or-self::h:div[@data-type='part']|ancestor-or-self::h:section)[last()]"/>
                <xsl:with-param name="context" select="//h:section[@data-type='index'][count(ancestor::node()|$scope) = count(ancestor::node()) and ($role = @role or $type = @type or (string-length($role) = 0 and string-length($type) = 0))][1]"/>
              </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
              <xsl:call-template name="href.target">
                <xsl:with-param name="object" select="."/>
                <xsl:with-param name="context" select="//h:section[@data-type='index'][count(ancestor::node()|$scope) = count(ancestor::node()) and ($role = @role or $type = @type or (string-length($role) = 0 and string-length($type) = 0))][1]"/>
              </xsl:call-template>
            </xsl:otherwise>
          </xsl:choose>

        </xsl:attribute>

        <xsl:value-of select="$title"/> <!-- text only -->
      </a>

      <xsl:variable name="id" select="(@id|@xml:id)[1]"/>
      <xsl:if test="key('endofrange', $id)[count(ancestor::node()|$scope) = count(ancestor::node()) and ($role = @role or $type = @type or (string-length($role) = 0 and string-length($type) = 0))]">
        <xsl:apply-templates select="key('endofrange', $id)[count(ancestor::node()|$scope) = count(ancestor::node()) and ($role = @role or $type = @type or (string-length($role) = 0 and string-length($type) = 0))][last()]" mode="reference">
          <xsl:with-param name="position" select="position()"/>
          <xsl:with-param name="scope" select="$scope"/>
          <xsl:with-param name="role" select="$role"/>
          <xsl:with-param name="type" select="$type"/>
          <xsl:with-param name="separator" select="$range.separator"/>
        </xsl:apply-templates>
      </xsl:if>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template name="reference">
  <xsl:param name="scope" select="."/>
  <xsl:param name="role" select="''"/>
  <xsl:param name="type" select="''"/>
  <xsl:param name="zones"/>

  <xsl:choose>
    <xsl:when test="contains($zones, ' ')">
      <xsl:variable name="zone" select="substring-before($zones, ' ')"/>
      <xsl:variable name="target" select="key('sections', $zone)"/>

      <a data-type="index:locator"> <!-- From EPUB Indexes Specification -->
        <xsl:attribute name="href">
          <xsl:call-template name="href.target">
            <xsl:with-param name="object" select="$target[1]"/>
            <xsl:with-param name="context" select="//h:section[@data-type='index'][count(ancestor::node()|$scope) = count(ancestor::node()) and ($role = @role or $type = @type or (string-length($role) = 0 and string-length($type) = 0))][1]"/>
          </xsl:call-template>
        </xsl:attribute>
        <xsl:apply-templates select="$target[1]" mode="index-title-content"/>
      </a>
      <xsl:text>, </xsl:text>
      <xsl:call-template name="reference">
        <xsl:with-param name="zones" select="substring-after($zones, ' ')"/>
        <xsl:with-param name="position" select="position()"/>
        <xsl:with-param name="scope" select="$scope"/>
        <xsl:with-param name="role" select="$role"/>
        <xsl:with-param name="type" select="$type"/>
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
      <xsl:variable name="zone" select="$zones"/>
      <xsl:variable name="target" select="key('sections', $zone)"/>

      <a data-type="index.locator"> <!-- From EPUB Indexes Specification -->
        <xsl:attribute name="href">
          <xsl:call-template name="href.target">
            <xsl:with-param name="object" select="$target[1]"/>
            <xsl:with-param name="context" select="//h:section[@data-type='index'][count(ancestor::node()|$scope) = count(ancestor::node()) and ($role = @role or $type = @type or (string-length($role) = 0 and string-length($type) = 0))][1]"/>
          </xsl:call-template>
        </xsl:attribute>
        <xsl:apply-templates select="$target[1]" mode="index-title-content"/>
      </a>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="h:a[@data-type='indexterm']" mode="index-see">
  <xsl:param name="scope" select="."/>
  <xsl:param name="role" select="''"/>
  <xsl:param name="type" select="''"/>

  <xsl:text> (</xsl:text>
  <!-- data-gentext provided so that you can do a CSS override for localization, if desired -->
  <span data-gentext="see">
    <xsl:call-template name="get-localization-value">
      <xsl:with-param name="gentext-key" select="'see'"/>
    </xsl:call-template>
  </span>
  <xsl:text> </xsl:text>
  <xsl:value-of select="@data-see"/>
  <xsl:text>)</xsl:text>
</xsl:template>

<xsl:template match="h:a[@data-type='indexterm']" mode="index-seealso">
  <xsl:param name="scope" select="."/>
  <xsl:param name="role" select="''"/>
  <xsl:param name="type" select="''"/>
    <li>
    <xsl:text>(</xsl:text>
    <!-- data-gentext provided so that you can do a CSS override for localization, if desired -->
    <span data-gentext="see">
      <xsl:call-template name="get-localization-value">
	<xsl:with-param name="gentext-key" select="'seealso'"/>
      </xsl:call-template>
    </span>
    <xsl:text> </xsl:text>
    <xsl:value-of select="@data-seealso"/>
    <xsl:text>)</xsl:text>
    </li>
</xsl:template>

<xsl:template match="*" mode="index-title-content">
  <xsl:variable name="title">
    <xsl:apply-templates select="(ancestor-or-self::h:nav|ancestor-or-self::h:div[@data-type='part']|ancestor-or-self::h:section)[last()]" mode="title.markup"/>
  </xsl:variable>

  <xsl:value-of select="$title"/>
</xsl:template>

<xsl:template name="index.separator">
  <xsl:param name="key" select="''"/>

  <xsl:choose>
    <xsl:when test="$key = 'index.term.separator'">
      <xsl:choose>
        <!-- Use the override if not blank -->
        <xsl:when test="$index.term.separator != ''">
          <xsl:copy-of select="$index.term.separator"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="get-localization-value">
            <xsl:with-param name="context">index</xsl:with-param>
            <xsl:with-param name="gentext-key">term-separator</xsl:with-param>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:when test="$key = 'index.number.separator'">
      <xsl:choose>
        <!-- Use the override if not blank -->
        <xsl:when test="$index.number.separator != ''">
          <xsl:copy-of select="$index.number.separator"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="get-localization-value">
            <xsl:with-param name="context">index</xsl:with-param>
            <xsl:with-param name="gentext-key">number-separator</xsl:with-param>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:when test="$key = 'index.range.separator'">
      <xsl:choose>
        <!-- Use the override if not blank -->
        <xsl:when test="$index.range.separator != ''">
          <xsl:copy-of select="$index.range.separator"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="get-localization-value">
            <xsl:with-param name="context">index</xsl:with-param>
            <xsl:with-param name="gentext-key">range-separator</xsl:with-param>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:when>
  </xsl:choose>
</xsl:template>

</xsl:stylesheet>
