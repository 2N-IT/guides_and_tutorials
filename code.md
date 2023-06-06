## Service Objects

Probably **Operation/Command/Action** or even **Process** would be a better name, but **Service Object** is most common name of this pattern/concept in Rails community, so lets stick to it.

### Why?

The Rails-way approach and the standard MVC pattern don't provide us with a meaningful place for complex business logic.

List below presents what can happen when you stick strictly to MVC:
- you could have **very large models** with logic seemingly related to it (e.g. creating an order object that also sends emails or updates stock levels, which also changes other models or performs "non-model" actions)
- you could have **very large controller methods**, which often results in code duplication if the same logic can be called in multiple places in the system and violates basic object-oriented programming principles such as SRP (the controller should accept parameters, call the appropriate class, and return its result to the view it renders, it should not be responsible for the details of a given action's logic).

As a result, it becomes **unreadable** and very difficult to test and maintain.

Therefore, one of the most frequently and quickly introduced concepts into MVC projects is the **ServiceObject**.

### What?

*“What is a Rails service object”* - definition / explanation written down by Andrzej Krzywda about 10 years ago, and still relevant:

>In my observation different programming communities have different meaning of service objects.
>
>
>Before I describe ‘the Rails meaning’ I’d like to quote some more generic definitions.
>
>- According to Martin Fowler’s - P of EEA Catalog:
>
> > Defines an application’s boundary with a layer of services that establishes a set of available operations and coordinates the application’s response in each operation.
>
>  - Bryan Helmkapp, the autor of famous “7 patterns to refactor Fat ActiveRecord models” described it as 
>    >Some actions in a system warrant a Service Object to encapsulate their operation.
>
>    I reach for Service Object when an action meets one or more of these criteria
>
>    - The action is complex (eg. closing the books at the end of accounting period )
>    - The action reaches accross multiple models (e.g. e-commerce purchase using Order, CreditCard and Customer objects)
>    - The action interacts with an external service (e.g. posting to social networks)
>    - The action is not a core concern of the underlying model ( e.g. sweeping up outdated data after a certain time period)
>    - There are multiple ways of performing the action (e.g. authenticating with an access token or password). This is the Gang of Four Strategy pattern.
>
>  - According to Eric Evans and his Domain-Driven Design: Tackling Complexity in the Heart of Software’s book:
>
> > Service: A standalone operation withing the context of your domain. A Service Object collects one or more services into an object. Typically you will have only one instance of each service object type within your execution context.
>  
>
>In the Rails world, the most popular defitnion seems to be: **everything that happens in the controller without all the HTTP-related stuff (params, render, redirect).**
>
>A service object encapsulates a single process of the business logic.


### How?

There are **hundreds** of different implementations of ServiceObjects (sometimes called *operations* or *processes*) to be found in the wild. All are based on the principles described above, but mainly differ in context of:
- error handling
- error storage
- result storage
- returned values and approach to accessing these data.

[In the approach we agreed upon as the default](https://github.com/mateuszbialowas/brug-service_objects/pull/4), we have established the following rules:

- SO is invoked once in the lifetime of the request in order to perform one task
- The data stored by SO (both errors and results) should not be changed in it
- SO returns itself
- In the returned object, we have access to the #errors method that stores information about errors (both unhappy-path and errors caught by rescue), and #result that stores information about the result or details of the error message if any occurred
- Additionally, the SO object has a #success? method that returns true if there is no indication in the @errors array (returned by the #errors method) that something went wrong with the happy-path
- In case of any [StandardError](https://www.honeybadger.io/blog/ruby-exception-vs-standarderror-whats-the-difference/), the BaseService catches such error, saves it in the errors array, and then interrupts further SO operations

[Examples of other approaches to SO](https://github.com/mateuszbialowas/brug-service_objects/pulls)
