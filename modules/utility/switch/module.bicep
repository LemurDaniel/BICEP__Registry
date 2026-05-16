targetScope = 'resourceGroup'

/////////////////////////////////////////////////////////////////////////
//
// Flag Functions

@export()
func switchFlag(flag 'caseSensitive' | 'ignoreWhitespace' | 'endsWith' | 'startsWith' | 'contains') object => {
  flag: true
  startsWith: 'startsWith' == flag
  endsWith: 'endsWith' == flag
  contains: 'contains' == flag
  caseSensitive: 'caseSensitive' == flag
  ignoreWhitespace: 'ignoreWhitespace' == flag
}

//@export()
//func switchFlags(flags ['caseSensitive' | 'ignoreWhitespace' | 'endsWith' | 'startsWith']) object =>
//  reduce(map(flags, entry => switchFlag(entry)), {}, (acc, entry) => union(entry, acc))

/////////////////////////////////////////////////////////////////////////
//
// Switch Functions

func switchPreProcess(value string?, cases array, error string?) object =>
  switchPreProcess2(
    reduce(
      filter(cases, case => case.?flag ?? false),
      {
        startsWith: false
        endsWith: false
        contains: false
        caseSensitive: false
        ignoreWhitespace: false
      },
      (acc, entry) => {
        startsWith: acc.startsWith || (entry.?startsWith ?? false)
        endsWith: acc.endsWith || (entry.?endsWith ?? false)
        contains: acc.contains || (entry.?contains ?? false)
        caseSensitive: acc.caseSensitive || (entry.?caseSensitive ?? false)
        ignoreWhitespace: acc.ignoreWhitespace || (entry.?ignoreWhitespace ?? false)
      }
    ),
    error,
    value ?? 'null',
    filter(cases, case => case.?default ?? false),
    filter(cases, case => !empty(case.?when))
  )

func switchPreProcess2(
  flags {
    contains: bool
    caseSensitive: bool
    startsWith: bool
    endsWith: bool
    ignoreWhitespace: bool
  },
  error string?,
  value string,
  defaults array,
  cases array
) object =>
  switchEvaluate(
    flags,
    error,
    flags.caseSensitive ? value : toLower(value),
    defaults,
    map(
      map(cases, case => {
        when: flags.ignoreWhitespace ? replace(case.when, ' ', '') : case.when
        then: case.then
      }),
      case => {
        when: flags.caseSensitive ? case.when : toLower(case.when)
        then: case.then
      }
    )
  )

func switchEvaluate(flags object, error string?, value string, defaults array, cases array) object =>
  last([
    // Check the number of default cases. Only one default case is allowed.
    length(defaults) <= 1 ? '' : fail('Only one default case is allowed')
    // Starts with and case sensitive are not compatible.
    flags.startsWith && flags.caseSensitive
      ? fail('Starts with is always CaseInsensitive! CaseSensitive has no effect!')
      : ''
    // Ends with and case sensitive are not compatible.
    flags.endsWith && flags.caseSensitive
      ? fail('Ends with is always CaseInsensitive! CaseSensitive has no effect!')
      : ''

    // Check if there are any cases that match the when condition.
    // If there are no cases that match, return the default case
    // Otherwise throw an error.
    concat(
      // Case match
      filter(cases, case => case.when == value),
      // Starts with match
      filter(cases, case => flags.startsWith && startsWith(value, case.when)),
      // Ends with match
      filter(cases, case => flags.endsWith && endsWith(value, case.when)),
      // Contains match
      filter(cases, case => flags.contains && contains(value, case.when)),

      //
      // Default case
      filter(defaults, default => default.default)
    )[?0].?then ?? fail(error ?? 'No case matched')
  ])

/////////////////////////////////////////////////////////////////////////
//
// Object Functions

@export()
@description('[Object] | Can be used in a switch statement to define a case.')
func case(when string, then object) object => {
  when: when
  then: {
    result: then
  }
}

@export()
@description('[Object] | Can be used in a switch statement to define a case.')
func default(then object) object => {
  default: true
  then: {
    result: then
  }
}

@export()
@description('[Object] | Similar to a switch statement returns the first case that matches. All cases are evaluated. No lazy evaluation!!!')
func switch(value string?, cases array) object => switchFail(value, cases, null)

@export()
@description('[Object] | Similar to a switch statement returns the first case that matches. All cases are evaluated. No lazy evaluation!!!')
func switchFail(value string?, cases array, error string?) object => switchPreProcess(value, cases, error)

/////////////////////////////////////////////////////////////////////////
//
// String Functions

@export()
@description('[String] | Can be used in a switch statement to define a case.')
func caseStr(when string, then string) object => {
  when: when
  then: {
    result: then
  }
}

@export()
@description('[String] | Can be used in a switch statement to define a case.')
func defaultStr(then string) object => {
  default: true
  then: {
    result: then
  }
}

@export()
@description('[String] | Similar to a switch statement returns the first case that matches. All cases are evaluated. No lazy evaluation!!!')
func switchStr(value string?, cases array) string => switch(value, cases).result

@export()
@description('[String] | Similar to a switch statement returns the first case that matches. All cases are evaluated. No lazy evaluation!!!')
func switchStrFail(value string?, cases array, error string) string => switchFail(value, cases, error).result

/////////////////////////////////////////////////////////////////////////
//
// Integer Functions

@export()
@description('[Int] | Can be used in a switch statement to define a case.')
func caseInt(when string, then int) object => {
  when: when
  then: {
    result: then
  }
}

@export()
@description('[Int] | Can be used in a switch statement to define a case.')
func defaultInt(then int) object => {
  default: true
  then: {
    result: then
  }
}

@export()
@description('[Int] | Similar to a switch statement returns the first case that matches. All cases are evaluated. No lazy evaluation!!!')
func switchInt(value string?, cases array) int => switch(value, cases).result

@export()
@description('[Int] | Similar to a switch statement returns the first case that matches. All cases are evaluated. No lazy evaluation!!!')
func switchIntFail(value string?, cases array, error string) int => switchFail(value, cases, error).result

/////////////////////////////////////////////////////////////////////////
//
// Array Functions

@export()
@description('[Array] | Can be used in a switch statement to define a case.')
func caseArr(when string, then array) object => {
  when: when
  then: {
    result: then
  }
}

@export()
@description('[Array] | Can be used in a switch statement to define a case.')
func defaultArr(then array) object => {
  default: true
  then: {
    result: then
  }
}

@export()
@description('[Array] | Similar to a switch statement returns the first case that matches. All cases are evaluated. No lazy evaluation!!!')
func switchArr(value string?, cases array) array => switch(value, cases).result

@export()
@description('[Array] | Similar to a switch statement returns the first case that matches. All cases are evaluated. No lazy evaluation!!!')
func switchArrFail(value string?, cases array, error string) array => switchFail(value, cases, error).result
