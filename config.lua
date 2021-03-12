return {
    -- be aware that each config should be followed by a comma

    -- the side length of the crossbreeding farm
    -- the recommend value is 9 because it's crop-matron's working area size.
    farmSize = 9,
    -- the side length of the new crop storage farm
    -- the recommend value is 13 because it's just enough to hold all the crops in GTNH
    storageFarmSize = 13, -- don't change

    -- below which percentage should the robot to charge itself.
    needChargeLevel = 0.2,

    -- the coordinate for charger
    chargerPos = {0, 0},
    -- the coordinate for the container contains crop sticks
    stickContainerPos = {0, 1},
    -- the coordinate for the container to store seeds, products, etc
    storagePos = {0, 2},
    -- the coordinate for the transvector dislocator
    dislocatorPos = {0, 3},
    -- the coordinate for the farmland that the dislocaotr is facing
    relayFarmlandPos = {0, 4},

    -- the slot for spade, count from 0, count from bottom-right to top-left
    spadeSlot = 0,
    -- the slot for binder for the transvector dislocator
    binderSlot = -1,
    -- the slot for crop sticks
    stickSlot = -2,
    -- to which slot should the robot stop storing items
    storageStopSlot = -3,

    -- flags

    -- if you turn on this flag, the robot will try to take care of the item drops
    -- from destroying crops, harvesting crops, destroying sticks, etc
    takeCareOfDrops = false,

    -- if you turn on this flag, you need to prepare a storage farm
    -- the recommend size is 13, which you change above.
    keepNewCropWhileMinMaxing = false,

    -- assume there is no bare stick in the farm, should increace speed.
    assumeNoBareStick = true,
}
