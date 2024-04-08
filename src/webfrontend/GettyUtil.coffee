class GettyUtil
  @getStandardFromGettyJSON: (context, object, cdata, databaseLanguages = false) ->
    if databaseLanguages == false
      databaseLanguages = ez5.loca.getDatabaseLanguages()
    shortenedDatabaseLanguages = databaseLanguages.map((value, key, array) ->
      value.split('-').shift()
    )
    activeFrontendLanguage = null
    if context
      activeFrontendLanguage = context.getFrontendLanguage()

    if cdata?.frontendLanguage
        if cdata?.frontendLanguage?.length == 2
          activeFrontendLanguage = cdata.frontendLanguage

    if Array.isArray(object)
      object = object[0]

    _standard = {}
    l10nObject = {}

    # init l10nObject for fulltext
    for language in databaseLanguages
      l10nObject[language] = ''

    # 1. L10N
    #  give l10n-languages the easydb-language-syntax
    for l10nObjectKey, l10nObjectValue of l10nObject
      # add to l10n
      l10nObject[l10nObjectKey] = object._label

    _standard.l10ntext = l10nObject

    return _standard


  @getFullTextFromGettyJSON: (object, databaseLanguages = false) ->
    if databaseLanguages == false
      databaseLanguages = ez5.loca.getDatabaseLanguages()

    shortenedDatabaseLanguages = databaseLanguages.map((value, key, array) ->
      value.split('-').shift()
    )

    if Array.isArray(object)
      object = object[0]

    _fulltext = {}
    fullTextString = ''
    l10nObject = {}
    l10nObjectWithShortenedLanguages = {}

    # init l10nObject for fulltext
    for language in databaseLanguages
      l10nObject[language] = ''

    for language in shortenedDatabaseLanguages
      l10nObjectWithShortenedLanguages[language] = ''

    # preflabel to all languages
    fullTextString += object._label + ' '
    # identifier to fulltext
    fullTextString += object.id + ' '

    # parse all altlabels
    if object.identified_by
      for altInfo in object.identified_by
        fullTextString += altInfo.content + ' '

    for l10nObjectWithShortenedLanguagesKey, l10nObjectWithShortenedLanguagesValue of l10nObjectWithShortenedLanguages
      l10nObjectWithShortenedLanguages[l10nObjectWithShortenedLanguagesKey] = fullTextString

    # finally give l10n-languages the easydb-language-syntax
    for l10nObjectKey, l10nObjectValue of l10nObject
      # get shortened version
      shortenedLanguage = l10nObjectKey.split('-')[0]
      # add to l10n
      if l10nObjectWithShortenedLanguages[shortenedLanguage]
        l10nObject[l10nObjectKey] = l10nObjectWithShortenedLanguages[shortenedLanguage]

    _fulltext.text = fullTextString
    _fulltext.l10ntext = l10nObject

    return _fulltext


  @getGeoJSONFromGettyJSON: (object) ->
        
    geoJSON = false

    if object?.type == 'Place'
      if object?.identified_by
        for objectKey, objectValue of object.identified_by
          if objectValue?.type == 'crm:E47_Spatial_Coordinates'
            if objectValue?.classified_as?.id = 'http://geojson.org'
                if objectValue?.value
                    coordinates = JSON.parse(objectValue.value);
                    isValidCoordinates = (Array.isArray(coordinates) and (coordinates.length == 2) and coordinates.every (coord) -> typeof coord == 'number')
                    if isValidCoordinates
                      geoJSON =
                        type: "Point"
                        coordinates: coordinates

    #geoJSON = JSON.parse('{ "type": "FeatureCollection", "features": [ { "type": "Feature", "geometry": { "type": "Polygon", "coordinates": [ [ [ 16.2953092403489, 5.877002745532067 ], [ 16.2953092403489, -6.130023633976933 ], [ 29.467584082107635, -6.130023633976933 ], [ 29.467584082107635, 5.877002745532067 ], [ 16.2953092403489, 5.877002745532067 ] ] ] }, "properties": {} } ] }');
    return geoJSON
