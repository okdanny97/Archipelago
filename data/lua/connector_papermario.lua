
local socket = require("socket")
local json = require("json")

local STATE_NOT_CONNECTED = 0
local STATE_CONNECTED = 1

local CURRENT_PLAYER_DATA = 0x8010F290 -- System Bus
local BOOTS_LEVEL_OFFSET = 0x0
local HAMMER_LEVEL_OFFSET = 0x1
local COINS_OFFSET = 0xC
local STAR_PIECES_OFFSET = 0xF
local PARTNERS_OFFSET = 0x14


local PARTNER_NONE = 0x0
local PARTNER_GOOMBARIO = 0x1
local PARTNER KOOPER = 0x2
local PARTNER_BOMBETTE = 0x3
local PARTNER_PARAKARRY = 0x4
local PARTNER_GOOMPA = 0x5
local PARTNER_WATT = 0x6
local PARTNER_SUSHIE = 0x7
local PARTNER_LAKILESTER = 0x8
local PARTNER_BOW = 0x9
local PARTNER_GOOMBARIA = 0xA
local PARTNER_TWINK = 0xB

local PARTNER_LEVEL_OFFSET = 0x1
local PARTNER_UNLOCKED_OFFSET = 0x2
local SIZEOF_PARTNER_STRUCT = 0x8

local BADGE_INVENTORY =    0x10F344 -- RDRAM
-- local ITEM_INVENTORY  =    0x10F456 -- RDRAM
local ITEM_INVENTORY  =    0x10F444 -- RDRAM
local KEY_ITEM_INVENTORY = 0x356E04 -- RDRAM
local ITEM_NONE = 0x0


local SAVE_DATA  <const> = 0x0DACC0; -- RDRAM
local GAME_FLAGS <const> = SAVE_DATA + 0xFB0; -- RDRAM

