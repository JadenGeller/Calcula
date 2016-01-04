# Calcula

Calcula provides a `Lambda` type for defining, comparing, and printing lambda calculus functions.

In [lambda calculus](https://en.wikipedia.org/wiki/Lambda_calculus), values are represented by functions. Here's an example defining two function *values*, one representing true and one representing false. It's [too hard](https://en.wikipedia.org/wiki/Halting_problem) to tell if two functions actually do the same thing, so we define equality based on shape. A function with the exact same *shape* as our `truth` function is what we call intensionally equal to our `truth` function. Thus, we can represent the values true and false with functions of a particular shape.
```swift
let truth   = Lambda { t in Lambda { f in t } }
let falsity = Lambda { t in Lambda { f in f } }
```
We didn't just arbitrarily choose these definitions though! Note that `truth` is a function that takes two arguments and always returns the first, and that `falsity` is a function that takes two arguments and always returns the second. Thus, we can easily write a function `not` that will return `falsity` given `truth` and will return `truth` given `falsity`.
```swift
let not = Lambda { condition in condition[falsity][truth] }
```
See how, when `condition == truth`, it will return the first argument passed to it, `falsity`, and when `condition == falsity`, it will return the second argument passed to it, `truth`. (Note that we use brackets to represent function invocation as parenthesis are reserved by Swift.)

We can also easily write `and` and `or`. When `condition1` is `true`, `and` will take on the value of `condition2`; otherwise, `and` will take on the value `falsity`. Similiarly, when `condition1` is `false`, `or` will take on the value of `condition2`' otherwise, `or` will take on the value `truth`.
```swift
let and = Lambda { condition1 in Lambda { condition2 in condition1[condition2][falsity] } }
let or  = Lambda { condition1 in Lambda { condition2 in condition1[truth][condition2] } }
```

We can easily check whether our functions work since Calcula supports checking intensional equality with the `==` operator.
```
print(and[truth][falsity] == falsity) // -> true
print(or[truth][falsity] == truth)    // -> true
```

Here's another example:
```swift
let pair   = Lambda { left in Lambda { right in Lambda { selector in selector[left][right] } } }
let first  = Lambda { pairing in pairing[truth] }
let second = Lambda { pairing in pairing[falsity] }

print(first[pair[truth][falsity]] == truth)    // true
print(second[pair[truth][falsity]] == falsity) // true
```
In the definition of `pair`, we apply `left` and `right` to an argument `selector` so we can later retrieve the desired argument by choice of a `selector` function. Recall that `truth` and `falsity` both expect two arguments, but `truth` returns the first argument it receives while `falsity` returns the second argument it receives. Thus, if we pass the selector `truth`, we can retrive the left element of our pair and if we pass the selector `falsity`, we can retrive the right element of our pair.
