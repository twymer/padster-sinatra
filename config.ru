require './padster'
require './middlewares/pad_backend'

use Padster::PadBackend

run Padster::App
