module RandomEvent exposing (RandomEventFocus(..), focusCodec, focusToString)

import Serialize


type RandomEventFocus
    = RemoteEvent
    | AmbiguousEvent
    | NewNpc
    | NpcEvent String String
    | ThreadEvent String String
    | PcEvent String (Maybe String)
    | CurrentContext


focusCodec : Serialize.Codec e RandomEventFocus
focusCodec =
    Serialize.customType
        (\remoteEventEncoder ambiguousEventEncoder newNpcEncoder npcEventEncoder threadEventEncoder pcEventEncoder currentContextEncoder value ->
            case value of
                RemoteEvent ->
                    remoteEventEncoder

                AmbiguousEvent ->
                    ambiguousEventEncoder

                NewNpc ->
                    newNpcEncoder

                NpcEvent name target ->
                    npcEventEncoder name target

                ThreadEvent name target ->
                    threadEventEncoder name target

                PcEvent name target ->
                    pcEventEncoder name target

                CurrentContext ->
                    currentContextEncoder
        )
        |> Serialize.variant0 RemoteEvent
        |> Serialize.variant0 AmbiguousEvent
        |> Serialize.variant0 NewNpc
        |> Serialize.variant2 NpcEvent Serialize.string Serialize.string
        |> Serialize.variant2 ThreadEvent Serialize.string Serialize.string
        |> Serialize.variant2 PcEvent Serialize.string (Serialize.maybe Serialize.string)
        |> Serialize.variant0 CurrentContext
        |> Serialize.finishCustomType


focusToString : RandomEventFocus -> String
focusToString focus =
    case focus of
        RemoteEvent ->
            "Remote Event"

        AmbiguousEvent ->
            "Ambiguous Event"

        NewNpc ->
            "New NPC"

        NpcEvent name _ ->
            name

        ThreadEvent name _ ->
            name

        PcEvent name _ ->
            name

        CurrentContext ->
            "Current Context"
