# REST APIs

[We have a demo project](https://github.com/2N-IT/DemoRest)

## Requests and responses

###url

###http methods

### Status codes

tldr:

2xx - it's working ok
3xx - router shenenigans
4xx - frontend messed up
5xx - backend messed up

Success Statuses

200 OK - request has succeeded. The catchall generic one.(GET, PUT and PATCH usually return this)

201 Created - The request was successful and resulted in creating a new resource (POST requests should return this)

202 Accepted - related to async handling, rarely used

204 No Content - Request successful server has nothing to return (usually for DELETE requests)

DON’T return 201 for a get data request it’s misleading and scary.

Error Statuses

400 Bad Request - something wrong with the request. Try fixing it before sending again
401 Unauthorised - you can’t do this without logging in
403 Forbidden - you are logged in correctly but dont have the permission for this
404 Not Found - the url you provided don’t show any resource (also used when user dont have permission but we don’t want to divulge the information that such data exists on the server potentially)

500 Internal Server Error - usually if an unhandled exception get raised when processing the request. Sometimes the request is a correct one but the server have a bug. Usually it’s a bad request that broke the server.

### Headers

1. CORS
2. content-type

### Authentication/Authorisation

### collections operations

1. pagination
2. filtering
3. ordering

### Other less common aspects

1.versionning
2.Rate limits/throttling


## Autogenerating documentation

## JSON::API

[JSON::API design documentation](todo)
[JSON::API ruby/rails gem](todo)