config = require '../config'
crypto = require 'crypto'
redis = require 'redis'


# Redis
client = redis.createClient()

# Keys
HASH_ALGORITHM = 'sha256'
HASH_ENCODING = 'hex'

NEXT_ID_KEY = 'content:next.id'

getIdKey = (id) ->
    "content:id:#{id}"

getURLKey = (url) ->
    hash = crypto.createHash HASH_ALGORITHM
    hash.update url
    digest = hash.digest HASH_ENCODING
    "content:url:#{digest}"


# Public API
module.exports = class Content
    constructor: (@id, url) ->
        @url = url
        @self = "#{config.BASE_URL}/v1/content/#{@id}"
        @shareUrl = "#{config.BASE_URL}/#{@id}"
        @embedHtml = "<script src='#{@shareUrl}.js?width=auto&height=400px'></script>"
        @type = 'dzi'
        @dzi =
            url: "#{config.BASE_URL}#{config.STATIC_DIR}#{config.DZI_DIR}/#{@id}.dzi"
            # # TODO: implement these.
            # width: "IMPLEMENT WIDTH"
            # height: "IMPLEMENT HEIGHT"
            # tileSize: "IMPLEMENT TILE SIZE"
            # tileOverlap: "IMPLEMENT TILE OVERLAP"
            # tileFormat: "IMPLEMENT TILE FORMAT"

      # # TODO: implement progress/status
      # @ready = "IMPLEMENT READY"
      # @failed = "IMPLEMENT FAILED"
      # @progress = "IMPLEMENT PROGRESS"

    @getById: (id, _) ->
        key = getIdKey id
        result = client.get key, _
        JSON.parse result

    @getByURL: (url, _) ->
        id = client.get getURLKey(url), _
        if not id?
            return null
        @getById id, _

    @fromURL: (url, _) ->
        nextId = client.incr NEXT_ID_KEY, _
        content = new Content nextId, url
        id = content.id
        idKey = getIdKey id
        value = JSON.stringify content
        urlKey = getURLKey url
        client.mset idKey, value, urlKey, id, _
        content

    @getOrCreate: (url, _) ->
        content = @getByURL url, _
        return content if content?
        @fromURL url, _
