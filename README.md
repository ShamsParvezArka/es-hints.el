# es-hints.el
> This package is in early beta. Right now it only supports(or atleast i've tasted for) C/C++. PRs are much appreciated.

4coder like Scope hint implementation for emacs. Take a look at this video [demo](https://youtu.be/SWvGKLvxtew)

## Installation
Just add these lines to you're emacs config
```lisp
(add-to-list 'load-path "~/YOU'RE/DESIRED/PATH/TO/es-hints.el")
(require 'es-hints)
(add-hook 'c-mode-hook 'es-hints-mode)
```

> [!WARNIGN]
> This extension will freeze your Emacs if you open massive files like [The SQLite Amalgamation](https://sqlite.org/amalgamation.html)
