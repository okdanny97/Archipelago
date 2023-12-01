import yaml
from pmrseedgen.models.options.OptionSet import OptionSet
from pmrseedgen.rando_modules.logic import _generate_item_pools
from pmrseedgen.worldgraph import generate, get_all_nodes, get_all_edges, enrich_graph_data
from yaml import SafeLoader

test = (generate(None, None), get_all_nodes(), get_all_edges())
print(test)

# Declare and init additional data structures
## Data structures for graph traversal
all_item_nodes = []
## Data structures for item pool
pool_progression_items = []
pool_other_items = []
pool_misc_progression_items = []

with open("/home/dpa/dev/Archipelago/worlds/paper_mario/default.yaml", "r", encoding="utf-8") as file:
    data = yaml.load(file, Loader=SafeLoader)
    rando_settings = OptionSet()
    rando_settings.update_options(data)



    # Generate item pool
    print("Generating item pool...")
    pool_other_items = _generate_item_pools(
        enrich_graph_data(test[0]),
        pool_progression_items,
        pool_misc_progression_items,
        pool_other_items,
        all_item_nodes,
        rando_settings.include_coins_overworld,
        rando_settings.include_coins_blocks,
        rando_settings.include_coins_foliage,
        rando_settings.include_coins_favors,
        rando_settings.include_shops,
        rando_settings.include_panels,
        rando_settings.include_favors_mode,
        rando_settings.include_letters_mode,
        rando_settings.include_radiotradeevent,
        rando_settings.include_dojo,
        rando_settings.gear_shuffle_mode,
        rando_settings.randomize_consumable_mode,
        rando_settings.item_quality,
        rando_settings.itemtrap_mode,
        rando_settings.bluehouse_open,
        rando_settings.foreverforest_open,
        rando_settings.magical_seeds_required,
        rando_settings.keyitems_outside_dungeon,
        rando_settings.partners_in_default_locations,
        rando_settings.always_speedyspin,
        rando_settings.always_ispy,
        rando_settings.always_peekaboo,
        [],
        [],
        rando_settings.starting_boots,
        rando_settings.starting_hammer,
        rando_settings.add_item_pouches,
        rando_settings.add_unused_badge_duplicates,
        rando_settings.add_beta_items,
        rando_settings.progressive_badges,
        rando_settings.badge_pool_limit,
        rando_settings.bowsers_castle_mode,
        0,
        True
    )
    print('ah')