local nodes = {
	['MAC_00/ShopItemA'] = nil,
	['MAC_00/ShopItemB'] = nil,
	['MAC_00/ShopItemC'] = nil,
	['MAC_00/ShopItemD'] = nil,
	['MAC_00/ShopItemE'] = nil,
	['MAC_00/ShopItemF'] = nil,
	['MAC_01/ShopBadgeA'] = 0x680,
	['MAC_01/ShopBadgeB'] = 0x681,
	['MAC_01/ShopBadgeC'] = 0x682,
	['MAC_01/ShopBadgeD'] = 0x683,
	['MAC_01/ShopBadgeE'] = 0x684,
	['MAC_01/ShopBadgeF'] = 0x685,
	['MAC_01/ShopBadgeG'] = 0x686,
	['MAC_01/ShopBadgeH'] = 0x687,
	['MAC_01/ShopBadgeI'] = 0x688,
	['MAC_01/ShopBadgeJ'] = 0x689,
	['MAC_01/ShopBadgeK'] = 0x68A,
	['MAC_01/ShopBadgeL'] = 0x68B,
	['MAC_01/ShopBadgeM'] = 0x68C,
	['MAC_01/ShopBadgeN'] = 0x68D,
	['MAC_01/ShopBadgeO'] = 0x68E,
	['MAC_01/ShopBadgeP'] = 0x68F,
	['MAC_04/ShopItemA'] = nil,
	['MAC_04/ShopItemB'] = nil,
	['MAC_04/ShopItemC'] = nil,
	['MAC_04/ShopItemD'] = nil,
	['MAC_04/ShopItemE'] = nil,
	['MAC_04/ShopItemF'] = nil,
	['HOS_03/ShopItemA'] = nil,
	['HOS_03/ShopItemB'] = nil,
	['HOS_03/ShopItemC'] = nil,
	['HOS_03/ShopItemD'] = nil,
	['HOS_03/ShopItemE'] = nil,
	['HOS_03/ShopItemF'] = nil,
	['HOS_06/ShopBadgeA'] = nil,
	['HOS_06/ShopBadgeB'] = nil,
	['HOS_06/ShopBadgeC'] = nil,
	['HOS_06/ShopBadgeD'] = nil,
	['HOS_06/ShopBadgeE'] = nil,
	['HOS_06/ShopBadgeF'] = nil,
	['HOS_06/ShopBadgeG'] = nil,
	['HOS_06/ShopBadgeH'] = nil,
	['HOS_06/ShopBadgeI'] = nil,
	['HOS_06/ShopBadgeJ'] = nil,
	['HOS_06/ShopBadgeK'] = nil,
	['HOS_06/ShopBadgeL'] = nil,
	['HOS_06/ShopBadgeM'] = nil,
	['HOS_06/ShopBadgeN'] = nil,
	['HOS_06/ShopBadgeO'] = nil,
	['HOS_06/ShopRewardA'] = nil,
	['HOS_06/ShopRewardB'] = nil,
	['HOS_06/ShopRewardC'] = nil,
	['HOS_06/ShopRewardD'] = nil,
	['HOS_06/ShopRewardE'] = nil,
	['HOS_06/ShopRewardF'] = nil,
	['NOK_01/ShopItemA'] = nil,
	['NOK_01/ShopItemB'] = nil,
	['NOK_01/ShopItemC'] = nil,
	['NOK_01/ShopItemD'] = nil,
	['NOK_01/ShopItemE'] = nil,
	['NOK_01/ShopItemF'] = nil,
	['DRO_01/ShopItemA'] = nil,
	['DRO_01/ShopItemC'] = nil,
	['DRO_01/ShopItemF'] = nil,
	['OBK_03/ShopItemA'] = nil,
	['OBK_03/ShopItemB'] = nil,
	['OBK_03/ShopItemC'] = nil,
	['OBK_03/ShopItemD'] = nil,
	['OBK_03/ShopItemE'] = nil,
	['OBK_03/ShopItemF'] = nil,
	['JAN_03/ShopItemA'] = nil,
	['JAN_03/ShopItemB'] = nil,
	['JAN_03/ShopItemC'] = nil,
	['JAN_03/ShopItemD'] = nil,
	['JAN_03/ShopItemE'] = nil,
	['JAN_03/ShopItemF'] = nil,
	['SAM_02/ShopItemA'] = nil,
	['SAM_02/ShopItemB'] = nil,
	['SAM_02/ShopItemC'] = nil,
	['SAM_02/ShopItemD'] = nil,
	['SAM_02/ShopItemE'] = nil,
	['SAM_02/ShopItemF'] = nil,
	['KPA_96/ShopItemA'] = nil,
	['KPA_96/ShopItemB'] = nil,
	['KPA_96/ShopItemC'] = nil,
	['KPA_96/ShopItemD'] = nil,
	['KPA_96/ShopItemE'] = nil,
	['KPA_96/ShopItemF'] = nil,
	['KMR_00/HiddenPanel'] = 0x056,
	['KMR_03/HiddenPanel'] = 0x058,
	['KMR_11/HiddenPanel'] = 0x05A,
	['MAC_00/HiddenPanel'] = 0x127,
	['MAC_02/HiddenPanel'] = 0x129,
	['MAC_03/HiddenPanel'] = 0x12A,
	['MAC_05/HiddenPanel'] = 0x12C,
	['HOS_00/HiddenPanel'] = 0x21A,
	['HOS_01/HiddenPanel'] = 0x21B,
	['HOS_06/HiddenPanel'] = 0x21C,
	['NOK_01/HiddenPanel'] = 0x25E,
	['NOK_13/HiddenPanel'] = 0x260,
	['NOK_14/HiddenPanel'] = 0x261,
	['IWA_01/HiddenPanel'] = 0x2CD,
	['DRO_02/HiddenPanel'] = 0x2F4,
	['SBK_33/HiddenPanel'] = 0x31C,
	['MIM_12/HiddenPanel'] = 0x3A5,
	['OBK_01/HiddenPanel'] = 0x3C1,
	['OBK_02/HiddenPanel'] = 0x3C4,
	['OBK_04/HiddenPanel'] = 0x3CC,
	['OBK_08/HiddenPanel'] = 0x3D4,
	['OMO_03/HiddenPanel'] = 0x4A6,
	['OMO_06/HiddenPanel'] = 0x4A7,
	['OMO_08/HiddenPanel'] = 0x4A8,
	['OMO_10/HiddenPanel'] = 0x4A9,
	['JAN_02/HiddenPanel'] = 0x4F5,
	['JAN_15/HiddenPanel'] = 0x4F6,
	['KZN_09/HiddenPanel'] = 0x53A,
	['KZN_18/HiddenPanel'] = 0x53B,
	['FLO_03/HiddenPanel'] = 0x57C,
	['FLO_24/HiddenPanel'] = 0x57E,
	['FLO_25/HiddenPanel'] = 0x57F,
	['SAM_01/HiddenPanel'] = 0x59C,
	['SAM_04/HiddenPanel'] = 0x5A5,
	['PRA_21/HiddenPanel'] = 0x5E6,
	['PRA_22/HiddenPanel'] = 0x5E8,
	['KMR_02/GiftA'] = 0x064, -- Koot: The Tape
	['KMR_02/GiftB'] = nil, -- Power Jump
	['KMR_02/GiftC'] = nil, -- Star Piece 44
	['KMR_02/GiftD'] = nil, -- Star Piece 4A
	['KMR_02/GiftE'] = nil, -- Letter 13
	['KMR_02/GiftF'] = nil, -- Lucky Day
	['KMR_02/ItemA'] = 0x02E,
	['KMR_02/Tree1_Drop1A'] = 0x030,
	['KMR_02/Partner'] = nil, -- Goombario
	['KMR_02/Bush2_Drop1'] = 0x02F,
	['KMR_03/HiddenYBlockA'] = 0x034,
	['KMR_03/YBlockA'] = 0x032,
	['KMR_03/ItemA'] = 0x038,
	['KMR_03/ItemB'] = 0x039,
	['KMR_03/ItemC'] = 0x03A,
	['KMR_03/ItemD'] = 0x03B,
	['KMR_03/ItemE'] = nil, -- Fire Flower - suspect 0x031
	['KMR_03/Tree1_Drop1A'] = 0x035,
	['KMR_04/Tree3_Drop1A'] = 0x01E, -- Dolly
	['KMR_04/Bush7_Drop1'] = nil, -- Hammer 1 Proxy
	['KMR_04/Bush1_Drop1'] = 0x03E,
	['KMR_04/Bush2_Drop1'] = 0x03F,
	['KMR_04/Bush3_Drop1A'] = 0x040,
	['KMR_04/Bush3_Drop1B'] = 0x041,
	['KMR_04/Bush4_Drop1'] = 0x042,
	['KMR_04/Bush5_Drop1'] = 0x043,
	['KMR_04/Tree1_Drop1'] = 0x03C,
	['KMR_04/Tree2_Drop1'] = 0x03D,
	['KMR_04/RandomBlockItemA'] = 0x046,
	['KMR_05/ItemA'] = 0x04A,
	['KMR_05/Tree1_Drop1A'] = 0x049,
	['KMR_06/RBlockA'] = 0x050,
	['KMR_06/ItemA'] = 0x04F,
	['KMR_09/YBlockA'] = 0x04D,
	['KMR_09/YBlockB'] = 0x04E,
	['KMR_10/ChestA'] = 0x054,
	['KMR_10/YBlockA'] = 0x055,
	['KMR_11/YBlockA'] = 0x051,
	['KMR_11/Tree1_Drop1A'] = 0x052,
	['KMR_11/Tree2_Drop1'] = 0x053,
	['KMR_20/GiftA'] = 0x063,
	['MAC_00/ItemA'] = 0x12D,
	['MAC_00/GiftA'] = 0x0F4, -- Star Piece for returning Dictionary CONFIRM
	['MAC_00/GiftB'] = nil, -- Star Piece for giving Russ T Letter
	['MAC_00/GiftC'] = nil, -- Letter 19 From Miss T
	['MAC_00/GiftD'] = nil, -- Trading event toad first contest
	['MAC_00/DojoA'] = nil, -- First Degree Card
	['MAC_00/DojoB'] = nil, -- Second Degree Card
	['MAC_00/DojoC'] = nil, -- Third Degree Card
	['MAC_00/DojoD'] = nil, -- Fouth Degree Card
	['MAC_00/DojoE'] = nil, -- Diploma
	['MAC_01/ItemA'] = 0x0FF,
	['MAC_01/GiftA'] = 0x102,
	['MAC_01/GiftB'] = nil, -- Star Piece After giving letter to one of Minh T, Merlon, Postmaster
	['MAC_01/GiftC'] = nil, -- Star Piece After giving letter to one of Minh T, Merlon, Postmaster
	['MAC_01/GiftD'] = nil, -- Star Piece After giving letter to one of Minh T, Merlon, Postmaster
	['MAC_01/Tree1_Drop1A'] = 0x12E,
	['MAC_02/ItemA'] = 0x084,
	['MAC_02/GiftA'] = 0x11B, -- Magical Seed 1
	['MAC_02/GiftB'] = 0x119, -- Cake After Giving Tayce T Frying Pan CONFIRM
	['MAC_02/GiftC'] = nil, -- Star Piece afte giving letter to Fice T
	['MAC_02/GiftD'] = nil, -- Forest Pass
	['MAC_03/GiftA'] = nil, -- Letter 1 from Dane T
	['MAC_03/GiftB'] = nil, -- Letter 2 From Dane T
	['MAC_04/ItemA'] = 0x12F,
	['MAC_04/ItemB'] = 0x130,
	['MAC_04/ItemC'] = 0x121,
	['MAC_04/ItemD'] = 0x131,
	['MAC_05/GiftA'] = 0x125, -- Get Lyrics
	['MAC_05/GiftB'] = 0x126, -- Finish Pop Diva Quest CONFIRM
	['MAC_05/GiftC'] = nil, -- Letter from Fishmael
	['MAC_05/GiftD'] = nil, -- Trading event toad 3rd contest
	['MAC_05/RandomBlockItemA'] = 0x132,
	['TIK_02/ChestA'] = 0x18F,
	['TIK_03/YBlockA'] = 0x190,
	['TIK_03/YBlockB'] = 0x191,
	['TIK_03/YBlockC'] = 0x192,
	['TIK_05/ChestA'] = 0x193,
	['TIK_07/ItemA'] = 0x194,
	['TIK_07/RandomBlockItemA'] = 0x1B1, -- TIK07_SuperBlock
	['TIK_10/HiddenYBlockA'] = 0x195,
	['TIK_10/HiddenYBlockB'] = 0x196,
	['TIK_10/HiddenYBlockC'] = 0x197,
	['TIK_10/RandomBlockItemA'] = 0x1B2, -- TIK10_SuperBlock
	['TIK_12/RandomBlockItemA'] = 0x1B3, -- Mislabeled as TIK02_SuperBlock
	['TIK_15/GiftA'] = nil, -- Rip Cheato
	['TIK_15/GiftB'] = nil, -- Rip Cheato
	['TIK_15/GiftC'] = nil, -- Rip Cheato
	['TIK_15/GiftD'] = nil, -- Rip Cheato
	['TIK_15/GiftE'] = nil, -- Rip Cheato
	['TIK_15/GiftF'] = nil, -- Rip Cheato
	['TIK_15/GiftG'] = nil, -- Rip Cheato
	['TIK_15/GiftH'] = nil, -- Rip Cheato
	['TIK_15/GiftI'] = nil, -- Rip Cheato
	['TIK_15/GiftJ'] = nil, -- Rip Cheato
	['TIK_15/GiftK'] = nil, -- Rip Cheato
	['TIK_17/RandomBlockItemA'] = 0x1B4, -- TIK17_SuperBlock
	['TIK_18/HiddenYBlockA'] = 0x198,
	['TIK_18/RandomBlockItemA'] = 0x199,
	['TIK_19/RandomBlockItemA'] = 0x1B5, -- TIK19_SuperBlock
	['TIK_20/YBlockA'] = 0x19A,
	['TIK_21/YBlockA'] = 0x19B,
	['TIK_21/YBlockB'] = 0x19C,
	['TIK_21/YBlockC'] = 0x19D,
	['TIK_21/YBlockD'] = 0x19E,
	['TIK_21/YBlockE'] = 0x19F,
	['TIK_23/HiddenYBlockA'] = 0x1A0,
	['TIK_23/HiddenYBlockB'] = 0x1A1,
	['TIK_23/HiddenYBlockC'] = 0x1A2,
	['TIK_23/YBlockA'] = 0x1A3,
	['TIK_24/HiddenYBlockA'] = 0x1A4,
	['TIK_24/YBlockA'] = 0x1A5,
	['TIK_24/YBlockB'] = 0x1A6,
	['TIK_25/BigChest'] = 0x1A7,
	['KKJ_16/ItemA'] = 0x1F8,
	['KKJ_16/ItemB'] = 0x1E4,
	['KKJ_17/ItemA'] = 0x1E6,
	['KKJ_20/ChestA'] = 0x1E7,
	['HOS_01/ItemA'] = 0x220,
	['HOS_06/GiftA'] = 0x219,
	['HOS_06/GiftB'] = nil, -- starpiece from merlow after letter from snowfield
	['NOK_01/Bush1_Drop1A'] = 0x24C,
	['NOK_01/Bush3_Drop1A'] = 0x24D,
	['NOK_01/Bush4_Drop1A'] = 0x24E,
	['NOK_01/Bush5_Drop1A'] = 0x24F,
	['NOK_01/Bush6A_Drop1A'] = 0x263,
	['NOK_01/Bush7A_Drop1A'] = 0x264,
	['NOK_01/GiftA'] = nil, -- Given by Mort T for letter
	['NOK_01/GiftB'] = nil, -- Letter from Koover 1
	['NOK_01/GiftC'] = nil, -- Letter from Koover 2
	['NOK_02/ItemA'] = 0x243,
	['NOK_02/GiftA'] = 0x265, -- Koot: Koopa Legends
	['NOK_02/GiftB'] = 0x6B0, -- Silver Credit: Koot Reward after second favor
	['NOK_02/GiftC'] = 0x6C8, -- Gold Credit: Koot Reward after tenth favor
	['NOK_02/GiftD'] = nil, -- Star Piece?
	['NOK_02/GiftE'] = nil, -- Star Piece?
	['NOK_02/Bush1_Drop1'] = 0x250,
	['NOK_02/Partner'] = nil, -- Kooper
	['NOK_02/KootGift00'] = 0x6AD, -- Favor 00 Complete
	['NOK_02/KootGift01'] = 0x6B0, -- Favor 01 Complete - Received With GiftB
	['NOK_02/KootGift02'] = 0x6B3, -- Favor 02 Complete
	['NOK_02/KootGift03'] = 0x6B6, -- Favor 03 Complete
	['NOK_02/KootGift04'] = 0x6B9, -- Favor 04 Complete
	['NOK_02/KootGift05'] = 0x6BC, -- Favor 05 Complete
	['NOK_02/KootGift06'] = 0x6BF, -- Favor 06 Complete
	['NOK_02/KootGift07'] = 0x6C2, -- Favor 07 Complete
	['NOK_02/KootGift08'] = 0x6C5, -- Favor 08 Complete
	['NOK_02/KootGift09'] = 0x6C8, -- Favor 09 Complete - Received With GiftC
	['NOK_02/KootGift0A'] = 0x6CB, -- Favor 0A Complete
	['NOK_02/KootGift0B'] = 0x6CE, -- Favor 0B Complete
	['NOK_02/KootGift0C'] = 0x6D1, -- Favor 0C Complete
	['NOK_02/KootGift0D'] = 0x6D4, -- Favor 0D Complete
	['NOK_02/KootGift0E'] = 0x6D7, -- Favor 0E Complete
	['NOK_02/KootGift0F'] = 0x6DA, -- Favor 0F Complete
	['NOK_02/KootGift10'] = 0x6DD, -- Favor 10 Complete
	['NOK_02/KootGift11'] = 0x6E0, -- Favor 11 Complete
	['NOK_02/KootGift12'] = 0x6E3, -- Favor 12 Complete
	['NOK_02/KootGift13'] = 0x6E6, -- Favor 13 Complete
	['NOK_02/Bush6_Drop1'] = nil, -- Coin
	['NOK_03/ItemA'] = 0x242,
	['NOK_04/GiftA'] = nil, -- Fuzzy Forest - Kooper Shell?
	['NOK_11/YBlockA'] = 0x252,
	['NOK_11/RBlockA'] = 0x253,
	['NOK_11/YBlockB'] = 0x254,
	['NOK_12/YBlockA'] = 0x255,
	['NOK_12/ItemA'] = 0x244,
	['NOK_12/ItemB'] = 0x267,
	['NOK_12/RandomBlockItemA'] = 0x258,
	['NOK_13/RBlockA'] = 0x256,
	['NOK_13/ItemA'] = 0x268,
	['NOK_14/ItemA'] = 0x246,
	['NOK_14/ItemB'] = 0x247,
	['NOK_14/ItemC'] = 0x248,
	['NOK_14/ItemD'] = 0x249,
	['NOK_14/ItemE'] = 0x24A,
	['NOK_14/ItemF'] = 0x245,
	['NOK_14/HiddenYBlockA'] = 0x257,
	['NOK_15/Tree1_Drop1A'] = 0x251,
	['TRD_00/ChestA'] = 0x281,
	['TRD_00/ChestB'] = 0x282,
	['TRD_01/ItemA'] = 0x27E,
	['TRD_01/ItemB'] = 0x285,
	['TRD_03/ItemA'] = 0x286,
	['TRD_03/ItemB'] = 0x287,
	['TRD_03/ItemC'] = 0x27F,
	['TRD_06/Partner'] = nil, -- Bombette
	['TRD_08/ItemA'] = 0x288,
	['TRD_09/YBlockA'] = 0x280,
	['IWA_00/ItemA'] = 0x2B3,
	['IWA_00/ItemB'] = 0x2B4,
	['IWA_00/ItemC'] = 0x2B5,
	['IWA_00/YBlockA'] = 0x2CB,
	['IWA_00/ItemD'] = nil, -- Whacka's Bump
	['IWA_01/ItemA'] = 0x2AE,
	['IWA_01/ItemB'] = 0x2C1,
	['IWA_02/ItemA'] = 0x2AF,
	['IWA_02/GiftA'] = 0x2CC, -- Magical Seed 2
	['IWA_03/ChestA'] = 0x2B1,
	['IWA_03/YBlockA'] = 0x2BE,
	['IWA_03/YBlockB'] = 0x2BF,
	['IWA_03/YBlockC'] = 0x2C0,
	['IWA_03/ItemA'] = 0x2C2,
	['IWA_03/ItemB'] = 0x2B0,
	['IWA_03/ItemC'] = 0x2B6,
	['IWA_03/ItemD'] = 0x2B7,
	['IWA_03/ItemE'] = 0x2B8,
	['IWA_03/ItemF'] = 0x2B9,
	['IWA_03/ItemG'] = 0x2BA,
	['IWA_03/ItemH'] = 0x2BB,
	['IWA_03/ItemI'] = 0x2BC,
	['IWA_03/ItemJ'] = 0x2BD,
	['IWA_04/ItemA'] = 0x2C3,
	['IWA_10/Bush1_Drop1'] = 0x2C5,
	['IWA_10/Bush2_Drop1'] = 0x2C6,
	['IWA_10/Bush3_Drop1'] = 0x2C7,
	['IWA_10/Bush4_Drop1'] = nil, -- Egg
	['IWA_10/Partner'] = nil, -- Parakarry
	['IWA_10/RandomBlockItemA'] = 0x2D1, -- IWA10_SuperBlock
	['DRO_01/GiftA'] = 0x2F2,
	['DRO_01/GiftB'] = 0x2F6,
	['DRO_01/GiftC'] = nil, -- Letter 12 from Little Mouser to Franky
	['DRO_01/Tree1_Drop1'] = 0x2F8,
	['DRO_02/ItemA'] = 0x2F5,
	['DRO_02/GiftA'] = 0x2F7, -- Decompilation marks this as DRO_01
	['DRO_02/GiftB'] = nil, -- Pulse Stone From Moustafa - Potentiall 0x2EF
	['DRO_02/GiftC'] = nil, -- Letter 18 from Mr E to Miss T
	['SBK_00/YBlockA'] = 0x31D,
	['SBK_00/YBlockB'] = 0x31E,
	['SBK_02/GiftA'] = nil, -- Trading Event Second Contest Ruins Entrance
	['SBK_05/ItemA'] = 0x33F,
	['SBK_06/Tree1_Drop1'] = 0x345,
	['SBK_06/RandomBlockItemA'] = 0x330,
	['SBK_10/HiddenYBlockA'] = 0x31F,
	['SBK_14/YBlockA'] = 0x320,
	['SBK_14/YBlockB'] = 0x321,
	['SBK_14/RandomBlockItemA'] = 0x331,
	['SBK_20/YBlockA'] = 0x322,
	['SBK_20/YBlockB'] = 0x323,
	['SBK_20/YBlockC'] = 0x324,
	['SBK_22/YBlockA'] = 0x325,
	['SBK_22/YBlockB'] = 0x326,
	['SBK_22/YBlockC'] = 0x327,
	['SBK_22/YBlockD'] = 0x328,
	['SBK_22/YBlockE'] = 0x329,
	['SBK_24/HiddenRBlockA'] = 0x32A,
	['SBK_25/RandomBlockItemA'] = 0x332,
	['SBK_25/RandomBlockItemB'] = 0x333,
	['SBK_26/Tree1_Drop1'] = 0x346,
	['SBK_30/Tree2_Drop1A'] = 0x340,
	['SBK_34/GiftA'] = nil, -- Star piece for giving nomadimouse a letter
	['SBK_34/Tree1_Drop1'] = 0x347,
	['SBK_35/Tree1_Drop1'] = 0x348,
	['SBK_36/Tree9_Drop1A'] = 0x341,
	['SBK_36/Tree1_Drop1'] = 0x349,
	['SBK_36/Tree2_Drop1'] = 0x34A,
	['SBK_36/Tree6_Drop1'] = 0x34B,
	['SBK_40/RandomBlockItemA'] = 0x334,
	['SBK_43/YBlockA'] = 0x32B,
	['SBK_45/ItemA'] = 0x343,
	['SBK_45/ItemB'] = 0x342,
	['SBK_46/YBlockA'] = 0x32C,
	['SBK_46/HiddenYBlockA'] = 0x32D,
	['SBK_46/Tree2_Drop1'] = 0x34C,
	['SBK_52/RandomBlockItemA'] = 0x335,
	['SBK_55/ItemA'] = 0x344,
	['SBK_55/Tree1_Drop1'] = 0x34D,
	['SBK_55/RandomBlockItemA'] = 0x336,
	['SBK_56/Tree1_Drop1A'] = 0x318,
	['SBK_56/Tree2_Drop1A'] = 0x31A,
	['SBK_56/Tree3_Drop1'] = 0x34E,
	['SBK_56/Tree9_Drop1'] = 0x34F,
	['SBK_56/RandomBlockItemA'] = 0x33D, -- SBK56_SuperBlock
	['SBK_61/HiddenRBlockA'] = 0x32E,
	['SBK_64/YBlockA'] = 0x32F,
	['SBK_66/Tree3_Drop1'] = nil,
	['SBK_66/RandomBlockItemA'] = 0x337,
	['SBK_66/RandomBlockItemB'] = 0x338,
	['SBK_66/RandomBlockItemC'] = 0x339,
	['SBK_66/RandomBlockItemD'] = 0x33A,
	['SBK_66/RandomBlockItemE'] = 0x33B,
	['SBK_66/RandomBlockItemF'] = 0x33C,
	['ISK_02/ItemA'] = 0x694,
	['ISK_03/ItemA'] = 0x367,
	['ISK_05/ItemA'] = 0x372,
	['ISK_06/ItemA'] = 0x375,
	['ISK_06/ItemB'] = 0x36A,
	['ISK_07/ItemA'] = 0x36B,
	['ISK_07/ItemB'] = 0x374,
	['ISK_09/ChestA'] = 0x385,
	['ISK_09/BigChest'] = 0x384,
	['ISK_10/RandomBlockItemA'] = 0x387, -- ISK10_SuperBlock
	['ISK_12/ItemA'] = 0x377,
	['ISK_13/ItemA'] = 0x371,
	['ISK_14/ItemA'] = 0x373,
	['MIM_04/GiftA'] = 0x3A2, -- Magical Seed 3
	['MIM_08/RBlockA'] = 0x39D,
	['MIM_09/RBlockA'] = 0x39E,
	['MIM_11/YBlockA'] = 0x3A7,
	['MIM_11/Bush1_Drop1'] = nil,
	['OBK_01/GiftA'] = 0x3BF,
	['OBK_01/GiftB'] = nil, -- Letter 20 from Franky to Dane T
	['OBK_03/CrateA'] = 0x3C5,
	['OBK_03/GiftA'] = nil, -- Star Piece Reward for giving Igor Letter 11
	['OBK_04/CrateA'] = 0x3CA,
	['OBK_04/BigChest'] = 0x3C7,
	['OBK_05/CrateA'] = nil,
	['OBK_05/CrateB'] = nil,
	['OBK_06/ItemA'] = 0x3CF,
	['OBK_06/CrateA'] = 0x3D0,
	['OBK_07/ChestA'] = 0x3D2,
	['OBK_08/ItemA'] = 0x3D3,
	['OBK_09/Partner'] = nil, -- Bow
	['ARN_02/ItemA'] = 0x3ED,
	['ARN_02/ItemB'] = 0x3EE,
	['ARN_02/YBlockA'] = 0x3EA,
	['ARN_02/YBlockB'] = 0x3EB,
	['ARN_02/YBlockC'] = 0x3EC,
	['ARN_03/GiftA'] = 0x3F7,
	['ARN_03/YBlockA'] = 0x3EF,
	['ARN_04/YBlockA'] = 0x3F0,
	['ARN_04/YBlockB'] = 0x3F1,
	['ARN_04/ItemA'] = 0x3FB,
	['ARN_04/RandomBlockItemA'] = 0x3F2,
	['DGB_03/ItemA'] = 0x412,
	['DGB_04/RandomBlockItemA'] = 0x416, -- DGB04_SuperBlock
	['DGB_06/ChestA'] = 0x418,
	['DGB_07/ItemA'] = 0x41A,
	['DGB_11/ItemA'] = 0x41F,
	['DGB_12/ChestA'] = 0x421,
	['DGB_13/ItemA'] = 0x422,
	['DGB_13/ItemB'] = 0x423,
	['DGB_13/ItemC'] = 0x424,
	['DGB_13/ItemD'] = 0x425,
	['DGB_13/ItemE'] = 0x426,
	['DGB_13/ItemF'] = 0x427,
	['DGB_13/ItemG'] = 0x428,
	['DGB_14/YBlockA'] = 0x429,
	['DGB_16/ItemA'] = 0x42D,
	['OMO_01/ItemA'] = 0x454,
	['OMO_01/ItemB'] = nil, -- Maple Syrup - Running Shy Guys in Toy Box
	['OMO_01/ItemC'] = nil, -- Cake Mix - Running Shy Guys in Toy Box
	['OMO_01/ItemD'] = nil, -- Cake Mix - Running Shy Guys in Toy Box
	['OMO_01/ItemE'] = nil, -- Mushroom - Running Shy Guys in Toy Box
	['OMO_01/ItemF'] = nil, -- Fire Flower - Running Shy Guys in Toy Box
	['OMO_01/HiddenYBlockA'] = 0x456,
	['OMO_01/HiddenYBlockB'] = 0x457,
	['OMO_02/YBlockA'] = 0x45A,
	['OMO_02/HiddenYBlockA'] = 0x45B,
	['OMO_02/ItemA'] = 0x45C,
	['OMO_03/HiddenYBlockA'] = 0x45D,
	['OMO_04/ItemA'] = 0x44E,
	['OMO_04/ChestA'] = 0x45F,
	['OMO_04/YBlockA'] = 0x460,
	['OMO_04/YBlockB'] = 0x461,
	['OMO_04/YBlockC'] = 0x462,
	['OMO_04/ItemB'] = 0x463,
	['OMO_04/ItemC'] = 0x464,
	['OMO_04/ItemD'] = 0x465,
	['OMO_04/ItemE'] = 0x466,
	['OMO_04/ItemF'] = 0x467,
	['OMO_04/ItemG'] = 0x468,
	['OMO_04/ItemH'] = 0x469,
	['OMO_04/ItemI'] = 0x46A,
	['OMO_04/ItemJ'] = 0x46C,
	['OMO_04/ItemK'] = 0x46D,
	['OMO_05/ItemA'] = 0x452,
	['OMO_05/YBlockA'] = 0x46E,
	['OMO_05/YBlockB'] = 0x46F,
	['OMO_05/HiddenYBlockA'] = 0x470,
	['OMO_05/HiddenYBlockB'] = 0x471,
	['OMO_06/ChestA'] = 0x472,
	['OMO_06/HiddenYBlockA'] = 0x473,
	['OMO_07/ItemA'] = 0x474, -- OMO07_SpawnedPeachChoice2
	['OMO_07/ChestA'] = 0x476,
	['OMO_07/ChestB'] = 0x477,
	['OMO_07/ChestC'] = 0x478,
	['OMO_07/YBlockA'] = 0x475,
	['OMO_08/HiddenYBlockA'] = 0x479,
	['OMO_09/ItemA'] = 0x47A, -- OMO09_SpawnedPeachChoice3
	['OMO_09/ChestA'] = 0x47B,
	['OMO_09/ItemB'] = 0x47E,
	['OMO_09/ItemC'] = 0x47F,
	['OMO_09/ItemD'] = 0x480,
	['OMO_09/ItemE'] = 0x481,
	['OMO_09/ItemF'] = 0x482,
	['OMO_09/ItemG'] = 0x483,
	['OMO_09/ItemH'] = 0x496,
	['OMO_09/ItemI'] = 0x488,
	['OMO_09/ItemJ'] = 0x489,
	['OMO_09/ItemK'] = 0x48D,
	['OMO_09/ItemL'] = 0x48E,
	['OMO_09/ItemM'] = 0x492,
	['OMO_09/ItemN'] = 0x493,
	['OMO_09/ItemO'] = 0x47D,
	['OMO_09/RandomBlockItemA'] = 0x497,
	['OMO_10/HiddenYBlockA'] = 0x498,
	['OMO_11/HiddenYBlockA'] = 0x49D,
	['OMO_11/HiddenYBlockB'] = 0x49E,
	['OMO_11/YBlockA'] = 0x49B,
	['OMO_11/HiddenRBlockA'] = 0x49A,
	['OMO_11/YBlockB'] = 0x49C,
	['OMO_11/RandomBlockItemA'] = 0x499, -- MULTICOIN, MAY BE BACKWARDS CONFIRM
	['OMO_11/RandomBlockItemB'] = 0x4AA, -- OMO11_SuperBlock, MAY BE BACKWARDS CONFIRM
	['OMO_12/Partner'] = nil, -- Watt
	['OMO_13/ChestA'] = 0x49F,
	['OMO_13/YBlockA'] = 0x4A0,
	['OMO_13/HiddenYBlockA'] = 0x4A1,
	['OMO_17/YBlockA'] = 0x4A2,
	['OMO_17/YBlockB'] = 0x4A3,
	['OMO_17/YBlockC'] = 0x4A4,
	['OMO_17/RandomBlockItemA'] = 0x4A5,
	['JAN_00/ItemA'] = 0x4C0,
	['JAN_00/ItemB'] = 0x4C1,
	['JAN_00/ItemC'] = 0x4C3,
	['JAN_00/Tree1_Drop1A'] = 0x4BF, -- Mislabeled as unused - CONFIRM 
	['JAN_01/ItemA'] = 0x4C6,
	['JAN_01/HiddenYBlockA'] = 0x4DE,
	['JAN_01/HiddenYBlockB'] = 0x4DF,
	['JAN_01/ItemB'] = 0x4C5,
	['JAN_01/ItemC'] = 0x4FD,
	['JAN_01/Tree2_Drop1'] = nil, -- Coconut
	['JAN_01/Tree3_Drop1'] = nil, -- Coconut
	['JAN_01/Tree4_Drop1'] = nil, -- Coconut
	['JAN_01/Tree5_Drop1'] = nil, -- Coconut
	['JAN_01/Tree6_Drop1'] = nil, -- Coconut
	['JAN_01/Tree7_Drop1A'] = 0x4E4,
	['JAN_01/Tree7_Drop1B'] = nil, -- Coconut
	['JAN_02/GiftA'] = nil, -- Jade Raven -- Suspect 0x4C7 CONFIRM
	['JAN_02/Tree2_Drop1A'] = nil, -- Coconut
	['JAN_02/Tree3_Drop1A'] = nil, -- Coconut
	['JAN_03/GiftA'] = 0x4FB, -- Magical Seed 4
	['JAN_03/GiftB'] = nil, -- Melon - Trade Tayce T food to yellow yoshi
	['JAN_03/GiftC'] = nil, -- Letter 22 as reward for delivering Letter 21 to Yoshi Kid
	['JAN_03/Tree1_Drop1A'] = nil, -- Coconut
	['JAN_04/ChestA'] = 0x4CC,
	['JAN_04/ItemA'] = 0x4CD,
	['JAN_04/Tree2_Drop1A'] = 0x4CB,
	['JAN_04/Partner'] = nil, -- Sushie
	['JAN_05/RBlockA'] = 0x4D6,
	['JAN_05/Bush1_Drop1'] = 0x4F0,
	['JAN_05/Bush2_Drop1'] = 0x4D7,
	['JAN_05/Tree2_Drop1'] = 0x4E5,
	['JAN_06/ItemA'] = 0x4D8,
	['JAN_06/Tree1_Drop1'] = 0x4E6,
	['JAN_07/Tree1_Drop1'] = 0x4E7,
	['JAN_08/ItemA'] = 0x4FF,
	['JAN_08/ItemB'] = 0x500,
	['JAN_08/ItemC'] = 0x501,
	['JAN_08/HiddenYBlockA'] = 0x4E1,
	['JAN_08/Bush1_Drop1'] = 0x4F1,
	['JAN_08/Bush2_Drop1'] = 0x4F2,
	['JAN_08/Tree2_Drop1'] = 0x4E8,
	['JAN_08/Tree3_Drop1'] = 0x4E9,
	['JAN_08/RandomBlockItemA'] = 0x4FE, -- JAN08_SuperBlock
	['JAN_09/Bush1_Drop1'] = 0x4F3,
	['JAN_09/Bush6_Drop1'] = 0x4F4,
	['JAN_09/Tree2_Drop1'] = 0x4EA,
	['JAN_09/Tree3_Drop1'] = 0x4EB,
	['JAN_10/ItemA'] = 0x502,
	['JAN_12/Tree1_Drop1'] = 0x4DA,
	['JAN_12/HiddenYBlockA'] = 0x4E2,
	['JAN_12/Tree1_Drop2'] = 0x4EC,
	['JAN_13/HiddenYBlockA'] = 0x4E3,
	['JAN_13/Tree1_Drop1'] = 0x4ED,
	['JAN_14/Tree2_Drop1'] = 0x4DB,
	['JAN_14/Tree5_Drop1'] = 0x4DC,
	['JAN_15/Tree2_Drop1'] = 0x4EE,
	['JAN_18/ItemA'] = 0x4DD,
	['JAN_22/GiftA'] = nil, -- ultra stone - suspect 0x4FA
	['JAN_22/ItemA'] = 0x4D9,
	['KZN_03/ItemA'] = 0x532,
	['KZN_03/ItemB'] = 0x533,
	['KZN_03/YBlockA'] = 0x534,
	['KZN_03/YBlockB'] = 0x535,
	['KZN_03/YBlockC'] = 0x536,
	['KZN_03/YBlockD'] = 0x537,
	['KZN_04/RandomBlockItemA'] = 0x530, -- KZN04_SuperBlock
	['KZN_06/HiddenYBlockA'] = 0x520,
	['KZN_07/BigChest'] = 0x523,
	['KZN_08/ChestA'] = 0x52C,
	['KZN_09/RandomBlockItemA'] = 0x531, -- KZN09_SuperBlock
	['KZN_19/YBlockA'] = 0x538,
	['KZN_19/YBlockB'] = 0x539,
	['FLO_03/GiftA'] = 0x583, -- Gift for beating all monty moles - suspect 0x583 - CONFIRM
	['FLO_03/Tree1_Drop1A'] = nil, -- red berry proxy
	['FLO_03/Tree1_Drop1B'] = nil, -- red berry proxy
	['FLO_07/ItemA'] = 0x55E,
	['FLO_07/GiftA'] = nil, -- fertile soil - given by Posie
	['FLO_08/ItemA'] = 0x565,
	['FLO_08/ItemB'] = nil, -- Stinky Herb
	['FLO_08/Tree1_Drop1A'] = nil, -- blue berry proxy
	['FLO_08/Tree1_Drop1B'] = nil, -- blue berry proxy
	['FLO_08/RandomBlockItemA'] = 0x57A, -- FLO08_SuperBlock
	['FLO_09/Tree1_Drop1'] = 0x566, -- Suspect flipped with FLO_09/ItemA
	['FLO_09/ItemA'] = nil, -- Stinky Herb
	['FLO_10/GiftA'] = 0x560, -- Miracle Water - CONFIRM
	['FLO_10/Tree1_Drop1A'] = 0x567,
	['FLO_11/RandomBlockItemA'] = 0x568,
	['FLO_12/GiftA'] = 0x564, -- Water Stone - CONFIRM
	['FLO_13/ItemA'] = 0x569,
	['FLO_13/ItemB'] = 0x56A,
	['FLO_13/Partner'] = nil, -- Lakilester
	['FLO_14/ItemA'] = 0x56B,
	['FLO_14/ItemB'] = nil, -- Stinky Herb
	['FLO_16/ItemA'] = 0x56C,
	['FLO_16/ItemB'] = nil, -- Stinky Herb
	['FLO_16/RandomBlockItemA'] = 0x57B, -- FLO16_SuperBlock
	['FLO_17/HiddenYBlockA'] = 0x56E,
	['FLO_17/ItemA'] = 0x56D,
	['FLO_19/ItemA'] = 0x56F,
	['FLO_22/ItemA'] = 0x570,
	['FLO_23/HiddenYBlockA'] = 0x581,
	['FLO_23/HiddenYBlockB'] = 0x580,
	['FLO_24/YBlockA'] = 0x571,
	['FLO_24/HiddenYBlockA'] = 0x572,
	['FLO_24/Tree1_Drop1A'] = nil, -- blue berry proxy
	['FLO_24/Tree1_Drop1B'] = nil, -- blue berry proxy
	['FLO_25/ItemA'] = nil, -- Stinky Herb
	['FLO_25/Tree1_Drop1A'] = nil, -- yellow berry proxy
	['FLO_25/Tree1_Drop1B'] = nil, -- yellow berry proxy
	['SAM_01/GiftA'] = nil, -- snowman bucket - visit mayor after scarf from merle
	['SAM_01/GiftB'] = nil, -- star piece 4E - given by mayor after giving him letter 05
	['SAM_01/ChestA'] = 0x59B,
	['SAM_02/ItemA'] = 0x59E,
	['SAM_02/ItemB'] = 0x5A0,
	['SAM_02/ItemC'] = 0x5A1,
	['SAM_02/ItemD'] = 0x5A2,
	['SAM_02/ItemE'] = 0x5A3,
	['SAM_02/ItemF'] = 0x5A4,
	['SAM_04/Tree2_Drop1'] = 0x5A6,
	['SAM_04/ItemA'] = 0x5A7,
	['SAM_05/ItemA'] = 0x5A9,
	['SAM_05/HiddenYBlockA'] = 0x5AA,
	['SAM_06/GiftA'] = 0x5AB, -- snowman scarf - talk to merle - CONFIRM
	['SAM_06/GiftB'] = nil, -- letter 24 reward for giving letter 23 to fross t
	['SAM_07/HiddenYBlockA'] = 0x5B0,
	['SAM_08/ItemA'] = nil, -- Pebble
	['SAM_08/RandomBlockItemA'] = 0x5B1, -- SAM08_SuperBlock
	['SAM_09/ItemA'] = nil, -- Shooting Star
	['SAM_09/ItemB'] = nil, -- Snowman Doll
	['SAM_09/ItemC'] = nil, -- Thunder Rage
	['SAM_10/RBlockA'] = 0x5B7,
	['SAM_10/ItemA'] = 0x5B8,
	['SAM_11/ItemA'] = 0x5BA,
	['SAM_12/ItemA'] = 0x599,
	['PRA_04/YBlockA'] = 0x5DA,
	['PRA_05/ChestA'] = 0x5D5,
	['PRA_06/ItemA'] = 0x5DB,
	['PRA_11/ChestA'] = 0x5D4,
	['PRA_12/ChestA'] = 0x5DD,
	['PRA_14/RandomBlockItemA'] = 0x5E0,
	['PRA_14/RandomBlockItemB'] = 0x5E1,
	['PRA_15/ItemA'] = 0x5E2,
	['PRA_21/YBlockA'] = 0x5E5,
	['PRA_22/HiddenYBlockA'] = 0x5E7,
	['PRA_27/ChestA'] = 0x5E9,
	['PRA_28/ChestA'] = 0x5EA,
	['PRA_35/ChestA'] = 0x5ED,
	['KPA_01/YBlockA'] = 0x609,
	['KPA_03/YBlockA'] = 0x60A,
	['KPA_10/YBlockA'] = 0x60B,
	['KPA_11/ItemA'] = 0x60D,
	['KPA_14/ItemA'] = 0x611,
	['KPA_14/ItemB'] = 0x612,
	['KPA_15/ChestA'] = 0x613,
	['KPA_17/CrateA'] = 0x617,
	['KPA_17/CrateB'] = 0x618,
	['KPA_61/YBlockA'] = 0x61F,
	['KPA_61/YBlockB'] = 0x620,
	['KPA_61/YBlockC'] = 0x621,
	['KPA_61/ItemA'] = 0x622,
	['KPA_62/RBlockA'] = 0x61D,
	['KPA_91/ItemA'] = 0x627,
	['KPA_95/ItemA'] = 0x62A,
	['KPA_100/ItemA'] = 0x62B,
	['KPA_101/ItemA'] = 0x62C,
	['KPA_111/YBlockA'] = 0x62D,
	['KPA_111/HiddenYBlockA'] = 0x62E,
	['KPA_119/ItemA'] = 0x630,
	['KPA_133/ItemA'] = 0x631,
	['KPA_134/HiddenYBlockA'] = 0x637,
	['OSR_01/GiftA'] = nil, -- Letter 14 for giving Muss T Letter 13
	['OSR_02/HiddenYBlockA'] = 0x66B,
};

