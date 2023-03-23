module Translations exposing (..)

{-| 
-}


import I18Next


generalGreeting : List I18Next.Translations -> String
generalGreeting translations =
    I18Next.tf translations "general greeting"


personalGreeting : List I18Next.Translations -> String
personalGreeting translations =
    I18Next.tf translations "personal greeting"


