NAME
===========

Dancer::Plugin::Multilang - Plugin to manage languages on Dancer2

VERSION
=======

version 0.001 (still beta!)

DESCRIPTION
===========

A little plugin to create a multilanguage site with routes like /it/... and /en/... with also the SEO headers.

CONFIGURATION
=============

Only needed parameters are the managed languages and the default one (when the language of the user is not managed)

```
plugins: 
  Multilang: 
    languages: ['it', 'en'] 
    default: 'it' 
```

USAGE
=====

Just import it in the app. All the routes will be managed by a before hook that will change them. Do not add internalization on the routes. The plugin will do all the work for you (well... i hope)

AUTHOR
======

Simone Faré
