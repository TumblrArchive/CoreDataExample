# Core Data Example

This is a sample project whose purpose is to gather feedback on the best way to use Core Data in a multithreaded environment. Here's a [blog post]() explaining the motivation behind this repository:

> We’ve been using Core Data for persistence in [Tumblr for iOS](https://itunes.apple.com/us/app/tumblr/id305343404) for years now, but are always interested in re-evaluating our approach to make sure that we’re leveraging the SDK as effectively as possible.

The focal point is the [TMCoreDataController](https://github.com/tumblr/CoreDataExample/blob/master/CoreDataExample/TMCoreDataController.h) class, which exposes a block-based API for updating managed object contexts both from the main queue as well as in the background.

The application simply fetches, persists, and displays a little bit of data from the Tumblr API, in order to provide a real-world example of how `TMCoreDataController` is expected to be used.

If you have any feedback, please create [issues](https://github.ewr01.tumblr.net/bryan/CoreDataExample/issues) or [pull requests](https://github.ewr01.tumblr.net/bryan/CoreDataExample/pulls). Thanks for taking a look!

## Approach

`TMCoreDataController` is implemented using three-levels of parent/child managed object contexts (based off of the suggestions made in [this blog post](http://floriankugler.com/blog/2013/4/2/the-concurrent-core-data-stack)):

* **Master** context (private queue concurrency type) – long lived
    * **Main** context (main queue concurrency type) – long lived
        * **Background** contexts (private queue concurrency type) – a new one created each time

Write operations should only be done through `TMCoreDataController`'s `performBackgroundBlockAndWait:` and `performMainContextBlock:` methods, both of which save the context being written to as well as any parent contexts (recursively) immediately after.

### Thought process

* Disk writes are slow, so we want them to happen off of the main thread. Hence writing to disk occurs in the background when the master context is saved.
* Main context is written to and read from on the main queue via interaction with user interface.
* Background updates (e.g. updating our Core Data database off the back of network requests) occur on a background context. A new background context is created each time to make sure they are up to date.
    * Background context is a child of the main context such that the UI is updated after our background changes are saved.
* When a managed object context is saved, its parent context(s) are also saved, recursively, so ensure that all of our changes are written to disk.

In this particular example, the “heavy lifting” of updating our database with new posts is done in `TMDashboardViewController`'s `refresh` method. The code in this particular project is pretty simple and contrived, but assume that a lot more work would be done here in a real production app. It is expected that user interaction may result in updates to the main queue's context while this background block is being executed.

## Running CoreDataExample

To run the sample application, you need to add OAuth keys, tokens, and secrets to [TMAppDelegate](https://github.com/tumblr/CoreDataExample/blob/master/CoreDataExample/TMAppDelegate.m#L24). If you don't already have one, you can create a Tumblr API application [here](https://www.tumblr.com/oauth/apps) and generate a token and secret using our [API console](https://api.tumblr.com/console).

## Questions

What problems are there with this approach? How could this be improved?

Specifically:

* Is the recursive managed object context save the best way to ensure that all of our data is kept in sync?

* I'm worried that this architecture makes us susceptible to deadlocks, as outlined in [this article](http://wbyoung.tumblr.com/post/27851725562/core-data-growing-pains):

> With NSFetchedResultsController and nested contexts, it’s pretty easy to do. Using the same UIManagedDocument setup described above, executing fetch requests in the private queue context while using NSFetchedResultsController with the main queue context will likely deadlock. If you start both at about the same time it happens with almost 100% consistency. NSFetchedResultsController is probably acquiring a lock that it shouldn’t be. This has been reported as fixed for an upcoming release of iOS.

Unfortunately I've seen a couple of crashes which may corroborate the above, such as:

    Incident Identifier: 5168BD71-BFD2-4DF6-84C4-240364B888DD
    CrashReporter Key:   289E38A8-3E8A-41CB-877F-1FEEF852AF30
    Hardware Model:      iPhone6,1
    Version:         251
    Code Type:       ARM-64
    Parent Process:  launchd [1]

    Date/Time:       2014-05-13T01:23:26Z
    OS Version:      iPhone OS 7.1.1 (11D201)
    Report Version:  104

    Exception Type:  SIGSEGV
    Exception Codes: SEGV_ACCERR at 0xbf02beb8
    Crashed Thread:  0

    Application Specific Information:
    objc_msgSend() selector name: isFault

    Thread 0 Crashed:
    0   libobjc.A.dylib                      0x00000001978fc1d0 objc_msgSend + 16
    1   CoreData                             0x000000018b1782a8 __92-[NSManagedObjectContext(_NestedContextSupport) newValuesForObjectWithID:withContext:error:]_block_invoke + 276
    2   libdispatch.dylib                    0x0000000197ec3fd4 _dispatch_client_callout + 12
    3   libdispatch.dylib                    0x0000000197ec9c84 _dispatch_barrier_sync_f_invoke + 44
    4   CoreData                             0x000000018b16ccec _perform + 120
    5   CoreData                             0x000000018b178150 -[NSManagedObjectContext(_NestedContextSupport) newValuesForObjectWithID:withContext:error:] + 124
    6   CoreData                             0x000000018b0e8b00 _PFFaultHandlerLookupRow + 356
    7   CoreData                             0x000000018b0e8604 _PF_FulfillDeferredFault + 252
    8   CoreData                             0x000000018b0e8458 _sharedIMPL_pvfk_core + 60
    9   ExampleApplication                   0x00000001000887cc 0x100054000 + 214988
    10  ExampleApplication                   0x00000001000625c0 0x100054000 + 58816
    11  libdispatch.dylib                    0x0000000197ec4014 _dispatch_call_block_and_release + 20
    12  libdispatch.dylib                    0x0000000197ec3fd4 _dispatch_client_callout + 12
    13  libdispatch.dylib                    0x0000000197ec9ea8 _dispatch_after_timer_callback + 76
    14  libdispatch.dylib                    0x0000000197ec3fd4 _dispatch_client_callout + 12
    15  libdispatch.dylib                    0x0000000197ec5b90 _dispatch_source_invoke + 496
    16  libdispatch.dylib                    0x0000000197ec7180 _dispatch_main_queue_callback_4CF + 240
    17  CoreFoundation                       0x000000018b3a2c2c __CFRUNLOOP_IS_SERVICING_THE_MAIN_DISPATCH_QUEUE__ + 8
    18  CoreFoundation                       0x000000018b3a0f6c __CFRunLoopRun + 1448
    19  CoreFoundation                       0x000000018b2e1c20 CFRunLoopRunSpecific + 448
    20  GraphicsServices                     0x0000000190fc9c0c GSEventRunModal + 164
    21  UIKit                                0x000000018e412fdc UIApplicationMain + 1152
    22  ExampleApplication                   0x000000010005df3c 0x100054000 + 40764
    23  libdyld.dylib                        0x0000000197edfaa0 start + 0

How can this be mitigated, other than just optimizing all of our fetches and saves to prevent the persistent store coordinator from being locked for longer than it needs to be?

### Marcus Zarra's suggestions for how to prevent deadlocks (thanks for your feedback, Marcus!)

* [“Long fetch, long save, long activity to the PSC locks it. Simple rule, don't lock the PSC for a long time.”](https://twitter.com/mzarra/status/466302788863938560)
* [“Smaller saves during the import, more intelligent fetching for your update/insert question. Those are the normal first pass items.”](https://twitter.com/mzarra/status/466304487859048448)
* [“Doing a count instead of a fetch, fetching ids only, predicate performance, batch size, things like that can make a huge difference.”](https://twitter.com/mzarra/status/466316613227409408)

## Thank you!

Bryan Irace ([Email](mailto:bryan@tumblr.com), [Twitter](http://twitter.com/irace))

