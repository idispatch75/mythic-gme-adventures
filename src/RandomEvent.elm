module RandomEvent exposing (RandomEventFocus(..), focusCodec, focusToString)

import Serialize


type RandomEventFocus
    = RemoteEvent
    | AmbiguousEvent
    | NewNpc
    | NpcAction String
    | NpcNegative String
    | NpcPositive String
    | MoveTowardThread String
    | MoveAwayFromThread String
    | CloseThread String
    | PcNegative (Maybe String)
    | PcPositive (Maybe String)
    | CurrentContext


focusCodec : Serialize.Codec e RandomEventFocus
focusCodec =
    Serialize.customType
        (\remoteEventEncoder ambiguousEventEncoder newNpcEncoder npcActionEncoder npcNegativeActionEncoder npcPositiveActionEncoder moveTowardThreadEncoder moveAwayFromThreadEncoder closeThreadEncoder pcNegativeEncoder pcPositiveEncoder currentContextEncoder value ->
            case value of
                RemoteEvent ->
                    remoteEventEncoder

                AmbiguousEvent ->
                    ambiguousEventEncoder

                NewNpc ->
                    newNpcEncoder

                NpcAction item ->
                    npcActionEncoder item

                NpcNegative item ->
                    npcNegativeActionEncoder item

                NpcPositive item ->
                    npcPositiveActionEncoder item

                MoveTowardThread item ->
                    moveTowardThreadEncoder item

                MoveAwayFromThread item ->
                    moveAwayFromThreadEncoder item

                CloseThread item ->
                    closeThreadEncoder item

                PcNegative item ->
                    pcNegativeEncoder item

                PcPositive item ->
                    pcPositiveEncoder item

                CurrentContext ->
                    currentContextEncoder
        )
        |> Serialize.variant0 RemoteEvent
        |> Serialize.variant0 AmbiguousEvent
        |> Serialize.variant0 NewNpc
        |> Serialize.variant1 NpcAction Serialize.string
        |> Serialize.variant1 NpcNegative Serialize.string
        |> Serialize.variant1 NpcPositive Serialize.string
        |> Serialize.variant1 MoveTowardThread Serialize.string
        |> Serialize.variant1 MoveAwayFromThread Serialize.string
        |> Serialize.variant1 CloseThread Serialize.string
        |> Serialize.variant1 PcNegative (Serialize.maybe Serialize.string)
        |> Serialize.variant1 PcPositive (Serialize.maybe Serialize.string)
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

        NpcAction _ ->
            "NPC Action"

        NpcNegative _ ->
            "NPC Negative"

        NpcPositive _ ->
            "NPC Positive"

        MoveTowardThread _ ->
            "Move toward a Thread"

        MoveAwayFromThread _ ->
            "Move away from a Thread"

        CloseThread _ ->
            "Close a Thread"

        PcNegative _ ->
            "PC Negative"

        PcPositive _ ->
            "PC Positive"

        CurrentContext ->
            "Current Context"
