import { ifThen, when } from '../module.bicep'
import { ifThenStr, whenStr, elseStr } from '../module.bicep'
import { ifThenInt, whenInt, elseInt } from '../module.bicep'

param sku string = 'S4'

output ifThenInt int = ifThenInt([
  whenInt(sku == 'S0', 10)
  whenInt(sku == 'S1', 20)
  whenInt(sku == 'S2', 50)
  whenInt(sku == 'S3', 100)
  whenInt(sku == 'S4', 200)
  whenInt(sku == 'S6', 400)
  whenInt(sku == 'S7', 800)
  whenInt(sku == 'S9', 1600)
  whenInt(sku == 'S12', 3000)
  elseInt(10)
])

output ifThenTest string = ifThenStr([
  whenStr(true, 'test2')

  whenStr(false, 'test2')

  elseStr('defaultString')
])

output ifThenTest2 object = ifThen([
  elseStr('defaultString')

  when(false && (2 > 1) && ('string' == 'string'), {
    test: 'test2'
    additional: 'complexCondition'
    details: {
      nestedKey: 'nestedValue'
      anotherKey: 123
    }
  })

  when((false && (3 == 3)) && (5 < 10), {
    test: 'test3'
    nested: {
      key: 'value'
      deepNested: {
        innerKey: 'innerValue'
      }
    }
  })

  when((false || false) && (length('string') > 3), {
    test: 'test5'
    complexArray: [
      {
        id: 1
        value: 'first'
      }
      {
        id: 2
        value: 'second'
      }
    ]
  })
])