function getLocation(index) 
    local byteIndex = math.floor(index / 32)
    local bitIndex = (index % 32)
    return {addr=GAME_FLAGS+(byteIndex * 4), bit=bitIndex}
end

local collected = {}
function collect(node)
    console.log('collecting', node)
    collected[node] = true
end

function is_collected(node)
    return not not collected[node]
end

function set_boots_level(level)
	memory.write_s8(CURRENT_PLAYER_DATA + BOOTS_LEVEL_OFFSET, level, 'System Bus')
end

function set_hammer_level(level)
	memory.write_s8(CURRENT_PLAYER_DATA + HAMMER_LEVEL_OFFSET, level, 'System Bus')
end

function get_coin(count)
	local current = memory.read_s16_be(CURRENT_PLAYER_DATA + COINS_OFFSET, 'System Bus')
	if (current <= 32767 - count) then -- max s16
		memory.write_s16_be(CURRENT_PLAYER_DATA + COINS_OFFSET, current + count, 'System Bus')
	end
end

function get_star_pieces(count)
	local current = memory.read_u8(CURRENT_PLAYER_DATA + STAR_PIECES_OFFSET, 'System Bus')
	if (current <= 255 - count) then -- max u8
		memory.write_u8(CURRENT_PLAYER_DATA + STAR_PIECES_OFFSET, current + count, 'System Bus')
	end
