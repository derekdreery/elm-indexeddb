
var _derekdreery$elm_indexeddb$Native_IndexedDB = function() {
"use strict";

/*
 * This library is structured as follows:
 *  - First we write converters between IDB objects and Elm objects
 *  - Then we define errors
 *  - Then idk
 */

var hasIndexedDB = Boolean(window && window.indexedDB);
var indexedDB = hasIndexedDB ? window.indexedDB : null;

// use this for giving each database an identifier
// Databases are opened for the duration of the app
// TODO look at closing if Db type goes out of scope (db.close())
var dbid = 0;
var databases = {};


// ERRORS

/**
 * An elm error type for when there is no database
 */
var noIndexedDBError = {
    ctor: "NoIndexedDBError",
    _0: "indexedDB is not present on this platform"
};

function noDatabaseError(db) {
    return {
        ctor: "DbNotFound",
        _0: "Could not find the database with the db id " + db
    };
}

var abortError = {
    ctor: "Abort",
    _0: "The IndexedDB transaction was aborted"
};

/**
 * Convert a js error to an elm error
 */
function jsErrorToError(err) {
    return {
        ctor: "_Tuple2",
        _0: { ctor: err.name },
        _1: err.message
    };
}

/**
 * Convert an indexedDB error event to an elm error
 */
function eventToError(event) {
    return jsErrorToError(event.target.error);
}

// HELPER FUNCTIONS


/**
 * Convert KeyPath elm value to javascript value for indexedDB
 */
function convertKeyPath(keyPath) {
    switch (keyPath.ctor) {
    case "NoKeyPath":
        return null;
    case "SingleKeyPath":
        return keyPath._0;
    case "MultiKeyPath":
        return _elm_lang$core$Native_List.toArray(keyPath._0);
    default:
        throw new Error(
            "Invalid keyPath state '" + keyPath.ctor + "', this " +
            "is a bug in elm-indexeddb - please report it!"
        );
    }
}


/**
 * Conver the elm object for addObjectStore options to the form indexedDB
 * expects
 */
function convertAddStoreOptions(options) {
    return Object.assign({}, options, {
        keyPath: convertKeyPath(options.keyPath)
    });
}


/**
 * Fetch a reference to an existing object store
 */
function getObjectStore(objectStores, name, transaction) {
    objectStores[name] = transaction.objectStore(name);
}


/**
 * Converts a maybe to null if Nothing
 */
function unwrapMaybe(maybe, defaultVal) {
    switch (maybe.ctor) {
    case 'Just':
        return maybe._0;
    case 'Nothing':
        return defaultVal; // defaults to undefined
    default:
        throw new Error(
            "Maybe has value other than Just or Nothing (" + maybe.ctor + ")"
        );
    }
}


/**
 * Function to map a nullable (or undefined) value to an elm maybe
 */
function wrapMaybe(value) {
    if (value == null) {
        return { ctor: 'Nothing' }
    }
    return {
        ctor: 'Just',
        _0: value
    };
}


/**
 * Convert an elm KeyRange to an IDBKeyRange
 */
function convertIDBKeyRange(keyRange) {
    switch (keyRange.ctor) {
    case "UpperBound":
        // UpperBound Value Bool
        return IDBKeyRange.upperBound(keyRange._0, keyRange._1);
    case "LowerBound":
        // LowerBound Value Bool
        return IDBKeyRange.lowerBound(keyRange._0, keyRange._1);
    case "Bound":
        // Bound Value Value Bool Bool
        return IDBKeyRange.bound(
            keyRange._0,
            keyRange._1,
            keyRange._2,
            keyRange._3
        );
    case "Only":
        // Only Value
        return IDBKeyRange.only(keyRange._0);
    default:
        throw new Error(
            "Invalid KeyRange.ctor '" + keyRange.ctor + "', this " +
            "is a bug in elm-indexeddb - please report it!"
        );
    }
}

/**
 * Applies an upgrade action to the database. Should only be called during
 * `onupgradeneeded`
 *
 * @param {IDBDatabase} db The database
 * @param {Object} action The Elm action
 * @param {Object} objectStores A hash of object stores, used for
 *      adding/removing indexed
 * @param {IDBTransaction} transaction The indexedDB transaction, used for
 *      getting object stores we aren't creating
 */
function applyUpgradeAction(db, action, objectStores, transaction) {
    switch (action.ctor) {
    case "AddObjectStore":
        objectStores[action._0] =
            db.createObjectStore(action._0, convertAddStoreOptions(action._1));
        break;
    case "DeleteObjectStore":
        db.deleteObjectStore(action._0);
        break;
    case "AddIndex":
        if (!objectStores[action._0]) {
            getObjectStore(objectStores, action._0, transaction);
        }
        objectStores[action._0].createIndex(
            action._1,
            convertKeyPath(action._2),
            action._3
        );
        break;
    case "DeleteIndex":
        if (!objectStores[action._0]) {
            getObjectStore(objectStores, action._0, transaction);
        }
        objectStores[action._0].delerteIndex(action._1);
        break;
    default:
        throw new Error(
            "Invalid action '" + action.ctor + "', this " +
            "is a bug in elm-indexeddb - please report it!"
        );
    }
}

/**
 *
 */
function getTransactionParameters(operations) {
    var i, l, op, store
      , stores = [] // `Set` would be a better data structure, but not old js
      , write = false;
    for (i=0, l=operations.length; i<l; i++) {
        op = operations[i];
        store = op._0;

        switch (op._1.ctor) {
        case "Add":
        case "Clear":
        case "Delete":
        case "Put":
            write = true;
            break;
        case "Get":
        case "GetAll":
        case "Count":
            // no-op
            break;
        default:
            throw new Error(
                "Invalid operation type '" + op.ctor + "', this " +
                "is a bug in elm-indexeddb - please report it!"
            );
        }

        // ie9+ only - is this OK? A: yes, as IDB is ie10+
        if (stores.indexOf(store) == -1) {
            stores.push(store);
        }
    }

    return {
        stores: stores,
        write: write
    };
}

/**
 *
 */
function applyTransactionOperation(transaction, op, results, resultIdx) {
    var store = transaction.objectStore(op._0)
      , maybeKeyRange
      , request;
    op = op._1;

    switch (op.ctor) {
    case "Add":
        //console.log(op);
        // op._1 = Maybe Value
        request = store.add(op._0, unwrapMaybe(op._1));
        break;
    case "Clear":
        // IDB call
        request = store.clear();
        break;
    case "Delete":
        request = store.delete(convertIDBKeyRange(op._0));
        break;
    case "Put":
        request = store.put(op._0, unwrapMaybe(op._1));
        break;
    case "Get":
        request = store.get(convertIDBKeyRange(op._0));
        break;
    case "GetAll":
        request = store.getAll();
        break;
    case "Count":
        maybeKeyRange = unwrapMaybe(op._0);
        if (maybeKeyRange == null) {
            request = store.count();
        } else {
            request = store.count(convertIDBKeyRange(maybeKeyRange));
        }
        break;
    default:
        throw new Error(
            "Invalid operation type '" + op.ctor + "', this " +
            "is a bug in elm-indexeddb - please report it!"
        );
    }

    // request.onerror is handled by the transaciton (I think :S)
    request.onsuccess = function(evt) {
        //debugger;
        results[resultIdx] = evt.target.result;
    }
}

// CALLABLE METHODS

/**
 * Open a database
 *
 * @param {String} name The name of the database
 * @param {Integer} version The version of the database to open
 * @param {Function} upgradeFn A function to upgrade the database (the only
 *    place to create and delete object stores, and modify indexes).
 *
 * @returns {Function} A function created by the scheduler to feed the Cmd back
 *    into elm (I assume I don't actually know)
 */
function open(name, version, upgradeFn) {
    return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback) {
        var request;
        if (!hasIndexedDB) {
            callback(_elm_lang$core$Native_Scheduler.fail(noIndexedDBError));
        }

        request = indexedDB.open(name, version);


        request.onerror = function(event) {;
            callback(_elm_lang$core$Native_Scheduler.fail(eventToError(event)));
        }

        request.onsuccess = function(event) {
            callback(_elm_lang$core$Native_Scheduler.succeed(event.target.result));
        }

        request.onupgradeneeded = function(event) {
            var db = event.target.result
              , transaction = event.target.transaction
              , oldVersion = event.oldVersion
              , newVersion = event.newVersion
              , upgrades = A2(upgradeFn, oldVersion, newVersion)
              // objectStores keep any opened stores around for indexing
              // Lifetime is this function
              , objectStores = {};

            // TODO write bindings for all the operations that can be done
            // while upgrading the db
            //console.log(oldVersion, newVersion, upgrades);

            // Walk the upgrades linked-list and action the commands
            while (upgrades.ctor == "::") {
                applyUpgradeAction(db, upgrades._0, objectStores, transaction);
                upgrades = upgrades._1
            }
        }
    });
}

