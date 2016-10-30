---
layout: post
---

<div class='notice' style='margin-top:10px;'>
  Note: a Pro membership is required to use contact forms.
</div>

In this post, I’ll show you how to add a contact form to your UpDog site, like
this one:

<https://contact-form-example.updog.co/>

In order to start receiving messages from your site's visitors, you’ll need to
add an HTML form. The minimum required code to set this up is:

```html
<form method='post'>
  <textarea name='message'></textarea>
  <button type='submit'>Submit</button>
</form>
```

### Required Code

The two most important parts of the above code are:

```html
<form method='post'>
```

which tells UpDog to process a form request instead of loading a file from your
Dropbox folder.

and

```html
<input name='message'>
```

Every form input on your site with a `name` attribute, will be collected and formatted
into a table before arriving in your inbox.

![](https://dl.dropbox.com/s/8v69u1nuchepw3w/Screenshot%202016-10-30%2017.26.23.png?dl=0)

You can have as many form inputs as you like.

### Confirming a Successful Form Submission

By default, visitors who submit the contact form will be redirected back to the
page with the contact form.

If instead, you’d like to redirect to a thank you or confirmation page, add a
hidden input with the name `redirect`, like:

```html
<input type='hidden' name='redirect' value='/thanks.html'>
```

### The Complete Code

```html
<!-- index.html -->
<h1>An Example Contact Form</h1>
<form method='post'>
  <label>Your Email</label>
  <input required type='email' name='email' placeholder='jane@doe.com'>
  <label>Your Message</label>
  <textarea required name='message'></textarea><br>
  <input type='hidden' value='/thanks.html' name='redirect'>
  <button type='submit'>Submit</button>
</form>
```

```html
<!-- thanks.html -->
<h1>Thank You!</h1>
<p>Your form was sent successfully.</p>
```

Questions? [Contact us](/contact).
