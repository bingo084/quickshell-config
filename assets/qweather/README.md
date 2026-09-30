# QWeather Icons

Version: 1.8.0

Source: https://github.com/qwd/Icons

Website: https://icons.qweather.com/

Imported from QWeather-Icons-1.8.0.zip. These unmodified SVGs include regular
and fill variants for all 54 current weather condition codes, including
999 (unknown):
https://dev.qweather.com/docs/api/weather/weather-conditions/

Fonts, night variants, moon phases and warning icons are not included.
See LICENSE for the upstream MIT license.

The weather widget uses the fill variants, falling back to 999-fill.svg for
unknown codes. Regular variants are retained for visual comparison.

Offsets.js provides per-icon optical alignment for the fill variants. Offsets
are calculated offline at 256px, starting with the visible bounding-box center
and moving 25% toward the alpha-weighted center of mass. Visible bounds use
pixels with at least 50% opacity. This keeps thin rain drops, rays and other
details from being ignored when balancing a heavy filled shape. Offsets are
expressed in a 16px box and rounded to quarter pixels; the widget scales them
with the display size. The 25% weighting is a conservative heuristic and still
needs visual review. The upstream SVG artwork is unchanged.

To regenerate after replacing the SVGs, run `bash scripts/qweather-icon-offsets.sh`
from the project root and use its output for Offsets.js. The script requires
rsvg-convert, ImageMagick and Node.js; these are not runtime dependencies.
