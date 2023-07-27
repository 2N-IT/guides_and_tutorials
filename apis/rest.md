# REST APIs

[We have a demo project](https://github.com/2N-IT/DemoRest)

## Requests and responses

TODO: Write a section about http protocol 101
with: 
- url safe character/encoding
- url/uri/urn
- anatomy of a http url

### url anatomy

This is not strictly rest related but it can help to establish some terminology.

ex: https://example.com/path/to/resource?param1=value1&param2=value2#anchor

Anatomy of the URL:
- Scheme: `https://`
- Domain: `example.com`
- Path: `/path/to/resource`
- Query Parameters: `?param1=value1&param2=value2`
- Anchor: `#anchor`

The entire URL can be referred to as an address.

In this document about rest the 2 parts we care about the most are the `Path` and the `Query Parameters`

### resource path

The URLs path defines the resource we want to access. It differs from other API standards like  where you can have one address, and the content of the request body defines the response.

The simplest path would be just the name of the resource we want to access ex: `/users` The standard is to use the prular form of a noun. This example path would refer to all the users. If we want a specific user we add it's id after the resource name in the path. !note! while technically using params would work resource ids should be in the path. 

Example:
GOOD: /users/1
BAD: /users?user_id=1

We can expand on such a path when we want to acces related resources. ex: `/users/1/orders` will be a list of the users orders.

Notice that another approach would be `/orders?user_id=1` were we immediately access the end resource with added filters. It depend on the use case which form is the right one for the scenario ex if we want to avoid too long of an url with multiple nestings.

Paths can also have prefixes ex it's common for a rest api path to start with a `/api` and potentially to also have a version ex `/v1`.

we endup often with something resembing: `/api/v1/users/1/orders`

**Note on security:**
Using integers as ids is very convinient, easy to implement and to debug but also easy to exploit. Potential attakers could scrap more information than they should by just bumping the id by one nad checking the response. (even when permissions blok acces sometimes response times varie between processing requests for existing and unexisting data). A common solution to make this vector of attack harder is to use **uuid** as id key.

### http methods

The same url can have different effects based on the HTTP method used.
'GET mywebsite.com/book' will return a list of books while 'POST mywebsite.com/book' whill create a new book. 'PUT mywebsite.com/book/1' update the book with id 1 while 'DELETE mywebsite.com/book/1' whill delete it. 

**GET** - Shows data (single resource or collection) Sould not make any changes to the system just display. No body params in the request only url and headers.

**POST** - Creates new data. Possible to have a body content in the request (usually json)

**PUT/PATCH** - Edits data. Put overrides the entire object with provided data, patch changes only fields describes in the request.

**DELETE** - Deletes resource from the database

Post vs Put - Some specification argue that put should be used for creation and post should be used for edits. This is a less common approach but worht knowing about.

### But my feature need Actions/Processes

This is also often the most lackluster point of Rest. Being 100% focused on **Resource** crud is awkward in a **Process** oriented world where you can have different interactions with a resource.

For example we often have a `POST /sign_up` instead of a `POST /users` even if we technically are creating a user.

Another example would be a `POST /users/1/ban` instead of a `PATCH /users/1` with a body: `{banned: true}`. It's because in real life scenario the backend dont only store resource data with some acces policies but do some processing like side efects in the form of email notifications.

The fact that this kind of actions are taped to the base of a rest resource is also the reason why we have urls looking like `/users/1/ban` instead of `/users/ban/1/`. We try to keep the REST convention in path building as long as we can and diverge only in the last element.

## Status codes

### summary:

2xx - it's working ok
3xx - router shenenigans
4xx - frontend messed up
5xx - backend messed up

### Success Statuses

200 OK - request has succeeded. The catchall generic one.(GET, PUT and PATCH usually return this)

201 Created - The request was successful and resulted in creating a new resource (POST requests should return this)

202 Accepted - related to async handling, rarely used

204 No Content - Request successful server has nothing to return (usually for DELETE requests)

DON’T return 201 for a get data request it’s misleading and scary. It implies that some database changes were made while we were trying to just read data.

### Error Statuses

**400 Bad Request** - something wrong with the request. Try fixing it before sending again

**401 Unauthorised** - you can’t do this without logging in

**403 Forbidden** - you are logged in correctly but dont have the permission for this

**404 Not Found** - the url you provided don’t show any resource

**500 Internal Server Error** - usually if an unhandled exception get raised when processing the request. Sometimes the request is a correct one but the server have a bug. Usually it’s a bad request that broke the server.

401 vs 403 - Q: Why should we differentiate between these two status codes? Can't we always use 403 since being unidentified technically means being forbidden from the action?

A: It's better to be specific thant vague. Also it allow better frontend handling. ex: 401 redirect the interface to a login page while 403 display a message to contact some admin or manager if you need access.

403 vs 404 - Q: If the resource id exists in the database but is outside the scope of the user, should I use 403 or 404?

A: thechnically by the definitions one would argue 403 is the correct status. But from a security point of view if a user dont have access to a resource he probably shouldnt even have acces to the knowledge of it's existance so it's safer to use 404.

## Headers

In addition to the url and the body of requests/responses headers are often used to carry some additional meta information. Most of the time these are handled by the tools used to serve the api but it's useful to have a list to check in case you need to add them/ configure them.

1. CORS

    This is the one that's most important to remember since you need to manually configure it. (Check demo project for example).

    Remember that curl requests and testing using postman and similar tools will work fine witout cors headers. BUT it wont work once a browser based application start to making calls to the api. #ItWorkedWhenITestedIt

    TODO: section on how to test it and on the technical aspects why it's used

2. content-type

    Remember to add the correct header (application/json in 99.99% of the cases). It helps with autodetection for some dev/debugging tools in addition to being the 'technically correct thing to do.'

3. caching

    Cache-Control header can be used to define the caching settings. It's worth to check if you have issues were it seems as if the requests made in front dont get registred in backend logs or have outdated data.

4. Auth

    More on this in next section. Auth data is usually communicated through headers.

## Authentication/Authorisation

Before any details the obvious basics: if you use http instead of **https** it's all pointless and insecure.

Since rest apis are stateless but we need to provide user based features authorisation mechanisms needed to be defined. There are different approaches but most of them result in using a Token in each request that allows the server to identify the user making it.

Authentication is the process of receiving such a Token for example by providing login/password credentials.

Token security is very important and multiple features on top of just issuing it can be added:

  1- Tokens can be timed so they expire after a set duration. Usually to avoid breaking the user flow and asking him to resubmit his credentials during app use refresh mechanisms are added to generate a new token.

  2-Possibility to revoke tokens. Something like the feature log me out on other devices for example. usually changing an accounts password should revoke old tokens.

There are different ways to implement tokens:

### JWT

This approach encode some identifing data in a token. On each request the token is deserialized since the issuing party have the decryption keys. ANy kind of data can be stored in such a token wich is bot good and potenially open to bad practices.

Good points:
   + A lot of ready tools
   + relatively simple
   + No database storage of tokens needed

Bad Points:
  + triky to revoke/blaklist tokens since they are not stored in db

### Oauth

This kind of tokens are popular when you need to make some server to server communication on behalf of a user. Ex: sign-in with facebook were the customer give your app permission to retreive information from facebook on their behalf.

Good points:
  + Standardised approach common in different sites (facebook/shopify ...)

Bad points:
  + Designed for specific cases you probably wont have it as the single token type in an app
  + Can be a bit complicated to start depending on added security measures/configs

### Custom Tokens

A catch all category. Most of the apps will have a custom way to generate tokens and will differ in what additional features the tokens will handle: timed or eternal, revokable or not, how are they stored ...

Good points:
  + you can have any feature you want

Bad points:
  + you need to implement any feature you want from scratch
  + lack of standarization
  
### Auth summary

when to use which kind of auth strategy?
- If your auth lib offer some kind of ready gem use it if possible. Usually it will be some kind of custom token ex [devise-api](https://github.com/nejdetkadir/devise-api)
- If you need to make somthing without storing backend data use JWT tokens
- If the communication is server-server but on behalf of a user use Oauth

header note: It's common to have a prefix in the authorisation header but it's not always the case. Make sure to document well the structure when making an api and cheking the docs when using one. ex: ```Authorization: Bearer <token>``` or ```Authorization: <token>```

## collections operations

1. pagination
2. filtering
3. ordering

## Other less common aspects

1.versionning
2.Rate limits/throttling


## Autogenerating documentation

All developped APIs **Should** have a documentation. No, your code is not self-documenting. Assume the documentation is needed for a frontend developper with no knowlege of your backend stack.
Swagger is a well-defined documentation standard for REST APIs and is highly recommended.

Since manually updated documentation takes time and often get out of sync with the code, auto-generating the documentation is preferred. Good rest api libraries allow you to generate a documentation contaning: Endpoint urls, request params and response schema from code. Some additional tags can be used to add more info like error messages or short descriptions.

Most autogeneration tools provide juste a swagger JSON file. Make sure to also include a swagger interface for ease of use.

For examples of such documentation you cna have a look at the [demorest app](https://github.com/2N-IT/DemoRest).

Additional notes:
- http status codes need to be manually set and described dont forget them
- using Serializers instead of plain hash objects for responses will allow you to easly document responses
- remember in setting response serializers to include when it's an array of objects and when it's a single object.

# JSON::API

- [JSON::API design documentation](official documentation)
- [JSON::API ruby/rails gem](Rails gem)
