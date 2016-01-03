# Calcula
Lambda calculus framework for Swift supporting intensional equality

```swift
let truth   = Lambda { t in Lambda { f in t } }
let falsity = Lambda { t in Lambda { f in f } }

let and = Lambda { a in Lambda { b in a[b][falsity] } }
let or  = Lambda { a in Lambda { b in a[truth][b] } }
let not = Lambda { x in x[falsity][truth] }

print(and[truth][falsity] == falsity) // true
print(or[truth][falsity] == truth)    // true
```

```swift
let pair   = Lambda { x in Lambda { y in Lambda { f in f[x][y] } } }
let first  = Lambda { p in p[t] }
let second = Lambda { p in p[f] }

print(first[pair[truth][falsity]] == truth)    // true
print(second[pair[truth][falsity]] == falsity) // true
```