end

function collect_partner(partner_index)
	memory.write_u8(
		CURRENT_PLAYER_DATA + PARTNERS_OFFSET + (partner_index * SIZEOF_PARTNER_STRUCT) + PARTNER_UNLOCKED_OFFSET,
		1,
		'System Bus'
	)
end

function upgrade_partner(partner_index)
	local current = memory.read_s8(
		CURRENT_PLAYER_DATA + PARTNERS_OFFSET + (partner_index * SIZEOF_PARTNER_STRUCT) + PARTNER_LEVEL_OFFSET, 
		'System Bus'
	)
	if (current < 127) then -- max s8
		memory.write_u8(
			CURRENT_PLAYER_DATA + PARTNERS_OFFSET + (partner_index * SIZEOF_PARTNER_STRUCT) + PARTNER_LEVEL_OFFSET, 
			current + 1, 
			'System Bus'
		)
	end
end

function collect_badge(badge_id)
	local addr = BADGE_INVENTORY

	while true do
		local current = memory.read_s16_be(addr, 'RDRAM')
		if (current == ITEM_NONE) then
			memory.write_s16_be(addr, badge_id, 'RDRAM')
			break
		end

		addr = addr + 2 -- s16 is 2 bytes
	end
end

function collect_item(item_id)
	local addr = ITEM_INVENTORY

	-- todo add upper bound by max storage!!!!!
	while true do
		local current = memory.read_s16_be(addr, 'RDRAM')
		if (current == ITEM_NONE) then
			memory.write_s16_be(addr, item_id, 'RDRAM')
			break
		end

		addr = addr + 2 -- s16 is 2 bytes
	end
