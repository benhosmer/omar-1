package org.ossim.omar

import org.ossim.omar.VideoDataSet
import org.hibernate.CacheMode as CM
import org.hibernate.CacheMode
import org.hibernate.FetchMode as FM
import org.hibernate.FetchMode

//import javax.jws.WebParam

//import org.ossim.postgis.Geometry
import com.vividsolutions.jts.geom.Geometry

class VideoDataSetSearchService
{
  //static expose = ['xfire']

  static transactional = true

  List<VideoDataSet> runQuery(
  /*@WebParam (name = "videoDataSetQuery", header = true)*/
  VideoDataSetQuery videoDataSetQuery,
  /*@WebParam (name = "params", header = true)*/
  Map<String, String> params)
  {
    def x = {
      if ( videoDataSetQuery?.groundGeom )
      {
        addToCriteria(videoDataSetQuery.createIntersection("groundGeom"))
      }
      if ( videoDataSetQuery?.startDate || videoDataSetQuery?.endDate )
      {
        addToCriteria(videoDataSetQuery.createDateRange("startDate", "endDate"))
      }
      if ( params?.max )
      {
        maxResults(params.max as Integer)
      }
      if ( params?.offset )
      {
        firstResult(params.offset as Integer)
      }
      if ( params?.sort && params?.order )
      {
        def sortColumn = null

        // HACK:  Need to find a better way to do this
        switch ( params?.sort )
        {
          case "id":
          case "startDate":
          case "endDate":
            sortColumn = params?.sort
            break
        }
        if ( sortColumn )
        {
          order(sortColumn, params?.order)
        }
      }
      videoDataSetQuery.searchTagNames?.size()?.times {i ->
        String name = videoDataSetQuery.searchTagNames[i]
        String value = videoDataSetQuery.searchTagValues[i]

        if ( name && value )
        {
          def results = Utility.parseSearchTag(name, value)

          if ( results["property"] == "otherTagsXml" )
          {
            String tag = results["tag"].trim()
            String content = results["content"].trim()
            ilike("otherTagsXml", "%<${tag}>%${content}%</${tag}>%")
          }
          else
          {
            ilike(results["property"], "%${results['value']}%")
          }
        }
      }
    }


    return VideoDataSet.createCriteria().list(x)
  }


  List<Geometry>  getGeometries(VideoDataSetQuery videoDataSetQuery, Map<String, String> params)
  {
    def x = {
      projections { property("groundGeom") }
      if ( videoDataSetQuery?.groundGeom )
      {
        addToCriteria(videoDataSetQuery.createIntersection("groundGeom"))
      }
      if ( videoDataSetQuery?.startDate || videoDataSetQuery?.endDate )
      {
        addToCriteria(videoDataSetQuery.createDateRange("startDate", "endDate"))
      }
      if ( params?.max )
      {
        maxResults(params.max as Integer)
      }
      if ( params?.offset )
      {
        firstResult(params.offset as Integer)
      }
      videoDataSetQuery.searchTagNames?.size()?.times {i ->
        String name = videoDataSetQuery.searchTagNames[i]
        String value = videoDataSetQuery.searchTagValues[i]

        if ( name && value )
        {
          def results = Utility.parseSearchTag(name, value)

          if ( results["property"] == "otherTagsXml" )
          {
            String tag = results["tag"].trim()
            String content = results["content"].trim()
            ilike("otherTagsXml", "%<${tag}>%${content}%</${tag}>%")
          }
          else
          {
            ilike(results["property"], "%${results['value']}%")
          }
        }
      }
      cacheMode(CacheMode.GET)
    }

    return VideoDataSet.createCriteria().list(x)
    //def geometries = VideoDataSetMetadata.createCriteria().list(x)
    //return geometries
  }

  int getCount(VideoDataSetQuery videoDataSetQuery)
  {
    def totalCount = VideoDataSet.createCriteria().get {
      projections { rowCount() }
      if ( videoDataSetQuery?.groundGeom )
      {
        addToCriteria(videoDataSetQuery.createIntersection("groundGeom"))
      }
      if ( videoDataSetQuery?.startDate || videoDataSetQuery?.endDate )
      {
        addToCriteria(videoDataSetQuery.createDateRange("startDate", "endDate"))
      }
      videoDataSetQuery.searchTagNames?.size()?.times {i ->
        String name = videoDataSetQuery.searchTagNames[i]
        String value = videoDataSetQuery.searchTagValues[i]

        if ( name && value )
        {
          def results = Utility.parseSearchTag(name, value)

          if ( results["property"] == "otherTagsXml" )
          {
            String tag = results["tag"].trim()
            String content = results["content"].trim()
            ilike("otherTagsXml", "%<${tag}>%${content}%</${tag}>%")
          }
          else
          {
            ilike(results["property"], "%${results['value']}%")
          }
        }
      }
    }

    return totalCount
  }
}
