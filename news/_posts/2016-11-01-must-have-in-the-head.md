---
layout: post
title: 3 Must Have &lt;meta> Tags
---

Every HTML document consists of two main tags, `<head>` and `<body>`. `<head>`
is a place for meta information, like the web page’s title and links to stylesheets
and javascripts.

In this post, I’ll share three absolutely must have, couldn’t live without `<meta>`
tags. They are:

```html
<meta charset='utf-8'>
<meta name='viewport' content='width=device-width'>
<meta name='description' content='A description that appears in search results'>
```

Let's break those down...


### `charset='utf-8'`

This attribute specifies the [character encoding](https://en.wikipedia.org/wiki/Character_encodings_in_HTML#Specifying_the_document.27s_character_encoding) the document should use.

There are 127 characters available to display on a web page using the default encoding,
[ascii](http://www.ascii-code.com/), which include the numbers 0-9, the letters
a-z, their uppercase variants A-Z, and other commonly used symbols: `!@#$%^&*()-+{}[]"'`

If you’re using any other symbol, like `é` (in resumé) or curly quotes `‘’“”`, the
browser will try to represent these characters with gibberish symbols: `â€˜â€œâ€™â€œ`

To show the characters you type into your text editor, add

```html
<meta charset='utf-8'>
```

to the `<head>` of your HTML document.


### `name='viewport' content='width=device-width'`

The viewport the browser’s virtual represenation of a screen's size. This allows users
to pinch to zoom and pan to focus on your content. 

Sometimes though, you want to override the default viewport width to take control
over what exactly your visitors see when they visit your site, especially on mobile
devices like phones and tablets.

By adding 

```html
<meta name="viewport" content="width=device-width">
```

you are telling the browser to force the layout into the provided screensize, rather
than allowing visitors to zoom into your content. In effect, the browser will
do the zooming for you.

Have a look at the following demonstrations:

With: ![](https://dl.dropbox.com/s/irquh1zzzfiz3fd/Screenshot%202016-11-01%2018.20.02.png?dl=0)

Without: ![](https://dl.dropbox.com/s/bj4h3s7nl1dlhgh/Screenshot%202016-11-01%2018.20.32.png?dl=0)

By specifying the viewport’s width, you’re putting your content front and center
for all visitors.

### `name='description' content='your description here'`
