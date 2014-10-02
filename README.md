# ZoomHub

This is the beginning of an open-source codebase for a cloud zooming service,
like [Zoom.it].


## Contributing

See [CONTRIBUTING.md] for details.


## Setup

-   [Install Node.js][node-installation].
-   [Install Redis][redis].
-   Install dependencies: `./zh install`


## Optional Prerequisites

-   [Ansible][ansible-installation] for deployment.
-   [pip] for installing `passlib` (see below).
-   Python `passlib` for generating passwords: `pip install passlib`.


## API

(This isn't implemented yet; this is just a WIP design/spec.)

Staying close to the original Zoom.it API as a starting point, but none of
this is finalized. See notes at the bottom.

Fetching content:

```
GET /content/<url> or GET /v1/content?url=<url>
- the latter is for Zoom.it compatibility
- be sure to percent-encode the URL
- 3xx to /content/:id, w/ info in body for convenience
- 400 if the URL is malformed
```

```
GET /content/:id
- 200 w/ info
- 404 if nothing found by that ID
```

In both cases, response JSON:

```
- id (string)
- self (string; URL of content metadata)
- url (string; the original source URL)
- shareUrl (string; URL for viewing)
- embedHtml (string; a script tag to paste into your webpage to embed the resulting image)
- type (string: is only ever 'dzi' right now; 'dzc' may be possible later.)
- dzi (object, or null if still in progress or failed)
```

DZI objects:

```
- url (string; to .dzi XML file)
```

Other DZI object attributes that we'd like to include but aren't yet:
```
- width (int)
- height (int)
- tileSize (int)
- tileFormat (string; 'png' or 'jpg')
- tileOverlap (int)
```

Future error objects:

```
- code (string; semantic code that'll be documented here)
- message (string; developer-facing to help in debugging, NOT user-facing)
- data (arbitrary and optional; will be documented w/ code if it's needed)
```

Fetching the DZI directly:

```
GET /dzi?url=<url> --or--
GET /dzi/:id
- if ready, 3xx directly to .dzi XML file, w/ DZI JSON in body for convenience
- if not ready but in progress, 404 w/ a Retry-After header
- if failed, 404
```

Notes, and thoughts for improvement:

- Changed from zoom.it's `ready` and `failed` bool properties to just `dzi`
  and `error` objects. It was always most robust as a client to just check
  the `dzi` property directly (that's ultimately all you cared for), and
  `error` objects will let us expose semantic error codes as well (we were
  routinely asked how to programmatically get at the cause of failures).

- An advantage over calling it `dzi` instead of e.g. `result` is that it'll
  let us eventually return `dzc` too. E.g. every URL will always generate a
  DZI, but a link to a Flickr album may also generate a DZC. Maybe we should
  namespace both `error` and `progress` to this too, e.g. `dzcProgress`.

- Kept the generic "content" namespace to support that scenario above, as
  well as to support the concept of clients ultimately just wanting content
  (and not e.g. enqueueing a new "conversion" or "job" -- that's an impl.
  detail), but we could rethink that. Relates to prev point too.

- The JSON format is different than a typical XML-to-JSON conversion format,
  e.g. what OpenSeadragon supports, because this is simpler and more natural.
  Is that fine?

- Calling the source URL just `url` is nice and simple, but doesn't play nice
  with other kinds of URLs we may want to return. We may want to be specific
  and call this e.g. `sourceURL`. But it should be consistent between the
  response JSON and the request query string param.


## Embedding with OpenSeadragon
As it currently stands, the embed code needs to read an existing DZI. From the
information contained in the DZI, it instantiates an OpenSeadragon viewer and
attaches that to its own element in the DOM of the webpage that the embed is placed in.


## Administation

### Prerequisites

-   Copy `deployment/hosts.sample` to `deployment/hosts` and replace
    `localhost` with your server IP.
-   Copy `credentials/userpassword.sample` to
    `deployment/credentials/userpassword` and paste in your password.

### Commands

`zh` is a script for managing ZoomHub. Currently, we support the following
commands:

-   `./zh install`: Install dependencies.
-   `./zh run`: Run app locally.
-   `./zh bootstrap`: Bootstrap server(s); only required once per user.
-   `./zh ping`: Ping production machines.
-   `./zh setup`: Setup server(s).
-   `./zh deploy`: Deploy latest app code from Git.

## License

The MIT License. See [LICENSE][] file.



[ansible-installation]: http://www.ansibleworks.com/docs/intro_installation.html
[CONTRIBUTING.md]: CONTRIBUTING.md
[LICENSE]: LICENSE
[node-installation]: http://nodejs.org/download/
[pip]: https://pypi.python.org/pypi/pip
[redis]: http://redis.io/
[Zoom.it]: http://zoom.it/
