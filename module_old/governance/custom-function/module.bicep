type typeCheckValidation_Checks = {
  error: string
  when: bool
}[]

@export()
func checkValidations(checks typeCheckValidation_Checks) typeCheckValidation_Checks =>
  map(checks, check => check.when ? fail(check.error) : check)

//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
///////

@description('Adds an item to an array. If the item is empty, the array is returned as is.')
@export()
func AddItemToArray(items array, item object?) array => empty(item) ? items : concat(items, [item])

@description('Adds an item to an array. If the item is empty, the array is returned as is.')
@export()
func AddStringToArray(items array, item string?) array => empty(item) ? items : concat(items, [item])

@description('Get the distinct items of an array.')
@export()
func GetDistinct(items array) array => union(items, items)

@description('Get the segments of an ID.')
@export()
func GetSegmentFromId(id string?) {
  subscription: string
  resourceGroup: string
  provider: string
  service: string
  name: string
  id: string
} => {
  subscription: split(id ?? '/', '/')[?2] ?? ''
  resourceGroup: split(id ?? '/', '/')[?4] ?? ''
  provider: split(id ?? '/', '/')[?6] ?? ''
  service: '${split(id ?? '/', '/')[?6] ?? ''}/${split(id ?? '/', '/')[?7] ?? ''}'
  name: split(id ?? '/', '/')[?8] ?? ''
  id: id ?? ''
}

@description('Wraps each item into an object with an index for having indexs in lambdas-functions.')
@export()
func GetCustomIndexer(items array) array =>
  reduce(
    items,
    {
      acc: 0
      result: []
    },
    (acc, item) =>
      ({
        // This keeps track of the index and increments it for the next iteration.
        acc: acc.acc + 1
        // Append the item to the result array.
        result: concat(acc.result, [
          {
            index: acc.acc
            value: any(item)
          }
        ])
      })
  ).result

@description('Wraps each item into an object with an index for having indexs in lambdas-functions.')
@export()
func GetObjectCustomIndexer(items object) array =>
  reduce(
    map(sys.objectKeys(items), key => {
      key: key
      acc: 0
      result: []
    }),
    {
      acc: 0
      result: []
    },
    (acc, item) =>
      ({
        // This keeps track of the index and increments it for the next iteration.
        acc: acc.acc + 1
        // Append the item to the result array.
        result: [
          concat(acc.result, [
            {
              index: int(acc.acc)
              key: item.key
              value: any(items[item.key])
            }
          ])
        ]
      })
  ).result