end

function collect_key_item(item_id)
	local addr = KEY_ITEM_INVENTORY

	-- todo in game tracker
	while true do
		local current = memory.read_s16_be(addr, 'RDRAM')
		if (current == ITEM_NONE) then
			memory.write_s16_be(addr, item_id, 'RDRAM')
			break
		end

		addr = addr + 2 -- s16 is 2 bytes
	end
end

local current_state = STATE_NOT_CONNECTED


function process_request(req)
	if (req['req'] == 'coin') then
		get_coin(1)
	end

	return { locations=collected }
end


-- Receive data from AP client and send message back
function send_receive ()
	-- console.log('waiting for message')
    local message, err = client_socket:receive()
	-- console.log('got message', message, err)
    -- Handle errors
    if err == "closed" then
        if current_state == STATE_CONNECTED then
            print("Connection to client closed")
        end
        current_state = STATE_NOT_CONNECTED
        return
    elseif err == "timeout" then
        -- unlock()
        return
    elseif err ~= nil then
        -- console.log(err)
        current_state = STATE_NOT_CONNECTED
        -- unlock()
        return
    end

    -- Reset timeout timer
    timeout_timer = 5

    -- Process received data
    if DEBUG then
        console.log("Received Message ["..emu.framecount().."]: "..'"'..message..'"')
    end

    if message == "VERSION" then
        local result, err client_socket:send(tostring(SCRIPT_VERSION).."\n")
    else
        local res = {}
		-- console.log('decoding')
        local data = json.decode(message)
		-- console.log('decoded')
        local failed_guard_response = nil
        for i, req in ipairs(data) do
            if failed_guard_response ~= nil then
                res[i] = failed_guard_response
            else
                -- An error is more likely to cause an NLua exception than to return an error here
                console.log('sending to process_request', req)
				table.insert(res, process_request(req))
            end
        end
		console.log('sending', res)
		client_socket:send(json.encode(res).."\n")
    end
