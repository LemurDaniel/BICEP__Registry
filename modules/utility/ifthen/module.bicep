targetScope = 'resourceGroup'

/////////////////////////////////////////////////////////////////////////
//
// Switch Functions

func ifThenPreProcess(cases array, error string?) object =>
  ifThenEvaluate(error, filter(cases, case => case.?default ?? false), filter(cases, case => !(case.?default ?? false)))

func ifThenEvaluate(error string?, defaults array, whens array) object =>
  last([
    // Check the number of default cases. Only one default case is allowed.
    length(defaults) <= 1 ? '' : fail('Only one default case is allowed')

    // Check if there are any cases that match the when condition.
    // If there are no cases that match, return the default case
    // Otherwise throw an error.
    concat(
      // Case match
      filter(whens, item => item.when),

      //
      // Default case
      filter(defaults, default => default.default)
    )[?0].?then ?? fail(error ?? 'No case matched')
  ])

/////////////////////////////////////////////////////////////////////////
//
// Object Functions

@export()
@description('[Object] | Define a condition and result.')
func when(when bool, then object) object => {
  when: when
  then: {
    result: then
  }
}

@export()
@description('[Object] | Define an when else statment')
func else(then object) object => {
  default: true
  then: {
    result: then
  }
}

@export()
@description('[Object] | Define a set of conditions and results. No lazy evaluation!!!')
func ifThen(whens array) object => ifThenFail(whens, null)

@export()
@description('[Object] | Define a set of conditions and results. No lazy evaluation!!!')
func ifThenFail(whens array, error string?) object => ifThenPreProcess(whens, error)

/////////////////////////////////////////////////////////////////////////
//
// String Functions

@export()
@description('[String] | Define an when else statment')
func whenStr(when bool, then string) object => {
  when: when
  then: {
    result: then
  }
}

@export()
@description('[String] | Define an when else statment')
func elseStr(then string) object => {
  default: true
  then: {
    result: then
  }
}

@export()
@description('[String] | Define a set of conditions and results. No lazy evaluation!!!')
func ifThenStr(whens array) string => ifThen(whens).result

@export()
@description('[String] | Define a set of conditions and results. No lazy evaluation!!!')
func ifThenStrFail(whens array, error string) string => ifThenFail(whens, error).result

/////////////////////////////////////////////////////////////////////////
//
// Integer Functions

@export()
@description('[Int] | Define an when else statment')
func whenInt(when bool, then int) object => {
  when: when
  then: {
    result: then
  }
}

@export()
@description('[Int] | Define an when else statment')
func elseInt(then int) object => {
  default: true
  then: {
    result: then
  }
}

@export()
@description('[Int] | Define a set of conditions and results. No lazy evaluation!!!')
func ifThenInt(whens array) int => ifThen(whens).result

@export()
@description('[Int] | Define a set of conditions and results. No lazy evaluation!!!')
func ifThenFailInt(whens array, error string) int => ifThenFail(whens, error).result

/////////////////////////////////////////////////////////////////////////
//
// Array Functions

@export()
@description('[Array] | Define an when else statment')
func whenArr(when bool, then array) object => {
  when: when
  then: {
    result: then
  }
}

@export()
@description('[Array] | Define an when else statment')
func elseArr(then array) object => {
  default: true
  then: {
    result: then
  }
}

@export()
@description('[Array] | Define a set of conditions and results. No lazy evaluation!!!')
func ifThenArr(whens array) array => ifThen(whens).result

@export()
@description('[Array] | Define a set of conditions and results. No lazy evaluation!!!')
func ifThenFailArr(whens array, error string) array => ifThenFail(whens, error).result