/**
 * Execute an action against the database
 *
 * @param {Int} db The database id generated by a call to `open`
 * @param {Transaction} operations The operations to run as part of the
 * transaction
 *
 * @return {Function} Scheduler function
 */
function transaction(db, operations) {
    return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback) {
        var i, l, op, transParams, transaction
          , results = new Array(operations.length); // for get results

        if (db == null) {
            callback(_elm_lang$core$Native_Scheduler.fail(noDatabaseError(db)));
            return;
        }
        // convert to array for ease of use
        operations = _elm_lang$core$Native_List.toArray(operations);
        // Work out what we need to know to open the transaction
        transParams = getTransactionParameters(operations);
        try {
            // create the IDB transaction
            transaction = db.transaction(
                transParams.stores,
                transParams.write ? 'readwrite' : 'readonly'
            );
        } catch (err) {
            //console.log(err);
            callback(_elm_lang$core$Native_Scheduler.fail(jsErrorToError(err)));
            return;
        }

        for (i=0, l=operations.length; i<l; i++) {
            op = operations[i];
            // results is pass by ref (is there a better way to do this)
            applyTransactionOperation(transaction, op, results, i);

        }

        transaction.oncomplete = function(evt) {
            results = _elm_lang$core$Native_List.fromArray(results.map(wrapMaybe));
            console.log(results);
            callback(_elm_lang$core$Native_Scheduler.succeed(results));
        };

        transaction.onabort = function(evt) {
            callback(_elm_lang$core$Native_Scheduler.fail(abortError));
        };

        transaction.onerror = function(evt) {
            callback(_elm_lang$core$Native_Scheduler.fail(eventToError(evt)));
        };
    });
}


return {
    open: F3(open),
    transaction: F2(transaction)
};

}();
