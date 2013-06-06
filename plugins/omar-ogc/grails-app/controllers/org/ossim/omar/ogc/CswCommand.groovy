package org.ossim.omar.ogc

import grails.validation.Validateable
import groovy.transform.EqualsAndHashCode
import groovy.transform.ToString
import groovy.util.slurpersupport.GPathResult
import groovy.xml.StreamingMarkupBuilder

/**
 * Created with IntelliJ IDEA.
 * User: sbortman
 * Date: 5/23/13
 * Time: 2:31 PM
 * To change this template use File | Settings | File Templates.
 */
@Validateable
@ToString( includeNames = true, includeFields = true, excludes = 'errors,dateCreated,lastUpdated,metaClass' )
@EqualsAndHashCode

class CswCommand
{
  String service
  String version
  String request

  Integer maxRecords
  Integer startPosition

  String elementSetName
  String resultType
  String typeNames
  String outputFormat

  String constraint
  String constraintLanguage

  static CswCommand fromXML(String xmlText)
  {
    fromXML( new XmlSlurper().parseText( xmlText ) )
  }

  static CswCommand fromXML(GPathResult xml)
  {
    def params = [
        service: xml.@service?.text(),
        version: xml.@version?.text(),
        request: xml?.name(),
    ]

    switch ( params.request )
    {
    case "GetCapabilities":
      params.version = xml?.AcceptVersions?.Version?.text()
      break

    case "DescribeRecord":
      break

    case "GetRecords":
      params.maxRecords = xml.@maxRecords?.text()?.toInteger() ?: 10
      params.startPosition = ( xml.@startPosition?.text() ) ? xml.@startPosition?.text()?.toInteger() : 1
      params.resultType = xml.@resultType?.text()
      params.typeNames = xml.Query?.@typeNames?.text()
      params.outputFormat = xml.Query?.@outputFormat?.text()
      params.elementSetName = xml.Query?.ElementSetName?.text()
      params.constraintLanguage = xml?.Query?.Constraint?.childNodes()?.next()?.name()?.toUpperCase()

      switch ( params.constraintLanguage )
      {
      case "CQLTEXT":
      case "CQL_TEXT":
        params.constraint = xml?.Query?.Constraint?.childNodes()?.next()?.text()
        break
      case "FILTER":
        params.constraint = xml.Query.collect { new StreamingMarkupBuilder().bindNode( it.Filter ).toString().trim() }?.first()

        break
      }
      break
    }

    new CswCommand( params )
  }
}
