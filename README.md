
# loader 2.0.0 ![stable](https://img.shields.io/badge/stability-stable-4EBA0F.svg?style=flat)

An asynchronous `Function` that blocks calls when loading.

The `Loader` class is useful when you don't need "lazy loading" or "unique keys".

Use [`LazyLoader`](http://github.com/aleclarson/lazy-loader) for result caching.

Use [`ListLoader`](http://github.com/aleclarson/list-loader) for unique key validation.

#### Properties

- `isLoading: Boolean { get }`

#### Events

- `didLoad(result: Any)`
- `didAbort()`
- `didFail(error: Error)`

#### Methods

- `load(args...) -> Promise`
- `abort()`
- `unload()`

-

**TODO:** Write tests!?
