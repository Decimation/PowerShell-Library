/// ... somewhere in your cmdlet (might need to be PSCmdlet?)

private const BindingFlags BindingFlags = System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.Static | System.Reflection.BindingFlags.Public;
// provided you have a tasty function to reflect private fields/properties
protected object TryGetProperty(object instance, string fieldName) {
	// any access of a null object returns null. 
	if (instance == null || string.IsNullOrEmpty(fieldName)) {
		return null;
	}

	var propertyInfo = instance.GetType().GetProperty(fieldName, BindingFlags);

	if (propertyInfo != null) {
		try {
			return propertyInfo.GetValue(instance, null);
		}
		catch {
		}
	}

	// maybe it's a field
      var fieldInfo = instance.GetType().GetField(fieldName, BindingFlags);

      if (fieldInfo!= null) {
          try {
              return fieldInfo.GetValue(instance);
          } catch {
          }
      }

      // no match, return null.
      return null;
  }
  
  // you can create a property in your cmdlet:
   private Dictionary<string, object> UnboundArguments {
      get {
          var context = TryGetProperty(this, "Context");
          var processor = TryGetProperty(context, "CurrentCommandProcessor");
          var parameterBinder = TryGetProperty(processor, "CmdletParameterBinderController");
          var args = TryGetProperty(parameterBinder, "UnboundArguments") as IEnumerable;
          // args is reaaaaly deeep!

          var result = new Dictionary<string, object>(StringComparer.OrdinalIgnoreCase);
          if (args != null) {
              var currentParameterName = string.Empty;
              int i = 0;
              foreach (var arg in args) {
                  var isParameterName = TryGetProperty(arg, "ParameterNameSpecified");
                  if (isParameterName != null && true.Equals(isParameterName)) {
                      var parameterName = TryGetProperty(arg, "ParameterName");

                      if (parameterName != null) {
                          currentParameterName = parameterName.ToString();
                          
                          // add it now, just in case it's value isn't set (or it's a switch)
result.AddOrSet(currentParameterName, null);
continue;
}
}

// not a parameter name.
// treat as a value
var parameterValue = TryGetProperty(arg, "ArgumentValue");

if (string.IsNullOrEmpty(currentParameterName)) {
	result.Add("unbound_" + (i++), parameterValue);
} else {
	result[currentParameterName] = parameterValue;
}

// clear the current parameter name
currentParameterName = null;
}
              
}
return result;
}
}
  
// then, during dynamic parameter generation : 
  
public object GetDynamicParameters() {
	// ... bla bla ...
    
	// get the unbound parameters:
	var unbound = UnboundParameters;
    
	// now you can examine what the user specified 
	// and make better judgements of what parameters to emit.
	// in a nice clean dictionary.
	if ( unbound.containsKey("sample")) {
		// we know the user specified -sample 
		var sampleVal = unbound["sample"];
      
		// and we have it's value.
    }
    // ... bla-bla ...
    return dynamicParameterDictionary;
  }
  