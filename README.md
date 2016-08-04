# WebRTC Build Script for iOS

TODO

## Using a Built Framework

Copy `WebRTC.framework` into your projects or write the following code to Cartfile.

```
github "shiguredo/WebRTC-iOS"
```

## Getting `depot_tools`

It needs `depot_tools` to build WebRTC.
You can get `depot_tools` with executing `./build.sh setup`.
The command downloads `depot_tools` into local directory.

If you already have installed `depot_tools`, this process is not needed.

## Getting or Synchronising WebRTC source code

`./build.sh fetch` gets WebRTC source code or synchronises it with specified revision.
If you already have the huge source code, move it into `webrtc/src`.

WebRTC revision can be specified in `config.sh`.
The script gets branch head if `WEBRTC_REVISION` is empty.

```
export WEBRTC_REVISION="f3010bdf85a0c5432acda813ec8ce402db811e20"
```

## Building a Framework

TODO: debug, release, dist
