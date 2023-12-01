from Options import Choice, Toggle, DefaultOnToggle, DeathLink, StartInventoryPool
import random

class HiddenPanels(DefaultOnToggle):
    """Star Pieces hidden under hidden panels are included in the item pool."""
    display_name = "Include Hidden Panels"

class Keysanity(DefaultOnToggle):
    """Off: Dungeon keys can only be found in their respective dungeon.
    On: Dungeon keys can be found anywhere"""
    display_name = "Keysanity"

class DojoRewards(DefaultOnToggle):
    """Include Dojo fight rewards in the item pool. The logic can only expect you to do the 2nd fight with 1 star spirit
    saved. Master fights requirements are 3,4 and 5 star spirits saved."""
    display_name = "Include Dojo Rewards"

class TradingEvents(Toggle):
    """Adds the 3 rewards obtained for doing the Trading Toad quests (started Koopa Village's radio) in the item
    pool."""
    display_name = "Include Trading Event Rewards"

paper_mario_options = {
    "hidden_panels": HiddenPanels,
    "keysanity": Keysanity,
    "dojo_rewards": DojoRewards,
    "trading_events": TradingEvents
}
