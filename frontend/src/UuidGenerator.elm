module UuidGenerator exposing (next)

import Random.Pcg
import Uuid exposing (uuidGenerator)


type alias ExposingSeed =
    { currentSeed : Random.Pcg.Seed }


next : Random.Pcg.Seed -> ( Uuid.Uuid, Random.Pcg.Seed )
next seed =
    Random.Pcg.step uuidGenerator seed