end

function queue_push (self, value)
    self[self.right] = value
    self.right = self.right + 1
end

function queue_is_empty (self)
    return self.right == self.left
end

function queue_shift (self)
    value = self[self.left]
    self[self.left] = nil
    self.left = self.left + 1
    return value
end

function new_queue ()
    local queue = {left = 1, right = 1}
    return setmetatable(queue, {__index = {is_empty = queue_is_empty, push = queue_push, shift = queue_shift}})
end

local message_queue = new_queue()

local timeout_timer = 0
local message_timer = 0
local message_interval = 0
local prev_time = 0
local current_time = 0
local message_queue = new_queue()


function request_handler()
	-- console.log('binding to localhost:43055')
	server, err = socket.bind('*', 43088)
	console.log('bound')
	if err ~= nil then
        -- console.log(err)
		console.log('returning', err)
        return
    end

	while true do
        current_time = socket.socket.gettime()
        timeout_timer = timeout_timer - (current_time - prev_time)
        message_timer = message_timer - (current_time - prev_time)
        prev_time = current_time

        if message_timer <= 0 and not message_queue:is_empty() then
            gui.addmessage(message_queue:shift())
            message_timer = message_interval
        end

        if current_state == STATE_NOT_CONNECTED then
			-- console.log('trying to connect?pt1')

            if emu.framecount() % 60 == 0 then
				console.log('trying to connect?')
                server:settimeout(2)
                local client, timeout = server:accept()
                if timeout == nil then
                    console.log("Client connected")
                    current_state = STATE_CONNECTED
                    client_socket = client
                    client_socket:settimeout(0)
                else
                    console.log("No client found. Trying again...")
                end
            end
        else
            repeat
                send_receive()
				coroutine.yield()

					if timeout_timer <= 0 then
						-- console.log("Client timed out")
						-- current_state = STATE_NOT_CONNECTED
					end
				until false

        end

        coroutine.yield()
    end
end


function main() 
	console.log('starting')
	while true do
		local memcache = {}

		for nodeid, index in pairs(nodes) do
			local location = getLocation(index)
			if (memcache[location['addr']] == nil) then
				memcache[location['addr']] = mainmemory.read_s32_be(location['addr']);
			end

			-- console.log(nodeid, string.format('%x',location['addr']), location['bit'], )

			if (bit.check(memcache[location['addr']], location.bit)) then
				-- console.log('in here?',nodeid)
				if (not is_collected(nodeid)) then
					collect(nodeid)
				end
			end
		end

		coroutine.yield()
	end
end

console.log('here!')
local co = coroutine.create(main)
local reqs = coroutine.create(request_handler)

event.onframeend(function() coroutine.resume(co); coroutine.resume(reqs); end)

while true do
	emu.frameadvance()
end