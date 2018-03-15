# BluetoothLinux `gh-pages`

## Documentation

[Docs](https://github.com/PureSwift/BluetoothLinux.git) generated with [jazzy](https://github.com/realm/jazzy). Hosted by [GitHub Pages](https://pages.github.com).

## Setup

The `gh-pages` branch includes `master` as a [git submodule](http://git-scm.com/book/en/v2/Git-Tools-Submodules) in order to generate docs.

````bash
$ git clone https://github.com/PureSwift/BluetoothLinux.git
$ cd BluetoothLinux/
$ git checkout gh-pages
$ git submodule init
$ git submodule update
````

## Generate

````bash
$ ./build_docs.sh
````

## Preview

````bash
$ open index.html -a Safari
````

## Publish

````bash
$ ./publish_docs.sh
````
