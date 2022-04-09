
webtools_config:
    type: data
    debug: false
    # Configure this to your EXTERNAL web address. It used to generate links.
    url_base: http://localhost:8081/

webserver_startup_world:
    type: world
    debug: false
    events:
        on server start:
        - webserver start port:8081 ignore_errors

webserver_corefiles_handler_world:
    type: world
    debug: false
    events:
        on webserver web request path:/|/index|/index.html method:get:
        - determine code:403 passively
        - determine headers:[Content-Type=text/html] passively
        - determine cached_file:index.htm
        on webserver web request path:/favicon.ico method:get:
        - determine code:200 passively
        - determine cached_file:favicon.ico
        on webserver web request path:/robots.txt method:get:
        - determine code:200 passively
        - determine "raw_text_content:User-agent: *<n>Disallow: /<n>"
        on webserver web request path:/css/bootstrap_dark.min.css method:get:
        - determine code:200 passively
        - determine headers:[Content-Type=text/css] passively
        - determine cached_file:/css/bootstrap_dark.min.css
        on webserver web request path:/js/jquery.min.js|/js/bootstrap.min.js method:get:
        - determine code:200 passively
        - determine headers:[Content-Type=application/javascript] passively
        - determine cached_file:<context.path>

webserver_fallback_handler_world:
    type: world
    debug: false
    events:
        on webserver web request priority:1000 has_response:false:
        - determine code:404 passively
        - determine headers:[Content-Type=text/plain] passively
        - determine "raw_text_content:Invalid path"
