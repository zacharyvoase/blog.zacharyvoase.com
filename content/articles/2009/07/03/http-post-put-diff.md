--- 
kind: article
timestamp: 2009-07-03
title: "The Difference Between POST and PUT—Get it Right!"
---

I’ve been getting pretty annoyed lately by a popular misconception by web
developers that a POST is used to create a resource, and a PUT is used to
update/change one.

If you take a look at page 55 of [RFC 2616](http://www.ietf.org/rfc/rfc2616.txt)
(“Hypertext Transfer Protocol -- HTTP/1.1”), Section 9.6 (“PUT”), you’ll see
what PUT is actually for:

> The PUT method requests that the enclosed entity be stored under the
> supplied Request-URI.

There’s also a handy paragraph to explain the difference between POST and PUT:

> The fundamental difference between the POST and PUT requests is reflected
> in the different meaning of the Request-URI. The URI in a POST request
> identifies the resource that will handle the enclosed entity. That
> resource might be a data-accepting process, a gateway to some other
> protocol, or a separate entity that accepts annotations. In contrast, the
> URI in a PUT request identifies the entity enclosed with the request --
> the user agent knows what URI is intended and the server MUST NOT attempt
> to apply the request to some other resource.

It doesn’t mention anything about the difference between updating/creating,
because that’s not what it’s about. It’s about the difference between this:

    obj.set_attribute(value) # A POST request.

And this:

    obj.attribute = value # A PUT request.

So please, stop the spread of this popular misconception. Read your RFCs.
