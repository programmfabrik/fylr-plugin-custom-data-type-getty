> This Plugin / Repo is being maintained by a community of developers.
There is no warranty given or bug fixing guarantee; especially not by
Programmfabrik GmbH. Please use the github issue tracking to report bugs
and self organize bug fixing. Feel free to directly contact the committing
developers.

# easydb-custom-data-type-getty

This is a plugin for [easyDB 5](http://5.easydb.de/) with Custom Data Type `CustomDataTypeGetty` for references to entities of the [Getty Vocabularys](http://vocab.getty.edu/).

The Plugins uses <http://ws.gbv.de/suggest/getty/> for the autocomplete-suggestions. <http://ws.gbv.de/suggest/getty/> communicates live with getty's sparql-endpoint and works as a proxy.

## configuration

As defined in `manifest.yml` this datatype can be configured:

### Schema options

* which getty-vocabularys are offered for search. One or multiple of
    * aat
    * tgn
    * ulan
* starting point for searching within a hierarchical vocabulary. Limits the search to entries that are children of this node, including all of its children and grandchildren.
     * examples:
        * aat:300194567
        * aat:300312045
        * tgn:7000084

### Mask options

* whether additional informationen is loaded if the mouse hovers a suggestion in the search result

## saved data
* conceptName
    * Preferred label of the linked record
* conceptURI
    * URI to linked record
* conceptGeoJSON
    * geoJSON, if given in places 
* _fulltext
    * easydb-fulltext
* _standard
    * easydb-standard

## sources

The source code of this plugin is managed in a git repository at <https://github.com/programmfabrik/easydb-custom-data-type-getty>. Please use [the issue tracker](https://github.com/programmfabrik/easydb-custom-data-type-getty/issues) for bug reports and feature requests!
