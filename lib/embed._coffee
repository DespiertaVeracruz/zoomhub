fs = require 'fs'
path = require 'path'
config = require '../config'
dziparser = require './dziparser'

seadragon_path = '/js/openseadragon.min.js'

inject_viewer = "var el = document.createElement('div');
                el.setAttribute('id', '__seadragon1');
                document.body.appendChild(el);

                var viewer = OpenSeadragon({
                    id: '__seadragon1',
                    prefixUrl: '/static/js/images/',
                    tileSources: tileSource
                });"

createTileSourceBlock = (base_path, dzi, _) ->
    path_fragment = path.join config.DZI_DIR, "#{dzi}"
    attribs = dziparser.parse path.join(base_path, "#{path_fragment}.dzi"), _

    if not attribs.ready
        path_fragment = '/queued'
        attribs = dziparser.parse path.join(base_path, "#{path_fragment}.dzi"), _

    "var tileSource = {
        Image: {
            xmlns: 'http://schemas.microsoft.com/deepzoom/2008',
            Url: '#{config.STATIC_DIR}#{path_fragment}_files/',
            Format: '#{attribs.tileFormat}',
            Overlap: '#{attribs.tileOverlap}',
            TileSize: '#{attribs.tileSize}',
            Size: {
                Height: '#{attribs.height}',
                Width: '#{attribs.width}'
            }
        }
    };"

# Public API
module.exports = class Embed
  constructor: (@path) ->

  generate: (@id, _) ->
    result = fs.readFile (path.join @path, seadragon_path), _
    result += createTileSourceBlock @path, @id, _
    result += inject_viewer
