class GettyUtil
    
  # from https://github.com/programmfabrik/coffeescript-ui/blob/fde25089327791d9aca540567bfa511e64958611/src/base/util.coffee#L506
  # has to be reused here, because cui not be used in updater
  @isEqual: (x, y, debug) ->
    #// if both are function
    if x instanceof Function
      if y instanceof Function
        return x.toString() == y.toString()
      return false

    if x == null or x == undefined or y == null or y == undefined
      return x == y

    if x == y or x.valueOf() == y.valueOf()
      return true

    # if one of them is date, they must had equal valueOf
    if x instanceof Date
      return false

    if y instanceof Date
      return false

    # if they are not function or strictly equal, they both need to be Objects
    if not (x instanceof Object)
      return false

    if not (y instanceof Object)
      return false

    p = Object.keys(x)
    if Object.keys(y).every( (i) -> return p.indexOf(i) != -1 )
      return p.every((i) =>
        eq = @isEqual(x[i], y[i], debug)
        if not eq
          if debug
            console.debug("X: ",x)
            console.debug("Differs to Y:", y)
            console.debug("Key differs: ", i)
            console.debug("Value X:", x[i])
            console.debug("Value Y:", y[i])
          return false
        else
          return true
      )
    else
      return false
    
  ########################################################################
  #generates a json-structure, which is only used for facetting (aka filter) in frontend
  ########################################################################
  @getFacetTerm: (data, databaseLanguages) ->

    shortenedDatabaseLanguages = databaseLanguages.map((value, key, array) ->
      value.split('-').shift()
    )

    _facet_term = {}
    l10nObject = {}

    # init l10nObject
    for language in databaseLanguages
      l10nObject[language] = ''

    # build facetTerm upon prefLabel and uri!    
    label = data?._label || ''
    for l10nObjectKey, l10nObjectValue of l10nObject
      l10nObject[l10nObjectKey] = label + '@$@' + data.id

    # if l10n-object is not empty
    _facet_term = l10nObject
    return _facet_term


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
    
    geoJSON = @getGeoJSONFromGettyJSON object
    if geoJSON
       _standard.geo =  geoJSON

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
        if altInfo.content
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

    if geoJSON
      geoJSON =       
        type: "Feature"      
        properties: {},      
        geometry: geoJSON 

    return geoJSON
