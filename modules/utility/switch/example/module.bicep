import { switch, case, default } from '../module.bicep'
import { switchStr, caseStr, defaultStr } from '../module.bicep'
import { switchInt, caseInt, defaultInt, switchFlag } from '../module.bicep'

param sku string = 's4'

output switchInt int = switchInt(sku, [
  caseInt('S0', 10)
  caseInt('S1', 20)
  caseInt('S2', 50)
  caseInt('S3', 100)
  caseInt('S4', 200)
  caseInt('S6', 400)
  caseInt('S7', 800)
  caseInt('S9', 1600)
  caseInt('S12', 3000)
  defaultInt(999)
])
output switchInt2 int = switchInt(sku, [
  switchFlag('caseSensitive')
  switchFlag('ignoreWhitespace')

  caseInt('S0', 10)
  caseInt('S1', 20)
  caseInt('S2', 50)
  caseInt('S3', 100)
  caseInt('S4', 200)
  caseInt('  s  4', 250)
  caseInt('S6', 400)
  caseInt('S7', 800)
  caseInt('S9', 1600)
  caseInt('S12', 3000)
  defaultInt(1000000)
])

output switchWithFlags string = switchStr(sku, [
  switchFlag('startsWith')
  switchFlag('ignoreWhitespace')

  caseStr('  s  ', 'Starts with s (ignoring whitespace)')
  defaultStr('No match')
])

output switchTest string = switchStr(sku, [
  caseStr('S0', 'test0')
  caseStr('S4', 'test4')
  defaultStr('defaultString')
])

output switchTest2 object = switch(sku, [
  defaultStr('test0')

  case('S3', {
    test: 'test3'
    nested: {
      key: 'value'
      deepNested: {
        innerKey: 'innerValue'
      }
    }
  })
  case('S5', {
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
  case('S7', {
    test: 'test2'
    additional: 'complexCondition'
    details: {
      nestedKey: 'nestedValue'
      anotherKey: 123
    }
  })
])
