---
layout: default
title: UpDog Now Supports Markdown Rendering
---

<meta http-equiv="refresh" content="0;URL='https://jshawl.updog.co/markdown-example.md'" />

# UpDog Now Supports Markdown!

We're happy to announce that UpDog now compiles markdown files (any file that ends in `.md` or `.markdown`) automatically for Pro members.

You can view the raw markdown at anytime by appending `?raw` to the URL, like this:

https://jshawl.updog.co/markdown-example.md?raw

Pretty cool, huh?

>A CSS File has been provided for you, though you can override these styles by
adding a file named `markdown.css` to your site's document root.

## UpDog Syntax-Highlights Your Code

```js
// javascript
var i = 0;
for(var i = 0; i < 10; i++){
  console.log(i);
}
```

```css
/* CSS */
body{
  font-family: 'Helvetica Neue', Helvetica;
  line-height: 1;
}
```

```rb
# ruby
class User < ActiveRecord::Base
  has_many :posts
end
```

We're using the [GitHub Pygments CSS Theme](https://github.com/richleland/pygments-css/blob/master/autumn.css), but you can include your own [Pygments theme](http://richleland.github.io/pygments-css/).

## Getting Started

1. Upgrade to a Pro membership
  - If you haven't already
2. Click on `settings` for one of your sites.
3. Enable markdown rendering.
4. Check it out in a browser!
