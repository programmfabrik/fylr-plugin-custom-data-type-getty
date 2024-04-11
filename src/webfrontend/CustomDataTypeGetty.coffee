class CustomDataTypeGetty extends CustomDataTypeWithCommons

  #######################################################################
  # return name of plugin
  getCustomDataTypeName: ->
    "custom:base.custom-data-type-getty.getty"


  #######################################################################
  # return name (l10n) of plugin
  getCustomDataTypeNameLocalized: ->
    $$("custom.data.type.getty.name")

  #######################################################################
  # support geostandard in frontend?
  supportsGeoStandard: ->
    return true
    
  #######################################################################
  # get frontend-language
  getFrontendLanguage: () ->
    # language
    desiredLanguage = ez5?.loca?.getLanguage()
    if desiredLanguage
      desiredLanguage = desiredLanguage.split('-')
      desiredLanguage = desiredLanguage[0]
    else
      desiredLanguage = false

    desiredLanguage

  isUriEncoded = (uri) ->
    # Die URI decodieren
    decodedUri = decodeURIComponent(uri)
    # Die decodierte URI erneut codieren
    reEncodedUri = encodeURIComponent(decodedUri)
    # Überprüfen, ob die re-codierte URI der ursprünglichen entspricht
    return reEncodedUri == uri.replace(/%20/g, '+')

    
  #######################################################################
  # get more info about record
  __getAdditionalTooltipInfo: (uri, tooltip, extendedInfo_xhr) ->
    that = @
    # download infos
    if extendedInfo_xhr.xhr != undefined
      # abort eventually running request
      extendedInfo_xhr.abort()

    if isUriEncoded(uri)
        uri = decodeURIComponent(uri)
        
    uriParts = uri.split('/')
    gettyID = uriParts.pop()
    gettyType = uriParts.pop()

    uri = 'http://vocab.getty.edu/' + gettyType + '/' + gettyID + '.json'
    
    # start new request
    xurl = location.protocol + '//jsontojsonp.gbv.de/?url=' + uri
    
    extendedInfo_xhr = new (CUI.XHR)(url: xurl)
    extendedInfo_xhr.start()
    .done((data, status, statusText) ->
      if data
        htmlContent = '<span style="padding: 10px 10px 0px 10px; font-weight: bold">' + $$('custom.data.type.getty.config.parameter.mask.infopop.info.label') + '</span>'
        htmlContent += '<table style="border-spacing: 10px; border-collapse: separate;">'

        # uri
        htmlContent += "<tr><td>" + $$('custom.data.type.getty.config.parameter.mask.infopop.labels.uri') + ":</td>"
        htmlContent += "<td>" + data.id + "</td></tr>"

        # preflabel
        htmlContent += "<tr><td>" + $$('custom.data.type.getty.config.parameter.mask.infopop.labels.preflabel') + ":</td>"
        htmlContent += "<td>" + data._label + "</td></tr>"

        # broader
        if data?.broader
          htmlContent += "<tr><td>" + $$('custom.data.type.getty.config.parameter.mask.infopop.labels.broader') + ":</td>"
          if data.broader[0]?._label['@value']
            broaderString = data.broader[0]._label['@value'];
          else if data.broader[0]?._label
            broaderString = data.broader[0]._label;
          broaderString = broaderString.replace('<', '')
          broaderString = broaderString.replace('>', '')
          htmlContent += "<td>" + broaderString + "</td></tr>"

        # labels
        htmlContent += "<tr><td>" + $$('custom.data.type.getty.config.parameter.mask.infopop.labels.label') + ":</td>"
        labels = []
        if data.identified_by
          for altInfo in data.identified_by
            if (altInfo.type == 'Name')
              labels.push('- ' + altInfo.content)
        htmlContent += "<td>" + labels.join('<br />') + "</td></tr>"

        # note
        notes = []
        if data.subject_of
          for info in data.subject_of
            if info?.classified_as
              if info.classified_as[0]._label == 'descriptive note'
                language = info.language[0]._label
                if that.getFrontendLanguage() == language || language == 'en'
                  notes.push info.content

        if notes.length > 0
          htmlContent += "<tr><td>" + $$('custom.data.type.getty.config.parameter.mask.infopop.labels.note') + ":</td>"
          htmlContent += "<td>" + notes.join('<br />') + "</td></tr>"

        htmlContent += "</table>"
        tooltip.DOM.innerHTML = htmlContent
        tooltip.autoSize()
      else
        tooltip.hide()
        tooltip.destroy()
        return false
    )
    .fail((data, status, statusText) ->
      tooltip.hide()
      tooltip.destroy()
      return false
    )

    return


  #######################################################################
  # handle suggestions-menu
  __updateSuggestionsMenu: (cdata, cdata_form, searchstring, input, suggest_Menu, searchsuggest_xhr, layout, opts) ->
    that = @

    delayMillisseconds = 200

    setTimeout ( ->
      getty_searchterm = searchstring
      getty_countSuggestions = 20

      if (cdata_form)
        getty_searchterm = cdata_form.getFieldsByName("searchbarInput")[0].getValue()
        getty_searchtype = cdata_form.getFieldsByName("gettySelectType")[0].getValue()
        getty_countSuggestions = cdata_form.getFieldsByName("countOfSuggestions")[0].getValue()

      # if "search-all-types", search all allowed types
      if getty_searchtype == 'all_supported_types' || !getty_searchtype
        getty_searchtype = []
        if that.getCustomSchemaSettings().add_aat?.value
          getty_searchtype.push 'aat'
        if that.getCustomSchemaSettings().add_tgn?.value
          getty_searchtype.push 'tgn'
        if that.getCustomSchemaSettings().add_ulan?.value
          getty_searchtype.push 'ulan'
        getty_searchtype = getty_searchtype.join(',')

      if getty_searchtype == ''
          getty_searchtype ='aat,tgn,ulan'
        
      if getty_searchterm.length == 0
          return
        
      # startParentID
      startParentID = ''
      allowedStartParentIDBeginnings = ['tgn:', 'aat:', 'ulan:']
      if that.getCustomSchemaSettings().start_parent_id?.value
        startsWithAllowedPrefix = false
        for prefix in allowedStartParentIDBeginnings when that.getCustomSchemaSettings().start_parent_id.value.startsWith(prefix)
          startsWithAllowedPrefix = true
          break

        if startsWithAllowedPrefix
            startParentID = '&startParentID=' + that.getCustomSchemaSettings().start_parent_id.value

      # run autocomplete-search via xhr
      if searchsuggest_xhr.xhr != undefined
          # abort eventually running request
          searchsuggest_xhr.xhr.abort()

      # start new request
      searchsuggest_xhr.xhr = new (CUI.XHR)(url: location.protocol + '//ws.gbv.de/suggest/getty/?searchstring=' + getty_searchterm + '&voc=' + getty_searchtype + '&count=' + getty_countSuggestions + startParentID)
      searchsuggest_xhr.xhr.start().done((data, status, statusText) ->

          # init xhr for tooltipcontent
          extendedInfo_xhr = { "xhr" : undefined }
          # create new menu with suggestions
          menu_items = []
          for suggestion, key in data[1]
            do(key) ->
              # the actual Featureclass...
              aktType = data[2][key]
              lastType = ''
              if key > 0
                lastType = data[2][key-1]
              if aktType != lastType
                item =
                  divider: true
                menu_items.push item
                item =
                  label: aktType
                menu_items.push item
                item =
                  divider: true
                menu_items.push item
              item =
                text: suggestion
                value: data[3][key]
                tooltip:
                  markdown: true
                  placement: "e"
                  content: (tooltip) ->
                    that.__getAdditionalTooltipInfo(data[3][key], tooltip, extendedInfo_xhr)
                    new CUI.Label(icon: "spinner", text: "lade Informationen")
              menu_items.push item

          # set new items to menu
          itemList =
            onClick: (ev2, btn) ->
              # lock in save data
              cdata.conceptURI = btn.getOpt("value")
              cdata.conceptName = btn.getText()

              # try to get better fulltext
              encodedURL = encodeURIComponent(cdata.conceptURI + '.json')
              dataEntry_xhr = new (CUI.XHR)(url: location.protocol + '//jsontojsonp.gbv.de/?url=' + encodedURL)
              dataEntry_xhr.start().done((data, status, statusText) ->

                # _standard & _fulltext
                cdata._fulltext = GettyUtil.getFullTextFromGettyJSON data, false
                cdata._standard = GettyUtil.getStandardFromGettyJSON that, data, cdata, false

                geoJSON = GettyUtil.getGeoJSONFromGettyJSON data
                if geoJSON
                  cdata.conceptGeoJSON = geoJSON
                # update the layout in form
                that.__updateResult(cdata, layout, opts)
                # hide suggest-menu
                suggest_Menu.hide()
                # close popover
                if that.popover
                  that.popover.hide()
              )
              .fail((data, status, statusText) ->
                # update the layout in form
                that.__updateResult(cdata, layout, opts)
                # hide suggest-menu
                suggest_Menu.hide()
                # close popover
                if that.popover
                  that.popover.hide()
              )
            items: menu_items

          # if no hits set "empty" message to menu
          if itemList.items.length == 0
            itemList =
              items: [
                text: "kein Treffer"
                value: undefined
              ]

          suggest_Menu.setItemList(itemList)

          suggest_Menu.show()
      )
    ), delayMillisseconds


  #######################################################################
  # create form
  __getEditorFields: (cdata) ->
    # read searchtypes from datamodell-options
    dropDownSearchOptions = []
    # offer DifferentiatedPerson
    if @getCustomSchemaSettings().add_aat?.value
        option = (
            value: 'aat'
            text: 'Art & Architecture Thesaurus'
          )
        dropDownSearchOptions.push option
    # offer CorporateBody?
    if @getCustomSchemaSettings().add_tgn?.value
        option = (
            value: 'tgn'
            text: 'Getty Thesaurus of Geographic Names'
          )
        dropDownSearchOptions.push option
    # offer PlaceOrGeographicName?
    if @getCustomSchemaSettings().add_ulan?.value
        option = (
            value: 'ulan'
            text: 'Union List of Artist Names'
          )
        dropDownSearchOptions.push option
    # add "Alle"-Option? If count of options > 1!
    #if dropDownSearchOptions.length > 1
    #    option = (
    #        value: 'all_supported_types'
    #        text: 'Alle'
    #      )
    #    dropDownSearchOptions.unshift option
    # if empty options -> offer all
    if dropDownSearchOptions.length == 0
        dropDownSearchOptions = [
          (
            value: 'aat'
            text: 'Art & Architecture Thesaurus'
          )
          (
            value: 'tgn'
            text: 'Getty Thesaurus of Geographic Names'
          )
          (
            value: 'ulan'
            text: 'Union List of Artist Names'
          )
        ]
    [{
      type: CUI.Select
      undo_and_changed_support: false
      form:
          label: $$('custom.data.type.getty.modal.form.text.type')
      options: dropDownSearchOptions
      name: 'gettySelectType'
      class: 'commonPlugin_Select'
    }
    {
      type: CUI.Select
      undo_and_changed_support: false
      class: 'commonPlugin_Select'
      form:
          label: $$('custom.data.type.getty.modal.form.text.count')
      options: [
        (
            value: 10
            text: '10 Vorschläge'
        )
        (
            value: 20
            text: '20 Vorschläge'
        )
        (
            value: 50
            text: '50 Vorschläge'
        )
        (
            value: 100
            text: '100 Vorschläge'
        )
      ]
      name: 'countOfSuggestions'
    }
    {
      type: CUI.Input
      undo_and_changed_support: false
      form:
          label: $$("custom.data.type.getty.modal.form.text.searchbar")
      placeholder: $$("custom.data.type.getty.modal.form.text.searchbar.placeholder")
      name: "searchbarInput"
      class: 'commonPlugin_Input'
    }
    ]


  #######################################################################
  # renders the "result" in original form (outside popover)
  __renderButtonByData: (cdata) ->
        
    that = @

    # when status is empty or invalid --> message

    switch @getDataStatus(cdata)
      when "empty"
        return new CUI.EmptyLabel(text: $$("custom.data.type.getty.edit.no_getty")).DOM
      when "invalid"
        return new CUI.EmptyLabel(text: $$("custom.data.type.getty.edit.no_valid_getty")).DOM

    # if status is ok
    conceptURI = CUI.parseLocation(cdata.conceptURI).url

    tt_text = $$("custom.data.type.getty.url.tooltip", name: cdata.conceptName)

    # replace conceptUri with better human-readable website
    # http://vocab.getty.edu/aat/300386183 turns http://vocab.getty.edu/page/aat/300386183
    displayUri = cdata.conceptURI.replace('http://vocab.getty.edu', 'http://vocab.getty.edu/page')

    extendedInfo_xhr = { "xhr" : undefined }
    
    # output Button with Name of picked entry and URI
    new CUI.HorizontalLayout
      maximize: false
      left:
        content:
          new CUI.Label
            centered: false
            multiline: true
            text: cdata.conceptName
      center:
        content:
          # output Button with Name of picked Entry and Url to the Source
          new CUI.ButtonHref
            appearance: "link"
            href: cdata.conceptURI
            target: "_blank"
            tooltip:
              markdown: true
              placement: 'n'
              content: (tooltip) ->
                that.__getAdditionalTooltipInfo(cdata.conceptURI, tooltip, extendedInfo_xhr)
                new CUI.Label(icon: "spinner", text: "lade Informationen")
            text: ' '
      right: null
    .DOM



  #######################################################################
  # zeige die gewählten Optionen im Datenmodell unter dem Button an
  getCustomDataOptionsInDatamodelInfo: (custom_settings) ->
    tags = []

    if custom_settings.add_aat?.value
      tags.push "✓ AAT"
    else
      tags.push "✘ AAT"

    if custom_settings.add_tgn?.value
      tags.push "✓ TGN"
    else
      tags.push "✘ TGN"

    if custom_settings.add_ulan?.value
      tags.push "✓ ULAN"
    else
      tags.push "✘ ULAN"

    if custom_settings.start_parent_id?.value
      tags.push "✓ startParentID"
    else
      tags.push "✘ startParentID"
        
    tags


CustomDataType.register(CustomDataTypeGetty)
