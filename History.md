# Version 0.1.3

### Enhancement

* Changed output white-space to pre-wrap to preserve leading spaces. This is specially
  useful when `puts obj.method(:method).source` is used.

# Version 0.1.2

### Security

* Added a token for better protection against CSRF.

# Version 0.1.1

### Security

* Added basic protection against CSRF by checking Referer or Origin headers.

# Version 0.1.0

First release.

