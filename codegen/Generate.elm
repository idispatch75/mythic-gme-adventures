module Generate exposing (main)

import I18NextGen
import Gen.CodeGen.Generate as Generate
import Json.Decode exposing (Value)

main : Program Value () ()
main = 
  Generate.fromJson
    I18NextGen.flagsDecoder
    I18NextGen.files
