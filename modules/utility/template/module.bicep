targetScope = 'resourceGroup'

@export()
@description('Replaces \${{ parameters.<name> }} and returns a bicep-object.')
func jsonTemplate(json string, parameters object) object => sys.json(jsonTemplateString(json, parameters))

@export()
@description('''
Use replaceParams(json, parameters) to get a bicep-object!

This only returns the json-string with the parameters replaced!
Replaces \${{ parameters.<name> }} with the value of the parameter in the json string.
''')
func jsonTemplateString(data string, parameters object) string =>
  join(
    map(
      //
      //
      // split the data into segments based on the parameter syntax.
      split(replace(data, '\${{', '~\$\${{'), '~\$'),
      segment => hasParam(segment) ? replaceParamOnLine(segment, parameters, getParamDefinition(segment)) : segment
    ),
    ''
  )

//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////

@description('''
Retrives the name and fallback value of a parameter definition
''')
func getParamDefinition(line string) {
  full: string
  name: string
  fallback: string
} => {
  full: getFullParam(line)

  // Split into parameter name and fallback value.
  // This is to support the syntax: ${{ parameters.<name> || <fallback_value> }}
  name: trim(split(getCleanedParam(line), '||')[0])
  fallback: trim(split(getCleanedParam(line), '||')[?1] ?? '')
}

@description('''
Return only the ${{ parameters.<name> || <fallback> }} part of a line of string.
It expects only one parameter per line. Split the line accordingly.
''')
func getFullParam(line string) string =>
  substring(
    line,
    indexOf(line, '\${{'),
    indexOf(line, '}}') - indexOf(line, '\${{') + 2 // + 2 for the opening }}
  )

@description('''
Returns the <name> || <fallback> part of the ${{ parameters.<name> || <fallback> }} definition.
It expects only one parameter per line. Split the line accordingly.
''')
func getCleanedParam(line string) string =>
  trim(replace(replace(replace(getFullParam(line), 'parameters.', ''), '\${{', ''), '}}', ''))

@description('''
Checks if the line contains a parameter definition.
''')
func hasParam(line string) bool => contains(line, '\${{') && contains(line, 'parameters.') && contains(line, '}}')

//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////

@description('''
Replaces \${{ parameters.<name> || <fallback> }} with the value of the parameter in the line.
Only call this function if the line actually contains a parameter, else it will fail.
''')
func replaceParamOnLine(
  line string,
  paramRef object,
  paramDef {
    full: string
    name: string
    fallback: string?
  }
) string =>
  replace(
    line,
    paramDef.full,
    concat(
      // Try using the parameter value from the parameter object.
      filter([paramRef[?paramDef.name]], arg => !empty(arg)),

      // Fallback to the fallback value if the parameter is not found in the parameter object.
      filter([paramDef.?fallback], arg => !empty(arg))
    )[?0] ?? fail('Could not find parameter value for ${paramDef.full}')
  )
