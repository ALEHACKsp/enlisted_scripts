local monetization = persist("monetization" , @() Watched(false))

local features = {
  monetization
}

console.register_command(
  @(name) name in features ? console_print($"{name} = {features[name].value}") : console_print($"FEATURE NOT EXIST {name}"),
  "feature.has")

console.register_command(
  function(name) {
    if (name not in features)
      return console_print($"FEATURE NOT EXIST {name}")
    local feature = features[name]
    feature(!feature.value)
    console_print($"Feature {name} changed to {feature.value}")
  }
  "feature.toggle")

return features 