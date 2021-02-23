## [2.1.0] - 23/02/2021

* On error function added for easier error handling
* Clients have extra function: onServerAlreadyExist()
* Uses a different more appropriate package for getting IP adress on Android
* Example app has much more depth e.g Json sending example
* Most improvements from [Fikrirazzaq](https://github.com/fikrirazzaq)

## [2.0.3] - 20/02/2021

* Code refactoring using pedantic

## [2.0.2] - 20/02/2021

* Package dependencies should be resolved properly now

## [2.0.1] - 11/02/2021

* Updated packages hoping to fix a dio error
* Updated README to reflect package better including the fact that more platforms are supported

## [2.0.0] - 01/02/2021

* If a client is disposed it tells the server.
* If a server is disposed all the clients are disposed as well.
* There are also extra functions that can be called for if a client or server is disposed
* The payload is now always a String to simplify the process

## [1.2.0] - 26/01/2021

* Clients from the same IP adress can't be added twice

## [1.1.0] - 30/04/2020

* Remove access to internal API components to make API simpler
* Added a shield.io so easy to find auto generated documentation and the pub.dev package

## [1.0.2] - 30/04/2020

* Code cleanup and addition to documentation

## [1.0.1] - 21/04/2020

* Minor changes to code formatting

## [1.0.0] - 21/04/2020

* I did a massive overhaul so that the data transferred is a packet object rather then just a string. This allows the information of each packet to be read (e.g host, port, name of user packet from). On top of this you can also give packets names. This means you can send mutliple types of data as a payload (be wary that the data may be converted into String upon arrival). 
* Feel free to leave feedback (or even contribute :grin: )on my Github as this is still a work in progress.

## [0.1.1] - 20/04/2020

* The package now has a reasonable length description.

## [0.1.0] - 20/04/2020

* The package has been created. It's still going to be unstable as many of the features haven't yet been tested.
* Thank the creator of Node Commander as he is the real one behind all this
