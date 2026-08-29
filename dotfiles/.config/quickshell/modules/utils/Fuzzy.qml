pragma Singleton
import Quickshell
import "./fuzzySort.js" as FuzzySort


Singleton {
    function go(...args) {
        return FuzzySort.go(...args)
    }

    function prepare(...args) {
        return FuzzySort.prepare(...args)
    }
}

