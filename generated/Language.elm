module Language exposing (..)

{-| 
-}


import I18Next


defaultLanguage : I18Next.Translations
defaultLanguage =
    I18Next.fromTree
        [ ( ""
          , I18Next.object
                [ ( "general greeting", I18Next.string "Hello there" )
                , ( "personal greeting", I18Next.string "Hello" )
                ]
          )
        ]


