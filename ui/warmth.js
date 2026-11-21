.pragma library

function rgb(kelvin) {
  var t = Math.max(1000, Math.min(40000, kelvin)) / 100
  var r, g, b
  if (t <= 66) {
    r = 255
    g = 99.4708025861 * Math.log(t) - 161.1195681661
  } else {
    r = 329.698727446 * Math.pow(t - 60, -0.1332047592)
    g = 288.1221695283 * Math.pow(t - 60, -0.0755148492)
  }
  if (t >= 66) b = 255
  else if (t <= 19) b = 0
  else b = 138.5177312231 * Math.log(t - 10) - 305.0447927307
  function c(v) { return Math.max(0, Math.min(255, v)) / 255 }
  return { r: c(r), g: c(g), b: c(b) }
}

function name(kelvin) {
  if (kelvin <= 2500) return "Candlelight"
  if (kelvin <= 3200) return "Very warm"
  if (kelvin <= 4000) return "Warm"
  if (kelvin <= 5000) return "Soft"
  if (kelvin <= 5800) return "Neutral"
  return "Daylight"
}

function minutes(hhmm) {
  var parts = String(hhmm || "0:0").split(":")
  return (parseInt(parts[0], 10) || 0) * 60 + (parseInt(parts[1], 10) || 0)
}

function clock(mins) {
  var m = ((mins % 1440) + 1440) % 1440
  var h = Math.floor(m / 60)
  var mm = m % 60
  return (h < 10 ? "0" : "") + h + ":" + (mm < 10 ? "0" : "") + mm
}
