local { configs } = require("enlisted/enlist/configs/configs.nut")

return ::Computed(@() configs.value?.upgrades ?? {}) 