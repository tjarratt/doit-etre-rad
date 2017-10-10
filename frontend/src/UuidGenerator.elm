module UuidGenerator exposing (next)

import Random.Pcg exposing (Seed, initialSeed, step)
import Uuid exposing (uuidGenerator)


type alias ExposingSeed =
    { currentSeed : Seed }


next : Seed -> ( Uuid.Uuid, Seed )
next seed =
    Random.Pcg.step uuidGenerator seed
